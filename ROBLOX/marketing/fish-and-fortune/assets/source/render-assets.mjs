#!/usr/bin/env node
// Genera TODOS los placeholders de Fish & Fortune: SVG (source/svg) -> PNG (icon/, thumbnails/, passes/, products/)
// + hoja de contactos + informe de validacion (assets-manifest.json).
//
// Uso (desde esta carpeta, despues de `npm install`):
//   node render-assets.mjs                      # todo
//   node render-assets.mjs --only=vip,icon-b-fortu   # solo algunas piezas (ids del manifiesto)
//   node render-assets.mjs --no-sheet           # sin hoja de contactos
//   node render-assets.mjs --validate-only      # solo valida los PNG ya generados
//
// Requisitos: Node >= 20, playwright-core (npm install), un Chromium (CHROMIUM_PATH o /opt/pw-browsers o el de Playwright)
// e ImageMagick (`magick` o `convert`) para optimizar PNG. No hay IA ni red: todo es codigo.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { execFileSync } from 'node:child_process';
import { chromium } from 'playwright-core';
import { svgDoc, esc, C } from './lib/core.mjs';
import { ASSETS, DISABLED, SAFE_R, W, H } from './lib/assets.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.resolve(HERE, '..'); // .../assets
const BUILD = path.join(HERE, 'build');
const SVG_DIR = path.join(HERE, 'svg');
const args = process.argv.slice(2);
const flag = (n) => args.includes(`--${n}`);
const opt = (n) => (args.find((a) => a.startsWith(`--${n}=`)) || '').split('=').slice(1).join('=');
const only = opt('only') ? new Set(opt('only').split(',')) : null;

const mkdirp = (p) => fs.mkdirSync(p, { recursive: true });

// ---------------------------------------------------------------- utilidades: Chromium e ImageMagick
function findChromium() {
  if (process.env.CHROMIUM_PATH && fs.existsSync(process.env.CHROMIUM_PATH)) return process.env.CHROMIUM_PATH;
  const roots = [process.env.PLAYWRIGHT_BROWSERS_PATH, '/opt/pw-browsers', path.join(process.env.HOME || process.env.USERPROFILE || '', '.cache', 'ms-playwright'), path.join(process.env.LOCALAPPDATA || '', 'ms-playwright')].filter(Boolean);
  const cands = [];
  for (const r of roots) {
    if (!fs.existsSync(r)) continue;
    for (const d of fs.readdirSync(r).sort().reverse()) {
      if (d.startsWith('chromium_headless_shell')) cands.unshift(path.join(r, d, 'chrome-linux', 'headless_shell'), path.join(r, d, 'chrome-headless-shell-win64', 'chrome-headless-shell.exe'));
      else if (d.startsWith('chromium-')) cands.push(path.join(r, d, 'chrome-linux', 'chrome'), path.join(r, d, 'chrome-win', 'chrome.exe'));
    }
  }
  const hit = cands.find((c) => fs.existsSync(c));
  if (hit) return hit;
  try { const p = chromium.executablePath(); if (p && fs.existsSync(p)) return p; } catch { /* sin navegador */ }
  throw new Error('No se encontro Chromium. Define CHROMIUM_PATH=/ruta/a/chrome o PLAYWRIGHT_BROWSERS_PATH.');
}

let IM = null;
function im(argv, opts = {}) {
  if (!IM) {
    for (const cand of [['magick'], ['convert']]) {
      try { execFileSync(cand[0], ['-version'], { stdio: 'ignore' }); IM = cand; break; } catch { /* siguiente */ }
    }
    if (!IM) throw new Error('Falta ImageMagick (magick o convert).');
  }
  return execFileSync(IM[0], argv, { maxBuffer: 1 << 28, ...opts });
}
const identify = (f) => {
  im(['-version']); // fija IM
  const out = (IM[0] === 'magick' ? execFileSync('magick', ['identify', '-format', '%w %h %m %[channels]', f]) : execFileSync('identify', ['-format', '%w %h %m %[channels]', f])).toString().trim().split(' ');
  return { w: +out[0], h: +out[1], fmt: out[2], channels: out.slice(3).join(' ') };
};

// ---------------------------------------------------------------- contraste WCAG
const lin = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; };
const lum = (r, g, b) => 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
const hexRgb = (h) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16));
const ratio = (l1, l2) => (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);

// ---------------------------------------------------------------- render
async function renderAll(list) {
  mkdirp(BUILD); mkdirp(SVG_DIR); mkdirp(path.join(BUILD, 'raw')); mkdirp(path.join(BUILD, 'subject')); mkdirp(path.join(BUILD, 'notext'));
  const browser = await chromium.launch({ executablePath: findChromium(), headless: true, args: ['--no-sandbox', '--disable-gpu', '--hide-scrollbars', '--force-color-profile=srgb', '--font-render-hinting=none', '--allow-file-access-from-files'] });
  const ctx = await browser.newContext({ viewport: { width: 512, height: 512 }, deviceScaleFactor: 1 });
  const page = await ctx.newPage();
  page.on('pageerror', (e) => console.error('  [pageerror]', String(e)));
  const report = {};
  for (const a of list) {
    const t0 = Date.now();
    const svg = svgDoc({ w: a.w, h: a.h, title: a.name, body: a.body() });
    fs.writeFileSync(path.join(SVG_DIR, `${a.id}.svg`), svg);
    const htmlPath = path.join(BUILD, `${a.id}.html`);
    fs.writeFileSync(htmlPath, `<!doctype html><html><head><meta charset="utf-8"><style>html,body{margin:0;background:#000}svg{display:block}</style></head><body>${svg}</body></html>`);
    await page.setViewportSize({ width: a.w, height: a.h });
    await page.goto(pathToFileURL(htmlPath).href);
    await page.evaluate(async () => { await document.fonts.load('700 100px Fredoka'); await document.fonts.ready; });
    const fontOk = await page.evaluate(() => document.fonts.check('700 100px Fredoka'));
    await page.screenshot({ path: path.join(BUILD, 'raw', `${a.id}.png`), type: 'png' });
    const rep = { fontOk, texts: [] };
    // cajas de texto (coordenadas del SVG)
    rep.texts = await page.evaluate(() => [...document.querySelectorAll('svg text.t')].map((t) => {
      const b = t.getBoundingClientRect();
      return { text: t.textContent, x: b.x, y: b.y, w: b.width, h: b.height, fill: t.getAttribute('data-contrast'), stroke: t.getAttribute('stroke') };
    }));
    if (a.group !== 'thumbnail') {
      // sujeto solo, sobre transparente, para comprobar el circulo seguro
      await page.addStyleTag({ content: '#bg,.deco{display:none!important}html,body{background:transparent!important}' });
      await page.screenshot({ path: path.join(BUILD, 'subject', `${a.id}.png`), type: 'png', omitBackground: true });
    }
    // sin texto: para medir el fondo bajo cada texto
    if (rep.texts.length) {
      await page.goto(pathToFileURL(htmlPath).href);
      await page.evaluate(() => document.fonts.ready);
      await page.addStyleTag({ content: 'text.t,.wordmark{visibility:hidden!important}' });
      await page.screenshot({ path: path.join(BUILD, 'notext', `${a.id}.png`), type: 'png' });
    }
    report[a.id] = rep;
    console.log(`  render ${a.id.padEnd(26)} ${a.w}x${a.h}  ${Date.now() - t0} ms${fontOk ? '' : '  (!) fuente Fredoka no cargo'}`);
  }
  await browser.close();
  return report;
}

// ---------------------------------------------------------------- optimizar PNG (sin canal alfa, sin metadatos)
function optimize(a) {
  const raw = path.join(BUILD, 'raw', `${a.id}.png`);
  const dest = path.join(OUT, a.dir, `${a.id}.png`);
  mkdirp(path.dirname(dest));
  const base = ['-strip', '-alpha', 'off', '-quality', '95'];
  const limit = a.group === 'thumbnail' ? 650 * 1024 : 200 * 1024; // objetivo por archivo
  im([raw, ...base, `PNG24:${dest}`]);
  let mode = 'PNG24';
  if (fs.statSync(dest).size > limit) {
    // cuantizacion a 256 colores con difuminado Floyd-Steinberg (se ve igual a simple vista; mantiene el degradado)
    im([raw, ...base, '-dither', 'FloydSteinberg', '-colors', '256', `PNG8:${dest}`]);
    mode = 'PNG8-256';
  }
  return { dest, mode, bytes: fs.statSync(dest).size };
}

// ---------------------------------------------------------------- comprobaciones de contenido
/** Pixeles del sujeto (alfa > 10 %) fuera del circulo seguro de radio SAFE_R. */
function safeZoneCheck(a) {
  const sub = path.join(BUILD, 'subject', `${a.id}.png`);
  const mask = path.join(BUILD, `mask-${a.w}.png`);
  if (!fs.existsSync(mask)) im(['-size', `${a.w}x${a.h}`, 'xc:white', '-fill', 'black', '-draw', `circle ${a.w / 2},${a.h / 2} ${a.w / 2},${a.h / 2 - SAFE_R}`, mask]);
  const outside = (extra) => +im([sub, '-alpha', 'extract', '-threshold', '10%', mask, '-compose', 'multiply', '-composite', ...extra, '-format', '%[fx:mean*w*h]', 'info:']).toString();
  const px = Math.round(outside([]));
  const where = px > 0 ? im([sub, '-alpha', 'extract', '-threshold', '10%', mask, '-compose', 'multiply', '-composite', '-format', '%@', 'info:']).toString().trim() : null;
  // radio maximo aproximado del sujeto: menor R de la lista que deja 0 px fuera
  let maxR = null;
  for (const R of [170, 180, 190, 200, 210, 220, 230, 240, 256]) {
    const m = path.join(BUILD, `mask-${a.w}-${R}.png`);
    if (!fs.existsSync(m)) im(['-size', `${a.w}x${a.h}`, 'xc:white', '-fill', 'black', '-draw', `circle ${a.w / 2},${a.h / 2} ${a.w / 2},${a.h / 2 - R}`, m]);
    const n = +im([sub, '-alpha', 'extract', '-threshold', '10%', m, '-compose', 'multiply', '-composite', '-format', '%[fx:mean*w*h]', 'info:']).toString();
    if (Math.round(n) === 0) { maxR = R; break; }
  }
  // esquinas del fondo: el color debe ser continuo (sin detalle) -> desviacion tipica en las 4 esquinas 40x40
  return { outsidePx: px, outsideBBox: where, subjectMaxRadius: maxR };
}

/** Contraste de cada texto frente al fondo medido bajo su caja (percentil 5/95) y frente a su contorno. */
function contrastCheck(a, rep) {
  const nt = path.join(BUILD, 'notext', `${a.id}.png`);
  if (!fs.existsSync(nt)) return [];
  const out = [];
  for (const t of rep.texts) {
    if (!t.fill || t.w < 4) continue;
    const x = Math.max(0, Math.floor(t.x)), y = Math.max(0, Math.floor(t.y)), w = Math.min(a.w - x, Math.ceil(t.w)), h = Math.min(a.h - y, Math.ceil(t.h));
    const buf = im([nt, '-crop', `${w}x${h}+${x}+${y}`, '+repage', '-depth', '8', 'rgb:-']);
    const ls = [];
    for (let i = 0; i + 2 < buf.length; i += 3) ls.push(lum(buf[i], buf[i + 1], buf[i + 2]));
    ls.sort((p, q) => p - q);
    const q = (p) => ls[Math.min(ls.length - 1, Math.floor(p * ls.length))];
    const tl = lum(...hexRgb(t.fill));
    const worstBg = tl > 0.3 ? q(0.95) : q(0.05); // texto claro: lo peor es el fondo claro
    const stroke = t.stroke && t.stroke.startsWith('#') ? ratio(tl, lum(...hexRgb(t.stroke))) : null;
    out.push({ text: t.text.slice(0, 28), fill: t.fill, vsBackground: +ratio(tl, worstBg).toFixed(2), vsOutline: stroke ? +stroke.toFixed(2) : null, bottomEdge: Math.round(t.y + t.h) });
  }
  return out;
}

// ---------------------------------------------------------------- validacion contra las reglas oficiales
function validate(list, reports) {
  const rows = [];
  let total = 0;
  for (const a of list) {
    const f = path.join(OUT, a.dir, `${a.id}.png`);
    const row = { id: a.id, file: path.relative(OUT, f).replaceAll('\\', '/'), group: a.group, key: a.key, errors: [], warnings: [] };
    if (!fs.existsSync(f)) { row.errors.push('no existe'); rows.push(row); continue; }
    const info = identify(f), bytes = fs.statSync(f).size;
    Object.assign(row, { w: info.w, h: info.h, format: info.fmt, bytes });
    total += bytes;
    if (info.fmt !== 'PNG') row.errors.push(`formato ${info.fmt}, se esperaba PNG`);
    if (a.group === 'thumbnail') {
      if (info.w !== 1920 || info.h !== 1080) row.errors.push(`miniatura ${info.w}x${info.h}: debe ser 1920x1080 (16:9)`);
      if (bytes >= 3 * 1024 * 1024) row.errors.push('miniatura >= 3 MB (limite para personalizacion de Home)');
    } else {
      if (info.w !== info.h) row.errors.push('no es cuadrada');
      if (info.w > 512 && a.group !== 'icon') row.errors.push('pase/producto > 512x512');
      if (a.group === 'icon' && info.w < 512) row.errors.push('icono < 512x512');
      if (a.group === 'icon' && info.w !== 512) row.warnings.push(`icono ${info.w}x${info.h} (la plantilla es 512x512)`);
      if (info.w !== 512) row.errors.push(`se esperaba 512x512, es ${info.w}x${info.h}`);
    }
    if (reports?.[a.id]) {
      if (a.group !== 'thumbnail') {
        const sz = safeZoneCheck(a);
        row.safeZone = sz;
        if (sz.outsidePx > 0) row.errors.push(`${sz.outsidePx} px del sujeto fuera del circulo seguro (radio ${SAFE_R}); caja ${sz.outsideBBox}`);
      }
      const cc = contrastCheck(a, reports[a.id]);
      row.textContrast = cc;
      for (const c of cc) {
        const ok = c.vsBackground >= 4.5 || (c.vsOutline !== null && c.vsOutline >= 4.5);
        if (!ok) row.errors.push(`contraste bajo en "${c.text}" (fondo ${c.vsBackground}:1, contorno ${c.vsOutline}:1)`);
        else if (c.vsBackground < 4.5) row.warnings.push(`"${c.text}" depende del contorno (fondo ${c.vsBackground}:1, contorno ${c.vsOutline}:1)`);
        if (a.group === 'thumbnail' && c.bottomEdge > H * 0.85) row.errors.push(`texto "${c.text}" invade el 15 % inferior (borde ${c.bottomEdge} > ${Math.round(H * 0.85)})`);
      }
      if (!reports[a.id].fontOk) row.errors.push('Fredoka no se cargo');
    }
    rows.push(row);
  }
  return { rows, totalBytes: total };
}

// ---------------------------------------------------------------- hoja de contactos
async function contactSheet() {
  const U = (rel) => pathToFileURL(path.join(OUT, rel)).href;
  const by = (g) => ASSETS.filter((a) => a.group === g);
  const fontCss = `@font-face{font-family:'Fredoka';src:url('${pathToFileURL(path.resolve(HERE, '../../specs-video/fonts/Fredoka.ttf')).href}');font-weight:300 700}@font-face{font-family:'Nunito';src:url('${pathToFileURL(path.resolve(HERE, '../../specs-video/fonts/Nunito.ttf')).href}');font-weight:200 1000}`;
  const icon = (a) => `<div class="card"><img src="${U(`${a.dir}/${a.id}.png`)}" width="320" height="320"><div class="lbl"><b>${esc(a.name)}</b><br>${a.w}x${a.h}</div>
    <div class="small">${[150, 110, 64].map((s) => `<span><img src="${U(`${a.dir}/${a.id}.png`)}" width="${s}" height="${s}"><i>${s}px</i></span>`).join('')}</div></div>`;
  const thumb = (a) => `<div class="card th"><div class="tw"><img src="${U(`${a.dir}/${a.id}.png`)}" width="560" height="315"><div class="safeline"></div></div><div class="lbl"><b>${esc(a.name)}</b><br>${a.w}x${a.h} &middot; linea roja = inicio del 15 % inferior</div>
    <div class="small"><span><img src="${U(`${a.dir}/${a.id}.png`)}" width="320" height="180"><i>320x180</i></span></div></div>`;
  const prod = (a) => `<div class="card pc"><div class="circ"><img src="${U(`${a.dir}/${a.id}.png`)}" width="220" height="220"></div><div class="sq"><img src="${U(`${a.dir}/${a.id}.png`)}" width="150" height="150"></div>
    <div class="lbl"><b>${esc(a.name)}</b><br><code>${esc(a.key)}</code></div><div class="small"><span><img class="r" src="${U(`${a.dir}/${a.id}.png`)}" width="64" height="64"><i>64px</i></span></div></div>`;
  const html = `<!doctype html><meta charset="utf-8"><style>${fontCss}
  body{margin:0;width:2400px;background:#0A1F44;color:#F4FBFF;font-family:Nunito,sans-serif;padding:40px 50px;box-sizing:border-box}
  h1{font-family:Fredoka;font-weight:700;font-size:54px;margin:0 0 6px;color:#FFC83D} h2{font-family:Fredoka;font-weight:600;font-size:34px;margin:34px 0 14px;color:#19C3C0;border-bottom:3px solid #0F6E9E;padding-bottom:6px}
  p.s{margin:0;color:#9FB3C8;font-size:20px}
  .row{display:flex;flex-wrap:wrap;gap:22px}.card{background:#0F2D5E;border-radius:16px;padding:14px;box-sizing:border-box}
  .lbl{font-size:18px;margin-top:8px;line-height:1.25}.lbl code{color:#FFC83D;font-size:16px}.small{display:flex;gap:14px;align-items:flex-end;margin-top:8px}.small span{display:flex;flex-direction:column;align-items:center;font-size:13px;color:#9FB3C8}.small i{font-style:normal}
  .card img{display:block;border-radius:6px}
  .tw{position:relative}.safeline{position:absolute;left:0;right:0;top:85%;border-top:3px dashed #FF5C73}
  .circ{width:220px;height:220px;border-radius:50%;overflow:hidden;box-shadow:0 0 0 4px #F4FBFF22;float:left}.pc .circ img{border-radius:0}.sq{float:left;margin-left:14px}
  .pc{width:490px;overflow:hidden}.pc .lbl,.pc .small{clear:both;padding-top:10px}.r{border-radius:50%!important}
  .off{background:#3A1230;border:2px dashed #FF4FB8;padding:12px 18px;border-radius:12px;margin-top:8px;font-size:20px}
  </style>
  <h1>Fish &amp; Fortune &mdash; hoja de contactos de placeholders</h1><p class="s">Generado por render-assets.mjs &middot; todo es arte por codigo (sin IA) &middot; reemplazable por arte de IA (ver README)</p>
  <h2>Iconos del juego 512x512 (A/B/C) con vista previa a 150, 110 y 64 px</h2><div class="row">${by('icon').map(icon).join('')}</div>
  <h2>Miniaturas 1920x1080 (ES y EN), con vista a 320x180</h2><div class="row">${by('thumbnail').map(thumb).join('')}</div>
  <h2>Pases (recorte circular como los muestra Roblox + cuadrado original + 64 px)</h2><div class="row">${by('pass').map(prod).join('')}</div>
  <h2>Productos de desarrollador</h2><div class="row">${by('product').map(prod).join('')}</div>
  <h2>No generados en la v1 (FeatureFlags.paidLuckEnabled = false)</h2>${DISABLED.map((d) => `<div class="off"><b>${esc(d.name)}</b> &middot; <code>${esc(d.key)}</code> &mdash; ${esc(d.why)}</div>`).join('')}`;
  const hp = path.join(BUILD, 'contact-sheet.html');
  fs.writeFileSync(hp, html);
  const browser = await chromium.launch({ executablePath: findChromium(), headless: true, args: ['--no-sandbox', '--disable-gpu', '--allow-file-access-from-files', '--force-color-profile=srgb'] });
  const page = await (await browser.newContext({ viewport: { width: 2400, height: 1000 }, deviceScaleFactor: 1 })).newPage();
  await page.goto(pathToFileURL(hp).href);
  await page.evaluate(async () => { await document.fonts.ready; await Promise.all([...document.images].map((i) => i.decode().catch(() => {}))); });
  const raw = path.join(BUILD, 'contact-sheet-raw.png');
  await page.screenshot({ path: raw, fullPage: true, type: 'png' });
  await browser.close();
  const dest = path.join(OUT, 'contact-sheet.png');
  im([raw, '-strip', '-alpha', 'off', '-resize', '2000x', '-dither', 'FloydSteinberg', '-colors', '192', `PNG8:${dest}`]);
  console.log(`  hoja de contactos -> ${path.relative(process.cwd(), dest)} (${(fs.statSync(dest).size / 1024).toFixed(0)} KB)`);
}

// ---------------------------------------------------------------- main
(async () => {
  const list = ASSETS.filter((a) => !only || only.has(a.id));
  let reports = null;
  if (!flag('validate-only')) {
    console.log(`Renderizando ${list.length} piezas...`);
    reports = await renderAll(list);
    for (const a of list) {
      const o = optimize(a);
      console.log(`  png    ${a.id.padEnd(26)} ${(o.bytes / 1024).toFixed(0).padStart(5)} KB  ${o.mode}`);
    }
  } else {
    // modo solo-validar: no hay informe de texto/sujeto salvo que exista build/ de una ejecucion previa
    console.log('Validando PNG existentes (sin comprobaciones de circulo/contraste; ejecuta el render completo para esas).');
  }
  if (!flag('no-sheet') && !flag('validate-only') && !only) await contactSheet();
  const full = ASSETS; // la validacion cubre siempre todos los archivos
  const { rows, totalBytes } = validate(full, reports ? Object.fromEntries(Object.entries(reports)) : null);
  const errors = rows.flatMap((r) => r.errors.map((e) => `${r.id}: ${e}`));
  const warns = rows.flatMap((r) => r.warnings.map((e) => `${r.id}: ${e}`));
  const sheet = path.join(OUT, 'contact-sheet.png');
  const totalAll = totalBytes + (fs.existsSync(sheet) ? fs.statSync(sheet).size : 0);
  fs.writeFileSync(path.join(OUT, 'assets-manifest.json'), JSON.stringify({
    generated: new Date().toISOString().slice(0, 10),
    rules: { icon: '512x512 cuadrado (>=512), preview a 150x150', thumbnail: '16:9, ideal 1920x1080, <3 MB, jpg/gif/png/tga/bmp, sin elementos clave en el borde inferior', passAndProduct: '<=512x512, jpg/png/bmp, sin detalles importantes fuera del circulo' },
    totalBytes: totalAll, totalMB: +(totalAll / 1048576).toFixed(2), disabledV1: DISABLED, files: rows,
  }, null, 2));
  console.log(`\nValidacion: ${rows.length} archivos, ${(totalAll / 1048576).toFixed(2)} MB (con hoja de contactos), ${errors.length} errores, ${warns.length} avisos`);
  for (const e of errors) console.log('  ERROR  ' + e);
  for (const w of warns) console.log('  aviso  ' + w);
  process.exit(errors.length ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(2); });
