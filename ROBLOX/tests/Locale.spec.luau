--!nonstrict
-- Tests de packages/Locale: formato, plural, respaldo a ES, eleccion de idioma, formatos de numero y validacion
-- (lista blanca) de los mensajes que el servidor envia como { key, args }.
local testkit = require("@testkit")
local Locale = require("../packages/Locale")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect

local function newLocale(overrides)
	local config = {
		languages = { "es", "en" },
		default = "es",
		referenceable = { "name." },
		messagePrefixes = { "toast." },
		entries = {
			["toast.hello"] = { es = "Hola {who}", en = "Hello {who}" },
			["toast.sold"] = {
				es = { one = "Vendiste 1 captura por {coins}.", other = "Vendiste {count} capturas por {coins}." },
				en = { one = "Sold 1 catch for {coins}.", other = "Sold {count} catches for {coins}." },
			},
			["toast.only_es"] = { es = "Solo espanol" },
			["toast.ref"] = { es = "Pescaste: {fish}", en = "You caught: {fish}" },
			["toast.plain"] = { es = "Sin argumentos", en = "No arguments" },
			["name.minnow"] = { es = "Pececillo", en = "Minnow" },
			["secret.internal"] = { es = "No referenciable", en = "Not referenceable" },
			["other.thing"] = { es = "Fuera de prefijo", en = "Outside prefix" },
		},
	}
	for key, value in overrides or {} do
		config[key] = value
	end
	return Locale.new(config :: any) -- el literal de pruebas es mas laxo que Config (uniones de texto)
end

describe("Locale: formato", function()
	local locale = newLocale()

	it("sustituye marcadores, formatea numeros segun el idioma y deja las cadenas tal cual", function()
		expect(locale:format("es", "toast.hello", { who = "Ana" })).toBe("Hola Ana")
		expect(locale:format("en", "toast.hello", { who = "Ana" })).toBe("Hello Ana")
		expect(locale:format("en", "toast.hello", { who = 1234567 })).toBe("Hello 1,234,567")
		expect(locale:format("es", "toast.hello", { who = 1234567 })).toBe("Hola 1.234.567")
		expect(locale:format("es", "toast.hello", { who = "1,2K" })).toBe("Hola 1,2K")
	end)

	it("sustituye en UNA sola pasada: un valor con llaves o % no inyecta marcadores ni rompe el formato", function()
		expect(locale:format("en", "toast.hello", { who = "{who}" })).toBe("Hello {who}")
		expect(locale:format("en", "toast.sold", { count = 3, coins = "%1 {count}" })).toBe(
			"Sold 3 catches for %1 {count}."
		)
		expect(locale:format("en", "toast.hello", { who = "100%" })).toBe("Hello 100%")
	end)

	it("plural: count == 1 elige 'one'; el resto 'other'", function()
		expect(locale:format("es", "toast.sold", { count = 1, coins = 50 })).toBe("Vendiste 1 captura por 50.")
		expect(locale:format("es", "toast.sold", { count = 2, coins = 50 })).toBe("Vendiste 2 capturas por 50.")
		expect(locale:format("en", "toast.sold", { count = 1, coins = 50 })).toBe("Sold 1 catch for 50.")
		expect(locale:format("en", "toast.sold", { count = 0, coins = 50 })).toBe("Sold 0 catches for 50.")
		expect(locale:format("en", "toast.sold", { coins = 50 })).toBe("Sold {count} catches for 50.") -- sin count: 'other'
	end)

	it("respaldo: sin el idioma usa ES; sin la clave devuelve la clave; nunca lanza", function()
		expect(locale:format("en", "toast.only_es")).toBe("Solo espanol")
		expect(locale:format("fr", "toast.hello", { who = "Ana" })).toBe("Hola Ana")
		expect(locale:format("es", "no.existe")).toBe("no.existe")
		expect(locale:format("es", "toast.hello")).toBe("Hola {who}") -- argumento ausente: el fallo se ve (las pruebas lo impiden)
		expect(locale:format("es", "toast.hello", { who = { key = "secret.internal" } })).toBe("Hola {who}")
	end)

	it("una referencia { key } inserta otro texto, solo de los prefijos permitidos", function()
		expect(locale:format("en", "toast.ref", { fish = { key = "name.minnow" } })).toBe("You caught: Minnow")
		expect(locale:format("es", "toast.ref", { fish = { key = "name.minnow" } })).toBe("Pescaste: Pececillo")
		expect(locale:format("es", "toast.ref", { fish = { key = "secret.internal" } })).toBe("Pescaste: {fish}")
	end)

	it("translator liga el idioma y, si es una funcion, la relee en cada llamada", function()
		local current = "es"
		local t = locale:translator(function()
			return current
		end)
		expect(t("toast.hello", { who = "Ana" })).toBe("Hola Ana")
		current = "en"
		expect(t("toast.hello", { who = "Ana" })).toBe("Hello Ana")
		expect(locale:translator("en")("toast.plain")).toBe("No arguments")
	end)

	it("joined junta todos los idiomas, uno por linea (expulsiones: no se conoce el idioma)", function()
		expect(locale:joined("toast.plain")).toBe("Sin argumentos\nNo arguments")
	end)

	it("placeholdersOf y variantsOf", function()
		expect(Locale.placeholdersOf("{b} y {a} y {b} {1}")).toEqual({ "a", "b" })
		expect(Locale.variantsOf("x")).toEqual({ "x" })
		expect(Locale.variantsOf({ one = "a", other = "b" })).toEqual({ "a", "b" })
		expect(Locale.variantsOf({ other = "b" })).toEqual({ "b" })
	end)
end)

describe("Locale: idioma del jugador", function()
	local locale = newLocale()

	it("convierte el LocaleId de Roblox en un idioma soportado", function()
		expect(locale:resolveLanguage("es-es")).toBe("es")
		expect(locale:resolveLanguage("es-mx")).toBe("es")
		expect(locale:resolveLanguage("en-us")).toBe("en")
		expect(locale:resolveLanguage("EN_GB")).toBe("en")
		expect(locale:resolveLanguage("en")).toBe("en")
	end)

	it("lo desconocido, vacio o de otro tipo da el idioma por defecto (ES)", function()
		expect(locale:resolveLanguage("fr-fr")).toBe("es")
		expect(locale:resolveLanguage("pt-br")).toBe("es")
		expect(locale:resolveLanguage("zh-cn")).toBe("es")
		expect(locale:resolveLanguage("")).toBe("es")
		expect(locale:resolveLanguage(nil)).toBe("es")
		expect(locale:resolveLanguage(42)).toBe("es")
		expect(locale:resolveLanguage("--")).toBe("es")
	end)

	it("el idioma por defecto sale de la configuracion", function()
		expect(newLocale({ default = "en" }):resolveLanguage("fr-fr")).toBe("en")
		expect(function()
			newLocale({ default = "de" })
		end).toThrow()
	end)
end)

describe("Locale: formatos de numero (las cifras no cambian, solo los separadores)", function()
	it("formatNumber agrupa miles y usa el decimal del idioma", function()
		expect(Locale.formatNumber("en", 0)).toBe("0")
		expect(Locale.formatNumber("en", 999)).toBe("999")
		expect(Locale.formatNumber("en", 1000)).toBe("1,000")
		expect(Locale.formatNumber("es", 1000)).toBe("1.000")
		expect(Locale.formatNumber("en", 1234567)).toBe("1,234,567")
		expect(Locale.formatNumber("es", 1234567)).toBe("1.234.567")
		expect(Locale.formatNumber("en", 0.5)).toBe("0.5")
		expect(Locale.formatNumber("es", 0.5)).toBe("0,5")
		expect(Locale.formatNumber("es", 2.6)).toBe("2,6")
		expect(Locale.formatNumber("en", -1500)).toBe("-1,500")
		expect(Locale.formatNumber("en", 0 / 0)).toBe("0")
		expect(Locale.formatNumber("en", math.huge)).toBe("0")
	end)

	it("compact abrevia con K/M/B/T y cambia solo el separador decimal", function()
		expect(Locale.formatCompact("en", 999)).toBe("999")
		expect(Locale.formatCompact("en", 1234)).toBe("1.2K")
		expect(Locale.formatCompact("es", 1234)).toBe("1,2K")
		expect(Locale.formatCompact("en", 1000)).toBe("1K")
		expect(Locale.formatCompact("es", 1500000)).toBe("1,5M")
		expect(Locale.formatCompact("en", 2e9)).toBe("2B")
		expect(Locale.formatCompact("en", -1234)).toBe("-1.2K")
		expect(Locale.formatCompact("en", 0 / 0)).toBe("0")
	end)

	it("percent adapta '12.34%' al idioma sin tocar un solo digito", function()
		expect(Locale.formatPercent("en", "12.34%")).toBe("12.34%")
		expect(Locale.formatPercent("es", "12.34%")).toBe("12,34 %")
		expect(Locale.formatPercent("es", "100.00%")).toBe("100,00 %")
		expect(Locale.formatPercent("es", "0.04%")).toBe("0,04 %")
		expect(Locale.formatPercent("es", "7%")).toBe("7 %")
		for _, text in { "0.04%", "12.34%", "100.00%", "99.9%" } do
			local digitsOnly = string.gsub(text, "%D", "")
			expect(string.gsub(Locale.formatPercent("es", text), "%D", "")).toBe(digitsOnly)
			expect(string.gsub(Locale.formatPercent("en", text), "%D", "")).toBe(digitsOnly)
		end
	end)
end)

describe("Locale: mensajes servidor -> cliente (lista blanca)", function()
	local locale = newLocale()

	local function reject(message, options)
		local key, reason = locale:sanitizeMessage(message, options)
		expect(key).toBeNil()
		return reason
	end

	it("acepta una clave con prefijo permitido y argumentos declarados por la plantilla", function()
		local key, args = locale:sanitizeMessage({ key = "toast.hello", args = { who = "Ana" } })
		expect(key).toBe("toast.hello")
		expect(args).toEqual({ who = "Ana" })
		local refKey, refArgs = locale:sanitizeMessage({ key = "toast.ref", args = { fish = { key = "name.minnow" } } })
		expect(refKey).toBe("toast.ref")
		expect(refArgs).toEqual({ fish = { key = "name.minnow" } })
		expect(locale:sanitizeMessage({ key = "toast.plain" })).toBe("toast.plain")
		expect(locale:sanitizeMessage({ key = "toast.sold", args = { count = 2, coins = 10 } })).toBe("toast.sold")
	end)

	it("rechaza lo que no es un mensaje valido", function()
		reject(nil)
		reject("toast.hello")
		reject({})
		reject({ key = 5 })
		reject({ key = "" })
		reject({ key = "toast." .. string.rep("x", 100) })
		reject({ key = "toast.hello", args = "texto" })
	end)

	it("rechaza claves fuera de los prefijos permitidos o que no existen", function()
		expect(reject({ key = "other.thing" })).toContain("prefijo")
		expect(reject({ key = "secret.internal" })).toContain("prefijo")
		expect(reject({ key = "toast.no_existe" })).toContain("desconocida")
		-- con otra lista de prefijos si se acepta
		expect(locale:sanitizeMessage({ key = "other.thing" }, { prefixes = { "other." } })).toBe("other.thing")
	end)

	it("rechaza argumentos que la plantilla no declara, de tipo raro o fuera de rango", function()
		reject({ key = "toast.hello", args = { who = "Ana", extra = 1 } })
		reject({ key = "toast.hello", args = { who = true } })
		reject({ key = "toast.hello", args = { who = function() end } })
		reject({ key = "toast.hello", args = { who = 0 / 0 } })
		reject({ key = "toast.hello", args = { who = math.huge } })
		reject({ key = "toast.hello", args = { who = 1e30 } })
		reject({ key = "toast.hello", args = { [1] = "x" } })
		local many = {}
		for index = 1, 12 do
			many["a" .. index] = index
		end
		reject({ key = "toast.hello", args = many })
	end)

	it("rechaza cadenas con UTF-8 invalido o demasiado largas", function()
		reject({ key = "toast.hello", args = { who = "\255\254" } })
		reject({ key = "toast.hello", args = { who = string.rep("a", Locale.MAX_STRING_ARG + 1) } })
		expect(locale:sanitizeMessage({ key = "toast.hello", args = { who = "\u{6F22}\u{5B57}" } })).toBe("toast.hello")
	end)

	it("rechaza referencias a claves fuera de los prefijos referenciables o inexistentes", function()
		reject({ key = "toast.ref", args = { fish = { key = "secret.internal" } } })
		reject({ key = "toast.ref", args = { fish = { key = "name.no_existe" } } })
		reject({ key = "toast.ref", args = { fish = { key = 5 } } })
	end)

	it(
		"modo permisivo: descarta los argumentos no declarados en vez de rechazar (ofertas con argumentos compartidos)",
		function()
			local key, args = locale:sanitizeMessage(
				{ key = "toast.hello", args = { who = "Ana", hours = 6 } },
				{ lenient = true }
			)
			expect(key).toBe("toast.hello")
			expect(args).toEqual({ who = "Ana" })
		end
	)

	it("message() construye un mensaje validado o devuelve nil (el servidor descarta lo invalido)", function()
		expect(locale:message("toast.hello", { who = "Ana" })).toEqual({ key = "toast.hello", args = { who = "Ana" } })
		expect(locale:message("toast.plain")).toEqual({ key = "toast.plain", args = {} })
		expect(locale:message("toast.hello", { nope = 1 })).toBeNil()
		expect(locale:message("toast.no_existe")).toBeNil()
	end)
end)
