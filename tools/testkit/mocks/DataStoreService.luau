--!nonstrict
--[[
	DataStoreService (mock): GetDataStore / GetAsync / SetAsync / UpdateAsync /
	IncrementAsync / RemoveAsync en memoria, con simulacion de fallos y limites.

	IMPORTANTE: es un modelo SIMPLIFICADO para probar logica (reintentos, idempotencia,
	manejo de errores). Los textos de error, codigos y limites son aproximaciones
	[NO VERIFICADO contra la documentacion oficial]; ajustalos en `DataStoreService.Limits`
	o por opciones. No reproduce colas de throttling, replicacion ni el cooldown
	de escritura por clave (opcional: `enforceWriteCooldown`).

	Uso:
		local service = DataStoreService.new({ clock = clock, players = players })
		local store = service:GetDataStore("PlayerData")
		store:SetAsync("k", { coins = 1 })

	Simulacion de fallos (todas deterministas):
		service:SetOutage(true)                     -- todo falla hasta SetOutage(false)
		service:FailNext(2, { op = "UpdateAsync", key = "k", message = "..." })
		service:SetFailureRate(0.3, seed)           -- fallos pseudoaleatorios reproducibles
		service.onRequest = function(info) ... end  -- gancho previo a cada peticion
		                                            -- (p. ej. simular otro servidor escribiendo)
	Inspeccion (no consume presupuesto ni se registra):
		store:_peek(key)  store:_seed(key, value)  store:_keys()
		service.log (lista de {op, store, key, time, ok, err})  service:GetRequestCount(op?)
]]

local DataStoreService = {}
DataStoreService.__index = DataStoreService

local DataStore = {}
DataStore.__index = DataStore

-- Aproximaciones (ver aviso arriba). Editables.
DataStoreService.Limits = {
	maxKeyLength = 50,
	maxNameLength = 50,
	maxValueBytes = 4 * 1024 * 1024,
	-- Presupuesto por minuto del servidor: base + perPlayer * jugadores (token bucket continuo).
	-- Valores por defecto segun roblox-dev/references/datastore-persistence.md (2026-10) [TERCERO].
	-- Se ignora la categoria List (no se simula ListKeysAsync & co.).
	budgets = {
		Get = { base = 60, perPlayer = 40 },
		Set = { base = 60, perPlayer = 40 },
		Remove = { base = 60, perPlayer = 40 },
	},
	writeCooldownSeconds = 6,
}

-- UpdateAsync consume presupuesto de lectura Y de escritura.
local OP_CATEGORIES = {
	GetAsync = { "Get" },
	SetAsync = { "Set" },
	UpdateAsync = { "Get", "Set" },
	IncrementAsync = { "Set" },
	RemoveAsync = { "Remove" },
}

----------------------------------------------------------------------------
-- Utilidades: copia profunda y "serializacion" (validacion tipo JSON)
----------------------------------------------------------------------------

local function deepCopy(value, seen)
	if type(value) ~= "table" then
		return value
	end
	seen = seen or {}
	if seen[value] then
		return seen[value]
	end
	local copy = {}
	seen[value] = copy
	for k, v in value do
		copy[deepCopy(k, seen)] = deepCopy(v, seen)
	end
	return copy
end

local function isArray(t)
	local n = 0
	for _ in t do
		n += 1
	end
	if n == 0 then
		return true
	end
	for i = 1, n do
		if t[i] == nil then
			return false
		end
	end
	return true
end

-- Devuelve (ok, bytesAprox | mensajeError)
local function validate(value, path, visiting)
	local t = type(value)
	if t == "string" then
		if not utf8.len(value) then
			return false, "104: Cannot store string with invalid UTF-8 in data store"
		end
		return true, #value + 2
	elseif t == "number" then
		if value ~= value or value == math.huge or value == -math.huge then
			return false, "104: Cannot store NaN or infinity in data store"
		end
		return true, 8
	elseif t == "boolean" then
		return true, 5
	elseif t == "nil" then
		return true, 4
	elseif t == "table" then
		if visiting[value] then
			return false, "104: Cannot store cyclic table in data store"
		end
		if getmetatable(value) ~= nil then
			return false, "104: Cannot store table with a metatable in data store (" .. path .. ")"
		end
		visiting[value] = true
		local total = 2
		if isArray(value) then
			for i = 1, #value do
				local ok, res = validate(value[i], path .. "[" .. i .. "]", visiting)
				if not ok then
					visiting[value] = nil
					return false, res
				end
				total += res + 1
			end
		else
			for k, v in value do
				if type(k) ~= "string" then
					visiting[value] = nil
					return false,
						"104: Cannot store table with non-string keys (mixed or sparse array) in data store ("
							.. path
							.. ")"
				end
				local okK, resK = validate(k, path, visiting)
				if not okK then
					visiting[value] = nil
					return false, resK
				end
				local ok, res = validate(v, path .. "." .. k, visiting)
				if not ok then
					visiting[value] = nil
					return false, res
				end
				total += resK + res + 1
			end
		end
		visiting[value] = nil
		return true, total
	else
		return false, "104: Cannot store " .. t .. " in data store"
	end
end

----------------------------------------------------------------------------
-- DataStoreKeyInfo
----------------------------------------------------------------------------

local function newKeyInfo(entry)
	local info = {
		Version = tostring(entry.version),
		CreatedTime = entry.created,
		UpdatedTime = entry.updated,
	}
	local userIds = deepCopy(entry.userIds or {})
	local metadata = deepCopy(entry.metadata or {})
	function info:GetUserIds()
		return deepCopy(userIds)
	end
	function info:GetMetadata()
		return deepCopy(metadata)
	end
	return info
end

----------------------------------------------------------------------------
-- Servicio
----------------------------------------------------------------------------

--[[
	options:
	  clock                 mocks/Clock (para tiempos, latencia y cooldowns)
	  players               mocks/Players (para el presupuesto por jugador)
	  latency               segundos simulados por peticion (usa clock.task.wait)
	  enforceBudgets        bool (por defecto false): activar presupuestos por minuto
	  enforceWriteCooldown  bool (por defecto false): error si se escribe la misma clave < 6 s
]]
function DataStoreService.new(options)
	local opts = options or {}
	local self = setmetatable({}, DataStoreService)
	self._clock = opts.clock
	self._players = opts.players
	self._latency = opts.latency or 0
	self._enforceBudgets = opts.enforceBudgets == true
	self._enforceWriteCooldown = opts.enforceWriteCooldown == true
	self._stores = {} -- "name\0scope" -> DataStore
	self._outage = false
	self._failQueue = {}
	self._failureRate = 0
	self._rngState = 12345
	self._tokens = {} -- categoria -> { value=, last= }
	self.log = {}
	self.onRequest = nil
	self.Limits = DataStoreService.Limits
	return self
end

function DataStoreService:_time(): number
	return self._clock and self._clock:now() or 0
end

function DataStoreService:_wait(seconds: number)
	if seconds <= 0 then
		return
	end
	if self._clock then
		self._clock.task.wait(seconds)
	end
end

function DataStoreService:GetDataStore(name: string, scope: string?, _options: any?)
	if type(name) ~= "string" or name == "" then
		error("102: DataStore name can't be empty", 0)
	end
	if #name > self.Limits.maxNameLength then
		error("102: DataStore name exceeds the " .. self.Limits.maxNameLength .. " character limit", 0)
	end
	local scopeName = scope or "global"
	local id = name .. "\0" .. scopeName
	local store = self._stores[id]
	if not store then
		store = setmetatable({
			Name = name,
			Scope = scopeName,
			_service = self,
			_data = {}, -- key -> entry {value, version, created, updated, userIds, metadata}
			_lastWrite = {}, -- key -> tiempo de la ultima escritura
			_versionCounter = 0,
		}, DataStore)
		self._stores[id] = store
	end
	return store
end

function DataStoreService:GetGlobalDataStore()
	return self:GetDataStore("global", "u")
end

-- Todas las peticiones fallan hasta SetOutage(false).
function DataStoreService:SetOutage(enabled: boolean, message: string?)
	self._outage = enabled
	self._outageMessage = message
end

--[[
	Las siguientes `count` peticiones (que cumplan el filtro) fallan.
	filter = { op = "GetAsync"|..., key = "k", store = "Nombre", message = "texto" }
]]
function DataStoreService:FailNext(count: number, filter: { [string]: any }?)
	table.insert(self._failQueue, { remaining = count or 1, filter = filter or {} })
end

-- Fallos aleatorios reproducibles (LCG). rate en [0, 1].
function DataStoreService:SetFailureRate(rate: number, seed: number?)
	self._failureRate = rate
	if seed then
		self._rngState = seed % 2147483647
		if self._rngState == 0 then
			self._rngState = 1
		end
	end
end

function DataStoreService:_random(): number
	self._rngState = (self._rngState * 48271) % 2147483647
	return self._rngState / 2147483647
end

function DataStoreService:SetLatency(seconds: number)
	self._latency = seconds
end

function DataStoreService:GetRequestCount(op: string?): number
	local n = 0
	for _, entry in self.log do
		if op == nil or entry.op == op then
			n += 1
		end
	end
	return n
end

function DataStoreService:ResetLog()
	self.log = {}
end

-- Comprueba todas las categorias y solo consume si TODAS tienen presupuesto.
function DataStoreService:_budgetCheck(categories: { string }): string?
	if not self._enforceBudgets then
		return nil
	end
	local players = self._players and #self._players:GetPlayers() or 0
	local now = self:_time()
	local buckets = {}
	for _, category in categories do
		local cfg = self.Limits.budgets[category]
		if cfg then
			local perMinute = cfg.base + cfg.perPlayer * players
			local bucket = self._tokens[category]
			if not bucket then
				bucket = { value = perMinute, last = now }
				self._tokens[category] = bucket
			end
			bucket.value = math.min(perMinute, bucket.value + (now - bucket.last) * (perMinute / 60))
			bucket.last = now
			if bucket.value < 1 then
				return "301: DataStore request was throttled ("
					.. category
					.. " budget of "
					.. perMinute
					.. "/min exhausted)"
			end
			table.insert(buckets, bucket)
		end
	end
	for _, bucket in buckets do
		bucket.value -= 1
	end
	return nil
end

-- Punto unico de entrada de peticiones: registro, gancho, fallos, latencia, presupuesto.
function DataStoreService:_begin(store, op: string, key: any, isWrite: boolean)
	local entry = { op = op, store = store.Name, key = key, time = self:_time() }
	table.insert(self.log, entry)

	if self.onRequest then
		self.onRequest({ op = op, store = store.Name, scope = store.Scope, key = key })
	end

	self:_wait(self._latency)
	entry.time = self:_time()

	local function fail(message)
		entry.ok = false
		entry.err = message
		error(message, 0)
	end

	if type(key) ~= "string" or key == "" then
		fail("101: Key name can't be empty")
	end
	if #key > self.Limits.maxKeyLength then
		fail("102: Key name exceeds the " .. self.Limits.maxKeyLength .. " character limit")
	end

	if self._outage then
		fail(self._outageMessage or "502: [mock] simulated DataStore outage")
	end

	for i, queued in self._failQueue do
		local f = queued.filter
		if
			(f.op == nil or f.op == op)
			and (f.key == nil or f.key == key)
			and (f.store == nil or f.store == store.Name)
		then
			queued.remaining -= 1
			local message = f.message or "502: [mock] simulated DataStore failure"
			if queued.remaining <= 0 then
				table.remove(self._failQueue, i)
			end
			fail(message)
		end
	end

	if self._failureRate > 0 and self:_random() < self._failureRate then
		fail("502: [mock] random simulated DataStore failure")
	end

	local budgetError = self:_budgetCheck(OP_CATEGORIES[op])
	if budgetError then
		fail(budgetError)
	end

	if isWrite and self._enforceWriteCooldown then
		local last = store._lastWrite[key]
		if last and self:_time() - last < self.Limits.writeCooldownSeconds then
			fail("306: [mock] write to the same key within the cooldown window")
		end
	end

	entry.ok = true
	return entry
end

----------------------------------------------------------------------------
-- DataStore
----------------------------------------------------------------------------

function DataStore:_commit(key, value, userIds, metadata)
	local ok, sizeOrErr = validate(value, "value", {})
	if not ok then
		error(sizeOrErr, 0)
	end
	if sizeOrErr > self._service.Limits.maxValueBytes then
		error("105: Serialized value exceeds the " .. self._service.Limits.maxValueBytes .. " byte limit", 0)
	end
	local now = self._service:_time()
	self._versionCounter += 1
	local previous = self._data[key]
	local entry = {
		value = deepCopy(value),
		version = self._versionCounter,
		created = previous and previous.created or now,
		updated = now,
		userIds = userIds or (previous and previous.userIds) or {},
		metadata = metadata or (previous and previous.metadata) or {},
	}
	self._data[key] = entry
	self._lastWrite[key] = now
	return entry
end

function DataStore:GetAsync(key: string, _options: any?)
	self._service:_begin(self, "GetAsync", key, false)
	local entry = self._data[key]
	if not entry then
		return nil, nil
	end
	return deepCopy(entry.value), newKeyInfo(entry)
end

function DataStore:SetAsync(key: string, value: any, userIds: { number }?, options: any?)
	self._service:_begin(self, "SetAsync", key, true)
	local metadata = options and options.GetMetadata and options:GetMetadata() or nil
	local entry = self:_commit(key, value, userIds, metadata)
	return tostring(entry.version)
end

--[=[
	transform(oldValue, keyInfo) -> newValue | nil [, userIds [, metadata]]
	  * devolver nil cancela la actualizacion (se devuelve nil, nil).
	  * el callback NO puede ceder (en Roblox esta prohibido): el mock lanza error si cede.
	  * una peticion es atomica en el mock (no hay entrelazado dentro de UpdateAsync).
]=]
function DataStore:UpdateAsync(key: string, transform: (any, any) -> ...any)
	assert(type(transform) == "function", "UpdateAsync espera una funcion de transformacion")
	self._service:_begin(self, "UpdateAsync", key, true)
	local entry = self._data[key]
	local oldValue = entry and deepCopy(entry.value) or nil
	local keyInfo = entry and newKeyInfo(entry) or nil

	local thread = coroutine.create(transform)
	local results = table.pack(coroutine.resume(thread, oldValue, keyInfo))
	if not results[1] then
		error(results[2], 0)
	end
	if coroutine.status(thread) ~= "dead" then
		error("UpdateAsync: el callback cedio (yield); en Roblox no se permite ceder dentro del callback", 0)
	end
	local newValue, userIds, metadata = results[2], results[3], results[4]
	if newValue == nil then
		return nil, nil
	end
	local committed = self:_commit(key, newValue, userIds, metadata)
	return deepCopy(committed.value), newKeyInfo(committed)
end

function DataStore:IncrementAsync(key: string, delta: number?, userIds: { number }?)
	self._service:_begin(self, "IncrementAsync", key, true)
	local entry = self._data[key]
	local current = entry and entry.value or 0
	if type(current) ~= "number" then
		error("104: IncrementAsync on a non-number value", 0)
	end
	local newValue = current + (delta or 1)
	if newValue ~= math.floor(newValue) then
		error("104: IncrementAsync requires integer values", 0)
	end
	self:_commit(key, newValue, userIds, nil)
	return newValue
end

function DataStore:RemoveAsync(key: string)
	self._service:_begin(self, "RemoveAsync", key, true)
	local entry = self._data[key]
	if not entry then
		return nil, nil
	end
	self._data[key] = nil
	self._lastWrite[key] = self._service:_time()
	return deepCopy(entry.value), newKeyInfo(entry)
end

-- Ayudas de inspeccion (no cuentan como peticion).
function DataStore:_peek(key: string)
	local entry = self._data[key]
	return entry and deepCopy(entry.value) or nil
end

function DataStore:_seed(key: string, value: any)
	self:_commit(key, value, nil, nil)
end

function DataStore:_keys(): { string }
	local keys = {}
	for k in self._data do
		table.insert(keys, k)
	end
	table.sort(keys)
	return keys
end

return DataStoreService
