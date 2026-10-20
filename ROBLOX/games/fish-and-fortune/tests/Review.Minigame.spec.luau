--!nonstrict
--[[
	Revision 2026-10-20: CUANTIFICA que gana un cliente tramposo con el minijuego que depende del tiempo informado
	por el cliente (FishingRules.evaluateReel). Son pruebas de CARACTERIZACION: describen el limite real del diseno
	actual (no un bug nuevo). Si se endurece el minijuego, actualiza las cifras.

	Resultado (con Balance actual): ventana de mentira = maxLagSeconds + timingTolerance = 2,85 s > periodo del
	marcador (1,5 s) => para CUALQUIER centro de la zona perfecta el cliente puede declarar un tiempo que ponga el
	marcador justo en ella, y recoger en cuanto pasa minReelSeconds (0,35 s) o poco despues. Aun asi:
	  * NO puede recoger antes de minReelSeconds ni declarar mas tiempo del transcurrido (+0,35 s);
	  * el premio es solo la calidad "perfecta" (+1 de suerte, gratis; ver Balance.minigame.perfectLuck);
	  * el ciclo minimo sigue siendo minReel + castCooldown (>= 1,35 s por captura).
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

	-- Mejor jugada de un tramposo: a cada instante `serverElapsed` declara el tiempo (dentro de lo permitido) cuyo
	-- marcador esta mas cerca del centro. Devuelve el primer instante (paso 0,01 s) en que consigue "perfect".
	local function earliestPerfect(center)
		local cast = newCast(center)
		local serverElapsed = mg.minReelSeconds
		while serverElapsed <= mg.durationSeconds do
			local low = math.max(mg.minReelSeconds, serverElapsed - mg.maxLagSeconds)
			local high = serverElapsed + mg.timingTolerance
			local claimed = low
			while claimed <= high do
				if rules:evaluateReel(cast, claimed, serverElapsed) == "perfect" then
					return serverElapsed
				end
				claimed += 0.01
			end
			serverElapsed += 0.01
		end
		return nil
	end

	it(
		"un tramposo acierta la zona perfecta con CUALQUIER centro en menos de ~1 s (ventana de mentira > periodo)",
		function()
			expect(mg.maxLagSeconds + mg.timingTolerance > mg.markerPeriod).toBe(true)
			local worst = 0
			for i = 0, 50 do
				local center = mg.centerMin + (mg.centerMax - mg.centerMin) * i / 50
				local at = earliestPerfect(center)
				expect(at).toBeTruthy()
				worst = math.max(worst, at)
			end
			expect(worst < 1.1).toBe(true) -- medido: ~0,96 s en el peor centro
		end
	)

	it("lo que NO puede: recoger antes del minimo, declarar mas tiempo del transcurrido, ni NaN", function()
		local cast = newCast(0.5)
		expect(rules:evaluateReel(cast, mg.minReelSeconds - 0.01, 1)).toBeNil()
		local quality, reason = rules:evaluateReel(cast, 1.0 + mg.timingTolerance + 0.01, 1.0)
		expect(quality).toBeNil()
		expect(reason).toBe("impossible-time")
		expect(select(2, rules:evaluateReel(cast, 0 / 0, 1.0))).toBe("too-early")
	end)

	it(
		"impacto economico acotado: perfecta = +1 de suerte (Mitico 0,040 % -> 0,057 % en el Lago), tope global de suerte 8",
		function()
			local lake = rules:oddsFor("lake")
			local base = lake:probabilityOf("lake_spirit", 0)
			local perfect = lake:probabilityOf("lake_spirit", Balance.minigame.perfectLuck)
			expect(math.abs(base - 0.0004) < 0.00001).toBe(true)
			expect(perfect / base > 1.4 and perfect / base < 1.5).toBe(true)
			expect(lake:probabilityOf("lake_spirit", 1000) < 0.007).toBe(true) -- tope maxLuck = 8
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
