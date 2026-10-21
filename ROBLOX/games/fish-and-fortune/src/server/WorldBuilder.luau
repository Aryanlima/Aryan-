--!strict
--[[
	WorldBuilder: construye el mundo de Fish & Fortune POR CODIGO (partes simples, colores agradables,
	iluminacion). No hay arte: este modulo es el unico sitio a sustituir cuando haya mapa generado con IA
	(ver README, "Que falta"). Contrato con el resto del juego:

	  Workspace.World/<zona>/Spawn        Part invisible: donde aparece el jugador al viajar a la zona
	  Workspace.World/<zona>/CastTarget   Part invisible sobre el agua: donde cae el flotador
	  Workspace.World/<zona>/Sign         cartel con el nombre (SurfaceGui)

	Si un mapa nuevo respeta ese contrato (y el servidor lee `build()`), nada mas cambia.

	ARTE GENERADO (opcional): `build(zonas, art)` recibe el proveedor de arte (packages/Art). Muelle, farolas, barca y
	arboles aceptan modelos generados y conservan respaldo procedural. MaterialVariants opcionales se aplican al muelle
	y a un portador invisible para el suelo; el terreno visible siempre usa Terrain. La cubierta del muelle mantiene su
	colision y altura propias. Sin `art`, todos los elementos se construyen proceduralmente.
]]

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
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

local function detail(part: Part): Part
	part.CanCollide = false
	part.CastShadow = false
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

-- El fondo del lago es de arena clara (no barro): asi el agua se ve turquesa y no turbia.
local function buildWater(folder: Folder, style: ZoneStyle)
	local origin = style.origin
	local terrain: any = Workspace.Terrain
	local function callTerrain(methodName: string, ...: any)
		local ok, method = pcall(function()
			return terrain[methodName]
		end)
		if ok and type(method) == "function" then
			method(terrain, ...)
		end
	end
	-- Orden: orilla de arena y fondo de barro (sin sobresalir del suelo, y = 0), se VACIA con Air (el agua no
	-- reemplaza tierra solida) y se llena de agua a ras de suelo. El muelle (cubierta a y = 1.2) queda por encima.
	if style.waterShape == "disc" then
		local center = origin + Vector3.new(0, 0, -45)
		callTerrain("FillCylinder", CFrame.new(center + Vector3.new(0, -4, 0)), 8, 65, Enum.Material.Sand)
		callTerrain("FillCylinder", CFrame.new(center + Vector3.new(0, -4, 0)), 8, 58, Enum.Material.Sand)
		callTerrain("FillCylinder", CFrame.new(center + Vector3.new(0, -2, 0)), 8, 55, Enum.Material.Air)
		callTerrain("FillCylinder", CFrame.new(center + Vector3.new(0, -3, 0)), 6, 55, Enum.Material.Water)
		-- tierra firme bajo la entrada del muelle (si no, el muelle empieza dentro del agua)
		callTerrain("FillBlock", CFrame.new(origin + Vector3.new(0, -4, 4)), Vector3.new(14, 8, 16), Enum.Material.Sand)
	elseif style.waterShape == "river" then
		local center = origin + Vector3.new(0, 0, -40)
		callTerrain(
			"FillBlock",
			CFrame.new(center + Vector3.new(0, -4, 0)),
			Vector3.new(78, 8, 188),
			Enum.Material.Sand
		)
		callTerrain(
			"FillBlock",
			CFrame.new(center + Vector3.new(0, -4, 0)),
			Vector3.new(68, 8, 184),
			Enum.Material.Sand
		)
		callTerrain("FillBlock", CFrame.new(center + Vector3.new(0, -2, 0)), Vector3.new(60, 8, 170), Enum.Material.Air)
		callTerrain(
			"FillBlock",
			CFrame.new(center + Vector3.new(0, -3, 0)),
			Vector3.new(60, 6, 170),
			Enum.Material.Water
		)
		-- calzada de tierra por el centro del rio hasta el muelle (el aparicion esta dentro del rio)
		callTerrain(
			"FillBlock",
			CFrame.new(origin + Vector3.new(0, -4, 8.5)),
			Vector3.new(14, 8, 77),
			Enum.Material.Sand
		)
	else
		-- Mar abierto: la orilla sigue en z = -20 (canFishAt) y el agua se extiende hasta el horizonte.
		local center = origin + Vector3.new(0, 0, -200)
		callTerrain(
			"FillBlock",
			CFrame.new(center + Vector3.new(0, -4, 0)),
			Vector3.new(560, 8, 372),
			Enum.Material.Sand
		)
		callTerrain(
			"FillBlock",
			CFrame.new(center + Vector3.new(0, -4, 0)),
			Vector3.new(552, 8, 366),
			Enum.Material.Sand
		)
		callTerrain(
			"FillBlock",
			CFrame.new(center + Vector3.new(0, -2, 0)),
			Vector3.new(540, 8, 360),
			Enum.Material.Air
		)
		callTerrain(
			"FillBlock",
			CFrame.new(center + Vector3.new(0, -3, 0)),
			Vector3.new(540, 6, 360),
			Enum.Material.Water
		)
	end
	local _ = folder
end

local PIER_WOOD = Color3.fromRGB(128, 80, 47)

-- Muelle procedural de siempre (respaldo del arte "pier"): cubierta + postes.
local function buildProceduralPier(folder: Folder, style: ZoneStyle, art: ArtLike?)
	local darkWood = Color3.fromRGB(76, 52, 39)
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
		detail(
			newPart(
				folder,
				"PierPost",
				Vector3.new(1.2, 5, 1.2),
				origin + Vector3.new(-3.6, 0.5, z),
				darkWood,
				Enum.Material.Wood
			)
		)
		detail(
			newPart(
				folder,
				"PierPost",
				Vector3.new(1.2, 5, 1.2),
				origin + Vector3.new(3.6, 0.5, z),
				darkWood,
				Enum.Material.Wood
			)
		)
	end
	for index = 0, 8 do
		detail(
			newPart(
				folder,
				"DeckPlank",
				Vector3.new(7.7, 0.12, 4.8),
				origin + Vector3.new(0, 1.76, -39 + index * 5.2),
				Color3.fromRGB(128 + (index % 2) * 8, 80 + (index % 2) * 5, 47),
				Enum.Material.WoodPlanks
			)
		)
	end
	for _, side in { -1, 1 } do
		for index = 0, 3 do
			local z = -35 + index * 11
			local railPost = detail(
				newPart(
					folder,
					"PierRailPost",
					Vector3.new(0.55, 3.2, 0.55),
					origin + Vector3.new(side * 3.55, 3.2, z),
					darkWood,
					Enum.Material.Wood
				)
			)
			railPost.CanCollide = true
		end
		local rail = detail(
			newPart(
				folder,
				"PierRail",
				Vector3.new(0.45, 0.45, 34),
				origin + Vector3.new(side * 3.55, 4.55, -18.5),
				PIER_WOOD,
				Enum.Material.WoodPlanks
			)
		)
		rail.CanCollide = true
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

-- El arte puede sustituir las farolas y la barca; si falta se construyen piezas locales.
local function buildArtOnlyProps(folder: Folder, style: ZoneStyle, art: ArtLike?)
	local origin = style.origin
	local index = 0
	for _, z in { -34, -20, -6 } do
		for _, side in { -1, 1 } do
			index += 1
			local function fallback(parent: Instance, cf: CFrame): Instance?
				local pole = detail(
					newPart(
						parent,
						"LanternPost",
						Vector3.new(0.35, 3.4, 0.35),
						cf.Position + Vector3.new(0, 1.7, 0),
						Color3.fromRGB(77, 55, 42),
						Enum.Material.Wood
					)
				)
				local bulb = detail(
					newPart(
						parent,
						"LanternBulb",
						Vector3.new(1.1, 1.1, 1.1),
						cf.Position + Vector3.new(0, 3.65, 0),
						Color3.fromRGB(255, 200, 61),
						Enum.Material.Glass
					)
				)
				bulb.Shape = Enum.PartType.Ball
				local light = Instance.new("PointLight")
				light.Color = Color3.fromRGB(255, 194, 103)
				light.Brightness = 1.2
				light.Range = 18
				light.Parent = bulb
				return pole
			end
			if art ~= nil then
				art:place("props", "lantern", {
					parent = folder,
					cframe = CFrame.new(origin + Vector3.new(side * 3.5, 1.7, z)),
					name = "Lantern" .. index,
					fallback = fallback,
				})
			else
				fallback(folder, CFrame.new(origin + Vector3.new(side * 3.5, 1.7, z)))
			end
		end
	end
	local function boatFallback(parent: Instance, cf: CFrame): Instance?
		local hull = detail(
			newPart(
				parent,
				"RowboatHull",
				Vector3.new(4.5, 1, 9),
				cf.Position,
				Color3.fromRGB(139, 82, 45),
				Enum.Material.WoodPlanks
			)
		)
		for _, side in { -1, 1 } do
			detail(
				newPart(
					parent,
					"BoatGunwale",
					Vector3.new(0.35, 1.3, 9),
					cf.Position + Vector3.new(side * 2.1, 0.7, 0),
					Color3.fromRGB(201, 138, 75),
					Enum.Material.WoodPlanks
				)
			)
		end
		return hull
	end
	local boatCFrame = CFrame.new(origin + Vector3.new(-10, -0.4, -30)) * CFrame.Angles(0, math.rad(20), 0)
	if art ~= nil then
		art:place("props", "rowboat", {
			parent = folder,
			cframe = boatCFrame,
			name = "Rowboat",
			fallback = boatFallback,
		})
	else
		boatFallback(folder, boatCFrame)
	end
	local rope = detail(
		newPart(
			folder,
			"MooringRope",
			Vector3.new(0.16, 0.16, 8),
			origin + Vector3.new(-6, 0.5, -30),
			Color3.fromRGB(105, 81, 58),
			Enum.Material.Fabric
		)
	)
	rope.CFrame = CFrame.new(rope.Position) * CFrame.Angles(0, math.rad(90), math.rad(12))
	local cargoX = if style.waterShape == "river" then 34 else 14
	for crateIndex = 1, 3 do
		local crate = detail(
			newPart(
				folder,
				"FishCrate",
				Vector3.new(2.4, 2, 2.4),
				origin + Vector3.new(cargoX + (crateIndex % 2) * 2.5, 1, 5 + crateIndex * 2.5),
				Color3.fromRGB(158, 105, 61),
				Enum.Material.WoodPlanks
			)
		)
		crate.CFrame = CFrame.new(crate.Position) * CFrame.Angles(0, math.rad(crateIndex * 9), 0)
	end
	for barrelIndex = 1, 2 do
		local barrel = detail(
			newPart(
				folder,
				"Barrel",
				Vector3.new(1.8, 2.4, 1.8),
				origin + Vector3.new(cargoX + 2, 1.2, 8 + barrelIndex * 3),
				Color3.fromRGB(128, 83, 49),
				Enum.Material.Wood
			)
		)
		barrel.Shape = Enum.PartType.Cylinder
		barrel.CFrame = CFrame.new(barrel.Position) * CFrame.Angles(0, 0, math.rad(90))
	end
end

local function buildSign(folder: Folder, style: ZoneStyle)
	local post = detail(
		newPart(
			folder,
			"Sign",
			Vector3.new(8, 3.2, 0.6),
			style.origin + Vector3.new(12, 4, 8),
			Color3.fromRGB(60, 45, 35),
			Enum.Material.Wood
		)
	)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back -- el jugador llega desde +Z: la cara visible es la de atras
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
	local arrow = detail(
		newPart(
			folder,
			"FishHereSign",
			Vector3.new(6, 1.6, 0.7),
			style.origin + Vector3.new(12, 6.4, 8),
			Color3.fromRGB(255, 90, 95),
			Enum.Material.SmoothPlastic
		)
	)
	local arrowGui = Instance.new("SurfaceGui")
	arrowGui.Face = Enum.NormalId.Back
	arrowGui.PixelsPerStud = 32
	local arrowLabel = Instance.new("TextButton")
	arrowLabel.Size = UDim2.fromScale(1, 1)
	arrowLabel.BackgroundTransparency = 1
	arrowLabel.Active = false
	arrowLabel.Text = "← Fish here!"
	arrowLabel.TextColor3 = Color3.new(1, 1, 1)
	arrowLabel.Font = Enum.Font.GothamBlack
	arrowLabel.TextScaled = true
	arrowLabel.Parent = arrowGui
	arrowGui.Parent = arrow
	detail(
		newPart(
			folder,
			"SignLegs",
			Vector3.new(1, 4, 1),
			style.origin + Vector3.new(12, 2, 7.6),
			Color3.fromRGB(60, 45, 35),
			Enum.Material.Wood
		)
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
			local trunk = detail(
				newPart(
					folder,
					"TreeTrunk" .. index,
					Vector3.new(2, height, 2),
					origin + Vector3.new(x, height / 2, z),
					Color3.fromRGB(110, 78, 50),
					Enum.Material.Wood
				)
			)
			trunk.CanCollide = false
			if style.treeArt == "palm_tree" then
				for frond = 1, 6 do
					local angle = math.rad((frond - 1) * 60)
					local leaf = detail(
						newPart(
							folder,
							"PalmFrond",
							Vector3.new(1.1, 0.5, 7),
							origin + Vector3.new(x + math.cos(angle) * 2.2, height + 1, z + math.sin(angle) * 2.2),
							Color3.fromRGB(42 + frond * 3, 132 + frond * 4, 78),
							Enum.Material.Grass
						)
					)
					leaf.CFrame = CFrame.new(leaf.Position) * CFrame.Angles(math.rad(-20), -angle, math.rad(12))
				end
				return trunk
			end
			local crown = detail(
				newPart(
					folder,
					"TreeCrown" .. index,
					Vector3.new(9, 9, 9),
					origin + Vector3.new(x, height + 3, z),
					style.treeColor,
					Enum.Material.Grass
				)
			)
			crown.Shape = Enum.PartType.Ball
			for cluster = 1, 3 do
				local canopyColor = if cluster == 1
					then style.treeColor
					else Color3.fromRGB(70 + cluster * 15, 126 + cluster * 8, 62 + cluster * 6)
				local canopy = detail(
					newPart(
						folder,
						"TreeCanopy" .. index,
						Vector3.new(6.4, 6.4, 6.4),
						origin
							+ Vector3.new(
								x + (cluster - 2) * 2.5,
								height + 2 + (cluster % 2) * 1.3,
								z + (cluster % 2) * 1.8
							),
						canopyColor,
						Enum.Material.Grass
					)
				)
				canopy.Shape = Enum.PartType.Ball
			end
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
	for _ = 1, 10 do
		local x = rng:NextNumber(-85, 85)
		local z = rng:NextNumber(14, 88)
		local size = rng:NextNumber(2, 5)
		local terrain: any = Workspace.Terrain
		local hasFillBall, fillBall = pcall(function()
			return terrain.FillBall
		end)
		if hasFillBall and type(fillBall) == "function" then
			fillBall(terrain, origin + Vector3.new(x, size / 2 - 0.3, z), size, Enum.Material.Rock)
		end
	end
	for index = 1, 12 do
		local x, z = rng:NextNumber(-86, 86), rng:NextNumber(18, 90)
		local bush = detail(
			newPart(
				folder,
				"Bush" .. index,
				Vector3.new(3.4, 2.8, 3.4),
				origin + Vector3.new(x, 1.2, z),
				Color3.fromRGB(46, 113 + (index % 3) * 12, 67),
				Enum.Material.Grass
			)
		)
		bush.Shape = Enum.PartType.Ball
		for bloom = 1, 2 do
			local flower = detail(
				newPart(
					folder,
					"Flower" .. index,
					Vector3.new(0.45, 0.45, 0.45),
					origin + Vector3.new(x + bloom * 0.6, 2.2, z + 0.4),
					if bloom == 1 then Color3.fromRGB(255, 90, 95) else Color3.fromRGB(255, 200, 61),
					Enum.Material.Neon
				)
			)
			flower.Shape = Enum.PartType.Ball
		end
	end
end

-- Detalle visual barato: sin colision, consulta ni sombra.
local function deco(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?
): Part
	local part = detail(newPart(parent, name, size, position, color, material))
	part.CanQuery = false
	if shape then
		part.Shape = shape
	end
	return part
end

-- Roca grande de Terrain (gratis en Parts); si Terrain no existe (pruebas) cae a una esfera.
local function rockBall(
	parent: Instance,
	name: string,
	center: Vector3,
	radius: number,
	color: Color3,
	material: Enum.Material
)
	local terrain: any = Workspace.Terrain
	local ok = pcall(function()
		terrain:FillBall(center, radius, material)
	end)
	if not ok then
		deco(parent, name, Vector3.one * radius * 2, center, color, material, Enum.PartType.Ball)
	end
end

local WHITE = Color3.fromRGB(240, 248, 250)
local THEME_WOOD = Color3.fromRGB(104, 76, 52)

-- Rio de montana: rocas en orillas y agua, pinos azul-verdosos, cascada al fondo (el agua acaba en z = -125), niebla y puente.
local function buildRiverTheme(folder: Folder, style: ZoneStyle)
	local o = style.origin
	local rng = Random.new(style.seed + 500)
	local rockColor = Color3.fromRGB(96, 108, 118)
	for i = 1, 12 do -- orillas (|x| > 33, fuera del agua)
		local r = rng:NextNumber(2.5, 5)
		local x = (if i % 2 == 0 then 1 else -1) * rng:NextNumber(35, 44)
		rockBall(
			folder,
			"Boulder" .. i,
			o + Vector3.new(x, r * 0.3, rng:NextNumber(-115, 30)),
			r,
			rockColor,
			Enum.Material.Slate
		)
	end
	for i = 1, 6 do -- en el agua, lejos del muelle y del carril de pesca central (|x| >= 13)
		local r = rng:NextNumber(1.8, 3)
		local x = (if i % 2 == 0 then 1 else -1) * rng:NextNumber(13, 26)
		local pos = o + Vector3.new(x, 0.2, rng:NextNumber(-118, -60))
		rockBall(folder, "WaterRock" .. i, pos, r, rockColor, Enum.Material.Rock)
		local foam =
			deco(folder, "Foam" .. i, Vector3.new(0.2, r * 2.8, r * 2.8), pos, WHITE, nil, Enum.PartType.Cylinder)
		foam.CFrame = CFrame.new(pos.X, 0.15, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
		foam.Transparency = 0.4
	end
	for i = 1, 16 do -- pinos extra en dos tonos, en tierra (nunca en el agua ni en la calzada)
		local x, z
		if i % 2 == 0 then
			x, z = rng:NextNumber(-90, 90), rng:NextNumber(52, 95)
		else
			x, z = (if i % 4 == 1 then 1 else -1) * rng:NextNumber(38, 92), rng:NextNumber(-95, 40)
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
		deco(
			folder,
			"ConiferCrown" .. i,
			Vector3.new(7, h * 1.1, 7),
			o + Vector3.new(x, h + 2, z),
			if i % 3 == 0 then Color3.fromRGB(32, 98, 92) else Color3.fromRGB(44, 118, 110),
			Enum.Material.Grass,
			Enum.PartType.Ball
		)
	end
	-- cascada: risco de roca, lamina de agua, estrias de espuma y remolino al pie
	local cliff =
		deco(folder, "FallsCliff", Vector3.new(90, 22, 10), o + Vector3.new(0, 9, -132), rockColor, Enum.Material.Slate)
	cliff.CanCollide = true
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
		deco(folder, "FallsFoam" .. i, Vector3.new(1.8, 15, 0.4), o + Vector3.new(x, 9, -125.5), WHITE).Transparency =
			0.3
	end
	deco(folder, "FallsPlunge", Vector3.new(26, 0.2, 8), o + Vector3.new(0, 0.2, -121), WHITE).Transparency = 0.35
	for i, x in { -14, 4, 16 } do -- niebla suave
		deco(folder, "Mist" .. i, Vector3.new(40, 7, 18), o + Vector3.new(x, 4, -112 + i * 5), WHITE).Transparency = 0.9
	end
	-- puente de troncos en z = -95 (cubierta baja y pisable, barandas sin colision)
	for i = 0, 5 do
		local log = deco(
			folder,
			"BridgeLog" .. i,
			Vector3.new(76, 1.6, 1.6),
			o + Vector3.new(0, 1, -95 + (i - 2.5) * 1.7),
			THEME_WOOD,
			Enum.Material.Wood,
			Enum.PartType.Cylinder
		)
		log.CanCollide = true
	end
	for _, side in { -1, 1 } do
		local railAt = o + Vector3.new(0, 3.6, -95 + side * 5.2)
		deco(
			folder,
			"BridgeRail",
			Vector3.new(76, 0.8, 0.8),
			railAt,
			THEME_WOOD,
			Enum.Material.Wood,
			Enum.PartType.Cylinder
		)
		for _, x in { -34, -17, 0, 17, 34 } do
			deco(
				folder,
				"BridgePost",
				Vector3.new(0.9, 7, 0.9),
				o + Vector3.new(x, 1, -95 + side * 5.2),
				THEME_WOOD,
				Enum.Material.Wood
			)
		end
	end
end

-- Palmera extra: tronco inclinado y 4 hojas caidas.
local function buildPalm(folder: Folder, index: number, base: Vector3, height: number, leaf: Color3)
	local lean = math.sin(index * 2.3) * 0.14
	local trunk = deco(
		folder,
		"PalmTrunk" .. index,
		Vector3.new(1.3, height, 1.3),
		base,
		Color3.fromRGB(150, 118, 80),
		Enum.Material.Wood
	)
	trunk.CFrame = CFrame.new(base) * CFrame.Angles(0, 0, lean) * CFrame.new(0, height / 2, 0)
	local top = base + Vector3.new(-math.sin(lean) * height, math.cos(lean) * height, 0)
	for frond = 0, 3 do
		local part = deco(folder, "PalmLeaf" .. index, Vector3.new(9, 0.3, 2.6), top, leaf, Enum.Material.Grass)
		part.CFrame = CFrame.new(top)
			* CFrame.Angles(0, frond * math.pi / 2 + index, 0)
			* CFrame.Angles(0, 0, -0.4)
			* CFrame.new(4.2, 0, 0)
	end
end

-- Costa: palmeras altas, conchas, estrellas de mar, rocas de playa, faro en una isla del mar abierto y gaviotas.
local function buildCoastTheme(folder: Folder, style: ZoneStyle)
	local o = style.origin
	local rng = Random.new(style.seed + 500)
	local function beachX(range: number): number -- evita la entrada del muelle (|x| < 9)
		local x = rng:NextNumber(-range, range)
		return if math.abs(x) < 9 then x + 18 else x
	end
	for i = 1, 8 do
		buildPalm(
			folder,
			i,
			o + Vector3.new(beachX(88), 0, rng:NextNumber(22, 85)),
			rng:NextNumber(15, 22),
			style.treeColor
		)
	end
	for i = 1, 20 do
		deco(
			folder,
			"Shell" .. i,
			Vector3.new(0.9, 0.5, 0.9),
			o + Vector3.new(beachX(85), 0.25, rng:NextNumber(-12, 36)),
			if i % 2 == 0 then Color3.fromRGB(250, 238, 222) else Color3.fromRGB(240, 190, 180),
			nil,
			Enum.PartType.Ball
		)
	end
	for i = 1, 6 do
		local at = o + Vector3.new(beachX(80), 0.12, rng:NextNumber(-12, 34))
		for arm = 0, 2 do
			local bar = deco(folder, "Starfish" .. i, Vector3.new(2.4, 0.2, 0.6), at, Color3.fromRGB(235, 120, 70))
			bar.CFrame = CFrame.new(at) * CFrame.Angles(0, arm * math.pi / 3, 0)
		end
	end
	for i = 1, 6 do -- rocas de playa lejos del muelle y de la linea de pesca (z = -20)
		local r = rng:NextNumber(1.6, 3)
		local x = (if i % 2 == 0 then 1 else -1) * rng:NextNumber(20, 85)
		rockBall(
			folder,
			"BeachRock" .. i,
			o + Vector3.new(x, r * 0.3, rng:NextNumber(-4, 30)),
			r,
			Color3.fromRGB(165, 156, 142),
			Enum.Material.Rock
		)
	end
	-- faro en una isla del mar abierto (88 studs de la orilla, fuera del carril de pesca); el fondo marino esta en y = -6
	local base = o + Vector3.new(52, 0, -108)
	local island = deco(
		folder,
		"LighthouseIsland",
		Vector3.new(8, 24, 24),
		base + Vector3.new(0, -2, 0),
		style.groundColor,
		Enum.Material.Sand,
		Enum.PartType.Cylinder
	)
	island.CFrame = CFrame.new(base + Vector3.new(0, -2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	island.CanCollide = true
	local function tower(name: string, size: Vector3, y: number, color: Color3, material: Enum.Material)
		local part = deco(folder, name, size, base + Vector3.new(0, y, 0), color, material, Enum.PartType.Cylinder)
		part.CFrame = CFrame.new(base + Vector3.new(0, y, 0)) * CFrame.Angles(0, 0, math.rad(90))
	end
	for i = 0, 3 do
		local d = 4.6 - i * 0.3
		local color = if i % 2 == 0 then Color3.fromRGB(235, 70, 60) else Color3.fromRGB(245, 245, 240)
		tower("LighthouseBody" .. i, Vector3.new(5, d, d), 4.5 + i * 5, color, Enum.Material.SmoothPlastic)
	end
	tower("LighthouseLamp", Vector3.new(2.6, 3.2, 3.2), 24.1, Color3.fromRGB(255, 235, 150), Enum.Material.Neon)
	tower("LighthouseRoof", Vector3.new(1.6, 4.6, 4.6), 26.1, Color3.fromRGB(90, 40, 40), Enum.Material.SmoothPlastic)
	for i = 1, 4 do
		local r = rng:NextNumber(2, 3.6)
		local a = i * 1.6
		local at = base + Vector3.new(math.cos(a) * 11, r * 0.3, math.sin(a) * 11)
		rockBall(folder, "IslandRock" .. i, at, r, Color3.fromRGB(150, 145, 140), Enum.Material.Rock)
	end
	-- 3 gaviotas lejanas que van y vienen con un Tween infinito (en pcall: sin TweenService real no pasa nada)
	for i = 1, 3 do
		local gull = deco(
			folder,
			"Gull" .. i,
			Vector3.new(3, 0.3, 1.1),
			o + Vector3.new(-50 + i * 30, 34 + i * 4, -70 - i * 8),
			WHITE
		)
		pcall(function()
			local info = TweenInfo.new(14 + i * 3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			local goal = gull.CFrame * CFrame.new(70 - i * 20, 6, 10) * CFrame.Angles(0, math.rad(20 * i), 0)
			TweenService:Create(gull, info, { CFrame = goal }):Play()
		end)
	end
end

-- Siluetas frías al horizonte y nubes de bajo coste para ampliar visualmente cada zona.
local function buildHorizon(folder: Folder, style: ZoneStyle)
	local origin = style.origin
	local terrain: any = Workspace.Terrain
	-- Colinas lejanas de Terrain (pasto con cima de roca), parcialmente enterradas: se ven como relieve real.
	for index = 1, 7 do
		local side = if index % 2 == 0 then 1 else -1
		local x = side * (95 + (index % 3) * 22)
		local z = -112 - index * 10
		local radius = 26 + (index % 3) * 8
		pcall(function()
			terrain:FillBall(origin + Vector3.new(x, -6, z), radius, Enum.Material.Grass)
			terrain:FillBall(origin + Vector3.new(x, -6 + radius * 0.62, z), radius * 0.5, Enum.Material.Rock)
		end)
	end
	local _ = folder
end

-- Nubes reales de Terrain (una sola vez, compartidas por las zonas).
local function buildClouds()
	pcall(function()
		local terrain: any = Workspace.Terrain
		if terrain:FindFirstChildOfClass("Clouds") ~= nil then
			return
		end
		local clouds = Instance.new("Clouds")
		clouds.Cover = 0.55
		clouds.Density = 0.6
		clouds.Color = Color3.fromRGB(255, 245, 232)
		clouds.Parent = terrain
	end)
end

local function buildWildlife(folder: Folder, style: ZoneStyle)
	local origin = style.origin
	-- Solo un pez efímero a la vez por zona; Tween y Debris limitan trabajo y vida de las piezas.
	local scheduler: any = task
	if scheduler == nil then
		return -- entornos sin planificador (pruebas): sin animacion
	end
	local function alive(): boolean
		local parent: Instance? = folder.Parent
		return parent ~= nil
	end
	scheduler.spawn(function()
		while alive() do
			scheduler.wait(4.5)
			if not alive() then
				break
			end
			local fish = detail(
				newPart(
					folder,
					"JumpingFish",
					Vector3.new(1.8, 0.65, 0.55),
					origin + Vector3.new(math.random(-12, 12), 1, -48 - math.random(0, 18)),
					Color3.fromRGB(255, 196, 97),
					Enum.Material.SmoothPlastic
				)
			)
			fish.CanQuery = false
			local start = fish.CFrame
			fish.CFrame = start * CFrame.Angles(0, 0, math.rad(-18))
			local tween = TweenService:Create(
				fish,
				TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CFrame = start + Vector3.new(0, 5, 0) }
			)
			tween:Play()
			Debris:AddItem(fish, 1.8)
		end
	end)
	-- Partículas breves en dos puntos altos sugieren pájaros/libélulas sin emisores activos permanentes.
	for index = 1, 2 do
		local perch = detail(
			newPart(
				folder,
				"DistantWildlife",
				Vector3.new(0.3, 0.3, 0.3),
				origin + Vector3.new(-42 + index * 78, 15, -35),
				Color3.fromRGB(255, 226, 157),
				Enum.Material.SmoothPlastic
			)
		)
		perch.Transparency = 1
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "FireflyGlints"
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 130))
		emitter.LightEmission = 0.35
		emitter.Rate = 0.7
		emitter.Lifetime = NumberRange.new(1.5, 2.5)
		emitter.Speed = NumberRange.new(0.5, 1.2)
		emitter.SpreadAngle = Vector2.new(35, 35)
		emitter.Size = NumberSequence.new(0.14)
		emitter.Parent = perch
	end
end

local function buildZone(world: Folder, style: ZoneStyle, art: ArtLike?)
	local folder = Instance.new("Folder")
	folder.Name = style.id
	local groundMaterialCarrier = newPart(
		folder,
		"Ground",
		Vector3.new(200, 1, 200),
		style.origin + Vector3.new(0, -1, 0),
		style.groundColor,
		style.groundMaterial
	)
	groundMaterialCarrier.Transparency = 1
	groundMaterialCarrier.CanCollide = false
	groundMaterialCarrier.CanQuery = false
	groundMaterialCarrier.CanTouch = false
	applyVariant(groundMaterialCarrier, art, "ground_" .. style.id)
	local terrain: any = Workspace.Terrain
	local hasFillBlock, fillBlock = pcall(function()
		return terrain.FillBlock
	end)
	if hasFillBlock and type(fillBlock) == "function" then
		fillBlock(
			terrain,
			CFrame.new(style.origin + Vector3.new(0, -4, 0)),
			Vector3.new(200, 8, 200),
			style.groundMaterial
		)
	end
	buildWater(folder, style)
	buildPier(folder, style, art)
	buildHorizon(folder, style)
	buildSign(folder, style)
	buildDecor(folder, style, art)
	if style.id == "river" then
		buildRiverTheme(folder, style)
	elseif style.id == "coast" then
		buildCoastTheme(folder, style)
	end
	buildArtOnlyProps(folder, style, art)
	buildWildlife(folder, style)
	folder.Parent = world
end

local function setupLighting()
	Lighting.ClockTime = 16.3
	Lighting.Brightness = 2
	Lighting.ExposureCompensation = 0.1
	Lighting.Ambient = Color3.fromRGB(123, 145, 166)
	Lighting.OutdoorAmbient = Color3.fromRGB(169, 196, 211)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 240, 215)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.5
	local terrain = Workspace.Terrain
	terrain.WaterColor = Color3.fromRGB(28, 116, 178)
	terrain.WaterTransparency = 0.4
	terrain.WaterWaveSize = 0.16
	terrain.WaterWaveSpeed = 7
	terrain.WaterReflectance = 0.12
	local previousSky = Lighting:FindFirstChild("FishFortuneSky")
	if previousSky then
		previousSky:Destroy()
	end
	local sky = Instance.new("Sky")
	sky.Name = "FishFortuneSky"
	sky.CelestialBodiesShown = true
	sky.StarCount = 0
	sky.SunAngularSize = 14
	sky.Parent = Lighting

	local previousAtmosphere = Lighting:FindFirstChild("FishFortuneAtmosphere")
	if previousAtmosphere then
		previousAtmosphere:Destroy()
	end
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "FishFortuneAtmosphere"
	atmosphere.Density = 0.25
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(197, 232, 243)
	atmosphere.Decay = Color3.fromRGB(242, 201, 149)
	atmosphere.Glare = 0.15
	atmosphere.Haze = 1.2
	atmosphere.Parent = Lighting

	local previousCorrection = Lighting:FindFirstChild("FishFortuneColorCorrection")
	if previousCorrection then
		previousCorrection:Destroy()
	end
	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name = "FishFortuneColorCorrection"
	correction.Saturation = 0.08
	correction.Contrast = 0.04
	correction.TintColor = Color3.fromRGB(255, 239, 215)
	correction.Parent = Lighting

	local previousBloom = Lighting:FindFirstChild("FishFortuneBloom")
	if previousBloom then
		previousBloom:Destroy()
	end
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "FishFortuneBloom"
	bloom.Intensity = 0.18
	bloom.Size = 24
	bloom.Threshold = 1.4
	bloom.Parent = Lighting
	for _, effectName in { "FishFortuneSunRays", "FishFortuneDepthOfField" } do
		local oldEffect = Lighting:FindFirstChild(effectName)
		if oldEffect then
			oldEffect:Destroy()
		end
	end
	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Name = "FishFortuneSunRays"
	sunRays.Intensity = 0.035
	sunRays.Spread = 0.72
	sunRays.Parent = Lighting
	local depthOfField = Instance.new("DepthOfFieldEffect")
	depthOfField.Name = "FishFortuneDepthOfField"
	depthOfField.FarIntensity = 0.08
	depthOfField.NearIntensity = 0.04
	depthOfField.FocusDistance = 55
	depthOfField.InFocusRadius = 45
	depthOfField.Parent = Lighting
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

	buildClouds()
	setupLighting()
	return info
end

return WorldBuilder
