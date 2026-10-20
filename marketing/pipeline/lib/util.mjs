// Utilidades compartidas. Ninguna ruta absoluta: todo se resuelve relativo a este archivo.
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import fs from 'node:fs';
import crypto from 'node:crypto';

export const PIPE_DIR = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const CACHE_DIR = path.join(PIPE_DIR, '.cache');

export function sha1(...parts) {
  const h = crypto.createHash('sha1');
  for (const p of parts) h.update(typeof p === 'string' ? p : JSON.stringify(p));
  return h.digest('hex').slice(0, 16);
}

export function mkdirp(d) { fs.mkdirSync(d, { recursive: true }); return d; }

/** Ejecuta un comando y devuelve {code, stdout, stderr}. Lanza si code != 0 salvo allowFail. */
export function run(cmd, args, { allowFail = false, input = null, binary = false } = {}) {
  return new Promise((resolve, reject) => {
    const p = spawn(cmd, args, { stdio: ['pipe', 'pipe', 'pipe'] });
    const out = [], err = [];
    p.stdout.on('data', (d) => out.push(d));
    p.stderr.on('data', (d) => err.push(d));
    p.on('error', reject);
    p.on('close', (code) => {
      const stdout = binary ? Buffer.concat(out) : Buffer.concat(out).toString('utf8');
      const stderr = Buffer.concat(err).toString('utf8');
      if (code !== 0 && !allowFail) return reject(new Error(`${cmd} ${args.slice(0, 6).join(' ')} ... salió con código ${code}\n${stderr.slice(-1500)}`));
      resolve({ code, stdout, stderr });
    });
    if (input) p.stdin.end(input); else p.stdin.end();
  });
}

export async function ffprobe(file) {
  const { stdout } = await run('ffprobe', ['-v', 'error', '-print_format', 'json', '-show_format', '-show_streams', file]);
  return JSON.parse(stdout);
}
export async function mediaDuration(file) {
  const j = await ffprobe(file);
  const d = parseFloat(j.format && j.format.duration);
  return Number.isFinite(d) ? d : 0;
}

export function fmtSec(ms) { return (ms / 1000).toFixed(1) + 's'; }

export class Timer {
  constructor() { this.t0 = Date.now(); this.marks = {}; this.last = this.t0; }
  mark(name) { const n = Date.now(); this.marks[name] = n - this.last; this.last = n; }
  total() { return Date.now() - this.t0; }
}

export function warn(...a) { console.warn('[aviso]', ...a); }
