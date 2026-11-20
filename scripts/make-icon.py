"""Draws the 1024 px app icon from the mascot frames. Usage: make-icon.py frames.json out.png
frames.json is the list of per-form pixel rows in Sources/PowerLevel/PixelSprite.swift.
Then: sips to the iconset sizes and `iconutil -c icns` to make Resources/AppIcon.icns."""
import json, zlib, struct, sys
frames = json.load(open(sys.argv[1])); out = sys.argv[2]
g = frames[2]; GH, GW = len(g), len(g[0])
N = 1024
PAL = {'k': (0x3a, 0x3a, 0x55), 'K': (0x5c, 0x5c, 0x80), 's': (0xf1, 0xc2, 0x7d), 'S': (0xff, 0xdd, 0xa8),
       'd': (0xc6, 0x86, 0x42), 'g': (0x29, 0x6b, 0xdb), 'G': (0x1a, 0x45, 0x99), 'v': (0x40, 0xff, 0x80),
       'V': (0x1c, 0x9a, 0x50), 'e': (0x14, 0x14, 0x1c), 'w': (0xff, 0xff, 0xff), 'o': (0xee, 0x78, 0x1a),
       'O': (0x9e, 0x48, 0x0d), 'j': (0x24, 0x24, 0x38), 'F': (0x5a, 0x93, 0xf0), 'p': (0xff, 0x8c, 0x1a), 'm': (0x8a, 0x2c, 0x2c)}
acc = (0xff, 0xd6, 0x0a); BG = (6, 26, 13); RING = (0x40, 0xff, 0x80)
def mix(a, b, t): return tuple((a[i] * (100 - t) + b[i] * t) // 100 for i in range(3))
def colour(c):
    if c in 'bA': return acc
    if c == 'B': return mix(acc, (0, 0, 0), 30)
    if c == 'h': return mix(acc, (0, 0, 0), 18)
    if c == 'H': return mix(acc, (255, 255, 255), 25)
    if c == 'L': return mix(acc, (255, 255, 255), 65)
    if c == 'a': return mix(acc, BG, 55)
    return PAL[c]
M, RAD, BORDER = 100, 185, 14          # Apple icon grid: 824 px tile inside a 1024 canvas
def inside(x, y, m, r):
    lo, hi = m, N - 1 - m
    if x < lo or x > hi or y < lo or y > hi: return False
    cx = min(max(x, lo + r), hi - r); cy = min(max(y, lo + r), hi - r)
    return (x - cx) ** 2 + (y - cy) ** 2 <= r * r
PX = 14
ox = (N - GW * PX) // 2; oy = (N - GH * PX) // 2 + 6
rows = []
for y in range(N):
    row = bytearray()
    for x in range(N):
        if not inside(x, y, M, RAD): row += b'\x00\x00\x00\x00'; continue
        col = RING if not inside(x, y, M + BORDER, RAD - BORDER) else BG
        gx, gy = (x - ox) // PX, (y - oy) // PX
        if col == BG and 0 <= gx < GW and 0 <= gy < GH and g[gy][gx] != '.': col = colour(g[gy][gx])
        row += bytes(col) + b'\xff'
    rows.append(b'\x00' + bytes(row))
raw = zlib.compress(b''.join(rows), 9)
def chunk(t, d): return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
open(out, 'wb').write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', N, N, 8, 6, 0, 0, 0)) + chunk(b'IDAT', raw) + chunk(b'IEND', b''))
