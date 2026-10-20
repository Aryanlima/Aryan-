--!strict
--[[
	Nombres de los remotos (cliente <-> servidor). Un solo lugar para evitar errores de texto.

	  inbound  = cliente -> servidor. El cliente SOLO SOLICITA; el servidor valida tipos, rangos y estado
	             (packages/Net) y decide. Todos tienen limitador de frecuencia.
	  outbound = servidor -> cliente (informacion para mostrar; el cliente no la puede usar para ganar nada).
]]

return {
	folderName = "Remotes",
	inbound = {
		"Cast",
		"Reel",
		"SellAll",
		"BuyRod",
		"EquipRod",
		"UnlockZone",
		"TravelZone",
		"SetAutoFish",
		"ClaimBestiary",
		"ClaimSeason",
		"ClaimDaily",
		"BuySlotsWithPearls",
		"RedeemCode",
		"RequestOffers",
		"RequestPurchase",
		"RequestState",
	},
	outbound = {
		"State",
		"CastStarted",
		"CastFailed",
		"Catch",
		"Toast",
		"Offers",
		"Banner",
	},
}
