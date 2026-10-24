--!strict
-- Skills: tabla de las 20 habilidades del GDD y funciones PURAS (sin motor): roll y apply.

export type Stats = { [string]: number }
export type Skill = { id: string, name: string, rarity: string, max: number, stat: string, add: number?, mul: number? }
export type Owned = { [string]: number }

local weights: { [string]: number } = { common = 70, rare = 25, epic = 5 }

local function s(id: string, name: string, rarity: string, max: number, stat: string, add: number?, mul: number?): Skill
	return { id = id, name = name, rarity = rarity, max = max, stat = stat, add = add, mul = mul }
end

local Skills = {}

-- mul = porcentaje por acumulacion (0.15 = +15 %); add = suma plana por acumulacion.
Skills.list = {
	s("s01", "Pulso Rapido", "common", 5, "fireRate", nil, 0.15),
	s("s02", "Punta Afilada", "common", 5, "damage", nil, 0.2),
	s("s03", "Corazon de Faro", "common", 5, "maxHp", nil, 0.2),
	s("s04", "Pies de Brisa", "common", 3, "moveSpeed", nil, 0.1),
	s("s05", "Disparo Doble", "rare", 2, "extraArrows", 1),
	s("s06", "Flecha Lateral", "rare", 1, "sideArrows", 1),
	s("s07", "Rebote", "rare", 3, "bounces", 1),
	s("s08", "Perforar", "rare", 3, "pierce", 1),
	s("s09", "Veneno de Alga", "common", 3, "poison", 1),
	s("s10", "Fuego Calido", "common", 1, "burn", 1),
	s("s11", "Escarcha", "common", 2, "slow", 0.2),
	s("s12", "Critico Claro", "common", 5, "crit", 0.1),
	s("s13", "Escudo de Niebla", "rare", 1, "shield", 1),
	s("s14", "Marea Vital", "common", 3, "healOnKill", 1),
	s("s15", "Estampida", "rare", 1, "haste", 1),
	s("s16", "Rafaga Final", "epic", 1, "volley", 1),
	s("s17", "Lluvia de Estrellas", "epic", 2, "meteor", 1),
	s("s18", "Segundo Aliento", "epic", 1, "revive", 1),
	s("s19", "Ojo del Faro", "rare", 1, "bossDamage", 0.3),
	s("s20", "Iman de Brillo", "common", 1, "magnet", 1),
} :: { Skill }

local byId: { [string]: Skill } = {}
for _, skill in Skills.list do
	byId[skill.id] = skill
end

function Skills.get(id: string): Skill?
	return byId[id]
end

function Skills.canStack(owned: Owned, id: string): boolean
	local skill = byId[id]
	return skill ~= nil and (owned[id] or 0) < skill.max
end

-- Sorteo determinista por semilla (LCG), `count` ids distintos ponderados por rareza.
function Skills.roll(seed: number, owned: Owned, count: number): { string }
	local state = seed % 4294967296
	local pool: { Skill } = {}
	for _, skill in Skills.list do
		if Skills.canStack(owned, skill.id) then
			table.insert(pool, skill)
		end
	end
	local picks: { string } = {}
	while #picks < count and #pool > 0 do
		local total = 0
		for _, skill in pool do
			total += weights[skill.rarity]
		end
		state = (state * 1664525 + 1013904223) % 4294967296
		local r = state / 4294967296 * total
		for i, skill in pool do
			r -= weights[skill.rarity]
			if r < 0 or i == #pool then
				table.insert(picks, skill.id)
				table.remove(pool, i)
				break
			end
		end
	end
	return picks
end

-- Stats finales = base + efectos acumulados (add antes de mul). Total de flechas <= 5 (GDD s05+s06).
-- ponytail: s09/s10 "gana la ultima" no se resuelve aqui; el consumidor decide con el orden de eleccion.
function Skills.apply(base: Stats, owned: Owned): Stats
	local out: Stats = table.clone(base)
	for _, skill in Skills.list do
		local n = owned[skill.id] or 0
		if n > 0 then
			local v = (out[skill.stat] or 0) + (skill.add or 0) * n
			out[skill.stat] = if skill.mul then v * (1 + skill.mul * n) else v
		end
	end
	local extra = (out.extraArrows or 0) + (out.sideArrows or 0)
	if extra > 4 then
		out.extraArrows = math.max(0, 4 - (out.sideArrows or 0))
	end
	return out
end

return Skills
