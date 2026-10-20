--!nonstrict
-- Tests de packages/Odds: suma 100 %, distribucion con RNG inyectado, cumplimiento y pity.
local testkit = require("@testkit")
local Odds = require("../packages/Odds")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect

-- PRNG determinista (LCG de 32 bits) en [0, 1)
local function lcg(seed: number)
	local state = seed
	return function()
		state = (state * 1664525 + 1013904223) % 4294967296
		return state / 4294967296
	end
end

local function sequence(values: { number })
	local i = 0
	return function()
		i += 1
		return values[((i - 1) % #values) + 1]
	end
end

local function sum(list: { number }): number
	local total = 0
	for _, value in list do
		total += value
	end
	return total
end

local function pondTable()
	return {
		{ id = "minnow", weight = 600, rarity = "Common", value = 5 },
		{ id = "trout", weight = 250, rarity = "Uncommon", luckFactor = 1.05, value = 20 },
		{ id = "pike", weight = 100, rarity = "Rare", luckFactor = 1.12, value = 90 },
		{ id = "koi", weight = 40, rarity = "Epic", luckFactor = 1.25, value = 400 },
		{ id = "dragon", weight = 9.9, rarity = "Legendary", luckFactor = 1.4, value = 2500 },
		{ id = "leviathan", weight = 0.1, rarity = "Mythic", luckFactor = 1.6, value = 20000 },
	}
end

describe("Odds.new / validate", function()
	it("acepta una tabla valida", function()
		local ok = Odds.validate(pondTable(), { maxLuck = 10 })
		expect(ok).toBe(true)
	end)

	it("rechaza resultados tipo 'nada' (cumplimiento)", function()
		local entries = pondTable()
		table.insert(entries, { id = "Nothing", weight = 10 })
		local ok, reason = Odds.validate(entries)
		expect(ok).toBe(false)
		expect(reason).toContain("nada")
	end)

	it("rechaza resultados sin valor para el jugador", function()
		local entries = pondTable()
		entries[1].value = 0
		local ok = Odds.validate(entries)
		expect(ok).toBe(false)
	end)

	it("rechaza ids duplicados, pesos invalidos (0, negativo, NaN, inf) y tablas vacias", function()
		local dup = pondTable()
		table.insert(dup, { id = "trout", weight = 1 })
		expect((Odds.validate(dup))).toBe(false)
		for _, weight in { 0, -5, 0 / 0, math.huge } do
			local bad = pondTable()
			bad[1].weight = weight
			expect((Odds.validate(bad))).toBe(false)
		end
		expect((Odds.validate({}))).toBe(false)
	end)

	it("rechaza entradas que se mostrarian como 0.00 %", function()
		local entries = {
			{ id = "a", weight = 1000000 },
			{ id = "b", weight = 1 }, -- 0.0001 % < 0.01 %
		}
		local ok, reason = Odds.validate(entries)
		expect(ok).toBe(false)
		expect(reason).toContain("unidad mostrable")
	end)

	it("Odds.new lanza error si la tabla es invalida", function()
		expect(function()
			Odds.new({ { id = "x", weight = -1 } })
		end).toThrow("weight invalido")
	end)

	it("rechaza un pity sin texto visible o con objetivos inexistentes", function()
		local noNote = { pity = { rolls = 10, targetIds = { "koi" }, note = "" } }
		expect((Odds.validate(pondTable(), noNote))).toBe(false)
		local badTarget = { pity = { rolls = 10, targetIds = { "ghost" }, note = "visible" } }
		expect((Odds.validate(pondTable(), badTarget))).toBe(false)
	end)
end)

describe("probabilidades y UI de probabilidades", function()
	it("las probabilidades suman 1 con cualquier suerte", function()
		local odds = Odds.new(pondTable(), { maxLuck = 20 })
		for _, luck in { 0, 0.5, 1, 5, 12.5, 20, 999, -4 } do
			expect(sum(odds:probabilities(luck))).toBeCloseTo(1, 9)
		end
	end)

	it("los porcentajes mostrados suman EXACTAMENTE 100 % y nadie muestra 0 %", function()
		local odds = Odds.new(pondTable(), { maxLuck = 20, decimals = 2 })
		for _, luck in { 0, 1, 2.5, 7, 13.37, 20 } do
			local view = odds:displayRows({ luck = luck })
			local totalUnits = 0
			for _, row in view.rows do
				totalUnits += math.floor(row.percent * 100 + 0.5)
				expect(row.percent).toBeGreaterThan(0)
				expect(row.percentText).never.toBe("0.00%")
			end
			expect(totalUnits).toBe(10000)
			expect(view.totalPercentText).toBe("100.00%")
			expect(view.rows).toHaveLength(6)
		end
	end)

	it("la suma de unidades es 100 % para tablas aleatorias (propiedad)", function()
		local rng = lcg(7)
		for round = 1, 300 do
			local count = 2 + math.floor(rng() * 25)
			local entries = {}
			for i = 1, count do
				-- pesos entre 1 y ~1000 para evitar filas < 0.01 %
				entries[i] = { id = "e" .. i, weight = 1 + rng() * 1000 }
			end
			local odds = Odds.new(entries, { decimals = 2 })
			local units = Odds.allocateUnits(odds:probabilities(0), 2)
			expect(sum(units)).toBe(10000)
			for _, u in units do
				expect(u).toBeGreaterThanOrEqual(1)
			end
			local decimals0 = Odds.allocateUnits(odds:probabilities(0), 0)
			expect(sum(decimals0)).toBe(100)
			local _ = round
		end
	end)

	it("tres entradas iguales: 33.34 / 33.33 / 33.33 suman 100.00", function()
		local odds = Odds.new({
			{ id = "a", weight = 1 },
			{ id = "b", weight = 1 },
			{ id = "c", weight = 1 },
		})
		local view = odds:displayRows({ sort = "entry" })
		expect(view.rows[1].percentText).toBe("33.34%")
		expect(view.rows[2].percentText).toBe("33.33%")
		expect(view.rows[3].percentText).toBe("33.33%")
	end)

	it("la suerte cambia las probabilidades MOSTRADAS y la columna base se mantiene", function()
		local odds = Odds.new(pondTable(), { maxLuck = 20 })
		local base = odds:displayRows({ luck = 0 })
		local lucky = odds:displayRows({ luck = 10 })
		expect(lucky.luckActive).toBe(true)
		expect(base.luckActive).toBe(false)

		local function rowOf(view, id)
			for _, row in view.rows do
				if row.id == id then
					return row
				end
			end
			return nil
		end

		expect(rowOf(lucky, "leviathan").probability).toBeGreaterThan(rowOf(base, "leviathan").probability)
		expect(rowOf(lucky, "minnow").probability).toBeLessThan(rowOf(base, "minnow").probability)
		-- la columna "base" con suerte 10 es igual a lo que se muestra sin suerte
		expect(rowOf(lucky, "koi").basePercentText).toBe(rowOf(base, "koi").percentText)
	end)

	it("la suerte esta limitada por maxLuck y NaN/inf cuentan como 0", function()
		local odds = Odds.new(pondTable(), { maxLuck = 5 })
		expect(odds:displayRows({ luck = 1e9 }).luck).toBe(5)
		expect(odds:displayRows({ luck = 0 / 0 }).luck).toBe(0)
		expect(odds:displayRows({ luck = -3 }).luck).toBe(0)
		expect(odds:probabilityOf("koi", 1e9)).toBeCloseTo(odds:probabilityOf("koi", 5), 12)
	end)

	it("un resultado de un solo uso excluido deja de mostrarse y el resto sigue sumando 100 %", function()
		local odds = Odds.new(pondTable(), { maxLuck = 5 })
		local view = odds:displayRows({ exclude = { leviathan = true } })
		expect(view.rows).toHaveLength(5)
		local totalUnits = 0
		for _, row in view.rows do
			totalUnits += math.floor(row.percent * 100 + 0.5)
			expect(row.id).never.toBe("leviathan")
		end
		expect(totalUnits).toBe(10000)
	end)

	it("incluye siempre la nota de pity si hay pity", function()
		local odds = Odds.new(pondTable(), {
			pity = { rolls = 50, targetIds = { "koi", "dragon", "leviathan" }, note = "Garantia visible" },
		})
		expect(odds:displayRows().pityNote).toBe("Garantia visible")
		local plain = Odds.new(pondTable())
		expect(plain:displayRows().pityNote).toBeNil()
	end)
end)

describe("tirada del servidor (RNG inyectado)", function()
	it("es determinista: mismos numeros => mismos resultados", function()
		local odds = Odds.new(pondTable())
		local a, b = lcg(42), lcg(42)
		for _ = 1, 100 do
			expect(odds:roll(a)).toBe(odds:roll(b))
		end
	end)

	it("los extremos del RNG caen en la primera y la ultima entrada", function()
		local odds = Odds.new(pondTable())
		expect(odds:roll(function()
			return 0
		end)).toBe("minnow")
		expect(odds:roll(function()
			return 0.9999999999
		end)).toBe("leviathan")
		expect(odds:roll(function()
			return 1
		end)).toBe("leviathan") -- un RNG defectuoso (>= 1) no rompe nada
		expect(odds:roll(function()
			return 0 / 0
		end)).toBe("minnow") -- NaN se trata como 0
	end)

	it("los umbrales acumulados coinciden con las probabilidades", function()
		local odds = Odds.new({
			{ id = "a", weight = 50 },
			{ id = "b", weight = 30 },
			{ id = "c", weight = 20 },
		})
		local function rollAt(x)
			return odds:roll(function()
				return x
			end)
		end
		expect(rollAt(0.4999)).toBe("a")
		expect(rollAt(0.5)).toBe("b")
		expect(rollAt(0.7999)).toBe("b")
		expect(rollAt(0.8)).toBe("c")
	end)

	it("la frecuencia empirica (200k tiradas) coincide con la tabla mostrada", function()
		local odds = Odds.new(pondTable(), { maxLuck = 20 })
		for _, luck in { 0, 8 } do
			local rng = lcg(2026 + luck)
			local counts = {}
			local rolls = 200000
			for _ = 1, rolls do
				local id = odds:roll(rng, luck)
				counts[id] = (counts[id] or 0) + 1
			end
			local view = odds:displayRows({ luck = luck })
			for _, row in view.rows do
				local observed = (counts[row.id] or 0) / rolls
				-- tolerancia: 5 sigmas binomiales (+ margen para filas muy raras)
				local sigma = math.sqrt(row.probability * (1 - row.probability) / rolls)
				expect(math.abs(observed - row.probability)).toBeLessThan(5 * sigma + 0.0005)
			end
		end
	end)

	it("una entrada excluida nunca sale", function()
		local odds = Odds.new(pondTable())
		local rng = lcg(5)
		for _ = 1, 5000 do
			expect(odds:roll(rng, 0, { minnow = true })).never.toBe("minnow")
		end
	end)

	it("si todo esta excluido se lanza un error claro", function()
		local odds = Odds.new({ { id = "a", weight = 1 } })
		expect(function()
			odds:roll(function()
				return 0.5
			end, 0, { a = true })
		end).toThrow("todas las probabilidades son 0")
	end)
end)

describe("pity visible", function()
	local function pityOdds()
		return Odds.new(pondTable(), {
			maxLuck = 5,
			pity = { rolls = 5, targetIds = { "koi", "dragon", "leviathan" }, note = "Cada 5 lanzamientos sin Epico, el siguiente lo es." },
		})
	end

	it("garantiza un objetivo tras rolls - 1 fallos y reinicia el contador", function()
		local odds = pityOdds()
		local counter = 0
		-- RNG que siempre cae en la primera entrada (minnow): nunca es objetivo por azar
		local rng = function()
			return 0
		end
		local results = {}
		for _ = 1, 5 do
			local id
			id, counter = odds:rollWithPity(rng, 0, nil, counter)
			table.insert(results, id)
		end
		expect(results[1]).toBe("minnow")
		expect(results[4]).toBe("minnow")
		expect(results[5]).never.toBe("minnow") -- la 5.a esta garantizada
		expect(counter).toBe(0)
	end)

	it("un objetivo obtenido por azar reinicia el contador", function()
		local odds = pityOdds()
		local id, counter = odds:rollWithPity(function()
			return 0.9999
		end, 0, nil, 3)
		expect(id).toBe("leviathan")
		expect(counter).toBe(0)
	end)

	it("sin pity configurado se comporta como roll y devuelve contador 0", function()
		local odds = Odds.new(pondTable())
		local id, counter = odds:rollWithPity(function()
			return 0
		end, 0, nil, 99)
		expect(id).toBe("minnow")
		expect(counter).toBe(0)
	end)
end)

describe("gating por PolicyService", function()
	it("sin datos de politica se considera restringido (conservador)", function()
		expect(Odds.paidRandomAllowed(nil)).toBe(false)
		expect(Odds.paidItemTradingAllowed(nil)).toBe(false)
	end)

	it("usa ArePaidRandomItemsRestricted (true = restringido)", function()
		expect(Odds.paidRandomAllowed({ ArePaidRandomItemsRestricted = true })).toBe(false)
		expect(Odds.paidRandomAllowed({ ArePaidRandomItemsRestricted = false })).toBe(true)
		expect(Odds.paidRandomAllowed({})).toBe(false) -- campo ausente: no asumir permiso
	end)

	it("el comercio de objetos pagados es una comprobacion separada", function()
		expect(Odds.paidItemTradingAllowed({ IsPaidItemTradingAllowed = true })).toBe(true)
		expect(Odds.paidItemTradingAllowed({ IsPaidItemTradingAllowed = false })).toBe(false)
		expect(
			Odds.paidItemTradingAllowed({ ArePaidRandomItemsRestricted = false, IsPaidItemTradingAllowed = false })
		).toBe(false)
	end)
end)
