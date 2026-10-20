--!nonstrict
-- StudioMemoryStore: debe comportarse como un DataStore para packages/Data (carga, guardado, bloqueo de sesion).
local testkit = require("@testkit")
local StudioMemoryStore = require("../src/server/StudioMemoryStore")
local Data = require("../../../packages/Data")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect

describe("StudioMemoryStore", function()
	it("UpdateAsync recibe una copia, guarda lo devuelto y devolver nil cancela", function()
		local store = StudioMemoryStore.new()
		store:UpdateAsync("k", function(old)
			expect(old).toBeNil()
			return { n = 1 }
		end)
		local result = store:UpdateAsync("k", function(old)
			old.n += 1 -- modificar la copia no debe tocar el original hasta devolverlo
			return old
		end)
		expect(result.n).toBe(2)
		store:UpdateAsync("k", function()
			return nil -- cancela
		end)
		local value = store:GetAsync("k")
		expect(value.n).toBe(2)
	end)

	it("no comparte referencias con lo guardado", function()
		local store = StudioMemoryStore.new()
		local mine = { list = { 1, 2 } }
		store:UpdateAsync("k", function()
			return mine
		end)
		mine.list[1] = 99
		expect(store:GetAsync("k").list[1]).toBe(1)
	end)

	it("sirve de almacen para Data: carga, guarda, libera y bloquea a otro servidor", function()
		local store = StudioMemoryStore.new()
		local clock = 1000
		local function manager(jobId)
			return Data.new({
				dataStore = store,
				schema = { version = 1, template = { coins = 0 } },
				jobId = jobId,
				now = function()
					return clock
				end,
				task = {
					wait = function(seconds)
						clock += seconds
					end,
					spawn = function(fn, ...)
						return coroutine.wrap(fn)(...)
					end,
				},
				random = function()
					return 0
				end,
				log = function() end,
				lock = { staleSeconds = 600, waitSeconds = 4, pollSeconds = 2 },
			})
		end
		local a, b = manager("A"), manager("B")
		local profile = a:load(7)
		profile.data.coins = 12
		profile:markDirty()
		expect(profile:save()).toBe(true)
		local blocked, reason = b:load(7)
		expect(blocked).toBeNil()
		expect(reason).toBe("locked")
		expect(profile:release()).toBe(true)
		expect(b:load(7).data.coins).toBe(12)
	end)
end)
