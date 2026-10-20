# Playtest 1 — Fish & Fortune en Studio (PC de Aryan)

Fecha: 2026-10-21 ~07:40 KST. Rama `pc/aryan-local` con `origin/claude/brave-meitner-esyqy8` (09c85b8) mezclada.
Cómo se abrió: `rojo build ROBLOX/games/fish-and-fortune/default.project.json -o ROBLOX/.toolchain/ff-playtest.rbxl`. Luego Studio con `RobloxStudioBeta.exe -task EditFile -localPlaceFile <rbxl>` y Play solo por MCP. Es un archivo **local sin publicar**.

**Resumen:** el mundo carga bien, pero **el servidor del juego se cae al arrancar** en un lugar sin publicar, así que no hay HUD, tutorial, tienda ni datos. Puerta 0.4 de la misión 2 = **PARAR**.

| Paso | Resultado | Evidencia | Notas |
|---|---|---|---|
| Arranque del servidor | **FALLA** | Consola: `You must publish this place to the web to access DataStore.` en `ServerScriptService.Server.GameService` línea 109 (`pickDataStore`), llamada desde la línea 124 (`start`) y `Server.Main` línea 61 | `DataStoreService:GetDataStore(DATASTORE_NAME)` está **fuera** del `pcall`. En un lugar sin publicar, `GetDataStore` lanza el error él mismo, no solo `GetAsync`, y el respaldo `StudioMemoryStore` nunca se usa. Arreglo sugerido: meter también `GetDataStore` en el `pcall` (o envolver todo `pickDataStore`). No se editó: regla 7 |
| Mundo / escenario | OK | `ROBLOX/.toolchain/evidencia/playtest1-arranque.jpg` | Lago, muelle y cartel visibles; el personaje aparece |
| Arte | OK (respaldo) | Consola: `[Art] arte generado: 0 de 35 piezas (35 sin arte -> respaldo procedural, 0 rechazadas)` | Esperado: aún no hay piezas generadas |
| Asset de contenido | AVISO | Consola, 3 veces: `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type` | Ese ID no está en el repo (`grep` vacío); probablemente lo usa un script interno de Roblox o un valor por defecto. Revisarlo cuando arranque el servidor |
| Avisos de UIBlox `FoundationProvider not found` | Ignorable | Consola | Vienen de CorePackages de Roblox, no del juego |
| Tutorial y primeros 60 s, minijuego, venta, bestiario, zonas, banner, eventos, tienda, probabilidades, idiomas | NO PROBADO | — | Bloqueados por la caída del servidor |

## Pruebas y lint en Windows (Git Bash)

- `test.sh`: **639 pasan, 1 falla, 3 omitidas** (34 specs). La que falla es `tools/wire-ids.spec.luau`, que lanza `node --test` desde Lune. Corridas directamente, `node --test ROBLOX/tools/*.test.mjs` pasan **52 de 52**. El fallo está en el lanzador de Lune en Windows, no en las herramientas. Probable causa: `process.exec("node.exe", …)` desde Lune; la salida no se imprime y la nube debería mostrarla.
- `lint.sh`: **OK**. `format.sh --check`: **OK** (sin salida).
- `ROBLOX_API_KEY`: **NO definida**.

## Qué sigue

1. La nube arregla `pickDataStore` (y, si puede, que el spec de Node imprima la salida en Windows).
2. Se repite este playtest con el checklist completo del README §6. Otra opción: hacerlo directamente en la experiencia de prueba privada (Etapa 1), donde `GetDataStore` sí funciona.

## Segunda pasada (después del arreglo, mismo día ~08:10 KST)

Con permiso de Aryan ("haz lo que quieras"), la sesión del PC arregló `pickDataStore`: `GetDataStore` ahora va dentro de un `pcall`; en Studio usa la memoria y fuera de Studio relanza el error. También se añadió la prueba `GameService.spec`, "en un lugar sin publicar…", con la opción `unpublishedStudio` del arnés. Pruebas: 640 pasan (+1); lint y formato OK.

| Paso | Resultado | Evidencia | Notas |
|---|---|---|---|
| Arranque | OK | Consola: `[Data] … almacen en MEMORIA`, `[Shop] hay 11 pases/productos con ID 0`, `[FishFortune] servidor iniciado` | — |
| HUD y pista de los primeros 60 s | OK | `evidencia/p1b-hud.jpg` | "Press CAST to start fishing", monedas, perlas, bolsa y zona |
| Minijuego | OK | `p1b-minijuego.jpg`, `p1b-captura.jpg` | 15 de 15 capturas (Carp Common, Golden Trout Rare, etc.). Cualquier recogida dentro de 4,2 s pesca; la zona verde solo da calidad (`evaluateReel`), así que es a propósito |
| Venta | OK | `p1b-venta.jpg` | "Sold 15 catches for 1,776 coins" (evento Golden Tide x2 activo) |
| Cañas y compra con monedas | OK | `p1b-cana.jpg` | Reed Rod comprada por 120 monedas y equipada |
| Bestiario | OK | `p1b-bestiario.jpg` | 5 / 25 descubiertos |
| Temporada | OK | `p1b-temporada.jpg` | Pista gratis y premium; "Fixed rewards, no randomness" |
| Probabilidades | OK | `p1b-odds.jpg` | Por zona, con la suerte total y su tope (8) |
| Tienda | OK | `p1b-tienda.jpg` | Con ID 0, cada objeto dice "Not available right now" (no abre compra). No aparece Suerte+ ni Cebo |
| Banner de evento | AVISO (diseño) | `p1b-hud.jpg` | "Golden Tide (coins x2): 5d 1h" en verde muy claro sobre el cielo: casi no se lee |
| HUD y chat | AVISO (diseño) | `p1b-minijuego.jpg` | Al abrir el chat de Roblox (arriba a la izquierda), tapa el panel de monedas |
| Toast sobre panel | AVISO (diseño) | `p1b-cana.jpg` | El aviso "Rod bought and equipped." tapa el título del panel |
| LiveOps | AVISO | Consola: `ConfigService: Failed to load config` | Esperado en un lugar sin publicar; conserva la configuración por defecto |
| Zonas 2 y 3, eventos que rotan, códigos, idiomas, offline, auto-pesca | NO PROBADO | — | Para la experiencia privada (Etapa 1) |
