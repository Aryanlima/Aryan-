--!strict
--[[
	Hud: interfaz principal, movil primero. Monedas/perlas/mochila arriba a la izquierda, boton grande de
	LANZAR/RECOGER y VENDER abajo, menus a la derecha (Tienda, Canas, Bestiario, Temporada, Probabilidades y
	Codigos), eventos activos con cuenta atras EXACTA y la guia del tutorial (primeros 60 s).

	Todo lo que muestra viene del ultimo estado del servidor (Store); los botones solo envian solicitudes.
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
	local gui: ScreenGui = ctx.gui

	----------------------------------------------------------------------------
	-- Estadisticas (arriba a la izquierda)
	----------------------------------------------------------------------------
	local stats = UI.create("Frame", {
		Name = "Stats",
		Position = UDim2.new(0, 10, 0, 10),
		Size = UDim2.new(0, 230, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = rgb(UI.theme.colors.panel),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Parent = gui,
	}, {
		UI.create("UICorner", { CornerRadius = UDim.new(0, 12) }),
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
			textSize = 18,
			bold = true,
			colorName = colorName,
			layoutOrder = order,
			parent = stats,
		})
	end
	local coinsLabel = statLabel(1, "Legendary")
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
		colorName = "positive",
		parent = gui,
	})
	eventsLabel.Name = "Events"
	eventsLabel.AnchorPoint = Vector2.new(0.5, 0)
	eventsLabel.Position = UDim2.new(0.5, 0, 0, 10)
	eventsLabel.AutomaticSize = Enum.AutomaticSize.Y

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
	local actionButton = UI.button({
		text = "LANZAR",
		size = UDim2.new(0.62, 0, 1, 0),
		onActivated = function()
			minigame.action()
		end,
		parent = actionBar,
	})
	actionButton.Name = "ActionButton"
	actionButton.TextSize = 26
	local sellButton = UI.button({
		text = "VENDER",
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

	----------------------------------------------------------------------------
	-- Menus (derecha)
	----------------------------------------------------------------------------
	local menuColumn = UI.create("ScrollingFrame", {
		Name = "Menu",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.46, 0),
		Size = UDim2.new(0, 132, 0.62, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = gui,
	}, { UI.create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }) })

	local menuButtons: { [string]: TextButton } = {}
	local function menuButton(order: number, id: string, text: string)
		local button = UI.button({
			text = text,
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
	menuButton(1, "shop", "Tienda")
	menuButton(2, "rods", "Canas")
	menuButton(3, "bestiary", "Bestiario")
	menuButton(4, "season", "Temporada")
	menuButton(5, "odds", "Probabilidades")
	menuButton(6, "codes", "Codigos")

	local autoButton = UI.button({
		text = "Auto-pesca: NO",
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
		if modifiers.coins then
			table.insert(parts, ("monedas x%s"):format(tostring(modifiers.coins)))
		end
		if modifiers.luck then
			table.insert(parts, ("suerte +%s"):format(tostring(modifiers.luck)))
		end
		return table.concat(parts, ", ")
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
				("%s (%s): %s"):format(event.name, modifiersText(event.modifiers), UI.formatDuration(remaining))
			)
		end
		eventsLabel.Text = table.concat(lines, "\n")
	end

	local function refreshAction()
		local state = store:get()
		actionButton.Text = if minigame.isCasting() then "RECOGER" else "LANZAR"
		actionButton.BackgroundColor3 = if minigame.isCasting()
			then rgb(UI.theme.colors.positive)
			else rgb(UI.theme.colors.accent)
		if state ~= nil then
			local hint = ClientLogic.ftueHint(state, balance, minigame.isCasting())
			if hint ~= nil then
				hintLabel.Text = hint.text
				hintLabel.Visible = true
				hintStroke.Parent = hintTargets[hint.target]
			else
				hintLabel.Visible = false
				hintStroke.Parent = nil
			end
		end
	end

	local function refresh(state: any)
		coinsLabel.Text = "Monedas: " .. UI.formatNumber(state.coins)
		pearlsLabel.Text = "Perlas: " .. UI.formatNumber(state.pearls)
		bagLabel.Text = ("Mochila: %d / %d"):format(state.inventoryCount, state.capacity)
		zoneLabel.Text = balance.zones[state.zone].name .. (if state.isPrivateServer then " - Servidor privado" else "")
		autoButton.Visible = state.passes.auto_fish == true
		autoButton.Text = if state.autoFish then "Auto-pesca: SI" else "Auto-pesca: NO"
		sellButton.Text = if state.inventoryCount > 0 then ("VENDER (%d)"):format(state.inventoryCount) else "VENDER"
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
