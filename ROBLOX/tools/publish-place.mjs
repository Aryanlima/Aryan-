#!/usr/bin/env node
// publish-place.mjs: construye el lugar de Fish & Fortune con Rojo y lo SUBE a una experiencia PRIVADA de pruebas por
// Open Cloud (Place Publishing API, BETA), leyendo la clave de la variable de entorno ROBLOX_API_KEY.
// Por que existe: `rojo upload` solo acepta la clave como argumento (--api_key <CLAVE>): quedaria en la linea de comandos.
//
//   node ROBLOX/tools/publish-place.mjs --universe <UniverseID> --place <PlaceID>              # plan (no sube nada)
//   node ROBLOX/tools/publish-place.mjs --universe <U> --place <P> --apply                     # sube una version GUARDADA
//   node ROBLOX/tools/publish-place.mjs --universe <U> --place <P> --apply --publish           # version PUBLICADA (live)
//
// Salvaguardas:
//   * Antes de subir consulta GET /cloud/v2/universes/{id} y SOLO sigue si `visibility` es PRIVATE (falla cerrado: si no
//     puede comprobarlo, no sube; --skip-visibility-check existe solo para cuando una persona ya lo confirmo en Creator Hub).
//   * Por defecto sube versionType=Saved (no cambia lo que ve nadie). --publish usa versionType=Published.
//   * NUNCA cambia la visibilidad de la experiencia (no hay ningun endpoint de ese tipo aqui).
//   * La clave solo se lee de ROBLOX_API_KEY; no se acepta por argumento ni se imprime.
//   * Permisos minimos de la clave: universe-places:write (y, para la comprobacion, lectura de la experiencia). Ver la guia.
//   * Limitacion de la API: no actualiza EditableImage, EditableMesh, PartOperation, SurfaceAppearance ni BaseWrap;
//     si el lugar los usa, publicar desde Studio (File > Publish) en esa experiencia PRIVADA.
// Salida: 0 bien · 1 error de la API o de la construccion · 2 uso incorrecto.

import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { checkBase } from "./create-items.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROBLOX_ROOT = path.resolve(HERE, "..");
const PROJECT_FILE = path.join(ROBLOX_ROOT, "games", "fish-and-fortune", "default.project.json");
const BUILD_DIR = path.join(ROBLOX_ROOT, ".toolchain", "build");
const DEFAULT_BASE = "https://apis.roblox.com";

function findRojo(env) {
	const exe = process.platform === "win32" ? "rojo.exe" : "rojo";
	const local = path.join(ROBLOX_ROOT, ".toolchain", "bin", exe);
	for (const candidate of [env.ARYAN_ROJO, local, "rojo"].filter(Boolean)) {
		const probe = spawnSync(candidate, ["--version"], { encoding: "utf8" });
		if (!probe.error && probe.status === 0) {
			return candidate;
		}
	}
	return null;
}

function buildPlace(env, log, logErr) {
	const rojo = findRojo(env);
	if (!rojo) {
		logErr("ERROR: no se encontro rojo (ROBLOX/.toolchain/bin o PATH). Ejecuta `rokit install` en ROBLOX/ o `bash ROBLOX/tools/setup.sh`.");
		return null;
	}
	fs.mkdirSync(BUILD_DIR, { recursive: true });
	const output = path.join(BUILD_DIR, "FishAndFortune.publish.rbxl");
	const result = spawnSync(rojo, ["build", PROJECT_FILE, "--output", output], { encoding: "utf8" });
	if (result.error || result.status !== 0) {
		logErr(`ERROR: rojo build fallo:\n${result.stdout ?? ""}${result.stderr ?? ""}${result.error?.message ?? ""}`);
		return null;
	}
	log(`Lugar construido: ${path.relative(ROBLOX_ROOT, output)}`);
	return output;
}

export async function run(options, deps = {}) {
	const log = deps.log ?? ((line) => console.log(line));
	const logErr = deps.logErr ?? ((line) => console.error(line));
	const env = deps.env ?? process.env;
	const doFetch = deps.fetch ?? globalThis.fetch;
	const universe = String(options.universe ?? "").trim();
	const place = String(options.place ?? "").trim();
	for (const [label, value] of [["--universe", universe], ["--place", place]]) {
		if (!/^[1-9]\d{0,14}$/.test(value)) {
			logErr(`ERROR: ${label} debe ser un numero entero (Universe ID / Place ID de Creator Hub).`);
			return 2;
		}
	}
	const versionType = options.publish ? "Published" : "Saved";
	log(`Experiencia (Universe ID): ${universe} · Lugar (Place ID): ${place} · version: ${versionType}`);
	if (!options.apply) {
		log("PLAN: se construiria el lugar con Rojo, se comprobaria que la experiencia es PRIVADA y se subiria. Nada se hizo. Agrega --apply.");
		return 0;
	}
	const apiKey = (env.ROBLOX_API_KEY ?? "").trim();
	const viaProxy = env.ROBLOX_API_KEY_VIA_PROXY === "1"; // sesion de la nube con "secreto de red": el proxy anade x-api-key
	const authHeaders = apiKey ? { "x-api-key": apiKey } : {};
	if (apiKey === "" && !viaProxy) {
		logErr("ERROR: falta la variable de entorno ROBLOX_API_KEY (clave con permiso universe-places:write sobre ESTA experiencia). Nunca en un archivo ni en el chat.");
		return 2;
	}
	let origin;
	try {
		origin = checkBase(env.ROBLOX_API_BASE ?? DEFAULT_BASE);
	} catch (error) {
		logErr(`ERROR: ${error.message}`);
		return 2;
	}
	const redact = (text) => (apiKey ? String(text).split(apiKey).join("[clave oculta]") : String(text));

	try {
		// 1. La experiencia debe ser PRIVADA (falla cerrado)
		if (!options.skipVisibilityCheck) {
			const response = await doFetch(new URL(`/cloud/v2/universes/${universe}`, origin), { headers: authHeaders });
			if (!response.ok) {
				logErr(`ERROR: no se pudo comprobar si la experiencia es privada (HTTP ${response.status}). No se sube nada.`);
				logErr("  Anade a la clave el permiso de lectura de la experiencia, o confirma EN CREATOR HUB que es privada y repite con --skip-visibility-check.");
				return 1;
			}
			const universeInfo = await response.json();
			if (universeInfo.visibility !== "PRIVATE") {
				logErr(`ERROR: la experiencia NO es privada (visibility = ${universeInfo.visibility}). No se sube nada. Esta herramienta nunca toca lo publico.`);
				return 1;
			}
			log("Comprobado: la experiencia es PRIVADA.");
		} else {
			log("AVISO: se omitio la comprobacion de visibilidad (--skip-visibility-check). Confirma en Creator Hub que la experiencia es privada.");
		}

		// 2. Construir (o usar el .rbxl indicado)
		const rbxl = options.rbxl ? path.resolve(options.rbxl) : buildPlace(env, log, logErr);
		if (!rbxl) {
			return 1;
		}
		const bytes = fs.readFileSync(rbxl);
		log(`Subiendo ${(bytes.length / 1024 / 1024).toFixed(2)} MB...`);

		// 3. Subir
		const url = new URL(`/universes/v1/${universe}/places/${place}/versions`, origin);
		url.searchParams.set("versionType", versionType);
		const upload = await doFetch(url, {
			method: "POST",
			headers: { ...authHeaders, "Content-Type": "application/octet-stream" },
			body: bytes,
		});
		const text = await upload.text();
		if (!upload.ok) {
			logErr(`ERROR: la subida fallo (HTTP ${upload.status}): ${redact(text).slice(0, 300)}`);
			return 1;
		}
		const version = JSON.parse(text).versionNumber;
		log(`LISTO: version ${version} (${versionType}) del lugar ${place}. Comprueba en Creator Hub que la experiencia sigue en privado.`);
		return 0;
	} catch (error) {
		logErr(`ERROR: ${redact(error.message)}`);
		return 1;
	}
}

export function parseArgs(argv) {
	const options = {};
	for (let i = 0; i < argv.length; i++) {
		const arg = argv[i];
		if (["--universe", "--place", "--rbxl"].includes(arg)) {
			const value = argv[++i];
			if (value === undefined || value.startsWith("--")) {
				return { error: `${arg} necesita un valor` };
			}
			options[arg.slice(2)] = value;
		} else if (arg === "--apply") {
			options.apply = true;
		} else if (arg === "--publish") {
			options.publish = true;
		} else if (arg === "--skip-visibility-check") {
			options.skipVisibilityCheck = true;
		} else if (arg === "-h" || arg === "--help") {
			options.help = true;
		} else if (/api[-_]?key/i.test(arg)) {
			return { error: "la clave NO se acepta por argumento: usa la variable de entorno ROBLOX_API_KEY" };
		} else {
			return { error: `opcion desconocida: ${arg}` };
		}
	}
	return { options };
}

const HELP = `publish-place.mjs: sube el lugar a una experiencia PRIVADA de pruebas (Open Cloud).
Uso: node ROBLOX/tools/publish-place.mjs --universe <ID> --place <ID> [--apply] [--publish] [--rbxl <archivo>]
  sin --apply           solo muestra el plan
  --publish             sube como version PUBLICADA (por defecto GUARDADA)
  --rbxl <archivo>      sube este .rbxl en vez de construirlo con Rojo
  --skip-visibility-check   solo si una persona ya confirmo en Creator Hub que la experiencia es privada
Clave: variable de entorno ROBLOX_API_KEY (nunca por argumento).`;

async function main() {
	const parsed = parseArgs(process.argv.slice(2));
	if (parsed.error) {
		console.error(`ERROR: ${parsed.error}\n\n${HELP}`);
		return 2;
	}
	if (parsed.options.help) {
		console.log(HELP);
		return 0;
	}
	return run(parsed.options);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
	process.exitCode = await main();
}
