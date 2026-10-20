--!nonstrict
-- Tests de packages/Data: bloqueo de sesion, fallo de lectura (no sobrescribir), migraciones, reintentos.
local testkit = require("@testkit")
local Mocks = require("@testkit/mocks")
local Data = require("../packages/Data")

local describe, it, expect, beforeEach = testkit.describe, testkit.it, testkit.expect, testkit.beforeEach

local USER = 1001
local KEY = "Player_1001"

local function newSchema()
	return {
		version = 3,
		template = {
			coins = 0,
			inventory = {},
			settings = { music = true, sfx = true },
			purchases = {},
			fresh = 5,
		},
		migrations = {
			[1] = function(d) -- v1 -> v2: Coins -> coins
				d.coins = d.Coins or 0
				d.Coins = nil
			end,
			[2] = function(d) -- v2 -> v3: inventario lista -> mapa de conteos
				local counts = {}
				for _, item in d.inventory or {} do
					counts[item] = (counts[item] or 0) + 1
				end
				d.inventory = counts
			end,
		},
	}
end

describe("Data", function()
	local env, store, logs

	local function newManager(jobId: string, overrides)
		local cfg = {
			dataStore = store,
			schema = newSchema(),
			jobId = jobId,
			now = env.clock.osTime,
			task = env.task,
			random = function()
				return 0
			end,
			log = function(m)
				table.insert(logs, m)
			end,
			lock = { staleSeconds = 600, waitSeconds = 10, pollSeconds = 3 },
		}
		for k, v in overrides or {} do
			cfg[k] = v
		end
		return Data.new(cfg)
	end

	beforeEach(function()
		env = Mocks.new()
		store = env.DataStoreService:GetDataStore("PlayerData")
		logs = {}
	end)

	describe("utilidades puras", function()
		it("validate acepta datos serializables y rechaza NaN, inf, ciclos, claves mixtas y metatablas", function()
			expect((Data.validate({ a = 1, b = { 1, 2, 3 }, c = "hola", d = true }))).toBe(true)
			expect((Data.validate({ a = 0 / 0 }))).toBe(false)
			expect((Data.validate({ a = math.huge }))).toBe(false)
			local cyclic = {}
			cyclic.self = cyclic
			expect((Data.validate(cyclic))).toBe(false)
			expect((Data.validate({ [1] = "a", x = "b" }))).toBe(false) -- mixto
			expect((Data.validate({ [1] = "a", [3] = "c" }))).toBe(false) -- disperso
			expect((Data.validate(setmetatable({}, {})))).toBe(false)
			expect((Data.validate({ f = function() end }))).toBe(false)
			expect((Data.validate({ s = "\xff" }))).toBe(false) -- UTF-8 invalido
		end)

		it("reconcile rellena claves nuevas sin pisar las existentes", function()
			local data: { [string]: any } = { coins = 50, settings = { music = false } }
			Data.reconcile(data, { coins = 0, settings = { music = true, sfx = true }, fresh = 5, list = {} })
			expect(data.coins).toBe(50)
			expect(data.settings.music).toBe(false)
			expect(data.settings.sfx).toBe(true)
			expect(data.fresh).toBe(5)
			expect(data.list).toEqual({})
		end)

		it("isRetriable: 101-107 no se reintentan; el resto si", function()
			expect(Data.isRetriable("104: Cannot store Dictionary")).toBe(false)
			expect(Data.isRetriable("105: Serialized value exceeds")).toBe(false)
			expect(Data.isRetriable("502: server error")).toBe(true)
			expect(Data.isRetriable("301: throttled")).toBe(true)
			expect(Data.isRetriable("1040 algo")).toBe(true)
		end)
	end)

	describe("carga", function()
		it("jugador nuevo: crea el registro con la plantilla y reclama el bloqueo", function()
			local manager = newManager("A")
			local profile, reason = manager:load(USER)
			expect(reason).toBeNil()
			expect(profile).toBeTruthy()
			expect(profile.data.coins).toBe(0)
			expect(profile.data.fresh).toBe(5)
			local record = store:_peek(KEY)
			expect(record.schemaVersion).toBe(3)
			expect(record.lock.jobId).toBe("A")
			-- asocia el UserId (GDPR / derecho al olvido)
			local _, info = store:GetAsync(KEY)
			expect(info:GetUserIds()).toEqual({ USER })
		end)

		it("jugador existente: conserva los datos y rellena campos nuevos", function()
			store:_seed(KEY, { schemaVersion = 3, data = { coins = 777, inventory = { rod = 2 } }, savedAt = 1 })
			local manager = newManager("A")
			local profile = manager:load(USER)
			expect(profile.data.coins).toBe(777)
			expect(profile.data.inventory.rod).toBe(2)
			expect(profile.data.fresh).toBe(5) -- reconcile
			expect(profile.data.settings.music).toBe(true)
		end)

		it("FALLO DE LECTURA: no carga, no escribe valores por defecto y no toca el registro", function()
			local original = { schemaVersion = 3, data = { coins = 999, inventory = {}, purchases = {} }, savedAt = 5 }
			store:_seed(KEY, original)
			env.DataStoreService:SetOutage(true)
			local manager = newManager("A")
			local profile, reason = manager:load(USER)
			expect(profile).toBeNil()
			expect(reason).toBe("datastore")
			env.DataStoreService:SetOutage(false)
			expect(store:_peek(KEY)).toEqual(original) -- intacto: nada de defaults
			for _, entry in env.DataStoreService.log do
				expect(entry.ok).never.toBe(true) -- ninguna peticion llego a tener exito
			end
		end)

		it("FALLO DE LECTURA con jugador nuevo: tampoco crea la clave", function()
			env.DataStoreService:SetOutage(true)
			local manager = newManager("A")
			expect((manager:load(USER))).toBeNil()
			env.DataStoreService:SetOutage(false)
			expect(store:_peek(KEY)).toBeNil()
		end)

		it("fallos transitorios: reintenta con backoff exponencial (1 s, 2 s) y carga", function()
			env.DataStoreService:FailNext(2, { op = "UpdateAsync" })
			local manager = newManager("A")
			local profile = manager:load(USER)
			expect(profile).toBeTruthy()
			expect(env.clock:now()).toBe(3) -- 1 + 2 s de espera simulada
			expect(env.DataStoreService:GetRequestCount("UpdateAsync")).toBe(3)
		end)

		it("errores 10x (valor/clave invalidos) no se reintentan", function()
			env.DataStoreService:FailNext(5, { op = "UpdateAsync", message = "104: Cannot store" })
			local manager = newManager("A")
			local profile, reason = manager:load(USER)
			expect(profile).toBeNil()
			expect(reason).toBe("datastore")
			expect(env.DataStoreService:GetRequestCount("UpdateAsync")).toBe(1)
		end)

		it("agota los reintentos y devuelve datastore", function()
			env.DataStoreService:FailNext(50, { op = "UpdateAsync" })
			local manager = newManager("A", { retry = { attempts = 3, baseDelay = 1, maxDelay = 4 } })
			local profile, reason = manager:load(USER)
			expect(profile).toBeNil()
			expect(reason).toBe("datastore")
			expect(env.DataStoreService:GetRequestCount("UpdateAsync")).toBe(3)
		end)
	end)

	describe("bloqueo de sesion", function()
		it("otro servidor no puede cargar mientras el bloqueo siga vivo", function()
			local a, b = newManager("A"), newManager("B")
			local profileA = a:load(USER)
			profileA.data.coins = 42
			profileA:markDirty()
			expect(profileA:save()).toBe(true)

			local profileB, reason = b:load(USER)
			expect(profileB).toBeNil()
			expect(reason).toBe("locked")
			-- A no se ve afectado y los datos siguen siendo los suyos
			expect(profileA:isActive()).toBe(true)
			expect(store:_peek(KEY).data.coins).toBe(42)
			expect(store:_peek(KEY).lock.jobId).toBe("A")
		end)

		it("espera a que el otro servidor libere y entonces carga los datos actualizados", function()
			local a, b = newManager("A"), newManager("B")
			local profileA = a:load(USER)
			profileA.data.coins = 123
			env.task.delay(5, function()
				profileA:release()
			end)
			local profileB, reason = b:load(USER)
			expect(reason).toBeNil()
			expect(profileB.data.coins).toBe(123)
			expect(store:_peek(KEY).lock.jobId).toBe("B")
		end)

		it("un bloqueo sin latido (servidor caido) se reclama tras staleSeconds", function()
			local a, b = newManager("A"), newManager("B")
			local profileA = a:load(USER)
			profileA.data.coins = 10
			profileA:markDirty()
			profileA:save()
			env.clock:advance(700) -- A "se cae": no hay mas latidos
			local profileB, reason = b:load(USER)
			expect(reason).toBeNil()
			expect(profileB).toBeTruthy()
			expect(profileB.data.coins).toBe(10)
		end)

		it("el servidor que perdio el bloqueo NO puede sobrescribir y expulsa al jugador", function()
			local lostFor = {}
			local a = newManager("A")
			local b = newManager("B")
			a.onProfileLost = function(profile)
				table.insert(lostFor, profile.userId)
			end
			local profileA = a:load(USER)
			env.clock:advance(700)
			local profileB = b:load(USER)
			profileB.data.coins = 500
			profileB:markDirty()
			expect(profileB:save()).toBe(true)

			-- A (zombi) intenta guardar con datos viejos
			profileA.data.coins = 1
			profileA:markDirty()
			expect(profileA:save()).toBe(false)
			expect(profileA:isActive()).toBe(false)
			expect(profileA:isLost()).toBe(true)
			expect(lostFor).toEqual({ USER })
			expect(store:_peek(KEY).data.coins).toBe(500) -- los datos de B siguen intactos
			-- y A tampoco puede liberar el bloqueo de B
			expect(profileA:release()).toBe(false)
			expect(store:_peek(KEY).lock.jobId).toBe("B")
		end)

		it("release guarda y libera: otro servidor puede cargar de inmediato", function()
			local a, b = newManager("A"), newManager("B")
			local profileA = a:load(USER)
			profileA.data.coins = 9
			expect(profileA:release()).toBe(true)
			expect(store:_peek(KEY).lock).toBeNil()
			expect(store:_peek(KEY).data.coins).toBe(9)
			expect(a:get(USER)).toBeNil()
			local profileB = b:load(USER)
			expect(profileB.data.coins).toBe(9)
		end)

		it("recargar al mismo jugador en el mismo servidor espera a que termine la liberacion", function()
			local a = newManager("A")
			local profile = a:load(USER)
			profile.data.coins = 5
			env.task.spawn(function()
				profile:release()
			end)
			local again = a:load(USER)
			expect(again).toBeTruthy()
			expect(again.data.coins).toBe(5)
		end)

		it("cargar dos veces el mismo jugador activo devuelve already-loaded", function()
			local a = newManager("A")
			a:load(USER)
			local profile, reason = a:load(USER)
			expect(profile).toBeNil()
			expect(reason).toBe("already-loaded")
		end)
	end)

	describe("guardado", function()
		it("save persiste y marca el perfil como guardado", function()
			local manager = newManager("A")
			local profile = manager:load(USER)
			profile.data.coins = 250
			profile:markDirty()
			expect(profile:isPersisted()).toBe(false)
			expect(profile:save()).toBe(true)
			expect(profile:isPersisted()).toBe(true)
			expect(store:_peek(KEY).data.coins).toBe(250)
		end)

		it("si el guardado falla devuelve false, conserva el guardado anterior y se puede reintentar", function()
			local manager = newManager("A", { retry = { attempts = 2, baseDelay = 1, maxDelay = 2 } })
			local profile = manager:load(USER)
			profile.data.coins = 1
			profile:markDirty()
			profile:save()
			profile.data.coins = 2
			profile:markDirty()
			env.DataStoreService:FailNext(2, { op = "UpdateAsync" })
			expect(profile:save()).toBe(false)
			expect(profile:isPersisted()).toBe(false)
			expect(store:_peek(KEY).data.coins).toBe(1) -- el guardado anterior sigue ahi
			expect(profile:save()).toBe(true) -- ya sin fallos
			expect(store:_peek(KEY).data.coins).toBe(2)
		end)

		it("datos no serializables (NaN) NO sobrescriben el guardado bueno", function()
			local manager = newManager("A")
			local profile = manager:load(USER)
			profile.data.coins = 100
			profile:markDirty()
			profile:save()
			profile.data.coins = 0 / 0
			profile:markDirty()
			expect(profile:save()).toBe(false)
			expect(profile.lastError).toContain("no serializables")
			expect(store:_peek(KEY).data.coins).toBe(100)
		end)

		it("guardados concurrentes se coalescen y ambos terminan bien", function()
			local manager = newManager("A")
			local profile = manager:load(USER)
			env.DataStoreService:SetLatency(0.5)
			profile.data.coins = 11
			profile:markDirty()
			local results = {}
			env.task.spawn(function()
				table.insert(results, profile:save())
			end)
			env.task.spawn(function()
				table.insert(results, profile:save())
			end)
			env.clock:advance(5)
			expect(results).toEqual({ true, true })
			expect(store:_peek(KEY).data.coins).toBe(11)
			expect(env.DataStoreService:GetRequestCount("UpdateAsync")).toBeLessThanOrEqual(3)
		end)

		it("release con DataStore caido deja el perfil en release-failed y el autosave lo reintenta", function()
			local manager = newManager("A", {
				retry = { attempts = 2, baseDelay = 1, maxDelay = 1 },
				releaseRetry = { attempts = 2, baseDelay = 1, maxDelay = 1 },
				autosaveSeconds = 60,
			})
			local profile = manager:load(USER)
			profile.data.coins = 321
			env.DataStoreService:SetOutage(true)
			expect(profile:release()).toBe(false)
			expect(profile.state).toBe("release-failed")
			expect(manager:get(USER)).toBe(profile) -- sigue en memoria: no se pierde
			env.DataStoreService:SetOutage(false)
			manager:startAutosave()
			env.clock:advance(130)
			manager:stopAutosave()
			expect(profile.state).toBe("released")
			expect(store:_peek(KEY).data.coins).toBe(321)
			expect(store:_peek(KEY).lock).toBeNil()
		end)

		it("autosave guarda periodicamente y renueva el latido del bloqueo", function()
			local manager = newManager("A", { autosaveSeconds = 60 })
			local profile = manager:load(USER)
			local firstHeartbeat = store:_peek(KEY).lock.heartbeat
			profile.data.coins = 8
			manager:startAutosave()
			env.clock:advance(125)
			manager:stopAutosave()
			local record = store:_peek(KEY)
			expect(record.data.coins).toBe(8)
			expect(record.lock.heartbeat).toBeGreaterThan(firstHeartbeat)
			env.clock:runAll(200) -- deja terminar el bucle
		end)
	end)

	describe("migraciones", function()
		it("migra de v1 a v3 conservando los datos y la persiste", function()
			store:_seed(KEY, {
				data = { Coins = 5, inventory = { "rod", "rod", "net" } }, -- sin schemaVersion = v1
				savedAt = 1,
			})
			local manager = newManager("A")
			local profile = manager:load(USER)
			expect(profile.data.coins).toBe(5)
			expect(profile.data.Coins).toBeNil()
			expect(profile.data.inventory).toEqual({ rod = 2, net = 1 })
			expect(profile:save()).toBe(true)
			expect(store:_peek(KEY).schemaVersion).toBe(3)
		end)

		it("v2 -> v3 aplica solo la ultima migracion", function()
			store:_seed(KEY, { schemaVersion = 2, data = { coins = 9, inventory = { "a" } }, savedAt = 1 })
			local profile = newManager("A"):load(USER)
			expect(profile.data.coins).toBe(9)
			expect(profile.data.inventory).toEqual({ a = 1 })
		end)

		it("datos de un esquema MAS NUEVO se rechazan sin tocar el registro ni reclamar el bloqueo", function()
			local future = { schemaVersion = 9, data = { coins = 1 }, savedAt = 1 }
			store:_seed(KEY, future)
			local manager = newManager("A")
			local profile, reason = manager:load(USER)
			expect(profile).toBeNil()
			expect(reason).toBe("newer-version")
			expect(store:_peek(KEY)).toEqual(future)
		end)

		it("una migracion que falla libera el bloqueo y no modifica los datos", function()
			store:_seed(KEY, { schemaVersion = 1, data = { Coins = 5 }, savedAt = 1 })
			local schema = newSchema()
			schema.migrations[1] = function()
				error("boom")
			end
			local manager = newManager("A", { schema = schema })
			local profile, reason = manager:load(USER)
			expect(profile).toBeNil()
			expect(reason).toBe("migration")
			local record = store:_peek(KEY)
			expect(record.lock).toBeNil()
			expect(record.data.Coins).toBe(5)
			expect(record.schemaVersion).toBe(1)
		end)

		it("falta una migracion intermedia: falla limpiamente", function()
			store:_seed(KEY, { schemaVersion = 1, data = { Coins = 5 }, savedAt = 1 })
			local schema = newSchema()
			schema.migrations[2] = nil
			local profile, reason = newManager("A", { schema = schema }):load(USER)
			expect(profile).toBeNil()
			expect(reason).toBe("migration")
		end)

		it("registro corrupto (no es una tabla con data): no se toca", function()
			store:_seed(KEY, { weird = true })
			local profile, reason = newManager("A"):load(USER)
			expect(profile).toBeNil()
			expect(reason).toBe("corrupt")
			expect(store:_peek(KEY)).toEqual({ weird = true })
		end)
	end)

	describe("integracion con Players y BindToClose", function()
		local function setup(overrides)
			local manager = newManager("A", overrides)
			local closeCallback
			local loaded, failed, removing = {}, {}, {}
			manager:attach(env.Players, function(callback)
				closeCallback = callback
			end, {
				onLoaded = function(player, profile)
					table.insert(loaded, { userId = player.UserId, profile = profile })
				end,
				onLoadFailed = function(player, reason)
					table.insert(failed, { userId = player.UserId, reason = reason })
				end,
				onRemoving = function(player)
					table.insert(removing, player.UserId)
				end,
			})
			return manager, function()
				return closeCallback
			end, loaded, failed, removing
		end

		it("carga al entrar y guarda/libera al salir", function()
			local manager, _, loaded, _, removing = setup()
			local player = env.Players:AddPlayer(USER, "Alice")
			env.clock:flush()
			expect(loaded).toHaveLength(1)
			loaded[1].profile.data.coins = 64
			env.Players:RemovePlayer(player)
			env.clock:flush()
			expect(removing).toEqual({ USER })
			expect(store:_peek(KEY).data.coins).toBe(64)
			expect(store:_peek(KEY).lock).toBeNil()
			expect(manager:get(USER)).toBeNil()
		end)

		it("si la carga falla expulsa al jugador con un mensaje y no escribe nada", function()
			env.DataStoreService:SetOutage(true)
			local _, _, loaded, failed = setup({ retry = { attempts = 2, baseDelay = 1, maxDelay = 1 } })
			local player = env.Players:AddPlayer(USER, "Alice")
			env.clock:runAll(60)
			expect(loaded).toHaveLength(0)
			expect(failed[1].reason).toBe("datastore")
			expect(player.kicked).toContain("progreso esta a salvo")
			env.DataStoreService:SetOutage(false)
			expect(store:_peek(KEY)).toBeNil()
		end)

		it("jugador bloqueado en otro servidor: mensaje especifico", function()
			local other = newManager("B")
			other:load(USER)
			local _, _, _, failed = setup()
			local player = env.Players:AddPlayer(USER, "Alice")
			env.clock:runAll(60)
			expect(failed[1].reason).toBe("locked")
			expect(player.kicked).toContain("sesion anterior")
		end)

		it("si el jugador se va mientras carga, no queda el bloqueo reclamado", function()
			env.DataStoreService:SetLatency(2)
			local manager = setup()
			local player = env.Players:AddPlayer(USER, "Alice")
			env.clock:advance(1)
			env.Players:RemovePlayer(player) -- se va a mitad de la carga
			env.clock:runAll(120)
			env.DataStoreService:SetLatency(0)
			local record = store:_peek(KEY)
			expect(record == nil or record.lock == nil).toBe(true)
			expect(manager:get(USER)).toBeNil()
		end)

		it("BindToClose libera todos los perfiles en paralelo", function()
			local manager, getClose, loaded = setup()
			for i = 1, 5 do
				env.Players:AddPlayer(USER + i, "P" .. i)
			end
			env.clock:flush()
			expect(loaded).toHaveLength(5)
			for i, entry in loaded do
				entry.profile.data.coins = i * 10
			end
			local failedCount
			env.task.spawn(function()
				getClose()()
				failedCount = manager:shutdown(1) -- idempotente: no debe romper nada
			end)
			env.clock:runAll(60)
			for i = 1, 5 do
				local record = store:_peek("Player_" .. (USER + i))
				expect(record.lock).toBeNil()
			end
			expect(failedCount).toBe(0)
		end)

		it("waitForProfile devuelve el perfil cuando llega y nil si falla la carga", function()
			local manager = setup()
			env.DataStoreService:SetLatency(1)
			env.Players:AddPlayer(USER, "Alice")
			local got
			env.task.spawn(function()
				got = manager:waitForProfile(USER, 20)
			end)
			env.clock:advance(10)
			expect(got).toBeTruthy()
			expect(got.userId).toBe(USER)
			expect(manager:waitForProfile(424242, 5)).toBeNil() -- ni carga ni existe
		end)
	end)
end)
