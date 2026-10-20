--!nonstrict
--[[
	Pruebas de la revision de seguridad/correccion (2026-10-20) sobre packages/Shop (+ Data).
	  * "MUTANTE Sx": matan mutantes que sobrevivian a la suite original (pasan con el codigo original).
	  * "BUG SHOP-xx": fallaban con el codigo original; pasan con el arreglo propuesto en docs/revision-codigo-dinero.md.
]]
local testkit = require("@testkit")
local Mocks = require("@testkit/mocks")
local Data = require("../packages/Data")
local Shop = require("../packages/Shop")

local describe, it, expect, beforeEach = testkit.describe, testkit.it, testkit.expect, testkit.beforeEach

local USER = 1001
local KEY = "Player_1001"

local function newCatalog()
	return {
		priceLadder = { basic = 99, value = 199 },
		passes = {},
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
			boost = {
				key = "boost",
				id = 2002,
				name = "Boost",
				description = "Boost de monedas.",
				kind = "boost",
				grant = { boostId = "coin_boost", seconds = 900 },
				tier = "value",
			},
		},
	}
end

describe("Review: Shop", function()
	local env, store, logs, granted

	local function grants()
		return {
			currency = function(_, profile, product)
				granted += 1
				profile.data.coins += product.grant.coins
				return true
			end,
			boost = function(_, profile, product)
				granted += 1
				profile.data.boosts[product.grant.boostId] = (profile.data.boosts[product.grant.boostId] or 0)
					+ product.grant.seconds
				return true
			end,
		}
	end

	local function newManager(jobId, overrides)
		local cfg = {
			dataStore = store,
			schema = { version = 1, template = { coins = 0, boosts = {}, purchases = {}, passGrants = {} } },
			jobId = jobId,
			now = env.clock.osTime,
			task = env.task,
			random = function()
				return 0
			end,
			log = function(message)
				table.insert(logs, message)
			end,
			lock = { staleSeconds = 600, waitSeconds = 30, pollSeconds = 3 },
		}
		for key, value in overrides or {} do
			cfg[key] = value
		end
		return Data.new(cfg)
	end

	local function newShop(manager, overrides)
		local cfg = {
			catalog = newCatalog(),
			marketplace = env.MarketplaceService,
			players = env.Players,
			decision = env.Enum.ProductPurchaseDecision,
			waitForProfile = function(userId, timeout)
				return manager:waitForProfile(userId, timeout)
			end,
			grants = grants(),
			task = env.task,
			now = env.clock.osTime,
			random = function()
				return 0
			end,
			log = function(message)
				table.insert(logs, message)
			end,
		}
		for key, value in overrides or {} do
			cfg[key] = value
		end
		return Shop.new(cfg)
	end

	beforeEach(function()
		env = Mocks.new()
		store = env.DataStoreService:GetDataStore("PlayerData")
		logs = {}
		granted = 0
	end)

	it(
		"MUTANTE S9: si waitForProfile devuelve un perfil NO activo, ProcessReceipt no concede (defensa en profundidad)",
		function()
			local manager = newManager("A")
			local player = env.Players:AddPlayer(USER, "Alice")
			local profile = manager:load(USER)
			local inactive = setmetatable({
				isActive = function()
					return false
				end,
			}, { __index = profile })
			local shop = newShop(manager, {
				waitForProfile = function()
					return inactive
				end,
			})
			shop:start()
			local _, decision = env.MarketplaceService:SimulatePurchase(player, 2001)
			expect(decision).toBe(env.Enum.ProductPurchaseDecision.NotProcessedYet)
			expect(granted).toBe(0)
			expect(profile.data.coins).toBe(0)
		end
	)

	it(
		"BUG SHOP-02: compra justo al cambiar de servidor: ProcessReceipt espera el traspaso del bloqueo (> 20 s)",
		function()
			-- Servidor A aun tiene el perfil y lo libera a los 25 s (DataStore lento). El jugador ya esta en B y Roblox
			-- entrega el recibo al entrar. Con la espera por defecto de 20 s el recibo quedaba SIN RESOLVER hasta que el
			-- jugador volviera a entrar o comprara otra cosa (ProcessReceipt no tiene reintento por tiempo).
			local managerA = newManager("A")
			local profileA = managerA:load(USER)
			local managerB = newManager("B")
			local player = env.Players:AddPlayer(USER, "Alice", { fire = false })
			env.task.delay(25, function()
				profileA:release()
			end)
			env.task.spawn(function()
				managerB:load(USER)
			end)
			local shop = newShop(managerB) -- SIN profileWaitSeconds: se usa el valor por defecto
			shop:start()
			local _, decision = env.MarketplaceService:SimulatePurchase(player, 2001)
			expect(decision).toBe(env.Enum.ProductPurchaseDecision.PurchaseGranted)
			expect(store:_peek(KEY).data.coins).toBe(100)
			expect(granted).toBe(1)
		end
	)

	it(
		"BUG SHOP-04: dos productos con el MISMO id => Shop.new falla (un recibo concederia el producto equivocado)",
		function()
			local catalog = newCatalog()
			catalog.products.boost.id = 2001 -- copia/pega: mismo ID que coins_small
			local manager = newManager("A")
			local ok, err = pcall(newShop, manager, { catalog = catalog })
			expect(ok).toBe(false)
			expect(tostring(err)).toContain("repetido")
		end
	)

	it(
		"BUG SHOP-05: canPurchase veta lo que el jugador pagaria sin recibir todo su valor (antes del prompt)",
		function()
			local manager = newManager("A")
			local player = env.Players:AddPlayer(USER, "Alice")
			manager:load(USER)
			local blocked = true
			local shop = newShop(manager, {
				canPurchase = function(_player, _profile, item)
					if item.key == "boost" and blocked then
						return false, "maxed"
					end
					return true, nil
				end,
			})
			shop:start()
			local ok, reason = shop:promptProduct(player, "boost")
			expect(ok).toBe(false)
			expect(reason).toBe("maxed")
			blocked = false
			env.clock:advance(10)
			expect((shop:promptProduct(player, "boost"))).toBe(true)
			-- un gancho que lanza error => no se vende
			local crashing = newShop(manager, {
				canPurchase = function()
					error("boom")
				end,
			})
			local okCrash, reasonCrash = crashing:canOffer(player, "product", "coins_small")
			expect(okCrash).toBe(false)
			expect(reasonCrash).toBe("unavailable")
		end
	)

	describe("BUG PASS-01: la consulta de propiedad de un pase fallo al entrar", function()
		local function passCatalog()
			local catalog = newCatalog()
			catalog.passes.starter = {
				key = "starter",
				id = 3001,
				name = "Pack de inicio",
				description = "Monedas para empezar.",
				tier = "basic",
				oneTimeGrant = { kind = "currency", coins = 500 },
			}
			return catalog
		end

		local function setup(changes)
			local manager = newManager("A")
			local player = env.Players:AddPlayer(USER, "Alice")
			local profile = manager:load(USER)
			local shop = newShop(manager, {
				catalog = passCatalog(),
				onPassChanged = function(_, pass, owned)
					table.insert(changes, pass.key .. ":" .. tostring(owned))
				end,
			})
			shop:start()
			return player, profile, shop
		end

		it(
			"si el prompt termina SIN compra (wasPurchased = false) se re-verifica: el dueno real deja de figurar como no poseido",
			function()
				local changes = {}
				local player, profile, shop = setup(changes)
				env.MarketplaceService:GrantGamePass(USER, 3001) -- ya es dueno (la compra fue en otra sesion o en la web)
				env.MarketplaceService:FailNext(3) -- los 3 intentos de la consulta de entrada fallan
				shop:loadPlayer(player)
				expect(shop:ownsPass(player, "starter")).toBe(false) -- desconocido: no se asume propiedad
				-- el jugador pulsa "Ver compra": Roblox le dice que ya lo tiene y cierra el prompt sin compra
				env.MarketplaceService:SimulateGamePassPurchase(player, 3001, false)
				expect(shop:ownsPass(player, "starter")).toBe(true) -- antes: seguia en false hasta reentrar
				expect(profile.data.coins).toBe(500) -- la concesion unica del pase tambien se aplica (una vez)
				expect(changes).toEqual({ "starter:true" })
				env.MarketplaceService:SimulateGamePassPurchase(player, 3001, false)
				expect(profile.data.coins).toBe(500)
			end
		)

		it("si la re-verificacion tambien falla se sigue sin asumir propiedad y se puede volver a intentar", function()
			local changes = {}
			local player, profile, shop = setup(changes)
			env.MarketplaceService:GrantGamePass(USER, 3001)
			env.MarketplaceService:FailNext(6) -- entrada (3 intentos) + primera re-verificacion (3 intentos)
			shop:loadPlayer(player)
			env.MarketplaceService:SimulateGamePassPurchase(player, 3001, false)
			env.clock:advance(10) -- los reintentos de la re-verificacion esperan 1 s y 2 s
			expect(shop:ownsPass(player, "starter")).toBe(false)
			expect(profile.data.coins).toBe(0)
			env.MarketplaceService:SimulateGamePassPurchase(player, 3001, false) -- ahora Roblox responde
			env.clock:advance(10)
			expect(shop:ownsPass(player, "starter")).toBe(true)
			expect(profile.data.coins).toBe(500)
		end)

		it("si la consulta de entrada FUE bien (no es dueno), cancelar un prompt no gasta llamadas a Roblox", function()
			local changes = {}
			local player, _, shop = setup(changes)
			shop:loadPlayer(player)
			local calls = 0
			local realOwns = env.MarketplaceService.UserOwnsGamePassAsync
			env.MarketplaceService.UserOwnsGamePassAsync = function(self, userId, passId)
				calls += 1
				return realOwns(self, userId, passId)
			end
			env.MarketplaceService:SimulateGamePassPurchase(player, 3001, false)
			expect(calls).toBe(0)
			expect(shop:ownsPass(player, "starter")).toBe(false)
			expect(changes).toEqual({})
		end)
	end)

	it(
		"la puerta previa a publicar (allowPlaceholders = false) no cuenta lo apagado por flag (enabled = false)",
		function()
			local catalog = newCatalog()
			catalog.products.off = {
				key = "off",
				id = 0,
				name = "Apagado",
				description = "Apagado por flag.",
				kind = "currency",
				grant = { coins = 1 },
				tier = "basic",
				enabled = false,
			}
			catalog.products.boost.id = 0 -- este SI esta pendiente
			local problems = Shop.validateCatalog(catalog, grants(), { allowPlaceholders = false })
			expect(#problems).toBe(1)
			expect(problems[1]).toContain("boost")
		end
	)
end)
