--!strict
--[[
	UNICO archivo con los IDs de Roblox de Fish & Fortune (pases y productos de desarrollador).

	Como rellenarlo (guia completa en ROBLOX/docs/publicar-paso-a-paso.md):
	  1. En Creator Hub crea cada pase / producto con el nombre indicado en store-items.json (o server/Catalog.luau).
	  2. Copia su ID numerico a ROBLOX/games/fish-and-fortune/ids.local.json (ver ids.example.json).
	  3. NO edites este archivo a mano: ejecuta `node ROBLOX/tools/wire-ids.mjs` (valida, reescribe este archivo y
	     corre la puerta previa a publicar). `--dry-run` muestra los cambios sin escribir nada.
	  4. Un ID en 0 significa "todavia sin crear": ese objeto NO se ofrece en la tienda (Shop.canOffer
	     devuelve "unavailable") y `Shop.validateCatalog(..., { allowPlaceholders = false })` falla, para que
	     el chequeo previo a publicar (tests/ReleaseGate.spec.luau con FF_RELEASE_CHECK=1) avise de lo que falta.
	     Suerte+ y Cebo de Suerte estan APAGADOS a proposito en la v1 (FeatureFlags.paidLuckEnabled): se quedan en 0.

	`passes`: el ID de cada PASE que el juego pasa a PromptGamePassPurchase y a UserOwnsGamePassAsync y con el que
	reconoce PromptGamePassPurchaseFinished (el "TargetId" del pase). Los de PRODUCTOS son los ProductId de Creator Hub >
	Monetizacion > Productos de desarrollador.

	`passAssetIds` (normalmente VACIO): REVIEW(money) la documentacion de Roblox se contradice sobre si el ID de un pase
	es su TargetId o su assetId. Si la prueba de Studio (guia, "TargetId o assetId") muestra que para un pase los dos
	numeros son DISTINTOS, aqui va su assetId: el juego lo reconoce como alias en PromptGamePassPurchaseFinished y como
	respaldo para consultar precios. Nunca se usa para vender ni para conceder nada.

	No son secretos (se ven en la pagina publica del juego), pero este archivo vive en el servidor: el
	cliente pide por CLAVE ("luck_plus") y nunca por ID.
]]

return {
	passes = {
		auto_fish = 0, -- TODO_ID  (Pase Auto-Pesca)
		double_coins = 0, -- TODO_ID  (Pase 2x Dinero)
		luck_plus = 0, -- TODO_ID  (Pase Suerte+ : ALTERA PROBABILIDADES)
		starter = 0, -- TODO_ID  (Pack de inicio, pago unico)
		vip = 0, -- TODO_ID  (Pase VIP)
		season_pass = 0, -- TODO_ID  (Pase de Temporada 1: pista premium)
		golden_rod = 0, -- TODO_ID  (Cana Dorada, cosmetico)
		bubble_trail = 0, -- TODO_ID  (Estela de Burbujas, cosmetico)
	},
	products = {
		lucky_bait_15 = 0, -- TODO_ID  (Cebo de Suerte, 15 min : ALTERA PROBABILIDADES)
		coin_boost_15 = 0, -- TODO_ID  (Boost de Monedas x2, 15 min)
		coin_pack_small = 0, -- TODO_ID  (Pack de monedas pequeno)
		coin_pack_medium = 0, -- TODO_ID  (Pack de monedas mediano)
		coin_pack_large = 0, -- TODO_ID  (Pack de monedas grande)
		pearl_pack = 0, -- TODO_ID  (Pack de perlas)
		slot_pack = 0, -- TODO_ID  (+10 espacios de inventario)
	},
	passAssetIds = {},
} :: { passes: { [string]: number }, products: { [string]: number }, passAssetIds: { [string]: number } }
