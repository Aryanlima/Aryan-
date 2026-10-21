# Playtest 2 — Fish & Fortune en Studio (2026-10-21)

Archivo local `ff-playtest9.rbxl` (sincronizado con Rojo). Experiencia privada; no se compró nada.

| paso | resultado (OK / NO PROBADO / AVISO) | evidencia | notas |
|---|---|---|---|
| Arranque y consola | OK | Consola de Studio | Sin errores propios. Los avisos de UIBlox y del ContentId 203785492 son de Roblox. |
| Pesca solo desde muelle u orilla (validada en servidor) | OK | Pruebas Lune; en Studio se lanzó desde el muelle | La validación de la posición está en el servidor. |
| Espera de picada y "BITE!" | OK | Studio | |
| Fallar la zona verde = el pez escapa | OK en pruebas; NO visto en Studio | Pruebas Lune | Falta comprobarlo en Studio. |
| HUD sin solaparse con el chat | OK | Capturas: stats a la izquierda, centradas | |
| Banner de evento legible | OK | Capturas: píldora oscura con letra dorada | |
| Toast sobre la barra de acciones | OK | Capturas | |
| Audio | AVISO | Música, lago y gente jugando suenan y cargan | Faltan sonidos de cast, escape y button. |
| Río Cristal y Costa Dorada | AVISO | Ambas zonas construyen | El Río parece un canal y la Costa una piscina. Mejora en curso. |
| Mando / gamepad | NO PROBADO | — | Botón A añadido; sin mando real. |
| Móvil | NO PROBADO | — | No probado en el emulador de Studio. |
| Equilibrio | OK (según Odds) | Auditoría independiente de Codex | Cañas 120 / 1.500 / 12.000 / 80.000; zonas 1.500 / 15.000; míticos con peso 1. Las probabilidades suman 100 % por zona. |
| Compras | NO PROBADO | 13 objetos creados fuera de venta | No se probó ningún diálogo de compra. |

## Auditorías de Codex (solo lectura)

- Economía lenta y bestiario de ~349 min de media; se cambiaron los míticos a más frecuentes.
- Saltos de precio de las cañas de 12 a 20 veces; suavizados.
- Zonas muy parecidas en composición: pendiente.
- UI móvil: barra de acciones al 90 % del ancho y avisos a 130 px del borde; pendiente de probar en móvil.
