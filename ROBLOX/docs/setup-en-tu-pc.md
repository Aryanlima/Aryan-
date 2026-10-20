# Montar todo en tu PC (Windows o macOS), paso a paso

Fecha: 2026-10-20. Para alguien que no sabe programar mucho. Idioma: espanol.

Esta guia te lleva de "no tengo nada instalado" a "Claude Code conectado a Roblox Studio, con el
primer juego abierto". Cuenta con unos 60 a 90 minutos la primera vez.

## Como leer las etiquetas

Cada comando lleva una de estas etiquetas justo encima:

- **[VERIFICADO EN DOC OFICIAL]**: lo lei el 2026-10-20 en la documentacion oficial (Roblox `creator-docs`,
  README del plugin oficial de Roblox, o la documentacion de Claude Code de Anthropic). Entre parentesis va la fuente.
- **[NO VERIFICADO]**: no esta en documentacion oficial o no pude abrirla. Suele ser un comando estandar
  de Git o de PowerShell, o viene del README de una herramienta de terceros. Si falla, mira la seccion 11.

Importante: esta guia se escribio desde un servidor Linux sin Roblox Studio. **Ningun paso se ejecuto en
Windows ni en macOS.** Los menus de Studio cambian a menudo; si un nombre no coincide, busca el parecido.

## Antes de empezar

- Windows 10 (version 1809 o mas nueva) o macOS 13 o mas nuevo; 4 GB de RAM o mas; internet
  [VERIFICADO EN DOC OFICIAL] (Claude Code, `setup`).
- Una cuenta de **Roblox**.
- Una cuenta de **Claude** de pago (Pro, Max, Team o Enterprise) o una cuenta de Console. El plan gratuito
  de claude.ai **no** incluye Claude Code [VERIFICADO EN DOC OFICIAL] (Claude Code, `setup`).
- Una cuenta de **GitHub** con acceso al repositorio `https://github.com/Aryanlima/Aryan-` (si es privado).

Palabras que veras:

- **Terminal**: ventana donde se escriben comandos. En Windows se llama **PowerShell** (menu Inicio, escribe
  "PowerShell", abrela). En macOS se llama **Terminal** (pulsa Cmd+Espacio, escribe "Terminal", Enter).
  Para ejecutar un comando: lo pegas y pulsas Enter.
- **Repositorio**: la carpeta del proyecto con todo su historial (Git).
- **MCP**: el "cable" que deja a Claude ver y manejar tu Studio abierto.

## 1. Instalar Roblox Studio

**[VERIFICADO EN DOC OFICIAL]** (Roblox `studio/setup.md`)

1. Ve a https://create.roblox.com/docs/studio/setup y pulsa el boton de descargar Studio.
2. En la ventana emergente pulsa **Download Studio**.
3. Abre el instalador que se descargo: en Windows es `RobloxStudio.exe`, en macOS `RobloxStudio.dmg`
   (haz doble clic; en macOS arrastra Studio a Aplicaciones si te lo pide).
4. Al terminar pulsa **Launch Studio** e inicia sesion con tu cuenta de Roblox.
5. Comprueba que puedes crear un lugar nuevo (**New Experience**, plantilla **Baseplate**). Luego cierra ese lugar de prueba.

Mantenlo actualizado: si ves el boton **Update** arriba a la derecha, pulsalo (te pedira guardar y cerrar).

## 2. Instalar Git

Git guarda las versiones de tu proyecto y lo descarga desde GitHub.

**Windows.** Opcion facil: descarga el instalador desde https://git-scm.com/install y pulsa Siguiente en todo.

**[VERIFICADO EN DOC OFICIAL]** (Roblox `ai/coding-harness.md`, paso 1: tambien se puede con WinGet)

```
winget install --id Git.Git -e --source winget
```

**macOS.**

**[VERIFICADO EN DOC OFICIAL]** (Roblox `ai/coding-harness.md`, paso 1; requiere tener Homebrew, https://brew.sh)

```
brew install git
```

Si no tienes Homebrew, escribe `git --version` en Terminal: macOS suele ofrecer instalar las "herramientas de
linea de comandos" y con eso basta. **[NO VERIFICADO]** (comportamiento habitual de macOS, no lo vi en doc oficial).

**[NO VERIFICADO]** (comando estandar de Git) Comprueba que quedo instalado (cierra y vuelve a abrir la terminal):

```
git --version
```

**Solo Windows, hazlo ANTES de descargar el proyecto (seccion 5).** El proyecto usa un "acceso directo"
(symlink) para que Claude encuentre su skill de Roblox. Windows solo lo crea bien si activas el modo
desarrollador:

1. Configuracion de Windows, **Sistema**, **Para programadores** (o "Privacidad y seguridad", "Para
   programadores"), activa **Modo de desarrollador**. **[NO VERIFICADO]** (la ruta del menu cambia entre versiones de Windows).
2. En PowerShell: **[NO VERIFICADO]** (comando estandar de Git)

```
git config --global core.symlinks true
```

## 3. Instalar Visual Studio Code

El editor donde veras los archivos.

**[VERIFICADO EN DOC OFICIAL]** (Roblox `ai/coding-harness.md`, paso 1)

1. Descargalo desde https://code.visualstudio.com e instalalo (Siguiente en todo).
2. Abre VS Code, ve a Extensiones (icono de cuadraditos a la izquierda) y busca **Claude Code** (de Anthropic).
   Enlace: https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code . Instalala.
3. Pulsa el icono de Claude en la barra lateral, inicia sesion con tu cuenta de Anthropic y comprueba que se
   abre el panel de chat (paso 2 de la misma guia de Roblox).

(Si prefieres Cursor, la guia de Roblox dice que tambien sirve; aqui seguimos con VS Code.)

## 4. Instalar Claude Code (en la terminal)

Claude Code es el asistente que escribe el codigo. La extension de VS Code (seccion 3) y la terminal pueden
convivir; esta seccion instala el programa de terminal `claude`.

**[VERIFICADO EN DOC OFICIAL]** (Anthropic, Claude Code `setup`, leida el 2026-10-20)

Windows (PowerShell):

```
irm https://claude.ai/install.ps1 | iex
```

macOS (Terminal):

```
curl -fsSL https://claude.ai/install.sh | bash
```

Esos dos comandos descargan y ejecutan el instalador de Anthropic directamente. Si prefieres no ejecutar
un script descargado, la misma documentacion ofrece estas alternativas.

**[VERIFICADO EN DOC OFICIAL]** (Anthropic, Claude Code `setup`)

```
winget install Anthropic.ClaudeCode
```

(Windows, WinGet; no se actualiza solo: `winget upgrade Anthropic.ClaudeCode` de vez en cuando)

```
brew install --cask claude-code
```

(macOS, Homebrew; no se actualiza solo: `brew upgrade claude-code`)

**[VERIFICADO EN DOC OFICIAL]** (Anthropic, Claude Code `setup`) Cierra y abre la terminal, y comprueba:

```
claude --version
```

Debe salir un numero de version. Si dice que `claude` no se reconoce, mira la seccion 11. Para iniciar sesion
la primera vez, ejecuta `claude` y sigue las indicaciones del navegador. En Windows, Git (seccion 2) es
recomendable para que Claude Code pueda usar su herramienta Bash.

## 5. Descargar el proyecto y dejarlo en el Escritorio como carpeta ROBLOX

El repositorio entero se descarga en una carpeta **ROBLOX** del Escritorio. Dentro habra **otra** carpeta
`ROBLOX/` (con los juegos, la documentacion y las skills): es normal, la de fuera es la raiz del
repositorio y la de dentro es la parte de Roblox. Resultado:

```
Escritorio/
  ROBLOX/                     <- raiz del repositorio (aqui abres VS Code y Claude Code)
    CLAUDE.md                 <- reglas del proyecto para Claude
    .claude/skills/roblox-dev <- acceso directo a la skill de Roblox
    research/  tools/  marketing/
    ROBLOX/                   <- la parte de Roblox
      docs/  games/  packages/  skills/ ...
```

**[NO VERIFICADO]** (comandos estandar de Git y PowerShell; no pude abrir el repositorio desde mi entorno)

Windows (PowerShell). El Escritorio a veces esta dentro de OneDrive; este comando lo localiza solo:

```
cd ([Environment]::GetFolderPath("Desktop"))
git clone https://github.com/Aryanlima/Aryan- ROBLOX
cd ROBLOX
```

macOS (Terminal):

```
cd ~/Desktop
git clone https://github.com/Aryanlima/Aryan- ROBLOX
cd ROBLOX
```

(Si el repositorio es privado, Git abrira una ventana del navegador para que inicies sesion en GitHub.)

Comprueba que el acceso directo de la skill se creo bien.

**[NO VERIFICADO]** (comandos estandar de shell)

Windows (PowerShell):

```
Test-Path .claude\skills\roblox-dev\SKILL.md
```

macOS (Terminal):

```
ls .claude/skills/roblox-dev/SKILL.md
```

Debe salir `True` (Windows) o el nombre del archivo (macOS). Si no sale, no entres en panico: mira
"La skill de Roblox no aparece" en la seccion 11.

Abre la carpeta en VS Code: **File, Open Folder**, y elige la carpeta `ROBLOX` del Escritorio (la de fuera).
Si ves el repositorio sin las carpetas `ROBLOX/docs` o `ROBLOX/skills`, estas en la rama equivocada: seccion 11.

## 6. Instalar Rokit y las herramientas (Rojo, StyLua, Selene, luau-lsp, Lune)

**Rokit** es un "gestor de herramientas": descarga y mantiene las versiones exactas que usa el proyecto.
Las herramientas son:

- **Rojo**: sincroniza archivos del disco con Studio.
- **StyLua**: ordena el codigo (formato).
- **Selene**: revisa el codigo (errores de estilo y bugs tipicos).
- **luau-lsp**: entiende el codigo Luau (tipos, errores) y lo comprueba con `analyze`.
- **Lune**: ejecuta codigo Luau fuera de Roblox, para las pruebas automaticas.

Todo esto es software de terceros (no de Roblox): los comandos vienen de sus README, leidos el 2026-10-20.

### 6.1 Instalar Rokit

**[NO VERIFICADO]** (README de Rokit, repositorio `rojo-rbx/rokit`; no es documentacion oficial de Roblox)

Windows, opcion mas simple y sin pegar scripts: abre https://github.com/rojo-rbx/rokit/releases/latest,
descarga `rokit.exe` y **haz doble clic** (Rokit se instala solo). Opcion por PowerShell:

```
Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression
```

macOS (Terminal):

```
curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
```

Cierra y abre la terminal. **[NO VERIFICADO]** (el README dice que `rokit --help` da la lista de comandos):

```
rokit --help
```

### 6.2 Instalar las herramientas del proyecto

Dentro de la carpeta `ROBLOX` del Escritorio (la raiz del repo):

**[NO VERIFICADO]** (README de Rokit: `rokit install` instala "todas las herramientas del proyecto"; usalo solo si el
repositorio ya trae un archivo `rokit.toml`; Rokit puede pedirte confirmar que confias en cada herramienta)

```
rokit install
```

Si el repositorio **aun no tiene** `rokit.toml`, crea uno y anade las herramientas (esto fija las versiones
actuales en `rokit.toml`; despues se sube a Git para que todos usen las mismas):

**[NO VERIFICADO]** (README de Rokit: comandos `init` y `add`; los nombres `usuario/repositorio` salen del informe
`research/04` y de los repos de cada herramienta)

```
rokit init
rokit add rojo-rbx/rojo
rokit add JohnnyMorganz/StyLua
rokit add Kampfkarren/selene
rokit add JohnnyMorganz/luau-lsp
rokit add lune-org/lune
```

Comprueba que cada una responde (si no, cierra y abre la terminal):

**[NO VERIFICADO]** (la opcion `--version` es la habitual; no la vi en cada README)

```
rojo --version
stylua --version
selene --version
luau-lsp --version
lune --version
```

Si todo imprime un numero, listo. No hace falta aprender a usarlas: Claude las ejecuta por ti.

### 6.3 Opcional: comprobador `roblox-optimum`

Es opcional y de un tercero muy nuevo; la evaluacion y el comando con la version fijada estan en
`ROBLOX/docs/skills-instaladas.md`, seccion 3. Requiere Node.js 22 o superior (https://nodejs.org).

## 7. Activar el MCP de Studio y conectar Claude Code

El "MCP" es lo que permite a Claude leer tu juego abierto, jugarlo, ver la consola y hacer capturas.

> **Advertencia oficial:** "MCP clients can read and modify content in your open Roblox places. Make sure to
> only connect clients you trust." Y: "Not every change can be undone from Studio, so save or publish a version
> of your place before asking for bigger changes." **[VERIFICADO EN DOC OFICIAL]** (Roblox `studio/mcp.md` y README del plugin oficial)

### 7.1 Activar el servidor en Studio

**[VERIFICADO EN DOC OFICIAL]** (Roblox `studio/mcp.md`, "Enable the MCP server in Studio")

1. Abre Roblox Studio, inicia sesion y **abre un lugar** (cualquiera, por ejemplo uno nuevo con Baseplate).
2. Abre **Assistant** (boton arriba a la derecha).
3. Pulsa **...** y luego **Manage MCP Servers** (en versiones mas nuevas: **... , Settings, MCP Servers**).
4. Activa **Enable Studio as MCP server**.

### 7.2 Conectar Claude Code: elige UNA de estas dos vias

**Via A: Quick connect (la mas simple).**

**[VERIFICADO EN DOC OFICIAL]** (Roblox `studio/mcp.md`, "Quick connect")

1. En Studio: **Assistant Settings, MCP Servers**, abre el desplegable **Quick connect**.
2. Activa **Claude Code** (aparece si Claude Code ya esta instalado; si no aparece, instalalo y reinicia Studio).
3. Reinicia Claude Code (y Studio si hace falta).

**Via B: plugin oficial de Roblox para Claude Code.**

**[VERIFICADO EN DOC OFICIAL]** (README de `Roblox/roblox-studio-agent-plugin`)

1. En Claude Code escribe `/plugin`, busca **Roblox Studio** e instalalo.
2. Puedes pedirle: "Get me set up with Roblox Studio." (te pregunta una sola vez antes de instalar nada).

Mi recomendacion es usar solo una de las dos vias, para no tener el servidor duplicado **[NO VERIFICADO]**
(el README del plugin no dice nada sobre usar ambas a la vez).

**Via C: manual (solo si A y B no te funcionan).** Anade esta entrada a tu archivo de configuracion MCP:

**[VERIFICADO EN DOC OFICIAL]** (Roblox `studio/mcp.md`, "JSON configuration")

Windows:

```
{
  "mcpServers": {
    "Roblox_Studio": {
      "command": "cmd.exe",
      "args": ["/c", "%LOCALAPPDATA%\\Roblox\\mcp.bat"]
    }
  }
}
```

macOS:

```
{
  "mcpServers": {
    "Roblox_Studio": {
      "command": "/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"
    }
  }
}
```

(Si ya tienes otras entradas en `mcpServers`, separalas con comas: una coma que falta rompe todo el archivo.)

La doc oficial tambien da el comando directo para clientes que lo piden (Windows: `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`;
macOS: `/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`). Para Claude Code, el equivalente seria
`claude mcp add Roblox_Studio -- "/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"` (macOS):
**[NO VERIFICADO]** (sintaxis estandar de `claude mcp add` aplicada a la ruta oficial; no lo ejecute). Prefiere
la via A o B.

### 7.3 Comprobar que funciona

**[VERIFICADO EN DOC OFICIAL]** (Roblox `studio/mcp.md`, "Verify your connection")

1. En Studio: **Assistant, ..., Manage MCP Servers**: debajo de **Enable Studio as MCP server** debe haber un
   indicador **verde** con el numero de clientes conectados.

**[VERIFICADO EN DOC OFICIAL]** (README del plugin oficial, "Verify it worked")

2. Si usaste el plugin (via B), en Claude Code escribe `/mcp`: se ven `plugin:roblox-studio:macos` y
   `plugin:roblox-studio:windows`. **Solo el de tu sistema se conecta; el otro en rojo es normal.**
3. Pidele a Claude: `list my open Roblox Studio windows` (debe nombrar el lugar que tienes abierto).

**[VERIFICADO EN DOC OFICIAL]** (Roblox `ai/coding-harness.md`, paso 9)

4. Prueba de lectura: `Use the Roblox MCP to read the current game tree in Roblox Studio. List what's in Workspace.`
   Es posible que tengas que aprobar el comando o anadir la herramienta a una lista permitida.

### 7.4 Permisos: aprueba a mano lo que cambia cosas

**[VERIFICADO EN DOC OFICIAL]** (README del plugin oficial, lista de herramientas de solo lectura frente a las que cambian cosas)

- Roblox clasifica como **solo lectura**: `list_roblox_studios`, `get_studio_state`, `get_console_output`,
  `script_read`, `script_search`, `script_grep`, `search_game_tree`, `inspect_instance`, `screen_capture`,
  `http_get`, `skill`, `search_asset`, `wait_job_finished`, `store_image`. Mi recomendacion (informe
  `research/04`, 4.5) es permitir "siempre" solo las mas basicas: `list_roblox_studios`, `get_studio_state`,
  `get_console_output`, `script_read`, `search_game_tree`, `inspect_instance` y `screen_capture`.
- **Cambian tu lugar o tu cuenta (aprueba cada vez, nunca "permitir siempre")**: `execute_luau`, `multi_edit`,
  `insert_asset`, `generate_mesh`, `generate_material`, `generate_procedural_model`, `generate_texture`,
  `segment_mesh`, `upload_image`, `start_stop_play`, `character_navigation`, `user_keyboard_input`,
  `user_mouse_input`, `subagent`.

Antes de cada tarea grande: **guarda una version** del lugar (File, Save to Roblox) y haz un commit de Git.
Si hay varias ventanas de Studio abiertas, cierra las que no uses: el MCP apunta a una por su `studio_id` y
equivocarse de lugar es el error mas peligroso.

## 8. Abrir y probar el primer juego: Fish & Fortune

El primer juego es **Fish & Fortune**, en `ROBLOX/games/fish-and-fortune` dentro de la carpeta del
repositorio. **Otro agente lo esta construyendo ahora mismo**, asi que esta guia no describe su contenido:
sigue **su README**.

- Lee primero: [ROBLOX/games/fish-and-fortune/README.md](../games/fish-and-fortune/README.md). Si el enlace no abre,
  el juego aun no se ha subido al repositorio: haz `git pull` mas tarde (seccion 11).

Pasos generales (los detalles exactos, los de su README):

1. Abre Claude Code en la raiz del repositorio: en VS Code, Terminal nueva, y escribe `claude`
   (o usa el panel de Claude Code). **[VERIFICADO EN DOC OFICIAL]** (Anthropic, Claude Code `setup`: "open a terminal in
   the project you want to work in and start Claude Code: `claude`")
2. Dile: `Lee ROBLOX/games/fish-and-fortune/README.md y dime los pasos para abrirlo en Studio.`
3. En Studio abre un lugar nuevo (o el que indique el README) y guardalo donde diga el README (File, Save to File).
   Si el README no lo dice, preguntale a Claude donde guardarlo y si ese archivo debe ir o no a Git; el repositorio
   de ejemplo de Roblox deja fuera de Git los `.rbxlx` (`ai/coding-harness.md`, paso 4), pero lo de este proyecto
   lo decide su `.gitignore`.
4. **Conecta los archivos con Studio. Elige UNA via por juego; no las mezcles** (un solo "escritor" por script):

   **Via 1: Script Sync (la oficial y mas simple).**

   **[VERIFICADO EN DOC OFICIAL]** (Roblox `ai/coding-harness.md`, pasos 5 y 6)

   - En Studio: **File, Beta Features**, busca **Script Sync**, activalo, **Save**, y reinicia Studio. (La doc
     oficial aun lo llama beta; si no lo ves, actualiza Studio.)
   - En el Explorer, clic derecho en cada servicio que use el juego (por ejemplo **ServerScriptService**,
     **ReplicatedStorage**, **StarterPlayerScripts**): **Script Sync, Sync to...** y elige la carpeta que indique el README.
   - Limitacion oficial: **no cubre StarterGui ni StarterPack**; eso lo cubre el MCP.

   **Via 2: Rojo.** Solo si el README del juego dice que usa Rojo.

   **[NO VERIFICADO]** (README de Rojo y del informe `research/04`; su pagina de instalacion, rojo.space, no pude abrirla)

   - Instala el plugin de Rojo en Studio (el informe da `rojo plugin install`, o el archivo `Rojo.rbxm`, o la
     tienda de plugins), y en la raiz del juego ejecuta:

   ```
   rojo serve
   ```

   - En Studio abre el plugin **Rojo** y pulsa **Connect**.

5. Prueba la conexion de Script Sync como hace la doc oficial.

   **[VERIFICADO EN DOC OFICIAL]** (Roblox `ai/coding-harness.md`, pasos 7 y 10)

   Pidele a Claude: `Create a test script at ServerScriptService/Test.server.luau that prints 'Hello from Script Sync!' to the output.`
   y mira que aparece `Test` en el Explorer. Despues pidele que lo borre.

6. Pidele a Claude que juegue y mire la consola (con tu aprobacion de cada herramienta): `Haz un playtest del
   juego, lee la consola y dime si hay errores.`

## 9. Conseguir y poner los IDs de pases y productos

Los pases y productos de desarrollador (los "microtransacciones") se crean en la web de Roblox, y su **ID** se
copia al codigo. **[VERIFICADO EN DOC OFICIAL]** (Roblox `production/monetization/passes.md` y `developer-products.md`)

1. **Publica el juego primero.** En Studio: **File, Publish**, pon nombre, icono, genero y pulsa **Save**
   (Roblox `production/publishing/publish-games-and-places.md`). Sin publicar no se pueden crear pases ni productos.
2. Ve a https://create.roblox.com/dashboard/creations y elige tu juego.
3. **Monetization, Passes** (compra unica y permanente) o **Monetization, Developer Products** (se compra varias
   veces: monedas, pociones...).
4. Pulsa **Create pass** o **Create developer product**. Sube un icono (maximo 512x512, `.jpg`, `.png` o `.bmp`),
   escribe nombre y descripcion, elige categoria y, para productos, el precio en Robux (minimo 1, maximo mil millones).
5. **Copiar el ID:** pasa el raton por la miniatura, pulsa el boton **...** y elige **Copy Asset ID**.
6. **Ponerlo en el juego:** no lo invento aqui. Pidele a Claude: `Segun el README de Fish & Fortune, donde se ponen
   los IDs de pases y productos? Pon estos IDs ahi: ...` y revisa el cambio. Los IDs no son secretos (se ven
   en el juego); **una clave de API, una cookie o una contrasena SI lo son: nunca las pegues en archivos ni en el chat.**

Reglas de oro del proyecto (viven en `CLAUDE.md` y `research/03`):

- Un solo script asigna `ProcessReceipt`, y debe ser **idempotente** (no dar el premio dos veces). Siempre con
  revision humana.
- Si algo es aleatorio y se paga con Robux, las **probabilidades** se muestran antes de comprar. Sin urgencia falsa.

Para pruebas de compra, **no confirmes compras con tu cuenta principal** hasta comprobar en la doc de Roblox si
una compra hecha desde Studio gasta Robux reales: **[NO VERIFICADO]** (no encontre ese dato en la documentacion que lei).

## 10. Hacer un playtest

**[VERIFICADO EN DOC OFICIAL]** (Roblox `studio/testing-modes.md` e `includes/studio/playtest-modes.md`)

En la parte izquierda de la barra superior ("mezzanine") eliges el modo en el desplegable y pulsas **Play**:

| Modo | Atajo | Que hace |
|---|---|---|
| **Test** | F5 | Simula el juego y te pone en un `SpawnLocation` (o cerca de (0, 100, 0)) |
| **Test Here** | (sin atajo) | Igual, pero te pone delante de la camara actual |
| **Run** | F8 | Simula el juego **sin** tu avatar; te mueves con la camara de Studio |
| **Server & Clients** | F7 | Abre un servidor y varios clientes (normalmente 1-2, hasta 8): sirve para probar multijugador |

- Para parar: **Stop** (Shift+F5). Al parar, todo vuelve a como estaba antes de probar.
- En **Test** y **Test Here** puedes alternar **Client / Server** con el boton de la barra (borde azul = cliente,
  verde = servidor). En la ventana **Output**, los mensajes salen azules (cliente) o verdes (servidor).
- Probar en varios modos es importante porque el juego funciona con modelo cliente-servidor.
- **Por defecto, un juego probado en Studio no puede usar DataStores**, y no hay que activar "Enable Studio Access
  to API Services" en un juego ya publicado: accede a los **mismos** DataStores que el juego real y podrias
  sobrescribir datos de jugadores (Roblox `cloud-services/data-stores/index.md`). Si lo necesitas, usa una copia
  del juego solo para pruebas.

Pidele a Claude que haga el playtest con el MCP (`start_stop_play`, `get_console_output`, `screen_capture`), pero
**juega tu tambien el resultado**: el playtest automatico no sustituye a una persona, sobre todo en compras y datos.

## 11. Que hacer si algo falla

| Sintoma | Que probar |
|---|---|
| `git`, `claude`, `rokit`, `rojo`... "no se reconoce el comando" / "command not found" | Cierra la terminal y abre una nueva (el sistema recarga la lista de programas). Si sigue, reinstala ese programa. Para `claude`: **[VERIFICADO EN DOC OFICIAL]** (Anthropic) el instalador nativo avisa que si `claude` no se encuentra, su carpeta aun no esta en el PATH; ejecuta `claude doctor` para un diagnostico de solo lectura |
| En PowerShell sale "The token '&&' is not a valid statement separator" o `irm` no se reconoce | **[VERIFICADO EN DOC OFICIAL]** (Anthropic): estas en el tipo de terminal equivocado: `irm ...` es para PowerShell y `curl ... && ...` para CMD |
| El servidor MCP no aparece o las herramientas no estan | **[VERIFICADO EN DOC OFICIAL]** (Roblox `studio/mcp.md`, Troubleshooting): reinicia Studio **y** el cliente; comprueba que la ruta del comando existe; revisa la sintaxis del JSON (una coma o un corchete que falta basta para romperlo) |
| Quick connect no lista Claude Code | **[VERIFICADO EN DOC OFICIAL]** (Roblox `studio/mcp.md`): instala el cliente y reinicia Studio |
| Claude dice que no ve ningun Studio | Abre un **lugar** (no solo la pantalla de inicio), confirma el indicador verde (7.3) y pide `list_roblox_studios` |
| Cambios en el codigo que no llegan a Studio | Estas mezclando vias de sincronizacion o falta conectar el servicio (seccion 8); una sola via por juego. En Script Sync, si Studio lo pide, resuelve el conflicto eligiendo version con cuidado |
| La skill de Roblox no aparece (Windows: el symlink se creo como archivo de texto) | **[NO VERIFICADO]** (comandos estandar). En PowerShell, desde la raiz del repo: `Remove-Item .claude\skills\roblox-dev` y luego `Copy-Item -Recurse ROBLOX\skills\roblox-dev .claude\skills\roblox-dev` (copia la carpeta en vez del acceso directo; hay que repetirlo al actualizar la skill). Mejor: activa el modo desarrollador (seccion 2) y vuelve a clonar |
| No ves `ROBLOX/docs`, `ROBLOX/skills` o `ROBLOX/games` | **[NO VERIFICADO]** (comandos estandar de Git). Puede que el trabajo este en otra rama o que aun no se haya subido: `git pull`; `git branch -a` lista ramas; `git checkout <nombre-de-rama>` cambia. Si dudas, pidele a Claude: `Dime en que rama estoy y donde esta el trabajo mas reciente` |
| `git clone` pide usuario/contrasena o falla | **[NO VERIFICADO]**. Si el repo es privado, inicia sesion en GitHub cuando Git abra el navegador. No pegues tu contrasena ni tokens en el chat |
| Studio se cuelga | Un `execute_luau` con un bucle infinito puede colgar Studio y no tiene limite de tiempo: hay que cerrarlo a la fuerza y se puede perder lo no guardado. Por eso se guarda antes de cada tarea grande (7.4) |
| Un cambio de Claude rompio el lugar y no se puede deshacer | Recupera la version guardada o publicada de Studio, o vuelve al ultimo commit de Git (`git status` y `git diff` para ver que cambio). Nunca borres cosas sin tener una copia |
| `roblox-optimum` o `npx` fallan | Necesitan Node.js 22 o superior (`node --version`). Es opcional; el proyecto funciona sin el |
| Cualquier otra cosa | Copia el mensaje de error **completo** (sin claves ni datos personales) y pegaselo a Claude Code, diciendole tu sistema (Windows o macOS) y en que paso estabas |

## 12. Resumen de comprobaciones (lista rapida)

- [ ] Studio instalado y con sesion iniciada; puedo abrir un lugar.
- [ ] `git --version`, `claude --version` y `rokit --help` responden.
- [ ] El proyecto esta en `Escritorio/ROBLOX` y existe `.claude/skills/roblox-dev/SKILL.md`.
- [ ] `rojo --version`, `stylua --version`, `selene --version`, `luau-lsp --version`, `lune --version` responden.
- [ ] Studio: **Enable Studio as MCP server** activo, indicador verde, y Claude lista mi Studio.
- [ ] Las herramientas que cambian cosas piden mi aprobacion; guarde una version antes de empezar.
- [ ] Abri el README de Fish & Fortune y segui sus pasos.
