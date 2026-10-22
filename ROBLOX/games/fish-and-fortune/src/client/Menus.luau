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
	local muted = { MuteMusic = false, MuteSFX = false }

	-- Mando: al abrir un panel se selecciona su primer boton (si el entorno no tiene GuiService o mando, no hace nada).
	local function selectFirst(root: any)
		pcall(function()
			if not game:GetService("UserInputService").GamepadEnabled then
				return
			end
			local guiService = game:GetService("GuiService")
			local selected = guiService.SelectedObject
			if selected ~= nil and selected:IsDescendantOf(root) then
				return
			end
			local content = root:FindFirstChild("Content")
			local target = if content ~= nil then content:FindFirstChildWhichIsA("GuiButton", true) else nil
			guiService.SelectedObject = target or root:FindFirstChild("Close")
		end)
	end
	local latestOffers: any = nil
	local shopHandle: any = nil
	local selectedOddsZone: string? = nil

	-- Estado de filas de la apertura actual: "hecho" previo (para el destello verde al comprar/reclamar) y escalonado.
	local rowDone: { [string]: boolean } = {}
	local animateRows = false
	local rowIndex = 0

	-- Cierra el panel actual: encoge y desvanece (0.14 s) y se destruye con task.delay. Se renombra para que no cuente como
	-- "...Panel" mientras se va. `instant` (redibujos) lo destruye al momento.
	local function close(instant: boolean?)
		local open = current
		if open ~= nil then
			if open.unsubscribe then
				open.unsubscribe()
			end
			local root = open.root
			local veil = gui:FindFirstChild("Veil")
			current = nil
			shopHandle = nil
			if instant == true or UI.motion.reduced then
				root:Destroy()
				if veil ~= nil then
					veil:Destroy()
				end
				return
			end
			root.Name = "Closing"
			UI.motion.tween(UI.motion.scaleOf(root), { Scale = 0.92 }, 0.14, "Quad", "In")
			UI.motion.tween(root, { BackgroundTransparency = 1 }, 0.14, "Quad", "In")
			if veil ~= nil then
				veil.Name = "VeilOut"
				UI.motion.tween(veil, { BackgroundTransparency = 1 }, 0.14, "Quad", "In")
			end
			task.delay(0.16, function()
				root:Destroy()
				if veil ~= nil then
					veil:Destroy()
				end
			end)
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
			textSize = 22,
			display = true,
			layoutOrder = order,
			parent = content,
			colorName = "gold",
		})
	end

	type RowOptions = { key: string, icon: string?, done: boolean?, accent: string?, titleColor: string? }

	-- Fila de madera oscura: icono, nombre (letra de cartel), descripcion y botones verdes (apagados = gris).
	local function addRow(
		content: any,
		order: number,
		title: string,
		subtitle: string?,
		buttons: { ButtonSpec },
		opts: RowOptions
	)
		local done = opts.done == true
		local stroke = UI.create("UIStroke", {
			Color = rgb(if done then UI.theme.colors.positive else UI.theme.colors.woodDark),
			Thickness = if done then 2 else 3,
		})
		local row = UI.create("Frame", {
			Name = "Row_" .. opts.key,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = rgb(UI.theme.colors.row),
			BorderSizePixel = 0,
			LayoutOrder = order,
		}, {
			UI.create("UICorner", { CornerRadius = UDim.new(0, 12) }),
			stroke,
			UI.create("UIPadding", {
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, if opts.accent then 20 else 10),
				PaddingRight = UDim.new(0, 10),
			}),
			UI.create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
		})
		if opts.accent ~= nil then
			UI.create("Frame", {
				Name = "Accent",
				Position = UDim2.new(0, -10, 0, -2),
				Size = UDim2.new(0, 6, 1, 4),
				BackgroundColor3 = rgb(UI.theme.colors[opts.accent]),
				BorderSizePixel = 0,
				Parent = row,
			}, { UI.create("UICorner", { CornerRadius = UDim.new(0, 3) }) })
		end
		local textParent: any = row
		if opts.icon ~= nil then
			local head = UI.create("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				Parent = row,
			}, {
				UI.create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 10),
				}),
			})
			UI.icon(opts.icon, 56, { LayoutOrder = 1, Parent = head })
			textParent = UI.create("Frame", {
				Size = UDim2.new(1, -66, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				Parent = head,
			}, { UI.create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }) })
		end
		UI.label({
			text = title,
			display = true,
			textSize = 22,
			layoutOrder = 1,
			parent = textParent,
			colorName = opts.titleColor,
		})
		if subtitle ~= nil then
			UI.label({ text = subtitle, colorName = "textMuted", textSize = 16, layoutOrder = 2, parent = textParent })
		end
		for index, spec in buttons do
			UI.button({
				text = spec.text,
				enabled = spec.enabled,
				colorName = "positive",
				onActivated = spec.onClick,
				layoutOrder = 2 + index,
				parent = row,
			})
		end
		-- Se acaba de volver "hecho" (comprada, equipada, reclamada): destello verde del borde + pop.
		if done and rowDone[opts.key] == false then
			stroke.Thickness = 5
			UI.motion.tween(stroke, { Thickness = 2 }, 0.45)
			UI.motion.pop(row, 1.05)
		end
		rowDone[opts.key] = done
		-- Aparicion escalonada solo la primera vez (max 8 filas, 30 ms); los redibujos por State no animan.
		if animateRows and rowIndex < 8 and not UI.motion.reduced then
			rowIndex += 1
			local scale = UI.motion.scaleOf(row)
			scale.Scale = 0.9
			task.delay((rowIndex - 1) * 0.03, function()
				UI.motion.tween(scale, { Scale = 1 }, 0.18)
			end)
		end
	end

	-- Abre un panel que se redibuja con cada estado nuevo del servidor (la aparicion la hace UI.panel).
	local function openPanel(name: string, title: string, icon: string, build: (content: any, state: any) -> ())
		close(true)
		table.clear(rowDone)
		local root, content = UI.panel(gui, { name = name, title = title, icon = icon, onClose = close })
		local function render()
			clearContent(content)
			local state = store:get()
			if state ~= nil then
				rowIndex = 0
				build(content, state)
			end
			animateRows = false
			selectFirst(root)
		end
		animateRows = true
		render()
		current = { name = name, root = root, unsubscribe = store:subscribe(render) }
	end

	----------------------------------------------------------------------------
	-- Canas y zonas
	----------------------------------------------------------------------------
	local function openRods()
		openPanel("RodsPanel", L("rods.title"), "Rods", function(content: any, state: any)
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
				addRow(
					content,
					nextOrder(),
					L("rod." .. rodId),
					subtitle,
					{ button },
					{ key = "rod_" .. rodId, icon = "Rods", done = equipped }
				)
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
					{ button },
					{ key = "zone_" .. zoneId, icon = "Cast", done = state.zone == zoneId }
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
				},
				{ key = "bag", icon = "Bag", done = maxed }
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
				}, { key = "vip", icon = "Pearl", done = state.dailyAvailable ~= true })
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
		openPanel("BestiaryPanel", L("bestiary.title"), "Bestiary", function(content: any, state: any)
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
					addRow(content, nextOrder(), text, nil, {}, {
						key = "creature_" .. creature.id,
						accent = if found then creature.rarity else "disabled",
						titleColor = if found then UI.rarityColorName(creature.rarity) else "textMuted",
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
				}, { key = "reward_" .. reward.id, icon = "Bestiary", done = claimed })
			end
		end)
	end

	----------------------------------------------------------------------------
	-- Temporada
	----------------------------------------------------------------------------
	local function openSeason()
		openPanel("SeasonPanel", L("menu.season"), "Season", function(content: any, state: any)
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
				}, { key = "premium", icon = "Season" })
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
				}, { key = "tier_" .. key, icon = "Season", done = freeClaimed and premiumClaimed })
			end
		end)
	end

	----------------------------------------------------------------------------
	-- Codigos
	----------------------------------------------------------------------------
	local function openCodes()
		close()
		local root, content =
			UI.panel(gui, { name = "CodesPanel", title = L("menu.codes"), icon = "Codes", onClose = close })
		UI.label({
			text = L("codes.intro"),
			colorName = "textMuted",
			layoutOrder = 1,
			parent = content,
		})
		local box = Instance.new("TextBox")
		box.Name = "CodeBox"
		box.PlaceholderText = L("codes.placeholder")
		box.Text = ""
		box.ClearTextOnFocus = false
		box.Size = UDim2.new(1, 0, 0, UI.theme.minTouchHeight)
		box.BackgroundColor3 = rgb(UI.theme.colors.ink)
		box.TextColor3 = rgb(UI.theme.colors.gold)
		box.PlaceholderColor3 = rgb(UI.theme.colors.textMuted)
		box.Font = (Enum.Font :: any)[UI.theme.fonts.display]
		box.TextSize = 22
		box.LayoutOrder = 2
		box.Parent = content
		UI.create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = box })
		UI.create("UIStroke", { Color = rgb(UI.theme.colors.woodDark), Thickness = 4, Parent = box })
		UI.button({
			text = L("codes.redeem"),
			colorName = "positive",
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
		local function soundText(attribute: string): string
			if attribute == "MuteMusic" then
				return if muted[attribute] then L("sound.music_off") else L("sound.music_on")
			end
			return if muted[attribute] then L("sound.sfx_off") else L("sound.sfx_on")
		end
		for index, attribute in { "MuteMusic", "MuteSFX" } do
			local toggle: any
			toggle = UI.button({
				text = soundText(attribute),
				colorName = "row",
				layoutOrder = 3 + index,
				parent = content,
				onActivated = function()
					muted[attribute] = not muted[attribute]
					toggle.Text = soundText(attribute)
					pcall(function()
						game:GetService("SoundService"):SetAttribute(attribute, muted[attribute])
					end)
				end,
			})
		end
		current = { name = "codes", root = root, unsubscribe = nil }
		selectFirst(root)
	end

	----------------------------------------------------------------------------
	-- Probabilidades (cumplimiento: TODOS los resultados, suma 100 %, base y suerte visibles)
	----------------------------------------------------------------------------
	local function openOdds(zoneId: string?, refresh: boolean?)
		local state = store:get()
		if state == nil then
			return
		end
		close(refresh == true)
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
			animate = refresh ~= true,
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
				local tab = UI.button({
					text = L("zone." .. id .. ".name"),
					colorName = if id == zone then "gold" else "row",
					size = UDim2.new(1 / #balance.zoneOrder, -6, 1, 0),
					layoutOrder = index,
					parent = tabs,
					onActivated = function()
						openOdds(id, true)
					end,
				})
				if id == zone then
					tab.TextColor3 = rgb(UI.theme.colors.ink)
					tab.TextStrokeTransparency = 1
				end
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
		selectFirst(handle.root)
		current = {
			name = "odds",
			root = handle.root,
			unsubscribe = store:subscribe(function(newState: any)
				if newState.luck ~= lastLuck then
					lastLuck = newState.luck
					openOdds(zone, true)
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
		selectFirst(handle.root)
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

	-- B del mando cierra el panel abierto; sin panel, el boton pasa de largo.
	pcall(function()
		game:GetService("ContextActionService")
			:BindAction("FF_Back", function(_name: string, state: Enum.UserInputState)
				if state == Enum.UserInputState.Begin and current ~= nil then
					close()
					return Enum.ContextActionResult.Sink
				end
				return Enum.ContextActionResult.Pass
			end, false, Enum.KeyCode.ButtonB)
	end)

	return {
		open = open,
		close = close,
		onOffers = onOffers,
		isOpen = function(): boolean
			return current ~= nil
		end,
	}
end

return Menus
