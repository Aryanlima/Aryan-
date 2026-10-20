--!nonstrict
--[[
	Spy / funcion simulada (estilo jest.fn):

	  local fn = Spy.new(function(a, b) return a + b end)   -- implementacion opcional
	  fn(1, 2)
	  fn.callCount        --> 1
	  fn.calls[1]         --> { 1, 2, n = 2 }
	  fn.results[1]       --> 3
	  fn:mockReturn(5)    -- siguientes llamadas devuelven 5
	  fn:reset()
	expect(fn).toHaveBeenCalledWith(1, 2)
]]

local Spy = {}

local spies = setmetatable({}, { __mode = "k" })

function Spy.isSpy(value): boolean
	return type(value) == "table" and spies[value] == true
end

function Spy.new(implementation: ((...any) -> ...any)?)
	local spy = {
		callCount = 0,
		calls = {},
		results = {},
		_impl = implementation,
	}

	function spy.mockReturn(self, ...)
		local values = table.pack(...)
		self._impl = function()
			return table.unpack(values, 1, values.n)
		end
		return self
	end

	function spy.mockImplementation(self, impl)
		self._impl = impl
		return self
	end

	function spy.reset(self)
		self.callCount = 0
		self.calls = {}
		self.results = {}
	end

	spies[spy] = true
	return setmetatable(spy, {
		__call = function(self, ...)
			self.callCount += 1
			table.insert(self.calls, table.pack(...))
			if self._impl then
				local packed = table.pack(self._impl(...))
				table.insert(self.results, packed[1])
				return table.unpack(packed, 1, packed.n)
			end
			table.insert(self.results, false) -- placeholder: sin implementacion
			return nil
		end,
	})
end

return Spy
