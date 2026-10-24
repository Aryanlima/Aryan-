--!strict
-- ArrowFx: flechas visuales (pool de 24 Parts ancladas), numeros de dano, shake corto y destello blanco.
-- Solo dibuja lo que manda el servidor. Atributo ReducedMotion (LocalPlayer) apaga shake y destello.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Balance = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Balance"))
local Camera = require(script.Parent:WaitForChild("Camera"))
local Hud = require(script.Parent:WaitForChild("Hud"))

local MAX = 24
local PARKED = Vector3.new(0, -1000, 0)
local player = Players.LocalPlayer

type Arrow = { part: Part, origin: Vector3, dir: Vector3, speed: number, t0: number, life: number, alive: boolean }

local ArrowFx = {}

function ArrowFx.start(shot: RemoteEvent, damage: RemoteEvent)
	local folder = Instance.new("Folder")
	folder.Name = "ArrowFx"
	folder.Parent = workspace
	local pool: { Arrow } = {}
	for i = 1, MAX do
		local part = Instance.new("Part")
		part.Name = "Arrow"
		part.Size = Vector3.new(0.4, 0.4, 3)
		part.Color = Hud.theme.yellow
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
		part.CastShadow = false
		part.Position = PARKED
		part.Parent = folder
		pool[i] = { part = part, origin = Vector3.zero, dir = Vector3.zero, speed = 0, t0 = 0, life = 0, alive = false }
	end
	local nextSlot = 1

	shot.OnClientEvent:Connect(function(origin: any, direction: any, speed: any, _kind: any, t0: any)
		if
			typeof(origin) ~= "Vector3"
			or typeof(direction) ~= "Vector3"
			or type(speed) ~= "number"
			or type(t0) ~= "number"
		then
			return
		end
		if direction.Magnitude < 0.01 or speed <= 0 then
			return
		end
		-- libre primero; si todo esta ocupado se recicla el siguiente en orden (tope 24 vivas)
		local slot = pool[nextSlot]
		for _, a in pool do
			if not a.alive then
				slot = a
				break
			end
		end
		nextSlot = nextSlot % MAX + 1
		slot.origin, slot.dir, slot.speed, slot.t0 = origin, direction.Unit, speed, t0
		slot.life = Balance.bow.range / speed
		slot.alive = true
	end)

	RunService.RenderStepped:Connect(function()
		local now = workspace:GetServerTimeNow()
		for _, a in pool do
			if a.alive then
				local t = now - a.t0
				if t > a.life then
					a.alive = false
					a.part.Position = PARKED
				elseif t >= 0 then
					local p = a.origin + a.dir * (a.speed * t)
					a.part.CFrame = CFrame.lookAt(p, p + a.dir)
				end
			end
		end
	end)

	local flash = Hud.makeGui("HitFlash", 20)
	flash.IgnoreGuiInset = true
	local white = Instance.new("Frame")
	white.Size, white.BackgroundColor3, white.BackgroundTransparency = UDim2.fromScale(1, 1), Hud.theme.white, 1
	white.Active = false
	white.Parent = flash
	flash.Parent = player:WaitForChild("PlayerGui")

	damage.OnClientEvent:Connect(function(pos: any, amount: any, crit: any)
		if typeof(pos) ~= "Vector3" or type(amount) ~= "number" then
			return
		end
		local isCrit = crit == true
		-- numero flotante: BillboardGui sobre una Part anclada que Debris limpia
		local anchor = Instance.new("Part")
		anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
		anchor.Transparency, anchor.Size, anchor.Position = 1, Vector3.one, pos + Vector3.new(0, 3, 0)
		local bb = Instance.new("BillboardGui")
		bb.Size, bb.AlwaysOnTop = UDim2.fromOffset(120, 40), true
		bb.Adornee = anchor
		local l = Hud.label(
			bb,
			tostring(math.floor(amount)),
			if isCrit then 34 else 26,
			if isCrit then Hud.theme.yellow else Hud.theme.white
		)
		l.Size = UDim2.fromScale(1, 1)
		l.TextStrokeTransparency = 0.3
		bb.Parent = anchor
		anchor.Parent = folder
		TweenService:Create(anchor, TweenInfo.new(0.7), { Position = anchor.Position + Vector3.new(0, 4, 0) }):Play()
		TweenService
			:Create(l, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 })
			:Play()
		Debris:AddItem(anchor, 0.75)
		if player:GetAttribute("ReducedMotion") ~= true then
			Camera.addShake(if isCrit then 0.6 else 0.3)
			white.BackgroundTransparency = 0.8
			TweenService:Create(white, TweenInfo.new(0.12), { BackgroundTransparency = 1 }):Play()
		end
	end)
end

return ArrowFx
