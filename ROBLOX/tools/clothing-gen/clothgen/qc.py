"""Control de calidad automatico para texturas de ropa clasica."""
from __future__ import annotations

import hashlib
import os
from pathlib import Path

import numpy as np
from PIL import Image

from . import layout as L

HERE = Path(__file__).resolve().parent.parent


def load_blocklist(path: str | None = None) -> list[str]:
    p = Path(path) if path else HERE / "ip_blocklist.txt"
    if not p.exists():
        return []
    out = []
    for line in p.read_text(encoding="utf-8").splitlines():
        line = line.strip().lower()
        if line and not line.startswith("#"):
            out.append(line)
    return out


def check_text(strings, blocklist=None) -> list[str]:
    """Devuelve lista de terminos prohibidos encontrados en las cadenas."""
    bl = blocklist if blocklist is not None else load_blocklist()
    hits = []
    for s in strings:
        low = (s or "").lower()
        for term in bl:
            if term in low:
                hits.append(term)
    return sorted(set(hits))


def _face_mask(shape):
    m = np.zeros(shape, bool)
    for _, _, x, y, w, h in L.all_faces():
        m[y:y + h, x:x + w] = True
    return m


def belt_wrap_score(arr, part):
    """(diferencia en la costura de cierre, maximo de diferencias columna-a-columna internas).

    Un borde duro legitimo (p. ej. entre dos rayas) puede caer justo en el cierre; por eso se
    compara con el MAXIMO interno y no con un percentil. La garantia fuerte de periodicidad
    esta en tests/test_periodic.py."""
    faces = L.PARTS[part]
    order, C, Hh = L.belt_geometry(part)
    cols = []
    for f in order:
        x, y, w, h = faces[f]
        cols.append(arr[y:y + h, x:x + w])
    belt = np.concatenate(cols, axis=1).astype(np.float64)
    rgb, a = belt[..., :3], belt[..., 3]
    vis = a > 0
    diffs = []
    for i in range(C - 1):
        ok = vis[:, i] & vis[:, i + 1]
        diffs.append(np.abs(rgb[ok, i] - rgb[ok, i + 1]).mean() if ok.any() else 0.0)
    ok = vis[:, C - 1] & vis[:, 0]
    wrap = np.abs(rgb[ok, C - 1] - rgb[ok, 0]).mean() if ok.any() else 0.0
    return float(wrap), float(np.max(diffs))


def skin_tone_fraction(arr_rgba) -> float:
    """Fraccion de pixeles opacos con color tipo piel (heuristica burda: tono 8-45 grados, sat 0.15-0.65, valor > 0.45).

    Solo sirve para AVISAR: un diseno muy 'color piel' puede leerse como desnudez y ser moderado.
    """
    a = arr_rgba[..., 3] > 0
    if not a.any():
        return 0.0
    rgb = arr_rgba[..., :3][a].astype(np.float64) / 255.0
    mx, mn = rgb.max(axis=1), rgb.min(axis=1)
    d = mx - mn
    sat = np.where(mx > 0, d / np.maximum(mx, 1e-9), 0)
    r, g, b = rgb[:, 0], rgb[:, 1], rgb[:, 2]
    h = np.zeros_like(mx)
    m = d > 1e-9
    rm = m & (mx == r)
    gm = m & (mx == g) & ~rm
    bm = m & ~rm & ~gm
    h[rm] = (60 * ((g[rm] - b[rm]) / d[rm])) % 360
    h[gm] = 60 * ((b[gm] - r[gm]) / d[gm]) + 120
    h[bm] = 60 * ((r[bm] - g[bm]) / d[bm]) + 240
    skin = (h >= 8) & (h <= 45) & (sat >= 0.15) & (sat <= 0.65) & (mx > 0.45)
    return float(skin.mean())


MAX_TEXT_CHARS = 24   # decision propia: la politica dice "no excessive text"; esto es un umbral de aviso


def check_clothing(path, kind="shirt", texts=None, blocklist=None) -> dict:
    """QC de un PNG de camisa/pantalon. Devuelve dict con 'ok' y detalles."""
    res = {"file": str(path), "kind": kind, "problems": [], "warnings": []}
    img = Image.open(path)
    res["size"] = img.size
    res["mode"] = img.mode
    res["format"] = img.format
    res["bytes"] = os.path.getsize(path)
    if img.format != "PNG":
        res["problems"].append("no es PNG")
    if img.size != L.CANVAS:
        res["problems"].append(f"tamano {img.size} != {L.CANVAS} (plantilla oficial)")
    if img.mode != "RGBA":
        res["warnings"].append(f"modo {img.mode}: la plantilla oficial es RGBA (8-bit alpha)")
    if res["problems"]:
        res["ok"] = False
        return res
    arr = np.array(img.convert("RGBA"))
    mask = _face_mask(arr.shape[:2])
    stray = int(((arr[..., 3] > 0) & ~mask).sum())
    res["stray_pixels_outside_faces"] = stray
    if stray:
        res["problems"].append(f"{stray} pixeles opacos fuera de las regiones oficiales")
    cov = {}
    for part, face, x, y, w, h in L.all_faces():
        cov[f"{part}.{face}"] = round(float((arr[y:y + h, x:x + w, 3] > 0).mean()), 3)
    res["coverage"] = cov
    total_opaque = float((arr[..., 3][mask] > 0).mean())
    res["opaque_fraction_of_faces"] = round(total_opaque, 3)
    if total_opaque < 0.15:
        res["warnings"].append("menos del 15% de las regiones tiene pintura (item casi vacio)")
    semi = int(((arr[..., 3] > 0) & (arr[..., 3] < 255)).sum())
    res["semi_transparent_pixels"] = semi
    seams = {}
    for part in L.BELTS:
        wrap, mx = belt_wrap_score(arr, part)
        seams[part] = {"wrap_diff": round(wrap, 2), "max_internal": round(mx, 2)}
        if wrap > mx * 1.05 + 2.0:
            res["warnings"].append(f"costura de cierre visible en {part}: {wrap:.1f} > max interno {mx:.1f}")
    res["seams"] = seams
    res["sha1"] = hashlib.sha1(Path(path).read_bytes()).hexdigest()[:12]
    skin = skin_tone_fraction(arr)
    res["skin_tone_fraction"] = round(skin, 3)
    if skin > 0.35:
        res["warnings"].append(f"{skin:.0%} de los pixeles parecen color piel: riesgo de leerse como desnudez; revisa a mano")
    total_chars = sum(len(t) for t in (texts or []) if t)
    if total_chars > MAX_TEXT_CHARS * 2:
        res["warnings"].append(f"{total_chars} caracteres de texto: la politica pide no incluir texto excesivo")
    hits = check_text(texts or [], blocklist)
    if hits:
        res["problems"].append(f"textos con posible marca/IP: {hits}")
    res["ok"] = not res["problems"]
    return res


def check_tshirt(path, texts=None, blocklist=None) -> dict:
    res = {"file": str(path), "kind": "tshirt", "problems": [], "warnings": []}
    img = Image.open(path)
    res.update(size=img.size, mode=img.mode, format=img.format, bytes=os.path.getsize(path))
    if img.format != "PNG":
        res["problems"].append("no es PNG")
    if img.size[0] != img.size[1]:
        res["problems"].append("la T-shirt debe ser cuadrada")
    elif img.size != L.TSHIRT_SIZE:
        res["warnings"].append(f"tamano {img.size}; la doc oficial usa p. ej. 512x512")
    a = np.array(img.convert("RGBA"))[..., 3]
    res["opaque_fraction"] = round(float((a > 0).mean()), 3)
    hits = check_text(texts or [], blocklist)
    if hits:
        res["problems"].append(f"textos con posible marca/IP: {hits}")
    res["sha1"] = hashlib.sha1(Path(path).read_bytes()).hexdigest()[:12]
    res["ok"] = not res["problems"]
    return res


def dhash(img: Image.Image, n=16) -> int:
    g = Image.new("RGB", img.size, (128, 128, 128))
    g.paste(img.convert("RGBA"), (0, 0), img.convert("RGBA"))
    g = g.convert("L").resize((n + 1, n), Image.LANCZOS)
    a = np.array(g, dtype=np.int16)
    bits = (a[:, 1:] > a[:, :-1]).flatten()
    return int("".join("1" if b else "0" for b in bits), 2)


def near_duplicates(items: dict[str, str], max_dist_frac=0.08, n=16):
    """items: id -> ruta PNG. Devuelve pares (a, b, distancia) demasiado parecidos."""
    hs = {k: dhash(Image.open(v), n) for k, v in items.items()}
    keys = list(hs)
    out = []
    lim = int(max_dist_frac * n * n)
    for i in range(len(keys)):
        for j in range(i + 1, len(keys)):
            d = bin(hs[keys[i]] ^ hs[keys[j]]).count("1")
            if d <= lim:
                out.append((keys[i], keys[j], d))
    return out


def tile_seam_score(path):
    """Para teselas: compara la costura (izq/der y arriba/abajo) con diferencias internas."""
    a = np.array(Image.open(path).convert("RGB")).astype(np.float64)
    res = {}
    for name, ax in (("x", 1), ("y", 0)):
        d = np.abs(np.diff(a, axis=ax)).mean(axis=(0, 2) if ax == 1 else (1, 2))
        seam = np.abs(a[:, -1] - a[:, 0]).mean() if ax == 1 else np.abs(a[-1] - a[0]).mean()
        res[name] = {"seam": round(float(seam), 2), "max_internal": round(float(d.max()), 2)}
        res[name]["ok"] = bool(seam <= d.max() * 1.05 + 2.0)
    return res
