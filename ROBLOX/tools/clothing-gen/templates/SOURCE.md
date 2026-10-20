# Origen de las plantillas

Archivos descargados el 2026-10-20 desde el repositorio oficial de documentacion de Roblox:

| Archivo | URL | Nota |
|---|---|---|
| `Classic-Clothing-Templates.zip` | https://github.com/Roblox/creator-docs/blob/main/content/en-us/assets/accessories/classic-clothing/Classic-Clothing-Templates.zip | contiene los dos PNG de abajo; enlazado desde https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar/classic-clothing.md |
| `Template-Shirts-R15.png` | .../classic-clothing/Template-Shirts-R15.png | 585 x 559, RGBA |
| `Template-Pants-R15.png` | .../classic-clothing/Template-Pants-R15.png | 585 x 559, RGBA |

Los binarios estan en Git LFS: `raw.githubusercontent.com` devuelve solo el puntero (130 bytes); el
binario real se obtiene en `https://media.githubusercontent.com/media/Roblox/creator-docs/main/content/en-us/assets/accessories/classic-clothing/<archivo>`.
Su SHA-256 coincide con el `oid` del puntero LFS (lo comprueba `verify_layout.py`).

Licencia del repositorio de documentacion: CC BY 4.0 (https://github.com/Roblox/creator-docs/blob/main/LICENSE).
Atribucion: (c) Roblox Corporation, creator-docs.

IMPORTANTE: las plantillas contienen el logotipo de Roblox. Se guardan SOLO como referencia de
geometria (y para `verify_layout.py`). El generador nunca copia sus pixeles: toda salida usa
fondo transparente y patrones originales. La politica del Marketplace prohibe usar branding de
Roblox en los items: https://github.com/Roblox/creator-docs/blob/main/content/en-us/marketplace/marketplace-policy.md
