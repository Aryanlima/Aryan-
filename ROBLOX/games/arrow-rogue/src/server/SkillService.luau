--!strict
local SkillService = {}
type Owned = { [string]: number }
type Offer = { ids: { string }, level: number }

-- deps (inyectadas): Skills, offer (RemoteEvent salida SkillOffer), now(), seed(player, level) -> number,
-- minInterval (s entre SkillPick por jugador). Conectar SkillPick.OnServerEvent a service.pick.
function SkillService.new(deps: any)
	local Skills = deps.Skills
	local offers: { [any]: Offer } = {}
	local owned: { [any]: Owned } = {}
	local levels: { [any]: number } = {}
	local lastPick: { [any]: number } = {}
	local service = {}
	function service.owned(player: any): Owned
		local o = owned[player] or {}
		owned[player] = o
		return o
	end
	function service.levelUp(player: any)
		local level = (levels[player] or 0) + 1
		levels[player] = level
		local ids = Skills.roll(deps.seed(player, level), service.owned(player), 3)
		if #ids > 0 then
			offers[player] = { ids = ids, level = level }
			deps.offer:FireClient(player, ids)
		end
	end
	function service.pick(player: any, index: any): boolean
		local now = deps.now()
		if now - (lastPick[player] or -math.huge) < deps.minInterval then
			return false
		end
		lastPick[player] = now
		local offer = offers[player]
		if offer == nil or type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > #offer.ids then
			return false
		end
		offers[player] = nil
		local id = offer.ids[index]
		local o = service.owned(player)
		o[id] = (o[id] or 0) + 1
		return true
	end
	return service
end

return SkillService
