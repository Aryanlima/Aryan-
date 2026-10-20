--!strict
--[[
	WorldBuilder: construye el mundo de Fish & Fortune POR CODIGO (partes simples, colores agradables,
	iluminacion). No hay arte: este modulo es el unico sitio a sustituir cuando haya mapa generado con IA
	(ver README, "Que falta"). Contrato con el resto del juego:

	  Workspace.World/<zona>/Spawn        Part invisible: donde aparece el jugador al viajar a la zona
	  Workspace.World/<zona>/CastTarget   Part invisible sobre el agua: donde cae el flotador
	  Workspace.World/<zona>/Sign         cartel con el nombre (SurfaceGui)

	Si un mapa nuevo respeta ese contrato (y el servidor lee `build()`), nada mas cambia.
]]

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

export type WorldInfo = {
	spawns: { [string]: Vector3 },
	castTargets: { [string]: Vector3 },
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

local function buildPier(folder: Folder, style: ZoneStyle)
	local wood = Color3.fromRGB(150, 110, 70)
	local darkWood = Color3.fromRGB(110, 80, 50)
	local origin = style.origin
	newPart(folder, "Pier", Vector3.new(8, 1, 44), origin + Vector3.new(0, 1.2, -18), wood, Enum.Material.WoodPlanks)
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
	local spawn = invisible(newPart(folder, "Spawn", Vector3.new(4, 1, 4), origin + Vector3.new(0, 6, 12), wood, nil))
	spawn.Name = "Spawn"
	local target =
		invisible(newPart(folder, "CastTarget", Vector3.new(1, 1, 1), origin + Vector3.new(0, 0.9, -52), wood, nil))
	target.Name = "CastTarget"
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

local function buildDecor(folder: Folder, style: ZoneStyle)
	local rng = Random.new(style.seed)
	local origin = style.origin
	for index = 1, 16 do
		-- arboles en la parte de tierra (z > 20) y a los lados
		local x = rng:NextNumber(-80, 80)
		local z = rng:NextNumber(20, 85)
		if math.abs(x) < 8 and z < 40 then
			x += 20
		end
		local height = rng:NextNumber(7, 11)
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

local function buildZone(world: Folder, style: ZoneStyle)
	local folder = Instance.new("Folder")
	folder.Name = style.id
	newPart(
		folder,
		"Ground",
		Vector3.new(200, 4, 200),
		style.origin + Vector3.new(0, -2, 0),
		style.groundColor,
		style.groundMaterial
	)
	buildWater(folder, style)
	buildPier(folder, style)
	buildSign(folder, style)
	buildDecor(folder, style)
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
]]
function WorldBuilder.build(zones: { { id: string, name: string, nameKey: string } }): WorldInfo
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
			seed = 33,
		},
	}

	local info: WorldInfo = { spawns = {}, castTargets = {} }
	for _, zone in zones do
		local style = styles[zone.id]
		if style then
			style.name = zone.name
			style.nameKey = zone.nameKey
			buildZone(world, style)
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
