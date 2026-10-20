--!nonstrict
--[[
	ArtDirector: la cana en la mano y el escaparate de capturas con arte generado (y sin el: nada cambia).
	Usa el proveedor REAL (packages/Art) sobre instancias de Lune.
]]
local testkit = require("@testkit")
local Engine = require("@testkit/engine")
local Balance = require("../src/shared/Balance")

local describe, it, expect, beforeEach = testkit.describe, testkit.it, testkit.expect, testkit.beforeEach

local HERE = (debug.info(1, "s") :: string):gsub("[^/\\]+$", "")
local Art = Engine.load(HERE .. "../../../packages/Art.luau")
local ArtProfiles = Engine.load(HERE .. "../src/shared/ArtProfiles.luau")
local ArtDirector = Engine.load(HERE .. "../src/server/ArtDirector.luau")
local Instance, Vector3, CFrame = Engine.roblox.Instance, Engine.roblox.Vector3, Engine.roblox.CFrame

local function model(id, size, position)
	local m = Instance.new("Model")
	m.Name = id
	local body = Instance.new("MeshPart")
	body.Name = "Body"
	body.Size = size or Vector3.new(1, 1, 5)
	body.MeshId = "rbxassetid://777"
	body.CFrame = CFrame.new(position or Vector3.new(0, 0, 0))
	body.Parent = m
	return m
end

local function put(root, category, template)
	local folder = root:FindFirstChild(category)
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = category
		folder.Parent = root
	end
	template.Parent = folder
	return template
end

local function countClass(root, className)
	local n = 0
	for _, d in root:GetDescendants() do
		if d:IsA(className) then
			n += 1
		end
	end
	return n
end

local root, container, logs, queue, debrisItems, now, director, provider

local function newDirector(showcaseOverrides)
	local showcase = table.clone(ArtProfiles.showcase)
	for key, value in showcaseOverrides or {} do
		showcase[key] = value
	end
	provider = Art.new({ roots = { root }, profiles = ArtProfiles.build(Balance) })
	return ArtDirector.create({
		provider = provider,
		rarityOrder = function(rarity)
			local info = Balance.rarities[rarity]
			return info and info.order
		end,
		container = container,
		showcase = showcase,
		debris = {
			AddItem = function(_self, item, lifetime)
				table.insert(debrisItems, { item = item, lifetime = lifetime })
			end,
		},
		clock = function()
			return now
		end,
		spawn = function(callback)
			table.insert(queue, callback)
			return nil
		end,
		wait = function()
			return 0
		end,
		log = function(message)
			table.insert(logs, message)
		end,
	})
end

local function character()
	local c = Instance.new("Model")
	c.Name = "Character"
	local hand = Instance.new("Part")
	hand.Name = "RightHand"
	hand.Size = Vector3.new(1, 1, 1)
	hand.CFrame = CFrame.new(5, 3, 5)
	hand.Parent = c
	return c, hand
end

local function runQueue()
	local pending = queue
	queue = {}
	for _, callback in pending do
		callback()
	end
end

beforeEach(function()
	root = Instance.new("Folder")
	container = Instance.new("Folder")
	logs, queue, debrisItems, now = {}, {}, {}, 100
	director = newDirector()
end)

describe("ArtDirector.attachRod", function()
	it("SIN arte: devuelve false y no toca el personaje (GameService usa su cana procedural)", function()
		local c, hand = character()
		expect(director.attachRod("golden", hand, c)).toBe(false)
		expect(#c:GetChildren()).toBe(1) -- solo la mano
	end)

	it(
		"CON arte: cana de arte llamada FishingRod, sin anclar, soldada a la mano y a escala de la cana (largo 5)",
		function()
			put(root, "rods", model("golden", Vector3.new(2, 2, 20))) -- generada demasiado grande: se escala a 5 de largo
			local c, hand = character()
			expect(director.attachRod("golden", hand, c)).toBe(true)
			local rod = c:FindFirstChild("FishingRod")
			expect(rod ~= nil).toBe(true)
			expect(rod.ClassName).toBe("Model")
			local _, size = Art.bounds(rod)
			expect(math.abs(size.Z - 5) < 1e-3).toBe(true)
			local primary = rod.PrimaryPart
			expect(primary.Anchored).toBe(false)
			expect(primary.Massless).toBe(true)
			expect(primary.CanCollide).toBe(false)
			-- soldadura mano -> cana
			local welds = {}
			for _, d in c:GetDescendants() do
				if d:IsA("WeldConstraint") then
					table.insert(welds, d)
				end
			end
			expect(#welds).toBe(1)
			expect(welds[1].Part0).toBe(hand)
			expect(welds[1].Part1).toBe(primary)
			-- el mango (cara trasera) queda en la mano: 0,3 por delante en -Z y 0,4 por debajo
			local handPosition = hand.CFrame.Position
			expect(math.abs(primary.CFrame.Position.Z - (handPosition.Z + 0.3 - 2.5)) < 1e-3).toBe(true)
			expect(math.abs(primary.CFrame.Position.Y - (handPosition.Y - 0.4)) < 1e-3).toBe(true)
		end
	)

	it("CON arte INVALIDO (script dentro): false, no entra nada del asset y se avisa por el proveedor", function()
		local malo = model("carbon")
		Instance.new("Script").Parent = malo
		put(root, "rods", malo)
		local c, hand = character()
		expect(director.attachRod("carbon", hand, c)).toBe(false)
		expect(#c:GetChildren()).toBe(1)
		expect(countClass(c, "Script")).toBe(0)
	end)

	it("cambiar de cana no deja dos: el llamador destruye la anterior y se vuelve a colocar", function()
		put(root, "rods", model("golden"))
		local c, hand = character()
		expect(director.attachRod("golden", hand, c)).toBe(true)
		c:FindFirstChild("FishingRod"):Destroy()
		expect(director.attachRod("golden", hand, c)).toBe(true)
		local rods = 0
		for _, child in c:GetChildren() do
			if child.Name == "FishingRod" then
				rods += 1
			end
		end
		expect(rods).toBe(1)
	end)
end)

describe("ArtDirector.showCatch (escaparate de capturas)", function()
	local function info(overrides)
		local i = {
			zone = "lake",
			creatureId = "lake_spirit",
			rarity = "Mythic",
			position = Vector3.new(0, 0.9, -52),
			auto = false,
		}
		for key, value in overrides or {} do
			i[key] = value
		end
		return i
	end

	it("SIN arte de esa criatura: no muestra nada ni consume el enfriamiento", function()
		expect(director.showCatch(info())).toBe(false)
		expect(#container:GetChildren()).toBe(0)
		expect(#debrisItems).toBe(0)
		-- el enfriamiento no se consumio: una criatura CON arte se muestra de inmediato
		put(root, "creatures", model("river_queen", Vector3.new(3, 3.6, 9)))
		expect(director.showCatch(info({ creatureId = "river_queen", zone = "lake" }))).toBe(true)
	end)

	it(
		"CON arte: aparece CatchShowcase sobre el punto de lanzamiento, mirando al muelle, y se programa su retirada",
		function()
			put(root, "creatures", model("lake_spirit", Vector3.new(7, 8, 20)))
			expect(director.showCatch(info())).toBe(true)
			local shown = container:FindFirstChild("CatchShowcase")
			expect(shown ~= nil).toBe(true)
			local center, size = Art.bounds(shown)
			-- escalado a la caja del Mitico (3,5 x 4 x 10) y centrado a 3 studs sobre el punto de lanzamiento
			expect(math.abs(size.Z - 10) < 1e-3 or math.abs(size.Y - 4) < 1e-3 or math.abs(size.X - 3.5) < 1e-3).toBe(
				true
			)
			expect(math.abs(center.X - 0) < 1e-3).toBe(true)
			expect(math.abs(center.Y - (0.9 + ArtProfiles.showcase.height)) < 1e-3).toBe(true)
			expect(math.abs(center.Z - -52) < 1e-3).toBe(true)
			expect(#debrisItems).toBe(1)
			expect(debrisItems[1].item).toBe(shown)
			expect(debrisItems[1].lifetime).toBe(ArtProfiles.showcase.lifetimeSeconds + 0.5)
			for _, d in shown:GetDescendants() do
				if d:IsA("BasePart") then
					expect(d.Anchored).toBe(true)
					expect(d.CanCollide).toBe(false)
				end
			end
		end
	)

	it("umbral de rareza: manual desde Rara, automatica desde Legendaria", function()
		put(root, "creatures", model("minnow"))
		put(root, "creatures", model("bluegill"))
		put(root, "creatures", model("golden_trout"))
		put(root, "creatures", model("moon_koi"))
		put(root, "creatures", model("ancient_carp"))
		expect(director.showCatch(info({ creatureId = "minnow", rarity = "Common", zone = "a" }))).toBe(false)
		expect(director.showCatch(info({ creatureId = "bluegill", rarity = "Uncommon", zone = "b" }))).toBe(false)
		expect(director.showCatch(info({ creatureId = "golden_trout", rarity = "Rare", zone = "c" }))).toBe(true)
		-- pesca automatica: una Epica no se muestra, una Legendaria si
		expect(director.showCatch(info({ creatureId = "moon_koi", rarity = "Epic", zone = "d", auto = true }))).toBe(
			false
		)
		expect(director.showCatch(info({ creatureId = "ancient_carp", rarity = "Legendary", zone = "e", auto = true }))).toBe(
			true
		)
		-- rareza desconocida: nada
		expect(director.showCatch(info({ creatureId = "moon_koi", rarity = "Nope", zone = "f" }))).toBe(false)
	end)

	it("enfriamiento por zona: no hay dos escaparates seguidos en la misma zona, otra zona si", function()
		put(root, "creatures", model("lake_spirit"))
		put(root, "creatures", model("river_queen"))
		expect(director.showCatch(info())).toBe(true)
		now += 1
		expect(director.showCatch(info())).toBe(false) -- misma zona, < 2 s
		expect(director.showCatch(info({ creatureId = "river_queen", zone = "river" }))).toBe(true)
		now += 2
		expect(director.showCatch(info())).toBe(true)
	end)

	it("maximo de escaparates a la vez en el servidor; al terminar su vida se libera el cupo", function()
		director = newDirector({ maxLive = 2, cooldownSeconds = 0 })
		put(root, "creatures", model("lake_spirit"))
		expect(director.showCatch(info({ zone = "z1" }))).toBe(true)
		expect(director.showCatch(info({ zone = "z2" }))).toBe(true)
		expect(director.showCatch(info({ zone = "z3" }))).toBe(false)
		runQueue() -- terminan las esperas de vida
		expect(director.showCatch(info({ zone = "z3" }))).toBe(true)
	end)

	it("arte invalido (script): no se muestra", function()
		local malo = model("lake_spirit")
		Instance.new("ModuleScript").Parent = malo
		put(root, "creatures", malo)
		expect(director.showCatch(info())).toBe(false)
		expect(#container:GetChildren()).toBe(0)
	end)
end)

describe("ArtDirector.logStatus", function()
	it("resume cuantas piezas tienen arte y lista las rechazadas con el motivo", function()
		put(root, "rods", model("golden"))
		local malo = model("pier")
		Instance.new("Script").Parent = malo
		put(root, "props", malo)
		director.logStatus()
		local total = 0
		for _, byId in ArtProfiles.build(Balance) do
			for _ in byId do
				total += 1
			end
		end
		expect(logs[1]).toBe(
			string.format(
				"[Art] arte generado: 1 de %d piezas (%d sin arte -> respaldo procedural, 1 rechazadas)",
				total,
				total - 2
			)
		)
		expect(logs[2]).toBe("[Art] rechazada: props/pier: contains-script")
	end)
end)
