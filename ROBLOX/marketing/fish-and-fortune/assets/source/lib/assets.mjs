// Manifiesto de piezas: cada entrada define archivo de salida, tamano, clave de ProductIds.luau y como se dibuja.
// El texto es minimo (regla de contenido): los iconos de pases/productos solo llevan "x2" y "VIP"; el icono del juego no lleva texto.
import { C, r1, starPath, sparkle, outlined, wordmark, esc } from './core.mjs';
import { fortu, fish, whale, shell, pearl, bobber, rod, waves, rays, T } from './parts.mjs';
import { skyLake, waterFront, splash, dock, fisher, riverScene, coastScene, bestiaryBook, pine } from './scenes.mjs';

// ---------------------------------------------------------------------------------------------
// Marco comun de iconos 512x512: fondo continuo en las 4 esquinas (<g id="bg">) y sujeto dentro del circulo seguro (<g id="subject">).
// ---------------------------------------------------------------------------------------------
const SAFE_R = 230; // circulo seguro: diametro 460 (90 %) centrado en 512x512
function iconFrame({ a = '#1C8FC0', b = '#0A1F44', glow = C.gold, bgExtra = '', subject, ring = true, uid }) {
  return `<g id="bg">
  <radialGradient id="ibg_${uid}" cx=".5" cy=".42" r=".78"><stop offset="0" stop-color="${a}"/><stop offset="1" stop-color="${b}"/></radialGradient>
  <rect width="512" height="512" fill="url(#ibg_${uid})"/>
  ${rays(256, 236, 420, 16, 0.1, '#fff')}
  <circle cx="256" cy="246" r="190" fill="${glow}" opacity=".16" filter="url(#fB24)"/>
  ${bgExtra}
  ${ring ? `<circle cx="256" cy="256" r="${SAFE_R - 10}" fill="none" stroke="${C.gold}" stroke-opacity=".55" stroke-width="6"/>` : ''}
  <radialGradient id="vig_${uid}" cx=".5" cy=".5" r=".72"><stop offset=".72" stop-color="#04101F" stop-opacity="0"/><stop offset="1" stop-color="#04101F" stop-opacity=".55"/></radialGradient>
  <rect width="512" height="512" fill="url(#vig_${uid})"/>
</g>
<g id="subject">${subject}</g>`;
}

function arcArrow(cx, cy, R, a0, a1, w, color, stroke = C.navy) {
  const P = (a, rr = R) => [cx + rr * Math.cos((a * Math.PI) / 180), cy + rr * Math.sin((a * Math.PI) / 180)];
  const [x0, y0] = P(a0), [x1, y1] = P(a1);
  const t = [-Math.sin((a1 * Math.PI) / 180), Math.cos((a1 * Math.PI) / 180)], n = [Math.cos((a1 * Math.PI) / 180), Math.sin((a1 * Math.PI) / 180)];
  const hw = w * 0.95, L = w * 1.15;
  const head = `M${r1(x1 + n[0] * hw)} ${r1(y1 + n[1] * hw)}L${r1(x1 + t[0] * L)} ${r1(y1 + t[1] * L)}L${r1(x1 - n[0] * hw)} ${r1(y1 - n[1] * hw)}Z`;
  const arc = `M${r1(x0)} ${r1(y0)}A${R} ${R} 0 0 1 ${r1(x1)} ${r1(y1)}`;
  return `<g stroke-linejoin="round" stroke-linecap="round"><path d="${arc}" stroke="${stroke}" stroke-width="${w + 12}" fill="none"/><path d="${head}" fill="${stroke}" stroke="${stroke}" stroke-width="12"/>
  <path d="${arc}" stroke="${color}" stroke-width="${w}" fill="none"/><path d="${head}" fill="${color}"/></g>`;
}

const goldText = (t, o) => `<text x="${o.x}" y="${o.y}" font-size="${o.size}" text-anchor="middle" fill="url(#gGold)" stroke="${C.navy}" stroke-width="${o.sw ?? 20}" stroke-linejoin="round" paint-order="stroke" class="t" data-contrast="${C.gold}">${esc(t)}</text>`;

// ---------------------------------------------------------------------------------------------
// Pases y productos (512x512, contenido dentro del circulo seguro)
// ---------------------------------------------------------------------------------------------
const PASSES = {
  auto_fish: () => iconFrame({
    uid: 'af', a: '#1FA5D2', b: '#0A1F44', glow: C.teal,
    subject: `${arcArrow(256, 258, 142, 205, 335, 30, C.gold)}${arcArrow(256, 258, 142, 25, 155, 30, C.gold)}
    ${rod({ x1: 168, y1: 376, x2: 350, y2: 150, w: 22 })}
    <path d="M346 152Q372 230 340 300" stroke="#fff" stroke-opacity=".9" stroke-width="3" fill="none" stroke-linecap="round"/>
    ${waves(296, 330, 90, 2, '#fff', 0.75)}${bobber({ x: 340, y: 304, s: 1.05 })}
    ${sparkle(150, 160, 16, C.foam)}${sparkle(380, 400, 12, C.foam)}`,
  }),
  double_coins: () => iconFrame({
    uid: 'dc', a: '#1FB6B8', b: '#0A1F44', glow: C.gold,
    subject: `${shell({ x: 142, y: 170, s: 0.9, rot: -18 })}${shell({ x: 384, y: 150, s: 0.65, rot: 14, tone: 'coral' })}${shell({ x: 366, y: 366, s: 0.9, rot: 10 })}${shell({ x: 146, y: 372, s: 0.62, rot: -10, tone: 'teal' })}
    ${goldText('x2', { x: 256, y: 336, size: 250 })}
    ${sparkle(250, 118, 20)}${sparkle(98, 270, 12)}${sparkle(430, 250, 14)}`,
  }),
  starter: () => iconFrame({
    uid: 'st', a: '#1C9BC4', b: '#0A1F44', glow: C.teal,
    subject: `${rod({ x1: 330, y1: 262, x2: 426, y2: 118, w: 11, reel: false })}
    <path d="M186 214Q256 92 326 214" stroke="${C.navy}" stroke-width="28" fill="none" stroke-linecap="round"/>
    <path d="M186 214Q256 92 326 214" stroke="url(#gGold)" stroke-width="15" fill="none" stroke-linecap="round"/>
    <g filter="url(#fSh)"><rect x="150" y="204" width="212" height="70" rx="16" fill="url(#gTeal)" stroke="${C.navy}" stroke-width="6"/></g>
    <path d="M221 212V266M291 212V266" stroke="#0A6B76" stroke-width="5"/>
    ${bobber({ x: 185, y: 246, s: 0.5 })}
    ${fish({ x: 256, y: 242, s: 0.26, top: '#FFB020', mid: '#FFD54F', belly: '#FFF3C4', fin: '#FF8A1E', uid: 'stl', outline: '#0A1F44' })}
    <g filter="url(#fShS)"><rect x="308" y="222" width="38" height="46" rx="10" fill="url(#gGlass)" stroke="#BFE9F4" stroke-width="3"/><rect x="312" y="212" width="30" height="14" rx="5" fill="url(#gGold)" stroke="#A56A06" stroke-width="2.5"/></g>
    <g filter="url(#fSh)"><rect x="126" y="264" width="260" height="66" rx="16" fill="#35A9DC" stroke="${C.navy}" stroke-width="6"/></g>
    <path d="M196 272V324M316 272V324" stroke="#1B6F9E" stroke-width="5"/>
    ${[160, 176].map((hx) => `<path d="M${hx} 284V306Q${hx} 318 ${hx - 12} 310" stroke="url(#gGold)" stroke-width="6" fill="none" stroke-linecap="round"/>`).join('')}
    <circle cx="256" cy="298" r="20" fill="url(#gGold)" stroke="#A56A06" stroke-width="4"/><circle cx="256" cy="298" r="7" fill="#A56A06"/>
    <path d="M338 288q14 -10 28 0q-14 10 -28 0Z" fill="${C.coral}" stroke="${C.navy}" stroke-width="3"/>
    <g filter="url(#fSh)"><rect x="110" y="322" width="292" height="94" rx="22" fill="url(#gCoral)" stroke="${C.navy}" stroke-width="6"/></g>
    <path d="M128 340H384" stroke="#fff" stroke-opacity=".5" stroke-width="5" stroke-linecap="round"/>
    ${[158, 354].map((lx) => `<rect x="${lx - 15}" y="322" width="30" height="42" rx="8" fill="url(#gGold)" stroke="#A56A06" stroke-width="4"/><circle cx="${lx}" cy="343" r="5" fill="#A56A06"/>`).join('')}
    <rect x="226" y="360" width="60" height="30" rx="10" fill="${C.foam}" stroke="${C.navy}" stroke-width="4"/><path d="M240 375H272" stroke="${C.navy}" stroke-width="5" stroke-linecap="round"/>
    ${sparkle(122, 150, 13)}${sparkle(412, 220, 12)}`,
  }),
  vip: () => iconFrame({
    uid: 'vp', a: '#2A6FD0', b: '#0A1F44', glow: C.gold,
    subject: `<g filter="url(#fSh)">
    <path d="M256 170V282C256 346 188 352 182 292" stroke="${C.navy}" stroke-width="50" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M256 170V282C256 346 188 352 182 292" stroke="url(#gGold)" stroke-width="32" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M182 300L152 258L204 266Z" fill="${C.navy}" stroke="${C.navy}" stroke-width="16" stroke-linejoin="round"/><path d="M182 300L152 258L204 266Z" fill="#FFD25F"/>
    <path d="M238 214C246 226 268 226 276 214" stroke="#fff" stroke-opacity=".55" stroke-width="7" fill="none" stroke-linecap="round"/>
    </g>
    <g filter="url(#fSh)"><path d="M184 166L194 92L224 126L256 72L288 126L318 92L328 166Z" fill="${C.navy}" stroke="${C.navy}" stroke-width="16" stroke-linejoin="round"/>
    <path d="M184 166L194 92L224 126L256 72L288 126L318 92L328 166Z" fill="url(#gGold)"/>
    <rect x="184" y="158" width="144" height="28" rx="12" fill="url(#gGoldD)" stroke="${C.navy}" stroke-width="5"/>
    <path d="${starPath(256, 136, 19)}" fill="${C.foam}" stroke="#A56A06" stroke-width="3" stroke-linejoin="round"/></g>
    <g filter="url(#fShS)"><path d="M130 382L162 368L162 420L130 420L144 401Z" fill="#D2472B"/><path d="M382 382L350 368L350 420L382 420L368 401Z" fill="#D2472B"/>
    <rect x="150" y="360" width="212" height="62" rx="14" fill="url(#gCoral)" stroke="${C.navy}" stroke-width="5"/></g>
    <text x="256" y="406" font-size="52" text-anchor="middle" fill="${C.foam}" stroke="${C.navy}" stroke-width="9" paint-order="stroke" stroke-linejoin="round" class="t" data-contrast="${C.foam}" letter-spacing="4">VIP</text>
    ${sparkle(386, 190, 14)}${sparkle(124, 220, 11)}`,
  }),
  season_pass: () => iconFrame({
    uid: 'sp', a: '#1FB6B8', b: '#0A1F44', glow: C.coral,
    subject: `<g filter="url(#fShS)"><path d="M196 300L158 430L214 410L236 440L262 320Z" fill="url(#gCoral)" stroke="${C.navy}" stroke-width="5" stroke-linejoin="round"/><path d="M316 300L354 430L298 410L276 440L250 320Z" fill="#E4573A" stroke="${C.navy}" stroke-width="5" stroke-linejoin="round"/></g>
    <g filter="url(#fSh)"><circle cx="256" cy="228" r="132" fill="url(#gGold)" stroke="${C.navy}" stroke-width="7"/></g>
    <circle cx="256" cy="228" r="112" fill="none" stroke="#B96A06" stroke-opacity=".7" stroke-width="5" stroke-dasharray="3 13" stroke-linecap="round"/>
    <circle cx="256" cy="228" r="96" fill="url(#gTeal)" stroke="#0A6B76" stroke-width="5"/>
    <path d="M178 250Q200 222 222 250T266 250T310 250T334 240" stroke="${C.foam}" stroke-width="13" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M186 284Q208 262 228 284T270 284T314 284" stroke="${C.foam}" stroke-opacity=".6" stroke-width="10" fill="none" stroke-linecap="round"/>
    <path d="${starPath(256, 196, 30)}" fill="url(#gGold)" stroke="${C.navy}" stroke-width="6" stroke-linejoin="round"/>
    <g filter="url(#fShS)"><circle cx="356" cy="344" r="44" fill="${C.foam}" stroke="${C.navy}" stroke-width="6"/>
    <text x="356" y="362" font-size="62" text-anchor="middle" fill="${C.navy}" class="t" data-contrast="${C.navy}">1</text></g>
    ${sparkle(140, 120, 14)}${sparkle(398, 120, 11)}`,
  }),
};

const stopwatch = () => `<g filter="url(#fSh)">
  <rect x="232" y="132" width="48" height="34" rx="9" fill="url(#gGoldD)" stroke="${C.navy}" stroke-width="5"/>
  <rect x="226" y="120" width="60" height="20" rx="8" fill="url(#gGold)" stroke="${C.navy}" stroke-width="5"/>
  <circle cx="256" cy="278" r="124" fill="url(#gTeal)" stroke="${C.navy}" stroke-width="7"/></g>
  <circle cx="256" cy="278" r="100" fill="#0E3566" stroke="#0A6B76" stroke-width="5"/>
  ${Array.from({ length: 12 }, (_, i) => `<rect x="253" y="187" width="6" height="${i % 3 === 0 ? 18 : 10}" rx="3" transform="rotate(${i * 30} 256 278)" fill="${i % 3 === 0 ? C.gold : '#9FE9E7'}"/>`).join('')}
  <path d="M276 212L232 286H258L240 348L296 262H266Z" fill="url(#gGold)" stroke="${C.navy}" stroke-width="8" stroke-linejoin="round"/>`;

const PRODUCTS = {
  coin_boost_15: () => iconFrame({
    uid: 'cb', a: '#E8664A', b: '#0A1F44', glow: C.coral,
    subject: `${stopwatch()}
    <g stroke="${C.coral}" stroke-width="12" stroke-linecap="round" opacity=".95"><path d="M92 228H132"/><path d="M80 276H128"/><path d="M92 324H132"/></g>
    ${shell({ x: 400, y: 160, s: 0.62, rot: 16 })}${shell({ x: 404, y: 360, s: 0.5, rot: -10, tone: 'coral' })}${sparkle(130, 128, 13)}${sparkle(396, 262, 12)}`,
  }),
  coin_pack_small: () => iconFrame({
    uid: 'cs', a: '#1FA5D2', b: '#0A1F44', glow: C.gold,
    subject: `${shell({ x: 168, y: 296, s: 1.0, rot: -14, tone: 'coral' })}${shell({ x: 350, y: 300, s: 1.0, rot: 14, tone: 'teal' })}${shell({ x: 258, y: 250, s: 1.55 })}${sparkle(256, 108, 20)}${sparkle(120, 170, 12)}${sparkle(400, 190, 13)}`,
  }),
  coin_pack_medium: () => iconFrame({
    uid: 'cm', a: '#1FA5D2', b: '#0A1F44', glow: C.gold,
    subject: `${shell({ x: 196, y: 198, s: 1.0, rot: -22 })}${shell({ x: 322, y: 198, s: 1.0, rot: 22, tone: 'coral' })}${shell({ x: 256, y: 168, s: 1.15 })}
    <g filter="url(#fSh)"><path d="M212 286C146 322 112 392 150 428C196 454 318 454 362 428C400 392 366 322 300 286Z" fill="url(#gTeal)" stroke="${C.navy}" stroke-width="6" stroke-linejoin="round"/></g>
    <path d="M168 350Q256 380 346 350M158 392Q256 424 354 392" stroke="#0A6B76" stroke-opacity=".5" stroke-width="4" fill="none" stroke-dasharray="10 9"/>
    <ellipse cx="206" cy="340" rx="34" ry="14" transform="rotate(-30 206 340)" fill="#fff" opacity=".35"/>
    <path d="M208 292Q256 312 304 292" stroke="${C.navy}" stroke-width="22" fill="none" stroke-linecap="round"/><path d="M208 292Q256 312 304 292" stroke="url(#gCoral)" stroke-width="14" fill="none" stroke-linecap="round"/>
    <path d="M256 306C226 306 214 344 240 352C252 342 258 322 256 306ZM256 306C286 306 298 344 272 352C260 342 254 322 256 306Z" fill="url(#gCoral)" stroke="${C.navy}" stroke-width="4" stroke-linejoin="round"/>
    ${sparkle(128, 150, 14)}${sparkle(392, 130, 12)}`,
  }),
  coin_pack_large: () => iconFrame({
    uid: 'cl', a: '#1FA5D2', b: '#0A1F44', glow: C.gold,
    subject: `<g filter="url(#fSh)"><ellipse cx="256" cy="296" rx="124" ry="26" fill="#3A220E"/></g>
    ${shell({ x: 190, y: 156, s: 0.9, rot: -14, tone: 'coral' })}${shell({ x: 322, y: 156, s: 0.9, rot: 14, tone: 'teal' })}${shell({ x: 256, y: 132, s: 1.0 })}
    ${shell({ x: 150, y: 214, s: 0.95, rot: -22 })}${shell({ x: 362, y: 214, s: 0.95, rot: 22 })}${shell({ x: 256, y: 200, s: 1.1 })}
    ${shell({ x: 196, y: 252, s: 1.0, rot: -8, tone: 'coral' })}${shell({ x: 316, y: 252, s: 1.0, rot: 8 })}
    <g filter="url(#fSh)"><path d="M126 284H386L356 428Q354 440 342 440H170Q158 440 156 428Z" fill="url(#gWood)" stroke="${C.navy}" stroke-width="6" stroke-linejoin="round"/></g>
    <path d="M134 326H378M146 394H366" stroke="#5E3818" stroke-width="13" stroke-opacity=".65"/><path d="M134 326H378M146 394H366" stroke="url(#gTeal)" stroke-width="8"/>
    <path d="M190 292V434M256 292V440M322 292V434" stroke="#5E3818" stroke-opacity=".4" stroke-width="3"/>
    <rect x="118" y="276" width="276" height="24" rx="12" fill="url(#gWood)" stroke="${C.navy}" stroke-width="5"/>
    ${sparkle(114, 132, 16)}${sparkle(404, 118, 18)}${sparkle(256, 64, 12)}`,
  }),
  pearl_pack: () => iconFrame({
    uid: 'pp', a: '#3AB6D8', b: '#0A1F44', glow: C.foam,
    subject: `${shell({ x: 256, y: 246, s: 2.45, rot: 0, tone: 'coral' })}
    <g filter="url(#fSh)"><path d="M112 316C140 440 372 440 400 316C340 360 172 360 112 316Z" fill="url(#gCoral)" stroke="#D2472B" stroke-width="5" stroke-linejoin="round"/></g>
    <path d="M150 340Q256 384 362 340" stroke="#FFD0C2" stroke-opacity=".7" stroke-width="5" fill="none" stroke-linecap="round"/>
    ${pearl({ x: 184, y: 352, r: 40 })}${pearl({ x: 330, y: 354, r: 42 })}${pearl({ x: 256, y: 330, r: 60 })}
    ${sparkle(130, 140, 15)}${sparkle(392, 152, 17)}${sparkle(256, 80, 11)}`,
  }),
  slot_pack: () => iconFrame({
    uid: 'sl', a: '#1FA5D2', b: '#0A1F44', glow: C.teal,
    subject: `<g filter="url(#fSh)"><path d="M130 214C112 304 146 408 256 424C366 408 400 304 382 214Z" fill="url(#gWood)" stroke="${C.navy}" stroke-width="6" stroke-linejoin="round"/></g>
    <clipPath id="creelClip"><path d="M130 214C112 304 146 408 256 424C366 408 400 304 382 214Z"/></clipPath>
    <g clip-path="url(#creelClip)" stroke="#6B4020" stroke-opacity=".5" stroke-width="5">${Array.from({ length: 12 }, (_, i) => `<path d="M${90 + i * 36} 200L${210 + i * 36} 440M${330 + i * 36 - 440} 200L${210 + i * 36 - 440 + 0} 440"/>`).join('')}</g>
    <ellipse cx="256" cy="214" rx="127" ry="38" fill="#4A2B12" stroke="${C.navy}" stroke-width="6"/>
    ${fish({ x: 256, y: 196, s: 0.58, rot: -8, top: '#FFB020', mid: '#FFD36B', belly: '#FFF0C0', fin: '#FF8A1E', spots: '#B96A06', uid: 'sl1' })}
    <ellipse cx="256" cy="226" rx="127" ry="24" fill="none"/><path d="M131 216Q256 260 381 216" stroke="${C.navy}" stroke-width="6" fill="none"/>
    <path d="M118 226C98 150 130 100 256 96C382 100 414 150 394 226" stroke="${C.navy}" stroke-width="22" fill="none" stroke-linecap="round"/><path d="M118 226C98 150 130 100 256 96C382 100 414 150 394 226" stroke="url(#gWood)" stroke-width="12" fill="none" stroke-linecap="round"/>
    <g filter="url(#fSh)"><circle cx="372" cy="342" r="66" fill="url(#gTeal)" stroke="${C.navy}" stroke-width="7"/>
    <rect x="364" y="308" width="16" height="68" rx="8" fill="${C.foam}"/><rect x="338" y="334" width="68" height="16" rx="8" fill="${C.foam}"/></g>
    ${sparkle(130, 150, 12)}${sparkle(404, 150, 14)}`,
  }),
};

// ---------------------------------------------------------------------------------------------
// Iconos del juego (512x512): 3 variantes A/B/C
// ---------------------------------------------------------------------------------------------
const ICONS = {
  'icon-a-mitico': () => `<g id="bg">${skyLake({ w: 512, h: 512, hz: 0.6, sunX: 0.5, uid: 'ia', pines: false })}
  <clipPath id="skyclip_ia"><rect width="512" height="306"/></clipPath>
  <ellipse cx="256" cy="200" rx="260" ry="210" fill="url(#gHaloM)"/><g clip-path="url(#skyclip_ia)">${rays(256, 300, 420, 14, 0.09, '#fff')}</g>
  <radialGradient id="vig_ia" cx=".5" cy=".5" r=".72"><stop offset=".72" stop-color="#04101F" stop-opacity="0"/><stop offset="1" stop-color="#04101F" stop-opacity=".5"/></radialGradient><rect width="512" height="512" fill="url(#vig_ia)"/></g>
  <g id="subject">
  ${whale({ x: 240, y: 212, s: 0.54, rot: -5, uid: 'ia', halo: false })}
  ${splash(246, 304, 110, 12)}
  ${waterFront({ x: -40, y: 304, w: 592, h: 240, uid: 'wfa' })}
  ${fortu({ x: 232, y: 376, s: 0.4, rot: -4, uid: 'ia' })}
  ${sparkle(122, 120, 14)}${sparkle(402, 100, 11)}${sparkle(436, 206, 9)}${sparkle(300, 110, 8)}
  </g>`,
  'icon-b-fortu': () => iconFrame({
    uid: 'ib', a: '#2FD6D0', b: '#0B6F86', glow: C.gold, ring: false,
    bgExtra: `<circle cx="256" cy="250" r="176" fill="url(#gHalo)"/>${rays(256, 250, 420, 18, 0.14, '#FFE9A0')}`,
    subject: `${fortu({ x: 274, y: 268, s: 0.75, rot: 0, uid: 'ib' })}${sparkle(112, 150, 17)}${sparkle(404, 134, 13)}${sparkle(98, 330, 10)}${sparkle(420, 300, 12)}`,
  }),
  'icon-c-salto': () => `<g id="bg">${skyLake({ w: 512, h: 512, hz: 0.62, sunX: 0.5, uid: 'ic', pines: false })}
  <clipPath id="skyclip_ic"><rect width="512" height="318"/></clipPath>
  <circle cx="256" cy="232" r="150" fill="url(#gHalo)"/><g clip-path="url(#skyclip_ic)">${rays(256, 300, 420, 14, 0.1, '#FFE9A0')}</g>
  <radialGradient id="vig_ic" cx=".5" cy=".5" r=".72"><stop offset=".72" stop-color="#04101F" stop-opacity="0"/><stop offset="1" stop-color="#04101F" stop-opacity=".5"/></radialGradient><rect width="512" height="512" fill="url(#vig_ic)"/></g>
  <g id="subject">
  ${splash(256, 346, 130, 12)}
  ${fish({ x: 262, y: 206, s: 1.4, rot: -30, top: '#FFB020', mid: '#FFD54F', belly: '#FFF3C4', fin: '#FF8A1E', h: 1.15, tail: 1.1, spots: '#B96A06', glow: '#FFC83D', uid: 'ic' })}
  ${waterFront({ x: -40, y: 348, w: 592, h: 200, uid: 'wfc' })}
  ${splash(256, 352, 86, 9)}
  ${sparkle(124, 140, 15)}${sparkle(402, 126, 13)}${sparkle(414, 262, 10)}
  </g>`,
};

// ---------------------------------------------------------------------------------------------
// Miniaturas 1920x1080 (ES y EN). Texto: <= 3 palabras + logotipo. Nada esencial en el 15 % inferior (y > 918).
// ---------------------------------------------------------------------------------------------
const W = 1920, H = 1080;
const vignette = (uid) => `<radialGradient id="tv_${uid}" cx=".5" cy=".5" r=".75"><stop offset=".6" stop-color="#04101F" stop-opacity="0"/><stop offset="1" stop-color="#04101F" stop-opacity=".45"/></radialGradient><rect width="${W}" height="${H}" fill="url(#tv_${uid})"/>`;
// halo oscuro difuminado detras del bloque de texto (sube el contraste sin oscurecer el arte)
const textHalo = (x, y, w, h) => `<g filter="url(#fB24)"><rect x="${x + 20}" y="${y + 20}" width="${w - 40}" height="${h - 40}" rx="90" fill="#061630" opacity=".42"/></g>`;
const hook = (lines, { x = 90, y, size = 168, fill = C.gold, lh = 1.02 }) => lines.map((l, i) => outlined(l, { x, y: y + i * size * lh, size, fill, sw: Math.round(size * 0.13), id: `hook${i}` })).join('');

const TXT = {
  es: { t1: ['¿UN MÍTICO?'], t2: ['COMPLETA EL', 'BESTIARIO'], t3: ['PESCA CON', 'AMIGOS'], t4: ['EXPLORA', '3 ZONAS'] },
  en: { t1: ['A MYTHIC?'], t2: ['FILL THE', 'BESTIARY'], t3: ['FISH WITH', 'FRIENDS'], t4: ['EXPLORE', '3 ZONES'] },
};

function thumb1(loc) {
  const L = TXT[loc].t1;
  return `<g id="bg">${skyLake({ w: W, h: H, hz: 0.6, sunX: 0.68, uid: 't1', pines: true })}
  <ellipse cx="1340" cy="520" rx="760" ry="520" fill="url(#gHaloM)"/>${rays(1340, 600, 1500, 20, 0.07, '#fff')}${vignette('t1')}</g>
  <g id="art">
  ${whale({ x: 1360, y: 560, s: 1.28, rot: -3, uid: 't1', halo: false })}
  ${splash(1340, 690, 520, 22)}
  ${waterFront({ x: -40, y: 690, w: 2000, h: 400, uid: 'wf1' })}
  ${dock({ x: -40, y: 800, w: 800, thick: 38, posts: 4, lantern: [80], uid: 't1' })}
  ${fortu({ x: 330, y: 654, s: 0.95, rot: -2, rod: true, uid: 't1' })}
  <path d="M645 402Q700 640 806 752" stroke="#fff" stroke-opacity=".9" stroke-width="3.5" fill="none"/>
  ${waves(740, 770, 140, 2, '#fff', 0.7)}${bobber({ x: 806, y: 758, s: 0.8 })}
  ${sparkle(1000, 300, 22)}${sparkle(1640, 280, 18)}${sparkle(1760, 420, 14)}${sparkle(920, 560, 12)}
  </g>
  <g id="text">${textHalo(40, 40, 1240, 400)}${wordmark({ x: 90, y: 160, size: 96 })}${hook(L, { y: 345, size: 190 })}</g>`;
}

function thumb2(loc) {
  const L = TXT[loc].t2;
  return `<g id="bg"><radialGradient id="b2" cx=".74" cy=".45" r=".85"><stop offset="0" stop-color="#1F8FC0"/><stop offset=".55" stop-color="#0F5C92"/><stop offset="1" stop-color="#0A1F44"/></radialGradient><rect width="${W}" height="${H}" fill="url(#b2)"/>
  ${rays(1430, 480, 1500, 22, 0.06, '#fff')}
  ${Array.from({ length: 22 }, (_, i) => `<circle cx="${(i * 211) % W}" cy="${(i * 97) % 900}" r="${4 + (i % 4) * 3}" fill="#fff" opacity="${0.08 + (i % 3) * 0.05}"/>`).join('')}${vignette('t2')}</g>
  <g id="art"><g transform="translate(1440 510) rotate(-3) scale(0.92)">${bestiaryBook({ uid: 'b2' })}</g>
  ${sparkle(1080, 190, 18)}${sparkle(1850, 150, 20)}${sparkle(1830, 840, 14)}</g>
  <g id="text">${textHalo(40, 40, 1100, 540)}${wordmark({ x: 90, y: 160, size: 96 })}${hook(L, { y: 350, size: 148 })}</g>`;
}

function thumb3(loc) {
  const L = TXT[loc].t3;
  const FY = 830;
  const rodsTips = [[556, 683], [898, 672], [1216, 683]];
  return `<g id="bg">${skyLake({ w: W, h: H, hz: 0.58, sunX: 0.72, uid: 't3', pines: true })}${vignette('t3')}</g>
  <g id="art">
  ${splash(1690, 650, 150, 14)}
  ${fish({ x: 1690, y: 510, s: 1.5, rot: 30, flip: true, top: '#FFB020', mid: '#FFD54F', belly: '#FFF3C4', fin: '#FF8A1E', h: 1.15, tail: 1.1, spots: '#B96A06', glow: '#FFC83D', uid: 't3' })}
  ${waterFront({ x: -40, y: 650, w: 2000, h: 440, uid: 'wf3' })}
  ${dock({ x: -40, y: FY, w: 1500, thick: 40, posts: 7, lantern: [110, 1450], uid: 't3' })}
  ${fisher({ x: 300, y: FY, s: 1.5, shirt: C.coral, hat: C.coral, pose: 'sit', tip: rodsTips[0], bend: 26, lineTo: [562, 776] })}${bobber({ x: 562, y: 782, s: 0.6 })}
  ${fisher({ x: 630, y: FY, s: 1.55, shirt: C.teal, hat: C.teal, pose: 'stand', tip: rodsTips[1], bend: 30, lineTo: [904, 772] })}${bobber({ x: 904, y: 778, s: 0.6 })}
  ${fisher({ x: 960, y: FY, s: 1.5, shirt: C.gold, hat: '#E9A21F', pose: 'sit', tip: rodsTips[2], bend: 26, lineTo: [1222, 776] })}${bobber({ x: 1222, y: 782, s: 0.6 })}
  ${fisher({ x: 1290, y: FY, s: 1.62, shirt: C.foam, hat: '#A66BFF', pose: 'stand', tip: [1545, 388], bend: 70, lineTo: [1572, 442] })}
  ${sparkle(1560, 300, 20)}${sparkle(1850, 360, 14)}${sparkle(1400, 480, 12)}
  </g>
  <g id="text">${textHalo(40, 40, 1000, 520)}${wordmark({ x: 90, y: 160, size: 96 })}${hook(L, { y: 340, size: 170 })}</g>`;
}

function zonePanel(i, { x, y, w, h, kind, skew = 0.06 }) {
  const sk = h * skew;
  const poly = `${r1(x + sk)},${y} ${x + w + sk},${y} ${x + w},${y + h} ${x},${y + h}`;
  const scene = kind === 'lake'
    ? `${skyLake({ w, h, hz: 0.55, sunX: 0.5, uid: `z${i}`, pines: true, stars: false })}${dock({ x: -20, y: h * 0.78, w: w * 0.7, thick: 24, posts: 3, uid: `zd${i}` })}`
    : kind === 'river' ? riverScene({ w, h, uid: `z${i}` }) : coastScene({ w, h, uid: `z${i}` });
  return `<g><g filter="url(#fSh)"><polygon points="${poly}" fill="${C.foam}" stroke="${C.foam}" stroke-width="22" stroke-linejoin="round"/></g>
  <clipPath id="zc${i}"><polygon points="${poly}"/></clipPath>
  <g clip-path="url(#zc${i})"><g transform="translate(${x + sk / 2} ${y})"><svg x="0" y="0" width="${w + sk}" height="${h}" viewBox="0 0 ${w} ${h}" preserveAspectRatio="xMidYMid slice" overflow="hidden">${scene}</svg></g></g></g>`;
}

function thumb4(loc) {
  const L = TXT[loc].t4;
  return `<g id="bg"><radialGradient id="b4" cx=".72" cy=".5" r=".9"><stop offset="0" stop-color="#1F8FC0"/><stop offset=".6" stop-color="#0F5C92"/><stop offset="1" stop-color="#0A1F44"/></radialGradient><rect width="${W}" height="${H}" fill="url(#b4)"/>${rays(1380, 500, 1500, 22, 0.06, '#fff')}${vignette('t4')}</g>
  <g id="art">
  ${zonePanel(0, { x: 850, y: 150, w: 300, h: 720, kind: 'lake' })}
  ${zonePanel(1, { x: 1190, y: 190, w: 300, h: 720, kind: 'river' })}
  ${zonePanel(2, { x: 1530, y: 150, w: 300, h: 720, kind: 'coast' })}
  ${sparkle(800, 150, 18)}${sparkle(1880, 120, 14)}${sparkle(1860, 900, 12)}
  </g>
  <g id="text">${textHalo(40, 40, 800, 560)}${wordmark({ x: 90, y: 160, size: 96 })}${hook(L, { y: 350, size: 150 })}</g>`;
}

// ---------------------------------------------------------------------------------------------
// Manifiesto
// ---------------------------------------------------------------------------------------------
export const ASSETS = [
  // Iconos del juego
  { id: 'icon-a-mitico', group: 'icon', dir: 'icon', w: 512, h: 512, name: 'Icono A - El Mitico emerge', body: ICONS['icon-a-mitico'], key: '(ninguna: icono del juego)', note: 'Idea 1: criatura Mitica + Fortu con cana' },
  { id: 'icon-b-fortu', group: 'icon', dir: 'icon', w: 512, h: 512, name: 'Icono B - Fortu (mascota)', body: ICONS['icon-b-fortu'], key: '(ninguna: icono del juego)', note: 'Idea 5: primer plano de la mascota; el mas legible a 64 px' },
  { id: 'icon-c-salto', group: 'icon', dir: 'icon', w: 512, h: 512, name: 'Icono C - Salto dorado', body: ICONS['icon-c-salto'], key: '(ninguna: icono del juego)', note: 'Pez dorado saltando al atardecer (escena de pesca)' },
  // Miniaturas
  ...['es', 'en'].flatMap((loc) => [
    { id: `thumb-1-mitico-${loc}`, group: 'thumbnail', dir: 'thumbnails', w: W, h: H, name: `Miniatura 1 - ${TXT[loc].t1.join(' ')} (${loc.toUpperCase()})`, body: () => thumb1(loc), key: '(ninguna: miniatura)', note: 'Hero: Mitico + Fortu', loc },
    { id: `thumb-2-bestiario-${loc}`, group: 'thumbnail', dir: 'thumbnails', w: W, h: H, name: `Miniatura 2 - ${TXT[loc].t2.join(' ')} (${loc.toUpperCase()})`, body: () => thumb2(loc), key: '(ninguna: miniatura)', note: 'Libro del bestiario con 6 casillas', loc },
    { id: `thumb-3-amigos-${loc}`, group: 'thumbnail', dir: 'thumbnails', w: W, h: H, name: `Miniatura 3 - ${TXT[loc].t3.join(' ')} (${loc.toUpperCase()})`, body: () => thumb3(loc), key: '(ninguna: miniatura)', note: 'Co-juego: 4 pescadores en un muelle', loc },
    { id: `thumb-4-zonas-${loc}`, group: 'thumbnail', dir: 'thumbnails', w: W, h: H, name: `Miniatura 4 - ${TXT[loc].t4.join(' ')} (${loc.toUpperCase()})`, body: () => thumb4(loc), key: '(ninguna: miniatura)', note: 'Lago, Rio y Costa', loc },
  ]),
  // Pases
  { id: 'auto_fish', group: 'pass', dir: 'passes', w: 512, h: 512, name: 'Pase Auto-Pesca', body: PASSES.auto_fish, key: 'passes.auto_fish', note: 'Cana + bucle de flechas' },
  { id: 'double_coins', group: 'pass', dir: 'passes', w: 512, h: 512, name: 'Pase 2x Dinero', body: PASSES.double_coins, key: 'passes.double_coins', note: '"x2" + conchas (sin monedas)' },
  { id: 'starter', group: 'pass', dir: 'passes', w: 512, h: 512, name: 'Pack de inicio', body: PASSES.starter, key: 'passes.starter', note: 'Caja de aparejos abierta (sin cofre de botin)' },
  { id: 'vip', group: 'pass', dir: 'passes', w: 512, h: 512, name: 'Pase VIP', body: PASSES.vip, key: 'passes.vip', note: 'Anzuelo dorado + corona con estrella + cinta VIP' },
  { id: 'season_pass', group: 'pass', dir: 'passes', w: 512, h: 512, name: 'Pase de Temporada 1', body: PASSES.season_pass, key: 'passes.season_pass', note: 'Medalla con ola y estrella, insignia "1"' },
  // Productos
  { id: 'coin_boost_15', group: 'product', dir: 'products', w: 512, h: 512, name: 'Boost de Monedas (15 min)', body: PRODUCTS.coin_boost_15, key: 'products.coin_boost_15', note: 'Cronometro + rayo' },
  { id: 'coin_pack_small', group: 'product', dir: 'products', w: 512, h: 512, name: 'Pack de monedas pequeno', body: PRODUCTS.coin_pack_small, key: 'products.coin_pack_small', note: '3 conchas' },
  { id: 'coin_pack_medium', group: 'product', dir: 'products', w: 512, h: 512, name: 'Pack de monedas mediano', body: PRODUCTS.coin_pack_medium, key: 'products.coin_pack_medium', note: 'Saco de red con conchas' },
  { id: 'coin_pack_large', group: 'product', dir: 'products', w: 512, h: 512, name: 'Pack de monedas grande', body: PRODUCTS.coin_pack_large, key: 'products.coin_pack_large', note: 'Cubo de madera desbordante de conchas' },
  { id: 'pearl_pack', group: 'product', dir: 'products', w: 512, h: 512, name: 'Pack de perlas', body: PRODUCTS.pearl_pack, key: 'products.pearl_pack', note: 'Concha abierta con 3 perlas' },
  { id: 'slot_pack', group: 'product', dir: 'products', w: 512, h: 512, name: 'Mas espacio (+10 espacios)', body: PRODUCTS.slot_pack, key: 'products.slot_pack', note: 'Cesta de pesca con insignia "+"' },
];

/** Productos APAGADOS en la v1 (FeatureFlags.paidLuckEnabled = false): se listan, no se generan. */
export const DISABLED = [
  { key: 'passes.luck_plus', name: 'Pase Suerte+', why: 'altera probabilidades: objeto aleatorio de pago; apagado en v1 (paidLuckEnabled=false)' },
  { key: 'products.lucky_bait_15', name: 'Cebo de Suerte (15 min)', why: 'altera probabilidades: objeto aleatorio de pago; apagado en v1 (paidLuckEnabled=false)' },
];

export { SAFE_R, W, H };
