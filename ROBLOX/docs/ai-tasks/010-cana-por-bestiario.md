# 010 — Cañas que piden descubrir especies (bestiario)

Estado: PENDIENTE
Asignada a: Codex
Creada por: Claude, 2026-10-22

## Objetivo
Algunas cañas de gama alta, además del precio en monedas, exigen haber descubierto N especies distintas (`GameLogic.discoveries(data)` ya cuenta las del bestiario). Une colección y progreso (idea #8 de ROBLOX/research/11-ideas-juegos-top.md). El servidor decide.

## Alcance (solo estos archivos)
- `ROBLOX/games/fish-and-fortune/src/shared/Balance.luau`: campo opcional `requiresDiscoveries: number?` en las cañas (poner 8 en la penúltima y 14 en la última; las demás sin campo). Respetar los tests de orden de precios/suerte de `tests/Balance.spec.luau`.
- `ROBLOX/games/fish-and-fortune/src/server/GameLogic.luau`: `buyRod` rechaza con razón `"need-discoveries"` si faltan especies ANTES de gastar; marcar `REVIEW(money)`.
- `ROBLOX/games/fish-and-fortune/src/shared/Strings.luau`: texto de la razón en el formato de las otras razones de fallo (ES+EN; mira cómo están `fail.not-enough-coins` o similar).
- `ROBLOX/games/fish-and-fortune/tests/GameLogic.spec.luau`: prueba nueva (falla sin el cambio): con monedas de sobra pero pocas especies → `false, "need-discoveries"` y no se gasta nada; con las especies → compra OK.

## Fuera de alcance
Menus.luau, Hud.luau, WorldBuilder, compras con Robux.

## Criterios de aceptación
- [ ] Solo corre: `bash ROBLOX/tools/test.sh ROBLOX/games/fish-and-fortune/tests/GameLogic.spec.luau ROBLOX/games/fish-and-fortune/tests/Balance.spec.luau ROBLOX/games/fish-and-fortune/tests/Strings.spec.luau` (si no puedes ejecutarlo, dilo; Claude lo corre).
- [ ] `--!strict`, sin comentarios innecesarios.
