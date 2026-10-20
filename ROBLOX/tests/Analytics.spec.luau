--!nonstrict
-- Tests de packages/Analytics: envoltorio de AnalyticsService (no-op, validacion, limites, dedupe).
local testkit = require("@testkit")
local Analytics = require("../packages/Analytics")

local describe, it, expect, beforeEach = testkit.describe, testkit.it, testkit.expect, testkit.beforeEach

describe("Analytics", function()
	local calls, service, enums, logs, analytics
	local player = { UserId = 7 }

	beforeEach(function()
		calls = {}
		logs = {}
		local function recorder(name)
			return function(_, ...)
				table.insert(calls, { name = name, args = table.pack(...) })
			end
		end
		service = {
			LogEconomyEvent = recorder("LogEconomyEvent"),
			LogFunnelStepEvent = recorder("LogFunnelStepEvent"),
			LogOnboardingFunnelStepEvent = recorder("LogOnboardingFunnelStepEvent"),
			LogCustomEvent = recorder("LogCustomEvent"),
		}
		enums = { AnalyticsEconomyFlowType = { Source = "ENUM_SOURCE", Sink = "ENUM_SINK" } }
		analytics = Analytics.new({
			service = service,
			enums = enums,
			log = function(m)
				table.insert(logs, m)
			end,
		})
	end)

	it("sin servicio todo es no-op y no lanza", function()
		local noop = Analytics.noop()
		noop:economy(player, "Source", "coins", 1, 1, "Gameplay")
		noop:ftue(player, 1)
		noop:funnel(player, "shop", 1)
		noop:custom(player, "x")
		expect(#calls).toBe(0)
	end)

	it("economy: traduce flow al enum y pasa los argumentos en el orden oficial", function()
		analytics:economy(player, "Source", "coins", 50, 150, "Gameplay", "fish_sale")
		analytics:economy(player, "Sink", "coins", 20, 130, "Shop", "rod_reed")
		expect(calls).toHaveLength(2)
		expect(calls[1].name).toBe("LogEconomyEvent")
		expect(calls[1].args[1]).toBe(player)
		expect(calls[1].args[2]).toBe("ENUM_SOURCE")
		expect(calls[1].args[3]).toBe("coins")
		expect(calls[1].args[4]).toBe(50)
		expect(calls[1].args[5]).toBe(150)
		expect(calls[1].args[6]).toBe("Gameplay")
		expect(calls[1].args[7]).toBe("fish_sale")
		expect(calls[2].args[2]).toBe("ENUM_SINK")
	end)

	it("economy: descarta cantidades invalidas y flows desconocidos", function()
		analytics:economy(player, "Source", "coins", 0, 10, "Gameplay")
		analytics:economy(player, "Source", "coins", -5, 10, "Gameplay")
		analytics:economy(player, "Source", "coins", 0 / 0, 10, "Gameplay")
		analytics:economy(player, "Source", "coins", 5, -1, "Gameplay")
		analytics:economy(player, "Source", "coins", 5, math.huge, "Gameplay")
		analytics:economy(player, "Gain", "coins", 5, 5, "Gameplay")
		expect(#calls).toBe(0)
	end)

	it("economy: respeta los limites (5 monedas, 20 transacciones, 100 SKUs)", function()
		for i = 1, 7 do
			analytics:economy(player, "Source", "cur" .. i, 1, 1, "Gameplay")
		end
		expect(#calls).toBe(5)
		calls = {}
		for i = 1, 25 do
			analytics:economy(player, "Source", "cur1", 1, 1, "tx" .. i)
		end
		expect(#calls).toBe(19) -- "Gameplay" (de las monedas) ya ocupaba uno de los 20 tipos
		calls = {}
		for i = 1, 110 do
			analytics:economy(player, "Source", "cur1", 1, 1, "tx1", "sku" .. i)
		end
		expect(#calls).toBe(110) -- el evento se envia igualmente...
		expect(calls[101].args[7]).toBeNil() -- ...pero sin SKU a partir del 101
		expect(calls[100].args[7]).toBe("sku100")
		expect(table.concat(logs, "\n")).toContain("limite de")
	end)

	it("ftue: cada paso se envia una sola vez por jugador y sesion", function()
		analytics:ftue(player, 1, "joined")
		analytics:ftue(player, 1, "joined")
		analytics:ftue(player, 2, "first_cast")
		analytics:ftue({ UserId = 8 }, 1, "joined")
		expect(calls).toHaveLength(3)
		expect(calls[1].name).toBe("LogOnboardingFunnelStepEvent")
		expect(calls[2].args[2]).toBe(2)
		analytics:forget(player)
		analytics:ftue(player, 1, "joined") -- tras olvidar, vuelve a contar (otra sesion)
		expect(calls).toHaveLength(4)
	end)

	it("ftue: ignora pasos fuera de 1..100 o no enteros", function()
		for _, step in { 0, 101, 1.5, -1, 0 / 0 } do
			analytics:ftue(player, step)
		end
		expect(#calls).toBe(0)
	end)

	it("funnel: pasa nombre, sesion, paso y nombre del paso; limita a 10 embudos", function()
		analytics:funnel(player, "shop", 2, "view_item", "sess-1")
		expect(calls[1].name).toBe("LogFunnelStepEvent")
		expect(calls[1].args[2]).toBe("shop")
		expect(calls[1].args[3]).toBe("sess-1")
		expect(calls[1].args[4]).toBe(2)
		expect(calls[1].args[5]).toBe("view_item")
		for i = 1, 12 do
			analytics:funnel(player, "f" .. i, 1)
		end
		expect(#calls).toBe(1 + 9) -- "shop" + 9 mas = 10 embudos
	end)

	it("custom: valor por defecto 1, campos opcionales y limite de 100 eventos", function()
		analytics:custom(player, "mythic_caught")
		expect(calls[1].args[3]).toBe(1)
		analytics:custom(player, "codes", 3, { CustomField01 = "x" })
		expect(calls[2].args[3]).toBe(3)
		expect(calls[2].args[4]).toEqual({ CustomField01 = "x" })
		analytics:custom(player, "bad", 0 / 0)
		analytics:custom(player, "", 1)
		expect(#calls).toBe(2)
		for i = 1, 110 do
			analytics:custom(player, "evt" .. i)
		end
		expect(#calls).toBe(2 + 98) -- 100 nombres distintos como maximo
	end)

	it("un error del servicio no se propaga (se avisa una sola vez)", function()
		service.LogCustomEvent = function()
			error("API caida")
		end
		analytics:custom(player, "a")
		analytics:custom(player, "b")
		expect(#logs).toBe(1)
		expect(logs[1]).toContain("LogCustomEvent fallo")
	end)

	it("sin Enum disponible no envia economia (y avisa)", function()
		local bare = Analytics.new({
			service = service,
			log = function(m)
				table.insert(logs, m)
			end,
		})
		bare:economy(player, "Source", "coins", 1, 1, "Gameplay")
		expect(#calls).toBe(0)
		expect(table.concat(logs, "\n")).toContain("AnalyticsEconomyFlowType")
	end)
end)
