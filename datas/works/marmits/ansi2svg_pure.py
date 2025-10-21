#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Convertit un ASCII art coloré (ANSI) en SVG coloré, sans dépendances externes.
Usage:
    python3 ansi2svg_pure.py input.txt output.svg \
        --font "DejaVu Sans Mono" --font-size 12 \
        --line-height 1.2 --bg none --char-width-ratio 0.6 --margin 10

Conçu pour des sorties générées par `img2txt --ansi ...` (libcaca).
Gère : SGR 0/1/3/4/22/23/24, 30-37/90-97 (fg), 40-47/100-107 (bg),
      38;5;n / 48;5;n (256c), 38;2;r;g;b / 48;2;r;g;b (truecolor).
"""

import argparse
import html
import re
import sys
from typing import Optional, Tuple, List

CSI_SGR_RE = re.compile(r"\x1b\[((?:\d{1,3};?)*?)m")

# Couleurs ANSI 16 de base (xterm)
ANSI_16 = {
    # normal 30-37 / 40-47
    30: (0, 0, 0),          # black
    31: (205, 49, 49),      # red
    32: (13, 188, 121),     # green
    33: (229, 229, 16),     # yellow
    34: (36, 114, 200),     # blue
    35: (188, 63, 188),     # magenta
    36: (17, 168, 205),     # cyan
    37: (204, 204, 204),    # white (light gray)
    # bright 90-97 / 100-107
    90: (102, 102, 102),    # bright black (gray)
    91: (241, 76, 76),      # bright red
    92: (35, 209, 139),     # bright green
    93: (245, 245, 67),     # bright yellow
    94: (59, 142, 234),     # bright blue
    95: (214, 112, 214),    # bright magenta
    96: (41, 184, 219),     # bright cyan
    97: (229, 229, 229),    # bright white
}

def xterm256_to_rgb(n: int) -> Tuple[int, int, int]:
    """Mappe un code couleur xterm 256 (0-255) vers (r,g,b)."""
    if n < 0: n = 0
    if n > 255: n = 255
    if n < 16:
        # 0-7 standard + 8-15 bright
        base = [
            (0,0,0),(205,0,0),(0,205,0),(205,205,0),
            (0,0,238),(205,0,205),(0,205,205),(229,229,229),
            (127,127,127),(255,0,0),(0,255,0),(255,255,0),
            (92,92,255),(255,0,255),(0,255,255),(255,255,255),
        ]
        return base[n]
    if 16 <= n <= 231:
        n -= 16
        r = n // 36
        g = (n % 36) // 6
        b = n % 6
        def level(v):
            return 55 + v * 40 if v > 0 else 0
        return (level(r), level(g), level(b))
    # 232..255 grayscale
    gray = 8 + (n - 232) * 10
    return (gray, gray, gray)

def rgb_to_hex(rgb: Optional[Tuple[int,int,int]]) -> str:
    if rgb is None:
        return "currentColor"  # fallback
    r,g,b = rgb
    return f"#{r:02x}{g:02x}{b:02x}"

class Style:
    __slots__ = ("fg", "bg", "bold", "italic", "underline")
    def __init__(self):
        self.fg: Optional[Tuple[int,int,int]] = (229,229,229)  # défaut clair
        self.bg: Optional[Tuple[int,int,int]] = None           # transparent
        self.bold = False
        self.italic = False
        self.underline = False

    def clone(self) -> 'Style':
        s = Style()
        s.fg = None if self.fg is None else tuple(self.fg)
        s.bg = None if self.bg is None else tuple(self.bg)
        s.bold = self.bold
        s.italic = self.italic
        s.underline = self.underline
        return s

    def apply_sgr(self, params: List[int]):
        if not params:
            params = [0]
        i = 0
        while i < len(params):
            p = params[i]
            if p == 0:  # reset
                self.__init__()
            elif p == 1:
                self.bold = True
            elif p == 3:
                self.italic = True
            elif p == 4:
                self.underline = True
            elif p == 22:
                self.bold = False
            elif p == 23:
                self.italic = False
            elif p == 24:
                self.underline = False
            elif p == 39:
                self.fg = (229,229,229)
            elif p == 49:
                self.bg = None
            elif (30 <= p <= 37) or (90 <= p <= 97):
                self.fg = ANSI_16.get(p)
            elif (40 <= p <= 47) or (100 <= p <= 107):
                self.bg = ANSI_16.get(p - 10)  # bg code -> fg equivalent (30..)
            elif p in (38, 48):
                # 38 -> set fg ; 48 -> set bg
                is_fg = (p == 38)
                # expecting 5;n or 2;r;g;b
                if i+1 < len(params):
                    mode = params[i+1]
                    if mode == 5 and i+2 < len(params):
                        n = params[i+2]
                        rgb = xterm256_to_rgb(n)
                        if is_fg: self.fg = rgb
                        else: self.bg = rgb
                        i += 2
                    elif mode == 2 and i+4 < len(params):
                        r, g, b = params[i+2], params[i+3], params[i+4]
                        rgb = (max(0,min(255,r)), max(0,min(255,g)), max(0,min(255,b)))
                        if is_fg: self.fg = rgb
                        else: self.bg = rgb
                        i += 4
            # autres codes ignorés
            i += 1

def parse_ansi_to_runs(line: str) -> List[Tuple[str, Style]]:
    """
    Transforme une ligne ANSI en une liste de (texte_sans_ansi, style).
    Chaque élément est un run de même style.
    """
    runs: List[Tuple[str, Style]] = []
    style = Style()
    pos = 0
    for m in CSI_SGR_RE.finditer(line):
        text_chunk = line[pos:m.start()]
        if text_chunk:
            # Ajouter le texte courant avec le style actuel
            runs.append((text_chunk, style.clone()))
        sgr_params = [int(x) for x in m.group(1).split(";") if x != ""]
        style.apply_sgr(sgr_params)
        pos = m.end()
    # Reste de la ligne
    tail = line[pos:]
    if tail:
        runs.append((tail, style.clone()))
    return runs

def strip_ansi_visible_len(s: str) -> int:
    """Longueur visible (sans séquences ANSI)."""
    return len(CSI_SGR_RE.sub("", s))

def main():
    ap = argparse.ArgumentParser(description="ANSI colored text -> Colored SVG (no deps)")
    ap.add_argument("input", help="Fichier texte ANSI (ex: picture.txt)")
    ap.add_argument("output", help="Fichier SVG de sortie (ex: picture.svg)")
    ap.add_argument("--font", default="DejaVu Sans Mono", help="Police monospace (déf: DejaVu Sans Mono)")
    ap.add_argument("--font-size", type=float, default=12.0, help="Taille de police en px (déf: 12)")
    ap.add_argument("--line-height", type=float, default=1.2, help="Multiplicateur de hauteur de ligne (déf: 1.2)")
    ap.add_argument("--char-width-ratio", type=float, default=0.6, help="Largeur/FontSize pour monospace (déf: 0.6)")
    ap.add_argument("--margin", type=float, default=10.0, help="Marge en px autour (déf: 10)")
    ap.add_argument("--bg", default="none", help="Arrière-plan: 'none' (transparent) ou #rrggbb (déf: none)")
    args = ap.parse_args()

    try:
        with open(args.input, "r", encoding="utf-8", errors="replace") as f:
            raw_lines = f.read().splitlines()
    except Exception as e:
        print(f"Erreur: impossible de lire {args.input}: {e}", file=sys.stderr)
        sys.exit(1)

    # Mesures de grille
    fs = args.font_size
    lh = args.line_height * fs
    cw = args.char_width_ratio * fs
    margin = args.margin

    rows = len(raw_lines)
    cols = max((strip_ansi_visible_len(L) for L in raw_lines), default=0)

    width = 2*margin + cols * cw
    height = 2*margin + rows * lh

    # Prépare le SVG
    out = []
    out.append('<?xml version="1.0" encoding="UTF-8"?>')
    out.append(f'<svg xmlns="http://www.w3.org/2000/svg" version="1.1" '
               f'width="{width:.2f}" height="{height:.2f}" '
               f'viewBox="0 0 {width:.2f} {height:.2f}">')
    # Fond
    if args.bg and args.bg.lower() != "none":
        out.append(f'<rect x="0" y="0" width="{width:.2f}" height="{height:.2f}" fill="{html.escape(args.bg)}"/>')
    # Style texte global
    out.append('<g>')
    out.append(f'<g font-family="{html.escape(args.font)}" font-size="{fs:.2f}px" '
               f'xml:space="preserve">')

    # Dessine ligne par ligne
    # Pour placer le texte correctement: y = margin + (row+1)*lh - (lh - fs)/2
    # (approximation: baseline ~ fs, visuellement suffisant)
    for r, line in enumerate(raw_lines):
        runs = parse_ansi_to_runs(line)
        x_cursor = 0  # colonne visible
        y = margin + (r + 1) * lh - (lh - fs) * 0.5
        # On reconstruit la ligne en runs, en tenant compte des espaces
        for text, style in runs:
            if not text:
                continue
            # Avance la colonne pour les espaces "invisibles" avant le run ?
            # Ici, on place le run à la colonne courante et on dessine exactement son contenu.
            # Calcul du x
            x = margin + x_cursor * cw
            # Échappe le texte et remplace les tabulations par espaces (rare dans img2txt)
            safe_text = text.replace("\t", "    ")
            safe_text = html.escape(safe_text)

            # Calcul des couleurs / décorations
            fill = rgb_to_hex(style.fg)
            # Background: on peut dessiner un rect derrière le run si besoin
            if style.bg is not None and safe_text:
                run_cols = len(text)
                rx = x
                ry = margin + r * lh
                rw = run_cols * cw
                rh = lh
                out.append(f'<rect x="{rx:.2f}" y="{ry:.2f}" width="{rw:.2f}" height="{rh:.2f}" '
                           f'fill="{rgb_to_hex(style.bg)}"/>')

            deco = []
            if style.bold:
                deco.append("font-weight:bold")
            if style.italic:
                deco.append("font-style:italic")
            if style.underline:
                deco.append("text-decoration:underline")

            style_attr = f' fill="{fill}"'
            if deco:
                style_attr += f' style="{";".join(deco)}"'

            # Texte du run à la position calculée
            out.append(f'<text x="{x:.2f}" y="{y:.2f}"{style_attr}>{safe_text}</text>')

            # Avancer le curseur de colonnes visibles
            x_cursor += len(text)

        # S'il reste du vide en fin de ligne, rien à dessiner (fond transparent)

    out.append('</g>')
    out.append('</g>')
    out.append('</svg>')

    try:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write("\n".join(out))
    except Exception as e:
        print(f"Erreur: impossible d'écrire {args.output}: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"[OK] SVG coloré généré : {args.output}")
    print(f"     Dimensions: {width:.0f} x {height:.0f}px  (cols={cols}, rows={rows}, fs={fs}px, cw≈{cw:.2f}, lh≈{lh:.2f})")

if __name__ == "__main__":
    main()
