# Estado de la PC de Aryan (Windows)

Fecha: 2026-10-20. Lo preparó Claude Code en la PC (rama `pc/aryan-local`, con lo último de `claude/brave-meitner-esyqy8` mezclado).
Informes de los ayudantes que investigaron: `ROBLOX/docs/pc-investigacion/` (flujo, MCP, skills, pruebas).

## Sistema

| Cosa | Estado |
|---|---|
| Windows | 11 Pro, build 22631, x64 |
| Git | 2.54.0 (con Git Bash en `C:\Program Files\Git\bin\bash.exe`) |
| Node / npm | v24.21.0 / 11.19.0 |
| VS Code | 1.142.0 (instalador oficial de Microsoft, firma verificada) |
| Roblox Studio | Instalado en `C:\Program Files\Roblox\Versions\` (no en `%LOCALAPPDATA%`), sesión iniciada |
| Claude Code | 2.1.304 |

## Toolchain de Roblox (con Rokit)

Rokit se instaló con su script oficial (`rojo-rbx/rokit/scripts/install.ps1`, leído antes).
Herramientas **globales** (`rokit add --global`): no hay `rokit.toml` en el repo.

| Herramienta | Versión |
|---|---|
| rokit | 1.2.0 |
| rojo | 7.7.1 |
| stylua | 2.6.0 |
| selene | 0.32.0 |
| luau-lsp | 1.70.1 |
| lune | 0.11.0 (fijada: `.luaurc` y `tools/testkit/runner.luau` usan Lune 0.11) |

`CLAUDE.md` pide el toolchain en `ROBLOX/.toolchain/`; en Windows quedó global con Rokit. Si la nube añade un `rokit.toml`, aquí se corre `rokit install`.

## Extensiones de VS Code

`anthropic.claude-code`, `evaera.vscode-rojo`, `johnnymorganz.luau-lsp`, `johnnymorganz.stylua`, `kampfkarren.selene-vscode`.

## Rojo ↔ Studio: FUNCIONA

- `rojo plugin install` falla en esta PC ("Couldn't find registry keys"), porque Studio está instalado para toda la máquina.
  Se puso a mano el `Rojo.rbxm` oficial de la release v7.7.1 en `%LOCALAPPDATA%\Roblox\Plugins\`.
- Proyecto de prueba en `ROBLOX/.toolchain/rojo-prueba` (ignorado por git). Con `rojo serve` corriendo,
  Studio conectó: el panel muestra "rojo-prueba · localhost:34872".
- La nube todavía no tiene un `*.project.json` real. Cuando lo suba, se usará ese en vez del de prueba.

## Skill `roblox-dev`

En Windows sin modo desarrollador, `.claude/skills/roblox-dev` llega como un archivo de texto (el symlink no se crea).
Arreglo sin tocar el repo: una junction `C:\Users\Administrator\.claude\skills\roblox-dev` → `ROBLOX\skills\roblox-dev`.
Claude Code ya la detecta, y se actualiza sola con `git pull`.

## MCP de Roblox Studio: FUNCIONA

- Registrado en Claude Code (usuario): `claude mcp add --scope user Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`.
- "Enable Studio as MCP server" está **encendido**. Lo activó Claude con clics automáticos sobre la pantalla, con permiso de Aryan.
  En esta versión de Studio la ruta es: ícono **AI Assistant** (arriba a la derecha) → **⋯ → Settings → MCP Servers**.
- Prueba de punta a punta por stdio: `list_roblox_studios` → `rojo-prueba`; `tools/list` → 28 herramientas;
  `search_game_tree` ve `ReplicatedStorage.Shared.Hello` y `ServerScriptService.Server`. Es decir: disco → Rojo → Studio → MCP.
- Studio tarda unos segundos en conectarse al proxy MCP: si se pregunta enseguida, la lista sale vacía.
- El plugin oficial `Roblox/roblox-studio-agent-plugin` (v0.2.2, MIT) existe y solo trae configuración y una skill de instalación.
  No aparece en ningún catálogo que la CLI pueda ver (`claude-plugins-official`, `anthropic-plugin-directory`). Hace lo mismo que el registro manual,
  así que no se instaló, para no tener el servidor duplicado.

## Pruebas y lint (Git Bash, con la nube hasta `a469340`)

`tools/test.sh`: **8 specs, 212 tests: todos pasan.**

`tools/lint.sh`: **FALLA**, por el código y no por la PC:
- selene: 0 errores, 5 avisos de variables sin usar.
- `stylua --check`: sin formatear `ROBLOX/packages/{Economy,LiveOps,Shop,Data}.luau` y `ROBLOX/tests/{Odds,Shop}.spec.luau` (basta con `tools/format.sh`).
- `luau-lsp analyze` con tipos de Roblox: 11 errores. Por ejemplo: `Data.luau` 546, 669 y 818; `Economy.luau` 120; `Net.luau` 342, 359, 387 y 483; `Shop.luau` 507 y 582;
  `tests/Data.spec.luau` 88 (`Key 'sfx' not found`). Los "Function only returns 1 value, but 2 are required" y "TokenBucket and nil cannot be compared" se repiten.

Arreglos del entorno Windows que hicieron falta (no tocan código):
- **Saltos de línea:** Git para Windows trae `core.autocrlf=true` (sistema), así que los `.luau` salían con CRLF y `stylua.toml` pide `line_endings = "Unix"`: todo daba "Diff".
  En este clon: `git config --local core.autocrlf false` y `core.eol lf`, más una nueva extracción de los archivos. **Recomendación para la nube:** añadir `.gitattributes` con `* text=auto eol=lf`.
- **Tipos de Lune:** `lune setup` (corrido fuera del repo) generó `~/.lune/.typedefs/0.11.0/`, que pide el alias `lune` de `.luaurc`.
- **Tipos de Roblox:** `ROBLOX/.toolchain/share/globalTypes.d.luau` bajado de `JohnnyMorganz/luau-lsp/main/scripts/` (lo usa `lint.sh`).
- **`rokit.toml`** nuevo en la raíz, con las versiones de `tools/setup.sh` (selene 0.31.0, no 0.32.0). `rokit install` funciona en Windows.

## Verificaciones en la doc oficial (hechas desde la PC, que sí abre create.roblox.com y el DevForum)

Detalle y citas: `pc-investigacion/verificacion-monetizacion.md` y `pc-investigacion/verificacion-studio-politicas.md`.
- `ProcessReceipt` **no está deprecado** (la doc lo llama "legacy"). Existe `MarketplaceService:BindReceiptHandler(...)`, que devuelve `Enum.ReceiptDecision`. Si conviven, gana la nueva. `tools/examples/ReceiptHandler.luau` sigue siendo válido.
- Impuestos DevEx confirmados: desde el 1-nov-2026 son regalías; W-8BEN o W-8BEN-E antes del 31-oct en Creator Hub → Finances → Taxes.
- DevEx: sin tarifas por país (0,0038 / 0,0054 / 0,0035 legado). Qué países quedan fuera sigue sin verificar (la lista de Tipalti da 403).
- **Script Sync ya NO es beta** (salió completo el 2026-06-17, según anuncio de staff). Corregir `research/04` y `pc-investigacion/flujo.md`.
- Planning Mode existe (`/plan` en Assistant), pero no se puede usar desde el MCP ni desde Claude Code.
- Open Cloud: `universe-places:write` para publicar (endpoint beta) y `universe.place.luau-execution-session:write` para Luau Execution. Las claves caducan tras 60 días sin uso.
- Los requisitos de publicación se aplican a cada actualización, no solo al primer lanzamiento.

## Recomendaciones para la nube (de la investigación)

- Usar **Rojo** como vía de sincronización: todo vive en archivos, `rojo build` funciona sin Studio y genera el sourcemap para luau-lsp. No mezclarlo con Script Sync en las mismas carpetas.
- Publicar sin clics: `rojo upload --api_key … --universe_id … --asset_id …` (existe en 7.7.1) con una API key de Open Cloud con el permiso `universe-places` Write.
- Pruebas dentro de Roblox: Jest-Lua por la API Open Cloud **Luau Execution** sobre un place de pruebas. TestEZ y run-in-roblox están abandonados.
- CI: no hay `.github/workflows` ni `stylua.toml`. Un CI mínimo sería selene + `stylua --check` + `rojo build` + `lune run` de los specs.
- No instalar MCPs de terceros (Chrrxs, boshyxd): repiten lo que hace el oficial, se instalan con `npx @latest` sin versión fija y ejecutan Luau.

## Lo que Aryan tiene que hacer a mano

- [x] Instalar Roblox Studio e iniciar sesión.
- [x] Conectar Rojo en Studio (Plugins → Rojo → Connect).
- [x] Encender "Enable Studio as MCP server" (lo hizo Claude).
- [ ] Abrir una sesión nueva de Claude Code en `Aryan-` y comprobar con `/mcp` que `Roblox_Studio` sale conectado (esta sesión se abrió antes de registrarlo).
- [ ] **Urgente (según `CLAUDE.md`): impuestos de DevEx antes del 31-oct-2026** (Creator Hub → Finances → Taxes). Ver `pc-investigacion/verificacion-monetizacion.md`.
- [ ] (Cuando haga falta publicar) Crear en create.roblox.com un place de pruebas y una API key de Open Cloud con permisos mínimos.
      Guardarla en una variable de entorno de Windows, nunca en archivos ni en el chat.
