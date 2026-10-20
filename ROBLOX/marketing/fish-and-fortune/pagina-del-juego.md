# Fish & Fortune — Página del juego (título, descripciones, etiquetas, ícono y miniaturas)

Fecha: 2026-10-20. Idioma del documento: español. Textos públicos del juego: ES + EN.
Estado del juego (2026-10-20): `ROBLOX/games/fish-and-fortune/src` ya tiene **lógica de servidor y balance** (3 zonas: Lago Calmo, Río Cristal, Costa Dorada; 25 criaturas; 6 rarezas; cañas; bestiario; eventos Marea Dorada y Luna Mítica; código `WELCOME`; panel Probabilidades generado por la misma tabla que la tirada), pero **todavía no hay cliente ni UI jugable**. Los datos de abajo salen de `Balance.luau` y del concepto 1 de `ROBLOX/research/07` (**provisionales**). Cada afirmación que dependa de la UI o de algo aún no confirmado lleva **[AJUSTAR A LO REAL]**: antes de publicar, contrasta con el juego construido. Una página que promete algo que el juego no tiene baja en recomendaciones y en búsqueda [OFICIAL, `discovery.md`] y puede ser moderada.

Etiquetas: **[OFICIAL]** leído hoy en el espejo `Roblox/creator-docs` (raw.githubusercontent.com); **[TERCERO]**; **[NO VERIFICADO]**; **[IDEA PROPIA]**; **[VERIFICAR a mano en Roblox]** = hay que mirarlo en la web/Creator Hub porque desde aquí no se puede.

---

## 1. Título (3 opciones)

Reglas oficiales que condicionan el título [OFICIAL, `discovery.md`]: los metadatos deben reflejar de qué va el juego; las palabras clave irrelevantes se penalizan; **un título que insinúa una recompensa económica "no se prioriza"** (el ejemplo oficial es un título que empieza por Robux); los títulos repetitivos o parecidos a otros ya publicados pierden prioridad; hay que dar "un giro propio" a las tendencias. El límite de caracteres del título no sale en los docs que pude leer: **[VERIFICAR en Creator Hub]** (cifra de memoria: 50 caracteres [NO VERIFICADO]; los títulos de abajo miden ≤ 34).

| # | Título EN | Título ES (localización) | Por qué | Riesgo |
|---|---|---|---|---|
| **A (recomendado para el lanzamiento)** | **Fish & Fortune** | **Fish & Fortune** | Marca corta, igual en ambos idiomas, se recuerda y se escribe bien en búsqueda y en TikTok. Toda la comunicación de la v1 ya lo usa. | "Fortune" puede leerse como "dinero" (ver nota 1). Sin palabra de género: depende de miniatura y descripción para que se entienda que es de pesca. |
| **B (si G1 muestra poco icono→visita o poca búsqueda)** | **Fish & Fortune: Cozy Fishing** | **Fish & Fortune: Pesca Relajante** | Añade la palabra de género que la gente escribe al buscar ("fishing/pesca") y el tono real del juego (tranquilo, coleccionista). | "Cozy" está muy usado en 2026; poca diferenciación. Cambiar el título a mitad de prueba mezcla cohortes: hacerlo solo tras G1. |
| **C (solo si el balance cambia)** | **Fish & Fortune: Catch a Mythic** | **Fish & Fortune: Atrapa un Mítico** | Pone en el título el momento clipable (el aviso de Mítico). Mejor clic esperable. | **Sobre-promete con el balance actual:** un Mítico pesa 0,4 sobre ~936–999 por zona ≈ **0,04 % por lanzada** (1 de cada ~2.500) con suerte 0 [`Balance.luau`]. Un título que promete atrapar uno sube el rebote de primera sesión (señal negativa [OFICIAL‡ `07` §3.1]) y roza metadatos engañosos [OFICIAL `discovery.md`]. **Recomendación: descartarlo** salvo que los Míticos se vuelvan alcanzables en una sesión. |

### Notas del chequeo de nombres (no sustituyen la verificación manual)

1. **"Fortune" y recompensa económica [IDEA PROPIA, sobre regla OFICIAL]:** la regla dice que "metadata that implies any type of monetary reward is not prioritized". "Fortune" no es "Robux gratis", pero para quitar dudas: en **miniaturas y descripción no usar monedas, billetes, "rico/riqueza", "gana", "premio"**, y mostrar pesca y criaturas, no dinero. Si G1 muestra impresiones raras, el título B o C no cambia esto: cambiaría el nombre de marca (plan B de marca: ver prompts-ia.md §1, alternativas "Tidewater Tales", "Lagoon Legends" también por verificar).
2. **Búsqueda web hecha hoy (1 consulta, mode standard, US-only) [TERCERO/NO VERIFICADO]:** no apareció ningún juego de Roblox llamado exactamente "Fish & Fortune". Sí aparecieron juegos de pesca con nombres cercanos: **Fisch** (muy conocido, con un objeto "Fortune Rod" según una guía de terceros) y **Fish and Fight**. Una sola búsqueda no prueba que el nombre esté libre.
3. **Asociación con "fish table games" [NO VERIFICADO, conocimiento previo]:** en EE. UU. existe un género de máquinas/apps de azar con dinero llamadas "fish games / fish tables" y nombres con "Fortune". Roblox prohíbe apuestas jugables incluso simuladas [OFICIAL, `03` §2.2]. Mitigación: nada de ruedas, máquinas, dados, cofres que giran ni estética de casino en ningún material; el juego es pesca + colección.
4. **[VERIFICAR a mano en Roblox]** antes de fijar el nombre: buscar en Discover (con sesión iniciada, en EN y ES) "Fish & Fortune", "Fish and Fortune", "Fishing Fortune", "Fortune Fish", "Fortune Fishing"; comprobar que no hay juego, grupo ni usuario conocido con el nombre; mirar el grupo propio y el @ de redes.
5. **[VERIFICAR a mano]** marcas registradas: USPTO (TESS / "Trademark Search"), EUIPO (eSearch plus) y WIPO Global Brand Database, buscando "FISH & FORTUNE" y variantes en clases 9, 28 y 41 (software/juegos). Roblox elimina contenido que infringe marcas aunque lo haya hecho una IA [OFICIAL, `ip-guidelines.md`]. No es asesoría legal.
6. **Localización:** el nombre, la descripción, el ícono y las miniaturas se pueden localizar por idioma (un ícono por idioma [OFICIAL, `experience-icons.md`]). Recomendado: título A igual en todos; B/C localizados.

---

## 2. Descripciones (ES / EN)

Reglas aplicadas: sin promesas de Robux gratis ni palabras de recompensa económica; sin superlativos no comprobables ("el mejor", "el #1"); sin urgencia falsa; sin URL de redes ni invitación de Discord en el texto (las redes van en el apartado de enlaces sociales de la página, hasta 3, solo si la cuenta es 16+ verificada [OFICIAL, `social-media-links.md`]); dice la verdad sobre las compras. Límite de caracteres de la descripción: **[VERIFICAR en Creator Hub]** (cifra de memoria 1.000 [NO VERIFICADO]; las largas de abajo miden menos de 1.000).

### 2.1 Descripción corta (para bio de TikTok/YouTube, anuncios, Discord y "about" del grupo)

**ES (≈155 caracteres):**
> Pesca en lagos compartidos, completa tu bestiario y descubre criaturas raras. Si alguien pesca un Mítico, el servidor lo ve. Gratis, con compras opcionales.

**EN (≈157 characters):**
> Fish in shared lakes, fill your bestiary and discover rare creatures. When someone catches a Mythic, the whole server sees it. Free, with optional purchases.

### 2.2 Descripción larga para la página del juego

**ES**
```
Fish & Fortune es un juego de pesca relajante para jugar solo o con amigos.

Lanza la caña, supera el minijuego y descubre qué ha picado. Cada criatura que pescas se guarda en tu bestiario, y cada zona esconde criaturas distintas.

QUÉ PUEDES HACER
• Pescar en lagos compartidos con otros jugadores.
• Completar tu bestiario (25 criaturas en esta versión).
• Mejorar tu caña y explorar 3 zonas: Lago Calmo, Río Cristal y Costa Dorada.
• Ver un aviso en pantalla cuando alguien pesca una criatura Mítica (son rarísimas).
• Participar en eventos semanales y canjear códigos oficiales.

TRANSPARENCIA
• Es gratis. Hay compras opcionales con Robux.
• Las probabilidades de cada criatura se muestran en el panel Probabilidades. [AJUSTAR A LO REAL: la lógica ya existe; confirmar que la UI lo muestra]
• Los eventos y los códigos indican siempre sus fechas reales.

Tus ideas cuentan: cuéntanos qué te gustaría ver en las novedades (enlaces de la comunidad en esta página).
```

**EN**
```
Fish & Fortune is a relaxing fishing game to play solo or with friends.

Cast your line, beat the mini-game and find out what bit. Every creature you catch goes into your bestiary, and every zone hides different creatures.

WHAT YOU CAN DO
• Fish in shared lakes with other players.
• Fill your bestiary (25 creatures in this version).
• Upgrade your rod and explore 3 zones: Calm Lake, Crystal River and Golden Coast.
• See an on-screen notice when someone catches a Mythic creature (they are extremely rare).
• Join weekly events and redeem official codes.

TRANSPARENCY
• Free to play. Optional purchases with Robux.
• Each creature's catch chance is shown in the Probabilities panel. [ADJUST TO REALITY: the logic exists; confirm the UI shows it]
• Events and codes always show their real dates.

Your ideas matter: tell us what you want to see in future updates (community links on this page).
```
(Quitar los marcadores `[AJUSTAR…]` antes de pegar en Creator Hub. Nombres en inglés de las zonas: Calm Lake / Crystal River / Golden Coast, traducción mía: confirmar el nombre EN oficial en el juego.)

### 2.3 Lo que NO debe aparecer (lista de verificación del texto)

- **"Suerte", "Suerte+", "Cebo de Suerte", "más probabilidad de Míticos" como producto:** el catálogo del juego incluye el Pase Suerte+ y el Cebo de Suerte (alteran probabilidades), que son objetos aleatorios de pago y **no se promocionan** (un pase promocionado no puede dar objetos aleatorios de pago [OFICIAL `passes.md` vía `03` §2.1]; decisión D9: sin suerte en v1). Los pases de la página/anuncios deben ser Auto-Pesca, 2x Dinero, VIP, Pack de inicio o Temporada 1 (premios fijos).

- "Robux gratis", "free Robux", "gana Robux", "sorteo", "giveaway", "regalo de Robux".
- "El mejor juego de pesca", "#1", "viral", "nuevo récord" (afirmaciones no verificables).
- "Última oportunidad", "solo hoy", cuentas atrás falsas. Los eventos y códigos reales sí pueden decir su fecha de fin.
- Nombres de otros juegos de pesca, de creadores o de marcas (metadatos engañosos o de IP ajena).
- Texto repetido o palabras clave sueltas ("fishing fishing simulator tycoon codes") → degradación por metadatos spam [OFICIAL, `publish-games-and-places.md` vía `03` §6].
- Cualquier insinuación de apuesta (suerte, jackpot, apuesta, casino).

---

## 3. Género, etiquetas y ajustes de la página

Los docs que pude leer no listan los géneros ni los límites de campos [OFICIAL: ausencia en `configure-games.md`]; los nombres exactos de los selectores son **[VERIFICAR en Creator Hub]**.

| Campo | Valor recomendado | Razón |
|---|---|---|
| Género principal | Simulador / "Idle & Collection" si existe; si no, el más cercano a "Simulator" | Es lo que realmente es (bucle de coleccionar y mejorar). No elegir un género solo porque está de moda (metadato desajustado) |
| Etiquetas / temas (si el selector las admite) | fishing, collecting, relaxing/cozy, co-op/friends | Descriptivas y ciertas; máximo las que apliquen |
| Dispositivos | Móvil, tablet, PC (y consola solo si la UI se probó con mando) | Diseño móvil-primero [decisión D6/`07` §6.1] |
| Jugadores por servidor | El número que use el juego | [AJUSTAR A LO REAL] (no está en el código leído) |
| Madurez | Cuestionario completo respondiendo con "el contenido más maduro que un jugador puede encontrar" [OFICIAL, `03` §3.2]; objetivo Minimal/Mild; sin chat libre ni "hangouts" (decisión D11) | Una respuesta inexacta puede moderar el juego y la cuenta |
| Servidores privados | Sí, a 199 R$ (concepto 1) [AJUSTAR A LO REAL] | Producto de co-juego |
| Enlaces sociales | Hasta 3 (grupo de Roblox, YouTube, Discord), solo desde la página; la cuenta debe ser 16+ verificada | [OFICIAL] `social-media-links.md` |
| Localización | Nombre + descripción + ícono + miniaturas en ES y EN | Mercado hispano y global |
| IA en el juego | Ninguna prevista; si algún día hay, declararla en el cuestionario [OFICIAL, `generative-AI.md`] | |
| Tarifa / Plus para llegar a Kids/Select | Decisión D10 del plan (ver `plan-90-dias.md`) | Sin ella, un juego nuevo solo llega a 16+ verificados [OFICIAL, `03` §1.2] |

---

## 4. Texto para miniaturas

Reglas: máximo 3 palabras + logo; legible a 320×180 px; sin números, sin precios, sin "gratis", sin "Robux"; que describa algo que **existe en el juego**; nada esencial en el borde inferior (el recuento de jugadores puede taparlo [OFICIAL, `thumbnails.md`]).

| Uso | ES | EN | Se corresponde con |
|---|---|---|---|
| Miniatura 1 (hero) | ¿UN MÍTICO? | A MYTHIC? | Aviso de Mítico (pregunta, no promesa: son ≈ 0,04 % por lanzada) |
| Miniatura 2 | COMPLETA EL BESTIARIO | FILL THE BESTIARY | Bestiario (25 criaturas) |
| Miniatura 3 | PESCA CON AMIGOS | FISH WITH FRIENDS | Co-juego [AJUSTAR A LO REAL: no confirmado en el código leído] |
| Miniatura 4 | EXPLORA 3 ZONAS | EXPLORE 3 ZONES | Lago Calmo, Río Cristal, Costa Dorada |
| Evento (solo con evento real) | NUEVO EVENTO | NEW EVENT | Una miniatura de evento admite hasta 5 [OFICIAL, `discovery.md`] |
| Logo (en todas) | FISH & FORTUNE | FISH & FORTUNE | Marca |

El texto **no** se genera con la IA de imagen salvo en Ideogram/gpt-image-2: lo seguro es generar la imagen sin texto y componerlo después (Figma/Canva/Photopea) con la tipografía de marca (Fredoka 700, ver `prompts-ia.md`), para controlar la ortografía y la localización [`05` §4.2].

---

## 5. Cinco ideas de ícono / miniatura con prompts de IA

**Formato de trabajo (ver §6 para las reglas oficiales).** Generar a 1024×1024 (ícono) o 1920×1080 / 16:9 (miniatura) y exportar a 512×512 y 1920×1080. **Margen del círculo:** aunque el ícono del juego es cuadrado [OFICIAL], los íconos de pases y productos se recortan a círculo [OFICIAL, `passes.md`] y el ícono del juego baja a ~150×150 [OFICIAL]: diseñar siempre con todo lo importante dentro de un **círculo de 460 px de diámetro (radio 230) centrado en el lienzo de 512** (≈ 90 %), y las esquinas con fondo continuo (sin elementos que solo vivan en la esquina). Probar el ícono a 150×150 y a 110×110 antes de subirlo [IDEA PROPIA, consejos de blogs [NO VERIFICADO]].

**Plantilla de prompt (bloques reutilizables en `prompts-ia.md` §2):**
`[SUJETO] + [ESCENA] + STYLE_BLOCK + PALETTE_BLOCK + COMPOSITION + NEGATIVE`
- `STYLE_BLOCK`: "stylized 3D cartoon render, soft rounded shapes, smooth shading, bright cozy lighting, clean silhouette readable at small size, saturated but not neon"
- `PALETTE_BLOCK`: "deep navy blue #0A1F44, lagoon teal #19C3C0, sunlit gold #FFC83D, coral orange #FF7A59, foam white #F4FBFF"
- `NEGATIVE`: "text, letters, watermark, logo, signature, real brands, copyrighted characters, human faces, photorealism, casino, slot machine, dice, playing cards, coins, banknotes, gambling, blood, scary"

Regla de oro [OFICIAL, `thumbnails.md` y `discovery.md`]: la miniatura debe mostrar imagen **única y relevante para lo que el jugador va a experimentar**. Por eso cada idea tiene dos fases: (1) arte de IA para el fondo/hero y (2) **recomposición con capturas reales del juego** cuando exista (banner, bestiario, caña). Nunca mostrar criaturas, zonas ni UI que el juego no tenga.

### Idea 1 — "El Mítico emerge" (hero principal, ícono y miniatura)
- **Concepto:** una criatura gigante y luminosa (ballena de luz) emerge del lago al atardecer; abajo, Fortu (la mascota) con la caña doblada, mirando hacia arriba.
- **Ícono (1:1):** primer plano de la criatura y Fortu, criatura centrada, ojos grandes, brillo dorado. **Miniatura (16:9):** más lago y cielo, criatura a la derecha, Fortu a la izquierda, texto "¿UN MÍTICO?" arriba a la izquierda.
- **Prompt (ícono):**
  `Square game icon. A giant glowing whale-like mythic sea creature rising from a calm lake at golden hour, bioluminescent teal and gold patterns on its body, in front of it a small round golden koi-like fish mascot wearing a tiny teal knitted beanie, holding a bent fishing rod, looking up in awe. Subject centered inside a circle occupying 90% of the frame, simple background of sunset sky, solid color fill extending to all four corners. stylized 3D cartoon render, soft rounded shapes, smooth shading, bright cozy lighting, clean silhouette readable at small size, saturated but not neon. deep navy blue #0A1F44, lagoon teal #19C3C0, sunlit gold #FFC83D, coral orange #FF7A59, foam white #F4FBFF. no text, no letters, no watermark, no real brands, no copyrighted characters, no human faces, no photorealism, no casino, no coins.`
- **Parámetros:** gpt-image-2: `size 1024x1024`, calidad media. Ideogram: `1:1`, estilo "3D render" o "design" sin texto. Midjourney: añadir `--ar 1:1 --style raw --no text`.
- **Miniatura 16:9:** mismo prompt cambiando la primera frase por `Wide 16:9 game key art.` y `composition: creature on the right third, mascot on the left third, open sky area top-left for a title, keep the bottom 15% of the frame empty of important elements`.

### Idea 2 — "Aviso global" (el momento clipable)
- **Concepto:** miniatura que cuenta el gancho del juego: un lago con 3 pescadores pequeños en un muelle de madera y un destello dorado en el agua; el banner de "X pescó un MÍTICO" se **añade con la captura real del banner** (no se pinta con IA, porque debe ser idéntico al del juego).
- **Prompt (fondo):**
  `Wide 16:9 key art. A cozy wooden fishing dock on a calm lake at golden hour, three small friendly silhouette fishers with rods seen from behind, a bright golden shimmer rising from the water near the end of the dock, soft sun rays, empty sky band across the top third reserved for a banner. stylized 3D cartoon render, soft rounded shapes, smooth shading, bright cozy lighting, clean silhouette readable at small size, saturated but not neon. palette deep navy #0A1F44, lagoon teal #19C3C0, sunlit gold #FFC83D, coral orange #FF7A59, foam white #F4FBFF. no text, no letters, no watermark, no real brands, no human faces, no photorealism, no casino, no coins, bottom 15% plain water.`
- **Capa real:** captura del banner de Mítico dentro del juego, colocada en la banda superior, sin retocar su texto. Texto de marca "¿UN MÍTICO?" solo si el banner no lo incluye ya.

### Idea 3 — "Bestiario" (coleccionismo)
- **Concepto:** cuadrícula 3×2 de seis criaturas con borde de color por rareza y una "página" de libro como fondo; refuerza "completa la colección". Sirve de ícono si se recorta a 3 criaturas.
- **Prompt:**
  `Wide 16:9 key art. An open illustrated field guide book seen from above on a deep navy background, six different original cartoon fish and sea creatures displayed in framed slots, each slot with a glowing colored border (gray-blue, green, blue, purple, gold, magenta) to show rarity, one slot is a silhouette with a question mark shape (unknown creature), warm sunlit gold sparkles. stylized 3D cartoon render, soft rounded shapes, smooth shading, bright cozy lighting, clean silhouettes. palette deep navy #0A1F44, lagoon teal #19C3C0, sunlit gold #FFC83D, coral orange #FF7A59, foam white #F4FBFF. no text, no letters, no numbers, no watermark, no real brands, no copyrighted characters, no photorealism, no casino.`
- **Capa real:** sustituir las 6 criaturas generadas por las criaturas reales del juego (capturas del bestiario). Si no coinciden, **no** usar esta miniatura.

### Idea 4 — "Pesca con amigos" (co-juego)
- **Concepto:** atardecer cálido, muelle largo con 4 siluetas distintas pescando juntas, una caña doblada; transmite lagos compartidos y co-juego (señal que premia el algoritmo [OFICIAL‡ `07` §3.1]).
- **Prompt:**
  `Wide 16:9 key art. Four small friendly cartoon silhouettes of different fishers sitting and standing together on a long wooden pier at sunset, one rod bending as a golden fish splashes out of the water, lanterns glowing, warm teal and gold sky reflected in the lake, relaxing cozy mood. stylized 3D cartoon render, soft rounded shapes, smooth shading, bright cozy lighting, clean silhouettes readable at small size, saturated but not neon. palette deep navy #0A1F44, lagoon teal #19C3C0, sunlit gold #FFC83D, coral orange #FF7A59, foam white #F4FBFF. no text, no letters, no watermark, no real brands, no copyrighted characters, no human faces, no photorealism, no casino, no coins, no alcohol, bottom 15% plain water.`
- **Capa real:** si hay captura de 3-4 avatares reales en un muelle del juego, usarla en lugar de las siluetas.

### Idea 5 — "Fortu" (ícono con mascota, el más legible a 110 px)
- **Concepto:** primer plano de la mascota con la caña y el destello; ojos grandes, fondo teal liso con un solo halo dorado. Es el candidato a ícono por contraste y sujeto único.
- **Prompt:**
  `Square game icon, close-up portrait of a chubby round golden koi-like fish mascot with glossy honey-gold scales, a single small star-shaped scale on the left cheek, big friendly dark eyes with white highlights, rounded coral-orange fins, wearing a tiny teal knitted beanie, smiling gently, holding a small fishing rod with a bobber. Centered inside a circle occupying 90% of the frame, smooth lagoon teal #19C3C0 background with a soft warm golden halo behind the head, solid color extending to all four corners. stylized 3D cartoon render, soft rounded shapes, smooth shading, bright cozy lighting, clean silhouette readable at 110 pixels, saturated but not neon. palette deep navy #0A1F44, lagoon teal #19C3C0, sunlit gold #FFC83D, coral orange #FF7A59, foam white #F4FBFF. no text, no letters, no watermark, no real brands, no copyrighted characters, no human faces, no photorealism, no casino, no coins.`
- **Importante:** la mascota debe parecerse al arte que el jugador verá dentro del juego. Si el juego usa avatares de Roblox y arte distinto, la miniatura engaña por estilo. Decisión: mostrar la mascota solo si aparece en el juego (pantalla de carga, bestiario, NPC). **[AJUSTAR A LO REAL]**.

### Plan de prueba de íconos/miniaturas (conecta con el plan de anuncios)
Variantes A/B/C para G1 (3 días, mismo presupuesto por variante): **A = Idea 1**, **B = Idea 5**, **C = Idea 3 o 4** (la que tenga capturas reales). Ver `plan-lanzamiento.md` §6. Crea todas antes de L-3 por la moderación (assets hasta 48 h [OFICIAL, `ads-manager.md`]). Un thumbnail **personalizado es obligatorio** para recibir impresiones en recomendaciones de la home [OFICIAL, `discovery.md`].

---

## 6. Checklist técnico de ícono, miniaturas y vídeo (según documentación oficial, leída hoy)

Fuentes [OFICIAL], consultadas el 2026-10-20 en `Roblox/creator-docs`: `production/publishing/experience-icons.md`, `production/publishing/thumbnails.md`, `discovery.md`, `production/promotion/ads-manager.md`, y (de `ROBLOX/research/05` §2) `passes.md` y `developer-products.md`. Las rutas web equivalentes están en create.roblox.com (bloqueado desde esta red): **[VERIFICAR a mano]** que la web publicada coincide con el espejo antes de subir.

### Ícono del juego
- [ ] Cuadrado, **mínimo 512×512 px** (plantilla de 512×512 para alta resolución). Una versión por idioma.
- [ ] Se reduce a ~**150×150 px** en algunos sitios: revisarlo a ese tamaño (y a 110×110 [NO VERIFICADO]).
- [ ] Tipo de medio "Image" al subir; ruta: Creator Dashboard > Configurations > Places > lugar inicial > Icon.
- [ ] Pasa moderación antes de que lo vean otros. Se genera uno automático al publicar por primera vez.
- [ ] Un solo sujeto, alto contraste, sin elementos ambiguos en las esquinas; transmite el tema/género.
- [ ] No especificado en el doc: formatos aceptados, peso máximo, recorte (círculo u otro), reglas de texto → **[VERIFICAR a mano]**. Prudencia: PNG o JPG, <3 MB, sin texto salvo el logotipo.

### Miniaturas (página del juego)
- [ ] **16:9, ideal 1920×1080 px.** Si no es 16:9, se estira a 16:9 (se deforma).
- [ ] Formatos: `.jpg`, `.gif`, `.png`, `.tga`, `.bmp`. Gratis.
- [ ] Hasta **10 imágenes o vídeos** por página. Moderación de todas.
- [ ] Personalización de Home: 2 a 5 miniaturas activas; **menos de 3 MB** y 1920×1080 cada una. Con una sola activa se muestra a todos.
- [ ] **Imagen personalizada obligatoria** para recibir impresiones de recomendaciones de la home.
- [ ] Sin elementos esenciales en el **borde inferior** (el recuento de jugadores puede taparlo).
- [ ] Imagen original/propia, única y que refleje el juego real ("todas las miniaturas deben reflejar tu juego con exactitud").
- [ ] Sin lenguaje que insinúe recompensa económica; sin palabras fuertes (metadatos de juego incluidos).
- [ ] Hasta 10 miniaturas **16:9 por campaña de anuncios**; el anuncio **es** la miniatura (no hay reglas de texto publicadas: aplicar las de la página) [OFICIAL, `ads-manager.md`].

### Vídeo de la página del juego (no confundir con los de TikTok)
- [ ] Cuota gratuita **3 subidas al mes**; los rechazados cuentan.
- [ ] Debe ser **juego auténtico**: nada de mecánicas, UI o interacciones que el juego no tenga; sin gráficos mejores que los reales.
- [ ] **Prohibido:** voz en off o narración, música con letra, imágenes de la vida real, texto promocional o afirmaciones subjetivas ("50 % off", "Free UGC!"). Texto superpuesto: poco y solo para describir el juego.
- [ ] **Permitido:** logotipo superpuesto, texto de UI del juego, cámara libre, retoques menores, música del catálogo de Roblox, secuencias "highlight".
- [ ] No soportado en Xbox, PlayStation ni VR. No se indica duración ni peso máximos.
- [ ] Los vídeos con IA (Veo/Kling/Runway) y los renders del pipeline (`specs-video/`) **no valen para la página**: son gráficos, no juego. Solo para TikTok/Shorts/Reels/Discord.
- [ ] Contenido de IA en miniaturas: el doc no menciona IA; vale la regla general de no engañar. Si usas imagen de IA, composita con capturas reales y revisa que no copie IP ajena.

### Íconos de pases y productos (de `ROBLOX/research/05`)
- [ ] Máximo 512×512, `.jpg/.png/.bmp`, **recorte en círculo**: lo importante dentro del círculo. Roblox recomienda un ícono propio por producto. Nada de arte de azar (ruedas, cofres que giran) en pases promocionados.

### Antes de subir
- [ ] Revisar cada imagen contra marcas y personajes conocidos (IP) [OFICIAL, `ip-guidelines.md`: el contenido alterado por IA puede denunciarse].
- [ ] Guardar los prompts y las capturas de origen (prueba de originalidad).
- [ ] Subir con 3 días de margen antes de L y antes de cualquier campaña (moderación de assets hasta 48 h).
