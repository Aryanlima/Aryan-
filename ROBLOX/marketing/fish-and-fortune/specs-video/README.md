# specs-video — 6 vídeos de marca de Fish & Fortune (pipeline de renderizado por código)

Fecha: 2026-10-20. Renderizador: `marketing/pipeline/render.mjs` (otro agente; **no se ha modificado**). Estos vídeos son **gráficos de marca** (texto, emojis, partículas, música sintetizada): **no son gameplay**, así que sirven para TikTok, Shorts, Reels y Discord, **nunca para la página del juego en Roblox** (allí solo vale gameplay real sin voz ni anuncios [OFICIAL `thumbnails.md`]). Cada vídeo lleva en pantalla la línea legal "Fish & Fortune es gratis con compras opcionales con Robux. Imágenes de marca, no es gameplay."

## Estado del renderizador
`marketing/pipeline/README.md` **no existía** al hacer este trabajo; el formato del spec se dedujo del código (`lib/compile.mjs`, `player/*.js`) y de los 4 ejemplos de `marketing/pipeline/specs/`. `node render.mjs --help` funciona (Node 22.22, Chromium headless de `/opt/pw-browsers`, ffmpeg del sistema). Los 6 specs compilan sin avisos y se renderizaron completos.

## Cómo renderizar
Desde cualquier carpeta, con las rutas del repo:

```bash
# uno
node marketing/pipeline/render.mjs ROBLOX/marketing/fish-and-fortune/specs-video/ff-01-gancho-mitico.json out/ff-01.mp4 --crf 21 --report
# todos (los .json de una carpeta)
cd ROBLOX/marketing/fish-and-fortune/specs-video && node ../../../../marketing/pipeline/render.mjs --all . out --crf 21 --report
# revisión rápida: fotogramas sueltos a media resolución
node marketing/pipeline/render.mjs <spec.json> <carpeta_pngs> --stills 1,5,9 --scale 0.5
```

Las rutas relativas del spec (`fonts/Fredoka.ttf`, y los `bg.src` de clips) se resuelven **respecto a la carpeta del spec**. Los MP4 ya generados están en `out/` junto con su informe `.json` (opción `--report`).

## Alineación con el juego real
Los specs usan datos de `ROBLOX/games/fish-and-fortune/src/shared/Balance.luau` (leído el 2026-10-20, **provisional**; el juego aún no tiene cliente/UI): zonas Lago Calmo / Río Cristal / Costa Dorada, 25 criaturas, rarezas (Raro, Legendario, **Mítico**), mini-juego de recogida en la zona perfecta (+1 punto de suerte gratis), evento **Marea Dorada** (monedas por venta ×2, semanas que empiezan el 30-nov, 14-dic y 28-dic) y código **`WELCOME`** (1.000 monedas + 5 perlas, sin caducidad en la config actual). Los Míticos son ≈ 0,04 % por lanzada con suerte 0: ningún vídeo promete que "caerá uno" (el gancho es una pregunta: "¿Podrás pescar un MÍTICO?"). `ff-02` muestra los % **base del Lago Calmo** (4,50 % / 0,60 % / 0,04 %, calculados de los pesos 45 / 6 / 0,4 sobre 999,4). **Si cambia el balance, hay que recalcular o quitar los `stat`.**

## Los 6 specs

| Spec | Plantilla | Aspecto | Duración | Guion | MP4 renderizado | Qué hay que confirmar antes de publicar |
|---|---|---|---|---|---|---|
| `ff-01-gancho-mitico.json` | `hook-gameplay-cta` | 9:16 | 18,2 s | V03 | `out/ff-01-gancho-mitico.mp4` (7,2 MB) | Que el aviso de Mítico y los textos coincidan con la UI final |
| `ff-02-escalera-rareza.json` | `top-list` | 9:16 | 17,4 s | V07 | `out/ff-02-escalera-rareza.mp4` (6,9 MB) | Que los % base sigan siendo los de `Balance.luau` (panel Probabilidades = fuente de verdad) |
| `ff-03-zonas-progresion.json` | `progression` | 9:16 | 15,0 s | V11 | `out/ff-03-zonas-progresion.mp4` (6,7 MB) | Nombres y orden de zonas |
| `ff-04-evento-semanal.json` | `custom` | **16:9** | 15,1 s | V19 | `out/ff-04-evento-semanal.mp4` (6,2 MB) | Que la config de eventos mantenga Marea Dorada del 14 al 21-dic (inicio y fin lunes 00:00 UTC) |
| `ff-05-codigo-lanzamiento.json` | `custom` | 9:16 | 14,9 s | V22 | `out/ff-05-codigo-lanzamiento.mp4` (5,0 MB) | **No publicar** hasta que el botón "Códigos" exista y el canje esté probado; si se añade `expiresAt`, poner la fecha real |
| `ff-06-tutorial-15s.json` | `custom` | 9:16 | 14,2 s | V15 | `out/ff-06-tutorial-15s.mp4` (4,7 MB) | Que la UI del mini-juego coincida con los 3 tips |

Tamaños con `--crf 21` (el defecto del pipeline es 18, más pesado). Total ≈ 37 MB: valorar si se versionan en git o se regeneran.

## Verificación hecha (2026-10-20)
- `ffprobe` de los 6 MP4 finales: H.264 (High, yuv420p) + AAC estéreo 44,1 kHz; 30 fps; 1080×1920 (cinco verticales) y 1920×1080 (`ff-04`); duraciones 18,2 / 17,4 / 15,0 / 15,1 / 14,9 / 14,2 s; nº de fotogramas = duración × 30 (546 / 522 / 450 / 453 / 447 / 426).
- Sonoridad de `ff-01` (versión anterior del mismo spec): −14,6 LUFS integrados, cerca del objetivo −14 LUFS del pipeline.
- Revisión visual de fotogramas **extraídos de los MP4 finales** con ffmpeg: `ff-02` a 10 s (Legendaria con "BASE EN EL LAGO 0,60 %"), `ff-04` a 5 s (lista de Marea Dorada, 16:9), `ff-05` a 9 s ("Recibes 1.000 monedas y 5 perlas"), `ff-06` a 9 s (3 tips). Antes del render completo se revisaron fotogramas de prueba (`--stills`) y se corrigieron: títulos largos, chips que tapaban el título, subtítulos que duplicaban o solapaban listas, y la transición `flash` (pantalla blanca) del CTA de `ff-01`, cambiada por `circle`.
- Tiempo del render completo de los 6: 161 s con 4 workers (renders anteriores, con los textos previos a la alineación con `Balance.luau`: 249 s).

## Formato del spec (resumen, deducido de `lib/compile.mjs`)
- **Raíz:** `id`, `template` (`hook-gameplay-cta` | `top-list` | `before-after` | `progression` | `offer` | `custom`), `title`, `aspect` (`9:16` | `16:9` | `1:1` | `4:5`), `fps`, `palette` (nombre o objeto con `bg1,bg2,accent,accent2,hot,text,dim,good,bad`), `typography` (`heading`, `body`, `headingWeight`, `uppercase`), `fonts` (`family`, `file`, `weight`), `brand`, `bg`, `hook`, `scenes[]`, `items[]` (solo `top-list`), `cta`, `subtitles` (`{enabled,y}` o `false`), `progress`, `audio` (`music:{style:chill|arcade|epic|hype,volume}`, `sfx`, `narration:{engine:'espeak',voice,speed,pitch}`, `voiceover`), `legal`, `duration` (objetivo opcional), `safeZone`.
- **Tipos de escena (`kind`):** `hook`, `caption` (`text`, `stickers[]`, `chips[]`, `images[]`), `rank`, `counter`, `compare`, `stages`, `offer`, `bullets`, `cta`. Texto enriquecido: `*acento*`, `**acento2**`, `|` o `\n` = salto de línea.
- **Fondos (`bg.type`):** `gradient`, `rays`, `grid`, `blocks`, `runner`, `color`, `image` (con `src`), `video` (con `src`, `trim`, `speed`, `loop`). **Partículas:** `sparks`, `stars`, `coins`, `confetti`. **Transiciones:** `slide-up`, `slide-down`, `slide-left`, `slide-right`, `zoom`, `zoom-out`, `wipe`, `wipe-up`, `circle`, `flash`, `glitch`, `fade`.
- **Campos propios de este directorio:** `_nota` (ignorado por el compilador; guarda avisos de qué ajustar).
- **Opciones por escena útiles aquí:** `"captions": false` (sin subtítulos en esa escena; la `narration` queda como texto de guion), `"transition"` (fijar la transición, p. ej. para evitar `flash`), `duration` (segundos).

## Cómo adaptarlos
- **Poner voz:** grabar o generar la voz (ElevenLabs u otra con licencia comercial) y añadir por escena `"narrationFile": "voz/escena1.mp3"` o a nivel global `"audio": {"voiceover": {"file": "voz/todo.mp3"}}`. `audio.narration.engine: "espeak"` solo sirve para pruebas (voz robótica). Voz sintética realista = contenido de IA: divulgar.
- **Gameplay real de fondo:** en cualquier escena, `"bg": {"type": "video", "src": "../clips/mi-clip.mp4", "speed": 1}`; el pipeline extrae los fotogramas y dibuja el texto y el CTA encima. Respeta las reglas de `guiones-videos.md` (privacidad, entorno de pruebas).
- **Inglés:** copiar el spec, traducir los textos, `"locale": "en"` y renderizar con otro nombre de salida.
- **Otro formato:** `--aspect 1:1` o `--aspect 4:5` (se recoloca la zona segura automáticamente).
- **Datos reales:** `counter`/`stages`/`stat` aceptan números; usar **solo cifras reales** del panel de Analytics y de la tabla `Odds`.

## Licencias de los recursos
- **Fredoka** y **Nunito** (SIL Open Font License 1.1): descargadas de `github.com/google/fonts` (carpeta `ofl/`) el 2026-10-20, con sus textos `OFL-Fredoka.txt` y `OFL-Nunito.txt` en `fonts/`.
- **Emojis:** Noto Color Emoji del sistema (Google); la licencia exacta de sus componentes [NO VERIFICADO]; no se usan emojis de otros fabricantes.
- **Música y efectos:** sintetizados por código en `marketing/pipeline/lib/synth.mjs` (sin muestras ni terceros).
