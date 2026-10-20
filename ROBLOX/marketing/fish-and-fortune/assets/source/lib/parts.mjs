// Piezas dibujadas: Fortu (mascota), criaturas, ballena Mitica, conchas, perlas, cana, boya, libro...
// Cada funcion devuelve un fragmento SVG; (x, y) es el centro, s la escala.
import { C, r1, starPath, sparkle } from './core.mjs';

const T = (x, y, s = 1, rot = 0, flip = false) =>
  `translate(${r1(x)} ${r1(y)}) rotate(${rot}) scale(${r1(flip ? -s : s)} ${r1(s)})`;

// ---------------------------------------------------------------------------------------------
// Fortu: pececillo dorado regordete con gorrito de punto teal, escama-estrella en la mejilla izquierda
// (a la derecha del espectador), ojos grandes oscuros con brillo, aletas coral. Centro del cuerpo = (0,0).
// ---------------------------------------------------------------------------------------------
export function fortu({ x = 0, y = 0, s = 1, rot = 0, flip = false, rod = false, uid = 'f' } = {}) {
  const fins = (side) => {
    // aleta pectoral redondeada coral con nervaduras
    const k = side; // -1 izquierda, +1 derecha
    return `<g transform="translate(0 38) scale(${k} 1)">
    <path d="M118 30C170 14 214 52 198 98C172 112 140 92 120 66Z" fill="url(#gCoral)" stroke="#D2472B" stroke-opacity=".55" stroke-width="3" stroke-linejoin="round"/>
    <path d="M132 52C158 50 178 62 190 88M126 62C148 68 166 80 176 100" stroke="#FFD0C2" stroke-opacity=".7" stroke-width="3.5" fill="none" stroke-linecap="round"/></g>`;
  };
  const scales = [];
  for (let r = 0; r < 3; r++) for (let c = -4; c <= 4; c++) {
    const cx = c * 36 + (r % 2) * 18, cy = 78 + r * 26;
    scales.push(`M${cx - 17} ${cy}Q${cx} ${cy + 24} ${cx + 17} ${cy}`);
  }
  const bodyClip = `bodyClip_${uid}`;
  return `<g transform="${T(x, y, s, rot, flip)}">
  ${rod ? `<g>
    <path d="M168 120L330 -250" stroke="#6B3E19" stroke-width="15" stroke-linecap="round"/>
    <path d="M168 120L330 -250" stroke="url(#gWood)" stroke-width="10" stroke-linecap="round"/>
    <path d="M176 100L196 54" stroke="#3E2410" stroke-width="22" stroke-linecap="round"/>
    <circle cx="298" cy="-176" r="5" fill="${C.gold}"/><circle cx="318" cy="-224" r="4" fill="${C.gold}"/>
  </g>` : ''}
  <!-- cola -->
  <g filter="url(#fShS)" transform="translate(-34 58) rotate(28 -70 92)"><path d="M-70 92C-118 70-168 30-208 36C-188 66-204 88-226 108C-198 118-192 142-180 166C-140 152-100 128-70 92Z" fill="url(#gCoral)" stroke="#D2472B" stroke-opacity=".55" stroke-width="3" stroke-linejoin="round"/>
  <path d="M-96 88C-130 72-166 56-196 52M-100 100C-134 108-160 124-176 148" stroke="#FFD0C2" stroke-opacity=".7" stroke-width="3.5" fill="none" stroke-linecap="round"/></g>
  <!-- aletas -->
  <g filter="url(#fShS)">${fins(-1)}</g>
  <!-- cuerpo -->
  <g filter="url(#fSh)"><ellipse cx="0" cy="8" rx="152" ry="140" fill="url(#gHoney)"/></g>
  <clipPath id="${bodyClip}"><ellipse cx="0" cy="8" rx="152" ry="140"/></clipPath>
  <g clip-path="url(#${bodyClip})">
    <ellipse cx="28" cy="160" rx="190" ry="84" fill="#DE7408" opacity=".38" filter="url(#fB10)"/>
    <ellipse cx="-4" cy="92" rx="96" ry="56" fill="#FFF6D2" opacity=".55" filter="url(#fB10)"/>
    <path d="${scales.join('')}" stroke="#D88A12" stroke-opacity=".5" stroke-width="4" fill="none" stroke-linecap="round"/>
    <ellipse cx="-70" cy="-62" rx="56" ry="26" transform="rotate(-32 -70 -62)" fill="#fff" opacity=".5" filter="url(#fB5)"/>
  </g>
  <ellipse cx="0" cy="8" rx="152" ry="140" fill="none" stroke="#C97C0C" stroke-opacity=".55" stroke-width="3"/>
  <!-- mejillas -->
  <ellipse cx="-98" cy="52" rx="23" ry="13" fill="${C.coral}" opacity=".5" filter="url(#fB2)"/>
  <ellipse cx="98" cy="52" rx="23" ry="13" fill="${C.coral}" opacity=".5" filter="url(#fB2)"/>
  <!-- ojos -->
  <g>
    <ellipse cx="-55" cy="-5" rx="30" ry="35" fill="#10182B"/><ellipse cx="55" cy="-5" rx="30" ry="35" fill="#10182B"/>
    <ellipse cx="-55" cy="12" rx="22" ry="16" fill="#2F4A7C" opacity=".55"/><ellipse cx="55" cy="12" rx="22" ry="16" fill="#2F4A7C" opacity=".55"/>
    <circle cx="-44" cy="-19" r="12" fill="#fff"/><circle cx="66" cy="-19" r="12" fill="#fff"/>
    <circle cx="-67" cy="10" r="5.5" fill="#fff" opacity=".92"/><circle cx="43" cy="10" r="5.5" fill="#fff" opacity=".92"/>
  </g>
  <!-- boca -->
  <path d="M-25 48Q0 74 25 48" stroke="#7A2E14" stroke-width="7.5" fill="none" stroke-linecap="round"/>
  <!-- gorrito de punto -->
  <g transform="translate(0 -128) rotate(-7)" filter="url(#fShS)">
    <path d="M-110 40C-122 -36-62 -82 0 -82C62 -82 122 -36 110 40Z" fill="url(#gTeal)" stroke="#087783" stroke-opacity=".6" stroke-width="3"/>
    ${[-4, -3, -2, -1, 0, 1, 2, 3, 4].map((i) => `<path d="M${i * 22} 34Q${i * 17} -20 ${i * 11} -78" stroke="#087783" stroke-opacity=".28" stroke-width="3.5" fill="none" stroke-linecap="round"/>`).join('')}
    <ellipse cx="-44" cy="-40" rx="34" ry="14" transform="rotate(-30 -44 -40)" fill="#fff" opacity=".38" filter="url(#fB5)"/>
    <rect x="-122" y="26" width="244" height="46" rx="22" fill="url(#gTeal)" stroke="#087783" stroke-opacity=".6" stroke-width="3"/>
    ${Array.from({ length: 14 }, (_, i) => -104 + i * 16).map((px) => `<path d="M${px} 34V64" stroke="#087783" stroke-opacity=".45" stroke-width="4.5" stroke-linecap="round"/>`).join('')}
    <circle cx="0" cy="-94" r="31" fill="url(#gPearl)" stroke="#9FB9CC" stroke-width="2.5"/>
    ${Array.from({ length: 9 }, (_, i) => `<circle cx="${r1(Math.cos((i * 2 * Math.PI) / 9) * 29)}" cy="${r1(-94 + Math.sin((i * 2 * Math.PI) / 9) * 29)}" r="8" fill="#F4FBFF" opacity=".9"/>`).join('')}
    <ellipse cx="-9" cy="-105" rx="12" ry="7" fill="#fff" opacity=".85" filter="url(#fB2)"/>
  </g>
  <!-- aleta derecha (sobre la cana si hay) -->
  <g filter="url(#fShS)">${fins(1)}</g>
  <!-- escama-estrella en la mejilla izquierda de Fortu (derecha del espectador) -->
  <path d="${starPath(104, 46, 21)}" fill="#FFF7D6" stroke="#E09A14" stroke-width="3.5" stroke-linejoin="round" filter="url(#fShS)"/>
  <path d="${starPath(104, 46, 11)}" fill="#fff" opacity=".7"/>
</g>`;
}

// ---------------------------------------------------------------------------------------------
// Pez generico (de lado, mira a la derecha). Para el bestiario y el pez que salta.
// ---------------------------------------------------------------------------------------------
export function fish({ x = 0, y = 0, s = 1, rot = 0, flip = false, top = '#9FB3C8', mid = '#CFDCE8', belly = '#F2F7FB', fin = '#7C93AB', h = 1, tail = 1, stripes = null, spots = null, glow = null, whisk = false, dorsal = true, outline = '#0A1F44', uid = 'z' }) {
  const H = 50 * h;
  const body = `M92 0C90 -${r1(H * 0.55)} 50 -${r1(H)} -4 -${r1(H * 0.92)}C-40 -${r1(H * 0.84)} -62 -${r1(H * 0.38)} -64 -10L-64 10C-62 ${r1(H * 0.38)} -40 ${r1(H * 0.84)} -4 ${r1(H * 0.92)}C50 ${r1(H)} 90 ${r1(H * 0.55)} 92 0Z`;
  const tl = 56 * tail, th = 46 * tail * (0.8 + h * 0.2);
  const tailP = `M-56 0C-74 -${r1(th * 0.2)} -86 -${r1(th * 0.7)} -${r1(56 + tl)} -${r1(th)}C-${r1(56 + tl * 0.55)} -${r1(th * 0.3)} -${r1(56 + tl * 0.55)} ${r1(th * 0.3)} -${r1(56 + tl)} ${r1(th)}C-86 ${r1(th * 0.7)} -74 ${r1(th * 0.2)} -56 0Z`;
  const clip = `fishClip_${uid}`;
  return `<g transform="${T(x, y, s, rot, flip)}">
   ${glow ? `<ellipse class="deco" cx="14" cy="0" rx="${r1(150 * (0.75 + h * 0.25))}" ry="${r1(H * 2.1)}" fill="${glow}" opacity=".35" filter="url(#fB24)"/>` : ''}
  <g filter="url(#fShS)">
  <path d="${tailP}" fill="${fin}" stroke="${outline}" stroke-opacity=".55" stroke-width="3.5" stroke-linejoin="round"/>
  ${dorsal ? `<path d="M-30 -${r1(H * 0.86)}C-18 -${r1(H * 1.5)} 24 -${r1(H * 1.5)} 40 -${r1(H * 0.92)}C20 -${r1(H * 0.86)} -10 -${r1(H * 0.84)} -30 -${r1(H * 0.86)}Z" fill="${fin}" stroke="${outline}" stroke-opacity=".55" stroke-width="3.5" stroke-linejoin="round"/>` : ''}
  <path d="${body}" fill="url(#fishG_${uid})" stroke="${outline}" stroke-opacity=".6" stroke-width="4" stroke-linejoin="round"/></g>
  <linearGradient id="fishG_${uid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${top}"/><stop offset=".55" stop-color="${mid}"/><stop offset="1" stop-color="${belly}"/></linearGradient>
  <clipPath id="${clip}"><path d="${body}"/></clipPath>
  <g clip-path="url(#${clip})">
    ${stripes ? [-40, -16, 8, 32].map((px) => `<path d="M${px} -70Q${px + 14} 0 ${px} 70" stroke="${stripes}" stroke-width="9" fill="none" opacity=".7"/>`).join('') : ''}
    ${spots ? [[-30, -18], [-4, -26], [22, -14], [-44, 4], [-14, -4], [10, 6], [34, 4], [-26, 20]].map(([a, b], i) => `<circle cx="${a}" cy="${b * h}" r="${i % 2 ? 4.5 : 3.2}" fill="${spots}" opacity=".9"/>`).join('') : ''}
    <ellipse cx="14" cy="-${r1(H * 0.52)}" rx="62" ry="${r1(H * 0.2)}" fill="#fff" opacity=".42" filter="url(#fB5)"/>
  </g>
  <path d="M40 -${r1(H * 0.7)}Q58 0 40 ${r1(H * 0.7)}" stroke="${outline}" stroke-opacity=".35" stroke-width="3.5" fill="none" stroke-linecap="round"/>
  <circle cx="64" cy="-9" r="11.5" fill="#10182B"/><circle cx="68" cy="-13" r="4.6" fill="#fff"/><circle cx="60" cy="-4" r="2.2" fill="#fff" opacity=".9"/>
  <path d="M82 9Q88 13 94 8" stroke="${outline}" stroke-width="3.5" fill="none" stroke-linecap="round"/>
  ${whisk ? `<path d="M90 6C108 12 112 30 102 44M88 12C104 24 100 40 88 52" stroke="${fin}" stroke-width="4" fill="none" stroke-linecap="round"/>` : ''}
</g>`;
}

// ---------------------------------------------------------------------------------------------
// Ballena-espiritu del lago (Mitico). Mira a la izquierda. Origen en el centro del cuerpo.
// ---------------------------------------------------------------------------------------------
export function whale({ x = 0, y = 0, s = 1, rot = 0, flip = false, uid = 'w', halo = true, sil = false }) {
  const body = 'M-290 24C-296 -72 -228 -142 -130 -152C-20 -164 92 -142 168 -86C204 -58 232 -42 256 -64L270 -40C246 -6 220 2 196 12C150 36 96 74 26 104C-52 136 -140 132 -208 108C-262 90 -288 62 -290 24Z';
  const fluke = 'M256 -64C246 -108 262 -150 300 -178C312 -150 308 -128 286 -108C306 -118 332 -116 356 -96C330 -76 300 -62 270 -40Z';
  const clip = `whaleClip_${uid}`;
  if (sil) return `<g transform="${T(x, y, s, rot, flip)}"><path d="${fluke}" fill="#102A57" stroke="#FF4FB8" stroke-width="12" stroke-linejoin="round"/><path d="${body}" fill="#102A57" stroke="#FF4FB8" stroke-width="12" stroke-linejoin="round"/><path d="${fluke}" fill="#102A57"/><path d="${body}" fill="#102A57"/></g>`;
  const dots = [[-210, -86, 6], [-170, -118, 8], [-120, -134, 5], [-70, -140, 9], [-20, -140, 6], [34, -132, 8], [86, -116, 5], [136, -90, 7], [-236, -54, 5], [-96, -104, 4], [10, -112, 4], [70, -92, 4]];
  return `<g transform="${T(x, y, s, rot, flip)}">
  ${halo ? `<ellipse cx="0" cy="-10" rx="430" ry="300" fill="url(#gHaloM)"/><ellipse cx="-10" cy="-30" rx="330" ry="230" fill="url(#gHalo)" opacity=".6"/>` : ''}
  <g filter="url(#fSh)">
    <path d="${fluke}" fill="url(#whG_${uid})" stroke="#3B1D8F" stroke-opacity=".6" stroke-width="4" stroke-linejoin="round"/>
    <path d="${body}" fill="url(#whG_${uid})" stroke="#3B1D8F" stroke-opacity=".6" stroke-width="4.5" stroke-linejoin="round"/>
  </g>
  <linearGradient id="whG_${uid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8F6BFF"/><stop offset=".5" stop-color="#4E8FF0"/><stop offset="1" stop-color="#45D2E6"/></linearGradient>
  <clipPath id="${clip}"><path d="${body}"/></clipPath>
  <g clip-path="url(#${clip})">
    <!-- vientre claro con surcos -->
    <path d="M-290 50C-240 70-150 72-70 62C-10 54 60 40 150 -10L290 40L290 200L-300 200Z" fill="#CFF6FF" opacity=".92"/>
    ${[78, 94, 110].map((yy, i) => `<path d="M-250 ${yy - 6}C-170 ${yy + 12} -90 ${yy + 6} -20 ${yy - 6}C40 ${yy - 14} 90 ${yy - 30} 130 ${yy - 50 + i * 4}" stroke="#7EC9E3" stroke-width="3.5" fill="none" opacity=".7" stroke-linecap="round"/>`).join('')}
    <ellipse cx="-120" cy="-118" rx="120" ry="26" transform="rotate(-10 -120 -118)" fill="#fff" opacity=".4" filter="url(#fB10)"/>
  </g>
  <!-- patrones bioluminiscentes -->
  <g filter="url(#fGlow)">
    <path d="M-186 -96C-130 -128 -40 -134 40 -112C90 -98 126 -78 160 -52" stroke="${C.gold}" stroke-width="6" fill="none" stroke-linecap="round" stroke-dasharray="2 16"/>
    <path d="M-60 -60C-30 -84 10 -86 36 -66" stroke="${C.teal}" stroke-width="6" fill="none" stroke-linecap="round"/>
    <path d="M44 -60C70 -80 104 -74 120 -52" stroke="#FF4FB8" stroke-width="6" fill="none" stroke-linecap="round"/>
    ${dots.map(([a, b, r], i) => `<circle cx="${a}" cy="${b}" r="${r}" fill="${i % 3 === 0 ? C.gold : i % 3 === 1 ? '#8CF5F2' : '#FFE0F3'}"/>`).join('')}
    <path d="M-236 -22c14 6 28 6 40 0" stroke="${C.gold}" stroke-width="5" fill="none" stroke-linecap="round"/>
  </g>
  <!-- cara amable -->
  <circle cx="-186" cy="-4" r="25" fill="#10182B"/><circle cx="-177" cy="-14" r="9.5" fill="#fff"/><circle cx="-196" cy="8" r="4.5" fill="#fff" opacity=".9"/>
  <path d="M-282 36C-246 70-196 78-150 62" stroke="#2A1768" stroke-width="6" fill="none" stroke-linecap="round"/>
  <ellipse cx="-142" cy="34" rx="22" ry="12" fill="#FF4FB8" opacity=".5" filter="url(#fB2)"/>
  <!-- aleta pectoral -->
  <path d="M-86 92C-46 76 8 84 36 126C-10 146 -62 132 -86 92Z" fill="#6F8DF3" stroke="#3B1D8F" stroke-opacity=".5" stroke-width="3.5" stroke-linejoin="round"/>
</g>`;
}

// ---------------------------------------------------------------------------------------------
// Concha tipo vieira (abanico con costillas): "moneda" propia del juego SIN usar monedas.
// ---------------------------------------------------------------------------------------------
export function shell({ x = 0, y = 0, s = 1, rot = 0, tone = 'gold', shadow = true } = {}) {
  const tones = {
    gold: ['#FFE08A', '#FFC83D', '#C98308', '#8A5200'],
    coral: ['#FFC0AE', '#FF7A59', '#C8472B', '#7F2A16'],
    teal: ['#8FF3F0', '#19C3C0', '#0B8591', '#065560'],
    pearl: ['#FFFFFF', '#E8F1F8', '#AFC6DA', '#6E8AA5'],
  }[tone];
  const n = 7, R = 74, a0 = -76, span = 152;
  const wedges = [];
  for (let i = 0; i < n; i++) {
    const a = ((a0 + (i * span) / n) * Math.PI) / 180, b = ((a0 + ((i + 1) * span) / n) * Math.PI) / 180;
    const p = (ang, rr) => `${r1(rr * Math.sin(ang))} ${r1(-rr * Math.cos(ang))}`;
    wedges.push(`<path d="M0 0L${p(a, R)}A${R} ${R} 0 0 1 ${p(b, R)}Z" fill="${i % 2 ? tones[1] : tones[0]}" stroke="${tones[2]}" stroke-width="3" stroke-linejoin="round"/>`);
  }
  return `<g transform="${T(x, y, s, rot)}" ${shadow ? 'filter="url(#fShS)"' : ''}>
  <g transform="translate(0 16)">${wedges.join('')}
  <path d="M-30 -2Q0 -18 30 -2L22 18Q0 28 -22 18Z" fill="${tones[1]}" stroke="${tones[2]}" stroke-width="3" stroke-linejoin="round" transform="translate(0 4)"/>
  <path d="M-36 -48Q-8 -66 22 -62" stroke="#fff" stroke-opacity=".6" stroke-width="7" fill="none" stroke-linecap="round"/></g>
</g>`;
}

export function pearl({ x = 0, y = 0, r = 30, tint = '#FFE9F4' } = {}) {
  const id = `pg_${Math.round(x)}_${Math.round(y)}_${Math.round(r)}`;
  return `<g filter="url(#fShS)"><radialGradient id="${id}" cx=".34" cy=".3" r=".85"><stop offset="0" stop-color="#FFFFFF"/><stop offset=".45" stop-color="#F6EAF6"/><stop offset=".8" stop-color="#C9B5E3"/><stop offset="1" stop-color="#8FA7D6"/></radialGradient>
  <circle cx="${x}" cy="${y}" r="${r}" fill="url(#${id})" stroke="#5C6FA8" stroke-opacity=".7" stroke-width="3"/>
  <ellipse cx="${r1(x + r * 0.28)}" cy="${r1(y + r * 0.5)}" rx="${r1(r * 0.5)}" ry="${r1(r * 0.28)}" fill="#7FE6E6" opacity=".35" filter="url(#fB5)"/>
  <ellipse cx="${r1(x - r * 0.34)}" cy="${r1(y - r * 0.4)}" rx="${r1(r * 0.3)}" ry="${r1(r * 0.2)}" transform="rotate(-30 ${r1(x - r * 0.34)} ${r1(y - r * 0.4)})" fill="#fff" opacity=".95"/></g>`;
}

/** Boya (flotador) coral y blanca. */
export function bobber({ x = 0, y = 0, s = 1 } = {}) {
  return `<g transform="${T(x, y, s)}" filter="url(#fShS)">
  <clipPath id="bobClip"><circle cx="0" cy="0" r="30"/></clipPath>
  <circle cx="0" cy="0" r="30" fill="${C.foam}"/>
  <g clip-path="url(#bobClip)"><rect x="-32" y="-32" width="64" height="38" fill="url(#gCoral)"/><ellipse cx="-10" cy="-16" rx="12" ry="7" fill="#fff" opacity=".5" transform="rotate(-25 -10 -16)"/></g>
  <circle cx="0" cy="0" r="30" fill="none" stroke="${C.navy}" stroke-opacity=".6" stroke-width="3.5"/>
  <rect x="-3.5" y="-44" width="7" height="16" rx="3" fill="${C.navy}" opacity=".85"/><circle cx="0" cy="-46" r="4.5" fill="${C.gold}"/></g>`;
}

/** Cana de pescar de (x1,y1) a (x2,y2): mango, anillas doradas. */
export function rod({ x1, y1, x2, y2, w = 14, reel = true }) {
  const dx = x2 - x1, dy = y2 - y1, L = Math.hypot(dx, dy);
  const ang = (Math.atan2(dy, dx) * 180) / Math.PI;
  const guides = [0.35, 0.55, 0.72, 0.88].map((t) => `<circle cx="${r1(L * t)}" cy="${r1(-w * 0.7 * (1 - t) - 3)}" r="${r1(w * 0.42)}" fill="none" stroke="${C.gold}" stroke-width="3"/>`).join('');
  return `<g transform="translate(${r1(x1)} ${r1(y1)}) rotate(${r1(ang)})" filter="url(#fShS)">
  <path d="M0 ${-w / 2}L${r1(L)} ${-w * 0.14}L${r1(L)} ${w * 0.14}L0 ${w / 2}Z" fill="url(#gWood)" stroke="#5E3818" stroke-width="2.5" stroke-linejoin="round"/>
  <path d="M-2 ${-w * 0.7}H${r1(L * 0.22)}V${w * 0.7}H-2Z" fill="#E7C9A0" stroke="#8A5224" stroke-width="2.5" stroke-linejoin="round" rx="6"/>
  ${[0.05, 0.11, 0.17].map((t) => `<path d="M${r1(L * t)} ${-w * 0.7}V${w * 0.7}" stroke="#B07A3E" stroke-width="2"/>`).join('')}
  ${guides}
  ${reel ? `<g transform="translate(${r1(L * 0.3)} ${r1(w * 1.5)})"><circle r="${r1(w * 1.15)}" fill="url(#gGold)" stroke="#A56A06" stroke-width="3"/><circle r="${r1(w * 0.45)}" fill="#A56A06"/><rect x="-3" y="${-w * 1.9}" width="6" height="${r1(w * 0.8)}" fill="#A56A06"/></g>` : ''}
  </g>`;
}

/** Olas pequenas (curvas) para colocar sobre el agua. */
export function waves(x, y, w, n = 3, color = '#fff', op = 0.5) {
  return Array.from({ length: n }, (_, i) => {
    const yy = y + i * 16, ww = w * (1 - i * 0.18), xx = x + (w - ww) / 2;
    return `<path d="M${r1(xx)} ${yy}q${r1(ww / 8)} -9 ${r1(ww / 4)} 0t${r1(ww / 4)} 0t${r1(ww / 4)} 0t${r1(ww / 4)} 0" stroke="${color}" stroke-opacity="${op}" stroke-width="4" fill="none" stroke-linecap="round"/>`;
  }).join('');
}

/** Rayos de sol radiales (fondo). */
export function rays(cx, cy, len, n = 14, op = 0.12, color = C.gold) {
  return `<g opacity="${op}">${Array.from({ length: n }, (_, i) => {
    const a = (i * 2 * Math.PI) / n, b = a + Math.PI / n * 0.8;
    return `<path d="M${cx} ${cy}L${r1(cx + len * Math.cos(a))} ${r1(cy + len * Math.sin(a))}L${r1(cx + len * Math.cos(b))} ${r1(cy + len * Math.sin(b))}Z" fill="${color}"/>`;
  }).join('')}</g>`;
}

/** Estrellas de rareza (n estrellas de color). */
export function rarityStars(cx, cy, n, color, size = 11, gap = 4) {
  const total = n * size * 2 + (n - 1) * gap;
  const x0 = cx - total / 2 + size;
  return Array.from({ length: n }, (_, i) => `<path d="${starPath(r1(x0 + i * (size * 2 + gap)), cy, size)}" fill="${color}" stroke="#0A1F44" stroke-width="2.2" stroke-linejoin="round"/>`).join('');
}

export { sparkle, starPath, T };
