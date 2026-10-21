--!strict
-- IDs de audio reales de la Creator Store. "" = pendiente (hay que buscarlos con search_asset con Studio abierto;
-- no se inventan IDs). Audio.luau ignora las claves vacías. Formato: "rbxassetid://<número>".
return {
	music = "", -- música tranquila y alegre (bucle)
	ambience_nature = "", -- lago, pájaros, agua (bucle)
	ambience_crowd = "", -- gente jugando y riendo a lo lejos (bucle)
	cast = "", -- lanzar la caña
	splash = "", -- corcho al agua
	bite = "", -- picada
	catch = "", -- captura
	escape = "", -- pez escapado
	sell = "", -- vender (monedas)
	buy = "", -- comprar
	button = "", -- botón de interfaz
	rare = "", -- fanfarria raro / mítico
} :: { [string]: string }
