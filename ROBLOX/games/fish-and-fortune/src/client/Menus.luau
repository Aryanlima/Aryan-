--!strict
--[[
	Menus: paneles de la interfaz (tienda, canas y zonas, bestiario, temporada, codigos y probabilidades).
	Solo presentacion y solicitudes: cada boton envia una peticion al servidor, que valida y decide.

	Cumplimiento visible en la UI:
	  * Probabilidades: se abre con un boton con TEXTO (Strings: menu.odds), muestra TODOS los resultados de la zona
	    con su porcentaje (suma 100 %), la columna "base" y el desglose de la suerte activa. Las cifras son las mismas en
	    todos los idiomas (solo cambia el separador decimal).
	  * Tienda: textos neutros (Strings: ui.buy = "Ver compra" / "View item"); los precios son los de Roblox (con "~" si son
	    aproximados).

	Textos: todos por clave (ctx.L, shared/Strings.luau) en el idioma del jugador; cada panel se vuelve a dibujar con cada
	estado del servidor, asi un cambio de idioma se aplica solo.
]]

local Menus = {}
local TweenService = game:GetService("TweenService")

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
	local L = ctx.L
	local fmt = ctx.fmt
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
			UI.create("UICorner", { CornerRadius = UDim.new(0, 16) }),
			UI.create("UIStroke", { Color = rgb(UI.theme.colors.water), Thickness = 1.5, Transparency = 0.12 }),
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
		local scale = Instance.new("UIScale")
		scale.Scale = 0.92
		scale.Parent = root
		TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1,
		}):Play()
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
		openPanel("RodsPanel", L("rods.title"), function(content: any, state: any)
			local order = 0
			local function nextOrder(): number
				order += 1
				return order
			end
			addHeader(content, nextOrder(), L("rods.header"))
			for _, rodId in balance.rodOrder do
				local rod = balance.rods[rodId]
				local owned = state.ownedRods[rodId] == true
				local equipped = state.rod == rodId
				local subtitle = L("rods.stats", {
					luck = rod.luck,
					sweet = math.floor(rod.sweetSpot * 100 + 0.5),
					interval = rod.autoInterval,
				})
				local button: ButtonSpec
				if equipped then
					button = { text = L("rods.equipped"), enabled = false }
				elseif owned then
					button = {
						text = L("rods.equip"),
						onClick = function()
							net:fire("EquipRod", rodId)
						end,
					}
				else
					button = {
						text = L("rods.buy", { price = fmt.compact(rod.price) }),
						enabled = state.coins >= rod.price,
						onClick = function()
							net:fire("BuyRod", rodId)
						end,
					}
				end
				addRow(content, nextOrder(), L("rod." .. rodId), subtitle, { button })
			end

			addHeader(content, nextOrder(), L("zones.header"))
			for _, zoneId in balance.zoneOrder do
				local zone = balance.zones[zoneId]
				local unlocked = state.unlockedZones[zoneId] == true
				local button: ButtonSpec
				if state.zone == zoneId then
					button = { text = L("zones.here"), enabled = false }
				elseif unlocked then
					button = {
						text = L("zones.travel"),
						onClick = function()
							net:fire("TravelZone", zoneId)
						end,
					}
				else
					button = {
						text = L("zones.unlock", { price = fmt.compact(zone.unlockCost) }),
						enabled = state.coins >= zone.unlockCost,
						onClick = function()
							net:fire("UnlockZone", zoneId)
						end,
					}
				end
				addRow(
					content,
					nextOrder(),
					L("zone." .. zoneId .. ".name"),
					L("zone." .. zoneId .. ".desc"),
					{ button }
				)
			end

			addHeader(content, nextOrder(), L("bag.header"))
			local maxed = state.capacity >= balance.inventory.maxSlots
			addRow(
				content,
				nextOrder(),
				L("bag.space", { used = state.inventoryCount, capacity = state.capacity }),
				nil,
				{
					{
						text = L("bag.expand", {
							slots = balance.inventory.slotsPerPack,
							pearls = balance.inventory.pearlsPerSlotPack,
						}),
						enabled = not maxed and state.pearls >= balance.inventory.pearlsPerSlotPack,
						onClick = function()
							net:fire("BuySlotsWithPearls")
						end,
					},
				}
			)
			if state.passes.vip then
				addRow(content, nextOrder(), L("pass.vip.name"), L("vip.daily", { pearls = balance.vip.dailyPearls }), {
					{
						text = if state.dailyAvailable then L("vip.claim") else L("vip.claimed"),
						enabled = state.dailyAvailable == true,
						onClick = function()
							net:fire("ClaimDaily")
						end,
					},
				})
			end
		end)
	end

	-- Premio { coins?, pearls?, slots? } como texto ("500 monedas + 5 perlas"); `count` elige singular o plural.
	local function rewardText(reward: any): string
		local parts = {}
		if reward.coins then
			table.insert(parts, L("reward.coins", { count = reward.coins, amount = fmt.compact(reward.coins) }))
		end
		if reward.pearls then
			table.insert(parts, L("reward.pearls", { count = reward.pearls, amount = fmt.compact(reward.pearls) }))
		end
		if reward.slots then
			table.insert(parts, L("reward.slots", { count = reward.slots, amount = fmt.compact(reward.slots) }))
		end
		return table.concat(parts, " + ")
	end

	----------------------------------------------------------------------------
	-- Bestiario
	----------------------------------------------------------------------------
	local function openBestiary()
		openPanel("BestiaryPanel", L("bestiary.title"), function(content: any, state: any)
			local order = 0
			local function nextOrder(): number
				order += 1
				return order
			end
			addHeader(
				content,
				nextOrder(),
				L("bestiary.found", { found = state.discoveries, total = #balance.creatures })
			)
			for _, zoneId in balance.zoneOrder do
				addHeader(content, nextOrder(), L("zone." .. zoneId .. ".name"))
				for _, creature in rules:creaturesOf(zoneId) do
					local count = state.bestiary[creature.id]
					local found = count ~= nil
					local text = if found
						then L("bestiary.entry", {
							name = { key = "creature." .. creature.id },
							count = count,
							rarity = { key = "rarity." .. creature.rarity },
						})
						else L("bestiary.unknown")
					UI.label({
						text = text,
						colorName = if found then UI.rarityColorName(creature.rarity) else "textMuted",
						bold = found,
						layoutOrder = nextOrder(),
						parent = content,
					})
				end
			end
			addHeader(content, nextOrder(), L("bestiary.rewards"))
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
				addRow(content, nextOrder(), L("bestiary.reward." .. reward.id), rewardText(reward.reward), {
					{
						text = if claimed
							then L("bestiary.claimed")
							elseif reached then L("bestiary.claim")
							else L("bestiary.not_yet"),
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
	local function openSeason()
		openPanel("SeasonPanel", L("menu.season"), function(content: any, state: any)
			local season = state.season
			local order = 0
			local function nextOrder(): number
				order += 1
				return order
			end
			if season == nil then
				UI.label({
					text = L("season.none"),
					layoutOrder = nextOrder(),
					parent = content,
				})
				return
			end
			local remaining =
				ctx.ClientLogic.remainingSeconds(season.endsAt, state.serverNow, store:receivedAt(), os.clock())
			-- Nombre con clave propia (season.<id>.name) o, si es una temporada nueva de la configuracion remota, el configurado.
			local seasonKey = "season." .. tostring(season.id) .. ".name"
			addHeader(
				content,
				nextOrder(),
				if ctx.locale:has(seasonKey) then L(seasonKey) else ctx.serverText(season.name, "?")
			)
			UI.label({
				text = L("season.points", { points = season.points, time = UI.formatDuration(remaining) }),
				layoutOrder = nextOrder(),
				parent = content,
			})
			if not state.passes.season_pass then
				addRow(content, nextOrder(), L("season.premium_title"), L("season.premium_desc"), {
					{
						text = L("season.view_pass"),
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
				local function status(claimed: boolean): string
					return if claimed
						then L("season.status_claimed")
						elseif reached then L("season.status_claimable")
						else L("season.status_locked")
				end
				addRow(content, nextOrder(), L("season.tier", { tier = tier.tier, points = tier.points }), nil, {
					{
						text = L("season.free_line", { reward = rewardText(tier.free), status = status(freeClaimed) }),
						enabled = reached and not freeClaimed,
						onClick = function()
							net:fire("ClaimSeason", tier.tier, "free")
						end,
					},
					{
						text = L(
							"season.premium_line",
							{ reward = rewardText(tier.premium), status = status(premiumClaimed) }
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
		local root, content = UI.panel(gui, { name = "CodesPanel", title = L("menu.codes"), onClose = close })
		UI.label({
			text = L("codes.intro"),
			layoutOrder = 1,
			parent = content,
		})
		local box = Instance.new("TextBox")
		box.Name = "CodeBox"
		box.PlaceholderText = L("codes.placeholder")
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
			text = L("codes.redeem"),
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
		-- Mismas cifras en todos los idiomas: solo cambian el nombre de las filas y los separadores decimales.
		local view = ctx.ClientLogic.localizeOddsView(
			rules:oddsFor(zone):displayRows({ luck = state.luck }),
			ctx.locale,
			ctx.language()
		)
		local handle = UI.oddsPanel(gui, {
			title = L("odds.title", { zone = L("zone." .. zone .. ".name") }),
			view = view,
			onClose = close,
			luckExplanation = L("odds.luck_explanation", { perfect = balance.minigame.perfectLuck }),
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
					text = L("zone." .. id .. ".name"),
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
			local lines = { L("odds.luck_total", { luck = state.luck, cap = balance.limits.maxLuck }) }
			for _, source in state.luckSources do
				-- La clave del nombre llega del servidor: solo se acepta una clave conocida de los prefijos permitidos.
				local labelKey = ctx.safeKey(source.labelKey, { "rod.", "odds.source.", "pass.", "product." })
				if source.active and labelKey ~= nil then
					table.insert(
						lines,
						L("odds.luck_line", {
							label = L(labelKey),
							value = source.value,
							paid = if source.paid then L("odds.paid_suffix") else "",
						})
					)
				end
			end
			UI.label({ text = table.concat(lines, "\n"), layoutOrder = -2, parent = content })
			if state.totalCasts < #balance.ftue.guaranteedRarities then
				UI.label({
					text = L("ftue.odds_note", { count = #balance.ftue.guaranteedRarities }),
					colorName = "positive",
					layoutOrder = -1,
					parent = content,
				})
			end
			if state.paidRandomRestricted then
				UI.label({
					text = L("odds.restricted"),
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
			title = L("shop.title"),
			offers = latestOffers or {},
			onBuy = function(kind: string, key: string)
				net:fire("RequestPurchase", kind, key)
			end,
			onClose = close,
		})
		local content = handle.root:FindFirstChild("Content")
		if content ~= nil then
			UI.label({
				text = L("shop.note"),
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

	-- Las claves de texto de cada oferta llegan del servidor: solo se aceptan claves de pases/productos que existen y con
	-- argumentos validos; si no, se muestra el texto de respaldo (`name`/`description`).
	local function cleanOffers(offers: any): { any }
		local list = {}
		if type(offers) ~= "table" then
			return list
		end
		for _, offer in offers do
			local copy = table.clone(offer)
			local prefixes = { "pass.", "product." }
			local nameKey, nameArgs = ctx.safeKey(offer.nameKey, prefixes, offer.textArgs)
			local descriptionKey, descriptionArgs = ctx.safeKey(offer.descriptionKey, prefixes, offer.textArgs)
			copy.nameKey = nameKey
			copy.descriptionKey = descriptionKey
			-- argumentos ya validados (los de nombre y descripcion se unen: la oferta los comparte)
			local merged: { [string]: any } = {}
			for _, args in { nameArgs or {}, descriptionArgs or {} } do
				for name, value in args do
					merged[name] = value
				end
			end
			copy.textArgs = merged
			table.insert(list, copy)
		end
		return list
	end

	local function onOffers(offers: any)
		latestOffers = cleanOffers(offers)
		if shopHandle ~= nil then
			shopHandle.update(latestOffers)
		end
	end

	return { open = open, close = close, onOffers = onOffers }
end

return Menus
