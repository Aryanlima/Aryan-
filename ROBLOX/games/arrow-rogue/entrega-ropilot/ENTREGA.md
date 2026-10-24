# ENTREGA Ropilot · Brumaflecha: Asedio de los Faros

Ruta: C:\Users\Administrator\Desktop\Aryan-\ROBLOX\games\arrow-rogue\entrega-ropilot

## Estado de lotes
- Lote 1 (enemigos y jefes): EN CURSO. 8 modelos hechos, revisados en Blender e importados a Studio con rig Motor6D. Animaciones: cangrejo hecho (5); faltan 7 criaturas.
- Lotes 2 a 8: pendientes.

## Notas técnicas
- Kit de arena: está en Workspace directamente (Workspace.Kit_*), no en Workspace.Extras.Kit.
- Los enemigos se dejan en Workspace.Extras.Enemigos (fila en X=0..105, Z=440, Y suelo=-298.25).
- Rig de cada enemigo: HumanoidRootPart (Part invisible, anclado) -> Motor6D "Joint" en cada parte móvil; AnimationController + Animator. Animaciones en <Model>.Animations, KeyframeSequences en <Model>.AnimSaves.
- Todas las mallas usan un atlas de paleta (blend/tex/BF_Palette.png, 512 px, 24 colores de la paleta de estilo); una textura compartida.
- Bisagras (pivotes de cada parte, en studs, Blender XYZ = Roblox X, -Z, Y): blend/rigdata.py.
- Animaciones: aviso 0.42 s (prioridad Action), ataque (Action), muerte (Action2), idle (Idle, loop), mover (Movement, loop).
- Capturas de Studio: el visor de Studio devolvía una imagen plana (#191a1f) en todos los intentos y luego Studio se desconectó. capturas/ está vacío: NO COMPROBADO en Studio.

## Piezas
| nombre | lote | .blend | render | dimensiones studs | triángulos | pivote | ruta Studio | IDs | estado |
|---|---|---|---|---|---|---|---|---|---|
| Kit_CangrejoFarol | 1 | blend/Lote1_Enemigos.blend | renders/Kit_CangrejoFarol.png | 4.1 x 3.5 x 3.6 (X x alto x Z) | 11178 (máx. 5730 por malla) | base centrada, suelo | Workspace.Extras.Enemigos.Kit_CangrejoFarol | textura atlas rbxassetid://84743793906612; mallas: no registradas; anims: CangrejoFarol_Idle=rbxassetid://89131058682010, _Mover=85387701504771, _Aviso=72882401037051, _Ataque=74477280928446, _Muerte=91292126952213 | aprobado (Blender); Studio no comprobado |
| Kit_JabaliCoral | 1 | blend/Lote1_Enemigos.blend | renders/Kit_JabaliCoral.png | 2.5 x 3.9 x 5.3 (X x alto x Z) | 6818 (máx. 2384 por malla) | base centrada, suelo | Workspace.Extras.Enemigos.Kit_JabaliCoral | textura atlas rbxassetid://84743793906612; mallas: no registradas; anims: pendiente | modelo aprobado (Blender); animaciones pendientes; Studio no comprobado |
| Kit_PlantaEspinosa | 1 | blend/Lote1_Enemigos.blend | renders/Kit_PlantaEspinosa.png | 3.2 x 3.8 x 2.7 (X x alto x Z) | 5470 (máx. 2660 por malla) | base centrada, suelo | Workspace.Extras.Enemigos.Kit_PlantaEspinosa | textura atlas rbxassetid://84743793906612; mallas: no registradas; anims: pendiente | modelo aprobado (Blender); animaciones pendientes; Studio no comprobado |
| Kit_MedusaNiebla | 1 | blend/Lote1_Enemigos.blend | renders/Kit_MedusaNiebla.png | 3.0 x 3.5 x 3.0 (flota 0.8) (X x alto x Z) | 8940 (máx. 3192 por malla) | base centrada, suelo | Workspace.Extras.Enemigos.Kit_MedusaNiebla | textura atlas rbxassetid://84743793906612; mallas: no registradas; anims: pendiente | modelo aprobado (Blender); animaciones pendientes; Studio no comprobado |
| Kit_EspirituGemelo | 1 | blend/Lote1_Enemigos.blend | renders/Kit_EspirituGemelo.png | 5.2 x 4.4 x 2.2 (X x alto x Z) | 4120 (máx. 1654 por malla) | base centrada, suelo | Workspace.Extras.Enemigos.Kit_EspirituGemelo | textura atlas rbxassetid://84743793906612; mallas: no registradas; anims: pendiente | modelo aprobado (Blender); animaciones pendientes; Studio no comprobado |
| Kit_MonjeFaro | 1 | blend/Lote1_Enemigos.blend | renders/Kit_MonjeFaro.png | 2.7 x 5.2 x 2.0 (X x alto x Z) | 5720 (máx. 1890 por malla) | base centrada, suelo | Workspace.Extras.Enemigos.Kit_MonjeFaro | textura atlas rbxassetid://84743793906612; mallas: no registradas; anims: pendiente | modelo aprobado (Blender); animaciones pendientes; Studio no comprobado |
| Kit_GuardianRocaHueca | 1 | blend/Lote1_Enemigos.blend | renders/Kit_GuardianRocaHueca.png | 14.0 x 15.7 x 6.5 (X x alto x Z) | 10660 (máx. 3470 por malla) | base centrada, suelo | Workspace.Extras.Enemigos.Kit_GuardianRocaHueca | textura atlas rbxassetid://84743793906612; mallas: no registradas; anims: pendiente | modelo aprobado (Blender); animaciones pendientes; Studio no comprobado |
| Kit_ReinaFaroApagado | 1 | blend/Lote1_Enemigos.blend | renders/Kit_ReinaFaroApagado.png | 10.0 x 17.3 x 10.0 (X x alto x Z) | 13990 (máx. 4604 por malla) | base centrada, suelo | Workspace.Extras.Enemigos.Kit_ReinaFaroApagado | textura atlas rbxassetid://84743793906612; mallas: no registradas; anims: pendiente | modelo aprobado (Blender); animaciones pendientes; Studio no comprobado |

## Incidencia Studio
Studio se desconectó y al volver el lugar abierto (place 0, sin publicar) tiene el Workspace vacío (solo Terrain y Camera) y ReplicatedStorage solo con Packages y Shared: no están el kit, las animaciones de Nara ni los 8 enemigos importados. Las mallas, la textura y las 5 animaciones del cangrejo siguen subidas a la cuenta; los modelos siguen en blend/Lote1_Enemigos.blend y se pueden volver a importar. Las rutas de Studio de la tabla quedan NO COMPROBADAS hasta reabrir el lugar correcto.

## Pendientes
1. Animaciones (idle, mover, aviso, ataque, muerte) de Jabalí, Planta, Medusa, Espíritu, Monje, Guardián y Reina.
2. Capturas de Studio de los 8 enemigos junto a Nara (no comprobado).
3. Registrar los MeshId de cada parte en esta tabla (se leen en Studio).
4. Lotes 2–8.
