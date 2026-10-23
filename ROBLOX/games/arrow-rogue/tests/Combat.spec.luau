--!nonstrict
-- Logica pura de combate de Arrow Rogue.
local testkit = require("@testkit")
local Combat = require("../src/shared/Combat")
local Balance = require("../src/shared/Balance")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect

local noWalls = function()
	return false
end
local origin = { x = 0, z = 0 }

describe("Combat.pickTarget", function()
	it("elige el mas cercano y es determinista ante empates", function()
		local a = { id = 2, pos = { x = 5, z = 0 } }
		local b = { id = 1, pos = { x = 0, z = 5 } }
		local far = { id = 3, pos = { x = 20, z = 0 } }
		expect((Combat.pickTarget(origin, { a, b, far }, noWalls) :: any).id).toBe(1)
		expect((Combat.pickTarget(origin, { far, b, a }, noWalls) :: any).id).toBe(1)
	end)

	it("ignora enemigos tras una pared y devuelve nil si no hay ninguno", function()
		local near = { id = 1, pos = { x = 2, z = 0 } }
		local far = { id = 2, pos = { x = 9, z = 0 } }
		local walls = function(_, to)
			return to.x == 2
		end
		expect((Combat.pickTarget(origin, { near, far }, walls) :: any).id).toBe(2)
		expect(Combat.pickTarget(origin, { near }, walls)).toBeNil()
	end)
end)

describe("Combat.canFire", function()
	it("respeta el enfriamiento", function()
		local cd = Balance.bow.cooldown
		expect(Combat.canFire(0, cd - 0.01, cd)).toBe(false)
		expect(Combat.canFire(0, cd, cd)).toBe(true)
	end)
end)

describe("Combat.applyDamage", function()
	it("resta y nunca baja de 0 ni cura con dano negativo", function()
		expect(Combat.applyDamage(30, 10)).toBe(20)
		expect(Combat.applyDamage(5, 50)).toBe(0)
		expect(Combat.applyDamage(5, -10)).toBe(5)
	end)
end)

describe("Combat.isStanding", function()
	local th, sec = Balance.standing.speedThreshold, Balance.standing.standSeconds
	it("parado si la ventana esta cubierta y todas las muestras son lentas", function()
		local s = { { t = 0, speed = 0.1 }, { t = 0.06, speed = 0.2 }, { t = 0.13, speed = 0 } }
		expect(Combat.isStanding(s, th, sec)).toBe(true)
	end)
	it("no parado si hay una muestra rapida en la ventana o falta historial", function()
		local moving = { { t = 0, speed = 0 }, { t = 0.06, speed = 5 }, { t = 0.13, speed = 0 } }
		expect(Combat.isStanding(moving, th, sec)).toBe(false)
		expect(Combat.isStanding({ { t = 0, speed = 0 }, { t = 0.05, speed = 0 } }, th, sec)).toBe(false)
		expect(Combat.isStanding({}, th, sec)).toBe(false)
	end)
end)
