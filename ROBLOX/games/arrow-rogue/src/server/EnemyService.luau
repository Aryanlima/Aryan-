--!strict
local EnemyService = {}

function EnemyService.new(deps)
	local Balance = deps.Balance
	local enemies = {}
	local nextId = 0
	local service = {}
	function service.list()
		return enemies
	end
	function service.spawn(id, pos)
		if #enemies >= Balance.enemyLimit then
			return nil
		end
		nextId += 1
		local part = deps.createPart("Chaser", pos)
		local enemy =
			{ id = id or nextId, pos = pos, hp = Balance.enemies.chaser.hp, part = part, state = "Idle", untilTime = 0 }
		table.insert(enemies, enemy)
		return enemy
	end
	function service.clear()
		for _, enemy in enemies do
			enemy.part:Destroy()
		end
		table.clear(enemies)
	end
	function service.remove(enemy)
		for i = #enemies, 1, -1 do
			if enemies[i] == enemy then
				enemy.part:Destroy()
				table.remove(enemies, i)
				return
			end
		end
	end
	function service.step(dt, now, players)
		for _, enemy in enemies do
			local target, best = nil, math.huge
			for _, player in players do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root then
					local d = (root.Position - enemy.part.Position).Magnitude
					if d < best then
						target, best = root, d
					end
				end
			end
			if enemy.state == "Idle" then
				enemy.state = "Chase"
			end
			if enemy.state == "Chase" and target then
				if best <= Balance.chaser.attackRange then
					enemy.state, enemy.untilTime = "Windup", now + Balance.chaser.windup
				else
					local delta = target.Position - enemy.part.Position
					local move = Vector3.new(delta.X, 0, delta.Z)
					if move.Magnitude > 0 then
						enemy.part.Position += move.Unit * Balance.enemies.chaser.speed * dt
					end
				end
			elseif enemy.state == "Windup" and now >= enemy.untilTime then
				enemy.state, enemy.untilTime = "Attack", now + 0.1
			elseif enemy.state == "Attack" and now >= enemy.untilTime then
				enemy.state, enemy.untilTime = "Recover", now + Balance.chaser.recover
			elseif enemy.state == "Recover" and now >= enemy.untilTime then
				enemy.state = "Chase"
			end
		end
	end
	return service
end

return EnemyService
