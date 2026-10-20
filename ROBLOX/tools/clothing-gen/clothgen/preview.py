"""Vistas previas 2D para revisar rapido (NO sustituyen la prueba en Roblox Studio)."""
from __future__ import annotations

from PIL import Image, ImageDraw, ImageFont

from . import layout as L

GRAY = (227, 227, 227, 255)
BODY = (163, 162, 165, 255)   # gris neutro del maniqui (no es un color oficial)
SKIN = (245, 205, 150, 255)


def overlay(img: Image.Image) -> Image.Image:
    """Diseno sobre gris + contornos y etiquetas de las regiones oficiales."""
    bg = Image.new("RGBA", img.size, GRAY)
    bg.alpha_composite(img.convert("RGBA"))
    d = ImageDraw.Draw(bg)
    f = ImageFont.load_default(size=11)
    for part, face, x, y, w, h in L.all_faces():
        d.rectangle((x, y, x + w - 1, y + h - 1), outline=(255, 0, 255, 255))
        d.text((x + 3, y + 2), face[:1].upper(), fill=(255, 0, 255, 255), font=f)
    for key, yy in (("torso", L.DOTTED_LINE_Y["torso"]),):
        x0 = L.TORSO["right"][0]
        x1 = L.TORSO["back"][0] + L.TORSO["back"][2]
        d.line((x0, yy, x1, yy), fill=(0, 0, 0, 160), width=1)
    ly = L.DOTTED_LINE_Y["limb"]
    for x0, x1 in ((19, 281), (308, 570)):
        d.line((x0, ly, x1, ly), fill=(0, 0, 0, 160), width=1)
    return bg


def _crop(img, face_box):
    x, y, w, h = face_box
    return img.crop((x, y, x + w, y + h))


def mock(shirt: Image.Image | None, pants: Image.Image | None, scale=2) -> Image.Image:
    """Muneco plano (proporciones tipo bloque) de frente y de espalda. Aproximacion 2D."""
    parts = {}
    for view in ("front", "back"):
        w, h = 256, 64 + 128 + 128
        im = Image.new("RGBA", (w, h), GRAY)
        d = ImageDraw.Draw(im)
        d.rectangle((96, 0, 159, 63), fill=SKIN)                     # cabeza
        d.rectangle((64, 64, 191, 191), fill=BODY)                   # torso
        d.rectangle((0, 64, 63, 191), fill=SKIN)                     # brazo (viewer izq)
        d.rectangle((192, 64, 255, 191), fill=SKIN)                  # brazo (viewer der)
        d.rectangle((64, 192, 127, 319), fill=BODY)                  # pierna (viewer izq)
        d.rectangle((128, 192, 191, 319), fill=BODY)                 # pierna (viewer der)
        # de frente: viewer izq = derecha del avatar. de espalda: viewer izq = izquierda del avatar.
        if view == "front":
            limb_l, limb_r = L.R_LIMB, L.L_LIMB
        else:
            limb_l, limb_r = L.L_LIMB, L.R_LIMB
        for name, src in (("pants", pants), ("shirt", shirt)):  # pantalon debajo, camisa encima
            if src is None:
                continue
            img = src.convert("RGBA")
            im.alpha_composite(_crop(img, L.TORSO[view]), (64, 64))
            if name == "shirt":
                im.alpha_composite(_crop(img, limb_l[view]), (0, 64))
                im.alpha_composite(_crop(img, limb_r[view]), (192, 64))
            else:
                im.alpha_composite(_crop(img, limb_l[view]), (64, 192))
                im.alpha_composite(_crop(img, limb_r[view]), (128, 192))
        parts[view] = im
    out = Image.new("RGBA", (256 * 2 + 16, 320), GRAY)
    out.paste(parts["front"], (0, 0))
    out.paste(parts["back"], (272, 0))
    return out.resize((out.width * scale, out.height * scale), Image.NEAREST)


def contact_sheet(images: list[tuple[str, Image.Image]], cols=4, cell=(300, 190), pad=8) -> Image.Image:
    rows = (len(images) + cols - 1) // cols
    W = cols * (cell[0] + pad) + pad
    H = rows * (cell[1] + pad + 14) + pad
    sheet = Image.new("RGB", (W, H), (40, 40, 44))
    d = ImageDraw.Draw(sheet)
    f = ImageFont.load_default(size=11)
    for i, (label, im) in enumerate(images):
        r, c = divmod(i, cols)
        x, y = pad + c * (cell[0] + pad), pad + r * (cell[1] + pad + 14)
        t = im.convert("RGB")
        t.thumbnail(cell, Image.LANCZOS)
        sheet.paste(t, (x + (cell[0] - t.width) // 2, y + 14))
        d.text((x, y), label[:46], fill=(230, 230, 230), font=f)
    return sheet
