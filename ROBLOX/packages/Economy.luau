--!strict
--[[
	Economy: moneda blanda/dura, multiplicadores combinables con tope, boosts temporales y
	ganancias offline con tope. TODO se ejecuta en el servidor (server-authoritative): el cliente
	solo recibe numeros para mostrar; nunca propone cantidades.

	Reglas:
	  * Saldos = enteros >= 0 y <= tope por moneda (por defecto 1e12; el doble de Roblox es exacto
	    hasta 2^53 ~ 9e15). Cantidades NaN/inf/negativas/fraccionarias se rechazan.
	  * gastar() es atomico: o se gasta todo o no se toca nada.
	  * Multiplicadores: combinacion ADITIVA por defecto (2x + 2x = 3x, no 4x) y SIEMPRE con tope.
	    Esto evita que pases + eventos + boosts se disparen de forma impredecible.
	  * Offline: tope de horas acumulables (el regreso diario compensa) y proteccion contra relojes
	    adelantados/atrasados.
	  * Cada movimiento puede notificarse (onTransaction) para Analytics: LogEconomyEvent.

	// REVIEW(money): cualquier cambio en topes, redondeo o reglas de stacking afecta a la economia
	// y a lo que el jugador paga; revisar con una persona antes de publicar.
]]

export type Wallet = { [string]: number }

export type CurrencyDef = {
	kind: string, -- "soft" | "hard" (informativo)
	maxBalance: number?,
}

export type TransactionInfo = {
	player: any?,
	reason: string?, -- transactionType para Analytics (p. ej. "Gameplay", "Shop", "IAP")
	sku: string?,
}

export type Transaction = {
	flow: string, -- "Source" | "Sink"
	currency: string,
	amount: number,
	endingBalance: number,
	reason: string,
	sku: string?,
	player: any?,
}

export type LedgerConfig = {
	currencies: { [string]: CurrencyDef },
	onTransaction: ((transaction: Transaction) -> ())?,
}

export type MultiplierSource = {
	id: string,
	kind: string, -- "coins" | "luck" | ... (lo define el juego)
	value: number, -- multiplicador (2 = x2) o, en sumBonuses, puntos aditivos
	active: boolean,
}

export type BoostState = { [string]: number } -- id -> expiresAt (epoch en segundos)

export type OfflineParams = {
	lastSeen: number, -- epoch (s)
	now: number, -- epoch (s)
	ratePerHour: number,
	capSeconds: number,
	multiplier: number?,
	minSeconds: number?, -- por debajo de esto no se otorga nada (evita pop-ups triviales)
}

export type OfflineResult = { amount: number, seconds: number, capped: boolean }

local Economy = {}

local DEFAULT_MAX_BALANCE = 1e12

----------------------------------------------------------------------------
-- Validacion
----------------------------------------------------------------------------

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- Cantidad valida para sumar/restar: entero finito >= 0.
function Economy.isValidAmount(amount: any): boolean
	return isFinite(amount) and (amount :: number) >= 0 and (amount :: number) % 1 == 0
end

-- Redondeo estandar de pagos: al entero mas cercano, nunca negativo.
function Economy.round(value: number): number
	if not isFinite(value) or value <= 0 then
		return 0
	end
	return math.floor(value + 0.5)
end

----------------------------------------------------------------------------
-- Ledger (saldos)
----------------------------------------------------------------------------

local Ledger = {}
Ledger.__index = Ledger

type LedgerData = { config: LedgerConfig }
export type Ledger = typeof(setmetatable({} :: LedgerData, Ledger))

function Economy.newLedger(config: LedgerConfig): Ledger
	assert(type(config.currencies) == "table", "Economy.newLedger requiere currencies")
	return setmetatable({ config = config }, Ledger)
end

function Ledger._cap(self: Ledger, currency: string): number
	local def = self.config.currencies[currency]
	assert(def ~= nil, "moneda desconocida: " .. tostring(currency))
	return def.maxBalance or DEFAULT_MAX_BALANCE
end

function Ledger._notify(self: Ledger, flow: string, currency: string, amount: number, ending: number, info: TransactionInfo?)
	local hook = self.config.onTransaction
	if hook == nil or amount <= 0 then
		return
	end
	local ok, err = pcall(hook, {
		flow = flow,
		currency = currency,
		amount = amount,
		endingBalance = ending,
		reason = if info and info.reason then info.reason else "Gameplay",
		sku = if info then info.sku else nil,
		player = if info then info.player else nil,
	})
	if not ok then
		warn("[Economy] onTransaction fallo: " .. tostring(err))
	end
end

function Ledger.balance(self: Ledger, wallet: Wallet, currency: string): number
	local value = wallet[currency]
	if type(value) ~= "number" or not isFinite(value) or value < 0 then
		return 0
	end
	return value
end

function Ledger.canAfford(self: Ledger, wallet: Wallet, currency: string, amount: number): boolean
	return Economy.isValidAmount(amount) and self:balance(wallet, currency) >= amount
end

--[[
	Suma `amount` (entero >= 0). Respeta el tope. Devuelve (sumado, saldoNuevo).
	Una cantidad invalida NO modifica nada y devuelve (0, saldoActual).
]]
function Ledger.add(self: Ledger, wallet: Wallet, currency: string, amount: number, info: TransactionInfo?): (number, number)
	local current = self:balance(wallet, currency)
	if not Economy.isValidAmount(amount) or amount == 0 then
		return 0, current
	end
	local cap = self:_cap(currency)
	local newBalance = math.min(cap, current + amount)
	local added = newBalance - current
	wallet[currency] = newBalance
	self:_notify("Source", currency, added, newBalance, info)
	return added, newBalance
end

-- Gasta `amount` de forma atomica. true si se pudo; false (sin cambios) si no alcanza o es invalido.
function Ledger.spend(self: Ledger, wallet: Wallet, currency: string, amount: number, info: TransactionInfo?): boolean
	if not Economy.isValidAmount(amount) then
		return false
	end
	local current = self:balance(wallet, currency)
	if current < amount then
		return false
	end
	local newBalance = current - amount
	wallet[currency] = newBalance
	self:_notify("Sink", currency, amount, newBalance, info)
	return true
end

----------------------------------------------------------------------------
-- Multiplicadores combinables con tope
----------------------------------------------------------------------------

--[[
	Combina multiplicadores ACTIVOS de un tipo.
	  mode "additive" (por defecto): 1 + sum(m - 1)      -> 2x y 2x dan 3x
	  mode "multiplicative":         producto de todos     -> 2x y 2x dan 4x
	El resultado se limita a [1, cap]. Valores no finitos o <= 0 se ignoran.
]]
function Economy.combineMultipliers(sources: { MultiplierSource }, kind: string, cap: number, mode: string?): number
	local total = 1
	local multiplicative = mode == "multiplicative"
	for _, source in sources do
		if source.active and source.kind == kind and isFinite(source.value) and source.value > 0 then
			if multiplicative then
				total *= source.value
			else
				total += source.value - 1
			end
		end
	end
	return math.clamp(total, 1, math.max(cap, 1))
end

-- Suma de bonus aditivos (p. ej. puntos de suerte). Limitada a [0, cap].
function Economy.sumBonuses(sources: { MultiplierSource }, kind: string, cap: number): number
	local total = 0
	for _, source in sources do
		if source.active and source.kind == kind and isFinite(source.value) and source.value > 0 then
			total += source.value
		end
	end
	return math.clamp(total, 0, math.max(cap, 0))
end

----------------------------------------------------------------------------
-- Boosts temporales (se guardan como expiracion en epoch, sobreviven a reconexiones)
----------------------------------------------------------------------------

function Economy.isBoostActive(boosts: BoostState, id: string, now: number): boolean
	local expiresAt = boosts[id]
	return type(expiresAt) == "number" and expiresAt > now
end

function Economy.boostRemaining(boosts: BoostState, id: string, now: number): number
	local expiresAt = boosts[id]
	if type(expiresAt) ~= "number" or expiresAt <= now then
		return 0
	end
	return expiresAt - now
end

--[[
	Concede (o prolonga) un boost. Si ya esta activo se suma la duracion, pero el tiempo restante
	total nunca supera `maxRemainingSeconds` (evita acumular boosts de dias). Devuelve el nuevo
	vencimiento. Devuelve nil (sin cambios) si los parametros son invalidos.
]]
function Economy.grantBoost(boosts: BoostState, id: string, durationSeconds: number, now: number, maxRemainingSeconds: number): number?
	if not isFinite(durationSeconds) or durationSeconds <= 0 or not isFinite(now) or not isFinite(maxRemainingSeconds) then
		return nil
	end
	local remaining = Economy.boostRemaining(boosts, id, now)
	local newRemaining = math.min(remaining + durationSeconds, math.max(maxRemainingSeconds, durationSeconds))
	local expiresAt = now + newRemaining
	boosts[id] = expiresAt
	return expiresAt
end

-- Elimina boosts vencidos (mantiene el perfil pequeño).
function Economy.pruneBoosts(boosts: BoostState, now: number): number
	local removed = 0
	for id, expiresAt in boosts do
		if type(expiresAt) ~= "number" or expiresAt <= now then
			boosts[id] = nil
			removed += 1
		end
	end
	return removed
end

----------------------------------------------------------------------------
-- Ganancias offline con tope
----------------------------------------------------------------------------

function Economy.offlineEarnings(params: OfflineParams): OfflineResult
	local none: OfflineResult = { amount = 0, seconds = 0, capped = false }
	if
		not isFinite(params.lastSeen)
		or not isFinite(params.now)
		or not isFinite(params.ratePerHour)
		or not isFinite(params.capSeconds)
	then
		return none
	end
	local elapsed = params.now - params.lastSeen
	-- Reloj atrasado/adelantado o primera sesion (lastSeen = 0): no se otorga nada.
	if elapsed <= 0 or params.lastSeen <= 0 or params.ratePerHour <= 0 or params.capSeconds <= 0 then
		return none
	end
	local seconds = math.min(elapsed, params.capSeconds)
	if seconds < (params.minSeconds or 0) then
		return none
	end
	local multiplier = params.multiplier or 1
	if not isFinite(multiplier) or multiplier < 0 then
		multiplier = 1
	end
	local amount = Economy.round(params.ratePerHour / 3600 * seconds * multiplier)
	return { amount = amount, seconds = seconds, capped = elapsed > params.capSeconds }
end

return Economy
