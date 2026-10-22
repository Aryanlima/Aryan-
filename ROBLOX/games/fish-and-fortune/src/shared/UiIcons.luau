--!strict
-- Iconos 3D del HUD y texturas de efectos (renders de Ropilot, assets/ui-icons/ y assets/vfx/), subidos a la cuenta de Aryan el 22-oct.
-- Splash es un flipbook 4x4 de una pasada (FlipbookLayout Grid4x4, FlipbookMode OneShot, Lifetime 0.67).
local ids: { [string]: number } = {
	Coin = 123017725079956,
	Pearl = 90103049172246,
	Bag = 123597865110344,
	Shop = 136549961107129,
	Rods = 76446740978093,
	Bestiary = 88978301575111,
	Season = 103582046386134,
	Odds = 140684582740769,
	Codes = 130139248157796,
	Settings = 111176383964892,
	Cast = 119685550858824,
	Sell = 139413273930745,
	Sparkle = 96957545744302,
	Bubble = 129925549749096,
	Splash = 90949931605332,
}
local icons: { [string]: string } = {}
for name, id in ids do
	icons[name] = "rbxassetid://" .. id
end
return icons
