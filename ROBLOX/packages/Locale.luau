--!strict
--[[
	Locale: localizacion (ES/EN, ampliable) para TODO texto visible al jugador. Logica PURA (sin servicios del motor):
	se prueba con Lune (tests/Locale.spec.luau) y es seguro para el cliente (ReplicatedStorage.Packages).

	Modelo
	  * Los textos viven en UN archivo de datos por juego (en Fish & Fortune: src/shared/Strings.luau) con la forma
	      entries[clave] = { es = "texto", en = "text" }
	    o, con plural, { es = { one = "...", other = "..." }, en = { one = "...", other = "..." } }.
	    Un idioma nuevo es un campo mas en cada entrada (ver el README del juego).
	  * Marcadores `{nombre}`: se sustituyen en UNA sola pasada (el valor sustituido nunca se vuelve a interpretar, asi que
	    un nombre de jugador con llaves no puede inyectar marcadores).
	  * Falta una clave o un idioma => se usa el idioma por defecto del juego (config.default); si tampoco existe, se devuelve la propia clave
	    (visible en desarrollo; las pruebas impiden que ocurra).
	  * Argumentos: numero (se formatea segun el idioma), cadena (se usa tal cual: el llamador la formatea, p. ej. con
	    `compact`) o `{ key = "clave" }` (referencia a OTRO texto, p. ej. el nombre de una criatura; solo prefijos permitidos).
	  * Plural: el argumento `count` (numero) elige entre `one` y `other`.

	Servidor -> cliente: el servidor envia { key, args } y NUNCA texto ya traducido. `sanitizeMessage` valida lo recibido contra
	listas blancas (prefijos de clave permitidos, claves que existen, nombres de argumento que la plantilla declara, tipos y
	longitudes) antes de mostrarlo: un cliente o un servidor desactualizados no pueden mostrar texto arbitrario.

	Idioma del jugador: `resolveLanguage(localeId)` convierte el LocaleId de Roblox ("es-mx", "en-us"...) en un idioma
	soportado; lo desconocido o ausente => idioma por defecto. Leer el LocaleId del motor es cosa del cliente (ver Main.client).

	Numeros: `number` (agrupa miles), `compact` (1.2K / 1,2K) y `percent` (12.34% / 12,34 %) cambian separadores segun el
	idioma pero NUNCA las cifras: el panel de probabilidades muestra los mismos digitos en todos los idiomas.
]]

export type Plural = { one: string?, other: string }
export type Text = string | Plural
export type Entry = { [string]: Text } -- idioma -> texto
export type Entries = { [string]: Entry } -- clave -> entrada
export type Value = number | string | { key: string }
export type Args = { [string]: Value }
export type Translate = (key: string, args: Args?) -> string

export type Config = {
	entries: Entries,
	languages: { string }, -- idiomas soportados (el primero es el de respaldo si no se indica `default`)
	default: string?, -- idioma por defecto y de respaldo
	-- Prefijos de clave que un argumento `{ key = ... }` puede referenciar (evita mostrar claves internas arbitrarias).
	referenceable: { string }?,
	-- Prefijos de clave que el servidor puede enviar como mensaje (toast, banner...).
	messagePrefixes: { string }?,
}

type LocaleData = {
	entries: Entries,
	languages: { string },
	supported: { [string]: boolean },
	default: string,
	referenceable: { string },
	messagePrefixes: { string },
}

local Locale = {}
Locale.__index = Locale
export type Locale = typeof(setmetatable({} :: LocaleData, Locale))

-- Limites de lo que se acepta de un mensaje enviado por el servidor.
Locale.MAX_KEY_LENGTH = 64
Locale.MAX_ARGS = 8
Locale.MAX_STRING_ARG = 300 -- bytes (el texto de bienvenida de LiveOps admite hasta 300)
Locale.MAX_ABS_NUMBER = 1e15

----------------------------------------------------------------------------
-- Utilidades puras
----------------------------------------------------------------------------

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function startsWithAny(text: string, prefixes: { string }): boolean
	for _, prefix in prefixes do
		if string.sub(text, 1, #prefix) == prefix then
			return true
		end
	end
	return false
end

-- Nombres de los marcadores `{nombre}` de una plantilla (sin repetidos, orden alfabetico).
function Locale.placeholdersOf(template: string): { string }
	local seen: { [string]: boolean } = {}
	local names: { string } = {}
	for name in string.gmatch(template, "{([%a_][%w_]*)}") do
		if not seen[name] then
			seen[name] = true
			table.insert(names, name)
		end
	end
	table.sort(names)
	return names
end

-- Todos los textos (variantes de plural incluidas) de un texto.
function Locale.variantsOf(text: Text): { string }
	if type(text) == "string" then
		return { text }
	end
	local list: { string } = {}
	if text.one ~= nil then
		table.insert(list, text.one)
	end
	table.insert(list, text.other)
	return list
end

-- Categoria de plural. ES y EN: solo el 1 exacto es singular. Otro idioma con reglas distintas se anade aqui.
function Locale.pluralCategory(_language: string, count: number): string
	if count == 1 then
		return "one"
	end
	return "other"
end

local DECIMAL_SEPARATOR: { [string]: string } = { es = ",", en = "." }
local GROUP_SEPARATOR: { [string]: string } = { es = ".", en = "," }

local function decimalSeparator(language: string): string
	return DECIMAL_SEPARATOR[language] or "."
end

local function groupSeparator(language: string): string
	return GROUP_SEPARATOR[language] or ","
end

local function groupDigits(integerDigits: string, separator: string): string
	local reversed = string.reverse(integerDigits)
	local grouped = string.gsub(reversed, "(%d%d%d)", "%1" .. separator)
	grouped = string.reverse(grouped)
	if string.sub(grouped, 1, #separator) == separator then
		grouped = string.sub(grouped, #separator + 1)
	end
	return grouped
end

-- 1234567 -> "1,234,567" (EN) / "1.234.567" (ES). Decimales (hasta 2) solo si los hay. No finitos -> "0".
function Locale.formatNumber(language: string, value: number): string
	if not isFinite(value) then
		return "0"
	end
	local sign = if value < 0 then "-" else ""
	local absolute = math.abs(value)
	local text = string.format("%.2f", absolute)
	local integerPart, fraction = string.match(text, "^(%d+)%.(%d+)$")
	if integerPart == nil or fraction == nil then
		return "0"
	end
	fraction = string.gsub(fraction, "0+$", "")
	local result = groupDigits(integerPart, groupSeparator(language))
	if fraction ~= "" then
		result ..= decimalSeparator(language) .. fraction
	end
	return sign .. result
end

-- 999 -> "999", 1234 -> "1.2K" (EN) / "1,2K" (ES), 1500000 -> "1.5M". Mismas cifras, solo cambia el separador decimal.
function Locale.formatCompact(language: string, value: number): string
	if not isFinite(value) then
		return "0"
	end
	local sign = if value < 0 then "-" else ""
	local absolute = math.abs(value)
	local suffixes: { { value: number, suffix: string } } = {
		{ value = 1e12, suffix = "T" },
		{ value = 1e9, suffix = "B" },
		{ value = 1e6, suffix = "M" },
		{ value = 1e3, suffix = "K" },
	}
	for _, entry in suffixes do
		if absolute >= entry.value then
			local text = string.format("%.1f", absolute / entry.value)
			text = string.gsub(text, "%.0$", "")
			text = string.gsub(text, "%.", decimalSeparator(language))
			return sign .. text .. entry.suffix
		end
	end
	return sign .. tostring(math.floor(absolute + 0.5))
end

--[[
	Adapta un porcentaje ya redondeado por Odds ("12.34%") al idioma: ES "12,34 %", EN "12.34%".
	Cambia SOLO el separador decimal y el espacio antes del %; los digitos son exactamente los mismos.
]]
function Locale.formatPercent(language: string, text: string): string
	local converted = string.gsub(text, "(%d)%.(%d)", "%1" .. decimalSeparator(language) .. "%2")
	if language == "es" then
		converted = string.gsub(converted, "%s*%%", " %%")
	end
	return converted
end

----------------------------------------------------------------------------
-- Instancia
----------------------------------------------------------------------------

function Locale.new(config: Config): Locale
	assert(#config.languages > 0, "Locale.new requiere al menos un idioma")
	local supported: { [string]: boolean } = {}
	for _, language in config.languages do
		supported[language] = true
	end
	local default = config.default or config.languages[1]
	assert(supported[default], "Locale.new: el idioma por defecto no esta en la lista de idiomas")
	local data: LocaleData = {
		entries = config.entries,
		languages = table.clone(config.languages),
		supported = supported,
		default = default,
		referenceable = config.referenceable or {},
		messagePrefixes = config.messagePrefixes or {},
	}
	return setmetatable(data, Locale)
end

function Locale.languages(self: Locale): { string }
	return table.clone(self.languages)
end

function Locale.defaultLanguage(self: Locale): string
	return self.default
end

function Locale.isSupported(self: Locale, language: string): boolean
	return self.supported[language] == true
end

--[[
	LocaleId de Roblox -> idioma soportado. Acepta "es-mx", "es_ES", "en-us", "EN"... Lo desconocido, vacio o no-cadena
	devuelve el idioma por defecto del juego (config.default).
]]
function Locale.resolveLanguage(self: Locale, localeId: any): string
	if type(localeId) ~= "string" then
		return self.default
	end
	local language = string.match(string.lower(localeId), "^(%a%a%a?)[%-_]?")
	if language ~= nil and self.supported[language] then
		return language
	end
	return self.default
end

-- true si la clave existe (en el idioma por defecto).
function Locale.has(self: Locale, key: string): boolean
	local entry = self.entries[key]
	return entry ~= nil and entry[self.default] ~= nil
end

function Locale.keys(self: Locale): { string }
	local list: { string } = {}
	for key in self.entries do
		table.insert(list, key)
	end
	table.sort(list)
	return list
end

-- Texto crudo de una clave en un idioma (sin respaldo): para pruebas y herramientas.
function Locale.raw(self: Locale, key: string, language: string): Text?
	local entry = self.entries[key]
	if entry == nil then
		return nil
	end
	return entry[language]
end

function Locale.number(_self: Locale, language: string, value: number): string
	return Locale.formatNumber(language, value)
end

function Locale.compact(_self: Locale, language: string, value: number): string
	return Locale.formatCompact(language, value)
end

function Locale.percent(_self: Locale, language: string, text: string): string
	return Locale.formatPercent(language, text)
end

local function chooseVariant(language: string, text: Text, args: Args?): string
	if type(text) == "string" then
		return text
	end
	local count = if args ~= nil then args.count else nil
	if type(count) == "number" and Locale.pluralCategory(language, count) == "one" and text.one ~= nil then
		return text.one
	end
	return text.other
end

function Locale._lookup(self: Locale, language: string, key: string, args: Args?): string?
	local entry = self.entries[key]
	if entry == nil then
		return nil
	end
	local text = entry[language]
	if text == nil then
		text = entry[self.default]
	end
	if text == nil then
		return nil
	end
	return chooseVariant(language, text, args)
end

function Locale._renderValue(self: Locale, language: string, value: Value): string?
	if type(value) == "number" then
		return Locale.formatNumber(language, value)
	elseif type(value) == "string" then
		return value
	elseif type(value) == "table" then
		local reference = value.key
		if type(reference) == "string" and startsWithAny(reference, self.referenceable) then
			return self:_lookup(language, reference, nil)
		end
	end
	return nil
end

--[[
	Texto de `key` en `language` con los marcadores sustituidos. Nunca lanza.
	Sin clave => clave (visible); sin idioma => idioma por defecto.
]]
function Locale.format(self: Locale, language: string, key: string, args: Args?): string
	local template = self:_lookup(language, key, args)
	if template == nil then
		return key
	end
	local provided: Args = args or {}
	local result = string.gsub(template, "{[%a_][%w_]*}", function(placeholder: string): string
		local value = provided[string.sub(placeholder, 2, -2)]
		if value == nil then
			return placeholder -- se deja el marcador tal cual (se ve el fallo en desarrollo)
		end
		return self:_renderValue(language, value) or placeholder
	end)
	return result
end

-- El texto de `key` en TODOS los idiomas, uno por linea (para lo que se muestra antes de conocer el idioma del jugador).
function Locale.joined(self: Locale, key: string, args: Args?): string
	local lines: { string } = {}
	for _, language in self.languages do
		table.insert(lines, self:format(language, key, args))
	end
	return table.concat(lines, "\n")
end

-- Funcion `t(clave, args)` ligada a un idioma fijo o a una funcion que lo devuelve (se relee en cada llamada).
function Locale.translator(self: Locale, language: string | (() -> string)): Translate
	return function(key: string, args: Args?): string
		local current = if type(language) == "function" then language() else language
		return self:format(current, key, args)
	end
end

----------------------------------------------------------------------------
-- Mensajes servidor -> cliente
----------------------------------------------------------------------------

export type SanitizeOptions = {
	prefixes: { string }?, -- prefijos de clave aceptados (por defecto messagePrefixes)
	lenient: boolean?, -- true: los argumentos que la plantilla no declara se descartan en lugar de rechazar el mensaje
}

local function validString(value: string): boolean
	return #value <= Locale.MAX_STRING_ARG and utf8.len(value) ~= nil
end

--[[
	Valida un mensaje { key, args } construido por el servidor o recibido por el cliente.
	Devuelve (clave, argumentos limpios) o (nil, motivo). Reglas (lista blanca):
	  * la clave empieza por uno de messagePrefixes (o de options.prefixes), mide <= MAX_KEY_LENGTH y existe;
	  * solo pasan los argumentos que la plantilla declara (en cualquier idioma) y `count`; uno de mas rechaza el mensaje
	    (o se descarta con options.lenient, para datos con argumentos compartidos como las ofertas de la tienda);
	  * numeros finitos y acotados; cadenas UTF-8 validas y cortas; referencias `{ key }` con prefijo permitido que existen.
]]
function Locale.sanitizeMessage(self: Locale, message: any, options: SanitizeOptions?): (string?, Args | string)
	if type(message) ~= "table" then
		return nil, "mensaje no es una tabla"
	end
	local key = message.key
	if type(key) ~= "string" or #key > Locale.MAX_KEY_LENGTH or key == "" then
		return nil, "clave invalida"
	end
	local prefixes = if options ~= nil and options.prefixes ~= nil then options.prefixes else self.messagePrefixes
	local lenient = options ~= nil and options.lenient == true
	if not startsWithAny(key, prefixes) then
		return nil, "prefijo de clave no permitido: " .. key
	end
	local entry = self.entries[key]
	if entry == nil or entry[self.default] == nil then
		return nil, "clave desconocida: " .. key
	end
	local declared: { [string]: boolean } = { count = true }
	for _, text in entry do
		for _, variant in Locale.variantsOf(text) do
			for _, name in Locale.placeholdersOf(variant) do
				declared[name] = true
			end
		end
	end
	local clean: Args = {}
	local rawArgs = message.args
	if rawArgs ~= nil then
		if type(rawArgs) ~= "table" then
			return nil, "args no es una tabla"
		end
		local count = 0
		for name, value in rawArgs do
			count += 1
			if count > Locale.MAX_ARGS then
				return nil, "demasiados argumentos"
			end
			if type(name) ~= "string" then
				return nil, "nombre de argumento invalido"
			end
			if not declared[name] then
				if not lenient then
					return nil, "argumento no permitido: " .. name
				end
				continue -- modo permisivo: se descarta el argumento que la plantilla no declara
			end
			if type(value) == "number" then
				if not isFinite(value) or math.abs(value) > Locale.MAX_ABS_NUMBER then
					return nil, "numero fuera de rango en " .. name
				end
				clean[name] = value
			elseif type(value) == "string" then
				if not validString(value) then
					return nil, "cadena invalida en " .. name
				end
				clean[name] = value
			elseif type(value) == "table" then
				local reference = value.key
				if
					type(reference) ~= "string"
					or #reference > Locale.MAX_KEY_LENGTH
					or not startsWithAny(reference, self.referenceable)
					or not self:has(reference)
				then
					return nil, "referencia invalida en " .. name
				end
				clean[name] = { key = reference }
			else
				return nil, "tipo de argumento no permitido en " .. name
			end
		end
	end
	return key, clean
end

--[[
	Construye un mensaje validado para enviarlo por un remoto. El servidor lo usa en lugar de armar tablas a mano: un error de
	programacion (clave inexistente, argumento sobrante) sale en las pruebas y, en produccion, devuelve nil (se descarta).
]]
function Locale.message(self: Locale, key: string, args: Args?): { key: string, args: Args }?
	local cleanKey, cleanArgs = self:sanitizeMessage({ key = key, args = args })
	if cleanKey == nil or type(cleanArgs) ~= "table" then
		return nil
	end
	return { key = cleanKey, args = cleanArgs }
end

return Locale
