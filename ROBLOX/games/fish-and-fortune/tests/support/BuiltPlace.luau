--!nonstrict
--[[
	BuiltPlace: construye el lugar de Fish & Fortune con `rojo build` y devuelve su contenido (bytes del .rbxl).

	  local BuiltPlace = require("./support/BuiltPlace")
	  if BuiltPlace.bytes == nil then ... BuiltPlace.problem explica por que (no hay rojo, fallo el build) ...
	  local game = require("@lune/roblox").deserializePlace(BuiltPlace.bytes)

	IMPORTANTE (testkit/Lune): hacer el `require` de este modulo ANTES del primer `describe` del spec. Construir el lugar
	usa procesos y disco (llamadas asincronas de Lune que ceden el hilo) y el runner de testkit arranca en el primer cede
	posterior a un `describe`; ademas, las llamadas asincronas dentro de un `it` hacen entrar en panico a Lune 0.11.

	Busca `rojo` en ROBLOX/.toolchain/bin (o en ARYAN_TOOLCHAIN) y luego en el PATH. El .rbxl intermedio se borra enseguida.
]]
local fs = require("@lune/fs")
local process = require("@lune/process")

local HERE = (debug.info(1, "s") :: string):gsub("[^/\\]+$", "")
local PROJECT_FILE = HERE .. "../../default.project.json"
local TOOLCHAIN = process.env.ARYAN_TOOLCHAIN or (HERE .. "../../../../.toolchain")
local BUILD_DIR = TOOLCHAIN .. "/build"

local function probe(program: string): boolean
	local ok, result = pcall(process.exec, program, { "--version" })
	return ok and result.ok
end

local function findRojo(): string?
	local exe = if process.os == "windows" then "rojo.exe" else "rojo"
	for _, candidate in { TOOLCHAIN .. "/bin/" .. exe, "rojo" } do
		if probe(candidate) then
			return candidate
		end
	end
	return nil
end

local function build(): (string?, string?)
	local rojo = findRojo()
	if rojo == nil then
		return nil, "no se encontro el binario rojo (bash ROBLOX/tools/setup.sh lo instala en ROBLOX/.toolchain/bin)"
	end
	pcall(fs.writeDir, BUILD_DIR)
	local output = BUILD_DIR .. "/FishAndFortune.test-" .. tostring(process.env.USER or "run") .. ".rbxl"
	local ok, result = pcall(process.exec, rojo, { "build", PROJECT_FILE, "--output", output })
	if not ok then
		return nil, "no se pudo ejecutar rojo: " .. tostring(result)
	end
	if not result.ok then
		return nil, "rojo build fallo:\n" .. result.stdout .. result.stderr
	end
	local bytes = fs.readFile(output)
	pcall(fs.removeFile, output)
	return bytes, nil
end

local bytes, problem = build()

return {
	bytes = bytes :: string?,
	problem = problem :: string?,
	-- true si ARYAN_REQUIRE_ROJO=1: en vez de omitir las pruebas por falta de rojo, deben fallar.
	required = process.env.ARYAN_REQUIRE_ROJO == "1",
}
