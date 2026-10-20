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

## MCP de Roblox Studio

- Registrado en Claude Code (usuario): `claude mcp add --scope user Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`.
- Probado a mano por stdio: `initialize` responde (`RobloxStudio 1.0.0`) y `list_roblox_studios` devuelve `{"studios":[]}`,
  porque **falta encender "Enable Studio as MCP server"** en Studio. No se puede activar sin la interfaz.
- El plugin oficial `Roblox/roblox-studio-agent-plugin` (v0.2.2, MIT) existe y solo trae configuración y una skill de instalación.
  No aparece en ningún catálogo que la CLI pueda ver (`claude-plugins-official`, `anthropic-plugin-directory`). Hace lo mismo que el registro manual,
  así que no se instaló, para no tener el servidor duplicado.

## Pruebas

No existe `tools/test.sh`. Se corrió cada `*.spec.luau` con `lune run <archivo>` desde la raíz:

| Archivo | Resultado |
|---|---|
| `ROBLOX/tests/Economy.spec.luau` | 22 pasan, 0 fallan |
| `ROBLOX/tests/Net.spec.luau` | 20 pasan, 0 fallan |
| `ROBLOX/tests/Odds.spec.luau` | 27 pasan, 0 fallan |
| `tools/examples/ReceiptHandler.spec.luau` | 9 pasan, 0 fallan |
| `tools/testkit/mocks/mocks.spec.luau` | 40 pasan, 0 fallan |
| `tools/testkit/testkit.spec.luau` | 16 pasan, 0 fallan |

Total: **134 pasan, 0 fallan** (corrido con la nube hasta `a47220b`). `selene tools`: 0 errores, 0 avisos.

## Recomendaciones para la nube (de la investigación)

- Usar **Rojo** como vía de sincronización: todo vive en archivos, `rojo build` funciona sin Studio y genera el sourcemap para luau-lsp. No mezclarlo con Script Sync en las mismas carpetas.
- Publicar sin clics: `rojo upload --api_key … --universe_id … --asset_id …` (existe en 7.7.1) con una API key de Open Cloud con el permiso `universe-places` Write.
- Pruebas dentro de Roblox: Jest-Lua por la API Open Cloud **Luau Execution** sobre un place de pruebas. TestEZ y run-in-roblox están abandonados.
- CI: no hay `.github/workflows` ni `stylua.toml`. Un CI mínimo sería selene + `stylua --check` + `rojo build` + `lune run` de los specs.
- No instalar MCPs de terceros (Chrrxs, boshyxd): repiten lo que hace el oficial, se instalan con `npx @latest` sin versión fija y ejecutan Luau.

## Lo que Aryan tiene que hacer a mano

- [x] Instalar Roblox Studio e iniciar sesión.
- [x] Conectar Rojo en Studio (Plugins → Rojo → Connect).
- [ ] En Studio: **Assistant → ⋯ → Manage MCP Servers → Enable Studio as MCP server**. Después, en una sesión nueva de Claude Code, `/mcp` debe mostrar `Roblox_Studio` conectado.
- [ ] (Cuando haga falta publicar) Crear en create.roblox.com un place de pruebas y una API key de Open Cloud con permisos mínimos.
      Guardarla en una variable de entorno de Windows, nunca en archivos ni en el chat.
