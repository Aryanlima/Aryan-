--!strict
--[[
	Cosmeticos de pase (tarea 002): SOLO aspecto, visible para todos (se crea en el servidor y se replica).
	No tocan suerte, monedas ni velocidad: GameLogic no lee estos pases (comprobado en tests/Cosmetics.spec.luau).
]]

local Cosmetics = {}

function Cosmetics.colorRod(rod: Instance, color: { number })
	local value = Color3.fromRGB(color[1], color[2], color[3])
	if rod:IsA("BasePart") then
		rod.Color = value
	end
	for _, part in rod:GetDescendants() do
		if part:IsA("BasePart") then
			part.Color = value
		end
	end
end

Cosmetics.GOLD = Color3.fromRGB(255, 200, 61)
Cosmetics.TRAIL_NAME = "BubbleTrail"

local function partsOf(root: Instance): { BasePart }
	local parts: { BasePart } = {}
	if root:IsA("BasePart") then
		table.insert(parts, root)
	end
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end
	return parts
end

-- Cana Dorada: tine la cana (procedural o de arte) y le pone un brillo de chispas doradas.
function Cosmetics.goldenRod(rod: Instance)
	local parts = partsOf(rod)
	for _, part in parts do
		part.Color = Cosmetics.GOLD
		part.Material = Enum.Material.Neon
	end
	local first: BasePart? = parts[1]
	if first == nil or first:FindFirstChild("GoldSparkles") ~= nil then
		return
	end
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "GoldSparkles"
	sparkles.Color = ColorSequence.new(Cosmetics.GOLD)
	sparkles.LightEmission = 1
	sparkles.Rate = 6
	sparkles.Lifetime = NumberRange.new(0.6, 1)
	sparkles.Speed = NumberRange.new(0.5, 1)
	sparkles.Size = NumberSequence.new(0.15, 0)
	sparkles.Parent = first
end

-- Estela de Burbujas: Trail entre dos Attachments del HumanoidRootPart; `enabled = false` la quita.
function Cosmetics.bubbleTrail(character: Model, enabled: boolean)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return
	end
	for _, name in
		{
			Cosmetics.TRAIL_NAME,
			Cosmetics.TRAIL_NAME .. "Top",
			Cosmetics.TRAIL_NAME .. "Bottom",
			Cosmetics.TRAIL_NAME .. "Bubbles",
		}
	do
		local old = root:FindFirstChild(name)
		if old ~= nil then
			old:Destroy()
		end
	end
	if not enabled then
		return
	end
	local top = Instance.new("Attachment")
	top.Name = Cosmetics.TRAIL_NAME .. "Top"
	top.Position = Vector3.new(0, 0.8, 0)
	top.Parent = root
	local bottom = Instance.new("Attachment")
	bottom.Name = Cosmetics.TRAIL_NAME .. "Bottom"
	bottom.Position = Vector3.new(0, -0.8, 0)
	bottom.Parent = root
	local trail = Instance.new("Trail")
	trail.Name = Cosmetics.TRAIL_NAME
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Lifetime = 0.6
	trail.LightEmission = 0.5
	trail.FaceCamera = true
	trail.Color = ColorSequence.new(Color3.fromRGB(46, 196, 241), Color3.fromRGB(255, 255, 255))
	trail.Transparency = NumberSequence.new(0.3, 1)
	trail.Parent = root
	-- Burbujas que suben (revision de Codex: el Trail solo es una cinta). Textura por defecto del motor;
	-- PENDIENTE: subir una textura de burbuja propia y ponerla en `Texture` (no se inventan IDs de assets).
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Name = Cosmetics.TRAIL_NAME .. "Bubbles"
	bubbles.Color = ColorSequence.new(Color3.fromRGB(190, 236, 255))
	bubbles.LightEmission = 0.4
	bubbles.Rate = 8
	bubbles.Lifetime = NumberRange.new(0.8, 1.4)
	bubbles.Speed = NumberRange.new(0.5, 1.5)
	bubbles.Acceleration = Vector3.new(0, 3, 0)
	bubbles.SpreadAngle = Vector2.new(25, 25)
	bubbles.Size = NumberSequence.new(0.25, 0.4)
	bubbles.Transparency = NumberSequence.new(0.2, 1)
	bubbles.Parent = bottom
end

return Cosmetics
