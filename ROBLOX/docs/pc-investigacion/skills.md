# Skills, plugins, MCP y agentes para crear juegos de Roblox con IA (2026-10-20)

Fuentes: GitHub (API y READMEs), Anthropic marketplace.json, WebSearch. Leído hoy, nada instalado.
Base que ya tenemos: `ROBLOX/skills/roblox-dev` (MSayib v2.18.1). Ya cubre: Luau, seguridad, DataStores,
monetización, UI, rendimiento, Rojo, las 28 herramientas del MCP integrado de Studio (incl. `generate_mesh`,
`generate_material`, `generate_texture`, `upload_image`, `skill` con los `rbx-*` de Roblox), Lune para
archivos, y los índices de Open Cloud. **No cubre**: pruebas automáticas (Jest), ejecución en la nube
(Open Cloud Luau Execution), lint/formato sin Studio, ni pruebas multijugador.
Ver también `ROBLOX/docs/skills-instaladas.md` (decisiones ya tomadas; esto las actualiza, no las repite).

Leyenda: [OFICIAL] = de Roblox o Anthropic. [TERCERO] = comunidad. [NO VERIFICADO] = no lo pude confirmar.

## 1. Recomendados (máx. 5, por utilidad)

### 1) Roblox Studio (plugin de agente) [OFICIAL Roblox]
- URL: https://github.com/Roblox/roblox-studio-agent-plugin · Autor: Roblox · MIT · 13 estrellas ·
  último push 2026-10-15 (v0.2.2).
- Qué aporta: registra solo el servidor MCP **integrado** de Studio (`StudioMCP` / `%LOCALAPPDATA%\Roblox\mcp.bat`)
  y añade la skill `roblox-get-started` (instalar/abrir Studio, activar MCP, elegir el Studio correcto,
  diagnóstico) + `SECURITY.md` + evals. No trae código propio.
- Instalar (en tu PC, no en la nube): en Claude Code `/plugin` → buscar **Roblox Studio** → instalar
  (así lo dice su README). Ojo: **no aparece** en `anthropics/claude-plugins-official` ni en
  `claude-plugins-community` (grep del marketplace.json hoy) y el repo no trae `.claude-plugin/marketplace.json`,
  así que `/plugin marketplace add Roblox/roblox-studio-agent-plugin` **no funcionaría** [NO VERIFICADO
  dónde lo indexa `/plugin`]. Alternativa equivalente: Studio → Assistant → Settings → MCP Servers → Quick connect.
- Riesgo: medio. Lanza un ejecutable de Studio; `execute_luau`, `multi_edit`, `insert_asset`, `generate_*`
  modifican el lugar sin deshacer seguro. Sin tokens (usa tu sesión de Studio). Puede descargar Studio de
  `setup.rbxcdn.com` tras pedir permiso. Usar este **o** Quick connect, no los dos.

### 2) Toolchain por Rokit: Rojo + luau-lsp + Selene + StyLua + Lune [TERCERO, estándar de facto]
- URLs/estrellas/push: rojo-rbx/rokit (483, 2026-09-27, MIT) · rojo-rbx/rojo (1808, 2026-10-06, MPL-2.0) ·
  JohnnyMorganz/luau-lsp (557, 2026-10-17, MIT) · Kampfkarren/selene (836, 2026-10-01, MPL-2.0) ·
  JohnnyMorganz/StyLua (2320, 2026-10-12, MPL-2.0) · lune-org/lune (966, 2026-10-11, MPL-2.0).
- Qué aporta: que la IA compruebe tipos, lint y formato **sin abrir Studio** (`luau-lsp analyze`,
  `selene`, `stylua --check`, `rojo build`). Es la forma barata de verificar antes de tocar Studio.
  No hay plugin de Claude Code para luau-lsp (el `lua-lsp` oficial de Anthropic es Lua 5.x, no Luau).
- Instalar: descargar `rokit.exe` de Releases y ejecutar `rokit.exe self-install` (evitar `irm ... | iex`).
  Luego en el proyecto: `rokit init` y `rokit add rojo-rbx/rojo`, `rokit add JohnnyMorganz/luau-lsp`,
  `rokit add Kampfkarren/selene`, `rokit add JohnnyMorganz/StyLua`, `rokit add lune-org/lune`.
  (Ya previsto en `ROBLOX/docs/setup-en-tu-pc.md`.)
- Riesgo: bajo. Binarios de GitHub Releases (fijar versiones en `rokit.toml`). Sin tokens. Nunca usar
  `getAuthCookie` de Lune.

### 3) Jest Roblox [OFICIAL Roblox]
- URL: https://github.com/Roblox/jest-roblox · Roblox · MIT · 50 estrellas · push 2026-10-02.
- Qué aporta: pruebas unitarias tipo Jest en Luau (lo que la skill no tiene). Corre en Studio o en CI vía
  Open Cloud Luau Execution.
- Instalar: en `wally.toml` → `[dev-dependencies]` `Jest = "roblox/jest@=3.20.0"` y
  `JestGlobals = "roblox/jest-globals@=3.20.0"`; luego `wally install` (Wally vía `rokit add UpliftGames/wally`).
- Riesgo: bajo. Es código Luau que solo corre en tu lugar de pruebas. Sin tokens (salvo si lo lanzas por Open Cloud).

### 4) Open Cloud Luau Execution (API oficial) + `rbxcloud` CLI
- API [OFICIAL]: https://create.roblox.com/docs/cloud/reference/features/luau-execution — corre un script
  en un servidor sin cabeza con tu lugar (máx. 5 min, 10 tareas por lugar). Sirve para CI: tests Jest
  en cada commit sin Studio abierto.
- CLI [TERCERO]: https://github.com/Sleitnick/rbxcloud · Sleitnick · MIT · 138 estrellas · **último push
  2025-03-23 (parado)**; v0.17 dice soportar Luau Execution [NO VERIFICADO en uso real].
  Instalar: `rokit add Sleitnick/rbxcloud`. Alternativa: `curl` directo a `apis.roblox.com` (menos dependencias).
- Riesgo: **alto con la clave**. Pide API key de Open Cloud (`x-api-key`) con permisos de ejecución/publicación.
  Crear una clave por juego, solo con permisos mínimos, solo en variable de entorno, y un **lugar de pruebas**
  separado del lugar publicado.

### 5) m4bwav/roblox-agent — solo como referencia, sin instalar aún [TERCERO]
- URL: https://github.com/m4bwav/roblox-agent · m4bwav · README dice MIT (la API de GitHub da NOASSERTION) ·
  2 estrellas · push 2026-10-18.
- Qué aporta: `rbx_check.py` (rojo + selene + StyLua + luau-lsp + Lune en un informe JSON) y `rbx_cloud.py`
  (Luau Execution, subir lugar, se niega a publicar sin `--yes`). Justo los huecos de 2–4, ya empaquetados.
- Instalar (si se aprueba tras revisar el código): `/plugin marketplace add m4bwav/roblox-agent` y
  `/plugin install roblox-agent@roblox-agent`.
- Riesgo: medio. Ejecuta Python y binarios; lee `ROBLOX_API_KEY`. El autor admite que **no lo probó con
  Studio real ni con Open Cloud real**. Mejor copiar la idea en un script propio de 30 líneas.

## 2. Otros encontrados (no recomendados ahora)

| Candidato | Tipo | Datos | Por qué no |
|---|---|---|---|
| Roblox/open-game-eval | [OFICIAL] benchmark | MIT, 73★, 2026-10-05 | Mide modelos en tareas de Studio; no construye juegos. Pide API key Open Cloud + clave de Anthropic. Útil solo para comparar agentes |
| Roblox/data-stores-batch-processor-cli | [OFICIAL] CLI | MIT, 20★, 2026-10-01 | Ejecuta Luau arbitrario sobre DataStores **de producción**. Solo para migraciones de datos en live ops, con copia previa |
| Chrrxs/robloxstudio-mcp (fork de boshyxd) | [TERCERO] MCP | MIT, 318★, 2026-10-18 | Único extra real: pruebas multijugador con `eval_server_runtime`/`eval_client_runtime` por peer. Pero `npx ...@latest` sin fijar, ejecuta Luau, `manage_monetization` pide API key. Duplica el MCP oficial |
| boshyxd/robloxstudio-mcp | [TERCERO] MCP | archivado 2026-06-06 | Autor perdió acceso a npm: riesgo de cadena de suministro |
| Roblox/studio-rust-mcp-server | [OFICIAL] MCP | archivado 2026-04-03 | Sustituido por el MCP integrado de Studio |
| SyphoDev-yt/roblox-ai-skills | [TERCERO] skills | 35★, 2 commits, licencia sin nombre | Lo más cercano a "assets/UI/SFX/animación": usa Blender, Spaces de Hugging Face y Kiln. Instala con `install.ps1` (no leído). El autor cuenta que su cuenta de Kaggle fue baneada. Demasiado frágil |
| AshExplained/roblox-skills, sentinelcore, tabooharmony/roblox-brain, nonlooped/roblox-suite, dig1t, kursku, greedychipmunk, EL4CTEO, zilibobi | [TERCERO] skills | 2–60★ | Solapan con nuestra skill y gastan contexto; alguna escribe en `CLAUDE.md` |
| ShiroKSH/skills (`roblox-studio@skills`), MCPBridge, Vibe Blocks MCP, princeofscale, WEPPY, Meganugger, Justice219 | [TERCERO] MCP/plugins | poca adopción | Ejecutan código en Studio o piden claves; nada que no cubra el MCP oficial |
| `lua-lsp` en claude-plugins-official | [OFICIAL Anthropic] | — | Es Lua 5.x/LuaJIT, no entiende tipos de Luau ni Roblox. Usar luau-lsp por CLI |

## 3. Huecos sin solución oficial

- **Sonidos**: no hay herramienta oficial de generación de audio en el MCP de Studio (solo `search_asset`/
  `insert_asset` de la Creator Store) [NO VERIFICADO que no exista en betas]. Usar audio de la Creator Store.
- **UI**: no hay generador oficial; la skill ya cubre UI por código. `screen_capture` sirve para revisarla.
- **3D/texturas**: ya cubiertos por `generate_mesh`/`generate_material`/`generate_texture` del MCP integrado.
- Anthropic **sí** lista plugins oficiales de Unity y Unreal en su marketplace, pero **ninguno de Roblox** (hoy).

## 4. Reglas de seguridad para lo que se instale

- Nada con `npx ...@latest`, `curl | bash` o `irm | iex` sin fijar versión y leer antes.
- Claves Open Cloud: mínimas, por juego, en variable de entorno, con caducidad; nunca en el repo ni en el chat.
- Aprobar a mano toda herramienta que modifique (ver `skills-instaladas.md` §4). Guardar versión del lugar antes.
