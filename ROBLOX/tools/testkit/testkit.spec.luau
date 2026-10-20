--!nonstrict
-- Autotest del propio testkit (expect, spies y runner).

local testkit = require("@testkit")
local describe, it, expect = testkit.describe, testkit.it, testkit.expect

-- Ejecuta una funcion y devuelve el mensaje del fallo de expect (o nil si pasa).
local function failureOf(fn): string?
	local ok, err = pcall(fn)
	if ok then
		return nil
	end
	return type(err) == "table" and err.message or tostring(err)
end

describe("expect", function()
	it("toBe usa igualdad estricta (rawequal) y trata NaN como igual a NaN", function()
		expect(1).toBe(1)
		expect("a").toBe("a")
		expect(0 / 0).toBe(0 / 0)
		expect(failureOf(function()
			expect({}).toBe({})
		end)).toContain("to be")
	end)

	it("toEqual compara en profundidad", function()
		expect({ a = 1, b = { 1, 2, { c = true } } }).toEqual({ a = 1, b = { 1, 2, { c = true } } })
		expect(failureOf(function()
			expect({ a = 1 }).toEqual({ a = 2 })
		end)).toContain("to equal")
		expect(failureOf(function()
			expect({ a = 1 }).toEqual({ a = 1, b = 2 })
		end)).toBeType("string")
	end)

	it("toEqual admite comodines y tablas con ciclos", function()
		expect({ id = 5, name = "x" }).toEqual({ id = expect.any("number"), name = expect.anything() })
		local a, b = {}, {}
		a.self, b.self = a, b
		expect(a).toEqual(b)
	end)

	it(".never invierte el matcher", function()
		expect(1).never.toBe(2)
		expect({ 1 }).never.toEqual({ 2 })
		expect(failureOf(function()
			expect(1).never.toBe(1)
		end)).toContain("not to be")
	end)

	it("matchers de nil/verdad/numeros", function()
		expect(nil).toBeNil()
		expect(false).toBeFalsy()
		expect(0).toBeTruthy() -- en Luau 0 es verdadero
		expect(5).toBeGreaterThan(4)
		expect(5).toBeGreaterThanOrEqual(5)
		expect(4).toBeLessThan(5)
		expect(5).toBeLessThanOrEqual(5)
		expect(0.1 + 0.2).toBeCloseTo(0.3, 5)
		expect(failureOf(function()
			expect(1).toBeCloseTo(2)
		end)).toContain("not close")
	end)

	it("toContain / toHaveLength / toMatch / toHaveProperty / toBeType", function()
		expect("hello world").toContain("lo wo")
		expect({ 1, 2, 3 }).toContain(2)
		expect({ { a = 1 } }).toContain({ a = 1 })
		expect({ 1, 2, 3 }).toHaveLength(3)
		expect("abc").toHaveLength(3)
		expect("id_42").toMatch("^id_%d+$")
		expect({ a = 1 }).toHaveProperty("a")
		expect({ a = { b = 2 } }).toHaveProperty("a", { b = 2 })
		expect("x").toBeType("string")
	end)

	it("toThrow: cualquier error, texto, predicado y negado", function()
		expect(function()
			error("boom: algo fallo")
		end).toThrow()
		expect(function()
			error("boom: algo fallo")
		end).toThrow("algo fallo")
		expect(function()
			error({ code = 7 })
		end).toThrow(function(err)
			return err.code == 7
		end)
		expect(function() end).never.toThrow()
		expect(failureOf(function()
			expect(function() end).toThrow()
		end)).toContain("to throw")
	end)

	it("matcher desconocido da un error claro", function()
		expect(failureOf(function()
			expect(1).toBeAwesome()
		end)).toContain("matcher desconocido")
	end)
end)

describe("spy (testkit.fn)", function()
	it("registra llamadas y argumentos", function()
		local fn = testkit.fn(function(a, b)
			return a + b
		end)
		expect(fn(1, 2)).toBe(3)
		fn(3, 4)
		expect(fn).toHaveBeenCalled()
		expect(fn).toHaveBeenCalledTimes(2)
		expect(fn).toHaveBeenCalledWith(3, 4)
		expect(fn).never.toHaveBeenCalledWith(9, 9)
		expect(fn.results).toEqual({ 3, 7 })
	end)

	it("mockReturn y reset", function()
		local fn = testkit.fn():mockReturn("x")
		expect(fn()).toBe("x")
		fn:reset()
		expect(fn.callCount).toBe(0)
	end)
end)

describe("runner", function()
	local function summaryOf(build)
		local runner = testkit.createRunner({ timeout = 0.2 })
		build(runner)
		return runner:run({ silent = true, exit = false })
	end

	it("cuenta pasados, fallidos y omitidos", function()
		local s = summaryOf(function(r)
			r.describe("suite", function()
				r.it("ok", function() end)
				r.it("falla", function()
					r.expect(1).toBe(2)
				end)
				r.it.skip("omitido", function()
					error("no deberia correr")
				end)
			end)
		end)
		expect(s.passed).toBe(1)
		expect(s.failed).toBe(1)
		expect(s.skipped).toBe(1)
		expect(s.failures[1].name).toBe("suite > falla")
	end)

	it("ejecuta hooks en orden y afterEach aunque el test falle", function()
		local order = {}
		summaryOf(function(r)
			r.describe("outer", function()
				r.beforeAll(function()
					table.insert(order, "beforeAll")
				end)
				r.beforeEach(function()
					table.insert(order, "beforeEach-outer")
				end)
				r.afterEach(function()
					table.insert(order, "afterEach-outer")
				end)
				r.afterAll(function()
					table.insert(order, "afterAll")
				end)
				r.describe("inner", function()
					r.beforeEach(function()
						table.insert(order, "beforeEach-inner")
					end)
					r.afterEach(function()
						table.insert(order, "afterEach-inner")
					end)
					r.it("falla", function()
						table.insert(order, "test")
						error("x")
					end)
				end)
			end)
		end)
		expect(order).toEqual({
			"beforeAll",
			"beforeEach-outer",
			"beforeEach-inner",
			"test",
			"afterEach-inner",
			"afterEach-outer",
			"afterAll",
		})
	end)

	it("respeta it.only", function()
		local s = summaryOf(function(r)
			r.it("a", function() end)
			r.it.only("b", function() end)
			r.it("c", function() end)
		end)
		expect(s.passed).toBe(1)
		expect(s.skipped).toBe(2)
	end)

	it("aplica un timeout a los tests que nunca terminan", function()
		local s = summaryOf(function(r)
			r.it("cuelga", function()
				coroutine.yield() -- nunca se reanuda
			end)
		end)
		expect(s.failed).toBe(1)
		expect(s.failures[1].error.message).toContain("timeout")
	end)

	it("un error al definir una suite se informa como fallo", function()
		local s = summaryOf(function(r)
			r.describe("rota", function()
				error("fallo al definir")
			end)
		end)
		expect(s.failed).toBe(1)
		expect(s.failures[1].error.message).toContain("fallo al definir")
	end)

	it("soporta tests asincronos que ceden con el scheduler real", function()
		local task = require("@lune/task")
		local finished = false
		local s = summaryOf(function(r)
			r.it("espera", function()
				task.wait(0.01)
				finished = true
			end)
		end)
		expect(s.passed).toBe(1)
		expect(finished).toBe(true)
	end)
end)
