#!/bin/bash
# génére un logo ascii (txt) à partir du logo casque.png
# puis génére un logo svg à partir du logo ascii (txt)

# converti en ascii couleur
img2txt -W 100 -x 1 -y 2 casque.png > output/casque.txt


python3 ansi2svg_pure.py output/casque.txt output/casque-grey.svg \
  --font "DejaVu Sans Mono" \
  --font-size 12 \
  --line-height 1.2 \
  --bg none \
  --char-width-ratio 0.6 \
  --margin 10
