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
	codex review --commit "$sha" </dev/null > "$f" 2>&1; echo "Revisión: $f"; exit 0
fi
task="${1:?falta la ruta de la tarea}"
name="$(basename "$task" .md)"
root="$(git rev-parse --show-toplevel)"
wt="$root/../$(basename "$root")-codex-$name"
out="$root/ROBLOX/.toolchain/codex"
mkdir -p "$out"
[ -d "$wt" ] || git -C "$root" worktree add -q -b "codex/$name" "$wt" HEAD
codex exec -C "$wt" -s workspace-write -o "$out/$name.md" "$(cat "$root/$task")" </dev/null
echo "Informe de Codex: $out/$name.md"
git -C "$wt" status --short
echo "Revisar con: git -C \"$wt\" diff   ·   aceptar: git merge codex/$name (tras pruebas)   ·   descartar: git worktree remove \"$wt\" && git branch -D codex/$name"
