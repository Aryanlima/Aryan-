--!strict
-- Balance de Arrow Rogue: datos puros (sin logica ni requires). Todo el ajuste vive aqui.

export type Weapon = { damage: number, cooldown: number, projectileSpeed: number, range: number }
export type Enemy = { hp: number, speed: number, contactDamage: number }
export type Skill = { id: string, extraArrows: number, damageFactor: number }

local Balance = {
	hero = { maxHp = 100, moveSpeed = 16 },
	bow = { damage = 10, cooldown = 0.6, projectileSpeed = 80, range = 60 } :: Weapon,
	enemies = {
		chaser = { hp = 30, speed = 10, contactDamage = 10 } :: Enemy,
	},
	skills = {
		multishot = { id = "multishot", extraArrows = 2, damageFactor = 0.7 } :: Skill,
	},
	-- Dispara solo si el heroe esta parado: velocidad < speedThreshold (studs/s) durante standSeconds.
	standing = { speedThreshold = 0.5, standSeconds = 0.12 },
	arena = { width = 80, depth = 80 },
}

return Balance
