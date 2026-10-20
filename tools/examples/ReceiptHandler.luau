--!nonstrict
--[[
	Ejemplo: ProcessReceipt IDEMPOTENTE con dependencias inyectadas (para poder probarlo con mocks).

	Patron:
	  1. Se identifica la compra por PurchaseId (unico por compra; Roblox puede reentregar el mismo recibo).
	  2. Con UpdateAsync se aplica el premio Y se anota el PurchaseId en los datos del jugador en UNA sola
	     escritura atomica: si el recibo ya estaba anotado, no se vuelve a conceder.
	  3. Solo se devuelve PurchaseGranted si esa escritura se confirmo; ante cualquier fallo
	     (datastore caido, jugador ausente, producto desconocido) se devuelve NotProcessedYet y
	     Roblox reintentara mas tarde.

	NOTA: patron de ejemplo para el toolchain; no se ha probado en Roblox Studio.

	Uso en un juego real:
	  local handler = ReceiptHandler.new({
	  	dataStoreService = game:GetService("DataStoreService"),
	  	players = game:GetService("Players"),
	  	enum = Enum,
	  	storeName = "PlayerData",
	  	products = { [1001] = function(data) data.coins += 100 end },
	  })
	  MarketplaceService.ProcessReceipt = handler:getCallback()
]]

local ReceiptHandler = {}
ReceiptHandler.__index = ReceiptHandler

local MAX_RECEIPTS_KEPT = 200

function ReceiptHandler.new(deps)
	assert(deps.dataStoreService, "ReceiptHandler: falta dataStoreService")
	assert(deps.players, "ReceiptHandler: falta players")
	assert(deps.enum, "ReceiptHandler: falta enum")
	assert(deps.products, "ReceiptHandler: falta products")
	local self = setmetatable({}, ReceiptHandler)
	self._store = deps.dataStoreService:GetDataStore(deps.storeName or "PlayerData")
	self._players = deps.players
	self._decision = deps.enum.ProductPurchaseDecision
	self._products = deps.products
	self._log = deps.log or function() end
	return self
end

function ReceiptHandler.keyFor(userId: number): string
	return "Player_" .. tostring(userId)
end

local function defaultData()
	return { coins = 0, receipts = {}, receiptOrder = {} }
end

-- Devuelve la decision (Enum.ProductPurchaseDecision.*).
function ReceiptHandler:process(receiptInfo)
	local grant = self._products[receiptInfo.ProductId]
	if grant == nil then
		self._log("producto desconocido " .. tostring(receiptInfo.ProductId))
		return self._decision.NotProcessedYet
	end

	-- Si el jugador no esta, Roblox reintentara cuando vuelva a entrar.
	if self._players:GetPlayerByUserId(receiptInfo.PlayerId) == nil then
		return self._decision.NotProcessedYet
	end

	local purchaseId = receiptInfo.PurchaseId
	local alreadyGranted = false

	local ok, err = pcall(function()
		self._store:UpdateAsync(ReceiptHandler.keyFor(receiptInfo.PlayerId), function(data)
			data = data or defaultData()
			if data.receipts[purchaseId] then
				alreadyGranted = true
				return nil -- cancelar: no hay nada que escribir, ya estaba concedido
			end
			grant(data, receiptInfo)
			data.receipts[purchaseId] = true
			table.insert(data.receiptOrder, purchaseId)
			-- acotar el historial para no crecer sin limite
			while #data.receiptOrder > MAX_RECEIPTS_KEPT do
				local oldest = table.remove(data.receiptOrder, 1)
				data.receipts[oldest] = nil
			end
			return data
		end)
	end)

	if not ok then
		self._log("UpdateAsync fallo: " .. tostring(err))
		return self._decision.NotProcessedYet
	end
	if alreadyGranted then
		self._log("recibo duplicado " .. tostring(purchaseId) .. " (ya concedido)")
	end
	return self._decision.PurchaseGranted
end

-- Funcion lista para asignar a MarketplaceService.ProcessReceipt.
function ReceiptHandler:getCallback()
	return function(receiptInfo)
		return self:process(receiptInfo)
	end
end

return ReceiptHandler
