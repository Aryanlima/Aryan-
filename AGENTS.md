# AGENTS.md (Codex y otros agentes)

Repo de juegos de Roblox con microtransacciones. Todo lo de Roblox vive en `ROBLOX/`. Reglas completas en `CLAUDE.md`. Este archivo es el resumen para Codex.

- **Tu papel (Codex):** revisar código, buscar errores de lógica, seguridad y rendimiento, hacer SOLO la tarea que te den en `ROBLOX/docs/ai-tasks/NNN-*.md` y mejorar pruebas. No cambies la arquitectura ni toques archivos fuera del alcance de la tarea.
- **Coordina Claude:** él decide, revisa tu diff y lo acepta o lo rechaza. Trabajas en tu propia rama `codex/<tarea>` (worktree); nunca hagas commit en `claude/*`, `pc/aryan-local` ni `main`.
- **Luau:** `--!strict`, servidor autoritativo, validar cada RemoteEvent y un único `ProcessReceipt` idempotente. Marca con `REVIEW(money)` lo que toque dinero o datos.
- **Comprobar antes de terminar** (desde Git Bash): `bash ROBLOX/tools/test.sh`, `bash ROBLOX/tools/lint.sh` y `bash ROBLOX/tools/format.sh --check`. Si no puedes ejecutar algo, dilo; nunca digas que pasó si no se ejecutó.
- **Prohibido:** secretos en archivos, publicar o hacer pública una experiencia, gastar Robux e inventar IDs de assets o APIs.
- **Informe final** (máximo 10 líneas): qué cambiaste, archivos, pruebas ejecutadas y su resultado real, y dudas.
- Skills de Roblox para Codex: `~/.agents/skills` (roblox-luau, roblox-security, roblox-code-review, roblox-testing…).
