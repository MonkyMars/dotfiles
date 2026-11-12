#!/usr/bin/env python3
"""Pinta as pastas do MacTahoe com a cor tonal do Noctalia.

Chamado pelo post_hook do template "mactahoe" sempre que o Noctalia muda
o esquema. Parte sempre dos SVG originais (azul #006efd) guardados em
~/.local/share/mactahoe-noctalia/orig e reescreve places/scalable.

Uso manual:  mactahoe-recolor.py [#rrggbb]
Ajustes:     LIGHTNESS (0-1) e MAX_SAT (0-1) abaixo.
"""
import colorsys, json, os, re, shutil, subprocess, sys
from pathlib import Path

LIGHTNESS = 0.58   # luminosidade da pasta (Finder ~0.50; mais alto = mais pastel)
MAX_SAT = 0.60     # teto de saturação (0.3 = tonal discreto, 0.8 = vivo)

HOME = Path.home()
ORIG = HOME / ".local/share/mactahoe-noctalia/orig"
PALETTE = HOME / ".local/state/mactahoe-noctalia/palette.json"
THEMES = [HOME / ".local/share/icons" / t for t in ("MacTahoe", "MacTahoe-dark")]
SRC_HEX = "#006efd"

def pick_color() -> list:
    """Devolve as cores candidatas; o matiz vem da primeira, a saturação da mais viva."""
    if len(sys.argv) > 1:
        return [sys.argv[1]]
    try:
        p = json.loads(PALETTE.read_text())
        return [c for c in (p.get("primary_light"), p.get("primary")) if c]
    except Exception:
        # primeira execução: usa o accent do kdeglobals gerado pelo Noctalia
        kg = (HOME / ".config/kdeglobals").read_text()
        m = re.search(r"DecorationFocus=(\d+),(\d+),(\d+)", kg)
        return ["#%02x%02x%02x" % tuple(map(int, m.groups()))]

def hls(hex_: str):
    return colorsys.rgb_to_hls(*(int(hex_.lstrip("#")[i:i + 2], 16) / 255 for i in (0, 2, 4)))

def tone(colors: list) -> str:
    h = hls(colors[0])[0]
    s = max(hls(c)[2] for c in colors)
    r, g, b = colorsys.hls_to_rgb(h, LIGHTNESS, min(s, MAX_SAT))
    return "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))

def main():
    new = tone(pick_color())
    for theme in THEMES:
        dest = theme / "places/scalable"
        if not dest.is_dir():
            continue
        for svg in ORIG.glob("*.svg"):
            txt = svg.read_text().replace(SRC_HEX, new).replace(SRC_HEX.upper(), new)
            out = dest / svg.name
            if out.is_symlink():
                continue
            out.write_text(txt)
        os.utime(theme)  # invalida caches que comparam mtime
        if shutil.which("gtk-update-icon-cache"):
            subprocess.run(["gtk-update-icon-cache", "-qf", str(theme)],
                           stderr=subprocess.DEVNULL, check=False)
    cache = HOME / ".cache/icon-cache.kcache"
    if cache.exists():
        cache.write_bytes(b"")  # esvazia a cache de ícones do KDE
    print(f"MacTahoe: pastas -> {new}")

if __name__ == "__main__":
    main()
