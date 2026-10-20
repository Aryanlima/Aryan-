--!strict
--[[
	Odds: UNA tabla de probabilidades que genera, a la vez,
	  (1) la tirada del servidor (con RNG inyectable para tests), y
	  (2) los datos de la UI de probabilidades (cumplimiento de "Paid Random Items").

	Por que una sola tabla: si la UI y la logica leyeran datos distintos, lo que se muestra
	podria diferir de lo que se sortea (incumplimiento y riesgo de moderacion). Aqui no puede.

	Reglas de cumplimiento que este modulo IMPONE (ver research/03 seccion 2.1):
	  * Cada resultado se muestra con su porcentaje numerico real; la suma mostrada es EXACTAMENTE
	    100 % (metodo del resto mayor), y ninguna fila se muestra como 0 %.
	  * No existe el resultado "nada": se rechazan ids tipo nothing/none/miss y valores <= 0.
	  * Un modificador de suerte cambia las probabilidades MOSTRADAS (displayRows(luck)), con la
	    columna "base" al lado, para que su efecto numerico sea visible.
	  * Pity: solo se acepta si trae un texto visible (`note`); displayRows SIEMPRE lo incluye.
	  * Gating por PolicyService: paidRandomAllowed(policy) (por defecto restringido si no hay datos).

	Modelo de suerte (documentado y visible para el jugador):
	  peso efectivo de la entrada i = weight_i * luckFactor_i ^ luck
	  luckFactor > 1 favorece a esa entrada (raros), 1 es neutro. La probabilidad es el peso
	  efectivo normalizado. `luck` es un numero >= 0 limitado a Options.maxLuck.

	Sin dependencias del motor: se prueba con Lune.
]]

export type RandomFn = () -> number

export type Entry = {
	id: string,
	weight: number,
	label: string?,
	rarity: string?,
	luckFactor: number?,
	value: number?, -- valor para el jugador (p. ej. precio de venta). Si existe debe ser > 0.
}

export type PityConfig = {
	rolls: number, -- tras `rolls - 1` fallos seguidos, la tirada `rolls` esta garantizada
	targetIds: { string },
	note: string, -- texto visible para el jugador (obligatorio)
}

export type Options = {
	decimals: number?, -- decimales mostrados (0..4, por defecto 2)
	maxLuck: number?, -- tope de suerte (por defecto 0: sin suerte)
	pity: PityConfig?,
}

export type Exclude = { [string]: boolean }

export type DisplayRow = {
	id: string,
	label: string,
	rarity: string?,
	probability: number, -- exacta (0..1) con la suerte actual
	percent: number, -- redondeada para mostrar
	percentText: string, -- p. ej. "12.34%"
	basePercentText: string, -- sin suerte
}

export type DisplayView = {
	rows: { DisplayRow },
	totalPercentText: string, -- siempre "100.00%" (segun decimales)
	baseTotalPercentText: string,
	luck: number, -- suerte efectiva (ya limitada)
	luckActive: boolean,
	pityNote: string?,
	decimals: number,
}

export type DisplayOptions = {
	luck: number?,
	exclude: Exclude?,
	sort: string?, -- "probability" (por defecto, mayor a menor) | "entry" (orden de la tabla)
}

local Odds = {}

local OddsTable = {}
OddsTable.__index = OddsTable

type OddsTableData = {
	entries: { Entry },
	decimals: number,
	maxLuck: number,
	pity: PityConfig?,
	indexById: { [string]: number },
}

export type OddsTable = typeof(setmetatable({} :: OddsTableData, OddsTable))

local FORBIDDEN_IDS: { [string]: boolean } = {
	nothing = true,
	none = true,
	nada = true,
	miss = true,
	empty = true,
	blank = true,
	fail = true,
	null = true,
	["nil"] = true,
}

----------------------------------------------------------------------------
-- Utilidades puras
----------------------------------------------------------------------------

local function isFiniteNumber(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function sanitizeLuck(luck: number?, maxLuck: number): number
	if luck == nil or not isFiniteNumber(luck) then
		return 0
	end
	return math.clamp(luck :: number, 0, maxLuck)
end

local function effectiveWeight(entry: Entry, luck: number): number
	local factor = entry.luckFactor or 1
	if luck == 0 or factor == 1 then
		return entry.weight
	end
	return entry.weight * factor ^ luck
end

local function computeProbabilities(entries: { Entry }, luck: number, exclude: Exclude?): { number }
	local weights: { number } = {}
	local total = 0
	for index, entry in entries do
		local weight = 0
		if not (exclude and exclude[entry.id]) then
			weight = effectiveWeight(entry, luck)
		end
		weights[index] = weight
		total += weight
	end
	local probabilities: { number } = {}
	for index, weight in weights do
		probabilities[index] = if total > 0 then weight / total else 0
	end
	return probabilities
end

type Remainder = { index: number, fraction: number }

--[[
	Reparte `100 * 10^decimals` unidades entre las probabilidades con el metodo del resto mayor.
	La suma de las unidades devueltas es EXACTAMENTE ese total y nadie con p > 0 se queda en 0.
]]
function Odds.allocateUnits(probabilities: { number }, decimals: number): { number }
	local scale = 10 ^ decimals
	local totalUnits = math.floor(100 * scale + 0.5)
	local units: { number } = {}
	local remainders: { Remainder } = {}
	local assigned = 0
	for index, p in probabilities do
		local exact = p * totalUnits
		local base = math.floor(exact)
		units[index] = base
		assigned += base
		table.insert(remainders, { index = index, fraction = exact - base })
	end
	table.sort(remainders, function(a: Remainder, b: Remainder): boolean
		if a.fraction ~= b.fraction then
			return a.fraction > b.fraction
		end
		return a.index < b.index
	end)
	local missing = totalUnits - assigned
	local cursor = 1
	while missing > 0 and #remainders > 0 do
		-- solo reparte a quien tiene p > 0
		local candidate = remainders[cursor]
		if probabilities[candidate.index] > 0 then
			units[candidate.index] += 1
			missing -= 1
		end
		cursor += 1
		if cursor > #remainders then
			cursor = 1
		end
	end
	-- Seguridad: ninguna fila con p > 0 puede quedar en 0 (se le presta 1 unidad a la mayor).
	for index, p in probabilities do
		if p > 0 and units[index] < 1 then
			local largest = 1
			for other, value in units do
				if value > units[largest] then
					largest = other
				end
			end
			if units[largest] > 1 then
				units[largest] -= 1
				units[index] = 1
			end
		end
	end
	return units
end

local function formatUnits(units: number, decimals: number): string
	local value = units / 10 ^ decimals
	return string.format("%." .. tostring(decimals) .. "f", value) .. "%"
end

Odds.formatUnits = formatUnits

----------------------------------------------------------------------------
-- Validacion y construccion
----------------------------------------------------------------------------

--[[
	Devuelve (true) o (false, motivo). No lanza.
]]
function Odds.validate(entries: { Entry }, options: Options?): (boolean, string?)
	local opts: Options = options or {}
	local decimals = opts.decimals or 2
	if type(entries) ~= "table" or #entries == 0 then
		return false, "la tabla de odds esta vacia"
	end
	if decimals ~= math.floor(decimals) or decimals < 0 or decimals > 4 then
		return false, "decimals debe ser un entero entre 0 y 4"
	end
	local maxLuck = opts.maxLuck or 0
	if not isFiniteNumber(maxLuck) or maxLuck < 0 then
		return false, "maxLuck debe ser un numero finito >= 0"
	end

	local seen: { [string]: boolean } = {}
	for index, entry in entries do
		if type(entry) ~= "table" or type(entry.id) ~= "string" or entry.id == "" then
			return false, "entrada #" .. index .. " sin id valido"
		end
		if seen[entry.id] then
			return false, "id duplicado: " .. entry.id
		end
		seen[entry.id] = true
		if FORBIDDEN_IDS[string.lower(entry.id)] then
			return false, "resultado 'nada' no permitido (cumplimiento): " .. entry.id
		end
		if not isFiniteNumber(entry.weight) or entry.weight <= 0 then
			return false, "weight invalido (debe ser finito y > 0) en " .. entry.id
		end
		if entry.luckFactor ~= nil and (not isFiniteNumber(entry.luckFactor) or entry.luckFactor <= 0) then
			return false, "luckFactor invalido en " .. entry.id
		end
		if entry.value ~= nil and (not isFiniteNumber(entry.value) or entry.value <= 0) then
			return false, "resultado sin valor para el jugador (value <= 0) en " .. entry.id
		end
	end

	-- Ninguna fila debe mostrarse como 0 % (ni sin suerte ni con la suerte maxima).
	local minimumUnit = 1 / (100 * 10 ^ decimals)
	for _, luck in { 0, maxLuck } do
		local probabilities = computeProbabilities(entries, luck, nil)
		for index, p in probabilities do
			if p < minimumUnit then
				return false,
					string.format(
						"la entrada %s tendria una probabilidad menor que la unidad mostrable (%.6f) con suerte %s",
						entries[index].id,
						p,
						tostring(luck)
					)
			end
		end
	end

	if opts.pity then
		local pity = opts.pity
		if not isFiniteNumber(pity.rolls) or pity.rolls < 2 or pity.rolls ~= math.floor(pity.rolls) then
			return false, "pity.rolls debe ser un entero >= 2"
		end
		if type(pity.note) ~= "string" or pity.note == "" then
			return false, "el pity debe tener un texto visible (pity.note): cumplimiento"
		end
		if #pity.targetIds == 0 then
			return false, "pity sin targetIds"
		end
		for _, id in pity.targetIds do
			if not seen[id] then
				return false, "pity apunta a un id inexistente: " .. tostring(id)
			end
		end
	end
	return true, nil
end

function Odds.new(entries: { Entry }, options: Options?): OddsTable
	local ok, reason = Odds.validate(entries, options)
	if not ok then
		error("Odds.new: " .. tostring(reason), 2)
	end
	local opts: Options = options or {}
	local copy: { Entry } = {}
	local indexById: { [string]: number } = {}
	for index, entry in entries do
		copy[index] = table.clone(entry)
		indexById[entry.id] = index
	end
	local data: OddsTableData = {
		entries = copy,
		decimals = opts.decimals or 2,
		maxLuck = opts.maxLuck or 0,
		pity = opts.pity,
		indexById = indexById,
	}
	return setmetatable(data, OddsTable)
end

----------------------------------------------------------------------------
-- Consulta y tirada
----------------------------------------------------------------------------

function OddsTable.getEntry(self: OddsTable, id: string): Entry?
	local index = self.indexById[id]
	return if index then self.entries[index] else nil
end

function OddsTable.sanitizeLuck(self: OddsTable, luck: number?): number
	return sanitizeLuck(luck, self.maxLuck)
end

-- Probabilidades (0..1) en el orden de `entries`. Suman 1.
function OddsTable.probabilities(self: OddsTable, luck: number?, exclude: Exclude?): { number }
	return computeProbabilities(self.entries, sanitizeLuck(luck, self.maxLuck), exclude)
end

function OddsTable.probabilityOf(self: OddsTable, id: string, luck: number?, exclude: Exclude?): number
	local index = self.indexById[id]
	if not index then
		return 0
	end
	return self:probabilities(luck, exclude)[index]
end

local function pickIndex(probabilities: { number }, rng: RandomFn): number
	local roll = rng()
	if not isFiniteNumber(roll) or roll < 0 then
		roll = 0
	elseif roll >= 1 then
		roll = 1 - 2 ^ -53
	end
	local accumulated = 0
	local lastPositive = 0
	for index, p in probabilities do
		if p > 0 then
			accumulated += p
			lastPositive = index
			if roll < accumulated then
				return index
			end
		end
	end
	if lastPositive == 0 then
		error("Odds: todas las probabilidades son 0 (todo excluido?)", 3)
	end
	return lastPositive -- redondeo de coma flotante: cae en la ultima entrada posible
end

-- Tirada del servidor. `rng` devuelve un numero en [0, 1).
function OddsTable.roll(self: OddsTable, rng: RandomFn, luck: number?, exclude: Exclude?): string
	local probabilities = self:probabilities(luck, exclude)
	return self.entries[pickIndex(probabilities, rng)].id
end

--[[
	Tirada con pity visible. `counter` = tiradas consecutivas SIN resultado objetivo.
	Devuelve (id, nuevoContador). Sin pity configurado equivale a roll().
]]
function OddsTable.rollWithPity(
	self: OddsTable,
	rng: RandomFn,
	luck: number?,
	exclude: Exclude?,
	counter: number
): (string, number)
	local pity = self.pity
	if not pity then
		return self:roll(rng, luck, exclude), 0
	end
	local isTarget: { [string]: boolean } = {}
	for _, id in pity.targetIds do
		isTarget[id] = true
	end
	local probabilities = self:probabilities(luck, exclude)
	local forced = counter >= pity.rolls - 1
	if forced then
		local restricted: { number } = {}
		for index, entry in self.entries do
			restricted[index] = if isTarget[entry.id] then probabilities[index] else 0
		end
		-- Si el jugador ya tiene excluidos todos los objetivos, no hay nada que garantizar.
		local anyTarget = false
		for _, p in restricted do
			if p > 0 then
				anyTarget = true
				break
			end
		end
		if anyTarget then
			-- renormaliza
			local sum = 0
			for _, p in restricted do
				sum += p
			end
			for index, p in restricted do
				restricted[index] = p / sum
			end
			local id = self.entries[pickIndex(restricted, rng)].id
			return id, 0
		end
	end
	local id = self.entries[pickIndex(probabilities, rng)].id
	if isTarget[id] then
		return id, 0
	end
	return id, counter + 1
end

----------------------------------------------------------------------------
-- Datos para la UI de probabilidades
----------------------------------------------------------------------------

function OddsTable.displayRows(self: OddsTable, options: DisplayOptions?): DisplayView
	local opts: DisplayOptions = options or {}
	local luck = sanitizeLuck(opts.luck, self.maxLuck)
	local probabilities = computeProbabilities(self.entries, luck, opts.exclude)
	local baseProbabilities = computeProbabilities(self.entries, 0, opts.exclude)
	local units = Odds.allocateUnits(probabilities, self.decimals)
	local baseUnits = Odds.allocateUnits(baseProbabilities, self.decimals)

	local rows: { DisplayRow } = {}
	local order: { number } = {}
	for index = 1, #self.entries do
		if probabilities[index] > 0 then
			table.insert(order, index)
		end
	end
	if opts.sort ~= "entry" then
		table.sort(order, function(a: number, b: number): boolean
			if probabilities[a] ~= probabilities[b] then
				return probabilities[a] > probabilities[b]
			end
			return a < b
		end)
	end
	local scale = 10 ^ self.decimals
	for _, index in order do
		local entry = self.entries[index]
		table.insert(rows, {
			id = entry.id,
			label = entry.label or entry.id,
			rarity = entry.rarity,
			probability = probabilities[index],
			percent = units[index] / scale,
			percentText = formatUnits(units[index], self.decimals),
			basePercentText = formatUnits(baseUnits[index], self.decimals),
		})
	end
	local totalUnits = math.floor(100 * scale + 0.5)
	return {
		rows = rows,
		totalPercentText = formatUnits(totalUnits, self.decimals),
		baseTotalPercentText = formatUnits(totalUnits, self.decimals),
		luck = luck,
		luckActive = luck > 0,
		pityNote = if self.pity then self.pity.note else nil,
		decimals = self.decimals,
	}
end

----------------------------------------------------------------------------
-- Gating por PolicyService (ver research/03 2.1)
----------------------------------------------------------------------------

export type PolicyInfo = { [string]: any }

--[[
	true solo si PolicyService confirma que el jugador PUEDE interactuar con objetos aleatorios de pago.
	Propiedad oficial: ArePaidRandomItemsRestricted (true = restringido). Sin datos => restringido
	(conservador). // VERIFIED: creator-docs PolicyService.yaml + paid-random-items.md (2026-10-20)
]]
function Odds.paidRandomAllowed(policy: PolicyInfo?): boolean
	if policy == nil then
		return false
	end
	return policy.ArePaidRandomItemsRestricted == false
end

-- IsPaidItemTradingAllowed es una comprobacion SEPARADA de la de adquisicion.
function Odds.paidItemTradingAllowed(policy: PolicyInfo?): boolean
	if policy == nil then
		return false
	end
	return policy.IsPaidItemTradingAllowed == true
end

return Odds
