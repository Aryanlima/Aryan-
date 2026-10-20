--!nonstrict
-- Integracion de la monetizacion de Fish & Fortune: Data + Shop + GameLogic + Catalog con los mocks del testkit.
local testkit = require("@testkit")
local Mocks = require("@testkit/mocks")
local Balance = require("../src/shared/Balance")
local FishingRules = require("../src/shared/FishingRules")
local GameLogic = require("../src/server/GameLogic")
local Catalog = require("../src/server/Catalog")
local Data = require("../../../packages/Data")
local Shop = require("../../../packages/Shop")
local Economy = require("../../../packages/Economy")
local Odds = require("../../../packages/Odds")

local describe, it, expect, beforeEach = testkit.describe, testkit.it, testkit.expect, testkit.beforeEach

local USER = 4242
local KEY = "Player_4242"

local FAKE_IDS = {
	passes = {
		auto_fish = 1,
		double_coins = 2,
		luck_plus = 3,
		starter = 4,
		vip = 5,
		season_pass = 6,
	},
	products = {
		lucky_bait_15 = 11,
		coin_boost_15 = 12,
		coin_pack_small = 13,
		coin_pack_medium = 14,
		coin_pack_large = 15,
		pearl_pack = 16,
		slot_pack = 17,
	},
}

describe("Monetizacion de Fish & Fortune (integracion)", function()
	local env, store, manager, shop, logic, policyRestricted, flags

	local function join()
		local player = env.Players:AddPlayer(USER, "Alice")
		local profile = assert(manager:load(USER))
		return player, profile
	end

	local function build(featureFlags)
		flags = featureFlags
		env = Mocks.new()
		store = env.DataStoreService:GetDataStore("FF_PlayerData")
		policyRestricted = false
		local template = GameLogic.template()
		for key, value in Shop.DATA_TEMPLATE do
			template[key] = value
		end
		manager = Data.new({
			dataStore = store,
			schema = { version = 1, template = template },
			jobId = "JOB-A",
			now = env.clock.osTime,
			task = env.task,
			random = function()
				return 0
			end,
			log = function() end,
			retry = { attempts = 2, baseDelay = 1, maxDelay = 1 },
		})
		logic = GameLogic.new({
			balance = Balance,
			rules = FishingRules.new(Balance, Odds),
			economy = Economy,
			rng = function()
				return 0.5
			end,
			clock = env.clock.time,
			flags = flags,
		})
		shop = Shop.new({
			catalog = Catalog.build(FAKE_IDS, Balance, flags),
			marketplace = env.MarketplaceService,
			players = env.Players,
			decision = env.Enum.ProductPurchaseDecision,
			policy = {
				GetPolicyInfoForPlayerAsync = function()
					return { ArePaidRandomItemsRestricted = policyRestricted }
				end,
			},
			waitForProfile = function(userId, timeout)
				return manager:waitForProfile(userId, timeout)
			end,
			grants = logic:shopHandlers(env.clock.osTime),
			task = env.task,
			now = env.clock.osTime,
			random = function()
				return 0
			end,
			log = function() end,
			profileWaitSeconds = 5,
		})
		shop:start()
	end

	-- v1: la suerte de pago esta APAGADA por defecto. Los tests de suerte la encienden con build(ON).
	local OFF = { paidLuckEnabled = false }
	local ON = { paidLuckEnabled = true }

	beforeEach(function()
		build(OFF)
	end)

	it("pack de monedas: se concede una vez, se guarda y es idempotente", function()
		local player = join()
		local receipt, decision = env.MarketplaceService:SimulatePurchase(player, FAKE_IDS.products.coin_pack_small)
		expect(decision).toBe(env.Enum.ProductPurchaseDecision.PurchaseGranted)
		expect(store:_peek(KEY).data.wallet.coins).toBe(Balance.products.coinPackSmall.coins)
		env.MarketplaceService:SimulateRedelivery(receipt.PurchaseId)
		expect(store:_peek(KEY).data.wallet.coins).toBe(Balance.products.coinPackSmall.coins)
	end)

	it("si el DataStore falla no se confirma, y al reintentar se concede exactamente una vez", function()
		local player = join()
		env.DataStoreService:FailNext(2, { op = "UpdateAsync" })
		local _, decision = env.MarketplaceService:SimulatePurchase(player, FAKE_IDS.products.coin_pack_medium)
		expect(decision).toBe(env.Enum.ProductPurchaseDecision.NotProcessedYet)
		expect(env.MarketplaceService:RetryPending()).toBe(1)
		expect(store:_peek(KEY).data.wallet.coins).toBe(Balance.products.coinPackMedium.coins)
	end)

	it("[v1.5, flag ON] Cebo de Suerte: concede el boost y su suerte cuenta en la tabla de odds", function()
		build(ON)
		local player, profile = join()
		env.MarketplaceService:SimulatePurchase(player, FAKE_IDS.products.lucky_bait_15)
		local now = env.clock.osTime()
		local ctx = { passes = {}, events = {}, paidRandomAllowed = true, now = now }
		local luck = logic:luck(profile.data, ctx)
		expect(luck).toBe(Balance.rods.driftwood.luck + Balance.products.luckyBait.luck)
		-- expira: tras 15 min deja de contar
		env.clock:advance(Balance.products.luckyBait.seconds + 1)
		ctx.now = env.clock.osTime()
		expect(logic:luck(profile.data, ctx)).toBe(Balance.rods.driftwood.luck)
	end)

	it("[v1.5, flag ON] con objetos aleatorios de pago restringidos: no se ofrece el Cebo ni suma suerte", function()
		build(ON)
		policyRestricted = true
		local player, profile = join()
		local ok, reason = shop:promptProduct(player, "lucky_bait_15")
		expect(ok).toBe(false)
		expect(reason).toBe("restricted")
		expect(select(2, shop:promptPass(player, "luck_plus"))).toBe("restricted")
		-- boost ya concedido antes de que cambiara la politica: no cuenta
		profile.data.boosts.lucky_bait = env.clock.osTime() + 600
		local ctx = { passes = { luck_plus = true }, events = {}, paidRandomAllowed = false, now = env.clock.osTime() }
		expect(logic:luck(profile.data, ctx)).toBe(Balance.rods.driftwood.luck)
		-- los productos que no alteran azar siguen disponibles
		policyRestricted = true
		expect((shop:promptProduct(player, "coin_pack_small"))).toBe(true)
	end)

	it("pack de inicio (pase): se concede una sola vez aunque se cargue varias veces", function()
		local player, profile = join()
		env.MarketplaceService:GrantGamePass(USER, FAKE_IDS.passes.starter)
		shop:loadPlayer(player)
		shop:loadPlayer(player)
		expect(profile.data.wallet.coins).toBe(Balance.products.starterPack.coins)
		expect(profile.data.wallet.pearls).toBe(Balance.products.starterPack.pearls)
		expect(profile.data.extraSlots).toBe(Balance.products.starterPack.slots)
	end)

	it("pase 2x Dinero: duplica la venta y se suma (no multiplica) con el VIP", function()
		local player, profile = join()
		env.MarketplaceService:GrantGamePass(USER, FAKE_IDS.passes.double_coins)
		env.MarketplaceService:GrantGamePass(USER, FAKE_IDS.passes.vip)
		shop:loadPlayer(player)
		local ctx = {
			passes = {
				double_coins = shop:ownsPass(player, "double_coins"),
				vip = shop:ownsPass(player, "vip"),
			},
			events = {},
			paidRandomAllowed = true,
			now = env.clock.osTime(),
		}
		profile.data.inventory = { carp = 10 } -- 180
		local earned = logic:sellAll(profile.data, ctx)
		expect(earned).toBe(Economy.round(180 * 2.1))
	end)

	it("slots: el producto suma espacio; al llegar al tope se convierte en perlas (no se pierde el pago)", function()
		local player, profile = join()
		local maxExtra = Balance.inventory.maxSlots - Balance.inventory.baseSlots
		profile.data.extraSlots = maxExtra
		env.MarketplaceService:SimulatePurchase(player, FAKE_IDS.products.slot_pack)
		expect(profile.data.extraSlots).toBe(maxExtra)
		expect(profile.data.wallet.pearls).toBe(Balance.products.slotPack.slots)
	end)

	it("[v1.5, flag ON] la tienda muestra las ofertas del jugador con motivos neutros", function()
		build(ON)
		local player = join()
		policyRestricted = true
		local offers = shop:getOffers(player)
		local byKey = {}
		for _, offer in offers do
			byKey[offer.key] = offer
		end
		expect(byKey.lucky_bait_15.available).toBe(false)
		expect(byKey.lucky_bait_15.reason).toBe("restricted")
		expect(byKey.coin_pack_small.available).toBe(true)
		expect(#offers).toBe(13)
	end)
	describe("v1: suerte de pago APAGADA (FeatureFlags.paidLuckEnabled = false)", function()
		it("Suerte+ y Cebo de Suerte NO aparecen en la tienda", function()
			local player = join()
			policyRestricted = false -- aunque la politica lo permitiera
			local keys = {}
			for _, offer in shop:getOffers(player) do
				keys[offer.key] = true
			end
			expect(keys.luck_plus).toBeNil()
			expect(keys.lucky_bait_15).toBeNil()
			expect(keys.coin_pack_small).toBe(true)
			expect(#shop:getOffers(player)).toBe(11) -- 13 menos los 2 apagados
		end)

		it("ningun texto de la tienda menciona suerte comprable", function()
			local player = join()
			for _, offer in shop:getOffers(player) do
				local text = string.lower(offer.name .. " " .. offer.description)
				expect(string.find(text, "suerte", 1, true)).toBeNil()
				expect(string.find(text, "probabilidad", 1, true)).toBeNil()
			end
		end)

		it("no se pueden comprar: los prompts se rechazan como no disponibles", function()
			local player = join()
			policyRestricted = false
			expect(select(2, shop:promptProduct(player, "lucky_bait_15"))).toBe("unavailable")
			expect(select(2, shop:promptPass(player, "luck_plus"))).toBe("unavailable")
			expect(#env.MarketplaceService.prompts).toBe(0)
		end)

		it("un recibo ANTIGUO del Cebo se rechaza de forma segura: no concede, no se confirma, no se pierde", function()
			local player, profile = join()
			local receipt, decision = env.MarketplaceService:SimulatePurchase(player, FAKE_IDS.products.lucky_bait_15)
			expect(decision).toBe(env.Enum.ProductPurchaseDecision.NotProcessedYet)
			expect(profile.data.boosts.lucky_bait).toBeNil()
			expect(profile.data.purchases[receipt.PurchaseId]).toBeNil()
			-- sigue pendiente (Roblox lo volvera a entregar): ni regalado ni consumido
			expect(env.MarketplaceService:GetReceiptStatus(receipt.PurchaseId)).toBe("pending")
			expect(env.MarketplaceService:RetryPending()).toBe(0)
			-- y los demas productos siguen funcionando con normalidad
			local _, ok = env.MarketplaceService:SimulatePurchase(player, FAKE_IDS.products.coin_pack_small)
			expect(ok).toBe(env.Enum.ProductPurchaseDecision.PurchaseGranted)
		end)

		it("aunque el jugador ya tuviera el pase Suerte+, no cuenta ni se consulta su propiedad", function()
			local player, profile = join()
			env.MarketplaceService:GrantGamePass(USER, FAKE_IDS.passes.luck_plus)
			shop:loadPlayer(player)
			expect(shop:ownsPass(player, "luck_plus")).toBe(false)
			local ctx = {
				passes = { luck_plus = shop:ownsPass(player, "luck_plus") },
				events = {},
				paidRandomAllowed = true,
				now = env.clock.osTime(),
			}
			expect(logic:luck(profile.data, ctx)).toBe(Balance.rods.driftwood.luck)
		end)

		it("la UI de probabilidades muestra las odds base (sin fuentes de pago)", function()
			local player, profile = join()
			env.MarketplaceService:GrantGamePass(USER, FAKE_IDS.passes.luck_plus)
			profile.data.boosts.lucky_bait = env.clock.osTime() + 600
			shop:loadPlayer(player)
			local ctx = { passes = {}, events = {}, paidRandomAllowed = true, now = env.clock.osTime() }
			local luck, sources = logic:luck(profile.data, ctx)
			local rules = FishingRules.new(Balance, Odds)
			local view = rules:oddsFor("lake"):displayRows({ luck = luck })
			expect(view.luckActive).toBe(false)
			for _, source in sources do
				expect(source.paid).toBe(false)
			end
		end)

		it(
			"el resto de la monetizacion de la v1 sigue operativa (pack de inicio, 2x, VIP, slots, temporada)",
			function()
				local player = join()
				policyRestricted = true -- da igual: nada de lo demas depende de la politica de azar
				for _, key in { "coin_pack_small", "coin_boost_15", "slot_pack", "pearl_pack" } do
					expect((shop:promptProduct(player, key))).toBe(true)
					env.clock:advance(5)
				end
				for _, key in { "auto_fish", "double_coins", "starter", "vip", "season_pass" } do
					expect((shop:promptPass(player, key))).toBe(true)
					env.clock:advance(5)
				end
			end
		)
	end)
end)
