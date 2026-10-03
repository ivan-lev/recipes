#!/usr/bin/env bash
# Нарезает PNG-иконки и favicon.ico из icon.png и icon-maskable.png (квадрат,
# фон до краёв, без прозрачности; в maskable рисунок вписан в центральный круг
# диаметром 80% стороны — Android обрезает её по своей маске). Запускать локально
# на macOS после замены исходников и коммитить результат.
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p png

render() { sips -z "$2" "$2" "$1" --out "png/$3" >/dev/null; }

render icon.png 16 favicon-16x16.png
render icon.png 32 favicon-32x32.png
render icon.png 180 apple-touch-icon.png
render icon.png 192 android-chrome-192x192.png
render icon.png 512 android-chrome-512x512.png
render icon-maskable.png 192 android-chrome-192x192-maskable.png
render icon-maskable.png 512 android-chrome-512x512-maskable.png

# ICO с PNG внутри: заголовок и по записи на каждый размер.
python3 - png/favicon.ico png/favicon-16x16.png png/favicon-32x32.png <<'PY'
import struct, sys
out, *pngs = sys.argv[1:]
images = [open(p, "rb").read() for p in pngs]
header = struct.pack("<HHH", 0, 1, len(images))
offset = len(header) + 16 * len(images)
entries = b""
for data in images:
    w, h = struct.unpack(">II", data[16:24])
    entries += struct.pack("<BBBBHHII", w % 256, h % 256, 0, 0, 1, 32, len(data), offset)
    offset += len(data)
open(out, "wb").write(header + entries + b"".join(images))
PY
