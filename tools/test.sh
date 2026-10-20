#!/usr/bin/env bash
# Ejecuta todos los *.spec.luau con lune (cada archivo en su propio proceso).
#
# Uso:
#   tools/test.sh                       # todos los specs del proyecto
#   tools/test.sh tools/examples        # solo los de una carpeta o archivo(s)
#   tools/test.sh -t "ProcessReceipt"   # solo tests cuyo nombre completo contiene el texto
#   tools/test.sh -v                    # muestra la salida completa tambien de los que pasan
#
# Codigo de salida: 0 si todo pasa, 1 si algun spec falla, 2 si falta lune o no hay specs.
set -uo pipefail
# shellcheck source=tools/env.sh
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

verbose=0
filter=""
targets=()
while [ $# -gt 0 ]; do
	case "$1" in
	-v | --verbose) verbose=1 ;;
	-t | --filter)
		shift
		filter="${1:-}"
		;;
	-h | --help)
		sed -n '2,11p' "${BASH_SOURCE[0]}"
		exit 0
		;;
	*) targets+=("$1") ;;
	esac
	shift
done

require_tool lune || exit 2
[ -n "$filter" ] && export TESTKIT_FILTER="$filter"

specs=()
if [ "${#targets[@]}" -eq 0 ]; then
	targets=("$ROOT")
else
	mapfile -t targets < <(abs_paths "${targets[@]}")
fi
for target in "${targets[@]}"; do
	if [ -f "$target" ]; then
		specs+=("$target")
	else
		while IFS= read -r f; do specs+=("$f"); done < <(
			find "$target" \
				\( -name .git -o -name node_modules -o -name .toolchain -o -name venv -o -name research -o -name .claude \) -prune -o \
				-type f -name '*.spec.luau' -print | sort
		)
	fi
done

if [ "${#specs[@]}" -eq 0 ]; then
	echo "No se encontraron archivos *.spec.luau" >&2
	exit 2
fi

cd "$ROOT" || exit 2
failed=0
passed_files=0
total_passed=0
total_failed=0
total_skipped=0

for spec in "${specs[@]}"; do
	rel="${spec#"$ROOT"/}"
	output="$(lune run "$spec" 2>&1)"
	status=$?
	summary="$(printf '%s\n' "$output" | grep -E '^Tests: ' | tail -n 1)"
	if [ $status -eq 0 ]; then
		passed_files=$((passed_files + 1))
		echo "PASS  $rel  ${summary#Tests: }"
		[ $verbose -eq 1 ] && printf '%s\n\n' "$output"
	else
		failed=$((failed + 1))
		echo "FAIL  $rel  ${summary#Tests: }"
		printf '%s\n\n' "$output"
	fi
	if [[ "$summary" =~ ([0-9]+)\ passed,\ ([0-9]+)\ failed,\ ([0-9]+)\ skipped ]]; then
		total_passed=$((total_passed + BASH_REMATCH[1]))
		total_failed=$((total_failed + BASH_REMATCH[2]))
		total_skipped=$((total_skipped + BASH_REMATCH[3]))
	fi
done

echo
echo "Specs: $passed_files passed, $failed failed, ${#specs[@]} total"
echo "Tests: $total_passed passed, $total_failed failed, $total_skipped skipped"
[ $failed -eq 0 ]
