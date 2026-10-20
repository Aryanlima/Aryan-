--!nonstrict
--[[
	Clock: reloj controlable y simulacion de la libreria `task` de Roblox.

	Idea: el codigo bajo prueba recibe `clock.task` (o `clock.task.wait`, etc.) por
	inyeccion de dependencias en vez de usar el global `task`. El test decide
	cuando pasa el tiempo con `clock:advance(segundos)`; nunca se espera de verdad.

	Semantica (resumen):
	  * `clock.task.spawn(fnOThread, ...)`  corre YA, en un hilo gestionado por el reloj.
	  * `clock.task.defer(fnOThread, ...)`  corre en el siguiente `advance`/`flush` (tiempo actual).
	  * `clock.task.delay(dt, fn, ...)`     corre cuando el reloj alcanza now + dt.
	  * `clock.task.wait(dt)`:
	      - dentro de un hilo gestionado (spawn/defer/delay): cede el hilo y lo reanuda el reloj.
	      - fuera (p. ej. el cuerpo del test): AVANZA el reloj `dt` segundos (el test "es" el
	        que hace pasar el tiempo) y devuelve `dt`.
	    `wait(0)` o `wait()` equivalen a un frame (1/60 s), como en Roblox, para evitar bucles infinitos.
	  * `clock.task.cancel(hilo)` cancela un hilo/temporizador pendiente.

	Los errores dentro de hilos gestionados no se propagan (igual que en Roblox):
	se acumulan en `clock.errors`. Usa `clock:assertNoErrors()` en los tests.
]]

local FRAME = 1 / 60
local MAX_STEPS = 1000000

local Clock = {}
Clock.__index = Clock

export type Clock = typeof(setmetatable({} :: any, Clock))

function Clock.new(options: { startTime: number?, epoch: number? }?)
	local opts = options or {}
	local self = setmetatable({}, Clock)
	self._now = opts.startTime or 0
	self._epoch = opts.epoch or 1700000000 -- instante "real" simulado (segundos unix) en now = 0
	self._timers = {} -- { {time=, seq=, thread=, args=} } sin ordenar; se busca el minimo
	self._seq = 0
	self._managed = setmetatable({}, { __mode = "k" })
	self.errors = {}

	local function spawnThread(target, ...)
		local thread
		if type(target) == "thread" then
			thread = target
		else
			thread = coroutine.create(target)
		end
		self._managed[thread] = true
		self:_resume(thread, ...)
		return thread
	end

	self.task = {
		spawn = spawnThread,
		defer = function(target: any, ...)
			local thread: thread = if type(target) == "thread" then target else coroutine.create(target)
			self._managed[thread] = true
			self:_schedule(self._now, thread, { ... })
			return thread
		end,
		delay = function(dt: number?, target: any, ...)
			local thread: thread = if type(target) == "thread" then target else coroutine.create(target)
			self._managed[thread] = true
			self:_schedule(self._now + math.max(dt or 0, 0), thread, { ... })
			return thread
		end,
		wait = function(dt)
			dt = math.max(dt or FRAME, FRAME)
			local running = coroutine.running()
			if self._managed[running] and coroutine.isyieldable() then
				local started = self._now
				self:_schedule(started + dt, running, nil)
				coroutine.yield()
				return self._now - started
			end
			-- Hilo no gestionado (el test): hacer pasar el tiempo.
			self:advance(dt)
			return dt
		end,
		cancel = function(thread)
			self:_cancel(thread)
		end,
	}

	-- Funciones de tiempo estilo Roblox, inyectables.
	self.time = function()
		return self._now
	end
	self.tick = function()
		return self._epoch + self._now
	end
	self.osTime = function()
		return math.floor(self._epoch + self._now)
	end
	self.clock = self.time

	return self
end

function Clock:now(): number
	return self._now
end

function Clock:_schedule(time: number, thread: thread, args: { any }?)
	self._seq += 1
	table.insert(self._timers, { time = time, seq = self._seq, thread = thread, args = args })
end

function Clock:_cancel(thread: thread)
	for i = #self._timers, 1, -1 do
		if self._timers[i].thread == thread then
			table.remove(self._timers, i)
		end
	end
	if coroutine.status(thread) == "suspended" then
		pcall(coroutine.close, thread)
	end
end

function Clock:_resume(thread: thread, ...)
	local ok, err = coroutine.resume(thread, ...)
	if not ok then
		table.insert(self.errors, tostring(err))
	end
end

function Clock:_nextTimerIndex(limit: number?): number?
	local best: number? = nil
	for i, timer in self._timers do
		if limit == nil or timer.time <= limit then
			if best == nil then
				best = i
			else
				local b = self._timers[best]
				if timer.time < b.time or (timer.time == b.time and timer.seq < b.seq) then
					best = i
				end
			end
		end
	end
	return best
end

-- Numero de temporizadores/hilos pendientes.
function Clock:pending(): number
	return #self._timers
end

-- Tiempo del proximo temporizador (o nil si no hay).
function Clock:nextTime(): number?
	local i = self:_nextTimerIndex(nil)
	return i and self._timers[i].time or nil
end

-- Avanza `dt` segundos de tiempo simulado, ejecutando en orden todo lo que venza.
function Clock:advance(dt: number)
	assert(type(dt) == "number" and dt >= 0, "Clock:advance(dt) requiere dt >= 0")
	local target = self._now + dt
	local steps = 0
	while true do
		local index = self:_nextTimerIndex(target)
		if index == nil then
			break
		end
		steps += 1
		if steps > MAX_STEPS then
			error("Clock: demasiados temporizadores en un solo advance (bucle infinito?)", 2)
		end
		local timer = table.remove(self._timers, index)
		if timer.time > self._now then
			self._now = timer.time
		end
		local args = timer.args
		if args == nil then
			-- reanudacion de task.wait: no se pasan argumentos (wait lee el reloj)
			self:_resume(timer.thread)
		else
			self:_resume(timer.thread, table.unpack(args))
		end
	end
	self._now = target
end

-- Ejecuta lo que ya vencio sin avanzar el tiempo (util tras task.defer).
function Clock:flush()
	self:advance(0)
end

-- Avanza hasta que no queden temporizadores. `maxSeconds` limita el avance (por defecto 1e9).
function Clock:runAll(maxSeconds: number?)
	local limit = self._now + (maxSeconds or 1e9)
	local steps = 0
	while true do
		local nextTime = self:nextTime()
		if nextTime == nil or nextTime > limit then
			break
		end
		steps += 1
		if steps > MAX_STEPS then
			error("Clock:runAll: demasiados pasos (bucle infinito?)", 2)
		end
		self:advance(math.max(nextTime - self._now, 0))
	end
end

function Clock:assertNoErrors()
	if #self.errors > 0 then
		local joined = table.concat(self.errors, "\n---\n")
		self.errors = {}
		error("Errores en hilos del reloj (task.spawn/delay/defer):\n" .. joined, 2)
	end
end

return Clock
