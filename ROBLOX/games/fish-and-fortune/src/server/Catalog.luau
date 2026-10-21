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

	Textos: nombre y descripcion NO viven aqui sino en shared/Strings.luau (claves `pass.<clave>.name|desc` y
	`product.<clave>.name|desc`, con los importes de Balance como argumentos). `Catalog.build(ids, balance, flags, text)` recibe
	un traductor opcional (en el servidor: espanol) para rellenar `name`/`description` (logs, validacion de lenguaje de presion
	y respaldo); sin traductor `name`/`description` son las propias claves. El cliente traduce con `nameKey`/`descriptionKey`/
	`textArgs` en el idioma del jugador.

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
	deluxe = 799,
	premium = 999,
	anchor = 1999,
}

export type Text = (key: string, args: { [string]: any }?) -> string

-- Anade nombre/descripcion por clave (`<prefijo>.name`, `<prefijo>.desc`) y los argumentos que usa la plantilla.
local function withText(
	text: Text?,
	prefix: string,
	args: { [string]: any },
	item: { [string]: any }
): { [string]: any }
	local nameKey = prefix .. ".name"
	local descriptionKey = prefix .. ".desc"
	item.nameKey = nameKey
	item.descriptionKey = descriptionKey
	item.textArgs = args
	item.name = if text ~= nil then text(nameKey, args) else nameKey
	item.description = if text ~= nil then text(descriptionKey, args) else descriptionKey
	return item
end

function Catalog.build(
	ids: {
		passes: { [string]: number },
		products: { [string]: number },
		passAssetIds: { [string]: number }?,
	},
	balance: any,
	flags: { paidLuckEnabled: boolean }?,
	text: Text?
): any
	local products = balance.products
	local paidLuckEnabled = flags ~= nil and flags.paidLuckEnabled == true -- por defecto APAGADO (v1)
	local catalog = {
		priceLadder = Catalog.ladder,
		passes = {
			auto_fish = withText(text, "pass.auto_fish", { hours = balance.offline.autoFishCapSeconds / 3600 }, {
				key = "auto_fish",
				id = ids.passes.auto_fish,
				tier = "standard",
			}),
			double_coins = withText(text, "pass.double_coins", {}, {
				key = "double_coins",
				id = ids.passes.double_coins,
				tier = "plus",
			}),
			luck_plus = withText(text, "pass.luck_plus", { points = products.passes.luckPlus }, {
				key = "luck_plus",
				id = ids.passes.luck_plus,
				tier = "strong",
				affectsOdds = true,
				enabled = paidLuckEnabled,
			}),
			starter = withText(text, "pass.starter", {
				coins = products.starterPack.coins,
				pearls = products.starterPack.pearls,
				slots = products.starterPack.slots,
			}, {
				key = "starter",
				id = ids.passes.starter,
				tier = "basic",
				oneTimeGrant = {
					kind = "currency",
					coins = products.starterPack.coins,
					pearls = products.starterPack.pearls,
					slots = products.starterPack.slots,
				},
			}),
			vip = withText(text, "pass.vip", {
				percent = math.floor((balance.vip.coinBonus - 1) * 100 + 0.5),
				pearls = balance.vip.dailyPearls,
			}, {
				key = "vip",
				id = ids.passes.vip,
				tier = "value",
			}),
			season_pass = withText(text, "pass.season_pass", {}, {
				key = "season_pass",
				id = ids.passes.season_pass,
				tier = "strong",
			}),
			-- Cosmeticos (tarea 002): solo aspecto, sin efecto de juego.
			golden_rod = withText(text, "pass.golden_rod", {}, {
				key = "golden_rod",
				id = ids.passes.golden_rod,
				tier = "strong",
				cosmetic = true,
			}),
			bubble_trail = withText(text, "pass.bubble_trail", {}, {
				key = "bubble_trail",
				id = ids.passes.bubble_trail,
				tier = "deluxe",
				cosmetic = true,
			}),
		},
		products = {
			lucky_bait_15 = withText(
				text,
				"product.lucky_bait_15",
				{ luck = products.luckyBait.luck, minutes = products.luckyBait.seconds / 60 },
				{
					key = "lucky_bait_15",
					id = ids.products.lucky_bait_15,
					kind = "boost",
					grant = { boostId = "lucky_bait", seconds = products.luckyBait.seconds },
					tier = "impulse",
					affectsOdds = true,
					enabled = paidLuckEnabled,
				}
			),
			coin_boost_15 = withText(text, "product.coin_boost_15", { minutes = products.coinBoost.seconds / 60 }, {
				key = "coin_boost_15",
				id = ids.products.coin_boost_15,
				kind = "boost",
				grant = { boostId = "coin_boost", seconds = products.coinBoost.seconds },
				tier = "impulse",
			}),
			coin_pack_small = withText(text, "product.coin_pack_small", { coins = products.coinPackSmall.coins }, {
				key = "coin_pack_small",
				id = ids.products.coin_pack_small,
				kind = "currency",
				grant = { coins = products.coinPackSmall.coins },
				tier = "basic",
			}),
			coin_pack_medium = withText(text, "product.coin_pack_medium", { coins = products.coinPackMedium.coins }, {
				key = "coin_pack_medium",
				id = ids.products.coin_pack_medium,
				kind = "currency",
				grant = { coins = products.coinPackMedium.coins },
				tier = "major",
			}),
			coin_pack_large = withText(text, "product.coin_pack_large", { coins = products.coinPackLarge.coins }, {
				key = "coin_pack_large",
				id = ids.products.coin_pack_large,
				kind = "currency",
				grant = { coins = products.coinPackLarge.coins },
				tier = "anchor",
			}),
			pearl_pack = withText(text, "product.pearl_pack", { pearls = products.pearlPack.pearls }, {
				key = "pearl_pack",
				id = ids.products.pearl_pack,
				kind = "currency",
				grant = { pearls = products.pearlPack.pearls },
				tier = "value",
			}),
			slot_pack = withText(text, "product.slot_pack", { slots = products.slotPack.slots }, {
				key = "slot_pack",
				id = ids.products.slot_pack,
				kind = "slots",
				grant = { slots = products.slotPack.slots },
				tier = "basic",
			}),
		},
	}

	-- REVIEW(money): alias opcional por pase (ProductIds.passAssetIds): el assetId del pase cuando difiere de su TargetId.
	-- Solo sirve para reconocer PromptGamePassPurchaseFinished y como respaldo de precios; nunca para vender ni conceder.
	if ids.passAssetIds ~= nil then
		for key, assetId in ids.passAssetIds do
			local pass = catalog.passes[key]
			if pass ~= nil then
				pass.assetId = assetId
			else
				-- Clave desconocida (error al pegar IDs): queda visible para Shop.validateCatalog en lugar de ignorarse.
				local alias = "unknown_asset_alias_" .. key
				catalog.passes[alias] =
					{ key = alias, id = 0, assetId = assetId, name = "", description = "", enabled = false }
			end
		end
	end
	return catalog
end

return Catalog
