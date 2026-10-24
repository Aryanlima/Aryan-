--!strict
local CombatService = {}
type Arrow = { owner: Player, pos: Vector3, direction: Vector3, damage: number, remaining: number }
type Enemy = { id: number, hp: number, part: BasePart }
type Sample = { t: number, speed: number }
type Target = { id: number, pos: { x: number, z: number }, ref: Enemy }
type Balance = {
	bow: { damage: number, cooldown: number, projectileSpeed: number, range: number },
	standing: { speedThreshold: number, standSeconds: number },
	projectiles: { maxPerPlayer: number, radius: number },
	chaser: { radius: number },
}
local function segmentDistance2(p: Vector3, a: Vector3, b: Vector3): number
	local dx, dz = b.X - a.X, b.Z - a.Z
	local length = dx * dx + dz * dz
	local t = if length == 0 then 0 else math.clamp(((p.X - a.X) * dx + (p.Z - a.Z) * dz) / length, 0, 1)
	local x, z = a.X + dx * t, a.Z + dz * t
	return (p.X - x) ^ 2 + (p.Z - z) ^ 2
end

-- deps: any en la frontera de inyeccion (los tests pasan dobles de Vector3).
function CombatService.new(deps: any)
	local Combat: any, Balance: Balance, Vector3: any = deps.Combat, deps.Balance, deps.vector3
	local arrows: { Arrow }, samples: { [Player]: { Sample } }, lastShot: { [Player]: number } = {}, {}, {}
	local service = {}
	function service.step(dt: number, now: number)
		local players: { Player }, enemies: { Enemy } = deps.players(), deps.enemies()
		local targets: { Target } = {}
		for _, enemy in enemies do
			if enemy.hp > 0 then
				local position = deps.enemyPosition(enemy)
				table.insert(targets, { id = enemy.id, pos = { x = position.X, z = position.Z }, ref = enemy })
			end
		end
		for _, player in players do
			local root = (player.Character and player.Character:FindFirstChild("HumanoidRootPart")) :: BasePart?
			if root then
				local velocity: Vector3 = root.AssemblyLinearVelocity
				local history: { Sample } = samples[player] or {}
				samples[player] = history
				table.insert(history, { t = now, speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude })
				while #history > 0 and now - history[1].t > Balance.standing.standSeconds + 0.1 do
					table.remove(history, 1)
				end
				if
					Combat.isStanding(history, Balance.standing.speedThreshold, Balance.standing.standSeconds)
					and Combat.canFire(lastShot[player] or -math.huge, now, Balance.bow.cooldown)
				then
					local p: Vector3 = root.Position
					local target = Combat.pickTarget(
						{ x = p.X, z = p.Z },
						targets,
						function(_: any, to: { x: number, z: number })
							return deps.wallBetween(p, Vector3.new(to.x, p.Y, to.z), player.Character)
						end
					)
					if target then
						lastShot[player] = now
						local direction: Vector3 = (Vector3.new(target.pos.x, p.Y, target.pos.z) - p).Unit
						local live = 0
						for _, arrow in arrows do
							if arrow.owner == player then
								live += 1
							end
						end
						if live < Balance.projectiles.maxPerPlayer then
							table.insert(arrows, {
								owner = player,
								pos = p,
								direction = direction,
								damage = Balance.bow.damage,
								remaining = Balance.bow.range,
							})
							deps.shot:FireClient(
								player,
								p,
								direction,
								Balance.bow.projectileSpeed,
								"arrow",
								deps.serverTime()
							)
						end
					end
				end
			end
		end
		for i = #arrows, 1, -1 do
			local arrow: Arrow = arrows[i]
			local distance = math.min(arrow.remaining, Balance.bow.projectileSpeed * dt)
			local finish = arrow.pos + arrow.direction * distance
			if deps.wallBetween(arrow.pos, finish, arrow.owner.Character) then
				table.remove(arrows, i)
			else
				local hit = false
				for _, enemy in enemies do
					local pos = deps.enemyPosition(enemy)
					if
						enemy.hp > 0
						and segmentDistance2(pos, arrow.pos, finish)
							<= (Balance.projectiles.radius + Balance.chaser.radius) ^ 2
					then
						-- REVIEW(money): damage is server-owned; persist rewards only after idempotent settlement.
						enemy.hp = Combat.applyDamage(enemy.hp, arrow.damage)
						if enemy.hp == 0 then
							deps.killEnemy(enemy)
						end
						hit = true
						break
					end
				end
				arrow.pos, arrow.remaining = finish, arrow.remaining - distance
				if hit or arrow.remaining <= 0 then
					table.remove(arrows, i)
				end
			end
		end
	end
	return service
end

return CombatService
