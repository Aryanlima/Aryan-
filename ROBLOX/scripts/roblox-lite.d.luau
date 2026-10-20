-- Definiciones MINIMAS y permisivas de la API de Roblox, solo para `typecheck.mjs`.
--
-- Por que no se usa globalTypes.d.luau (luau-lsp): el analizador WASM (Luau 0.739) aborta con
-- "Code is too complex to typecheck" al cargar esas ~870 KB. Estas definiciones declaran solo lo que
-- usa este repo; los miembros no listados caen en `[string]: any`. NO sustituyen a luau-lsp en Studio.

declare extern type Instance with
	Name: string
	ClassName: string
	Parent: Instance?
	[string]: any
end

declare extern type Player extends Instance with
	UserId: number
	DisplayName: string
	AccountAge: number
	Character: Instance?
	function Kick(self, message: string?): ()
end

declare extern type RBXScriptConnection with
	Connected: boolean
	function Disconnect(self): ()
end

declare extern type RBXScriptSignal with
	function Connect(self, callback: (...any) -> ()): RBXScriptConnection
	function Once(self, callback: (...any) -> ()): RBXScriptConnection
	function Wait(self): ...any
end

declare extern type RemoteEvent extends Instance with
	OnServerEvent: RBXScriptSignal
	OnClientEvent: RBXScriptSignal
	function FireServer(self, ...: any): ()
	function FireClient(self, player: Player, ...: any): ()
	function FireAllClients(self, ...: any): ()
end

declare extern type RemoteFunction extends Instance with
	OnServerInvoke: ((player: Player, ...any) -> ...any)?
	function InvokeServer(self, ...: any): ...any
end

declare extern type GuiObject extends Instance with
	[string]: any
end

declare extern type Frame extends GuiObject with end
declare extern type TextLabel extends GuiObject with end
declare extern type TextButton extends GuiObject with
	Activated: RBXScriptSignal
end
declare extern type ImageLabel extends GuiObject with end
declare extern type ScrollingFrame extends GuiObject with end
declare extern type ScreenGui extends Instance with end
declare extern type Folder extends Instance with end
declare extern type Model extends Instance with end
declare extern type BasePart extends Instance with end
declare extern type Part extends BasePart with end
declare extern type Tween extends Instance with
	Completed: RBXScriptSignal
	function Play(self): ()
	function Cancel(self): ()
end

declare extern type UDim2 with
	X: any
	Y: any
	[string]: any
end
declare extern type UDim with
	[string]: any
end
declare extern type Vector2 with
	X: number
	Y: number
	[string]: any
end
declare extern type Vector3 with
	X: number
	Y: number
	Z: number
	Magnitude: number
	[string]: any
end
declare extern type CFrame with
	Position: Vector3
	[string]: any
end
declare extern type Color3 with
	R: number
	G: number
	B: number
	[string]: any
end
declare extern type TweenInfo with
	[string]: any
end
declare extern type Random with
	function NextNumber(self, min: number?, max: number?): number
	function NextInteger(self, min: number, max: number): number
end
declare extern type InputObject with
	[string]: any
end

declare UDim2: {
	new: (...any) -> UDim2,
	fromScale: (number, number) -> UDim2,
	fromOffset: (number, number) -> UDim2,
}
declare UDim: { new: (number, number) -> UDim }
declare Vector2: { new: (number?, number?) -> Vector2 }
declare Vector3: { new: (number?, number?, number?) -> Vector3, zero: Vector3, one: Vector3 }
declare CFrame: { new: (...any) -> CFrame, Angles: (number, number, number) -> CFrame, lookAt: (Vector3, Vector3) -> CFrame }
declare Color3: {
	new: (number?, number?, number?) -> Color3,
	fromRGB: (number, number, number) -> Color3,
	fromHSV: (number, number, number) -> Color3,
}
declare TweenInfo: { new: (...any) -> TweenInfo }
declare Random: { new: (number?) -> Random }
declare Instance: { new: (string) -> any }
declare Enum: any
declare game: any
declare workspace: any
declare script: any
declare shared: any
declare function typeof(value: any): string
declare function warn(...: any): ()
declare function tick(): number
declare function time(): number
declare function require(module: any): any
declare task: {
	wait: (number?) -> number,
	spawn: (any, ...any) -> thread,
	defer: (any, ...any) -> thread,
	delay: (number, any, ...any) -> thread,
	cancel: (thread) -> (),
}
