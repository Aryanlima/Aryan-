--!strict
--[[
	Menus: paneles de la interfaz (tienda, canas y zonas, bestiario, temporada, codigos y probabilidades).
	Solo presentacion y solicitudes: cada boton envia una peticion al servidor, que valida y decide.

	Cumplimiento visible en la UI:
	  * Probabilidades: se abre con un boton con TEXTO ("Probabilidades"), muestra TODOS los resultados de la zona
	    con su porcentaje (suma 100 %), la columna "base" y el desglose de la suerte activa.
	  * Tienda: textos neutros ("Ver compra"); los precios son los de Roblox (con "~" si son aproximados).
]]

local Menus = {}

local function rgb(triple: { number }): Color3
	return Color3.fromRGB(triple[1], triple[2], triple[3])
end

type ButtonSpec = { text: string, enabled: boolean?, onClick: (() -> ())? }

function Menus.start(ctx: any): any
	local UI = ctx.UI
	local net = ctx.net
	local store = ctx.store
	local balance = ctx.Balance
	local rules = ctx.rules
	local gui: ScreenGui = ctx.gui

	local current: { name: string, root: any, unsubscribe: (() -> ())? }? = nil
	local latestOffers: any = nil
	local shopHandle: any = nil
	local selectedOddsZone: string? = nil

	local function close()
		local open = current
		if open ~= nil then
			if open.unsubscribe then
				open.unsubscribe()
			end
			open.root:Destroy()
			current = nil
			shopHandle = nil
		end
	end

	local function clearContent(content: any)
		for _, child in content:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
	end

	local function addHeader(content: any, order: number, text: string)
		UI.label({
			text = text,
			textSize = 20,
			bold = true,
			layoutOrder = order,
			parent = content,
			colorName = "accent",
		})
	end

	local function addRow(
		content: any,
		order: number,
		title: string,
		subtitle: string?,
		buttons: { ButtonSpec },
		colorName: string?
	)
		local row = UI.create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = rgb(UI.theme.colors.row),
			BorderSizePixel = 0,
			LayoutOrder = order,
			Parent = content,
		}, {
			UI.create("UICorner", { CornerRadius = UDim.new(0, 12) }),
			UI.create("UIPadding", {
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
			UI.create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
		})
		UI.label({ text = title, bold = true, layoutOrder = 1, parent = row, colorName = colorName })
		if subtitle ~= nil then
			UI.label({ text = subtitle, colorName = "textMuted", layoutOrder = 2, parent = row })
		end
		for index, spec in buttons do
			UI.button({
				text = spec.text,
				enabled = spec.enabled,
				onActivated = spec.onClick,
				layoutOrder = 2 + index,
				parent = row,
			})
		end
	end

	-- Abre un panel que se redibuja con cada estado nuevo del servidor.
	local function openPanel(name: string, title: string, build: (content: any, state: any) -> ())
		close()
		local root, content = UI.panel(gui, { name = name, title = title, onClose = close })
		local function render()
			clearContent(content)
			local state = store:get()
			if state ~= nil then
				build(content, state)
			end
		end
		render()
		current = { name = name, root = root, unsubscribe = store:subscribe(render) }
	end

	----------------------------------------------------------------------------
	-- Canas y zonas
	----------------------------------------------------------------------------
	local function openRods()
		openPanel("RodsPanel", "Canas y zonas", function(content: any, state: any)
			local order = 0
			local function nextOrder(): number
				order += 1
				return order
			end
			addHeader(content, nextOrder(), "Canas")
			for _, rodId in balance.rodOrder do
				local rod = balance.rods[rodId]
				local owned = state.ownedRods[rodId] == true
				local equipped = state.rod == rodId
				local subtitle = ("Suerte +%s - zona perfecta %d%% - auto cada %ds"):format(
					tostring(rod.luck),
					math.floor(rod.sweetSpot * 100 + 0.5),
					rod.autoInterval
				)
				local button: ButtonSpec
				if equipped then
					button = { text = "Equipada", enabled = false }
				elseif owned then
					button = {
						text = "Equipar",
						onClick = function()
							net:fire("EquipRod", rodId)
						end,
					}
				else
					button = {
						text = "Comprar - " .. UI.formatNumber(rod.price) .. " monedas",
						enabled = state.coins >= rod.price,
						onClick = function()
							net:fire("BuyRod", rodId)
						end,
					}
				end
				addRow(content, nextOrder(), rod.name, subtitle, { button })
			end

			addHeader(content, nextOrder(), "Zonas")
			for _, zoneId in balance.zoneOrder do
				local zone = balance.zones[zoneId]
				local unlocked = state.unlockedZones[zoneId] == true
				local button: ButtonSpec
				if state.zone == zoneId then
					button = { text = "Estas aqui", enabled = false }
				elseif unlocked then
					button = {
						text = "Viajar",
						onClick = function()
							net:fire("TravelZone", zoneId)
						end,
					}
				else
					button = {
						text = "Desbloquear - " .. UI.formatNumber(zone.unlockCost) .. " monedas",
						enabled = state.coins >= zone.unlockCost,
						onClick = function()
							net:fire("UnlockZone", zoneId)
						end,
					}
				end
				addRow(content, nextOrder(), zone.name, zone.description, { button })
			end

			addHeader(content, nextOrder(), "Mochila")
			local maxed = state.capacity >= balance.inventory.maxSlots
			addRow(content, nextOrder(), ("Espacio: %d / %d"):format(state.inventoryCount, state.capacity), nil, {
				{
					text = ("Ampliar +%d con %d perlas"):format(
						balance.inventory.slotsPerPack,
						balance.inventory.pearlsPerSlotPack
					),
					enabled = not maxed and state.pearls >= balance.inventory.pearlsPerSlotPack,
					onClick = function()
						net:fire("BuySlotsWithPearls")
					end,
				},
			})
			if state.passes.vip then
				addRow(content, nextOrder(), "Pase VIP", ("Perlas diarias: +%d"):format(balance.vip.dailyPearls), {
					{
						text = if state.dailyAvailable then "Reclamar perlas de hoy" else "Ya reclamadas hoy",
						enabled = state.dailyAvailable == true,
						onClick = function()
							net:fire("ClaimDaily")
						end,
					},
				})
			end
		end)
	end

	----------------------------------------------------------------------------
	-- Bestiario
	----------------------------------------------------------------------------
	local function openBestiary()
		openPanel("BestiaryPanel", "Bestiario", function(content: any, state: any)
			local order = 0
			local function nextOrder(): number
				order += 1
				return order
			end
			addHeader(content, nextOrder(), ("Descubiertas: %d / %d"):format(state.discoveries, #balance.creatures))
			for _, zoneId in balance.zoneOrder do
				addHeader(content, nextOrder(), balance.zones[zoneId].name)
				for _, creature in rules:creaturesOf(zoneId) do
					local count = state.bestiary[creature.id]
					local found = count ~= nil
					local text = if found
						then ("%s  x%d  (%s)"):format(creature.name, count, balance.rarities[creature.rarity].label)
						else "???"
					UI.label({
						text = text,
						colorName = if found then UI.rarityColorName(creature.rarity) else "textMuted",
						bold = found,
						layoutOrder = nextOrder(),
						parent = content,
					})
				end
			end
			addHeader(content, nextOrder(), "Recompensas")
			for _, reward in balance.bestiary.rewards do
				local claimed = state.bestiaryClaimed[reward.id] == true
				local reached = false
				if reward.kind == "zone" then
					reached = true
					for _, creature in rules:creaturesOf(reward.zone) do
						if state.bestiary[creature.id] == nil then
							reached = false
						end
					end
				else
					reached = state.discoveries >= reward.target
				end
				local parts = {}
				if reward.reward.coins then
					table.insert(parts, UI.formatNumber(reward.reward.coins) .. " monedas")
				end
				if reward.reward.pearls then
					table.insert(parts, reward.reward.pearls .. " perlas")
				end
				addRow(content, nextOrder(), reward.label, table.concat(parts, " + "), {
					{
						text = if claimed then "Reclamada" elseif reached then "Reclamar" else "Aun no",
						enabled = reached and not claimed,
						onClick = function()
							net:fire("ClaimBestiary", reward.id)
						end,
					},
				})
			end
		end)
	end

	----------------------------------------------------------------------------
	-- Temporada
	----------------------------------------------------------------------------
	local function rewardText(reward: any): string
		local parts = {}
		if reward.coins then
			table.insert(parts, UI.formatNumber(reward.coins) .. " monedas")
		end
		if reward.pearls then
			table.insert(parts, reward.pearls .. " perlas")
		end
		if reward.slots then
			table.insert(parts, reward.slots .. " espacios")
		end
		return table.concat(parts, " + ")
	end

	local function openSeason()
		openPanel("SeasonPanel", "Temporada", function(content: any, state: any)
			local season = state.season
			local order = 0
			local function nextOrder(): number
				order += 1
				return order
			end
			if season == nil then
				UI.label({
					text = "No hay una temporada activa ahora mismo.",
					layoutOrder = nextOrder(),
					parent = content,
				})
				return
			end
			local remaining =
				ctx.ClientLogic.remainingSeconds(season.endsAt, state.serverNow, store:receivedAt(), os.clock())
			addHeader(content, nextOrder(), season.name)
			UI.label({
				text = ("Puntos: %d - termina en %s"):format(season.points, UI.formatDuration(remaining)),
				layoutOrder = nextOrder(),
				parent = content,
			})
			if not state.passes.season_pass then
				addRow(content, nextOrder(), "Pista premium", "Premios fijos, sin azar. Pase de Temporada.", {
					{
						text = "Ver Pase de Temporada",
						onClick = function()
							net:fire("RequestPurchase", "pass", "season_pass")
						end,
					},
				})
			end
			for _, tier in balance.season.tiers do
				local reached = season.points >= tier.points
				local key = "t" .. tostring(tier.tier)
				local freeClaimed = season.claimedFree[key] == true
				local premiumClaimed = season.claimedPremium[key] == true
				addRow(content, nextOrder(), ("Nivel %d - %d puntos"):format(tier.tier, tier.points), nil, {
					{
						text = ("Gratis: %s - %s"):format(
							rewardText(tier.free),
							if freeClaimed then "reclamada" elseif reached then "reclamar" else "bloqueada"
						),
						enabled = reached and not freeClaimed,
						onClick = function()
							net:fire("ClaimSeason", tier.tier, "free")
						end,
					},
					{
						text = ("Premium: %s - %s"):format(
							rewardText(tier.premium),
							if premiumClaimed then "reclamada" elseif reached then "reclamar" else "bloqueada"
						),
						enabled = reached and not premiumClaimed and state.passes.season_pass == true,
						onClick = function()
							net:fire("ClaimSeason", tier.tier, "premium")
						end,
					},
				})
			end
		end)
	end

	----------------------------------------------------------------------------
	-- Codigos
	----------------------------------------------------------------------------
	local function openCodes()
		close()
		local root, content = UI.panel(gui, { name = "CodesPanel", title = "Codigos", onClose = close })
		UI.label({
			text = "Escribe un codigo y pulsa Canjear. Cada codigo se puede usar una vez.",
			layoutOrder = 1,
			parent = content,
		})
		local box = Instance.new("TextBox")
		box.Name = "CodeBox"
		box.PlaceholderText = "CODIGO"
		box.Text = ""
		box.ClearTextOnFocus = false
		box.Size = UDim2.new(1, 0, 0, UI.theme.minTouchHeight)
		box.BackgroundColor3 = rgb(UI.theme.colors.row)
		box.TextColor3 = rgb(UI.theme.colors.text)
		box.PlaceholderColor3 = rgb(UI.theme.colors.textMuted)
		box.Font = Enum.Font.GothamBold
		box.TextSize = 22
		box.LayoutOrder = 2
		box.Parent = content
		UI.create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = box })
		UI.button({
			text = "Canjear",
			layoutOrder = 3,
			parent = content,
			onActivated = function()
				local text = string.upper(string.match(box.Text, "^%s*(.-)%s*$") or "")
				if text ~= "" then
					net:fire("RedeemCode", string.sub(text, 1, 32))
					box.Text = ""
				end
			end,
		})
		current = { name = "codes", root = root, unsubscribe = nil }
	end

	----------------------------------------------------------------------------
	-- Probabilidades (cumplimiento: TODOS los resultados, suma 100 %, base y suerte visibles)
	----------------------------------------------------------------------------
	local function openOdds(zoneId: string?)
		local state = store:get()
		if state == nil then
			return
		end
		close()
		local zone = zoneId or selectedOddsZone or state.zone
		selectedOddsZone = zone
		local view = rules:oddsFor(zone):displayRows({ luck = state.luck })
		local handle = UI.oddsPanel(gui, {
			title = "Probabilidades - " .. balance.zones[zone].name,
			view = view,
			onClose = close,
			luckExplanation = "Tu suerte activa cambia estas probabilidades. La columna 'base' muestra los valores sin suerte. "
				.. "Un lanzamiento perfecto suma ademas +"
				.. tostring(balance.minigame.perfectLuck)
				.. " de suerte gratis.",
		})
		local content = handle.root:FindFirstChild("Content")
		if content ~= nil then
			-- pestanas de zona
			local tabs = UI.create("Frame", {
				Name = "ZoneTabs",
				Size = UDim2.new(1, 0, 0, UI.theme.minTouchHeight),
				BackgroundTransparency = 1,
				LayoutOrder = -3,
				Parent = content,
			}, {
				UI.create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
				}),
			})
			for index, id in balance.zoneOrder do
				UI.button({
					text = balance.zones[id].name,
					colorName = if id == zone then "accent" else "row",
					size = UDim2.new(1 / #balance.zoneOrder, -6, 1, 0),
					layoutOrder = index,
					parent = tabs,
					onActivated = function()
						openOdds(id)
					end,
				})
			end
			-- desglose de la suerte activa
			local lines =
				{ ("Suerte total activa: +%s (tope %d)"):format(tostring(state.luck), balance.limits.maxLuck) }
			for _, source in state.luckSources do
				if source.active then
					table.insert(
						lines,
						("- %s: +%s%s"):format(
							source.label,
							tostring(source.value),
							if source.paid then " (de pago)" else ""
						)
					)
				end
			end
			UI.label({ text = table.concat(lines, "\n"), layoutOrder = -2, parent = content })
			if state.totalCasts < #balance.ftue.guaranteedRarities then
				UI.label({ text = balance.ftue.oddsNote, colorName = "positive", layoutOrder = -1, parent = content })
			end
			if state.paidRandomRestricted then
				UI.label({
					text = "En tu region los objetos aleatorios de pago estan restringidos: no se ofrecen ni se aplican.",
					colorName = "textMuted",
					layoutOrder = 0,
					parent = content,
				})
			end
		end
		local lastLuck = state.luck
		current = {
			name = "odds",
			root = handle.root,
			unsubscribe = store:subscribe(function(newState: any)
				if newState.luck ~= lastLuck then
					lastLuck = newState.luck
					openOdds(zone)
				end
			end),
		}
	end

	----------------------------------------------------------------------------
	-- Tienda
	----------------------------------------------------------------------------
	local function openShop()
		close()
		net:fire("RequestOffers")
		local handle = UI.shopPanel(gui, {
			title = "Tienda",
			offers = latestOffers or {},
			onBuy = function(kind: string, key: string)
				net:fire("RequestPurchase", kind, key)
			end,
			onClose = close,
		})
		local content = handle.root:FindFirstChild("Content")
		if content ~= nil then
			UI.label({
				text = "Los precios los define Roblox. Cada compra se confirma en la ventana de Roblox.",
				colorName = "textMuted",
				textSize = 14,
				layoutOrder = -1,
				parent = content,
			})
		end
		shopHandle = handle
		current = { name = "shop", root = handle.root, unsubscribe = nil }
	end

	local function open(name: string)
		if current ~= nil and current.name == name then
			close()
			return
		end
		if name == "shop" then
			openShop()
		elseif name == "rods" then
			openRods()
		elseif name == "bestiary" then
			openBestiary()
		elseif name == "season" then
			openSeason()
		elseif name == "codes" then
			openCodes()
		elseif name == "odds" then
			selectedOddsZone = nil
			openOdds(nil)
		end
	end

	local function onOffers(offers: any)
		latestOffers = offers
		if shopHandle ~= nil then
			shopHandle.update(offers)
		end
	end

	return { open = open, close = close, onOffers = onOffers }
end

return Menus
