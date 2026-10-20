--!strict
--[[
	StudioMemoryStore: almacen en memoria con la forma MINIMA de un DataStore (solo UpdateAsync), para poder
	jugar en Studio cuando "Enable Studio Access to API Services" esta desactivado.

	  * Los datos NO se guardan al terminar la sesion de Studio. Es solo para pruebas.
	  * GameService lo usa unicamente en Studio y solo si el DataStore real no responde, avisandolo con warn.
	  * Imita la semantica de UpdateAsync: el callback recibe una copia, devolver nil cancela, y se devuelve
	    el valor nuevo.
]]

local StudioMemoryStore = {}

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value do
		copy[k] = deepCopy(v)
	end
	return copy
end

function StudioMemoryStore.new(): any
	local records: { [string]: any } = {}
	local store = {}

	function store.UpdateAsync(_self: any, key: string, transform: (any, any?) -> (any, any?, any?)): (any, any?)
		local old = deepCopy(records[key])
		local new = transform(old, nil)
		if new == nil then
			return old, nil
		end
		records[key] = deepCopy(new)
		return deepCopy(new), nil
	end

	function store.GetAsync(_self: any, key: string): (any, any?)
		return deepCopy(records[key]), nil
	end

	return store
end

return StudioMemoryStore
