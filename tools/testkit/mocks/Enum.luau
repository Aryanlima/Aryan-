--!nonstrict
--[[
	Enum (mock) minimo: solo los enums que la logica de monetizacion/jugadores suele usar.
	Cada item es una tabla unica { Name, Value, EnumType } comparable con ==.
	Anade los que necesites con `Enum.define("NombreEnum", { Item = valor, ... })`.
]]

local EnumMock = {}

local function define(enumName: string, items: { [string]: number })
	local enum = { _name = enumName }
	local list = {}
	for itemName, value in items do
		local item = table.freeze({ Name = itemName, Value = value, EnumType = enum })
		enum[itemName] = item
		table.insert(list, item)
	end
	table.sort(list, function(a, b)
		return a.Value < b.Value
	end)
	function enum:GetEnumItems()
		return table.clone(list)
	end
	function enum:FromValue(value: number)
		for _, item in list do
			if item.Value == value then
				return item
			end
		end
		return nil
	end
	function enum:FromName(name: string)
		return rawget(enum, name)
	end
	EnumMock[enumName] = enum
	return enum
end

EnumMock.define = define

define("ProductPurchaseDecision", { PurchaseGranted = 0, NotProcessedYet = 1 })
define("InfoType", { Asset = 0, Product = 1, GamePass = 2, Subscription = 3, Bundle = 4 })
define("CurrencyType", { Default = 0, Robux = 1, Tix = 2 })
define("MembershipType", { None = 0, BuildersClub = 1, TurboBuildersClub = 2, OutrageousBuildersClub = 3, Premium = 4 })

return EnumMock
