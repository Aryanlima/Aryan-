# Fish & Fortune (MVP v1)

Pesca relajante en lagos compartidos: lanza la caña, recoge en el momento justo, descubre 25 criaturas de 6 rarezas en 3 zonas, véndelas, mejora tu caña y completa el bestiario. Concepto 1 del informe `ROBLOX/research/07`.

**Estado: código completo del MVP, NUNCA ejecutado en Roblox Studio.** Se ha comprobado con tests de lógica pura (Lune), análisis estático (selene, StyLua, luau-lsp con los tipos de Roblox) y `rojo build`. Antes de publicar hay que hacer el playtest de la sección 6 y la revisión humana de todo lo marcado `-- REVIEW(money):`.

Arquitectura, flujos de compra y de datos, decisiones y riesgos: [`../../docs/arquitectura.md`](../../docs/arquitectura.md).

---

## 1. Qué incluye

| Área | Contenido |
|---|---|
| Mundo | 3 zonas construidas **por código** (`server/WorldBuilder.luau`): Lago Calmo, Río Cristal, Costa Dorada. Partes simples, colores agradables, iluminación y viaje entre zonas. Limpio y sustituible por arte generado con IA. |
| Pesca | Lanzamiento con minijuego de ~3 s (barra, marcador, zona perfecta), 25 criaturas (6 rarezas), 5 cañas, venta, bestiario con recompensas, **pesca automática** (pase), inventario con slots, ganancias **offline** con tope. |
| Social / viral | **Banner global** al capturar un MÍTICO (MessagingService), códigos de canje, mensaje de bienvenida. |
| LiveOps | 2 eventos rotativos semanales (**Marea Dorada** x2 monedas, **Luna Mítica** +3 suerte gratuita), temporada con 10 niveles (pista gratis + premium), configurables **sin republicar**. |
| Monetización v1 | Pack de inicio, Pase 2x Dinero, Pase Auto-Pesca, Pase VIP, Pase de Temporada, Boost de Monedas 15 min, packs de monedas (3), pack de perlas, +10 slots. Servidor privado (VIP de Roblox). |
| Cumplimiento | Panel **Probabilidades** siempre accesible (botón con texto), suma 100 %, columna base, desglose de suerte. Sin lenguaje de presión. **Sin suerte ni azar de pago en la v1** (sección 4). |
| Tutorial (FTUE) | Los 3 primeros lanzamientos están garantizados (Poco común, Poco común, Raro) y una guía en pantalla lleva de *lanzar* a *vender* a *comprar la primera caña*. Objetivo: primera captura y primera venta en **≤ 60 s** (probado en `tests/GameLogic.spec.luau` con un jugador simulado). |
| Analítica | Embudo FTUE (6 pasos), embudo de tienda, eventos de economía (`LogEconomyEvent`), `first_join` con la **fuente** (referido, teletransporte, enlace, directo), capturas y MÍTICOS. |

Estructura:

```
default.project.json         proyecto Rojo
src/shared/                  Balance (TODO el balance), FeatureFlags, FishingRules, Remotes, ClientLogic, Store
src/server/                  Main.server (Script), GameService, GameLogic, Catalog, ProductIds (IDs), Schema,
                             LiveOpsDefaults, WorldBuilder, StudioMemoryStore
src/client/                  Main.client (LocalScript), Hud, Minigame, Feedback, Menus
tests/                       *.spec.luau de la lógica del juego (Lune)
```

Los paquetes compartidos (`Data`, `Economy`, `Shop`, `Odds`, `Net`, `LiveOps`, `Analytics`, `UI`) se mapean desde `../../packages/`.

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
bash ROBLOX/tools/test.sh      # tests de lógica pura
bash ROBLOX/tools/lint.sh      # selene + stylua --check + luau-lsp
bash ROBLOX/tools/format.sh    # aplica StyLua
```

Para un build: `rojo build default.project.json -o FishAndFortune.rbxl` (el `.rbxl` no se versiona).

---

## 3. Crear los pases y productos en Creator Hub y pegar los IDs

`src/server/ProductIds.luau` es el **único archivo con IDs**. Cada ID vale `0 -- TODO_ID` hasta que lo rellenes; un ID en 0 **oculta el objeto de la tienda** y bloquea su compra (no rompe nada).

1. Creator Hub → tu experiencia → **Monetización**.
2. Crea cada **pase** (Passes) y cada **producto de desarrollador** (Developer Products) con el nombre y precio sugerido de las tablas de abajo. Los precios salen de la escalera `Catalog.ladder`; son hipótesis para A/B test, no datos de mercado.
3. Copia el ID de cada uno y sustituye el `0` correspondiente en `ProductIds.luau`. Para los pases, usa el **ID del pase** (el `TargetId` que usa `PromptGamePassPurchase`), no el assetId; verifícalo con una compra de prueba.
4. Activa los pases/productos (*Item for sale*). Los pases deben estar a la venta para aparecer también fuera del juego.
5. Antes de publicar, ejecuta la puerta de calidad: `Shop.validateCatalog(catalogo, handlers, { allowPlaceholders = false })` (el test `tests/Catalog.spec.luau` muestra cómo) — falla si queda algún `0`.

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
* Todo el texto está en **español**; falta la localización EN/ES.
* El banner global es de **mejor esfuerzo** (MessagingService no garantiza la entrega) y tiene enfriamiento de 5 s por servidor.
* La analítica de Roblox solo envía desde servidores **publicados**; los gráficos tardan hasta 24 h.
* No hay rebirth ("Mareas"), cañas cosméticas de pago, intercambio ni zonas 4-6 (concepto completo en ROBLOX/research/07).
* `ConfigService` y la forma de su valor JSON: `-- VERIFY:` (sección 5).

---

## 8. Qué falta (arte, sonido, miniaturas)

* **Arte:** mapa y modelos (muelles, árboles, cartel, tienda), modelos de caña por tier, criaturas (iconos o modelos), skins de UI, partículas de captura, efecto del banner. El mundo actual es procedural y debe sustituirse respetando el contrato de `WorldBuilder` (`Workspace.World/<zona>/Spawn` y `CastTarget`).
* **Sonido:** lanzar, mordisco, captura por rareza, MÍTICO, venta, compra, música ambiente.
* **Icono y miniaturas** del juego (cumpliendo la guía de miniaturas de Roblox), 5-6 capturas con las criaturas más raras y un clip del banner MÍTICO (ROBLOX/research/05).
* **Cuestionario de madurez**, descripción y título únicos, texto de la tienda revisado por una persona.
* **Revisión humana** de `REVIEW(money)` y prueba con el Player Emulator antes de activar la suerte de pago (v1.5).

---

## 9. APIs de Roblox usadas y su verificación

Verificadas contra `Roblox/creator-docs` (2026-10-20): `MarketplaceService.ProcessReceipt`, `PromptProductPurchase`, `PromptGamePassPurchase`, `PromptGamePassPurchaseFinished`, `UserOwnsGamePassAsync`, `GetProductInfoAsync`; `PolicyService:GetPolicyInfoForPlayerAsync` y la propiedad `ArePaidRandomItemsRestricted` (+ `IsPaidItemTradingAllowed`); `DataStore:UpdateAsync` (el callback no cede; puede repetirse), límites y códigos de error; `game:BindToClose` (30 s, en paralelo); `AnalyticsService:LogEconomyEvent/LogFunnelStepEvent/LogOnboardingFunnelStepEvent/LogCustomEvent`; `MessagingService:PublishAsync/SubscribeAsync`; `Player:GetJoinData`; `TweenService:Create`; `ContextActionService:BindAction`; `RemoteEvent` (límite ~500/s por cliente). **Sin verificar del todo (`-- VERIFY:`):** el formato del valor de `ConfigService` y su límite de tamaño; la migración futura de `ProcessReceipt` a `BindReceiptHandler`.
