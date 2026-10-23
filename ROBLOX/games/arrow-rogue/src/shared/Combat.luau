--!strict
-- Combat: funciones PURAS (sin motor) del disparo automatico "parar para disparar".

export type Vec = { x: number, z: number }
export type Enemy = { id: number, pos: Vec }
export type WallsFn = (from: Vec, to: Vec) -> boolean -- true si hay pared entre ambos

local Combat = {}

local function dist2(a: Vec, b: Vec): number
	local dx, dz = a.x - b.x, a.z - b.z
	return dx * dx + dz * dz
end

-- Enemigo mas cercano con linea de vista; empate -> menor id (determinista).
function Combat.pickTarget(playerPos: Vec, enemies: { Enemy }, wallsFn: WallsFn): Enemy?
	local best: Enemy? = nil
	local bestD = math.huge
	for _, e in enemies do
		if not wallsFn(playerPos, e.pos) then
			local d = dist2(playerPos, e.pos)
			if best == nil or d < bestD or (d == bestD and e.id < best.id) then
				best, bestD = e, d
			end
		end
	end
	return best
end

function Combat.canFire(lastShotAt: number, now: number, cooldown: number): boolean
	return now - lastShotAt >= cooldown
end

function Combat.applyDamage(hp: number, dmg: number): number
	return math.max(0, hp - math.max(0, dmg))
end

-- speedSamples: { {t = segundos, speed = studs/s} } en orden. Parado = todas las muestras de la
-- ultima ventana `seconds` bajo `threshold` y la ventana esta cubierta por las muestras.
function Combat.isStanding(speedSamples: { { t: number, speed: number } }, threshold: number, seconds: number): boolean
	local n = #speedSamples
	if n == 0 then
		return false
	end
	local now = speedSamples[n].t
	if now - speedSamples[1].t < seconds then
		return false
	end
	for i = n, 1, -1 do
		local s = speedSamples[i]
		if s.speed >= threshold then
			return false
		end
		if now - s.t >= seconds then
			break
		end
	end
	return true
end

return Combat
