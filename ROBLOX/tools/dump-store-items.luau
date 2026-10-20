--!nonstrict
--[[
	Regenera ROBLOX/games/fish-and-fortune/store-items.json (lo que hay que crear en Creator Hub, con nombres EN/ES,
	precios sugeridos e iconos). Uso, desde cualquier carpeta del repo:
	    lune run ROBLOX/tools/dump-store-items.luau
	(o `cd ROBLOX && lune run tools/dump-store-items.luau`). games/fish-and-fortune/tests/PassIds.spec.luau comprueba que
	el archivo versionado coincide con el codigo.
]]
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local StoreItems = require("./store-items")

local HERE = (debug.info(1, "s") :: string):gsub("[^/\\]+$", "")
local OUTPUT = HERE .. "../games/fish-and-fortune/store-items.json"

fs.writeFile(OUTPUT, serde.encode("json", StoreItems.build(), true) .. "\n")
print("Escrito " .. OUTPUT)
