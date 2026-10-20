# Fish & Fortune — 30 guiones de vídeo corto (9:16, 15–35 s)

Fecha: 2026-10-20. Idioma: español (con gancho y CTA en inglés para audiencia EN). Calendario completo: `plan-lanzamiento.md` §5. Marca, paleta y prompts reutilizables: `prompts-ia.md`.

Etiquetas: **[OFICIAL]**, **[TERCERO]**, **[NO VERIFICADO]**, **[IDEA PROPIA]**, **[AJUSTAR A LO REAL]**.

**Estado del juego al escribir esto (2026-10-20):** `ROBLOX/games/fish-and-fortune/src` ya tiene la lógica de servidor y el balance, pero **aún no hay cliente/UI jugable**. Los datos de los guiones (zonas Lago Calmo / Río Cristal / Costa Dorada, 25 criaturas, rarezas, Míticos ≈ 0,04 % por lanzada con suerte 0, mini-juego de recogida en la zona perfecta, cañas, premios del bestiario, eventos Marea Dorada y Luna Mítica, código `WELCOME`) vienen de `Balance.luau` y son **provisionales**; ver `plan-lanzamiento.md` §0.1. Donde pone [AJUSTAR A LO REAL] falta la UI o la confirmación.

---

## 0. Cómo leer y reglas comunes

**Los 3 orígenes del material**

| Código | Origen | Cuántos | Qué necesita |
|---|---|---|---|
| **A** | **Captura de gameplay real** [a grabar por Aryan o por la sesión de su PC] | 15 | El juego abierto (Studio o publicado), grabador (OBS, o grabación de pantalla del móvil) y CapCut/DaVinci para montar. **Claude no puede grabar** gameplay desde la nube |
| **B** | **Generado por IA** (Veo / Kling / Runway; incluye PROMPT exacto) | 7 | **Cuenta + créditos de Aryan** en la herramienta elegida (ver §0.3). Es ambiente/marca/lore, **nunca gameplay** |
| **C** | **Render por código con el pipeline** (`ROBLOX/marketing/pipeline/`) | 8 (6 con spec ya hechos y renderizados en `specs-video/`) | Nada externo: `node render.mjs` (Node + Chromium + ffmpeg, ya funciona en esta sesión) |

**Reglas comunes de cumplimiento (aplican a los 30)**

1. **Divulga quién habla [IDEA PROPIA + práctica de transparencia]:** en los guiones en primera persona ("probé…") di en la descripción "Soy el creador del juego" / "I made this game". No simular ser un jugador neutral.
2. **Nada de "Robux gratis"**, sorteos de Robux, "gana", "premio", ni insinuar recompensa económica [OFICIAL: política de anuncios, `comply-with-advertising-standards.md` vía `03` §2.5; y `discovery.md`].
3. **Sin urgencia falsa:** solo fechas de fin reales (eventos, códigos). Sin cuentas atrás que se reinicien [OFICIAL, `monetization/index.md` vía `03` §2.3].
4. **Menores:** el juego apunta a 13+ (decisión D11). Prohibido presionar a comprar o pedir a menores que gasten; no usar "¡cómpralo antes de que se acabe!". En los CTA: "Juega gratis" (cierto) y mención de "compras opcionales".
5. **Odds:** solo se muestran porcentajes **reales** sacados de la tabla `Odds` del juego (`ROBLOX/packages/Odds.luau`); si no hay dato real, no hay porcentaje. En la v1 no hay venta de "suerte" ni cajas con Robux (decisión D9), pero el bestiario puede enseñar la probabilidad [AJUSTAR A LO REAL].
6. **Contenido de IA:** poner en pantalla "Escena creada con IA · no es gameplay" (≥ 2 s) en todo vídeo tipo **B**, y activar el interruptor de contenido generado por IA de cada plataforma. TikTok pide etiquetar el contenido de IA realista y YouTube pide divulgar contenido sintético/alterado realista al subir [TERCERO: resúmenes de guías de 2026; **verificar en las páginas oficiales de TikTok y YouTube** antes de publicar; no encontré las oficiales desde aquí]. Un vídeo B de "ambiente" claramente irreal puede no exigirlo en YouTube, pero etiquetar es gratis y más seguro.
7. **Colaboraciones pagadas o con incentivo:** el creador debe declararlo (ver `plantillas-colaboracion.md`). Para anuncios fuera de Roblox: declarar claramente que es publicidad [OFICIAL, `advertise-on-roblox.md` vía `05` §7.1].
8. **Privacidad en capturas de gameplay:** grabar en servidor VIP/privado o con cuentas de prueba; **difuminar nombres de usuario ajenos** y no mostrar a menores identificables [IDEA PROPIA].
9. **Música:** solo (a) la música sintetizada por el pipeline (generada por código, sin terceros), (b) audio del Creator Store, (c) música/SFX con licencia comprobada (ElevenLabs Starter+ tras confirmar el alcance de la licencia [NO VERIFICADO, `05` §5]) o (d) la biblioteca comercial de la plataforma si la cuenta es de empresa [NO VERIFICADO]. **Nunca canciones con derechos.** Música con letra: prohibida en el vídeo de la página del juego [OFICIAL].
10. **Los vídeos de este documento son para TikTok / Shorts / Reels / Discord, no para la página del juego.** El vídeo de la página debe ser gameplay auténtico sin voz ni anuncios [OFICIAL, `thumbnails.md`]; ver `pagina-del-juego.md` §6.
11. **Voz:** el pipeline puede usar eSpeak (robótico, solo pruebas). Para voz buena Aryan necesita una cuenta de TTS (ElevenLabs u otra con licencia comercial) o su propia voz: se enchufa como `narrationFile` por escena o `audio.voiceover` en el spec. **Voz de IA = contenido de IA**: divulgar si imita voz realista.
12. **Hashtags:** 3–5 por vídeo; la base es `#FishAndFortune #Roblox`. Prohibidos: `#freerobux`, `#robuxgratis` y similares.

### 0.3 Herramientas de vídeo de IA (estado)

- **Sora (OpenAI):** según terceros, la app cerró el 2026-04-26 y la API termina el 2026-09-24 [TERCERO, `05` §7.1]: **no planificar con Sora**. Los prompts de abajo valen para cualquier modelo.
- **Google Veo 3.1:** ~0,03–0,40 USD/s según calidad y audio [TERCERO]. **Kling:** ~7–10 USD/mes de entrada; el plan gratis es no comercial [TERCERO]. **Runway:** desde ~15 USD/mes [TERCERO]. Precios y licencia de uso comercial: **verificar el día de contratar** [NO VERIFICADO].
- Plan recomendado [IDEA PROPIA]: 1 herramienta, 1 mes, ~7 clips de 5–8 s (≈ 60–120 s de vídeo generado, con 3–4 intentos por clip). Generar siempre **sin texto** y poner el texto en CapCut o en el pipeline.

### 0.4 Negativos y bloques comunes (para los prompts B)

- `STYLE_VIDEO`: "stylized 3D cartoon look, soft rounded shapes, smooth shading, warm cozy lighting, calm slow camera, 9:16 vertical"
- `PALETTE`: "deep navy #0A1F44, lagoon teal #19C3C0, sunlit gold #FFC83D, coral orange #FF7A59, foam white #F4FBFF"
- `NEG_VIDEO` (campo "negative prompt" en Kling y Veo API; en Runway añadir al final como frase "avoid ..."): "text, subtitles, captions, watermark, logo, real brands, copyrighted characters, human faces, realistic photo, horror, blood, casino, slot machine, dice, coins, gambling, flicker, morphing artifacts"

### 0.5 Índice de los 30 guiones

| ID | Formato | Dur. | Origen | Día previsto (L = 1-dic) | Spec / cuenta necesaria |
|---|---|---|---|---|---|
| V01 | Teaser misterioso del lago | 15 s | B | D-14 · 17 nov | Veo/Kling/Runway |
| V02 | Momento clipable: "X pescó un MÍTICO" | 20 s | A | D-8 · 23 nov | Grabar |
| V03 | Gancho de marca "¿Podrás pescar un MÍTICO?" | 18 s | C | D-11 · 20 nov | `ff-01-gancho-mitico` |
| V04 | Progresión: mi primera caña | 25 s | A | D+1 · 2 dic | Grabar |
| V05 | Presentación de la mascota Fortu | 12 s | B | D-12 · 19 nov | Imagen + Kling/Veo |
| V06 | "Probé el pez más raro": intenté pescar al Espíritu del Lago | 28 s | A | D+2 · 3 dic | Grabar |
| V07 | Escalera de rareza (top 3) | 17 s | C | D-2 · 29 nov | `ff-02-escalera-rareza` |
| V08 | POV: eres quien pescó el Mítico | 15 s | A | D0 · 1 dic | Grabar |
| V09 | La leyenda del lago (lore) | 20 s | B | D-9 · 22 nov | Veo/Kling/Runway |
| V10 | Progresión: del Lago Calmo al Río Cristal | 30 s | A | D-5 · 26 nov | Grabar |
| V11 | Zonas: del lago a la costa | 15 s | C | D+4 · 5 dic | `ff-03-zonas-progresion` |
| V12 | Bestiario: la criatura que no sabías | 20 s | A | D-7 · 24 nov | Grabar |
| V13 | Loop relajante de pesca (ASMR) | 20 s | B | D-4 · 27 nov | Veo/Kling/Runway |
| V14 | Comparativa: Caña de Madera vs Caña de Fibra | 28 s | A | D+5 · 6 dic | Grabar |
| V15 | Tutorial express de 15 s | 15 s | C | D+8 · 9 dic | `ff-06-tutorial-15s` |
| V16 | Reto: completar el bestiario (día 1) | 30 s | A | D+6 · 7 dic | Grabar |
| V17 | Amanecer de lanzamiento | 12 s | B | D-1 · 30 nov | Veo/Kling/Runway |
| V18 | Pesco con amigos y pasa esto | 25 s | A | D+3 · 4 dic | Grabar (2+ cuentas) |
| V19 | Anuncio de evento (Marea Dorada) | 15 s | C | D+12 · 13 dic | `ff-04-evento-semanal` |
| V20 | Tutorial real: recoger en la zona perfecta | 20 s | A | D+10 · 11 dic | Grabar |
| V21 | Teaser de evento de invierno | 15 s | B | D+11 · 12 dic | Veo/Kling/Runway |
| V22 | Código WELCOME | 15 s | C | D0 · 1 dic | `ff-05-codigo-lanzamiento` |
| V23 | Reacción de un amigo al banner | 20 s | A | D+9 · 10 dic | Grabar + amigo |
| V24 | Reto: completar el bestiario (día 7) | 30 s | A | D+13 · 14 dic | Grabar |
| V25 | Comparativa de zonas con datos reales | 30 s | A | Banco | Grabar + datos |
| V26 | Encuesta: ¿qué criatura quieres? | 15 s | C | D+14 · 15 dic | Spec a crear (variante de `ff-01`) |
| V27 | Marea Dorada en acción | 25 s | A | D+15 · 16 dic | Grabar |
| V28 | Hito de comunidad (solo si es real) | 12 s | B | Banco | Veo/Kling/Runway |
| V29 | Resumen de la semana con datos reales | 20 s | C | D+7 · 8 dic | Spec a crear (variante de `ff-03`) |
| V30 | Balance de 30 días (honesto) | 30 s | A | Banco → D+30 · 31 dic | Grabar + datos |

---

## 1. Guiones

Formato de cada ficha: **Gancho (0–2 s)** · **Formato** · **Texto en pantalla** · **Narración (ES)** · **CTA** · **Hashtags** · **Origen** · **Requiere de Aryan**. `EN:` = versión corta del gancho/CTA para audiencia inglesa.

### V01 — Teaser misterioso del lago · 15 s · origen B
- **Gancho (0–2 s):** plano cenital del lago con un destello dorado que late bajo el agua. Texto: "Algo brilla en el lago…".
- **Formato:** 2 clips de IA de 6–8 s unidos; sin narración; sonido ambiente + SFX suaves.
- **Texto en pantalla:** 0–2 s "Algo brilla en el lago…" · 8–12 s "Fish & Fortune" · 12–15 s "Próximamente en Roblox" + etiqueta "Escena creada con IA · no es gameplay".
- **Narración:** ninguna (texto solo).
- **CTA:** "Síguenos para saber cuándo abre el lago." (sin fecha: aún no pasa G0).
- **EN:** "Something is glowing in the lake…" / "Follow to be first to fish."
- **Hashtags:** `#FishAndFortune #Roblox #RobloxFishing #CozyGames`
- **Origen B — PROMPT exacto (Veo/Kling/Runway), clip 1:**
  `Vertical 9:16 cinematic shot, slow push-in over a calm mountain lake at dawn, thin mist drifting on the water, a single soft golden shimmer glows beneath the surface and slowly pulses, an empty wooden fishing dock in the foreground with a fishing rod resting on it, gentle ambient lake sounds, no dialogue. stylized 3D cartoon look, soft rounded shapes, smooth shading, warm cozy lighting, calm slow camera. deep navy #0A1F44, lagoon teal #19C3C0, sunlit gold #FFC83D, coral orange #FF7A59, foam white #F4FBFF.`
  **Negative:** `text, subtitles, captions, watermark, logo, real brands, copyrighted characters, human faces, realistic photo, horror, casino, coins, gambling, flicker, morphing artifacts`
  **Clip 2:** igual pero `the golden shimmer brightens, ripples spread outward, the camera tilts up to the sunrise sky`.
- **Requiere de Aryan:** cuenta de Veo/Kling/Runway con créditos; cuenta de TikTok/YouTube; activar el interruptor de contenido de IA al subir.

### V02 — Momento clipable: "X pescó un MÍTICO" · 20 s · origen A
- **Gancho (0–2 s):** corte directo al instante en que aparece el aviso global de Mítico en pantalla + zoom al banner. Texto: "Todo el servidor lo vio".
- **Formato:** captura de pantalla vertical (móvil) o recorte 9:16 del PC; 3 cortes: (1) lanzar, (2) el banner global, (3) reacción.
- **Texto en pantalla:** 0–2 s "¿Qué acaba de pasar?" · 3–8 s "Alguien pescó un MÍTICO" · 12–18 s "Y lo vio todo el servidor". El texto del banner es el del juego, sin retocar.
- **Narración:** "Estaba pescando tranquilo y de repente… aparece esto en la pantalla de todos. Alguien acababa de pescar un mítico."
- **CTA:** "Busca Fish & Fortune en Roblox."
- **EN:** "Everyone on the server saw it." / "Search Fish & Fortune on Roblox."
- **Hashtags:** `#FishAndFortune #Roblox #RobloxFishing #Gaming`
- **Origen A — plano a grabar [a grabar por Aryan o por la sesión de su PC]:** un Mítico sale de forma natural ≈ 1 de cada 2.500 lanzadas con suerte 0 (≈ 0,04 %, `Balance.luau`), así que **no se puede grabar "a pelo"**: en un servidor con 2 cuentas de prueba, la cuenta B pesca el Mítico (con un comando de pruebas/admin del universo de pruebas **nunca en producción**) y la cuenta A graba la pantalla. Duración del clip crudo: 15–25 s. Si el comando de pruebas hace aparecer un Mítico "falso", **decirlo en la descripción** ("grabado en entorno de pruebas") para no engañar sobre la probabilidad.
- **Requiere de Aryan:** el juego jugable con el banner global [AJUSTAR A LO REAL: texto exacto del banner], 2 cuentas, grabador.

### V03 — Gancho de marca "¿Tu próxima lanzada será MÍTICA?" · 18 s · origen C
- **Gancho (0–2 s):** "¿Podrás pescar un MÍTICO?" sobre el lago con partículas (pregunta, no promesa: los Míticos son rarísimos).
- **Formato:** render del pipeline, 9:16 (sin gameplay).
- **Texto en pantalla / narración:** ver `specs-video/ff-01-gancho-mitico.json` (Lanza y recoge a tiempo → 25 criaturas en tu bestiario → 3 zonas por explorar → Un MÍTICO es rarísimo y se anuncia).
- **CTA:** "Busca Fish & Fortune — gratis en Roblox · compras opcionales".
- **EN:** "Can you catch a MYTHIC?" (traducir el spec cambiando los textos).
- **Hashtags:** `#FishAndFortune #Roblox #Pesca #CozyGames`
- **Origen C:** `node ROBLOX/marketing/pipeline/render.mjs ROBLOX/marketing/fish-and-fortune/specs-video/ff-01-gancho-mitico.json out/ff-01.mp4` → **ya renderizado** en `specs-video/out/ff-01-gancho-mitico.mp4` (1080×1920, 18,2 s). Fondo de gráficos de marca con emojis (Noto Color Emoji), no gameplay; lleva la línea legal "Imágenes de marca, no es gameplay".
- **Requiere de Aryan:** nada para publicarlo; opcional voz (`narrationFile`) y sustituir fondos por clips reales (`bg {type:'video'}`).

### V04 — Progresión: mi primera caña · 25 s · origen A
- **Gancho (0–2 s):** inventario vacío + caña de madera. Texto: "Empiezo con 0 monedas".
- **Formato:** captura continua acelerada (x2–x4) con cortes; contador de monedas real visible.
- **Texto en pantalla:** 0–2 s "Empiezo con la Caña de Madera" · mitad "Vendo mis primeras criaturas" · final "Caña de Junco (120 monedas)" (cifras reales de la pantalla; precios de `Balance.luau`).
- **Narración:** "Empiezo con la caña de madera. Pesco, vendo y compro la de junco, que cuesta ciento veinte monedas. ¿Notas la diferencia?"
- **CTA:** "¿Qué mejorarías primero? Cuéntamelo en comentarios."
- **EN:** "Starting with 0 coins." / "What would you upgrade first?"
- **Hashtags:** `#FishAndFortune #Roblox #RobloxFishing #Progresion`
- **Origen A — plano:** nueva cuenta de prueba desde la pantalla de inicio hasta la primera mejora (los primeros 3–5 min del FTUE). Es además material de **G0** (¿llega a la primera recompensa en < 60 s?).
- **Requiere de Aryan:** build jugable con tutorial inicial.

### V05 — Presentación de la mascota Fortu · 12 s · origen B
- **Gancho (0–2 s):** la mascota guiña el ojo a cámara. Texto: "Hola, soy Fortu".
- **Formato:** imagen estática de la mascota (generada con el prompt de `pagina-del-juego.md` §5 idea 5 o `prompts-ia.md`) + animación imagen-a-vídeo de 5–6 s en bucle.
- **Texto en pantalla:** "Hola, soy Fortu" · "Te enseño a pescar" · "Fish & Fortune" + "Escena creada con IA · no es gameplay".
- **Narración:** voz opcional, cálida y amable (ver `prompts-ia.md` §6); sin voz: solo texto.
- **CTA:** "¿Qué criatura quieres que busquemos primero?"
- **EN:** "Hi, I'm Fortu — I'll teach you to fish."
- **Hashtags:** `#FishAndFortune #Roblox #Mascota #CozyGames`
- **Origen B — PROMPT exacto (imagen-a-vídeo, Kling o Veo "image to video"):**
  `Use the provided mascot image as the first frame. The round golden koi-like fish mascot blinks, smiles warmly and gives a small wave with one fin, the bobber on its tiny rod bobs gently, a few bubbles rise, the camera stays still, loopable 5 seconds. stylized 3D cartoon look, soft rounded shapes, smooth shading, warm cozy lighting. Keep the character design identical to the first frame.`
  **Negative:** `text, subtitles, watermark, logo, real brands, human faces, realistic photo, scary, extra fins, changing colors, morphing artifacts`
- **Requiere de Aryan:** la imagen base de la mascota aprobada (generada por él en su herramienta de imagen); cuenta de vídeo IA. **Solo si la mascota existe en el juego** [AJUSTAR A LO REAL] (si no, es marca, no engaño, pero decirlo: "mascota de la marca").

### V06 — "Intenté pescar al Espíritu del Lago" · 28 s · origen A
- **Gancho (0–2 s):** ficha del Espíritu del Lago (Mítico) con su probabilidad real. Texto: "Probabilidad base: 0,04 %" (leer el valor del panel Probabilidades, no de memoria).
- **Formato:** captura de una sesión larga con **contador de lanzadas** en pantalla; inserto del panel Probabilidades.
- **Texto en pantalla:** "Lanzada [n]" (contador real) · "Probabilidad base: [valor real del panel]" · resultado real al final (aunque sea "no salió").
- **Narración:** "El Espíritu del Lago es el pez más raro del primer lago: la probabilidad base es de cero coma cero cuatro por ciento. Vamos a ver cuántas lanzadas aguanto… y si sale."
- **CTA:** "¿Cuántas lanzadas crees que hacen falta? Dime tu número."
- **EN:** "I tried to catch the Lake Spirit: base odds 0.04%."
- **Hashtags:** `#FishAndFortune #Roblox #RobloxFishing #Bestiario`
- **Origen A — plano:** sesión larga real **sin recortar intentos fallidos** y sin presentar un resultado de entorno de pruebas como natural; si se usa auto-pesca o suerte (la Luna Mítica da +3 de suerte), decirlo. Honesto y gracioso: "no salió" también es contenido.
- **Requiere de Aryan:** build jugable con el panel Probabilidades [AJUSTAR A LO REAL].

### V07 — Escalera de rareza (top 3) · 17 s · origen C
- **Gancho:** "¿Qué tan RARO puede ser tu próximo pez?"
- **Formato:** `top-list` del pipeline: #3 Criatura Rara → #2 Legendaria → #1 MÍTICA.
- **Texto / narración:** ver `specs-video/ff-02-escalera-rareza.json` (Rara = Trucha Dorada 4,50 %; Legendaria = Carpa Ancestral 0,60 %; Mítica = Espíritu del Lago 0,04 %; **probabilidad base en el Lago Calmo, suerte 0**, calculada de los pesos de `Balance.luau`).
- **CTA:** "¿Cuál te falta? Fish & Fortune · gratis en Roblox".
- **EN:** "How rare can your next catch be?"
- **Hashtags:** `#FishAndFortune #Roblox #Rareza #Coleccion`
- **Origen C:** **ya renderizado** `specs-video/out/ff-02-escalera-rareza.mp4` (1080×1920, 17,4 s). Si cambia el balance, recalcular los % (la fuente de verdad es el panel Probabilidades) o quitarlos.
- **Requiere de Aryan:** confirmar que el balance no ha cambiado antes de publicar.

### V08 — POV: eres quien pescó el Mítico · 15 s · origen A
- **Gancho (0–2 s):** cámara en primera persona sobre la caña que se dobla. Texto: "POV: algo enorme ha picado".
- **Formato:** captura con cámara subjetiva, cortes rápidos, pista de SFX original (sonido del juego) + latido.
- **Texto en pantalla:** "POV: algo enorme ha picado" → "…" → "¡MÍTICO!" (el aviso es el real).
- **Narración:** ninguna; solo sonido del juego y música.
- **CTA:** "Búscalo en Roblox: Fish & Fortune."
- **EN:** "POV: something huge just bit."
- **Hashtags:** `#FishAndFortune #Roblox #POV #RobloxFishing`
- **Origen A:** mismo plano que V02, pero guion de reacción; reutilizar la toma con otro corte.
- **Requiere de Aryan:** misma que V02.

### V09 — La leyenda del lago (lore) · 20 s · origen B
- **Gancho (0–2 s):** sombra gigante bajo el agua. Texto: "Dicen que en este lago vive una leyenda".
- **Formato:** 2–3 clips de IA con voz en off cálida (opcional) o solo texto; música suave.
- **Texto en pantalla:** "Dicen que en este lago vive una leyenda" → "Pocos la han visto" → "¿Serás tú quien la pesque?" + etiqueta de IA. Frase prudente: **no afirmar** que es fácil ni frecuente.
- **Narración:** "Dicen que bajo este lago vive una criatura enorme. Pocos la han visto. Y si alguien la pesca, todo el servidor se entera."
- **CTA:** "Fish & Fortune, gratis en Roblox."
- **EN:** "They say a legend lives in this lake."
- **Hashtags:** `#FishAndFortune #Roblox #Leyenda #CozyGames`
- **Origen B — PROMPT exacto, clip 1:**
  `Vertical 9:16 slow cinematic shot, deep under a calm lake, a giant luminous whale-like creature glides slowly past as a dark silhouette with soft golden bioluminescent patterns, shafts of light from the surface, tiny fish scatter, no dialogue, gentle magical ambient sound. stylized 3D cartoon look, soft rounded shapes, smooth shading, calm slow camera. deep navy #0A1F44, lagoon teal #19C3C0, sunlit gold #FFC83D, foam white #F4FBFF.`
  **Clip 2:** `The camera tilts up to the surface where a tiny wooden rowboat with a glowing lantern floats on the lake, the creature's golden glow ripples under the boat, the fisher inside is only a small silhouette seen from far away.`
  **Negative:** `text, subtitles, watermark, logo, real brands, copyrighted characters, human faces, realistic photo, horror, blood, jump scare, casino, coins, flicker, morphing artifacts`
- **Requiere de Aryan:** cuenta de vídeo IA; voz (opcional).

### V10 — Progresión 60 s: del lago al río · 30 s · origen A
- **Gancho (0–2 s):** timelapse del Lago Calmo. Texto: "Del Lago Calmo al Río Cristal" (+ el tiempo real que tardas).
- **Formato:** captura acelerada (x8) + 3 cortes: ganar monedas → comprar la Caña de Junco → desbloquear el **Río Cristal (2.000 monedas)**.
- **Texto en pantalla:** contador real de monedas y nombre real de la zona 2. "Zona 2 desbloqueada" solo si el juego lo dice.
- **Narración:** "Dos minutos, comprimidos en treinta segundos: pesco, vendo, mejoro y llego a la segunda zona."
- **CTA:** "¿Hasta qué zona has llegado tú?"
- **EN:** "From the lake to the river in 60 seconds."
- **Hashtags:** `#FishAndFortune #Roblox #Progresion #RobloxFishing`
- **Origen A — plano:** cuenta nueva con cronómetro; si el tiempo real a la zona 2 es mayor, **decir el tiempo real** en pantalla ("x8 de velocidad"). No prometer "en 60 segundos" si no es verdad: ajustar el gancho al tiempo real.
- **Requiere de Aryan:** build con la zona 2 (el balance trae 3 zonas).

### V11 — Zonas: del lago a la costa · 15 s · origen C
- **Gancho:** "Del LAGO a la COSTA".
- **Formato:** `progression` del pipeline: Zona 1 Lago → 2 Río → 3 Costa.
- **Texto / narración:** ver `specs-video/ff-03-zonas-progresion.json` (Lago Calmo → Río Cristal → Costa Dorada).
- **CTA:** "Empieza hoy — Fish & Fortune, gratis en Roblox".
- **EN:** "From the lake to the coast."
- **Hashtags:** `#FishAndFortune #Roblox #Explora #CozyGames`
- **Origen C:** **ya renderizado** `specs-video/out/ff-03-zonas-progresion.mp4` (1080×1920, 15 s). Nombres y orden tomados de `Balance.luau`.
- **Requiere de Aryan:** nada, salvo confirmar que no cambian los nombres.

### V12 — Bestiario: la criatura que no sabías que existía · 20 s · origen A
- **Gancho (0–2 s):** ficha del bestiario con "???" que se revela. Texto: "¿Sabías que existe esta criatura?".
- **Formato:** captura del bestiario: desplazamiento, ficha desbloqueada, estadística real.
- **Texto en pantalla:** nombre real de la criatura · rareza · zona donde aparece (datos reales de la ficha) · el premio real del bestiario (p. ej. "Descubre 5 criaturas: 500 monedas").
- **Narración:** "Este es mi bestiario. Me faltan estas criaturas. Esta aparece solo en [zona]."
- **CTA:** "¿Cuántas llevas en tu bestiario?"
- **EN:** "Did you know this creature exists?"
- **Hashtags:** `#FishAndFortune #Roblox #Bestiario #Coleccion`
- **Origen A — plano:** abrir el bestiario con progreso parcial y desbloquear una criatura nueva.
- **Requiere de Aryan:** bestiario con fichas [AJUSTAR A LO REAL].

### V13 — Loop relajante de pesca (ASMR) · 20 s · origen B
- **Gancho (0–2 s):** boya flotando, ondas lentas. Texto: "Para desconectar 🎣".
- **Formato:** un clip de IA en bucle (6–8 s) repetido 3 veces con corte suave; audio de agua/ambiente (Creator Store o ElevenLabs SFX con licencia).
- **Texto en pantalla:** "Para desconectar" · "Fish & Fortune" + etiqueta de IA.
- **Narración:** ninguna.
- **CTA:** "Pesca con calma en Roblox."
- **EN:** "Relax, cast, repeat."
- **Hashtags:** `#FishAndFortune #Roblox #CozyGames #Relax`
- **Origen B — PROMPT exacto:**
  `Seamless looping vertical 9:16 shot, a teal and gold fishing bobber (not red and white) floating on a calm lake at golden hour, concentric ripples spread slowly, a dragonfly passes by, soft reeds sway, locked camera, gentle water ambience, no dialogue. stylized 3D cartoon look, soft rounded shapes, smooth shading, warm cozy lighting. deep navy #0A1F44, lagoon teal #19C3C0, sunlit gold #FFC83D, foam white #F4FBFF.`
  **Negative:** `text, subtitles, watermark, logo, real brands, human faces, realistic photo, horror, casino, coins, camera shake, flicker, morphing artifacts`
- **Requiere de Aryan:** cuenta de vídeo IA.

### V14 — Comparativa: caña básica vs mejorada · 28 s · origen A
- **Gancho (0–2 s):** pantalla dividida con las dos cañas. Texto: "10 lanzadas con cada caña".
- **Formato:** pantalla dividida (o dos tomas seguidas) con **10 lanzadas reales por caña**; tabla final con el resultado real.
- **Texto en pantalla:** "Caña básica" vs "Caña mejorada" · resultado real de cada serie (criaturas, rarezas).
- **Narración:** "Diez lanzadas con cada caña, sin trucos. Esto es lo que cambia."
- **CTA:** "¿Qué comparativa quieres ver ahora?"
- **EN:** "10 casts with each rod — real results."
- **Hashtags:** `#FishAndFortune #Roblox #Comparativa #RobloxFishing`
- **Origen A — plano:** dos tandas reales; mostrar el resultado aunque sea poco favorable (honestidad; si la mejora es pequeña, decirlo).
- **Requiere de Aryan:** 2 cañas reales (p. ej. Caña de Madera frente a Caña de Fibra: la zona perfecta pasa de 0,14 a 0,18 y la suerte de 0 a 1 [`Balance.luau`]). Las cañas se compran con **monedas**, no con Robux.

### V15 — Tutorial express de 15 s · 15 s · origen C
- **Gancho:** "3 tips para pescar mejor".
- **Formato:** `bullets` del pipeline: recoge con el marcador en la zona perfecta · recoger perfecto da suerte extra, gratis · con mejores cañas la zona perfecta es más ancha (mecánica real de `Balance.minigame`).
- **Texto / narración:** ver `specs-video/ff-06-tutorial-15s.json`.
- **CTA:** "Pruébalo gratis — Fish & Fortune en Roblox".
- **EN:** "3 tips to fish better."
- **Hashtags:** `#FishAndFortune #Roblox #Tutorial #RobloxTips`
- **Origen C:** **ya renderizado** `specs-video/out/ff-06-tutorial-15s.mp4` (14,2 s). **Confirmar cada tip contra la UI final**; si cambian, editar el spec y re-renderizar.
- **Requiere de Aryan:** confirmar la UI del mini-juego.

### V16 — Reto: completar el bestiario sin gastar Robux (día 1) · 30 s · origen A
- **Gancho (0–2 s):** bestiario casi vacío. Texto: "Reto: completar el bestiario sin gastar Robux".
- **Formato:** episodio 1 de una serie; progreso real mostrado "x/25" y los premios reales del bestiario (5, 10, 15, 20 y 25 criaturas; el completo da 40 perlas y 500.000 monedas).
- **Texto en pantalla:** "Día 1 · [n]/[total] criaturas" · "0 Robux gastados" (solo si es cierto).
- **Narración:** "Empiezo desde cero. Regla: ni un Robux. Veamos cuántas criaturas consigo hoy."
- **CTA:** "Parte 2 en una semana. ¿Te sumas al reto?"
- **EN:** "Challenge: fill the bestiary without spending Robux — Day 1."
- **Hashtags:** `#FishAndFortune #Roblox #Reto #RobloxFishing`
- **Origen A — plano:** sesión de 20–30 min recortada a 30 s con contador real. No usar compras de Robux ni comandos de pruebas.
- **Requiere de Aryan:** cuenta de pruebas "limpia"; compromiso de seguir la serie (V24 en 1 semana).

### V17 — Amanecer de lanzamiento · 12 s · origen B
- **Gancho (0–2 s):** amanecer sobre el muelle. Texto: "Mañana abre el lago" (solo si ya pasó G0 y el juego está aprobado).
- **Formato:** clip de IA (6–8 s) + título; sin cuenta atrás falsa: fecha real.
- **Texto en pantalla:** "Fish & Fortune" · "1 de diciembre" (fecha real confirmada) · etiqueta de IA.
- **Narración:** ninguna.
- **CTA:** "Activa el aviso y busca Fish & Fortune en Roblox."
- **EN:** "The lake opens tomorrow."
- **Hashtags:** `#FishAndFortune #Roblox #Lanzamiento #CozyGames`
- **Origen B — PROMPT exacto:**
  `Vertical 9:16, sunrise over a calm lake, golden light slowly spreads across the water and mist, an empty wooden dock with a fishing rod resting on it, the rod tip dips slightly as if something just bit, slow gentle push-in, soft birdsong, no dialogue. stylized 3D cartoon look, soft rounded shapes, smooth shading, warm cozy lighting. deep navy #0A1F44, lagoon teal #19C3C0, sunlit gold #FFC83D, coral orange #FF7A59, foam white #F4FBFF.`
  **Negative:** `text, subtitles, watermark, logo, real brands, human faces, realistic photo, horror, casino, coins, flicker, morphing artifacts`
- **Requiere de Aryan:** publicar solo si el juego fue aprobado y la fecha es firme; cuenta de vídeo IA.

### V18 — Pesco con amigos y pasa esto · 25 s · origen A
- **Gancho (0–2 s):** dos avatares en el mismo muelle; la caña de uno se dobla. Texto: "Pesqué con un amigo y pasó esto".
- **Formato:** captura de 2 cuentas en el mismo lago; momento cooperativo o competitivo real (quién pesca más rara).
- **Texto en pantalla:** marcador real; "Lagos compartidos".
- **Narración:** "Compartimos lago y nos retamos: a ver quién pesca la criatura más rara." (reto amistoso sin dinero ni Robux; no usar la palabra "apuesta")
- **CTA:** "Etiqueta a quien jugaría contigo."
- **EN:** "We fished together and this happened."
- **Hashtags:** `#FishAndFortune #Roblox #ConAmigos #RobloxFishing`
- **Origen A — plano:** 2 cuentas; difuminar nombres si no son tuyos/de amigos que lo autoricen.
- **Requiere de Aryan:** un amigo o 2.ª cuenta; consentimiento de quien aparezca.

### V19 — Anuncio de evento · 15 s · origen C
- **Gancho:** "Evento semanal: Marea Dorada — del lunes 14 al domingo 20 de diciembre" (evento real de la config: monedas por venta ×2).
- **Formato:** `custom` 16:9 del pipeline (Discord / comunidad de YouTube); versión 9:16 con `--aspect 9:16`.
- **Texto / narración:** ver `specs-video/ff-04-evento-semanal.json` (monedas por venta ×2, se suma a otros bonus con tope, se repite cada dos semanas). Fechas: semanas que empiezan el 30-nov, 14-dic y 28-dic; la Luna Mítica (+3 de suerte) las del 7-dic y 21-dic.
- **CTA:** "¡Nos vemos en el lago!"
- **EN:** "Weekly event: Golden Tide — Dec 14–20."
- **Hashtags:** `#FishAndFortune #Roblox #Evento #CozyGames`
- **Origen C:** **ya renderizado** `specs-video/out/ff-04-evento-semanal.mp4` (1920×1080, 15,1 s). Las fechas deben coincidir con la config remota (inicio lunes 00:00 UTC).
- **Requiere de Aryan:** confirmar la config de eventos antes de publicar (no depende de G2: ya existe en el juego).

### V20 — Tutorial real: recoger en la zona perfecta · 20 s · origen A
- **Gancho (0–2 s):** recogida fallida. Texto: "Así NO se recoge".
- **Formato:** captura con comparación fallo/acierto; flechas y círculos de resaltado (permitido: "resaltados de mecánicas reales").
- **Texto en pantalla:** "Espera al marcador" · "Recoge en la zona perfecta" · nombres reales de los controles.
- **Narración:** "Un marcador va y viene. Si recoges fuera de la zona, pierdes la oportunidad de suerte extra. Recoge justo en la zona perfecta."
- **CTA:** "¿Algún otro truco? Cuéntalo."
- **EN:** "How to cast properly."
- **Hashtags:** `#FishAndFortune #Roblox #Tutorial #RobloxTips`
- **Origen A — plano:** 3 recogidas: mala, buena y perfecta (la perfecta da +1 punto de suerte gratis [`Balance.minigame`]).
- **Requiere de Aryan:** build con el mini-juego y su UI.

### V21 — Teaser de evento de invierno · 15 s · origen B
- **Gancho (0–2 s):** nieve cayendo sobre el lago. Texto: "El lago se viste de invierno".
- **Formato:** clip de IA (6–8 s) + texto; solo si el evento festivo es real (plan v1.3, 22–24 dic).
- **Texto en pantalla:** "El lago se viste de invierno" · fecha real de inicio · etiqueta de IA.
- **Narración:** ninguna.
- **CTA:** "Fish & Fortune — próximamente: evento de invierno."
- **EN:** "The lake turns to winter."
- **Hashtags:** `#FishAndFortune #Roblox #Invierno #CozyGames`
- **Origen B — PROMPT exacto:**
  `Vertical 9:16, a snowy lake at dusk, soft snowfall, warm lanterns glowing along a wooden pier, frozen edges on the shore, a bright teal-and-gold shimmer pulses in an open patch of dark water, slow gentle push-in, quiet winter ambience, no dialogue. stylized 3D cartoon look, soft rounded shapes, smooth shading, warm cozy lighting. deep navy #0A1F44, lagoon teal #19C3C0, sunlit gold #FFC83D, coral orange #FF7A59, foam white #F4FBFF.`
  **Negative:** `text, subtitles, watermark, logo, real brands, human faces, realistic photo, horror, casino, coins, flicker, morphing artifacts`
- **Requiere de Aryan:** evento festivo confirmado (no está en la config por defecto: es el contenido v1.3 del plan 90); cuenta de vídeo IA.

### V22 — Código de lanzamiento · 15 s · origen C
- **Gancho:** "Código WELCOME".
- **Formato:** `custom` con 3 pasos y la recompensa real.
- **Texto / narración:** ver `specs-video/ff-05-codigo-lanzamiento.json` (código `WELCOME` = 1.000 monedas + 5 perlas, un canje por cuenta; **sin caducidad** en la config actual, por eso el vídeo no afirma ninguna).
- **CTA:** "Código WELCOME — un canje por cuenta".
- **EN:** "Code WELCOME: 1,000 coins + 5 pearls (one per account)."
- **Hashtags:** `#FishAndFortune #Roblox #Codigo #RobloxCodes`
- **Origen C:** **ya renderizado** `specs-video/out/ff-05-codigo-lanzamiento.mp4` (1080×1920, 14,9 s). **No publicar hasta que el botón "Códigos" exista y el canje esté probado.** Si Aryan añade una caducidad (`expiresAt`), poner la fecha real en el vídeo.
- **Requiere de Aryan:** el canje funcionando (ver `plan-lanzamiento.md` §7).

### V23 — Reacción de un amigo al banner · 20 s · origen A
- **Gancho (0–2 s):** cara/pantalla del amigo en el momento del aviso. Texto: "Su cara al ver el aviso".
- **Formato:** split-screen: pantalla de juego + webcam/voz del amigo (con su consentimiento). Sin menores: solo amigos adultos o con permiso expreso de sus tutores.
- **Texto en pantalla:** "Alguien pescó un MÍTICO" (banner real).
- **Narración:** reacción natural; nada ensayado que prometa probabilidades.
- **CTA:** "¿Te ha pasado? Cuéntalo."
- **EN:** "His face when the Mythic notice popped up."
- **Hashtags:** `#FishAndFortune #Roblox #Reaccion #RobloxFishing`
- **Origen A — plano:** grabar en vivo, 2 PCs; no avisar del banner al amigo si se simula, y **decir que es entorno de pruebas** si lo es.
- **Requiere de Aryan:** un amigo adulto y consentimiento por escrito (un mensaje basta).

### V24 — Reto: completar el bestiario (día 7) · 30 s · origen A
- **Gancho (0–2 s):** "Una semana después…". Texto: "Reto, parte 2: [n]/[total]".
- **Formato:** misma cuenta que V16, progreso real.
- **Texto en pantalla:** "Día 7 · [n]/[total] criaturas" · "0 Robux gastados" (si sigue siendo cierto).
- **Narración:** "Una semana, cero Robux. Estas son las criaturas que me faltan y esta la que casi no consigo."
- **CTA:** "Parte 3: ¿qué zona quieres que explore?"
- **EN:** "One week, zero Robux: where I am now."
- **Hashtags:** `#FishAndFortune #Roblox #Reto #Bestiario`
- **Origen A — plano:** sesiones de la semana resumidas.
- **Requiere de Aryan:** haber hecho V16 y seguir la serie.

### V25 — Comparativa de zonas con datos reales · 30 s · origen A (banco)
- **Gancho (0–2 s):** "¿Qué zona da más criaturas raras?"
- **Formato:** 3 tandas de 20 lanzadas (una por zona) con tabla final; datos **reales** y método visible.
- **Texto en pantalla:** tabla de resultados reales con el número de lanzadas.
- **Narración:** "Veinte lanzadas por zona, mismo equipo. Este es el resultado y no es un estudio científico, solo mi muestra."
- **CTA:** "¿Repetimos con 100 lanzadas?"
- **EN:** "Which zone gives the rarest catches?"
- **Hashtags:** `#FishAndFortune #Roblox #Comparativa #Datos`
- **Origen A:** tomas largas; registrar los números en una hoja de cálculo.
- **Requiere de Aryan:** ≥ 2 zonas jugables; tiempo de grabación. Usar cuando haya hueco en el calendario.

### V26 — Encuesta: ¿qué criatura quieres? · 15 s · origen C
- **Gancho:** "¿Qué criatura quieres en el próximo evento?"
- **Formato:** `custom` con 3 opciones (stickers) y pregunta; sirve para feedback (ver `plan-lanzamiento.md` §9).
- **Texto / narración:** variante del spec `ff-01` con `scenes` de tipo `caption` y 3 `chips` (A/B/C); **las opciones deben ser ideas reales que el juego podría hacer**, no promesas.
- **CTA:** "Vota en los comentarios".
- **EN:** "Which creature do you want next?"
- **Hashtags:** `#FishAndFortune #Roblox #Comunidad`
- **Origen C:** spec a crear (copia de `ff-01-gancho-mitico.json`, cambiando textos). Se renderiza con la misma orden.
- **Requiere de Aryan:** decidir las opciones.

### V27 — Marea Dorada en acción · 25 s · origen A
- **Gancho (0–2 s):** venta de criaturas con el multiplicador activo. Texto: "Marea Dorada: ¿cuánto cambia vender?"
- **Formato:** captura de la misma venta con y sin evento (monedas por venta ×2, que se suma a otros bonus con tope); cifras reales de la pantalla.
- **Texto en pantalla:** monedas antes/durante el evento (reales); "Hasta el lunes 21, 00:00 UTC".
- **Narración:** "Esta semana las monedas por venta se multiplican por dos. Así cambia vender lo mismo con y sin evento."
- **CTA:** "Termina el lunes 21 de diciembre a las 00:00 UTC (hora de tu zona: míralo en el juego)."
- **EN:** "I tried the event in its first hour."
- **Hashtags:** `#FishAndFortune #Roblox #Evento #RobloxFishing`
- **Origen A:** requiere el juego en producción con la config de eventos.
- **Requiere de Aryan:** el evento activo en esa fecha.

### V28 — Hito de comunidad (solo si es real) · 12 s · origen B (banco)
- **Gancho (0–2 s):** fuegos artificiales sobre el lago. Texto: "¡[hito real]!" p. ej. "Ya somos [n] en el grupo" con cifra real.
- **Formato:** clip de IA + texto; **solo con cifra real y verificable**; si no hay hito, no se publica.
- **Texto en pantalla:** hito real · "Gracias" · etiqueta de IA.
- **Narración:** ninguna.
- **CTA:** "Gracias por pescar con nosotros."
- **EN:** "Thank you for fishing with us!"
- **Hashtags:** `#FishAndFortune #Roblox #Comunidad`
- **Origen B — PROMPT exacto:**
  `Vertical 9:16, fireworks bursting over a calm lake at night and reflecting on the water, a round golden koi-like fish mascot wearing a tiny teal knitted beanie leaps out of the lake in a joyful arc, droplets sparkle, warm celebratory mood, no dialogue. stylized 3D cartoon look, soft rounded shapes, smooth shading. deep navy #0A1F44, lagoon teal #19C3C0, sunlit gold #FFC83D, coral orange #FF7A59, foam white #F4FBFF.`
  **Negative:** `text, subtitles, watermark, logo, real brands, human faces, realistic photo, casino, coins, flicker, morphing artifacts`
- **Requiere de Aryan:** hito real; cuenta de vídeo IA.

### V29 — Resumen de la semana con datos reales · 20 s · origen C
- **Gancho:** "Así fue la primera semana".
- **Formato:** `counter` + `stages` del pipeline con **cifras reales de Creator Analytics** (nunca estimaciones). Ejemplos de cifras permitidas: jugadores únicos, criaturas pescadas, Míticos pescados esta semana. **Si la cifra es pequeña, se muestra igual** (honestidad); si no hay cifra real, no se publica.
- **Texto / narración:** crear el spec desde `ff-03-zonas-progresion.json` + escena `counter` (campos `label`, `from`, `to`, `suffix`).
- **CTA:** "Gracias por probarlo. ¿Qué mejoramos?"
- **EN:** "Our first week in numbers."
- **Hashtags:** `#FishAndFortune #Roblox #Comunidad #Novedades`
- **Origen C:** spec a crear con datos del panel; se renderiza igual.
- **Requiere de Aryan:** pasar las cifras reales del panel de Analytics.

### V30 — Balance de 30 días (honesto) · 30 s · origen A (banco)
- **Gancho (0–2 s):** "30 días haciendo un juego de Roblox con IA: lo que salió bien y mal".
- **Formato:** montaje de clips + pantalla del panel de Analytics (con datos reales) + lecciones.
- **Texto en pantalla:** 3 aciertos y 3 errores **reales**; cifras reales (D1, visitas, etc.).
- **Narración:** honesta, sin inflar. Si el juego no pasó G1/G2, decirlo.
- **CTA:** "Gracias por seguir el proceso."
- **EN:** "30 days building a Roblox game with AI: what worked, what didn't."
- **Hashtags:** `#FishAndFortune #Roblox #GameDev #RobloxDevlog`
- **Origen A:** montaje + captura del panel (sin mostrar datos personales).
- **Requiere de Aryan:** datos reales del día 30 (D+30 = 31 dic). Contenido de proceso (devlog) suele rendir en TikTok/YouTube [NO VERIFICADO].

---

## 2. Cómo se produce cada tipo (pasos)

**A (gameplay):** grabar a 1080×1920 (móvil) o 1920×1080 y recortar; montar en CapCut (la versión gratuita solo cubre cuentas personales; para cuenta de empresa/marca hace falta Pro [TERCERO, `05` §7.1]) o DaVinci Resolve (gratis); exportar 1080×1920 H.264. Se puede **componer sobre el pipeline**: `"bg": {"type":"video","src":"../clips/mi-clip.mp4","speed":1}` para que el texto/sticker/CTA de marca se dibuje encima de un clip real (el compilador lo convierte a frames y lo encaja a la escena).

**B (IA):** generar clips de 5–8 s sin texto; revisar uno por uno (IP, rostros, "artefactos" raros); montar y añadir texto y la etiqueta "Escena creada con IA · no es gameplay"; activar el interruptor de IA de la plataforma.

**C (pipeline):** `node ROBLOX/marketing/pipeline/render.mjs <spec.json> <salida.mp4>`; opciones útiles: `--aspect 9:16|16:9|1:1|4:5`, `--scale 0.5` (preview), `--stills 1,5,9` (fotogramas de revisión), `--crf 21 --report`. Ver `specs-video/README.md`.
