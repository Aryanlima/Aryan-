--!strict
--[[
	LiveOpsDefaults: configuracion de LiveOps POR DEFECTO (eventos, codigos, bienvenida, temporada).
	Es la red de seguridad si ConfigService no responde; en produccion se SUSTITUYE sin republicar publicando la
	clave "FishFortune_LiveOps" en Creator Hub > Configs (ver README, "LiveOps sin republicar").

	Vive en el SERVIDOR (no en ReplicatedStorage) para no exponer los codigos de canje al cliente.
	Textos: los de aqui (nombres de evento, temporada, bienvenida) son el RESPALDO en espanol: el cliente usa las claves de
	shared/Strings.luau (event.<id>.name, season.<id>.name, welcome.<id>) y solo cae al texto de la configuracion si no hay clave.
	tests/Strings.spec.luau comprueba que ambos coinciden.
	Los textos de los eventos son de uso GRATUITO (no hay suerte ni azar comprable: FeatureFlags.paidLuckEnabled).
]]

local WEEK = 7 * 24 * 3600
-- Lunes 2026-10-19 00:00:00 UTC
local ANCHOR = 1792368000

return {
	version = 1,
	events = {
		{
			id = "halloween_harvest",
			name = "Cosecha de Halloween",
			description = "Sube tu suerte en 2 puntos hasta el 2 de noviembre.",
			startsAt = 1792627200, -- 2026-10-22 00:00 UTC
			endsAt = 1793577600, -- 2026-11-02 00:00 UTC
			modifiers = { luck = 2 } :: { [string]: number },
		},
		{
			id = "golden_tide",
			name = "Marea Dorada",
			description = "Las monedas por venta se multiplican por 2 durante este evento.",
			cycle = { anchor = ANCHOR, slotSeconds = WEEK, slotCount = 2, slot = 0 },
			modifiers = { coins = 2 } :: { [string]: number },
		},
		{
			id = "mythic_moon",
			name = "Luna Mítica",
			description = "Sube tu suerte en 3 puntos mientras dure el evento.",
			cycle = { anchor = ANCHOR, slotSeconds = WEEK, slotCount = 2, slot = 1 },
			modifiers = { luck = 3 } :: { [string]: number },
		},
	},
	codes = {
		WELCOME = { reward = { coins = 1000, pearls = 5 } },
	},
	welcome = {
		id = "launch",
		message = "Bienvenido a Fish & Fortune. Lanza la caña, descubre criaturas y completa el bestiario.",
	},
	season = { id = 1, name = "Temporada 1", startsAt = ANCHOR, endsAt = ANCHOR + 8 * WEEK },
} :: { [string]: any } -- forma validada en runtime por packages/LiveOps (validateConfig)
