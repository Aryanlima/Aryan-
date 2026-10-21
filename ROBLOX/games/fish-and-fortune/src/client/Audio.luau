--!strict

local SoundIds: { [string]: string } = {} -- los pasa Main con Audio.init (solo Main requiere modulos por instancia)

local hasSoundService, soundService = pcall(function(): SoundService
	return game:GetService("SoundService")
end)
if not hasSoundService then
	return { play = function(_key: string) end, init = function(_ids: { [string]: string }) end }
end

local groups: { [string]: SoundGroup } = {}
local GROUP_VOLUMES: { [string]: number } = { Music = 0.12, Ambience = 0.2, SFX = 0.65 }
for name, volume in GROUP_VOLUMES do
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

local Audio = {}

function Audio.init(ids: { [string]: string })
	SoundIds = ids
	startLoop("music", "Music", 1)
	startLoop("ambience_nature", "Ambience", 0.7)
	startLoop("ambience_crowd", "Ambience", 0.25)
end

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
