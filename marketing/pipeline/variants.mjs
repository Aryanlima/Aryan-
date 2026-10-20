#!/usr/bin/env node
// Genera N specs a partir de una base + una lista de variantes (para producir muchos vídeos sin copiar/pegar).
//   node variants.mjs specs/ejemplo-gancho.json variantes.json specs/generados
// variantes.json = [ { "id": "v1", "palette": "sunset", "hook": { "text": "..." }, "$set": { "scenes.0.text": "...", "cta.code": "X" } }, ... ]
//  - Las claves normales se fusionan en profundidad sobre la base (los arrays se reemplazan enteros).
//  - "$set" asigna por ruta con puntos (índices de array permitidos) para tocar un campo concreto.
// Después: node render.mjs --all specs/generados out/generados
import fs from 'node:fs';
import path from 'node:path';

const [base, vars, outDir] = process.argv.slice(2);
if (!base || !vars || !outDir) { console.error('Uso: node variants.mjs <base.json> <variantes.json> <carpeta_salida>'); process.exit(2); }

const isObj = (x) => x && typeof x === 'object' && !Array.isArray(x);
function merge(a, b) {
  if (!isObj(a) || !isObj(b)) return b;
  const o = { ...a };
  for (const [k, v] of Object.entries(b)) o[k] = k in a ? merge(a[k], v) : v;
  return o;
}
function setPath(obj, p, val) {
  const ks = p.split('.'); let o = obj;
  for (let i = 0; i < ks.length - 1; i++) { if (o[ks[i]] == null) throw new Error(`Ruta inexistente en $set: ${p}`); o = o[ks[i]]; }
  o[ks[ks.length - 1]] = val;
}

const B = JSON.parse(fs.readFileSync(base, 'utf8'));
const V = JSON.parse(fs.readFileSync(vars, 'utf8'));
fs.mkdirSync(outDir, { recursive: true });
V.forEach((v, i) => {
  const { $set, ...over } = v;
  const spec = merge(B, over);
  for (const [p, val] of Object.entries($set || {})) setPath(spec, p, val);
  spec.id = v.id || `${B.id || 'video'}-${String(i + 1).padStart(3, '0')}`;
  const f = path.join(outDir, spec.id + '.json');
  fs.writeFileSync(f, JSON.stringify(spec, null, 2) + '\n');
  console.log('  ' + f);
});
console.log(`${V.length} specs generados. Siguiente paso: node render.mjs --all ${outDir} <carpeta_salida>`);
