--!nonstrict
--[[
	Runner de tests minimo (describe / it / hooks) para Lune.

	Cada *.spec.luau se ejecuta como un script independiente (`lune run archivo`):
	registra suites con describe/it y, al terminar el script, el runner se ejecuta solo
	(o explicitamente con `testkit.run()`), imprime el informe y sale con codigo 1 si
	algun test falla.

	Caracteristicas:
	  * describe / it / test, describe.skip / it.skip, describe.only / it.only
	  * beforeAll / afterAll / beforeEach / afterEach (anidados, afterEach corre aunque el test falle)
	  * tests que ceden (task.wait real, Signal:Wait ...) con timeout (5 s por defecto)
	  * filtro por nombre: variable de entorno TESTKIT_FILTER (subcadena del nombre completo)
	  * `Runner.new()` crea runners aislados (se usa para testear el propio testkit)
]]

local expect = require("./expect")

-- En Lune 0.11 `task` no es un global: se importa (y asi los mocks no lo pisan).
local task = require("@lune/task")

local okProcess, process = pcall(require, "@lune/process")
if not okProcess then
	process = nil
end

local Runner = {}
Runner.__index = Runner

local DEFAULT_TIMEOUT = 5

local function newSuite(name: string, parent: any?)
	return {
		name = name,
		parent = parent,
		items = {}, -- { {kind="test"|"suite", ...} } en orden de registro
		beforeAll = {},
		afterAll = {},
		beforeEach = {},
		afterEach = {},
		skip = false,
		only = false,
	}
end

function Runner.new(options: { timeout: number? }?)
	local self = setmetatable({}, Runner)
	self._root = newSuite("", nil)
	self._current = self._root
	self._hasOnly = false
	self._ran = false
	self._autoScheduled = false
	self._timeout = options and options.timeout or DEFAULT_TIMEOUT

	-- Funciones ligadas (sin `self`) para usarlas como globales del spec.
	local runner = self
	local function describe(name: string, fn: () -> ())
		runner:_describe(name, fn, false, false)
	end
	local function describeSkip(name: string, fn: () -> ())
		runner:_describe(name, fn, true, false)
	end
	local function describeOnly(name: string, fn: () -> ())
		runner:_describe(name, fn, false, true)
	end
	local function it(name: string, fn: () -> ())
		runner:_it(name, fn, false, false)
	end
	local function itSkip(name: string, fn: () -> ())
		runner:_it(name, fn, true, false)
	end
	local function itOnly(name: string, fn: () -> ())
		runner:_it(name, fn, false, true)
	end

	self.describe = setmetatable({ skip = describeSkip, only = describeOnly }, {
		__call = function(_, name, fn)
			describe(name, fn)
		end,
	})
	self.it = setmetatable({ skip = itSkip, only = itOnly }, {
		__call = function(_, name, fn)
			it(name, fn)
		end,
	})
	self.test = self.it
	self.beforeAll = function(fn)
		table.insert(runner._current.beforeAll, fn)
	end
	self.afterAll = function(fn)
		table.insert(runner._current.afterAll, fn)
	end
	self.beforeEach = function(fn)
		table.insert(runner._current.beforeEach, fn)
	end
	self.afterEach = function(fn)
		table.insert(runner._current.afterEach, fn)
	end
	self.expect = expect
	return self
end

function Runner:_scheduleAutoRun()
	if self._autoScheduled or not self._auto then
		return
	end
	self._autoScheduled = true
	task.defer(function()
		if not self._ran then
			self:run()
		end
	end)
end

function Runner:_describe(name: string, fn: () -> (), skip: boolean, only: boolean)
	local suite = newSuite(name, self._current)
	suite.skip = skip
	suite.only = only
	if only then
		self._hasOnly = true
	end
	table.insert(self._current.items, { kind = "suite", suite = suite })
	local previous = self._current
	self._current = suite
	local ok, err = pcall(fn)
	self._current = previous
	if not ok then
		-- un error al definir la suite se informa como test fallido
		table.insert(suite.items, {
			kind = "test",
			name = "(error al definir la suite)",
			fn = function()
				error(err, 0)
			end,
		})
	end
	self:_scheduleAutoRun()
end

function Runner:_it(name: string, fn: () -> (), skip: boolean, only: boolean)
	if only then
		self._hasOnly = true
	end
	table.insert(self._current.items, { kind = "test", name = name, fn = fn, skip = skip, only = only })
	self:_scheduleAutoRun()
end

----------------------------------------------------------------------------
-- Ejecucion de una funcion posiblemente asincrona, con timeout
----------------------------------------------------------------------------

local function normalizeError(err)
	if type(err) == "table" and err.__testFailure then
		return { message = err.message, assertion = true }
	end
	if type(err) == "table" and err.message then
		return { message = tostring(err.message), trace = err.trace }
	end
	return { message = tostring(err) }
end

-- Devuelve (ok, errInfo?)
function Runner:_runFunction(fn: () -> (), timeout: number)
	local runner = coroutine.running()
	local finished = false
	local waiting = false
	local resultOk, resultErr = true, nil
	local timer

	local function complete(ok, err)
		if finished then
			return
		end
		finished = true
		resultOk, resultErr = ok, err
		if timer then
			task.cancel(timer)
			timer = nil
		end
		if waiting then
			task.defer(runner)
		end
	end

	task.spawn(function()
		local ok, err = xpcall(fn, function(e)
			local info = normalizeError(e)
			if not info.assertion and not info.trace then
				info.trace = debug.traceback("", 2)
			end
			return info
		end)
		complete(ok, err)
	end)

	if not finished then
		timer = task.delay(timeout, function()
			timer = nil -- ya esta corriendo: no cancelarse a si mismo
			complete(false, { message = string.format("el test excedio el timeout de %gs (sin terminar)", timeout) })
		end)
		waiting = true
		coroutine.yield()
	end
	return resultOk, resultErr
end

----------------------------------------------------------------------------
-- Recorrido de suites
----------------------------------------------------------------------------

local function fullName(suite, testName: string?): string
	local parts = {}
	local s = suite
	while s and s.parent do
		table.insert(parts, 1, s.name)
		s = s.parent
	end
	if testName then
		table.insert(parts, testName)
	end
	return table.concat(parts, " > ")
end

local function suiteHasOnly(suite): boolean
	if suite.only then
		return true
	end
	for _, item in suite.items do
		if item.kind == "test" and item.only then
			return true
		elseif item.kind == "suite" and suiteHasOnly(item.suite) then
			return true
		end
	end
	return false
end

function Runner:run(options: { exit: boolean?, silent: boolean?, filter: string? }?)
	local opts = options or {}
	if self._ran then
		return self._summary
	end
	self._ran = true

	local silent = opts.silent == true
	local filter = opts.filter
	if filter == nil and process and process.env then
		filter = process.env.TESTKIT_FILTER
		if filter == "" then
			filter = nil
		end
	end

	local out = function(text: string)
		if not silent then
			print(text)
		end
	end

	local summary = { passed = 0, failed = 0, skipped = 0, total = 0, failures = {}, results = {} }
	local startClock = os.clock()
	local runner = self

	local function record(name: string, status: string, err: any?, ms: number)
		summary.total += 1
		if status == "passed" then
			summary.passed += 1
		elseif status == "failed" then
			summary.failed += 1
			table.insert(summary.failures, { name = name, error = err })
		else
			summary.skipped += 1
		end
		table.insert(summary.results, { name = name, status = status, error = err, ms = ms })
	end

	local function runHooks(hooks, label: string, suiteName: string)
		for _, hook in hooks do
			local ok, err = runner:_runFunction(hook, runner._timeout)
			if not ok then
				return false, { message = label .. " fallo en '" .. suiteName .. "': " .. tostring(err.message), trace = err.trace }
			end
		end
		return true, nil
	end

	local function collectHooks(suite, kind: string)
		local chain = {}
		local s = suite
		while s do
			table.insert(chain, 1, s)
			s = s.parent
		end
		local hooks = {}
		if kind == "beforeEach" then
			for _, node in chain do
				for _, h in node.beforeEach do
					table.insert(hooks, h)
				end
			end
		else
			for i = #chain, 1, -1 do
				for _, h in chain[i].afterEach do
					table.insert(hooks, h)
				end
			end
		end
		return hooks
	end

	local useOnly = self._hasOnly

	local function visit(suite, depth: number, inheritedSkip: boolean, inheritedOnly: boolean)
		local indent = string.rep("  ", depth)
		if suite.parent then
			out(indent .. suite.name)
		end
		local skipSuite = inheritedSkip or suite.skip
		local onlySuite = inheritedOnly or suite.only

		-- beforeAll solo si hay algo que ejecutar
		local ranBeforeAll = false
		local beforeAllError = nil

		local function ensureBeforeAll()
			if ranBeforeAll then
				return
			end
			ranBeforeAll = true
			local ok, err = runHooks(suite.beforeAll, "beforeAll", suite.name)
			if not ok then
				beforeAllError = err
			end
		end

		for _, item in suite.items do
			if item.kind == "suite" then
				visit(item.suite, depth + 1, skipSuite, onlySuite)
			else
				local name = fullName(suite, item.name)
				local skipped = skipSuite or item.skip or (useOnly and not (onlySuite or item.only))
				if not skipped and filter and not string.find(name, filter, 1, true) then
					skipped = true
				end
				if skipped then
					record(name, "skipped", nil, 0)
					out(indent .. "  - " .. item.name .. " (omitido)")
				else
					ensureBeforeAll()
					local t0 = os.clock()
					local ok, err
					if beforeAllError then
						ok, err = false, beforeAllError
					else
						ok, err = runHooks(collectHooks(suite, "beforeEach"), "beforeEach", suite.name)
						if ok then
							ok, err = self:_runFunction(item.fn, self._timeout)
						end
						-- afterEach siempre
						local okAfter, errAfter = runHooks(collectHooks(suite, "afterEach"), "afterEach", suite.name)
						if ok and not okAfter then
							ok, err = false, errAfter
						end
					end
					local ms = (os.clock() - t0) * 1000
					if ok then
						record(name, "passed", nil, ms)
						out(string.format("%s  \u{2713} %s (%.0fms)", indent, item.name, ms))
					else
						record(name, "failed", err, ms)
						out(string.format("%s  \u{2717} %s", indent, item.name))
						for line in string.gmatch(tostring(err.message) .. "\n", "(.-)\n") do
							out(indent .. "      " .. line)
						end
						if err.trace and not err.assertion and err.trace ~= "" then
							for line in string.gmatch(err.trace, "[^\n]+") do
								out(indent .. "      " .. line)
							end
						end
					end
				end
			end
		end

		if ranBeforeAll then
			local ok, err = runHooks(suite.afterAll, "afterAll", suite.name)
			if not ok then
				record(fullName(suite, "(afterAll)"), "failed", err, 0)
				out(indent .. "  \u{2717} (afterAll) " .. tostring(err.message))
			end
		end
	end

	if useOnly then
		-- si hay `only`, comprobar que existe de verdad en el arbol
		useOnly = suiteHasOnly(self._root)
	end
	visit(self._root, -1, false, false)

	summary.durationMs = (os.clock() - startClock) * 1000
	out("")
	out(
		string.format(
			"Tests: %d passed, %d failed, %d skipped, %d total (%.0fms)",
			summary.passed,
			summary.failed,
			summary.skipped,
			summary.total,
			summary.durationMs
		)
	)
	if summary.total == 0 then
		out("(aviso) no se registro ningun test")
	end
	self._summary = summary

	local shouldExit = opts.exit
	if shouldExit == nil then
		shouldExit = self._auto == true
	end
	if shouldExit and process then
		process.exit(summary.failed > 0 and 1 or 0)
	end
	return summary
end

-- Ejecucion automatica al terminar el script (solo para el runner por defecto).
function Runner:enableAutoRun()
	self._auto = true
end

return Runner
