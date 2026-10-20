--!nonstrict
local testkit = require("@testkit")
local Store = require("../src/shared/Store")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect

describe("Store", function()
	it("guarda el estado, cuando llego y avisa a los suscriptores", function()
		local now = 10
		local store = Store.new(function()
			return now
		end)
		local seen = {}
		store:subscribe(function(state)
			table.insert(seen, state.coins)
		end)
		expect(store:get()).toBeNil()
		now = 12
		store:set({ coins = 5 })
		expect(store:get().coins).toBe(5)
		expect(store:receivedAt()).toBe(12)
		expect(seen).toEqual({ 5 })
	end)

	it("cancelar la suscripcion detiene los avisos", function()
		local store = Store.new(function()
			return 0
		end)
		local count = 0
		local cancel = store:subscribe(function()
			count += 1
		end)
		store:set({})
		cancel()
		store:set({})
		expect(count).toBe(1)
	end)

	it("un suscriptor que falla no impide avisar a los demas", function()
		local store = Store.new(function()
			return 0
		end)
		local ok = false
		store:subscribe(function()
			error("boom")
		end)
		store:subscribe(function()
			ok = true
		end)
		store:set({})
		expect(ok).toBe(true)
	end)
end)
