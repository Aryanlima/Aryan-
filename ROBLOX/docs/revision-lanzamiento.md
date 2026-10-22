# Revision de lanzamiento (auditoria de solo lectura)

Fecha: 2026-10-22. Alcance: `games/fish-and-fortune/src`, `packages/*.luau` (Data, Economy, Shop, LiveOps, Analytics, Net, Odds) y docs.
Los paquetes son archivos planos (`packages/Data.luau`), no carpetas. Nada se ejecuto en Studio: todo es lectura de codigo.
Rutas: GS = `games/fish-and-fortune/src/server/GameService.luau`, GL = `.../server/GameLogic.luau`, FR = `.../shared/FishingRules.luau`.
Estados: hecho / bloqueado (depende de una accion tuya o de Roblox) / no aplica / riesgo.

## 1. Persistencia

| Item | Estado | Evidencia | Accion |
|---|---|---|---|
| Bloqueo de sesion con UpdateAsync, jobId y latido | hecho | packages/Data.luau:492-535, 696-711 | Ninguna |
| Reintentos con backoff exponencial + jitter; errores 101-107 no se reintentan | hecho | Data.luau:425-460 (5 intentos, 1-16 s; 8 al liberar, :716) | Ninguna |
| Guardado en PlayerRemoving y BindToClose en paralelo, con limite de cola (301-306) | hecho | Data.luau:463-470, 785; GS:926-928 | Probar un cierre con muchos jugadores: no verificable aqui |
| Si la carga falla no se escriben datos por defecto (se expulsa) | hecho | Data.luau:563-632; GS:135-141 | Ninguna |
| Salir y volver a entrar: espera al bloqueo (30 s, sondeo 3 s) | hecho | Data.luau:577-612 | Ninguna |
| El bloqueo caduca a 600 s tras un crash; el mensaje dice "espera un minuto" | riesgo | Data.luau:496; docs/revision-codigo-dinero.md DATA-01 | Decidir `staleSeconds=300` y autosave 90 s (propuesto, sin aplicar) |
| Migraciones versionadas; rechaza datos de version mayor | hecho | Data.luau:191-215; server/Schema.luau:13-24 | `Schema.version = 1`: la primera migracion real no esta probada |
| Nombre del DataStore fijo `FishFortune_PlayerData_v1` | hecho | GS:33 | No cambiarlo tras publicar |
| Studio usa memoria o el DataStore REAL (pickDataStore) | riesgo | GS:110-127 | Ver nota |
| Autosave cada 120 s | hecho | GS:132; Data.luau:749-770 | Ninguna |
| Ganancias offline: lastSeen vivo, reloj atrasado = 0 | hecho | GS:978-982; packages/Economy.luau:297-299 | Ninguna |

Nota Studio: si el lugar esta publicado y "Studio Access to API Services" esta activo, `pickDataStore` hace `GetAsync("__studio_probe")` y,
si funciona, escribe en el DataStore REAL con el MISMO nombre que produccion (GS:110-121). Solo avisa con `warn`. En el lugar privado de pruebas
(docs/publicar-paso-a-paso.md:85) no toca produccion, pero el codigo no lo impide. Accion: otro nombre de store en Studio (sufijo `_studio`)
o no activar el acceso a la API en el lugar de produccion.

## 2. Integridad del bucle central (servidor)

| Item | Estado | Evidencia | Accion |
|---|---|---|---|
| Cast: posicion medida por el servidor, cooldown e inventario lleno | hecho | GS:602-626; GL:345-358 | Ninguna |
| Reel: castId entero y `elapsed` 0-30; el servidor compara con su reloj (too-early, impossible-time, stale, expired) | hecho | GS:639-653; FR:176-208 | Ninguna |
| Un solo lanzamiento activo; se borra al pescar o fallar; cooldown tras cada intento | hecho | GL:420-444 | Ninguna |
| Pescar dos veces con el mismo castId | hecho | GL:429, 440 | Ninguna |
| NaN en `elapsed` | hecho | FR:190; Net valida `t.number` | Ninguna |
| La ventana de trampa (2,85 s) supera el periodo del marcador (1,5 s): un bot acierta "perfect" | riesgo | docs/revision-codigo-dinero.md MINI-01 | Decision tuya; afecta la calidad de pesca, no duplica dinero |
| Venta (SellAll) sin argumentos, calculo en el servidor, sin yields | hecho | GS:656-672; GL:462 | Ninguna |
| Compras (cana, zona, espacios con perlas): validadores por tipo y listas cerradas | hecho | GS:679-760, 772-780; GL:481-577 | Ninguna |
| Limite por remoto (token bucket) + limite global 40/20 s + aviso de abuso | hecho | packages/Net.luau:335-366; GS:210-218 | `onAbuse` solo registra, no expulsa: aceptable |
| Los 16 remotos de entrada estan en la lista y los vistos tienen `rate` | hecho | shared/Remotes.luau:12-29; GS:594-870 | Revisados a mano: RequestState, Cast, Reel, SellAll, SetAutoFish, ClaimBestiary, ClaimSeason, ClaimDaily, BuySlotsWithPearls, RedeemCode, RequestOffers, RequestPurchase; el resto pasa por `simpleAction` (no leido linea a linea) |
| Compras del cliente piden por CLAVE, nunca por precio ni ID | hecho | GS:852-856 (`^[%w_]+$`) | Ninguna |
| Suite de pruebas / fuzzing de remotos | no verificable | tests/GameService.spec.luau existe; no se ejecuto | Correr la suite antes de publicar |

## 3. Monetizacion

| Item | Estado | Evidencia | Accion |
|---|---|---|---|
| Un unico ProcessReceipt, idempotente por PurchaseId, guarda antes de confirmar | hecho | packages/Shop.luau:477-570, 1010-1017 | REVIEW(money): lectura humana pendiente |
| Historial de PurchaseId acotado a 500 | riesgo (bajo) | Shop.luau:441-460 | Un recibo viejo sin resolver podria repetirse tras 500 compras; improbable, revisar |
| Pases: UserOwnsGamePassAsync con reintentos y re-verificacion tras comprar | hecho | Shop.luau:630-640, 787-795 | REVIEW(money) PASS-01 (Shop.luau:650, 772) |
| Fallo de consulta de pase = propiedad DESCONOCIDA, no "no poseido" | hecho | Shop.luau:650, 772 | Ninguna |
| IDs reales (no 0): pases auto_fish, double_coins, starter, vip, season_pass, golden_rod, bubble_trail; productos coin_boost_15, coin_pack_small/medium/large, pearl_pack, slot_pack | hecho | server/ProductIds.luau:25-42 | Confirmar en Creator Hub que cada ID coincide con nombre y precio de store-items.json |
| IDs en 0: `passes.luck_plus` y `products.lucky_bait_15` | hecho (a proposito) | ProductIds.luau:28, 36 | Apagados en v1 |
| `passAssetIds` vacio: TargetId frente a assetId sin comprobar | bloqueado | ProductIds.luau:19, 43; docs/pc-investigacion/verificacion-pases-y-publicacion.md:120 | Probar una compra real de un pase |
| Suerte de pago apagada (`paidLuckEnabled=false`); recibos viejos devuelven NotProcessedYet | hecho | shared/FeatureFlags.luau:22; Shop.luau:497-509; GL:290 | REVIEW(money) FeatureFlags.luau:19: encenderla es decision de cumplimiento |
| PolicyService: sin datos = restringido; no se consulta con el flag apagado | hecho | Shop.luau:586-622; GS:236-239, 879 | Probar con Player Emulator antes de v1.5 |
| Textos honestos, sin urgencia, ofertas ni cuenta atras | hecho | shared/Strings.luau:15 | Solo se leyo la regla y una busqueda de palabras; no se leyo todo el texto |
| Jugador ausente en el recibo: NotProcessedYet y reintento al volver | hecho | Shop.luau:497-505 | Ninguna |
| Analitica de compra solo tras guardar, una vez | hecho | GS:72-76, 393; Shop.luau:572-585 | REVIEW(money) ANALYTICS-01 |
| Compra de prueba real | bloqueado | docs/pc-investigacion/verificacion-pases-y-publicacion.md:98 | La hace Aryan |

## 4. Diario, temporada y codigos

| Item | Estado | Evidencia | Accion |
|---|---|---|---|
| Diario VIP: dia UTC con `os.time()//86400` del servidor, un cobro por dia | hecho | GL:676-687 | No existe racha (streak): no aplica |
| Doble cobro entre servidores | hecho | `lastClaimDay` dentro del perfil con bloqueo de sesion | Ninguna |
| Temporada: `claimedFree/Premium` por tier; premium exige el pase | hecho | GL:635-672 | Ninguna |
| Codigos: normalizados, un canje por perfil, ventanas con hora del servidor, guardado inmediato | hecho | packages/LiveOps.luau:551-576; GS:814-840 | Limite 3 intentos y 0,1/s |
| Premio mal formado se revierte | hecho | GS:822-830 | Ninguna |
| Premios y eventos vienen de ConfigService (formato no verificado) | bloqueado | GS:143-150; revision-codigo-dinero.md CONFIG-01 | Probar con una config real |
| Offline con tope por pase | hecho | GL:690-713 | Ninguna |

## 5. Analitica y privacidad

| Item | Estado | Evidencia | Accion |
|---|---|---|---|
| Eventos minimos: ftue, embudo de tienda (3 pasos), economia, catch, mythic, first_join, code_redeemed, net_abuse | hecho | GS:259, 374, 393-394, 421, 473, 833, 847, 864, 915 | Ninguna |
| Campos personalizados solo con datos de juego (rareza, id de criatura, origen) | hecho | GS:421, 473, 915 | Sin nombres ni texto libre |
| Nombres de evento validados y con tope de variantes | hecho | packages/Analytics.luau:119, 233-256 | Ninguna |
| Clave del perfil enlazada al UserId para borrado (RTBF) | no verificable | no se leyo el armado de la clave | Confirmar `User_{UserId}` o AddUserId |

## 6. Politicas y publicacion (segun los docs)

| Item | Estado | Evidencia | Accion |
|---|---|---|---|
| Cuestionario de madurez veraz | bloqueado | docs/publicar-paso-a-paso.md:184, 196 | Lo contesta Aryan (v1: sin apuestas, sin azar de pago, sin chat propio) |
| Formulario fiscal W-9 | bloqueado | docs/publicar-paso-a-paso.md:183 | Lo hace Aryan |
| Lectura humana de todo `REVIEW(money)` | bloqueado | docs/publicar-paso-a-paso.md:193 | Pendientes DATA-01, MINI-01, CONFIG-01 |
| Iconos y miniaturas finales | bloqueado | docs/publicar-paso-a-paso.md:194; borradores en `marketing/fish-and-fortune/assets/icon/` | Subir los finales en Creator Hub |
| Descripciones de la experiencia y de cada objeto | hecho (borrador) | games/fish-and-fortune/store-items.json; docs/publicar-paso-a-paso.md:115 | Pegar en Creator Hub (EN y ES) |
| Puerta previa a publicar (FF_RELEASE_CHECK=1) | hecho (no ejecutada) | tests/ReleaseGate.spec.luau | Ejecutarla antes de subir |
| IA generativa en vivo | no aplica | docs/pc-investigacion/verificacion-studio-politicas.md:47 | Solo si se anade |
| Acceso al universo (bloquear teletransporte desde otros lugares) | no verificable | sin referencia en el repo | Revisar en Creator Dashboard |

## Sitios REVIEW(money)

Catalog.luau:20, 192 | GameLogic.luau:9 | GameService.luau:14, 72, 978 | ProductIds.luau:19 | FeatureFlags.luau:19 |
packages/Data.luau:29 | packages/Economy.luau:17 | packages/Shop.luau:20, 36, 263, 392, 507, 650, 763, 772 | tests/PassIds.spec.luau:6 (solo cita).

## Riesgos principales

1. Studio puede escribir en el DataStore de produccion (mismo nombre): GS:110-127.
2. Primer pase real: TargetId frente a assetId sin probar: ProductIds.luau:19, 43.
3. Bloqueo de sesion de 600 s tras un crash: Data.luau:496 (DATA-01).
4. Minijuego enganable (ventana 2,85 s > periodo 1,5 s): FR:176-208 (MINI-01).
5. Historial de recibos limitado a 500: Shop.luau:441-460.
