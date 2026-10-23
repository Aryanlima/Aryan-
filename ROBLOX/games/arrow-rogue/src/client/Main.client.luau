--!strict
-- Main (LocalScript) de Arrow Rogue: arranque vacio, sin jugabilidad todavia.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local _Balance = require(Shared:WaitForChild("Balance"))
