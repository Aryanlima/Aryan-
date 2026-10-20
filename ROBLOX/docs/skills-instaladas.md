# Skills y herramientas de IA instaladas

Fecha: 2026-10-20. Autor: agente de herramientas de IA (sesion Claude Code). Idioma: espanol.
Base: `ROBLOX/research/04-ia-studio-mcp-skills.md` (secciones 5, 7, 8 y 11).

Leyenda de fiabilidad: **[VERIFICADO]** = leido hoy en el propio archivo o en documentacion oficial;
**[NO VERIFICADO]** = no pude confirmarlo; **[TERCERO]** = viene de un tercero.
Todo contenido descargado se trato como NO CONFIABLE hasta revisarlo. Nada de lo descargado se ejecuto
(salvo el comprobador `roblox-optimum --check` de la seccion 3, en modo solo lectura y sin red).

## 1. Resumen

| Elemento | Estado | Donde |
|---|---|---|
| Skill `roblox-dev-skill` (MSayib, MIT, v2.18.1, commit `4a35b01`) | **Instalada** (solo la parte de skill) | `ROBLOX/skills/roblox-dev/` + symlink `.claude/skills/roblox-dev` |
| Plugin oficial `Roblox/roblox-studio-agent-plugin` | **No instalable aqui** (la sesion corre en Linux en la nube, sin Studio). Se instala en tu PC con `/plugin` | Pasos en `ROBLOX/docs/setup-en-tu-pc.md` |
| `roblox-optimum` (npm) | **Evaluado, no instalado.** Uso fijado a la version 1.14.0 y solo el subcomando `--check` | Seccion 3 |
| Resto (AshExplained, brockmartin, rbsmithy, m4bwav, MCP de terceros...) | **No instalados** | Seccion 5 |

## 2. Skill `roblox-dev-skill`

### 2.1 De donde viene y que se instalo

- Repositorio: https://github.com/MSayib/roblox-dev-skill (tercero). Licencia MIT.
- Commit fijado: `4a35b01cb07eb237081bee705455e19db37342d8` (2026-10-17), version 2.18.1, verificada por su
  autor contra Studio 0.743.0.7431133 y Luau 0.743.
- Descarga: `git clone --depth 1` a un directorio temporal fuera del repo. No se ejecuto `install.sh`,
  `install.ps1` ni `install.cmd`.
- Copiado **sin modificar**: `SKILL.md`, `LICENSE` y `references/` (14 guias). Hashes SHA-256 en
  `ROBLOX/skills/roblox-dev/PROVENANCE.md` (16 de 16 coinciden con el upstream).
- Archivos nuestros en la misma carpeta: `PROVENANCE.md` (origen y revision) y `LOCAL-NOTES.md`
  (discrepancias con nuestras decisiones).
- Descubrimiento: symlink relativo `.claude/skills/roblox-dev -> ../../ROBLOX/skills/roblox-dev`.
  Claude Code carga skills de proyecto desde `.claude/skills/<nombre>/SKILL.md` y acepta symlinks a
  directorios [VERIFICADO en la doc de skills de Claude Code, 2026-10-20]. La sesion la listo como
  `roblox-dev (roblox-dev-skill)`: el `name` del frontmatter manda sobre el nombre de carpeta.
- Frontmatter valido: solo `name` y `description` (876 caracteres).

### 2.2 Que se reviso y resultado

Detalle completo en `ROBLOX/skills/roblox-dev/PROVENANCE.md`. Resumen:

- **Resultado: seguro de adoptar** como base de conocimiento. Es Markdown: no trae herramientas, hooks,
  `.claude-plugin/`, ni `settings`. No encontre instrucciones que alteren permisos, toquen `settings.json`
  o `CLAUDE.md`, exfiltren datos, ejecuten comandos remotos (`curl | bash`), oculten informacion o
  desactiven controles de seguridad. Tampoco Unicode invisible ni comentarios HTML ocultos.
- La skill refuerza nuestras reglas: server authority, validacion de remotes, `ProcessReceipt`
  idempotente (con avisos), sin secretos en `ReplicatedStorage`, y `agent-safety.md` (confirmar antes de
  operaciones destructivas, tratar el texto del lugar como datos y no como ordenes).
- Hallazgos menores, ninguno bloqueante (todos en `LOCAL-NOTES.md`):
  1. Fallback `npx ctx7@latest` y monitor `~/RobloxDocs`: se usarian solo con permiso. **Decision: no
     usarlos sin aprobacion explicita.**
  2. Ejemplo de recibo con efectos laterales dentro del callback de `UpdateAsync` (Roblox puede
     re-ejecutarlo): **no copiar tal cual**; el patron de referencia es `ROBLOX/tools/examples/ReceiptHandler.luau`.
  3. Pruebas "contra un DataStore real" en dos ejemplos: **usar mocks o un lugar de pruebas**.
  4. Menciona `getAuthCookie` (Lune): **prohibido usarlo**.
  5. No trata odds/Paid Random Items ni `PolicyService`: **manda `ROBLOX/research/03`**.
  6. Conflictos de estilo (`--!strict` frente a `.luaurc` en `nonstrict`) y flujo (`multi_edit` frente a
     archivos con Rojo): ver `LOCAL-NOTES.md`.
- Limite de esta revision: busqueda automatica de patrones sobre todos los archivos y lectura atenta de
  `SKILL.md` y de las guias de monetizacion, datos, seguridad del agente, MCP y ejemplos. Las otras
  guias (red, rendimiento, UI, migracion, fundamentos, formatos) se revisaron por patrones y encabezados.
  No es una auditoria humana.

### 2.3 Riesgos residuales

- **Es contenido de un tercero que el agente trata como instrucciones.** Mitigacion: commit fijado,
  hashes, sin scripts, y reglas de precedencia en `LOCAL-NOTES.md`. Si el contenido cambiara en una
  actualizacion, repetir la revision.
- **Datos que caducan**: Roblox publica cada semana; la skill esta verificada a 2026-10-17 (Studio
  0.743). Cifras de monetizacion y APIs nuevas pueden quedar viejas. Contrastar con la documentacion
  oficial cuando importe (y con `ROBLOX/research/02` y `ROBLOX/research/03`).
- **Coste de contexto**: `SKILL.md` ocupa ~26 KB y su descripcion pide cargarla en "cualquier tarea de
  Roblox". Aceptado; por eso no se instalan skills solapadas.
- **Nombre de carpeta distinto del `name`** (`roblox-dev` frente a `roblox-dev-skill`): funciona en
  Claude Code; un agente estricto podria ignorarla (arreglo en `LOCAL-NOTES.md`, nota A9).
- **No se instalo `metadata.json`**: el "chequeo de frescura" de la skill no corre; la frescura se
  controla a mano con `PROVENANCE.md`.
- **Symlink en Windows**: si se clona sin soporte de symlinks, `.claude/skills/roblox-dev` queda como un
  archivo de texto y la skill no se encuentra. Solucion en `setup-en-tu-pc.md`.

### 2.4 Como actualizar

No usar los instaladores ni el "Manual Knowledge Update" de la skill (edita sus archivos y rompe la
procedencia). Procedimiento manual y revisado:

1. En un directorio **nuevo y vacio fuera del repo**: `git clone https://github.com/MSayib/roblox-dev-skill <DIR>`
   y anotar `git rev-parse HEAD`. Si quieres comparar con la version actual, clona con mas historial
   (`--depth 50`) y ejecuta `git diff 4a35b01cb07eb237081bee705455e19db37342d8 HEAD -- SKILL.md references LICENSE`.
2. Leer el diff entero como contenido no confiable (mismas busquedas que en `PROVENANCE.md`: ordenes de
   ejecucion remota, permisos, `settings`, `CLAUDE.md`, Unicode invisible, dominios nuevos). Mirar tambien
   `git diff --stat` por si aparecieron carpetas nuevas (`.claude-plugin/`, hooks).
3. Si es seguro, copiar **solo** `SKILL.md`, `LICENSE` y `references/` encima de
   `ROBLOX/skills/roblox-dev/` (sin tocar `PROVENANCE.md` ni `LOCAL-NOTES.md`).
4. Actualizar `PROVENANCE.md` (commit, fecha, version, hashes con `sha256sum SKILL.md LICENSE references/*.md`)
   y revisar `LOCAL-NOTES.md` (las discrepancias pueden haber cambiado).
5. Comprobar el frontmatter (`name`, `description`) y reiniciar Claude Code para que recargue la skill.
6. Revisar el cambio con `git diff` antes de hacer commit.

Cadencia sugerida: al empezar cada juego nuevo, o cuando Studio cambie de version mayor. No hace falta cada
semana.

## 3. `roblox-optimum` (comprobador estatico, opcional)

### 3.1 Datos del paquete (npm view y tarball, 2026-10-20)

| Campo | Valor |
|---|---|
| Paquete | `roblox-optimum` 1.14.0 (publicada 2026-10-18), MIT, autor unico `andrian-syh` |
| Antiguedad | Creado 2026-09-05; 26 versiones en seis semanas. **Muy nuevo y de adopcion minima** (el informe 04 cuenta 1 estrella) |
| Dependencias | **0**. Sin scripts `preinstall`/`postinstall`/`prepare` (solo `test`). Node >= 22 |
| Tarball | 73 archivos, 288 729 bytes. `npm pack` descargado a un directorio nuevo; `sha512` y `shasum` calculados a mano **coinciden** con los del registro |
| Integridad | `sha512-WTxBg1UsgKD5GlPlNi/RQfD7GPMxnzlsxnP4XJKXHmu6eiVgkYu/yGJQ280sdsc+Jxn4xZ5p2OiYEXf7qUZhyQ==` |
| Procedencia | El registro declara firmas y atestacion SLSA. **No pude verificarlas** (`npm audit signatures` fallo por la red de la sesion): [NO VERIFICADO] |

### 3.2 Revision del codigo publicado

- `roblox-optimum --check <rutas>` (`scripts/roblox-optimum.mjs` + `scripts/lib/checker.mjs`): solo
  **lee** archivos `.lua`/`.luau` (`readFileSync`, `readdirSync`, `statSync`), aplica expresiones regulares y
  escribe el informe en stderr. **No usa red, no escribe nada y no lanza procesos.** Si existe, lee la cache
  `~/.cache/roblox-optimum/currency-overlay.json` (datos validados); no existia en esta maquina.
  Con `ROBLOX_OPTIMUM_OFFLINE=1` y `ROBLOX_OPTIMUM_CACHE_DIR=<dir inexistente>` no hay ningun efecto.
- Lo que **no** hay que usar, porque escribe o llama a la red:
  - `install` / `install --global` / `uninstall`: escriben reglas, hooks, un hook de Git `pre-commit`,
    skills y registros MCP en el proyecto o en el directorio personal.
  - `sync`: descarga el volcado de la API desde `raw.githubusercontent.com` y `api.github.com` y escribe la cache.
  - `--session`, `--hook ...`, `--prompt`, `--pre-write`: pensados para hooks de agente; `--session` lanza un
    `sync` en segundo plano si la cache esta vieja.
  - Servidor MCP `roblox-mcp` y los `mcp.json`/`hooks.json` del paquete: usan `npx -y -p roblox-optimum@latest`
    (version **sin fijar**).
  - Plugin del marketplace de Claude Code (`/plugin install roblox-optimum@...`): trae skills, subagente y
    hooks, solapados con nuestra skill.
- No encontre `eval`, `new Function`, ni ejecucion de shell con entrada externa. Los unicos procesos que
  lanza son: `node --test` (`--selftest`), un `sync` en segundo plano (`--session`), `git rev-parse` (en
  `install`) y el lanzador del `StudioMCP` para Antigravity. Variables de entorno leidas: `ROBLOX_OPTIMUM*`
  (y `LOCALAPPDATA` en ese lanzador). Revision por busqueda de patrones y lectura de `roblox-optimum.mjs`,
  `currency-sync.mjs` y partes de `checker.mjs`; `install.mjs`, `hooks.mjs`, `doctor.mjs` y `catalog.mjs` solo
  por patrones.

### 3.3 Veredicto

Razonable **solo como comprobador opcional de solo lectura**, con la version fijada y solo `--check`.
Complementa a StyLua, Selene y `luau-lsp analyze` (no los sustituye): detecta APIs obsoletas (`wait`, `spawn`,
`:connect()`, `Body*`...), `yield` dentro de `UpdateAsync`, bucles que congelan el hilo y **varias asignaciones
a `ProcessReceipt`**. Es heuristico (regex sobre texto): puede dar falsos positivos y no revisa logica.
Mantenimiento: un unico autor, muy reciente. Si algun dia desaparece, no perdemos nada (no esta en el
camino critico).

### 3.4 Como fijar la version y usarlo

Requiere Node.js 22 o superior. Comprobar la integridad antes de la primera vez:

```
npm view roblox-optimum@1.14.0 dist.integrity
# debe imprimir: sha512-WTxBg1UsgKD5GlPlNi/RQfD7GPMxnzlsxnP4XJKXHmu6eiVgkYu/yGJQ280sdsc+Jxn4xZ5p2OiYEXf7qUZhyQ==
```

Uso puntual, version fijada (probado en Linux con Node 22.22 el 2026-10-20; la salida con hallazgos devuelve
codigo 1):

```
ROBLOX_OPTIMUM_OFFLINE=1 npx --yes --ignore-scripts --package=roblox-optimum@1.14.0 roblox-optimum --check ROBLOX/packages
```

En PowerShell: `$env:ROBLOX_OPTIMUM_OFFLINE="1"` en una linea y el `npx ...` en otra. Equivalente al
`npx roblox-optimum --check src/` del informe, pero con `@1.14.0` y sin dejar el paquete suelto en `@latest`.

Alternativa con candado (recomendada para CI): `npm install --save-dev --save-exact --ignore-scripts roblox-optimum@1.14.0`
crea `package-lock.json` con la integridad; luego `npx roblox-optimum --check ...` usa esa copia. Se prueba
igual en una carpeta nueva; si se hace dentro del repo hay que acordar donde vive el `package.json`.

Cuando se quiera subir de version: `npm pack roblox-optimum@<nueva>` a un directorio nuevo, extraer, comparar
con `diff -r` contra la version revisada, mirar de nuevo `package.json` (scripts, dependencias) y los usos de
red/escritura (seccion 3.2), y solo entonces cambiar el numero.

### 3.5 Resultados observados

- Sobre una muestra sintetica con `:connect()` y `wait()`: los detecta (2 hallazgos, codigo 1).
- Sobre `ROBLOX/packages` (14:30 UTC: `Net.luau`, `Economy.luau` y `Odds.luau`; otro agente lo esta
  construyendo): **limpio, 0 hallazgos, codigo 0.** No se modifico nada. Repetir cuando haya mas codigo.
- Sobre `ROBLOX/tools/testkit` y `ROBLOX/tools/examples` (solo lectura): da **falsos positivos esperables**: la regla de
  "`ProcessReceipt` asignado en varios archivos" salta con los mocks y specs, y marca un `UpdateAsync` de un
  spec de mocks. Conclusion: ejecutarlo sobre codigo de juego (`ROBLOX/packages`, `ROBLOX/games/*/src`), no
  sobre `ROBLOX/tools/`.

## 4. Politica de seguridad para el MCP de Studio (recordatorio)

Fuente: doc oficial `studio/mcp.md` y README del plugin oficial, leidos el 2026-10-20 [VERIFICADO].

- Conectar solo clientes de confianza: pueden leer y modificar tus lugares abiertos.
- No todo cambio se puede deshacer: guarda o publica una version del lugar antes de tareas grandes.
- Aprobar a mano `execute_luau`, `multi_edit`, `insert_asset`, `generate_*`, `upload_image`, `start_stop_play`,
  `subagent` y las de entrada simulada. Solo las de lectura pueden ir en lista permitida.
- Sin claves, cookies ni tokens en archivos, en el chat ni en scripts replicados.

## 5. Que NO se instalo y por que

Decision basada en `ROBLOX/research/04-ia-studio-mcp-skills.md` §5 y §7 (lectura de READMEs del 2026-10-20 por
otro agente). **Hoy no se clonaron ni se revisaron estos repositorios**; las cifras son del informe y
[NO VERIFICADO] por mi.

| Proyecto | Por que no |
|---|---|
| `AshExplained/roblox-skills` (34 o 40 skills) | Demasiado contexto y solapa con la skill base; sus skills de "negocio" (economia, monetizacion, live ops) podrian contradecir nuestras reglas (odds, sin urgencia falsa). `setup-roblox-skills` **escribe en tu `CLAUDE.md`**, justo lo que no queremos automatizar. 6 commits, inconsistencias internas (40 frente a 34), "battle-tested" sin evidencia. Revisitar tras un juego piloto |
| `brockmartin/roblox-game-skill` | Sin licencia visible; modo "Full" depende de `boshyxd/robloxstudio-mcp` (archivado); 3 commits |
| `gogolumo/rbsmithy-roblox-claude-skill` | Modelo freemium (edicion Pro de pago); solapa con la skill base |
| `m4bwav/roblox-agent` | **Candidato para despues**: `rbx_check.py` (comprobaciones) y `rbx_cloud.py` (Open Cloud). Declara no haberse probado con Studio real ni con Open Cloud real; 2 estrellas; incluye scripts Python y plugin con 5 skills. Posponer hasta tener un juego piloto y revisar su codigo antes de usarlo |
| `Roblox/roblox-studio-agent-plugin` | Oficial y recomendado, pero se instala en tu PC (`/plugin`), no en esta sesion sin Studio. Su `SECURITY.md` y `plugin.json` (leidos hoy) son coherentes: sin codigo propio, solo lanza el `StudioMCP` de Studio; descarga de Studio solo desde `setup.rbxcdn.com` y con una aprobacion. Recomendacion mia: elegir **o** este plugin **o** Quick connect, no ambos, para no duplicar el servidor ([NO VERIFICADO] que ambos a la vez causen problemas) |
| `roblox-optimum` como plugin, hooks o MCP | Ver 3.2: escriben configuracion y usan `npx ...@latest` sin fijar. Solo se admite `--check` |
| MCP de terceros (`boshyxd/robloxstudio-mcp` archivado, `Chrrxs/robloxstudio-mcp`, otros) | Ejecutan codigo arbitrario en tu Studio y llegan por `npx`/GitHub Releases (cadena de suministro; el caso boshyxd acabo con el autor sin acceso a su paquete). El MCP integrado de Studio cubre lo necesario. La propia skill oficial de Roblox dice evitar MCP de terceros y paquetes `npx` |
| `Roblox/studio-rust-mcp-server` | Archivado desde 2026-04-03 |
| Instaladores `curl ... \| bash` / `irm ... \| iex` de MSayib | Ejecutan codigo remoto con tus permisos; se instalo a mano tras leerlos |
| `~/RobloxDocs` (volcado local de la API) | Lo crea el instalador de MSayib y su monitor hace peticiones de red; no se usa. La documentacion se consulta con `http_get` de Studio o por la red |
| Context7 / `npx ctx7@latest` | Paquete sin fijar; solo con aprobacion explicita |
| Pesos de Cube 3D en un pipeline propio | Licencia de investigacion en el LICENSE leido (`ROBLOX/research/04` §3). Usar `generate_mesh` dentro de Studio |
