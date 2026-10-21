# AI_HANDOFF — estado para el siguiente agente

Actualizado: 2026-10-21, sesión del PC (rama `pc/aryan-local`).

## Estado
- Fish & Fortune se juega entero en Studio (playtest-1, 2.ª pasada): pesca, venta, cañas, bestiario, temporada, probabilidades y tienda con ID 0.
- Arreglo propio: `pickDataStore` con `GetDataStore` dentro de un `pcall` y prueba nueva. Pruebas: 640 pasan y 1 falla solo en Windows (tarea 001).
- Experiencia PRIVADA "FF Pruebas (privado)": Universe 10772154962, Place 98614059053563.
- Investigación: `research/10-ranking-real-y-cartera.md` (ranking real) y `GDD.md` (dirección de arte y monetización cosmética).

## Decisiones
- La nube orquesta y escribe en `claude/brave-meitner-esyqy8`; el PC commitea en `pc/aryan-local`; Codex trabaja en `codex/<tarea>`.
- Monetización v1.1: cosméticos y comodidad antes que suerte de pago.

## Pendiente
1. Aryan: `codex login`; la clave `ROBLOX_API_KEY` limitada a Universe 10772154962, para la etapa 2 de la misión 2 (11 pases y productos); el W-9 antes del 31-oct.
2. Codex: tarea 001 (spec de Node en Windows).
3. UI: banner legible, el chat tapa el HUD y el aviso tapa el título del panel.
4. Pases cosméticos v1.1 (ver GDD §3) e ícono y miniatura según GDD §4.

## Siguiente paso
Cuando haya clave de API: `node ROBLOX/tools/create-items.mjs --universe 10772154962` (plan) → `--apply` → `wire-ids.mjs` (misión 2, etapas 2 y 3).
