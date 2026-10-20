--!strict
--[[
	Analytics: envoltorio de AnalyticsService (economia, embudo FTUE, eventos personalizados).

	  * Si no hay servicio (tests, Studio sin publicar) todo es no-op.
	  * Nunca lanza: la analitica no puede romper el juego (pcall en cada llamada).
	  * Valida cantidades (amount > 0 finito, endingBalance >= 0 finito, pasos 1..100) y respeta los
	    limites documentados por experiencia: 5 monedas, 20 tipos de transaccion, 100 SKUs, 10 embudos
	    y 100 eventos personalizados. Lo que exceda se descarta con un aviso (para no ensuciar los paneles).
	  * Solo se envian desde el SERVIDOR y en juegos publicados.

	// VERIFIED (creator-docs AnalyticsService.yaml, 2026-10-20):
	//   LogEconomyEvent(player, flowType: Enum.AnalyticsEconomyFlowType, currencyType: string, amount: number,
	//                   endingBalance: number, transactionType: string, itemSku: string?, customFields: {}?)
	//   LogFunnelStepEvent(player, funnelName, funnelSessionId?, step = 1, stepName?, customFields?)
	//   LogOnboardingFunnelStepEvent(player, step, stepName?, customFields?)
	//   LogCustomEvent(player, eventName, value = 1, customFields?)
	//   Enum.AnalyticsEconomyFlowType = { Sink, Source }
]]

export type Config = {
	service: any?, -- AnalyticsService (o doble)
	enums: any?, -- tabla Enum (o doble) con AnalyticsEconomyFlowType; por defecto el global Enum
	log: ((message: string) -> ...any)?,
}

local Analytics = {}
Analytics.__index = Analytics

type AnalyticsData = {
	service: any?,
	enums: any?,
	log: ((message: string) -> ...any)?,
	currencies: { [string]: boolean },
	transactionTypes: { [string]: boolean },
	skus: { [string]: boolean },
	funnels: { [string]: boolean },
	customEvents: { [string]: boolean },
	seenSteps: { [number]: { [string]: boolean } }, -- userId -> "embudo:paso" ya enviado
	warned: { [string]: boolean },
}
export type Analytics = typeof(setmetatable({} :: AnalyticsData, Analytics))

local LIMITS = {
	currencies = 5,
	transactionTypes = 20,
	skus = 100,
	funnels = 10,
	customEvents = 100,
}

Analytics.LIMITS = LIMITS

function Analytics.new(config: Config?): Analytics
	local cfg: Config = config or {}
	local data: AnalyticsData = {
		service = cfg.service,
		enums = cfg.enums,
		log = cfg.log,
		currencies = {},
		transactionTypes = {},
		skus = {},
		funnels = {},
		customEvents = {},
		seenSteps = {},
		warned = {},
	}
	return setmetatable(data, Analytics)
end

-- Instancia sin servicio: todas las llamadas son no-op.
function Analytics.noop(): Analytics
	return Analytics.new({})
end

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function Analytics._warnOnce(self: Analytics, key: string, message: string)
	if self.warned[key] then
		return
	end
	self.warned[key] = true
	local log = self.log
	if log then
		log(message)
	else
		warn("[Analytics] " .. message)
	end
end

-- Registra `value` en el conjunto con tope; devuelve false si el tope ya esta lleno y es nuevo.
function Analytics._track(
	self: Analytics,
	set: { [string]: boolean },
	limit: number,
	value: string,
	label: string
): boolean
	if set[value] then
		return true
	end
	local count = 0
	for _ in set do
		count += 1
	end
	if count >= limit then
		self:_warnOnce(
			label .. ":" .. value,
			"limite de " .. label .. " (" .. limit .. ") alcanzado; se descarta '" .. value .. "'"
		)
		return false
	end
	set[value] = true
	return true
end

local function validName(value: any): boolean
	return type(value) == "string" and value ~= "" and #value <= 100
end

function Analytics._call(self: Analytics, method: string, ...: any)
	local service = self.service
	if service == nil then
		return
	end
	local args = { ... }
	local count = select("#", ...)
	local ok, err = pcall(function()
		service[method](service, table.unpack(args, 1, count))
	end)
	if not ok then
		self:_warnOnce("call:" .. method, method .. " fallo: " .. tostring(err))
	end
end

--[[
	Evento de economia. flow = "Source" (entra moneda) | "Sink" (sale moneda).
	transactionType: "Gameplay" | "Shop" | "IAP" | "TimedReward" | "Onboarding" | "ContextualPurchase" o uno propio.
]]
function Analytics.economy(
	self: Analytics,
	player: any,
	flow: string,
	currency: string,
	amount: number,
	endingBalance: number,
	transactionType: string,
	sku: string?
)
	if self.service == nil then
		return
	end
	if flow ~= "Source" and flow ~= "Sink" then
		self:_warnOnce("flow:" .. tostring(flow), "flow invalido: " .. tostring(flow))
		return
	end
	if not isFinite(amount) or amount <= 0 or not isFinite(endingBalance) or endingBalance < 0 then
		self:_warnOnce("econ-amount", "economy: amount debe ser > 0 y endingBalance >= 0 (ambos finitos)")
		return
	end
	if not validName(currency) or not validName(transactionType) then
		return
	end
	if not self:_track(self.currencies, LIMITS.currencies, currency, "monedas") then
		return
	end
	if not self:_track(self.transactionTypes, LIMITS.transactionTypes, transactionType, "tipos de transaccion") then
		return
	end
	local itemSku = sku
	if itemSku ~= nil and not self:_track(self.skus, LIMITS.skus, itemSku, "SKUs") then
		itemSku = nil -- se registra el evento igualmente, sin SKU
	end
	local enums: any = self.enums
	if enums == nil and typeof(Enum) == "Enum" then
		enums = Enum
	end
	if enums == nil or enums.AnalyticsEconomyFlowType == nil then
		self:_warnOnce("enum", "no hay Enum.AnalyticsEconomyFlowType disponible")
		return
	end
	self:_call(
		"LogEconomyEvent",
		player,
		enums.AnalyticsEconomyFlowType[flow],
		currency,
		amount,
		endingBalance,
		transactionType,
		itemSku
	)
end

--[[
	Paso de embudo de onboarding (FTUE), una vez por jugador y paso en esta sesion.
	step: 1..100 (los pasos saltados cuentan como completados).
]]
function Analytics.ftue(self: Analytics, player: any, step: number, stepName: string?)
	if self.service == nil then
		return
	end
	if not isFinite(step) or step < 1 or step > 100 or step % 1 ~= 0 then
		return
	end
	local userId = if type(player) == "table" or typeof(player) == "Instance" then player.UserId else 0
	local seen = self.seenSteps[userId]
	if seen == nil then
		seen = {}
		self.seenSteps[userId] = seen
	end
	local key = "ftue:" .. tostring(step)
	if seen[key] then
		return
	end
	seen[key] = true
	self:_call("LogOnboardingFunnelStepEvent", player, step, stepName)
end

-- Paso de un embudo recurrente (p. ej. embudo de tienda). `sessionId` agrupa los pasos de una misma pasada.
function Analytics.funnel(
	self: Analytics,
	player: any,
	funnelName: string,
	step: number,
	stepName: string?,
	sessionId: string?
)
	if self.service == nil then
		return
	end
	if not validName(funnelName) or not isFinite(step) or step < 1 or step > 100 or step % 1 ~= 0 then
		return
	end
	if not self:_track(self.funnels, LIMITS.funnels, funnelName, "embudos") then
		return
	end
	self:_call("LogFunnelStepEvent", player, funnelName, sessionId, step, stepName)
end

function Analytics.custom(self: Analytics, player: any, eventName: string, value: number?, fields: { [string]: any }?)
	if self.service == nil then
		return
	end
	if not validName(eventName) then
		return
	end
	local amount = value or 1
	if not isFinite(amount) then
		return
	end
	if not self:_track(self.customEvents, LIMITS.customEvents, eventName, "eventos personalizados") then
		return
	end
	self:_call("LogCustomEvent", player, eventName, amount, fields)
end

-- Libera la memoria de un jugador (PlayerRemoving).
function Analytics.forget(self: Analytics, player: any)
	local userId = if type(player) == "table" or typeof(player) == "Instance" then player.UserId else 0
	self.seenSteps[userId] = nil
end

return Analytics
