#!/bin/bash
# génére un logo ascii (txt) à partir du logo marmits.png
# puis génére un logo svg à partir du logo ascii (txt)

# converti en ascii couleur
img2txt -W 100 -x 1 -y 2 marmits.png > output/marmits.txt

#Convertir 1;30 → 90 (bright black = gris).
# 1;30 => 90  (avec ou sans 0; en tête, et avec ou sans ;40)
LC_ALL=C sed -E \
  -e 's/\x1b\[0;1;30;40m/\x1b[90;40m/g' \
  -e 's/\x1b\[0;1;30m/\x1b[90m/g' \
  -e 's/\x1b\[1;30;40m/\x1b[90;40m/g' \
  -e 's/\x1b\[1;30m/\x1b[90m/g' \
  output/marmits.txt > output/marmits.norm.txt


#retirer le fond noir 40 → 49 (fond par défaut) si tu veux éviter tout aplat noir.
# Enlever le fond noir : ;40m → ;49m (fond par défaut/transparent côté SVG) :
LC_ALL=C sed -E \
  -e 's/\x1b\[([0-9;]*);40m/\x1b[\1;49m/g' \
  -i output/marmits.norm.txt

python3 ansi2svg_pure.py output/marmits.norm.txt output/marmits-grey.svg \
  --font "DejaVu Sans Mono" \
  --font-size 12 \
  --line-height 1.2 \
  --bg none \
  --char-width-ratio 0.6 \
  --margin 10
