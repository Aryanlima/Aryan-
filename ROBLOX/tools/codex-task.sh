#!/usr/bin/env bash
# Delega una tarea a Codex en su propio worktree y rama (codex/<tarea>). No mezcla nada: Claude revisa y decide.
# Uso: bash ROBLOX/tools/codex-task.sh ROBLOX/docs/ai-tasks/001-nombre.md
#      bash ROBLOX/tools/codex-task.sh --review <commit>   (Codex revisa un commit de Claude; no edita nada)
set -euo pipefail
command -v codex >/dev/null || { echo "Codex no está instalado: npm install -g @openai/codex"; exit 1; }
if ! codex login status >/dev/null 2>&1; then echo "Codex sin sesión: ejecuta 'codex login' (cuenta de ChatGPT)"; exit 1; fi
if [ "${1:-}" = "--review" ]; then
	sha="${2:?falta el commit}"; mkdir -p "$(git rev-parse --show-toplevel)/ROBLOX/.toolchain/codex"
	f="$(git rev-parse --show-toplevel)/ROBLOX/.toolchain/codex/review-$sha.md"
	# En Windows el sandbox de solo lectura de Codex bloquea `git`: se le pasa el diff por stdin y no ejecuta nada.
	git show --stat --patch "$sha" -- . ':(exclude)*.png' | codex exec -s read-only --skip-git-repo-check -o "$f" 		"Revisa este commit de un juego de Roblox (Luau --!strict, servidor autoritativo). Lee AGENTS.md si lo necesitas. Busca SOLO problemas reales: errores de lógica, exploits o confianza en el cliente, pérdida de datos o de compras, regresiones y fallos de rendimiento. Para cada hallazgo: archivo:línea, gravedad (alta/media/baja), por qué falla y el arreglo propuesto. Si no hay problemas, dilo. Responde en español, máximo 25 líneas." >/dev/null 2>&1
	echo "Revisión: $f"; exit 0
fi
task="${1:?falta la ruta de la tarea}"
name="$(basename "$task" .md)"
root="$(git rev-parse --show-toplevel)"
wt="$root/../$(basename "$root")-codex-$name"
out="$root/ROBLOX/.toolchain/codex"
mkdir -p "$out"
[ -d "$wt" ] || git -C "$root" worktree add -q -b "codex/$name" "$wt" HEAD
# El sandbox de Windows de Codex corre con otro token: Git exige marcar la carpeta como segura.
git config --global --get-all safe.directory | grep -qxF "$(cd "$wt" && pwd -W)" || git config --global --add safe.directory "$(cd "$wt" && pwd -W)"
codex exec -C "$wt" -s workspace-write -o "$out/$name.md" "$(cat "$root/$task")" </dev/null
echo "Informe de Codex: $out/$name.md"
git -C "$wt" status --short
echo "Revisar con: git -C \"$wt\" diff   ·   aceptar: git merge codex/$name (tras pruebas)   ·   descartar: git worktree remove \"$wt\" && git branch -D codex/$name"
