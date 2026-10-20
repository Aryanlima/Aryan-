# Herramientas y apps de IA para assets y marketing de juegos Roblox

Informe técnico de arte, audio y marketing para producir muchos juegos pequeños de Roblox con microtransacciones.
Fecha de la investigación: **2026-10-20**. Idioma: español. Alcance: assets y marketing (no programación).

---

## 0. Resumen ejecutivo

1. **Roblox ya trae generación de IA dentro de Studio** (mallas, materiales, texturas PBR, modelos procedurales) y un servidor MCP oficial para conectar Claude Code. Es el punto de partida más barato y el que menos riesgo de licencia tiene. Los docs oficiales no dicen cuánto cuesta ni qué límites exactos tiene la generación de mallas.
2. **Límites oficiales de malla**: máximo **20.000 triángulos por malla individual**, malla estanca (watertight), un solo material y un solo set de UV por malla. Las mallas de IA suelen venir con muchos más triángulos, así que **Blender (decimar + bakear texturas) es obligatorio** en casi todos los casos.
3. **Licencias de 3D con IA, lo que importa**:
   - **Hunyuan3D 2.1 está prohibido en UE, Reino Unido y Corea del Sur** (licencia oficial). Si el usuario vive en España, no debe usarlo.
   - **El Cube 3D abierto de Roblox es solo investigación** (no comercial).
   - **TRELLIS.2 (Microsoft) es MIT** pero exige GPU NVIDIA de 24 GB o más.
   - Meshy y Tripo: la capa gratis lleva CC BY 4.0 (atribución) o no comercial según la fuente; **para producción hay que pagar el plan de pago (~20 USD/mes)** y leer sus términos el día de contratar.
4. **Iconos de game passes y productos**: máximo **512x512**, jpg/png/bmp, y lo importante debe quedar **dentro del círculo** (el resto se recorta). Icono de juego: cuadrado, mínimo 512x512. Miniaturas: 16:9, ideal 1920x1080. Todo pasa por moderación.
5. **Texto dentro de imágenes**: Ideogram y gpt-image-2 son los mejores según varias reseñas (todas de terceros). Midjourney y Flux son más flojos. Para iconos pequeños conviene generar la imagen sin texto y añadir el texto después en Figma o un editor.
6. **Audio**: Roblox exige derechos legales sobre lo que se sube. **Udio no permite descargas** (evitar). Suno exige plan de pago para uso comercial y tiene litigios abiertos. **El Creator Store tiene más de 100.000 SFX y música gratis** y es la opción de menor riesgo. No encontré una política oficial de Roblox sobre audio generado con IA.
7. **Animación**: el editor de Roblox incluye captura de cuerpo por vídeo (solo R15, menos de 15 s, una persona) y captura facial (hasta 60 s). Cascadeur, Plask y DeepMotion son alternativas de pago.
8. **Marketing**: los vídeos en la página del juego deben mostrar **juego real** (nada de gameplay inventado, voces en off ni música con letra). Para TikTok/Shorts, el footage del propio juego es gratis; las herramientas de vídeo de IA (Runway, Veo, Kling) solo sirven para anuncios o clips fuera de la página del juego.
9. **Automatización**: la API Open Cloud publica lugares (`.rbxl`) y sube assets. **Aviso importante**: la documentación oficial dice que la API de publicación **no actualiza `SurfaceAppearance`, `EditableMesh`, `EditableImage`, `PartOperation` ni `BaseWrap`**. Si los juegos usan texturas PBR, hay que verificar si esto sigue vigente antes de montar CI/CD.
10. **Presupuesto**: stack mínimo ≈ **0 a 40 USD/mes**; stack recomendado ≈ **150 a 170 USD/mes** (cálculo propio con precios de terceros, ver sección 10).

---

## 1. Metodología, etiquetas y límites de esta investigación

### Etiquetas usadas
| Etiqueta | Significado |
|---|---|
| **[OFICIAL]** | Leído por mí directamente en la fuente del propietario el 2026-10-20: documentación del Creator Hub de Roblox (a través del espejo oficial `Roblox/creator-docs` en GitHub, porque `create.roblox.com` está bloqueado), repositorios y licencias oficiales en GitHub, y `github.com/pricing`. |
| **[TERCERO]** | Información de blogs, reseñas o comparadores. Solo vi el **resumen que devuelve WebSearch**; no pude abrir las páginas (WebFetch dio ENOTFOUND). Los precios pueden estar desactualizados y a menudo se contradicen entre fuentes. Indico la fecha que declara la fuente cuando existe. |
| **[NO VERIFICADO]** | Conocimiento previo mío, o dato sin fuente comprobable hoy. No lo tomes como cierto sin comprobar. |

### Limitaciones (importante)
- **WebFetch** solo funcionó contra `github.com`. Falló (ENOTFOUND) con `create.roblox.com`, `devforum.roblox.com`, `meshy.ai`, `tripo3d.ai`, `huggingface.co`, `figma.com`, `linear.app`, `notion.com`, `elevenlabs.io`, `docs.midjourney.com`, `docs.github.com`. No intenté esquivar el proxy.
- El límite de **200 búsquedas web por turno se agotó** antes de cubrir estos temas, que quedan **sin investigar**: precios y licencia de Adobe Firefly, Nano Banana/Gemini Image/Imagen, precios actuales de Figma/Notion/Linear, Mixamo y Rokoko, códigos de influencers o afiliados en Roblox, políticas de TikTok/YouTube sobre contenido de IA, y los "Audio Terms of Use" de Roblox.
- Los precios de terceros cambian cada pocas semanas y los comparadores suelen ser páginas de afiliados. **Todo precio de esta tabla debe revalidarse en la web oficial antes de pagar.**

---

## 2. Reglas técnicas y de plataforma de Roblox (lo que condiciona cualquier herramienta)

Todas las filas son **[OFICIAL]**, leídas el 2026-10-20 en el espejo GitHub de los docs, salvo que se indique otra cosa.

| Tema | Regla | Fuente |
|---|---|---|
| Triángulos por malla | "Individual meshes can not exceed **20,000 triangles**". Los items de avatar (cuerpos, accesorios rígidos y en capas) tienen presupuestos propios. Otras guías de terceros dicen 21.000 o 10.000 (lote): **conflicto, probar importando**. | [specifications.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/specifications.md) |
| Geometría | Malla estanca, sin huecos ni caras traseras expuestas, usar quads donde se pueda, con volumen real (no espesor cero). | idem |
| Rig y skinning | Transformaciones congeladas (escala 1,1,1; rotación 0,0,0), máximo 4 influencias de hueso por vértice, **una sola pista de animación por malla** en FBX. | idem |
| Texturas sueltas | Formatos `.png`, `.jpg`, `.tga`, `.bmp`. Máximo 4096x4096 en la sección de texturas básicas; **la misma página dice 1024x1024 en la sección UV/PBR**: contradicción interna, verificar. | [texture-specifications.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/texture-specifications.md) |
| PBR (SurfaceAppearance) | Albedo RGB 24-bit; Normal RGB 24-bit **OpenGL**; Roughness y Metalness en escala de grises de 8 bits; máscara emisiva de 8 bits. Un solo material y **un solo set de UV** por malla; UV dentro del espacio 0-1. Guía de tamaños: 1024x1024 máximo para ropa completa o humanoides; accesorios rígidos 256x256 máximo para mapas distintos del albedo. | idem |
| Exportar desde Blender | FBX recomendado. Path Mode = Copy y **Embed Textures** activado; Apply Scalings = FBX Unit Scale; desactivar Add Leaf Bones; desactivar Bake Animation salvo que haya animación. | [export-requirements.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/export-requirements.md) |
| glTF | Soportado en **beta**: mallas, texturas, color de vértice, rig/skinning, cages. **No exporta animación.** Solo se pueden exportar assets de tu propiedad o compartidos explícitamente. | [gltf-export.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/gltf-export.md) |
| Subida por API (Open Cloud Assets) | Modelos `.fbx`, `.gltf`, `.glb`, `.rbxm`, `.rbxmx` (se importan como Model con MeshParts, se suben como paquete). Imágenes `.png/.jpeg/.bmp/.tga` menores de 8000x8000. Audio `.mp3/.ogg/.wav/.flac`. Vídeo `.mp4/.mov` hasta 5 min. Endpoint `POST https://apis.roblox.com/assets/v1/assets` con cabecera `x-api-key`. | [usage-assets.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/usage-assets.md) |
| Icono del juego | Cuadrado, mínimo 512x512; se reduce a ~150x150 en algunos sitios; debe pasar moderación antes de verse. | [experience-icons.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/experience-icons.md) |
| Miniaturas | 16:9, ideal 1920x1080; `.jpg/.gif/.png/.tga/.bmp`; hasta 10 imágenes o vídeos por página; para personalización de portada, menos de 3 MB. Todo se modera. | [thumbnails.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/thumbnails.md) |
| Vídeo en miniaturas | Cuota gratuita de 3 subidas al mes (los rechazados también cuentan). Debe mostrar **juego real**. Prohibido: mecánicas que el juego no tiene, gráficos mejorados más allá de lo real, imágenes de la vida real, voz en off, música con letra, anuncios o afirmaciones subjetivas. Permitido: logos superpuestos, música del catálogo de Roblox, resaltados de mecánicas reales. | idem |
| Icono de game pass | Máximo **512x512**, `.jpg/.png/.bmp`. Se muestra en círculo: **lo importante debe quedar dentro del círculo**. | [passes.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/passes.md) |
| Icono de producto de desarrollador | Igual: 512x512 máximo, `.jpg/.png/.bmp`, círculo. Precio de 1 a 1.000 millones de Robux. Roblox recomienda un icono propio por producto. | [developer-products.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/developer-products.md) |
| Audio (formato) | Mono o estéreo 2.0/3.0/5.1; `.mp3/.ogg/.wav/.flac`; menos de **20 MB** y **7 minutos**; frecuencia de muestreo máxima 48 kHz. | [audio/assets.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/audio/assets.md) |
| Audio (derechos y cuota) | "You must have the legal rights to the audio". Cuota: **2.000 audios gratis cada 30 días con ID verificado, 100 sin verificar**. (La guía de Open Cloud dice 100 y 10 respectivamente: **conflicto interno entre páginas**, probablemente una está desactualizada.) | idem y [usage-assets.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/usage-assets.md) |
| Audio (privacidad y moderación) | Todo audio nuevo es **privado por defecto**, entra en una cola de moderación y se puede dar permiso a amigos y experiencias concretas. Se clasifica automáticamente como efecto de sonido o canción. | idem |
| Verificación de ID | Desbloquea distribuir audios de menos de 10 s, monetizar plugins y más cupo de assets. Requiere 13 años o más, documento oficial con foto y un móvil con cámara. | [account-verification.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/account-verification.md) |
| Propiedad intelectual | Roblox elimina contenido que infrinja derechos aunque no lo monetices ni des crédito. **El contenido modificado con IA puede seguir siendo denunciado** si reproduce la expresión protegida. Las cuentas reincidentes pueden ser suspendidas. | [ip-guidelines.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/ip-guidelines.md) |
| IA de terceros | Con herramientas de IA externas, **tú eres responsable de todo lo que ven los usuarios** (debe cumplir Community Standards y la clasificación de madurez). Las APIs de IA propias de Roblox moderan entradas y salidas. | [generative-AI.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/generative-AI.md) |
| Creator Store | Verificados: 200 mallas/imágenes/modelos y 100 audios por 30 días (regla de la sección del Creator Store, contexto de vendedores; sin verificar: 10). Los assets "Restricted" sin permiso no cargan. | [creator-store.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/creator-store.md) |
| Partículas (VFX) | Un emisor admite hasta **400 partículas/s (100 en móvil)**; vida máxima 20 s; texturas `.png` con transparencia; flipbooks Grid2x2/4x4/8x8 hasta 30 fps; probar en calidad mínima y máxima. | [particle-emitters.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/effects/particle-emitters.md) |

---

## 3. Modelado 3D con IA

### 3.1 Herramientas de Roblox dentro de Studio

| Herramienta | Qué hace | Precio / límites | Licencia | Calidad para Roblox | Recomendación | Fuente |
|---|---|---|---|---|---|---|
| **Roblox Assistant `/generate_mesh` y MCP `generate_mesh`** | Genera una malla con textura a partir de **texto o una imagen (no ambos a la vez)**. | Los docs **no indican precio** ni límite diario para mallas. Sí indican **50 modelos procedurales por ventana móvil de 24 h**. Un tercero dice triángulos máximos por defecto 10.000 [TERCERO]. | Los docs no tratan la propiedad de los resultados. Los términos de Roblox dicen que el creador es responsable de lo generado [TERCERO, resumen de WebSearch]. | Nativa: entra en Studio como MeshPart, sin pasar por importación. Calidad sin evaluar por mí. | **Usar** como primera opción para props sencillos; probar antes de pagar otra cosa. | [assistant/guide.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/assistant/guide.md) [OFICIAL], [mcp.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/mcp.md) [OFICIAL] |
| **Texture Generator de Studio** | Modo **Fast**: textura difusa 1K en menos de 30 s. Modo **Quality**: textura PBR 4K en un par de minutos, aplicada como `SurfaceAppearance`. | Los docs no mencionan coste. Un tercero informa de un "Quality Mode" en beta con anuncio del 2026-10-16 [TERCERO]. | idem | Sirve para dar aspecto a mallas propias. Ojo: **la API de publicación no actualiza SurfaceAppearance** (ver sección 8). | **Usar**, con la advertencia anterior. | [texture-generator.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/texture-generator.md) [OFICIAL] |
| **Material Generator, procedural models, Segment Any Mesh** | Material personalizado, modelos procedurales y partir una malla en hasta 5 partes (`/segment_mesh`). | El `/segment_mesh` y el Quality Mode solo los vi en terceros. | idem | Útil para modular y reutilizar. | **Usar** para variantes baratas. | [bloxbot.ai](https://bloxbot.ai/guide/roblox-ai-texture-generation-mesh-segmentation-2026) [TERCERO, 2026-10] |
| **Cube 3D (modelo abierto de Roblox)** | Genera formas 3D en `.obj` desde texto. | Gratis, pero con licencia **Research-Only RAIL-MS**: solo propósito académico o de investigación. | **No permite uso comercial.** | Sin textura final. | **Evitar** como pipeline comercial propio (usar la versión integrada en Studio). | [Roblox/cube LICENSE](https://github.com/Roblox/cube/blob/main/LICENSE) [OFICIAL] |

### 3.2 Servicios de texto/imagen a 3D de terceros

| Herramienta | Qué hace | Precio aprox. y plan gratis (fecha) | Licencia comercial | Calidad para Roblox | Recomendación | Fuente |
|---|---|---|---|---|---|---|
| **Meshy** (Meshy 6) | Texto/imagen a 3D con textura PBR, remallado y API. | Gratis: 100 créditos/mes. Pro **~20 USD/mes** (1.000 créditos). Otros niveles ~40, 60-70 y 100 USD; las fuentes discrepan. Una generación consume ~10-30 créditos. (Consulta 2026-10-20.) | **Gratis: CC BY 4.0, con atribución a Meshy.** De pago: licencia privada y uso comercial. Revisar términos oficiales. | Topología "cuadri-dominante" según el fabricante; los reseñadores dicen que requiere limpieza. Tiene tutoriales propios para Roblox. | **Usar con plan Pro** para prototipos y props estáticos. Probar la salida de decimado. | [costbench](https://costbench.com/software/ai-3d-generation/meshy/), [stacksheriff](https://stacksheriff.com/ai-tools/meshy-ai-pricing/) [TERCERO, 2026]; [Roblox UGC tutorial de Meshy](https://www.meshy.ai/tutorials/roblox-ugc-items) [TERCERO, fabricante] |
| **Tripo** | Texto/imagen a 3D, rigging automático, API. | Gratis: 200-300 créditos/mes (fuentes discrepan). Pro **~20 USD/mes** (3.000 créditos); Max ~90 USD; Team ~55 USD por asiento (media.io, revisado 2026-09). | **Conflicto**: un blog del propio Tripo dice que la capa gratis es CC BY 4.0 (atribución); otras fuentes dicen que es pública y no comercial. De pago: privada y comercial. | Considerada la opción barata para salida "lista para juego"; topología "borrador" para lo cercano. | **Usar con plan Pro**; comparar con Meshy un mes y quedarse con uno. | [media.io](https://www.media.io/comparison/tripo-ai-review.html), [Tripo blog](https://www.tripo3d.ai/blog/commercial-use-ai-3d-models), [costbench](https://costbench.com/software/ai-3d-generation/tripo-ai/) [TERCERO, 2026-05 a 2026-09] |
| **Rodin / Hyper3D (Deemos)** | Texto/imagen a 3D de alta calidad; pago por descarga. | Creador ~30 USD/mes; otras fuentes: 16/32/80 USD, API 400 USD; pago por descarga 0,5-1,5 USD; ~0,40 USD por generación vía fal.ai. Muy contradictorio. | Dicen que el plan Business incluye licencia comercial; **sin confirmar**. | Se cita como la mejor topología para personajes "hero" y rigging; cara para volumen. | **Probar** solo para activos clave. | [makerstack](https://makerstack.co/reviews/hyper3d-rodin-review/), [3dtoolwiki](https://3dtoolwiki.com/tools/rodin) [TERCERO] |
| **Hunyuan3D 2.1 (Tencent, pesos abiertos)** | Forma y textura locales; integrado en Blender MCP. | Gratis. Necesita ~10 GB de VRAM (forma), 21 GB (textura), 29 GB (ambas). | **La licencia define el "Territory" como todo el mundo excepto UE, Reino Unido y Corea del Sur.** Más de 1 millón de MAU requiere otra licencia. Prohíbe usar los outputs para mejorar otros modelos de IA. Tencent no reclama derechos sobre los outputs. Un resumen de terceros de la licencia (vía Hugging Face) añade que usar el modelo **o sus outputs fuera del Territory no está licenciado** [TERCERO]. | Calidad de forma buena; textura requiere GPU grande. | **Evitar si el usuario está en UE/UK/Corea**; en Latinoamérica, usable con cuidado. Aclarar con un abogado si "territorio" se refiere a dónde usas el modelo o a dónde juegan los jugadores. | [LICENSE oficial](https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1/blob/main/LICENSE), [README](https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1) [OFICIAL] |
| **TRELLIS.2 (Microsoft)** | Imagen a 3D con PBR (base, rugosidad, metalicidad, opacidad), exporta GLB. | Gratis. **Requiere GPU NVIDIA con al menos 24 GB**; probado en A100/H100 y solo en Linux. | **MIT** (algunas dependencias tienen su propia licencia). | Buena base para volumen si se alquila GPU; no medido por mí en Roblox. | **Usar** si se monta un pipeline propio en una GPU alquilada. | [microsoft/TRELLIS.2](https://github.com/microsoft/TRELLIS.2) [OFICIAL] |
| **TripoSR (VAST-AI)** | Imagen a 3D rápida, vertex colors o textura. | Gratis; ~6 GB de VRAM. | **MIT**. | Más antiguo y básico que TRELLIS.2. | **Opcional** para pruebas baratas. | [TripoSR](https://github.com/VAST-AI-Research/TripoSR) [OFICIAL] |
| **Luma Genie** | Texto a 3D. | Información contradictoria y de baja calidad (30-300 USD/mes). | Sin verificar. | Sin evidencia sólida de uso en 2026. | **Evitar** (no hay datos fiables). | [costbench](https://www.costbench.com/software/ai-3d-generation/luma-ai-3d/) [TERCERO/NO VERIFICADO] |

**Consenso de las reseñas (todas con posibles sesgos de afiliación)**: la topología de la IA va bien para **props estáticos** y mal para **personajes deformables** y piezas modulares exactas. [TERCERO: [3daistudio](https://www.3daistudio.com/3d-generator-ai-comparison-alternatives-guide/can-ai-generate-game-ready-3d-models), [indiehackers](https://www.indiehackers.com/post/best-ai-3d-model-generator-in-2026-i-tested-9-of-the-best-and-here-is-what-i-found-70ecab1a0a)]. No encontré pruebas con mediciones de triángulos ni de deformación.

### 3.3 Blender y su ecosistema

| Herramienta | Qué hace | Precio / licencia | Recomendación | Fuente |
|---|---|---|---|---|
| **Blender** | Limpieza, decimado, retopología, bakeo de texturas, rig y exportación FBX/glTF. | Gratis (GPL; los modelos que crees no quedan sujetos a la GPL) [NO VERIFICADO, conocimiento previo]. | **Usar** (imprescindible). | Los docs de Roblox nombran a Blender y Maya como herramientas de referencia: [modeling/index.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/index.md) [OFICIAL] |
| **Roblox Blender plugin** | Sube mallas o colecciones de Blender a Roblox por Open Cloud, como paquetes que se actualizan solos en Studio. | MIT. Requiere Blender 3.2 o superior. Es una implementación de referencia: solo acepta correcciones de errores, no funciones nuevas. | **Usar** para saltarse el export/import manual. | [roblox-blender-plugin](https://github.com/Roblox/roblox-blender-plugin) [OFICIAL] |
| **Blender MCP (ahujasid)** | Controla Blender desde un LLM (crear, modificar, materiales, ejecutar Python, render para comprobar). Integra Poly Haven, Sketchfab, Hyper3D Rodin, Hunyuan3D, Meshy, Tripo y Poly Pizza. | MIT. Blender 3.0+ y Python 3.10+. **Cuidado**: `execute_blender_code` ejecuta código arbitrario, el socket no tiene autenticación ni cifrado, y se recoge telemetría mínima por defecto (se desactiva con `DISABLE_TELEMETRY=true`). Los modelos de Poly Pizza suelen ser CC-BY (requieren crédito). | **Usar** con precaución y solo en localhost, guardando el trabajo antes. | [blender-mcp](https://github.com/ahujasid/blender-mcp) [OFICIAL] |
| **Servidor MCP de Studio (oficial)** | Deja que Claude Code lea y edite el lugar, ejecute Luau, haga playtests y genere mallas y materiales. | Integrado en Studio: Assistant, "Manage MCP Servers", "Enable Studio as MCP server". Solo local (stdio). Los docs no documentan límites de uso. | **Usar**. Conectar solo clientes de confianza. | [studio/mcp.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/mcp.md) [OFICIAL] |

**Cómo importar** (resumen verificado): FBX desde Blender con los ajustes de la sección 2, importar con el 3D Importer de Studio (se crean MeshParts; los nombres con sufijo `_Att`, `_OuterCage`, `_InnerCage` generan objetos automáticamente), o subir con la API Open Cloud / el plugin de Blender. [OFICIAL: [modeling/index.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/index.md)]

---

## 4. Imágenes: texturas, iconos de pases y productos, miniaturas y logos

### 4.1 Comparativa

| Herramienta | Precio aprox. y plan gratis (fecha) | Licencia comercial | Texto en imagen | Calidad para iconos y miniaturas | Recomendación | Fuente |
|---|---|---|---|---|---|---|
| **Ideogram** | Gratis limitado (generaciones **públicas**). De pago: Plus **~20 USD/mes**, Pro **~60 USD/mes**, Team ~30 USD por usuario (las fuentes discrepan; las más recientes, mayo-octubre 2026, coinciden en esto). Generación privada solo en planes de pago. | Varias fuentes dicen que Ideogram no reclama propiedad; la capa gratis es pública. Verificar términos. | **El mejor** según la mayoría de reseñas. | Muy bueno para logos, carteles y miniaturas con título. | **Usar** para miniaturas con texto y logos. | [eesel](https://eesel.ai/blog/ideogram-pricing), [costbench](https://costbench.com/software/ai-image-generators/ideogram) [TERCERO, 2026-10] |
| **gpt-image-2 (OpenAI)** | Facturación por tokens: ~8 USD/M de tokens de imagen de entrada y 30 USD/M de salida. A 1024x1024: ~0,006 / 0,053 / 0,211 USD por imagen en calidad baja/media/alta (revisado 2026-09-06). **Un calculador indica que gpt-image-1 se retira el 2026-10-23.** | Los términos de OpenAI no se comprobaron [NO VERIFICADO]. | Muy bueno, ligeramente por debajo de Ideogram en una reseña (8,2 contra 8,5). | Excelente instrucción-seguimiento; bueno para sprites y UI. Por API es barato y automatizable. | **Usar** por API para volumen. | [aifreeapi](https://www.aifreeapi.com/en/posts/openai-image-generation-api-pricing), [costgoat](https://costgoat.com/pricing/openai-images) [TERCERO, 2026-09 a 2026-10] |
| **Midjourney** | Basic 10, Standard 30, Pro 60, Mega 120 USD/mes (20% menos con pago anual). Sin plan gratis. | **Uso comercial en todos los planes de pago**; si la empresa o el empleado supera **1 millón USD/año de ingresos**, hace falta Pro o Mega. | **Flojo** (falla en cadenas de varias palabras, según un blog). | El mejor en estilo artístico para arte "hero" y fondos. | **Usar** (Standard) solo si se necesita estética premium. | [costbench](https://costbench.com/software/ai-image-generators/midjourney/), [eesel](https://www.eesel.ai/blog/midjourney-pricing) [TERCERO, 2026-09] |
| **Flux (Black Forest Labs)** | Pesos abiertos y API de pago (no encontré precios). | **FLUX.2 [dev]: licencia no comercial. FLUX.2 [klein] 4B: Apache 2.0. [klein] 9B: no comercial. [pro]/[flex]: alojados.** Si los outputs se pueden usar comercialmente no lo dice la página del repositorio [NO VERIFICADO]. | Flojo según reseñas. | Muy bueno en fotorrealismo y autohospedable. | **Usar solo klein 4B (Apache 2.0)** para generación local barata; lo demás exige licencia. | [black-forest-labs/flux2](https://github.com/black-forest-labs/flux2) [OFICIAL]; [layer3labs](https://www.layer3labs.io/guides/flux-explained) [TERCERO] |
| **Recraft** | Gratis con créditos diarios (30-50), **sin licencia comercial**. De pago: Basic ~10-12,5 USD/mes. Vector cuesta 2 créditos, ráster 1. | Licencia comercial **solo en planes de pago**. | Aceptable. | Su punto fuerte son los **vectores e iconos** con estilo coherente. | **Usar** (plan Basic) para sets de iconos. | [eesel](https://www.eesel.ai/blog/recraft-ai-pricing), [dailyaifixs](https://dailyaifixs.com/blog/recraft-pricing-2026-free-has-no-license) [TERCERO, 2026] |
| **Leonardo AI** | Gratis: 150 tokens/día (generaciones públicas). De pago: 12 / 30 / 60 USD/mes (8.500 / 25.000 / 60.000 tokens). | **Conflicto**: unas fuentes dicen uso comercial incluso en gratis; otras dicen que en gratis Leonardo conserva los derechos y en pago eres el dueño. | Medio. | Bueno para sprites, personajes y texturas con modelos entrenados. | **Opcional**; leer sus términos antes de usarlo comercialmente en gratis. | [krea.ai](https://www.krea.ai/blog/leonardo-ai-review-is-it-free-any-good-and-how-it-compares-in-2026), [fluxnote](https://fluxnote.io/guides/leonardo-ai-pricing-guide-2026) [TERCERO, 2026] |
| **Adobe Firefly** | **No investigado** (presupuesto de búsquedas agotado). | Se promociona como "comercialmente segura" [NO VERIFICADO]. | Sin datos. | Sin datos. | **Pendiente de verificar.** | n/d |
| **Nano Banana / Gemini Image / Imagen** | **No investigado.** | Sin datos. | Sin datos. | Sin datos. | **Pendiente de verificar.** | n/d |

### 4.2 Consejos prácticos (derivados de las reglas oficiales)

- **Iconos de pases y productos**: genera en 1024x1024 sin texto, reduce a **512x512** y comprueba que el sujeto cabe dentro del **círculo**. Revisa también a ~150x150 para el icono del juego [OFICIAL: passes.md, developer-products.md, experience-icons.md].
- **Texto**: en iconos pequeños casi no se lee; para miniaturas, añade el título después con Figma o un editor (ortografía exacta y localización a varios idiomas). Ideogram o gpt-image-2 son opciones si necesitas texto generado.
- **Texturas de superficie y materiales**: preferir el **Material Generator y el Texture Generator de Studio** (se integran como SurfaceAppearance). Fuera de Roblox, TRELLIS.2 genera mapas PBR junto con la malla.
- **Moderación**: todo icono y miniatura se modera; antes de verse hay espera. Evitar personajes o marcas de terceros: Roblox puede eliminar contenido que infrinja aunque lo haya generado una IA [OFICIAL: ip-guidelines.md].
- **Propiedad del resultado**: según un artículo de terceros, la Oficina de Derechos de Autor de EE. UU. no protege el contenido generado solo por IA. Si esto es correcto, sería difícil impedir que otros copien tus iconos [TERCERO: [promise.legal](https://blog.promise.legal/ai-generated-music-copyright-ownership/), resumen de WebSearch; tema de música, extrapolado].
- **Ads Manager de Roblox** ofrece "AI generate": tres variantes de miniatura desde una descripción de texto [OFICIAL: [ads-manager.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/ads-manager.md)].

---

## 5. Audio: música y SFX

| Herramienta | Qué hace | Precio aprox. y plan gratis (fecha) | Licencia comercial | Calidad / riesgo para Roblox | Recomendación | Fuente |
|---|---|---|---|---|---|---|
| **Creator Store (Roblox)** | Más de **100.000** SFX y pistas de música gratis. | Gratis. | Se pueden usar y distribuir los assets gratuitos. | Riesgo mínimo de reclamación; variedad limitada y los mismos sonidos que usan otros juegos. | **Usar primero.** | [audio/assets.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/audio/assets.md), [creator-store.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/creator-store.md) [OFICIAL] |
| **Suno** | Canciones completas con voz. | Pro **~10 USD/mes** (8 anual), Premier **~30 USD/mes** (24 anual) (revisado 2026-07 a 2026-10). Gratis: sin derechos comerciales. Un tercero dice que los derechos comerciales dependen de descargas mensuales (20 en Pro, 60 en Premier); **sin confirmar**. | Pro y Premier incluyen licencia comercial, pero tras el acuerdo con Warner (2025-11) las condiciones habrían cambiado de "propiedad" a "licencia" [TERCERO]. Demanda de la RIAA aún abierta. | **Riesgo de copyright y de reclamaciones**: un hilo del DevForum de 2025 describe audio hecho con Suno de pago que Roblox seguía eliminando; sin resolución visible. Hay planes de marca de agua y huella digital en Suno. | **Usar con cautela**, solo para música de fondo, y subir una pista de prueba antes de depender de ella. | [lumimusic](https://lumimusic.ai/blog/suno-pricing), [rinzara](https://rinzara.com/suno-pricing), [DevForum](https://devforum.roblox.com/t/uploading-music-i-own-the-license-for-but-getting-taken-down/3638155) [TERCERO] |
| **Udio** | Canciones con IA. | **Descargas desactivadas** desde el acuerdo con UMG (finales de 2025) y aún off en 2026-09. | Los derechos de planes de pago son contradictorios. | Sin exportación no sirve para subir a Roblox. | **Evitar.** | [undetectr](https://undetectr.com/blog/udio-download), [aitools-directory](https://www.aitools-directory.com/blog/udio-ai-review-2026/) [TERCERO, 2026-09] |
| **ElevenLabs** (SFX, Eleven Music) | SFX por texto, música, voces. | Gratis: 10.000 créditos/mes (sin uso comercial). **Starter ~6 USD/mes** (30.000 créditos), Creator ~22, Pro ~99. API de música ~0,15 USD/min y SFX ~0,12 USD/min (página antigua). | Uso comercial desde Starter. Un tercero dice que los planes autoservicio **excluyen cine, TV y "Studio Games"**: no sé qué significa para juegos de Roblox; **aclarar con ElevenLabs**. Los términos de SFX no aparecen en las fuentes. | SFX y música cortas muy usados por desarrolladores de Roblox según el DevForum. | **Usar** (Starter) para SFX tras confirmar la licencia. | [promptsrush](https://promptsrush.com/blog/elevenlabs-pricing-starter-creator-pro), [ampm-aiops](https://ampm-aiops.com/en/guides/eleven-music-free-vs-paid-commercial-2026/) [TERCERO, 2026] |
| **Stable Audio** (Open / 2.5) | Audio y música; Open (pesos abiertos); 2.5 comercial vía API/empresa. | Open: gratis. | **Stability Community License: uso comercial hasta 1 millón USD de ingresos anuales** (según Stability, vía WebSearch); 2.5 "comercialmente segura", entrenada con datos licenciados. No encontré los términos 2026 de 2.5. | Open fue entrenado con Freesound y FMA (Creative Commons). | **Opcional** para SFX locales; verificar términos. | [Stability](https://stability.ai/news/stable-audio-open-research-paper), [MBW](https://www.musicbusinessworldwide.com/stability-ai-launches-ai-model-for-brands-to-create-custom-sounds) [TERCERO] |
| **AudioCraft / MusicGen (Meta)** | Música y SFX locales. | Código MIT; **pesos CC-BY-NC 4.0**. | **No comercial** (los pesos). | No sirve para juegos con microtransacciones. | **Evitar.** | [facebookresearch/audiocraft](https://github.com/facebookresearch/audiocraft) [OFICIAL] |
| **Herramientas de terceros para Roblox** (Sonilo, ForgeGUI, Audioscape) | Generan música/SFX a partir de vídeo o texto, con plugin. | Sin precios fiables. Audioscape es una beta antigua (~1.100 días). | Sin verificar; el propio vendedor avisa de que los archivos igual deben pasar por importación y moderación de Roblox, y de no incluir una clave de API reutilizable dentro del juego. | Sin evaluar. | **Evitar por ahora** (poca evidencia). | [DevForum Sonilo](https://devforum.roblox.com/t/generate-music-sound-effects-from-gameplay-videos-using-sonilo/4886492), [ForgeGUI](https://devforum.roblox.com/t/forgegui-generate-game-music-soundtracks-and-sfx-with-ai-for-roblox-games-feature/4734570) [TERCERO] |

### Reglas y riesgos de audio en Roblox
- **Derechos**: Roblox exige tener los derechos legales del audio; el contenido infractor se elimina y las cuentas reincidentes pueden suspenderse [OFICIAL: audio/assets.md, ip-guidelines.md].
- **Cuotas y verificación**: 2.000 importaciones cada 30 días con ID verificado y 100 sin verificar (docs de audio), con la contradicción ya citada (100 y 10 en la guía de Open Cloud).
- **Efecto vs canción**: Roblox clasifica solo. Los efectos no salen en la página de detalles del juego; las canciones pueden salir si cumplen criterios (verificación de ID y aceptar los Audio Terms of Use). Los audios de menos de 10 s para distribución pública requieren ID verificado [OFICIAL: audio/assets.md, account-verification.md].
- **Política sobre audio generado por IA**: los docs de audio de Roblox **no tienen reglas específicas para IA**; esta página solo advierte que algunas herramientas antiguas producen archivos inválidos [OFICIAL]. No encontré una política oficial de Roblox sobre música de Suno u otras IA [TERCERO: resumen de WebSearch].
- **Riesgo legal más amplio**: la demanda de la RIAA contra Suno sigue en los tribunales (un juzgado denegó una moción para desestimar, 2026-09-28) [TERCERO: [minnlawyer](https://minnlawyer.com/2026/09/28/us-district-court-denies-motion-to-dismiss-copyright-claims-suno/)].

---

## 6. Animación, VFX y UI

### 6.1 Animación

| Herramienta | Qué hace | Precio aprox. (fecha) | Licencia comercial | Calidad para Roblox | Recomendación | Fuente |
|---|---|---|---|---|---|---|
| **Animation Editor de Roblox** | Keyframes en rigs con Motor6D; publica animaciones; editor de curvas, IK, prioridades (7 niveles). | Gratis. | Animaciones propias, usables en cualquier juego. | Nativo; 30 fps por defecto. | **Usar** como base. | [animation/editor.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/animation/editor.md) [OFICIAL] |
| **Animation Capture (cuerpo)** de Roblox | Genera keyframes R15 a partir de un vídeo. | Los docs no mencionan coste ni cuotas. | Debe cumplir Community Rules. | **Solo R15**, `.mp4`/`.mov`, **menos de 15 s**, una sola persona, plano continuo con cámara estable; tarda ~1 minuto. | **Usar** para animaciones sencillas de personaje. | [animation/capture.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/animation/capture.md) [OFICIAL] |
| **Animation Capture (cara)** de Roblox | Captura facial por webcam, hasta 60 s. | idem | Requiere consentimiento para recoger movimientos faciales. | Solo con cabezas dinámicas compatibles. | **Usar** si se usan avatares con cabeza dinámica. | idem [OFICIAL] |
| **Moon Animator 2** | Plugin para cinemáticas y cámara. | ~**29,99 USD** en el Creator Store según un tercero (listados antiguos mostraban Robux). | Compra de plugin. | Más útil para cinemáticas que para animar personajes. | **Opcional.** Desconfiar de versiones "gratis" de terceros (riesgo de código malicioso). | [thetoolstrunk](https://thetoolstrunk.com/how-much-is-moon-animator/), [DevForum](https://devforum.roblox.com/t/is-moon-animator-worth-it/2477738) [TERCERO] |
| **Cascadeur** | Animación asistida con física. | Gratis (no comercial, solo `.casc`). Indie ~**8 USD/mes anual** o 19 mensual (añade FBX/DAE, para estudios bajo 100.000 USD de ingresos). Pro ~33 anual o 49 mensual. Precios discrepan entre fuentes. | Comercial solo en planes de pago. | Buena para animaciones pulidas que se exportan por FBX. Recordar: **una pista de animación por malla** en el FBX que se importa a Roblox. | **Usar** (Indie) si se necesitan animaciones propias de calidad. | [aicentralresources](https://www.aicentralresources.com/compare/deepmotion-vs-cascadeur), [tasarim.ai](https://tasarim.ai/en/alternatives/cascadeur) [TERCERO, 2026-08] |
| **DeepMotion (Animate 3D)** | Vídeo a animación 3D; tiene integración para Roblox. | Gratis: 60 s/mes sin uso comercial. De pago: desde ~9 a 300 USD/mes (muy contradictorio). | Comercial en planes de pago. | Sin evaluar. | **Opcional** (la captura de Roblox cubre lo básico). | [DeepMotion Roblox](https://www.deepmotion.com/companion-tools/roblox) [TERCERO, fabricante] |
| **Plask Motion** | Vídeo a animación en navegador. | Gratis con segundos diarios; entrada de pago ~18 USD/mes anual (10 min/mes). | Términos comerciales poco claros. | Sin evaluar. | **Evitar** hasta aclarar la licencia. | [topai.tools](https://topai.tools/compare/deepmotion-vs-plask) [TERCERO] |
| **NoCapMocap** | Texto o vídeo a animación R15; plugin gratis "Motion Lab" en Studio. | Sin precios verificados. | Sin verificar. | Sin evaluar; es material de marketing del fabricante. | **No recomendable aún.** | [nocapmocap.com](https://www.nocapmocap.com/roblox) [TERCERO, fabricante] |
| **Rokoko, Mixamo** | **No investigados.** | n/d | n/d | n/d | **Pendiente de verificar.** | n/d |

No encontré ninguna función oficial de Roblox de "texto a animación" [TERCERO: resumen de WebSearch].

### 6.2 VFX

- **ParticleEmitter, Beam, Trail y luces** son nativos [OFICIAL: [effects/](https://github.com/Roblox/creator-docs/tree/main/content/en-us/effects)]. Reglas clave: máximo 400 partículas/s por emisor (100 en móvil), vida máxima 20 s, texturas `.png` con transparencia, flipbooks hasta 8x8 a 30 fps, y probar en calidad de editor mínima y máxima [OFICIAL: particle-emitters.md].
- Para producir en volumen, conviene una **biblioteca propia de 20-30 efectos reutilizables** (chispas, monedas, aura, nivel up) en un paquete compartido (Wally) y usarla en todos los juegos [recomendación propia].
- Texturas de partículas y sprites se pueden generar con gpt-image-2 o Recraft y limpiar fondo; **verificar siempre el resultado en móvil**.

### 6.3 UI

| Herramienta | Qué hace | Precio / licencia | Recomendación | Fuente |
|---|---|---|---|---|
| **UI nativa de Roblox** | Layouts de lista/rejilla/flex, 9-slice, animación, texto enriquecido, contenedores en pantalla. | Gratis. | **Usar** como base; el 9-slice y los layouts reducen la cantidad de imágenes. | [ui/](https://github.com/Roblox/creator-docs/tree/main/content/en-us/ui) [OFICIAL] |
| **react-lua (Roblox) + Rojo** | UI declarativa en Luau; Roact quedó obsoleto. | Código abierto. | **Opcional** si hay tiempo; mejora la reutilización entre juegos. | [DevForum "How To: React + Roblox"](https://devforum.roblox.com/t/how-to-react-roblox/2964543) [TERCERO] |
| **Figma** | Diseño de UI, iconos y miniaturas. | **Precio actual no verificado**; existe un plan gratis (Starter) [NO VERIFICADO, conocimiento previo]. Los MCP de Figma fallaron al conectarse en esta sesión (proxy 403). | **Usar** el plan gratis para kits de UI y composición de miniaturas. | n/d |
| **GuiForge** (editor de UI + importador de Figma) | Exporta un script Luau que construye la UI. | Proyecto comunitario; estado sin verificar. | **Opcional.** | [DevForum](https://devforum.roblox.com/t/guiforge-roblox-ui-editorfigma-export/4834077) [TERCERO] |

No encontré un plugin oficial de Figma a Roblox ni un kit de UI oficial de 2026.

---

## 7. Marketing, vídeo y analítica

### 7.1 Vídeo corto para TikTok y YouTube Shorts

| Herramienta | Qué hace | Precio aprox. y plan gratis (fecha) | Licencia comercial | Recomendación | Fuente |
|---|---|---|---|---|---|
| **Captura de gameplay propio + CapCut** | Edición de clips con el propio juego. | CapCut: Pro/Standard ~9,99-19,99 USD/mes (el precio se fija en la app y varía; Pro ~179,99 USD/año). | **La versión gratis cubre solo cuentas personales de redes sociales**; Pro quita esa restricción. | **Usar** (gratis para empezar). El footage de tu propio juego es el mejor contenido y no cuesta nada. | [vidpros](https://vidpros.com/capcut-pro-vs-free/), [bigvu](https://www.bigvu.tv/blog/capcut-pricing-2026-free-vs-pro-included-alternatives) [TERCERO, 2026] |
| **Runway** | Vídeo generativo y edición con IA. | Standard ~15, Pro ~35, Max ~95 USD/mes. Un tercero afirma que su plan gratis (125 créditos, una sola vez) permite uso comercial: **raro, verificar**. | De pago: comercial. | **Opcional** para tráilers estilizados o anuncios; no para la página del juego (ver reglas). | [higgsfield](https://higgsfield.ai/blog/best-ai-video-generators-2026) [TERCERO, 2026] |
| **Google Veo 3.1** | Vídeo con audio, facturado por segundo. | ~0,03 a 0,40 USD/s según calidad y audio (las fuentes discrepan). | Verificar términos. | **Opcional.** | [fluxnote](https://fluxnote.io/guides/ai-video-model-pricing-comparison-2026) [TERCERO] |
| **Kling** | Vídeo generativo barato. | ~7-10 USD/mes de entrada. Gratis: no comercial. | Es un derecho de uso, no propiedad total; revisar. | **Opcional.** | idem [TERCERO] |
| **Sora (OpenAI)** | Vídeo generativo. | Según terceros, la app cerró el 2026-04-26 y la API termina el 2026-09-24. | n/d | **No disponible**: no planificar con él. | [techietory](https://techietory.com/best-ai-video-generators-2026/) [TERCERO] |
| **Seedance** | Vídeo generativo. | API entre ~0,03 y 0,23 USD/s según la fuente. | Sin verificar. | **Opcional / sin datos fiables.** | [guptadeepak](https://guptadeepak.com/tools/top-5-ai-video-generation-tools-2026/) [TERCERO] |

**Reglas de Roblox para vídeo y promoción**
- Los vídeos de la **página del juego** deben ser de **juego real** (sin voz en off, sin música con letra, sin anuncios). Cuota gratuita de 3 al mes [OFICIAL: thumbnails.md].
- Una promoción **fuera de Roblox** (por ejemplo TikTok con influencers de pago) cae bajo la "Independent Advertising Policy": hay que **declarar claramente que es publicidad**, no copiar los avisos oficiales de Roblox y ocultar el anuncio a usuarios no elegibles. Tú eres responsable del cumplimiento y de las leyes locales [OFICIAL: [advertise-on-roblox.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/advertise-on-roblox.md), [comply-with-advertising-standards.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/comply-with-advertising-standards.md)].
- **Enlaces sociales** (YouTube, Discord, Twitch, X, etc.) hasta 3 por juego, solo visibles para mayores de 16 verificados; **no se puede escribir la URL ni el invite de Discord dentro del juego** [OFICIAL: [social-media-links.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/social-media-links.md)].
- Mi observación: no encontré las reglas de TikTok o YouTube sobre contenido de IA ni sobre música en Shorts [NO VERIFICADO]; revisar antes de publicar con volumen.

### 7.2 Anuncios de Roblox (Ads Manager)

| Dato | Valor | Fuente |
|---|---|---|
| Tipos de anuncio | Immersive ads, Search ads, Sponsored games, Sponsored items. | [advertise-on-roblox.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/advertise-on-roblox.md) [OFICIAL] |
| Objetivos | Plays, Earnings (limitado), Engagement. Audiencias: todos, nuevos, recientes (10.000+), inactivos (20.000+). | [ads-manager.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/ads-manager.md) [OFICIAL] |
| Presupuesto mínimo | La página **no indica un mínimo de campaña**; la compra mínima es de 1 crédito. Un anuncio de 2023 del DevForum decía 10 créditos (5 al día durante 2 días), y un blog de 2026 sugiere unos 35 USD de mínimo: **conflicto; comprobar en el Creator Hub**. | idem [OFICIAL]; [DevForum](https://devforum.roblox.com/t/sponsored-experiences-moving-to-ads-manager/2661756), [bloxg](https://bloxg.com/guides/roblox-ads-guide) [TERCERO] |
| Requisitos | 13 años o más y correo verificado; pago con tarjeta solo para mayores de 18; convertir Robux en créditos de anuncio es **irreversible**. Cobro inicial de 5 USD en el primer pago con tarjeta. | idem [OFICIAL] |
| Creativos | Hasta 10 miniaturas por campaña (16:9); moderación de campaña hasta 24 h y de assets hasta 48 h. | idem [OFICIAL] |
| Sistema de referidos | Banners de recompensa configurables en Engagement > Referral Rewards; solo un banner publicado a la vez. | [referral-system.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/referral-system.md) [OFICIAL] |
| Códigos de influencers/afiliados | **No investigado.** No sé si Roblox ofrece un sistema oficial; la alternativa es implementarlo con códigos propios (ver dudas abiertas). | n/d |

### 7.3 Analítica e investigación de mercado

| Herramienta | Qué hace | Precio / licencia | Recomendación | Fuente |
|---|---|---|---|---|
| **Roblox Creator Analytics** | Paneles de adquisición, retención, monetización, rendimiento, demografía, embudos, eventos personalizados, alertas y paneles personalizados. | Gratis, integrado. | **Usar.** | [production/analytics/](https://github.com/Roblox/creator-docs/tree/main/content/en-us/production/analytics) [OFICIAL] |
| **Analytics Query API (Open Cloud)** | Consulta DAU, ingresos, retención, conversión de pagadores y embudos, con desgloses por plataforma, país y edad. Clave con `universe.analytics:read`. Métricas estándar hasta 4 años; rendimiento 28 días. | Gratis. | **Usar** para un panel único de todo el portafolio. | [analytics/index.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/analytics/index.md) [OFICIAL] |
| **RoMonitor Stats** | Extensión de navegador con estadísticas, hitos e ingresos estimados en páginas de juego. | Gratis según una guía de 2026. | **Usar** para vigilar a la competencia (CCU, visitas). | [lensblox](https://lensblox.com/blog/best-roblox-game-analytics-tools-compared-2026-guide/) [TERCERO, 2026] |
| **Rolimon's Game Analytics** | Gráficos de juego, seguimiento de game passes y badges; escaneo cada ~10 minutos. | Gratis. | **Usar** para investigar el mercado. | [DevForum](https://devforum.roblox.com/t/rolimons-game-analytics-free-statistics-for-roblox-games/491663), [lensblox](https://lensblox.com/blog/best-roblox-game-analytics-tools-compared-2026-guide/) [TERCERO] |
| **RoLearn, CCUCheck, GGAID** | Previsión de ingresos, exportación de datos y gráficos de catálogo. | Gratis con niveles de pago; sin precios. Según la misma guía, Rotrends se está cerrando. | **Opcional.** | lensblox [TERCERO] |
| **Datos de audiencia de Roblox** | Más usuarios de 13 años o más que menores de 13; EE. UU., Reino Unido y Canadá siguen siendo las regiones más grandes; Europa y APAC crecen. Gráficos de DAU de 2022 (sin cifras en el texto). | n/d | Útil para decidir idioma y estilo. | [roblox-user-base.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/roblox-user-base.md) [OFICIAL] |

Nota: los datos de RoMonitor y Rolimon's son estimaciones de terceros; usar los paneles oficiales para decisiones de dinero.

---

## 8. Productividad, plantillas y automatización (GitHub, Open Cloud, Figma, Notion, Linear)

### 8.1 Herramientas

| Herramienta | Qué hace | Precio y licencia | Recomendación | Fuente |
|---|---|---|---|---|
| **GitHub (Free)** | Repos públicos y privados ilimitados, Issues, Projects, **2.000 minutos de Actions al mes en repos privados**, 500 MB de Packages. Team 4 USD/usuario (3.000 min), Enterprise 21 USD/usuario (50.000 min). | Precios de la página oficial, 2026-10-20. | **Usar.** Con Issues y Projects no hace falta Notion ni Linear al principio. | [github.com/pricing](https://github.com/pricing) [OFICIAL] |
| **Open Cloud: publicar lugar** | `POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published` con `x-api-key`, cuerpo `.rbxl` (`application/octet-stream`) o `.rbxlx` (`application/xml`). La clave necesita el permiso `universe-places` con operación Write. **Límite documentado: la API no actualiza `EditableImage`, `EditableMesh`, `PartOperation`, `SurfaceAppearance` ni `BaseWrap`; en esos casos hay que publicar desde Studio.** No indica límites de tamaño ni de frecuencia. | Gratis. | **Usar**, pero **probar pronto** si el límite sigue vigente con texturas PBR. | [usage-place-publishing.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/usage-place-publishing.md) [OFICIAL] |
| **Open Cloud: subir assets** | Create Asset / Update Asset (un asset por llamada), con consulta de operación asíncrona. Soporta audio, imágenes, modelos y vídeo. | Gratis. | **Usar** para subir lotes de assets desde un script. | [usage-assets.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/usage-assets.md) [OFICIAL] |
| **Rojo** | Edita scripts y modelos desde archivos, versiona con Git y construye/despliega desde la línea de comandos. | MPL-2.0. | **Usar.** | [rojo-rbx/rojo](https://github.com/rojo-rbx/rojo) [OFICIAL] |
| **Wally** | Gestor de paquetes (como Cargo/npm) con `wally.toml` y `wally.lock`. | MPL-2.0. | **Usar** para compartir código y VFX entre juegos. | [UpliftGames/wally](https://github.com/UpliftGames/wally) [OFICIAL] |
| **rbxcloud (Sleitnick)** | CLI y biblioteca en Rust para Open Cloud (assets, DataStores, mensajería, publicación de lugares y algunas APIs v2). Versión 0.17.0. | MIT. | **Opcional**; la publicación también se puede hacer con `curl`. | [Sleitnick/rbxcloud](https://github.com/Sleitnick/rbxcloud) [OFICIAL] |
| **Acciones de GitHub Marketplace para Roblox** | Existen "Setup Rojo", "upload-to-roblox", "Update Roblox Asset", "Roblox Luau Execution via Open Cloud", "rblxsync" y otras. | Terceros; auditar antes de usar. | **Opcional.** Preferir un `curl` propio y simple. | [Marketplace](https://github.com/marketplace?query=roblox&type=actions) [TERCERO, 2026-10-20] |
| **Assistant Skills** | Archivos Markdown que enseñan a Assistant tus convenciones y rutinas (nombres, formato). | Gratis; ligados a la cuenta. | **Usar** para convenciones comunes entre juegos. | [assistant/skills.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/assistant/skills.md) [OFICIAL] |
| **Figma, Notion, Linear** | Diseño, documentación y tickets. | **Precios no verificados** (WebFetch bloqueado y sin búsquedas). Los conectores MCP de Notion, Linear y Figma fallaron en esta sesión (proxy 403). | **Pendiente de verificar.** Empezar con GitHub Issues/Projects. | n/d |

### 8.2 Plantilla de proyecto para un portafolio de muchos juegos (recomendación propia)

1. **Repositorio plantilla** (`roblox-game-template`) con: proyecto Rojo, `wally.toml`, carpeta `assets/` (fuentes en Blender y exportaciones), carpeta `store/` (iconos de pases/productos y miniaturas con los tamaños de la sección 2), `CHANGELOG`, y un flujo de GitHub Actions de publicación.
2. **Un repo por juego**, creado desde la plantilla. Los paquetes comunes (economía, tienda, VFX, UI) se instalan con Wally.
3. **Un tablero único** (GitHub Projects) con una columna por juego, o un campo "juego" por tarjeta.
4. **Claves de Open Cloud** guardadas como secretos de GitHub (una clave por universo, con el mínimo permiso).
5. **Panel único de analítica** con un script que llame a la Analytics Query API por cada universo.

### 8.3 Esquema de publicación (ilustrativo, **no probado**)

```yaml
# .github/workflows/publish.yml
name: Publish
on:
  push:
    tags: ["v*"]
jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # Instalar Rojo (por ejemplo con Rokit o la acción "Setup Rojo")
      - run: rojo build default.project.json --output game.rbxl
      - run: >
          curl --silent --fail --show-error --request POST
          --header "x-api-key: ${{ secrets.ROBLOX_API_KEY }}"
          --header "Content-Type: application/octet-stream"
          --data-binary @game.rbxl
          "https://apis.roblox.com/universes/v1/${{ secrets.UNIVERSE_ID }}/places/${{ secrets.PLACE_ID }}/versions?versionType=Published"
```

El endpoint, las cabeceras y el permiso de la clave salen de la documentación oficial; el resto (acciones, comando de Rojo, estructura) es un esquema mío sin ejecutar.

---

## 9. Flujo de producción propuesto para volumen (recomendación propia)

| Paso | Qué se hace | Herramienta | Verificaciones oficiales |
|---|---|---|---|
| 1. Concepto | Prompt de estilo único para todo el portafolio y un "style guide" corto. | gpt-image-2 por API / Ideogram | Evitar IP de terceros. |
| 2. Props 3D | Imagen a 3D, o `generate_mesh` dentro de Studio. | Studio Assistant, Tripo/Meshy Pro, TRELLIS.2 | Revisar la licencia del servicio. |
| 3. Limpieza | Decimar bajo 20.000 triángulos (mejor muy por debajo), comprobar estanqueidad, un solo material y un solo UV, bakear texturas. | Blender (+ Blender MCP) | Reglas de `specifications.md`. |
| 4. Exportar | FBX con Embed Textures y FBX Unit Scale. | Blender | `export-requirements.md`. |
| 5. Subir | Plugin de Roblox para Blender, importador de Studio o API Open Cloud. | Roblox Blender plugin / API | Lote de `usage-assets.md`. |
| 6. Texturas finas | Texture Generator o texturas bakeadas. | Studio | Cuidado con SurfaceAppearance y la API de publicación. |
| 7. Iconos de tienda | Generar sin texto, 512x512, centrado en el círculo. | Recraft / gpt-image-2 + Figma | `passes.md`, `developer-products.md`. |
| 8. Audio | Creator Store primero; IA solo si hay licencia clara. | Creator Store, ElevenLabs | `audio/assets.md`. |
| 9. Animación | Animation Capture (R15) y Animation Editor. | Roblox | `capture.md`. |
| 10. Publicación | CI con Open Cloud. | GitHub Actions | `usage-place-publishing.md`. |
| 11. Marketing | Clips del propio juego con CapCut, miniaturas con título. | CapCut, Ideogram | `thumbnails.md`, política de publicidad independiente. |
| 12. Analítica | Panel por juego y comparación con la competencia. | Creator Analytics + API, RoMonitor/Rolimon's | n/a |

---

## 10. Stacks propuestos

Los costes son una suma **mía** de precios de terceros del 2026-10-20 (sección 3 a 8); varían y deben revalidarse.

### 10.1 Stack mínimo barato (≈ 0 a 40 USD/mes)

| Área | Herramienta | Coste aprox. |
|---|---|---|
| 3D | Roblox Assistant (`generate_mesh`, Material/Texture Generator) + Blender + Roblox Blender plugin + Blender MCP | 0 |
| 3D opcional | Tripo o Meshy Pro **solo cuando haga falta**, un mes cada vez | 0-20 |
| Imágenes | gpt-image-2 por API (pago por uso, ~0,05 USD/imagen en calidad media) o Recraft Basic | ~5-12 |
| Iconos y miniaturas | Figma (plan gratis) para recortar a 512x512 y añadir texto | 0 (sin verificar) |
| Audio | Creator Store (más de 100.000 SFX y música) + ElevenLabs Starter solo si hace falta | 0-6 |
| Animación | Animation Editor + Animation Capture de Roblox | 0 |
| VFX | ParticleEmitter nativo + paquete propio en Wally | 0 |
| Marketing | Gameplay propio + CapCut (gratis) + Roblox Ads Manager (presupuesto aparte) | 0 |
| Analítica | Creator Analytics + Analytics Query API + RoMonitor/Rolimon's | 0 |
| Automatización | GitHub Free (2.000 min), Rojo, Wally, Open Cloud con `curl` | 0 |
| **Total herramientas** | | **≈ 0 a 40 USD/mes** |

Cuidado con el modelo gratis de Meshy/Tripo: **no usar la capa gratis en juegos comerciales** (atribución o no comercial, según la fuente).

### 10.2 Stack recomendado (≈ 150 a 170 USD/mes)

| Área | Herramienta | Coste aprox. |
|---|---|---|
| 3D | Tripo Pro **o** Meshy Pro (probar ambos un mes; quedarse con uno) | 20 |
| 3D local (opcional) | TRELLIS.2 en una GPU alquilada (coste no verificado) | n/d |
| Imágenes | Ideogram Plus (texto y logos) | ~20 |
| Imágenes | Midjourney Standard (arte hero y fondos) | ~30 |
| Imágenes | gpt-image-2 por API (volumen) | ~10 |
| Iconos vectoriales | Recraft Basic | ~10-12 |
| Audio | ElevenLabs Creator (SFX y música, tras confirmar licencia de juegos) | ~22 |
| Audio opcional | Suno Pro (solo música de fondo; riesgo de reclamaciones) | ~10 |
| Animación | Cascadeur Indie | ~8-19 |
| Marketing | CapCut Pro | ~20 |
| Marketing | Runway Standard (anuncios y tráilers) | ~15 |
| Productividad | GitHub Free (o Team a 4 USD/usuario) + Figma + tablero GitHub Projects | 0-4 |
| **Total aproximado** | | **≈ 150 a 170 USD/mes** |

---

## 11. Riesgos y reglas que más pueden doler

| Riesgo | Detalle | Mitigación |
|---|---|---|
| Licencia de 3D | Hunyuan3D excluye UE/UK/Corea. Cube 3D abierto es solo investigación. Las capas gratis de Meshy/Tripo imponen atribución o prohíben el uso comercial. | Pagar el plan Pro; guardar capturas de los términos de la fecha de contratación. |
| Copyright de audio | Roblox exige derechos; Suno tiene litigios; un hilo de 2025 describe audio de Suno que seguía eliminándose. | Preferir Creator Store; probar con un único audio antes de basar un juego en música de IA. |
| IP en imágenes y mallas | Roblox elimina contenido que infringe IP aunque lo haya generado una IA; las cuentas reincidentes pueden suspenderse. | No pedir personajes ni marcas de terceros; revisar resultados. |
| Moderación | Todo icono, miniatura, audio y vídeo pasa por moderación; tú eres responsable de la salida de IA de terceros. | Dejar margen de tiempo antes de lanzar. |
| Publicación con CI | La API no actualiza `SurfaceAppearance`, `EditableMesh`, etc. | Probar con un lugar de prueba y planear publicación manual de esos juegos. |
| Seguridad | Blender MCP ejecuta Python arbitrario sin autenticación; el MCP de Studio da acceso al lugar. | Solo localhost, solo clientes de confianza, guardar copia. |
| Precios | Los precios cambian cada pocas semanas; los comparadores se contradicen. | Revalidar en la web oficial el día de pagar. |
| Dependencia de herramientas | Sora cerrado y Udio sin descargas muestran que los servicios cambian. | No basar el pipeline en una sola herramienta cerrada. |

---

## 12. Dudas abiertas

1. **País de residencia del usuario**: si está en la UE, Reino Unido o Corea del Sur, Hunyuan3D queda descartado; y no sé si "Territory" se refiere al lugar de uso del modelo o al lugar de los jugadores.
2. **Licencias exactas** de Meshy y Tripo (capa de pago): comprobar los términos oficiales; las fuentes se contradicen. Tampoco verifiqué sus formatos de exportación (FBX/OBJ/GLB) ni el control de polígonos.
3. **Límite de triángulos**: los docs dicen 20.000 por malla; otras guías dicen 21.000 o 10.000. Probar una importación real.
4. **Textura máxima**: los docs dicen 4096x4096 en una sección y 1024x1024 en otra. Probar.
5. **`SurfaceAppearance` y la API de publicación**: ¿sigue sin actualizarse? Esto condiciona todo el CI/CD si se usan texturas PBR.
6. **Cuota de audio**: 2.000/30 días (docs de audio) contra 100/10 (guía de Open Cloud) y otras cifras de terceros.
7. **Política sobre audio de IA** en Roblox: no encontré ninguna oficial. Tampoco los "Audio Terms of Use".
8. **Costes y límites** de `generate_mesh` y del Texture Generator en Studio: los docs no los indican; propiedad y licencia del resultado, tampoco.
9. **ElevenLabs**: significado exacto de la exclusión "Studio Games" en la licencia de Eleven Music, y términos de SFX.
10. **Suno**: topes de descarga y derechos tras el acuerdo con Warner; litigios abiertos.
11. **Mínimo de Ads Manager**: 10 créditos (2023), 35 USD (blog 2026) o ninguno (docs actuales).
12. **No investigado** por falta de presupuesto de búsquedas: Firefly, Nano Banana/Gemini Image, Figma/Notion/Linear, Mixamo/Rokoko, códigos de influencers o afiliados en Roblox, políticas de TikTok/YouTube sobre IA, y la licencia de salida de Flux [pro].

---

## 13. Fuentes (consultadas el 2026-10-20)

### Oficiales (leídas directamente)
- Roblox creator-docs (espejo GitHub del Creator Hub): [specifications](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/specifications.md), [texture-specifications](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/texture-specifications.md), [export-requirements](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/export-requirements.md), [gltf-export](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/gltf-export.md), [modeling/index](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/index.md), [roblox-blender-plugin](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/roblox-blender-plugin.md), [audio/assets](https://github.com/Roblox/creator-docs/blob/main/content/en-us/audio/assets.md), [usage-assets](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/usage-assets.md), [usage-place-publishing](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/usage-place-publishing.md), [analytics (API)](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/analytics/index.md), [generative-AI](https://github.com/Roblox/creator-docs/blob/main/content/en-us/generative-AI.md), [texture-generator](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/texture-generator.md), [studio/mcp](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/mcp.md), [assistant/guide](https://github.com/Roblox/creator-docs/blob/main/content/en-us/assistant/guide.md), [assistant/skills](https://github.com/Roblox/creator-docs/blob/main/content/en-us/assistant/skills.md), [animation/capture](https://github.com/Roblox/creator-docs/blob/main/content/en-us/animation/capture.md), [animation/editor](https://github.com/Roblox/creator-docs/blob/main/content/en-us/animation/editor.md), [particle-emitters](https://github.com/Roblox/creator-docs/blob/main/content/en-us/effects/particle-emitters.md), [experience-icons](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/experience-icons.md), [thumbnails](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/thumbnails.md), [ip-guidelines](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/ip-guidelines.md), [rights-manager](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/rights-manager.md), [account-verification](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/account-verification.md), [passes](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/passes.md), [developer-products](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/developer-products.md), [ads-manager](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/ads-manager.md), [advertise-on-roblox](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/advertise-on-roblox.md), [comply-with-advertising-standards](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/comply-with-advertising-standards.md), [referral-system](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/referral-system.md), [social-media-links](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/social-media-links.md), [creator-store](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/creator-store.md), [roblox-user-base](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/roblox-user-base.md), [ui/](https://github.com/Roblox/creator-docs/tree/main/content/en-us/ui).
- Repositorios y licencias: [Hunyuan3D-2.1 LICENSE](https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1/blob/main/LICENSE), [Hunyuan3D-2.1](https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1), [TRELLIS.2](https://github.com/microsoft/TRELLIS.2), [TripoSR](https://github.com/VAST-AI-Research/TripoSR), [Roblox/cube](https://github.com/Roblox/cube), [Cube LICENSE](https://github.com/Roblox/cube/blob/main/LICENSE), [FLUX.2](https://github.com/black-forest-labs/flux2), [AudioCraft](https://github.com/facebookresearch/audiocraft), [Blender MCP](https://github.com/ahujasid/blender-mcp), [roblox-blender-plugin](https://github.com/Roblox/roblox-blender-plugin), [Rojo](https://github.com/rojo-rbx/rojo), [Wally](https://github.com/UpliftGames/wally), [rbxcloud](https://github.com/Sleitnick/rbxcloud), [GitHub pricing](https://github.com/pricing), [GitHub Marketplace (búsqueda roblox)](https://github.com/marketplace?query=roblox&type=actions).

### Terceros (solo resúmenes de WebSearch; páginas no abiertas)
- 3D: [costbench Meshy](https://costbench.com/software/ai-3d-generation/meshy/), [stacksheriff Meshy](https://stacksheriff.com/ai-tools/meshy-ai-pricing/), [media.io Tripo](https://www.media.io/comparison/tripo-ai-review.html), [Tripo blog licencias](https://www.tripo3d.ai/blog/commercial-use-ai-3d-models), [costbench Tripo](https://costbench.com/software/ai-3d-generation/tripo-ai/), [makerstack Rodin](https://makerstack.co/reviews/hyper3d-rodin-review/), [3dtoolwiki Rodin](https://3dtoolwiki.com/tools/rodin), [3daistudio game-ready](https://www.3daistudio.com/3d-generator-ai-comparison-alternatives-guide/can-ai-generate-game-ready-3d-models), [indiehackers 9 generadores](https://www.indiehackers.com/post/best-ai-3d-model-generator-in-2026-i-tested-9-of-the-best-and-here-is-what-i-found-70ecab1a0a), [bloxbot texturas y segmentación](https://bloxbot.ai/guide/roblox-ai-texture-generation-mesh-segmentation-2026), [costbench Luma](https://www.costbench.com/software/ai-3d-generation/luma-ai-3d/).
- Imágenes: [eesel Ideogram](https://eesel.ai/blog/ideogram-pricing), [costbench Ideogram](https://costbench.com/software/ai-image-generators/ideogram), [aifreeapi gpt-image-2](https://www.aifreeapi.com/en/posts/openai-image-generation-api-pricing), [costgoat](https://costgoat.com/pricing/openai-images), [costbench Midjourney](https://costbench.com/software/ai-image-generators/midjourney/), [eesel Midjourney](https://www.eesel.ai/blog/midjourney-pricing), [eesel Recraft](https://www.eesel.ai/blog/recraft-ai-pricing), [dailyaifixs Recraft](https://dailyaifixs.com/blog/recraft-pricing-2026-free-has-no-license), [krea Leonardo](https://www.krea.ai/blog/leonardo-ai-review-is-it-free-any-good-and-how-it-compares-in-2026), [fluxnote Leonardo](https://fluxnote.io/guides/leonardo-ai-pricing-guide-2026), [layer3labs Flux](https://www.layer3labs.io/guides/flux-explained), [comparativa de texto en imagen](https://www.aimagicx.com/blog/midjourney-vs-flux-vs-ideogram-image-comparison-2026).
- Audio: [lumimusic Suno](https://lumimusic.ai/blog/suno-pricing), [rinzara Suno](https://rinzara.com/suno-pricing), [DevForum audio eliminado](https://devforum.roblox.com/t/uploading-music-i-own-the-license-for-but-getting-taken-down/3638155), [minnlawyer Suno](https://minnlawyer.com/2026/09/28/us-district-court-denies-motion-to-dismiss-copyright-claims-suno/), [undetectr Udio](https://undetectr.com/blog/udio-download), [aitools-directory Udio](https://www.aitools-directory.com/blog/udio-ai-review-2026/), [promptsrush ElevenLabs](https://promptsrush.com/blog/elevenlabs-pricing-starter-creator-pro), [ampm-aiops Eleven Music](https://ampm-aiops.com/en/guides/eleven-music-free-vs-paid-commercial-2026/), [Stability Audio Open](https://stability.ai/news/stable-audio-open-research-paper), [MBW Stable Audio](https://www.musicbusinessworldwide.com/stability-ai-launches-ai-model-for-brands-to-create-custom-sounds), [DevForum Sonilo](https://devforum.roblox.com/t/generate-music-sound-effects-from-gameplay-videos-using-sonilo/4886492), [DevForum ForgeGUI](https://devforum.roblox.com/t/forgegui-generate-game-music-soundtracks-and-sfx-with-ai-for-roblox-games-feature/4734570).
- Animación y UI: [aicentralresources Cascadeur](https://www.aicentralresources.com/compare/deepmotion-vs-cascadeur), [tasarim.ai](https://tasarim.ai/en/alternatives/cascadeur), [topai.tools DeepMotion vs Plask](https://topai.tools/compare/deepmotion-vs-plask), [DeepMotion Roblox](https://www.deepmotion.com/companion-tools/roblox), [NoCapMocap](https://www.nocapmocap.com/roblox), [thetoolstrunk Moon Animator](https://thetoolstrunk.com/how-much-is-moon-animator/), [DevForum Moon Animator](https://devforum.roblox.com/t/is-moon-animator-worth-it/2477738), [DevForum React + Roblox](https://devforum.roblox.com/t/how-to-react-roblox/2964543), [DevForum GuiForge](https://devforum.roblox.com/t/guiforge-roblox-ui-editorfigma-export/4834077).
- Marketing y analítica: [vidpros CapCut](https://vidpros.com/capcut-pro-vs-free/), [bigvu CapCut](https://www.bigvu.tv/blog/capcut-pricing-2026-free-vs-pro-included-alternatives), [higgsfield vídeo IA](https://higgsfield.ai/blog/best-ai-video-generators-2026), [fluxnote precios de vídeo](https://fluxnote.io/guides/ai-video-model-pricing-comparison-2026), [techietory](https://techietory.com/best-ai-video-generators-2026/), [guptadeepak](https://guptadeepak.com/tools/top-5-ai-video-generation-tools-2026/), [lensblox analítica Roblox](https://lensblox.com/blog/best-roblox-game-analytics-tools-compared-2026-guide/), [DevForum Rolimon's](https://devforum.roblox.com/t/rolimons-game-analytics-free-statistics-for-roblox-games/491663), [DevForum Ads Manager](https://devforum.roblox.com/t/sponsored-experiences-moving-to-ads-manager/2661756), [bloxg guía de ads](https://bloxg.com/guides/roblox-ads-guide).
