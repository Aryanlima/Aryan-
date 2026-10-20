# Prompt para la sesión del PC: primer playtest de Fish & Fortune

Cuándo usarlo: la sesión del PC ya tiene Studio, Rojo y el MCP funcionando (ver [estado-pc.md](estado-pc.md)). Se pega tal cual en la sesión de Claude Code que corre en tu PC, dentro de la carpeta `Aryan-`.

```
Hola. Soy Aryan. La nube actualizó la rama claude/brave-meitner-esyqy8: ahora todo lo de Roblox está bajo ROBLOX/, hay un primer juego (Fish & Fortune) y más de 420 pruebas. Tu trabajo ahora es el PRIMER PLAYTEST en Studio y SOLO INFORMAR: no edites el código del juego (la nube lo sigue modificando y se mezclarían los cambios).

Reglas: responde en español y simple (no soy programador). No pongas claves en archivos ni en el chat. No compres nada real con Robux. No uses execute_luau salvo para consultas de solo lectura. Commits solo en la rama pc/aryan-local.

Pasos:
1. Trae lo último de la nube sin perder lo tuyo: `git fetch origin` y `git merge origin/claude/brave-meitner-esyqy8`. Si hay conflictos, conserva la versión de la nube salvo en tus archivos estado-pc.md y pc-investigacion/. El rokit.toml de la raíz ya no hace falta (el oficial está en ROBLOX/rokit.toml): bórralo si estorba. Comprueba que existe el archivo .gitattributes (fuerza saltos de línea LF) y, si hace falta, vuelve a extraer los archivos para que no queden con CRLF.
2. Dentro de ROBLOX/ ejecuta `rokit install`. Luego, en Git Bash: `bash ROBLOX/tools/test.sh`, `bash ROBLOX/tools/lint.sh` y `bash ROBLOX/tools/format.sh --check`. Dime los resultados REALES (se esperan 420 o más pruebas en verde). Si algo falla en Windows y no en la nube, es un hallazgo importante: diagnostícalo y repórtalo, sin parchear el juego.
3. Abre el juego en Studio con Rojo: `rojo serve ROBLOX/games/fish-and-fortune/default.project.json` y conecta el plugin de Rojo en Studio. Con el MCP de Studio: lee el árbol del juego (search_game_tree) y comprueba que el mundo y los scripts quedaron en su sitio (ServerScriptService, ReplicatedStorage, StarterPlayerScripts). Inicia el juego (start_stop_play), lee la consola (get_console_output) y toma capturas (screen_capture).
4. Sigue el checklist de playtest de ROBLOX/games/fish-and-fortune/README.md: tutorial y primeros 60 segundos (primera captura y primera venta en 60 s o menos), minijuego de lanzamiento, venta, bestiario, zonas, banner global, eventos, tienda (solo abrirla y mirar, sin comprar), panel de Probabilidades y que no aparezca nada de suerte comprable (Suerte+ y Cebo de Suerte están apagados a propósito en la v1).
5. Anota TODO error o advertencia de la consola con archivo y línea, y qué hiciste para provocarlo. Los IDs de pases y productos valen 0 (TODO_ID): indica qué pasa al intentar comprar.
6. Escribe el informe en ROBLOX/docs/playtest-1.md con una tabla: paso del checklist | OK, FALLA o NO PROBADO | evidencia (consola o captura) | notas. Commitéalo SOLO en la rama pc/aryan-local y súbelo con `git push -u origin pc/aryan-local`.

Cuando termines, dime en 5 líneas qué funcionó, qué falló y qué sigue.
```

La nube lee el informe en la rama `pc/aryan-local`, así que no hace falta pegárselo de vuelta. Después de ese informe, la nube arregla lo que falle y se repite el ciclo.
