#!/usr/bin/env bash
# Guarda en el repo lo hecho a mano en Studio (modelos de Ropilot, retoques): Workspace.Extras -> world/Extras.
# Uso (otro juego: GAME=arrow-rogue bash ROBLOX/tools/save-extras.sh <ruta>): 1) en Studio mete lo nuevo en Workspace.Extras y guarda (Ctrl+S) el .rbxl abierto;
#      2) bash ROBLOX/tools/save-extras.sh ROBLOX/.toolchain/ff-playtest13.rbxl
# Rojo ya carga world/Extras en Workspace.Extras (default.project.json); WorldBuilder no lo toca.
# Si syncback falla por "SpawnLocation duplicated": en Studio borra los SpawnLocation sueltos de Workspace (el mundo los recrea) y guarda de nuevo.
set -euo pipefail
rbxl="$(realpath "${1:?falta la ruta del .rbxl guardado}")"
game="$(cd "$(dirname "${BASH_SOURCE[0]}")/../games/${GAME:-fish-and-fortune}" && pwd)"
tmp="$(mktemp -d)"; mkdir "$tmp/extras"
echo '{"name":"ExtrasOnly","tree":{"$className":"DataModel","Workspace":{"$className":"Workspace","Extras":{"$className":"Folder","$path":"extras"}}}}' >"$tmp/default.project.json"
(cd "$tmp" && "${ROJO:-rojo}" syncback default.project.json --input "$rbxl" --non-interactive)
rm -rf "$game/world/Extras"; mkdir -p "$game/world"; cp -r "$tmp/extras" "$game/world/Extras"
rm -rf "$tmp"; echo "Guardado en $game/world/Extras"
