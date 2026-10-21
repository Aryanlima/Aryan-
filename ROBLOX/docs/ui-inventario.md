# Inventario de UI - Fish & Fortune (para el rediseno)

Rutas: `G` = `games/fish-and-fortune/src/client`, `UI` = `packages/UI.luau`. Raiz: un solo `ScreenGui` "FishFortune" (`G/Main.client.luau:46`, DisplayOrder 5, ResetOnSpawn=false, IgnoreGuiInset=false, AutoLocalize=false).
No hay opcion de "movimiento reducido" en el codigo (grep: nada). Habria que anadirla.

## 1. Pantallas y elementos

### HUD (`G/Hud.luau`)
| Elemento (Name) | Linea | Muestra | Helpers | Estados |
|---|---|---|---|---|
| `Stats` (Frame izq-centro, 230px) | 37 | monedas (26pt oro), perlas (Rare), mochila usado/capacidad, zona (+privada) | UI.create, UI.label x4 | se rellena en `refresh(state)` (l.~300); textos `hud.coins/pearls/bag/zone_private` |
| `Events` (TextLabel pildora arriba-centro) | 82 | eventos activos con cuenta atras (1 linea por evento) | UI.label, UI.formatDuration | oculto si no hay eventos; refresco cada 1 s |
| `ActionBar` (Frame abajo, UIScale 0.82->1) | 112 | contenedor de los 2 botones | UI.create | - |
| `ActionButton` (62%) | 130 | LANZAR / RECOGER (`hud.cast`/`hud.reel`), 26pt | UI.button | color accent -> positive al lanzar; texto segun `minigame.isCasting()` |
| `SellButton` (36%) | 141 | VENDER o "Vender (n)" (`hud.sell`/`hud.sell_count`) | UI.button colorName positive | `Visible=false` mientras se pesca |
| `Menu` (ScrollingFrame der., 160px, 62% alto) | 172 | 6 botones + Auto | UI.button (row), UIListLayout | LayoutOrder 1..6 = shop, rods, bestiary, season, odds, codes; 7 = Auto |
| boton Auto (sin Name, LayoutOrder 7) | 205 | `hud.auto_on/off` | UI.button | `Visible = state.passes.auto_fish` |
| `Hint` (TextLabel FTUE) + `HintStroke` | 226 | guia del tutorial (`hint.*`) | UI.label | oculto fuera de FTUE; el UIStroke se re-parenta al boton objetivo (cast/sell/rods/bestiary) |

### Menus (`G/Menus.luau`)
Todos via `UI.panel` (`UI:446`): Frame `<name>` 92%x86% (max 560x720), hijos `Title`, `Content` (ScrollingFrame + UIListLayout), `Close` (boton 56px, abajo). Solo UN panel abierto (`current`); pulsar el mismo menu lo cierra. `openPanel` (l.114) = UIScale 0.92->1 Back 0.22 s; se redibuja en cada update del `store` (borra y reconstruye `Content`).
| Panel (Name) | Linea | Contenido | Estados de boton |
|---|---|---|---|
| `RodsPanel` | 137 | canas (stats), zonas (viajar/desbloquear), mochila (ampliar con perlas), VIP diario | Equipada (off) / Equipar / Comprar (off si monedas < precio); Aqui / Viajar / Desbloquear; Ampliar off si maxed o sin perlas; VIP Reclamar/Reclamado |
| `BestiaryPanel` | 260 | contador, criaturas por zona (color de rareza, "???" si no hallada), premios | Reclamar / Reclamado / Aun no (off) |
| `SeasonPanel` | 326 | nombre, puntos + tiempo, tarjeta de pase premium, tiers (2 botones libre/premium) | off si no alcanzado, ya reclamado, o premium sin pase |
| `CodesPanel` | 403 | intro, TextBox `CodeBox` (56px), boton Canjear | - |
| `OddsPanel` | 443 (+`UI:577`) | pestanas de zona `ZoneTabs`, desglose de suerte, filas `Odds_<id>`, total, redondeo, pity | pestana activa = accent; se reabre si cambia la suerte |
| `ShopPanel` | 541 (+`UI:540`) | nota + filas `pass_<key>` / `product_<key>` (nombre, descripcion, precio, boton) | Ver compra / Ya lo tienes (off) / No disponible... (off); `Offers` llega async (`onOffers`) |

Helpers locales: `addHeader` (l.61), `addRow` (l.72: Frame row + corner + stroke water + label x2 + UI.button por boton).

### Minijuego (`G/Minigame.luau`)
| Elemento | Linea | Notas |
|---|---|---|
| `Minigame` (Frame 86%x84px, 42% alto, oculto) | 37 | visible solo al picar; titulo (`hint.bite`) |
| `Bar` > `SweetSpot` + `Marker` | 58-81 | SweetSpot = zona perfecta (payload); Marker se mueve cada `RenderStepped` (l.239) con `rules:markerPosition` |
| Mundo 3D: corcho `Bobber`, salpicadura (`splashAt`), "!" BillboardGui | 97-193 | fuera del rediseno GUI, comparte timing |
| Atajo ESPACIO/ButtonA (`FF_Action`) | 274 | no tocar |

### Feedback (`G/Feedback.luau`)
| Elemento | Linea | Notas |
|---|---|---|
| Toast (`UI.toast`, `UI:652`) Name `Toast` | 61 | abajo (1,-130), 80% ancho, se destruye a los `seconds` (3.5) via `env.task.delay` |
| `CatchCard` | 71 | arriba 12%; lineas: nombre, rareza, valor, "Nuevo", "autovendido"; borde color rareza; max 1; 3 s |
| `CatchSparkle` (hasta 12 Frames, tope 20) | 27 | solo Rare+ |
| `MythicBanner` (TextLabel) | 165 | banner global, `balance.mythicBanner.displaySeconds` |

### Paquete UI
Tema `UI.theme` (l.82): colores crudos RGB (background, panel, row, text, textMuted, accent, accentText, disabled, positive, water, wood, gold, coral + 6 rarezas), `minTouchHeight=56`, textSize 18, titleSize 24, corner 12, padding 12.
Componentes: `UI.create` (297), `UI.label` (366), `UI.button` (395: TextButton + UICorner + `Sheen` Frame + UIStroke; NO usar UIGradient en TextButton, tine la letra), `UI.panel` (446), `UI.shopPanel` (540), `UI.oddsPanel` (577), `UI.toast` (652). Utilidades: `formatNumber/formatDuration/priceText/reasonText/buyButtonText/rarityColorName`.
Fuente unica: GothamBold / GothamMedium. Sin imagenes ni iconos hoy (solo texto).

## Lo que las pruebas exigen (no romper)
`ClientBoot.spec.luau` ejecuta el `Main.client` real con instancias falsas validadas por la base de reflexion de Lune (propiedad y tipo validos, no efecto visual).
- `ScreenGui` con `Name=="FishFortune"` y `ResetOnSpawn==false`; `FF_Action` ligado a ContextActionService.
- Nombres exactos: `Menu` (hijos directos `TextButton`; los 6 primeros por `LayoutOrder` = shop, rods, bestiary, season, odds, codes; se pulsan con `Activated`), `ActionButton`, `SellButton` (su `.Text` debe cambiar entre ES y EN), `Minigame` (`.Visible==true` tras CastStarted), `CatchCard` (exactamente 1 tras Catch), `Close` (dentro del panel, con Activated).
- Paneles: Frame con Name terminado en `Panel` (regex `Panel$`); tras abrir un menu debe haber EXACTAMENTE 1, tras `Close` 0; un nuevo `State` no debe duplicarlo. Ninguna otra Frame puede llamarse `*Panel`.
- Filas de tienda: nombres `pass_*` o `product_*` (>0 tras `Offers`).
- HUD: al menos 4 `TextLabel`, y alguno con "250" (monedas compactadas) tras `State`.
- Eventos de fachada admitidos: Activated, FocusLost, Changed, MouseButton1Click. Evitar `InputBegan`, `MouseEnter`, etc. sin anadirlos al arnes.
- Servicios del arnes: Players, Workspace, TweenService (`Create` devuelve solo `{Play, Cancel}`: SIN `Completed`, `Pause`, `Destroy`), RunService (SOLO `RenderStepped`, sin `Heartbeat`), ContextActionService, LocalizationService, ReplicatedStorage. Pedir otro (UserInputService, GuiService, SoundService, HapticService) hace FALLAR el arranque: anadirlo al arnes. `TweenInfo.new` devuelve `{}`. Globals OK: Enum, Vector2/3, Color3, CFrame, UDim(2), ColorSequence, NumberSequence, NumberRange, task, os.clock. NO existen `NumberSequenceKeypoint`, `ColorSequenceKeypoint`, `Rect`, `Font`, `TextService` (anadir si se usan).
- Toda clase de `Instance.new/UI.create` debe ser creable por Lune y toda propiedad existir en su base (UIScale.Scale, UIGradient.Rotation, ImageLabel.Image ok; propiedades muy nuevas pueden fallar).
- `tests/UI.spec.luau`: `UI.toast(parent,text,2)` anade 1 hijo con `.Text=="Hola"` y lo destruye al avanzar el reloj 3 s (debe seguir siendo TextLabel con `.Text` y destruirse por `env.task.delay`); botones de panel `TextButton` con `Size.Y.Offset >= 56` (tienda: >=4 botones); textos exactos "Ver compra", "Ya lo tienes", "No disponible en tu region"; boton no disponible: `Active==false`; filas `pass_`/`product_` (3); filas `Odds_*` (3) y textos "Total: 100.00%", "(base " (solo con suerte), "suerte activa", "Garantia cada 20 lanzamientos."; funciones puras formatNumber/formatDuration/priceText/buyButtonText/reasonText/rarityColorName.
- `Strings.spec`: toda clave `["ui.*"]` de UI.luau y toda `L("...")` nueva debe existir en `Strings.luau` (ES+EN); `UI.priceText/buyButtonText` se prueban en ambos idiomas.
- `ProjectStructure.spec`: el cliente solo requiere modulos replicados; los remotos `net:onEvent("X")` / `net:fire("X")` se escanean por regex (no cambiar esas llamadas). Modulos esperados: Feedback, Hud, Menus, Minigame (ModuleScript).

## 2. Animaciones actuales (TweenService)
| Donde | Que | Params |
|---|---|---|
| Hud:119 | `ActionBar` UIScale 0.82->1 al cargar | 0.3 s Back Out |
| Hud:150-165 | squash al pulsar ActionButton/SellButton: UIScale 0.94 y vuelta a 1 | 0.08 Quad Out + 0.16 Back Out (`task.delay`) |
| Hud:221 | `HintStroke.Transparency` ->0.7, pulso infinito | 0.6 Sine InOut, -1, reverse |
| Menus:117 | panel UIScale 0.92->1 al abrir (sin animacion de cierre) | 0.22 Back Out |
| Minigame:128 | anillo 3D de salpicadura | 0.9 Quad Out |
| Minigame:187 | corcho sube/baja (3D) | 0.6 Sine InOut infinito |
| Minigame:248 | Marker: posicion cada RenderStepped (unico trabajo por fotograma) | - |
| Feedback:47 | `CatchSparkle` sube y se desvanece | 0.35 Quad Out |
| Feedback:65 | toast fade-in (Text/BackgroundTransparency); sin fade-out | 0.2 Quad Out |
| Feedback:148/154 | CatchCard: flash oro->panel (Rare+) y cae desde y=-160 | 0.22 Quad / 0.25 Back Out |
| Feedback:191 | MythicBanner baja de y=-80 a 8; se destruye sin salida | 0.35 Quad Out |

Faltan: contador de monedas sin animacion, sin feedback al cambiar valores, sin cierre animado, nada en Odds/Shop/filas.

## 3. Animaciones propuestas
Reglas: solo TweenService + UIScale/UIStroke/UIGradient (UIGradient NO en TextButton). Un helper central `UI.motion.tween(inst, props, dur, style)` que cancela el tween previo de esa instancia y respeta `UI.motion.reduced`. Con movimiento reducido: duracion 0, sin bucles ni parpadeo. Maximo ~3 bucles a la vez. Esperar con `task.delay`, no con `Completed` (el arnes no lo tiene).
| Elemento | Disparador | Propiedad | Duracion / easing |
|---|---|---|---|
| Contador monedas/perlas (`Stats`) | cambia el valor en `refresh` | cuenta hacia arriba del valor mostrado (max 12 pasos con `task.delay`, o NumberValue) | 0.5 s Quad Out |
| Pop del contador | sube el valor | UIScale 1->1.18->1, texto oro; si baja (compra) flash coral | 0.12 Back Out + 0.14 Quad |
| Mochila llena | `inventoryCount >= capacity` | UIStroke de `Stats` a coral con pulso, solo mientras este llena | 0.5 s Sine bucle |
| Todos los botones (`UI.button`) | Activated | UIScale 0.94 y 1 (mover el squash de Hud a `UI.button`) | 0.07 Quad Out + 0.16 Back Out |
| Boton deshabilitado | pulsar | shake horizontal 6 px | 0.18 s Quad |
| ActionButton | lista / lanzando | color accent<->positive con tween; pulso UIScale 1->1.04 esperando la picada | 0.2 s Quad; 0.8 s Sine bucle |
| `Menu` (botones der.) | al cargar | entrada escalonada: desliza desde x +40 con fade, 40 ms entre botones | 0.25 s Back Out |
| `Stats` | al cargar | desliza desde la izquierda | 0.3 s Back Out |
| Paneles (UI.panel) abrir | abrir | UIScale 0.9->1 + fade del fondo + velo oscuro detras (Frame negro 0.5) | 0.22 s Back Out |
| Paneles cerrar | cerrar | UIScale 1->0.94 + fade, luego Destroy tras `task.delay` | 0.14 s Quad In |
| Filas (Rods/Bestiary/Season/Shop) | primera apertura | aparicion escalonada (max 8 filas, 30 ms); NO animar en redibujos por `State` | 0.18 s Quad Out |
| Fila comprada/reclamada | boton pasa a Equipada/Reclamado | flash verde del UIStroke + check con pop | 0.25 s |
| Pestanas Odds | cambio de zona | color accent con tween | 0.15 s |
| Toast | aparece / sale | desliza 30 px desde abajo + fade-in; sale con fade-out + baja y Destroy. Mantener TextLabel `.Text` y Destroy por `env.task.delay` (test) | 0.2 s Back Out / 0.2 s Quad In |
| `Minigame` barra | CastStarted | desliza + UIScale 0.9->1 | 0.2 s Back Out |
| `SweetSpot` | barra activa | UIStroke/brillo pulsa transparencia 0.2<->0.6 | 0.5 s Sine bucle |
| `Marker` | cerca del SweetSpot | UIScale 1->1.25 evaluado en el mismo RenderStepped (sin tween extra) | instantaneo |
| Resultado minijuego | perfecto / fallo | perfecto: flash del SweetSpot + texto "PERFECTO" con pop; fallo: shake 6 px del `Bar` | 0.25 s |
| Espera de picada | antes de la picada | titulo con "..." cada 0.4 s o barra fina que se llena | 0.4 s paso |
| `CatchCard` (reveal) | Catch | cae con Back; icono del pez escala 0->1 con rebote; Epic+ aro de luz con UIGradient.Rotation 0->360 lento; Common sin extras | 0.3 s Back Out; gradiente 2 s lineal |
| Reveal raro (Rare+) | Catch | destello de pantalla (Frame blanco 0.6->1) + estrellas (reusar `sparkle`, tope 20); Legendary/Mythic: sacudida corta + sonido | 0.3 s; Mythic hasta 0.6 s |
| Etiqueta "Nuevo" | `isNew` | pop con rotacion -6 grados | 0.2 s Back Out |
| `MythicBanner` | Banner | baja con Back, brillo UIGradient.Offset -1->1, sale subiendo | 0.35 s; 1.2 s barrido |
| `Events` (pildora) | aparece/desaparece | fade + deslizar 12 px | 0.2 s |
| `Hint` FTUE | cambia de objetivo | pulso del stroke (ya existe) + flecha/dedo que rebota sobre el boton (Position y +-6) | 0.5 s Sine bucle |

Rendimiento: ningun `RenderStepped` nuevo (el del Marker ya existe); reusar el `task.spawn` de 1 s para tiempos; destruir los Frames temporales; no animar `Size` de filas dentro de ScrollingFrame (usar UIScale del contenedor o transparencia).

## 4. Iconos que necesita el HUD nuevo
Hoy no hay ninguno (todo es texto). Set coherente, PNG transparente 128x128 (subir a Roblox requiere permiso del usuario):
- Estado: moneda, perla, mochila (capacidad), zona/ubicacion, reloj/evento, flecha-dedo del tutorial.
- Accion: cana (lanzar), carrete (recoger), bolsa de monedas (vender), auto-pesca (on/off).
- Menus (6): tienda (bolsa/carrito), canas, bestiario (libro/pez), temporada (trofeo/estrella), probabilidades (dado o %), codigos (regalo/ticket).
- Paneles: cerrar (X), candado, check (comprado/reclamado), regalo (reclamar), Robux (precio), flecha de viaje, corona VIP, trebol (suerte).
- Minijuego/feedback: "!" de picada, estrella ("Nuevo"/rareza), marcos de rareza x6 (Common a Mythic, colores de `UI.theme`), pez generico para `CatchCard` y silueta "???" del bestiario.
