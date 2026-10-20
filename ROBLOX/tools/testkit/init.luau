--!nonstrict
--[[
	testkit: runner de tests + expect + spies para Lune. Sin dependencias.

	  local testkit = require("@testkit")
	  local describe, it, expect = testkit.describe, testkit.it, testkit.expect

	  describe("Suma", function()
	  	it("suma", function()
	  		expect(1 + 1).toBe(2)
	  	end)
	  end)
	  -- no hace falta llamar a nada al final: el runner se ejecuta solo al terminar el script.
	  -- (explicito y opcional: testkit.run())

	Mocks de servicios de Roblox: require("@testkit/mocks")  (ver ROBLOX/tools/testkit/mocks/init.luau).
	El alias @testkit se define en ROBLOX/.luaurc.
]]

-- En un init.luau, "./" apunta al directorio padre: los hijos se piden con @self.
local Runner = require("@self/runner")
local Spy = require("@self/spy")
local expect = require("@self/expect")

local default = Runner.new()
default:enableAutoRun()

local testkit = {
	describe = default.describe,
	it = default.it,
	test = default.test,
	beforeAll = default.beforeAll,
	afterAll = default.afterAll,
	beforeEach = default.beforeEach,
	afterEach = default.afterEach,
	expect = expect,
	fn = Spy.new,
	spy = Spy.new,
	run = function(options)
		return default:run(options)
	end,
	-- Runner aislado (para testear el propio testkit o agrupar suites independientes)
	createRunner = function(options)
		return Runner.new(options)
	end,
}

return testkit
