# Pipeline de vídeos promocionales (spec JSON → MP4)

Renderizador **dirigido por datos** para producir muchos vídeos cortos (TikTok / YouTube Shorts / Reels en 9:16, y también 16:9 / 1:1 / 4:5) a partir de un archivo JSON por vídeo.

```
spec.json ──► compile.mjs ──► player (HTML/CSS/Canvas, window.renderFrame(t)) ──► Chromium (Playwright) ──► frames JPEG ─┐
                │                                                                                                      ├─► ffmpeg ─► MP4 H.264 + AAC (yuv420p, faststart)
                └─► audio.mjs (música + SFX sintéticos, narración opcional, ducking, loudnorm) ────────────────────────┘
```

- **Determinista**: el estado visual es una función pura del tiempo (`window.renderFrame(t)`), sin timers ni transiciones CSS. Capturar el mismo `t` dos veces da la misma imagen (verificado: 2 píxeles de 518 000 distintos tras saltar de `t`).
- **Sin GPU, sin Roblox Studio, sin servicios de IA**: todo corre local (Node + Chromium + ffmpeg). Los clips de IA o las grabaciones de Studio se enchufan como capas de fondo (ver [§6](#6-enchufar-clips-de-ia-o-capturas-de-studio)).
- Rutas **siempre relativas**: las rutas de los assets del spec se resuelven respecto a la carpeta del propio spec, y el código no contiene rutas absolutas, así que la carpeta se puede mover.

---

## 1. Requisitos e instalación

- Node ≥ 20 (probado con 22), `ffmpeg` + `ffprobe` en el PATH (probado con 6.1), un Chromium (se busca solo en `PLAYWRIGHT_BROWSERS_PATH`, `/opt/pw-browsers`, `~/.cache/ms-playwright`; o define `CHROMIUM_PATH=/ruta/al/chrome`).
- Instalación (solo local, dentro de esta carpeta):

```bash
cd ROBLOX/marketing/pipeline  # desde la raiz del repositorio
npm install                  # playwright-core + mespeak (TTS opcional). NO descarga navegadores.
```

`node_modules/`, `.cache/` y los intermedios están en `.gitignore`.

## 2. Uso rápido

```bash
# un vídeo
node render.mjs specs/ejemplo-gancho.json out/ejemplo-gancho.mp4

# todos los specs de una carpeta
node render.mjs --all specs out

# previsualización barata: mitad de resolución, solo 6 s
node render.mjs specs/ejemplo-top.json out/prev.mp4 --scale 0.5 --max 6

# revisar el diseño SIN renderizar: PNG de instantes concretos (carpeta de salida)
node render.mjs specs/ejemplo-oferta.json out/stills --stills 0.5,3,9.5

# forzar otra relación de aspecto (los layouts se adaptan)
node render.mjs specs/ejemplo-gancho.json out/gancho-16x9.mp4 --aspect 16:9
```

Desde la carpeta de un juego (p. ej. `ROBLOX/marketing/<juego>/`): `node ../pipeline/render.mjs specs-video/x.json specs-video/out/x.mp4`.

| Opción | Efecto |
|---|---|
| `--aspect 9:16\|16:9\|1:1\|4:5` | Anula `aspect` del spec (1080×1920, 1920×1080, 1080×1080, 1080×1350) |
| `--size WxH` | Tamaño exacto (anula el aspecto) |
| `--fps N` | Fotogramas por segundo (def. 30) |
| `--scale X` | Escala de render (0.5 = previsualización rápida) |
| `--workers N` | Procesos de captura en paralelo (def. `min(4, CPUs)`) |
| `--crf N` / `--preset P` | Calidad / velocidad x264 (def. 18 / `veryfast`; también en el spec: `"encode": {"crf":24,"preset":"slow"}`) |
| `--max SEG` | Solo los primeros SEG segundos |
| `--png` | Frames intermedios PNG sin pérdida (≈3× más lento) en vez de JPEG q94 |
| `--no-audio` | Sin música/SFX/narración |
| `--stills t1,t2,…` | No renderiza vídeo: guarda PNG de esos instantes en la carpeta de salida |
| `--guides` | Dibuja la zona segura (depuración) |
| `--keep` | Conserva los frames intermedios en `.cache/work` |
| `--report` | Escribe `<salida>.json` con tiempos y metadatos (ffprobe) |

Variables: `PROFILE=1` muestra ms por frame (render / captura); `CHROMIUM_PATH`.

## 3. Estructura

```
render.mjs            CLI
variants.mjs          genera N specs a partir de una base + lista de variantes
lib/compile.mjs       spec "humano" → spec resuelto (tiempos absolutos, texto parseado, SFX, subtítulos, fondos)
lib/capture.mjs       Playwright: N navegadores en paralelo, captura frame a frame (CDP)
lib/audio.mjs         mezcla: música + SFX + narración, ducking, loudnorm
lib/synth.mjs         sintetizador JS puro: 4 estilos de música + 12 SFX (sin dependencias, con semilla)
lib/tts.mjs           narración local opcional (eSpeak vía `mespeak`)
player/               index.html, styles.css, fx.js (easings/pop/shake), bg.js (fondos), scenes.js (tipos de escena), runtime.js (renderFrame)
specs/                4 ejemplos (uno por plantilla)
out/                  MP4 de ejemplo (+ .json de tiempos)
.cache/               frames de clips, TTS, intermedios (se puede borrar)
```

## 4. Formato del spec

Todo es opcional salvo que haya al menos una escena (`hook`, `scenes`, `items` u `offer`, o `cta`). Los **textos** admiten marcado: `*acento*` (color de acento), `**acento 2**` (color "hot"), `\n` o `|` (salto de línea) y emojis.

### 4.1 Campos raíz

| Campo | Descripción |
|---|---|
| `id`, `title` | `id` = nombre del vídeo (en logs). `title` se usa como texto del gancho si no hay `hook.text`. |
| `template` | `hook-gameplay-cta`, `top-list`, `before-after`, `progression`, `offer`, `custom` (ver 4.2) |
| `aspect`, `fps` | `"9:16"` (def.), `"16:9"`, `"1:1"`, `"4:5"`; `30` |
| `duration` | Duración objetivo (s). Reparte la diferencia entre escenas sin `duration` propia. Si no se da, es la suma de escenas menos solapes de transición. |
| `palette` | Nombre (`neon`, `sunset`, `candy`, `lime`, `gold`, `ocean`) o un objeto con `bg1,bg2,accent,accent2,hot,text,dim,good,bad` (parcial: se mezcla sobre `neon`). Se puede combinar: `{"name":"gold","accent":"#fff"}`. |
| `typography` | `{heading, body, headingWeight, uppercase}`. Fuentes del sistema (Inter, DejaVu, Liberation, JetBrains Mono, Noto Color Emoji) o propias vía `fonts`. |
| `fonts` | `[{ "family":"Fredoka", "file":"fonts/Fredoka.ttf", "weight":"300 700" }]` (ruta relativa al spec) |
| `brand` | `{name, handle, watermark}`; `watermark`: `"top-left"`/`"top-right"` para pastilla fija. `handle` se usa en el CTA. |
| `bg` | Fondo por defecto de `hook` y `caption` (ver 4.4). Sin él: `runner` (procedural). |
| `hook` | Escena de gancho (primeros ~2 s): `{text, sub, emoji, kicker, chip, duration, …campos comunes}`. `false` la omite. |
| `scenes` | Lista de escenas `{kind, …}` (ver 4.3). |
| `items` | Solo `top-list`: lista `{title, sub, emoji, image, stat, rank?}` en orden de aparición (el ranking se numera hacia atrás: N…1). |
| `offer` | Solo `offer`: objeto de la escena `offer` (insertada tras el gancho; su `code` pasa al CTA). |
| `cta` | `{text, sub, button, emoji, handle, code, codeLabel}`; `false` la omite. Es la última escena. |
| `subtitles` | `{enabled, y, size, color, style}`: `y` = posición vertical (fracción 0‒1; def. 0.70 vertical / 0.88 apaisado), `size` en unidades de 1080, `style:"reveal"` atenúa palabras aún no dichas. `false` los desactiva. |
| `progress` | `{style:"segments"\|"solid"\|"none", position:"top"\|"bottom"}`; `false` = sin barra. |
| `safeZone` | `"auto"` (def.), `"none"` o `{t,b,l,r}` en unidades de 1080. Auto (9:16): 170 arriba, 340 abajo, 96 laterales *[NO VERIFICADO: aproximación a la UI de TikTok/Shorts/Reels; comprobar con `--guides`]*. |
| `legal` | Línea pequeña inferior (aviso legal / "juego de ejemplo"). |
| `locale` | `"es"` (def., miles con `.`) o `"en"` (miles con `,`). |
| `encode` | `{crf, preset}` por defecto para este spec. |
| `audio` | Ver 4.6. |

### 4.2 Plantillas

| `template` | Qué añade | Escena por defecto |
|---|---|---|
| `hook-gameplay-cta` (a) | gancho + `scenes` + CTA; música `hype` | `caption` (sobre fondo gameplay) |
| `top-list` (b) | gancho + una escena `rank` por cada `items[]` (cuenta atrás N…1) + CTA; música `arcade` | `rank` |
| `before-after` / `progression` (c) | gancho + tus `scenes` (`compare`, `stages`, `counter`…) + CTA; música `epic` | `compare` / `stages` |
| `offer` (d) | gancho + `offer` (descuento, cuenta atrás, objetos, **código de canje**) + `scenes` + CTA con el código; música `hype` | `bullets` |
| `custom` | solo lo que declares | `caption` |

La plantilla solo decide qué escenas se generan y los valores por defecto (música, transiciones, fondos): cualquier combinación de `kind` funciona en cualquier plantilla.

### 4.3 Tipos de escena (`kind`)

Campos comunes: `id`, `duration` (s o `"auto"`; la narración puede alargarla), `transition` (`fade`, `slide-up`, `slide-down`, `slide-left`, `slide-right`, `zoom`, `zoom-out`, `wipe`, `wipe-up`, `circle`, `flash`, `glitch`, `cut`), `transitionDur` (0.4), `bg`, `scrim` (0‒1, oscurecido del fondo), `particles`, `narration`, `subtitle`, `narrationFile`, `narrationDelay`, `captions:false`, `subY`, `sfx:[{at,type,gain,pan}]`.

| kind | Campos específicos | Efectos |
|---|---|---|
| `hook` | `text, sub, emoji, kicker, chip` | palabras que "golpean" (slam + sacudida), flash, emoji pop, zoom lento |
| `caption` | `text, titleAnim` (`pop`/`rise`/`slam`), `chips[{text,emoji,at,x,y,style,rot,counter}]`, `stickers[{emoji,at,x,y,size,rot}]`, `images[{src,at,x,y,w}]` | título cinético arriba; chips/stickers/PNG con pop; chip con contador (`counter:{from,to,dur,prefix,suffix,decimals}`). `x,y` = fracción de la zona segura. `style`: `white`,`dark`,`hot`,`bad`,`good`,`accent`. |
| `rank` | `rank, total, title, sub, emoji, image, stat{label,from,to,prefix,suffix,decimals,at}` | insignia "TOP #n" (oro/plata/bronce), puntos de ranking, contador |
| `counter` | `label, from, to, prefix, suffix, decimals, emoji, at, countDur, sub` | número gigante rodando con barra y "rebote" final, ticks de SFX |
| `compare` | `text, before{label,bg}, after{label,bg}, wipeAt, wipeDur, stats[{label,before,after,prefix,suffix,decimals}]` | cortinilla antes/después sobre dos fondos (`bg` admite clip/imagen/procedural), barras comparativas con contadores |
| `stages` | `text, stages[{label,value,emoji}], prefix, suffix, decimals, firstAt` | progresión: valor que sube etapa a etapa, barra de XP con hitos, lista que se ilumina |
| `offer` | `kicker, headline, discount, discountLabel, items[{emoji,label}], code, codeLabel, codeAt, endsIn, endsLabel, countRate, flash` | cinta parpadeante, estrella giratoria con descuento, cuenta atrás HH:MM:SS, código que se "teclea" con brillo |
| `bullets` | `text, items[{emoji,text,at}]` | tarjetas que entran deslizando |
| `cta` | `text, sub, button, emoji, handle, code, codeLabel` | botón con pulso y brillo, mano "tap", código, confeti |

Las escenas se solapan durante la transición; la duración de cada escena es su tiempo propio. Si el contenido no cabe en la zona segura se reduce automáticamente (texto y bloque).

### 4.4 Fondos (`bg`)

Cadena (`"runner"`) u objeto `{type, …}`. Comunes: `seed`, `speed`, `particles` (`coins`, `confetti`, `stars`, `sparks`), `scrim` (0‒1), `punch`.

| `type` | Notas |
|---|---|
| `runner` | pseudo-3D de 3 carriles con personaje de bloques, monedas y obstáculos. **Sustituto de gameplay** para maquetar. Continuo entre escenas (`continuous:false` para reiniciar). |
| `grid` (synthwave), `rays`, `blocks` (cubos isométricos), `gradient`, `color` | fondos de apoyo |
| `image` | `{src, zoom, kenburns:false}` — imagen con Ken Burns suave |
| `video` | `{src, trim, speed, loop, pingpong, zoom}` — clip externo (ver §6) |

### 4.5 Subtítulos con resaltado de palabra

Cada escena con `narration` (hablada si hay TTS/archivo) o `subtitle` (solo texto) genera subtítulos quemados, en trozos de 3 palabras (5 en apaisado) con la palabra activa resaltada y "pop". Con narración (TTS o `narrationFile`) el reparto de tiempos usa la **duración real del audio**, repartida por longitud de palabra y puntuación; sin audio se reparte sobre la escena. No hay alineación forzada palabra a palabra (ver limitaciones). `captions:false` los apaga en una escena; `subY` mueve su altura.

### 4.6 Audio

```json
"audio": {
  "music": { "style": "hype", "bpm": 140, "key": "A", "volume": 0.55, "seed": 7 },
  "sfx": true, "sfxVolume": 0.8,
  "narration": { "engine": "espeak", "voice": "es-la", "speed": 150, "pitch": 48, "delay": 0.3, "volume": 1 },
  "voiceover": { "file": "assets/voz.mp3", "start": 0 },
  "duck": true, "loudness": -14, "beatPulse": true
}
```

- **Música** (`false` la quita; `"hype"` abrevia): sintetizada con semilla, **libre de derechos** (`hype` 140 BPM, `arcade` 128 chiptune, `chill` 88 lo-fi, `epic` 100 cinematográfica; bombo con sidechain, reverb/eco). O trae la tuya: `"music": {"file": "assets/tema.mp3"}` (en bucle, recortada; tú respondes de su licencia). Con música sintética el fondo "late" con el pulso (`beatPulse`).
- **SFX** automáticos, alineados con lo que ocurre en pantalla (impactos del gancho, pops de chips, ticks de contadores, whoosh de transiciones, ding/coin/success…). Tipos: `pop, hit, tick, whoosh, swipe, impact, ding, coin, riser, success, alarm, boom`. Extra por escena: `"sfx":[{"at":1.2,"type":"boom","gain":0.9}]`.
- **Narración**: `engine:"espeak"` sintetiza `narration` de cada escena (voz **robótica**, ver §7); `narrationFile` por escena o `audio.voiceover` global aceptan locución externa (cualquier formato de ffmpeg); la duración del audio alarga la escena si hace falta.
- **Mezcla**: música ducked ≈ −11 dB bajo la voz (`sidechaincompress`, medido: −14.2 → −25.5 dB), `loudnorm` a −14 LUFS (medido −14.8 LUFS, LRA 3.1), limitador. AAC 192 kb/s, 44.1 kHz estéreo.

## 5. Ejemplos incluidos

| Spec | Plantilla | Formato | Notas |
|---|---|---|---|
| `specs/ejemplo-gancho.json` | a) gancho + gameplay + CTA | 9:16, 19 s | fondo `runner`, chips con contador, subtítulos |
| `specs/ejemplo-top.json` | b) top/lista | 9:16, 13.6 s | cuenta atrás #3→#1, música `arcade` |
| `specs/ejemplo-progresion.json` | c) antes/después + progresión | **16:9**, 15.4 s | `compare` + `stages`, música `epic` |
| `specs/ejemplo-oferta.json` | d) oferta con código | 9:16, 16.2 s | narración eSpeak + ducking, cuenta atrás, código `SUPER50` (ficticio) |

Juegos y códigos de los ejemplos son **ficticios** (marcados en `legal`).

## 6. Enchufar clips de IA o capturas de Studio

Cualquier escena (o el `bg` global) puede usar un clip como fondo; el pipeline lo trocea a frames con ffmpeg (recorte "cover" al tamaño de salida, cacheado en `.cache/frames/`) y el player los muestra sincronizados con la línea de tiempo.

```json
{
  "bg": { "type": "video", "src": "assets/veo-gameplay-01.mp4", "scrim": 0.25 },
  "hook": { "text": "¿SOBREVIVES *60 SEGUNDOS*?" },
  "scenes": [
    { "kind": "caption", "duration": 4, "text": "Esquiva *TODO*",
      "bg": { "type": "video", "src": "assets/studio-captura.mp4", "trim": 0 } },
    { "kind": "caption", "duration": 4, "text": "Mejora tu *PERSONAJE*",
      "bg": { "type": "video", "src": "assets/studio-captura.mp4", "trim": 4 } },
    { "kind": "caption", "duration": 3, "text": "Logo encima",
      "bg": { "type": "image", "src": "assets/key-art.png" },
      "images": [{ "src": "assets/logo.png", "w": 420, "x": 0.5, "y": 0.55, "at": 0.4 }] }
  ]
}
```

Pasos recomendados:

1. Coloca los archivos junto al spec (p. ej. `assets/`) y referencia **rutas relativas** al spec.
2. **Veo / Kling / Runway / Sora**: genera o exporta en vertical 9:16 (≥ 720×1280; se reescala con "cover", así que un 16:9 se recorta al centro) y guarda `.mp4`/`.mov`/`.webm`. Los clips de IA suelen durar 5‒10 s: úsalos con `trim` por escena para encadenar tomas, o deja que se repitan (`loop`, por defecto; `pingpong:true` va y vuelve; el pipeline avisa cuando repite). Que sea un solo plano continuo más largo no hace falta: concatena varias escenas con `trim` distinto.
3. **Capturas de Roblox Studio** (o de una sesión de juego): graba con el grabador de Studio u OBS en vertical o recorta a 9:16; igual que arriba. `speed` acelera/ralentiza (`1.25` = +25 %), `zoom` añade un empuje lento.
4. El audio del clip se **ignora** (la banda sonora la construye el pipeline). Si quieres su sonido, extráelo (`ffmpeg -i clip.mp4 -vn audio.wav`) y pásalo como `audio.music.file` o `audio.voiceover`.
5. Si el clip es más oscuro/claro de lo que conviene para leer el texto, ajusta `scrim` (0‒1). Para solo imágenes fijas usa `type:"image"` (Ken Burns incluido, `kenburns:false` para estático).
6. `compare` acepta clips/imágenes en `before.bg` y `after.bg` (p. ej. captura "antes" vs "después" de una tienda o base).
7. Coste: 1080×1920 ≈ 150‒300 KB por frame en caché (≈ 5‒9 MB por segundo de clip). Borra `.cache/frames` cuando quieras.

> Aviso de contenido: marca como "no es gameplay" lo que sea arte/maqueta, y no uses clips generados que sugieran funciones que el juego no tiene (reglas de publicidad de cada plataforma: **[NO VERIFICADO]** aquí, revisarlas antes de publicar).

## 7. Narración (TTS) y limitaciones de red

- **Disponible aquí**: eSpeak (`mespeak`, JS puro, voces `es-la`, `es`, `pt`, `en/…`). Es inteligible pero **robótico**: sirve para pruebas, para fijar tiempos de subtítulos y para demostrar el ducking; **no es apto para publicar**. (Licencia: `mespeak` es GPL y es dependencia *opcional*; el audio generado no queda "contagiado", pero ten en cuenta la licencia si lo redistribuyes.)
- **No hay un TTS decente alcanzable desde esta red.** Comprobado: `huggingface.co` y `cdn-lfs.huggingface.co` (sin conexión), `github.com/rhasspy/piper/releases` (403), `api.openai.com`, `api.elevenlabs.io`, `speech.platform.bing.com` (sin conexión). PyPI sí responde (el paquete `piper-tts` existe), pero sus **voces** viven en Hugging Face. Para activar una voz neuronal local habría que permitir: `huggingface.co` + `cdn-lfs.huggingface.co` (voces Piper en español, repositorio `rhasspy/piper-voices`) y `github.com`/`objects.githubusercontent.com` (binarios de Piper) *[TERCERO, no verificado desde aquí]*.
- **Alternativa inmediata**: genera la locución fuera (ElevenLabs, OpenAI TTS, Piper en tu PC…) y pásala con `narrationFile` (por escena) o `audio.voiceover`; el pipeline hace el ducking, la mezcla y los subtítulos con la duración real.

## 8. Producir muchos vídeos

```bash
# 1) variantes: fusión profunda sobre una base + "$set" por ruta con puntos
node variants.mjs specs/ejemplo-gancho.json variantes.json specs/generados
# variantes.json: [ {"id":"v1","palette":"sunset","hook":{"text":"¿LLEGAS AL *NIVEL 50*?"},"$set":{"scenes.0.text":"Salta y *VUELA*","cta.code":"SUN50"}}, … ]

# 2) renderizar todo
node render.mjs --all specs/generados out/generados
```

(Los `src` relativos se resuelven respecto a la carpeta del spec generado: genera en una carpeta hermana de `assets/` o usa rutas que sirvan desde allí.) `--all` renderiza en serie y cada vídeo ya usa los 4 CPUs.

## 9. Rendimiento medido (4 vCPU, sin GPU, 30 fps, CRF 24 `veryfast`)

| Vídeo | Salida | Duración | Captura | Codificación | **Total** | Tamaño |
|---|---|---|---|---|---|---|
| ejemplo-gancho | 1080×1920 | 19.0 s | 30.4 s (20 fps) | 15.6 s | **46 s** | 5.75 MB |
| ejemplo-oferta (TTS) | 1080×1920 | 16.2 s | 16.1 s (32 fps) | 12.9 s | **29 s** | 4.47 MB |
| ejemplo-progresion | 1920×1080 | 15.4 s | 23.3 s (21 fps) | 13.0 s | **36 s** | 4.81 MB |
| ejemplo-top | 1080×1920 | 13.6 s | 17.9 s (24 fps) | 9.4 s | **27 s** | 3.86 MB |

≈ 2‒2.5 s de cómputo por segundo de vídeo (con audio, que va en paralelo y cuesta <1 s). Notas de ingeniería:

- El cuello de botella es la **captura** (compositado y JPEG por software). **Un navegador por worker** escala a ≈ 22 fps con 4 workers frente a ≈ 14 fps con 4 contextos de un mismo navegador (el compositor se comparte y serializa). `--disable-gpu`/`--disable-software-rasterizer`/`--num-raster-threads` no mejoraron; SwiftShader/ANGLE empeoró 10×.
- Codificación: `veryfast` tarda ≈ 2× menos que `medium` con tamaño casi idéntico en este contenido; usa `--preset slow --crf 18` para una entrega final.
- Reduce coste en borradores con `--scale 0.5` (≈ 3×) y `--max`.

## 10. Cómo funciona por dentro (para extender)

- `lib/compile.mjs` es la **única fuente de verdad de tiempos**: calcula inicio/fin de escenas (con solape de transición), tiempos por palabra, cues de SFX, trozos de subtítulos y descarga de clips a frames. El navegador solo lee ese JSON (`window.__SPEC__`).
- `window.renderFrame(t)` (en `player/runtime.js`) coloca escenas, transiciones, barra de progreso, subtítulos y flash para el instante `t` y devuelve una promesa (espera a que decodifiquen las imágenes/frames de fondo). Cada tipo de escena es `(sc, C) => update(lt)` en `player/scenes.js`; un fondo nuevo es una función `(ctx, t, W, H, pal, desc)` en `player/bg.js`.
- Para añadir un tipo de escena: (1) caso en `compile.mjs` (datos + tiempos + SFX), (2) `K.mi_tipo` en `scenes.js`, (3) entrada en `KIND_DUR`.

## 11. Limitaciones conocidas

- Los fondos procedurales (`runner`, `grid`, …) son **placeholders** para maquetar; el gameplay real hay que grabarlo (Studio) o generarlo (IA) y enchufarlo (§6). No se ha probado con clips de Veo/Kling/Runway/Sora reales (esos servicios no son alcanzables desde este entorno): solo con clips y capturas sintéticas de ffmpeg.
- Sin TTS neuronal local (ver §7). Los subtítulos no usan alineación forzada: los tiempos por palabra son una estimación proporcional a la duración real del audio (con voz externa muy expresiva pueden desviarse unas décimas).
- La música es procedural y sencilla (útil como cama libre de derechos, no como producción musical). No he podido *escucharla*: se validó por espectrograma, picos y niveles; conviene revisarla a oído.
- Solo fuentes del sistema o `.ttf/.otf` propios (`fonts`). Emojis con Noto Color Emoji (pueden verse distintos a los de cada plataforma).
- Layouts pensados para 9:16; 16:9 y 1:1 se adaptan (filas en `offer`/`rank`, reducción automática del bloque) pero 4:5 y 1:1 están menos probados. Textos muy largos se reducen y pueden quedar pequeños: mejor frases cortas.
- Las zonas seguras son aproximadas y dependen de cada app/dispositivo.
- Capas de vídeo solo como fondo (no hay PiP de varios clips ni máscaras); imágenes con transparencia sí (`images`).
- Intermedios en JPEG q94 (`--png` para sin pérdida). Solo probado en Linux/x64 con Chromium headless-shell de Playwright 1.56 y ffmpeg 6.1.
- Sin GPU el render es CPU-bound (2‒2.5× tiempo real con 4 CPUs).

## 12. Solución de problemas

- `No se encontró Chromium` → `CHROMIUM_PATH=/ruta/chrome` o `PLAYWRIGHT_BROWSERS_PATH`.
- `Tipo de escena desconocido` → revisa `kind` (válidos: hook, caption, rank, counter, compare, stages, offer, bullets, cta).
- Texto cortado/solapado → `--stills t1,t2` + `--guides` para inspeccionar; acorta el texto o sube `duration`.
- `[aviso] Clip … se repite en bucle` → el clip es más corto que la escena; alarga el clip, acorta la escena o usa `pingpong`.
- Espacio en disco → borra `.cache/` (frames de clips, TTS) y `out/_work`.
