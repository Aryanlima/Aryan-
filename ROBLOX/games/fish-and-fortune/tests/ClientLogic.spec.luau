--!nonstrict
local testkit = require("@testkit")
local Balance = require("../src/shared/Balance")
local ClientLogic = require("../src/shared/ClientLogic")
local Shop = require("../../../packages/Shop")
local Locale = require("../../../packages/Locale")
local Odds = require("../../../packages/Odds")
local FishingRules = require("../src/shared/FishingRules")
local Strings = require("../src/shared/Strings")

local locale = Locale.new(Strings)

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

describe("ClientLogic.layout (zonas del chat y de los avisos)", function()
	it("las estadisticas bajan de la zona del chat y los avisos quedan sobre la guia y la barra de acciones", function()
		expect(ClientLogic.layout.statsTopScale > 0).toBe(true)
		expect(ClientLogic.layout.statsTopOffset > 0).toBe(true)
		expect(ClientLogic.layout.toastBottomOffset <= -(96 + 40 + 8)).toBe(true) -- hint: 96 px del borde + 40 px de alto
	end)
end)

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

	it("los textos de las pistas no usan lenguaje de presion (en espanol y en ingles)", function()
		for _, hint in
			{
				ClientLogic.ftueHint(state(), Balance, false),
				ClientLogic.ftueHint(state(), Balance, true),
				ClientLogic.ftueHint(state({ totalCasts = 1, inventoryCount = 1, ftueStep = 3 }), Balance, false),
			}
		do
			for _, language in { "es", "en" } do
				expect(Shop.findPressureLanguage(locale:format(language, hint.key))).toBeNil()
			end
		end
	end)

	it("las pistas devuelven claves de texto que existen en todos los idiomas (nunca texto)", function()
		local hints = {
			assert(ClientLogic.ftueHint(state(), Balance, false)),
			assert(ClientLogic.ftueHint(state(), Balance, true)),
			assert(ClientLogic.ftueHint(state({ totalCasts = 1, inventoryCount = 1, ftueStep = 3 }), Balance, false)),
			assert(
				ClientLogic.ftueHint(
					state({ totalCasts = 3, ftueStep = 4, coins = Balance.rods.reed.price }),
					Balance,
					false
				)
			),
			assert(ClientLogic.ftueHint(state({ totalCasts = 4, ftueStep = 5, discoveries = 3 }), Balance, false)),
		}
		for _, hint in hints do
			expect(string.sub(hint.key, 1, 5)).toBe("hint.")
			for _, language in { "es", "en" } do
				expect(locale:raw(hint.key, language)).toBeTruthy()
			end
		end
		expect(locale:format("es", "hint.cast")).toContain("LANZAR")
		expect(locale:format("en", "hint.cast")).toContain("CAST")
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
	-- El banner de MITICO lo arma el servidor como { key, args } (nunca texto) y lo traduce el cliente: aqui se comprueba
	-- el resultado en los dos idiomas con los mismos argumentos que envia GameService.
	local function banner(vip)
		return {
			key = if vip then "banner.mythic_vip" else "banner.mythic",
			args = { player = "Ana", creature = { key = "creature.moon_koi" }, zone = { key = "zone.lake.name" } },
		}
	end

	it("el banner de MITICO incluye al jugador, la criatura y la zona (ES y EN)", function()
		local key, args = locale:sanitizeMessage(banner(true))
		local es = locale:format("es", assert(key, "clave"), args)
		expect(es).toContain("[VIP] Ana")
		expect(es).toContain("MÍTICO")
		expect(es).toContain("Koi Lunar")
		expect(es).toContain("Lago Calmo")
		local en = locale:format("en", assert(key, "clave"), args)
		expect(en).toContain("[VIP] Ana")
		expect(en).toContain("MYTHIC")
		expect(en).toContain("Moon Koi")
		expect(en).toContain("Calm Lake")
		local plainKey, plainArgs = locale:sanitizeMessage(banner(false))
		expect(string.find(locale:format("es", assert(plainKey, "clave"), plainArgs), "[VIP]", 1, true)).toBeNil()
	end)

	it("failureKey da la clave del motivo de jugador y oculta los tecnicos", function()
		expect(ClientLogic.failureKey("inventory-full")).toBe("fail.inventory-full")
		expect(locale:format("es", assert(ClientLogic.failureKey("inventory-full")))).toContain("Mochila llena")
		expect(locale:format("en", assert(ClientLogic.failureKey("inventory-full")))).toContain("bag is full")
		expect(ClientLogic.failureKey("too-early")).toBeNil()
		expect(ClientLogic.failureKey("no-cast")).toBeNil()
		expect(ClientLogic.failureKey("impossible-time")).toBeNil()
	end)

	it("ningun texto de fallo usa lenguaje de presion (ES y EN) y todos existen, incluido 'maxed'", function()
		for _, reason in ClientLogic.FAILURE_REASONS do
			for _, language in { "es", "en" } do
				local text = locale:raw("fail." .. reason, language)
				expect(text).toBeTruthy()
				expect(Shop.findPressureLanguage(locale:format(language, "fail." .. reason))).toBeNil()
			end
		end
		expect(ClientLogic.failureKey("maxed")).toBe("fail.maxed")
	end)
end)

describe("ClientLogic.localizeOddsView: las mismas cifras en todos los idiomas", function()
	local rules = FishingRules.new(Balance, Odds)

	local function digits(text)
		return (string.gsub(text, "%D", ""))
	end

	local function numeric(percentText)
		-- "12,34 %" / "12.34%" -> 12.34
		local cleaned = string.gsub(string.gsub(percentText, "[%s%%]", ""), ",", ".")
		return tonumber(cleaned)
	end

	it("cada zona y suerte: mismos digitos, suma exactamente 100 y nombres localizados", function()
		for _, zoneId in Balance.zoneOrder do
			for _, luck in { 0, 0.5, 2.6, 8 } do
				local views = {}
				for _, language in { "es", "en" } do
					views[language] = ClientLogic.localizeOddsView(
						rules:oddsFor(zoneId):displayRows({ luck = luck }),
						locale,
						language
					)
				end
				local raw = rules:oddsFor(zoneId):displayRows({ luck = luck })
				expect(#views.es.rows).toBe(#views.en.rows)
				local sumEs, sumEn = 0, 0
				for index, row in raw.rows do
					local es, en = views.es.rows[index], views.en.rows[index]
					expect(digits(es.percentText)).toBe(digits(row.percentText))
					expect(digits(en.percentText)).toBe(digits(row.percentText))
					expect(digits(es.basePercentText)).toBe(digits(row.basePercentText))
					expect(digits(en.basePercentText)).toBe(digits(row.basePercentText))
					expect(es.label).toBe(locale:format("es", "creature." .. row.id))
					expect(en.label).toBe(locale:format("en", "creature." .. row.id))
					sumEs += numeric(es.percentText)
					sumEn += numeric(en.percentText)
				end
				expect(math.abs(sumEs - 100) < 1e-6).toBe(true)
				expect(math.abs(sumEn - 100) < 1e-6).toBe(true)
				expect(digits(views.es.totalPercentText)).toBe(digits(raw.totalPercentText))
				expect(digits(views.en.totalPercentText)).toBe(digits(raw.totalPercentText))
			end
		end
	end)

	it("solo cambian los separadores: ES usa coma y espacio antes de %, EN punto", function()
		local raw = rules:oddsFor("lake"):displayRows({ luck = 0 })
		local es = ClientLogic.localizeOddsView(rules:oddsFor("lake"):displayRows({ luck = 0 }), locale, "es")
		local en = ClientLogic.localizeOddsView(rules:oddsFor("lake"):displayRows({ luck = 0 }), locale, "en")
		expect(raw.rows[1].percentText).toContain(".")
		expect(es.rows[1].percentText).toContain(",")
		expect(es.rows[1].percentText).toContain(" %")
		expect(en.rows[1].percentText).toBe(raw.rows[1].percentText)
		expect(es.totalPercentText).toBe("100,00 %")
		expect(en.totalPercentText).toBe("100.00%")
	end)
end)
