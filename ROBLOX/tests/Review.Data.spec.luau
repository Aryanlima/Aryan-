--!nonstrict
--[[
	Pruebas de la revision de seguridad/correccion (2026-10-20) sobre packages/Data.
	  * "MUTANTE Dx": matan mutantes que sobrevivian a la suite original (pasan con el codigo original).
	  * "BUG DATA-xx": fallaban con el codigo original; pasan con el arreglo propuesto en docs/revision-codigo-dinero.md.
]]
local testkit = require("@testkit")
local Mocks = require("@testkit/mocks")
local Data = require("../packages/Data")

local describe, it, expect, beforeEach = testkit.describe, testkit.it, testkit.expect, testkit.beforeEach

local USER = 1001
local KEY = "Player_1001"

describe("Review: Data", function()
	local env, store, logs

	local function newManager(jobId, overrides)
		local cfg = {
			dataStore = store,
			schema = { version = 1, template = { coins = 0, purchases = {} } },
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

	beforeEach(function()
		env = Mocks.new()
		store = env.DataStoreService:GetDataStore("PlayerData")
		logs = {}
	end)

	it(
		"MUTANTE D8: un cambio hecho MIENTRAS se guarda no se da por persistido (la siguiente save() lo escribe)",
		function()
			local manager = newManager("A")
			local profile = manager:load(USER)
			env.DataStoreService:SetLatency(1)
			profile.data.coins = 1
			profile:markDirty()
			local firstSaved
			env.task.spawn(function()
				firstSaved = profile:save()
			end)
			env.clock:advance(0.5) -- el guardado esta en vuelo (ya hizo la copia con coins = 1)
			profile.data.coins = 2
			profile:markDirty()
			env.clock:advance(2)
			expect(firstSaved).toBe(true)
			expect(store:_peek(KEY).data.coins).toBe(1)
			expect(profile:isPersisted()).toBe(false) -- el cambio a 2 aun NO esta en el DataStore
			expect(profile:save()).toBe(true)
			expect(store:_peek(KEY).data.coins).toBe(2)
			expect(profile:isPersisted()).toBe(true)
		end
	)

	it("MUTANTE D6: el callback de BindToClose (sin llamar a shutdown() a mano) guarda y libera a todos", function()
		local manager = newManager("A")
		local closeCallback
		manager:attach(env.Players, function(callback)
			closeCallback = callback
		end, {})
		for i = 1, 3 do
			env.Players:AddPlayer(USER + i, "P" .. i)
		end
		env.clock:flush()
		for i = 1, 3 do
			manager:get(USER + i).data.coins = i * 10
		end
		expect(closeCallback).toBeTruthy()
		env.task.spawn(closeCallback)
		env.clock:runAll(60)
		for i = 1, 3 do
			local record = store:_peek("Player_" .. (USER + i))
			expect(record.lock).toBeNil()
			expect(record.data.coins).toBe(i * 10)
		end
	end)

	it(
		"UpdateAsync que REEJECUTA el callback (conflicto con otro servidor): vale el resultado de la ULTIMA ejecucion",
		function()
			-- El mock del testkit nunca reejecuta el callback. Este doble lo hace como Roblox: 1a vez con el valor viejo
			-- (libre), 2a vez con el valor nuevo (otro servidor ya tomo el bloqueo).
			local real = store
			local lockedByOther = {
				schemaVersion = 1,
				data = { coins = 5, purchases = {} },
				lock = { jobId = "OTHER", heartbeat = env.clock.osTime(), claimedAt = env.clock.osTime() },
			}
			local free = { schemaVersion = 1, data = { coins = 5, purchases = {} } }
			local flaky = {
				UpdateAsync = function(_self, key, transform)
					transform(free, nil) -- primera ejecucion (descartada por el conflicto)
					return real:UpdateAsync(key, function(_old)
						return transform(lockedByOther, nil)
					end)
				end,
			}
			real:_seed(KEY, lockedByOther)
			local manager =
				newManager("A", { dataStore = flaky, lock = { staleSeconds = 600, waitSeconds = 1, pollSeconds = 1 } })
			local profile, reason = manager:load(USER)
			expect(profile).toBeNil() -- la ultima ejecucion vio el bloqueo ajeno: NO se carga
			expect(reason).toBe("locked")
			expect(real:_peek(KEY).lock.jobId).toBe("OTHER")
		end
	)

	it(
		"BUG DATA-03: PlayerRemoving + BindToClose a la vez => UNA sola liberacion (sin 'bloqueo perdido' falso)",
		function()
			local manager = newManager("A")
			local closeCallback
			local loaded
			manager:attach(env.Players, function(callback)
				closeCallback = callback
			end, {
				onLoaded = function(_player, profile)
					loaded = profile
				end,
			})
			local player = env.Players:AddPlayer(USER, "Alice")
			env.clock:flush()
			loaded.data.coins = 7
			env.DataStoreService:SetLatency(1)
			env.DataStoreService:ResetLog()
			env.Players:RemovePlayer(player) -- PlayerRemoving: release() en curso
			env.clock:advance(0.1)
			expect(loaded.state).toBe("releasing")
			env.task.spawn(closeCallback) -- el servidor se cierra: shutdown() tambien intenta liberar
			env.clock:runAll(60)
			expect(env.DataStoreService:GetRequestCount("UpdateAsync")).toBe(1) -- antes: 2
			expect(loaded.state).toBe("released") -- antes: "lost"
			expect(store:_peek(KEY).lock).toBeNil()
			expect(store:_peek(KEY).data.coins).toBe(7)
			for _, message in logs do
				expect(string.find(message, "PERDIDO", 1, true)).toBeNil()
			end
		end
	)

	it("BUG DATA-03b: dos release() simultaneos devuelven el mismo resultado y no duplican la escritura", function()
		local manager = newManager("A")
		local profile = manager:load(USER)
		profile.data.coins = 3
		env.DataStoreService:SetLatency(1)
		env.DataStoreService:ResetLog()
		local results = {}
		for _ = 1, 3 do
			env.task.spawn(function()
				table.insert(results, profile:release())
			end)
		end
		env.clock:runAll(60)
		expect(results).toEqual({ true, true, true })
		expect(env.DataStoreService:GetRequestCount("UpdateAsync")).toBe(1)
		expect(store:_peek(KEY).data.coins).toBe(3)
	end)

	it("un release() que falla puede reintentarse despues (el autosave lo hace) y entonces si libera", function()
		local manager = newManager("A", {
			retry = { attempts = 1, baseDelay = 1, maxDelay = 1 },
			releaseRetry = { attempts = 1, baseDelay = 1, maxDelay = 1 },
		})
		local profile = manager:load(USER)
		profile.data.coins = 9
		env.DataStoreService:FailNext(1, { op = "UpdateAsync" })
		expect(profile:release()).toBe(false)
		expect(profile.state).toBe("release-failed")
		expect(profile:release()).toBe(true)
		expect(store:_peek(KEY).lock).toBeNil()
		expect(store:_peek(KEY).data.coins).toBe(9)
	end)

	it(
		"BUG DATA-02: el cierre del servidor con 60 jugadores no lanza mas de 20 peticiones a la vez (cola de DataStore = 30)",
		function()
			local inFlight, maxInFlight = 0, 0
			local real = store
			local counting = {
				UpdateAsync = function(_self, key, transform)
					inFlight += 1
					maxInFlight = math.max(maxInFlight, inFlight)
					local ok, a, b = pcall(real.UpdateAsync, real, key, transform)
					inFlight -= 1
					if not ok then
						error(a, 0)
					end
					return a, b
				end,
			}
			local manager = newManager("A", { dataStore = counting })
			local closeCallback
			manager:attach(env.Players, function(callback)
				closeCallback = callback
			end, {})
			local players = {}
			for i = 1, 60 do
				players[i] = env.Players:AddPlayer(USER + i, "P" .. i)
			end
			env.clock:flush()
			expect(inFlight).toBe(0)
			env.DataStoreService:SetLatency(1)
			maxInFlight = 0
			for _, player in players do
				env.Players:RemovePlayer(player) -- PlayerRemoving de todos a la vez (release en paralelo)
			end
			env.task.spawn(closeCallback) -- y ademas BindToClose
			env.clock:runAll(120)
			expect(maxInFlight <= 20).toBe(true) -- antes: 60
			for i = 1, 60 do
				expect(real:_peek("Player_" .. (USER + i)).lock).toBeNil() -- todos guardados y liberados
			end
		end
	)
end)
