# Flujo recomendado: juegos de Roblox solo con código + Claude Code (Windows, octubre 2026)

Investigado el 2026-10-20. Etiquetas: [OFICIAL] = docs/foro de Roblox · [TERCERO] = docs/repo de la herramienta (no es de Roblox) · [NO VERIFICADO] = deducción mía o fuente débil.

## Resumen del flujo recomendado
1. Código en carpeta del proyecto con **Rojo** (los archivos mandan) + Git.
2. Claude Code edita `.luau`; `rojo serve` + plugin de Rojo lo mete en Studio en vivo.
3. **MCP de Studio** para que Claude lea el árbol, cree objetos, ejecute Luau y haga playtest.
4. `rojo build -o juego.rbxl` + **Open Cloud Place Publishing** (`rojo upload` o `rbxcloud`) para publicar sin clics.
5. StyLua + Selene + luau-lsp para formato, lint y tipos.

---

## 1. Rojo vs Script Sync

**Script Sync**
- Sincroniza en las dos direcciones scripts (`Script`, `LocalScript`, `ModuleScript`) y `Folder` con archivos `.luau`. Todo lo demás se ignora. [OFICIAL] create.roblox.com/docs/en-us/scripting/sync.md (actualizada 2026-10-19)
- Límites: 10 000 scripts por instancia sincronizada de primer nivel y 128 instancias de primer nivel. [OFICIAL] misma fuente
- Nombres de archivo: `x.server.luau` = Script de servidor, `x.client.luau` = Script de cliente, `x.local.luau` = LocalScript, `x.luau` = ModuleScript, `carpeta/init.*.luau` = script con hijos. [OFICIAL] misma fuente
- Si Studio y el disco no coinciden, aparece un diálogo para elegir "Keep Studio" o "Keep Disk". [OFICIAL] misma fuente
- Sigue en **beta**: se activa en File → Beta Features → Script Sync y luego hay que reiniciar Studio. [OFICIAL] create.roblox.com/docs/en-us/ai/coding-harness.md (2026-10-19)
  - La skill local `roblox-dev` dice "Full release 2026-06-17", pero no encontré ese anuncio y las docs oficiales del 2026-10-19 siguen diciendo beta. [NO VERIFICADO]
- Roblox tiene una guía oficial para agentes de IA (Claude Code incluido) que usa **Script Sync + MCP de Studio + Git**, sin Rojo. Ahí Script Sync no llega a StarterGui ni a StarterPack; para eso se usa el MCP. [OFICIAL] coding-harness.md (2026-10-19)

**Rojo**
- Roblox dice que Rojo es mejor si quieres versionar *todo* el proyecto o que el sistema de archivos sea la fuente de verdad. [OFICIAL] scripting/sync.md (2026-10-19)
- Roblox "no tiene planes de reemplazar Rojo ni dejarlo obsoleto". [OFICIAL] devforum.roblox.com/t/4065468 (2025-11-12)
- Rojo 7.7.1 salió el 2026-10-01 con arreglos de rutas en Windows para `rojo sourcemap` y `rojo serve`. Rojo 7.7.0 salió el 2026-07-01 y trajo `rojo syncback`, que pasa un place existente a archivos. [TERCERO] github.com/rojo-rbx/rojo CHANGELOG.md
- Rojo genera el `sourcemap.json` que necesita luau-lsp. Script Sync no lo genera. [TERCERO] marketplace de luau-lsp, y respuesta de la comunidad en el foro (2025-11-12)

**Cuál conviene hoy, para crear juegos SOLO con código y automatizar:** **Rojo**.
- Con Rojo el proyecto entero vive en archivos, lo que sirve para Git, para Claude y para `rojo build`.
- Con `rojo build` puedes generar el `.rbxl` y publicarlo sin abrir Studio.
- Script Sync solo sincroniza scripts y necesita que Studio esté abierto.

**¿Se pueden usar juntos?** No en las mismas carpetas.
- Ninguna fuente oficial lo prohíbe ni lo explica. [OFICIAL: no hay nada documentado]
- Si los dos tocan los mismos scripts, uno puede sobrescribir lo que escribe el otro. [NO VERIFICADO, deducción mía]
- Elige uno por proyecto. Si alguna vez los mezclas, que cada uno tenga carpetas distintas.

**Instalar el plugin de Rojo en Studio:**
- Sí, el comando es `rojo plugin install`. También sirve para actualizarlo. [TERCERO] rojo.space/docs/v7/getting-started/installation/ y notas de 7.7.1
- Otras formas: el plugin "Rojo 7" del Creator Store, o el `.rbxm` de GitHub Releases copiado a la carpeta de plugins. [TERCERO] misma fuente
- La versión mayor del plugin tiene que coincidir con la del CLI (7). [TERCERO]

## 2. Extensiones de VS Code (ID exacto · publicador)
| Extensión | ID | Publicador | Nota |
|---|---|---|---|
| Luau Language Server | `JohnnyMorganz.luau-lsp` | JohnnyMorganz | v1.70.1. Tipos, autocompletado, usa sourcemap de Rojo [TERCERO] marketplace |
| Rojo | `evaera.vscode-rojo` | evaera | v2.1.2. Arranca/para `rojo serve` desde VS Code [TERCERO] marketplace |
| StyLua | `JohnnyMorganz.stylua` | JohnnyMorganz | v1.7.2. Formateador [TERCERO] marketplace |
| selene | `Kampfkarren.selene-vscode` | Kampfkarren | Linter (no vi la versión) [TERCERO] marketplace |

- Las versiones salen de las páginas del marketplace consultadas el 2026-10-20.
- La extensión de Rojo es **opcional**, porque ya tienes Rojo por Rokit. Si Rojo no está instalado, intenta instalarlo con Aftman. [TERCERO]
- La guía oficial solo pide "VS Code con una extensión como Claude Code". [OFICIAL] coding-harness.md
- Configuración útil de luau-lsp:
  - `luau-lsp.sourcemap.enabled = true`
  - `luau-lsp.sourcemap.rojoProjectFile = "default.project.json"`
  - Comando manual: `rojo sourcemap --watch default.project.json --output sourcemap.json`
  - [TERCERO] marketplace de luau-lsp

## 3. Publicar sin clics (Open Cloud)

**API oficial: Place Publishing** [OFICIAL] create.roblox.com/docs/cloud/guides/usage-place-publishing.md (2026-10-19)
- Petición: `POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published`
- Cabeceras: `x-api-key: <clave>` y `Content-Type: application/octet-stream` (para `.rbxl`) o `application/xml` (para `.rbxlx`).
- Respuesta: `{ "versionNumber": N }`.
- Permiso de la API key: **universe-places**, con la operación **Write** sobre esa experiencia.
- Límite: 10 peticiones por minuto por IP. [OFICIAL] referencia universes-api (dato del buscador, no lo abrí directamente)

**Herramientas que llaman a esa API:**
- **`rojo upload`** [TERCERO] código fuente en github rojo-rbx/rojo src/cli/upload.rs (rama master)
  - Comando: `rojo upload default.project.json --api_key <KEY> --universe_id <U> --asset_id <PLACE_ID>`
  - Construye el place y lo publica (`versionType=Published`).
  - Sin `--api_key` usa la cookie de sesión del navegador. **No conviene.**
  - Confírmalo con `rojo upload --help` en tu 7.7.1. [NO VERIFICADO para 7.7.1 en concreto]
- **rbxcloud** (Sleitnick), v0.17.0 [TERCERO] sleitnick.github.io/rbxcloud
  - Comando: `rbxcloud experience publish -f juego.rbxl -p <PLACE_ID> -u <UNIVERSE_ID> -t published -a <KEY>`
  - `-t` acepta `saved` o `published`. Con `saved` guarda sin publicar.
  - Lee la clave de la variable de entorno `RBXCLOUD_API_KEY`.
  - Se instala con Aftman/GitHub (no menciona Rokit). Con Rokit sería `rokit add Sleitnick/rbxcloud`. [NO VERIFICADO]
- **Lune**: se puede llamar a la API con su librería `net`. Es más código y no aporta nada sobre las dos anteriores. [NO VERIFICADO]
- **Recomendación**: `rojo build -o juego.rbxl` y luego `rbxcloud experience publish`. La opción `-t saved` permite subir sin publicar.

**Subir assets (imágenes, audio, modelos): Assets API** [OFICIAL] cloud/guides/usage-assets.md (2026-10-19)
- `POST https://apis.roblox.com/assets/v1/assets` para crear y `PATCH .../assets/{assetId}` para actualizar.
- Máximo 20 MB por archivo.
- Tipos: Decal/Image (png, jpeg, bmp, tga), Audio (mp3, ogg, wav, flac, hasta 7 min), Model (fbx, gltf, glb, rbxm), Animation, Video.
- Permiso de la API key: **assets**, con Read/Write.
- Hace falta el ID de usuario o de grupo del creador.
- rbxcloud también tiene comandos para Assets. [TERCERO]

**Extra: Luau Execution API** [OFICIAL] cloud/reference/features/luau-execution.md
- `POST /cloud/v2/universes/{u}/places/{p}/luau-execution-session-tasks`
- Scope: `universe.place.luau-execution-session:write`.
- Ejecuta Luau en la nube sobre un place. Sirve para tests automáticos en CI.

**API keys** [OFICIAL] cloud/auth/api-keys.md (2026-10-19)
- Son de usuario y tienen los mismos permisos que su dueño.
- Para grupos, se recomienda crearlas con una cuenta alternativa que tenga permisos mínimos.
- **Caducan solas tras 60 días sin uso ni cambios.** Para reactivarlas, apaga y vuelve a encender "Enable Key".
- La restricción por IP es opcional y usa notación CIDR.
- Nunca subas la clave a un repositorio. Guárdala en una variable de entorno o en un `.env` que esté en `.gitignore`.

**Lo que el usuario tiene que hacer A MANO (una sola vez):**
1. Crear la experiencia.
   - En Studio: File → Publish to Roblox, o "Create Experience" en create.roblox.com.
   - No encontré ninguna API oficial de Open Cloud que cree experiencias nuevas. [NO VERIFICADO]
2. Copiar los IDs en create.roblox.com/dashboard/creations.
   - **Universe ID**: menú ⋯ de la miniatura → "Copy Universe ID".
   - **Place ID**: pestaña Places. [OFICIAL] usage-place-publishing.md
3. Crear la API key en Creator Dashboard → Open Cloud → API Keys → Create API Key.
   - Añade `universe-places` (Write) y, si hace falta, `assets` (Read/Write).
   - Restríngela a esa experiencia y pulsa "Save & Generate key". [OFICIAL] api-keys.md
4. Ajustar en el Dashboard: hacer pública la experiencia, el cuestionario de madurez (*Maturity questionnaire*) y otros ajustes. No encontré cómo hacer esto por API. [NO VERIFICADO]

## 4. Gestor de paquetes (Wally / pesde)
- Wally es el que aparece en la doc oficial de herramientas externas, junto con Rojo y Rokit. [OFICIAL] projects/external-tools.md (2026-10-19)
  - Última versión estable: v0.3.2. Hay una 0.4.0-alpha.1 publicada el 12 de octubre. [TERCERO] GitHub UpliftGames/wally releases
  - Problema conocido: rompe los tipos en luau-lsp si no usas `wally-package-types`. [TERCERO] post de Forest en el foro, ojo que es un competidor
- pesde va por la 0.7.x. Sirve para Roblox y para Lune, y puede instalar paquetes de Wally. [TERCERO] docs.rs/pesde
- **Para empezar no vale la pena.** Añádelo cuando necesites una librería concreta, por ejemplo ProfileStore o React-lua. Para paquetes de Roblox, la opción por defecto es Wally. [NO VERIFICADO, opinión]

## 5. Plugin compañero de luau-lsp para Studio
- Qué hace: envía el árbol vivo del DataModel de Studio a luau-lsp. Así tienes autocompletado y tipos de instancias que **no** están en tus archivos de Rojo, como las Parts de Workspace o la UI hecha en Studio. [TERCERO] github JohnnyMorganz/luau-lsp plugin/README.md
- Instalación:
  - Creator Store "Luau Language Server Companion", asset 10913122509.
  - En VS Code: `luau-lsp.studioPlugin.enabled = true`, puerto 3667.
  - En Studio hay que pulsar Connect, o activar `startAutomatically`.
- **¿Hace falta?** No es obligatorio. Si todo el juego está en archivos de Rojo, el `sourcemap.json` ya cubre casi todo.
  - Es útil si construyes cosas a mano en Studio o con el MCP.
  - Y Claude ya puede consultar el árbol directamente con el MCP (`search_game_tree`). [NO VERIFICADO, opinión]

## 6. Otras herramientas imprescindibles que faltan
- **Git**: la guía oficial lo pide para hacer commit tras cada hito. [OFICIAL] coding-harness.md
- **MCP de Studio**, que ya tienes. [OFICIAL] create.roblox.com/docs/en-us/studio/mcp.md (2026-10-19)
  - Se activa en Assistant → … → Manage MCP Servers → "Enable Studio as MCP server", y luego Quick connect → Claude Code.
  - Comando en Windows: `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`.
  - **No publica ni guarda places.** Para eso se usa Open Cloud.
- **rbxcloud**: falta instalarlo. Es lo único necesario para publicar si no quieres usar `rojo upload`. [TERCERO]
- **Rokit**: añade todas las herramientas al `rokit.toml` del proyecto. Es lo que recomienda Roblox. [OFICIAL] external-tools.md
- Tests: TestEZ/Jest-Lua se pueden ejecutar con la Luau Execution API. Opcional para empezar. [NO VERIFICADO]
- Ojo: las funciones que están en beta de Studio no funcionan en juegos publicados, así que no te fíes de ellas en código de producción. [TERCERO] skill local roblox-dev, que cita al staff de Roblox
