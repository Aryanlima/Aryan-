--!strict
--[[
	Main (Script de servidor): punto de entrada de Fish & Fortune. Solo resuelve los modulos por su ruta en
	el DataModel (ver default.project.json) y arranca GameService. Nada mas.

	Mapa Rojo -> Studio:
	  ReplicatedStorage.Packages    Odds, Net, UI              (seguros para el cliente)
	  ReplicatedStorage.Shared      Balance, FishingRules, Remotes
	  ServerScriptService.ServerPackages   Data, Economy, Shop, LiveOps, Analytics   (SOLO servidor)
	  ServerScriptService.Server    este script + GameService, GameLogic, Catalog, ProductIds, Schema, WorldBuilder
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local packages = ReplicatedStorage:WaitForChild("Packages") :: Instance
local shared = ReplicatedStorage:WaitForChild("Shared") :: Instance
local serverPackages = ServerScriptService:WaitForChild("ServerPackages") :: Instance
local server = script.Parent :: Instance

-- require por instancia a traves de una funcion tipada: luau-lsp, sin sourcemap, no sabe resolver
-- `require(instancia)` y marca "Unknown require"; asi el analisis queda limpio y el comportamiento es identico.
local requireModule: (ModuleScript) -> any = require

local function load(container: Instance, name: string): any
	return requireModule(container:WaitForChild(name) :: ModuleScript)
end

local GameService = load(server, "GameService")

GameService.start({
	-- paquetes compartidos
	Odds = load(packages, "Odds"),
	Net = load(packages, "Net"),
	-- paquetes solo de servidor
	Data = load(serverPackages, "Data"),
	Economy = load(serverPackages, "Economy"),
	Shop = load(serverPackages, "Shop"),
	LiveOps = load(serverPackages, "LiveOps"),
	Analytics = load(serverPackages, "Analytics"),
	-- juego
	Balance = load(shared, "Balance"),
	FishingRules = load(shared, "FishingRules"),
	Remotes = load(shared, "Remotes"),
	GameLogic = load(server, "GameLogic"),
	Catalog = load(server, "Catalog"),
	ProductIds = load(server, "ProductIds"),
	Schema = load(server, "Schema"),
	WorldBuilder = load(server, "WorldBuilder"),
	StudioMemoryStore = load(server, "StudioMemoryStore"),
})
