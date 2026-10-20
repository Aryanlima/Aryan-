"""Coordenadas de la plantilla oficial de ropa clasica (R15) de Roblox.

FUENTE [OFICIAL]: Roblox/creator-docs (CC BY 4.0)
  content/en-us/assets/accessories/classic-clothing/Classic-Clothing-Templates.zip
  (Template-Shirts-R15.png y Template-Pants-R15.png, 585 x 559, RGBA)
  Doc: https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/classic-clothing.md

Las cajas (x, y, w, h) NO estan inventadas: se midieron sobre los pixeles de la
plantilla oficial (componentes conexos de cada color de region) y se pueden
re-verificar con `python verify_layout.py`. Los tamanos coinciden con la tabla
de la documentacion oficial: 128x128 (FRONT/BACK), 64x128 (lados), 128x64
(UP/DOWN del torso), 64x64 (U/D de brazos y piernas).

Camisa y pantalon comparten exactamente la misma geometria.
"""
from __future__ import annotations

CANVAS = (585, 559)  # (ancho, alto) que exige la plantilla oficial

# Cada cara: (x, y, w, h) en pixeles del lienzo 585x559
TORSO = {
    "up": (231, 8, 128, 64),
    "right": (165, 74, 64, 128),
    "front": (231, 74, 128, 128),
    "left": (361, 74, 64, 128),
    "back": (427, 74, 128, 128),
    "down": (231, 204, 128, 64),
}
# Brazo derecho / pierna derecha (fila inferior izquierda de la plantilla)
R_LIMB = {
    "up": (217, 289, 64, 64),
    "left": (19, 355, 64, 128),
    "back": (85, 355, 64, 128),
    "right": (151, 355, 64, 128),
    "front": (217, 355, 64, 128),
    "down": (217, 485, 64, 64),
}
# Brazo izquierdo / pierna izquierda (fila inferior derecha)
L_LIMB = {
    "up": (308, 289, 64, 64),
    "front": (308, 355, 64, 128),
    "left": (374, 355, 64, 128),
    "back": (440, 355, 64, 128),
    "right": (506, 355, 64, 128),
    "down": (308, 485, 64, 64),
}

# Orden de las caras alrededor del cilindro (adyacentes en la plantilla, y la
# ultima vuelve a la primera en 3D). Sirve para que un patron "de la vuelta"
# sin costuras. Torso: R | FRONT | L | BACK -> (vuelve a R).
BELTS = {
    "torso": ["right", "front", "left", "back"],
    "r_limb": ["left", "back", "right", "front"],
    "l_limb": ["front", "left", "back", "right"],
}
PARTS = {"torso": TORSO, "r_limb": R_LIMB, "l_limb": L_LIMB}

# Lineas punteadas de la plantilla (fila de pixeles medida en el PNG oficial).
# Texto oficial: "maximum limits for height of gloves and lower leg details on
# R15 only". Torso: y=170; brazos/piernas: y=407.
DOTTED_LINE_Y = {"torso": 170, "limb": 407}

# Nombres legibles
PART_LABELS = {
    "shirt": {"torso": "Torso", "r_limb": "Brazo derecho", "l_limb": "Brazo izquierdo"},
    "pants": {"torso": "Torso (cintura)", "r_limb": "Pierna derecha", "l_limb": "Pierna izquierda"},
}

TSHIRT_SIZE = (512, 512)  # [OFICIAL] "T-shirts are a square image, such as 512x512 pixels"


def all_faces():
    """Itera (parte, cara, x, y, w, h)."""
    for part, faces in PARTS.items():
        for face, (x, y, w, h) in faces.items():
            yield part, face, x, y, w, h


def belt_geometry(part: str):
    """Devuelve (caras en orden, circunferencia C en px, alto en px)."""
    faces = PARTS[part]
    order = BELTS[part]
    c = sum(faces[f][2] for f in order)
    h = faces[order[0]][3]
    return order, c, h
