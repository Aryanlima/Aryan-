--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundIds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundIds"))

local hasSoundService, soundService = pcall(function(): SoundService
	return game:GetService("SoundService")
end)
if not hasSoundService then
	return { play = function(_key: string) end }
end

local groups: { [string]: SoundGroup } = {}
for name, volume in { Music = 0.12, Ambience = 0.2, SFX = 0.65 } do
	local group = Instance.new("SoundGroup")
	group.Name = name
	group.Volume = volume
	group.Parent = soundService
	groups[name] = group
end

local function startLoop(key: string, groupName: string, volume: number)
	local soundId = SoundIds[key]
	if soundId == nil or soundId == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.Name = key
	sound.SoundId = soundId
	sound.Looped = true
	sound.Volume = volume
	sound.SoundGroup = groups[groupName]
	sound.Parent = soundService
	sound:Play()
end

startLoop("music", "Music", 1)
startLoop("ambience_nature", "Ambience", 0.7)
startLoop("ambience_crowd", "Ambience", 0.25)

local Audio = {}

function Audio.play(key: string)
	local soundId = SoundIds[key]
	if soundId == nil or soundId == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.Name = key
	sound.SoundId = soundId
	sound.SoundGroup = groups.SFX
	sound.Parent = soundService
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound:Play()
end

return Audio
