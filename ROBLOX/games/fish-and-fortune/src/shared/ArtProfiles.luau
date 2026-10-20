--!strict
--[[
	ArtProfiles: "perfil" de cada pieza de arte de Fish & Fortune (tamano objetivo en studs, pivote, presupuesto de
	triangulos). Son DATOS: los consume packages/Art (que valida el asset generado y lo escala/orienta con ellos).

	Fuente de verdad del prompt de cada pieza: art/manifest.json. Este archivo repite SOLO lo que hace falta en tiempo de
	ejecucion; tests/ArtProfiles.spec.luau comprueba que ambos coinciden (ids, categorias, tamanos, presupuestos).

	Convencion de orientacion del modelo en su plantilla: ejes del mundo (sin girar), alto en Y, frente (morro / punta de la
	cana) hacia -Z. Si un modelo generado sale girado se corrige aqui con `rotation` (grados), sin tocar el asset.
	Los presupuestos de triangulos son propios de este juego (por debajo del limite oficial de 20.000 por malla).
]]

export type Profile = {
	category: string,
	id: string,
	targetSize: Vector3,
	fit: ("contain" | "height" | "length")?,
	pivot: ("center" | "bottom" | "back")?,
	rotation: Vector3?,
	offset: Vector3?,
	maxTriangles: number?,
	maxParts: number?,
}

local ArtProfiles = {}

ArtProfiles.categories = { "creatures", "rods", "props" }

-- Carpetas dentro de la raiz de arte (ServerStorage/Art/<categoria>/<id>).
ArtProfiles.rootName = "Art"

-- MaterialVariant generados (MaterialService/FF_<id>): id -> material base que debe tener la variante.
ArtProfiles.materials = {
	ground_lake = "Grass",
	ground_river = "Grass",
	ground_coast = "Sand",
	pier_wood = "WoodPlanks",
} :: { [string]: string }

-- Escaparate de capturas (criatura que salta del agua al pescarla). Sin arte de esa criatura no se muestra nada.
ArtProfiles.showcase = {
	minRarityManual = "Rare", -- desde esta rareza en capturas manuales
	minRarityAuto = "Legendary", -- desde esta rareza en la pesca automatica
	cooldownSeconds = 2, -- minimo entre escaparates de una misma zona
	lifetimeSeconds = 3.5,
	maxLive = 4, -- a la vez en todo el servidor
	height = 3, -- studs sobre el punto de lanzamiento
}

-- Caja objetivo (ancho X, alto Y, largo Z) y presupuesto de triangulos por rareza.
local RARITY_SIZE: { [string]: Vector3 } = {
	Common = Vector3.new(0.8, 1.0, 2.2),
	Uncommon = Vector3.new(1.0, 1.3, 2.8),
	Rare = Vector3.new(1.2, 1.5, 3.4),
	Epic = Vector3.new(1.6, 2.0, 4.4),
	Legendary = Vector3.new(2.2, 2.8, 6.0),
	Mythic = Vector3.new(3.0, 3.6, 9.0),
}
local RARITY_TRIANGLES: { [string]: number } = {
	Common = 1500,
	Uncommon = 2000,
	Rare = 3000,
	Epic = 4000,
	Legendary = 6000,
	Mythic = 8000,
}

-- Criaturas cuya silueta no es "pez normal": su caja se define a mano.
local CREATURE_SIZE_OVERRIDE: { [string]: Vector3 } = {
	eel = Vector3.new(0.7, 0.7, 4.0),
	sand_crab = Vector3.new(2.0, 1.0, 2.0),
	glass_shrimp = Vector3.new(1.0, 0.8, 2.2),
	manta = Vector3.new(6.0, 1.5, 4.5),
	golden_marlin = Vector3.new(1.4, 2.0, 7.0),
	lake_spirit = Vector3.new(3.5, 4.0, 10.0),
	tide_leviathan = Vector3.new(5.0, 5.0, 15.0),
}

local ROD_TRIANGLES: { [string]: number } = {
	driftwood = 1500,
	reed = 1500,
	fiberglass = 2000,
	carbon = 2500,
	golden = 3500,
}

local function add(profiles: { [string]: { [string]: Profile } }, profile: Profile)
	local byCategory = profiles[profile.category]
	if byCategory == nil then
		byCategory = {}
		profiles[profile.category] = byCategory
	end
	byCategory[profile.id] = profile
end

-- `balance` = shared/Balance (se usa `creatures[].id|rarity` y `rodOrder`); tipo `any` como en Catalog.build para no atar el tipo.
function ArtProfiles.build(balance: any): { [string]: { [string]: Profile } }
	local profiles: { [string]: { [string]: Profile } } = {}

	for _, creature in balance.creatures do
		add(profiles, {
			category = "creatures",
			id = creature.id,
			targetSize = CREATURE_SIZE_OVERRIDE[creature.id] or RARITY_SIZE[creature.rarity] or RARITY_SIZE.Common,
			fit = "contain",
			pivot = "center",
			maxTriangles = RARITY_TRIANGLES[creature.rarity] or RARITY_TRIANGLES.Common,
			maxParts = 8,
		})
	end

	for _, rodId in balance.rodOrder do
		add(profiles, {
			category = "rods",
			id = rodId,
			targetSize = Vector3.new(0.6, 0.9, 5),
			fit = "length", -- el largo manda: un carrete ancho no debe encoger la cana
			pivot = "back", -- el extremo del mango (+Z) queda en la mano
			maxTriangles = ROD_TRIANGLES[rodId] or 2500,
			maxParts = 8,
		})
	end

	local props: { Profile } = {
		{
			category = "props",
			id = "pier",
			targetSize = Vector3.new(8, 5, 44),
			fit = "contain",
			pivot = "bottom",
			maxTriangles = 8000,
			maxParts = 12,
		},
		{
			category = "props",
			id = "lantern",
			targetSize = Vector3.new(1.2, 4.2, 1.2),
			fit = "height",
			pivot = "bottom",
			maxTriangles = 1500,
			maxParts = 6,
		},
		{
			category = "props",
			id = "rowboat",
			targetSize = Vector3.new(3.6, 1.8, 8.5),
			fit = "contain",
			pivot = "bottom",
			maxTriangles = 3000,
			maxParts = 8,
		},
		{
			category = "props",
			id = "pine_tree",
			targetSize = Vector3.new(7, 14, 7),
			fit = "height",
			pivot = "bottom",
			maxTriangles = 1500,
			maxParts = 4,
		},
		{
			category = "props",
			id = "palm_tree",
			targetSize = Vector3.new(8, 13, 8),
			fit = "height",
			pivot = "bottom",
			maxTriangles = 2000,
			maxParts = 4,
		},
	}
	for _, profile in props do
		add(profiles, profile)
	end

	return profiles
end

return ArtProfiles
