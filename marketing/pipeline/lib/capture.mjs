// Captura determinista frame a frame con Chromium (Playwright). Cada worker = un contexto/renderer propio.
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { chromium } from 'playwright-core';
import { PIPE_DIR, mkdirp } from './util.mjs';

export function findChromium() {
  if (process.env.CHROMIUM_PATH && fs.existsSync(process.env.CHROMIUM_PATH)) return process.env.CHROMIUM_PATH;
  const roots = [process.env.PLAYWRIGHT_BROWSERS_PATH, '/opt/pw-browsers', path.join(process.env.HOME || '', '.cache', 'ms-playwright')].filter(Boolean);
  const cands = [];
  for (const r of roots) {
    if (!fs.existsSync(r)) continue;
    for (const d of fs.readdirSync(r).sort().reverse()) {
      if (d.startsWith('chromium_headless_shell')) cands.unshift(path.join(r, d, 'chrome-linux', 'headless_shell'), path.join(r, d, 'chrome-headless-shell-linux64', 'chrome-headless-shell'));
      else if (d.startsWith('chromium-')) cands.push(path.join(r, d, 'chrome-linux', 'chrome'), path.join(r, d, 'chrome-linux64', 'chrome'));
    }
  }
  const hit = cands.find((c) => fs.existsSync(c));
  if (hit) return hit;
  try { const p = chromium.executablePath(); if (p && fs.existsSync(p)) return p; } catch { /* sin navegador */ }
  throw new Error('No se encontró Chromium. Define CHROMIUM_PATH=/ruta/a/chrome o PLAYWRIGHT_BROWSERS_PATH.');
}

const PLAYER_URL = pathToFileURL(path.join(PIPE_DIR, 'player', 'index.html')).href;

async function openWorker(browser, resolved, idx) {
  const ctx = await browser.newContext({ viewport: { width: resolved.vw, height: resolved.vh }, deviceScaleFactor: 1 });
  const page = await ctx.newPage();
  const logs = [];
  page.on('console', (m) => { if (m.type() === 'error' || m.type() === 'warning') logs.push(m.text()); });
  page.on('pageerror', (e) => logs.push(String(e)));
  await page.addInitScript((spec) => { window.__SPEC__ = spec; }, resolved);
  await page.goto(PLAYER_URL);
  await page.waitForFunction('window.__ready === true || !!window.__error', null, { timeout: 60000 });
  const err = await page.evaluate('window.__error || null');
  if (err) throw new Error('Error en el player:\n' + err);
  const cdp = await ctx.newCDPSession(page);
  return { ctx, page, cdp, logs, idx };
}

async function shot(w, format, quality) {
  const r = await w.cdp.send('Page.captureScreenshot', format === 'png' ? { format: 'png', optimizeForSpeed: true } : { format: 'jpeg', quality, optimizeForSpeed: true });
  return Buffer.from(r.data, 'base64');
}

/** Captura todos los frames a outDir/f_000001.jpg ... Devuelve estadísticas. */
export async function captureFrames(resolved, outDir, { workers = 4, format = 'jpeg', quality = 94, onProgress } = {}) {
  mkdirp(outDir);
  const N = Math.round(resolved.duration * resolved.fps);
  const ext = format === 'png' ? 'png' : 'jpg';
  const browser = await chromium.launch({
    executablePath: findChromium(), headless: true,
    args: ['--no-sandbox', '--disable-gpu', '--hide-scrollbars', '--force-color-profile=srgb', '--font-render-hinting=none', '--disable-lcd-text',
      '--allow-file-access-from-files', '--disable-dev-shm-usage', '--disable-background-timer-throttling', '--disable-renderer-backgrounding', '--disable-backgrounding-occluded-windows'],
  });
  const t0 = Date.now();
  try {
    const nW = Math.max(1, Math.min(workers, N));
    const ws = await Promise.all(Array.from({ length: nW }, (_, i) => openWorker(browser, resolved, i)));
    const tReady = Date.now() - t0;
    let next = 0, done = 0, msEval = 0, msShot = 0, msWrite = 0;
    const CH = 8;
    await Promise.all(ws.map(async (w) => {
      for (;;) {
        const a = next; if (a >= N) break; next += CH;
        for (let f = a; f < Math.min(N, a + CH); f++) {
          const a0 = Date.now();
          await w.page.evaluate((t) => window.renderFrame(t), f / resolved.fps);
          const a1 = Date.now();
          const buf = await shot(w, format, quality);
          const a2 = Date.now();
          fs.writeFileSync(path.join(outDir, `f_${String(f + 1).padStart(6, '0')}.${ext}`), buf);
          msEval += a1 - a0; msShot += a2 - a1; msWrite += Date.now() - a2;
          done++;
          if (onProgress && (done % 30 === 0 || done === N)) onProgress(done, N);
        }
      }
    }));
    const logs = ws.flatMap((w) => w.logs);
    return { frames: N, ext, ms: Date.now() - t0 - tReady, startMs: tReady, workers: nW, logs: [...new Set(logs)].slice(0, 10), perFrameMs: { render: +(msEval / N).toFixed(1), screenshot: +(msShot / N).toFixed(1), write: +(msWrite / N).toFixed(1) } };
  } finally {
    await browser.close();
  }
}

/** Captura fotogramas sueltos (PNG) en los tiempos pedidos → rutas. Útil para revisar el diseño sin renderizar todo. */
export async function captureStills(resolved, times, outDir, prefix = 'still') {
  mkdirp(outDir);
  const browser = await chromium.launch({ executablePath: findChromium(), headless: true, args: ['--no-sandbox', '--disable-gpu', '--hide-scrollbars', '--force-color-profile=srgb', '--font-render-hinting=none', '--allow-file-access-from-files', '--disable-dev-shm-usage'] });
  try {
    const w = await openWorker(browser, resolved, 0);
    const files = [];
    for (const t of times) {
      await w.page.evaluate((tt) => window.renderFrame(tt), t);
      const f = path.join(outDir, `${prefix}_${String(t).replace('.', '_')}s.png`);
      fs.writeFileSync(f, await shot(w, 'png', 100));
      files.push(f);
    }
    return { files, logs: [...new Set(w.logs)] };
  } finally { await browser.close(); }
}
