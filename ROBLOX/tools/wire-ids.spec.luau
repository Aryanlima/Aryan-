--!nonstrict
--[[
	Lanza las pruebas de Node de wire-ids.mjs, create-items.mjs y publish-place.mjs (ROBLOX/tools/*.test.mjs, `node --test`) desde el runner
	de Lune, para que `bash ROBLOX/tools/test.sh` (y el CI) cubran tambien las herramientas que crean y cablean los IDs.

	Sin Node 20+ la prueba se OMITE con un aviso (con ARYAN_REQUIRE_NODE=1 falla), igual que las pruebas de rojo.
	El proceso se lanza ANTES del primer `describe` (los procesos dentro de un `it` hacen entrar en panico a Lune 0.11).
]]
local fs = require("@lune/fs")
local process = require("@lune/process")
local testkit = require("@testkit")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect

local HERE = (debug.info(1, "s") :: string):gsub("[^/\\]+$", "")
local TEST_FILES = { HERE .. "wire-ids.test.mjs", HERE .. "create-items.test.mjs", HERE .. "publish-place.test.mjs" }

local function tail(text: string, limit: number): string
	return if #text <= limit then text else "[...]" .. string.sub(text, -limit)
end

local function diagnose(exe: string, args: { string }, result: any): string
	local lines = {
		"[wire-ids.spec] node --test FALLO (codigo de salida " .. tostring(result.code) .. ")",
		"  so: " .. process.os .. " | cwd: " .. tostring(process.cwd),
		"  comando: " .. exe .. " " .. table.concat(args, " "),
	}
	for _, file in TEST_FILES do
		table.insert(lines, "  " .. file .. ": " .. (if fs.isFile(file) then "existe" else "NO EXISTE"))
	end
	table.insert(lines, "--- stdout ---\n" .. tail(result.stdout, 6000))
	table.insert(lines, "--- stderr ---\n" .. tail(result.stderr, 6000))
	return table.concat(lines, "\n")
end

-- Devuelve (paso, texto, nodeAusente). El diagnostico tambien se IMPRIME para que se vea aunque el ejecutor lo recorte.
local function run(): (boolean, string, boolean)
	local exe = if process.os == "windows" then "node.exe" else "node"
	local okVersion, version = pcall(process.exec, exe, { "--version" })
	if not okVersion or not version.ok then
		return false, "node no esta instalado", true
	end
	local major = tonumber(string.match(version.stdout, "^v(%d+)")) or 0
	if major < 20 then
		return false, "se necesita Node 20 o superior (hay " .. string.gsub(version.stdout, "%s+", "") .. ")", true
	end
	-- Reportero fijo: desde Node 23 el de por defecto es "spec" ("ℹ fail 0") y no TAP ("# fail 0").
	local args = { "--test", "--test-reporter=tap" }
	for _, file in TEST_FILES do
		table.insert(args, file)
	end
	local ok, result = pcall(process.exec, exe, args)
	if not ok then
		local text = "[wire-ids.spec] no se pudo ejecutar node: " .. tostring(result)
		print(text)
		return false, text, false
	end
	if not result.ok then
		local report = diagnose(exe, args, result)
		print(report)
		return false, report, false
	end
	return true, result.stdout .. result.stderr, false
end

local passed, output, nodeMissing = run()
if nodeMissing and process.env.ARYAN_REQUIRE_NODE ~= "1" then
	print("AVISO: wire-ids.test.mjs omitida: " .. output)
end
local nodeFound = not nodeMissing

describe("wire-ids.mjs, create-items.mjs y publish-place.mjs (pruebas de Node)", function()
	local run_ = if nodeFound or process.env.ARYAN_REQUIRE_NODE == "1" then it else it.skip
	run_("node --test wire-ids/create-items/publish-place .test.mjs pasa completa", function()
		if not passed then
			error("fallaron las pruebas de Node:\n" .. output, 0)
		end
		expect(string.find(output, "# fail 0", 1, true) ~= nil).toBe(true)
		expect(string.find(output, "# pass ", 1, true) ~= nil).toBe(true)
	end)
end)
