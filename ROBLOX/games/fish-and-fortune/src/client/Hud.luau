--!strict
--[[
	Hud: interfaz principal, movil primero, estilo "Muelle de madera". Cartera a la izquierda (monedas, perlas,
	mochila), nombre de la zona y eventos arriba al centro, boton grande de LANZAR/RECOGER y VENDER abajo, menus a la
	derecha (Tienda, Canas, Bestiario, Temporada, Probabilidades y Codigos) y la guia del tutorial (primeros 60 s).

	Todo lo que muestra viene del ultimo estado del servidor (Store); los botones solo envian solicitudes.
	Textos: todos por clave (ctx.L, shared/Strings.luau) en el idioma del jugador; se reponen en cada refresco, asi un cambio de
	idioma se aplica solo. Jugo: contadores que suben y saltan, barra de mochila, entrada escalonada, pulso mientras se espera la picada.
]]

local TweenService = game:GetService("TweenService")

local Hud = {}

local function rgb(triple: { number }): Color3
	return Color3.fromRGB(triple[1], triple[2], triple[3])
end

function Hud.start(ctx: any): any
	local UI = ctx.UI
	local motion = UI.motion
	local net = ctx.net
	local store = ctx.store
	local balance = ctx.Balance
	local menus = ctx.menus
	local minigame = ctx.minigame
	local ClientLogic = ctx.ClientLogic
	local L = ctx.L
	local fmt = ctx.fmt
	local gui: ScreenGui = ctx.gui
	local colors = UI.theme.colors

	----------------------------------------------------------------------------
	-- Cartera (izquierda, centrada en vertical: arriba la tapaba la ventana del chat)
	----------------------------------------------------------------------------
	local stats = UI.create("Frame", {
		Name = "Stats",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 26, 0.5, 0),
		Size = UDim2.new(0, 190, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		UI.create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12) }),
	})

	-- Tabla de madera con el icono grande saliendo por la izquierda. Devuelve (tabla, borde).
	local function pill(order: number, iconName: string, height: number): (Frame, UIStroke)
		local frame = UI.create("Frame", {
			Name = iconName .. "Pill",
			Size = UDim2.new(1, 0, 0, height),
			BackgroundColor3 = rgb(colors.wood),
			BorderSizePixel = 0,
			LayoutOrder = order,
			Parent = stats,
		}, {
			UI.create("UICorner", { CornerRadius = UDim.new(0, 14) }),
			UI.create("Frame", {
				Name = "Grain",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 36, 0.5, 0),
				Size = UDim2.new(1, -44, 0, 3),
				BackgroundColor3 = rgb(colors.woodGrain),
				BorderSizePixel = 0,
				ZIndex = 1,
			}),
		})
		local stroke: UIStroke = UI.create("UIStroke", {
			Color = rgb(colors.woodDark),
			Thickness = 3,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = frame,
		})
		UI.icon(iconName, 54, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, -18, 0.5, 0),
			ZIndex = 3,
			Parent = frame,
		})
		return frame, stroke
	end
	local function pillLabel(parent: Frame, height: number, textSize: number): TextLabel
		local label = UI.label({
			text = "",
			size = UDim2.new(1, -46, 0, height),
			textSize = textSize,
			display = true,
			parent = parent,
		})
		label.Position = UDim2.new(0, 42, 0, 0)
		label.ZIndex = 4
		label.TextTruncate = Enum.TextTruncate.AtEnd
		return label
	end

	local coinsPill, coinsStroke = pill(1, "Coin", 48)
	local coinsLabel = pillLabel(coinsPill, 48, 26)
	local pearlsPill, pearlsStroke = pill(2, "Pearl", 48)
	local pearlsLabel = pillLabel(pearlsPill, 48, 26)
	local bagPill, bagStroke = pill(3, "Bag", 60)
	local bagLabel = pillLabel(bagPill, 38, 24)
	local bagTrack = UI.create("Frame", {
		Name = "BagTrack",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 42, 1, -9),
		Size = UDim2.new(1, -54, 0, 9),
		BackgroundColor3 = rgb(colors.woodDark),
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = bagPill,
	}, { UI.create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local bagFill = UI.create("Frame", {
		Name = "BagFill",
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = rgb(colors.positive),
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = bagTrack,
	}, { UI.create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	----------------------------------------------------------------------------
	-- Zona y eventos activos (arriba al centro)
	----------------------------------------------------------------------------
	local zoneBanner = UI.create("Frame", {
		Name = "ZoneBanner",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.new(0.5, 0, 0, 52),
		BackgroundColor3 = rgb(colors.woodDark),
		BorderSizePixel = 0,
		Parent = gui,
	}, {
		UI.create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		UI.create("UIStroke", {
			Color = rgb(colors.ink),
			Thickness = 3,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		UI.create("UISizeConstraint", { MinSize = Vector2.new(190, 52), MaxSize = Vector2.new(300, 52) }),
	})
	local zoneLabel = UI.label({
		text = "",
		size = UDim2.new(1, -16, 1, 0),
		textSize = 28,
		display = true,
		alignX = Enum.TextXAlignment.Center,
		parent = zoneBanner,
	})
	zoneLabel.Position = UDim2.new(0, 8, 0, 0)
	zoneLabel.TextTruncate = Enum.TextTruncate.AtEnd

	-- Eventos activos: una tabla de madera por evento en el borde derecho, encima del menu.
	local eventsHolder = UI.create("Frame", {
		Name = "Events",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.new(0, 212, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	}, {
		UI.create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
		}),
	})
	local plaques: { [string]: { frame: Frame, stroke: UIStroke, time: TextLabel, effects: TextLabel, name: TextLabel } } = {}
	local plaqueOrder = 0

	-- Bienvenida (una vez por sesion, ver refresh).
	local welcomed = false
	local function showWelcome()
		local banner = UI.create("CanvasGroup", {
			Name = "Welcome",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 70),
			Size = UDim2.new(0.7, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = rgb(colors.woodDark),
			BorderSizePixel = 0,
			ZIndex = 20,
			Parent = gui,
		}, {
			UI.create("UICorner", { CornerRadius = UDim.new(0, 16) }),
			UI.create("UIStroke", { Color = rgb(colors.gold), Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
			UI.create("UISizeConstraint", { MaxSize = Vector2.new(520, 200) }),
			UI.create("UIPadding", {
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
			}),
			UI.create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }),
		})
		UI.label({
			text = L("hud.welcome_title"),
			textSize = 30,
			display = true,
			alignX = Enum.TextXAlignment.Center,
			colorName = "gold",
			layoutOrder = 1,
			parent = banner,
		})
		UI.label({
			text = L("hud.welcome_hint"),
			textSize = 18,
			alignX = Enum.TextXAlignment.Center,
			layoutOrder = 2,
			parent = banner,
		})
		motion.appear(banner, 0.7, 0.35)
		task.delay(4, function()
			motion.tween(banner, { GroupTransparency = 1 }, 0.5)
			task.delay(0.6, function()
				banner:Destroy()
			end)
		end)
	end

	----------------------------------------------------------------------------
	-- Barra de acciones (abajo)
	----------------------------------------------------------------------------
	local actionBar = UI.create("Frame", {
		Name = "ActionBar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.new(0.9, 0, 0, 76),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { UI.create("UISizeConstraint", { MaxSize = Vector2.new(560, 84) }) })
	motion.appear(actionBar, 0.82, 0.3)

	local function bigButton(text: string, colorName: string, iconName: string, textSize: number, onActivated: () -> ())
		local button = UI.button({
			text = text,
			colorName = colorName,
			onActivated = onActivated,
			parent = actionBar,
		})
		button.TextSize = textSize
		button.TextStrokeTransparency = 1 -- el contorno lo da el UIStroke, que sigue la forma de la letra
		UI.create("UIStroke", {
			Color = rgb(colors.ink),
			Thickness = 2.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			Parent = button,
		})
		UI.create("UIPadding", { PaddingLeft = UDim.new(0, 72), Parent = button })
		UI.icon(iconName, 52, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, -62, 0.5, -2), -- el UIPadding de arriba desplaza a los hijos: -72 + 10
			Parent = button,
		})
		return button
	end
	local actionButton = bigButton(L("hud.cast"), "accent", "Cast", 30, function()
		minigame.action()
	end)
	actionButton.Name = "ActionButton"
	actionButton.Size = UDim2.new(0.62, 0, 1, 0)
	local pulseScale = UI.create("UIScale", { Name = "PulseScale", Scale = 1, Parent = actionButton })
	local sellButton = bigButton(L("hud.sell"), "positive", "Sell", 24, function()
		net:fire("SellAll")
	end)
	sellButton.Name = "SellButton"
	sellButton.Size = UDim2.new(0.36, 0, 1, 0)
	sellButton.Position = UDim2.new(0.64, 0, 0, 0)

	----------------------------------------------------------------------------
	-- Menus (derecha): cuadricula de 2 columnas con icono y rotulo
	----------------------------------------------------------------------------
	local menuColumn = UI.create("ScrollingFrame", {
		Name = "Menu",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 78),
		Size = UDim2.new(0, 190, 0.55, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = gui,
	}, {
		UI.create("UIGridLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			CellSize = UDim2.fromOffset(72, 64),
			CellPadding = UDim2.fromOffset(6, 6),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
		}),
		UI.create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingRight = UDim.new(0, 6) }),
	})

	-- El rotulo va en el Text del boton (abajo); el tamano baja si el texto es largo (ES: "Probabilidades").
	local function setMenuText(button: TextButton, text: string)
		button.Text = text
		button.TextSize = math.clamp(math.floor(68 / (utf8.len(text) or #text) / 0.62), 10, 15)
	end

	local function menuButton(order: number, iconName: string, text: string, onActivated: () -> ()): TextButton
		local button = UI.button({
			text = "",
			colorName = "wood",
			layoutOrder = order,
			onActivated = onActivated,
			parent = menuColumn,
		})
		button.TextYAlignment = Enum.TextYAlignment.Bottom
		button.TextStrokeTransparency = 1
		UI.create("UIStroke", {
			Color = rgb(colors.ink),
			Thickness = 2,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			Parent = button,
		})
		UI.create("UIPadding", { PaddingBottom = UDim.new(0, 5), Parent = button })
		UI.icon(iconName, 36, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 4),
			Parent = button,
		})
		setMenuText(button, text)
		return button
	end

	local menuButtons: { [string]: TextButton } = {}
	local menuKeys: { [string]: string } = {}
	local menuIcons = { shop = "Shop", rods = "Rods", bestiary = "Bestiary", season = "Season", odds = "Odds", codes = "Codes" }
	local function addMenu(order: number, id: string, key: string)
		menuKeys[id] = key
		menuButtons[id] = menuButton(order, menuIcons[id], L(key), function()
			menus.open(id)
		end)
	end
	addMenu(1, "shop", "menu.shop")
	addMenu(2, "rods", "menu.rods")
	addMenu(3, "bestiary", "menu.bestiary")
	addMenu(4, "season", "menu.season")
	addMenu(5, "odds", "menu.odds")
	addMenu(6, "codes", "menu.codes")

	local autoButton = menuButton(7, "Settings", L("hud.auto_off_short"), function()
		local state = store:get()
		if state ~= nil then
			net:fire("SetAutoFish", not state.autoFish)
		end
	end)
	autoButton.Visible = false

	----------------------------------------------------------------------------
	-- Entrada escalonada: la cartera desliza desde la izquierda y los botones del menu aparecen de 40 en 40 ms
	----------------------------------------------------------------------------
	motion.slideIn(stats, -260, 0, 0.3)
	local introIndex = 0
	for _, child in menuColumn:GetChildren() do
		if child:IsA("TextButton") then
			introIndex += 1
			if not motion.reduced then
				local scale = motion.scaleOf(child)
				scale.Scale = 0.01
				task.delay(0.04 * introIndex, function()
					motion.tween(scale, { Scale = 1 }, 0.25, "Back")
				end)
			end
		end
	end

	----------------------------------------------------------------------------
	-- Guia del tutorial (FTUE)
	----------------------------------------------------------------------------
	local hintLabel = UI.label({
		text = "",
		size = UDim2.new(0.9, 0, 0, 40),
		textSize = 22,
		display = true,
		alignX = Enum.TextXAlignment.Center,
		parent = gui,
	})
	hintLabel.Name = "Hint"
	hintLabel.AnchorPoint = Vector2.new(0.5, 1)
	hintLabel.Position = UDim2.new(0.5, 0, 1, -98)
	hintLabel.Visible = false
	local hintStroke = Instance.new("UIStroke")
	hintStroke.Name = "HintStroke"
	hintStroke.Color = rgb(colors.Legendary)
	hintStroke.Thickness = 4
	TweenService:Create(
		hintStroke,
		TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.7 }
	):Play()
	local hintTargets: { [string]: GuiObject } = {
		cast = actionButton,
		sell = sellButton,
		rods = menuButtons.rods,
		bestiary = menuButtons.bestiary,
	}

	----------------------------------------------------------------------------
	-- Refresco
	----------------------------------------------------------------------------
	local function modifiersText(modifiers: { [string]: number }): string
		local parts = {}
		if type(modifiers.coins) == "number" then
			table.insert(parts, L("hud.effect_coins", { value = modifiers.coins }))
		end
		if type(modifiers.luck) == "number" then
			table.insert(parts, L("hud.effect_luck", { value = modifiers.luck }))
		end
		return table.concat(parts, ", ")
	end

	-- Nombre del evento: con clave propia en Strings (event.<id>.name) se traduce; si viene de la configuracion remota sin
	-- traduccion, se muestra el nombre configurado.
	local function eventName(event: any): string
		local key = "event." .. tostring(event.id) .. ".name"
		if ctx.locale:has(key) then
			return L(key)
		end
		return ctx.serverText(event.name, "?")
	end

	local function makePlaque(id: string, halloween: boolean)
		plaqueOrder += 1
		local base = if halloween then rgb(colors.Epic) else rgb(colors.woodDark)
		local frame = UI.create("Frame", {
			Name = "Event_" .. id,
			Size = UDim2.new(1, 0, 0, 66),
			BackgroundColor3 = if halloween then rgb(colors.gold):Lerp(rgb(colors.coral), 0.5) else rgb(colors.wood),
			BorderSizePixel = 0,
			LayoutOrder = plaqueOrder,
			Parent = eventsHolder,
		}, { UI.create("UICorner", { CornerRadius = UDim.new(0, 14) }) })
		local stroke: UIStroke = UI.create("UIStroke", {
			Color = base,
			Thickness = 3,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = frame,
		})
		UI.icon("Season", 40, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, -14, 0.5, 0),
			ZIndex = 3,
			Parent = frame,
		})
		local function line(y: number, h: number, size: number, display: boolean, colorName: string): TextLabel
			local label = UI.label({
				text = "",
				size = UDim2.new(1, -30, 0, h),
				textSize = size,
				display = display,
				colorName = colorName,
				alignX = Enum.TextXAlignment.Right,
				parent = frame,
			})
			label.Position = UDim2.new(0, 24, 0, y)
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.ZIndex = 4
			return label
		end
		local plaque = {
			frame = frame,
			stroke = stroke,
			name = line(4, 20, 16, true, "text"),
			time = line(21, 30, 26, true, "gold"),
			effects = line(50, 14, 12, false, "ink"),
		}
		plaques[id] = plaque
		motion.appear(frame, 0.6, 0.3)
		-- Brillo que late mientras el evento esta activo.
		motion.tween(stroke, { Color = rgb(colors.gold) }, 0.9, "Sine", "InOut", -1, true)
		return plaque
	end

	local function refreshTimers()
		local state = store:get()
		if state == nil then
			return
		end
		local seen: { [string]: boolean } = {}
		for _, event in state.events do
			local id = tostring(event.id)
			seen[id] = true
			local plaque = plaques[id] or makePlaque(id, id == "halloween_harvest")
			local remaining =
				ClientLogic.remainingSeconds(event.endsAt, state.serverNow, store:receivedAt(), os.clock())
			plaque.name.Text = eventName(event)
			plaque.time.Text = UI.formatDuration(remaining)
			plaque.effects.Text = modifiersText(event.modifiers)
		end
		for id, plaque in plaques do
			if not seen[id] then
				plaques[id] = nil
				motion.tween(plaque.stroke, { Color = rgb(colors.woodDark) }, 0.01)
				motion.pop(plaque.frame, 1.2)
				task.delay(0.3, function()
					plaque.frame:Destroy()
				end)
			end
		end
		eventsHolder.Visible = next(seen) ~= nil
	end

	local pulsing = false
	local function setPulse(on: boolean)
		if on == pulsing then
			return
		end
		pulsing = on
		if on and not motion.reduced then
			motion.tween(pulseScale, { Scale = 1.04 }, 0.8, "Sine", "InOut", -1, true)
		else
			motion.tween(pulseScale, { Scale = 1 }, 0.15)
		end
	end

	local function refreshAction()
		local state = store:get()
		local casting = minigame.isCasting()
		actionButton.Text = if casting then L("hud.reel") else L("hud.cast")
		sellButton.Visible = not casting
		motion.tween(actionButton, { BackgroundColor3 = rgb(if casting then colors.positive else colors.accent) }, 0.2)
		local castIcon = actionButton:FindFirstChild("CastIcon")
		if castIcon ~= nil then
			castIcon.Visible = not casting
		end
		setPulse(casting and not minigame.isBiting())
		if state ~= nil then
			local hint = ClientLogic.ftueHint(state, balance, casting)
			if hint ~= nil then
				local waiting = hint.id == "reel" and not minigame.isBiting()
				hintLabel.Text = L(if waiting then "hint.wait_bite" else hint.key)
				hintLabel.Visible = true
				hintStroke.Parent = hintTargets[hint.target]
			else
				hintLabel.Visible = false
				hintStroke.Parent = nil
			end
		end
	end

	-- Contador que sube (con salto y destello dorado) o baja (sacudida y destello coral).
	local function changeNumber(label: TextLabel, holder: Frame, stroke: UIStroke, previous: number?, value: number)
		local function show(amount: number): string
			return fmt.compact(amount)
		end
		if previous == nil or previous == value then
			if previous == nil then
				label.Text = show(value)
			end
			return
		end
		motion.countUp(label, previous, value, show, 0.45)
		local up = value > previous
		if up then
			motion.pop(holder, 1.1)
		else
			motion.shake(label, 5)
		end
		motion.tween(stroke, { Color = rgb(if up then colors.gold else colors.coral) }, 0.08)
		task.delay(0.35, function()
			if stroke.Parent ~= nil then
				motion.tween(stroke, { Color = rgb(colors.woodDark) }, 0.3)
			end
		end)
	end

	local shownCoins: number? = nil
	local shownPearls: number? = nil
	local bagFull = false
	local function refresh(state: any)
		for id, button in menuButtons do
			setMenuText(button, L(menuKeys[id]))
		end
		changeNumber(coinsLabel, coinsPill, coinsStroke, shownCoins, state.coins)
		shownCoins = state.coins
		changeNumber(pearlsLabel, pearlsPill, pearlsStroke, shownPearls, state.pearls)
		shownPearls = state.pearls
		bagLabel.Text = string.format("%d / %d", state.inventoryCount, state.capacity)
		local full = state.capacity > 0 and state.inventoryCount >= state.capacity
		motion.tween(
			bagFill,
			{
				Size = UDim2.new(math.clamp(state.inventoryCount / math.max(1, state.capacity), 0, 1), 0, 1, 0),
				BackgroundColor3 = rgb(if full then colors.coral else colors.positive),
			},
			0.3,
			"Quad"
		)
		if full ~= bagFull then
			bagFull = full
			if full and not motion.reduced then
				motion.tween(bagStroke, { Color = rgb(colors.coral) }, 0.5, "Sine", "InOut", -1, true)
			else
				motion.tween(bagStroke, { Color = rgb(if full then colors.coral else colors.woodDark) }, 0.2)
			end
		end
		local zoneName = L("zone." .. state.zone .. ".name")
		zoneLabel.Text = if state.isPrivateServer then L("hud.zone_private", { zone = zoneName }) else zoneName
		autoButton.Visible = state.passes.auto_fish == true
		setMenuText(autoButton, if state.autoFish then L("hud.auto_on_short") else L("hud.auto_off_short"))
		sellButton.Text = if state.inventoryCount > 0
			then L("hud.sell_count", { count = state.inventoryCount })
			else L("hud.sell")
		refreshTimers()
		refreshAction()
		if not welcomed then
			welcomed = true
			showWelcome()
		end
	end

	store:subscribe(refresh)
	minigame.subscribe(refreshAction)
	task.spawn(function()
		while true do
			task.wait(1)
			refreshTimers()
		end
	end)

	return { refresh = refresh }
end

return Hud
