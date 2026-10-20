#!/usr/bin/env node
// create-items.mjs: crea en Creator Hub (por Open Cloud, API BETA) los pases y productos de Fish & Fortune y guarda sus
// IDs en ids.local.json, listos para `node ROBLOX/tools/wire-ids.mjs`. ALTERNATIVA a crearlos a mano en la web.
//
// Lo que hace, por defecto (SIN --apply) es solo MOSTRAR el plan; no usa la red ni necesita clave.
//   node ROBLOX/tools/create-items.mjs --universe 1234567890                  # plan (nada se crea)
//   node ROBLOX/tools/create-items.mjs --universe 1234567890 --apply          # crea lo que falte
//   node ROBLOX/tools/create-items.mjs --universe 1234567890 --apply --for-sale   # ademas los pone A LA VENTA
//
// Seguridad:
//   * La clave de Open Cloud se lee SOLO de la variable de entorno ROBLOX_API_KEY. Nunca de argumentos ni de archivos,
//     y nunca se imprime. Permisos minimos de la clave: game-pass:read, game-pass:write, developer-product:read,
//     developer-product:write, limitada a ESTA experiencia (ver ROBLOX/docs/publicar-paso-a-paso.md, Etapa 2).
//   * Sin --for-sale los objetos se crean FUERA DE VENTA (isForSale=false): nadie puede comprarlos. Es reversible: se
//     borran desde Creator Hub; esta herramienta nunca borra nada.
//   * Es idempotente: antes de crear consulta lo que ya existe (por nombre) y reutiliza su ID; no duplica.
//   * No crea Suerte+ ni Cebo de Suerte (apagados en la v1): solo lo que lista store-items.json.
//   * Con --for-sale comprueba antes (GET /cloud/v2/universes/{id}) que la experiencia es PRIVATE; si no puede, no hace nada.
//   * Nunca cambia la visibilidad de la experiencia (no hay ningun endpoint de ese tipo en esta herramienta).
//
// Endpoints (BETA, create-docs reference/cloud/game-passes-http-service/v1.json y developer-products-api/v1.json):
//   POST  /game-passes/v1/universes/{universeId}/game-passes                    scope game-pass:write      (5 peticiones/s)
//   GET   /game-passes/v1/universes/{universeId}/game-passes/creator            scope game-pass:read
//   PATCH /game-passes/v1/universes/{universeId}/game-passes/{gamePassId}       scope game-pass:write
//   POST  /developer-products/v2/universes/{universeId}/developer-products      scope developer-product:write (3/s)
//   GET   /developer-products/v2/universes/{universeId}/developer-products/creator   scope developer-product:read
//   PATCH /developer-products/v2/universes/{universeId}/developer-products/{productId}
//
// Salida: 0 bien · 1 error de la API o datos · 2 uso incorrecto.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROBLOX_ROOT = path.resolve(HERE, "..");
const GAME_DIR = path.join(ROBLOX_ROOT, "games", "fish-and-fortune");
export const DEFAULT_STORE_ITEMS = path.join(GAME_DIR, "store-items.json");
export const DEFAULT_OUT = path.join(GAME_DIR, "ids.local.json");
const DEFAULT_BASE = "https://apis.roblox.com";
const MAX_PAGES = 20;

/** Valida la base de la API: https salvo bucle local (solo para las pruebas). */
export function checkBase(base) {
	let url;
	try {
		url = new URL(base);
	} catch {
		throw new Error(`ROBLOX_API_BASE no es una URL valida: ${base}`);
	}
	const local = ["127.0.0.1", "localhost", "[::1]"].includes(url.hostname);
	if (url.protocol !== "https:" && !(local && url.protocol === "http:")) {
		throw new Error("La API debe usarse por HTTPS (solo se admite http en 127.0.0.1 para pruebas).");
	}
	return url.origin;
}

const endpoints = (universeId) => ({
	pass: {
		list: `/game-passes/v1/universes/${universeId}/game-passes/creator`,
		create: `/game-passes/v1/universes/${universeId}/game-passes`,
		update: (id) => `/game-passes/v1/universes/${universeId}/game-passes/${id}`,
		listField: "gamePasses",
		idField: "gamePassId",
	},
	product: {
		list: `/developer-products/v2/universes/${universeId}/developer-products/creator`,
		create: `/developer-products/v2/universes/${universeId}/developer-products`,
		update: (id) => `/developer-products/v2/universes/${universeId}/developer-products/${id}`,
		listField: "developerProducts",
		idField: "productId",
	},
});

function describeApiError(status, bodyText) {
	let detail = "";
	try {
		const body = JSON.parse(bodyText);
		const parts = [body.errorCode, body.errorMessage, body.hint, body.field && `campo ${body.field}`, body.message, body.code]
			.filter(Boolean)
			.map(String);
		detail = parts.join(" - ");
	} catch {
		detail = bodyText.slice(0, 200).replace(/\s+/g, " ");
	}
	const hints = {
		401: "La clave no es valida o no esta definida (variable ROBLOX_API_KEY).",
		403: "La clave no tiene el permiso necesario o no esta limitada a esta experiencia (scopes game-pass y developer-product, lectura y escritura).",
		404: "No se encontro la experiencia (universeId incorrecto) o el objeto.",
		429: "Demasiadas peticiones: espera un minuto y repite (la herramienta es idempotente).",
	};
	return `HTTP ${status}${detail ? ` (${detail})` : ""}. ${hints[status] ?? ""}`.trim();
}

async function request(ctx, method, route, { form, query } = {}) {
	const url = new URL(route, ctx.base);
	for (const [key, value] of Object.entries(query ?? {})) {
		if (value !== undefined && value !== null && value !== "") {
			url.searchParams.set(key, String(value));
		}
	}
	const response = await ctx.fetch(url, { method, headers: ctx.apiKey ? { "x-api-key": ctx.apiKey } : {}, body: form });
	const text = await response.text();
	if (!response.ok) {
		throw new Error(`${method} ${route}: ${describeApiError(response.status, text)}`);
	}
	try {
		return text ? JSON.parse(text) : {};
	} catch {
		throw new Error(`${method} ${route}: la respuesta no es JSON.`);
	}
}

async function listAll(ctx, kind) {
	const ep = ctx.endpoints[kind];
	const found = [];
	let token;
	for (let page = 0; page < MAX_PAGES; page++) {
		const data = await request(ctx, "GET", ep.list, { query: { pageSize: 100, pageToken: token } });
		found.push(...(data[ep.listField] ?? []));
		token = data.nextPageToken;
		if (!token) {
			return found;
		}
	}
	throw new Error(`Mas de ${MAX_PAGES} paginas de ${kind === "pass" ? "pases" : "productos"}: algo no cuadra; revisa Creator Hub.`);
}

function buildForm(item, { forSale, withImage }) {
	const form = new FormData();
	form.set("name", item.name.en);
	form.set("description", item.description.en);
	form.set("price", String(item.price));
	form.set("isForSale", forSale ? "true" : "false");
	if (withImage && item.icon) {
		const file = path.join(ROBLOX_ROOT, item.icon);
		form.set("imageFile", new Blob([fs.readFileSync(file)], { type: "image/png" }), path.basename(file));
	}
	return form;
}

/** Lee ids.local.json existente (si lo hay) para no pisar IDs ya cableados. */
function readExisting(outFile) {
	try {
		return JSON.parse(fs.readFileSync(outFile, "utf8").replace(/^﻿/, ""));
	} catch {
		return null;
	}
}

/** Estructura de salida: todas las claves de store-items + las apagadas (Suerte+, Cebo) en 0. */
function emptyIds(example) {
	return { passes: { ...example.passes }, products: { ...example.products } };
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Flujo principal. `deps`: { fetch, env, log, logErr } (inyectables para las pruebas). Devuelve el codigo de salida.
 */
export async function run(options, deps = {}) {
	const log = deps.log ?? ((line) => console.log(line));
	const logErr = deps.logErr ?? ((line) => console.error(line));
	const env = deps.env ?? process.env;
	const storeFile = path.resolve(options.storeItems ?? DEFAULT_STORE_ITEMS);
	const outFile = path.resolve(options.out ?? DEFAULT_OUT);
	const exampleFile = path.resolve(options.example ?? path.join(path.dirname(DEFAULT_STORE_ITEMS), "ids.example.json"));

	const universe = String(options.universe ?? env.ROBLOX_UNIVERSE_ID ?? "").trim();
	if (!/^[1-9]\d{0,14}$/.test(universe)) {
		logErr("ERROR: falta --universe <ID> (o la variable ROBLOX_UNIVERSE_ID): el Universe ID es un numero entero (Creator Hub > ... > Copy Universe ID).");
		return 2;
	}
	let store;
	let example;
	try {
		store = JSON.parse(fs.readFileSync(storeFile, "utf8"));
		example = JSON.parse(fs.readFileSync(exampleFile, "utf8"));
	} catch (error) {
		logErr(`ERROR: no se pudo leer store-items.json / ids.example.json: ${error.message}`);
		return 2;
	}
	const items = store.items ?? [];
	if (items.length === 0) {
		logErr("ERROR: store-items.json no lista ningun objeto.");
		return 2;
	}

	log(`Experiencia (Universe ID): ${universe}`);
	log(`Modo: ${options.apply ? "APLICAR (crea lo que falte)" : "PLAN (no se crea nada; no usa la red)"}${options.forSale ? " · A LA VENTA" : " · fuera de venta"}`);
	log("");
	log("Objetos (de store-items.json; Suerte+ y Cebo de Suerte NO se crean: apagados en la v1):");
	for (const item of items) {
		log(`  ${item.kind === "pass" ? "pase    " : "producto"} ${item.key.padEnd(18)} ${String(item.price).padStart(5)} R$  ${item.name.en}  [icono: ${item.icon ?? "ninguno"}]`);
	}
	if (!options.apply) {
		log("");
		log("Es solo el plan. Para crear: define ROBLOX_API_KEY (clave con permisos minimos) y agrega --apply.");
		return 0;
	}

	// Dos formas de tener la clave: la variable de entorno ROBLOX_API_KEY (sesion del PC) o, en la sesion de la nube con un
	// "secreto de red" (docs/dar-acceso-a-claude.md), ROBLOX_API_KEY_VIA_PROXY=1: el proxy anade la cabecera x-api-key y esta
	// herramienta no ve la clave nunca [NO VERIFICADO: comportamiento del proxy].
	const apiKey = (env.ROBLOX_API_KEY ?? "").trim();
	const viaProxy = env.ROBLOX_API_KEY_VIA_PROXY === "1";
	if (apiKey === "" && !viaProxy) {
		logErr("ERROR: falta la variable de entorno ROBLOX_API_KEY. Pidele a Aryan que cree la clave (permisos minimos) y la guarde en una variable de entorno; NUNCA en un archivo ni en el chat.");
		return 2;
	}
	let base;
	try {
		base = checkBase(env.ROBLOX_API_BASE ?? DEFAULT_BASE);
	} catch (error) {
		logErr(`ERROR: ${error.message}`);
		return 2;
	}
	const ctx = { base, apiKey, fetch: deps.fetch ?? globalThis.fetch, endpoints: endpoints(universe) };
	const delayMs = options.delayMs ?? 450;

	try {
		// Poner objetos A LA VENTA solo se permite en una experiencia PRIVADA (falla cerrado, igual que publish-place.mjs).
		if (options.forSale) {
			if (options.skipVisibilityCheck) {
				log("AVISO: se omitio la comprobacion de visibilidad (--skip-visibility-check). Confirma en Creator Hub que la experiencia es privada.");
			} else {
				const info = await request(ctx, "GET", `/cloud/v2/universes/${universe}`).catch((error) => {
					throw new Error(`No se pudo comprobar que la experiencia es privada (${error.message}). No se creo nada. Anade el permiso de lectura de la experiencia a la clave, o confirma en Creator Hub que es privada y usa --skip-visibility-check.`);
				});
				if (info.visibility !== "PRIVATE") {
					throw new Error(`La experiencia NO es privada (visibility = ${info.visibility}): no se ponen objetos a la venta ni se crea nada.`);
				}
				log("Comprobado: la experiencia es PRIVADA.");
			}
		}
		const result = emptyIds(example);
		const previous = readExisting(outFile);
		const saved = { passes: previous?.passes ?? {}, products: previous?.products ?? {} };
		for (const group of ["passes", "products"]) {
			for (const [key, value] of Object.entries(saved[group])) {
				if (key in result[group] && !key.startsWith("_")) {
					result[group][key] = value; // lo ya cableado se conserva en cada guardado
				}
			}
		}
		const existingByKind = {};
		for (const kind of ["pass", "product"]) {
			existingByKind[kind] = await listAll(ctx, kind);
		}

		// FASE 1 (sin escribir nada): decidir que hacer con cada objeto y detener TODO ante cualquier duda.
		const plan = items.map((item) => {
			const ep = ctx.endpoints[item.kind];
			const group = item.kind === "pass" ? "passes" : "products";
			const matches = existingByKind[item.kind].filter((entry) => entry.name === item.name.en);
			if (matches.length > 1) {
				throw new Error(`Hay ${matches.length} ${item.kind === "pass" ? "pases" : "productos"} llamados "${item.name.en}" en Creator Hub: borra los repetidos a mano y repite. No se creo nada.`);
			}
			const already = saved[group][item.key];
			const alreadyId = Number(already !== null && typeof already === "object" ? already.passId : already) || 0;
			if (matches.length === 1) {
				const id = matches[0][ep.idField];
				if (alreadyId !== 0 && alreadyId !== id) {
					throw new Error(`ids.local.json ya tiene ${group}.${item.key} = ${alreadyId}, distinto del ID de Creator Hub (${id}). Revisa cual es el correcto; no se creo ni se piso nada.`);
				}
				return { item, ep, group, action: "exists", id, match: matches[0], already };
			}
			if (alreadyId !== 0) {
				return { item, ep, group, action: "wired", id: alreadyId, already };
			}
			return { item, ep, group, action: "create", id: 0, already };
		});

		// FASE 2: ejecutar.
		let created = 0;
		let reused = 0;
		log("");
		for (const step of plan) {
			const { item, ep, group, already } = step;
			let id = step.id;
			if (step.action === "exists") {
				reused += 1;
				log(`  ya existia  ${item.key.padEnd(18)} id ${id}`);
				if (options.forSale && step.match.isForSale !== true) {
					const patch = new FormData();
					patch.set("isForSale", "true");
					await request(ctx, "PATCH", ep.update(id), { form: patch });
					log(`              ${item.key}: puesto A LA VENTA`);
				}
			} else if (step.action === "wired") {
				reused += 1;
				log(`  ya tenia ID en ids.local.json (${id}) y no hay uno con ese nombre en Creator Hub: no se crea`);
			} else {
				const body = await request(ctx, "POST", ep.create, { form: buildForm(item, { forSale: options.forSale === true, withImage: true }) });
				id = body[ep.idField];
				if (!Number.isSafeInteger(id) || id <= 0) {
					throw new Error(`La API no devolvio un ${ep.idField} valido para ${item.key}.`);
				}
				created += 1;
				log(`  CREADO      ${item.key.padEnd(18)} id ${id}`);
				await sleep(delayMs); // limites: 5/s (pases), 3/s (productos)
			}
			result[group][item.key] = already !== null && typeof already === "object" ? { ...already, passId: id } : id;
			// guardado incremental: si algo falla a mitad, lo creado no se pierde
			fs.writeFileSync(outFile, `${JSON.stringify({ universeId: Number(universe), ...result }, null, 2)}\n`, "utf8");
		}
		log("");
		log(`Listo: ${created} creado(s), ${reused} ya existian. IDs guardados en ${outFile}`);
		log("Siguiente paso: node ROBLOX/tools/wire-ids.mjs --dry-run   (y luego sin --dry-run).");
		return 0;
	} catch (error) {
		logErr(`ERROR: ${ctx.apiKey ? String(error.message).split(ctx.apiKey).join("[clave oculta]") : String(error.message)}`);
		logErr("Nada se borro. Lo ya creado esta en Creator Hub y en ids.local.json; al repetir el comando no se duplica.");
		return 1;
	}
}

const HELP = `create-items.mjs: crea los pases y productos de Fish & Fortune por Open Cloud (API BETA) y guarda sus IDs.

Uso: node ROBLOX/tools/create-items.mjs --universe <ID> [--apply] [--for-sale]
  --universe <ID>   Universe ID de la experiencia (o variable ROBLOX_UNIVERSE_ID)
  --apply           crea de verdad (sin esto solo muestra el plan, sin red)
  --for-sale        crea/pone los objetos A LA VENTA (por defecto se crean fuera de venta). Solo si la experiencia es PRIVADA
                    (se comprueba por API; --skip-visibility-check solo si una persona ya lo confirmo en Creator Hub)
  --out <archivo>   donde guardar los IDs (por defecto games/fish-and-fortune/ids.local.json)
  --store-items <archivo>   otro store-items.json (pruebas)
Requiere la variable de entorno ROBLOX_API_KEY solo con --apply (nunca se acepta por argumento).`;

export function parseArgs(argv) {
	const options = {};
	for (let i = 0; i < argv.length; i++) {
		const arg = argv[i];
		if (["--universe", "--out", "--store-items", "--example", "--delay-ms"].includes(arg)) {
			const value = argv[++i];
			if (value === undefined || value.startsWith("--")) {
				return { error: `${arg} necesita un valor` };
			}
			const name = { "--store-items": "storeItems", "--delay-ms": "delayMs" }[arg] ?? arg.slice(2);
			options[name] = name === "delayMs" ? Number(value) : value;
		} else if (arg === "--apply") {
			options.apply = true;
		} else if (arg === "--for-sale") {
			options.forSale = true;
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
