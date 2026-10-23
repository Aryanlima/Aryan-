# GDD - Brumaflecha: Asedio de los Faros (v0, MVP)

Solo mecanicas genericas del genero roguelite de arquero. Nada de nombres, arte ni IP de terceros. Base: research/13, 14, 15. Todo numero es DEFAULT a calibrar con prototipo [medir].
Raiz de codigo: `ROBLOX/games/arrow-rogue/` (`src/server`, `src/client`, `src/shared`, `tests/`, `docs/`). Reusar `ROBLOX/packages/Data.luau`, `Shop.luau`, `Economy.luau`.

## 1. Vision y pilares
Nara, exploradora, restaura faros vivos en un archipielago cubierto de niebla. Run corta (5-8 min): moverse para esquivar, pararse para disparar, elegir 1 de 3 mejoras al subir de nivel.
1. **Parar = disparar, mover = esquivar.** Todo el juego es ese compromiso.
2. **Todo se lee.** Cada ataque avisa, la camara nunca tapa, los efectos nunca esconden patrones.
3. **Cada run distinta.** Elecciones de 3 opciones; la build se nota en las flechas.
4. **Servidor manda, movil primero.** Un dedo, 30 FPS estables en gama media-baja.
5. **Honesto.** Sin azar pagado, sin ventaja pagada, sin urgencia falsa.

## 2. Preguntas de diseno con respuesta por defecto
| # | Tema | Default |
|---|---|---|
| 1 | Controles movil | Joystick izquierdo flotante (propio, Frame + toque); sin boton de disparo. Esquiva = v1.1, no MVP. |
| 2 | PC/gamepad | WASD y stick izquierdo; sin clic para disparar. Movimiento relativo a la camara. |
| 3 | Camara | Scriptable, 3/4 desde arriba, ~55 grados, altura ~38 studs, suavizado `1-exp(-k*dt)` en `BindToRenderStep`. Cerca de una pared se acerca; nunca atraviesa ni tapa. |
| 4 | Arena | 64x64 studs por sala (celdas de 8); jefe 96x96; puerta 16 studs. |
| 5 | Umbral parar-disparar | Velocidad horizontal < 0.5 studs/s durante >= 0.12 s [medir]; lo decide el servidor, con histeresis. |
| 6 | Autoapuntado | Enemigo vivo mas cercano con linea de vision; empate = menor id. Servidor lo elige y lo publica en un atributo; aro visible en el blanco. Ajuste: "ultimo blanco". |
| 7 | Cadencia | 1.0 disparo/s base (dato, no codigo); el cliente nunca pide disparar. |
| 8 | Tope enemigos | <= 24 vivos por sala, <= 8 con IA completa; el resto piensa a 2 Hz. |
| 9 | Tope proyectiles | Jugador <= 24 vivos, enemigos <= 40; si se llena no se crea (el dano igual lo decide el servidor). |
| 10 | Tiempos de aviso | Normal 0.5-0.8 s; area/carga 0.8-1.0 s; jefe 1.0-1.4 s. Minimo 0.4 s. Zona de peligro dibujada en el suelo. |
| 11 | Colisiones | Nara y enemigos: circulo 2D (radio 1.5 / 1.2). Paredes: raycast con grupo "Paredes". Flechas: sin fisica, raycast + circulo-segmento. Cero `Touched`. |
| 12 | Acumulacion | Campo `stack` de la tabla: `uno`, `suma(max)`. Misma funcion pura `calcular(base, skills)` en cliente y servidor. |
| 13 | Sorteo | 3 ids distintos; pesos comun 70 / rara 25 / epica 5; epica desde la sala 4; semilla por run. |
| 14 | Muerte | La run termina; recompensa parcial (50 %) UNA vez; vuelta al hub. |
| 15 | Revivir | 1 vez por run, gratis, 50 % de vida e invulnerable 2 s [medir]. Sin revivir de pago. |
| 16 | Coop | Fuera del MVP. Luego: vida enemiga escala por jugador, revivir entre amigos, botin por jugador. |
| 17 | Recompensas | Sala: monedas + XP. Fin de capitulo: cofre de recompensa fija y 1 skill desbloqueable. |
| 18 | Persistencia | Solo `monedas`, `mejorCapitulo`, `skillsDesbloqueadas`, version. La run vive en memoria del servidor. Guarda al terminar run y al salir. REVIEW(money). |
| 19 | UI | Vida arriba-izq, nivel/XP abajo, 3 tarjetas de skill al centro (en solo, el mundo se congela mientras eliges), safe areas, `UIScale`; texto en Title Case. |
| 20 | Audio | Sonidos originales: disparo, impacto, aviso (tono propio por enemigo), subir nivel, jefe. Musica suave en bucle; volumen SFX y musica separados. |
| 21 | Paleta | Coral #FF6F59, turquesa #2EC4B6, jade #3DA35D, amarillo calido #FFC857, violeta #7B5EA7, azul noche #1B2A41. Mate. |
| 22 | Limites moviles | <= 100 partes de flecha en pool, <= 100 particulas, 0-1 luz con sombra, < 150k triangulos, memoria < 800 MB, servidor <= 3 ms/frame [medir]. |
| 23 | Remotos | Lista en la seccion 6; todos tipados, con rate limit y validacion. |
| 24 | Pruebas | Lune para calculo puro + playtest dirigido en Studio (solo lo autorizado por la tarea). Ver seccion 4. |
| 25 | Terminado MVP | Run de 10 salas sin errores de consola, sin entidades huerfanas, recompensa una sola vez, legible en 3 pantallas. |
| 26 | Feedback | Pausa visual 0.04 s al golpear, destello, numero de dano legible, shake moderado (ajustable/apagable). |
| 27 | Monetizacion | Ninguna en el MVP. Despues solo cosmeticos de precio visible; nada de cajas ni azar con Robux (PolicyService). |

## 3. Alcance MVP
Un capitulo, **Archipielago de la Niebla**, 10 salas: combate x6 (1-6), altar de skill (7), mini-jefe (8), descanso que cura 30 % (9), jefe final (10). Un heroe (Nara), 3 armas, 6 enemigos, 2 jefes, 20 skills.

### Armas (se elige 1 al inicio; `shared/Weapons.luau`)
| id | Nombre | Comportamiento |
|---|---|---|
| bow | Arco de Faro | 1 flecha recta, rapida, dano medio. |
| twin | Ballesta Gemela | 2 virotes en paralelo, cadencia menor, dano bajo por virote. |
| sling | Honda de Rebote | Piedra lenta que rebota 2 veces en paredes; dano alto, cadencia lenta. |

### Enemigos (patron unico con aviso visible)
| id | Nombre | Patron y telegrafo |
|---|---|---|
| e1 | Muelle (cangrejo-farol) | Persigue lento; 0.6 s pinza arriba y circulo en el suelo, luego golpe corto. |
| e2 | Embestida (jabali de coral) | Se frena, rasca 0.9 s con linea roja hacia Nara, carga recta; 1 s aturdido al chocar con pared. |
| e3 | Abanico (planta espinosa) | Fija; brilla 0.7 s y lanza 5 espinas en abanico de 60 grados, una salva. |
| e4 | Charca (medusa de niebla) | Flota; marca un circulo 0.9 s y deja un charco 3 s que daña por pulso. |
| e5 | Eco (espiritu gemelo) | Parpadea 0.5 s marcando destino, salta y dispara 1 orbe lento. |
| e6 | Invocador (monje de faro) | Quieto; baston arriba 1.0 s e invoca 2 muelles; maximo 1 invocacion viva. |

### Jefes (la vida se resuelve una sola vez en servidor)
| id | Nombre | Fases |
|---|---|---|
| b1 | Guardian de Roca Hueca (sala 8) | F1 (100-50 %): carga + abanico de 7 rocas. F2 (<50 %): suma 3 columnas de lluvia marcadas 1.2 s. Ventana de dano: 2 s aturdido tras la carga. |
| b2 | Reina del Faro Apagado (sala 10) | F1: rayos giratorios lentos (lineas marcadas) + invoca e1. F2 (<66 %): anillos de orbes con hueco de 40 grados. F3 (<33 %): el faro se enciende, areas marcadas 1.4 s, ventana de dano 3 s tras cada barrido. |

### Habilidades (`shared/Skills.luau`)
| id | Nombre | Efecto generico | Rareza | Stack |
|---|---|---|---|---|
| s01 | Pulso Rapido | +15 % cadencia | comun | suma(5) |
| s02 | Punta Afilada | +20 % dano | comun | suma(5) |
| s03 | Corazon de Faro | +20 % vida maxima y cura igual | comun | suma(5) |
| s04 | Pies de Brisa | +10 % velocidad de movimiento | comun | suma(3) |
| s05 | Disparo Doble | +1 proyectil, 75 % dano c/u | rara | suma(2) |
| s06 | Flecha Lateral | +1 proyectil a 45 grados | rara | uno |
| s07 | Rebote | el proyectil rebota 1 vez mas | rara | suma(3) |
| s08 | Perforar | atraviesa 1 enemigo mas | rara | suma(3) |
| s09 | Veneno de Alga | dano por pulso 3 s | comun | suma(3) |
| s10 | Fuego Calido | quema 3 s, no se acumula | comun | uno |
| s11 | Escarcha | -20 % velocidad enemiga 2 s | comun | suma(2) |
| s12 | Critico Claro | +10 % prob. de critico (x2) | comun | suma(5) |
| s13 | Escudo de Niebla | absorbe 1 golpe, recarga 12 s | rara | uno |
| s14 | Marea Vital | cura 1 al matar | comun | suma(3) |
| s15 | Estampida | +cadencia 3 s tras matar | rara | uno |
| s16 | Rafaga Final | cada 5.o disparo lanza 3 flechas | epica | uno |
| s17 | Lluvia de Estrellas | cada 8 s cae un area de dano | epica | suma(2) |
| s18 | Segundo Aliento | revive extra 1 vez al 30 % | epica | uno |
| s19 | Ojo del Faro | +30 % dano a jefes | rara | uno |
| s20 | Iman de Brillo | atrae monedas y XP | comun | uno |
Reglas: s05+s06 no pasan de 5 proyectiles totales; s09 y s10 en la misma flecha: gana la ultima elegida. Campo opcional `requiere`. Todo es dato.

## 4. Fases de construccion (las 9 de research/15)
C = Claude (decide, integra, revisa todo diff); X = tarea Codex en `ROBLOX/docs/ai-tasks/arrow-faseN.md`; B = agente barato (solo inventario, revision read-only o 1 asset). Rutas relativas a `ROBLOX/games/arrow-rogue/`.
| Fase | Quien | Archivos exactos | Terminado cuando (medible) |
|---|---|---|---|
| 0 Auditoria/plan | C | `docs/GDD.md`, `docs/plan.md`, `tests/cases.md`, `ROBLOX/docs/ai-tasks/arrow-fase0.md` | Plan + 27 respuestas + archivos autorizados + 4 casos dirigidos escritos y revisados. |
| 1 Arena/camara/mov. | X, C revisa | `src/server/Arena.luau`, `src/client/Camera.luau`, `src/client/Input.luau`, `src/shared/Config.luau` | Movil, teclado y gamepad mueven; camara no se tapa en las 4 esquinas; arena y costa se leen en 3 resoluciones (movil chico, movil grande, PC). |
| 2 Combate basico | X | `src/server/Combat.luau`, `src/server/Projectiles.luau`, `src/shared/Weapons.luau`, `tests/combat.spec.luau` | Quieto dispara, mover pausa; blanco determinista; impacto y cadencia en servidor; prueba pasa; cliente no acelera cadencia. |
| 3 Seis enemigos | X (1 por tarea) | `src/server/Enemies/e1.luau` ... `e6.luau`, `src/server/EnemyService.luau` | Cada patron esquivable sin dano en escena controlada; 0 entidades huerfanas al limpiar sala. |
| 4 Habilidades | C (tabla) + X | `src/shared/Skills.luau`, `src/server/Skills.luau`, `src/client/SkillCards.luau`, `tests/skills.spec.luau` | 20 skills con texto, efecto real en servidor e icono; 0 incompatibles activos; prueba: 3 opciones, elegir 1, aplicar 1 vez. |
| 5 Dos jefes | X, C disena patrones | `src/server/Bosses/b1.luau`, `b2.luau`, `tests/boss.spec.luau` | Cada ataque esquivable con tactil y teclado; vida/muerte resuelta 1 vez; ventanas de dano medidas. |
| 6 Sala/capitulo/recompensa | X + C | `src/server/RunService.luau`, `src/server/Rooms.luau`, `src/server/Rewards.luau` | Run de 10 salas completa y reinicia; recompensa 1 sola vez; sin softlock en muerte ni reconexion. REVIEW(money). |
| 7 Arte/UI/audio | C + Ropilot; B inventario | `assets/`, `src/client/Hud.luau`, `docs/art-bible.md` | Checklist de la seccion 5 completo; legible en movil real. |
| 8 Perfilado/revision | C (+B read-only) | `docs/perf-report.md` | Estres (24 enemigos + 24 flechas + efectos) 5 min sin errores ni fugas; se registra dispositivo, ms y resultado. No prometer FPS sin medir. |
Pruebas (solo las autorizadas por la tarea): (1) Lune: dano, cooldown, valores invalidos; (2) servidor: quieto dispara, mover suspende, cliente no elige dano; (3) skill: 3 opciones, 1 aplicada; (4) jefe/sala: esquiva, recompensa unica, reinicio; (5) manual en Studio movil y PC.

## 5. Biblia de arte (Ropilot) y checklist anti-errores
Ropilot para TODO el arte. Si no esta conectado: documentar el bloqueo y dejar prompts, nunca bloques cuadrados como final. Pedir permiso antes de subir imagenes a Roblox.
- **Forma:** siluetas redondas, bordes suaves, detalles grandes; legible a tamano de icono. **Color:** paleta de la fila 21, saturada, materiales mate. **Acabado:** juguete pintado de alta calidad; iconos con contorno grueso.
- **Escala:** Nara 5 studs; enemigos 3-6; jefes 14-18; arbol de decorado maximo ~3x Nara; suelo modular 8x8.
- **Por asset:** prompt con vista superior y 3/4, escala Roblox, pivote en la base, dimensiones, colision Box, materiales, paleta, LOD si hace falta. Se inspecciona en Studio sobre suelo y junto a Nara; si falla, se rechaza y regenera.
Checklist (todo "si" para pasar):
1. Nada flotando: cada pieza asentada en el suelo (raycast/offset revisado).
2. Relieve con malla o terreno continuo; nunca esferas pegadas como terreno.
3. Agua con fondo visible y costa legible.
4. Arboles con escala medida contra Nara y la camara.
5. Camara probada en paredes, esquinas y jefes: nunca tapa a Nara ni a las amenazas.
6. UI sin solapes ni texto cortado en movil chico, movil grande, PC y gamepad, con safe areas.
7. Ningun efecto esconde un telegrafo.

## 6. Remotos y reglas de servidor
Modulo tipado `src/shared/Remotes.luau`, un solo folder de remotos, rate limit por jugador en cada entrada, `--!strict`.
**Entrantes (cliente -> servidor):**
| Remoto | Datos | Validacion |
|---|---|---|
| `MoveIntent` (Unreliable) | Vector2 | finito, longitud <= 1, <= 20/s |
| `StartRun` | weaponId:string | existe en Weapons, jugador en hub, sin run activa |
| `PickSkill` | entero 1-3 | hay opciones pendientes; una sola vez |
| `EnterDoor` | - | sala limpia, estado correcto |
| `SetSetting` | clave, valor | lista blanca de claves y rangos |
| `Dodge` (v1.1) | - | cooldown en servidor |
**Salientes (servidor -> cliente):**
| Remoto | Datos |
|---|---|
| `RunState` | sala, vida, nivel, xp, estado (hub/combate/jefe/fin) |
| `SkillOptions` | {id, id, id} |
| `SkillsApplied` | lista de ids de la run |
| `Shot` (Unreliable) | origen, direccion, velocidad, tipo, t0 (`GetServerTimeNow`), id |
| `ProjectileDead` | id |
| `Telegraph` | tipo, pos, forma, duracion, t0 |
| `Damage` | objetivoId, cantidad, critico |
| `EnemySpawned` / `EnemyDied` | id, tipo, pos (movimiento por modelos anclados; Plan B 10 Hz) |
| `RunEnd` | victoria/derrota, recompensa |
**Reglas de autoridad:**
- Servidor decide movimiento valido (tope 1.5x WalkSpeed y limites de sala), blanco, cadencia, impacto, dano, drops, XP, sorteo de skills, recompensas y fin de run. El cliente solo manda intencion y dibuja.
- Nunca confiar en posicion, blanco o dano del cliente. Validar tipo, vivo, distancia, cadencia, valores finitos.
- Un solo bucle Heartbeat para enemigos y proyectiles; cero `Touched`; flechas son datos, no Instances (pool visual).
- Recompensa y guardado una sola vez por `runId`. Un unico `ProcessReceipt` (el de `Shop.luau`); no crear otro. `REVIEW(money)` en todo cambio de monedas o datos persistentes.

## 7. Riesgos
Joystick propio tactil (hay que dibujarlo); replicar 24 modelos anclados (Plan B a 10 Hz); cifras sin calibrar [medir]; sin pruebas aun en movil real.
