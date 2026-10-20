# Pases, productos, pruebas sin Robux y experiencia privada (investigación)

Fecha: 2026-10-20. Hecha por la sesión de la nube (sin acceso a create.roblox.com ni a ninguna credencial de Roblox).
Lo que se leyó: el repositorio público `Roblox/creator-docs` (rama `main`, el origen de create.roblox.com/docs; GitHub sí es accesible desde la nube) y las especificaciones OpenAPI que viven en él.

Etiquetas: **[OFICIAL leído]** = lo leí yo mismo en `Roblox/creator-docs` (ruta indicada) · **[DEL PC]** = lo verificó la sesión del PC (ver los otros informes de esta carpeta) · **[LOCAL]** = lo comprobé ejecutando la herramienta instalada en este repo · **[TERCERO]** = resumen de un buscador o foro (no abrí la página) · **[NO VERIFICADO]** = deducción mía o sin fuente.
Antes de gastar dinero o tocar algo público, repite en Creator Hub (que sí abre desde el PC) lo que aquí diga [NO VERIFICADO].

---

## 0. Resumen

1. **Crear pases y productos es gratis y se puede hacer por la web o por API.** La web exige que la experiencia ya esté publicada ("accesible en Roblox"). Existe una API Open Cloud **BETA** para crearlos, leerlos y editarlos (no hay endpoint para borrarlos). Esta sesión dejó listo `ROBLOX/tools/create-items.mjs` (probado con un servidor falso, nunca contra Roblox).
2. **No se encontró ningún requisito de pago, de identidad ni de Plus para CREAR o poner en venta un pase/producto** en las dos páginas oficiales (`passes.md`, `developer-products.md`). Los requisitos fuertes aparecen al **hacer pública** la experiencia (sección 6).
3. **Probar compras sin gastar Robux: la documentación oficial actual no describe compras simuladas en Studio.** Un aviso antiguo del DevForum dice que son gratis [TERCERO]; un reporte de 2026 dice lo contrario [TERCERO]. Regla de este proyecto: **nunca confirmar una compra en un diálogo de Roblox**; se verifica el cableado con el código (Lune), con consultas de solo lectura (`GetProductInfoAsync`) y abriendo el diálogo para **cancelarlo**.
4. **TargetId o assetId:** la documentación se contradice (sección 4). El código ahora soporta los dos casos con un campo explícito (`passAssetIds`) y la prueba de Studio decide cuál ID es cuál. Si el diálogo solo funciona con un ID distinto del que dice la documentación, hay que parar y reportar.
5. **La experiencia de prueba privada** se crea con *File > Publish* de Studio (primera vez, ventana "Game details"); por defecto queda **solo para el creador y quienes tengan acceso de edición**. **No existe API para crear experiencias.** Hacerla pública es un paso distinto (ventana de madurez o *Manage Audience*) que **nunca** debe hacer la sesión del PC.

---

## 1. (a) Cómo se crean pases y productos

### 1.1 Por la interfaz de Creator Hub [OFICIAL leído]

Fuentes: `content/en-us/production/monetization/passes.md` y `developer-products.md` (rama `main`, leídas el 2026-10-20).

**Requisito previo (las dos páginas, en una alerta):** "Before creating a pass, make sure your game has been published and is accessible on Roblox." Si "accesible" incluye una experiencia privada es **[NO VERIFICADO]** (la doc no lo aclara); si Creator Hub no deja crear mientras sea privada, **parar y reportar: no se hace pública para poder crearlos**.

**Pase:**
1. [Creations](https://create.roblox.com/dashboard/creations) → elegir la experiencia.
2. **Monetization → Passes**.
3. **Create pass**.
4. Subir el ícono (máx. 512×512, `.jpg`, `.png` o `.bmp`; se recorta en círculo).
5. Nombre y descripción.
6. Elegir una **categoría** (organiza la tienda dentro del juego).
7. **Create pass**.
8. El precio y "a la venta" se configuran después en la ficha del pase [NO VERIFICADO el orden exacto de la pantalla; la doc no lo detalla].

**Producto de desarrollador:** Monetization → **Developer Products** → **Create developer product** → ícono (mismas reglas) → nombre y descripción → categoría → **precio en Robux (mínimo 1, máximo 1.000 millones)** → **Save Changes**.

**Copiar el ID** (ambas páginas): Monetization → Passes (o Developer Products) → pasar el ratón sobre la miniatura → botón **⋯** → **Copy Asset ID**. (El menú dice "Asset ID" también para productos, cuyo ID es el `ProductId`; ver la sección 4 para pases.)

**"Listed" (¡cuidado!):** los pases y productos que estén **Listed** (Monetization → **Shop**) salen **fuera del juego**: página de inicio de Roblox, búsquedas y la página posterior a comprar Robux. Los no listados "nunca aparecen en la Shop ni fuera de tu juego". Mientras la experiencia sea de prueba, **no marcar nada como Listed**. Un producto Listed además exige que `ProcessReceipt` esté bien implementado (Roblox lo vigila).

### 1.2 Por API: Open Cloud [OFICIAL leído, ambas BETA]

Fuentes: `content/en-us/reference/cloud/game-passes-http-service/v1.json` y `developer-products-api/v1.json` (OpenAPI). Servidor: `https://apis.roblox.com`.

| Acción | Endpoint | Scope de la clave | Límite |
|---|---|---|---|
| Crear pase | `POST /game-passes/v1/universes/{universeId}/game-passes` | `game-pass:write` | 5/s por dueño de clave |
| Listar pases | `GET /game-passes/v1/universes/{universeId}/game-passes/creator` (`pageSize`, `pageToken`) | `game-pass:read` | 10/s |
| Leer un pase | `GET .../game-passes/{gamePassId}/creator` | `game-pass:read` | 10/s |
| Editar un pase | `PATCH .../game-passes/{gamePassId}` | `game-pass:write` | |
| Crear producto | `POST /developer-products/v2/universes/{universeId}/developer-products` | `developer-product:write` | 3/s |
| Listar productos | `GET .../developer-products/creator` | `developer-product:read` | 10/s |
| Leer / editar producto | `GET .../{productId}/creator` · `PATCH .../{productId}` | `:read` / `:write` | |

- **Cuerpo de la creación** (`multipart/form-data`): `name` (obligatorio), `description`, `imageFile` (binario), `isForSale` (booleano), `price` (entero, Robux), `isRegionalPricingEnabled` (booleano).
- **Respuesta 200:** pase → `gamePassId`, `name`, `description`, `isForSale`, `iconAssetId`, `priceInformation`, fechas. Producto → `productId`, `iconImageAssetId`, `universeId`, `isForSale`, `storePageEnabled`, `isImmutable`, `priceInformation`, fechas.
- Errores: JSON `{ errorCode, errorMessage, field, hint }`. Códigos útiles: pases `PassNotFound`, `UniverseNotFound`, `NotForSale`, `PricingConfigError`; productos `DuplicateProductName`, `InvalidPriceInRobux`, `PendingProductsLimitExceeded`, `InvalidName`.
- `x-roblox-engine-usability: apiKeyWithHttpService = false`: **no** se pueden llamar desde `HttpService` dentro del juego (y no se debe).
- **No hay endpoint de borrado** de pases ni productos en estas especificaciones; borrar es manual en Creator Hub. Tampoco hay un endpoint para marcar "Listed".
- Creación de claves: Creator Dashboard → **API Keys** → *Create API Key* → elegir **cada API** (Game Passes, Developer Products…), operaciones y la experiencia concreta; caducan solas a los 60 días sin uso [OFICIAL leído, `cloud/auth/api-keys.md`].
- Herramienta del repo: `node ROBLOX/tools/create-items.mjs --universe <ID>` (plan) y `--apply` (crea), idempotente, **fuera de venta** por defecto, clave solo por la variable `ROBLOX_API_KEY`. Está probada contra un servidor falso con las mismas rutas y campos de la especificación. **No se ha ejecutado contra Roblox [NO VERIFICADO]**: si la API se comporta distinto (campos, límites, moderación del ícono), se puede crear a mano por la web; el resultado final (ids.local.json) es el mismo.

---

## 2. (b) Costes y requisitos para crearlos y venderlos

- **Crear:** ninguna de las dos páginas oficiales menciona precio, tarifa, ID verificado, Premium ni Plus para crear un pase o producto [OFICIAL leído: ausencia en `passes.md`, `developer-products.md`, `monetization/index.md`]. Sí piden que la experiencia esté publicada.
- **Vender dentro del juego:** `PromptGamePassPurchase` / `PromptProductPurchase` desde el servidor; para productos, `ProcessReceipt` obligatorio y Roblox no guarda el historial de compras (hay que guardarlo; el juego ya lo hace) [OFICIAL leído].
- **Vender fuera del juego:** marcar **Listed** (Shop). Productos: `ProcessReceipt` correcto. Pases: sin requisito extra [OFICIAL leído].
- **Quién puede comprar:** mientras la experiencia sea privada, solo quien tenga acceso a ella. Las compras son con **Robux reales** de la cuenta que compra [obvio, pero no citado en la doc leída; ver sección 3 sobre Studio].
- **Reparto y cobro (informativo):** el 30 % de comisión de la plataforma y la tarifa DevEx están en `research/02`; no se re-leyó aquí.
- **Publicar la experiencia (no crear objetos)** sí tiene requisitos: sección 6.
- **Moderación:** los íconos y nombres pasan moderación. El ícono de cada objeto está en `ROBLOX/marketing/fish-and-fortune/assets/{passes,products}/` (512×512, hechos por código) [NO VERIFICADO que Roblox los apruebe].
- **Precios regionales / Managed pricing:** los objetos nuevos pueden quedar inscritos por defecto [TERCERO: nota de la skill local]; revisar en Creator Hub si se quiere un precio fijo.

---

## 3. (c) Probar compras SIN gastar Robux

### 3.1 Lo que dice la documentación

- Ni `passes.md`, ni `developer-products.md`, ni `MarketplaceService.yaml` (rama `main`) describen compras de prueba ni simuladas en Studio [OFICIAL leído: ausencia; búsqueda de "test", "Studio" y "charged"]. Ese vacío es el dato.
- Búsqueda web (2026-10-20, resumen del buscador, **no pude abrir DevForum**): "Mock purchases in Studio" (hilo 26974, antiguo) dice que las compras hechas en Studio no se cobran y se simulan; otro hilo de 2026, "Roblox playtest gamepass subtracted real Robux" (4753185), reporta que una compra de pase durante un playtest **sí descontó Robux reales** [TERCERO]. Dos reportes contradictorios → **se asume que una compra confirmada puede costar Robux reales.**

### 3.2 Regla y cómo se verifica entonces (de menos a más riesgo)

1. **Sin Studio, sin Robux (ya hecho en la nube):** `FF_RELEASE_CHECK=1 bash ROBLOX/tools/test.sh` ejecuta el servidor REAL (`GameService`) con los IDs REALES de `ProductIds.luau` y comprueba (`tests/support/IdWiringChecks.luau`): cada clave abre su prompt con su ID; un recibo con el ID de cada producto lo concede **una sola vez** y solo en lo que dice su catálogo; el ID de cada pase activa solo ese pase; los alias funcionan. Esto responde "¿`ProcessReceipt` funciona con los IDs reales?" para la lógica del juego. **No prueba que el ID exista en Roblox.**
2. **Solo lectura en Studio (gratis):** `node ROBLOX/tools/wire-ids.mjs --emit-verify-luau` imprime un script para `execute_luau` que llama `GetProductInfoAsync` de cada ID y compara nombre, precio, "a la venta" y `TargetId`/`ProductId`. No compra ni escribe. [OFICIAL leído: `GetProductInfoAsync` devuelve `Name`, `PriceInRobux`, `IsForSale`, `TargetId`… y "si el ID no existe, lanza un error"]. Que funcione dentro de `execute_luau` (contexto de plugin) es **[NO VERIFICADO]**.
3. **Abrir el diálogo y CANCELAR (gratis si se cancela):** durante el playtest, la tienda del juego pide `PromptGamePassPurchase`/`PromptProductPurchase`; el diálogo oficial muestra el nombre y el precio; se pulsa **Cancelar** (o se cierra). Esto prueba que Roblox acepta ese ID en ese método. `PromptGamePassPurchaseFinished` se dispara con `wasPurchased=false` y, si el ID que informa no es el cableado, el juego deja en la salida `PromptGamePassPurchaseFinished con un ID de pase DESCONOCIDO`. **Riesgo:** un clic equivocado confirma la compra. Mitigaciones obligatorias: cuenta de prueba sin Robux (o saldo 0), o que Aryan lo haga con su mano; la sesión del PC **nunca** pulsa el botón de confirmar.
4. **Compra real mínima (SOLO con OK explícito de Aryan en ese momento):** el producto más barato es `coin_boost_15` (49 R$). La comprueba de punta a punta (diálogo → `ProcessReceipt` → guardado → concesión, y la re-entrega) y es la única que prueba el recibo real. Cuesta Robux reales de la cuenta que compra. Detalle en la guía, Etapa 3b.

### 3.3 Verificar `ProcessReceipt` con los IDs reales

- Lógica: punto 1 (Lune). Para hacerlo desde Studio sin comprar haría falta un gancho "solo Studio" que inyecte un recibo sintético en el `ProcessReceipt` del juego; **no se implementó**: añade una vía en el código de dinero (aunque limitada a `RunService:IsStudio()`) y no aporta lo que el punto 1 no cubra (los IDs son solo claves de tabla). Si Aryan lo quiere, es un cambio pequeño y aislado.
- `ProcessReceipt` **no está deprecado** (la doc lo llama "legacy"; existe `BindReceiptHandler`): ver `verificacion-monetizacion.md`. No se migra en esta misión.
- Un producto que se deje **Listed** con un recibo fallido sale de las superficies externas (ver 1.1): otro motivo para no listar nada en pruebas.

---

## 4. (d) TargetId o assetId en `PromptGamePassPurchase`

### 4.1 Lo que dice cada página oficial [OFICIAL leído]

| Página | Texto relevante | ID que implica |
|---|---|---|
| `production/monetization/passes.md`, "Get the pass ID" | "hover over a pass' thumbnail, click ⋯ and select **Copy Asset ID**". Los ejemplos usan ese número en `GetProductInfo(id, Enum.InfoType.GamePass)`, `UserOwnsGamePassAsync(userId, passID)`, `PromptGamePassPurchase(player, passID)` y en `PromptGamePassPurchaseFinished` | el que da "Copy Asset ID" |
| `reference/engine/classes/MarketplaceService.yaml`, `PromptGamePassPurchase` | "The pass ID to purchase. This is the `TargetId` returned by `GetProductInfo()` when `InfoType` is `GamePass`. **It is not the pass's asset ID and not its `ProductId`.**" | `TargetId` |
| ídem, `UserOwnsGamePassAsync` | "the pass with the given `gamePassId` (**not to be confused with an asset ID**)" | `gamePassId` |
| ídem, `PromptGamePassPurchaseFinished` | "The ID number of the pass shown in the prompt. Not to be confused with an asset ID." | ID del pase |
| ídem, `PlayerOwnsAssetAsync` | no usarlo para pases porque "use a separate ID system. **Legacy** passes that still depend on an asset ID should use `UserOwnsGamePassAsync`" | pases nuevos ≠ assetId; los antiguos sí dependen del assetId |
| ídem, `GetProductInfoAsync` | el parámetro se llama `assetId`; la tabla devuelta incluye `TargetId`: "The ID of the product or asset" | — |
| API Open Cloud de pases (`game-passes-http-service/v1.json`) | crea un pase y devuelve `gamePassId` ("The game pass ID") **y** `iconAssetId` por separado | `gamePassId` ≠ ícono |

### 4.2 Interpretación [NO VERIFICADO]

Lo más probable: la opción de menú **"Copy Asset ID"** de la pestaña Passes copia el **ID del pase** (el mismo `gamePassId` de la API y el `TargetId` de `GetProductInfoAsync`), y la etiqueta "Asset" es un resto histórico (los pases antiguos eran assets). Entonces `passes.md` y `MarketplaceService.yaml` coinciden y no hace falta cambiar nada. Pero **no hay ninguna prueba**; si las dos páginas dijeran cosas distintas de verdad, el diálogo fallaría para todos los desarrolladores, lo que hace improbable el caso malo. Por eso se mide.

### 4.3 La prueba concreta en Studio (con un pase real, sin gastar nada)

Para CADA pase creado (o al menos para dos de ellos, el primero y el último):

1. Anotar el número **A** que da *Copy Asset ID* (menú ⋯ del pase) y, si hay clave de API, el `gamePassId` **G** que devuelve `GET /game-passes/v1/universes/{U}/game-passes/creator` (`create-items.mjs` lo guarda solo).
2. En Studio (`execute_luau`, datamodel Edit): `MarketplaceService:GetProductInfoAsync(A, Enum.InfoType.GamePass)` y leer **`TargetId` = T**, `Name`, `PriceInRobux`, `IsForSale`. (El script de `wire-ids.mjs --emit-verify-luau` lo hace para todos y marca `TargetId DISTINTO`.)
3. **Decisión:** el `passId` del juego = **T** (lo que dice la referencia de `PromptGamePassPurchase`). Si T = A para todos → **Caso A**.
4. Abrir el diálogo desde el juego (playtest, botón de la tienda) con ese `passId` y **cancelar**: debe mostrar el nombre y precio correctos. Mirar la salida: no debe aparecer `PromptGamePassPurchaseFinished con un ID de pase DESCONOCIDO`.

### 4.4 Qué cambio de código hace falta en cada caso

| Caso | Observación | Cambio | Estado |
|---|---|---|---|
| **A** | T = A = G para todos y el diálogo muestra el pase correcto | Ninguno. `ids.local.json` con un número por pase | Es el caso esperado |
| **B** | T ≠ A pero el diálogo funciona con T | En `ids.local.json`: `"vip": { "passId": T, "assetId": A }`. `wire-ids.mjs` escribe `passes.vip = T` y `passAssetIds.vip = A` | **Implementado** y probado (`tests/PassIds.spec.luau`, `wire-ids.test.mjs`): el juego usa T para el diálogo y la propiedad, y acepta A como alias del evento `PromptGamePassPurchaseFinished` y como respaldo para mostrar el precio |
| **C** | El evento `Finished` informa un ID distinto del que se pasó al diálogo | Mismo mecanismo que B (alias) | Cubierto por el alias; el registro `ID DESCONOCIDO` avisa si falta |
| **D** | El diálogo **solo** funciona con A (contradice dos páginas oficiales) | **PARAR y reportar.** Cambio previsto: un campo `promptId` por pase usado solo por `Shop.promptPass` (≈15 líneas + 4 pruebas) | **No implementado a ciegas**: toca dinero y contradice la referencia |

`REVIEW(money)` está marcado en `ProductIds.luau`, `Catalog.luau` y `Shop.luau` (alias): el alias **nunca** se usa para vender ni conceder, solo para reconocer eventos y mostrar precios; `Shop.new` se niega a arrancar si un alias coincide con el ID de otro pase o de otro alias. Es reversible: dejar `passAssetIds = {}`.

---

## 5. (e) Experiencia de PRUEBA privada y publicar el lugar con Rojo

### 5.1 Crear la experiencia privada [OFICIAL leído, `production/publishing/publish-games-and-places.md`]

- **No existe API de Open Cloud para crear experiencias** (revisadas las 833 rutas de `reference/cloud/openapi.json`; solo hay actualización de universo/lugar, no creación) [OFICIAL leído]. Se crea desde Studio.
- **Ojo, endpoints que HACEN PÚBLICA una experiencia:** `POST /legacy-develop/v1/universes/{universeId}/activate` y `POST /v1/universes/{universeId}/activate` (EXPERIMENTAL, heredados) y `PATCH /cloud/v2/universes/{universe_id}` con `universe:write` (STABLE; el campo `visibility` figura como solo lectura en el esquema). **Ninguna herramienta del repo los llama y la clave de la misión no lleva `universe:write` ni `legacy-universe:manage`.** [OFICIAL leído en `openapi.json`]
- Primera publicación: en Studio **File → Publish** abre la ventana **Game details** (ícono y miniatura, **Name**, **Genre**, **Description**) → **Save**. "Roblox publishes your game to the cloud with a unique `UniverseID`." "By default, new games are only accessible to you as the creator, users with **Edit** access, and group members with the appropriate roles."
- Hacerla pública es **otra** acción: *File → Publish* otra vez (ventana con **Invite** / **Continue** y la primera pregunta del cuestionario de madurez → **Publish**) o *Creator Hub → Publish settings → Manage Audience → Public*. **La sesión del PC no puede abrir ni completar ninguno de los dos.**
- "Invite early testers" (hasta 10 amigos de edad parecida) permite probar **antes** de publicar y de tener etiqueta de madurez, pero es una acción que invita a otras personas: Etapa 4 opcional.
- Si la interfaz difiere de esta descripción: **parar y reportar**.
- Nombre sugerido para la de prueba: algo que no se confunda con el juego final, p. ej. `FF Pruebas (privado)`; el nombre final y la descripción del juego definitivo se ajustan al lanzar.

### 5.2 IDs que se necesitan

- **Universe ID:** Creations → ⋯ de la miniatura → **Copy Universe ID**. En Studio, con la experiencia abierta, `game.GameId` también lo da [NO VERIFICADO desde `execute_luau`].
- **Place ID:** Creations → la experiencia → pestaña **Places** → el lugar; está en la URL `.../experiences/{universe}/places/{place}/configure` [OFICIAL leído, `usage-place-publishing.md`]. `game.PlaceId` en Studio.

### 5.3 Publicar el lugar construido con Rojo

Dos vías, ambas hacia la experiencia **privada**:

- **Sin API (recomendada para empezar):** Rojo + Studio. `rojo serve ROBLOX/games/fish-and-fortune/default.project.json` y conectar el plugin; Studio ve los scripts en vivo. Para guardar en la nube: *File → Save to Roblox* o *Publish* de Studio sobre la experiencia ya privada **solo si no se abre la ventana de madurez**; ante la duda, usar la vía API. Los cambios de Rojo quedan en el lugar abierto en Studio. [NO VERIFICADO el nombre exacto del comando de guardado en esta versión de Studio.]
- **Con API (Open Cloud Place Publishing, BETA):** `POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Saved|Published`, cabeceras `x-api-key` y `Content-Type: application/octet-stream` (`.rbxl`) o `application/xml` (`.rbxlx`); respuesta `{ "versionNumber": N }`. Scope: **`universe-places:write`** sobre esa experiencia [OFICIAL leído]. Límite 10 peticiones/min por IP [TERCERO, flujo.md]. Limitación: no actualiza `EditableImage`, `EditableMesh`, `PartOperation`, `SurfaceAppearance` ni `BaseWrap` (publicar entonces desde Studio) [OFICIAL leído].
  - **`rojo upload` existe en 7.7.1 [LOCAL: `rojo upload --help`]**: `rojo upload [PROJECT] --api_key <API_KEY> --universe_id <U> --asset_id <PLACE_ID>`. **La clave solo se acepta como argumento** (no hay variable de entorno en la ayuda): quedaría en la línea de comandos y el historial. Por eso el repo trae `node ROBLOX/tools/publish-place.mjs`, que construye con `rojo build` y sube leyendo `ROBLOX_API_KEY`, y **se niega a subir si `GET /cloud/v2/universes/{id}` no dice `visibility = PRIVATE`** (falla cerrado). Sube versión *Saved* por defecto (no cambia lo que ve nadie); `--publish` sube *Published*.
  - `GET /cloud/v2/universes/{universe_id}` es **STABLE**; devuelve `visibility` (`PUBLIC` / `PRIVATE`), `rootPlace`, `ageRating` [OFICIAL leído en `openapi.json`]. Qué permiso exige la clave para ese GET es **[NO VERIFICADO]** (la especificación lista `scopes: []`); si da 403, añadir el permiso de lectura de la experiencia.

### 5.4 La clave de Open Cloud: permisos mínimos y dónde guardarla

- Creator Dashboard → **API Keys** → *Create API Key* [OFICIAL leído, `cloud/auth/api-keys.md`]. Una sola clave puede llevar varias APIs. Para esta misión, **limitada a la experiencia de prueba**:
  - **Game Passes**: Read + Write → `game-pass:read`, `game-pass:write`
  - **Developer Products**: Read + Write → `developer-product:read`, `developer-product:write`
  - **Place Publishing (`universe-places`)**: Write → `universe-places:write`
  - opcional, para la comprobación de privacidad: lectura de la experiencia (**universe** Read).
  - Caducidad: poner fecha (p. ej. 7 días). Sin uso durante 60 días se desactiva sola. Restricción por IP: opcional (CIDR).
- **Dónde guardarla (Windows):** variable de entorno de **usuario** `ROBLOX_API_KEY` (Panel de control → "Editar las variables de entorno de esta cuenta" → Nueva), y **abrir una terminal nueva**. **Nunca** en un archivo del repo, en `ids.local.json`, en un comando pegado en el chat ni en un mensaje. Las herramientas del repo no la aceptan por argumento y no la imprimen. Tras la misión: **borrar la clave en Creator Hub** (revocar) y la variable.
- Quien crea la clave es **Aryan** (es su cuenta); la sesión del PC solo guía.
- **Desde la nube** (guía `dar-acceso-a-claude.md`): en vez de una variable de entorno, un *secreto de red* con la cabecera `x-api-key` que añade el proxy; las herramientas lo admiten con `ROBLOX_API_KEY_VIA_PROXY=1` (no envían ninguna clave). [NO VERIFICADO el comportamiento del proxy.]

---

## 6. (f) Qué cambia al hacerlo público

Todo [OFICIAL leído] en `publish-games-and-places.md`, `kids-and-select.md` y `content-maturity.md` salvo indicación. Resumen para decidir (la lista de verificación está en la guía, Etapa 5):

- **Los requisitos se aplican en CADA acción de publicación**, no solo al primer lanzamiento: primera publicación, **actualizar un juego ya publicado**, "Publish As" a otro juego y cambiar la audiencia. Es decir: cada actualización futura vuelve a pasar por esto.
- **Para 16+ (lo mínimo):** cuenta en buen estado y de **al menos 2 días**; control de edad (estimación facial o documento); responder la **primera pregunta** del cuestionario. Respuesta "No" (sin contenido restringido) → etiqueta **Content May Vary**: el juego solo lo ven usuarios de 16+ con edad comprobada.
- **Para todas las edades (Kids 5-8 y Select 9-15):** lo anterior **más** verificación (estimación facial si es menor de 18; **documento** si tiene 18 o más), **2FA**, y **una** de: Roblox Plus/Premium activo **2 meses seguidos**, o **tarifa única reembolsable de 1.000 Robux por juego**; **cuestionario completo** con resultado Minimal/Mild/Moderate; y superar la **evaluación** (250 jugadas únicas de jugadores muy comprometidos en 60 días).
- **Reembolso de la tarifa:** `kids-and-select.md` dice "automáticamente 90 días después de que el juego sea elegible (o 90 días después de pagar si nunca lo es)"; `publish-games-and-places.md` dice "25 jugadores muy comprometidos durante 60 días sin moderación". **Las dos páginas se contradicen** → no contar con el reembolso. No se reembolsa si el juego se retira permanentemente por infracciones graves.
- **Cuestionario de madurez:** debe ser **veraz** ("base your answers on the most mature or extreme content players can encounter"); información inexacta expone el juego **y la cuenta** a moderación. Para Fish & Fortune v1: sin violencia, sin apuestas jugables, sin chat propio, sin IA, **sin objetos aleatorios de pago** (suerte de pago apagada; lanzar la caña no cuesta Robux ni monedas), sin comercio. Aryan debe responder cada pregunta leyéndola; si la respuesta correcta cambia algo del juego, **se reenvía el cuestionario**.
- **Dinero:** los pases/productos pasan a venderse a todo el público permitido; `PolicyService` y la tienda honesta (research/03) aplican. DevEx: mínimo 30.000 Robux ganados; **la información fiscal debe estar antes del 31-oct-2026** (independiente de publicar, pero urgente). Aryan vive en EE. UU., 18+, como persona: le toca el **W-9**, no el W-8BEN (`preguntas-para-aryan.md`, 2026-10-20) — ver `verificacion-monetizacion.md` §4.
- **Tope:** hasta **5 juegos nuevos por día**; revocar el acceso público y volver a publicar no cuenta.
- **Fuera del juego:** pases y productos solo aparecen en la Shop de Roblox si están **Listed** (decisión aparte de Aryan).
- **Lo que SOLO puede hacer Aryan:** pagar la tarifa o decidir Plus/Premium; verificar identidad/edad; 2FA; W-9/Impuestos; crear la clave de API; responder el cuestionario; pulsar "Publicar"/"Public".

---

## 7. Fuentes leídas (2026-10-20)

`raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/` + `production/monetization/{passes,developer-products,index}.md`, `production/publishing/{publish-games-and-places,kids-and-select}.md`, `production/promotion/content-maturity.md`, `projects/{configure-games,update-games}.md`, `reference/engine/classes/MarketplaceService.yaml`, `reference/cloud/{game-passes-http-service/v1.json, developer-products-api/v1.json, universes-api/v1.json, openapi.json}`, `cloud/auth/api-keys.md`, `cloud/guides/usage-place-publishing.md`, `cloud/reference/scopes.md`. Ejecutado en local: `rojo --version` (7.7.1), `rojo upload --help`.
Búsqueda web (resúmenes, sin abrir la página): hilos del DevForum 26974 y 4753185 sobre compras en Studio.
