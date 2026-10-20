--!nonstrict
--[[
	expect(valor) estilo Jest/TestEZ.

	Matchers: toBe, toEqual, toBeNil, toBeTruthy, toBeFalsy, toBeGreaterThan(OrEqual),
	toBeLessThan(OrEqual), toBeCloseTo, toBeType, toContain, toHaveLength, toMatch,
	toHaveProperty, toThrow, toHaveBeenCalled, toHaveBeenCalledTimes, toHaveBeenCalledWith.
	Negacion: `.never` (en Luau `not` es palabra reservada): expect(x).never.toBe(y).
	Comodines para toEqual / toHaveBeenCalledWith: expect.any("number"), expect.anything().
]]

local Spy = require("./spy")

local expectModule = {}

----------------------------------------------------------------------------
-- Formato de valores para mensajes
----------------------------------------------------------------------------

local function format(value, depth, seen)
	depth = depth or 0
	local t = type(value)
	if t == "string" then
		return string.format("%q", value)
	elseif t == "table" then
		if value.__asymmetric then
			return value.__describe
		end
		seen = seen or {}
		if seen[value] then
			return "<ciclo>"
		end
		if depth >= 4 then
			return "{...}"
		end
		seen[value] = true
		local parts = {}
		local count = 0
		local keys = {}
		for k in value do
			table.insert(keys, k)
		end
		table.sort(keys, function(a, b)
			local ta, tb = type(a), type(b)
			if ta == tb and (ta == "number" or ta == "string") then
				return a < b
			end
			return ta < tb
		end)
		for _, k in keys do
			count += 1
			if count > 12 then
				table.insert(parts, "...")
				break
			end
			local keyText = type(k) == "string" and k or "[" .. tostring(k) .. "]"
			table.insert(parts, keyText .. " = " .. format(value[k], depth + 1, seen))
		end
		seen[value] = nil
		return "{ " .. table.concat(parts, ", ") .. " }"
	end
	return tostring(value)
end

expectModule.format = format

----------------------------------------------------------------------------
-- Igualdad profunda
----------------------------------------------------------------------------

local function deepEqual(a, b, seen)
	if type(b) == "table" and b.__asymmetric then
		return b.__match(a)
	end
	if type(a) == "table" and a.__asymmetric then
		return a.__match(b)
	end
	if a == b then
		return true
	end
	if type(a) == "number" and type(b) == "number" then
		return a ~= a and b ~= b -- NaN == NaN
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	seen = seen or {}
	if seen[a] == b then
		return true
	end
	seen[a] = b
	for k, v in a do
		if not deepEqual(v, b[k], seen) then
			return false
		end
	end
	for k in b do
		if a[k] == nil then
			return false
		end
	end
	return true
end

expectModule.deepEqual = deepEqual

----------------------------------------------------------------------------
-- Comodines
----------------------------------------------------------------------------

function expectModule.any(typeName: string)
	return {
		__asymmetric = true,
		__describe = "Any<" .. typeName .. ">",
		__match = function(value)
			return type(value) == typeName or typeof(value) == typeName
		end,
	}
end

function expectModule.anything()
	return {
		__asymmetric = true,
		__describe = "Anything",
		__match = function(value)
			return value ~= nil
		end,
	}
end

----------------------------------------------------------------------------
-- Matchers
----------------------------------------------------------------------------

local matchers = {}

local function fail(message: string)
	error({ __testFailure = true, message = message }, 0)
end

local function check(self, pass: boolean, positiveMessage: string, negativeMessage: string)
	if self._negated then
		if pass then
			fail(negativeMessage)
		end
	elseif not pass then
		fail(positiveMessage)
	end
end

function matchers.toBe(self, expected)
	check(
		self,
		rawequal(self._actual, expected) or (self._actual ~= self._actual and expected ~= expected),
		"expected " .. format(self._actual) .. " to be " .. format(expected),
		"expected " .. format(self._actual) .. " not to be " .. format(expected)
	)
end

function matchers.toEqual(self, expected)
	check(
		self,
		deepEqual(self._actual, expected),
		"expected " .. format(self._actual) .. " to equal " .. format(expected),
		"expected " .. format(self._actual) .. " not to equal " .. format(expected)
	)
end

function matchers.toBeNil(self)
	check(
		self,
		self._actual == nil,
		"expected " .. format(self._actual) .. " to be nil",
		"expected value not to be nil"
	)
end

function matchers.toBeTruthy(self)
	check(
		self,
		not not self._actual,
		"expected " .. format(self._actual) .. " to be truthy",
		"expected " .. format(self._actual) .. " not to be truthy"
	)
end

function matchers.toBeFalsy(self)
	check(
		self,
		not self._actual,
		"expected " .. format(self._actual) .. " to be falsy",
		"expected " .. format(self._actual) .. " not to be falsy"
	)
end

local function numeric(self, name)
	if type(self._actual) ~= "number" then
		fail(name .. ": expected a number, got " .. format(self._actual))
	end
end

function matchers.toBeGreaterThan(self, n)
	numeric(self, "toBeGreaterThan")
	check(self, self._actual > n, format(self._actual) .. " is not > " .. format(n), format(self._actual) .. " is > " .. format(n))
end

function matchers.toBeGreaterThanOrEqual(self, n)
	numeric(self, "toBeGreaterThanOrEqual")
	check(self, self._actual >= n, format(self._actual) .. " is not >= " .. format(n), format(self._actual) .. " is >= " .. format(n))
end

function matchers.toBeLessThan(self, n)
	numeric(self, "toBeLessThan")
	check(self, self._actual < n, format(self._actual) .. " is not < " .. format(n), format(self._actual) .. " is < " .. format(n))
end

function matchers.toBeLessThanOrEqual(self, n)
	numeric(self, "toBeLessThanOrEqual")
	check(self, self._actual <= n, format(self._actual) .. " is not <= " .. format(n), format(self._actual) .. " is <= " .. format(n))
end

-- |actual - expected| < 10^-digits / 2   (digits por defecto 2)
function matchers.toBeCloseTo(self, expected, digits)
	numeric(self, "toBeCloseTo")
	local tolerance = (10 ^ -(digits or 2)) / 2
	check(
		self,
		math.abs(self._actual - expected) < tolerance,
		format(self._actual) .. " is not close to " .. format(expected) .. " (digits " .. tostring(digits or 2) .. ")",
		format(self._actual) .. " is close to " .. format(expected)
	)
end

function matchers.toBeType(self, typeName)
	local actualType = typeof(self._actual)
	check(
		self,
		actualType == typeName or type(self._actual) == typeName,
		"expected type " .. typeName .. " but got " .. actualType,
		"expected type not to be " .. typeName
	)
end

function matchers.toContain(self, item)
	local actual = self._actual
	local found = false
	if type(actual) == "string" then
		found = string.find(actual, tostring(item), 1, true) ~= nil
	elseif type(actual) == "table" then
		for _, v in actual do
			if deepEqual(v, item) then
				found = true
				break
			end
		end
	else
		fail("toContain: expected a string or table, got " .. format(actual))
	end
	check(self, found, format(actual) .. " does not contain " .. format(item), format(actual) .. " contains " .. format(item))
end

function matchers.toHaveLength(self, n)
	local actual = self._actual
	local length
	if type(actual) == "string" then
		length = #actual
	elseif type(actual) == "table" then
		length = #actual
	else
		fail("toHaveLength: expected a string or table, got " .. format(actual))
	end
	check(self, length == n, "expected length " .. tostring(n) .. " but got " .. tostring(length), "expected length not to be " .. tostring(n))
end

-- Patron de Luau (string.find), no regex.
function matchers.toMatch(self, pattern)
	if type(self._actual) ~= "string" then
		fail("toMatch: expected a string, got " .. format(self._actual))
	end
	check(
		self,
		string.find(self._actual, pattern) ~= nil,
		format(self._actual) .. " does not match pattern " .. format(pattern),
		format(self._actual) .. " matches pattern " .. format(pattern)
	)
end

-- toHaveProperty("clave") o toHaveProperty("clave", valor) (igualdad profunda)
function matchers.toHaveProperty(self, key, ...)
	local actual = self._actual
	if type(actual) ~= "table" then
		fail("toHaveProperty: expected a table, got " .. format(actual))
	end
	local has = actual[key] ~= nil
	if select("#", ...) > 0 then
		has = has and deepEqual(actual[key], (...))
	end
	check(self, has, format(actual) .. " does not have property " .. format(key), format(actual) .. " has property " .. format(key))
end

--[[
	toThrow()                    lanza cualquier error
	toThrow("texto")             el mensaje contiene el texto (busqueda literal)
	toThrow(function(err) ... end) predicado sobre el error (true = ok)
]]
function matchers.toThrow(self, expected)
	if type(self._actual) ~= "function" then
		fail("toThrow: expected a function, got " .. format(self._actual))
	end
	local ok, err = pcall(self._actual)
	local threw = not ok
	local matches = threw
	local detail = ""
	if threw and expected ~= nil then
		local message = type(err) == "table" and (err.message or format(err)) or tostring(err)
		if type(expected) == "string" then
			matches = string.find(message, expected, 1, true) ~= nil
			detail = " containing " .. format(expected) .. " (got " .. format(message) .. ")"
		elseif type(expected) == "function" then
			matches = expected(err) == true
			detail = " satisfying the predicate (got " .. format(message) .. ")"
		end
	end
	check(self, threw and matches, "expected function to throw" .. detail, "expected function not to throw" .. detail)
end

function matchers.toHaveBeenCalled(self)
	local spy = self._actual
	if not Spy.isSpy(spy) then
		fail("toHaveBeenCalled: expected a spy (testkit.fn)")
	end
	check(self, spy.callCount > 0, "expected spy to have been called", "expected spy not to have been called (called " .. spy.callCount .. " times)")
end

function matchers.toHaveBeenCalledTimes(self, n)
	local spy = self._actual
	if not Spy.isSpy(spy) then
		fail("toHaveBeenCalledTimes: expected a spy (testkit.fn)")
	end
	check(self, spy.callCount == n, "expected spy to be called " .. n .. " times but was called " .. spy.callCount, "expected spy not to be called " .. n .. " times")
end

function matchers.toHaveBeenCalledWith(self, ...)
	local spy = self._actual
	if not Spy.isSpy(spy) then
		fail("toHaveBeenCalledWith: expected a spy (testkit.fn)")
	end
	local expectedArgs = table.pack(...)
	local found = false
	for _, call in spy.calls do
		if call.n == expectedArgs.n then
			local same = true
			for i = 1, call.n do
				if not deepEqual(call[i], expectedArgs[i]) then
					same = false
					break
				end
			end
			if same then
				found = true
				break
			end
		end
	end
	check(
		self,
		found,
		"expected spy to have been called with " .. format(expectedArgs) .. " (calls: " .. tostring(#spy.calls) .. ")",
		"expected spy not to have been called with " .. format(expectedArgs)
	)
end

----------------------------------------------------------------------------
-- expect(...)
----------------------------------------------------------------------------

local Expectation = {}
Expectation.__index = function(self, key)
	if type(key) == "string" and string.sub(key, 1, 1) == "_" then
		return nil -- campos internos ausentes (p. ej. _actual = nil en expect(nil))
	end
	if key == "never" then
		return setmetatable({ _actual = rawget(self, "_actual"), _negated = not rawget(self, "_negated") }, Expectation)
	end
	local matcher = matchers[key]
	if matcher then
		return function(selfAgain, ...)
			return matcher(selfAgain, ...)
		end
	end
	error("expect(...): matcher desconocido '" .. tostring(key) .. "'", 2)
end

local expect = setmetatable({
	any = expectModule.any,
	anything = expectModule.anything,
	format = format,
	deepEqual = deepEqual,
}, {
	__call = function(_, actual)
		return setmetatable({ _actual = actual, _negated = false }, Expectation)
	end,
})

return expect
