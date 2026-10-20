# Ropa y accesorios de avatar (UGC) frente a juegos con microtransacciones: informe a 2026-10-20

Área: opción (B) = vender ropa clásica 2D, ropa en capas 3D, accesorios y limiteds en el Marketplace de Roblox, comparada con (A) = juegos con microtransacciones (ver informes [01](01-mejores-juegos.md), [02](02-monetizacion-y-economia.md), [03](03-politicas-y-cumplimiento.md), [07](07-diseno-crecimiento-y-conceptos.md)). Idioma: español. Cifras en R$ (Robux) y US$ (dólares); decimales con coma.

---

## 0. Cómo leer este informe y límites del método

| Etiqueta | Significado |
|---|---|
| **[OFICIAL]** | Lo leí yo mismo en la documentación oficial de Roblox (repositorio público [Roblox/creator-docs](https://github.com/Roblox/creator-docs), commit `7400643` del 2026-10-20, y su historial git). Es el texto que Roblox publica, no un resumen de buscador. |
| **[TERCERO]** | Prensa, blogs, sitios de tendencias, resúmenes de buscador. Se indica si es débil. |
| **[DERIVADO]** | Aritmética mía sobre datos citados. Hereda su incertidumbre. |
| **[IDEA PROPIA]** | Supuesto o recomendación mía, no un dato. |
| **[NO VERIFICADO]** | Fuente única, contradictoria o no comprobable en esta sesión. |

**Qué pude y qué no pude hacer (honestidad metodológica)**

1. `create.roblox.com`, `devforum.roblox.com` y sitios de prensa dan `ENOTFOUND` en esta red (probado con WebFetch en devforum y PCGamesN; no eludí el proxy). **Sí pude clonar el repositorio oficial de documentación** (`git clone --depth 1`, luego `fetch --depth=400`), que se sincroniza desde los equipos internos de Roblox. Eso me permitió leer las páginas vigentes **y comparar versiones antes/después del 14-jul-2026** con `git show`. Es la mejor evidencia oficial disponible aquí.
2. El hilo del DevForum "Unifying 2D and 3D Avatar Item Publishing" solo lo vi como **extractos del buscador** (lo marco como tal). Lo que sí está confirmado en la documentación oficial es el resultado final (sección 2.5).
3. Gasté 12 búsquedas web (presupuesto compartido). Los datos de mercado de UGC (número de vendedores, medianas, tendencias) son de **sitios de terceros de calidad baja o media, sin fuente primaria**. **Roblox no publica ninguna cifra desglosada de pagos por ítems de avatar** (en las búsquedas solo apareció que el 10-Q lista las ventas de ítems de avatar como una de las fuentes de Earned Robux). Por eso la parte de mercado es la más débil del informe y lo digo en cada tabla.
4. Los números de la sección 4 son un **modelo con supuestos explícitos**, no una previsión. Las fórmulas están en la sección 4.2 para que puedas cambiar los supuestos.

---

## 1. Resumen ejecutivo

1. **Las reglas cambiaron el 14-jul-2026 y está confirmado en la documentación oficial** (commit [`1296aef5`](https://github.com/Roblox/creator-docs/commit/1296aef5)). La ropa clásica 2D pasó de 70 % para el creador en el Marketplace a **30 %**; dentro de un juego pasó de 60 % creador + 10 % dueño del juego a **30 % + 40 %**. La subida de ropa 2D pasó de 10 R$ a **80 R$**, y la 3D bajó de 300 R$ a **80 R$**. Ahora ID verificado (propio o de un padre/tutor vinculado), verificación en dos pasos y **Roblox Plus o Premium 1000/2200** son obligatorios para publicar y para mantener a la venta [OFICIAL].
2. **Las cifras "200 R$" (subida) y "600 R$" (anticipo) que viste en fuentes son del anuncio inicial** del DevForum y fueron **corregidas**: la documentación oficial vigente dice **80 R$ de subida** y anticipo de **10 R$ para ropa clásica**; el anticipo de **600 R$** sigue vigente **solo para ropa en capas 3D** (camisa, chaqueta, pantalón, falda, zapatos…). La documentación nunca llegó a mostrar 200 R$ (sección 2.5).
3. **Dinero real por cada 100 R$ que gasta el comprador** [DERIVADO de datos oficiales]: juego (pase/producto) **US$0,266**; juego con jugador de EE. UU. 18+ **US$0,378**; ítem **propio vendido en juego propio** (30 % + 40 % = 70 %) **US$0,266**; ítem propio en el Marketplace a precio suelo (30 %) **US$0,114**; a 2x el suelo (50 %) US$0,190. **Los ítems de avatar no cobran la tarifa 0,0054** (la lista oficial solo incluye productos, pases, suscripciones y servidores privados).
4. **Los ítems de avatar sí son Earned Robux elegibles para DevEx**, a la tarifa estándar de **0,0038 US$/R$** [OFICIAL]. Hay 30 días de retención (escrow) en cada venta; mínimo de cobro 30.000 R$.
5. **Mercado B: sin datos oficiales de distribución.** Terceros débiles dicen ~120.000 vendedores activos, mediana < 5.000 R$/mes (< US$19/mes) y ~2,4 millones de ítems con ~12.000 nuevos por semana [TERCERO débil, sin fuente primaria]. Comparación incómoda: la mediana de DevEx de juegos (US$1.500/año) es de gente que ya superó el umbral de cobro; la de ítems es de otra población y no es comparable directamente.
6. **Economía por ítem 3D en capas (suelo hipotético de 100 R$)** [DERIVADO]: desembolso de 680 R$ (80 + 600) ≈ US$2,58 al valor DevEx o ≈ US$6,80 si compras Robux a 0,01 nominal. El anticipo se recupera con las ventas (rebate del 30 % de la comisión de plataforma). Recuperas todo con ~12 ventas a precio suelo, ~7 ventas a 1,5x y ~5 ventas a 2x. **Un ítem que no vende pierde 680 R$.** Para ganar **US$100/mes** hacen falta ~877 unidades/mes en toda la cartera a precio suelo, ~428 a 1,5x o ~263 a 2x.
7. **La ropa clásica 2D ya no es negocio en el Marketplace**: a 5 R$ el creador recibe 1,5 R$ (US$0,0057) por venta y necesita ~54 ventas solo para recuperar subida y anticipo. Roblox además advierte que muchos avatares UGC ya no la soportan [OFICIAL].
8. **Riesgo de plataforma de B demostrado**: el recorte del 14-jul-2026 (petición con "miles" de firmas; hilo de DevForum con al menos ~1.300 mensajes según la URL), 9 modificaciones de la página oficial de tarifas entre el 7-jul y el 9-oct (cambios de importes, requisitos y secciones), y la FAQ oficial que dice que el anticipo "puede cambiar 2-3 veces por trimestre" [OFICIAL/TERCERO].
9. **Riesgo cruzado**: una infracción de IP o de Normas de la Comunidad en B puede costarte los Robux del ítem, acciones sobre la cuenta y, en el límite, la suspensión de DevEx, que **es la misma cuenta que cobra los juegos (A)** [OFICIAL: DevEx exige cumplimiento total].
10. **RECOMENDACIÓN (confianza media, ~65 %): A como motor (≈ 75-80 % del tiempo y del dinero); B solo como línea secundaria acotada y por etapas**: primero (a) una tienda de avatar **dentro de tus propios juegos** (70 % en vez de 30 %; además ganas 40 % de comisión por ítems ajenos vendidos en tu juego) y (b) un piloto de 20-30 ítems **3D** (no 2D) en el Marketplace con criterios de parada. No empieces por B-primero: el techo es menor, los datos son peores y el cobro tarda más. Plan en la sección 6.

---

## 2. Reglas vigentes a 2026-10-20

Todo lo de esta sección sale de la documentación oficial salvo que se indique. Enlaces base:
[Fees and commissions](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-fees-and-commissions.md) ·
[Marketplace policy](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-policy.md) ·
[Publish to Marketplace](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/publish-to-marketplace.md) ·
[Moderation](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/moderation.md) ·
[FAQ](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/frequently-asked-questions.md) ·
[Classic clothing](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/classic-clothing.md) ·
[DevEx](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/developer-exchange.md).

### 2.1 Tipos de ítem

| Tipo | Qué es | Herramienta | Anticipo de publicación (no limitado) | Notas [OFICIAL] |
|---|---|---|---:|---|
| Camiseta / camisa / pantalón **clásicos 2D** | Imagen que envuelve un avatar de bloques | Editor de imágenes + web | **10 R$** | Es el tipo "más básico". Aviso oficial: "many user-generated avatars on the Marketplace do not support 2D classic clothing". |
| **Ropa en capas 3D** (chaqueta, camiseta, camisa, jersey, pantalón, falda/vestido, shorts, zapatos) | Malla con jaula (cage) que se ajusta al cuerpo | Blender/Maya + Studio; [Avatar Setup](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar-setup/auto-setup-requirements.md) añade rig y jaula | **600 R$** | Máx. **4.000 triángulos**; textura máx. **2.048 x 2.048** ([especificaciones](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/layered-accessories/specifications.md)). |
| **Accesorios rígidos** (pelo, cuello, hombro, frente, espalda, cintura) | Malla fija en un punto de anclaje | Blender + Studio | **1.000 R$** | Pelo 1.000; cuello/hombro/frente/espalda/cintura 1.000. |
| Sombrero / cara | Idem | Idem | **1.500 R$** | |
| Cuerpo / cabeza / emote / maquillaje | Más complejos | Idem | Cuerpo 2.500; cabeza 1.500; emote 1.500; maquillaje 1.000 (añadido 2026-10-09) | Exigen cabeza dinámica, 17 poses FACS, capas de modestia, etc. |
| **Emisivo** (máscara emisiva) | Brillo propio | Idem | **x5** el anticipo no limitado (ej. capas: 3.000 R$) | Subida de **500 R$** en vez de 80 (desde 2026-09-03). |
| **Limited pagado** | Cantidad fija (máx. 3.000 uds.) | | **5.000 a 20.000 R$** según tipo (ej. chaqueta 5.000; cuerpo 20.000) | Sin tope diario para pagados; **50/día** los gratuitos. |
| **Limited gratuito** | Precio 0, pagas por unidad | | **Tarifa por unidad**; la FAQ dice 100 R$/unidad "hoy", dinámica | **Roblox se queda con toda la tarifa**. 200 sombreros gratis = 20.000 R$ (ejemplo oficial). |
| Paquetes (bundles) | Cuerpo/cabeza/zapatos como conjunto | | Según tipo | Los bundles no se pueden actualizar tras subirlos. |

### 2.2 Requisitos del creador (individuo o grupo)

| Acción | Requisitos [OFICIAL, [Marketplace policy](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-policy.md#creator-requirements)] |
|---|---|
| Subir (Studio o Creator Dashboard) | Verificación por **documento de identidad propio** o **cuenta de padre/tutor vinculada con ID verificado** (aclaración del 2026-08-03); 80 R$ por envío |
| Publicar en el Marketplace | Lo anterior + **verificación en dos pasos** + anticipo (10 a 2.500 R$ según tipo) + **Roblox Plus o Premium 1000/2200** (individuo o propietario del grupo) |
| Mantener a la venta | Seguir cumpliendo; **Plus o Premium 1000/2200 activo** |

- **Grupo o cuenta personal:** puedes elegir como creador tu usuario o un grupo asociado; el grupo también debe cumplir requisitos y el **propietario del grupo** necesita Plus/Premium. Los pagos de grupo cuentan como Earned Robux si provienen de ganancias legítimas ([DevEx](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/developer-exchange.md)).
- **Edad:** las páginas que leí no fijan una edad mínima específica para vender; la vía "cuenta parental vinculada con ID verificado" sugiere que un menor puede vender apoyándose en un padre/tutor [DERIVADO, confirmar en Creator Hub]. DevEx exige **13+** años [OFICIAL].
- **Precio de Roblox Plus:** US$4,99/mes (lanzado 30-abr-2026) según [informe 02](02-monetizacion-y-economia.md) [TERCERO/OFICIAL vía Help Center]. **Precio actual y disponibilidad de Premium 1000/2200: [NO VERIFICADO]** (un tercero afirma que Premium dejó de venderse; la política sigue citándolo).
- **Programa UGC heredado:** la FAQ oficial dice que se **elimina** el proceso de solicitud antiguo; quien cumple los requisitos puede vender.

### 2.3 Costes de lanzar un ítem [OFICIAL, con conversión DERIVADA]

| Concepto | R$ | US$ al valor DevEx (0,0038) | US$ si compras Robux (nominal 0,01) |
|---|---:|---:|---:|
| Subida (por envío, también si se rechaza; también por cada actualización) | 80 | 0,30 | 0,80 |
| Subida con máscara emisiva | 500 | 1,90 | 5,00 |
| Anticipo ropa clásica | 10 | 0,04 | 0,10 |
| Anticipo ropa en capas | 600 | 2,28 | 6,00 |
| **Total ropa clásica (80 + 10)** | **90** | **0,34** | **0,90** |
| **Total ropa en capas (80 + 600)** | **680** | **2,58** | **6,80** |
| Total accesorio rígido (80 + 1.000) | 1.080 | 4,10 | 10,80 |
| Total sombrero/cara (80 + 1.500) | 1.580 | 6,00 | 15,80 |
| Total Limited pagado chaqueta (80 + 5.000) | 5.080 | 19,30 | 50,80 |

Importante: pagar con Robux **ganados** cuesta US$0,0038 por R$ (coste de oportunidad); pagar con Robux **comprados** cuesta más. Uso 0,01 como valor nominal porque Roblox calcula sus "ganancias efectivas" contra US$0,01 por R$ ([informe 02](02-monetizacion-y-economia.md)); el precio real de compra en tu país **no lo verifiqué**.

**Reglas del anticipo (publishing advance)** [OFICIAL]:
- Es un pago al **publicar** (después de aprobada la moderación), por lo que **un rechazo solo te cuesta los 80 R$ de subida**, no el anticipo.
- Se llama "reembolsable", pero **se devuelve con las ventas**: Roblox te da, por cada unidad vendida, un *rebate* igual a su comisión de plataforma (30 % del precio) hasta cubrir el anticipo. El ejemplo oficial (anticipo 1.000 R$, venta en juego a 400 R$) muestra 120 R$ de comisión + 120 R$ de rebate por unidad hasta devolver los 1.000. El rebate **no pasa por el escrow de 30 días**. Un ítem que no se vende **no devuelve nada**: la página no habla de reembolso sin ventas [DERIVADO].
- Quitar y volver a poner a la venta no exige otro anticipo.
- La FAQ dice que el anticipo "puede cambiar como máximo 2-3 veces por trimestre" [OFICIAL].
- Para Marketplace (no en juego) el ejemplo oficial usa una venta en juego; que el rebate funcione igual en ventas del Marketplace **[NO VERIFICADO]**: confirmar en *Transacciones > Publishing Advance Rebates*.

### 2.4 Reparto de ingresos (comisiones)

| Canal de la venta | Creador | Dueño del juego (afiliado) | Roblox | Fuente |
|---|---:|---:|---:|---|
| **Marketplace** a precio suelo | **30 %** | 0 % | 70 % (40 % "porción de vendedor" + 30 % de tarifa de mercado) | [Fees](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-fees-and-commissions.md#commissions), [Monetization overview](https://github.com/Roblox/creator-docs/blob/main/content/en-us/get-started/monetization.md) |
| Vendido **dentro del juego de otra persona** (Inspect Menu, AvatarEditorService o MarketplaceService) | 30 % | **40 %** | 30 % | Idem |
| Vendido **en tu propio juego** | 30 % | 40 % (eres tú) | 30 % | Total para ti **70 %** ("bringing your return to 70% of Robux spent") |

**Reparto progresivo en el Marketplace** [OFICIAL]: cuanto más sube el precio sobre el **suelo de precio** (dinámico, por categoría), mayor % de creador. **Solo aplica a compras en el Marketplace; en juegos es 30 % fijo.** Los ajustes de **precio regional** no alteran el %.

| Múltiplo del suelo | 1 | 1,3 | 1,5 | 2 | 2,5 | 3 | 3,5 | 4 | 5 | 6+ |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| % del creador | 30 | 37 | 41 | 50 | 57 | 62 | 65 | 67 | 69 | 70 |

- **R$ por venta con suelo de 100 R$** [DERIVADO]: precio 100 → 30 R$; 150 → 61,5; 200 → 100; 300 → 186; 400 → 268; 600 → 420. El ingreso por venta crece más rápido que el precio, así que fijar el precio por encima del suelo compensa **si** la demanda no se hunde.
- El suelo vigente por categoría **no está en la documentación** (se ve en `create.roblox.com/dashboard/creations/pricing`, bloqueado aquí). Datos de terceros: camiseta clásica 2 R$, camisa/pantalón clásicos 5 R$ (Fandom, fecha incierta) y promedio de la ropa en capas ~150 R$ (RoLearn) **[TERCERO débil]**. La FAQ oficial confirma que el suelo se mueve con la demanda.
- Si el progresivo aplica a la ropa clásica 2D tras el 14-jul: **[NO VERIFICADO]** (un tercero dice que sí; la documentación habla de "3D asset type" en la sección de rangos de precio).
- **Roblox Plus**: los suscriptores reciben 10 % de descuento (20 % desde el tercer mes) en ítems de avatar, **subvencionado por Roblox**: tu ganancia por compra no baja ([Roblox Plus](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/roblox-plus.md)).

**Limiteds y reventa** [OFICIAL]: cuando se revende un Limited creado por la comunidad: **50 % revendedor, 10 % creador (regalía original), 10 % vendedor/afiliado, 30 % Roblox**. Revender exige Plus/Premium; espera de hasta 30 días antes de revender; no disponible en cuentas de Japón. **Los Robux de comprar/vender ítems que no creaste no son Earned Robux** (inelegibles para DevEx). La propia página dice a la vez que "only Roblox-created Limiteds are tradeable" y describe la reventa de Limiteds de la comunidad: **contradicción interna, [NO VERIFICADO] cuál rige hoy**.

**Licencias de marca (IP)** [OFICIAL, [ip-licensing/creators](https://github.com/Roblox/creator-docs/blob/main/content/en-us/ip-licensing/creators.md)]: puedes pedir una *Marketplace license* a un titular de derechos; cada licencia fija un % de reparto para el titular, que se aplica **después** de las tarifas del Marketplace.

### 2.5 Confirmación del cambio del 14-jul-2026 (documentación oficial)

El historial del repositorio oficial muestra el cambio en el commit [`1296aef5`](https://github.com/Roblox/creator-docs/commit/1296aef5) del **2026-07-14 17:14 UTC** y la corrección posterior [`6b60f26c`](https://github.com/Roblox/creator-docs/commit/6b60f26c) a las 17:29 UTC.

| Concepto | Antes (documentación hasta 2026-07-07) | Después (desde 2026-07-14) |
|---|---|---|
| Subida ropa 2D | **10 R$** | **80 R$** |
| Subida ítem 3D | **300 R$** | **80 R$** (500 si usa máscara emisiva, desde 2026-09-03) |
| Anticipo ropa clásica | 10 R$ | **10 R$** (la documentación mostró 20 R$ durante 15 minutos y se corrigió a 10) |
| Anticipo 3D | 600 a 2.500 R$ | 600 a 2.500 R$ (sin cambio) |
| Reparto ropa 2D, Marketplace | Creador **70 %** | Creador **30 %** |
| Reparto ropa 2D, en juego | Creador **60 %** + dueño del juego **10 %** | Creador **30 %** + dueño **40 %** |
| Reparto 3D | 30 % / 40 % en juego | Sin cambio |
| Requisitos 2D | Plus/Premium (sin ID explícito en la tabla) | **ID verificado + 2FA + Plus/Premium**, igual que 3D |
| Requisitos 3D | ID + Plus/Premium | Igual |

**Lo que no cuadra con otras fuentes, y la resolución:**

| Afirmación | Veredicto |
|---|---|
| "Subida de 200 R$ y anticipo desde 600 R$" (Tech Insider, y el extracto del buscador del propio hilo del DevForum) | Es el **anuncio inicial** (publicado ~7-jul según un tercero). Una respuesta posterior de Roblox lo **ajustó a 80 R$ de subida (2D y 3D) y 10 R$ de anticipo 2D** (según extractos del DevForum y PCGamesN; [TERCERO]). La **documentación oficial** solo muestra 80/10 desde su primera versión del 14-jul. **No uses 200/600 para 2D.** |
| "800 R$" (extracto de un resumen) | Falso/desfasado, no aparece en la documentación [NO VERIFICADO]. |
| "Los ingresos de Roblox no cambian" | Roblox dice que su tarifa efectiva y el total repartido a la comunidad no cambian (extracto del DevForum, [TERCERO]). **Interpretación mía [IDEA PROPIA]:** eso solo se cumple si las ventas se mueven a juegos (40 % al dueño del juego); en el Marketplace Roblox retiene ahora el 70 % de la ropa 2D (antes 30 %), es decir, para quien vende ropa 2D solo en el Marketplace **sí es un recorte del 57 %** (de 70 a 30). |
| "Modelo progresivo posterior" (FFBooyah, 15-jul) | La documentación sí tiene reparto progresivo en el Marketplace; que aplique a 2D es [NO VERIFICADO]. |

**Cambios posteriores en la documentación** (para medir la volatilidad): 2026-07-07 desaparece la sección "Restocking" de la página de tarifas (la FAQ y la página de publicación siguen mencionándola); 2026-07-28 se elimina la sección "Classic clothing" de la página de tarifas; 2026-07-31 cambia la redacción "experience/game"; [2026-08-03](https://github.com/Roblox/creator-docs/commit/d26166c3) aclara que el ID debe ser propio o de un padre/tutor con ID; [2026-09-03](https://github.com/Roblox/creator-docs/commit/40503291) añade la subida de 500 R$ y la tabla emisiva; [2026-10-09](https://github.com/Roblox/creator-docs/commit/4fc84785) añade el anticipo de maquillaje (1.000 R$).

### 2.6 ¿Cuentan como Earned Robux para DevEx y a qué tarifa?

[OFICIAL, [DevEx](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/developer-exchange.md) y [18+](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/18-plus-devex-rate.md)]

| Pregunta | Respuesta |
|---|---|
| ¿Cuentan los Robux de vender ítems de avatar? | **Sí.** "Earnings from selling avatar items in the Marketplace" y "fees from in-game purchases of Marketplace items" figuran como Earned Robux. |
| ¿Qué no cuenta? | Comprar/vender o revender ítems que no creaste; Robux recibidos por transferencia; Robux comprados; subvenciones mensuales de suscripción; contenido moderado. Roblox decide "a su discreción". |
| Tarifa | **0,0038 US$/R$** (estándar vigente desde 2026-09-05). Los saldos anteriores a esa fecha se cobran primero a 0,0035. |
| ¿Aplica la tarifa 18+ de **0,0054**? | **No para ítems de avatar.** La lista de Earned Robux elegibles son solo productos de desarrollador, pases, suscripciones y servidores privados, comprados por jugadores de EE. UU. 18+ verificados, en juegos que usen avatares R15. [DERIVADO] por exclusión: ítems de avatar = 0,0038. |
| Mínimo / frecuencia | 30.000 R$ ganados (≈ US$114); un cobro completado por mes natural; 13+ años; W-9 o W-8; revisión ~10 días hábiles el primer cobro y ~5 después. |
| Escrow | **30 días** en cada venta de ítem (los *rebates* del anticipo, no). |

### 2.7 Moderación, reembolsos, límites, derechos

| Tema | Regla [OFICIAL salvo indicación] |
|---|---|
| Tiempo de revisión | "Hasta 24 horas" ([Moderation](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/moderation.md)). Tasa de rechazo: **no hay dato público** [NO VERIFICADO]. |
| Rechazo | La subida (80 R$) **no se reembolsa en general**; el anticipo no se ha pagado todavía. |
| Retirada posterior | Si Roblox retira un ítem con ventas, **reembolsa a los compradores y cancela los pagos pendientes** de ese ítem. |
| Apelación | Página de apelaciones; reporte de IP con aviso DMCA vía Rights Manager. |
| Si hay una retirada por IP | El infractor **pierde las tarifas por unidad y los Robux ganados** con el ítem; los reincidentes pueden perder la cuenta. |
| Archivar | Solo ítems con ≥ 180 días; no se pueden archivar los Limiteds. Archivar no te libra de un reporte de IP. |
| Límites diarios | Subida y moderación: sin límite. Publicar no limitados: sin límite. Limiteds pagados: sin límite; gratuitos: 50/día. (La FAQ dice "1 Limited por día": **página desfasada, [NO VERIFICADO]**.) |
| Actualizar un ítem ya publicado | Solo arreglos (ajuste, cage, textura, miniatura), mismo tipo, **80 R$ y otra moderación**; "substantial design changes aren't allowed". |
| Prohibido | Marcas oficiales de Roblox; ítems "overly similar" a otros (incluidos tus propios ítems republicados como Limited); copiar a otro creador; vender sin permiso contenido con IP ajena o "inspirado" en ella; categorías falsas; texto excesivo; ítems que molestan a otros jugadores; temas políticos, religiosos, de citas/boda, etc. |
| Derechos | Copyright automático sobre lo original; "the more original… the more protected"; no te protege contra otros sombreros distintos ([IP](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/intellectual-property.md)). No es asesoría legal. |
| IA generativa | **No hay una regla oficial específica de IA** en la política del Marketplace. Aplica lo general: debes tener derecho a lo que subes. Una búsqueda no halló política 2026 propia de IA; [NO VERIFICADO]. |
| Venta exclusiva en tus juegos | Campo *Sale Location* "Experience By Place ID (API Only)": el stock original solo se vende en tus Place IDs. Hay que activar el ítem en el juego ([Avatar items](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/avatar-items.md)). |
| Publicidad | *Sponsored Items*: subasta diaria, mínimo **10 R$/día**, ciclos de 24 h a 28 días; gestionable por API ([sponsor-items](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/sponsor-items.md)). |

---

## 3. El mercado de ropa/ítems de avatar

### 3.1 Datos disponibles y su fiabilidad

| Dato | Valor | Etiqueta y fuente |
|---|---|---|
| Pagos DevEx totales (todos los creadores) | US$1.503 M en 2025; ~US$1,7 mil M en los 12 meses a 30-jun-2026; >42.000 creadores; mediana ≈ US$1.500; top 1.000 ≈ 82 % | [TERCERO-prensa] vía [informe 02](02-monetizacion-y-economia.md); **no desglosa ítems de avatar** |
| Pagos solo de ítems de avatar | **No publicado por Roblox** | [NO VERIFICADO] (el 10-Q solo los menciona como fuente de Earned Robux) |
| Vendedores activos | ~120.000 a inicios de 2026 | [TERCERO débil] [RoLearn tendencias](https://rolearn.dev/trend-reports/roblox-ugc-marketplace-trends-2026) (sin fuente primaria) |
| Mediana de vendedor | < 5.000 R$/mes (< US$19/mes a 0,0038); top 1 % "seis cifras" | [TERCERO débil] RoLearn |
| Catálogo | ~2,4 millones de ítems rastreados, ~12.000 nuevos por semana; las tendencias suben y bajan en 8-12 semanas; ropa en capas ~11 % de ventas, ~150 R$ de media | [TERCERO débil] [RoLearn catálogo](https://rolearn.dev/trend-reports/roblox-ugc-catalog-2026-categories-trends-top-creators/); otro informe suyo habla de 14 millones de ítems listados en 2025: **se contradicen** |
| Ítem mediano | ~US$20 de por vida; decil superior > US$1.000; top 1 % > US$50.000 | [NO VERIFICADO] (resumen de buscador de blogs; no identifiqué la fuente exacta) |
| Top 1.000 de UGC | US$0,8-1,1 M/año de media | [TERCERO débil]; el dato de Roblox es de **todos los** creadores, no solo UGC |
| Limiteds | Los mejores (Junozy, Soulskor, Reverse Polarity) se agotan en segundos y se revenden a 5-20x | [TERCERO débil] [RoWatcher](https://rowatcher.com/news/inside-roblox-s-ugc-economy-who-s-winning-in-2026) |
| Caso de éxito verificable con prensa | **Metafashion** (Arjun Goel, 19 años): ~2,5 M de unidades y ~US$300.000 de GMV, ronda pre-seed de US$400.000 (mayo-2026) | [TERCERO] [Outlook Respawn, 2026-07-30](https://respawn.outlookindia.com/gaming/gaming-originals/how-a-19-year-old-is-turning-roblox-into-a-fashion-business). [DERIVADO]: US$0,12 brutos por unidad ⇒ modelo de **volumen y precios bajos**; lo que él cobró es una fracción del GMV |
| Caso "seis cifras" anónimo | "UGC creator earning six figures" | [NO VERIFICADO] [RoLearn](https://rolearn.dev/case-studies/ugc-creator-six-figure-avatar-items) (no nombra a la persona) |

**Lectura:** hay **evidencia de cola larga** (pocos creadores ganan mucho) pero **ninguna distribución verificable**. Un mismo creador de ropa 2D vivió además el recorte de 70 % a 30 %.

### 3.2 Reacción al cambio de reparto del 14-jul-2026

| Hecho | Fuente |
|---|---|
| Petición en Change.org pidiendo mantener el 70 % o limitar el recorte a 10 % con aviso previo; "miles" de firmas (sin total verificado) | [Change.org](https://www.change.org/p/protect-roblox-clothing-creators-revenue-share) [TERCERO] |
| El hilo del anuncio en DevForum tiene al menos ~1.300 mensajes (el número sale de la URL de un mensaje del hilo: `/4722717/1298`); hubo además un hilo de reversión | [DevForum](https://devforum.roblox.com/t/building-stronger-protections-and-a-more-consistent-marketplace-unifying-2d-and-3d-avatar-item-publishing/4722717), [reversión](https://devforum.roblox.com/t/revert-changes-to-the-2d-clothing-update/4732289) [DERIVADO]/[TERCERO]; no pude abrirlos |
| Los críticos lo llamaron "pay cut dressed up as a policy update"; el argumento de Roblox es seguridad y coherencia, y el coste como "disuasión financiera" contra redes de cuentas automatizadas | [PCGamesN](https://www.pcgamesn.com/roblox/backlash-clothing-changes-unifying-requirements-2d-3d), [Tech Insider](https://tech-insider.org/roblox-2d-creator-revenue-share-cut-2026/) [TERCERO] |
| Roblox respondió reduciendo la subida (200 → 80 R$) y el anticipo 2D (a 10 R$); dice que "no elimina" la ropa 2D y que quiere "explorar funciones avanzadas del Marketplace para 2D" | extractos del DevForum vía buscador [TERCERO] |
| **No hay cifra oficial** de cuántos creadores se vieron afectados ni de la caída de ingresos | [NO VERIFICADO] |

### 3.3 Estacionalidad, saturación y tendencias 2026

- **Estacionalidad por ítem: sin datos.** Lo único medible es de plataforma: pagos DevEx Q4-2025 US$477 M, Q1-2026 US$423 M, Q2-2026 US$363 M, y guía de Roblox para el T3-2026 de **bookings −14 % a −18 %** interanual ([informe 02](02-monetizacion-y-economia.md), [OFICIAL vía resúmenes del 8-K]). La ropa depende del mismo gasto. **[IDEA PROPIA]:** espera picos en noviembre-diciembre y en vacaciones de verano, y estacionales (Halloween, Navidad). Hoy es 20-oct: Halloween llega en 11 días; la moderación tarda ≤ 24 h, así que un lote para Navidad debe subirse a mediados de noviembre.
- **Saturación:** 12.000 ítems nuevos/semana [TERCERO débil] y la política de "no overly similar" empujan a la diferenciación. La propia FAQ justifica el anticipo diciendo que cuando los ítems de una categoría crecen más rápido que el interés, "es más difícil descubrir ítems únicos" [OFICIAL].
- **Tendencias:** los paquetes (bundles) crecen más rápido (+41 % interanual, RoLearn, débil); la FAQ del DevForum promete funciones avanzadas para 2D (sin fecha); Roblox Plus añade descuentos de 10-20 % **subvencionados por Roblox** en ítems de avatar, lo que puede empujar el volumen [OFICIAL]; las **ventas dentro de juegos** reciben el 40 % para el dueño del juego, lo que convierte el tráfico de juegos en un canal.
- **Moderación en la práctica:** hay quejas en DevForum de borrados "aleatorios" de ítems antiguos por moderación automática ([hilo](https://devforum.roblox.com/t/seemingly-random-ugc-item-deletions-are-happening/3032202), fecha no verificada) [TERCERO]. Si te retiran un ítem con ventas, se reembolsa al comprador y pierdes el pago pendiente [OFICIAL].

### 3.4 Canales de venta "dentro del juego" (in-experience)

| Mecanismo | Qué es | Reparto | Fuente |
|---|---|---|---|
| Menú de inspección / AvatarEditorService / MarketplaceService | Tu juego permite probar y comprar ítems del catálogo (el menú de inspección está activado por defecto) | Dueño del juego **40 %** de cada ítem comprado en tu juego (si lo compran fuera no ganas) | [Inspect Menu](https://github.com/Roblox/creator-docs/blob/main/content/en-us/players/avatar-inspect-menu.md), [Avatar Editor](https://github.com/Roblox/creator-docs/blob/main/content/en-us/players/avatar-editor.md) [OFICIAL] |
| Ítems exclusivos de tu juego | Sale Location por Place ID | 70 % si eres creador y dueño | [Avatar items](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/avatar-items.md) [OFICIAL] |
| UGC Homestore | Plantilla de tienda con maniquíes | Igual: "larger commission split" en tu propio juego | [Homestore](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/homestore.md) [OFICIAL] |
| Creación en el juego (AvatarCreationService) | Los jugadores crean cuerpos/maquillaje y los compran | Tú eres el *publisher*; requiere *Avatar Creation Token* (anticipo + tarifa de creación); **los ítems no se listan en el Marketplace ni se revenden** | [in-experience](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/in-experience-creation.md), [token](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/avatar-creation-token.md) [OFICIAL] |

---

## 4. Economía unitaria de un ítem

### 4.1 Dinero real por cada 100 R$ que paga el comprador [DERIVADO de datos oficiales]

| Canal | % para ti | US$ por 100 R$ (a 0,0038, salvo indicación) |
|---|---:|---:|
| Juego: pase/producto/suscripción (estándar) | 70 % | **0,266** |
| Juego: gasto cualificado de jugador EE. UU. 18+ (0,0054) | 70 % | **0,378** |
| Ítem propio, vendido en tu propio juego | 70 % (30 + 40) | **0,266** |
| Ítem ajeno vendido en tu juego (solo comisión) | 40 % | 0,152 |
| Ítem propio en juego ajeno | 30 % | 0,114 |
| Ítem propio, Marketplace, precio = suelo | 30 % | **0,114** |
| Marketplace 1,5x suelo | 41 % | 0,156 |
| Marketplace 2x suelo | 50 % | 0,190 |
| Marketplace 3x suelo | 62 % | 0,236 |
| Marketplace 6x o más | 70 % | 0,266 |

La conclusión central: **en el Marketplace a precio suelo ganas menos de la mitad (0,114) que en un juego por el mismo gasto del comprador (0,266), y nunca accedes a 0,378.** Solo vendiendo en tu propio juego igualas a un juego.

### 4.2 Supuestos explícitos del modelo [IDEA PROPIA]

- Suelo de precio hipotético **F = 100 R$** (el real es dinámico y no lo pude ver; recalcula con el tuyo: la fórmula es `R$ por venta = % progresivo × precio`).
- Ventas por ítem y mes (Q): **no existe distribución oficial**; los niveles siguientes son escenarios, no estimaciones de probabilidad.
- Rebate del anticipo = 30 % del precio por unidad hasta devolver el anticipo (ejemplo oficial; en Marketplace [NO VERIFICADO]).
- Ignoro impuestos, retención de DevEx (consultar asesor fiscal) y la rebaja por precio regional (en LATAM el comprador puede pagar menos R$ por el mismo ítem [DERIVADO]; el % de creador no cambia).
- Fórmulas para reproducir: `USD/mes por ítem = Q x %progresivo(m) x (m x F) x 0,0038`; `ventas para recuperar = (80 + A) / (precio x (%creador + 30 %))` mientras dure el rebate (en la clásica con A pequeño el rebate se agota antes, y el cálculo se hace por tramos).

### 4.3 Ventas para recuperar el coste de subida y anticipo (Marketplace, F = 100) [DERIVADO]

| Ítem y precio | Ventas para recuperar subida + anticipo | Ventas para que el rebate devuelva el anticipo |
|---|---:|---:|
| Capas 3D, anticipo 600, precio 100 (1x, 30 %) | **12** | 20 |
| Capas 3D, precio 150 (1,5x, 41 %) | **7** | 14 |
| Capas 3D, precio 200 (2x, 50 %) | **5** | 10 |
| Accesorio rígido, anticipo 1.000, precio 150 (1x) | 12 | 23 |
| Sombrero/cara, anticipo 1.500, precio 150 (1x) | 18 | 34 |
| **Clásica 2D, anticipo 10, precio 5 R$ (30 %)** | **54** | 7 |
| Clásica 2D, precio 25 R$ | 11 | 2 |

Lectura: **un ítem 3D que logra apenas 7-12 ventas se paga solo**; el riesgo real es el ítem que **no vende nada** (pierdes 680 R$ ≈ US$2,58 a US$6,80) y el tiempo. En la clásica 2D el problema no es el desembolso (US$0,34-0,90) sino que cada venta deja ~1,5 R$ (US$0,0057) a precio de 5 R$.

### 4.4 Ingreso mensual por ítem activo (US$, F = 100, 0,0038) [DERIVADO]

| Ventas/mes por ítem (Q) | Precio = suelo (30 %) | 1,5x (41 %) | 2x (50 %) | 3x (62 %) |
|---:|---:|---:|---:|---:|
| 2 | 0,23 | 0,47 | 0,76 | 1,41 |
| 10 | 1,14 | 2,34 | 3,80 | 7,07 |
| 30 | 3,42 | 7,01 | 11,40 | 21,20 |
| 100 | 11,40 | 23,37 | 38,00 | 70,68 |
| 300 | 34,20 | 70,11 | 114,00 | 212,04 |

**Escenarios por ítem (supuestos míos, 6 meses de vida):**

| Escenario | Supuesto | Ingreso por ítem y mes | Total en 6 meses | Veredicto |
|---|---|---:|---:|---|
| **Pesimista** | Q = 2/mes, precio suelo | US$0,23 | ≈ US$1,4 + rebate; casi no recupera los 680 R$ (US$2,58) | Pérdida pequeña por ítem; **grande en cartera** |
| **Base** | Q = 10/mes, 1,5x | US$2,34 (+ US$1,71 de rebate mientras se recupera el anticipo) | ≈ US$14 sin contar el rebate | Se paga en 1-2 meses (según valores el Robux a 0,0038 o a 0,01) |
| **Optimista** | Q = 100/mes, 2x | US$38 | ≈ US$228 | Solo lo logra un porcentaje muy pequeño de ítems |

**Tamaño de cartera para llegar a US$100/mes netos (26.316 R$ ganados/mes) [DERIVADO]:** ~877 unidades/mes en total a precio suelo; ~428 a 1,5x; ~263 a 2x; ~141 a 3x. Con 100 ítems activos eso son entre 1,4 y 8,8 ventas por ítem y mes. Para igualar el **US$125/mes** (= mediana DevEx de juegos de US$1.500/año) harían falta ~535 unidades/mes a 1,5x.

**Capital de la cartera [DERIVADO]:** 10 ítems en capas = 6.800 R$ (US$26 a US$68); 30 ítems = 20.400 R$ (US$78 a US$204); 100 ítems = 68.000 R$ (US$258 a US$680). El retorno llega por rebate (30 % del bruto) más tu % de creador.

**Tiempo hasta cobrar [DERIVADO]:** necesitas 30.000 R$ ganados; con 5.000 R$/mes (la mediana según RoLearn) tardas **6 meses**, más 30 días de escrow y ~10 días hábiles de revisión; con 26.316 R$/mes, ~1,1 meses. Es decir, **aunque el ítem esté a la venta al día siguiente (moderación ≤ 24 h), tu primer dinero real tarda de 2 a 7+ meses** salvo que la cartera ya venda bien.

### 4.5 Coste de producción con IA

| Tipo | Flujo con IA | Tiempo [IDEA PROPIA] | Coste de herramientas | Dificultad |
|---|---|---|---|---|
| **Clásica 2D** | Imagen con IA + plantilla oficial; prueba en Studio con maniquí | 10-20 min | ~0 | Muy fácil; economía mala |
| **Capas 3D** (jersey, camiseta, pantalón) | Base validada en Blender (plantillas con jaula de Roblox) + texturas generadas con IA; [Avatar Setup](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar-setup/auto-setup-requirements.md) añade rig y jaula; herramienta de validación de Studio | Primer ítem: 4-10 h; variantes por retextura: 30-90 min; silueta nueva: 2-4 h | Blender gratis; Meshy/Tripo Pro ~US$20/mes opcional ([informe 05](05-ia-assets-y-marketing.md)) | Media-alta |
| **Accesorios rígidos** (sombreros, mochilas) | Imagen a 3D (Meshy/Tripo) + limpieza + puntos de anclaje | 1-3 h | ~US$20/mes | Media. La malla generada suele no ser estanca (watertight); hay que limpiarla |

- La validación oficial comprueba esquema, geometría, texturas, jaulas, rig, anclajes y moderación ([validation-system](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/validation-system.md)): una malla generada por IA **suele fallar** (triángulos > 4.000, jaula incorrecta, UV fuera de [0,1]). Eso es trabajo de iteración, no de un solo "prompt" **[IDEA PROPIA]**.
- Los modelos abiertos de Roblox (Cube 3D) son solo para investigación; no para uso comercial propio ([informe 05](05-ia-assets-y-marketing.md)). Revisa la licencia de cualquier servicio de IA 3D el día que lo contrates.
- Claude puede escribir scripts de Blender (bpy) y de Studio, preparar las descripciones y analizar ventas; **lo que no puedo garantizar** es la revisión visual del ajuste en distintos cuerpos ni el envío automático: la subida de ítems 3D es **"Save to Roblox"** en Studio y la clásica es la web; la API de Open Cloud para activos [no lista ítems de avatar](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/usage-assets.md) **[NO VERIFICADO si hay vía automática]**.

### 4.6 Escalabilidad

- Sin tope de subida ni de publicación de no limitados, **el límite real es el capital y la moderación**: 10 ítems/día = 6.800 R$/día ≈ US$26-68/día. A 30 ítems/día el coste es US$78-204/día.
- Las variantes casi idénticas chocan con la regla de "overly similar" y con la competencia (12.000 ítems nuevos por semana, RoLearn débil). Escala con **colecciones diferenciadas**, no con retexturas masivas.
- Un ítem es un **activo con cola larga** (se sigue vendiendo sin tráfico propio) pero su descubrimiento lo decide el algoritmo del catálogo o la publicidad (*Sponsored Items*, mínimo 10 R$/día). Un anuncio solo compensa si su coste por venta es menor que lo que dejas por venta (p. ej. 61,5 R$ a 1,5x del suelo; mejor que el coste medio por venta sea < ~30 R$ [IDEA PROPIA]).

### 4.7 Riesgos de B

| Riesgo | Gravedad | Detalle |
|---|---|---|
| **IP / marcas** | **Muy alta** | La IA reproduce con facilidad logos, marcas deportivas, personajes de anime y estilos. Copiar o vender "inspirado" sin licencia está prohibido; el aviso DMCA te quita los Robux del ítem y puede costarte la cuenta [OFICIAL]. |
| **Contagio a A** | Alta | El mismo usuario/ID cobra DevEx; DevEx exige cumplimiento total de Términos y Normas y puede suspenderte [OFICIAL]. No abras cuentas alternativas para esquivar sanciones: ID verificado existe precisamente para impedirlo [FAQ oficial]. |
| **Cambio de reglas** | Alta | Julio 2026: recorte 70 → 30 %, subida 2D 10 → 80 R$, ID/2FA obligatorios; el anticipo puede cambiar 2-3 veces/trimestre; el suelo de precios es dinámico. |
| **Dependencia de membresía** | Media | Si dejas de pagar Plus/Premium, no puedes mantener los ítems a la venta [OFICIAL]. |
| **Falsos positivos de moderación** | Media | Retiradas tras ventas con reembolso y pérdida del pago pendiente. |
| **Cuello de botella manual** | Media | Subida por Studio/web; automatización [NO VERIFICADO]. |
| **Competencia/saturación** | Alta | Catálogo masivo; precios al suelo. |

---

## 5. Comparación A (juegos) vs B (ropa/ítems de avatar)

| Criterio | A: juegos con microtransacciones | B: ropa/ítems de avatar |
|---|---|---|
| **Ingreso esperado** | Mediana DevEx ≈ **US$1.500/año** de quienes ya cobran (>42.000), top 1.000 ≈ 82 % del total, top 10 media US$65,7 M [TERCERO-prensa]. Para una cartera de juegos pequeños, la expectativa realista es la mediana o menos ([informes 01/02/07](07-diseno-crecimiento-y-conceptos.md)) | **Sin distribución oficial.** Terceros débiles: mediana de vendedor < 5.000 R$/mes (< US$19/mes ≈ US$228/año); top 1 % de seis cifras. Ítem mediano ~US$20 de por vida [NO VERIFICADO] |
| **Dinero por 100 R$ de gasto** | **US$0,266** (0,378 con 18+ EE. UU. y avatares R15) | **US$0,114** (precio suelo) a 0,266 (precio ≥ 6x suelo o venta en tu juego); nunca 0,378 |
| **Varianza** | Muy alta: un acierto cambia todo, la mayoría ≈ 0 | Alta por ítem, **más baja por ítem pero con techo bajo**; cartera con cola larga |
| **Tiempo hasta primer ingreso** | Semanas para un prototipo; Creator Rewards con retención de 60 días [informe 02]; cobro: umbral 30.000 R$ | **1-2 días** a la venta (moderación ≤ 24 h); primer **cobro** ≥ 30 días de escrow + 30.000 R$ (2 a 7+ meses con ventas modestas) |
| **Capital inicial** | Plus US$4,99/mes o 1.000 R$ por juego (reembolsable a 3 meses si sigue activo) + anuncios de prueba 5.000-10.000 R$/juego [informes 01/02/07] | Plus/Premium + ID verificado + **680 R$ por ítem 3D en capas** (80 + 600), 90 R$ por clásica; 30 ítems ≈ 20.400 R$ (US$78 a US$204) |
| **Habilidad requerida** | Luau, diseño de juego, operación en vivo | Blender/rig/cages/UV (3D) o nada (2D); ojo para estilo; validación de Roblox |
| **Apalancamiento de IA** | **Alto**: código Luau, UI, datastores, analítica ([informe 04](04-ia-studio-mcp-skills.md)) | **Medio**: texturas e imágenes fáciles; malla y jaula necesitan limpieza y verificación visual; Avatar Setup ayuda |
| **Escalabilidad** | Muchos juegos, limitado por tráfico/anuncios | Ítems ilimitados, limitado por **capital (680 R$/ítem)**, moderación y saturación |
| **Defensibilidad** | Baja (clones en 4-6 semanas [informe 01]); algo de moat con comunidad/eventos | Baja (otros pueden hacer ítems parecidos; la IP original protege poco); algo de moat con marca/colecciones/Limiteds |
| **Riesgo regulatorio / de plataforma** | Alto: Q3-2026 bookings −14 % a −18 %, cambios de algoritmo, verificación de edad, requisitos de publicación [informes 02/03] | **Alto y ya materializado** (recorte del 14-jul-2026); riesgo de IP más serio; riesgo cruzado con DevEx |
| **Tareas que Claude automatiza bien** | Scripts, tiendas dentro del juego, economía, pruebas con MCP, lectura de analítica | Scripts de Blender, plantillas de textura, descripciones y metadatos, hoja de precios vs suelo, lista de comprobación de IP, análisis de ventas, apuestas de *Sponsored Items* por API |
| **Dependencia del tráfico** | Total (algoritmo + anuncios); sin tráfico no hay ventas | Catálogo/buscador + anuncios; **y tu propio juego como canal (70 % del reparto)** |
| **Sinergia** | Provee tráfico propio para vender ítems a 70 % y comisiones del 40 % por ítems ajenos | Aporta cosméticos y marca a tus juegos |

---

## 6. Recomendación y plan "las dos a la vez"

### 6.1 Veredicto

**Confianza media (~65 %): A como motor; B como línea secundaria, por etapas y con criterios de parada.** Motivos:

1. **Cash por R$ gastado**: el juego rinde 0,266 (0,378 con 18+) frente a 0,114 del Marketplace a precio suelo. B solo iguala a A cuando **vendes en tu propio juego**; así que B **depende de A** para ser competitivo.
2. **Techo y datos**: en A hay evidencia oficial de lanzamientos con millones; en B solo hay anécdotas y estimaciones de terceros débiles.
3. **Cobro**: B tiene 30 días de escrow y 30.000 R$ de umbral con ventas por unidad de centavos: tarda en pagar.
4. **Riesgo de plataforma**: B acaba de sufrir un recorte del 57 % para 2D y puede volver a cambiar; IP es un riesgo de cuenta que contamina A.
5. **Apalancamiento de IA**: mayor en A (código) que en B (malla/jaula verificadas).

**No recomiendo** (a) ropa clásica 2D como negocio en el Marketplace, ni (b) Limiteds pagados (5.000-20.000 R$ de anticipo), ni (c) ítems con máscara emisiva (anticipo x5) al principio.

### 6.2 Reparto de tiempo y presupuesto [IDEA PROPIA]

| Fase | Duración | A (juegos) | B (ítems) |
|---|---|---|---|
| **0. Verificación** | Días 0-3 | Seguir plan de informes 01/02/07 | Comprobar en Creator Hub la lista de la sección 7 (ID, Plus, suelos, rebates) **antes de gastar Robux** |
| **1. Piloto** | Semanas 1-6 | 75-80 % del tiempo | **5 ítems 3D** (3.400 R$ ≈ US$13-34) con una sola base validada: medir tiempo por ítem, tasa de aprobación, suelo real |
| **2. Tienda en tu juego** | Cuando A tenga ≥ 100-200 jugadores diarios | Añadir "tienda de avatar" (Homestore o AvatarEditorService) | Vender 5-10 ítems propios **exclusivos** por Place ID: 70 % |
| **3. Escalado condicional** | Semanas 6-16 | Mantener | 20-30 ítems en total, **solo si** se cumple el criterio de la 6.3 |

Presupuesto de arranque de B: Plus (US$4,99/mes) + 3.400 R$ (fase 1) ≈ US$18 a US$40 al mes en el primer mes **si compras Robux** [DERIVADO]; el tope total del piloto hasta 30 ítems es ~20.400 R$. Este importe lo fija tu tolerancia a perder dinero: es el máximo que puedes perder en B si ningún ítem vende.

**Sinergias** [IDEA PROPIA, apoyadas en reglas oficiales]:
1. **Ítems en tu juego a 70 %** (30 % creador + 40 % vendedor) en vez de 30 %, más **comisión del 40 %** por cualquier ítem ajeno comprado en tu juego mediante el menú de inspección (activado por defecto).
2. **Un único grupo/marca** como creador de ítems y propietario de juegos; el propietario del grupo necesita Plus/Premium; los pagos de grupo cuentan como Earned Robux.
3. **Marketing compartido**: ítems que lucen NPC y mascotas de tus juegos; *Sponsored Items* y Ads Manager con un único presupuesto de crecimiento.
4. **Un solo kit de estilo** (mismas texturas y personajes) para juegos y colecciones.
5. **Cuidado:** regalar Limiteds gratuitos como gancho cuesta la tarifa por unidad (100 R$ según la FAQ): 1.000 unidades = 100.000 R$ (≈ US$380 a US$1.000); no lo hagas al principio.

### 6.3 Criterios para matar o duplicar B

| Decisión | Condición (a 30 y a 60 días desde la publicación; mínimo 20 ítems publicados) |
|---|---|
| **Matar B en el Marketplace** | Ventas medianas < 3 uds./ítem/mes **y** ingresos acumulados de creador + rebates < 1,0x lo gastado (80 + anticipo) en el 60 % de los ítems; o una retirada por IP/Normas; o el suelo/% de creador cambia de forma que 1,5x el suelo deje < 40 R$ por venta |
| **Mantener** | ≥ 50 % de los ítems con ≥ 5 uds./mes y > 60 R$ por venta de media |
| **Duplicar** | Un ítem con ≥ 100 uds./mes a ≥ 1,5x suelo, o 3 ítems con ≥ 30 uds./mes: crear una **colección** diferenciada (5-8 piezas), probar *Sponsored Items* con coste por venta < 30 R$, y llevarla también a la tienda de tu juego |
| **Pasar a B más en serio** | Cuando B genere más del 30 % de tus Robux ganados durante 3 meses seguidos |
| **Matar la tienda dentro del juego** | Si, con ≥ 500 jugadores diarios durante 30 días, las ventas de ítems son < 5 % de los Robux del juego |

Los umbrales son heurísticas mías, no de Roblox: **calibra con tus propios datos tras los 20 primeros ítems**.

---

## 7. Dudas abiertas y qué verificar a mano en Creator Hub

| # | Qué verificar | Dónde | Por qué importa |
|---|---|---|---|
| 1 | **Suelo de precio actual** de cada categoría (ropa en capas, accesorios, clásica) | `create.roblox.com/dashboard/creations/pricing` | Todo el modelo depende de F |
| 2 | ¿El **reparto progresivo** aplica a la ropa clásica 2D tras el 14-jul? | Diálogo de precio en *Manage Item* (muestra el desglose) | Cambia el 30 % a hasta 70 % |
| 3 | ¿El **rebate del anticipo** funciona igual en ventas del Marketplace? ¿Se devuelve algo si el ítem no vende? | *Transacciones > Publishing Advance Rebates* y primeras ventas | Capital en riesgo |
| 4 | **Roblox Plus vs Premium 1000/2200**: precio, disponibilidad y Robux mensuales en tu país | Roblox Membership | Un Premium con Robux mensuales podría pagar subidas y anticipos [NO VERIFICADO] |
| 5 | **ID verificado**: ¿está disponible en tu país y a tu edad? ¿vía padre/tutor? | Ajustes > Verificación | Es el primer requisito |
| 6 | **Precio real del Robux** en tu moneda | Tienda de Robux | Coste real de cada ítem |
| 7 | Si dejas de pagar Plus: ¿qué pasa con comisiones y con ítems? | Help Center | Riesgo de continuidad |
| 8 | **Limiteds**: ¿tarifa por unidad actual?, ¿reventa de Limiteds de la comunidad?, ¿límites diarios reales?, ¿restock? | Documentación contradictoria (sección 2.7) | Sólo si quieres hacer Limiteds |
| 9 | ¿Hay **norma o etiqueta específica para contenido generado con IA**? | Normas de la Comunidad / Términos de Uso | No hay regla oficial encontrada |
| 10 | ¿Existe vía **automática** de subida/publicación de ítems de avatar? | Docs de Open Cloud / Studio | Define la escalabilidad |
| 11 | El texto final y las respuestas del staff en el hilo del DevForum del 14-jul | DevForum | Solo lo vi por extractos |
| 12 | **Impuestos y retención** de DevEx para tu país (W-8BEN) y el cambio citado del 1-nov-2026 | Creator Hub > Taxes; [informe 02](02-monetizacion-y-economia.md) | Afecta al neto |
| 13 | Datos de **ventas reales** tras el piloto: unidades por ítem, % de rechazo, tiempos | Tus transacciones | Sustituir mis escenarios por datos |

---

## 8. Fuentes

**Oficiales (repositorio de documentación de Roblox, commit 7400643 del 2026-10-20; leído por clonación):**
[marketplace-fees-and-commissions](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-fees-and-commissions.md) ·
[marketplace-policy](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-policy.md) ·
[publish-to-marketplace](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/publish-to-marketplace.md) ·
[moderation](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/moderation.md) ·
[frequently-asked-questions](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/frequently-asked-questions.md) ·
[intellectual-property](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/intellectual-property.md) ·
[validation-system](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/validation-system.md) ·
[sponsor-items](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/sponsor-items.md) ·
[homestore](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/homestore.md) ·
[classic-clothing](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/classic-clothing.md) ·
[layered-accessories/specifications](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/layered-accessories/specifications.md) ·
[avatar-setup](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar-setup/auto-setup-requirements.md) ·
[developer-exchange](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/developer-exchange.md) ·
[18-plus-devex-rate](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/18-plus-devex-rate.md) ·
[avatar-items (en juego)](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/avatar-items.md) ·
[roblox-plus](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/roblox-plus.md) ·
[get-started/monetization](https://github.com/Roblox/creator-docs/blob/main/content/en-us/get-started/monetization.md) ·
[ip-licensing/creators](https://github.com/Roblox/creator-docs/blob/main/content/en-us/ip-licensing/creators.md) ·
[in-experience-creation](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/in-experience-creation.md) ·
[avatar-creation-token](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/avatar-creation-token.md) ·
[avatar-inspect-menu](https://github.com/Roblox/creator-docs/blob/main/content/en-us/players/avatar-inspect-menu.md) ·
[avatar-editor](https://github.com/Roblox/creator-docs/blob/main/content/en-us/players/avatar-editor.md).
**Commits de cambios** (todos del repositorio oficial): [`1296aef5`](https://github.com/Roblox/creator-docs/commit/1296aef5) y [`6b60f26c`](https://github.com/Roblox/creator-docs/commit/6b60f26c) (2026-07-14), [`d26166c3`](https://github.com/Roblox/creator-docs/commit/d26166c3) (2026-08-03), [`40503291`](https://github.com/Roblox/creator-docs/commit/40503291) (2026-09-03), [`4fc84785`](https://github.com/Roblox/creator-docs/commit/4fc84785) (2026-10-09).

**Terceros (consultados el 2026-10-20; solo como extractos del buscador, salvo indicación):**
[Tech Insider](https://tech-insider.org/roblox-2d-creator-revenue-share-cut-2026/) ·
[PCGamesN](https://www.pcgamesn.com/roblox/backlash-clothing-changes-unifying-requirements-2d-3d) ·
[Blox News](https://bloxnetwork.org/news/article/roblox-unifies-2d-and-3d-clothing-rules-in-major-marketplace-overhaul) ·
[Change.org](https://www.change.org/p/protect-roblox-clothing-creators-revenue-share) ·
[FFBooyah](https://ffbooyah.com/2026/07/15/the-roblox-2d-clothing-update-what-actually-happened-and-why-it-matters/) ·
[DevForum, hilo del anuncio](https://devforum.roblox.com/t/building-stronger-protections-and-a-more-consistent-marketplace-unifying-2d-and-3d-avatar-item-publishing/4722717) (extractos; no abrí la página) ·
[RoLearn tendencias](https://rolearn.dev/trend-reports/roblox-ugc-marketplace-trends-2026) ·
[RoLearn catálogo](https://rolearn.dev/trend-reports/roblox-ugc-catalog-2026-categories-trends-top-creators/) ·
[RoWatcher](https://rowatcher.com/news/inside-roblox-s-ugc-economy-who-s-winning-in-2026) ·
[Outlook Respawn, Metafashion](https://respawn.outlookindia.com/gaming/gaming-originals/how-a-19-year-old-is-turning-roblox-into-a-fashion-business) ·
[DevForum, borrados aleatorios](https://devforum.roblox.com/t/seemingly-random-ugc-item-deletions-are-happening/3032202).

**Informes previos de esta carpeta:** [01](01-mejores-juegos.md) · [02](02-monetizacion-y-economia.md) · [03](03-politicas-y-cumplimiento.md) · [04](04-ia-studio-mcp-skills.md) · [05](05-ia-assets-y-marketing.md) · [07](07-diseno-crecimiento-y-conceptos.md).
