# 011 — Minijuego: cerrar la ventana de trampa (MINI-01)

Estado: PENDIENTE
Asignada a: Codex
Creada por: Claude, 2026-10-22

Usa ponytail: el cambio más pequeño que funcione, reutilizar lo existente, sin abstracciones nuevas, una sola prueba dirigida.

## Problema (auditoría ROBLOX/docs/revision-lanzamiento.md, riesgo 4)
En `ROBLOX/games/fish-and-fortune/src/shared/FishingRules.luau` (~176-208) la ventana de tiempo aceptada para `Reel` (≈2,85 s) es mayor que el periodo del marcador (1,5 s): un bot que envía Reel en cualquier instante dentro de la ventana siempre cae en la zona perfecta.

## Objetivo
El servidor calcula la posición del marcador en el instante `elapsed` del Reel y solo da `perfect` si ese instante cae realmente en la zona, sin que una ventana más larga que el periodo permita acertar siempre. No cambies la dificultad para jugadores normales (mismo periodo y zona); solo que el acierto dependa del tiempo exacto enviado y esté acotado por tiempo mínimo/máximo plausible.

## Alcance
- `ROBLOX/games/fish-and-fortune/src/shared/FishingRules.luau`
- `ROBLOX/games/fish-and-fortune/tests/FishingRules*.spec.luau` o `Review.Minigame.spec.luau`: UNA prueba nueva que falla sin el cambio (varios `elapsed` distintos dentro de la ventana no pueden dar todos `perfect`).

## Fuera de alcance
Interfaz, economía, remotos.

## Criterios
- [ ] Solo corre: `bash ROBLOX/tools/test.sh ROBLOX/games/fish-and-fortune/tests/Review.Minigame.spec.luau` y el spec que toques. Marca `REVIEW(money)` si tocas lo que decide recompensas.
