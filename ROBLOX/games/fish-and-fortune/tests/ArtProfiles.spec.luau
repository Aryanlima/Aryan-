--!nonstrict
--[[
	ArtProfiles y art/manifest.json: los perfiles de tiempo de ejecucion y el manifiesto de prompts no pueden desincronizarse,
	todas las piezas del juego tienen perfil, los presupuestos respetan los limites oficiales y los prompts siguen el brand kit
	(sin IP ni marcas, sin estetica de casino/azar: nada de monedas, dados, cartas...).
]]
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local testkit = require("@testkit")
local Engine = require("@testkit/engine")
local Balance = require("../src/shared/Balance")

local describe, it, expect = testkit.describe, testkit.it, testkit.expect

local HERE = (debug.info(1, "s") :: string):gsub("[^/\\]+$", "")
local ArtProfiles = Engine.load(HERE .. "../src/shared/ArtProfiles.luau")
local manifest = serde.decode("json", fs.readFile(HERE .. "../art/manifest.json"))
local profiles = ArtProfiles.build(Balance)

local MESH_HARD_MAX = 20000 -- specifications.md: "Individual meshes can not exceed 20,000 triangles"

local function piecesOf(kind)
	local list = {}
	for _, piece in manifest.pieces do
		if piece.kind == kind then
			table.insert(list, piece)
		end
	end
	return list
end

local function sizeOf(vector3)
	return { vector3.X, vector3.Y, vector3.Z }
end

describe("ArtProfiles: una ficha por pieza de arte del juego", function()
	it("hay un perfil para cada una de las 25 criaturas y las 5 canas", function()
		expect(#Balance.creatures).toBe(25)
		for _, creature in Balance.creatures do
			expect(profiles.creatures[creature.id] ~= nil).toBe(true)
		end
		for _, rodId in Balance.rodOrder do
			expect(profiles.rods[rodId] ~= nil).toBe(true)
		end
		local props = {}
		for id in profiles.props do
			table.insert(props, id)
		end
		table.sort(props)
		expect(props).toEqual({ "lantern", "palm_tree", "pier", "pine_tree", "rowboat" })
	end)

	it("cada perfil es coherente: categoria/id, caja positiva, presupuesto <= 20.000, partes razonables", function()
		for category, byId in profiles do
			for id, profile in byId do
				expect(profile.category).toBe(category)
				expect(profile.id).toBe(id)
				expect(profile.targetSize.X > 0 and profile.targetSize.Y > 0 and profile.targetSize.Z > 0).toBe(true)
				expect(
					profile.maxTriangles ~= nil and profile.maxTriangles > 0 and profile.maxTriangles <= MESH_HARD_MAX
				).toBe(true)
				expect(profile.maxParts ~= nil and profile.maxParts >= 1 and profile.maxParts <= 12).toBe(true)
			end
		end
	end)

	it("las criaturas raras son mas grandes y tienen mas presupuesto que las comunes", function()
		local minnow, spirit = profiles.creatures.minnow, profiles.creatures.lake_spirit
		expect(spirit.targetSize.Z > minnow.targetSize.Z * 3).toBe(true)
		expect(spirit.maxTriangles > minnow.maxTriangles).toBe(true)
	end)

	it("las canas se igualan por LARGO y se agarran por el mango (pivot back)", function()
		for _, rodId in Balance.rodOrder do
			local profile = profiles.rods[rodId]
			expect(profile.fit).toBe("length")
			expect(profile.pivot).toBe("back")
			expect(profile.targetSize.Z).toBe(5) -- el largo de la cana procedural
		end
	end)

	it("el escaparate de capturas usa rarezas que existen y tiene limites sensatos", function()
		local cfg = ArtProfiles.showcase
		expect(Balance.rarities[cfg.minRarityManual] ~= nil).toBe(true)
		expect(Balance.rarities[cfg.minRarityAuto] ~= nil).toBe(true)
		expect(Balance.rarities[cfg.minRarityAuto].order >= Balance.rarities[cfg.minRarityManual].order).toBe(true)
		expect(cfg.maxLive >= 1 and cfg.maxLive <= 10).toBe(true)
		expect(cfg.lifetimeSeconds > 0 and cfg.lifetimeSeconds <= 10).toBe(true)
	end)
end)

describe("art/manifest.json coincide con los perfiles (sin desviaciones)", function()
	it("cada pieza de malla del manifiesto tiene el mismo perfil que ArtProfiles", function()
		local seen = {}
		for _, piece in piecesOf("mesh") do
			local key = piece.category .. "/" .. piece.id
			expect(seen[key]).toBeNil() -- sin duplicados
			seen[key] = true
			local profile = profiles[piece.category] and profiles[piece.category][piece.id]
			if profile == nil then
				error("el manifiesto tiene " .. key .. " pero ArtProfiles no")
			end
			local size = sizeOf(profile.targetSize)
			for axis = 1, 3 do
				expect(piece.targetSize[axis]).toBeCloseTo(size[axis], 3) -- Vector3 guarda float32
			end
			expect(piece.fit).toBe(profile.fit)
			expect(piece.pivot).toBe(profile.pivot)
			expect(piece.maxTriangles).toBe(profile.maxTriangles)
			expect(piece.maxParts).toBe(profile.maxParts)
		end
	end)

	it(
		"el manifiesto cubre TODAS las canas y TODOS los props, y al menos 8 criaturas incluidos los 3 Miticos",
		function()
			local inManifest = {}
			for _, piece in piecesOf("mesh") do
				inManifest[piece.category .. "/" .. piece.id] = piece
			end
			for _, rodId in Balance.rodOrder do
				expect(inManifest["rods/" .. rodId] ~= nil).toBe(true)
			end
			for id in profiles.props do
				expect(inManifest["props/" .. id] ~= nil).toBe(true)
			end
			local creatures = 0
			for _, creature in Balance.creatures do
				if inManifest["creatures/" .. creature.id] then
					creatures += 1
					expect(inManifest["creatures/" .. creature.id].rarity).toBe(creature.rarity)
					expect(inManifest["creatures/" .. creature.id].zone).toBe(creature.zone)
				end
				if creature.rarity == "Mythic" then
					expect(inManifest["creatures/" .. creature.id] ~= nil).toBe(true)
				end
			end
			expect(creatures >= 8 and creatures <= 12).toBe(true)
		end
	)

	it(
		"los materiales del manifiesto son exactamente ArtProfiles.materials (con su material base y nombre FF_)",
		function()
			local ids = {}
			for _, piece in piecesOf("material") do
				ids[piece.id] = true
				expect(ArtProfiles.materials[piece.id]).toBe(piece.baseMaterial)
				expect(piece.variantName).toBe("FF_" .. piece.id)
			end
			for id in ArtProfiles.materials do
				expect(ids[id]).toBe(true)
			end
		end
	)

	it("limites del manifiesto = limites oficiales; ningun presupuesto los supera", function()
		expect(manifest.limits.hardMaxTrianglesPerMesh).toBe(MESH_HARD_MAX)
		expect(manifest.limits.materialsPerMesh).toBe(1)
		expect(manifest.limits.proceduralModelsPer24h).toBe(50)
		expect(manifest.limits.retriesPerPiece).toBe(2)
		for _, piece in piecesOf("mesh") do
			expect(piece.maxTriangles <= MESH_HARD_MAX).toBe(true)
		end
	end)
end)

describe("art/manifest.json: prompts coherentes con el brand kit", function()
	local FORBIDDEN_WORDS = {
		"coin",
		"money",
		"casino",
		"dice",
		"card",
		"slot",
		"gambl",
		"jackpot",
		"treasure chest",
		"lootbox",
		"roblox",
		"pokemon",
		"nintendo",
		"disney",
		"pixar",
		"minecraft",
		"nemo",
		"ghibli",
		"in the style of",
	}

	local function positivePart(prompt)
		local before = string.match(prompt, "^(.-)Avoid:") or prompt
		return string.lower(before)
	end

	it("cada prompt de malla lleva el bloque de estilo y las restricciones, y 2 reintentos distintos", function()
		for _, piece in piecesOf("mesh") do
			expect(#piece.retryPrompts).toBe(2)
			expect(piece.retryPrompts[1] ~= piece.prompt).toBe(true)
			expect(piece.retryPrompts[2] ~= piece.retryPrompts[1]).toBe(true)
			for _, prompt in { piece.prompt, piece.retryPrompts[1], piece.retryPrompts[2] } do
				expect(string.find(prompt, manifest.styleBlock, 1, true) ~= nil).toBe(true)
				expect(string.find(prompt, manifest.constraintsBlock, 1, true) ~= nil).toBe(true)
			end
		end
	end)

	it("la parte positiva de los prompts no nombra marcas, estudios, azar ni dinero", function()
		for _, piece in manifest.pieces do
			for _, prompt in { piece.prompt, piece.retryPrompts[1], piece.retryPrompts[2] } do
				local positive = positivePart(prompt)
				for _, word in FORBIDDEN_WORDS do
					if string.find(positive, word, 1, true) ~= nil then
						error(piece.id .. ": el prompt positivo contiene '" .. word .. "'")
					end
				end
			end
		end
	end)

	it("la lista negativa y las restricciones prohiben monedas, dinero, dados, cartas y casino", function()
		local negative = table.concat(manifest.negative, " | ")
		for _, word in { "coins", "money", "dice", "playing cards", "casino", "text", "logos", "human faces" } do
			expect(string.find(negative, word, 1, true) ~= nil).toBe(true)
			expect(string.find(manifest.constraintsBlock, word, 1, true) ~= nil).toBe(true)
		end
	end)

	it("los prompts de malla son en ingles y razonablemente cortos (< 900 caracteres)", function()
		for _, piece in piecesOf("mesh") do
			for _, prompt in { piece.prompt, piece.retryPrompts[1], piece.retryPrompts[2] } do
				expect(#prompt < 900).toBe(true)
				expect(string.find(prompt, "[\128-\255]") == nil).toBe(true) -- ASCII puro: sin tildes ni simbolos raros
			end
		end
	end)

	it("las piezas que piden caja contenedora indican su tamano (propiedades que se ajustan al perfil)", function()
		for _, piece in piecesOf("mesh") do
			if piece.category == "props" or piece.category == "rods" then
				local t = piece.targetSize
				local expected = string.format("%s x %s x %s studs", tostring(t[1]), tostring(t[2]), tostring(t[3]))
				expect(string.find(piece.prompt, expected, 1, true) ~= nil).toBe(true)
			end
		end
	end)
end)

describe("art/manifest.json: lotes diarios", function()
	it("cada pieza esta en un unico lote que existe; ningun lote supera el cupo diario propio", function()
		local batchOf = {}
		local batchIds = {}
		for _, batch in manifest.batches do
			batchIds[batch.id] = true
			expect(batch.meshCalls <= 12).toBe(true)
			for _, id in batch.pieces do
				expect(batchOf[id]).toBeNil()
				batchOf[id] = batch.id
			end
		end
		for _, piece in manifest.pieces do
			expect(batchOf[piece.id]).toBe(piece.batch)
			expect(batchIds[piece.batch]).toBe(true)
		end
		for _, batch in manifest.batches do
			local meshes, materials = 0, 0
			for _, id in batch.pieces do
				for _, piece in manifest.pieces do
					if piece.id == id then
						if piece.kind == "mesh" then
							meshes += 1
						else
							materials += 1
						end
					end
				end
			end
			-- se prevé de media <= 2 intentos por pieza dentro del cupo de llamadas del dia
			expect(meshes * 2 <= batch.meshCalls).toBe(true)
			expect(materials <= (batch.materialCalls or 0) or materials == 0).toBe(true)
		end
	end)

	it("el primer dia contiene los 3 Miticos y el muelle (mayor impacto visual)", function()
		local first = manifest.batches[1]
		expect(first.day).toBe(1)
		for _, id in { "lake_spirit", "river_queen", "tide_leviathan", "pier" } do
			expect(table.find(first.pieces, id) ~= nil).toBe(true)
		end
	end)
end)
