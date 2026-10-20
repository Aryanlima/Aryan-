--!strict
--[[
	Catalog: catalogo de la tienda de Fish & Fortune (nombres, descripciones, escalon de precio y contenido).
	Los IDs vienen de server/ProductIds.luau y los importes de shared/Balance.luau.

	Reglas de honestidad (ROBLOX/research/03 2.3), comprobadas por tests/Catalog.spec.luau:
	  * Sin lenguaje de presion ni "ofertas"/descuentos/temporizadores inventados.
	  * Lo que altera probabilidades (Suerte+, Cebo de Suerte) esta marcado `affectsOdds` y se oculta si
	    PolicyService restringe los objetos aleatorios de pago; ningun pase promocionado puede alterarlas.
	  * v1: esos dos objetos estan APAGADOS por el flag FeatureFlags.paidLuckEnabled (= false): salen del
	    catalogo con `enabled = false` (no se muestran, no se compran y sus recibos se rechazan).
	  * El pack de inicio no incluye azar ni bonus de suerte.

	// REVIEW(money): precios y contenido de cada producto; revisar antes de publicar.
]]

local Catalog = {}

-- Escalera de precios propia del juego (R$). Es una hipotesis para A/B test, no un dato de mercado.
Catalog.ladder = {
	impulse = 49,
	basic = 99,
	value = 199,
	plus = 249,
	standard = 299,
	strong = 399,
	major = 499,
	premium = 999,
	anchor = 1999,
}

function Catalog.build(
	ids: { passes: { [string]: number }, products: { [string]: number } },
	balance: any,
	flags: { paidLuckEnabled: boolean }?
): any
	local products = balance.products
	local paidLuckEnabled = flags ~= nil and flags.paidLuckEnabled == true -- por defecto APAGADO (v1)
	return {
		priceLadder = Catalog.ladder,
		passes = {
			auto_fish = {
				key = "auto_fish",
				id = ids.passes.auto_fish,
				name = "Pase Auto-Pesca",
				description = "Pesca automaticamente mientras juegas y sube a 6 horas el limite de ganancias sin conexion.",
				tier = "standard",
			},
			double_coins = {
				key = "double_coins",
				id = ids.passes.double_coins,
				name = "Pase 2x Dinero",
				description = "Duplica las monedas que ganas al vender. Se suma a otros bonus, con un tope.",
				tier = "plus",
			},
			luck_plus = {
				key = "luck_plus",
				id = ids.passes.luck_plus,
				name = "Pase Suerte+",
				description = "Suma "
					.. tostring(products.passes.luckPlus)
					.. " puntos de suerte de forma permanente. Cambia las probabilidades: miralo en el panel Probabilidades.",
				tier = "strong",
				affectsOdds = true,
				enabled = paidLuckEnabled,
			},
			starter = {
				key = "starter",
				id = ids.passes.starter,
				name = "Pack de inicio",
				description = "Pago unico: " .. tostring(products.starterPack.coins) .. " monedas, " .. tostring(
					products.starterPack.pearls
				) .. " perlas y " .. tostring(products.starterPack.slots) .. " espacios de inventario.",
				tier = "basic",
				oneTimeGrant = {
					kind = "currency",
					coins = products.starterPack.coins,
					pearls = products.starterPack.pearls,
					slots = products.starterPack.slots,
				},
			},
			vip = {
				key = "vip",
				id = ids.passes.vip,
				name = "Pase VIP",
				description = "Etiqueta VIP, +10% de monedas y "
					.. tostring(balance.vip.dailyPearls)
					.. " perlas al dia.",
				tier = "value",
			},
			season_pass = {
				key = "season_pass",
				id = ids.passes.season_pass,
				name = "Pase de Temporada 1",
				description = "Desbloquea la pista premium de la Temporada 1: premios fijos, sin azar.",
				tier = "strong",
			},
		},
		products = {
			lucky_bait_15 = {
				key = "lucky_bait_15",
				id = ids.products.lucky_bait_15,
				name = "Cebo de Suerte (15 min)",
				description = "+"
					.. tostring(products.luckyBait.luck)
					.. " de suerte durante 15 minutos. Cambia las probabilidades: miralo en el panel Probabilidades.",
				kind = "boost",
				grant = { boostId = "lucky_bait", seconds = products.luckyBait.seconds },
				tier = "impulse",
				affectsOdds = true,
				enabled = paidLuckEnabled,
			},
			coin_boost_15 = {
				key = "coin_boost_15",
				id = ids.products.coin_boost_15,
				name = "Boost de Monedas (15 min)",
				description = "Duplica las monedas de venta durante 15 minutos (suma con otros bonus, con tope).",
				kind = "boost",
				grant = { boostId = "coin_boost", seconds = products.coinBoost.seconds },
				tier = "impulse",
			},
			coin_pack_small = {
				key = "coin_pack_small",
				id = ids.products.coin_pack_small,
				name = "Pack de monedas pequeno",
				description = tostring(products.coinPackSmall.coins) .. " monedas.",
				kind = "currency",
				grant = { coins = products.coinPackSmall.coins },
				tier = "basic",
			},
			coin_pack_medium = {
				key = "coin_pack_medium",
				id = ids.products.coin_pack_medium,
				name = "Pack de monedas mediano",
				description = tostring(products.coinPackMedium.coins) .. " monedas.",
				kind = "currency",
				grant = { coins = products.coinPackMedium.coins },
				tier = "major",
			},
			coin_pack_large = {
				key = "coin_pack_large",
				id = ids.products.coin_pack_large,
				name = "Pack de monedas grande",
				description = tostring(products.coinPackLarge.coins) .. " monedas.",
				kind = "currency",
				grant = { coins = products.coinPackLarge.coins },
				tier = "anchor",
			},
			pearl_pack = {
				key = "pearl_pack",
				id = ids.products.pearl_pack,
				name = "Pack de perlas",
				description = tostring(products.pearlPack.pearls) .. " perlas para ampliar tu inventario.",
				kind = "currency",
				grant = { pearls = products.pearlPack.pearls },
				tier = "value",
			},
			slot_pack = {
				key = "slot_pack",
				id = ids.products.slot_pack,
				name = "Mas espacio (+" .. tostring(products.slotPack.slots) .. ")",
				description = "Suma " .. tostring(products.slotPack.slots) .. " espacios a tu inventario.",
				kind = "slots",
				grant = { slots = products.slotPack.slots },
				tier = "basic",
			},
		},
	}
end

return Catalog
