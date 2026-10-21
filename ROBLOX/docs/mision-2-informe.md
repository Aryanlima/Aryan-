# Misión 2 — informe (PC de Aryan)

Fecha: 2026-10-21. Datos de Aryan no dados: `ROBUX_EN_LA_CUENTA` en blanco, así que la 3.5 se omite. `ROBLOX_API_KEY`: NO definida, así que habría que ir por el camino B.

| Paso | Resultado | Evidencia | Notas |
|---|---|---|---|
| 0.1 Merge de la nube | OK | `git merge origin/claude/brave-meitner-esyqy8` (09c85b8) sin conflictos | `.gitattributes` LF presente; Node v24.21.0; `rokit install` OK |
| 0.2 Pruebas / lint / formato | FALLA (solo Windows) | 639 pasan, 1 falla, 3 omitidas; lint OK; formato OK | Falla `tools/wire-ids.spec.luau` (Lune → node). `node --test` directo: 52/52. Detalle en `playtest-1.md` |
| 0.3 Playtest sin compras | FALLA | `ROBLOX/docs/playtest-1.md`; `evidencia/playtest1-arranque.jpg` | El servidor se cae: `GetDataStore` fuera del `pcall` (GameService.luau:109) en un lugar sin publicar |
| 0.3b Arreglo + playtest de nuevo | OK | `playtest-1.md`, "Segunda pasada" | Aryan dio permiso para todo: se arregló `pickDataStore` con prueba nueva (640 en verde) y el juego se juega entero en Studio |
| 0.4 Puerta | OK (tras el arreglo) | — | — |
| 1.1 Crear la experiencia | OK | `evidencia/m2-1-privada.png` | Se publicó desde Studio con Alt+P y el nombre "FF Pruebas (privado)". Team Create quedó apagado y Data Sharing con su valor por defecto (encendido; lo decide Aryan). Se publicó directamente el `.rbxl` del juego, no un Baseplate vacío. En "Manage Audience" se cerró con la X, sin pulsar Invite ni Continue |
| 1.2 IDs | OK | `execute_luau`: `game.GameId` / `game.PlaceId` | **Universe ID 10772154962 · Place ID 98614059053563** |
| 1.3 Es privada | OK | Studio: "Only available to you and your collaborators". La API pública `games.roblox.com/v1/games?universeIds=10772154962` devuelve `[TITLE UNAVAILABLE]` | No se probó `publish-place.mjs` porque no hay `ROBLOX_API_KEY` |
| 1.4 Juego cargado | OK | `search_game_tree`: `ServerScriptService.Server` con Main, GameService, ProductIds… | Se publicó con el juego dentro; no hizo falta `rojo serve` |
| 2.1-2.2 Crear (camino A) | OK | `create-items.mjs --apply`: "13 creado(s), 0 ya existian" | La clave de Aryan está en la variable de usuario de Windows y se cargó solo para el comando, sin imprimirla. El primer intento dio 403 "Scope not authorized" (faltaban game-pass y developer-product); Aryan los añadió. Son 13 objetos porque se sumaron 2 cosméticos (tarea 002) |
| 2.3 Privada | OK | Open Cloud `cloud/v2/universes/10772154962` → `visibility: PRIVATE` | — |
| 2.4 Fuera de venta, precios | OK | Listado por API: los 13 con `isForSale=false` y el precio de `store-items.json` | Ninguno "Listed" |
| 3.1-3.2 Cablear | OK | `wire-ids.mjs` → 13 ID(s) cambian; StyLua OK; **PUERTA OK** (ReleaseGate 3/3) | — |
| 3.3 Verificación de solo lectura | OK | `execute_luau` (Edit) con `GetProductInfoAsync`: los 13 con nombre correcto, `venta=false` y precio `nil` (normal fuera de venta) | — |
| 3.4 TargetId o assetId | OK, **caso A** | En los 7 pases, `TargetId` = el ID de Open Cloud | Queda resuelta la duda de `PromptGamePassPurchase`: no hace falta alias |
| 3.5 Diálogo de compra | NO PROBADO | — | `ROBUX_EN_LA_CUENTA` sin dato. Además pide poner los objetos a la venta: decisión de Aryan |
