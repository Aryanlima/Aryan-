--!nonstrict
--[[
	Cableado de IDs de pases y productos (sin Studio, sin Robux):
	  * el codigo REAL de GameService con IDs distintos de los de prueba: cada clave abre SU prompt, SU recibo concede SU
	    efecto y SU pase se reconoce (IdWiringChecks);
	  * el alias opcional `passAssetIds` (REVIEW(money): TargetId frente a assetId de un pase);
	  * el contrato con ROBLOX/tools/wire-ids.mjs (claves apagadas, ids.example.json).
	La misma bateria corre con los IDs REALES en ReleaseGate.spec.luau cuando FF_RELEASE_CHECK=1.
]]
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local testkit = require("@testkit")
local Mocks = require("@testkit/mocks")
local Balance = require("../src/shared/Balance")
local Catalog = require("../src/server/Catalog")
local FeatureFlags = require("../src/shared/FeatureFlags")
local ProductIds = require("../src/server/ProductIds")
local IdWiringChecks = require("./support/IdWiringChecks")
local Shop = require("../../../packages/Shop")
local StoreItems = require("../../../tools/store-items")

local describe, it, expect, beforeEach = testkit.describe, testkit.it, testkit.expect, testkit.beforeEach

local HERE = (debug.info(1, "s") :: string):gsub("[^/\\]+$", "")

-- Se calcula ANTES del primer describe (acceso a disco). Es lo que debe contener store-items.json.
local EXPECTED_STORE_ITEMS = serde.decode("json", serde.encode("json", StoreItems.build()))
local STORE_ITEMS_FILE = fs.readFile(HERE .. "../store-items.json")

-- IDs sinteticos con aspecto real (10 digitos), distintos de los FAKE_IDS del arnes. Suerte+ y Cebo apagados (0).
local function syntheticIds()
	return {
		passes = {
			auto_fish = 7000000001,
			double_coins = 7000000002,
			luck_plus = 0,
			starter = 7000000003,
			vip = 7000000004,
			season_pass = 7000000005,
			golden_rod = 7000000006,
			bubble_trail = 7000000007,
		},
		products = {
			lucky_bait_15 = 0,
			coin_boost_15 = 7000000011,
			coin_pack_small = 7000000012,
			coin_pack_medium = 7000000013,
			coin_pack_large = 7000000014,
			pearl_pack = 7000000015,
			slot_pack = 7000000016,
		},
		passAssetIds = {},
	}
end

local function sortedKeys(map)
	local keys = {}
	for key in map do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end

describe("Cableado de IDs con el codigo real del servidor (IDs sinteticos)", function()
	it("cada clave habilitada abre el prompt con SU ID (7 pases + 6 productos)", function()
		expect(IdWiringChecks.checkPrompts(syntheticIds(), expect)).toBe(13)
	end)

	it("cada recibo concede SOLO el efecto de su producto, una vez, y se guarda", function()
		expect(IdWiringChecks.checkReceipts(syntheticIds(), expect)).toBe(6)
	end)

	it("tener un pase (por su ID) activa SOLO ese pase", function()
		expect(IdWiringChecks.checkPassOwnership(syntheticIds(), expect)).toBe(7)
	end)

	it(
		"con alias (assetId distinto del TargetId): el evento del prompt con el alias activa el pase correcto",
		function()
			local ids = syntheticIds()
			ids.passAssetIds = { vip = 9100000104, auto_fish = 9100000101 }
			expect(IdWiringChecks.checkAliases(ids, expect)).toBe(2)
			expect(IdWiringChecks.checkPrompts(ids, expect)).toBe(13) -- el prompt sigue usando el ID principal, nunca el alias
		end
	)

	it("los objetos apagados (Suerte+, Cebo) con ID 0 no se ofrecen y no rompen nada", function()
		local ids = syntheticIds()
		local catalog = Catalog.build(ids, Balance, FeatureFlags)
		expect(catalog.passes.luck_plus.enabled).toBe(false)
		expect(catalog.products.lucky_bait_15.enabled).toBe(false)
		expect(Shop.validateCatalog(catalog, nil, { allowPlaceholders = false })).toEqual({})
	end)
end)

describe("Alias de pase (passAssetIds): catalogo y validacion", function()
	it("Catalog.build copia el alias al pase y no toca los productos", function()
		local ids = syntheticIds()
		ids.passAssetIds = { vip = 9100000104 }
		local catalog = Catalog.build(ids, Balance, FeatureFlags)
		expect(catalog.passes.vip.assetId).toBe(9100000104)
		expect(catalog.passes.vip.id).toBe(7000000004)
		expect(catalog.passes.auto_fish.assetId).toBeNil()
		expect(Shop.validateCatalog(catalog, nil, { allowPlaceholders = false })).toEqual({})
	end)

	it("sin la tabla passAssetIds todo funciona igual (compatibilidad con los IDs de prueba del arnes)", function()
		local ids = syntheticIds()
		ids.passAssetIds = nil
		local catalog = Catalog.build(ids, Balance, FeatureFlags)
		expect(catalog.passes.vip.assetId).toBeNil()
	end)

	it("una clave de alias que no existe en passes queda como problema visible y NO se ofrece en la tienda", function()
		local ids = syntheticIds()
		ids.passAssetIds = { vipp = 9100000104 }
		local catalog = Catalog.build(ids, Balance, FeatureFlags)
		local problems = Shop.validateCatalog(catalog, nil, { allowPlaceholders = false })
		expect(#problems >= 1).toBe(true)
		local found = false
		for _, problem in problems do
			if string.find(problem, "assetId", 1, true) then
				found = true
			end
		end
		expect(found).toBe(true)
		expect(catalog.passes.unknown_asset_alias_vipp.enabled).toBe(false)
	end)

	it("validateCatalog detecta alias repetidos, iguales al id, invalidos o de un pase sin id", function()
		local function problemsFor(mutate)
			local ids = syntheticIds()
			ids.passAssetIds = {}
			local catalog = Catalog.build(ids, Balance, FeatureFlags)
			mutate(catalog)
			return table.concat(Shop.validateCatalog(catalog, nil, { allowPlaceholders = false }), "\n")
		end
		expect(problemsFor(function(c)
			c.passes.vip.assetId = c.passes.auto_fish.id -- choca con el ID de OTRO pase
		end)).toMatch("repetido")
		expect(problemsFor(function(c)
			c.passes.vip.assetId = c.products.pearl_pack.id -- choca con un producto
		end)).toMatch("repetido")
		expect(problemsFor(function(c)
			c.passes.vip.assetId = c.passes.vip.id
		end)).toMatch("igual al id")
		expect(problemsFor(function(c)
			c.passes.vip.assetId = -4
		end)).toMatch("assetId invalido")
		expect(problemsFor(function(c)
			c.passes.vip.assetId = 1.5
		end)).toMatch("assetId invalido")
		expect(problemsFor(function(c)
			c.passes.luck_plus.assetId = 9100000999 -- su id es 0
		end)).toMatch("id esta en 0")
		expect(problemsFor(function(_c) end)).toBe("")
	end)

	describe("Shop con alias", function()
		local env
		local logs

		local function newShop(catalog)
			return Shop.new({
				catalog = catalog,
				marketplace = env.MarketplaceService,
				players = env.Players,
				decision = env.Enum.ProductPurchaseDecision,
				infoTypes = { Product = env.Enum.InfoType.Product, GamePass = env.Enum.InfoType.GamePass },
				waitForProfile = function()
					return nil
				end,
				grants = {},
				task = env.task,
				now = env.clock.osTime,
				log = function(message)
					table.insert(logs, message)
				end,
			})
		end

		beforeEach(function()
			env = Mocks.new()
			logs = {}
			env.MarketplaceService.GetProductInfoAsync = function(self, id, infoType)
				return self:GetProductInfo(id, infoType)
			end
		end)

		it("Shop.new se niega a arrancar si un alias pisa el ID de otro pase (conceder el pase equivocado)", function()
			local ids = syntheticIds()
			ids.passAssetIds = {}
			local catalog = Catalog.build(ids, Balance, FeatureFlags)
			catalog.passes.vip.assetId = catalog.passes.auto_fish.id
			expect(function()
				newShop(catalog)
			end).toThrow("repetido")
			catalog = Catalog.build(ids, Balance, FeatureFlags)
			catalog.passes.vip.assetId = 9100000104
			catalog.passes.starter.assetId = 9100000104
			expect(function()
				newShop(catalog)
			end).toThrow("assetId de pase repetido")
		end)

		it("el evento del prompt con el alias se reconoce; con un numero desconocido se ignora", function()
			local ids = syntheticIds()
			ids.passAssetIds = { vip = 9100000104 }
			local catalog = Catalog.build(ids, Balance, FeatureFlags)
			local shop = newShop(catalog)
			local player = env.Players:AddPlayer(7001, "Alice")
			env.MarketplaceService:GrantGamePass(7001, ids.passes.vip)
			shop:_onPassPromptFinished(player, 123456789, true) -- desconocido: nada, pero queda en el registro
			expect(shop:ownsPass(player, "vip")).toBe(false)
			expect(#logs).toBe(1)
			expect(logs[1]).toMatch("DESCONOCIDO: 123456789")
			shop:_onPassPromptFinished(player, 9100000104, true) -- alias: reconocido
			expect(shop:ownsPass(player, "vip")).toBe(true)
			shop:_onPassPromptFinished(player, ids.passes.auto_fish, true) -- otro pase que NO tiene (el mock dice false)
			expect(shop:ownsPass(player, "auto_fish")).toBe(false)
		end)

		it(
			"refreshPrices usa el alias como RESPALDO para mostrar el precio, nunca en lugar del ID principal",
			function()
				local ids = syntheticIds()
				ids.passAssetIds = { vip = 9100000104, auto_fish = 9100000101 }
				local catalog = Catalog.build(ids, Balance, FeatureFlags)
				local shop = newShop(catalog)
				local market = env.MarketplaceService
				-- vip: el ID principal falla y el alias existe; auto_fish: el principal existe (su alias no debe consultarse)
				market:RegisterProduct(9100000104, { Name = "VIP", PriceInRobux = 150 }, env.Enum.InfoType.GamePass)
				market:RegisterProduct(
					ids.passes.auto_fish,
					{ Name = "Auto", PriceInRobux = 250 },
					env.Enum.InfoType.GamePass
				)
				market:RegisterProduct(
					9100000101,
					{ Name = "Auto alias", PriceInRobux = 999 },
					env.Enum.InfoType.GamePass
				)
				shop:refreshPrices()
				local offers = {}
				for _, offer in shop:getOffers(env.Players:AddPlayer(7002, "Bob")) do
					offers[offer.key] = offer
				end
				expect(offers.vip.priceRobux).toBe(150)
				expect(offers.vip.priceIsApproximate).toBe(false)
				expect(offers.auto_fish.priceRobux).toBe(250)
			end
		)
	end)
end)

describe("Contrato con ROBLOX/tools/wire-ids.mjs", function()
	local function readJson(relative)
		return serde.decode("json", fs.readFile(HERE .. relative))
	end

	it("la lista GATED_KEYS de wire-ids.mjs es EXACTAMENTE el conjunto apagado por paidLuckEnabled", function()
		local source = fs.readFile(HERE .. "../../../tools/wire-ids.mjs")
		local list = string.match(source, "export const GATED_KEYS = %[(.-)%];")
		expect(list).toBeTruthy()
		local inTool = {}
		for key in string.gmatch(list, '"([%w_]+)"') do
			table.insert(inTool, key)
		end
		table.sort(inTool)

		local off = Catalog.build(syntheticIds(), Balance, { paidLuckEnabled = false })
		local disabled = {}
		for _, group in { off.passes, off.products } do
			for key, item in group do
				if item.enabled == false then
					table.insert(disabled, key)
				end
			end
		end
		table.sort(disabled)
		expect(inTool).toEqual(disabled)

		-- con el flag encendido (v1.5) nada queda apagado: wire-ids exigira IDs para todo
		local on = Catalog.build(syntheticIds(), Balance, { paidLuckEnabled = true })
		for _, group in { on.passes, on.products } do
			for _, item in group do
				expect(item.enabled ~= false).toBe(true)
			end
		end
	end)

	it(
		"ids.example.json tiene EXACTAMENTE las claves de ProductIds.luau, todas en 0 (para que falle hasta rellenarlo)",
		function()
			local example = readJson("../ids.example.json")
			expect(sortedKeys(example.passes)).toEqual(sortedKeys(ProductIds.passes))
			expect(sortedKeys(example.products)).toEqual(sortedKeys(ProductIds.products))
			for _, group in { example.passes, example.products } do
				for _, value in group do
					expect(value).toBe(0)
				end
			end
		end
	)

	it("ProductIds.luau tiene la tabla passAssetIds (vacia o con claves de pases existentes) y IDs enteros", function()
		expect(type(ProductIds.passAssetIds)).toBe("table")
		for key, assetId in ProductIds.passAssetIds do
			expect(ProductIds.passes[key] ~= nil).toBe(true)
			expect(assetId > 0 and assetId % 1 == 0).toBe(true)
		end
		for _, group in { ProductIds.passes, ProductIds.products } do
			for _, id in group do
				expect(id >= 0 and id % 1 == 0).toBe(true)
			end
		end
	end)
end)

describe("store-items.json (lo que hay que crear en Creator Hub)", function()
	it(
		"coincide con el codigo: si cambia el catalogo o los textos, regenerar con `lune run ROBLOX/tools/dump-store-items.luau`",
		function()
			expect(serde.decode("json", STORE_ITEMS_FILE)).toEqual(EXPECTED_STORE_ITEMS)
		end
	)

	it(
		"lista exactamente los 7 pases y 6 productos habilitados (sin Suerte+ ni Cebo), con precio entero e icono",
		function()
			local keys = {}
			for _, item in EXPECTED_STORE_ITEMS.items do
				table.insert(keys, item.kind .. ":" .. item.key)
				expect(item.price > 0 and item.price % 1 == 0).toBe(true)
				expect(item.icon ~= nil).toBe(true) -- hay arte para todo lo habilitado
				expect(item.name.en ~= "" and item.name.es ~= "").toBe(true)
			end
			table.sort(keys)
			expect(keys).toEqual({
				"pass:auto_fish",
				"pass:bubble_trail",
				"pass:double_coins",
				"pass:golden_rod",
				"pass:season_pass",
				"pass:starter",
				"pass:vip",
				"product:coin_boost_15",
				"product:coin_pack_large",
				"product:coin_pack_medium",
				"product:coin_pack_small",
				"product:pearl_pack",
				"product:slot_pack",
			})
		end
	)
end)
