--!strict
-- SkillCards: 3 tarjetas centradas al llegar SkillOffer; pulsar una dispara SkillPick(indice 1..3), nada mas.
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hud = require(script.Parent:WaitForChild("Hud"))
local Skills = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Skills"))

local theme = Hud.theme
local rarityColor: { [string]: Color3 } = { common = theme.jade, rare = theme.turquoise, epic = theme.violet }

local SkillCards = {}

type Parts = { stroke: UIStroke, icon: TextLabel, name: TextLabel, desc: TextLabel, rarity: TextLabel }

function SkillCards.start(offer: RemoteEvent, pick: RemoteEvent)
	local gui = Hud.makeGui("SkillCards", 5)
	gui.Enabled = false
	local title = Hud.label(gui, Hud.text("skill.title"), 40, theme.yellow)
	title.AnchorPoint, title.Position, title.Size =
		Vector2.new(0.5, 0.5), UDim2.new(0.5, 0, 0.5, -190), UDim2.fromOffset(600, 50)
	local row = Instance.new("Frame")
	row.AnchorPoint, row.Position, row.Size =
		Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(720, 300)
	row.BackgroundTransparency = 1
	row.Parent = gui
	local list = Instance.new("UIListLayout")
	list.FillDirection, list.Padding = Enum.FillDirection.Horizontal, UDim.new(0, 16)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = row

	local cards: { TextButton } = {}
	local parts: { Parts } = {}
	for i = 1, 3 do
		local card = Instance.new("TextButton")
		card.Name = `Card{i}`
		card.Size = UDim2.fromOffset(224, 300) -- con UIScale 0.7 sigue en 157 x 210 px (>= 56)
		card.BackgroundColor3 = theme.night
		card.Text = ""
		card.Selectable = true
		card.LayoutOrder = i
		card.Parent = row
		Hud.round(card, 20, theme.jade)
		-- ponytail: icono = marco de color con la inicial; el arte de Ropilot llega luego (entrega-ropilot/).
		local icon = Hud.label(card, "", 56)
		icon.Size, icon.Position = UDim2.fromOffset(96, 96), UDim2.fromOffset(64, 16)
		icon.BackgroundTransparency = 0
		icon.BackgroundColor3 = theme.jade
		Hud.round(icon, 24)
		local name = Hud.label(card, "", 24)
		name.Size, name.Position = UDim2.new(1, -16, 0, 56), UDim2.fromOffset(8, 124)
		local desc = Hud.label(card, "", 20)
		desc.Size, desc.Position = UDim2.new(1, -24, 0, 70), UDim2.fromOffset(12, 184)
		desc.TextColor3 = Color3.fromHex("DDE6F0")
		local rarity = Hud.label(card, "", 18)
		rarity.Size, rarity.Position = UDim2.new(1, 0, 0, 28), UDim2.fromOffset(0, 262)
		cards[i] = card
		parts[i] = {
			stroke = card:FindFirstChildOfClass("UIStroke") :: UIStroke,
			icon = icon,
			name = name,
			desc = desc,
			rarity = rarity,
		}
		card.Activated:Connect(function()
			if gui.Enabled then
				gui.Enabled = false
				GuiService.SelectedObject = nil
				pick:FireServer(i)
			end
		end)
	end

	offer.OnClientEvent:Connect(function(ids: any)
		if type(ids) ~= "table" then
			return
		end
		for i = 1, 3 do
			local id = (ids :: { any })[i]
			local skill = if type(id) == "string" then Skills.get(id) else nil
			cards[i].Visible = skill ~= nil
			if skill then
				local color = rarityColor[skill.rarity] or theme.jade
				local p = parts[i]
				p.stroke.Color = color
				p.icon.BackgroundColor3 = color
				p.icon.Text = string.sub(Hud.text(`{skill.id}.name`), 1, 1)
				p.name.Text = Hud.text(`{skill.id}.name`)
				p.desc.Text = Hud.text(`{skill.id}.desc`)
				p.rarity.Text = Hud.text(`rarity.{skill.rarity}`)
				p.rarity.TextColor3 = color
			end
		end
		gui.Enabled = true
		GuiService.SelectedObject = cards[1]
	end)
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

return SkillCards
