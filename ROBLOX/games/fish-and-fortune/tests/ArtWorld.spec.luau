--!nonstrict
--[[
	WorldBuilder + arte generado, sobre el lugar construido por Rojo (necesita el binario `rojo`; sin el, se OMITE igual que
	ProjectStructure). Comprueba el contrato del mundo CON arte, SIN arte (identico al procedural), con arte invalido y a medias.
]]
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local testkit = require("@testkit")
local Engine = require("@testkit/engine")
-- Todos los `require` ANTES del primer `describe` (ver el aviso de BuiltPlace).
local Balance = require("../src/shared/Balance")
local BuiltPlace = require("./support/BuiltPlace")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect

if BuiltPlace.bytes == nil then
	print("AVISO [ArtWorld] " .. tostring(BuiltPlace.problem) .. " -> pruebas OMITIDAS")
	describe("Mundo con arte generado (OMITIDA: falta rojo)", function()
		it.skip("necesita el binario rojo", function() end)
	end)
	return
end

local HERE = (debug.info(1, "s") :: string):gsub("[^/\\]+$", "")
local Art = Engine.load(HERE .. "../../../packages/Art.luau")
local ArtProfiles = Engine.load(HERE .. "../src/shared/ArtProfiles.luau")
local WORLD_SOURCE = fs.readFile(HERE .. "../src/server/WorldBuilder.luau")
local roblox = Engine.roblox
local Instance, Vector3, Enum = roblox.Instance, roblox.Vector3, roblox.Enum

-- Generador determinista: la clase Random de Roblox no existe en Lune.
local function newRandom(seed)
	local state = seed or 1
	return {
		NextNumber = function(_self, minimum, maximum)
			state = (state * 1103515245 + 12345) % 2147483648
			local unit = state / 2147483648
			if minimum ~= nil and maximum ~= nil then
				return minimum + (maximum - minimum) * unit
			end
			return unit
		end,
	}
end

local zones = {}
for _, zoneId in Balance.zoneOrder do
	table.insert(zones, { id = zoneId, nameKey = "zone." .. zoneId .. ".name", name = zoneId })
end

-- Devuelve (game, artRoot): un lugar nuevo construido por Rojo y la carpeta ServerStorage.Art.
local function newPlace()
	local game = roblox.deserializePlace(BuiltPlace.bytes)
	return game, game:GetService("ServerStorage"):FindFirstChild("Art")
end

local function build(game, art)
	local chunk = luau.load(WORLD_SOURCE, {
		environment = Engine.environment({ game = game, Random = { new = newRandom } }),
		debugName = "WorldBuilder",
	})
	return chunk().build(zones, art)
end

local function provider(artRoot, extra)
	local config = { roots = { artRoot }, profiles = ArtProfiles.build(Balance) }
	for key, value in extra or {} do
		config[key] = value
	end
	return Art.new(config)
end

local function mesh(name, size)
	local part = Instance.new("MeshPart")
	part.Name = name
	part.Size = size
	part.MeshId = "rbxassetid://4242"
	return part
end

local function addArt(artRoot, category, id, size)
	local model = Instance.new("Model")
	model.Name = id
	mesh("Body", size).Parent = model
	model.Parent = artRoot:FindFirstChild(category)
	return model
end

-- Firma estable de todo lo que hay en Workspace.World (nombre, clase y, en partes, tamano/posicion/color/material).
local function signature(game)
	local lines = {}
	local function walk(instance, depth)
		local line = string.rep(" ", depth) .. instance.Name .. ":" .. instance.ClassName
		if instance:IsA("BasePart") then
			line ..= " " .. tostring(instance.Size) .. " " .. tostring(instance.CFrame.Position) .. " " .. tostring(
				instance.Color
			)
			line ..= " " .. tostring(instance.Material) .. " t" .. tostring(instance.Transparency) .. " c" .. tostring(
				instance.CanCollide
			)
		end
		table.insert(lines, line)
		for _, child in instance:GetChildren() do
			walk(child, depth + 1)
		end
	end
	walk(game:GetService("Workspace"):FindFirstChild("World"), 0)
	return table.concat(lines, "\n")
end

local function countNamed(root, prefix)
	local n = 0
	for _, child in root:GetChildren() do
		if string.sub(child.Name, 1, #prefix) == prefix then
			n += 1
		end
	end
	return n
end

local function assertContract(game, info)
	local world = game:GetService("Workspace"):FindFirstChild("World")
	for _, zoneId in Balance.zoneOrder do
		local folder = world:FindFirstChild(zoneId)
		for _, partName in { "Spawn", "CastTarget", "Sign" } do
			local part = folder:FindFirstChild(partName)
			if part == nil or not part:IsA("BasePart") then
				error("Workspace.World." .. zoneId .. "." .. partName .. " no existe o no es BasePart")
			end
		end
		expect(info.spawns[zoneId] ~= nil).toBe(true)
		expect(info.castTargets[zoneId] ~= nil).toBe(true)
	end
end

describe("WorldBuilder con arte generado", function()
	it("SIN arte (carpetas de ServerStorage.Art vacias): el mundo es IDENTICO al procedural de siempre", function()
		local gameA = newPlace()
		build(gameA, nil)
		local gameB, artRoot = newPlace()
		expect(#artRoot:GetDescendants()).toBe(3) -- solo las tres carpetas de categoria
		build(gameB, provider(artRoot))
		expect(signature(gameB)).toBe(signature(gameA))
	end)

	it("SIN arte: farolas, barca, muelle y arboles salen con piezas procedurales (sin PierArt)", function()
		local game, artRoot = newPlace()
		build(game, provider(artRoot))
		local lake = game:GetService("Workspace").World.lake
		expect(lake:FindFirstChild("PierArt")).toBeNil()
		expect(lake:FindFirstChild("RowboatHull", true) ~= nil).toBe(true)
		expect(countNamed(lake, "LanternPost") > 0).toBe(true)
		expect(countNamed(lake, "PierPost") >= 10).toBe(true)
	end)

	it(
		"CON arte de muelle: PierArt visual + cubierta 'Pier' invisible que SI colisiona; sin postes procedurales",
		function()
			local game, artRoot = newPlace()
			addArt(artRoot, "props", "pier", Vector3.new(10, 6, 50))
			local info = build(game, provider(artRoot))
			assertContract(game, info)
			for _, zoneId in Balance.zoneOrder do
				local zone = game:GetService("Workspace").World[zoneId]
				local art = zone:FindFirstChild("PierArt")
				expect(art ~= nil and art.ClassName == "Model").toBe(true)
				expect(countNamed(zone, "PierPost")).toBe(0)
				local walkway = zone:FindFirstChild("Pier")
				expect(walkway.ClassName).toBe("Part")
				expect(walkway.Transparency).toBe(1)
				expect(walkway.CanCollide).toBe(true)
				expect(walkway.CanQuery).toBe(false)
				-- la caja del arte se ajusto al muelle (8 x 5 x 44) y su base queda en y = -2
				local center, size = Art.bounds(art)
				expect(math.abs(size.X - 8) < 1e-2 or math.abs(size.Z - 44) < 1e-2).toBe(true)
				expect(math.abs((center.Y - size.Y / 2) - -2) < 1e-2).toBe(true)
			end
		end
	)

	it("CON farolas y barca: 6 farolas y 1 barca por zona; el resto del mundo no cambia", function()
		local game, artRoot = newPlace()
		addArt(artRoot, "props", "lantern", Vector3.new(1, 5, 1))
		addArt(artRoot, "props", "rowboat", Vector3.new(4, 2, 9))
		local info = build(game, provider(artRoot))
		assertContract(game, info)
		for _, zoneId in Balance.zoneOrder do
			local zone = game:GetService("Workspace").World[zoneId]
			expect(countNamed(zone, "Lantern")).toBe(6)
			expect(zone:FindFirstChild("Rowboat") ~= nil).toBe(true)
			expect(countNamed(zone, "PierPost")).toBe(10) -- el muelle sigue siendo el procedural
		end
	end)

	it(
		"CON arboles: pine_tree en Lago y Rio, palm_tree en Costa; las 4 posiciones, sin troncos procedurales",
		function()
			local game, artRoot = newPlace()
			addArt(artRoot, "props", "pine_tree", Vector3.new(5, 10, 5))
			addArt(artRoot, "props", "palm_tree", Vector3.new(6, 9, 6))
			build(game, provider(artRoot))
			local world = game:GetService("Workspace").World
			for _, zoneId in { "lake", "river", "coast" } do
				expect(countNamed(world[zoneId], "Tree")).toBe(4)
				expect(countNamed(world[zoneId], "TreeTrunk")).toBe(0)
				expect(countNamed(world[zoneId], "TreeCrown")).toBe(0)
			end
			-- variedad de tamano: no todos los arboles miden lo mismo
			local heights = {}
			for _, child in world.lake:GetChildren() do
				if string.sub(child.Name, 1, 4) == "Tree" then
					local _, size = Art.bounds(child)
					heights[string.format("%.2f", size.Y)] = true
				end
			end
			local distinct = 0
			for _ in heights do
				distinct += 1
			end
			expect(distinct > 3).toBe(true)
		end
	)

	it("arboles: las posiciones de rocas y arboles NO cambian por usar arte (generador aparte)", function()
		local gameA = newPlace()
		build(gameA, nil)
		local gameB, artRoot = newPlace()
		addArt(artRoot, "props", "pine_tree", Vector3.new(5, 10, 5))
		build(gameB, provider(artRoot))
		local function rocks(game)
			local list = {}
			for _, child in game:GetService("Workspace").World.lake:GetChildren() do
				if string.sub(child.Name, 1, 4) == "Rock" then
					table.insert(list, child.Name .. tostring(child.CFrame.Position))
				end
			end
			return table.concat(list, ";")
		end
		expect(rocks(gameB)).toBe(rocks(gameA))
	end)

	it("ARTE INVALIDO (script dentro del muelle): se usa el muelle procedural y no entra ningun script", function()
		local game, artRoot = newPlace()
		local malo = addArt(artRoot, "props", "pier", Vector3.new(8, 5, 44))
		Instance.new("Script").Parent = malo
		local logs = {}
		build(
			game,
			provider(artRoot, {
				log = function(message)
					table.insert(logs, message)
				end,
			})
		)
		local lake = game:GetService("Workspace").World.lake
		expect(lake:FindFirstChild("PierArt")).toBeNil()
		expect(countNamed(lake, "PierPost")).toBe(10)
		expect(lake:FindFirstChild("Pier").Transparency).toBe(0)
		for _, descendant in game:GetService("Workspace"):GetDescendants() do
			expect(descendant:IsA("LuaSourceContainer")).toBe(false)
		end
		expect(#logs).toBe(1) -- se avisa una sola vez aunque haya 3 zonas
		expect(logs[1]).toContain("contains-script")
	end)

	it("ARTE A MEDIAS: solo hay muelle y un arbol; lo demas sigue procedural y el mundo se construye", function()
		local game, artRoot = newPlace()
		addArt(artRoot, "props", "pier", Vector3.new(8, 5, 44))
		local roto = Instance.new("Model") -- barca sin partes
		roto.Name = "rowboat"
		roto.Parent = artRoot.props
		local info = build(game, provider(artRoot))
		assertContract(game, info)
		local lake = game:GetService("Workspace").World.lake
		expect(lake:FindFirstChild("PierArt") ~= nil).toBe(true)
		expect(lake:FindFirstChild("Rowboat")).toBeNil() -- la barca rota se descarta (y no tiene respaldo)
		expect(countNamed(lake, "TreeTrunk")).toBe(4)
	end)

	it("materiales generados: el suelo usa el MaterialVariant FF_ground_<zona> con su material base", function()
		local game, artRoot = newPlace()
		local materials = Instance.new("Folder")
		local variant = Instance.new("MaterialVariant")
		variant.Name = "FF_ground_lake"
		variant.BaseMaterial = Enum.Material.Grass
		variant.Parent = materials
		local sand = Instance.new("MaterialVariant")
		sand.Name = "FF_ground_coast"
		sand.BaseMaterial = Enum.Material.Sand
		sand.Parent = materials
		local planks = Instance.new("MaterialVariant")
		planks.Name = "FF_pier_wood"
		planks.BaseMaterial = Enum.Material.WoodPlanks
		planks.Parent = materials
		build(game, provider(artRoot, { materialRoot = materials }))
		local world = game:GetService("Workspace").World
		expect(world.lake.Ground.MaterialVariant).toBe("FF_ground_lake")
		expect(world.lake.Ground.Material).toBe(Enum.Material.Grass)
		expect(world.coast.Ground.MaterialVariant).toBe("FF_ground_coast")
		expect(world.river.Ground.MaterialVariant).toBe("")
		expect(world.lake.Pier.MaterialVariant).toBe("FF_pier_wood") -- muelle procedural
	end)

	it("construir dos veces con arte no duplica nada", function()
		local game, artRoot = newPlace()
		addArt(artRoot, "props", "lantern", Vector3.new(1, 5, 1))
		local art = provider(artRoot)
		build(game, art)
		build(game, art)
		local count = 0
		for _, child in game:GetService("Workspace"):GetChildren() do
			if child.Name == "World" then
				count += 1
			end
		end
		expect(count).toBe(1)
		expect(countNamed(game:GetService("Workspace").World.lake, "Lantern")).toBe(6)
	end)
end)
