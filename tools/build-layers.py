#!/usr/bin/env python3
"""build-layers.py — GeoNames cities1000 -> compact zoom-band layers + lookup index.

Outputs (data/layers/):
  z0..z3.json   columnar bands, sorted by population desc:
                {"v":1,"lng":[..],"lat":[..],"pop":[..],"name":[..],"cc":[..]}
  index.json    "folded name|cc" -> [lat, lng]   (biggest place wins)

Usage:
  tools/build-layers.py                      download cities1000.zip and build
  tools/build-layers.py --from-geojson z3.geojson   rebuild from an old z3.geojson
"""
import io, json, os, sys, unicodedata, urllib.request, zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
LAYERS = HERE / "data" / "layers"
CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "travel-atlas"
URL = "https://download.geonames.org/export/dump/cities1000.zip"
ZIP = CACHE / "cities1000.zip"

BANDS = [("z0", 500_000), ("z1", 100_000), ("z2", 10_000), ("z3", 1_000)]


def fold(s):
    """Lower-case and strip diacritics: 'Zürich' -> 'zurich'."""
    s = unicodedata.normalize("NFKD", s.lower())
    return "".join(c for c in s if not unicodedata.combining(c)).strip()


def rows_from_geonames():
    if not ZIP.exists():
        CACHE.mkdir(parents=True, exist_ok=True)
        print(f"→ downloading {URL}")
        urllib.request.urlretrieve(URL, ZIP)
    with zipfile.ZipFile(ZIP) as z, z.open("cities1000.txt") as f:
        for raw in io.TextIOWrapper(f, encoding="utf-8"):
            c = raw.rstrip("\n").split("\t")
            if len(c) < 15 or c[6] != "P":
                continue
            try:
                yield c[1], c[8], int(c[14] or 0), float(c[4]), float(c[5]), c[2]
            except ValueError:
                continue


def rows_from_geojson(path):
    for ft in json.load(open(path))["features"]:
        p, (lng, lat) = ft["properties"], ft["geometry"]["coordinates"]
        yield p["name"], p["country"], int(p["pop"]), lat, lng, ""


def write(rows):
    rows = sorted(rows, key=lambda r: -r[2])      # (name, cc, pop, lat, lng, asciiname)
    LAYERS.mkdir(parents=True, exist_ok=True)
    for name, minpop in BANDS:
        sel = [r for r in rows if r[2] >= minpop]
        out = {"v": 1,
               "lng": [round(r[4], 3) for r in sel], "lat": [round(r[3], 3) for r in sel],
               "pop": [r[2] for r in sel], "name": [r[0] for r in sel], "cc": [r[1] for r in sel]}
        p = LAYERS / f"{name}.json"
        p.write_text(json.dumps(out, ensure_ascii=False, separators=(",", ":")))
        print(f"  {p.name}: {len(sel):,} places, {p.stat().st_size/1e6:.1f} MB")

    index = {}                       # rows are pop-desc, so first writer wins
    for n, cc, pop, lat, lng, ascii_name in rows:
        for key in {f"{n.lower()}|{cc.lower()}", f"{fold(n)}|{cc.lower()}",
                    f"{fold(ascii_name)}|{cc.lower()}" if ascii_name else ""} - {""}:
            index.setdefault(key, [round(lat, 4), round(lng, 4)])
    p = LAYERS / "index.json"
    p.write_text(json.dumps(index, ensure_ascii=False, separators=(",", ":")))
    print(f"  index.json: {len(index):,} keys, {p.stat().st_size/1e6:.1f} MB")


def main():
    if len(sys.argv) > 2 and sys.argv[1] == "--from-geojson":
        write(rows_from_geojson(sys.argv[2]))
    else:
        write(rows_from_geonames())
    print("✓ done")


if __name__ == "__main__":
    sys.exit(main())
