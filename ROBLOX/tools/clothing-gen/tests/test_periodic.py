"""Pruebas: (1) los patrones dan la vuelta al cilindro sin costura; (2) el layout coincide con la
plantilla oficial. Ejecutar:  ./venv/bin/python -m unittest discover -s tests -v
"""
import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from clothgen import layout as L  # noqa: E402
from clothgen.palettes import PALETTES, get_palette  # noqa: E402
from clothgen.patterns import PATTERNS, render_pattern  # noqa: E402


def _grid(C, H, width):
    u = np.arange(width, dtype=np.float64) + 0.5
    v = np.arange(H, dtype=np.float64) + 0.5
    return np.meshgrid(u, v)


class Periodic(unittest.TestCase):
    def test_pattern_is_periodic_in_u(self):
        """f(U + C) == f(U), llamando al patron DIRECTAMENTE (sin el U % C de render_pattern)."""
        for part in L.BELTS:
            _, C, H = L.belt_geometry(part)
            for name, fn in PATTERNS.items():
                pal = get_palette("sunset")
                U, V = _grid(C, H, 2 * C)          # dos vueltas completas
                out = fn(U, V, float(C), float(H), pal, seed=3)
                self.assertTrue(np.allclose(out[:, :C], out[:, C:], atol=1e-6),
                                f"{name}/{part}: NO periodico en u (habria costura al dar la vuelta)")

    def test_pattern_is_not_degenerate(self):
        """Evita que el test de arriba pase por patrones constantes."""
        U, V = _grid(384, 128, 384)
        for name, fn in PATTERNS.items():
            if name == "solid":
                continue
            out = fn(U, V, 384.0, 128.0, get_palette("ocean"), seed=4)
            self.assertGreater(out.std(), 5.0, f"{name}: casi constante")

    def test_tile_wraps_in_v(self):
        """Para teselas (wrap_v=True): f(V + H) == f(V)."""
        for name, fn in PATTERNS.items():
            pal = get_palette("candy")
            C = H = 256
            u = np.arange(C, dtype=np.float64) + 0.5
            v = np.arange(2 * H, dtype=np.float64) + 0.5
            U, V = np.meshgrid(u, v)
            out = fn(U, V, float(C), float(H), pal, seed=2, wrap_v=True)
            self.assertTrue(np.allclose(out[:H], out[H:], atol=1e-6), f"{name}: NO periodico en v")


class ImagePattern(unittest.TestCase):
    def test_image_pattern_periodic(self):
        """El patron `image` (tesela de usuario) tambien cierra al dar la vuelta."""
        import tempfile
        from PIL import Image
        from clothgen.patterns import PATTERNS_WITH_FILE
        rng = np.random.default_rng(0)
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "t.png"
            Image.fromarray((rng.random((64, 48, 3)) * 255).astype("uint8")).save(p)
            for C, H in ((384, 128), (256, 128)):
                U, V = _grid(C, H, 2 * C)
                out = PATTERNS_WITH_FILE["image"](U, V, float(C), float(H), get_palette("mono"), path=str(p), scale=1.5)
                self.assertTrue(np.allclose(out[:, :C], out[:, C:], atol=1e-6))


class Layout(unittest.TestCase):
    def test_sizes_match_official_table(self):
        """Tabla oficial: 128x128 FRONT/BACK; 64x128 lados; 128x64 UP/DOWN torso; 64x64 U/D limbs."""
        self.assertEqual(L.TORSO["front"][2:], (128, 128))
        self.assertEqual(L.TORSO["back"][2:], (128, 128))
        self.assertEqual(L.TORSO["left"][2:], (64, 128))
        self.assertEqual(L.TORSO["up"][2:], (128, 64))
        self.assertEqual(L.R_LIMB["up"][2:], (64, 64))
        self.assertEqual(L.L_LIMB["front"][2:], (64, 128))

    def test_faces_inside_canvas_and_disjoint(self):
        W, H = L.CANVAS
        seen = np.zeros((H, W), int)
        for _, _, x, y, w, h in L.all_faces():
            self.assertTrue(0 <= x and x + w <= W and 0 <= y and y + h <= H)
            seen[y:y + h, x:x + w] += 1
        self.assertEqual(int(seen.max()), 1, "hay caras solapadas")

    def test_belt_geometry(self):
        self.assertEqual(L.belt_geometry("torso")[1:], (384, 128))
        self.assertEqual(L.belt_geometry("r_limb")[1:], (256, 128))
        self.assertEqual(L.belt_geometry("l_limb")[1:], (256, 128))

    def test_palettes(self):
        for k in PALETTES:
            self.assertGreaterEqual(len(get_palette(k)), 4)


if __name__ == "__main__":
    unittest.main()
