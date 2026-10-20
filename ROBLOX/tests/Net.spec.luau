--!nonstrict
-- Tests de packages/Net: validacion de remotos y limitador de frecuencia (token bucket).
local testkit = require("@testkit")
local Mocks = require("@testkit/mocks")
local Net = require("../packages/Net")

local describe, it, expect, beforeEach = testkit.describe, testkit.it, testkit.expect, testkit.beforeEach
local t = Net.t

local function fakePlayer(userId: number)
	return { UserId = userId, Name = "P" .. userId }
end

describe("validadores", function()
	it("number rechaza NaN, inf, tipos erroneos y fuera de rango", function()
		local v = t.number({ min = 0, max = 1 })
		expect((v(0.5))).toBe(true)
		expect((v(0 / 0))).toBe(false)
		expect((v(math.huge))).toBe(false)
		expect((v(-math.huge))).toBe(false)
		expect((v("0.5"))).toBe(false)
		expect((v(nil))).toBe(false)
		expect((v({}))).toBe(false)
		expect((v(-0.001))).toBe(false)
		expect((v(1.001))).toBe(false)
	end)

	it("integer exige enteros dentro del rango", function()
		local v = t.integer(1, 10)
		expect((v(5))).toBe(true)
		expect((v(5.5))).toBe(false)
		expect((v(0))).toBe(false)
		expect((v(11))).toBe(false)
	end)

	it("string limita longitud, UTF-8 y patron", function()
		local v = t.string({ maxLength = 8, pattern = "^[%w_]+$" })
		expect((v("abc_123"))).toBe(true)
		expect((v(""))).toBe(false)
		expect((v(string.rep("a", 9)))).toBe(false)
		expect((v("a b"))).toBe(false)
		expect((v(123))).toBe(false)
		expect((t.string()("\xff\xfe"))).toBe(false) -- UTF-8 invalido
	end)

	it("oneOf solo admite valores de la lista", function()
		local v = t.oneOf({ "starter_rod", "reed_rod" })
		expect((v("reed_rod"))).toBe(true)
		expect((v("admin_rod"))).toBe(false)
		expect((v({}))).toBe(false)
		expect((v(0 / 0))).toBe(false)
	end)

	it("optional acepta nil pero valida si hay valor; boolean es estricto", function()
		local v = t.optional(t.boolean())
		expect((v(nil))).toBe(true)
		expect((v(true))).toBe(true)
		expect((v("true"))).toBe(false)
	end)

	it("checkArgs rechaza argumentos de mas y faltantes obligatorios", function()
		local schema = { t.integer(1, 5), t.optional(t.boolean()) }
		expect((Net.checkArgs(schema, 3))).toBe(true)
		expect((Net.checkArgs(schema, 3, true))).toBe(true)
		expect((Net.checkArgs(schema, 3, true, 9))).toBe(false) -- demasiados
		expect((Net.checkArgs(schema))).toBe(false) -- falta el obligatorio
		local ok, reason = Net.checkArgs(schema, "x")
		expect(ok).toBe(false)
		expect(reason).toContain("argumento #1")
	end)
end)

describe("token bucket", function()
	it("gasta fichas y se rellena con el tiempo", function()
		local now = 0
		local bucket = Net.newBucket(3, 1, function()
			return now
		end)
		expect(bucket:take(1)).toBe(true)
		expect(bucket:take(1)).toBe(true)
		expect(bucket:take(1)).toBe(true)
		expect(bucket:take(1)).toBe(false)
		now = 1
		expect(bucket:take(1)).toBe(true)
		expect(bucket:take(1)).toBe(false)
		now = 100
		expect(bucket:available()).toBe(3) -- nunca supera la capacidad
	end)

	it("un reloj que retrocede no regala fichas", function()
		local now = 10
		local bucket = Net.newBucket(2, 1, function()
			return now
		end)
		bucket:take(2)
		now = 5
		expect(bucket:take(1)).toBe(false)
		now = 6
		expect(bucket:take(1)).toBe(true)
	end)
end)

describe("Net.newServer", function()
	local now, server, remotes, handled, rejected, abuse

	local function create(className, name)
		local remote = {
			ClassName = className,
			Name = name,
			OnServerEvent = Mocks.Signal.new(),
			fired = {},
		}
		function remote:FireClient(player, ...)
			table.insert(self.fired, { player = player, args = table.pack(...) })
		end
		function remote:FireAllClients(...)
			table.insert(self.fired, { all = true, args = table.pack(...) })
		end
		remotes[name] = remote
		return remote
	end

	beforeEach(function()
		now = 0
		remotes = {}
		handled = {}
		rejected = {}
		abuse = {}
		server = Net.newServer({
			createRemote = create,
			clock = function()
				return now
			end,
			onReject = function(player, name, reason)
				table.insert(rejected, { userId = player.UserId, name = name, reason = reason })
			end,
			abuseThreshold = 5,
			abuseWindowSeconds = 10,
			onAbuse = function(player, count)
				table.insert(abuse, { userId = player.UserId, count = count })
			end,
			log = function() end,
		})
		server:event("CastRod", {
			args = { t.number({ min = 0, max = 1 }) },
			rate = { capacity = 3, refillPerSecond = 1 },
			handler = function(player, power)
				table.insert(handled, { userId = player.UserId, power = power })
			end,
		})
	end)

	local function call(player, ...)
		remotes.CastRod.OnServerEvent:Fire(player, ...)
	end

	it("entrega al handler una llamada valida", function()
		call(fakePlayer(1), 0.75)
		expect(handled).toHaveLength(1)
		expect(handled[1].power).toBe(0.75)
	end)

	it("rechaza NaN, inf, tipos erroneos, rango y aridad sin llamar al handler", function()
		local p = fakePlayer(1)
		call(p, 0 / 0)
		call(p, math.huge)
		call(p, "1")
		call(p, 5)
		call(p, 0.5, "extra")
		call(p)
		expect(handled).toHaveLength(0)
		expect(rejected).toHaveLength(6)
		expect(rejected[1].reason).toContain("no finito")
	end)

	it("limita la frecuencia por jugador (token bucket) y se recupera con el tiempo", function()
		local p = fakePlayer(1)
		for _ = 1, 10 do
			call(p, 0.5)
		end
		expect(handled).toHaveLength(3) -- capacidad 3
		expect(rejected[1].reason).toBe("rate")
		now = 2 -- +2 fichas
		call(p, 0.5)
		call(p, 0.5)
		call(p, 0.5)
		expect(handled).toHaveLength(5)
	end)

	it("los limites son independientes por jugador", function()
		local a, b = fakePlayer(1), fakePlayer(2)
		for _ = 1, 5 do
			call(a, 0.1)
		end
		call(b, 0.1)
		expect(handled).toHaveLength(4) -- 3 de a + 1 de b
	end)

	it("dispara onAbuse una sola vez al superar el umbral de rechazos en la ventana", function()
		local p = fakePlayer(7)
		for _ = 1, 20 do
			call(p, "malo")
		end
		expect(abuse).toHaveLength(1)
		expect(abuse[1].userId).toBe(7)
		expect(abuse[1].count).toBe(5)
		now = 100 -- ventana nueva: puede volver a marcarse
		for _ = 1, 20 do
			call(p, "malo")
		end
		expect(abuse).toHaveLength(2)
	end)

	it("forget libera los contadores del jugador", function()
		local p = fakePlayer(3)
		for _ = 1, 3 do
			call(p, 0.5)
		end
		call(p, 0.5)
		expect(handled).toHaveLength(3)
		server:forget(p)
		call(p, 0.5) -- bucket nuevo: otra vez 3 fichas
		expect(handled).toHaveLength(4)
	end)

	it("un error dentro del handler no se propaga y se registra", function()
		local messages = {}
		local s2 = Net.newServer({
			createRemote = create,
			log = function(m)
				table.insert(messages, m)
			end,
		})
		s2:event("Boom", {
			args = {},
			handler = function()
				error("kaboom")
			end,
		})
		remotes.Boom.OnServerEvent:Fire(fakePlayer(1))
		expect(messages).toHaveLength(1)
		expect(messages[1]).toContain("kaboom")
	end)

	it("limite global por jugador sobre todos los remotos", function()
		local s2 = Net.newServer({
			createRemote = create,
			clock = function()
				return now
			end,
			globalRate = { capacity = 4, refillPerSecond = 0 },
			log = function() end,
		})
		local count = 0
		s2:event("A", {
			args = {},
			handler = function()
				count += 1
			end,
		})
		s2:event("B", {
			args = {},
			handler = function()
				count += 1
			end,
		})
		local p = fakePlayer(9)
		for _ = 1, 3 do
			remotes.A.OnServerEvent:Fire(p)
			remotes.B.OnServerEvent:Fire(p)
		end
		expect(count).toBe(4)
	end)

	it("RemoteFunction: devuelve valores, valida y devuelve nil si se rechaza", function()
		server:func("GetPrice", {
			args = { t.oneOf({ "rod_1", "rod_2" }) },
			handler = function(_, key)
				return 100, key
			end,
		})
		local fn = remotes.GetPrice.OnServerInvoke
		local price, key = fn(fakePlayer(1), "rod_2")
		expect(price).toBe(100)
		expect(key).toBe("rod_2")
		expect(fn(fakePlayer(1), "hack")).toBeNil()
		expect(fn(fakePlayer(1), 0 / 0)).toBeNil()
	end)

	it("fireClient / fireAllClients usan el remoto registrado y fallan con nombres desconocidos", function()
		server:event("Banner", { args = {}, handler = function() end })
		local p = fakePlayer(1)
		server:fireClient("Banner", p, "hola", 3)
		server:fireAllClients("Banner", "todos")
		expect(remotes.Banner.fired).toHaveLength(2)
		expect(remotes.Banner.fired[1].args[1]).toBe("hola")
		expect(function()
			server:fireClient("Nope", p)
		end).toThrow("remoto desconocido")
	end)

	it("outbound crea un remoto servidor -> cliente sin escuchar al cliente", function()
		server:outbound("State")
		expect(remotes.State.OnServerEvent:ConnectionCount()).toBe(0)
		server:fireClient("State", fakePlayer(1), { coins = 5 })
		expect(remotes.State.fired).toHaveLength(1)
		expect(function()
			server:outbound("State")
		end).toThrow("remoto duplicado")
	end)

	it("no permite registrar dos veces el mismo remoto", function()
		expect(function()
			server:event("CastRod", { args = {}, handler = function() end })
		end).toThrow("remoto duplicado")
	end)

	it("cuenta aceptados y rechazados", function()
		local p = fakePlayer(1)
		call(p, 0.5)
		call(p, "x")
		local stats = server:stats()
		expect(stats.accepted).toBe(1)
		expect(stats.rejected).toBe(1)
	end)
end)
