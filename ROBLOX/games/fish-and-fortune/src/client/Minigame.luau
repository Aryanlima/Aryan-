--!strict
--[[
	Minigame: el lanzamiento de ~3 s. El servidor crea la sesion (CastStarted) y valida la recogida; aqui solo se
	dibuja la barra, el marcador y la zona perfecta, y se envia Reel(castId, segundosTranscurridos).

	El tiempo que enviamos lo contrasta el servidor con su propio reloj (no puede ser imposible); lo unico que un
	cliente tramposo podria conseguir es acertar siempre la zona perfecta: bonus pequeno y gratuito.
	Tambien gestiona la tecla ESPACIO (ContextActionService) como atajo de LANZAR / RECOGER.

	Estilo "Muelle de madera": marco de tablas, zona perfecta brillante que late, marcador que crece dentro de ella.
	Jugo: la barra entra con Back, "!" al picar + golpe de camara minimo, PERFECT/GREAT con pop y destello, y
	temblor + "Escaped!" al fallar. Todo respeta UI.motion.reduced; sin RenderStepped nuevo.
]]

local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Minigame = {}

local function rgb(triple: { number }): Color3
	return Color3.fromRGB(triple[1], triple[2], triple[3])
end

function Minigame.start(ctx: any): any
	local UI = ctx.UI
	local rules = ctx.rules
	local balance = ctx.Balance
	local L = ctx.L
	local gui: ScreenGui = ctx.gui

	local casting = false
	local waiting = false -- recogido: esperando el resultado del servidor
	local session: any = nil
	local startedClock = 0
	local renderConnection: RBXScriptConnection? = nil
	local bobber: Part? = nil
	local listeners: { () -> () } = {}

	local BASE_POSITION = UDim2.new(0.5, 0, 0.42, 0)
	local overlay = UI.create("Frame", {
		Name = "Minigame",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = BASE_POSITION,
		Size = UDim2.new(0.86, 0, 0, 92),
		BackgroundColor3 = rgb(UI.theme.colors.woodGrain),
		BorderSizePixel = 0,
		Visible = false,
		Parent = gui,
	}, {
		UI.create("UICorner", { CornerRadius = UDim.new(0, 16) }),
		UI.create("UIStroke", {
			Color = rgb(UI.theme.colors.woodDark),
			Thickness = 4,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		UI.create("UISizeConstraint", { MaxSize = Vector2.new(520, 104) }),
	})
	local title = UI.label({
		text = L("hint.reel"),
		size = UDim2.new(1, -16, 0, 28),
		textSize = 20,
		display = true,
		alignX = Enum.TextXAlignment.Center,
		parent = overlay,
	})
	title.Position = UDim2.new(0, 8, 0, 6)
	local bar = UI.create("Frame", {
		Name = "Bar",
		Position = UDim2.new(0, 12, 0, 46),
		Size = UDim2.new(1, -24, 0, 30),
		BackgroundColor3 = rgb(UI.theme.colors.woodDark),
		BorderSizePixel = 0,
		Parent = overlay,
	}, {
		UI.create("UICorner", { CornerRadius = UDim.new(0, 12) }),
		UI.create("UIStroke", {
			Color = rgb(UI.theme.colors.ink),
			Thickness = 3,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
	})
	local sweet = UI.create("Frame", {
		Name = "SweetSpot",
		Size = UDim2.new(0.14, 0, 1, 0),
		BackgroundColor3 = rgb(UI.theme.colors.positive),
		BorderSizePixel = 0,
		Parent = bar,
	}, { UI.create("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	local glow = UI.create("UIStroke", {
		Color = rgb(UI.theme.colors.gold),
		Thickness = 3,
		Transparency = 0.3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = sweet,
	})
	local marker = UI.create("Frame", {
		Name = "Marker",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 8, 1, 10),
		BackgroundColor3 = rgb(UI.theme.colors.text),
		BorderSizePixel = 0,
		Parent = bar,
	}, {
		UI.create("UICorner", { CornerRadius = UDim.new(0, 4) }),
		UI.create("UIStroke", { Color = rgb(UI.theme.colors.ink), Thickness = 2 }),
	})
	local markerScale = UI.motion.scaleOf(marker)
	local inside = false
	local shown = false
	local resultLabel: any = nil
	local hideToken = 0
	local punching = false

	-- Golpe de camara diminuto (campo de vision: no choca con el script de camara). Sin camara o con movimiento reducido: nada.
	local function nudge(amount: number)
		if UI.motion.reduced or punching then
			return
		end
		pcall(function()
			local camera = Workspace.CurrentCamera
			if camera == nil then
				return
			end
			punching = true
			local base = camera.FieldOfView
			UI.motion.tween(camera, { FieldOfView = base - amount }, 0.06)
			task.delay(0.06, function()
				UI.motion.tween(camera, { FieldOfView = base }, 0.2)
				task.delay(0.22, function()
					punching = false
				end)
			end)
		end)
	end

	-- Texto grande de resultado (PERFECT / GREAT / Escaped): pop y se desvanece solo.
	local function showResult(text: string, colorName: string)
		if resultLabel ~= nil then
			resultLabel:Destroy()
		end
		local label = UI.label({
			text = text,
			size = UDim2.new(0.9, 0, 0, 60),
			textSize = 48,
			display = true,
			alignX = Enum.TextXAlignment.Center,
			parent = gui,
		})
		label.Name = "MinigameResult"
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.new(0.5, 0, 0.64, 0)
		label.TextColor3 = rgb(UI.theme.colors[colorName])
		label.ZIndex = 6
		resultLabel = label
		UI.motion.appear(label, 0.4, 0.28)
		task.delay(0.75, function()
			if label.Parent ~= nil then
				UI.motion.tween(label, { TextTransparency = 1, Position = UDim2.new(0.5, 0, 0.26, 0) }, 0.3)
			end
		end)
		task.delay(1.1, function()
			if label.Parent ~= nil then
				label:Destroy()
			end
			if resultLabel == label then
				resultLabel = nil
			end
		end)
	end

	local function flash(colorName: string)
		if UI.motion.reduced then
			return
		end
		local frame = UI.create("Frame", {
			Name = "MinigameFlash",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = rgb(UI.theme.colors[colorName]),
			BackgroundTransparency = 0.8,
			BorderSizePixel = 0,
			Active = false,
			ZIndex = 4,
			Parent = gui,
		})
		UI.motion.tween(frame, { BackgroundTransparency = 1 }, 0.25)
		task.delay(0.3, function()
			frame:Destroy()
		end)
	end

	-- La barra aparece al picar: entra deslizando con Back y la zona perfecta late.
	local function showBar()
		hideToken += 1
		overlay.Position = BASE_POSITION
		overlay.Visible = true
		UI.motion.slideIn(overlay, 0, 50, 0.3)
		UI.motion.appear(overlay, 0.9, 0.3)
		UI.motion.tween(glow, { Transparency = 0.75 }, 0.5, "Sine", "InOut", -1, true)
	end

	-- Fallo: la barra reaparece un momento, tiembla y sale "Escaped!".
	local function showEscape()
		hideToken += 1
		local token = hideToken
		overlay.Position = BASE_POSITION
		overlay.Visible = true
		UI.motion.tween(glow, { Transparency = 0.3 }, 0.05)
		UI.motion.shake(overlay, 8)
		showResult(L("minigame.escaped"), "coral")
		task.delay(0.5, function()
			if hideToken == token and not casting then
				overlay.Visible = false
			end
		end)
	end

	local function notify()
		for _, listener in listeners do
			listener()
		end
	end

	local function removeBobber()
		if bobber ~= nil then
			bobber:Destroy()
			bobber = nil
		end
	end

	-- Salpicadura con particulas y onda expansiva. Solo vista: si algo falla (p. ej. el entorno de pruebas) no pasa nada.
	local function splashAt(position: Vector3, count: number)
		pcall(function()
			local holder = Instance.new("Part")
			holder.Anchored = true
			holder.CanCollide = false
			holder.CanQuery = false
			holder.Transparency = 1
			holder.Size = Vector3.new(0.2, 0.2, 0.2)
			holder.Position = position
			holder.Parent = Workspace
			local drops = Instance.new("ParticleEmitter")
			drops.Color = ColorSequence.new(Color3.fromRGB(220, 244, 255))
			drops.Size = NumberSequence.new(0.5, 0.1)
			drops.Lifetime = NumberRange.new(0.5, 0.9)
			drops.Speed = NumberRange.new(10, 18)
			drops.SpreadAngle = Vector2.new(35, 35)
			drops.Acceleration = Vector3.new(0, -40, 0)
			drops.Rate = 0
			drops.Texture = UI.theme.icons.Bubble or ""
			drops.Parent = holder
			drops:Emit(count)
			-- Flipbook de salpicadura: si el entorno no admite sus propiedades, solo se omite.
			pcall(function()
				local flip = Instance.new("ParticleEmitter")
				flip.Texture = UI.theme.icons.Splash or ""
				flip.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
				flip.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
				flip.Lifetime = NumberRange.new(0.67)
				flip.LightEmission = 0
				flip.Size = NumberSequence.new(5)
				flip.Speed = NumberRange.new(0)
				flip.Rate = 0
				flip.Parent = holder
				flip:Emit(1)
			end)
			local ring = Instance.new("Part")
			ring.Shape = Enum.PartType.Cylinder
			ring.Anchored = true
			ring.CanCollide = false
			ring.CanQuery = false
			ring.Material = Enum.Material.Neon
			ring.Color = Color3.fromRGB(230, 248, 255)
			ring.Transparency = 0.35
			ring.Size = Vector3.new(0.1, 1, 1)
			ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
			ring.Parent = Workspace
			TweenService:Create(ring, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.1, 9, 9),
				Transparency = 1,
			}):Play()
			task.delay(1.2, function()
				holder:Destroy()
				ring:Destroy()
			end)
		end)
	end

	-- "!" grande en pantalla + golpe de camara + "!" sobre el corcho cuando pica el pez.
	local function biteAlert()
		nudge(3)
		local mark = UI.label({
			text = "!",
			size = UDim2.new(0, 120, 0, 120),
			textSize = 110,
			display = true,
			alignX = Enum.TextXAlignment.Center,
			parent = gui,
		})
		mark.Name = "BiteMark"
		mark.AnchorPoint = Vector2.new(0.5, 0.5)
		mark.Position = UDim2.new(0.5, 0, 0.25, 0)
		mark.TextColor3 = rgb(UI.theme.colors.gold)
		mark.ZIndex = 6
		UI.motion.appear(mark, 0.3, 0.25)
		task.delay(0.5, function()
			UI.motion.tween(mark, { TextTransparency = 1 }, 0.2)
		end)
		task.delay(0.75, function()
			mark:Destroy()
		end)
		local current = bobber
		if current == nil then
			return
		end
		pcall(function()
			splashAt(current.Position, 28)
			local board = Instance.new("BillboardGui")
			board.Size = UDim2.fromOffset(60, 60)
			board.StudsOffset = Vector3.new(0, 3, 0)
			board.AlwaysOnTop = true
			local exclaim = Instance.new("TextLabel")
			exclaim.Size = UDim2.fromScale(1, 1)
			exclaim.BackgroundTransparency = 1
			exclaim.Text = "!"
			exclaim.TextScaled = true
			exclaim.Font = Enum.Font.GothamBlack
			exclaim.TextColor3 = Color3.fromRGB(255, 200, 61)
			exclaim.TextStrokeTransparency = 0
			exclaim.Parent = board
			board.Parent = current
			task.delay(1.4, function()
				board:Destroy()
			end)
		end)
	end

	local function placeBobber(zoneId: string)
		removeBobber()
		local world = Workspace:FindFirstChild("World")
		local zoneFolder = if world then world:FindFirstChild(zoneId) else nil
		local target = if zoneFolder then zoneFolder:FindFirstChild("CastTarget") else nil
		if target == nil or not target:IsA("BasePart") then
			return
		end
		local part = Instance.new("Part")
		part.Name = "Bobber"
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(1.2, 1.2, 1.2)
		part.Color = Color3.fromRGB(235, 70, 70)
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.Position = target.Position + Vector3.new(0, 0.6, 0)
		part.Parent = Workspace
		splashAt(part.Position, 14)
		TweenService:Create(
			part,
			TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Position = part.Position + Vector3.new(0, 0.5, 0) }
		):Play()
		bobber = part
	end

	local function stopRender()
		if renderConnection ~= nil then
			renderConnection:Disconnect()
			renderConnection = nil
		end
	end

	local function finish()
		casting = false
		stopRender()
		overlay.Visible = false
		UI.motion.tween(glow, { Transparency = 0.3 }, 0.05) -- corta el latido
		notify()
	end

	local function reel()
		if not casting or session == nil or os.clock() < startedClock then
			return -- todavia no ha picado: recoger antes no hace nada
		end
		local elapsed = os.clock() - startedClock
		ctx.net:fire("Reel", session.id, elapsed)
		waiting = true
		finish()
	end

	local function action()
		if casting then
			reel()
		elseif not waiting then
			ctx.net:fire("Cast")
		end
	end

	local function onCastStarted(payload: any)
		session = payload
		casting = true
		waiting = false
		shown = false
		inside = false
		markerScale.Scale = 1
		marker.BackgroundColor3 = rgb(UI.theme.colors.text)
		startedClock = os.clock() + (payload.bite or 0) -- el minijuego empieza con la PICADA
		sweet.Size = UDim2.new(payload.width, 0, 1, 0)
		sweet.Position = UDim2.new(payload.center - payload.width / 2, 0, 0, 0)
		title.Text = L("hint.bite") -- en el idioma actual del jugador
		overlay.Visible = (payload.bite or 0) <= 0 -- sin espera, la barra sale ya
		placeBobber(payload.zone)
		ctx.feedback.toast(L("hint.wait_bite"))
		stopRender()
		renderConnection = RunService.RenderStepped:Connect(function()
			local elapsed = os.clock() - startedClock
			if elapsed < 0 then
				return -- esperando la picada: solo se ve el corcho
			end
			if not shown then
				shown = true
				showBar()
				biteAlert()
			end
			local position = rules:markerPosition(elapsed)
			marker.Position = UDim2.new(position, 0, 0.5, 0)
			-- el marcador crece dentro de la zona perfecta (se calcula aqui, sin tween)
			local nowInside = math.abs(position - session.center) <= session.width / 2
			if nowInside ~= inside then
				inside = nowInside
				markerScale.Scale = if nowInside then 1.3 else 1
				marker.BackgroundColor3 = rgb(if nowInside then UI.theme.colors.gold else UI.theme.colors.text)
			end
			if elapsed > balance.minigame.durationSeconds + balance.minigame.graceSeconds - 0.2 then
				-- tiempo agotado en el cliente: el pez se suelta (el servidor tambien lo da por perdido)
				finish()
				removeBobber()
				showEscape()
				ctx.feedback.toast(L("fail.expired"))
			end
		end)
		notify()
	end

	local function onCastFailed(_reason: string)
		local wasActive = waiting or casting
		waiting = false
		if casting then
			finish()
		end
		if wasActive and shown then
			showEscape()
		end
		removeBobber()
		notify()
	end

	local function onCatch(payload: any)
		waiting = false
		removeBobber()
		if type(payload) == "table" then
			if payload.quality == "perfect" then
				showResult(L("minigame.perfect"), "gold")
				flash("gold")
			elseif payload.quality == "good" then
				showResult(L("minigame.great"), "positive")
			end
		end
		notify()
	end

	ContextActionService:BindAction("FF_Action", function(_name: string, state: Enum.UserInputState)
		-- con un panel abierto, A/Espacio son del panel (seleccion del mando), no del anzuelo
		if ctx.menus ~= nil and ctx.menus.isOpen() then
			return Enum.ContextActionResult.Pass
		end
		if state == Enum.UserInputState.Begin then
			action()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA) -- teclado y mando

	return {
		action = action,
		isBiting = function(): boolean
			return casting and os.clock() >= startedClock
		end,
		isCasting = function(): boolean
			return casting
		end,
		onCastStarted = onCastStarted,
		onCastFailed = onCastFailed,
		onCatch = onCatch,
		subscribe = function(listener: () -> ())
			table.insert(listeners, listener)
		end,
	}
end

return Minigame
