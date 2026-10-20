# Estado de la PC de Aryan (Windows)

Fecha: 2026-10-20. Lo preparó Claude Code en la PC, a partir de la rama `claude/brave-meitner-esyqy8` (commit `eaf261b`).

## Sistema

| Cosa | Estado |
|---|---|
| Windows | 11 Pro, build 22631, x64 |
| Git | 2.54.0 (con Git Bash en `C:\Program Files\Git\bin\bash.exe`) |
| Node / npm | v24.21.0 / 11.19.0 |
| VS Code | No instalado (no hace falta para lo de ahora) |
| Roblox Studio | **No instalado** (no existe `%LOCALAPPDATA%\Roblox\Versions`) |
| Claude Code | 2.1.304 (`C:\Users\Administrator\.local\bin\claude.exe`) |

## Toolchain de Roblox (con Rokit)

Instalé Rokit con su script oficial (`rojo-rbx/rokit/scripts/install.ps1`, lo leí antes de ejecutarlo).
Las herramientas están instaladas de forma **global** (`rokit add --global`), así que no hay ningún `rokit.toml` en el repo.

| Herramienta | Versión |
|---|---|
| rokit | 1.2.0 |
| rojo | 7.7.1 |
| stylua | 2.6.0 |
| selene | 0.32.0 |
| luau-lsp | 1.70.1 |
| lune | 0.11.0 (fijada así porque `.luaurc` y `tools/testkit/runner.luau` usan Lune 0.11) |

Nota: `CLAUDE.md` dice que el toolchain va en `ROBLOX/.toolchain/`. En Windows lo dejé global con Rokit, que es más simple.
Si la nube quiere versiones fijas por proyecto, que añada un `rokit.toml` y aquí se corre `rokit install`.

## Pruebas

No existe `tools/test.sh` ni `tools/README.md`. Corrí cada `*.spec.luau` con `lune run <archivo>` desde la raíz del repo:

| Archivo | Resultado |
|---|---|
| `tools/examples/ReceiptHandler.spec.luau` | 9 pasan, 0 fallan |
| `tools/testkit/mocks/mocks.spec.luau` | 38 pasan, 0 fallan |
| `tools/testkit/testkit.spec.luau` | 16 pasan, 0 fallan |

Total: **63 pasan, 0 fallan.** Además `selene tools` da 0 errores y 0 avisos.

## MCP de Roblox Studio (pendiente: falta Studio)

Pasos confirmados en la documentación oficial (`Roblox/creator-docs`, `content/en-us/ai/coding-harness.md` y `content/en-us/studio/mcp.md`):

1. Instalar Studio desde https://create.roblox.com/docs/studio/setup e iniciar sesión.
2. En Studio: botón **Assistant** (arriba a la derecha) → **⋯** → **Manage MCP Servers** → activar **Enable Studio as MCP server**.
3. En **Quick connect**, activar **Claude Code** (sale en la lista oficial). Si no aparece, reiniciar Studio.
4. Plan B, según la documentación: `claude mcp add Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`.
5. Verificar en Claude Code con `/mcp` y luego pedirle: "Usa el MCP de Roblox para listar lo que hay en Workspace".

No encontré en esa documentación la opción `/plugin` → "Roblox Studio", así que no está confirmada.

## Lo que Aryan tiene que hacer a mano

- [ ] Instalar Roblox Studio e iniciar sesión.
- [ ] Activar el MCP en Studio (pasos 2 y 3 de arriba) y avisar a Claude para verificarlo con `/mcp`.
- [ ] (Opcional) Instalar VS Code si quiere editar código con Script Sync.
