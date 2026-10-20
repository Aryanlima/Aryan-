--!nonstrict
--[[
	Lanza las pruebas de Node de wire-ids.mjs, create-items.mjs y publish-place.mjs (ROBLOX/tools/*.test.mjs, `node --test`) desde el runner
	de Lune, para que `bash ROBLOX/tools/test.sh` (y el CI) cubran tambien las herramientas que crean y cablean los IDs.

	Sin Node 20+ la prueba se OMITE con un aviso (con ARYAN_REQUIRE_NODE=1 falla), igual que las pruebas de rojo.
	El proceso se lanza ANTES del primer `describe` (los procesos dentro de un `it` hacen entrar en panico a Lune 0.11).
]]
local process = require("@lune/process")
local testkit = require("@testkit")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect

local HERE = (debug.info(1, "s") :: string):gsub("[^/\\]+$", "")
local TEST_FILES = { HERE .. "wire-ids.test.mjs", HERE .. "create-items.test.mjs", HERE .. "publish-place.test.mjs" }

local function run(): (boolean, string)
	local exe = if process.os == "windows" then "node.exe" else "node"
	local okVersion, version = pcall(process.exec, exe, { "--version" })
	if not okVersion or not version.ok then
		return false, "node no esta instalado"
	end
	local major = tonumber(string.match(version.stdout, "^v(%d+)")) or 0
	if major < 20 then
		return false, "se necesita Node 20 o superior (hay " .. string.gsub(version.stdout, "%s+", "") .. ")"
	end
	local args = { "--test" }
	for _, file in TEST_FILES do
		table.insert(args, file)
	end
	local ok, result = pcall(process.exec, exe, args)
	if not ok then
		return false, "no se pudo ejecutar node: " .. tostring(result)
	end
	return result.ok, result.stdout .. result.stderr
end

local nodeFound = true
local passed, output = run()
if
	not passed and (string.find(output, "node no esta instalado", 1, true) or string.find(output, "Node 20", 1, true))
then
	nodeFound = false
	if process.env.ARYAN_REQUIRE_NODE ~= "1" then
		print("AVISO: wire-ids.test.mjs omitida: " .. output)
	end
end

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
