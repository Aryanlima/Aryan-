--!nonstrict
--[[
	Estructura del lugar CONSTRUIDO por Rojo (la que vera Roblox Studio), sin abrir Studio.

	Que hace: ejecuta `rojo build default.project.json` (proceso hijo), lee el .rbxl resultante con la libreria
	`@lune/roblox` y comprueba sobre ese arbol de instancias los errores tipicos que, si no, solo aparecen al jugar:

	  (a) los servicios y carpetas esperados existen y contienen EXACTAMENTE los scripts esperados;
	  (b) cada script tiene la clase correcta (Script / LocalScript / ModuleScript), RunContext y Disabled adecuados;
	  (c) cada `require(...)` por instancia del codigo resuelve a un ModuleScript que existe en el arbol (se escanean
	      los fuentes de los scripts construidos y se evaluan las rutas contra el arbol; las que no se saben evaluar
	      FALLAN en vez de ignorarse), y el cliente nunca depende de modulos de servidor ni al reves;
	  (d) no hay nombres duplicados entre hermanos, ni scripts fuera de lo esperado, ni modulos huerfanos;
	  (e) los nombres de remotos de shared/Remotes.luau coinciden con lo que el servidor registra/dispara y con lo que
	      el cliente conecta/envia, y la carpeta de remotos no choca con nada del arbol;
	  (f) el contrato del mundo: se ejecuta WorldBuilder sobre un DataModel real de Lune (propiedades y enums validados
	      por la base de reflexion de Roblox) y se comprueba lo que el cliente busca (Workspace.World/<zona>/CastTarget...);
	  (g) todo `game:GetService("X")` / `Instance.new("X")` escrito con texto literal nombra un servicio / una clase real.

	Requisitos: el binario `rojo` (ROBLOX/.toolchain/bin/rojo, o `rojo` en el PATH; ARYAN_TOOLCHAIN lo cambia). Si no
	esta, las pruebas se OMITEN con un aviso claro (con ARYAN_REQUIRE_ROJO=1 fallan en vez de omitirse).

	Limites (lo que esto NO prueba): replicacion real cliente/servidor, orden real de ejecucion de los scripts,
	streaming, el comportamiento de los servicios reales ni nada de Studio. Ver docs/verificacion-estructura.md.
]]
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox") :: any
local serde = require("@lune/serde")
local testkit = require("@testkit")
-- Todos los `require` van ANTES del primer `describe`: un require de Lune cede el hilo, y el runner de testkit arranca
-- al primer cede tras el primer `describe`, con lo que las suites registradas despues se perderian en silencio.
local Balance = require("../src/shared/Balance")
local Locale = require("../../../packages/Locale")
local Remotes = require("../src/shared/Remotes")
local Strings = require("../src/shared/Strings")
local BuiltPlace = require("./support/BuiltPlace")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect

local HERE = (debug.info(1, "s") :: string):gsub("[^/\\]+$", "")
local PROJECT_FILE = HERE .. "../default.project.json"
local SRC_DIR = HERE .. "../src/"

----------------------------------------------------------------------------
-- Construccion del lugar con rojo (tests/support/BuiltPlace.luau)
----------------------------------------------------------------------------

if BuiltPlace.bytes == nil then
	local message = "[ProjectStructure] " .. tostring(BuiltPlace.problem)
	if BuiltPlace.required then
		describe("Estructura del lugar construido con Rojo", function()
			it("rojo esta disponible y construye el lugar (ARYAN_REQUIRE_ROJO=1)", function()
				error(message, 0)
			end)
		end)
	else
		print("AVISO " .. message .. " -> pruebas de estructura OMITIDAS")
		describe(
			"Estructura del lugar construido con Rojo (OMITIDA: "
				.. string.match(tostring(BuiltPlace.problem), "^[^\n]*") :: string
				.. ")",
			function()
				it.skip("(a)-(g) necesitan el binario rojo", function() end)
			end
		)
	end
	return
end

-- Toda la E/S de disco se hace AQUI, al cargar el archivo (ver el aviso de BuiltPlace sobre las llamadas asincronas).
local PROJECT = serde.decode("json", fs.readFile(PROJECT_FILE))
local WORLD_BUILDER_SOURCE = fs.readFile(SRC_DIR .. "server/WorldBuilder.luau")

local function loadPlace()
	return roblox.deserializePlace(BuiltPlace.bytes)
end

----------------------------------------------------------------------------
-- Utilidades sobre el arbol
----------------------------------------------------------------------------

local place = loadPlace()

-- Devuelve la instancia o nil si algun tramo no existe (anotado `any` para no forzar comprobaciones en cada prueba).
local function find(path: string, root: any?): any
	local current = root or place
	for segment in string.gmatch(path, "[^%.]+") do
		current = current:FindFirstChild(segment)
		if current == nil then
			return nil
		end
	end
	return current
end

local function isScript(instance: any): boolean
	return instance:IsA("LuaSourceContainer")
end

-- Ruta legible "ServerScriptService.Server.Main" (sin el nombre del DataModel).
local function pathOf(instance: any): string
	local parts = {}
	local current = instance
	while current ~= nil and current ~= place do
		table.insert(parts, 1, current.Name)
		current = current.Parent
	end
	return table.concat(parts, ".")
end

local function allScripts(): { any }
	local list = {}
	for _, descendant in place:GetDescendants() do
		if isScript(descendant) then
			table.insert(list, descendant)
		end
	end
	table.sort(list, function(a, b)
		return pathOf(a) < pathOf(b)
	end)
	return list
end

local function readProperty(instance: any, name: string): any
	local ok, value = pcall(function()
		return instance[name]
	end)
	if ok then
		return value
	end
	return nil
end

----------------------------------------------------------------------------
-- (a) + (b) + (d): contenido esperado
----------------------------------------------------------------------------

-- El CONTRATO: carpeta -> { nombre = clase }. Si default.project.json cambia, esta tabla debe cambiar a proposito.
local EXPECTED = {
	["ReplicatedStorage.Packages"] = {
		Odds = "ModuleScript",
		Net = "ModuleScript",
		UI = "ModuleScript",
		Locale = "ModuleScript",
		Art = "ModuleScript",
	},
	["ReplicatedStorage.Shared"] = {
		ArtProfiles = "ModuleScript",
		Balance = "ModuleScript",
		ClientLogic = "ModuleScript",
		FeatureFlags = "ModuleScript",
		FishingRules = "ModuleScript",
		Remotes = "ModuleScript",
		Store = "ModuleScript",
		Strings = "ModuleScript",
	},
	["ServerScriptService.ServerPackages"] = {
		Data = "ModuleScript",
		Economy = "ModuleScript",
		Shop = "ModuleScript",
		LiveOps = "ModuleScript",
		Analytics = "ModuleScript",
	},
	["ServerScriptService.Server"] = {
		Main = "Script",
		GameService = "ModuleScript",
		GameLogic = "ModuleScript",
		Catalog = "ModuleScript",
		ProductIds = "ModuleScript",
		Schema = "ModuleScript",
		WorldBuilder = "ModuleScript",
		StudioMemoryStore = "ModuleScript",
		LiveOpsDefaults = "ModuleScript",
		ArtDirector = "ModuleScript",
	},
	-- Plantillas de arte generado (carpetas vacias en el repo; se llenan con .rbxm o desde Studio). Ver README, seccion Arte.
	["ServerStorage.Art"] = {
		creatures = "Folder",
		rods = "Folder",
		props = "Folder",
	},
	["StarterPlayer.StarterPlayerScripts.Client"] = {
		Main = "LocalScript",
		Feedback = "ModuleScript",
		Hud = "ModuleScript",
		Menus = "ModuleScript",
		Minigame = "ModuleScript",
	},
}

local SERVICES = {
	ReplicatedStorage = "ReplicatedStorage",
	ServerScriptService = "ServerScriptService",
	Workspace = "Workspace",
	Lighting = "Lighting",
	ServerStorage = "ServerStorage",
	["ServerStorage.Art"] = "Folder",
	StarterPlayer = "StarterPlayer",
	["StarterPlayer.StarterPlayerScripts"] = "StarterPlayerScripts",
}

local function sortedKeys(map: { [string]: any }): { string }
	local keys = {}
	for key in map do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end

local function childMap(folder: any): { [string]: string }
	local map = {}
	for _, child in folder:GetChildren() do
		map[child.Name] = child.ClassName
	end
	return map
end

describe("(a) Servicios y carpetas del lugar construido", function()
	for _, path in sortedKeys(SERVICES) do
		it("existe " .. path .. " con la clase " .. SERVICES[path], function()
			local instance = find(path)
			expect(instance ~= nil).toBe(true)
			expect(instance.ClassName).toBe(SERVICES[path])
		end)
	end

	it("el DataModel solo trae los servicios declarados en default.project.json", function()
		local declared = {}
		for name in PROJECT.tree do
			if string.sub(name, 1, 1) ~= "$" then
				declared[name] = true
			end
		end
		for _, child in place:GetChildren() do
			expect(declared[child.Name]).toBe(true)
		end
		for name in declared do
			expect(place:FindFirstChild(name) ~= nil).toBe(true)
		end
	end)

	for _, path in sortedKeys(EXPECTED) do
		it(path .. " contiene exactamente lo esperado (nombres y clases)", function()
			local folder = find(path)
			expect(folder ~= nil).toBe(true)
			expect(childMap(folder)).toEqual(EXPECTED[path])
		end)
	end

	it(
		"los Workspace/Lighting de Rojo no traen instancias (el mundo lo crea WorldBuilder en tiempo de ejecucion)",
		function()
			expect(#find("Workspace"):GetChildren()).toBe(0)
			expect(#find("Lighting"):GetChildren()).toBe(0)
		end
	)
end)

describe("(b) Clase, RunContext y Disabled de cada script", function()
	it("el unico Script esta en ServerScriptService y se ejecuta (Legacy o Server, no Disabled)", function()
		local main = find("ServerScriptService.Server.Main")
		expect(main.ClassName).toBe("Script")
		local runContext = tostring(readProperty(main, "RunContext"))
		expect(runContext == "Enum.RunContext.Legacy" or runContext == "Enum.RunContext.Server").toBe(true)
		expect(readProperty(main, "Disabled")).toBe(false)
	end)

	it("el unico LocalScript esta en StarterPlayerScripts y se ejecuta en el cliente (no Disabled)", function()
		local main = find("StarterPlayer.StarterPlayerScripts.Client.Main")
		expect(main.ClassName).toBe("LocalScript")
		local runContext = tostring(readProperty(main, "RunContext"))
		expect(runContext == "Enum.RunContext.Legacy" or runContext == "Enum.RunContext.Client").toBe(true)
		expect(readProperty(main, "Disabled")).toBe(false)
	end)

	it("hay exactamente 1 Script y 1 LocalScript en todo el lugar (el resto son ModuleScript)", function()
		local counts = { Script = 0, LocalScript = 0, ModuleScript = 0 }
		for _, instance in allScripts() do
			counts[instance.ClassName] = (counts[instance.ClassName] or 0) + 1
		end
		expect(counts.Script).toBe(1)
		expect(counts.LocalScript).toBe(1)
		local expectedModules = 0
		for _, children in EXPECTED do
			for _, className in children do
				if className == "ModuleScript" then
					expectedModules += 1
				end
			end
		end
		expect(counts.ModuleScript).toBe(expectedModules)
	end)

	it("ningun script esta vacio ni sin --!strict (Rojo no mapeo un archivo vacio o equivocado)", function()
		for _, instance in allScripts() do
			local source = instance.Source
			expect(#source > 200).toBe(true)
			if string.sub(source, 1, 9) ~= "--!strict" then
				error(pathOf(instance) .. " no empieza por --!strict")
			end
		end
	end)
end)

describe("(d) Sin duplicados ni scripts fuera de sitio", function()
	it("no hay dos hermanos con el mismo nombre en todo el arbol", function()
		for _, instance in place:GetDescendants() do
			local seen = {}
			for _, child in instance:GetChildren() do
				if seen[child.Name] then
					error("nombre duplicado entre hermanos: " .. pathOf(child))
				end
				seen[child.Name] = true
			end
		end
	end)

	it(
		"todo script esta dentro de una de las carpetas esperadas (nada en ReplicatedStorage/Workspace suelto)",
		function()
			for _, instance in allScripts() do
				local parent = pathOf(instance.Parent)
				if EXPECTED[parent] == nil then
					error(pathOf(instance) .. " esta fuera de las carpetas esperadas")
				end
			end
		end
	)
end)

----------------------------------------------------------------------------
-- (c): evaluacion estatica de los require
----------------------------------------------------------------------------

local function stripComments(source: string): string
	local text = string.gsub(source, "%-%-%[(=*)%[.-%]%1%]", "")
	text = string.gsub(text, "%-%-[^\n]*", "")
	return text
end

-- Evalua una cadena de instancias: raiz (script | game | alias) seguida de .Nombre, .Parent, :WaitForChild("N"),
-- :FindFirstChild("N") o :GetService("N"). Devuelve (instancia | nil, motivo).
local function parseSteps(text: string): ({ any }?, string?)
	local steps = {}
	local rest = text
	while rest ~= "" do
		local childName, after = string.match(rest, '^:WaitForChild%(%s*"([^"]+)"[^%)]*%)(.*)$')
		if childName == nil then
			childName, after = string.match(rest, '^:FindFirstChild%(%s*"([^"]+)"[^%)]*%)(.*)$')
		end
		if childName ~= nil then
			table.insert(steps, { kind = "child", name = childName })
			rest = after
		else
			local serviceName, afterService = string.match(rest, '^:GetService%(%s*"([^"]+)"%s*%)(.*)$')
			if serviceName ~= nil then
				table.insert(steps, { kind = "service", name = serviceName })
				rest = afterService
			else
				local property, afterProperty = string.match(rest, "^%.([%a_][%w_]*)(.*)$")
				if property == nil then
					return nil, "paso no soportado en `" .. rest .. "`"
				end
				if property == "Parent" then
					table.insert(steps, { kind = "parent" })
				else
					table.insert(steps, { kind = "child", name = property })
				end
				rest = afterProperty
			end
		end
	end
	return steps, nil
end

local function parseChain(expression: string): ({ root: string, steps: { any } }?, string?)
	local text = string.gsub(expression, "%s+$", "")
	text = string.gsub(text, "^%s+", "")
	text = string.gsub(text, "%s*::%s*[%w_%.<>%?]+$", "") -- `:: Tipo` al final
	local root, rest = string.match(text, "^([%a_][%w_]*)(.*)$")
	if root == nil then
		return nil, "no es una cadena de instancias: `" .. text .. "`"
	end
	local steps, problem = parseSteps(rest)
	if steps == nil then
		return nil, problem
	end
	return { root = root, steps = steps }, nil
end

-- Alias `local nombre = <cadena>` de un script (ambiguo si se declara dos veces con distinta cadena).
local function collectAliases(source: string): { [string]: any }
	local aliases = {}
	for name, expression in string.gmatch(source, "local%s+([%a_][%w_]*)%s*=%s*([^\n]+)") do
		local chain = parseChain(expression)
		if chain ~= nil then
			local previous = aliases[name]
			if previous ~= nil and previous.expression ~= expression then
				aliases[name] = { ambiguous = true }
			elseif previous == nil then
				aliases[name] = { chain = chain, expression = expression }
			end
		end
	end
	return aliases
end

local function evaluate(chain: any, scriptInstance: any, aliases: { [string]: any }, depth: number): (any?, string?)
	if depth > 8 then
		return nil, "alias demasiado anidado"
	end
	local current
	if chain.root == "script" then
		current = scriptInstance
	elseif chain.root == "game" then
		current = place
	else
		local alias = aliases[chain.root]
		if alias == nil then
			return nil,
				"raiz `" .. chain.root .. "` desconocida (solo script, game o un `local` con cadena de instancias)"
		end
		if alias.ambiguous then
			return nil, "el alias `" .. chain.root .. "` se declara mas de una vez con distinto valor"
		end
		local resolved, problem = evaluate(alias.chain, scriptInstance, aliases, depth + 1)
		if resolved == nil then
			return nil, problem
		end
		current = resolved
	end
	for _, step in chain.steps do
		if step.kind == "parent" then
			current = current.Parent
			if current == nil then
				return nil, "`.Parent` es nil"
			end
		elseif step.kind == "service" then
			if current ~= place then
				return nil, ":GetService solo es valido sobre `game`"
			end
			local service = place:FindFirstChild(step.name)
			if service == nil then
				return nil, "el servicio " .. step.name .. " no esta en el lugar construido"
			end
			current = service
		else
			local child = current:FindFirstChild(step.name)
			if child == nil then
				return nil, "no existe `" .. step.name .. "` dentro de " .. pathOf(current)
			end
			current = child
		end
	end
	return current, nil
end

local function extractRequireArguments(source: string): { string }
	local arguments = {}
	local from = 1
	while true do
		local startIndex, endIndex = string.find(source, "require%s*%(", from)
		if startIndex == nil then
			break
		end
		from = endIndex + 1
		local before = if startIndex > 1 then string.sub(source, startIndex - 1, startIndex - 1) else ""
		if not string.find(before, "[%w_%.:]") then
			local depth, index = 1, endIndex + 1
			while index <= #source and depth > 0 do
				local char = string.sub(source, index, index)
				if char == "(" then
					depth += 1
				elseif char == ")" then
					depth -= 1
				end
				index += 1
			end
			table.insert(arguments, string.sub(source, endIndex + 1, index - 2))
		end
	end
	return arguments
end

-- Para cada script: lista de { argumento, destino | nil, problema | nil }.
local function scanRequires(): { [any]: { any } }
	local result = {}
	for _, instance in allScripts() do
		local source = stripComments(instance.Source)
		local arguments = extractRequireArguments(source)
		if #arguments > 0 then
			local aliases = collectAliases(source)
			local entries = {}
			for _, argument in arguments do
				local entry = { argument = argument }
				local chain, problem = parseChain(argument)
				if chain == nil then
					entry.problem = problem
				else
					entry.target, entry.problem = evaluate(chain, instance, aliases, 0)
				end
				table.insert(entries, entry)
			end
			result[instance] = entries
		end
	end
	return result
end

local requires = scanRequires()

local function closure(rootScript: any): { [any]: boolean }
	local seen = {}
	local queue = { rootScript }
	while #queue > 0 do
		local current = table.remove(queue)
		for _, entry in requires[current] or {} do
			if entry.target ~= nil and not seen[entry.target] then
				seen[entry.target] = true
				table.insert(queue, entry.target)
			end
		end
	end
	return seen
end

describe("(c) require por instancia resueltos contra el arbol construido", function()
	it("el escaneo encuentra los require esperados (solo los dos Main requieren por instancia)", function()
		local owners = {}
		for instance in requires do
			table.insert(owners, pathOf(instance))
		end
		table.sort(owners)
		expect(owners).toEqual({
			"ServerScriptService.Server.Main",
			"StarterPlayer.StarterPlayerScripts.Client.Main",
		})
	end)

	it("cada require resuelve a un ModuleScript que existe (rutas, mayusculas, carpetas)", function()
		local total = 0
		for instance, entries in requires do
			for _, entry in entries do
				total += 1
				if entry.target == nil then
					error(
						pathOf(instance)
							.. ": require("
							.. entry.argument
							.. ") no se pudo resolver: "
							.. tostring(entry.problem)
					)
				end
				if entry.target.ClassName ~= "ModuleScript" then
					error(
						pathOf(instance) .. ": require(" .. entry.argument .. ") apunta a un " .. entry.target.ClassName
					)
				end
			end
		end
		-- cada Main requiere sus modulos uno a uno: hay decenas; 0 significaria que el escaneo no entiende el codigo
		expect(total >= 30).toBe(true)
	end)

	it("el cliente solo depende de modulos que Roblox le replica (ReplicatedStorage y StarterPlayerScripts)", function()
		local clientMain = find("StarterPlayer.StarterPlayerScripts.Client.Main")
		for module in closure(clientMain) do
			local path = pathOf(module)
			local ok = string.sub(path, 1, 18) == "ReplicatedStorage." or string.sub(path, 1, 14) == "StarterPlayer."
			if not ok then
				error("el cliente requiere " .. path .. ", que NO se replica al cliente")
			end
		end
	end)

	it("el servidor no depende de modulos de StarterPlayer (el codigo del cliente no existe alli)", function()
		local serverMain = find("ServerScriptService.Server.Main")
		for module in closure(serverMain) do
			local path = pathOf(module)
			if string.sub(path, 1, 14) == "StarterPlayer." then
				error("el servidor requiere " .. path .. ", que es codigo de cliente")
			end
		end
	end)

	it("los modulos solo-servidor (Data, Economy, Shop, LiveOps, Analytics) no estan al alcance del cliente", function()
		local reachable = closure(find("StarterPlayer.StarterPlayerScripts.Client.Main"))
		for _, name in { "Data", "Economy", "Shop", "LiveOps", "Analytics", "GameService", "GameLogic", "Catalog" } do
			local serverSide = find("ServerScriptService.ServerPackages." .. name)
				or find("ServerScriptService.Server." .. name)
			expect(serverSide ~= nil).toBe(true)
			expect(reachable[serverSide]).toBeNil()
		end
	end)

	it("(d) no hay modulos huerfanos: todo ModuleScript lo requiere algun script", function()
		local required = {}
		for _, entries in requires do
			for _, entry in entries do
				if entry.target ~= nil then
					required[entry.target] = true
				end
			end
		end
		for _, instance in allScripts() do
			if instance.ClassName == "ModuleScript" and not required[instance] then
				error("modulo huerfano (nadie lo requiere): " .. pathOf(instance))
			end
		end
	end)

	it(
		'(d) ningun modulo se requiere desde un Script de otro lado ni por texto (require("...")) que Roblox no resuelve',
		function()
			for instance, entries in requires do
				for _, entry in entries do
					expect(string.find(entry.argument, '^%s*"') == nil).toBe(true)
				end
				expect(instance.ClassName == "Script" or instance.ClassName == "LocalScript").toBe(true)
			end
		end
	)
end)

----------------------------------------------------------------------------
-- (e): remotos
----------------------------------------------------------------------------

local function scanNames(roots: { string }, patterns: { string }): { [string]: number }
	local found = {}
	for _, rootPath in roots do
		for _, instance in find(rootPath):GetDescendants() do
			if isScript(instance) then
				local source = stripComments(instance.Source)
				for _, pattern in patterns do
					for name in string.gmatch(source, pattern) do
						found[name] = (found[name] or 0) + 1
					end
				end
			end
		end
	end
	return found
end

local function asSet(list: { string }): { [string]: boolean }
	local set = {}
	for _, name in list do
		set[name] = true
	end
	return set
end

local function diff(actual: { [string]: any }, expected: { [string]: any }): string
	local extra, missing = {}, {}
	for name in actual do
		if expected[name] == nil then
			table.insert(extra, name)
		end
	end
	for name in expected do
		if actual[name] == nil then
			table.insert(missing, name)
		end
	end
	table.sort(extra)
	table.sort(missing)
	return "sobran: [" .. table.concat(extra, ", ") .. "] faltan: [" .. table.concat(missing, ", ") .. "]"
end

local function sameSet(actual: { [string]: any }, expected: { [string]: any }, label: string)
	local equal = true
	for name in actual do
		equal = equal and expected[name] ~= nil
	end
	for name in expected do
		equal = equal and actual[name] ~= nil
	end
	if not equal then
		error(label .. " no coincide: " .. diff(actual, expected))
	end
end

describe("(e) Remotos: servidor, cliente y shared/Remotes.luau coinciden", function()
	local inbound, outbound = asSet(Remotes.inbound), asSet(Remotes.outbound)
	local serverRoot = { "ServerScriptService.Server" }
	local clientRoot = { "StarterPlayer.StarterPlayerScripts.Client" }

	it("las listas no tienen duplicados, no se mezclan y los nombres son identificadores validos", function()
		expect(#Remotes.inbound).toBe(#sortedKeys(inbound))
		expect(#Remotes.outbound).toBe(#sortedKeys(outbound))
		expect(#Remotes.inbound > 0 and #Remotes.outbound > 0).toBe(true)
		for _, name in Remotes.inbound do
			expect(outbound[name]).toBeNil()
			expect(string.match(name, "^[%a_][%w_]*$") ~= nil).toBe(true)
		end
		for _, name in Remotes.outbound do
			expect(string.match(name, "^[%a_][%w_]*$") ~= nil).toBe(true)
		end
	end)

	it("el servidor registra como entrada EXACTAMENTE los remotos de Remotes.inbound", function()
		local registered = scanNames(serverRoot, { 'net:event%(%s*"([%w_]+)"', 'simpleAction%(%s*"([%w_]+)"' })
		sameSet(
			registered,
			inbound,
			"los remotos registrados por el servidor (net:event / simpleAction) y Remotes.inbound"
		)
		for name, count in registered do
			if count ~= 1 then
				error("el remoto " .. name .. " se registra " .. count .. " veces en el servidor")
			end
		end
	end)

	it("el servidor solo dispara (fireClient / fireAllClients) remotos de salida, y dispara todos", function()
		local fired = scanNames(serverRoot, { 'net:fireClient%(%s*"([%w_]+)"', 'net:fireAllClients%(%s*"([%w_]+)"' })
		sameSet(fired, outbound, "los remotos que dispara el servidor y Remotes.outbound")
	end)

	it("el cliente conecta (onEvent) EXACTAMENTE los remotos de salida", function()
		local connected = scanNames(clientRoot, { 'net:onEvent%(%s*"([%w_]+)"' })
		sameSet(connected, outbound, "los remotos que conecta el cliente (net:onEvent) y Remotes.outbound")
	end)

	it("el cliente solo envia (fire) remotos de entrada, y los usa todos", function()
		local sent = scanNames(clientRoot, { 'net:fire%(%s*"([%w_]+)"' })
		sameSet(sent, inbound, "los remotos que envia el cliente (net:fire) y Remotes.inbound")
	end)

	it("nadie usa net:func / net:invoke (RemoteFunction) sin que esta prueba lo contemple", function()
		local functions = scanNames({ "ServerScriptService.Server", "StarterPlayer.StarterPlayerScripts.Client" }, {
			'net:func%(%s*"([%w_]+)"',
			'net:invoke%(%s*"([%w_]+)"',
		})
		expect(sortedKeys(functions)).toEqual({})
	end)

	it("la carpeta de remotos (Remotes.folderName) no choca con nada de ReplicatedStorage construido", function()
		expect(type(Remotes.folderName)).toBe("string")
		expect(find("ReplicatedStorage"):FindFirstChild(Remotes.folderName)).toBeNil()
		expect(find("Workspace"):FindFirstChild(Remotes.folderName)).toBeNil()
	end)

	it("el servidor crea la carpeta en ReplicatedStorage con ese nombre y el cliente la espera ahi", function()
		local server = stripComments(find("ServerScriptService.Server.GameService").Source)
		expect(string.find(server, "remotesFolder.Name = m.Remotes.folderName", 1, true) ~= nil).toBe(true)
		expect(string.find(server, "remotesFolder.Parent = ReplicatedStorage", 1, true) ~= nil).toBe(true)
		local client = stripComments(find("StarterPlayer.StarterPlayerScripts.Client.Main").Source)
		expect(string.find(client, "ReplicatedStorage:WaitForChild(Remotes.folderName", 1, true) ~= nil).toBe(true)
	end)
end)

----------------------------------------------------------------------------
-- (g): servicios y clases con nombre literal
----------------------------------------------------------------------------

describe("(g) Nombres literales de servicios y clases existen en Roblox", function()
	local database = roblox.getReflectionDatabase()

	local function hasTag(class: any, tag: string): boolean
		for _, candidate in class.Tags do
			if candidate == tag then
				return true
			end
		end
		return false
	end

	it(
		'todo game:GetService("X") literal nombra un servicio real (base de reflexion '
			.. roblox.getReflectionDatabase().Version
			.. ")",
		function()
			local services = scanNames({ "ReplicatedStorage", "ServerScriptService", "StarterPlayer" }, {
				'GetService%(%s*"([%w_]+)"%s*%)',
			})
			expect(next(services) ~= nil).toBe(true)
			for name in services do
				local class = database:GetClass(name)
				if class == nil or not hasTag(class, "Service") then
					error('game:GetService("' .. name .. '") no es un servicio de Roblox')
				end
			end
		end
	)

	it('todo Instance.new("X") literal nombra una clase creable', function()
		local classes = scanNames({ "ReplicatedStorage", "ServerScriptService", "StarterPlayer" }, {
			'Instance%.new%(%s*"([%w_]+)"%s*%)',
			'UI%.create%(%s*"([%w_]+)"',
		})
		expect(next(classes) ~= nil).toBe(true)
		for name in classes do
			local class = database:GetClass(name)
			if class == nil or hasTag(class, "NotCreatable") then
				error('Instance.new("' .. name .. '") no es una clase creable de Roblox')
			end
		end
	end)
end)

----------------------------------------------------------------------------
-- (f): el mundo que construye WorldBuilder vs lo que busca el cliente
----------------------------------------------------------------------------

describe("(f) Contrato del mundo (WorldBuilder sobre un DataModel real de Lune)", function()
	-- Pequeno generador determinista: la clase Random de Roblox no existe en Lune.
	local function newRandom(seed: number?)
		local state = seed or 1
		return {
			NextNumber = function(_self, minimum: number?, maximum: number?): number
				state = (state * 1103515245 + 12345) % 2147483648
				local unit = state / 2147483648
				if minimum ~= nil and maximum ~= nil then
					return minimum + (maximum - minimum) * unit
				end
				return unit
			end,
		}
	end

	local function buildWorld()
		local game = loadPlace()
		local sandbox = table.clone((getfenv :: any)(0))
		sandbox.game = game
		for _, name in { "Instance", "Enum", "Vector3", "Vector2", "Color3", "CFrame", "UDim2", "UDim" } do
			sandbox[name] = roblox[name]
		end
		sandbox.Random = { new = newRandom }
		local chunk = luau.load(WORLD_BUILDER_SOURCE, { environment = sandbox, debugName = "WorldBuilder" })
		local WorldBuilder = chunk()
		local zones = {}
		local spanish = Locale.new(Strings):translator("es")
		for _, zoneId in Balance.zoneOrder do
			table.insert(zones, {
				id = zoneId,
				nameKey = "zone." .. zoneId .. ".name",
				name = spanish("zone." .. zoneId .. ".name"),
			})
		end
		return game, WorldBuilder.build(zones), WorldBuilder
	end

	it(
		"WorldBuilder.build se ejecuta sin errores (propiedades y enums validos segun la base de reflexion de Roblox)",
		function()
			local game, info = buildWorld()
			expect(game:GetService("Workspace"):FindFirstChild("World") ~= nil).toBe(true)
			expect(info ~= nil).toBe(true)
		end
	)

	it(
		"crea Workspace.World/<zona> con Spawn y CastTarget (BasePart) y Sign por cada zona de Balance.zoneOrder",
		function()
			local game, info = buildWorld()
			local world = game:GetService("Workspace"):FindFirstChild("World")
			expect(world.ClassName).toBe("Folder")
			expect(#Balance.zoneOrder > 0).toBe(true)
			for _, zoneId in Balance.zoneOrder do
				local folder = world:FindFirstChild(zoneId)
				expect(folder ~= nil).toBe(true)
				for _, partName in { "Spawn", "CastTarget", "Sign" } do
					local part = folder:FindFirstChild(partName)
					if part == nil or not part:IsA("BasePart") then
						error("Workspace.World." .. zoneId .. "." .. partName .. " no existe o no es BasePart")
					end
				end
				expect(info.spawns[zoneId] ~= nil).toBe(true)
				expect(info.castTargets[zoneId] ~= nil).toBe(true)
			end
			expect(#world:GetChildren()).toBe(#Balance.zoneOrder)
		end
	)

	it("hay una SpawnLocation en Workspace (CharacterAutoLoads necesita donde aparecer)", function()
		local game = buildWorld()
		local spawnLocation = game:GetService("Workspace"):FindFirstChild("SpawnLocation")
		expect(spawnLocation ~= nil).toBe(true)
		expect(spawnLocation.ClassName).toBe("SpawnLocation")
	end)

	it("cada cartel es un TextLabel con el atributo LocaleKey que existe en Strings (ES y EN)", function()
		local game = buildWorld()
		local locale = Locale.new(Strings)
		local labels = 0
		for _, descendant in game:GetService("Workspace"):GetDescendants() do
			if descendant:IsA("TextLabel") then
				labels += 1
				local key = descendant:GetAttribute("LocaleKey")
				expect(type(key)).toBe("string")
				expect(locale:has(key)).toBe(true)
				for _, language in { "es", "en" } do
					expect(locale:translator(language)(key)).never.toBe(key)
				end
			end
		end
		expect(labels).toBe(#Balance.zoneOrder)
	end)

	it("construir dos veces no duplica el mundo (WorldBuilder destruye el anterior)", function()
		local game, _, WorldBuilder = buildWorld()
		local zones = {}
		for _, zoneId in Balance.zoneOrder do
			table.insert(zones, { id = zoneId, nameKey = "zone." .. zoneId .. ".name", name = zoneId })
		end
		WorldBuilder.build(zones)
		local count = 0
		for _, child in game:GetService("Workspace"):GetChildren() do
			if child.Name == "World" then
				count += 1
			end
		end
		expect(count).toBe(1)
	end)
end)
