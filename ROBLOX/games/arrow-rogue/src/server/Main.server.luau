--!strict
-- Main (Script de servidor) de Arrow Rogue: remotos, RunDirector y bucle Heartbeat.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Balance = require(Shared:WaitForChild("Balance"))
local Chapter = require(Shared:WaitForChild("Chapter"))
local Combat = require(Shared:WaitForChild("Combat"))
local Skills = require(Shared:WaitForChild("Skills"))
local EnemyService = require(script.Parent:WaitForChild("EnemyService"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local SkillService = require(script.Parent:WaitForChild("SkillService"))

-- Remotos (GDD s6). Salida: Shot, SkillOffer, RoomState, RunResult, DamageNumber. Entrada: SkillPick, Ready.
local function remote(name: string): RemoteEvent
	local r = ReplicatedStorage:FindFirstChild(name) or Instance.new("RemoteEvent")
	r.Name, r.Parent = name, ReplicatedStorage
	return r :: RemoteEvent
end
local shot, skillOffer, roomState = remote("Shot"), remote("SkillOffer"), remote("RoomState")
local runResult, damageNumber = remote("RunResult"), remote("DamageNumber")
local skillPick, ready = remote("SkillPick"), remote("Ready")

-- Rate limit por jugador y remoto de entrada (intervalo minimo en segundos).
local lastIn: { [string]: { [Player]: number } } = { SkillPick = {}, Ready = {} }
local function allow(name: string, player: Player, minInterval: number): boolean
	local now, t = os.clock(), lastIn[name]
	if now - (t[player] or -math.huge) < minInterval then
		return false
	end
	t[player] = now
	return true
end

local enemiesFolder = Workspace:FindFirstChild("Enemies") or Instance.new("Folder")
enemiesFolder.Name, enemiesFolder.Parent = "Enemies", Workspace

-- Hub: suelo y spawn para el menu Ready y las reapariciones (sin esto el personaje cae al vacio).
if not Workspace:FindFirstChild("HubFloor") then
	local hub = Instance.new("Part")
	hub.Name, hub.Anchored, hub.Size, hub.Position = "HubFloor", true, Vector3.new(60, 1, 60), Vector3.new(0, -0.5, 0)
	hub.Parent = Workspace
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored, spawn.Neutral, spawn.Size, spawn.Position = true, true, Vector3.new(6, 1, 6), Vector3.new(0, 0.5, 0)
	spawn.Parent = Workspace
end

local enemyService = EnemyService.new({
	Balance = Balance,
	createPart = function(name, pos)
		local part = Instance.new("Part")
		part.Name, part.Shape, part.Size, part.Anchored = name, Enum.PartType.Ball, Vector3.one * 4, true
		part.Position, part.Parent = pos, enemiesFolder
		return part
	end,
})

-- Copia de Balance que lee CombatService; los stats de Skills.apply se escriben aqui.
local combatBalance = table.clone(Balance)
combatBalance.bow = table.clone(Balance.bow)

local combatService = CombatService.new({
	Combat = Combat,
	Balance = combatBalance,
	vector3 = Vector3,
	players = function()
		return Players:GetPlayers()
	end,
	enemies = enemyService.list,
	shot = shot,
	serverTime = function()
		return Workspace:GetServerTimeNow()
	end,
	wallBetween = function(from: Vector3, to: Vector3, character: Model?)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = if character then { character, enemiesFolder } else { enemiesFolder }
		return Workspace:Raycast(from, to - from, params) ~= nil
	end,
	enemyPosition = function(enemy)
		return enemy.part.Position
	end,
	damaged = function(enemy, amount, owner)
		damageNumber:FireClient(owner, enemy.part.Position, amount)
	end,
	killEnemy = function(enemy)
		enemyService.remove(enemy)
	end,
})

-- RunDirector inline. ponytail: una run activa a la vez; multi-run pide un EnemyService por run.
type Run = {
	player: Player,
	state: Chapter.State,
	seed: number,
	room: Chapter.Room?,
	pending: { Chapter.Wave },
	roomStart: number,
	nextAt: number?,
	gold: number,
	xp: number,
	levelXp: number,
	level: number,
	owedLevels: number,
	offerOpen: boolean,
	ended: boolean,
	arena: Instance?,
	died: RBXScriptConnection?,
}
local ORIGIN = Vector3.new(0, 0, 2000) -- lejos del hub
local active: Run? = nil
local hitDone: { [any]: boolean } = {}

local skillService = SkillService.new({
	Skills = Skills,
	offer = skillOffer,
	now = os.clock,
	minInterval = 0.2,
	seed = function(_, level)
		return (if active then active.seed else 0) * 31 + level
	end,
})

local function humanoidOf(player: Player): Humanoid?
	return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end

-- Atributos que lee el cliente (Hud): vida desde el Humanoid de cada personaje.
local function bindHp(player: Player, character: Model)
	local hum = character:WaitForChild("Humanoid") :: Humanoid
	local function sync()
		player:SetAttribute("Hp", hum.Health)
		player:SetAttribute("MaxHp", hum.MaxHealth)
	end
	hum.HealthChanged:Connect(sync)
	hum:GetPropertyChangedSignal("MaxHealth"):Connect(sync)
	sync()
end
local function watchHp(player: Player)
	player.CharacterAdded:Connect(function(character)
		task.spawn(bindHp, player, character)
	end)
	if player.Character then
		task.spawn(bindHp, player, player.Character)
	end
end
Players.PlayerAdded:Connect(watchHp)
for _, player in Players:GetPlayers() do
	watchHp(player)
end

local function syncXp(run: Run)
	run.player:SetAttribute("Xp", run.levelXp)
	run.player:SetAttribute("XpNext", Balance.xpPerLevel)
	run.player:SetAttribute("Level", run.level)
end

local function applyStats(run: Run)
	local stats = Skills.apply(
		{ damage = Balance.bow.damage, fireRate = 1, maxHp = Balance.hero.maxHp, moveSpeed = Balance.hero.moveSpeed },
		skillService.owned(run.player)
	)
	combatBalance.bow.damage = stats.damage
	combatBalance.bow.cooldown = Balance.bow.cooldown / stats.fireRate
	local hum = humanoidOf(run.player)
	if hum then
		local gain = stats.maxHp - hum.MaxHealth
		hum.MaxHealth, hum.WalkSpeed = stats.maxHp, stats.moveSpeed
		if gain > 0 then
			hum.Health += gain
		end
	end
end

local function endRun(run: Run, result: string)
	if run.ended then
		return -- una sola vez: sin recompensa duplicada
	end
	run.ended = true
	if run.died then
		run.died:Disconnect()
	end
	-- REVIEW(money): derrota paga 50 %; nada persiste aun. Si se guarda, liquidar idempotente por run.
	local gold = if result == "win" then run.gold else run.gold // 2
	enemyService.clear()
	table.clear(hitDone)
	if run.arena then
		run.arena:Destroy()
	end
	table.clear(skillService.owned(run.player))
	runResult:FireClient(run.player, result == "win", gold)
	task.delay(3, function() -- vuelta al hub; `active` sigue ocupado hasta aqui
		if run.player.Parent then
			run.player:LoadCharacterAsync()
		end
		combatBalance.bow.damage, combatBalance.bow.cooldown = Balance.bow.damage, Balance.bow.cooldown
		active = nil
	end)
end

local function enterRoom(run: Run, now: number)
	local room = Chapter.nextRoom(run.state)
	if not room then
		return endRun(run, "win")
	end
	run.room, run.pending, run.roomStart = room, table.clone(room.waves), now
	run.player:SetAttribute("Room", room.index)
	run.player:SetAttribute("RoomTotal", #run.state.rooms)
	if run.arena then
		run.arena:Destroy()
	end
	local kindFolder = ServerStorage:FindFirstChild("Rooms") and ServerStorage.Rooms:FindFirstChild(room.kind)
	local template = kindFolder and kindFolder:FindFirstChild(room.template)
	local arena: Instance
	if template and template:IsA("Model") then
		local model = template:Clone()
		model:PivotTo(CFrame.new(ORIGIN))
		arena = model
	else -- placeholder; el arte real llega luego desde Workspace.Extras.Kit
		local floor = Instance.new("Part")
		floor.Name, floor.Anchored = "Floor", true
		floor.Size = Vector3.new(Balance.arena.width, 1, Balance.arena.depth)
		floor.Position = ORIGIN - Vector3.new(0, 0.5, 0)
		arena = floor
	end
	arena.Parent, run.arena = Workspace, arena
	local character = run.player.Character
	local alive = humanoidOf(run.player)
	if character and alive and alive.Health > 0 then
		character:PivotTo(CFrame.new(ORIGIN + Vector3.new(0, 4, 0)))
	end
	local hum = humanoidOf(run.player)
	if room.kind == "rest" and hum then
		hum.Health = hum.MaxHealth
	end
	roomState:FireClient(run.player, room.index, room.kind, "start")
end

local function spawnWave(run: Run, room: Chapter.Room, wave: Chapter.Wave)
	local rng = Random.new(run.seed + room.index * 100 + wave.delay)
	local r = math.min(Balance.arena.width, Balance.arena.depth) * 0.4
	local mul = Balance.bossHpMul[room.kind] or 1
	for _ = 1, wave.count do
		local a = rng:NextNumber(0, math.pi * 2)
		local enemy = enemyService.spawn(nil, ORIGIN + Vector3.new(math.cos(a) * r, 2, math.sin(a) * r))
		if enemy then
			enemy.hp *= mul
		end
	end
end

local function finishRoom(run: Run, room: Chapter.Room, now: number)
	local reward = Chapter.reward(room.kind, room.index) -- REVIEW(money): oro/xp, aun sin persistir
	run.gold += reward.gold
	run.xp += reward.xp
	run.levelXp += reward.xp
	while run.levelXp >= Balance.xpPerLevel do
		run.levelXp -= Balance.xpPerLevel
		run.level += 1
		run.owedLevels += 1
	end
	syncXp(run)
	if run.owedLevels > 0 and not run.offerOpen then
		run.owedLevels -= 1
		run.offerOpen = true
		skillService.levelUp(run.player)
	end
	roomState:FireClient(run.player, room.index, room.kind, "cleared")
	if room.kind == "boss" then
		return endRun(run, "win")
	end
	run.room, run.nextAt = nil, now + 2
end

ready.OnServerEvent:Connect(function(player: Player)
	if not allow("Ready", player, 1) or active then
		return
	end
	local hum = humanoidOf(player)
	if not hum or hum.Health <= 0 then
		return
	end
	local seed = os.time() + player.UserId % 1000
	local run: Run = {
		player = player,
		state = Chapter.start(seed),
		seed = seed,
		pending = {},
		roomStart = 0,
		gold = 0,
		xp = 0,
		levelXp = 0,
		level = 1,
		owedLevels = 0,
		offerOpen = false,
		ended = false,
	}
	active = run
	run.died = hum.Died:Connect(function()
		endRun(run, "lose")
	end)
	applyStats(run)
	syncXp(run)
	enterRoom(run, Workspace:GetServerTimeNow())
end)

skillPick.OnServerEvent:Connect(function(player: Player, index: unknown)
	if not allow("SkillPick", player, 0.2) then
		return
	end
	local run = active
	if not run or run.player ~= player or run.ended or not run.offerOpen then
		return
	end
	if typeof(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > 3 then
		return
	end
	if skillService.pick(player, index) then
		run.offerOpen = false
		applyStats(run)
		if run.owedLevels > 0 then
			run.owedLevels -= 1
			run.offerOpen = true
			skillService.levelUp(player)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	for _, t in lastIn do
		t[player] = nil
	end
	if active and active.player == player then
		endRun(active, "lose")
	end
end)

RunService.Heartbeat:Connect(function(dt)
	local now = Workspace:GetServerTimeNow()
	enemyService.step(dt, now, Players:GetPlayers())
	combatService.step(dt, now)
	local run = active
	if not run or run.ended then
		return
	end
	local hum = humanoidOf(run.player)
	local root = run.player.Character and run.player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	for _, enemy in enemyService.list() do
		-- dano de contacto: una vez por ataque y solo en rango (el servidor decide)
		if enemy.state == "Attack" and not hitDone[enemy] then
			hitDone[enemy] = true
			if hum and root and (root.Position - enemy.part.Position).Magnitude <= Balance.chaser.attackRange + 2 then
				hum:TakeDamage(Balance.enemies.chaser.contactDamage)
			end
		elseif enemy.state ~= "Attack" then
			hitDone[enemy] = nil
		end
	end
	if run.nextAt then
		if now >= run.nextAt then
			run.nextAt = nil
			enterRoom(run, now)
		end
		return
	end
	local room = run.room
	if not room then
		return
	end
	for i = #run.pending, 1, -1 do
		local wave = run.pending[i]
		if now >= run.roomStart + wave.delay then
			table.remove(run.pending, i)
			spawnWave(run, room, wave)
		end
	end
	if Chapter.isCleared(#enemyService.list(), #run.pending) then
		finishRoom(run, room, now)
	end
end)
