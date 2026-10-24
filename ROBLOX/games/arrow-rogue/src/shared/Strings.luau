--!strict
-- Strings: textos ES/EN del cliente. Ingles en Title Case. Strings.get(key, lang) cae a "en" y luego a la clave.
export type Entry = { es: string, en: string }

local function e(es: string, en: string): Entry
	return { es = es, en = en }
end

local entries: { [string]: Entry } = {
	["hud.room"] = e("Sala {room}/{total}", "Room {room}/{total}"),
	["hud.level"] = e("Nivel {level}", "Level {level}"),
	["skill.title"] = e("Elige Una Mejora", "Choose An Upgrade"),
	["rarity.common"] = e("Comun", "Common"),
	["rarity.rare"] = e("Rara", "Rare"),
	["rarity.epic"] = e("Epica", "Epic"),
	["result.victory"] = e("Victoria", "Victory"),
	["result.defeat"] = e("Derrota", "Defeat"),
	["result.reward"] = e("Recompensa: {reward}", "Reward: {reward}"),
	["result.retry"] = e("Reintentar", "Retry"),
	["s01.name"] = e("Pulso Rapido", "Quick Pulse"),
	["s01.desc"] = e("+15% cadencia", "+15% Fire Rate"),
	["s02.name"] = e("Punta Afilada", "Sharp Tip"),
	["s02.desc"] = e("+20% dano", "+20% Damage"),
	["s03.name"] = e("Corazon de Faro", "Lighthouse Heart"),
	["s03.desc"] = e("+20% vida maxima", "+20% Max Health"),
	["s04.name"] = e("Pies de Brisa", "Breeze Feet"),
	["s04.desc"] = e("+10% velocidad", "+10% Move Speed"),
	["s05.name"] = e("Disparo Doble", "Double Shot"),
	["s05.desc"] = e("+1 proyectil", "+1 Projectile"),
	["s06.name"] = e("Flecha Lateral", "Side Arrow"),
	["s06.desc"] = e("+1 flecha a 45 grados", "+1 Arrow At 45 Degrees"),
	["s07.name"] = e("Rebote", "Ricochet"),
	["s07.desc"] = e("Rebota 1 vez mas", "Bounces 1 More Time"),
	["s08.name"] = e("Perforar", "Pierce"),
	["s08.desc"] = e("Atraviesa 1 enemigo mas", "Pierces 1 More Enemy"),
	["s09.name"] = e("Veneno de Alga", "Kelp Venom"),
	["s09.desc"] = e("Dano por pulso 3 s", "Pulse Damage For 3s"),
	["s10.name"] = e("Fuego Calido", "Warm Fire"),
	["s10.desc"] = e("Quema 3 s", "Burns For 3s"),
	["s11.name"] = e("Escarcha", "Frost"),
	["s11.desc"] = e("-20% velocidad enemiga", "-20% Enemy Speed"),
	["s12.name"] = e("Critico Claro", "Clear Crit"),
	["s12.desc"] = e("+10% critico", "+10% Crit Chance"),
	["s13.name"] = e("Escudo de Niebla", "Mist Shield"),
	["s13.desc"] = e("Absorbe 1 golpe", "Absorbs 1 Hit"),
	["s14.name"] = e("Marea Vital", "Vital Tide"),
	["s14.desc"] = e("Cura 1 al matar", "Heals 1 On Kill"),
	["s15.name"] = e("Estampida", "Stampede"),
	["s15.desc"] = e("Mas cadencia tras matar", "Faster Fire After A Kill"),
	["s16.name"] = e("Rafaga Final", "Final Volley"),
	["s16.desc"] = e("Cada 5.o disparo lanza 3", "Every 5th Shot Fires 3"),
	["s17.name"] = e("Lluvia de Estrellas", "Star Rain"),
	["s17.desc"] = e("Cada 8 s cae un area", "Area Strike Every 8s"),
	["s18.name"] = e("Segundo Aliento", "Second Wind"),
	["s18.desc"] = e("Revives 1 vez mas", "Revive 1 More Time"),
	["s19.name"] = e("Ojo del Faro", "Lighthouse Eye"),
	["s19.desc"] = e("+30% dano a jefes", "+30% Boss Damage"),
	["s20.name"] = e("Iman de Brillo", "Shine Magnet"),
	["s20.desc"] = e("Atrae monedas y XP", "Pulls Coins And XP"),
}

local Strings = {}

-- args opcionales: marcadores {nombre}, una sola pasada.
function Strings.get(key: string, lang: string, args: { [string]: any }?): string
	local entry = entries[key]
	if entry == nil then
		return key
	end
	local text = if lang == "es" then entry.es else entry.en
	if args then
		text = string.gsub(text, "{(%w+)}", function(name: string): string
			local v = args[name]
			return if v == nil then `\{{name}}` else tostring(v)
		end)
	end
	return text
end

return Strings
