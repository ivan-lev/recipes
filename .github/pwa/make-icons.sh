#!/usr/bin/env bash
# Нарезает PNG-иконки и favicon.ico из icon.png (квадрат, фон до краёв, без
# прозрачности). Запускать локально на macOS после замены icon.png и коммитить
# результат.
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p png

render() { sips -z "$1" "$1" icon.png --out "png/$2" >/dev/null; }

render 16 favicon-16x16.png
render 32 favicon-32x32.png
render 180 apple-touch-icon.png
render 192 android-chrome-192x192.png
render 512 android-chrome-512x512.png
# Фон залит до краёв, поэтому maskable-версии те же картинки.
cp png/android-chrome-192x192.png png/android-chrome-192x192-maskable.png
cp png/android-chrome-512x512.png png/android-chrome-512x512-maskable.png

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
