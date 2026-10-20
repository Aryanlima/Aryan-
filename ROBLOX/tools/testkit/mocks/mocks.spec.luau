--!nonstrict
--!nolint DeprecatedApi
-- Tests de los mocks de servicios de Roblox (Clock, Signal, Players, RunService, DataStore, Marketplace).

local testkit = require("@testkit")
local Mocks = require("@testkit/mocks")

local describe, it, expect, beforeEach = testkit.describe, testkit.it, testkit.expect, testkit.beforeEach

describe("Clock (reloj controlable)", function()
	local env, clock

	beforeEach(function()
		env = Mocks.new()
		clock = env.clock
	end)

	it("advance ejecuta task.delay en orden de tiempo", function()
		local order = {}
		clock.task.delay(2, function()
			table.insert(order, "b")
		end)
		clock.task.delay(1, function()
			table.insert(order, "a")
		end)
		clock:advance(1.5)
		expect(order).toEqual({ "a" })
		clock:advance(1)
		expect(order).toEqual({ "a", "b" })
		expect(clock:now()).toBeCloseTo(2.5, 6)
	end)

	it("task.wait dentro de un hilo gestionado cede hasta que el reloj avanza", function()
		local log = {}
		clock.task.spawn(function()
			table.insert(log, "inicio")
			local elapsed = clock.task.wait(5)
			table.insert(log, "fin tras " .. tostring(elapsed))
		end)
		expect(log).toEqual({ "inicio" })
		clock:advance(4.9)
		expect(log).toEqual({ "inicio" })
		clock:advance(0.2)
		expect(log).toEqual({ "inicio", "fin tras 5" })
	end)

	it("task.wait en el cuerpo del test hace pasar el tiempo (y corre lo pendiente)", function()
		local fired = false
		clock.task.delay(10, function()
			fired = true
		end)
		clock.task.wait(10)
		expect(fired).toBe(true)
		expect(clock:now()).toBe(10)
	end)

	it("bucle con task.wait se puede avanzar de forma determinista", function()
		local ticks = 0
		clock.task.spawn(function()
			while true do
				clock.task.wait(1)
				ticks += 1
			end
		end)
		clock:advance(10)
		expect(ticks).toBe(10)
	end)

	it("task.cancel evita que corra un delay", function()
		local ran = false
		local handle = clock.task.delay(1, function()
			ran = true
		end)
		clock.task.cancel(handle)
		clock:advance(5)
		expect(ran).toBe(false)
		expect(clock:pending()).toBe(0)
	end)

	it("task.defer corre en el siguiente flush; runAll vacia la cola", function()
		local log = {}
		clock.task.defer(function()
			table.insert(log, "defer")
		end)
		expect(log).toEqual({})
		clock:flush()
		expect(log).toEqual({ "defer" })
		clock.task.delay(100, function()
			table.insert(log, "tarde")
		end)
		clock:runAll()
		expect(log).toEqual({ "defer", "tarde" })
	end)

	it("los errores en hilos del reloj se acumulan y assertNoErrors los lanza", function()
		clock.task.spawn(function()
			error("fallo interno")
		end)
		expect(#clock.errors).toBe(1)
		expect(function()
			clock:assertNoErrors()
		end).toThrow("fallo interno")
	end)

	it("time/tick/osTime siguen al reloj simulado", function()
		clock:advance(30)
		expect(clock.time()).toBe(30)
		expect(clock.tick()).toBe(1700000030)
		expect(clock.osTime()).toBe(1700000030)
	end)
end)

describe("Signal", function()
	it("Connect / Once / Disconnect", function()
		local signal = Mocks.Signal.new()
		local calls = {}
		local connection = signal:Connect(function(a)
			table.insert(calls, "c" .. a)
		end)
		signal:Once(function(a)
			table.insert(calls, "o" .. a)
		end)
		signal:Fire(1)
		signal:Fire(2)
		connection.Disconnect()
		signal:Fire(3)
		expect(calls).toEqual({ "c1", "o1", "c2" })
		expect(signal:ConnectionCount()).toBe(0)
	end)

	it("un handler que falla no impide los demas y el error queda registrado", function()
		local signal = Mocks.Signal.new({ quiet = true })
		local reached = false
		signal:Connect(function()
			error("handler roto")
		end)
		signal:Connect(function()
			reached = true
		end)
		signal:Fire()
		expect(reached).toBe(true)
		expect(signal.errors[1]).toContain("handler roto")
	end)

	it("Wait devuelve los argumentos del siguiente Fire", function()
		local env = Mocks.new()
		local signal = Mocks.Signal.new({ spawn = env.clock.task.spawn })
		local got
		env.clock.task.spawn(function()
			got = table.pack(signal:Wait())
		end)
		expect(got).toBeNil()
		signal:Fire("x", 2)
		expect(got[1]).toBe("x")
		expect(got[2]).toBe(2)
	end)
end)

describe("Players", function()
	it("dispara PlayerAdded / PlayerRemoving y mantiene la lista", function()
		local env = Mocks.new()
		local events = {}
		env.Players.PlayerAdded:Connect(function(p)
			table.insert(events, "added:" .. p.Name)
		end)
		env.Players.PlayerRemoving:Connect(function(p)
			table.insert(events, "removing:" .. p.Name)
		end)
		local alice = env.Players:AddPlayer(1, "Alice")
		env.Players:AddPlayer(2, "Bob")
		expect(#env.Players:GetPlayers()).toBe(2)
		expect(env.Players:GetPlayerByUserId(2).Name).toBe("Bob")

		env.Players:RemovePlayer(alice)
		expect(events).toEqual({ "added:Alice", "added:Bob", "removing:Alice" })
		expect(env.Players:GetPlayerByUserId(1)).toBeNil()
		expect(alice.Parent).toBeNil()
	end)

	it("Kick guarda la razon y quita al jugador", function()
		local env = Mocks.new()
		local p = env.Players:AddPlayer(5)
		p:Kick("trampas")
		expect(p.kicked).toBe("trampas")
		expect(#env.Players:GetPlayers()).toBe(0)
	end)

	it("rechaza userIds duplicados", function()
		local env = Mocks.new()
		env.Players:AddPlayer(1)
		expect(function()
			env.Players:AddPlayer(1)
		end).toThrow("duplicado")
	end)
end)

describe("RunService", function()
	it("Step dispara Heartbeat y avanza el reloj", function()
		local env = Mocks.new()
		local total = 0
		env.RunService.Heartbeat:Connect(function(dt)
			total += dt
		end)
		local fired = false
		env.clock.task.delay(1, function()
			fired = true
		end)
		env.RunService:RunFor(1, 0.25)
		expect(total).toBeCloseTo(1, 6)
		expect(fired).toBe(true)
	end)

	it("IsServer/IsClient/IsStudio son configurables", function()
		local env = Mocks.new({ runService = { isServer = false, isStudio = true } })
		expect(env.RunService:IsServer()).toBe(false)
		expect(env.RunService:IsClient()).toBe(true)
		expect(env.RunService:IsStudio()).toBe(true)
	end)
end)

describe("DataStoreService", function()
	local env, store

	beforeEach(function()
		env = Mocks.new()
		store = env.DataStoreService:GetDataStore("Test")
	end)

	it("Get/Set/Remove y copias independientes (sin compartir referencias)", function()
		local value = { coins = 1, items = { "a" } }
		store:SetAsync("k", value)
		value.coins = 999 -- no debe afectar lo guardado
		local got, info = store:GetAsync("k")
		expect(got).toEqual({ coins = 1, items = { "a" } })
		expect(info.Version).toBeType("string")
		got.coins = 5
		expect(store:GetAsync("k").coins).toBe(1)
		local removed = store:RemoveAsync("k")
		expect(removed.coins).toBe(1)
		expect(store:GetAsync("k")).toBeNil()
	end)

	it("mismo nombre+scope devuelve el mismo DataStore", function()
		expect(env.DataStoreService:GetDataStore("Test")).toBe(store)
		expect(env.DataStoreService:GetDataStore("Test", "otro")).never.toBe(store)
	end)

	it("UpdateAsync transforma, y devolver nil cancela", function()
		store:SetAsync("n", 5)
		local newValue = store:UpdateAsync("n", function(old)
			return old + 1
		end)
		expect(newValue).toBe(6)
		local cancelled = store:UpdateAsync("n", function()
			return nil
		end)
		expect(cancelled).toBeNil()
		expect(store:_peek("n")).toBe(6)
		-- clave inexistente: old es nil
		store:UpdateAsync("nuevo", function(old)
			expect(old).toBeNil()
			return { ok = true }
		end)
		expect(store:_peek("nuevo")).toEqual({ ok = true })
	end)

	it("UpdateAsync prohibe ceder dentro del callback", function()
		expect(function()
			store:UpdateAsync("k", function()
				coroutine.yield()
				return 1
			end)
		end).toThrow("cedio")
	end)

	it("IncrementAsync suma enteros", function()
		expect(store:IncrementAsync("c", 5)).toBe(5)
		expect(store:IncrementAsync("c")).toBe(6)
		expect(store:IncrementAsync("c", -2)).toBe(4)
	end)

	it("rechaza valores no serializables y claves invalidas", function()
		expect(function()
			store:SetAsync("k", { f = function() end })
		end).toThrow("104")
		expect(function()
			store:SetAsync("k", 0 / 0)
		end).toThrow("NaN")
		expect(function()
			store:SetAsync("k", { [1] = "a", [3] = "c" }) -- array con huecos
		end).toThrow("104")
		expect(function()
			store:SetAsync("", 1)
		end).toThrow("101")
		expect(function()
			store:SetAsync(string.rep("x", 51), 1)
		end).toThrow("102")
		expect(function()
			store:SetAsync("big", string.rep("x", 4 * 1024 * 1024 + 1))
		end).toThrow("105")
	end)

	it("SetOutage hace fallar todo hasta que se restaura", function()
		store:SetAsync("k", 1)
		env.DataStoreService:SetOutage(true)
		expect(function()
			store:GetAsync("k")
		end).toThrow("simulated")
		env.DataStoreService:SetOutage(false)
		expect(store:GetAsync("k")).toBe(1)
	end)

	it("FailNext falla N peticiones, con filtro por operacion", function()
		env.DataStoreService:FailNext(2, { op = "SetAsync", message = "503: boom" })
		expect(store:GetAsync("k")).toBeNil() -- GetAsync no entra en el filtro
		expect(function()
			store:SetAsync("k", 1)
		end).toThrow("503: boom")
		expect(function()
			store:SetAsync("k", 1)
		end).toThrow("503: boom")
		store:SetAsync("k", 1) -- ya funciona
		expect(store:_peek("k")).toBe(1)
	end)

	it("SetFailureRate es reproducible con la misma semilla", function()
		local function run(seed)
			local e = Mocks.new()
			local s = e.DataStoreService:GetDataStore("T")
			e.DataStoreService:SetFailureRate(0.5, seed)
			local results = {}
			for i = 1, 20 do
				results[i] = pcall(s.GetAsync, s, "k")
			end
			return results
		end
		expect(run(42)).toEqual(run(42))
		local failures = 0
		for _, ok in run(42) do
			if not ok then
				failures += 1
			end
		end
		expect(failures).toBeGreaterThan(0)
		expect(failures).toBeLessThan(20)
	end)

	it("presupuesto por minuto: se agota y se recupera con el tiempo simulado", function()
		local e = Mocks.new({ dataStore = { enforceBudgets = true } })
		local s = e.DataStoreService:GetDataStore("T")
		for _ = 1, 60 do
			s:GetAsync("k")
		end
		expect(function()
			s:GetAsync("k")
		end).toThrow("301")
		e.clock:advance(6) -- 60/min = 1 por segundo
		expect(function()
			s:GetAsync("k")
		end).never.toThrow()
		-- los jugadores amplian el presupuesto: 60 + 40 por jugador
		e.Players:AddPlayer(1)
		e.clock:advance(60)
		for _ = 1, 100 do
			s:GetAsync("k")
		end
		expect(function()
			s:GetAsync("k")
		end).toThrow("301")
	end)

	it("UpdateAsync consume presupuesto de lectura y de escritura", function()
		local e = Mocks.new({ dataStore = { enforceBudgets = true } })
		local s = e.DataStoreService:GetDataStore("T")
		for _ = 1, 60 do
			s:UpdateAsync("k", function(old)
				return (old or 0) + 1
			end)
		end
		expect(function()
			s:GetAsync("k") -- la lectura tambien se agoto
		end).toThrow("301")
		expect(function()
			s:SetAsync("k", 1) -- y la escritura
		end).toThrow("301")
		expect(s:_peek("k")).toBe(60)
	end)

	it("latencia simulada consume tiempo del reloj, no tiempo real", function()
		local e = Mocks.new({ dataStore = { latency = 0.5 } })
		local s = e.DataStoreService:GetDataStore("T")
		s:SetAsync("k", 1)
		s:GetAsync("k")
		expect(e.clock:now()).toBeCloseTo(1, 6)
	end)

	it("registra peticiones y permite el gancho onRequest", function()
		local seen = {}
		env.DataStoreService.onRequest = function(info)
			table.insert(seen, info.op .. ":" .. info.key)
		end
		store:SetAsync("a", 1)
		store:GetAsync("a")
		expect(seen).toEqual({ "SetAsync:a", "GetAsync:a" })
		expect(env.DataStoreService:GetRequestCount("GetAsync")).toBe(1)
		expect(env.DataStoreService:GetRequestCount()).toBe(2)
	end)

	it("enforceWriteCooldown rechaza escrituras seguidas a la misma clave", function()
		local e = Mocks.new({ dataStore = { enforceWriteCooldown = true } })
		local s = e.DataStoreService:GetDataStore("T")
		s:SetAsync("k", 1)
		expect(function()
			s:SetAsync("k", 2)
		end).toThrow("cooldown")
		e.clock:advance(6)
		s:SetAsync("k", 2)
		expect(s:_peek("k")).toBe(2)
	end)
end)

describe("MarketplaceService", function()
	local env, market, alice

	beforeEach(function()
		env = Mocks.new()
		market = env.MarketplaceService
		alice = env.Players:AddPlayer(10, "Alice")
	end)

	it("UserOwnsGamePassAsync refleja Grant/Revoke y admite fallos simulados", function()
		expect(market:UserOwnsGamePassAsync(10, 555)).toBe(false)
		market:GrantGamePass(10, 555)
		expect(market:UserOwnsGamePassAsync(10, 555)).toBe(true)
		market:RevokeGamePass(10, 555)
		expect(market:UserOwnsGamePassAsync(10, 555)).toBe(false)

		market:FailNext(1, "HTTP 503")
		expect(function()
			market:UserOwnsGamePassAsync(10, 555)
		end).toThrow("HTTP 503")
		expect(market:UserOwnsGamePassAsync(10, 555)).toBe(false)
	end)

	it("PromptGamePassPurchase queda registrado; SimulateGamePassPurchase concede y notifica", function()
		local finished = {}
		market.PromptGamePassPurchaseFinished:Connect(function(player, id, purchased)
			table.insert(finished, { player.Name, id, purchased })
		end)
		market:PromptGamePassPurchase(alice, 777)
		expect(market.prompts[1].kind).toBe("GamePass")
		expect(market:UserOwnsGamePassAsync(10, 777)).toBe(false)

		market:SimulateGamePassPurchase(alice, 777)
		expect(market:UserOwnsGamePassAsync(10, 777)).toBe(true)
		expect(finished).toEqual({ { "Alice", 777, true } })

		market:SimulateGamePassPurchase(alice, 888, false) -- el jugador cancelo
		expect(market:UserOwnsGamePassAsync(10, 888)).toBe(false)
	end)

	it("PromptProductPurchase con autoApprove entrega el recibo a ProcessReceipt", function()
		local e = Mocks.new({ marketplace = { autoApprove = true } })
		local player = e.Players:AddPlayer(1, "Z")
		local seen
		e.MarketplaceService.ProcessReceipt = function(receipt)
			seen = receipt
			return e.Enum.ProductPurchaseDecision.PurchaseGranted
		end
		e.MarketplaceService:PromptProductPurchase(player, 4242)
		expect(seen.ProductId).toBe(4242)
		expect(seen.PlayerId).toBe(1)
		expect(seen.PurchaseId).toBeType("string")
		expect(e.MarketplaceService:GetReceiptStatus(seen.PurchaseId)).toBe("granted")
	end)

	it("sin callback ProcessReceipt el recibo queda pendiente", function()
		local _, decision = market:SimulatePurchase(alice, 1)
		expect(decision).toBe(env.Enum.ProductPurchaseDecision.NotProcessedYet)
		expect(#market:GetPendingReceipts()).toBe(1)
	end)

	it("PromptProductPurchaseFinished se dispara una sola vez aunque haya redelivery", function()
		local count = 0
		market.PromptProductPurchaseFinished:Connect(function()
			count += 1
		end)
		market.ProcessReceipt = function()
			return env.Enum.ProductPurchaseDecision.PurchaseGranted
		end
		local receipt = market:SimulatePurchase(alice, 1)
		market:SimulateRedelivery(receipt.PurchaseId)
		expect(count).toBe(1)
	end)

	it("BindReceiptHandler tiene prioridad sobre ProcessReceipt y respeta el filtro de productos", function()
		local legacyCalls = 0
		market.ProcessReceipt = function()
			legacyCalls += 1
			return env.Enum.ProductPurchaseDecision.PurchaseGranted
		end
		local unbind = market:BindReceiptHandler(env.Enum.ReceiptType.DeveloperProduct, function()
			return env.Enum.ReceiptDecision.Processed
		end, { 1 })

		local r1, d1 = market:SimulatePurchase(alice, 1) -- lo toma el handler enlazado
		expect(d1).toBe(env.Enum.ProductPurchaseDecision.PurchaseGranted)
		expect(legacyCalls).toBe(0)
		local _, d2 = market:SimulatePurchase(alice, 2) -- fuera del filtro: cae a ProcessReceipt
		expect(d2).toBe(env.Enum.ProductPurchaseDecision.PurchaseGranted)
		expect(legacyCalls).toBe(1)
		expect(market:GetReceiptStatus(r1.PurchaseId)).toBe("granted")

		unbind()
		market:SimulatePurchase(alice, 1)
		expect(legacyCalls).toBe(2)
	end)

	it("RetryPending(userId) solo reintenta los recibos de ese jugador", function()
		local bob = env.Players:AddPlayer(11, "Bob")
		market:SimulatePurchase(alice, 1) -- sin callback: pendiente
		market:SimulatePurchase(bob, 1)
		market.ProcessReceipt = function()
			return env.Enum.ProductPurchaseDecision.PurchaseGranted
		end
		expect(market:RetryPending(bob.UserId)).toBe(1)
		expect(#market:GetPendingReceipts()).toBe(1)
		expect(market:GetPendingReceipts()[1].PlayerId).toBe(alice.UserId)
	end)

	it("GetProductInfo devuelve lo registrado y falla con ids desconocidos", function()
		market:RegisterProduct(1001, { Name = "100 Coins", PriceInRobux = 49 }, env.Enum.InfoType.Product)
		local info = market:GetProductInfo(1001, env.Enum.InfoType.Product)
		expect(info.PriceInRobux).toBe(49)
		expect(function()
			market:GetProductInfo(1, env.Enum.InfoType.Product)
		end).toThrow("not registered")
	end)
end)

describe("Mocks.new().game", function()
	it("GetService devuelve los mocks y falla con servicios no simulados", function()
		local env = Mocks.new()
		expect(env.game:GetService("Players")).toBe(env.Players)
		expect(env.game:GetService("DataStoreService")).toBe(env.DataStoreService)
		expect(function()
			env.game:GetService("HttpService")
		end).toThrow("no simulado")
	end)

	it("installGlobals expone Enum/game como globales y restoreGlobals los quita", function()
		local env = Mocks.new()
		expect(env:installGlobals()).toBe(true)
		-- se leen via getfenv para no depender de como cada runtime resuelve globales
		expect(getfenv(0).Enum).toBe(env.Enum)
		expect(getfenv(0).game).toBe(env.game)
		env.restoreGlobals()
		expect(getfenv(0).Enum).toBeNil()
	end)
end)
