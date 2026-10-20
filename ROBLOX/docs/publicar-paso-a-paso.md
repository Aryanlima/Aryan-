# Publicar Fish & Fortune paso a paso (con puertas y marcha atrás)

Fecha: 2026-10-20. Para Aryan (no hace falta saber programar) y para las dos sesiones de Claude.
Investigación detrás de cada paso, con fuentes: [`pc-investigacion/verificacion-pases-y-publicacion.md`](pc-investigacion/verificacion-pases-y-publicacion.md).
El mensaje listo para pegar en la sesión del PC (Etapas 0 a 3): [`prompt-pc-mision-2.md`](prompt-pc-mision-2.md).

> **Regla de oro.** Hasta la Etapa 5 **nada es público y no se gasta nada**. Ni la nube ni la sesión del PC hacen público el juego, pagan, tocan tu verificación de identidad ni tus formularios fiscales, ni guardan claves en archivos o en el chat. **Lo público y lo que cuesta dinero lo haces tú, con tus manos, y solo cuando lo confirmes en ese momento.**

Quién hace qué: **[NUBE]** sesión de la nube (código, herramientas, pruebas) · **[PC]** sesión del PC (Studio, Rojo, clics en Creator Hub con tu permiso) · **[ARYAN]** solo tú.

---

## Mapa

| Etapa | Qué pasa | ¿Público? | ¿Cuesta Robux/dinero? | Quién | Puerta para pasar a la siguiente |
|---|---|---|---|---|---|
| **0** | Playtest en Studio **sin compras** | No | No | [PC] | `docs/playtest-1.md` sin fallos graves; los FALLA los arregla la nube |
| **1** | Experiencia de **prueba PRIVADA** | **No (solo tú)** | No | [PC] + [ARYAN] | Se comprueba que es **privada** y que el lugar está guardado |
| **2** | Crear pases y productos (**fuera de venta**) y copiar sus IDs | No | No | [PC] + [ARYAN] (clave) | Los 11 objetos existen y coinciden con `store-items.json` |
| **3** | Cablear los IDs, comprobar, y probar compras **sin confirmar ninguna** | No | No | [PC] | `wire-ids` verde + verificación de solo lectura + `TargetId` resuelto + commit en `pc/aryan-local` |
| **3b** | *(Opcional)* una compra real mínima de 49 R$ | No | **Sí, tus Robux** | [ARYAN] decide | Solo con tu OK explícito en ese momento |
| **4** | *(Opcional)* Prueba con amigos | No (invitados) | Podrían gastar los suyos | [ARYAN] decide | Solo con tu OK explícito en ese momento |
| **5** | **PÚBLICO** | **Sí** | Posible (tarifa 1.000 R$ o Plus) | **[ARYAN]** | Lista de verificación final completa |

Las etapas 0 a 3 las encadena la sesión del PC sola con el mensaje de `prompt-pc-mision-2.md`. Las 3b, 4 y 5 **no** las ejecuta nadie sin tu orden.

---

## El archivo de IDs (`ids.local.json`) y las herramientas

Lo único que se rellena a mano (o lo rellena `create-items.mjs`) es `ROBLOX/games/fish-and-fortune/ids.local.json`. Se parte de `ids.example.json` (copiarlo con ese nombre). **Los IDs de pases no son secretos y este archivo SÍ se versiona.**

```json
{
  "universeId": 1234567890,
  "passes": {
    "auto_fish": 1111111111, "double_coins": 1111111112, "luck_plus": 0,
    "starter": 1111111113, "vip": 1111111114, "season_pass": 1111111115
  },
  "products": {
    "lucky_bait_15": 0, "coin_boost_15": 2222222221, "coin_pack_small": 2222222222,
    "coin_pack_medium": 2222222223, "coin_pack_large": 2222222224,
    "pearl_pack": 2222222225, "slot_pack": 2222222226
  }
}
```

- **Mismas claves que `ProductIds.luau`** (si falta una o sobra una, falla diciendo cuál y, si es un error de tecleo, sugiere la correcta).
- Cada valor es **solo el número** del ID (un entero; también vale entre comillas). Nada de URL, espacios, letras, decimales ni negativos.
- **`luck_plus` y `lucky_bait_15` se quedan en 0**: la suerte de pago está **apagada a propósito** en la v1 (`FeatureFlags.paidLuckEnabled = false`). **No los crees en Creator Hub** (un recibo de un producto apagado queda sin resolver para siempre, hallazgo SHOP-03). Si les pones un ID, la herramienta lo rechaza.
- Un pase puede escribirse `{ "passId": 111, "assetId": 222 }` **solo** si la prueba de Studio de la Etapa 3 demuestra que su `TargetId` y su `assetId` son distintos (ver "TargetId o assetId" abajo).
- `universeId` (opcional) es informativo. Las claves que empiezan por `_` son comentarios.

**Herramientas** (todas con salida en español, sin rutas del equipo, sin claves en archivos):

| Herramienta | Para qué | Seguro por defecto |
|---|---|---|
| `node ROBLOX/tools/wire-ids.mjs --dry-run` | Valida `ids.local.json` y muestra los cambios en `ProductIds.luau` | No escribe nada |
| `node ROBLOX/tools/wire-ids.mjs` | Valida, reescribe `ProductIds.luau`, comprueba el formato y corre la **puerta** (`FF_RELEASE_CHECK=1 bash ROBLOX/tools/test.sh`) | Si la puerta falla, **restaura** el archivo anterior |
| `node ROBLOX/tools/wire-ids.mjs --emit-verify-luau` | Imprime un script de Studio de **solo lectura** que consulta cada ID | No compra nada |
| `node ROBLOX/tools/create-items.mjs --universe <ID>` | Plan de lo que se crearía en Creator Hub (**BETA**, API Open Cloud) | Sin `--apply` no usa la red |
| `node ROBLOX/tools/publish-place.mjs --universe <U> --place <P>` | Sube el lugar a la experiencia **privada** | Sin `--apply` no hace nada; **se niega si la experiencia no es privada** |
| `lune run ROBLOX/tools/dump-store-items.luau` | Regenera `store-items.json` (nombres, precios e íconos de los 11 objetos) | Lo vigila una prueba |

`wire-ids.mjs` rechaza: IDs en 0 en objetos **habilitados**, IDs repetidos (en cualquier par de sitios), negativos, decimales, texto, URL, claves que faltan o sobran, e IDs en los objetos apagados. Códigos de salida: 0 bien · 1 datos inválidos o la puerta falló · 2 uso incorrecto. Con `ids.example.json` (todo en 0) **falla a propósito**, diciendo qué falta.

---

## Etapa 0: Playtest sin compras  [PC]

**Qué:** el primer recorrido del juego en Studio (tutorial, pesca, venta, bestiario, probabilidades, nada de suerte comprable) **sin comprar nada**. Ya está escrito: [`prompt-pc-playtest-1.md`](prompt-pc-playtest-1.md) → informe `docs/playtest-1.md`. **No se repite aquí.**

**Puerta:** `docs/playtest-1.md` existe y no tiene FALLA en arranque, tienda ni datos; los FALLA los corrige la nube antes de seguir. Tú decides si lo que queda es aceptable.

**Cómo deshacer:** nada que deshacer (no se publicó nada; Studio con el almacén de datos en memoria).

---

## Etapa 1: Experiencia de prueba PRIVADA  [PC + ARYAN]

**Qué:** un "juego de pruebas" que solo ves tú. Sirve para crear los pases/productos (Roblox exige que la experiencia esté publicada) y para probar con IDs reales.

**Pasos (en Studio, con tu sesión iniciada):**
1. Abrir un lugar vacío (plantilla Baseplate). **No** usar un lugar de producción.
2. **File → Publish.** Se abre la ventana **Game details**: ponle nombre `FF Pruebas (privado)`, género y descripción cortos, y **Save**. Eso crea la experiencia con su **Universe ID**. Por defecto es **solo para ti y quienes tengan acceso de edición** (documentación oficial de publicación).
3. **Parar aquí.** Si Studio abre otra ventana con **Invite / Continue** o con preguntas del cuestionario de madurez, es el flujo de hacerla **pública**: **no pulses Continue, ni Publish, ni respondas nada**; ciérrala. (Ver "Cómo deshacer".)
4. Copiar el **Universe ID** (Creator Hub → Creations → ⋯ de la miniatura → *Copy Universe ID*) y el **Place ID** (la experiencia → pestaña *Places* → el lugar; está en la URL `.../places/{PlaceID}/configure`).
5. Comprobar que es **privada**: en Creator Hub la experiencia no debe mostrar "Public" ni tener "Manage Audience" en público. Captura de pantalla como evidencia.
6. Cargar el juego: `rojo serve ROBLOX/games/fish-and-fortune/default.project.json` y conectar el plugin en ese lugar. Guardar con Studio **sin abrir la ventana de madurez**; si no está claro cómo, usar `publish-place.mjs` (necesita la clave de la Etapa 2).

**Puerta:** la experiencia aparece como **privada** en Creator Hub y se anotaron Universe ID y Place ID.

**Cómo deshacer:** una experiencia privada no la ve nadie. Para quitarla de en medio: Creator Hub → ⋯ → archivar/ocultar si aparece esa opción [no verificado]; si no, dejarla. **No se borra nada importante** porque no hay jugadores ni dinero.

---

## Etapa 2: Crear pases y productos (reversible)  [PC + ARYAN]

**Los 11 objetos a crear** (de `store-items.json`, que sale del código; **no** crear Suerte+ ni Cebo de Suerte). Nombre en inglés (idioma por defecto del juego) con su traducción al español luego, en Creator Hub → Localization. Íconos ya hechos en `ROBLOX/marketing/fish-and-fortune/assets/`.

| Tipo | Clave | Nombre (EN) | Precio sugerido (R$) | Ícono |
|---|---|---|---:|---|
| Pase | `auto_fish` | Auto-Fishing Pass | 299 | `passes/auto_fish.png` |
| Pase | `double_coins` | 2x Coins Pass | 249 | `passes/double_coins.png` |
| Pase | `starter` | Starter Pack | 99 | `passes/starter.png` |
| Pase | `vip` | VIP Pass | 199 | `passes/vip.png` |
| Pase | `season_pass` | Season 1 Pass | 399 | `passes/season_pass.png` |
| Producto | `coin_boost_15` | Coin Boost (15 min) | 49 | `products/coin_boost_15.png` |
| Producto | `coin_pack_small` | Small Coin Pack | 99 | `products/coin_pack_small.png` |
| Producto | `coin_pack_medium` | Medium Coin Pack | 499 | `products/coin_pack_medium.png` |
| Producto | `coin_pack_large` | Large Coin Pack | 1.999 | `products/coin_pack_large.png` |
| Producto | `pearl_pack` | Pearl Pack | 199 | `products/pearl_pack.png` |
| Producto | `slot_pack` | More Space (+10) | 99 | `products/slot_pack.png` |

Las descripciones exactas (EN y ES) están en `store-items.json`. Los precios son hipótesis de la escalera del juego, no datos de mercado.

**Camino A, por API (menos clics, BETA):**
1. **[ARYAN]** Crea una clave de API (Creator Hub → *API Keys* → *Create API Key*) con **solo** estos permisos, **limitada a la experiencia de prueba** y con caducidad corta (7 días): *Game Passes* lectura+escritura, *Developer Products* lectura+escritura, *Place Publishing (universe-places)* escritura y, si aparece, lectura de la experiencia. La pegas **tú** en una variable de entorno de Windows llamada `ROBLOX_API_KEY` (Panel de control → "Editar las variables de entorno de esta cuenta" → Nueva) y abres una terminal nueva. **Nunca** en un archivo, ni en el chat, ni en un comando que se vea.
2. **[PC]** `node ROBLOX/tools/create-items.mjs --universe <ID>` (muestra el plan; revisarlo) y luego `... --apply`. Crea los 11 **fuera de venta**, no duplica si se repite y guarda los IDs en `ids.local.json`.

**Camino B, a mano (plan B si la API falla o la interfaz difiere):** Creator Hub → la experiencia → **Monetization → Passes → Create pass** (ícono, nombre, descripción, categoría, precio); **Monetization → Developer Products → Create developer product** (ícono, nombre, descripción, categoría, precio). Copiar cada ID con **⋯ → Copy Asset ID** al archivo `ids.local.json`. **No marcar nada como "Listed"** (Monetization → Shop): eso los saca a la tienda de Roblox fuera del juego.

**Puerta:** los 11 existen, con nombre y precio como en la tabla, y todos **fuera de venta o sin Listed**. `ids.local.json` completo.

**Cómo deshacer:** borrar cada objeto en Creator Hub (no hay endpoint de borrado); revocar la clave de API en Creator Hub y borrar la variable `ROBLOX_API_KEY`. No hay dinero involucrado porque nadie puede comprar nada.

---

## Etapa 3: Cablear los IDs y probar sin gastar  [PC]

### 3.1 Cablear
1. `node ROBLOX/tools/wire-ids.mjs --dry-run` → revisar el resumen "antes → después" (11 cambios; `luck_plus` y `lucky_bait_15` siguen en 0 "apagado a propósito").
2. `node ROBLOX/tools/wire-ids.mjs` → escribe `ProductIds.luau`, comprueba el formato y corre la **puerta previa a publicar**. Debe terminar con `PUERTA OK`. La puerta ejecuta el servidor real con los IDs reales (prompts, recibos, pases) en el entorno de pruebas.
3. `git diff ROBLOX/games/fish-and-fortune/src/server/ProductIds.luau` y commit en la rama `pc/aryan-local`.

### 3.2 Verificar contra Roblox, solo lectura
`node ROBLOX/tools/wire-ids.mjs --emit-verify-luau` imprime un script. Se ejecuta en Studio con la experiencia de prueba (herramienta `execute_luau`, datamodel *Edit*): consulta cada ID con `GetProductInfoAsync` y marca `OK` o `REVISAR` (nombre distinto, precio distinto, no a la venta, `TargetId` distinto). **No compra ni escribe.** Si `GetProductInfoAsync` exige que el objeto esté a la venta o falla en Edit, se pasa a Play.

### 3.3 TargetId o assetId (la duda abierta)
La documentación de Roblox se contradice sobre el ID de un pase (ver investigación §4). La prueba:
1. Para cada pase, comparar `Copy Asset ID` con el `TargetId` que informa el script del paso 3.2.
2. **Caso A (esperado):** iguales → nada más.
3. **Caso B:** distintos → en `ids.local.json`: `"vip": { "passId": <TargetId>, "assetId": <el de Copy Asset ID> }` y repetir 3.1. El juego ya sabe usar `passId` para el diálogo y la propiedad y acepta el otro como alias.
4. Abrir el diálogo de **un** pase desde el juego en playtest y **cancelarlo**: debe mostrar el pase correcto; en la salida no debe salir `PromptGamePassPurchaseFinished con un ID de pase DESCONOCIDO`.
5. **Si el diálogo solo funciona con el otro ID: PARAR y reportar.** Es el caso que contradice dos páginas oficiales; no se parchea a ciegas con dinero.

### 3.4 Probar el diálogo de compra **sin confirmar**
Poner los objetos a la venta solo si la experiencia es privada (`create-items.mjs --apply --for-sale` lo comprueba por API; a mano, confirmar en Creator Hub). En el playtest: abrir la tienda del juego, pulsar un pase y un producto, mirar nombre y precio del diálogo oficial y **Cancelar**. **Nunca** pulsar el botón de comprar. Idealmente la cuenta de pruebas tiene **0 Robux**; si tiene saldo, [ARYAN] decide. Resultado esperado en el juego: `PromptGamePassPurchaseFinished` con `wasPurchased = false` y nada concedido.

### Etapa 3b (opcional, cuesta Robux): una compra real mínima  [ARYAN decide]
Es la **única** prueba que ejercita el recibo de verdad (diálogo → `ProcessReceipt` → guardado → concesión → re-entrega). Cuesta Robux reales de la cuenta que compra (el más barato: `coin_boost_15`, **49 R$**); parte de lo que pagas se la queda Roblox como comisión (ver `research/02`). **No hay forma documentada de hacerla gratis en Studio** (hay reportes contradictorios; ver investigación §3). Solo si tú lo ordenas en ese momento, con la cuenta y el producto que tú elijas, y con el juego aún privado.

**Puerta a la Etapa 4 / 5:** `wire-ids` verde; verificación de solo lectura sin `REVISAR` (o explicados); `TargetId` resuelto; diálogos cancelados sin compra; commit hecho; `docs/mision-2-informe.md` completo.

**Cómo deshacer:** `git checkout -- ROBLOX/games/fish-and-fortune/src/server/ProductIds.luau` vuelve a todos los IDs en 0 (el juego los oculta de la tienda y no rompe nada). `wire-ids` ya restaura solo si la puerta falla. Poner objetos fuera de venta: `PATCH isForSale=false` o el interruptor en Creator Hub.

---

## Etapa 4 (OPCIONAL): Prueba con amigos  [requiere OK explícito de Aryan en ese momento]

Solo si tú lo decides. Invita a personas concretas, con la experiencia **todavía privada**:
1. Studio → **File → Invite early testers** (hasta 10 amigos de edad parecida a la tuya; reglas de edad en la documentación). Reciben una vista previa con una marca de agua; las herramientas de seguridad y reporte siguen activas.
2. Que el juego esté subido con `publish-place.mjs --apply --publish` (versión *Published*, solo visible para ti y tus testers).
3. Avisa a tus amigos: **las compras cuestan Robux reales y no son necesarias**; que no compren. Los objetos pueden seguir fuera de venta.
4. Pide: tutorial ≤ 60 s, errores, si entienden la tienda y las probabilidades.

**Cómo deshacer:** *Manage Collaborators* (arriba a la derecha en Studio) → quitar a los testers. Nada se hizo público.

---

## Etapa 5: PÚBLICO  [solo ARYAN, con confirmación explícita en ese momento]

> Nadie más que tú pulsa "publicar". La sesión del PC solo te guía si se lo pides ese día.

### Decisiones y pagos que son SOLO tuyos
| Decisión | Detalle | Fuente |
|---|---|---|
| **Audiencia** | Solo 16+ (gratis, etiqueta *Content May Vary*) o todas las edades | `publish-games-and-places.md` |
| **Tarifa 1.000 Robux** (o Plus/Premium 2 meses seguidos) | Para llegar a menores de 16. Reembolsable según una página; **las dos páginas oficiales se contradicen** (90 días tras ser elegible / 25 jugadores en 60 días): no contar con ella | `kids-and-select.md` |
| **Verificación de identidad / edad** | Estimación facial si eres menor de 18; documento si tienes 18 o más. Más 2FA | `publish-games-and-places.md` |
| **Formulario fiscal W-8BEN** (o W-8BEN-E) | Creator Hub → Finances → Taxes. **Antes del 31-oct-2026** si quieres cobrar con retención correcta; sin él puede aplicarse 24 % a todo el pago. Independiente de publicar, pero **urgente** | `tax-information.md` |
| **Cuestionario de madurez veraz** | Se contesta pensando en lo más maduro que puede ver un jugador. Datos falsos → moderación del juego **y de tu cuenta** | `content-maturity.md` |
| **¿"Listed"?** | Si los pases/productos salen en la tienda de Roblox fuera del juego | `passes.md` |
| **Crear/ revocar la clave de API** | Es tu cuenta | `api-keys.md` |
| **DevEx** | Se podrá cobrar a partir de 30.000 Robux ganados (0,0038 USD cada uno) | `research/02` |

### Lista de verificación final (marcar todo antes de publicar)
- [ ] Etapas 0 a 3 hechas y sus informes (`playtest-1.md`, `mision-2-informe.md`) leídos por ti.
- [ ] `FF_RELEASE_CHECK=1 bash ROBLOX/tools/test.sh` verde, `lint.sh` y `format.sh --check` verdes, **sin IDs en 0** salvo Suerte+ y Cebo.
- [ ] `FeatureFlags.paidLuckEnabled = false` y **no existe** en Creator Hub ni Suerte+ ni Cebo de Suerte.
- [ ] Todo lo marcado `REVIEW(money)` leído por **una persona** (`docs/revision-codigo-dinero.md` §7). Pendientes: DATA-01, MINI-01, CONFIG-01.
- [ ] Nombres, descripciones, íconos y miniaturas finales (no los de prueba); traducciones de pases/productos en Creator Hub.
- [ ] Panel **Probabilidades** visible y suma 100 %; nada de lenguaje de presión (lo comprueban las pruebas); descuentos y temporizadores reales (no hay).
- [ ] Cuestionario de madurez respondido **tú mismo y con la verdad**. Para la v1: sin apuestas jugables, sin objetos aleatorios de pago, sin chat propio, sin IA, sin comercio.
- [ ] Audiencia decidida (16+ o todas las edades) y, si es el caso, tarifa/Plus resuelta por ti.
- [ ] Verificación de edad hecha (cuenta con 2+ días de antigüedad) y 2FA activada.
- [ ] W-8BEN presentado.
- [ ] Copia local del `.rbxl` y de los IDs (versionados).
- [ ] Máximo 5 juegos nuevos por día (aquí es 1).
- [ ] Entendido que **cada actualización futura vuelve a pasar por los requisitos de publicación** (documentación oficial).

### Cómo se hace
Lo haces tú en Studio (*File → Publish* → seguir la ventana) o en Creator Hub (*Publish settings → Manage Audience*), leyendo cada pantalla. Después: poner los objetos a la venta si estaban fuera de venta, decidir "Listed", y **revisar Creator Hub el primer día** (panel de seguridad, errores, compras).

**Cómo deshacer lo público:** Creator Hub → la experiencia → **Publish settings → Manage Audience → Manage access** y quitar el acceso público ("revocar el acceso público"; no cuenta para el tope de 5 por día) o *Restart servers* tras revocar para sacar a los jugadores [`update-games.md`]. Lo ya comprado por jugadores no se deshace solo: hay que gestionarlo con Roblox.

---

## Cómo deshacer cada etapa (resumen)

| Etapa | Marcha atrás |
|---|---|
| 0 | Nada que deshacer |
| 1 | La experiencia es privada: se puede dejar o archivar. Si por error se abrió la ventana de publicar: **cerrarla sin pulsar nada** |
| 2 | Borrar los 11 objetos en Creator Hub; revocar la clave de API y borrar la variable `ROBLOX_API_KEY` |
| 3 | `git checkout -- .../ProductIds.luau` (todos en 0); objetos fuera de venta; `wire-ids` restaura solo si falla la puerta |
| 3b | Una compra real **no** se deshace desde el repo (soporte de Roblox); por eso es opcional y solo con tu OK |
| 4 | Quitar testers (*Manage Collaborators*) |
| 5 | Revocar el acceso público (*Manage Audience*), reiniciar servidores; los reembolsos van por soporte de Roblox |

---

## Si algo falla

| Síntoma | Qué hacer |
|---|---|
| `wire-ids` dice `ID 0 ... HABILITADO` | Falta crear ese objeto o pegar su ID en `ids.local.json` |
| `ID repetido N: passes.a, passes.b` | Copiaste el mismo ID dos veces; vuelve a copiar el de uno de los dos |
| `... APAGADO a propósito` | No crees Suerte+ / Cebo en la v1 (déjalos en 0) |
| `LA PUERTA FALLO` | Se restauró `ProductIds.luau`. Lee las últimas 40 líneas de la salida; si es un test que no tocaste, espera y repite (otro agente edita) |
| Creator Hub no deja crear objetos en una experiencia privada | **Parar y reportar.** No se hace pública para poder crearlos |
| La interfaz de Creator Hub/Studio no coincide con lo descrito | **Parar y reportar** con una captura. No improvisar con dinero |
| `create-items`: HTTP 401/403/404/429 | 401/403: la clave o sus permisos; 404: Universe ID; 429: esperar un minuto y repetir (es idempotente) |

## Qué sigue sin verificar (se mide en estas etapas)
- Si se pueden crear pases/productos en una experiencia **privada**.
- Si la API BETA de pases/productos se comporta como su especificación (probada solo con un servidor falso).
- Si `GetProductInfoAsync` funciona dentro de `execute_luau` (Edit) y qué `TargetId` devuelve cada pase.
- Si las compras confirmadas en Studio cuestan Robux (por eso nunca se confirman).
- Qué permiso necesita exactamente `GET /cloud/v2/universes/{id}` para la comprobación de privacidad.
- Qué ventanas exactas abre *File → Publish* en la versión de Studio instalada.
