"""Paletas originales (combinaciones de color genericas, sin marcas)."""
from __future__ import annotations

PALETTES = {
    "sunset": ["#ff5e5b", "#ff9f1c", "#ffd166", "#7b2cbf", "#3a0ca3"],
    "ocean": ["#03045e", "#0077b6", "#00b4d8", "#90e0ef", "#caf0f8"],
    "forest": ["#1b4332", "#2d6a4f", "#52b788", "#95d5b2", "#d8f3dc"],
    "candy": ["#ff6fb5", "#ffb3d9", "#8ef0ff", "#b5a2ff", "#fff3b0"],
    "mono": ["#111111", "#444444", "#888888", "#cccccc", "#f5f5f5"],
    "autumn": ["#7f2f0f", "#c1440e", "#e08a1e", "#f2c14e", "#5b3a29"],
    "neon": ["#0b0b1a", "#ff2bd6", "#00f5d4", "#fee440", "#7a5cff"],
    "pastel": ["#ffd6e0", "#ffefd5", "#d6f5e3", "#d6e4ff", "#e8d6ff"],
    "midnight": ["#0b132b", "#1c2541", "#3a506b", "#5bc0be", "#e0fbfc"],
    "desert": ["#5e4b3c", "#a68a64", "#c9ada1", "#e6d5b8", "#8d6e53"],
    "berry": ["#3c1642", "#86bbd8", "#ff7aa2", "#c9184a", "#ffd6e8"],
    "mint": ["#0f4c5c", "#2ec4b6", "#a8e6cf", "#fdfffc", "#ffbf69"],
    # Estacionales (colores genericos, no emblemas protegidos)
    "halloween": ["#14110f", "#ff7518", "#6a0dad", "#7bd389", "#f2e9dc"],
    "christmas": ["#9b1d20", "#14532d", "#f8f4e3", "#d4a017", "#0b3d2e"],
    "valentine": ["#8b1e3f", "#e63e6d", "#ffb3c6", "#fff0f3", "#590d22"],
    "spring": ["#ff9ebb", "#ffd1dc", "#b8f2e6", "#aed9e0", "#ffa69e"],
    "summer": ["#ff7b00", "#ffd60a", "#00c2d1", "#0a9396", "#fff8e7"],
}

SEASONAL = {
    "halloween": ["halloween", "midnight", "autumn"],
    "christmas": ["christmas", "mono", "midnight"],
    "valentine": ["valentine", "candy", "berry"],
    "spring": ["spring", "pastel", "mint"],
    "summer": ["summer", "ocean", "sunset"],
    "backtoschool": ["midnight", "mono", "forest", "autumn"],
}


def hex_to_rgb(h: str) -> tuple[int, int, int]:
    h = h.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def get_palette(spec) -> list[tuple[int, int, int]]:
    """spec: nombre de paleta, o lista de '#rrggbb'."""
    if isinstance(spec, str):
        if spec not in PALETTES:
            raise KeyError(f"paleta desconocida: {spec!r}. Opciones: {sorted(PALETTES)}")
        spec = PALETTES[spec]
    return [hex_to_rgb(c) if isinstance(c, str) else tuple(c) for c in spec]
