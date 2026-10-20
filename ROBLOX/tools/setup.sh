#!/usr/bin/env bash
# Instala el toolchain Luau local (sin Roblox Studio). Idempotente: lo ya instalado y con la
# version correcta se omite. Todo va a $TOOLCHAIN (ROBLOX/.toolchain, ignorado por git).
# Las mismas versiones fijas estan en ROBLOX/rokit.toml (alternativa: instalar con Rokit).
#
# Herramientas:
#   lune          runtime Luau para ejecutar scripts/tests            (cargo, crates.io)
#   stylua        formateador                                         (cargo)
#   selene        linter                                              (cargo)
#   rojo          sincronizacion/compilacion de proyectos Rojo        (cargo)
#   luau-analyze  comprobador de tipos Luau (+ luau, luau-compile)    (compila desde fuente)
#   luau-lsp      analizador/LSP con tipos de Roblox                  (compila desde fuente)
#   globalTypes.d.luau  definiciones de tipos de Roblox (salen del codigo fuente de luau-lsp)
#
# Red necesaria (hosts): index.crates.io, static.crates.io, proxy.golang.org. NO hace falta github.com:
# el codigo fuente de Luau y luau-lsp se baja del proxy de modulos de Go (es un espejo de los repos).
#
# Uso:
#   bash ROBLOX/tools/setup.sh                    # instala todo lo que falte
#   bash ROBLOX/tools/setup.sh --check            # solo verifica lo instalado (no instala nada)
#   bash ROBLOX/tools/setup.sh --only lune,stylua # solo esas: lune stylua selene rojo luau luau-lsp
#   bash ROBLOX/tools/setup.sh --skip-lsp         # omite luau-lsp (la compilacion mas lenta)
#   JOBS=2 bash ROBLOX/tools/setup.sh             # hilos de compilacion (por defecto: nproc, maximo 4)
#   KEEP_BUILD=1 bash ROBLOX/tools/setup.sh       # conserva los directorios de compilacion
#
# Requisitos del sistema: cargo/rustc, cmake, g++ o clang++, curl, python3 (ninja es opcional).
set -euo pipefail
# shellcheck source=ROBLOX/tools/env.sh
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

# ---- Versiones fijadas (las que se probaron; mantener sincronizadas con ROBLOX/rokit.toml) -----------------
LUNE_VERSION="0.11.0"
STYLUA_VERSION="2.6.0"
SELENE_VERSION="0.31.0"
ROJO_VERSION="7.7.1"
# Versiones "pseudo-semver" del proxy de Go = commit de la rama principal en esa fecha.
LUAU_GO_MODULE="github.com/luau-lang/luau"
LUAU_GO_VERSION="v0.0.0-20261010001518-8387cfb461b3" # 2026-10-10
LUAU_LSP_GO_MODULE="github.com/!johnny!morganz/luau-lsp" # '!j' = 'J' (codificacion del proxy de Go)
LUAU_LSP_GO_VERSION="v0.0.0-20261010135809-6f90396fa8f6" # 2026-10-10
GO_PROXY="${GO_PROXY_URL:-https://proxy.golang.org}"

JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"
[ "$JOBS" -gt 4 ] && JOBS=4

check_only=0
skip_lsp=0
only=""
while [ $# -gt 0 ]; do
	case "$1" in
	--check) check_only=1 ;;
	--skip-lsp) skip_lsp=1 ;;
	--only)
		shift
		only="${1:-}"
		;;
	-h | --help)
		sed -n '2,25p' "${BASH_SOURCE[0]}"
		exit 0
		;;
	*)
		echo "Opcion desconocida: $1" >&2
		exit 2
		;;
	esac
	shift
done

wanted() { # wanted <nombre>: true si esta en --only (o no se uso --only)
	[ -z "$only" ] || [[ ",$only," == *",$1,"* ]]
}

BIN="$TOOLCHAIN/bin"
SHARE="$TOOLCHAIN/share"
BUILD="$TOOLCHAIN/.build"
mkdir -p "$BIN" "$SHARE"

log() { printf '\n[setup] %s\n' "$*"; }

# ---- Utilidades -------------------------------------------------------------------------------
installed_version_ok() { # <binario> <texto esperado en --version>
	[ -x "$BIN/$1" ] && "$BIN/$1" --version 2>&1 | grep -qF "$2"
}

marker_ok() { # <marcador> <valor esperado>
	[ -f "$SHARE/$1" ] && [ "$(cat "$SHARE/$1")" = "$2" ]
}

install_cargo_tool() { # <crate> <binario> <version> [flags extra de cargo install]
	local crate="$1" bin="$2" version="$3"
	shift 3
	if installed_version_ok "$bin" "$version"; then
		log "$bin $version ya instalado"
		return 0
	fi
	[ $check_only -eq 1 ] && {
		echo "FALTA $bin $version"
		return 1
	}
	log "cargo install $crate $version (puede tardar varios minutos)"
	cargo install "$crate" --locked --version "$version" --root "$TOOLCHAIN" -j "$JOBS" "$@"
}

SUMDB_URL="${SUMDB_URL:-https://sum.golang.org}"

# Comprueba el hash h1 del zip contra la base de checksums de Go (transparency log), igual que `go mod`.
verify_go_zip() { # <zip> <modulo> <version>
	local zip="$1" module="$2" version="$3" lookup
	if ! lookup="$(curl -fsSL --retry 2 -m 60 "$SUMDB_URL/lookup/$module@$version" 2>/dev/null)"; then
		echo "[setup] AVISO: no se pudo consultar $SUMDB_URL; zip de $module NO verificado" >&2
		return 0
	fi
	python3 -I -c '
import base64, hashlib, sys, zipfile
zip_path, version, lookup = sys.argv[1:4]
archive = zipfile.ZipFile(zip_path)
summary = "".join(
    hashlib.sha256(archive.read(name)).hexdigest() + "  " + name + "\n"
    for name in sorted(archive.namelist())
    if not name.endswith("/")
)
h1 = "h1:" + base64.b64encode(hashlib.sha256(summary.encode()).digest()).decode()
fields = [line.split() for line in lookup.splitlines()]
sys.exit(0 if any(len(f) == 3 and f[1] == version and f[2] == h1 for f in fields) else 1)
' "$zip" "$version" "$lookup" || {
		echo "[setup] ERROR: el hash del zip de $module@$version no coincide con sum.golang.org" >&2
		return 1
	}
	log "hash de $module@$version verificado contra sum.golang.org"
}

fetch_go_module() { # <modulo> <version> <destino>: baja, verifica y extrae el zip del proxy de Go
	local module="$1" version="$2" dest="$3"
	local zip="$dest.zip"
	mkdir -p "$dest"
	log "descargando $module@$version desde $GO_PROXY"
	curl -fsSL --retry 3 -o "$zip" "$GO_PROXY/$module/@v/$version.zip"
	verify_go_zip "$zip" "$module" "$version"
	python3 -I -c 'import sys, zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])' "$zip" "$dest"
	rm -f "$zip"
}

cmake_build() { # <fuente> <build dir> <objetivos...>
	local src="$1" bdir="$2"
	shift 2
	local generator=()
	command -v ninja >/dev/null 2>&1 && generator=(-G Ninja)
	local compilers=()
	# clang++ evita falsos positivos de -Werror de GCC 13 al compilar luau-lsp
	if command -v clang++ >/dev/null 2>&1 && command -v clang >/dev/null 2>&1; then
		compilers=(-DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++)
	fi
	cmake -S "$src" -B "$bdir" "${generator[@]}" "${compilers[@]}" -DCMAKE_BUILD_TYPE=Release \
		-DLUAU_BUILD_TESTS=OFF -DLUAU_BUILD_WEB=OFF >/dev/null
	cmake --build "$bdir" --target "$@" -j "$JOBS"
}

# ---- Luau (luau-analyze, luau, luau-compile) --------------------------------------------------
LUAU_SRC=""
ensure_luau_source() {
	if [ -z "$LUAU_SRC" ]; then
		rm -rf "$BUILD/luau-src"
		fetch_go_module "$LUAU_GO_MODULE" "$LUAU_GO_VERSION" "$BUILD/luau-src"
		LUAU_SRC="$BUILD/luau-src/$LUAU_GO_MODULE@$LUAU_GO_VERSION"
	fi
}

install_luau() {
	if marker_ok luau.version "$LUAU_GO_VERSION" && [ -x "$BIN/luau-analyze" ]; then
		log "luau-analyze ($LUAU_GO_VERSION) ya instalado"
		return 0
	fi
	[ $check_only -eq 1 ] && {
		echo "FALTA luau-analyze"
		return 1
	}
	log "compilando Luau (luau-analyze, luau, luau-compile) desde fuente"
	ensure_luau_source
	cmake_build "$LUAU_SRC" "$BUILD/luau-build" Luau.Analyze.CLI Luau.Compile.CLI Luau.Repl.CLI
	cp "$BUILD/luau-build/luau-analyze" "$BUILD/luau-build/luau" "$BUILD/luau-build/luau-compile" "$BIN/"
	printf '%s' "$LUAU_GO_VERSION" >"$SHARE/luau.version"
}

# ---- luau-lsp + definiciones de tipos de Roblox -----------------------------------------------
install_luau_lsp() {
	if marker_ok luau-lsp.version "$LUAU_LSP_GO_VERSION" && [ -x "$BIN/luau-lsp" ] && [ -f "$GLOBAL_TYPES" ]; then
		log "luau-lsp ($LUAU_LSP_GO_VERSION) y globalTypes.d.luau ya instalados"
		return 0
	fi
	[ $check_only -eq 1 ] && {
		echo "FALTA luau-lsp / globalTypes.d.luau"
		return 1
	}
	log "compilando luau-lsp desde fuente (lento: ~10 min con 4 hilos)"
	ensure_luau_source
	rm -rf "$BUILD/lsp-src"
	fetch_go_module "$LUAU_LSP_GO_MODULE" "$LUAU_LSP_GO_VERSION" "$BUILD/lsp-src"
	local lsp_src="$BUILD/lsp-src/$LUAU_LSP_GO_MODULE@$LUAU_LSP_GO_VERSION"
	# El zip del proxy no incluye submodulos: luau-lsp espera el codigo de Luau en ./luau
	rm -rf "$lsp_src/luau"
	cp -r "$LUAU_SRC" "$lsp_src/luau"
	# Definiciones de tipos de Roblox (vienen en el propio repo de luau-lsp)
	cp "$lsp_src/scripts/globalTypes.d.luau" "$GLOBAL_TYPES"
	cmake_build "$lsp_src" "$BUILD/lsp-build" Luau.LanguageServer.CLI
	local built
	built="$(find "$BUILD/lsp-build" -maxdepth 1 -type f -name 'luau-lsp*' -perm -u+x | head -n 1)"
	if [ -z "$built" ]; then
		echo "No se encontro el binario luau-lsp tras compilar" >&2
		return 1
	fi
	cp "$built" "$BIN/luau-lsp"
	printf '%s' "$LUAU_LSP_GO_VERSION" >"$SHARE/luau-lsp.version"
}

# ---- Verificacion (smoke tests) ---------------------------------------------------------------
verify() {
	log "verificacion"
	local status=0
	local tool
	for tool in lune stylua selene rojo; do
		if [ -x "$BIN/$tool" ]; then
			printf '  %-13s %s\n' "$tool" "$("$BIN/$tool" --version 2>&1 | head -n 1)"
		else
			printf '  %-13s NO INSTALADO\n' "$tool"
			status=1
		fi
	done
	if [ -x "$BIN/luau-analyze" ]; then
		printf '  %-13s %s\n' luau-analyze "compilado de $LUAU_GO_MODULE@$LUAU_GO_VERSION"
	else
		printf '  %-13s NO INSTALADO\n' luau-analyze
	fi
	if [ -x "$BIN/luau-lsp" ]; then
		printf '  %-13s %s\n' luau-lsp "$("$BIN/luau-lsp" --version 2>&1 | head -n 1)"
	else
		printf '  %-13s NO INSTALADO (opcional)\n' luau-lsp
	fi
	[ -f "$GLOBAL_TYPES" ] && printf '  %-13s %s\n' "tipos Roblox" "$GLOBAL_TYPES" || printf '  %-13s NO INSTALADO\n' "tipos Roblox"

	if [ -x "$BIN/lune" ]; then
		local tmp
		tmp="$(mktemp -d)"
		printf 'local x: number = 40 + 2\nprint("lune ok", x)\n' >"$tmp/smoke.luau"
		if "$BIN/lune" run "$tmp/smoke.luau" | grep -q "lune ok 42"; then
			echo "  smoke lune: OK (script Luau ejecutado)"
		else
			echo "  smoke lune: FALLO" >&2
			status=1
		fi
		rm -rf "$tmp"
	fi
	return $status
}

# ---- Principal --------------------------------------------------------------------------------
rc=0
if [ $check_only -eq 0 ]; then
	for need in cargo cmake curl python3; do
		command -v "$need" >/dev/null 2>&1 || {
			echo "Falta el requisito '$need'" >&2
			exit 1
		}
	done
	command -v clang++ >/dev/null 2>&1 || command -v g++ >/dev/null 2>&1 || {
		echo "Falta un compilador C++ (clang++ o g++)" >&2
		exit 1
	}
fi

wanted lune && { install_cargo_tool lune lune "$LUNE_VERSION" || rc=1; }
wanted stylua && { install_cargo_tool stylua stylua "$STYLUA_VERSION" --features luau || rc=1; }
wanted selene && { install_cargo_tool selene selene "$SELENE_VERSION" || rc=1; }
wanted rojo && { install_cargo_tool rojo rojo "$ROJO_VERSION" || rc=1; }
wanted luau && { install_luau || rc=1; }
if [ $skip_lsp -eq 0 ] && wanted luau-lsp; then
	install_luau_lsp || rc=1
fi

# Definiciones de tipos de Lune (modulos @lune/*): se generan localmente, sin red.
# `lune setup` escribe en ~/.lune y toca el .luaurc del directorio actual: se ejecuta en un temporal.
if [ $check_only -eq 0 ] && [ -x "$BIN/lune" ] && wanted lune; then
	tmp="$(mktemp -d)"
	(cd "$tmp" && "$BIN/lune" setup >/dev/null 2>&1) || echo "Aviso: 'lune setup' fallo (tipos de @lune/* no generados)" >&2
	rm -rf "$tmp"
fi

[ $check_only -eq 0 ] && [ "${KEEP_BUILD:-0}" != "1" ] && rm -rf "$BUILD"

verify || rc=1
if [ $rc -eq 0 ]; then
	log "listo. Prueba: bash ROBLOX/tools/test.sh && bash ROBLOX/tools/lint.sh"
else
	log "terminado con elementos pendientes (ver arriba)" >&2
fi
exit $rc
