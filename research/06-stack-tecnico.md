# Stack técnico y mejores prácticas de ingeniería para una "fábrica" de juegos de Roblox con microtransacciones

Fecha del informe: 2026-10-20 · Área: ingeniería (Luau, compras, datos, arquitectura, seguridad, rendimiento, analítica, aprendizaje).
Audiencia: desarrollador hispanohablante que quiere crear muchos juegos con ayuda de IA y reutilizar código.

---

## 0. Cómo leer este informe

### Leyenda de fiabilidad
- **[OFICIAL]**: documentación de Roblox. Importante: `create.roblox.com` estaba bloqueado (ENOTFOUND), pero el **código fuente de esa documentación es el repositorio público `Roblox/creator-docs`**, accesible vía `github.com` / `raw.githubusercontent.com`. Leí ahí los `.md` y `.yaml` de la referencia de API el 2026-10-20. Cada enlace apunta al archivo del repo; la página pública equivalente es `https://create.roblox.com/docs/...` (misma ruta lógica, no la pude abrir).
- **[TERCERO]**: READMEs/CHANGELOGs de repos de la comunidad, hilos de DevForum, blogs, tweets. Los hilos de DevForum y blogs salieron solo como resultados de búsqueda (no pude abrirlos), así que cito título y URL pero no su contenido completo.
- **[NO VERIFICADO]**: no pude confirmarlo en fuente primaria, o es inferencia mía. **No generar código con estos datos sin comprobarlos primero.**

### Limitaciones de la investigación (honestidad)
1. `WebFetch` falló con ENOTFOUND en: create.roblox.com, devforum.roblox.com, madstudioroblox.github.io, robloxapi.github.io, kitsblox.com, luau.org, pesde.dev, jsdotlua.github.io. No esquivé el proxy. `api.github.com` devolvió 403. El MCP de GitHub solo permite el repo del usuario.
2. Funcionaron `github.com` y `raw.githubusercontent.com`; de ahí sale casi toda la evidencia [OFICIAL] y la de repos.
3. El límite de `WebSearch` (200 por turno, compartido con otros agentes) se agotó tras ~17 búsquedas, así que **no pude buscar** recursos de aprendizaje en español, YouTubers ni comunidades. Esa sección es en buena parte [NO VERIFICADO].
4. `WebFetch` resume el contenido con un modelo pequeño. Los nombres de API y números de este informe vienen de esos resúmenes de fuentes primarias; las citas literales entre comillas son fiables, pero **antes de generar código, contrastar cada firma con el autocompletado de Studio / luau-lsp** (ver sección 9).

---

## 1. Compras: procesarlas bien (donde se pierde dinero)

### 1.1 Developer Products: `MarketplaceService.ProcessReceipt`

Hechos [OFICIAL] ([MarketplaceService.yaml](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/MarketplaceService.yaml), [developer-products.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/developer-products.md), leídos 2026-10-20):

- `ProcessReceipt` es un *callback* que se asigna **una sola vez, en un único Script de servidor**, y debe manejar **todos** los developer products. Si no lo asignas, los recibos se auto-confirman y **no se pueden recuperar después**.
- Campos de `receiptInfo`: `PurchaseId` (string, único por compra), `PlayerId`, `ProductId`, `PlaceIdWherePurchased` (puede ser otro place), `CurrencySpent`, `CurrencyType` (siempre Robux), `ProductPurchaseChannel`.
- Valores de retorno: `Enum.ProductPurchaseDecision.PurchaseGranted` o `NotProcessedYet`.
- Reintentos: "no time-based retry mechanism". Solo se vuelve a invocar en el mismo servidor cuando el usuario inicia otra compra o vuelve a entrar al experience. El usuario **debe estar en el servidor** para que se invoque.
- El callback de una misma compra **puede ejecutarse en dos servidores a la vez** (si el jugador entra a otro servidor antes de que el primero devuelva).
- El callback **puede hacer yield mientras el servidor siga vivo**.
- "Unresolved developer product purchases are not removed or refunded after the escrow period expires".
- Un `PurchaseGranted` puede fallar al registrarse en el backend, y entonces la compra queda sin resolver (se vuelve a entregar).
- Roblox **no guarda historial de compras por usuario**: "it's your responsibility to store the data".
- `PromptProductPurchaseFinished` **no** significa que se haya comprado: no usarlo para entregar. Usar solo `ProcessReceipt`.
- Existe además `BindReceiptHandler(transactionType, handler, filter?)` con `Enum.ReceiptType` (`DeveloperProduct`, `RobuxTransferSender`, `RobuxTransferReceiver`) y `Enum.ReceiptDecision` (`Processed` / `NotProcessedYet`). Los handlers enlazados tienen prioridad; los recibos de developer product sin handler caen a `ProcessReceipt`. Los recibos de Robux Transfers **solo** se manejan por `BindReceiptHandler` ([robux-transfers.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/robux-transfers.md)).
  - Nota de diseño: dos enums distintos (`ProductPurchaseDecision` vs `ReceiptDecision`). **No mezclarlos en código generado.**

### 1.2 Flujo correcto (oficial) para entregar sin duplicar ni perder

[OFICIAL] [player-data-purchasing.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/data-stores/player-data-purchasing.md): devolver `PurchaseGranted` **solo después de guardar**.

1. Esperar a que los datos del jugador estén cargados sin errores (si el jugador se va, devolver `NotProcessedYet`).
2. ¿Ya está registrado el `PurchaseId`? Si está guardado: devolver `PurchaseGranted`. Si está en memoria pero **no guardado**: `NotProcessedYet`.
3. Otorgar el ítem **en memoria**.
4. Registrar el `PurchaseId` **en los mismos datos** (misma tabla, mismo guardado).
5. Guardar en DataStore. Éxito → `PurchaseGranted`. Fallo → `NotProcessedYet` (Roblox reintentará y el paso 2 lo absorbe).

Con ProfileStore ([docs de developer products](https://github.com/MadStudioRoblox/ProfileStore/blob/main/docs/devproducts/index.md), [TERCERO] del autor) hay dos enfoques:
- **Enfoque 1 ("a la Roblox")**: modificar `profile.Data`, llamar `profile:Save()` y devolver. Riesgo: si todas las peticiones de DataStore fallan antes de un crash, se pierde la compra.
- **Enfoque 2 (recomendado para moneda/permanentes)**: guardar el `PurchaseId` en `profile.Data.PurchaseIdCache` (acotado, p. ej. 100), **esperar a que aparezca en `profile.LastSavedData`**, y solo entonces devolver `PurchaseGranted`. El autor avisa de que depende de un comportamiento observado (que `ProcessReceipt` tolere el yield), que la doc oficial confirma ("can yield for as long as the server is running").

Esqueleto ilustrativo (derivado de las dos fuentes; **no ejecutado**; verificar nombres de señales de ProfileStore como `OnAfterSave` y si admite `:Wait()`):

```lua
--!strict
-- Esqueleto de ProcessReceipt idempotente (enfoque 2). ILUSTRATIVO: no ejecutado.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local CACHE_SIZE = 100
-- Profiles[player] lo rellena tu módulo de datos (ProfileStore:StartSessionAsync).
local function process(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local profile = getProfileAsync(player) -- tu función: espera carga, devuelve nil si el jugador se va
	local grant = GrantRegistry[receipt.ProductId] -- por juego; debe devolver true solo si otorgó
	if not profile or not grant or not profile:IsActive() then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local cache = profile.Data.PurchaseIdCache -- debe existir en el template ({}) del perfil
	if not table.find(cache, receipt.PurchaseId) then
		local ok, result = pcall(grant, player, profile.Data, receipt)
		if not ok or result ~= true then -- OJO: comprobar el valor devuelto, no solo el pcall
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		table.insert(cache, receipt.PurchaseId)
		while #cache > CACHE_SIZE do table.remove(cache, 1) end
	end
	-- esperar a que el PurchaseId esté en LastSavedData (guardado confirmado)
	while profile:IsActive() do
		if table.find(profile.LastSavedData.PurchaseIdCache or {}, receipt.PurchaseId) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		profile:Save()
		task.wait(1)
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end
MarketplaceService.ProcessReceipt = process
```

### 1.3 Errores típicos que pierden dinero o duplican ítems

| # | Error | Consecuencia | Fuente |
|---|---|---|---|
| 1 | No asignar `ProcessReceipt`, o asignarlo desde 2 scripts | Recibos auto-confirmados e irrecuperables / error | [OFICIAL] developer-products.md |
| 2 | Devolver `PurchaseGranted` antes de guardar | Compra perdida si el servidor cae | [OFICIAL] player-data-purchasing.md |
| 3 | Otorgar y devolver `NotProcessedYet` **sin** registrar `PurchaseId` | Entrega doble en el reintento | [OFICIAL] (flujo de 5 pasos) |
| 4 | No deduplicar por `PurchaseId` (el callback puede correr en 2 servidores) | Duplicados | [OFICIAL] MarketplaceService.yaml |
| 5 | `pcall` que solo mira errores y no el valor que devuelve el handler | Un handler que devuelve `nil`/`false` acaba dando `PurchaseGranted` (compra "tragada") | [OFICIAL] (la propia doc señala el fallo en su ejemplo) + hilos [TERCERO] [1](https://devforum.roblox.com/t/marketplaceservice-processreceipt-code-sample-robs-players-of-money/2021619), [2](https://devforum.roblox.com/t/logic-error-in-the-processreceipt-example-code-will-cause-player-to-get-the-same-paid-items-with-every-server-join-after-purchase/3563250) (títulos vistos en búsqueda; contenido no abierto) |
| 6 | Entregar con `PromptProductPurchaseFinished` / `PromptGamePassPurchaseFinished` sin verificar | Entrega sin cobro o spoofing | [OFICIAL] dice que no se usen para entregar; [TERCERO] hay quejas de spoofing |
| 7 | Perfil en estado de error con datos por defecto | Ítem "gratis" en la sesión y pérdida de datos si se guarda encima | [OFICIAL] player-data-purchasing.md: marcar el perfil como errored, no guardarlo, bloquear compras |
| 8 | Precios *hard-coded* en la UI | Con Regional Pricing el cobro difiere del precio mostrado | [OFICIAL] regional-pricing.md |
| 9 | Ignorar reembolsos | Jugador conserva ítems tras reembolso | [OFICIAL] existe webhook "Transaction Refunded" (sección 1.6) |
| 10 | Usar DataStore en Studio con "API access" apuntando a datos de producción | Sobrescribir datos vivos | [OFICIAL] data-stores/index.md |
| 11 | Caché de `UserOwnsGamePassAsync` mal entendida | "No reconoce mi pase" tras comprar | [OFICIAL] sección 1.3 |
| 12 | No bloquear compras mientras el perfil carga o falló el guardado | Entregas sin persistir | [OFICIAL] |
| 13 | Usar `TeleportData` para pasar moneda/inventario | Datos visibles y no confiables | [OFICIAL] teleport.md |
| 14 | Ventas cruzadas de pases entre juegos | **Desactivadas desde el 2026-05-30**: "Starting May 30, 2026, cross-game pass sales will be disabled" | [OFICIAL] [passes.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/passes.md) |

### 1.4 Game Passes: `PromptGamePassPurchase`, `UserOwnsGamePassAsync`

[OFICIAL] ([MarketplaceService.yaml](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/MarketplaceService.yaml), [passes.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/passes.md)):
- `UserOwnsGamePassAsync(userId, gamePassId)`: yield, cliente y servidor, **con caché**. `PromptGamePassPurchaseFinished` **refresca** la caché. Compras hechas **fuera** del experience durante la misma sesión pueden tardar varios minutos en reflejarse. Tras comprar, **la primera entrada siempre devuelve `true`**.
- `PromptGamePassPurchaseFinished(player, gamePassId, wasPurchased)`: "Listen on the server only".
- Los pases **no necesitan `ProcessReceipt`**, pero deben estar *Listed* para aparecer fuera del juego. Roblox no guarda historial por usuario.
- Patrón: comprobar con `pcall` en `PlayerAdded` + escuchar el evento para compras a mitad de sesión.
- La doc dice que `gamePassId` es el `TargetId` del pase, no el asset ID ni el `ProductId` — **[NO VERIFICADO] la distinción exacta; comprobar el ID que se usa en los dos sitios del Creator Hub**.
- [TERCERO] hilos de DevForum ([1](https://devforum.roblox.com/t/userownsgamepassasync-caching-problem/3222173), [2](https://devforum.roblox.com/t/do-not-cache-results-of-userownsgamepassasync/3639404), [3](https://devforum.roblox.com/t/userownsgamepassasync-api-is-imprecise/4122302)) discuten latencia/imprecisión y spoofing del evento. Mi recomendación **[NO VERIFICADO, inferencia]**: al recibir `wasPurchased == true`, re-verificar con `UserOwnsGamePassAsync` (cuya caché la doc dice que el evento refresca) antes de otorgar y guardar el flag en el perfil.
- Se puede suspender el *prompt* si el jugador ya posee el pase (la doc lo recomienda).

### 1.5 Suscripciones (no existe `SubscriptionService`)

No hay un servicio `SubscriptionService`; la API vive en `MarketplaceService` + `Players` [OFICIAL] ([subscriptions.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/subscriptions.md), [Players.yaml](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/Players.yaml)):

| API | Notas |
|---|---|
| `MarketplaceService:GetUserSubscriptionStatusAsync(user, subscriptionId)` → `{IsSubscribed, IsRenewing}` | Servidor. `IsSubscribed` es false mientras el pago inicial se procesa o falla |
| `MarketplaceService:GetUserSubscriptionDetailsAsync(user, subscriptionId)` | Solo Script de servidor: `SubscriptionState`, `NextRenewTime`, `ExpireTime`, `ExpirationDetails` |
| `MarketplaceService:GetUserSubscriptionPaymentHistoryAsync(user, subscriptionId)` | Solo servidor; historial de hasta 1 año para creadores afiliados |
| `MarketplaceService:GetSubscriptionProductInfoAsync(subscriptionId)` | **Solo cliente** (precios localizados) |
| `MarketplaceService:PromptSubscriptionPurchase(user, subscriptionId)` / `PromptCancelSubscription(...)` | Prompt |
| `MarketplaceService.PromptSubscriptionPurchaseFinished(user, subscriptionId, didTryPurchasing)` | Rechequear estado ~10 s después (el registro tarda) |
| `Players.UserSubscriptionStatusChanged(user, subscriptionId)` | Servidor; se comprueba tras cerrar el modal de compra |
| `MarketplaceService:PromptRobloxSubscriptionPurchase(user)` / `GetRobloxSubscriptionDetailsAsync(user)` | Roblox Plus (sustituye a `PromptPremiumPurchase`, deprecado) |

Patrón oficial: comprobar en `PlayerAdded` y en `UserSubscriptionStatusChanged`; conceder si `IsSubscribed`, revocar si estaba concedido y ya no. Para migrar de pase a suscripción: comprobar primero `UserOwnsGamePassAsync`.

Datos de negocio (solo para ingeniería; detalle en otra área): mínimo 49 Robux; precios en moneda local con 5 niveles fijos; hasta 50 suscripciones por juego; Robux se pueden cambiar cada 60 días con 30 días de aviso; las suscripciones **no** se pueden vender cruzadas entre juegos. **No hay cobertura de pruebas en Studio en la doc leída** [NO VERIFICADO cómo probarlas; un hilo [TERCERO] sobre un bug del prompt de Roblox Plus en Studio: [enlace](https://devforum.roblox.com/t/promptrobloxsubscriptionpurchase-subscribe-button-doesnt-work-in-studio/4607010)].

**Webhooks de Open Cloud** [OFICIAL] ([webhook-notifications.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/webhooks/webhook-notifications.md)): eventos de suscripción (Purchased, Renewed, Resubscribed, Refunded, Cancelled con motivo), "Transaction Refunded" (dev products, pases, servidores privados, acceso de pago; **no** suscripciones), "Right to Erasure", "Early Harm Detection" (experimentos) y `SampleNotification`. **No existe webhook de "compra de dev product/pase"** (solo reembolso). Firma HMAC-SHA256 en base64: cabecera `t=<timestamp>,v1=<firma>` sobre `timestamp.body`; 5 reintentos; el endpoint debe responder 2XX en ≤5 s; máximo 5 webhooks; los eventos pueden duplicarse (deduplicar por `NotificationId`).

### 1.6 Regalos (gifting)
- **No encontré API oficial de regalos** para developer products/pases en lo leído. Lo único oficial relacionado: `GetUsersPriceLevelsAsync` "protege trades y regalos" bajo Managed Pricing ([regional-pricing.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/regional-pricing.md)), y *Robux Transfers* (solo emisores Roblox Plus; 10–500 Robux; el juego se queda el 10%) ([robux-transfers.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/robux-transfers.md)).
- Diseño propio **[NO VERIFICADO]**: el comprador paga un dev product; antes de pagar el servidor registra (en memoria/MemoryStore) el destinatario; en `ProcessReceipt` se acredita **al destinatario** y se entrega por `ProfileStore:MessageAsync` si está offline. Riesgos: recibo reintentado en otro servidor, destinatario inexistente, y *price levels* para impedir "lavado" de valor.

### 1.7 Políticas por región: `PolicyService:GetPolicyInfoForPlayerAsync`

[OFICIAL] ([PolicyService.yaml](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/PolicyService.yaml), [paid-random-items.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/paid-random-items.md)):
- `GetPolicyInfoForPlayerAsync(player)` yield, devuelve diccionario por geolocalización/edad/plataforma. Envolver en `pcall`. Falla si se llama >100 veces antes de recibir respuesta. En cliente solo para el jugador local.
- Campos: `AreAdsAllowed`, `ArePaidRandomItemsRestricted`, `IsContentSharingAllowed`, `IsEligibleToPurchaseCommerceProduct`, `IsEligibleToPurchaseSubscription`, `IsPaidItemTradingAllowed`, `IsPhotoToAvatarAllowed`, `IsSubjectToChinaPolicies`, `IsEndlessContentLoadAllowed`, `IsEndlessContentAutoplayAllowed`, `AllowedExternalLinkReferences` (heredado; siempre vacío).
- **Paid Random Items** (cajas, ruletas, huevos, pociones aleatorias, boosts de suerte, pity…): obligatorio mostrar **todos los resultados y probabilidades numéricas que sumen exactamente 100%**, antes de gastar la moneda (incluye monedas compradas con Robux). Si `ArePaidRandomItemsRestricted == true`: ofrecer alternativa (vía gratuita, orden fijo y divulgado, compra directa por valor esperado, ocultar/bloquear). Si `IsPaidItemTradingAllowed == false`: no permitir intercambiar los resultados de ítems pagados.
- La doc leída **no da fechas de entrada en vigor ni sanciones**. Un blog [TERCERO] ([enlace](https://zehn-studio26.com/news/paid-random-items-odds-disclosure/)) afirma vigencia desde 2026-05-26 y regiones (Australia, Bélgica, Países Bajos, Reino Unido, Brasil): **[NO VERIFICADO]**. Hay un anuncio de DevForum ["Clarifying Requirements for Paid Random Items"](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622) (título visto en búsqueda; no abierto).
- Regla de ingeniería: **cachear el resultado por jugador al unirse, en el servidor, y centralizar** en un módulo `Policy` (la tienda y cualquier generador aleatorio consultan ahí, nunca directamente).

### 1.8 Precios dinámicos
[OFICIAL] ([managed-pricing.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/managed-pricing.md), [price-optimization.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/price-optimization.md)): precios regionales entre 30% y 100% del precio base; mostrar precios con `GetProductInfoAsync` / `GetDeveloperProductsAsync`, nunca hard-coded; *price optimization* exige ~60 000 transacciones en 30 días (los juegos nuevos no entran), solo pases y dev products, y los scripts de precio deben ejecutarse en el **cliente**; `receiptInfo` da el Robux exacto pagado.

---

## 2. Persistencia de datos

### 2.1 Comparativa

| Opción | Estado (2026-10-20) | Session locking | Veredicto |
|---|---|---|---|
| **ProfileStore** (loleris / MadStudioRoblox) | Sucesor de ProfileService. Un solo ModuleScript, Apache-2.0, 32 commits [TERCERO] | Sí (con MessagingService) | **Recomendado por defecto** |
| ProfileService | Predecesor; ProfileStore lo mejora [TERCERO] | Sí (solo `UpdateAsync`, no sabe si el servidor dueño sigue vivo) | Migrar en proyectos nuevos |
| **Lapis** (nezuo) | README: validación, migraciones, inmutabilidad, reintentos, autosave 5 min, **"not battle-tested in a large production game yet"** [TERCERO] | Sí | Alternativa interesante; evaluar con riesgo |
| DataStore2 | Repo `Kampfkarren/Roblox`, README sin nota de deprecación pero con "documentación casi nula" [TERCERO]. No pude leer su README principal | **[NO VERIFICADO]** | No recomendado para juegos nuevos con economía/trading |
| `DataStoreService` directo | Oficial. La doc incluye un ejemplo completo de cola con reintentos + session locking pero avisa: "has not been proven over a long period in a popular game" | Lo implementas tú | Solo si necesitas control total |

Fuentes: [ProfileStore README](https://github.com/MadStudioRoblox/ProfileStore) · [código y API](https://raw.githubusercontent.com/MadStudioRoblox/ProfileStore/main/ProfileStore.luau) · [api.md](https://github.com/MadStudioRoblox/ProfileStore/blob/main/docs/api.md) · [Lapis](https://github.com/nezuo/lapis) · [player-data-purchasing.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/data-stores/player-data-purchasing.md) [OFICIAL]. Hilos/artículos [TERCERO] (solo títulos): [ProfileStore (DevForum)](https://devforum.roblox.com/t/profilestore-save-your-player-data-easy-datastore-module/3190543), [DataStoreService vs ProfileService](https://devforum.roblox.com/t/datastoreservice-vs-profileservice-which-should-you-use-for-your-game/3582901), [tweet de loleris](https://x.com/lolerismad/status/1934666444660150570) (afirma que Grow a Garden usa ProfileService/ProfileStore; **[NO VERIFICADO]**).

### 2.2 ProfileStore: lo esencial para generar código [TERCERO, fuente primaria del autor]
API leída en el código y `api.md` (2026-10-20):
- `ProfileStore.New(storeName, template?)`; `ProfileStore:StartSessionAsync(profileKey, {Steal?, Cancel?})` → `Profile?` (puede devolver `nil` si hay carrera entre servidores: **expulsar al jugador**).
- `Profile.Data` (tabla), `Profile.LastSavedData`, `Profile:IsActive()`, `Profile:Reconcile()` (rellena campos nuevos desde el template), `Profile:EndSession()`, `Profile:Save()` (cuesta 1 `UpdateAsync`; pensado para momentos críticos como compras), `Profile:AddUserId/RemoveUserId` (cumplimiento GDPR), `Profile:MessageHandler(fn)` y `ProfileStore:MessageAsync(key, msg)` (mensajes a perfiles online u offline; cuesta 2 `UpdateAsync`), `ProfileStore:GetAsync`, `:VersionQuery` (leer versiones antiguas), `:RemoveAsync`, `ProfileStore.Mock` (almacén temporal para Studio).
- Señales: `OnSave`, `OnLastSave(reason)` ("Manual"/"External"/"Shutdown"), `OnSessionEnd` (úsala para expulsar o dejar de modificar), `OnAfterSave`.
- Constantes por defecto: `AUTO_SAVE_PERIOD = 300 s`, `SESSION_STEAL = 40 s`, `ASSUME_DEAD = 630 s`, `START_SESSION_TIMEOUT = 120 s`; suscripción a MessagingService por tema `"PS_" .. sessionId` (máx. 1 mensaje/6 s). 
- Avisos del autor: `Steal` rompe el session lock (solo depuración); los cambios en `Data` solo se garantizan si se hacen justo tras `IsActive()` sin yield; `RobloxMetaData` ≈ 300 caracteres; en Studio con API access el store por defecto escribe en claves **reales** (usar `.Mock`); **no sirve para leaderboards ni estado global**.
- **No hay migraciones de esquema integradas**: solo `Reconcile()` (añadir campos). Para cambios de forma, añade `Data.SchemaVersion` y una cadena de funciones `migrate_N_to_N+1` tras `StartSessionAsync` (patrón propio; Lapis sí las trae).

### 2.3 Límites y presupuestos de DataStore [OFICIAL] ([error-codes-and-limits.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/data-stores/error-codes-and-limits.md))

| Concepto | Límite |
|---|---|
| Lectura/escritura estándar por servidor (por minuto) | 60 + numPlayers × 40 (ambos) |
| Ordered DS: escritura / remove | 30 + numPlayers × 5 |
| List por servidor | 5 + numPlayers × 2 |
| A nivel experience (compartido con Open Cloud) por minuto | Read 300 + CCU × 40; Write 300 + CCU × 20; List 300 + CCU × 2; Remove 300 + CCU × 40 |
| Por clave (ventana de 60 s, todos los servidores) | Lectura 25 MB; escritura 4 MB |
| Tamaños | Nombre/clave/scope 50 caracteres; valor 4 194 304 por clave; metadata de valor 250 caracteres (300 total) |
| Almacenamiento | 500 MB + 1 MB × usuarios de por vida (tamaño comprimido, solo última versión) |

(La doc no incluye la fórmula "60 + numPlayers*10" que a veces se cita; usar la tabla.) Prácticas oficiales ([best-practices.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/data-stores/best-practices.md), [versioning-listing-and-caching.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/data-stores/versioning-listing-and-caching.md)):
- Una tabla por jugador en una sola clave; datos en memoria; guardar al cargar/autosave/compra/salida/cierre del servidor. Autosave con *jitter* aleatorio. `BindToClose` dispone de unos 30 s: guardar en paralelo.
- Reintentos con backoff exponencial + jitter y **en orden por clave** (un reintento tardío puede pisar un dato más nuevo). Preferir `UpdateAsync` cuando la escritura depende del valor actual. **El callback de `UpdateAsync` no puede hacer yield.**
- `GetAsync` se cachea 4 s por instancia (`DataStoreGetOptions.UseCache=false` para saltarlo).
- Claves estáticas basadas en identificadores estables (`Player_{UserId}`), con prefijos.

### 2.4 Backups y recuperación [OFICIAL]
- Versionado: la primera escritura de cada hora UTC crea una copia de seguridad; las copias antiguas caducan 30 días después de ser sobrescritas por una versión más nueva. `ListVersionsAsync`, `GetVersionAsync`, restauración con `SetAsync` + metadata.
- **API Open Cloud "Snapshot Data Stores"**: snapshot diario de todos los data stores; hacer uno **antes de publicar cambios en la lógica de datos**.
- Observabilidad: dashboard de DataStores y Data Stores Manager; alertas de uso de DataStore (hasta 20 alertas por experience; requiere ≥100 DAU) ([alerts.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/alerts.md)).
- **Derecho al olvido (RTBF)**: hasta 100 plantillas con el token `{UserId}` (sensible a mayúsculas) en el Data Stores Manager o por Open Cloud Configs; verificar la eliminación en ≤30 días (buena práctica) ([right-to-be-forgotten.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/data-stores/right-to-be-forgotten.md)). Con ProfileStore: `AddUserId`.

### 2.5 Multi-juego: los datos no se comparten solos
Los DataStores son **por universo (juego)**; "shared across all places in a game" [OFICIAL] ([data-stores/index.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/data-stores/index.md)). Compartir cuenta/inventario entre juegos requiere Open Cloud (API key) o un backend propio vía `HttpService` (máx. 500 peticiones/min/servidor; secretos con `HttpService:GetSecret()`; solo HTTPS) [OFICIAL] ([http-service.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/http-service.md), [secrets.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/secrets.md)). Recomendación: **no compartir datos entre juegos al principio**; cada juego su ProfileStore.

---

## 3. Estado de herramientas y frameworks (2026-10-20)

| Herramienta | Qué es | Estado verificado | Decisión sugerida |
|---|---|---|---|
| **Rokit** | Gestor de toolchain (sucesor de Foreman/Aftman) | Activo, MIT, ~482 estrellas [TERCERO]. La doc oficial usa un `rokit.toml` con `rojo 7.6.1`, `wally 0.3.2`, `lune 0.10.4` [OFICIAL] ([external-tools.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/projects/external-tools.md)) | Usar y **fijar versiones** |
| **Rojo** | Sincroniza archivos con Studio, `rojo build`, `sourcemap`, `syncback` | **7.7.1 (2026-10-01)**; 7.7.0 (2026-07-01) [TERCERO] ([CHANGELOG](https://raw.githubusercontent.com/rojo-rbx/rojo/master/CHANGELOG.md)). Arreglo en 7.7.1: `$path` fuera de la carpeta del proyecto con `syncRule`s | Usar |
| **Wally** | Gestor de paquetes (realms `shared`/`server`) | Última versión publicada **0.3.2 (2023-06-05)**; cambios sin lanzar en `main` [TERCERO] ([CHANGELOG](https://raw.githubusercontent.com/UpliftGames/wally/main/CHANGELOG.md)); sigue siendo el recomendado por la doc oficial | Usar para dependencias de terceros |
| **pesde** | Gestor de paquetes alternativo (Roblox/Lune) | 0.7.3 (2026-03-18); "Unreleased" con rediseño de workspaces y *string requires* también para Wally [TERCERO] ([CHANGELOG](https://raw.githubusercontent.com/pesde-pkg/pesde/main/CHANGELOG.md)) | **Esperar** a la siguiente versión estable; no usar aún |
| **StyLua** | Formateador | 2.6.0 (2026-10-10) [TERCERO] | Usar en CI (`--check`) |
| **Selene** | Linter | 0.32.0 (2026-10-01) [TERCERO] | Usar |
| **luau-lsp** | LSP + `analyze` para CI | **1.70.1 (2026-09-27)** sincronizado con Luau 0.740 [TERCERO] ([CHANGELOG](https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/CHANGELOG.md)); usa `sourcemap.json` de Rojo | Usar (editor + CI) |
| **Lune** | Runtime Luau independiente, con librería para leer/escribir archivos de place | Activo, MPL-2.0 [TERCERO] | Scripts de build/deploy y tests de lógica pura |
| **Jest Lua** | Tests (Jest 27.4.7); "can currently only run inside of Roblox" | Usado internamente por Roblox; README: "battle-tested" [TERCERO] | Tests dentro de Roblox |
| **TestEZ** | Tests antiguos | **Archivado 2024-09-14** [TERCERO] | No usar |
| **Knit** | Framework de servicios/controladores | **Archivado 2024-07-31**: "will no longer receive updates". El autor recomienda ModuleScripts + un wrapper fino de remotes + `assert` de tipos [TERCERO] ([README](https://github.com/Sleitnick/Knit), [ARCHIVAL.md](https://raw.githubusercontent.com/Sleitnick/Knit/main/ARCHIVAL.md)) | **Sí, está deprecado. No usarlo** |
| **React Lua** (`jsdotlua/react-lua`) | Traducción de React 17.x | La doc oficial lo pinea como `react = "jsdotlua/react@17.2.1"`, `react-roblox` 17.2.1 [OFICIAL] | UI por defecto |
| Fusion | UI reactiva | Activo (804★); versión actual no verificada [TERCERO] | Alternativa; no mezclar con React |
| Matter (ECS) | ECS | 0.8.4, no archivado [TERCERO] | Solo si hay muchísimas entidades |
| Zap / Blink | Redes con buffers (IDL → Luau) | Zap: rama principal en reescritura, 0.6.x mantenida por sasial-dev; Blink activo (489 commits) [TERCERO] | Opcional (rendimiento); el wrapper fino es suficiente al inicio |
| roblox-ts / Flamework | TypeScript → Luau | roblox-ts activo (2 544 commits) [TERCERO]; compatibilidad con Wally/pesde **[NO VERIFICADO]** | Evitar: capa extra, ecosistema paralelo |
| Roblox Studio MCP (integrado) y **Script Sync (beta)** | Integración IA ↔ Studio | La doc oficial describe un "coding harness": Script Sync enlaza servicios de Studio con carpetas locales y el MCP de Studio permite leer el árbol, crear objetos, ejecutar scripts y comprobar salida [OFICIAL] ([coding-harness.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/ai/coding-harness.md), [mcp.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/assistant/mcp.md)) | Útil para IA. El repo independiente `Roblox/studio-rust-mcp-server` está **archivado desde 2026-04-03** y Roblox recomienda el MCP integrado [OFICIAL/TERCERO] ([repo](https://github.com/Roblox/studio-rust-mcp-server)) |

### Luau puro vs roblox-ts (recomendación)
**Luau puro con `--!strict`.** Razones: (1) el código generado por IA es más fiable cuando no hay una capa de compilación; (2) el tipado de Luau (`--!nocheck`/`--!nonstrict`/`--!strict` por script, `export type`, genéricos) ya cubre la necesidad [OFICIAL] ([type-checking.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/luau/type-checking.md)); (3) luau-lsp + `analyze` en CI detectan APIs inventadas. Caveat: en luau-lsp los tipos del DataModel resuelven a `any` por defecto salvo `strictDatamodelTypes` [TERCERO]. 
Funciones nuevas vistas en changelogs de luau-lsp: *string requires* con alias (`require("@Packages/JestGlobals")` aparece en el README de Jest Lua) y locales `const`. **[NO VERIFICADO] que el runtime de Roblox en producción los soporte para tus juegos; la doc oficial de módulos solo muestra `require(Instance)`** ([module.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/module.md)). Para código generado: usar `require(<Instance>)` hasta confirmarlo.

---

## 4. Arquitectura propuesta para un monorepo de múltiples juegos

### 4.1 Principios
1. **Juegos finos, paquetes gruesos.** Un juego = configuración + contenido + reglas propias; compras, datos, economía, tienda, analítica, seguridad y UI viven en paquetes compartidos.
2. **Todo guiado por datos (`game.config`).** IDs de productos/pases/suscripciones, monedas, tablas de loot y *feature flags* en un módulo de datos por juego; el código de paquetes solo lee la config.
3. **Una sola puerta para cada riesgo**: un `PurchaseRouter` (único `ProcessReceipt`), un `Policy` (único acceso a `PolicyService`), un `Remotes` (toda validación), un `Analytics` (todos los eventos), un `LiveConfig` (todo `ConfigService`).
4. **Lógica pura separada de servicios de Roblox** para poder testearla fuera de Studio (Lune) y con Jest Lua dentro de Roblox.
5. **Los paquetes compartidos se mapean con Rojo (`$path`) al principio**, sin registro: Rojo 7.7.1 menciona arreglos para `$path` que apuntan fuera de la carpeta del proyecto [TERCERO]. Pasar a versionado/registro solo cuando haya >5 juegos o varios colaboradores. Wally solo para dependencias de terceros.

### 4.2 Estructura

```
roblox-games/
├─ rokit.toml                    # rojo, wally, stylua, selene, luau-lsp, lune: VERSIONES FIJADAS
├─ stylua.toml  selene.toml  .luaurc  .gitignore  CLAUDE.md   # convenciones para la IA
├─ packages/                     # código propio reutilizable (--!strict en todo)
│  ├─ Core/        # Signal, Trove/Janitor (vía Wally), Result, logging, tipos base
│  ├─ Data/        # envoltorio de ProfileStore: SchemaVersion + migraciones, Reconcile,
│  │               # réplica al cliente (claves privadas/públicas), estado "errored"
│  ├─ Purchases/   # PurchaseRouter (único ProcessReceipt), PurchaseLedger (PurchaseId),
│  │               # GrantRegistry por ProductId, PassOwnership (caché), Subscriptions,
│  │               # RefundHandler (webhook→cola externa), Mocks de MarketplaceService
│  ├─ Economy/     # monedas, fuentes/sumideros, transacciones atómicas; log LogEconomyEvent
│  ├─ Shop/        # catálogo desde config; precios con GetProductInfoAsync; gating por Policy
│  ├─ Policy/      # PolicyService cacheado por jugador (RandomItems, Trading, Subscription…)
│  ├─ Remotes/     # remotes tipados, validación, rate limiting (token bucket), honeypots
│  ├─ Analytics/   # nombres de eventos como constantes, funnels, helpers de custom fields
│  ├─ LiveConfig/  # ConfigService con valores por defecto, snapshots, refresh, flags
│  ├─ UIKit/       # React Lua + tokens de tema, componentes móvil primero
│  └─ TestKit/     # utilidades de test y dobles (ProfileStore, MarketplaceService)
├─ games/
│  ├─ game-a/
│  │  ├─ default.project.json    # mapea ../../packages/* y src/ del juego
│  │  ├─ wally.toml  wally.lock  # dependencias de terceros
│  │  ├─ game.config.luau        # productIds, monedas, drops con probabilidades, flags
│  │  ├─ src/{server,client,shared}/
│  │  └─ world/                  # (opcional) .rbxm del mapa
│  └─ game-b/ ...
├─ templates/game-template/      # esqueleto clonable para un juego nuevo
├─ tools/                        # scripts Lune: build, deploy, sync de productos, exportar métricas
├─ .github/workflows/{ci.yml,deploy.yml}
└─ docs/                         # ADRs, runbooks, checklist de lanzamiento
```

Ejemplo ilustrativo de proyecto Rojo (formato recordado, **[NO VERIFICADO]**: la documentación de formato de Rojo devolvió 404; comprobar con `rojo init`):

```json
{
  "name": "game-a",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "Packages":  { "$path": "Packages" },
      "Shared":    { "$path": "../../packages/Core" },
      "Game":      { "$path": "src/shared" }
    },
    "ServerScriptService": {
      "ServerPackages": { "$path": "ServerPackages" },
      "Game":           { "$path": "src/server" }
    },
    "StarterPlayer": { "StarterPlayerScripts": { "Game": { "$path": "src/client" } } }
  }
}
```
Regla de seguridad: los paquetes con lógica de servidor (Purchases, Data, Policy, partes de Economy) se mapean **solo** bajo `ServerScriptService`/`ServerStorage`; nunca en `ReplicatedStorage` ([access-control.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/security/access-control.md) [OFICIAL]: lo que replica puede extraerse; no mezclar lógica de cliente y servidor en un ModuleScript).

### 4.3 Integración continua y despliegue (GitHub Actions + Open Cloud)

Pipeline por juego (matriz + filtros de ruta `games/<x>/**` y `packages/**`):
1. Instalar toolchain con Rokit (`rokit install`). El nombre de la acción de Rokit para Actions **no está verificado**; alternativa segura: instalar el binario de Rokit desde su release.
2. `wally install` en cada juego.
3. `stylua --check`, `selene`, `rojo sourcemap` + `luau-lsp analyze` (los *flags* exactos: **[NO VERIFICADO]**, comprobar con `luau-lsp analyze --help`).
4. Tests: lógica pura con Lune; tests dependientes de Roblox con Jest Lua dentro de Roblox (ver abajo).
5. `rojo build games/<x>/default.project.json -o build/<x>.rbxl`.
6. Publicar con Open Cloud.

Publicación [OFICIAL] ([usage-place-publishing.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/usage-place-publishing.md)): `POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published` con cabecera `x-api-key`, cuerpo binario `.rbxl` (`application/octet-stream`) o `.rbxlx` (`application/xml`); permiso `universe-places` con *Write* sobre el juego; respuesta `{ "versionNumber": N }`. **No actualiza** `EditableImage`, `EditableMesh`, `PartOperation`, `SurfaceAppearance`, `BaseWrap`: si los modificas, publica desde Studio. (El valor `Saved` de `versionType` aparece solo en fuentes [TERCERO] — [rbxcloud](https://github.com/Sleitnick/rbxcloud) y acciones de la comunidad — **[NO VERIFICADO]** en la doc oficial.)

Esqueleto ilustrativo del paso de despliegue (no ejecutado):

```yaml
- name: Publicar place (Open Cloud)
  env:
    RBX_API_KEY: ${{ secrets.RBX_KEY_GAME_A }}   # una clave por juego, restringida a ese experience
    UNIVERSE_ID: ${{ vars.GAME_A_UNIVERSE_ID }}
    PLACE_ID:    ${{ vars.GAME_A_PLACE_ID }}
  run: |
    curl --fail --silent --show-error --location --request POST \
      "https://apis.roblox.com/universes/v1/${UNIVERSE_ID}/places/${PLACE_ID}/versions?versionType=Published" \
      --header "x-api-key: ${RBX_API_KEY}" \
      --header "Content-Type: application/octet-stream" \
      --data-binary @build/game-a.rbxl
```

Claves de API [OFICIAL] ([api-keys.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/auth/api-keys.md), [rate-limits.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/reference/rate-limits.md)): "equivalent to a password"; una clave por aplicación, permisos mínimos, restringir por experience; **auto-expiran tras 60 días sin uso** (planificar rotación); no guardarlas en git (usar Secrets de GitHub; dentro de Roblox, el Secrets Store); expirar y manejar 429 con `retry-after`/backoff; los límites son compartidos entre todas las claves del mismo dueño.

Entornos: **un universo de staging privado por juego** (recomendado por la doc: separar entornos de desarrollo/prueba en universos privados distintos), con aprobación manual (GitHub Environments) antes de producción **[recomendación propia]**.

**Cómo evitar que `rojo build` pise el mapa** (decisión de diseño importante; análisis propio **[NO VERIFICADO]**): `rojo build` genera el place desde lo que hay en el repo. Opciones: (A) mantener el mapa como `.rbxm` versionado en el repo (puede requerir Git LFS) y publicar siempre el place completo; (B) publicar **solo código** con la API de instancias de Open Cloud (beta; solo lee/actualiza `Script`/`LocalScript`/`ModuleScript`; requiere sesión colaborativa habilitada; no puede actualizar scripts abiertos en Studio; cuerpo ≤200 KB) [OFICIAL] ([instance.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/instance.md)); (C) publicar el mapa desde Studio y usar CI solo para validar. Para juegos pequeños y repetitivos recomiendo (A) con mapas hechos de partes/meshes simples.

Tests en CI: Jest Lua "can only run inside of Roblox" [TERCERO]. Opción oficial: **Luau Execution API** (beta): `POST /cloud/v2/universes/{universe_id}/places/{place_id}/luau-execution-session-tasks`; tareas de hasta 5 min, 10 concurrentes por place; DataStores y HttpService deshabilitados; los cambios no se guardan; scope `luau-execution-sessions:write` (otra fuente lo nombra `universe.place.luau-execution-session:write`) [fuente: resultados de búsqueda sobre la [página oficial](https://create.roblox.com/docs/cloud/reference/features/luau-execution) y el [anuncio beta](https://devforum.roblox.com/t/beta-open-cloud-engine-api-for-executing-luau/3172185); **no pude abrirlas** → **[NO VERIFICADO]**]. Un reporte de bug [TERCERO] ([enlace](https://devforum.roblox.com/t/luau-execution-task-creation-has-an-undocumented-30hour-limit-per-api-key-owner-far-below-the-documented-5min/4890044)) dice que el límite real es ~30 tareas/hora por dueño de clave frente a 5/min documentados (**[NO VERIFICADO]**). La API antigua `open-eval-api` (beta; 100 peticiones/día para `POST /eval`) [OFICIAL] ([v1.json](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/cloud/open-eval-api/v1.json)) parece su predecesora; **no usar para CI**.

### 4.4 Automatización de catálogos entre juegos [OFICIAL, beta]
Open Cloud permite crear/actualizar developer products (`/developer-products/v2/universes/{universeId}/developer-products`, scope `developer-product:write`, 3 req/s) y pases (`/game-passes/v1/universes/{universeId}/game-passes`, `game-pass:write`, 5 req/s) ([developer-products v1.json](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/cloud/developer-products-api/v1.json), [game-passes v1.json](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/cloud/game-passes-http-service/v1.json)). Ambos están marcados **BETA** y no se pueden usar con API key desde `HttpService`. Idea: un script Lune que lee `game.config.luau` y crea/actualiza productos en cada juego para que los IDs queden consistentes.

### 4.5 Flujo de trabajo con IA
- `CLAUDE.md` en la raíz: reglas (`--!strict`, un solo `ProcessReceipt`, jamás confiar en el cliente, checklist de compras de la sección 1.3).
- **CI como red de seguridad**: `luau-lsp analyze` + Selene + StyLua + tests; así se detectan APIs inventadas.
- Mantener un clon local de [`Roblox/creator-docs`](https://github.com/Roblox/creator-docs) como referencia de la IA (contiene la referencia de API en `.yaml` y todas las guías en `.md`; solo existe el idioma `en-us`).
- Conectar Studio por el MCP integrado / Script Sync (beta) para playtests asistidos [OFICIAL].

### 4.6 Fases sugeridas
0. Toolchain (Rokit/Rojo/Wally/StyLua/Selene/luau-lsp) + CI de lint/tipos. 
1. Paquetes **Data** + **Purchases** (los más críticos) con tests de idempotencia. 
2. **Remotes** + **Policy** + **Analytics** + **LiveConfig**. 
3. **Shop/Economy/UIKit** y plantilla de juego. 
4. Despliegue automático a staging; luego producción con aprobación.

---

## 5. Anti-exploit y seguridad

[OFICIAL] ([client-server-boundary.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/security/client-server-boundary.md), [security-tactics.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/security/security-tactics.md), [defensive-design.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/security/defensive-design.md), [server-side-detection.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/security/server-side-detection.md), [remote.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/events/remote.md)):

**Qué puede hacer un exploiter**: disparar cualquier RemoteEvent/RemoteFunction con argumentos arbitrarios (tipos erróneos, tablas en vez de Instancias, cadenas enormes, NaN/inf, negativos) y a cualquier frecuencia; disparar `ProximityPrompt`/`ClickDetector` desde cualquier distancia (solo `ProximityPrompt.Triggered` tiene comprobación de distancia en servidor); tomar *network ownership* de partes sin anclar; leer y decompilar lo que se replica (LocalScripts, ModuleScripts en cliente).

**Checklist de validación en servidor**
- `typeof()` y clase de Instancia; rechazar tablas donde se esperan Instancias; ubicación en el DataModel.
- Números: `math.isfinite()`, detectar NaN con `x ~= x`, rangos (cantidades > 0).
- Cadenas: tope de longitud y `utf8.len()`; tablas: claves válidas (DataStore rechaza NaN/nil).
- Distancia, estado vivo, propiedad y desbloqueos **comprobados en servidor**.
- Nunca aceptar rutas/Instancias arbitrarias para modificar, ni `require` dinámico por argumentos de remote.
- **Rate limit por jugador** (token bucket) y limpiar buckets en `PlayerRemoving`; cooldowns del lado servidor contra duplicación.
- El servidor es "gatekeeper, not just a relay": validar antes de `FireAllClients()`.
- Preferir `RemoteEvent` a `RemoteFunction` hacia el cliente: `InvokeClient` puede colgar el hilo del servidor para siempre. `UnreliableRemoteEvent`: carga útil ≤1 000 bytes.
- Los datos de teleport **no son seguros** (visibles, sin cifrar).

Ejemplo mínimo de validación (usa solo APIs estándar; ilustrativo):

```lua
--!strict
local function validAmount(x: unknown): number?
	if typeof(x) ~= "number" then return nil end
	if x ~= x or not math.isfinite(x) then return nil end -- NaN / inf
	if x < 1 or x > 99 or x % 1 ~= 0 then return nil end
	return x
end
```

**Economías con trading**: session locking (ProfileStore/oficial) es la defensa principal contra duplicación entre servidores y teletransportes [OFICIAL player-data-purchasing.md]; hacer los intercambios atómicos y validar cada transacción contra el inventario actual del servidor (defensive-design); si el juego permite tradear ítems pagados, comprobar `IsPaidItemTradingAllowed` y usar `GetUsersPriceLevelsAsync` (sin cachear) [OFICIAL]. Registrar todas las transacciones en `Analytics` para poder revertir.

**Detección** [OFICIAL server-side-detection.md]: medir "posible pero improbable" (tiempo récord, tasa de ganancia, cadencia inhumana), *honeypot remotes*, **puntuación de sospecha** y escalar de log silencioso → mitigación discreta (p. ej., rubber-band) → restricciones temporales → expulsión/ban; evitar falsos positivos y baneos permanentes por una única señal. API de baneo: `Players:BanAsync(config)` con `UserIds` (≤50), `Duration` (segundos; `-1` permanente), `DisplayReason` (≤400), `PrivateReason` (≤1000), `ApplyToUniverse` (por defecto `true`), `ExcludeAltAccounts` (por defecto `false`), `ApplyDeviceBlock` (por defecto `false`); además `UnbanAsync` y `GetBanHistoryAsync` [OFICIAL] ([Players.yaml](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/Players.yaml)).

**Server Authority (nuevo modelo de netcode)**: el servidor es la única fuente de verdad y los clientes predicen; elimina flyhacks/speedhacks pero exige `AuthorityMode=Server`, `NextGenerationReplication`, `UseFixedSimulation`, `StreamingEnabled`, `RunService:BindToSimulation()`, etc., y no se indica si es beta o estable [OFICIAL] ([server-authority/index.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/projects/server-authority/index.md)). Probablemente innecesario para simuladores/tycoons; **no lo adoptes de entrada**.

**Código de terceros**: modelos del Creator Store pueden traer *backdoors*; la doc recomienda `SandboxedInstance`/`Sandboxed` + `Capabilities` mínimas y auditar [OFICIAL] ([third-party-vulnerabilities.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/security/third-party-vulnerabilities.md)). Con IA: **no importar modelos gratuitos con scripts**.

---

## 6. Rendimiento móvil, servidores y live-ops

### 6.1 Móvil [OFICIAL] ([test-on-hardware.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/performance-optimization/test-on-hardware.md), [improve.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/performance-optimization/improve.md), [design.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/performance-optimization/design.md), [streaming](https://github.com/Roblox/creator-docs/blob/main/content/en-us/workspace/streaming/index.md))
- Perfil de público (según la doc): Android ≈65% de la base típica de un juego; >50% de jugadores con dispositivos de 10 000–20 000 puntos Passmark; ≈60% de Android con 2–4 GB de RAM, ≈35% con 4–8 GB. Probar en gama baja real (la doc cita Infinix Smart 9, Moto G05, Oppo A18, Fire HD 10, Galaxy S22 Ultra). El emulador de Studio **no** es fiable para memoria. Jugar 10–15 min para detectar *thermal throttling*.
- **Streaming**: activado por defecto en places nuevos. Valores por defecto: `StreamingMinRadius=64`, `StreamingTargetRadius=1024`. Recomendado: `StreamOutBehavior=Opportunistic`, `ModelStreamingBehavior=Improved`, `StreamingIntegrityMode=PauseOutsideLoadedArea`; usar `Persistent` con moderación; `WaitForChild` mínimo; solo los descendientes de Workspace hacen streaming.
- **Texturas**: una 1024² usa 4× la memoria de una 512². Mantener importantes ≈512 o menos y menores <256; materiales integrados consumen mucho menos que texturas propias; subir cada malla una sola vez para compartir draw call.
- Ejemplo de la doc (no norma): "stay below 1,000 draw calls and 1,000,000 triangles" en su dispositivo base.
- Código: limitar trabajo en `Heartbeat`/`PreRender`; repartir trabajo pesado entre frames; **pooling** de NPC/objetos respawneables; desconectar conexiones de `Player`/personaje; limpiar tablas en `PlayerRemoving`; efectos y tweens en **cliente**; enviar a red solo cambios; precargar solo lo esencial y mantener `ReplicatedStorage` ligero. Parallel Luau (`Actor`, `task.desynchronize`, `SharedTable`) solo para trabajo pesado independiente ([multithreading.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/multithreading.md)).
- Datos de bandera: `Workspace.EnableSLIMAvatars` y `LevelOfDetail=SLIM` (la doc los cita para escenas con muchos avatares; **[NO VERIFICADO] nombres exactos de propiedades**).

### 6.2 MemoryStore, MessagingService, Teleport
- **MemoryStore** [OFICIAL] ([index.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/memory-stores/index.md)): efímero. Estructuras: sorted map, queue, hash map. Máx. 1 000 000 ítems y 100 MB por estructura; cuota de memoria del juego `64 KB + 1.2 KB × usuarios`; unidades de petición (RU) `1 000 + 120 × CCU` por minuto; expiración por defecto y máxima 45 días (3 888 000 s). Casos: matchmaking, leaderboards, subastas, caché.
- **MessagingService / Open Cloud messaging** [OFICIAL] ([usage-messaging.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/usage-messaging.md)): mensaje ≤1 024 caracteres, tema ≤80; límites: envío por servidor `600 + 240 × players`/min; recepción por tema `40 + 80 × servers`/min; global `400 + 200 × servers`/min; suscripciones `20 + 8 × players`/servidor. `POST https://apis.roblox.com/cloud/v2/universes/{universe}:publishMessage` (scope `universe-messaging-service:publish`), solo llega a servidores en vivo.
- **Teleport** [OFICIAL] ([teleport.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/projects/teleport.md)): `TeleportService:TeleportAsync(placeId, players, options)` solo en servidor; `TeleportOptions` (`ShouldReserveServer`, `ReservedServerAccessCode`, `ServerInstanceId`, `SetTeleportData`); envolver en `pcall` con reintentos (5 con 1 s en el ejemplo); escuchar `TeleportInitFailed`; no se puede probar en Studio. El teletransporte descarta datos locales → guardar con DataStore/MemoryStore.

### 6.3 Eventos en vivo y configuración remota sin republicar
**La respuesta oficial es `ConfigService` (Configs)** [OFICIAL] ([production/configs.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/configs.md), [data-stores-vs-memory-stores.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/data-stores-vs-memory-stores.md)):
- Pares clave-valor (string, number, boolean, JSON). Hasta 1 000 configs activas; strings/JSON hasta 100 000 caracteres.
- Solo servidor: `ConfigService:GetConfigAsync()` (instantánea global), `ConfigService:GetConfigForPlayerAsync(player)` (condicionales/experimentos), `snapshot:GetValue(key)` (nil si no existe), `snapshot:Refresh()`, el evento `snapshot.UpdateAvailable` (avisa de que hay valores nuevos; entonces llamas a `Refresh()`), `snapshot:GetValueChangedSignal(key)`, `ConfigService:SetTestingValue(key, value)` / `ClearTestingValue()`. Las instantáneas **no se actualizan solas** (a propósito, para no cambiar reglas a mitad de partida). Si nunca cargó y falla, `GetConfigAsync()` lanza error → `pcall` + valores por defecto.
- Publicación: "Publish now" llega a los jugadores en ~15 s–1 min; "Publish over 15 min" es gradual. Edición desde Creator Hub o Studio (File > Open Configs). **Nota**: la doc de comparación todavía dice "~5 minutos"; la página de Configs dice 15 s–1 min → **[NO VERIFICADO] cuál es el actual**.
- Segmentación condicional por país, idioma, nuevo/recurrente, fuente de adquisición, pagador, plataforma, etc.; 100 condiciones por juego y 20 por clave.
- **Open Cloud Configs API** (para tu tooling de live-ops) [OFICIAL] ([cloud/guides/configs.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/configs.md)): base `https://apis.roblox.com/creator-configs-public-api/v1/configs/universes/{UNIVERSE_ID}/repositories/InExperienceConfig`; `PUT /draft:overwrite`, `PATCH /draft`, `POST /publish` (`deploymentStrategy`: `GradualRollout` ≈15 min o `Immediate`), `GET`, `GET /full`, `GET /revisions`, `POST /revisions/{id}/restore`; scopes `universe:read`/`universe:write`; **límite 100 claves por repositorio y 256 caracteres por clave** (contradice las 1 000 configs de la otra página → **[NO VERIFICADO]**).
- Para pocas lecturas globales usar Configs antes que MemoryStore; para datos que cambian dentro del juego, MemoryStore/DataStore (los configs son de solo lectura desde el juego).
- **Publicar una versión no expulsa jugadores**: los servidores viejos siguen vivos; "Restart Servers" (solo los desactualizados, con retraso de 1–60 min); evento `ServerRestartScheduled` (fuente `DeveloperUpdate` o `RobloxMaintenance`). Si cambias el formato de datos, reinicia. Para lanzamientos con hora fija: desplegar antes y activar con un flag de Configs [OFICIAL] ([update-games.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/projects/update-games.md)).

---

## 7. Analítica y live-ops

### 7.1 `AnalyticsService` (API actual) [OFICIAL] ([AnalyticsService.yaml](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/AnalyticsService.yaml))
Firmas leídas (todas con `player: Player` primero):
- `LogEconomyEvent(player, flowType: Enum.AnalyticsEconomyFlowType, currencyType: string, amount: number, endingBalance: number, transactionType: string, itemSku: string, customFields: Dictionary?)`. `amount` siempre positivo; `endingBalance` ≥ 0. Límites: **5 monedas, 20 tipos de transacción, 100 SKUs por experience**. `flowType`: `Source`/`Sink`; `transactionType` se pasa como string (p. ej. `Enum.AnalyticsEconomyTransactionType.IAP.Name`; también `TimedReward`, `Onboarding`, `Shop`, `Gameplay`, `ContextualPurchase`, o nombres propios) ([economy-events.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/economy-events.md)). La guía llama a `itemSKU` opcional pero la firma de la referencia lo lista sin valor por defecto → **[NO VERIFICADO]; pasar siempre un SKU**.
- `LogFunnelStepEvent(player, funnelName, funnelSessionId, step = 1, stepName, customFields?)` (recurrente; ≤10 funnels; pasos 1–100; `funnelSessionId` típicamente `HttpService:GenerateGUID()`) y `LogOnboardingFunnelStepEvent(player, step, stepName, customFields?)` (una vez por usuario) ([funnel-events.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/funnel-events.md)). Pasos repetidos en la misma sesión se ignoran; los saltados cuentan como completados.
- `LogCustomEvent(player, eventName, value = 1, customFields?)` (hasta 100 eventos custom por juego; usar campos para variaciones, no nombres distintos) ([custom-events.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/custom-events.md)).
- `LogProgressionEvent`/`LogProgressionStartEvent`/`...CompleteEvent`/`...FailEvent` (no aparecen en los gráficos de Roblox) y `LogJourneyEvent(player, journeyName, nodeName, journeySessionId, customFields?)` (diagrama Sankey).
- `GetPlayerSegmentsAsync(player)` (servidor; segmentos aproximados por jugador).
- **Custom fields**: solo las claves `Enum.AnalyticsCustomFieldKeys.CustomField01/02/03` (`.Name`), valores **string**, hasta 8 000 combinaciones únicas por experience ([custom-fields.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/custom-fields.md)).
- Los métodos `FireEvent`, `FireCustomEvent`, `FireInGameEconomyEvent`, `FireLogEvent`, `FirePlayerProgressionEvent` están **deprecados**.
- Solo se envían **desde el servidor y en juegos publicados** (no desde Studio ni cliente); los gráficos de Explore pueden tardar hasta 24 h; hay un límite global de frecuencia no numérico → agrupar con `value`.

Plan de eventos mínimo para todos los juegos (un módulo `Analytics` común):
- Onboarding funnel: unido → primer objetivo → primera compra de moneda soft → …
- Funnel de tienda recurrente: abrir tienda → ver producto → prompt → **compra confirmada (registrar dentro de `ProcessReceipt`, tras guardar)**.
- Economía: **cada** fuente y sumidero con `LogEconomyEvent`; compras de Robux como `IAP`.
- Custom events para hitos y para errores de compra (fallos de guardado, `NotProcessedYet`).

### 7.2 Métricas y paneles [OFICIAL]
- D1/D7/D30: porcentaje de **nuevos usuarios** que vuelven el día 1/7/30 tras su primera visita; los últimos días de los gráficos D7/D30 aparecen vacíos hasta que pasan 7/30 días; cohortes diarias (10 días) y semanales (10 semanas) ([retention.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/retention.md)). Monetización: ingresos por hora/día, tasa de conversión de pagadores, usuarios que pagan, ARPPU, ARPDAU ([monetization.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/monetization.md)).
- Paneles personalizados: hasta 20 por experience ([custom-dashboards.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/custom-dashboards.md)). Alertas: hasta 20 por experience, requieren ≥100 DAU, entrega **solo por webhook** (PagerDuty/Slack/Discord vía webhook) ([alerts.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/alerts.md)).
- **API de consulta de analítica (Open Cloud)**: `https://apis.roblox.com/analytics-query-api/v1/universes/{UniverseId}/metrics`, scope `universe.analytics:read` (sistema `universe-analytics`); métricas como `ForwardD1Retention`, `ForwardD7Retention`, `ForwardD30Retention`, `DailyActiveUsers`, `DailyRevenue`, `PayingUsers`, `PayingUsersCVR`, `AverageRevenuePerPayingUser`, `EconomyTransactionAmount`, `Funnel*`, `CustomEvent*`; retención de datos 1 468 días (rendimiento y DataStore 28 días); respuestas largas devuelven 202 y se sondea; error 429 si la consulta es demasiado grande ([analytics/index.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/analytics/index.md), [metrics.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/analytics/metrics.md)). Permite un **tablero multi-juego propio** (un script Lune que consulta cada universo).

### 7.3 Pruebas A/B: **sí existen** (Experiments) [OFICIAL] ([experiments.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/experiments.md), [cloud/guides/experiments.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/experiments.md))
- Experimentos **en la experiencia**: variantes de una **clave de Config**, control + hasta 2 variantes; duración 14–60 días; porcentaje de despliegue; segmentación como en Configs.
- Métricas siempre medidas: D1, D7, Playtime, ARPU, ARPPU, conversión de pagadores, session time. Alertas de "daño temprano" (Playtime −10%, ARPU −20%, conversión −20%) solo con ≥10 000 jugadores inscritos. Los juegos con <1 000 DAU pueden no alcanzar significancia; hay aviso de **SRM** (reparto inesperado).
- En código: usar **`GetConfigForPlayerAsync(player)`** y llamar a **`GetValue` solo cuando el jugador llega a la función** (si no, se inscribe a gente que no ve el contenido). `GetConfigAsync()` **no** aplica experimentos. Persistir la asignación si necesitas continuidad (la elegibilidad se evalúa por sesión).
- Open Cloud Experiments API (`/v1/experimentation/universes/{universeId}/experiments`, `:start`, `:schedule`, `:complete`, `/stats`; scopes `universe:read`/`universe:write`).
- *Price optimization* (precios) es otra cosa: exige ~60 000 transacciones/30 días.

---

## 8. Recursos para aprender

**Oficiales [OFICIAL]**
- Documentación del Creator Hub: https://create.roblox.com/docs (no abrí la web; su fuente completa está en [`Roblox/creator-docs`](https://github.com/Roblox/creator-docs), solo en inglés `en-us`).
- Tutoriales y currículos oficiales: carpetas `tutorials/curriculums` (animator, artist, building, coding, core, gameplay-scripting, studio, user-interface-design) y `tutorials/use-case-tutorials` (scripting básico/intermedio, data-storage, UI, etc.) ([árbol](https://github.com/Roblox/creator-docs/tree/main/content/en-us/tutorials)).
- Módulos y plantillas oficiales en `resources/` (Feature Packages, kits de armas/NPC, plantillas).
- Hoja de ruta y eventos: Creator Roadmap (create.roblox.com/roadmap), RDC (Roblox Developers Conference) ([get-started/resources.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/get-started/resources.md); la propia página no menciona comunidades).
- Seguridad y datos: guías oficiales citadas en las secciones 2 y 5.

**Comunidad en inglés [TERCERO]**
- DevForum de Roblox (devforum.roblox.com): foro oficial para desarrolladores; hilos de interés: ProfileStore, ProcessReceipt, Configs. No lo pude abrir; los enlaces de este informe salieron de búsquedas.
- Documentación de herramientas: ProfileStore (madstudioroblox.github.io/ProfileStore), Rojo, Wally, Jest Lua (jsdotlua.github.io/jest-lua), Fusion (elttob.uk/Fusion), Zap (zap.redblox.dev), Blink (1axen.github.io/blink), rbxcloud (sleitnick.github.io/rbxcloud), Lapis (nezuo.github.io/lapis). Los dominios `*.github.io` **estaban bloqueados**; sus fuentes están en los repos enlazados arriba.
- Blogs de terceros (de baja fiabilidad; verificar contra la doc oficial): [ProfileService vs DataStore2 (MattQ)](https://mattqdev.github.io/blog/profileservice-datastore-in-roblox-studio-2026-developer-guide), [guía de AnalyticsService](https://gamertagmythras.com/blog/roblox/roblox-analytics-service-guide), [guía de pases/dev products con IA](https://forgeblox.app/guides/roblox-game-pass-script-with-ai) (la propia búsqueda indicó que son guías no oficiales).

**YouTubers, Discords, libros y cursos**: **[NO VERIFICADO]**. Se agotó el cupo de `WebSearch` antes de buscarlos y no quiero inventar nombres. Pendiente de una búsqueda posterior: canales en español de Roblox/Luau, servidores de Discord comunitarios (p. ej. los de la comunidad de desarrolladores de Roblox), libros y cursos de pago. Mientras tanto, la combinación más segura es: tutoriales oficiales + DevForum + documentación de las herramientas.

---

## 9. Dudas abiertas (verificar antes de generar código)

1. **`ProcessReceipt` vs `BindReceiptHandler`** para dev products: la doc ofrece ambos; ¿conviene usar solo `ProcessReceipt` y `BindReceiptHandler` únicamente para Robux Transfers? (Los enums de retorno son distintos.)
2. **`itemSku` en `LogEconomyEvent`**: ¿obligatorio u opcional? Pasar siempre un valor.
3. **String requires y `const`** en el runtime de Roblox para juegos en producción.
4. **Discrepancias en Configs**: 1 000 configs activas (guía) vs 100 claves por repositorio (API Open Cloud); 15 s–1 min vs ~5 min de despliegue.
5. **Luau Execution API**: límites reales (5/min documentado vs ~30/hora reportado) y nombre exacto del scope; `versionType=Saved` en Place Publishing.
6. **ID correcto de pase** para `PromptGamePassPurchase` (`TargetId` vs asset ID) y comportamiento real de `PromptGamePassPurchaseFinished` frente a spoofing.
7. **Fechas/regiones de Paid Random Items**: solo hay fuente de terceros; leer el anuncio de DevForum.
8. **Cómo probar suscripciones en Studio** y cómo se comporta `UserSubscriptionStatusChanged` en pruebas.
9. **Regalos**: no hay API oficial; el diseño propio necesita revisión de reglas de la plataforma.
10. **Wally** (última versión estable 2023) y **pesde** (cambios importantes sin lanzar): revisar antes de comprometerse; Lapis "no probado en producción grande".
11. **Fusion**: versión vigente y API; **DataStore2**: README no leído.
12. **Flags exactos de `luau-lsp analyze`** y acción de Actions para Rokit.
13. **Recursos en español**: pendientes de búsqueda.
14. **Estado de "Script Sync" y del MCP integrado** (la doc solo marca Script Sync como beta).

---

## 10. Fuentes principales (todas consultadas el 2026-10-20)

**[OFICIAL] (repo `Roblox/creator-docs`, rama `main`)**
- Referencia de clases: [MarketplaceService](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/MarketplaceService.yaml), [PolicyService](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/PolicyService.yaml), [AnalyticsService](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/AnalyticsService.yaml), [Players](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/Players.yaml).
- Monetización: [developer-products](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/developer-products.md), [passes](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/passes.md), [subscriptions](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/subscriptions.md), [paid-random-items](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/paid-random-items.md), [managed-pricing](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/managed-pricing.md), [regional-pricing](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/regional-pricing.md), [price-optimization](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/price-optimization.md), [robux-transfers](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/robux-transfers.md), [creator-rewards](https://github.com/Roblox/creator-docs/blob/main/content/en-us/creator-rewards.md).
- Datos: [data-stores/index](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/data-stores/index.md), [player-data-purchasing](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/data-stores/player-data-purchasing.md), [best-practices](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/data-stores/best-practices.md), [error-codes-and-limits](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/data-stores/error-codes-and-limits.md), [versioning-listing-and-caching](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/data-stores/versioning-listing-and-caching.md), [right-to-be-forgotten](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/data-stores/right-to-be-forgotten.md), [memory-stores](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/memory-stores/index.md), [cross-server-messaging](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/cross-server-messaging.md), [http-service](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/http-service.md), [secrets](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/secrets.md).
- Open Cloud: [api-keys](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/auth/api-keys.md), [rate-limits](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/reference/rate-limits.md), [usage-place-publishing](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/usage-place-publishing.md), [usage-messaging](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/usage-messaging.md), [configs](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/configs.md), [experiments](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/experiments.md), [instance](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/instance.md), [analytics query](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/analytics/index.md), [webhooks](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/webhooks/webhook-notifications.md).
- Producción/analítica: [configs](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/configs.md), [experiments](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/experiments.md), [economy-events](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/economy-events.md), [funnel-events](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/funnel-events.md), [custom-events](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/custom-events.md), [custom-fields](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/custom-fields.md), [retention](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/retention.md), [monetization](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/monetization.md), [custom-dashboards](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/custom-dashboards.md), [alerts](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/analytics/alerts.md).
- Scripting/seguridad/rendimiento/proyectos: [security/*](https://github.com/Roblox/creator-docs/tree/main/content/en-us/scripting/security), [remote](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/events/remote.md), [module](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/module.md), [multithreading](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/multithreading.md), [type-checking](https://github.com/Roblox/creator-docs/blob/main/content/en-us/luau/type-checking.md), [performance-optimization/*](https://github.com/Roblox/creator-docs/tree/main/content/en-us/performance-optimization), [streaming](https://github.com/Roblox/creator-docs/blob/main/content/en-us/workspace/streaming/index.md), [teleport](https://github.com/Roblox/creator-docs/blob/main/content/en-us/projects/teleport.md), [update-games](https://github.com/Roblox/creator-docs/blob/main/content/en-us/projects/update-games.md), [external-tools](https://github.com/Roblox/creator-docs/blob/main/content/en-us/projects/external-tools.md), [server-authority](https://github.com/Roblox/creator-docs/blob/main/content/en-us/projects/server-authority/index.md), [coding-harness](https://github.com/Roblox/creator-docs/blob/main/content/en-us/ai/coding-harness.md), [assistant/mcp](https://github.com/Roblox/creator-docs/blob/main/content/en-us/assistant/mcp.md), [bans (dashboard)](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/bans.md).
- OpenAPI: [developer-products v1](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/cloud/developer-products-api/v1.json), [game-passes v1](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/cloud/game-passes-http-service/v1.json), [open-eval v1](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/cloud/open-eval-api/v1.json).

**[TERCERO]**
- Repos: [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore), [Lapis](https://github.com/nezuo/lapis), [Rojo](https://github.com/rojo-rbx/rojo), [Rokit](https://github.com/rojo-rbx/rokit), [Wally](https://github.com/UpliftGames/wally), [pesde](https://github.com/pesde-pkg/pesde), [StyLua](https://github.com/JohnnyMorganz/StyLua), [Selene](https://github.com/Kampfkarren/selene), [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp), [Lune](https://github.com/lune-org/lune), [Jest Lua](https://github.com/jsdotlua/jest-lua), [TestEZ](https://github.com/Roblox/testez), [Knit](https://github.com/Sleitnick/Knit), [React Lua](https://github.com/jsdotlua/react-lua), [Fusion](https://github.com/Elttob/Fusion), [Matter](https://github.com/matter-ecs/matter), [roblox-ts](https://github.com/roblox-ts/roblox-ts), [Zap](https://github.com/red-blox/zap), [Blink](https://github.com/1Axen/blink), [rbxcloud](https://github.com/Sleitnick/rbxcloud), [studio-rust-mcp-server](https://github.com/Roblox/studio-rust-mcp-server), [Krultu/rbx-publish](https://github.com/Krultu/rbx-publish) (su README remite a otra acción, `filiptibell/roblox-place-publish-action@v2.1`; **verificar cuál usar**).
- Hilos/blogs (solo vistos como resultados de búsqueda): ver enlaces inline en las secciones 1, 2, 4 y 8.
