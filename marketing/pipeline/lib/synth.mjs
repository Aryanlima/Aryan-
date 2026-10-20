// Sintetizador mínimo en JS puro (sin dependencias): música de fondo + SFX libres de derechos.
// Todo es determinista (PRNG con semilla) y se escribe a WAV 16-bit estéreo 44.1 kHz.
import fs from 'node:fs';

export const SR = 44100;
const TAU = Math.PI * 2;
const mtof = (m) => 440 * Math.pow(2, (m - 69) / 12);

export function rngSeed(seed) {
  let a = seed >>> 0;
  return () => {
    a |= 0; a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/* ---------- filtros ---------- */
function lp(x, fc) {
  const a = 1 - Math.exp((-TAU * fc) / SR), y = new Float32Array(x.length);
  let s = 0;
  for (let i = 0; i < x.length; i++) { s += a * (x[i] - s); y[i] = s; }
  return y;
}
function hp(x, fc) {
  const l = lp(x, fc), y = new Float32Array(x.length);
  for (let i = 0; i < x.length; i++) y[i] = x[i] - l[i];
  return y;
}
function lpSweep(x, fcFn) { // lowpass con cutoff variable fcFn(i)
  const y = new Float32Array(x.length); let s = 0;
  for (let i = 0; i < x.length; i++) { const a = 1 - Math.exp((-TAU * fcFn(i)) / SR); s += a * (x[i] - s); y[i] = s; }
  return y;
}
const env = (len, f) => { const e = new Float32Array(len); for (let i = 0; i < len; i++) e[i] = f(i / SR, i); return e; };
const mul = (x, e) => { for (let i = 0; i < x.length; i++) x[i] *= e[i]; return x; };
const noise = (n, R) => { const x = new Float32Array(n); for (let i = 0; i < n; i++) x[i] = R() * 2 - 1; return x; };
const saw = (ph) => 2 * (ph - Math.floor(ph + 0.5));
const sqr = (ph, d = 0.5) => ((ph % 1) + 1) % 1 < d ? 1 : -1;
const tri = (ph) => 4 * Math.abs(ph - Math.floor(ph + 0.75) + 0.25) - 1;

export class Stereo {
  constructor(seconds) { this.n = Math.ceil(seconds * SR); this.L = new Float32Array(this.n); this.R = new Float32Array(this.n); }
  add(mono, t, gain = 1, pan = 0) {
    const s0 = Math.round(t * SR); if (s0 >= this.n) return;
    const gl = gain * Math.cos(((pan + 1) * Math.PI) / 4), gr = gain * Math.sin(((pan + 1) * Math.PI) / 4);
    const end = Math.min(this.n, s0 + mono.length);
    for (let i = Math.max(0, s0); i < end; i++) { const v = mono[i - s0]; this.L[i] += v * gl; this.R[i] += v * gr; }
  }
  mixIn(o, g = 1) { for (let i = 0; i < this.n; i++) { this.L[i] += o.L[i] * g; this.R[i] += o.R[i] * g; } }
  peak() { let p = 0; for (let i = 0; i < this.n; i++) p = Math.max(p, Math.abs(this.L[i]), Math.abs(this.R[i])); return p; }
  scale(g) { for (let i = 0; i < this.n; i++) { this.L[i] *= g; this.R[i] *= g; } }
}

function reverb(st, mix = 0.2) { // Schroeder simplificado
  const combs = [1557, 1617, 1491, 1422], aps = [225, 556];
  for (const ch of [st.L, st.R]) {
    const dry = Float32Array.from(ch), wet = new Float32Array(ch.length);
    for (const d of combs) {
      const buf = new Float32Array(d); let idx = 0;
      for (let i = 0; i < ch.length; i++) { const y = buf[idx]; buf[idx] = dry[i] + y * 0.8; idx = (idx + 1) % d; wet[i] += y * 0.25; }
    }
    for (const d of aps) {
      const buf = new Float32Array(d); let idx = 0;
      for (let i = 0; i < ch.length; i++) { const y = buf[idx], x = wet[i]; buf[idx] = x + y * 0.5; wet[i] = y - x * 0.5; idx = (idx + 1) % d; }
    }
    for (let i = 0; i < ch.length; i++) ch[i] = dry[i] + wet[i] * mix * 2;
  }
}
function pingPong(st, delay, fb = 0.4) { // eco estéreo con realimentación cruzada (en sitio)
  const d = Math.round(delay * SR);
  for (let i = d; i < st.n; i++) { st.L[i] += fb * st.R[i - d]; st.R[i] += fb * st.L[i - d]; }
}

/* ---------- voces ---------- */
function kick(R, len = 0.38, deep = 1) {
  const n = Math.floor(len * SR), y = new Float32Array(n); let ph = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR, f = 42 + 130 * Math.exp(-t * 32) * deep;
    ph += (TAU * f) / SR;
    y[i] = Math.sin(ph) * Math.exp(-t * 8.5) + (R() * 2 - 1) * Math.exp(-t * 400) * 0.25;
  }
  return y;
}
function snare(R, len = 0.22) {
  const n = Math.floor(len * SR), nz = hp(noise(n, R), 1400), y = new Float32Array(n);
  for (let i = 0; i < n; i++) { const t = i / SR; y[i] = nz[i] * Math.exp(-t * 17) * 0.9 + Math.sin(TAU * 188 * t) * Math.exp(-t * 26) * 0.5; }
  return y;
}
function clap(R) {
  const n = Math.floor(0.25 * SR), nz = lp(hp(noise(n, R), 900), 7000), y = new Float32Array(n);
  for (let i = 0; i < n; i++) { const t = i / SR; let e = 0; for (const o of [0, 0.011, 0.022]) if (t >= o) e += Math.exp(-(t - o) * (o === 0.022 ? 18 : 70)); y[i] = nz[i] * Math.min(1, e) * 1.1; }
  return y;
}
function hat(R, open = false) {
  const len = open ? 0.28 : 0.07, n = Math.floor(len * SR), nz = hp(noise(n, R), 7000), y = new Float32Array(n);
  for (let i = 0; i < n; i++) y[i] = nz[i] * Math.exp((-i / SR) * (open ? 13 : 75));
  return y;
}
function bass(f, len, kind = 'saw') {
  const n = Math.floor((len + 0.08) * SR), y = new Float32Array(n); let ph = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR; ph += f / SR;
    const w = kind === 'sine' ? Math.sin(TAU * ph) : kind === 'tri' ? tri(ph) : saw(ph) * 0.8 + Math.sin(TAU * ph) * 0.6;
    const a = Math.min(1, t / 0.006), r = t > len ? Math.max(0, 1 - (t - len) / 0.08) : 1;
    y[i] = w * a * r * Math.exp(-t * (kind === 'sine' ? 1.2 : 2.2));
  }
  return kind === 'saw' ? lp(y, 700) : y;
}
function pluck(f, len = 0.25, bright = 1) {
  const n = Math.floor(len * SR), y = new Float32Array(n); let p1 = 0, p2 = 0;
  for (let i = 0; i < n; i++) { const t = i / SR; p1 += f / SR; p2 += (f * 1.005) / SR; y[i] = (saw(p1) + saw(p2)) * 0.5 * Math.exp(-t * 9) * Math.min(1, t / 0.002); }
  return lpSweep(y, (i) => 600 + 5200 * bright * Math.exp((-i / SR) * 14));
}
function pad(f, len) {
  const n = Math.floor((len + 0.4) * SR), y = new Float32Array(n); const ph = [0, 0, 0], det = [0.994, 1, 1.007];
  for (let i = 0; i < n; i++) {
    const t = i / SR; let s = 0;
    for (let k = 0; k < 3; k++) { ph[k] += (f * det[k]) / SR; s += saw(ph[k]); }
    const a = Math.min(1, t / 0.28), r = t > len ? Math.max(0, 1 - (t - len) / 0.4) : 1;
    y[i] = (s / 3) * a * r;
  }
  return lp(y, 1400);
}
function lead(f, len, duty = 0.5, vib = 0.004) {
  const n = Math.floor((len + 0.05) * SR), y = new Float32Array(n); let ph = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR; ph += (f * (1 + vib * Math.sin(TAU * 5.5 * t) * Math.min(1, t * 6))) / SR;
    const a = Math.min(1, t / 0.004), r = t > len ? Math.max(0, 1 - (t - len) / 0.05) : 1;
    y[i] = sqr(ph, duty) * a * r * (0.75 + 0.25 * Math.exp(-t * 6));
  }
  return y;
}
function bell(f, len = 0.9, dec = 4) {
  const n = Math.floor(len * SR), y = new Float32Array(n);
  for (let i = 0; i < n; i++) { const t = i / SR; y[i] = (Math.sin(TAU * f * t) + 0.45 * Math.sin(TAU * f * 2.76 * t) * Math.exp(-t * 8) + 0.25 * Math.sin(TAU * f * 5.4 * t) * Math.exp(-t * 14)) * Math.exp(-t * dec) * Math.min(1, t / 0.002); }
  return y;
}
function rhodes(f, len = 1.2) {
  const n = Math.floor(len * SR), y = new Float32Array(n);
  for (let i = 0; i < n; i++) { const t = i / SR; y[i] = (Math.sin(TAU * f * t + 0.6 * Math.sin(TAU * f * t) * Math.exp(-t * 6)) + 0.18 * Math.sin(TAU * 2 * f * t)) * Math.exp(-t * 2.6) * Math.min(1, t / 0.004); }
  return lp(y, 3500);
}

/* ---------- acordes ---------- */
const QUAL = { m: [0, 3, 7], M: [0, 4, 7], m7: [0, 3, 7, 10], M7: [0, 4, 7, 11], sus: [0, 5, 7] };
const KEYS = { C: 0, 'C#': 1, D: 2, 'D#': 3, E: 4, F: 5, 'F#': 6, G: 7, 'G#': 8, A: 9, 'A#': 10, B: 11 };
const chordOf = (rootMidi, off, q) => QUAL[q].map((i) => rootMidi + off + i);

export const STYLES = {
  hype:   { bpm: 140, key: 'A', prog: [[0, 'm'], [-4, 'M'], [-9, 'M'], [-2, 'M']] },
  arcade: { bpm: 128, key: 'C', prog: [[0, 'M'], [-3, 'm'], [-7, 'M'], [-5, 'M']] },
  chill:  { bpm: 88,  key: 'D', prog: [[0, 'm7'], [-4, 'M7'], [-9, 'M7'], [-2, 'M7']] },
  epic:   { bpm: 100, key: 'D', prog: [[0, 'm'], [-4, 'M'], [-9, 'M'], [-2, 'M']] },
};

/** Genera música. Devuelve {L,R,bpm,kickTimes}. */
export function renderMusic({ style = 'hype', bpm, key, seconds = 20, seed = 7 } = {}) {
  const S = STYLES[style] || STYLES.hype;
  bpm = bpm || S.bpm; key = key || S.key;
  const R = rngSeed(seed), step = 60 / bpm / 4, bars = Math.ceil((seconds + 1) / (step * 16)) + 1;
  const keyBase = KEYS[key] ?? 9;
  const drums = new Stereo(seconds + 1), body = new Stereo(seconds + 1), mel = new Stereo(seconds + 1);
  const kicks = [];
  const K = kick(R), K2 = kick(R, 0.6, 0.7), SN = snare(R), CL = clap(R), HH = hat(R), HO = hat(R, true);
  const rootMidi = 48 + keyBase; // octava 3
  const penta = [0, 2, 4, 7, 9];

  for (let b = 0; b < bars; b++) {
    const [off, q] = S.prog[b % S.prog.length];
    const ch = chordOf(rootMidi, off, q);
    const t0 = b * 16 * step;
    if (t0 > seconds + 0.5) break;
    if (style === 'hype') {
      for (const n of ch) mel.add(pad(mtof(n + 12), 16 * step), t0, 0.07, (R() - 0.5) * 0.6);
      for (let s = 0; s < 16; s++) {
        const t = t0 + s * step;
        if (s % 4 === 0) { drums.add(K, t, 0.95); kicks.push(t); }
        if (s === 4 || s === 12) { drums.add(CL, t, 0.55); drums.add(SN, t, 0.3); }
        if (s % 4 === 2) drums.add(HO, t, 0.2, 0.25);
        else if (s % 2 === 0) drums.add(HH, t, 0.12, -0.2);
        if (b % 4 === 3 && s >= 12) drums.add(HH, t, 0.18); // redoble
        if (s % 2 === 0) {
          const oct = [0, 0, 12, 0, 0, 12, 0, 12][(s / 2) % 8];
          body.add(bass(mtof(ch[0] - 12 + oct), step * 1.8, 'saw'), t, 0.5);
        }
        const seq = [0, 2, 1, 2, 0, 2, 1, 3, 0, 2, 1, 2, 1, 2, 3, 2][s];
        mel.add(pluck(mtof(ch[seq % ch.length] + 12 + (s % 8 >= 4 ? 12 : 0)), 0.22), t, 0.2, s % 2 ? 0.35 : -0.35);
      }
      if (b % 4 === 0) drums.add(hat(R, true), t0, 0.3);
    } else if (style === 'arcade') {
      for (let s = 0; s < 16; s++) {
        const t = t0 + s * step;
        if (s % 4 === 0) { drums.add(K, t, 0.85); kicks.push(t); }
        if (s === 4 || s === 12) drums.add(SN, t, 0.5);
        if (s % 2 === 0) drums.add(HH, t, 0.12, s % 4 ? 0.2 : -0.2);
        if (s % 2 === 0) body.add(bass(mtof(ch[(s / 2) % 4 === 3 ? 2 : 0] - 12), step * 1.7, 'tri'), t, 0.55);
        const pr = R();
        if (s % 2 === 0 || pr < 0.35) {
          const deg = penta[Math.floor(R() * 5)] + (R() < 0.4 ? 12 : 0);
          if (s % 4 === 0 || pr < 0.55) mel.add(lead(mtof(rootMidi + off + 12 + deg), step * (R() < 0.3 ? 3.5 : 1.7), 0.25), t, 0.22, 0.1);
        }
        mel.add(lead(mtof(ch[s % 3] + 24), step * 0.8, 0.125, 0), t, 0.09, -0.3);
      }
    } else if (style === 'chill') {
      for (const n of ch) mel.add(rhodes(mtof(n + 12), 16 * step * 0.9), t0 + R() * 0.02, 0.17, (R() - 0.5) * 0.5);
      for (let s = 0; s < 16; s++) {
        const t = t0 + s * step * 1.0 + (s % 2 ? step * 0.25 : 0); // swing
        if (s === 0 || s === 10) { drums.add(K2, t, 0.7); kicks.push(t); }
        if (s === 4 || s === 12) drums.add(lp(SN, 5000), t, 0.38);
        if (s % 2 === 0) drums.add(HH, t, 0.09, 0.2);
        if (s === 0 || s === 8) body.add(bass(mtof(ch[0] - 12), step * 6, 'sine'), t, 0.7);
        if (R() < 0.22) mel.add(rhodes(mtof(ch[Math.floor(R() * ch.length)] + 24), 0.8), t, 0.12, 0.4);
      }
    } else { // epic
      for (const n of ch) mel.add(pad(mtof(n + 12), 16 * step), t0, 0.1, (R() - 0.5) * 0.8);
      for (const n of ch) mel.add(pad(mtof(n), 16 * step), t0, 0.09);
      for (let s = 0; s < 16; s++) {
        const t = t0 + s * step;
        if (s === 0 || s === 8) { drums.add(K2, t, 1.0); kicks.push(t); }
        if (s === 4 || s === 12) drums.add(lp(SN, 3500), t, 0.4);
        if (b % 4 === 3 && s >= 8) { drums.add(K2, t, 0.45); kicks.push(t); }
        if (s % 4 === 0) mel.add(bell(mtof(ch[(s / 4) % ch.length] + 24), 1.0, 3), t, 0.16, s % 8 ? 0.4 : -0.4);
        if (s === 0) body.add(bass(mtof(ch[0] - 12), step * 8, 'sine'), t, 0.8);
      }
      if (b % 4 === 0) drums.add(hp(noise(Math.floor(1.2 * SR), R), 3000).map((v, i) => v * Math.exp((-i / SR) * 3)), t0, 0.35);
    }
  }
  // sidechain: baja bajo/melodía en cada bombo
  const duck = new Float32Array(body.n).fill(1);
  for (const kt of kicks) {
    const s0 = Math.floor(kt * SR), len = Math.floor(0.28 * SR);
    for (let i = 0; i < len && s0 + i < duck.length; i++) duck[s0 + i] = Math.min(duck[s0 + i], 1 - 0.62 * Math.exp((-i / SR) * 11));
  }
  for (const bus of [body, mel]) for (let i = 0; i < bus.n; i++) { bus.L[i] *= duck[i]; bus.R[i] *= duck[i]; }
  reverb(mel, style === 'epic' ? 0.35 : 0.16);
  if (style === 'arcade' || style === 'hype') pingPong(mel, step * 3, 0.38);
  const out = new Stereo(seconds);
  out.mixIn(drums, 1);
  out.mixIn(body, 1);
  out.mixIn(mel, 1);
  // limitar y fade-out
  const pk = out.peak() || 1; out.scale(0.9 / pk);
  const fo = Math.floor(Math.min(1.4, seconds * 0.1) * SR);
  for (let i = 0; i < fo; i++) { const g = i / fo; const k = out.n - 1 - i; out.L[k] *= g * g; out.R[k] *= g * g; }
  return { L: out.L, R: out.R, bpm, kickTimes: kicks };
}

/* ---------- SFX ---------- */
export function makeSfx(type, R = rngSeed(11)) {
  switch (type) {
    case 'pop': { const n = Math.floor(0.12 * SR), y = new Float32Array(n); let ph = 0;
      for (let i = 0; i < n; i++) { const t = i / SR; ph += (TAU * (420 + 900 * Math.exp(-t * 40))) / SR; y[i] = Math.sin(ph) * Math.exp(-t * 32) + (R() * 2 - 1) * Math.exp(-t * 500) * 0.2; } return y; }
    case 'hit': { const n = Math.floor(0.18 * SR), y = new Float32Array(n); let ph = 0;
      for (let i = 0; i < n; i++) { const t = i / SR; ph += (TAU * (180 + 400 * Math.exp(-t * 50))) / SR; y[i] = (Math.sin(ph) * 0.8 + (R() * 2 - 1) * 0.35) * Math.exp(-t * 22); } return y; }
    case 'tick': { const n = Math.floor(0.03 * SR), y = new Float32Array(n);
      for (let i = 0; i < n; i++) { const t = i / SR; y[i] = Math.sin(TAU * 1800 * t) * Math.exp(-t * 180) * 0.8; } return y; }
    case 'whoosh': { const len = 0.45, n = Math.floor(len * SR), nz = noise(n, R);
      const f = lpSweep(nz, (i) => 250 + 7000 * Math.pow(Math.sin((Math.PI * i) / n), 2));
      return mul(hp(f, 180), env(n, (t) => Math.pow(Math.sin((Math.PI * t) / len), 1.4) * 1.4)); }
    case 'swipe': { const len = 0.25, n = Math.floor(len * SR), nz = noise(n, R);
      const f = lpSweep(nz, (i) => 600 + 9000 * (i / n));
      return mul(hp(f, 400), env(n, (t) => Math.pow(Math.sin((Math.PI * t) / len), 1.2))); }
    case 'impact': { const n = Math.floor(0.9 * SR), y = new Float32Array(n); let ph = 0; const nz = lp(noise(n, R), 2500);
      for (let i = 0; i < n; i++) { const t = i / SR; ph += (TAU * (38 + 110 * Math.exp(-t * 14))) / SR; y[i] = Math.sin(ph) * Math.exp(-t * 4.2) * 1.1 + nz[i] * Math.exp(-t * 11) * 0.6; } return y; }
    case 'ding': { const a = bell(1318.5, 1.1, 3.2), b = bell(1975.5, 1.1, 4), y = new Float32Array(a.length); for (let i = 0; i < y.length; i++) y[i] = a[i] * 0.6 + b[i] * 0.35; return y; }
    case 'coin': { const n = Math.floor(0.32 * SR), y = new Float32Array(n);
      for (let i = 0; i < n; i++) { const t = i / SR, f = t < 0.07 ? 987.8 : 1318.5; y[i] = sqr(f * t, 0.5) * 0.35 * Math.exp(-Math.max(0, t - (t < 0.07 ? 0 : 0.07)) * (t < 0.07 ? 6 : 9)) * Math.min(1, t / 0.002); } return lp(y, 7000); }
    case 'riser': { const len = 1.4, n = Math.floor(len * SR), nz = noise(n, R); const f = lpSweep(nz, (i) => 300 + 9000 * Math.pow(i / n, 2.2));
      const y = mul(hp(f, 250), env(n, (t) => Math.pow(t / len, 1.6))); let ph = 0; for (let i = 0; i < n; i++) { const t = i / SR; ph += (TAU * (200 + 1400 * Math.pow(t / len, 2))) / SR; y[i] += Math.sin(ph) * 0.18 * (t / len); } return y; }
    case 'success': { const notes = [523.25, 659.25, 783.99, 1046.5], n = Math.floor(1.3 * SR), y = new Float32Array(n);
      notes.forEach((f, k) => { const b = bell(f, 1.0, 3.2), o = Math.floor(k * 0.075 * SR); for (let i = 0; i < b.length && o + i < n; i++) y[o + i] += b[i] * 0.5; }); return y; }
    case 'alarm': { const n = Math.floor(0.7 * SR), y = new Float32Array(n);
      for (let i = 0; i < n; i++) { const t = i / SR, on = (t % 0.35) < 0.22; y[i] = on ? sqr((t % 0.35) * (t < 0.35 ? 880 : 740), 0.5) * 0.25 * Math.min(1, ((t % 0.35) / 0.004)) : 0; } return lp(y, 5000); }
    case 'boom': { const n = Math.floor(1.4 * SR), y = new Float32Array(n); let ph = 0; const nz = lp(noise(n, R), 1800);
      for (let i = 0; i < n; i++) { const t = i / SR; ph += (TAU * (32 + 80 * Math.exp(-t * 9))) / SR; y[i] = Math.sin(ph) * Math.exp(-t * 2.6) + nz[i] * Math.exp(-t * 6) * 0.7; } return y; }
    default: return makeSfx('pop', R);
  }
}

/** events: [{t, type, gain?, pan?}] -> Stereo */
export function renderSfxTrack(events, seconds) {
  const out = new Stereo(seconds + 1.5), cache = {};
  for (const e of events) {
    cache[e.type] = cache[e.type] || makeSfx(e.type);
    out.add(cache[e.type], e.t, e.gain != null ? e.gain : 0.7, e.pan || 0);
  }
  const trimmed = new Stereo(seconds); trimmed.mixIn({ L: out.L.subarray(0, trimmed.n), R: out.R.subarray(0, trimmed.n) }, 1);
  return trimmed;
}

/* ---------- WAV ---------- */
export function writeWav(file, L, R, sr = SR) {
  const n = L.length, buf = Buffer.alloc(44 + n * 4);
  buf.write('RIFF', 0); buf.writeUInt32LE(36 + n * 4, 4); buf.write('WAVE', 8); buf.write('fmt ', 12);
  buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(2, 22); buf.writeUInt32LE(sr, 24);
  buf.writeUInt32LE(sr * 4, 28); buf.writeUInt16LE(4, 32); buf.writeUInt16LE(16, 34); buf.write('data', 36); buf.writeUInt32LE(n * 4, 40);
  let o = 44;
  for (let i = 0; i < n; i++) {
    buf.writeInt16LE(Math.max(-32768, Math.min(32767, Math.round(L[i] * 32767))), o); o += 2;
    buf.writeInt16LE(Math.max(-32768, Math.min(32767, Math.round(R[i] * 32767))), o); o += 2;
  }
  fs.writeFileSync(file, buf);
}
