# Revisión independiente del código de dinero, datos y exploits

Fecha: 2026-10-20. Alcance: `ROBLOX/packages/*` y `ROBLOX/games/fish-and-fortune/*` (commit `c29c460`). La hizo un agente revisor distinto del que escribió el código, sobre una copia aislada. Este documento resume su informe; los arreglos marcados **aplicado** ya están en el repositorio con sus pruebas.

**Cómo leer las etiquetas:** **[EJ]** = el revisor lo comprobó ejecutando código. **[LEÍDO]** = razonado leyendo, sin ejecutar. **[DOC]** = contrastado con la documentación oficial (`Roblox/creator-docs`). Nada de esto se ha ejecutado en Roblox Studio.

## 1. Veredicto

**No se puede publicar todavía, pero no por defectos críticos.** No se encontró doble concesión de compras, compra cobrada y perdida, ni datos buenos pisados por valores por defecto. La idempotencia por `PurchaseId`, "guardar antes de confirmar" y el bloqueo de sesión de datos se comprobaron con pruebas y con errores inyectados [EJ].

Hallazgos: **0 críticos, 3 altos, 7 medios, 8 bajos.**

**Qué bloquea la publicación (aunque el código esté arreglado):**
1. El juego nunca se ha jugado en Studio.
2. Todos los IDs de `ProductIds.luau` valen 0: hoy no se vende nada. Hay que crear los pases y productos en Creator Hub y pegar los IDs reales.
3. **Sin resolver:** no está claro si `PromptGamePassPurchase` espera el `TargetId` o el assetId del pase. La documentación de Roblox se contradice (`production/monetization/passes.md` frente a `reference/engine/classes/MarketplaceService.yaml`). Se resuelve probando con un pase real en Studio.
4. La puerta previa a publicar es opt-in (`FF_RELEASE_CHECK=1`): hay que ejecutarla cuando estén los IDs reales.

## 2. Estado de las pruebas tras integrar la revisión

| Medida | Antes | Después |
|---|---|---|
| Pruebas | 382 | **420 pasan, 0 fallan, 2 omitidas** (puerta previa a publicar, opt-in) |
| `lint` (Selene + StyLua + luau-lsp) | OK | OK |
| Formato | OK | OK |
| Mutation testing (60 errores inyectados) | 50 detectados, **10 sobrevivían** | Los 10 mueren con las pruebas nuevas; 10 mutantes más sobre los propios arreglos también mueren |

Los mutantes que sobrevivían estaban casi todos en `GameService` (GS1 a GS7), que **no tenía ninguna prueba**; además S9, D6 y D8. Pruebas nuevas: `GameService.spec`, `Review.Data.spec`, `Review.Shop.spec`, `Review.LiveOps.spec`, `Review.Minigame.spec` y `ReleaseGate.spec`.

## 3. Hallazgos

| ID | Sev. | Dónde | Escenario | Evidencia | Estado |
|---|---|---|---|---|---|
| TEST-01 | Alta | `GameService.luau` | Ninguna prueba ejecutaba `GameService`; sin `shop:start()` Roblox auto-confirma los recibos y las compras se pierden. 7 de 7 mutantes sobrevivían | [EJ] | **Aplicado**: arnés `GameService.spec.luau` |
| SHOP-02 | Alta | `Shop.luau` | `ProcessReceipt` esperaba el perfil 20 s; el traspaso del bloqueo de datos puede tardar 25-30 s. Devuelve `NotProcessedYet`, Roblox no reintenta por tiempo y el jugador paga sin recibir hasta reentrar | [EJ] + [DOC] | **Aplicado**: espera de 90 s |
| SHOP-04 | Alta | `Shop.luau`, `GameService.luau` | Un ID repetido al pegar IDs: el último gana y el recibo concede el producto equivocado | [EJ] | **Aplicado**: `assert` al arrancar |
| SHOP-05 | Media | `GameLogic.luau`, `Economy.luau`, `Shop.luau` | Un boost al tope de acumulación (1 h): otro boost de 49 R$ se recorta y el jugador paga por 0-10 min. Igual con packs de monedas o perlas al tope del saldo | [EJ] | **Aplicado**: veto `canPurchase` antes del prompt (motivo `maxed`) |
| DATA-02 | Media | `Data.luau` | Al cerrar el servidor salen N liberaciones en paralelo; la cola de DataStore es de 30 y el resto falla (códigos 301-306) | [EJ] + [DOC] | **Aplicado**: límite de 20 peticiones simultáneas |
| DATA-03 | Media | `Data.luau` | `release()` no era reentrante: PlayerRemoving + BindToClose hacen 2 escrituras y la segunda marca el perfil como `lost` con un falso "bloqueo perdido" (los datos quedan bien) | [EJ] | **Aplicado**: bandera `_releasing` |
| PUB-01 | Media | `Catalog.spec.luau`, `Shop.luau` | El test exigía que todos los IDs fueran 0, así que fallaba al pegar el primero real, y contaba como pendientes a Suerte+ y Cebo (apagados a propósito) | [EJ] | **Aplicado** + `ReleaseGate.spec` opt-in |
| POLICY-01 | Media | `GameService.luau` | Se llamaba a `getPolicy` (cede) aunque el flag de suerte esté apagado, en cada remoto y en el bucle de auto-pesca | [EJ] | **Aplicado** |
| DATA-01 | Media | `Data.luau` | Si cae un servidor, el bloqueo caduca a los 600 s: el jugador no entra en ningún sitio hasta 10 min y el mensaje dice "espera un minuto" | [LEÍDO] | **Propuesto, decisión tuya**: `staleSeconds=300` y autosave cada 90 s |
| MINI-01 | Media | `FishingRules.luau`, `Balance.luau` | La ventana de trampa (2,85 s) supera el periodo del marcador (1,5 s): un tramposo acierta la perfecta con cualquier centro | [EJ] | **Inherente, decisión tuya** (ver 4) |
| LIVEOPS-01 | Baja | `LiveOps.luau`, `GameService.luau` | Un premio mal formado en la configuración remota marcaba el código como usado y fallaba sin pagar | [EJ] | **Aplicado**: validación (0 a 1e9) y reversión del canje |
| BANNER-01 | Baja | `GameService.luau` | `string.sub(...,1,40)` corta bytes: un nombre CJK queda en UTF-8 inválido y el banner global no sale en otros servidores | [EJ] | **Aplicado**: corte por caracteres (`utf8.offset`) |
| ANALYTICS-01 | Baja | `GameLogic.luau`, `GameService.luau` | El evento de compra sale antes de guardar; si el guardado falla se cuenta dos veces | [EJ] | Propuesto: registrarlo en `onPurchaseGranted` |
| OFFLINE-01 | Baja | `GameService.luau` | `lastSeen` solo se guarda al salir; tras un crash se paga offline también el tiempo jugado (acotado por el tope) | [LEÍDO] | Propuesto: refrescar en el autosave |
| PASS-01 | Baja | `Shop.luau` | Si la consulta de propiedad falló al entrar, el dueño real figura como "no poseído" hasta reentrar | [LEÍDO] | Propuesto: re-verificar si `wasPurchased=false` |
| CONFIG-01 | Baja | `GameService.luau` | Un snapshot de configuración nuevo por sondeo; la doc dice que solo cambia con `Refresh()` | [DOC] (la API existe; semántica no verificada) | Propuesto: usar `Refresh()` |
| COMPLIANCE-01 | Baja | `Balance.luau` | Con `decimals=2` el Mítico se muestra "0.04 %" (real 0,0400-0,0427 %). Solo importa cuando haya suerte de pago (v1.5) | [EJ] | Propuesto: `decimals=4` en la v1.5 |
| SHOP-03 | Baja | `Shop.luau` | El recibo de un producto deshabilitado queda `NotProcessedYet` para siempre. Es seguro, pero Roblox retira de superficies externas los productos listados con `ProcessReceipt` fallido | [DOC] | **No crear** en Creator Hub los productos de suerte en la v1; definir política para recibos antiguos antes de la v1.5 |

## 4. Impacto del minijuego (MINI-01) [EJ]

El servidor le envía el centro de la zona al cliente, así que un script puede acertar siempre. El revisor midió el daño:
- Tiempo medio hasta una captura perfecta: **0,50 s** el tramposo frente a **0,64 s** un bot honesto, es decir, alrededor de un 9 % más de cadencia (2.395 frente a 2.195 por hora).
- El premio es +1 de suerte gratuita: el Mítico del Lago pasa de 0,0400 % a 0,0572 %. El tope global de suerte (8) deja el Mítico en 0,66 %.
- No puede recoger antes de 0,35 s, declarar más tiempo del transcurrido (+0,35 s) ni duplicar capturas.
- Un bot así rinde unas 4 veces más que la pesca automática de pago (máximo 600 por hora). **No hay pérdida directa de Robux.**

Es una decisión de diseño tuya: aceptarlo en la v1 o rediseñar el minijuego para que el servidor no revele el centro.

## 5. Lo que está bien [EJ salvo indicación]

- **`ProcessReceipt`:** idempotente, concede en memoria y confirma solo tras guardar. Un doble recibo, un jugador que sale, un perfil liberado o un recibo desconocido devuelven `NotProcessedYet`.
- **`paidLuckEnabled = false`:** cerrado por seis vías en el código (catálogo, `canOffer`, `ProcessReceipt`, `grantProduct`, fuentes de suerte, sin consulta de propiedad). Solo se abre si alguien crea ese producto en Creator Hub.
- **Datos:** el callback de `UpdateAsync` no cede y tolera reejecución (probado con un doble que reejecuta); no se escriben valores por defecto si falla la lectura; una versión nueva o un registro corrupto no se tocan.
- **Economía:** topes, rechazo de NaN, infinito y negativos; el offline solo usa `os.time()` del servidor. Odds en una sola tabla con suma exacta del 100 %.
- **Remotos y canje de códigos:** validados y sin carrera.

## 6. APIs de Roblox

- **Verificadas en la documentación oficial:** `ProcessReceipt` y `ReceiptInfo`; `PromptProductPurchase`; `UserOwnsGamePassAsync`; `PromptGamePassPurchaseFinished`; `UpdateAsync` con sus presupuestos y la cola de 30; `BindToClose` (30 s, en paralelo); `PolicyService` (`ArePaidRandomItemsRestricted`); `AnalyticsService` (4 métodos; en `LogEconomyEvent` el `amount` va antes de `endingBalance`); `MessagingService`; `Player:GetJoinData`; `task.*`.
- **Existe pero la semántica no está verificada:** `ConfigService:GetConfigAsync` (refresco).
- **Sin verificar:** qué ID de pase esperan `PromptGamePassPurchase` y `GetProductInfoAsync`, y todo lo que solo se ve en el motor real (replicación, orden de scripts de Rojo, Player Emulator).
- **`ProcessReceipt` es "legacy"** frente a `BindReceiptHandler`; el `VERIFY` del código es correcto. Migrar es un trabajo futuro.

## 7. Prioridades que quedan

1. Rellenar `ProductIds.luau` con IDs reales, ejecutar `FF_RELEASE_CHECK=1 bash ROBLOX/tools/test.sh` y probar en Studio una compra real de cada producto y de cada pase (resuelve el bloqueo 3).
2. Decidir DATA-01 (tiempo de caducidad del bloqueo) y MINI-01 (minijuego).
3. Aplicar los arreglos propuestos de impacto bajo (ANALYTICS-01, OFFLINE-01, PASS-01, CONFIG-01) y fijar `decimals=4` antes de activar suerte de pago.
4. Sustituir el módulo `Data` por ProfileStore para producción, o auditar con la misma exigencia el módulo propio.
5. Una persona debe leer todo lo marcado `REVIEW(money)` antes de publicar.
