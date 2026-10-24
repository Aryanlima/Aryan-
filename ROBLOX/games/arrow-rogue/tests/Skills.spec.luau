--!nonstrict
local testkit = require("@testkit")
local Skills = require("../src/shared/Skills")
local Service = require("../src/server/SkillService")
local describe, it, expect = testkit.describe, testkit.it, testkit.expect

local function distinct(ids)
	local seen = {}
	for _, id in ids do
		if seen[id] then
			return false
		end
		seen[id] = true
	end
	return true
end

describe("Skills", function()
	it("tiene 20 habilidades y el roll es determinista, sin repetidos", function()
		expect(#Skills.list).toBe(20)
		local a, b = Skills.roll(7, {}, 3), Skills.roll(7, {}, 3)
		expect(#a).toBe(3)
		expect(distinct(a)).toBe(true)
		expect(table.concat(a, ",")).toBe(table.concat(b, ","))
	end)
	it("no ofrece las que llegaron al tope", function()
		local owned = {}
		for _, skill in Skills.list do
			owned[skill.id] = skill.max
		end
		owned.s01 = 4
		expect(table.concat(Skills.roll(1, owned, 3), ",")).toBe("s01")
	end)
	it("apply compone modificadores y limita flechas a 5", function()
		local out = Skills.apply({ damage = 10, fireRate = 1, extraArrows = 2 }, { s02 = 2, s01 = 1, s05 = 2, s06 = 1 })
		expect(out.damage).toBeCloseTo(14)
		expect(out.fireRate).toBeCloseTo(1.15)
		expect(out.extraArrows + out.sideArrows).toBe(4)
	end)
	it("SkillPick rechaza indices invalidos, doble eleccion y sin oferta", function()
		local t, fired = 0, {}
		local svc = Service.new({
			Skills = Skills,
			offer = {
				FireClient = function(_, _, ids)
					table.insert(fired, ids)
				end,
			},
			now = function()
				return t
			end,
			seed = function(_, level)
				return level
			end,
			minInterval = 0.5,
		})
		local p = {}
		expect(svc.pick(p, 1)).toBe(false)
		svc.levelUp(p)
		expect(#fired[1]).toBe(3)
		t = 1
		expect(svc.pick(p, 0)).toBe(false)
		t = 2
		expect(svc.pick(p, 1.5)).toBe(false)
		t = 3
		expect(svc.pick(p, "1")).toBe(false)
		t = 4
		expect(svc.pick(p, 4)).toBe(false)
		t = 5
		expect(svc.pick(p, 2)).toBe(true)
		expect(svc.owned(p)[fired[1][2]]).toBe(1)
		t = 6
		expect(svc.pick(p, 2)).toBe(false)
		svc.levelUp(p)
		t = 6.1
		expect(svc.pick(p, 1)).toBe(false)
	end)
end)
