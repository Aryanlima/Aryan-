--!strict
--[[
	UI: helpers para construir interfaces POR CODIGO, mobile-first, con paneles reutilizables de
	tienda y de probabilidades.

	Principios:
	  * Movil primero: botones grandes (alto >= 56 px), texto >= 16 pt, tamanos con escala + UISizeConstraint,
	    listas con ScrollingFrame y AutomaticCanvasSize.
	  * Tienda honesta: textos neutros ("Ver compra"), sin temporizadores ni "oferta", sin presion. Los
	    precios los pone el servidor (Roblox); aqui solo se muestran, marcando con "~" los aproximados.
	  * Probabilidades: panel con TODOS los resultados, columna "Ahora" y "Base", total y nota de pity;
	    se abre con un boton con TEXTO ("Probabilidades"), no solo un icono.
	  * Sin dependencias de otros paquetes (los tipos de las vistas son estructurales, compatibles con
	    Odds.DisplayView y Shop.Offer).
	  * Textos: cada texto propio del paquete tiene una CLAVE (`ui.close`, `ui.reason.owned`...) y un texto por defecto en
	    espanol. `UI.setTranslator(t)` lo sustituye por un traductor (packages/Locale); sin traductor funciona igual en
	    espanol. Las ofertas pueden traer `nameKey`/`descriptionKey`/`textArgs` para traducirse; sin ellos se usa `name`.
	  * Las instancias se tipan como `any` porque se crean por nombre de clase (frontera con el motor).
	    Las funciones puras (formatNumber, formatDuration, ...) no tocan el motor y se prueban con Lune.
	    Los constructores aceptan un entorno inyectable (UI.setEnvironment) para probarlos con la
	    libreria roblox de Lune (tests/UI.spec.luau).
]]

export type OddsRow = {
	id: string,
	label: string,
	rarity: string?,
	percentText: string,
	basePercentText: string,
}

export type OddsView = {
	rows: { OddsRow },
	totalPercentText: string,
	baseTotalPercentText: string,
	luck: number,
	luckActive: boolean,
	pityNote: string?,
	decimals: number,
}

export type OfferView = {
	kind: string,
	key: string,
	name: string,
	description: string,
	nameKey: string?, -- clave traducible del nombre (si hay traductor); `name` es el respaldo
	descriptionKey: string?,
	textArgs: { [string]: any }?,
	priceRobux: number?,
	priceIsApproximate: boolean,
	available: boolean,
	reason: string?,
	owned: boolean,
}

export type Environment = {
	Instance: any,
	UDim2: any,
	UDim: any,
	Color3: any,
	ColorSequence: any,
	Vector2: any,
	Enum: any,
	task: any?,
}

export type Translate = (key: string, args: { [string]: any }?) -> string

export type Handle = {
	root: any,
	update: (view: any) -> (),
	destroy: () -> (),
}

local UI = {}

----------------------------------------------------------------------------
-- Tema (valores crudos; los Color3 se crean al construir)
----------------------------------------------------------------------------

UI.theme = {
	colors = {
		background = { 20, 28, 44 },
		panel = { 30, 42, 68 },
		row = { 42, 64, 92 },
		text = { 240, 245, 255 },
		textMuted = { 170, 185, 210 },
		accent = { 46, 196, 241 },
		accentText = { 255, 255, 255 },
		disabled = { 80, 90, 110 },
		positive = { 90, 200, 140 },
		water = { 46, 196, 241 },
		wood = { 201, 138, 75 },
		gold = { 255, 200, 61 },
		coral = { 255, 90, 95 },
		-- colores de rareza (nombres = rarezas del juego)
		Common = { 190, 200, 210 },
		Uncommon = { 110, 210, 130 },
		Rare = { 90, 160, 255 },
		Epic = { 180, 110, 255 },
		Legendary = { 255, 190, 70 },
		Mythic = { 255, 100, 130 },
	} :: { [string]: { number } },
	minTouchHeight = 56, -- px: objetivo tactil minimo recomendado
	textSize = 18,
	titleSize = 24,
	corner = 12,
	padding = 12,
}

----------------------------------------------------------------------------
-- Textos (traducibles)
----------------------------------------------------------------------------

-- Textos por defecto (espanol) del paquete, con marcadores {nombre}. Un juego los sustituye con UI.setTranslator.
local DEFAULT_TEXT: { [string]: string } = {
	["ui.close"] = "Cerrar",
	["shop.title"] = "Tienda",
	["ui.odds_title"] = "Probabilidades",
	["ui.price"] = "R$ {price}",
	["ui.price_approx"] = "~R$ {price}",
	["ui.price_unavailable"] = "Precio no disponible",
	["ui.buy"] = "Ver compra",
	["ui.reason.owned"] = "Ya lo tienes",
	["ui.reason.unavailable"] = "No disponible por ahora",
	["ui.reason.loading"] = "Cargando tus datos...",
	["ui.reason.restricted"] = "No disponible en tu region",
	["ui.reason.left"] = "No disponible",
	["ui.reason.cooldown"] = "Espera un momento",
	["ui.reason.maxed"] = "Ya tienes el maximo acumulado",
	["ui.reason.unknown"] = "No disponible",
	["ui.odds_luck_default"] = "Tu suerte activa cambia estas probabilidades. La columna 'base' muestra los valores sin suerte.",
	["ui.odds_with_base"] = "{percent} (base {base})",
	["ui.odds_total"] = "Total: {total}",
	["ui.odds_rounding"] = "Los porcentajes estan redondeados para sumar exactamente {total}.",
}

local translator: Translate? = nil

-- Sustituye los textos por defecto por un traductor (p. ej. Locale:translator(...)). nil restablece el espanol por defecto.
function UI.setTranslator(newTranslator: Translate?)
	translator = newTranslator
end

local function tr(key: string, args: { [string]: any }?): string
	local active = translator
	if active ~= nil then
		return active(key, args)
	end
	local template = DEFAULT_TEXT[key] or key
	local result = string.gsub(template, "{[%a_][%w_]*}", function(placeholder: string): string
		local value = if args ~= nil then args[string.sub(placeholder, 2, -2)] else nil
		if value == nil then
			return placeholder
		end
		return tostring(value)
	end)
	return result
end

-- Nombre/descripcion de una oferta: traducidos por clave si hay traductor; si no, el texto que trae la oferta.
local function offerText(offer: OfferView, field: string): string
	local key = if field == "name" then offer.nameKey else offer.descriptionKey
	if translator ~= nil and key ~= nil then
		return translator(key, offer.textArgs)
	end
	return if field == "name" then offer.name else offer.description
end

----------------------------------------------------------------------------
-- Funciones puras
----------------------------------------------------------------------------

-- 999 -> "999", 1234 -> "1.2K", 1500000 -> "1.5M". Nunca lanza; no finitos -> "0".
function UI.formatNumber(value: number): string
	if value ~= value or value == math.huge or value == -math.huge then
		return "0"
	end
	local sign = if value < 0 then "-" else ""
	local absolute = math.abs(value)
	local suffixes: { { value: number, suffix: string } } = {
		{ value = 1e12, suffix = "T" },
		{ value = 1e9, suffix = "B" },
		{ value = 1e6, suffix = "M" },
		{ value = 1e3, suffix = "K" },
	}
	for _, entry in suffixes do
		if absolute >= entry.value then
			local scaled = absolute / entry.value
			local text = string.format("%.1f", scaled)
			text = string.gsub(text, "%.0$", "")
			return sign .. text .. entry.suffix
		end
	end
	return sign .. tostring(math.floor(absolute + 0.5))
end

-- 75 -> "1:15", 3725 -> "1:02:05", 90000 -> "1d 1h". Para temporizadores EXACTOS (sin redondeos a favor).
function UI.formatDuration(seconds: number): string
	if seconds ~= seconds or seconds < 0 then
		return "0:00"
	end
	local total = math.floor(seconds)
	if total >= 86400 then
		local days = total // 86400
		local hours = (total % 86400) // 3600
		return string.format("%dd %dh", days, hours)
	end
	local hours = total // 3600
	local minutes = (total % 3600) // 60
	local secs = total % 60
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	end
	return string.format("%d:%02d", minutes, secs)
end

-- Texto de precio: "R$ 199" (o "~R$ 199" si es aproximado) / "Precio no disponible".
function UI.priceText(offer: OfferView): string
	if offer.priceRobux == nil then
		return tr("ui.price_unavailable")
	end
	return tr(if offer.priceIsApproximate then "ui.price_approx" else "ui.price", { price = offer.priceRobux })
end

-- Motivo por el que una oferta no esta disponible, en lenguaje neutro.
function UI.reasonText(reason: string?): string
	local known: { [string]: boolean } = {
		owned = true,
		unavailable = true,
		loading = true,
		restricted = true,
		left = true,
		cooldown = true,
		maxed = true,
		unknown = true,
	}
	local code = reason or "unknown"
	return tr("ui.reason." .. (if known[code] then code else "unknown"))
end

-- Etiqueta del boton de compra. Neutra a proposito (ROBLOX/research/03 2.3: "View Item", nunca "BUY NOW").
function UI.buyButtonText(offer: OfferView): string
	if offer.owned then
		return tr("ui.reason.owned")
	end
	if not offer.available then
		return UI.reasonText(offer.reason)
	end
	return tr("ui.buy")
end

function UI.rarityColorName(rarity: string?): string
	if rarity ~= nil and UI.theme.colors[rarity] ~= nil then
		return rarity
	end
	return "text"
end

----------------------------------------------------------------------------
-- Entorno del motor
----------------------------------------------------------------------------

local currentEnvironment: Environment? = nil

-- Inyecta otro entorno (pruebas con la libreria roblox de Lune). nil restablece los globales de Roblox.
function UI.setEnvironment(environment: Environment?)
	currentEnvironment = environment
end

local function env(): Environment
	if currentEnvironment ~= nil then
		return currentEnvironment
	end
	local resolved: Environment = {
		Instance = Instance,
		UDim2 = UDim2,
		UDim = UDim,
		Color3 = Color3,
		Vector2 = Vector2,
		Enum = Enum,
		ColorSequence = ColorSequence,
		task = task,
	}
	currentEnvironment = resolved
	return resolved
end

local function color(name: string): any
	local triple = UI.theme.colors[name] or UI.theme.colors.text
	return env().Color3.fromRGB(triple[1], triple[2], triple[3])
end

-- Crea una instancia, asigna propiedades y hijos, y el Parent AL FINAL (mejor rendimiento y sin
-- Instance.new(clase, padre), que esta obsoleto).
function UI.create(className: string, props: { [string]: any }?, children: { any }?): any
	local instance = env().Instance.new(className)
	local parent: any = nil
	local propList: { [string]: any } = props or {}
	for key, value in propList do
		if key == "Parent" then
			parent = value
		else
			(instance :: any)[key] = value
		end
	end
	local childList: { any } = children or {}
	for _, child in childList do
		child.Parent = instance
	end
	if parent ~= nil then
		instance.Parent = parent
	end
	return instance
end

local function corner(radius: number?): any
	return UI.create("UICorner", { CornerRadius = env().UDim.new(0, radius or UI.theme.corner) })
end

local function outline(strokeColor: any?, thickness: number?): any
	return UI.create(
		"UIStroke",
		{ Color = strokeColor or color("gold"), Thickness = thickness or 2, Transparency = 0.12 }
	)
end

local function padding(amount: number?): any
	local pad = env().UDim.new(0, amount or UI.theme.padding)
	return UI.create("UIPadding", {
		PaddingTop = pad,
		PaddingBottom = pad,
		PaddingLeft = pad,
		PaddingRight = pad,
	})
end

local function listLayout(gap: number?): any
	local e = env()
	return UI.create("UIListLayout", {
		FillDirection = e.Enum.FillDirection.Vertical,
		SortOrder = e.Enum.SortOrder.LayoutOrder,
		Padding = e.UDim.new(0, gap or 8),
	})
end

----------------------------------------------------------------------------
-- Componentes
----------------------------------------------------------------------------

export type LabelOptions = {
	text: string,
	size: any?,
	textSize: number?,
	colorName: string?,
	bold: boolean?,
	alignX: any?,
	wrap: boolean?,
	parent: any?,
	layoutOrder: number?,
}

function UI.label(options: LabelOptions): any
	local e = env()
	local label = UI.create("TextLabel", {
		Text = options.text,
		Size = options.size or e.UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		TextColor3 = color(options.colorName or "text"),
		TextSize = options.textSize or UI.theme.textSize,
		Font = if options.bold then e.Enum.Font.GothamBold else e.Enum.Font.Gotham,
		TextXAlignment = options.alignX or e.Enum.TextXAlignment.Left,
		TextWrapped = options.wrap ~= false,
		AutomaticSize = if options.size == nil then e.Enum.AutomaticSize.Y else e.Enum.AutomaticSize.None,
		LayoutOrder = options.layoutOrder or 0,
		Parent = options.parent,
	})
	return label
end

export type ButtonOptions = {
	text: string,
	onActivated: (() -> ())?,
	size: any?,
	colorName: string?,
	enabled: boolean?,
	parent: any?,
	layoutOrder: number?,
}

-- Boton grande (>= 56 px de alto por defecto). Usa Activated (valido en raton, tactil y mando).
function UI.button(options: ButtonOptions): any
	local e = env()
	local enabled = options.enabled ~= false
	local button = UI.create("TextButton", {
		Text = options.text,
		Size = options.size or e.UDim2.new(1, 0, 0, UI.theme.minTouchHeight),
		BackgroundColor3 = color(if enabled then (options.colorName or "accent") else "disabled"),
		TextColor3 = color("accentText"),
		TextSize = UI.theme.textSize,
		Font = e.Enum.Font.GothamBold,
		AutoButtonColor = enabled,
		Active = enabled,
		LayoutOrder = options.layoutOrder or 0,
		Parent = options.parent,
	}, {
		corner(16),
		UI.create("UIGradient", {
			Color = e.ColorSequence.new(color("water"), color("panel")),
			Rotation = 90,
		}),
		outline(color(if enabled then (options.colorName or "gold") else "textMuted"), 2),
	})
	local callback = options.onActivated
	if callback ~= nil and enabled then
		button.Activated:Connect(function()
			callback()
		end)
	end
	return button
end

export type PanelOptions = {
	name: string,
	title: string,
	onClose: (() -> ())?,
	closeText: string?,
	maxSize: any?,
}

-- Panel centrado con titulo, boton "Cerrar" grande y zona con scroll. Devuelve (raiz, contenido).
function UI.panel(parent: any, options: PanelOptions): (any, any)
	local e = env()
	local content = UI.create("ScrollingFrame", {
		Name = "Content",
		Size = e.UDim2.new(1, 0, 1, -(UI.theme.minTouchHeight + 56)),
		Position = e.UDim2.new(0, 0, 0, 48),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = e.Enum.AutomaticSize.Y,
		CanvasSize = e.UDim2.new(0, 0, 0, 0),
	}, { listLayout(8) })

	local title = UI.label({
		text = options.title,
		size = e.UDim2.new(1, 0, 0, 40),
		textSize = UI.theme.titleSize,
		bold = true,
	})
	title.Name = "Title"

	local closeButton = UI.button({
		text = options.closeText or tr("ui.close"),
		colorName = "row",
		size = e.UDim2.new(1, 0, 0, UI.theme.minTouchHeight),
		onActivated = options.onClose,
	})
	closeButton.Name = "Close"
	closeButton.AnchorPoint = e.Vector2.new(0, 1)
	closeButton.Position = e.UDim2.new(0, 0, 1, 0)

	local root = UI.create("Frame", {
		Name = options.name,
		AnchorPoint = e.Vector2.new(0.5, 0.5),
		Position = e.UDim2.fromScale(0.5, 0.5),
		Size = e.UDim2.fromScale(0.92, 0.86),
		BackgroundColor3 = color("panel"),
		BorderSizePixel = 0,
		Visible = true,
	}, {
		corner(16),
		outline(color("gold"), 2),
		padding(),
		-- limite en pantallas grandes (tablet / PC)
		UI.create("UISizeConstraint", { MaxSize = options.maxSize or e.Vector2.new(560, 720) }),
		title,
		content,
		closeButton,
	})
	root.Parent = parent
	return root, content
end

-- Fila de oferta de la tienda.
local function offerRow(offer: OfferView, onBuy: (kind: string, key: string) -> (), order: number): any
	local e = env()
	local buyText = UI.buyButtonText(offer)
	local interactive = offer.available and not offer.owned
	return UI.create("Frame", {
		Name = offer.kind .. "_" .. offer.key,
		Size = e.UDim2.new(1, 0, 0, 0),
		AutomaticSize = e.Enum.AutomaticSize.Y,
		BackgroundColor3 = color("row"),
		BorderSizePixel = 0,
		LayoutOrder = order,
	}, {
		corner(),
		outline(color("water"), 1.5),
		padding(),
		listLayout(6),
		UI.label({ text = offerText(offer, "name"), bold = true, layoutOrder = 1 }),
		UI.label({ text = offerText(offer, "description"), colorName = "textMuted", layoutOrder = 2 }),
		UI.label({ text = UI.priceText(offer), colorName = "positive", bold = true, layoutOrder = 3 }),
		UI.button({
			text = buyText,
			enabled = interactive,
			layoutOrder = 4,
			onActivated = function()
				onBuy(offer.kind, offer.key)
			end,
		}),
	})
end

export type ShopPanelOptions = {
	title: string?,
	offers: { OfferView },
	onBuy: (kind: string, key: string) -> (), -- el cliente SOLO solicita; el servidor decide y abre el prompt
	onClose: (() -> ())?,
}

-- Panel de tienda reutilizable. handle.update(offers) refresca la lista.
function UI.shopPanel(parent: any, options: ShopPanelOptions): Handle
	local root, content = UI.panel(parent, {
		name = "ShopPanel",
		title = options.title or tr("shop.title"),
		onClose = options.onClose,
	})
	local function render(offers: { OfferView })
		for _, child in content:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		for index, offer in offers do
			local row = offerRow(offer, options.onBuy, index)
			row.Parent = content
		end
	end
	render(options.offers)
	return {
		root = root,
		update = function(view: any)
			render(view :: { OfferView })
		end,
		destroy = function()
			root:Destroy()
		end,
	}
end

export type OddsPanelOptions = {
	title: string?,
	view: OddsView,
	onClose: (() -> ())?,
	luckExplanation: string?, -- texto que explica el efecto numerico de la suerte (obligatorio si hay suerte activa)
}

-- Panel de probabilidades: TODOS los resultados con su porcentaje, total 100 % y nota de pity.
function UI.oddsPanel(parent: any, options: OddsPanelOptions): Handle
	local e = env()
	local root, content = UI.panel(parent, {
		name = "OddsPanel",
		title = options.title or tr("ui.odds_title"),
		onClose = options.onClose,
	})
	local function render(view: OddsView)
		for _, child in content:GetChildren() do
			if child:IsA("Frame") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		local order = 0
		local function add(instance: any)
			order += 1
			instance.LayoutOrder = order
			instance.Parent = content
		end
		if view.luckActive then
			add(UI.label({
				text = options.luckExplanation or tr("ui.odds_luck_default"),
				colorName = "textMuted",
			}))
		end
		for _, row in view.rows do
			local frame = UI.create("Frame", {
				Name = "Odds_" .. row.id,
				Size = e.UDim2.new(1, 0, 0, 44),
				BackgroundColor3 = color("row"),
				BorderSizePixel = 0,
			}, { corner(8) })
			local name = UI.label({
				text = row.label,
				size = e.UDim2.new(0.5, 0, 1, 0),
				colorName = UI.rarityColorName(row.rarity),
				bold = true,
				parent = frame,
			})
			name.Position = e.UDim2.new(0, 10, 0, 0)
			local value = UI.label({
				text = if view.luckActive
					then tr("ui.odds_with_base", { percent = row.percentText, base = row.basePercentText })
					else row.percentText,
				size = e.UDim2.new(0.5, -10, 1, 0),
				alignX = e.Enum.TextXAlignment.Right,
				textSize = 16,
				parent = frame,
			})
			value.Position = e.UDim2.new(0.5, 0, 0, 0)
			add(frame)
		end
		add(UI.label({ text = tr("ui.odds_total", { total = view.totalPercentText }), bold = true }))
		add(UI.label({
			text = tr("ui.odds_rounding", { total = view.totalPercentText }),
			colorName = "textMuted",
			textSize = 14,
		}))
		if view.pityNote ~= nil then
			add(UI.label({ text = view.pityNote, colorName = "positive" }))
		end
	end
	render(options.view)
	return {
		root = root,
		update = function(view: any)
			render(view :: OddsView)
		end,
		destroy = function()
			root:Destroy()
		end,
	}
end

-- Aviso breve (no bloquea). Desaparece solo tras `seconds`.
function UI.toast(parent: any, text: string, seconds: number?): any
	local e = env()
	local toast = UI.create("TextLabel", {
		Name = "Toast",
		-- Abajo, encima de la barra de acciones: arriba tapaba el titulo de los paneles (playtest-1).
		AnchorPoint = e.Vector2.new(0.5, 1),
		Position = e.UDim2.new(0.5, 0, 1, -130),
		Size = e.UDim2.new(0.8, 0, 0, 48),
		BackgroundColor3 = color("panel"),
		TextColor3 = color("text"),
		TextSize = UI.theme.textSize,
		Font = e.Enum.Font.GothamBold,
		Text = text,
		TextWrapped = true,
		Parent = parent,
	}, {
		corner(18),
		outline(color("gold"), 2),
		UI.create("UISizeConstraint", { MaxSize = e.Vector2.new(520, 120) }),
	})
	local scheduler = e.task
	if scheduler ~= nil then
		scheduler.delay(seconds or 3, function()
			toast:Destroy()
		end)
	end
	return toast
end

return UI
