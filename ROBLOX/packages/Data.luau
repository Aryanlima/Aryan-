--!strict
--[[
	Data: persistencia por jugador con DataStore `UpdateAsync`, bloqueo de sesion, reintentos con
	backoff, migraciones de esquema versionadas y guardado en PlayerRemoving / BindToClose.

	NOTA DE PRODUCCION: esta es una implementacion propia (para poder probarla a fondo con mocks).
	Para un juego real con mucho trafico se recomienda SUSTITUIRLA por ProfileStore
	(MadStudioRoblox/ProfileStore, ver research/06 seccion 2): lo ha usado mucha mas gente.
	La API publica de este modulo (load / save / release / attach) es deliberadamente parecida para
	que el cambio sea mecanico.

	Garantias que cubre este modulo:
	  1. NUNCA se escriben valores por defecto si la lectura falla. La carga reclama el registro con
	     UpdateAsync (que lee y escribe de forma atomica); si todos los intentos fallan, load()
	     devuelve nil y el jugador es expulsado con un mensaje; la clave no se toca.
	  2. Bloqueo de sesion: el registro guarda { jobId, heartbeat }. Otro servidor no puede cargarlo
	     mientras el bloqueo siga vivo; un bloqueo sin latido durante `staleSeconds` se considera de
	     un servidor caido y puede reclamarse. Si un servidor descubre que perdio el bloqueo, deja de
	     escribir y expulsa al jugador (evita duplicar objetos).
	  3. El callback de UpdateAsync NO cede (sin task.wait/Async dentro) y puede ejecutarse varias
	     veces: el resultado se comunica por variables locales, no por efectos externos.
	  4. Reintentos con backoff exponencial + jitter; errores 101-107 (clave/valor invalidos) no se
	     reintentan.
	  5. Datos de un esquema MAS NUEVO que el de este servidor se rechazan sin tocar el registro
	     (durante una actualizacion, un servidor viejo no debe degradar datos).
	  6. Los datos se validan antes de guardar (NaN/inf, claves mixtas, ciclos...). Si no son
	     serializables NO se sobrescribe el guardado bueno anterior.

	// REVIEW(money): este modulo guarda saldos y compras. Una persona debe revisar el flujo de
	// carga/guardado/liberacion antes de publicar.
]]

export type Schema = {
	version: number,
	template: { [string]: any },
	migrations: { [number]: (data: { [string]: any }) -> () }?,
}

export type RetryConfig = {
	attempts: number?,
	baseDelay: number?,
	maxDelay: number?,
}

export type LockConfig = {
	staleSeconds: number?, -- sin latido durante este tiempo => servidor caido (por defecto 600)
	waitSeconds: number?, -- cuanto esperar a que otro servidor suelte el bloqueo (por defecto 30)
	pollSeconds: number?, -- intervalo de sondeo mientras se espera (por defecto 3)
}

export type Messages = {
	loadFailed: string?,
	locked: string?,
	newerVersion: string?,
	lockLost: string?,
}

export type Config = {
	dataStore: any, -- DataStoreService:GetDataStore(nombre) (o un doble)
	schema: Schema,
	jobId: string, -- game.JobId (en Studio es "": pasar un GUID)
	keyPrefix: string?, -- por defecto "Player_"
	now: (() -> number)?, -- epoch en segundos (os.time)
	task: any?, -- { wait, spawn } (task en Roblox; clock.task en tests)
	random: (() -> number)?, -- jitter del backoff, [0,1)
	log: ((message: string) -> ())?,
	retry: RetryConfig?,
	releaseRetry: RetryConfig?, -- la liberacion final reintenta MAS (es el ultimo guardado)
	lock: LockConfig?,
	autosaveSeconds: number?, -- por defecto 120
	messages: Messages?,
}

export type AttachHandlers = {
	onLoaded: ((player: any, profile: any) -> ())?,
	onLoadFailed: ((player: any, reason: string) -> ())?,
	onRemoving: ((player: any, profile: any?) -> ())?,
}

local Data = {}

----------------------------------------------------------------------------
-- Utilidades puras (se prueban sin motor)
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

Data.deepCopy = deepCopy

local function isArray(tbl: { [any]: any }): boolean
	local count = 0
	for _ in tbl do
		count += 1
	end
	for i = 1, count do
		if tbl[i] == nil then
			return false
		end
	end
	return true
end

--[[
	Comprueba que `value` es serializable por DataStore: strings UTF-8 validas, numeros finitos,
	booleanos y tablas sin ciclos ni metatablas; las claves son todas strings (diccionario) o todas
	enteros 1..n (arreglo). Devuelve (true) o (false, ruta y motivo).
]]
function Data.validate(value: any, path: string?, visiting: { [any]: boolean }?, depth: number?): (boolean, string?)
	local where = path or "data"
	local level = depth or 0
	if level > 40 then
		return false, where .. ": demasiado profundo"
	end
	local kind = type(value)
	if kind == "number" then
		if not isFinite(value) then
			return false, where .. ": numero no finito"
		end
		return true, nil
	elseif kind == "boolean" then
		return true, nil
	elseif kind == "string" then
		if not utf8.len(value) then
			return false, where .. ": string con UTF-8 invalido"
		end
		return true, nil
	elseif kind == "table" then
		local seen: { [any]: boolean } = visiting or {}
		if seen[value] then
			return false, where .. ": ciclo"
		end
		if getmetatable(value) ~= nil then
			return false, where .. ": tabla con metatabla"
		end
		seen[value] = true
		local array = isArray(value)
		for k, v in value do
			if array then
				if type(k) ~= "number" then
					seen[value] = nil
					return false, where .. ": clave no numerica en arreglo"
				end
			elseif type(k) ~= "string" then
				seen[value] = nil
				return false, where .. ": clave no string (arreglo disperso o mixto)"
			end
			local ok, reason = Data.validate(v, where .. "." .. tostring(k), seen, level + 1)
			if not ok then
				seen[value] = nil
				return false, reason
			end
		end
		seen[value] = nil
		return true, nil
	end
	return false, where .. ": tipo no serializable (" .. kind .. ")"
end

-- Rellena en `data` las claves que existen en `template` y faltan (recursivo en diccionarios).
function Data.reconcile(data: { [string]: any }, template: { [string]: any })
	for key, templateValue in template do
		local current = data[key]
		if current == nil then
			data[key] = deepCopy(templateValue)
		elseif type(templateValue) == "table" and type(current) == "table" and not isArray(templateValue) then
			if next(templateValue) ~= nil then
				Data.reconcile(current, templateValue)
			end
		end
	end
end

--[[
	Migra `record` (tabla { schemaVersion, data }) hasta schema.version, en el sitio.
	Devuelve (true) o (false, motivo, esMasNueva).
]]
function Data.migrate(record: { [string]: any }, schema: Schema): (boolean, string?, boolean)
	local version = record.schemaVersion
	if type(version) ~= "number" then
		version = 1
	end
	if version > schema.version then
		return false, "datos de esquema v" .. tostring(version) .. " > v" .. tostring(schema.version), true
	end
	local data = record.data
	if type(data) ~= "table" then
		return false, "registro sin data", false
	end
	local migrations = schema.migrations or {}
	while version < schema.version do
		local step = migrations[version]
		if step == nil then
			return false, "falta la migracion v" .. tostring(version) .. " -> v" .. tostring(version + 1), false
		end
		local ok, err = pcall(step :: any, data)
		if not ok then
			return false, "migracion v" .. tostring(version) .. " fallo: " .. tostring(err), false
		end
		version += 1
	end
	record.schemaVersion = schema.version
	return true, nil, false
end

-- Errores 101-107 son del llamador (clave/valor invalidos): reintentar no sirve.
local function isRetriable(message: any): boolean
	local text = tostring(message)
	return string.match(text, "^%s*10[1-7]%f[%D]") == nil
end

Data.isRetriable = isRetriable

----------------------------------------------------------------------------
-- Profile
----------------------------------------------------------------------------

local Profile = {}
Profile.__index = Profile

type ProfileData = {
	userId: number,
	key: string,
	data: any,
	state: string, -- "active" | "releasing" | "released" | "lost" | "release-failed"
	revision: number,
	persistedRevision: number,
	lastError: string?,
	claimedAt: number,
	_manager: any,
	_saving: boolean,
}
export type Profile = typeof(setmetatable({} :: ProfileData, Profile))

function Profile.isActive(self: Profile): boolean
	return self.state == "active"
end

-- true si otro servidor tomo el bloqueo (el perfil ya no debe escribirse).
function Profile.isLost(self: Profile): boolean
	return self.state == "lost"
end

-- Marca que `data` cambio (los guardados son por revision). Llamar tras mutaciones importantes.
function Profile.markDirty(self: Profile)
	self.revision += 1
end

-- true si todo lo marcado hasta ahora ya esta en el DataStore.
function Profile.isPersisted(self: Profile): boolean
	return self.persistedRevision >= self.revision
end

function Profile.save(self: Profile): boolean
	local manager = self._manager
	local target = self.revision
	while self.persistedRevision < target do
		if self.state == "lost" then
			return false
		end
		if self._saving then
			manager:_wait(0.1)
		else
			if self.state ~= "active" and self.state ~= "releasing" and self.state ~= "release-failed" then
				return self.persistedRevision >= target
			end
			self._saving = true
			local ok = manager:_persist(self, false)
			self._saving = false
			if not ok then
				return false
			end
		end
	end
	return true
end

--[[
	Guardado final + liberacion del bloqueo. Devuelve true si quedo guardado y liberado.
	Si falla tras todos los reintentos el perfil queda en "release-failed" y el autosave lo reintenta.
]]
function Profile.release(self: Profile): boolean
	local manager = self._manager
	if self.state == "released" then
		return true
	end
	if self.state == "lost" then
		manager:_forget(self)
		return false
	end
	self.state = "releasing"
	while self._saving do
		manager:_wait(0.1)
	end
	self._saving = true
	self.revision += 1
	local ok = manager:_persist(self, true)
	self._saving = false
	if ok then
		self.state = "released"
		manager:_forget(self)
		return true
	end
	if Profile.isLost(self) then
		manager:_forget(self)
	else
		self.state = "release-failed"
		manager:_log(
			"CRITICO: no se pudo guardar/liberar el perfil " .. self.key .. " (" .. tostring(self.lastError) .. ")"
		)
	end
	return false
end

----------------------------------------------------------------------------
-- Manager
----------------------------------------------------------------------------

local Manager = {}
Manager.__index = Manager

type ManagerData = {
	cfg: Config,
	store: any,
	schema: Schema,
	jobId: string,
	prefix: string,
	taskLib: any,
	nowFn: () -> number,
	randomFn: () -> number,
	profiles: { [number]: Profile },
	loading: { [number]: boolean },
	autosaveRunning: boolean,
	shuttingDown: boolean,
	onProfileLost: ((profile: Profile) -> ())?,
}
export type Manager = typeof(setmetatable({} :: ManagerData, Manager))

function Data.new(config: Config): Manager
	assert(config.dataStore ~= nil, "Data.new requiere dataStore")
	assert(config.schema ~= nil and type(config.schema.version) == "number", "Data.new requiere schema.version")
	assert(type(config.jobId) == "string" and config.jobId ~= "", "Data.new requiere un jobId no vacio")
	local state: ManagerData = {
		cfg = config,
		store = config.dataStore,
		schema = config.schema,
		jobId = config.jobId,
		prefix = config.keyPrefix or "Player_",
		taskLib = config.task or task,
		nowFn = config.now or function(): number
			return os.time()
		end,
		randomFn = config.random or function(): number
			return math.random()
		end,
		profiles = {},
		loading = {},
		autosaveRunning = false,
		shuttingDown = false,
		onProfileLost = nil,
	}
	return setmetatable(state, Manager)
end

function Manager._wait(self: Manager, seconds: number)
	self.taskLib.wait(seconds)
end

function Manager._log(self: Manager, message: string)
	local log = self.cfg.log
	if log then
		log(message)
	else
		warn("[Data] " .. message)
	end
end

function Manager._message(self: Manager, name: string): string
	local custom = self.cfg.messages
	local override = if custom then (custom :: any)[name] else nil
	if override then
		return override
	end
	local defaults: { [string]: string } = {
		loadFailed = "No pudimos cargar tus datos. Tu progreso esta a salvo: vuelve a entrar en un momento.",
		locked = "Tu sesion anterior aun se esta cerrando. Espera un minuto y vuelve a entrar.",
		newerVersion = "Este servidor esta desactualizado. Vuelve a entrar para unirte a una version nueva.",
		lockLost = "Tu sesion se abrio en otro servidor. Vuelve a entrar.",
	}
	return defaults[name] or defaults.loadFailed
end

function Manager._forget(self: Manager, profile: Profile)
	if self.profiles[profile.userId] == profile then
		self.profiles[profile.userId] = nil
	end
end

local function backoff(manager: Manager, config: RetryConfig?, defaults: { attempts: number, baseDelay: number, maxDelay: number })
	local cfg: RetryConfig = config or {}
	return cfg.attempts or defaults.attempts, cfg.baseDelay or defaults.baseDelay, cfg.maxDelay or defaults.maxDelay
end

--[[
	Ejecuta `attempt` (que devuelve (ok, resultadoOError)) con reintentos y backoff exponencial + jitter.
	Los errores no reintentables cortan de inmediato.
]]
function Manager._retry(self: Manager, label: string, config: RetryConfig?, attempt: () -> (boolean, any)): (boolean, any)
	local attempts, delay, maxDelay = backoff(self, config, { attempts = 5, baseDelay = 1, maxDelay = 16 })
	local lastError: any = nil
	for index = 1, attempts do
		local ok, result = attempt()
		if ok then
			return true, result
		end
		lastError = result
		if not isRetriable(result) or index == attempts then
			break
		end
		self:_log(label .. ": intento " .. index .. "/" .. attempts .. " fallo (" .. tostring(result) .. "), reintentando")
		local jitter = 1 + self.randomFn() * 0.25
		self:_wait(math.min(delay, maxDelay) * jitter)
		delay = math.min(delay * 2, maxDelay)
	end
	return false, lastError
end

function Manager.keyFor(self: Manager, userId: number): string
	return self.prefix .. tostring(userId)
end

function Manager.get(self: Manager, userId: number): Profile?
	return self.profiles[userId]
end

----------------------------------------------------------------------------
-- Carga (reclamar el bloqueo de sesion)
----------------------------------------------------------------------------

type ClaimOutcome = { kind: string, record: any?, lockedBy: string? }

-- Un intento de UpdateAsync que reclama el registro. Devuelve (ok, ClaimOutcome | error).
function Manager._claimOnce(self: Manager, key: string, userId: number): (boolean, any)
	local jobId = self.jobId
	local schema = self.schema
	local staleSeconds = if self.cfg.lock and self.cfg.lock.staleSeconds then self.cfg.lock.staleSeconds else 600
	local outcome: ClaimOutcome = { kind = "unset", record = nil, lockedBy = nil }

	local function transform(old: any): any
		-- IMPORTANTE: sin yields. Puede ejecutarse varias veces; solo escribe en `outcome`.
		local now = self.nowFn()
		if old == nil then
			local fresh = {
				schemaVersion = schema.version,
				data = deepCopy(schema.template),
				lock = { jobId = jobId, heartbeat = now, claimedAt = now },
				savedAt = now,
			}
			outcome = { kind = "claimed", record = fresh, lockedBy = nil }
			return fresh, { userId }
		end
		if type(old) ~= "table" or type(old.data) ~= "table" then
			outcome = { kind = "corrupt", record = nil, lockedBy = nil }
			return nil
		end
		local version = if type(old.schemaVersion) == "number" then old.schemaVersion else 1
		if version > schema.version then
			outcome = { kind = "newer", record = nil, lockedBy = nil }
			return nil
		end
		local lock = old.lock
		if type(lock) == "table" and lock.jobId ~= jobId then
			local heartbeat = if type(lock.heartbeat) == "number" then lock.heartbeat else 0
			if now - heartbeat < staleSeconds then
				outcome = { kind = "locked", record = nil, lockedBy = tostring(lock.jobId) }
				return nil
			end
		end
		local claimed = table.clone(old)
		claimed.lock = { jobId = jobId, heartbeat = now, claimedAt = now }
		outcome = { kind = "claimed", record = claimed, lockedBy = nil }
		return claimed, { userId }
	end

	local ok, err = pcall(function()
		self.store:UpdateAsync(key, transform)
	end)
	if not ok then
		return false, err
	end
	return true, outcome
end

-- Libera un bloqueo que acabamos de reclamar sin tocar los datos (p. ej. migracion fallida).
function Manager._unlockOnly(self: Manager, key: string)
	local jobId = self.jobId
	self:_retry("unlock " .. key, nil, function()
		return pcall(function()
			self.store:UpdateAsync(key, function(old: any): any
				if type(old) ~= "table" or type(old.lock) ~= "table" or old.lock.jobId ~= jobId then
					return nil
				end
				local copy = table.clone(old)
				copy.lock = nil
				return copy
			end)
		end)
	end)
end

--[[
	Carga el perfil de `userId`. Devuelve (Profile) o (nil, motivo) con motivo en:
	  "datastore" | "locked" | "newer-version" | "corrupt" | "migration" | "cancelled" | "already-loaded"
	`shouldCancel` (opcional) permite abortar si el jugador ya se fue.
]]
function Manager.load(self: Manager, userId: number, shouldCancel: (() -> boolean)?): (Profile?, string?)
	if self.profiles[userId] and self.profiles[userId].state == "active" then
		return nil, "already-loaded"
	end
	self.loading[userId] = true
	local profile, reason = self:_loadInner(userId, shouldCancel)
	self.loading[userId] = nil
	return profile, reason
end

function Manager._loadInner(self: Manager, userId: number, shouldCancel: (() -> boolean)?): (Profile?, string?)
	local lockCfg: LockConfig = self.cfg.lock or {}
	local waitSeconds = lockCfg.waitSeconds or 30
	local pollSeconds = lockCfg.pollSeconds or 3
	local startedAt = self.nowFn()
	local key = self:keyFor(userId)

	-- Una liberacion previa del mismo jugador en este servidor puede seguir en curso.
	while self.profiles[userId] ~= nil do
		if shouldCancel and shouldCancel() then
			return nil, "cancelled"
		end
		if self.nowFn() - startedAt >= waitSeconds then
			return nil, "already-loaded"
		end
		self:_wait(0.25)
	end

	while true do
		if shouldCancel and shouldCancel() then
			return nil, "cancelled"
		end
		local ok, result = self:_retry("claim " .. key, self.cfg.retry, function()
			return self:_claimOnce(key, userId)
		end)
		if not ok then
			self:_log("no se pudo leer/reclamar " .. key .. ": " .. tostring(result))
			return nil, "datastore"
		end
		local outcome = result :: ClaimOutcome
		if outcome.kind == "locked" then
			if self.nowFn() - startedAt >= waitSeconds then
				self:_log(key .. " sigue bloqueado por el servidor " .. tostring(outcome.lockedBy))
				return nil, "locked"
			end
			self:_wait(pollSeconds)
		elseif outcome.kind == "newer" then
			self:_log(key .. ": datos de un esquema mas nuevo; no se toca el registro")
			return nil, "newer-version"
		elseif outcome.kind == "corrupt" then
			self:_log(key .. ": registro corrupto; no se toca (revision manual)")
			return nil, "corrupt"
		elseif outcome.kind == "claimed" and outcome.record ~= nil then
			local record = outcome.record :: { [string]: any }
			local migrated, why = Data.migrate(record, self.schema)
			if not migrated then
				self:_log(key .. ": " .. tostring(why))
				self:_unlockOnly(key)
				return nil, "migration"
			end
			Data.reconcile(record.data, self.schema.template)
			if shouldCancel and shouldCancel() then
				self:_unlockOnly(key)
				return nil, "cancelled"
			end
			local profileData: ProfileData = {
				userId = userId,
				key = key,
				data = record.data,
				state = "active",
				revision = 0,
				persistedRevision = 0,
				lastError = nil,
				claimedAt = self.nowFn(),
				_manager = self,
				_saving = false,
			}
			local profile: Profile = setmetatable(profileData, Profile)
			self.profiles[userId] = profile
			-- Si la migracion cambio la forma de los datos, hay que persistirla en el siguiente guardado.
			profile.revision = 1
			return profile, nil
		else
			return nil, "datastore"
		end
	end
end

-- Espera (con tope) a que el perfil de un jugador este cargado. nil si no llega / falla.
function Manager.waitForProfile(self: Manager, userId: number, timeoutSeconds: number): Profile?
	local deadline = self.nowFn() + timeoutSeconds
	while true do
		local profile = self.profiles[userId]
		if profile and profile.state == "active" then
			return profile
		end
		if not self.loading[userId] and profile == nil then
			return nil -- no se esta cargando y no existe: no esperar en vano
		end
		if self.nowFn() >= deadline then
			return nil
		end
		self:_wait(0.25)
	end
end

----------------------------------------------------------------------------
-- Guardado
----------------------------------------------------------------------------

-- Un guardado completo con reintentos. `releasing` => escribe lock = nil. Llamar con _saving = true.
function Manager._persist(self: Manager, profile: Profile, releasing: boolean): boolean
	local capturedRevision = profile.revision
	local snapshot = deepCopy(profile.data)
	local valid, why = Data.validate(snapshot)
	if not valid then
		profile.lastError = "datos no serializables: " .. tostring(why)
		self:_log("NO se guarda " .. profile.key .. " (se conserva el guardado anterior): " .. tostring(why))
		return false
	end

	local jobId = self.jobId
	local schemaVersion = self.schema.version
	local userId = profile.userId
	local lockLost = false

	local function transform(old: any): any
		-- Sin yields. Puede ejecutarse varias veces.
		local now = self.nowFn()
		if type(old) ~= "table" or type(old.lock) ~= "table" or old.lock.jobId ~= jobId then
			lockLost = true
			return nil
		end
		lockLost = false
		local new = table.clone(old)
		new.schemaVersion = schemaVersion
		new.data = snapshot
		new.savedAt = now
		if releasing then
			new.lock = nil
		else
			new.lock = { jobId = jobId, heartbeat = now, claimedAt = old.lock.claimedAt }
		end
		return new, { userId }
	end

	local defaultReleaseRetry: RetryConfig = { attempts = 8 }
	local retryConfig: RetryConfig? = if releasing then (self.cfg.releaseRetry or defaultReleaseRetry) else self.cfg.retry
	local ok, result = self:_retry("save " .. profile.key, retryConfig, function()
		return pcall(function()
			self.store:UpdateAsync(profile.key, transform)
		end)
	end)
	if not ok then
		profile.lastError = tostring(result)
		return false
	end
	if lockLost then
		profile.state = "lost"
		profile.lastError = "bloqueo de sesion perdido"
		self:_log("bloqueo de sesion PERDIDO para " .. profile.key .. ": se detienen los guardados")
		local handler = self.onProfileLost
		if handler then
			handler(profile)
		end
		return false
	end
	profile.persistedRevision = math.max(profile.persistedRevision, capturedRevision)
	profile.lastError = nil
	return true
end

----------------------------------------------------------------------------
-- Autosave / cierre / jugadores
----------------------------------------------------------------------------

function Manager.startAutosave(self: Manager)
	if self.autosaveRunning then
		return
	end
	self.autosaveRunning = true
	local interval = self.cfg.autosaveSeconds or 120
	self.taskLib.spawn(function()
		while self.autosaveRunning do
			self:_wait(interval)
			local list: { Profile } = {}
			for _, profile in self.profiles do
				table.insert(list, profile)
			end
			local spacing = math.min(1, interval / math.max(#list, 1))
			for _, profile in list do
				if not self.autosaveRunning then
					break
				end
				self.taskLib.spawn(function()
					if profile.state == "active" then
						profile:markDirty() -- tambien sirve de latido del bloqueo
						profile:save()
					elseif profile.state == "release-failed" then
						profile:release() -- reintento de un guardado final fallido
					end
				end)
				self:_wait(spacing)
			end
		end
	end)
end

function Manager.stopAutosave(self: Manager)
	self.autosaveRunning = false
end

--[[
	Cierre del servidor (BindToClose): libera todos los perfiles EN PARALELO y espera hasta `maxSeconds`
	(Roblox da ~30 s). Devuelve el numero de perfiles que NO pudieron guardarse.
]]
function Manager.shutdown(self: Manager, maxSeconds: number?): number
	self.shuttingDown = true
	self.autosaveRunning = false
	local limit = maxSeconds or 25
	local startedAt = self.nowFn()
	local pending = 0
	for _, profile in self.profiles do
		if profile.state ~= "released" and profile.state ~= "lost" then
			pending += 1
			self.taskLib.spawn(function()
				profile:release()
				pending -= 1
			end)
		end
	end
	while pending > 0 and self.nowFn() - startedAt < limit do
		self:_wait(0.25)
	end
	local failed = 0
	for _, profile in self.profiles do
		if profile.state ~= "released" then
			failed += 1
		end
	end
	return failed
end

--[[
	Integra con Players: carga al entrar, libera al salir, expulsa si falla la carga y guarda en BindToClose.
	`players` = servicio Players (o doble). `bindToClose` = function(callback) game:BindToClose(callback).
]]
function Manager.attach(self: Manager, players: any, bindToClose: ((callback: () -> ()) -> ())?, handlers: AttachHandlers?)
	local hooks: AttachHandlers = handlers or {}

	self.onProfileLost = function(profile: Profile)
		local player = players:GetPlayerByUserId(profile.userId)
		if player then
			player:Kick(self:_message("lockLost"))
		end
	end

	local function loadPlayer(player: any)
		local profile, reason = self:load(player.UserId, function()
			return player.Parent == nil
		end)
		if profile == nil then
			if reason ~= "cancelled" and player.Parent ~= nil then
				local messageKey = if reason == "locked"
					then "locked"
					elseif reason == "newer-version" then "newerVersion"
					else "loadFailed"
				if hooks.onLoadFailed then
					hooks.onLoadFailed(player, reason or "unknown")
				end
				player:Kick(self:_message(messageKey))
			end
			return
		end
		if player.Parent == nil then
			profile:release()
			return
		end
		if hooks.onLoaded then
			hooks.onLoaded(player, profile)
		end
	end

	players.PlayerAdded:Connect(function(player: any)
		self.taskLib.spawn(loadPlayer, player)
	end)

	players.PlayerRemoving:Connect(function(player: any)
		local profile = self.profiles[player.UserId]
		if hooks.onRemoving then
			local ok, err = pcall(hooks.onRemoving, player, profile)
			if not ok then
				self:_log("onRemoving fallo: " .. tostring(err))
			end
		end
		if profile then
			self.taskLib.spawn(function()
				profile:release()
			end)
		end
	end)

	for _, player in players:GetPlayers() do
		self.taskLib.spawn(loadPlayer, player)
	end

	if bindToClose then
		bindToClose(function()
			self:shutdown()
		end)
	end
end

return Data
