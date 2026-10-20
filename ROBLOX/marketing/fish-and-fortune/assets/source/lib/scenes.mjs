// Escenarios: cielo + lago al atardecer, muelle, pescadores (siluetas), rio, costa, libro del bestiario.
import { C, r1, starPath, sparkle, outlined } from './core.mjs';
import { fish, whale, fortu, waves, rays, rarityStars, shell, T } from './parts.mjs';

/** Pino estilizado (triangulos apilados). */
export function pine(x, y, s = 1, col = '#0B3A52', hi = '#1B6D80') {
  return `<g transform="translate(${x} ${y}) scale(${s})"><rect x="-6" y="-8" width="12" height="26" fill="#3E2A1A"/>
  ${[[0, 46, 74], [-34, 40, 66], [-66, 34, 56]].map(([yy, w, hh], i) => `<path d="M0 ${yy - hh}L${w} ${yy}L${-w} ${yy}Z" fill="${col}"/><path d="M0 ${yy - hh}L${w} ${yy}L${r1(w * 0.1)} ${yy}Z" fill="${hi}" opacity=".35"/>`).join('')}</g>`;
}

/** Cielo de atardecer + montanas + lago con reflejo. Devuelve el grupo (sin recorte). */
export function skyLake({ w, h, hz = 0.6, sunX = 0.5, uid = 's', pines = true, stars = true }) {
  const H = h * hz, sx = w * sunX;
  return `<g>
  <linearGradient id="sky_${uid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0A1F44"/><stop offset=".38" stop-color="#145C98"/><stop offset=".72" stop-color="#2FB3C4"/><stop offset="1" stop-color="#FFD58A"/></linearGradient>
  <linearGradient id="lake_${uid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5BC7CB"/><stop offset=".25" stop-color="#1C86B4"/><stop offset="1" stop-color="#0A2A55"/></linearGradient>
  <rect x="0" y="0" width="${w}" height="${r1(H + 2)}" fill="url(#sky_${uid})"/>
  <ellipse cx="${sx}" cy="${H}" rx="${r1(w * 0.55)}" ry="${r1(h * 0.36)}" fill="url(#gHalo)"/>
  ${stars ? Array.from({ length: 14 }, (_, i) => sparkle(r1(((i * 137) % 100) / 100 * w), r1(((i * 53) % 40) / 100 * H), 5 + (i % 3) * 3, C.foam, 0.8)).join('') : ''}
  <path d="M0 ${H} L0 ${r1(H - h * 0.1)} L${r1(w * 0.12)} ${r1(H - h * 0.17)} L${r1(w * 0.24)} ${r1(H - h * 0.09)} L${r1(w * 0.36)} ${r1(H - h * 0.14)} L${r1(w * 0.46)} ${r1(H - h * 0.04)} L${r1(w * 0.6)} ${r1(H - h * 0.13)} L${r1(w * 0.74)} ${r1(H - h * 0.18)} L${r1(w * 0.88)} ${r1(H - h * 0.09)} L${w} ${r1(H - h * 0.14)} L${w} ${H}Z" fill="#2C79A8" opacity=".75"/>
  <path d="M0 ${H} L0 ${r1(H - h * 0.05)} L${r1(w * 0.1)} ${r1(H - h * 0.1)} L${r1(w * 0.22)} ${r1(H - h * 0.05)} L${r1(w * 0.34)} ${r1(H - h * 0.085)} L${r1(w * 0.5)} ${r1(H - h * 0.02)} L${r1(w * 0.68)} ${r1(H - h * 0.07)} L${r1(w * 0.82)} ${r1(H - h * 0.11)} L${r1(w * 0.93)} ${r1(H - h * 0.05)} L${w} ${r1(H - h * 0.08)} L${w} ${H}Z" fill="#0F4673"/>
  ${pines ? [0.04, 0.09, 0.15, 0.2, 0.85, 0.91, 0.96].map((px, i) => pine(r1(w * px), r1(H + 2), (h / 1080) * (0.9 + (i % 3) * 0.28), '#0A3A55', '#1D7A8A')).join('') : ''}
  <rect x="0" y="${H}" width="${w}" height="${r1(h - H)}" fill="url(#lake_${uid})"/>
  <ellipse cx="${sx}" cy="${r1(H + h * 0.1)}" rx="${r1(w * 0.09)}" ry="${r1(h * 0.1)}" fill="${C.gold}" opacity=".45" filter="url(#fB10)"/>
  ${waves(r1(sx - w * 0.12), r1(H + h * 0.03), r1(w * 0.24), 4, '#FFE9A0', 0.55)}
  ${waves(r1(w * 0.05), r1(H + h * 0.12), r1(w * 0.28), 3, '#fff', 0.22)}
  ${waves(r1(w * 0.68), r1(H + h * 0.16), r1(w * 0.28), 3, '#fff', 0.2)}
  </g>`;
}

/** Agua frontal (para tapar la base de algo): ola con espuma desde yTop hasta abajo. */
export function waterFront({ x, y, w, h, uid = 'wf' }) {
  const n = Math.max(3, Math.round(w / 110));
  let top = `M${x} ${y}`;
  for (let i = 0; i < n; i++) top += `q${r1(w / n / 4)} -16 ${r1(w / n / 2)} 0t${r1(w / n / 2)} 0`;
  return `<g class="deco"><linearGradient id="${uid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3FB9D4" stop-opacity=".95"/><stop offset="1" stop-color="#0A3A6B"/></linearGradient>
  <path d="${top}L${x + w} ${y + h}L${x} ${y + h}Z" fill="url(#${uid})"/>
  <path d="${top}" stroke="#fff" stroke-opacity=".75" stroke-width="6" fill="none" stroke-linecap="round"/>
  ${waves(x + w * 0.1, y + 30, w * 0.3, 2, '#fff', 0.25)}${waves(x + w * 0.6, y + 46, w * 0.3, 2, '#fff', 0.2)}</g>`;
}

/** Salpicadura: gotas brillantes alrededor de (x,y). */
export function splash(x, y, R, n = 12, color = '#fff') {
  return `<g fill="${color}" opacity=".9">${Array.from({ length: n }, (_, i) => {
    const a = -Math.PI * (0.1 + (0.8 * i) / (n - 1)), d = R * (0.7 + ((i * 37) % 10) / 22);
    return `<ellipse cx="${r1(x + Math.cos(a) * d)}" cy="${r1(y + Math.sin(a) * d)}" rx="${r1(4 + (i % 3) * 2)}" ry="${r1(6 + (i % 3) * 2.5)}" transform="rotate(${r1((a * 180) / Math.PI + 90)} ${r1(x + Math.cos(a) * d)} ${r1(y + Math.sin(a) * d)})"/>`;
  }).join('')}</g>`;
}

/** Muelle de madera visto de lado. Cubierta superior en y, grosor, postes hacia el agua. Linterna opcional. */
export function dock({ x, y, w, thick = 34, posts = 4, lantern = [], uid = 'd' }) {
  const plankW = 78;
  const planks = Array.from({ length: Math.ceil(w / plankW) }, (_, i) => `<path d="M${x + i * plankW} ${y}V${y + thick}" stroke="#5E3818" stroke-opacity=".55" stroke-width="3"/>`).join('');
  const ps = Array.from({ length: posts }, (_, i) => {
    const px = x + (w / (posts - 1 || 1)) * i * 0.96 + 30;
    return `<rect x="${r1(px)}" y="${y + thick - 4}" width="30" height="${r1(130)}" rx="6" fill="url(#gWoodD)"/>`;
  }).join('');
  const lan = lantern.map((lx) => `<g><rect x="${lx - 6}" y="${y - 120}" width="12" height="120" rx="4" fill="#5E3818"/>
    <circle cx="${lx}" cy="${y - 140}" r="78" fill="url(#gHalo)"/>
    <rect x="${lx - 20}" y="${y - 168}" width="40" height="54" rx="12" fill="#FFE9A0" stroke="#7A4A1A" stroke-width="5"/>
    <path d="M${lx - 24} ${y - 168}H${lx + 24}L${lx} ${y - 190}Z" fill="#7A4A1A"/><rect x="${lx - 10}" y="${y - 160}" width="20" height="38" rx="8" fill="#fff" opacity=".8"/></g>`).join('');
  return `<g>${ps}
  <g filter="url(#fSh)"><rect x="${x}" y="${y}" width="${w}" height="${thick}" rx="8" fill="url(#gWood)" stroke="#5E3818" stroke-width="3"/></g>
  <path d="M${x} ${y + 6}H${x + w}" stroke="#F0C48E" stroke-opacity=".7" stroke-width="5"/>${planks}${lan}</g>`;
}

/** Pescador amable visto de espaldas/perfil, sin cara (chaqueta de color, gorro). pose: stand | sit.
 *  tip=[x,y] (coordenadas absolutas) fija la punta de la cana; bend curva la cana; lineTo=[x,y] dibuja el hilo hasta ese punto. */
export function fisher({ x, y, s = 1, shirt = C.coral, hat = C.teal, pose = 'stand', rodLen = 190, rodAng = -28, bend = 0, tip = null, lineTo = null }) {
  const sil = '#0C2850', rim = C.gold;
  const legs = pose === 'sit'
    ? `<path d="M-6 0q24 6 28 34v38M4 0q26 0 36 30v36" stroke="${sil}" stroke-width="16" fill="none" stroke-linecap="round"/>`
    : `<rect x="-17" y="-2" width="15" height="64" rx="7" fill="${sil}"/><rect x="3" y="-2" width="15" height="64" rx="7" fill="${sil}"/>`;
  const hx = 34, hy = -50;
  let tx, ty;
  if (tip) { tx = (tip[0] - x) / s; ty = (tip[1] - y) / s; } else { const ra = (rodAng * Math.PI) / 180; tx = hx + Math.cos(ra) * rodLen; ty = hy + Math.sin(ra) * rodLen; }
  const mx = (hx + tx) / 2, my = (hy + ty) / 2 - bend;
  const line = lineTo ? `<path d="M${r1(tx)} ${r1(ty)}Q${r1(tx + (lineTo[0] - x) / s * 0.15)} ${r1((ty + (lineTo[1] - y) / s) / 2)} ${r1((lineTo[0] - x) / s)} ${r1((lineTo[1] - y) / s)}" stroke="#fff" stroke-opacity=".85" stroke-width="2.6" fill="none"/>` : '';
  return `<g transform="${T(x, y, s)}">
  <g stroke="${rim}" stroke-opacity=".6" stroke-width="3">${legs}
    <rect x="-25" y="-72" width="50" height="80" rx="22" fill="${shirt}"/></g>
  <rect x="-25" y="-72" width="50" height="80" rx="22" fill="url(#gShade)"/>
  <path d="M-3 -54L${hx} ${hy}" stroke="${shirt}" stroke-width="14" stroke-linecap="round" fill="none"/><circle cx="${hx}" cy="${hy}" r="7.5" fill="#F2C7A0"/>
  <circle cx="0" cy="-94" r="22" fill="#2B2140" stroke="${rim}" stroke-opacity=".6" stroke-width="3"/>
  <path d="M-24 -98C-23 -128 23 -128 24 -98Z" fill="${hat}" stroke="#0A1F44" stroke-opacity=".55" stroke-width="2.5"/>
  <rect x="-28" y="-101" width="56" height="10" rx="5" fill="${hat}" stroke="#0A1F44" stroke-opacity=".55" stroke-width="2.5"/>
  <circle cx="0" cy="-128" r="8" fill="${C.foam}"/>
  <path d="M${hx} ${hy}Q${r1(mx)} ${r1(my)} ${r1(tx)} ${r1(ty)}" stroke="#4A2B12" stroke-width="6.5" fill="none" stroke-linecap="round"/>
  <path d="M${hx} ${hy}Q${r1(mx)} ${r1(my)} ${r1(tx)} ${r1(ty)}" stroke="#E2B27A" stroke-width="2.4" fill="none" stroke-linecap="round"/>
  ${line}
</g>`;
}

/** Escena de rio (zona 2): luz verde suave, rocas con musgo, puentecito. */
export function riverScene({ w, h, uid = 'rv' }) {
  const H = h * 0.5;
  return `<g>
  <linearGradient id="rs_${uid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2FA7A0"/><stop offset=".6" stop-color="#B7F0C9"/><stop offset="1" stop-color="#F3F7B8"/></linearGradient>
  <linearGradient id="rw_${uid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7DDDC0"/><stop offset=".4" stop-color="#1FA6A8"/><stop offset="1" stop-color="#0B5D7C"/></linearGradient>
  <rect width="${w}" height="${r1(H + 2)}" fill="url(#rs_${uid})"/>
  <ellipse cx="${r1(w * 0.7)}" cy="${r1(H * 0.7)}" rx="${r1(w * 0.5)}" ry="${r1(h * 0.28)}" fill="#FFF6B8" opacity=".55" filter="url(#fB24)"/>
  <path d="M0 ${H}L0 ${r1(H - h * 0.13)}Q${r1(w * 0.25)} ${r1(H - h * 0.26)} ${r1(w * 0.5)} ${r1(H - h * 0.12)}T${w} ${r1(H - h * 0.14)}L${w} ${H}Z" fill="#2F9E6A"/>
  <path d="M0 ${H}L0 ${r1(H - h * 0.05)}Q${r1(w * 0.3)} ${r1(H - h * 0.14)} ${r1(w * 0.6)} ${r1(H - h * 0.04)}T${w} ${r1(H - h * 0.07)}L${w} ${H}Z" fill="#1E7A52"/>
  ${[0.12, 0.3, 0.82].map((p, i) => pine(r1(w * p), r1(H - h * 0.03), (h / 760) * (0.8 + i * 0.15), '#1B6B4A', '#46B07F')).join('')}
  <rect y="${H}" width="${w}" height="${r1(h - H)}" fill="url(#rw_${uid})"/>
  ${waves(r1(w * 0.1), r1(H + h * 0.08), r1(w * 0.5), 3, '#fff', 0.3)}${waves(r1(w * 0.4), r1(H + h * 0.2), r1(w * 0.55), 3, '#fff', 0.22)}
  <g filter="url(#fShS)"><path d="M${r1(w * 0.1)} ${r1(H + 6)}Q${r1(w * 0.45)} ${r1(H - h * 0.14)} ${r1(w * 0.8)} ${r1(H + 6)}" stroke="#8A5224" stroke-width="20" fill="none" stroke-linecap="round"/>
  <path d="M${r1(w * 0.1)} ${r1(H + 6)}Q${r1(w * 0.45)} ${r1(H - h * 0.14)} ${r1(w * 0.8)} ${r1(H + 6)}" stroke="#D9985A" stroke-width="9" fill="none" stroke-linecap="round"/></g>
  ${[[0.22, 0.78, 1], [0.62, 0.86, 1.25], [0.82, 0.74, 0.8]].map(([px, py, sc]) => `<g transform="translate(${r1(w * px)} ${r1(h * py)}) scale(${sc * (h / 760)})" filter="url(#fShS)"><path d="M-80 30C-86 -20-40 -52 6 -46C52 -42 86 -10 82 30Z" fill="#7C8C93"/><path d="M-80 30C-86 -20-40 -52 6 -46C30 -44 50 -34 62 -20C20 -28-30 -10-80 30Z" fill="#46B07F"/><ellipse cx="-24" cy="-20" rx="30" ry="12" fill="#fff" opacity=".3"/></g>`).join('')}
  </g>`;
}

/** Escena de costa (zona 3): cielo calido coral, arena, conchas, olas. */
export function coastScene({ w, h, uid = 'co' }) {
  const H = h * 0.52;
  return `<g>
  <linearGradient id="cs_${uid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4FC3F7"/><stop offset=".55" stop-color="#FFC7A3"/><stop offset="1" stop-color="#FF9A72"/></linearGradient>
  <linearGradient id="cw_${uid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#53D3D0"/><stop offset="1" stop-color="#0F7CA6"/></linearGradient>
  <linearGradient id="sand_${uid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFE7B0"/><stop offset="1" stop-color="#EDB66C"/></linearGradient>
  <rect width="${w}" height="${r1(H + 2)}" fill="url(#cs_${uid})"/>
  <circle cx="${r1(w * 0.72)}" cy="${r1(H * 0.62)}" r="${r1(w * 0.2)}" fill="url(#gHalo)"/><circle cx="${r1(w * 0.72)}" cy="${r1(H * 0.62)}" r="${r1(w * 0.07)}" fill="#FFF1B8"/>
  <ellipse cx="${r1(w * 0.25)}" cy="${r1(H * 0.3)}" rx="${r1(w * 0.18)}" ry="${r1(h * 0.03)}" fill="#fff" opacity=".7"/><ellipse cx="${r1(w * 0.36)}" cy="${r1(H * 0.26)}" rx="${r1(w * 0.12)}" ry="${r1(h * 0.025)}" fill="#fff" opacity=".7"/>
  <rect y="${H}" width="${w}" height="${r1(h * 0.28)}" fill="url(#cw_${uid})"/>
  ${waves(r1(w * 0.05), r1(H + h * 0.05), r1(w * 0.5), 3, '#fff', 0.45)}${waves(r1(w * 0.5), r1(H + h * 0.12), r1(w * 0.45), 3, '#fff', 0.35)}
  <path d="M0 ${r1(H + h * 0.22)}Q${r1(w * 0.25)} ${r1(H + h * 0.15)} ${r1(w * 0.5)} ${r1(H + h * 0.22)}T${w} ${r1(H + h * 0.2)}L${w} ${h}L0 ${h}Z" fill="url(#sand_${uid})"/>
  <path d="M0 ${r1(H + h * 0.22)}Q${r1(w * 0.25)} ${r1(H + h * 0.15)} ${r1(w * 0.5)} ${r1(H + h * 0.22)}T${w} ${r1(H + h * 0.2)}" stroke="#fff" stroke-width="8" fill="none" opacity=".9"/>
  <g filter="url(#fShS)"><rect x="${r1(w * 0.52)}" y="${r1(H - h * 0.02)}" width="${r1(w * 0.44)}" height="14" rx="5" fill="url(#gWood)"/><rect x="${r1(w * 0.58)}" y="${r1(H - h * 0.02)}" width="12" height="${r1(h * 0.14)}" fill="#6B4020"/><rect x="${r1(w * 0.78)}" y="${r1(H - h * 0.02)}" width="12" height="${r1(h * 0.14)}" fill="#6B4020"/></g>
  ${shell({ x: w * 0.25, y: h * 0.86, s: (h / 760) * 0.8, rot: -12, tone: 'coral' })}${shell({ x: w * 0.68, y: h * 0.9, s: (h / 760) * 0.6, rot: 16, tone: 'pearl' })}${shell({ x: w * 0.46, y: h * 0.93, s: (h / 760) * 0.5, rot: 6 })}
  </g>`;
}

/** Libro del bestiario abierto con 6 casillas (5 criaturas + 1 silueta con "?"). Origen: centro del libro. Tamano ~ 1040 x 760. */
export function bestiaryBook({ uid = 'bk' } = {}) {
  const R = C.rar;
  const slots = [
    { col: R.common, n: 1, f: { top: '#8FA3B8', mid: '#C9D6E2', belly: '#F2F7FB', fin: '#7C93AB', h: 0.8, tail: 0.8 } },
    { col: R.uncommon, n: 2, f: { top: '#3FB9E8', mid: '#7CD9C0', belly: '#E8FBD8', fin: '#3CCB7F', h: 1.25, tail: 0.75, stripes: '#2F9E6A' } },
    { col: R.rare, n: 3, f: { top: '#FFB020', mid: '#FFD36B', belly: '#FFF0C0', fin: '#3FA2FF', h: 1.0, spots: '#8A5200' } },
    { col: R.epic, n: 4, f: { top: '#BFA3FF', mid: '#E5DAFF', belly: '#FFFFFF', fin: '#A66BFF', h: 1.1, tail: 1.2, glow: '#A66BFF', stripes: '#7F5BD8' } },
    { col: R.legendary, n: 5, f: { top: '#FFA81E', mid: '#FFD04A', belly: '#FFF3C4', fin: '#FF8A1E', h: 1.15, tail: 1.1, whisk: true, glow: '#FFB020', spots: '#B96A06' } },
    { col: R.mythic, n: 6, unknown: true },
  ];
  const sw = 252, sh = 226; // casilla
  const pos = (i) => {
    const page = i < 3 ? -1 : 1, row = i % 3;
    return [page * 176, -236 + row * 236];
  };
  const slotSvg = slots.map((sl, i) => {
    const [px, py] = pos(i);
    const clipId = `sc_${uid}_${i}`;
    const inner = sl.unknown
      ? `<g transform="translate(0 6)"><g filter="url(#fGlow)">${whale({ x: -6, y: 18, s: 0.34, uid: `bk${i}`, halo: false, sil: true })}</g>
         <text x="62" y="-22" text-anchor="middle" font-size="84" fill="${R.mythic}" stroke="#0A1F44" stroke-width="9" paint-order="stroke">?</text></g>`
      : fish({ x: 0, y: 2, s: 0.86, uid: `bk${i}`, ...sl.f });
    return `<g transform="translate(${px} ${py})">
    <g filter="url(#fShS)"><rect x="${-sw / 2}" y="${-sh / 2}" width="${sw}" height="${sh}" rx="28" fill="${sl.col}"/></g>
    <rect x="${-sw / 2 + 9}" y="${-sh / 2 + 9}" width="${sw - 18}" height="${sh - 18}" rx="21" fill="url(#bkIn_${uid})"/>
    <clipPath id="${clipId}"><rect x="${-sw / 2 + 9}" y="${-sh / 2 + 9}" width="${sw - 18}" height="${sh - 18}" rx="21"/></clipPath>
    <g clip-path="url(#${clipId})"><ellipse cx="0" cy="0" rx="120" ry="90" fill="${sl.col}" opacity=".28" filter="url(#fB24)"/>${inner}</g>
    <g>${rarityStars(0, r1(sh / 2 - 24), sl.n, sl.col, 11, 3)}</g>
  </g>`;
  }).join('');
  return `<g>
  <radialGradient id="bkIn_${uid}" cx=".5" cy=".4" r=".8"><stop offset="0" stop-color="#1B5C93"/><stop offset="1" stop-color="#0A2A55"/></radialGradient>
  <linearGradient id="bkCover_${uid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#11A4AD"/><stop offset="1" stop-color="#0A5F78"/></linearGradient>
  <g filter="url(#fSh)">
    <rect x="-352" y="-384" width="704" height="792" rx="34" fill="url(#bkCover_${uid})"/></g>
  <path d="M-336 -372Q-170 -390 0 -352L0 378Q-170 342 -336 362Z" fill="#F3E8C8"/>
  <path d="M-326 -362Q-170 -378 0 -342L0 366Q-170 330 -326 350Z" fill="#FFF8E4" stroke="#D9C79A" stroke-width="3"/>
  <path d="M336 -372Q170 -390 0 -352L0 378Q170 342 336 362Z" fill="#F3E8C8"/>
  <path d="M326 -362Q170 -378 0 -342L0 366Q170 330 326 350Z" fill="#FFF8E4" stroke="#D9C79A" stroke-width="3"/>
  <rect x="-16" y="-346" width="32" height="708" fill="url(#bkSp_${uid})"/>
  <linearGradient id="bkSp_${uid}" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C8B27C" stop-opacity="0"/><stop offset=".5" stop-color="#8F7A48" stop-opacity=".45"/><stop offset="1" stop-color="#C8B27C" stop-opacity="0"/></linearGradient>
  ${slotSvg}
</g>`;
}

export { sparkle, starPath };
