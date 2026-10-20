--!nonstrict
--[[
	Arnes de servidor compartido por las pruebas de integracion (GameService.spec, ClientBoot.spec): carga el codigo REAL
	de GameService y de los paquetes con `luau.load` y un entorno de dobles (ver el comentario de GameService.spec).
	Extraido de GameService.spec sin cambios de comportamiento.

	  local ServerHarness = require("./support/ServerHarness")
	  local world = ServerHarness.buildWorld()
]]
local luau = require("@lune/luau")
local fs = require("@lune/fs")
local Mocks = require("@testkit/mocks")

local HERE = (debug.info(1, "s") :: string):gsub("[^/\\]+$", "")
local GAME = HERE .. "../../src/"
local PACKAGES = HERE .. "../../../../packages/"

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
		created = {}, -- toda instancia creada con Instance.new (el doble no sabe de jerarquia: sirve para inspeccionar)
	}

	-- Remotos y otras instancias falsas
	local function newInstance(className)
		local instance = { ClassName = className, Name = "", Parent = nil }
		table.insert(world.created, instance)
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
			SubscribeAsync = function()
				-- opts.messagingStallSeconds: simula un MessagingService lento (cede el hilo que lo llama)
				if opts.messagingStallSeconds then
					env.task.wait(opts.messagingStallSeconds)
				end
			end,
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
		Material = { Wood = "Wood" }, -- attachRod (cana del personaje)
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
		new = function(position)
			return { position = position }
		end,
	}
	sandbox.Color3 = {
		fromRGB = function(r, g, b)
			return { r = r, g = g, b = b }
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
		ProductIds = opts.productIds or FAKE_IDS, -- opts.productIds: IDs a probar (p. ej. los REALES de ProductIds.luau)
		Schema = load(GAME .. "server/Schema.luau"),
		WorldBuilder = {
			build = function(zones, art)
				world.builtWithArt = art -- opts.artDirector: el proveedor de arte que GameService entrega a WorldBuilder
				local spawns = {}
				local castTargets = {}
				for _, zone in zones do
					castTargets[zone.id] = if opts.artDirector then { castOf = zone.id } else nil
					-- Vector3 falso: `spawn + Vector3.new(...)` devuelve { zone = id } para poder comprobar a donde se viaja
					spawns[zone.id] = setmetatable({ zone = zone.id }, {
						__add = function(self)
							return { zone = self.zone }
						end,
					})
				end
				return { spawns = spawns, castTargets = castTargets }
			end,
		},
		StudioMemoryStore = load(GAME .. "server/StudioMemoryStore.luau"),
		LiveOpsDefaults = load(GAME .. "server/LiveOpsDefaults.luau"),
		ArtDirector = opts.artDirector, -- opcional (nil = sin arte generado, como siempre)
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

return {
	buildWorld = buildWorld,
	FAKE_IDS = FAKE_IDS,
	USER = USER,
	KEY = KEY,
}
