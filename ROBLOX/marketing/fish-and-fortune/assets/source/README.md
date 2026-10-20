# source — código que genera los placeholders de Fish & Fortune

Todo el arte es SVG escrito con funciones de JavaScript (sin imágenes externas ni IA). `render-assets.mjs` convierte cada SVG en PNG con Chromium (Playwright), lo optimiza con ImageMagick, valida contra las reglas oficiales y arma la hoja de contactos. Resultado en `../icon`, `../thumbnails`, `../passes`, `../products`, `../contact-sheet.png` y `../assets-manifest.json`.

## Uso
```bash
npm install                        # instala playwright-core (node_modules/ está en .gitignore)
node render-assets.mjs             # todo (~1 min)
node render-assets.mjs --only=vip,starter --no-sheet
node render-assets.mjs --validate-only
```
- **Chromium:** usa `CHROMIUM_PATH` si existe; si no, busca en `PLAYWRIGHT_BROWSERS_PATH`, `/opt/pw-browsers`, `~/.cache/ms-playwright` y `%LOCALAPPDATA%\ms-playwright`. No ejecuta `playwright install`: si no tienes navegador, instala uno tú (`npx playwright-core install chromium`) o apunta `CHROMIUM_PATH` a Chrome/Chromium.
- **ImageMagick:** `magick` (v7, Windows/macOS) o `convert` (v6, Linux).
- **Fuentes:** `../../specs-video/fonts/Fredoka.ttf` y `Nunito.ttf` (SIL OFL 1.1, con sus licencias al lado). El SVG las carga por ruta relativa (`@font-face`), así que **abre bien en un navegador** sin instalar nada.

## Estructura
| Archivo | Qué contiene |
|---|---|
| `lib/core.mjs` | Paleta oficial (`C`), `<defs>` (degradados y filtros), `svgDoc()`, texto con contorno y el logotipo (`wordmark`) |
| `lib/parts.mjs` | Piezas: `fortu` (mascota), `fish`, `whale` (Mítico), `shell` (concha = "moneda" sin monedas), `pearl`, `bobber`, `rod`, olas, rayos, estrellas de rareza |
| `lib/scenes.mjs` | Cielo+lago, agua frontal, muelle, pescadores, río, costa y libro del bestiario |
| `lib/assets.mjs` | **Manifiesto**: id, carpeta, tamaño, clave de `ProductIds` y función que dibuja cada pieza; lista `DISABLED` (suerte, apagada en v1) |
| `render-assets.mjs` | Render, optimización, validación y hoja de contactos |
| `svg/` | SVG generados (se pueden editar/abrir en el navegador o en un editor vectorial) |
| `build/` | Temporal (HTML, renders crudos, máscaras); ignorado por git |

## Convenciones para que la validación funcione
- Íconos de 512×512: el fondo va en `<g id="bg">` (cubre las 4 esquinas) y el sujeto en `<g id="subject">`. Lo decorativo que no debe contar para el círculo seguro (agua, resplandores) lleva `class="deco"`. El script renderiza el sujeto solo, sobre transparente, y cuenta píxeles fuera del círculo de **radio 230** (diámetro 460 px = 90 %).
- Todo texto que deba medirse lleva `class="t"` y `data-contrast="#RRGGBB"` (lo hace `outlined()` y `wordmark()`); el script mide el contraste frente al fondo real (render sin texto) y frente al contorno, y comprueba que no invada el 15 % inferior en miniaturas.
- Un SVG por pieza; los `id` internos de degradados usan un `uid` único por pieza.

## Añadir o cambiar una pieza
1. Escribe la función de dibujo en `lib/assets.mjs` (copia una existente) y añade una entrada a `ASSETS` con `id`, `group` (`icon|thumbnail|pass|product`), `dir`, `w`, `h`, `key`.
2. `node render-assets.mjs --only=<id> --no-sheet` y mira `../<dir>/<id>.png`.
3. Antes de dar por buena la pieza, ejecuta el render completo (actualiza la hoja y `assets-manifest.json`).

## Optimización
PNG sin alfa ni metadatos (`-strip`); si una pieza supera 200 KB (650 KB las miniaturas) se cuantiza a 256 colores con difuminado Floyd-Steinberg (el degradado se conserva). Resultado ≈ 8 MB en total.
