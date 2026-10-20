"""Patrones procedurales vectorizados (numpy). Todos son ORIGINALES (matematicos).

Convencion: cada patron recibe una rejilla de coordenadas en pixeles
  U (horizontal, periodica con periodo C) y V (vertical, 0..H)
y devuelve un array float (h, w, 3) en 0..255.
Todos los tamanos se dan en pixeles y se "ajustan" para que un numero entero de
periodos encaje en C (y en H si wrap_v=True) -> el patron da la vuelta al
cilindro (torso / brazo / pierna) sin costura.
"""
from __future__ import annotations

import numpy as np

# ----------------------------------------------------------------- utilidades

def _smooth(t):
    return t * t * (3.0 - 2.0 * t)


def fit(size_px: float, total: float) -> int:
    """Numero entero de periodos de ~size_px que caben exactamente en total."""
    return max(1, int(round(total / max(1.0, size_px))))


def periodic_noise(U, V, C, H, cells_u, cells_v, seed, wrap_v=False):
    """Value-noise en [0,1], periodico en U (periodo C) y opcionalmente en V."""
    rng = np.random.default_rng(seed)
    rows = cells_v if wrap_v else cells_v + 2
    lat = rng.random((rows, cells_u))
    gu = (U / C) * cells_u
    gv = (V / H) * cells_v
    iu = np.floor(gu).astype(int)
    fu = _smooth(gu - iu)
    iv = np.floor(gv).astype(int)
    fv = _smooth(gv - iv)
    iu0, iu1 = iu % cells_u, (iu + 1) % cells_u
    if wrap_v:
        iv0, iv1 = iv % cells_v, (iv + 1) % cells_v
    else:
        iv0 = np.clip(iv, 0, cells_v)
        iv1 = iv0 + 1
    a, b = lat[iv0, iu0], lat[iv0, iu1]
    c, d = lat[iv1, iu0], lat[iv1, iu1]
    return (a * (1 - fu) + b * fu) * (1 - fv) + (c * (1 - fu) + d * fu) * fv


def fractal(U, V, C, H, cell_px, seed, octaves=4, wrap_v=False, persistence=0.5):
    cu = fit(cell_px, C)
    cv = fit(cell_px, H)
    total, amp, norm = 0.0, 1.0, 0.0
    for o in range(octaves):
        total = total + amp * periodic_noise(U, V, C, H, cu * 2 ** o, cv * 2 ** o,
                                             seed + 101 * o, wrap_v)
        norm += amp
        amp *= persistence
    n = total / norm
    # estira el contraste (el value-noise sumado se agrupa cerca de 0.5)
    return np.clip((n - 0.5) * 2.2 + 0.5, 0, 1)


def pal_arr(pal):
    return np.array(pal, dtype=np.float64)


def ramp(t, pal, cyclic=True):
    """Interpola suavemente por la paleta con t en [0,1]."""
    p = pal_arr(pal)
    n = len(p)
    t = np.asarray(t, dtype=np.float64)
    if cyclic:
        x = (t % 1.0) * n
        i0 = np.floor(x).astype(int) % n
        i1 = (i0 + 1) % n
    else:
        x = np.clip(t, 0, 1) * (n - 1)
        i0 = np.minimum(np.floor(x).astype(int), n - 2) if n > 1 else np.zeros_like(x, int)
        i1 = np.minimum(i0 + 1, n - 1)
    f = (x - np.floor(x))[..., None] if cyclic else (x - i0)[..., None]
    return p[i0] * (1 - f) + p[i1] * f


def pick(idx, pal):
    p = pal_arr(pal)
    return p[np.asarray(idx).astype(int) % len(p)]


def _hash2(ix, iy, seed):
    """Hash entero determinista -> float [0,1)."""
    h = (ix.astype(np.int64) * 374761393 + iy.astype(np.int64) * 668265263 + seed * 2246822519) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    h = h ^ (h >> 16)
    return (h & 0xFFFFFF) / float(0x1000000)


# -------------------------------------------------------------------- patrones

def solid(U, V, C, H, pal, seed=0, **kw):
    out = np.empty(U.shape + (3,))
    out[...] = pal_arr(pal)[0]
    return out


def stripes(U, V, C, H, pal, seed=0, orient="v", size=24, wrap_v=False, **kw):
    """Rayas. orient: v (verticales), h (horizontales), d (diagonal 45), d2 (diagonal inversa)."""
    n = len(pal)
    if orient == "h":
        k = fit(size, H) if wrap_v else None
        period = (H / k) if k else size
        idx = np.floor(V / period)
        return pick(idx, pal)
    count = fit(size, C)
    count = max(n, int(round(count / n)) * n)  # multiplo de n: la secuencia de colores cierra al dar la vuelta
    phase = count * U / C
    if orient in ("d", "d2"):
        period_px = C / count
        j = (H / period_px)
        j = max(1, round(j))
        sign = 1 if orient == "d" else -1
        phase = phase + sign * j * V / H
    return pick(np.floor(phase + 1e-4), pal)  # eps: evita parpadeos de redondeo justo en el borde


def gradient(U, V, C, H, pal, seed=0, axis="v", noise=0.12, bands=0, wrap_v=False, **kw):
    """Degradado (ombre). axis v: arriba->abajo; u: ida y vuelta alrededor del cilindro."""
    if axis == "u":
        t = 0.5 - 0.5 * np.cos(2 * np.pi * U / C)
    else:
        t = 0.5 - 0.5 * np.cos(2 * np.pi * V / H) if wrap_v else V / H
    if noise:
        t = t + (fractal(U, V, C, H, 40, seed, 3, wrap_v) - 0.5) * noise
    if bands:
        t = np.floor(np.clip(t, 0, 0.9999) * bands) / max(1, bands - 1)
    return ramp(t, pal, cyclic=False)


def tiedye(U, V, C, H, pal, seed=0, centers=4, ring=15, warp=0.9, wrap_v=False, edge=0.35, **kw):
    """Tie-dye: anillos concentricos (bullseye) deformados por ruido; ring = ancho de cada color (px).

    edge = anchura de la transicion entre colores (0 = bordes duros, 1 = degradado suave).
    """
    rng = np.random.default_rng(seed)
    n1 = fractal(U, V, C, H, 70, seed + 1, 3, wrap_v)
    n2 = fractal(U, V, C, H, 70, seed + 2, 3, wrap_v)
    Uw = (U + (n1 - 0.5) * warp * ring * 5.0) % C
    Vw = V + (n2 - 0.5) * warp * ring * 5.0
    d = np.full(U.shape, 1e9)
    for _ in range(centers):
        cx = rng.uniform(0, C)
        cy = rng.uniform(0, H)
        du = np.abs(Uw - cx)
        du = np.minimum(du, C - du)
        dv = Vw - cy
        if wrap_v:
            dv = np.abs(dv) % H
            dv = np.minimum(dv, H - dv)
        d = np.minimum(d, np.hypot(du, dv))
    x = d / ring                      # cada unidad = un color
    i = np.floor(x)
    f = x - i
    # mantiene el color en el centro de la banda y transiciona en el borde (edge)
    w = max(1e-3, float(edge))
    t = np.clip((f - (1 - w) / 2) / w, 0, 1)
    t = t * t * (3 - 2 * t)
    p = pal_arr(pal)
    n = len(p)
    c0 = p[i.astype(int) % n]
    c1 = p[(i.astype(int) + 1) % n]
    # la transicion ocurre en la mitad superior de la banda hacia el siguiente color
    return c0 * (1 - t[..., None]) + c1 * t[..., None]


_Q_CACHE = {}


def _noise_threshold(q: float) -> float:
    """Cuantil q de fractal() medido una vez sobre una muestra grande y fija (reproducible)."""
    if "tab" not in _Q_CACHE:
        u = np.arange(768, dtype=np.float64) + 0.5
        U, V = np.meshgrid(u, u)
        n = np.concatenate([fractal(U, V, 768.0, 768.0, 52, sd, 3, True).ravel() for sd in (1, 2, 3)])
        qs = np.linspace(0, 1, 101)
        _Q_CACHE["tab"] = (qs, np.quantile(n, qs))
    qs, vals = _Q_CACHE["tab"]
    return float(np.interp(q, qs, vals))


def camo(U, V, C, H, pal, seed=0, cell=52, block=0, wrap_v=False, **kw):
    """Camuflaje de manchas organicas. pal[0]=fondo, el resto = capas. block>0 -> pixelado."""
    if block:
        U = (np.floor(U / block) + 0.5) * block
        V = (np.floor(V / block) + 0.5) * block
    out = np.empty(U.shape + (3,))
    out[...] = pal_arr(pal)[0]
    layers = pal[1:]
    cover = np.linspace(0.44, 0.24, len(layers)) if layers else []   # fraccion que pinta cada capa
    for i, col in enumerate(layers):
        n = fractal(U, V, C, H, cell, seed + 31 * (i + 1), 3, wrap_v)
        out[n > _noise_threshold(1.0 - cover[i])] = col   # umbral FIJO (no depende del tamano de la rejilla)
    return out


def checks(U, V, C, H, pal, seed=0, size=32, wrap_v=False, **kw):
    nu = fit(size, C)
    nu += nu % 2  # par -> alterna bien al cerrar el cilindro
    cell = C / nu
    iu = np.floor(U / cell)
    iv = np.floor(V / cell)
    return pick((iu + iv) % 2, pal[:2] if len(pal) >= 2 else pal)


def diamonds(U, V, C, H, pal, seed=0, size=48, wrap_v=False, **kw):
    """Rombos tipo argyle (4 colores de la paleta)."""
    nu = fit(size, C)
    nu += nu % 2
    cell = C / nu
    s, t = U / cell, V / cell
    a = np.floor(s + t + 1e-4) % 2
    b = np.floor(s - t + 1e-4) % 2
    return pick(a * 2 + b, pal)


def chevron(U, V, C, H, pal, seed=0, size=32, band=18, wrap_v=False, **kw):
    """Zigzag / chevron en bandas."""
    nu = fit(size, C)
    if wrap_v:
        k = fit(band, H)
        k = max(len(pal), int(round(k / len(pal))) * len(pal))
        band = H / k
    ph = (nu * U / C) % 1.0
    tri = np.abs(2 * ph - 1)  # 0..1..0 periodico
    idx = np.floor((V + tri * band) / band)
    return pick(idx, pal)


def dots(U, V, C, H, pal, seed=0, size=28, radius=0.28, wrap_v=False, **kw):
    """Lunares en red hexagonal. pal[0]=fondo, pal[1]=lunar (pal[2] alterna filas si existe)."""
    nu = fit(size, C)
    cell = C / nu
    if wrap_v:
        m = max(1, len(pal) - 1)
        step = int(np.lcm(2, m))  # filas multiplo de 2 (escalonado) y del ciclo de colores
        rows = max(step, int(round(fit(cell, H) / step)) * step)
        cell_v = H / rows
    else:
        cell_v = cell
    row = np.floor(V / cell_v)
    s = U / cell + 0.5 * (row % 2)
    fx = (s % 1.0) - 0.5
    fy = ((V / cell_v) % 1.0) - 0.5
    inside = np.hypot(fx * cell, fy * cell_v) < radius * cell
    out = np.empty(U.shape + (3,))
    out[...] = pal_arr(pal)[0]
    dot_col = pal_arr(pal)[1:] if len(pal) > 1 else pal_arr(pal)
    pick_i = (row % len(dot_col)).astype(int)
    out[inside] = dot_col[pick_i[inside]]
    return out


def triangles(U, V, C, H, pal, seed=0, size=40, jitter=0.12, wrap_v=False, **kw):
    """Mosaico 'low-poly' de triangulos con colores de la paleta."""
    nu = fit(size, C)
    cell = C / nu
    cell_v = (H / fit(cell, H)) if wrap_v else cell
    rows = fit(cell, H) if wrap_v else 10 ** 6
    s, t = U / cell, V / cell_v
    ix, iy = np.floor(s).astype(int), np.floor(t).astype(int)
    iy = iy % rows
    fx, fy = s - ix, t - np.floor(t)
    tri = ((fx + fy) > 1.0).astype(int)
    key_x = (ix % nu) * 2 + tri
    h = _hash2(key_x, iy, seed)
    col = pick(np.floor(h * len(pal) * 1.0), pal)
    shade = 1.0 + (_hash2(key_x + 7, iy + 3, seed + 5) - 0.5) * 2 * jitter
    return col * shade[..., None]


def waves(U, V, C, H, pal, seed=0, size=16, amp=9, freq=0, wrap_v=False, **kw):
    """Ondas horizontales (olas)."""
    nu = fit(size * 4, C) if not freq else int(freq)
    if wrap_v:
        k = fit(size, H)
        k = max(len(pal), int(round(k / len(pal))) * len(pal))
        size = H / k
    phase = (V + amp * np.sin(2 * np.pi * nu * U / C)) / size
    return pick(np.floor(phase), pal)


def gingham(U, V, C, H, pal, seed=0, size=24, wrap_v=False, **kw):
    """Cuadros vichy (pal[0]=base, pal[1]=color)."""
    nu = fit(size, C)
    nu += nu % 2
    cell = C / nu
    a = np.floor(U / cell) % 2
    b = np.floor(V / cell) % 2
    p0, p1 = pal_arr(pal)[0], pal_arr(pal)[1 % len(pal)]
    mid = (p0 + p1) / 2
    idx = (a + b).astype(int)
    out = np.empty(U.shape + (3,))
    out[idx == 0] = p0
    out[idx == 1] = mid
    out[idx == 2] = p1
    return out


def speckle(U, V, C, H, pal, seed=0, density=0.10, wrap_v=False, **kw):
    """Fondo pal[0] con motitas de las demas (tipo 'terrazo')."""
    out = np.empty(U.shape + (3,))
    out[...] = pal_arr(pal)[0]
    b = 4
    ix, iy = np.floor(U / b).astype(int), np.floor(V / b).astype(int)
    nu = int(C // b)
    if wrap_v:
        iy = iy % int(H // b)
    h = _hash2(ix % nu, iy, seed)
    m = h < density
    out[m] = pick(np.floor(_hash2(ix % nu + 5, iy + 9, seed) * len(pal)), pal)[m]
    return out


def _lum(c):
    r, g, b = c
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


TWO_COLOR = {"checks", "gingham"}
BG_PLUS_ACCENTS = {"dots", "speckle"}


def prep_palette(name, pal):
    """Reordena la paleta para que los patrones de 2 colores tengan contraste legible.

    checks/gingham: el par con mayor diferencia de luminancia pasa a ser (0, 1).
    dots/speckle: el fondo es el color extremo (mas oscuro o mas claro) y los acentos
    se ordenan por contraste decreciente contra el fondo.
    """
    pal = list(pal)
    if name in TWO_COLOR and len(pal) > 2:
        best = max(((i, j) for i in range(len(pal)) for j in range(i + 1, len(pal))),
                   key=lambda ij: abs(_lum(pal[ij[0]]) - _lum(pal[ij[1]])))
        rest = [c for k, c in enumerate(pal) if k not in best]
        return [pal[best[0]], pal[best[1]]] + rest
    if name in BG_PLUS_ACCENTS and len(pal) > 2:
        lums = [_lum(c) for c in pal]
        bg_i = lums.index(min(lums)) if (sum(lums) / len(lums)) > 110 else lums.index(max(lums))
        bg = pal[bg_i]
        acc = sorted((c for k, c in enumerate(pal) if k != bg_i), key=lambda c: -abs(_lum(c) - _lum(bg)))
        return [bg] + acc
    return pal


PATTERNS = {
    "solid": solid, "stripes": stripes, "gradient": gradient, "tiedye": tiedye,
    "camo": camo, "checks": checks, "diamonds": diamonds, "chevron": chevron,
    "dots": dots, "triangles": triangles, "waves": waves, "gingham": gingham,
    "speckle": speckle,
}


def render_pattern(name, pal, C, H, origin_u=0.0, seed=0, grain=2.0, wrap_v=False, **params):
    """Renderiza un patron sobre una rejilla (H x C) y devuelve uint8 (H, C, 3)."""
    if name not in PATTERNS:
        raise KeyError(f"patron desconocido {name!r}. Opciones: {sorted(PATTERNS)}")
    C_i, H_i = int(C), int(H)
    u = np.arange(C_i, dtype=np.float64) + 0.5
    v = np.arange(H_i, dtype=np.float64) + 0.5
    U, V = np.meshgrid(u + origin_u, v)
    U = U % C
    pal = prep_palette(name, pal)
    rgb = PATTERNS[name](U, V, float(C), float(H), pal, seed=seed, wrap_v=wrap_v, **params)
    if grain:
        # grano de tela periodico en u: ruido determinista por pixel
        g = _hash2((U - 0.5).astype(int) % C_i, (V - 0.5).astype(int), seed + 99) - 0.5
        rgb = rgb + g[..., None] * 2 * grain
    return np.clip(rgb, 0, 255).astype(np.uint8)
