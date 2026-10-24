--!nonstrict
-- Flujo puro del capitulo de Arrow Rogue.
local testkit = require("@testkit")
local Chapter = require("../src/shared/Chapter")
local Balance = require("../src/shared/Balance")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect

describe("Chapter.plan", function()
	it("misma semilla, mismo plan; 10 salas; jefe al final", function()
		local a, b = Chapter.plan(42), Chapter.plan(42)
		expect(#a).toBe(10)
		for i = 1, 10 do
			expect(a[i].template).toBe(b[i].template)
			expect(#a[i].waves).toBe(#b[i].waves)
		end
		expect(a[10].kind).toBe("boss")
		expect(a[8].kind).toBe("miniboss")
	end)

	it("nunca repite plantilla seguida y las oleadas respetan el tope", function()
		for seed = 1, 200 do
			local rooms = Chapter.plan(seed)
			for i, r in rooms do
				if i > 1 then
					expect(r.template == rooms[i - 1].template).toBe(false)
				end
				local total = 0
				for _, w in r.waves do
					total += w.count
				end
				expect(total <= Balance.enemyLimit and total <= 24).toBe(true)
			end
		end
	end)
end)

describe("Chapter flow", function()
	it("isCleared exige 0 vivos y 0 oleadas", function()
		expect(Chapter.isCleared(0, 0)).toBe(true)
		expect(Chapter.isCleared(1, 0)).toBe(false)
		expect(Chapter.isCleared(0, 1)).toBe(false)
	end)

	it("nextRoom avanza y termina en nil; reward sin pago", function()
		local s = Chapter.start(7)
		for i = 1, 10 do
			expect((Chapter.nextRoom(s) :: any).index).toBe(i)
		end
		expect(Chapter.nextRoom(s)).toBeNil()
		expect(Chapter.reward("boss", 10).gold > Chapter.reward("combat", 1).gold).toBe(true)
	end)
end)
