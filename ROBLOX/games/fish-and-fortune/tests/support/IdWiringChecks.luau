--!nonstrict
--[[
	Comprobaciones del CABLEADO de IDs (clave -> ID -> prompt -> recibo -> concesion) con el codigo REAL de GameService
	cargado en el arnes de dobles (ver ServerHarness). Se reutilizan con:
	  * IDs sinteticos distintos de FAKE_IDS (PassIds.spec, corre siempre), y
	  * los IDs REALES de ProductIds.luau (ReleaseGate.spec, solo con FF_RELEASE_CHECK=1).

	Que prueban (sin gastar nada, sin Studio):
	  1. Pedir la compra de cada pase/producto abre el prompt con EXACTAMENTE el ID cableado para esa clave.
	  2. Un recibo con el ID de cada producto habilitado se concede UNA vez, solo en lo que dice su catalogo, y se guarda.
	  3. Tener el pase (UserOwnsGamePassAsync con su ID) activa SOLO ese pase.
	  4. Si hay alias (passAssetIds): el evento PromptGamePassPurchaseFinished con el alias activa el pase correcto.
	Lo que NO prueban: que el ID exista en Roblox ni que el prompt real muestre el objeto correcto (eso lo hace el script
	de verificacion de wire-ids.mjs --emit-verify-luau y la prueba de Studio de la guia).
]]
local ServerHarness = require("./ServerHarness")

local buildWorld, USER = ServerHarness.buildWorld, ServerHarness.USER

local IdWiringChecks = {}

local PASS_KEYS = { "auto_fish", "double_coins", "luck_plus", "starter", "vip", "season_pass" }

local function sortedKeys(map)
	local keys = {}
	for key in map do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end

-- Claves habilitadas (ID distinto de 0 y no apagadas por flag) de un catalogo ya construido.
local function enabledKeys(group)
	local keys = {}
	for _, key in sortedKeys(group) do
		local item = group[key]
		if item.id ~= 0 and item.enabled ~= false then
			table.insert(keys, key)
		end
	end
	return keys
end

local function newWorld(ids)
	local world = buildWorld({ productIds = ids })
	local catalog = world.m.Catalog.build(ids, world.m.Balance, world.m.FeatureFlags)
	return world, catalog
end

function IdWiringChecks.checkPrompts(ids, expect)
	local world, catalog = newWorld(ids)
	local player = world.join()
	local shop = world.api.shop
	local env = world.env
	local count = 0
	for _, key in enabledKeys(catalog.passes) do
		env.clock:advance(4) -- enfriamiento entre prompts
		local ok, reason = shop:promptPass(player, key)
		expect(reason).toBeNil()
		expect(ok).toBe(true)
		expect(world.prompts[#world.prompts]).toEqual({ kind = "pass", id = ids.passes[key] })
		count += 1
	end
	for _, key in enabledKeys(catalog.products) do
		env.clock:advance(4)
		local ok, reason = shop:promptProduct(player, key)
		expect(reason).toBeNil()
		expect(ok).toBe(true)
		expect(world.prompts[#world.prompts]).toEqual({ kind = "product", id = ids.products[key] })
		count += 1
	end
	env.clock:assertNoErrors()
	return count
end

function IdWiringChecks.checkReceipts(ids, expect)
	local _, probe = newWorld(ids)
	local count = 0
	for _, key in enabledKeys(probe.products) do
		-- mundo nuevo por producto: el efecto se mide contra un jugador recien creado
		local world, catalog = newWorld(ids)
		local env = world.env
		local product = catalog.products[key]
		local player = world.join()
		local receipt, decision = env.MarketplaceService:SimulatePurchase(player, ids.products[key])
		env.clock:advance(1)
		expect(decision).toBe(env.Enum.ProductPurchaseDecision.PurchaseGranted)
		local data = world.stored().data
		expect(data.purchases[receipt.PurchaseId]).toBeTruthy()
		local grant = product.grant
		if product.kind == "currency" then
			expect(data.wallet.coins).toBe(grant.coins or 0)
			expect(data.wallet.pearls).toBe(grant.pearls or 0)
			expect(data.extraSlots).toBe(0)
		elseif product.kind == "slots" then
			expect(data.extraSlots).toBe(grant.slots)
			expect(data.wallet.coins).toBe(0)
		elseif product.kind == "boost" then
			expect(data.boosts[grant.boostId]).toBeTruthy()
			expect(data.wallet.coins).toBe(0)
			expect(data.extraSlots).toBe(0)
		end
		-- reentrega del mismo recibo: sigue confirmada y NO se concede dos veces
		local again = env.MarketplaceService:SimulateRedelivery(receipt.PurchaseId)
		env.clock:advance(1)
		expect(again).toBe(env.Enum.ProductPurchaseDecision.PurchaseGranted)
		expect(world.stored().data.wallet.coins).toBe(grant.coins or 0)
		env.clock:assertNoErrors()
		count += 1
	end
	return count
end

function IdWiringChecks.checkPassOwnership(ids, expect)
	local _, probe = newWorld(ids)
	local count = 0
	for _, key in enabledKeys(probe.passes) do
		local world = newWorld(ids)
		local env = world.env
		env.MarketplaceService:GrantGamePass(USER, ids.passes[key])
		local player = world.join()
		for _, other in PASS_KEYS do
			expect(world.api.shop:ownsPass(player, other)).toBe(other == key)
		end
		env.clock:assertNoErrors()
		count += 1
	end
	return count
end

function IdWiringChecks.checkAliases(ids, expect)
	local count = 0
	for _, key in sortedKeys(ids.passAssetIds or {}) do
		local world = newWorld(ids)
		local env = world.env
		local player = world.join()
		expect(world.api.shop:ownsPass(player, key)).toBe(false)
		-- el motor avisa con el alias y el pase queda concedido en UserOwnsGamePassAsync con el ID principal
		env.MarketplaceService:GrantGamePass(USER, ids.passes[key])
		env.MarketplaceService.PromptGamePassPurchaseFinished:Fire(player, ids.passAssetIds[key], true)
		env.clock:advance(1)
		expect(world.api.shop:ownsPass(player, key)).toBe(true)
		env.clock:assertNoErrors()
		count += 1
	end
	return count
end

-- Todo junto; devuelve cuantos objetos se comprobaron.
function IdWiringChecks.checkAll(ids, expect)
	local total = IdWiringChecks.checkPrompts(ids, expect)
	IdWiringChecks.checkReceipts(ids, expect)
	IdWiringChecks.checkPassOwnership(ids, expect)
	IdWiringChecks.checkAliases(ids, expect)
	return total
end

return IdWiringChecks
