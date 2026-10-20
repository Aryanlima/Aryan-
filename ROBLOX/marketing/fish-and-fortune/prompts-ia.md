# Fish & Fortune — Brand kit y librería de prompts de IA (imagen, vídeo, música, voz)

Fecha: 2026-10-20. Idioma del documento: español; los prompts van en **inglés** (los modelos de imagen/vídeo/música responden mejor) con nota en español. Sin IP ajena: ningún prompt nombra marcas, estudios, artistas vivos, personajes ni juegos.

Etiquetas: **[OFICIAL]**, **[TERCERO]**, **[NO VERIFICADO]**, **[IDEA PROPIA]**. Todo lo que dependa del juego construido lleva **[AJUSTAR A LO REAL]**. Contexto de licencias y herramientas: `ROBLOX/research/05` (resumido en §7).

---

## 1. Brand kit

### 1.1 Nombre, lema y alternativas
- **Nombre de trabajo:** **Fish & Fortune** (ver el chequeo de nombre y los riesgos en `pagina-del-juego.md` §1: **[VERIFICAR a mano en Roblox y en registros de marcas]**).
- **Lema ES:** "Pesca. Colecciona. Descubre." · **EN:** "Cast. Collect. Discover." [IDEA PROPIA]
- **Alternativas de marca si el nombre falla** (todas **[VERIFICAR]**, no comprobadas): *Lagoon Legends*, *Tidewater Tales*, *Mythic Waters*.
- **Qué comunica:** pesca tranquila, colección de criaturas, momento de sorpresa compartida (el Mítico). **No** comunica dinero, azar de casino ni "hazte rico".

### 1.2 Mascota: **Fortu**
- **Qué es:** un pececillo dorado regordete, tipo koi, con un gorrito de punto azul-verdoso, que acompaña al jugador. Es la "cara" del juego en íconos, redes y tutorial.
- **Rasgos fijos (para que la IA los repita):** cuerpo redondo; escamas color miel dorada con brillo suave; **una pequeña escama en forma de estrella en la mejilla izquierda**; ojos grandes, oscuros, con brillo blanco; aletas redondeadas color coral; gorrito de punto teal; sonrisa suave; a veces con una caña diminuta con boya.
- **Personalidad:** curiosa, paciente, un poco despistada, nunca presiona. Frases de ejemplo: "¿Probamos una más?", "Mira, algo se mueve en el agua".
- **No hacer:** darle ojos "de dólar", monedas, cartas, dados o gestos de apostar; ponerle voz de bebé; usarla para meter prisa a comprar; cambiar de color por escena.
- **Originalidad:** diseño propio y simple; evitar parecidos con peces de películas o franquicias conocidas [OFICIAL: el contenido de IA que reproduce IP ajena puede denunciarse, `ip-guidelines.md`]. **Revisar cada imagen generada** contra personajes conocidos.
- **Aparece en el juego?** [AJUSTAR A LO REAL] Solo usarla en miniaturas si el arte del juego la incluye o es coherente con él (`pagina-del-juego.md` §5, idea 5).

### 1.3 Paleta (códigos HEX)

| Rol | Nombre | HEX | Uso | Contraste sobre Azul Abismo #0A1F44 |
|---|---|---|---|---|
| Fondo principal | **Azul Abismo** | `#0A1F44` | Fondos, pantallas, cielos | — |
| Fondo secundario | **Azul Océano** | `#0F6E9E` | Degradados, agua | — |
| Acento 1 | **Teal Laguna** | `#19C3C0` | Botones secundarios, destellos | 7,4 : 1 |
| Acento 2 (marca) | **Oro Sol** | `#FFC83D` | Palabras clave, "Fortune", CTA | 10,5 : 1 |
| Acento 3 | **Coral** | `#FF7A59` | Detalles, aletas, avisos suaves | 6,3 : 1 (texto navy sobre coral 6,3 : 1; **no** texto blanco sobre coral: 2,6 : 1) |
| Texto/claro | **Espuma** | `#F4FBFF` | Texto sobre fondos oscuros | 15,5 : 1 |
| Texto oscuro | **Tinta** | `#10182B` | Texto sobre fondos claros | (sobre Espuma 16,9 : 1) |
| Éxito | **Alga** | `#3CCB7F` | Confirmaciones | 7,8 : 1 |
| Error | **Coral rojo** | `#FF5C73` | Errores | 5.4 : 1 |

Contrastes calculados con la fórmula WCAG 2.1 (cálculo propio, 2026-10-20). **Colores de rareza** (para el bestiario, las miniaturas y los vídeos) y su contraste sobre `#0A1F44`:

| Rareza | HEX | Contraste |
|---|---|---|
| Común | `#9FB3C8` | 7,6 : 1 |
| Poco común | `#4CD38A` | 8,5 : 1 |
| Raro | `#3FA2FF` | 6,1 : 1 |
| Épico | `#A66BFF` | 4,8 : 1 |
| Legendario | `#FFB020` | 8,9 : 1 |
| **Mítico** | `#FF4FB8` | 5,5 : 1 |

Regla: **la rareza nunca se indica solo con el color** (daltonismo): añadir forma/icono/etiqueta (estrellas, marco distinto) [IDEA PROPIA]. Los nombres de rareza son los del concepto; confirmar con el juego [AJUSTAR A LO REAL].

### 1.4 Tipografías libres (licencia SIL Open Font License)
- **Títulos:** **Fredoka** (peso 600–700). Descargada en `specs-video/fonts/Fredoka.ttf` con su licencia `OFL-Fredoka.txt` (desde `google/fonts`, 2026-10-20). Alternativas OFL: Baloo 2, Lilita One.
- **Texto:** **Nunito** (peso 400–800). Descargada en `specs-video/fonts/Nunito.ttf` con `OFL-Nunito.txt`.
- **Notas:** son fuentes libres para uso comercial bajo OFL (se pueden incrustar y redistribuir con su licencia). En Roblox Studio las fuentes se eligen del catálogo de Roblox; Roblox incluye una fuente redonda de aspecto similar a Fredoka [NO VERIFICADO: comprobar el nombre en el selector de fuentes]. El pipeline de vídeo ya las usa (`typography` + `fonts`).

### 1.5 Estilo visual
- **3D cartoon suave:** formas redondeadas, sombreado limpio, luz cálida de atardecer, colores saturados pero no neón; siluetas legibles a 110 px.
- **Mundo:** lagos tranquilos, muelles de madera, linternas, neblina suave, luz dorada; criaturas simpáticas con brillo según rareza; nada de terror, sangre o casino.
- **Composición:** un sujeto principal, fondo sencillo, borde inferior libre (el recuento de jugadores puede tapar la parte baja de la miniatura [OFICIAL `thumbnails.md`]).
- **Prohibido en cualquier pieza:** monedas/billetes como motivo central, ruedas, máquinas, dados, cartas, estética de casino; marcas reales; personajes con derechos; rostros humanos realistas; mensajes de "gana/regalo".

### 1.6 Voz de marca (texto)
- **Tono:** amable, tranquilo, curioso, inclusivo; humor ligero; frases cortas; tuteo. ES neutro latinoamericano; EN sencillo (nivel B1).
- **Reglas:** nada de MAYÚSCULAS salvo etiquetas cortas; sin presión ("¡compra ya!"); sin superlativos que no se puedan comprobar; sin promesas de Robux; fechas reales.

| Sí | No |
|---|---|
| "¿Probamos una más?" | "¡Última oportunidad, no te lo pierdas!" |
| "Revisa tu bestiario antes de vender." | "¡Compra ya y consigue el mejor pez!" |
| "Hay compras opcionales con Robux." | "¡Gana Robux gratis!" |
| "Un Mítico se anuncia a todo el servidor." | "Todos se hacen ricos pescando." |

### 1.7 Voz hablada (TTS o voz propia)
- **Perfil:** cálida, cercana, ritmo medio (150–160 palabras/min), sonrisa suave; no infantil, no locutor de anuncios; género neutro a elección. Para ES, acento neutro; para EN, estándar.
- **Dirección para el modelo de voz** (ElevenLabs u otro con licencia comercial; el alcance exacto de la licencia para juegos hay que confirmarlo [NO VERIFICADO, `05` §5]): "Warm, friendly and calm, medium pace, gentle smile in the voice, curious tone, clear articulation, no exaggerated hype, no baby voice."
- **Ejemplo de lectura (ES, 12 s):** "Lanza la caña, espera la picada y descubre qué ha aparecido en el lago. ¿Será un Mítico?"
- **Pronunciación:** "Fish & Fortune" se lee "fish an' fortune" (EN) y "fish and fortune" (ES); fijarlo en el guion para que no varíe.
- **Etiqueta:** voz sintética realista = contenido de IA; divulgar donde la plataforma lo pida (`guiones-videos.md` §0).

### 1.8 Logotipo (wordmark)
- Texto "Fish & Fortune" en Fredoka 700; "&" en Oro Sol `#FFC83D`; el resto en Espuma `#F4FBFF`; contorno Azul Abismo `#0A1F44`; un pececito dorado (Fortu en perfil) nadando por el "&". Zona de respeto = altura de la "F" alrededor; versión monocroma blanca y versión oscura.
- No usar el logotipo ni el nombre de Roblox como parte del logo propio; el texto "en Roblox" en una frase es normal [NO VERIFICADO: revisar las guías de marca de Roblox antes de usar su logo].

---

## 2. Bloques de prompt reutilizables

Fórmula: **`[SUJETO] + [ESCENA] + STYLE_BLOCK + PALETTE_BLOCK + COMPOSITION + NEGATIVE`**. Los bloques son texto fijo que se pega igual en todos los prompts (así el estilo es coherente).

```
STYLE_BLOCK:
stylized 3D cartoon render, soft rounded shapes, smooth shading, bright cozy lighting,
clean silhouette readable at small size, saturated but not neon

PALETTE_BLOCK:
deep navy blue #0A1F44, ocean blue #0F6E9E, lagoon teal #19C3C0, sunlit gold #FFC83D,
coral orange #FF7A59, foam white #F4FBFF

CHARACTER_FORTU:
a chubby round golden koi-like fish mascot with glossy honey-gold scales, a single small
star-shaped scale on the left cheek, big friendly dark eyes with white highlights,
rounded coral-orange fins, wearing a tiny teal knitted beanie, gentle smile

WORLD_BLOCK:
a calm lake at golden hour, wooden fishing docks, glowing lanterns, soft mist,
friendly cartoon fish and sea creatures, relaxing cozy mood

NEGATIVE_IMAGE:
text, letters, numbers, watermark, logo, signature, real brands, copyrighted characters,
human faces, photorealism, casino, slot machine, dice, playing cards, coins, banknotes,
gambling, blood, scary, extra limbs, distorted, low quality

NEGATIVE_VIDEO:
text, subtitles, captions, watermark, logo, real brands, copyrighted characters, human faces,
realistic photo, horror, blood, casino, slot machine, dice, coins, gambling, flicker,
morphing artifacts, sudden cuts
```

**Consejos por herramienta** [TERCERO, de reseñas de 2026 vía `05` §4.1; **probar antes de pagar**]:
- **gpt-image-2 (API):** buen seguimiento de instrucciones y texto; pega el prompt completo; negativos como frase "Avoid: …". Calidad media basta para pruebas (~0,05 USD/imagen [TERCERO]).
- **Ideogram:** el mejor para el logotipo/texto; elegir "sin texto" para íconos y escribir el texto después.
- **Midjourney:** estética premium; usar `--no text, letters, coins, casino` y `--ar` según el formato; para personaje consistente usar `--cref` con la imagen de Fortu.
- **Flux klein 4B (Apache 2.0):** solo esa variante tiene licencia comercial abierta [OFICIAL, `05`]; el resto de Flux 2 (dev) es no comercial.
- **Recraft (plan de pago):** vectores/iconos con estilo coherente; el plan gratis no tiene licencia comercial [TERCERO].

**Flujo para un personaje consistente:** 1) generar una **hoja de personaje** (§3.1) y elegir una; 2) guardarla como referencia; 3) en cada prompt posterior, adjuntarla como imagen de referencia y pegar `CHARACTER_FORTU`; 4) revisar a mano ojos, estrella de la mejilla y gorrito (las tres cosas que la IA suele cambiar).

**Registro de prompts (obligatorio):** guardar para cada pieza usada en producción: ID, herramienta y versión/modelo, fecha, prompt exacto, semilla (si hay), imagen de referencia, plan/licencia usado, quién la revisó y comparación con IP ajena. Sirve de prueba de originalidad ante una denuncia [OFICIAL: Roblox retira contenido infractor aunque lo haya hecho una IA; `03` §4].

---

## 3. Librería de prompts de imagen

Tamaños: generar al doble y reducir. Íconos: 1024×1024 → 512×512. Miniaturas: 1920×1080 (16:9). Todos con `NEGATIVE_IMAGE`.

### 3.1 Hoja de personaje de Fortu (3 vistas)
`Character turnaround sheet on a plain flat teal background: front view, side view and three-quarter view of CHARACTER_FORTU. STYLE_BLOCK. PALETTE_BLOCK. Consistent proportions across all views, full body visible, even soft lighting, no text.`
- Formato: 16:9 · Negativo: `NEGATIVE_IMAGE`.

### 3.2 Poses/expresiones de Fortu (para stickers y tutorial)
`A 3×2 grid of six poses of CHARACTER_FORTU on a plain flat teal background: happy, surprised, curious looking sideways, proud holding a small fishing rod, sleepy, waving a fin. STYLE_BLOCK. PALETTE_BLOCK. Same character design in every cell, consistent colors, no text.`

### 3.3 Logotipo (Ideogram / gpt-image-2)
`Game logo wordmark that reads exactly "Fish & Fortune", rounded friendly bold letters, the ampersand in sunlit gold #FFC83D, the other letters foam white #F4FBFF with a deep navy #0A1F44 outline, a tiny golden koi-like fish swimming through the ampersand, centered on a transparent or plain deep navy background, vector-like clean shapes, no extra text.`
- Verificar la ortografía del texto generado y recomponer en Figma con Fredoka si falla.

### 3.4 Criaturas por rareza (arte de bestiario; nombres reales de `Balance.luau`, Lago Calmo)
Plantilla: `A single original cartoon [CRIATURA] centered on a soft vignette background, [DETALLES], glowing [COLOR DE RAREZA] outline and soft aura. STYLE_BLOCK. PALETTE_BLOCK. Clean silhouette readable at 110 px, no text.`

| Rareza | Color de aura | Descripción de ejemplo (originales) |
|---|---|---|
| Común (Pececillo, Perca, Carpa) | gris-azul `#9FB3C8` | "a small round silver minnow with a plain pale belly" |
| Poco común (Branquia Azul, Bagre) | verde `#4CD38A` | "a bluegill-like sunfish with bright blue gill covers and a green-striped body" |
| Raro (Trucha Dorada) | azul `#3FA2FF` | "a trout with golden speckled scales and a soft blue glow along the fins" |
| Épico (Koi Lunar) | violeta `#A66BFF` | "a pale moon-colored koi with violet shimmer patterns and crescent-shaped markings" |
| Legendario (Carpa Ancestral) | oro `#FFB020` | "an ancient golden carp with moss on its scales and long flowing whisker-fins" |
| **Mítico** (Espíritu del Lago; también Reina del Río y Leviatán de la Marea) | magenta `#FF4FB8` | "a giant gentle whale-like lake spirit with bioluminescent patterns and a trail of tiny light particles" |

### 3.5 Fondos de zona (16:9, sin personajes)
`Wide 16:9 environment concept, [ZONA], WORLD_BLOCK adapted to the zone. STYLE_BLOCK. PALETTE_BLOCK. No characters, empty center for gameplay, bottom 15% plain.`
- **Zona 1 Lago:** `a calm mountain lake with a wooden pier, pine trees, golden hour.`
- **Zona 2 Río:** `a gentle river with mossy rocks, small wooden bridge, soft green light.` 
- **Zona 3 Costa:** `a sunny coast with a pier, shells on a beach, small waves, warm coral sky.`
- (Zonas de los 6 del concepto: cueva, volcán, abismo; solo si el juego las tiene.)

### 3.6 Íconos de pases y productos (512×512, recorte circular)
`Square icon, [OBJETO] centered inside a circle occupying 90% of the frame, simple deep navy #0A1F44 background filling all four corners, soft golden rim light. STYLE_BLOCK. PALETTE_BLOCK. One clear subject, bold shapes, no text.`
- **Auto-pesca:** `a fishing rod that casts by itself with a small glowing arrow loop`.
- **Pack de inicio:** `a small open wooden tackle box showing a rod, a float and a jar of bait`. (Sin cofres de botín ni estética de azar.)
- **VIP:** `a golden fishing hook crowned with a tiny star`.
- **Cañas cosméticas:** `a fishing rod with a [material] handle and glowing [color] tip`.
- Revisar que **no parezca una caja de botín/ruleta** (un pase promocionado no puede dar objetos aleatorios de pago [OFICIAL, `passes.md` vía `03` §2.1]).

### 3.7 Imagen de evento (plantilla; solo con evento real)
`Wide 16:9 key art, [TEMA DEL EVENTO], a cozy lake scene with [DETALLES], open sky area in the top third for a title. STYLE_BLOCK. PALETTE_BLOCK adapted to the theme (e.g. add icy light blue #BFE9FF for winter). Bottom 15% plain water.`

### 3.8 Foto de perfil de redes y servidor de Discord
`Square profile picture, close-up of CHARACTER_FORTU's face inside a circle occupying 90% of the frame, smooth lagoon teal #19C3C0 background with a soft golden halo. STYLE_BLOCK. PALETTE_BLOCK. No text.` → 512×512 (Discord) y 400×400 (TikTok) [dimensiones de plataforma: **[VERIFICAR]**].

### 3.9 Banner de Discord (16:9 → 960×540 aprox.)
`Wide banner, a long wooden pier on a calm lake at sunset with a small golden fish mascot popping out of the water, empty left third for a title. STYLE_BLOCK. PALETTE_BLOCK. No text.`

### 3.10 Portada ("cover") de TikTok/Shorts (9:16)
`Vertical 9:16 cover, [ESCENA], key subject in the center third, empty top fifth for a hook text, empty bottom fifth. STYLE_BLOCK. PALETTE_BLOCK. No text.` El texto del gancho se añade después con Fredoka 700.

---

## 4. Librería de prompts de vídeo (Veo / Kling / Runway)

Reglas: clips de 5–8 s; un solo movimiento de cámara lento; sin personas realistas; sin texto (el texto va después); siempre `NEGATIVE_VIDEO`; etiquetar como IA. **Sora no está disponible** según terceros (app cerrada 2026-04-26, API hasta 2026-09-24) [TERCERO, `05` §7.1]. Los 7 prompts completos de los guiones B están en `guiones-videos.md` (V01, V05, V09, V13, V17, V21, V28).

Plantillas:
- **Ambiente en bucle:** `Seamless looping vertical 9:16 shot, [ESCENA], locked camera, gentle motion, [SONIDO AMBIENTE], no dialogue. STYLE_BLOCK adapted for video. PALETTE_BLOCK.`
- **Revelación (reveal):** `Vertical 9:16, [ESCENA ESTÁTICA], a soft golden shimmer builds under the water, then [CRIATURA] rises slowly into view, camera pushes in slowly, no dialogue. STYLE_BLOCK. PALETTE_BLOCK.`
- **Mascota animada (imagen→vídeo):** `Use the provided mascot image as the first frame. [ACCIÓN: blinks, smiles, waves a fin], camera still, loopable 5 seconds. Keep the character design identical to the first frame.`
- **Teaser de evento:** `Vertical 9:16, [ESCENA ESTACIONAL], [EFECTO CLIMÁTICO], warm lanterns, a bright teal-and-gold shimmer pulses in the water, slow push-in, no dialogue.`

Vocabulario de cámara útil: "slow push-in", "slow tilt up", "locked camera", "gentle drift". Evitar: "fast cuts", "handheld", "shaky", "whip pan" (producen artefactos).

---

## 5. Prompts de música (y alternativas seguras)

**Regla:** Roblox exige derechos legales sobre todo audio; no hay política oficial específica para música de IA, y hay casos de audio de Suno que Roblox siguió eliminando [OFICIAL `audio/assets.md`; TERCERO `05` §5]. **Orden de preferencia:** 1) música sintetizada por el pipeline (propia), 2) Creator Store (más de 100.000 pistas y SFX gratis [OFICIAL]), 3) música de IA con licencia comercial **comprobada** el día de contratar. **Probar subiendo una pista antes de depender de ella.**

**Prompts (para la herramienta con licencia que elijas) — instrumental, sin voz:**
- **Tema principal (cozy):** `Cozy relaxing instrumental, acoustic guitar and soft marimba, gentle pizzicato strings, light hand percussion, warm and hopeful, 90 BPM, loopable, no vocals, no lyrics, no samples of existing songs.`
- **Momento Mítico (sting de 6–8 s):** `Short magical sting, rising harp glissando and soft chimes with a warm swell, bright and awe-inspiring, 7 seconds, no vocals.`
- **Evento de invierno:** `Gentle winter instrumental, celesta and soft piano with light sleigh-bell texture, calm and cozy, 80 BPM, loopable, no vocals.`
- **SFX (ElevenLabs SFX/Creator Store):** "water splash small", "fishing reel click", "soft bubble pop", "magical chime", "UI confirm".

**Estilos de música sintética del pipeline:** `chill` (88 BPM), `arcade` (128), `epic` (100), `hype` (140), generados por código (sin derechos de terceros). Los 6 vídeos ya renderizados usan `chill`, `arcade` y `epic`.

---

## 6. Prompt de guion y de voz (para escribir más textos con IA)

`Write a 20-second vertical video script in [Spanish/English] for a relaxing fishing game called Fish & Fortune. Tone: warm, curious, calm; short sentences; no hype claims; no "free Robux"; no pressure to buy; do not promise any probability or reward; mention "free to play with optional purchases" only at the end; hook in the first 2 seconds; end with "Search Fish & Fortune on Roblox". Output: hook, on-screen text, narration, call to action.`
- **Revisar siempre** que el guion no inventa cifras, probabilidades, premios ni funciones del juego.

---

## 7. Licencias, cumplimiento y controles de calidad (resumen)

| Tema | Regla | Fuente |
|---|---|---|
| IP | No se nombran marcas/personajes/artistas; revisar cada resultado; el contenido alterado con IA puede denunciarse | [OFICIAL] `ip-guidelines.md` |
| Responsabilidad | Con herramientas de IA de terceros, el creador responde de todo lo que ven los usuarios | [OFICIAL] `generative-AI.md` |
| 3D/imagen/audio | Capas gratis de varias herramientas imponen atribución o no permiten uso comercial; pagar el plan y guardar los términos del día | [TERCERO] `05` §3–5 |
| Flux | Solo klein 4B (Apache 2.0) tiene licencia comercial abierta | [OFICIAL] `05` §4.1 |
| Vídeo IA | Sora cerrado; Veo/Kling/Runway: precios y licencia a verificar | [TERCERO] `05` §7.1 |
| Etiquetado de IA en redes | Etiqueta en pantalla + interruptor de la plataforma | [TERCERO]; **verificar oficial** |
| Vídeo de la página del juego | Solo gameplay real, sin voz ni música con letra; los vídeos de IA **no** valen | [OFICIAL] `thumbnails.md` |
| Moderación | Todo ícono/miniatura/audio se modera; margen de 48 h | [OFICIAL] `ads-manager.md`, `thumbnails.md` |

**Checklist por pieza de IA:** (1) sin texto ni logos de terceros; (2) sin rostros reales; (3) personaje igual a la hoja de referencia; (4) paleta HEX respetada; (5) legible a 110 px; (6) sin motivos de azar/casino; (7) registrada en el log de prompts; (8) etiquetada como IA donde proceda.
