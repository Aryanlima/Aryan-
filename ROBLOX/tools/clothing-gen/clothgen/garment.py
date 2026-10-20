"""Compone texturas de camisa / pantalon / camiseta (T-shirt) y teselas seamless."""
from __future__ import annotations

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from . import layout as L
from .palettes import get_palette, hex_to_rgb
from .patterns import render_pattern

# Parametros de diseno propios (NO son medidas oficiales; son decisiones de estilo)
DEFAULT_SLEEVE_LEN = 56   # px desde el hombro para manga corta
DEFAULT_SHORTS_LEN = 64   # px desde la cintura para shorts
CUFF_H = 10
HEM_H = 10


def _font(size: int, font_path: str | None = None):
    if font_path:
        return ImageFont.truetype(font_path, size)
    return ImageFont.load_default(size=size)  # Pillow >= 10.1 (fuente integrada, escalable)


def draw_text_layer(w, h, text, color="#ffffff", outline="#000000", size=None,
                    y_frac=0.5, font_path=None, margin=8, outline_w=2):
    """Capa RGBA (w x h) con el texto centrado y autoajustado."""
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    s = size or 64
    while s > 6:
        f = _font(s, font_path)
        bb = d.textbbox((0, 0), text, font=f, stroke_width=outline_w if outline else 0)
        if bb[2] - bb[0] <= w - 2 * margin and bb[3] - bb[1] <= h - 2 * margin:
            break
        s -= 2
    bw, bh = bb[2] - bb[0], bb[3] - bb[1]
    x = (w - bw) / 2 - bb[0]
    y = h * y_frac - bh / 2 - bb[1]
    d.text((x, y), text, font=f, fill=hex_to_rgb(color) + (255,),
           stroke_width=outline_w if outline else 0,
           stroke_fill=(hex_to_rgb(outline) + (255,)) if outline else None)
    return layer


def _rgba(rgb, alpha=None):
    h, w = rgb.shape[:2]
    out = np.zeros((h, w, 4), np.uint8)
    out[..., :3] = rgb
    out[..., 3] = 255 if alpha is None else alpha
    return out


def render_clothing(kind: str, spec: dict) -> Image.Image:
    """kind: 'shirt' | 'pants'. Devuelve un PNG RGBA 585x559.

    spec keys (todas opcionales salvo pattern/palette):
      pattern, palette (nombre o lista hex), seed, params (dict del patron),
      palette2/pattern2 + split ('none'|'yoke'): no implementado (reservado)
      sleeve: 'long'|'short'|'sleeveless' (camisa)   | length: 'long'|'shorts' (pantalon)
      torso_coverage: 0..1 (pantalon: fraccion inferior del torso que se pinta)
      hem: '#hex' | cuff: '#hex' | collar: '#hex'
      text: {"front": "..", "back": ".."} y text_style {color, outline, size, y}
    """
    W, H = L.CANVAS
    canvas = np.zeros((H, W, 4), np.uint8)
    pal = get_palette(spec.get("palette", "mono"))
    name = spec.get("pattern", "stripes")
    seed = int(spec.get("seed", 0))
    params = dict(spec.get("params", {}))
    grain = spec.get("grain", 2.0)

    sleeve = spec.get("sleeve", "long") if kind == "shirt" else None
    length = spec.get("length", "long") if kind == "pants" else None
    coverage = float(spec.get("torso_coverage", 1.0))
    hem = spec.get("hem")
    cuff = spec.get("cuff")
    collar = spec.get("collar")

    for part, faces in L.PARTS.items():
        order, C, Hh = L.belt_geometry(part)
        rgb = render_pattern(name, pal, C, Hh, seed=seed, grain=grain, **params)
        alpha = np.full((Hh, C), 255, np.uint8)

        if part == "torso":
            if hem:
                rgb[Hh - HEM_H:, :, :] = hex_to_rgb(hem)
            if collar:
                rgb[:8, :, :] = hex_to_rgb(collar)
            if kind == "pants" and coverage < 1.0:
                alpha[: int(round(Hh * (1.0 - coverage))), :] = 0
        else:
            if kind == "shirt":
                if sleeve == "short":
                    alpha[DEFAULT_SLEEVE_LEN:, :] = 0
                    if cuff:
                        rgb[DEFAULT_SLEEVE_LEN - CUFF_H: DEFAULT_SLEEVE_LEN, :, :] = hex_to_rgb(cuff)
                elif sleeve == "sleeveless":
                    alpha[:, :] = 0
                elif cuff:
                    rgb[Hh - CUFF_H:, :, :] = hex_to_rgb(cuff)
            else:  # pants
                if length == "shorts":
                    alpha[DEFAULT_SHORTS_LEN:, :] = 0
                    if cuff:
                        rgb[DEFAULT_SHORTS_LEN - CUFF_H: DEFAULT_SHORTS_LEN, :, :] = hex_to_rgb(cuff)
                elif cuff:
                    rgb[Hh - CUFF_H:, :, :] = hex_to_rgb(cuff)

        belt = _rgba(rgb, alpha)
        x0 = 0
        for f in order:
            fx, fy, fw, fh = faces[f]
            canvas[fy:fy + fh, fx:fx + fw] = belt[:, x0:x0 + fw]
            x0 += fw

        # Tapas (up/down): patron plano; 'up' de torso = cuello (opcional)
        for f in ("up", "down"):
            fx, fy, fw, fh = faces[f]
            cap = render_pattern(name, pal, fw, fh, seed=seed + 7, grain=grain, **params)
            a = np.full((fh, fw), 255, np.uint8)
            if part == "torso" and f == "up" and collar:
                cap[:] = hex_to_rgb(collar)
            if part != "torso" and f == "down":
                if (kind == "shirt" and sleeve in ("short", "sleeveless")) or (kind == "pants" and length == "shorts"):
                    a[:] = 0
            if part != "torso" and f == "up" and kind == "shirt" and sleeve == "sleeveless":
                a[:] = 0
            if part == "torso" and f == "down" and kind == "shirt":
                pass
            if kind == "pants" and part == "torso" and f == "up" and coverage < 1.0:
                a[:] = 0
            canvas[fy:fy + fh, fx:fx + fw] = _rgba(cap, a)

    img = Image.fromarray(canvas, "RGBA")

    # Texto (solo torso frente / espalda)
    txt = spec.get("text") or {}
    st = spec.get("text_style", {})
    for face, key in (("front", "front"), ("back", "back")):
        if txt.get(key):
            fx, fy, fw, fh = L.TORSO[face]
            layer = draw_text_layer(fw, fh, txt[key], color=st.get("color", "#ffffff"),
                                    outline=st.get("outline", "#000000"), size=st.get("size"),
                                    y_frac=st.get("y", 0.38), font_path=st.get("font"))
            region = img.crop((fx, fy, fx + fw, fy + fh))
            region.alpha_composite(layer)
            img.paste(region, (fx, fy))
    return img


# ------------------------------------------------------------- T-shirt (512x512)

def _shape_mask(shape: str, size=512, margin=36):
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    r = (margin, margin, size - margin, size - margin)
    c = size / 2
    if shape == "circle":
        d.ellipse(r, fill=255)
    elif shape == "rounded":
        d.rounded_rectangle(r, radius=70, fill=255)
    elif shape == "diamond":
        d.polygon([(c, margin), (size - margin, c), (c, size - margin), (margin, c)], fill=255)
    elif shape == "hexagon":
        import math
        rad = (size - 2 * margin) / 2
        pts = [(c + rad * math.cos(math.radians(60 * i + 30)), c + rad * math.sin(math.radians(60 * i + 30)))
               for i in range(6)]
        d.polygon(pts, fill=255)
    else:
        raise KeyError(f"forma desconocida: {shape}")
    return m


def render_tshirt(spec: dict) -> Image.Image:
    """Camiseta/grafico: 512x512 RGBA, insignia con patron + texto. Fondo transparente."""
    W, H = L.TSHIRT_SIZE
    pal = get_palette(spec.get("palette", "mono"))
    rgb = render_pattern(spec.get("pattern", "stripes"), pal, W, H, seed=int(spec.get("seed", 0)),
                         grain=spec.get("grain", 2.0), wrap_v=True, **spec.get("params", {}))
    shape = spec.get("shape", "circle")
    mask = _shape_mask(shape, W)
    base = Image.fromarray(rgb, "RGB").convert("RGBA")
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    out.paste(base, (0, 0), mask)
    # borde: dilatar la mascara y pintar anillo
    from PIL import ImageFilter
    ring_col = hex_to_rgb(spec.get("ring", "#ffffff")) + (255,)
    outer = mask.filter(ImageFilter.MaxFilter(15))
    ring = Image.new("RGBA", (W, H), ring_col)
    ring_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ring_layer.paste(ring, (0, 0), outer)
    ring_layer.paste(Image.new("RGBA", (W, H), (0, 0, 0, 0)), (0, 0), mask)
    out = Image.alpha_composite(ring_layer, out)
    t = spec.get("text")
    if t:
        st = spec.get("text_style", {})
        layer = draw_text_layer(W, H, t, color=st.get("color", "#ffffff"), outline=st.get("outline", "#000000"),
                                size=st.get("size", 90), y_frac=st.get("y", 0.5), font_path=st.get("font"),
                                margin=70, outline_w=4)
        out.alpha_composite(layer)
    return out


# ------------------------------------------------------------- tesela seamless

def render_tile(spec: dict, size: int = 512) -> Image.Image:
    """Tesela cuadrada que repite sin costuras en X e Y (para texturas de ropa 3D)."""
    pal = get_palette(spec.get("palette", "mono"))
    rgb = render_pattern(spec.get("pattern", "stripes"), pal, size, size, seed=int(spec.get("seed", 0)),
                         grain=spec.get("grain", 2.0), wrap_v=True, **spec.get("params", {}))
    return Image.fromarray(rgb, "RGB")
