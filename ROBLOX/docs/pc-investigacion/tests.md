# Probar juegos de Roblox automáticamente (Windows + IA) — investigación 2026-10-20

Marcas: [OFICIAL] = docs/repos de Roblox · [TERCERO] = comunidad, comprobado en su repo · [NO VERIFICADO] = deducido, sin probar.

## Resumen rápido
- Lógica pura -> seguir con **Lune + testkit propio** (rápido, sin claves, sirve en CI).
- Pruebas dentro del motor real, sin abrir Studio -> **Open Cloud Luau Execution** (necesita una API key).
- Probar jugando en local -> **MCP de Studio** (`start_stop_play` + `execute_luau` + `get_console_output`).
- Framework de tests dentro de Roblox -> **Jest-Lua**. TestEZ está archivado.

## 1. Open Cloud "Luau Execution" [OFICIAL]
Fuente: create.roblox.com/docs/en-us/cloud/reference/features/luau-execution.md (leída el 2026-10-20). Los 5 endpoints están marcados **STABLE**.
Base: `https://apis.roblox.com`, cabecera `x-api-key`.
| Acción | Método y ruta | Límite |
|---|---|---|
| Crear tarea (última versión) | `POST /cloud/v2/universes/{universe_id}/places/{place_id}/luau-execution-session-tasks` | 5/min |
| Crear tarea (versión fija) | `POST /cloud/v2/universes/{universe_id}/places/{place_id}/versions/{version_id}/luau-execution-session-tasks` | 5/min |
| Ver tarea | `GET .../versions/{version_id}/luau-execution-sessions/{session_id}/tasks/{task_id}` | 200/min |
| Logs | `GET .../tasks/{task_id}/logs` (`maxPageSize` máx. 10000) | 45/min |
| Entrada binaria | `POST /cloud/v2/universes/{universe_id}/luau-execution-session-task-binary-inputs` (máx. 100 MiB, vale 15 min) | 5/min |
- **Permiso (scope) de la API key:** `universe.place.luau-execution-session:write` (para leer basta `:read`).
- **Límites:** script de hasta 4 MB y 5 min (`timeout` por defecto 5 min); como mucho 10 tareas sin terminar por place (si hay más, devuelve 429);
  lo que devuelve el script ≤ 4 MB en JSON; logs ≤ 450 KB; los datos se guardan 24 h.
- **Estados:** QUEUED → PROCESSING → COMPLETE / FAILED / CANCELLED. Hay que consultar (poll) la tarea hasta que termine.
- **Ojo:** no hay física y los Scripts/LocalScripts del place **no se ejecutan solos**. Los cambios no se guardan.
  El test tiene que hacer `require` de los módulos a mano. Sirve para lógica en ModuleScripts; no sirve para "jugar".
- **Cómo se usa con un place subido:**
  1) `rojo build -o test.rbxl`
  2) subir a un place SOLO de pruebas: `POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Saved`
     (body = el .rbxl; scope `universe-places:write`; 30/min; responde con el número de versión) [OFICIAL, endpoint marcado BETA, docs .../features/places.md]
  3) crear la tarea en esa `version_id` con un script que llame al runner (Jest-Lua o TestEZ) y haga `error()` si algo falla
  4) consultar la tarea y los logs; el CI falla si `state == FAILED`.
- Ejemplo oficial: `Roblox/place-ci-cd-demo` (Rojo + Selene + StyLua + Luau Execution) [OFICIAL, **archivado el 2024-09-25**; úsalo como modelo, no como dependencia].
  Su README dice que hay "2 tareas a la vez por universo"; la doc actual dice 10 por place. Manda la doc actual.
- Herramienta que ya lo hace todo: **jest-roblox-cli** (`christopher-buss/jest-roblox-cli`, v0.4.7 del 2026-10-13) [TERCERO].
  Backends: `open-cloud` (sube el place y consulta el resultado), `studio-cli` (Studio sin ventana, necesita sesión iniciada y no pide clave), `studio`.
  Variables: `ROBLOX_OPEN_CLOUD_API_KEY`, `ROBLOX_UNIVERSE_ID`, `ROBLOX_PLACE_ID`; tiene formato `--formatters github-actions`. Se instala con `rokit add christopher-buss/jest-roblox-cli`.

## 2. run-in-roblox vs Jest-Lua vs TestEZ
| Herramienta | Estado (comprobado el 2026-10-20 en la API de GitHub) | ¿Conviene? |
|---|---|---|
| TestEZ (`Roblox/testez`) [OFICIAL] | **Archivado el 2024-09-14** | No para código nuevo |
| run-in-roblox (`rojo-rbx/run-in-roblox`) [TERCERO] | No archivado, pero el último push es del **2024-03-06**. Abre Studio de verdad | No: lo sustituyen Luau Execution o jest-roblox-cli `studio-cli` |
| Jest-Lua (`jsdotlua/jest-lua`) [TERCERO, fork de Roblox] | v3.10.0 del **2024-12-23**; quieto pero estable, "listo para producción". Solo corre dentro de Roblox | **Sí**, si quieres tests dentro del motor (Wally: `jsdotlua/jest-globals@3.10.0`) |
| jest-roblox-cli [TERCERO] | Activo (v0.4.7, 2026-10-13) | Sí, como lanzador de Jest-Lua desde la terminal o el CI |
| Lune + testkit propio | Ya lo tienes | Sí, para lógica pura; es lo más barato |
- Truco [NO VERIFICADO]: escribir los specs con una API parecida a la de Jest para poder correr los mismos archivos en Lune y en Jest-Lua más adelante.

## 3. MCP de Studio para playtest automático [OFICIAL]
Fuente: creator-docs `content/en-us/studio/mcp.md` (último cambio 2026-08-21). Se activa en Assistant → … → Manage MCP Servers → "Enable Studio as MCP server".
En Windows: `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat` (stdio). **Studio tiene que estar abierto** con el place; no es headless, así que no vale para GitHub Actions.
Herramientas útiles (todas piden `studio_id`; sale de `list_roblox_studios`):
- `get_studio_state` → si está en play y qué datamodels hay.
- `start_stop_play` → arranca o para el playtest.
- `execute_luau` con `datamodel_type` = `Edit` | `Server` | `Client` → ejecuta asserts dentro de la partida y devuelve el resultado o el error.
- `get_console_output` → lee el Output (prints, warnings, errores de scripts).
- `screen_capture`, `character_navigation`, `user_keyboard_input`, `user_mouse_input` → simular al jugador.
- `subagent` con tipo `playtest` → playtest guiado por el agente.
Bucle recomendado [NO VERIFICADO como receta, sale de la doc]:
1) `rojo serve` sincronizando 2) `start_stop_play` (start) 3) esperar a que `get_studio_state` diga que está en play
4) `execute_luau` en Server con un script que ejecute los tests y haga `return {ok=..., fallos=...}`
5) `get_console_output` y buscar líneas de error 6) `start_stop_play` (stop).
El servidor de la comunidad `Roblox/studio-rust-mcp-server` llama a la herramienta de consola `get_console_output` y tiene además `run_script_in_play_mode` [TERCERO]; hay otras guías que la llaman `console_output`. Usa los nombres que salgan en tu lista de herramientas.

## 4. CI mínimo con GitHub Actions (proyecto Rojo) [NO VERIFICADO, basado en place-ci-cd-demo + setup-rokit]
Requisito: un `rokit.toml` en la raíz con rojo 7.7.1, selene, stylua y lune. Acción `CompeyDev/setup-rokit` [TERCERO, activa, último push 2026-05-06].
```yaml
name: ci
on: [push, pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: CompeyDev/setup-rokit@v0.1.2   # fija la versión que exista en su página de Releases
      - run: selene src
      - run: stylua --check src
      - run: rojo build default.project.json -o build.rbxl
      - run: lune run tools/testkit/runner   # ajusta a cómo arranca vuestro runner
  cloud-tests:            # opcional: solo cuando haya API key
    needs: check
    runs-on: ubuntu-latest
    if: ${{ vars.ROBLOX_TEST_PLACE_ID != '' }}
    concurrency: luau-execution   # evita pasarse del límite de tareas
    steps:
      - uses: actions/checkout@v4
      - uses: CompeyDev/setup-rokit@v0.1.2
      - run: jest-roblox --backend open-cloud --formatters github-actions
        env:
          ROBLOX_OPEN_CLOUD_API_KEY: ${{ secrets.ROBLOX_API_KEY }}
          ROBLOX_UNIVERSE_ID: ${{ vars.ROBLOX_TEST_UNIVERSE_ID }}
          ROBLOX_PLACE_ID: ${{ vars.ROBLOX_TEST_PLACE_ID }}
```
Notas sobre el repo: hay `selene.toml`, pero no hay `stylua.toml` ni `.github/workflows`. El único `default.project.json` está en `ROBLOX/.toolchain/rojo-prueba/`.
Antes de esto hay que decidir qué proyecto Rojo es el real.

## 5. Lo que tiene que hacer el usuario a mano (no compartir la clave con nadie, tampoco con la IA)
1. Crear una **experiencia/place SOLO de pruebas** (nunca el de producción) y apuntar su Universe ID y su Place ID.
2. En create.roblox.com → Open Cloud → API Keys: crear una clave con acceso a **esa** experiencia y los scopes
   `universe.place.luau-execution-session:write` y `universe-places:write`. Añadir restricción de IP si se puede (GitHub Actions no tiene IP fija; mejor una caducidad corta).
3. Guardarla en GitHub → Settings → Secrets → `ROBLOX_API_KEY`; los IDs, en Variables (`ROBLOX_TEST_UNIVERSE_ID`, `ROBLOX_TEST_PLACE_ID`).
   En local, guardarla en una variable de entorno de usuario de Windows, nunca en el repo.
4. Para el MCP: abrir Studio, iniciar sesión y activar "Enable Studio as MCP server" una vez.
5. (Opcional) Para jest-roblox `studio-cli`: tener Studio con la sesión iniciada en el PC; no hace falta clave.
