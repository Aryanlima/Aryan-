--!strict
-- Animaciones de Nara (rig R15 de Ropilot, 24 cuadros, 0,958 s), subidas a la cuenta de Aryan el 24-oct.
-- Origen: assets/source/blender-nara.py + blender-nara-anim.py. Idle y Run van en bucle.
local ids: { [string]: number } = {
	Idle = 101221934254841, -- prioridad Idle, bucle
	Run = 95772669651080, -- prioridad Movement, bucle
	Shoot = 89743821336567, -- prioridad Action
	Hit = 84549462740269, -- prioridad Action2
	Die = 130776400122816, -- prioridad Action3
	Celebrate = 70710874826050, -- prioridad Action4
}
local out: { [string]: string } = {}
for name, id in ids do
	out[name] = "rbxassetid://" .. id
end
return out
