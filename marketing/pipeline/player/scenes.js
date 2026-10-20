/* Tipos de escena (kinds). Cada uno: (sc, C) => update(lt)   [lt = segundos desde el inicio de la escena]
   sc = datos ya resueltos por lib/compile.mjs (tiempos incluidos). C = contexto de render. */
(function () {
  const VP = window.VP;
  const { clamp, lerp, seg, E, setT, pop, shake, fmtNum, rgba } = VP;

  const $ = (tag, cls, parent, text) => {
    const e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    if (parent) parent.appendChild(e);
    return e;
  };
  const px = (C, n) => n * C.u;

  /* ---------- texto cinético ---------- */
  function words(parent, list, cls) {
    const wrap = $('div', 'rich ' + (cls || ''), parent);
    const items = [];
    (list || []).forEach((w) => {
      if (w.br) { wrap.appendChild(document.createElement('br')); return; }
      const s = $('span', 'w em' + (w.em || 0), wrap, w.w);
      items.push({ el: s, t: w.t || 0, em: w.em || 0 });
    });
    return { wrap, items };
  }
  function fitWords(wrap, items, maxH, maxPx) {
    let size = parseFloat(getComputedStyle(wrap).fontSize);
    if (maxPx && size > maxPx) size = maxPx;
    wrap.style.fontSize = size + 'px';
    for (let i = 0; i < 60; i++) {
      const wide = items.some((it) => it.el.offsetWidth > wrap.clientWidth + 1);
      if (!wide && wrap.offsetHeight <= maxH) break;
      size *= 0.94;
      wrap.style.fontSize = size + 'px';
    }
  }
  function animWords(items, lt, mode, seed) {
    for (let i = 0; i < items.length; i++) {
      const it = items[i], d = lt - it.t, el = it.el;
      if (d < 0) { el.style.opacity = '0'; el.style.transform = 'scale(0)'; continue; }
      const sgn = i % 2 ? 1 : -1;
      if (mode === 'slam') {
        const p = clamp(d / 0.3), k = 3 - 2 * E.outBack(p, 1.5);
        const sh = shake(lt, it.t + 0.18, 0.2, 14, (seed || 1) + i);
        setT(el, { s: Math.max(0.01, k), r: (1 - E.outC(p)) * 9 * sgn + sh.r, x: sh.x, y: sh.y, o: clamp(p * 10) });
      } else if (mode === 'rise') {
        const p = clamp(d / 0.35);
        setT(el, { y: (1 - E.outC(p)) * 70, s: lerp(0.9, 1, E.outC(p)), o: clamp(p * 4) });
      } else { // pop
        const p = pop(d, 0, 0.36, 2.4);
        setT(el, { s: p.s, r: (1 - clamp(d / 0.36)) * 6 * sgn, o: p.o });
      }
    }
  }
  const lastT = (items) => items.reduce((m, it) => Math.max(m, it.t), 0);

  function counterText(sc, lt, o) {
    const p = E.outExpo(seg(lt, o.at, o.at + o.dur));
    const v = lerp(o.from, o.to, p);
    return fmtNum(v, { decimals: o.decimals || 0, prefix: o.prefix || '', suffix: o.suffix || '', sep: o.sep });
  }

  /* posiciona un elemento absoluto dentro de .safe por fracciones (x,y) centrado */
  function place(el, x, y) {
    el.style.position = 'absolute';
    el.style.left = (x * 100).toFixed(2) + '%';
    el.style.top = (y * 100).toFixed(2) + '%';
    el.style.translate = '-50% -50%';
  }

  const K = (VP.kinds = {});

  /* ================= HOOK (primeros ~2 s) ================= */
  K.hook = function (sc, C) {
    const { fit } = C;
    let kick = null, emo = null, sub = null, chip = null;
    if (sc.kicker) kick = $('div', 'pill hot', fit, sc.kicker);
    if (sc.emoji) { emo = $('div', 'emoji', fit, sc.emoji); emo.style.fontSize = px(C, C.land ? 150 : 230) + 'px'; }
    const T = words(fit, sc.title.words, 'h1');
    fitWords(T.wrap, T.items, C.safeH * (C.land ? 0.55 : 0.46), px(C, C.land ? 150 : 200));
    if (sc.sub) { sub = words(fit, sc.sub.words, 'h3'); }
    if (sc.chip) chip = $('div', 'pill dark', fit, sc.chip);
    const tl = lastT(T.items);
    return function (lt) {
      if (kick) { const p = pop(lt, 0.02, 0.3); setT(kick, { s: p.s, o: p.o, y: (1 - E.outC(clamp(lt / 0.3))) * -40 }); }
      if (emo) { const p = pop(lt, 0.0, 0.45, 3); setT(emo, { s: p.s, o: p.o, r: Math.sin(lt * 9) * 6 * Math.exp(-lt * 1.2) }); }
      animWords(T.items, lt, 'slam', 3);
      const z = 1 + 0.05 * seg(lt, tl, tl + 1.6);
      T.wrap.style.transform = `scale(${z.toFixed(4)})`;
      if (sub) animWords(sub.items, lt, 'rise');
      if (chip) { const p = pop(lt, tl + 0.35, 0.3); setT(chip, { s: p.s, o: p.o }); }
      const f = 1 - seg(lt, 0, 0.16);
      C.flash(f * 0.85);
    };
  };

  /* ================= CAPTION (sobre gameplay) ================= */
  K.caption = function (sc, C) {
    const { fit } = C;
    fit.classList.add('top');
    let T = null;
    if (sc.title) {
      T = words(fit, sc.title.words, 'h2');
      fitWords(T.wrap, T.items, C.safeH * 0.3, px(C, C.land ? 90 : 112));
    }
    const chips = (sc.chips || []).map((c, i) => {
      const e = $('div', 'pill ' + (c.style || 'white'));
      if (c.emoji) $('span', 'emoji', e, c.emoji);
      const tx = $('span', '', e, c.text || '');
      C.safeEl.appendChild(e);
      place(e, c.x != null ? c.x : 0.5, c.y != null ? c.y : 0.6);
      return { e, tx, c, i };
    });
    const stickers = (sc.stickers || []).map((s) => {
      const e = $('div', 'sticker', C.safeEl, s.emoji);
      e.style.fontSize = px(C, s.size || 200) + 'px';
      place(e, s.x != null ? s.x : 0.5, s.y != null ? s.y : 0.5);
      return { e, s };
    });
    const imgs = (sc.images || []).map((m) => {
      const e = $('img', 'sticker', C.safeEl); e.src = m.src; e.style.width = px(C, m.w || 400) + 'px'; e.style.height = 'auto';
      place(e, m.x != null ? m.x : 0.5, m.y != null ? m.y : 0.5);
      return { e, m };
    });
    return function (lt) {
      if (T) animWords(T.items, lt, sc.titleAnim || 'pop');
      chips.forEach(({ e, tx, c, i }) => {
        const p = pop(lt, c.at || 0, 0.38, 2.6);
        const bob = Math.sin(lt * 3 + i * 1.7) * px(C, 7);
        setT(e, { s: p.s, o: p.o, y: bob, r: (c.rot || 0) + (1 - clamp((lt - (c.at || 0)) / 0.38)) * 10 });
        if (c.counter) tx.textContent = counterText(sc, lt, { at: c.at || 0, dur: c.counter.dur || 1.2, from: c.counter.from || 0, to: c.counter.to, prefix: c.counter.prefix, suffix: c.counter.suffix, decimals: c.counter.decimals, sep: C.sep }) + (c.text ? ' ' + c.text : '');
      });
      stickers.forEach(({ e, s }) => {
        const p = pop(lt, s.at || 0, 0.5, 3.2);
        setT(e, { s: p.s, o: p.o, r: (s.rot || 0) + Math.sin(lt * 5 + (s.at || 0)) * 5, y: Math.sin(lt * 2.5) * px(C, 8) });
      });
      imgs.forEach(({ e, m }) => { const p = pop(lt, m.at || 0, 0.45, 2.4); setT(e, { s: p.s, o: p.o, y: Math.sin(lt * 2.4) * px(C, 8) }); });
    };
  };

  /* ================= RANK (top / lista) ================= */
  K.rank = function (sc, C) {
    const { fit } = C;
    fit.classList.add('top');
    const total = sc.total || 5;
    const dots = $('div', '', fit);
    dots.style.cssText = `display:flex;gap:${px(C, 14)}px;margin-bottom:${px(C, 6)}px`;
    const dotEls = [];
    for (let i = total; i >= 1; i--) {
      const d = $('div', '', dots);
      const cur = i === sc.rank;
      d.style.cssText = `width:${px(C, cur ? 56 : 30)}px;height:${px(C, 30)}px;border-radius:99px;background:${i >= sc.rank ? sc.accent : 'rgba(255,255,255,0.3)'};opacity:${cur ? 1 : 0.7}`;
      dotEls.push(d);
    }
    const badgeBox = $('div', '', fit);
    badgeBox.style.cssText = `position:relative;width:${px(C, 470)}px;height:${px(C, 400)}px;`;
    const badge = $('div', 'badge', badgeBox);
    badge.style.cssText = `position:absolute;inset:0;border-radius:${px(C, 70)}px;background:linear-gradient(145deg,${sc.accent},${sc.accent2});border:${px(C, 10)}px solid #fff;box-shadow:0 ${px(C, 18)}px 0 rgba(0,0,0,0.35);`;
    const top = $('div', 'rich h3', badge, 'TOP'); top.style.cssText += `width:auto;color:#0b0618;-webkit-text-stroke:0;text-shadow:none;font-size:${px(C, 54)}px;letter-spacing:0.2em;margin-top:${px(C, 6)}px`;
    const num = $('div', 'num', badge, '#' + sc.rank); num.style.fontSize = px(C, 260) + 'px';
    num.style.webkitTextStroke = px(C, 12) + 'px #0b0618';
    let emo = null;
    if (sc.emoji) { emo = $('div', 'sticker', badgeBox, sc.emoji); emo.style.fontSize = px(C, 170) + 'px'; emo.style.right = px(C, -90) + 'px'; emo.style.top = px(C, -70) + 'px'; }
    let img = null;
    if (sc.image) { img = $('img', 'sticker', badgeBox); img.src = sc.image; img.style.width = px(C, 260) + 'px'; img.style.right = px(C, -120) + 'px'; img.style.top = px(C, -90) + 'px'; }
    const T = words(fit, sc.title.words, 'h2');
    fitWords(T.wrap, T.items, C.safeH * 0.22, px(C, 104));
    let sub = null, stat = null;
    if (sc.sub) sub = words(fit, sc.sub.words, 'h3');
    if (sc.stat) stat = $('div', 'pill big', fit, '');
    return function (lt) {
      const p = clamp(lt / 0.45), k = E.outBack(p, 1.7);
      setT(badgeBox, { x: (1 - k) * -C.W * 0.9, r: (1 - k) * -14, s: 1 });
      const sh = shake(lt, 0.3, 0.25, 12, sc.rank);
      badge.style.transform = `translate(${sh.x.toFixed(1)}px,${sh.y.toFixed(1)}px)`;
      dotEls.forEach((d, i) => { d.style.transform = `scale(${(1 + (i === total - sc.rank ? 0.15 * Math.sin(lt * 8) : 0)).toFixed(3)})`; });
      if (emo) { const q = pop(lt, 0.35, 0.45, 3); setT(emo, { s: q.s, o: q.o, r: Math.sin(lt * 4) * 8 }); }
      if (img) { const q = pop(lt, 0.35, 0.45, 3); setT(img, { s: q.s, o: q.o, y: Math.sin(lt * 3) * 8 }); }
      animWords(T.items, lt, 'pop');
      if (sub) animWords(sub.items, lt, 'rise');
      if (stat) {
        const q = pop(lt, sc.stat.at || 0.9, 0.4);
        setT(stat, { s: q.s, o: q.o });
        const txt = typeof sc.stat.to === 'number' ? counterText(sc, lt, { at: sc.stat.at || 0.9, dur: 0.9, from: sc.stat.from || 0, to: sc.stat.to, prefix: sc.stat.prefix, suffix: sc.stat.suffix, decimals: sc.stat.decimals, sep: C.sep }) : String(sc.stat.to);
        stat.textContent = (sc.stat.label ? sc.stat.label + ' ' : '') + txt;
      }
    };
  };

  /* ================= COUNTER ================= */
  K.counter = function (sc, C) {
    const { fit } = C;
    let emo = null;
    if (sc.emoji) { emo = $('div', 'emoji', fit, sc.emoji); emo.style.fontSize = px(C, 200) + 'px'; }
    const L = words(fit, sc.label.words, 'h3');
    const num = $('div', 'num', fit, '0'); num.style.fontSize = px(C, 250) + 'px';
    const track = $('div', '', fit); track.style.cssText = `width:78%;height:${px(C, 34)}px;border-radius:99px;background:rgba(255,255,255,0.22);overflow:hidden;border:${px(C, 5)}px solid rgba(255,255,255,0.5)`;
    const fill = $('div', '', track); fill.style.cssText = `height:100%;width:0%;border-radius:99px;background:linear-gradient(90deg,${sc.accent},${sc.accent2})`;
    let sub = null;
    if (sc.sub) sub = words(fit, sc.sub.words, 'h3');
    const o = { at: sc.at || 0.5, dur: sc.countDur || 2.2, from: sc.from || 0, to: sc.to, prefix: sc.prefix, suffix: sc.suffix, decimals: sc.decimals, sep: C.sep };
    return function (lt) {
      if (emo) { const p = pop(lt, 0.05, 0.45, 3); setT(emo, { s: p.s, o: p.o, y: Math.sin(lt * 3) * px(C, 8) }); }
      animWords(L.items, lt, 'rise');
      const prog = seg(lt, o.at, o.at + o.dur);
      num.textContent = counterText(sc, lt, o);
      const end = o.at + o.dur;
      const bump = lt > end ? 1 + 0.18 * Math.exp(-(lt - end) * 7) * Math.cos((lt - end) * 22) : 1;
      const pp = pop(lt, 0.1, 0.4);
      setT(num, { s: bump * pp.s, o: pp.o });
      num.style.color = lt > end ? sc.accent : '#fff';
      fill.style.width = (E.outExpo(prog) * 100).toFixed(2) + '%';
      if (sub) animWords(sub.items, lt - 0 + 0, 'rise');
    };
  };

  /* ================= COMPARE (antes / después) ================= */
  K.compare = function (sc, C) {
    const { W, H } = C;
    const bA = C.makeBg(sc.before.bg), bB = C.makeBg(sc.after.bg);
    C.root.insertBefore(bA.el, C.safeEl);
    C.root.insertBefore(bB.el, C.safeEl);
    const dim = $('div', 'abs'); dim.style.cssText = 'inset:0;background:rgba(18,12,30,0.5)'; C.root.insertBefore(dim, C.safeEl);
    // la capa "después" va encima de la de "antes"; el divisor encima de ambas
    const divider = $('div', 'abs'); divider.style.cssText = `top:0;bottom:0;width:${px(C, 10)}px;margin-left:${px(C, -5)}px;background:#fff;box-shadow:0 0 ${px(C, 28)}px rgba(255,255,255,0.9)`;
    const handle = $('div', 'abs pill white', divider, '◀ ▶'); handle.style.cssText += `top:50%;left:50%;translate:-50% -50%;font-size:${px(C, 40)}px`;
    C.root.insertBefore(divider, C.safeEl);
    const fit = C.fit; fit.classList.add('spread');
    const T = words(fit, sc.title.words, 'h2');
    fitWords(T.wrap, T.items, C.safeH * 0.2, px(C, 100));
    const tags = $('div', '', fit); tags.style.cssText = 'width:100%;display:flex;justify-content:space-between';
    const tB = $('div', 'pill dark', tags, sc.before.label || 'ANTES'), tA = $('div', 'pill', tags, sc.after.label || 'DESPUÉS');
    const spacer = $('div', '', fit); spacer.style.flex = '1';
    const rows = (sc.stats || []).map((s) => {
      const card = $('div', 'card', fit); card.style.width = '100%';
      const head = $('div', 'body', card); head.style.cssText += `display:flex;justify-content:space-between;margin-bottom:${px(C, 10)}px;font-size:${px(C, 40)}px`;
      const l = $('span', '', head, s.label), v = $('span', '', head, '');
      const tr = $('div', '', card); tr.style.cssText = `height:${px(C, 26)}px;border-radius:99px;background:rgba(255,255,255,0.15);overflow:hidden;position:relative`;
      const b1 = $('div', '', tr); b1.style.cssText = `position:absolute;left:0;top:0;bottom:0;border-radius:99px;background:rgba(255,255,255,0.5);width:${(s.beforePct * 100).toFixed(1)}%`;
      const b2 = $('div', '', tr); b2.style.cssText = `position:absolute;left:0;top:0;bottom:0;border-radius:99px;background:linear-gradient(90deg,${sc.accent},${sc.accent2});width:0%`;
      return { card, v, b2, s };
    });
    const w0 = sc.wipeAt, w1 = sc.wipeAt + sc.wipeDur;
    return function (lt) {
      const ps = [];
      const k = E.inOutC(seg(lt, w0, w1));
      const xd = W * k;
      bB.el.style.clipPath = `inset(0 ${(W - xd).toFixed(1)}px 0 0)`;
      divider.style.left = xd.toFixed(1) + 'px';
      divider.style.opacity = (k > 0.002 && k < 0.998 ? 1 : 0) + '';
      dim.style.clipPath = `inset(0 0 0 ${xd.toFixed(1)}px)`;
      ps.push(bA.update(lt, sc.dur, C.abs, C.beat), bB.update(lt, sc.dur, C.abs, C.beat));
      animWords(T.items, lt, 'pop');
      const a = pop(lt, 0.15, 0.35); setT(tB, { s: a.s, o: (a.o) * (k > 0.35 ? 0.35 : 1) });
      const b = pop(lt, w1 - 0.25, 0.4, 3); setT(tA, { s: b.s, o: b.o });
      rows.forEach((r, i) => {
        const at = w1 + 0.1 + i * 0.35, q = pop(lt, 0.4 + i * 0.12, 0.4);
        setT(r.card, { s: q.s, o: q.o });
        const g = E.outExpo(seg(lt, at, at + 0.9));
        r.b2.style.width = (g * r.s.afterPct * 100).toFixed(1) + '%';
        const val = lerp(r.s.before, r.s.after, g);
        r.v.textContent = lt < at ? fmtNum(r.s.before, { decimals: r.s.decimals, suffix: r.s.suffix || '', prefix: r.s.prefix || '', sep: C.sep }) : fmtNum(val, { decimals: r.s.decimals, suffix: r.s.suffix || '', prefix: r.s.prefix || '', sep: C.sep });
      });
      return Promise.all(ps);
    };
  };

  /* ================= STAGES (progresión) ================= */
  K.stages = function (sc, C) {
    const { fit } = C;
    const T = words(fit, sc.title.words, 'h3');
    const val = $('div', 'num', fit, ''); val.style.fontSize = px(C, 210) + 'px';
    const lab = $('div', 'pill big', fit, '');
    const track = $('div', '', fit); track.style.cssText = `width:92%;height:${px(C, 44)}px;border-radius:99px;background:rgba(255,255,255,0.2);border:${px(C, 6)}px solid rgba(255,255,255,0.55);position:relative`;
    const fill = $('div', '', track); fill.style.cssText = `position:absolute;left:0;top:0;bottom:0;width:0%;border-radius:99px;background:linear-gradient(90deg,${sc.accent},${sc.accent2})`;
    const n = sc.stages.length;
    const marks = sc.stages.map((s, i) => {
      const m = $('div', '', track); m.style.cssText = `position:absolute;top:50%;left:${(i / (n - 1)) * 100}%;width:${px(C, 40)}px;height:${px(C, 40)}px;translate:-50% -50%;border-radius:50%;background:#fff;border:${px(C, 8)}px solid #0b0618`;
      return m;
    });
    const list = $('div', '', fit); list.style.cssText = `width:100%;display:flex;flex-direction:column;gap:${px(C, 14)}px`;
    const cards = sc.stages.map((s) => {
      const c = $('div', 'card', list); c.style.cssText += `display:flex;align-items:center;gap:${px(C, 24)}px;padding:${px(C, 14)}px ${px(C, 30)}px`;
      const e = $('span', 'emoji', c, s.emoji || '⭐'); e.style.fontSize = px(C, 62) + 'px';
      const l = $('span', 'body', c, s.label); l.style.flex = '1'; l.style.textAlign = 'left';
      const v = $('span', 'body', c, fmtNum(s.value, { prefix: sc.prefix || '', suffix: sc.suffix || '', sep: C.sep })); v.style.color = sc.accent;
      return { c, s };
    });
    return function (lt) {
      animWords(T.items, lt, 'rise');
      // etapa actual según tiempos s.t
      let cur = -1; for (let i = 0; i < n; i++) if (lt >= sc.stages[i].t) cur = i;
      let v = sc.stages[0].value, prog = 0;
      if (cur >= 0) {
        v = sc.stages[cur].value; prog = cur / (n - 1);
        if (cur < n - 1) {
          const q = E.inOutQ(seg(lt, sc.stages[cur].t + sc.hold, sc.stages[cur + 1].t));
          v = lerp(sc.stages[cur].value, sc.stages[cur + 1].value, q); prog = (cur + q) / (n - 1);
        }
      }
      const pp = pop(lt, 0.1, 0.4);
      const last = cur >= 0 ? sc.stages[cur].t : 0, bump = cur >= 0 ? 1 + 0.12 * Math.exp(-(lt - last) * 8) * Math.cos((lt - last) * 20) : 1;
      val.textContent = fmtNum(v, { decimals: sc.decimals, prefix: sc.prefix || '', suffix: sc.suffix || '', sep: C.sep });
      setT(val, { s: pp.s * bump, o: pp.o });
      lab.textContent = cur >= 0 ? (sc.stages[cur].emoji || '') + ' ' + sc.stages[cur].label : '…';
      setT(lab, { s: pop(lt, 0.2, 0.35).s, o: pop(lt, 0.2, 0.35).o });
      fill.style.width = (prog * 100).toFixed(2) + '%';
      marks.forEach((m, i) => { m.style.background = i <= cur ? sc.accent : '#fff'; });
      cards.forEach(({ c, s }, i) => {
        const q = pop(lt, 0.35 + i * 0.1, 0.35);
        const on = i <= cur;
        setT(c, { s: q.s, o: q.o * (on ? 1 : 0.45), x: on ? 0 : 0 });
        c.style.borderColor = i === cur ? sc.accent : 'rgba(255,255,255,0.18)';
      });
    };
  };

  /* ================= OFFER (oferta limitada) ================= */
  K.offer = function (sc, C) {
    const { fit } = C;
    const main = $('div', '', fit);
    main.style.cssText = `width:100%;display:flex;flex-direction:${C.land ? 'row' : 'column'};align-items:center;justify-content:center;gap:${px(C, C.land ? 70 : 26)}px`;
    const colA = $('div', '', main), colB = $('div', '', main);
    for (const c of [colA, colB]) c.style.cssText = `display:flex;flex-direction:column;align-items:center;gap:${px(C, 24)}px;${C.land ? 'flex:1' : 'width:100%'}`;
    const rib = $('div', 'pill big bad', colB, sc.kicker || '⚠ OFERTA LIMITADA ⚠');
    const T = words(colB, sc.headline.words, 'h2');
    fitWords(T.wrap, T.items, C.safeH * (C.land ? 0.3 : 0.17), px(C, 98));
    // starburst
    const BS = px(C, C.land ? 470 : 440);
    const bw = $('div', '', colA); bw.style.cssText = `position:relative;width:${BS}px;height:${BS}px;`;
    const star = $('div', '', bw);
    const pts = []; for (let i = 0; i < 48; i++) { const r = i % 2 ? 0.82 : 1, a = (i / 48) * Math.PI * 2; pts.push(`${(50 + 50 * r * Math.cos(a)).toFixed(2)}% ${(50 + 50 * r * Math.sin(a)).toFixed(2)}%`); }
    star.style.cssText = `position:absolute;inset:0;clip-path:polygon(${pts.join(',')});background:radial-gradient(circle at 50% 40%,${sc.accent},${sc.accent2});`;
    const sh = $('div', '', bw); sh.style.cssText = `position:absolute;inset:${px(C, 36)}px;border-radius:50%;border:${px(C, 8)}px dashed rgba(11,6,24,0.45)`;
    const dtx = $('div', 'badge', bw); dtx.style.cssText = 'position:absolute;inset:0;';
    const dn = $('div', 'num', dtx, sc.discount); dn.style.fontSize = px(C, sc.discount.length > 5 ? 130 : 170) + 'px'; dn.style.webkitTextStroke = px(C, 12) + 'px #0b0618';
    const dl = $('div', 'rich h3', dtx, sc.discountLabel || 'DESCUENTO'); dl.style.cssText += `width:auto;color:#0b0618;-webkit-text-stroke:0;text-shadow:none;font-size:${px(C, 46)}px;letter-spacing:0.08em`;
    const items = (sc.items || []).map((it) => {
      const c = $('div', 'card', null); c.style.cssText += `display:flex;flex-direction:column;align-items:center;gap:${px(C, 8)}px;padding:${px(C, 16)}px ${px(C, 24)}px;min-width:${px(C, 200)}px`;
      const e = $('div', 'emoji', c, it.emoji); e.style.fontSize = px(C, 86) + 'px';
      $('div', 'body', c, it.label).style.fontSize = px(C, 32) + 'px';
      return { c, it };
    });
    if (items.length) { const row = $('div', '', colB); row.style.cssText = `display:flex;gap:${px(C, 18)}px;justify-content:center;flex-wrap:wrap`; items.forEach((x) => row.appendChild(x.c)); }
    // cuenta atrás
    const cdw = $('div', '', colB); cdw.style.cssText = `display:flex;flex-direction:column;align-items:center;gap:${px(C, 8)}px`;
    $('div', 'body dim', cdw, sc.endsLabel || 'TERMINA EN').style.cssText += `font-size:${px(C, 36)}px;letter-spacing:0.15em`;
    const cd = $('div', '', cdw); cd.style.cssText = `display:flex;gap:${px(C, 14)}px;align-items:center`;
    const cells = [0, 1, 2].map((i) => {
      if (i) $('div', 'num', cd, ':').style.fontSize = px(C, 80) + 'px';
      const b = $('div', 'card', cd); b.style.cssText += `padding:${px(C, 6)}px ${px(C, 26)}px;min-width:${px(C, 170)}px`;
      const nn = $('div', 'num', b, '00'); nn.style.fontSize = px(C, 112) + 'px'; nn.style.webkitTextStroke = '0'; nn.style.textShadow = 'none';
      return { b, nn };
    });
    // código
    let code = null, codeTx = null, codeLab = null;
    if (sc.code) {
      code = $('div', 'card', colB); code.style.cssText += `border:${px(C, 7)}px dashed ${sc.accent};display:flex;flex-direction:column;align-items:center;gap:${px(C, 4)}px;padding:${px(C, 14)}px ${px(C, 50)}px;position:relative;overflow:hidden`;
      codeLab = $('div', 'body dim', code, sc.codeLabel || 'CÓDIGO DE CANJE'); codeLab.style.fontSize = px(C, 32) + 'px';
      codeTx = $('div', 'num', code, ''); codeTx.style.cssText += `font-size:${px(C, 100)}px;letter-spacing:0.08em;-webkit-text-stroke:0;text-shadow:none;color:${sc.accent};font-family:'JetBrains Mono','DejaVu Sans Mono',monospace`;
    }
    const left = sc.endsIn;
    return function (lt) {
      const blink = Math.floor(lt / 0.28) % 2;
      rib.className = 'pill big ' + (blink ? 'bad' : 'hot');
      { const p = pop(lt, 0.0, 0.35); setT(rib, { s: p.s, o: p.o }); }
      animWords(T.items, lt, 'pop');
      const pb = pop(lt, 0.15, 0.55, 2.8);
      setT(bw, { s: pb.s * (1 + 0.035 * Math.sin(lt * 7)), o: pb.o, r: Math.sin(lt * 2.2) * 3 });
      star.style.transform = `rotate(${(lt * 14).toFixed(2)}deg)`;
      items.forEach(({ c }, i) => { const p = pop(lt, 0.9 + i * 0.18, 0.35); setT(c, { s: p.s, o: p.o }); });
      const rem = Math.max(0, left - lt * (sc.countRate || 1));
      const hh = Math.floor(rem / 3600), mm = Math.floor((rem % 3600) / 60), ss = Math.floor(rem % 60);
      [hh, mm, ss].forEach((v, i) => { cells[i].nn.textContent = String(v).padStart(2, '0'); });
      const fr = (lt * (sc.countRate || 1)) % 1;
      setT(cells[2].b, { s: 1 + 0.07 * Math.exp(-fr * 9) });
      const pc = pop(lt, 0.8, 0.4); setT(cdw, { s: pc.s, o: pc.o });
      if (code) {
        const at = sc.codeAt || 1.8, p = pop(lt, at, 0.4, 2.2); setT(code, { s: p.s, o: p.o });
        const nch = Math.min(sc.code.length, Math.floor(Math.max(0, lt - at - 0.15) / 0.07));
        codeTx.textContent = sc.code.slice(0, nch) + (nch < sc.code.length && Math.floor(lt * 6) % 2 ? '▌' : '');
        const sw = seg((lt - at - 0.9) % 2.2, 0, 0.7);
        code.style.backgroundImage = lt > at + 0.9 ? `linear-gradient(105deg, transparent ${(sw * 140 - 30).toFixed(1)}%, rgba(255,255,255,0.35) ${(sw * 140 - 15).toFixed(1)}%, transparent ${(sw * 140).toFixed(1)}%)` : 'none';
      }
      C.flash(0.6 * (1 - seg(lt, 0, 0.12)) * (sc.flash ? 1 : 0));
    };
  };

  /* ================= BULLETS ================= */
  K.bullets = function (sc, C) {
    const { fit } = C;
    const T = words(fit, sc.title.words, 'h2');
    fitWords(T.wrap, T.items, C.safeH * 0.25, px(C, 104));
    const list = $('div', '', fit); list.style.cssText = `width:100%;display:flex;flex-direction:column;gap:${px(C, 20)}px`;
    const its = sc.items.map((it) => {
      const c = $('div', 'card', list); c.style.cssText += `display:flex;align-items:center;gap:${px(C, 28)}px;text-align:left`;
      const e = $('span', 'emoji', c, it.emoji || '✅'); e.style.fontSize = px(C, 80) + 'px';
      const t = $('span', 'body', c, it.text); t.style.fontSize = px(C, 52) + 'px';
      return { c, it };
    });
    return function (lt) {
      animWords(T.items, lt, 'pop');
      its.forEach(({ c, it }) => {
        const p = clamp((lt - it.at) / 0.4), k = E.outBack(p, 1.5);
        setT(c, { x: (1 - k) * C.W * 0.8, o: clamp(p * 5) });
      });
    };
  };

  /* ================= CTA ================= */
  K.cta = function (sc, C) {
    const { fit } = C;
    let emo = null;
    if (sc.emoji) { emo = $('div', 'emoji', fit, sc.emoji); emo.style.fontSize = px(C, C.land ? 140 : 210) + 'px'; }
    const T = words(fit, sc.title.words, 'h1');
    fitWords(T.wrap, T.items, C.safeH * (C.land ? 0.4 : 0.3), px(C, C.land ? 130 : 160));
    let sub = null;
    if (sc.sub) sub = words(fit, sc.sub.words, 'h3');
    const bw = $('div', '', fit); bw.style.cssText = `position:relative;margin-top:${px(C, 12)}px`;
    const btn = $('div', 'pill big', bw, sc.button || '¡JUEGA GRATIS!'); btn.style.cssText += `font-size:${px(C, 72)}px;padding:${px(C, 30)}px ${px(C, 70)}px;overflow:hidden;position:relative;background:linear-gradient(180deg,${sc.accent},${sc.accent2});`;
    const shine = $('div', '', btn); shine.style.cssText = 'position:absolute;top:0;bottom:0;width:30%;left:0;background:linear-gradient(105deg,transparent,rgba(255,255,255,0.65),transparent)';
    const hand = $('div', 'emoji', bw, '👆'); hand.style.cssText += `position:absolute;right:${px(C, 10)}px;top:${px(C, 78)}px;font-size:${px(C, 120)}px`;
    let code = null, handle = null;
    if (sc.code) { code = $('div', 'pill dark', fit, ''); code.innerHTML = `<span class="small" style="opacity:.8">${sc.codeLabel || 'CÓDIGO'}</span><span style="color:${sc.accent};font-family:'JetBrains Mono','DejaVu Sans Mono',monospace;letter-spacing:.06em">${sc.code}</span>`; }
    if (sc.handle) handle = $('div', 'body', fit, sc.handle);
    const tl = lastT(T.items);
    return function (lt) {
      if (emo) { const p = pop(lt, 0.0, 0.5, 3); setT(emo, { s: p.s, o: p.o, r: Math.sin(lt * 5) * 6, y: Math.sin(lt * 3.5) * px(C, 10) }); }
      animWords(T.items, lt, 'slam', 9);
      if (sub) animWords(sub.items, lt, 'rise');
      const p = pop(lt, tl + 0.3, 0.45, 2.8);
      setT(btn, { s: p.s * (1 + 0.045 * Math.sin(lt * 8)), o: p.o });
      shine.style.left = ((((lt * 0.7) % 1.6) * 160) - 40).toFixed(1) + '%';
      const tap = Math.sin(lt * 7);
      setT(hand, { y: tap * px(C, 16), x: -tap * px(C, 10), s: pop(lt, tl + 0.6, 0.4, 3).s, o: pop(lt, tl + 0.6, 0.4).o, r: -tap * 6 });
      if (code) { const q = pop(lt, tl + 0.55, 0.4); setT(code, { s: q.s, o: q.o }); }
      if (handle) { const q = pop(lt, tl + 0.75, 0.4); setT(handle, { s: q.s, o: q.o }); }
    };
  };
})();
