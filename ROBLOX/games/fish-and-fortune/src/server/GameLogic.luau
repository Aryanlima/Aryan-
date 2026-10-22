--!strict
--[[
	GameLogic: reglas de juego de Fish & Fortune sobre los datos del perfil. LOGICA PURA (sin servicios
	del motor, sin requires): todo llega por inyeccion, asi se prueba con Lune (tests/GameLogic.spec.luau).

	Autoridad del servidor: ninguna cantidad viene del cliente. El cliente solo pide ("lanza", "vende",
	"compra esta cana") y aqui se valida contra el estado.

	// REVIEW(money): grantProduct / grantReward / sellAll / buyRod mueven moneda del jugador.
]]

export type Context = {
	player: any?,
	passes: { [string]: boolean }, -- auto_fish, double_coins, luck_plus, vip, season_pass, starter
	events: { { id: string, kind: string, value: number, active: boolean } }, -- LiveOps.getModifierSources
	paidRandomAllowed: boolean, -- PolicyService: false => la suerte comprada con Robux no cuenta
	now: number, -- epoch (s)
}

export type Runtime = {
	cast: any?, -- sesion de lanzamiento en curso
	nextCastAt: number, -- os.clock: enfriamiento entre lanzamientos
	nextCastId: number,
	nextAutoAt: number,
}

export type CatchResult = {
	creatureId: string,
	rarity: string,
	kg: number,
	value: number,
	isNew: boolean,
	stored: boolean, -- false si el inventario estaba lleno y se vendio solo
	autoSoldFor: number?,
	quality: string?,
	luck: number,
	tutorial: boolean,
	zone: string,
}

local GameLogic = {}
GameLogic.__index = GameLogic

type LogicData = {
	balance: any,
	rules: any,
	economy: any,
	ledger: any,
	rng: () -> number,
	clock: () -> number,
	flags: { paidLuckEnabled: boolean },
}
export type Logic = typeof(setmetatable({} :: LogicData, GameLogic))

export type Deps = {
	balance: any,
	rules: any, -- FishingRules
	economy: any, -- packages/Economy
	rng: () -> number,
	clock: () -> number, -- os.clock
	onTransaction: ((transaction: any) -> ...any)?,
	flags: { paidLuckEnabled: boolean }?, -- FeatureFlags; por defecto la suerte de pago esta APAGADA
}

function GameLogic.new(deps: Deps): Logic
	local ledger = deps.economy.newLedger({
		currencies = {
			coins = { kind = "soft", maxBalance = deps.balance.limits.maxBalance },
			pearls = { kind = "hard", maxBalance = deps.balance.limits.pearlsMaxBalance },
		},
		onTransaction = deps.onTransaction,
	})
	local data: LogicData = {
		balance = deps.balance,
		rules = deps.rules,
		economy = deps.economy,
		ledger = ledger,
		rng = deps.rng,
		clock = deps.clock,
		flags = deps.flags or { paidLuckEnabled = false },
	}
	return setmetatable(data, GameLogic)
end

-- Plantilla de datos del perfil (el esquema de Data la usa junto a Shop.DATA_TEMPLATE).
function GameLogic.template(): { [string]: any }
	return {
		wallet = { coins = 0, pearls = 0 },
		rod = "driftwood",
		ownedRods = { driftwood = true },
		zone = "lake",
		unlockedZones = { lake = true },
		inventory = {},
		records = {},
		extraSlots = 0,
		bestiary = {},
		bestiaryClaimed = {},
		stats = { casts = 0, catches = 0, sells = 0, perfectCasts = 0, coinsEarned = 0 },
		ftue = { step = 0, joinLogged = false },
		boosts = {},
		autoFish = false,
		lastSeen = 0,
		redeemedCodes = {},
		seenWelcome = "",
		season = { id = 0, points = 0, claimedFree = {}, claimedPremium = {} },
		daily = { lastClaimDay = 0 },
		purchases = {},
		passGrants = {},
	}
end

--[[
	Fuente de la primera conexion para la analitica ("first_join"). Funcion pura sobre Player:GetJoinData():
	  "referral"          lo invito un jugador (ReferredByPlayerId)
	  "teleport"          viene de otro juego/lugar (SourceGameId / SourcePlaceId)
	  "share_<codigo>"    enlace compartido con LaunchData (solo A-Z a-z 0-9 _ -, maximo 20 caracteres)
	  "direct"            cualquier otro caso (Home, busqueda, amigos...)
	// VERIFIED: Player:GetJoinData() (creator-docs Player.yaml): SourceGameId, SourcePlaceId, ReferredByPlayerId,
	// Members, TeleportData, LaunchData (string).
]]
function GameLogic.joinSource(joinData: any): string
	if type(joinData) ~= "table" then
		return "direct"
	end
	if type(joinData.ReferredByPlayerId) == "number" then
		return "referral"
	end
	if type(joinData.SourceGameId) == "number" or type(joinData.SourcePlaceId) == "number" then
		return "teleport"
	end
	local launch = joinData.LaunchData
	if type(launch) == "string" and launch ~= "" then
		local cleaned = string.sub(string.gsub(launch, "[^%w_%-]", ""), 1, 20)
		if cleaned ~= "" then
			return "share_" .. cleaned
		end
	end
	return "direct"
end

function GameLogic.newRuntime(): Runtime
	return { cast = nil, nextCastAt = 0, nextCastId = 1, nextAutoAt = 0 }
end

----------------------------------------------------------------------------
-- Suerte y multiplicadores
----------------------------------------------------------------------------

-- `labelKey`: clave de texto (shared/Strings.luau) del nombre de la fuente; el cliente la traduce.
export type LuckSource = { id: string, labelKey: string, value: number, paid: boolean, active: boolean }

function GameLogic.luckSources(self: Logic, data: any, ctx: Context, quality: string?): { LuckSource }
	local balance = self.balance
	local list: { LuckSource } = {}
	local rod = balance.rods[data.rod]
	table.insert(list, { id = "rod", labelKey = "rod." .. data.rod, value = rod.luck, paid = false, active = true })
	local qualityLuck = self.rules:qualityLuck(quality)
	if qualityLuck > 0 then
		table.insert(
			list,
			{ id = "minigame", labelKey = "odds.source.perfect", value = qualityLuck, paid = false, active = true }
		)
	end
	for _, source in ctx.events do
		if source.kind == "luck" and source.active then
			table.insert(
				list,
				{ id = source.id, labelKey = "odds.source.event", value = source.value, paid = false, active = true }
			)
		end
	end
	-- Fuentes de pago (Suerte+ y Cebo): SOLO existen si el flag paidLuckEnabled esta encendido (v1.5) y, ademas,
	-- solo cuentan si PolicyService permite objetos aleatorios de pago. Con el flag apagado ni se listan.
	if self.flags.paidLuckEnabled then
		table.insert(list, {
			id = "pass:luck_plus",
			labelKey = "pass.luck_plus.name",
			value = balance.products.passes.luckPlus,
			paid = true,
			active = ctx.passes.luck_plus == true and ctx.paidRandomAllowed,
		})
		table.insert(list, {
			id = "boost:lucky_bait",
			labelKey = "product.lucky_bait_15.name",
			value = balance.products.luckyBait.luck,
			paid = true,
			active = self.economy.isBoostActive(data.boosts, "lucky_bait", ctx.now) and ctx.paidRandomAllowed,
		})
	end
	return list
end

-- Suerte total (limitada) y el desglose para mostrarlo en la UI.
function GameLogic.luck(self: Logic, data: any, ctx: Context, quality: string?): (number, { LuckSource })
	local list = self:luckSources(data, ctx, quality)
	local sources = {}
	for _, source in list do
		table.insert(sources, { id = source.id, kind = "luck", value = source.value, active = source.active })
	end
	local total = self.economy.sumBonuses(sources, "luck", self.balance.limits.maxLuck)
	return total, list
end

function GameLogic.coinMultiplier(self: Logic, data: any, ctx: Context): number
	local balance = self.balance
	local sources = {
		{
			id = "pass:double_coins",
			kind = "coins",
			value = balance.products.passes.doubleCoins,
			active = ctx.passes.double_coins == true,
		},
		{ id = "pass:vip", kind = "coins", value = balance.vip.coinBonus, active = ctx.passes.vip == true },
		{
			id = "boost:coin_boost",
			kind = "coins",
			value = balance.products.coinBoost.multiplier,
			active = self.economy.isBoostActive(data.boosts, "coin_boost", ctx.now),
		},
	}
	for _, source in ctx.events do
		if source.kind == "coins" and source.active then
			table.insert(sources, source)
		end
	end
	return self.economy.combineMultipliers(sources, "coins", balance.limits.coinMultiplierCap)
end

----------------------------------------------------------------------------
-- Inventario
----------------------------------------------------------------------------

function GameLogic.capacity(self: Logic, data: any): number
	return math.min(self.balance.inventory.baseSlots + data.extraSlots, self.balance.inventory.maxSlots)
end

function GameLogic.inventoryCount(_self: Logic, data: any): number
	local total = 0
	for _, count in data.inventory do
		total += count
	end
	return total
end

----------------------------------------------------------------------------
-- Recompensas y productos
----------------------------------------------------------------------------

-- Concede una recompensa { coins?, pearls?, slots? }. Las ranuras por encima del tope se convierten en perlas 1:1.
function GameLogic.grantReward(self: Logic, data: any, reward: any, reason: string, sku: string?, player: any?)
	local info = { reason = reason, sku = sku, player = player }
	if reward.coins and reward.coins > 0 then
		self.ledger:add(data.wallet, "coins", reward.coins, info)
	end
	local pearls = reward.pearls or 0
	if reward.slots and reward.slots > 0 then
		local maxExtra = self.balance.inventory.maxSlots - self.balance.inventory.baseSlots
		local room = math.max(0, maxExtra - data.extraSlots)
		local granted = math.min(room, reward.slots)
		data.extraSlots += granted
		pearls += reward.slots - granted
	end
	if pearls > 0 then
		self.ledger:add(data.wallet, "pearls", pearls, info)
	end
end

--[[
	Handler de concesion para packages/Shop (ProcessReceipt y concesiones unicas). Sin yields.
	product = { key, kind, grant }. Devuelve true solo si concedio.
]]
function GameLogic.grantProduct(self: Logic, player: any, profile: any, product: any, now: number): boolean
	local data = profile.data
	local grant = product.grant
	if type(grant) ~= "table" then
		return false
	end
	local kind = product.kind
	local sku = product.key
	if kind == "currency" then
		self:grantReward(data, grant, "IAP", sku, player)
		return true
	elseif kind == "slots" then
		self:grantReward(data, { slots = grant.slots }, "IAP", sku, player)
		return true
	elseif kind == "boost" then
		if type(grant.boostId) ~= "string" or type(grant.seconds) ~= "number" then
			return false
		end
		if grant.boostId == "lucky_bait" and not self.flags.paidLuckEnabled then
			return false -- defensa en profundidad: la suerte de pago esta apagada (el recibo queda sin resolver)
		end
		local expiresAt =
			self.economy.grantBoost(data.boosts, grant.boostId, grant.seconds, now, self.balance.limits.maxBoostSeconds)
		return expiresAt ~= nil
	end
	return false
end

--[[
	Veto previo al prompt (Shop.canPurchase): no se debe vender lo que el jugador pagaria sin recibir todo su valor.
	  * boost: si `restante + duracion` supera el tope de acumulacion (maxBoostSeconds), la compra se "comeria" parte
	    de lo pagado (grantBoost recorta) => "maxed".
	  * monedas/perlas: si el saldo + el pack superaria el tope del saldo, el exceso se perderia => "maxed".
	Devuelve (true) o (false, motivo).
]]
function GameLogic.canBuy(self: Logic, data: any, item: any, itemKind: string, now: number): (boolean, string?)
	if itemKind ~= "product" or type(item.grant) ~= "table" then
		return true, nil
	end
	local grant = item.grant
	if item.kind == "boost" and type(grant.boostId) == "string" and type(grant.seconds) == "number" then
		local remaining = self.economy.boostRemaining(data.boosts, grant.boostId, now)
		if remaining + grant.seconds > self.balance.limits.maxBoostSeconds then
			return false, "maxed"
		end
	elseif item.kind == "currency" then
		local limits = self.balance.limits
		if type(grant.coins) == "number" and data.wallet.coins + grant.coins > limits.maxBalance then
			return false, "maxed"
		end
		if type(grant.pearls) == "number" and data.wallet.pearls + grant.pearls > limits.pearlsMaxBalance then
			return false, "maxed"
		end
	end
	return true, nil
end

-- Handlers de concesion para packages/Shop (uno por `kind` del catalogo).
function GameLogic.shopHandlers(
	self: Logic,
	now: () -> number
): { [string]: (player: any, profile: any, product: any, receipt: any?) -> boolean }
	local function handler(player: any, profile: any, product: any, _receipt: any?): boolean
		return self:grantProduct(player, profile, product, now())
	end
	return { currency = handler, boost = handler, slots = handler }
end

----------------------------------------------------------------------------
-- Lanzar y recoger
----------------------------------------------------------------------------

-- Inicia el minijuego. Devuelve (sesion) o (nil, motivo).
function GameLogic.startCast(self: Logic, data: any, runtime: Runtime): (any?, string?)
	local now = self.clock()
	if now < runtime.nextCastAt then
		return nil, "cooldown"
	end
	if self:inventoryCount(data) >= self:capacity(data) then
		return nil, "inventory-full"
	end
	local id = runtime.nextCastId
	runtime.nextCastId += 1
	local session = self.rules:newCast(id, data.zone, data.rod, now, self.rng)
	runtime.cast = session
	return session, nil
end

function GameLogic.resolveCatch(self: Logic, data: any, ctx: Context, quality: string?): CatchResult
	local zone = data.zone
	local luck = self:luck(data, ctx, quality)
	local creatureId, tutorial = self.rules:pickCatch(zone, self.rng, luck, data.stats.casts)
	local creature = self.rules:creature(creatureId)
	assert(creature ~= nil, "criatura inexistente: " .. creatureId)

	data.stats.casts += 1
	data.stats.catches += 1
	if quality == "perfect" then
		data.stats.perfectCasts += 1
	end
	local isNew = data.bestiary[creatureId] == nil
	data.bestiary[creatureId] = (data.bestiary[creatureId] or 0) + 1
	-- Peso (solo muestra y record: el precio de venta no cambia, el inventario guarda cantidades).
	local range = self.balance.weightRanges[creature.rarity]
	local kg = math.floor((range.min + (range.max - range.min) * self.rng() ^ 2) * 100 + 0.5) / 100
	local record = data.records[creatureId]
	if record == nil or kg > record.kg then
		data.records[creatureId] = { kg = kg }
	end

	-- puntos de temporada
	if data.season.id ~= 0 then
		data.season.points += self.balance.rarities[creature.rarity].seasonPoints
	end

	local stored = true
	local autoSoldFor: number? = nil
	if self:inventoryCount(data) < self:capacity(data) then
		data.inventory[creatureId] = (data.inventory[creatureId] or 0) + 1
	else
		-- inventario lleno: se vende solo al precio normal (nunca se pierde una captura)
		stored = false
		local earned = self.economy.round(creature.value * self:coinMultiplier(data, ctx))
		local added = self.ledger:add(
			data.wallet,
			"coins",
			earned,
			{ reason = "Gameplay", sku = "fish_autosell", player = ctx.player }
		)
		data.stats.coinsEarned += added
		autoSoldFor = added
	end
	return {
		creatureId = creatureId,
		rarity = creature.rarity,
		kg = kg,
		value = creature.value,
		isNew = isNew,
		stored = stored,
		autoSoldFor = autoSoldFor,
		quality = quality,
		luck = luck,
		tutorial = tutorial,
		zone = zone,
	}
end

-- Recoger: valida el minijuego y resuelve la captura. Devuelve (resultado) o (nil, motivo).
function GameLogic.reel(
	self: Logic,
	data: any,
	runtime: Runtime,
	ctx: Context,
	castId: number,
	clientElapsed: number
): (CatchResult?, string?)
	local cast = runtime.cast
	if cast == nil or cast.id ~= castId then
		return nil, "no-cast"
	end
	local quality, reason = self.rules:evaluateReel(cast, clientElapsed, self.clock())
	if quality == nil then
		if reason == "expired" or reason == "stale" or reason == "missed" then
			runtime.cast = nil -- se soltó
			runtime.nextCastAt = self.clock() + self.balance.minigame.castCooldownSeconds
		end
		return nil, reason
	end
	runtime.cast = nil
	runtime.nextCastAt = self.clock() + self.balance.minigame.castCooldownSeconds
	return self:resolveCatch(data, ctx, quality), nil
end

-- Lanzamiento automatico (pase de Auto-Pesca): sin minijuego y sin bonus de calidad.
function GameLogic.autoCast(self: Logic, data: any, ctx: Context): CatchResult?
	if not ctx.passes.auto_fish then
		return nil
	end
	return self:resolveCatch(data, ctx, nil)
end

function GameLogic.autoInterval(self: Logic, data: any): number
	return self.balance.rods[data.rod].autoInterval
end

----------------------------------------------------------------------------
-- Venta, canas, zonas
----------------------------------------------------------------------------

-- Vende todo el inventario. Devuelve (monedasGanadas, cantidadDePeces).
function GameLogic.sellAll(self: Logic, data: any, ctx: Context): (number, number)
	local total = 0
	local count = 0
	for creatureId, amount in data.inventory do
		total += self.rules:sellValue(creatureId) * amount
		count += amount
	end
	if count == 0 then
		return 0, 0
	end
	local earned = self.economy.round(total * self:coinMultiplier(data, ctx))
	local added =
		self.ledger:add(data.wallet, "coins", earned, { reason = "Gameplay", sku = "fish_sale", player = ctx.player })
	data.inventory = {}
	data.stats.sells += 1
	data.stats.coinsEarned += added
	return added, count
end

function GameLogic.buyRod(self: Logic, data: any, rodId: string, player: any?): (boolean, string?)
	local rod = self.balance.rods[rodId]
	if rod == nil then
		return false, "unknown"
	end
	if data.ownedRods[rodId] then
		return false, "owned"
	end
	if
		not self.ledger:spend(
			data.wallet,
			"coins",
			rod.price,
			{ reason = "Shop", sku = "rod_" .. rodId, player = player }
		)
	then
		return false, "not-enough-coins"
	end
	data.ownedRods[rodId] = true
	-- equipa automaticamente si es mejor que la actual
	local current = self.balance.rods[data.rod]
	if rod.luck >= current.luck then
		data.rod = rodId
	end
	return true, nil
end

function GameLogic.equipRod(self: Logic, data: any, rodId: string): (boolean, string?)
	if self.balance.rods[rodId] == nil then
		return false, "unknown"
	end
	if not data.ownedRods[rodId] then
		return false, "not-owned"
	end
	data.rod = rodId
	return true, nil
end

function GameLogic.unlockZone(self: Logic, data: any, zoneId: string, player: any?): (boolean, string?)
	local zone = self.balance.zones[zoneId]
	if zone == nil then
		return false, "unknown"
	end
	if data.unlockedZones[zoneId] then
		return false, "owned"
	end
	if
		not self.ledger:spend(
			data.wallet,
			"coins",
			zone.unlockCost,
			{ reason = "Shop", sku = "zone_" .. zoneId, player = player }
		)
	then
		return false, "not-enough-coins"
	end
	data.unlockedZones[zoneId] = true
	return true, nil
end

function GameLogic.travel(self: Logic, data: any, zoneId: string): (boolean, string?)
	if self.balance.zones[zoneId] == nil then
		return false, "unknown"
	end
	if not data.unlockedZones[zoneId] then
		return false, "locked"
	end
	data.zone = zoneId
	return true, nil
end

-- Compra espacio con perlas (alternativa gratuita al producto de Robux).
function GameLogic.buySlotsWithPearls(self: Logic, data: any, player: any?): (boolean, string?)
	local inventory = self.balance.inventory
	if self:capacity(data) >= inventory.maxSlots then
		return false, "max-slots"
	end
	if
		not self.ledger:spend(
			data.wallet,
			"pearls",
			inventory.pearlsPerSlotPack,
			{ reason = "Shop", sku = "slots_pearls", player = player }
		)
	then
		return false, "not-enough-pearls"
	end
	data.extraSlots = math.min(data.extraSlots + inventory.slotsPerPack, inventory.maxSlots - inventory.baseSlots)
	return true, nil
end

----------------------------------------------------------------------------
-- Bestiario
----------------------------------------------------------------------------

function GameLogic.discoveries(self: Logic, data: any): number
	local count = 0
	for _, creature in self.balance.creatures do
		if data.bestiary[creature.id] ~= nil then
			count += 1
		end
	end
	return count
end

function GameLogic.zoneComplete(self: Logic, data: any, zoneId: string): boolean
	for _, creature in self.rules:creaturesOf(zoneId) do
		if data.bestiary[creature.id] == nil then
			return false
		end
	end
	return true
end

function GameLogic.claimBestiary(self: Logic, data: any, rewardId: string, player: any?): (boolean, string?)
	local reward: any = nil
	for _, candidate in self.balance.bestiary.rewards do
		if candidate.id == rewardId then
			reward = candidate
			break
		end
	end
	if reward == nil then
		return false, "unknown"
	end
	if data.bestiaryClaimed[rewardId] then
		return false, "claimed"
	end
	local reached = if reward.kind == "zone"
		then self:zoneComplete(data, reward.zone)
		else self:discoveries(data) >= reward.target
	if not reached then
		return false, "not-reached"
	end
	data.bestiaryClaimed[rewardId] = true -- se marca ANTES de conceder (un solo cobro)
	self:grantReward(data, reward.reward, "Gameplay", "bestiary_" .. rewardId, player)
	return true, nil
end

----------------------------------------------------------------------------
-- Temporada
----------------------------------------------------------------------------

-- Reinicia el progreso cuando cambia el id de temporada (los premios sin reclamar se pierden: avisarlo en la UI).
function GameLogic.seasonSync(_self: Logic, data: any, seasonId: number?)
	local id = seasonId or 0
	if data.season.id ~= id then
		data.season = { id = id, points = 0, claimedFree = {}, claimedPremium = {} }
	end
end

function GameLogic.claimSeason(self: Logic, data: any, tier: number, track: string, ctx: Context): (boolean, string?)
	if data.season.id == 0 then
		return false, "no-season"
	end
	local def: any = nil
	for _, candidate in self.balance.season.tiers do
		if candidate.tier == tier then
			def = candidate
			break
		end
	end
	if def == nil then
		return false, "unknown"
	end
	if data.season.points < def.points then
		return false, "not-reached"
	end
	local claimedTable, reward
	if track == "premium" then
		if not ctx.passes.season_pass then
			return false, "needs-pass"
		end
		claimedTable, reward = data.season.claimedPremium, def.premium
	elseif track == "free" then
		claimedTable, reward = data.season.claimedFree, def.free
	else
		return false, "unknown"
	end
	local key = "t" .. tostring(tier)
	if claimedTable[key] then
		return false, "claimed"
	end
	claimedTable[key] = true
	self:grantReward(data, reward, "Gameplay", "season_" .. track .. "_" .. tostring(tier), ctx.player)
	return true, nil
end

----------------------------------------------------------------------------
-- Diario VIP y offline
----------------------------------------------------------------------------

function GameLogic.claimDaily(self: Logic, data: any, ctx: Context): (boolean, string?)
	if not ctx.passes.vip then
		return false, "needs-vip"
	end
	local day = math.floor(ctx.now / 86400)
	if data.daily.lastClaimDay >= day then
		return false, "claimed"
	end
	data.daily.lastClaimDay = day
	self:grantReward(data, { pearls = self.balance.vip.dailyPearls }, "TimedReward", "vip_daily", ctx.player)
	return true, nil
end

-- Ganancias offline con tope. Devuelve (monedas, segundos, limitado).
function GameLogic.applyOffline(self: Logic, data: any, ctx: Context): (number, number, boolean)
	local offline = self.balance.offline
	local rod = self.balance.rods[data.rod]
	local result = self.economy.offlineEarnings({
		lastSeen = data.lastSeen,
		now = ctx.now,
		ratePerHour = rod.offlinePerHour,
		capSeconds = if ctx.passes.auto_fish then offline.autoFishCapSeconds else offline.baseCapSeconds,
		multiplier = self:coinMultiplier(data, ctx),
		minSeconds = offline.minSeconds,
	})
	data.lastSeen = ctx.now
	if result.amount > 0 then
		local added = self.ledger:add(
			data.wallet,
			"coins",
			result.amount,
			{ reason = "TimedReward", sku = "offline", player = ctx.player }
		)
		return added, result.seconds, result.capped
	end
	return 0, 0, false
end

return GameLogic
