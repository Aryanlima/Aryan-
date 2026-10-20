# Verificación de estructura de Fish & Fortune (sin Studio)

Fecha: 2026-10-20. Alcance: `ROBLOX/games/fish-and-fortune/` (`src/server`, `src/client`, `src/shared`, `default.project.json`) y los paquetes de `ROBLOX/packages/` que monta. Objetivo: cazar **aquí** los errores de estructura que normalmente solo aparecen al abrir Studio (rutas de `require` que no resuelven, scripts mal mapeados por Rojo, remotos que no coinciden, objetos que el cliente busca y no existen, propiedades mal escritas) y dejar al playtest del PC una lista corta y concreta de lo que de verdad necesita el motor.

**Cómo leer las etiquetas:** **[EJ]** = comprobado ejecutando algo (herramienta o prueba) y, cuando se dice, con una mutación que prueba que la comprobación detecta el fallo. **[LEÍDO]** = razonado leyendo el código. **[DOC]** = contrastado con la documentación oficial (`Roblox/creator-docs`, leída el 2026-10-20). **[STUDIO]** = no se puede saber sin Studio. Nada de esto sustituye al playtest.

## 1. Veredicto

**La estructura es coherente: no se encontró ninguna ruta rota, ningún script mal mapeado ni ningún remoto desparejado.** Los 35 `require` por instancia (21 del servidor y 14 del cliente) resuelven a un `ModuleScript` que existe en el árbol construido por Rojo, y los 23 remotos coinciden entre `Remotes.luau`, el servidor y el cliente [EJ].

Lo que sí había (corregido, con prueba que falla antes y pasa después):

* los `require` de `Main.server` y `Main.client` pasaban por una función con los nombres en variables, así que **ningún analizador podía comprobarlos** (ST-01);
* dos carreras al entrar/reaparecer que dejaban la caña equivocada o al jugador en el Lago aunque su zona guardada fuera otra (ST-03);
* una espera de red (`SubscribeAsync`) en el hilo de arranque del servidor (ST-02);
* un cliente que se quedaba mudo si el servidor no llegaba a crear los remotos (ST-04).

Nada de esto toca dinero ni DATA-01/MINI-01. No se marcó ningún `REVIEW(money)` nuevo.

## 2. Qué se verificó y cómo

| Qué | Cómo | Etiqueta |
|---|---|---|
| El árbol que genera Rojo (servicios, carpetas, clase de cada script, `RunContext`, `Disabled`) | `rojo build` → `.rbxl` → `@lune/roblox` (`deserializePlace`); `tests/ProjectStructure.spec.luau` (a), (b), (d) | [EJ] |
| Cada `require(...)` del código existe en la ruta que usa | luau-lsp con el **sourcemap de Rojo** (`tools/lint.sh`) **y** la prueba (c): escanea los fuentes del lugar construido y evalúa cada ruta contra el árbol (`script.Parent`, `:WaitForChild`, alias `local`); lo que no sabe evaluar **falla** | [EJ] |
| El cliente no depende de módulos de servidor (ni al revés); no hay módulos huérfanos ni nombres duplicados | prueba (c)/(d) | [EJ] |
| Remotos: lo que registra el servidor, lo que dispara, lo que conecta el cliente y lo que envía == `shared/Remotes.luau` | prueba (e) | [EJ] |
| `game:GetService("X")` e `Instance.new("X")` con texto literal nombran servicios/clases reales | prueba (g) con la base de reflexión de Roblox de Lune (0.741.19). luau-lsp **no** detecta un `GetService("Nombre")` mal escrito (comprobado), por eso hace falta | [EJ] |
| `WorldBuilder` (lo primero que ejecuta `GameService.start`, y que **no tenía ninguna prueba**) crea lo que busca el cliente | prueba (f): se ejecuta sobre un `DataModel` real de Lune; cada propiedad/enum se valida contra la base de reflexión. Comprueba `Workspace.World/<zona>/{Spawn,CastTarget,Sign}`, `SpawnLocation`, atributos `LocaleKey` ES/EN | [EJ] |
| El `Main.client.luau` **real**, sus 14 `require` y la interfaz completa (HUD, minijuego, tarjeta de captura, banner, tienda, cañas, bestiario, temporada, probabilidades, códigos) con el estado y las ofertas **reales** que produce el servidor, en ES y EN | `tests/ClientBoot.spec.luau`: ejecuta el script del lugar construido contra instancias "fachada" cuyas propiedades se validan una a una con la base de reflexión; el estado sale del arnés de `GameService` | [EJ] |
| Los tipos de las rutas (`require` tipados, sin `any`) | luau-lsp con sourcemap sobre los 36 archivos `.luau` del juego (src + tests) | [EJ] |
| Detecta de verdad (mutaciones) | 8 mutaciones inyectadas a mano (require con nombre mal, remoto renombrado, propiedad mal escrita en `Menus`, carpeta `Shared` renombrada, `GetService` mal escrito, propiedad mal en `WorldBuilder`, campo de estado mal en `Hud`, módulo de servidor requerido desde el cliente): **las 8 hacen fallar** `ProjectStructure` y/o `ClientBoot`; y `lint.sh` falla con `Unknown require` ante un nombre mal escrito | [EJ] |
| Servicios solo de servidor/cliente (`ConfigService`, `MessagingService`, `AnalyticsService`, `PolicyService`, `DataStoreService` solo en el servidor; `LocalizationService`, `ContextActionService`, `RunService.RenderStepped` solo en el cliente) | lectura de todos los `GetService` + doc oficial de `ConfigService` ("Configs can only be accessed by game servers"; cede; lanza error si no hay configuración y no había otra previa) | [LEÍDO] [DOC] |
| Firma de las llamadas a `AnalyticsService`, `MarketplaceService`, `PolicyService`, `MessagingService`, `DataStore` | contraste con `globalTypes.d.luau` (volcado de la API de Roblox) | [EJ] |
| `Enum.AnalyticsEconomyFlowType.{Source,Sink}`, `Enum.ProductPurchaseDecision.{PurchaseGranted,NotProcessedYet}`, `Enum.InfoType.{Product,GamePass}` existen | base de reflexión de Lune | [EJ] |

**Qué sale de `rojo build`** [EJ]: `ServerScriptService.Server.Main` es un `Script` con `RunContext = Legacy` y `Disabled = false` (se ejecuta porque está en `ServerScriptService`); `StarterPlayer.StarterPlayerScripts.Client.Main` es un `LocalScript` (`Legacy`, no deshabilitado); los otros 28 son `ModuleScript`; no hay ningún otro `Script`/`LocalScript`. `Workspace` y `Lighting` salen vacíos (`$ignoreUnknownInstances`): el mundo lo crea `WorldBuilder` al arrancar.

### Datos oficiales usados [DOC]

* `RemoteEvent` fiable: "Roblox queues it and delivers it, in order, as soon as a handler connects" (`scripting/events/remote.md`). Por tanto el aviso de bienvenida/offline que el servidor envía en `onLoaded` **no se pierde** si llega antes de que el cliente conecte; además el cliente pide el estado con `RequestState` cuando ya está listo.
* `Script` con `RunContext` por defecto (`Legacy`) "only runs if it is in a server container" (`ServerScriptService`, `Workspace`) (`scripting/locations.md`). `LocalScript` se lista en `StarterPlayerScripts`.
* `LocalizationService.RobloxLocaleId`: solo lectura, seguridad `None`, formato `en-us` (`LocalizationService.yaml`); el código ya lo envuelve en `pcall`.
* `ConfigService:GetConfigAsync()`: solo servidor, cede y lanza error si no carga y no hay configuración previa. `LiveOps.refresh` lo llama dentro de `pcall`.
* `ContextActionService:BindAction`: lo ligado después tiene prioridad y `Sink` corta la entrada para los anteriores (ver ST-05).

## 3. Hallazgos

| ID | Severidad | Dónde | Qué falla en Studio | Estado |
|---|---|---|---|---|
| ST-01 | Media (hueco de verificación) | `src/server/Main.server.luau`, `src/client/Main.client.luau` | Los 35 `require` pasaban por `local requireModule: (ModuleScript) -> any = require` y `load(contenedor, "Nombre")`: el nombre iba en una variable, así que luau-lsp (sin sourcemap) no podía comprobar nada y un nombre mal escrito (o una carpeta renombrada en `default.project.json`) solo habría aparecido al jugar: el servidor no arranca / el cliente sin interfaz, con un error de `WaitForChild` o "Infinite yield". Los módulos además llegaban tipados como `any` | **Corregido.** `require(contenedor:WaitForChild("Nombre"))` con literales; `tools/lint.sh` genera `rojo sourcemap --absolute` por juego y se lo pasa a luau-lsp (que ahora resuelve y tipa cada ruta). Comprobado: las 35 rutas existían (no había ninguna rota) y un nombre mal escrito ahora da `Unknown require`. Pruebas: `ProjectStructure` (c), mutaciones |
| ST-02 | Baja | `src/server/GameService.luau` (`start`) | `liveOps:subscribe(MessagingService, ...)` ejecuta `SubscribeAsync` (cede por red) **en el hilo de arranque**. Un `MessagingService` lento retrasa el resto del arranque: la carga de datos de los jugadores que entran (`manager:attach`), el bucle de pesca automática y los `PlayerAdded`. (`ProcessReceipt` ya está puesto antes, no se afecta) | **Corregido:** va en su propio `task.spawn`, como ya iba la suscripción de los MÍTICOS. Prueba nueva `GameService.spec`: "un MessagingService lento no retrasa el arranque" (falla antes: el reloj simulado avanzaba 60 s) |
| ST-03 | Media (jugabilidad, sin dinero) | `src/server/GameService.luau` (`onCharacter`, `onLoaded`) | Dos carreras entre la carga del perfil y la aparición del personaje. (a) Si el personaje aparece **antes** que el perfil (lo normal con un DataStore real, ~0,2-1 s), `attachRod` no tiene perfil y pone la **caña por defecto**; `onLoaded` no la refrescaba: un jugador que vuelve con la caña de carbono ve una rama de madera hasta que compra/equipa o reaparece. (b) Si el perfil carga **antes** que el personaje, o el jugador muere y reaparece, `teleportToZone` no tiene a quién mover y el jugador sale en el muelle del Lago mientras el HUD dice "Río Cristal": el flotador (`CastTarget` de la zona guardada) queda a 400 studs | **Corregido:** `onLoaded` llama a `refreshRod`; `onCharacter` (diferido) lleva al jugador a su zona guardada si no es el Lago y luego pone la caña. 3 pruebas nuevas en `GameService.spec` (fallan antes, pasan después) |
| ST-04 | Baja | `src/client/Main.client.luau` | `ReplicatedStorage:WaitForChild(Remotes.folderName)` sin tiempo límite: si el arranque del servidor falla (p. ej. una excepción en `WorldBuilder` o en `Data.new`), la carpeta de remotos no existe nunca y el cliente se queda **mudo** (solo `Infinite yield possible` tras 5 s), sin pista de que la causa está en la consola del servidor | **Corregido:** `WaitForChild(Remotes.folderName, 30)` y `error("[FishFortune] el servidor no creo los remotos en 30 s (mira su consola)")`. Prueba nueva en `ClientBoot.spec` ("Servidor que no arrancó") |
| ST-05 | Informativa (diseño) | `src/client/Minigame.luau` (`BindAction("FF_Action", ..., false, Enum.KeyCode.Space)` devolviendo `Sink`) | En PC la barra espaciadora queda ligada a LANZAR/RECOGER **y se sinkea**: según la doc lo ligado después tiene prioridad y `Sink` corta lo anterior, así que **Espacio ya no hace saltar** al personaje. No es un error si es lo que se quiere, pero conviene saberlo | **Abierto:** decisión de Aryan. Se confirma en el playtest (consola del desarrollador → pestaña "Action Bindings") [STUDIO]. Alternativa si molesta: `Pass` o otra tecla |
| ST-06 | Baja (documentación) | `src/client/Main.client.luau` (comentario), `README.md` | El comentario decía "Sin dato válido => ES" y el README "ES (por defecto)"; el código y `Strings.default` usan **EN** | **Corregido** (texto) |
| ST-07 | Informativa | `src/server/WorldBuilder.luau` | Era el único módulo del servidor sin ninguna prueba y lo primero que ejecuta `GameService.start`: si lanzara un error, el servidor entero no arrancaría. Ahora se ejecuta contra un `DataModel` de Lune con validación de propiedades/enums | **Sin hallazgos** (se ejecuta limpio) [EJ] |
| ST-08 | Informativa | luau-lsp | No detecta `game:GetService("Nombre mal escrito")` ni `Instance.new("ClaseMalEscrita")` fuera de los archivos tipados; las propiedades de `UI.create(...)` pasan por `{ [string]: any }` y tampoco se comprueban | **Cubierto** por `ProjectStructure` (g) y `ClientBoot` (valida cada propiedad); no corregible en el analizador |

## 4. Lo que sigue sin poder verificarse sin Studio (lista para el playtest del PC)

Marcar cada punto. Lo que falle, anotarlo con la salida del servidor/cliente.

**Arranque y estructura**
1. Play: la salida del servidor muestra `[FishFortune] servidor iniciado` sin errores en rojo y sin `Infinite yield possible`. Avisos **esperados** en Studio: `[Data] Studio sin acceso a DataStores ... MEMORIA` (si no activaste el acceso), y posibles avisos de `LiveOps`/`MessagingService`/`ConfigService`/`AnalyticsService` (están en `pcall`).
2. Explorer (con el juego corriendo, vista Server): `ReplicatedStorage.Remotes` con **23** `RemoteEvent` (16 de entrada + 7 de salida), `Workspace.World` con `lake`, `river`, `coast`, `Workspace.SpawnLocation`. Vista Client: `PlayerGui.FishFortune`.
3. El `LocalScript` `StarterPlayerScripts.Client.Main` se ejecuta aunque esté **anidado en la carpeta `Client`** (la doc lista `StarterPlayerScripts` pero no habla de carpetas anidadas; es el patrón habitual de Rojo). Si no se ejecutara, la interfaz no aparece nunca.
4. Rojo en vivo (`rojo serve` + plugin): que `Packages`, `Shared`, `ServerPackages`, `Server` y `Client` aparezcan donde dice el README y que reconectar no duplique la interfaz al reaparecer (`ResetOnSpawn = false`).

**Personaje, zonas y mundo**
5. La caña aparece en la mano derecha (R15 `RightHand`; la caña se pega en el `CharacterAdded` diferido y asume que la mano ya existe: si llegara después, no aparece) con el color de la caña equipada; al reaparecer también; al comprar/equipar otra cambia.
6. Salir y volver con la zona `river`/`coast` guardada: el jugador sale en esa zona; morir (reset del personaje) en el Río: reaparece en el Río (ST-03).
7. El flotador (`Bobber`) cae sobre el agua en cada zona; `CastTarget` está donde se espera; el cartel de cada zona se traduce al idioma del jugador (`SurfaceGui` con `AutoLocalize = false` y atributo `LocaleKey`).
8. Streaming: ver si el lugar tiene `StreamingEnabled` (el valor por defecto de un lugar construido por Rojo no se verificó). El código tolera que `CastTarget` aún no exista.
9. Iluminación/atmósfera y partes del mundo se ven bien (solo se validó que las propiedades existen, no el aspecto).
10. Un jugador que ya esté en la sesión cuando arranca el script (Play Solo muy rápido) no recibe la caña en el primer personaje: el bucle `for ... Players:GetPlayers()` conecta `CharacterAdded` pero no atiende un personaje ya existente. Baja prioridad; solo si se observa.

**Interfaz y entrada**
11. Espacio (ST-05): ¿se quiere perder el salto con Espacio? Comprobar "Action Bindings".
12. El contorno pulsante de la guía del tutorial (`UIStroke` + `Tween` infinito, creado sin padre y reparentado entre botones): la doc de `Tween` no aclara si anima sin padre; si no pulsa, es cosmético.
13. Diseño real (no se puede simular): los botones grandes no se tapan con los botones de Roblox ni con el pulgar en el emulador móvil y en un dispositivo real; `IgnoreGuiInset = false` deja la interfaz bajo la barra superior; paneles con `UISizeConstraint` en pantallas grandes.
14. Fuentes `Gotham`/`GothamBold` y tamaños de texto legibles; ningún texto sale como clave (`hud.coins`) ni con `{...}` sin sustituir (ya cubierto en la prueba de cliente, pero con texto de verdad).

**Lo que ya se sabía y sigue pendiente** (de `revision-codigo-dinero.md` y del README): IDs de pases/productos en 0; si `PromptGamePassPurchase` espera el `TargetId` o el assetId; tolerancia real a Studio sin acceso a la API; compras con Robux de prueba; `ProcessReceipt` frente a `BindReceiptHandler`.

**Aviso para Windows (PC de Aryan):** `tools/lint.sh` usa `rojo sourcemap --absolute`; en Linux funciona [EJ] pero **no se probó en Windows**. Si allí aparece `Unknown require` en archivos que sí existen, el sourcemap no está casando rutas: ejecutar `rojo sourcemap ROBLOX/games/fish-and-fortune/default.project.json -o <archivo>`, mirar si las rutas son `C:\...` y avisar (alternativa: lanzar luau-lsp con `cd` en la carpeta del juego y sin `--absolute`). Las dos pruebas nuevas usan `rojo.exe` si `process.os == "windows"`.

## 5. Cómo correr las pruebas nuevas

```
bash ROBLOX/tools/test.sh                                              # todo (incluye las nuevas)
bash ROBLOX/tools/test.sh ROBLOX/games/fish-and-fortune/tests/ProjectStructure.spec.luau
bash ROBLOX/tools/test.sh ROBLOX/games/fish-and-fortune/tests/ClientBoot.spec.luau
bash ROBLOX/tools/test.sh -t "remotos"                                 # solo las pruebas cuyo nombre contenga "remotos"
ARYAN_REQUIRE_ROJO=1 bash ROBLOX/tools/test.sh ROBLOX/games/fish-and-fortune/tests   # sin rojo: FALLAR en vez de omitir
bash ROBLOX/tools/lint.sh                                              # incluye el análisis con sourcemap
```

* `ProjectStructure.spec.luau` y `ClientBoot.spec.luau` ejecutan `rojo build` (proceso hijo; `tests/support/BuiltPlace.luau`) y borran el `.rbxl` temporal (`ROBLOX/.toolchain/build/`). Buscan `rojo` en `ROBLOX/.toolchain/bin` (o `ARYAN_TOOLCHAIN`) y luego en el `PATH`. **Sin `rojo` se omiten con un aviso** ("pruebas de estructura OMITIDAS") y `test.sh` sigue en verde; con `ARYAN_REQUIRE_ROJO=1` fallan.
* `ProjectStructure.spec.luau`: (a) servicios y carpetas, (b) clase/`RunContext`/`Disabled`, (c) `require` resueltos, (d) duplicados y huérfanos, (e) remotos, (f) contrato del mundo con `WorldBuilder`, (g) nombres de servicios/clases. El **contrato** (`EXPECTED`) está escrito a mano en el archivo: si añades, quitas o renombras un módulo o remoto, actualízalo a propósito (esa es la gracia: un cambio de estructura no puede pasar desapercibido).
* `ClientBoot.spec.luau` arranca el cliente en ES y en EN, abre y cierra los 6 menús, dispara `State`/`CastStarted`/`Catch`/`Toast`/`Banner`/`Offers` con payloads reales del servidor y exige: ninguna propiedad inválida, ninguna advertencia, ningún error en handlers ni en hilos.
* `tests/support/ServerHarness.luau` es el arnés de `GameService` extraído de `GameService.spec.luau` sin cambios de comportamiento (lo comparten `GameService.spec` y `ClientBoot.spec`).

**Dos trampas de Lune 0.11 + testkit** (cada una cuesta tiempo si no se conoce): (1) las llamadas asíncronas (`fs.readFile`, `process.exec`) **dentro de un `it`** hacen entrar en pánico al planificador (`CoroutineUnresumable`): toda la E/S va al cargar el archivo, antes de los `describe`. (2) El runner arranca en el primer "cede" posterior al primer `describe`; un `require("./x")` de Lune cede el hilo, así que **todos los `require` van antes del primer `describe`** o las suites posteriores se pierden sin avisar.

## 6. Límites de lo hecho

* Las instancias de interfaz de `ClientBoot` son fachadas: validan **nombres y tipos** de propiedad contra la base de reflexión de Lune (0.741.19, un poco anterior a Studio 0.743), no el layout ni el aspecto. `TweenService`, `ContextActionService` y `RunService` son dobles.
* La replicación (qué ve el cliente, cuándo), el orden real de ejecución de los scripts y el streaming no se simulan.
* El escáner de `require` entiende `script`, `game`, `:GetService`, `.Parent`, `.Nombre`, `:WaitForChild`, `:FindFirstChild` y alias `local`; una forma nueva **falla** con un mensaje claro en vez de ignorarse (hay que ampliar el escáner o simplificar el `require`).
