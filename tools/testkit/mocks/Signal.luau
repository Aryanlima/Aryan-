--!nonstrict
--[[
	Signal: sustituto de RBXScriptSignal / BindableEvent para pruebas.

	  signal:Connect(fn)  -> connection { Connected, Disconnect() }
	  signal:Once(fn)
	  signal:Wait()       -> devuelve los argumentos del siguiente Fire (cede el hilo actual)
	  signal:Fire(...)    -> (API de mock) cada handler corre en su propio hilo, como en Roblox
	  signal:DisconnectAll() / signal:Destroy()

	Opciones: `spawn(fn, ...)` para lanzar handlers (p. ej. clock.task.spawn, para que
	un handler que llama a task.wait use el reloj simulado); `quiet = true` no hace warn()
	de los errores de handlers (siguen en `signal.errors`).
	Los errores de handlers se acumulan en `signal.errors` (no se propagan, igual que en Roblox).
]]

local stdio = require("@lune/stdio")

local Signal = {}
Signal.__index = Signal

local function defaultSpawn(fn, ...)
	local thread = coroutine.create(fn)
	local ok, err = coroutine.resume(thread, ...)
	return thread, ok, err
end

function Signal.new(options: { spawn: ((any, ...any) -> any)? }?)
	local self = setmetatable({}, Signal)
	self._handlers = {}
	self._spawn = options and options.spawn or nil
	self._quiet = options ~= nil and options.quiet == true
	self.errors = {}
	return self
end

function Signal:_run(fn, ...)
	local errors = self.errors
	local quiet = self._quiet
	local wrapped = function(...)
		local ok, err = pcall(fn, ...)
		if not ok then
			table.insert(errors, tostring(err))
			if not quiet then
				stdio.ewrite("[mock Signal] error en handler: " .. tostring(err) .. "\n")
			end
		end
	end
	if self._spawn then
		self._spawn(wrapped, ...)
	else
		defaultSpawn(wrapped, ...)
	end
end

function Signal:Connect(fn)
	assert(type(fn) == "function", "Signal:Connect espera una funcion")
	local connection = { Connected = true }
	local entry = { fn = fn, connection = connection }
	function connection.Disconnect()
		connection.Connected = false
		for i, e in self._handlers do
			if e == entry then
				table.remove(self._handlers, i)
				break
			end
		end
	end
	connection.disconnect = connection.Disconnect
	table.insert(self._handlers, entry)
	return connection
end

function Signal:Once(fn)
	local connection
	connection = self:Connect(function(...)
		connection.Disconnect()
		fn(...)
	end)
	return connection
end

function Signal:Wait()
	local thread = coroutine.running()
	self:Once(function(...)
		-- reanudar el hilo que espera con los argumentos del Fire
		local ok, err = coroutine.resume(thread, ...)
		if not ok then
			table.insert(self.errors, tostring(err))
		end
	end)
	return coroutine.yield()
end

function Signal:Fire(...)
	-- copia para tolerar Connect/Disconnect dentro de handlers
	local snapshot = table.clone(self._handlers)
	for _, entry in snapshot do
		if entry.connection.Connected then
			self:_run(entry.fn, ...)
		end
	end
end

function Signal:ConnectionCount(): number
	return #self._handlers
end

function Signal:DisconnectAll()
	for _, entry in table.clone(self._handlers) do
		entry.connection.Connected = false
	end
	self._handlers = {}
end

Signal.Destroy = Signal.DisconnectAll

return Signal
