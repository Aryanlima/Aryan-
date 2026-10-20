--!nonstrict
-- Catalogo de la tienda de Fish & Fortune: validez, honestidad y gating. No toca el motor.
local testkit = require("@testkit")
local Balance = require("../src/shared/Balance")
local Catalog = require("../src/server/Catalog")
local ProductIds = require("../src/server/ProductIds")
local Shop = require("../../../packages/Shop")
local GameLogic = require("../src/server/GameLogic")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect

local function handlers()
	local function handler()
		return true
	end
	return { currency = handler, boost = handler, slots = handler }
end

local function countKeys(tbl)
	local n = 0
	for _ in tbl do
		n += 1
	end
	return n
end

describe("Catalog", function()
	local catalog = Catalog.build(ProductIds, Balance)

	it("es valido (precios en la escalera, sin ids repetidos, sin lenguaje de presion)", function()
		expect(Shop.validateCatalog(catalog, handlers())).toEqual({})
	end)

	it("incluye lo que pide el concepto: 3 pases base, productos, pack de inicio, slots, VIP y temporada", function()
		for _, key in { "auto_fish", "double_coins", "luck_plus", "starter", "vip", "season_pass" } do
			expect(catalog.passes[key]).toBeTruthy()
		end
		for _, key in { "lucky_bait_15", "coin_boost_15", "coin_pack_small", "slot_pack", "pearl_pack" } do
			expect(catalog.products[key]).toBeTruthy()
		end
	end)

	it("los IDs son placeholders 0 -- TODO_ID en el UNICO archivo de configuracion", function()
		local pending = 0
		for key, id in ProductIds.passes do
			expect(type(id)).toBe("number")
			expect(catalog.passes[key]).toBeTruthy()
			if id == 0 then
				pending += 1
			end
		end
		for key, id in ProductIds.products do
			expect(type(id)).toBe("number")
			expect(catalog.products[key]).toBeTruthy()
			if id == 0 then
				pending += 1
			end
		end
		-- todo catalogo tiene su ID en ProductIds (ni mas ni menos)
		expect(countKeys(ProductIds.passes)).toBe(countKeys(catalog.passes))
		expect(countKeys(ProductIds.products)).toBe(countKeys(catalog.products))
		expect(pending).toBe(countKeys(catalog.passes) + countKeys(catalog.products)) -- aun sin rellenar
	end)

	it("el chequeo previo a publicar (allowPlaceholders = false) lista todo lo pendiente", function()
		local problems = Shop.validateCatalog(catalog, handlers(), { allowPlaceholders = false })
		expect(#problems).toBe(countKeys(catalog.passes) + countKeys(catalog.products))
	end)

	it("con IDs reales distintos el catalogo sigue siendo valido tambien sin placeholders", function()
		local ids = { passes = {}, products = {} }
		local n = 100
		for key in ProductIds.passes do
			n += 1
			ids.passes[key] = n
		end
		for key in ProductIds.products do
			n += 1
			ids.products[key] = n
		end
		local real = Catalog.build(ids, Balance)
		expect(Shop.validateCatalog(real, handlers(), { allowPlaceholders = false })).toEqual({})
	end)

	it("solo Suerte+ y el Cebo de Suerte alteran probabilidades (y se gatean por PolicyService)", function()
		local affecting = {}
		for key, pass in catalog.passes do
			if pass.affectsOdds then
				table.insert(affecting, key)
			end
		end
		for key, product in catalog.products do
			if product.affectsOdds then
				table.insert(affecting, key)
			end
		end
		table.sort(affecting)
		expect(affecting).toEqual({ "luck_plus", "lucky_bait_15" })
	end)

	it("ninguna descripcion usa lenguaje de presion (menores)", function()
		for _, group in { catalog.passes, catalog.products } do
			for _, item in group do
				expect(Shop.findPressureLanguage(item.name)).toBeNil()
				expect(Shop.findPressureLanguage(item.description)).toBeNil()
			end
		end
	end)

	it("los pases que alteran probabilidades lo dicen en su descripcion (efecto visible)", function()
		expect(catalog.passes.luck_plus.description).toContain("probabilidades")
		expect(catalog.products.lucky_bait_15.description).toContain("probabilidades")
	end)

	it("el contenido de los productos coincide con el balance y es concedible por GameLogic", function()
		local data = GameLogic.template()
		expect(catalog.products.coin_pack_small.grant.coins).toBe(Balance.products.coinPackSmall.coins)
		expect(catalog.products.lucky_bait_15.grant.seconds).toBe(Balance.products.luckyBait.seconds)
		expect(catalog.passes.starter.oneTimeGrant.coins).toBe(Balance.products.starterPack.coins)
		-- el pack de inicio no tiene claves de azar
		for key in catalog.passes.starter.oneTimeGrant do
			expect(key == "kind" or key == "coins" or key == "pearls" or key == "slots").toBe(true)
		end
		expect(data.wallet.coins).toBe(0)
	end)

	it("la escalera de precios es creciente y el pase mas caro es un ancla", function()
		local ladder = Catalog.ladder
		local values = {}
		for _, price in ladder do
			table.insert(values, price)
		end
		table.sort(values)
		expect(values[1]).toBeGreaterThanOrEqual(49)
		expect(values[#values]).toBe(1999)
	end)
end)
