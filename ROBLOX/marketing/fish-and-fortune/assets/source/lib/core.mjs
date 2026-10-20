// Nucleo compartido: paleta del brand kit, <defs> (degradados y filtros), helpers de dibujo y texto.
// Todo el arte es codigo: SVG generado con plantillas de texto. Sin imagenes externas ni IA.

/** Paleta oficial (ROBLOX/marketing/fish-and-fortune/prompts-ia.md, seccion 1.3). */
export const C = {
  navy: '#0A1F44', // Azul Abismo
  ocean: '#0F6E9E', // Azul Oceano
  teal: '#19C3C0', // Teal Laguna
  gold: '#FFC83D', // Oro Sol (acento de marca)
  coral: '#FF7A59', // Coral
  foam: '#F4FBFF', // Espuma (texto claro)
  ink: '#10182B', // Tinta (texto oscuro)
  alga: '#3CCB7F', // Exito
  rar: { common: '#9FB3C8', uncommon: '#4CD38A', rare: '#3FA2FF', epic: '#A66BFF', legendary: '#FFB020', mythic: '#FF4FB8' },
};

// Rutas relativas a source/svg y source/build (ambas a la misma profundidad que source/html).
const FONT_DIR = '../../../specs-video/fonts';

/** Degradados y filtros reutilizables. Cada documento SVG incluye este bloque una sola vez. */
export const DEFS = `<defs>
<linearGradient id="gGold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFEFB0"/><stop offset=".45" stop-color="#FFC83D"/><stop offset="1" stop-color="#E08F0E"/></linearGradient>
<linearGradient id="gGoldD" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFD25F"/><stop offset=".5" stop-color="#F0A81C"/><stop offset="1" stop-color="#B96A06"/></linearGradient>
<linearGradient id="gTeal" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6BEDEA"/><stop offset=".5" stop-color="#19C3C0"/><stop offset="1" stop-color="#0B8591"/></linearGradient>
<linearGradient id="gCoral" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFB39B"/><stop offset=".5" stop-color="#FF7A59"/><stop offset="1" stop-color="#DE4F33"/></linearGradient>
<linearGradient id="gWood" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#D9985A"/><stop offset=".5" stop-color="#B27236"/><stop offset="1" stop-color="#8A5224"/></linearGradient>
<linearGradient id="gWoodD" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A86B34"/><stop offset="1" stop-color="#5E3818"/></linearGradient>
<linearGradient id="gOcean" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2CA2D4"/><stop offset="1" stop-color="#0F6E9E"/></linearGradient>
<linearGradient id="gGlass" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E8FBFF" stop-opacity=".85"/><stop offset="1" stop-color="#8FD9E8" stop-opacity=".55"/></linearGradient>
<linearGradient id="gShade" x1="0" y1="0" x2="0" y2="1"><stop offset=".5" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#04101F" stop-opacity=".35"/></linearGradient>
<radialGradient id="gHoney" cx=".35" cy=".3" r=".85"><stop offset="0" stop-color="#FFF2BE"/><stop offset=".5" stop-color="#FFC83D"/><stop offset="1" stop-color="#EE9418"/></radialGradient>
<radialGradient id="gPearl" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#FFFFFF"/><stop offset=".55" stop-color="#E7F2F9"/><stop offset="1" stop-color="#A9C7DE"/></radialGradient>
<radialGradient id="gHalo" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#FFE9A0" stop-opacity=".95"/><stop offset=".5" stop-color="#FFC83D" stop-opacity=".4"/><stop offset="1" stop-color="#FFC83D" stop-opacity="0"/></radialGradient>
<radialGradient id="gHaloM" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#FF4FB8" stop-opacity=".75"/><stop offset=".55" stop-color="#A66BFF" stop-opacity=".3"/><stop offset="1" stop-color="#A66BFF" stop-opacity="0"/></radialGradient>
<radialGradient id="gHaloT" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#8CF5F2" stop-opacity=".85"/><stop offset="1" stop-color="#19C3C0" stop-opacity="0"/></radialGradient>
<filter id="fSh" x="-30%" y="-30%" width="160%" height="170%"><feDropShadow dx="0" dy="9" stdDeviation="7" flood-color="#04101F" flood-opacity=".42"/></filter>
<filter id="fShS" x="-30%" y="-30%" width="160%" height="170%"><feDropShadow dx="0" dy="4" stdDeviation="3.2" flood-color="#04101F" flood-opacity=".38"/></filter>
<filter id="fB2" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="2"/></filter>
<filter id="fB5" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="5"/></filter>
<filter id="fB10" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="10"/></filter>
<filter id="fB24" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="24"/></filter>
<filter id="fGlow" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="6" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
</defs>`;

/** Envuelve un cuerpo en un documento SVG independiente (abre bien en un navegador). */
export function svgDoc({ w, h, body, title }) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}" role="img" aria-label="${esc(title)}">
<title>${esc(title)}</title>
<style>
@font-face{font-family:'Fredoka';src:url('${FONT_DIR}/Fredoka.ttf') format('truetype');font-weight:300 700;}
@font-face{font-family:'Nunito';src:url('${FONT_DIR}/Nunito.ttf') format('truetype');font-weight:200 1000;}
text{font-family:'Fredoka','Nunito',sans-serif;font-weight:700;}
</style>
${DEFS}
${body}
</svg>`;
}

export function esc(s) {
  return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

export const r1 = (n) => Math.round(n * 10) / 10;

/** Estrella de 5 puntas (se usa en la escama de Fortu y en el marcador de rareza). */
export function starPath(cx, cy, R, ratio = 0.46) {
  const pts = [];
  for (let i = 0; i < 10; i++) {
    const a = -Math.PI / 2 + (i * Math.PI) / 5;
    const rr = i % 2 === 0 ? R : R * ratio;
    pts.push(`${r1(cx + rr * Math.cos(a))},${r1(cy + rr * Math.sin(a))}`);
  }
  return `M${pts.join('L')}Z`;
}

/** Destello de 4 puntas. */
export function sparkle(x, y, s = 20, fill = C.foam, op = 1) {
  const p = `M0 ${-s}Q${s * 0.12} ${-s * 0.12} ${s} 0Q${s * 0.12} ${s * 0.12} 0 ${s}Q${-s * 0.12} ${s * 0.12} ${-s} 0Q${-s * 0.12} ${-s * 0.12} 0 ${-s}Z`;
  return `<path transform="translate(${x} ${y})" d="${p}" fill="${fill}" opacity="${op}" filter="url(#fGlow)"/>`;
}

/** Texto con contorno oscuro (legible sobre cualquier fondo). */
export function outlined(text, { x, y, size, fill = C.foam, stroke = C.navy, sw, anchor = 'start', cls = 't', extra = '', id = '' }) {
  const w = sw ?? Math.max(4, Math.round(size * 0.14));
  return `<text ${id ? `id="${id}" ` : ''}class="${cls}" data-contrast="${fill}" x="${x}" y="${y}" font-size="${size}" text-anchor="${anchor}" fill="${fill}" stroke="${stroke}" stroke-width="${w}" stroke-linejoin="round" paint-order="stroke" ${extra}>${esc(text)}</text>`;
}

// Posicion horizontal del centro de la "&" en "Fish & Fortune" (Fredoka 700), como fraccion del tamano de fuente.
// Medida con Chromium (ver README): inicio del texto -> centro de "&".
export const AMP = { cx: 2.447, width: 6.64 }; // medido con Chromium (Fredoka 700, 100 px): centro de la "&" y ancho total, en em

/** Logotipo (wordmark) "Fish & Fortune": "&" en Oro Sol, resto en Espuma, contorno Azul Abismo y un pez dorado nadando por la "&". */
export function wordmark({ x, y, size, anchor = 'start', fish = true }) {
  const total = AMP.width * size;
  const x0 = anchor === 'middle' ? x - total / 2 : anchor === 'end' ? x - total : x;
  const sw = Math.round(size * 0.16);
  const ampX = x0 + AMP.cx * size;
  const t = `<text class="t wm" data-contrast="${C.foam}" x="${x0}" y="${y}" font-size="${size}" text-anchor="start" fill="${C.foam}" stroke="${C.navy}" stroke-width="${sw}" stroke-linejoin="round" paint-order="stroke">Fish <tspan fill="${C.gold}">&amp;</tspan> Fortune</text>`;
  // pez minusculo que cruza la "&": cuerpo dorado, cola, ojo
  const fs = size / 100;
  const f = fish
    ? `<g transform="translate(${r1(ampX + size * 0.04)} ${r1(y - size * 1.0)}) rotate(-22) scale(${r1(fs * 0.46)})" filter="url(#fShS)">
  <path d="M-34 0C-60 -22 -66 -26 -70 -30C-66 -10 -66 10 -70 30C-66 26 -60 22 -34 0Z" fill="${C.coral}" stroke="${C.navy}" stroke-width="5" stroke-linejoin="round"/>
  <path d="M-38 0C-30 -28 10 -36 40 -22C58 -12 62 8 40 22C10 36 -30 28 -38 0Z" fill="url(#gHoney)" stroke="${C.navy}" stroke-width="5" stroke-linejoin="round"/>
  <circle cx="30" cy="-6" r="7" fill="${C.navy}"/><circle cx="32" cy="-9" r="2.6" fill="#fff"/>
  <path d="M42 8Q48 12 54 8" stroke="${C.navy}" stroke-width="4" fill="none" stroke-linecap="round"/></g>`
    : '';
  return `<g class="wordmark">${t}${f}</g>`;
}
