--!strict
-- Balance de Arrow Rogue: datos puros (sin logica ni requires). Todo el ajuste vive aqui.

export type Weapon = { damage: number, cooldown: number, projectileSpeed: number, range: number }
export type Enemy = { hp: number, speed: number, contactDamage: number }
export type Skill = { id: string, extraArrows: number, damageFactor: number }

local Balance = {
	hero = { maxHp = 100, moveSpeed = 16 },
	bow = { damage = 6, cooldown = 1.0, projectileSpeed = 80, range = 60 } :: Weapon,
	enemies = {
		chaser = { hp = 30, speed = 10, contactDamage = 3 } :: Enemy,
	},
	skills = {
		multishot = { id = "multishot", extraArrows = 2, damageFactor = 0.7 } :: Skill,
	},
	-- Dispara solo si el heroe esta parado: velocidad < speedThreshold (studs/s) durante standSeconds.
	standing = { speedThreshold = 0.5, standSeconds = 0.12 },
	projectiles = { maxPerPlayer = 24, radius = 1 },
	chaser = { radius = 2, windup = 0.6, attackRange = 4, recover = 2.8 },
	enemyLimit = 40,
	healOnClearFrac = 0.35, -- fraccion de vida maxima que se cura al limpiar cada sala
	xpPerKill = 4, -- XP por enemigo base; en jefes se multiplica por bossHpMul
	xpPerLevel = 40, -- XP para subir de nivel (se resta al subir)
	bossHpMul = { miniboss = 8, boss = 20 } :: { [string]: number }, -- multiplica la vida del chaser en jefes
	arena = { width = 80, depth = 80 },
}

return Balance
