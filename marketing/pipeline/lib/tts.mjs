// TTS local opcional. Único motor disponible sin red: eSpeak (vía el paquete npm `mespeak`, WASM/JS puro).
// Es inteligible pero ROBÓTICO: sirve para pruebas y para fijar tiempos de subtítulos, no para publicar.
// Para voz decente: genera la locución fuera (ElevenLabs, OpenAI TTS, Piper con voz es_ES, etc.) y usa
// `narrationFile` en la escena o `audio.voiceover` en el spec. Ver README.
import { createRequire } from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
import { PIPE_DIR, CACHE_DIR, mkdirp, sha1, run, mediaDuration, warn } from './util.mjs';

const require = createRequire(import.meta.url);
let engine = null, engineTried = false;

function loadEngine() {
  if (engineTried) return engine;
  engineTried = true;
  try {
    const dir = path.join(PIPE_DIR, 'node_modules', 'mespeak');
    const me = require(path.join(dir, 'src', 'index.js'));
    me.loadConfig(JSON.parse(fs.readFileSync(path.join(dir, 'src', 'mespeak_config.json'), 'utf8')));
    engine = { me, dir, voices: new Set() };
  } catch (e) {
    warn('TTS eSpeak no disponible (¿npm install?):', e.message.split('\n')[0]);
  }
  return engine;
}

/** Sintetiza `text`; devuelve {file, duration} o null. Resultado cacheado en .cache/tts */
export async function synthesizeEspeak(text, { voice = 'es-la', speed = 158, pitch = 50, amplitude = 100 } = {}) {
  const clean = text.replace(/\*+/g, '').replace(/[\u{1F000}-\u{1FFFF}\u{2600}-\u{27BF}]/gu, '').replace(/\s+/g, ' ').trim();
  if (!clean) return null;
  const key = sha1('espeak-v2', clean, voice, speed, pitch, amplitude);
  const outDir = mkdirp(path.join(CACHE_DIR, 'tts'));
  const out = path.join(outDir, key + '.wav');
  if (fs.existsSync(out)) return { file: out, duration: await mediaDuration(out) };
  const en = loadEngine();
  if (!en) return null;
  if (!en.voices.has(voice)) {
    const vf = path.join(en.dir, 'voices', voice + '.json');
    if (!fs.existsSync(vf)) { warn(`Voz eSpeak '${voice}' no encontrada`); return null; }
    en.me.loadVoice(JSON.parse(fs.readFileSync(vf, 'utf8')));
    en.voices.add(voice);
  }
  const buf = en.me.speak(clean, { voice, rawdata: 'buffer', speed, pitch, amplitude, wordgap: 1 });
  if (!buf) { warn('eSpeak devolvió vacío para:', clean.slice(0, 40)); return null; }
  const raw = out + '.raw.wav';
  fs.writeFileSync(raw, Buffer.from(buf));
  // 44.1 kHz mono, recorte de silencios, EQ suave para quitar aspereza
  await run('ffmpeg', ['-y', '-v', 'error', '-i', raw, '-af',
    'silenceremove=start_periods=1:start_threshold=-50dB,highpass=f=110,lowpass=f=7000,equalizer=f=2800:t=q:w=1.2:g=-3,acompressor=threshold=-26dB:ratio=3:makeup=4,loudnorm=I=-17:TP=-2:LRA=7,alimiter=limit=0.9',
    '-ar', '44100', '-ac', '1', out]);
  fs.unlinkSync(raw);
  return { file: out, duration: await mediaDuration(out) };
}
