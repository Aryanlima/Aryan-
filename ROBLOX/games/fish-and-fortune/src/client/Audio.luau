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

-- Silencio desde el menu: Menus pone el atributo MuteMusic / MuteSFX en SoundService (sin DataStore: dura la sesion).
local function applyMute(name: string, attribute: string, also: string?)
	local volume = if soundService:GetAttribute(attribute) == true then 0 else GROUP_VOLUMES[name]
	groups[name].Volume = volume
	if also ~= nil then
		groups[also].Volume = if volume == 0 then 0 else GROUP_VOLUMES[also]
	end
end
soundService:GetAttributeChangedSignal("MuteMusic"):Connect(function()
	applyMute("Music", "MuteMusic", "Ambience")
end)
soundService:GetAttributeChangedSignal("MuteSFX"):Connect(function()
	applyMute("SFX", "MuteSFX")
end)

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
	sound.PlaybackSpeed = 0.96 + math.random() * 0.1 -- variacion minima: no suena igual dos veces
	sound.Parent = soundService
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound:Play()
end

return Audio
