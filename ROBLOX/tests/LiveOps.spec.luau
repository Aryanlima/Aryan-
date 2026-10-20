--!nonstrict
-- Tests de packages/LiveOps: ventanas de eventos, rotacion, configuracion remota y codigos de canje.
local testkit = require("@testkit")
local Mocks = require("@testkit/mocks")
local LiveOps = require("../packages/LiveOps")

local describe, it, expect, beforeEach = testkit.describe, testkit.it, testkit.expect, testkit.beforeEach

local T0 = 1700000000 -- epoch base del reloj simulado (Mocks: epoch = 1700000000)

local function baseConfig()
	return {
		version = 1,
		events = {
			{
				id = "golden_tide",
				name = "Marea Dorada",
				startsAt = T0 + 1000,
				endsAt = T0 + 2000,
				modifiers = { coins = 2 },
			},
			{
				id = "mythic_moon",
				name = "Luna Mitica",
				startsAt = T0 + 1500,
				endsAt = T0 + 3000,
				modifiers = { luck = 3, coins = 1.5 },
			},
		},
		codes = {
			WELCOME = { reward = { coins = 500 } },
			SUMMER = { reward = { pearls = 5 }, startsAt = T0 + 100, expiresAt = T0 + 5000 },
		},
		welcome = { id = "w1", message = "Bienvenido a Fish & Fortune", endsAt = T0 + 10000 },
		season = { id = 1, name = "Temporada 1", startsAt = T0, endsAt = T0 + 100000 },
	}
end

describe("LiveOps.eventWindow (puro)", function()
	it("ventana fija: inicio inclusivo, fin exclusivo", function()
		local event = { id = "e", name = "E", startsAt = 100, endsAt = 200 }
		expect((LiveOps.eventWindow(event, 99))).toBe(false)
		expect((LiveOps.eventWindow(event, 100))).toBe(true)
		expect((LiveOps.eventWindow(event, 199.9))).toBe(true)
		expect((LiveOps.eventWindow(event, 200))).toBe(false)
	end)

	it("rotacion: cada evento esta activo solo en su slot", function()
		local function cycleEvent(slot)
			return {
				id = "e" .. slot,
				name = "E",
				cycle = { anchor = 0, slotSeconds = 100, slotCount = 3, slot = slot },
			}
		end
		local e1 = cycleEvent(1)
		local active, startsAt, endsAt = LiveOps.eventWindow(e1, 150)
		expect(active).toBe(true)
		expect(startsAt).toBe(100)
		expect(endsAt).toBe(200)
		-- en el slot 0 no esta activo y apunta a su proximo slot
		local a0, s0, e0 = LiveOps.eventWindow(e1, 50)
		expect(a0).toBe(false)
		expect(s0).toBe(100)
		expect(e0).toBe(200)
		-- en el slot 2 tampoco; el siguiente es el slot 1 de la proxima vuelta (400..500)
		local a2, s2, e2 = LiveOps.eventWindow(e1, 250)
		expect(a2).toBe(false)
		expect(s2).toBe(400)
		expect(e2).toBe(500)
		-- vuelve a estar activo en la siguiente vuelta
		expect((LiveOps.eventWindow(e1, 450))).toBe(true)
		-- exactamente un evento activo en cada instante
		local events = { cycleEvent(0), cycleEvent(1), cycleEvent(2) }
		for t = 0, 1000, 37 do
			local count = 0
			for _, event in events do
				if LiveOps.eventWindow(event, t) then
					count += 1
				end
			end
			expect(count).toBe(1)
		end
	end)

	it("antes del ancla ningun slot esta activo", function()
		local event = { id = "e", name = "E", cycle = { anchor = 1000, slotSeconds = 100, slotCount = 2, slot = 0 } }
		local active, startsAt = LiveOps.eventWindow(event, 500)
		expect(active).toBe(false)
		expect(startsAt).toBe(1000)
	end)
end)

describe("LiveOps.normalizeCode", function()
	it("recorta, pasa a mayusculas y valida caracteres y longitud", function()
		expect(LiveOps.normalizeCode("  hello-123 ")).toBe("HELLO-123")
		expect(LiveOps.normalizeCode("")).toBeNil()
		expect(LiveOps.normalizeCode("   ")).toBeNil()
		expect(LiveOps.normalizeCode("con espacio")).toBeNil()
		expect(LiveOps.normalizeCode("ñandú")).toBeNil()
		expect(LiveOps.normalizeCode(string.rep("A", 33))).toBeNil()
		expect(LiveOps.normalizeCode(123)).toBeNil()
		expect(LiveOps.normalizeCode(nil)).toBeNil()
		expect(LiveOps.normalizeCode({})).toBeNil()
	end)
end)

describe("LiveOps.validateConfig", function()
	it("acepta la configuracion de pruebas", function()
		local ok, problems = LiveOps.validateConfig(baseConfig(), T0)
		expect(problems).toEqual({})
		expect(ok).toBe(true)
	end)

	it("detecta ventanas invertidas, ids duplicados y ciclos invalidos", function()
		local cfg = baseConfig()
		cfg.events[1].endsAt = cfg.events[1].startsAt
		cfg.events[2].id = "golden_tide"
		table.insert(cfg.events, {
			id = "bad_cycle",
			name = "X",
			cycle = { anchor = 0, slotSeconds = 10, slotCount = 2, slot = 5 },
		})
		local ok, problems = LiveOps.validateConfig(cfg, T0)
		expect(ok).toBe(false)
		local text = table.concat(problems, "\n")
		expect(text).toContain("posterior a startsAt")
		expect(text).toContain("id duplicado")
		expect(text).toContain("ciclo invalido")
	end)

	it("detecta codigos mal formados y caducidades incoherentes", function()
		local cfg = baseConfig()
		cfg.codes.lower = { reward = { coins = 1 } }
		cfg.codes.EMPTY = { reward = {} }
		cfg.codes.BACKWARDS = { reward = { coins = 1 }, startsAt = 200, expiresAt = 100 }
		local ok, problems = LiveOps.validateConfig(cfg, T0)
		expect(ok).toBe(false)
		local text = table.concat(problems, "\n")
		expect(text).toContain("MAYUSCULAS")
		expect(text).toContain("sin reward")
		expect(text).toContain("expiresAt debe ser posterior")
	end)

	it("limita los eventos activos o proximos a 10", function()
		local cfg = baseConfig()
		cfg.events = {}
		for i = 1, 11 do
			table.insert(cfg.events, { id = "e" .. i, name = "E", startsAt = T0, endsAt = T0 + 1000 })
		end
		local ok, problems = LiveOps.validateConfig(cfg, T0 + 10, 10)
		expect(ok).toBe(false)
		expect(table.concat(problems, "\n")).toContain("el maximo es 10")
		-- los ya terminados no cuentan
		local ok2 = LiveOps.validateConfig(cfg, T0 + 5000, 10)
		expect(ok2).toBe(true)
	end)

	it("rechaza modificadores invalidos y tipos erroneos", function()
		local cfg = baseConfig()
		cfg.events[1].modifiers = { coins = 0 / 0 }
		expect((LiveOps.validateConfig(cfg, T0))).toBe(false)
		expect((LiveOps.validateConfig("nope", T0))).toBe(false)
		expect((LiveOps.validateConfig({}, T0))).toBe(false)
	end)
end)

describe("LiveOps (instancia)", function()
	local env, now, ops, remote, fetchCalls, logs

	local function setNow(t)
		now = t
	end

	local function newOps(overrides)
		local cfg = {
			defaults = baseConfig(),
			now = function()
				return now
			end,
			task = env.task,
			random = function()
				return 0.5
			end,
			log = function(m)
				table.insert(logs, m)
			end,
			fetch = function()
				fetchCalls += 1
				if remote == "error" then
					error("sin red")
				end
				return remote
			end,
			pollSeconds = 100,
		}
		for k, v in overrides or {} do
			cfg[k] = v
		end
		return LiveOps.new(cfg)
	end

	beforeEach(function()
		env = Mocks.new()
		now = T0
		remote = nil
		fetchCalls = 0
		logs = {}
		ops = newOps()
	end)

	it("rechaza una configuracion por defecto invalida", function()
		local bad = baseConfig()
		bad.events[1].endsAt = 0
		expect(function()
			LiveOps.new({ defaults = bad })
		end).toThrow("configuracion por defecto")
	end)

	it("getActiveEvents respeta las ventanas y da el tiempo restante exacto", function()
		setNow(T0 + 500)
		expect(ops:getActiveEvents()).toHaveLength(0)
		setNow(T0 + 1200)
		local active = ops:getActiveEvents()
		expect(active).toHaveLength(1)
		expect(active[1].id).toBe("golden_tide")
		expect(active[1].secondsLeft).toBe(800)
		setNow(T0 + 1700)
		active = ops:getActiveEvents()
		expect(active).toHaveLength(2)
		expect(active[1].id).toBe("golden_tide") -- ordenados por inicio
		-- un evento terminado NO se reinicia solo
		setNow(T0 + 2500)
		active = ops:getActiveEvents()
		expect(active).toHaveLength(1)
		expect(active[1].id).toBe("mythic_moon")
		setNow(T0 + 3000)
		expect(ops:getActiveEvents()).toHaveLength(0)
		setNow(T0 + 999999)
		expect(ops:getActiveEvents()).toHaveLength(0)
	end)

	it("getUpcomingEvents lista lo que empezara dentro del horizonte", function()
		setNow(T0 + 500)
		local upcoming = ops:getUpcomingEvents(600)
		expect(upcoming).toHaveLength(1) -- solo golden_tide (empieza en 500 s); mythic_moon en 1000 s
		expect(upcoming[1].id).toBe("golden_tide")
		expect(upcoming[1].secondsLeft).toBe(500)
		expect(ops:getUpcomingEvents(2000)).toHaveLength(2)
		expect(ops:getUpcomingEvents(10)).toHaveLength(0)
	end)

	it("getModifierSources entrega fuentes listas para Economy.combineMultipliers", function()
		setNow(T0 + 1700)
		local sources = ops:getModifierSources()
		expect(sources).toHaveLength(3)
		local byKey = {}
		for _, source in sources do
			byKey[source.id .. "/" .. source.kind] = source.value
			expect(source.active).toBe(true)
		end
		expect(byKey["event:golden_tide/coins"]).toBe(2)
		expect(byKey["event:mythic_moon/luck"]).toBe(3)
		expect(byKey["event:mythic_moon/coins"]).toBe(1.5)
	end)

	it("los eventos rotativos cambian solos segun la configuracion", function()
		local cfg = baseConfig()
		cfg.events = {}
		for slot = 0, 2 do
			table.insert(cfg.events, {
				id = "rot" .. slot,
				name = "Rotacion " .. slot,
				cycle = { anchor = T0, slotSeconds = 3600, slotCount = 3, slot = slot },
			})
		end
		local rot = newOps({ defaults = cfg })
		setNow(T0 + 10)
		expect(rot:getActiveEvents()[1].id).toBe("rot0")
		setNow(T0 + 3600 + 10)
		expect(rot:getActiveEvents()[1].id).toBe("rot1")
		setNow(T0 + 3 * 3600 + 10)
		expect(rot:getActiveEvents()[1].id).toBe("rot0") -- vuelve a empezar la rotacion
		expect(rot:getActiveEvents()[1].secondsLeft).toBe(3590)
	end)

	describe("configuracion remota", function()
		it("aplica una configuracion nueva y valida", function()
			local cfg = baseConfig()
			cfg.version = 2
			cfg.events[1].name = "Marea Nueva"
			remote = cfg
			expect(ops:refresh()).toBe(true)
			setNow(T0 + 1200)
			expect(ops:getActiveEvents()[1].name).toBe("Marea Nueva")
		end)

		it("una configuracion invalida NO reemplaza a la buena", function()
			local cfg = baseConfig()
			cfg.version = 2
			cfg.events[1].endsAt = 0
			remote = cfg
			expect(ops:refresh()).toBe(false)
			expect(table.concat(logs, "\n")).toContain("INVALIDA")
			setNow(T0 + 1200)
			expect(ops:getActiveEvents()[1].name).toBe("Marea Dorada")
		end)

		it("un error de red conserva la configuracion anterior", function()
			remote = "error"
			expect(ops:refresh()).toBe(false)
			setNow(T0 + 1200)
			expect(ops:getActiveEvents()).toHaveLength(1)
		end)

		it("misma version o sin configuracion remota: no cambia nada", function()
			remote = baseConfig() -- version 1 = la de los defaults
			expect(ops:refresh()).toBe(false)
			remote = nil
			expect(ops:refresh()).toBe(false)
		end)

		it("el sondeo refresca periodicamente y se puede detener", function()
			local cfg = baseConfig()
			cfg.version = 5
			remote = cfg
			ops:startPolling()
			env.clock:advance(1) -- primer refresco inmediato
			expect(fetchCalls).toBe(1)
			env.clock:advance(100)
			expect(fetchCalls).toBe(2)
			ops:stopPolling()
			env.clock:advance(1000)
			expect(fetchCalls).toBeLessThanOrEqual(3)
			env.clock:runAll(500)
			local after = fetchCalls
			env.clock:advance(1000)
			expect(fetchCalls).toBe(after)
		end)

		it("subscribe pide refrescar cuando MessagingService avisa", function()
			local callback
			local messaging = {
				SubscribeAsync = function(_, topic, fn)
					expect(topic).toBe("LiveOpsUpdated")
					callback = fn
					return { Disconnect = function() end }
				end,
			}
			expect(ops:subscribe(messaging, "LiveOpsUpdated")).toBe(true)
			local cfg = baseConfig()
			cfg.version = 9
			remote = cfg
			callback({ Data = "x", Sent = now })
			env.clock:advance(10) -- el retraso aleatorio (< 5 s) y el refresco
			expect(fetchCalls).toBe(1)
		end)

		it("si no se puede suscribir devuelve false y no rompe", function()
			local messaging = {
				SubscribeAsync = function()
					error("cuota")
				end,
			}
			expect(ops:subscribe(messaging, "T")).toBe(false)
		end)
	end)

	describe("codigos de canje", function()
		it("canjea una vez por jugador y marca el uso", function()
			local redeemed: { [string]: number } = {}
			local result = ops:redeemCode(redeemed, "welcome")
			expect(result.ok).toBe(true)
			expect(result.reward).toEqual({ coins = 500 })
			expect(result.code).toBe("WELCOME")
			expect(redeemed.WELCOME).toBe(T0)
			local again = ops:redeemCode(redeemed, " WELCOME ")
			expect(again.ok).toBe(false)
			expect(again.reason).toBe("already")
			-- otro jugador puede canjearlo
			expect(ops:redeemCode({}, "WELCOME").ok).toBe(true)
		end)

		it("devuelve una copia: modificar la recompensa no altera la configuracion", function()
			local result = ops:redeemCode({}, "WELCOME")
			result.reward.coins = 999999
			expect(ops:redeemCode({}, "WELCOME").reward.coins).toBe(500)
		end)

		it("respeta inicio y caducidad (fin exclusivo)", function()
			setNow(T0 + 50)
			expect(ops:redeemCode({}, "SUMMER").reason).toBe("notStarted")
			setNow(T0 + 100)
			expect(ops:redeemCode({}, "SUMMER").ok).toBe(true)
			setNow(T0 + 4999)
			expect(ops:redeemCode({}, "SUMMER").ok).toBe(true)
			setNow(T0 + 5000)
			local expired = ops:redeemCode({}, "SUMMER")
			expect(expired.ok).toBe(false)
			expect(expired.reason).toBe("expired")
		end)

		it("un codigo caducado no se marca como usado", function()
			setNow(T0 + 6000)
			local redeemed: { [string]: number } = {}
			ops:redeemCode(redeemed, "SUMMER")
			expect(redeemed.SUMMER).toBeNil()
		end)

		it("rechaza codigos desconocidos y entradas invalidas sin tocar el perfil", function()
			local redeemed = {}
			expect(ops:redeemCode(redeemed, "NOPE").reason).toBe("unknown")
			expect(ops:redeemCode(redeemed, "").reason).toBe("invalid")
			expect(ops:redeemCode(redeemed, 42).reason).toBe("invalid")
			expect(ops:redeemCode(redeemed, "a b").reason).toBe("invalid")
			expect(next(redeemed)).toBeNil()
		end)

		it("los codigos se actualizan con la configuracion remota (sin republicar)", function()
			local cfg = baseConfig()
			cfg.version = 2
			cfg.codes.NEWCODE = { reward = { pearls = 10 } }
			remote = cfg
			ops:refresh()
			expect(ops:redeemCode({}, "newcode").ok).toBe(true)
		end)
	end)

	describe("bienvenida y temporada", function()
		it("muestra el mensaje solo si no se vio y no caduco", function()
			expect(ops:getWelcome(nil).id).toBe("w1")
			expect(ops:getWelcome("w1")).toBeNil()
			expect(ops:getWelcome("otro").id).toBe("w1")
			setNow(T0 + 10000)
			expect(ops:getWelcome(nil)).toBeNil() -- caducado
		end)

		it("getSeason devuelve la temporada vigente", function()
			expect(ops:getSeason().id).toBe(1)
			setNow(T0 + 100000)
			expect(ops:getSeason()).toBeNil()
		end)
	end)
end)
