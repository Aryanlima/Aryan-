# Claude Code (Windows) + MCP de Roblox Studio — investigación (20-oct-2026)

Etiquetas: [OFICIAL] = docs de Roblox/Anthropic · [TERCERO] = repo/blog ajeno · [NO VERIFICADO] = no confirmado / deducción.
Fuentes principales:
- A = https://create.roblox.com/docs/en-us/studio/mcp.md (metadato "updated" 2026-10-19), igual que raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/studio/mcp.md (último commit 2026-08-21). Leídas el 2026-10-20.
- B = content/en-us/ai/coding-harness.md y ai/accelerated-workflows.md (creator-docs, leídos 2026-10-20).
- C = tu PC (solo lectura, 2026-10-20): %LOCALAPPDATA%\Roblox\ y ~/.claude.json.

## 0. Hallazgo importante en tu PC
- [C] Ya tienes el MCP añadido en Claude Code (ámbito usuario, `~/.claude.json`):
  `"Roblox_Studio": { "type":"stdio", "command":"cmd.exe", "args":["/c","%LOCALAPPDATA%\\Roblox\\mcp.bat"] }`
- [C] `%LOCALAPPDATA%\Roblox\mcp.bat` existe y lanza `C:\Program Files\Roblox\Versions\version-4f087c32742644ab\StudioMCP.exe`
  (si no existe, busca la carpeta en el registro HKCU\Software\Roblox\RobloxStudio\ContentFolder).
- Falta solo: tener Studio abierto con el interruptor activado. Comprueba con `/mcp` dentro de Claude Code.

## 1. Herramientas del MCP integrado (26) [OFICIAL, A, 2026-10-19]
Scripts
- `script_read` — lee un script por ruta con puntos (ej. game.ServerScriptService.MyScript).
- `multi_edit` — varias ediciones a un script en una sola operación (pide `datamodel_type`).
- `script_search` — busca scripts por nombre (difuso), máx. 10 resultados.
- `script_grep` — busca texto en todos los scripts, máx. 50 coincidencias.
Assets y generación
- `generate_mesh` — malla 3D con textura desde un texto (IA).
- `generate_material` — crea un MaterialVariant; devuelve material base y nombre de la variante.
- `generate_procedural_model` — objetos 3D hechos con piezas primitivas (bloques, esferas, cilindros, cuñas).
- `wait_job_finished` — espera a que termine un trabajo de generación procedural y da el estado final.
- `search_asset` — busca en Creator Store e Inventario (usuario, grupo o universo).
- `insert_asset` — inserta un asset por su ID numérico.
- `upload_image` — sube imágenes desde URLs HTTP; devuelve mapa ruta → asset ID.
- `store_image` — carga una imagen de un archivo local y da una URI para otras herramientas.
Modelo de datos
- `subagent` — lanza un subagente (tipos `explore` y `playtest`) para tareas largas.
- `search_game_tree` — explora la jerarquía de instancias (JSON plano).
- `inspect_instance` — detalle de una instancia: propiedades, atributos, etc.
Luau
- `execute_luau` — ejecuta Luau en Studio (datamodel Edit, Client o Server); devuelve resultado o error.
Playtest
- `get_studio_state` — estado de Studio (modo play, datamodels disponibles).
- `start_stop_play` — inicia / para el playtest.
- `get_console_output` — lee la ventana Output.
- `screen_capture` — captura el viewport (opcional: posición de cámara y punto al que mirar).
Entrada de jugador
- `character_navigation` — mueve el personaje a una posición o instancia.
- `user_keyboard_input` — teclas: down, up, press, texto, espera.
- `user_mouse_input` — ratón: mover, clic, botón down/up, scroll, espera.
Docs y skills
- `http_get` — descarga páginas de docs de Roblox permitidas (API, Creator docs…).
- `skill` — conocimiento/buenas prácticas de "skills" concretas.
Sesiones
- `list_roblox_studios` — lista Studios conectados: nombre, studio_id y place ID.
Nota: cada llamada lleva `studio_id` [OFICIAL, A]. Algunas webs citan `set_active_studio`; NO está en la doc actual
(era de una versión anterior) [TERCERO/NO VERIFICADO].

## 2. Formas de conectar Claude Code
Paso previo obligatorio [OFICIAL, A]: Studio → Assistant → "…" → Manage MCP Servers → activar
"Enable Studio as MCP server". Un indicador verde muestra clientes conectados.
a) Quick connect [OFICIAL, A]: Assistant Settings → MCP Servers → desplegable Quick connect. Lista:
   Antigravity, Codex CLI, Claude Code, Claude Desktop, Cursor, Gemini CLI, VS Code. Activas el tuyo.
   Si no aparece: instalar el cliente y reiniciar Studio. (B, coding-harness.md, solo menciona Cursor/VS Code.)
b) Comando CLI [OFICIAL, A — el comando Windows es `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`]:
   `claude mcp add --scope user Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`
   (la sintaxis `claude mcp add <nombre> -- <comando>` es de Claude Code; el `--scope user` es opcional).
   Tú ya lo tienes (ver punto 0).
c) JSON [OFICIAL, A]: entrada `Roblox_Studio` en `mcpServers` con command `cmd.exe`, args `["/c","%LOCALAPPDATA%\\Roblox\\mcp.bat"]`.
   En Claude Code puede ir en `.mcp.json` del proyecto.
d) Plugin "Roblox Studio" en el marketplace de Claude Code: NO ENCONTRADO.
   - Revisé el catálogo oficial `anthropics/claude-plugins-official/.claude-plugin/marketplace.json` (2026-10-20): 0 coincidencias con "roblox".
   - La doc de Roblox (A y B) no menciona plugin ni `/plugin`.
   - No hay comando `/plugin install` que pueda darte con fuente. [NO VERIFICADO que exista]
   - Si apareciera, el formato general sería `/plugin install <nombre>@claude-plugins-official` [OFICIAL Anthropic, mecánica general].
Después de configurar: reiniciar Studio y el cliente [OFICIAL, A].

## 3. ¿Se puede activar el interruptor sin la interfaz?
- Doc oficial: solo describe el interruptor en la UI. Ningún archivo, ajuste ni flag documentado [OFICIAL, A].
- Búsqueda web: nada sobre FFlag/archivo/GlobalSettings para esto [TERCERO, 2026-10-20].
- En tu PC [C]: `ClientSettings\StudioAppSettings.json` (flags que descarga Studio) tiene
  `FFlagAssistantStartMcpServerWithoutUI=True`, `FFlagEnableStudioMCPAuth=True`, `FFlagStudioMCPProxyToken=True`.
  Interpretación [NO VERIFICADO]: el servidor arranca sin abrir el panel Assistant una vez activado, y hay token/auth
  entre StudioMCP.exe y Studio. No es un "interruptor oculto".
- No encontré dónde guarda Studio el interruptor (no está en InstalledPlugins\0\settings.json ni en AssistantSettings).
- Conclusión: hay que activarlo a mano en Studio (una vez; debería recordarse). No recomiendo tocar FFlags locales
  (ClientAppSettings.json): no soportado y puede romper Studio.

## 4. MCPs de la comunidad
- Roblox/studio-rust-mcp-server [OFICIAL antiguo, GitHub]: ARCHIVADO el 2026-04-03; Roblox recomienda el integrado.
  Tenía 6 herramientas (run_code, insert_model, run_script_in_play_mode, get_studio_mode…). No usar.
- boshyxd/robloxstudio-mcp [TERCERO, GitHub, leído 2026-10-20]: ARCHIVADO (solo lectura), ~493 estrellas,
  "43 tools" (v2.7.0-next.6). Necesita plugin de Studio + "Allow HTTP Requests". Recomienda el fork de abajo.
  Instalación: `claude mcp add robloxstudio -- npx -y robloxstudio-mcp@latest`.
- Chrrxs/robloxstudio-mcp (fork mantenido) [TERCERO, GitHub, leído 2026-10-20]:
  `claude mcp add robloxstudio -- npx -y @chrrxs/robloxstudio-mcp@latest --auto-install-plugin`.
  Extras que el oficial no lista: playtest multicliente, `eval_server_runtime`/`eval_client_runtime` en caliente,
  breakpoints sin pausa, profiling CPU/memoria, gestión de developer products / game passes, edición "Inspector" solo-lectura,
  abrir/cerrar Studio. Fecha de último commit no visible.
- Otros: RobloxUI CLI (escribe .mcp.json), pipeworx "roblox" (datos públicos de perfiles, no Studio) [TERCERO].
Riesgos de seguridad:
- `npx -y ...@latest` ejecuta la última versión de npm sin fijar: si roban la cuenta del autor, ejecutas código malicioso.
- `--auto-install-plugin` descarga e instala un plugin de Studio con acceso total a tus places.
- "Allow HTTP Requests" abre un puente HTTP local.
- Repos archivados = sin parches.
- Cualquier MCP (también el oficial) puede leer y modificar tus places; `execute_luau` puede escribir en DataStores,
  hacer HTTP, etc. Conecta solo clientes de confianza y prueba en places de test [OFICIAL, A + TERCERO].
- Para ti: el oficial cubre casi todo (incl. playtest, input, capturas). Solo plantearse el fork si necesitas
  multicliente, profiling o monetización. Si lo usas, fija versión (sin `@latest`).

## 5. Limitaciones conocidas
- Studio debe estar abierto, con el place abierto y el interruptor activado; si no, no hay servidor [OFICIAL, A y B].
- Requiere la última versión de Studio y cliente compatible con stdio [OFICIAL, A].
- Varias ventanas de Studio: se puede, pero cada llamada debe llevar `studio_id`; usar `list_roblox_studios`.
  Places locales sin place ID aparecen solo por nombre (fácil confundirlos) [OFICIAL, A].
- Límites: script_search 10 resultados, script_grep 50 [OFICIAL, A].
- multi_edit y execute_luau necesitan `datamodel_type` (Edit / Client / Server): en playtest hay que apuntar al correcto [OFICIAL, A].
- Playtest: el agente lo controla con start_stop_play/get_studio_state; los cambios hechos en modo Play se pierden al parar (comportamiento normal de Studio) [NO VERIFICADO en la doc MCP].
- Si no aparece el servidor: reiniciar Studio y cliente, revisar ruta y JSON (una coma de menos lo rompe) [OFICIAL, A].
- Puede que tengas que aprobar comandos o añadir las herramientas MCP a la allowlist del agente [OFICIAL, B].
- Flag local `FFlagAssistantResetMcpSessionOnPlaceClose=True`: al cerrar el place se reinicia la sesión MCP [C, NO VERIFICADO].
- Script Sync (alternativa para editar archivos) es beta: File → Beta Features [OFICIAL, B].

## Fuentes
- https://create.roblox.com/docs/en-us/studio/mcp.md (2026-10-19)
- https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/studio/mcp.md (commit 2026-08-21)
- https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/ai/coding-harness.md
- https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/ai/accelerated-workflows.md
- https://raw.githubusercontent.com/anthropics/claude-plugins-official/main/.claude-plugin/marketplace.json
- https://github.com/Roblox/studio-rust-mcp-server (archivado 2026-04-03)
- https://github.com/boshyxd/robloxstudio-mcp · https://github.com/Chrrxs/robloxstudio-mcp
- https://www.moguravr.com/roblox-studio-mcp-server-agentic-update/ (2026-02-24)
