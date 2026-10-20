--!nonstrict
--[[
	Arnes de integracion de GameService (el "pegamento" del servidor, ~820 lineas que NINGUN otro test ejecuta).

	Como funciona: GameService usa globales de Roblox (game, Instance, Enum, task, Random, os...). Aqui se carga
	su codigo (y el de los paquetes que usa) con `luau.load` y un ENTORNO propio: `game` falso con servicios falsos,
	`task` y `os.time/os.clock` ligados al reloj simulado del testkit, `Instance.new` que devuelve remotos falsos.
	Asi se puede ejecutar `GameService.start(m)` entero y disparar los remotos como lo haria un cliente.

	Limites (lo que esto NO prueba): el motor real (replicacion, orden de scripts, Rojo), ni los servicios reales.
	Es una ejecucion con dobles, no un playtest en Studio.

	Rutas: se calculan a partir de la ubicacion de ESTE archivo (tests/ -> ../src, ../../../packages).
]]
local luau = require("@lune/luau")
local fs = require("@lune/fs")
local testkit = require("@testkit")
local Mocks = require("@testkit/mocks")

local describe, it, expect, beforeEach = testkit.describe, testkit.it, testkit.expect, testkit.beforeEach

local HERE = (debug.info(1, "s") :: string):gsub("[^/\\]+$", "")
local GAME = HERE .. "../src/"
local PACKAGES = HERE .. "../../../packages/"

local FAKE_IDS = {
	passes = { auto_fish = 1, double_coins = 2, luck_plus = 3, starter = 4, vip = 5, season_pass = 6 },
	products = {
		lucky_bait_15 = 11,
		coin_boost_15 = 12,
		coin_pack_small = 13,
		coin_pack_medium = 14,
		coin_pack_large = 15,
		pearl_pack = 16,
		slot_pack = 17,
	},
}

local USER = 7001
local KEY = "FishFortune_PlayerData_v1" -- DATASTORE_NAME de GameService

local function buildWorld(overrides)
	local opts = overrides or {}
	local env = Mocks.new()
	local world = {
		env = env,
		sent = {}, -- { {name=, player=, args={...}} } (servidor -> cliente)
		remotes = {}, -- nombre -> remoto falso (RemoteEvent)
		warnings = {},
		analytics = {},
		published = {},
		bindToClose = nil,
		policy = { ArePaidRandomItemsRestricted = false },
		policyCalls = 0,
		prompts = {}, -- PromptProductPurchase / PromptGamePassPurchase solicitados por el servidor
	}

	-- Remotos y otras instancias falsas
	local function newInstance(className)
		local instance = { ClassName = className, Name = "", Parent = nil }
		if className == "RemoteEvent" then
			instance.OnServerEvent = Mocks.Signal.new({ spawn = env.task.spawn })
			function instance.FireClient(_self, player, ...)
				table.insert(world.sent, { name = instance.Name, player = player, args = table.pack(...) })
			end
			function instance.FireAllClients(_self, ...)
				table.insert(world.sent, { name = instance.Name, player = "ALL", args = table.pack(...) })
			end
			table.insert(world.remotes, instance)
		end
		function instance.Destroy() end
		function instance.FindFirstChild()
			return nil
		end
		return instance
	end

	local analyticsService = {}
	for _, method in { "LogEconomyEvent", "LogFunnelStepEvent", "LogOnboardingFunnelStepEvent", "LogCustomEvent" } do
		analyticsService[method] = function(_self, ...)
			table.insert(world.analytics, { method = method, args = table.pack(...) })
		end
	end

	local services = {
		AnalyticsService = analyticsService,
		DataStoreService = env.DataStoreService,
		HttpService = {
			GenerateGUID = function()
				return "guid-" .. tostring(#world.warnings + 1)
			end,
			JSONDecode = function(_self, text)
				return text
			end,
		},
		MarketplaceService = env.MarketplaceService,
		MessagingService = {
			PublishAsync = function(_self, topic, message)
				table.insert(world.published, { topic = topic, message = message })
			end,
			SubscribeAsync = function() end,
		},
		PolicyService = {
			GetPolicyInfoForPlayerAsync = function()
				world.policyCalls += 1
				return world.policy
			end,
		},
		Players = env.Players,
		ReplicatedStorage = newInstance("ReplicatedStorage"),
		RunService = env.RunService,
		ConfigService = {
			GetConfigAsync = function()
				return { GetValue = function() end }
			end,
		},
	}

	local marketplace = env.MarketplaceService
	local realPromptProduct, realPromptPass = marketplace.PromptProductPurchase, marketplace.PromptGamePassPurchase
	marketplace.PromptProductPurchase = function(self, player, productId, ...)
		table.insert(world.prompts, { kind = "product", id = productId })
		return realPromptProduct(self, player, productId, ...)
	end
	marketplace.PromptGamePassPurchase = function(self, player, passId, ...)
		table.insert(world.prompts, { kind = "pass", id = passId })
		return realPromptPass(self, player, passId, ...)
	end

	local gameStub = {
		PrivateServerId = "",
		PrivateServerOwnerId = 0,
		JobId = "",
		GetService = function(_self, name)
			local service = services[name]
			if service == nil then
				error("servicio no simulado en el arnes: " .. tostring(name), 2)
			end
			return service
		end,
		BindToClose = function(_self, callback)
			world.bindToClose = callback
		end,
	}

	local EnumWithAnalytics = setmetatable({
		AnalyticsEconomyFlowType = { Source = "Source", Sink = "Sink" },
	}, { __index = env.Enum })

	-- Copia de los globales del runtime (string, math, table, pcall...) como base del entorno del codigo cargado.
	local sandbox = table.clone((getfenv :: any)(0))
	sandbox.game = gameStub
	sandbox.Enum = EnumWithAnalytics
	sandbox.task = env.task
	sandbox.Instance = { new = newInstance }
	sandbox.Random = {
		new = function()
			return {
				NextNumber = function()
					return opts.random and opts.random() or math.random()
				end,
			}
		end,
	}
	sandbox.os = {
		time = env.clock.osTime,
		clock = env.clock.time,
		date = os.date,
	}
	sandbox.warn = function(...)
		local parts = {}
		for _, part in { ... } do
			table.insert(parts, tostring(part))
		end
		table.insert(world.warnings, table.concat(parts, " "))
	end
	sandbox.print = function() end
	sandbox.Vector3 = {
		new = function()
			return {}
		end,
	}
	sandbox.CFrame = {
		new = function()
			return {}
		end,
	}
	sandbox.Color3 = {
		fromRGB = function()
			return {}
		end,
	}

	local function load(path)
		local source = fs.readFile(path)
		local chunk = luau.load(source, { environment = sandbox, debugName = path })
		return chunk()
	end
	world.load = load

	local m = {
		Odds = load(PACKAGES .. "Odds.luau"),
		Net = load(PACKAGES .. "Net.luau"),
		Locale = load(PACKAGES .. "Locale.luau"),
		Data = load(PACKAGES .. "Data.luau"),
		Economy = load(PACKAGES .. "Economy.luau"),
		Shop = load(PACKAGES .. "Shop.luau"),
		LiveOps = load(PACKAGES .. "LiveOps.luau"),
		Analytics = load(PACKAGES .. "Analytics.luau"),
		Balance = load(GAME .. "shared/Balance.luau"),
		Strings = load(GAME .. "shared/Strings.luau"),
		FishingRules = load(GAME .. "shared/FishingRules.luau"),
		Remotes = load(GAME .. "shared/Remotes.luau"),
		FeatureFlags = opts.flags or load(GAME .. "shared/FeatureFlags.luau"),
		GameLogic = load(GAME .. "server/GameLogic.luau"),
		Catalog = load(GAME .. "server/Catalog.luau"),
		ProductIds = FAKE_IDS,
		Schema = load(GAME .. "server/Schema.luau"),
		WorldBuilder = {
			build = function(zones)
				local spawns = {}
				for _, zone in zones do
					spawns[zone.id] = {}
				end
				return { spawns = spawns, castTargets = {} }
			end,
		},
		StudioMemoryStore = load(GAME .. "server/StudioMemoryStore.luau"),
		LiveOpsDefaults = load(GAME .. "server/LiveOpsDefaults.luau"),
	}
	local GameService = load(GAME .. "server/GameService.luau")
	world.api = GameService.start(m)
	world.m = m

	function world.remote(name)
		for _, remote in world.remotes do
			if remote.Name == name and remote.ClassName == "RemoteEvent" then
				return remote
			end
		end
		error("remoto inexistente: " .. name)
	end
	-- Dispara un remoto como si lo enviara el cliente del jugador.
	function world.fire(player, name, ...)
		world.remote(name).OnServerEvent:Fire(player, ...)
		env.clock:advance(0.01)
	end
	function world.sentTo(name)
		local list = {}
		for _, entry in world.sent do
			if entry.name == name then
				table.insert(list, entry)
			end
		end
		return list
	end
	function world.join(userId, name, props)
		-- El stub de Player del testkit no trae CharacterAdded (GameService se conecta a el): se anade y SOLO
		-- despues se dispara PlayerAdded.
		local properties = table.clone(props or {})
		properties.fire = false
		local player = env.Players:AddPlayer(userId or USER, name or "Alice", properties)
		player.CharacterAdded = Mocks.Signal.new({ spawn = env.task.spawn })
		env.Players.PlayerAdded:Fire(player)
		env.clock:advance(2) -- carga del perfil + loadPlayer + onLoaded
		return player
	end
	function world.stored()
		return env.DataStoreService:GetDataStore(KEY):_peek("Player_" .. USER)
	end
	return world
end

describe("GameService (arnes de integracion con dobles)", function()
	local world, env

	beforeEach(function()
		world = buildWorld()
		env = world.env
	end)

	it("arranca sin errores y registra ProcessReceipt, BindToClose y los 16 remotos de entrada", function()
		expect(env.MarketplaceService.ProcessReceipt).toBeTruthy()
		expect(world.bindToClose).toBeTruthy()
		local inbound = 0
		for _, remote in world.remotes do
			if remote.OnServerEvent and #remote.OnServerEvent._handlers > 0 then
				inbound += 1
			end
		end
		expect(inbound).toBe(16)
		env.clock:assertNoErrors()
	end)

	it("al entrar un jugador se carga el perfil y se le envia el estado inicial", function()
		local player = world.join()
		local profile = world.api.manager:get(USER)
		expect(profile).toBeTruthy()
		expect(profile:isActive()).toBe(true)
		local states = world.sentTo("State")
		expect(#states >= 1).toBe(true)
		expect(states[#states].player).toBe(player)
		expect(states[#states].args[1].coins).toBe(0)
		expect(states[#states].args[1].paidLuckEnabled).toBe(false)
		env.clock:assertNoErrors()
	end)

	it("autosave: un perfil activo se vuelve a guardar a los 2 minutos (y renueva el latido del bloqueo)", function()
		world.join()
		local before = env.DataStoreService:GetRequestCount("UpdateAsync")
		env.clock:advance(130)
		expect(env.DataStoreService:GetRequestCount("UpdateAsync") > before).toBe(true)
	end)

	it("pesca de punta a punta: Cast -> CastStarted -> Reel -> Catch y el inventario se guarda", function()
		local player = world.join()
		world.fire(player, "Cast")
		local started = world.sentTo("CastStarted")
		expect(#started).toBe(1)
		local session = started[1].args[1]
		expect(session.center >= 0.25 and session.center <= 0.75).toBe(true)
		env.clock:advance(0.8)
		world.fire(player, "Reel", session.id, 0.8)
		local catches = world.sentTo("Catch")
		expect(#catches).toBe(1)
		-- los 3 primeros lanzamientos son del tutorial: la primera captura es Poco comun
		expect(catches[1].args[1].rarity).toBe("Uncommon")
		local profile = world.api.manager:get(USER)
		expect(world.api.logic:inventoryCount(profile.data)).toBe(1)
		env.clock:assertNoErrors()
	end)

	it(
		"validacion de remotos: NaN, inf, fuera de rango, tipo erroneo y argumentos de mas se rechazan sin tocar el estado",
		function()
			local player = world.join()
			world.fire(player, "Cast")
			local session = world.sentTo("CastStarted")[1].args[1]
			env.clock:advance(0.8)
			local rejectedBefore = world.api.net:stats().rejected
			-- ni NaN, ni inf, ni 31 s (el maximo es 30), ni texto, ni un argumento extra
			world.fire(player, "Reel", session.id, 0 / 0)
			env.clock:advance(1)
			world.fire(player, "Reel", session.id, math.huge)
			env.clock:advance(1)
			world.fire(player, "Reel", session.id, 31)
			env.clock:advance(1)
			world.fire(player, "Reel", session.id, "0.8")
			env.clock:advance(1)
			world.fire(player, "Reel", session.id, 0.8, "extra")
			expect(world.api.net:stats().rejected - rejectedBefore).toBe(5)
			expect(#world.sentTo("Catch")).toBe(0)
			expect(#world.sentTo("CastFailed")).toBe(0) -- rechazados por Net, ni siquiera llegan a la logica
		end
	)

	it(
		"RequestPurchase solo acepta claves de catalogo con el patron [%w_]+ (el cliente nunca manda IDs ni precios)",
		function()
			local player = world.join()
			local rejectedBefore = world.api.net:stats().rejected
			world.fire(player, "RequestPurchase", "product", "coin pack; drop")
			world.fire(player, "RequestPurchase", "product", "../etc")
			world.fire(player, "RequestPurchase", "gift", "coin_pack_small")
			world.fire(player, "RequestPurchase", "product", 13) -- un ID numerico no vale
			expect(world.api.net:stats().rejected - rejectedBefore).toBe(4)
		end
	)

	it("limite de frecuencia: 30 RequestState seguidos no producen 30 respuestas", function()
		local player = world.join()
		local before = #world.sentTo("State")
		for _ = 1, 30 do
			world.remote("RequestState").OnServerEvent:Fire(player)
		end
		env.clock:advance(0.01)
		expect(#world.sentTo("State") - before <= 5).toBe(true)
		expect(world.api.net:stats().rejected >= 20).toBe(true)
	end)

	it("compra de un pack de monedas: se concede UNA vez, se guarda antes de confirmar y es idempotente", function()
		local player = world.join()
		local receipt, decision = env.MarketplaceService:SimulatePurchase(player, FAKE_IDS.products.coin_pack_small)
		env.clock:advance(1)
		expect(decision).toBe(env.Enum.ProductPurchaseDecision.PurchaseGranted)
		expect(world.stored().data.wallet.coins).toBe(2500)
		expect(world.stored().data.purchases[receipt.PurchaseId]).toBeTruthy()
		-- reentrega del mismo recibo
		local again = env.MarketplaceService:SimulateRedelivery(receipt.PurchaseId)
		env.clock:advance(1)
		expect(again).toBe(env.Enum.ProductPurchaseDecision.PurchaseGranted)
		expect(world.stored().data.wallet.coins).toBe(2500)
		-- y el cliente recibe un aviso y el estado actualizado
		expect(#world.sentTo("Toast") >= 1).toBe(true)
		env.clock:assertNoErrors()
	end)

	it("v1: el recibo de un producto de suerte (Cebo) NO se concede ni se confirma", function()
		local player = world.join()
		local _, decision = env.MarketplaceService:SimulatePurchase(player, FAKE_IDS.products.lucky_bait_15)
		env.clock:advance(1)
		expect(decision).toBe(env.Enum.ProductPurchaseDecision.NotProcessedYet)
		expect(next(world.stored().data.boosts)).toBeNil()
		expect(next(world.stored().data.purchases)).toBeNil()
	end)

	it("v1: la tienda no ofrece suerte y el servidor rechaza pedirla por clave", function()
		local player = world.join()
		world.fire(player, "RequestOffers")
		local offers = world.sentTo("Offers")[1].args[1]
		for _, offer in offers do
			expect(offer.key == "luck_plus" or offer.key == "lucky_bait_15").toBe(false)
		end
		world.fire(player, "RequestPurchase", "product", "lucky_bait_15")
		env.clock:advance(4)
		world.fire(player, "RequestPurchase", "pass", "luck_plus")
		local failed = world.sentTo("CastFailed")
		expect(#failed).toBe(2)
		expect(failed[1].args[1]).toBe("unavailable")
		expect(failed[2].args[1]).toBe("unavailable")
	end)

	it("SetAutoFish sin el pase Auto-Pesca no se activa", function()
		local player = world.join()
		world.fire(player, "SetAutoFish", true)
		expect(world.api.manager:get(USER).data.autoFish).toBe(false)
	end)

	it("SetAutoFish con el pase (propiedad verificada al entrar) si se activa", function()
		env.MarketplaceService:GrantGamePass(USER, FAKE_IDS.passes.auto_fish)
		local player = world.join()
		world.fire(player, "SetAutoFish", true)
		expect(world.api.manager:get(USER).data.autoFish).toBe(true)
	end)

	it("codigo de canje: se cobra UNA vez, aunque se envie dos veces seguidas, y se guarda enseguida", function()
		local player = world.join()
		world.remote("RedeemCode").OnServerEvent:Fire(player, "welcome")
		world.remote("RedeemCode").OnServerEvent:Fire(player, "WELCOME")
		env.clock:advance(1)
		local profile = world.api.manager:get(USER)
		expect(profile.data.wallet.coins).toBe(1000)
		expect(profile.data.wallet.pearls).toBe(5)
		expect(world.stored().data.wallet.coins).toBe(1000) -- guardado al momento (no espera al autosave)
	end)

	it("al salir el jugador: lastSeen (base del offline) se guarda y el bloqueo se libera", function()
		local player = world.join()
		env.clock:advance(500)
		local leftAt = env.clock.osTime()
		env.Players:RemovePlayer(player)
		env.clock:advance(5)
		local record = world.stored()
		expect(record.lock).toBeNil()
		expect(record.data.lastSeen).toBe(leftAt)
	end)

	it("BindToClose: guarda y libera a todos los jugadores", function()
		world.join(7001, "A")
		world.join(7002, "B")
		env.task.spawn(function()
			world.bindToClose()
		end)
		env.clock:advance(10)
		for _, uid in { 7001, 7002 } do
			local record = env.DataStoreService:GetDataStore(KEY):_peek("Player_" .. uid)
			expect(record.lock).toBeNil()
		end
	end)

	it("ganancias offline: solo con el reloj del SERVIDOR (os.time) y con tope", function()
		-- primera sesion: sale con rod = driftwood, 40 monedas/hora
		local player = world.join()
		env.clock:advance(10)
		env.Players:RemovePlayer(player)
		env.clock:advance(5)
		-- 10 horas despues vuelve: el tope base es 2 h => 80 monedas (40/h x 2 h x multiplicador 1)
		env.clock:advance(10 * 3600)
		world.join()
		env.clock:advance(2)
		local profile = world.api.manager:get(USER)
		expect(profile.data.wallet.coins).toBe(80)
	end)

	it(
		"BUG SHOP-05: no se ofrece (ni se abre el prompt de) un Boost cuyo tiempo ya esta en el tope de acumulacion",
		function()
			local player = world.join()
			local profile = world.api.manager:get(USER)
			profile.data.boosts.coin_boost = env.clock.osTime() + 3500 -- 1 h de tope: otro de 15 min se "comeria" lo pagado
			world.fire(player, "RequestPurchase", "product", "coin_boost_15")
			expect(#world.prompts).toBe(0)
			local failed = world.sentTo("CastFailed")
			expect(failed[#failed].args[1]).toBe("maxed")
			-- con tiempo de sobra en el tope si se ofrece
			profile.data.boosts.coin_boost = nil
			env.clock:advance(4)
			world.fire(player, "RequestPurchase", "product", "coin_boost_15")
			expect(#world.prompts).toBe(1)
			expect(world.prompts[1].id).toBe(FAKE_IDS.products.coin_boost_15)
		end
	)

	it(
		"v1 (flag apagado): ningun remoto consulta PolicyService (getPolicy cede y context() corre en cada remoto)",
		function()
			local player = world.join()
			world.fire(player, "Cast")
			env.clock:advance(0.8)
			world.fire(player, "Reel", world.sentTo("CastStarted")[1].args[1].id, 0.8)
			world.fire(player, "SellAll")
			world.fire(player, "RequestOffers")
			expect(world.policyCalls).toBe(0)
		end
	)

	it("BUG LIVEOPS-01: un premio mal formado en la configuracion remota NO gasta el codigo del jugador", function()
		local player = world.join()
		world.api.liveOps:getConfig().codes.BAD = { reward = { coins = "mucho" } }
		world.remote("RedeemCode").OnServerEvent:Fire(player, "BAD")
		env.clock:advance(1)
		local profile = world.api.manager:get(USER)
		expect(profile.data.redeemedCodes.BAD).toBeNil() -- sigue disponible cuando se corrija la configuracion
		expect(profile.data.wallet.coins).toBe(0)
	end)

	-- Eventos de economia (LogEconomyEvent) de tipo IAP registrados hasta ahora.
	local function iapEconomyEvents(w)
		local list = {}
		for _, entry in w.analytics do
			if entry.method == "LogEconomyEvent" and entry.args[6] == "IAP" then
				table.insert(list, entry)
			end
		end
		return list
	end

	it(
		"BUG ANALYTICS-01: el evento IAP solo sale DESPUES de guardar; si el guardado falla no se cuenta (ni se cuenta dos veces)",
		function()
			local player = world.join()
			env.DataStoreService:SetOutage(true)
			local receipt, decision = env.MarketplaceService:SimulatePurchase(player, FAKE_IDS.products.coin_pack_small)
			env.clock:advance(60)
			-- concedido en memoria pero NO guardado: Roblox lo reintentara; analitica a cero
			expect(decision).toBe(env.Enum.ProductPurchaseDecision.NotProcessedYet)
			expect(#iapEconomyEvents(world)).toBe(0)
			-- vuelve el DataStore: el reintento guarda y SOLO entonces se registra el evento (una vez)
			env.DataStoreService:SetOutage(false)
			local retried = env.MarketplaceService:SimulateRedelivery(receipt.PurchaseId)
			env.clock:advance(1)
			expect(retried).toBe(env.Enum.ProductPurchaseDecision.PurchaseGranted)
			local events = iapEconomyEvents(world)
			expect(#events).toBe(1)
			expect(events[1].args[4]).toBe(2500) -- amount
			expect(events[1].args[5]).toBe(2500) -- endingBalance
			expect(events[1].args[7]).toBe("coin_pack_small") -- sku
			-- otra reentrega del mismo recibo no vuelve a contar
			env.MarketplaceService:SimulateRedelivery(receipt.PurchaseId)
			env.clock:advance(1)
			expect(#iapEconomyEvents(world)).toBe(1)
			expect(world.stored().data.wallet.coins).toBe(2500)
		end
	)

	it(
		"ANALYTICS-01: con el guardado correcto el evento IAP se registra una vez y el resto de la economia no cambia",
		function()
			local player = world.join()
			env.MarketplaceService:SimulatePurchase(player, FAKE_IDS.products.coin_pack_small)
			env.clock:advance(1)
			expect(#iapEconomyEvents(world)).toBe(1)
			-- una venta normal sigue registrando su evento de economia en el momento (no es dinero real)
			world.fire(player, "Cast")
			env.clock:advance(0.8)
			world.fire(player, "Reel", world.sentTo("CastStarted")[1].args[1].id, 0.8)
			world.fire(player, "SellAll")
			local gameplay = 0
			for _, entry in world.analytics do
				if entry.method == "LogEconomyEvent" and entry.args[6] == "Gameplay" then
					gameplay += 1
				end
			end
			expect(gameplay >= 1).toBe(true)
			expect(#iapEconomyEvents(world)).toBe(1)
		end
	)

	it(
		"BUG OFFLINE-01: el autosave refresca lastSeen (tras un crash no se paga como offline el tiempo jugado)",
		function()
			world.join()
			local joinedAt = env.clock.osTime()
			env.clock:advance(500) -- sin salir ni BindToClose: solo hay autosaves cada 120 s
			local lastSeen = world.stored().data.lastSeen
			expect(lastSeen >= joinedAt + 360).toBe(true) -- antes: lastSeen seguia en el instante de entrada
			expect(lastSeen <= env.clock.osTime()).toBe(true)
		end
	)

	it(
		"OFFLINE-01: refrescar lastSeen no pisa el calculo offline de la entrada aunque loadPlayer tarde varios segundos",
		function()
			local player = world.join()
			env.clock:advance(10)
			env.Players:RemovePlayer(player)
			env.clock:advance(5)
			env.clock:advance(10 * 3600)
			-- la consulta de pases falla 3 veces (reintentos con espera): onLoaded tarda ~3 s antes de pagar el offline
			env.MarketplaceService:FailNext(3 * 6)
			world.join()
			env.clock:advance(10)
			expect(world.api.manager:get(USER).data.wallet.coins).toBe(80) -- 40/h x 2 h de tope
		end
	)

	-- Localizacion: el servidor envia CLAVES + argumentos validados (nunca texto traducido); el cliente traduce.
	local function validMessage(w, payload)
		local locale = w.m.Locale.new(w.m.Strings)
		local key, args = locale:sanitizeMessage(payload)
		return key, args, locale
	end

	it("i18n: los avisos (Toast) son { key, args } validos y se traducen a ES y EN con las mismas cifras", function()
		local player = world.join()
		world.fire(player, "SellAll") -- nada que vender
		world.fire(player, "Cast")
		env.clock:advance(0.8)
		world.fire(player, "Reel", world.sentTo("CastStarted")[1].args[1].id, 0.8)
		world.fire(player, "SellAll")
		env.MarketplaceService:SimulatePurchase(player, FAKE_IDS.products.coin_pack_small)
		env.clock:advance(1)
		local keys = {}
		for _, entry in world.sentTo("Toast") do
			local payload = entry.args[1]
			expect(type(payload)).toBe("table") -- nunca una cadena ya traducida
			local key, args, locale = validMessage(world, payload)
			expect(key).toBeTruthy()
			table.insert(keys, key)
			for _, language in { "es", "en" } do
				local text = locale:format(language, key, args)
				expect(string.find(text, "[{}]") == nil).toBe(true) -- sin marcadores sin sustituir
			end
			if key == "toast.sold" then
				expect(args.count).toBe(1)
				expect(locale:format("en", key, args)).toBe(
					"Sold 1 catch for " .. locale:number("en", args.coins) .. " coins."
				)
				expect(locale:format("es", key, args)).toContain("Vendiste 1 captura por")
			end
			if key == "toast.purchase_received" then
				expect(args.item).toEqual({ key = "product.coin_pack_small.name" })
				expect(locale:format("en", key, args)).toBe("Purchase received: Small Coin Pack")
				expect(locale:format("es", key, args)).toBe("Compra recibida: Pack de monedas pequeño")
			end
		end
		expect(table.find(keys, "toast.nothing_to_sell") ~= nil).toBe(true)
		expect(table.find(keys, "toast.sold") ~= nil).toBe(true)
		expect(table.find(keys, "toast.purchase_received") ~= nil).toBe(true)
	end)

	it("i18n: el aviso de ganancias offline, el canje de codigos y la bienvenida llegan como claves", function()
		local player = world.join()
		-- la bienvenida por defecto tiene clave propia (welcome.launch)
		local welcomeKeys = {}
		for _, entry in world.sentTo("Toast") do
			table.insert(welcomeKeys, entry.args[1].key)
		end
		expect(table.find(welcomeKeys, "welcome.launch") ~= nil).toBe(true)
		world.remote("RedeemCode").OnServerEvent:Fire(player, "WELCOME")
		env.clock:advance(1)
		world.remote("RedeemCode").OnServerEvent:Fire(player, "NOEXISTE")
		env.clock:advance(1)
		local keys = {}
		for _, entry in world.sentTo("Toast") do
			table.insert(keys, entry.args[1].key)
		end
		expect(table.find(keys, "toast.code_redeemed") ~= nil).toBe(true)
		expect(table.find(keys, "toast.code_unknown") ~= nil).toBe(true)
	end)

	it("i18n: un mensaje de bienvenida de la configuracion remota sin traduccion se envia como toast.raw", function()
		world.api.liveOps:getConfig().welcome = { id = "w-remoto", message = "Mensaje remoto" }
		local player = world.join()
		local found = false
		for _, entry in world.sentTo("Toast") do
			local payload = entry.args[1]
			if payload.key == "toast.raw" then
				found = true
				expect(payload.args.text).toBe("Mensaje remoto")
				expect(validMessage(world, payload)).toBe("toast.raw")
			end
		end
		expect(found).toBe(true)
		expect(player).toBeTruthy()
	end)

	it("i18n: el banner de MITICO viaja como mensaje con referencias a criatura y zona (no como texto)", function()
		local mythicWorld = buildWorld({
			random = function()
				return 0.99999
			end,
		})
		local player = mythicWorld.join(USER, "Alice")
		for _ = 1, 4 do
			mythicWorld.fire(player, "Cast")
			mythicWorld.env.clock:advance(0.8)
			local started = mythicWorld.sentTo("CastStarted")
			mythicWorld.fire(player, "Reel", started[#started].args[1].id, 0.8)
			mythicWorld.env.clock:advance(1.2)
		end
		local banners = mythicWorld.sentTo("Banner")
		expect(#banners >= 1).toBe(true)
		local payload = banners[1].args[1]
		local key, args, locale = validMessage(mythicWorld, payload)
		expect(key).toBe("banner.mythic")
		expect(args.player).toBe("Alice")
		expect(args.creature).toEqual({ key = "creature.lake_spirit" })
		expect(args.zone).toEqual({ key = "zone.lake.name" })
		expect(locale:format("en", assert(key, "clave"), args)).toBe("Alice caught a MYTHIC: Lake Spirit (Calm Lake)")
		expect(locale:format("es", assert(key, "clave"), args)).toBe(
			"Alice pescó un MÍTICO: Espíritu del Lago (Lago Calmo)"
		)
		-- la captura ya no lleva el nombre: el cliente lo traduce con el id
		local catches = mythicWorld.sentTo("Catch")
		expect(catches[4].args[1].name).toBeNil()
		expect(catches[4].args[1].id).toBe("lake_spirit")
	end)

	it(
		"i18n: las ofertas de la tienda llevan claves y argumentos ademas del texto de respaldo (y 'maxed' sigue siendo un motivo)",
		function()
			local player = world.join()
			world.fire(player, "RequestOffers")
			local offers = world.sentTo("Offers")[1].args[1]
			local locale = world.m.Locale.new(world.m.Strings)
			local seen = 0
			for _, offer in offers do
				seen += 1
				expect(offer.nameKey).toBe(offer.kind .. "." .. offer.key .. ".name")
				expect(offer.descriptionKey).toBe(offer.kind .. "." .. offer.key .. ".desc")
				local key, args = locale:sanitizeMessage(
					{ key = offer.descriptionKey, args = offer.textArgs },
					{ prefixes = { "pass.", "product." }, lenient = true }
				)
				expect(key).toBe(offer.descriptionKey)
				expect(string.find(locale:format("en", assert(key, "clave"), args), "[{}]") == nil).toBe(true)
				expect(#offer.name > 0).toBe(true) -- texto de respaldo en espanol
			end
			expect(seen).toBe(11)
		end
	)

	it("i18n: las expulsiones de Data muestran ES y EN juntos (el servidor no conoce el idioma del jugador)", function()
		local manager = world.api.manager
		for name, spanishFragment in
			{ locked = "Espera un minuto", loadFailed = "No pudimos cargar", lockLost = "otro servidor" }
		do
			local text = manager:_message(name)
			expect(text).toContain(spanishFragment)
			expect(string.find(text, "rejoin", 1, true) ~= nil).toBe(true)
		end
	end)

	it(
		"BUG BANNER-01: el aviso global de MITICO recorta el nombre por CARACTERES (UTF-8 valido) y llega a otros servidores",
		function()
			-- rng = 0.99999: la ultima criatura de la tabla del Lago es el Mitico (tras los 3 lanzamientos del tutorial)
			local mythicWorld = buildWorld({
				random = function()
					return 0.99999
				end,
			})
			local mythicEnv = mythicWorld.env
			local longName = string.rep("\u{6F22}", 20) -- 20 caracteres = 60 bytes
			local player = mythicWorld.join(USER, "Alice", { DisplayName = longName })
			for _ = 1, 4 do
				mythicWorld.fire(player, "Cast")
				mythicEnv.clock:advance(0.8)
				local started = mythicWorld.sentTo("CastStarted")
				mythicWorld.fire(player, "Reel", started[#started].args[1].id, 0.8)
				mythicEnv.clock:advance(1.2)
			end
			local catches = mythicWorld.sentTo("Catch")
			expect(catches[4].args[1].rarity).toBe("Mythic")
			expect(#mythicWorld.sentTo("Banner") >= 1).toBe(true)
			expect(#mythicWorld.published).toBe(1)
			local shown = mythicWorld.published[1].message.p
			expect(utf8.len(shown)).toBe(20) -- antes: nil (corte por bytes en mitad de un caracter)
		end
	)
end)
