--!strict
--[[
	Shop: tienda dirigida por configuracion (pases, productos de desarrollador, boosts, packs) con
	  * UN unico ProcessReceipt, IDEMPOTENTE por PurchaseId,
	  * concesion en memoria + registro del PurchaseId en el MISMO perfil + guardado; solo se devuelve
	    PurchaseGranted DESPUES de que el guardado se confirmo (si falla: NotProcessedYet),
	  * cache de propiedad de pases (UserOwnsGamePassAsync con reintentos) y re-verificacion tras comprar,
	  * compras seguras con jugadores que se van, perfiles sin cargar o bloqueo perdido,
	  * gating por PolicyService (objetos que alteran probabilidades) y por precios/IDs placeholder,
	  * escalera de precios en Robux configurable y validacion del catalogo (sin urgencia ni descuentos falsos).

	Flujo de ProcessReceipt (ver ROBLOX/docs/arquitectura.md):
	  1. validar recibo y producto            -> si no: NotProcessedYet (nunca se "traga" una compra)
	  2. jugador presente y perfil activo      -> si no: NotProcessedYet (Roblox reintenta al volver a entrar)
	  3. PurchaseId ya registrado?             -> guardar (si faltaba) y PurchaseGranted
	  4. aplicar efecto (handler sincrono, SIN ceder) + registrar PurchaseId, en el mismo paso
	  5. perfil:save()                         -> ok: PurchaseGranted | fallo: NotProcessedYet
	El reintento de Roblox cae en el paso 3, asi que el efecto se concede UNA sola vez.

	// REVIEW(money): TODO este archivo es codigo de monetizacion. Requiere revision humana y pruebas con
	// jugadores de prueba en Studio antes de publicar.
]]

export type Receipt = {
	PurchaseId: string,
	PlayerId: number,
	ProductId: number,
	PlaceIdWherePurchased: number?,
	CurrencySpent: number?,
	CurrencyType: any?,
}

export type PassDef = {
	key: string,
	id: number, -- 0 = placeholder TODO_ID: no se puede comprar hasta rellenarlo
	name: string,
	description: string,
	tier: string?, -- escalon de la escalera de precios
	priceRobux: number?, -- si falta, se resuelve desde `tier`
	priceOverride: boolean?, -- true: precio fuera de la escalera (revisar a mano)
	promoted: boolean?, -- los pases promocionados deben costar 50-800 R$ y NO pueden alterar azar
	affectsOdds: boolean?, -- modifica probabilidades (suerte): requiere PolicyService
	enabled: boolean?, -- false: no se ofrece, no se puede comprar y sus recibos se rechazan (flag de funcion)
	oneTimeGrant: { [string]: any }?, -- { kind = "...", ... } concesion unica al poseerlo (p. ej. pack de inicio)
}

export type ProductDef = {
	key: string,
	id: number, -- 0 = placeholder TODO_ID
	name: string,
	description: string,
	kind: string, -- clave del handler de concesion
	grant: { [string]: any }, -- datos para el handler
	tier: string?,
	priceRobux: number?,
	priceOverride: boolean?,
	affectsOdds: boolean?,
	enabled: boolean?, -- false: no se ofrece, no se puede comprar y sus recibos se rechazan (flag de funcion)
}

export type Catalog = {
	priceLadder: { [string]: number }, -- escalon -> Robux
	passes: { [string]: PassDef },
	products: { [string]: ProductDef },
}

-- Handler de concesion. Debe validar ANTES de mutar, NO ceder y devolver true solo si concedio todo.
export type GrantHandler = (player: any, profile: any, product: any, receipt: Receipt?) -> boolean

export type Config = {
	catalog: Catalog,
	marketplace: any, -- MarketplaceService (o doble)
	players: any, -- Players (o doble)
	decision: { PurchaseGranted: any, NotProcessedYet: any }, -- Enum.ProductPurchaseDecision
	infoTypes: { Product: any, GamePass: any }?, -- Enum.InfoType (solo para precios)
	policy: any?, -- PolicyService (o doble)
	waitForProfile: (userId: number, timeoutSeconds: number) -> any?, -- Data manager:waitForProfile
	grants: { [string]: GrantHandler },
	task: any?,
	now: (() -> number)?,
	log: ((message: string) -> ())?,
	random: (() -> number)?,
	profileWaitSeconds: number?, -- por defecto 20
	purchaseHistorySize: number?, -- por defecto 500
	promptCooldownSeconds: number?, -- por defecto 3
	onPurchaseGranted: ((player: any, product: ProductDef, receipt: Receipt) -> ...any)?, -- DESPUES de persistir
	onPassChanged: ((player: any, pass: PassDef, owned: boolean) -> ...any)?,
}

local Shop = {}

-- Campos que la plantilla de datos del juego debe incluir (Data schema.template).
Shop.DATA_TEMPLATE = { purchases = {}, passGrants = {} }

Shop.DECISION_NOT_PROCESSED = "NotProcessedYet"

----------------------------------------------------------------------------
-- Escalera de precios y validacion del catalogo
----------------------------------------------------------------------------

-- Escalera por defecto (hipotesis para A/B test, ROBLOX/research/02 seccion 5.2): NO es un dato de mercado.
Shop.DEFAULT_LADDER = {
	impulse = 25,
	entry = 49,
	basic = 99,
	value = 199,
	strong = 499,
	premium = 999,
	anchor = 1999,
}

function Shop.priceForTier(ladder: { [string]: number }, tier: string): number?
	return ladder[tier]
end

-- Devuelve el precio efectivo (explicito o por escalon); nil si no se puede resolver.
function Shop.resolvePrice(catalog: Catalog, item: { tier: string?, priceRobux: number? }): number?
	if item.priceRobux ~= nil then
		return item.priceRobux
	end
	if item.tier ~= nil then
		return catalog.priceLadder[item.tier]
	end
	return nil
end

local function stripAccents(text: string): string
	local map: { [string]: string } = {
		["á"] = "a",
		["é"] = "e",
		["í"] = "i",
		["ó"] = "o",
		["ú"] = "u",
		["ü"] = "u",
		["ñ"] = "n",
		["Á"] = "a",
		["É"] = "e",
		["Í"] = "i",
		["Ó"] = "o",
		["Ú"] = "u",
		["Ñ"] = "n",
	}
	local result = string.gsub(text, utf8.charpattern, function(char: string): string
		return map[char] or char
	end)
	return string.lower(result)
end

-- Lenguaje de presion/urgencia que NO debe aparecer en tiendas (menores; ROBLOX/research/03 2.3).
local PRESSURE_PHRASES: { string } = {
	"ultima oportunidad",
	"ultimas unidades",
	"solo hoy",
	"solo por hoy",
	"solo por tiempo limitado",
	"tiempo limitado",
	"se acaba",
	"antes de que se acabe",
	"date prisa",
	"corre ",
	"no te lo pierdas",
	"ahora o nunca",
	"oferta relampago",
	"quedan pocos",
	"no volvera",
	"last chance",
	"limited time",
	"hurry",
	"before it's gone",
	"before its gone",
	"don't miss",
	"dont miss",
	"only today",
	"act now",
	"running out",
	"few left",
	"buy now",
	"compra ya",
	"compralo ya",
}

-- Devuelve la primera frase de presion encontrada (o nil).
function Shop.findPressureLanguage(text: string): string?
	local normalized = stripAccents(text) .. " "
	for _, phrase in PRESSURE_PHRASES do
		if string.find(normalized, phrase, 1, true) then
			return phrase
		end
	end
	return nil
end

local FORBIDDEN_FIELDS: { string } = {
	"discountPercent",
	"originalPrice",
	"strikethroughPrice",
	"limitedTime",
	"countdown",
	"expiresIn",
	"stockLeft",
	"fakeStock",
}

--[[
	Valida el catalogo. Devuelve una lista de problemas (vacia = correcta).
	Opciones: allowPlaceholders (los IDs 0 TODO_ID son validos en desarrollo; por defecto true).
]]
function Shop.validateCatalog(
	catalog: Catalog,
	grants: { [string]: any }?,
	options: { allowPlaceholders: boolean? }?
): { string }
	local problems: { string } = {}
	local function problem(message: string)
		table.insert(problems, message)
	end
	local allowPlaceholders = true
	if options and options.allowPlaceholders == false then
		allowPlaceholders = false
	end
	local ladderValues: { [number]: boolean } = {}
	for tier, price in catalog.priceLadder do
		if type(price) ~= "number" or price < 1 or price % 1 ~= 0 then
			problem("escalera: precio invalido en el escalon " .. tier)
		else
			ladderValues[price] = true
		end
	end

	local seenIds: { [number]: string } = {}
	local seenKeys: { [string]: boolean } = {}

	local function checkCommon(kind: string, key: string, item: any)
		local label = kind .. " '" .. key .. "'"
		if seenKeys[key] then
			problem(label .. ": clave duplicada entre pases y productos")
		end
		seenKeys[key] = true
		if item.key ~= key then
			problem(label .. ": la clave del diccionario no coincide con item.key")
		end
		if type(item.id) ~= "number" or item.id < 0 or item.id % 1 ~= 0 then
			problem(label .. ": id invalido")
		elseif item.id == 0 then
			if not allowPlaceholders then
				problem(label .. ": id placeholder (0 -- TODO_ID) sin rellenar")
			end
		elseif seenIds[item.id] ~= nil then
			problem(label .. ": id " .. item.id .. " repetido con " .. seenIds[item.id])
		else
			seenIds[item.id] = label
		end
		local price = Shop.resolvePrice(catalog, item)
		if price == nil then
			problem(label .. ": sin precio (ni priceRobux ni tier valido)")
		elseif price < 1 or price % 1 ~= 0 then
			problem(label .. ": precio invalido")
		elseif not ladderValues[price] and not item.priceOverride then
			problem(
				label .. ": precio " .. price .. " fuera de la escalera (usa priceOverride = true si es a proposito)"
			)
		end
		for _, field in FORBIDDEN_FIELDS do
			if item[field] ~= nil then
				problem(label .. ": campo '" .. field .. "' no permitido (sin urgencia ni descuentos falsos)")
			end
		end
		for _, textField in { "name", "description" } do
			local text = item[textField]
			if type(text) ~= "string" or text == "" then
				problem(label .. ": falta " .. textField)
			else
				local phrase = Shop.findPressureLanguage(text)
				if phrase then
					problem(label .. ": lenguaje de presion en " .. textField .. " ('" .. phrase .. "')")
				end
			end
		end
	end

	for key, pass in catalog.passes do
		checkCommon("pase", key, pass)
		if pass.promoted then
			local price = Shop.resolvePrice(catalog, pass)
			if price ~= nil and (price < 50 or price > 800) then
				problem("pase '" .. key .. "': los pases promocionados deben costar 50-800 R$")
			end
			if pass.affectsOdds then
				problem("pase '" .. key .. "': un pase promocionado no puede alterar probabilidades (azar de pago)")
			end
		end
		if pass.oneTimeGrant and grants and grants[pass.oneTimeGrant.kind] == nil then
			problem(
				"pase '" .. key .. "': no hay handler para oneTimeGrant.kind = " .. tostring(pass.oneTimeGrant.kind)
			)
		end
	end
	for key, product in catalog.products do
		checkCommon("producto", key, product)
		if grants and grants[product.kind] == nil then
			problem("producto '" .. key .. "': no hay handler de concesion para kind = " .. tostring(product.kind))
		end
		if type(product.grant) ~= "table" then
			problem("producto '" .. key .. "': falta grant")
		end
	end
	table.sort(problems)
	return problems
end

----------------------------------------------------------------------------
-- Instancia
----------------------------------------------------------------------------

local ShopImpl = {}
ShopImpl.__index = ShopImpl

type ShopData = {
	cfg: Config,
	catalog: Catalog,
	productsById: { [number]: ProductDef },
	passesById: { [number]: PassDef },
	taskLib: any,
	nowFn: () -> number,
	randomFn: () -> number,
	owned: { [number]: { [string]: boolean } }, -- userId -> passKey -> poseido
	policies: { [number]: any },
	policyRetryAt: { [number]: number }, -- tras un fallo de PolicyService no se reintenta antes de esta hora
	lastPrompt: { [number]: number },
	priceCache: { [string]: number },
	pendingHooks: { [string]: { player: any, product: ProductDef, receipt: Receipt } }, -- compras concedidas aun sin confirmar
	started: boolean,
	connections: { any },
}
export type Shop = typeof(setmetatable({} :: ShopData, ShopImpl))

-- ProcessReceipt solo debe asignarse UNA vez por servidor (varias asignaciones se pisan en silencio).
local processReceiptOwner: any = nil

function Shop.new(config: Config): Shop
	assert(config.catalog ~= nil, "Shop.new requiere catalog")
	assert(config.marketplace ~= nil, "Shop.new requiere marketplace")
	assert(config.decision ~= nil, "Shop.new requiere decision (Enum.ProductPurchaseDecision)")
	local productsById: { [number]: ProductDef } = {}
	for _, product in config.catalog.products do
		if product.id ~= 0 then
			productsById[product.id] = product
		end
	end
	local passesById: { [number]: PassDef } = {}
	for _, pass in config.catalog.passes do
		if pass.id ~= 0 then
			passesById[pass.id] = pass
		end
	end
	local data: ShopData = {
		cfg = config,
		catalog = config.catalog,
		productsById = productsById,
		passesById = passesById,
		taskLib = config.task or task,
		nowFn = config.now or function(): number
			return os.time()
		end,
		randomFn = config.random or function(): number
			return math.random()
		end,
		owned = {},
		policies = {},
		policyRetryAt = {},
		lastPrompt = {},
		priceCache = {},
		pendingHooks = {},
		started = false,
		connections = {},
	}
	return setmetatable(data, ShopImpl)
end

function ShopImpl._log(self: Shop, message: string)
	local log = self.cfg.log
	if log then
		log(message)
	else
		warn("[Shop] " .. message)
	end
end

function ShopImpl._wait(self: Shop, seconds: number)
	self.taskLib.wait(seconds)
end

----------------------------------------------------------------------------
-- ProcessReceipt (UNICO e idempotente)
----------------------------------------------------------------------------

function ShopImpl._trimHistory(self: Shop, purchases: { [string]: number })
	local limit = self.cfg.purchaseHistorySize or 500
	local count = 0
	for _ in purchases do
		count += 1
	end
	if count <= limit then
		return
	end
	local entries: { { id: string, at: number } } = {}
	for id, at in purchases do
		table.insert(entries, { id = id, at = at })
	end
	table.sort(entries, function(a: { id: string, at: number }, b: { id: string, at: number }): boolean
		if a.at ~= b.at then
			return a.at < b.at
		end
		return a.id < b.id
	end)
	for index = 1, count - limit do
		purchases[entries[index].id] = nil
	end
end

--[[
	Procesa un recibo. Devuelve el enum de decision. NUNCA lanza: cualquier duda => NotProcessedYet,
	porque Roblox reintentara y el paso "ya registrado" evita conceder dos veces.
]]
function ShopImpl.processReceipt(self: Shop, receipt: Receipt): any
	local decision = self.cfg.decision
	local notYet = decision.NotProcessedYet
	local ok, result = pcall(function(): any
		return self:_processReceiptInner(receipt)
	end)
	if not ok then
		self:_log("ProcessReceipt lanzo un error (NotProcessedYet): " .. tostring(result))
		return notYet
	end
	return result
end

function ShopImpl._processReceiptInner(self: Shop, receipt: Receipt): any
	local decision = self.cfg.decision
	local notYet = decision.NotProcessedYet

	-- 1. recibo y producto
	if type(receipt) ~= "table" or type(receipt.PurchaseId) ~= "string" or receipt.PurchaseId == "" then
		self:_log("recibo sin PurchaseId valido")
		return notYet
	end
	if type(receipt.PlayerId) ~= "number" or type(receipt.ProductId) ~= "number" then
		self:_log("recibo mal formado: " .. receipt.PurchaseId)
		return notYet
	end
	local purchaseId = receipt.PurchaseId
	local product = self.productsById[receipt.ProductId]
	if product == nil then
		self:_log("producto desconocido " .. tostring(receipt.ProductId) .. " (recibo " .. purchaseId .. ")")
		return notYet
	end

	if product.enabled == false then
		-- Producto apagado por un flag de funcion (p. ej. suerte de pago en la v1). NO se concede y NO se confirma:
		-- el recibo queda sin resolver (no se pierde ni se regala nada) hasta que una persona decida (ver README).
		self:_log(
			"REVIEW(money): recibo "
				.. purchaseId
				.. " de un producto DESHABILITADO ("
				.. product.key
				.. "): NotProcessedYet"
		)
		return notYet
	end

	-- 2. jugador y perfil
	local player = self.cfg.players:GetPlayerByUserId(receipt.PlayerId)
	if player == nil then
		return notYet -- Roblox vuelve a llamar cuando el jugador entre de nuevo
	end
	local profile = self.cfg.waitForProfile(receipt.PlayerId, self.cfg.profileWaitSeconds or 20)
	if profile == nil or not profile:isActive() then
		return notYet
	end
	local data = profile.data
	if type(data.purchases) ~= "table" then
		data.purchases = {}
	end
	local purchases = data.purchases :: { [string]: number }

	-- 3. ya registrado? (reentrega o segundo servidor): solo falta asegurar que esta guardado
	if purchases[purchaseId] ~= nil then
		if profile:save() then
			self:_fireGrantedHook(purchaseId)
			return decision.PurchaseGranted
		end
		return notYet
	end

	-- 4. aplicar efecto + registrar PurchaseId en el MISMO paso (sin yields entre medias)
	local handler = self.cfg.grants[product.kind]
	if handler == nil then
		self:_log("sin handler de concesion para kind=" .. tostring(product.kind))
		return notYet
	end
	local handlerOk, applied = pcall(handler, player, profile, product, receipt)
	if not handlerOk then
		self:_log("handler de " .. product.key .. " fallo: " .. tostring(applied))
		return notYet
	end
	if applied ~= true then
		return notYet -- comprobar el VALOR devuelto, no solo que no haya errores
	end
	purchases[purchaseId] = self.nowFn()
	self:_trimHistory(purchases)
	profile:markDirty()
	self.pendingHooks[purchaseId] = { player = player, product = product, receipt = receipt }

	-- 5. persistir; solo entonces confirmar
	if not profile:save() then
		self:_log("compra " .. purchaseId .. " concedida en memoria pero NO guardada: NotProcessedYet")
		return notYet
	end
	self:_fireGrantedHook(purchaseId)
	return decision.PurchaseGranted
end

-- Analitica/efectos laterales: solo DESPUES de confirmar el guardado y una sola vez por compra.
function ShopImpl._fireGrantedHook(self: Shop, purchaseId: string)
	local pending = self.pendingHooks[purchaseId]
	if pending == nil then
		return
	end
	self.pendingHooks[purchaseId] = nil
	local hook = self.cfg.onPurchaseGranted
	if hook then
		local ok, err = pcall(hook, pending.player, pending.product, pending.receipt)
		if not ok then
			self:_log("onPurchaseGranted fallo: " .. tostring(err))
		end
	end
end

----------------------------------------------------------------------------
-- Politica (PolicyService), cacheada por jugador
----------------------------------------------------------------------------

--[[
	PolicyInfo del jugador (cacheado). nil si no se pudo obtener => los llamadores deben tratarlo como
	RESTRINGIDO. // VERIFIED: PolicyService:GetPolicyInfoForPlayerAsync(player) yield, usar pcall.
]]
function ShopImpl.getPolicy(self: Shop, player: any): { [string]: any }?
	local userId = player.UserId
	local cached = self.policies[userId]
	if cached ~= nil then
		return cached
	end
	local service = self.cfg.policy
	if service == nil then
		return nil
	end
	-- Memoria negativa: si acaba de fallar, no se bloquea al llamador reintentando en cada consulta.
	local retryAt = self.policyRetryAt[userId]
	if retryAt ~= nil and self.nowFn() < retryAt then
		return nil
	end
	for attempt = 1, 3 do
		local ok, info = pcall(function(): any
			return service:GetPolicyInfoForPlayerAsync(player)
		end)
		if ok and type(info) == "table" then
			self.policies[userId] = info
			self.policyRetryAt[userId] = nil
			return info
		end
		if attempt < 3 then
			self:_wait(attempt)
		end
	end
	self.policyRetryAt[userId] = self.nowFn() + 60
	self:_log("PolicyService no disponible para " .. tostring(userId) .. ": se trata como restringido")
	return nil
end

----------------------------------------------------------------------------
-- Pases: propiedad y concesiones unicas
----------------------------------------------------------------------------

function ShopImpl.ownsPass(self: Shop, player: any, passKey: string): boolean
	local ownedByPlayer = self.owned[player.UserId]
	return ownedByPlayer ~= nil and ownedByPlayer[passKey] == true
end

function ShopImpl._checkOwnership(self: Shop, player: any, pass: PassDef): (boolean, boolean) -- (consultaOk, poseido)
	for attempt = 1, 3 do
		local ok, owns = pcall(function(): any
			return self.cfg.marketplace:UserOwnsGamePassAsync(player.UserId, pass.id)
		end)
		if ok then
			return true, owns == true
		end
		if attempt < 3 then
			self:_wait(attempt)
		end
	end
	return false, false
end

function ShopImpl._setOwned(self: Shop, player: any, pass: PassDef, owned: boolean)
	local userId = player.UserId
	local byPlayer = self.owned[userId]
	if byPlayer == nil then
		byPlayer = {}
		self.owned[userId] = byPlayer
	end
	local before = byPlayer[pass.key] == true
	byPlayer[pass.key] = owned
	if before ~= owned and self.cfg.onPassChanged then
		local ok, err = pcall(self.cfg.onPassChanged, player, pass, owned)
		if not ok then
			self:_log("onPassChanged fallo: " .. tostring(err))
		end
	end
end

--[[
	Concesion UNICA ligada a un pase (p. ej. pack de inicio). Idempotente: el perfil guarda
	passGrants[passKey]. Devuelve true si quedo concedida y guardada (o ya lo estaba).
]]
function ShopImpl._applyOneTimeGrant(self: Shop, player: any, pass: PassDef): boolean
	local grant = pass.oneTimeGrant
	if grant == nil then
		return true
	end
	local profile = self.cfg.waitForProfile(player.UserId, self.cfg.profileWaitSeconds or 20)
	if profile == nil or not profile:isActive() then
		return false
	end
	local data = profile.data
	if type(data.passGrants) ~= "table" then
		data.passGrants = {}
	end
	if data.passGrants[pass.key] == nil then
		local handler = self.cfg.grants[grant.kind]
		if handler == nil then
			self:_log("pase " .. pass.key .. ": sin handler para " .. tostring(grant.kind))
			return false
		end
		local ok, applied = pcall(handler, player, profile, { key = pass.key, grant = grant, kind = grant.kind }, nil)
		if not ok or applied ~= true then
			self:_log("concesion unica de " .. pass.key .. " fallo: " .. tostring(applied))
			return false
		end
		data.passGrants[pass.key] = self.nowFn()
		profile:markDirty()
	end
	return profile:save()
end

--[[
	Llamar cuando el perfil del jugador esta listo. Consulta la propiedad de TODOS los pases (en paralelo, para
	aprovechar el batching transparente) y aplica las concesiones unicas pendientes.
]]
function ShopImpl.loadPlayer(self: Shop, player: any)
	local pending = 0
	for _, pass in self.catalog.passes do
		if pass.id ~= 0 and pass.enabled ~= false then
			pending += 1
			self.taskLib.spawn(function()
				local ok, owns = self:_checkOwnership(player, pass)
				if ok then
					self:_setOwned(player, pass, owns)
					if owns and pass.oneTimeGrant then
						self:_applyOneTimeGrant(player, pass)
					end
				else
					self:_log("no se pudo comprobar el pase " .. pass.key .. " de " .. tostring(player.UserId))
				end
				pending -= 1
			end)
		end
	end
	local waited = 0
	while pending > 0 and waited < 30 do
		self:_wait(0.25)
		waited += 0.25
	end
end

-- Llamar en PlayerRemoving: libera caches del jugador.
function ShopImpl.unloadPlayer(self: Shop, player: any)
	local userId = player.UserId
	self.owned[userId] = nil
	self.policies[userId] = nil
	self.policyRetryAt[userId] = nil
	self.lastPrompt[userId] = nil
end

function ShopImpl._onPassPromptFinished(self: Shop, player: any, passId: number, wasPurchased: boolean)
	local pass = self.passesById[passId]
	if pass == nil or pass.enabled == false or not wasPurchased then
		return
	end
	-- Re-verificar (la cache de UserOwnsGamePassAsync se actualiza con este evento). Si la
	-- verificacion falla por red, se confia en el evento del SERVIDOR (documentado como resultado final).
	local ok, owns = self:_checkOwnership(player, pass)
	if ok and not owns then
		self:_log("PromptGamePassPurchaseFinished dijo comprado pero UserOwnsGamePassAsync = false: " .. pass.key)
		return
	end
	self:_setOwned(player, pass, true)
	if pass.oneTimeGrant then
		self:_applyOneTimeGrant(player, pass)
	end
end

----------------------------------------------------------------------------
-- Prompts (el cliente solo solicita; el servidor decide)
----------------------------------------------------------------------------

-- Devuelve (true) o (false, motivo). Motivos: "unknown" | "unavailable" | "loading" | "restricted" | "owned" | "cooldown" | "left"
function ShopImpl.canOffer(self: Shop, player: any, itemKind: string, key: string): (boolean, string?)
	local item: any = if itemKind == "pass" then self.catalog.passes[key] else self.catalog.products[key]
	if item == nil then
		return false, "unknown"
	end
	if item.id == 0 or item.enabled == false then
		return false, "unavailable" -- placeholder TODO_ID o funcion apagada
	end
	if player.Parent == nil then
		return false, "left"
	end
	local profile = self.cfg.waitForProfile(player.UserId, 0)
	if profile == nil or not profile:isActive() then
		return false, "loading" -- no vender antes de que el perfil este cargado y activo
	end
	if item.affectsOdds then
		local info = self:getPolicy(player)
		local restricted = info == nil or info.ArePaidRandomItemsRestricted ~= false
		if restricted then
			return false, "restricted"
		end
	end
	if itemKind == "pass" and self:ownsPass(player, key) then
		return false, "owned"
	end
	return true, nil
end

function ShopImpl._cooldownOk(self: Shop, player: any): boolean
	local now = self.nowFn()
	local last = self.lastPrompt[player.UserId]
	local cooldown = self.cfg.promptCooldownSeconds or 3
	if last ~= nil and now - last < cooldown then
		return false
	end
	self.lastPrompt[player.UserId] = now
	return true
end

function ShopImpl.promptProduct(self: Shop, player: any, productKey: string): (boolean, string?)
	local ok, reason = self:canOffer(player, "product", productKey)
	if not ok then
		return false, reason
	end
	if not self:_cooldownOk(player) then
		return false, "cooldown"
	end
	local product = self.catalog.products[productKey]
	local success, err = pcall(function()
		self.cfg.marketplace:PromptProductPurchase(player, product.id)
	end)
	if not success then
		self:_log("PromptProductPurchase fallo: " .. tostring(err))
		return false, "error"
	end
	return true, nil
end

function ShopImpl.promptPass(self: Shop, player: any, passKey: string): (boolean, string?)
	local ok, reason = self:canOffer(player, "pass", passKey)
	if not ok then
		return false, reason
	end
	if not self:_cooldownOk(player) then
		return false, "cooldown"
	end
	local pass = self.catalog.passes[passKey]
	local success, err = pcall(function()
		self.cfg.marketplace:PromptGamePassPurchase(player, pass.id)
	end)
	if not success then
		self:_log("PromptGamePassPurchase fallo: " .. tostring(err))
		return false, "error"
	end
	return true, nil
end

----------------------------------------------------------------------------
-- Precios mostrados (la fuente es Roblox, no el codigo)
----------------------------------------------------------------------------

-- Consulta precios reales (regional pricing). Los que fallen usan el precio de la escalera (aproximado).
function ShopImpl.refreshPrices(self: Shop)
	local types = self.cfg.infoTypes
	if types == nil then
		return
	end
	local marketplace = self.cfg.marketplace
	local function fetch(id: number, infoType: any): number?
		for attempt = 1, 3 do
			local ok, info = pcall(function(): any
				return marketplace:GetProductInfoAsync(id, infoType)
			end)
			if ok and type(info) == "table" and type(info.PriceInRobux) == "number" then
				return info.PriceInRobux
			end
			if attempt < 3 then
				self:_wait(attempt)
			end
		end
		return nil
	end
	for key, product in self.catalog.products do
		if product.id ~= 0 and product.enabled ~= false then
			local price = fetch(product.id, types.Product)
			if price then
				self.priceCache["product:" .. key] = price
			end
		end
	end
	for key, pass in self.catalog.passes do
		if pass.id ~= 0 and pass.enabled ~= false then
			local price = fetch(pass.id, types.GamePass)
			if price then
				self.priceCache["pass:" .. key] = price
			end
		end
	end
end

export type Offer = {
	kind: string, -- "pass" | "product"
	key: string,
	name: string,
	description: string,
	priceRobux: number?,
	priceIsApproximate: boolean,
	available: boolean,
	reason: string?, -- por que no esta disponible ("owned" | "restricted" | "unavailable" | "loading")
	owned: boolean,
}

-- Datos para la UI de la tienda de ESTE jugador (sin textos de urgencia).
function ShopImpl.getOffers(self: Shop, player: any): { Offer }
	local offers: { Offer } = {}
	local function add(kind: string, key: string, item: any)
		if item.enabled == false then
			return -- funcion apagada: ni siquiera se muestra en la tienda
		end
		local cached = self.priceCache[kind .. ":" .. key]
		local price = cached or Shop.resolvePrice(self.catalog, item)
		local available, reason = self:canOffer(player, kind, key)
		table.insert(offers, {
			kind = kind,
			key = key,
			name = item.name,
			description = item.description,
			priceRobux = price,
			priceIsApproximate = cached == nil,
			available = available,
			reason = reason,
			owned = kind == "pass" and self:ownsPass(player, key),
		})
	end
	local passKeys: { string } = {}
	for key in self.catalog.passes do
		table.insert(passKeys, key)
	end
	table.sort(passKeys)
	for _, key in passKeys do
		add("pass", key, self.catalog.passes[key])
	end
	local productKeys: { string } = {}
	for key in self.catalog.products do
		table.insert(productKeys, key)
	end
	table.sort(productKeys)
	for _, key in productKeys do
		add("product", key, self.catalog.products[key])
	end
	return offers
end

----------------------------------------------------------------------------
-- Arranque
----------------------------------------------------------------------------

--[[
	Registra el UNICO ProcessReceipt y escucha el fin de los prompts de pases.
	Devuelve la funcion de ProcessReceipt por si el llamador quiere probarla directamente.
]]
-- VERIFY: la referencia oficial de MarketplaceService (2026-10-20) llama a ProcessReceipt "legacy" y documenta
-- BindReceiptHandler(Enum.ReceiptType.DeveloperProduct, handler, filter?) con Enum.ReceiptDecision. ProcessReceipt sigue
-- funcionando y es lo que pide este proyecto; migrar a BindReceiptHandler es un cambio mecanico (misma logica,
-- otro enum de retorno) que debe probarse en Studio con compras reales de prueba antes de adoptarlo.
function ShopImpl.start(self: Shop): (receipt: Receipt) -> any
	assert(not self.started, "Shop.start ya se ejecuto")
	if processReceiptOwner ~= nil and processReceiptOwner ~= self then
		self:_log("AVISO: ya existe otro Shop con ProcessReceipt; solo puede haber UNO por servidor")
	end
	self.started = true
	processReceiptOwner = self
	local callback = function(receipt: Receipt): any
		return self:processReceipt(receipt)
	end
	self.cfg.marketplace.ProcessReceipt = callback
	local signal = self.cfg.marketplace.PromptGamePassPurchaseFinished
	if signal ~= nil then
		local connection = signal:Connect(function(player: any, passId: number, wasPurchased: boolean)
			self:_onPassPromptFinished(player, passId, wasPurchased)
		end)
		table.insert(self.connections, connection)
	end
	return callback
end

function ShopImpl.stop(self: Shop)
	for _, connection in self.connections do
		connection:Disconnect()
	end
	self.connections = {}
	if processReceiptOwner == self then
		processReceiptOwner = nil
	end
	self.started = false
end

return Shop
