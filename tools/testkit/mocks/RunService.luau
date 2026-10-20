--!nonstrict
--[[
	RunService (mock): eventos por frame controlados a mano.

	  local run = RunService.new({ clock = clock, isServer = true })
	  run.Heartbeat:Connect(function(dt) ... end)
	  run:Step(1 / 60)        -- dispara Stepped/PreSimulation, Heartbeat/PostSimulation y avanza el reloj
	  run:RunFor(2, 1 / 30)   -- 2 s simulados en pasos de 1/30

	IsServer/IsClient/IsStudio/IsRunning/IsRunMode/IsEdit configurables por opciones.
]]

local Signal = require("./Signal")

local RunService = {}
RunService.__index = RunService

--[[
	options: clock, isServer (true), isStudio (false), isRunning (true)
]]
function RunService.new(options)
	local opts = options or {}
	local self = setmetatable({}, RunService)
	local spawn = opts.clock and opts.clock.task.spawn or nil
	self._clock = opts.clock
	self._isServer = opts.isServer ~= false
	self._isStudio = opts.isStudio == true
	self._isRunning = opts.isRunning ~= false
	self._elapsed = 0
	for _, name in { "Heartbeat", "Stepped", "PreSimulation", "PostSimulation", "RenderStepped", "PreRender", "PreAnimation" } do
		self[name] = Signal.new({ spawn = spawn })
	end
	return self
end

function RunService:IsServer()
	return self._isServer
end

function RunService:IsClient()
	return not self._isServer
end

function RunService:IsStudio()
	return self._isStudio
end

function RunService:IsRunning()
	return self._isRunning
end

function RunService:IsRunMode()
	return self._isStudio and self._isRunning
end

function RunService:IsEdit()
	return self._isStudio and not self._isRunning
end

function RunService:Step(dt: number?)
	local delta = dt or (1 / 60)
	self._elapsed += delta
	if not self._isServer then
		self.PreRender:Fire(delta)
		self.RenderStepped:Fire(delta)
	end
	self.Stepped:Fire(self._elapsed, delta)
	self.PreSimulation:Fire(delta)
	self.PostSimulation:Fire(delta)
	self.Heartbeat:Fire(delta)
	if self._clock then
		self._clock:advance(delta)
	end
end

function RunService:RunFor(seconds: number, dt: number?)
	local delta = dt or (1 / 60)
	local remaining = seconds
	while remaining > 1e-9 do
		local step = math.min(delta, remaining)
		self:Step(step)
		remaining -= step
	end
end

return RunService
