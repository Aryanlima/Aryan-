// Pruebas de create-items.mjs con un servidor HTTP falso en 127.0.0.1 (no usa la red real ni ninguna clave real).
//   node --test ROBLOX/tools/create-items.test.mjs
import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import { checkBase, parseArgs, run, DEFAULT_STORE_ITEMS } from "./create-items.mjs";
import { parseProductIds, validateIds, DEFAULT_TARGET } from "./wire-ids.mjs";

const FAKE_KEY = "TEST-KEY-do-not-leak-0123456789";
const STORE = JSON.parse(fs.readFileSync(DEFAULT_STORE_ITEMS, "utf8"));

function field(body, name) {
	const m = new RegExp(`name="${name}"(?:; filename="[^"]*")?\\r\\n(?:Content-Type:[^\\r]*\\r\\n)?\\r\\n([\\s\\S]*?)\\r\\n--`).exec(body);
	return m ? m[1] : undefined;
}

/** Servidor falso de Open Cloud (pases y productos). `state.requests` guarda cada peticion. */
async function startServer(options = {}) {
	const state = { passes: [], products: [], requests: [], nextId: 8_100_000_001, ...options };
	const server = http.createServer((req, res) => {
		const chunks = [];
		req.on("data", (c) => chunks.push(c));
		req.on("end", () => {
			const body = Buffer.concat(chunks).toString("latin1");
			const url = new URL(req.url, "http://x");
			state.requests.push({ method: req.method, path: url.pathname, key: req.headers["x-api-key"], body, query: url.search });
			const send = (status, data) => {
				res.writeHead(status, { "content-type": "application/json" });
				res.end(JSON.stringify(data));
			};
			if (req.method === "GET" && url.pathname.startsWith("/cloud/v2/universes/")) {
				return state.universeStatus && state.universeStatus !== 200
					? send(state.universeStatus, { message: "forbidden" })
					: send(200, { visibility: state.visibility ?? "PRIVATE" });
			}
			if (state.failWith) {
				return send(state.failWith, { errorCode: "UnauthorizedAccess", errorMessage: "sin permiso", hint: "revisa los scopes" });
			}
			const passList = /\/game-passes\/v1\/universes\/(\d+)\/game-passes\/creator$/;
			const prodList = /\/developer-products\/v2\/universes\/(\d+)\/developer-products\/creator$/;
			if (req.method === "GET" && passList.test(url.pathname)) {
				return send(200, { gamePasses: state.passes, nextPageToken: null });
			}
			if (req.method === "GET" && prodList.test(url.pathname)) {
				return send(200, { developerProducts: state.products, nextPageToken: null });
			}
			const create = /\/(game-passes\/v1|developer-products\/v2)\/universes\/(\d+)\/(game-passes|developer-products)$/.exec(url.pathname);
			if (req.method === "POST" && create) {
				const isPass = create[3] === "game-passes";
				const id = state.nextId++;
				const entry = { name: field(body, "name"), isForSale: field(body, "isForSale") === "true", [isPass ? "gamePassId" : "productId"]: id };
				(isPass ? state.passes : state.products).push(entry);
				return send(200, entry);
			}
			const patch = /\/(game-passes\/v1|developer-products\/v2)\/universes\/(\d+)\/(game-passes|developer-products)\/(\d+)$/.exec(url.pathname);
			if (req.method === "PATCH" && patch) {
				const list = patch[3] === "game-passes" ? state.passes : state.products;
				const entry = list.find((e) => String(e.gamePassId ?? e.productId) === patch[4]);
				entry.isForSale = field(body, "isForSale") === "true";
				return send(200, entry);
			}
			return send(404, { errorCode: "NotFound" });
		});
	});
	await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
	state.origin = `http://127.0.0.1:${server.address().port}`;
	state.close = () => new Promise((resolve) => server.close(resolve));
	return state;
}

function setup(state, extraEnv = {}) {
	const dir = fs.mkdtempSync(path.join(os.tmpdir(), "create-items-test-"));
	const out = path.join(dir, "ids.local.json");
	const lines = [];
	const errs = [];
	const env = { ROBLOX_API_KEY: FAKE_KEY, ROBLOX_API_BASE: state?.origin, ...extraEnv };
	return { dir, out, lines, errs, env, deps: { env, log: (l) => lines.push(l), logErr: (l) => errs.push(l) } };
}

const base = { universe: "5555555555", delayMs: 0 };

test("PLAN (sin --apply): muestra los 11 objetos, no usa la red y no necesita clave", async () => {
	const ctx = setup(null, { ROBLOX_API_KEY: undefined });
	ctx.deps.fetch = () => assert.fail("el plan no debe usar la red");
	const code = await run({ ...base, out: ctx.out }, ctx.deps);
	assert.equal(code, 0);
	const text = ctx.lines.join("\n");
	assert.match(text, /PLAN \(no se crea nada/);
	assert.match(text, /Auto-Fishing Pass/);
	assert.equal(STORE.items.length, 11);
	assert.doesNotMatch(text, /Luck\+|Lucky Bait/);
	assert.equal(fs.existsSync(ctx.out), false);
});

test("--apply sin ROBLOX_API_KEY: error 2 con instrucciones (la clave va en una variable de entorno)", async () => {
	const ctx = setup(null, { ROBLOX_API_KEY: undefined });
	const code = await run({ ...base, apply: true, out: ctx.out }, ctx.deps);
	assert.equal(code, 2);
	assert.match(ctx.errs.join("\n"), /ROBLOX_API_KEY.*variable de entorno/s);
});

test("--apply crea los 11 objetos FUERA DE VENTA, con icono, guarda ids.local.json y la clave nunca se imprime", async () => {
	const server = await startServer();
	try {
		const ctx = setup(server);
		const code = await run({ ...base, apply: true, out: ctx.out }, ctx.deps);
		assert.equal(code, 0, ctx.errs.join("\n"));
		const posts = server.requests.filter((r) => r.method === "POST");
		assert.equal(posts.length, 11);
		assert.ok(server.requests.every((r) => r.key === FAKE_KEY));
		assert.ok(posts.every((r) => field(r.body, "isForSale") === "false"), "deben crearse fuera de venta");
		assert.ok(posts.every((r) => /name="imageFile"; filename="[\w]+\.png"/.test(r.body)), "cada objeto sube su icono");
		assert.equal(server.passes.length, 5);
		assert.equal(server.products.length, 6);
		const names = posts.map((r) => field(r.body, "name"));
		assert.ok(names.includes("Auto-Fishing Pass") && names.includes("Small Coin Pack"));
		assert.ok(!names.some((n) => /Luck|Lucky/.test(n)));
		const saved = JSON.parse(fs.readFileSync(ctx.out, "utf8"));
		assert.equal(saved.universeId, 5555555555);
		assert.equal(saved.passes.luck_plus, 0);
		assert.equal(saved.products.lucky_bait_15, 0);
		assert.ok(saved.passes.auto_fish >= 8_100_000_001);
		// el archivo producido supera la validacion de wire-ids.mjs (estructura real de ProductIds.luau)
		const structure = parseProductIds(fs.readFileSync(DEFAULT_TARGET, "utf8"));
		assert.deepEqual(validateIds(saved, structure, {}).errors, []);
		const everything = [...ctx.lines, ...ctx.errs].join("\n");
		assert.ok(!everything.includes(FAKE_KEY));
		assert.ok(!fs.readFileSync(ctx.out, "utf8").includes(FAKE_KEY));
	} finally {
		await server.close();
	}
});

test("ROBLOX_API_KEY_VIA_PROXY=1 (secreto de red de la nube): no necesita la clave y no envia x-api-key", async () => {
	const server = await startServer();
	try {
		const ctx = setup(server, { ROBLOX_API_KEY: undefined, ROBLOX_API_KEY_VIA_PROXY: "1" });
		assert.equal(await run({ ...base, apply: true, out: ctx.out }, ctx.deps), 0, ctx.errs.join("\n"));
		assert.ok(server.requests.length > 11);
		assert.ok(server.requests.every((r) => r.key === undefined));
	} finally {
		await server.close();
	}
});

test("es IDEMPOTENTE: repetir el comando no crea duplicados", async () => {
	const server = await startServer();
	try {
		const ctx = setup(server);
		assert.equal(await run({ ...base, apply: true, out: ctx.out }, ctx.deps), 0);
		const first = fs.readFileSync(ctx.out, "utf8");
		const before = server.requests.filter((r) => r.method === "POST").length;
		const ctx2 = setup(server);
		assert.equal(await run({ ...base, apply: true, out: ctx.out }, ctx2.deps), 0);
		assert.equal(server.requests.filter((r) => r.method === "POST").length, before);
		assert.equal(fs.readFileSync(ctx.out, "utf8"), first);
		assert.match(ctx2.lines.join("\n"), /0 creado\(s\), 11 ya existian/);
	} finally {
		await server.close();
	}
});

test("--for-sale: crea a la venta y, en objetos que ya existian fuera de venta, los pone a la venta", async () => {
	const server = await startServer();
	try {
		const ctx = setup(server);
		assert.equal(await run({ ...base, apply: true, out: ctx.out }, ctx.deps), 0);
		assert.ok(server.passes.every((p) => p.isForSale === false));
		const ctx2 = setup(server);
		assert.equal(await run({ ...base, apply: true, forSale: true, out: ctx.out }, ctx2.deps), 0);
		assert.ok(server.passes.every((p) => p.isForSale === true));
		assert.ok(server.products.every((p) => p.isForSale === true));
		assert.equal(server.requests.filter((r) => r.method === "PATCH").length, 11);
	} finally {
		await server.close();
	}
});

test("--for-sale SOLO en una experiencia PRIVADA: si es publica, o no se puede comprobar, no crea nada", async () => {
	for (const options of [{ visibility: "PUBLIC" }, { universeStatus: 403 }]) {
		const server = await startServer(options);
		try {
			const ctx = setup(server);
			const code = await run({ ...base, apply: true, forSale: true, out: ctx.out }, ctx.deps);
			assert.equal(code, 1);
			assert.match(ctx.errs.join("\n"), /NO es privada|No se pudo comprobar que la experiencia es privada/);
			assert.equal(server.requests.filter((r) => r.method === "POST" || r.method === "PATCH").length, 0);
			assert.equal(fs.existsSync(ctx.out), false);
		} finally {
			await server.close();
		}
	}
	// con la comprobacion omitida a mano si crea
	const server = await startServer({ universeStatus: 403 });
	try {
		const ctx = setup(server);
		assert.equal(await run({ ...base, apply: true, forSale: true, skipVisibilityCheck: true, out: ctx.out }, ctx.deps), 0);
		assert.ok(server.passes.every((p) => p.isForSale === true));
	} finally {
		await server.close();
	}
});

test("un 403 da un mensaje claro con la pista de permisos, sale con 1 y no filtra la clave", async () => {
	const server = await startServer({ failWith: 403 });
	try {
		const ctx = setup(server);
		const code = await run({ ...base, apply: true, out: ctx.out }, ctx.deps);
		assert.equal(code, 1);
		const text = ctx.errs.join("\n");
		assert.match(text, /HTTP 403/);
		assert.match(text, /scopes game-pass y developer-product/);
		assert.match(text, /Nada se borro/);
		assert.ok(!text.includes(FAKE_KEY));
	} finally {
		await server.close();
	}
});

test("dos objetos con el mismo nombre en Creator Hub: error ANTES de crear nada", async () => {
	const server = await startServer({ passes: [{ name: "VIP Pass", gamePassId: 1111111111 }, { name: "VIP Pass", gamePassId: 2222222222 }] });
	try {
		const ctx = setup(server);
		const code = await run({ ...base, apply: true, out: ctx.out }, ctx.deps);
		assert.equal(code, 1);
		assert.match(ctx.errs.join("\n"), /2 pases llamados "VIP Pass"/);
		assert.equal(server.requests.filter((r) => r.method === "POST").length, 0);
	} finally {
		await server.close();
	}
});

test("si ids.local.json ya tiene OTRO ID para un objeto que existe, no crea ni pisa nada", async () => {
	const server = await startServer({ passes: [{ name: "VIP Pass", gamePassId: 3333333333, isForSale: false }] });
	try {
		const ctx = setup(server);
		fs.writeFileSync(ctx.out, JSON.stringify({ passes: { vip: 4444444444 }, products: {} }));
		const code = await run({ ...base, apply: true, out: ctx.out }, ctx.deps);
		assert.equal(code, 1);
		assert.match(ctx.errs.join("\n"), /passes\.vip = 4444444444, distinto del ID de Creator Hub \(3333333333\)/);
		assert.equal(JSON.parse(fs.readFileSync(ctx.out, "utf8")).passes.vip, 4444444444);
	} finally {
		await server.close();
	}
});

test("un ID ya cableado a mano (sin objeto con ese nombre) NO se duplica", async () => {
	const server = await startServer();
	try {
		const ctx = setup(server);
		fs.writeFileSync(ctx.out, JSON.stringify({ passes: { vip: 4444444444 }, products: {} }));
		assert.equal(await run({ ...base, apply: true, out: ctx.out }, ctx.deps), 0);
		assert.equal(server.requests.filter((r) => r.method === "POST").length, 10);
		assert.equal(JSON.parse(fs.readFileSync(ctx.out, "utf8")).passes.vip, 4444444444);
	} finally {
		await server.close();
	}
});

test("validaciones de uso: universo invalido, base no HTTPS, clave por argumento", async () => {
	const ctx = setup(null);
	assert.equal(await run({ universe: "abc", out: ctx.out }, ctx.deps), 2);
	assert.equal(await run({ universe: "0", out: ctx.out }, ctx.deps), 2);
	const insecure = setup({ origin: "http://example.com" });
	assert.equal(await run({ ...base, apply: true, out: insecure.out }, insecure.deps), 2);
	assert.match(insecure.errs.join("\n"), /HTTPS/);
	assert.throws(() => checkBase("ftp://x"), /HTTPS/);
	assert.equal(checkBase("https://apis.roblox.com"), "https://apis.roblox.com");
	assert.match(parseArgs(["--api-key", "abc"]).error, /variable de entorno/);
	assert.match(parseArgs(["--apikey=abc"]).error, /variable de entorno/);
	assert.deepEqual(parseArgs(["--universe", "1", "--apply", "--for-sale"]).options, { universe: "1", apply: true, forSale: true });
});

test("el script no contiene rutas absolutas ni claves", () => {
	const source = fs.readFileSync(new URL("./create-items.mjs", import.meta.url), "utf8");
	assert.doesNotMatch(source, /[A-Za-z]:\\(?:Users|Windows|Program|Documents)|\/home\/|\/Users\//);
});
