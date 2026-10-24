--!strict
-- Main (LocalScript) de Arrow Rogue: arranca camara, HUD, tarjetas de skill y efectos. El cliente solo dibuja y manda intencion
-- (SkillPick con el indice 1..3, Ready); nunca dano, blancos ni cadencia.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hud = require(script.Parent:WaitForChild("Hud"))
local Camera = require(script.Parent:WaitForChild("Camera"))
local SkillCards = require(script.Parent:WaitForChild("SkillCards"))
local ArrowFx = require(script.Parent:WaitForChild("ArrowFx"))

local function remote(name: string): RemoteEvent
	return ReplicatedStorage:WaitForChild(name) :: RemoteEvent
end

Camera.start()
Hud.start()
-- Cada remoto se espera en su propio hilo: si el servidor aun no crea uno, no bloquea al resto.
task.spawn(function()
	ArrowFx.start(remote("Shot"), remote("DamageNumber"))
end)
task.spawn(function()
	SkillCards.start(remote("SkillOffer"), remote("SkillPick"))
end)
task.spawn(function()
	local ready, result = remote("Ready"), remote("RunResult")
	result.OnClientEvent:Connect(function(victory: any, reward: any)
		Hud.showResult(victory == true, if type(reward) == "number" then reward else 0, ready)
	end)
end)
