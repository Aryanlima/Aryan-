--!strict
--[[
	Main (Script de servidor): punto de entrada de Fish & Fortune. Solo resuelve los modulos por su ruta en
	el DataModel (ver default.project.json) y arranca GameService. Nada mas.

	Mapa Rojo -> Studio:
	  ReplicatedStorage.Packages    Odds, Net, UI, Locale, Art   (seguros para el cliente)
	  ReplicatedStorage.Shared      Balance, Strings, FishingRules, Remotes, ArtProfiles
	  ServerScriptService.ServerPackages   Data, Economy, Shop, LiveOps, Analytics   (SOLO servidor)
	  ServerScriptService.Server    este script + GameService, GameLogic, Catalog, ProductIds, Schema, WorldBuilder, ArtDirector
	  ServerStorage.Art             plantillas de arte generado: Art/<categoria>/<id> (ver README, seccion Arte)
]]

local Debris = game:GetService("Debris")
local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local packages = ReplicatedStorage:WaitForChild("Packages")
local shared = ReplicatedStorage:WaitForChild("Shared")
local serverPackages = ServerScriptService:WaitForChild("ServerPackages")
local server = script.Parent

local GameService = require(server:WaitForChild("GameService"))

-- Arte generado con IA (opcional). Las plantillas viven en ServerStorage.Art/<categoria>/<id> (no se replican al cliente);
-- los MaterialVariant, en MaterialService con el prefijo FF_. Sin plantillas (o rechazadas por la validacion) todo es procedural.
local Balance = require(shared:WaitForChild("Balance"))
local ArtProfiles = require(shared:WaitForChild("ArtProfiles"))
local ArtPackage = require(packages:WaitForChild("Art"))
local ArtDirector = require(server:WaitForChild("ArtDirector"))

local artRoots: { Instance } = {}
local artRoot = ServerStorage:FindFirstChild(ArtProfiles.rootName)
if artRoot ~= nil then
	table.insert(artRoots, artRoot)
end
local artProvider = ArtPackage.new({
	roots = artRoots,
	profiles = ArtProfiles.build(Balance),
	materialRoot = MaterialService,
	log = warn,
})
local artDirector = ArtDirector.create({
	provider = artProvider,
	rarityOrder = function(rarity: string): number?
		local info = Balance.rarities[rarity]
		return if info ~= nil then info.order else nil
	end,
	container = Workspace,
	showcase = ArtProfiles.showcase,
	debris = Debris,
	clock = os.clock,
	spawn = task.spawn,
	wait = task.wait,
	log = print,
})

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
	Balance = Balance,
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
	ArtDirector = artDirector,
})
