--!strict
--[[
	GameService: orquesta el servidor de Fish & Fortune. SOLO pega piezas (el codigo con reglas esta en
	GameLogic y en los paquetes, que si tienen tests): datos de jugador, tienda, LiveOps, remotos, pesca
	automatica y banner global de MITICOS.

	Autoridad del servidor: todos los remotos del cliente solo SOLICITAN; aqui se valida (packages/Net)
	y se decide. Nada de lo que envia el cliente se usa como cantidad.

	Textos: el servidor NUNCA envia texto traducido al cliente: envia CLAVES con argumentos validados (`toast`, banner;
	packages/Locale + shared/Strings.luau) y el cliente las traduce al idioma del jugador. Solo las expulsiones (Kick) se
	arman aqui, con ES y EN juntos, porque el servidor no sabe el idioma del jugador antes de que cargue su cliente.

	// REVIEW(money): onPurchaseGranted / Shop.start / handlers de concesion / Data.attach tocan dinero real
	// y datos de jugador. Revisar con una persona antes de publicar. No se ha probado en Studio.
]]

local AnalyticsService = game:GetService("AnalyticsService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local MessagingService = game:GetService("MessagingService")
local PolicyService = game:GetService("PolicyService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameService = {}

local PASS_KEYS = { "auto_fish", "double_coins", "luck_plus", "starter", "vip", "season_pass" }
local DATASTORE_NAME = "FishFortune_PlayerData_v1" -- NO cambiar el nombre una vez publicado (seria un almacen vacio)
local LIVEOPS_CONFIG_KEY = "FishFortune_LiveOps" -- clave de ConfigService (JSON)
local LIVEOPS_TOPIC = "FishFortune_LiveOpsUpdated"

-- Todos los modulos llegan inyectados (`m`): asi este archivo no depende de rutas de instancias.
function GameService.start(m: any)
	local balance = m.Balance
	local locale = m.Locale.new(m.Strings)
	local spanish = locale:translator("es") -- textos del servidor para logs, validacion del catalogo y respaldo
	local random = Random.new()
	local isPrivateServer = game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
	local jobId = if game.JobId ~= "" then game.JobId else HttpService:GenerateGUID(false)

	----------------------------------------------------------------------------
	-- Mundo
	----------------------------------------------------------------------------
	local zoneList = {}
	for _, zoneId in balance.zoneOrder do
		table.insert(zoneList, {
			id = zoneId,
			nameKey = "zone." .. zoneId .. ".name",
			name = spanish("zone." .. zoneId .. ".name"),
		})
	end
	-- Arte generado (opcional): sin `m.ArtDirector` el mundo, la cana y las capturas son los procedurales de siempre.
	local art = m.ArtDirector
	local world = m.WorldBuilder.build(zoneList, if art ~= nil then art.provider else nil)
	if art ~= nil then
		art.logStatus()
	end

	----------------------------------------------------------------------------
	-- Paquetes
	----------------------------------------------------------------------------
	local flags = m.FeatureFlags -- { paidLuckEnabled = false } en la v1
	local analytics = m.Analytics.new({ service = AnalyticsService, enums = Enum })

	local rules = m.FishingRules.new(balance, m.Odds)

	-- REVIEW(money) ANALYTICS-01: el evento de economia de una compra con Robux (IAP) NO se envia al conceder (en memoria),
	-- sino DESPUES de guardar, en onPurchaseGranted. Si el guardado falla, Roblox reintenta el recibo y el evento sale una
	-- sola vez al confirmar; antes se contaba al conceder y se duplicaba si la concesion se repetia.
	-- Cola por jugador: userId -> eventos IAP concedidos aun sin confirmar (tope por jugador).
	local pendingIap: { [number]: { any } } = {}
	local MAX_PENDING_IAP = 20

	local logic = m.GameLogic.new({
		balance = balance,
		rules = rules,
		economy = m.Economy,
		rng = function(): number
			return random:NextNumber()
		end,
		clock = os.clock,
		flags = flags,
		onTransaction = function(tx: any)
			if tx.player == nil then
				return
			end
			if tx.reason == "IAP" then
				local queue = pendingIap[tx.player.UserId]
				if queue == nil then
					queue = {}
					pendingIap[tx.player.UserId] = queue
				end
				if #queue < MAX_PENDING_IAP then
					table.insert(queue, tx)
				end
				return
			end
			analytics:economy(tx.player, tx.flow, tx.currency, tx.amount, tx.endingBalance, tx.reason, tx.sku)
		end,
	})

	local schema = m.Schema.build(m.GameLogic.template(), m.Shop.DATA_TEMPLATE)

	-- En Studio sin acceso a la API de DataStores se usa un almacen en memoria (SIN persistencia) para poder jugar.
	local function pickDataStore(): any
		-- En un lugar sin publicar GetDataStore ya lanza error (playtest-1), no solo GetAsync.
		local okStore, realStore = pcall(DataStoreService.GetDataStore, DataStoreService, DATASTORE_NAME)
		if not okStore and not RunService:IsStudio() then
			error(realStore, 0)
		end
		if RunService:IsStudio() then
			local reachable = okStore and pcall(function()
				realStore:GetAsync("__studio_probe")
			end)
			if not reachable then
				warn("[Data] Studio sin acceso a DataStores: se usa un almacen en MEMORIA (no se guarda nada).")
				return m.StudioMemoryStore.new()
			end
			warn("[Data] Studio con acceso a la API: se escribe en el DataStore REAL. Usa un lugar de pruebas.")
		end
		return realStore
	end

	local manager = m.Data.new({
		dataStore = pickDataStore(),
		schema = schema,
		jobId = jobId,
		autosaveSeconds = 120,
		-- Expulsiones: ES y EN juntos (el servidor no conoce el idioma del jugador antes de que cargue su cliente).
		messages = {
			loadFailed = locale:joined("kick.load_failed"),
			locked = locale:joined("kick.locked"),
			newerVersion = locale:joined("kick.newer_version"),
			lockLost = locale:joined("kick.lock_lost"),
		},
	})

	-- LiveOps: configuracion remota SIN republicar (ConfigService), con valores por defecto en Balance.
	local function fetchRemoteConfig(): any
		-- VERIFY: ConfigService:GetConfigAsync() (yield, devuelve ConfigSnapshot) y snapshot:GetValue(key)
		-- (Variant) segun creator-docs ConfigService.yaml / ConfigSnapshot.yaml. El formato exacto del valor
		-- JSON (string o tabla) y el limite de tamano por clave NO estan verificados: se aceptan ambos.
		local service = game:GetService("ConfigService")
		local snapshot = service:GetConfigAsync()
		local value = snapshot:GetValue(LIVEOPS_CONFIG_KEY)
		if value == nil then
			return nil
		end
		if type(value) == "string" then
			return HttpService:JSONDecode(value)
		end
		return value
	end
	local liveOps = m.LiveOps.new({
		defaults = m.LiveOpsDefaults,
		fetch = fetchRemoteConfig,
		pollSeconds = 120,
		log = function(message: string)
			warn("[LiveOps] " .. message)
		end,
	})

	local catalog = m.Catalog.build(m.ProductIds, balance, flags, spanish)
	local grants = logic:shopHandlers(os.time)
	for _, problem in m.Shop.validateCatalog(catalog, grants) do
		warn("[Shop] catalogo: " .. problem)
	end
	local pendingIds = m.Shop.validateCatalog(catalog, grants, { allowPlaceholders = false })
	if #pendingIds > 0 then
		warn(
			"[Shop] hay " .. #pendingIds .. " pases/productos con ID 0 (TODO_ID): no se ofreceran. Ver ProductIds.luau"
		)
	end

	local shop: any = nil -- se crea mas abajo (necesita los handlers); `context` lo usa en tiempo de ejecucion

	-- Estado transitorio por jugador (no se guarda)
	local runtimes: { [number]: any } = {}
	local dirty: { [number]: boolean } = {}
	local funnelSessions: { [number]: string } = {}
	-- OFFLINE-01: jugadores cuyo calculo offline de la entrada ya se pago; solo entonces se refresca lastSeen.
	local offlineReady: { [number]: boolean } = {}

	local function profileOf(player: Player): any?
		local profile = manager:get(player.UserId)
		if profile ~= nil and profile:isActive() then
			return profile
		end
		return nil
	end

	local function markDirty(player: Player)
		dirty[player.UserId] = true
	end

	----------------------------------------------------------------------------
	-- Remotos
	----------------------------------------------------------------------------
	local remotesFolder = Instance.new("Folder")
	remotesFolder.Name = m.Remotes.folderName
	remotesFolder.Parent = ReplicatedStorage

	local net = m.Net.newServer({
		folder = remotesFolder,
		globalRate = { capacity = 40, refillPerSecond = 20 },
		onAbuse = function(player: Player, rejections: number)
			-- Solo se registra (escalar a expulsion por una unica senal da falsos positivos).
			warn(("[Net] %s supero el umbral de solicitudes invalidas (%d)"):format(player.Name, rejections))
			analytics:custom(player, "net_abuse", 1)
		end,
	})
	for _, name in m.Remotes.outbound do
		net:outbound(name)
	end
	local t = m.Net.t

	----------------------------------------------------------------------------
	-- Contexto de reglas por jugador
	----------------------------------------------------------------------------
	local function context(player: Player): any
		local passes: { [string]: boolean } = {}
		for _, key in PASS_KEYS do
			passes[key] = shop:ownsPass(player, key)
		end
		return {
			player = player,
			passes = passes,
			events = liveOps:getModifierSources(),
			-- PolicyService: sin datos => restringido (conservador). Cacheado por jugador en Shop.getPolicy.
			-- Con el flag de suerte de pago APAGADO (v1) no se consulta: getPolicy cede (yield) y context() corre en
			-- cada remoto y en el bucle de pesca automatica.
			paidRandomAllowed = flags.paidLuckEnabled and m.Odds.paidRandomAllowed(shop:getPolicy(player)) or false,
			now = os.time(),
		}
	end

	-- Aviso al jugador: se envia { key, args } validado (lista blanca de prefijos y de argumentos), nunca texto traducido.
	local function toast(player: Player, key: string, args: { [string]: any }?)
		local message = locale:message(key, args)
		if message == nil then
			warn("[Locale] mensaje invalido descartado: " .. key)
			return
		end
		net:fireClient("Toast", player, message)
	end

	local function ftue(player: Player, data: any, step: number, name: string)
		if data.ftue.step >= step then
			return
		end
		data.ftue.step = step
		analytics:ftue(player, step, name)
	end

	----------------------------------------------------------------------------
	-- Estado enviado al cliente
	----------------------------------------------------------------------------
	local function buildState(player: Player, profile: any): any
		local data = profile.data
		local c = context(player)
		local luck, luckSources = logic:luck(data, c)
		local now = c.now
		local season = liveOps:getSeason(now)
		local events = {}
		for _, event in liveOps:getActiveEvents(now) do
			table.insert(events, {
				id = event.id,
				name = event.name,
				description = event.description,
				endsAt = event.endsAt,
				modifiers = event.modifiers,
			})
		end
		return {
			serverNow = now,
			coins = data.wallet.coins,
			pearls = data.wallet.pearls,
			inventory = data.inventory,
			inventoryCount = logic:inventoryCount(data),
			capacity = logic:capacity(data),
			rod = data.rod,
			ownedRods = data.ownedRods,
			zone = data.zone,
			unlockedZones = data.unlockedZones,
			luck = luck,
			luckSources = luckSources,
			coinMultiplier = logic:coinMultiplier(data, c),
			autoFish = data.autoFish,
			passes = c.passes,
			paidLuckEnabled = flags.paidLuckEnabled,
			paidRandomRestricted = flags.paidLuckEnabled and not c.paidRandomAllowed,
			boosts = data.boosts,
			bestiary = data.bestiary,
			bestiaryClaimed = data.bestiaryClaimed,
			discoveries = logic:discoveries(data),
			season = if season
				then {
					id = season.id,
					name = season.name,
					endsAt = season.endsAt,
					points = data.season.points,
					claimedFree = data.season.claimedFree,
					claimedPremium = data.season.claimedPremium,
				}
				else nil,
			events = events,
			dailyAvailable = c.passes.vip and data.daily.lastClaimDay < math.floor(now / 86400),
			isPrivateServer = isPrivateServer,
			ftueStep = data.ftue.step,
			totalCasts = data.stats.casts,
		}
	end

	local function pushState(player: Player)
		local profile = profileOf(player)
		if profile == nil then
			return
		end
		dirty[player.UserId] = nil
		net:fireClient("State", player, buildState(player, profile))
	end

	task.spawn(function()
		-- Envia el estado como mucho 4 veces por segundo por jugador (agrupa cambios).
		while true do
			task.wait(0.25)
			local pending = {}
			for userId in dirty do
				table.insert(pending, userId)
			end
			for _, userId in pending do
				local player = Players:GetPlayerByUserId(userId)
				if player then
					pushState(player)
				else
					dirty[userId] = nil
				end
			end
		end
	end)

	----------------------------------------------------------------------------
	-- Tienda
	----------------------------------------------------------------------------
	shop = m.Shop.new({
		catalog = catalog,
		marketplace = MarketplaceService,
		players = Players,
		decision = Enum.ProductPurchaseDecision,
		infoTypes = { Product = Enum.InfoType.Product, GamePass = Enum.InfoType.GamePass },
		policy = PolicyService,
		waitForProfile = function(userId: number, timeoutSeconds: number): any?
			return manager:waitForProfile(userId, timeoutSeconds)
		end,
		grants = grants,
		profileWaitSeconds = 90, -- ProcessReceipt no tiene reintento por tiempo: esperar mas que el bloqueo de sesion
		canPurchase = function(_player: Player, profile: any, item: any, itemKind: string): (boolean, string?)
			return logic:canBuy(profile.data, item, itemKind, os.time())
		end,
		onPurchaseGranted = function(player: Player, product: any, receipt: any)
			-- Solo corre DESPUES de confirmar el guardado.
			local queue = pendingIap[player.UserId]
			if queue ~= nil then
				local waiting = {}
				for _, tx in queue do
					if tx.sku == product.key then
						analytics:economy(
							tx.player,
							tx.flow,
							tx.currency,
							tx.amount,
							tx.endingBalance,
							tx.reason,
							tx.sku
						)
					else
						table.insert(waiting, tx)
					end
				end
				if #waiting > 0 then
					pendingIap[player.UserId] = waiting
				else
					pendingIap[player.UserId] = nil
				end
			end
			analytics:funnel(player, "shop", 3, "purchase_granted", funnelSessions[player.UserId])
			analytics:custom(
				player,
				"purchase_" .. product.key,
				1,
				{ CustomField01 = tostring(receipt.CurrencySpent or 0) }
			)
			toast(player, "toast.purchase_received", { item = { key = "product." .. product.key .. ".name" } })
			markDirty(player)
		end,
		onPassChanged = function(player: Player, _pass: any, _owned: boolean)
			markDirty(player)
		end,
	})
	shop:start()
	task.spawn(function()
		shop:refreshPrices() -- precios reales (regionales); si falla se muestran los de la escalera con "~"
	end)

	----------------------------------------------------------------------------
	-- Capturas
	----------------------------------------------------------------------------
	local lastMythicPublish = 0

	local function announceMythic(player: Player, result: any)
		analytics:custom(player, "mythic_caught", 1, { CustomField01 = result.creatureId })
		local isVip = shop:ownsPass(player, "vip")
		local banner = locale:message(if isVip then "banner.mythic_vip" else "banner.mythic", {
			player = player.DisplayName,
			creature = { key = "creature." .. result.creatureId },
			zone = { key = "zone." .. result.zone .. ".name" },
		})
		if banner ~= nil then
			net:fireAllClients("Banner", banner)
		end
		if isPrivateServer then
			return
		end
		local now = os.clock()
		if now - lastMythicPublish < balance.mythicBanner.cooldownSeconds then
			return -- MessagingService tiene cuotas: el banner local ya se mostro
		end
		lastMythicPublish = now
		task.spawn(function()
			-- Truncar por CARACTERES (un corte por bytes puede partir un caracter UTF-8 y el receptor descartaria el banner).
			local shownName = player.DisplayName
			local cut = utf8.offset(shownName, 21)
			if cut ~= nil then
				shownName = string.sub(shownName, 1, cut - 1)
			end
			local message = { j = jobId, p = shownName, c = result.creatureId, v = isVip }
			local ok, err = pcall(function()
				MessagingService:PublishAsync(balance.mythicBanner.topic, message)
			end)
			if not ok then
				warn("[Banner] no se pudo publicar el MITICO: " .. tostring(err))
			end
		end)
	end

	local function onCatch(player: Player, profile: any, result: any, isAuto: boolean?)
		profile:markDirty()
		local data = profile.data
		net:fireClient("Catch", player, {
			id = result.creatureId,
			rarity = result.rarity,
			value = result.value,
			isNew = result.isNew,
			stored = result.stored,
			autoSoldFor = result.autoSoldFor,
			quality = result.quality,
			tutorial = result.tutorial,
		})
		analytics:custom(player, "catch", 1, { CustomField01 = result.rarity })
		ftue(player, data, 3, "first_catch")
		if balance.rarities[result.rarity].order >= balance.rarities.Rare.order then
			ftue(player, data, 6, "first_rare")
		end
		if result.rarity == "Mythic" then
			announceMythic(player, result)
		end
		local castPosition = world.castTargets[result.zone]
		if art ~= nil and castPosition ~= nil then
			-- Escaparate de la criatura (solo si hay arte de ella; ver ArtDirector). Nunca debe afectar a la captura.
			pcall(art.showCatch, {
				zone = result.zone,
				creatureId = result.creatureId,
				rarity = result.rarity,
				position = castPosition,
				auto = isAuto == true,
			})
		end
		markDirty(player)
	end

	-- Banner global recibido de otros servidores.
	if not isPrivateServer then
		task.spawn(function()
			local ok, err = pcall(function()
				MessagingService:SubscribeAsync(balance.mythicBanner.topic, function(message: any)
					local data = message.Data
					if type(data) ~= "table" or data.j == jobId then
						return
					end
					local creature = rules:creature(tostring(data.c))
					if creature == nil or type(data.p) ~= "string" or not utf8.len(data.p) or #data.p > 100 then
						return
					end
					local banner = locale:message(if data.v == true then "banner.mythic_vip" else "banner.mythic", {
						player = data.p,
						creature = { key = "creature." .. creature.id },
						zone = { key = "zone." .. creature.zone .. ".name" },
					})
					if banner ~= nil then
						net:fireAllClients("Banner", banner)
					end
				end)
			end)
			if not ok then
				warn("[Banner] no se pudo suscribir a los MITICOS globales: " .. tostring(err))
			end
		end)
		-- SubscribeAsync cede (red): fuera del hilo de arranque, para que un MessagingService lento no retrase el resto del
		-- arranque (datos de jugadores, pesca automatica, PlayerAdded).
		task.spawn(function()
			liveOps:subscribe(MessagingService, LIVEOPS_TOPIC)
		end)
	end
	liveOps:startPolling()

	local function attachRod(player: Player, character: Model)
		local profile = profileOf(player)
		local rodId = if profile then profile.data.rod else "driftwood"
		local rod = balance.rods[rodId]
		local old = character:FindFirstChild("FishingRod")
		if old then
			old:Destroy()
		end
		local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
		if hand == nil or not hand:IsA("BasePart") then
			return
		end
		if art ~= nil and art.attachRod(rodId, hand, character) then
			return -- cana de arte generado; si no hay (o se rechaza), sigue el respaldo procedural
		end
		local part = Instance.new("Part")
		part.Name = "FishingRod"
		part.Size = Vector3.new(0.25, 0.25, 5)
		part.Color = Color3.fromRGB(rod.color[1], rod.color[2], rod.color[3])
		part.Material = Enum.Material.Wood
		part.CanCollide = false
		part.Massless = true
		part.CFrame = hand.CFrame * CFrame.new(0, -0.4, -2.2)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hand
		weld.Part1 = part
		weld.Parent = part
		part.Parent = character
	end

	local function refreshRod(player: Player)
		local character = player.Character
		if character ~= nil then
			attachRod(player, character)
		end
	end

	----------------------------------------------------------------------------
	-- Handlers de remotos (todos validados por packages/Net)
	----------------------------------------------------------------------------
	local function withProfile(
		handler: (player: Player, profile: any, ...any) -> ...any
	): (player: Player, ...any) -> ...any
		return function(player: Player, ...: any)
			local profile = profileOf(player)
			if profile == nil then
				return
			end
			handler(player, profile, ...)
		end
	end

	net:event("RequestState", {
		args = {},
		rate = { capacity = 4, refillPerSecond = 1 },
		handler = function(player: Player)
			pushState(player)
		end,
	})

	net:event("Cast", {
		args = {},
		rate = { capacity = 3, refillPerSecond = 1.5 },
		handler = withProfile(function(player: Player, profile: any)
			local runtime = runtimes[player.UserId]
			if runtime == nil then
				return
			end
			local session, reason = logic:startCast(profile.data, runtime)
			if session == nil then
				net:fireClient("CastFailed", player, reason)
				return
			end
			ftue(player, profile.data, 2, "first_cast")
			net:fireClient("CastStarted", player, {
				id = session.id,
				zone = session.zone,
				center = session.center,
				width = session.width,
				duration = balance.minigame.durationSeconds,
				period = balance.minigame.markerPeriod,
			})
		end),
	})

	net:event("Reel", {
		args = { t.integer(1, 2147483647), t.number({ min = 0, max = 30 }) },
		rate = { capacity = 4, refillPerSecond = 2 },
		handler = withProfile(function(player: Player, profile: any, castId: number, elapsed: number)
			local runtime = runtimes[player.UserId]
			if runtime == nil then
				return
			end
			local result, reason = logic:reel(profile.data, runtime, context(player), castId, elapsed)
			if result == nil then
				net:fireClient("CastFailed", player, reason)
				return
			end
			onCatch(player, profile, result)
		end),
	})

	net:event("SellAll", {
		args = {},
		rate = { capacity = 3, refillPerSecond = 0.5 },
		handler = withProfile(function(player: Player, profile: any)
			local earned, count = logic:sellAll(profile.data, context(player))
			if count == 0 then
				toast(player, "toast.nothing_to_sell")
				return
			end
			profile:markDirty()
			ftue(player, profile.data, 4, "first_sale")
			toast(player, "toast.sold", { count = count, coins = earned })
			markDirty(player)
		end),
	})

	local function simpleAction(
		name: string,
		validators: { any },
		rate: any,
		action: (player: Player, profile: any, ...any) -> (boolean, string?),
		okKey: string?
	)
		net:event(name, {
			args = validators,
			rate = rate,
			handler = withProfile(function(player: Player, profile: any, ...: any)
				local ok, reason = action(player, profile, ...)
				if ok then
					profile:markDirty()
					if okKey then
						toast(player, okKey)
					end
				else
					net:fireClient("CastFailed", player, reason or "error")
				end
				markDirty(player)
			end),
		})
	end

	local slowRate = { capacity = 4, refillPerSecond = 0.5 }

	simpleAction(
		"BuyRod",
		{ t.oneOf(balance.rodOrder) },
		slowRate,
		function(player: Player, profile: any, rodId: string)
			local ok, reason = logic:buyRod(profile.data, rodId, player)
			if ok then
				ftue(player, profile.data, 5, "first_rod")
				refreshRod(player)
			end
			return ok, reason
		end,
		"toast.rod_bought"
	)

	simpleAction(
		"EquipRod",
		{ t.oneOf(balance.rodOrder) },
		slowRate,
		function(player: Player, profile: any, rodId: string)
			local ok, reason = logic:equipRod(profile.data, rodId)
			if ok then
				refreshRod(player)
			end
			return ok, reason
		end,
		nil
	)

	simpleAction(
		"UnlockZone",
		{ t.oneOf(balance.zoneOrder) },
		slowRate,
		function(player: Player, profile: any, zoneId: string)
			return logic:unlockZone(profile.data, zoneId, player)
		end,
		"toast.zone_unlocked"
	)

	local function teleportToZone(player: Player, zoneId: string)
		local character = player.Character
		local position = world.spawns[zoneId]
		if character ~= nil and position ~= nil then
			character:PivotTo(CFrame.new(position + Vector3.new(0, 3, 0)))
		end
	end

	simpleAction(
		"TravelZone",
		{ t.oneOf(balance.zoneOrder) },
		slowRate,
		function(player: Player, profile: any, zoneId: string)
			local ok, reason = logic:travel(profile.data, zoneId)
			if ok then
				teleportToZone(player, zoneId)
			end
			return ok, reason
		end,
		nil
	)

	net:event("SetAutoFish", {
		args = { t.boolean() },
		rate = slowRate,
		handler = withProfile(function(player: Player, profile: any, enabled: boolean)
			if enabled and not shop:ownsPass(player, "auto_fish") then
				toast(player, "toast.autofish_needs_pass")
				return
			end
			profile.data.autoFish = enabled
			profile:markDirty()
			markDirty(player)
		end),
	})

	local rewardIds = {}
	for _, reward in balance.bestiary.rewards do
		table.insert(rewardIds, reward.id)
	end
	simpleAction(
		"ClaimBestiary",
		{ t.oneOf(rewardIds) },
		slowRate,
		function(player: Player, profile: any, rewardId: string)
			return logic:claimBestiary(profile.data, rewardId, player)
		end,
		"toast.bestiary_claimed"
	)

	simpleAction(
		"ClaimSeason",
		{ t.integer(1, #balance.season.tiers), t.oneOf({ "free", "premium" }) },
		slowRate,
		function(player: Player, profile: any, tier: number, track: string)
			return logic:claimSeason(profile.data, tier, track, context(player))
		end,
		"toast.season_claimed"
	)

	simpleAction("ClaimDaily", {}, slowRate, function(player: Player, profile: any)
		return logic:claimDaily(profile.data, context(player))
	end, "toast.daily_claimed")

	simpleAction("BuySlotsWithPearls", {}, slowRate, function(player: Player, profile: any)
		return logic:buySlotsWithPearls(profile.data, player)
	end, "toast.slots_expanded")

	-- Resultado de LiveOps.redeemCode -> clave de texto
	local codeMessages: { [string]: string } = {
		invalid = "toast.code_invalid",
		unknown = "toast.code_unknown",
		notStarted = "toast.code_not_started",
		expired = "toast.code_expired",
		already = "toast.code_already",
	}
	net:event("RedeemCode", {
		args = { t.string({ minLength = 1, maxLength = 32 }) },
		rate = { capacity = 3, refillPerSecond = 0.1 },
		handler = withProfile(function(player: Player, profile: any, code: string)
			local result = liveOps:redeemCode(profile.data.redeemedCodes, code, os.time())
			if not result.ok then
				toast(player, codeMessages[result.reason or "invalid"] or "toast.code_invalid")
				return
			end
			local granted, grantErr =
				pcall(logic.grantReward, logic, profile.data, result.reward, "TimedReward", "redeem_code", player)
			if not granted then
				-- Premio mal formado en la configuracion remota: no se "gasta" el codigo del jugador sin pagarle.
				profile.data.redeemedCodes[result.code :: string] = nil
				warn("[LiveOps] el premio del codigo " .. tostring(result.code) .. " fallo: " .. tostring(grantErr))
				toast(player, "toast.code_failed")
				return
			end
			profile:markDirty()
			analytics:custom(player, "code_redeemed", 1)
			toast(player, "toast.code_redeemed")
			markDirty(player)
			task.spawn(function()
				profile:save() -- guarda ya: un codigo canjeado no debe perderse si el servidor cae
			end)
		end),
	})

	net:event("RequestOffers", {
		args = {},
		rate = { capacity = 3, refillPerSecond = 0.5 },
		handler = function(player: Player)
			funnelSessions[player.UserId] = HttpService:GenerateGUID(false)
			analytics:funnel(player, "shop", 1, "open_shop", funnelSessions[player.UserId])
			net:fireClient("Offers", player, shop:getOffers(player))
		end,
	})

	net:event("RequestPurchase", {
		args = { t.oneOf({ "pass", "product" }), t.string({ minLength = 1, maxLength = 32, pattern = "^[%w_]+$" }) },
		rate = { capacity = 3, refillPerSecond = 0.3 },
		handler = function(player: Player, kind: string, key: string)
			-- El cliente pide por CLAVE de catalogo; el servidor decide si se ofrece y abre el prompt de Roblox.
			local ok, reason
			if kind == "pass" then
				ok, reason = shop:promptPass(player, key)
			else
				ok, reason = shop:promptProduct(player, key)
			end
			if ok then
				analytics:funnel(player, "shop", 2, "prompt_" .. key, funnelSessions[player.UserId])
			else
				net:fireClient("CastFailed", player, reason or "error")
			end
		end,
	})

	----------------------------------------------------------------------------
	-- Ciclo de vida del jugador
	----------------------------------------------------------------------------
	local function onLoaded(player: Player, profile: any)
		runtimes[player.UserId] = m.GameLogic.newRuntime()
		task.spawn(function()
			-- 1. propiedad de pases + concesiones unicas + politica (se cachea para no ceder despues)
			shop:loadPlayer(player)
			if flags.paidLuckEnabled then
				shop:getPolicy(player) -- precalienta la cache (solo hace falta si la suerte de pago esta encendida)
			end
			if not profile:isActive() then
				return
			end
			local data = profile.data
			local c = context(player)
			-- 2. temporada y offline
			local season = liveOps:getSeason(c.now)
			logic:seasonSync(data, if season then season.id else 0)
			local earned, seconds = logic:applyOffline(data, c)
			offlineReady[player.UserId] = true -- applyOffline ya dejo lastSeen = ahora: desde aqui se puede refrescar
			if earned > 0 then
				toast(player, "toast.offline", { minutes = math.floor(seconds / 60), coins = earned, count = earned })
			end
			-- 3. bienvenida (una vez por id)
			local welcome = liveOps:getWelcome(data.seenWelcome, c.now)
			if welcome then
				data.seenWelcome = welcome.id
				-- Bienvenida: con clave propia (welcome.<id>) se traduce; si viene de la configuracion remota sin traduccion,
				-- se muestra su texto tal cual (en el idioma en que se escribio).
				if locale:has("welcome." .. welcome.id) then
					toast(player, "welcome." .. welcome.id)
				else
					toast(player, "toast.raw", { text = welcome.message })
				end
			end
			ftue(player, data, 1, "joined")
			if not data.ftue.joinLogged then
				-- Primera conexion: evento con la FUENTE de adquisicion (referido, teletransporte, enlace, directo).
				data.ftue.joinLogged = true
				local okJoin, joinData = pcall(function()
					return player:GetJoinData()
				end)
				local source = m.GameLogic.joinSource(if okJoin then joinData else nil)
				analytics:custom(player, "first_join", 1, { CustomField01 = source })
			end
			profile:markDirty()
			pushState(player)
			-- Si el personaje aparecio ANTES que el perfil, tiene la cana por defecto y esta en el Lago: se corrige aqui.
			refreshRod(player)
			if data.zone ~= "lake" then
				teleportToZone(player, data.zone)
			end
		end)
	end

	manager:attach(Players, function(callback: () -> ())
		game:BindToClose(callback)
	end, {
		onLoaded = onLoaded,
		onRemoving = function(player: Player, profile: any?)
			if profile ~= nil then
				profile.data.lastSeen = os.time() -- base del calculo de ganancias offline
				profile:markDirty()
			end
			net:forget(player)
			shop:unloadPlayer(player)
			analytics:forget(player)
			runtimes[player.UserId] = nil
			dirty[player.UserId] = nil
			funnelSessions[player.UserId] = nil
			offlineReady[player.UserId] = nil
			pendingIap[player.UserId] = nil -- compra concedida que no llego a confirmarse antes de salir: se prefiere no contar
		end,
	})
	manager:startAutosave()

	local function onCharacter(player: Player, character: Model)
		task.defer(function()
			-- Si el perfil cargo ANTES que el personaje, onLoaded no tenia a quien mover: se coloca al aparecer (y tras morir).
			local profile = profileOf(player)
			if profile ~= nil and profile.data.zone ~= "lake" then
				teleportToZone(player, profile.data.zone)
			end
			attachRod(player, character)
		end)
	end
	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function(character: Model)
			onCharacter(player, character)
		end)
	end)
	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function(character: Model)
			onCharacter(player, character)
		end)
	end

	----------------------------------------------------------------------------
	-- Pesca automatica (pase Auto-Pesca)
	----------------------------------------------------------------------------
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.clock()
			for _, player in Players:GetPlayers() do
				local profile = profileOf(player)
				-- REVIEW(money) OFFLINE-01: lastSeen (base de las ganancias offline) se mantiene "vivo" en memoria; el
				-- autosave y cualquier otro guardado lo persisten. Antes solo se fijaba al salir: tras un crash se pagaba como
				-- offline tambien el tiempo jugado (acotado por el tope). Solo tras pagar el offline de la entrada.
				if profile ~= nil and offlineReady[player.UserId] then
					profile.data.lastSeen = os.time()
				end
				local runtime = runtimes[player.UserId]
				if profile ~= nil and runtime ~= nil and profile.data.autoFish and now >= runtime.nextAutoAt then
					runtime.nextAutoAt = now + logic:autoInterval(profile.data)
					local result = logic:autoCast(profile.data, context(player))
					if result ~= nil then
						onCatch(player, profile, result, true)
					end
				end
			end
		end
	end)

	print("[FishFortune] servidor iniciado (" .. (if isPrivateServer then "servidor privado" else "publico") .. ")")
	return { manager = manager, shop = shop, liveOps = liveOps, logic = logic, net = net }
end

return GameService
