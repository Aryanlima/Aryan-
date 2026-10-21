--!strict
--[[
	WorldBuilder: construye el mundo de Fish & Fortune POR CODIGO (partes simples, colores agradables,
	iluminacion). No hay arte: este modulo es el unico sitio a sustituir cuando haya mapa generado con IA
	(ver README, "Que falta"). Contrato con el resto del juego:

	  Workspace.World/<zona>/Spawn        Part invisible: donde aparece el jugador al viajar a la zona
	  Workspace.World/<zona>/CastTarget   Part invisible sobre el agua: donde cae el flotador
	  Workspace.World/<zona>/Sign         cartel con el nombre (SurfaceGui)

	Si un mapa nuevo respeta ese contrato (y el servidor lee `build()`), nada mas cambia.

	ARTE GENERADO (opcional): `build(zonas, art)` recibe el proveedor de arte (packages/Art). Para cada pieza que tiene perfil
	(muelle, farolas, barca, arboles) pide el modelo generado; si no existe o no es valido usa el generador procedural de
	siempre como RESPALDO (farolas y barca no tienen respaldo: sin arte no aparecen). Los materiales generados
	(MaterialVariant) se aplican al suelo y al muelle procedural. El arte es solo visual: lo que se pisa (la cubierta del
	muelle) sigue siendo una parte propia e invisible. Sin `art` el resultado es identico al de siempre.
]]

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

export type WorldInfo = {
	spawns: { [string]: Vector3 },
	castTargets: { [string]: Vector3 },
}

-- Lo que WorldBuilder necesita del proveedor de arte (packages/Art.Provider); `self: any` porque es un objeto con metatabla.
export type ArtLike = {
	place: (
		self: any,
		category: string,
		id: string,
		options: {
			parent: Instance,
			cframe: CFrame,
			name: string?,
			anchored: boolean?,
			scale: number?,
			fallback: ((parent: Instance, cframe: CFrame) -> Instance?)?,
		}
	) -> { source: string, instance: Instance?, reason: string? },
	materialFor: (self: any, id: string) -> { baseMaterial: Enum.Material, variantName: string }?,
}

type ZoneStyle = {
	id: string,
	name: string, -- los pone WorldBuilder.build desde la lista de zonas (texto en espanol + clave de Strings)
	nameKey: string,
	origin: Vector3,
	groundColor: Color3,
	groundMaterial: Enum.Material,
	waterColor: Color3,
	waterShape: string, -- "disc" | "river" | "sea"
	treeColor: Color3,
	treeArt: string, -- id del arbol generado en props ("pine_tree" | "palm_tree")
	seed: number,
}

local WorldBuilder = {}

local function newPart(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent -- el Parent se asigna al final (no Instance.new(clase, padre))
	return part
end

local function invisible(part: Part): Part
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	return part
end

-- Aplica el MaterialVariant generado (si existe) a una parte procedural.
local function applyVariant(part: Part, art: ArtLike?, materialId: string)
	if art == nil then
		return
	end
	local choice = art:materialFor(materialId)
	if choice ~= nil then
		part.Material = choice.baseMaterial
		part.MaterialVariant = choice.variantName
	end
end

local function buildWater(folder: Folder, style: ZoneStyle)
	local origin = style.origin
	local water: Part
	if style.waterShape == "disc" then
		water = newPart(
			folder,
			"Water",
			Vector3.new(1, 110, 110),
			origin + Vector3.new(0, 0.1, -45),
			style.waterColor,
			Enum.Material.Glass
		)
		water.Shape = Enum.PartType.Cylinder
		water.CFrame = CFrame.new(origin + Vector3.new(0, 0.1, -45)) * CFrame.Angles(0, 0, math.rad(90))
	elseif style.waterShape == "river" then
		water = newPart(
			folder,
			"Water",
			Vector3.new(60, 1, 170),
			origin + Vector3.new(0, 0.1, -40),
			style.waterColor,
			Enum.Material.Glass
		)
	else
		water = newPart(
			folder,
			"Water",
			Vector3.new(180, 1, 100),
			origin + Vector3.new(0, 0.1, -70),
			style.waterColor,
			Enum.Material.Glass
		)
	end
	water.Transparency = 0.35
	water.CanCollide = false -- se puede caminar por debajo del muelle sin "flotar"
	water.CanQuery = false
end

local PIER_WOOD = Color3.fromRGB(150, 110, 70)

-- Muelle procedural de siempre (respaldo del arte "pier"): cubierta + postes.
local function buildProceduralPier(folder: Folder, style: ZoneStyle, art: ArtLike?)
	local darkWood = Color3.fromRGB(110, 80, 50)
	local origin = style.origin
	local deck = newPart(
		folder,
		"Pier",
		Vector3.new(8, 1, 44),
		origin + Vector3.new(0, 1.2, -18),
		PIER_WOOD,
		Enum.Material.WoodPlanks
	)
	applyVariant(deck, art, "pier_wood")
	for index = 0, 4 do
		local z = -36 + index * 9
		newPart(
			folder,
			"PierPost",
			Vector3.new(1.2, 5, 1.2),
			origin + Vector3.new(-3.6, 0.5, z),
			darkWood,
			Enum.Material.Wood
		)
		newPart(
			folder,
			"PierPost",
			Vector3.new(1.2, 5, 1.2),
			origin + Vector3.new(3.6, 0.5, z),
			darkWood,
			Enum.Material.Wood
		)
	end
end

local function buildPier(folder: Folder, style: ZoneStyle, art: ArtLike?)
	local origin = style.origin
	if art == nil then
		buildProceduralPier(folder, style, nil)
	else
		-- La base del modelo queda donde acaban los postes (y = -2) y centrado en la cubierta; si no hay arte valido, el respaldo.
		local result = art:place("props", "pier", {
			parent = folder,
			cframe = CFrame.new(origin + Vector3.new(0, -2, -18)),
			name = "PierArt",
			fallback = function(): Instance?
				buildProceduralPier(folder, style, art)
				return nil
			end,
		})
		if result.source == "art" then
			-- El arte es solo visual: por donde se camina sigue siendo una cubierta propia (invisible), a la altura de siempre.
			local walkway = newPart(
				folder,
				"Pier",
				Vector3.new(8, 1, 44),
				origin + Vector3.new(0, 1.2, -18),
				PIER_WOOD,
				Enum.Material.WoodPlanks
			)
			walkway.Transparency = 1
			walkway.CanQuery = false
		end
	end
	local spawn =
		invisible(newPart(folder, "Spawn", Vector3.new(4, 1, 4), origin + Vector3.new(0, 6, 12), PIER_WOOD, nil))
	spawn.Name = "Spawn"
	local target = invisible(
		newPart(folder, "CastTarget", Vector3.new(1, 1, 1), origin + Vector3.new(0, 0.9, -52), PIER_WOOD, nil)
	)
	target.Name = "CastTarget"
end

-- Farolas y barca: SOLO existen con arte generado (no hay respaldo: sin arte el mundo es el de siempre).
local function buildArtOnlyProps(folder: Folder, style: ZoneStyle, art: ArtLike)
	local origin = style.origin
	local index = 0
	for _, z in { -34, -20, -6 } do
		for _, side in { -1, 1 } do
			index += 1
			art:place("props", "lantern", {
				parent = folder,
				cframe = CFrame.new(origin + Vector3.new(side * 3.5, 1.7, z)),
				name = "Lantern" .. index,
			})
		end
	end
	art:place("props", "rowboat", {
		parent = folder,
		cframe = CFrame.new(origin + Vector3.new(-9, 0.15, -30)) * CFrame.Angles(0, math.rad(20), 0),
		name = "Rowboat",
	})
end

local function buildSign(folder: Folder, style: ZoneStyle)
	local post = newPart(
		folder,
		"Sign",
		Vector3.new(12, 6, 0.6),
		style.origin + Vector3.new(14, 5, 8),
		Color3.fromRGB(60, 45, 35),
		Enum.Material.Wood
	)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = style.name -- respaldo (espanol); el cliente lo cambia al idioma del jugador usando LocaleKey
	label:SetAttribute("LocaleKey", style.nameKey)
	gui.AutoLocalize = false -- el texto lo localiza el juego (Strings), no la traduccion automatica de Roblox
	label.TextColor3 = Color3.fromRGB(255, 240, 210)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = gui
	gui.Parent = post
	newPart(
		folder,
		"SignLegs",
		Vector3.new(1, 5, 1),
		style.origin + Vector3.new(14, 2.5, 7.6),
		Color3.fromRGB(60, 45, 35),
		Enum.Material.Wood
	)
end

local function buildDecor(folder: Folder, style: ZoneStyle, art: ArtLike?)
	local rng = Random.new(style.seed)
	local artRng = Random.new(style.seed + 1000)
	local origin = style.origin
	for index = 1, 16 do
		-- arboles en la parte de tierra (z > 20) y a los lados
		local x = rng:NextNumber(-80, 80)
		local z = rng:NextNumber(20, 85)
		if math.abs(x) < 8 and z < 40 then
			x += 20
		end
		local height = rng:NextNumber(7, 11)
		local function proceduralTree(): Instance?
			newPart(
				folder,
				"TreeTrunk" .. index,
				Vector3.new(2, height, 2),
				origin + Vector3.new(x, height / 2, z),
				Color3.fromRGB(110, 78, 50),
				Enum.Material.Wood
			)
			local crown = newPart(
				folder,
				"TreeCrown" .. index,
				Vector3.new(9, 9, 9),
				origin + Vector3.new(x, height + 3, z),
				style.treeColor,
				Enum.Material.Grass
			)
			crown.Shape = Enum.PartType.Ball
			return crown
		end
		if art == nil then
			proceduralTree()
		else
			-- variedad (giro y tamano) con un generador APARTE: no altera la secuencia del procedural
			art:place("props", style.treeArt, {
				parent = folder,
				cframe = CFrame.new(origin + Vector3.new(x, -0.2, z))
					* CFrame.Angles(0, artRng:NextNumber(0, math.pi * 2), 0),
				name = "Tree" .. index,
				scale = 0.8 + 0.4 * artRng:NextNumber(),
				fallback = proceduralTree,
			})
		end
	end
	for index = 1, 10 do
		local x = rng:NextNumber(-85, 85)
		local z = rng:NextNumber(14, 88)
		local size = rng:NextNumber(2, 5)
		local rock = newPart(
			folder,
			"Rock" .. index,
			Vector3.new(size * 1.4, size, size * 1.2),
			origin + Vector3.new(x, size / 2 - 0.3, z),
			Color3.fromRGB(125, 130, 135),
			Enum.Material.Slate
		)
		rock.Shape = Enum.PartType.Ball
	end
end

local function buildZone(world: Folder, style: ZoneStyle, art: ArtLike?)
	local folder = Instance.new("Folder")
	folder.Name = style.id
	local ground = newPart(
		folder,
		"Ground",
		Vector3.new(200, 4, 200),
		style.origin + Vector3.new(0, -2, 0),
		style.groundColor,
		style.groundMaterial
	)
	applyVariant(ground, art, "ground_" .. style.id)
	buildWater(folder, style)
	buildPier(folder, style, art)
	buildSign(folder, style)
	buildDecor(folder, style, art)
	if art ~= nil then
		buildArtOnlyProps(folder, style, art)
	end
	folder.Parent = world
end

local function setupLighting()
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(110, 120, 140)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 150, 170)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 240, 215)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.5

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(200, 215, 235)
	atmosphere.Decay = Color3.fromRGB(255, 225, 190)
	atmosphere.Glare = 0.2
	atmosphere.Haze = 0.6
	atmosphere.Parent = Lighting

	local correction = Instance.new("ColorCorrectionEffect")
	correction.Saturation = 0.15
	correction.Contrast = 0.05
	correction.TintColor = Color3.fromRGB(255, 248, 238)
	correction.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.25
	bloom.Size = 24
	bloom.Threshold = 1.6
	bloom.Parent = Lighting
end

--[[
	Construye el mundo y devuelve los puntos de aparicion y de lanzamiento por zona.
	`zones` = lista ordenada de { id, name, nameKey } (Balance.zoneOrder; `name` en espanol y `nameKey` = clave de Strings).
	`art` = proveedor de arte opcional (packages/Art); nil = todo procedural, como siempre.
]]
-- Formas del agua por zona (las mismas medidas que buildWater/buildPier), relativas al origen de la zona.
local WATER_SHAPES: { [string]: { origin: Vector3, shape: string } } = {}

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
end

--[[
	Se puede pescar en el muelle o en la orilla (a `reach` studs del borde del agua), nunca tierra adentro ni nadando.
	Lo usa el SERVIDOR al lanzar (no se confia en el cliente) y el cliente solo para la pista de la UI.
]]
function WorldBuilder.canFishAt(zoneId: string, position: Vector3, reach: number): boolean
	local water = WATER_SHAPES[zoneId]
	if water == nil then
		return false
	end
	local rel = position - water.origin
	if math.abs(rel.X) <= 4.5 and rel.Z <= 2 and rel.Z >= -41 then
		return true -- sobre el muelle
	end
	if water.shape == "disc" then
		local d = flatDistance(rel, Vector3.new(0, 0, -45))
		return d >= 55 - reach and d <= 55 + reach
	elseif water.shape == "river" then
		local edge = math.abs(math.abs(rel.X) - 30)
		return edge <= reach and rel.Z >= -125 and rel.Z <= 45
	end
	return math.abs(rel.Z + 20) <= reach and math.abs(rel.X) <= 90
end

function WorldBuilder.build(zones: { { id: string, name: string, nameKey: string } }, art: ArtLike?): WorldInfo
	local existing = Workspace:FindFirstChild("World")
	if existing then
		existing:Destroy()
	end
	local world = Instance.new("Folder")
	world.Name = "World"

	local styles: { [string]: ZoneStyle } = {
		lake = {
			id = "lake",
			name = "",
			nameKey = "",
			origin = Vector3.new(0, 0, 0),
			groundColor = Color3.fromRGB(104, 170, 98),
			groundMaterial = Enum.Material.Grass,
			waterColor = Color3.fromRGB(70, 150, 220),
			waterShape = "disc",
			treeColor = Color3.fromRGB(70, 140, 70),
			treeArt = "pine_tree",
			seed = 11,
		},
		river = {
			id = "river",
			name = "",
			nameKey = "",
			origin = Vector3.new(400, 0, 0),
			groundColor = Color3.fromRGB(120, 160, 110),
			groundMaterial = Enum.Material.Grass,
			waterColor = Color3.fromRGB(90, 200, 215),
			waterShape = "river",
			treeColor = Color3.fromRGB(50, 120, 90),
			treeArt = "pine_tree",
			seed = 22,
		},
		coast = {
			id = "coast",
			name = "",
			nameKey = "",
			origin = Vector3.new(800, 0, 0),
			groundColor = Color3.fromRGB(232, 210, 150),
			groundMaterial = Enum.Material.Sand,
			waterColor = Color3.fromRGB(40, 130, 200),
			waterShape = "sea",
			treeColor = Color3.fromRGB(95, 170, 80),
			treeArt = "palm_tree",
			seed = 33,
		},
	}

	local info: WorldInfo = { spawns = {}, castTargets = {} }
	for _, zone in zones do
		local style = styles[zone.id]
		if style then
			style.name = zone.name
			style.nameKey = zone.nameKey
			buildZone(world, style, art)
			WATER_SHAPES[zone.id] = { origin = style.origin, shape = style.waterShape }
			info.spawns[zone.id] = style.origin + Vector3.new(0, 6, 12)
			info.castTargets[zone.id] = style.origin + Vector3.new(0, 0.9, -52)
		end
	end
	world.Parent = Workspace

	-- Aparicion inicial: el comienzo del muelle del Lago Calmo.
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "SpawnLocation"
	spawnLocation.Anchored = true
	spawnLocation.Size = Vector3.new(6, 1, 6)
	spawnLocation.Position = Vector3.new(0, 0.5, 14)
	spawnLocation.Transparency = 1
	spawnLocation.Neutral = true
	spawnLocation.Duration = 0
	spawnLocation.Parent = Workspace

	setupLighting()
	return info
end

return WorldBuilder
