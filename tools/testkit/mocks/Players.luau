--!nonstrict
--[[
	Players (mock): PlayerAdded / PlayerRemoving y jugadores "stub".

	  local players = Players.new({ clock = clock, enum = Enum })
	  players.PlayerAdded:Connect(function(player) ... end)
	  local p = players:AddPlayer(1001, "Alice")   -- dispara PlayerAdded
	  players:RemovePlayer(p)                      -- dispara PlayerRemoving, Parent = nil
	  players:GetPlayers() / :GetPlayerByUserId(id) / :GetPlayerFromName(name)

	Igual que en Roblox, conectar PlayerAdded DESPUES de AddPlayer no dispara el evento
	para jugadores existentes: la logica real suele recorrer `GetPlayers()` al arrancar.

	El stub de Player cubre lo comun: Name, DisplayName, UserId, AccountAge, Parent,
	Character, :Kick(reason), :IsA, :GetAttribute/:SetAttribute, hijos (:FindFirstChild,
	:AddChild) y `kicked` (razon del Kick, para asertar).
]]

local Signal = require("./Signal")

local Players = {}
Players.__index = Players

local Player = {}
Player.__index = Player

function Player:IsA(className: string): boolean
	return className == "Player" or className == "Instance"
end

function Player:GetAttribute(name: string)
	return self._attributes[name]
end

function Player:SetAttribute(name: string, value: any)
	self._attributes[name] = value
end

function Player:FindFirstChild(name: string)
	return self._children[name]
end

function Player:AddChild(name: string, child: any)
	self._children[name] = child
	return child
end

function Player:IsDescendantOf(ancestor: any): boolean
	return self.Parent == ancestor and ancestor ~= nil
end

function Player:Kick(reason: string?)
	self.kicked = reason or ""
	if self.Parent then
		self._players:RemovePlayer(self)
	end
end

--[[
	options:
	  clock   mocks/Clock: los handlers de eventos se lanzan con clock.task.spawn
	  enum    tabla Enum del mock (para MembershipType por defecto)
	  maxPlayers
]]
function Players.new(options)
	local opts = options or {}
	local self = setmetatable({}, Players)
	local spawn = opts.clock and opts.clock.task.spawn or nil
	self._list = {}
	self._enum = opts.enum
	self._spawn = spawn
	self.PlayerAdded = Signal.new({ spawn = spawn })
	self.PlayerRemoving = Signal.new({ spawn = spawn })
	self.MaxPlayers = opts.maxPlayers or 50
	self.LocalPlayer = nil -- nil en el servidor
	return self
end

--[[
	props opcionales: DisplayName, AccountAge, MembershipType, attributes = {...}
	`fire = false` crea el jugador sin disparar PlayerAdded.
]]
function Players:AddPlayer(userId: number, name: string?, props: { [string]: any }?)
	assert(type(userId) == "number", "Players:AddPlayer(userId, name?, props?) requiere userId numerico")
	assert(not self:GetPlayerByUserId(userId), "Players:AddPlayer: userId duplicado " .. tostring(userId))
	local p = props or {}
	local playerName = name or ("Player" .. tostring(userId))
	local player = setmetatable({
		Name = playerName,
		DisplayName = p.DisplayName or playerName,
		UserId = userId,
		AccountAge = p.AccountAge or 100,
		MembershipType = p.MembershipType or (self._enum and self._enum.MembershipType.None) or 0,
		Parent = self,
		Character = nil,
		ClassName = "Player",
		kicked = nil,
		_players = self,
		_attributes = table.clone(p.attributes or {}),
		_children = {},
	}, Player)
	table.insert(self._list, player)
	if p.fire ~= false then
		self.PlayerAdded:Fire(player)
	end
	return player
end

function Players:RemovePlayer(player)
	for i, candidate in self._list do
		if candidate == player then
			self.PlayerRemoving:Fire(player)
			-- el evento corre antes de quitarlo (como en Roblox); si el handler ya lo quito, no repetir
			for j, other in self._list do
				if other == player then
					table.remove(self._list, j)
					break
				end
			end
			player.Parent = nil
			return true
		end
	end
	return false
end

function Players:GetPlayers()
	return table.clone(self._list)
end

function Players:GetPlayerByUserId(userId: number)
	for _, player in self._list do
		if player.UserId == userId then
			return player
		end
	end
	return nil
end

function Players:GetPlayerFromName(name: string)
	for _, player in self._list do
		if player.Name == name then
			return player
		end
	end
	return nil
end

function Players:GetNumPlayers(): number
	return #self._list
end

return Players
