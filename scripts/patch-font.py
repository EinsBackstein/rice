#!/usr/bin/env python3
"""Regenerates home/.local/share/fonts/SpaceGroteskFixed from the system Space Grotesk.

Why: Space Grotesk's glyphs reach 1134 units but its declared line ascent is 984, so tall glyphs/accents get
clipped by toolkits that trust the line metrics. The copy is renamed "Space Grotesk Fixed" (SIL OFL allows
modified, renamed redistribution) and gets ascent 1160 / descent 300 / lineGap 0.

Needs fontTools:  python3 -m venv /tmp/v && /tmp/v/bin/pip install fonttools && /tmp/v/bin/python scripts/patch-font.py
"""
import glob, os
from fontTools.ttLib import TTFont

SRC = "/usr/share/fonts/truetype/space-grotesk"
OUT = os.path.join(os.path.dirname(__file__), "..", "home", ".local", "share", "fonts", "SpaceGroteskFixed")
FAM, ASC, DESC = "Space Grotesk Fixed", 1160, 300
os.makedirs(OUT, exist_ok=True)

for p in glob.glob(f"{SRC}/SpaceGrotesk-*.ttf"):
    f = TTFont(p)
    w = os.path.basename(p)[len("SpaceGrotesk-"):-4]
    f["hhea"].ascent, f["hhea"].descent, f["hhea"].lineGap = ASC, -DESC, 0
    o = f["OS/2"]
    o.sTypoAscender, o.sTypoDescender, o.sTypoLineGap, o.usWinAscent, o.usWinDescent = ASC, -DESC, 0, ASC, DESC
    name = f["name"]
    plain = w in ("Regular", "Bold")
    for rec in list(name.names):
        if rec.nameID in (1, 2, 3, 4, 6, 16, 17, 21, 22):
            name.removeNames(nameID=rec.nameID)
    for pid, eid, lid in ((3, 1, 0x409), (1, 0, 0)):
        name.setName(FAM if plain else f"{FAM} {w}", 1, pid, eid, lid)
        name.setName(w if plain else "Regular", 2, pid, eid, lid)
        name.setName(f"{FAM} {w} fixed-metrics", 3, pid, eid, lid)
        name.setName(FAM if w == "Regular" else f"{FAM} {w}", 4, pid, eid, lid)
        name.setName(f"SpaceGroteskFixed-{w}", 6, pid, eid, lid)
        if not plain:
            name.setName(FAM, 16, pid, eid, lid)
            name.setName(w, 17, pid, eid, lid)
    f.save(os.path.join(OUT, f"SpaceGroteskFixed-{w}.ttf"))
    print("patched", w)
