# 009 — Revelado "1 en N" en la tarjeta de captura

Estado: PENDIENTE
Asignada a: Codex
Creada por: Claude, 2026-10-22

## Objetivo
En la tarjeta de captura (Rare o superior) mostrar "1 en N" (N = 1 / probabilidad real de esa criatura en la zona con la suerte actual, redondeado y con separador de miles). Idea #2 de ROBLOX/research/11-ideas-juegos-top.md. El servidor calcula N; el cliente solo lo muestra.

## Alcance (solo estos archivos)
- `ROBLOX/games/fish-and-fortune/src/server/GameService.luau` (payload del evento Catch, cerca de la línea 463: añadir `oneIn: number`; usar las odds que ya existen, ver `rules:oddsFor(zone):probabilityOf(id, luck)`)
- `ROBLOX/games/fish-and-fortune/src/client/Feedback.luau` (una línea nueva en la tarjeta si la rareza es Rare+)
- `ROBLOX/games/fish-and-fortune/src/shared/Strings.luau` (clave `catch.one_in`, ES+EN, p. ej. "1 en {n}" / "1 in {n}")

## Fuera de alcance
Probabilidades, economía, UI.luau, Hud, Menus.

## Criterios de aceptación
- [ ] `oneIn` sale de la probabilidad real (no inventada); Common/Uncommon no muestran la línea.
- [ ] Solo corre: bash ROBLOX/tools/test.sh ROBLOX/games/fish-and-fortune/tests/ClientBoot.spec.luau ROBLOX/games/fish-and-fortune/tests/Strings.spec.luau
