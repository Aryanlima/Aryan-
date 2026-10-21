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
local packages = ReplicatedStorage:WaitForChild("Packages")
local shared = ReplicatedStorage:WaitForChild("Shared")
local client = script.Parent

-- `require(instancia:WaitForChild("Nombre"))`: luau-lsp lo resuelve con el sourcemap de Rojo (ver tools/lint.sh) y tipa cada
-- modulo; un nombre que no exista en default.project.json es un error del analisis, no un fallo al jugar.
local UI = require(packages:WaitForChild("UI"))
local Net = require(packages:WaitForChild("Net"))
local Odds = require(packages:WaitForChild("Odds"))
local Locale = require(packages:WaitForChild("Locale"))
local Balance = require(shared:WaitForChild("Balance"))
local Strings = require(shared:WaitForChild("Strings"))
local FishingRules = require(shared:WaitForChild("FishingRules"))
local Remotes = require(shared:WaitForChild("Remotes"))
local ClientLogic = require(shared:WaitForChild("ClientLogic"))
local Store = require(shared:WaitForChild("Store"))
local Feedback = require(client:WaitForChild("Feedback"))
local Menus = require(client:WaitForChild("Menus"))
local Minigame = require(client:WaitForChild("Minigame"))
local Hud = require(client:WaitForChild("Hud"))
local Audio = require(client:WaitForChild("Audio"))

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
-- oculta, no esta en los tipos de luau-lsp). Sin dato valido => el idioma por defecto de Strings (EN).
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

-- La carpeta la crea el servidor al arrancar (GameService). Si el arranque del servidor fallo (mira SU consola), no llega
-- nunca: con tiempo limite el cliente lo dice claro en vez de quedarse mudo con un "Infinite yield possible".
local remotes = ReplicatedStorage:WaitForChild(Remotes.folderName, 30)
if remotes == nil then
	error("[FishFortune] el servidor no creo los remotos en 30 s (mira su consola)", 0)
end
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

ctx.feedback = Feedback.start(ctx)
ctx.menus = Menus.start(ctx)
ctx.minigame = Minigame.start(ctx)
ctx.hud = Hud.start(ctx)

-- Servidor -> cliente (solo informacion para mostrar)
net:onEvent("State", function(state: any)
	ctx.store:set(state)
end)
net:onEvent("Toast", function(message: any)
	if type(message) == "table" then
		if message.key == "toast.sold" then
			Audio.play("sell")
		elseif message.key == "toast.rod_bought" then
			Audio.play("buy")
		end
	end
	local text = messageText(message)
	if text ~= nil then
		ctx.feedback.toast(text)
	end
end)
net:onEvent("Catch", function(payload: any)
	Audio.play("catch")
	ctx.minigame.onCatch(payload)
	ctx.feedback.showCatch(payload)
end)
net:onEvent("Banner", function(message: any)
	local text = messageText(message)
	if text ~= nil then
		if
			type(message) == "table"
			and type(message.key) == "string"
			and string.find(message.key, "banner.mythic", 1, true) == 1
		then
			Audio.play("rare")
		end
		ctx.feedback.showBanner(text)
	end
end)
net:onEvent("CastStarted", function(payload: any)
	Audio.play("splash")
	if type(payload) == "table" and type(payload.bite) == "number" and payload.bite >= 0 then
		task.delay(payload.bite, function()
			Audio.play("bite")
		end)
	end
	ctx.minigame.onCastStarted(payload)
end)
net:onEvent("CastFailed", function(reason: string)
	Audio.play("escape")
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
