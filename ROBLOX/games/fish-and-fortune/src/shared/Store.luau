--!strict
--[[
	Store: contenedor minimo de estado del cliente (sin motor). Guarda el ultimo estado recibido del servidor,
	cuando llego (reloj local) y avisa a los suscriptores. Esta en `shared` para poder probarlo con Lune.
]]

local Store = {}
Store.__index = Store

type StoreData = {
	state: any,
	receivedAtClock: number,
	listeners: { [number]: (state: any) -> ...any },
	nextId: number,
	clock: () -> number,
}
export type Store = typeof(setmetatable({} :: StoreData, Store))

function Store.new(clock: (() -> number)?): Store
	local data: StoreData = {
		state = nil,
		receivedAtClock = 0,
		listeners = {},
		nextId = 1,
		clock = clock or os.clock,
	}
	return setmetatable(data, Store)
end

function Store.get(self: Store): any
	return self.state
end

function Store.receivedAt(self: Store): number
	return self.receivedAtClock
end

-- Reemplaza el estado (el servidor es la fuente de verdad) y avisa a los suscriptores.
function Store.set(self: Store, state: any)
	self.state = state
	self.receivedAtClock = self.clock()
	local snapshot: { (state: any) -> ...any } = {}
	for _, listener in self.listeners do
		table.insert(snapshot, listener)
	end
	for _, listener in snapshot do
		local ok, err = pcall(listener, state)
		if not ok then
			warn("[Store] suscriptor fallo: " .. tostring(err))
		end
	end
end

-- Devuelve una funcion para cancelar la suscripcion.
function Store.subscribe(self: Store, listener: (state: any) -> ...any): () -> ()
	local id = self.nextId
	self.nextId += 1
	self.listeners[id] = listener
	return function()
		self.listeners[id] = nil
	end
end

return Store
