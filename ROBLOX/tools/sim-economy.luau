--!nonstrict
-- Simulacion de economia de Fish & Fortune con los modulos REALES (Balance, FishingRules, GameLogic).
-- SIMULADO, no medido con jugadores reales.  Uso: bash -c 'source ROBLOX/tools/env.sh; cd "$ROOT"; lune run tools/sim-economy'
local Balance = require("../games/fish-and-fortune/src/shared/Balance")
local FishingRules = require("../games/fish-and-fortune/src/shared/FishingRules")
local GameLogic = require("../games/fish-and-fortune/src/server/GameLogic")
local Economy = require("../packages/Economy")
local Odds = require("../packages/Odds")

local SESSION = 3600
local SEEDS = 20
local NOW = 1800000000

local function lcg(seed)
	local state = seed
	return function()
		state = (state * 1664525 + 1013904223) % 4294967296
		return state / 4294967296
	end
end

-- cycle: segundos por intento (nil = intervalo de la cana, auto-pesca); perfect/good: probabilidades del minijuego
local profiles = {
	{ name = "casual", cycle = 8, perfect = 0.25, good = 0.35 },
	{ name = "activo", cycle = 1.35, perfect = 0.60, good = 0.25 },
	{ name = "idle", cycle = nil, auto = true },
}

local function run(profile, seed)
	local rng = lcg(seed)
	local logic = GameLogic.new({
		balance = Balance,
		rules = FishingRules.new(Balance, Odds),
		economy = Economy,
		rng = lcg(seed * 7919 + 13),
		clock = function()
			return 0
		end,
	})
	local data = GameLogic.template()
	local ctx =
		{ player = nil, passes = { auto_fish = profile.auto }, events = {}, paidRandomAllowed = true, now = NOW }
	local r = { rod = {}, zone = {}, full = 0, top = 0, catches = 0, lastBuy = 0, maxGap = 0, gapAt = 0 }

	local function bought(t)
		r.maxGap = math.max(r.maxGap, t - r.lastBuy)
		r.lastBuy = t
	end

	-- politica voraz: reclamar bestiario, comprar cana/zona/ranuras si alcanza (cualquier orden, la mas cara asequible primero)
	local function upgrades(t)
		for _, reward in Balance.bestiary.rewards do
			if logic:claimBestiary(data, reward.id) then
				bought(t)
			end
		end
		for _, id in Balance.rodOrder do
			if not data.ownedRods[id] and logic:buyRod(data, id) then
				r.rod[id] = t
				bought(t)
			end
		end
		for _, id in Balance.zoneOrder do
			if not data.unlockedZones[id] and logic:unlockZone(data, id) then
				r.zone[id] = t
				bought(t)
			end
		end
		for i = #Balance.zoneOrder, 1, -1 do -- viaja a la mejor zona desbloqueada
			if data.unlockedZones[Balance.zoneOrder[i]] then
				logic:travel(data, Balance.zoneOrder[i])
				break
			end
		end
		while logic:buySlotsWithPearls(data) do
			bought(t)
		end
	end

	local t = 0
	while t < SESSION do
		if logic:inventoryCount(data) >= logic:capacity(data) then
			r.full += 1
			logic:sellAll(data, ctx)
			upgrades(t)
		end
		local quality = nil
		local caught = true
		if not profile.auto then
			local roll = rng()
			if roll < profile.perfect then
				quality = "perfect"
			elseif roll < profile.perfect + profile.good then
				quality = "good"
			else
				caught = false
			end
		end
		if caught then
			local res = logic:resolveCatch(data, ctx, quality)
			r.catches += 1
			if res.rarity == "Legendary" or res.rarity == "Mythic" then
				r.top += 1
			end
		end
		t += profile.cycle or Balance.rods[data.rod].autoInterval
		upgrades(t)
	end
	logic:sellAll(data, ctx)
	r.coins = data.stats.coinsEarned
	r.disc = logic:discoveries(data)
	r.pearls = data.wallet.pearls
	r.slots = logic:capacity(data)
	return r
end

local function fmt(sum, n, scale)
	return if n == 0 then "-" else string.format("%.1f", sum / n / scale)
end

print(`SIMULADO (no medido con jugadores) - {SEEDS} semillas, {SESSION // 60} min por perfil, medias`)
local keys = { "reed", "fiberglass", "carbon", "golden", "river", "coast" }
print(
	string.format(
		"%-7s %s | coins/h | especies | %%leg+myt | llenos | hueco max(min) | slots",
		"perfil",
		"min->: reed fibra carbon golden rio costa"
	)
)
for _, p in profiles do
	local sums, counts = {}, {}
	local coins, disc, top, catches, full, gap, slots = 0, 0, 0, 0, 0, 0, 0
	for s = 1, SEEDS do
		local r = run(p, s)
		for _, k in keys do
			local v = r.rod[k] or r.zone[k]
			if v then
				sums[k] = (sums[k] or 0) + v
				counts[k] = (counts[k] or 0) + 1
			end
		end
		coins += r.coins
		disc += r.disc
		top += r.top
		catches += r.catches
		full += r.full
		gap += r.maxGap
		slots += r.slots
	end
	local cols = {}
	for _, k in keys do
		local c = counts[k] or 0
		table.insert(cols, string.format("%s%s", fmt(sums[k] or 0, c, 60), if c < SEEDS then `({c}/{SEEDS})` else ""))
	end
	print(
		string.format(
			"%-7s %s | %d | %.1f | %.2f%% | %.1f | %.1f | %d",
			p.name,
			table.concat(cols, " "),
			coins / SEEDS,
			disc / SEEDS,
			top / catches * 100,
			full / SEEDS,
			gap / SEEDS / 60,
			slots / SEEDS
		)
	)
end
