--!nonstrict
--[[
	engine: carga modulos Luau que usan los tipos de datos del motor de Roblox (Instance, Vector3, CFrame, Enum, Color3...)
	dentro de Lune, que no los trae como globales. Usa la libreria `@lune/roblox` (instancias reales de la base de reflexion:
	`Instance.new("MeshPart")`, `:Clone()`, `:GetDescendants()`, atributos...). Lo que Lune NO implementa (Model:PivotTo,
	Model:GetBoundingBox, Model:ScaleTo, Part.Position...) hay que no usarlo en el codigo bajo prueba o inyectarlo.

	  local Engine = require("@testkit/engine")
	  local Art = Engine.load(PACKAGES .. "Art.luau")                     -- modulo con los globales del motor
	  local Thing = Engine.load(path, { task = Mocks.new().task })         -- globales extra o sustituidos

	  Engine.roblox   la libreria @lune/roblox (Instance, Vector3, CFrame, serializeModel...)

	`warn` y `print` son mudos salvo que se pasen en `extra`. Cada llamada a `load` evalua el archivo de nuevo (estado limpio).
]]
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox") :: any

local DATATYPES = {
	"Instance",
	"Enum",
	"Vector3",
	"Vector2",
	"Color3",
	"CFrame",
	"UDim",
	"UDim2",
	"Rect",
	"Font",
	"ColorSequence",
	"NumberSequence",
	"NumberRange",
}

local Engine = {}

Engine.roblox = roblox

function Engine.environment(extra: { [string]: any }?): { [string]: any }
	local sandbox = table.clone((getfenv :: any)(0))
	for _, name in DATATYPES do
		if roblox[name] ~= nil then
			sandbox[name] = roblox[name]
		end
	end
	sandbox.warn = function() end
	sandbox.print = function() end
	if extra ~= nil then
		for key, value in extra do
			sandbox[key] = value
		end
	end
	return sandbox
end

function Engine.load(path: string, extra: { [string]: any }?): any
	local source = fs.readFile(path)
	local chunk = luau.load(source, { environment = Engine.environment(extra), debugName = path })
	return chunk()
end

return Engine
