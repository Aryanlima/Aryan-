#!/usr/bin/env node
// CLI: node render.mjs specs/ejemplo.json out/ejemplo.mp4 [opciones]
//      node render.mjs --all specs out            (renderiza todos los .json de una carpeta)
// Ver README.md para el formato del spec y todas las opciones.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { PIPE_DIR, CACHE_DIR, mkdirp, run, ffprobe, Timer, fmtSec, sha1 } from './lib/util.mjs';
import { compileSpec } from './lib/compile.mjs';
import { buildAudio } from './lib/audio.mjs';
import { captureFrames, captureStills } from './lib/capture.mjs';

const HELP = `Uso:
  node render.mjs <spec.json> <salida.mp4> [opciones]
  node render.mjs --all <carpeta_specs> <carpeta_salida> [opciones]

Opciones:
  --aspect 9:16|16:9|1:1|4:5   Fuerza la relación de aspecto (anula el spec)
  --fps N                      Fotogramas por segundo (def. 30)
  --scale X                    Escala de render (0.5 = mitad de resolución, para previews rápidas)
  --workers N                  Procesos de captura en paralelo (def. min(4, CPUs))
  --crf N                      Calidad x264 (def. 18; más alto = más pequeño)
  --preset NAME                Preset x264 (def. veryfast; usa slow para entrega final)
  --max SEG                    Renderiza solo los primeros SEG segundos
  --png                        Captura PNG sin pérdida (más lento) en vez de JPEG q94
  --no-audio                   Sin música/SFX/narración
  --stills t1,t2,...           No renderiza vídeo: guarda PNG de esos instantes en <salida> (carpeta)
  --guides                     Dibuja la zona segura (depuración)
  --keep                       Conserva los frames intermedios en .cache/work
  --report                     Escribe <salida>.json con tiempos y metadatos
  --help
`;

function parseArgs(argv) {
  const o = { _: [], workers: Math.min(4, os.cpus().length || 4) };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const val = () => argv[++i];
    if (a === '--help' || a === '-h') o.help = true;
    else if (a === '--all') o.all = true;
    else if (a === '--aspect') o.aspect = val();
    else if (a === '--fps') o.fps = +val();
    else if (a === '--scale') o.scale = +val();
    else if (a === '--workers') o.workers = +val();
    else if (a === '--crf') o.crf = +val();
    else if (a === '--preset') o.preset = val();
    else if (a === '--max') o.maxDuration = +val();
    else if (a === '--png') o.png = true;
    else if (a === '--no-audio') o.noAudio = true;
    else if (a === '--stills') o.stills = val().split(',').map(Number);
    else if (a === '--guides') o.guides = true;
    else if (a === '--keep') o.keep = true;
    else if (a === '--report') o.report = true;
    else if (a === '--size') o.size = val();
    else if (a.startsWith('--')) { console.error('Opción desconocida: ' + a); process.exit(2); }
    else o._.push(a);
  }
  return o;
}

async function renderOne(specFile, outFile, o) {
  const T = new Timer();
  const specAbs = path.resolve(specFile);
  const raw = JSON.parse(fs.readFileSync(specAbs, 'utf8'));
  const specDir = path.dirname(specAbs);
  const { resolved, warns, audio } = await compileSpec(raw, { specDir, opts: { ...o, specFile: specAbs } });
  T.mark('compilar+TTS+clips');
  warns.forEach((w) => console.warn('[aviso] ' + w));
  const id = resolved.id;
  console.log(`▶ ${id}  ${resolved.vw}x${resolved.vh} @${resolved.fps}fps  ${resolved.duration.toFixed(2)}s  ${resolved.scenes.length} escenas  [${resolved.template}]`);

  if (o.stills) {
    const r = await captureStills(resolved, o.stills, outFile, id);
    r.logs.forEach((l) => console.warn('[navegador] ' + l));
    r.files.forEach((f) => console.log('  still: ' + f));
    return { id, stills: r.files };
  }

  const work = mkdirp(path.join(CACHE_DIR, 'work', `${id}-${sha1(specAbs, Date.now()).slice(0, 6)}`));
  try {
    // audio (en paralelo con la captura: no comparten CPU de forma crítica)
    const audioP = o.noAudio ? Promise.resolve(null) : buildAudio(audio, resolved.duration, work);
    const frames = path.join(work, 'frames');
    let lastPct = -1;
    const cap = await captureFrames(resolved, frames, {
      workers: o.workers, format: o.png ? 'png' : 'jpeg', quality: 94,
      onProgress: (d, n) => { const p = Math.floor((d / n) * 10) * 10; if (p !== lastPct) { lastPct = p; process.stdout.write(`  captura ${p}%\r`); } },
    });
    T.mark('captura');
    if (process.env.PROFILE) console.log('  por frame (ms, por worker):', JSON.stringify(cap.perFrameMs), 'arranque navegador', cap.startMs + 'ms');
    cap.logs.forEach((l) => console.warn('[navegador] ' + l));
    const aud = await audioP;
    T.mark('audio');
    if (aud) console.log('  audio: ' + aud.parts.join(' · '));

    mkdirp(path.dirname(path.resolve(outFile)));
    const vf = [`scale=${resolved.vw}:${resolved.vh}:flags=lanczos:in_range=full:in_color_matrix=bt601:out_range=limited:out_color_matrix=bt709`, 'format=yuv420p'].join(',');
    const args = ['-y', '-v', 'error', '-framerate', String(resolved.fps), '-i', path.join(frames, `f_%06d.${cap.ext}`)];
    if (aud) args.push('-i', aud.file);
    const enc = raw.encode || {};
    args.push('-vf', vf, '-c:v', 'libx264', '-preset', o.preset || enc.preset || 'veryfast', '-crf', String(o.crf != null ? o.crf : enc.crf != null ? enc.crf : 18), '-profile:v', 'high', '-pix_fmt', 'yuv420p',
      '-colorspace', 'bt709', '-color_primaries', 'bt709', '-color_trc', 'bt709', '-g', String(resolved.fps * 2), '-movflags', '+faststart');
    if (aud) args.push('-c:a', 'aac', '-b:a', '192k', '-ar', '44100', '-ac', '2');
    else args.push('-an');
    args.push('-t', resolved.duration.toFixed(3), path.resolve(outFile));
    await run('ffmpeg', args);
    T.mark('codificar');

    const info = await ffprobe(outFile);
    const v = info.streams.find((s) => s.codec_type === 'video'), a = info.streams.find((s) => s.codec_type === 'audio');
    const size = fs.statSync(outFile).size;
    const rep = {
      id, out: outFile, width: v.width, height: v.height, codec: v.codec_name, pix_fmt: v.pix_fmt, audio: a ? a.codec_name : null,
      duration_s: +parseFloat(info.format.duration).toFixed(2), frames: cap.frames, size_mb: +(size / 1048576).toFixed(2),
      workers: cap.workers, capture_fps: +(cap.frames / (cap.ms / 1000)).toFixed(1),
      timings_ms: { ...T.marks, total: T.total() },
    };
    console.log(`✔ ${outFile}  ${rep.width}x${rep.height} ${rep.codec}${a ? '+' + rep.audio : ''}  ${rep.duration_s}s  ${rep.size_mb} MB`);
    console.log(`  tiempos: ${Object.entries(T.marks).map(([k, v]) => `${k} ${fmtSec(v)}`).join(' · ')} · TOTAL ${fmtSec(T.total())}  (captura ${rep.capture_fps} fps con ${cap.workers} workers)`);
    if (o.report) fs.writeFileSync(outFile.replace(/\.mp4$/, '') + '.json', JSON.stringify(rep, null, 2));
    return rep;
  } finally {
    if (!o.keep) fs.rmSync(work, { recursive: true, force: true });
    else console.log('  frames conservados en ' + path.relative(process.cwd(), work));
  }
}

const o = parseArgs(process.argv.slice(2));
if (o.help || !o._.length) { console.log(HELP); process.exit(o.help ? 0 : 2); }
try {
  if (o.all) {
    const [dir, outDir] = o._;
    if (!dir || !outDir) { console.log(HELP); process.exit(2); }
    const files = fs.readdirSync(dir).filter((f) => f.endsWith('.json')).sort();
    const t0 = Date.now();
    for (const f of files) await renderOne(path.join(dir, f), path.join(outDir, f.replace(/\.json$/, '.mp4')), o);
    console.log(`\nTotal ${files.length} videos en ${fmtSec(Date.now() - t0)}`);
  } else {
    const [spec, out] = o._;
    if (!out) { console.log(HELP); process.exit(2); }
    await renderOne(spec, out, o);
  }
} catch (e) {
  console.error('✖ ' + (e && e.stack ? e.stack : e));
  process.exit(1);
}
