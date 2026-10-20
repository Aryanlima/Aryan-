"""CLI: python -m clothgen <comando> ...   (usar el python del venv)"""
from __future__ import annotations

import argparse
import csv
import json
import random
import sys
from pathlib import Path

from PIL import Image

from . import __version__, qc
from .garment import render_clothing, render_tile, render_tshirt
from .naming import make_description, make_name, random_params
from .palettes import PALETTES, SEASONAL
from .patterns import PATTERNS
from .preview import contact_sheet, mock, overlay


def _parse_params(items):
    out = {}
    for it in items or []:
        k, _, v = it.partition("=")
        for cast in (int, float):
            try:
                v = cast(v)
                break
            except ValueError:
                continue
        if v == "true":
            v = True
        out[k] = v
    return out


def _spec_from_args(a):
    spec = {"pattern": a.pattern, "palette": a.palette.split(",") if "," in a.palette else a.palette,
            "seed": a.seed, "params": _parse_params(a.param)}
    for k in ("sleeve", "length", "hem", "cuff", "collar", "torso_coverage"):
        v = getattr(a, k, None)
        if v is not None:
            spec[k] = v
    t = {}
    if getattr(a, "text_front", None):
        t["front"] = a.text_front
    if getattr(a, "text_back", None):
        t["back"] = a.text_back
    if t:
        spec["text"] = t
    return spec


def _save(img, path):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    img.save(path, format="PNG", optimize=True)
    return path


def make_item(item: dict, out: Path, previews=True) -> list[dict]:
    """Genera los PNG de un item del lote. Devuelve filas de manifiesto."""
    kind = item["kind"]
    iid = item["id"]
    rows = []
    lang = item.get("lang", "en")
    pal_name = item["palette"] if isinstance(item["palette"], str) else "custom"
    texts = list((item.get("text") or {}).values())
    if isinstance(item.get("text"), str):
        texts = [item["text"]]
    kinds = ["shirt", "pants"] if kind == "set" else [kind]
    imgs = {}
    for k in kinds:
        spec = dict(item)
        if k == "pants" and "pants_extra" in item:
            spec.update(item["pants_extra"])
        if k == "tshirt":
            img = render_tshirt(spec)
        else:
            img = render_clothing(k, spec)
        imgs[k] = img
        path = out / f"{iid}-{k}.png"
        _save(img, path)
        name = item.get("name") or make_name("set" if kind == "set" else k, item["pattern"], pal_name, lang)
        if kind == "set":
            name = f"{name.rsplit(' ', 1)[0]} {'Shirt' if k == 'shirt' else 'Pants'}" if lang == "en" else \
                f"{'Camisa' if k == 'shirt' else 'Pantalon'} {' '.join(name.split(' ')[1:])}"
        r = (qc.check_tshirt(path, texts + [name]) if k == "tshirt"
             else qc.check_clothing(path, k, texts + [name]))
        rows.append({
            "id": iid, "type": {"shirt": "Shirt", "pants": "Pants", "tshirt": "T-Shirt"}[k],
            "file": str(path.name), "name": name,
            "description": item.get("description") or make_description(k, item["pattern"], pal_name, lang),
            "pattern": item["pattern"], "palette": pal_name, "seed": item.get("seed", 0),
            "qc_ok": r["ok"], "qc_problems": "; ".join(r["problems"]), "qc_warnings": "; ".join(r["warnings"]),
            "sha1": r.get("sha1", ""), "_qc": r,
        })
    if previews and kind in ("shirt", "pants", "set"):
        m = mock(imgs.get("shirt"), imgs.get("pants"))
        _save(m, out / "previews" / f"{iid}-mock.png")
        for k, im in imgs.items():
            _save(overlay(im), out / "previews" / f"{iid}-{k}-overlay.png")
    return rows


def write_manifest(rows, out: Path):
    out.mkdir(parents=True, exist_ok=True)
    cols = ["id", "type", "file", "name", "description", "pattern", "palette", "seed",
            "qc_ok", "qc_problems", "qc_warnings", "sha1", "uploaded_by_hand", "asset_id", "price_robux", "notes"]
    with open(out / "manifest.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=cols, extrasaction="ignore")
        w.writeheader()
        for r in rows:
            r = dict(r)
            r.update(uploaded_by_hand="", asset_id="", price_robux="", notes="")
            w.writerow(r)
    with open(out / "qc_report.json", "w", encoding="utf-8") as f:
        json.dump([r["_qc"] for r in rows], f, indent=1, ensure_ascii=False, default=str)


def cmd_one(a):
    out = Path(a.out)
    spec = _spec_from_args(a)
    spec.update(id=a.id or f"{a.cmd}-{a.pattern}-{a.seed}", kind=a.cmd)
    if a.cmd == "tshirt":
        spec["text"] = a.text
        spec["shape"] = a.shape
    rows = make_item(spec, out, previews=a.cmd != "tshirt")
    write_manifest(rows, out)
    for r in rows:
        print(("OK  " if r["qc_ok"] else "FAIL"), out / r["file"], r["qc_problems"], r["qc_warnings"])
    return 0 if all(r["qc_ok"] for r in rows) else 1


def cmd_tile(a):
    spec = {"pattern": a.pattern, "palette": a.palette, "seed": a.seed, "params": _parse_params(a.param)}
    img = render_tile(spec, a.size)
    p = _save(img, Path(a.out) / f"tile-{a.pattern}-{a.palette}-{a.seed}.png")
    print(p, qc.tile_seam_score(p))
    return 0


def cmd_batch(a):
    cfg = json.loads(Path(a.config).read_text(encoding="utf-8"))
    items = cfg["items"] if isinstance(cfg, dict) else cfg
    return _run_items(items, Path(a.out))


def cmd_collection(a):
    rng = random.Random(a.seed)
    themes = SEASONAL.get(a.theme, [a.theme]) if a.theme in SEASONAL or a.theme in PALETTES else list(PALETTES)
    pats = [p for p in PATTERNS if p != "solid"]
    items = []
    for i in range(a.n):
        pat = pats[i % len(pats)] if a.unique_patterns else rng.choice(pats)
        pal = rng.choice(themes)
        items.append({
            "id": f"{a.theme}-{i + 1:03d}", "kind": a.kind, "pattern": pat, "palette": pal,
            "seed": rng.randrange(1, 10 ** 6), "params": random_params(pat, rng), "lang": a.lang,
            "sleeve": rng.choice(["long", "long", "short"]) if a.kind in ("shirt", "set") else None,
            "pants_extra": {"length": rng.choice(["long", "long", "shorts"])},
            "hem": None, "cuff": None,
        })
        if items[-1]["sleeve"] is None:
            items[-1].pop("sleeve")
    return _run_items(items, Path(a.out))


def _run_items(items, out: Path):
    out.mkdir(parents=True, exist_ok=True)
    rows = []
    for it in items:
        it = {k: v for k, v in it.items() if v is not None}
        rows += make_item(it, out)
    write_manifest(rows, out)
    # duplicados cercanos (Roblox pide no subir items demasiado parecidos entre si)
    for kind in ("Shirt", "Pants", "T-Shirt"):
        group = {r["id"]: str(out / r["file"]) for r in rows if r["type"] == kind}
        dups = qc.near_duplicates(group) if len(group) > 1 else []
        for x, y, d in dups:
            print(f"AVISO casi-duplicado ({kind}): {x} ~ {y} (distancia {d})")
    imgs = []
    for r in rows:
        p = out / "previews" / f"{r['id']}-mock.png"
        if p.exists() and r["type"] != "Pants":
            imgs.append((f"{r['id']} {r['pattern']}/{r['palette']}", Image.open(p)))
    if imgs:
        _save(contact_sheet(imgs, cols=4), out / "previews" / "_contact_sheet.png")
    ok = sum(1 for r in rows if r["qc_ok"])
    print(f"{len(rows)} archivos generados, QC ok: {ok}/{len(rows)} -> {out}")
    return 0 if ok == len(rows) else 1


def cmd_qc(a):
    d = Path(a.dir)
    bad = 0
    for p in sorted(d.glob("*.png")):
        kind = "pants" if p.stem.endswith("-pants") else "tshirt" if p.stem.endswith("-tshirt") else "shirt"
        r = qc.check_tshirt(p) if kind == "tshirt" else qc.check_clothing(p, kind)
        print(("OK  " if r["ok"] else "FAIL"), p.name, r["problems"], r["warnings"])
        bad += not r["ok"]
    return 1 if bad else 0


def cmd_list(a):
    print("patrones:", ", ".join(sorted(PATTERNS)))
    print("paletas:", ", ".join(sorted(PALETTES)))
    print("temporadas:", ", ".join(sorted(SEASONAL)))
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(prog="clothgen", description=__doc__)
    ap.add_argument("--version", action="version", version=__version__)
    sub = ap.add_subparsers(dest="cmd", required=True)

    def common(p):
        p.add_argument("--pattern", default="stripes", choices=sorted(PATTERNS))
        p.add_argument("--palette", default="sunset", help="nombre o lista '#hex,#hex,...'")
        p.add_argument("--seed", type=int, default=1)
        p.add_argument("--param", action="append", help="clave=valor del patron (repetible)")
        p.add_argument("--out", default="out")
        p.add_argument("--id")

    for name in ("shirt", "pants", "set"):
        p = sub.add_parser(name)
        common(p)
        p.add_argument("--sleeve", choices=["long", "short", "sleeveless"])
        p.add_argument("--length", choices=["long", "shorts"])
        p.add_argument("--torso-coverage", dest="torso_coverage", type=float)
        p.add_argument("--hem")
        p.add_argument("--cuff")
        p.add_argument("--collar")
        p.add_argument("--text-front")
        p.add_argument("--text-back")
        p.set_defaults(fn=cmd_one)
    p = sub.add_parser("tshirt")
    common(p)
    p.add_argument("--shape", default="circle", choices=["circle", "rounded", "hexagon", "diamond"])
    p.add_argument("--text")
    p.set_defaults(fn=cmd_one)
    p = sub.add_parser("tile")
    common(p)
    p.add_argument("--size", type=int, default=512)
    p.set_defaults(fn=cmd_tile)
    p = sub.add_parser("batch")
    p.add_argument("--config", required=True)
    p.add_argument("--out", default="out")
    p.set_defaults(fn=cmd_batch)
    p = sub.add_parser("collection", help="N items automaticos con un tema")
    p.add_argument("--n", type=int, default=12)
    p.add_argument("--theme", default="halloween")
    p.add_argument("--kind", default="set", choices=["shirt", "pants", "set"])
    p.add_argument("--lang", default="en", choices=["en", "es"])
    p.add_argument("--seed", type=int, default=1)
    p.add_argument("--unique-patterns", action="store_true")
    p.add_argument("--out", default="out")
    p.set_defaults(fn=cmd_collection)
    p = sub.add_parser("qc")
    p.add_argument("--dir", required=True)
    p.set_defaults(fn=cmd_qc)
    p = sub.add_parser("list")
    p.set_defaults(fn=cmd_list)

    a = ap.parse_args(argv)
    return a.fn(a)


if __name__ == "__main__":
    sys.exit(main())
