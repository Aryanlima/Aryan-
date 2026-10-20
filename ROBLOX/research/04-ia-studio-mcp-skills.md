# IA para programar y construir en Roblox Studio: Assistant, MCP, Skills y flujo con Git

Fecha del informe: 2026-10-20. Autor: agente de investigación (área 04). Idioma: español.

## 0. Resumen ejecutivo

1. **Roblox ya trae un servidor MCP dentro de Studio** (no hay que instalar nada externo). Se activa en Assistant, menú "...", "Manage MCP Servers", "Enable Studio as MCP server". Claude Code, Claude Desktop, Cursor, Codex CLI, Gemini CLI, Antigravity y VS Code salen en "Quick connect". Es la opción recomendada por Roblox. El servidor open source anterior (`Roblox/studio-rust-mcp-server`) está archivado desde 2026-04-03.
2. **Existe un plugin oficial de Roblox para Claude Code/Codex**: `Roblox/roblox-studio-agent-plugin`. Se instala con `/plugin` en Claude Code y buscando "Roblox Studio". Solo trae configuración y una skill de arranque; las herramientas son las del propio Studio.
3. **Para hacer MUCHOS juegos conviene "código en archivos + Git"**: Rojo (o Script Sync de Studio, ahora integrado) + Rokit + luau-lsp + Selene + StyLua. El agente edita archivos; el MCP se usa para playtest, inspección, capturas y ejecutar Luau puntual.
4. **El MCP de terceros más conocido (`boshyxd/robloxstudio-mcp`) está archivado** (2026-06-06). Hay forks activos (p. ej. `Chrrxs/robloxstudio-mcp`), pero Roblox recomienda el integrado y su propia skill de arranque advierte contra paquetes `npx` de terceros.
5. **Riesgo principal**: el agente puede ejecutar Luau con privilegios de plugin y modificar tu lugar abierto; el deshacer no es fiable. Guarda versiones/commits antes de cada tarea grande y no dejes que toque DataStores reales durante playtests.
6. **Lo más peligroso para un negocio de microtransacciones** es el código generado de `ProcessReceipt`, DataStore y RemoteEvents. Ahí la IA falla de forma sutil; exige revisión humana, linters y tests.
7. **Costes**: Roblox no publica en su documentación ningún precio ni cuota de Assistant, salvo 50 modelos procedurales por 24 h. Todo lo demás sobre cuotas gratuitas es de terceros y no verificado.

## 1. Metodología y límites de esta investigación

- `create.roblox.com`, `devforum.roblox.com` y casi todos los sitios de terceros (blogs, TechCrunch, etc.) dieron `ENOTFOUND` con WebFetch. Probé una vez por dominio y no insistí. No usé proxies ni TLS desactivado.
- **GitHub y raw.githubusercontent.com sí funcionaron.** Como Roblox publica su documentación oficial en el repositorio `Roblox/creator-docs`, pude leer el texto fuente de varias páginas oficiales (rama `main`, leídas el 2026-10-20; el repositorio no mostró fecha de commit). Eso se marca como [OFICIAL] con enlace al archivo del repo.
- **La cuota de WebSearch se agotó a mitad de investigación** (límite compartido). Cube 4D, precios y varios temas quedaron sin confirmar. Lo indico en la sección 12.
- De las publicaciones de DevForum solo vi resúmenes del buscador, no el texto completo. Se marcan "vía resumen del buscador".
- Leyenda: **[OFICIAL]** = publicado por Roblox (docs o repos de la organización Roblox). **[TERCERO]** = comunidad, blogs, repos de terceros. **[NO VERIFICADO]** = no pude confirmarlo o solo lo vi en un resumen o en marketing.
- Las estrellas y commits de GitHub son de la lectura del 2026-10-20 y vienen de un modelo que resume la página; trátalos como orientativos.

## 2. Roblox Assistant integrado

### 2.1 Qué es y qué incluye

- [OFICIAL] Assistant es el panel conversacional de Studio. Puede escribir y ejecutar Luau, crear y editar instancias, buscar e insertar assets del Creator Store, generar mallas y materiales, simular entradas y hacer playtest. Fuente: [ai/accelerated-workflows.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/ai/accelerated-workflows.md).
- [OFICIAL] **Planning Mode**: se activa con el desplegable "Plan" o con `/plan`. Genera un plan editable en Markdown y "solo se ejecuta cuando pulsas Build". Los planes se guardan en la nube, ligados a tu experiencia y perfil, y son privados. Fuente: [assistant/guide.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/assistant/guide.md) y [ai/build-with-assistant.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/ai/build-with-assistant.md).
- [OFICIAL] Comandos: `/generate_mesh` (malla texturizada desde texto o imagen, no ambos a la vez; una Part seleccionada puede servir de caja delimitadora), `/generate_procedural_model` (modelos ajustables por atributos, dejados en `GeneratedFolder`), `/generate_material` (aplica un material personalizado a partes), `/segment_mesh` (vista previa temprana: divide una MeshPart en partes con nombre), `/insert_asset`.
- [OFICIAL] **Subagente de captura de pantalla**: captura el viewport en modo Edit y Play para responder preguntas visuales.
- [OFICIAL] **Skills de Assistant** (distintas de las de Claude Code): documentos Markdown con frontmatter `name`, `description`, `enabled`; el prefijo `rbx-` está reservado. Vienen siete integradas: `rbx-create-skill`, `rbx-debug`, `rbx-device-simulator-lua`, `rbx-docs-search`, `rbx-perf-profiling`, `rbx-scene-analysis`, `rbx-unit-test`. Están ligadas a tu cuenta, no al lugar. Fuente: [assistant/skills.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/assistant/skills.md). La documentación no dice si el formato es compatible con `SKILL.md` de Claude Code.
- [OFICIAL] **BYOK**: Assistant, "...", "Manage API Keys"; proveedores Anthropic, OpenAI y Google Gemini; eliges el modelo en el desplegable. Fuente: [assistant/mcp.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/assistant/mcp.md). La página no dice quién paga el uso ni hay nota de precios.
- [OFICIAL] **Code Assist**: autocompletado en el editor (misma página accelerated-workflows).
- [OFICIAL] Historial de chats: se sincroniza en la nube, por lugar (no por experiencia). No hay límite duro de chats por lugar.

### 2.2 Límites documentados

| Límite | Valor | Fuente |
|---|---|---|
| Modelos procedurales | 50 por ventana móvil de 24 h | [OFICIAL] [assistant/guide.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/assistant/guide.md) |
| Triángulos de malla generada | máximo por defecto 10 000 | ídem |
| Segmentación | hasta 8 partes por modelo; `/segment_mesh` hasta 5 nombres por ejecución | ídem |
| Longitud de respuesta | si se corta una construcción, botón Continue | [OFICIAL] [ai/build-with-assistant.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/ai/build-with-assistant.md) |
| Cuota diaria de Assistant, costo, créditos | **no documentados** | [NO VERIFICADO] |

- [TERCERO] Hay una petición en DevForum para subir el límite de uso de Assistant ("se alcanza rápido") — [vía resumen del buscador](https://devforum.roblox.com/t/devforum-feature-request-increase-roblox-assistant-usage-limit/4686944). No pude abrirla.
- [NO VERIFICADO] Un blog de proveedor (sorceress.games) afirma que Assistant corre gratis sobre un modelo por defecto alojado por Roblox con cuota, y que la captura de pantalla del subagente de playtest y las imágenes de referencia en planes exigen BYOK. El texto oficial solo dice que quien use un cliente de terceros por MCP "o su propia API key" tiene acceso directo a la herramienta de captura subyacente, lo cual es ambiguo. No lo des por cierto.
- [NO VERIFICADO] Una página de competidor (Ropilot) dice que el Playtest Agent tiene cuota diaria propia y un tope de 50 turnos. Es marketing de la competencia.

### 2.3 Fechas y estado

- [OFICIAL, vía resumen del buscador] 2026-02-25: DevForum anuncia BYOK en Assistant (Anthropic, OpenAI, Gemini) y bucles agénticos con el MCP; avance de MCP de terceros (Blender, Figma). Ver [post](https://devforum.roblox.com/t/studio-mcp-server-updates-and-external-llm-support-for-assistant/4415631) y el [mensaje de Baszucki en X](https://x.com/DavidBaszucki/status/2025246197209071959).
- [OFICIAL, vía resumen del buscador] 2026-03-05: el servidor MCP pasa a ejecutarse nativamente dentro de Studio, con automatización de playtest ([post](https://devforum.roblox.com/t/assistant-updates-studio-built-in-mcp-server-and-playtest-automation/4474643)).
- [TERCERO] Mediados de abril de 2026 (TechCrunch, 2026-04-16): Assistant "agéntico" con planificación, generación de mallas y pruebas de juego ([artículo](https://techcrunch.com/2026/04/16/robloxs-ai-assistant-gets-new-agentic-tools-to-plan-build-and-test-games/), no pude abrirlo). Otra guía fecha Planning Mode el 1 de mayo; hay conflicto. El [post oficial de Planning Mode](https://devforum.roblox.com/t/announcing-planning-mode-for-roblox-assistant/4580715) lo resolvería y no pude leerlo.
- [NO VERIFICADO] Estado del "Playtesting Agent": la prensa lo llamó beta en abril; la documentación oficial no lo nombra como función aparte, solo habla de `subagent` con tipos `explore` y `playtest`.

### 2.4 Roblox "Build" (app móvil) — otra cosa

- [OFICIAL] Herramienta móvil para crear juegos 2D/2.5D desde texto. Mensajes diarios gratis (número no indicado) y créditos comprables con Robux. Despliegue gradual por región, empezando por Nueva Zelanda. Mínimo 9 años. **Editar el juego en Studio le quita para siempre el estado "Build"**. Fuente: [ai/build.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/ai/build.md). No es el camino para producir muchos juegos con monetización fina.

## 3. Generación de contenido: mallas, materiales, Cube 3D, 4D

- [OFICIAL] Mallas: `generate_mesh` (herramienta MCP y comando de Assistant). Texturas: `generate_texture`; segmentación: `segment_mesh`. Las dos últimas están presentes en builds recientes pero **sin documentar**; trátalas como no soportadas ([TERCERO] según [mcp-integration.md](https://raw.githubusercontent.com/MSayib/roblox-dev-skill/master/references/mcp-integration.md) de MSayib).
- [OFICIAL] Generador de materiales: imágenes 2D teselables guardadas como `MaterialVariant`. Modelos procedurales: se reconstruyen al cambiar parámetros. Avatar Auto-Setup: rigging y segmentación automática de modelos 3D. Fuente: accelerated-workflows.md.
- [OFICIAL] **Cube 3D** (repo [Roblox/cube](https://github.com/Roblox/cube), 1,3k estrellas): modelo fundacional 3D con pesos en Hugging Face (`Roblox/cube3d-v0.5`, `Roblox/cubepart`). Línea de tiempo en el README: marzo de 2025 v0.1; julio de 2025 v0.5; **mayo de 2026 CubePart** (generador 3D por partes controlable). Texturas y diseño de escenas figuran como "próximamente".
- [OFICIAL] **Licencia: el archivo LICENSE leído es la "CUBE3D RESEARCH-ONLY RAIL-MS LICENSE"** (aplica a v0.1 y código de inferencia): solo propósitos académicos o de investigación. [Texto](https://raw.githubusercontent.com/Roblox/cube/main/LICENSE). La licencia de los pesos v0.5 y CubePart en Hugging Face **no la pude verificar**. Conclusión práctica: **no montes tu propio pipeline comercial con los pesos de Cube sin revisar la licencia de cada modelo**. Usar `generate_mesh` dentro de Studio sí es el uso previsto por Roblox.
- [NO VERIFICADO] "4D" (generación con comportamiento/animación): el README de Cube no lo menciona y no pude buscarlo. No tengo datos.
- [NO VERIFICADO] Precio de la generación de mallas: la documentación oficial no lo trae. Una web (aitooltier) dice que incluye cuota diaria gratis sin dar el número, y un blog (Picoo) estima 20 a 60 USD "si compras créditos" sin fuente. Descartar ambos.

## 4. MCP integrado de Studio (recomendado)

### 4.1 Activación y conexión

[OFICIAL] Fuente: [studio/mcp.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/studio/mcp.md).

1. Última versión de Roblox Studio y un cliente MCP.
2. Studio: Assistant, "...", **Manage MCP Servers**, activar **Enable Studio as MCP server**.
3. Conectar el cliente por **Quick connect** (Assistant Settings, MCP Servers, desplegable Quick connect). Clientes listados: **Antigravity, Codex CLI, Claude Code, Claude Desktop, Cursor, Gemini CLI, Visual Studio Code**.
4. Alternativa: configuración JSON con una entrada `Roblox_Studio` bajo `mcpServers`:
   - macOS: comando `/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`
   - Windows: comando `cmd.exe`, argumentos `/c` y `%LOCALAPPDATA%\Roblox\mcp.bat`
5. Reiniciar el cliente (y Studio). En Manage MCP Servers aparece un indicador verde con el número de clientes conectados.

Detalles técnicos: transporte **solo stdio**, proceso local. Un cliente puede conectar a varias instancias de Studio; **cada llamada exige `studio_id`** (sale de `list_roblox_studios`).

### 4.2 Cómo se conecta cada herramienta

| Herramienta | Vía | Estado |
|---|---|---|
| Claude Code | Quick connect, o plugin oficial (`/plugin`, buscar "Roblox Studio") | [OFICIAL] |
| Claude Desktop / Cowork | Quick connect; en Cowork, Customize, Plugins, "Roblox Studio" | [OFICIAL] |
| Cursor | Quick connect o JSON | [OFICIAL] |
| Codex CLI | Quick connect, o `codex plugin marketplace add Roblox/roblox-studio-agent-plugin` y luego `/plugins` | [OFICIAL] |
| VS Code (incluye GitHub Copilot en modo agente) | Quick connect lista "Visual Studio Code". Los pasos específicos de Copilot no los vi | [OFICIAL] para VS Code; [NO VERIFICADO] para Copilot como tal |
| Windsurf | No figura en Quick connect. Podría funcionar con el JSON porque es stdio | [NO VERIFICADO] |
| Gemini CLI, Antigravity | Quick connect | [OFICIAL] |

- [NO VERIFICADO, derivado] Añadir a mano en Claude Code sería `claude mcp add Roblox_Studio -- "/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"` (sintaxis estándar de `claude mcp add` aplicada a la ruta oficial). No lo ejecuté; prefiere Quick connect o el plugin.
- [TERCERO] En Claude Code las herramientas aparecen como `mcp__Roblox_Studio__<nombre>` y algunas son diferidas (hay que cargar su esquema con tool-search) — [mcp-integration.md de MSayib](https://raw.githubusercontent.com/MSayib/roblox-dev-skill/master/references/mcp-integration.md).
- [TERCERO, vía resumen del buscador] Hay una guía de la comunidad para Linux con Vinegar/Wine ([DevForum](https://devforum.roblox.com/t/guide-to-setup-claudecodex-mcp-on-roblox-studio-vinegarwine/4770012)). El plugin oficial solo soporta macOS y Windows con Studio local.

### 4.3 Herramientas expuestas (26 documentadas)

[OFICIAL] según [studio/mcp.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/studio/mcp.md):

- **Scripts**: `script_read` (por ruta con puntos, todo o por líneas), `multi_edit` (varias ediciones en un script; crea el script si no existe; requiere `datamodel_type`), `script_search` (máx. 10), `script_grep` (máx. 50).
- **Luau**: `execute_luau` (contexto Edit, Client o Server; devuelve resultado o error).
- **Modelo de datos**: `search_game_tree`, `inspect_instance`, `subagent` (tipos `explore` y `playtest`).
- **Playtest**: `get_studio_state`, `start_stop_play`, `get_console_output`, `screen_capture`.
- **Simulación de entrada**: `character_navigation`, `user_keyboard_input`, `user_mouse_input`.
- **Assets y generación**: `generate_mesh`, `generate_material`, `generate_procedural_model`, `wait_job_finished`, `search_asset`, `insert_asset`, `upload_image`, `store_image`.
- **Docs y skills**: `http_get` (solo documentación de Roblox permitida), `skill` (material de referencia: depuración, simulación de dispositivos...).
- **Sesión**: `list_roblox_studios`.

Notas de versión [TERCERO] (MSayib, verificadas contra Studio 0.743 el 2026-10-17): el build 0.743 expone 28 herramientas (las 26 más `generate_texture` y `segment_mesh` sin documentar); `list_plugin_guis` y `capture_plugin_gui` aparecieron en 0.742 y desaparecieron en 0.743; los tipos de `subagent` varían entre builds. **El conjunto de herramientas cambia entre versiones; lista lo que tu host expone en lugar de fiarte de este texto.**

Las herramientas de **solo lectura** vs **que modifican lugar o cuenta** según el README del plugin oficial ([Roblox/roblox-studio-agent-plugin](https://github.com/Roblox/roblox-studio-agent-plugin)): de lectura `list_roblox_studios`, `get_studio_state`, `script_read`, `search_game_tree`, `inspect_instance`, `screen_capture`, `http_get`; que cambian cosas `execute_luau`, `multi_edit`, `insert_asset`, `generate_mesh`, `start_stop_play`, `subagent`, entre otras.

### 4.4 El plugin oficial de Roblox para agentes

[OFICIAL] [github.com/Roblox/roblox-studio-agent-plugin](https://github.com/Roblox/roblox-studio-agent-plugin) (MIT; 13 estrellas; solo 2 commits en la lectura; sin releases; lectura 2026-10-20).

- Solo contiene configuración y la skill `roblox-get-started`; arranca el `StudioMCP` del propio Studio. El resto del conocimiento viene de las skills `rbx-*` que trae tu versión de Studio (herramienta `skill`).
- Instalar: Claude Code, `/plugin`, buscar **Roblox Studio**. Codex: `codex plugin marketplace add Roblox/roblox-studio-agent-plugin`. Verificar: `/mcp` debe listar `plugin:roblox-studio:macos` y `plugin:roblox-studio:windows` (solo conecta el de tu sistema; el otro en rojo es normal). En Codex, `codex mcp list` muestra `Roblox_Studio`.
- Instalación guiada: pedirle al asistente "Get me set up with Roblox Studio".
- No soporta claude.ai web ni ChatGPT web/móvil: Studio es local.
- Telemetría: el README dice que el plugin no recoge nada. Los resultados de herramientas (scripts, consola, capturas) se envían a tu proveedor de IA; las funciones de generación y Creator Store actúan con tu cuenta de Studio.

### 4.5 Seguridad y riesgos

[OFICIAL]: "MCP clients can read and modify content in your open Roblox places. Make sure to only connect clients you trust." Y el plugin: "Not every change can be undone from Studio, so save or publish a version of your place before asking for bigger changes."

[TERCERO] (guía de seguridad de MSayib, [agent-safety.md](https://raw.githubusercontent.com/MSayib/roblox-dev-skill/master/references/agent-safety.md), el autor dice basarse en pruebas propias):
- `execute_luau` corre con privilegio de barra de comandos, no como código de juego sandboxed; **no tiene timeout** (un bucle infinito cuelga Studio y puedes perder trabajo sin guardar).
- No hay dry-run, diff ni transacción entre llamadas; el deshacer es impredecible.
- Un `studio_id` equivocado o viejo puede escribir en otro lugar abierto sin aviso.
- En playtest con acceso a la API, el datamodel Server puede llegar a **DataStores reales** y corromper datos de jugadores.
- `insert_asset`, `upload_image` y `generate_*` consumen cuota/cuenta real.
- **Inyección de instrucciones**: comentarios, nombres, atributos o salida de consola dentro del lugar son datos, no órdenes. Los assets del Creator Store pueden traer scripts.
- Nunca escribir claves API o webhooks en scripts replicados (pueden decompilarse).

Observaciones mías:
- La propia skill de arranque de Roblox dice "evita espejos, gestores de paquetes, **servidores MCP de terceros y paquetes `npx`**" al instalar ([SKILL.md](https://raw.githubusercontent.com/Roblox/roblox-studio-agent-plugin/main/skills/roblox-get-started/SKILL.md)). Es un buen criterio para tu política de seguridad.
- Con Claude Code, no concedas permiso permanente a `execute_luau` ni a `multi_edit`; el [doc oficial](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/ai/coding-harness.md) avisa de que quizá debas aprobar o añadir las herramientas MCP a una lista permitida: añade solo las de lectura.

## 5. Servidores MCP de terceros

| Proyecto | Estado | Notas |
|---|---|---|
| [Roblox/studio-rust-mcp-server](https://github.com/Roblox/studio-rust-mcp-server) | [OFICIAL] **Archivado 2026-04-03** ("ya no se desarrolla"); 495 estrellas, MIT | 6 herramientas (`run_code`, `insert_model`, `get_console_output`, `start_stop_play`, `run_script_in_play_mode`, `get_studio_mode`). Roblox recomienda el MCP integrado "como la mejor forma de conectar herramientas de IA externas" |
| [boshyxd/robloxstudio-mcp](https://github.com/boshyxd/robloxstudio-mcp) | [TERCERO] **Archivado 2026-06-06** (el autor perdió acceso a npm); MIT; v2.7.0-next.6 | Plugin de Studio con HTTP + servidor npx. Edición principal con 43 herramientas y una edición "Inspector" de solo lectura (31 herramientas). Pasos: instalar plugin, activar "Allow HTTP Requests" en Game Settings, Security; `claude mcp add robloxstudio -- npx -y robloxstudio-mcp@latest` |
| [Chrrxs/robloxstudio-mcp](https://github.com/Chrrxs/robloxstudio-mcp) | [TERCERO] fork recomendado por el autor original; MIT; 318 estrellas, 170 commits | Base v2.7.0. Evaluación de runtime servidor/cliente, playtest solo y multijugador, perfiles, captura, `manage_monetization` (requiere clave Open Cloud). Instalar (según su README): `claude mcp add robloxstudio -- npx -y @chrrxs/robloxstudio-mcp@latest --auto-install-plugin`. El instalador descarga el plugin de GitHub Releases |
| bdidk235/RobloxStudioMCP, drgost1/robloxstudio-mcp, Codder13/rbx-studio-mcp (y copia idéntica Qazcto7/rbx-studio-mcp) | [NO VERIFICADO] solo vi el título en el buscador | No los abrí. La existencia de dos repos con descripción idéntica sugiere copias: desconfía |

Cómo se conectan: igual que cualquier MCP stdio (Claude Code: `claude mcp add`; Cursor, Claude Desktop: entrada `mcpServers` con `npx -y <paquete>`; en Windows, si falla, `cmd /c npx ...`). Los comandos de la tabla son los que publican los README leídos el 2026-10-20; **no los ejecuté**.

Cuándo valen la pena: hoy, el servidor integrado cubre lectura/edición de scripts, Luau, playtest, entrada simulada y capturas. Los forks añaden perfilado, breakpoints, playtest multijugador y monetización por API. Un usuario del [hilo de DevForum](https://devforum.roblox.com/t/what%E2%80%99s-your-setup-to-use-claude-code/4684713) (vía resumen del buscador, [TERCERO]) usa un fork de boshy "con muchas más herramientas" y reporta que consultar un MCP de documentación mejoró la consistencia, que los espacios en blanco rompen `multi_edit` (lo mitigó con notas de memoria del proyecto) y que Opus para planificar más subagentes baratos le costó unos 40 dólares al mes.

**Riesgos de los de terceros**: ejecutan código arbitrario en tu Studio, se instalan vía npm (cadena de suministro; el caso boshyxd acabó con el autor sin acceso a su paquete), y descargan plugins de GitHub. Fija versiones y revisa el código antes de dar permisos.

## 6. Flujo "código en archivos + Git"

### 6.1 Dos caminos de sincronización

- [OFICIAL] **Studio Script Sync**: sincroniza Scripts/ModuleScripts de Studio con archivos `.luau` en disco, ahora integrado. El [documento oficial "coding harness"](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/ai/coding-harness.md) lo describe con **Cursor o VS Code + extensión de Claude Code + Studio MCP + Git**. Pasos clave: activar Script Sync (en el documento aparece como Beta Features y requiere reiniciar), clic derecho en cada servicio, Script Sync, "Sync to...", elegir carpeta; activar MCP y Quick connect. Limitación: no cubre StarterGui ni StarterPack (eso lo cubre el MCP). Ejemplos de prompts de verificación del doc: crear `ServerScriptService/Test.server.luau` que imprima "Hello from Script Sync!" y "Use the Roblox MCP to read the current game tree in Roblox Studio. List what's in Workspace."
- [TERCERO] Estado: el documento oficial aún dice "beta", pero hay un hilo DevForum "[Full Release] Studio Script Sync" ([enlace](https://devforum.roblox.com/t/full-release-studio-script-sync/4688454), vía resumen del buscador) y la skill de m4bwav fecha el lanzamiento completo el 2026-06-17 y da límites: 10 000 scripts por instancia de nivel superior y 128 instancias de nivel superior; conflictos con diálogo "Keep Studio / Keep Disk"; solo sincroniza scripts/carpetas; Roblox dice que **no sustituye a Rojo** ([roblox-agent-project](https://raw.githubusercontent.com/m4bwav/roblox-agent/main/skills/roblox-agent-project/SKILL.md)). Hay conflicto entre fuentes sobre si sigue en beta; en tu Studio comprueba File, Script Sync.
- [TERCERO] **Rojo** ([rojo-rbx/rojo](https://github.com/rojo-rbx/rojo)): MPL-2.0, 1,8k estrellas, 1534 commits. Última versión vista: **v7.7.1** (2 de octubre; la página no muestra el año; el release anterior 7.7.0 incluye `rojo syncback`). Instalación: Rokit, binario o `cargo install rojo --version 7.7.1`; plugin de Studio con `rojo plugin install`, `Rojo.rbxm` o el marketplace. Comandos (según m4bwav, [TERCERO]): `rojo init`, `rojo serve`, `rojo build -o build.rbxl`, `rojo syncback`, `rojo sourcemap -o sourcemap.json`. Rojo tiene sincronización bidireccional opcional en el plugin.
- [TERCERO] **Argon** ([argon-rbx/argon](https://github.com/argon-rbx/argon)): Apache-2.0, 150 estrellas, sincronización bidireccional, extensión de VS Code; última versión vista **2.0.29 (19 de mayo, año no mostrado)**. Alternativa a Rojo con menos comunidad; los comandos no los pude leer (su wiki es argon.wiki, no la abrí). Para agentes y equipos, Rojo es la apuesta con más documentación y herramientas de IA.
- Regla de oro [TERCERO]: **un solo escritor por script**. Con Rojo se edita en disco; ediciones directas en Studio (o `multi_edit` del MCP) en zonas mapeadas se sobrescriben en la siguiente sincronización. No mezclar Rojo y Script Sync sobre los mismos scripts.

### 6.2 Herramientas del entorno

| Herramienta | Qué hace | Estado/madurez (lectura 2026-10-20) |
|---|---|---|
| [Rokit](https://github.com/rojo-rbx/rokit) | Gestor de toolchain (`rokit add`, `rokit.toml`) | [TERCERO] MIT, 482 estrellas, 393 commits. m4bwav afirma que Aftman está archivado |
| [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp) | Servidor de lenguaje y `luau-lsp analyze` (tipos y lint con API de Roblox) | [TERCERO] MIT, 557 estrellas, **v1.70.1 (2026-09-27)** sincronizada con Luau 0.740; muy activo |
| [StyLua](https://github.com/JohnnyMorganz/StyLua) | Formateador; `stylua --check` sale con código 1 si falta formatear | [TERCERO] MPL-2.0, 2,3k estrellas; ejemplos con v2.6.0 |
| [Selene](https://github.com/Kampfkarren/selene) | Linter; configurar `std = "roblox"` | [TERCERO] MPL-2.0, 836 estrellas; 132 incidencias abiertas, mantenimiento incierto |
| [Wally](https://github.com/UpliftGames/wally) | Gestor de paquetes (`wally install`, `wally publish`) | [TERCERO] MPL-2.0, 505 estrellas; no vi fecha de actividad |
| [pesde](https://github.com/pesde-pkg/pesde) | Gestor de paquetes alternativo, multi-runtime (Roblox, Lune) | [TERCERO] MIT, 128 estrellas; **v0.7.4 (2026-09-09)**, estable |
| Lune | Ejecutor de Luau fuera de Roblox para tests de lógica pura | [TERCERO] citado por m4bwav; no abrí su repo |
| [jest-roblox](https://github.com/Roblox/jest-roblox) (organización Roblox) | Framework de tests para Luau | [OFICIAL] por aparecer en el listado de repos de Roblox; no lo abrí |

Sourcemap para luau-lsp [TERCERO, README de luau-lsp]: requiere Rojo 7.3.0+; `rojo sourcemap --watch default.project.json --output sourcemap.json`; ajustes `luau-lsp.sourcemap.*`; recomienda `sourcemap.json` en `.gitignore`. Para que luau-lsp reconozca los globales de Roblox hay que darle un archivo de definiciones (`--defs=...`); la skill de m4bwav lo descarga con `--fetch-defs` (`globalTypes.d.luau`, unos 0,9 MB). Con solo Script Sync no hay tipos en el editor; se puede usar el plugin "Luau Language Server Companion" ([TERCERO]).

### 6.3 Cómo lo usa un agente como Claude Code

Un flujo típico (verificado en documentación de terceros, no probado por mí):
1. Claude Code edita `src/**` (archivos `.luau`, `*.server.luau`, `*.client.luau`).
2. `rojo serve` + plugin de Studio los refleja en Studio (o Script Sync, si eliges ese camino).
3. El agente usa el **MCP de Studio** para: `start_stop_play`, `get_console_output`, `screen_capture`, `user_keyboard_input`/`user_mouse_input`, `execute_luau` (solo para consultas).
4. Antes de dar la tarea por hecha: `stylua --check`, `selene`, `luau-lsp analyze`, `rojo build` y tests Lune (la skill [roblox-agent-checks](https://raw.githubusercontent.com/m4bwav/roblox-agent/main/skills/roblox-agent-checks/SKILL.md) los reúne en un script `rbx_check.py` con salida JSON; su autor declara que aún no se probó con Studio real).
5. Git: ramas por función, `.gitignore` con `*.rbxl`, `*.rbxlx`, `sourcemap.json`, `Packages/`, `ServerPackages/`, `DevPackages/` (Wally) y `roblox_packages/` (pesde).

### 6.4 Open Cloud: publicar y automatizar

- [OFICIAL] **Publicar versión de lugar**: `POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published` con cabecera `x-api-key`, tipos `.rbxl` (octet-stream) o `.rbxlx` (xml); permiso `universe-places` con Write. Respuesta `{ "versionNumber": 7 }`. Aviso: no actualiza instancias de `EditableImage`, `EditableMesh`, `PartOperation`, `SurfaceAppearance` ni `BaseWrap`; si las usas, publica desde Studio. Fuente: [usage-place-publishing.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/cloud/guides/usage-place-publishing.md).
- [TERCERO, según la skill de m4bwav] `versionType` también acepta `Saved` (guarda sin publicar a jugadores); HTTP 409 si Studio tiene el lugar abierto; la clave se crea en Creator Dashboard, Open Cloud, API Keys, limitada a una experiencia.
- [OFICIAL, vía resumen del buscador; detalle TERCERO] **Luau Execution API** (beta en su día, ahora listada como estable en la referencia): crea una tarea (POST a `.../luau-execution-session-tasks`), Roblox arranca un servidor, carga el lugar y ejecuta tu script con acceso al DataModel; permiso `universe.place.luau-execution-session` (lectura y escritura). Límites según m4bwav: 5 minutos por tarea, 10 tareas concurrentes por lugar, 5 creaciones por minuto, scripts y resultados hasta 4 MB, datos 24 h; los cambios se pierden salvo `SavePlaceAsync`. Sirve para **tests de motor en CI**. Úsalo siempre contra un lugar de pruebas.
- Herramientas comunitarias: `rbxcloud` (CLI), `Krultu/rbx-publish` y `tenx29/save-to-roblox` (GitHub Actions) — [TERCERO, vía buscador].
- [TERCERO] Cambios de cuotas: según m4bwav, desde 2026-07-29 los DataStores de juego y de Open Cloud comparten presupuesto por experiencia; tras 2026-10-19 las APIs web autenticadas por cookie o sin autenticar tienen límites mucho menores, Open Cloud no cambia. Usa clave API u OAuth 2.0.
- Seguridad de claves: nunca en el chat, nunca en archivos del repo, nunca como argumento de línea de comandos; variable de entorno o secreto de GitHub.

## 7. Skills, plugins y repos de IA específicos de Roblox

Criterio de calidad: licencia visible, commits, CI/evals, fecha de verificación, y si el contenido es contrastable. Estrellas bajas no significan mala calidad, pero indican poca prueba en uso real. No ejecuté ninguno.

| Proyecto | Para | Qué hace | Calidad/mantenimiento |
|---|---|---|---|
| [Roblox/roblox-studio-agent-plugin](https://github.com/Roblox/roblox-studio-agent-plugin) [OFICIAL] | Claude Code, Cowork, Codex, ChatGPT | Conecta con el MCP de Studio; skill de arranque | MIT, 13 estrellas, 2 commits, sin releases. Delgado pero oficial. **Instalar** |
| [MSayib/roblox-dev-skill](https://github.com/MSayib/roblox-dev-skill) [TERCERO] | Claude Code, Antigravity, Codex y cualquier asistente con formato Skills | `SKILL.md` + 14 guías (Luau, red, seguridad, DataStores, rendimiento, UI, monetización, migración, uso del MCP, seguridad del agente). Versión 2.18.1, **verificada contra Studio 0.743 y Luau 0.743 el 2026-10-17** | MIT, 52 estrellas, 30 commits, CI, ejemplos con `--strict`, "registro de afirmaciones" con la fuente de cada dato de alto riesgo. **La mejor mantenida que vi.** Instalación por `curl ... \| bash` / PowerShell `irm ... \| iex`: **lee el script antes de ejecutarlo** |
| [m4bwav/roblox-agent](https://github.com/m4bwav/roblox-agent) [TERCERO] | Claude Code (plugin), Copilot CLI y VS Code, otros agentes con Agent Skills | 5 skills: studio, project (Script Sync o Rojo con Rokit), checks (`rbx_check.py`), cloud (`rbx_cloud.py`), workflow (API y seguridad). Instalar: `/plugin marketplace add m4bwav/roblox-agent` y `/plugin install roblox-agent@roblox-agent` | MIT, 2 estrellas, 35 commits, CI en 3 sistemas, evals por skill, `SECURITY.md`. Declara que **aún no se probó con Studio real ni con una llamada real a Open Cloud**. Muy buen diseño, poca adopción |
| [andrian-syh/roblox-optimum](https://github.com/andrian-syh/roblox-optimum) [TERCERO] | Claude Code, Copilot CLI, Codex, Qwen Code; reglas `.cursor/rules` y `AGENTS.md` para Cursor y Kiro | Normas + comprobador estático determinista (`npx roblox-optimum --check src/`) que detecta APIs obsoletas (`:connect()`, `wait()`), yields dentro de `UpdateAsync`, `ProcessReceipt` duplicado, bucles que congelan el hilo y miembros usados en el lado equivocado; MCP con `check_luau`, `explain_finding`, `get_standards`. Requiere Node 22+ | MIT, 1 estrella, 35 commits, CI, SECURITY.md con provenance de npm. **Interesante para tu caso (monetización)**; adopción mínima |
| [brockmartin/roblox-game-skill](https://github.com/brockmartin/roblox-game-skill) [TERCERO] | Claude Code | Router + 16 referencias + 7 plantillas de género (simulador, tycoon, obby...) + 7 flujos. Modo "Full" depende de `boshyxd/robloxstudio-mcp` (archivado) | 258 estrellas, solo 3 commits, **sin licencia visible**, cifras autodeclaradas. Popular pero sin pruebas de mantenimiento |
| [AshExplained/roblox-skills](https://github.com/AshExplained/roblox-skills) [TERCERO] | Claude Code | 40 skills (README) o 34 (sección About): arquitectura, economía, monetización, seguridad, QA, publicación, live ops; flujo PRD a issues; `setup-roblox-skills` escribe en tu `CLAUDE.md` | MIT, 25 estrellas, 6 commits, sin releases; inconsistencias internas; "battle-tested" sin evidencia |
| [gogolumo/rbsmithy-roblox-claude-skill](https://github.com/gogolumo/rbsmithy-roblox-claude-skill) [TERCERO] | Claude Code | Skill de flujo de producción (Luau, Rojo, multijugador, QA). Edición gratis MIT; **edición Pro de pago** (Agensi) con auditor CLI offline | 9 estrellas, 28 commits, CHANGELOG, tests. Aviso: modelo freemium |
| Otras (solo vistas en el buscador): `nonlooped/roblox-suite`, `tabooharmony/roblox-brain`, `afrxo/roblox-agent-skills`, `gamedev-skills/awesome-gamedev-agent-skills` (skill `roblox-luau`), `greedychipmunk/agent-skills`, listados en mcpmarket/skillselion/skills.sh | Claude Code | — | [NO VERIFICADO] no abrí los repos |
| Reglas para Cursor | Cursor | `roblox-optimum` trae `.cursor/rules`; Roxlit dice generar `CLAUDE.md`/`.cursorrules` con `npx roxlit setup` ([TERCERO, vía buscador; no abrí su web]). Las listas genéricas (PatrickJS/awesome-cursorrules) no mostraron sección de Roblox | [NO VERIFICADO] No encontré reglas oficiales de Roblox para Cursor |

Observaciones:
- No encontré una skill oficial de Anthropic para Roblox; la del buscador solo mostró terceros.
- No existe, que yo haya visto, una lista "awesome roblox ai" consolidada.
- **No instales cinco skills solapadas.** Cada skill consume contexto y pueden contradecirse (por ejemplo, ProfileService frente a ProfileStore). Elige una base de conocimiento (MSayib) y, si quieres, un comprobador (roblox-optimum o `rbx_check.py`).
- Las skills de Assistant (`rbx-*`) y las skills de Claude Code son cosas distintas, aunque ambas sean Markdown.

## 8. Documentación de Luau para LLMs (llms.txt)

- [OFICIAL, vía buscador; no pude abrir el host] Roblox publica un índice para agentes: `https://create.roblox.com/docs/llms.txt`, con contenido completo en `/docs/llms-full.txt`, y sub-índices: motor `/docs/reference/engine/llms.txt` y Open Cloud `/docs/cloud/llms.txt`, más un inventario de APIs obsoletas. El índice avisa de que usar el sub-índice equivocado produce código no funcional (escribir Luau dentro de la experiencia: índice del motor; llamar REST desde fuera: índice de Open Cloud).
- [TERCERO] Según m4bwav: añadir `.md` a cualquier URL de la documentación devuelve Markdown, y hay un endpoint de búsqueda que devuelve JSON. No lo verifiqué.
- [OFICIAL] Dentro de Studio, la herramienta MCP `http_get` solo permite URLs de documentación de Roblox (según MSayib, que terminen en `.md` o `llms.txt`) y la skill `rbx-docs-search` recupera documentación del motor, Creator y Cloud. Para Claude Code esto es lo mejor: **la documentación llega a través del propio Studio**, sin pedir red extra.
- [NO VERIFICADO] En mi entorno el host está bloqueado; en tu máquina sí debería abrirse. Prueba `curl` a `llms.txt` y fija su ruta en `CLAUDE.md`.
- Luau: el repositorio de [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp) sincroniza con Luau 0.740 (la versión de Studio 0.743 trae Luau 0.743; el desfase es normal).

## 9. Limitaciones reales de la IA con Luau y cómo mitigarlas

### 9.1 Documentado por Roblox [OFICIAL] ([prompt-engineering.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/assistant/prompt-engineering.md))

- Assistant confunde a menudo tiempo de edición con tiempo de ejecución y por defecto hace acciones de edición. Para algo "durante el juego" hay que pedir "añade un script que...".
- Resultados no deterministas; falla con prompts vagos; "requiere trabajo" aprender a pedirle.
- Consejos: ser específico (nombres exactos, servicio concreto como TweenService), usar la selección, prompts en varios pasos, imágenes `.png` de referencia limpias.

### 9.2 Errores comunes (recopilados por terceros; contrastar con la documentación)

Fuente: guías de MSayib sobre [DataStores](https://raw.githubusercontent.com/MSayib/roblox-dev-skill/master/references/datastore-persistence.md) y [seguridad](https://raw.githubusercontent.com/MSayib/roblox-dev-skill/master/references/security-hardening.md), y la skill [roblox-agent-workflow](https://raw.githubusercontent.com/m4bwav/roblox-agent/main/skills/roblox-agent-workflow/SKILL.md). [TERCERO]; algunos números de la guía de MSayib son medidos por el propio autor y no oficiales.

| Área | Error típico de la IA | Mitigación |
|---|---|---|
| APIs obsoletas | `wait`/`spawn`/`delay` en vez de `task.*`; `BodyVelocity` etc. en vez de `LinearVelocity`, `VectorForce`, `AlignOrientation`, `AlignPosition`; `Humanoid:LoadAnimation`; chat antiguo en vez de `TextChatService`; `Instance.new(clase, padre)` | roblox-optimum, skill con tabla de obsoletas, consultar `llms.txt` |
| Yields | Esperar (`task.wait`, llamadas que ceden) dentro del callback de `UpdateAsync`; bucles `while true` sin yield | roblox-optimum lo detecta; revisar manualmente |
| DataStore | Llamarlo desde `LocalScript`; sin `pcall`; `GetAsync` seguido de `SetAsync` (carrera); sin `BindToClose`; guardar valores por defecto si falla la lectura (sobrescribe un guardado real); reintentos sin backoff; mezclar métodos de ProfileService y ProfileStore | Usar `UpdateAsync` o ProfileStore (bloqueo de sesión); expulsar al jugador si falla la carga; tests de pérdida de datos |
| RemoteEvents | Confiar en valores del cliente (daño, posición, precio); sin comprobar tipos; aceptar NaN/infinito; sin límite de frecuencia; raycast desde origen que dice el cliente | Validar tipo, rango, propiedad, estado en el servidor; token bucket por jugador (usar `os.clock()`); el servidor decide, el cliente solo pide |
| Monetización | `ProcessReceipt` duplicado o no idempotente; conceder compra sin comprobar persistencia | **Revisión humana obligatoria**; roblox-optimum marca `ProcessReceipt` duplicado; probar con jugadores de prueba |
| Estructura | Scripts en ServerStorage (no corren); lógica o secretos en ReplicatedStorage; asumir orden de ejecución de scripts hermanos; ScreenGui sin `ResetOnSpawn = false` | CLAUDE.md con la arquitectura; skill MSayib de estructura |
| Edición | Reescribir scripts completos a ciegas; `multi_edit` falla si el texto no coincide exactamente (espacios) | Leer con `script_read` antes; tareas pequeñas; Git |
| Alucinación de API | Propiedades/eventos inexistentes; instancias que solo el motor permite en ciertos contextos | `luau-lsp analyze` con definiciones, `selene`; consultar `rbx-docs-search`/`http_get`; marcar "no verificado" si no hay doc |

### 9.3 Capas de defensa recomendadas (resumen)

1. **Contexto**: `CLAUDE.md` + una skill de base + documentación de Roblox bajo demanda (`llms.txt`, `http_get`).
2. **Análisis estático**: StyLua (`--check`), Selene (`std = "roblox"`), luau-lsp `analyze` (modo estricto `--!strict` en módulos críticos), roblox-optimum.
3. **Tests**: Lune para lógica pura; Jest-Roblox o la skill `rbx-unit-test` de Studio; Luau Execution API en CI para tests con motor; playtest automatizado (`subagent` `playtest`, entrada simulada) y siempre un playtest humano.
4. **Proceso**: ramas y PR; revisión humana en monetización/datos/remotos; lugar de pruebas separado; versiones `Saved` antes de publicar.

## 10. Comparativa honesta

Esto es **mi análisis** a partir de las fuentes; no hay un benchmark independiente. No encontré precios verificables, así que no los comparo salvo el dato anecdótico indicado.

| Criterio | Assistant integrado | Claude Code + MCP de Studio (+ Rojo/Script Sync) | Cursor (+ MCP de Studio) | GitHub Copilot (VS Code) |
|---|---|---|---|---|
| Instalación | Nada; viene con Studio | Quick connect o plugin oficial + proyecto en disco | Quick connect + Script Sync/Rojo | VS Code figura en Quick connect; no vi guía específica de Copilot |
| Planificar, construir, probar | Plan Mode con botón Build, subagentes, generación de mallas/materiales/procedurales | Edita código en disco; usa el MCP para playtest, capturas, entrada. Tú orquestas el plan | Similar a Claude Code en modo agente; edición dentro del IDE | Modo agente con MCP (no verificado para Roblox) |
| Git, revisión, CI | Débil: trabaja sobre el lugar abierto, sin diff propio | **Fuerte**: archivos, ramas, linters, tests, PR | Fuerte | Fuerte |
| Generación 3D/materiales | **Nativa** (`/generate_mesh`, etc.); también vía MCP (`generate_mesh`...) | Vía MCP si necesitas (consume cuota de tu cuenta) | Igual | Igual |
| Escala a muchos juegos | Media: cada lugar aparte | **Alta**: plantilla de repo, paquetes compartidos, automatización | Alta | Alta |
| Control de costes | Límites propios de Roblox (no publicados salvo 50 procedurales/24 h); puedes usar BYOK | Costo de tu suscripción o API; anécdota: unos 40 USD al mes con Opus para planificar y subagentes baratos | Costo del plan de Cursor | Costo del plan de Copilot |
| Riesgo | Ediciones directas al lugar, deshacer no fiable | Permisos de `execute_luau`/`multi_edit`; mitigar con Git y lista de herramientas permitidas | Igual | Igual |
| Cuándo usarlo | Prototipos rápidos, assets 3D, materiales, preguntas sobre el lugar abierto, ver cómo "se ve" | **Código de producción, sistemas con DataStore y monetización**, refactors, CI | Si prefieres IDE gráfico y elegir modelo | Si ya pagas Copilot |

Recomendación para tu objetivo (muchos juegos con microtransacciones): **Claude Code + Rojo + MCP integrado de Studio** como columna vertebral; **Assistant** solo para assets 3D, materiales, bocetos de mapa y UI inicial; Cursor o Copilot son equivalentes funcionales si prefieres IDE, no una mejora de fondo. Para decidirlo con datos, mide en un juego piloto: tiempo hasta primer playtest jugable y errores detectados por tus linters.

## 11. Setup recomendado paso a paso

Se asume Windows o macOS con Roblox Studio (Studio no corre de forma nativa en Linux; hay guías Vinegar/Wine, no verificadas por mí). Los comandos con etiqueta [TERCERO] vienen de los README de esas herramientas; verifica con `--help` o con su documentación antes de depender de ellos.

### Paso 0. Prerrequisitos
1. Cuenta de Roblox, Studio actualizado, Git, VS Code, Claude Code.
2. Instala Rokit siguiendo su [README](https://github.com/rojo-rbx/rokit) (script de instalación; no copié el comando porque no lo pude leer).
3. Pide a tu agente: "Get me set up with Roblox Studio" **solo después** de leer qué va a descargar. Roblox dice que pide una única aprobación y descarga desde `setup.rbxcdn.com`.

### Paso 1. Activar el MCP integrado [OFICIAL]
1. Studio, Assistant, "...", **Manage MCP Servers**, **Enable Studio as MCP server**.
2. Quick connect, activa **Claude Code**. O en Claude Code: `/plugin`, busca **Roblox Studio**, instala.
3. Verifica con `/mcp` (debe verse `plugin:roblox-studio:<tu sistema>`). Prueba: "Usa el MCP de Roblox para leer el árbol del juego y lista lo que hay en Workspace."
4. Permisos: concede solo herramientas de lectura (`list_roblox_studios`, `get_studio_state`, `script_read`, `search_game_tree`, `inspect_instance`, `get_console_output`, `screen_capture`). Deja `execute_luau`, `multi_edit`, `insert_asset`, `generate_*` y `start_stop_play` con aprobación manual.

### Paso 2. Repositorio y toolchain por juego [TERCERO]
```
mkdir mi-juego && cd mi-juego && git init
rokit init
rokit add rojo-rbx/rojo
rokit add JohnnyMorganz/StyLua
rokit add Kampfkarren/selene
rokit add JohnnyMorganz/luau-lsp
rokit add lune-org/lune
rokit add UpliftGames/wally      # o pesde-pkg/pesde, solo si usas paquetes
rojo init
```
- Confirma `rokit.toml` en Git (fija versiones; si no, pasa en tu máquina y falla en CI).
- Crea `selene.toml` con `std = "roblox"` y `stylua.toml` (por defecto StyLua usa tabuladores, ancho 120).
- `.gitignore`: `*.rbxl`, `*.rbxlx`, `sourcemap.json`, `Packages/`, `ServerPackages/`, `DevPackages/`, `roblox_packages/`.
- Instala el plugin de Rojo en Studio (`rojo plugin install`, o `Rojo.rbxm`, o el marketplace) y ejecuta `rojo serve`; en Studio pulsa Connect.
- Alternativa más simple para un primer juego: **Script Sync** (File, Script Sync) siguiendo la [guía oficial](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/ai/coding-harness.md). Decide **una** vía por juego y no mezcles.

### Paso 3. Tipos y calidad (puertas de control)
1. Sourcemap: `rojo sourcemap --watch default.project.json --output sourcemap.json` ([README de luau-lsp](https://github.com/JohnnyMorganz/luau-lsp)).
2. Comprobaciones que el agente debe ejecutar antes de cerrar una tarea [TERCERO, de la skill roblox-agent-checks]: `stylua --check src`, `selene src`, `luau-lsp analyze --platform=roblox --defs=<globalTypes.d.luau> --sourcemap=sourcemap.json src` (verifica flags con `luau-lsp --help`), `rojo build -o build.rbxl` y `lune run tests/<test>.luau`.
3. Opcional: `npx roblox-optimum install` y `npx roblox-optimum --check src/` (requiere Node 22+; es un paquete npm de terceros con 1 estrella, revisa su código y fija la versión).
4. Haz que estas comprobaciones corran también en GitHub Actions (plantilla a escribir por ti; no probé una).

### Paso 4. CLAUDE.md del proyecto (plantilla propia, ajústala)
```
# Reglas del proyecto (Roblox/Luau)
- Fuente de verdad: archivos en src/ (Rojo). No editar scripts directamente en Studio ni con multi_edit en zonas mapeadas.
- Antes de usar una API que no conozcas, consulta la documentación (llms.txt del Creator Hub o la herramienta http_get del MCP de Studio). Si no puedes verificarla, dilo.
- Server authority: el cliente solo solicita; el servidor valida tipo, rango, propiedad y estado, con límite de frecuencia por jugador.
- Datos: ProfileStore o UpdateAsync, pcall con reintentos, guardar en PlayerRemoving y BindToClose; nunca valores por defecto si falla la lectura.
- Compras: ProcessReceipt único e idempotente; todo cambio en monetización requiere revisión humana.
- Prohibido: wait/spawn/delay, Body* movers, Instance.new(clase, padre), secretos en ReplicatedStorage.
- Antes de terminar: stylua --check, selene, luau-lsp analyze, rojo build y tests. Informa qué comprobaciones se omitieron.
- No toques DataStores reales durante playtests; usa un lugar de pruebas.
```

### Paso 5. Skills (poco, bien elegidas)
1. Roblox Studio (plugin oficial) ya instalado en el paso 1.
2. Una skill de conocimiento: [MSayib/roblox-dev-skill](https://github.com/MSayib/roblox-dev-skill). Lee `install.sh` antes de ejecutarlo (el README publica `curl ... | bash` y PowerShell `irm ... | iex`); alternativa: clonar el repo y copiar la carpeta de la skill a `.claude/skills/` si prefieres no ejecutar scripts remotos.
3. Opcional: [m4bwav/roblox-agent](https://github.com/m4bwav/roblox-agent) (`/plugin marketplace add m4bwav/roblox-agent`, `/plugin install roblox-agent@roblox-agent`) para `rbx_check.py` y `rbx_cloud.py`.
4. No instales skills "de negocio" masivas (AshExplained, 40 skills) hasta probar con un juego piloto.

### Paso 6. Flujo diario con el agente
1. Commit limpio y **guarda una versión** del lugar antes de cada tarea grande.
2. Pide el cambio en una rama; el agente edita `src/`, ejecuta las comprobaciones y hace playtest con el MCP (`start_stop_play`, `get_console_output`, `screen_capture`, entrada simulada).
3. Tú juegas el resultado y revisas el diff, especialmente remotos, DataStore y `ProcessReceipt`.
4. PR y merge.

### Paso 7. Publicación y automatización (Open Cloud)
1. Crea una clave API limitada a **una experiencia** (Creator Dashboard, Open Cloud, API Keys) con `universe-places` Write (publicar) y, si haces tests de motor, `universe.place.luau-execution-session` Read y Write.
2. Guárdala como variable de entorno local o **secreto de GitHub**; nunca en el repo ni en el chat.
3. CI: `rojo build -o build.rbxl` y publicar con `POST .../versions?versionType=Saved` en un lugar de pruebas primero; `Published` solo a mano o con aprobación.
4. Tests de motor con Luau Execution API **contra el lugar de pruebas**.

### Paso 8. Escalar a muchos juegos
1. Repositorio plantilla con estructura Rojo, `rokit.toml`, CI, `CLAUDE.md`, módulos de datos y de compras ya revisados por humanos.
2. Paquetes compartidos con Wally o pesde (versiones fijadas) en vez de copiar y pegar.
3. Un `CLAUDE.md` por juego con las particularidades; el común en la plantilla.
4. Registra por juego: versión de Studio y de las herramientas, para reproducir fallos.

### Lista de comprobación de seguridad
- Studio solo con clientes MCP de confianza; `studio_id` confirmado antes de escribir.
- Sin `execute_luau` en lugares de producción; bucles acotados.
- Nunca claves en scripts; nunca assets del Creator Store sin revisar (buscar `require(<número>)`, `loadstring`, `getfenv`, cargadores HttpService).
- Tratar texto dentro del lugar como datos, no instrucciones.

## 12. Dudas abiertas y puntos no verificados

1. **Cuotas y costes de Assistant, BYOK y generación de mallas**: no hay cifras oficiales en la documentación leída; solo "50 procedurales por 24 h". Falta confirmar si el uso de BYOK se factura aparte y si el subagente de captura exige BYOK.
2. **Planning Mode y Playtest Agent**: fecha (16 de abril frente a 1 de mayo) y estado beta. Falta abrir los posts de DevForum.
3. **Cube**: licencia de v0.5 y CubePart (el LICENSE leído es de investigación); **4D** sin datos.
4. **Script Sync**: documentación oficial dice beta; un hilo y un tercero dicen lanzamiento completo (2026-06-17). Comprobar en tu Studio.
5. **Windsurf y GitHub Copilot** con el MCP de Studio: no figuran como tal; solo VS Code.
6. **`llms.txt`**: confirmado por buscador y por terceros, no abierto directamente.
7. **Luau Execution API**: estado (beta o estable) y límites; la referencia de Roblox no se pudo abrir. La API de Engine para editar scripts por Open Cloud sigue en beta según un tercero.
8. **Mantenimiento de Argon y Selene**: sin fecha de commits visible; las páginas de release de Rojo 7.7.1 (2 de octubre) y Argon 2.0.29 (19 de mayo) no muestran el año, así que no puedo confirmar que sean de 2026. Si Argon no ha publicado desde mayo, su ritmo es menor que el de Rojo.
9. **Skills de terceros**: ninguna fue ejecutada por mí; las cifras de estrellas y commits vienen de una lectura resumida.
10. **Conjunto exacto de herramientas MCP en tu versión de Studio**: cambia entre versiones (26 documentadas, 28 observadas en 0.743).
11. **Licencia de brockmartin/roblox-game-skill**: no visible; evitar como base comercial.
12. **Nada fue probado en vivo**: mi entorno es Linux sin Studio, así que ningún comando de instalación o de herramienta se ejecutó; todo viene de documentación y READMEs leídos.

## 13. Fuentes (leídas el 2026-10-20 salvo indicación)

### [OFICIAL] Roblox
- [studio/mcp.md (Connect to the Roblox Studio MCP server)](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/studio/mcp.md) (URL pública: create.roblox.com/docs/studio/mcp, bloqueada en mi entorno)
- [assistant/guide.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/assistant/guide.md)
- [assistant/mcp.md (BYOK)](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/assistant/mcp.md)
- [assistant/skills.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/assistant/skills.md)
- [assistant/prompt-engineering.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/assistant/prompt-engineering.md)
- [assistant/overview.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/assistant/overview.md)
- [ai/accelerated-workflows.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/ai/accelerated-workflows.md)
- [ai/build-with-assistant.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/ai/build-with-assistant.md)
- [ai/build.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/ai/build.md)
- [ai/coding-harness.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/ai/coding-harness.md)
- [cloud/guides/usage-place-publishing.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/cloud/guides/usage-place-publishing.md)
- [Roblox/roblox-studio-agent-plugin](https://github.com/Roblox/roblox-studio-agent-plugin) y su [SKILL.md](https://raw.githubusercontent.com/Roblox/roblox-studio-agent-plugin/main/skills/roblox-get-started/SKILL.md)
- [Roblox/studio-rust-mcp-server (archivado 2026-04-03)](https://github.com/Roblox/studio-rust-mcp-server)
- [Roblox/cube](https://github.com/Roblox/cube) y su [LICENSE](https://raw.githubusercontent.com/Roblox/cube/main/LICENSE)
- [Roblox/creator-docs](https://github.com/Roblox/creator-docs) (CC-BY-4.0 el texto, MIT los ejemplos)
- Posts de DevForum (solo vistos vía resumen del buscador, no abiertos): [MCP integrado y automatización de playtest](https://devforum.roblox.com/t/assistant-updates-studio-built-in-mcp-server-and-playtest-automation/4474643), [BYOK y MCP](https://devforum.roblox.com/t/studio-mcp-server-updates-and-external-llm-support-for-assistant/4415631), [Planning Mode](https://devforum.roblox.com/t/announcing-planning-mode-for-roblox-assistant/4580715), [mallas, nuevas herramientas MCP y captura](https://devforum.roblox.com/t/assistant-updates-mesh-generation-new-mcp-server-tools-screenshot-tool-and-more/4527258), [Script Sync lanzamiento completo](https://devforum.roblox.com/t/full-release-studio-script-sync/4688454), [Luau Execution (beta)](https://devforum.roblox.com/t/beta-open-cloud-engine-api-for-executing-luau/3172185), [índice `llms.txt`](https://create.roblox.com/docs/llms.txt)

### [TERCERO]
- [MSayib/roblox-dev-skill](https://github.com/MSayib/roblox-dev-skill): [mcp-integration.md](https://raw.githubusercontent.com/MSayib/roblox-dev-skill/master/references/mcp-integration.md), [agent-safety.md](https://raw.githubusercontent.com/MSayib/roblox-dev-skill/master/references/agent-safety.md), [project-structure.md](https://raw.githubusercontent.com/MSayib/roblox-dev-skill/master/references/project-structure.md), [security-hardening.md](https://raw.githubusercontent.com/MSayib/roblox-dev-skill/master/references/security-hardening.md), [datastore-persistence.md](https://raw.githubusercontent.com/MSayib/roblox-dev-skill/master/references/datastore-persistence.md)
- [m4bwav/roblox-agent](https://github.com/m4bwav/roblox-agent): skills [checks](https://raw.githubusercontent.com/m4bwav/roblox-agent/main/skills/roblox-agent-checks/SKILL.md), [project](https://raw.githubusercontent.com/m4bwav/roblox-agent/main/skills/roblox-agent-project/SKILL.md), [workflow](https://raw.githubusercontent.com/m4bwav/roblox-agent/main/skills/roblox-agent-workflow/SKILL.md), [cloud](https://raw.githubusercontent.com/m4bwav/roblox-agent/main/skills/roblox-agent-cloud/SKILL.md)
- [andrian-syh/roblox-optimum](https://github.com/andrian-syh/roblox-optimum), [brockmartin/roblox-game-skill](https://github.com/brockmartin/roblox-game-skill), [AshExplained/roblox-skills](https://github.com/AshExplained/roblox-skills), [gogolumo/rbsmithy-roblox-claude-skill](https://github.com/gogolumo/rbsmithy-roblox-claude-skill)
- MCP de terceros: [boshyxd/robloxstudio-mcp](https://github.com/boshyxd/robloxstudio-mcp), [Chrrxs/robloxstudio-mcp](https://github.com/Chrrxs/robloxstudio-mcp)
- Toolchain: [Rojo](https://github.com/rojo-rbx/rojo) ([release](https://github.com/rojo-rbx/rojo/releases/latest)), [Argon](https://github.com/argon-rbx/argon) ([release](https://github.com/argon-rbx/argon/releases/latest)), [pesde](https://github.com/pesde-pkg/pesde) ([releases](https://github.com/pesde-pkg/pesde/releases)), [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp) ([release](https://github.com/JohnnyMorganz/luau-lsp/releases/latest)), [StyLua](https://github.com/JohnnyMorganz/StyLua), [Selene](https://github.com/Kampfkarren/selene), [Wally](https://github.com/UpliftGames/wally), [Rokit](https://github.com/rojo-rbx/rokit)
- Prensa y blogs (solo vía buscador, no abiertos): [TechCrunch 2026-04-16](https://techcrunch.com/2026/04/16/robloxs-ai-assistant-gets-new-agentic-tools-to-plan-build-and-test-games/), [sorceress.games](https://sorceress.games/blog/stack-the-best-ai-for-roblox-game-development-studio-2026) (blog de proveedor), [Ropilot vs Assistant](https://ropilot.ai/blog/ropilot-vs-roblox-assistant) (competidor), [hilo "What's your setup to use Claude Code?"](https://devforum.roblox.com/t/what%E2%80%99s-your-setup-to-use-claude-code/4684713), [guía Vinegar/Wine](https://devforum.roblox.com/t/guide-to-setup-claudecodex-mcp-on-roblox-studio-vinegarwine/4770012)

## 14. Correcciones posteriores (2026-10-20, verificadas desde el PC de Aryan)

La sesión del PC puede abrir `create.roblox.com` y el DevForum (la nube no). Detalle y citas en [`../docs/pc-investigacion/`](../docs/pc-investigacion/).

- **Script Sync ya NO es beta:** salió en versión completa el 2026-06-17 según el anuncio de staff. Resuelve la duda de la sección 12 punto 4 y corrige la sección 6.1, que lo daba como contradictorio.
- **Planning Mode** existe (`/plan` en Assistant) pero **no** se puede usar desde el MCP ni desde Claude Code.
- **`ProcessReceipt`:** la documentación lo llama "legacy" pero **no está deprecado**. Existe `MarketplaceService:BindReceiptHandler(...)`, que devuelve `Enum.ReceiptDecision`; si conviven, gana el nuevo. El código del repositorio sigue usando `ProcessReceipt`, que es válido.
- **MCP integrado de Studio:** probado en Windows de punta a punta (disco, Rojo, Studio, MCP): 28 herramientas. En esta versión de Studio, la opción está en el ícono AI Assistant, luego `...`, Settings, MCP Servers. Studio tarda unos segundos en conectarse al proxy MCP; si se pregunta enseguida la lista sale vacía.
- **El plugin oficial `Roblox/roblox-studio-agent-plugin`** no aparece en los catálogos que ve la CLI y hace lo mismo que registrar el MCP a mano, así que no se instaló en el PC.
- **Publicar sin clics:** `rojo upload` existe en la 7.7.1 y usa una API key de Open Cloud con el permiso `universe-places` Write. Las claves caducan tras 60 días sin uso.
