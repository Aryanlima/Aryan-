--!nonstrict
--[[
	Localizacion de Fish & Fortune: shared/Strings.luau (ES + EN) y su uso en el codigo.

	  * Toda clave existe en TODOS los idiomas, sin textos vacios y con los MISMOS marcadores {nombre} en cada idioma.
	  * Ninguna clave huerfana (que ningun codigo use) ni usada sin definir: se ESCANEAN los archivos fuente en busca de
	    literales de clave. Las claves dinamicas (creature.<id>, rod.<id>, zone.<id>.name...) se cruzan con los datos del juego.
	  * Ningun texto (ES ni EN) usa lenguaje de presion; las descripciones de la tienda no mencionan suerte comprable.
	  * El texto visible no vuelve a escribirse a mano en el codigo del cliente (heuristica sobre literales con varias palabras).
]]
local fs = require("@lune/fs")
local testkit = require("@testkit")
local Balance = require("../src/shared/Balance")
local Catalog = require("../src/server/Catalog")
local ClientLogic = require("../src/shared/ClientLogic")
local FeatureFlags = require("../src/shared/FeatureFlags")
local LiveOpsDefaults = require("../src/server/LiveOpsDefaults")
local Locale = require("../../../packages/Locale")
local ProductIds = require("../src/server/ProductIds")
local Shop = require("../../../packages/Shop")
local Strings = require("../src/shared/Strings")
local UI = require("../../../packages/UI")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect

local HERE = (debug.info(1, "s") :: string):gsub("[^/\\]+$", "")
local GAME = HERE .. "../src/"
local PACKAGES = HERE .. "../../../packages/"

local locale = Locale.new(Strings)
local LANGUAGES = Strings.languages

local function sortedKeys()
	return locale:keys()
end

local function otherVariant(text)
	return if type(text) == "string" then text else text.other
end

local function placeholderSet(text)
	local set = {}
	for _, name in Locale.placeholdersOf(text) do
		set[name] = true
	end
	return set
end

local function sameSet(a, b)
	for name in a do
		if not b[name] then
			return false
		end
	end
	for name in b do
		if not a[name] then
			return false
		end
	end
	return true
end

----------------------------------------------------------------------------
-- Escaneo del codigo fuente
----------------------------------------------------------------------------

local function sourceFiles()
	local files = {}
	for _, folder in { "client", "server", "shared" } do
		for _, name in fs.readDir(GAME .. folder) do
			if string.match(name, "%.luau$") and not (folder == "shared" and name == "Strings.luau") then
				table.insert(files, GAME .. folder .. "/" .. name)
			end
		end
	end
	table.insert(files, PACKAGES .. "UI.luau") -- el paquete UI tambien usa claves (ui.*, shop.title)
	table.sort(files)
	return files
end

-- Quita comentarios (--[[ ]] y --linea) para que no cuenten como uso.
local function stripComments(source)
	local result = string.gsub(source, "%-%-%[%[.-%]%]", "")
	result = string.gsub(result, "%-%-[^\n]*", "")
	return result
end

-- Literales entre comillas dobles (sin escapes ni saltos de linea).
local function stringLiterals(source)
	local list = {}
	for literal in string.gmatch(stripComments(source), '"([^"\\\n]*)"') do
		table.insert(list, literal)
	end
	return list
end

local namespaces = {}
for _, key in sortedKeys() do
	namespaces[string.match(key, "^([%w_]+)%.")] = true
end

-- Literales que parecen una clave de texto: empiezan por un espacio de nombres de Strings y un punto.
local function keyLikeLiterals()
	local exact, prefixes = {}, {}
	for _, path in sourceFiles() do
		for _, literal in stringLiterals(fs.readFile(path)) do
			local namespace = string.match(literal, "^([%w_]+)%.")
			if namespace ~= nil and namespaces[namespace] and not string.find(literal, "%s") then
				if string.sub(literal, -1) == "." then
					prefixes[literal] = path
				else
					exact[literal] = path
				end
			end
		end
	end
	return exact, prefixes
end

-- Claves "familia": las construye el codigo con un prefijo y existen una por cada dato del juego.
local function isFamilyKey(key)
	return string.match(key, "^creature%.")
		or string.match(key, "^rod%.")
		or string.match(key, "^rarity%.")
		or string.match(key, "^zone%.[%w_]+%.name$")
		or string.match(key, "^zone%.[%w_]+%.desc$")
		or string.match(key, "^bestiary%.reward%.")
		or string.match(key, "^pass%.")
		or string.match(key, "^product%.")
		or string.match(key, "^event%.")
		or string.match(key, "^season%.%d+%.name$")
		or string.match(key, "^welcome%.")
		or string.match(key, "^fail%.")
end

local FAMILY_PREFIXES = {
	"creature.",
	"rod.",
	"rarity.",
	"zone.",
	"bestiary.reward.",
	"pass.",
	"product.",
	"event.",
	"season.",
	"welcome.",
	"fail.",
}

local function expectedFamilyKeys()
	local expected = {}
	for _, creature in Balance.creatures do
		expected["creature." .. creature.id] = true
	end
	for _, id in Balance.rodOrder do
		expected["rod." .. id] = true
	end
	for _, rarity in Balance.rarityOrder do
		expected["rarity." .. rarity] = true
	end
	for _, id in Balance.zoneOrder do
		expected["zone." .. id .. ".name"] = true
		expected["zone." .. id .. ".desc"] = true
	end
	for _, reward in Balance.bestiary.rewards do
		expected["bestiary.reward." .. reward.id] = true
	end
	local catalog = Catalog.build(ProductIds, Balance, FeatureFlags)
	for key in catalog.passes do
		expected["pass." .. key .. ".name"] = true
		expected["pass." .. key .. ".desc"] = true
	end
	for key in catalog.products do
		expected["product." .. key .. ".name"] = true
		expected["product." .. key .. ".desc"] = true
	end
	for _, event in LiveOpsDefaults.events do
		expected["event." .. event.id .. ".name"] = true
	end
	expected["season." .. tostring(LiveOpsDefaults.season.id) .. ".name"] = true
	expected["welcome." .. LiveOpsDefaults.welcome.id] = true
	for _, reason in ClientLogic.FAILURE_REASONS do
		expected["fail." .. reason] = true
	end
	return expected
end

----------------------------------------------------------------------------
-- Pruebas
----------------------------------------------------------------------------

describe("Strings: completitud (ES y EN)", function()
	it("EN es el idioma de respaldo (idioma no soportado) y ES y EN estan soportados", function()
		expect(Strings.default).toBe("en")
		expect(table.find(LANGUAGES, "es")).toBeTruthy()
		expect(table.find(LANGUAGES, "en")).toBeTruthy()
	end)

	it("toda clave existe en TODOS los idiomas, sin textos vacios (variantes de plural incluidas)", function()
		local count = 0
		for _, key in sortedKeys() do
			count += 1
			local entry = Strings.entries[key]
			for _, language in LANGUAGES do
				local text = entry[language]
				expect(text ~= nil).toBe(true)
				if text == nil then
					error("falta " .. language .. " en " .. key)
				end
				for _, variant in Locale.variantsOf(text) do
					expect(type(variant)).toBe("string")
					expect(string.match(variant, "%S") ~= nil).toBe(true)
				end
				if type(text) == "table" then
					expect(type(text.other)).toBe("string") -- `other` siempre; `one` es opcional
				end
			end
			for language in entry do
				expect(table.find(LANGUAGES, language) ~= nil).toBe(true) -- ni idiomas no declarados
			end
		end
		expect(count > 150).toBe(true)
	end)

	it("mismos marcadores {nombre} en todos los idiomas (y 'one' solo usa marcadores del 'other')", function()
		for _, key in sortedKeys() do
			local entry = Strings.entries[key]
			local base = placeholderSet(otherVariant(entry.es))
			for _, language in LANGUAGES do
				local text = entry[language]
				expect(sameSet(base, placeholderSet(otherVariant(text)))).toBe(true)
				if type(text) == "table" and text.one ~= nil then
					for name in placeholderSet(text.one) do
						expect(base[name] == true).toBe(true)
					end
				end
				for _, variant in Locale.variantsOf(text) do
					-- llaves sueltas o mal cerradas romperian el formato
					local stripped = string.gsub(variant, "{[%a_][%w_]*}", "")
					expect(string.find(stripped, "[{}]") == nil).toBe(true)
				end
			end
		end
	end)

	it("el EN no es una copia del ES: los textos largos difieren (traduccion real)", function()
		-- Plantillas que son iguales en ambos idiomas a proposito (solo marcadores, signos y la palabra "Premium"/"Total").
		local sameOnPurpose = { ["odds.luck_line"] = true, ["season.premium_line"] = true, ["ui.odds_total"] = true }
		local identical = {}
		for _, key in sortedKeys() do
			local es, en = otherVariant(Strings.entries[key].es), otherVariant(Strings.entries[key].en)
			if es == en and #es > 12 and not string.find(es, "^{") and not sameOnPurpose[key] then
				table.insert(identical, key)
			end
		end
		expect(identical).toEqual({})
	end)

	it("el mensaje 'maxed' (compra de algo ya al maximo) esta en la UI y en los avisos, en ambos idiomas", function()
		for _, language in LANGUAGES do
			expect(locale:raw("fail.maxed", language)).toBeTruthy()
			expect(locale:raw("ui.reason.maxed", language)).toBeTruthy()
		end
	end)
end)

describe("Strings: uso en el codigo (sin claves huerfanas ni sin definir)", function()
	-- OJO: fs.readFile cede el hilo; no se puede llamar al definir la suite (el runner arrancaria antes de registrar las
	-- demas), asi que el escaneo es perezoso y se hace dentro de cada prueba.
	local cachedExact, cachedPrefixes
	local function scan()
		if cachedExact == nil then
			cachedExact, cachedPrefixes = keyLikeLiterals()
		end
		return cachedExact, cachedPrefixes
	end

	it("todo literal de clave que aparece en el codigo esta definido en Strings", function()
		local exact, prefixes = scan()
		local missing = {}
		for literal, path in exact do
			local defined = Strings.entries[literal] ~= nil
			if not defined then
				-- prefijo de una familia sin el punto final ("pass.auto_fish" + ".name")
				for _, key in sortedKeys() do
					if string.sub(key, 1, #literal + 1) == literal .. "." then
						defined = true
						break
					end
				end
			end
			if not defined then
				table.insert(missing, literal .. " (" .. path .. ")")
			end
		end
		table.sort(missing)
		expect(missing).toEqual({})
		for prefix, path in prefixes do
			local any = false
			for _, key in sortedKeys() do
				if string.sub(key, 1, #prefix) == prefix then
					any = true
					break
				end
			end
			if not any then
				error("el prefijo '" .. prefix .. "' (" .. path .. ") no coincide con ninguna clave")
			end
		end
	end)

	it(
		"toda clave de Strings se usa: literal exacto en el codigo o miembro de una familia construida con prefijo",
		function()
			local exact = scan()
			local orphans = {}
			for _, key in sortedKeys() do
				if exact[key] == nil and not isFamilyKey(key) then
					-- ¿la construye el codigo como prefijo + dato? (p. ej. "pass.auto_fish" + ".name")
					local viaPrefix = false
					for literal in exact do
						if string.sub(key, 1, #literal + 1) == literal .. "." then
							viaPrefix = true
						end
					end
					if not viaPrefix then
						table.insert(orphans, key)
					end
				end
			end
			expect(orphans).toEqual({})
		end
	)

	it("las claves familia coinciden EXACTAMENTE con los datos del juego (ni faltan ni sobran)", function()
		local expected = expectedFamilyKeys()
		for key in expected do
			if Strings.entries[key] == nil then
				error("falta la clave " .. key)
			end
		end
		for _, key in sortedKeys() do
			if isFamilyKey(key) and not expected[key] then
				error("clave huerfana (no hay dato que la use): " .. key)
			end
		end
	end)

	it("el codigo construye cada familia con su prefijo (si se borra el uso, la prueba lo avisa)", function()
		local sources = {}
		for _, path in sourceFiles() do
			table.insert(sources, fs.readFile(path))
		end
		local all = table.concat(sources, "\n")
		for _, prefix in FAMILY_PREFIXES do
			expect(string.find(all, '"' .. prefix, 1, true) ~= nil).toBe(true)
		end
	end)

	it("los motivos de rechazo de ClientLogic tienen texto en todos los idiomas", function()
		for _, reason in ClientLogic.FAILURE_REASONS do
			for _, language in LANGUAGES do
				expect(locale:raw("fail." .. reason, language)).toBeTruthy()
			end
		end
	end)

	it("el servidor solo envia mensajes de los prefijos permitidos y todos son validos con sus argumentos", function()
		local toastKeys = 0
		for _, key in sortedKeys() do
			if string.match(key, "^toast%.") or string.match(key, "^banner%.") or string.match(key, "^welcome%.") then
				toastKeys += 1
				local args = {}
				for _, name in Locale.placeholdersOf(otherVariant(Strings.entries[key].es)) do
					args[name] = if name == "item"
							or name == "creature"
							or name == "zone"
						then { key = "creature.minnow" }
						else 1
				end
				expect(locale:message(key, args) ~= nil).toBe(true)
			end
		end
		expect(toastKeys > 15).toBe(true)
		-- las claves internas no se pueden enviar como mensaje
		expect(locale:message("kick.locked")).toBeNil()
		expect(locale:message("hud.coins", { amount = 1 })).toBeNil()
	end)
end)

describe("Strings: honestidad y tono (ES y EN)", function()
	it("ningun texto usa lenguaje de presion ni urgencia", function()
		for _, key in sortedKeys() do
			for _, language in LANGUAGES do
				for _, variant in Locale.variantsOf(Strings.entries[key][language]) do
					expect(Shop.findPressureLanguage(variant)).toBeNil()
				end
			end
		end
	end)

	it("el catalogo del servidor rellena nombre y descripcion en ES y EN, sin marcadores sin sustituir", function()
		for _, language in LANGUAGES do
			local catalog = Catalog.build(ProductIds, Balance, FeatureFlags, locale:translator(language))
			for _, group in { catalog.passes, catalog.products } do
				for key, item in group do
					expect(item.nameKey ~= nil and item.descriptionKey ~= nil).toBe(true)
					expect(item.name ~= item.nameKey).toBe(true)
					expect(item.description ~= item.descriptionKey).toBe(true)
					expect(string.find(item.name, "[{}]") == nil).toBe(true)
					expect(string.find(item.description, "[{}]") == nil).toBe(true)
					expect(Shop.findPressureLanguage(item.name)).toBeNil()
					expect(Shop.findPressureLanguage(item.description)).toBeNil()
					expect(#item.name > 0 and #item.description > 0).toBe(true)
					expect(key).toBe(item.key)
				end
			end
			expect(Shop.validateCatalog(catalog, {
				currency = function() end,
				boost = function() end,
				slots = function() end,
			})).toEqual({})
		end
	end)

	it("los objetos que cambian probabilidades lo dicen en su descripcion (ES: probabilidades, EN: odds)", function()
		expect(locale:format("es", "pass.luck_plus.desc", { points = 3 })).toContain("probabilidades")
		expect(locale:format("en", "pass.luck_plus.desc", { points = 3 })).toContain("odds")
		expect(locale:format("es", "product.lucky_bait_15.desc", { luck = 4, minutes = 15 })).toContain(
			"probabilidades"
		)
		expect(locale:format("en", "product.lucky_bait_15.desc", { luck = 4, minutes = 15 })).toContain("odds")
	end)

	it("v1: lo que se ofrece (sin suerte de pago) no menciona suerte ni probabilidades en ningun idioma", function()
		local words = { es = { "suerte", "probabilidad" }, en = { "luck", "odds", "probabilit" } }
		for _, language in LANGUAGES do
			local catalog = Catalog.build(ProductIds, Balance, FeatureFlags, locale:translator(language))
			for _, group in { catalog.passes, catalog.products } do
				for _, item in group do
					if item.enabled ~= false then
						local text = string.lower(item.name .. " " .. item.description)
						for _, word in words[language] do
							expect(string.find(text, word, 1, true)).toBeNil()
						end
					end
				end
			end
		end
	end)

	it(
		"los textos por defecto de LiveOps (nombres de evento, temporada, bienvenida) coinciden con Strings en ES",
		function()
			for _, event in LiveOpsDefaults.events do
				expect(event.name).toBe(locale:format("es", "event." .. event.id .. ".name"))
			end
			expect(LiveOpsDefaults.season.name).toBe(
				locale:format("es", "season." .. tostring(LiveOpsDefaults.season.id) .. ".name")
			)
			expect(LiveOpsDefaults.welcome.message).toBe(locale:format("es", "welcome." .. LiveOpsDefaults.welcome.id))
		end
	)

	it("el balance ya no lleva textos visibles (solo numeros e ids)", function()
		for _, creature in Balance.creatures do
			expect(creature.name).toBeNil()
		end
		for _, rod in Balance.rods do
			expect(rod.name).toBeNil()
		end
		for _, zone in Balance.zones do
			expect(zone.name).toBeNil()
			expect(zone.description).toBeNil()
		end
		for _, rarity in Balance.rarities do
			expect(rarity.label).toBeNil()
		end
		for _, reward in Balance.bestiary.rewards do
			expect(reward.label).toBeNil()
		end
		expect((Balance.ftue :: { [string]: any }).oddsNote).toBeNil()
	end)

	it("el texto de bienvenida de LiveOps cabe en el limite de mensajes del servidor", function()
		for _, language in LANGUAGES do
			expect(#locale:format(language, "welcome.launch") <= Locale.MAX_STRING_ARG).toBe(true)
		end
	end)
end)

describe("Strings: el texto visible no se escribe a mano en el codigo del cliente", function()
	-- Heuristica: un literal con espacios y al menos dos palabras de letras (p. ej. "Mochila llena") fuera de logs y avisos
	-- de depuracion. Los nombres de clases/propiedades de Roblox no tienen espacios.
	-- Textos que NO ve el jugador: nombre de una pieza del motor, mensajes de depuracion (logs, assert) del programador.
	local developerOnly = { "Right Arm", "TODO_ID", "criatura inexistente" }

	local function isDeveloperOnly(literal)
		for _, fragment in developerOnly do
			if string.find(literal, fragment, 1, true) then
				return true
			end
		end
		return false
	end

	local function offenders(files)
		local found = {}
		for _, path in files do
			local source = stripComments(fs.readFile(path))
			for line in string.gmatch(source, "[^\n]+") do
				if
					not string.find(line, "warn%(")
					and not string.find(line, "print%(")
					and not string.find(line, "error%(")
				then
					for literal in string.gmatch(line, '"([^"\\]*)"') do
						if
							string.match(literal, "%a%a+%s+%a%a+")
							and not string.match(literal, "^[%w_]+%.")
							and not isDeveloperOnly(literal)
						then
							table.insert(found, literal .. " (" .. path .. ")")
						end
					end
				end
			end
		end
		return found
	end

	it("cliente (Hud, Menus, Feedback, Minigame, Main) sin textos escritos a mano", function()
		local files = {}
		for _, name in fs.readDir(GAME .. "client") do
			table.insert(files, GAME .. "client/" .. name)
		end
		table.sort(files)
		expect(offenders(files)).toEqual({})
	end)

	it(
		"servidor (GameService) y logica compartida (ClientLogic, GameLogic) sin textos visibles escritos a mano",
		function()
			expect(offenders({
				GAME .. "server/GameService.luau",
				GAME .. "shared/ClientLogic.luau",
				GAME .. "server/GameLogic.luau",
			})).toEqual({})
		end
	)
end)

describe("Strings: el paquete UI usa el traductor inyectado", function()
	local translator

	local function withTranslator(language, run)
		translator = locale:translator(language)
		UI.setTranslator(translator)
		local ok, err = pcall(run)
		UI.setTranslator(nil)
		if not ok then
			error(err, 0)
		end
	end

	it("precio, motivo y boton de compra se traducen (y 'maxed' tiene texto propio)", function()
		local offer =
			{ priceRobux = 1999, priceIsApproximate = false, available = false, owned = false, reason = "maxed" }
		withTranslator("en", function()
			expect(UI.priceText(offer :: any)).toBe("R$ 1,999")
			expect(UI.priceText({ priceRobux = 99, priceIsApproximate = true } :: any)).toBe("~R$ 99")
			expect(UI.priceText({ priceIsApproximate = true } :: any)).toBe("Price not available")
			expect(UI.buyButtonText(offer :: any)).toBe("You're at the maximum for now")
			expect(UI.buyButtonText({ available = true, owned = false } :: any)).toBe("View item")
			expect(UI.buyButtonText({ available = false, owned = true } :: any)).toBe("Owned")
			expect(UI.reasonText("restricted")).toBe("Not available in your region")
			expect(UI.reasonText("algo-raro")).toBe("Not available")
		end)
		withTranslator("es", function()
			expect(UI.priceText(offer :: any)).toBe("R$ 1.999")
			expect(UI.buyButtonText(offer :: any)).toBe("Ya tienes el máximo acumulado")
			expect(UI.buyButtonText({ available = true, owned = false } :: any)).toBe("Ver compra")
		end)
	end)

	it("sin traductor el paquete sigue funcionando en espanol (por defecto)", function()
		UI.setTranslator(nil)
		expect(UI.buyButtonText({ available = true, owned = false } :: any)).toBe("Ver compra")
		expect(UI.reasonText("maxed")).toBe("Ya tienes el maximo acumulado")
		expect(UI.priceText({ priceRobux = 199, priceIsApproximate = false } :: any)).toBe("R$ 199")
	end)

	it("todas las claves ui.* del paquete tienen texto en Strings (ES y EN)", function()
		local source = fs.readFile(PACKAGES .. "UI.luau")
		local count = 0
		for key in string.gmatch(stripComments(source), '%["([%w_.%-]+)"%]%s*=') do
			count += 1
			for _, language in LANGUAGES do
				expect(locale:raw(key, language)).toBeTruthy()
			end
		end
		expect(count >= 15).toBe(true)
	end)
end)
