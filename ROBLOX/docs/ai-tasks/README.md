# Tareas para agentes (Claude → Codex)

1. Claude copia `TEMPLATE.md` como `NNN-nombre-corto.md` (por ejemplo `002-ui-banner.md`) y rellena el alcance y los criterios de aceptación.
2. Lo delega con `bash ROBLOX/tools/codex-task.sh ROBLOX/docs/ai-tasks/NNN-nombre.md`. El script crea el worktree `../Aryan--codex-NNN-nombre`, la rama `codex/NNN-nombre` y ejecuta `codex exec`. El informe queda en `ROBLOX/.toolchain/codex/`.
3. Claude revisa el diff (`git -C <worktree> diff`), corre las pruebas y **acepta** (merge), **corrige** o **rechaza** (borra el worktree y la rama). Nunca se acepta nada sin revisarlo.
4. Se anota el resultado en `ROBLOX/docs/AI_HANDOFF.md` y se cambia `Estado:` en la tarea.

Para que Codex revise un commit de Claude sin editar nada: `bash ROBLOX/tools/codex-task.sh --review <commit>`.

Reglas: una tarea = un objetivo pequeño. Claude y Codex no tocan los mismos archivos a la vez; si hay solape, se espera.
