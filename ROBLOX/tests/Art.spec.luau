--!nonstrict
--[[
	Pruebas de packages/Art (arte intercambiable con respaldo). Usan instancias REALES de la libreria @lune/roblox
	(Instance.new("MeshPart"), Clone, atributos...) cargando el modulo con los tipos del motor (@testkit/engine).

	Cubren: con arte, sin arte, arte invalido (con script dentro -> se rechaza y se usa el respaldo), arte a medias,
	escala/orientacion/pivote, aislamiento de la plantilla, soldaduras, materiales, raices en orden e informe.
]]
local testkit = require("@testkit")
local Engine = require("@testkit/engine")

local describe, it, expect, beforeEach = testkit.describe, testkit.it, testkit.expect, testkit.beforeEach

local HERE = (debug.info(1, "s") :: string):gsub("[^/\\]+$", "")
local Art = Engine.load(HERE .. "../packages/Art.luau")
local Instance, Vector3, CFrame, Enum =
	Engine.roblox.Instance, Engine.roblox.Vector3, Engine.roblox.CFrame, Engine.roblox.Enum

----------------------------------------------------------------------------
-- Ayudantes
----------------------------------------------------------------------------

local function mesh(name, size, position, meshId)
	local part = Instance.new("MeshPart")
	part.Name = name or "Mesh"
	part.Size = size or Vector3.new(2, 4, 6)
	part.CFrame = CFrame.new(position or Vector3.new(0, 0, 0))
	if meshId ~= false then
		part.MeshId = meshId or "rbxassetid://12345"
	end
	return part
end

-- Modelo valido de una sola malla (como lo deja generate_mesh)
local function model(id, size)
	local m = Instance.new("Model")
	m.Name = id
	mesh("Body", size).Parent = m
	return m
end

local function profile(overrides)
	local p = {
		category = "creatures",
		id = "fish",
		targetSize = Vector3.new(1, 2, 3),
		fit = "contain",
		pivot = "center",
	}
	for key, value in overrides or {} do
		p[key] = value
	end
	return p
end

local function profilesOf(...)
	local map = {}
	for _, p in { ... } do
		map[p.category] = map[p.category] or {}
		map[p.category][p.id] = p
	end
	return map
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

local function close(actual, expected, label)
	if math.abs(actual - expected) > 1e-3 then
		error((label or "valor") .. ": esperaba " .. tostring(expected) .. " y es " .. tostring(actual), 2)
	end
end

local function closeVector(actual, expected, label)
	close(actual.X, expected.X, (label or "v") .. ".X")
	close(actual.Y, expected.Y, (label or "v") .. ".Y")
	close(actual.Z, expected.Z, (label or "v") .. ".Z")
end

local function firstPart(root)
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			return d
		end
	end
	return nil
end

local function count(root, className)
	local n = 0
	for _, d in root:GetDescendants() do
		if d:IsA(className) then
			n += 1
		end
	end
	return n
end

----------------------------------------------------------------------------

describe("Art.validate (lista blanca, sin ejecutar nada)", function()
	local p = profile()

	it("acepta un Model con una malla valida y un MeshPart suelto", function()
		expect({ Art.validate(model("fish"), p) }).toEqual({ true })
		expect({ Art.validate(mesh("fish"), p) }).toEqual({ true })
	end)

	it(
		"acepta lo que suele traer el generador: varias mallas, SurfaceAppearance, Attachment, Decal, WeldConstraint",
		function()
			local m = model("fish")
			local body = m:FindFirstChild("Body")
			Instance.new("SurfaceAppearance").Parent = body
			Instance.new("Attachment").Parent = body
			Instance.new("Decal").Parent = body
			local fin = mesh("Fin", Vector3.new(1, 1, 1), Vector3.new(2, 0, 0))
			fin.Parent = m
			local weld = Instance.new("WeldConstraint")
			weld.Part0, weld.Part1 = body, fin
			weld.Parent = body
			expect({ Art.validate(m, p) }).toEqual({ true })
		end
	)

	it("RECHAZA cualquier script, en cualquier nivel (asset con codigo oculto)", function()
		for _, className in { "Script", "LocalScript", "ModuleScript" } do
			-- como hijo directo del modelo
			local m1 = model("fish")
			Instance.new(className).Parent = m1
			expect({ Art.validate(m1, p) }).toEqual({ false, "contains-script" })
			-- dentro de una malla
			local m2 = model("fish")
			Instance.new(className).Parent = m2:FindFirstChild("Body")
			expect({ Art.validate(m2, p) }).toEqual({ false, "contains-script" })
			-- enterrado en carpetas
			local m3 = model("fish")
			local f1, f2 = Instance.new("Folder"), Instance.new("Folder")
			f2.Parent = f1
			f1.Parent = m3
			Instance.new(className).Parent = f2
			expect({ Art.validate(m3, p) }).toEqual({ false, "contains-script" })
		end
	end)

	it("RECHAZA un script aunque este deshabilitado o vacio, y una raiz que es un script", function()
		local m = model("fish")
		local script = Instance.new("Script")
		script.Disabled = true
		script.Parent = m
		expect({ Art.validate(m, p) }).toEqual({ false, "contains-script" })
		expect({ Art.validate(Instance.new("ModuleScript"), p) }).toEqual({ false, "bad-root-class" })
	end)

	it("RECHAZA clases fuera de la lista blanca (remotos, sonidos, humanoides, constraints, valores...)", function()
		for _, className in
			{
				"RemoteEvent",
				"RemoteFunction",
				"BindableEvent",
				"Sound",
				"Humanoid",
				"StringValue",
				"ObjectValue",
				"BillboardGui",
				"ParticleEmitter",
				"PointLight",
				"HingeConstraint",
				"UnionOperation",
				"ClickDetector",
			}
		do
			local m = model("fish")
			Instance.new(className).Parent = m
			expect({ Art.validate(m, p) }).toEqual({ false, "disallowed-class:" .. className })
		end
	end)

	it("la lista blanca solo contiene clases reales que no son scripts", function()
		for className in Art.ALLOWED_CLASSES do
			local instance = Instance.new(className)
			expect(instance:IsA("LuaSourceContainer")).toBe(false)
			expect(instance:IsA("BaseScript")).toBe(false)
		end
	end)

	it("rechaza raices que no son Model ni MeshPart", function()
		expect({ Art.validate(Instance.new("Part"), p) }).toEqual({ false, "bad-root-class" })
		expect({ Art.validate(Instance.new("Folder"), p) }).toEqual({ false, "bad-root-class" })
	end)

	it("arte a medias: modelo sin partes, malla sin MeshId o con un MeshId no permitido", function()
		expect({ Art.validate(Instance.new("Model"), p) }).toEqual({ false, "no-parts" })
		local sinMalla = Instance.new("Model")
		mesh("Body", nil, nil, false).Parent = sinMalla
		expect({ Art.validate(sinMalla, p) }).toEqual({ false, "mesh-without-id" })
		local vacia = Instance.new("Model")
		mesh("Body", nil, nil, "").Parent = vacia
		expect({ Art.validate(vacia, p) }).toEqual({ false, "mesh-without-id" })
		for _, bad in { "https://example.com/mesh.obj", "file:///etc/passwd", "rbxassetid://abc", "rbxassetid://" } do
			local m = Instance.new("Model")
			mesh("Body", nil, nil, bad).Parent = m
			expect({ Art.validate(m, p) }).toEqual({ false, "bad-mesh-id" })
		end
		-- una malla buena y otra a medias en el mismo modelo: se rechaza todo
		local mitad = model("fish")
		mesh("Fin", nil, nil, false).Parent = mitad
		expect({ Art.validate(mitad, p) }).toEqual({ false, "mesh-without-id" })
	end)

	it("acepta los formatos de MeshId de Roblox", function()
		for _, good in { "rbxassetid://1", "rbxasset://meshes/x.mesh", "http://www.roblox.com/asset/?id=99" } do
			local m = Instance.new("Model")
			mesh("Body", nil, nil, good).Parent = m
			expect({ Art.validate(m, p) }).toEqual({ true })
		end
	end)

	it("tamano razonable: ni cero, ni NaN, ni infinito, ni gigante, ni escala absurda", function()
		local cero = Instance.new("Model")
		mesh("Body", Vector3.new(0, 1, 1)).Parent = cero
		expect({ Art.validate(cero, p) }).toEqual({ false, "bad-size" })
		local nan = Instance.new("Model")
		mesh("Body", Vector3.new(0 / 0, 1, 1)).Parent = nan
		expect({ Art.validate(nan, p) }).toEqual({ false, "bad-size" })
		local gigante = Instance.new("Model")
		mesh("Body", Vector3.new(2048, 2048, 2048)).Parent = gigante
		local pequeno = profile({ targetSize = Vector3.new(0.1, 0.1, 0.1) })
		expect({ Art.validate(gigante, pequeno) }).toEqual({ false, "bad-scale" })
		-- dos mallas muy separadas: la caja del modelo supera el maximo
		local lejos = model("fish", Vector3.new(1, 1, 1))
		mesh("Far", Vector3.new(1, 1, 1), Vector3.new(5000, 0, 0)).Parent = lejos
		expect({ Art.validate(lejos, profile({ maxParts = 12 })) }).toEqual({ false, "bad-size" })
		-- una malla diminuta pedida a escala enorme
		local minuscula = Instance.new("Model")
		mesh("Body", Vector3.new(0.002, 0.002, 0.002)).Parent = minuscula
		expect({ Art.validate(minuscula, profile({ targetSize = Vector3.new(50, 50, 50) })) }).toEqual({
			false,
			"bad-scale",
		})
	end)

	it("limita instancias y partes", function()
		local muchas = Instance.new("Model")
		for index = 1, 13 do
			mesh("P" .. index).Parent = muchas
		end
		expect({ Art.validate(muchas, p) }).toEqual({ false, "too-many-parts" })
		local pocas = Instance.new("Model")
		for index = 1, 3 do
			mesh("P" .. index).Parent = pocas
		end
		expect({ Art.validate(pocas, profile({ maxParts = 2 })) }).toEqual({ false, "too-many-parts" })
		local llena = model("fish")
		for index = 1, 70 do
			local f = Instance.new("Folder")
			f.Name = "F" .. index
			f.Parent = llena
		end
		expect({ Art.validate(llena, p) }).toEqual({ false, "too-many-instances" })
	end)

	it("presupuesto de triangulos: el atributo ArtTriangles no puede pasarse del perfil ni de 20.000", function()
		local m = model("fish")
		m:SetAttribute("ArtTriangles", 1500)
		expect({ Art.validate(m, profile({ maxTriangles = 2000 })) }).toEqual({ true })
		m:SetAttribute("ArtTriangles", 2001)
		expect({ Art.validate(m, profile({ maxTriangles = 2000 })) }).toEqual({ false, "over-triangle-budget" })
		-- un perfil con presupuesto mayor que el limite oficial sigue topado en 20.000
		m:SetAttribute("ArtTriangles", 20001)
		expect({ Art.validate(m, profile({ maxTriangles = 99999 })) }).toEqual({ false, "over-triangle-budget" })
		m:SetAttribute("ArtTriangles", 20000)
		expect({ Art.validate(m, profile({ maxTriangles = 99999 })) }).toEqual({ true })
		m:SetAttribute("ArtTriangles", "muchos")
		expect({ Art.validate(m, p) }).toEqual({ false, "bad-attribute" })
		m:SetAttribute("ArtTriangles", -1)
		expect({ Art.validate(m, p) }).toEqual({ false, "bad-attribute" })
	end)
end)

----------------------------------------------------------------------------

describe("Art.place con arte valido", function()
	local root, provider, parent, logs

	beforeEach(function()
		root = Instance.new("Folder")
		parent = Instance.new("Folder")
		logs = {}
		provider = Art.new({
			roots = { root },
			profiles = profilesOf(profile()),
			log = function(message)
				table.insert(logs, message)
			end,
		})
	end)

	it("clona, escala al perfil (contain) y centra en el CFrame de destino", function()
		put(root, "creatures", model("fish")) -- malla 2x4x6 -> caja 1x2x3: escala 0.5
		local result = provider:place("creatures", "fish", { parent = parent, cframe = CFrame.new(10, 5, 20) })
		expect(result.source).toBe("art")
		expect(result.reason).toBeNil()
		expect(result.instance.Parent).toBe(parent)
		expect(result.instance.ClassName).toBe("Model")
		expect(result.instance.Name).toBe("fish")
		local part = firstPart(result.instance)
		closeVector(part.Size, Vector3.new(1, 2, 3), "size")
		closeVector(part.CFrame.Position, Vector3.new(10, 5, 20), "pos")
		expect(result.instance.PrimaryPart).toBe(part)
		expect(#logs).toBe(0)
	end)

	it("'contain' respeta el eje mas restrictivo y 'height'/'length' solo igualan su eje", function()
		put(root, "creatures", model("fish", Vector3.new(4, 2, 2)))
		local contain = provider:place("creatures", "fish", { parent = parent, cframe = CFrame.new() })
		closeVector(firstPart(contain.instance).Size, Vector3.new(1, 0.5, 0.5), "contain") -- X: 1/4 manda
		local heightProvider = Art.new({ roots = { root }, profiles = profilesOf(profile({ fit = "height" })) })
		local height = heightProvider:place("creatures", "fish", { parent = parent, cframe = CFrame.new() })
		closeVector(firstPart(height.instance).Size, Vector3.new(4, 2, 2), "height") -- 2/2 = x1
		local lengthProvider = Art.new({ roots = { root }, profiles = profilesOf(profile({ fit = "length" })) })
		local length = lengthProvider:place("creatures", "fish", { parent = parent, cframe = CFrame.new() })
		closeVector(firstPart(length.instance).Size, Vector3.new(6, 3, 3), "length") -- 3/2 = x1.5
	end)

	it("el multiplicador `scale` da variedad y esta acotado", function()
		put(root, "creatures", model("fish"))
		local doble = provider:place("creatures", "fish", { parent = parent, cframe = CFrame.new(), scale = 2 })
		closeVector(firstPart(doble.instance).Size, Vector3.new(2, 4, 6), "x2")
		local absurdo = provider:place("creatures", "fish", { parent = parent, cframe = CFrame.new(), scale = 1000 })
		closeVector(firstPart(absurdo.instance).Size, Vector3.new(4, 8, 12), "tope x4")
	end)

	it("pivote bottom y back: la base / la cara trasera quedan en el punto de destino", function()
		put(root, "creatures", model("fish"))
		for pivot, expected in
			{
				center = Vector3.new(10, 5, 20),
				bottom = Vector3.new(10, 6, 20), -- alto final 2: el centro queda 1 por encima
				back = Vector3.new(10, 5, 18.5), -- largo final 3: el centro queda 1,5 por delante (-Z)
			}
		do
			local custom = Art.new({ roots = { root }, profiles = profilesOf(profile({ pivot = pivot })) })
			local result = custom:place("creatures", "fish", { parent = parent, cframe = CFrame.new(10, 5, 20) })
			closeVector(firstPart(result.instance).CFrame.Position, expected, pivot)
		end
	end)

	it("offset desplaza tras colocar el pivote; el CFrame de destino gira el modelo", function()
		put(root, "creatures", model("fish"))
		local custom = Art.new({
			roots = { root },
			profiles = profilesOf(profile({ offset = Vector3.new(0, 1, 0) })),
		})
		local rotated = CFrame.new(10, 5, 20) * CFrame.Angles(0, math.pi / 2, 0)
		local result = custom:place("creatures", "fish", { parent = parent, cframe = rotated })
		local part = firstPart(result.instance)
		-- el offset va en los ejes del CFrame de destino (Y no cambia con un giro en Y)
		closeVector(part.CFrame.Position, Vector3.new(10, 6, 20), "pos")
		-- el modelo quedo girado 90 grados en Y: su frente (-Z) mira hacia -X
		closeVector(part.CFrame.LookVector, Vector3.new(-1, 0, 0), "look")
	end)

	it("rotation corrige un modelo generado de lado antes de escalar", function()
		local lateral = Instance.new("Model")
		lateral.Name = "fish"
		mesh("Body", Vector3.new(6, 2, 1)).Parent = lateral -- largo en X, pero el juego lo quiere en Z
		put(root, "creatures", lateral)
		local custom = Art.new({
			roots = { root },
			profiles = profilesOf(
				profile({ fit = "length", targetSize = Vector3.new(1, 1, 3), rotation = Vector3.new(0, 90, 0) })
			),
		})
		local result = custom:place("creatures", "fish", { parent = parent, cframe = CFrame.new() })
		local _, size = Art.bounds(result.instance)
		closeVector(size, Vector3.new(0.5, 1, 3), "caja final") -- largo 6 -> 3 (escala 0,5) ahora en Z
	end)

	it("es visual SOLO: sin colisiones, sin toques, sin consultas; anclado por defecto", function()
		put(root, "creatures", model("fish"))
		local result = provider:place("creatures", "fish", { parent = parent, cframe = CFrame.new() })
		for _, d in result.instance:GetDescendants() do
			if d:IsA("BasePart") then
				expect(d.CanCollide).toBe(false)
				expect(d.CanTouch).toBe(false)
				expect(d.CanQuery).toBe(false)
				expect(d.Anchored).toBe(true)
			end
		end
	end)

	it("anchored=false: partes soldadas a la principal (la mas grande) y Massless", function()
		local m = model("fish", Vector3.new(4, 4, 4))
		mesh("Fin", Vector3.new(1, 1, 1), Vector3.new(3, 0, 0)).Parent = m
		mesh("Eye", Vector3.new(0.5, 0.5, 0.5), Vector3.new(0, 3, 0)).Parent = m
		put(root, "creatures", m)
		local result = provider:place("creatures", "fish", { parent = parent, cframe = CFrame.new(), anchored = false })
		local primary = result.instance.PrimaryPart
		expect(primary.Name).toBe("Body")
		expect(count(result.instance, "WeldConstraint")).toBe(2)
		for _, d in result.instance:GetDescendants() do
			if d:IsA("WeldConstraint") then
				expect(d.Part0).toBe(primary)
				expect(d.Part1 ~= primary).toBe(true)
			elseif d:IsA("BasePart") then
				expect(d.Anchored).toBe(false)
				expect(d.Massless).toBe(true)
			end
		end
	end)

	it("descarta las soldaduras del asset (y no deja ninguna cuando va anclado)", function()
		local m = model("fish")
		local body = m:FindFirstChild("Body")
		local fin = mesh("Fin", Vector3.new(1, 1, 1), Vector3.new(2, 0, 0))
		fin.Parent = m
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1 = body, fin
		weld.Parent = body
		put(root, "creatures", m)
		local result = provider:place("creatures", "fish", { parent = parent, cframe = CFrame.new() })
		expect(count(result.instance, "WeldConstraint")).toBe(0)
	end)

	it("escala tambien los Attachment y conserva SurfaceAppearance/Decal", function()
		local m = model("fish")
		local body = m:FindFirstChild("Body")
		local attachment = Instance.new("Attachment")
		attachment.Position = Vector3.new(2, 4, 6)
		attachment.Parent = body
		Instance.new("SurfaceAppearance").Parent = body
		put(root, "creatures", m)
		local result = provider:place("creatures", "fish", { parent = parent, cframe = CFrame.new() })
		local scaled = result.instance:FindFirstChildWhichIsA("Attachment", true)
		closeVector(scaled.Position, Vector3.new(1, 2, 3), "attachment")
		expect(count(result.instance, "SurfaceAppearance")).toBe(1)
	end)

	it("un MeshPart suelto se envuelve en un Model", function()
		put(root, "creatures", mesh("fish"))
		local result = provider:place("creatures", "fish", { parent = parent, cframe = CFrame.new() })
		expect(result.source).toBe("art")
		expect(result.instance.ClassName).toBe("Model")
		expect(result.instance.PrimaryPart ~= nil).toBe(true)
	end)

	it("nombre personalizado; la plantilla NO se toca (mismo sitio, tamano y posicion)", function()
		local template = put(root, "creatures", model("fish"))
		local original = template:FindFirstChild("Body")
		local result =
			provider:place("creatures", "fish", { parent = parent, cframe = CFrame.new(50, 50, 50), name = "Pez1" })
		expect(result.instance.Name).toBe("Pez1")
		expect(result.instance ~= template).toBe(true)
		expect(template.Parent.Name).toBe("creatures")
		closeVector(original.Size, Vector3.new(2, 4, 6), "plantilla")
		closeVector(original.CFrame.Position, Vector3.new(0, 0, 0), "plantilla pos")
		expect(original.Anchored).toBe(false) -- no se normalizo la plantilla
	end)

	it("dos colocaciones son clones independientes", function()
		put(root, "creatures", model("fish"))
		local a = provider:place("creatures", "fish", { parent = parent, cframe = CFrame.new(0, 0, 0) })
		local b = provider:place("creatures", "fish", { parent = parent, cframe = CFrame.new(100, 0, 0) })
		expect(a.instance ~= b.instance).toBe(true)
		closeVector(firstPart(a.instance).CFrame.Position, Vector3.new(0, 0, 0), "a")
		closeVector(firstPart(b.instance).CFrame.Position, Vector3.new(100, 0, 0), "b")
	end)

	it("no llama al respaldo cuando hay arte", function()
		put(root, "creatures", model("fish"))
		local llamadas = 0
		provider:place("creatures", "fish", {
			parent = parent,
			cframe = CFrame.new(),
			fallback = function()
				llamadas += 1
				return nil
			end,
		})
		expect(llamadas).toBe(0)
	end)
end)

----------------------------------------------------------------------------

describe("Art.place sin arte, con arte invalido o a medias (siempre hay respaldo)", function()
	local root, provider, parent, logs

	beforeEach(function()
		root = Instance.new("Folder")
		parent = Instance.new("Folder")
		logs = {}
		provider = Art.new({
			roots = { root },
			profiles = profilesOf(
				profile({ id = "a" }),
				profile({ id = "b" }),
				profile({ id = "c" }),
				profile({ category = "props", id = "pier" })
			),
			log = function(message)
				table.insert(logs, message)
			end,
		})
	end)

	local function fallbackSpy()
		local state = { calls = 0 }
		state.fn = function(fallbackParent, cframe)
			state.calls += 1
			state.parent, state.cframe = fallbackParent, cframe
			local made = Instance.new("Part")
			made.Name = "Procedural"
			made.Parent = fallbackParent
			return made
		end
		return state
	end

	it("SIN arte (carpeta de arte vacia): usa el respaldo, sin avisos ni errores", function()
		local spy = fallbackSpy()
		local cframe = CFrame.new(1, 2, 3)
		local result = provider:place("creatures", "a", { parent = parent, cframe = cframe, fallback = spy.fn })
		expect(result.source).toBe("fallback")
		expect(result.reason).toBe("missing")
		expect(spy.calls).toBe(1)
		expect(spy.parent).toBe(parent)
		expect(spy.cframe).toBe(cframe)
		expect(parent:FindFirstChild("Procedural") ~= nil).toBe(true)
		expect(#logs).toBe(0) -- sin arte es lo normal: no es un aviso
	end)

	it("SIN arte y sin respaldo: devuelve 'none' y no crea nada", function()
		local result = provider:place("creatures", "a", { parent = parent, cframe = CFrame.new() })
		expect(result.source).toBe("none")
		expect(result.instance).toBeNil()
		expect(#parent:GetChildren()).toBe(0)
	end)

	it("SIN raices (ServerStorage.Art no existe): respaldo", function()
		local sinRaices = Art.new({ roots = {}, profiles = profilesOf(profile({ id = "a" })) })
		local spy = fallbackSpy()
		local result = sinRaices:place("creatures", "a", { parent = parent, cframe = CFrame.new(), fallback = spy.fn })
		expect(result.source).toBe("fallback")
		expect(spy.calls).toBe(1)
	end)

	it("pieza sin perfil: respaldo con motivo no-profile (aunque exista una carpeta con ese nombre)", function()
		put(root, "creatures", model("zzz"))
		local spy = fallbackSpy()
		local result = provider:place("creatures", "zzz", { parent = parent, cframe = CFrame.new(), fallback = spy.fn })
		expect(result.source).toBe("fallback")
		expect(result.reason).toBe("no-profile")
	end)

	it("ARTE INVALIDO (script dentro): se rechaza, se usa el respaldo y se avisa UNA sola vez", function()
		local malo = model("a")
		local script = Instance.new("Script")
		script.Name = "Backdoor"
		script.Parent = malo
		put(root, "creatures", malo)
		local spy = fallbackSpy()
		for _ = 1, 3 do
			local result =
				provider:place("creatures", "a", { parent = parent, cframe = CFrame.new(), fallback = spy.fn })
			expect(result.source).toBe("fallback")
			expect(result.reason).toBe("contains-script")
		end
		expect(spy.calls).toBe(3)
		expect(#logs).toBe(1)
		expect(logs[1]).toContain("creatures/a")
		expect(logs[1]).toContain("contains-script")
		-- NO se coló ninguna instancia del asset: solo lo del respaldo
		expect(count(parent, "Script")).toBe(0)
		expect(count(parent, "MeshPart")).toBe(0)
	end)

	it("arte a medias: una malla sin MeshId -> respaldo; otra pieza buena de la misma carpeta si se usa", function()
		local medias = Instance.new("Model")
		medias.Name = "a"
		mesh("Body", nil, nil, false).Parent = medias
		put(root, "creatures", medias)
		put(root, "creatures", model("b"))
		local spy = fallbackSpy()
		local a = provider:place("creatures", "a", { parent = parent, cframe = CFrame.new(), fallback = spy.fn })
		local b = provider:place("creatures", "b", { parent = parent, cframe = CFrame.new(), fallback = spy.fn })
		local c = provider:place("creatures", "c", { parent = parent, cframe = CFrame.new(), fallback = spy.fn })
		expect(a.source).toBe("fallback")
		expect(a.reason).toBe("mesh-without-id")
		expect(b.source).toBe("art")
		expect(c.source).toBe("fallback")
		expect(c.reason).toBe("missing")
		expect(spy.calls).toBe(2)
	end)

	it("una plantilla con la clase raiz equivocada (p. ej. una Part llamada como el id) se rechaza", function()
		local suelta = Instance.new("Part")
		suelta.Name = "a"
		put(root, "creatures", suelta)
		local spy = fallbackSpy()
		local result = provider:place("creatures", "a", { parent = parent, cframe = CFrame.new(), fallback = spy.fn })
		expect(result.reason).toBe("bad-root-class")
		expect(spy.calls).toBe(1)
	end)

	it("error al construir: se destruye lo medio hecho y se usa el respaldo", function()
		put(root, "creatures", model("a"))
		local calls = 0
		-- un padre que no es una Instancia hace fallar la ultima asignacion (model.Parent = ...) tras clonar y colocar todo
		local result = provider:place("creatures", "a", {
			parent = 12345,
			cframe = CFrame.new(),
			fallback = function()
				calls += 1
				return nil
			end,
		})
		expect(result.source).toBe("fallback")
		expect(result.reason).toBe("build-error")
		expect(calls).toBe(1)
		expect(#logs).toBe(1)
		expect(logs[1]).toContain("build-error")
	end)

	it("si el respaldo falla, el error se propaga (comportamiento de siempre del generador procedural)", function()
		expect(function()
			provider:place("creatures", "a", {
				parent = parent,
				cframe = CFrame.new(),
				fallback = function()
					error("fallo del generador")
				end,
			})
		end).toThrow("fallo del generador")
	end)

	it("categorias separadas: creatures/a no se confunde con props/a", function()
		put(root, "props", model("pier"))
		local ok = provider:place("props", "pier", { parent = parent, cframe = CFrame.new() })
		expect(ok.source).toBe("art")
		local no = provider:place("creatures", "pier", { parent = parent, cframe = CFrame.new() })
		expect(no.source).toBe("none")
	end)
end)

----------------------------------------------------------------------------

describe("Art: raices, check, report y materiales", function()
	it("busca en las raices en orden; la primera que tenga la pieza gana", function()
		local first, second = Instance.new("Folder"), Instance.new("Folder")
		local p = profilesOf(profile({ id = "a" }), profile({ id = "b" }))
		local provider = Art.new({ roots = { first, second }, profiles = p })
		put(second, "creatures", model("a", Vector3.new(2, 4, 6)))
		put(first, "creatures", model("b", Vector3.new(2, 4, 6)))
		put(second, "creatures", model("b", Vector3.new(10, 10, 10)))
		expect(provider:find("creatures", "a").Parent.Parent).toBe(second)
		expect(provider:find("creatures", "b").Parent.Parent).toBe(first)
		expect(provider:find("creatures", "zzz")).toBeNil()
	end)

	it("check distingue ok / missing / invalid sin construir nada", function()
		local root = Instance.new("Folder")
		local provider = Art.new({
			roots = { root },
			profiles = profilesOf(profile({ id = "ok" }), profile({ id = "falta" }), profile({ id = "mal" })),
		})
		put(root, "creatures", model("ok"))
		local malo = model("mal")
		Instance.new("LocalScript").Parent = malo
		put(root, "creatures", malo)
		expect(provider:check("creatures", "ok")).toEqual({ status = "ok" })
		expect(provider:check("creatures", "falta")).toEqual({ status = "missing", reason = "missing" })
		expect(provider:check("creatures", "mal")).toEqual({ status = "invalid", reason = "contains-script" })
		expect(provider:check("creatures", "nope")).toEqual({ status = "invalid", reason = "no-profile" })
		expect(provider:has("creatures", "ok")).toBe(true)
		expect(provider:has("creatures", "mal")).toBe(false)
	end)

	it("report resume cuantas piezas tienen arte, faltan o se rechazan (con el motivo)", function()
		local root = Instance.new("Folder")
		local provider = Art.new({
			roots = { root },
			profiles = profilesOf(
				profile({ id = "a" }),
				profile({ id = "b" }),
				profile({ id = "c" }),
				profile({ category = "rods", id = "r" })
			),
		})
		put(root, "creatures", model("a"))
		local mal = Instance.new("Model")
		mal.Name = "b"
		put(root, "creatures", mal)
		local report = provider:report()
		expect(report.total).toBe(4)
		expect(report.art).toBe(1)
		expect(report.invalid).toBe(1)
		expect(report.missing).toBe(2)
		expect(report.invalidList).toEqual({ "creatures/b: no-parts" })
	end)

	it("materialFor devuelve el MaterialVariant FF_<id> valido y nada mas", function()
		local materials = Instance.new("Folder")
		local variant = Instance.new("MaterialVariant")
		variant.Name = "FF_ground_lake"
		variant.BaseMaterial = Enum.Material.Grass
		variant.Parent = materials
		local impostor = Instance.new("Folder")
		impostor.Name = "FF_pier_wood"
		impostor.Parent = materials
		local provider = Art.new({ roots = {}, profiles = {}, materialRoot = materials })
		local choice = provider:materialFor("ground_lake")
		expect(choice.variantName).toBe("FF_ground_lake")
		expect(choice.baseMaterial).toBe(Enum.Material.Grass)
		expect(provider:materialFor("pier_wood")).toBeNil() -- existe el nombre pero no es un MaterialVariant
		expect(provider:materialFor("ground_river")).toBeNil()
		expect(Art.new({ roots = {}, profiles = {} }):materialFor("ground_lake")).toBeNil() -- sin materialRoot
	end)
end)
