--!strict
--[[
	Main (Script de servidor): punto de entrada de Fish & Fortune. Solo resuelve los modulos por su ruta en
	el DataModel (ver default.project.json) y arranca GameService. Nada mas.

	Mapa Rojo -> Studio:
	  ReplicatedStorage.Packages    Odds, Net, UI, Locale      (seguros para el cliente)
	  ReplicatedStorage.Shared      Balance, Strings, FishingRules, Remotes
	  ServerScriptService.ServerPackages   Data, Economy, Shop, LiveOps, Analytics   (SOLO servidor)
	  ServerScriptService.Server    este script + GameService, GameLogic, Catalog, ProductIds, Schema, WorldBuilder
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local packages = ReplicatedStorage:WaitForChild("Packages")
local shared = ReplicatedStorage:WaitForChild("Shared")
local serverPackages = ServerScriptService:WaitForChild("ServerPackages")
local server = script.Parent

local GameService = require(server:WaitForChild("GameService"))

GameService.start({
	-- paquetes compartidos
	Odds = require(packages:WaitForChild("Odds")),
	Net = require(packages:WaitForChild("Net")),
	Locale = require(packages:WaitForChild("Locale")),
	-- paquetes solo de servidor
	Data = require(serverPackages:WaitForChild("Data")),
	Economy = require(serverPackages:WaitForChild("Economy")),
	Shop = require(serverPackages:WaitForChild("Shop")),
	LiveOps = require(serverPackages:WaitForChild("LiveOps")),
	Analytics = require(serverPackages:WaitForChild("Analytics")),
	-- juego
	Balance = require(shared:WaitForChild("Balance")),
	Strings = require(shared:WaitForChild("Strings")),
	FishingRules = require(shared:WaitForChild("FishingRules")),
	Remotes = require(shared:WaitForChild("Remotes")),
	FeatureFlags = require(shared:WaitForChild("FeatureFlags")),
	GameLogic = require(server:WaitForChild("GameLogic")),
	Catalog = require(server:WaitForChild("Catalog")),
	ProductIds = require(server:WaitForChild("ProductIds")),
	Schema = require(server:WaitForChild("Schema")),
	WorldBuilder = require(server:WaitForChild("WorldBuilder")),
	StudioMemoryStore = require(server:WaitForChild("StudioMemoryStore")),
	LiveOpsDefaults = require(server:WaitForChild("LiveOpsDefaults")),
})
