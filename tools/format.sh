#!/usr/bin/env bash
# Formatea (o comprueba) el codigo Luau con StyLua usando stylua.toml.
#
# Uso:
#   tools/format.sh                 # reformatea todo el proyecto (excluye research/, .toolchain/, venv/...)
#   tools/format.sh --check         # no modifica nada; sale con 1 si algo no esta formateado
#   tools/format.sh tools/testkit   # solo una carpeta o archivos concretos
set -uo pipefail
# shellcheck source=tools/env.sh
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

check=0
paths=()
for arg in "$@"; do
	case "$arg" in
	--check) check=1 ;;
	-h | --help)
		sed -n '2,8p' "${BASH_SOURCE[0]}"
		exit 0
		;;
	*) paths+=("$arg") ;;
	esac
done

require_tool stylua || exit 2
mapfile -t paths < <(abs_paths "${paths[@]}")
cd "$ROOT" || exit 2

mapfile -t files < <(find_luau_files "${paths[@]}")
if [ "${#files[@]}" -eq 0 ]; then
	echo "No hay archivos .luau/.lua que formatear"
	exit 0
fi

if [ $check -eq 1 ]; then
	stylua --check "${files[@]}"
else
	stylua "${files[@]}" && echo "Formateados ${#files[@]} archivo(s)"
fi
