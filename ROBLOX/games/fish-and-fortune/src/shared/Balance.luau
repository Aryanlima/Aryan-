--!strict
--[[
	Balance de Fish & Fortune: TODO el balance vive aqui (datos puros, sin logica ni requires).
	Para ajustar el juego se edita ESTE archivo; los tests (tests/Balance.spec.luau) comprueban que
	sigue siendo coherente (odds validas, FTUE en <= 60 s, sin resultados sin valor, etc.).

	Convenciones:
	  * Monedas: `coins` (blanda, se gana jugando) y `pearls` (dura, escasa: bestiario, temporada, packs).
	  * Suerte: puntos aditivos. Cada punto multiplica el peso relativo de una rareza por su `luckFactor`
	    (ver packages/Odds). La suerte total se limita a `limits.maxLuck`.
	  * Los precios en Robux NO estan aqui (ver server/Catalog.luau y la escalera de Shop).
	  * Este modulo es seguro para ReplicatedStorage: no contiene IDs de compra ni secretos.
]]

export type RarityInfo = {
	order: number,
	luckFactor: number,
	seasonPoints: number,
}

export type Creature = {
	id: string,
	zone: string,
	rarity: string,
	weight: number, -- peso en la tabla de probabilidades de su zona
	value: number, -- monedas al vender (antes de multiplicadores)
}

export type Zone = {
	id: string,
	order: number,
	unlockCost: number, -- monedas; 0 = disponible desde el principio
}

export type Rod = {
	id: string,
	price: number, -- monedas
	luck: number, -- puntos de suerte (gratis: se gana jugando)
	sweetSpot: number, -- anchura de la zona perfecta del minijuego (fraccion de la barra)
	autoInterval: number, -- segundos entre lanzamientos automaticos
	offlinePerHour: number, -- monedas/hora acumulables offline
	color: { number },
}

export type Reward = { coins: number?, pearls: number?, slots: number? }

export type BestiaryReward = {
	id: string,
	kind: string, -- "discoveries" | "zone"
	target: number?, -- descubrimientos necesarios (kind = discoveries)
	zone: string?, -- zona completa (kind = zone)
	reward: Reward,
}

export type SeasonTier = {
	tier: number,
	points: number, -- puntos de temporada acumulados necesarios
	free: Reward,
	premium: Reward,
}

local Balance = {}

----------------------------------------------------------------------------
-- Rarezas
----------------------------------------------------------------------------

Balance.rarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }

Balance.rarities = {
	Common = { order = 1, luckFactor = 1, seasonPoints = 1 },
	Uncommon = { order = 2, luckFactor = 1.04, seasonPoints = 2 },
	Rare = { order = 3, luckFactor = 1.09, seasonPoints = 5 },
	Epic = { order = 4, luckFactor = 1.16, seasonPoints = 15 },
	Legendary = { order = 5, luckFactor = 1.28, seasonPoints = 50 },
	Mythic = { order = 6, luckFactor = 1.45, seasonPoints = 200 },
} :: { [string]: RarityInfo }

----------------------------------------------------------------------------
-- Limites
----------------------------------------------------------------------------

Balance.limits = {
	maxLuck = 8, -- tope de puntos de suerte (todas las fuentes juntas)
	coinMultiplierCap = 8, -- tope del multiplicador de monedas (aditivo)
	maxBoostSeconds = 3600, -- un boost no puede acumular mas de 1 h restante
	maxBalance = 1e12,
	pearlsMaxBalance = 1e9,
}

Balance.decimals = 2 -- decimales mostrados en la UI de probabilidades

----------------------------------------------------------------------------
-- Zonas (3) y criaturas (25)
----------------------------------------------------------------------------

Balance.zoneOrder = { "lake", "river", "coast" }

Balance.zones = {
	lake = {
		id = "lake",
		order = 1,
		unlockCost = 0,
	},
	river = {
		id = "river",
		order = 2,
		unlockCost = 2000,
	},
	coast = {
		id = "coast",
		order = 3,
		unlockCost = 30000,
	},
} :: { [string]: Zone }

Balance.creatures = {
	-- Lago Calmo (9)
	{ id = "minnow", zone = "lake", rarity = "Common", weight = 320, value = 8 },
	{ id = "perch", zone = "lake", rarity = "Common", weight = 260, value = 12 },
	{ id = "carp", zone = "lake", rarity = "Common", weight = 190, value = 18 },
	{ id = "bluegill", zone = "lake", rarity = "Uncommon", weight = 100, value = 40 },
	{ id = "catfish", zone = "lake", rarity = "Uncommon", weight = 60, value = 60 },
	{ id = "golden_trout", zone = "lake", rarity = "Rare", weight = 45, value = 160 },
	{ id = "moon_koi", zone = "lake", rarity = "Epic", weight = 18, value = 900 },
	{ id = "ancient_carp", zone = "lake", rarity = "Legendary", weight = 6, value = 6000 },
	{ id = "lake_spirit", zone = "lake", rarity = "Mythic", weight = 0.4, value = 60000 },
	-- Rio Cristal (8)
	{ id = "chub", zone = "river", rarity = "Common", weight = 350, value = 45 },
	{ id = "salmon", zone = "river", rarity = "Common", weight = 300, value = 70 },
	{ id = "eel", zone = "river", rarity = "Uncommon", weight = 120, value = 200 },
	{ id = "glass_shrimp", zone = "river", rarity = "Uncommon", weight = 80, value = 260 },
	{ id = "rapids_trout", zone = "river", rarity = "Rare", weight = 60, value = 800 },
	{ id = "crystal_pike", zone = "river", rarity = "Epic", weight = 20, value = 4500 },
	{
		id = "aurora_sturgeon",
		zone = "river",
		rarity = "Legendary",
		weight = 6,
		value = 30000,
	},
	{ id = "river_queen", zone = "river", rarity = "Mythic", weight = 0.4, value = 300000 },
	-- Costa Dorada (8)
	{ id = "sand_crab", zone = "coast", rarity = "Common", weight = 350, value = 250 },
	{ id = "sardine", zone = "coast", rarity = "Common", weight = 300, value = 350 },
	{ id = "mackerel", zone = "coast", rarity = "Uncommon", weight = 120, value = 1000 },
	{ id = "clownfish", zone = "coast", rarity = "Uncommon", weight = 80, value = 1300 },
	{ id = "tuna", zone = "coast", rarity = "Rare", weight = 60, value = 4000 },
	{ id = "manta", zone = "coast", rarity = "Epic", weight = 20, value = 22000 },
	{ id = "golden_marlin", zone = "coast", rarity = "Legendary", weight = 6, value = 150000 },
	{
		id = "tide_leviathan",
		zone = "coast",
		rarity = "Mythic",
		weight = 0.4,
		value = 1500000,
	},
} :: { Creature }

----------------------------------------------------------------------------
-- Canas (5)
----------------------------------------------------------------------------

Balance.rodOrder = { "driftwood", "reed", "fiberglass", "carbon", "golden" }

Balance.rods = {
	driftwood = {
		id = "driftwood",
		price = 0,
		luck = 0,
		sweetSpot = 0.14,
		autoInterval = 10,
		offlinePerHour = 40,
		color = { 150, 110, 70 },
	},
	reed = {
		id = "reed",
		price = 120,
		luck = 0.5,
		sweetSpot = 0.16,
		autoInterval = 9,
		offlinePerHour = 120,
		color = { 120, 170, 90 },
	},
	fiberglass = {
		id = "fiberglass",
		price = 2500,
		luck = 1,
		sweetSpot = 0.18,
		autoInterval = 8,
		offlinePerHour = 900,
		color = { 90, 170, 230 },
	},
	carbon = {
		id = "carbon",
		price = 30000,
		luck = 1.8,
		sweetSpot = 0.2,
		autoInterval = 7,
		offlinePerHour = 7000,
		color = { 60, 60, 75 },
	},
	golden = {
		id = "golden",
		price = 400000,
		luck = 2.6,
		sweetSpot = 0.22,
		autoInterval = 6,
		offlinePerHour = 55000,
		color = { 255, 200, 70 },
	},
} :: { [string]: Rod }

----------------------------------------------------------------------------
-- Minijuego de lanzamiento (~3 s)
----------------------------------------------------------------------------

Balance.minigame = {
	durationSeconds = 3, -- ventana para recoger
	graceSeconds = 1.2, -- margen por latencia antes de dar el lanzamiento por perdido
	markerPeriod = 1.5, -- el marcador va y vuelve en este tiempo (onda triangular)
	minReelSeconds = 0.35, -- no se puede recoger antes (evita clics a ciegas)
	centerMin = 0.25,
	centerMax = 0.75,
	goodWidthFactor = 2, -- "bien" = zona perfecta x2
	perfectLuck = 1, -- puntos de suerte GRATIS por recoger en la zona perfecta
	goodLuck = 0.4,
	castCooldownSeconds = 1, -- minimo entre lanzamientos
	biteMinSeconds = 1.5, -- espera hasta que pica (al azar entre min y max); antes no se puede recoger
	biteMaxSeconds = 4,
	fishReach = 7, -- studs desde la orilla o el muelle en los que se puede lanzar
	timingTolerance = 0.35, -- el tiempo que dice el cliente no puede superar al del servidor en mas de esto
	maxLagSeconds = 2.5, -- ...ni quedarse por debajo en mas de esto
}

----------------------------------------------------------------------------
-- Inventario, pesca automatica, offline
----------------------------------------------------------------------------

Balance.inventory = {
	baseSlots = 20,
	slotsPerPack = 10,
	maxSlots = 200,
	pearlsPerSlotPack = 10, -- alternativa gratuita al producto de Robux
}

Balance.autoFish = {
	-- La pesca automatica NO obtiene el bonus del minijuego.
	requiresPass = true,
}

Balance.offline = {
	baseCapSeconds = 2 * 3600,
	autoFishCapSeconds = 6 * 3600, -- el pase de Auto-Pesca amplia el tope (comodidad, no poder nuevo)
	minSeconds = 120,
}

----------------------------------------------------------------------------
-- Tutorial (FTUE): los 3 primeros lanzamientos estan garantizados (premio de juego, gratis)
----------------------------------------------------------------------------

Balance.ftue = {
	guaranteedRarities = { "Uncommon", "Uncommon", "Rare" },
	-- (el texto "tus N primeros lanzamientos..." esta en Strings: ftue.odds_note)
	targetSeconds = 60, -- primera captura y primera venta en <= 60 s
}

----------------------------------------------------------------------------
-- Bestiario
----------------------------------------------------------------------------

Balance.bestiary = {
	rewards = {
		{ id = "disc_5", kind = "discoveries", target = 5, reward = { coins = 500 } },
		{ id = "disc_10", kind = "discoveries", target = 10, reward = { pearls = 5 } },
		{
			id = "disc_15",
			kind = "discoveries",
			target = 15,
			reward = { coins = 25000 },
		},
		{
			id = "disc_20",
			kind = "discoveries",
			target = 20,
			reward = { pearls = 15 },
		},
		{
			id = "disc_25",
			kind = "discoveries",
			target = 25,
			reward = { pearls = 40, coins = 500000 },
		},
		{
			id = "zone_lake",
			kind = "zone",
			zone = "lake",
			reward = { coins = 2000, pearls = 5 },
		},
		{
			id = "zone_river",
			kind = "zone",
			zone = "river",
			reward = { coins = 30000, pearls = 10 },
		},
		{
			id = "zone_coast",
			kind = "zone",
			zone = "coast",
			reward = { coins = 400000, pearls = 20 },
		},
	} :: { BestiaryReward },
}

----------------------------------------------------------------------------
-- Pase de temporada basico (10 niveles). Premios sin azar: monedas, perlas y espacio.
----------------------------------------------------------------------------

Balance.season = {
	tiers = {
		{ tier = 1, points = 40, free = { coins = 300 }, premium = { pearls = 5 } },
		{ tier = 2, points = 120, free = { coins = 800 }, premium = { coins = 2000 } },
		{ tier = 3, points = 260, free = { pearls = 2 }, premium = { slots = 5 } },
		{ tier = 4, points = 480, free = { coins = 5000 }, premium = { pearls = 8 } },
		{ tier = 5, points = 800, free = { pearls = 3 }, premium = { coins = 20000 } },
		{ tier = 6, points = 1250, free = { coins = 30000 }, premium = { pearls = 12 } },
		{ tier = 7, points = 1900, free = { pearls = 4 }, premium = { slots = 10 } },
		{ tier = 8, points = 2800, free = { coins = 120000 }, premium = { pearls = 20 } },
		{ tier = 9, points = 4000, free = { pearls = 6 }, premium = { coins = 400000 } },
		{ tier = 10, points = 5600, free = { coins = 500000 }, premium = { pearls = 40, slots = 10 } },
	} :: { SeasonTier },
}

----------------------------------------------------------------------------
-- VIP
----------------------------------------------------------------------------

Balance.vip = {
	coinBonus = 1.1, -- multiplicador de monedas aditivo (+10 %)
	dailyPearls = 5,
}

----------------------------------------------------------------------------
-- Contenido de los productos de Robux (importes; los precios estan en server/Catalog.luau)
----------------------------------------------------------------------------

Balance.products = {
	luckyBait = { luck = 4, seconds = 900 }, -- Cebo de Suerte: +4 suerte 15 min (ALTERA PROBABILIDADES)
	coinBoost = { multiplier = 2, seconds = 900 }, -- Boost de monedas x2 15 min
	coinPackSmall = { coins = 2500 },
	coinPackMedium = { coins = 15000 },
	coinPackLarge = { coins = 80000 },
	pearlPack = { pearls = 30 },
	slotPack = { slots = 10 },
	starterPack = { coins = 600, pearls = 10, slots = 10 }, -- sin azar ni bonus de suerte (si no, seria "pack aleatorio")
	passes = {
		doubleCoins = 2, -- Pase 2x Dinero
		luckPlus = 3, -- Pase Suerte+ (ALTERA PROBABILIDADES): +3 puntos de suerte
	},
}

----------------------------------------------------------------------------
-- Mensajes globales
----------------------------------------------------------------------------

Balance.mythicBanner = {
	topic = "FishFortune_Mythic",
	cooldownSeconds = 5, -- minimo entre publicaciones de un servidor (MessagingService tiene cuotas)
	displaySeconds = 6,
}

return Balance
