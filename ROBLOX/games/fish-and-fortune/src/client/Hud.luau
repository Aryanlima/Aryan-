--!strict
--[[
	Hud: interfaz principal, movil primero. Monedas/perlas/mochila arriba a la izquierda, boton grande de
	LANZAR/RECOGER y VENDER abajo, menus a la derecha (Tienda, Canas, Bestiario, Temporada, Probabilidades y
	Codigos), eventos activos con cuenta atras EXACTA y la guia del tutorial (primeros 60 s).

	Todo lo que muestra viene del ultimo estado del servidor (Store); los botones solo envian solicitudes.
	Textos: todos por clave (ctx.L, shared/Strings.luau) en el idioma del jugador; se reponen en cada refresco, asi un cambio de
	idioma se aplica solo.
]]

local TweenService = game:GetService("TweenService")

local Hud = {}

local function rgb(triple: { number }): Color3
	return Color3.fromRGB(triple[1], triple[2], triple[3])
end

function Hud.start(ctx: any): any
	local UI = ctx.UI
	local net = ctx.net
	local store = ctx.store
	local balance = ctx.Balance
	local menus = ctx.menus
	local minigame = ctx.minigame
	local ClientLogic = ctx.ClientLogic
	local L = ctx.L
	local fmt = ctx.fmt
	local gui: ScreenGui = ctx.gui

	----------------------------------------------------------------------------
	-- Estadisticas (izquierda, centradas en vertical: arriba las tapaba la ventana del chat)
	----------------------------------------------------------------------------
	local stats = UI.create("Frame", {
		Name = "Stats",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.42, 0),
		Size = UDim2.new(0, 230, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = rgb(UI.theme.colors.panel),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Parent = gui,
	}, {
		UI.create("UICorner", { CornerRadius = UDim.new(0, 18) }),
		UI.create("UIStroke", { Color = rgb(UI.theme.colors.water), Thickness = 2, Transparency = 0.12 }),
		UI.create("UISizeConstraint", { MaxSize = Vector2.new(250, 220) }),
		UI.create("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
		UI.create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }),
	})
	local function statLabel(order: number, colorName: string?): TextLabel
		return UI.label({
			text = "",
			size = UDim2.new(1, 0, 0, 24),
			textSize = if order == 1 then 26 else 18,
			bold = true,
			colorName = colorName,
			layoutOrder = order,
			parent = stats,
		})
	end
	local coinsLabel = statLabel(1, "gold")
	local pearlsLabel = statLabel(2, "Rare")
	local bagLabel = statLabel(3, nil)
	local zoneLabel = statLabel(4, "textMuted")

	----------------------------------------------------------------------------
	-- Eventos activos (arriba al centro)
	----------------------------------------------------------------------------
	local eventsLabel = UI.label({
		text = "",
		size = UDim2.new(0.5, 0, 0, 0),
		textSize = 16,
		alignX = Enum.TextXAlignment.Center,
		colorName = "gold",
		bold = true,
		parent = gui,
	})
	eventsLabel.Name = "Events"
	eventsLabel.AnchorPoint = Vector2.new(0.5, 0)
	eventsLabel.Position = UDim2.new(0.5, 0, 0, 10)
	eventsLabel.AutomaticSize = Enum.AutomaticSize.Y
	-- Pildora oscura: el texto verde sobre el cielo casi no se leia (playtest-1).
	eventsLabel.BackgroundColor3 = rgb(UI.theme.colors.panel)
	eventsLabel.BackgroundTransparency = 0.15
	UI.create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = eventsLabel })
	UI.create("UIStroke", {
		Color = rgb(UI.theme.colors.gold),
		Thickness = 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = eventsLabel,
	})
	UI.create("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = eventsLabel,
	})

	----------------------------------------------------------------------------
	-- Barra de acciones (abajo)
	----------------------------------------------------------------------------
	local actionBar = UI.create("Frame", {
		Name = "ActionBar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.new(0.9, 0, 0, 72),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { UI.create("UISizeConstraint", { MaxSize = Vector2.new(560, 80) }) })
	local actionScale = Instance.new("UIScale")
	actionScale.Scale = 0.82
	actionScale.Parent = actionBar
	TweenService:Create(actionScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()
	local actionButton = UI.button({
		text = L("hud.cast"),
		size = UDim2.new(0.62, 0, 1, 0),
		onActivated = function()
			minigame.action()
		end,
		parent = actionBar,
	})
	actionButton.Name = "ActionButton"
	actionButton.TextSize = 26
	local sellButton = UI.button({
		text = L("hud.sell"),
		colorName = "positive",
		size = UDim2.new(0.36, 0, 1, 0),
		onActivated = function()
			net:fire("SellAll")
		end,
		parent = actionBar,
	})
	sellButton.Name = "SellButton"
	sellButton.Position = UDim2.new(0.64, 0, 0, 0)
	sellButton.TextSize = 22
	for _, button in { actionButton, sellButton } do
		local scale = Instance.new("UIScale")
		scale.Parent = button
		button.Activated:Connect(function()
			TweenService:Create(scale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Scale = 0.94,
			}):Play()
			task.delay(0.09, function()
				if button.Parent ~= nil then
					TweenService:Create(scale, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
						Scale = 1,
					}):Play()
				end
			end)
		end)
	end

	----------------------------------------------------------------------------
	-- Menus (derecha)
	----------------------------------------------------------------------------
	local menuColumn = UI.create("ScrollingFrame", {
		Name = "Menu",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.46, 0),
		Size = UDim2.new(0, 144, 0.62, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = gui,
	}, { UI.create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }) })

	local menuButtons: { [string]: TextButton } = {}
	local menuKeys: { [string]: string } = {}
	local function menuButton(order: number, id: string, key: string)
		menuKeys[id] = key
		local button = UI.button({
			text = L(key),
			colorName = "row",
			size = UDim2.new(1, -6, 0, UI.theme.minTouchHeight),
			layoutOrder = order,
			onActivated = function()
				menus.open(id)
			end,
			parent = menuColumn,
		})
		button.TextSize = 16
		menuButtons[id] = button
	end
	menuButton(1, "shop", "menu.shop")
	menuButton(2, "rods", "menu.rods")
	menuButton(3, "bestiary", "menu.bestiary")
	menuButton(4, "season", "menu.season")
	menuButton(5, "odds", "menu.odds")
	menuButton(6, "codes", "menu.codes")

	local autoButton = UI.button({
		text = L("hud.auto_off"),
		colorName = "row",
		size = UDim2.new(1, -6, 0, UI.theme.minTouchHeight),
		layoutOrder = 7,
		onActivated = function()
			local state = store:get()
			if state ~= nil then
				net:fire("SetAutoFish", not state.autoFish)
			end
		end,
		parent = menuColumn,
	})
	autoButton.TextSize = 16
	autoButton.Visible = false

	----------------------------------------------------------------------------
	-- Guia del tutorial (FTUE)
	----------------------------------------------------------------------------
	local hintLabel = UI.label({
		text = "",
		size = UDim2.new(0.9, 0, 0, 40),
		textSize = 20,
		bold = true,
		alignX = Enum.TextXAlignment.Center,
		colorName = "Legendary",
		parent = gui,
	})
	hintLabel.Name = "Hint"
	hintLabel.AnchorPoint = Vector2.new(0.5, 1)
	hintLabel.Position = UDim2.new(0.5, 0, 1, -96)
	hintLabel.Visible = false
	local hintStroke = Instance.new("UIStroke")
	hintStroke.Name = "HintStroke"
	hintStroke.Color = rgb(UI.theme.colors.Legendary)
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

	local function refreshTimers()
		local state = store:get()
		if state == nil then
			return
		end
		local lines = {}
		for _, event in state.events do
			local remaining =
				ClientLogic.remainingSeconds(event.endsAt, state.serverNow, store:receivedAt(), os.clock())
			table.insert(
				lines,
				L("hud.event_line", {
					name = eventName(event),
					effects = modifiersText(event.modifiers),
					time = UI.formatDuration(remaining),
				})
			)
		end
		eventsLabel.Text = table.concat(lines, "\n")
		eventsLabel.Visible = #lines > 0
	end

	local function refreshAction()
		local state = store:get()
		actionButton.Text = if minigame.isCasting() then L("hud.reel") else L("hud.cast")
		actionButton.BackgroundColor3 = if minigame.isCasting()
			then rgb(UI.theme.colors.positive)
			else rgb(UI.theme.colors.accent)
		if state ~= nil then
			local hint = ClientLogic.ftueHint(state, balance, minigame.isCasting())
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

	local function refresh(state: any)
		for id, button in menuButtons do
			button.Text = L(menuKeys[id])
		end
		coinsLabel.Text = L("hud.coins", { amount = fmt.compact(state.coins) })
		pearlsLabel.Text = "💎 " .. L("hud.pearls", { amount = fmt.compact(state.pearls) })
		bagLabel.Text = L("hud.bag", { used = state.inventoryCount, capacity = state.capacity })
		local zoneName = L("zone." .. state.zone .. ".name")
		zoneLabel.Text = if state.isPrivateServer then L("hud.zone_private", { zone = zoneName }) else zoneName
		autoButton.Visible = state.passes.auto_fish == true
		autoButton.Text = if state.autoFish then L("hud.auto_on") else L("hud.auto_off")
		sellButton.Text = if state.inventoryCount > 0
			then L("hud.sell_count", { count = state.inventoryCount })
			else L("hud.sell")
		refreshTimers()
		refreshAction()
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
