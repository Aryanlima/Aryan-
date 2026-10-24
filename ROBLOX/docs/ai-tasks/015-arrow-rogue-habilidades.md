# 015 — arrow-rogue: sistema de habilidades y subida de nivel (fase 4)

Estado: PENDIENTE
Asignada a: Codex
Creada por: Claude, 2026-10-24

Usa ponytail: el cambio más pequeño que funcione, reutilizar lo existente, sin abstracciones nuevas, una sola prueba dirigida.

## Objetivo
En `ROBLOX/games/arrow-rogue/` crea el sistema de habilidades del servidor. Lee antes `docs/GDD.md` (sección de las 20 habilidades, su tabla y reglas de acumulación), `src/shared/Balance.luau` y `src/shared/Combat.luau`.
1. `src/shared/Skills.luau` (PURO, sin motor): la tabla tipada de las 20 habilidades del GDD (id s01..s20, nombre, rareza common/rare/epic, regla de acumulación, efecto como modificadores numéricos sobre las stats del héroe: daño, cadencia, flechas extra, rebotes, perforación, velocidad, vida, etc.), `Skills.roll(seed, owned, count)` que devuelve 3 opciones sin repetir y sin ofrecer las que ya no pueden acumularse, y `Skills.apply(stats, owned)` que calcula las stats finales con una función pura.
2. `src/server/SkillService.luau`: al subir de nivel el servidor sortea 3 opciones con semilla y las envía por un RemoteEvent de salida `SkillOffer` (ids, nunca valores calculados por el cliente); un RemoteEvent de entrada `SkillPick` recibe SOLO el índice 1..3, valida (entero, dentro de rango, hay oferta pendiente para ese jugador, una sola vez) y aplica la habilidad. Limitar la frecuencia de `SkillPick`.
3. Una prueba nueva `tests/Skills.spec.luau`: roll determinista por semilla, sin repetidos, respeta el tope de acumulación; apply compone modificadores; SkillPick rechaza índices inválidos, doble selección y selección sin oferta.

## Alcance
`ROBLOX/games/arrow-rogue/src/shared/Skills.luau`, `src/server/SkillService.luau`, `tests/Skills.spec.luau`, y añadir campos a `Balance.luau` si hace falta. No toques CombatService/EnemyService (otro agente los está editando).

## Fuera de alcance
Interfaz, arte, jefes, salas, persistencia entre partidas, dinero.

## Criterios
- [ ] `--!strict` sin errores de tipo: correr `bash ROBLOX/tools/lint.sh` y arreglar lo que salga en tus archivos.
- [ ] Correr solo: `bash ROBLOX/tools/test.sh ROBLOX/games/arrow-rogue/tests/Skills.spec.luau`.
