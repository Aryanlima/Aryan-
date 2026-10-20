--!nonstrict
-- Tests de packages/UI: funciones puras y construccion de paneles con un entorno simulado.
-- El entorno usa la libreria `roblox` de Lune SOLO para validar nombres de propiedades/enums reales
-- (UI.create asigna cada propiedad tambien en una Instance real de Lune dentro de un pcall).
local testkit = require("@testkit")
local Mocks = require("@testkit/mocks")
-- El tipado de @lune/roblox no declara los datatypes (UDim2, Enum...) aunque existen en runtime.
local roblox = require("@lune/roblox") :: any
local UI = require("../packages/UI")
local Odds = require("../packages/Odds")

local describe, it, expect, beforeEach, afterEach =
	testkit.describe, testkit.it, testkit.expect, testkit.beforeEach, testkit.afterEach

describe("UI (funciones puras)", function()
	it("formatNumber abrevia con K/M/B/T y no lanza con valores raros", function()
		expect(UI.formatNumber(0)).toBe("0")
		expect(UI.formatNumber(999)).toBe("999")
		expect(UI.formatNumber(1234)).toBe("1.2K")
		expect(UI.formatNumber(1000)).toBe("1K")
		expect(UI.formatNumber(1500000)).toBe("1.5M")
		expect(UI.formatNumber(2e9)).toBe("2B")
		expect(UI.formatNumber(3.2e12)).toBe("3.2T")
		expect(UI.formatNumber(-1234)).toBe("-1.2K")
		expect(UI.formatNumber(0 / 0)).toBe("0")
		expect(UI.formatNumber(math.huge)).toBe("0")
	end)

	it("formatDuration es exacto (sin redondeos a favor) y cubre minutos, horas y dias", function()
		expect(UI.formatDuration(0)).toBe("0:00")
		expect(UI.formatDuration(75)).toBe("1:15")
		expect(UI.formatDuration(899.9)).toBe("14:59") -- redondea hacia abajo: nunca promete mas tiempo
		expect(UI.formatDuration(3725)).toBe("1:02:05")
		expect(UI.formatDuration(90000)).toBe("1d 1h")
		expect(UI.formatDuration(-5)).toBe("0:00")
		expect(UI.formatDuration(0 / 0)).toBe("0:00")
	end)

	it("priceText marca con ~ los precios aproximados", function()
		expect(UI.priceText({ priceRobux = 199, priceIsApproximate = false } :: any)).toBe("R$ 199")
		expect(UI.priceText({ priceRobux = 199, priceIsApproximate = true } :: any)).toBe("~R$ 199")
		expect(UI.priceText({ priceRobux = nil, priceIsApproximate = true } :: any)).toBe("Precio no disponible")
	end)

	it("el texto del boton de compra es neutro (sin presion)", function()
		local base = { kind = "product", key = "k", name = "n", description = "d", priceIsApproximate = false }
		local available = table.clone(base)
		available.available, available.owned = true, false
		expect(UI.buyButtonText(available)).toBe("Ver compra")
		local owned = table.clone(base)
		owned.available, owned.owned = false, true
		expect(UI.buyButtonText(owned)).toBe("Ya lo tienes")
		local restricted = table.clone(base)
		restricted.available, restricted.owned, restricted.reason = false, false, "restricted"
		expect(UI.buyButtonText(restricted)).toBe("No disponible en tu region")
		-- ningun texto de UI usa lenguaje de urgencia
		local Shop = require("../packages/Shop")
		for _, text in
			{
				UI.buyButtonText(available),
				UI.reasonText("owned"),
				UI.reasonText("unavailable"),
				UI.reasonText("loading"),
				UI.reasonText("restricted"),
				UI.reasonText(nil),
			}
		do
			expect(Shop.findPressureLanguage(text)).toBeNil()
		end
	end)

	it("rarityColorName usa el color de la rareza o el de texto por defecto", function()
		expect(UI.rarityColorName("Mythic")).toBe("Mythic")
		expect(UI.rarityColorName("Desconocida")).toBe("text")
		expect(UI.rarityColorName(nil)).toBe("text")
	end)
end)

describe("UI (construccion con entorno simulado)", function()
	local invalidProperties
	local environment
	local clock

	local methods = {}

	function methods.IsA(self, className)
		return self.ClassName == className or className == "Instance"
	end

	function methods.GetChildren(self)
		return table.clone(self._children)
	end

	function methods.Destroy(self)
		local parent: any = rawget(self, "Parent")
		if parent then
			for i, child in parent._children do
				if child == self then
					table.remove(parent._children, i)
					break
				end
			end
		end
		rawset(self, "Parent", nil)
	end

	local function newFake(className)
		local real = roblox.Instance.new(className)
		local node = { ClassName = className, _props = {}, _children = {}, Activated = Mocks.Signal.new() }
		return setmetatable(node, {
			__newindex = function(t, key, value)
				if key == "Parent" then
					rawset(t, "Parent", value)
					if value ~= nil then
						table.insert(value._children, t)
					end
					return
				end
				local ok, err = pcall(function()
					real[key] = value
				end)
				if not ok then
					table.insert(invalidProperties, className .. "." .. tostring(key) .. ": " .. tostring(err))
				end
				t._props[key] = value
			end,
			__index = function(t, key)
				local method = methods[key]
				if method then
					return method
				end
				return (rawget(t, "_props") :: any)[key]
			end,
		})
	end

	local function findAll(node, predicate, found)
		found = found or {}
		if predicate(node) then
			table.insert(found, node)
		end
		for _, child in node._children do
			findAll(child, predicate, found)
		end
		return found
	end

	beforeEach(function()
		invalidProperties = {}
		clock = Mocks.Clock.new()
		environment = {
			Instance = { new = newFake },
			UDim2 = roblox.UDim2,
			UDim = roblox.UDim,
			Color3 = roblox.Color3,
			Vector2 = roblox.Vector2,
			Enum = roblox.Enum,
			task = clock.task,
		}
		UI.setEnvironment(environment)
	end)

	afterEach(function()
		UI.setEnvironment(nil)
	end)

	local function offers()
		return {
			{
				kind = "pass",
				key = "auto_fish",
				name = "Pesca automatica",
				description = "Pesca sola.",
				priceRobux = 299,
				priceIsApproximate = false,
				available = true,
				owned = false,
			},
			{
				kind = "pass",
				key = "vip",
				name = "VIP",
				description = "Etiqueta VIP.",
				priceRobux = 199,
				priceIsApproximate = true,
				available = true,
				owned = true,
			},
			{
				kind = "product",
				key = "lucky_bait",
				name = "Cebo de suerte",
				description = "15 minutos.",
				priceRobux = 49,
				priceIsApproximate = false,
				available = false,
				reason = "restricted",
				owned = false,
			},
		}
	end

	it("crea el panel de tienda sin propiedades invalidas y con botones grandes", function()
		local parent = newFake("ScreenGui")
		local handle = UI.shopPanel(parent, { offers = offers(), onBuy = function() end })
		expect(invalidProperties).toEqual({})
		local rows = findAll(handle.root, function(node)
			return string.sub(node.Name or "", 1, 5) == "pass_" or string.sub(node.Name or "", 1, 8) == "product_"
		end)
		expect(rows).toHaveLength(3)
		-- todos los botones miden >= 56 px (objetivo tactil)
		local buttons = findAll(handle.root, function(node)
			return node.ClassName == "TextButton"
		end)
		expect(#buttons).toBeGreaterThanOrEqual(4) -- 3 filas + Cerrar
		for _, button in buttons do
			expect(button.Size.Y.Offset).toBeGreaterThanOrEqual(56)
		end
	end)

	it("pulsar 'Ver compra' solicita la compra por clave (el servidor decide)", function()
		local parent = newFake("ScreenGui")
		local clicked = {}
		local handle = UI.shopPanel(parent, {
			offers = offers(),
			onBuy = function(kind, key)
				table.insert(clicked, kind .. ":" .. key)
			end,
		})
		local buyButtons = findAll(handle.root, function(node)
			return node.ClassName == "TextButton" and node.Text == "Ver compra"
		end)
		expect(buyButtons).toHaveLength(1)
		buyButtons[1].Activated:Fire()
		expect(clicked).toEqual({ "pass:auto_fish" })
	end)

	it("las ofertas no disponibles o ya poseidas tienen el boton deshabilitado y sin accion", function()
		local parent = newFake("ScreenGui")
		local clicked = 0
		local handle = UI.shopPanel(parent, {
			offers = offers(),
			onBuy = function()
				clicked += 1
			end,
		})
		local owned = findAll(handle.root, function(node)
			return node.ClassName == "TextButton" and node.Text == "Ya lo tienes"
		end)
		local restricted = findAll(handle.root, function(node)
			return node.ClassName == "TextButton" and node.Text == "No disponible en tu region"
		end)
		expect(owned).toHaveLength(1)
		expect(restricted).toHaveLength(1)
		owned[1].Activated:Fire()
		restricted[1].Activated:Fire()
		expect(clicked).toBe(0)
		expect(owned[1].Active).toBe(false)
	end)

	it("update reemplaza las filas", function()
		local parent = newFake("ScreenGui")
		local handle = UI.shopPanel(parent, { offers = offers(), onBuy = function() end })
		handle.update({ offers()[1] })
		local rows = findAll(handle.root, function(node)
			return string.sub(node.Name or "", 1, 5) == "pass_"
		end)
		expect(rows).toHaveLength(1)
		handle.destroy()
		expect(#parent._children).toBe(0)
		expect(invalidProperties).toEqual({})
	end)

	it("el panel de probabilidades muestra todos los resultados, el total y la nota de pity", function()
		local odds = Odds.new({
			{ id = "minnow", weight = 70, label = "Pececillo", rarity = "Common", value = 5 },
			{ id = "koi", weight = 25, label = "Koi", rarity = "Epic", luckFactor = 1.3, value = 100 },
			{ id = "dragon", weight = 5, label = "Dragon", rarity = "Mythic", luckFactor = 1.6, value = 9000 },
		}, { maxLuck = 10, pity = { rolls = 20, targetIds = { "dragon" }, note = "Garantia cada 20 lanzamientos." } })
		local parent = newFake("ScreenGui")
		local handle = UI.oddsPanel(parent, { view = odds:displayRows({ luck = 4 }) })
		expect(invalidProperties).toEqual({})
		local texts = {}
		for _, node in
			findAll(handle.root, function(n)
				return n.ClassName == "TextLabel"
			end)
		do
			table.insert(texts, node.Text)
		end
		local joined = table.concat(texts, "\n")
		expect(joined).toContain("Pececillo")
		expect(joined).toContain("Koi")
		expect(joined).toContain("Dragon")
		expect(joined).toContain("Total: 100.00%")
		expect(joined).toContain("Garantia cada 20 lanzamientos.")
		expect(joined).toContain("(base ") -- con suerte activa se muestra la columna base
		expect(joined).toContain("suerte activa") -- explicacion del efecto
		-- cada fila de resultado existe una vez
		local rows = findAll(handle.root, function(n)
			return string.sub(n.Name or "", 1, 5) == "Odds_"
		end)
		expect(rows).toHaveLength(3)
	end)

	it("sin suerte activa no hay columna base ni explicacion", function()
		local odds = Odds.new({ { id = "a", weight = 1 }, { id = "b", weight = 1 } })
		local parent = newFake("ScreenGui")
		local handle = UI.oddsPanel(parent, { view = odds:displayRows() })
		local joined = {}
		for _, node in
			findAll(handle.root, function(n)
				return n.ClassName == "TextLabel"
			end)
		do
			table.insert(joined, node.Text)
		end
		local text = table.concat(joined, "\n")
		expect(text).never.toContain("(base ")
		expect(text).toContain("Total: 100.00%")
	end)

	it("toast crea un aviso y lo destruye pasado el tiempo", function()
		local parent = newFake("ScreenGui")
		local toast = UI.toast(parent, "Hola", 2)
		expect(#parent._children).toBe(1)
		expect(toast.Text).toBe("Hola")
		clock:advance(3)
		expect(#parent._children).toBe(0)
		expect(invalidProperties).toEqual({})
	end)
end)
