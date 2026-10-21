# 003 — Mundo visual de Fish & Fortune
Estado: PENDIENTE · Asignada a: Codex · Alcance: solo ROBLOX/games/fish-and-fortune/src/server/WorldBuilder.luau (y pruebas de estructura si cambian nombres)

El dueño dice que el mundo "se ve malísimo": agua = placa de vidrio sobre un suelo de Part 200x200 y árboles de bloques. Objetivo: nivel de Fish It!/Fisch.
- Usa Terrain en tiempo de ejecución (Workspace.Terrain:FillBlock/FillCylinder/FillBall; materiales Grass, Sand, Rock, Mud, Water; WaterColor/WaterTransparency/WaterWaveSize/WaterWaveSpeed/WaterReflectance) para suelo, orillas de arena, rocas y agua real en las 3 zonas.
- MANTÉN la geometría que asume `WorldBuilder.canFishAt` (lago disco centro origin+(0,-45) radio 55; río |x|<=30, z de -125 a 45; mar z<-20, |x|<=90; muelle |x|<=4.5, z de -41 a 2, cubierta y≈1.2). No cambies canFishAt, WorldInfo (spawns, castTargets) ni el SpawnLocation.
- Muelle de tablones con barandas y postes, farol con PointLight, barca amarrada, cajas y barriles, rocas, árboles mejores (tronco + varias copas con colores variados; palmeras en la costa), arbustos y flores, cartel de zona legible, cartel/flecha "Fish here!" hacia el muelle.
- Iluminación cálida de tarde (Atmosphere, Sky, ColorCorrection, Bloom suaves), bien en móvil.
- Rendimiento: pocos miles de Parts como máximo, Anchored, CanCollide solo donde se camina, CastShadow=false en detalles.
- Respeta el proveedor de arte opcional (art) como ya hace el código.
Lee primero AGENTS.md y ROBLOX/docs/GDD.md (§4 dirección de arte y paleta: agua #2EC4F1, madera #C98A4B, oro #FFC83D, coral #FF5A5F, UI azul noche #1E2A44). Luau --!strict. Verifica con `bash ROBLOX/tools/test.sh`, `bash ROBLOX/tools/lint.sh` y `bash ROBLOX/tools/format.sh` (formatea) desde la raíz del repo; borra carpetas `.governor/` dentro de ROBLOX/ antes de probar. No uses IDs de assets inventados. No publiques nada. Haz commit en tu rama con mensaje en español. Informe final de máximo 12 líneas con el resultado REAL de las pruebas.
