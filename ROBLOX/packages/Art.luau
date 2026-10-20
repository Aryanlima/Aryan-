--!strict
--[[
	Art: ARTE INTERCAMBIABLE con respaldo. Es el UNICO punto donde un juego enlaza arte (modelos 3D generados con IA u
	hechos a mano) con su codigo. Generico (sin nada de Fish & Fortune): cada juego le da sus "perfiles" (tamano objetivo,
	pivote...) y las carpetas donde buscar.

	Convencion de carpetas (decidida por el juego, ver games/fish-and-fortune/README.md "Arte"):
	  <raiz>/<categoria>/<id>      p. ej. ServerStorage/Art/creatures/lake_spirit, ServerStorage/Art/rods/golden
	Cada plantilla es un `Model` (o un `MeshPart` suelto) llamado exactamente como el id logico.

	Que hace `place(categoria, id, opciones)`
	  1. Busca la plantilla en las raices (en orden). Si no existe => RESPALDO (sin ruido: es el caso normal sin arte).
	  2. La VALIDA (ver `Art.validate`): clase raiz, lista blanca de clases (un asset NO puede traer scripts ni remotos ni
	     sonidos...), numero de instancias y de partes, mallas con MeshId valido, tamano razonable, presupuesto de triangulos
	     si el atributo ArtTriangles lo declara. Un asset invalido NO se usa: se avisa UNA vez y se usa el RESPALDO.
	  3. La CLONA (nunca se ejecuta nada: no hay scripts en la lista blanca), la gira/escala/coloca segun el perfil con
	     matematica propia (no depende de Model:ScaleTo/PivotTo, asi que se prueba con Lune) y normaliza las propiedades:
	     visual SOLO (CanCollide/CanTouch/CanQuery = false), anclado salvo que se pida lo contrario (entonces se sueldan las
	     partes entre si y se marca Massless).
	  4. Cualquier error al construir => se destruye lo medio hecho y se usa el RESPALDO.
	El respaldo lo aporta quien llama (`options.fallback`): sigue siendo el generador procedural de siempre. Sin respaldo
	y sin arte valido, `place` devuelve source = "none" y no crea nada.

	Seguridad de lo importado: la validacion es una LISTA BLANCA de clases (todo lo que no esta, se rechaza); no se confia en
	nombres ni atributos salvo ArtTriangles (numero). Plantillas en ServerStorage: no se replican al cliente.

	Orientacion canonica del modelo en la plantilla: ejes del mundo (sin girar), alto en Y, frente hacia -Z. Si un modelo
	sale girado, el perfil trae `rotation` (grados) para corregirlo sin tocar el asset.

	Materiales: `materialFor(id)` devuelve el MaterialVariant guardado en `materialRoot` (MaterialService) con el nombre
	`<materialPrefix><id>` si existe y es valido.
]]

local Art = {}

export type Fit = "contain" | "height" | "length"
export type Pivot = "center" | "bottom" | "back"

export type Profile = {
	category: string,
	id: string,
	targetSize: Vector3, -- caja objetivo (X ancho, Y alto, Z largo) en studs
	fit: Fit?, -- "contain" (defecto: cabe entera en la caja), "height" (iguala el alto), "length" (iguala el largo Z)
	pivot: Pivot?, -- punto del modelo que queda en el CFrame de destino (defecto "center")
	rotation: Vector3?, -- correccion de orientacion en grados (X, Y, Z) aplicada antes de escalar
	offset: Vector3?, -- ajuste fino en studs (ejes del CFrame de destino) tras colocar el pivote
	maxTriangles: number?, -- presupuesto (atributo ArtTriangles); nunca por encima del limite global
	maxParts: number?,
}

export type Limits = {
	maxInstances: number,
	maxParts: number,
	minDimension: number, -- studs: cada eje de cada parte
	maxDimension: number, -- studs: cada eje de la caja del modelo (Roblox limita las partes a 2048)
	maxTriangles: number, -- limite oficial por malla individual: 20.000
	minScale: number, -- escala resultante aceptable (modelo ya muy distinto del objetivo = sospechoso)
	maxScale: number,
}

export type CheckResult = {
	status: "ok" | "missing" | "invalid",
	reason: string?,
}

export type PlaceOptions = {
	parent: Instance,
	cframe: CFrame,
	name: string?, -- nombre del Model resultante (defecto: el id)
	anchored: boolean?, -- defecto true; false => partes soldadas entre si y Massless (p. ej. la cana en la mano)
	scale: number?, -- multiplicador sobre la escala del perfil (variedad: arboles); se limita a 0.25-4
	fallback: ((parent: Instance, cframe: CFrame) -> Instance?)?,
}

export type PlaceResult = {
	source: "art" | "fallback" | "none",
	instance: Instance?,
	reason: string?, -- por que no se uso arte ("missing" o el motivo del rechazo)
}

export type MaterialChoice = {
	baseMaterial: Enum.Material,
	variantName: string,
}

export type Config = {
	roots: { Instance }, -- carpetas donde buscar <categoria>/<id>, en orden de prioridad
	profiles: { [string]: { [string]: Profile } }, -- profiles[categoria][id]
	materialRoot: Instance?, -- donde estan los MaterialVariant (MaterialService)
	materialPrefix: string?, -- defecto "FF_"
	limits: Limits?,
	log: ((message: string) -> ())?,
}

Art.DEFAULT_LIMITS = {
	maxInstances = 64,
	maxParts = 12, -- el generador de Roblox segmenta en hasta 8 partes (assistant/guide.md)
	minDimension = 0.001,
	maxDimension = 2048,
	maxTriangles = 20000, -- specifications.md: "Individual meshes can not exceed 20,000 triangles"
	minScale = 0.005,
	maxScale = 200,
} :: Limits

-- Lista BLANCA de clases permitidas dentro de un asset. Todo lo demas (Script, LocalScript, ModuleScript, RemoteEvent,
-- BindableEvent, Sound, Humanoid, otras constraints, luces, particulas, valores...) se rechaza. WeldConstraint se admite
-- (el generador de Roblox puede soldar los segmentos) pero se DESCARTA al clonar: las soldaduras las rehace este modulo.
local ALLOWED_CLASSES: { [string]: boolean } = {
	Model = true,
	Folder = true,
	MeshPart = true,
	Part = true,
	WedgePart = true,
	SurfaceAppearance = true,
	Decal = true,
	Texture = true,
	Attachment = true,
	WeldConstraint = true, -- se admite en el asset y se descarta al clonar
}
Art.ALLOWED_CLASSES = ALLOWED_CLASSES

local MESH_ID_PATTERNS = {
	"^rbxassetid://%d+$",
	"^rbxasset://.+",
	"^https?://www%.roblox%.com/asset/%?id=%d+$",
}

----------------------------------------------------------------------------
-- Utilidades
----------------------------------------------------------------------------

local function isFinite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

local function isFiniteVector(vector: Vector3): boolean
	return isFinite(vector.X) and isFinite(vector.Y) and isFinite(vector.Z)
end

local function readMeshId(part: MeshPart): string
	-- Un MeshPart sin MeshId puede lanzar al leerse en algunos entornos (Lune); en el motor devuelve "".
	local ok, value = pcall(function()
		return part.MeshId
	end)
	if ok and type(value) == "string" then
		return value
	end
	return ""
end

local function validMeshId(meshId: string): boolean
	for _, pattern in MESH_ID_PATTERNS do
		if string.match(meshId, pattern) ~= nil then
			return true
		end
	end
	return false
end

-- Todas las instancias de la plantilla (raiz incluida).
local function allInstances(template: Instance): { Instance }
	local list = template:GetDescendants()
	table.insert(list, 1, template)
	return list
end

local function collectParts(root: Instance): { BasePart }
	local parts: { BasePart } = {}
	for _, instance in allInstances(root) do
		if instance:IsA("BasePart") then
			table.insert(parts, instance)
		end
	end
	return parts
end

-- Caja alineada con los ejes del mundo que contiene todas las partes (esquinas orientadas). `rotation` opcional: giro
-- (alrededor del origen) que se aplica a las esquinas antes de medir (el tamano no depende del punto de giro).
local function measure(parts: { BasePart }, rotation: CFrame?): (Vector3, Vector3)
	local minimum = Vector3.new(math.huge, math.huge, math.huge)
	local maximum = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, part in parts do
		local half = part.Size / 2
		local frame = part.CFrame
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local corner = frame * Vector3.new(sx * half.X, sy * half.Y, sz * half.Z)
					if rotation ~= nil then
						corner = rotation * corner
					end
					minimum = minimum:Min(corner)
					maximum = maximum:Max(corner)
				end
			end
		end
	end
	return (minimum + maximum) / 2, maximum - minimum
end

local function rotationOf(profile: Profile): CFrame?
	local degrees = profile.rotation
	if degrees == nil then
		return nil
	end
	return CFrame.Angles(math.rad(degrees.X), math.rad(degrees.Y), math.rad(degrees.Z))
end

-- Escala uniforme que lleva `size` al perfil; nil si algun eje usado no tiene grosor.
local function fitScale(size: Vector3, profile: Profile): number?
	local target = profile.targetSize
	local fit = profile.fit or "contain"
	local ratios: { number }
	if fit == "height" then
		ratios = { target.Y / size.Y }
	elseif fit == "length" then
		ratios = { target.Z / size.Z }
	else
		ratios = { target.X / size.X, target.Y / size.Y, target.Z / size.Z }
	end
	local scale = math.huge
	for _, ratio in ratios do
		if not isFinite(ratio) or ratio <= 0 then
			return nil
		end
		scale = math.min(scale, ratio)
	end
	return scale
end

----------------------------------------------------------------------------
-- Validacion (estatica, pura: no modifica nada)
----------------------------------------------------------------------------

--[[
	Devuelve (true) o (false, motivo). Motivos estables (los usan las pruebas, los logs y el informe del PC):
	  bad-root-class            la raiz no es Model ni MeshPart
	  contains-script           hay un script (LuaSourceContainer) en cualquier nivel
	  disallowed-class:<Clase>  clase fuera de la lista blanca
	  too-many-instances / too-many-parts / no-parts
	  mesh-without-id           MeshPart sin MeshId ("a medias") ; bad-mesh-id: formato no permitido
	  bad-size                  tamano de parte o de caja no finito / demasiado pequeno o grande
	  bad-scale                 la escala que pide el perfil es absurda (modelo fuera de proporcion)
	  bad-attribute             ArtTriangles no es un numero valido
	  over-triangle-budget      ArtTriangles supera el presupuesto del perfil o el limite oficial
]]
function Art.validate(template: Instance, profile: Profile, limits: Limits?): (boolean, string?)
	local lim = limits or Art.DEFAULT_LIMITS
	local rootClass = template.ClassName
	if rootClass ~= "Model" and rootClass ~= "MeshPart" then
		return false, "bad-root-class"
	end
	local everything = allInstances(template)
	for _, instance in everything do
		if instance:IsA("LuaSourceContainer") then
			return false, "contains-script"
		end
	end
	for _, instance in everything do
		if not ALLOWED_CLASSES[instance.ClassName] then
			return false, "disallowed-class:" .. instance.ClassName
		end
	end
	if #everything > lim.maxInstances then
		return false, "too-many-instances"
	end

	local parts = collectParts(template)
	if #parts == 0 then
		return false, "no-parts"
	end
	if #parts > math.min(profile.maxParts or lim.maxParts, lim.maxParts) then
		return false, "too-many-parts"
	end
	for _, part in parts do
		if part:IsA("MeshPart") then
			local meshId = readMeshId(part)
			if meshId == "" then
				return false, "mesh-without-id"
			end
			if not validMeshId(meshId) then
				return false, "bad-mesh-id"
			end
		end
		local size = part.Size
		if
			not isFiniteVector(size)
			or size.X < lim.minDimension
			or size.Y < lim.minDimension
			or size.Z < lim.minDimension
			or not isFiniteVector(part.CFrame.Position)
		then
			return false, "bad-size"
		end
	end

	local triangles = template:GetAttribute("ArtTriangles")
	if triangles ~= nil then
		if type(triangles) ~= "number" or not isFinite(triangles) or triangles < 0 then
			return false, "bad-attribute"
		end
		if triangles > math.min(profile.maxTriangles or lim.maxTriangles, lim.maxTriangles) then
			return false, "over-triangle-budget"
		end
	end

	local _, size = measure(parts, rotationOf(profile))
	if
		not isFiniteVector(size)
		or size.X < lim.minDimension
		or size.Y < lim.minDimension
		or size.Z < lim.minDimension
	then
		return false, "bad-size"
	end
	if size.X > lim.maxDimension or size.Y > lim.maxDimension or size.Z > lim.maxDimension then
		return false, "bad-size"
	end
	local scale = fitScale(size, profile)
	if scale == nil or scale < lim.minScale or scale > lim.maxScale then
		return false, "bad-scale"
	end
	return true, nil
end

-- Centro y tamano de la caja (ejes del mundo) que contiene todas las partes de `root`. Sirve para inspeccionar un
-- asset (p. ej. el script de archivado del PC y las pruebas); sin partes devuelve una caja infinita invertida.
function Art.bounds(root: Instance): (Vector3, Vector3)
	return measure(collectParts(root), nil)
end

----------------------------------------------------------------------------
-- Proveedor
----------------------------------------------------------------------------

local Impl = {}
Impl.__index = Impl

type ImplData = {
	roots: { Instance },
	profiles: { [string]: { [string]: Profile } },
	materialRoot: Instance?,
	materialPrefix: string,
	limits: Limits,
	log: (message: string) -> (),
	warned: { [string]: boolean },
}

export type Provider = typeof(setmetatable({} :: ImplData, Impl))

function Art.new(config: Config): Provider
	local data: ImplData = {
		roots = config.roots,
		profiles = config.profiles,
		materialRoot = config.materialRoot,
		materialPrefix = config.materialPrefix or "FF_",
		limits = config.limits or Art.DEFAULT_LIMITS,
		log = config.log or function() end,
		warned = {},
	}
	return setmetatable(data, Impl)
end

function Impl.profile(self: Provider, category: string, id: string): Profile?
	local byCategory = self.profiles[category]
	if byCategory == nil then
		return nil
	end
	return byCategory[id]
end

-- Plantilla cruda (sin validar) o nil.
function Impl.find(self: Provider, category: string, id: string): Instance?
	for _, root in self.roots do
		local folder = root:FindFirstChild(category)
		if folder ~= nil then
			local template = folder:FindFirstChild(id)
			if template ~= nil then
				return template
			end
		end
	end
	return nil
end

-- Estado de una pieza sin construir nada: "ok", "missing" (no hay asset) o "invalid" (hay asset pero se rechaza).
function Impl.check(self: Provider, category: string, id: string): CheckResult
	local profile = self:profile(category, id)
	if profile == nil then
		return { status = "invalid", reason = "no-profile" }
	end
	local template = self:find(category, id)
	if template == nil then
		return { status = "missing", reason = "missing" }
	end
	local ok, reason = Art.validate(template, profile, self.limits)
	if ok then
		return { status = "ok", reason = nil }
	end
	return { status = "invalid", reason = reason }
end

function Impl.has(self: Provider, category: string, id: string): boolean
	return self:check(category, id).status == "ok"
end

local function warnOnce(self: Provider, key: string, message: string)
	if self.warned[key] then
		return
	end
	self.warned[key] = true
	self.log(message)
end

local function setParts(parts: { BasePart }, anchored: boolean)
	for _, part in parts do
		part.Anchored = anchored
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = not anchored
	end
end

local function largestPart(parts: { BasePart }): BasePart
	local best = parts[1]
	local bestVolume = -1.0
	for _, part in parts do
		local size = part.Size
		local volume = size.X * size.Y * size.Z
		if volume > bestVolume then
			best = part
			bestVolume = volume
		end
	end
	return best
end

-- Construye el modelo desde una plantilla YA validada. Puede lanzar error: `place` lo captura.
local function build(template: Instance, profile: Profile, options: PlaceOptions, created: { Instance }): Model
	local clone = template:Clone() :: Instance? -- el motor devuelve nil si la plantilla no es Archivable
	if clone == nil then
		error("not-clonable")
	end
	table.insert(created, clone)

	local model: Model
	if clone:IsA("Model") then
		model = clone
	else
		model = Instance.new("Model")
		table.insert(created, model)
		clone.Parent = model
	end
	-- Las soldaduras del asset no se respetan: se rehacen mas abajo si hace falta.
	for _, instance in model:GetDescendants() do
		if instance:IsA("WeldConstraint") then
			instance:Destroy()
		end
	end

	local parts = collectParts(model)
	local center0 = measure(parts, nil)

	-- 1. Correccion de orientacion (alrededor del centro de la caja)
	local rotation = rotationOf(profile)
	if rotation ~= nil then
		for _, part in parts do
			part.CFrame = CFrame.new(center0) * rotation * CFrame.new(-center0) * part.CFrame
		end
	end

	-- 2. Escala uniforme alrededor del centro
	local center1, size1 = measure(parts, nil)
	local scale = fitScale(size1, profile)
	if scale == nil then
		error("bad-scale")
	end
	scale *= math.clamp(options.scale or 1, 0.25, 4)
	for _, part in parts do
		local frame = part.CFrame
		part.Size = part.Size * scale
		part.CFrame = CFrame.new(center1 + (frame.Position - center1) * scale) * frame.Rotation
	end
	for _, instance in model:GetDescendants() do
		if instance:IsA("Attachment") then
			instance.Position = instance.Position * scale
		end
	end

	-- 3. Pivote -> CFrame de destino
	local center2, size2 = measure(parts, nil)
	local pivot = profile.pivot or "center"
	local point = center2
	if pivot == "bottom" then
		point = center2 - Vector3.new(0, size2.Y / 2, 0)
	elseif pivot == "back" then
		point = center2 + Vector3.new(0, 0, size2.Z / 2)
	end
	local shift = CFrame.new((profile.offset or Vector3.zero) - point)
	for _, part in parts do
		part.CFrame = options.cframe * (shift * part.CFrame)
	end

	-- 4. Propiedades normalizadas y soldaduras
	local anchored = options.anchored ~= false
	setParts(parts, anchored)
	local primary = largestPart(parts)
	if not anchored then
		for _, part in parts do
			if part ~= primary then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = primary
				weld.Part1 = part
				weld.Parent = part
			end
		end
	end
	model.PrimaryPart = primary
	model.Name = options.name or profile.id
	model.Parent = options.parent
	return model
end

function Impl.place(self: Provider, category: string, id: string, options: PlaceOptions): PlaceResult
	local profile = self:profile(category, id)
	local reason: string?
	if profile == nil then
		reason = "no-profile"
		-- una pieza sin perfil es un error de programacion (id mal escrito), no un asset: se avisa una vez
		warnOnce(
			self,
			category .. "/" .. id .. ":no-profile",
			"[Art] " .. category .. "/" .. id .. ": no tiene perfil (no-profile)"
		)
	else
		local template = self:find(category, id)
		if template == nil then
			reason = "missing"
		else
			local valid, why = Art.validate(template, profile, self.limits)
			if not valid then
				reason = why
				warnOnce(
					self,
					category .. "/" .. id .. ":" .. tostring(why),
					"[Art] "
						.. category
						.. "/"
						.. id
						.. ": arte rechazado ("
						.. tostring(why)
						.. "); se usa el respaldo"
				)
			else
				local created: { Instance } = {}
				local ok, built = pcall(build, template, profile, options, created)
				if ok then
					return { source = "art", instance = built, reason = nil }
				end
				for _, instance in created do
					instance:Destroy()
				end
				reason = "build-error"
				warnOnce(
					self,
					category .. "/" .. id .. ":build-error",
					"[Art] "
						.. category
						.. "/"
						.. id
						.. ": build-error, no se pudo construir ("
						.. (string.match(tostring(built), "^[^\n]*") or "")
						.. "); se usa el respaldo"
				)
			end
		end
	end

	if options.fallback ~= nil then
		local instance = options.fallback(options.parent, options.cframe)
		return { source = "fallback", instance = instance, reason = reason }
	end
	return { source = "none", instance = nil, reason = reason }
end

-- MaterialVariant generado (guardado en materialRoot con el nombre <prefijo><id>) o nil.
function Impl.materialFor(self: Provider, id: string): MaterialChoice?
	local root = self.materialRoot
	if root == nil then
		return nil
	end
	local name = self.materialPrefix .. id
	local variant = root:FindFirstChild(name)
	if variant == nil or not variant:IsA("MaterialVariant") then
		return nil
	end
	return { baseMaterial = variant.BaseMaterial, variantName = variant.Name }
end

export type Report = {
	total: number,
	art: number,
	missing: number,
	invalid: number,
	invalidList: { string }, -- "categoria/id: motivo"
}

-- Resumen de todas las piezas con perfil (para el registro de arranque y el informe del PC).
function Impl.report(self: Provider): Report
	local report: Report = { total = 0, art = 0, missing = 0, invalid = 0, invalidList = {} }
	local categories: { string } = {}
	for category in self.profiles do
		table.insert(categories, category)
	end
	table.sort(categories)
	for _, category in categories do
		local ids: { string } = {}
		for id in self.profiles[category] do
			table.insert(ids, id)
		end
		table.sort(ids)
		for _, id in ids do
			report.total += 1
			local result = self:check(category, id)
			if result.status == "ok" then
				report.art += 1
			elseif result.status == "missing" then
				report.missing += 1
			else
				report.invalid += 1
				table.insert(report.invalidList, category .. "/" .. id .. ": " .. tostring(result.reason))
			end
		end
	end
	return report
end

return Art
