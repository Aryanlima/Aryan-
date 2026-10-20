--!strict
--[[
	LiveOps: programador de eventos (inicio/fin y rotacion), codigos de canje con caducidad y un solo
	uso por jugador, mensaje de bienvenida y temporada. TODO se configura SIN republicar el juego:
	la configuracion vive en una fuente remota (ConfigService / DataStore, inyectada con `fetch`) y los
	servidores la refrescan cada pocos minutos y/o al recibir un aviso de MessagingService.

	Principios de honestidad (research/03 2.3):
	  * Los temporizadores son exactos (endsAt - now) y NO se reinician solos: un evento solo se repite si
	    su configuracion define explicitamente un ciclo (`cycle`).
	  * Maximo 10 eventos activos/proximos a la vez (limite documentado en research/07 [F28]).
	  * Una configuracion invalida NUNCA reemplaza a la buena: se registra el problema y se sigue con la anterior.

	Sin dependencias del motor: se prueba con Lune.
]]

export type CycleDef = {
	anchor: number, -- epoch (s) del inicio del primer slot
	slotSeconds: number, -- duracion de cada slot
	slotCount: number, -- numero de eventos que rotan
	slot: number, -- 0..slotCount-1: el slot en el que este evento esta activo
}

export type EventDef = {
	id: string,
	name: string,
	description: string?,
	startsAt: number?, -- epoch (s). Ventana fija...
	endsAt: number?,
	cycle: CycleDef?, -- ...o rotacion periodica
	modifiers: { [string]: number }?, -- p. ej. { coins = 2 }: los interpreta el juego
}

export type CodeDef = {
	reward: { [string]: any },
	startsAt: number?,
	expiresAt: number?,
}

export type WelcomeDef = {
	id: string, -- cambia el id para volver a mostrarlo a todos
	message: string,
	startsAt: number?,
	endsAt: number?,
}

export type SeasonDef = {
	id: number,
	name: string,
	startsAt: number,
	endsAt: number,
}

export type LiveConfig = {
	version: number,
	events: { EventDef },
	codes: { [string]: CodeDef },
	welcome: WelcomeDef?,
	season: SeasonDef?,
}

export type ActiveEvent = {
	id: string,
	name: string,
	description: string?,
	startsAt: number,
	endsAt: number,
	secondsLeft: number,
	modifiers: { [string]: number },
}

export type RedeemResult = {
	ok: boolean,
	reason: string?, -- "invalid" | "unknown" | "notStarted" | "expired" | "already"
	reward: { [string]: any }?,
	code: string?,
}

export type Config = {
	defaults: LiveConfig,
	fetch: (() -> any)?, -- devuelve la tabla de configuracion remota (puede lanzar error)
	now: (() -> number)?,
	task: any?,
	log: ((message: string) -> ())?,
	pollSeconds: number?, -- por defecto 120
	maxActiveOrUpcoming: number?, -- por defecto 10
	random: (() -> number)?,
}

local LiveOps = {}

local MAX_CODE_LENGTH = 32

----------------------------------------------------------------------------
-- Funciones puras
----------------------------------------------------------------------------

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value do
		copy[k] = deepCopy(v)
	end
	return copy
end

--[[
	Ventana de un evento en el instante `now`.
	Devuelve (activo, inicio, fin). Para eventos ciclicos, inicio/fin son los del slot ACTUAL si esta
	activo o los del PROXIMO slot de ese evento si no lo esta.
]]
function LiveOps.eventWindow(event: EventDef, now: number): (boolean, number, number)
	local cycle = event.cycle
	if cycle then
		local sinceAnchor = now - cycle.anchor
		if sinceAnchor < 0 then
			local startsAt = cycle.anchor + cycle.slot * cycle.slotSeconds
			return false, startsAt, startsAt + cycle.slotSeconds
		end
		local slotIndex = math.floor(sinceAnchor / cycle.slotSeconds)
		if slotIndex % cycle.slotCount == cycle.slot then
			local startsAt = cycle.anchor + slotIndex * cycle.slotSeconds
			return true, startsAt, startsAt + cycle.slotSeconds
		end
		-- proximo slot de este evento
		local ahead = (cycle.slot - slotIndex) % cycle.slotCount
		local nextIndex = slotIndex + ahead
		local startsAt = cycle.anchor + nextIndex * cycle.slotSeconds
		return false, startsAt, startsAt + cycle.slotSeconds
	end
	local startsAt = event.startsAt or 0
	local endsAt = event.endsAt or math.huge
	return now >= startsAt and now < endsAt, startsAt, endsAt
end

-- Normaliza un codigo escrito por el jugador: recorta, mayusculas, solo A-Z 0-9 y guion. nil si no es valido.
function LiveOps.normalizeCode(raw: any): string?
	if type(raw) ~= "string" then
		return nil
	end
	local trimmed = string.match(raw, "^%s*(.-)%s*$") or ""
	if trimmed == "" or #trimmed > MAX_CODE_LENGTH then
		return nil
	end
	local upper = string.upper(trimmed)
	if string.find(upper, "[^A-Z0-9%-]") then
		return nil
	end
	return upper
end

--[[
	Valida una configuracion. Devuelve (true) o (false, { problemas }).
]]
function LiveOps.validateConfig(config: any, now: number?, maxActiveOrUpcoming: number?): (boolean, { string })
	local problems: { string } = {}
	local function problem(message: string)
		table.insert(problems, message)
	end
	if type(config) ~= "table" then
		return false, { "la configuracion no es una tabla" }
	end
	if type(config.version) ~= "number" then
		problem("falta version")
	end
	local events = config.events
	if type(events) ~= "table" then
		problem("falta events")
		events = {}
	end
	local seen: { [string]: boolean } = {}
	for index, event in events do
		local label = "evento #" .. tostring(index)
		if type(event) ~= "table" or type(event.id) ~= "string" or event.id == "" then
			problem(label .. ": sin id")
		else
			label = "evento '" .. event.id .. "'"
			if seen[event.id] then
				problem(label .. ": id duplicado")
			end
			seen[event.id] = true
			if type(event.name) ~= "string" or event.name == "" then
				problem(label .. ": sin nombre")
			end
			local cycle = event.cycle
			if cycle ~= nil then
				if
					not isFinite(cycle.anchor)
					or not isFinite(cycle.slotSeconds)
					or cycle.slotSeconds < 60
					or not isFinite(cycle.slotCount)
					or cycle.slotCount < 1
					or cycle.slotCount % 1 ~= 0
					or not isFinite(cycle.slot)
					or cycle.slot < 0
					or cycle.slot >= cycle.slotCount
					or cycle.slot % 1 ~= 0
				then
					problem(label .. ": ciclo invalido")
				end
			else
				if not isFinite(event.startsAt) or not isFinite(event.endsAt) then
					problem(label .. ": necesita startsAt y endsAt (o un ciclo)")
				elseif event.endsAt <= event.startsAt then
					problem(label .. ": endsAt debe ser posterior a startsAt")
				end
			end
			if event.modifiers ~= nil then
				if type(event.modifiers) ~= "table" then
					problem(label .. ": modifiers invalido")
				else
					for kind, value in event.modifiers do
						if type(kind) ~= "string" or not isFinite(value) or value <= 0 then
							problem(label .. ": modificador invalido '" .. tostring(kind) .. "'")
						end
					end
				end
			end
		end
	end

	if type(config.codes) ~= "table" then
		problem("falta codes")
	else
		for code, def in config.codes do
			if type(code) ~= "string" or LiveOps.normalizeCode(code) ~= code then
				problem("codigo '" .. tostring(code) .. "': debe estar en MAYUSCULAS (A-Z, 0-9, guion) y <= " .. MAX_CODE_LENGTH)
			elseif type(def) ~= "table" or type(def.reward) ~= "table" or next(def.reward) == nil then
				problem("codigo '" .. code .. "': sin reward")
			else
				if def.startsAt ~= nil and not isFinite(def.startsAt) then
					problem("codigo '" .. code .. "': startsAt invalido")
				end
				if def.expiresAt ~= nil then
					if not isFinite(def.expiresAt) then
						problem("codigo '" .. code .. "': expiresAt invalido")
					elseif def.startsAt ~= nil and def.expiresAt <= def.startsAt then
						problem("codigo '" .. code .. "': expiresAt debe ser posterior a startsAt")
					end
				end
			end
		end
	end

	local welcome = config.welcome
	if welcome ~= nil then
		if type(welcome) ~= "table" or type(welcome.id) ~= "string" or type(welcome.message) ~= "string" then
			problem("welcome invalido (id y message)")
		elseif #welcome.message > 300 then
			problem("welcome: mensaje demasiado largo")
		end
	end
	local season = config.season
	if season ~= nil then
		if
			type(season) ~= "table"
			or not isFinite(season.id)
			or not isFinite(season.startsAt)
			or not isFinite(season.endsAt)
			or season.endsAt <= season.startsAt
		then
			problem("season invalida")
		end
	end

	-- Limite de eventos activos o proximos.
	if now ~= nil and #problems == 0 then
		local count = 0
		for _, event in events do
			local active, _, endsAt = LiveOps.eventWindow(event, now)
			if active or endsAt > now then
				count += 1
			end
		end
		local limit = maxActiveOrUpcoming or 10
		if count > limit then
			problem("hay " .. count .. " eventos activos/proximos; el maximo es " .. limit)
		end
	end

	table.sort(problems)
	return #problems == 0, problems
end

----------------------------------------------------------------------------
-- Instancia
----------------------------------------------------------------------------

local Impl = {}
Impl.__index = Impl

type ImplData = {
	cfg: Config,
	config: LiveConfig,
	nowFn: () -> number,
	taskLib: any,
	randomFn: () -> number,
	polling: boolean,
	lastRefreshOk: boolean,
	lastRefreshAt: number,
	version: number,
}
export type LiveOpsInstance = typeof(setmetatable({} :: ImplData, Impl))

function LiveOps.new(config: Config): LiveOpsInstance
	local nowFn: () -> number = config.now
		or function(): number
			return os.time()
		end
	local ok, problems = LiveOps.validateConfig(config.defaults, nil, config.maxActiveOrUpcoming)
	assert(ok, "LiveOps: la configuracion por defecto es invalida: " .. table.concat(problems, "; "))
	local data: ImplData = {
		cfg = config,
		config = deepCopy(config.defaults),
		nowFn = nowFn,
		taskLib = config.task or task,
		randomFn = config.random or function(): number
			return math.random()
		end,
		polling = false,
		lastRefreshOk = false,
		lastRefreshAt = 0,
		version = config.defaults.version,
	}
	return setmetatable(data, Impl)
end

function Impl._log(self: LiveOpsInstance, message: string)
	local log = self.cfg.log
	if log then
		log(message)
	else
		warn("[LiveOps] " .. message)
	end
end

function Impl.getConfig(self: LiveOpsInstance): LiveConfig
	return self.config
end

--[[
	Descarga y aplica la configuracion remota. Devuelve true si se aplico una configuracion NUEVA y valida.
	Un fallo de red o una configuracion invalida conservan la anterior.
]]
function Impl.refresh(self: LiveOpsInstance): boolean
	local fetch = self.cfg.fetch
	if fetch == nil then
		return false
	end
	local ok, candidate = pcall(fetch)
	if not ok then
		self.lastRefreshOk = false
		self:_log("no se pudo descargar la configuracion (se conserva la anterior): " .. tostring(candidate))
		return false
	end
	if candidate == nil then
		return false -- no hay configuracion remota publicada: se usan los valores por defecto
	end
	local now = self.nowFn()
	local valid, problems = LiveOps.validateConfig(candidate, now, self.cfg.maxActiveOrUpcoming)
	if not valid then
		self.lastRefreshOk = false
		self:_log("configuracion remota INVALIDA (se conserva la anterior): " .. table.concat(problems, "; "))
		return false
	end
	self.lastRefreshOk = true
	self.lastRefreshAt = now
	if candidate.version == self.version then
		return false -- misma version: nada que aplicar
	end
	self.config = deepCopy(candidate)
	self.version = candidate.version
	return true
end

-- Refresco periodico (con jitter). Llamar una vez en el arranque del servidor.
function Impl.startPolling(self: LiveOpsInstance)
	if self.polling then
		return
	end
	self.polling = true
	local interval = self.cfg.pollSeconds or 120
	self.taskLib.spawn(function()
		self:refresh()
		while self.polling do
			self.taskLib.wait(interval * (0.9 + self.randomFn() * 0.2))
			if not self.polling then
				break
			end
			self:refresh()
		end
	end)
end

function Impl.stopPolling(self: LiveOpsInstance)
	self.polling = false
end

--[[
	Suscribe al aviso de cambios por MessagingService (mejor esfuerzo; el sondeo es la red de seguridad).
	// VERIFIED: MessagingService:SubscribeAsync(topic, callback) yield, devuelve RBXScriptConnection.
]]
function Impl.subscribe(self: LiveOpsInstance, messaging: any, topic: string): boolean
	local ok, err = pcall(function()
		messaging:SubscribeAsync(topic, function()
			self.taskLib.spawn(function()
				-- pequeno retraso aleatorio para no saturar el origen si hay muchos servidores
				self.taskLib.wait(self.randomFn() * 5)
				self:refresh()
			end)
		end)
	end)
	if not ok then
		self:_log("no se pudo suscribir a " .. topic .. ": " .. tostring(err))
	end
	return ok
end

----------------------------------------------------------------------------
-- Consultas
----------------------------------------------------------------------------

function Impl.getActiveEvents(self: LiveOpsInstance, now: number?): { ActiveEvent }
	local at = now or self.nowFn()
	local list: { ActiveEvent } = {}
	for _, event in self.config.events do
		local active, startsAt, endsAt = LiveOps.eventWindow(event, at)
		if active then
			table.insert(list, {
				id = event.id,
				name = event.name,
				description = event.description,
				startsAt = startsAt,
				endsAt = endsAt,
				secondsLeft = math.max(0, endsAt - at),
				modifiers = deepCopy(event.modifiers or {}),
			})
		end
	end
	table.sort(list, function(a: ActiveEvent, b: ActiveEvent): boolean
		if a.startsAt ~= b.startsAt then
			return a.startsAt < b.startsAt
		end
		return a.id < b.id
	end)
	return list
end

-- Proximos eventos (que aun no empezaron) dentro de `horizonSeconds`.
function Impl.getUpcomingEvents(self: LiveOpsInstance, horizonSeconds: number, now: number?): { ActiveEvent }
	local at = now or self.nowFn()
	local list: { ActiveEvent } = {}
	for _, event in self.config.events do
		local active, startsAt, endsAt = LiveOps.eventWindow(event, at)
		if not active and startsAt > at and startsAt - at <= horizonSeconds then
			table.insert(list, {
				id = event.id,
				name = event.name,
				description = event.description,
				startsAt = startsAt,
				endsAt = endsAt,
				secondsLeft = startsAt - at, -- tiempo hasta que empiece
				modifiers = deepCopy(event.modifiers or {}),
			})
		end
	end
	table.sort(list, function(a: ActiveEvent, b: ActiveEvent): boolean
		if a.startsAt ~= b.startsAt then
			return a.startsAt < b.startsAt
		end
		return a.id < b.id
	end)
	return list
end

-- Fuentes de multiplicador de los eventos activos, en el formato de Economy.combineMultipliers.
function Impl.getModifierSources(self: LiveOpsInstance, now: number?): { { id: string, kind: string, value: number, active: boolean } }
	local sources = {}
	for _, event in self:getActiveEvents(now) do
		for kind, value in event.modifiers do
			table.insert(sources, { id = "event:" .. event.id, kind = kind, value = value, active = true })
		end
	end
	table.sort(sources, function(a: any, b: any): boolean
		if a.id ~= b.id then
			return a.id < b.id
		end
		return a.kind < b.kind
	end)
	return sources
end

function Impl.getSeason(self: LiveOpsInstance, now: number?): SeasonDef?
	local at = now or self.nowFn()
	local season = self.config.season
	if season and at >= season.startsAt and at < season.endsAt then
		return season
	end
	return nil
end

--[[
	Mensaje de bienvenida pendiente para este jugador (o nil). `seenId` es el ultimo id que vio.
	El juego guarda welcome.id en el perfil tras mostrarlo.
]]
function Impl.getWelcome(self: LiveOpsInstance, seenId: string?, now: number?): WelcomeDef?
	local at = now or self.nowFn()
	local welcome = self.config.welcome
	if welcome == nil or welcome.id == seenId then
		return nil
	end
	if welcome.startsAt ~= nil and at < welcome.startsAt then
		return nil
	end
	if welcome.endsAt ~= nil and at >= welcome.endsAt then
		return nil
	end
	return welcome
end

--[[
	Canjea un codigo. `redeemed` es la tabla del perfil (codigo -> epoch). Si tiene exito la MARCA en el
	mismo paso (un solo uso por jugador) y devuelve una COPIA de la recompensa; el llamador la concede y
	guarda el perfil. Los codigos son por jugador: un limite global necesitaria un almacen compartido.
]]
function Impl.redeemCode(self: LiveOpsInstance, redeemed: { [string]: number }, rawCode: any, now: number?): RedeemResult
	local code = LiveOps.normalizeCode(rawCode)
	if code == nil then
		return { ok = false, reason = "invalid" }
	end
	local def = self.config.codes[code]
	if def == nil then
		return { ok = false, reason = "unknown", code = code }
	end
	local at = now or self.nowFn()
	if def.startsAt ~= nil and at < def.startsAt then
		return { ok = false, reason = "notStarted", code = code }
	end
	if def.expiresAt ~= nil and at >= def.expiresAt then
		return { ok = false, reason = "expired", code = code }
	end
	if redeemed[code] ~= nil then
		return { ok = false, reason = "already", code = code }
	end
	redeemed[code] = at
	return { ok = true, reward = deepCopy(def.reward), code = code }
end

return LiveOps
