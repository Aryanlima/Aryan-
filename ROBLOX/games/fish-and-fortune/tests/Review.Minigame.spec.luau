--!nonstrict
--[[
	Revision 2026-10-20: CUANTIFICA que gana un cliente tramposo con el minijuego que depende del tiempo informado
	por el cliente (FishingRules.evaluateReel). Son pruebas de CARACTERIZACION: describen el limite real del diseno
	actual (no un bug nuevo). Si se endurece el minijuego, actualiza las cifras.

	La posicion del marcador se determina con el reloj del servidor al recoger.
]]
local testkit = require("@testkit")
local Odds = require("../../../packages/Odds")
local Balance = require("../src/shared/Balance")
local FishingRules = require("../src/shared/FishingRules")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect

describe("Review: minijuego con tiempo del cliente", function()
	local rules = FishingRules.new(Balance, Odds)
	local mg = Balance.minigame

	local function newCast(center)
		return {
			id = 1,
			zone = "lake",
			startedAt = 0,
			center = center,
			width = Balance.rods.driftwood.sweetSpot,
			expiresAt = mg.durationSeconds + mg.graceSeconds,
		}
	end

	it("varios tiempos dentro de la ventana no fuerzan un acierto perfecto", function()
		local cast = newCast(0.5)
		expect(rules:evaluateReel(cast, 0.375, 0.375)).toBe("perfect")
		expect(rules:evaluateReel(cast, 0.75, 0.75)).toBeNil()
		expect(rules:evaluateReel(cast, 1.125, 1.125)).toBe("perfect")
	end)

	it("lo que NO puede: recoger antes del minimo, declarar mas tiempo del transcurrido, ni NaN", function()
		local cast = newCast(0.5)
		expect(rules:evaluateReel(cast, mg.minReelSeconds - 0.01, 1)).toBeNil()
		local quality, reason = rules:evaluateReel(cast, 1.0 + mg.timingTolerance + 0.01, 1.0)
		expect(quality).toBeNil()
		expect(reason).toBe("impossible-time")
		expect(select(2, rules:evaluateReel(cast, 0 / 0, 1.0))).toBe("too-early")
	end)

	it(
		"impacto economico acotado: perfecta = +1 de suerte (Mitico 0,100 % -> 0,143 % en el Lago), tope global de suerte 8",
		function()
			local lake = rules:oddsFor("lake")
			local base = lake:probabilityOf("lake_spirit", 0)
			local perfect = lake:probabilityOf("lake_spirit", Balance.minigame.perfectLuck)
			expect(math.abs(base - 0.001) < 0.00001).toBe(true)
			expect(perfect / base > 1.4 and perfect / base < 1.5).toBe(true)
			expect(lake:probabilityOf("lake_spirit", 1000) < 0.02).toBe(true) -- tope maxLuck = 8
		end
	)

	it(
		"cadencia maxima: minReel + cooldown => >= 1,35 s por captura (~2.600/h), 4-7x la pesca automatica de pago",
		function()
			local cycle = mg.minReelSeconds + mg.castCooldownSeconds
			expect(math.abs(cycle - 1.35) < 1e-9).toBe(true)
			local perHour = 3600 / cycle
			expect(perHour > 2600 and perHour < 2700).toBe(true)
			expect(3600 / Balance.rods.golden.autoInterval).toBe(600) -- mejor caso del pase Auto-Pesca
		end
	)
end)
