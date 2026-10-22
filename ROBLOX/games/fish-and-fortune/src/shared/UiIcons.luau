--!strict
-- Iconos 3D del HUD (renders de Ropilot, assets/ui-icons/). rbxasset:// = copia local en la carpeta de Studio de este PC:
-- solo se ven aqui. Antes de publicar, subirlos (con permiso de Aryan) y poner aqui los rbxassetid://.
local LOCAL = "rbxasset://textures/fishfortune/"
local icons: { [string]: string } = {}
for _, name in { "Coin", "Pearl", "Bag", "Shop", "Rods", "Bestiary", "Season", "Odds", "Codes", "Settings", "Cast", "Sell" } do
	icons[name] = LOCAL .. name .. ".png"
end
-- Texturas de efectos (Ropilot): Splash es un flipbook 4x4 de una pasada (FlipbookLayout Grid4x4, FlipbookMode OneShot, Lifetime 0.67).
icons.Sparkle = LOCAL .. "ff_sparkle.png"
icons.Bubble = LOCAL .. "ff_bubble.png"
icons.Splash = LOCAL .. "ff_splash.flipbook.png"
return icons
