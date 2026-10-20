/* Fondos: procedurales (canvas 2D, deterministas por t), imagen con Ken Burns y clips (secuencia de frames).
   Los fondos procedurales son *sustitutos* de gameplay real: úsalos mientras no tengas grabaciones. */
(function () {
  const VP = window.VP;
  const { clamp, lerp, seg, E, rng, rgba, mix, shade } = VP;
  const TAU = Math.PI * 2;

  /* ---------- helpers de dibujo ---------- */
  function vgrad(ctx, y0, y1, stops) {
    const g = ctx.createLinearGradient(0, y0, 0, y1);
    stops.forEach(([p, c]) => g.addColorStop(p, c));
    return g;
  }
  function poly(ctx, pts, fill) {
    ctx.beginPath();
    ctx.moveTo(pts[0][0], pts[0][1]);
    for (let i = 1; i < pts.length; i++) ctx.lineTo(pts[i][0], pts[i][1]);
    ctx.closePath();
    ctx.fillStyle = fill;
    ctx.fill();
  }
  function cube(ctx, cx, yBase, w, h, color) {
    // cara frontal + tapa (vista desde arriba)
    const x0 = cx - w / 2, top = yBase - h, tp = w * 0.2;
    poly(ctx, [[x0, top], [x0 + w, top], [x0 + w, yBase], [x0, yBase]], color);
    poly(ctx, [[x0, top], [x0 + w, top], [cx + w * 0.4, top - tp], [cx - w * 0.4, top - tp]], shade(color, 0.35));
    ctx.fillStyle = 'rgba(0,0,0,0.18)';
    ctx.fillRect(x0, yBase - h * 0.28, w, h * 0.28);
    ctx.strokeStyle = 'rgba(255,255,255,0.28)';
    ctx.lineWidth = Math.max(1, w * 0.025);
    ctx.strokeRect(x0, top, w, h);
  }
  function isoCube2(ctx, x, y, s, c) {
    // Cubo isométrico completo: s = lado; (x,y) = vértice superior de la tapa.
    const a = s * 0.5, b = s * 0.866;
    poly(ctx, [[x, y], [x + b, y + a], [x, y + 2 * a], [x - b, y + a]], shade(c, 0.32)); // tapa
    poly(ctx, [[x - b, y + a], [x, y + 2 * a], [x, y + 2 * a + s], [x - b, y + a + s]], shade(c, -0.05)); // izquierda
    poly(ctx, [[x + b, y + a], [x, y + 2 * a], [x, y + 2 * a + s], [x + b, y + a + s]], shade(c, -0.35)); // derecha
  }

  /* ---------- partículas (overlay) ---------- */
  function drawParticles(ctx, kind, t, W, H, pal, seed) {
    const R = rng(seed * 31 + 7);
    const n = kind === 'confetti' ? 70 : kind === 'coins' ? 22 : kind === 'stars' ? 34 : 46;
    const colors = [pal.accent, pal.accent2, pal.hot, '#ffffff'];
    for (let i = 0; i < n; i++) {
      const x0 = R(), sp = 0.08 + R() * 0.16, ph = R(), sz = 0.6 + R() * 0.9, wob = R() * TAU, c = colors[i % 4];
      if (kind === 'coins') {
        const p = (t * sp * 1.2 + ph) % 1; // cae
        const x = x0 * W + Math.sin(t * 1.3 + wob) * W * 0.03, y = -80 + p * (H + 160), r = W * 0.028 * sz;
        const sx = Math.abs(Math.cos(t * 4 + wob)) * 0.9 + 0.1;
        ctx.save(); ctx.translate(x, y); ctx.scale(sx, 1);
        ctx.fillStyle = '#ffb800'; ctx.beginPath(); ctx.arc(0, 0, r, 0, TAU); ctx.fill();
        ctx.fillStyle = '#ffe066'; ctx.beginPath(); ctx.arc(0, 0, r * 0.78, 0, TAU); ctx.fill();
        ctx.fillStyle = '#ffb800'; ctx.fillRect(-r * 0.12, -r * 0.45, r * 0.24, r * 0.9);
        ctx.restore();
      } else if (kind === 'confetti') {
        const p = (t * sp * 1.6 + ph) % 1;
        const x = x0 * W + Math.sin(t * 2 + wob) * W * 0.04, y = -40 + p * (H + 80);
        ctx.save(); ctx.translate(x, y); ctx.rotate(t * (2 + sz * 2) + wob);
        ctx.fillStyle = c; ctx.globalAlpha = 0.9;
        ctx.fillRect(-W * 0.008 * sz, -W * 0.014 * sz, W * 0.016 * sz, W * 0.028 * sz * Math.abs(Math.cos(t * 5 + wob)));
        ctx.restore();
      } else if (kind === 'stars') {
        const tw = 0.5 + 0.5 * Math.sin(t * 3 + wob * 3);
        const x = x0 * W, y = ((ph * H) + t * sp * 30) % H, r = W * 0.012 * sz * (0.4 + tw);
        ctx.save(); ctx.translate(x, y); ctx.globalAlpha = 0.25 + tw * 0.75; ctx.fillStyle = '#fff';
        ctx.beginPath();
        for (let k = 0; k < 8; k++) { const rr = k % 2 ? r * 0.25 : r * 2; ctx.lineTo(Math.cos((k * TAU) / 8) * rr, Math.sin((k * TAU) / 8) * rr); }
        ctx.closePath(); ctx.fill(); ctx.restore();
      } else { // sparks: suben
        const p = (t * sp * 1.4 + ph) % 1;
        const x = x0 * W + Math.sin(t * 1.7 + wob) * W * 0.03, y = H + 20 - p * (H + 40), r = W * 0.007 * sz;
        ctx.globalAlpha = Math.sin(p * Math.PI) * 0.9; ctx.fillStyle = c;
        ctx.beginPath(); ctx.arc(x, y, r, 0, TAU); ctx.fill();
        ctx.globalAlpha = Math.sin(p * Math.PI) * 0.25; ctx.beginPath(); ctx.arc(x, y, r * 3, 0, TAU); ctx.fill();
      }
      ctx.globalAlpha = 1;
    }
  }

  /* ---------- fondos procedurales ---------- */
  const PROC = {};

  PROC.gradient = function (ctx, t, W, H, pal, d) {
    const a = t * 0.25 * (d.speed || 1);
    const x1 = W / 2 + Math.cos(a) * W, y1 = H / 2 + Math.sin(a) * H;
    const g = ctx.createLinearGradient(W - x1, H - y1, x1, y1);
    g.addColorStop(0, pal.bg1); g.addColorStop(1, pal.bg2);
    ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
    const R = rng((d.seed || 1) * 13);
    for (let i = 0; i < 9; i++) { // bokeh
      const x = (R() + Math.sin(t * 0.2 + i) * 0.05) * W, y = (((R() * H) - t * 40 * (0.4 + R())) % H + H) % H, r = W * (0.05 + R() * 0.12);
      const rg = ctx.createRadialGradient(x, y, 0, x, y, r);
      const c = i % 2 ? pal.accent : pal.accent2;
      rg.addColorStop(0, rgba(c, 0.28)); rg.addColorStop(1, rgba(c, 0));
      ctx.fillStyle = rg; ctx.fillRect(x - r, y - r, r * 2, r * 2);
    }
  };

  PROC.color = function (ctx, t, W, H, pal, d) { ctx.fillStyle = d.color || pal.bg1; ctx.fillRect(0, 0, W, H); };

  PROC.rays = function (ctx, t, W, H, pal, d) {
    ctx.fillStyle = pal.bg1; ctx.fillRect(0, 0, W, H);
    const cx = W / 2, cy = H * (d.cy != null ? d.cy : 0.42), n = 18, rot = t * 0.12 * (d.speed || 1), R = Math.hypot(W, H);
    ctx.fillStyle = rgba(pal.bg2, 0.9);
    for (let i = 0; i < n; i += 2) {
      const a0 = rot + (i / n) * TAU, a1 = rot + ((i + 1) / n) * TAU;
      ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(cx + Math.cos(a0) * R, cy + Math.sin(a0) * R); ctx.lineTo(cx + Math.cos(a1) * R, cy + Math.sin(a1) * R); ctx.closePath(); ctx.fill();
    }
    const rg = ctx.createRadialGradient(cx, cy, 0, cx, cy, W * 0.9);
    rg.addColorStop(0, rgba(pal.accent2, 0.55)); rg.addColorStop(0.5, rgba(pal.bg2, 0.0)); rg.addColorStop(1, rgba(pal.bg1, 0.7));
    ctx.fillStyle = rg; ctx.fillRect(0, 0, W, H);
  };

  PROC.blocks = function (ctx, t, W, H, pal, d) {
    PROC.gradient(ctx, t, W, H, pal, d);
    const R = rng((d.seed || 3) * 101);
    const cols = [pal.accent, pal.accent2, pal.hot, '#ffffff', pal.bg2];
    const n = 16;
    const items = [];
    for (let i = 0; i < n; i++) items.push({ x: R(), s: W * (0.05 + R() * 0.11), sp: 0.05 + R() * 0.1, ph: R(), c: cols[i % cols.length], z: R() });
    items.sort((a, b) => a.z - b.z);
    for (const it of items) {
      const p = (it.ph + t * it.sp * (d.speed || 1)) % 1;
      const y = H + it.s * 2 - p * (H + it.s * 4), x = it.x * W + Math.sin(t * 0.8 + it.ph * 9) * W * 0.02;
      ctx.globalAlpha = 0.35 + it.z * 0.65;
      isoCube2(ctx, x, y, it.s * (0.7 + it.z * 0.6), it.c);
    }
    ctx.globalAlpha = 1;
  };

  PROC.grid = function (ctx, t, W, H, pal, d) {
    const hor = H * 0.46, sp = d.speed || 1;
    ctx.fillStyle = vgrad(ctx, 0, hor, [[0, pal.bg1], [0.7, pal.bg2], [1, mix(pal.bg2, pal.accent2, 0.65)]]);
    ctx.fillRect(0, 0, W, hor + 2);
    const R = rng(9);
    ctx.fillStyle = '#fff';
    for (let i = 0; i < 40; i++) { const x = R() * W, y = R() * hor * 0.8, tw = 0.4 + 0.6 * Math.abs(Math.sin(t * 2 + i)); ctx.globalAlpha = 0.5 * tw; ctx.fillRect(x, y, 4, 4); }
    ctx.globalAlpha = 1;
    // sol con franjas
    const sx = W / 2, sy = hor - W * 0.06, sr = W * 0.28;
    ctx.save(); ctx.beginPath(); ctx.arc(sx, sy, sr, 0, TAU); ctx.clip();
    ctx.fillStyle = vgrad(ctx, sy - sr, sy + sr, [[0, pal.hot], [1, pal.accent2]]); ctx.fillRect(sx - sr, sy - sr, sr * 2, sr * 2);
    ctx.fillStyle = pal.bg2;
    for (let i = 0; i < 7; i++) { const yy = sy + sr * (0.0 + i * 0.15), hh = sr * (0.01 + i * 0.022); ctx.fillRect(sx - sr, yy, sr * 2, hh); }
    ctx.restore();
    // suelo
    ctx.fillStyle = vgrad(ctx, hor, H, [[0, mix(pal.bg1, '#000000', 0.2)], [1, pal.bg1]]); ctx.fillRect(0, hor, W, H - hor);
    ctx.strokeStyle = rgba(pal.accent, 0.9); ctx.lineWidth = 3;
    const N = 16, scroll = (t * 0.55 * sp) % 1;
    for (let k = 0; k < N; k++) {
      const z = (k + 1 - scroll) / N; // 0..1 lejos->cerca
      const y = hor + (H - hor) * Math.pow(z, 2.4);
      ctx.globalAlpha = 0.25 + 0.75 * z; ctx.lineWidth = 1 + z * 5;
      ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(W, y); ctx.stroke();
    }
    ctx.globalAlpha = 0.85; ctx.lineWidth = 3;
    for (let k = -14; k <= 14; k++) {
      ctx.beginPath(); ctx.moveTo(W / 2 + k * W * 0.012, hor); ctx.lineTo(W / 2 + k * W * 0.2, H); ctx.stroke();
    }
    ctx.globalAlpha = 1;
    const gl = ctx.createLinearGradient(0, hor - 30, 0, hor + 60);
    gl.addColorStop(0, rgba(pal.accent2, 0)); gl.addColorStop(0.5, rgba(pal.accent2, 0.55)); gl.addColorStop(1, rgba(pal.accent2, 0));
    ctx.fillStyle = gl; ctx.fillRect(0, hor - 30, W, 90);
  };

  // Pseudo-3D "runner" (sustituto de gameplay): pista de 3 carriles, personaje en bloques, monedas y obstáculos.
  PROC.runner = function (ctx, t, W, H, pal, d) {
    const seed = d.seed || 5, V = 3.4 * (d.speed || 1); // unidades de profundidad por segundo
    const hor = H * 0.34, K = (H - hor) * 1.0, S = W * 0.36, cx = W / 2, DP = 1.9;
    const Y = (z) => hor + K / (1 + z), XS = (X, z) => cx + (X * S) / (1 + z);
    // cielo
    ctx.fillStyle = vgrad(ctx, 0, hor, [[0, pal.bg1], [0.65, pal.bg2], [1, mix(pal.bg2, pal.accent2, 0.55)]]);
    ctx.fillRect(0, 0, W, hor + 2);
    // sol
    const sg = ctx.createRadialGradient(cx, hor - W * 0.05, 0, cx, hor - W * 0.05, W * 0.34);
    sg.addColorStop(0, rgba(pal.hot, 0.95)); sg.addColorStop(0.35, rgba(pal.accent2, 0.35)); sg.addColorStop(1, rgba(pal.accent2, 0));
    ctx.fillStyle = sg; ctx.fillRect(0, 0, W, hor + 4);
    // skyline de bloques con parallax
    const R0 = rng(seed * 17);
    for (let layer = 0; layer < 2; layer++) {
      const sp = (layer ? 0.03 : 0.015), col = layer ? shade(pal.bg2, -0.45) : shade(pal.bg2, -0.2);
      for (let i = 0; i < 18; i++) {
        const w = W * (0.05 + R0() * 0.08), h = H * (0.03 + R0() * (layer ? 0.1 : 0.07)), x0 = R0() * W * 1.2;
        const x = (((x0 - t * W * sp) % (W * 1.2)) + W * 1.2) % (W * 1.2) - W * 0.1;
        ctx.fillStyle = col; ctx.fillRect(x, hor - h, w, h + 2);
        ctx.fillStyle = rgba(pal.accent, 0.3);
        for (let wy = 0; wy < 3; wy++) ctx.fillRect(x + w * 0.2, hor - h + h * 0.2 + wy * h * 0.25, w * 0.15, h * 0.07);
      }
    }
    // suelo y pista
    ctx.fillStyle = shade(pal.bg1, -0.3); ctx.fillRect(0, hor, W, H - hor);
    const BAND = 1.5, FAR = 30;
    const off = (t * V) % (BAND * 2);
    for (let b = -2; b < FAR / BAND + 2; b++) {
      const z0 = Math.max(-0.2, b * BAND - off), z1 = Math.min(FAR, (b + 1) * BAND - off);
      if (z1 <= z0) continue;
      const c = (b & 1) ? shade(mix(pal.bg2, pal.bg1, 0.5), 0.02) : shade(mix(pal.bg2, pal.bg1, 0.5), 0.12);
      poly(ctx, [[XS(-1.55, z0), Y(z0)], [XS(1.55, z0), Y(z0)], [XS(1.55, z1), Y(z1)], [XS(-1.55, z1), Y(z1)]], c);
    }
    // rieles neón
    for (const sgn of [-1, 1]) {
      poly(ctx, [[XS(sgn * 1.5, -0.2), Y(-0.2)], [XS(sgn * 1.62, -0.2), Y(-0.2)], [XS(sgn * 1.62, FAR), Y(FAR)], [XS(sgn * 1.5, FAR), Y(FAR)]], sgn < 0 ? pal.accent : pal.accent2);
    }
    // líneas de carril (dashes)
    const DA = 1.6, offD = (t * V) % DA;
    ctx.fillStyle = 'rgba(255,255,255,0.55)';
    for (const X of [-0.5, 0.5]) for (let k = -1; k < FAR / DA + 1; k++) {
      const z0 = Math.max(-0.2, k * DA - offD), z1 = k * DA - offD + DA * 0.5;
      if (z1 <= z0) continue;
      const hw = 0.03;
      poly(ctx, [[XS(X - hw, z0), Y(z0)], [XS(X + hw, z0), Y(z0)], [XS(X + hw, z1), Y(z1)], [XS(X - hw, z1), Y(z1)]], 'rgba(255,255,255,0.55)');
    }
    // trayectoria del jugador
    const SEG = 1.15, R1 = rng(seed * 7 + 3);
    const lanes = []; for (let i = 0; i < 80; i++) lanes.push([-1, 0, 1][Math.floor(R1() * 3)]);
    const sstep = (x) => x * x * (3 - 2 * x);
    const px = (tt) => {
      const k = Math.max(0, Math.floor(tt / SEG)), a = lanes[k % 80], b = lanes[(k + 1) % 80];
      return lerp(a, b, sstep(seg(tt, (k + 1) * SEG - 0.3, (k + 1) * SEG)));
    };
    // items por filas
    const ROW = 0.5, items = [];
    const r0 = Math.floor((t - 0.5) / ROW), r1 = Math.ceil((t + (FAR - DP) / V) / ROW);
    for (let r = r0; r <= r1; r++) {
      const tp = r * ROW, RR = rng(seed * 1009 + r * 7919 + 11), x = px(tp), stable = Math.abs(x - Math.round(x)) < 0.02;
      const kind = RR();
      const z = DP - 1 + (tp - t) * V; // profundidad "z" (d-1)
      if (z < -0.35 || z > FAR) continue;
      if (kind < 0.62) items.push({ type: 'coin', X: x, z, tp });
      else if (stable && kind < 0.82) { // obstáculo en otro carril
        const alts = [-1, 0, 1].filter((l) => Math.abs(l - x) > 0.9); items.push({ type: 'block', X: alts[Math.floor(RR() * alts.length)], z, tp, h: 0.5 + RR() * 0.8, c: [pal.hot, pal.accent2, '#ff5c5c'][Math.floor(RR() * 3)] });
      } else if (stable && kind < 0.9) items.push({ type: 'hurdle', X: x, z, tp });
    }
    // salto
    let jump = 0;
    for (const it of items) if (it.type === 'hurdle') { const q = (t - (it.tp - 0.28)) / 0.56; if (q > 0 && q < 1) jump = Math.max(jump, Math.sin(q * Math.PI)); }
    items.sort((a, b) => b.z - a.z);
    const zp = DP - 1, charX = px(t);
    const drawItem = (it) => {
      const sc = S / (1 + it.z), y = Y(it.z), x = XS(it.X, it.z);
      if (it.type === 'coin') {
        if (it.z < zp && Math.abs(it.X - charX) < 0.6) return; // recogida
        const rr = sc * 0.2, sx = Math.abs(Math.cos(t * 5 + it.tp * 3)) * 0.85 + 0.15;
        ctx.save(); ctx.translate(x, y - sc * 0.4); ctx.scale(sx, 1);
        ctx.fillStyle = 'rgba(0,0,0,0.25)'; ctx.beginPath(); ctx.ellipse(0, sc * 0.4, rr, rr * 0.3, 0, 0, TAU); ctx.fill();
        ctx.fillStyle = '#e09a00'; ctx.beginPath(); ctx.arc(0, 0, rr, 0, TAU); ctx.fill();
        ctx.fillStyle = '#ffd23f'; ctx.beginPath(); ctx.arc(0, 0, rr * 0.8, 0, TAU); ctx.fill();
        ctx.fillStyle = '#fff3b0'; ctx.fillRect(-rr * 0.1, -rr * 0.42, rr * 0.2, rr * 0.84);
        ctx.restore();
      } else if (it.type === 'block') {
        cube(ctx, x, y, sc * 0.78, sc * it.h * 1.1, it.c);
      } else { // hurdle
        ctx.fillStyle = 'rgba(0,0,0,0.25)'; ctx.fillRect(x - sc * 0.46, y - sc * 0.03, sc * 0.92, sc * 0.06);
        cube(ctx, x, y, sc * 0.9, sc * 0.3, '#ff8a3d');
      }
    };
    let drewPlayer = false;
    const drawPlayer = () => {
      drewPlayer = true;
      const sc = S / (1 + zp), y0 = Y(zp), x = XS(charX, zp), jy = -jump * sc * 0.75;
      const ph = t * 11;
      ctx.fillStyle = 'rgba(0,0,0,0.3)'; ctx.beginPath(); ctx.ellipse(x, y0, sc * 0.3 * (1 - jump * 0.3), sc * 0.08, 0, 0, TAU); ctx.fill();
      const lw = sc * 0.14, lh = sc * 0.42, bw = sc * 0.46, bh = sc * 0.5, hs = sc * 0.36, yy = y0 + jy;
      const swing = jump > 0 ? 0.6 : Math.sin(ph);
      const body = pal.accent2, legc = shade(pal.bg1, 0.25), skin = '#f2c18d';
      // piernas
      ctx.fillStyle = legc; ctx.fillRect(x - bw * 0.35, yy - lh - swing * lh * 0.15, lw, lh + swing * lh * 0.3);
      ctx.fillRect(x + bw * 0.35 - lw, yy - lh + swing * lh * 0.15, lw, lh - swing * lh * 0.3);
      // torso
      const ty = yy - lh - bh;
      ctx.fillStyle = body; ctx.fillRect(x - bw / 2, ty, bw, bh);
      ctx.fillStyle = 'rgba(255,255,255,0.18)'; ctx.fillRect(x - bw / 2, ty, bw, bh * 0.18);
      // brazos
      ctx.fillStyle = skin; const aw = sc * 0.12;
      ctx.fillRect(x - bw / 2 - aw, ty + bh * 0.05 + (jump > 0 ? -bh * 0.3 : -swing * bh * 0.2), aw, bh * 0.7);
      ctx.fillRect(x + bw / 2, ty + bh * 0.05 + (jump > 0 ? -bh * 0.3 : swing * bh * 0.2), aw, bh * 0.7);
      // cabeza
      ctx.fillStyle = skin; ctx.fillRect(x - hs / 2, ty - hs, hs, hs);
      ctx.fillStyle = '#2b1b17'; ctx.fillRect(x - hs / 2, ty - hs, hs, hs * 0.28);
      ctx.fillStyle = '#1a1a1a'; ctx.fillRect(x - hs * 0.22, ty - hs * 0.55, hs * 0.1, hs * 0.14); ctx.fillRect(x + hs * 0.12, ty - hs * 0.55, hs * 0.1, hs * 0.14);
    };
    for (const it of items) { if (!drewPlayer && it.z <= zp) drawPlayer(); drawItem(it); }
    if (!drewPlayer) drawPlayer();
    // niebla en el horizonte
    const fg = ctx.createLinearGradient(0, hor - 20, 0, hor + H * 0.12);
    fg.addColorStop(0, rgba(pal.bg2, 0.0)); fg.addColorStop(0.3, rgba(mix(pal.bg2, pal.accent2, 0.5), 0.45)); fg.addColorStop(1, rgba(pal.bg2, 0));
    ctx.fillStyle = fg; ctx.fillRect(0, hor - 20, W, H * 0.12 + 20);
  };

  /* ---------- capa de fondo ---------- */
  // desc: {type, src?, frames?, seed, speed, particles, scrim, kenburns, fit}
  VP.createBg = function (desc, W, H, pal) {
    const root = document.createElement('div');
    root.className = 'bg';
    const type = desc.type || 'gradient';
    let base, ctx = null, img = null, lastSrc = null;
    if (type === 'image' || type === 'video') {
      img = document.createElement('img');
      img.className = 'bg-media';
      img.decoding = 'sync';
      root.appendChild(img);
      base = img;
    } else {
      base = document.createElement('canvas');
      base.width = W; base.height = H; base.className = 'bg-canvas';
      ctx = base.getContext('2d');
      root.appendChild(base);
    }
    let fx = null, fctx = null;
    if (desc.particles) {
      fx = document.createElement('canvas'); fx.width = W; fx.height = H; fx.className = 'bg-canvas';
      fctx = fx.getContext('2d'); root.appendChild(fx);
    }
    const scrim = document.createElement('div');
    scrim.className = 'bg-scrim';
    const s = desc.scrim != null ? desc.scrim : (type === 'video' || type === 'image' ? 0.28 : 0.12);
    scrim.style.background = `radial-gradient(ellipse at 50% 45%, rgba(0,0,0,0) 35%, rgba(0,0,0,0.5) 100%), linear-gradient(rgba(0,0,0,${s}),rgba(0,0,0,${s}))`;
    root.appendChild(scrim);

    return {
      el: root,
      // lt: tiempo local de la escena; beat: {bpm,offset,amp}; abs: tiempo absoluto
      update(lt, dur, abs, beat) {
        const T = (desc.tOffset || 0) + lt;
        let pulse = 0;
        if (beat && beat.bpm && beat.amp) {
          const ph = (((abs - (beat.offset || 0)) * beat.bpm) / 60) % 1;
          pulse = beat.amp * Math.exp(-ph * 7);
        }
        const punch = desc.punch ? desc.punch * Math.exp(-lt * 9) : 0;
        let scale = 1 + pulse + punch, tx = 0;
        let p = null;
        if (ctx) {
          ctx.clearRect(0, 0, W, H);
          (PROC[type] || PROC.gradient)(ctx, T, W, H, pal, desc);
        } else if (type === 'image') {
          const k = desc.kenburns !== false ? lerp(1.0, desc.zoom || 1.14, E.inOutQ(clamp(lt / Math.max(dur, 0.01)))) : 1;
          scale *= k; tx = desc.kenburns !== false ? lerp(-0.012, 0.012, clamp(lt / Math.max(dur, 0.01))) * W : 0;
          if (lastSrc !== desc.src) { lastSrc = desc.src; img.src = desc.src; p = img.decode().catch(() => {}); }
        } else if (type === 'video') {
          const fr = desc.frames; // {pattern, count}
          let idx = Math.floor(T * fr.fps * (desc.speed || 1)) + (desc.startFrame || 0);
          if (desc.loop === false) idx = Math.min(idx, fr.count - 1);
          else if (desc.pingpong) { const m = fr.count - 1 || 1, q = idx % (2 * m); idx = q <= m ? q : 2 * m - q; }
          else idx = idx % fr.count;
          const src = fr.pattern.replace('%06d', String(idx + 1).padStart(6, '0'));
          if (lastSrc !== src) { lastSrc = src; img.src = src; p = img.decode().catch(() => {}); }
          if (desc.zoom) scale *= lerp(1, desc.zoom, clamp(lt / Math.max(dur, 0.01)));
        }
        base.style.transform = `translate(${tx.toFixed(1)}px,0) scale(${scale.toFixed(4)})`;
        if (fctx) { fctx.clearRect(0, 0, W, H); drawParticles(fctx, desc.particles, T, W, H, pal, desc.seed || 1); }
        return p;
      },
    };
  };
})();
