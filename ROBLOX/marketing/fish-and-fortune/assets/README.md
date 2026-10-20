# Fish & Fortune — íconos, miniaturas, pases y productos (PLACEHOLDERS por código)

Fecha: 2026-10-20. Todo lo de esta carpeta está **hecho por código** (SVG → PNG con Chromium; no hay IA de imagen). Sirve para **desbloquear la publicación** (el juego ya puede tener ícono, miniaturas y arte de pases/productos) y para **probar A/B**. Cuando Aryan quiera, cada PNG se reemplaza por arte de IA conservando el nombre del archivo (ver "Cómo reemplazar por arte de IA").

Todo sigue el brand kit de `../prompts-ia.md` (§1) y `../pagina-del-juego.md`: nombre **Fish & Fortune**, paleta HEX (Azul Abismo `#0A1F44`, Azul Océano `#0F6E9E`, Teal `#19C3C0`, Oro Sol `#FFC83D`, Coral `#FF7A59`, Espuma `#F4FBFF`), tipografías **Fredoka** (títulos) y **Nunito** (OFL, de `../specs-video/fonts/`), mascota **Fortu** (pececillo dorado regordete, gorrito teal, escama-estrella en la mejilla izquierda, aletas coral) y estilo "3D cartoon suave".

**Revisión de un vistazo:** abre `contact-sheet.png` (iconos con vista previa a 150/110/64 px, miniaturas con la línea roja del 15 % inferior, pases y productos con el recorte circular de Roblox, y la lista de lo que NO se generó).

## 1. Archivos

### Íconos del juego (512×512, PNG)
| Archivo | Clave `ProductIds` | Tamaño | Estado |
|---|---|---|---|
| `icon/icon-a-mitico.png` | — (ícono del juego) | 512×512 | Placeholder listo. Idea 1: ballena-espíritu Mítica emergiendo + Fortu. Variante **A** del A/B |
| `icon/icon-b-fortu.png` | — | 512×512 | Placeholder listo. Idea 5: primer plano de Fortu; el más legible a 64 px. Variante **B** |
| `icon/icon-c-salto.png` | — | 512×512 | Placeholder listo. Pez dorado saltando al atardecer. Variante **C** |

Los íconos **no llevan texto** (el título del juego aparece debajo del ícono en Roblox).

### Miniaturas (1920×1080, PNG; ES y EN)
| Archivo | Texto | Tamaño | Estado |
|---|---|---|---|
| `thumbnails/thumb-1-mitico-{es,en}.png` | ¿UN MÍTICO? / A MYTHIC? | 1920×1080 | Placeholder listo (hero: Mítico + Fortu pescando) |
| `thumbnails/thumb-2-bestiario-{es,en}.png` | COMPLETA EL BESTIARIO / FILL THE BESTIARY | 1920×1080 | Placeholder listo. **Sustituir las criaturas por capturas reales del bestiario** antes de usarla (regla de `pagina-del-juego.md` §5, idea 3) |
| `thumbnails/thumb-3-amigos-{es,en}.png` | PESCA CON AMIGOS / FISH WITH FRIENDS | 1920×1080 | Placeholder listo. **[AJUSTAR A LO REAL]**: el co-juego no está confirmado en el código leído |
| `thumbnails/thumb-4-zonas-{es,en}.png` | EXPLORA 3 ZONAS / EXPLORE 3 ZONES | 1920×1080 | Placeholder listo (Lago, Río y Costa; `Balance.luau` tiene 3 zonas) |

Cada miniatura lleva el logotipo "Fish & Fortune" (con "&" en Oro Sol) y **≤ 3 palabras** de gancho; todo lo esencial queda por encima del 85 % de la altura (y < 918 px). Roblox permite activar de 2 a 5 miniaturas para la personalización de Home y una por idioma/lugar: sube las 4 ES (y las EN en la localización inglesa).

### Pases de juego (512×512, PNG)
| Archivo | Clave `ProductIds` (`passes.*`) | Tamaño | Estado |
|---|---|---|---|
| `passes/auto_fish.png` | `auto_fish` (Pase Auto-Pesca) | 512×512 | Placeholder listo: caña + bucle de flechas |
| `passes/double_coins.png` | `double_coins` (Pase 2x Dinero) | 512×512 | Placeholder listo: "x2" + conchas (sin monedas) |
| `passes/starter.png` | `starter` (Pack de inicio, pago único) | 512×512 | Placeholder listo: caja de aparejos (NO un cofre) |
| `passes/vip.png` | `vip` (Pase VIP) | 512×512 | Placeholder listo: anzuelo dorado + corona con estrella + cinta VIP |
| `passes/season_pass.png` | `season_pass` (Pase de Temporada 1) | 512×512 | Placeholder listo: medalla con ola y estrella, insignia "1" |

### Productos de desarrollador (512×512, PNG)
| Archivo | Clave `ProductIds` (`products.*`) | Tamaño | Estado |
|---|---|---|---|
| `products/coin_boost_15.png` | `coin_boost_15` (Boost de Monedas 15 min) | 512×512 | Placeholder listo: cronómetro + rayo |
| `products/coin_pack_small.png` | `coin_pack_small` | 512×512 | Placeholder listo: 3 conchas |
| `products/coin_pack_medium.png` | `coin_pack_medium` | 512×512 | Placeholder listo: saco de red con conchas |
| `products/coin_pack_large.png` | `coin_pack_large` | 512×512 | Placeholder listo: cubo de madera con conchas |
| `products/pearl_pack.png` | `pearl_pack` | 512×512 | Placeholder listo: concha abierta con 3 perlas |
| `products/slot_pack.png` | `slot_pack` (Más espacio +10) | 512×512 | Placeholder listo: cesta de pesca con insignia "+" |

### NO usar en la v1 (no se generaron; `FeatureFlags.paidLuckEnabled = false`)
| Clave | Nombre | Motivo |
|---|---|---|
| `passes.luck_plus` | Pase Suerte+ | Altera probabilidades = objeto aleatorio de pago; apagado en v1 (decisión D9). Sin ícono hasta la v1.5 |
| `products.lucky_bait_15` | Cebo de Suerte (15 min) | Igual. Un pase promocionado **no puede** dar objetos aleatorios de pago |

Tampoco hay ícono de **cañas cosméticas** ni de **servidor privado**: no existen en `ProductIds.luau` ni en `Catalog.luau` de la v1 (el README del juego dice "no hay cañas cosméticas de pago"; el servidor privado se configura en Creator Hub). Si se añaden, usar el prompt de `../prompts-ia.md` §3.6.

## 2. Especificaciones oficiales verificadas (2026-10-20)

Fuente: espejo oficial `Roblox/creator-docs` en GitHub (rama `main`), descargado y leído completo (también con WebFetch). `create.roblox.com` está bloqueado desde esta red, así que **no** se comparó con la web publicada.

| Documento | Regla verificada (cita resumida) | Cómo se cumple / valida |
|---|---|---|
| [experience-icons.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/production/publishing/experience-icons.md) ([web](https://create.roblox.com/docs/production/publishing/experience-icons)) | Plantilla de **512×512 px**; "should be **square** and at least 512×512"; a veces se reduce a **~150×150** (previsualizar a tamaños pequeños); evitar gráficos ambiguos (ejemplo oficial: símbolo extraño en la esquina superior derecha); no dejar el ícono automático; **un ícono por idioma**; debe pasar moderación. El doc **no** lista formatos, peso máximo ni reglas de texto | 3 íconos de 512×512 exactos; vista previa a 150/110/64 px en la hoja; sin texto; esquinas con fondo continuo |
| [thumbnails.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/production/publishing/thumbnails.md) ([web](https://create.roblox.com/docs/production/publishing/thumbnails)) | **16:9**, idealmente **1920×1080**; si no, se estira; formatos `.jpg .gif .png .tga .bmp`; hasta **10** miniaturas por página; personalización de Home: **2 a 5** activas, **< 3 MB** y 1920×1080; "evita poner texto o elementos esenciales en la **parte inferior**" (el recuento de jugadores puede taparlo); imagen única y relevante a lo que se jugará; moderación de todo | 1920×1080 PNG, todas < 700 KB; el texto termina por encima del 85 % de la altura (comprobado por script); línea roja del 15 % inferior en la hoja |
| [passes.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/production/monetization/passes.md) ([web](https://create.roblox.com/docs/production/monetization/passes)) | Ícono "no excede **512×512** px, no incluye detalles importantes fuera de sus **límites circulares** y es `.jpg`, `.png` o `.bmp`"; recomienda ícono propio por pase (si no, Roblox pone uno por defecto); un pase promocionado debe tener miniatura, no puede dar objetos aleatorios de pago, cumplir las Normas, y costar entre 50 y 800 Robux | 512×512 PNG; sujeto dentro del círculo de 460 px (radio 230), medido por script; ningún arte de azar |
| [developer-products.md](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/production/monetization/developer-products.md) ([web](https://create.roblox.com/docs/production/monetization/developer-products)) | Mismo texto de ícono: ≤ 512×512, sin detalles importantes fuera del círculo, `.jpg/.png/.bmp`; recomienda ícono propio por producto; no detalla reglas de contenido de imagen (solo remite a la política de objetos aleatorios) | Igual que los pases |

**No verificado / límites de esta verificación:** (1) que la web publicada coincida con el espejo de GitHub; (2) formatos y peso máximo del ícono del juego (el doc no los dice; se usó PNG < 200 KB por prudencia); (3) el radio exacto del recorte circular (el doc solo dice "límites circulares"; se usó un círculo de 460 px = 90 %, el criterio de `pagina-del-juego.md` §5); (4) el resultado de la moderación (nada se ha subido); (5) las reglas de texto en miniaturas de anuncios (no publicadas, ver `ads-manager.md`).

## 3. Reglas de contenido aplicadas
- **Sin monedas, billetes ni estética de casino.** La moneda del juego ("monedas") se representa con **conchas doradas** (vieiras), no con monedas. Ojo: el ícono de moneda dentro del juego debería coincidir (decisión de Aryan: usar también conchas en la UI, o cambiar estos 4 íconos).
- Sin cofres de botín, ruedas, dados, cartas ni máquinas. El "Pack de inicio" es una **caja de aparejos** con asa, bandejas, boya, señuelo y frasco (no un cofre).
- Sin "Robux gratis", sin precios ni promesas de dinero/premio; el único número de una miniatura es el "3" de "3 ZONAS" (una cifra real de `Balance.luau`; ver la tabla de `pagina-del-juego.md` §4, que la incluye aunque su regla general diga "sin números": si prefieres cero números, cambia el texto a "EXPLORA ZONAS" en `source/lib/assets.mjs`).
- ¿UN MÍTICO? es una pregunta, no una promesa (un Mítico ≈ 0,04 % por lanzada).
- Sin IP ni marcas de terceros, sin personas reales: los pescadores son figuras cartoon **sin cara**; la ballena, los peces y Fortu son diseños propios.
- Texto mínimo: íconos del juego sin texto; pases/productos solo "x2", "VIP" y una insignia "1"; miniaturas ≤ 3 palabras + logotipo. Texto en Fredoka 700, relleno Oro Sol/Espuma con **contorno Azul Abismo** (contraste relleno/contorno 10,5:1 y 15,5:1; la herramienta también mide el fondo y avisa si el texto depende del contorno).
- Rareza no solo por color: el libro del bestiario usa **1 a 6 estrellas** además del color del marco.
- Fortu en miniaturas **solo si aparece en el juego** (pantalla de carga, bestiario o NPC) — **[AJUSTAR A LO REAL]**; el juego aún no tiene cliente/arte.

## 4. Verificación hecha (2026-10-20)
`node render-assets.mjs` ejecuta y registra en `assets-manifest.json`:
- **Dimensiones y formato** (ImageMagick `identify`): 3 íconos 512×512, 8 miniaturas 1920×1080, 5 pases y 6 productos 512×512, todos PNG sRGB sin alfa; miniaturas 500–640 KB (< 3 MB), íconos/pases/productos 94–203 KB.
- **Círculo seguro**: cada ícono/pase/producto se renderiza dos veces (completo y solo el sujeto sobre transparente); se cuentan los píxeles del sujeto fuera del círculo de radio 230 → **0** en las 14 piezas (el agua, el resplandor y el fondo se marcan `deco`/`bg`: no cuentan, son continuos hasta las esquinas).
- **Contraste del texto** (fórmula WCAG): relleno vs contorno ≥ 10,5:1 en todos; la herramienta avisa (sin fallar) de 6 textos cuyo fondo medido da < 4,5:1 y dependen del contorno (miniaturas 1 y 3, "x2" y "VIP").
- **Zona inferior**: ningún texto cruza el 85 % de la altura en las miniaturas.
- **Revisión visual** de la hoja de contactos y de iconos, una miniatura de cada tipo, un pase y un producto a tamaño real; corregido: cofre → caja de aparejos, texto tapado por un degradado, mascota fuera del círculo, peces cortados por el borde, solapes de texto con el libro.
- Peso total de los PNG ≈ 8,0 MB (< 10 MB), más 0,45 MB de SVG.

## 5. Cómo regenerar
```bash
cd ROBLOX/marketing/fish-and-fortune/assets/source
npm install                     # solo playwright-core (node_modules ignorado por git)
node render-assets.mjs          # todo: SVG -> PNG optimizados + hoja de contactos + validación (~1 min)
node render-assets.mjs --only=vip,icon-b-fortu --no-sheet   # solo algunas piezas
node render-assets.mjs --validate-only                       # solo dimensiones/formato/peso de los PNG actuales
```
Requisitos: Node ≥ 20, un Chromium (usa `CHROMIUM_PATH`, `/opt/pw-browsers` o el de Playwright; no instala nada) e ImageMagick (`magick` o `convert`). Detalles, estructura del código y cómo añadir piezas: `source/README.md`.

## 6. Cómo reemplazar por arte de IA
1. Genera la pieza con los prompts de `../prompts-ia.md` (§3.1 hoja de Fortu primero para fijar el personaje; §3.6 pases/productos; §5 de `../pagina-del-juego.md` ideas 1–5 para íconos y miniaturas). Genera al doble (1024×1024 / 3840×2160) y reduce.
2. Exporta con **el mismo nombre de archivo** y en la carpeta que corresponde (los nombres ya están en las tablas de arriba y en `assets-manifest.json`).
3. Para pases/productos: sujeto dentro del círculo de 460 px, fondo continuo hasta las 4 esquinas, **sin cofres/ruedas/monedas**; para miniaturas: nada esencial en el 15 % inferior; texto añadido después con Fredoka 700 (no dejes que la IA escriba el texto).
4. Comprueba: `node render-assets.mjs --validate-only` (dimensiones, formato, peso). El círculo seguro y el contraste solo se miden en el render por código: revisa a ojo con la plantilla circular o mira `contact-sheet.png` de una versión regenerada con tus PNG (ajusta `source/lib/assets.mjs` si quieres incluirlos en la hoja).
5. Revisa cada resultado contra IP ajena (checklist de `../prompts-ia.md` §7), guarda el prompt exacto en el registro de prompts y, si el arte de IA incluye capturas reales (bestiario, banner Mítico), usa capturas auténticas: la miniatura debe reflejar el juego real.
6. Sube con 3 días de margen (moderación de assets hasta 48 h).

## 7. Dónde se sube cada cosa en Roblox (según los docs oficiales)
- **Ícono**: Creator Dashboard → juego → Configurations → Places → lugar inicial → Icon → Image → Change → Save Changes.
- **Miniaturas**: Configurations → Places → lugar → Thumbnails (pestañas Home Page y Experience Detail Page; activar 2–5 para personalización).
- **Pases**: Monetization → Passes → Create pass (subir el ícono en el paso 4). **Productos**: Monetization → Developer Products → Create developer product.
- Recuerda: los IDs de `ProductIds.luau` siguen en 0 hasta crear cada pase/producto; los de pases son el `TargetId` (ver la nota de ese archivo).

## 8. Contenido de esta carpeta
```
assets/
  README.md              este archivo
  contact-sheet.png      hoja de contactos (revisión de un vistazo)
  assets-manifest.json   informe de validación por archivo (tamaño, peso, círculo seguro, contraste)
  icon/ thumbnails/ passes/ products/    PNG finales
  source/                código: lib/*.mjs (arte), render-assets.mjs, svg/ (SVG editables), README.md
```
