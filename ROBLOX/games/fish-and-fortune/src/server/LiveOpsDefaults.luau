--!strict
--[[
	LiveOpsDefaults: configuracion de LiveOps POR DEFECTO (eventos, codigos, bienvenida, temporada).
	Es la red de seguridad si ConfigService no responde; en produccion se SUSTITUYE sin republicar publicando la
	clave "FishFortune_LiveOps" en Creator Hub > Configs (ver README, "LiveOps sin republicar").

	Vive en el SERVIDOR (no en ReplicatedStorage) para no exponer los codigos de canje al cliente.
	Los textos de los eventos son de uso GRATUITO (no hay suerte ni azar comprable: FeatureFlags.paidLuckEnabled).
]]

local WEEK = 7 * 24 * 3600
-- Lunes 2026-10-19 00:00:00 UTC
local ANCHOR = 1792368000

return {
	version = 1,
	events = {
		{
			id = "golden_tide",
			name = "Marea Dorada",
			description = "Las monedas por venta se multiplican por 2 durante este evento.",
			cycle = { anchor = ANCHOR, slotSeconds = WEEK, slotCount = 2, slot = 0 },
			modifiers = { coins = 2 } :: { [string]: number },
		},
		{
			id = "mythic_moon",
			name = "Luna Mitica",
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
		message = "Bienvenido a Fish & Fortune. Lanza la cana, descubre criaturas y completa el bestiario.",
	},
	season = { id = 1, name = "Temporada 1", startsAt = ANCHOR, endsAt = ANCHOR + 8 * WEEK },
} :: { [string]: any } -- forma validada en runtime por packages/LiveOps (validateConfig)
