#!/usr/bin/env bash
# Compile shaders/globe.{vert,frag} -> shaders/globe.{vert,frag}.qsb
# Targets SPIR-V (Vulkan) + GLSL 100es/120/150 + HLSL/MSL so every Qt RHI backend works
# (SPIR-V-only .qsb files render nothing under the OpenGL backend).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../shaders"

QSB=""
for c in qsb /usr/lib/qt6/bin/qsb /usr/lib64/qt6/bin/qsb qsb-qt6; do
    if command -v "$c" >/dev/null 2>&1; then QSB="$c"; break; fi
done
[ -z "$QSB" ] && { echo "!! qsb not found (install qt6-shadertools)"; exit 1; }
echo "→ using $QSB"

build() {   # $1 = source
    local src="$1" out="$1.qsb"
    rm -f "$out"
    if   "$QSB" --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "$out" "$src" 2>/dev/null; then :
    elif "$QSB" --glsl "100es,120,150"  --hlsl 50 --msl 12 -o "$out" "$src" 2>/dev/null; then :
    elif "$QSB" --glsl "100 es,120,150" -o "$out" "$src" 2>/dev/null; then :
    else echo "!! $src failed — run: $QSB -o $out $src"; exit 1; fi
    echo "  ✓ $out"
}
build globe.vert
build globe.frag
