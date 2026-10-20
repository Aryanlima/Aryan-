# Arquitectura del kit de juegos (paquetes + Fish & Fortune)

Fecha: 2026-10-20. Alcance: `ROBLOX/packages/` (kit reutilizable), `ROBLOX/games/fish-and-fortune/` (primer juego) y `ROBLOX/tests/`.
**Nada de este código se ha ejecutado en Roblox Studio** (el entorno de desarrollo es Linux sin Studio). Lo que sí se ha hecho: tests de lógica pura con Lune y los mocks de `ROBLOX/tools/testkit`, análisis estático con selene, StyLua y luau-lsp (con los tipos reales de Roblox) y una compilación con Rojo (`rojo build`). Las marcas `-- REVIEW(money):` señalan código de monetización o datos que **una persona debe revisar** antes de publicar; las marcas `-- VERIFY:` señalan algo que no se pudo comprobar en la documentación oficial.

---

## 1. Principios

1. **Juegos finos, paquetes gruesos.** Compras, datos, economía, probabilidades, red, eventos, analítica y UI viven en `packages/`; un juego aporta configuración y contenido (`Balance`, `Catalog`, `ProductIds`, mundo, pantallas).
2. **Autoridad total del servidor.** El cliente solo *solicita* (lanzar, vender, comprar esta caña, canjear este código). El servidor valida tipo, rango, propiedad y estado (`Net`) y decide (`GameLogic`). Ninguna cantidad la propone el cliente. Lo único que el cliente aporta es el tiempo del minijuego, que el servidor contrasta con su reloj.
3. **Lógica pura separada del motor.** Ningún módulo con reglas hace `require` de otro ni usa servicios al cargarse: todo llega por **inyección de dependencias** (`task`, reloj, `DataStore`, `MarketplaceService`, `Players`, RNG). Por eso se puede probar casi todo con Lune. El pegamento con el motor (`GameService`, `Main`, `WorldBuilder`, cliente) es fino y está tipado con luau-lsp.
4. **Una sola puerta por riesgo.** Un único `ProcessReceipt` (`Shop`), un único acceso a `PolicyService` (`Shop.getPolicy`), una única tabla de probabilidades (`Odds`), todos los remotos por `Net`, todos los eventos de analítica por `Analytics`.
5. **Sin secretos en `ReplicatedStorage`.** Rojo mapea `Odds`, `Net`, `UI` y `Shared` al cliente; `Data`, `Economy`, `Shop`, `LiveOps`, `Analytics`, `Catalog`, `ProductIds`, `LiveOpsDefaults` solo bajo `ServerScriptService`.
6. **Honestidad de tienda y cumplimiento por construcción** (no como revisión posterior): ver §6.

---

## 2. Mapa de módulos

| Paquete (`packages/`) | Responsabilidad | Corre en | Tests |
|---|---|---|---|
| `Data` | Persistencia por jugador con `UpdateAsync`, bloqueo de sesión (`jobId` + latido), reintentos con backoff, migraciones versionadas, autosave, `PlayerRemoving`, `BindToClose`. **Implementación propia; en producción sustituir por ProfileStore** (misma forma de uso). | servidor | `tests/Data.spec.luau` |
| `Economy` | Monedas blanda/dura (enteros acotados), multiplicadores combinables con tope (aditivos), boosts temporales con tope de acumulación, ganancias offline con tope. | servidor | `tests/Economy.spec.luau` |
| `Shop` | Catálogo por configuración (pases, productos, boosts, packs), `ProcessReceipt` único e idempotente, caché de propiedad de pases, prompts seguros, gating por `PolicyService`, escalera de precios, validación del catálogo (sin urgencia ni descuentos falsos), elementos `enabled = false`. | servidor | `tests/Shop.spec.luau` |
| `Odds` | UNA tabla de probabilidades que genera la tirada del servidor (RNG inyectable) y los datos de la UI de probabilidades (suman 100 %, sin "nada", pity solo si es visible, gating por política). | ambos | `tests/Odds.spec.luau` |
| `Locale` | Localización ES/EN (ampliable): claves → texto con marcadores `{nombre}`, plural, respaldo al idioma por defecto del juego (EN en Fish & Fortune), elección de idioma por `LocaleId`, formatos de número (solo cambian separadores) y validación con lista blanca de los mensajes `{ key, args }` que envía el servidor. Pura. | ambos | `tests/Locale.spec.luau` |
| `Net` | Registro de RemoteEvent/Function con validadores (rechaza NaN/inf, cadenas enormes, aridad), token bucket por jugador y remoto (`os.clock`), límite global, detección de abuso. | ambos | `tests/Net.spec.luau` |
| `LiveOps` | Ventanas de eventos y rotación, códigos con caducidad y un uso por jugador, bienvenida, temporada; configuración remota (ConfigService/DataStore, inyectada) validada antes de aplicarla. | servidor | `tests/LiveOps.spec.luau` |
| `Analytics` | Envoltorio de `AnalyticsService` (economía, embudo FTUE, eventos propios): no-op sin servicio, valida y respeta los límites documentados. | servidor | `tests/Analytics.spec.luau` |
| `UI` | Constructores de interfaz por código, móvil primero; paneles reutilizables de tienda y de probabilidades; formateo (`formatNumber`, `formatDuration`). | cliente | `tests/UI.spec.luau` |
| `Art` | Arte intercambiable con respaldo: busca plantillas `<raíz>/<categoría>/<id>`, las **valida con lista blanca** (sin scripts), las clona, escala/orienta con un perfil y cae al generador procedural si faltan o son inválidas. Genérico (sin nada de un juego). | ambos | `tests/Art.spec.luau` |

| Juego (`games/fish-and-fortune/src/`) | Qué es |
|---|---|
| `shared/Balance.luau` | **Todo el balance** (rarezas, 3 zonas, 25 criaturas, 5 cañas, minijuego, inventario, offline, FTUE, bestiario, temporada, VIP, importes de productos). Datos puros, **sin textos**. |
| `shared/Strings.luau` | **Todos los textos visibles** (ES + EN lado a lado). Datos puros; `tests/Strings.spec.luau` cruza el archivo con el código y los datos del juego. |
| `shared/FeatureFlags.luau` | Flags de funciones con riesgo de cumplimiento (`paidLuckEnabled = false` en la v1). |
| `shared/FishingRules.luau` | Reglas puras: tabla de odds por zona (vía `Odds`), elección de captura (con tutorial garantizado), minijuego (onda triangular, evaluación del tiempo). |
| `shared/{Remotes,ClientLogic,Store}.luau` | Nombres de remotos; guía del tutorial y textos del cliente; contenedor de estado. |
| `server/GameLogic.luau` | Reglas de juego sobre el perfil: lanzar/recoger, vender, canas, zonas, bestiario, temporada, VIP diario, offline, concesión de productos. |
| `server/{Catalog,ProductIds,Schema,LiveOpsDefaults}.luau` | Catálogo y precios; **único archivo de IDs** (`0 -- TODO_ID`); esquema de datos; configuración de LiveOps por defecto. |
| `server/{GameService,Main.server,WorldBuilder,StudioMemoryStore}.luau` | Pegamento con el motor: orquesta paquetes y remotos; mundo procedural (con arte opcional); almacén en memoria solo para Studio. |
| `server/ArtDirector.luau`, `shared/ArtProfiles.luau` | Arte generado opcional: caña en la mano, escaparate de capturas, resumen de arranque; fichas (tamaño, pivote, presupuesto) de las 35 piezas. Ver sección 13. |
| `client/*.luau` | `Main` (LocalScript), `Hud`, `Minigame`, `Feedback`, `Menus`. Solo presentación y solicitudes. |

Mapa Rojo (`default.project.json`):

```
ReplicatedStorage   Packages {Odds, Net, UI, Locale, Art}    <- seguros para el cliente
                    Shared   {Balance, Strings, FeatureFlags, FishingRules, Remotes, ClientLogic, Store, ArtProfiles}
ServerScriptService ServerPackages {Data, Economy, Shop, LiveOps, Analytics}   <- SOLO servidor
                    Server   {Main (Script), GameService, GameLogic, Catalog, ProductIds, Schema,
                              LiveOpsDefaults, WorldBuilder, StudioMemoryStore, ArtDirector}
ServerStorage       Art {creatures, rods, props}        <- plantillas de arte generado (vacías en el repo; .rbxm en art/models/)
StarterPlayer.StarterPlayerScripts.Client {Main (LocalScript), Hud, Minigame, Feedback, Menus}
```

---

## 3. Flujo de datos (perfil de jugador)

```
PlayerAdded -> Data.load(userId)
   UpdateAsync(clave):  nuevo? crear con plantilla | ocupado por otro jobId con latido reciente? cancelar |
                        reclamable? escribir lock = {jobId, heartbeat}
   -> migrar en memoria (schema.migrations) -> reconciliar con la plantilla -> perfil ACTIVO
cada 120 s (autosave): markDirty + save  == guardado + latido del bloqueo
compra / canje / recompensa importante: profile:save() inmediato
PlayerRemoving: Profile.release() = guardado final + lock = nil   (reintenta más que un guardado normal)
BindToClose: Manager.shutdown() libera todos los perfiles EN PARALELO (máx. ~25 s de los 30 s de Roblox)
```

Reglas que el código impone y los tests comprueban (`tests/Data.spec.luau`):

* **Nunca se escriben valores por defecto si la lectura falla.** La carga reclama el registro con `UpdateAsync` (lee y escribe atómicamente); si todos los reintentos fallan, `load` devuelve `nil` y el jugador es expulsado con un mensaje. La clave no se toca.
* **Bloqueo de sesión.** Otro servidor no puede cargar mientras el latido sea reciente (por defecto 600 s sin latido = servidor caído). Un servidor que descubre que perdió el bloqueo **deja de escribir** y expulsa al jugador (evita duplicar objetos).
* **El callback de `UpdateAsync` no cede** (sin `task.wait` ni llamadas `Async` dentro) y puede ejecutarse varias veces: comunica su resultado por variables locales.
* **Backoff exponencial con jitter**; los errores 101-107 (clave/valor inválidos) no se reintentan.
* **Datos de un esquema más nuevo** (servidor viejo durante una actualización) se rechazan sin tocar el registro. Una migración que falla libera el bloqueo y no modifica los datos.
* **Validación previa al guardado** (`Data.validate`: NaN/inf, claves mixtas, ciclos, metatablas). Datos no serializables *no* sobrescriben el último guardado bueno.
* `release()` que falla tras todos los reintentos deja el perfil en `release-failed` y el autosave lo reintenta (no se pierde en memoria).
* Cada clave se asocia al `UserId` (`UpdateAsync` devuelve `{userId}`) para el derecho al olvido.

Migraciones: `Schema.version` + `migrations[N]` (de vN a vN+1, en el sitio). **Nunca edites una migración publicada**; añade la siguiente y sube la versión. No cambies el nombre del DataStore (sería un almacén vacío). Haz un *snapshot* de DataStores antes de publicar cambios en la lógica de datos (Open Cloud, ver ROBLOX/research/06 §2.4).

---

## 4. Flujo de compra (`Shop`)

### 4.1 Pases (`UserOwnsGamePassAsync`)

`loadPlayer` consulta todos los pases **en paralelo** (batching transparente) con reintentos y rellena una caché por jugador. `PromptGamePassPurchaseFinished(player, id, true)` dispara una **re-verificación** con `UserOwnsGamePassAsync` antes de dar el pase por poseído (si la verificación falla por red se confía en el evento del servidor, documentado como resultado final). Las concesiones únicas ligadas a un pase (pack de inicio) usan `profile.passGrants[clave]` y son idempotentes entre sesiones.

### 4.2 Productos de desarrollador (`ProcessReceipt`)

Un único `ProcessReceipt` (`Shop.start`). Pasos y su resultado:

| # | Paso | Si falla / no aplica |
|---|---|---|
| 1 | Recibo bien formado y producto conocido | `NotProcessedYet` (no se "traga" una compra) |
| 1b | Producto `enabled = false` (flag de función apagado) | `NotProcessedYet`, sin conceder ni registrar; ver §6.3 |
| 2 | Jugador presente y perfil **activo** (`waitForProfile`) | `NotProcessedYet`: Roblox vuelve a llamar cuando el jugador entre |
| 3 | ¿`PurchaseId` ya registrado en el perfil? | `profile:save()`: si se guarda → `PurchaseGranted` (idempotencia); si no → `NotProcessedYet` |
| 4 | Aplicar el efecto con el handler del juego (síncrono, sin ceder) **y registrar el `PurchaseId` en el mismo paso** | handler que lanza error o no devuelve `true` → `NotProcessedYet` y no se registra |
| 5 | `profile:save()` | éxito → `PurchaseGranted` (y recién entonces analítica/avisos); fallo → `NotProcessedYet` |

Por qué es seguro:

* El reintento de Roblox cae en el paso 3, así que el efecto se concede **una sola vez** aunque el callback corra dos veces o en dos servidores (el segundo servidor tampoco puede cargar el perfil: bloqueo de sesión).
* Si el servidor cae **entre** el paso 4 y 5, la concesión (en memoria) desaparece y la compra queda sin resolver → se concede al volver a entrar. Si el guardado "falló" pero la escritura sí ocurrió (Roblox documenta que es posible), el reintento ve el `PurchaseId` en el paso 3.
* Si el jugador se va tras el paso 4, `release()` guarda el perfil con el `PurchaseId`; al volver, la reentrega cae en el paso 3.
* El historial de `PurchaseId` se acota (500 recientes). Roblox solo reentrega compras sin resolver, así que un recibo ya confirmado no vuelve.
* `ProcessReceipt` **nunca lanza**: cualquier error → `NotProcessedYet` + log.

`// VERIFY:` la referencia oficial llama a `ProcessReceipt` "legacy" y documenta `BindReceiptHandler` (con `Enum.ReceiptDecision`). Sigue funcionando y es lo que exige el encargo; migrar es mecánico pero debe probarse en Studio.

### 4.3 Prompts (`promptProduct` / `promptPass`)

El cliente pide por **clave de catálogo**; el servidor comprueba, por este orden: clave conocida → ID no placeholder y `enabled` → jugador presente → perfil activo (no se vende mientras carga) → política (si `affectsOdds`) → pase ya poseído → enfriamiento (3 s) y solo entonces llama a `PromptProductPurchase`/`PromptGamePassPurchase`. Los precios mostrados vienen de `GetProductInfoAsync` (regional) y se marcan con `~` si son los de la escalera.

---

## 5. Probabilidades (`Odds`) y cumplimiento

* Una `OddsTable` por zona se construye desde `Balance` y se usa **tanto** para sortear (`roll`, con `RandomFn` inyectable) **como** para la UI (`displayRows`). Lo mostrado es exactamente lo sorteado.
* Los porcentajes se reparten por el método del resto mayor: suman **exactamente** 100,00 % y nadie se muestra como 0,00 % (la validación lo exige a suerte 0 y a la suerte máxima).
* Se rechazan ids tipo `nothing/none/miss...` y valores ≤ 0 (ningún resultado sin valor).
* La suerte cambia las probabilidades *mostradas* (columna "Ahora" y columna "base"), con el desglose de fuentes.
* El pity solo se acepta con texto visible (`note`) y `displayRows` siempre lo incluye (Fish & Fortune no usa pity en la v1).
* `Odds.paidRandomAllowed(policy)` usa la propiedad oficial `ArePaidRandomItemsRestricted` (`true` = restringido); sin datos → restringido.
* Sorteo del tutorial: los 3 primeros lanzamientos están garantizados (Poco común, Poco común, Raro) **excluyendo** entradas de la *misma* tabla (no hay ruta aparte) y la UI lo avisa.

---

## 6. Honestidad de tienda y feature flags

### 6.1 Reglas comprobadas por tests
* `Shop.validateCatalog`: IDs únicos, precios dentro de la escalera (o `priceOverride` explícito), pases promocionados entre 50 y 800 R$ y **sin** poder alterar probabilidades, campos prohibidos (`discountPercent`, `countdown`, `stockLeft`...), y **lenguaje de presión** (`findPressureLanguage`: "última oportunidad", "solo hoy", "buy now"...).
* La UI usa textos neutros: "Ver compra", "Ya lo tienes", "No disponible en tu región".
* Los temporizadores de eventos son exactos (`endsAt - ahora`) y no se reinician solos.

### 6.2 Escalera de precios
Configurable: `Catalog.ladder` (impulso 49, básico 99, valor 199, plus 249, estándar 299, fuerte 399, mayor 499, premium 999, ancla 1999). Son hipótesis para A/B test, no datos de mercado.

### 6.3 `FeatureFlags.paidLuckEnabled = false` (decisión D9 del informe maestro)
En la v1 **no se vende suerte ni azar de pago**. Con el flag apagado:
* Suerte+ (pase) y Cebo de Suerte (producto) salen del catálogo con `enabled = false`: no se muestran, `canOffer` → `unavailable`, no se consulta su propiedad.
* Un recibo antiguo del Cebo (de una versión previa al flag) se **rechaza**: `NotProcessedYet`, sin conceder ni registrar, con log `REVIEW(money)`. El recibo queda sin resolver: ni se regala ni se consume.
* `GameLogic` no lista ni aplica fuentes de suerte de pago; `grantProduct` rechaza el boost `lucky_bait` (defensa en profundidad).
* La suerte **gratuita** (cañas, lanzamiento perfecto, eventos) sigue funcionando y la UI de probabilidades la muestra junto a la columna base.
* La lógica de v1.5 (PolicyService, odds dinámicas con suerte de pago) se conserva y se prueba con el flag encendido.

### 6.4 Textos e idiomas
El servidor no envía texto: envía claves y argumentos (`Locale.message`) y el cliente los valida y traduce al idioma del jugador (ver README del juego, sección 10). Los textos de tienda, tutorial y probabilidades se revisan una sola vez en `Strings.luau`, en ES y EN, con la misma prueba de lenguaje de presión.

---

## 7. Red (`Net`)

* `server:event(nombre, { args = {validadores}, rate = {capacity, refillPerSecond}, handler })`. Se rechazan los argumentos de más (aridad), los faltantes obligatorios, `NaN`, `inf`, números fuera de rango, cadenas fuera de longitud, UTF-8 inválido y valores fuera de una lista (`oneOf`).
* Token bucket por jugador y remoto con `os.clock` inyectable (no regala fichas si el reloj retrocede) + límite global por jugador. `server:forget(player)` en `PlayerRemoving`.
* `onAbuse` se dispara una sola vez por ventana cuando hay muchos rechazos; Fish & Fortune solo lo registra (escalar a expulsión por una única señal da falsos positivos).
* Remotos solo servidor → cliente se crean con `server:outbound` (no escuchan al cliente).
* El minijuego: el cliente envía `Reel(castId, segundos)`; el servidor rechaza tiempos imposibles (`> tiempo del servidor + 0,35 s`, `< tiempo − 2,5 s`, antes del mínimo o caducados). Un cliente tramposo solo puede acertar siempre la zona perfecta (+1 de suerte, gratuito).

---

## 8. LiveOps sin republicar

`LiveOps` recibe una función `fetch` (en Fish & Fortune lee la clave `FishFortune_LiveOps` de **ConfigService**, JSON) y una configuración por defecto (`LiveOpsDefaults`). Cada 120 s (con jitter) y al recibir un aviso de `MessagingService` se descarga, **se valida** (`validateConfig`) y solo entonces reemplaza a la anterior; una configuración inválida o un error de red conservan la buena. Cubre eventos (ventana fija o rotación por slots), códigos (por jugador, con inicio y caducidad; fin exclusivo), bienvenida (por `id`) y temporada. Límite: máximo 10 eventos activos/próximos.

---

## 9. Decisiones y alternativas

| Decisión | Alternativa descartada | Por qué |
|---|---|---|
| `Data` propio sobre `UpdateAsync` | ProfileStore desde el primer día | Hay que poder probar la pérdida de datos con mocks; **sustituir por ProfileStore en producción** (misma API de uso). No se vendorizó para no mantener código sin usar. |
| Conceder en memoria + guardar + confirmar | Guardar solo el `PurchaseId` y esperar a `LastSavedData` | Misma garantía de idempotencia con menos piezas; ver §4.2. |
| `ProcessReceipt` | `BindReceiptHandler` | El encargo lo pide y está documentado; migración mecánica pendiente de prueba en Studio. |
| Inyección de dependencias | `require` por instancia dentro de los módulos | Permite probar con Lune sin engañar al analizador; los `require` por instancia viven solo en `Main`. |
| Tiempo del minijuego medido por el cliente y contrastado | Tiempo solo del servidor | La latencia (50-200 ms) rompería zonas perfectas de ~15 % de la barra; el bonus es pequeño y gratuito. |
| `FeatureFlags` único | Borrar la suerte de pago | El kit la necesitará en la v1.5; se conserva con tests. |
| Mundo procedural en `WorldBuilder` | Mapa a mano | Sin arte disponible; el contrato (`Spawn`, `CastTarget`) permite sustituirlo por un mapa generado con IA. |

---

## 10. Riesgos y qué revisar

| Riesgo | Mitigación actual | Qué falta |
|---|---|---|
| Nada se ha probado en Studio | Tests de lógica pura, luau-lsp con tipos reales, `rojo build` | Playtest manual (README del juego), compras de prueba, 2 servidores a la vez |
| Datos y compras (dinero real) | Código marcado `REVIEW(money)`; tests de idempotencia y fallo de persistencia | Revisión humana; probar `BindToClose` y el bloqueo con el emulador de varios clientes y servidores |
| `Data` es implementación propia | Muchos tests de bloqueo, migración y fallos | Sustituir por ProfileStore, o auditar a fondo antes de escalar |
| Recibo antiguo de suerte con el flag apagado | Rechazo seguro (`NotProcessedYet`) | Decisión humana si aparece (ver README del juego) |
| `ConfigService` sin verificar a fondo | `pcall` + valores por defecto; `-- VERIFY:` | Confirmar formato del valor JSON y límites de tamaño en Studio |
| Cuotas (DataStore, MessagingService, Analytics) | Autosave 120 s, banner con cooldown, límites de analítica | Medir con tráfico real |
| Cumplimiento por país/edad | `PolicyService` cacheado y conservador; flag apagado | Probar con el Player Emulator (AU, BE, NL, UK, BR) antes de la v1.5 |
| Localización | ES (por defecto) y EN completos, un solo archivo de textos, servidor → cliente solo claves validadas (`Locale`) y pruebas que escanean el código | Probar en Studio con cuentas en ES y EN (`RobloxLocaleId` sin verificar); decidir el idioma de respaldo para idiomas no soportados; traducir la ficha y los pases en el Creator Hub |

---

## 11. Cómo se prueba y se comprueba

```
bash ROBLOX/tools/test.sh            # todos los *.spec.luau con Lune (testkit: ROBLOX/tools/testkit)
bash ROBLOX/tools/lint.sh            # selene + stylua --check + luau-lsp (tipos de Roblox)
bash ROBLOX/tools/format.sh          # aplica StyLua
cd ROBLOX/games/fish-and-fortune && rojo build default.project.json -o ../../../build.rbxl   # valida el proyecto Rojo
```

Los tests usan los dobles de `ROBLOX/tools/testkit/mocks` (`Clock`, `DataStoreService`, `MarketplaceService`, `Players`, `Signal`). El reloj simulado hace que `task.wait` avance el tiempo sin esperar: los reintentos con backoff y los bucles se prueban en milisegundos.

---

## 12. Cómo crear el siguiente juego con el kit

1. Copia `games/fish-and-fortune/` y cambia `Balance`, `Catalog`, `ProductIds`, `Schema` (sube `version` si cambia la forma de los datos), `GameLogic` y el mundo.
2. Mantén el mapa Rojo (paquetes compartidos al cliente; datos/tienda/economía solo en servidor).
3. Declara en `Balance` todo el contenido y escribe sus tests de coherencia (`tests/Balance.spec.luau`): odds válidas, valores > 0, FTUE ≤ 60 s.
4. Rellena `ProductIds` con IDs reales y ejecuta `Shop.validateCatalog(catalogo, handlers, { allowPlaceholders = false })` como puerta previa a publicar.
5. Revisa a mano todo lo marcado `REVIEW(money)` y haz un playtest con el checklist del README.
6. Arte: define las fichas de tus piezas (como `ArtProfiles`), pasa `Art.new` a tu `WorldBuilder` y pide cada pieza con `place(categoría, id, { fallback = ... })` (sección 13); empieza sin arte y llénalo después.

---

## 13. Arte intercambiable (`Art`, `ArtProfiles`, `ArtDirector`)

```
                      ServerStorage/Art/<categoría>/<id>        (plantillas: Model con el nombre del id)
                                  │  find
   WorldBuilder ─┐                ▼
   ArtDirector  ─┼─ place(cat, id, {parent, cframe, anchored?, scale?, fallback?}) ──► Art.Provider
   (caña, escaparate)             │ validate (lista blanca) ──✗──► respaldo: `fallback` (procedural de siempre) o nada
                                  │ ✓ clonar → girar → escalar (perfil) → pivote → normalizar (visual, anclado / soldado)
                                  ▼
                       Model en Workspace / personaje   (se replica solo)
```

**Decisiones y por qué**
| Decisión | Motivo | Alternativa descartada |
|---|---|---|
| Un único punto (`Art.place`) decide arte o respaldo; el respaldo lo pasa quien llama | Que el generador procedural no se toque y siga siendo la verdad cuando no hay arte; probable con Lune | `if` repartidos por el código |
| Plantillas en **`ServerStorage`** | Todo consumidor actual es del servidor y lo colocado se replica solo; el cliente no descarga plantillas ni puede alterarlas | `ReplicatedStorage` (replica todo a todos); queda como opción para `ViewportFrame` futuros |
| **Lista blanca** de clases, no lista negra de scripts | Un asset generado o importado no puede traer código, remotos, sonidos ni constraints; lo desconocido se rechaza | Buscar solo `Script`/`LocalScript`/`ModuleScript` |
| Clonar y normalizar; **nunca** asignar `MeshId` ni ejecutar nada | `MeshId` es de solo lectura para scripts; clonar conserva la malla ya subida | `AssetService:CreateMeshPartAsync`, `InsertService:LoadAsset` (cargar modelos en ejecución) |
| Arte **solo visual**; la colisión (cubierta del muelle) es una parte propia invisible | Una malla generada no garantiza una superficie transitable ni una colisión buena | Colisión de la malla |
| Geometría propia (cajas orientadas), no `Model:ScaleTo/GetBoundingBox/PivotTo` | Se prueba con Lune sin motor y se comporta igual en Studio | Métodos del motor |
| Perfiles en datos (`ArtProfiles`) + manifiesto de prompts (`art/manifest.json`) con prueba de no desviación | Un solo sitio para el tamaño/presupuesto de cada pieza; los prompts viven con sus medidas | Constantes sueltas |
| Farolas y barca **sin respaldo** | El procedural nunca las tuvo; sin arte el mundo no cambia | Crear versiones procedurales nuevas |

**Persistencia:** las plantillas viven en el lugar guardado desde Studio y, cuando se aceptan, como `art/models/<categoría>/<id>.rbxm` mapeados por Rojo (`$ignoreUnknownInstances: true`, así `rojo serve` no borra lo hecho en Studio). Un `.rbxm` guarda la referencia al `MeshId`, no la malla; el `SurfaceAppearance` y los `MaterialVariant` no los actualiza la API de publicación de Open Cloud: se publica desde Studio. Detalle y alternativas: `docs/arte-con-ia-en-studio.md` §8.

**Qué no cubre:** que el motor muestre bien cada modelo (aspecto, escala, soldaduras con el rig real), el recuento real de triángulos (solo se valida el atributo `ArtTriangles`) y los permisos de acceso a los assets de malla en un juego publicado. Todo ello requiere playtest en Studio.

