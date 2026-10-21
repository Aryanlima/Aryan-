# 001 — Que la prueba de Node funcione desde Lune en Windows

Estado: PENDIENTE
Asignada a: Codex
Creada por: Claude, 2026-10-21

## Objetivo
En Windows, `bash ROBLOX/tools/test.sh` da FALLO en `tools/wire-ids.spec.luau`, pero `node --test ROBLOX/tools/*.test.mjs` pasa 52 de 52 cuando se ejecuta directo. Hay que encontrar la causa y arreglarla. Además, cuando falle, la prueba debe imprimir la salida de node.

## Alcance (solo estos archivos)
- `ROBLOX/tools/wire-ids.spec.luau`

## Fuera de alcance
- `*.mjs`, el código del juego y el testkit.

## Criterios de aceptación
- [ ] En Windows (Git Bash), `bash ROBLOX/tools/test.sh` pasa `tools/wire-ids.spec.luau`.
- [ ] Si node falla de verdad, el mensaje de la prueba incluye su stdout/stderr (truncado a ~2.000 caracteres).
- [ ] En Linux (CI) sigue pasando; no se rompe el `skip` cuando falta node.
- [ ] Lint y formato limpios.

## Contexto útil
`ROBLOX/docs/playtest-1.md`, sección "Pruebas y lint en Windows". Sospecha: `process.exec("node.exe", {"--test", <rutas>})` desde Lune (las rutas, el cwd o el shell).
