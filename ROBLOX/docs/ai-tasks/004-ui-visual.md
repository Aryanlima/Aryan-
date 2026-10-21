# 004 — Interfaz visual de Fish & Fortune
Estado: PENDIENTE · Asignada a: Codex · Alcance: ROBLOX/packages/UI.luau, ROBLOX/games/fish-and-fortune/src/client/Hud.luau, Menus.luau, Feedback.luau (NO tocar Minigame.luau, Main.client.luau ni el servidor)

El dueño dice que la UI "se ve malísima": cajas azul marino planas con texto. Objetivo: simulador top (Fish It!, Pet Simulator 99): botones gruesos redondeados con UIStroke y UIGradient, sombra, contadores de monedas grandes y llamativos, animaciones al pulsar y al aparecer (TweenService), tarjetas de captura vistosas por rareza, todo legible en móvil.
- Conserva lo ya arreglado: stats a la izquierda centradas en vertical, banner de evento en píldora oscura dorada, toast abajo encima de la barra de acciones.
- Mantén los nombres de instancias que usan las pruebas (FishFortune, ActionBar, ActionButton, SellButton, Menu, Stats, Events, Toast) o actualiza las pruebas explicando por qué.
- Iconos solo con texto/emoji o formas de UI.
Lee primero AGENTS.md y ROBLOX/docs/GDD.md (§4 dirección de arte y paleta: agua #2EC4F1, madera #C98A4B, oro #FFC83D, coral #FF5A5F, UI azul noche #1E2A44). Luau --!strict. Verifica con `bash ROBLOX/tools/test.sh`, `bash ROBLOX/tools/lint.sh` y `bash ROBLOX/tools/format.sh` (formatea) desde la raíz del repo; borra carpetas `.governor/` dentro de ROBLOX/ antes de probar. No uses IDs de assets inventados. No publiques nada. Haz commit en tu rama con mensaje en español. Informe final de máximo 12 líneas con el resultado REAL de las pruebas.
