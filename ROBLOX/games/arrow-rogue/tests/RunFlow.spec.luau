--!nonstrict
-- Run de 10 salas con reloj falso: tras limpiar la sala N, la N+1 genera su primera oleada a tiempo.
local testkit = require("@testkit")
local Chapter = require("../src/shared/Chapter")
local Balance = require("../src/shared/Balance")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect

describe("RunFlow", function()
	it("las 10 salas arrancan su primera oleada en <= wave.delay tras entrar", function()
		for seed = 1, 50 do
			local state, t = Chapter.start(seed), 100
			for n = 1, 10 do
				local room = Chapter.nextRoom(state)
				local pending, roomStart = table.clone(room.waves), t
				local first = math.huge
				for _, w in room.waves do
					first = math.min(first, w.delay)
				end
				local alive, spawnedAt = 0, nil
				while #pending > 0 or alive > 0 do
					t += 0.1
					for _, w in Chapter.takeDue(pending, t, roomStart) do
						spawnedAt = spawnedAt or t
						alive += w.count
					end
					if alive > 0 and t - roomStart > 1 then
						alive = 0 -- mueren todos
					end
					expect(t - roomStart < 60).toBe(true)
				end
				if #room.waves > 0 then
					expect(spawnedAt - roomStart <= first + 0.15).toBe(true)
				end
				expect(Chapter.isCleared(alive, #pending)).toBe(true)
				t += 2 -- nextAt = now + 2
				expect(room.index).toBe(n)
			end
		end
	end)

	it("takeDue respeta el retraso y xpPerKill existe", function()
		local pending = { { enemyId = "e1", count = 1, delay = 0 }, { enemyId = "e1", count = 1, delay = 4 } }
		expect(#Chapter.takeDue(pending, 10, 10)).toBe(1)
		expect(#Chapter.takeDue(pending, 13.9, 10)).toBe(0)
		expect(#Chapter.takeDue(pending, 14, 10)).toBe(1)
		expect(Balance.xpPerKill > 0).toBe(true)
	end)
end)
