--!strict
-- Iconos 3D del HUD (renders de Ropilot, assets/ui-icons/). rbxasset:// = copia local en la carpeta de Studio de este PC:
-- solo se ven aqui. Antes de publicar, subirlos (con permiso de Aryan) y poner aqui los rbxassetid://.
local LOCAL = "rbxasset://textures/fishfortune/"
local icons: { [string]: string } = {}
for _, name in { "Coin", "Pearl", "Bag", "Shop", "Rods", "Bestiary", "Season", "Odds", "Codes", "Settings", "Cast", "Sell" } do
	icons[name] = LOCAL .. name .. ".png"
end
return icons
