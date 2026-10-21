# AI_HANDOFF — estado para el siguiente agente

Actualizado: 2026-10-21 (2.ª parte), sesión del PC (rama `pc/aryan-local`).

## Estado
- Fish & Fortune se juega entero en Studio (playtest-1, 2.ª pasada): pesca, venta, cañas, bestiario, temporada, probabilidades y tienda con ID 0.
- `pickDataStore` arreglado (versión de la nube mezclada). Tarea 001 hecha (`--test-reporter=tap`): **642 pruebas en verde en Windows**; lint y formato OK.
- UI (commit 4380a45): el banner del evento va en una píldora oscura y dorada, las estadísticas están a la izquierda y centradas (lejos del chat) y el aviso queda encima de la barra de acciones. **Falta verlo en Studio** (playtest final).
- Experiencia PRIVADA "FF Pruebas (privado)": Universe 10772154962, Place 98614059053563.
- Investigación: `research/10-ranking-real-y-cartera.md` (ranking real) y `GDD.md` (dirección de arte y monetización cosmética).

## Mecánica de pesca (commits fb2e8a2 y siguiente)
Solo se lanza desde el muelle u orilla (`WorldBuilder.canFishAt`, validado en el servidor), hay espera de picada (`bite` 1,5-4 s) y recoger fuera de la zona verde = el pez se escapa (`missed`). 649 pruebas OK. Codex lo revisó: 1 hallazgo válido (recoger antes de la picada, arreglado) y 2 no aplicables (la comprobación del lago es un anillo exacto; `startCast` no se bloquea con una sesión vieja).

## Mundo, interfaz y audio (Codex, mezclado; commit db9dbe2) — verificado en Studio el 21-oct
Mundo con Terrain (agua real, orilla de arena, muelle con barandas y farolas, barca, árboles), botones con reflejo y letra legible, `Audio.luau` (sin sonidos aún). 650 pruebas OK. Codex no pudo correr `test.sh`/`lint.sh`/git en su sandbox: Claude commitea y verifica. Bugs que Codex dejó y Claude arregló: `UIGradient` en TextButton volvía la letra ilegible; el agua de Terrain no reemplaza tierra (hay que `Air` antes); el anillo de arena enterraba el muelle; tofu del emoji 🪙; `UIStroke` contorneaba la letra.
**Pendiente visual (el dueño dijo que aún "parece malo"):** cartel de zona enorme y feo (tablero rosa + base oscura); agua demasiado plana, sin espuma ni reflejos; sin partículas al pescar ni cámara que siga el corcho; el texto de ayuda de abajo sigue diciendo "Press REEL IN…" mientras se espera la picada; el chat de Studio tapa el HUD; íconos y miniatura finales; **audio: puestos y verificados en Studio (música, lago, gente jugando, salpicadura, monedas, fanfarria; cargan y suenan). Pendientes: `cast`, `escape`, `button` en `SoundIds.luau`; `bite` y `catch` son provisionales y sin oír.** Hacer comparación Ropilot vs flujo propio con el mismo encargo (el MCP de Ropilot se carga al reiniciar Claude).
Ropilot: conectado a Claude y Codex (`claude mcp list`), sin usar todavía.

## Ropilot (21-oct, noche)
Su programa (`%APPDATA%
opilotin
opilot-infra-helper.exe mcp --ropilot-external-mcp`) funciona y expone 27 herramientas: Studio (scripts, capturas, playtest), Blender (modelos, renders para íconos/miniaturas, `ropilot_blender_upload_images` sube PNG a Roblox) y VFX (`ropilot_vfx_capture`). Se probó por stdio con `ROBLOX/tools/ropilot-mcp-probe.mjs` (solo lista y listchildren). **Studio NO estaba conectado a Ropilot** (falta que Aryan inicie sesión en la app Ropilot Studio y active el plugin en Plugins). Claude lo carga como herramienta nativa tras reiniciar. Pendiente: prueba comparativa (ícono y miniatura con Blender de Ropilot vs flujo propio). Ropilot es de terceros: su plugin ejecuta código recibido de ropilot.ai y usa créditos.

## Estado visual (21-oct, noche)
Mundo con colinas de Terrain, nubes reales, luz cálida, muelle con farolas, cartel legible, agua azul (28,116,178), HUD compacto, efectos de salpicadura y "!" al picar, audio real. Bug resuelto: `Lighting.Technology` no se puede fijar desde script y cortaba toda la iluminación (poner "Future" a mano en el lugar). Falta: ver la versión final con el agua corregida en Studio, ícono/miniatura finales, sonidos `cast`/`escape`/`button`, probar compras con IDs reales en la privada (Aryan decide).

## Pendiente al 22-oct (leer primero)
1. **Zonas Río/Costa (HECHO 22-oct):** ideas de 409bd48 re-aplicadas a mano sobre el `WorldBuilder.luau` actual (Río: rocas, cascada, puente de troncos, niebla, pinos; Costa: faro en isla en mar abierto, gaviotas, conchas, estrellas, palmeras). `canFishAt` intacto. ArtWorld + ProjectStructure en verde; visto en Studio construyendo el mundo en edición (sin playtest). La rama `pc/zonas-agente` ya no hace falta.
2. **Ícono y miniatura con Ropilot (HECHO 22-oct, sin subir):** Ropilot NO tiene prompts ni resources (solo `tools`); su "diseño" es `ropilot_blender_render` (estilo ultrabright: brillo, contorno, halo) sobre modelos que construye Claude en su Blender. Flujo: `ropilot_blender_import_rig` (maniquí R15 en memoria) → `ropilot_blender_run_python` con `assets/source/blender-icono-escena.py` (carga `blender-pez-3d.py`) → `ropilot_blender_render(items=['IconScene'], style='ultrabright', yaw=10, pitch=8, sparkles=false, padding=.04)` → `python assets/source/compose-icono.py icon|thumb en|es` (fondo y texto). Salidas: `assets/icon/icon-ropilot.png`, `assets/thumbnails/thumb-ropilot-{en,es}.png`. Subir a Roblox SOLO con permiso de Aryan (`ropilot_blender_upload_images`).
- Studio muere si lo abre un comando de Claude (se cierra con el proceso padre): abrirlo con una tarea programada (`Register-ScheduledTask` + `Start-ScheduledTask`, tarea `AbrirStudioFF`).
3. **Equilibrio nuevo (sin playtest largo):** cañas 120/1.500/12.000/80.000, zonas 1.500/15.000, míticos peso 1; mando con botón A; botones `Selectable`. Auditorías de Codex en `ROBLOX/.toolchain/codex/auditoria-1.md` y `-2.md` (resumidas en `docs/playtest-2.md`).
4. Pendientes de prueba en Studio: eventos, códigos, idiomas, offline, pesca automática, móvil real, mando real, compras con IDs reales (13 objetos fuera de venta; ninguna compra probada).
5. Costo: tabla "Reparto por costo" en la skill `token-efficient-development` (haiku mecánico, Codex revisión, Ropilot diseño). Claude Code Router NO instalado (pide claves de pago).
6. El límite de sesión del plan de Aryan cortó a los subagentes: se reinicia a las 3 a. m. (Seúl). Contexto de la conversación larga casi lleno: seguir en un chat nuevo.

## Decisiones
- La nube orquesta y escribe en `claude/brave-meitner-esyqy8`; el PC commitea en `pc/aryan-local`; Codex trabaja en `codex/<tarea>`.
- Monetización v1.1: cosméticos y comodidad antes que suerte de pago.

## Pendiente
1. Misión 2, etapas 2 y 3 HECHAS: 13 objetos creados fuera de venta y cableados en `ProductIds.luau` (PUERTA OK). TargetId = ID del pase (caso A). Pendiente de Aryan: el W-9 antes del 31-oct y decidir la 3b/3.5 (poner a la venta en la privada y una compra mínima).
2. Tarea 002 hecha en código: Caña Dorada (399) y Estela de Burbujas (799, escalón nuevo `deluxe`), con `server/Cosmetics.luau` aplicado por el servidor, íconos en `marketing/.../passes/`, `store-items.json` con **13 objetos** (antes 11) y `tests/Cosmetics.spec.luau`. Codex la revisó (`--review 80430f1`): 1 hallazgo bajo (el Trail no tenía burbujas) → arreglado con un ParticleEmitter. Pendiente: una textura de burbuja propia (subir la imagen) y verla en Studio. La misión 2 ahora crea 13 objetos.
- `render-assets.mjs` necesita ImageMagick (winget falla en este PC); los PNG se optimizaron con PIL (RGB y ≤200 KB).
3. Ícono y miniatura según GDD §4 (necesita una herramienta de imagen o generarlos en Studio).
4. Playtest final en Studio (UI nueva y cosméticos), cuando Aryan lo pida.
- Ojo: el plugin governor crea carpetas `.governor/` en cada carpeta donde se ejecuta un comando. Trabaja con rutas absolutas desde la raíz; si aparecen dentro de `ROBLOX/`, bórralas (rompen ProjectStructure.spec).

## Siguiente paso
Playtest final en la experiencia privada (UI nueva, cosméticos y tienda con IDs reales, que debe decir "no disponible" mientras estén fuera de venta) cuando Aryan lo pida. Luego, la etapa 4 (amigos) es decisión de Aryan.
