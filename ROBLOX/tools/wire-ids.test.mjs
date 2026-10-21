// Pruebas de wire-ids.mjs (node:test, sin dependencias). Se ejecutan con:
//   node --test ROBLOX/tools/wire-ids.test.mjs
// o, junto con el resto, con `bash ROBLOX/tools/test.sh` (ROBLOX/tools/wire-ids.spec.luau las lanza).
import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import {
	DEFAULT_TARGET,
	FEATURE_FLAGS_FILE,
	GATED_KEYS,
	judgeGateOutput,
	parseArgs,
	parseId,
	parseProductIds,
	readPaidLuckFlag,
	renderProductIds,
	renderVerifyLuau,
	run,
	validateIds,
} from "./wire-ids.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SCRIPT = path.join(HERE, "wire-ids.mjs");
// OJO: ProductIds.luau cambia cuando se cablean los IDs reales; estas pruebas NO pueden depender de que este todo en 0.
// Por eso usan CURRENT (el archivo tal cual esta) solo para leer la estructura y comprobar el viaje de ida y vuelta, y
// BASELINE (el mismo archivo con todo en 0, generado por la propia herramienta) como archivo de partida de cada prueba.
const CURRENT_PRODUCT_IDS = fs.readFileSync(DEFAULT_TARGET, "utf8").replace(/\r\n/g, "\n");
const REAL_FLAGS = fs.readFileSync(FEATURE_FLAGS_FILE, "utf8");
const EXAMPLE = path.join(path.dirname(path.dirname(DEFAULT_TARGET)), "..", "ids.example.json");

const structure = parseProductIds(CURRENT_PRODUCT_IDS);
const PASS_KEYS = structure.passes.map((e) => e.key);
const PRODUCT_KEYS = structure.products.map((e) => e.key);
const ZERO_RESULT = {
	passes: new Map(PASS_KEYS.map((k) => [k, { passId: 0, assetId: null }])),
	products: new Map(PRODUCT_KEYS.map((k) => [k, 0])),
};
const BASELINE = renderProductIds(structure, ZERO_RESULT);

/** IDs buenos y distintos para todo lo habilitado; lo apagado se queda en 0. */
function goodIds() {
	let next = 7_000_000_001;
	const passes = {};
	for (const key of PASS_KEYS) {
		passes[key] = GATED_KEYS.includes(key) ? 0 : next++;
	}
	const products = {};
	for (const key of PRODUCT_KEYS) {
		products[key] = GATED_KEYS.includes(key) ? 0 : next++;
	}
	return { passes, products };
}

function sandbox(idsJson) {
	const dir = fs.mkdtempSync(path.join(os.tmpdir(), "wire-ids-test-"));
	const target = path.join(dir, "ProductIds.luau");
	const flags = path.join(dir, "FeatureFlags.luau");
	const ids = path.join(dir, "ids.local.json");
	fs.writeFileSync(target, BASELINE);
	fs.writeFileSync(flags, REAL_FLAGS);
	fs.writeFileSync(ids, typeof idsJson === "string" ? idsJson : JSON.stringify(idsJson, null, 2));
	return { dir, target, flags, ids };
}

function capture() {
	const out = [];
	const err = [];
	return { out, err, deps: { log: (l) => out.push(l), logErr: (l) => err.push(l), runFormat: () => ({ status: 0, output: "" }) } };
}

const validate = (json, opts = {}) => validateIds(json, structure, opts);

test("la estructura leida de ProductIds.luau tiene los 8 pases y 7 productos del catalogo", () => {
	assert.deepEqual(PASS_KEYS, ["auto_fish", "double_coins", "luck_plus", "starter", "vip", "season_pass", "golden_rod", "bubble_trail"]);
	assert.equal(PRODUCT_KEYS.length, 7);
	assert.equal(readPaidLuckFlag(REAL_FLAGS), false);
	for (const key of GATED_KEYS) {
		assert.ok(PASS_KEYS.includes(key) || PRODUCT_KEYS.includes(key), `clave apagada desconocida: ${key}`);
	}
});

test("IDs buenos: sin errores", () => {
	const result = validate(goodIds());
	assert.deepEqual(result.errors, []);
	assert.equal(result.passes.size, 8);
	assert.equal(result.products.size, 7);
});

test("viaje de ida y vuelta: leer el ProductIds.luau ACTUAL (con ceros o con IDs reales) y volver a generarlo da EXACTAMENTE el mismo texto", () => {
	const assetOf = new Map(structure.passAssetIds.map((e) => [e.key, e.id]));
	const current = {
		passes: new Map(structure.passes.map((e) => [e.key, { passId: e.id, assetId: assetOf.get(e.key) ?? null }])),
		products: new Map(structure.products.map((e) => [e.key, e.id])),
	};
	assert.equal(renderProductIds(structure, current), CURRENT_PRODUCT_IDS);
	// y el archivo de partida de las pruebas (todo en 0) tambien es canonico
	assert.equal(renderProductIds(parseProductIds(BASELINE), ZERO_RESULT), BASELINE);
});

test("render + parse son inversos y ponen los numeros en su clave", () => {
	const result = validate(goodIds());
	const text = renderProductIds(structure, result);
	const reparsed = parseProductIds(text);
	for (const entry of reparsed.passes) {
		assert.equal(entry.id, result.passes.get(entry.key).passId);
	}
	for (const entry of reparsed.products) {
		assert.equal(entry.id, result.products.get(entry.key));
	}
	assert.match(text, /auto_fish = 7000000001, -- \(Pase Auto-Pesca\)/);
	assert.match(text, /luck_plus = 0, -- TODO_ID {2}\(Pase Suerte\+ : ALTERA PROBABILIDADES\)/);
});

test("ID 0 en un objeto HABILITADO es un error claro; en Suerte+ y Cebo de Suerte (apagados) no", () => {
	const ids = goodIds();
	ids.passes.vip = 0;
	const result = validate(ids);
	assert.equal(result.errors.length, 1);
	assert.match(result.errors[0], /passes\.vip: ID 0 \(TODO_ID\)/);
	assert.deepEqual(validate(goodIds()).errors, []);
});

test("con el flag de suerte de pago ENCENDIDO, Suerte+ y Cebo en 0 son errores", () => {
	const result = validate(goodIds(), { paidLuckEnabled: true });
	assert.equal(result.errors.length, 2);
	assert.ok(result.errors.some((e) => e.includes("passes.luck_plus")));
	assert.ok(result.errors.some((e) => e.includes("products.lucky_bait_15")));
});

test("un ID no cero en un objeto apagado es un error (SHOP-03), salvo con la opcion explicita", () => {
	const ids = goodIds();
	ids.products.lucky_bait_15 = 8_000_000_000;
	assert.match(validate(ids).errors[0], /lucky_bait_15.*APAGADO/);
	assert.deepEqual(validate(ids, { allowIdsInDisabled: true }).errors, []);
});

test("IDs repetidos (entre pases, entre productos o entre un pase y un producto) fallan nombrando los dos sitios", () => {
	const ids = goodIds();
	ids.passes.vip = ids.passes.auto_fish;
	ids.products.pearl_pack = ids.products.slot_pack;
	ids.products.coin_boost_15 = ids.passes.starter;
	const errors = validate(ids).errors.join("\n");
	assert.match(errors, /ID repetido 7000000001: passes\.auto_fish, passes\.vip/);
	assert.match(errors, /products\.pearl_pack|products\.slot_pack/);
	assert.match(errors, /passes\.starter, products\.coin_boost_15/);
});

test("IDs negativos, decimales, NaN, texto, URL, listas, booleanos y null se rechazan", () => {
	const bad = [-5, 12.5, "-7", "12.5", "abc", "12a", "https://create.roblox.com/dashboard/creations/experiences/1/passes/22/configure", "", "  ", true, null, [1], 1e30, 2 ** 53];
	for (const value of bad) {
		const ids = goodIds();
		ids.products.pearl_pack = value;
		const result = validate(ids);
		assert.ok(result.errors.length >= 1, `deberia rechazar ${JSON.stringify(value)}`);
		assert.ok(result.errors[0].startsWith("products.pearl_pack:"), result.errors[0]);
	}
	assert.equal(parseId(Number.NaN).error !== undefined, true);
	assert.equal(parseId(Infinity).error !== undefined, true);
});

test("IDs numericos entre comillas se aceptan (Creator Hub los copia como texto)", () => {
	const ids = goodIds();
	ids.products.pearl_pack = " 9100000001 ";
	ids.passes.vip = "9100000002";
	const result = validate(ids);
	assert.deepEqual(result.errors, []);
	assert.equal(result.products.get("pearl_pack"), 9100000001);
	assert.equal(result.passes.get("vip").passId, 9100000002);
});

test("clave que falta, clave desconocida (con sugerencia) y seccion que falta", () => {
	const ids = goodIds();
	delete ids.passes.vip;
	ids.passes.auto_fisch = 5_000_000_000;
	delete ids.products;
	const errors = validate(ids).errors.join("\n");
	assert.match(errors, /passes\.vip: falta la clave/);
	assert.match(errors, /passes\.auto_fisch: clave desconocida \(¿quisiste decir "auto_fish"\?\)/);
	assert.match(errors, /Falta la seccion "products"/);
});

test("el JSON debe ser un objeto; claves desconocidas arriba se rechazan, las que empiezan por _ se ignoran", () => {
	assert.match(validate([]).errors[0], /objeto JSON/);
	assert.match(validate({ ...goodIds(), pasess: {} }).errors[0], /pasess.*¿quisiste decir "passes"\?/);
	assert.deepEqual(validate({ ...goodIds(), _nota: "hola", universeId: 123456789, placeId: "987654321" }).errors, []);
	assert.deepEqual(validate({ ...goodIds(), universeId: 0 }).errors, []);
	assert.match(validate({ ...goodIds(), universeId: "abc" }).errors[0], /universeId/);
});

test("un pase puede llevar { passId, assetId }; un producto no", () => {
	const ids = goodIds();
	ids.passes.vip = { passId: 9_200_000_001, assetId: 9_200_000_002 };
	ids.products.pearl_pack = { passId: 9_200_000_003 };
	const result = validate(ids);
	assert.equal(result.errors.length, 1);
	assert.match(result.errors[0], /products\.pearl_pack: los productos llevan un solo ID/);
	assert.equal(result.passes.get("vip").assetId, 9_200_000_002);
	const text = renderProductIds(structure, result);
	assert.match(text, /passAssetIds = \{\n\t\tvip = 9200000002,\n\t\},/);
});

test("assetId repetido con otro ID, igual a passId o con passId en 0", () => {
	let ids = goodIds();
	ids.passes.vip = { passId: 9_200_000_001, assetId: ids.passes.auto_fish };
	assert.match(validate(ids).errors.join("\n"), /ID repetido 7000000001/);
	ids = goodIds();
	ids.passes.vip = { passId: 9_200_000_001, assetId: 9_200_000_001 };
	const same = validate(ids);
	assert.deepEqual(same.errors, []);
	assert.equal(same.passes.get("vip").assetId, null);
	assert.ok(same.warnings.some((w) => w.includes("assetId es igual a passId")));
	ids = goodIds();
	ids.passes.luck_plus = { passId: 0, assetId: 9_200_000_009 };
	assert.match(validate(ids).errors.join("\n"), /assetId pero passId es 0/);
});

test("IDs muy pequenos (1, 2, 3...) dan aviso pero no error", () => {
	const ids = goodIds();
	ids.products.pearl_pack = 17;
	const result = validate(ids);
	assert.deepEqual(result.errors, []);
	assert.ok(result.warnings.some((w) => w.includes("products.pearl_pack") && w.includes("muy pequeno")));
});

test("run --dry-run valida y muestra el resumen pero NO escribe ni corre la puerta", () => {
	const box = sandbox(goodIds());
	const cap = capture();
	let gateCalled = false;
	const code = run({ ids: box.ids, target: box.target, flags: box.flags, dryRun: true }, { ...cap.deps, runGate: () => (gateCalled = true) });
	assert.equal(code, 0);
	assert.equal(fs.readFileSync(box.target, "utf8"), BASELINE);
	assert.equal(gateCalled, false);
	assert.match(cap.out.join("\n"), /13 ID\(s\) cambian/);
	assert.match(cap.out.join("\n"), /luck_plus .* 0 +-> 0 +igual +<- apagado a proposito/);
	assert.match(cap.out.join("\n"), /--dry-run/);
});

test("run escribe ProductIds.luau, conserva la cabecera y corre la puerta; el resultado es idempotente", () => {
	const box = sandbox(goodIds());
	const cap = capture();
	let gateCalls = 0;
	const okGate = () => {
		gateCalls += 1;
		return { status: 0, output: "PASS  games/fish-and-fortune/tests/ReleaseGate.spec.luau  2 passed, 0 failed, 0 skipped, 2 total (3ms)\n" };
	};
	assert.equal(run({ ids: box.ids, target: box.target, flags: box.flags }, { ...cap.deps, runGate: okGate }), 0);
	const written = fs.readFileSync(box.target, "utf8");
	assert.ok(written.startsWith(structure.header));
	assert.match(written, /auto_fish = 7000000001,/);
	assert.equal(gateCalls, 1);
	assert.match(cap.out.join("\n"), /PUERTA OK/);
	// segunda ejecucion: nada cambia
	const cap2 = capture();
	assert.equal(run({ ids: box.ids, target: box.target, flags: box.flags }, { ...cap2.deps, runGate: okGate }), 0);
	assert.equal(fs.readFileSync(box.target, "utf8"), written);
	assert.match(cap2.out.join("\n"), /nada que cambiar/);
});

test("si la puerta FALLA, se restaura ProductIds.luau y el codigo de salida es 1", () => {
	const box = sandbox(goodIds());
	const cap = capture();
	const code = run(
		{ ids: box.ids, target: box.target, flags: box.flags },
		{ ...cap.deps, runGate: () => ({ status: 1, output: "FAIL  games/fish-and-fortune/tests/ReleaseGate.spec.luau\n" }) },
	);
	assert.equal(code, 1);
	assert.equal(fs.readFileSync(box.target, "utf8"), BASELINE);
	assert.match(cap.err.join("\n"), /LA PUERTA FALLO/);
	assert.match(cap.err.join("\n"), /RESTAURO/);
});

test("con --keep-on-fail los IDs nuevos se conservan aunque la puerta falle", () => {
	const box = sandbox(goodIds());
	const cap = capture();
	const code = run(
		{ ids: box.ids, target: box.target, flags: box.flags, keepOnFail: true },
		{ ...cap.deps, runGate: () => ({ status: 1, output: "FAIL\n" }) },
	);
	assert.equal(code, 1);
	assert.match(fs.readFileSync(box.target, "utf8"), /auto_fish = 7000000001,/);
});

test("si el formato de StyLua falla, se restaura el archivo", () => {
	const box = sandbox(goodIds());
	const cap = capture();
	const code = run(
		{ ids: box.ids, target: box.target, flags: box.flags },
		{ ...cap.deps, runFormat: () => ({ status: 1, output: "Diff in ProductIds.luau" }), runGate: () => assert.fail("no debe correr la puerta") },
	);
	assert.equal(code, 1);
	assert.equal(fs.readFileSync(box.target, "utf8"), BASELINE);
});

test("datos invalidos: codigo 1, no se escribe nada y no se corre la puerta", () => {
	const ids = goodIds();
	ids.passes.vip = -3;
	const box = sandbox(ids);
	const cap = capture();
	const code = run({ ids: box.ids, target: box.target, flags: box.flags }, { ...cap.deps, runGate: () => assert.fail("no debe correr la puerta") });
	assert.equal(code, 1);
	assert.equal(fs.readFileSync(box.target, "utf8"), BASELINE);
	assert.match(cap.err.join("\n"), /NO SE CAMBIO NADA/);
	assert.match(cap.err.join("\n"), /passes\.vip: es negativo/);
});

test("archivo de IDs inexistente o con JSON roto: codigo 2 con mensaje de ayuda", () => {
	const box = sandbox(goodIds());
	let cap = capture();
	assert.equal(run({ ids: path.join(box.dir, "no-existe.json"), target: box.target, flags: box.flags }, cap.deps), 2);
	assert.match(cap.err.join("\n"), /ids\.example\.json a ids\.local\.json/);
	fs.writeFileSync(box.ids, '{ "passes": { "vip": 1, } }');
	cap = capture();
	assert.equal(run({ ids: box.ids, target: box.target, flags: box.flags }, cap.deps), 2);
	assert.match(cap.err.join("\n"), /no es un JSON valido/);
});

test("un JSON con BOM y saltos de linea de Windows se lee bien", () => {
	const box = sandbox("﻿" + JSON.stringify(goodIds(), null, 2).replace(/\n/g, "\r\n"));
	const cap = capture();
	assert.equal(run({ ids: box.ids, target: box.target, flags: box.flags, dryRun: true }, cap.deps), 0);
});

test("judgeGateOutput exige que ReleaseGate se haya EJECUTADO (sin omitidas)", () => {
	const line = (counts) => `PASS  games/fish-and-fortune/tests/ReleaseGate.spec.luau  ${counts}, 2 total (3ms)\n`;
	assert.equal(judgeGateOutput(line("2 passed, 0 failed, 0 skipped"), 0).ok, true);
	assert.equal(judgeGateOutput(line("0 passed, 0 failed, 2 skipped"), 0).ok, false);
	assert.equal(judgeGateOutput(line("1 passed, 1 failed, 0 skipped"), 0).ok, false);
	assert.equal(judgeGateOutput("PASS otra cosa\n", 0).ok, false);
	assert.equal(judgeGateOutput(line("2 passed, 0 failed, 0 skipped"), 1).ok, false);
});

test("el ejemplo ids.example.json FALLA con un mensaje claro mientras tenga ceros (CLI real)", () => {
	const result = spawnSync(process.execPath, [SCRIPT, "--ids", EXAMPLE, "--dry-run"], { encoding: "utf8" });
	assert.equal(result.status, 1);
	assert.match(result.stderr, /NO SE CAMBIO NADA/);
	assert.match(result.stderr, /passes\.auto_fish: ID 0 \(TODO_ID\) pero este pase esta HABILITADO/);
	assert.doesNotMatch(result.stderr, /luck_plus/); // apagado a proposito: no es un problema
	assert.equal(fs.readFileSync(DEFAULT_TARGET, "utf8").replace(/\r\n/g, "\n"), CURRENT_PRODUCT_IDS); // y no toco nada
});

test("CLI real: --dry-run con IDs buenos sale con 0; opciones desconocidas con 2", () => {
	const box = sandbox(goodIds());
	let result = spawnSync(process.execPath, [SCRIPT, "--ids", box.ids, "--target", box.target, "--flags", box.flags, "--dry-run"], { encoding: "utf8" });
	assert.equal(result.status, 0, result.stderr);
	assert.match(result.stdout, /13 ID\(s\) cambian/);
	result = spawnSync(process.execPath, [SCRIPT, "--no-existe"], { encoding: "utf8" });
	assert.equal(result.status, 2);
	assert.match(result.stderr, /opcion desconocida/);
	result = spawnSync(process.execPath, [SCRIPT, "--help"], { encoding: "utf8" });
	assert.equal(result.status, 0);
	assert.match(result.stdout, /dry-run/);
});

test("CLI real con --no-gate: escribe, y el archivo resultante pasa StyLua y lo carga Lune (si estan instalados)", (t) => {
	const box = sandbox(goodIds());
	const result = spawnSync(process.execPath, [SCRIPT, "--ids", box.ids, "--target", box.target, "--flags", box.flags, "--no-gate"], { encoding: "utf8" });
	assert.equal(result.status, 0, result.stderr);
	const written = fs.readFileSync(box.target, "utf8");
	assert.ok(!written.includes("\r"));
	const toolchain = path.join(HERE, "..", ".toolchain", "bin");
	const exe = (name) => path.join(toolchain, process.platform === "win32" ? `${name}.exe` : name);
	if (fs.existsSync(exe("stylua"))) {
		const style = spawnSync(exe("stylua"), ["--config-path", path.join(HERE, "..", "stylua.toml"), "--check", box.target], { encoding: "utf8" });
		assert.equal(style.status, 0, `StyLua: ${style.stdout}${style.stderr}`);
	} else {
		t.diagnostic("stylua no instalado: comprobacion de formato omitida");
	}
	if (fs.existsSync(exe("lune"))) {
		const script = path.join(box.dir, "load.luau");
		fs.writeFileSync(script, `local ids = require("./ProductIds")\nprint(ids.passes.auto_fish, ids.products.slot_pack, ids.passes.luck_plus, next(ids.passAssetIds) == nil)\n`);
		const lune = spawnSync(exe("lune"), ["run", script], { encoding: "utf8" });
		assert.equal(lune.status, 0, `${lune.stdout}${lune.stderr}`);
		assert.match(lune.stdout, /7000000001\s+7000000011\s+0\s+true/);
	} else {
		t.diagnostic("lune no instalado: comprobacion de carga omitida");
	}
});

test("--emit-verify-luau imprime un script de SOLO LECTURA con los IDs y sin compras", () => {
	const ids = goodIds();
	ids.passes.vip = { passId: 9_200_000_001, assetId: 9_200_000_002 };
	const result = validate(ids);
	const text = renderVerifyLuau(result, { items: [{ kind: "pass", key: "vip", name: { en: "VIP Pass", es: "Pase VIP" }, price: 199 }] });
	assert.match(text, /GetProductInfoAsync/);
	assert.match(text, /key = "vip", id = 9200000001, assetId = 9200000002, expectedEn = "VIP Pass", expectedEs = "Pase VIP", price = 199/);
	assert.doesNotMatch(text, /Prompt(GamePass|Product)Purchase\(|ProcessReceipt\s*=|:SetAsync|:UpdateAsync/);
	assert.doesNotMatch(text, /luck_plus/); // apagado: sin ID, no se verifica
	assert.match(text, /^--!nonstrict/);
});

test("parseArgs", () => {
	assert.deepEqual(parseArgs(["--dry-run", "--ids", "a.json"]).options, { dryRun: true, ids: "a.json" });
	assert.match(parseArgs(["--ids"]).error, /necesita un valor/);
	assert.match(parseArgs(["--ids", "--dry-run"]).error, /necesita un valor/);
	assert.match(parseArgs(["--x"]).error, /desconocida/);
});

test("el script no contiene rutas absolutas del equipo ni claves", () => {
	const source = fs.readFileSync(SCRIPT, "utf8");
	assert.doesNotMatch(source, /[A-Za-z]:\\|\/home\/|\/Users\/|api[_-]?key\s*[:=]\s*["'][A-Za-z0-9]{12,}/i);
});
