--!nonstrict
-- Revision 2026-10-20: validacion de los PREMIOS de los codigos en la configuracion remota (LiveOps).
local testkit = require("@testkit")
local LiveOps = require("../packages/LiveOps")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect

local function config(reward)
	return { version = 1, events = {}, codes = { PROMO = { reward = reward } } }
end

describe("Review: LiveOps (premios de codigos)", function()
	it("BUG LIVEOPS-01: premios NaN, inf, negativos o absurdos se rechazan al validar", function()
		for _, reward in { { coins = 0 / 0 }, { coins = math.huge }, { pearls = -5 }, { coins = 1e300 } } do
			local ok, problems = LiveOps.validateConfig(config(reward), 1000)
			expect(ok).toBe(false)
			expect(table.concat(problems, ";")).toContain("fuera de rango")
		end
	end)

	it("premios normales (y valores no numericos que interpreta el juego) siguen siendo validos", function()
		expect((LiveOps.validateConfig(config({ coins = 500, pearls = 5, slots = 10 }), 1000))).toBe(true)
		expect((LiveOps.validateConfig(config({ coins = 1e9 }), 1000))).toBe(true)
		expect((LiveOps.validateConfig(config({ item = "sombrero" }), 1000))).toBe(true)
	end)
end)
