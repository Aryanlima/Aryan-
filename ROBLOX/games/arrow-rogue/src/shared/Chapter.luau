--!strict
-- Chapter: flujo PURO (sin motor) del capitulo de 10 salas segun el GDD seccion 3.
-- Combate x6 (1-6), altar (7), mini-jefe (8), descanso (9), jefe final (10).
local Balance = require("./Balance")

export type Kind = "combat" | "altar" | "miniboss" | "rest" | "boss"
export type Wave = { enemyId: string, count: number, delay: number }
export type Room = { index: number, kind: Kind, template: string, waves: { Wave } }
export type State = { index: number, rooms: { Room } }
export type Reward = { gold: number, xp: number }

local Chapter = {}

local KINDS: { Kind } =
	{ "combat", "combat", "combat", "combat", "combat", "combat", "altar", "miniboss", "rest", "boss" }
local TEMPLATES: { [Kind]: { string } } = {
	combat = { "arena_a", "arena_b", "arena_c" },
	altar = { "altar_a", "altar_b" },
	miniboss = { "b1_arena", "b1_arena_alt" },
	rest = { "camp_a", "camp_b" },
	boss = { "b2_arena", "b2_arena_alt" },
}
local ENEMIES = { "e1", "e2", "e3", "e4", "e5", "e6" } -- ids del GDD
local BOSS_WAVES: { [Kind]: { Wave } } = {
	miniboss = { { enemyId = "b1", count = 1, delay = 0 } },
	boss = { { enemyId = "b2", count = 1, delay = 0 } },
}
-- GDD: <= 24 vivos por sala; Balance.enemyLimit tambien manda.
local CAP = math.min(Balance.enemyLimit, 24)

-- LCG determinista (misma semilla -> mismo plan, en cualquier motor).
local function rng(seed: number): (number) -> number
	local s = seed % 2147483647
	if s <= 0 then
		s += 2147483646
	end
	return function(n: number): number
		s = (s * 48271) % 2147483647
		return s % n + 1
	end
end

function Chapter.plan(seed: number): { Room }
	local roll = rng(seed)
	local rooms: { Room } = {}
	local last: string = ""
	for i, k in KINDS do
		local kind: Kind = k :: any
		local list = TEMPLATES[kind]
		local t = list[roll(#list)]
		if t == last then -- nunca la misma plantilla dos veces seguidas
			t = list[(table.find(list, t) :: number) % #list + 1]
		end
		last = t
		local waves: { Wave } = {}
		if kind == "combat" then
			local budget = math.min(CAP, 4 + i * 2) -- dificultad sube con la sala
			local nWaves = 2 + i // 3
			for w = 1, nWaves do
				local count = math.min(budget // nWaves, 3 + i)
				table.insert(
					waves,
					{ enemyId = ENEMIES[roll(math.min(#ENEMIES, 1 + i))], count = count, delay = (w - 1) * 4 }
				)
			end
		elseif BOSS_WAVES[kind] then
			waves = table.clone(BOSS_WAVES[kind])
		end
		table.insert(rooms, { index = i, kind = kind, template = t, waves = waves })
	end
	return rooms
end

function Chapter.start(seed: number): State
	return { index = 0, rooms = Chapter.plan(seed) }
end

-- Avanza y devuelve la siguiente sala (nil al terminar el capitulo).
function Chapter.nextRoom(state: State): Room?
	local nxt = state.rooms[state.index + 1]
	if nxt then
		state.index += 1
	end
	return nxt
end

function Chapter.isCleared(aliveCount: number, wavesRemaining: number): boolean
	return aliveCount <= 0 and wavesRemaining <= 0
end

-- Solo monedas del juego y XP; nada de pago. REVIEW(money) al conectarlo a datos.
function Chapter.reward(roomKind: Kind, roomIndex: number): Reward
	if roomKind == "boss" then
		return { gold = 150, xp = 100 }
	elseif roomKind == "miniboss" then
		return { gold = 60, xp = 50 }
	elseif roomKind == "combat" then
		return { gold = 10 + roomIndex * 3, xp = 8 + roomIndex * 2 }
	end
	return { gold = 0, xp = 0 }
end

return Chapter
