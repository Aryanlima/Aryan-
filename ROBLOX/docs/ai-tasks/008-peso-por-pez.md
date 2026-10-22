# 008 — Peso por pez y "mi pez más grande"

Estado: ACEPTADA (Claude terminó la parte que Codex dejó a medias; el valor de venta no cambia)
Asignada a: Codex
Creada por: Claude, 2026-10-22

## Objetivo
Cada pez capturado tiene un peso aleatorio (kg) dentro de un rango por especie; vale más cuanto pesa más (±30 % del precio base) y se guarda el récord por especie. Idea #3 de `ROBLOX/research/11-ideas-juegos-top.md`.

## Alcance (solo estos archivos)
- `ROBLOX/games/fish-and-fortune/src/shared/Balance.luau` (rango de peso por rareza, `minigame`/precio)
- `ROBLOX/games/fish-and-fortune/src/server/GameLogic.luau` (`resolveCatch`, `sellAll`), `Schema.luau` (campo `records`, con migración que acepta datos viejos)
- `ROBLOX/games/fish-and-fortune/tests/GameLogic*.spec.luau` o `GameService.spec.luau` (pruebas nuevas)

## Fuera de alcance
- Interfaz (client/*), WorldBuilder, compras, probabilidades de rareza (no cambian).

## Criterios de aceptación
- [ ] El peso sale de un RNG inyectable (determinista en pruebas); el servidor decide, el cliente solo lo muestra.
- [ ] Valor de venta = precio base × factor(peso) acotado a 0,7–1,3; el total del inventario sigue calculándose en el servidor. Marcar `REVIEW(money)` donde toque dinero.
- [ ] `records[especie] = {kg}` se actualiza solo si es mayor; datos antiguos sin `records` cargan sin error.
- [ ] Prueba nueva que falla sin el cambio. Solo las pruebas afectadas; no la suite completa.

## Contexto útil
`GameLogic.resolveCatch` (~línea 358) y `sellAll` (~452). Estilo: `--!strict`, sin comentarios innecesarios.

## Informe de Codex
(Codex rellena: cambios y pruebas)
