#!/usr/bin/env bash
# Analisis estatico del codigo Luau: selene (lint) + stylua --check (formato) + comprobacion de tipos.
#
# Uso:
#   tools/lint.sh                  # todo el proyecto
#   tools/lint.sh tools/testkit    # solo una carpeta o archivos
#   tools/lint.sh --no-types       # sin la comprobacion de tipos
#   tools/lint.sh --no-format      # sin stylua --check
#
# Comprobacion de tipos (en este orden de preferencia):
#   1. luau-lsp analyze  + definiciones de Roblox ($TOOLCHAIN/share/globalTypes.d.luau)
#   2. luau-analyze      (Luau "puro": no conoce game/Instance/warn...; por eso solo se pasa a tools/)
#   3. si no hay ninguno, se omite con un aviso.
#
# Codigo de salida: 0 si todo esta limpio; 1 si algun paso falla.
set -uo pipefail
# shellcheck source=tools/env.sh
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

do_types=1
do_format=1
paths=()
for arg in "$@"; do
	case "$arg" in
	--no-types) do_types=0 ;;
	--no-format) do_format=0 ;;
	-h | --help)
		sed -n '2,15p' "${BASH_SOURCE[0]}"
		exit 0
		;;
	*) paths+=("$arg") ;;
	esac
done

cd "$ROOT" || exit 2
mapfile -t files < <(find_luau_files "${paths[@]}")
if [ "${#files[@]}" -eq 0 ]; then
	echo "No hay archivos .luau/.lua que analizar"
	exit 0
fi

failed=0
step() { printf '\n== %s ==\n' "$1"; }

step "selene (${#files[@]} archivos)"
if require_tool selene; then
	selene --display-style=rich "${files[@]}" || failed=1
else
	failed=1
fi

if [ $do_format -eq 1 ]; then
	step "stylua --check"
	if require_tool stylua; then
		stylua --check "${files[@]}" || {
			echo "Hay archivos sin formatear: ejecuta tools/format.sh" >&2
			failed=1
		}
	else
		failed=1
	fi
fi

if [ $do_types -eq 1 ]; then
	if command -v luau-lsp >/dev/null 2>&1 && [ -f "$GLOBAL_TYPES" ]; then
		step "luau-lsp analyze (tipos + definiciones de Roblox)"
		luau-lsp analyze --definitions="$GLOBAL_TYPES" "${files[@]}" || failed=1
	elif command -v luau-analyze >/dev/null 2>&1; then
		step "luau-analyze (solo tools/: Luau puro, sin tipos de Roblox)"
		mapfile -t pure < <(printf '%s\n' "${files[@]}" | grep -E "^$ROOT/tools/" || true)
		if [ "${#pure[@]}" -gt 0 ]; then
			luau-analyze --formatter=gnu "${pure[@]}" || failed=1
		else
			echo "(nada que analizar bajo tools/)"
		fi
		echo "Aviso: sin luau-lsp no se comprueba el codigo de Roblox (game, Instance...)."
	else
		echo
		echo "Aviso: no hay luau-lsp ni luau-analyze; se omite la comprobacion de tipos (ver tools/setup.sh)."
	fi
fi

echo
if [ $failed -eq 0 ]; then
	echo "lint: OK"
else
	echo "lint: FALLO" >&2
fi
exit $failed
