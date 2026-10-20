/* Utilidades de animación deterministas. Todo es función pura del tiempo t (segundos). */
(function () {
  const VP = (window.VP = window.VP || {});

  const clamp = (x, a = 0, b = 1) => (x < a ? a : x > b ? b : x);
  const lerp = (a, b, t) => a + (b - a) * t;
  const seg = (t, a, b) => clamp((t - a) / (b - a)); // progreso normalizado 0..1 de t en [a,b]

  const E = {
    lin: (t) => t,
    inQ: (t) => t * t,
    outQ: (t) => 1 - (1 - t) * (1 - t),
    inOutQ: (t) => (t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2),
    inC: (t) => t * t * t,
    outC: (t) => 1 - Math.pow(1 - t, 3),
    inOutC: (t) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2),
    outExpo: (t) => (t >= 1 ? 1 : 1 - Math.pow(2, -10 * t)),
    inExpo: (t) => (t <= 0 ? 0 : Math.pow(2, 10 * t - 10)),
    outBack: (t, s = 1.70158) => {
      t -= 1;
      return t * t * ((s + 1) * t + s) + 1;
    },
    outElastic: (t) => {
      if (t <= 0) return 0;
      if (t >= 1) return 1;
      return Math.pow(2, -10 * t) * Math.sin(((t * 10 - 0.75) * (2 * Math.PI)) / 3) + 1;
    },
    outBounce: (t) => {
      const n = 7.5625, d = 2.75;
      if (t < 1 / d) return n * t * t;
      if (t < 2 / d) return n * (t -= 1.5 / d) * t + 0.75;
      if (t < 2.5 / d) return n * (t -= 2.25 / d) * t + 0.9375;
      return n * (t -= 2.625 / d) * t + 0.984375;
    },
  };

  function rng(seed) {
    let a = seed >>> 0;
    return function () {
      a |= 0; a = (a + 0x6d2b79f5) | 0;
      let t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }

  function hex2rgb(h) {
    h = h.replace('#', '');
    if (h.length === 3) h = h.split('').map((c) => c + c).join('');
    const n = parseInt(h, 16);
    return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
  }
  function rgba(h, a = 1) {
    const [r, g, b] = hex2rgb(h);
    return `rgba(${r},${g},${b},${a})`;
  }
  function mix(h1, h2, t) {
    const a = hex2rgb(h1), b = hex2rgb(h2);
    return `rgb(${Math.round(lerp(a[0], b[0], t))},${Math.round(lerp(a[1], b[1], t))},${Math.round(lerp(a[2], b[2], t))})`;
  }
  function shade(h, f) { // f<0 oscurece, f>0 aclara
    const [r, g, b] = hex2rgb(h);
    const t = f < 0 ? 0 : 255, p = Math.abs(f);
    return `rgb(${Math.round(lerp(r, t, p))},${Math.round(lerp(g, t, p))},${Math.round(lerp(b, t, p))})`;
  }

  function fmtNum(n, o = {}) {
    const dec = o.decimals || 0;
    const sep = o.sep != null ? o.sep : '.';
    const dsep = sep === '.' ? ',' : '.';
    const v = Math.abs(n).toFixed(dec);
    let [ip, fp] = v.split('.');
    ip = ip.replace(/\B(?=(\d{3})+(?!\d))/g, sep);
    return (n < 0 ? '-' : '') + (o.prefix || '') + ip + (fp ? dsep + fp : '') + (o.suffix || '');
  }

  // Aplica transformación + opacidad de golpe. Siempre desde 0 (sin estado acumulado).
  function setT(el, o) {
    const x = o.x || 0, y = o.y || 0, r = o.r || 0;
    const sx = o.sx != null ? o.sx : o.s != null ? o.s : 1;
    const sy = o.sy != null ? o.sy : o.s != null ? o.s : 1;
    el.style.transform = `translate(${x.toFixed(2)}px,${y.toFixed(2)}px) rotate(${r.toFixed(3)}deg) scale(${sx.toFixed(4)},${sy.toFixed(4)})`;
    if (o.o != null) el.style.opacity = o.o.toFixed(3);
  }

  // "Pop" estilo Shorts: 0 -> overshoot -> 1.  Devuelve {s,o}
  function pop(lt, at, dur = 0.38, over = 2.2) {
    if (lt < at) return { s: 0, o: 0 };
    const p = clamp((lt - at) / dur);
    return { s: Math.max(0.0001, E.outBack(p, over)), o: clamp(p * 6) };
  }
  // sacudida decreciente (pseudo-aleatoria determinista)
  function shake(lt, at, dur = 0.25, amp = 14, seed = 1) {
    const p = (lt - at) / dur;
    if (p < 0 || p > 1) return { x: 0, y: 0, r: 0 };
    const k = (1 - p) * (1 - p) * amp;
    const f = Math.floor((lt - at) * 60);
    const r = rng(seed * 977 + f);
    return { x: (r() - 0.5) * 2 * k, y: (r() - 0.5) * 2 * k, r: (r() - 0.5) * k * 0.12 };
  }

  VP.clamp = clamp; VP.lerp = lerp; VP.seg = seg; VP.E = E; VP.rng = rng;
  VP.hex2rgb = hex2rgb; VP.rgba = rgba; VP.mix = mix; VP.shade = shade;
  VP.fmtNum = fmtNum; VP.setT = setT; VP.pop = pop; VP.shake = shake;
})();
