# 013 — Equipar y quitar skins de caña ya compradas

Estado: PENDIENTE
Asignada a: Codex
Creada por: Claude, 2026-10-23

Usa ponytail: el cambio más pequeño que funcione, reutilizar lo existente, sin abstracciones nuevas, una sola prueba dirigida.

## Problema
Los 3 skins de caña (Balance.cosmeticRods, tarea 012) se equipan solo al comprarse (`data.cosmeticRod`). `EquipRod` solo acepta cañas base y el State no envía qué skins tiene el jugador ni cuál está puesto, así que la interfaz no puede mostrar "Equipado" ni permitir cambiar.

## Objetivo
1. El State que recibe el cliente incluye `cosmeticRods` (mapa id -> true de los comprados) y `cosmeticRod` (id equipado o nil).
2. `EquipRod` (remoto existente, sin añadir remotos: los tests cuentan 16 de entrada) acepta además un id de skin comprado y lo equipa; acepta el id de una caña base para quitar el skin (cosmeticRod = nil) sin cambiar la caña base. Validar que el skin sea del jugador (servidor autoritativo).
3. Cliente `src/client/Menus.luau`, sección "Rod Skins" del panel de cañas: estado 'Equipped' (deshabilitado), botón 'Equip' para los comprados, y 'Buy' como ahora. Reutiliza las filas y UI.motion.pop existentes; textos nuevos en `shared/Strings.luau` ES+EN (Title Case en inglés, sin claves sin usar).

## Alcance
`src/server/GameService.luau`, `GameLogic.luau`, `src/shared/Strings.luau`, `src/client/Menus.luau`, y UNA prueba nueva en `tests/Cosmetics.spec.luau`.

## Criterios
- [ ] No se puede equipar un skin no comprado; quitar el skin no altera la caña base ni las monedas.
- [ ] Correr solo: `bash ROBLOX/tools/test.sh ROBLOX/games/fish-and-fortune/tests/Cosmetics.spec.luau ROBLOX/games/fish-and-fortune/tests/ClientBoot.spec.luau ROBLOX/games/fish-and-fortune/tests/Strings.spec.luau ROBLOX/games/fish-and-fortune/tests/GameService.spec.luau`.
