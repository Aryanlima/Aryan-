--!nonstrict
-- Tests de la logica de juego de Fish & Fortune (GameLogic + FishingRules + Balance).
local testkit = require("@testkit")
local Balance = require("../src/shared/Balance")
local FishingRules = require("../src/shared/FishingRules")
local GameLogic = require("../src/server/GameLogic")
local Economy = require("../../../packages/Economy")
local Odds = require("../../../packages/Odds")
local Data = require("../../../packages/Data")

local describe, it, expect, beforeEach = testkit.describe, testkit.it, testkit.expect, testkit.beforeEach

local NOW = 1800000000 -- epoch de pruebas

local function lcg(seed)
	local state = seed
	return function()
		state = (state * 1664525 + 1013904223) % 4294967296
		return state / 4294967296
	end
end

describe("GameLogic", function()
	local logic, rules, data, clock, transactions, rngValue

	local function ctx(overrides)
		local c = { player = nil, passes = {}, events = {}, paidRandomAllowed = true, now = NOW }
		for k, v in overrides or {} do
			c[k] = v
		end
		return c
	end

	local function setup(rng)
		clock = 0
		transactions = {}
		rules = FishingRules.new(Balance, Odds)
		logic = GameLogic.new({
			balance = Balance,
			rules = rules,
			economy = Economy,
			rng = rng or function()
				return rngValue
			end,
			clock = function()
				return clock
			end,
			onTransaction = function(tx)
				table.insert(transactions, tx)
			end,
		})
		data = GameLogic.template()
	end

	-- tiempo (s) en el que el marcador esta justo en `center`
	local function perfectTime(center)
		local t = center * Balance.minigame.markerPeriod / 2
		if t < Balance.minigame.minReelSeconds then
			t += Balance.minigame.markerPeriod
		end
		return t
	end

	local function catchOnce(c, quality)
		-- salta el minijuego: resuelve directamente una captura (para preparar estados)
		return logic:resolveCatch(data, c or ctx(), quality)
	end

	beforeEach(function()
		rngValue = 0.5
		setup()
	end)

	describe("plantilla de datos", function()
		it("es serializable (DataStore) y no usa claves numericas", function()
			local ok, why = Data.validate(GameLogic.template())
			expect(why).toBeNil()
			expect(ok).toBe(true)
		end)
	end)

	describe("lanzar y recoger", function()
		it("startCast crea la sesion con el centro dentro de los limites y la anchura de la cana", function()
			local session = logic:startCast(data, GameLogic.newRuntime())
			expect(session).toBeTruthy()
			expect(session.center).toBeGreaterThanOrEqual(Balance.minigame.centerMin)
			expect(session.center).toBeLessThanOrEqual(Balance.minigame.centerMax)
			expect(session.width).toBe(Balance.rods.driftwood.sweetSpot)
			expect(session.expiresAt - session.startedAt).toBeCloseTo(
				Balance.minigame.durationSeconds + Balance.minigame.graceSeconds,
				6
			)
		end)

		it("respeta el enfriamiento y el inventario lleno", function()
			local runtime = GameLogic.newRuntime()
			local session = logic:startCast(data, runtime)
			local t = perfectTime(session.center)
			clock = t
			expect(logic:reel(data, runtime, ctx(), session.id, t)).toBeTruthy()
			local again, reason = logic:startCast(data, runtime)
			expect(again).toBeNil()
			expect(reason).toBe("cooldown")
			clock += Balance.minigame.castCooldownSeconds + 0.01
			expect((logic:startCast(data, runtime))).toBeTruthy()
			-- inventario lleno
			data.inventory = { carp = logic:capacity(data) }
			clock += 100
			local full, why = logic:startCast(data, runtime)
			expect(full).toBeNil()
			expect(why).toBe("inventory-full")
		end)

		it("recoger en el momento perfecto da calidad perfect y suerte gratuita", function()
			local runtime = GameLogic.newRuntime()
			local session = logic:startCast(data, runtime)
			local t = perfectTime(session.center)
			clock = t + 0.05
			local result = logic:reel(data, runtime, ctx(), session.id, t)
			expect(result.quality).toBe("perfect")
			expect(result.luck).toBeGreaterThanOrEqual(Balance.minigame.perfectLuck)
			expect(data.stats.perfectCasts).toBe(1)
		end)

		it("recoger lejos de la zona da calidad ok (sin bonus), pero siempre hay captura", function()
			local runtime = GameLogic.newRuntime()
			local session = logic:startCast(data, runtime)
			local t = Balance.minigame.markerPeriod / 2 -- marcador en el extremo (posicion 1)
			clock = t
			local result = logic:reel(data, runtime, ctx(), session.id, t)
			expect(result.quality).toBe("ok")
			expect(result.creatureId).toBeTruthy()
			expect(data.stats.catches).toBe(1)
		end)

		it("rechaza recoger demasiado pronto sin gastar el lanzamiento", function()
			local runtime = GameLogic.newRuntime()
			local session = logic:startCast(data, runtime)
			clock = 0.2
			local result, reason = logic:reel(data, runtime, ctx(), session.id, 0.1)
			expect(result).toBeNil()
			expect(reason).toBe("too-early")
			expect(runtime.cast).toBeTruthy() -- sigue en curso
		end)

		it("rechaza tiempos imposibles (el cliente dice haber esperado mas de lo que paso)", function()
			local runtime = GameLogic.newRuntime()
			local session = logic:startCast(data, runtime)
			clock = 1
			local result, reason = logic:reel(data, runtime, ctx(), session.id, 2.9)
			expect(result).toBeNil()
			expect(reason).toBe("impossible-time")
		end)

		it("rechaza NaN y tiempos atrasados (stale)", function()
			local runtime = GameLogic.newRuntime()
			local session = logic:startCast(data, runtime)
			clock = 3.9
			expect((select(2, logic:reel(data, runtime, ctx(), session.id, 0 / 0)))).toBe("too-early")
			local _, reason = logic:reel(data, runtime, ctx(), session.id, 0.5)
			expect(reason).toBe("stale")
			expect(runtime.cast).toBeNil() -- se soltó
		end)

		it("un lanzamiento caducado se pierde (sin captura) y exige nuevo lanzamiento", function()
			local runtime = GameLogic.newRuntime()
			local session = logic:startCast(data, runtime)
			clock = session.expiresAt + 1
			local result, reason = logic:reel(data, runtime, ctx(), session.id, 3)
			expect(result).toBeNil()
			expect(reason).toBe("expired")
			expect(runtime.cast).toBeNil()
			expect(data.stats.catches).toBe(0)
		end)

		it("castId incorrecto o repetido: no-cast", function()
			local runtime = GameLogic.newRuntime()
			local session = logic:startCast(data, runtime)
			local t = perfectTime(session.center)
			clock = t
			expect((select(2, logic:reel(data, runtime, ctx(), session.id + 1, t)))).toBe("no-cast")
			expect(logic:reel(data, runtime, ctx(), session.id, t)).toBeTruthy()
			expect((select(2, logic:reel(data, runtime, ctx(), session.id, t)))).toBe("no-cast")
		end)
	end)

	describe("FTUE y capturas", function()
		it(
			"los 3 primeros lanzamientos estan garantizados: Poco comun, Poco comun, Raro (con cualquier RNG)",
			function()
				for _, value in { 0, 0.5, 0.9999 } do
					setup(function()
						return value
					end)
					local rarities = {}
					for _ = 1, 3 do
						table.insert(rarities, catchOnce().rarity)
					end
					expect(rarities).toEqual({ "Uncommon", "Uncommon", "Rare" })
				end
			end
		)

		it("a partir del 4.o lanzamiento se usa la tabla normal (puede salir un Comun)", function()
			rngValue = 0
			for _ = 1, 3 do
				catchOnce()
			end
			expect(catchOnce().rarity).toBe("Common")
		end)

		it("registra el bestiario, las estadisticas y el inventario", function()
			rngValue = 0
			for _ = 1, 3 do
				catchOnce()
			end
			local result = catchOnce()
			expect(result.creatureId).toBe("minnow")
			expect(result.isNew).toBe(true)
			expect(catchOnce().isNew).toBe(false)
			expect(data.bestiary.minnow).toBe(2)
			expect(data.stats.casts).toBe(5)
			expect(data.inventory.minnow).toBe(2)
		end)

		it("con el inventario lleno la captura se vende sola al precio normal (nunca se pierde)", function()
			rngValue = 0
			for _ = 1, 3 do
				catchOnce()
			end
			data.inventory = { carp = logic:capacity(data) }
			local result = catchOnce(ctx({ passes = { double_coins = true } }))
			expect(result.stored).toBe(false)
			expect(result.autoSoldFor).toBe(Balance.creatures[1].value * 2)
			expect(data.wallet.coins).toBe(result.autoSoldFor)
			expect(logic:inventoryCount(data)).toBe(logic:capacity(data))
		end)

		it("el pase de Auto-Pesca es necesario para lanzar automaticamente y no da bonus de minijuego", function()
			expect(logic:autoCast(data, ctx())).toBeNil()
			local result = logic:autoCast(data, ctx({ passes = { auto_fish = true } }))
			expect(result).toBeTruthy()
			expect(result.quality).toBeNil()
			expect(logic:autoInterval(data)).toBe(Balance.rods.driftwood.autoInterval)
		end)
	end)

	describe("suerte (visible en la tabla de odds)", function()
		local function totalLuck(c)
			return (logic:luck(data, c))
		end

		it("la caña aporta suerte gratis; sin otras fuentes es solo eso", function()
			expect(totalLuck(ctx())).toBe(0)
			data.rod = "carbon"
			expect(totalLuck(ctx())).toBeCloseTo(Balance.rods.carbon.luck, 6)
		end)

		it("Suerte+ y Cebo de Suerte suman si PolicyService lo permite", function()
			data.boosts.lucky_bait = NOW + 600
			local c = ctx({ passes = { luck_plus = true } })
			expect(totalLuck(c)).toBeCloseTo(Balance.products.passes.luckPlus + Balance.products.luckyBait.luck, 6)
		end)

		it("con objetos aleatorios de pago restringidos, la suerte comprada con Robux NO cuenta", function()
			data.boosts.lucky_bait = NOW + 600
			local c = ctx({ passes = { luck_plus = true }, paidRandomAllowed = false })
			expect(totalLuck(c)).toBe(0)
			-- la suerte gratuita (caña, evento) sigue contando
			c.events = { { id = "event:mythic_moon", kind = "luck", value = 3, active = true } }
			expect(totalLuck(c)).toBe(3)
		end)

		it("el desglose marca que fuentes son de pago", function()
			local _, list = logic:luck(data, ctx({ passes = { luck_plus = true } }))
			local paid = {}
			for _, source in list do
				if source.paid then
					table.insert(paid, source.id)
				end
			end
			table.sort(paid)
			expect(paid).toEqual({ "boost:lucky_bait", "pass:luck_plus" })
		end)

		it("el total esta limitado por maxLuck", function()
			data.rod = "golden"
			data.boosts.lucky_bait = NOW + 600
			local c = ctx({
				passes = { luck_plus = true },
				events = { { id = "e", kind = "luck", value = 3, active = true } },
			})
			expect(totalLuck(c)).toBe(Balance.limits.maxLuck)
		end)

		it("mas suerte => mas probabilidad de MITICO en la tabla mostrada", function()
			local odds = rules:oddsFor("lake")
			local base = odds:probabilityOf("lake_spirit", 0)
			local boosted = odds:probabilityOf("lake_spirit", Balance.limits.maxLuck)
			expect(boosted).toBeGreaterThan(base * 10)
		end)

		it("la tirada real usa la suerte total de la caña + bonus (resolveCatch -> luck)", function()
			setup(lcg(99))
			data.stats.casts = 10 -- fuera del tutorial
			data.rod = "golden"
			local result = catchOnce(ctx({ passes = { luck_plus = true } }), "perfect")
			expect(result.luck).toBeCloseTo(Balance.rods.golden.luck + 3 + Balance.minigame.perfectLuck, 6)
		end)
	end)

	describe("economia", function()
		it("sellAll vende todo, aplica multiplicadores ADITIVOS con tope y vacia el inventario", function()
			data.inventory = { minnow = 10, carp = 5 } -- 10*8 + 5*18 = 170
			local c = ctx({ passes = { double_coins = true, vip = true } }) -- 1 + 1 + 0.1 = 2.1
			local earned, count = logic:sellAll(data, c)
			expect(count).toBe(15)
			expect(earned).toBe(Economy.round(170 * 2.1))
			expect(data.wallet.coins).toBe(earned)
			expect(next(data.inventory)).toBeNil()
			expect(data.stats.sells).toBe(1)
		end)

		it("evento + boost + pase respetan el tope del multiplicador", function()
			data.boosts.coin_boost = NOW + 100
			local c = ctx({
				passes = { double_coins = true, vip = true },
				events = { { id = "e", kind = "coins", value = 20, active = true } },
			})
			expect(logic:coinMultiplier(data, c)).toBe(Balance.limits.coinMultiplierCap)
		end)

		it("vender un inventario vacio no hace nada", function()
			local earned, count = logic:sellAll(data, ctx())
			expect(earned).toBe(0)
			expect(count).toBe(0)
			expect(data.stats.sells).toBe(0)
		end)

		it("las transacciones se notifican para analitica (fuente Gameplay, SKU de venta)", function()
			data.inventory = { carp = 2 }
			logic:sellAll(data, ctx())
			local last = transactions[#transactions]
			expect(last.flow).toBe("Source")
			expect(last.currency).toBe("coins")
			expect(last.reason).toBe("Gameplay")
			expect(last.sku).toBe("fish_sale")
		end)

		it("comprar caña: valida precio, equipa si es mejor y no permite duplicados", function()
			local ok, reason = logic:buyRod(data, "reed")
			expect(ok).toBe(false)
			expect(reason).toBe("not-enough-coins")
			data.wallet.coins = 200
			expect(logic:buyRod(data, "reed")).toBe(true)
			expect(data.wallet.coins).toBe(200 - Balance.rods.reed.price)
			expect(data.rod).toBe("reed")
			expect(select(2, logic:buyRod(data, "reed"))).toBe("owned")
			expect(select(2, logic:buyRod(data, "nope"))).toBe("unknown")
			expect(logic:equipRod(data, "driftwood")).toBe(true)
			expect(select(2, logic:equipRod(data, "carbon"))).toBe("not-owned")
		end)

		it("zonas: desbloqueo con monedas y viaje solo a zonas desbloqueadas", function()
			expect(select(2, logic:travel(data, "river"))).toBe("locked")
			expect(select(2, logic:unlockZone(data, "river"))).toBe("not-enough-coins")
			data.wallet.coins = Balance.zones.river.unlockCost
			expect(logic:unlockZone(data, "river")).toBe(true)
			expect(data.wallet.coins).toBe(0)
			expect(logic:travel(data, "river")).toBe(true)
			expect(data.zone).toBe("river")
			expect(select(2, logic:unlockZone(data, "river"))).toBe("owned")
			expect(select(2, logic:travel(data, "mars"))).toBe("unknown")
		end)

		it("las ranuras por encima del tope se convierten en perlas (nunca se pierde un pago)", function()
			local maxExtra = Balance.inventory.maxSlots - Balance.inventory.baseSlots
			data.extraSlots = maxExtra - 4
			logic:grantReward(data, { slots = 10 }, "IAP", "slot_pack")
			expect(data.extraSlots).toBe(maxExtra)
			expect(data.wallet.pearls).toBe(6)
		end)

		it("comprar espacio con perlas (alternativa gratuita) respeta el tope", function()
			data.wallet.pearls = Balance.inventory.pearlsPerSlotPack
			expect(logic:buySlotsWithPearls(data)).toBe(true)
			expect(logic:capacity(data)).toBe(Balance.inventory.baseSlots + Balance.inventory.slotsPerPack)
			expect(select(2, logic:buySlotsWithPearls(data))).toBe("not-enough-pearls")
			data.extraSlots = Balance.inventory.maxSlots - Balance.inventory.baseSlots
			data.wallet.pearls = 999
			expect(select(2, logic:buySlotsWithPearls(data))).toBe("max-slots")
		end)
	end)

	describe("productos (handlers de Shop)", function()
		local function product(kind, grant)
			return { key = "p", kind = kind, grant = grant }
		end

		it("currency, slots y boost conceden lo esperado", function()
			local profile = { data = data }
			expect(logic:grantProduct(nil, profile, product("currency", { coins = 100, pearls = 2 }), NOW)).toBe(true)
			expect(data.wallet.coins).toBe(100)
			expect(data.wallet.pearls).toBe(2)
			expect(logic:grantProduct(nil, profile, product("slots", { slots = 10 }), NOW)).toBe(true)
			expect(data.extraSlots).toBe(10)
			expect(logic:grantProduct(nil, profile, product("boost", { boostId = "coin_boost", seconds = 900 }), NOW)).toBe(
				true
			)
			expect(Economy.boostRemaining(data.boosts, "coin_boost", NOW)).toBe(900)
		end)

		it("un boost no acumula mas del maximo", function()
			local profile = { data = data }
			for _ = 1, 20 do
				logic:grantProduct(nil, profile, product("boost", { boostId = "lucky_bait", seconds = 900 }), NOW)
			end
			expect(Economy.boostRemaining(data.boosts, "lucky_bait", NOW)).toBe(Balance.limits.maxBoostSeconds)
		end)

		it("datos invalidos o kind desconocido NO conceden (el recibo queda pendiente)", function()
			local profile = { data = data }
			expect(logic:grantProduct(nil, profile, product("boost", { boostId = 5, seconds = "x" }), NOW)).toBe(false)
			expect(logic:grantProduct(nil, profile, product("magic", { coins = 1 }), NOW)).toBe(false)
			expect(logic:grantProduct(nil, profile, { key = "x", kind = "currency" }, NOW)).toBe(false)
			expect(data.wallet.coins).toBe(0)
		end)
	end)

	describe("bestiario", function()
		local function discover(ids)
			for _, id in ids do
				data.bestiary[id] = 1
			end
		end

		it("no permite reclamar lo no alcanzado, ni reclamar dos veces", function()
			expect(select(2, logic:claimBestiary(data, "disc_5"))).toBe("not-reached")
			discover({ "minnow", "perch", "carp", "bluegill", "catfish" })
			expect(logic:claimBestiary(data, "disc_5")).toBe(true)
			expect(data.wallet.coins).toBe(500)
			expect(select(2, logic:claimBestiary(data, "disc_5"))).toBe("claimed")
			expect(data.wallet.coins).toBe(500)
			expect(select(2, logic:claimBestiary(data, "nope"))).toBe("unknown")
		end)

		it("completar una zona da su recompensa", function()
			discover({
				"minnow",
				"perch",
				"carp",
				"bluegill",
				"catfish",
				"golden_trout",
				"moon_koi",
				"ancient_carp",
			})
			expect(select(2, logic:claimBestiary(data, "zone_lake"))).toBe("not-reached") -- falta el MITICO
			discover({ "lake_spirit" })
			expect(logic:claimBestiary(data, "zone_lake")).toBe(true)
			expect(data.wallet.pearls).toBe(5)
		end)
	end)

	describe("temporada", function()
		it("seasonSync reinicia al cambiar de temporada y conserva dentro de la misma", function()
			logic:seasonSync(data, 1)
			data.season.points = 50
			logic:seasonSync(data, 1)
			expect(data.season.points).toBe(50)
			logic:seasonSync(data, 2)
			expect(data.season.points).toBe(0)
			expect(data.season.id).toBe(2)
		end)

		it("las capturas dan puntos segun la rareza", function()
			logic:seasonSync(data, 1)
			rngValue = 0
			data.stats.casts = 10
			catchOnce() -- minnow (Common) = 1 punto
			expect(data.season.points).toBe(Balance.rarities.Common.seasonPoints)
		end)

		it("reclamar exige puntos; la pista premium exige el pase; no se cobra dos veces", function()
			logic:seasonSync(data, 1)
			expect(select(2, logic:claimSeason(data, 1, "free", ctx()))).toBe("not-reached")
			data.season.points = 40
			expect(logic:claimSeason(data, 1, "free", ctx())).toBe(true)
			expect(data.wallet.coins).toBe(300)
			expect(select(2, logic:claimSeason(data, 1, "free", ctx()))).toBe("claimed")
			expect(select(2, logic:claimSeason(data, 1, "premium", ctx()))).toBe("needs-pass")
			expect(logic:claimSeason(data, 1, "premium", ctx({ passes = { season_pass = true } }))).toBe(true)
			expect(data.wallet.pearls).toBe(5)
			expect(select(2, logic:claimSeason(data, 1, "premium", ctx({ passes = { season_pass = true } })))).toBe(
				"claimed"
			)
			expect(select(2, logic:claimSeason(data, 99, "free", ctx()))).toBe("unknown")
			expect(select(2, logic:claimSeason(data, 1, "gold", ctx()))).toBe("unknown")
		end)

		it("sin temporada activa no se reclama nada", function()
			expect(select(2, logic:claimSeason(data, 1, "free", ctx()))).toBe("no-season")
		end)
	end)

	describe("VIP diario y offline", function()
		it("el diario VIP se cobra una vez por dia UTC", function()
			local c = ctx({ passes = { vip = true } })
			expect(logic:claimDaily(data, c)).toBe(true)
			expect(data.wallet.pearls).toBe(Balance.vip.dailyPearls)
			expect(select(2, logic:claimDaily(data, c))).toBe("claimed")
			c.now += 86400
			expect(logic:claimDaily(data, c)).toBe(true)
			expect(select(2, logic:claimDaily(data, ctx()))).toBe("needs-vip")
		end)

		it("offline: primera sesion no da nada; despues respeta el tope (mayor con Auto-Pesca)", function()
			local first = logic:applyOffline(data, ctx())
			expect(first).toBe(0)
			expect(data.lastSeen).toBe(NOW)
			-- 10 h despues, sin pase: tope de 2 h
			local later = ctx({ now = NOW + 10 * 3600 })
			local earned, seconds, capped = logic:applyOffline(data, later)
			expect(seconds).toBe(Balance.offline.baseCapSeconds)
			expect(capped).toBe(true)
			expect(earned).toBe(Economy.round(Balance.rods.driftwood.offlinePerHour * 2))
			-- con Auto-Pesca: tope de 6 h
			data.lastSeen = NOW
			local withPass = ctx({ now = NOW + 10 * 3600, passes = { auto_fish = true } })
			local earned2, seconds2 = logic:applyOffline(data, withPass)
			expect(seconds2).toBe(Balance.offline.autoFishCapSeconds)
			expect(earned2).toBeGreaterThan(earned)
		end)

		it("offline: menos de minSeconds no da nada", function()
			data.lastSeen = NOW
			local earned = logic:applyOffline(data, ctx({ now = NOW + 30 }))
			expect(earned).toBe(0)
		end)
	end)

	describe("primeros 60 segundos (FTUE)", function()
		it("primera captura, primera venta y primera compra en <= 60 s con un jugador razonable", function()
			setup(lcg(7))
			local runtime = GameLogic.newRuntime()
			local t = 5 -- 0-5 s: aparece y ve el objetivo
			local firstCatchAt, firstSellAt, firstBuyAt
			for i = 1, 3 do
				clock = t
				local session = logic:startCast(data, runtime)
				expect(session).toBeTruthy()
				local elapsed = perfectTime(session.center)
				-- el jugador reacciona con ~0.5 s de retraso sobre el momento ideal
				elapsed = math.max(elapsed, 1.0)
				clock = t + elapsed
				local result = logic:reel(data, runtime, ctx(), session.id, elapsed)
				expect(result).toBeTruthy()
				t = clock + 1.5 -- animacion de captura + enfriamiento
				if i == 1 then
					firstCatchAt = clock
				end
			end
			t += 3 -- pulsar "Vender todo"
			local earned = logic:sellAll(data, ctx())
			firstSellAt = t
			expect(earned).toBeGreaterThanOrEqual(Balance.rods.reed.price)
			t += 4 -- abrir la tienda y comprar la caña
			expect(logic:buyRod(data, "reed")).toBe(true)
			firstBuyAt = t
			expect(firstCatchAt).toBeLessThanOrEqual(Balance.ftue.targetSeconds)
			expect(firstSellAt).toBeLessThanOrEqual(Balance.ftue.targetSeconds)
			expect(firstBuyAt).toBeLessThanOrEqual(Balance.ftue.targetSeconds)
			-- y el tercer lanzamiento fue el "reveal" Raro
			expect(data.bestiary.golden_trout or data.bestiary.catfish).toBeTruthy()
		end)
	end)
end)
