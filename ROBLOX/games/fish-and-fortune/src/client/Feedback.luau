--!strict
--[[
	Feedback: avisos (toast), tarjeta de captura y banner global de MITICO. Solo presentacion.
	Textos por clave (ctx.L): el banner y los avisos llegan ya traducidos al idioma del jugador desde Main (que valida los
	mensajes del servidor); la tarjeta de captura se arma aqui con el id de la criatura.
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
	local L = ctx.L
	local fmt = ctx.fmt
	local currentCard: any = nil
	local currentBanner: any = nil
	local activeParticles = 0

	local function sparkle(parent: any)
		local count = math.min(12, 20 - activeParticles)
		for index = 1, count do
			activeParticles += 1
			local origin = parent.AbsolutePosition + parent.AbsoluteSize / 2
			local particle = UI.create("Frame", {
				Name = "CatchSparkle",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(origin.X + math.random(-120, 120), origin.Y + math.random(-18, 18)),
				Size = UDim2.fromOffset(math.random(5, 9), math.random(5, 9)),
				BackgroundColor3 = rgb(UI.theme.colors.gold),
				BackgroundTransparency = 0.1,
				BorderSizePixel = 0,
				ZIndex = 5,
				Parent = gui,
			}, { UI.create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
			local drift = (index % 2 == 0) and 1 or -1
			TweenService:Create(particle, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = particle.Position + UDim2.fromOffset(drift * math.random(12, 28), -math.random(10, 24)),
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(2, 2),
			}):Play()
			task.delay(0.36, function()
				if particle.Parent ~= nil then
					particle:Destroy()
				end
				activeParticles = math.max(0, activeParticles - 1)
			end)
		end
	end

	local function toast(text: string)
		local notice = UI.toast(gui, text, 3.5)
		notice.TextTransparency = 1
		notice.BackgroundTransparency = 1
		TweenService:Create(notice, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 0,
			BackgroundTransparency = 0.08,
		}):Play()
	end

	local function showCatch(payload: any)
		if currentCard ~= nil then
			currentCard:Destroy()
		end
		-- Solo criaturas y rarezas que existen en el balance (el servidor es de confianza, pero un dato raro no debe romper la UI).
		if balance.rarities[payload.rarity] == nil or ctx.rules:creature(payload.id) == nil then
			return
		end
		local color = UI.theme.colors[payload.rarity] or UI.theme.colors.text
		local card = UI.create("Frame", {
			Name = "CatchCard",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0.12, 0),
			Size = UDim2.new(0.86, 0, 0, 154),
			BackgroundColor3 = rgb(UI.theme.colors.panel),
			BorderSizePixel = 0,
			Parent = gui,
		}, {
			UI.create("UICorner", { CornerRadius = UDim.new(0, 12) }),
			UI.create("UIGradient", {
				Color = ColorSequence.new(rgb(UI.theme.colors.panel), Color3.fromRGB(18, 26, 42)),
				Rotation = 90,
			}),
			UI.create("UIStroke", {
				Color = rgb(color),
				Thickness = 2,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			UI.create("UISizeConstraint", { MaxSize = Vector2.new(420, 160) }),
			UI.create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 4),
			}),
		})
		local lines: { { text: string, size: number, color: { number }, order: number } } = {
			{ text = "✦  " .. L("creature." .. payload.id) .. "  ✦", size = 28, color = color, order = 1 },
			{ text = L("rarity." .. payload.rarity), size = 20, color = color, order = 2 },
			{
				text = L("catch.value", { amount = fmt.compact(payload.value) }),
				size = 18,
				color = UI.theme.colors.text,
				order = 3,
			},
		}
		if payload.isNew then
			table.insert(lines, { text = L("catch.new"), size = 18, color = UI.theme.colors.positive, order = 4 })
		end
		if payload.stored == false then
			table.insert(lines, {
				text = L("catch.autosold", { amount = fmt.compact(payload.autoSoldFor or 0) }),
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
		if
			payload.rarity == "Rare"
			or payload.rarity == "Epic"
			or payload.rarity == "Legendary"
			or payload.rarity == "Mythic"
		then
			card.BackgroundColor3 = rgb(UI.theme.colors.gold)
			TweenService:Create(card, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = rgb(UI.theme.colors.panel),
			}):Play()
			sparkle(card)
		end
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

	local function showBanner(text: string)
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
			Text = text,
			Parent = gui,
		}, {
			UI.create("UICorner", { CornerRadius = UDim.new(0, 12) }),
			UI.create("UIStroke", {
				Color = rgb(UI.theme.colors.Mythic),
				Thickness = 2,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
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
