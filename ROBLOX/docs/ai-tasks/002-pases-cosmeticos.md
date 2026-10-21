# 002 — Pases cosméticos v1.1: Caña Dorada y Estela de Burbujas

Estado: HECHA EN CÓDIGO (647 pruebas OK). Revisada por Codex (1 hallazgo bajo, arreglado). Falta: playtest visual y una textura de burbuja
Asignada a: Claude (toca dinero: no se delega). Codex hace la revisión con `codex-task.sh --review <commit>`.
Creada por: Claude, 2026-10-21

## Objetivo
Vender cosméticos que no dan ventaja, como los líderes del género (GDD §3): la **Caña Dorada** (399 R$, la caña se ve dorada y brilla) y la **Estela de Burbujas** (799 R$, una estela de burbujas al caminar). Los demás jugadores ven los dos efectos.

## Alcance
Seguir el mismo camino que el pase `vip` (búscalo con grep en estos archivos):
- `games/fish-and-fortune/src/shared/Balance.luau`
- `src/server/Catalog.luau`
- `src/server/ProductIds.luau` (ID 0 = TODO)
- `store-items.json`
- `src/shared/Strings.luau` (ES y EN)
- `src/client/Menus.luau`
- `src/server/GameService.luau`: aplicar el cosmético al personaje en el servidor
- Pruebas en `tests/` (PassIds, Store, Catalog y Strings esperan 11 objetos y pasarán a 13)

## Fuera de alcance
Suerte de pago (sigue apagada), cambiar los precios existentes y el arte final (por ahora, procedural: Color3 dorado, Material Neon, ParticleEmitter o Trail con propiedades nativas).

## Criterios de aceptación
- [ ] 2 pases nuevos en `store-items.json` y el catálogo, con ID 0 y "Not available" hasta que la etapa 2 de la misión 2 los cree.
- [ ] El servidor aplica el cosmético al aparecer el personaje y al comprarlo (`PromptGamePassPurchaseFinished` y `UserOwnsGamePassAsync`, con caché), sin confiar en el cliente.
- [ ] Ningún efecto de juego: la suerte, las monedas y la velocidad no cambian (hay una prueba para eso).
- [ ] Textos ES y EN, sin presión de compra.
- [ ] `test.sh`, `lint.sh` y `format.sh --check` en verde.
- [ ] Playtest: se ve el efecto en el cliente y en el servidor (al final, cuando Aryan diga).

## Contexto útil
`ROBLOX/research/10-ranking-real-y-cartera.md` §2. Fish It! vende un VIP de 445 con caña dorada y halo, y packs de skins de caña a 399. Keyboard Escape vende estelas de 199 a 1.999.
