import zlib, struct, sys, json
W, H = 40, 52
OX, OY = 4, 13

def blank(): return [['.'] * W for _ in range(H)]
def put(g, x, y, c):
    x += OX; y += OY
    if 0 <= x < W and 0 <= y < H: g[y][x] = c
def rect(g, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1): put(g, x, y, c)
def sym(g, x0, y0, x1, y1, c):
    rect(g, x0, y0, x1, y1, c); rect(g, 31 - x1, y0, 31 - x0, y1, c)
def rows(g, spec, c):
    for y, xs in spec:
        for x in xs: put(g, x, y, c)
R = lambda a, b: list(range(a, b + 1))

def body(pose, face, hair, extra, long):
    g = blank()
    hc, hl = ('k', 'K') if hair == 'calm' else ('H', 'L')
    if long:
        for y in range(10, 29):
            half = 8 if y < 22 else 8 - (y - 21)
            rect(g, 16 - half, y, 15 + half, y, 'B')
        for (x, y) in [(8, 18), (8, 19), (23, 20), (23, 21), (9, 24), (22, 25), (15, 26), (16, 27)]: put(g, x, y, 'H')

    # ---- legs, boots
    if pose == 0:
        rect(g, 10, 24, 21, 25, 'g')
        sym(g, 10, 26, 14, 32, 'g'); sym(g, 9, 27, 9, 31, 'g')
        sym(g, 14, 26, 14, 32, 'G'); sym(g, 10, 32, 14, 32, 'G')
        sym(g, 9, 33, 14, 35, 'o'); sym(g, 9, 33, 14, 33, 'p'); sym(g, 8, 35, 14, 35, 'O')
    else:
        rect(g, 10, 24, 21, 25, 'g')
        sym(g, 8, 26, 13, 32, 'g'); sym(g, 7, 28, 7, 31, 'g'); sym(g, 14, 26, 15, 26, 'g')
        sym(g, 13, 27, 13, 32, 'G'); sym(g, 8, 32, 13, 32, 'G')
        sym(g, 7, 33, 13, 35, 'o'); sym(g, 7, 33, 13, 33, 'p'); sym(g, 6, 35, 13, 35, 'O')

    # ---- torso: sleeveless gi, open collar, belt with knot
    rect(g, 10, 14, 21, 23, 'g')
    sym(g, 10, 14, 10, 21, 'G')
    rect(g, 14, 14, 17, 14, 's'); rect(g, 15, 15, 16, 16, 's'); put(g, 15, 16, 'd'); put(g, 16, 16, 'd')
    for (x, y) in [(13, 14), (14, 15), (14, 16), (15, 17), (15, 18)]:
        put(g, x, y, 'G'); put(g, 31 - x, y, 'G')
    rect(g, 10, 21, 21, 21, 'G')
    rect(g, 10, 22, 21, 23, 'b'); rect(g, 15, 22, 16, 23, 'B')
    for (x, y) in [(14, 24), (14, 25), (13, 26), (17, 24), (18, 25)]: put(g, x, y, 'b')

    # ---- neck, head
    rect(g, 14, 12, 17, 13, 'd')
    rect(g, 11, 2, 20, 9, 's'); rect(g, 12, 10, 19, 10, 's'); rect(g, 13, 11, 18, 11, 'd')
    sym(g, 10, 5, 10, 7, 'd')
    put(g, 20, 8, 'd'); put(g, 20, 9, 'd'); put(g, 16, 8, 'd')

    # ---- hair: a cap, a fringe and five shaded spikes (taller and more upright when powered up)
    hs = 'j' if hair == 'calm' else 'h'
    rows(g, [(0, R(8, 23)), (1, R(9, 22)), (2, R(10, 21)), (3, [10, 11, 12, 15, 16, 19, 20, 21]),
             (4, [10, 11, 16, 21]), (5, [10, 21])], hc)
    rows(g, [(1, [12, 18]), (2, [13, 19])], hl); rows(g, [(1, [22]), (2, [21]), (3, [21, 16])], hs)
    if hair != 'spiky':
        spikes = [(9, 13, 6, -2), (19, 23, 26, -3), (11, 15, 10, -6), (17, 21, 21, -5), (14, 18, 15, -8)]
    else:
        up = 2 if extra else 0
        spikes = [(8, 13, 5, -5), (19, 24, 27, -6), (10, 15, 10, -9 - up), (17, 22, 22, -10 - up), (13, 18, 16, -12 - up)]
        if extra: spikes = [(8, 11, 3, 0), (21, 24, 29, -1)] + spikes
    for (x0, x1, tx, ty) in spikes:
        for y in range(ty, 1):
            t = (y - ty) / max(-ty, 1)
            l = round(tx + (x0 - tx) * t); r = round(tx + (x1 - tx) * t)
            for x in range(l, r + 1): put(g, x, y, hc)
            if r - l >= 2: put(g, r, y, hs)
            if r - l >= 3: put(g, l + 1, y, hl)

    # ---- eyes, brows, mouth
    def eyes(pts, c):
        for (x, y) in pts: put(g, x, y, c); put(g, x - 5, y, c)
    def brows(pts):
        for (x, y) in pts: put(g, x, y, 'e'); put(g, 31 - x, y, 'e')
    if face == 0:
        eyes([(17, 7), (18, 7), (19, 6)], 'e')
    elif face == 1:
        brows([(17, 5), (18, 5), (19, 5)]); eyes([(17, 6), (17, 7)], 'w'); eyes([(18, 6), (18, 7)], 'e')
    elif face == 2:
        brows([(16, 5), (17, 5), (18, 4), (19, 4)]); eyes([(17, 6)], 'w'); eyes([(18, 6), (17, 7)], 'e')
    else:
        brows([(17, 4), (18, 3), (19, 3)])
        eyes([(x, y) for x in (17, 18, 19) for y in (5, 6, 7)], 'w'); eyes([(18, 6)], 'e')
    if face == 0:
        rows(g, [(10, [15, 16]), (9, [14, 17])], 'm')
    elif face == 1:
        rows(g, [(10, [14, 15, 16, 17])], 'm')
    elif face == 2:
        rows(g, [(10, [14, 17])], 'm'); rows(g, [(10, [15, 16])], 'w'); rows(g, [(9, [14, 15, 16, 17])], 'm')
    else:
        rect(g, 14, 9, 17, 11, 'm'); put(g, 15, 9, 'w'); put(g, 16, 9, 'w')

    # ---- arms
    if pose == 0:
        sym(g, 7, 14, 9, 21, 's'); sym(g, 8, 14, 9, 14, 's'); sym(g, 7, 15, 7, 21, 'd'); sym(g, 8, 17, 8, 18, 'S')
        sym(g, 7, 22, 9, 23, 'p'); sym(g, 7, 24, 9, 25, 's'); sym(g, 7, 25, 9, 25, 'd')
    elif pose == 1:
        sym(g, 5, 14, 9, 16, 's'); sym(g, 5, 16, 9, 16, 'd'); sym(g, 6, 14, 8, 14, 'S')
        sym(g, 4, 11, 6, 14, 's'); sym(g, 4, 11, 4, 14, 'd')
        sym(g, 4, 9, 6, 10, 'p'); sym(g, 4, 6, 6, 8, 's'); sym(g, 4, 8, 6, 8, 'd')
    else:
        sym(g, 7, 12, 9, 15, 's'); sym(g, 6, 8, 8, 12, 's'); sym(g, 6, 8, 6, 12, 'd'); sym(g, 7, 10, 7, 11, 'S')
        sym(g, 5, 4, 7, 8, 's'); sym(g, 5, 4, 5, 8, 'd')
        sym(g, 5, 2, 7, 3, 'p'); sym(g, 5, -1, 7, 1, 's'); sym(g, 5, 1, 7, 1, 'd')

    # ---- muscle definition: shoulders, biceps, pecs, abs, thighs
    if pose == 0:
        sym(g, 7, 13, 9, 13, 's'); sym(g, 8, 13, 8, 13, 'S')
        sym(g, 6, 15, 6, 19, 'd'); sym(g, 7, 15, 7, 19, 's'); sym(g, 8, 15, 8, 17, 'S'); sym(g, 7, 20, 9, 20, 'd')
        sym(g, 11, 26, 11, 29, 'F'); sym(g, 11, 30, 13, 30, 'G')
    else:
        if pose == 1:
            sym(g, 7, 12, 8, 12, 's'); sym(g, 7, 13, 9, 13, 's'); sym(g, 7, 12, 7, 12, 'S'); sym(g, 8, 13, 8, 13, 'S')
            sym(g, 5, 12, 5, 13, 'S')
        else:
            sym(g, 8, 13, 8, 14, 'S'); sym(g, 9, 9, 9, 11, 's'); sym(g, 9, 11, 9, 11, 'd'); sym(g, 8, 9, 8, 10, 'S')
        sym(g, 9, 27, 9, 29, 'F'); sym(g, 9, 30, 12, 30, 'G')
    sym(g, 11, 15, 12, 15, 'F'); sym(g, 11, 18, 13, 18, 'G'); sym(g, 13, 20, 14, 20, 'G'); sym(g, 12, 19, 12, 19, 'F')
    return g

def aura(g, tier):
    if tier == 0: return g
    solid = [[g[y][x] != '.' for x in range(W)] for y in range(H)]
    def near(x, y, k):
        if k < 0: return False
        for dy in range(-k, k + 1):
            for dx in range(-(k - abs(dy)), k - abs(dy) + 1):
                xx, yy = x + dx, y + dy
                if 0 <= xx < W and 0 <= yy < H and solid[yy][xx]: return True
        return False
    r = (0, 2, 3, 3, 4)[tier]
    for y in range(H):
        for x in range(W):
            if g[y][x] != '.': continue
            if near(x, y, r) and not near(x, y, r - 1): g[y][x] = 'A'
            elif tier >= 3 and near(x, y, r + 1) and not near(x, y, r) and (x + y) % 2 == 0: g[y][x] = 'a'
    if tier >= 2:
        prof = (1, 3, 5, 2, 4, 1, 3, 2) if tier >= 3 else (0, 2, 3, 1, 2, 0, 1, 1)
        for x in range(8, W - 8):
            top = next((y for y in range(H) if g[y][x] != '.'), None)
            if top is None: continue
            h = prof[x % 8] + (1 if tier == 4 else 0)
            for k in range(1, h + 1):
                if top - k >= 0: g[top - k][x] = 'A' if k == h else 'a'
    if tier >= 3:
        for pts in ([(1, 20), (2, 21), (3, 22), (2, 23), (1, 24), (2, 25)], [(38, 28), (37, 29), (36, 30), (37, 31), (38, 32), (37, 33)]):
            for (x, y) in pts: g[y][x] = 'w'
    if tier == 4:
        for pts in ([(38, 10), (37, 11), (36, 12), (37, 13), (38, 14)], [(1, 38), (2, 39), (3, 40), (2, 41), (1, 42)]):
            for (x, y) in pts: g[y][x] = 'w'
    return g

PAL = {'k': (0x3a, 0x3a, 0x55), 'K': (0x5c, 0x5c, 0x80), 's': (0xf1, 0xc2, 0x7d), 'S': (0xff, 0xdd, 0xa8),
       'd': (0xc6, 0x86, 0x42), 'g': (0x29, 0x6b, 0xdb), 'G': (0x1a, 0x45, 0x99), 'v': (0x40, 0xff, 0x80),
       'V': (0x1c, 0x9a, 0x50), 'e': (0x14, 0x14, 0x1c), 'w': (0xff, 0xff, 0xff), 'o': (0xee, 0x78, 0x1a),
       'O': (0x9e, 0x48, 0x0d), 'j': (0x24, 0x24, 0x38), 'F': (0x5a, 0x93, 0xf0), 'p': (0xff, 0x8c, 0x1a), 'm': (0x8a, 0x2c, 0x2c)}
ACC = [(0x40,0xff,0x80),(0xff,0x45,0x3a),(0xff,0xd6,0x0a),(0xff,0xd9,0x33),(0xff,0xa8,0x14),(0xff,0x38,0x70),(0x38,0xb8,0xff),(0xd6,0xe4,0xff)]
BG = (5, 20, 10)
def mix(a, b, t): return tuple((a[i] * (100 - t) + b[i] * t) // 100 for i in range(3))

def png(path, g, tier, scale=6):
    acc = ACC[tier]
    data = []
    for y in range(H):
        row = bytearray()
        for x in range(W):
            c = g[y][x]
            if c == '.': col = BG
            elif c in 'bA': col = acc
            elif c == 'B': col = mix(acc, (0, 0, 0), 30)
            elif c == 'H': col = mix(acc, (255, 255, 255), 25)
            elif c == 'h': col = mix(acc, (0, 0, 0), 18)
            elif c == 'L': col = mix(acc, (255, 255, 255), 65)
            elif c == 'a': col = mix(acc, BG, 55)
            else: col = PAL[c]
            row += bytes(col) * scale
        data += [b'\x00' + bytes(row)] * scale
    raw = zlib.compress(b''.join(data))
    def chunk(t, d): return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    open(path, 'wb').write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', W * scale, H * scale, 8, 2, 0, 0, 0)) + chunk(b'IDAT', raw) + chunk(b'IEND', b''))

out = sys.argv[1]
frames = []
FORMS = [(0, 0, 'calm', False, False, 0), (0, 1, 'calm', False, False, 1), (1, 2, 'spiky', False, False, 2),
         (1, 2, 'spiky', False, False, 3), (1, 2, 'spiky', False, True, 3), (0, 1, 'calmpow', False, False, 2),
         (1, 2, 'spiky', True, False, 4), (2, 3, 'spiky', True, False, 4)]
for t, (pose, face, hair, extra, long, lvl) in enumerate(FORMS):
    g = aura(body(pose, face, hair, extra, long), lvl)
    png(f'{out}/t{t}.png', g, t)
    frames.append([''.join(r) for r in g])
json.dump(frames, open(f'{out}/frames.json', 'w'))
