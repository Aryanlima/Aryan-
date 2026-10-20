// Banda sonora: música sintética (o archivo del usuario) + SFX + narración, con ducking (sidechaincompress) y loudnorm.
import fs from 'node:fs';
import path from 'node:path';
import { SR, renderMusic, renderSfxTrack, writeWav } from './synth.mjs';
import { run } from './util.mjs';

async function decodeMono(file) {
  const { stdout } = await run('ffmpeg', ['-v', 'error', '-i', file, '-f', 'f32le', '-ac', '1', '-ar', String(SR), '-'], { binary: true });
  return new Float32Array(stdout.buffer.slice(stdout.byteOffset, stdout.byteOffset + stdout.byteLength - (stdout.byteLength % 4)));
}

/** Devuelve { file, parts } con un WAV estéreo 44.1 kHz de exactamente `duration` s (o null si no hay audio configurado). */
export async function buildAudio(audio, duration, workDir) {
  const parts = [];
  const inputs = [];
  const D = duration;

  // música
  let musicFile = null;
  if (audio.music) {
    if (audio.music.file) {
      if (fs.existsSync(audio.music.file)) { musicFile = audio.music.file; parts.push('música: ' + path.basename(musicFile) + ' (archivo)'); }
      else parts.push('música: archivo no encontrado, omitida');
    } else {
      const m = renderMusic({ style: audio.music.style, bpm: audio.music.bpm, key: audio.music.key, seconds: D + 0.5, seed: audio.music.seed || 7 });
      musicFile = path.join(workDir, 'music.wav');
      writeWav(musicFile, m.L, m.R);
      parts.push(`música sintética '${audio.music.style}' ${m.bpm} BPM`);
    }
  }
  // sfx
  let sfxFile = null;
  if (audio.sfxEnabled && audio.sfx.length) {
    const tr = renderSfxTrack(audio.sfx, D);
    sfxFile = path.join(workDir, 'sfx.wav');
    writeWav(sfxFile, tr.L, tr.R);
    parts.push(`${audio.sfx.length} SFX`);
  }
  // narración
  let narFile = null;
  if (audio.narrations.length) {
    const n = Math.ceil(D * SR), buf = new Float32Array(n);
    for (const nr of audio.narrations) {
      const pcm = await decodeMono(nr.file), o = Math.round(nr.start * SR), g = (nr.gain != null ? nr.gain : 1) * audio.narVolume;
      for (let i = 0; i < pcm.length && o + i < n; i++) if (o + i >= 0) buf[o + i] += pcm[i] * g;
    }
    narFile = path.join(workDir, 'narration.wav');
    writeWav(narFile, buf, buf);
    parts.push(`${audio.narrations.length} locución(es)`);
  }
  const out = path.join(workDir, 'mix.wav');
  const args = ['-y', '-v', 'error'];
  const idx = {};
  let k = 0;
  const addIn = (name, f, extra = []) => { args.push(...extra, '-i', f); idx[name] = k++; };
  if (musicFile) addIn('m', musicFile, audio.music && audio.music.file ? ['-stream_loop', '-1'] : []);
  if (sfxFile) addIn('s', sfxFile);
  if (narFile) addIn('n', narFile);
  if (k === 0) { // sin audio: silencio estéreo
    args.push('-f', 'lavfi', '-i', `anullsrc=r=${SR}:cl=stereo`, '-t', String(D), '-c:a', 'pcm_s16le', out);
    await run('ffmpeg', args);
    return { file: out, parts: ['silencio'] };
  }
  const F = [], fmt = `aformat=sample_rates=${SR}:channel_layouts=stereo`;
  const fadeOut = Math.min(1.2, D * 0.1);
  let mixIns = [];
  if (musicFile) {
    F.push(`[${idx.m}:a]${fmt},atrim=0:${D},asetpts=PTS-STARTPTS,volume=${audio.musicVolume},afade=t=in:st=0:d=0.05,afade=t=out:st=${Math.max(0, D - fadeOut).toFixed(3)}:d=${fadeOut.toFixed(3)}[m0]`);
  }
  if (narFile) {
    F.push(`[${idx.n}:a]${fmt},asplit=2[n1][n2]`);
    if (musicFile && audio.duck) { F.push(`[m0][n1]sidechaincompress=threshold=0.035:ratio=5:attack=12:release=380:makeup=1[md]`); mixIns.push('[md]'); parts.push('ducking (sidechain) bajo la voz'); }
    else { if (musicFile) mixIns.push('[m0]'); F.push('[n1]anullsink'); }
    mixIns.push('[n2]');
  } else if (musicFile) mixIns.push('[m0]');
  if (sfxFile) { F.push(`[${idx.s}:a]${fmt},volume=${audio.sfxVolume}[sx]`); mixIns.push('[sx]'); }
  F.push(`${mixIns.join('')}amix=inputs=${mixIns.length}:normalize=0:duration=longest,loudnorm=I=${audio.loudness}:TP=-1.5:LRA=11,alimiter=limit=0.95,apad=whole_dur=${D},atrim=0:${D}[mix]`);
  args.push('-filter_complex', F.join(';'), '-map', '[mix]', '-ar', String(SR), '-ac', '2', '-c:a', 'pcm_s16le', out);
  await run('ffmpeg', args);
  return { file: out, parts };
}
