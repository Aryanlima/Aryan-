--!strict
--[[
	Main (LocalScript): punto de entrada del cliente de Fish & Fortune. Crea la interfaz (por codigo, movil primero),
	recibe el estado del servidor y SOLO envia solicitudes. El servidor es la autoridad: nada de lo que muestra
	o pide el cliente cambia el estado por si mismo.

	Idioma: ES y EN completos; EN por defecto (respaldo). Se elige por jugador con el LocaleId de Roblox (LocalizationService.RobloxLocaleId) y se
	vuelve a leer en cada texto. El servidor no envia texto sino CLAVES; aqui se validan (Locale.sanitizeMessage) y se traducen.

	Mapa Rojo -> Studio (ver default.project.json):
	  ReplicatedStorage.Packages  Odds, Net, UI, Locale
	  ReplicatedStorage.Shared    Balance, Strings, FishingRules, Remotes, ClientLogic, Store, FeatureFlags
	  StarterPlayer.StarterPlayerScripts.Client   este script + Hud, Minigame, Feedback, Menus
]]

local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

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
local Locale = load(packages, "Locale")
local Balance = load(shared, "Balance")
local Strings = load(shared, "Strings")
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
-- Los textos los localiza el juego (Strings); la traduccion automatica de Roblox no debe volver a tocarlos.
gui.AutoLocalize = false
gui.Parent = playerGui

----------------------------------------------------------------------------
-- Idioma y textos
----------------------------------------------------------------------------
local locale = Locale.new(Strings)

-- Idioma soportado del jugador. VERIFY: LocalizationService.RobloxLocaleId ("es-es", "en-us"...; solo lectura, no cede)
-- viene de la documentacion oficial pero no se ha probado en Studio. Alternativa documentada: Player.LocaleId (propiedad
-- oculta, no esta en los tipos de luau-lsp). Sin dato valido => ES.
local function currentLanguage(): string
	local ok, localeId = pcall(function(): string
		return LocalizationService.RobloxLocaleId
	end)
	return locale:resolveLanguage(if ok then localeId else nil)
end

local translate = locale:translator(currentLanguage)
UI.setTranslator(translate)

-- Texto de un mensaje { key, args } enviado por el servidor (toast, banner): solo claves y argumentos de la lista blanca.
local function messageText(message: any): string?
	local key, args = locale:sanitizeMessage(message)
	if key == nil or type(args) ~= "table" then
		return nil
	end
	return translate(key, args)
end

-- Clave recibida del servidor dentro de un estado u oferta: solo si empieza por un prefijo permitido y existe.
local function safeKey(key: any, prefixes: { string }, args: any?): (string?, { [string]: any }?)
	local cleanKey, cleanArgs = locale:sanitizeMessage(
		{ key = key, args = args },
		{ prefixes = prefixes, lenient = true }
	)
	if cleanKey == nil or type(cleanArgs) ~= "table" then
		return nil, nil
	end
	return cleanKey, cleanArgs
end

-- Texto libre del servidor (p. ej. el nombre de un evento de la configuracion remota): solo cadenas UTF-8 validas y cortas.
local function serverText(value: any, fallback: string): string
	if type(value) == "string" and value ~= "" and #value <= 100 and utf8.len(value) ~= nil then
		return value
	end
	return fallback
end

local fmt = {
	compact = function(value: number): string
		return locale:compact(currentLanguage(), value)
	end,
	number = function(value: number): string
		return locale:number(currentLanguage(), value)
	end,
	percent = function(text: string): string
		return locale:percent(currentLanguage(), text)
	end,
}

-- Rotulos del mundo (cartel de cada zona): el servidor los crea con texto en espanol y la clave en el atributo LocaleKey.
-- VERIFY: no probado en Studio (replicacion/streaming de Workspace.World).
local function localizeSign(instance: Instance)
	if instance:IsA("TextLabel") then
		local key = instance:GetAttribute("LocaleKey")
		if type(key) == "string" and locale:has(key) then
			instance.Text = translate(key)
		end
	end
end

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
	-- textos
	locale = locale,
	language = currentLanguage,
	L = translate,
	fmt = fmt,
	messageText = messageText,
	safeKey = safeKey,
	serverText = serverText,
}

ctx.feedback = load(client, "Feedback").start(ctx)
ctx.menus = load(client, "Menus").start(ctx)
ctx.minigame = load(client, "Minigame").start(ctx)
ctx.hud = load(client, "Hud").start(ctx)

-- Servidor -> cliente (solo informacion para mostrar)
net:onEvent("State", function(state: any)
	ctx.store:set(state)
end)
net:onEvent("Toast", function(message: any)
	local text = messageText(message)
	if text ~= nil then
		ctx.feedback.toast(text)
	end
end)
net:onEvent("Catch", function(payload: any)
	ctx.minigame.onCatch(payload)
	ctx.feedback.showCatch(payload)
end)
net:onEvent("Banner", function(message: any)
	local text = messageText(message)
	if text ~= nil then
		ctx.feedback.showBanner(text)
	end
end)
net:onEvent("CastStarted", function(payload: any)
	ctx.minigame.onCastStarted(payload)
end)
net:onEvent("CastFailed", function(reason: string)
	ctx.minigame.onCastFailed(reason)
	local key = ClientLogic.failureKey(reason)
	if key ~= nil then
		ctx.feedback.toast(translate(key))
	end
end)
net:onEvent("Offers", function(offers: any)
	ctx.menus.onOffers(offers)
end)

-- Cartel de cada zona en el idioma del jugador (y los que lleguen despues por streaming).
local world = Workspace:FindFirstChild("World")
if world ~= nil then
	for _, descendant in world:GetDescendants() do
		localizeSign(descendant)
	end
end
Workspace.DescendantAdded:Connect(localizeSign)

net:fire("RequestState")
