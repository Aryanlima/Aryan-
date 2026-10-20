# shellcheck shell=bash
# Entorno comun de los scripts de tools/ (se usa con `source`, no se ejecuta).
#
# Variables que define:
#   ROOT       raiz del proyecto (carpeta que contiene tools/, .luaurc, selene.toml, stylua.toml)
#   TOOLCHAIN  donde se instalan los binarios (ignorado por git). Por defecto ROBLOX/.toolchain
#              si existe ROBLOX/, si no .toolchain. Se puede forzar con ARYAN_TOOLCHAIN=/ruta.
#   GLOBAL_TYPES  definiciones de tipos de Roblox (globalTypes.d.luau) para luau-lsp
#
# Todo es relativo a la ubicacion de este archivo: no hay rutas absolutas del equipo.

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$TOOLS_DIR/.." && pwd)"

if [ -n "${ARYAN_TOOLCHAIN:-}" ]; then
	TOOLCHAIN="$ARYAN_TOOLCHAIN"
elif [ -d "$ROOT/ROBLOX" ]; then
	TOOLCHAIN="$ROOT/ROBLOX/.toolchain"
else
	TOOLCHAIN="$ROOT/.toolchain"
fi

GLOBAL_TYPES="$TOOLCHAIN/share/globalTypes.d.luau"

# Binarios del toolchain primero; ~/.cargo/bin al final (cargo/rustup para setup.sh).
export PATH="$TOOLCHAIN/bin:$PATH:$HOME/.cargo/bin"
export ROOT TOOLCHAIN GLOBAL_TYPES TOOLS_DIR

# Lista de archivos Luau/Lua del proyecto (excluye research, dependencias y el toolchain).
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
		echo "Falta '$1'. Ejecuta: tools/setup.sh" >&2
		return 1
	fi
}
