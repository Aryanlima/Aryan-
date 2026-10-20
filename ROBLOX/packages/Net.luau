--!strict
--[[
	Net: registro de RemoteEvents / RemoteFunctions con
	  * validacion de tipos y rangos de TODOS los argumentos (rechaza NaN/inf, cadenas enormes,
	    UTF-8 invalido, aridad incorrecta),
	  * limitador de frecuencia por jugador y por remoto (token bucket con os.clock inyectable),
	  * un limite global por jugador para todos los remotos juntos,
	  * deteccion de abuso (muchos rechazos en una ventana) con gancho `onAbuse`.

	Principio: el servidor decide, el cliente solo solicita. Ningun handler recibe datos sin validar.

	Uso (servidor):
	  local server = Net.newServer({ folder = remotesFolder })
	  server:event("CastRod", {
	  	args = { Net.t.number({ min = 0, max = 1 }) },
	  	rate = { capacity = 3, refillPerSecond = 1 },
	  	handler = function(player, power) ... end,
	  })
	  server:fireClient("Banner", player, "texto")

	Uso (cliente):
	  local client = Net.newClient(remotesFolder)
	  client:fire("CastRod", 0.8)
	  client:onEvent("Banner", function(text) ... end)

	Los objetos del motor (carpeta, remotos) se tipan como `any` en la frontera; las pruebas
	inyectan `createRemote` con dobles (ver tests/Net.spec.luau).
]]

export type Clock = () -> number
export type Validator = (value: any) -> (boolean, string?)

export type RateConfig = { capacity: number, refillPerSecond: number }

export type EventDef = {
	args: { Validator },
	rate: RateConfig?,
	handler: (player: any, ...any) -> ...any,
}

export type FunctionDef = {
	args: { Validator },
	rate: RateConfig?,
	handler: (player: any, ...any) -> ...any,
}

export type ServerConfig = {
	folder: any?,
	createRemote: ((className: string, name: string) -> any)?,
	clock: Clock?,
	globalRate: RateConfig?, -- limite combinado por jugador (todos los remotos)
	onReject: ((player: any, remoteName: string, reason: string) -> ...any)?,
	abuseThreshold: number?, -- rechazos por ventana para disparar onAbuse (por defecto 30)
	abuseWindowSeconds: number?, -- (por defecto 10)
	onAbuse: ((player: any, rejections: number) -> ...any)?,
	log: ((message: string) -> ...any)?,
}

local Net = {}

----------------------------------------------------------------------------
-- Validadores
----------------------------------------------------------------------------

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local t = {}

export type NumberOptions = { min: number?, max: number?, integer: boolean? }

-- Numero finito (rechaza NaN y +-inf), con rango y entero opcionales.
function t.number(options: NumberOptions?): Validator
	local opts: NumberOptions = options or {}
	return function(value: any): (boolean, string?)
		if type(value) ~= "number" then
			return false, "se esperaba number, llego " .. typeof(value)
		end
		if not isFinite(value) then
			return false, "numero no finito (NaN/inf)"
		end
		if opts.integer and value % 1 ~= 0 then
			return false, "se esperaba un entero"
		end
		if opts.min ~= nil and value < opts.min then
			return false, "por debajo del minimo " .. tostring(opts.min)
		end
		if opts.max ~= nil and value > opts.max then
			return false, "por encima del maximo " .. tostring(opts.max)
		end
		return true, nil
	end
end

function t.integer(min: number, max: number): Validator
	return t.number({ min = min, max = max, integer = true })
end

export type StringOptions = { minLength: number?, maxLength: number?, pattern: string? }

-- Cadena UTF-8 valida con longitud acotada (por defecto 1..64 bytes). `pattern` es un patron de Luau.
function t.string(options: StringOptions?): Validator
	local opts: StringOptions = options or {}
	local minLength = opts.minLength or 1
	local maxLength = opts.maxLength or 64
	return function(value: any): (boolean, string?)
		if type(value) ~= "string" then
			return false, "se esperaba string, llego " .. typeof(value)
		end
		local length = #value
		if length < minLength then
			return false, "cadena demasiado corta"
		end
		if length > maxLength then
			return false, "cadena demasiado larga"
		end
		if not utf8.len(value) then
			return false, "UTF-8 invalido"
		end
		if opts.pattern ~= nil and string.find(value, opts.pattern) == nil then
			return false, "no cumple el patron"
		end
		return true, nil
	end
end

function t.boolean(): Validator
	return function(value: any): (boolean, string?)
		if type(value) ~= "boolean" then
			return false, "se esperaba boolean, llego " .. typeof(value)
		end
		return true, nil
	end
end

-- El valor debe ser uno de la lista (cadenas o numeros). Ideal para claves de catalogo.
function t.oneOf(allowed: { any }): Validator
	local set: { [any]: boolean } = {}
	for _, item in allowed do
		set[item] = true
	end
	return function(value: any): (boolean, string?)
		if type(value) ~= "string" and type(value) ~= "number" then
			return false, "tipo no permitido"
		end
		if value ~= value or not set[value] then
			return false, "valor fuera de la lista permitida"
		end
		return true, nil
	end
end

-- nil es aceptado; si hay valor, debe cumplir `inner`.
function t.optional(inner: Validator): Validator
	return function(value: any): (boolean, string?)
		if value == nil then
			return true, nil
		end
		return inner(value)
	end
end

Net.t = t

--[[
	Valida una lista de argumentos contra un esquema posicional.
	Rechaza argumentos de mas (aridad) y los faltantes que no sean `optional`.
]]
function Net.checkArgs(schema: { Validator }, ...: any): (boolean, string?)
	local count = select("#", ...)
	if count > #schema then
		return false, "demasiados argumentos (" .. count .. " > " .. #schema .. ")"
	end
	local args = { ... }
	for index, validator in schema do
		local ok, reason = validator(args[index])
		if not ok then
			return false, "argumento #" .. index .. ": " .. tostring(reason)
		end
	end
	return true, nil
end

----------------------------------------------------------------------------
-- Token bucket
----------------------------------------------------------------------------

local TokenBucket = {}
TokenBucket.__index = TokenBucket

type TokenBucketData = {
	capacity: number,
	refillPerSecond: number,
	tokens: number,
	last: number,
	clock: Clock,
}
export type TokenBucket = typeof(setmetatable({} :: TokenBucketData, TokenBucket))

function Net.newBucket(capacity: number, refillPerSecond: number, clock: Clock?): TokenBucket
	assert(isFinite(capacity) and capacity > 0, "capacity debe ser > 0")
	assert(isFinite(refillPerSecond) and refillPerSecond >= 0, "refillPerSecond debe ser >= 0")
	local now = clock or os.clock
	local data: TokenBucketData = {
		capacity = capacity,
		refillPerSecond = refillPerSecond,
		tokens = capacity,
		last = now(),
		clock = now,
	}
	return setmetatable(data, TokenBucket)
end

function TokenBucket.refill(self: TokenBucket)
	local now = self.clock()
	if now < self.last then
		self.last = now -- el reloj retrocedio: no regalar fichas
	end
	local elapsed = now - self.last
	self.last = now
	self.tokens = math.min(self.capacity, self.tokens + elapsed * self.refillPerSecond)
end

-- Intenta gastar `cost` fichas. true si hay suficientes.
function TokenBucket.take(self: TokenBucket, cost: number?): boolean
	self:refill()
	local amount = cost or 1
	if self.tokens >= amount then
		self.tokens -= amount
		return true
	end
	return false
end

function TokenBucket.available(self: TokenBucket): number
	self:refill()
	return self.tokens
end

----------------------------------------------------------------------------
-- Servidor
----------------------------------------------------------------------------

local Server = {}
Server.__index = Server

type RemoteRecord = {
	kind: string, -- "event" | "function"
	remote: any,
	rate: RateConfig?,
}

type ServerData = {
	config: ServerConfig,
	clock: Clock,
	remotes: { [string]: RemoteRecord },
	buckets: { [number]: { [string]: TokenBucket } }, -- userId -> remoto -> bucket
	globalBuckets: { [number]: TokenBucket },
	rejections: { [number]: { count: number, windowStart: number, flagged: boolean } },
	rejectedTotal: number,
	acceptedTotal: number,
}
export type Server = typeof(setmetatable({} :: ServerData, Server))

function Net.newServer(config: ServerConfig?): Server
	local cfg: ServerConfig = config or {}
	local data: ServerData = {
		config = cfg,
		clock = cfg.clock or os.clock,
		remotes = {},
		buckets = {},
		globalBuckets = {},
		rejections = {},
		rejectedTotal = 0,
		acceptedTotal = 0,
	}
	return setmetatable(data, Server)
end

local function userIdOf(player: any): number
	local userId = if type(player) == "table" or typeof(player) == "Instance" then player.UserId else nil
	if type(userId) ~= "number" then
		return 0
	end
	return userId
end

function Server._createRemote(self: Server, className: string, name: string): any
	local create = self.config.createRemote
	if create then
		return create(className, name)
	end
	-- Por defecto: instancia real. Se ASIGNA el padre al final (no Instance.new(clase, padre)).
	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = self.config.folder
	return remote
end

function Server._log(self: Server, message: string)
	local log = self.config.log
	if log then
		log(message)
	else
		warn("[Net] " .. message)
	end
end

function Server._reject(self: Server, player: any, name: string, reason: string)
	self.rejectedTotal += 1
	local onReject = self.config.onReject
	if onReject then
		onReject(player, name, reason)
	end
	local userId = userIdOf(player)
	local now = self.clock()
	local window = self.config.abuseWindowSeconds or 10
	local threshold = self.config.abuseThreshold or 30
	local record = self.rejections[userId]
	if record == nil or now - record.windowStart > window then
		record = { count = 0, windowStart = now, flagged = false }
		self.rejections[userId] = record
	end
	record.count += 1
	if record.count >= threshold and not record.flagged then
		record.flagged = true
		local onAbuse = self.config.onAbuse
		if onAbuse then
			onAbuse(player, record.count)
		end
	end
end

-- Devuelve (true) o (false, motivo). Consume fichas del limite del remoto y del global.
function Server._admit(self: Server, player: any, name: string, record: RemoteRecord): (boolean, string?)
	local userId = userIdOf(player)

	local globalRate = self.config.globalRate
	if globalRate then
		local existing: TokenBucket? = self.globalBuckets[userId]
		local bucket: TokenBucket = existing
			or Net.newBucket(globalRate.capacity, globalRate.refillPerSecond, self.clock)
		self.globalBuckets[userId] = bucket
		if not bucket:take(1) then
			return false, "rate-global"
		end
	end

	local rate = record.rate
	if rate then
		local perPlayer = self.buckets[userId]
		if perPlayer == nil then
			perPlayer = {}
			self.buckets[userId] = perPlayer
		end
		local existing: TokenBucket? = perPlayer[name]
		local bucket: TokenBucket = existing or Net.newBucket(rate.capacity, rate.refillPerSecond, self.clock)
		perPlayer[name] = bucket
		if not bucket:take(1) then
			return false, "rate"
		end
	end
	return true, nil
end

function Server.event(self: Server, name: string, def: EventDef)
	assert(self.remotes[name] == nil, "remoto duplicado: " .. name)
	local remote = self:_createRemote("RemoteEvent", name)
	local record: RemoteRecord = { kind = "event", remote = remote, rate = def.rate }
	self.remotes[name] = record
	remote.OnServerEvent:Connect(function(player: any, ...: any)
		local admitted, why = self:_admit(player, name, record)
		if not admitted then
			self:_reject(player, name, why or "rate")
			return
		end
		local valid, reason = Net.checkArgs(def.args, ...)
		if not valid then
			self:_reject(player, name, "args: " .. tostring(reason))
			return
		end
		self.acceptedTotal += 1
		local ok, err = pcall(def.handler, player, ...)
		if not ok then
			self:_log("error en handler de " .. name .. ": " .. tostring(err))
		end
	end)
end

function Server.func(self: Server, name: string, def: FunctionDef)
	assert(self.remotes[name] == nil, "remoto duplicado: " .. name)
	local remote = self:_createRemote("RemoteFunction", name)
	local record: RemoteRecord = { kind = "function", remote = remote, rate = def.rate }
	self.remotes[name] = record
	remote.OnServerInvoke = function(player: any, ...: any): ...any
		local admitted, why = self:_admit(player, name, record)
		if not admitted then
			self:_reject(player, name, why or "rate")
			return nil
		end
		local valid, reason = Net.checkArgs(def.args, ...)
		if not valid then
			self:_reject(player, name, "args: " .. tostring(reason))
			return nil
		end
		self.acceptedTotal += 1
		local results = table.pack(pcall(def.handler, player, ...))
		if not results[1] then
			self:_log("error en handler de " .. name .. ": " .. tostring(results[2]))
			return nil
		end
		return table.unpack(results, 2, results.n)
	end
end

-- Remoto SOLO servidor -> cliente (no escucha OnServerEvent: lo que el cliente dispare se ignora).
function Server.outbound(self: Server, name: string)
	assert(self.remotes[name] == nil, "remoto duplicado: " .. name)
	local remote = self:_createRemote("RemoteEvent", name)
	self.remotes[name] = { kind = "event", remote = remote, rate = nil }
end

function Server.fireClient(self: Server, name: string, player: any, ...: any)
	local record = self.remotes[name]
	assert(record and record.kind == "event", "remoto desconocido: " .. name)
	record.remote:FireClient(player, ...)
end

function Server.fireAllClients(self: Server, name: string, ...: any)
	local record = self.remotes[name]
	assert(record and record.kind == "event", "remoto desconocido: " .. name)
	record.remote:FireAllClients(...)
end

-- Llamar en PlayerRemoving: libera fichas y contadores (evita fugas de memoria).
function Server.forget(self: Server, player: any)
	local userId = userIdOf(player)
	self.buckets[userId] = nil
	self.globalBuckets[userId] = nil
	self.rejections[userId] = nil
end

function Server.stats(self: Server): { accepted: number, rejected: number }
	return { accepted = self.acceptedTotal, rejected = self.rejectedTotal }
end

----------------------------------------------------------------------------
-- Cliente (solo conveniencia; la seguridad real esta en el servidor)
----------------------------------------------------------------------------

local Client = {}
Client.__index = Client

type ClientData = {
	folder: any,
	clock: Clock,
	buckets: { [string]: TokenBucket },
	timeout: number,
}
export type Client = typeof(setmetatable({} :: ClientData, Client))

export type ClientOptions = { clock: Clock?, timeoutSeconds: number? }

function Net.newClient(folder: any, options: ClientOptions?): Client
	local opts: ClientOptions = options or {}
	local data: ClientData = {
		folder = folder,
		clock = opts.clock or os.clock,
		buckets = {},
		timeout = opts.timeoutSeconds or 30,
	}
	return setmetatable(data, Client)
end

function Client._remote(self: Client, name: string): any
	local remote = self.folder:WaitForChild(name, self.timeout)
	if remote == nil then
		error("Net: remoto '" .. name .. "' no disponible", 3)
	end
	return remote
end

-- Dispara al servidor con un limite de cortesia local (el limite autoritativo es el del servidor).
function Client.fire(self: Client, name: string, ...: any)
	local existing: TokenBucket? = self.buckets[name]
	local bucket: TokenBucket = existing or Net.newBucket(6, 3, self.clock)
	self.buckets[name] = bucket
	if not bucket:take(1) then
		return
	end
	self:_remote(name):FireServer(...)
end

function Client.invoke(self: Client, name: string, ...: any): ...any
	return self:_remote(name):InvokeServer(...)
end

function Client.onEvent(self: Client, name: string, callback: (...any) -> ()): any
	return self:_remote(name).OnClientEvent:Connect(callback)
end

return Net
