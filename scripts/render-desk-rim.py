"""Render the desk's continuous rounded edge profile as a 4x nine-slice asset."""

import math
from pathlib import Path
import struct
import zlib


SCALE = 4
SIDE = 48
RADIUS = 16
pixels = SIDE * SCALE
rows = bytearray()

for y in range(pixels):
    rows.append(0)
    for x in range(pixels):
        px, py = (x + 0.5) / SCALE, (y + 0.5) / SCALE
        qx = abs(px - SIDE / 2) - (SIDE / 2 - RADIUS)
        qy = abs(py - SIDE / 2) - (SIDE / 2 - RADIUS)
        distance = -(math.hypot(max(qx, 0), max(qy, 0)) + min(max(qx, qy), 0) - RADIUS)
        if distance < -0.125 or distance > 5:
            rows.extend((0, 0, 0, 0))
            continue
        contact = 0.05 * math.exp(-((distance - 0.12) / 0.50) ** 2)
        ridge = 0.58 * math.exp(-((distance - 1.12) / 0.75) ** 2)
        shoulder = 0.12 * math.exp(-((distance - 2.05) / 0.9) ** 2)
        profile = ridge + shoulder - contact
        coverage = max(0, min(1, (distance + 0.125) * SCALE))
        alpha = round(abs(profile) * coverage * 255)
        rows.extend((255, 249, 241, alpha) if profile >= 0 else (100, 91, 78, alpha))


def chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


output = Path(__file__).resolve().parent.parent / "Sources/Menuminder/Assets/Desk/soft-rim.png"
output.write_bytes(
    b"\x89PNG\r\n\x1a\n"
    + chunk(b"IHDR", struct.pack(">IIBBBBB", pixels, pixels, 8, 6, 0, 0, 0))
    + chunk(b"IDAT", zlib.compress(rows, 9))
    + chunk(b"IEND", b"")
)
