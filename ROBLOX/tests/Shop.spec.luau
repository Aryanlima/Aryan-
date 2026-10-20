--!nonstrict
-- Tests de packages/Shop: ProcessReceipt unico e idempotente, fallos de persistencia, jugadores que se
-- desconectan, doble recibo, pases, gating por PolicyService y validacion del catalogo.
local testkit = require("@testkit")
local Mocks = require("@testkit/mocks")
local Data = require("../packages/Data")
local Shop = require("../packages/Shop")

local describe, it, expect, beforeEach = testkit.describe, testkit.it, testkit.expect, testkit.beforeEach

local function newCatalog()
	return {
		priceLadder = { basic = 99, value = 199, strong = 499, impulse = 25 },
		passes = {
			auto_fish = {
				key = "auto_fish",
				id = 111,
				name = "Pesca automatica",
				description = "Pesca sola mientras juegas.",
				tier = "strong",
			},
			luck_plus = {
				key = "luck_plus",
				id = 112,
				name = "Suerte+",
				description = "Aumenta tu suerte de forma permanente.",
				tier = "strong",
				affectsOdds = true,
			},
			starter = {
				key = "starter",
				id = 113,
				name = "Pack de inicio",
				description = "Monedas para empezar.",
				tier = "basic",
				oneTimeGrant = { kind = "currency", coins = 500 },
			},
			future_pass = {
				key = "future_pass",
				id = 0, -- TODO_ID
				name = "Pase futuro",
				description = "Aun sin crear.",
				tier = "value",
			},
		},
		products = {
			coins_small = {
				key = "coins_small",
				id = 2001,
				name = "Monedas pequenas",
				description = "100 monedas.",
				kind = "currency",
				grant = { coins = 100 },
				tier = "basic",
			},
			lucky_bait = {
				key = "lucky_bait",
				id = 2002,
				name = "Cebo de suerte",
				description = "15 minutos de suerte extra.",
				kind = "boost",
				grant = { boostId = "lucky_bait", seconds = 900 },
				tier = "impulse",
				affectsOdds = true,
			},
		},
	}
end

local USER = 1001
local KEY = "Player_1001"

describe("Shop", function()
	local env, store, manager, shop, catalog, logs
	local handlerCalls
	local grantedHooks
	local policyRestricted

	local function newGrants()
		return {
			currency = function(_, profile, product)
				handlerCalls += 1
				local coins = product.grant and product.grant.coins
				if type(coins) ~= "number" then
					return false
				end
				profile.data.coins += coins
				return true
			end,
			boost = function(_, profile, product)
				handlerCalls += 1
				profile.data.boosts[product.grant.boostId] = (profile.data.boosts[product.grant.boostId] or 0)
					+ product.grant.seconds
				return true
			end,
		}
	end

	local function newManager(jobId, overrides)
		local cfg = {
			dataStore = store,
			schema = {
				version = 1,
				template = { coins = 0, boosts = {}, purchases = {}, passGrants = {} },
			},
			jobId = jobId or "A",
			now = env.clock.osTime,
			task = env.task,
			random = function()
				return 0
			end,
			log = function(m)
				table.insert(logs, m)
			end,
			retry = { attempts = 2, baseDelay = 1, maxDelay = 1 },
			lock = { staleSeconds = 600, waitSeconds = 10, pollSeconds = 3 },
		}
		for k, v in overrides or {} do
			cfg[k] = v
		end
		return Data.new(cfg)
	end

	local function newShop(overrides)
		local cfg = {
			catalog = catalog,
			marketplace = env.MarketplaceService,
			players = env.Players,
			decision = env.Enum.ProductPurchaseDecision,
			infoTypes = { Product = env.Enum.InfoType.Product, GamePass = env.Enum.InfoType.GamePass },
			policy = {
				GetPolicyInfoForPlayerAsync = function()
					return { ArePaidRandomItemsRestricted = policyRestricted, IsPaidItemTradingAllowed = true }
				end,
			},
			waitForProfile = function(userId, timeout)
				return manager:waitForProfile(userId, timeout)
			end,
			grants = newGrants(),
			task = env.task,
			now = env.clock.osTime,
			random = function()
				return 0
			end,
			log = function(m)
				table.insert(logs, m)
			end,
			profileWaitSeconds = 5,
			onPurchaseGranted = function(player, product, receipt)
				table.insert(grantedHooks, { userId = player.UserId, key = product.key, purchaseId = receipt.PurchaseId })
			end,
		}
		for k, v in overrides or {} do
			cfg[k] = v
		end
		return Shop.new(cfg)
	end

	local function join(userId, name)
		local player = env.Players:AddPlayer(userId or USER, name or "Alice")
		local profile, reason = manager:load(player.UserId)
		assert(profile, "no se pudo cargar el perfil: " .. tostring(reason))
		return player, profile
	end

	beforeEach(function()
		env = Mocks.new()
		-- GetProductInfoAsync (la API vigente); el mock solo trae la antigua GetProductInfo.
		env.MarketplaceService.GetProductInfoAsync = function(self, id, infoType)
			return self:GetProductInfo(id, infoType)
		end
		store = env.DataStoreService:GetDataStore("PlayerData")
		logs = {}
		handlerCalls = 0
		grantedHooks = {}
		policyRestricted = false
		catalog = newCatalog()
		manager = newManager("A")
		shop = newShop()
		shop:start()
	end)

	describe("ProcessReceipt", function()
		it("concede una vez, persiste y devuelve PurchaseGranted", function()
			local player = join()
			local receipt, decision = env.MarketplaceService:SimulatePurchase(player, 2001)
			expect(decision).toBe(env.Enum.ProductPurchaseDecision.PurchaseGranted)
			local saved = store:_peek(KEY).data
			expect(saved.coins).toBe(100)
			expect(saved.purchases[receipt.PurchaseId]).toBeTruthy()
			expect(handlerCalls).toBe(1)
			expect(grantedHooks).toHaveLength(1)
		end)

		it("IDEMPOTENTE: reentregar el mismo PurchaseId no concede dos veces", function()
			local player = join()
			local receipt = env.MarketplaceService:SimulatePurchase(player, 2001)
			for _ = 1, 3 do
				local decision = env.MarketplaceService:SimulateRedelivery(receipt.PurchaseId)
				expect(decision).toBe(env.Enum.ProductPurchaseDecision.PurchaseGranted)
			end
			expect(handlerCalls).toBe(1)
			expect(store:_peek(KEY).data.coins).toBe(100)
			expect(grantedHooks).toHaveLength(1) -- el hook solo corre en la concesion real
		end)

		it("compras distintas se acumulan (mismo producto, distinto PurchaseId)", function()
			local player = join()
			env.MarketplaceService:SimulatePurchase(player, 2001)
			env.MarketplaceService:SimulatePurchase(player, 2001)
			expect(store:_peek(KEY).data.coins).toBe(200)
			expect(handlerCalls).toBe(2)
		end)

		it("FALLO DE PERSISTENCIA: devuelve NotProcessedYet y la reentrega concede UNA sola vez", function()
			local player, profile = join()
			env.DataStoreService:FailNext(2, { op = "UpdateAsync" }) -- agota los 2 intentos del guardado
			local receipt, decision = env.MarketplaceService:SimulatePurchase(player, 2001)
			expect(decision).toBe(env.Enum.ProductPurchaseDecision.NotProcessedYet)
			expect(grantedHooks).toHaveLength(0) -- nada de analitica/confirmacion antes de persistir
			expect(store:_peek(KEY).data.coins).toBe(0) -- el DataStore no lo tiene
			expect(profile.data.coins).toBe(100) -- esta en memoria, con su PurchaseId registrado
			expect(profile.data.purchases[receipt.PurchaseId]).toBeTruthy()

			-- Roblox reintenta
			local granted = env.MarketplaceService:RetryPending()
			expect(granted).toBe(1)
			expect(store:_peek(KEY).data.coins).toBe(100) -- 100, NO 200
			expect(handlerCalls).toBe(1)
			expect(grantedHooks).toHaveLength(1)
		end)

		it("fallo persistente del DataStore: nunca se confirma y nunca se duplica", function()
			local player = join()
			env.DataStoreService:FailNext(1000, { op = "UpdateAsync" })
			local receipt = env.MarketplaceService:SimulatePurchase(player, 2001)
			for _ = 1, 4 do
				expect(env.MarketplaceService:SimulateRedelivery(receipt.PurchaseId)).toBe(
					env.Enum.ProductPurchaseDecision.NotProcessedYet
				)
			end
			expect(handlerCalls).toBe(1)
			expect(env.MarketplaceService:GetReceiptStatus(receipt.PurchaseId)).toBe("pending")
		end)

		it("jugador desconectado: NotProcessedYet; al volver se concede una vez", function()
			local player, profile = join()
			profile:release()
			env.Players:RemovePlayer(player)
			local receipt, decision = env.MarketplaceService:SimulatePurchase(player, 2001)
			expect(decision).toBe(env.Enum.ProductPurchaseDecision.NotProcessedYet)
			expect(handlerCalls).toBe(0)

			join() -- vuelve a entrar
			expect(env.MarketplaceService:RetryPending()).toBe(1)
			expect(store:_peek(KEY).data.coins).toBe(100)
			expect(env.MarketplaceService:GetReceiptStatus(receipt.PurchaseId)).toBe("granted")
		end)

		it("el jugador se va tras la concesion en memoria: el guardado final conserva el PurchaseId", function()
			local player, profile = join()
			env.DataStoreService:FailNext(2, { op = "UpdateAsync" })
			local receipt, decision = env.MarketplaceService:SimulatePurchase(player, 2001)
			expect(decision).toBe(env.Enum.ProductPurchaseDecision.NotProcessedYet)
			-- se va: release() guarda el perfil (ya sin fallos) con compra y PurchaseId
			env.Players:RemovePlayer(player)
			expect(profile:release()).toBe(true)
			expect(store:_peek(KEY).data.coins).toBe(100)
			-- vuelve: la reentrega encuentra el PurchaseId guardado y NO vuelve a conceder
			join()
			expect(env.MarketplaceService:RetryPending()).toBe(1)
			expect(store:_peek(KEY).data.coins).toBe(100)
			expect(handlerCalls).toBe(1)
			expect(receipt.PurchaseId).toBeTruthy()
		end)

		it("DOBLE RECIBO simultaneo (dos servidores / dos hilos): una sola concesion", function()
			local player = join()
			env.DataStoreService:SetLatency(0.5)
			local receipt = env.MarketplaceService:CreateReceipt(player, 2001)
			local decisions = {}
			for _ = 1, 3 do
				env.task.spawn(function()
					table.insert(decisions, env.MarketplaceService:SimulateRedelivery(receipt.PurchaseId))
				end)
			end
			env.clock:advance(10)
			expect(decisions).toHaveLength(3)
			for _, decision in decisions do
				expect(decision).toBe(env.Enum.ProductPurchaseDecision.PurchaseGranted)
			end
			expect(handlerCalls).toBe(1)
			expect(store:_peek(KEY).data.coins).toBe(100)
		end)

		it("producto desconocido: NotProcessedYet, sin escribir nada", function()
			local player = join()
			local _, decision = env.MarketplaceService:SimulatePurchase(player, 999999)
			expect(decision).toBe(env.Enum.ProductPurchaseDecision.NotProcessedYet)
			expect(store:_peek(KEY).data.coins).toBe(0)
		end)

		it("handler que devuelve false / nil o lanza error: NotProcessedYet y NO se registra el PurchaseId", function()
			local player, profile = join()
			local cases = {
				function()
					return false
				end,
				function() end, -- nil
				function()
					error("boom")
				end,
			}
			for _, handler in cases do
				shop.cfg.grants.currency = handler
				local receipt, decision = env.MarketplaceService:SimulatePurchase(player, 2001)
				expect(decision).toBe(env.Enum.ProductPurchaseDecision.NotProcessedYet)
				expect(profile.data.purchases[receipt.PurchaseId]).toBeNil()
			end
			expect(profile.data.coins).toBe(0)
		end)

		it("perfil aun no cargado (o fallido): NotProcessedYet", function()
			env.Players:AddPlayer(USER, "Alice") -- jugador presente pero sin perfil (no se llamo a load)
			local player = env.Players:GetPlayerByUserId(USER)
			local _, decision = env.MarketplaceService:SimulatePurchase(player, 2001)
			expect(decision).toBe(env.Enum.ProductPurchaseDecision.NotProcessedYet)
			expect(handlerCalls).toBe(0)
		end)

		it("bloqueo de sesion perdido: NotProcessedYet y los datos del otro servidor siguen intactos", function()
			local player, profile = join()
			env.clock:advance(700)
			local other = newManager("B")
			local profileB = other:load(USER)
			profileB.data.coins = 50
			profileB:markDirty()
			profileB:save()
			local _, decision = env.MarketplaceService:SimulatePurchase(player, 2001)
			expect(decision).toBe(env.Enum.ProductPurchaseDecision.NotProcessedYet)
			expect(profile:isLost()).toBe(true)
			expect(store:_peek(KEY).data.coins).toBe(50)
		end)

		it("recibos mal formados no lanzan: NotProcessedYet", function()
			local player = join()
			local callback = env.MarketplaceService.ProcessReceipt
			local NOT_YET = env.Enum.ProductPurchaseDecision.NotProcessedYet
			expect(callback({})).toBe(NOT_YET)
			expect(callback({ PurchaseId = 5, PlayerId = player.UserId, ProductId = 2001 })).toBe(NOT_YET)
			expect(callback({ PurchaseId = "x", PlayerId = "a", ProductId = 2001 })).toBe(NOT_YET)
			expect(callback({ PurchaseId = "x", PlayerId = player.UserId, ProductId = "2001" })).toBe(NOT_YET)
			expect(handlerCalls).toBe(0)
		end)

		it("si el servicio Players falla, no lanza", function()
			local broken = newShop({
				players = {
					GetPlayerByUserId = function()
						error("players roto")
					end,
				},
			})
			local decision = broken:processReceipt({ PurchaseId = "p1", PlayerId = USER, ProductId = 2001 })
			expect(decision).toBe(env.Enum.ProductPurchaseDecision.NotProcessedYet)
		end)

		it("el historial de compras esta acotado (conserva las mas recientes)", function()
			local small = newShop({ purchaseHistorySize = 3 })
			small.cfg.marketplace.ProcessReceipt = function(receipt)
				return small:processReceipt(receipt)
			end
			local player, profile = join()
			local ids = {}
			for _ = 1, 5 do
				local receipt = env.MarketplaceService:SimulatePurchase(player, 2001)
				table.insert(ids, receipt.PurchaseId)
				env.clock:advance(2) -- tiempos distintos
			end
			local count = 0
			for _ in profile.data.purchases do
				count += 1
			end
			expect(count).toBe(3)
			expect(profile.data.purchases[ids[5]]).toBeTruthy()
			expect(profile.data.purchases[ids[1]]).toBeNil()
		end)

		it("boosts: concede el efecto del producto segun el handler del juego", function()
			local player = join()
			env.MarketplaceService:SimulatePurchase(player, 2002)
			expect(store:_peek(KEY).data.boosts.lucky_bait).toBe(900)
		end)
	end)

	describe("start", function()
		it("registra ProcessReceipt una sola vez por Shop", function()
			expect(env.MarketplaceService.ProcessReceipt).toBeTruthy()
			expect(function()
				shop:start()
			end).toThrow("ya se ejecuto")
		end)
	end)

	describe("pases", function()
		it("loadPlayer rellena la cache de propiedad y aplica la concesion unica una sola vez", function()
			local player, profile = join()
			env.MarketplaceService:GrantGamePass(USER, 111)
			env.MarketplaceService:GrantGamePass(USER, 113)
			shop:loadPlayer(player)
			expect(shop:ownsPass(player, "auto_fish")).toBe(true)
			expect(shop:ownsPass(player, "luck_plus")).toBe(false)
			expect(profile.data.coins).toBe(500)
			expect(profile.data.passGrants.starter).toBeTruthy()
			-- recargar (otra sesion/otro servidor) no vuelve a conceder
			shop:loadPlayer(player)
			expect(profile.data.coins).toBe(500)
			expect(store:_peek(KEY).data.coins).toBe(500)
		end)

		it("la concesion unica sobrevive a salir y volver a entrar", function()
			local player, profile = join()
			env.MarketplaceService:GrantGamePass(USER, 113)
			shop:loadPlayer(player)
			profile:release()
			env.Players:RemovePlayer(player)
			shop:unloadPlayer(player)
			local player2, profile2 = join()
			shop:loadPlayer(player2)
			expect(profile2.data.coins).toBe(500)
		end)

		it("reintenta UserOwnsGamePassAsync ante fallos transitorios", function()
			local player = join()
			env.MarketplaceService:GrantGamePass(USER, 111)
			env.MarketplaceService:FailNext(1)
			shop:loadPlayer(player)
			expect(shop:ownsPass(player, "auto_fish")).toBe(true)
		end)

		it("si Roblox no responde, no se asume propiedad y no se rompe nada", function()
			local player = join()
			env.MarketplaceService:GrantGamePass(USER, 111)
			env.MarketplaceService:FailNext(100)
			shop:loadPlayer(player)
			expect(shop:ownsPass(player, "auto_fish")).toBe(false)
		end)

		it("compra de un pase en la sesion: re-verifica, actualiza la cache y concede el pack una vez", function()
			local changes = {}
			local watching = newShop({
				onPassChanged = function(_, pass, owned)
					table.insert(changes, pass.key .. ":" .. tostring(owned))
				end,
			})
			shop:stop()
			watching:start()
			local player, profile = join()
			env.MarketplaceService:SimulateGamePassPurchase(player, 113) -- compra real (concede el pase)
			expect(watching:ownsPass(player, "starter")).toBe(true)
			expect(profile.data.coins).toBe(500)
			env.MarketplaceService:SimulateGamePassPurchase(player, 113) -- evento repetido
			expect(profile.data.coins).toBe(500)
			expect(changes).toEqual({ "starter:true" })
		end)

		it("un evento 'comprado' sin propiedad real (verificacion falsa) no concede nada", function()
			local player, profile = join()
			env.MarketplaceService.PromptGamePassPurchaseFinished:Fire(player, 113, true) -- sin GrantGamePass
			env.clock:flush()
			expect(shop:ownsPass(player, "starter")).toBe(false)
			expect(profile.data.coins).toBe(0)
		end)

		it("cancelar el prompt (wasPurchased = false) no cambia nada", function()
			local player = join()
			env.MarketplaceService:SimulateGamePassPurchase(player, 111, false)
			expect(shop:ownsPass(player, "auto_fish")).toBe(false)
		end)
	end)

	describe("prompts y gating", function()
		it("rechaza claves desconocidas y placeholders TODO_ID", function()
			local player = join()
			expect(select(2, shop:promptProduct(player, "no_existe"))).toBe("unknown")
			expect(select(2, shop:promptPass(player, "future_pass"))).toBe("unavailable")
			expect(#env.MarketplaceService.prompts).toBe(0)
		end)

		it("lanza el prompt de un producto valido y respeta el enfriamiento", function()
			local player = join()
			expect((shop:promptProduct(player, "coins_small"))).toBe(true)
			expect(#env.MarketplaceService.prompts).toBe(1)
			expect(env.MarketplaceService.prompts[1].id).toBe(2001)
			local ok, reason = shop:promptProduct(player, "coins_small")
			expect(ok).toBe(false)
			expect(reason).toBe("cooldown")
			env.clock:advance(5)
			expect((shop:promptProduct(player, "coins_small"))).toBe(true)
		end)

		it("no vende antes de que el perfil este cargado", function()
			local player = env.Players:AddPlayer(USER, "Alice")
			local ok, reason = shop:promptProduct(player, "coins_small")
			expect(ok).toBe(false)
			expect(reason).toBe("loading")
		end)

		it("no vende a jugadores que ya se fueron", function()
			local player = join()
			env.Players:RemovePlayer(player)
			expect(select(2, shop:promptProduct(player, "coins_small"))).toBe("left")
		end)

		it("no vuelve a ofrecer un pase ya poseido", function()
			local player = join()
			env.MarketplaceService:GrantGamePass(USER, 111)
			shop:loadPlayer(player)
			expect(select(2, shop:promptPass(player, "auto_fish"))).toBe("owned")
		end)

		it("productos que alteran probabilidades: bloqueados si PolicyService restringe o no responde", function()
			local player = join()
			policyRestricted = true
			expect(select(2, shop:promptProduct(player, "lucky_bait"))).toBe("restricted")
			expect(select(2, shop:promptPass(player, "luck_plus"))).toBe("restricted")

			-- sin datos de politica tambien se bloquea (conservador)
			local failing = newShop({
				policy = {
					GetPolicyInfoForPlayerAsync = function()
						error("sin red")
					end,
				},
			})
			expect(select(2, failing:promptProduct(player, "lucky_bait"))).toBe("restricted")
		end)

		it("productos que alteran probabilidades: permitidos si PolicyService lo permite", function()
			local player = join()
			policyRestricted = false
			expect((shop:promptProduct(player, "lucky_bait"))).toBe(true)
		end)

		it("getPolicy cachea por jugador (una sola consulta)", function()
			local calls = 0
			local counting = newShop({
				policy = {
					GetPolicyInfoForPlayerAsync = function()
						calls += 1
						return { ArePaidRandomItemsRestricted = false }
					end,
				},
			})
			local player = join()
			counting:getPolicy(player)
			counting:getPolicy(player)
			expect(calls).toBe(1)
			counting:unloadPlayer(player)
			counting:getPolicy(player)
			expect(calls).toBe(2)
		end)
	end)

	describe("ofertas y precios", function()
		it("getOffers marca disponibilidad, motivo y precio aproximado hasta consultar a Roblox", function()
			local player = join()
			policyRestricted = true
			local offers = shop:getOffers(player)
			local byKey = {}
			for _, offer in offers do
				byKey[offer.kind .. ":" .. offer.key] = offer
			end
			expect(byKey["product:coins_small"].available).toBe(true)
			expect(byKey["product:coins_small"].priceRobux).toBe(99) -- de la escalera
			expect(byKey["product:coins_small"].priceIsApproximate).toBe(true)
			expect(byKey["product:lucky_bait"].available).toBe(false)
			expect(byKey["product:lucky_bait"].reason).toBe("restricted")
			expect(byKey["pass:future_pass"].reason).toBe("unavailable")
		end)

		it("refreshPrices usa el precio real de Roblox (regional) cuando esta disponible", function()
			env.MarketplaceService:RegisterProduct(2001, { Name = "Monedas", PriceInRobux = 79 }, env.Enum.InfoType.Product)
			local player = join()
			shop:refreshPrices()
			local offers = shop:getOffers(player)
			for _, offer in offers do
				if offer.key == "coins_small" then
					expect(offer.priceRobux).toBe(79)
					expect(offer.priceIsApproximate).toBe(false)
				end
			end
		end)
	end)

	describe("catalogo", function()
		it("el catalogo de pruebas es valido", function()
			local problems = Shop.validateCatalog(newCatalog(), newGrants())
			expect(problems).toEqual({})
		end)

		it("detecta ids repetidos, precios fuera de la escalera y claves inconsistentes", function()
			local bad = newCatalog()
			bad.products.coins_small.id = 111 -- repetido con auto_fish
			bad.products.lucky_bait.priceRobux = 77 -- fuera de la escalera
			bad.passes.starter.key = "otra"
			local problems = Shop.validateCatalog(bad, newGrants())
			local text = table.concat(problems, "\n")
			expect(text).toContain("repetido")
			expect(text).toContain("fuera de la escalera")
			expect(text).toContain("no coincide")
		end)

		it("priceOverride permite precios fuera de la escalera a proposito", function()
			local custom = newCatalog()
			custom.products.lucky_bait.priceRobux = 77
			custom.products.lucky_bait.priceOverride = true
			expect(Shop.validateCatalog(custom, newGrants())).toEqual({})
		end)

		it("rechaza lenguaje de presion, descuentos falsos y countdowns", function()
			local bad = newCatalog()
			bad.products.coins_small.description = "¡ÚLTIMA OPORTUNIDAD! Solo hoy"
			bad.products.lucky_bait.discountPercent = 50
			bad.passes.auto_fish.countdown = 3600
			local text = table.concat(Shop.validateCatalog(bad, newGrants()), "\n")
			expect(text).toContain("lenguaje de presion")
			expect(text).toContain("discountPercent")
			expect(text).toContain("countdown")
		end)

		it("pases promocionados: 50-800 R$ y nunca pueden alterar probabilidades", function()
			local bad = newCatalog()
			bad.passes.auto_fish.promoted = true
			bad.passes.auto_fish.tier = "impulse" -- 25 R$ < 50
			bad.passes.luck_plus.promoted = true
			local text = table.concat(Shop.validateCatalog(bad, newGrants()), "\n")
			expect(text).toContain("50-800")
			expect(text).toContain("no puede alterar probabilidades")
		end)

		it("allowPlaceholders = false rechaza los IDs 0 (para el chequeo previo a publicar)", function()
			local problems = Shop.validateCatalog(newCatalog(), newGrants(), { allowPlaceholders = false })
			expect(table.concat(problems, "\n")).toContain("TODO_ID")
		end)

		it("exige handlers para cada kind del catalogo", function()
			local problems = Shop.validateCatalog(newCatalog(), { currency = function() end })
			expect(table.concat(problems, "\n")).toContain("no hay handler")
		end)

		it("findPressureLanguage distingue lenguaje de presion del neutro", function()
			expect(Shop.findPressureLanguage("¡ÚLTIMA OPORTUNIDAD!")).toBeTruthy()
			expect(Shop.findPressureLanguage("Solo hoy: oferta")).toBeTruthy()
			expect(Shop.findPressureLanguage("Don't miss it")).toBeTruthy()
			expect(Shop.findPressureLanguage("Ver precio")).toBeNil()
			expect(Shop.findPressureLanguage("Abrir tienda")).toBeNil()
			expect(Shop.findPressureLanguage("Pesca automatica mientras juegas")).toBeNil()
		end)

		it("la escalera de precios resuelve el escalon o el precio explicito", function()
			local cat = newCatalog()
			expect(Shop.priceForTier(cat.priceLadder, "value")).toBe(199)
			expect(Shop.resolvePrice(cat, { tier = "strong" })).toBe(499)
			expect(Shop.resolvePrice(cat, { tier = "strong", priceRobux = 450 })).toBe(450)
			expect(Shop.resolvePrice(cat, { tier = "nope" })).toBeNil()
		end)
	end)
end)
