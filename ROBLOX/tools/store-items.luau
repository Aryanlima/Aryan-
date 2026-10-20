--!nonstrict
--[[
	store-items: lista de lo que hay que CREAR en Creator Hub para Fish & Fortune (pases y productos HABILITADOS), con el
	nombre y la descripcion en EN y ES, el precio sugerido (Robux) y el icono. Sale del codigo (Catalog + Strings + Balance),
	no de una tabla a mano. Lo usan: dump-store-items.luau (genera games/fish-and-fortune/store-items.json) y
	games/fish-and-fortune/tests/PassIds.spec.luau (falla si el JSON versionado se queda desactualizado).
]]
local fs = require("@lune/fs")
local Balance = require("../games/fish-and-fortune/src/shared/Balance")
local Catalog = require("../games/fish-and-fortune/src/server/Catalog")
local FeatureFlags = require("../games/fish-and-fortune/src/shared/FeatureFlags")
local Locale = require("../packages/Locale")
local ProductIds = require("../games/fish-and-fortune/src/server/ProductIds")
local Shop = require("../packages/Shop")
local Strings = require("../games/fish-and-fortune/src/shared/Strings")

local HERE = (debug.info(1, "s") :: string):gsub("[^/\\]+$", "")
local ART_DIR = "marketing/fish-and-fortune/assets/"

local StoreItems = {}

local function sortedKeys(map)
	local keys = {}
	for key in map do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end

function StoreItems.build()
	local locale = Locale.new(Strings)
	local byLanguage = {}
	for _, language in { "en", "es" } do
		byLanguage[language] = Catalog.build(ProductIds, Balance, FeatureFlags, locale:translator(language))
	end
	local catalog = byLanguage.en
	local items = {}
	for _, group in
		{
			{ kind = "pass", folder = "passes", map = "passes" },
			{ kind = "product", folder = "products", map = "products" },
		}
	do
		for _, key in sortedKeys(catalog[group.map]) do
			local item = catalog[group.map][key]
			if item.enabled ~= false then
				local icon = ART_DIR .. group.folder .. "/" .. key .. ".png"
				table.insert(items, {
					kind = group.kind,
					key = key,
					price = Shop.resolvePrice(catalog, item),
					tier = item.tier,
					icon = if fs.isFile(HERE .. "../" .. icon) then icon else nil,
					name = { en = item.name, es = byLanguage.es[group.map][key].name },
					description = { en = item.description, es = byLanguage.es[group.map][key].description },
				})
			end
		end
	end
	return { _comentario = "Generado por ROBLOX/tools/dump-store-items.luau. NO editar a mano.", items = items }
end

return StoreItems
