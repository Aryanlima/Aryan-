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
| 2 Pases y productos | PENDIENTE | — | Camino A: necesita que Aryan cree `ROBLOX_API_KEY` limitada a esta experiencia (Universe 10772154962). Camino B, a mano en Creator Hub: 11 objetos con ícono, en espera |
| 3 Cablear IDs | PENDIENTE | — | Depende de la etapa 2 |
