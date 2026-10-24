--!strict
-- Hud: vida (arriba-izq), sala (arriba-centro), nivel/XP (abajo), pantalla de resultado y utilidades de UI compartidas.
-- Datos: atributos del LocalPlayer (los pone el servidor): Hp, MaxHp, Level, Xp, XpNext, Room, RoomTotal.
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Strings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Strings"))

local player = Players.LocalPlayer
local theme = {
	coral = Color3.fromHex("FF6F59"),
	turquoise = Color3.fromHex("2EC4B6"),
	jade = Color3.fromHex("3DA35D"),
	yellow = Color3.fromHex("FFC857"),
	violet = Color3.fromHex("7B5EA7"),
	night = Color3.fromHex("1B2A41"),
	white = Color3.new(1, 1, 1),
}

local Hud = {}
Hud.theme = theme

function Hud.lang(): string
	return if string.sub(player.LocaleId, 1, 2) == "es" then "es" else "en"
end

function Hud.text(key: string, args: { [string]: any }?): string
	return Strings.get(key, Hud.lang(), args)
end

-- ScreenGui con safe areas y UIScale por altura de pantalla (0.7-1).
function Hud.makeGui(name: string, order: number): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.DisplayOrder = order
	pcall(function()
		gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	end)
	local scale = Instance.new("UIScale")
	scale.Parent = gui
	local camera = workspace.CurrentCamera :: Camera
	local function update()
		scale.Scale = math.clamp(camera.ViewportSize.Y / 1080, 0.7, 1)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	update()
	return gui
end

function Hud.round(parent: Instance, radius: number, color: Color3?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	if color then
		local s = Instance.new("UIStroke")
		s.Color, s.Thickness = color, 3
		s.Parent = parent
	end
end

function Hud.label(parent: Instance, text: string, size: number, color: Color3?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.Text, l.TextSize, l.TextColor3 = text, size, color or theme.white
	l.TextWrapped = true
	l.Parent = parent
	return l
end

local function bar(parent: Instance, pos: UDim2, size: UDim2, anchor: Vector2, fill: Color3): (Frame, TextLabel)
	local back = Instance.new("Frame")
	back.AnchorPoint, back.Position, back.Size = anchor, pos, size
	back.BackgroundColor3 = theme.night
	back.BackgroundTransparency = 0.2
	back.Parent = parent
	Hud.round(back, 12, theme.night)
	local f = Instance.new("Frame")
	f.Name = "Fill"
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = fill
	f.Parent = back
	Hud.round(f, 12)
	local l = Hud.label(back, "", 20)
	l.Size = UDim2.fromScale(1, 1)
	l.ZIndex = 2
	return f, l
end

local function num(name: string, default: number): number
	local v = player:GetAttribute(name)
	return if type(v) == "number" then v else default
end

function Hud.start()
	local gui = Hud.makeGui("Hud", 1)
	local hpFill, hpText = bar(gui, UDim2.fromOffset(16, 16), UDim2.fromOffset(280, 32), Vector2.zero, theme.coral)
	local xpFill, xpText =
		bar(gui, UDim2.new(0.5, 0, 1, -16), UDim2.new(0.6, 0, 0, 28), Vector2.new(0.5, 1), theme.turquoise)
	local room = Hud.label(gui, "", 28, theme.yellow)
	room.Name = "Room"
	room.AnchorPoint, room.Position, room.Size =
		Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 16), UDim2.fromOffset(260, 36)

	local function refresh()
		local hp, maxHp = num("Hp", 0), math.max(num("MaxHp", 1), 1)
		hpFill.Size = UDim2.fromScale(math.clamp(hp / maxHp, 0, 1), 1)
		hpText.Text = `{math.ceil(hp)}/{math.ceil(maxHp)}`
		xpFill.Size = UDim2.fromScale(math.clamp(num("Xp", 0) / math.max(num("XpNext", 1), 1), 0, 1), 1)
		xpText.Text = Hud.text("hud.level", { level = num("Level", 1) })
		room.Text = Hud.text("hud.room", { room = num("Room", 1), total = num("RoomTotal", 10) })
	end
	for _, name in { "Hp", "MaxHp", "Xp", "XpNext", "Level", "Room", "RoomTotal" } do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end
	refresh()
	gui.Parent = player:WaitForChild("PlayerGui")
end

-- RunResult(victory, reward): panel central con boton Reintentar que dispara Ready.
function Hud.showResult(victory: boolean, reward: number, ready: RemoteEvent)
	local accent = if victory then theme.jade else theme.coral
	local gui = Hud.makeGui("RunResult", 10)
	local panel = Instance.new("Frame")
	panel.AnchorPoint, panel.Position, panel.Size =
		Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(420, 300)
	panel.BackgroundColor3 = theme.night
	panel.Parent = gui
	Hud.round(panel, 24, accent)
	local title = Hud.label(
		panel,
		Hud.text(if victory then "result.victory" else "result.defeat"),
		44,
		if victory then theme.yellow else theme.coral
	)
	title.Size, title.Position = UDim2.new(1, 0, 0, 70), UDim2.fromOffset(0, 24)
	local info = Hud.label(panel, Hud.text("result.reward", { reward = reward }), 26)
	info.Size, info.Position = UDim2.new(1, 0, 0, 40), UDim2.fromOffset(0, 110)
	local btn = Instance.new("TextButton")
	btn.AnchorPoint, btn.Position, btn.Size = Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -24), UDim2.fromOffset(240, 80)
	btn.BackgroundColor3 = theme.jade
	btn.Font, btn.TextSize, btn.TextColor3 = Enum.Font.GothamBold, 30, theme.white
	btn.Text = Hud.text("result.retry")
	btn.Selectable = true
	btn.Parent = panel
	Hud.round(btn, 16)
	btn.Activated:Connect(function()
		gui:Destroy()
		ready:FireServer()
	end)
	gui.Parent = player:WaitForChild("PlayerGui")
	GuiService.SelectedObject = btn
end

return Hud
