// Compila un spec JSON "humano" a un spec resuelto (tiempos absolutos, textos parseados, fondos, SFX, subtítulos).
// Esta es la ÚNICA fuente de verdad de tiempos: el runtime del navegador solo lee lo que sale de aquí.
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { CACHE_DIR, mkdirp, sha1, run, mediaDuration, warn } from './util.mjs';
import { synthesizeEspeak } from './tts.mjs';
import { STYLES } from './synth.mjs';

export const ASPECTS = { '9:16': [1080, 1920], '16:9': [1920, 1080], '1:1': [1080, 1080], '4:5': [1080, 1350] };

export const PALETTES = {
  neon:   { bg1: '#12062b', bg2: '#3b0f73', accent: '#00e5ff', accent2: '#ff3df2', hot: '#ffd400', text: '#ffffff', dim: '#c6b8f0', good: '#3dff8a', bad: '#ff3b5c' },
  sunset: { bg1: '#2b0a3d', bg2: '#c93a6a', accent: '#ffd23f', accent2: '#ff7a3c', hot: '#00e0ff', text: '#ffffff', dim: '#ffd9c7', good: '#3dff8a', bad: '#ff3b5c' },
  candy:  { bg1: '#3b1580', bg2: '#d6459f', accent: '#fff275', accent2: '#6df7ff', hot: '#ff3b6b', text: '#ffffff', dim: '#f3c6ee', good: '#3dff8a', bad: '#ff3b5c' },
  lime:   { bg1: '#04252a', bg2: '#0b8f5a', accent: '#c6ff3d', accent2: '#00e0b8', hot: '#ffe14d', text: '#ffffff', dim: '#b8f0d8', good: '#3dff8a', bad: '#ff4d4d' },
  gold:   { bg1: '#1a1033', bg2: '#5b2a9e', accent: '#ffcb2f', accent2: '#ff7a18', hot: '#ff3b5c', text: '#ffffff', dim: '#d9c8ff', good: '#3dff8a', bad: '#ff3b5c' },
  ocean:  { bg1: '#04122e', bg2: '#0b5fa8', accent: '#5cf2ff', accent2: '#3d7bff', hot: '#ffe14d', text: '#ffffff', dim: '#b8d8f5', good: '#3dff8a', bad: '#ff4d6d' },
};

const KIND_DUR = { hook: 2.0, caption: 3.5, rank: 3.2, counter: 3.4, compare: 5.2, stages: 5.4, offer: 5.0, bullets: 4.2, cta: 3.4 };
const TRANS_DEFAULT = ['slide-up', 'zoom', 'wipe', 'slide-left', 'flash', 'circle'];
const TEMPLATES = {
  'hook-gameplay-cta': { defKind: 'caption', music: 'hype', trans: ['slide-up', 'zoom', 'wipe', 'slide-left', 'flash'] },
  'top-list':          { defKind: 'rank', music: 'arcade', trans: ['slide-left', 'slide-up', 'zoom', 'wipe', 'circle'] },
  'before-after':      { defKind: 'compare', music: 'epic', trans: ['zoom', 'wipe', 'slide-up', 'flash'] },
  progression:         { defKind: 'stages', music: 'epic', trans: ['zoom', 'wipe', 'slide-up', 'flash'] },
  offer:               { defKind: 'bullets', music: 'hype', trans: ['glitch', 'slide-up', 'zoom', 'flash'] },
  custom:              { defKind: 'caption', music: 'hype', trans: TRANS_DEFAULT },
};

/* ---------- texto enriquecido: *acento*  **acento2**  \n o | = salto de línea ---------- */
export function plain(s) { return String(s == null ? '' : s).replace(/\*+/g, '').replace(/\|/g, ' '); }
export function rich(text, t0 = 0, stagger = 0.12) {
  const words = []; let cur = '', curEm = 0, em = 0, idx = 0;
  const flush = () => { if (cur) { words.push({ w: cur, em: curEm, t: +(t0 + idx * stagger).toFixed(3) }); idx++; cur = ''; } };
  const s = String(text == null ? '' : text);
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (c === '*') { if (s[i + 1] === '*') { em = em === 2 ? 0 : 2; i++; } else em = em === 1 ? 0 : 1; continue; }
    if (c === '\n' || c === '|') { flush(); words.push({ br: true }); continue; }
    if (/\s/.test(c)) { flush(); continue; }
    if (!cur) curEm = em;
    cur += c;
  }
  flush();
  const n = Math.max(1, idx);
  return { words, last: t0 + (n - 1) * stagger, count: n };
}

const num = (v, d) => (typeof v === 'number' && Number.isFinite(v) ? v : d);

/* ---------- fondos ---------- */
async function resolveBg(desc, ctx, sceneIdx, sceneStart, sceneDur, inherited) {
  if (desc == null) return null;
  let d = typeof desc === 'string' ? { type: desc } : { ...desc };
  d.type = d.type || 'gradient';
  if (d.seed == null) d.seed = (inherited ? 5 : 3) + (inherited ? 0 : sceneIdx * 7);
  if (inherited && d.continuous !== false && !['image', 'video'].includes(d.type)) d.tOffset = sceneStart;
  if (d.type === 'image') {
    if (!d.src) throw new Error(`Escena ${sceneIdx}: bg image requiere "src"`);
    d.src = ctx.fileUrl(d.src, `bg.src (escena ${sceneIdx})`);
    if (!d.src) { d.type = 'gradient'; }
  } else if (d.type === 'video') {
    const abs = ctx.absPath(d.src);
    if (!abs || !fs.existsSync(abs)) { warn(`Clip de fondo no encontrado: ${d.src} (escena ${sceneIdx}); uso fondo procedural.`); d = { type: 'runner', seed: d.seed }; }
    else {
      const fps = ctx.fps, speed = num(d.speed, 1), trim = num(d.trim, 0);
      const clipDur = await mediaDuration(abs);
      const avail = Math.max(0.1, clipDur - trim);
      const need = Math.min(avail, sceneDur * speed + 0.2);
      const count = Math.max(1, Math.floor(need * fps));
      const key = sha1('frames', abs, fs.statSync(abs).mtimeMs, fs.statSync(abs).size, trim, ctx.vw, ctx.vh, fps, count);
      const dir = path.join(CACHE_DIR, 'frames', key);
      if (!fs.existsSync(path.join(dir, '.done'))) {
        mkdirp(dir);
        await run('ffmpeg', ['-y', '-v', 'error', '-ss', String(trim), '-t', String(count / fps + 0.05), '-i', abs,
          '-vf', `fps=${fps},scale=${ctx.vw}:${ctx.vh}:force_original_aspect_ratio=increase,crop=${ctx.vw}:${ctx.vh}`,
          '-frames:v', String(count), '-q:v', '3', path.join(dir, '%06d.jpg')]);
        fs.writeFileSync(path.join(dir, '.done'), '1');
      }
      const real = fs.readdirSync(dir).filter((f) => f.endsWith('.jpg')).length;
      d.frames = { pattern: pathToFileURL(path.join(dir, '%06d.jpg')).href.replace('%2506d', '%06d'), count: real, fps };
      if (real * speed / fps < sceneDur - 0.05 && d.loop !== false) ctx.warns.push(`Clip "${d.src}" dura ${(real / fps).toFixed(1)}s < escena ${sceneDur.toFixed(1)}s: se repite en bucle.`);
      delete d.src;
    }
  }
  return d;
}

/* ---------- subtítulos ---------- */
function chunkWords(tokens, t0, t1, land) {
  if (!tokens.length) return [];
  const weights = tokens.map((w) => w.length + 1.6 + (/[.,!?;:…¿¡]$/.test(w) ? 4 : 0));
  const total = weights.reduce((a, b) => a + b, 0), span = Math.max(0.2, t1 - t0);
  let acc = 0;
  const timed = tokens.map((w, i) => { const a = t0 + (acc / total) * span; acc += weights[i]; return { w, t0: +a.toFixed(3), t1: +(t0 + (acc / total) * span).toFixed(3) }; });
  const maxW = land ? 5 : 3, maxC = land ? 34 : 19;
  const chunks = []; let cur = [];
  const len = (arr) => arr.map((x) => x.w).join(' ').length;
  for (const w of timed) {
    if (cur.length && (cur.length >= maxW || len([...cur, w]) > maxC)) { chunks.push(cur); cur = []; }
    cur.push(w);
    if (/[.!?…]$/.test(w.w) || (/[,;:]$/.test(w.w) && cur.length >= 2)) { chunks.push(cur); cur = []; }
  }
  if (cur.length) chunks.push(cur);
  return chunks.map((c, i) => ({ t0: c[0].t0, t1: c[c.length - 1].t1, words: c }));
}

/* ---------- compilación principal ---------- */
export async function compileSpec(raw, { specDir, opts = {} }) {
  const warns = [];
  const spec = JSON.parse(JSON.stringify(raw));
  const template = spec.template || 'custom';
  const T = TEMPLATES[template] || TEMPLATES.custom;
  if (!TEMPLATES[template]) warns.push(`Plantilla desconocida "${template}": uso "custom".`);

  const aspect = opts.aspect || spec.aspect || '9:16';
  let [W, H] = ASPECTS[aspect] || (() => { warns.push(`Aspecto "${aspect}" desconocido: uso 9:16`); return ASPECTS['9:16']; })();
  if (opts.size) { const m = /^(\d+)x(\d+)$/.exec(opts.size); if (m) { W = +m[1]; H = +m[2]; } }
  const fps = opts.fps || spec.fps || 30;
  const scale = opts.scale || 1;
  const even = (n) => Math.max(2, Math.round(n / 2) * 2);
  const vw = even(W * scale), vh = even(H * scale), u = (Math.min(W, H) * scale) / 1080;
  const land = W > H * 1.2;

  const palName = typeof spec.palette === 'string' ? spec.palette : spec.palette && spec.palette.name;
  const pal = { ...(PALETTES[palName || 'neon'] || PALETTES.neon), ...(typeof spec.palette === 'object' && spec.palette ? spec.palette : {}) };
  delete pal.name;

  let sz = spec.safeZone;
  if (sz === 'none') sz = { t: 40, b: 40, l: 40, r: 40 };
  else if (!sz || sz === 'auto' || typeof sz === 'string') sz = land ? { t: 80, b: 80, l: 120, r: 120 } : H > W * 1.1 ? { t: 170, b: 340, l: 96, r: 96 } : { t: 90, b: 140, l: 90, r: 90 };
  const safe = { t: sz.t * scale, b: sz.b * scale, l: sz.l * scale, r: sz.r * scale };

  const specDir_ = specDir;
  const ctx = {
    fps, vw, vh, warns,
    absPath: (p) => (p ? path.resolve(specDir_, p) : null),
    fileUrl: (p, what) => {
      const a = p ? path.resolve(specDir_, p) : null;
      if (!a || !fs.existsSync(a)) { warns.push(`Archivo no encontrado${what ? ' (' + what + ')' : ''}: ${p}`); return null; }
      return pathToFileURL(a).href;
    },
  };

  /* --- audio config --- */
  const A = spec.audio || {};
  const musicCfg = A.music === false ? null : typeof A.music === 'string' ? { style: A.music } : { style: T.music, ...(A.music || {}) };
  const narCfg = { engine: 'none', voice: 'es-la', speed: 158, pitch: 50, delay: 0.3, volume: 1, ...(A.narration || {}) };
  if (typeof A.narration === 'string') narCfg.engine = A.narration;

  /* --- 1) lista de escenas crudas según plantilla --- */
  const raws = [];
  const hookRaw = spec.hook === false ? null : spec.hook || (spec.title ? { text: spec.title } : null);
  if (hookRaw) raws.push({ kind: 'hook', ...(typeof hookRaw === 'string' ? { text: hookRaw } : hookRaw) });
  if (template === 'top-list') {
    const items = spec.items || [];
    items.forEach((it, i) => raws.push({ kind: 'rank', total: items.length, rank: it.rank != null ? it.rank : items.length - i, ...it }));
  }
  if (template === 'offer' && spec.offer) raws.push({ kind: 'offer', ...spec.offer });
  for (const s of spec.scenes || []) raws.push({ kind: s.kind || T.defKind, ...s });
  if (spec.cta !== false && (spec.cta || template !== 'custom')) {
    const c = spec.cta || {};
    const offerCode = template === 'offer' && spec.offer ? spec.offer.code : null;
    raws.push({ kind: 'cta', code: offerCode, ...c });
  }
  if (!raws.length) throw new Error('El spec no define escenas (hook / scenes / items / cta).');
  for (const r of raws) if (!KIND_DUR[r.kind]) throw new Error(`Tipo de escena desconocido: "${r.kind}". Válidos: ${Object.keys(KIND_DUR).join(', ')}`);

  /* --- 2) narración (TTS o archivo) → duraciones --- */
  const narrations = [];
  for (const r of raws) {
    r._nar = null;
    if (r.narrationFile) {
      const abs = ctx.absPath(r.narrationFile);
      if (abs && fs.existsSync(abs)) r._nar = { file: abs, duration: await mediaDuration(abs) };
      else warns.push(`narrationFile no encontrado: ${r.narrationFile}`);
    } else if (r.narration && narCfg.engine === 'espeak') {
      const res = await synthesizeEspeak(plain(r.narration), { voice: narCfg.voice, speed: narCfg.speed, pitch: narCfg.pitch });
      if (res) r._nar = res; else warns.push('TTS no disponible: la narración solo aparece como subtítulo.');
    }
  }

  /* --- 3) duraciones y línea de tiempo --- */
  const spoken = (r) => (r._nar ? (r.narrationDelay != null ? r.narrationDelay : r.kind === 'hook' ? 0.1 : narCfg.delay) + r._nar.duration + 0.35 : 0);
  const durs = raws.map((r) => {
    let d = r.duration != null && r.duration !== 'auto' ? +r.duration : r.kind === 'hook' && spec.hook && spec.hook.duration ? +spec.hook.duration : KIND_DUR[r.kind];
    const need = spoken(r);
    if (r._nar && (r.duration == null || r.duration === 'auto')) d = Math.max(d, need);
    else if (need > d + 0.05) { warns.push(`Escena "${r.id || r.kind}": la narración (${need.toFixed(1)}s) no cabe en ${d.toFixed(1)}s; se amplía.`); d = need; }
    return d;
  });
  const trs = raws.map((r, i) => {
    if (i === 0) return { type: 'cut', d: 0 };
    const type = r.transition || T.trans[(i - 1) % T.trans.length];
    return { type, d: type === 'cut' ? 0 : num(r.transitionDur, 0.4) };
  });
  const layout = () => {
    const starts = [], ends = []; let prevEnd = 0;
    raws.forEach((r, i) => { const s = i === 0 ? 0 : prevEnd - trs[i].d; starts.push(s); prevEnd = s + durs[i]; ends.push(prevEnd); });
    return { starts, ends, total: prevEnd };
  };
  let L = layout();
  const target = opts.duration || spec.duration;
  if (target && Math.abs(L.total - target) > 0.05) {
    const flexIdx = raws.map((r, i) => i).filter((i) => (raws[i].duration == null || raws[i].duration === 'auto') && !raws[i]._nar && raws[i].kind !== 'hook' && raws[i].kind !== 'cta');
    const idxs = flexIdx.length ? flexIdx : raws.map((r, i) => i).filter((i) => raws[i].kind !== 'hook' && raws[i].kind !== 'cta' && !raws[i]._nar);
    if (idxs.length) {
      for (let k = 0; k < 3; k++) {
        const delta = target - layout().total;
        idxs.forEach((i) => { durs[i] = Math.max(1.0, durs[i] + delta / idxs.length); });
      }
      L = layout();
    }
    if (Math.abs(L.total - target) > 0.3) warns.push(`Duración pedida ${target}s, resultante ${L.total.toFixed(1)}s (límites de escenas).`);
  }
  let duration = L.total;
  if (opts.maxDuration && duration > opts.maxDuration) duration = opts.maxDuration;

  /* --- 4) compilar cada escena --- */
  const scenes = [], sfx = [], captions = [];
  const bgDefaultFor = (kind, i) => {
    if (spec.bg) return { desc: spec.bg, inherited: true };
    const defs = { hook: 'runner', caption: 'runner', rank: ['blocks', 'grid', 'rays', 'gradient'][i % 4], counter: 'grid', stages: 'grid', offer: { type: 'rays', particles: 'coins' }, bullets: 'gradient', cta: { type: 'rays', particles: 'confetti' }, compare: null };
    return { desc: defs[kind], inherited: kind === 'hook' || kind === 'caption' };
  };
  const rankColors = { 1: ['#ffcb2f', '#ff9f1a'], 2: ['#e6edf7', '#9fb0c8'], 3: ['#ffb27a', '#d9692e'] };

  for (let i = 0; i < raws.length; i++) {
    const r = raws[i], start = L.starts[i], dur = durs[i], end = L.ends[i];
    const sc = { kind: r.kind, i, start: +start.toFixed(3), end: +end.toFixed(3), dur: +dur.toFixed(3), tr: trs[i], id: r.id || null };
    const abs = (lt) => +(start + lt).toFixed(3);
    const ev = (lt, type, gain, pan) => { if (start + lt < duration) sfx.push({ t: abs(lt), type, gain, pan }); };
    if (i > 0 && trs[i].d > 0) ev(0, trs[i].type === 'flash' || trs[i].type === 'glitch' ? 'hit' : 'whoosh', 0.55);

    // fondo
    if (r.kind !== 'compare') {
      const given = r.bg != null ? { desc: r.bg, inherited: false } : bgDefaultFor(r.kind, i);
      sc.bg = await resolveBg(given.desc, ctx, i, start, dur, given.inherited);
      if (sc.bg && r.kind === 'hook' && sc.bg.punch == null) sc.bg.punch = 0.1;
      if (sc.bg && r.scrim != null) sc.bg.scrim = r.scrim;
      if (sc.bg && r.particles) sc.bg.particles = r.particles;
    }

    switch (r.kind) {
      case 'hook': {
        const t = rich(r.text || spec.title || '', 0.1, 0);
        const st = Math.min(0.17, 0.95 / Math.max(1, t.count));
        sc.title = rich(r.text || spec.title || '', 0.1, st);
        sc.sub = r.sub ? rich(r.sub, sc.title.last + 0.25, 0.08) : null;
        sc.emoji = r.emoji || null; sc.kicker = r.kicker || null; sc.chip = r.chip || null;
        ev(0, 'impact', 1.0);
        sc.title.words.forEach((w) => { if (!w.br) ev(w.t, 'hit', 0.45); });
        if (sc.sub) ev(sc.sub.words[0].t, 'pop', 0.4);
        break;
      }
      case 'caption': {
        sc.title = r.text ? rich(r.text, 0.15, 0.09) : null;
        sc.titleAnim = r.titleAnim || 'pop';
        sc.chips = (r.chips || []).map((c) => ({ ...c, text: plain(c.text || ''), at: num(c.at, 0.5) }));
        sc.stickers = (r.stickers || []).map((c) => ({ ...c, at: num(c.at, 0.5) }));
        sc.images = (r.images || []).map((m) => ({ ...m, src: ctx.fileUrl(m.src, 'images'), at: num(m.at, 0.5) })).filter((m) => m.src);
        if (sc.title) ev(0.15, 'pop', 0.5);
        [...sc.chips, ...sc.stickers, ...sc.images].forEach((c) => ev(c.at, c.counter ? 'coin' : 'pop', 0.5));
        break;
      }
      case 'rank': {
        const rk = r.rank, [a1, a2] = rankColors[rk] || [pal.accent, pal.accent2];
        sc.rank = rk; sc.total = r.total || 5; sc.accent = a1; sc.accent2 = a2;
        sc.title = rich(r.title || r.text || '', 0.55, 0.1);
        sc.sub = r.sub ? rich(r.sub, sc.title.last + 0.2, 0.06) : null;
        sc.emoji = r.emoji || null; sc.image = r.image ? ctx.fileUrl(r.image, 'rank.image') : null;
        if (r.stat) sc.stat = { ...r.stat, at: num(r.stat.at, 1.0) };
        ev(0.18, 'impact', 0.9); ev(0.35, 'pop', 0.5);
        if (sc.stat) ev(sc.stat.at, 'coin', 0.55);
        break;
      }
      case 'counter': {
        sc.label = rich(r.label || '', 0.2, 0.08); sc.sub = r.sub ? rich(r.sub, 1.2, 0.07) : null;
        Object.assign(sc, { from: num(r.from, 0), to: num(r.to, 100), prefix: r.prefix || '', suffix: r.suffix || '', decimals: r.decimals || 0, emoji: r.emoji || null, at: num(r.at, 0.5), countDur: num(r.countDur, Math.min(2.4, dur - 1.0)), accent: pal.accent, accent2: pal.accent2 });
        for (let k = 0; k < 28; k++) ev(sc.at + (k / 28) * sc.countDur * 0.92, 'tick', 0.22 + 0.2 * (k / 28));
        ev(sc.at + sc.countDur, 'ding', 0.8);
        break;
      }
      case 'compare': {
        const mkBg = async (b, k) => resolveBg(b || (k ? { type: 'rays', particles: 'sparks' } : { type: 'gradient' }), ctx, i * 2 + k, start, dur, false);
        sc.before = { label: r.before && r.before.label, bg: await mkBg(r.before && r.before.bg, 0) };
        sc.after = { label: r.after && r.after.label, bg: await mkBg(r.after && r.after.bg, 1) };
        sc.title = rich(r.text || r.title || '', 0.1, 0.09);
        sc.wipeAt = num(r.wipeAt, 1.5); sc.wipeDur = num(r.wipeDur, 1.0);
        sc.accent = pal.accent; sc.accent2 = pal.accent2;
        const stats = (r.stats || []);
        sc.stats = stats.map((s) => { const m = Math.max(s.before, s.after, 1e-9); return { ...s, beforePct: s.before / m, afterPct: s.after / m, decimals: s.decimals || 0 }; });
        ev(sc.wipeAt - 0.7, 'riser', 0.5); ev(sc.wipeAt, 'whoosh', 0.7); ev(sc.wipeAt + sc.wipeDur - 0.1, 'ding', 0.7);
        break;
      }
      case 'stages': {
        sc.title = rich(r.text || r.title || '', 0.1, 0.08);
        const st = (r.stages || []).map((s) => ({ ...s }));
        if (st.length < 2) throw new Error('stages requiere al menos 2 etapas');
        const t0 = num(r.firstAt, 0.9), step = (dur - t0 - 0.7) / (st.length - 1);
        st.forEach((s, k) => { s.t = +(t0 + k * step).toFixed(3); });
        sc.stages = st; sc.hold = Math.min(0.4, step * 0.4);
        Object.assign(sc, { prefix: r.prefix || '', suffix: r.suffix || '', decimals: r.decimals || 0, accent: pal.accent, accent2: pal.accent2 });
        st.forEach((s, k) => ev(s.t, k === st.length - 1 ? 'success' : 'coin', 0.55));
        break;
      }
      case 'offer': {
        sc.headline = rich(r.headline || r.text || '', 0.3, 0.1);
        Object.assign(sc, { kicker: r.kicker, discount: r.discount || '-50%', discountLabel: r.discountLabel, items: r.items || [], code: r.code || null, codeLabel: r.codeLabel, codeAt: num(r.codeAt, 1.9),
          endsIn: num(r.endsIn, 3 * 3600 - 19), endsLabel: r.endsLabel, countRate: num(r.countRate, 1), flash: r.flash !== false, accent: pal.accent, accent2: pal.accent2 });
        ev(0, 'alarm', 0.55); ev(0.2, 'impact', 0.8);
        sc.items.forEach((_, k) => ev(0.9 + k * 0.18, 'pop', 0.45));
        if (sc.code) { for (let k = 0; k < sc.code.length; k++) ev(sc.codeAt + 0.15 + k * 0.07, 'tick', 0.3); ev(sc.codeAt + 0.2 + sc.code.length * 0.07, 'coin', 0.6); }
        for (let k = 1; k < dur; k++) ev(k + 0.0, 'tick', 0.12);
        break;
      }
      case 'bullets': {
        sc.title = rich(r.text || r.title || '', 0.1, 0.09);
        sc.items = (r.items || []).map((it, k) => ({ emoji: it.emoji, text: plain(it.text), at: num(it.at, 0.7 + k * 0.5) }));
        sc.items.forEach((it) => ev(it.at, 'pop', 0.5));
        break;
      }
      case 'cta': {
        sc.title = rich(r.text || r.title || '¡JUEGA AHORA!', 0.05, 0.1);
        sc.sub = r.sub ? rich(r.sub, sc.title.last + 0.2, 0.06) : null;
        Object.assign(sc, { button: r.button, handle: r.handle || (spec.brand && spec.brand.handle) || null, code: r.code || null, codeLabel: r.codeLabel, emoji: r.emoji || null, accent: pal.accent, accent2: pal.accent2 });
        ev(0.1, 'success', 0.7); ev(sc.title.last + 0.3, 'pop', 0.55);
        break;
      }
    }

    // sfx personalizados y narración/subtítulos
    for (const e of r.sfx || []) ev(num(e.at, 0), e.type || 'pop', e.gain, e.pan);
    const capText = r.subtitle != null ? r.subtitle : r.narration;
    const delay = r.narrationDelay != null ? r.narrationDelay : r.kind === 'hook' ? 0.1 : narCfg.delay;
    if (r._nar) narrations.push({ file: r._nar.file, start: +(start + delay).toFixed(3), duration: r._nar.duration });
    if (capText && r.captions !== false && spec.subtitles !== false && !(spec.subtitles && spec.subtitles.enabled === false)) {
      const toks = plain(capText).split(/\s+/).filter(Boolean);
      let a, b;
      if (r._nar) { a = start + delay; b = a + r._nar.duration; }
      else { a = start + (r.kind === 'hook' ? 0.2 : 0.35); b = end - 0.3 - (raws[i + 1] ? trs[i + 1].d : 0); }
      captions.push(...chunkWords(toks, a, Math.max(a + 0.4, b), land));
    }
    scenes.push(sc);
  }
  // evitar solapes de subtítulos
  captions.sort((a, b) => a.t0 - b.t0);
  for (let k = 0; k < captions.length; k++) {
    const nx = captions[k + 1];
    captions[k].t1 = +Math.min(captions[k].t1 + 0.12, nx ? nx.t0 : Infinity).toFixed(3);
  }

  // voz externa global
  if (A.voiceover) {
    const v = typeof A.voiceover === 'string' ? { file: A.voiceover } : A.voiceover;
    const abs = ctx.absPath(v.file);
    if (abs && fs.existsSync(abs)) narrations.push({ file: abs, start: num(v.start, 0), duration: await mediaDuration(abs), gain: num(v.volume, 1) });
    else warns.push(`audio.voiceover no encontrado: ${v.file}`);
  }

  // fuentes propias
  const fonts = (spec.fonts || []).map((f) => ({ family: f.family, weight: f.weight, src: ctx.fileUrl(f.file, 'fonts') })).filter((f) => f.src);

  const music = musicCfg ? { style: 'hype', ...musicCfg } : null;
  if (music && !music.file) { const S = STYLES[music.style]; if (!S) { warns.push(`audio.music.style "${music.style}" desconocido; uso hype`); music.style = 'hype'; } music.bpm = music.bpm || STYLES[music.style].bpm; }
  const beat = music && !music.file && A.beatPulse !== false ? { bpm: music.bpm, offset: 0, amp: num(A.beatAmp, 0.014) } : null;

  const resolved = {
    id: spec.id || path.basename(opts.specFile || 'video', '.json'),
    W, H, vw, vh, u, fps, aspect, duration: +duration.toFixed(3), template,
    palette: pal, typography: spec.typography || {}, safe, fonts, brand: spec.brand || {}, locale: spec.locale || 'es',
    progress: spec.progress === false ? { style: 'none' } : { style: 'segments', position: 'top', ...(spec.progress || {}) },
    subtitles: spec.subtitles === false ? { enabled: false } : spec.subtitles || {},
    legal: spec.legal || null, beat, debugGuides: !!opts.guides,
    scenes, captions,
  };
  return {
    resolved, warns,
    audio: { music, sfxEnabled: A.sfx !== false, sfxVolume: num(A.sfxVolume, 0.8), musicVolume: num(music && music.volume, 0.5), narrations, narVolume: narCfg.volume, sfx, loudness: num(A.loudness, -14), duck: A.duck !== false },
  };
}
