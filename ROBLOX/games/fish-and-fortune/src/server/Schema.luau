--!strict
--[[
	Esquema de datos del perfil (packages/Data): version, plantilla y migraciones.

	REGLAS para cambiar el esquema (ver ROBLOX/docs/arquitectura.md, "Migraciones"):
	  * Nunca edites una migracion ya publicada: anade la siguiente (migrations[N] pasa de vN a vN+1).
	  * Sube `version` en el mismo cambio. Un servidor con version menor RECHAZA datos de una version mayor.
	  * Mantén el nombre del DataStore: un nombre nuevo es un almacen vacio (todos empiezan de cero).
]]

local Schema = {}

Schema.version = 1

-- `gameTemplate` = GameLogic.template(); `shopTemplate` = Shop.DATA_TEMPLATE.
function Schema.build(gameTemplate: { [string]: any }, shopTemplate: { [string]: any }): any
	local template: { [string]: any } = table.clone(gameTemplate)
	for key, value in shopTemplate do
		template[key] = value
	end
	return {
		version = Schema.version,
		template = template,
		migrations = {
			-- [1] = function(data) ... end, -- ejemplo: v1 -> v2
		},
	}
end

return Schema
