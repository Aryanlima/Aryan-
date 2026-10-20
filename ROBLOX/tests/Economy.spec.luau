--!nonstrict
-- Tests de packages/Economy: saldos, topes, multiplicadores, boosts y ganancias offline.
local testkit = require("@testkit")
local Economy = require("../packages/Economy")

local describe, it, expect, beforeEach = testkit.describe, testkit.it, testkit.expect, testkit.beforeEach

describe("Ledger: saldos", function()
	local ledger, wallet, events

	beforeEach(function()
		events = {}
		ledger = Economy.newLedger({
			currencies = {
				coins = { kind = "soft", maxBalance = 1000 },
				pearls = { kind = "hard" },
			},
			onTransaction = function(tx)
				table.insert(events, tx)
			end,
		})
		wallet = {}
	end)

	it("suma y gasta enteros", function()
		expect(select(2, ledger:add(wallet, "coins", 50))).toBe(50)
		expect(ledger:spend(wallet, "coins", 20)).toBe(true)
		expect(ledger:balance(wallet, "coins")).toBe(30)
	end)

	it("gastar es atomico: sin saldo suficiente no cambia nada", function()
		ledger:add(wallet, "coins", 10)
		expect(ledger:spend(wallet, "coins", 11)).toBe(false)
		expect(ledger:balance(wallet, "coins")).toBe(10)
	end)

	it("rechaza cantidades invalidas (NaN, inf, negativas, fraccionarias, no numericas)", function()
		for _, bad in { 0 / 0, math.huge, -math.huge, -5, 1.5, "10", true } do
			local added = ledger:add(wallet, "coins", bad)
			expect(added).toBe(0)
			expect(ledger:spend(wallet, "coins", bad)).toBe(false)
		end
		expect(ledger:balance(wallet, "coins")).toBe(0)
		expect(#events).toBe(0)
	end)

	it("respeta el tope por moneda y reporta lo realmente sumado", function()
		ledger:add(wallet, "coins", 990)
		local added, balance = ledger:add(wallet, "coins", 50)
		expect(added).toBe(10)
		expect(balance).toBe(1000)
		expect(ledger:add(wallet, "coins", 1)).toBe(0)
	end)

	it("un saldo corrupto en el perfil (NaN/negativo) se lee como 0", function()
		wallet.coins = 0 / 0
		expect(ledger:balance(wallet, "coins")).toBe(0)
		wallet.coins = -4
		expect(ledger:balance(wallet, "coins")).toBe(0)
	end)

	it("notifica fuentes y sumideros con el saldo final (para LogEconomyEvent)", function()
		ledger:add(wallet, "coins", 100, { reason = "Gameplay", sku = "fish_sale" })
		ledger:spend(wallet, "coins", 40, { reason = "Shop", sku = "rod_reed" })
		expect(#events).toBe(2)
		expect(events[1]).toEqual({
			flow = "Source",
			currency = "coins",
			amount = 100,
			endingBalance = 100,
			reason = "Gameplay",
			sku = "fish_sale",
		})
		expect(events[2].flow).toBe("Sink")
		expect(events[2].endingBalance).toBe(60)
	end)

	it("un error en el hook de analitica no rompe la economia", function()
		local l2 = Economy.newLedger({
			currencies = { coins = { kind = "soft" } },
			onTransaction = function()
				error("analytics caido")
			end,
		})
		local w = {}
		expect(select(2, l2:add(w, "coins", 5))).toBe(5)
	end)

	it("moneda desconocida lanza error", function()
		expect(function()
			ledger:add(wallet, "gold", 1)
		end).toThrow("moneda desconocida")
	end)
end)

describe("multiplicadores", function()
	local function src(id, kind, value, active)
		return { id = id, kind = kind, value = value, active = active ~= false }
	end

	it("sin fuentes activas el multiplicador es 1", function()
		expect(Economy.combineMultipliers({}, "coins", 8)).toBe(1)
		expect(Economy.combineMultipliers({ src("a", "coins", 2, false) }, "coins", 8)).toBe(1)
	end)

	it("aditivo por defecto: 2x + 2x = 3x", function()
		local sources = { src("pass", "coins", 2), src("event", "coins", 2) }
		expect(Economy.combineMultipliers(sources, "coins", 8)).toBe(3)
	end)

	it("multiplicativo opcional: 2x * 2x = 4x", function()
		local sources = { src("pass", "coins", 2), src("event", "coins", 2) }
		expect(Economy.combineMultipliers(sources, "coins", 8, "multiplicative")).toBe(4)
	end)

	it("siempre limitado por el tope", function()
		local sources = { src("a", "coins", 5), src("b", "coins", 5), src("c", "coins", 5) }
		expect(Economy.combineMultipliers(sources, "coins", 6)).toBe(6)
		expect(Economy.combineMultipliers(sources, "coins", 6, "multiplicative")).toBe(6)
	end)

	it("ignora otros tipos y valores invalidos (NaN, inf, <= 0)", function()
		local sources = {
			src("a", "luck", 3),
			src("b", "coins", 0 / 0),
			src("c", "coins", math.huge),
			src("d", "coins", -2),
			src("e", "coins", 0),
		}
		expect(Economy.combineMultipliers(sources, "coins", 8)).toBe(1)
	end)

	it("sumBonuses suma puntos activos y respeta el tope", function()
		local sources = { src("rod", "luck", 2), src("bait", "luck", 3), src("pass", "luck", 2, false) }
		expect(Economy.sumBonuses(sources, "luck", 10)).toBe(5)
		expect(Economy.sumBonuses(sources, "luck", 4)).toBe(4)
		expect(Economy.sumBonuses({}, "luck", 4)).toBe(0)
	end)
end)

describe("boosts temporales", function()
	it("concede, prolonga con tope y expira", function()
		local boosts = {}
		local now = 1000
		expect(Economy.grantBoost(boosts, "bait", 900, now, 3600)).toBe(1900)
		expect(Economy.isBoostActive(boosts, "bait", now)).toBe(true)
		expect(Economy.boostRemaining(boosts, "bait", 1400)).toBe(500)
		-- comprar otro cebo con 500 s restantes: 500 + 900 = 1400
		expect(Economy.grantBoost(boosts, "bait", 900, 1400, 3600)).toBe(1400 + 1400)
		-- el tope de acumulacion limita a 3600 s restantes
		for _ = 1, 10 do
			Economy.grantBoost(boosts, "bait", 900, 1400, 3600)
		end
		expect(Economy.boostRemaining(boosts, "bait", 1400)).toBe(3600)
		expect(Economy.isBoostActive(boosts, "bait", 1400 + 3600)).toBe(false)
	end)

	it("rechaza duraciones invalidas sin tocar el estado", function()
		local boosts = {}
		expect(Economy.grantBoost(boosts, "x", -5, 0, 100)).toBeNil()
		expect(Economy.grantBoost(boosts, "x", 0 / 0, 0, 100)).toBeNil()
		expect(Economy.grantBoost(boosts, "x", math.huge, 0, 100)).toBeNil()
		expect(next(boosts)).toBeNil()
	end)

	it("pruneBoosts elimina solo los vencidos", function()
		local boosts = { old = 10, fresh = 500 }
		expect(Economy.pruneBoosts(boosts, 100)).toBe(1)
		expect(boosts.old).toBeNil()
		expect(boosts.fresh).toBe(500)
	end)
end)

describe("ganancias offline", function()
	local function earn(overrides)
		local params = { lastSeen = 1000, now = 1000 + 3600, ratePerHour = 100, capSeconds = 7200 }
		for k, v in overrides do
			params[k] = v
		end
		return Economy.offlineEarnings(params)
	end

	it("calcula por hora y aplica multiplicador", function()
		expect(earn({}).amount).toBe(100)
		expect(earn({ multiplier = 2 }).amount).toBe(200)
	end)

	it("aplica el tope de tiempo y lo senala", function()
		local result = earn({ now = 1000 + 10 * 3600 })
		expect(result.seconds).toBe(7200)
		expect(result.amount).toBe(200)
		expect(result.capped).toBe(true)
	end)

	it("no da nada con reloj atrasado, primera sesion o parametros invalidos", function()
		expect(earn({ now = 500 }).amount).toBe(0)
		expect(earn({ lastSeen = 0 }).amount).toBe(0)
		expect(earn({ ratePerHour = 0 / 0 }).amount).toBe(0)
		expect(earn({ capSeconds = -1 }).amount).toBe(0)
		expect(earn({ now = math.huge }).amount).toBe(0)
	end)

	it("respeta el minimo de segundos", function()
		expect(earn({ now = 1000 + 30, minSeconds = 60 }).amount).toBe(0)
		expect(earn({ now = 1000 + 90, minSeconds = 60 }).amount).toBeGreaterThan(0)
	end)
end)

describe("redondeo", function()
	it("round nunca devuelve negativos ni no finitos", function()
		expect(Economy.round(2.5)).toBe(3)
		expect(Economy.round(-3)).toBe(0)
		expect(Economy.round(0 / 0)).toBe(0)
		expect(Economy.round(math.huge)).toBe(0)
	end)
end)
