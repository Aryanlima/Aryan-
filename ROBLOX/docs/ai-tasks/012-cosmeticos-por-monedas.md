# 012 — Cosméticos de caña comprables con monedas (sumidero seguro)

Estado: PENDIENTE
Asignada a: Codex
Creada por: Claude, 2026-10-23

Usa ponytail: el cambio más pequeño que funcione, reutilizar lo existente, sin abstracciones nuevas, una sola prueba dirigida.

## Objetivo
La simulación (docs/equilibrio-simulacion.md) muestra que el jugador activo se queda sin nada que comprar. Añade 3 skins de caña SOLO cosméticas, compradas con monedas (precios 200.000, 1.000.000 y 5.000.000), sin suerte ni ventaja de juego. Reutiliza el sistema existente de cosméticos (`server/Cosmetics.luau`, `Balance`, `ownedRods`/campo de cosméticos del perfil, `Catalog.luau`) y un remoto ya existente para comprar si es posible (el test de estructura cuenta los 16 remotos de entrada: si necesitas uno nuevo, actualiza ese conteo en tests/GameService.spec.luau y ProjectStructure.spec.luau).

## Alcance
- `ROBLOX/games/fish-and-fortune/src/shared/Balance.luau`, `src/server/Cosmetics.luau`, `GameLogic.luau`, `GameService.luau`, `Catalog.luau`, `src/shared/Strings.luau` (ES+EN, nombres de los 3 skins) y UNA prueba nueva en `tests/Cosmetics.spec.luau`.

## Fuera de alcance
Interfaz (Menus.luau), mundo, compras con Robux, probabilidades, suerte.

## Criterios
- [ ] Comprar descuenta monedas (REVIEW(money)), no se puede comprar dos veces, falla sin monedas suficientes.
- [ ] Correr solo: `bash ROBLOX/tools/test.sh ROBLOX/games/fish-and-fortune/tests/Cosmetics.spec.luau ROBLOX/games/fish-and-fortune/tests/Strings.spec.luau` (y los specs de estructura si cambias remotos).
