#!/usr/bin/env bash
# Renders icon/AppIcon.svg into the asset catalogue.
#
#   ./icon/render.sh
#
# Inkscape is not on PATH from a .app install, hence the explicit path.
# Override with INKSCAPE=/path/to/inkscape if yours lives elsewhere.
set -euo pipefail

INKSCAPE="${INKSCAPE:-/Applications/Inkscape.app/Contents/MacOS/inkscape}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/icon/AppIcon.svg"
OUT="$ROOT/USAirQMinder/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

if [ ! -x "$INKSCAPE" ]; then
  echo "Inkscape not found at $INKSCAPE" >&2
  echo "Install it, or set INKSCAPE=/path/to/inkscape" >&2
  exit 1
fi

# The asset catalogue takes a single universal 1024; iOS derives the rest.
"$INKSCAPE" "$SRC" --export-type=png --export-filename="$OUT" \
  --export-width=1024 --export-height=1024 >/dev/null

echo "Wrote $OUT"
sips -g pixelWidth -g pixelHeight "$OUT" | tail -2
