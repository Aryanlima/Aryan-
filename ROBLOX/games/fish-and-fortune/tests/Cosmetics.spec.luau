--!nonstrict
-- Cosmeticos de pase (tarea 002): aplican el aspecto y NO dan ventaja de juego.
local testkit = require("@testkit")
local Engine = require("@testkit/engine")
local Balance = require("../src/shared/Balance")
local FishingRules = require("../src/shared/FishingRules")
local GameLogic = require("../src/server/GameLogic")
local Economy = require("../../../packages/Economy")
local Odds = require("../../../packages/Odds")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect
local roblox = Engine.roblox
local HERE = (debug.info(1, "s") :: string):gsub("[^/\\]+$", "")
local Cosmetics = Engine.load(HERE .. "../src/server/Cosmetics.luau", {
	ColorSequence = roblox.ColorSequence,
	NumberSequence = roblox.NumberSequence,
	NumberRange = roblox.NumberRange,
})

local function character()
	local model = roblox.Instance.new("Model")
	local root = roblox.Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Parent = model
	return model, root
end

describe("Cosmetics", function()
	it("Cana Dorada: tine de dorado la cana procedural (Part) y le pone chispas una sola vez", function()
		local rod = roblox.Instance.new("Part")
		Cosmetics.goldenRod(rod)
		Cosmetics.goldenRod(rod)
		expect(rod.Color == Cosmetics.GOLD).toBe(true)
		local sparkles = 0
		for _, child in rod:GetChildren() do
			if child.Name == "GoldSparkles" then
				sparkles += 1
			end
		end
		expect(sparkles).toBe(1)
	end)

	it("Cana Dorada: tambien tine una cana de arte (Model con varias piezas)", function()
		local model = roblox.Instance.new("Model")
		for _ = 1, 2 do
			roblox.Instance.new("MeshPart").Parent = model
		end
		Cosmetics.goldenRod(model)
		for _, part in model:GetChildren() do
			expect(part.Color == Cosmetics.GOLD).toBe(true)
		end
	end)

	it("Estela de Burbujas: se crea entre dos Attachments, no se duplica y se quita con enabled=false", function()
		local model, root = character()
		Cosmetics.bubbleTrail(model, true)
		Cosmetics.bubbleTrail(model, true)
		local trail = root:FindFirstChild(Cosmetics.TRAIL_NAME)
		expect(trail ~= nil).toBe(true)
		expect(trail.Attachment0 ~= nil and trail.Attachment1 ~= nil).toBe(true)
		expect(#root:GetChildren()).toBe(3)
		expect(root:FindFirstChild(Cosmetics.TRAIL_NAME .. "Bubbles", true) ~= nil).toBe(true)
		Cosmetics.bubbleTrail(model, false)
		expect(#root:GetChildren()).toBe(0)
	end)

	it("sin HumanoidRootPart no falla", function()
		Cosmetics.bubbleTrail(roblox.Instance.new("Model"), true)
	end)

	it("los pases cosmeticos no cambian suerte ni monedas", function()
		local logic = GameLogic.new({
			balance = Balance,
			rules = FishingRules.new(Balance, Odds),
			economy = Economy,
			rng = function()
				return 0.5
			end,
			clock = function()
				return 0
			end,
			onTransaction = function() end,
		})
		local data = GameLogic.template()
		local function ctx(passes)
			return { player = nil, passes = passes, events = {}, paidRandomAllowed = true, now = 1_800_000_000 }
		end
		local without, with = ctx({}), ctx({ golden_rod = true, bubble_trail = true })
		expect(logic:coinMultiplier(data, with)).toBe(logic:coinMultiplier(data, without))
		expect((logic:luck(data, with))).toBe((logic:luck(data, without)))
	end)

	it("compra skin con monedas una sola vez y rechaza saldo insuficiente", function()
		local logic = GameLogic.new({
			balance = Balance,
			rules = FishingRules.new(Balance, Odds),
			economy = Economy,
			rng = function()
				return 0.5
			end,
			clock = function()
				return 0
			end,
			onTransaction = function() end,
		})
		local data = GameLogic.template()
		data.wallet.coins = 200000
		local ok = logic:buyRod(data, "cane_sunset")
		expect(ok).toBe(true)
		expect(data.wallet.coins).toBe(0)
		expect(data.ownedRods.cane_sunset).toBe(true)
		expect(logic:buyRod(data, "cane_sunset")).toBe(false)
		data.wallet.coins = 199999
		expect(logic:buyRod(data, "cane_jade")).toBe(false)
		expect(data.wallet.coins).toBe(199999)
		expect(data.rod).toBe("driftwood")
	end)

	it("equipar y quitar skins requiere propiedad y conserva caña base y monedas", function()
		local logic = GameLogic.new({
			balance = Balance,
			rules = FishingRules.new(Balance, Odds),
			economy = Economy,
			rng = function()
				return 0.5
			end,
			clock = function()
				return 0
			end,
			onTransaction = function() end,
		})
		local data = GameLogic.template()
		data.wallet.coins = 123
		local ok = logic:equipRod(data, "cane_sunset")
		expect(ok).toBe(false)
		expect(data.cosmeticRod).toBe("")
		data.ownedRods.cane_sunset = true
		local equipped = logic:equipRod(data, "cane_sunset")
		expect(equipped).toBe(true)
		expect(data.cosmeticRod).toBe("cane_sunset")
		local baseRod = data.rod
		local coins = data.wallet.coins
		local unequipped = logic:equipRod(data, baseRod)
		expect(unequipped).toBe(true)
		expect(data.cosmeticRod).toBe(nil)
		expect(data.rod).toBe(baseRod)
		expect(data.wallet.coins).toBe(coins)
	end)
end)
