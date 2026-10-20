#!/usr/bin/env node
// wire-ids.mjs: cablea los IDs de pases y productos de Fish & Fortune en ProductIds.luau SIN errores humanos.
//
// Lee un JSON (por defecto ROBLOX/games/fish-and-fortune/ids.local.json), lo VALIDA, reescribe
// src/server/ProductIds.luau con formato valido para StyLua y despues ejecuta la puerta previa a publicar
// (FF_RELEASE_CHECK=1 bash ROBLOX/tools/test.sh). Si la puerta falla, RESTAURA el archivo anterior.
//
// Uso (desde cualquier carpeta; no hace falta instalar nada: solo Node 20 o superior):
//   node ROBLOX/tools/wire-ids.mjs --dry-run            # valida y muestra los cambios; no escribe nada
//   node ROBLOX/tools/wire-ids.mjs                      # valida, escribe y corre la puerta
//   node ROBLOX/tools/wire-ids.mjs --ids otra.json      # otro archivo de IDs
//   node ROBLOX/tools/wire-ids.mjs --no-gate            # escribe pero NO corre la puerta (solo para pruebas)
//   node ROBLOX/tools/wire-ids.mjs --emit-verify-luau   # imprime el script de Studio que comprueba los IDs (solo lectura)
//   node ROBLOX/tools/wire-ids.mjs --help
//
// Formato de ids.local.json (documentado en ROBLOX/docs/publicar-paso-a-paso.md y en ids.example.json):
//   { "passes":   { "auto_fish": 1234567890, ... },   // los MISMOS nombres de clave que ProductIds.luau
//     "products": { "coin_pack_small": 1234567890, ... } }
//   * Cada valor es el ID numerico tal como lo da Creator Hub (un entero, o el mismo numero entre comillas).
//   * Un pase puede llevar tambien { "passId": 111, "assetId": 222 } si la prueba de Studio demuestra que su
//     TargetId (passId) y su assetId son DISTINTOS (ver "TargetId o assetId" en la guia). passId es el que usa el juego.
//   * "luck_plus" y "lucky_bait_15" (suerte de pago) estan APAGADOS en la v1: deben quedarse en 0.
//   * Opcionales informativos: "universeId", "placeId" y cualquier clave que empiece por "_" (comentarios).
//
// Codigos de salida: 0 todo bien · 1 datos invalidos o la puerta fallo · 2 uso incorrecto o error de lectura/escritura.
// No usa red, ni claves, ni rutas absolutas del equipo. Los IDs de pases/productos NO son secretos.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROBLOX_ROOT = path.resolve(HERE, "..");
const GAME_DIR = path.join(ROBLOX_ROOT, "games", "fish-and-fortune");

export const DEFAULT_IDS_FILE = path.join(GAME_DIR, "ids.local.json");
export const DEFAULT_TARGET = path.join(GAME_DIR, "src", "server", "ProductIds.luau");
export const FEATURE_FLAGS_FILE = path.join(GAME_DIR, "src", "shared", "FeatureFlags.luau");
export const STORE_ITEMS_FILE = path.join(GAME_DIR, "store-items.json");

// Objetos que dependen del flag paidLuckEnabled (suerte de pago). Con el flag apagado (v1) NO se ofrecen y deben
// quedarse en ID 0 (crear el objeto en Creator Hub dejaria recibos sin resolver: ver README, "SHOP-03").
// ROBLOX/games/fish-and-fortune/tests/WireIds.spec.luau comprueba que esta lista coincide con Catalog.luau.
export const GATED_KEYS = ["luck_plus", "lucky_bait_15"];

const MAX_ID = Number.MAX_SAFE_INTEGER; // Luau guarda los numeros como doble: mas de 2^53 perderia precision
const SMALL_ID_WARNING = 100000; // los IDs reales de Roblox son mucho mayores; uno pequeno suele ser un error de copia

// ---------------------------------------------------------------------------------------------------------------
// Lectura de ProductIds.luau
// ---------------------------------------------------------------------------------------------------------------

/** Normaliza saltos de linea (Windows) y quita el BOM. */
function normalizeText(text) {
	return text.replace(/^﻿/, "").replace(/\r\n?/g, "\n");
}

/**
 * Analiza ProductIds.luau. Devuelve { header, passes, products, passAssetIds } donde passes/products son listas
 * [{ key, id, note }] en el orden del archivo, y header es todo lo que hay antes de `return {`.
 */
export function parseProductIds(rawText) {
	const text = normalizeText(rawText);
	const marker = text.indexOf("\nreturn {");
	if (marker < 0) {
		throw new Error("ProductIds.luau no tiene el formato esperado (falta `return {`).");
	}
	const header = text.slice(0, marker + 1);
	const body = text.slice(marker + 1);

	const sectionOf = (name) => {
		const open = new RegExp(`^\\t${name} = \\{(?:\\}|\\s*$)`, "m").exec(body);
		if (!open) {
			return null;
		}
		const start = open.index + open[0].length;
		if (open[0].trimEnd().endsWith("}")) {
			return []; // seccion vacia en una linea: `passAssetIds = {},`
		}
		const end = body.indexOf("\n\t},", start);
		if (end < 0) {
			throw new Error(`ProductIds.luau: no se encuentra el final de la seccion '${name}'.`);
		}
		const entries = [];
		for (const line of body.slice(start, end).split("\n")) {
			if (line.trim() === "") {
				continue;
			}
			const m = /^\t\t(\w+) = (\d+),(?:\s*--\s?(.*))?$/.exec(line);
			if (!m) {
				throw new Error(`ProductIds.luau: linea no reconocida en '${name}': ${JSON.stringify(line)}`);
			}
			const note = (m[3] ?? "").replace(/^TODO_ID\s*/, "").trim();
			entries.push({ key: m[1], id: Number(m[2]), note });
		}
		return entries;
	};

	const passes = sectionOf("passes");
	const products = sectionOf("products");
	if (!passes || !products) {
		throw new Error("ProductIds.luau: faltan las secciones `passes` y/o `products`.");
	}
	return { header, passes, products, passAssetIds: sectionOf("passAssetIds") ?? [] };
}

/** Lee el flag paidLuckEnabled de FeatureFlags.luau (true/false). Si no se puede leer, asume false (v1). */
export function readPaidLuckFlag(featureFlagsText) {
	const m = /paidLuckEnabled\s*=\s*(true|false)/.exec(normalizeText(featureFlagsText));
	return m ? m[1] === "true" : false;
}

// ---------------------------------------------------------------------------------------------------------------
// Validacion de ids.local.json
// ---------------------------------------------------------------------------------------------------------------

function describeValue(value) {
	if (typeof value === "string") {
		return JSON.stringify(value);
	}
	if (value === null) {
		return "null";
	}
	if (Array.isArray(value)) {
		return "una lista";
	}
	return String(value);
}

/** Convierte un valor del JSON en un ID entero >= 0, o devuelve { error }. */
export function parseId(value) {
	let numeric;
	if (typeof value === "number") {
		numeric = value;
	} else if (typeof value === "string") {
		const trimmed = value.trim();
		if (trimmed === "") {
			return { error: "esta vacio" };
		}
		if (/^-/.test(trimmed)) {
			return { error: `es negativo (${describeValue(value)})` };
		}
		if (/[/:.]|https?/i.test(trimmed)) {
			return { error: `parece una URL o un decimal (${describeValue(value)}); pega SOLO el numero del ID` };
		}
		if (!/^\d+$/.test(trimmed)) {
			return { error: `no es un numero entero (${describeValue(value)}); quita letras, espacios y simbolos` };
		}
		numeric = Number(trimmed);
	} else {
		return { error: `debe ser un numero entero, no ${describeValue(value)}` };
	}
	if (!Number.isFinite(numeric)) {
		return { error: "no es un numero finito" };
	}
	if (numeric < 0) {
		return { error: `es negativo (${numeric})` };
	}
	if (!Number.isInteger(numeric)) {
		return { error: `no es un entero (${numeric})` };
	}
	if (numeric > MAX_ID) {
		return { error: `es demasiado grande (${numeric}); un ID de Roblox cabe en 15 digitos` };
	}
	return { id: numeric };
}

function editDistance(a, b) {
	const dp = Array.from({ length: a.length + 1 }, (_, i) => [i]);
	for (let j = 1; j <= b.length; j++) {
		dp[0][j] = j;
	}
	for (let i = 1; i <= a.length; i++) {
		for (let j = 1; j <= b.length; j++) {
			dp[i][j] = Math.min(
				dp[i - 1][j] + 1,
				dp[i][j - 1] + 1,
				dp[i - 1][j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1),
			);
		}
	}
	return dp[a.length][b.length];
}

function suggest(unknownKey, knownKeys) {
	let best = null;
	for (const known of knownKeys) {
		const d = editDistance(unknownKey, known);
		if (d <= 3 && (best === null || d < best.d)) {
			best = { key: known, d };
		}
	}
	return best ? best.key : null;
}

/**
 * Valida el contenido de ids.local.json contra la estructura de ProductIds.luau.
 * Devuelve { errors, warnings, passes: Map(key -> {passId, assetId|null}), products: Map(key -> id) }.
 */
export function validateIds(json, structure, options = {}) {
	const errors = [];
	const warnings = [];
	const paidLuckEnabled = options.paidLuckEnabled === true;
	const allowIdsInDisabled = options.allowIdsInDisabled === true;
	const passes = new Map();
	const products = new Map();

	if (json === null || typeof json !== "object" || Array.isArray(json)) {
		errors.push("El archivo de IDs debe ser un objeto JSON con las secciones \"passes\" y \"products\".");
		return { errors, warnings, passes, products };
	}
	for (const topKey of Object.keys(json)) {
		if (["passes", "products", "universeId", "placeId"].includes(topKey) || topKey.startsWith("_")) {
			continue;
		}
		const hint = suggest(topKey, ["passes", "products"]);
		errors.push(`Clave desconocida al nivel superior: "${topKey}"${hint ? ` (¿quisiste decir "${hint}"?)` : ""}.`);
	}
	for (const meta of ["universeId", "placeId"]) {
		if (meta in json) {
			const parsed = parseId(json[meta]); // 0 = "todavia no definido" (solo informativo)
			if (parsed.error) {
				errors.push(`"${meta}" ${parsed.error}.`);
			}
		}
	}

	const sections = [
		{ name: "passes", label: "pase", expected: structure.passes.map((e) => e.key), target: passes, allowObject: true },
		{ name: "products", label: "producto", expected: structure.products.map((e) => e.key), target: products, allowObject: false },
	];
	for (const section of sections) {
		const data = json[section.name];
		if (data === undefined) {
			errors.push(`Falta la seccion "${section.name}".`);
			continue;
		}
		if (data === null || typeof data !== "object" || Array.isArray(data)) {
			errors.push(`La seccion "${section.name}" debe ser un objeto { "clave": ID, ... }.`);
			continue;
		}
		for (const key of Object.keys(data)) {
			if (key.startsWith("_")) {
				continue;
			}
			if (!section.expected.includes(key)) {
				const hint = suggest(key, section.expected);
				errors.push(
					`${section.name}.${key}: clave desconocida${hint ? ` (¿quisiste decir "${hint}"?)` : ""}. ` +
						`Las claves validas son: ${section.expected.join(", ")}.`,
				);
			}
		}
		for (const key of section.expected) {
			if (!(key in data)) {
				errors.push(`${section.name}.${key}: falta la clave (debe estar, aunque sea con 0 si esta apagada).`);
				continue;
			}
			const raw = data[key];
			let idValue = raw;
			let assetValue;
			if (raw !== null && typeof raw === "object" && !Array.isArray(raw)) {
				if (!section.allowObject) {
					errors.push(`${section.name}.${key}: los productos llevan un solo ID (un numero), no un objeto.`);
					continue;
				}
				for (const sub of Object.keys(raw)) {
					if (!["passId", "assetId"].includes(sub) && !sub.startsWith("_")) {
						errors.push(`${section.name}.${key}: campo desconocido "${sub}" (solo "passId" y "assetId").`);
					}
				}
				if (!("passId" in raw)) {
					errors.push(`${section.name}.${key}: el objeto necesita "passId".`);
					continue;
				}
				idValue = raw.passId;
				assetValue = raw.assetId;
			}
			const parsed = parseId(idValue);
			if (parsed.error) {
				errors.push(`${section.name}.${key}: ${parsed.error}.`);
				continue;
			}
			let assetId = null;
			if (assetValue !== undefined) {
				const parsedAsset = parseId(assetValue);
				if (parsedAsset.error) {
					errors.push(`${section.name}.${key}.assetId: ${parsedAsset.error}.`);
					continue;
				}
				if (parsedAsset.id === 0) {
					errors.push(`${section.name}.${key}.assetId: 0 no vale; quita el campo si no lo necesitas.`);
					continue;
				}
				if (parsedAsset.id === parsed.id) {
					warnings.push(`${section.name}.${key}: assetId es igual a passId; basta con el numero solo.`);
				} else {
					assetId = parsedAsset.id;
				}
				if (parsed.id === 0) {
					errors.push(`${section.name}.${key}: tiene assetId pero passId es 0.`);
					continue;
				}
			}
			const gated = GATED_KEYS.includes(key);
			const enabled = !gated || paidLuckEnabled;
			if (parsed.id === 0 && enabled) {
				errors.push(`${section.name}.${key}: ID 0 (TODO_ID) pero este ${section.label} esta HABILITADO; falta crearlo en Creator Hub y pegar su ID.`);
			}
			if (parsed.id !== 0 && !enabled && !allowIdsInDisabled) {
				errors.push(
					`${section.name}.${key}: tiene el ID ${parsed.id} pero esta APAGADO a proposito (suerte de pago, flag paidLuckEnabled = false). ` +
						"Dejalo en 0: crear ese objeto en Creator Hub deja recibos sin resolver (README, SHOP-03).",
				);
			}
			if (parsed.id !== 0 && parsed.id < SMALL_ID_WARNING) {
				warnings.push(`${section.name}.${key}: el ID ${parsed.id} es muy pequeno para un ID real de Roblox; revisa que lo copiaste bien.`);
			}
			section.target.set(key, section.name === "passes" ? { passId: parsed.id, assetId } : parsed.id);
		}
	}

	// Duplicados: el mismo numero en dos sitios casi siempre es un copiar/pegar mal hecho (y haria que un recibo
	// concediera el objeto equivocado: SHOP-04).
	const seen = new Map();
	const remember = (id, label) => {
		if (id === 0 || id === null) {
			return;
		}
		if (!seen.has(id)) {
			seen.set(id, []);
		}
		seen.get(id).push(label);
	};
	for (const [key, value] of passes) {
		remember(value.passId, `passes.${key}`);
		remember(value.assetId, `passes.${key}.assetId`);
	}
	for (const [key, id] of products) {
		remember(id, `products.${key}`);
	}
	for (const [id, labels] of seen) {
		if (labels.length > 1) {
			errors.push(`ID repetido ${id}: ${labels.join(", ")}. Cada pase y producto tiene un ID distinto.`);
		}
	}
	return { errors, warnings, passes, products };
}

// ---------------------------------------------------------------------------------------------------------------
// Generacion de ProductIds.luau
// ---------------------------------------------------------------------------------------------------------------

function renderEntries(entries, idFor) {
	return entries
		.map((entry) => {
			const id = idFor(entry.key);
			const note = entry.note;
			if (id === 0) {
				return `\t\t${entry.key} = 0, -- TODO_ID${note ? `  ${note}` : ""}`;
			}
			return `\t\t${entry.key} = ${id},${note ? ` -- ${note}` : ""}`;
		})
		.join("\n");
}

/** Devuelve el texto nuevo de ProductIds.luau (conserva la cabecera y las notas de cada linea). */
export function renderProductIds(structure, result) {
	const passLines = renderEntries(structure.passes, (key) => result.passes.get(key).passId);
	const productLines = renderEntries(structure.products, (key) => result.products.get(key));
	const withAsset = structure.passes.filter((entry) => result.passes.get(entry.key).assetId !== null);
	const assetBlock =
		withAsset.length === 0
			? "\tpassAssetIds = {},"
			: `\tpassAssetIds = {\n${withAsset
					.map((entry) => `\t\t${entry.key} = ${result.passes.get(entry.key).assetId},`)
					.join("\n")}\n\t},`;
	return (
		structure.header +
		"return {\n" +
		`\tpasses = {\n${passLines}\n\t},\n` +
		`\tproducts = {\n${productLines}\n\t},\n` +
		`${assetBlock}\n` +
		"} :: { passes: { [string]: number }, products: { [string]: number }, passAssetIds: { [string]: number } }\n"
	);
}

// ---------------------------------------------------------------------------------------------------------------
// Resumen para humanos
// ---------------------------------------------------------------------------------------------------------------

function buildSummary(structure, result) {
	const lines = [];
	const pad = (text, width) => text + " ".repeat(Math.max(0, width - text.length));
	const rows = [];
	for (const entry of structure.passes) {
		const next = result.passes.get(entry.key);
		if (next) {
			rows.push({ kind: "pase", key: entry.key, before: entry.id, after: next.passId, asset: next.assetId });
		}
	}
	for (const entry of structure.products) {
		const next = result.products.get(entry.key);
		if (next !== undefined) {
			rows.push({ kind: "producto", key: entry.key, before: entry.id, after: next, asset: null });
		}
	}
	const width = Math.max(...rows.map((row) => row.key.length), 10);
	let changes = 0;
	for (const row of rows) {
		const changed = row.before !== row.after;
		if (changed) {
			changes += 1;
		}
		const gated = GATED_KEYS.includes(row.key);
		const state = changed ? "CAMBIA" : "igual ";
		const extra = row.asset !== null ? `  (assetId ${row.asset})` : "";
		const note = row.after === 0 && gated ? "  <- apagado a proposito (v1)" : "";
		lines.push(
			`  ${pad(row.kind, 8)} ${pad(row.key, width)}  ${pad(String(row.before), 12)} -> ${pad(String(row.after), 12)} ${state}${extra}${note}`,
		);
	}
	return { lines, changes };
}

// ---------------------------------------------------------------------------------------------------------------
// Puerta previa a publicar
// ---------------------------------------------------------------------------------------------------------------

/** Ejecuta `FF_RELEASE_CHECK=1 bash ROBLOX/tools/test.sh` y devuelve { status, output }. */
export function runReleaseGate() {
	const result = spawnSync("bash", [path.join(HERE, "test.sh")], {
		env: { ...process.env, FF_RELEASE_CHECK: "1" },
		encoding: "utf8",
		maxBuffer: 64 * 1024 * 1024,
	});
	if (result.error) {
		return { status: 2, output: `No se pudo ejecutar bash ROBLOX/tools/test.sh: ${result.error.message}` };
	}
	return { status: result.status ?? 2, output: `${result.stdout ?? ""}${result.stderr ?? ""}` };
}

/**
 * Comprueba que la salida de test.sh demuestra que la puerta SE EJECUTO (ReleaseGate sin omitidas) y que todo paso.
 * Evita un falso verde si la variable FF_RELEASE_CHECK no llego al proceso de Lune.
 */
export function judgeGateOutput(output, status) {
	if (status !== 0) {
		return { ok: false, reason: `test.sh termino con codigo ${status}` };
	}
	const gateLine = output.split("\n").find((line) => line.includes("ReleaseGate.spec.luau"));
	if (!gateLine) {
		return { ok: false, reason: "no aparece ReleaseGate.spec.luau en la salida de test.sh" };
	}
	const m = /(\d+) passed, (\d+) failed, (\d+) skipped/.exec(gateLine);
	if (!m) {
		return { ok: false, reason: `no se pudo leer el resultado de ReleaseGate: ${gateLine.trim()}` };
	}
	if (Number(m[2]) !== 0 || Number(m[3]) !== 0 || Number(m[1]) < 1) {
		return { ok: false, reason: `ReleaseGate no paso completa (${m[0]}); con FF_RELEASE_CHECK=1 no debe haber omitidas` };
	}
	return { ok: true, reason: gateLine.trim() };
}

// ---------------------------------------------------------------------------------------------------------------
// Script de verificacion para Studio (solo lectura)
// ---------------------------------------------------------------------------------------------------------------

function luauString(text) {
	return `"${String(text).replace(/\\/g, "\\\\").replace(/"/g, '\\"')}"`;
}

/** Genera un script de Luau para `execute_luau` (o la barra de comandos) que NO compra ni escribe nada. */
export function renderVerifyLuau(result, storeItems) {
	const expected = new Map();
	for (const item of storeItems?.items ?? []) {
		expected.set(`${item.kind}:${item.key}`, item);
	}
	const itemLine = (kind, key, ids) => {
		const info = expected.get(`${kind}:${key}`);
		const name = info?.name?.en ?? "";
		const nameEs = info?.name?.es ?? "";
		const price = info?.price ?? 0;
		return `\t{ kind = ${luauString(kind)}, key = ${luauString(key)}, id = ${ids.id}, assetId = ${ids.assetId ?? "nil"}, expectedEn = ${luauString(name)}, expectedEs = ${luauString(nameEs)}, price = ${price} },`;
	};
	const items = [];
	for (const [key, value] of result.passes) {
		if (value.passId !== 0) {
			items.push(itemLine("pass", key, { id: value.passId, assetId: value.assetId }));
		}
	}
	for (const [key, id] of result.products) {
		if (id !== 0) {
			items.push(itemLine("product", key, { id, assetId: null }));
		}
	}
	return [
		"--!nonstrict",
		"-- Generado por ROBLOX/tools/wire-ids.mjs --emit-verify-luau.",
		"-- SOLO LECTURA: consulta GetProductInfoAsync de cada ID. NO compra, NO abre ningun dialogo de pago, NO escribe nada.",
		"-- Ejecutar en Studio con la experiencia de PRUEBA abierta (execute_luau del MCP, datamodel Edit, o la barra de comandos).",
		"local MarketplaceService = game:GetService(\"MarketplaceService\")",
		"local ITEMS = {",
		...items,
		"}",
		"local problems = 0",
		"local function say(line)",
		"\tprint(line)",
		"end",
		"for _, item in ITEMS do",
		"\tlocal infoType = if item.kind == \"pass\" then Enum.InfoType.GamePass else Enum.InfoType.Product",
		"\tlocal ok, info = pcall(function()",
		"\t\treturn MarketplaceService:GetProductInfoAsync(item.id, infoType)",
		"\tend)",
		"\tif not ok then",
		"\t\tproblems += 1",
		"\t\tsay((\"ERROR  %s %s id=%d: GetProductInfoAsync fallo: %s\"):format(item.kind, item.key, item.id, tostring(info)))",
		"\t\tcontinue",
		"\tend",
		"\tlocal notes = {}",
		"\tif item.expectedEn ~= \"\" and info.Name ~= item.expectedEn and info.Name ~= item.expectedEs then",
		"\t\ttable.insert(notes, (\"NOMBRE distinto (esperado '%s' o '%s')\"):format(item.expectedEn, item.expectedEs))",
		"\tend",
		"\tif info.IsForSale ~= true then",
		"\t\ttable.insert(notes, \"NO esta a la venta (IsForSale=false)\")",
		"\tend",
		"\tif item.price > 0 and info.PriceInRobux ~= item.price then",
		"\t\ttable.insert(notes, (\"PRECIO %s distinto del sugerido %d\"):format(tostring(info.PriceInRobux), item.price))",
		"\tend",
		"\tif item.kind == \"pass\" and info.TargetId ~= nil and info.TargetId ~= item.id then",
		"\t\ttable.insert(notes, (\"TargetId=%s DISTINTO del id usado (%d): ver 'TargetId o assetId' en la guia\"):format(tostring(info.TargetId), item.id))",
		"\tend",
		"\tif item.kind == \"product\" and info.ProductId ~= nil and info.ProductId ~= item.id then",
		"\t\ttable.insert(notes, (\"ProductId=%s DISTINTO del id usado (%d)\"):format(tostring(info.ProductId), item.id))",
		"\tend",
		"\tlocal status = if #notes == 0 then \"OK    \" else \"REVISAR\"",
		"\tif #notes > 0 then",
		"\t\tproblems += 1",
		"\tend",
		"\tsay((\"%s %s %s id=%d nombre='%s' precio=%s venta=%s TargetId=%s ProductId=%s %s\"):format(",
		"\t\tstatus, item.kind, item.key, item.id, tostring(info.Name), tostring(info.PriceInRobux), tostring(info.IsForSale),",
		"\t\ttostring(info.TargetId), tostring(info.ProductId), table.concat(notes, \"; \")))",
		"end",
		"say((\"VERIFICACION TERMINADA: %d objeto(s) con avisos de %d\"):format(problems, #ITEMS))",
		"",
	].join("\n");
}

// ---------------------------------------------------------------------------------------------------------------
// Flujo principal (exportado para las pruebas)
// ---------------------------------------------------------------------------------------------------------------

function atomicWrite(file, content) {
	const tmp = path.join(path.dirname(file), `.${path.basename(file)}.${process.pid}.tmp`);
	fs.writeFileSync(tmp, content, "utf8");
	fs.renameSync(tmp, file);
}

/**
 * Ejecuta el flujo completo. `deps` permite a las pruebas inyectar la puerta (runGate) y capturar la salida (log).
 * Devuelve el codigo de salida.
 */
export function run(options, deps = {}) {
	const log = deps.log ?? ((line) => console.log(line));
	const logErr = deps.logErr ?? ((line) => console.error(line));
	const runGate = deps.runGate ?? runReleaseGate;
	const idsFile = path.resolve(options.ids ?? DEFAULT_IDS_FILE);
	const targetFile = path.resolve(options.target ?? DEFAULT_TARGET);
	const flagsFile = path.resolve(options.flags ?? FEATURE_FLAGS_FILE);

	// 1. Leer ids.local.json
	let json;
	try {
		const text = normalizeText(fs.readFileSync(idsFile, "utf8"));
		json = JSON.parse(text);
	} catch (error) {
		if (error && error.code === "ENOENT") {
			logErr(`ERROR: no existe el archivo de IDs: ${idsFile}`);
			logErr("  Copia ids.example.json a ids.local.json (misma carpeta) y rellena los IDs que te dio Creator Hub.");
		} else if (error instanceof SyntaxError) {
			logErr(`ERROR: ${idsFile} no es un JSON valido: ${error.message}`);
			logErr("  Revisa comas, comillas dobles y llaves. Los numeros van sin comillas (o con comillas dobles, nunca simples).");
		} else {
			logErr(`ERROR: no se pudo leer ${idsFile}: ${error.message}`);
		}
		return 2;
	}

	// 2. Leer la estructura actual de ProductIds.luau y el flag
	let structure;
	let originalText;
	try {
		originalText = fs.readFileSync(targetFile, "utf8");
		structure = parseProductIds(originalText);
	} catch (error) {
		logErr(`ERROR: ${error.message}`);
		return 2;
	}
	let paidLuckEnabled = false;
	try {
		paidLuckEnabled = readPaidLuckFlag(fs.readFileSync(flagsFile, "utf8"));
	} catch {
		logErr("AVISO: no se pudo leer FeatureFlags.luau; se asume paidLuckEnabled = false (v1).");
	}

	// 3. Validar
	const result = validateIds(json, structure, { paidLuckEnabled, allowIdsInDisabled: options.allowIdsInDisabled });
	log(`Archivo de IDs : ${idsFile}`);
	log(`Se reescribira : ${targetFile}`);
	log(`Suerte de pago : ${paidLuckEnabled ? "ENCENDIDA (v1.5)" : "APAGADA (v1): luck_plus y lucky_bait_15 pueden seguir en 0"}`);
	for (const warning of result.warnings) {
		log(`AVISO: ${warning}`);
	}
	if (result.errors.length > 0) {
		logErr("");
		logErr(`NO SE CAMBIO NADA: hay ${result.errors.length} problema(s) en los IDs:`);
		for (const error of result.errors) {
			logErr(`  - ${error}`);
		}
		logErr("");
		logErr("Corrige ids.local.json y vuelve a ejecutar. (Nada se escribio y no se corrio ninguna prueba.)");
		return 1;
	}

	// 4. Generar y mostrar
	const newText = renderProductIds(structure, result);
	const summary = buildSummary(structure, result);
	log("");
	log("Resumen (antes -> despues):");
	for (const line of summary.lines) {
		log(line);
	}
	const unchanged = normalizeText(originalText) === newText;
	log("");
	log(unchanged ? "ProductIds.luau ya tiene exactamente estos IDs: nada que cambiar." : `${summary.changes} ID(s) cambian.`);

	if (options.emitVerifyLuau) {
		let storeItems = null;
		try {
			storeItems = JSON.parse(fs.readFileSync(options.storeItems ?? STORE_ITEMS_FILE, "utf8"));
		} catch {
			// opcional: sin store-items.json el script no compara nombres ni precios
		}
		log("");
		log("-- ===== script de verificacion para Studio (copialo tal cual) =====");
		log(renderVerifyLuau(result, storeItems));
		return 0;
	}

	if (options.dryRun) {
		log("");
		log("MODO --dry-run: no se escribio nada y no se corrio la puerta. Quita --dry-run para aplicar.");
		return 0;
	}

	// 5. Escribir (con copia para poder restaurar)
	if (!unchanged) {
		atomicWrite(targetFile, newText);
		log(`Escrito: ${targetFile}`);
	}

	// 6. Formato (StyLua) si esta disponible
	if (!options.noGate) {
		const fmt = deps.runFormat ? deps.runFormat(targetFile) : runFormatCheck(targetFile);
		if (fmt.status === 0) {
			log("Formato (StyLua): OK");
		} else if (fmt.status === 2) {
			log("Formato (StyLua): omitido (stylua no esta instalado; ejecuta ROBLOX/tools/setup.sh).");
		} else {
			if (!unchanged) {
				atomicWrite(targetFile, normalizeText(originalText));
			}
			logErr("ERROR: ProductIds.luau generado NO pasa el formato de StyLua. Se restauro el archivo anterior.");
			logErr(fmt.output);
			return 1;
		}
	}

	// 7. Puerta previa a publicar
	if (options.noGate) {
		log("MODO --no-gate: no se corrio la puerta previa a publicar (FF_RELEASE_CHECK=1). NO publiques sin correrla.");
		return 0;
	}
	log("");
	log("Corriendo la puerta previa a publicar: FF_RELEASE_CHECK=1 bash ROBLOX/tools/test.sh ...");
	const gate = runGate();
	const verdict = judgeGateOutput(gate.output, gate.status);
	if (!verdict.ok) {
		if (!unchanged) {
			atomicWrite(targetFile, normalizeText(originalText));
		}
		logErr(gate.output.split("\n").slice(-40).join("\n"));
		logErr("");
		logErr(`LA PUERTA FALLO (${verdict.reason}).`);
		logErr(
			options.keepOnFail
				? "Se dejo ProductIds.luau con los IDs nuevos (--keep-on-fail)."
				: "Se RESTAURO ProductIds.luau a su estado anterior. ids.local.json sigue intacto: corrige y repite.",
		);
		if (options.keepOnFail && !unchanged) {
			atomicWrite(targetFile, newText);
		}
		return 1;
	}
	log(`PUERTA OK: ${verdict.reason}`);
	log("Listo. Siguiente paso: revisa `git diff ROBLOX/games/fish-and-fortune/src/server/ProductIds.luau` y haz commit.");
	return 0;
}

/** `stylua --check` del archivo (via format.sh). status 2 = stylua no disponible. */
function runFormatCheck(file) {
	const result = spawnSync("bash", [path.join(HERE, "format.sh"), "--check", file], { encoding: "utf8" });
	if (result.error) {
		return { status: 2, output: result.error.message };
	}
	return { status: result.status ?? 2, output: `${result.stdout ?? ""}${result.stderr ?? ""}` };
}

// ---------------------------------------------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------------------------------------------

const HELP = `wire-ids.mjs: cablea los IDs de pases/productos en ProductIds.luau (validando todo antes de escribir).

Uso: node ROBLOX/tools/wire-ids.mjs [opciones]
  --ids <archivo>          JSON de IDs (por defecto ROBLOX/games/fish-and-fortune/ids.local.json)
  --dry-run                solo valida y muestra los cambios; no escribe ni corre pruebas
  --no-gate                escribe pero no corre la puerta previa a publicar (solo para pruebas)
  --keep-on-fail           si la puerta falla, deja los IDs nuevos en lugar de restaurar el archivo
  --allow-ids-in-disabled  permite IDs en objetos apagados por flag (NO recomendado en la v1)
  --emit-verify-luau       imprime el script de Studio (solo lectura) que comprueba cada ID con GetProductInfoAsync
  --target <archivo>       otro ProductIds.luau (para pruebas)
  -h, --help               esta ayuda
Salida: 0 bien · 1 datos invalidos o la puerta fallo · 2 uso incorrecto o error de lectura/escritura.`;

export function parseArgs(argv) {
	const options = {};
	for (let i = 0; i < argv.length; i++) {
		const arg = argv[i];
		switch (arg) {
			case "--ids":
			case "--target":
			case "--flags":
			case "--store-items": {
				const value = argv[++i];
				if (value === undefined || value.startsWith("--")) {
					return { error: `${arg} necesita un valor` };
				}
				options[arg === "--store-items" ? "storeItems" : arg.slice(2)] = value;
				break;
			}
			case "--dry-run":
				options.dryRun = true;
				break;
			case "--no-gate":
				options.noGate = true;
				break;
			case "--keep-on-fail":
				options.keepOnFail = true;
				break;
			case "--allow-ids-in-disabled":
				options.allowIdsInDisabled = true;
				break;
			case "--emit-verify-luau":
				options.emitVerifyLuau = true;
				break;
			case "-h":
			case "--help":
				options.help = true;
				break;
			default:
				return { error: `opcion desconocida: ${arg}` };
		}
	}
	return { options };
}

function main() {
	const parsed = parseArgs(process.argv.slice(2));
	if (parsed.error) {
		console.error(`ERROR: ${parsed.error}\n`);
		console.error(HELP);
		return 2;
	}
	if (parsed.options.help) {
		console.log(HELP);
		return 0;
	}
	return run(parsed.options);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
	process.exitCode = main();
}
