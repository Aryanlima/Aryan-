--!nonstrict
--[[
	Arnes de integracion de GameService (el "pegamento" del servidor, ~820 lineas que NINGUN otro test ejecuta).

	Como funciona: GameService usa globales de Roblox (game, Instance, Enum, task, Random, os...). Aqui se carga
	su codigo (y el de los paquetes que usa) con `luau.load` y un ENTORNO propio: `game` falso con servicios falsos,
	`task` y `os.time/os.clock` ligados al reloj simulado del testkit, `Instance.new` que devuelve remotos falsos.
	Asi se puede ejecutar `GameService.start(m)` entero y disparar los remotos como lo haria un cliente.

	Limites (lo que esto NO prueba): el motor real (replicacion, orden de scripts, Rojo), ni los servicios reales.
	Es una ejecucion con dobles, no un playtest en Studio.

	Rutas: se calculan a partir de la ubicacion de support/ServerHarness.luau (tests/support/ -> ../../src, ../../../../packages).
	El arnes (buildWorld) vive en tests/support/ServerHarness.luau para compartirlo con ClientBoot.spec.
]]
local testkit = require("@testkit")
local Mocks = require("@testkit/mocks")
local ServerHarness = require("./support/ServerHarness")

local describe, it, expect, beforeEach = testkit.describe, testkit.it, testkit.expect, testkit.beforeEach

local buildWorld, FAKE_IDS, USER, KEY =
	ServerHarness.buildWorld, ServerHarness.FAKE_IDS, ServerHarness.USER, ServerHarness.KEY

describe("GameService (arnes de integracion con dobles)", function()
	local world, env

	beforeEach(function()
		world = buildWorld()
		env = world.env
	end)

	it("arranca sin errores y registra ProcessReceipt, BindToClose y los 16 remotos de entrada", function()
		expect(env.MarketplaceService.ProcessReceipt).toBeTruthy()
		expect(world.bindToClose).toBeTruthy()
		local inbound = 0
		for _, remote in world.remotes do
			if remote.OnServerEvent and #remote.OnServerEvent._handlers > 0 then
				inbound += 1
			end
		end
		expect(inbound).toBe(16)
		env.clock:assertNoErrors()
	end)

	it(
		"Studio con un lugar sin publicar (GetDataStore lanza): arranca con el almacen en memoria, sin caerse",
		function()
			local w = buildWorld({ unpublished = true, mocks = { runService = { isStudio = true } } })
			local player = w.join()
			expect(w.api.manager:get(USER):isActive()).toBe(true)
			expect(w.sentTo("State")[1].player).toBe(player)
			expect(table.concat(w.warnings, "\n")).toContain("MEMORIA")
			w.env.clock:assertNoErrors()
		end
	)

	it("servidor real (no Studio) sin acceso a DataStore: falla a proposito en vez de usar memoria", function()
		local ok = pcall(buildWorld, { unpublished = true })
		expect(ok).toBe(false)
	end)

	it("al entrar un jugador se carga el perfil y se le envia el estado inicial", function()
		local player = world.join()
		local profile = world.api.manager:get(USER)
		expect(profile).toBeTruthy()
		expect(profile:isActive()).toBe(true)
		local states = world.sentTo("State")
		expect(#states >= 1).toBe(true)
		expect(states[#states].player).toBe(player)
		expect(states[#states].args[1].coins).toBe(0)
		expect(states[#states].args[1].paidLuckEnabled).toBe(false)
		env.clock:assertNoErrors()
	end)

	it("autosave: un perfil activo se vuelve a guardar a los 2 minutos (y renueva el latido del bloqueo)", function()
		world.join()
		local before = env.DataStoreService:GetRequestCount("UpdateAsync")
		env.clock:advance(130)
		expect(env.DataStoreService:GetRequestCount("UpdateAsync") > before).toBe(true)
	end)

	it("pesca de punta a punta: Cast -> CastStarted -> Reel -> Catch y el inventario se guarda", function()
		local player = world.join()
		world.fire(player, "Cast")
		local started = world.sentTo("CastStarted")
		expect(#started).toBe(1)
		local session = started[1].args[1]
		expect(session.center >= 0.25 and session.center <= 0.75).toBe(true)
		env.clock:advance(0.8)
		world.fire(player, "Reel", session.id, 0.8)
		local catches = world.sentTo("Catch")
		expect(#catches).toBe(1)
		-- los 3 primeros lanzamientos son del tutorial: la primera captura es Poco comun
		expect(catches[1].args[1].rarity).toBe("Uncommon")
		local profile = world.api.manager:get(USER)
		expect(world.api.logic:inventoryCount(profile.data)).toBe(1)
		env.clock:assertNoErrors()
	end)

	it(
		"validacion de remotos: NaN, inf, fuera de rango, tipo erroneo y argumentos de mas se rechazan sin tocar el estado",
		function()
			local player = world.join()
			world.fire(player, "Cast")
			local session = world.sentTo("CastStarted")[1].args[1]
			env.clock:advance(0.8)
			local rejectedBefore = world.api.net:stats().rejected
			-- ni NaN, ni inf, ni 31 s (el maximo es 30), ni texto, ni un argumento extra
			world.fire(player, "Reel", session.id, 0 / 0)
			env.clock:advance(1)
			world.fire(player, "Reel", session.id, math.huge)
			env.clock:advance(1)
			world.fire(player, "Reel", session.id, 31)
			env.clock:advance(1)
			world.fire(player, "Reel", session.id, "0.8")
			env.clock:advance(1)
			world.fire(player, "Reel", session.id, 0.8, "extra")
			expect(world.api.net:stats().rejected - rejectedBefore).toBe(5)
			expect(#world.sentTo("Catch")).toBe(0)
			expect(#world.sentTo("CastFailed")).toBe(0) -- rechazados por Net, ni siquiera llegan a la logica
		end
	)

	it(
		"RequestPurchase solo acepta claves de catalogo con el patron [%w_]+ (el cliente nunca manda IDs ni precios)",
		function()
			local player = world.join()
			local rejectedBefore = world.api.net:stats().rejected
			world.fire(player, "RequestPurchase", "product", "coin pack; drop")
			world.fire(player, "RequestPurchase", "product", "../etc")
			world.fire(player, "RequestPurchase", "gift", "coin_pack_small")
			world.fire(player, "RequestPurchase", "product", 13) -- un ID numerico no vale
			expect(world.api.net:stats().rejected - rejectedBefore).toBe(4)
		end
	)

	it("limite de frecuencia: 30 RequestState seguidos no producen 30 respuestas", function()
		local player = world.join()
		local before = #world.sentTo("State")
		for _ = 1, 30 do
			world.remote("RequestState").OnServerEvent:Fire(player)
		end
		env.clock:advance(0.01)
		expect(#world.sentTo("State") - before <= 5).toBe(true)
		expect(world.api.net:stats().rejected >= 20).toBe(true)
	end)

	it("compra de un pack de monedas: se concede UNA vez, se guarda antes de confirmar y es idempotente", function()
		local player = world.join()
		local receipt, decision = env.MarketplaceService:SimulatePurchase(player, FAKE_IDS.products.coin_pack_small)
		env.clock:advance(1)
		expect(decision).toBe(env.Enum.ProductPurchaseDecision.PurchaseGranted)
		expect(world.stored().data.wallet.coins).toBe(2500)
		expect(world.stored().data.purchases[receipt.PurchaseId]).toBeTruthy()
		-- reentrega del mismo recibo
		local again = env.MarketplaceService:SimulateRedelivery(receipt.PurchaseId)
		env.clock:advance(1)
		expect(again).toBe(env.Enum.ProductPurchaseDecision.PurchaseGranted)
		expect(world.stored().data.wallet.coins).toBe(2500)
		-- y el cliente recibe un aviso y el estado actualizado
		expect(#world.sentTo("Toast") >= 1).toBe(true)
		env.clock:assertNoErrors()
	end)

	it("v1: el recibo de un producto de suerte (Cebo) NO se concede ni se confirma", function()
		local player = world.join()
		local _, decision = env.MarketplaceService:SimulatePurchase(player, FAKE_IDS.products.lucky_bait_15)
		env.clock:advance(1)
		expect(decision).toBe(env.Enum.ProductPurchaseDecision.NotProcessedYet)
		expect(next(world.stored().data.boosts)).toBeNil()
		expect(next(world.stored().data.purchases)).toBeNil()
	end)

	it("v1: la tienda no ofrece suerte y el servidor rechaza pedirla por clave", function()
		local player = world.join()
		world.fire(player, "RequestOffers")
		local offers = world.sentTo("Offers")[1].args[1]
		for _, offer in offers do
			expect(offer.key == "luck_plus" or offer.key == "lucky_bait_15").toBe(false)
		end
		world.fire(player, "RequestPurchase", "product", "lucky_bait_15")
		env.clock:advance(4)
		world.fire(player, "RequestPurchase", "pass", "luck_plus")
		local failed = world.sentTo("CastFailed")
		expect(#failed).toBe(2)
		expect(failed[1].args[1]).toBe("unavailable")
		expect(failed[2].args[1]).toBe("unavailable")
	end)

	it("SetAutoFish sin el pase Auto-Pesca no se activa", function()
		local player = world.join()
		world.fire(player, "SetAutoFish", true)
		expect(world.api.manager:get(USER).data.autoFish).toBe(false)
	end)

	it("SetAutoFish con el pase (propiedad verificada al entrar) si se activa", function()
		env.MarketplaceService:GrantGamePass(USER, FAKE_IDS.passes.auto_fish)
		local player = world.join()
		world.fire(player, "SetAutoFish", true)
		expect(world.api.manager:get(USER).data.autoFish).toBe(true)
	end)

	it("codigo de canje: se cobra UNA vez, aunque se envie dos veces seguidas, y se guarda enseguida", function()
		local player = world.join()
		world.remote("RedeemCode").OnServerEvent:Fire(player, "welcome")
		world.remote("RedeemCode").OnServerEvent:Fire(player, "WELCOME")
		env.clock:advance(1)
		local profile = world.api.manager:get(USER)
		expect(profile.data.wallet.coins).toBe(1000)
		expect(profile.data.wallet.pearls).toBe(5)
		expect(world.stored().data.wallet.coins).toBe(1000) -- guardado al momento (no espera al autosave)
	end)

	it("al salir el jugador: lastSeen (base del offline) se guarda y el bloqueo se libera", function()
		local player = world.join()
		env.clock:advance(500)
		local leftAt = env.clock.osTime()
		env.Players:RemovePlayer(player)
		env.clock:advance(5)
		local record = world.stored()
		expect(record.lock).toBeNil()
		expect(record.data.lastSeen).toBe(leftAt)
	end)

	it("BindToClose: guarda y libera a todos los jugadores", function()
		world.join(7001, "A")
		world.join(7002, "B")
		env.task.spawn(function()
			world.bindToClose()
		end)
		env.clock:advance(10)
		for _, uid in { 7001, 7002 } do
			local record = env.DataStoreService:GetDataStore(KEY):_peek("Player_" .. uid)
			expect(record.lock).toBeNil()
		end
	end)

	it("ganancias offline: solo con el reloj del SERVIDOR (os.time) y con tope", function()
		-- primera sesion: sale con rod = driftwood, 40 monedas/hora
		local player = world.join()
		env.clock:advance(10)
		env.Players:RemovePlayer(player)
		env.clock:advance(5)
		-- 10 horas despues vuelve: el tope base es 2 h => 80 monedas (40/h x 2 h x multiplicador 1)
		env.clock:advance(10 * 3600)
		world.join()
		env.clock:advance(2)
		local profile = world.api.manager:get(USER)
		expect(profile.data.wallet.coins).toBe(80)
	end)

	it(
		"BUG SHOP-05: no se ofrece (ni se abre el prompt de) un Boost cuyo tiempo ya esta en el tope de acumulacion",
		function()
			local player = world.join()
			local profile = world.api.manager:get(USER)
			profile.data.boosts.coin_boost = env.clock.osTime() + 3500 -- 1 h de tope: otro de 15 min se "comeria" lo pagado
			world.fire(player, "RequestPurchase", "product", "coin_boost_15")
			expect(#world.prompts).toBe(0)
			local failed = world.sentTo("CastFailed")
			expect(failed[#failed].args[1]).toBe("maxed")
			-- con tiempo de sobra en el tope si se ofrece
			profile.data.boosts.coin_boost = nil
			env.clock:advance(4)
			world.fire(player, "RequestPurchase", "product", "coin_boost_15")
			expect(#world.prompts).toBe(1)
			expect(world.prompts[1].id).toBe(FAKE_IDS.products.coin_boost_15)
		end
	)

	it(
		"v1 (flag apagado): ningun remoto consulta PolicyService (getPolicy cede y context() corre en cada remoto)",
		function()
			local player = world.join()
			world.fire(player, "Cast")
			env.clock:advance(0.8)
			world.fire(player, "Reel", world.sentTo("CastStarted")[1].args[1].id, 0.8)
			world.fire(player, "SellAll")
			world.fire(player, "RequestOffers")
			expect(world.policyCalls).toBe(0)
		end
	)

	it("BUG LIVEOPS-01: un premio mal formado en la configuracion remota NO gasta el codigo del jugador", function()
		local player = world.join()
		world.api.liveOps:getConfig().codes.BAD = { reward = { coins = "mucho" } }
		world.remote("RedeemCode").OnServerEvent:Fire(player, "BAD")
		env.clock:advance(1)
		local profile = world.api.manager:get(USER)
		expect(profile.data.redeemedCodes.BAD).toBeNil() -- sigue disponible cuando se corrija la configuracion
		expect(profile.data.wallet.coins).toBe(0)
	end)

	-- Eventos de economia (LogEconomyEvent) de tipo IAP registrados hasta ahora.
	local function iapEconomyEvents(w)
		local list = {}
		for _, entry in w.analytics do
			if entry.method == "LogEconomyEvent" and entry.args[6] == "IAP" then
				table.insert(list, entry)
			end
		end
		return list
	end

	it(
		"BUG ANALYTICS-01: el evento IAP solo sale DESPUES de guardar; si el guardado falla no se cuenta (ni se cuenta dos veces)",
		function()
			local player = world.join()
			env.DataStoreService:SetOutage(true)
			local receipt, decision = env.MarketplaceService:SimulatePurchase(player, FAKE_IDS.products.coin_pack_small)
			env.clock:advance(60)
			-- concedido en memoria pero NO guardado: Roblox lo reintentara; analitica a cero
			expect(decision).toBe(env.Enum.ProductPurchaseDecision.NotProcessedYet)
			expect(#iapEconomyEvents(world)).toBe(0)
			-- vuelve el DataStore: el reintento guarda y SOLO entonces se registra el evento (una vez)
			env.DataStoreService:SetOutage(false)
			local retried = env.MarketplaceService:SimulateRedelivery(receipt.PurchaseId)
			env.clock:advance(1)
			expect(retried).toBe(env.Enum.ProductPurchaseDecision.PurchaseGranted)
			local events = iapEconomyEvents(world)
			expect(#events).toBe(1)
			expect(events[1].args[4]).toBe(2500) -- amount
			expect(events[1].args[5]).toBe(2500) -- endingBalance
			expect(events[1].args[7]).toBe("coin_pack_small") -- sku
			-- otra reentrega del mismo recibo no vuelve a contar
			env.MarketplaceService:SimulateRedelivery(receipt.PurchaseId)
			env.clock:advance(1)
			expect(#iapEconomyEvents(world)).toBe(1)
			expect(world.stored().data.wallet.coins).toBe(2500)
		end
	)

	it(
		"ANALYTICS-01: con el guardado correcto el evento IAP se registra una vez y el resto de la economia no cambia",
		function()
			local player = world.join()
			env.MarketplaceService:SimulatePurchase(player, FAKE_IDS.products.coin_pack_small)
			env.clock:advance(1)
			expect(#iapEconomyEvents(world)).toBe(1)
			-- una venta normal sigue registrando su evento de economia en el momento (no es dinero real)
			world.fire(player, "Cast")
			env.clock:advance(0.8)
			world.fire(player, "Reel", world.sentTo("CastStarted")[1].args[1].id, 0.8)
			world.fire(player, "SellAll")
			local gameplay = 0
			for _, entry in world.analytics do
				if entry.method == "LogEconomyEvent" and entry.args[6] == "Gameplay" then
					gameplay += 1
				end
			end
			expect(gameplay >= 1).toBe(true)
			expect(#iapEconomyEvents(world)).toBe(1)
		end
	)

	it(
		"BUG OFFLINE-01: el autosave refresca lastSeen (tras un crash no se paga como offline el tiempo jugado)",
		function()
			world.join()
			local joinedAt = env.clock.osTime()
			env.clock:advance(500) -- sin salir ni BindToClose: solo hay autosaves cada 120 s
			local lastSeen = world.stored().data.lastSeen
			expect(lastSeen >= joinedAt + 360).toBe(true) -- antes: lastSeen seguia en el instante de entrada
			expect(lastSeen <= env.clock.osTime()).toBe(true)
		end
	)

	it(
		"OFFLINE-01: refrescar lastSeen no pisa el calculo offline de la entrada aunque loadPlayer tarde varios segundos",
		function()
			local player = world.join()
			env.clock:advance(10)
			env.Players:RemovePlayer(player)
			env.clock:advance(5)
			env.clock:advance(10 * 3600)
			-- la consulta de pases falla 3 veces (reintentos con espera): onLoaded tarda ~3 s antes de pagar el offline
			env.MarketplaceService:FailNext(3 * 6)
			world.join()
			env.clock:advance(10)
			expect(world.api.manager:get(USER).data.wallet.coins).toBe(80) -- 40/h x 2 h de tope
		end
	)

	-- Localizacion: el servidor envia CLAVES + argumentos validados (nunca texto traducido); el cliente traduce.
	local function validMessage(w, payload)
		local locale = w.m.Locale.new(w.m.Strings)
		local key, args = locale:sanitizeMessage(payload)
		return key, args, locale
	end

	it("i18n: los avisos (Toast) son { key, args } validos y se traducen a ES y EN con las mismas cifras", function()
		local player = world.join()
		world.fire(player, "SellAll") -- nada que vender
		world.fire(player, "Cast")
		env.clock:advance(0.8)
		world.fire(player, "Reel", world.sentTo("CastStarted")[1].args[1].id, 0.8)
		world.fire(player, "SellAll")
		env.MarketplaceService:SimulatePurchase(player, FAKE_IDS.products.coin_pack_small)
		env.clock:advance(1)
		local keys = {}
		for _, entry in world.sentTo("Toast") do
			local payload = entry.args[1]
			expect(type(payload)).toBe("table") -- nunca una cadena ya traducida
			local key, args, locale = validMessage(world, payload)
			expect(key).toBeTruthy()
			table.insert(keys, key)
			for _, language in { "es", "en" } do
				local text = locale:format(language, key, args)
				expect(string.find(text, "[{}]") == nil).toBe(true) -- sin marcadores sin sustituir
			end
			if key == "toast.sold" then
				expect(args.count).toBe(1)
				expect(locale:format("en", key, args)).toBe(
					"Sold 1 catch for " .. locale:number("en", args.coins) .. " coins."
				)
				expect(locale:format("es", key, args)).toContain("Vendiste 1 captura por")
			end
			if key == "toast.purchase_received" then
				expect(args.item).toEqual({ key = "product.coin_pack_small.name" })
				expect(locale:format("en", key, args)).toBe("Purchase received: Small Coin Pack")
				expect(locale:format("es", key, args)).toBe("Compra recibida: Pack de monedas pequeño")
			end
		end
		expect(table.find(keys, "toast.nothing_to_sell") ~= nil).toBe(true)
		expect(table.find(keys, "toast.sold") ~= nil).toBe(true)
		expect(table.find(keys, "toast.purchase_received") ~= nil).toBe(true)
	end)

	it("i18n: el aviso de ganancias offline, el canje de codigos y la bienvenida llegan como claves", function()
		local player = world.join()
		-- la bienvenida por defecto tiene clave propia (welcome.launch)
		local welcomeKeys = {}
		for _, entry in world.sentTo("Toast") do
			table.insert(welcomeKeys, entry.args[1].key)
		end
		expect(table.find(welcomeKeys, "welcome.launch") ~= nil).toBe(true)
		world.remote("RedeemCode").OnServerEvent:Fire(player, "WELCOME")
		env.clock:advance(1)
		world.remote("RedeemCode").OnServerEvent:Fire(player, "NOEXISTE")
		env.clock:advance(1)
		local keys = {}
		for _, entry in world.sentTo("Toast") do
			table.insert(keys, entry.args[1].key)
		end
		expect(table.find(keys, "toast.code_redeemed") ~= nil).toBe(true)
		expect(table.find(keys, "toast.code_unknown") ~= nil).toBe(true)
	end)

	it("i18n: un mensaje de bienvenida de la configuracion remota sin traduccion se envia como toast.raw", function()
		world.api.liveOps:getConfig().welcome = { id = "w-remoto", message = "Mensaje remoto" }
		local player = world.join()
		local found = false
		for _, entry in world.sentTo("Toast") do
			local payload = entry.args[1]
			if payload.key == "toast.raw" then
				found = true
				expect(payload.args.text).toBe("Mensaje remoto")
				expect(validMessage(world, payload)).toBe("toast.raw")
			end
		end
		expect(found).toBe(true)
		expect(player).toBeTruthy()
	end)

	it("i18n: el banner de MITICO viaja como mensaje con referencias a criatura y zona (no como texto)", function()
		local mythicWorld = buildWorld({
			random = function()
				return 0.99999
			end,
		})
		local player = mythicWorld.join(USER, "Alice")
		for _ = 1, 4 do
			mythicWorld.fire(player, "Cast")
			mythicWorld.env.clock:advance(0.8)
			local started = mythicWorld.sentTo("CastStarted")
			mythicWorld.fire(player, "Reel", started[#started].args[1].id, 0.8)
			mythicWorld.env.clock:advance(1.2)
		end
		local banners = mythicWorld.sentTo("Banner")
		expect(#banners >= 1).toBe(true)
		local payload = banners[1].args[1]
		local key, args, locale = validMessage(mythicWorld, payload)
		expect(key).toBe("banner.mythic")
		expect(args.player).toBe("Alice")
		expect(args.creature).toEqual({ key = "creature.lake_spirit" })
		expect(args.zone).toEqual({ key = "zone.lake.name" })
		expect(locale:format("en", assert(key, "clave"), args)).toBe("Alice caught a MYTHIC: Lake Spirit (Calm Lake)")
		expect(locale:format("es", assert(key, "clave"), args)).toBe(
			"Alice pescó un MÍTICO: Espíritu del Lago (Lago Calmo)"
		)
		-- la captura ya no lleva el nombre: el cliente lo traduce con el id
		local catches = mythicWorld.sentTo("Catch")
		expect(catches[4].args[1].name).toBeNil()
		expect(catches[4].args[1].id).toBe("lake_spirit")
	end)

	it(
		"i18n: las ofertas de la tienda llevan claves y argumentos ademas del texto de respaldo (y 'maxed' sigue siendo un motivo)",
		function()
			local player = world.join()
			world.fire(player, "RequestOffers")
			local offers = world.sentTo("Offers")[1].args[1]
			local locale = world.m.Locale.new(world.m.Strings)
			local seen = 0
			for _, offer in offers do
				seen += 1
				expect(offer.nameKey).toBe(offer.kind .. "." .. offer.key .. ".name")
				expect(offer.descriptionKey).toBe(offer.kind .. "." .. offer.key .. ".desc")
				local key, args = locale:sanitizeMessage(
					{ key = offer.descriptionKey, args = offer.textArgs },
					{ prefixes = { "pass.", "product." }, lenient = true }
				)
				expect(key).toBe(offer.descriptionKey)
				expect(string.find(locale:format("en", assert(key, "clave"), args), "[{}]") == nil).toBe(true)
				expect(#offer.name > 0).toBe(true) -- texto de respaldo en espanol
			end
			expect(seen).toBe(11)
		end
	)

	it("i18n: las expulsiones de Data muestran ES y EN juntos (el servidor no conoce el idioma del jugador)", function()
		local manager = world.api.manager
		for name, spanishFragment in
			{ locked = "Espera un minuto", loadFailed = "No pudimos cargar", lockLost = "otro servidor" }
		do
			local text = manager:_message(name)
			expect(text).toContain(spanishFragment)
			expect(string.find(text, "rejoin", 1, true) ~= nil).toBe(true)
		end
	end)

	it(
		"BUG BANNER-01: el aviso global de MITICO recorta el nombre por CARACTERES (UTF-8 valido) y llega a otros servidores",
		function()
			-- rng = 0.99999: la ultima criatura de la tabla del Lago es el Mitico (tras los 3 lanzamientos del tutorial)
			local mythicWorld = buildWorld({
				random = function()
					return 0.99999
				end,
			})
			local mythicEnv = mythicWorld.env
			local longName = string.rep("\u{6F22}", 20) -- 20 caracteres = 60 bytes
			local player = mythicWorld.join(USER, "Alice", { DisplayName = longName })
			for _ = 1, 4 do
				mythicWorld.fire(player, "Cast")
				mythicEnv.clock:advance(0.8)
				local started = mythicWorld.sentTo("CastStarted")
				mythicWorld.fire(player, "Reel", started[#started].args[1].id, 0.8)
				mythicEnv.clock:advance(1.2)
			end
			local catches = mythicWorld.sentTo("Catch")
			expect(catches[4].args[1].rarity).toBe("Mythic")
			expect(#mythicWorld.sentTo("Banner") >= 1).toBe(true)
			expect(#mythicWorld.published).toBe(1)
			local shown = mythicWorld.published[1].message.p
			expect(utf8.len(shown)).toBe(20) -- antes: nil (corte por bytes en mitad de un caracter)
		end
	)
end)

----------------------------------------------------------------------------
-- Arranque y ciclo de vida del personaje (hallazgos de docs/verificacion-estructura.md: ST-04 y ST-05)
----------------------------------------------------------------------------

-- Personaje falso: una mano (BasePart) para la cana y PivotTo registrado. El Vector3/CFrame del arnes llevan la zona en
-- `position.zone` (ver support/ServerHarness.luau).
local function fakeCharacter()
	local pivots = {}
	local hand = {
		ClassName = "MeshPart",
		Name = "RightHand",
		CFrame = setmetatable({}, {
			__mul = function()
				return {}
			end,
		}),
	}
	function hand.IsA(_self, className)
		return className == "BasePart" or className == "Instance"
	end
	local character = { ClassName = "Model", Name = "Personaje", pivots = pivots }
	function character.FindFirstChild(_self, name)
		if name == "RightHand" then
			return hand
		end
		return nil
	end
	function character.PivotTo(_self, cframe)
		table.insert(pivots, cframe)
	end
	return character
end

local function lastRodColor(world)
	for index = #world.created, 1, -1 do
		local instance = world.created[index]
		if instance.ClassName == "Part" and instance.Name == "FishingRod" then
			return instance.Color
		end
	end
	return nil
end

local function rodColor(world, rodId)
	local color = world.m.Balance.rods[rodId].color
	return { r = color[1], g = color[2], b = color[3] }
end

describe("GameService: arranque y personaje", function()
	it("un MessagingService lento no retrasa el arranque (SubscribeAsync no cede el hilo de arranque)", function()
		local slow = buildWorld({ messagingStallSeconds = 60 })
		-- si el arranque esperara a SubscribeAsync, el reloj simulado habria avanzado ~60 s antes de volver
		expect(slow.env.clock:now() < 1).toBe(true)
		slow.join()
		expect(slow.api.manager:get(USER):isActive()).toBe(true)
		slow.env.clock:assertNoErrors()
	end)

	it("si el perfil carga ANTES que el personaje, al aparecer se le pone su cana y se le lleva a su zona", function()
		local world = buildWorld()
		local env = world.env
		local player = world.join()
		local data = world.api.manager:get(USER).data
		data.rod = "reed"
		data.zone = "river"
		local character = fakeCharacter()
		player.Character = character
		player.CharacterAdded:Fire(character)
		env.clock:advance(0.1)
		expect(lastRodColor(world)).toEqual(rodColor(world, "reed"))
		expect(#character.pivots).toBe(1)
		expect(character.pivots[1].position.zone).toBe("river")
		env.clock:assertNoErrors()
	end)

	it("en el Lago no se teletransporta al aparecer (ya sale en su SpawnLocation)", function()
		local world = buildWorld()
		local player = world.join()
		local character = fakeCharacter()
		player.Character = character
		player.CharacterAdded:Fire(character)
		world.env.clock:advance(0.1)
		expect(#character.pivots).toBe(0)
		expect(lastRodColor(world)).toEqual(rodColor(world, "driftwood"))
	end)

	it("si el personaje aparece ANTES que el perfil, al cargar se corrige la cana y se le lleva a su zona", function()
		local world = buildWorld()
		local env = world.env
		-- sesion 1: guardar cana y zona
		local first = world.join()
		local data = world.api.manager:get(USER).data
		data.rod = "reed"
		data.zone = "river"
		world.api.manager:get(USER):markDirty()
		env.Players:RemovePlayer(first)
		env.clock:advance(5)
		-- sesion 2: el personaje aparece antes de que termine de cargar el perfil (el DataStore tarda 0,5 s por peticion)
		env.DataStoreService:SetLatency(0.5)
		local second = env.Players:AddPlayer(USER, "Alice", { fire = false })
		second.CharacterAdded = Mocks.Signal.new({ spawn = env.task.spawn })
		env.Players.PlayerAdded:Fire(second)
		local character = fakeCharacter()
		second.Character = character
		second.CharacterAdded:Fire(character)
		env.clock:advance(0.01)
		expect(lastRodColor(world)).toEqual(rodColor(world, "driftwood")) -- aun sin perfil: cana por defecto
		env.clock:advance(8) -- termina de cargar el perfil -> onLoaded
		expect(world.api.manager:get(USER).data.rod).toBe("reed")
		expect(lastRodColor(world)).toEqual(rodColor(world, "reed"))
		expect(character.pivots[#character.pivots].position.zone).toBe("river")
		env.clock:assertNoErrors()
	end)
end)

----------------------------------------------------------------------------
-- Arte generado (opcional): GameService solo delega en m.ArtDirector (ver server/ArtDirector.luau)
----------------------------------------------------------------------------

local function fakeArtDirector(attachResult)
	local director = { provider = { isFakeProvider = true }, rods = {}, catches = {}, statusLogged = 0 }
	director.attachRod = function(rodId, hand, character)
		table.insert(director.rods, { rodId = rodId, hand = hand, character = character })
		return attachResult
	end
	director.showCatch = function(info)
		table.insert(director.catches, info)
		return true
	end
	director.logStatus = function()
		director.statusLogged += 1
	end
	return director
end

local function castUntilMythic(world, player)
	for _ = 1, 4 do
		world.fire(player, "Cast")
		world.env.clock:advance(0.8)
		local started = world.sentTo("CastStarted")
		world.fire(player, "Reel", started[#started].args[1].id, 0.8)
		world.env.clock:advance(1.2)
	end
end

describe("GameService con arte generado (ArtDirector opcional)", function()
	it("SIN ArtDirector: WorldBuilder no recibe proveedor y la cana es la procedural de siempre", function()
		local world = buildWorld()
		expect(world.builtWithArt).toBeNil()
		local player = world.join()
		local character = fakeCharacter()
		player.Character = character
		player.CharacterAdded:Fire(character)
		world.env.clock:advance(0.1)
		expect(lastRodColor(world)).toEqual(rodColor(world, "driftwood"))
		world.env.clock:assertNoErrors()
	end)

	it("CON ArtDirector: entrega su proveedor a WorldBuilder y registra el resumen de arranque una vez", function()
		local director = fakeArtDirector(false)
		local world = buildWorld({ artDirector = director })
		expect(world.builtWithArt).toBe(director.provider)
		expect(director.statusLogged).toBe(1)
	end)

	it("cana de arte: si attachRod devuelve true NO se crea la cana procedural", function()
		local director = fakeArtDirector(true)
		local world = buildWorld({ artDirector = director })
		local player = world.join()
		local data = world.api.manager:get(USER).data
		data.rod = "reed"
		local character = fakeCharacter()
		player.Character = character
		player.CharacterAdded:Fire(character)
		world.env.clock:advance(0.1)
		expect(#director.rods >= 1).toBe(true)
		local last = director.rods[#director.rods]
		expect(last.rodId).toBe("reed")
		expect(last.character).toBe(character)
		expect(last.hand.Name).toBe("RightHand")
		expect(lastRodColor(world)).toBeNil() -- ninguna Part "FishingRod" procedural
		world.env.clock:assertNoErrors()
	end)

	it("cana sin arte valido: attachRod devuelve false y se usa el respaldo procedural", function()
		local director = fakeArtDirector(false)
		local world = buildWorld({ artDirector = director })
		local player = world.join()
		local character = fakeCharacter()
		player.Character = character
		player.CharacterAdded:Fire(character)
		world.env.clock:advance(0.1)
		expect(#director.rods >= 1).toBe(true)
		expect(lastRodColor(world)).toEqual(rodColor(world, "driftwood"))
	end)

	it("captura Mitica: showCatch recibe zona, criatura, rareza, punto de lanzamiento y auto=false", function()
		local director = fakeArtDirector(false)
		local world = buildWorld({
			artDirector = director,
			random = function()
				return 0.99999
			end,
		})
		local player = world.join()
		castUntilMythic(world, player)
		local catches = world.sentTo("Catch")
		expect(catches[4].args[1].rarity).toBe("Mythic")
		expect(#director.catches).toBe(4) -- una llamada por captura (el director decide si la muestra)
		local mythic = director.catches[4]
		expect(mythic.rarity).toBe("Mythic")
		expect(mythic.zone).toBe("lake")
		expect(mythic.creatureId).toBe(catches[4].args[1].id)
		expect(mythic.position).toEqual({ castOf = "lake" })
		expect(mythic.auto).toBe(false)
		world.env.clock:assertNoErrors()
	end)

	it("si showCatch falla, la captura, el banner y el guardado siguen intactos", function()
		local director = fakeArtDirector(false)
		director.showCatch = function()
			error("fallo del escaparate")
		end
		local world = buildWorld({
			artDirector = director,
			random = function()
				return 0.99999
			end,
		})
		local player = world.join()
		castUntilMythic(world, player)
		expect(world.sentTo("Catch")[4].args[1].rarity).toBe("Mythic")
		expect(#world.sentTo("Banner") >= 1).toBe(true)
		expect(world.api.manager:get(USER).data.bestiary ~= nil).toBe(true)
		world.env.clock:assertNoErrors()
	end)
end)
