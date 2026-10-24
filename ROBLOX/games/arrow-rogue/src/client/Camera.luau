--!strict
-- Camera: camara fija alta 3/4 que sigue al personaje. Scriptable, BindToRenderStep, suavizado 1 - exp(-k*dt).
-- El movimiento sigue siendo el de Roblox (joystick/WASD/gamepad): como la camara tiene yaw fijo 0, "arriba" = -Z mundo.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local HEIGHT = 38 -- GDD: ~38 studs
local PITCH = math.rad(55) -- GDD: ~55 grados
local BACK = HEIGHT / math.tan(PITCH) -- distancia horizontal detras del objetivo
local K = 8 -- suavizado

local Camera = {}
local focus: Vector3? = nil
local shake = 0 -- amplitud en studs, la fija ArrowFx via addShake

function Camera.addShake(amount: number)
	shake = math.max(shake, amount)
end

function Camera.start()
	local camera = workspace.CurrentCamera :: Camera
	camera.CameraType = Enum.CameraType.Scriptable
	RunService:BindToRenderStep("ArrowRogueCamera", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local goal = root.Position
			focus = if focus then (focus :: Vector3):Lerp(goal, 1 - math.exp(-K * dt)) else goal
		end
		local f = focus
		if f == nil then
			return
		end
		-- ponytail: sin raycast; la camara esta por encima de las paredes (38 studs), nunca se bloquea.
		local eye = f + Vector3.new(0, HEIGHT, BACK)
		local offset = Vector3.zero
		if shake > 0.01 then
			offset = Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * 2 * shake
			shake *= math.exp(-12 * dt)
		else
			shake = 0
		end
		camera.CFrame = CFrame.lookAt(eye + offset, f + offset)
	end)
end

return Camera
