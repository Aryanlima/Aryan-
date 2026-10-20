// Comprobacion de tipos Luau (--!strict) SIN Roblox Studio ni luau-lsp.
//
// Usa el analizador Luau compilado a WebAssembly (@luau-rs/luau, Luau 0.739) + unas definiciones
// minimas de la API de Roblox (scripts/roblox-lite.d.luau).
//
// Instalacion (una vez; todo va a ROBLOX/.toolchain/typecheck, ignorado por git):
//   mkdir -p ROBLOX/.toolchain/typecheck && cd ROBLOX/.toolchain/typecheck
//   npm init -y && npm install @luau-rs/luau@0.739.0
//
// Uso (desde la raiz del repo):
//   node ROBLOX/scripts/typecheck.mjs ROBLOX/packages ROBLOX/games/fish-and-fortune/src
//
// Limitaciones: los `require(script.Parent.X)` / `require(ReplicatedStorage.X)` (por instancia)
// no se resuelven aqui (devuelven `any`), asi que las firmas entre modulos solo se comprueban
// en los `require("./ruta")` por cadena. Es una red de seguridad, no sustituye a luau-lsp/Studio.

import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join, relative, resolve, dirname } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const robloxRoot = resolve(here, "..");
const toolDir = join(robloxRoot, ".toolchain", "typecheck");

if (!existsSync(join(toolDir, "node_modules", "@luau-rs"))) {
	console.error("Falta el analizador. Ver instrucciones al inicio de ROBLOX/scripts/typecheck.mjs");
	process.exit(2);
}

// El paquete es solo-ESM y su mapa de exports no se resuelve con createRequire: se importa por ruta.
const analysisEntry = join(toolDir, "node_modules", "@luau-rs", "luau", "dist", "analysis.js");
const { Analysis } = await import(pathToFileURL(analysisEntry).href);

function walk(path, out) {
	const st = statSync(path);
	if (st.isDirectory()) {
		for (const name of readdirSync(path)) {
			if (name === "node_modules" || name === ".toolchain") continue;
			walk(join(path, name), out);
		}
	} else if (path.endsWith(".luau") || path.endsWith(".lua")) {
		out.push(path);
	}
}

const args = process.argv.slice(2).filter((a) => !a.startsWith("--"));
const includeSpecs = process.argv.includes("--with-tests");
const files = [];
for (const a of args.length > 0 ? args : [join(robloxRoot, "packages")]) {
	walk(resolve(a), files);
}
const selected = files.filter((f) => includeSpecs || !f.endsWith(".spec.luau"));

// Definiciones minimas propias (el globalTypes.d.luau completo desborda el analizador WASM).
const defs = readFileSync(join(here, "roblox-lite.d.luau"), "utf8");
const analysis = await Analysis.create({
	mode: "nonstrict", // cada archivo trae su propio --!strict
	lint: true,
	definitions: [{ name: "roblox", source: defs }],
});

// Nombre de modulo = ruta relativa a ROBLOX/ sin extension (para que `require("./X")` resuelva).
const nameOf = (f) => relative(robloxRoot, f).replace(/\\/g, "/").replace(/\.luau?$/, "");
for (const f of selected) {
	analysis.setModule(nameOf(f), readFileSync(f, "utf8"));
}

let errors = 0;
let warnings = 0;
for (const f of selected) {
	const result = analysis.check(nameOf(f));
	for (const d of result.diagnostics) {
		// Los avisos de lint sobre globales de Roblox en esta configuracion no aportan: se filtran los ruidosos.
		const line = d.location.begin.line + 1;
		const col = d.location.begin.column + 1;
		const tag = d.severity === "error" ? "error" : "warn ";
		if (d.severity === "error") errors++;
		else warnings++;
		console.log(`${relative(process.cwd(), f)}:${line}:${col}: ${tag} [${d.code}] ${d.message}`);
	}
	if (result.timeoutModules.length > 0) {
		console.log(`${relative(process.cwd(), f)}: timeout al comprobar ${result.timeoutModules.join(", ")}`);
	}
}
console.log(`\n${selected.length} archivos, ${errors} errores, ${warnings} avisos`);
process.exit(errors > 0 ? 1 : 0);
