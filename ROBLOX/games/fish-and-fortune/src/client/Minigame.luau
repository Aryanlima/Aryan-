--!strict
--[[
	Minigame: el lanzamiento de ~3 s. El servidor crea la sesion (CastStarted) y valida la recogida; aqui solo se
	dibuja la barra, el marcador y la zona perfecta, y se envia Reel(castId, segundosTranscurridos).

	El tiempo que enviamos lo contrasta el servidor con su propio reloj (no puede ser imposible); lo unico que un
	cliente tramposo podria conseguir es acertar siempre la zona perfecta: bonus pequeno y gratuito.
	Tambien gestiona la tecla ESPACIO (ContextActionService) como atajo de LANZAR / RECOGER.
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
	local gui: ScreenGui = ctx.gui

	local casting = false
	local waiting = false -- recogido: esperando el resultado del servidor
	local session: any = nil
	local startedClock = 0
	local renderConnection: RBXScriptConnection? = nil
	local bobber: Part? = nil
	local listeners: { () -> () } = {}

	local overlay = UI.create("Frame", {
		Name = "Minigame",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.42, 0),
		Size = UDim2.new(0.86, 0, 0, 84),
		BackgroundColor3 = rgb(UI.theme.colors.panel),
		BorderSizePixel = 0,
		Visible = false,
		Parent = gui,
	}, {
		UI.create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		UI.create("UISizeConstraint", { MaxSize = Vector2.new(520, 100) }),
	})
	local title = UI.label({
		text = "Pulsa RECOGER cuando el marcador pase por la zona verde",
		size = UDim2.new(1, -16, 0, 26),
		textSize = 16,
		alignX = Enum.TextXAlignment.Center,
		parent = overlay,
	})
	title.Position = UDim2.new(0, 8, 0, 6)
	local bar = UI.create("Frame", {
		Name = "Bar",
		Position = UDim2.new(0, 12, 0, 44),
		Size = UDim2.new(1, -24, 0, 26),
		BackgroundColor3 = rgb(UI.theme.colors.row),
		BorderSizePixel = 0,
		Parent = overlay,
	}, { UI.create("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	local sweet = UI.create("Frame", {
		Name = "SweetSpot",
		Size = UDim2.new(0.14, 0, 1, 0),
		BackgroundColor3 = rgb(UI.theme.colors.positive),
		BorderSizePixel = 0,
		Parent = bar,
	}, { UI.create("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	local marker = UI.create("Frame", {
		Name = "Marker",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 8, 1, 10),
		BackgroundColor3 = rgb(UI.theme.colors.text),
		BorderSizePixel = 0,
		Parent = bar,
	}, { UI.create("UICorner", { CornerRadius = UDim.new(0, 4) }) })

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
		notify()
	end

	local function reel()
		if not casting or session == nil then
			return
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
		startedClock = os.clock()
		sweet.Size = UDim2.new(payload.width, 0, 1, 0)
		sweet.Position = UDim2.new(payload.center - payload.width / 2, 0, 0, 0)
		overlay.Visible = true
		placeBobber(payload.zone)
		stopRender()
		renderConnection = RunService.RenderStepped:Connect(function()
			local elapsed = os.clock() - startedClock
			marker.Position = UDim2.new(rules:markerPosition(elapsed), 0, 0.5, 0)
			if elapsed > balance.minigame.durationSeconds + balance.minigame.graceSeconds - 0.2 then
				-- tiempo agotado en el cliente: el pez se suelta (el servidor tambien lo da por perdido)
				finish()
				removeBobber()
				ctx.feedback.toast("Se solto el pez. Vuelve a lanzar.")
			end
		end)
		notify()
	end

	local function onCastFailed(_reason: string)
		waiting = false
		if casting then
			finish()
		end
		removeBobber()
		notify()
	end

	local function onCatch(_payload: any)
		waiting = false
		removeBobber()
		notify()
	end

	ContextActionService:BindAction("FF_Action", function(_name: string, state: Enum.UserInputState)
		if state == Enum.UserInputState.Begin then
			action()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.Space)

	return {
		action = action,
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
