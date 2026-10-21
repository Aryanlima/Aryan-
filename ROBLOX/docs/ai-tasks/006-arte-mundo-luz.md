# 006 — Dirección de arte: mundo e iluminación
Estado: PENDIENTE · Asignada a: Codex · Alcance: SOLO ROBLOX/games/fish-and-fortune/src/server/WorldBuilder.luau (conserva canFishAt, WorldInfo, SpawnLocation y la geometría del agua/muelle de las pruebas)
Aplica del brief los puntos 1 a 5 (paleta, muelle, borde de la laguna, profundidad del agua, cielo e iluminación). Además, de la investigación de Claude sobre juegos top (Fish It!, Fisch):
- Fondo con profundidad: siluetas de colinas e islas lejanas (Parts/Terrain grandes, colores más fríos y claros con la distancia) y nubes (Terrain.Clouds o Parts), para que no se vea el borde del mundo.
- Iluminación de atardecer dorado con SunRaysEffect suave, DepthOfFieldEffect muy ligero y ColorCorrection cálido; nada de cian eléctrico.
- Vida: unos pocos peces que saltan del agua cada pocos segundos (Parts pequeñas con Tween, máx. 3 a la vez), pájaros lejanos o libélulas con partículas, linternas encendidas.
- El muelle debe ser el foco: más ancho y claro, con luz cálida, que guíe la mirada hacia el agua.
Lee primero AGENTS.md, ROBLOX/docs/GDD.md y ROBLOX/docs/brief-diseno-codex.md (brief de dirección de arte de Codex sobre una captura real del juego). Luau --!strict, solo piezas procedurales, SIN IDs de assets inventados, rendimiento móvil, no toques la lógica de servidor ni nada que no esté en tu alcance. Formatea con `bash ROBLOX/tools/format.sh` si puedes; no hace falta correr la suite completa (Claude la verifica). Informe final máximo 10 líneas.
