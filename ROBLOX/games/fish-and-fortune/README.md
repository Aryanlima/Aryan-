# Fish & Fortune (MVP v1)

Pesca relajante en lagos compartidos: lanza la caña, recoge en el momento justo, descubre 25 criaturas de 6 rarezas en 3 zonas, véndelas, mejora tu caña y completa el bestiario. Concepto 1 del informe `ROBLOX/research/07`.

**Estado: código completo del MVP, NUNCA ejecutado en Roblox Studio.** Se ha comprobado con tests de lógica pura (Lune), análisis estático (selene, StyLua, luau-lsp con los tipos de Roblox) y `rojo build`. Antes de publicar hay que hacer el playtest de la sección 6 y la revisión humana de todo lo marcado `-- REVIEW(money):`.

Arquitectura, flujos de compra y de datos, decisiones y riesgos: [`../../docs/arquitectura.md`](../../docs/arquitectura.md).

---

## 1. Qué incluye

| Área | Contenido |
|---|---|
| Mundo | 3 zonas construidas **por código** (`server/WorldBuilder.luau`): Lago Calmo, Río Cristal, Costa Dorada. Partes simples, colores agradables, iluminación y viaje entre zonas. **Cada pieza se puede sustituir por arte generado con IA sin tocar código y con respaldo procedural** (ver la sección 11, "Arte intercambiable"). |
| Pesca | Lanzamiento con minijuego de ~3 s (barra, marcador, zona perfecta), 25 criaturas (6 rarezas), 5 cañas, venta, bestiario con recompensas, **pesca automática** (pase), inventario con slots, ganancias **offline** con tope. |
| Social / viral | **Banner global** al capturar un MÍTICO (MessagingService), códigos de canje, mensaje de bienvenida. |
| LiveOps | 2 eventos rotativos semanales (**Marea Dorada** x2 monedas, **Luna Mítica** +3 suerte gratuita), temporada con 10 niveles (pista gratis + premium), configurables **sin republicar**. |
| Monetización v1 | Pack de inicio, Pase 2x Dinero, Pase Auto-Pesca, Pase VIP, Pase de Temporada, Boost de Monedas 15 min, packs de monedas (3), pack de perlas, +10 slots. Servidor privado (VIP de Roblox). |
| Cumplimiento | Panel **Probabilidades** siempre accesible (botón con texto), suma 100 %, columna base, desglose de suerte. Sin lenguaje de presión. **Sin suerte ni azar de pago en la v1** (sección 4). |
| Idiomas | **EN (por defecto/respaldo) y ES completos**, elegidos por jugador según su idioma de Roblox; todos los textos en un solo archivo (`src/shared/Strings.luau`). Ver la sección 10. |
| Tutorial (FTUE) | Los 3 primeros lanzamientos están garantizados (Poco común, Poco común, Raro) y una guía en pantalla lleva de *lanzar* a *vender* a *comprar la primera caña*. Objetivo: primera captura y primera venta en **≤ 60 s** (probado en `tests/GameLogic.spec.luau` con un jugador simulado). |
| Analítica | Embudo FTUE (6 pasos), embudo de tienda, eventos de economía (`LogEconomyEvent`), `first_join` con la **fuente** (referido, teletransporte, enlace, directo), capturas y MÍTICOS. |

Estructura:

```
default.project.json         proyecto Rojo
src/shared/                  Balance (TODO el balance, solo números), Strings (TODOS los textos, ES + EN), FeatureFlags,
                             FishingRules, Remotes, ClientLogic, Store, ArtProfiles (ficha de cada pieza de arte)
src/server/                  Main.server (Script), GameService, GameLogic, Catalog, ProductIds (IDs), Schema,
                             LiveOpsDefaults, WorldBuilder, StudioMemoryStore, ArtDirector (cana/escaparate de arte)
art/                         manifest.json (prompts de arte con IA) y models/<categoria>/<id>.rbxm (arte aceptado)
src/client/                  Main.client (LocalScript), Hud, Minigame, Feedback, Menus
tests/                       *.spec.luau de la lógica del juego (Lune); ProjectStructure y ClientBoot construyen el lugar con
                             `rojo build` y comprueban la estructura y el arranque del cliente (ver `../../docs/verificacion-estructura.md`)
tests/support/               ServerHarness (arnés de GameService, compartido) y BuiltPlace (construye el lugar con rojo)
```

Los paquetes compartidos (`Data`, `Economy`, `Shop`, `Odds`, `Net`, `LiveOps`, `Analytics`, `UI`, `Locale`, `Art`) se mapean desde `../../packages/`.

---

## 2. Correr el juego con Rojo + Studio

Requisitos en tu PC (ver `../../docs/setup-en-tu-pc.md`): Roblox Studio, [Rojo](https://rojo.space) 7.x con su plugin de Studio, y una cuenta de Roblox.

1. En Studio crea un lugar **de pruebas** vacío (no el de producción) y guárdalo/publícalo en tu cuenta.
2. Desde esta carpeta: `rojo serve default.project.json`.
3. En Studio: plugin Rojo → **Connect**. Aparecen `ReplicatedStorage.Packages/Shared`, `ServerScriptService.ServerPackages/Server` y `StarterPlayerScripts.Client`.
4. Pulsa **Play** (o *Test → Clients and Servers* para varios jugadores).
5. Sin "Enable Studio Access to API Services" el servidor usa un almacén **en memoria** (`StudioMemoryStore`; no se guarda nada) y avisa con `warn`. Con el acceso activado escribe en el DataStore **real** del lugar: usa un lugar de pruebas.
6. `MessagingService`, `ConfigService`, `AnalyticsService` y `PolicyService` pueden no responder en Studio: el código lo tolera (`pcall`, valores por defecto) y lo avisa en la salida.

Comprobaciones locales (desde la raíz del repositorio):

```
bash ROBLOX/tools/test.sh      # tests de lógica pura + estructura del lugar construido + arranque del cliente
bash ROBLOX/tools/lint.sh      # selene + stylua --check + luau-lsp (con el sourcemap de Rojo de este juego)
bash ROBLOX/tools/format.sh    # aplica StyLua
```

* `lint.sh` genera `ROBLOX/.toolchain/sourcemaps/fish-and-fortune.json` (`rojo sourcemap --absolute`, ignorado por git) y lo pasa a luau-lsp: los `require(carpeta:WaitForChild("Modulo"))` de `Main.server`/`Main.client` se resuelven y se tipan contra `default.project.json`; un nombre que no exista es un error de análisis. Los `require` van con literales (`packages:WaitForChild("Odds")`), no por una función con nombres en variables, porque esas no se pueden comprobar.
* Si añades, quitas o renombras un módulo/script/remoto: actualiza a propósito `EXPECTED` y las listas de `tests/ProjectStructure.spec.luau` (y `shared/Remotes.luau`). Esa prueba falla si el árbol de Rojo, los `require`, los remotos o `WorldBuilder` dejan de coincidir con lo que busca el cliente.
* Sin el binario `rojo`, esas dos pruebas se **omiten con un aviso** (con `ARYAN_REQUIRE_ROJO=1` fallan).

Para un build: `rojo build default.project.json -o FishAndFortune.rbxl` (el `.rbxl` no se versiona).

---

## 3. Crear los pases y productos en Creator Hub y pegar los IDs

`src/server/ProductIds.luau` es el **único archivo con IDs**. Cada ID vale `0 -- TODO_ID` hasta que lo rellenes; un ID en 0 **oculta el objeto de la tienda** y bloquea su compra (no rompe nada). **No lo edites a mano**: guía completa, con etapas, puertas y marcha atrás, en [`../../docs/publicar-paso-a-paso.md`](../../docs/publicar-paso-a-paso.md).

1. Crea la experiencia de prueba **privada** (guía, Etapa 1) y, en Creator Hub → **Monetización**, cada **pase** (Passes) y cada **producto de desarrollador** (Developer Products). La lista exacta —nombre y descripción en EN/ES, precio sugerido e ícono— está en `store-items.json` (generado del código por `lune run ROBLOX/tools/dump-store-items.luau`; una prueba falla si se desactualiza). Los precios salen de la escalera `Catalog.ladder`; son hipótesis para A/B test, no datos de mercado. Se puede hacer a mano o con `node ROBLOX/tools/create-items.mjs --universe <ID> --apply` (API BETA; clave solo en la variable `ROBLOX_API_KEY`).
2. Copia los IDs a `ids.local.json` (parte de `ids.example.json`; **sí se versiona**, no son secretos) y ejecuta `node ROBLOX/tools/wire-ids.mjs --dry-run` y luego `node ROBLOX/tools/wire-ids.mjs`: valida (sin 0 en lo habilitado, sin repetidos, sin negativos ni decimales), reescribe `ProductIds.luau` con formato de StyLua y corre la puerta `FF_RELEASE_CHECK=1 bash ROBLOX/tools/test.sh` (restaura el archivo si falla).
3. Para los pases, `REVIEW(money)`: la documentación de Roblox se contradice sobre si el ID es el `TargetId` o el assetId. Se resuelve con la prueba de la guía (Etapa 3.3); si difieren, `"vip": { "passId": <TargetId>, "assetId": <assetId> }` en `ids.local.json` y el juego usa `passId` para el diálogo y la propiedad y acepta el otro como alias (`ProductIds.passAssetIds`).
4. Activa los pases/productos (*Item for sale*) solo cuando la experiencia sea privada y estés probando, o en la publicación (Etapa 5). **No marques nada como "Listed"** hasta decidirlo tú.
5. Puerta previa a publicar: `FF_RELEASE_CHECK=1 bash ROBLOX/tools/test.sh` (ReleaseGate: sin IDs 0 en lo habilitado, y el servidor real con los IDs reales: prompts, recibos y pases).

**Pases (Game Passes)**

| Clave en `ProductIds` | Nombre | Precio sugerido | Qué hace |
|---|---|---:|---|
| `auto_fish` | Pase Auto-Pesca | 299 | Pesca automática; sube el tope offline a 6 h |
| `double_coins` | Pase 2x Dinero | 249 | Duplica las monedas de venta (aditivo con otros bonus, con tope x8) |
| `starter` | Pack de inicio | 99 | Pago único: 600 monedas, 10 perlas, 10 slots (sin azar) |
| `vip` | Pase VIP | 199 | Etiqueta VIP en banners, +10 % monedas, 5 perlas al día |
| `season_pass` | Pase de Temporada 1 | 399 | Pista premium de la temporada 1 (premios fijos) |
| `luck_plus` | Pase Suerte+ | 399 | **NO CREAR EN LA v1** (ver sección 4) |

**Productos de desarrollador**

| Clave en `ProductIds` | Nombre | Precio sugerido | Qué hace |
|---|---|---:|---|
| `coin_boost_15` | Boost de Monedas (15 min) | 49 | x2 monedas 15 min (aditivo, tope de acumulación 1 h) |
| `coin_pack_small` | Pack de monedas pequeño | 99 | 2.500 monedas |
| `coin_pack_medium` | Pack de monedas mediano | 499 | 15.000 monedas |
| `coin_pack_large` | Pack de monedas grande | 1.999 | 80.000 monedas |
| `pearl_pack` | Pack de perlas | 199 | 30 perlas |
| `slot_pack` | Más espacio (+10) | 99 | +10 slots (en el tope máximo se convierten en perlas 1:1) |
| `lucky_bait_15` | Cebo de Suerte (15 min) | 49 | **NO CREAR EN LA v1** (ver sección 4) |

Notas:
* **Servidor privado (VIP de Roblox):** se configura en Creator Hub (*Configure Experience → Monetization → Private Servers*), no en código. El juego detecta `game.PrivateServerId`: muestra "Servidor privado" y **no** publica banners globales desde ahí.
* **Suscripciones** (VIP mensual): no incluidas en este MVP; el Pase VIP es una compra única.
* **Cada temporada** necesita un pase nuevo: crea "Pase de Temporada 2", cambia el ID y el `season.id` de la configuración de LiveOps. Los premios sin reclamar de la temporada anterior se pierden al cambiar el `id` (avísalo en la UI).
* **Precios regionales:** la tienda muestra el precio real de `GetProductInfoAsync`; si falla, el de la escalera con `~`.
* Un jugador con **política restringida** o sin datos de política no ve ni compra nada que altere probabilidades (hoy no hay nada, ver sección 4).

---

## 4. Flag `paidLuckEnabled` (v1: suerte de pago APAGADA)

Decisión D9 del informe maestro: la v1 **no vende suerte ni azar con Robux** (sería un "objeto aleatorio de pago": odds dinámicas, `PolicyService` y alternativa por país). El flag único está en `src/shared/FeatureFlags.luau` y vale `false`.

Con el flag **apagado**:
* **Suerte+** y **Cebo de Suerte** no aparecen en la tienda, no se pueden comprar (`unavailable`) y no se consulta la propiedad del pase.
* Si llegara un **recibo antiguo** del Cebo (comprado con una versión previa al flag), `ProcessReceipt` lo **rechaza** con `NotProcessedYet`: no concede nada, no lo registra y deja un aviso `REVIEW(money)` en el log. El recibo queda sin resolver (ni se regala ni se consume). Si ocurriera de verdad: decidir entre (a) encender el flag solo para resolverlo y apagarlo, o (b) gestionar el reembolso con Roblox; no lo "arregles" devolviendo `PurchaseGranted` sin conceder.
* Ninguna fuente de suerte **de pago** cuenta en la tirada ni se lista en la UI de probabilidades. La suerte **gratuita** (cañas, lanzamiento perfecto, evento Luna Mítica) sí cuenta y la UI la muestra junto a la columna *base*.
* Ningún texto de tienda ni de tutorial menciona suerte comprable (lo comprueban `tests/Monetization.spec.luau` y `tests/Catalog.spec.luau`).

Para la **v1.5** (con el cumplimiento probado en el Player Emulator para AU, BE, NL, UK y BR): poner `paidLuckEnabled = true`, crear los dos objetos en Creator Hub y rellenar sus IDs. La lógica (PolicyService, odds dinámicas, gating) ya existe y la suite la cubre con el flag encendido y apagado.

---

## 5. LiveOps sin republicar (eventos, códigos, temporada)

Defaults en `src/server/LiveOpsDefaults.luau` (viven en el servidor: no exponen los códigos al cliente). Para cambiarlos sin republicar, publica en **Creator Hub → Configs** la clave `FishFortune_LiveOps` con un JSON como este (tiempos en segundos Unix UTC; sube `version` en cada cambio):

```json
{
  "version": 2,
  "events": [
    { "id": "golden_tide", "name": "Marea Dorada", "description": "Monedas x2 durante el evento.",
      "startsAt": 1793000000, "endsAt": 1793600000, "modifiers": { "coins": 2 } },
    { "id": "mythic_moon", "name": "Luna Mitica", "description": "+3 de suerte gratuita.",
      "cycle": { "anchor": 1792368000, "slotSeconds": 604800, "slotCount": 2, "slot": 1 },
      "modifiers": { "luck": 3 } }
  ],
  "codes": { "BIENVENIDA": { "reward": { "coins": 1000, "pearls": 5 }, "expiresAt": 1795000000 } },
  "welcome": { "id": "w2", "message": "Nueva temporada disponible." },
  "season": { "id": 1, "name": "Temporada 1", "startsAt": 1792368000, "endsAt": 1797000000 }
}
```

* Los servidores refrescan cada ~120 s; una configuración **inválida** o un error de red conservan la anterior (se registra el motivo).
* Los códigos se escriben en MAYÚSCULAS (A-Z, 0-9, guion), caducan con `expiresAt` (el instante de fin ya no es canjeable) y se canjean **una vez por jugador**.
* Los eventos ciclan solo si defines `cycle`; un evento con fecha fija **no se repite**. Máximo 10 eventos activos/próximos.
* `-- VERIFY:` el formato exacto del valor en Configs (string JSON o tabla) y su límite de tamaño por clave no están verificados (la documentación oficial se contradice: 256 caracteres por clave en la API de Open Cloud frente a 100.000 en la guía). El código acepta ambos formatos; si JSON no cabe, mueve la configuración a un DataStore o a varias claves.
* Aviso inmediato opcional: publica en el tema de `MessagingService` `FishFortune_LiveOpsUpdated` (Open Cloud) y los servidores refrescan en segundos.

---

## 6. Checklist de playtest manual

Hazlo en un lugar de pruebas, con un jugador nuevo (o borra su clave en el DataStore de pruebas).

**Arranque y estructura (primero; lo que no se puede comprobar sin Studio, ver `../../docs/verificacion-estructura.md` sección 4)**
- [ ] Salida del servidor sin errores en rojo: aparece `[FishFortune] servidor iniciado` y ninguna advertencia `Infinite yield possible`.
- [ ] En el Explorer, tras Play: `ReplicatedStorage.Remotes` con 23 RemoteEvents, `Workspace.World` con `lake`, `river` y `coast`, `Workspace.SpawnLocation` y la interfaz `FishFortune` en `PlayerGui`.
- [ ] El `LocalScript` de `StarterPlayerScripts.Client.Main` se ejecuta (anidado en la carpeta `Client`) y la interfaz sale una sola vez al reaparecer.

**Primeros 60 segundos (cronómetro en mano)**
- [ ] Apareces en el muelle del Lago Calmo con una caña en la mano y ves "Pulsa LANZAR para pescar" (objetivo visible, cero menús previos).
- [ ] Primera captura antes de los 20 s (Poco común garantizada) y aviso de "NUEVO en tu bestiario".
- [ ] Primera venta antes de los 40 s; la guía te lleva de LANZAR a VENDER.
- [ ] Antes de los 60 s puedes comprar la Caña de Junco (120 monedas) y se ve la tercera captura (Raro) como "reveal".
- [ ] En el móvil (emulador de Studio y un dispositivo real de gama baja) los botones se ven grandes y no se tapan con el chat ni con el pulgar.

**Pesca y economía**
- [ ] El marcador pasa por la zona verde; recoger fuera de ella igualmente da captura; esperar de más suelta el pez.
- [ ] Inventario lleno: la captura se vende sola y no se pierde.
- [ ] Vender con 2x Dinero + VIP (usa un pase de prueba): el multiplicador suma (x2,1), no multiplica.
- [ ] Salir y volver tras unos minutos: aviso de ganancias offline (mínimo 2 min, tope 2 h; 6 h con Auto-Pesca).
- [ ] Desbloquear el Río Cristal (2.000 monedas) y viajar; la costa (30.000).

**Probabilidades (cumplimiento)**
- [ ] Botón **Probabilidades** visible; cada zona suma exactamente 100,00 % y no hay filas en 0,00 %.
- [ ] Con caña de más suerte cambian los porcentajes y aparece la columna *base*; el desglose solo lista fuentes **gratuitas**.
- [ ] Los 3 primeros lanzamientos muestran la nota del tutorial.
- [ ] Ninguna pantalla menciona suerte comprable.

**Compras (con cuentas/Robux de prueba)**
- [ ] Cada pase y producto abre el diálogo de Roblox y concede **una sola vez**.
- [ ] Comprar un producto y cerrar el juego justo después: al volver se concede (o ya estaba concedido), nunca doble.
- [ ] Con el DataStore apagado (Studio sin acceso) las compras devuelven *NotProcessedYet* y no conceden.
- [ ] Suerte+ y Cebo **no** aparecen en la tienda.
- [ ] Un ID en 0 oculta el objeto.

**Datos y servidores**
- [ ] *Test → Clients and Servers*: dos servidores con el mismo jugador no pueden cargar a la vez (mensaje claro).
- [ ] Cerrar el servidor (Stop) guarda a todos (BindToClose).
- [ ] Un fallo de DataStore al entrar expulsa con mensaje y **no** sobrescribe el progreso.

**Idiomas (ES/EN)**
- [ ] Con la cuenta de Roblox en inglés: HUD, tienda, probabilidades, bestiario, temporada, códigos, avisos, banner de Mítico y carteles de zona salen en inglés; en español, en español. Ningún texto sale como una clave (`hud.coins`, `toast.sold`...) ni con llaves `{...}` sin sustituir.
- [ ] Las cifras del panel Probabilidades son las mismas en ambos idiomas (solo cambia `12.34%` por `12,34 %`) y siguen sumando 100 %.
- [ ] El nombre y la descripción que muestra el **diálogo de compra de Roblox** salen del Creator Hub: tradúcelos allí (Configure Experience → Localization, y la traducción de cada pase/producto).
- [ ] Un idioma no soportado (p. ej. francés) cae a inglés sin errores.

**Social y LiveOps**
- [ ] Capturar un MÍTICO (usa un RNG de prueba o sube la suerte en un lugar de pruebas) muestra el banner en este servidor y, con 2 servidores publicados, en el otro.
- [ ] Canjear `WELCOME` una vez; la segunda vez dice "Ya canjeaste ese código".
- [ ] Cambiar la configuración remota (sección 5) se refleja en ~2 minutos sin republicar; una configuración inválida no rompe nada.
- [ ] Temporada: los puntos suben con las capturas, los premios gratis se reclaman una vez y los premium exigen el pase.

**Seguridad**
- [ ] Desde la consola del cliente, dispara los remotos con valores raros (`NaN`, números enormes, tablas): se rechazan sin errores y sin efecto.

---

## 7. Límites conocidos

* **No probado en Studio.** Toda la integración con el motor (`GameService`, cliente, `WorldBuilder`) está tipada y revisada, pero no ejecutada.
* **`Data` es una implementación propia**: en producción, sustituir por ProfileStore (ver `ROBLOX/docs/arquitectura.md`).
* El minijuego depende del tiempo que informa el cliente: un script puede acertar siempre la zona perfecta (+1 de suerte gratuita). Es un riesgo aceptado y acotado.
* Los códigos de canje son por jugador; un límite global de usos necesitaría un almacén compartido (MemoryStore/DataStore).
* El pase de temporada es de **una** temporada: hay que crear un pase por temporada.
* **Idiomas:** solo ES y EN. Otro idioma de Roblox (francés, portugués...) ve **español** (decisión de producto: ver sección 10). Los textos que llegan de la configuración remota de LiveOps (nombre de un evento nuevo, mensaje de bienvenida nuevo) se muestran en el idioma en que se escribieron salvo que se añada su clave a `Strings.luau`.
* El banner global es de **mejor esfuerzo** (MessagingService no garantiza la entrega) y tiene enfriamiento de 5 s por servidor.
* La analítica de Roblox solo envía desde servidores **publicados**; los gráficos tardan hasta 24 h.
* No hay rebirth ("Mareas"), cañas cosméticas de pago, intercambio ni zonas 4-6 (concepto completo en ROBLOX/research/07).
* `ConfigService` y la forma de su valor JSON: `-- VERIFY:` (sección 5).

---

## 8. Qué falta (arte, sonido, miniaturas)

* **Arte:** el sistema para enchufar arte generado ya existe (sección 11) pero **no hay ninguna pieza generada todavía**: faltan por hacer en Studio (sesión del PC) los modelos de las criaturas, cañas, muelle, farolas, barca y árboles, y los materiales del suelo (`../../docs/arte-con-ia-en-studio.md`). Siguen sin existir: skins de UI, partículas de captura, efecto del banner, criaturas en el bestiario/tienda (necesitarían `ViewportFrame` en el cliente). El contrato del mundo (`Workspace.World/<zona>/Spawn`, `CastTarget`, `Sign`) no cambia con el arte.
* **Sonido:** lanzar, mordisco, captura por rareza, MÍTICO, venta, compra, música ambiente.
* **Icono y miniaturas** del juego (cumpliendo la guía de miniaturas de Roblox), 5-6 capturas con las criaturas más raras y un clip del banner MÍTICO (ROBLOX/research/05).
* **Cuestionario de madurez**, descripción y título únicos, texto de la tienda revisado por una persona.
* **Revisión humana** de `REVIEW(money)` y prueba con el Player Emulator antes de activar la suerte de pago (v1.5).

---

## 9. APIs de Roblox usadas y su verificación

Verificadas contra `Roblox/creator-docs` (2026-10-20): `LocalizationService.RobloxLocaleId` (propiedad de solo lectura, no cede, formato `es-es`/`en-us`), `Player.LocaleId` (alternativa documentada; propiedad oculta), `GuiBase2d.AutoLocalize`, `MarketplaceService.ProcessReceipt`, `PromptProductPurchase`, `PromptGamePassPurchase`, `PromptGamePassPurchaseFinished`, `UserOwnsGamePassAsync`, `GetProductInfoAsync`; `PolicyService:GetPolicyInfoForPlayerAsync` y la propiedad `ArePaidRandomItemsRestricted` (+ `IsPaidItemTradingAllowed`); `DataStore:UpdateAsync` (el callback no cede; puede repetirse), límites y códigos de error; `game:BindToClose` (30 s, en paralelo); `AnalyticsService:LogEconomyEvent/LogFunnelStepEvent/LogOnboardingFunnelStepEvent/LogCustomEvent`; `MessagingService:PublishAsync/SubscribeAsync`; `Player:GetJoinData`; `TweenService:Create`; `ContextActionService:BindAction`; `RemoteEvent` (límite ~500/s por cliente). **Sin verificar del todo (`-- VERIFY:`):** el formato del valor de `ConfigService` y su límite de tamaño; la migración futura de `ProcessReceipt` a `BindReceiptHandler`; que `LocalizationService.RobloxLocaleId` devuelva en Studio/cliente el idioma de la cuenta (no probado), si `Player.LocaleId` se puede leer desde el servidor (la documentación no lo dice; por eso el servidor no lo usa) y la actualización de los carteles de zona (`LocaleKey`) con streaming.

---

## 10. Idiomas (ES / EN): cómo se elige y cómo añadir uno

**Cómo se elige.** El cliente lee `LocalizationService.RobloxLocaleId` (el idioma de la cuenta de Roblox, p. ej. `es-mx`, `en-us`) y `Locale:resolveLanguage` lo convierte en un idioma soportado (`es`, `en`). Cualquier otro valor, vacío o con error cae al **idioma por defecto (EN)**. Se relee en cada texto, así que un cambio de idioma se aplica en el siguiente refresco de la interfaz. `-- VERIFY:` no se ha probado en Studio. Alternativa documentada: `Player.LocaleId`. **Decisión tomada (2026-10-20):** un jugador con un idioma no soportado ve **inglés** (lengua común más probable para el resto del mundo); si prefieres otro, cambia `default` en `src/shared/Strings.luau` (afecta también al respaldo de claves que falten).

**Qué manda el servidor.** Nunca texto: manda **claves + argumentos** (`{ key = "toast.sold", args = { count = 3, coins = 120 } }`). El cliente los valida contra listas blancas (`Locale.sanitizeMessage`: prefijos de clave permitidos `toast.`/`banner.`/`welcome.`, claves que existen, solo los argumentos que declara la plantilla, números finitos, cadenas UTF-8 cortas, referencias `{ key = "creature.minnow" }` solo a `creature./zone./rod./pass./product./rarity.`) y los traduce. Los motivos de rechazo (`CastFailed`) ya eran códigos (`maxed`, `inventory-full`...) y se traducen como `fail.<motivo>`. Las **expulsiones** (`Kick`) muestran ES y EN juntos, porque el servidor no conoce el idioma del jugador antes de que cargue su cliente.

**Dónde están los textos.** Un solo archivo, `src/shared/Strings.luau`, con cada clave y sus idiomas lado a lado:

```lua
["toast.sold"] = {
	es = { one = "Vendiste 1 captura por {coins} monedas.", other = "Vendiste {count} capturas por {coins} monedas." },
	en = { one = "Sold 1 catch for {coins} coins.", other = "Sold {count} catches for {coins} coins." },
},
```

* Marcadores `{nombre}` (los mismos en todos los idiomas). Si pasas un **número**, se formatea según el idioma (`1.500` en ES, `1,500` en EN); si pasas una **cadena**, se usa tal cual (p. ej. `1,2K` ya abreviado).
* Plural: `count` elige `one`/`other`.
* El balance (`Balance.luau`) ya no lleva textos: nombres y descripciones se buscan por id (`creature.<id>`, `rod.<id>`, `zone.<id>.name|desc`, `rarity.<Rareza>`, `bestiary.reward.<id>`; tienda: `pass.<clave>.name|desc`, `product.<clave>.name|desc`; eventos: `event.<id>.name`; temporada: `season.<id>.name`; bienvenida: `welcome.<id>`).
* Números: `Locale.formatNumber`/`formatCompact`/`formatPercent` cambian **solo los separadores** (ES `12,34 %`, EN `12.34%`); las cifras del panel de probabilidades son idénticas en todos los idiomas (lo comprueba `tests/ClientLogic.spec.luau`).
* Tono: neutro y honesto en ambos idiomas; sin urgencia ni presión de compra. La prueba de lenguaje de presión recorre **todos** los textos de **todos** los idiomas.

**Añadir un idioma (p. ej. portugués `pt`).**
1. En `Strings.luau`, añade `"pt"` a `languages` y un campo `pt = "..."` (o `{ one, other }`) en **cada** entrada. Mantén los mismos marcadores.
2. Si su plural no es "1 = singular", añade su regla en `Locale.pluralCategory` y, si usa otros separadores, en `DECIMAL_SEPARATOR`/`GROUP_SEPARATOR` (`packages/Locale.luau`).
3. `bash ROBLOX/tools/test.sh`: `tests/Strings.spec.luau` falla si falta una clave, si hay un texto vacío o si los marcadores no coinciden. Hasta que esté completo, un idioma a medias cae al idioma por defecto (EN) por clave.
4. Revisa a mano la traducción (nada de traducción literal ni de presión de compra) y, en el playtest, la lista "Idiomas".

**Añadir o cambiar un texto.** Edita/añade la entrada en `Strings.luau` (ES **y** EN) y úsala con `L("clave", { args })` en el cliente o `toast(player, "toast.clave", { args })` en el servidor. La prueba escanea el código: falla si usas una clave que no existe, si dejas una clave sin usar o si escribes un texto visible a mano en el cliente.

**Lo que no se localiza aquí.** (1) El nombre/descripción del **diálogo de compra de Roblox**, la ficha del juego, los iconos y las miniaturas: se traducen en el Creator Hub. (2) Los textos de la configuración remota de LiveOps (sección 5): un evento, temporada o bienvenida **nuevos** sin clave en `Strings.luau` se muestran con el texto configurado (en el idioma en que lo escribas); para traducirlos añade `event.<id>.name`, `season.<id>.name` o `welcome.<id>` y republica. (3) Los avisos de servidor y los logs (`warn`) siguen en español (no los ve el jugador). La traducción automática de Roblox está desactivada para esta interfaz (`AutoLocalize = false`) para que no vuelva a traducir lo ya localizado.

---

## 11. Arte intercambiable (modelos generados con IA, con respaldo procedural)

**Idea:** el mundo, la caña y las criaturas tienen una ficha (`src/shared/ArtProfiles.luau`: tamaño objetivo, pivote, presupuesto de triángulos). El proveedor `../../packages/Art.luau` busca para cada pieza una **plantilla** en `ServerStorage/Art/<categoría>/<id>`; si no existe o no es válida, se usa el generador procedural de siempre. **Sin plantillas el juego es idéntico al de antes** (hay una prueba de firma del mundo).

| Categoría | Ids | Dónde se usa |
|---|---|---|
| `creatures` | los 25 de `Balance.creatures` | Escaparate: al pescar una Rara o mejor (Legendaria o mejor en pesca automática) la criatura salta del agua 3,5 s sobre el punto de lanzamiento, visible para todos. Solo si hay arte de ESA criatura |
| `rods` | los 5 de `Balance.rodOrder` | Caña en la mano del personaje (si no hay arte, la `Part` de colores de siempre) |
| `props` | `pier`, `lantern`, `rowboat`, `pine_tree`, `palm_tree` | Muelle (con respaldo), árboles (con respaldo), farolas y barca (**sin** respaldo: sin arte no aparecen) |
| materiales | `FF_ground_lake`, `FF_ground_river`, `FF_ground_coast`, `FF_pier_wood` | `MaterialVariant` en `MaterialService` aplicado al suelo y al muelle procedural |

**Dónde viven (decisión de replicación):** `ServerStorage/Art`. Todo lo que hoy usa arte es del servidor (mundo, caña en el personaje, escaparate), y lo que el servidor coloca en `Workspace` o en el personaje se replica solo. Las plantillas **no se descargan al cliente** y un cliente tramposo no puede tocarlas. Si en el futuro el bestiario o la tienda muestran modelos 3D en un `ViewportFrame`, habrá que copiar esas plantillas a `ReplicatedStorage` (`Art` ya es seguro para el cliente: está en `ReplicatedStorage.Packages`).

**Seguridad:** la validación (`Art.validate`) es una **lista blanca** de clases (`Model, Folder, MeshPart, Part, WedgePart, SurfaceAppearance, Decal, Texture, Attachment, WeldConstraint`): un asset con un script (en cualquier nivel), un remoto, un sonido, etc. se rechaza, se avisa **una vez** en la salida y se usa el respaldo. También se rechazan: modelo sin partes, `MeshPart` sin `MeshId` o con un `MeshId` que no es un asset de Roblox, tamaños absurdos o no finitos, más de 12 partes o 64 instancias, y `ArtTriangles` (atributo que escribe el script de archivado) por encima del presupuesto de la pieza o de 20.000. Nada se ejecuta: solo se clona y se normaliza (visual, sin colisiones, anclado). `MeshId` nunca se asigna por código (es de solo lectura para scripts).

**Convención del modelo en su plantilla:** `Model` con el nombre exacto del id, ejes del mundo sin girar, alto en Y, frente (morro / punta de la caña) hacia −Z, un material, sin scripts. Si sale girado, el perfil corrige con `rotation`.

**Cómo se llena:**
1. Generar con IA dentro de Studio y archivar: `../../docs/arte-con-ia-en-studio.md` (runbook para la sesión del PC) y `../../docs/prompt-pc-arte-ia.md` (mensaje para pegar). Los prompts exactos, los lotes diarios y los criterios de aceptación están en `art/manifest.json`; el resultado se anota en `../../docs/arte-ia-informe.md`.
2. Para versionar el arte aceptado: guardar cada modelo como `art/models/<categoría>/<id>.rbxm`. El proyecto Rojo ya mapea esas tres carpetas a `ServerStorage.Art.<categoría>` con `$ignoreUnknownInstances: true`, así que `rojo serve` **no borra** lo que haya en Studio y `rojo build` incluye los `.rbxm`. Los `MaterialVariant` se quedan en el lugar guardado desde Studio.
3. **No publicar el lugar con `rojo upload`/`rbxcloud` mientras haya arte que solo esté en el lugar** (el build no lo trae y sobrescribiría la versión). Los `SurfaceAppearance` (texturas PBR) no los actualiza la API de publicación (`usage-place-publishing.md`): publicar desde Studio.

**Al arrancar** el servidor escribe `[Art] arte generado: N de 35 piezas (M sin arte -> respaldo procedural, K rechazadas)` y una línea por cada plantilla rechazada con su motivo.

**Pruebas:** `../../tests/Art.spec.luau` (proveedor: con arte, sin arte, arte inválido con script, arte a medias, escala/pivote/rotación, soldaduras, materiales), `tests/ArtProfiles.spec.luau` (fichas y manifiesto sin desviaciones, prompts sin marcas ni casino, lotes), `tests/ArtDirector.spec.luau` (caña y escaparate), `tests/ArtWorld.spec.luau` (`WorldBuilder` sobre el lugar construido por Rojo) y las pruebas de `GameService.spec.luau` con `ArtDirector`.

**Sin verificar en Studio (`-- VERIFY:`):** que `generate_mesh` deje un `MeshId` de asset persistente; el recuento de triángulos real de cada malla (solo se valida el atributo `ArtTriangles`); el aspecto en el motor de la caña soldada a la mano, del escaparate y de la altura de la cubierta del muelle de arte; el comportamiento de `Massless`/`WeldConstraint` con el rig real; que el nombre y el contenido de las plantillas sobrevivan a un guardado/publicación desde Studio.

