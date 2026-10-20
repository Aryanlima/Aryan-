# Arte 2D y vídeo con IA para Fish & Fortune: plan concreto

Fecha: 2026-10-20. Alcance: íconos, miniaturas, arte de pases/productos, clips de vídeo para TikTok/Shorts y voz. **Qué servicio de imagen/vídeo usar lo decide Aryan según las cuentas que tenga**: este plan no escribe clientes de APIs externas (no se pueden verificar desde la sesión de la nube) y no depende de ninguna clave. El arte 3D dentro de Roblox es otro documento: [`arte-con-ia-en-studio.md`](arte-con-ia-en-studio.md).
Etiquetas: **[OFICIAL]**, **[TERCERO]**, **[NO VERIFICADO]**, **[IDEA PROPIA]**. Fuentes: `ROBLOX/research/05-ia-assets-y-marketing.md` (§4, §7), `ROBLOX/marketing/fish-and-fortune/prompts-ia.md`, `.../assets/README.md`, `ROBLOX/marketing/pipeline/README.md`.

## 1. Situación
- Hoy todo el arte 2D son **placeholders hechos por código** (SVG → PNG, `marketing/fish-and-fortune/assets/`) y los 6 vídeos de `specs-video/` son gráficos de marca con fondos procedurales. Sirven para desbloquear la publicación y probar A/B, no son arte final.
- La sesión de la nube **no tiene IA de imagen ni de vídeo**. El reemplazo es **sin tocar código**: se sustituyen archivos con el **mismo nombre** (imágenes) o se cambia una línea de datos en un spec JSON (vídeo).

## 2. Qué herramientas encajan y qué necesitan

Precios y licencias son de terceros y cambian: **confirmar el día de contratar y guardar los términos** [TERCERO, `research/05`, 2026-10].

| Tarea | Herramienta recomendada | Cuenta / clave que necesita Aryan | Coste aprox. [TERCERO] | Notas |
|---|---|---|---|---|
| Hoja de personaje de Fortu, íconos de pases/productos, arte de bestiario | **gpt-image-2** (ChatGPT o API de OpenAI) | Cuenta de OpenAI; clave solo si usa la API | ~0,05 USD/imagen en calidad media | Sigue bien las instrucciones. según un tercero `gpt-image-1` se retira el 2026-10-23: usar el 2 |
| Mismo uso, estética premium | **Midjourney** (Standard) | Suscripción | 30 USD/mes | Sin API; consistencia con `--cref` (imagen de Fortu). Texto flojo: añadirlo después |
| Sets de íconos coherentes (vectoriales) | **Recraft** (plan de pago) | Suscripción | ~10–12,5 USD/mes | El plan gratis **no** tiene licencia comercial |
| Logotipo y miniaturas con texto | **Ideogram** (Plus) | Suscripción | ~20 USD/mes | El mejor con texto; generaciones privadas solo de pago |
| Generación local sin cuenta | **Flux klein 4B** (Apache 2.0) | GPU potente en su PC | 0 | El resto de Flux 2 **no** es comercial |
| Vídeo de ambiente / lore / Fortu animada (guiones V01, V05, V09, V13, V17, V21, V28) | **Veo, Kling o Runway** (una sola, un mes) | Suscripción | ~7–15 USD/mes de entrada (Veo por segundo) | **Sora no** (cerrada según terceros). El plan gratis de Kling es no comercial |
| Voz (locución de los vídeos) | ElevenLabs u otra **con licencia comercial**, o su propia voz | Cuenta | variable | Voz sintética realista = contenido de IA: divulgarlo. eSpeak del pipeline solo para pruebas |
| Música | La sintetizada por el pipeline (propia, sin derechos de terceros) o Creator Store | Ninguna | 0 | Sin música con letra en la página del juego |

No investigados: Adobe Firefly, Nano Banana/Gemini/Imagen [NO VERIFICADO]. **Sin clave:** todas las herramientas se pueden usar desde su web; las claves solo harían falta para automatizar por API, y eso hoy no se pide.

## 3. Cómo usar los prompts
1. **Primero la hoja de Fortu** (`prompts-ia.md` §3.1, 16:9, tres vistas) y elegir una. Guardarla en `ROBLOX/marketing/fish-and-fortune/assets/reference/fortu-sheet.png` (carpeta nueva, ningún código la lee). Todo lo demás la lleva como imagen de referencia + el bloque `CHARACTER_FORTU` (§2 del mismo archivo).
2. Pegar siempre los bloques fijos `STYLE_BLOCK`, `PALETTE_BLOCK`, `NEGATIVE_IMAGE` (§2) para que el estilo sea el mismo en todas las piezas. Ningún prompt nombra marcas, estudios ni artistas.
3. Orden de producción: pases y productos (§3.6) → íconos del juego (ideas 1–5 de `pagina-del-juego.md` §5; el más legible a 64 px es el de Fortu) → miniaturas (generar la imagen **sin texto**; el texto se añade después con Fredoka 700) → clips de vídeo.
4. Generar al doble (1024×1024 / 3840×2160) y reducir. Revisar cada resultado con el checklist de `prompts-ia.md` §7: sin texto ni logos de terceros, sin rostros reales, personaje igual a la hoja, paleta HEX, legible a 110 px, **sin monedas/dados/cartas/casino**, registrada en el log de prompts.
5. **Log de prompts obligatorio** (herramienta y versión, fecha, prompt exacto, semilla, referencia, plan/licencia, quién revisó): crear `ROBLOX/marketing/fish-and-fortune/assets/prompts-log.md` y rellenarlo pieza a pieza. Es la prueba de originalidad ante una denuncia [OFICIAL: Roblox retira contenido infractor aunque lo haya creado una IA, `ip-guidelines.md`].
6. Decisión pendiente de Aryan que afecta al arte: la moneda del juego se dibuja como **conchas doradas**, no como monedas (los íconos actuales lo hacen así). Si prefiere otra cosa en la interfaz, hay que cambiar los 4 íconos de packs.

## 4. Entrega de archivos (nombres exactos; reemplazan los provisionales)
Carpeta base: `ROBLOX/marketing/fish-and-fortune/assets/`. PNG sRGB **sin canal alfa**. Mismo nombre = se sustituye sin cambiar nada.

| Carpeta | Archivos (nombre exacto) | Tamaño | Reglas |
|---|---|---|---|
| `icon/` | `icon-a-mitico.png`, `icon-b-fortu.png`, `icon-c-salto.png` | 512×512 (cuadrado) | Sin texto; legible a 150 y 64 px; esquinas con fondo continuo |
| `passes/` | `auto_fish.png`, `double_coins.png`, `starter.png`, `vip.png`, `season_pass.png` | 512×512 | Sujeto dentro del círculo de ≈ 460 px; fondo continuo hasta las 4 esquinas; **sin cofres, ruedas, dados ni monedas** (un pase promocionado no puede dar objetos aleatorios de pago) |
| `products/` | `coin_boost_15.png`, `coin_pack_small.png`, `coin_pack_medium.png`, `coin_pack_large.png`, `pearl_pack.png`, `slot_pack.png` | 512×512 | Igual que los pases |
| `thumbnails/` | `thumb-1-mitico-es.png`, `thumb-1-mitico-en.png`, `thumb-2-bestiario-es.png`, `thumb-2-bestiario-en.png`, `thumb-3-amigos-es.png`, `thumb-3-amigos-en.png`, `thumb-4-zonas-es.png`, `thumb-4-zonas-en.png` | 1920×1080 (16:9), < 3 MB | Nada esencial en el 15 % inferior; ≤ 3 palabras de gancho; texto añadido a mano (Fredoka 700), no por la IA; reflejar el juego real (la 2 y la 3 piden capturas reales) |

- No hay ícono de `luck_plus` ni `lucky_bait_15` (apagados en la v1) ni de cañas cosméticas.
- Comprobar formato y peso: `cd ROBLOX/marketing/fish-and-fortune/assets/source && npm install && node render-assets.mjs --validate-only` (necesita Node ≥ 20). El círculo seguro y el contraste solo se miden en el render por código: revisar a ojo con la plantilla circular.
- Subir con 3 días de margen (moderación de assets hasta 48 h) [OFICIAL, `thumbnails.md`]. Dónde se sube cada cosa: `assets/README.md` §7.
- Moderación: todo ícono/miniatura se modera; evitar IP y rostros reales [OFICIAL].

## 5. Vídeo: clips de IA como fondo del pipeline

**Dónde van:** `ROBLOX/marketing/fish-and-fortune/specs-video/clips/` (carpeta nueva; las rutas del spec son relativas a la carpeta del spec).

| Guion | Archivo (nombre exacto) | Prompt |
|---|---|---|
| V01 Teaser misterioso del lago | `v01-teaser-lago.mp4` | `guiones-videos.md` V01 |
| V05 Presentación de Fortu | `v05-fortu.mp4` | V05 (imagen→vídeo con `fortu-sheet.png` como primer fotograma) |
| V09 La leyenda del lago | `v09-leyenda.mp4` | V09 |
| V13 Loop relajante de pesca | `v13-loop-pesca.mp4` | V13 |
| V17 Amanecer de lanzamiento | `v17-amanecer.mp4` | V17 |
| V21 Teaser de evento de invierno | `v21-evento-invierno.mp4` | V21 |
| V28 Hito de comunidad (solo si es real) | `v28-hito.mp4` | V28 |

- **Formato:** vertical 9:16, ≥ 720×1280 (ideal 1080×1920), `.mp4` H.264 (o `.mov`/`.webm`), 5–10 s por clip, **sin texto dentro** (el texto lo pone el pipeline). El audio del clip se ignora.
- **Cómo se enchufa** (datos, no código): copiar un spec (p. ej. `ff-01-gancho-mitico.json` → `v01-teaser.json`) y poner en `bg` o en la escena:

```json
"bg": { "type": "video", "src": "clips/v01-teaser-lago.mp4", "scrim": 0.25 }
```
  Varias tomas del mismo clip: `"trim": 4`, `"speed": 1`, `"loop": true`. Renderizar: `node ROBLOX/marketing/pipeline/render.mjs ROBLOX/marketing/fish-and-fortune/specs-video/v01-teaser.json out/v01.mp4`.
- **Etiquetado:** en pantalla "Escena creada con IA · no es gameplay" (≥ 2 s, p. ej. en `legal`) y activar el interruptor de contenido de IA de cada plataforma [TERCERO; verificar en las páginas oficiales de TikTok y YouTube].
- **No sirven para la página del juego en Roblox**: allí solo vale gameplay auténtico, sin voz ni música con letra [OFICIAL, `thumbnails.md`].
- Plan de coste mínimo [IDEA PROPIA]: 1 herramienta, 1 mes, ≈ 7 clips de 5–8 s (3–4 intentos por clip). Fondos que no sean IA (capturas del juego real) se enchufan igual con `"type": "video"`.

## 6. Lo que debe aportar Aryan (NUNCA en el chat ni en archivos del repositorio)
1. **Elegir** una herramienta de imagen y una de vídeo (o ninguna: hoy hay placeholders) y **pagar el plan** correspondiente.
2. **Confirmar la licencia comercial** el día de contratar y guardar los términos fuera del repositorio.
3. Si algún día se automatiza por API: crear la clave en la consola del servicio y guardarla como **variable de entorno de su PC** (Windows: "Editar las variables de entorno del sistema"). No pegarla en el chat, en `.env` versionado, en scripts ni en el informe. Hoy **no hace falta ninguna clave**: todo se puede hacer desde las webs.
4. **Revisar cada pieza** contra IP ajena, rostros reales y estética de casino, y aprobar el diseño de Fortu (mascota).
5. **Subir** íconos, miniaturas y pases al Creator Dashboard (con margen de moderación) y publicar los vídeos desde sus cuentas, con el etiquetado de IA.
6. Decidir lo pendiente: conchas vs. monedas en la interfaz, y si Fortu aparece en el juego (si no aparece, no usarla en miniaturas).
