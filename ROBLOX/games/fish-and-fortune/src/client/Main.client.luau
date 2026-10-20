--!strict
--[[
	Main (LocalScript): punto de entrada del cliente de Fish & Fortune. Crea la interfaz (por codigo, movil primero),
	recibe el estado del servidor y SOLO envia solicitudes. El servidor es la autoridad: nada de lo que muestra
	o pide el cliente cambia el estado por si mismo.

	Mapa Rojo -> Studio (ver default.project.json):
	  ReplicatedStorage.Packages  Odds, Net, UI
	  ReplicatedStorage.Shared    Balance, FishingRules, Remotes, ClientLogic, Store, FeatureFlags
	  StarterPlayer.StarterPlayerScripts.Client   este script + Hud, Minigame, Feedback, Menus
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local packages = ReplicatedStorage:WaitForChild("Packages") :: Instance
local shared = ReplicatedStorage:WaitForChild("Shared") :: Instance
local client = script.Parent :: Instance

-- require por instancia a traves de una funcion tipada (luau-lsp sin sourcemap no resuelve `require(instancia)`).
local requireModule: (ModuleScript) -> any = require

local function load(container: Instance, name: string): any
	return requireModule(container:WaitForChild(name) :: ModuleScript)
end

local UI = load(packages, "UI")
local Net = load(packages, "Net")
local Odds = load(packages, "Odds")
local Balance = load(shared, "Balance")
local FishingRules = load(shared, "FishingRules")
local Remotes = load(shared, "Remotes")
local ClientLogic = load(shared, "ClientLogic")
local Store = load(shared, "Store")

local gui = Instance.new("ScreenGui")
gui.Name = "FishFortune"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 5
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local remotes = ReplicatedStorage:WaitForChild(Remotes.folderName)
local net = Net.newClient(remotes)

local ctx: any = {
	player = player,
	gui = gui,
	net = net,
	store = Store.new(),
	UI = UI,
	Odds = Odds,
	Balance = Balance,
	rules = FishingRules.new(Balance, Odds),
	ClientLogic = ClientLogic,
}

ctx.feedback = load(client, "Feedback").start(ctx)
ctx.menus = load(client, "Menus").start(ctx)
ctx.minigame = load(client, "Minigame").start(ctx)
ctx.hud = load(client, "Hud").start(ctx)

-- Servidor -> cliente (solo informacion para mostrar)
net:onEvent("State", function(state: any)
	ctx.store:set(state)
end)
net:onEvent("Toast", function(text: string)
	ctx.feedback.toast(text)
end)
net:onEvent("Catch", function(payload: any)
	ctx.minigame.onCatch(payload)
	ctx.feedback.showCatch(payload)
end)
net:onEvent("Banner", function(payload: any)
	ctx.feedback.showBanner(payload)
end)
net:onEvent("CastStarted", function(payload: any)
	ctx.minigame.onCastStarted(payload)
end)
net:onEvent("CastFailed", function(reason: string)
	ctx.minigame.onCastFailed(reason)
	local text = ClientLogic.failureText(reason)
	if text ~= nil then
		ctx.feedback.toast(text)
	end
end)
net:onEvent("Offers", function(offers: any)
	ctx.menus.onOffers(offers)
end)

net:fire("RequestState")
