--!nonstrict
--[[
	MarketplaceService (mock): ProcessReceipt, game passes y compras de developer products.

	El juego asigna `marketplace.ProcessReceipt = function(receiptInfo) ... end` igual
	que en Roblox. El TEST hace de "Roblox" y entrega recibos:

	  local receipt = marketplace:SimulatePurchase(player, productId)   -- llama a ProcessReceipt
	  marketplace:SimulateRedelivery(receipt.PurchaseId)                 -- Roblox reintenta el mismo recibo
	  marketplace:RetryPending()                                         -- reintenta los NotProcessedYet

	Reglas modeladas (segun la documentacion de ProcessReceipt) [NO VERIFICADO aqui]:
	  * Si el callback devuelve PurchaseGranted el recibo se da por cerrado.
	  * Si devuelve NotProcessedYet, lanza un error o no hay callback: sigue pendiente
	    y Roblox lo vuelve a entregar mas tarde (aqui: `RetryPending`/`SimulateRedelivery`).
	  * Puede haber redelivery de un recibo ya concedido (p. ej. el servidor cayo antes
	    de confirmar): por eso el handler DEBE ser idempotente por PurchaseId.

	Game passes: GrantGamePass / RevokeGamePass / UserOwnsGamePassAsync.
	Fallos web: `marketplace:FailNext(n, "mensaje")` hace fallar las siguientes n llamadas Async.
]]

local Signal = require("./Signal")
local EnumMock = require("./Enum")

local MarketplaceService = {}
MarketplaceService.__index = MarketplaceService

--[[
	options:
	  clock                mocks/Clock
	  enum                 tabla Enum (por defecto el mock de Enum.luau)
	  placeId              PlaceIdWherePurchased de los recibos (por defecto 1)
	  autoApprove          si true, PromptProductPurchase/PromptGamePassPurchase compran solos
	  currencySpent        Robux gastados por defecto en los recibos (por defecto 0)
]]
function MarketplaceService.new(options)
	local opts = options or {}
	local self = setmetatable({}, MarketplaceService)
	local spawn = opts.clock and opts.clock.task.spawn or nil
	self._enum = opts.enum or EnumMock
	self._placeId = opts.placeId or 1
	self._autoApprove = opts.autoApprove == true
	self._currencySpent = opts.currencySpent or 0
	self._receiptCounter = 0
	self._receipts = {} -- PurchaseId -> { receipt=, status="pending"|"granted", attempts=n }
	self._receiptOrder = {}
	self._passes = {} -- userId -> { [gamePassId] = true }
	self._products = {} -- infoType.Name .. ":" .. id -> info
	self._failQueue = {}
	self._spawn = spawn
	self.ProcessReceipt = nil
	self.prompts = {} -- historial de Prompt* llamados desde el juego
	self.processErrors = {} -- errores lanzados por ProcessReceipt
	self.PromptProductPurchaseFinished = Signal.new({ spawn = spawn }) -- (userId, productId, isPurchased)
	self.PromptGamePassPurchaseFinished = Signal.new({ spawn = spawn }) -- (player, gamePassId, wasPurchased)
	self.PromptPurchaseFinished = Signal.new({ spawn = spawn }) -- (player, assetId, isPurchased)
	return self
end

----------------------------------------------------------------------------
-- Fallos simulados de las llamadas Async
----------------------------------------------------------------------------

function MarketplaceService:FailNext(count: number, message: string?)
	table.insert(self._failQueue, { remaining = count or 1, message = message or "[mock] simulated MarketplaceService web failure" })
end

function MarketplaceService:_maybeFail()
	local queued = self._failQueue[1]
	if queued then
		queued.remaining -= 1
		if queued.remaining <= 0 then
			table.remove(self._failQueue, 1)
		end
		error(queued.message, 0)
	end
end

----------------------------------------------------------------------------
-- Game passes
----------------------------------------------------------------------------

function MarketplaceService:GrantGamePass(userId: number, gamePassId: number)
	self._passes[userId] = self._passes[userId] or {}
	self._passes[userId][gamePassId] = true
end

function MarketplaceService:RevokeGamePass(userId: number, gamePassId: number)
	if self._passes[userId] then
		self._passes[userId][gamePassId] = nil
	end
end

function MarketplaceService:UserOwnsGamePassAsync(userId: number, gamePassId: number): boolean
	assert(type(userId) == "number", "UserOwnsGamePassAsync: userId debe ser numero")
	assert(type(gamePassId) == "number", "UserOwnsGamePassAsync: gamePassId debe ser numero")
	self:_maybeFail()
	return self._passes[userId] ~= nil and self._passes[userId][gamePassId] == true
end

function MarketplaceService:PromptGamePassPurchase(player, gamePassId: number)
	table.insert(self.prompts, { kind = "GamePass", player = player, id = gamePassId })
	if self._autoApprove then
		self:SimulateGamePassPurchase(player, gamePassId)
	end
end

-- El jugador compra el pase: se concede y se dispara PromptGamePassPurchaseFinished.
function MarketplaceService:SimulateGamePassPurchase(player, gamePassId: number, accepted: boolean?)
	local wasPurchased = accepted ~= false
	if wasPurchased then
		self:GrantGamePass(player.UserId, gamePassId)
	end
	self.PromptGamePassPurchaseFinished:Fire(player, gamePassId, wasPurchased)
end

----------------------------------------------------------------------------
-- Catalogo (GetProductInfo)
----------------------------------------------------------------------------

-- info: { Name=, PriceInRobux=, Description=, ... }  infoType: Enum.InfoType.* (por defecto Product)
function MarketplaceService:RegisterProduct(id: number, info: { [string]: any }, infoType: any?)
	local kind = infoType or self._enum.InfoType.Product
	local entry = table.clone(info)
	entry.ProductId = entry.ProductId or id
	self._products[kind.Name .. ":" .. tostring(id)] = entry
end

function MarketplaceService:GetProductInfo(id: number, infoType: any?)
	self:_maybeFail()
	local kind = infoType or self._enum.InfoType.Asset
	local entry = self._products[kind.Name .. ":" .. tostring(id)]
	if not entry then
		error("HTTP 400 (Bad Request): [mock] product " .. tostring(id) .. " not registered", 0)
	end
	return table.clone(entry)
end

----------------------------------------------------------------------------
-- Developer products / ProcessReceipt
----------------------------------------------------------------------------

function MarketplaceService:PromptProductPurchase(player, productId: number, _equipIfPurchased: boolean?, _currencyType: any?)
	table.insert(self.prompts, { kind = "Product", player = player, id = productId })
	if self._autoApprove then
		self:SimulatePurchase(player, productId)
	end
end

-- Crea un recibo (sin entregarlo). Util para tests que quieran controlar la entrega.
function MarketplaceService:CreateReceipt(player, productId: number, overrides: { [string]: any }?)
	self._receiptCounter += 1
	local o = overrides or {}
	local receipt = {
		PurchaseId = o.PurchaseId or ("mock-purchase-" .. tostring(self._receiptCounter)),
		PlayerId = player.UserId,
		ProductId = productId,
		PlaceIdWherePurchased = o.PlaceIdWherePurchased or self._placeId,
		CurrencySpent = o.CurrencySpent or self._currencySpent,
		CurrencyType = o.CurrencyType or self._enum.CurrencyType.Robux,
	}
	self._receipts[receipt.PurchaseId] = { receipt = receipt, status = "pending", attempts = 0, player = player }
	table.insert(self._receiptOrder, receipt.PurchaseId)
	return receipt
end

-- Entrega un recibo a ProcessReceipt. Devuelve la decision (Enum item).
function MarketplaceService:_deliver(purchaseId: string)
	local record = self._receipts[purchaseId]
	assert(record, "MarketplaceService: recibo desconocido " .. tostring(purchaseId))
	record.attempts += 1
	local decisionEnum = self._enum.ProductPurchaseDecision
	local callback = self.ProcessReceipt
	local decision
	if callback == nil then
		decision = decisionEnum.NotProcessedYet
	else
		-- copia para que el juego no pueda alterar el recibo guardado
		local ok, result = pcall(callback, table.clone(record.receipt))
		if ok then
			decision = result
		else
			table.insert(self.processErrors, tostring(result))
			decision = decisionEnum.NotProcessedYet
		end
	end
	if decision == decisionEnum.PurchaseGranted then
		local firstGrant = record.status ~= "granted"
		record.status = "granted"
		if firstGrant then
			self.PromptProductPurchaseFinished:Fire(record.receipt.PlayerId, record.receipt.ProductId, true)
		end
	else
		decision = decisionEnum.NotProcessedYet
		record.status = record.status == "granted" and "granted" or "pending"
	end
	record.lastDecision = decision
	return decision
end

--[[
	El jugador compra el producto: crea el recibo y lo entrega a ProcessReceipt.
	Devuelve (receipt, decision).
]]
function MarketplaceService:SimulatePurchase(player, productId: number, overrides: { [string]: any }?)
	local receipt = self:CreateReceipt(player, productId, overrides)
	local decision = self:_deliver(receipt.PurchaseId)
	return receipt, decision
end

-- Roblox reentrega un recibo concreto (aunque ya estuviera concedido).
function MarketplaceService:SimulateRedelivery(purchaseId: string)
	return self:_deliver(purchaseId)
end

-- Roblox reintenta todos los recibos pendientes (NotProcessedYet). Devuelve cuantos se concedieron.
function MarketplaceService:RetryPending(): number
	local granted = 0
	for _, purchaseId in table.clone(self._receiptOrder) do
		local record = self._receipts[purchaseId]
		if record.status == "pending" then
			if self:_deliver(purchaseId) == self._enum.ProductPurchaseDecision.PurchaseGranted then
				granted += 1
			end
		end
	end
	return granted
end

function MarketplaceService:GetReceiptStatus(purchaseId: string): string?
	local record = self._receipts[purchaseId]
	return record and record.status or nil
end

function MarketplaceService:GetDeliveryAttempts(purchaseId: string): number
	local record = self._receipts[purchaseId]
	return record and record.attempts or 0
end

function MarketplaceService:GetPendingReceipts()
	local pending = {}
	for _, purchaseId in self._receiptOrder do
		local record = self._receipts[purchaseId]
		if record.status == "pending" then
			table.insert(pending, table.clone(record.receipt))
		end
	end
	return pending
end

return MarketplaceService
