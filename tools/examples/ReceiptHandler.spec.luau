--!nonstrict
-- Test de ejemplo: ProcessReceipt idempotente usando los mocks de tools/testkit/mocks.

local testkit = require("@testkit")
local Mocks = require("@testkit/mocks")
local ReceiptHandler = require("./ReceiptHandler")

local describe, it, expect, beforeEach = testkit.describe, testkit.it, testkit.expect, testkit.beforeEach

local COINS_PRODUCT = 1001
local GEMS_PRODUCT = 1002

describe("ProcessReceipt idempotente", function()
	local env, handler, store, alice

	beforeEach(function()
		env = Mocks.new()
		handler = ReceiptHandler.new({
			dataStoreService = env.DataStoreService,
			players = env.Players,
			enum = env.Enum,
			products = {
				[COINS_PRODUCT] = function(data)
					data.coins += 100
				end,
				[GEMS_PRODUCT] = function(data)
					data.gems = (data.gems or 0) + 5
				end,
			},
		})
		env.MarketplaceService.ProcessReceipt = handler:getCallback()
		store = env.DataStoreService:GetDataStore("PlayerData")
		alice = env.Players:AddPlayer(1001, "Alice")
	end)

	local function coinsOf(userId: number): number
		local data = store:_peek(ReceiptHandler.keyFor(userId))
		return data and data.coins or 0
	end

	it("concede la compra una vez y devuelve PurchaseGranted", function()
		local receipt, decision = env.MarketplaceService:SimulatePurchase(alice, COINS_PRODUCT)

		expect(decision).toBe(env.Enum.ProductPurchaseDecision.PurchaseGranted)
		expect(coinsOf(alice.UserId)).toBe(100)
		expect(env.MarketplaceService:GetReceiptStatus(receipt.PurchaseId)).toBe("granted")
	end)

	it("no concede dos veces si Roblox reentrega el mismo recibo", function()
		local receipt = env.MarketplaceService:SimulatePurchase(alice, COINS_PRODUCT)

		-- Roblox puede volver a llamar a ProcessReceipt con el mismo PurchaseId
		for _ = 1, 3 do
			local decision = env.MarketplaceService:SimulateRedelivery(receipt.PurchaseId)
			expect(decision).toBe(env.Enum.ProductPurchaseDecision.PurchaseGranted)
		end

		expect(coinsOf(alice.UserId)).toBe(100) -- sigue siendo 100, no 400
		expect(env.MarketplaceService:GetDeliveryAttempts(receipt.PurchaseId)).toBe(4)
	end)

	it("compras distintas se acumulan (mismo producto, distinto PurchaseId)", function()
		env.MarketplaceService:SimulatePurchase(alice, COINS_PRODUCT)
		env.MarketplaceService:SimulatePurchase(alice, COINS_PRODUCT)
		env.MarketplaceService:SimulatePurchase(alice, GEMS_PRODUCT)

		local data = store:_peek(ReceiptHandler.keyFor(alice.UserId))
		expect(data.coins).toBe(200)
		expect(data.gems).toBe(5)
		expect(#data.receiptOrder).toBe(3)
	end)

	it("si el DataStore falla devuelve NotProcessedYet y NO concede; al reintentar concede una sola vez", function()
		env.DataStoreService:SetOutage(true)
		local receipt, decision = env.MarketplaceService:SimulatePurchase(alice, COINS_PRODUCT)

		expect(decision).toBe(env.Enum.ProductPurchaseDecision.NotProcessedYet)
		expect(env.MarketplaceService:GetReceiptStatus(receipt.PurchaseId)).toBe("pending")
		expect(coinsOf(alice.UserId)).toBe(0)

		-- el servicio se recupera y Roblox reintenta los recibos pendientes
		env.DataStoreService:SetOutage(false)
		expect(env.MarketplaceService:RetryPending()).toBe(1)
		expect(coinsOf(alice.UserId)).toBe(100)

		-- un reintento extra no vuelve a conceder
		env.MarketplaceService:RetryPending()
		env.MarketplaceService:SimulateRedelivery(receipt.PurchaseId)
		expect(coinsOf(alice.UserId)).toBe(100)
	end)

	it("fallos intermitentes: el recibo se concede exactamente una vez tras varios reintentos", function()
		env.DataStoreService:FailNext(2, { op = "UpdateAsync" })
		local receipt = env.MarketplaceService:SimulatePurchase(alice, COINS_PRODUCT)
		expect(env.MarketplaceService:GetReceiptStatus(receipt.PurchaseId)).toBe("pending")

		env.MarketplaceService:RetryPending() -- 2.o fallo
		expect(coinsOf(alice.UserId)).toBe(0)
		env.MarketplaceService:RetryPending() -- ya funciona
		expect(coinsOf(alice.UserId)).toBe(100)
		expect(env.MarketplaceService:GetDeliveryAttempts(receipt.PurchaseId)).toBe(3)
		expect(env.DataStoreService:GetRequestCount("UpdateAsync")).toBe(3)
	end)

	it("si el jugador no esta en el servidor devuelve NotProcessedYet hasta que vuelve", function()
		local bob = env.Players:AddPlayer(2002, "Bob")
		env.Players:RemovePlayer(bob)

		local receipt, decision = env.MarketplaceService:SimulatePurchase(bob, COINS_PRODUCT)
		expect(decision).toBe(env.Enum.ProductPurchaseDecision.NotProcessedYet)
		expect(env.DataStoreService:GetRequestCount()).toBe(0) -- ni siquiera toco el DataStore

		env.Players:AddPlayer(2002, "Bob")
		expect(env.MarketplaceService:RetryPending()).toBe(1)
		expect(coinsOf(2002)).toBe(100)
		expect(env.MarketplaceService:GetReceiptStatus(receipt.PurchaseId)).toBe("granted")
	end)

	it("producto desconocido: NotProcessedYet (no se pierde la compra) y no escribe datos", function()
		local _, decision = env.MarketplaceService:SimulatePurchase(alice, 9999)
		expect(decision).toBe(env.Enum.ProductPurchaseDecision.NotProcessedYet)
		expect(store:_keys()).toEqual({})
	end)

	it("un error lanzado por ProcessReceipt cuenta como NotProcessedYet", function()
		env.MarketplaceService.ProcessReceipt = function()
			error("boom")
		end
		local _, decision = env.MarketplaceService:SimulatePurchase(alice, COINS_PRODUCT)
		expect(decision).toBe(env.Enum.ProductPurchaseDecision.NotProcessedYet)
		expect(env.MarketplaceService.processErrors[1]).toContain("boom")
	end)

	it("tolera otro servidor concediendo el mismo recibo justo antes (carrera simulada)", function()
		local purchaseId = "mock-purchase-shared"
		-- justo antes de nuestro UpdateAsync, "otro servidor" ya anoto el recibo y concedio
		env.DataStoreService.onRequest = function(info)
			if info.op == "UpdateAsync" then
				env.DataStoreService.onRequest = nil
				store:_seed(ReceiptHandler.keyFor(alice.UserId), {
					coins = 100,
					receipts = { [purchaseId] = true },
					receiptOrder = { purchaseId },
				})
			end
		end

		local _, decision = env.MarketplaceService:SimulatePurchase(alice, COINS_PRODUCT, { PurchaseId = purchaseId })

		expect(decision).toBe(env.Enum.ProductPurchaseDecision.PurchaseGranted)
		expect(coinsOf(alice.UserId)).toBe(100) -- no se duplico
	end)
end)
