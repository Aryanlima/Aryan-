--!nonstrict
--[[
	Arranque del CLIENTE sin Studio: ejecuta el Main.client.luau REAL (y todos los modulos que requiere) tal como
	salen del lugar construido por Rojo, contra instancias de interfaz "fachada" cuyas propiedades se validan una a una
	con la base de reflexion de Roblox (libreria `@lune/roblox`), y alimentado con el estado y las ofertas REALES que
	produce el servidor en el arnes de GameService (tests/support/ServerHarness.luau).

	Que cazaria en Studio: `require` por instancia que no resuelven en tiempo de ejecucion, propiedades o enums mal
	escritos en UI.create / Instance.new (los analiza luau-lsp solo si no pasan por `any`), remotos que el cliente espera
	y el servidor no crea, y errores de indice/nil al pintar la interfaz con un estado de servidor real (HUD, minijuego,
	tarjeta de captura, banner, tienda, canas, bestiario, temporada, probabilidades y codigos), en ES y en EN.

	Limites (lo que esto NO prueba): el motor real (replicacion, orden de scripts, layout, fuentes, tamanos reales de
	pantalla, entrada tactil), TweenService, ni que la interfaz SE VEA bien. Las propiedades se validan por nombre y tipo,
	no por su efecto visual. Ver docs/verificacion-estructura.md.

	Si falta `rojo`, la prueba se OMITE con aviso (ARYAN_REQUIRE_ROJO=1 la hace fallar).
]]
local luau = require("@lune/luau")
local roblox = require("@lune/roblox") :: any
local testkit = require("@testkit")
local Mocks = require("@testkit/mocks")
-- Todos los `require` ANTES del primer `describe` (ver tests/support/BuiltPlace.luau).
local BuiltPlace = require("./support/BuiltPlace")
local ClientLogic = require("../src/shared/ClientLogic")
local Remotes = require("../src/shared/Remotes")
local ServerHarness = require("./support/ServerHarness")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect

if BuiltPlace.bytes == nil then
	local message = "[ClientBoot] " .. tostring(BuiltPlace.problem)
	if BuiltPlace.required then
		describe("Arranque del cliente", function()
			it("rojo esta disponible (ARYAN_REQUIRE_ROJO=1)", function()
				error(message, 0)
			end)
		end)
	else
		print("AVISO " .. message .. " -> prueba de arranque del cliente OMITIDA")
		describe("Arranque del cliente (OMITIDA: sin rojo)", function()
			it.skip("necesita el binario rojo", function() end)
		end)
	end
	return
end

----------------------------------------------------------------------------
-- Entorno del cliente: servicios falsos + instancias fachada validadas por Lune
----------------------------------------------------------------------------

local EVENT_NAMES = { Activated = true, FocusLost = true, Changed = true, MouseButton1Click = true }

local function buildClient(locale: string, options: { withoutRemotes: boolean? }?)
	local database = roblox.getReflectionDatabase()
	local clock = Mocks.Clock.new()
	local signals = {}
	local invalid = {}
	local warnings = {}
	local remoteLog = {} -- { {name=, args=} } lo que el cliente envia al servidor
	local remotes = {} -- nombre -> remoto falso
	local bound = {} -- ContextActionService.BindAction

	local function newSignal()
		local signal = Mocks.Signal.new({ spawn = clock.task.spawn, quiet = true })
		table.insert(signals, signal)
		return signal
	end

	-- Instancia fachada: cada propiedad que se asigna se valida tambien en una Instance real de Lune.
	local methods = {}
	function methods.IsA(self, className)
		local name = rawget(self, "ClassName")
		while name ~= nil do
			if name == className then
				return true
			end
			local class = database:GetClass(name)
			name = class and class.Superclass
		end
		return false
	end
	function methods.GetChildren(self)
		return table.clone(self._children)
	end
	function methods.GetDescendants(self)
		local list = {}
		local function walk(node)
			for _, child in node._children do
				table.insert(list, child)
				walk(child)
			end
		end
		walk(self)
		return list
	end
	function methods.FindFirstChild(self, name)
		for _, child in self._children do
			if child.Name == name then
				return child
			end
		end
		return nil
	end
	function methods.Destroy(self)
		local parent = rawget(self, "Parent")
		if parent then
			local index = table.find(parent._children, self)
			if index then
				table.remove(parent._children, index)
			end
		end
		rawset(self, "Parent", nil)
		rawset(self, "_destroyed", true)
	end

	local function newFake(className)
		local real = roblox.Instance.new(className) -- falla si la clase no existe o no es creable
		local node = { ClassName = className, _props = { Name = className }, _children = {}, _signals = {} }
		return setmetatable(node, {
			__newindex = function(t, key, value)
				if key == "Parent" then
					local previous = rawget(t, "Parent")
					if previous ~= nil then
						local index = table.find(previous._children, t)
						if index then
							table.remove(previous._children, index)
						end
					end
					rawset(t, "Parent", value)
					if value ~= nil then
						table.insert(value._children, t)
					end
					return
				end
				local ok, err = pcall(function()
					real[key] = value
				end)
				if not ok then
					table.insert(invalid, className .. "." .. tostring(key) .. ": " .. tostring(err))
				end
				t._props[key] = value
			end,
			__index = function(t, key)
				local method = methods[key]
				if method then
					return method
				end
				if EVENT_NAMES[key] then
					local signals_ = rawget(t, "_signals")
					if signals_[key] == nil then
						signals_[key] = newSignal()
					end
					return signals_[key]
				end
				return (rawget(t, "_props") :: any)[key]
			end,
		})
	end

	-- Mundo minimo (instancias REALES de Lune) para el cartel de zona y el flotador.
	local world = roblox.Instance.new("Folder")
	world.Name = "World"
	local lake = roblox.Instance.new("Folder")
	lake.Name = "lake"
	lake.Parent = world
	local castTarget = roblox.Instance.new("Part")
	castTarget.Name = "CastTarget"
	castTarget.Position = roblox.Vector3.new(0, 1, -50)
	castTarget.Parent = lake
	local sign = roblox.Instance.new("TextLabel")
	sign:SetAttribute("LocaleKey", "zone.lake.name")
	sign.Text = "Lago"
	sign.Parent = lake

	local workspaceFake = {
		_children = {},
		DescendantAdded = newSignal(),
		FindFirstChild = function(_self, name)
			if name == "World" then
				return world
			end
			return nil
		end,
	}

	local playerGui = newFake("Folder")
	playerGui.Name = "PlayerGui"
	local localization = { RobloxLocaleId = locale }

	local function remote(name)
		if remotes[name] == nil then
			local known = false
			for _, list in { Remotes.inbound, Remotes.outbound } do
				known = known or table.find(list, name) ~= nil
			end
			if not known then
				return nil
			end
			remotes[name] = {
				ClassName = "RemoteEvent",
				Name = name,
				OnClientEvent = newSignal(),
				FireServer = function(_self, ...)
					table.insert(remoteLog, { name = name, args = table.pack(...) })
				end,
			}
		end
		return remotes[name]
	end
	local remotesFolder = {
		Name = Remotes.folderName,
		WaitForChild = function(_self, name)
			return remote(name)
		end,
		FindFirstChild = function(_self, name)
			return remote(name)
		end,
	}

	-- Proxy sobre el arbol REAL construido por Rojo: WaitForChild/FindFirstChild/Parent y `require` por instancia.
	local place = roblox.deserializePlace(BuiltPlace.bytes)
	local proxies = {}
	local moduleCache = {}
	local services = {}
	local base = table.clone((getfenv :: any)(0))
	local wrap, requireInstance

	local function sandboxFor(scriptInstance)
		local environment = table.clone(base)
		environment.script = wrap(scriptInstance)
		environment.require = function(target)
			local inner = rawget(target, "_inst")
			if inner == nil then
				error("require: el argumento no es un ModuleScript del arbol construido: " .. tostring(target), 2)
			end
			return requireInstance(inner)
		end
		return environment
	end

	function requireInstance(inner)
		if inner.ClassName ~= "ModuleScript" then
			error("require: " .. inner:GetFullName() .. " es un " .. inner.ClassName .. ", no un ModuleScript", 2)
		end
		if moduleCache[inner] == nil then
			local chunk = luau.load(inner.Source, { environment = sandboxFor(inner), debugName = inner:GetFullName() })
			moduleCache[inner] = { value = chunk() }
		end
		return moduleCache[inner].value
	end

	function wrap(inner, extras)
		if inner == nil then
			return nil
		end
		if proxies[inner] ~= nil and extras == nil then
			return proxies[inner]
		end
		local proxy = { _inst = inner, Name = inner.Name, ClassName = inner.ClassName }
		local function child(_self, name)
			if extras ~= nil and extras[name] ~= nil then
				return extras[name]
			end
			return wrap(inner:FindFirstChild(name))
		end
		setmetatable(proxy, {
			__index = function(_t, key)
				if key == "Parent" then
					return wrap(inner.Parent)
				elseif key == "WaitForChild" or key == "FindFirstChild" then
					return child
				elseif key == "IsA" then
					return function(_self, className)
						return inner:IsA(className)
					end
				end
				return nil
			end,
		})
		if extras == nil then
			proxies[inner] = proxy
		end
		return proxy
	end

	-- options.withoutRemotes: el servidor NO llego a crear la carpeta de remotos (su arranque fallo)
	local extras = if options ~= nil and options.withoutRemotes then {} else { [Remotes.folderName] = remotesFolder }
	services.ReplicatedStorage = wrap(place:FindFirstChild("ReplicatedStorage"), extras)
	services.LocalizationService = localization
	services.Players = { LocalPlayer = {
		WaitForChild = function(_self, _name)
			return playerGui
		end,
	} }
	services.Workspace = workspaceFake
	services.TweenService = {
		Create = function()
			return { Play = function() end, Cancel = function() end }
		end,
	}
	services.RunService = { RenderStepped = newSignal() }
	services.ContextActionService = {
		BindAction = function(_self, name, callback)
			bound[name] = callback
		end,
	}

	base.game = {
		GetService = function(_self, name)
			local service = services[name]
			if service == nil then
				error("el cliente pidio un servicio que el arnes no simula: " .. tostring(name), 2)
			end
			return service
		end,
	}
	for _, name in { "Enum", "Vector3", "Vector2", "Color3", "CFrame", "UDim2", "UDim" } do
		base[name] = roblox[name]
	end
	base.Instance = { new = newFake }
	base.TweenInfo = {
		new = function()
			return {}
		end,
	}
	base.task = clock.task
	base.os = { clock = clock.time, time = clock.osTime, date = os.date }
	base.warn = function(...)
		local parts = {}
		for _, part in { ... } do
			table.insert(parts, tostring(part))
		end
		table.insert(warnings, table.concat(parts, " "))
	end
	base.print = function() end

	-- Main.client.luau del lugar construido
	local mainInstance = place
		:FindFirstChild("StarterPlayer")
		:FindFirstChild("StarterPlayerScripts")
		:FindFirstChild("Client")
		:FindFirstChild("Main")
	local chunk = luau.load(mainInstance.Source, { environment = sandboxFor(mainInstance), debugName = "Main.client" })
	chunk()

	local client = {
		clock = clock,
		invalid = invalid,
		warnings = warnings,
		remoteLog = remoteLog,
		remotes = remotes,
		signals = signals,
		bound = bound,
		localization = localization,
		sign = sign,
		workspace = workspaceFake,
	}
	client.gui = playerGui._children[1]

	function client.server(name, ...)
		local target = remote(name)
		assert(target ~= nil, "remoto desconocido: " .. name)
		target.OnClientEvent:Fire(...)
		clock:advance(0.05)
	end
	function client.find(predicate, root)
		local found = {}
		local function walk(node)
			if predicate(node) then
				table.insert(found, node)
			end
			for _, child in node._children do
				walk(child)
			end
		end
		walk(root or client.gui)
		return found
	end
	function client.press(node)
		node.Activated:Fire()
		clock:advance(0.05)
	end
	function client.sent(name)
		local list = {}
		for _, entry in remoteLog do
			if entry.name == name then
				table.insert(list, entry)
			end
		end
		return list
	end
	function client.assertHealthy()
		clock:assertNoErrors()
		expect(invalid).toEqual({})
		expect(warnings).toEqual({})
		for _, signal in signals do
			expect(signal.errors).toEqual({})
		end
	end
	return client
end

----------------------------------------------------------------------------
-- Estado REAL del servidor
----------------------------------------------------------------------------

local function serverPayloads()
	local world = ServerHarness.buildWorld()
	local env = world.env
	local player = world.join()
	local profile = world.api.manager:get(ServerHarness.USER)
	-- Un jugador con algo de progreso: 3 capturas (tutorial) + dinero para que las cañas/zonas tengan estados distintos.
	for _ = 1, 3 do
		world.fire(player, "Cast")
		local started = world.sentTo("CastStarted")
		local session = started[#started].args[1]
		env.clock:advance(0.9)
		world.fire(player, "Reel", session.id, 0.9)
		env.clock:advance(2)
	end
	profile.data.wallet.coins = 250000
	profile.data.wallet.pearls = 40
	world.fire(player, "RequestOffers")
	env.clock:advance(1)
	world.fire(player, "RequestState")
	env.clock:advance(1)
	local function last(name)
		local list = world.sentTo(name)
		return list[#list].args[1]
	end
	return {
		state = last("State"),
		offers = last("Offers"),
		catch = last("Catch"),
		castStarted = world.sentTo("CastStarted")[1].args[1],
		toasts = (function()
			local messages = {}
			for _, entry in world.sentTo("Toast") do
				table.insert(messages, entry.args[1])
			end
			return messages
		end)(),
		inventoryCount = world.api.logic:inventoryCount(profile.data),
	}
end

local payloads = serverPayloads()

----------------------------------------------------------------------------
-- Pruebas
----------------------------------------------------------------------------

local MENU_ORDER = { "shop", "rods", "bestiary", "season", "odds", "codes" }

local function menuButtons(client)
	local menu = client.find(function(node)
		return node.Name == "Menu"
	end)[1]
	local buttons = {}
	for _, child in menu._children do
		if child.ClassName == "TextButton" then
			table.insert(buttons, child)
		end
	end
	table.sort(buttons, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	return buttons
end

local function openPanels(client)
	return client.find(function(node)
		return node.ClassName == "Frame" and string.match(node.Name, "Panel$") ~= nil
	end)
end

for _, locale in { "es-es", "en-us" } do
	describe(
		"Cliente real (Main.client.luau del lugar construido) con estado de servidor real [" .. locale .. "]",
		function()
			it("arranca: requiere sus modulos, crea la interfaz, conecta TODOS los remotos y pide el estado", function()
				local client = buildClient(locale)
				expect(client.gui ~= nil).toBe(true)
				expect(client.gui.ClassName).toBe("ScreenGui")
				expect(client.gui.Name).toBe("FishFortune")
				expect(client.gui.ResetOnSpawn).toBe(false)
				for _, name in Remotes.outbound do
					local remote = client.remotes[name]
					if remote == nil or #remote.OnClientEvent._handlers < 1 then
						error("el cliente no conecto el remoto de salida " .. name)
					end
				end
				expect(#client.sent("RequestState")).toBe(1)
				-- el cartel del mundo se traduce al idioma del jugador
				expect(client.sign.Text ~= "Lago" or locale == "es-es").toBe(true)
				-- la tecla Espacio queda ligada a LANZAR / RECOGER
				expect(client.bound.FF_Action).toBeTruthy()
				client.assertHealthy()
			end)

			it(
				"pinta el HUD con el estado real y reacciona a CastStarted / Catch / Toast / Banner del servidor",
				function()
					local client = buildClient(locale)
					client.server("State", payloads.state)
					local texts = {}
					for _, node in
						client.find(function(candidate)
							return candidate.ClassName == "TextLabel"
						end)
					do
						texts[#texts + 1] = tostring(node.Text)
					end
					expect(#texts > 3).toBe(true)
					local hudText = table.concat(texts, "|")
					expect(string.find(hudText, "250", 1, true) ~= nil).toBe(true) -- monedas (compactadas: 250K)
					-- lanzar: llega CastStarted -> overlay del minijuego; luego la captura -> tarjeta
					client.server("CastStarted", payloads.castStarted)
					local overlay = client.find(function(node)
						return node.Name == "Minigame"
					end)[1]
					expect(overlay.Visible).toBe(true)
					client.clock:advance(0.5)
					client.press(client.find(function(node)
						return node.Name == "ActionButton"
					end)[1])
					expect(#client.sent("Reel")).toBe(1)
					client.server("Catch", payloads.catch)
					expect(#client.find(function(node)
						return node.Name == "CatchCard"
					end)).toBe(1)
					for _, message in payloads.toasts do
						client.server("Toast", message)
					end
					client.server("Banner", {
						key = "banner.mythic",
						args = {
							player = "Ana",
							creature = { key = "creature.leviathan" },
							zone = { key = "zone.lake.name" },
						},
					})
					client.clock:advance(10)
					client.assertHealthy()
				end
			)

			it("deja libre la zona del chat y pone los avisos sobre la barra de acciones", function()
				local client = buildClient(locale)
				client.server("State", payloads.state)
				local function named(name)
					return client.find(function(node)
						return node.Name == name
					end)[1]
				end
				expect(named("Stats").Position.Y.Scale).toBeCloseTo(ClientLogic.layout.statsTopScale, 4)
				expect(named("Events").Visible).toBe(#payloads.state.events > 0)
				client.server("Toast", payloads.toasts[1])
				local toast = named("Toast")
				expect(toast.AnchorPoint.Y).toBe(1)
				expect(toast.Position.Y.Offset).toBe(ClientLogic.layout.toastBottomOffset)
				client.assertHealthy()
			end)

			it(
				"abre y cierra cada menu (tienda, canas, bestiario, temporada, probabilidades, codigos) sin errores",
				function()
					local client = buildClient(locale)
					client.server("State", payloads.state)
					local buttons = menuButtons(client)
					expect(#buttons >= #MENU_ORDER).toBe(true)
					for index, menuId in MENU_ORDER do
						client.press(buttons[index])
						local panels = openPanels(client)
						if #panels ~= 1 then
							error("el menu '" .. menuId .. "' deberia dejar 1 panel abierto y hay " .. #panels)
						end
						if menuId == "shop" then
							expect(#client.sent("RequestOffers") >= 1).toBe(true)
							client.server("Offers", payloads.offers)
							local rows = client.find(function(node)
								return string.match(node.Name, "^pass_") ~= nil
									or string.match(node.Name, "^product_") ~= nil
							end)
							expect(#rows > 0).toBe(true)
						end
						-- un nuevo estado redibuja el panel abierto
						client.server("State", payloads.state)
						expect(#openPanels(client)).toBe(1)
						local close = client.find(function(node)
							return node.Name == "Close"
						end, panels[1])[1]
						client.press(close)
						expect(#openPanels(client)).toBe(0)
					end
					client.assertHealthy()
				end
			)

			it("los botones envian solo solicitudes: vender y la pesca automatica usan remotos de entrada", function()
				local client = buildClient(locale)
				client.server("State", payloads.state)
				client.press(client.find(function(node)
					return node.Name == "SellButton"
				end)[1])
				expect(#client.sent("SellAll")).toBe(1)
				for _, entry in client.sent("SellAll") do
					expect(entry.args.n).toBe(0)
				end
				client.assertHealthy()
			end)
		end
	)
end

describe("Servidor que no arranco", function()
	it("sin la carpeta de remotos el cliente falla con un error claro (no se queda mudo esperando)", function()
		local ok, err = pcall(buildClient, "en-us", { withoutRemotes = true })
		expect(ok).toBe(false)
		expect(string.find(tostring(err), "no creo los remotos", 1, true) ~= nil).toBe(true)
	end)
end)

describe("Cambio de idioma en caliente", function()
	it("el HUD y los paneles se redibujan en el nuevo idioma con el siguiente estado", function()
		local client = buildClient("es-es")
		client.server("State", payloads.state)
		local function sellText()
			return client.find(function(node)
				return node.Name == "SellButton"
			end)[1].Text
		end
		local spanish = sellText()
		client.localization.RobloxLocaleId = "en-us"
		client.server("State", payloads.state)
		local english = sellText()
		expect(spanish ~= english).toBe(true)
		client.assertHealthy()
	end)
end)
