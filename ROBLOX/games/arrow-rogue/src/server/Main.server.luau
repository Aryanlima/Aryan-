--!strict
-- Main (Script de servidor) de Arrow Rogue: arranque vacio, sin jugabilidad todavia.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local _Balance = require(Shared:WaitForChild("Balance"))
local Combat = require(Shared:WaitForChild("Combat"))
local Balance = require(Shared:WaitForChild("Balance"))
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local shot = ReplicatedStorage:FindFirstChild("Shot") or Instance.new("RemoteEvent")
shot.Name = "Shot"
shot.Parent = ReplicatedStorage
local enemiesFolder = Workspace:FindFirstChild("Enemies") or Instance.new("Folder")
enemiesFolder.Name = "Enemies"
enemiesFolder.Parent = Workspace
local EnemyService = require(script.Parent:WaitForChild("EnemyService"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local enemyService = EnemyService.new({
	Balance = Balance,
	createPart = function(name, pos)
		local part = Instance.new("Part")
		part.Name, part.Shape, part.Size, part.Anchored = name, Enum.PartType.Ball, Vector3.one * 4, true
		part.Position, part.Parent = pos, enemiesFolder
		return part
	end,
})
local combatService = CombatService.new({
	Combat = Combat,
	Balance = Balance,
	vector3 = Vector3,
	players = function()
		return Players:GetPlayers()
	end,
	enemies = enemyService.list,
	shot = shot,
	serverTime = function()
		return Workspace:GetServerTimeNow()
	end,
	wallBetween = function(from, to, character)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = if character then { character, enemiesFolder } else { enemiesFolder }
		return Workspace:Raycast(from, to - from, params) ~= nil
	end,
	enemyPosition = function(enemy)
		return enemy.part.Position
	end,
	killEnemy = function(enemy)
		enemyService.remove(enemy)
	end,
})
RunService.Heartbeat:Connect(function(dt)
	local now = Workspace:GetServerTimeNow()
	enemyService.step(dt, now, Players:GetPlayers())
	combatService.step(dt, now)
end)
