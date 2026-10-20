#!/usr/bin/env bash
# Analisis estatico del codigo Luau: selene (lint) + stylua --check (formato) + comprobacion de tipos.
#
# Uso:
#   bash ROBLOX/tools/lint.sh                         # todo ROBLOX/
#   bash ROBLOX/tools/lint.sh ROBLOX/tools/testkit    # solo una carpeta o archivos
#   bash ROBLOX/tools/lint.sh --no-types              # sin la comprobacion de tipos
#   bash ROBLOX/tools/lint.sh --no-format             # sin stylua --check
#
# Se puede invocar desde cualquier carpeta; el script trabaja con ROBLOX/ como raiz (selene.toml,
# stylua.toml y .luaurc se resuelven desde ahi).
#
# Comprobacion de tipos (en este orden de preferencia):
#   1. luau-lsp analyze  + definiciones de Roblox ($TOOLCHAIN/share/globalTypes.d.luau) + SOURCEMAP de Rojo:
#      para cada games/<juego>/default.project.json se genera `rojo sourcemap --absolute` en
#      $TOOLCHAIN/sourcemaps/<juego>.json (ignorado por git) y se usa para analizar los archivos de ese juego.
#      Asi luau-lsp resuelve y tipa los `require(script.Parent:WaitForChild("X"))` por instancia: una ruta que no
#      exista en el arbol de Rojo es un error de analisis ("Unknown require"). El resto de archivos (packages/,
#      tests/, tools/) se analiza sin sourcemap. Hace falta `rojo` (setup.sh lo instala).
#   2. luau-analyze      (Luau "puro": no conoce game/Instance/warn...; por eso solo se pasa a tools/ de ROBLOX/)
#   3. si no hay ninguno, se omite con un aviso.
#
# Codigo de salida: 0 si todo esta limpio; 1 si algun paso falla.
set -uo pipefail
# shellcheck source=ROBLOX/tools/env.sh
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

do_types=1
do_format=1
paths=()
for arg in "$@"; do
	case "$arg" in
	--no-types) do_types=0 ;;
	--no-format) do_format=0 ;;
	-h | --help)
		sed -n '2,24p' "${BASH_SOURCE[0]}"
		exit 0
		;;
	*) paths+=("$arg") ;;
	esac
done

mapfile -t paths < <(abs_paths "${paths[@]}")
cd "$ROOT" || exit 2
mapfile -t files < <(find_luau_files "${paths[@]}")
if [ "${#files[@]}" -eq 0 ]; then
	echo "No hay archivos .luau/.lua que analizar"
	exit 0
fi

# Analiza con luau-lsp: los archivos de cada juego (games/<juego>/) con el sourcemap de su default.project.json y
# el resto sin sourcemap. Devuelve 1 si algun analisis falla o si hace falta rojo y no esta.
lsp_analyze_all() {
	local status=0
	local -a rest=("$@")
	local project game_dir game_name sourcemap file
	local -a game_files others
	for project in "$ROOT"/games/*/default.project.json; do
		[ -f "$project" ] || continue
		game_dir="$(dirname "$project")"
		game_name="$(basename "$game_dir")"
		game_files=()
		others=()
		for file in "${rest[@]}"; do
			case "$file" in
			"$game_dir"/*) game_files+=("$file") ;;
			*) others+=("$file") ;;
			esac
		done
		rest=("${others[@]}")
		[ "${#game_files[@]}" -gt 0 ] || continue
		if ! require_tool rojo; then
			echo "Sin rojo no se puede generar el sourcemap de '$game_name': los require por instancia no se resuelven." >&2
			status=1
			continue
		fi
		sourcemap="$TOOLCHAIN/sourcemaps/$game_name.json"
		mkdir -p "$(dirname "$sourcemap")"
		# --absolute: sin el, las rutas del sourcemap salen relativas a la carpeta del proyecto (src/server/...) pero
		# luau-lsp las resuelve desde la carpeta de trabajo (ROBLOX/), y los paquetes compartidos (../../packages) no casan.
		if ! rojo sourcemap --absolute "$project" --output "$sourcemap" >/dev/null; then
			echo "rojo sourcemap fallo para $project" >&2
			status=1
			continue
		fi
		echo "-- $game_name: ${#game_files[@]} archivos, sourcemap en ${sourcemap#"$ROOT"/}"
		luau-lsp analyze --definitions="$GLOBAL_TYPES" --sourcemap="$sourcemap" "${game_files[@]}" || status=1
	done
	if [ "${#rest[@]}" -gt 0 ]; then
		echo "-- resto: ${#rest[@]} archivos, sin sourcemap"
		luau-lsp analyze --definitions="$GLOBAL_TYPES" "${rest[@]}" || status=1
	fi
	return $status
}

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
			echo "Hay archivos sin formatear: ejecuta bash ROBLOX/tools/format.sh" >&2
			failed=1
		}
	else
		failed=1
	fi
fi

if [ $do_types -eq 1 ]; then
	if command -v luau-lsp >/dev/null 2>&1 && [ -f "$GLOBAL_TYPES" ]; then
		step "luau-lsp analyze (tipos + definiciones de Roblox + sourcemap de Rojo)"
		lsp_analyze_all "${files[@]}" || failed=1
	elif command -v luau-analyze >/dev/null 2>&1; then
		step "luau-analyze (solo tools/: Luau puro, sin tipos de Roblox)"
		mapfile -t pure < <(printf '%s\n' "${files[@]}" | grep -E "^(${ROOT}/)?tools/" || true)
		if [ "${#pure[@]}" -gt 0 ]; then
			luau-analyze --formatter=gnu "${pure[@]}" || failed=1
		else
			echo "(nada que analizar bajo tools/)"
		fi
		echo "Aviso: sin luau-lsp no se comprueba el codigo de Roblox (game, Instance...)."
	else
		echo
		echo "Aviso: no hay luau-lsp ni luau-analyze; se omite la comprobacion de tipos (ver ROBLOX/tools/setup.sh)."
	fi
fi

echo
if [ $failed -eq 0 ]; then
	echo "lint: OK"
else
	echo "lint: FALLO" >&2
fi
exit $failed
