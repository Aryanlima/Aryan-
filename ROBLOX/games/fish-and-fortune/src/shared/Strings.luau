--!strict
--[[
	Strings: TODOS los textos visibles al jugador de Fish & Fortune, en UN solo archivo y lado a lado (ES | EN) para que una
	persona los revise de un vistazo. Datos puros (sin logica ni requires): seguro para ReplicatedStorage.

	Como se usa (ver packages/Locale.luau y el README del juego):
	  * clave -> { es = "...", en = "..." }. Con plural: { es = { one = "...", other = "..." }, en = { ... } }; el argumento
	    `count` elige la variante.
	  * Marcadores `{nombre}`: los mismos nombres en ES y EN (lo comprueba tests/Strings.spec.luau).
	  * Numeros: pasa un numero y se formatea segun el idioma (1.500 / 1,500); pasa una cadena si ya viene formateada
	    (p. ej. "1,2K"). `{ key = "creature.minnow" }` inserta otro texto (nombre de una criatura, zona...).
	  * El servidor NUNCA envia texto: envia claves (prefijos `messagePrefixes`) con argumentos validados (Locale.sanitizeMessage).
	  * Falta un idioma o una clave => se usa ES. Para anadir un idioma: un campo mas en cada entrada y su nombre en `languages`.

	Tono (ES y EN): neutro y honesto. Sin urgencia, sin presion de compra, sin "ofertas" ni cuenta atras falsa (lo comprueba la
	prueba de lenguaje de presion sobre TODOS los textos). Cada texto de tienda dice que hace el objeto y, si cambia las
	probabilidades, lo dice claro.

	Claves dinamicas (las construye el codigo con un prefijo; las pruebas las cruzan con los datos del juego):
	  creature.<id>  rod.<id>  rarity.<Rareza>  zone.<id>.name|desc  bestiary.reward.<id>  pass.<clave>.name|desc
	  product.<clave>.name|desc  event.<id>.name  season.<id>.name  welcome.<id>  fail.<motivo>
]]

export type Plural = { one: string?, other: string }
export type Text = string | Plural
export type Entry = { [string]: Text }

local entries: { [string]: Entry } = {
	----------------------------------------------------------------------------
	-- HUD
	----------------------------------------------------------------------------
	["hud.coins"] = { es = "Monedas: {amount}", en = "Coins: {amount}" },
	["hud.pearls"] = { es = "Perlas: {amount}", en = "Pearls: {amount}" },
	["hud.bag"] = { es = "Mochila: {used} / {capacity}", en = "Bag: {used} / {capacity}" },
	["hud.zone_private"] = { es = "{zone} - Servidor privado", en = "{zone} - Private server" },
	["hud.cast"] = { es = "LANZAR", en = "CAST" },
	["hud.reel"] = { es = "RECOGER", en = "REEL IN" },
	["hud.sell"] = { es = "VENDER", en = "SELL" },
	["hud.sell_count"] = { es = "VENDER ({count})", en = "SELL ({count})" },
	["hud.auto_on"] = { es = "Auto-pesca: SÍ", en = "Auto-fishing: ON" },
	["hud.auto_off"] = { es = "Auto-pesca: NO", en = "Auto-fishing: OFF" },
	["hud.event_line"] = { es = "{name} ({effects}): {time}", en = "{name} ({effects}): {time}" },
	["hud.effect_coins"] = { es = "monedas x{value}", en = "coins x{value}" },
	["hud.effect_luck"] = { es = "suerte +{value}", en = "luck +{value}" },

	["menu.shop"] = { es = "Tienda", en = "Shop" },
	["menu.rods"] = { es = "Cañas", en = "Rods" },
	["menu.bestiary"] = { es = "Bestiario", en = "Bestiary" },
	["menu.season"] = { es = "Temporada", en = "Season" },
	["menu.odds"] = { es = "Probabilidades", en = "Odds" },
	["menu.codes"] = { es = "Códigos", en = "Codes" },

	----------------------------------------------------------------------------
	-- Tutorial (FTUE) y minijuego
	----------------------------------------------------------------------------
	["hint.cast"] = { es = "Pulsa LANZAR para pescar", en = "Press CAST to start fishing" },
	["hint.reel"] = {
		es = "Pulsa RECOGER cuando el marcador pase por la zona verde",
		en = "Press REEL IN when the marker crosses the green zone",
	},
	["hint.sell"] = {
		es = "Pulsa VENDER para convertir tus peces en monedas",
		en = "Press SELL to turn your fish into coins",
	},
	["hint.rods"] = {
		es = "Ya puedes mejorar tu caña: abre CAÑAS",
		en = "You can upgrade your rod now: open RODS",
	},
	["hint.bestiary"] = {
		es = "Descubre criaturas para completar el bestiario",
		en = "Discover creatures to fill your bestiary",
	},

	----------------------------------------------------------------------------
	-- Capturas y banner global de Mítico
	----------------------------------------------------------------------------
	["catch.value"] = { es = "Valor: {amount} monedas", en = "Value: {amount} coins" },
	["catch.new"] = { es = "NUEVO en tu bestiario", en = "NEW in your bestiary" },
	["catch.autosold"] = { es = "Mochila llena: vendida por {amount}", en = "Bag full: sold for {amount}" },
	["banner.mythic"] = {
		es = "{player} pescó un MÍTICO: {creature} ({zone})",
		en = "{player} caught a MYTHIC: {creature} ({zone})",
	},
	["banner.mythic_vip"] = {
		es = "[VIP] {player} pescó un MÍTICO: {creature} ({zone})",
		en = "[VIP] {player} caught a MYTHIC: {creature} ({zone})",
	},

	----------------------------------------------------------------------------
	-- Avisos (toast) enviados por el servidor
	----------------------------------------------------------------------------
	["toast.nothing_to_sell"] = { es = "No tienes nada que vender.", en = "You have nothing to sell." },
	["toast.sold"] = {
		es = {
			one = "Vendiste 1 captura por {coins} monedas.",
			other = "Vendiste {count} capturas por {coins} monedas.",
		},
		en = { one = "Sold 1 catch for {coins} coins.", other = "Sold {count} catches for {coins} coins." },
	},
	["toast.rod_bought"] = { es = "Caña comprada y equipada.", en = "Rod bought and equipped." },
	["toast.zone_unlocked"] = { es = "Zona desbloqueada.", en = "Zone unlocked." },
	["toast.autofish_needs_pass"] = {
		es = "La pesca automática necesita el Pase Auto-Pesca.",
		en = "Auto-fishing needs the Auto-Fishing Pass.",
	},
	["toast.bestiary_claimed"] = { es = "Recompensa del bestiario reclamada.", en = "Bestiary reward claimed." },
	["toast.season_claimed"] = { es = "Recompensa de temporada reclamada.", en = "Season reward claimed." },
	["toast.daily_claimed"] = { es = "Perlas diarias VIP reclamadas.", en = "Daily VIP pearls claimed." },
	["toast.slots_expanded"] = { es = "Espacio de inventario ampliado.", en = "Inventory space expanded." },
	["toast.offline"] = {
		es = {
			one = "Mientras no estabas ({minutes} min): +{coins} moneda.",
			other = "Mientras no estabas ({minutes} min): +{coins} monedas.",
		},
		en = {
			one = "While you were away ({minutes} min): +{coins} coin.",
			other = "While you were away ({minutes} min): +{coins} coins.",
		},
	},
	["toast.purchase_received"] = { es = "Compra recibida: {item}", en = "Purchase received: {item}" },
	-- Texto ya redactado (p. ej. un mensaje de bienvenida de la configuracion remota sin traduccion propia).
	["toast.raw"] = { es = "{text}", en = "{text}" },
	["toast.code_redeemed"] = { es = "Código canjeado.", en = "Code redeemed." },
	["toast.code_invalid"] = { es = "Ese código no es válido.", en = "That code isn't valid." },
	["toast.code_unknown"] = { es = "Ese código no existe.", en = "That code doesn't exist." },
	["toast.code_not_started"] = { es = "Ese código todavía no está activo.", en = "That code isn't active yet." },
	["toast.code_expired"] = { es = "Ese código ha caducado.", en = "That code has expired." },
	["toast.code_already"] = { es = "Ya canjeaste ese código.", en = "You've already redeemed that code." },
	["toast.code_failed"] = {
		es = "Ese código no se pudo canjear ahora. Prueba más tarde.",
		en = "That code couldn't be redeemed right now. Please try again later.",
	},
	["welcome.launch"] = {
		es = "Bienvenido a Fish & Fortune. Lanza la caña, descubre criaturas y completa el bestiario.",
		en = "Welcome to Fish & Fortune. Cast your rod, discover creatures and complete the bestiary.",
	},

	----------------------------------------------------------------------------
	-- Motivos de rechazo (remoto CastFailed). Los motivos tecnicos (too-early, no-cast...) no se muestran.
	----------------------------------------------------------------------------
	["fail.cooldown"] = {
		es = "Espera un momento antes de volver a lanzar.",
		en = "Wait a moment before casting again.",
	},
	["fail.inventory-full"] = { es = "Mochila llena: vende tus capturas.", en = "Your bag is full: sell your catches." },
	["fail.expired"] = { es = "Se soltó el pez. Vuelve a lanzar.", en = "The fish got away. Cast again." },
	["fail.stale"] = { es = "Se soltó el pez. Vuelve a lanzar.", en = "The fish got away. Cast again." },
	["fail.not-enough-coins"] = { es = "No tienes monedas suficientes.", en = "You don't have enough coins." },
	["fail.not-enough-pearls"] = { es = "No tienes perlas suficientes.", en = "You don't have enough pearls." },
	["fail.locked"] = { es = "Esa zona todavía está bloqueada.", en = "That zone is still locked." },
	["fail.not-reached"] = { es = "Todavía no has llegado a ese objetivo.", en = "You haven't reached that goal yet." },
	["fail.needs-pass"] = { es = "Necesitas el pase correspondiente.", en = "You need the matching pass." },
	["fail.needs-vip"] = { es = "Necesitas el Pase VIP.", en = "You need the VIP Pass." },
	["fail.claimed"] = { es = "Ya reclamaste esa recompensa.", en = "You've already claimed that reward." },
	["fail.restricted"] = { es = "No disponible en tu región.", en = "Not available in your region." },
	["fail.owned"] = { es = "Ya lo tienes.", en = "You already have it." },
	["fail.unavailable"] = { es = "No disponible por ahora.", en = "Not available right now." },
	["fail.loading"] = { es = "Cargando tus datos...", en = "Loading your data..." },
	["fail.max-slots"] = { es = "Ya tienes el máximo de espacio.", en = "You already have the maximum space." },
	["fail.maxed"] = {
		es = "Ya tienes el máximo acumulado: no se puede comprar más por ahora.",
		en = "You've reached the maximum: you can't buy more for now.",
	},

	----------------------------------------------------------------------------
	-- Expulsiones (Data). El servidor no conoce el idioma antes de que cargue el cliente: se muestran ES y EN juntos.
	----------------------------------------------------------------------------
	["kick.load_failed"] = {
		es = "No pudimos cargar tus datos. Tu progreso está a salvo: vuelve a entrar en un momento.",
		en = "We couldn't load your data. Your progress is safe: please rejoin in a moment.",
	},
	["kick.locked"] = {
		es = "Tu sesión anterior aún se está cerrando. Espera un minuto y vuelve a entrar.",
		en = "Your previous session is still closing. Wait a minute and rejoin.",
	},
	["kick.newer_version"] = {
		es = "Este servidor está desactualizado. Vuelve a entrar para unirte a una versión nueva.",
		en = "This server is out of date. Rejoin to get a newer version.",
	},
	["kick.lock_lost"] = {
		es = "Tu sesión se abrió en otro servidor. Vuelve a entrar.",
		en = "Your session was opened on another server. Please rejoin.",
	},

	----------------------------------------------------------------------------
	-- Cañas, zonas y mochila
	----------------------------------------------------------------------------
	["rods.title"] = { es = "Cañas y zonas", en = "Rods & zones" },
	["rods.header"] = { es = "Cañas", en = "Rods" },
	["rods.stats"] = {
		es = "Suerte +{luck} - zona perfecta {sweet}% - auto cada {interval}s",
		en = "Luck +{luck} - perfect zone {sweet}% - auto every {interval}s",
	},
	["rods.equipped"] = { es = "Equipada", en = "Equipped" },
	["rods.equip"] = { es = "Equipar", en = "Equip" },
	["rods.buy"] = { es = "Comprar - {price} monedas", en = "Buy - {price} coins" },
	["zones.header"] = { es = "Zonas", en = "Zones" },
	["zones.here"] = { es = "Estás aquí", en = "You're here" },
	["zones.travel"] = { es = "Viajar", en = "Travel" },
	["zones.unlock"] = { es = "Desbloquear - {price} monedas", en = "Unlock - {price} coins" },
	["bag.header"] = { es = "Mochila", en = "Bag" },
	["bag.space"] = { es = "Espacio: {used} / {capacity}", en = "Space: {used} / {capacity}" },
	["bag.expand"] = { es = "Ampliar +{slots} con {pearls} perlas", en = "Expand +{slots} for {pearls} pearls" },
	["vip.daily"] = { es = "Perlas diarias: +{pearls}", en = "Daily pearls: +{pearls}" },
	["vip.claim"] = { es = "Reclamar perlas de hoy", en = "Claim today's pearls" },
	["vip.claimed"] = { es = "Ya reclamadas hoy", en = "Already claimed today" },

	----------------------------------------------------------------------------
	-- Bestiario
	----------------------------------------------------------------------------
	["bestiary.title"] = { es = "Bestiario", en = "Bestiary" },
	["bestiary.found"] = { es = "Descubiertas: {found} / {total}", en = "Discovered: {found} / {total}" },
	["bestiary.entry"] = { es = "{name}  x{count}  ({rarity})", en = "{name}  x{count}  ({rarity})" },
	["bestiary.unknown"] = { es = "???", en = "???" },
	["bestiary.rewards"] = { es = "Recompensas", en = "Rewards" },
	["bestiary.claimed"] = { es = "Reclamada", en = "Claimed" },
	["bestiary.claim"] = { es = "Reclamar", en = "Claim" },
	["bestiary.not_yet"] = { es = "Aún no", en = "Not yet" },
	["bestiary.reward.disc_5"] = { es = "Descubre 5 criaturas", en = "Discover 5 creatures" },
	["bestiary.reward.disc_10"] = { es = "Descubre 10 criaturas", en = "Discover 10 creatures" },
	["bestiary.reward.disc_15"] = { es = "Descubre 15 criaturas", en = "Discover 15 creatures" },
	["bestiary.reward.disc_20"] = { es = "Descubre 20 criaturas", en = "Discover 20 creatures" },
	["bestiary.reward.disc_25"] = { es = "Bestiario completo", en = "Complete bestiary" },
	["bestiary.reward.zone_lake"] = { es = "Completa el Lago Calmo", en = "Complete Calm Lake" },
	["bestiary.reward.zone_river"] = { es = "Completa el Río Cristal", en = "Complete Crystal River" },
	["bestiary.reward.zone_coast"] = { es = "Completa la Costa Dorada", en = "Complete Golden Coast" },

	-- Premios (monedas / perlas / espacios). `count` elige singular o plural; `amount` ya viene abreviado (1,2K).
	["reward.coins"] = {
		es = { one = "{amount} moneda", other = "{amount} monedas" },
		en = { one = "{amount} coin", other = "{amount} coins" },
	},
	["reward.pearls"] = {
		es = { one = "{amount} perla", other = "{amount} perlas" },
		en = { one = "{amount} pearl", other = "{amount} pearls" },
	},
	["reward.slots"] = {
		es = { one = "{amount} espacio", other = "{amount} espacios" },
		en = { one = "{amount} slot", other = "{amount} slots" },
	},

	----------------------------------------------------------------------------
	-- Temporada
	----------------------------------------------------------------------------
	["season.none"] = {
		es = "No hay una temporada activa ahora mismo.",
		en = "There's no active season right now.",
	},
	["season.points"] = { es = "Puntos: {points} - termina en {time}", en = "Points: {points} - ends in {time}" },
	["season.premium_title"] = { es = "Pista premium", en = "Premium track" },
	["season.premium_desc"] = {
		es = "Premios fijos, sin azar. Pase de Temporada.",
		en = "Fixed rewards, no randomness. Season Pass.",
	},
	["season.view_pass"] = { es = "Ver Pase de Temporada", en = "View Season Pass" },
	["season.tier"] = { es = "Nivel {tier} - {points} puntos", en = "Tier {tier} - {points} points" },
	["season.free_line"] = { es = "Gratis: {reward} - {status}", en = "Free: {reward} - {status}" },
	["season.premium_line"] = { es = "Premium: {reward} - {status}", en = "Premium: {reward} - {status}" },
	["season.status_claimed"] = { es = "reclamada", en = "claimed" },
	["season.status_claimable"] = { es = "reclamar", en = "claim" },
	["season.status_locked"] = { es = "bloqueada", en = "locked" },
	-- Nombre de la temporada (si una temporada nueva llega por configuracion remota sin clave propia, se usa su nombre).
	["season.1.name"] = { es = "Temporada 1", en = "Season 1" },

	----------------------------------------------------------------------------
	-- Eventos (nombres; los de la configuracion remota sin clave propia usan el nombre configurado)
	----------------------------------------------------------------------------
	["event.golden_tide.name"] = { es = "Marea Dorada", en = "Golden Tide" },
	["event.mythic_moon.name"] = { es = "Luna Mítica", en = "Mythic Moon" },

	----------------------------------------------------------------------------
	-- Códigos
	----------------------------------------------------------------------------
	["codes.intro"] = {
		es = "Escribe un código y pulsa Canjear. Cada código se puede usar una vez.",
		en = "Type a code and press Redeem. Each code can be used once.",
	},
	["codes.placeholder"] = { es = "CÓDIGO", en = "CODE" },
	["codes.redeem"] = { es = "Canjear", en = "Redeem" },

	----------------------------------------------------------------------------
	-- Probabilidades (cumplimiento: mismas cifras en todos los idiomas; solo cambia el texto alrededor)
	----------------------------------------------------------------------------
	["odds.title"] = { es = "Probabilidades - {zone}", en = "Odds - {zone}" },
	["odds.luck_total"] = {
		es = "Suerte total activa: +{luck} (tope {cap})",
		en = "Total active luck: +{luck} (cap {cap})",
	},
	["odds.luck_line"] = { es = "- {label}: +{value}{paid}", en = "- {label}: +{value}{paid}" },
	["odds.paid_suffix"] = { es = " (de pago)", en = " (paid)" },
	["odds.luck_explanation"] = {
		es = "Tu suerte activa cambia estas probabilidades. La columna 'base' muestra los valores sin suerte. Un lanzamiento perfecto suma además +{perfect} de suerte gratis.",
		en = "Your active luck changes these odds. The 'base' column shows the values without luck. A perfect cast also adds +{perfect} free luck.",
	},
	["odds.restricted"] = {
		es = "En tu región los objetos aleatorios de pago están restringidos: no se ofrecen ni se aplican.",
		en = "Paid random items are restricted in your region: they aren't offered or applied.",
	},
	["odds.source.perfect"] = { es = "Lanzamiento perfecto", en = "Perfect cast" },
	["odds.source.event"] = { es = "Evento", en = "Event" },
	["ftue.odds_note"] = {
		es = "Tus {count} primeros lanzamientos son un tutorial con premio garantizado (no cuentan como probabilidad normal).",
		en = "Your first {count} casts are a tutorial with a guaranteed prize (they don't count as normal odds).",
	},

	----------------------------------------------------------------------------
	-- Tienda y componentes de interfaz (packages/UI)
	----------------------------------------------------------------------------
	["shop.title"] = { es = "Tienda", en = "Shop" },
	["shop.note"] = {
		es = "Los precios los define Roblox. Cada compra se confirma en la ventana de Roblox.",
		en = "Prices are set by Roblox. Every purchase is confirmed in a Roblox window.",
	},
	["ui.close"] = { es = "Cerrar", en = "Close" },
	["ui.price"] = { es = "R$ {price}", en = "R$ {price}" },
	["ui.price_approx"] = { es = "~R$ {price}", en = "~R$ {price}" },
	["ui.price_unavailable"] = { es = "Precio no disponible", en = "Price not available" },
	["ui.buy"] = { es = "Ver compra", en = "View item" },
	["ui.reason.owned"] = { es = "Ya lo tienes", en = "Owned" },
	["ui.reason.unavailable"] = { es = "No disponible por ahora", en = "Not available right now" },
	["ui.reason.loading"] = { es = "Cargando tus datos...", en = "Loading your data..." },
	["ui.reason.restricted"] = { es = "No disponible en tu región", en = "Not available in your region" },
	["ui.reason.left"] = { es = "No disponible", en = "Not available" },
	["ui.reason.cooldown"] = { es = "Espera un momento", en = "Please wait a moment" },
	["ui.reason.maxed"] = { es = "Ya tienes el máximo acumulado", en = "You're at the maximum for now" },
	["ui.reason.unknown"] = { es = "No disponible", en = "Not available" },
	["ui.odds_title"] = { es = "Probabilidades", en = "Odds" },
	["ui.odds_luck_default"] = {
		es = "Tu suerte activa cambia estas probabilidades. La columna 'base' muestra los valores sin suerte.",
		en = "Your active luck changes these odds. The 'base' column shows the values without luck.",
	},
	["ui.odds_with_base"] = { es = "{percent} (base {base})", en = "{percent} (base {base})" },
	["ui.odds_total"] = { es = "Total: {total}", en = "Total: {total}" },
	["ui.odds_rounding"] = {
		es = "Los porcentajes están redondeados para sumar exactamente {total}.",
		en = "Percentages are rounded so they add up to exactly {total}.",
	},

	----------------------------------------------------------------------------
	-- Rarezas
	----------------------------------------------------------------------------
	["rarity.Common"] = { es = "Común", en = "Common" },
	["rarity.Uncommon"] = { es = "Poco común", en = "Uncommon" },
	["rarity.Rare"] = { es = "Raro", en = "Rare" },
	["rarity.Epic"] = { es = "Épico", en = "Epic" },
	["rarity.Legendary"] = { es = "Legendario", en = "Legendary" },
	["rarity.Mythic"] = { es = "MÍTICO", en = "MYTHIC" },

	----------------------------------------------------------------------------
	-- Zonas
	----------------------------------------------------------------------------
	["zone.lake.name"] = { es = "Lago Calmo", en = "Calm Lake" },
	["zone.lake.desc"] = {
		es = "Aguas tranquilas para empezar a pescar.",
		en = "Still waters, perfect for getting started.",
	},
	["zone.river.name"] = { es = "Río Cristal", en = "Crystal River" },
	["zone.river.desc"] = {
		es = "Corrientes rápidas y peces más valiosos.",
		en = "Fast currents and more valuable fish.",
	},
	["zone.coast.name"] = { es = "Costa Dorada", en = "Golden Coast" },
	["zone.coast.desc"] = {
		es = "El mar abierto guarda las mayores capturas.",
		en = "The open sea hides the biggest catches.",
	},

	----------------------------------------------------------------------------
	-- Cañas
	----------------------------------------------------------------------------
	["rod.driftwood"] = { es = "Caña de Madera", en = "Driftwood Rod" },
	["rod.reed"] = { es = "Caña de Junco", en = "Reed Rod" },
	["rod.fiberglass"] = { es = "Caña de Fibra", en = "Fiberglass Rod" },
	["rod.carbon"] = { es = "Caña de Carbono", en = "Carbon Rod" },
	["rod.golden"] = { es = "Caña Dorada", en = "Golden Rod" },

	----------------------------------------------------------------------------
	-- Criaturas
	----------------------------------------------------------------------------
	["creature.minnow"] = { es = "Pececillo", en = "Minnow" },
	["creature.perch"] = { es = "Perca", en = "Perch" },
	["creature.carp"] = { es = "Carpa", en = "Carp" },
	["creature.bluegill"] = { es = "Branquia Azul", en = "Bluegill" },
	["creature.catfish"] = { es = "Bagre", en = "Catfish" },
	["creature.golden_trout"] = { es = "Trucha Dorada", en = "Golden Trout" },
	["creature.moon_koi"] = { es = "Koi Lunar", en = "Moon Koi" },
	["creature.ancient_carp"] = { es = "Carpa Ancestral", en = "Ancient Carp" },
	["creature.lake_spirit"] = { es = "Espíritu del Lago", en = "Lake Spirit" },
	["creature.chub"] = { es = "Cacho de Río", en = "River Chub" },
	["creature.salmon"] = { es = "Salmón Plateado", en = "Silver Salmon" },
	["creature.eel"] = { es = "Anguila", en = "Eel" },
	["creature.glass_shrimp"] = { es = "Gamba de Cristal", en = "Glass Shrimp" },
	["creature.rapids_trout"] = { es = "Trucha de los Rápidos", en = "Rapids Trout" },
	["creature.crystal_pike"] = { es = "Lucio de Cristal", en = "Crystal Pike" },
	["creature.aurora_sturgeon"] = { es = "Esturión Aurora", en = "Aurora Sturgeon" },
	["creature.river_queen"] = { es = "Reina del Río", en = "River Queen" },
	["creature.sand_crab"] = { es = "Cangrejo de Arena", en = "Sand Crab" },
	["creature.sardine"] = { es = "Sardina", en = "Sardine" },
	["creature.mackerel"] = { es = "Caballa", en = "Mackerel" },
	["creature.clownfish"] = { es = "Pez Payaso", en = "Clownfish" },
	["creature.tuna"] = { es = "Atún Rojo", en = "Bluefin Tuna" },
	["creature.manta"] = { es = "Manta Gigante", en = "Giant Manta" },
	["creature.golden_marlin"] = { es = "Marlín Dorado", en = "Golden Marlin" },
	["creature.tide_leviathan"] = { es = "Leviatán de la Marea", en = "Tide Leviathan" },

	----------------------------------------------------------------------------
	-- Pases de la tienda (la v1 no vende suerte: luck_plus y lucky_bait_15 estan apagados por FeatureFlags)
	----------------------------------------------------------------------------
	["pass.auto_fish.name"] = { es = "Pase Auto-Pesca", en = "Auto-Fishing Pass" },
	["pass.auto_fish.desc"] = {
		es = "Pesca automáticamente mientras juegas y sube a {hours} horas el límite de ganancias sin conexión.",
		en = "Fishes automatically while you play and raises the offline earnings limit to {hours} hours.",
	},
	["pass.double_coins.name"] = { es = "Pase 2x Dinero", en = "2x Coins Pass" },
	["pass.double_coins.desc"] = {
		es = "Duplica las monedas que ganas al vender. Se suma a otros bonus, con un tope.",
		en = "Doubles the coins you earn when selling. Stacks with other bonuses, up to a cap.",
	},
	["pass.luck_plus.name"] = { es = "Pase Suerte+", en = "Luck+ Pass" },
	["pass.luck_plus.desc"] = {
		es = "Suma {points} puntos de suerte de forma permanente. Cambia las probabilidades: míralo en el panel Probabilidades.",
		en = "Adds {points} luck points permanently. It changes the odds: check them in the Odds panel.",
	},
	["pass.starter.name"] = { es = "Pack de inicio", en = "Starter Pack" },
	["pass.starter.desc"] = {
		es = "Pago único: {coins} monedas, {pearls} perlas y {slots} espacios de inventario.",
		en = "One-time purchase: {coins} coins, {pearls} pearls and {slots} inventory slots.",
	},
	["pass.vip.name"] = { es = "Pase VIP", en = "VIP Pass" },
	["pass.vip.desc"] = {
		es = "Etiqueta VIP, +{percent}% de monedas y {pearls} perlas al día.",
		en = "VIP tag, +{percent}% coins and {pearls} pearls per day.",
	},
	["pass.season_pass.name"] = { es = "Pase de Temporada 1", en = "Season 1 Pass" },
	["pass.season_pass.desc"] = {
		es = "Desbloquea la pista premium de la Temporada 1: premios fijos, sin azar.",
		en = "Unlocks the Season 1 premium track: fixed rewards, no randomness.",
	},
	["pass.golden_rod.name"] = { es = "Caña Dorada", en = "Golden Rod" },
	["pass.golden_rod.desc"] = {
		es = "Tu caña brilla en dorado y suelta chispas. Solo cambia el aspecto; los demás jugadores la ven.",
		en = "Your rod shines gold and gives off sparkles. Looks only; other players can see it.",
	},
	["pass.bubble_trail.name"] = { es = "Estela de Burbujas", en = "Bubble Trail" },
	["pass.bubble_trail.desc"] = {
		es = "Deja una estela de burbujas al moverte. Solo cambia el aspecto; los demás jugadores la ven.",
		en = "Leave a trail of bubbles as you move. Looks only; other players can see it.",
	},

	----------------------------------------------------------------------------
	-- Productos de la tienda
	----------------------------------------------------------------------------
	["product.lucky_bait_15.name"] = { es = "Cebo de Suerte ({minutes} min)", en = "Lucky Bait ({minutes} min)" },
	["product.lucky_bait_15.desc"] = {
		es = "+{luck} de suerte durante {minutes} minutos. Cambia las probabilidades: míralo en el panel Probabilidades.",
		en = "+{luck} luck for {minutes} minutes. It changes the odds: check them in the Odds panel.",
	},
	["product.coin_boost_15.name"] = { es = "Boost de Monedas ({minutes} min)", en = "Coin Boost ({minutes} min)" },
	["product.coin_boost_15.desc"] = {
		es = "Duplica las monedas de venta durante {minutes} minutos (suma con otros bonus, con tope).",
		en = "Doubles sale coins for {minutes} minutes (stacks with other bonuses, up to a cap).",
	},
	["product.coin_pack_small.name"] = { es = "Pack de monedas pequeño", en = "Small Coin Pack" },
	["product.coin_pack_small.desc"] = { es = "{coins} monedas.", en = "{coins} coins." },
	["product.coin_pack_medium.name"] = { es = "Pack de monedas mediano", en = "Medium Coin Pack" },
	["product.coin_pack_medium.desc"] = { es = "{coins} monedas.", en = "{coins} coins." },
	["product.coin_pack_large.name"] = { es = "Pack de monedas grande", en = "Large Coin Pack" },
	["product.coin_pack_large.desc"] = { es = "{coins} monedas.", en = "{coins} coins." },
	["product.pearl_pack.name"] = { es = "Pack de perlas", en = "Pearl Pack" },
	["product.pearl_pack.desc"] = {
		es = "{pearls} perlas para ampliar tu inventario.",
		en = "{pearls} pearls to expand your inventory.",
	},
	["product.slot_pack.name"] = { es = "Más espacio (+{slots})", en = "More Space (+{slots})" },
	["product.slot_pack.desc"] = {
		es = "Suma {slots} espacios a tu inventario.",
		en = "Adds {slots} slots to your inventory.",
	},
}

return {
	default = "en", -- idioma de respaldo (si falta una clave o el idioma del jugador no esta soportado). Decision de Aryan/nube 2026-10-20: EN, porque es la lengua comun mas probable para el resto del mundo; ES y EN estan completos (lo exige Strings.spec)
	languages = { "es", "en" },
	-- Un argumento { key = "..." } solo puede referenciar estos prefijos.
	referenceable = { "creature.", "zone.", "rod.", "pass.", "product.", "rarity." },
	-- Prefijos que el servidor puede enviar como mensaje (toast, banner, bienvenida).
	messagePrefixes = { "toast.", "banner.", "welcome." },
	entries = entries,
}
