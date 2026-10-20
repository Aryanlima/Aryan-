"""Nombres y descripciones sencillos y honestos (sin marcas, sin keyword-stuffing)."""
from __future__ import annotations

import random

ADJ_EN = {
    "sunset": "Sunset", "ocean": "Ocean", "forest": "Forest", "candy": "Candy", "mono": "Monochrome",
    "autumn": "Autumn", "neon": "Neon", "pastel": "Pastel", "midnight": "Midnight", "desert": "Desert",
    "berry": "Berry", "mint": "Mint", "halloween": "Spooky", "christmas": "Festive", "valentine": "Sweetheart",
    "spring": "Spring", "summer": "Summer",
}
NOUN_EN = {
    "stripes": "Stripes", "gradient": "Ombre", "tiedye": "Tie-Dye", "camo": "Camo", "checks": "Checkered",
    "diamonds": "Diamond", "chevron": "Zigzag", "dots": "Polka", "triangles": "Lowpoly", "waves": "Waves",
    "gingham": "Gingham", "speckle": "Speckle", "solid": "Classic",
}
KIND_EN = {"shirt": "Shirt", "pants": "Pants", "tshirt": "Tee", "set": "Set"}

ADJ_ES = {k: v for k, v in {
    "sunset": "Atardecer", "ocean": "Oceano", "forest": "Bosque", "candy": "Caramelo", "mono": "Monocromo",
    "autumn": "Otono", "neon": "Neon", "pastel": "Pastel", "midnight": "Medianoche", "desert": "Desierto",
    "berry": "Frutos rojos", "mint": "Menta", "halloween": "Tenebroso", "christmas": "Festivo",
    "valentine": "Enamorado", "spring": "Primavera", "summer": "Verano"}.items()}
NOUN_ES = {
    "stripes": "Rayas", "gradient": "Degradado", "tiedye": "Tie-Dye", "camo": "Camuflaje", "checks": "Cuadros",
    "diamonds": "Rombos", "chevron": "Zigzag", "dots": "Lunares", "triangles": "Lowpoly", "waves": "Olas",
    "gingham": "Vichy", "speckle": "Moteado", "solid": "Clasico",
}
KIND_ES = {"shirt": "Camisa", "pants": "Pantalon", "tshirt": "Camiseta", "set": "Conjunto"}


def make_name(kind, pattern, palette, lang="en", suffix=""):
    if lang == "es":
        n = f"{KIND_ES[kind]} {NOUN_ES.get(pattern, pattern)} {ADJ_ES.get(palette, str(palette).title())}"
    else:
        n = f"{ADJ_EN.get(palette, str(palette).title())} {NOUN_EN.get(pattern, pattern)} {KIND_EN[kind]}"
    return (n + (" " + suffix if suffix else "")).strip()


def make_description(kind, pattern, palette, lang="en"):
    if lang == "es":
        return (f"Diseno original de {KIND_ES[kind].lower()} con patron de {NOUN_ES.get(pattern, pattern).lower()} "
                f"en tonos {ADJ_ES.get(palette, str(palette)).lower()}. Combina con el resto de la coleccion.")
    return (f"Original {KIND_EN[kind].lower()} design with a {NOUN_EN.get(pattern, pattern).lower()} pattern "
            f"in {ADJ_EN.get(palette, str(palette)).lower()} tones. Mix and match with the rest of the collection.")


# Parametros aleatorios razonables por patron (para el modo coleccion)
def random_params(pattern, rng: random.Random):
    if pattern == "stripes":
        return {"orient": rng.choice(["v", "h", "d", "d2"]), "size": rng.choice([12, 16, 24, 32, 48])}
    if pattern == "gradient":
        return {"axis": rng.choice(["v", "u"]), "bands": rng.choice([0, 0, 6, 9])}
    if pattern == "tiedye":
        return {"centers": rng.choice([3, 4, 6]), "ring": rng.choice([10, 14, 20]), "warp": rng.choice([0.6, 0.9, 1.2])}
    if pattern == "camo":
        return {"cell": rng.choice([36, 52, 72]), "block": rng.choice([0, 0, 8])}
    if pattern in ("checks", "gingham"):
        return {"size": rng.choice([16, 24, 32, 48])}
    if pattern == "diamonds":
        return {"size": rng.choice([32, 48, 64])}
    if pattern == "chevron":
        return {"size": rng.choice([24, 32, 48]), "band": rng.choice([12, 18, 24])}
    if pattern == "dots":
        return {"size": rng.choice([20, 28, 40]), "radius": rng.choice([0.22, 0.28, 0.34])}
    if pattern == "triangles":
        return {"size": rng.choice([24, 32, 48]), "jitter": rng.choice([0.08, 0.14, 0.2])}
    if pattern == "waves":
        return {"size": rng.choice([10, 14, 18]), "amp": rng.choice([6, 9, 12])}
    if pattern == "speckle":
        return {"density": rng.choice([0.03, 0.05, 0.08])}
    return {}
