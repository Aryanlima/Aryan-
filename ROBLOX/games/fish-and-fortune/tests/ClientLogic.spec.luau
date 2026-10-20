--!nonstrict
local testkit = require("@testkit")
local Balance = require("../src/shared/Balance")
local ClientLogic = require("../src/shared/ClientLogic")
local Shop = require("../../../packages/Shop")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect

local function state(overrides)
	local s = {
		totalCasts = 0,
		inventoryCount = 0,
		ftueStep = 0,
		coins = 0,
		ownedRods = { driftwood = true },
		discoveries = 0,
	}
	for k, v in overrides or {} do
		s[k] = v
	end
	return s
end

describe("ClientLogic.ftueHint (primeros 60 s guiados)", function()
	it("sin estado no hay pista", function()
		expect(ClientLogic.ftueHint(nil, Balance, false)).toBeNil()
	end)

	it("al entrar, el objetivo es LANZAR (cero menus previos)", function()
		local hint = assert(ClientLogic.ftueHint(state(), Balance, false))
		expect(hint.id).toBe("cast")
		expect(hint.target).toBe("cast")
	end)

	it("durante el primer minijuego explica como recoger", function()
		expect(assert(ClientLogic.ftueHint(state(), Balance, true)).id).toBe("reel")
	end)

	it("con peces en el inventario antes de la primera venta, apunta a VENDER", function()
		local hint =
			assert(ClientLogic.ftueHint(state({ totalCasts = 1, inventoryCount = 1, ftueStep = 3 }), Balance, false))
		expect(hint.id).toBe("sell")
		expect(hint.target).toBe("sell")
	end)

	it("al poder pagar la primera mejora, apunta a CANAS", function()
		local hint = assert(
			ClientLogic.ftueHint(
				state({ totalCasts = 3, ftueStep = 4, coins = Balance.rods.reed.price }),
				Balance,
				false
			)
		)
		expect(hint.id).toBe("rods")
	end)

	it("no pide la mejora si no alcanza el dinero", function()
		local hint = ClientLogic.ftueHint(
			state({ totalCasts = 3, ftueStep = 4, coins = Balance.rods.reed.price - 1 }),
			Balance,
			false
		)
		expect(hint).toBeNil()
	end)

	it("tras la primera mejora invita al bestiario y luego deja de molestar", function()
		local s = state({ totalCasts = 4, ftueStep = 5, discoveries = 3 })
		expect(assert(ClientLogic.ftueHint(s, Balance, false)).id).toBe("bestiary")
		s.totalCasts = 30
		expect(ClientLogic.ftueHint(s, Balance, false)).toBeNil()
	end)

	it("los textos de las pistas no usan lenguaje de presion", function()
		for _, hint in
			{
				ClientLogic.ftueHint(state(), Balance, false),
				ClientLogic.ftueHint(state(), Balance, true),
				ClientLogic.ftueHint(state({ totalCasts = 1, inventoryCount = 1, ftueStep = 3 }), Balance, false),
			}
		do
			expect(Shop.findPressureLanguage(hint.text)).toBeNil()
		end
	end)
end)

describe("ClientLogic.remainingSeconds", function()
	it("cuenta atras exacta con el reloj del servidor del ultimo estado", function()
		-- el servidor decia que eran las 1000 s; han pasado 30 s locales; el evento acaba en 1100
		expect(ClientLogic.remainingSeconds(1100, 1000, 500, 530)).toBe(70)
	end)

	it("nunca es negativa ni crece si el reloj local retrocede", function()
		expect(ClientLogic.remainingSeconds(1100, 1000, 500, 400)).toBe(100)
		expect(ClientLogic.remainingSeconds(1100, 1000, 500, 9999)).toBe(0)
	end)
end)

describe("ClientLogic: textos", function()
	it("bannerText incluye al jugador, la criatura y la zona", function()
		local text = ClientLogic.bannerText({ player = "Ana", creature = "Koi Lunar", zone = "Lago Calmo", vip = true })
		expect(text).toContain("[VIP] Ana")
		expect(text).toContain("MITICO")
		expect(text).toContain("Koi Lunar")
	end)

	it("failureText traduce los motivos de jugador y oculta los tecnicos", function()
		expect(ClientLogic.failureText("inventory-full")).toContain("Inventario lleno")
		expect(ClientLogic.failureText("too-early")).toBeNil()
		expect(ClientLogic.failureText("no-cast")).toBeNil()
		expect(ClientLogic.failureText("impossible-time")).toBeNil()
	end)

	it("ningun texto de fallo usa lenguaje de presion", function()
		for _, reason in { "cooldown", "inventory-full", "expired", "not-enough-coins", "restricted", "owned" } do
			expect(Shop.findPressureLanguage(assert(ClientLogic.failureText(reason)))).toBeNil()
		end
	end)
end)
