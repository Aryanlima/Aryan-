--!nonstrict
--[[
	Mocks de servicios de Roblox para probar logica pura con Lune.

	  local Mocks = require("@testkit/mocks")
	  local env = Mocks.new()          -- entorno fresco por test (llamalo en beforeEach)
	  env.clock         Clock          (task.wait/spawn/delay/defer simulados, :advance, :runAll)
	  env.task          = env.clock.task
	  env.Enum          Enum minimo (ProductPurchaseDecision, InfoType, CurrencyType, MembershipType)
	  env.Players       Players mock   (PlayerAdded/PlayerRemoving, :AddPlayer, :RemovePlayer)
	  env.RunService    RunService mock (Heartbeat..., :Step, :RunFor)
	  env.DataStoreService   DataStoreService mock (fallos y limites simulables)
	  env.MarketplaceService MarketplaceService mock (ProcessReceipt, game passes)
	  env.game          stub con :GetService(name), PlaceId, JobId
	  env:installGlobals()  (ver abajo) intenta exponer Enum/task/game como globales

	La logica bajo prueba debe recibir estos objetos por inyeccion de dependencias
	(recomendado): Modulo.new({ players = env.Players, dataStoreService = env.DataStoreService, ... }).
]]

-- En un init.luau, "./" apunta al directorio padre: los hijos se piden con @self.
local Clock = require("@self/Clock")
local Signal = require("@self/Signal")
local EnumMock = require("@self/Enum")
local PlayersMock = require("@self/Players")
local RunServiceMock = require("@self/RunService")
local DataStoreServiceMock = require("@self/DataStoreService")
local MarketplaceServiceMock = require("@self/MarketplaceService")

local Mocks = {
	Clock = Clock,
	Signal = Signal,
	Enum = EnumMock,
	Players = PlayersMock,
	RunService = RunServiceMock,
	DataStoreService = DataStoreServiceMock,
	MarketplaceService = MarketplaceServiceMock,
}

--[[
	options:
	  clock = { startTime = 0, epoch = 1700000000 }
	  dataStore = { latency, enforceBudgets, enforceWriteCooldown }
	  marketplace = { autoApprove, placeId, currencySpent }
	  runService = { isServer, isStudio }
	  placeId, jobId
]]
function Mocks.new(options)
	local opts = options or {}
	local clock = Clock.new(opts.clock)
	local players = PlayersMock.new({ clock = clock, enum = EnumMock })
	local dsOptions = table.clone(opts.dataStore or {})
	dsOptions.clock = clock
	dsOptions.players = players
	local mpOptions = table.clone(opts.marketplace or {})
	mpOptions.clock = clock
	mpOptions.enum = EnumMock
	mpOptions.placeId = mpOptions.placeId or opts.placeId
	local rsOptions = table.clone(opts.runService or {})
	rsOptions.clock = clock

	local env = {
		clock = clock,
		task = clock.task,
		Enum = EnumMock,
		Players = players,
		RunService = RunServiceMock.new(rsOptions),
		DataStoreService = DataStoreServiceMock.new(dsOptions),
		MarketplaceService = MarketplaceServiceMock.new(mpOptions),
	}

	local services = {
		Players = env.Players,
		RunService = env.RunService,
		DataStoreService = env.DataStoreService,
		MarketplaceService = env.MarketplaceService,
	}
	env.game = {
		PlaceId = opts.placeId or 1,
		GameId = opts.gameId or 1,
		JobId = opts.jobId or "mock-job-id",
		GetService = function(_, name: string)
			local service = services[name]
			if service == nil then
				error("[mocks] servicio no simulado: " .. tostring(name) .. " (anadelo en Mocks.new o env.game.services)", 2)
			end
			return service
		end,
		services = services,
	}

	--[[
		Intenta exponer `Enum`, `game` y `task` como globales para codigo escrito para Roblox
		que los usa directamente. Depende de que el runtime permita modificar el entorno global
		(en Lune, getfenv(0)); devuelve true si lo logro. Si devuelve false, usa inyeccion.
		`restore` devuelve los valores previos.
	]]
	function env:installGlobals(replaceTask: boolean?)
		local okEnv, globalEnv = pcall(getfenv, 0)
		if not okEnv or type(globalEnv) ~= "table" then
			return false
		end
		local previous = { Enum = globalEnv.Enum, game = globalEnv.game, task = globalEnv.task }
		local okSet = pcall(function()
			globalEnv.Enum = env.Enum
			globalEnv.game = env.game
			if replaceTask then
				globalEnv.task = env.task
			end
		end)
		if not okSet then
			return false
		end
		env.restoreGlobals = function()
			globalEnv.Enum = previous.Enum
			globalEnv.game = previous.game
			globalEnv.task = previous.task
		end
		return true
	end

	return env
end

return Mocks
