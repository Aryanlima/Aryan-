--!strict
--[[
	ClientLogic: logica PURA del cliente (sin motor): guia del tutorial (FTUE), cuenta atras exacta y claves de texto.
	Devuelve CLAVES de texto (shared/Strings.luau), nunca texto: el cliente las traduce al idioma del jugador (packages/Locale).
	Esta en `shared` solo para poder probarla con Lune (tests/ClientLogic.spec.luau); el cliente la usa tal cual.
]]

export type Hint = { id: string, key: string, target: string } -- key: clave de Strings; target: "cast" | "sell" | "rods" | "bestiary"

local ClientLogic = {}

--[[
	Guia de los primeros 60 s (ROBLOX/research/07 4.1). Devuelve la sugerencia actual o nil.
	  * 0-5 s:   objetivo visible (Lanzar), cero menus previos
	  * primera captura -> vender -> comprar la primera mejora -> bestiario
]]
function ClientLogic.ftueHint(state: any, balance: any, isCasting: boolean): Hint?
	if state == nil then
		return nil
	end
	if state.totalCasts == 0 and not isCasting then
		return { id = "cast", key = "hint.cast", target = "cast" }
	end
	if state.totalCasts == 0 and isCasting then
		return { id = "reel", key = "hint.reel", target = "cast" }
	end
	if state.inventoryCount > 0 and state.ftueStep < 4 then
		return { id = "sell", key = "hint.sell", target = "sell" }
	end
	local nextRodId: string? = nil
	for _, rodId in balance.rodOrder do
		if not state.ownedRods[rodId] then
			nextRodId = rodId
			break
		end
	end
	if nextRodId ~= nil and state.ftueStep < 5 and state.coins >= balance.rods[nextRodId].price then
		return { id = "rods", key = "hint.rods", target = "rods" }
	end
	if state.ftueStep >= 5 and state.discoveries < 5 and state.totalCasts < 12 then
		return { id = "bestiary", key = "hint.bestiary", target = "bestiary" }
	end
	return nil
end

--[[
	Segundos que faltan hasta `endsAt` (epoch). Se calcula con el reloj del servidor del ultimo estado
	recibido + lo que ha pasado en el reloj local, asi la cuenta atras es EXACTA y nunca se reinicia sola.
]]
function ClientLogic.remainingSeconds(
	endsAt: number,
	serverNowAtReceive: number,
	localClockAtReceive: number,
	localClockNow: number
): number
	local estimatedServerNow = serverNowAtReceive + math.max(0, localClockNow - localClockAtReceive)
	return math.max(0, endsAt - estimatedServerNow)
end

--[[
	Vista del panel de probabilidades en el idioma del jugador: pone el nombre de cada criatura y adapta SOLO los separadores de
	los porcentajes (ES "12,34 %", EN "12.34%"). Las cifras son exactamente las mismas en todos los idiomas (lo comprueba
	tests/ClientLogic.spec.luau). `locale` = instancia de packages/Locale (inyectada: este modulo no hace require).
]]
function ClientLogic.localizeOddsView(view: any, locale: any, language: string): any
	for _, row in view.rows do
		row.label = locale:format(language, "creature." .. row.id)
		row.percentText = locale:percent(language, row.percentText)
		row.basePercentText = locale:percent(language, row.basePercentText)
	end
	view.totalPercentText = locale:percent(language, view.totalPercentText)
	view.baseTotalPercentText = locale:percent(language, view.baseTotalPercentText)
	return view
end

-- Motivos de rechazo del servidor ("CastFailed") que se muestran al jugador; cada uno tiene su texto `fail.<motivo>` en Strings.
-- Los motivos tecnicos (too-early, no-cast, impossible-time...) no se muestran.
ClientLogic.FAILURE_REASONS = {
	"cooldown",
	"inventory-full",
	"expired",
	"missed",
	"not-at-water",
	"stale",
	"not-enough-coins",
	"not-enough-pearls",
	"locked",
	"not-reached",
	"needs-pass",
	"needs-vip",
	"need-discoveries",
	"claimed",
	"restricted",
	"owned",
	"unavailable",
	"loading",
	"max-slots",
	"maxed",
}

local failureSet: { [string]: boolean } = {}
for _, reason in ClientLogic.FAILURE_REASONS do
	failureSet[reason] = true
end

-- Clave de texto neutro para un motivo de rechazo, o nil si es tecnico (no se muestra).
function ClientLogic.failureKey(reason: string): string?
	if type(reason) == "string" and failureSet[reason] then
		return "fail." .. reason
	end
	return nil
end

return ClientLogic
