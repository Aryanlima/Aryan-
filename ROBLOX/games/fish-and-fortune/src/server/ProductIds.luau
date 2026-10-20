--!strict
--[[
	UNICO archivo con los IDs de Roblox de Fish & Fortune (pases y productos de desarrollador).

	Como rellenarlo (ver README.md, seccion "Crear pases y productos"):
	  1. En Creator Hub crea cada pase / producto con el nombre indicado en server/Catalog.luau.
	  2. Copia su ID numerico y sustituye el `0 -- TODO_ID` correspondiente.
	  3. Un ID en 0 significa "todavia sin crear": ese objeto NO se ofrece en la tienda (Shop.canOffer
	     devuelve "unavailable") y `Shop.validateCatalog(..., { allowPlaceholders = false })` falla, para que
	     el chequeo previo a publicar (tests/Catalog.spec.luau, tools de CI) avise de lo que falta.

	Los IDs de PASES son los "TargetId" de la pagina del pase (no el assetId); los de PRODUCTOS son los
	ProductId de Creator Hub > Monetizacion > Productos de desarrollador.

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
} :: { passes: { [string]: number }, products: { [string]: number } }
