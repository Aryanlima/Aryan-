--!strict
--[[
	ClientLogic: logica PURA del cliente (sin motor): guia del tutorial (FTUE), cuenta atras exacta y textos.
	Esta en `shared` solo para poder probarla con Lune (tests/ClientLogic.spec.luau); el cliente la usa tal cual.
]]

export type Hint = { id: string, text: string, target: string } -- target: "cast" | "sell" | "rods" | "bestiary"

local ClientLogic = {}

--[[
	Guia de los primeros 60 s (research/07 4.1). Devuelve la sugerencia actual o nil.
	  * 0-5 s:   objetivo visible (Lanzar), cero menus previos
	  * primera captura -> vender -> comprar la primera mejora -> bestiario
]]
function ClientLogic.ftueHint(state: any, balance: any, isCasting: boolean): Hint?
	if state == nil then
		return nil
	end
	if state.totalCasts == 0 and not isCasting then
		return { id = "cast", text = "Pulsa LANZAR para pescar", target = "cast" }
	end
	if state.totalCasts == 0 and isCasting then
		return { id = "reel", text = "Pulsa RECOGER cuando el marcador pase por la zona verde", target = "cast" }
	end
	if state.inventoryCount > 0 and state.ftueStep < 4 then
		return { id = "sell", text = "Pulsa VENDER para convertir tus peces en monedas", target = "sell" }
	end
	local nextRodId: string? = nil
	for _, rodId in balance.rodOrder do
		if not state.ownedRods[rodId] then
			nextRodId = rodId
			break
		end
	end
	if nextRodId ~= nil and state.ftueStep < 5 and state.coins >= balance.rods[nextRodId].price then
		return { id = "rods", text = "Ya puedes mejorar tu cana: abre CANAS", target = "rods" }
	end
	if state.ftueStep >= 5 and state.discoveries < 5 and state.totalCasts < 12 then
		return { id = "bestiary", text = "Descubre criaturas para completar el bestiario", target = "bestiary" }
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

-- Texto del banner global de MITICO.
function ClientLogic.bannerText(payload: any): string
	local prefix = if payload.vip then "[VIP] " else ""
	return ("%s%s pesco un MITICO: %s (%s)"):format(
		prefix,
		tostring(payload.player),
		tostring(payload.creature),
		tostring(payload.zone)
	)
end

-- Mensaje neutro para los motivos de rechazo enviados por el servidor ("CastFailed").
function ClientLogic.failureText(reason: string): string?
	local texts: { [string]: string } = {
		cooldown = "Espera un momento antes de volver a lanzar.",
		["inventory-full"] = "Inventario lleno: vende tus capturas.",
		expired = "Se solto el pez. Vuelve a lanzar.",
		stale = "Se solto el pez. Vuelve a lanzar.",
		["not-enough-coins"] = "No tienes monedas suficientes.",
		["not-enough-pearls"] = "No tienes perlas suficientes.",
		locked = "Esa zona todavia esta bloqueada.",
		["not-reached"] = "Todavia no has llegado a ese objetivo.",
		["needs-pass"] = "Necesitas el pase correspondiente.",
		["needs-vip"] = "Necesitas el Pase VIP.",
		claimed = "Ya reclamaste esa recompensa.",
		restricted = "No disponible en tu region.",
		owned = "Ya lo tienes.",
		unavailable = "No disponible por ahora.",
		loading = "Cargando tus datos...",
		["max-slots"] = "Ya tienes el maximo de espacio.",
	}
	-- motivos tecnicos (too-early, no-cast, impossible-time...) no se muestran al jugador
	return texts[reason]
end

return ClientLogic
