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


class Periodic(unittest.TestCase):
    def test_pattern_wraps_in_u(self):
        """render con origen desplazado exactamente un periodo C == render normal."""
        for part in L.BELTS:
            _, C, H = L.belt_geometry(part)
            for name in PATTERNS:
                pal = get_palette("sunset")
                a = render_pattern(name, pal, C, H, origin_u=0, seed=3, grain=0)
                b = render_pattern(name, pal, C, H, origin_u=C, seed=3, grain=0)
                self.assertTrue(np.array_equal(a, b), f"{name}/{part}: no periodico en u")

    def test_pattern_continuity_across_wrap(self):
        """Un render desplazado k px es el render original rodado k px (sin costura oculta)."""
        for name in PATTERNS:
            pal = get_palette("ocean")
            C, H = 384, 128
            a = render_pattern(name, pal, C, H, origin_u=0, seed=5, grain=0)
            for k in (37, 130):
                b = render_pattern(name, pal, C, H, origin_u=k, seed=5, grain=0)
                self.assertTrue(np.array_equal(np.roll(a, -k, axis=1), b), f"{name}: roll k={k}")

    def test_tile_wraps_in_v(self):
        for name in PATTERNS:
            pal = get_palette("candy")
            a = render_pattern(name, pal, 256, 256, seed=2, grain=0, wrap_v=True)
            # continuidad vertical: la fila de cierre difiere como mucho lo que difieren filas vecinas
            d_int = np.abs(np.diff(a.astype(int), axis=0)).mean(axis=(1, 2)).max()
            d_seam = np.abs(a[-1].astype(int) - a[0].astype(int)).mean()
            self.assertLessEqual(d_seam, d_int * 1.05 + 2, f"{name}: costura vertical")


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
