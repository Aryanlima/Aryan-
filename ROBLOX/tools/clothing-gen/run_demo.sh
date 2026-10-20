#!/usr/bin/env bash
# Prepara el venv local, corre las pruebas y genera una coleccion de ejemplo en out/.
set -euo pipefail
cd "$(dirname "$0")"
if [ ! -x venv/bin/python ]; then
  python3 -m venv venv
  venv/bin/pip install --quiet -r requirements.txt
fi
PY=venv/bin/python
$PY verify_layout.py                       # coordenadas vs plantilla oficial
$PY -m unittest discover -s tests          # periodicidad (sin costuras) + layout
$PY -m clothgen batch --config batch.example.json --out out/example
$PY -m clothgen collection --n 12 --theme halloween --kind set --seed 4 --unique-patterns --out out/halloween
echo "Listo. Mira out/example/previews/ y out/halloween/previews/_contact_sheet.png"
