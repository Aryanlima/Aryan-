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

-- Detalle visual: anclado, sin colision ni sombra (barato en movil).
local function deco(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?
): Part
	local part = newPart(parent, name, size, position, color, material)
	part.CanCollide = false
	part.CanQuery = false
	part.CastShadow = false
	if shape then
		part.Shape = shape
	end
	return part
end

-- Roca grande: Terrain.FillBall (gratis en Parts); si Terrain falla (pruebas) cae a una Part esferica.
local function rockBall(
	parent: Instance,
	name: string,
	center: Vector3,
	radius: number,
	color: Color3,
	material: Enum.Material
)
	local ok = pcall(function()
		Workspace.Terrain:FillBall(center, radius, material)
	end)
	if not ok then
		local d = radius * 2
		local rock = deco(parent, name, Vector3.new(d, d, d), center, color, material, Enum.PartType.Ball)
		rock.CanCollide = true
	end
end

-- Palmera procedural: tronco inclinado y 6 hojas caidas. Devuelve la primera hoja (hace de "copa").
local function buildPalm(parent: Instance, tag: string, base: Vector3, height: number, leaf: Color3): Instance
	local lean = math.sin(#tag * 2.3 + (tonumber(tag) or 0) * 1.7) * 0.14
	local trunk = newPart(
		parent,
		(if tonumber(tag) then "TreeTrunk" else "PalmTrunk") .. tag,
		Vector3.new(1.3, height, 1.3),
		base,
		Color3.fromRGB(150, 118, 80),
		Enum.Material.Wood
	)
	trunk.CFrame = CFrame.new(base) * CFrame.Angles(0, 0, lean) * CFrame.new(0, height / 2, 0)
	trunk.CastShadow = false
	local top = base + Vector3.new(-math.sin(lean) * height, math.cos(lean) * height, 0)
	local first: Instance = trunk
	for frond = 0, 5 do
		local part = deco(
			parent,
			(if tonumber(tag) then "TreeCrown" else "PalmFrond") .. tag,
			Vector3.new(9, 0.3, 2.6),
			top,
			leaf,
			Enum.Material.Grass
		)
		part.CFrame = CFrame.new(top)
			* CFrame.Angles(0, frond * math.pi / 3 + (tonumber(tag) or 0), 0)
			* CFrame.Angles(0, 0, -0.4)
			* CFrame.new(4.2, 0, 0)
		if frond == 0 then
			first = part
		end
	end
	return first
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
			if style.id == "coast" then
				return buildPalm(folder, tostring(index), origin + Vector3.new(x, 0, z), height * 1.8, style.treeColor)
			end
			local river = style.id == "river"
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
				if river then Vector3.new(7, height * 1.1, 7) else Vector3.new(9, 9, 9),
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

local WHITE = Color3.fromRGB(240, 248, 250)

-- Rio de montana: rocas (Terrain) en orillas y agua, pinos densos azul-verdosos, cascada al fondo, puente de troncos, niebla.
local function buildRiverTheme(folder: Folder, style: ZoneStyle)
	local o = style.origin
	local rng = Random.new(style.seed + 500)
	local rockColor = Color3.fromRGB(96, 108, 118)
	for i = 1, 18 do -- orillas (fuera del agua, |x| > 33)
		local side = if i % 2 == 0 then 1 else -1
		local r = rng:NextNumber(2.5, 5.5)
		local pos = o + Vector3.new(side * rng:NextNumber(33, 42), r * 0.3, rng:NextNumber(-115, 30))
		rockBall(folder, "Boulder" .. i, pos, r, rockColor, Enum.Material.Slate)
	end
	for i = 1, 10 do -- dentro del agua, lejos del carril central de pesca (|x| >= 13)
		local side = if i % 2 == 0 then 1 else -1
		local r = rng:NextNumber(1.8, 3.4)
		local pos = o + Vector3.new(side * rng:NextNumber(13, 27), 0.2, rng:NextNumber(-118, -20))
		rockBall(folder, "WaterRock" .. i, pos, r, rockColor, Enum.Material.Rock)
		local foam = deco(
			folder,
			"Foam" .. i,
			Vector3.new(0.2, r * 2.8, r * 2.8),
			pos + Vector3.new(0, 0.45 - 0.2, 0),
			WHITE,
			Enum.Material.SmoothPlastic
		)
		foam.CFrame = CFrame.new(pos.X, 0.65, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
		foam.Transparency = 0.4
	end
	for i = 1, 26 do -- pinos extra (azul-verdosos, dos tonos)
		local x, z
		if rng:NextNumber() < 0.5 then
			x, z = rng:NextNumber(-90, 90), rng:NextNumber(22, 95)
			if math.abs(x) < 10 and z < 40 then
				x += 22
			end
		else
			x, z = (if i % 2 == 0 then 1 else -1) * rng:NextNumber(38, 92), rng:NextNumber(-95, 20)
		end
		local h = rng:NextNumber(8, 14)
		deco(
			folder,
			"Conifer" .. i,
			Vector3.new(1.6, h, 1.6),
			o + Vector3.new(x, h / 2, z),
			Color3.fromRGB(96, 74, 56),
			Enum.Material.Wood
		)
		local tone = if i % 2 == 0 then Color3.fromRGB(32, 98, 92) else Color3.fromRGB(44, 118, 110)
		deco(
			folder,
			"ConiferCrown" .. i,
			Vector3.new(7, h * 1.1, 7),
			o + Vector3.new(x, h + 2, z),
			tone,
			Enum.Material.Grass,
			Enum.PartType.Ball
		)
	end
	-- cascada al fondo (el agua acaba en z = -125)
	deco(folder, "FallsCliff", Vector3.new(90, 22, 10), o + Vector3.new(0, 9, -132), rockColor, Enum.Material.Slate)
	local sheet = deco(
		folder,
		"FallsWater",
		Vector3.new(22, 16, 1.5),
		o + Vector3.new(0, 9, -126.4),
		style.waterColor,
		Enum.Material.Glass
	)
	sheet.Transparency = 0.25
	for i, x in { -6, 0, 7 } do
		local streak = deco(
			folder,
			"FallsFoam" .. i,
			Vector3.new(1.8, 15, 0.4),
			o + Vector3.new(x, 9, -125.5),
			WHITE,
			Enum.Material.SmoothPlastic
		)
		streak.Transparency = 0.3
	end
	local plunge = deco(
		folder,
		"FallsPlunge",
		Vector3.new(26, 0.6, 8),
		o + Vector3.new(0, 0.7, -121),
		WHITE,
		Enum.Material.SmoothPlastic
	)
	plunge.Transparency = 0.35
	for i, x in { -14, 4, 16 } do -- niebla suave
		local mist = deco(
			folder,
			"Mist" .. i,
			Vector3.new(40, 7, 18),
			o + Vector3.new(x, 4, -112 + i * 5),
			WHITE,
			Enum.Material.SmoothPlastic
		)
		mist.Transparency = 0.9
	end
	-- puente de troncos (cruza el rio en z = -95; cubierta baja y pisable)
	for i = 0, 5 do
		local log = deco(
			folder,
			"BridgeLog" .. i,
			Vector3.new(76, 1.6, 1.6),
			o + Vector3.new(0, 1, -95 + (i - 2.5) * 1.7),
			Color3.fromRGB(104, 76, 52),
			Enum.Material.Wood,
			Enum.PartType.Cylinder
		)
		log.CanCollide = true
	end
	for _, side in { -1, 1 } do
		deco(
			folder,
			"BridgeRail",
			Vector3.new(76, 0.8, 0.8),
			o + Vector3.new(0, 3.6, -95 + side * 5.2),
			Color3.fromRGB(88, 64, 44),
			Enum.Material.Wood,
			Enum.PartType.Cylinder
		)
		for _, x in { -34, -17, 0, 17, 34 } do
			deco(
				folder,
				"BridgePost",
				Vector3.new(0.9, 7, 0.9),
				o + Vector3.new(x, 1, -95 + side * 5.2),
				Color3.fromRGB(88, 64, 44),
				Enum.Material.Wood
			)
		end
	end
end

-- Costa: palmeras extra altas, conchas, estrellas de mar, rocas de playa, faro en una isla, gaviotas y sol bajo.
local function buildCoastTheme(folder: Folder, style: ZoneStyle)
	local o = style.origin
	local rng = Random.new(style.seed + 500)
	for i = 1, 14 do
		local x, z = rng:NextNumber(-88, 88), rng:NextNumber(20, 85)
		if math.abs(x) < 10 and z < 40 then
			x += 22
		end
		buildPalm(folder, "Palm" .. i, o + Vector3.new(x, 0, z), rng:NextNumber(15, 22), style.treeColor)
	end
	for i = 1, 36 do
		local x = rng:NextNumber(-85, 85)
		if math.abs(x) < 9 then
			x += 18
		end
		local shell = deco(
			folder,
			"Shell" .. i,
			Vector3.new(0.9, 0.5, 0.9),
			o + Vector3.new(x, 0.25, rng:NextNumber(-17, 36)),
			if i % 2 == 0 then Color3.fromRGB(250, 238, 222) else Color3.fromRGB(240, 190, 180),
			Enum.Material.SmoothPlastic,
			Enum.PartType.Ball
		)
		shell.Name = "Shell" .. i
	end
	for i = 1, 10 do
		local x = rng:NextNumber(-80, 80)
		if math.abs(x) < 9 then
			x += 18
		end
		local at = o + Vector3.new(x, 0.12, rng:NextNumber(-15, 34))
		for arm = 0, 2 do
			local bar = deco(
				folder,
				"Starfish" .. i,
				Vector3.new(2.4, 0.2, 0.6),
				at,
				Color3.fromRGB(235, 120, 70),
				Enum.Material.SmoothPlastic
			)
			bar.CFrame = CFrame.new(at) * CFrame.Angles(0, arm * math.pi / 3, 0)
		end
	end
	for i = 1, 8 do
		local x = (if i % 2 == 0 then 1 else -1) * rng:NextNumber(20, 85)
		local r = rng:NextNumber(1.6, 3.2)
		rockBall(
			folder,
			"BeachRock" .. i,
			o + Vector3.new(x, r * 0.3, rng:NextNumber(-18, 30)),
			r,
			Color3.fromRGB(165, 156, 142),
			Enum.Material.Rock
		)
	end
	-- faro en una isla al fondo del mar (z = -108, fuera del carril de pesca)
	local base = o + Vector3.new(52, 0, -108)
	deco(
		folder,
		"LighthouseIsland",
		Vector3.new(4, 24, 24),
		base + Vector3.new(0, 0.8, 0),
		style.groundColor,
		Enum.Material.Sand,
		Enum.PartType.Cylinder
	).CFrame = CFrame.new(
		base + Vector3.new(0, 0.8, 0)
	) * CFrame.Angles(0, 0, math.rad(90))
	for i = 0, 3 do
		local seg = deco(
			folder,
			"LighthouseBody" .. i,
			Vector3.new(5, 4.6 - i * 0.3, 4.6 - i * 0.3),
			base + Vector3.new(0, 4.8 + i * 5, 0),
			if i % 2 == 0 then Color3.fromRGB(235, 70, 60) else Color3.fromRGB(245, 245, 240),
			Enum.Material.SmoothPlastic,
			Enum.PartType.Cylinder
		)
		seg.CFrame = CFrame.new(base + Vector3.new(0, 4.8 + i * 5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	end
	local lamp = deco(
		folder,
		"LighthouseLamp",
		Vector3.new(2.6, 3.2, 3.2),
		base + Vector3.new(0, 24.4, 0),
		Color3.fromRGB(255, 235, 150),
		Enum.Material.Neon,
		Enum.PartType.Cylinder
	)
	lamp.CFrame = CFrame.new(base + Vector3.new(0, 24.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local roof = deco(
		folder,
		"LighthouseRoof",
		Vector3.new(1.6, 4.6, 4.6),
		base + Vector3.new(0, 26.4, 0),
		Color3.fromRGB(90, 40, 40),
		Enum.Material.SmoothPlastic,
		Enum.PartType.Cylinder
	)
	roof.CFrame = CFrame.new(base + Vector3.new(0, 26.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
	for i = 1, 4 do
		local r = rng:NextNumber(2, 3.6)
		local a = i * 1.6
		rockBall(
			folder,
			"IslandRock" .. i,
			base + Vector3.new(math.cos(a) * 11, r * 0.3, math.sin(a) * 11),
			r,
			Color3.fromRGB(150, 145, 140),
			Enum.Material.Rock
		)
	end
	-- sol bajo y calido sobre el horizonte
	deco(
		folder,
		"SunGlow",
		Vector3.new(70, 70, 70),
		o + Vector3.new(-140, 20, -330),
		Color3.fromRGB(255, 170, 100),
		Enum.Material.Neon,
		Enum.PartType.Ball
	).Transparency =
		0.85
	deco(
		folder,
		"Sun",
		Vector3.new(34, 34, 34),
		o + Vector3.new(-140, 20, -330),
		Color3.fromRGB(255, 205, 130),
		Enum.Material.Neon,
		Enum.PartType.Ball
	)
	-- 3 gaviotas lejanas, animadas con Tween (solo si existe `task`; todo en pcall)
	local gulls = {}
	for i = 1, 3 do
		table.insert(
			gulls,
			deco(
				folder,
				"Gull" .. i,
				Vector3.new(3, 0.3, 1.1),
				o + Vector3.new(-50 + i * 30, 34 + i * 4, -70 - i * 8),
				WHITE,
				Enum.Material.SmoothPlastic
			)
		)
	end
	if typeof(task) == "table" then
		task.defer(function()
			pcall(function()
				local tweens = game:GetService("TweenService")
				for i, gull in gulls do
					local from = gull.Position
					local tween = tweens:Create(
						gull,
						TweenInfo.new(14 + i * 3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
						{
							CFrame = CFrame.new(from + Vector3.new(70 - i * 20, 6, 10))
								* CFrame.Angles(0, math.rad(20 * i), 0),
						}
					)
					tween:Play()
				end
			end)
		end)
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
	if style.id == "river" then
		buildRiverTheme(folder, style)
	elseif style.id == "coast" then
		buildCoastTheme(folder, style)
	end
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
			groundColor = Color3.fromRGB(88, 126, 108),
			groundMaterial = Enum.Material.Grass,
			waterColor = Color3.fromRGB(90, 200, 215),
			waterShape = "river",
			treeColor = Color3.fromRGB(36, 104, 98),
			treeArt = "pine_tree",
			seed = 22,
		},
		coast = {
			id = "coast",
			name = "",
			nameKey = "",
			origin = Vector3.new(800, 0, 0),
			groundColor = Color3.fromRGB(248, 234, 190),
			groundMaterial = Enum.Material.Sand,
			waterColor = Color3.fromRGB(40, 130, 200),
			waterShape = "sea",
			treeColor = Color3.fromRGB(120, 190, 70),
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
