--!strict
--[[
	FishingRules: reglas PURAS de pesca (sin motor, sin requires). Se usa en el servidor (tirada real) y
	en el cliente (UI de probabilidades) con LOS MISMOS datos: la tabla de odds sale de Balance via
	packages/Odds, asi lo que se muestra es exactamente lo que se sortea.

	Uso:  local rules = FishingRules.new(Balance, Odds)
]]

export type Quality = "perfect" | "good" | "ok"

export type CastSession = {
	id: number,
	zone: string,
	startedAt: number, -- reloj del servidor: momento de la PICADA (lanzamiento + bite)
	bite: number, -- segundos de espera hasta la picada
	center: number, -- centro de la zona perfecta (0..1)
	width: number, -- anchura de la zona perfecta
	expiresAt: number,
}

local FishingRules = {}
FishingRules.__index = FishingRules

type RulesData = {
	balance: any,
	odds: any, -- modulo packages/Odds
	tables: { [string]: any }, -- cache: zona -> OddsTable
	creatureById: { [string]: any },
	creaturesByZone: { [string]: { any } },
}
export type Rules = typeof(setmetatable({} :: RulesData, FishingRules))

function FishingRules.new(balance: any, oddsModule: any): Rules
	local byId: { [string]: any } = {}
	local byZone: { [string]: { any } } = {}
	for _, creature in balance.creatures do
		byId[creature.id] = creature
		local list = byZone[creature.zone]
		if list == nil then
			list = {}
			byZone[creature.zone] = list
		end
		table.insert(list, creature)
	end
	local data: RulesData = {
		balance = balance,
		odds = oddsModule,
		tables = {},
		creatureById = byId,
		creaturesByZone = byZone,
	}
	return setmetatable(data, FishingRules)
end

function FishingRules.creature(self: Rules, id: string): any?
	return self.creatureById[id]
end

function FishingRules.creaturesOf(self: Rules, zoneId: string): { any }
	return self.creaturesByZone[zoneId] or {}
end

-- Entradas de Odds de una zona (id, peso, rareza, factor de suerte por rareza, valor).
function FishingRules.entriesFor(self: Rules, zoneId: string): { any }
	local entries = {}
	for _, creature in self:creaturesOf(zoneId) do
		local rarity = self.balance.rarities[creature.rarity]
		table.insert(entries, {
			id = creature.id, -- sin `label`: el nombre visible lo pone el cliente (Strings: creature.<id>)
			weight = creature.weight,
			rarity = creature.rarity,
			luckFactor = rarity.luckFactor,
			value = creature.value,
		})
	end
	return entries
end

-- La tabla de probabilidades de una zona (cacheada). UNICA fuente de la tirada y de la UI.
function FishingRules.oddsFor(self: Rules, zoneId: string): any
	local cached = self.tables[zoneId]
	if cached ~= nil then
		return cached
	end
	local built = self.odds.new(self:entriesFor(zoneId), {
		decimals = self.balance.decimals,
		maxLuck = self.balance.limits.maxLuck,
	})
	self.tables[zoneId] = built
	return built
end

--[[
	Elige la captura. Los primeros lanzamientos (`casts` < #ftue) estan garantizados por rareza:
	se EXCLUYE de la misma tabla todo lo que no sea de la rareza garantizada (misma tabla, sin ruta aparte).
]]
function FishingRules.pickCatch(
	self: Rules,
	zoneId: string,
	rng: () -> number,
	luck: number,
	casts: number
): (string, boolean)
	local odds = self:oddsFor(zoneId)
	local guaranteed = self.balance.ftue.guaranteedRarities[casts + 1]
	local exclude: { [string]: boolean }? = nil
	if guaranteed ~= nil then
		local excluded: { [string]: boolean } = {}
		local kept = 0
		for _, creature in self:creaturesOf(zoneId) do
			if creature.rarity ~= guaranteed then
				excluded[creature.id] = true
			else
				kept += 1
			end
		end
		if kept > 0 then
			exclude = excluded
		end
	end
	local id = odds:roll(rng, luck, exclude)
	return id, exclude ~= nil
end

function FishingRules.sellValue(self: Rules, creatureId: string): number
	local creature = self.creatureById[creatureId]
	return if creature then creature.value else 0
end

----------------------------------------------------------------------------
-- Minijuego
----------------------------------------------------------------------------

-- Onda triangular 0..1..0 con periodo `period` (posicion del marcador en el instante t).
function FishingRules.markerPosition(self: Rules, t: number): number
	local period = self.balance.minigame.markerPeriod
	local phase = (t % period) / period -- 0..1
	return if phase < 0.5 then phase * 2 else (1 - phase) * 2
end

--[[
	Nueva sesion de lanzamiento. `rng` decide el centro de la zona perfecta.
]]
function FishingRules.newCast(
	self: Rules,
	id: number,
	zoneId: string,
	rodId: string,
	now: number,
	rng: () -> number
): CastSession
	local minigame = self.balance.minigame
	local rod = self.balance.rods[rodId]
	local center = minigame.centerMin + rng() * (minigame.centerMax - minigame.centerMin)
	-- Picada: el minijuego empieza cuando muerde el pez (startedAt), no al lanzar.
	local bite = minigame.biteMinSeconds + rng() * (minigame.biteMaxSeconds - minigame.biteMinSeconds)
	local startedAt = now + bite
	return {
		id = id,
		zone = zoneId,
		startedAt = startedAt,
		bite = bite,
		center = center,
		width = rod.sweetSpot,
		expiresAt = startedAt + minigame.durationSeconds + minigame.graceSeconds,
	}
end

--[[
	Evalua el momento de recoger. `clientElapsed` es lo que dice el cliente; el servidor lo contrasta con
	su propio reloj (`now - startedAt`) y rechaza lo imposible. Devuelve (calidad) o (nil, motivo).
	Nota: un script que calcule el momento perfecto siempre podra acertar la zona (bonus pequeno y gratuito);
	lo que NO puede es inventar tiempos imposibles ni recoger antes del minimo.
]]
function FishingRules.evaluateReel(
	self: Rules,
	cast: CastSession,
	clientElapsed: number,
	now: number
): (Quality?, string?)
	local minigame = self.balance.minigame
	if now > cast.expiresAt then
		return nil, "expired"
	end
	if now < cast.startedAt then
		return nil, "too-early" -- todavia no ha picado (el lanzamiento sigue activo)
	end
	local serverElapsed = now - cast.startedAt
	if clientElapsed ~= clientElapsed or clientElapsed < minigame.minReelSeconds then
		return nil, "too-early"
	end
	if clientElapsed > serverElapsed + minigame.timingTolerance then
		return nil, "impossible-time" -- dice haber esperado mas de lo que ha pasado
	end
	if clientElapsed < serverElapsed - minigame.maxLagSeconds then
		return nil, "stale"
	end
	if clientElapsed > minigame.durationSeconds + minigame.graceSeconds then
		return nil, "expired"
	end
	local distance = math.abs(self:markerPosition(clientElapsed) - cast.center)
	local half = cast.width / 2
	if distance <= half then
		return "perfect", nil
	elseif distance <= half * minigame.goodWidthFactor then
		return "good", nil
	end
	return nil, "missed" -- fuera de la zona verde (y de su margen): el pez se escapa
end

function FishingRules.qualityLuck(self: Rules, quality: Quality?): number
	if quality == "perfect" then
		return self.balance.minigame.perfectLuck
	elseif quality == "good" then
		return self.balance.minigame.goodLuck
	end
	return 0
end

return FishingRules
