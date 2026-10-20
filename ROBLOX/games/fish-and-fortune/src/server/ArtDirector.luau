--!strict
--[[
	ArtDirector: pegamento de Fish & Fortune con el proveedor de arte (packages/Art). Decide DONDE se usa arte generado:
	  * attachRod      cana en la mano del personaje (reemplaza la Part de colores del respaldo)
	  * showCatch      escaparate: la criatura capturada salta del agua unos segundos (solo si hay arte de ESA criatura)
	  * provider       el proveedor, para WorldBuilder (muelle, farolas, barca, arboles, materiales)
	  * logStatus      resumen de arranque: cuantas piezas tienen arte, cuantas faltan, cuales se rechazan y por que

	Es OPCIONAL: sin arte (o sin este modulo en `m.ArtDirector`) el juego se comporta exactamente como antes. Todo llega
	por inyeccion (sin servicios al cargarse) para poder probarlo con Lune. Los servicios reales se pasan en Main.server.
]]

type PlaceOptionsLike = {
	parent: Instance,
	cframe: CFrame,
	name: string?,
	anchored: boolean?,
	scale: number?,
	fallback: ((parent: Instance, cframe: CFrame) -> Instance?)?,
}

type PlaceResultLike = {
	source: string,
	instance: Instance?,
	reason: string?,
}

export type ShowcaseConfig = {
	minRarityManual: string,
	minRarityAuto: string,
	cooldownSeconds: number,
	lifetimeSeconds: number,
	maxLive: number,
	height: number,
}

export type Deps = {
	-- packages/Art.Provider. Es un objeto con metatabla: su tipo no se puede declarar de forma estructural (los campos de
	-- tabla de Luau son invariantes), asi que entra como `any` y cada resultado se anota con su tipo (PlaceResultLike).
	provider: any,
	rarityOrder: (rarity: string) -> number?, -- orden de rareza de Balance.rarities (nil = rareza desconocida)
	container: Instance, -- donde viven los escaparates (Workspace)
	showcase: ShowcaseConfig,
	debris: { AddItem: (self: any, item: Instance, lifetime: number) -> () },
	clock: () -> number, -- os.clock
	spawn: (callback: () -> ()) -> unknown, -- task.spawn
	wait: (seconds: number) -> unknown, -- task.wait
	log: (message: string) -> (),
}

export type CatchInfo = {
	zone: string,
	creatureId: string,
	rarity: string,
	position: Vector3, -- punto de lanzamiento de la zona (CastTarget)
	auto: boolean, -- true = pesca automatica
}

export type Director = {
	provider: any,
	attachRod: (rodId: string, hand: BasePart, character: Model) -> boolean,
	showCatch: (info: CatchInfo) -> boolean,
	logStatus: () -> (),
}

local ArtDirector = {}

-- Posicion de la cana respecto a la mano (la misma que usa el respaldo procedural de GameService.attachRod).
local ROD_HAND_OFFSET = CFrame.new(0, -0.4, 0.3)

function ArtDirector.create(deps: Deps): Director
	local provider = deps.provider
	local lastShown: { [string]: number } = {}
	local live = 0

	local director: Director = {
		provider = provider,
		attachRod = function()
			return false
		end,
		showCatch = function()
			return false
		end,
		logStatus = function() end,
	}

	-- Devuelve true si la cana en la mano es un modelo de arte generado. Si no (sin arte o arte rechazado) devuelve false y
	-- quien llama construye el respaldo de siempre.
	director.attachRod = function(rodId: string, hand: BasePart, character: Model): boolean
		local result: PlaceResultLike = provider:place("rods", rodId, {
			parent = character,
			cframe = hand.CFrame * ROD_HAND_OFFSET,
			name = "FishingRod",
			anchored = false,
		})
		local instance = result.instance
		if result.source ~= "art" or instance == nil or not instance:IsA("Model") then
			return false
		end
		local primary = instance.PrimaryPart
		if primary == nil then
			instance:Destroy()
			return false
		end
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hand
		weld.Part1 = primary
		weld.Parent = primary
		return true
	end

	local function bob(model: Model, lifetime: number)
		-- Movimiento suave arriba/abajo. Model:GetPivot/PivotTo solo existen en el motor: fuera de el (pruebas) no se anima.
		local ok, start = pcall(function()
			return model:GetPivot()
		end)
		if not ok then
			return
		end
		local steps = math.max(1, math.floor(lifetime / 0.05))
		for index = 1, steps do
			if model.Parent == nil then
				return
			end
			local lift = math.sin(index / steps * math.pi) * 1.2
			local moved = pcall(function()
				model:PivotTo(start * CFrame.new(0, lift, 0))
			end)
			if not moved then
				return
			end
			deps.wait(0.05)
		end
	end

	-- Muestra la criatura capturada si hay arte valido de ella. No tiene respaldo a proposito: sin arte, nada cambia.
	director.showCatch = function(info: CatchInfo): boolean
		local cfg = deps.showcase
		local order = deps.rarityOrder(info.rarity)
		local threshold = deps.rarityOrder(if info.auto then cfg.minRarityAuto else cfg.minRarityManual)
		if order == nil or threshold == nil or order < threshold then
			return false
		end
		local now = deps.clock()
		local last = lastShown[info.zone]
		if last ~= nil and now - last < cfg.cooldownSeconds then
			return false
		end
		if live >= cfg.maxLive then
			return false
		end
		local result: PlaceResultLike = provider:place("creatures", info.creatureId, {
			parent = deps.container,
			-- el morro (-Z del modelo) mira hacia el muelle (+Z de la zona)
			cframe = CFrame.new(info.position + Vector3.new(0, cfg.height, 0)) * CFrame.Angles(0, math.pi, 0),
			name = "CatchShowcase",
			anchored = true,
		})
		local instance = result.instance
		if result.source ~= "art" or instance == nil then
			return false
		end
		lastShown[info.zone] = now
		live += 1
		deps.debris:AddItem(instance, cfg.lifetimeSeconds + 0.5)
		deps.spawn(function()
			-- el contador baja cuando termina la vida del escaparate, se anime o no
			deps.wait(cfg.lifetimeSeconds)
			live -= 1
		end)
		if instance:IsA("Model") then
			local model = instance
			deps.spawn(function()
				bob(model, cfg.lifetimeSeconds)
			end)
		end
		return true
	end

	director.logStatus = function()
		local report = provider:report()
		deps.log(
			string.format(
				"[Art] arte generado: %d de %d piezas (%d sin arte -> respaldo procedural, %d rechazadas)",
				report.art,
				report.total,
				report.missing,
				report.invalid
			)
		)
		for _, line in report.invalidList do
			deps.log("[Art] rechazada: " .. line)
		end
	end

	return director
end

return ArtDirector
