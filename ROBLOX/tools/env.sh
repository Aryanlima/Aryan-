# shellcheck shell=bash
# Entorno comun de los scripts de ROBLOX/tools/ (se usa con `source`, no se ejecuta).
#
# Variables que define:
#   ROOT       raiz de trabajo = la carpeta ROBLOX/ (contiene tools/, .luaurc, selene.toml, stylua.toml).
#              Los scripts hacen `cd "$ROOT"` antes de llamar a selene/stylua/luau-lsp/lune, asi que esas
#              herramientas encuentran sus configs (y el alias @testkit de .luaurc) sin importar desde que
#              carpeta se invoque el script.
#   TOOLCHAIN  donde se instalan los binarios (ignorado por git): ROBLOX/.toolchain. Se puede forzar con
#              ARYAN_TOOLCHAIN=/ruta.
#   GLOBAL_TYPES  definiciones de tipos de Roblox (globalTypes.d.luau) para luau-lsp
#
# Todo es relativo a la ubicacion de este archivo: no hay rutas absolutas del equipo.

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$TOOLS_DIR/.." && pwd)"

if [ -n "${ARYAN_TOOLCHAIN:-}" ]; then
	TOOLCHAIN="$ARYAN_TOOLCHAIN"
else
	TOOLCHAIN="$ROOT/.toolchain"
fi

GLOBAL_TYPES="$TOOLCHAIN/share/globalTypes.d.luau"

# Binarios del toolchain primero; ~/.cargo/bin al final (cargo/rustup para setup.sh).
export PATH="$TOOLCHAIN/bin:$PATH:$HOME/.cargo/bin"
export ROOT TOOLCHAIN GLOBAL_TYPES TOOLS_DIR

# Convierte rutas (relativas al directorio desde el que se invoco el script) en absolutas.
# Uso: mapfile -t paths < <(abs_paths "${paths[@]}")
abs_paths() {
	local p
	for p in "$@"; do
		realpath -- "$p"
	done
}

# Lista de archivos Luau/Lua del proyecto (excluye research, dependencias, venv y el toolchain).
# Uso: mapfile -t FILES < <(find_luau_files [ruta...])
find_luau_files() {
	local paths=("$@")
	if [ "${#paths[@]}" -eq 0 ]; then
		paths=("$ROOT")
	fi
	find "${paths[@]}" \
		\( -name .git -o -name node_modules -o -name .toolchain -o -name venv -o -name research -o -name .claude \) -prune -o \
		-type f \( -name '*.luau' -o -name '*.lua' \) ! -name '*.d.luau' ! -name '*.d.lua' -print | sort
}

# Comprueba que un binario existe; si no, explica como instalarlo.
require_tool() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "Falta '$1'. Ejecuta: bash ROBLOX/tools/setup.sh" >&2
		return 1
	fi
}
