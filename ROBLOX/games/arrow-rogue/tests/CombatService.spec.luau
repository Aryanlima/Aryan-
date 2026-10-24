--!nonstrict
local testkit = require("@testkit")
local Combat = require("../src/shared/Combat")
local Balance = require("../src/shared/Balance")
local Service = require("../src/server/CombatService")
local describe, it, expect = testkit.describe, testkit.it, testkit.expect

local function vector(x, y, z)
	local v = { X = x, Y = y, Z = z }
	setmetatable(v, {
		__index = function(_, key)
			local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
			if key == "Magnitude" then
				return m
			end
			if key == "Unit" then
				return vector(v.X / m, v.Y / m, v.Z / m)
			end
			return nil
		end,
		__add = function(a, b)
			return vector(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
		end,
		__sub = function(a, b)
			return vector(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
		end,
		__mul = function(a, b)
			if type(a) == "number" then
				return vector(a * b.X, a * b.Y, a * b.Z)
			end
			return vector(a.X * b, a.Y * b, a.Z * b)
		end,
	})
	return v
end
-- selene: allow(global_usage)
_G.Vector3 = { new = vector }

describe("CombatService", function()
	it("solo dispara quieto al objetivo legal y no acepta daño ni cadencia del cliente", function()
		local velocity, shots = vector(0, 0, 0), {}
		local root = { Position = vector(0, 0, 0) }
		setmetatable(root, {
			__index = function(_, key)
				if key == "AssemblyLinearVelocity" then
					return velocity
				end
				return nil
			end,
		})
		local player = { Character = {
			FindFirstChild = function()
				return root
			end,
		} }
		local enemy = { id = 1, pos = { x = 10, z = 0 }, hp = Balance.enemies.chaser.hp }
		local service = Service.new({
			Combat = Combat,
			Balance = Balance,
			vector3 = { new = vector },
			players = function()
				return { player }
			end,
			enemies = function()
				return { enemy }
			end,
			enemyPosition = function()
				return vector(10, 0, 0)
			end,
			wallBetween = function()
				return false
			end,
			shot = {
				FireClient = function(_, _, origin, direction, speed, kind, t0)
					table.insert(shots, { origin, direction, speed, kind, t0 })
				end,
			},
			serverTime = function()
				return 99
			end,
			killEnemy = function() end,
		})
		service.step(0.01, 0)
		service.step(0.06, 0.06)
		service.step(0.07, 0.13)
		expect(#shots).toBe(1)
		velocity = vector(8, 0, 0)
		service.step(0.6, 0.73)
		expect(#shots).toBe(1)
		service.step(0.6, 1.33)
		expect(#shots).toBe(1)
		expect(shots[1][3]).toBe(Balance.bow.projectileSpeed)
		expect(shots[1][5]).toBe(99)
	end)
end)

describe("CombatService hits", function()
	local function rig(hp)
		local root = { Position = vector(0, 3, 0), AssemblyLinearVelocity = vector(0, 0, 0) }
		local player = { Character = {
			FindFirstChild = function()
				return root
			end,
		} }
		local part = { Position = vector(10, 2, 0) }
		local enemy = { id = 1, hp = hp, part = part }
		local hits, kills = {}, 0
		local service = Service.new({
			Combat = Combat,
			Balance = Balance,
			vector3 = { new = vector },
			players = function()
				return { player }
			end,
			enemies = function()
				return enemy.hp > 0 and { enemy } or {}
			end,
			enemyPosition = function(e)
				return e.part.Position
			end,
			wallBetween = function()
				return false
			end,
			shot = { FireClient = function() end },
			serverTime = function()
				return 0
			end,
			damaged = function(_, amount)
				table.insert(hits, amount)
			end,
			killEnemy = function()
				kills += 1
			end,
		})
		return service, enemy, hits, function()
			return kills
		end
	end

	it("una flecha a un enemigo quieto en rango lo daña y avisa; lo mata en 4-6 s", function()
		local service, enemy, hits, kills = rig(Balance.enemies.chaser.hp)
		local t, killedAt = 0, nil
		while t < 8 and not killedAt do
			service.step(1 / 60, t)
			t += 1 / 60
			if kills() > 0 then
				killedAt = t
			end
		end
		expect(hits[1]).toBe(Balance.bow.damage)
		expect(enemy.hp).toBe(0)
		expect(killedAt ~= nil and killedAt >= 3.5 and killedAt <= 6).toBe(true)
	end)
end)

describe("EnemyService contact", function()
	it("ataca solo tras el windup y respeta la recuperacion entre ataques", function()
		local E = require("../src/server/EnemyService")
		local service = E.new({
			Balance = Balance,
			createPart = function(_, pos)
				return { Position = pos, Destroy = function() end }
			end,
		})
		local enemy = service.spawn(1, vector(1, 0, 0))
		local root = { Position = vector(0, 0, 0) }
		local players = { { Character = {
			FindFirstChild = function()
				return root
			end,
		} } }
		local attackTimes = {}
		local was = false
		local t = 0
		while t < 8 do
			service.step(0.05, t, players)
			local now = enemy.state == "Attack"
			if now and not was then
				table.insert(attackTimes, t)
			end
			was = now
			t += 0.05
		end
		expect(#attackTimes).toBe(3)
		expect(attackTimes[1] >= Balance.chaser.windup).toBe(true)
		expect(attackTimes[2] - attackTimes[1] >= Balance.chaser.recover + Balance.chaser.windup).toBe(true)
	end)
end)
