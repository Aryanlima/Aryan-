# Producción de ropa y accesorios de avatar con IA: especificaciones, flujo, automatización y plan de 30 días (a 2026-10-20)

**Alcance de este informe.** Solo el *proceso de producción* y la *automatización*. La economía (comisiones, costes, rentabilidad, comparación con juegos) está en [`08-ropa-vs-juegos.md`](08-ropa-vs-juegos.md); aquí solo repito lo imprescindible. Las herramientas de IA para 3D, audio y marketing están en [`05-ia-assets-y-marketing.md`](05-ia-assets-y-marketing.md); aquí solo lo que cambia para ropa.

**Etiquetas** (cada dato lleva una): **[OFICIAL]** leído por mí en la documentación de Roblox el 2026-10-20 (repositorio `Roblox/creator-docs`, commit `7400643` del 2026-10-20 04:47 UTC; `create.roblox.com` está bloqueado, así que leí el espejo oficial de GitHub) · **[MEDIDO]** medido por mí sobre archivos oficiales (subtipo de oficial) · **[TERCERO]** blog, prensa o reseña · **[NO VERIFICADO]** no pude comprobarlo · **[IDEA PROPIA]** decisión o hipótesis mía · **[DERIVADO]** cálculo mío a partir de datos oficiales.

Enlaces base de la documentación oficial (todos `https://github.com/Roblox/creator-docs/blob/main/content/en-us/`): [`avatar/classic-clothing.md`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/classic-clothing.md) · [`avatar/layered-accessories/specifications.md`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/layered-accessories/specifications.md) · [`avatar/rigid-accessories/specifications.md`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/rigid-accessories/specifications.md) · [`marketplace/publish-to-marketplace.md`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/publish-to-marketplace.md) · [`marketplace/marketplace-policy.md`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-policy.md) · [`marketplace/marketplace-fees-and-commissions.md`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-fees-and-commissions.md) · [`cloud/guides/usage-assets.md`](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/usage-assets.md).

---

## 0. Resumen ejecutivo

1. **La plantilla oficial existe y la usé.** La plantilla de camisa y pantalón clásicos (`Classic-Clothing-Templates.zip`, 585 × 559 px, RGBA con alfa de 8 bits) está en el repo oficial (Git LFS; se baja de `media.githubusercontent.com`). Medí sus 18 regiones sobre los píxeles y construí el generador `ROBLOX/tools/clothing-gen/` con esas coordenadas verificadas [OFICIAL, MEDIDO]. Detalle en §10.
2. **No hay API oficial para subir ropa de avatar.** La Assets API de Open Cloud solo documenta Animation, Audio, Decal/Image, Mesh, Model y Video; `AssetService:CreateAssetAsync` solo admite Model, Plugin, Mesh e Image. Camisa, pantalón, camiseta clásica y accesorios de avatar **se suben a mano** (Creator Dashboard para clásica; Studio → *Save to Roblox* para 3D) [OFICIAL]. Cualquier método no oficial con la cookie de la cuenta es una violación probable de las normas y un riesgo para la cuenta: no lo hagas ni lo automatices (§8).
3. **Para vender hace falta, a la vez:** identificación con documento (o cuenta parental vinculada con ID), verificación en dos pasos, tarifa de subida de 80 R$ por envío, anticipo de publicación (10 R$ en clásica; 600 R$ en 3D de capas) y **Roblox Plus o Premium 1000/2200 activo** para publicar y para mantener a la venta [OFICIAL]. Esto no se puede automatizar ni delegar en IA (§9).
4. **La imagen de un ítem clásico no se puede reemplazar después de subirla** (la página de gestión solo deja cambiar nombre, descripción, venta y precio) [OFICIAL; la imposibilidad es DERIVADA de que la doc no ofrece esa opción]. Un diseño defectuoso cuesta otra subida de 80 R$. Por eso el control de calidad *antes* de subir es la pieza más rentable del pipeline.
5. **La política del Marketplace no tiene ninguna cláusula específica sobre contenido generado por IA** (leí la página completa; las únicas menciones de IA en `marketplace/`, `avatar/` y `production/publishing/` son un modelo de aprendizaje automático dentro del sistema de validación) [OFICIAL]. Pero **tú respondes por lo que subes**: "tienes que asegurarte de que tienes derecho a subir el activo", sea tuyo o no [OFICIAL]. Si Roblox tiene reglas de IA para ítems en los Términos de Uso o en las Normas de la Comunidad, **no pude leerlas** (`help.roblox.com` no resuelve desde esta red) [NO VERIFICADO].
6. **El mayor riesgo de una IA no es técnico, es de derechos.** Los modelos pueden reproducir logos, personajes y estilos reconocibles; Roblox retira el ítem por DMCA y el creador pierde las tarifas por unidad y los Robux ganados de ese ítem, con cierre de cuenta si es reincidente [OFICIAL]. Mitigación: patrones procedurales propios (cero riesgo de terceros), prompts sin nombres propios, lista de bloqueo y revisión humana (§5).
7. **Hay reglas de contenido que afectan al calendario:** la política prohíbe ítems "políticos, religiosos, sangrientos, violentos, de autolesión, de drogas, **sexuales, de boda o de citas**, o que probablemente se usen para esos juegos de rol" y "texto excesivo" [OFICIAL]. Eso hace arriesgados San Valentín (citas), Semana Santa/Pascua (religioso) y el Halloween sangriento (§3, §7).
8. **Hoy es 20-oct: Halloween (sábado 31-oct) queda a 11 días.** La moderación tarda hasta 24 h [OFICIAL]; un lote de Halloween solo llega si se sube antes del 27-oct. Trátalo como prueba del pipeline, no como fuente de ingresos. Las fechas que sí dan margen son Black Friday (27-nov) y Navidad (25-dic) (§7).
9. **Qué IA usar:** para estampados, lo más seguro y barato es el generador procedural incluido (sin licencias de terceros). Para ilustraciones, usa solo planes de pago con derechos comerciales explícitos y revisa los términos el día de contratar; en pesos abiertos, FLUX.1 [schnell] es Apache-2.0 y FLUX.1 [dev] es de licencia no comercial para el modelo [TERCERO: repositorio oficial de Black Forest Labs] (§6).
10. **Plan sugerido:** 30 días con puertas de decisión; coste de la tanda mínima ≈ 3.120 R$ (≈ US$ 11,9 al valor DevEx 0,0038) y de la tanda media ≈ 6.240 R$ (≈ US$ 23,7) [DERIVADO] (§11).

---

## 1. Especificaciones vigentes (2026-10-20)

### 1.1 Mapa de tipos y qué se puede producir con IA

| Tipo | Qué es | Herramienta de creación | Apto para producción en lote con IA | Fuente |
|---|---|---|---|---|
| T-shirt clásica (2D) | Imagen cuadrada que se muestra en el pecho de un avatar de bloques | Editor de imágenes + web | **Sí, totalmente** (generador incluido) | [classic-clothing](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/classic-clothing.md) [OFICIAL] |
| Camisa / pantalón clásicos (2D) | Imagen 585×559 que envuelve torso y extremidades | Plantilla oficial + editor | **Sí, totalmente** | ídem [OFICIAL] |
| Ropa en capas (3D) | Malla con jaula interior/exterior y esqueleto R15 | Blender o Maya + Studio (Importer + Accessory Fitting Tool) | **Parcial:** texturas y papeleo sí; modelado y jaulas, a mano o con script en Blender | [layered-accessories](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/layered-accessories/index.md) [OFICIAL] |
| Accesorio rígido (UGC) | Malla fija en un punto de anclaje (sombrero, pelo, espalda…) | Blender + Studio | **Parcial** (modelado asistido por IA 3D, con limpieza humana) | [rigid](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/rigid-accessories/index.md) [OFICIAL] |
| Zapatos | Dos accesorios (izquierdo/derecho) agrupados en un Model | Blender + Studio | Parcial | [publish](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/publish-to-marketplace.md) [OFICIAL] |
| Cuerpos, cabezas, emotes, maquillaje | Más complejos (FACS, jaulas de cuerpo, capas de modestia) | Avanzado | No recomendado como primera línea | [marketplace-policy](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-policy.md) [OFICIAL] |

**Bundles.** La documentación solo describe *bundles* de cuerpo, cabeza dinámica y zapatos (y su anticipo en la tabla de tarifas). **No hay un bundle de "conjunto camisa + pantalón" documentado** para creadores [OFICIAL; ausencia = NO VERIFICADO fuera de la doc]. Además "otros tipos de ítem, como los bundles, no se pueden actualizar después de subirlos" [OFICIAL]. Lo que sí existe para organizar: carpetas en *Creations → Avatar Items* (agrupan por colección o por lanzamiento; un ítem puede estar en varias) [OFICIAL].

### 1.2 Ropa clásica 2D: plantilla, regiones y reglas

| Requisito | Valor | Etiqueta / fuente |
|---|---|---|
| T-shirt | Imagen **cuadrada**, "como 512×512 px" | [OFICIAL] classic-clothing |
| Camisa y pantalón | **Descargar y modificar la plantilla oficial** (tamaño de lienzo 585×559, RGBA; el propio PNG dice "This template supports 8-bit alpha channels") | [OFICIAL, MEDIDO] [Classic-Clothing-Templates.zip](https://github.com/Roblox/creator-docs/blob/main/content/en-us/assets/accessories/classic-clothing/Classic-Clothing-Templates.zip) |
| Formato de exportación | `.png` o `.jpg` | [OFICIAL] |
| Tamaños de región (oficial) | FRONT/BACK 128×128; lados del torso 64×128; lados de brazos y piernas (L, B, R, F) 64×128; UP/DOWN del torso 128×64; U/D de brazos y piernas 64×64 | [OFICIAL] |
| Prueba previa gratuita | En Studio: *Avatar → Character → Block Avatar*; insertar `ShirtGraphic`, `Shirt` o `Pants` en el *Rig* y asignar `Graphic`, `ShirtTemplate` o `PantsTemplate`. "La prueba no requiere tarifas" | [OFICIAL] |
| Consejo oficial | Zapatos/guantes cerca del borde inferior de las regiones L/B/R/F; si suben demasiado parecen parte del pantalón (ejemplos *Good/Bad* en la doc) | [OFICIAL] |
| Líneas punteadas de la plantilla | "Límites máximos de altura de guantes y de detalles de la parte baja de la pierna, solo R15". Medidas: fila **y = 170** en el torso, **y = 407** en brazos/piernas | [OFICIAL] texto; coordenadas [MEDIDO] |
| Peso máximo / resolución mínima del archivo | No figura en la doc | [NO VERIFICADO] |
| Reemplazar la imagen tras subir | No está documentado (solo nombre, descripción, venta y precio) | [OFICIAL] por ausencia |

**Regiones medidas** sobre los píxeles de `Template-Shirts-R15.png` y `Template-Pants-R15.png` (idénticas en ambas; coordenadas `x, y, ancho × alto`) [MEDIDO 2026-10-20; reproducible con `ROBLOX/tools/clothing-gen/verify_layout.py`]:

| Parte | UP | Lados (orden alrededor del cilindro) | DOWN |
|---|---|---|---|
| Torso | 231, 8 · 128×64 | R 165,74 (64×128) · **FRONT 231,74 (128×128)** · L 361,74 (64×128) · **BACK 427,74 (128×128)** | 231, 204 · 128×64 |
| Brazo / pierna **derecha** | 217, 289 · 64×64 | L 19,355 · B 85,355 · R 151,355 · F 217,355 (todas 64×128) | 217, 485 · 64×64 |
| Brazo / pierna **izquierda** | 308, 289 · 64×64 | F 308,355 · L 374,355 · B 440,355 · R 506,355 (todas 64×128) | 308, 485 · 64×64 |

Hay 2 px de separación sin usar entre caras vecinas. Las caras de cada fila son contiguas en 3D: el torso da una vuelta de 384 px (64+128+64+128) y cada extremidad de 256 px (4×64). Eso permite que un estampado "dé la vuelta" sin costura, que es lo que implementa el generador (§10).

### 1.3 Ropa en capas 3D

| Requisito | Valor | Fuente |
|---|---|---|
| Malla | **Una sola malla**; ≤ **4.000 triángulos**; estanca (watertight, sin agujeros ni caras traseras); preferir quads (evitar caras de 5+ lados) | [specifications](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/layered-accessories/specifications.md) [OFICIAL] |
| Tamaño máximo (studs, centrado en el punto de anclaje) | Camiseta, camisa, jersey, chaqueta, pantalón, shorts, vestido/falda: **8 × 8 × 8** | ídem [OFICIAL] |
| Textura (Marketplace) | **≤ 2048 × 2048**; formatos de textura `.png .jpg .tga .bmp`; las de más resolución se bajan automáticamente | ídem + [texture-specifications](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/texture-specifications.md) [OFICIAL] |
| Rig | Pesado y enlazado al **armazón R15**; **≤ 4 influencias** de hueso por vértice (o *skinning* automático en tiempo de ejecución) | specifications + [automatic-skinning-transfer](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/automatic-skinning-transfer.md) [OFICIAL] |
| Jaulas | **Jaula interior** (`<nombre>_InnerCage`) y **exterior** (`<nombre>_OuterCage`); no borrar vértices ni alterar UVs de las jaulas; la exterior es idéntica a la interior por defecto y es la única que se ajusta sobre tu malla | ídem [OFICIAL] |
| Puntos de anclaje | Camisa/camiseta/jersey/chaqueta: `BodyFrontAttachment`; pantalón/shorts/falda: `WaistCenterAttachment` (el Accessory Fitting Tool los genera solo) | ídem [OFICIAL] |
| Requisitos de Marketplace | `Material = Plastic`; `Transparency = 0`; `VertexColor = 1,1,1`; el `Accessory` no puede contener scripts ni `Part` extra | ídem [OFICIAL] |
| Sistema de validación (UGC) | Se ejecuta al subir: esquema, geometría, texturas/UV, *skinning*, jaulas, anclajes, seguridad | [validation-system](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/validation-system.md) [OFICIAL] |
| Límite general de malla | 20.000 triángulos por malla en general; los ítems de avatar tienen presupuestos propios (4.000 aquí) | [modeling/specifications](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/specifications.md) [OFICIAL] |
| Emisivo | Máscara emisiva: subida 500 R$ y anticipo ×5 | [fees](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-fees-and-commissions.md) [OFICIAL] |

**Archivos de partida oficiales** ([project-files](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/layered-accessories/project-files.md)) [OFICIAL]: `Tshirt-model.fbx` (camiseta sin jaula), `Additional-FBX-assets.zip` (accesorios con jaula), maniquíes Classic / Rthro / Rthro Slender (con y sin jaulas), y para Blender `Rig_and_Attachments_Template.blend`, `Clothing_Cage_Template.blend` y `Combined-Template.blend`.

**Accessory Fitting Tool (AFT)** [OFICIAL, [doc](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/accessory-fitting-tool.md)]: herramienta de Studio (*Avatar → Accessory*) que convierte el `Model`/`MeshPart` importado en un `Accessory`, fija el `AccessoryType`, genera los anclajes, deja probar sobre varios cuerpos, animaciones y otras prendas, y permite retoques menores de ajuste. **Importer** de Studio: importa `.fbx` o `.gltf` como `Model` con la textura en `SurfaceAppearance` o `TextureID`; si las texturas no cargan, se importan a mano con el Asset Manager [OFICIAL, [import](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/layered-accessories/import.md)].

### 1.4 Accesorios rígidos (UGC) y zapatos

| Requisito | Valor | Fuente |
|---|---|---|
| Malla | Una sola; ≤ 4.000 triángulos; estanca; sin *skinning* | [rigid specs](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/rigid-accessories/specifications.md) [OFICIAL] |
| Tamaño máximo (cuerpo "Normal", studs) | Sombrero 1,87 × 2,5 × 1,87 · Cara 1,87 × 1,25 × 1,25 · Cuello 2,95 × 3,68 × 2,16 · Frente 2,95 × 3,68 × 3,24 · Espalda 9,86 × 8,59 × 4,87 (la doc da más filas y las escalas Slender/Classic) | ídem [OFICIAL] |
| Textura (Marketplace) | ≤ 2048 × 2048 | ídem [OFICIAL] |
| Zapatos | Nombrar `LeftShoeAccessory` y `RightShoeAccessory`, seleccionar ambos y *Group as a Model* antes de *Save to Roblox* | [publish](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/publish-to-marketplace.md) [OFICIAL] |
| Categorías | No clasificar mal (sombrero en Hat, pelo completo en Hair, etc.); algunas se detectan solas tras subir (bodysuit, máscara completa) | [categories](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/categories.md) [OFICIAL] |

### 1.5 Miniaturas (thumbnails)

- **3D:** puedes personalizarlas con el *UGC Custom Thumbnail Tool* (plugin) antes de subir; "una vez subido el activo, no puedes modificar la miniatura" [OFICIAL, [custom-thumbnails](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/custom-thumbnails.md)]. La doc de *Update an existing item* sí menciona la miniatura entre las cosas que una actualización puede corregir [OFICIAL, [publish](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/publish-to-marketplace.md)]: **las dos páginas se contradicen**; comprobar en el Creator Dashboard.
- **Clásica:** la doc no describe miniatura personalizada; el catálogo genera la vista del ítem [NO VERIFICADO el procedimiento exacto]. Para marketing fuera de Roblox usa `previews/<id>-mock.png` del generador (aproximación 2D) o capturas reales de Studio.

---

## 2. Flujo de subida y aprobación, paso a paso

### 2.1 Ropa clásica (Creator Dashboard) [OFICIAL, [classic-clothing](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/classic-clothing.md)]

| # | Paso | Quién |
|---|---|---|
| 0 | Cumplir los [requisitos de creador](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-policy.md#creator-requirements): ID verificada (o cuenta parental vinculada con ID), 2FA, Plus/Premium 1000/2200 | **Tú** |
| 1 | Generar el PNG y pasar el QC automático | **Claude Code** |
| 2 | Probar en Studio con *Block Avatar* (gratis) | **Tú** (Studio en tu PC) |
| 3 | *Creator Dashboard → Avatar Items → pestaña Classics*; arrastrar el archivo o *Upload Asset* | **Tú** |
| 4 | Elegir *Asset Type* (T-Shirt / Shirt / Pants), poner *Name* y *Description* | **Tú** (texto preparado en `manifest.csv`) |
| 5 | *Upload*: **80 R$** por envío (no reembolsables si se rechaza) | **Tú** |
| 6 | Moderación: **hasta 24 h** [OFICIAL, [moderation](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/moderation.md)]; al aprobarse queda "Ready To Sell" | Roblox |
| 7 | *Configure*: *On Sale* + *Set a price*; al **publicar por primera vez** se paga el anticipo (10 R$ en clásica) | **Tú** |
| 8 | Seguimiento: *Transactions* (comisiones y *Publishing Advance Rebates*) | **Tú** / Claude Code lee el CSV exportado |

### 2.2 Ropa en capas y accesorios 3D (Studio) [OFICIAL, [publish-to-marketplace](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/publish-to-marketplace.md)]

1. Modelar/texturizar en Blender o Maya y exportar `.fbx`/`.gltf` (ver §7.6).
2. Importar con el **Importer**; convertir con el **AFT** (*Clothing* o *Accessory*) y probar en varios cuerpos.
3. (Opcional) Miniatura personalizada con el *UGC Custom Thumbnail Tool* **antes** de subir.
4. En el *Explorer*: clic derecho sobre el `Accessory` → **Save to Roblox** → *Submit As* = **Avatar Asset** → elegir tipo de activo (la validación corre al elegirlo; si no aparece el desplegable, la cuenta no cumple los requisitos) → título y creador (usuario o grupo) → **Submit** (80 R$; 500 R$ con máscara emisiva).
5. Moderación (hasta 24 h). Después, en *Manage Item*: descripción, disponibilidad (No limitado o Limited), precio (*Amount Above Price Floor* y opcional *Do Not Price Below*), ubicación de venta, **Publish Item** (anticipo, p. ej. 600 R$ en ropa en capas).
6. *Schedule Sale*: fecha de inicio y fin opcional, **hasta 30 días de antelación** [OFICIAL].
7. **Actualizar** un accesorio rígido o en capas ya subido: mismo tipo de activo, mismo ID, historial y propietarios; cuesta la tarifa de subida de nuevo y pasa moderación; solo para correcciones (ajuste, jaulas, defectos pequeños), no rediseños [OFICIAL].
8. **Archivar**: solo ítems subidos hace ≥ 180 días; no vale para Limiteds; los dueños conservan el ítem [OFICIAL, [moderation](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/moderation.md)].

### 2.3 Qué pasa si falla

| Situación | Consecuencia | Fuente |
|---|---|---|
| Rechazo en moderación | Pierdes los 80 R$ de subida; el anticipo aún no se había pagado | [fees](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-fees-and-commissions.md) [OFICIAL] |
| Retirada posterior de un ítem con ventas | Se reembolsa a los compradores y se cancelan los pagos pendientes | [moderation](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/moderation.md) [OFICIAL] |
| Moderación errónea | Apelar en la [página de apelaciones](https://en.help.roblox.com/hc/en-us/articles/360000245263-Appeal-Your-Content-or-Account-Moderation) | [OFICIAL] (enlace no abierto desde aquí) |
| Conflictos de subida habituales | Texto del nombre/descripción filtrado; `AssetID`/`TextureID` de otro activo o aún en moderación | [publish](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/publish-to-marketplace.md) [OFICIAL] |
| Cumplir los requisitos de creador deja de ser cierto (p. ej. caduca Plus/Premium) | No puedes mantener los ítems a la venta | [policy](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-policy.md#creator-requirements) [OFICIAL] |

**Tarifas, en una línea (detalle y reparto en [08 §2](08-ropa-vs-juegos.md))** [OFICIAL]: subida 80 R$; anticipo clásica 10 R$; anticipo 3D de capas (camisa, pantalón, camiseta, jersey, chaqueta, falda, shorts, zapatos) 600 R$; accesorios rígidos 1.000-1.500 R$; el anticipo "puede cambiar 2-3 veces por trimestre como máximo" y **hay que confirmar el valor vigente en el Dashboard antes de planificar**.

---

## 3. Reglas de contenido y moderación (y cómo cumplirlas en el pipeline)

Origen: [marketplace-policy](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-policy.md#general-creation-guidelines), sección "General creation guidelines" y "Accessory and clothing guidelines" [OFICIAL].

| Regla oficial | Qué significa en producción | Control automático en `clothing-gen` |
|---|---|---|
| Seguir las Normas de la Comunidad. No crear ítems políticos, religiosos, sangrientos, violentos, de autolesión, de drogas, **sexuales/de boda/de citas**, ni "probablemente usados" para esos juegos de rol | Excluir temas, símbolos y palabras de esas categorías; evitar "couple", "wedding", "date", crucifijos, sangre, jeringuillas, etc. | Parcial: `ip_blocklist.txt` (solo marcas); **añade tus propias palabras vetadas** |
| No usar activos creados por Roblox ni su branding o iconografía | Nada de logo, "R" de Roblox, ícono de Robux ni capturas de ítems de Roblox | Las plantillas oficiales llevan logo: el generador usa fondo transparente y nunca copia sus píxeles; `roblox` y `robux` están en la lista de bloqueo |
| No crear ítems demasiado parecidos a otros existentes (ni copiar de otro creador ni de Roblox); no republicar el mismo ítem como Limited | No generar variaciones mínimas de tu propio ítem; no usar capturas del catálogo como entrada de la IA | QC de **casi-duplicados** entre ítems del lote (dHash 16×16) |
| Solo vender lo que tengas permiso de vender; si no eres el dueño de la IP, necesitas permiso del titular | Sin marcas, personajes, equipos, celebridades, memes con dueño (§5) | Lista de bloqueo de términos |
| Cuidado con ítems en la zona de la boca o la cintura; probar en varios tipos de personaje | Solo 3D | — |
| No molestar la partida: no tapar el avatar, la interfaz ni a otros jugadores, ni hacerlo desaparecer | Solo 3D (tamaño y transparencia) | — |
| No depender de fallos de la plataforma | — | — |
| **No incluir texto excesivo** | Máximo una frase corta por cara; sin eslóganes largos | Aviso si el texto supera 48 caracteres en total |
| No clasificar mal (camisa en la categoría de pantalón, etc.) | Elegir bien el *Asset Type* | — |
| Los modesty layers no pueden ser translúcidos ni insinuantes (lencería) (para cuerpos) | Para ropa: evitar texturas **color piel** que parezcan desnudez | Aviso si > 35 % de los píxeles opacos son "color piel" (heurística burda, revisar a mano) |

**Moderación en la práctica** [TERCERO, no verificado por mí]: hay quejas en el DevForum sobre borrados automáticos de ítems antiguos tras cambios de criterio ([hilo](https://devforum.roblox.com/t/seemingly-random-ugc-item-deletions-are-happening/3032202), sin fecha comprobada). La doc oficial confirma que "las moderaciones pueden ocurrir después de pasar la inicial" [OFICIAL].

---

## 4. Contenido generado por IA: qué dice y qué no dice Roblox

| Tema | Hallazgo | Etiqueta / fuente |
|---|---|---|
| ¿Prohíbe o exige declarar IA en ítems de avatar? | **La política del Marketplace no menciona IA**. Búsqueda en `marketplace/`, `avatar/`, `production/publishing/`, `art/accessories/`: la única mención es un modelo de aprendizaje automático del validador (detecta fragmentos de malla flotantes) | [OFICIAL] [validation-system](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/validation-system.md) |
| Responsabilidad | "Seas o no el creador original, debes asegurarte de que tienes derecho a subir el activo" | [OFICIAL] [policy](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-policy.md) |
| Reglas de IA para *juegos* (no ítems) | Con herramientas de terceros "eres responsable del contenido entregado, aunque sea generado por IA"; con APIs de Roblox (`GenerationService`, `TextGenerator`) las entradas y salidas se moderan | [OFICIAL] [generative-AI](https://github.com/Roblox/creator-docs/blob/main/content/en-us/generative-AI.md) (aplicar el mismo criterio por analogía [IDEA PROPIA]) |
| Términos de Uso / Normas de la Comunidad sobre IA | No pude abrirlos (`en.help.roblox.com` no resuelve) | [NO VERIFICADO] |
| Herramientas de IA propias de Roblox | Texture Generator (modo rápido: textura difusa 1K; modo calidad: PBR 4K, para mallas en Studio), Material Generator (texturas repetibles), `GenerateModelAsync` (en juego). **La doc no dice nada de tarifas ni de la titularidad de lo generado** | [OFICIAL] [texture-generator](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/texture-generator.md), [model-generation](https://github.com/Roblox/creator-docs/blob/main/content/en-us/parts/model-generation.md); costes y titularidad [NO VERIFICADO] |
| Derechos de autor sobre lo generado | Según los resúmenes de terceros, una imagen generada solo por IA puede no ser protegible por copyright en EE. UU., y Midjourney no indemniza al usuario (Adobe sí ofrece cobertura a clientes elegibles en su modelo propio) | [TERCERO] [guía de Midjourney 2026](https://terms.law/2026/01/15/midjourney-commercial-use-rights-complete-2026-guide/) (blog legal, no abierto directamente) |

**Consecuencia práctica [IDEA PROPIA]:** (a) asume que un diseño 100 % IA es difícil de defender si te lo copian: añade un elemento propio y reconocible (la doc sugiere incorporar tu marca propia) y edición humana; (b) conserva un expediente por ítem (herramienta, plan, fecha, prompt, versión del modelo y captura de los términos del día) para demostrar tus derechos si hay una reclamación; (c) como la regla de IA puede cambiar, relee las políticas antes de cada lanzamiento.

---

## 5. Propiedad intelectual, marcas y derechos: riesgos y cómo evitarlos

Marco oficial [OFICIAL, [intellectual-property](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/intellectual-property.md), [ip-guidelines](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/ip-guidelines.md); la doc advierte que no es asesoría legal]: puedes infringir derechos aunque no monetices, des crédito al autor, lo hayas descargado de internet o creas que es *fair use*; publicar un diseño ajeno en Roblox no te da su propiedad; los diseños genéricos (una gorra de béisbol) no son protegibles por nadie; Roblox cumple la DMCA, retira el contenido y cierra cuentas de reincidentes; el creador infractor pierde las tarifas por unidad y los Robux ganados con ese ítem; archivar un ítem no sustituye la vigilancia, aunque se tendrá en cuenta al aplicar sanciones.

| # | Riesgo | Ejemplo típico | Cómo evitarlo en el pipeline | Etiqueta |
|---|---|---|---|---|
| 1 | Branding de Roblox | Logo, ícono de Robux, plantilla con logo exportada por error | Fondo transparente; el QC rechaza `roblox`/`robux` en textos; revisar a ojo las vistas previas | [OFICIAL] policy |
| 2 | Marcas de moda/deporte | Swoosh, tres rayas, escudos de equipos, "Supreme" | Lista de bloqueo; **no uses tres rayas paralelas en mangas o costados** (se parecen a una marca registrada) | Regla [OFICIAL]; ejemplo de las tres rayas [IDEA PROPIA] |
| 3 | Personajes, franquicias, anime, videojuegos, memes con dueño | Mario, Pikachu, "skibidi", personajes de series | Prompts **sin nombres propios** y sin "estilo de X"; revisar la salida de la IA para detectar personajes reconocibles | [OFICIAL] "permiso del titular"; el resto [IDEA PROPIA] |
| 4 | Copiar ítems de otros creadores o de Roblox | Capturar un ítem del catálogo y pedirle a la IA "una versión parecida" | No usar capturas del catálogo como imagen de entrada; QC de casi-duplicados | [OFICIAL] policy ("overly similar") |
| 5 | Estampados de diseñadores | Monogramas, cuadros reconocibles de casas de moda | Usar patrones genéricos (vichy, rombos, rayas, camuflaje) y colores propios | [IDEA PROPIA] |
| 6 | Tipografías | Fuente comercial incrustada en el texto de la camisa | Usar fuentes con licencia explícita (p. ej. OFL: Fredoka/Nunito ya están en `ROBLOX/marketing/fish-and-fortune/specs-video/fonts/`); `--font ruta.ttf`. La fuente por defecto de Pillow es Aileron según su código; su licencia exacta [NO VERIFICADO] | [IDEA PROPIA] |
| 7 | Eslóganes, letras de canciones, citas | "Just Do It", versos de canciones | Texto propio y corto | [IDEA PROPIA] |
| 8 | Personas reales / deepfakes | Cara de un famoso o de un streamer | No incluir caras ni nombres de personas reales | [OFICIAL] "permiso del titular" |
| 9 | Licencia insuficiente de la herramienta de IA | Plan gratuito no comercial | Solo planes de pago con derechos comerciales o pesos con licencia que lo permita (§6) | [TERCERO] |
| 10 | Keyword-stuffing con marcas ajenas en el nombre/descripción | "Obby adopt me pokemon mario …" | Nunca nombres de otras IP; la doc oficial lo cita como mal ejemplo y "puede producir una democión" | [OFICIAL] [publish-games](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/publish-games-and-places.md) |

**Camino legítimo para usar IP de terceros:** el **Catálogo de licencias** del Creator Hub (*Explore → Licenses*). Una *Marketplace license* da permiso para vender ítems basados en esa IP; se aplica a una creación concreta, con una tarifa de reparto, duración, estándares de contenido y guía de marca; se solicita con un *pitch* y el titular aprueba, rechaza o condiciona. En *Item Attributes* del ítem eliges la licencia aprobada antes de publicar [OFICIAL, [creators](https://github.com/Roblox/creator-docs/blob/main/content/en-us/ip-licensing/creators.md#marketplace-licenses), [publish](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/publish-to-marketplace.md)]. Disponibilidad real de licencias de ropa [NO VERIFICADO].

**Checklist de higiene de IP antes de cada subida** (lo ejecuta Claude Code salvo el último punto): (1) texto contra la lista de bloqueo; (2) sin logos ni marcas en la imagen; (3) casi-duplicados dentro del lote; (4) sin caras ni personajes; (5) expediente del ítem guardado; (6) **tú**, una mirada humana a la vista previa a tamaño real.

---

## 6. Pipeline con IA para producir a escala

### 6.1 Vista general

```
Idea/tema ──► Diseño ───────────► QC automático ──► Prueba en Studio ──► Subida ──► Moderación ──► Publicar ──► Medir
(Claude)     generador procedural    (clothgen qc,     (TÚ, Block Avatar)   (TÚ, 80 R$)  (≤24 h)     (TÚ, anticipo   (TÚ + Claude
             o tesela de IA +        blocklist,                                                         + precio)       leen CSV)
             `seamless` + prenda     duplicados, piel)
Texto (nombre, descripción) ─► manifest.csv ─► (copiar/pegar a mano)
```

### 6.2 Herramientas (precio, licencia, calidad)

Los precios de IA cambian cada pocas semanas: **trátalos como orientativos y revisa los términos el día de contratar**. Para tarifas y planes de 3D, audio y marketing, ver [05](05-ia-assets-y-marketing.md).

| Herramienta | Para qué en ropa | Precio / límites | Licencia comercial | Calidad para clásica 2D | Etiqueta y fuente (fecha) |
|---|---|---|---|---|---|
| **`clothing-gen` (este repo)** | Rayas, degradados, tie-dye, camuflaje, rombos, zigzag, lunares, triángulos, olas, vichy, moteado, texto; piezas seamless; control de calidad; manifiesto | Gratis, corre en CPU | Código propio del repo; los diseños son originales y matemáticos | Buena para básicos, estampados y *drops* en serie; no hace ilustraciones | [OFICIAL] (plantilla) + construido y probado 2026-10-20 |
| **Adobe Firefly** | Estampados e ilustración sin personajes | Planes de pago desde ~US$5 al mes según blogs | Descrito como el de menor riesgo: entrenado con Adobe Stock, contenido licenciado y dominio público; indemnización a clientes elegibles en el modelo propio | Buena para texturas y patrones | [TERCERO, flojo] resumen de una búsqueda web del 2026-10-20 con varias fuentes secundarias (sin abrir ninguna página oficial de Adobe) [NO VERIFICADO] |
| **Midjourney** | Patrones decorativos y ambientes | Basic 10 · Standard 30 · Pro 60 · Mega 120 USD/mes ([05](05-ia-assets-y-marketing.md)) | Uso comercial en planes de pago; empresas con > 1 M USD/año deben usar Pro o Mega; sin indemnización; hay litigios en curso de estudios por personajes protegidos | Muy buena estética; el texto dentro de la imagen es flojo; **riesgo de parecerse a IP reconocible** | [TERCERO] [terms.law 2026-01-15](https://terms.law/2026/01/15/midjourney-commercial-use-rights-complete-2026-guide/) |
| **Ideogram** | Patrones con texto legible | De pago ~8-20 USD/mes según fuente | Planes de pago; el gratis genera en público | Buena con texto | [TERCERO] ([05](05-ia-assets-y-marketing.md)); las fuentes discrepan |
| **Leonardo.Ai** | Texturas y patrones | Desde ~12 USD/mes (fuentes) | Las fuentes discrepan sobre el plan gratuito | Aceptable | [TERCERO] [NO VERIFICADO] |
| **FLUX.1 [schnell]** (pesos abiertos) | Generación local de teselas si tienes GPU | Gratis; sin GPU no es viable aquí | **Apache-2.0** | Rápido; calidad media | [TERCERO: repo oficial del fabricante] [LICENSE-FLUX1-schnell](https://github.com/black-forest-labs/flux/blob/main/model_licenses/LICENSE-FLUX1-schnell), [README](https://github.com/black-forest-labs/flux/blob/main/README.md), leído 2026-10-20 |
| **FLUX.1 [dev]** | Idem | Gratis | **Licencia no comercial para el modelo** ("uso no comercial y no productivo"); sobre las *salidas* dice que "no reclama propiedad" y que puedes usarlas "para cualquier fin, incluso comercial, salvo lo expresamente prohibido", con obligaciones de filtros de contenido; para uso comercial del modelo hay licencia de pago | Buena | [TERCERO: repo oficial] [LICENSE-FLUX1-dev](https://github.com/black-forest-labs/flux/blob/main/model_licenses/LICENSE-FLUX1-dev), 2026-10-20. **Ambiguo para un negocio: prefiere schnell o pide licencia** [IDEA PROPIA]. [05](05-ia-assets-y-marketing.md) cubre FLUX.2 |
| **Stable Diffusion XL** (pesos abiertos) | Generación local | Gratis; necesita GPU | CreativeML Open RAIL++-M (26-jul-2023): "el licenciante no reclama derechos sobre la salida; eres responsable de ella y de su uso"; con restricciones de uso | Buena con ajustes | [TERCERO: repo oficial] [LICENSE-SDXL1.0](https://github.com/Stability-AI/generative-models/blob/main/model_licenses/LICENSE-SDXL1.0), 2026-10-20 |
| **Texture Generator / Material Generator (Studio)** | Texturas para *mallas* (ropa 3D) y materiales repetibles | La doc no da precio | **Titularidad y costes: no documentados** | Útil para 3D; **no sirve para plantillas clásicas** | [OFICIAL] uso; [NO VERIFICADO] el resto |
| **Blender** + plugin oficial de Roblox | Modelado, UV, jaulas, exportación FBX | Gratis | Los modelos que crees son tuyos [NO VERIFICADO, conocimiento previo; ver [05](05-ia-assets-y-marketing.md)] | Imprescindible para 3D | [OFICIAL] plantillas `.blend` |
| **GIMP / Krita / Photopea** | Retoque manual de piezas | Gratis | Software libre / web | Suficiente | [NO VERIFICADO] licencias exactas; uso estándar |
| **ImageMagick** (`convert`) | Conversiones, mosaicos de revisión | Ya instalado | — | — | Entorno |
| **IA 3D** (Meshy, Tripo, Rodin, etc.) | Bocetos de forma para accesorios rígidos | ~20 USD/mes y más | Ver [05](05-ia-assets-y-marketing.md) | **Mala para ropa en capas** (exige malla estanca de una pieza ≤ 4.000 triángulos con jaulas) | [TERCERO] / [DERIVADO] de las especificaciones |

### 6.3 Prompts de ejemplo (para una herramienta de IA con licencia comercial)

**Reglas de prompt [IDEA PROPIA]:** (1) describir *estilo y forma*, nunca nombres propios, marcas ni "al estilo de"; (2) pedir `seamless tileable`, vista cenital, **sin sombras ni pliegues** (el sombreado horneado queda mal en una prenda); (3) sin texto (el texto se añade después con `--text-front` y una fuente con licencia); (4) cuadrado 1:1 y alta resolución; (5) revisar a mano cada salida: personajes, logos o letras "fantasma".

| # | Tema | Prompt |
|---|---|---|
| 1 | Tie-dye | `Seamless tileable tie-dye pattern, concentric swirls in cobalt blue, magenta and warm yellow on white, soft dye bleed, flat top-down fabric, no text, no logos, no characters, square 1:1` |
| 2 | Camuflaje | `Seamless tileable camouflage pattern, organic blobs in olive green, sand, charcoal and stone gray, flat lay, even lighting, no text, no logos` |
| 3 | Retro geométrico | `Seamless 1970s wavy stripe pattern in burnt orange, mustard, brown and cream, flat vector style, no text, no characters` |
| 4 | Nubes pastel | `Seamless pattern of soft pastel clouds and tiny stars in pink, lavender and mint, flat vector illustration, no faces, no characters, no text` |
| 5 | Denim | `Seamless denim fabric texture, medium blue twill weave, subtle fading, orthographic top-down, even lighting, no stitching, no labels, no pockets` |
| 6 | Halloween genérico | `Seamless pattern of simple geometric bats and crescent moons in flat orange, purple and black, bold minimal shapes, no gore, no skulls, no text, no characters` |
| 7 | Navidad genérica | `Seamless pattern of snowflakes and pine branches in forest green, cream and berry red, flat vector, no text, no characters, no religious symbols` |

**Negative prompt** (si la herramienta lo admite): `text, letters, watermark, logo, brand, trademark, character, mascot, celebrity, face, signature, border, vignette, perspective, shadow, fold, wrinkle`.

### 6.4 Patrones seamless: cómo se garantizan

1. **Procedural (garantizado por construcción):** todos los patrones del generador son periódicos con el período del cilindro de cada parte (384 px el torso, 256 px cada extremidad). `tests/test_periodic.py` evalúa cada patrón dos vueltas seguidas y exige `f(U + C) = f(U)`; también hay pruebas de periodicidad vertical para las teselas y para el patrón `image`. Resultado de la última ejecución: **8 pruebas, OK** [MEDIDO].
2. **Imagen de IA → tesela:** `clothgen seamless --input x.png --out tile.png` mezcla la imagen con ella misma desplazada media vuelta; `tile_seam_score` pasa de 168 a 11 (escala 0-255) en una prueba con un degradado sintético [MEDIDO]. Después, `--pattern image --param path=tile.png --param scale=0.5` la repite un número entero de veces alrededor del cuerpo.
3. **Revisión visual:** mira siempre `previews/<id>-overlay.png` (las regiones con contorno) y la hoja de contactos de la colección.

### 6.5 Control de calidad (QC)

| Capa | Qué comprueba | Cómo |
|---|---|---|
| Automático (hecho) | PNG; tamaño exacto 585×559 (T-shirt cuadrada); modo RGBA; **ningún píxel opaco fuera de las regiones oficiales**; cobertura; costura de cierre; texto contra lista de bloqueo; texto excesivo; color "piel" (aviso); casi-duplicados del lote | `python -m clothgen qc` / se ejecuta al generar; devuelve código 1 si falla |
| Manual 1 (tú, 2 min por lote) | Mirar la hoja de contactos a tamaño real; descartar lo que se parezca a una marca o personaje | — |
| Manual 2 (tú, Studio) | Probar 2-3 ítems por lote con *Block Avatar*: orientación de caras, altura de zapatos/puños, camisa sobre pantalón | La prueba no cuesta Robux [OFICIAL] |
| Tras subir | Registrar aprobado/rechazado y el motivo en `manifest.csv` | Claude Code resume tasas por tema |

### 6.6 Ropa en capas con Blender: qué se puede asistir

**Flujo oficial** [OFICIAL, [tutorial](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/accessories/creating/index.md)]: partir del maniquí y las plantillas de jaula → modelar la prenda → *sculpt*/ajuste → UV → textura → armazón R15 y pesos → jaulas interior/exterior → exportar FBX → Importer → AFT → validar → subir. Ajustes de exportación en [export-requirements](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/export-requirements.md).

**Qué puede hacer Claude Code aquí [IDEA PROPIA, no probado en este entorno]:** sin Blender ni GPU en esta sesión no pude ejecutar nada de 3D. En tu PC, con Blender + el servidor MCP de Blender (ver [05 §3.3](05-ia-assets-y-marketing.md)), Claude puede escribir y ejecutar scripts `bpy` para: abrir `Clothing_Cage_Template.blend`, duplicar la malla base, asignar el material, **aplicar a la UV las teselas generadas** (`clothgen tile`), comprobar triángulos (≤ 4.000), exportar FBX con los ajustes oficiales y repetir por lote. **El modelado de formas y el ajuste fino de jaulas exigen criterio humano**; una IA 3D rara vez entrega una malla estanca de una pieza con jaulas válidas. Recomendación: 3-4 prendas base (camiseta, sudadera, pantalón, shorts) modeladas una vez y **retexturizadas en lote** con distintos estampados; cada variante cuesta 80 R$ de subida + 600 R$ de anticipo (anticipo recuperable por ventas, ver [08](08-ropa-vs-juegos.md)).

### 6.7 Cómo Claude Code orquesta el trabajo

| Tarea | Cómo | Cuándo |
|---|---|---|
| Generar un lote con tema | `python -m clothgen collection --n 24 --theme christmas --kind set --lang en --unique-patterns --out out/xmas` (de `ROBLOX/tools/clothing-gen/`, con el python del venv) | Cada lanzamiento |
| Lote a medida | `python -m clothgen batch --config lote.json` (ver `batch.example.json`) | Colecciones con texto o prendas distintas |
| Estampado propio de IA | `seamless` → `--pattern image` | Si hay ilustraciones con licencia |
| QC | `python -m clothgen qc --dir out/xmas` | Siempre antes de subir |
| Textos y manifiesto | `manifest.csv` con `id, type, file, name, description, qc_ok, uploaded_by_hand, asset_id, price_robux, notes` | Tú rellenas `uploaded_by_hand`, `asset_id`, `price_robux` |
| Ayudantes en paralelo | Un ayudante diseña, otro revisa IP/política, otro redacta textos (regla del proyecto: ayudantes en paralelo) | Lotes grandes |
| Lotes programados | Tareas programadas (`/loop` o un `cron`) para preparar el siguiente lote con X días de antelación según el calendario (§7) | Mensual |
| Análisis de resultados | Exportar *Transactions* a CSV y pedir a Claude un resumen por tema/patrón | Semanal |

---

## 7. Nombres, descripciones, etiquetas y precios; estacionalidad

### 7.1 Nombres, descripciones y "etiquetas"

- **No hay campo de etiquetas** en los flujos documentados: en clásica, solo *Name* y *Description*; en 3D, *Title* y *Description* [OFICIAL]. Roblox "clasifica los ítems automáticamente" por categoría [OFICIAL, [publish](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/publish-to-marketplace.md)].
- **Buenas prácticas oficiales** (de juegos, pero la doc de ítems remite a ellas: "metadata best practices") [OFICIAL, [publish-games](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/publish-games-and-places.md)]: nombre coherente y estable; sin repetir palabras (*Obby Madness* sí, *Obby Madness OBBY OBBY OBBY* no); como mucho una o dos decoraciones emoji; descripción con una primera frase que resuma el producto y palabras clave **relevantes**, sin repeticiones ni palabras irrelevantes (la doc lo ejemplifica con una lista de marcas ajenas como mal ejemplo).
- **Qué funciona en el catálogo [NO VERIFICADO]:** no tengo datos de búsqueda ni de conversión. **[IDEA PROPIA]** para probar: nombres de 3-4 palabras `[tema/color] [estampado] [prenda]` ("Sunset Stripes Shirt"), con la misma estructura en toda una colección; descripción de una o dos frases con palabras genéricas buscadas ("tie dye", "camo", "striped", "plaid") y la mención "combina con la colección". El generador (`naming.py`) produce esa estructura en inglés o español. **Nunca nombres de marcas, personajes ni palabras de moda con dueño.**
- **Idioma:** el catálogo es global; título en inglés + descripción en inglés es la apuesta por defecto [IDEA PROPIA, sin datos].

### 7.2 Precios (la economía completa está en [08](08-ropa-vs-juegos.md))

| Hecho | Valor | Fuente |
|---|---|---|
| Precio mínimo ("price floor") | **Dinámico por tipo de activo**; no se puede vender por debajo; Limiteds gratis (con tarifa por unidad) son la única forma de precio 0 | [fees](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-fees-and-commissions.md#price-ranges), [publish](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/publish-to-marketplace.md) [OFICIAL] |
| Controles de precio | *Amount Above Price Floor* (obligatorio, puede ser 0) y *Do Not Price Below* (opcional) | [OFICIAL] |
| Reparto progresivo en Marketplace | 1× el mínimo → 30 %; 1,3× → 37 %; 1,5× → 41 %; 2× → 50 %; 3× → 62 %; 6× o más → 70 % | [OFICIAL] fees |
| Opciones adicionales | Precios regionales (activados por defecto, se puede salir); opciones por tiempo de 3, 7 o 14 días para camisas, pantalones y jerséis 3D | [OFICIAL] |
| Valores actuales de los mínimos | Están en `create.roblox.com/dashboard/creations/pricing` (bloqueado desde aquí) | [NO VERIFICADO] |

**[IDEA PROPIA] para medir:** el primer lote con *Amount Above Price Floor* = 0; el segundo con ~30 % por encima (→ 1,3× ≈ 37 %); el tercero con ~50 % (→ 41 %), y comparar unidades vendidas por ítem entre grupos de ítems equivalentes. No cambies precios constantemente.

### 7.3 Calendario de estacionalidad (hoy 2026-10-20)

Reglas de planificación: moderación **hasta 24 h** [OFICIAL]; programar venta **hasta 30 días antes** [OFICIAL]; **subir al menos 10 días antes** de la fecha clave para absorber un rechazo y un reenvío [IDEA PROPIA]. Fechas calculadas con calendario gregoriano [DERIVADO]; la de Año Nuevo Lunar **no la verifiqué** [NO VERIFICADO].

| Evento | Fecha | Temas seguros | Cuidado con la política (§3) | Subir antes de |
|---|---|---|---|---|
| **Halloween 2026** | sáb 2026-10-31 | murciélagos, calabazas genéricas, colores otoño | sangre, vísceras, armas, violencia | **2026-10-27** (ya casi no hay margen) |
| Acción de Gracias (EE. UU.) | jue 2026-11-26 | otoño, texturas cálidas | tema religioso | 2026-11-12 |
| **Black Friday / Cyber Monday** | vie 2026-11-27 / lun 2026-11-30 | básicos y colecciones a juego; lanzamiento de la temporada | — | 2026-11-13 (programar inicio) |
| **Navidad y vacaciones de invierno** | vie 2026-12-25 (vacaciones escolares aprox. mediados de dic.-principios de ene. según país) | invierno, nieve, rojo/verde, suéteres | Símbolos religiosos (natividad, cruces) por la regla "religioso" | 2026-12-01 a 2026-12-10 |
| Año Nuevo | vie 2027-01-01 | dorado, confeti genérico | — | 2026-12-18 |
| Año Nuevo Lunar | feb. 2027 (≈ 6-feb) [NO VERIFICADO] | rojo y dorado genéricos | símbolos religiosos o marcas | principios de ene. |
| San Valentín | dom 2027-02-14 | rosa y rojo, geométricos | **"citas/bodas" está prohibido**: sin "couple", "date", "wedding", pareja a juego | 2027-02-01 |
| Pascua | dom 2027-03-28 | primavera, pasteles, flores | **religioso**: evitar la temática pascual explícita | 2027-03-15 |
| Verano | jun.-ago. 2027 | playa, tropical, neón | — | mayo |
| Vuelta al cole | ago.-sep. 2027 | uniformes genéricos, básicos | — | julio |
| Halloween 2027 | dom 2027-10-31 | ídem | ídem | 2027-10-01 |

**Cómo pasar de un calendario a una cadencia [IDEA PROPIA]:** un lanzamiento de 10-12 ítems cada 3-4 semanas, con 1 prenda "evergreen" (rayas, camuflaje, vichy) siempre a la venta y un tema de temporada. **La relación entre estacionalidad y ventas por ítem sigue sin datos** [NO VERIFICADO, ver [08 §3.3](08-ropa-vs-juegos.md)].

---

## 8. ¿Existe una API para subir ropa y accesorios?

**Respuesta: no hay API oficial para subir ropa clásica ni ítems de avatar al Marketplace.** Evidencia (leída en la doc oficial el 2026-10-20):

| Vía | Qué soporta | ¿Sirve para ropa de avatar? | Fuente |
|---|---|---|---|
| **Open Cloud Assets API** (`POST apis.roblox.com/assets/v1/assets`; beta) | Tipos con contenido: **Animation, Audio, Decal/Image (png, jpeg, bmp, tga; < 8000×8000), Mesh (solo contenido ya descargado de Roblox), Model (fbx, gltf, glb, rbxm, rbxmx), Video**; hasta 20 MB por llamada; clave API con permisos `asset:read/asset:write`; límite 120 solicitudes por minuto por propietario de la clave; `expectedPrice` para limitar la tarifa | **No:** no hay tipo Shirt, Pants, T-Shirt ni Accessory de avatar. Sirve para subir una *Imagen/Decal* (no se vende) o *Modelos* (paquetes) | [usage-assets](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/usage-assets.md), [assets/v1.json](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/cloud/assets/v1.json), [openapi.json](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/cloud/openapi.json) [OFICIAL] |
| Menciones de Shirt/Pants en Open Cloud | Entre los 833 endpoints del `openapi.json`, solo aparecen en la **lectura** de inventario (`/v2/users/{userId}/inventory`, filtros `CLASSIC_TSHIRT`, `CLASSIC_PANTS`, etc.) | Solo **leer** | [inventory](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/inventory.md) [OFICIAL] |
| `AssetService:CreateAssetAsync` / `CreateAssetVersionAsync` | Solo en *plugins* locales; tipos **Model, Plugin, Mesh (EditableMesh), Image (EditableImage)** | **No** | [AssetService](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/AssetService.yaml) [OFICIAL] |
| `AssetService:PromptCreatePlatformContentAsync` | Diálogo en un juego para que el jugador guarde un `Model` en su inventario | **No** | ídem [OFICIAL] |
| `AvatarCreationService` (creación en el juego) | Jugadores crean cuerpos/maquillaje y los compran; requiere *Avatar Creation Token*; **los ítems no se listan en el Marketplace ni se revenden** | **No** (otra finalidad) | [in-experience-creation](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/in-experience-creation.md), [token](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/avatar-creation-token.md) [OFICIAL] |
| Plugin de Blender de Roblox | Sube mallas o colecciones por Open Cloud **como paquetes** | No son ítems de avatar | [05](05-ia-assets-y-marketing.md) [OFICIAL] |
| Studio → *Save to Roblox* → *Avatar Asset* | Sí (3D) | **Es el único camino 3D, manual** | [publish](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/publish-to-marketplace.md) [OFICIAL] |
| Creator Dashboard → Classics | Sí (clásica) | **Único camino clásico, manual** | [classic-clothing](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/classic-clothing.md) [OFICIAL] |

**Lo que sí se puede automatizar alrededor:** el diseño, la validación, los textos, el manifiesto, la cadencia, la lectura de resultados.

**Lo que desaconsejo:** automatizar la web de subida con la cookie `.ROBLOSECURITY` o endpoints no documentados (violación probable de los Términos y riesgo de bloqueo; no verificado el texto exacto [NO VERIFICADO], pero no compensa el riesgo). **Alternativa de bajo riesgo [IDEA PROPIA, ToS NO VERIFICADO]:** un asistente de navegador en *tu* sesión (Claude en Chrome / uso de ordenador) que rellene los formularios mientras tú miras y **confirmas cada pago**; un lote pequeño y supervisado, nunca desatendido; solo si Roblox no lo prohíbe en sus Términos. El ahorro (minutos por ítem) no compensa si no estás seguro.

---

## 9. Qué se automatiza y qué haces tú

| Paso | Automatizable por Claude Code | Debes hacerlo tú | Por qué |
|---|---|---|---|
| Investigar temas y calendario | Sí (con las limitaciones de §7) | Decidir | — |
| Generar diseños (procedurales) | **Sí, en lote** | Revisar a ojo | Verificado en §10 |
| Generar con IA externa | Los prompts, el seamless, el empaquetado | **Generar en la herramienta con tu cuenta y plan; guardar el expediente de licencia** | Cuenta y facturación propias |
| QC técnico, IP y duplicados | **Sí** | Decidir casos dudosos | — |
| Prueba en Studio | Guion paso a paso | **Sí** (Studio en tu PC) | No hay Studio aquí |
| Verificación de identidad (documento + selfie) | No | **Sí** | Datos biométricos y personales [OFICIAL: [account-verification](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/account-verification.md); ≥ 13 años, documento con foto, móvil con cámara] |
| Verificación en dos pasos | No | **Sí** | Requisito de publicar |
| Comprar Roblox Plus/Premium y Robux | No | **Sí** | Pagos |
| Subida y pago de 80 R$ | No (no hay API) | **Sí** | §8 |
| Elegir tipo, nombre, descripción | Preparar textos | Pegarlos | — |
| Publicar, anticipo, precio, programar venta | Calcular y sugerir | **Sí** | Pagos |
| Responder moderación y apelaciones | Redactar borradores | **Sí** | Es tu cuenta |
| Impuestos y retiros (DevEx) | No | **Sí** | Fuera de este informe; ver `CLAUDE.md` y [02](02-monetizacion-y-economia.md) |
| Medir resultados | **Sí**, a partir de CSV exportados | Exportarlos | — |

---

## 10. Lo que se construyó: `ROBLOX/tools/clothing-gen/`

**Qué es.** Generador procedural en Python (Pillow + NumPy, instalados en un `venv` local ignorado por git) que produce **camisas, pantalones y camisetas clásicas** con estampados originales y los valida. Lee `ROBLOX/tools/clothing-gen/README.md`.

**Por qué las coordenadas son fiables [OFICIAL, MEDIDO].** Bajé la plantilla oficial (Git LFS) desde `media.githubusercontent.com`, comprobé que su SHA-256 coincide con el `oid` del puntero LFS del repo, medí las 18 regiones con componentes conexos de color y las comparé con `clothgen/layout.py`:

```
sha256 Template-Shirts-R15.png: OK
sha256 Classic-Clothing-Templates.zip: OK
Template-Shirts-R15.png: lienzo (585, 559), 18 regiones medidas, layout.py coincide: True
Template-Pants-R15.png: lienzo (585, 559), 18 regiones medidas, layout.py coincide: True
RESULTADO: OK
```

**Evidencia de que funciona [MEDIDO 2026-10-20].**

| Prueba | Resultado |
|---|---|
| `python -m unittest discover -s tests` | **8 pruebas OK** (periodicidad de los 13 patrones en torso y extremidades; periodicidad vertical de teselas; patrón `image`; tamaños de región = tabla oficial; caras dentro del lienzo y sin solaparse) |
| Dos errores reales detectados por las pruebas y corregidos | Parpadeo de redondeo en bordes diagonales (rombos, rayas diagonales) y ciclo de color de filas en lunares al envolver verticalmente |
| `batch.example.json` (8 ítems) | 12 archivos, **QC 12/12 OK**; `identify` de ImageMagick confirma `585x559 srgba` en camisas/pantalones y `512x512 srgba` en la T-shirt |
| `collection --n 12 --theme halloween` | 24 archivos, QC 24/24 OK; hoja de contactos revisada visualmente; el QC de casi-duplicados avisó de 4 pares parecidos en una versión anterior del generador (paletas de bajo contraste) y de ninguno en la versión final |
| Prueba negativa de IP | El texto "NIKE FAN" en una T-shirt falla con `textos con posible marca/IP: ['nike']` y código de salida 1 |
| Prueba negativa de "piel" | Una camisa lisa color `#e8b98a` avisa "100 % de los píxeles parecen color piel" |
| `seamless` | Una imagen no teselable pasa de costura 168 a 11 |

**Qué incluye:** 13 patrones (rayas, degradado, tie-dye, camuflaje, cuadros, rombos, zigzag, lunares, triángulos, olas, vichy, moteado, liso) + `image` (tu tesela); 17 paletas (12 genéricas y 5 estacionales: halloween, christmas, valentine, spring, summer); opciones de manga corta/larga/sin mangas, shorts, puños, dobladillo, cuello, texto (con `--font`); T-shirt 512×512 con insignia (círculo, hexágono, rombo, rectángulo redondeado); teselas seamless; `qc`, `batch`, `collection`, `seamless`, `list`; salidas `manifest.csv`, `qc_report.json`, vistas previas (superposición con las regiones oficiales, muñeco plano de frente/espalda, hoja de contactos). Ejemplos pequeños en `examples/` (1,3 MB).

**Límites y lo que NO se pudo verificar:** no se probó en Roblox Studio ni se subió nada; el muñeco plano es una aproximación 2D (el orden de capas camisa/pantalón y el aspecto real en el avatar quedan por comprobar con *Block Avatar*); las mangas cortas (56 px), shorts (64 px), puños y dobladillo (10 px) son decisiones de estilo propias, no medidas oficiales; la fuente por defecto de Pillow tiene licencia por confirmar (usa `--font`); la lista de bloqueo de IP es una ayuda, no una garantía; no hay IA generativa en la máquina (sin GPU).

---

## 11. Plan de producción de 30 días (2026-10-21 a 2026-11-19)

**Principio [IDEA PROPIA]:** gastar poco, aprender rápido y decidir con datos. **Condición previa:** que cumplas los requisitos de §9 (ID, 2FA, Plus/Premium). Si no los cumples o no quieres pagarlos, el plan se reduce a preparar los diseños y retomar cuando sí. **Recordatorio de [08](08-ropa-vs-juegos.md):** los juegos son el motor; la ropa es una línea secundaria; la clásica 2D no la soportan muchos avatares del Marketplace [OFICIAL: aviso en classic-clothing] y la ropa en capas es el producto "moderno".

### 11.1 Presupuesto máximo del plan [DERIVADO de las tarifas oficiales; valor DevEx 0,0038 USD por Robux según `CLAUDE.md`]

| Escenario | Contenido | Subidas (80 R$) | Anticipos | Total R$ | ≈ US$ |
|---|---|---:|---:|---:|---:|
| **Mínimo** | 12 clásicas + 3 ropa en capas | 15 × 80 = 1.200 | 12 × 10 + 3 × 600 = 1.920 | **3.120** | **≈ 11,9** |
| **Medio** | 24 clásicas + 6 ropa en capas | 30 × 80 = 2.400 | 24 × 10 + 6 × 600 = 3.840 | **6.240** | **≈ 23,7** |

Las subidas no se reembolsan; el anticipo se devuelve con las ventas ("rebate" igual a la comisión de plataforma, hasta recuperarlo) [OFICIAL, ver [08 §2.3](08-ropa-vs-juegos.md)]. Si pagas con Robux comprados, el coste en dinero es mayor [NO VERIFICADO el precio en tu país].

### 11.2 Calendario

| Fechas | Objetivo | Tareas (quién) | Entregable / puerta |
|---|---|---|---|
| **Sem. 1: 21-27 oct** ("prueba de Halloween") | Probar el pipeline de extremo a extremo con riesgo mínimo | **Tú:** ID, 2FA, Plus/Premium, abrir el Creator Dashboard y comprobar que aparece *Avatar Items → Classics*; instalar Studio (si no lo tienes); anotar el anticipo y el precio mínimo vigentes. **Claude:** `collection --theme halloween --n 12`; QC; elegir 3 a probar; textos y manifiesto. **Tú:** probar los 3 en *Block Avatar*; subir primero esos 3 (240 R$) | **Puerta 1 (27-oct):** ≥ 2 de 3 aprobados en ≤ 24 h. Si no: leer el motivo, ajustar y repetir; **no subir más** hasta entender el rechazo |
| 22-27 oct | Completar el primer lote | Si la puerta 1 pasa: subir 9 más; publicar con precio = mínimo + 0 | Lote 1 publicado (≤ 27-oct); no esperes ventas: el objetivo es medir aprobación y tiempo |
| **Sem. 2: 28 oct-3 nov** | Segundo lote y primera prenda 3D | **Claude:** lote 2 "otoño/básicos" (12 ítems, mezcla evergreen); **tú:** preparar Blender con `Clothing_Cage_Template.blend` y modelar **una** camiseta base; **Claude:** scripts de texturizado con teselas; AFT y validación | 1 prenda 3D validada en Studio (sin subir aún) |
| **Sem. 3: 4-10 nov** | Piloto 3D + lote de temporada | **Tú:** subir la prenda 3D (80 R$) y, si aprueba, publicar (600 R$); crear 2 variantes de textura. **Claude:** lote 3 "Black Friday/invierno" (12 clásicas + texto de lanzamiento) | Hasta 3 prendas 3D subidas; lote 3 listo y probado |
| **Sem. 4: 11-19 nov** | Programar la temporada y decidir | **Tú:** subir el lote 3 antes del 13-nov y **programar el inicio de venta** (≤ 30 días de antelación) para ~20-nov; **Claude:** informe de resultados a partir de *Transactions*; preparar el lote de Navidad (subir 1-10 dic) | Informe y decisión |

### 11.3 Métricas y criterios de decisión [IDEA PROPIA; coherentes con [08 §6.3](08-ropa-vs-juegos.md)]

| Métrica | Umbral para continuar |
|---|---|
| Tasa de aprobación de moderación | ≥ 80 % (si es menor, parar y analizar motivos) |
| Tiempo de moderación | Se cumple "≤ 24 h" en la mayoría |
| Coste por ítem (R$) | Medir: 90 en clásica, 680 en capas |
| Unidades vendidas a 14 días por ítem | Anotar; si la mediana es 0 tras 2 lotes, **no escalar**; revisar tema, precio y calidad |
| Anticipo recuperado | Medir el progreso en *Publishing Advance Rebates* |
| Tiempo humano por lote | ≤ 2 h por 12 ítems de clásica con este pipeline [IDEA PROPIA, objetivo] |

**Qué no hacer en 30 días:** no pagar Limiteds (anticipos de 5.000 R$ o más), no emisivo (500 R$ + anticipo ×5), no cuerpos ni cabezas, no meter más de 12 ítems por tema sin datos.

---

## 12. Dudas abiertas (lo que no pude verificar)

1. Reglas de Roblox sobre IA en los Términos de Uso y las Normas de la Comunidad (`help.roblox.com` inaccesible).
2. Valores vigentes de precio mínimo y de anticipo por tipo (cambian "2-3 veces por trimestre") y la página de precios (`create.roblox.com`, bloqueada).
3. Si los *schedule sale* y los *timed options* se aplican a ropa clásica (la doc de programación está en la guía de 3D).
4. Cómo se genera la miniatura de una clásica y si puede editarse; contradicción entre *custom-thumbnails* ("no se puede cambiar tras subir") y *publish* ("la actualización puede corregir la miniatura").
5. Peso máximo y resolución mínima aceptados para imágenes clásicas.
6. Costes y titularidad de las salidas de Texture Generator y Material Generator.
7. Términos exactos de Firefly, Leonardo y gpt-image (no abrí páginas oficiales: solo `github.com` es accesible desde aquí).
8. Licencia exacta de la fuente por defecto de Pillow (Aileron) y de GIMP/Krita/Photopea (usos estándar, sin comprobar).
9. Si el asistente de navegador en tu propia sesión está permitido por los Términos de Roblox.
10. Fecha exacta del Año Nuevo Lunar 2027 y efecto real de la estacionalidad en las ventas de ropa.
11. Aspecto real de los PNG generados sobre un avatar (requiere Studio).

---

## 13. Fuentes (todas leídas el 2026-10-20 salvo indicación)

**Oficiales (Roblox/creator-docs, commit `7400643`, 2026-10-20):** [classic-clothing](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/classic-clothing.md) · [Classic-Clothing-Templates.zip](https://github.com/Roblox/creator-docs/blob/main/content/en-us/assets/accessories/classic-clothing/Classic-Clothing-Templates.zip) (binario vía `media.githubusercontent.com`) · [layered specs](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/layered-accessories/specifications.md) · [layered index](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/layered-accessories/index.md) · [layered import](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/layered-accessories/import.md) · [layered project files](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/layered-accessories/project-files.md) · [rigid specs](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/rigid-accessories/specifications.md) · [AFT](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/accessory-fitting-tool.md) · [automatic skinning transfer](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/automatic-skinning-transfer.md) · [marketplace policy](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-policy.md) · [fees and commissions](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-fees-and-commissions.md) · [publish to marketplace](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/publish-to-marketplace.md) · [moderation](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/moderation.md) · [intellectual property](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/intellectual-property.md) · [categories](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/categories.md) · [custom thumbnails](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/custom-thumbnails.md) · [FAQ](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/frequently-asked-questions.md) · [validation system](https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/validation-system.md) · [IP guidelines](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/ip-guidelines.md) · [IP licensing for creators](https://github.com/Roblox/creator-docs/blob/main/content/en-us/ip-licensing/creators.md) · [account verification](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/account-verification.md) · [Roblox Plus](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/roblox-plus.md) · [publish games (metadata best practices)](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/publish-games-and-places.md) · [texture specifications](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/texture-specifications.md) · [general mesh specifications](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/specifications.md) · [Texture Generator](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/texture-generator.md) · [model generation](https://github.com/Roblox/creator-docs/blob/main/content/en-us/parts/model-generation.md) · [generative AI in games](https://github.com/Roblox/creator-docs/blob/main/content/en-us/generative-AI.md) · [Assets API usage guide](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/usage-assets.md) · [Assets API spec](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/cloud/assets/v1.json) · [Open Cloud openapi.json](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/cloud/openapi.json) · [inventory API](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/inventory.md) · [AssetService](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/AssetService.yaml) · [in-experience creation](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/in-experience-creation.md) · [avatar creation token](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/avatar-creation-token.md). Licencia del repositorio: [CC BY 4.0](https://github.com/Roblox/creator-docs/blob/main/LICENSE).

**Licencias de modelos (repos de los fabricantes, leídos 2026-10-20):** [FLUX.1 README](https://github.com/black-forest-labs/flux/blob/main/README.md) · [LICENSE-FLUX1-schnell (Apache-2.0)](https://github.com/black-forest-labs/flux/blob/main/model_licenses/LICENSE-FLUX1-schnell) · [LICENSE-FLUX1-dev (no comercial)](https://github.com/black-forest-labs/flux/blob/main/model_licenses/LICENSE-FLUX1-dev) · [LICENSE-SDXL1.0](https://github.com/Stability-AI/generative-models/blob/main/model_licenses/LICENSE-SDXL1.0).

**Terceros (búsqueda web del 2026-10-20; resumen de buscador, páginas no abiertas):** [Midjourney Commercial Use Rights 2026 (terms.law)](https://terms.law/2026/01/15/midjourney-commercial-use-rights-complete-2026-guide/) · [Best AI image generators (redescuela.org)](https://redescuela.org/ai-tools/best-ai-image-generation-tools/) · [hilo del DevForum sobre borrados de ítems](https://devforum.roblox.com/t/seemingly-random-ugc-item-deletions-are-happening/3032202).

**Inaccesibles desde esta red:** `create.roblox.com`, `devforum.roblox.com` (salvo lo que devolvió el buscador), `en.help.roblox.com`, `docs.midjourney.com`, `huggingface.co`, `www.adobe.com`.
