#!/usr/bin/env python
"""Re-mide las regiones sobre la plantilla OFICIAL y comprueba que clothgen/layout.py coincide.

Uso:  ./venv/bin/python verify_layout.py
Requiere templates/Template-Shirts-R15.png y Template-Pants-R15.png (ver templates/SOURCE.md).
Metodo: cada region de la plantilla es un rectangulo de color plano (rojo, azul, amarillo,
verde, celeste, naranja); se toman los componentes conexos de cada color y su caja envolvente.
"""
import hashlib
import sys
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from clothgen import layout as L  # noqa: E402

HERE = Path(__file__).resolve().parent
# sha256 = campo "oid" del puntero Git LFS del repo Roblox/creator-docs (integridad de la descarga)
LFS_OID = {
    "Template-Shirts-R15.png": "c87e4dfbc6cbee15e7f7283a74983f3762b715b1b366c0514754316474697d8c",
    "Classic-Clothing-Templates.zip": "678ddad004667f74dce223c7d1259e9dd437153c763639d7e668f3b532487c5d",
}
COLORS = [(226, 35, 26), (0, 116, 189), (246, 183, 2), (2, 183, 87), (0, 162, 255), (246, 136, 2)]


def boxes(path):
    a = np.array(Image.open(path).convert("RGBA"))
    h, w = a.shape[:2]
    found = set()
    for c in COLORS:
        m = (a[..., 0] == c[0]) & (a[..., 1] == c[1]) & (a[..., 2] == c[2])
        seen = np.zeros_like(m)
        for y in range(h):
            for x in range(w):
                if m[y, x] and not seen[y, x]:
                    q = deque([(y, x)])
                    seen[y, x] = True
                    x0 = x1 = x
                    y0 = y1 = y
                    n = 0
                    while q:
                        cy, cx = q.popleft()
                        n += 1
                        x0, x1, y0, y1 = min(x0, cx), max(x1, cx), min(y0, cy), max(y1, cy)
                        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                            ny, nx = cy + dy, cx + dx
                            if 0 <= ny < h and 0 <= nx < w and m[ny, nx] and not seen[ny, nx]:
                                seen[ny, nx] = True
                                q.append((ny, nx))
                    if n > 300:
                        found.add((x0, y0, x1 - x0 + 1, y1 - y0 + 1))
    return (w, h), found


def main():
    ok = True
    for fn, oid in LFS_OID.items():
        p = HERE / "templates" / fn
        got = hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None
        print(f"sha256 {fn}: {'OK' if got == oid else 'NO COINCIDE'}")
        ok &= got == oid
    expected = {(x, y, w, h) for _, _, x, y, w, h in L.all_faces()}
    for fn in ("Template-Shirts-R15.png", "Template-Pants-R15.png"):
        size, found = boxes(HERE / "templates" / fn)
        same = found == expected and size == L.CANVAS
        print(f"{fn}: lienzo {size}, {len(found)} regiones medidas, layout.py coincide: {same}")
        if not same:
            print("  solo en plantilla:", sorted(found - expected))
            print("  solo en layout.py:", sorted(expected - found))
        ok &= same
    print("RESULTADO:", "OK" if ok else "FALLO")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
