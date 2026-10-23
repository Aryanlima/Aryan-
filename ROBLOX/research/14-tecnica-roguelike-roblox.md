# 14 - Nota tecnica: roguelike de arquero tipo Archero en Roblox

Fecha: 2026-10-23. Solo investigacion, sin codigo. Meta: movil primero, servidor manda, muchos enemigos y proyectiles.
Marcas: [OFICIAL url] = confirmado en la doc oficial; [SKILL] = viene de las skills roblox-* locales; [DISENO] = decision/cifra mia, hay que medirla.
Base de docs: https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/ (abreviado DOCS/).

## Idea central
Mover y disparar parecen un juego de fisica, pero NO lo son: el jugador se mueve con el personaje normal (el cliente es dueno de su fisica), y todo lo demas (enemigos, flechas, dano, botin) es una simulacion logica en tablas del servidor, con una sola "malla" visual aparte en el cliente. Un solo bucle Heartbeat en el servidor, cero `Touched`, cero partes fisicas para proyectiles.

## 1. Movimiento y camara
- Camara fija desde arriba: `CameraType = Scriptable` y mover en `RunService:BindToRenderStep` (no Heartbeat), suavizar con `1 - exp(-k*dt)`. [SKILL roblox-input]
- Joystick movil: lo mas barato es dejar el control por defecto de Roblox (ya trae joystick tactil) y que el personaje se mueva con `Humanoid`. Para joystick propio: `InputAction` tipo `Direction2D` en un `InputContext` y `Workspace.PlayerScriptsUseInputActionSystem = Enabled`. [OFICIAL DOCS/input/input-action-system.md] OJO: esa pagina NO documenta un thumbstick tactil; solo botones tactiles (`UIButton`) y `TouchDelta`. Si se quiere joystick propio, hay que dibujarlo (Frame + `InputBegan/Changed` tactil) o usar `ContextActionService` con `Humanoid:Move()`. [DISENO]
- Con camara fija el movimiento debe ser relativo a la camara (arriba de pantalla = +Z mundo): pasar el vector por `Humanoid:Move(dir, false)`.
- Detectar "parado = dispara" EN EL SERVIDOR (el cliente no pide disparar nunca): cada Heartbeat leer `HumanoidRootPart.AssemblyLinearVelocity` horizontal (o diferencia de posicion en 0.1 s); parado si `< 0.5 studs/s` durante `>= 0.12 s` (histeresis para que no parpadee). Al estar parado y `ahora >= proximoDisparo` -> elegir blanco y disparar. Velocidad de ataque = datos, no codigo. [DISENO]
- Anti-trampa del movimiento: tope de velocidad horizontal (p. ej. 1.5x WalkSpeed) y limites de la sala; si se pasa, teletransportar a la ultima posicion buena. [SKILL roblox-security]
- Blanco: enemigo vivo mas cercano con linea de vision (1 raycast contra paredes solo para el candidato, no para todos). Cliente solo gira el torso hacia el blanco que el servidor publica en un atributo.

## 2. Proyectiles sin fisica
- [OFICIAL DOCS/reference/engine/classes/WorldRoot.yaml] `Raycast` (largo max 15000 studs, `CanQuery=false` se ignora; https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/workspace/raycasting.md), `Spherecast` (radio max 256, recorrido max 1024) y `Blockcast` (tamano max 512, recorrido max 1024). `GetPartBoundsInRadius` mira cajas, no formas exactas.
- Modelo: arrays paralelos (posicion, velocidad, dano, vida, dueno, rebotes, perforacion) en tablas Luau; NO una Instance por flecha. Un `Heartbeat` mueve todas: `nueva = pos + vel*dt`.
- Paredes: 1 `Raycast(pos, nueva-pos)` por flecha y por paso, con `RaycastParams` creado UNA vez (`FilterType=Include`, grupo de colision solo "Paredes" de la sala). Rebote = reflejar con `result.Normal`. Pasos grandes: subdividir si `vel*dt > radio`.
- Enemigos: NO raycast contra ellos. Rejilla espacial (celdas de 8 studs, clave entera `cx*1024+cz`): cada paso, probar la flecha solo contra enemigos de su celda y vecinas con prueba circulo-segmento. Coste ~O(flechas * 9 celdas). [DISENO]
- Con 40 enemigos y 60 flechas una rejilla gana poco frente a fuerza bruta (2400 pruebas baratas); activarla solo si el perfil lo pide (YAGNI), pero dejar la interfaz `grid:query(pos, r)`.
- Cliente: al disparar el servidor manda UN evento pequeno `{origen, direccion, velocidad, tipo, t0=GetServerTimeNow()}` (RemoteEvent, o buffer si hay mucho trafico); el cliente anima su flecha local con `pos = origen + dir*vel*(ahora - t0)`, sin recibir mas. Al impacto el servidor manda "murio flecha id" para cortar el visual. [SKILL roblox-networking] (`GetServerTimeNow` sincronizado).
- Visuales con pool: 1 `Part` anclada por flecha, `CanCollide/CanQuery/CanTouch=false`, `CastShadow=false`; reciclar (`Parent=nil` o mover lejos), nunca `Instance.new`/`Destroy` por disparo. Mover con `workspace:BulkMoveTo(partes, cframes, FireCFrameChanged)`. [SKILL roblox-performance]
- Tope duro: flechas jugador <= 24 vivas, enemigas <= 60; si se llena, no se crea (el dano no se pierde: lo decide el servidor igual).

## 3. Enemigos
- Un solo servicio, una tabla `enemigos[id]` con estado, y UN bucle. "Pensar" a 5-10 Hz escalonado (`id % 5 == frame % 5`), mover cada frame. [SKILL roblox-npc-ai]
- Maquina de estados minima: `Idle -> Chase -> Windup(tell) -> Attack -> Recover`, mas `Dead`. El "aviso" (tell) de 0.3-0.6 s es lo que hace justo el juego (esquivar mientras te paras). Datos por tipo: velocidad, dano, rango, tiempo de aviso, patron.
- Movimiento: salas abiertas -> "steering" simple (ir al jugador + separacion entre enemigos con la rejilla + empujon contra paredes con 1 raycast corto). `PathfindingService` solo para jefes o salas con laberinto; `ComputeAsync` cede y no se llama cada frame ni para todos; recalcular cada 0.5-1 s o al moverse el blanco mas de unos studs. [SKILL roblox-npc-ai]
- Cuerpo fisico: Parts ancladas movidas por el servidor (sin `Humanoid`; usa `AnimationController` si hay animacion). `Humanoid` por enemigo es caro; evitarlo.
- Replicacion: mover 40 modelos anclados desde el servidor manda posiciones cada frame. Plan A (empezar): asi. Plan B (si el panel de red lo exige): el servidor manda posiciones a 10-15 Hz por `UnreliableRemoteEvent` (<=1000 bytes por paquete, [SKILL roblox-networking]) y el cliente interpola modelos "titere". [DISENO]
- Topes y LOD: <= 40 enemigos vivos por sala (oleadas), <= 12 con IA "completa" cerca; los lejanos piensan a 2 Hz. Sin sombras ni particulas en los lejanos.
- Parallel Luau/Actors: NO al inicio. Solo si el MicroProfiler muestra `EnemyAI` > 2 ms por frame en servidor. Entonces: Actors por grupo de enemigos, calculo puro en fase paralela y `task.synchronize()` para escribir. [OFICIAL DOCS/scripting/multithreading.md] (requiere varios Actors para paralelismo real, `require` no se puede en fase paralela). Seguridad de hilos de `Raycast`: no pude confirmarla en la doc; [SIN VERIFICAR].

## 4. Salas y niveles
- Plantillas: carpetas `ServerStorage/Rooms/<bioma>/<sala_N>` (Model con `Floor`, `Walls`, `Spawns`, `Doors`, `PlayerStart`). Al entrar a una sala: `Clone()` -> `workspace.Sala_Actual`; al salir: `Destroy()` de la anterior tras 2 s. Solo UNA sala (mas la puerta de la siguiente) existe a la vez.
- Generador: lista fija de pasos por capitulo (p. ej. 10 salas: combate x7, tienda x1, evento x1, jefe) con una semilla; el servidor elige plantilla por reglas (sin repetir seguidas). Nada de laberintos grandes.
- Streaming: no hace falta `StreamingEnabled` con una sola sala pequena y clonada; si se activa, usar `ModelStreamingMode = Atomic`/`Persistent` para la sala. [OFICIAL DOCS/reference/engine/classes/Model.yaml] (la pagina de streaming que busque, `workspace/streaming.md`, no existe en esa ruta: [SIN VERIFICAR] valores por defecto de radio). Los raycast del servidor ignoran lo que el cliente no tiene cargado, asi que el servidor ve todo.
- Piso y paredes: Parts/MeshParts, NO Terrain (el Terrain es para mundos organicos; aqui son losas modulares, mas baratas y con colision predecible). Bloques de 16x16 o 8x8 studs, mismo `MeshId` repetido (se instancian). `CollisionFidelity=Box`, adornos con `CanQuery=false`. [SKILL roblox-performance]
- Kit modular con Ropilot/Blender (cuando se pueda): 8-12 piezas (suelo x3 variantes, pared recta/esquina/puerta, columna, adorno x4) con pivote en la esquina y rejilla de 8 studs; exportar con `ropilot_blender_import_model`. Regla del repo: pedir permiso antes de subir imagenes a Roblox.
- Cada sala marca sus paredes con `CollisionGroup = "Paredes"` para el raycast de proyectiles.

## 5. Habilidades (nivel y 3 opciones)
- Definiciones como DATOS en `shared/Skills.luau`: `{id, nombre_key, rareza, maxStacks, tags, mods = { {stat="dano", op="mul", valor=0.25} , ...}, requiere = {...}, peso}`. Operaciones: `add`, `mul`, `set`, y efectos con nombre (`multishot`, `rebote`, `perforar`, `veneno`) que lee el codigo de combate.
- Estadisticas finales = funcion pura `calcular(base, listaSkills)`: primero todos los `add`, luego `mul` acumulados, luego `set`. Misma funcion en cliente (para mostrar) y servidor (para aplicar) -> se prueba con Lune sin Roblox.
- Subida de nivel: el servidor sortea 3 ids distintos con `Random.new(seedRunNivel)` (pesos por rareza, excluye maxStacks y requisitos), guarda `opcionesPendientes` y envia `{ids}`. El cliente elige y manda SOLO el indice 1-3; el servidor valida que hay pendientes, que es un entero 1-3, aplica y limpia. Rate limit y tipo de argumento. [SKILL roblox-networking]
- Replicar: lista de ids de skills de la partida como atributo/evento de cambio (no stats completas por frame).
- Semilla por partida guardada = repetible para depurar y para el "reto diario".

## 6. Datos y dinero (reusar el repo)
- `ROBLOX/packages/Data.luau`: propio (UpdateAsync + bloqueo de sesion + reintentos + migraciones por version + validacion antes de guardar); su cabecera recomienda cambiarlo por ProfileStore con API parecida. Reusar tal cual: `Data.new{dataStore, schema{version, template, migrations}}`, `get(userId)`, `profile:markDirty()/save()/release()`. Esquema nuevo: `monedas`, `gemas`, `mejorasPermanentes`, `skillsDesbloqueadas`, `mejorCapitulo`, `purchases`. La PARTIDA (run) vive solo en memoria del servidor; al morir/ganar se pagan recompensas al perfil UNA vez.
- `ROBLOX/packages/Shop.luau`: UN `ProcessReceipt` idempotente por `PurchaseId`; concede + registra el id en el mismo perfil + guarda; solo devuelve `PurchaseGranted` tras confirmar el guardado. Reusar: catalogo `store-items.json` + `GrantHandler` por producto (p. ej. gemas, revivir, pase de temporada). Nunca vender poder dentro de una partida activa sin fuente gratis equivalente; evitar texto con urgencia/descuentos falsos (el validador del catalogo ya lo busca). Ver research/02 y 03.
- `Economy.luau` y `Odds.luau` para costos de mejoras y sorteos de cofres/skills (verificar las odds publicadas, politica de Roblox).
- Revisar siempre a mano los puntos marcados `REVIEW(money)`.

## 7. Presupuesto por frame (movil) [DISENO, medir]
Meta cliente 30-60 FPS en gama media-baja: 16.6 ms (60) / 33 ms (30). [SKILL roblox-performance]
| Parte | Servidor (ms) | Cliente (ms) |
|---|---|---|
| Bucle IA enemigos (40, pensar escalonado) | <= 1.0 | - |
| Proyectiles + rejilla (84 vivos) | <= 0.5 | - |
| Skills/dano/eventos | <= 0.3 | - |
| Visual de flechas (pool, <=100 partes) | - | <= 0.8 |
| Modelos enemigos (40 x <=40 partes) | - | <= 3 (CPU) |
| UI/HUD (solo al cambiar) | - | <= 0.5 |
Tope total servidor del juego: <= 3 ms de 16.6. Memoria cliente: apuntar a < 800 MB en movil. Particulas: <= 100 a la vez; luces con sombra: 0-1. Triangulos en pantalla: < 150k. Cada tope se pone como constante en `Config.luau` y se asserta en una prueba.
Como probar:
- Studio, Device Emulator (telefono/tablet) + Network Simulator (3G/4G, perdida de paquetes) [SKILL roblox-performance]; los modos Test / Test Here corren cliente y servidor separados. [OFICIAL DOCS/studio/testing-modes.md]
- MicroProfiler: Ctrl+F6 en Studio/cliente; en telefono Ajustes -> MicroProfiler On y abrir `IP:1338` desde la PC (30 frames por defecto, `/90` para mas); servidor: Consola de desarrollador (Ctrl+F9) -> MicroProfiler -> pestana Server, grabar hasta 60 frames; pausa en Studio con Ctrl+P. [OFICIAL DOCS/performance-optimization/microprofiler/index.md]
- Etiquetar: `debug.profilebegin("Enemies.think")`, `debug.setmemorycategory("Projectiles")`. Prueba de estres: "boton" de debug que llena la sala con 40 enemigos + 84 flechas, 60 s, y se mira el pico (no el promedio).

## 8. Estructura de modulos y tareas
Seguir el repo: juego en `ROBLOX/games/<nuevo>/` (p. ej. `games/arrow-rogue/`), paquetes comunes en `ROBLOX/packages/` (Data, Shop, Economy, Odds, Net, Locale, UI), archivo `default.project.json` de Rojo que apunta a `../../packages/*.luau`, pruebas Lune `*.spec.luau` + `tests/support/` (ServerHarness carga el codigo real con `luau.load` y dobles de `@testkit/mocks`). Correr: `bash ROBLOX/tools/test.sh`. Logica pura (sin Instances) para poder probarla.
```
games/arrow-rogue/
  default.project.json      (copiar el de fish-and-fortune)
  store-items.json  ids.example.json  README.md
  art/ (manifest.json, models/)   world/Extras/
  src/shared/  Config.luau  Skills.luau  Enemies.luau  Rooms.luau  Stats.luau(calcular)  Remotes.luau
  src/server/  Main.server.luau  RunService.luau(partida)  Combat.luau(bucle+proyectiles)  Grid.luau
               EnemyAI.luau  RoomManager.luau  SkillPicker.luau  Rewards.luau  Schema.luau
  src/client/  Main.client.luau  Camera.luau  Input.luau  ProjectileView.luau(pool)  Hud.luau  SkillMenu.luau
  tests/  Stats.spec  Skills.spec  Grid.spec  Projectiles.spec  EnemyAI.spec  SkillPicker.spec  Rewards.spec  support/
```
Tareas ordenadas (E = barato/Haiku-Codex, M = medio/Sonnet, A = Claude fuerte):
1. [A] Mini-GDD de 1 capitulo + `Config.luau` con topes y presupuesto (este doc como base).
2. [E] Copiar esqueleto de `fish-and-fortune` (project.json, README, tests/support) a `arrow-rogue`, cambiar nombres; `ProjectStructure.spec` pasa.
3. [M] `Stats.luau` + `Skills.luau` (datos) + specs Lune de apilado de modificadores.
4. [M] `Grid.luau` + `Projectiles.luau` puros (sin Instances) + specs: choque circulo-segmento, rebote, perforacion, topes.
5. [M] `SkillPicker.luau` (sorteo con semilla, validacion del indice) + spec.
6. [M] `EnemyAI.luau` estados puros + spec (aviso, persecucion, separacion).
7. [A] `Combat.luau` bucle Heartbeat que une 3-6, detector parado/en movimiento, atributos de blanco.
8. [E] `Remotes.luau` + validadores de argumentos + limites de tasa (copiar de `packages/Net.luau`).
9. [M] Cliente: camara fija, joystick, `ProjectileView` con pool, HUD, menu de 3 skills.
10. [M] `RoomManager` + 3 salas plantilla de prueba (cajas grises) -> luego kit de Ropilot.
11. [E] Esquema de datos en `Schema.luau` (copiar patron) + `Rewards.luau` que paga una vez + specs.
12. [A] Revision `REVIEW(money)` de Shop/Rewards + prueba de estres con MicroProfiler en emulador movil; ajustar topes.
13. [E] Textos con `Locale`; capturas para tienda; checklist de `ReleaseGate`.
Regla: pocas pruebas dirigidas por tarea; suite completa solo antes de commits criticos.

## Riesgos abiertos
Joystick tactil propio (no documentado); seguridad de hilos de Raycast; streaming por defecto; coste real de replicar 40 modelos anclados; todas las cifras de la seccion 7 son metas hasta medirlas en un telefono real.
