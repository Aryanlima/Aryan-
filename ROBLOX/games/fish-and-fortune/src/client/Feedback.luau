--!strict
--[[
	Feedback: avisos (toast), tarjeta de captura y banner global de MITICO. Solo presentacion.
	Textos por clave (ctx.L): el banner y los avisos llegan ya traducidos al idioma del jugador desde Main (que valida los
	mensajes del servidor); la tarjeta de captura se arma aqui con el id de la criatura.
	Estilo "Muelle de madera". Escalera de jugo por rareza: Common sin extras; Uncommon/Rare destellos; Epic+ aro de luz
	que gira; Legendary/Mythic ademas destello blanco, sacudida de camara y barrido del banner. El sonido lo pone Main (Audio).
]]

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Feedback = {}

local function rgb(triple: { number }): Color3
	return Color3.fromRGB(triple[1], triple[2], triple[3])
end

-- 0 = nada, 1 = destellos, 2 = aro de luz, 3 = destello de pantalla + sacudida
local TIER: { [string]: number } = { Common = 0, Uncommon = 1, Rare = 1, Epic = 2, Legendary = 3, Mythic = 3 }

function Feedback.start(ctx: any): any
	local gui: ScreenGui = ctx.gui
	local UI = ctx.UI
	local balance = ctx.Balance
	local L = ctx.L
	local fmt = ctx.fmt
	local currentCard: any = nil
	local currentBanner: any = nil
	local activeParticles = 0
	local shaking = false

	local function fieldOfView(): any
		local ok, camera = pcall(function()
			return Workspace.CurrentCamera
		end)
		return if ok then camera else nil
	end

	-- Sacudida breve de camara por campo de vision (no choca con el script de camara). Nada con movimiento reducido.
	local function cameraShake(amount: number)
		local camera = fieldOfView()
		if camera == nil or UI.motion.reduced or shaking then
			return
		end
		shaking = true
		local base = camera.FieldOfView
		for index, delta in { -amount, amount * 0.6, -amount * 0.4, 0 } do
			task.delay((index - 1) * 0.07, function()
				UI.motion.tween(camera, { FieldOfView = base + delta }, 0.07)
				if delta == 0 then
					shaking = false
				end
			end)
		end
	end

	local function screenFlash(transparency: number)
		if UI.motion.reduced then
			return
		end
		local frame = UI.create("Frame", {
			Name = "CatchFlash",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = transparency,
			BorderSizePixel = 0,
			Active = false,
			ZIndex = 8,
			Parent = gui,
		})
		UI.motion.tween(frame, { BackgroundTransparency = 1 }, 0.5)
		task.delay(0.6, function()
			frame:Destroy()
		end)
	end

	local function sparkle(parent: any, wanted: number)
		if parent.AbsoluteSize == nil or parent.AbsolutePosition == nil or UI.motion.reduced then
			return -- sin medidas de pantalla (pruebas) o movimiento reducido: sin destellos
		end
		local count = math.min(wanted, 20 - activeParticles)
		local image = UI.theme.icons.Sparkle
		local origin = parent.AbsolutePosition + parent.AbsoluteSize / 2
		local spread = parent.AbsoluteSize.X / 2
		for index = 1, count do
			activeParticles += 1
			local size = math.random(10, 20)
			local particle = UI.create("ImageLabel", {
				Name = "CatchSparkle",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(
					origin.X + math.random(-spread, spread),
					origin.Y + math.random(-parent.AbsoluteSize.Y / 2, parent.AbsoluteSize.Y / 2)
				),
				Size = UDim2.fromOffset(size, size),
				Image = image or "",
				ImageColor3 = rgb(UI.theme.colors.gold),
				BackgroundColor3 = rgb(UI.theme.colors.gold),
				BackgroundTransparency = if image then 1 else 0.1,
				BorderSizePixel = 0,
				ZIndex = 9,
				Parent = gui,
			}, if image then nil else { UI.create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
			local drift = (index % 2 == 0) and 1 or -1
			TweenService:Create(particle, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = particle.Position + UDim2.fromOffset(drift * math.random(12, 28), -math.random(14, 34)),
				ImageTransparency = 1,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(2, 2),
			}):Play()
			task.delay(0.52, function()
				if particle.Parent ~= nil then
					particle:Destroy()
				end
				activeParticles = math.max(0, activeParticles - 1)
			end)
		end
	end

	-- El aviso sigue siendo un TextLabel que se destruye solo (UI.toast); aqui sube desde abajo con fundido.
	local function toast(text: string)
		local notice = UI.toast(gui, text, 3.5)
		notice.TextTransparency = 1
		notice.BackgroundTransparency = 1
		TweenService:Create(notice, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 0,
			BackgroundTransparency = 0.08,
		}):Play()
		UI.motion.slideIn(notice, 0, 30, 0.25)
	end

	local function showCatch(payload: any)
		if currentCard ~= nil then
			currentCard:Destroy()
		end
		-- Solo criaturas y rarezas que existen en el balance (el servidor es de confianza, pero un dato raro no debe romper la UI).
		if balance.rarities[payload.rarity] == nil or ctx.rules:creature(payload.id) == nil then
			return
		end
		local tier = TIER[payload.rarity] or 0
		local color = UI.theme.colors[payload.rarity] or UI.theme.colors.text
		local home = UDim2.new(0.5, 0, 0.12, 0)
		-- Contenedor transparente (CatchCard): aro de luz detras y tabla de madera delante.
		local card = UI.create("Frame", {
			Name = "CatchCard",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, -190),
			Size = UDim2.new(0.86, 0, 0, 160),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = gui,
		}, {
			UI.create("UISizeConstraint", { MaxSize = Vector2.new(420, 400) }),
		})
		if tier >= 2 then
			local ring = UI.create("Frame", {
				Name = "LightRing",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, 28, 1, 28),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.25,
				BorderSizePixel = 0,
				ZIndex = 1,
				Parent = card,
			}, {
				UI.create("UICorner", { CornerRadius = UDim.new(0, 26) }),
			})
			local gradient = UI.create("UIGradient", {
				Color = ColorSequence.new(rgb(color), Color3.new(1, 1, 1)),
				Rotation = 0,
				Parent = ring,
			})
			UI.motion.tween(gradient, { Rotation = 360 }, 2, "Linear", "Out", -1)
		end
		local body = UI.create("Frame", {
			Name = "CatchBody",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = rgb(UI.theme.colors.woodGrain),
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = card,
		}, {
			UI.create("UICorner", { CornerRadius = UDim.new(0, 18) }),
			UI.create("UIStroke", {
				Color = rgb(UI.theme.colors.woodDark),
				Thickness = 4,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			UI.create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 2),
			}),
			UI.create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) }),
		})
		local lines: { { text: string, size: number, color: { number }, order: number, display: boolean } } = {
			{ text = L("creature." .. payload.id), size = 30, color = color, order = 1, display = true },
			{ text = L("rarity." .. payload.rarity), size = 20, color = color, order = 2, display = true },
			{
				text = L("catch.kg", { kg = payload.kg }),
				size = 18,
				color = UI.theme.colors.text,
				order = 2,
				display = false,
			},
			{
				text = L("catch.value", { amount = fmt.compact(payload.value) }),
				size = 18,
				color = UI.theme.colors.text,
				order = 3,
				display = false,
			},
		}
		if balance.rarities[payload.rarity].order >= balance.rarities.Rare.order then
			table.insert(lines, {
				text = L("catch.one_in", { n = fmt.number(payload.oneIn) }),
				size = 18,
				color = UI.theme.colors.text,
				order = 4,
				display = true,
			})
		end
		if payload.stored == false then
			table.insert(lines, {
				text = L("catch.autosold", { amount = fmt.compact(payload.autoSoldFor or 0) }),
				size = 16,
				color = UI.theme.colors.textMuted,
				order = 5,
				display = false,
			})
		end
		local newTag: any = nil
		for _, line in lines do
			UI.label({
				text = line.text,
				size = UDim2.new(1, -16, 0, line.size + 6),
				textSize = line.size,
				display = line.display,
				bold = line.order == 1,
				alignX = Enum.TextXAlignment.Center,
				parent = body,
				layoutOrder = line.order,
			}).TextColor3 =
				rgb(line.color)
		end
		if payload.isNew then
			newTag = UI.label({
				text = L("catch.new"),
				size = UDim2.new(1, -16, 0, 26),
				textSize = 18,
				display = true,
				alignX = Enum.TextXAlignment.Center,
				parent = body,
				layoutOrder = 4,
			})
			newTag.TextColor3 = rgb(UI.theme.colors.positive)
		end
		currentCard = card

		-- Cae con Back y un giro que se pasa un poco y se asienta.
		card.Rotation = -5
		UI.motion.tween(card, { Position = home, Rotation = 0 }, 0.4, "Back")
		if newTag ~= nil then
			task.delay(0.35, function()
				if newTag.Parent ~= nil then
					UI.motion.pop(newTag, 1.3)
					UI.motion.tween(newTag, { Rotation = -6 }, 0.2, "Back")
				end
			end)
		end
		if tier >= 1 then
			task.delay(0.3, function()
				if currentCard == card then
					UI.motion.pop(card, 1.05)
					sparkle(card, if tier == 1 then 8 else 14)
				end
			end)
		end
		if tier >= 3 then
			screenFlash(0.35)
			cameraShake(6)
		end
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
			BackgroundColor3 = rgb(UI.theme.colors.woodGrain),
			TextColor3 = rgb(UI.theme.colors.Mythic),
			TextStrokeColor3 = rgb(UI.theme.colors.ink),
			TextStrokeTransparency = 0,
			TextSize = 22,
			TextWrapped = true,
			Font = (Enum.Font :: any)[UI.theme.fonts.display],
			Text = text,
			ClipsDescendants = true,
			Parent = gui,
		}, {
			UI.create("UICorner", { CornerRadius = UDim.new(0, 14) }),
			UI.create("UIStroke", {
				Color = rgb(UI.theme.colors.woodDark),
				Thickness = 4,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			UI.create("UISizeConstraint", { MaxSize = Vector2.new(640, 90) }),
		})
		currentBanner = banner
		UI.motion.tween(banner, { Position = UDim2.new(0.5, 0, 0, 8) }, 0.4, "Back")
		if not UI.motion.reduced then
			-- Barrido de luz que cruza el cartel
			local sweep = UI.create("Frame", {
				Name = "Sweep",
				Position = UDim2.new(-0.3, 0, 0, 0),
				Size = UDim2.new(0.25, 0, 1, 0),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.6,
				BorderSizePixel = 0,
				Rotation = 12,
				Active = false,
				Parent = banner,
			})
			task.delay(0.4, function()
				if sweep.Parent ~= nil then
					UI.motion.tween(sweep, { Position = UDim2.new(1.1, 0, 0, 0) }, 1.2, "Quad", "InOut")
				end
			end)
		end
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
