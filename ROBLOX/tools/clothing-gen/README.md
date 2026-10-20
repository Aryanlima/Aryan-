# clothing-gen — generador procedural de ropa clásica 2D para Roblox

Genera **texturas PNG de camisas, pantalones y camisetas (T-shirt) clásicas** con patrones **100 % originales y matemáticos** (rayas, degradados, tie-dye, camuflaje, rombos, zigzag, lunares, triángulos, olas, vichy, moteado, texto), las comprueba automáticamente (QC) y deja un `manifest.csv` listo para subirlas **a mano** al Creator Dashboard.

> Estado: probado en Python 3.13 / Pillow 13 / NumPy 2.5 en Linux sin GPU. **No probado en Roblox Studio ni subido a Roblox** (no hay Studio en este entorno). Ver [Límites](#límites-y-lo-que-no-se-pudo-verificar).

## Por qué las coordenadas son fiables

Las regiones **no están inventadas**. Salen de la plantilla oficial `Classic-Clothing-Templates.zip` (585 × 559 px, RGBA) del repo `Roblox/creator-docs` (licencia CC BY 4.0), enlazada desde la doc oficial [Classic clothing](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/classic-clothing.md):

- `clothgen/layout.py` guarda las 18 cajas `(x, y, w, h)` (6 caras × torso, brazo/pierna derecha, brazo/pierna izquierda).
- `verify_layout.py` **re-mide** esas cajas sobre los píxeles de `templates/Template-*.png` (componentes conexos de cada color de región) y comprueba que coinciden; además verifica el SHA-256 de las plantillas contra el `oid` del puntero Git LFS oficial.
- Los tamaños coinciden con la tabla oficial: 128×128 (FRONT/BACK), 64×128 (lados), 128×64 (UP/DOWN del torso), 64×64 (U/D de brazos y piernas).

```
$ ./venv/bin/python verify_layout.py
sha256 Template-Shirts-R15.png: OK
sha256 Classic-Clothing-Templates.zip: OK
Template-Shirts-R15.png: lienzo (585, 559), 18 regiones medidas, layout.py coincide: True
Template-Pants-R15.png: lienzo (585, 559), 18 regiones medidas, layout.py coincide: True
RESULTADO: OK
```

Origen exacto de los archivos en `templates/SOURCE.md`. Las plantillas contienen el logo de Roblox: **solo sirven de referencia de geometría**; el generador nunca copia sus píxeles (fondo transparente) porque la política del Marketplace prohíbe usar branding de Roblox.

## Inicio rápido

```bash
cd ROBLOX/tools/clothing-gen
./run_demo.sh                       # crea venv, verifica layout, corre pruebas, genera ejemplos en out/
# o a mano:
python3 -m venv venv && venv/bin/pip install -r requirements.txt
venv/bin/python -m clothgen list    # patrones, paletas y temporadas
venv/bin/python -m clothgen set --pattern stripes --palette sunset --param orient=d --param size=20 --seed 7 --out out/demo --id demo
venv/bin/python -m clothgen shirt --pattern triangles --palette neon --text-front "NIGHT SHIFT" --collar "#ff2bd6" --cuff "#0b0b1a" --out out/demo --id neon
venv/bin/python -m clothgen tshirt --pattern tiedye --palette candy --shape hexagon --text "GOOD VIBES" --out out/demo --id tee1
venv/bin/python -m clothgen tile --pattern camo --palette desert --size 512 --out out/tiles   # tesela seamless para texturas 3D
venv/bin/python -m clothgen seamless --input mi_imagen_ia.png --out out/tiles/mi_tesela.png   # hace seamless una imagen cualquiera
venv/bin/python -m clothgen shirt --pattern image --param path=out/tiles/mi_tesela.png --param scale=0.5 --out out/demo --id ia-01   # usa TU tesela como estampado
venv/bin/python -m clothgen batch --config batch.example.json --out out/example
venv/bin/python -m clothgen collection --n 24 --theme christmas --kind set --lang en --unique-patterns --out out/xmas
venv/bin/python -m clothgen qc --dir out/example
```

Cada ítem produce: `<id>-shirt.png` / `<id>-pants.png` (585×559 RGBA) o `<id>-tshirt.png` (512×512 RGBA), `previews/<id>-mock.png` (muñeco plano frente/espalda), `previews/<id>-*-overlay.png` (diseño sobre las regiones oficiales con contornos magenta), `manifest.csv` y `qc_report.json`. Las colecciones añaden `previews/_contact_sheet.png`.

## Patrones (todos periódicos: dan la vuelta al cuerpo sin costura)

| Patrón | Parámetros útiles (`--param k=v`) |
|---|---|
| `stripes` | `orient=v/h/d/d2`, `size` (px por franja) |
| `gradient` | `axis=v/u`, `bands` (posterizado), `noise` |
| `tiedye` | `centers`, `ring` (ancho de color en px), `warp`, `edge` |
| `camo` | `cell` (tamaño de mancha), `block` (>0 = pixelado digital) |
| `checks`, `gingham` | `size` |
| `diamonds` | `size` |
| `chevron` | `size`, `band` |
| `dots` | `size`, `radius` |
| `triangles` | `size`, `jitter` |
| `waves` | `size`, `amp` |
| `speckle` | `density` |
| `solid` | — |
| `image` | `path=tu_tesela.png`, `scale` (repite TU imagen —p. ej. salida de una IA con licencia comercial— un número entero de veces alrededor del cuerpo) |

`clothgen seamless` convierte cualquier imagen en tesela sin costura (mezcla de bordes con la imagen desplazada media vuelta); en una prueba con un degradado sintético la costura bajó de 168 a 11 (escala 0-255) según `qc.tile_seam_score`.

Paletas (`--palette`): `sunset ocean forest candy mono autumn neon pastel midnight desert berry mint halloween christmas valentine spring summer`, o una lista `'#ff0000,#00ff00,...'`. Para patrones de 2 colores el generador reordena la paleta para asegurar contraste legible.

Opciones de prenda: `--sleeve long|short|sleeveless`, `--length long|shorts`, `--torso-coverage 0..1` (pantalón), `--hem`, `--cuff`, `--collar`, `--text-front`, `--text-back`, `--font ruta.ttf`, `--text-size`. Sin `--font` se usa la fuente integrada de Pillow (Aileron Regular según el código fuente de Pillow; su licencia exacta [NO VERIFICADO] aquí): para texto en ítems comerciales usa una fuente con licencia clara, p. ej. las OFL (Fredoka/Nunito) que ya están en `ROBLOX/marketing/fish-and-fortune/specs-video/fonts/`.

### Cómo se evita la costura
El torso es un cilindro de 384 px (R 64 + FRONT 128 + L 64 + BACK 128), cada brazo/pierna de 256 px (4 caras de 64). Todos los patrones se evalúan sobre esa coordenada "desenrollada" y son periódicos en ese período, así que el borde derecho de BACK enlaza con el izquierdo de R. `tests/test_periodic.py` lo comprueba llamando a cada patrón dos vueltas seguidas y exigiendo `f(U + C) == f(U)`.

## Control de calidad (`qc.py`)

Por archivo: PNG, tamaño exacto 585×559 (o cuadrado en T-shirt), RGBA, **cero píxeles opacos fuera de las regiones oficiales**, cobertura mínima, aviso de costura de cierre, **texto contra `ip_blocklist.txt`** (marcas/IP; lista de ayuda editable, no una garantía legal). Por lote: **casi-duplicados** (dHash 16×16) porque la política pide no subir ítems demasiado parecidos entre sí. El comando termina con código 1 si algo falla (útil en scripts / Claude Code).

## Límites y lo que no se pudo verificar

- **Sin prueba en Studio**: el aspecto real sobre un avatar (orden de capas camisa/pantalón, cómo se ve cada cara) no está verificado. El `mock` es una aproximación 2D plana, no un render 3D. Probar siempre con *Avatar → Character → Block Avatar* y un objeto `Shirt`/`Pants` antes de pagar tarifas (la prueba en Studio no cuesta, según la doc oficial).
- Los **2 px de separación** entre caras de la plantilla se dejan transparentes.
- Las **líneas punteadas** (torso y=170, brazos/piernas y=407, medidas en el PNG oficial) marcan "límite máximo de altura de guantes y detalles de la parte baja de la pierna (solo R15)". Los puños/dobladillos del generador (10 px en el borde inferior) y las mangas/shorts cortos (56/64 px) son **decisiones de estilo propias**, no medidas oficiales.
- El pantalón pinta por defecto todo el torso (`--torso-coverage 1.0`); cuánto del torso conviene pintar es algo a probar en Studio.
- **Subida**: no existe API oficial para subir Shirt/Pants/T-Shirt (ver `research/09-ropa-produccion-con-ia.md`); la subida y el pago de tarifas son manuales. El manifiesto trae columnas vacías (`uploaded_by_hand`, `asset_id`, `price_robux`) para llevar el control.
- No hay IA generativa aquí (sin GPU). Los patrones son matemáticos. Para diseños ilustrados, genera con una herramienta de IA con licencia comercial y úsalos como entrada propia (ver el informe).

## Estructura

```
clothgen/layout.py     coordenadas oficiales verificadas
clothgen/patterns.py   patrones periódicos (numpy)
clothgen/palettes.py   paletas originales + estacionales
clothgen/garment.py    camisa / pantalón / T-shirt / tesela
clothgen/qc.py         validaciones, blocklist, casi-duplicados
clothgen/preview.py    overlay, muñeco plano, hoja de contactos
clothgen/naming.py     nombres/descripciones sin keyword-stuffing
clothgen/cli.py        comandos
templates/             plantillas oficiales (referencia) + SOURCE.md
tests/                 periodicidad + layout
examples/              muestras generadas (pequeñas)
ip_blocklist.txt       términos a evitar (editable)
```

Añadir un patrón: escribe `def mi_patron(U, V, C, H, pal, seed=0, wrap_v=False, **kw)` que devuelva un array `(h, w, 3)`, hazlo periódico en `U` con período `C` (usa `fit(size, C)` para ajustar el número de repeticiones a un entero), regístralo en `PATTERNS` y corre los tests.

## Reglas de diseño (política de Roblox)

Ver el informe. Resumen: nada de marcas ni personajes de terceros, nada del logo/iconografía de Roblox, sin "texto excesivo", sin contenido político/religioso/sexual/violento, sin copiar ítems de otros; ID verificada + Premium/Plus para publicar.
