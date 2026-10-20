/* Runtime: construye escenas desde window.__SPEC__ (ya resuelto) y expone window.renderFrame(t) -> Promise.
   Determinista: el estado visual es una función pura de t. No hay timers ni CSS transitions. */
(function () {
  const VP = window.VP;
  const { clamp, lerp, seg, E, setT, pop } = VP;
  const $ = (tag, cls, parent, text) => {
    const e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    if (parent) parent.appendChild(e);
    return e;
  };

  /* ---------- transiciones: p = 0..1, partner = escena saliente ---------- */
  function resetEl(el) { el.style.transform = ''; el.style.opacity = '1'; el.style.clipPath = 'none'; el.style.translate = ''; }
  const TRANS = {
    fade(i, o, p) { i.style.opacity = p.toFixed(3); },
    'slide-up'(i, o, p, C) { const e = E.outCubic ? E.outCubic(p) : E.outC(p); i.style.transform = `translateY(${((1 - e) * C.H).toFixed(1)}px)`; o.style.transform = `translateY(${(-e * C.H * 0.25).toFixed(1)}px) scale(${(1 - 0.06 * e).toFixed(4)})`; },
    'slide-down'(i, o, p, C) { const e = E.outC(p); i.style.transform = `translateY(${(-(1 - e) * C.H).toFixed(1)}px)`; o.style.transform = `translateY(${(e * C.H * 0.25).toFixed(1)}px)`; },
    'slide-left'(i, o, p, C) { const e = E.outC(p); i.style.transform = `translateX(${((1 - e) * C.W).toFixed(1)}px)`; o.style.transform = `translateX(${(-e * C.W * 0.25).toFixed(1)}px)`; },
    'slide-right'(i, o, p, C) { const e = E.outC(p); i.style.transform = `translateX(${(-(1 - e) * C.W).toFixed(1)}px)`; o.style.transform = `translateX(${(e * C.W * 0.25).toFixed(1)}px)`; },
    zoom(i, o, p) { const e = E.outC(p); i.style.transform = `scale(${lerp(1.7, 1, e).toFixed(4)})`; i.style.opacity = clamp(p * 2.2).toFixed(3); o.style.transform = `scale(${lerp(1, 0.86, e).toFixed(4)})`; },
    'zoom-out'(i, o, p) { const e = E.outC(p); o.style.transform = `scale(${lerp(1, 1.8, e).toFixed(4)})`; o.style.opacity = (1 - clamp(p * 1.6)).toFixed(3); },
    wipe(i, o, p, C) { const e = E.inOutC(p); i.style.clipPath = `inset(0 ${((1 - e) * 100).toFixed(2)}% 0 0)`; },
    'wipe-up'(i, o, p) { const e = E.inOutC(p); i.style.clipPath = `inset(${((1 - e) * 100).toFixed(2)}% 0 0 0)`; },
    circle(i, o, p, C) { const e = E.inOutC(p); i.style.clipPath = `circle(${(e * 80).toFixed(2)}% at 50% 50%)`; },
    flash(i, o, p, C) { i.style.opacity = p >= 0.5 ? '1' : '0'; C.flash(1 - Math.abs(2 * p - 1)); },
    glitch(i, o, p, C) {
      const f = Math.floor(p * 14), r = VP.rng(f * 7 + 3)();
      const amp = (1 - p) * 70 * (r - 0.5);
      i.style.transform = `translateX(${(amp * C.u).toFixed(1)}px)`;
      o.style.transform = `translateX(${(-amp * 0.6 * C.u).toFixed(1)}px)`;
      i.style.opacity = (p < 0.2 && r < 0.4 ? 0 : 1) + '';
      C.flash(0.25 * (1 - p) * (r > 0.6 ? 1 : 0));
    },
  };

  async function init(spec) {
    const stage = document.getElementById('stage');
    const W = spec.vw, H = spec.vh, u = spec.u, pal = spec.palette;
    stage.style.width = W + 'px'; stage.style.height = H + 'px';
    const s = stage.style;
    s.setProperty('--u', u + 'px');
    for (const k of ['bg1', 'bg2', 'accent', 'accent2', 'hot', 'text', 'dim', 'good', 'bad']) s.setProperty('--c-' + k, pal[k]);
    const ty = spec.typography || {};
    const stack = (f) => `'${f}', 'Inter', 'DejaVu Sans', 'Noto Color Emoji', sans-serif`;
    s.setProperty('--f-head', stack(ty.heading || 'Inter'));
    s.setProperty('--f-body', stack(ty.body || 'Inter'));
    s.setProperty('--w-head', String(ty.headingWeight || 900));
    s.setProperty('--tt', ty.uppercase === false ? 'none' : 'uppercase');
    const safe = spec.safe; // en px de captura
    s.setProperty('--st', safe.t + 'px'); s.setProperty('--sb', safe.b + 'px'); s.setProperty('--sl', safe.l + 'px'); s.setProperty('--sr', safe.r + 'px');

    // fuentes propias
    if (spec.fonts && spec.fonts.length) {
      document.getElementById('userfonts').textContent = spec.fonts.map((f) => `@font-face{font-family:'${f.family}';src:url('${f.src}');font-weight:${f.weight || '100 900'};}`).join('\n');
      await Promise.all(spec.fonts.map((f) => document.fonts.load(`${f.weight || 900} 40px '${f.family}'`).catch(() => {})));
    }
    await document.fonts.load(`${ty.headingWeight || 900} 40px '${ty.heading || 'Inter'}'`).catch(() => {});
    await document.fonts.load('700 40px Inter').catch(() => {});
    await document.fonts.load('40px "Noto Color Emoji"').catch(() => {});
    await document.fonts.ready;

    let flashAcc = 0;
    const base = {
      W, H, u, pal, land: W > H * 1.2, sep: spec.locale === 'en' ? ',' : '.',
      safeH: H - safe.t - safe.b, safeW: W - safe.l - safe.r,
      flash: (a) => { flashAcc = Math.max(flashAcc, a); },
      makeBg: (d) => VP.createBg(d, W, H, pal),
      beat: spec.beat, abs: 0,
    };

    /* escenas */
    const scenes = spec.scenes.map((sc, i) => {
      const root = $('div', 'scene', stage);
      root.style.zIndex = String(i + 1); root.style.visibility = 'hidden';
      let bg = null;
      if (sc.bg) { bg = VP.createBg(sc.bg, W, H, pal); root.appendChild(bg.el); }
      const safeEl = $('div', 'safe', root);
      const fit = $('div', 'fit', safeEl);
      const C = Object.assign({}, base, { root, safeEl, fit });
      const kind = VP.kinds[sc.kind];
      if (!kind) throw new Error('Tipo de escena desconocido: ' + sc.kind);
      const update = kind(sc, C);
      // auto-ajuste si el contenido no cabe en la zona segura
      const sh = safeEl.clientHeight, sw = safeEl.clientWidth;
      const ch = Math.max(fit.offsetHeight, fit.scrollHeight), cw = Math.max(fit.offsetWidth, fit.scrollWidth);
      const k = Math.min(1, sh / ch, sw / cw);
      if (k < 0.995) { fit.style.scale = String(k); if (fit.classList.contains('top')) fit.style.transformOrigin = '50% 0'; }
      root.style.display = 'none'; root.style.visibility = 'visible';
      return { sc, root, bg, update, C };
    });

    /* overlays globales */
    const ovl = $('div', 'overlay', stage); ovl.style.zIndex = '1000';
    const pr = spec.progress || {};
    let prog = null, segs = [];
    if (pr.style && pr.style !== 'none') {
      prog = $('div', '', ovl); prog.id = 'progress';
      const yy = pr.position === 'bottom' ? H - safe.b * 0.55 : safe.t * 0.5;
      prog.style.top = yy + 'px';
      if (pr.style === 'solid') { prog.classList.add('solid'); segs = [$('div', 'fill', prog)]; }
      else spec.scenes.forEach(() => { const sg = $('div', 'seg', prog); segs.push($('div', 'fill', sg)); });
    }
    const subCfg = spec.subtitles || {};
    let subsEl = null, subLine = null, curChunk = -2, subWords = [];
    if (subCfg.enabled !== false && spec.captions && spec.captions.length) {
      subsEl = $('div', '', ovl); subsEl.id = 'subs';
      subsEl.style.top = (H * (subCfg.y != null ? subCfg.y : base.land ? 0.84 : 0.7)) + 'px';
      subsEl.style.translate = '0 -50%';
      subsEl.style.setProperty('--subsize', '1');
      const sz = (subCfg.size || (base.land ? 64 : 84)) * u;
      subsEl.style.fontSize = sz + 'px';
    }
    let brandEl = null;
    if (spec.brand && spec.brand.watermark && spec.brand.watermark !== 'none' && spec.brand.name) {
      brandEl = $('div', 'pill dark', ovl, spec.brand.name); brandEl.id = 'brand';
      brandEl.style.fontSize = 30 * u + 'px'; brandEl.style.padding = `${8 * u}px ${22 * u}px`;
      brandEl.style.left = safe.l + 'px'; brandEl.style.top = Math.max(8 * u, safe.t * 0.7) + 'px';
      if (spec.brand.watermark === 'top-right') { brandEl.style.left = 'auto'; brandEl.style.right = safe.r + 'px'; }
    }
    if (spec.legal) { const lg = $('div', '', ovl, spec.legal); lg.id = 'legal'; lg.style.bottom = Math.max(8 * u, safe.b * 0.18) + 'px'; }
    const flashEl = $('div', 'overlay', ovl); flashEl.id = 'flash';
    if (spec.debugGuides) {
      const g = $('div', '', ovl); g.id = 'guides';
      const r = $('div', '', g); r.style.cssText = `left:${safe.l}px;top:${safe.t}px;right:${safe.r}px;bottom:${safe.b}px`;
    }

    /* ---------- subtítulos con resaltado de palabra ---------- */
    const caps = spec.captions || [];
    function setChunk(idx) {
      subsEl.innerHTML = ''; subWords = [];
      if (idx < 0) return;
      subLine = $('div', 'line', subsEl);
      caps[idx].words.forEach((w) => { const e = $('span', 'sw', subLine, w.w); subWords.push({ e, w }); });
      // una sola línea que siempre cabe en la zona segura
      const avail = subsEl.clientWidth, wd = subLine.offsetWidth;
      if (wd > avail) subLine.style.fontSize = (parseFloat(getComputedStyle(subLine).fontSize) * avail / wd * 0.98) + 'px';
    }
    function updateSubs(t) {
      let idx = -1;
      for (let i = 0; i < caps.length; i++) if (t >= caps[i].t0 && t < caps[i].t1) { idx = i; break; }
      if (idx !== curChunk) { curChunk = idx; setChunk(idx); }
      if (idx < 0) return;
      const c = caps[idx], pin = clamp((t - c.t0) / 0.12);
      subLine.style.transform = `scale(${lerp(0.82, 1, E.outBack(pin, 2)).toFixed(4)})`;
      subLine.style.opacity = clamp(pin * 4).toFixed(3);
      const accent = subCfg.color || pal.accent;
      subWords.forEach(({ e, w }) => {
        const act = t >= w.t0 && t < w.t1 + 0.0;
        const k = act ? 1 + 0.07 * Math.sin(clamp((t - w.t0) / 0.14) * Math.PI * 0.5) : 1;
        e.style.color = act ? accent : (t >= w.t1 ? '#ffffff' : '#ffffff');
        e.style.transform = `scale(${k.toFixed(3)})`;
        e.style.opacity = subCfg.style === 'reveal' && t < w.t0 - 1e-6 ? '0.35' : '1';
      });
    }

    /* ---------- frame ---------- */
    const dur = spec.duration;
    window.__info = { duration: dur, fps: spec.fps, scenes: spec.scenes.length };
    window.renderFrame = async function (t) {
      flashAcc = 0;
      const ps = [];
      const vis = scenes.map((S) => t >= S.sc.start - 1e-6 && (t < S.sc.end - 1e-6 || S === scenes[scenes.length - 1]));
      scenes.forEach((S, i) => {
        S.root.style.display = vis[i] ? 'block' : 'none';
        if (vis[i]) resetEl(S.root);
      });
      for (let i = 1; i < scenes.length; i++) {
        const S = scenes[i], tr = S.sc.tr;
        if (!vis[i] || !vis[i - 1] || !tr || !(tr.d > 0)) continue;
        const p = (t - S.sc.start) / tr.d;
        if (p >= 0 && p < 1) (TRANS[tr.type] || TRANS.fade)(S.root, scenes[i - 1].root, p, base);
      }
      scenes.forEach((S, i) => {
        if (!vis[i]) return;
        base.abs = t; S.C.abs = t;
        const lt = t - S.sc.start;
        if (S.bg) { const p = S.bg.update(lt, S.sc.dur, t, spec.beat); if (p) ps.push(p); }
        const p2 = S.update(lt);
        if (p2) ps.push(p2);
      });
      if (prog) {
        if (pr.style === 'solid') segs[0].style.width = (clamp(t / dur) * 100).toFixed(2) + '%';
        else scenes.forEach((S, i) => {
          const a = i === 0 ? 0 : S.sc.start, b = i + 1 < scenes.length ? scenes[i + 1].sc.start : dur;
          segs[i].style.width = (clamp((t - a) / (b - a)) * 100).toFixed(2) + '%';
        });
      }
      if (subsEl) updateSubs(t);
      flashEl.style.opacity = clamp(flashAcc).toFixed(3);
      if (ps.length) await Promise.all(ps);
      return true;
    };
    window.__ready = true;
  }

  window.__init = init;
  (async () => {
    try {
      await init(window.__SPEC__);
    } catch (e) {
      window.__error = String(e && e.stack || e);
      console.error(window.__error);
    }
  })();
})();
