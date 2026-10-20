--!nonstrict
-- Coherencia del balance de Fish & Fortune: si alguien edita Balance.luau y rompe una regla, falla aqui.
local testkit = require("@testkit")
local Balance = require("../src/shared/Balance")
local FishingRules = require("../src/shared/FishingRules")
local LiveOpsDefaults = require("../src/server/LiveOpsDefaults")
local Odds = require("../../../packages/Odds")
local LiveOps = require("../../../packages/LiveOps")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect

describe("Balance: contenido del MVP", function()
	it("tiene 3 zonas, 25 criaturas, 5 canas y 6 rarezas", function()
		expect(#Balance.zoneOrder).toBe(3)
		expect(#Balance.creatures).toBe(25)
		expect(#Balance.rodOrder).toBe(5)
		expect(#Balance.rarityOrder).toBe(6)
	end)

	it("los ids de criaturas son unicos y su zona y rareza existen", function()
		local seen = {}
		for _, creature in Balance.creatures do
			expect(seen[creature.id]).toBeNil()
			seen[creature.id] = true
			expect(Balance.zones[creature.zone]).toBeTruthy()
			expect(Balance.rarities[creature.rarity]).toBeTruthy()
			expect(creature.value).toBeGreaterThan(0) -- ningun resultado sin valor
			expect(creature.weight).toBeGreaterThan(0)
		end
	end)

	it("cada zona tiene exactamente un MITICO y al menos una criatura de cada rareza base", function()
		for _, zoneId in Balance.zoneOrder do
			local mythic = 0
			local rarities = {}
			for _, creature in Balance.creatures do
				if creature.zone == zoneId then
					rarities[creature.rarity] = true
					if creature.rarity == "Mythic" then
						mythic += 1
					end
				end
			end
			expect(mythic).toBe(1)
			for _, rarity in Balance.rarityOrder do
				expect(rarities[rarity]).toBe(true)
			end
		end
	end)

	it("las canas mejoran de forma monotona (precio, suerte, zona perfecta) y la inicial es gratis", function()
		local previous
		for _, rodId in Balance.rodOrder do
			local rod = Balance.rods[rodId]
			if previous then
				expect(rod.price).toBeGreaterThan(previous.price)
				expect(rod.luck).toBeGreaterThan(previous.luck)
				expect(rod.sweetSpot).toBeGreaterThan(previous.sweetSpot)
				expect(rod.autoInterval).toBeLessThan(previous.autoInterval)
			end
			previous = rod
		end
		expect(Balance.rods.driftwood.price).toBe(0)
	end)

	it("las zonas se desbloquean con costes crecientes y la primera es gratis", function()
		expect(Balance.zones.lake.unlockCost).toBe(0)
		expect(Balance.zones.river.unlockCost).toBeGreaterThan(0)
		expect(Balance.zones.coast.unlockCost).toBeGreaterThan(Balance.zones.river.unlockCost)
	end)

	it("el valor medio de una captura crece de zona en zona", function()
		local rules = FishingRules.new(Balance, Odds)
		local function expectedValue(zoneId)
			local odds = rules:oddsFor(zoneId)
			local probabilities = odds:probabilities(0)
			local total = 0
			for index, entry in odds.entries do
				total += probabilities[index] * entry.value
			end
			return total
		end
		expect(expectedValue("river")).toBeGreaterThan(expectedValue("lake") * 3)
		expect(expectedValue("coast")).toBeGreaterThan(expectedValue("river") * 3)
	end)
end)

describe("Balance: cumplimiento de probabilidades", function()
	local rules = FishingRules.new(Balance, Odds)

	it("la tabla de cada zona es valida con suerte 0 y con la suerte maxima", function()
		for _, zoneId in Balance.zoneOrder do
			local ok, reason = Odds.validate(rules:entriesFor(zoneId), {
				decimals = Balance.decimals,
				maxLuck = Balance.limits.maxLuck,
			})
			expect(reason).toBeNil()
			expect(ok).toBe(true)
		end
	end)

	it("la UI de cada zona suma EXACTAMENTE 100 % con cualquier suerte y no tiene filas en 0 %", function()
		for _, zoneId in Balance.zoneOrder do
			local odds = rules:oddsFor(zoneId)
			for _, luck in { 0, 1, 3.5, 6, Balance.limits.maxLuck } do
				local view = odds:displayRows({ luck = luck })
				local units = 0
				for _, row in view.rows do
					units += math.floor(row.percent * 10 ^ Balance.decimals + 0.5)
					expect(row.percent).toBeGreaterThan(0)
				end
				expect(units).toBe(100 * 10 ^ Balance.decimals)
				expect(view.totalPercentText).toBe("100.00%")
				expect(#view.rows).toBe(#rules:creaturesOf(zoneId))
			end
		end
	end)

	it("el MITICO tiene una probabilidad base pequena pero visible (>= 0.01 %)", function()
		for _, zoneId in Balance.zoneOrder do
			local odds = rules:oddsFor(zoneId)
			local probability
			for _, creature in rules:creaturesOf(zoneId) do
				if creature.rarity == "Mythic" then
					probability = odds:probabilityOf(creature.id, 0)
				end
			end
			expect(probability).toBeGreaterThanOrEqual(0.0001)
			expect(probability).toBeLessThan(0.002)
		end
	end)

	it("el multiplicador de suerte de cada rareza es >= 1 y crece con la rareza", function()
		local previous = 0
		for _, rarity in Balance.rarityOrder do
			local factor = Balance.rarities[rarity].luckFactor
			expect(factor).toBeGreaterThanOrEqual(previous)
			previous = factor
		end
		expect(Balance.rarities.Common.luckFactor).toBe(1)
	end)
end)

describe("Balance: progresion y recompensas", function()
	it("los niveles de temporada son crecientes y sus premios no incluyen azar", function()
		local previous = 0
		for _, tier in Balance.season.tiers do
			expect(tier.points).toBeGreaterThan(previous)
			previous = tier.points
			for _, reward in { tier.free, tier.premium } do
				for key in reward do
					expect(key == "coins" or key == "pearls" or key == "slots").toBe(true)
				end
			end
		end
		expect(#Balance.season.tiers).toBe(10)
	end)

	it("las recompensas del bestiario referencian zonas y objetivos existentes", function()
		local ids = {}
		for _, reward in Balance.bestiary.rewards do
			expect(ids[reward.id]).toBeNil()
			ids[reward.id] = true
			if reward.kind == "zone" then
				expect(Balance.zones[reward.zone]).toBeTruthy()
			else
				expect(reward.target).toBeLessThanOrEqual(#Balance.creatures)
			end
		end
	end)

	it("el pack de inicio no contiene azar ni bonus de suerte", function()
		for key in Balance.products.starterPack do
			expect(key == "coins" or key == "pearls" or key == "slots").toBe(true)
		end
	end)

	it("el tutorial garantiza rarezas que existen en la zona inicial", function()
		local present = {}
		for _, creature in Balance.creatures do
			if creature.zone == "lake" then
				present[creature.rarity] = true
			end
		end
		for _, rarity in Balance.ftue.guaranteedRarities do
			expect(present[rarity]).toBe(true)
		end
	end)

	it(
		"la configuracion de LiveOps por defecto es valida y exactamente un evento esta activo en cada instante",
		function()
			local cfg = LiveOpsDefaults
			local ok, problems = LiveOps.validateConfig(cfg, 1792368000 + 10)
			expect(problems).toEqual({})
			expect(ok).toBe(true)
			local now = 1792368000
			for _ = 1, 40 do
				local active = 0
				for _, event in cfg.events do
					if LiveOps.eventWindow(event, now) then
						active += 1
					end
				end
				expect(active).toBe(1) -- rotacion semanal: siempre uno, nunca dos
				now += 3 * 24 * 3600 + 777
			end
		end
	)

	it("el codigo de canje por defecto y la bienvenida estan bien formados", function()
		expect(LiveOps.normalizeCode("WELCOME")).toBe("WELCOME")
		expect(LiveOpsDefaults.welcome.id).toBeTruthy()
	end)
end)
