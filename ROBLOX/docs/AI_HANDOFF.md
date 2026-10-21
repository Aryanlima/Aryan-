# AI_HANDOFF — estado para el siguiente agente

Actualizado: 2026-10-21 (2.ª parte), sesión del PC (rama `pc/aryan-local`).

## Estado
- Fish & Fortune se juega entero en Studio (playtest-1, 2.ª pasada): pesca, venta, cañas, bestiario, temporada, probabilidades y tienda con ID 0.
- `pickDataStore` arreglado (versión de la nube mezclada). Tarea 001 hecha (`--test-reporter=tap`): **642 pruebas en verde en Windows**; lint y formato OK.
- UI (commit 4380a45): el banner del evento va en una píldora oscura y dorada, las estadísticas están a la izquierda y centradas (lejos del chat) y el aviso queda encima de la barra de acciones. **Falta verlo en Studio** (playtest final).
- Experiencia PRIVADA "FF Pruebas (privado)": Universe 10772154962, Place 98614059053563.
- Investigación: `research/10-ranking-real-y-cartera.md` (ranking real) y `GDD.md` (dirección de arte y monetización cosmética).

## Decisiones
- La nube orquesta y escribe en `claude/brave-meitner-esyqy8`; el PC commitea en `pc/aryan-local`; Codex trabaja en `codex/<tarea>`.
- Monetización v1.1: cosméticos y comodidad antes que suerte de pago.

## Pendiente
1. Aryan: `codex login`; la clave `ROBLOX_API_KEY` limitada a Universe 10772154962, para la etapa 2 de la misión 2 (11 pases y productos); el W-9 antes del 31-oct.
2. Tarea 002 hecha en código: Caña Dorada (399) y Estela de Burbujas (799, escalón nuevo `deluxe`), con `server/Cosmetics.luau` aplicado por el servidor, íconos en `marketing/.../passes/`, `store-items.json` con **13 objetos** (antes 11) y `tests/Cosmetics.spec.luau`. Falta: verla en Studio y `codex-task.sh --review` cuando Codex tenga sesión. La misión 2 ahora crea 13 objetos.
- `render-assets.mjs` necesita ImageMagick (winget falla en este PC); los PNG se optimizaron con PIL (RGB y ≤200 KB).
3. Ícono y miniatura según GDD §4 (necesita una herramienta de imagen o generarlos en Studio).
4. Playtest final en Studio (UI nueva y cosméticos), cuando Aryan lo pida.
- Ojo: el plugin governor crea carpetas `.governor/` en cada carpeta donde se ejecuta un comando. Trabaja con rutas absolutas desde la raíz; si aparecen dentro de `ROBLOX/`, bórralas (rompen ProjectStructure.spec).

## Siguiente paso
Cuando haya clave de API: `node ROBLOX/tools/create-items.mjs --universe 10772154962` (plan) → `--apply` → `wire-ids.mjs` (misión 2, etapas 2 y 3).
