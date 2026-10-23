--!strict
-- Main (Script de servidor) de Arrow Rogue: arranque vacio, sin jugabilidad todavia.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local _Balance = require(Shared:WaitForChild("Balance"))
local _Combat = require(Shared:WaitForChild("Combat"))
