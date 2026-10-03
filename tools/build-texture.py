#!/usr/bin/env python3
"""build-texture.py — render assets/earth.png from Natural Earth (public domain).

Output is an equirectangular RGB mask the globe shader colours with the
active theme:  R = land,  G = country borders,  B = graticule.

Usage:  tools/build-texture.py [ne-dir]   (downloads the 3 GeoJSON files if absent)
Needs:  python3, pillow
"""
import json, sys, urllib.request
from pathlib import Path
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent.parent
NE = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / "tools" / ".ne-cache"
BASE = "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/"
FILES = ["ne_50m_land", "ne_50m_lakes", "ne_50m_admin_0_boundary_lines_land"]
W, H, SS = 4096, 2048, 2          # output size, supersampling factor
SW, SH = W * SS, H * SS

NE.mkdir(parents=True, exist_ok=True)
for f in FILES:
    p = NE / f"{f}.geojson"
    if not p.exists():
        print("→ downloading", f)
        urllib.request.urlretrieve(BASE + f + ".geojson", p)

def xy(lng, lat):
    return ((lng + 180.0) / 360.0 * SW, (90.0 - lat) / 180.0 * SH)

def polys(geom):
    if geom["type"] == "Polygon":
        yield geom["coordinates"]
    elif geom["type"] == "MultiPolygon":
        yield from geom["coordinates"]

def lines(geom):
    if geom["type"] == "LineString":
        yield geom["coordinates"]
    elif geom["type"] == "MultiLineString":
        yield from geom["coordinates"]

def load(name):
    return json.loads((NE / f"{name}.geojson").read_text())["features"]

def fill(draw, feats, value):
    for ft in feats:
        for rings in polys(ft["geometry"]):
            draw.polygon([xy(*c[:2]) for c in rings[0]], fill=value)
            for hole in rings[1:]:
                draw.polygon([xy(*c[:2]) for c in hole], fill=0)

land = Image.new("L", (SW, SH), 0)
d = ImageDraw.Draw(land)
fill(d, load("ne_50m_land"), 255)
fill(d, load("ne_50m_lakes"), 0)

border = Image.new("L", (SW, SH), 0)
d = ImageDraw.Draw(border)
for ft in load("ne_50m_admin_0_boundary_lines_land"):
    for ln in lines(ft["geometry"]):
        d.line([xy(*c[:2]) for c in ln], fill=255, width=2)

grat = Image.new("L", (SW, SH), 0)
d = ImageDraw.Draw(grat)
for lng in range(-180, 181, 30):
    x = xy(lng, 0)[0]; d.line([(x, 0), (x, SH)], fill=255, width=2)
for lat in range(-60, 61, 30):
    y = xy(0, lat)[1]; d.line([(0, y), (SW, y)], fill=255, width=2)

rgb = Image.merge("RGB", [im.resize((W, H), Image.LANCZOS) for im in (land, border, grat)])
out = HERE / "assets" / "earth.png"
out.parent.mkdir(exist_ok=True)
rgb.save(out, optimize=True)
print(f"✓ {out} ({out.stat().st_size/1024:.0f} KiB)")
