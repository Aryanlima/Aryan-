// Pruebas de publish-place.mjs con un servidor HTTP falso en 127.0.0.1 (sin red real ni clave real).
//   node --test ROBLOX/tools/publish-place.test.mjs
import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import { parseArgs, run } from "./publish-place.mjs";

const FAKE_KEY = "TEST-KEY-do-not-leak-9876543210";

async function startServer({ visibility = "PRIVATE", universeStatus = 200, uploadStatus = 200 } = {}) {
	const state = { requests: [] };
	const server = http.createServer((req, res) => {
		const chunks = [];
		req.on("data", (c) => chunks.push(c));
		req.on("end", () => {
			const url = new URL(req.url, "http://x");
			state.requests.push({ method: req.method, path: url.pathname, query: url.search, key: req.headers["x-api-key"], type: req.headers["content-type"], size: Buffer.concat(chunks).length });
			res.setHeader("content-type", "application/json");
			if (req.method === "GET" && url.pathname.startsWith("/cloud/v2/universes/")) {
				res.statusCode = universeStatus;
				return res.end(JSON.stringify(universeStatus === 200 ? { visibility } : { message: "forbidden" }));
			}
			if (req.method === "POST" && /^\/universes\/v1\/\d+\/places\/\d+\/versions$/.test(url.pathname)) {
				res.statusCode = uploadStatus;
				return res.end(JSON.stringify(uploadStatus === 200 ? { versionNumber: 7 } : { error: `rechazado con ${FAKE_KEY}` }));
			}
			res.statusCode = 404;
			res.end("{}");
		});
	});
	await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
	state.origin = `http://127.0.0.1:${server.address().port}`;
	state.close = () => new Promise((resolve) => server.close(resolve));
	return state;
}

function setup(server, extraEnv = {}) {
	const dir = fs.mkdtempSync(path.join(os.tmpdir(), "publish-place-test-"));
	const rbxl = path.join(dir, "test.rbxl");
	fs.writeFileSync(rbxl, Buffer.from("<roblox-fake-place>"));
	const lines = [];
	const errs = [];
	const env = { ROBLOX_API_KEY: FAKE_KEY, ROBLOX_API_BASE: server?.origin, ...extraEnv };
	return { rbxl, lines, errs, deps: { env, log: (l) => lines.push(l), logErr: (l) => errs.push(l) } };
}

const ids = { universe: "5555555555", place: "6666666666" };

test("PLAN: sin --apply no usa la red ni necesita clave", async () => {
	const ctx = setup(null, { ROBLOX_API_KEY: undefined });
	ctx.deps.fetch = () => assert.fail("no debe usar la red");
	assert.equal(await run(ids, ctx.deps), 0);
	assert.match(ctx.lines.join("\n"), /PLAN/);
});

test("--apply en una experiencia PRIVADA: comprueba visibilidad, sube una version GUARDADA y no filtra la clave", async () => {
	const server = await startServer();
	try {
		const ctx = setup(server);
		assert.equal(await run({ ...ids, apply: true, rbxl: ctx.rbxl }, ctx.deps), 0, ctx.errs.join("\n"));
		assert.equal(server.requests[0].method, "GET");
		const upload = server.requests[1];
		assert.equal(upload.path, "/universes/v1/5555555555/places/6666666666/versions");
		assert.equal(upload.query, "?versionType=Saved");
		assert.equal(upload.type, "application/octet-stream");
		assert.equal(upload.key, FAKE_KEY);
		assert.ok(upload.size > 0);
		assert.ok(![...ctx.lines, ...ctx.errs].join("\n").includes(FAKE_KEY));
		assert.match(ctx.lines.join("\n"), /version 7 \(Saved\)/);
	} finally {
		await server.close();
	}
});

test("--publish usa versionType=Published (solo si la experiencia es privada)", async () => {
	const server = await startServer();
	try {
		const ctx = setup(server);
		assert.equal(await run({ ...ids, apply: true, publish: true, rbxl: ctx.rbxl }, ctx.deps), 0);
		assert.equal(server.requests[1].query, "?versionType=Published");
	} finally {
		await server.close();
	}
});

test("si la experiencia es PUBLICA no sube NADA (code 1)", async () => {
	const server = await startServer({ visibility: "PUBLIC" });
	try {
		const ctx = setup(server);
		assert.equal(await run({ ...ids, apply: true, rbxl: ctx.rbxl }, ctx.deps), 1);
		assert.match(ctx.errs.join("\n"), /NO es privada/);
		assert.equal(server.requests.filter((r) => r.method === "POST").length, 0);
	} finally {
		await server.close();
	}
});

test("falla CERRADO: si no puede comprobar la visibilidad (403), no sube; con --skip-visibility-check si", async () => {
	const server = await startServer({ universeStatus: 403 });
	try {
		const ctx = setup(server);
		assert.equal(await run({ ...ids, apply: true, rbxl: ctx.rbxl }, ctx.deps), 1);
		assert.match(ctx.errs.join("\n"), /No se sube nada/);
		assert.equal(server.requests.filter((r) => r.method === "POST").length, 0);
		const ctx2 = setup(server);
		assert.equal(await run({ ...ids, apply: true, skipVisibilityCheck: true, rbxl: ctx2.rbxl }, ctx2.deps), 0);
		assert.match(ctx2.lines.join("\n"), /omitio la comprobacion/);
	} finally {
		await server.close();
	}
});

test("un error de subida sale con 1 y la clave no aparece aunque el servidor la repita", async () => {
	const server = await startServer({ uploadStatus: 403 });
	try {
		const ctx = setup(server);
		assert.equal(await run({ ...ids, apply: true, rbxl: ctx.rbxl }, ctx.deps), 1);
		const text = ctx.errs.join("\n");
		assert.match(text, /HTTP 403/);
		assert.ok(!text.includes(FAKE_KEY));
		assert.match(text, /clave oculta/);
	} finally {
		await server.close();
	}
});

test("uso incorrecto: IDs invalidos, sin clave, clave por argumento, base no HTTPS", async () => {
	const ctx = setup(null, { ROBLOX_API_KEY: undefined });
	assert.equal(await run({ universe: "x", place: "1" }, ctx.deps), 2);
	assert.equal(await run({ ...ids, apply: true, rbxl: ctx.rbxl }, ctx.deps), 2);
	assert.match(ctx.errs.join("\n"), /ROBLOX_API_KEY/);
	assert.match(parseArgs(["--api-key", "x"]).error, /variable de entorno/);
	const insecure = setup({ origin: "http://example.com" });
	assert.equal(await run({ ...ids, apply: true, rbxl: insecure.rbxl }, insecure.deps), 2);
	assert.match(insecure.errs.join("\n"), /HTTPS/);
	assert.deepEqual(parseArgs(["--universe", "1", "--place", "2", "--apply", "--publish"]).options, { universe: "1", place: "2", apply: true, publish: true });
});

test("no contiene rutas absolutas del equipo", () => {
	const source = fs.readFileSync(new URL("./publish-place.mjs", import.meta.url), "utf8");
	assert.doesNotMatch(source, /[A-Za-z]:\\(?:Users|Windows|Program|Documents)|\/home\/|\/Users\//);
});
