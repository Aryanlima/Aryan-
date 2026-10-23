# 014 — arrow-rogue: combate básico en el servidor (fase 2)

Estado: PENDIENTE
Asignada a: Codex
Creada por: Claude, 2026-10-23

Usa ponytail: el cambio más pequeño que funcione, reutilizar lo existente, sin abstracciones nuevas, una sola prueba dirigida.

## Objetivo
En `ROBLOX/games/arrow-rogue/` el servidor decide todo el combate. Lee antes `src/shared/Combat.luau` y `Balance.luau` (funciones puras ya probadas) y `ROBLOX/research/14-tecnica-roguelike-roblox.md` (secciones 1-3).
1. `src/server/CombatService.luau`: un solo bucle Heartbeat. Por jugador: leer la velocidad horizontal de `HumanoidRootPart` y usar `Combat.isStanding`; si está quieto y `Combat.canFire`, elegir blanco con `Combat.pickTarget` (el enemigo vivo más cercano con línea de vista) y disparar. Las flechas son datos (tablas), no Instances: mover en el bucle, un raycast contra paredes por paso, daño al enemigo si lo toca (círculo-segmento), tope de 24 flechas del jugador vivas.
2. `src/server/EnemyService.luau`: un enemigo `chaser` con estados Idle -> Chase -> Windup (aviso 0,4 s) -> Attack -> Recover, sin Humanoid (Part anclada movida por el servidor), tope de 40 vivos, `spawn(id, pos)` y `clear()`.
3. Publicar al cliente por atributos/un RemoteEvent de salida (`Shot`: origen, dirección, velocidad, tipo, t0 = GetServerTimeNow()) y NO aceptar ningún dato de combate del cliente (sin remotos de entrada de daño/blanco/cadencia).
4. Una prueba nueva en `tests/CombatService.spec.luau`: quieto dispara al blanco legal, moverse suspende el disparo, el cliente no puede elegir daño ni acelerar la cadencia (usar dobles como en ROBLOX/games/fish-and-fortune/tests/support).

## Alcance
`ROBLOX/games/arrow-rogue/src/server/*`, `src/shared/Balance.luau` (solo añadir campos), `tests/CombatService.spec.luau`, `default.project.json` si hace falta.

## Fuera de alcance
Interfaz, arte, habilidades, jefes, otros juegos, `packages/`.

## Criterios
- [ ] Marca `REVIEW(money)` donde el daño/recompensa pueda tocar datos persistentes (por ahora nada persiste).
- [ ] Correr solo: `bash ROBLOX/tools/test.sh ROBLOX/games/arrow-rogue/tests/CombatService.spec.luau ROBLOX/games/arrow-rogue/tests/Combat.spec.luau` y `bash ROBLOX/tools/lint.sh`.
