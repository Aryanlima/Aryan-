-- Para ejecutar en el Edit de Studio (execute_luau) DESPUES de WorldBuilder.build: coloca clones de Workspace.Extras.Kit sobre el
-- suelo real (raycast), evitando agua, muelle y zona de aparicion. Resultado en Workspace.Extras.Scatter (luego save-extras.sh).
local ws = workspace
local extras = ws.Extras
local kit = extras.Kit
local old = extras:FindFirstChild("Scatter")
if old then old:Destroy() end
local out = Instance.new("Folder") out.Name = "Scatter" out.Parent = extras
local rng = Random.new(2026)
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { ws.Terrain }

-- zona: origen x, caja de busqueda y zonas prohibidas
local ZONES = {
	lake = { ox = 0, x = { -150, 150 }, z = { -170, 70 }, spawn = Vector3.new(0, 0, 12), pier = { -16, 16, -52, 22 } },
	river = { ox = 414, x = { 330, 500 }, z = { -170, 70 }, spawn = Vector3.new(414, 0, 12), pier = { 398, 430, -52, 22 } },
	coast = { ox = 815, x = { 720, 910 }, z = { -170, 110 }, spawn = Vector3.new(815, 0, 12), pier = { 799, 831, -52, 22 } },
}
local PLAN = {
	lake = { Kit_Palm = 9, Kit_RoundTree = 14, Kit_Pine = 8, Kit_Rocks = 9 },
	river = { Kit_Pine = 16, Kit_RoundTree = 8, Kit_Rocks = 9, Kit_Crystals = 3 },
	coast = { Kit_Palm = 16, Kit_Rocks = 7, Kit_Rowboat = 2 },
}
local SCALE = { Kit_Palm = { 0.5, 0.75 }, Kit_RoundTree = { 0.42, 0.7 }, Kit_Pine = { 0.45, 0.8 }, Kit_Rocks = { 0.5, 1.0 }, Kit_Crystals = { 0.45, 0.7 }, Kit_Rowboat = { 0.55, 0.7 } } -- el kit se importo grande: factor ~0,5

local function ground(x, z)
	local hit = ws:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -800, 0), params)
	if hit and hit.Material ~= Enum.Material.Water then
		return hit.Position.Y
	end
	return nil
end

local placed = {}
local function farFromOthers(p, minDist)
	for _, q in placed do
		if (p - q).Magnitude < minDist then
			return false
		end
	end
	return true
end

local report = {}
for zone, plan in PLAN do
	local Z = ZONES[zone]
	for name, count in plan do
		local template = kit:FindFirstChild(name)
		local made = 0
		local tries = 0
		while made < count and tries < count * 80 do
			tries += 1
			local x = rng:NextNumber(Z.x[1], Z.x[2])
			local z = rng:NextNumber(Z.z[1], Z.z[2])
			local inPier = x > Z.pier[1] - 6 and x < Z.pier[2] + 6 and z > Z.pier[3] - 6 and z < Z.pier[4] + 10
			local y = not inPier and (Vector3.new(x, 0, z) - Z.spawn).Magnitude > 48 and not (math.abs(x - Z.spawn.X) < 55 and z > -14) and ground(x, z) or nil
			local flat = false
			if y and y > 1.2 and y < 16 then -- sin cimas de montana (los arboles flotarian vistos desde abajo)
				-- evita laderas muy empinadas: el suelo cercano no debe diferir mucho
				local y2, y3 = ground(x + 5, z), ground(x, z + 5)
				flat = y2 ~= nil and y3 ~= nil and math.abs(y2 - y) < 3.5 and math.abs(y3 - y) < 3.5
			end
			if flat and farFromOthers(Vector3.new(x, y, z), name == "Kit_Rocks" and 14 or 11) then
				local clone = template:Clone()
				clone.Name = zone .. "_" .. name:gsub("^Kit_", "") .. made -- unico en todo el arbol (ProjectStructure.spec)
				local s = rng:NextNumber(SCALE[name][1], SCALE[name][2])
				clone:ScaleTo(s)
				local bbcf, bbsize = clone:GetBoundingBox()
				local pivot = clone:GetPivot()
				local toBottom = pivot.Position.Y - (bbcf.Position.Y - bbsize.Y / 2)
				clone:PivotTo(CFrame.new(x, y + toBottom - 0.5, z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
				clone.Parent = out
				table.insert(placed, Vector3.new(x, y, z))
				made += 1
			end
		end
		table.insert(report, zone .. "/" .. name .. "=" .. made .. "/" .. count)
	end
end
return table.concat(report, " ")
