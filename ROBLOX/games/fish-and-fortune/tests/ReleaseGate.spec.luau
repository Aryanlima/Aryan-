--!nonstrict
--[[
	PUERTA PREVIA A PUBLICAR (solo corre con la variable de entorno FF_RELEASE_CHECK=1; si no, se omite):

	    FF_RELEASE_CHECK=1 bash tools/test.sh ROBLOX/games/fish-and-fortune/tests/ReleaseGate.spec.luau

	Falla mientras quede algun ID 0 (TODO_ID) en un pase/producto HABILITADO, o un ID repetido.
	Los objetos apagados por flag (Suerte+ y Cebo de Suerte en la v1) pueden quedarse en 0.
]]
local process = require("@lune/process")
local testkit = require("@testkit")
local Balance = require("../src/shared/Balance")
local Catalog = require("../src/server/Catalog")
local FeatureFlags = require("../src/shared/FeatureFlags")
local ProductIds = require("../src/server/ProductIds")
local GameLogic = require("../src/server/GameLogic")
local Economy = require("../../../packages/Economy")
local Odds = require("../../../packages/Odds")
local FishingRules = require("../src/shared/FishingRules")
local Shop = require("../../../packages/Shop")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect
local enabled = process.env.FF_RELEASE_CHECK == "1"
local run = if enabled then it else it.skip

describe("Puerta previa a publicar (FF_RELEASE_CHECK=1)", function()
	run("el catalogo no tiene IDs 0 (TODO_ID) en objetos habilitados ni IDs repetidos", function()
		local logic = GameLogic.new({
			balance = Balance,
			rules = FishingRules.new(Balance, Odds),
			economy = Economy,
			rng = math.random,
			clock = os.clock,
			flags = FeatureFlags,
		})
		local catalog = Catalog.build(ProductIds, Balance, FeatureFlags)
		local problems = Shop.validateCatalog(catalog, logic:shopHandlers(os.time), { allowPlaceholders = false })
		expect(problems).toEqual({})
	end)

	run("el flag de suerte de pago sigue APAGADO en la v1 (cambiarlo es una decision de cumplimiento)", function()
		expect(FeatureFlags.paidLuckEnabled).toBe(false)
	end)
end)
