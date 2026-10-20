--!strict
--[[
	Feedback: avisos (toast), tarjeta de captura y banner global de MITICO. Solo presentacion.
	Sin sonido ni particulas todavia (falta arte/sonido: ver README).
]]

local TweenService = game:GetService("TweenService")

local Feedback = {}

local function rgb(triple: { number }): Color3
	return Color3.fromRGB(triple[1], triple[2], triple[3])
end

function Feedback.start(ctx: any): any
	local gui: ScreenGui = ctx.gui
	local UI = ctx.UI
	local balance = ctx.Balance
	local currentCard: any = nil
	local currentBanner: any = nil

	local function toast(text: string)
		UI.toast(gui, text, 3.5)
	end

	local function showCatch(payload: any)
		if currentCard ~= nil then
			currentCard:Destroy()
		end
		local rarityInfo = balance.rarities[payload.rarity]
		local color = UI.theme.colors[payload.rarity] or UI.theme.colors.text
		local card = UI.create("Frame", {
			Name = "CatchCard",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0.12, 0),
			Size = UDim2.new(0.8, 0, 0, 132),
			BackgroundColor3 = rgb(UI.theme.colors.panel),
			BorderSizePixel = 0,
			Parent = gui,
		}, {
			UI.create("UICorner", { CornerRadius = UDim.new(0, 16) }),
			UI.create("UIStroke", { Color = rgb(color), Thickness = 3 }),
			UI.create("UISizeConstraint", { MaxSize = Vector2.new(420, 160) }),
			UI.create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 4),
			}),
		})
		local lines: { { text: string, size: number, color: { number }, order: number } } = {
			{ text = payload.name, size = 26, color = color, order = 1 },
			{ text = rarityInfo.label, size = 18, color = color, order = 2 },
			{
				text = "Valor: " .. UI.formatNumber(payload.value) .. " monedas",
				size = 18,
				color = UI.theme.colors.text,
				order = 3,
			},
		}
		if payload.isNew then
			table.insert(
				lines,
				{ text = "NUEVO en tu bestiario", size = 18, color = UI.theme.colors.positive, order = 4 }
			)
		end
		if payload.stored == false then
			table.insert(lines, {
				text = "Inventario lleno: vendida por " .. UI.formatNumber(payload.autoSoldFor or 0),
				size = 16,
				color = UI.theme.colors.textMuted,
				order = 5,
			})
		end
		for _, line in lines do
			UI.label({
				text = line.text,
				size = UDim2.new(1, 0, 0, line.size + 6),
				textSize = line.size,
				bold = line.order == 1,
				alignX = Enum.TextXAlignment.Center,
				parent = card,
				layoutOrder = line.order,
			}).TextColor3 =
				rgb(line.color)
		end
		currentCard = card
		card.Position = UDim2.new(0.5, 0, 0, -160)
		TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.12, 0),
		}):Play()
		task.delay(3, function()
			if currentCard == card then
				card:Destroy()
				currentCard = nil
			end
		end)
	end

	local function showBanner(payload: any)
		if currentBanner ~= nil then
			currentBanner:Destroy()
		end
		local banner = UI.create("TextLabel", {
			Name = "MythicBanner",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, -80),
			Size = UDim2.new(0.92, 0, 0, 56),
			BackgroundColor3 = rgb(UI.theme.colors.panel),
			TextColor3 = rgb(UI.theme.colors.Mythic),
			TextSize = 20,
			TextWrapped = true,
			Font = Enum.Font.GothamBold,
			Text = ctx.ClientLogic.bannerText(payload),
			Parent = gui,
		}, {
			UI.create("UICorner", { CornerRadius = UDim.new(0, 14) }),
			UI.create("UIStroke", { Color = rgb(UI.theme.colors.Mythic), Thickness = 2 }),
			UI.create("UISizeConstraint", { MaxSize = Vector2.new(640, 90) }),
		})
		currentBanner = banner
		TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0, 8),
		}):Play()
		task.delay(balance.mythicBanner.displaySeconds, function()
			if currentBanner == banner then
				banner:Destroy()
				currentBanner = nil
			end
		end)
	end

	return { toast = toast, showCatch = showCatch, showBanner = showBanner }
end

return Feedback
