"""Draws the room art of M11 Stage 1 (docs/design/m11-rooms.md sections 3, 4 and 5): the layered backdrop of each of the nine
rooms, the richer landmark of each room, the landmark's celebration piece and the stage reaction's end state.

    python tools/make_room_art.py

Writes (deterministic: the same script gives the same bytes) into app/assets/art/rooms/:
  <room>_far.svg       1600 x 200   the far band (distance: hills, sea, forest, cave wall, street, wall panels); pale, low contrast
  <room>_ground.svg    2400 x 100   the ground band (grass, sand, quay, paving, floor)
  <room>_top.svg       2400 x 100   the top band (clouds, cave ceiling, awning, cornice and garland); not every room has one
  <room>_corner.svg     240 x 200   the start-side corner cluster (bottom right of the stage)
  <room>_landmark.svg   200 x 200   the room's landmark (bottom left of the stage, or beside the card on tablet landscape)
  <room>_piece.svg      200 x 200   the celebration's new piece, drawn over the landmark in the same box
  <room>_reacted.svg    200 x 200   the stage reaction's end state, drawn over the landmark in the same box
  (Until 2026-11-15 it also wrote app/assets/art/hosts/goni_<pose>_safe.svg, Goni in a grey colour-safe skin. Retired: the owner
  gave Goni colour; his recolourable poses come from docs/design/m11/make_host_poses.py, docs/design/m11-rooms.md section 5.2.)
Rooms: numbers (Counting Hills), colors (Colour Bay), shapes (Shape Forest), logic (Riddle Grotto), cs (Robot Harbour),
math (Market Village), eng, heb, rus (the three language rooms behind their doors).

How a backdrop is put together (the developer's RoomBackdrop does exactly this; LAYERS below is the table of the spec, 3.2):
  1. the sky or wall: a vertical gradient over the whole stage, SKY[room] (top colour, bottom colour);
  2. the far band: height 0.66 of the stage, its bottom on the stage's bottom, centred, aspect kept, cropped at the sides;
  3. the ground band: height 0.22 of the stage, bottom, centred, aspect kept, cropped at the sides;
  4. the top band (if any): height 0.22 of the stage, top, centred, aspect kept, cropped at the sides;
  5. the corner: height 0.52 of the stage (no wider than 0.30 of its width), 6 in from the start (right) edge and 2 up from the
     bottom; in a language room 0.64 (no wider than 0.32);
  6. the landmark (part of the backdrop, behind the content): 0.44 of the stage's height (at most 0.24 of its width, for the tall
     robot stage) at the end-bottom corner (6 in, 2 up); a
     course window is 0.52 of the height (at most 0.26 of the width), 10 in from the end side, its box's bottom at 0.74. Piece and reaction are drawn in the landmark's own box.
  Nothing is ever stretched: every layer keeps its aspect and is cropped by the stage's rounded clip. Bands are wide enough that
  no stage shape (phone 2.6:1, tablet 2.1:1 to 2.8:1, the celebration window 3.5:1, the tall robot stage 1.2:1) shows their ends.

Rules the drawings keep (spec 3.1): the middle of the stage (15% to 80% of its height) stays light and low in chroma, so a
picture laid on it keeps its contrast; the colourful parts live at the edges; nothing in a band is a small repeated, countable
object in the working area; no text, letters or numerals in any picture; no clock face (Market Village teaches time); no flag,
no national symbol in the language rooms. Colour Bay is the most vivid room (2026-11-15): its colour lives at the edges (the
rainbow, the parasol, the easel, the shell), its middle is a pale sky and pale shallow water.

Style: the map islands' style (tools/make_home_map.py): flat shapes with no outline, lit from the upper left with one shade tone
on the right, soft ground shadows (#2B2350 at 12%), the world palette of design/tokens.json.

References looked at on 2026-11-14 (photographs and facts; every drawing here is our own, nothing traced or copied):
  Harbours: Bing image search "harbour quay bollard crane containers" and "small fishing harbour pier lighthouse bollards
    boats": gantry and jib cranes with a lattice boom, a trolley and a hook on a cable; containers stacked in a grid with
    corrugated sides; plank piers on posts; mushroom-shaped mooring bollards with rope; tyre fenders on the quay's face;
    a white lighthouse with red bands and a lantern room. Port of Haifa photographs (see tools/make_home_map.py).
  Market: Bing image search "Mahane Yehuda market fruit stall awning crates": produce heaped in sloping blocks of one colour in
    wooden crates, striped awnings, stone arcades of the covered market, glass jars on the counter.
  Grotto: Bing image search "Soreq stalactite cave" and Wikipedia "Stalactite": cones hanging from the ceiling in many lengths,
    stalagmites rising under them, columns where the two meet; Rosh HaNikra's chalk sea-cave arch (see make_home_map.py).
  Forest: Wikipedia "Cupressus sempervirens" (the narrow planted spire), fir and cypress woods in rows of cones.
  Classroom corners: Bing image search "kindergarten reading corner bookshelf rug cushions plant window": low shelves with
    books, round rugs, floor cushions, an easel, potted plants, paper lanterns on a string, drawings pegged on a line.
  Rock pools and beaches for Colour Bay; a budgerigar's perch stand (a T-perch with a ring and a bell) for Pip's room.
References looked at on 2026-11-15 (the vivid Colour Bay and the harbour's crate, QA of Stage 1):
  Bing image search "colorful beach huts striped umbrellas turquoise sea": turquoise water lighter in the shallows, golden sand
    with a white line of foam, rainbow-striped parasols in wedges, sailboats with striped sails. Scallop shells (fan of ribs
    from a hinge with two "ears", a scalloped rim) and starfish (five tapering arms) from the same beach photographs.
  Bing image search "crane hook lifting wooden crate slings": four slings from the crate's top corners meeting at the hook in a
    pyramid, a slatted crate with a thick frame and a diagonal brace.
  Our own approved art: app/assets/art/scenes/home_phone.svg (the islands), app/assets/art/world/*.svg (the landmark icons),
  app/assets/art/languages/door_*.svg (the windows: round, arched, square).
"""
import math
import os

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
OUT = os.path.join(ROOT, 'app', 'assets', 'art', 'rooms')
HOSTS = os.path.join(ROOT, 'app', 'assets', 'art', 'hosts')
CAST = os.path.join(ROOT, 'design', 'assets')

INK = '#2B2350'
WHITE = '#FFFFFF'
GOLD, GOLD_DEEP, GOLD_TINT = '#FFC83D', '#E0A21A', '#FFF1C4'
SKY_TOP, SKY_BOTTOM = '#CDEFFF', '#FFF1D6'
SEA1, SEA2, SEA3 = '#A8E3E3', '#6CCBCD', '#3FAFB3'
SAND, SAND_SHADE = '#F6DDB0', '#E8C48A'
GRASS, GRASS_SHADE, TREE, TREE_SHADE = '#A8DB8F', '#86C474', '#8FD3A0', '#6FBF8C'
WOOD, WOOD_LIGHT, WOOD_DARK = '#B07A52', '#D7A27A', '#8A5F3E'
ROCK, ROCK_SHADE = '#C9C3D9', '#A9A1C2'
CORAL = '#F07F6E'

ROOMS = ['numbers', 'colors', 'shapes', 'logic', 'cs', 'math', 'eng', 'heb', 'rus']

# The sky (or wall) gradient of each room: top colour, bottom colour. Code-drawn (layer 1).
SKY = {
    'numbers': (SKY_TOP, SKY_BOTTOM),
    'colors': ('#A9DEF9', '#EAF8FD'),
    'shapes': (SKY_TOP, '#EAF7EE'),
    'logic': ('#F7F3FF', '#ECE3FE'),
    'cs': (SKY_TOP, '#EEF6FD'),
    'math': ('#DCE3EF', '#E6EAF3'),   # 2026-11-15: the covered market's roof (was #FFF8EC to #FEEFD6, the screen's own tint)
    'eng': ('#F4F8FD', '#E1ECF8'),
    'heb': ('#FEF6F3', '#FBE4DF'),
    'rus': ('#F8F4FD', '#EBE3F7'),
}

# The layer table (spec 3.2). Fractions of the stage's height; the corner's width is capped at 0.30 of the stage's width.
LAYERS = dict(far=0.66, ground=0.22, top=0.22, corner=0.52, cornerMaxW=0.30, cornerInset=(6, 2), landmark=0.44, landmarkMaxW=0.24,
              landmarkInset=(6, 2),
              # the language rooms: taller furniture in the corner, a bigger window on the wall, its box's bottom at 0.74
              roomCorner=0.64, roomCornerMaxW=0.32, window=0.52, windowMaxW=0.26, windowBottom=0.74)
COURSES = ('eng', 'heb', 'rus')
ASPECT = dict(far=(1600, 200), ground=(2400, 100), top=(2400, 100), corner=(240, 200), landmark=(200, 200))


# ---------------------------------------------------------------- tiny SVG helpers
def f(v):
    s = ('%.2f' % v).rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


def el(tag, **a):
    attrs = ' '.join('%s="%s"' % (k.rstrip('_').replace('_', '-'), f(v) if isinstance(v, (int, float)) else v)
                     for k, v in a.items() if v is not None)
    return '<%s %s/>' % (tag, attrs)


def P(d, fill='none', **a):
    return el('path', d=d, fill=fill, **a)


def E(cx, cy, rx, ry, fill, **a):
    return el('ellipse', cx=cx, cy=cy, rx=rx, ry=ry, fill=fill, **a)


def C(cx, cy, r, fill, **a):
    return el('circle', cx=cx, cy=cy, r=r, fill=fill, **a)


def R(x, y, w, h, fill, rx=None, **a):
    return el('rect', x=x, y=y, width=w, height=h, rx=rx, fill=fill, **a)


def G(body, tr=None, op=None):
    return '<g%s%s>%s</g>' % ('' if tr is None else ' transform="%s"' % tr, '' if op is None else ' opacity="%s"' % f(op), ''.join(body))


def shadow(cx, cy, rx, ry=None):
    return E(cx, cy, rx, ry or rx * 0.16, INK, opacity=0.12)


def doc(w, h, body, label):
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d" role="img" aria-label="%s">'
            % (w, h, w, h, label) + ''.join(body) + '</svg>\n')


def poly(*pts):
    return 'M' + ' L'.join('%s %s' % (f(x), f(y)) for x, y in pts) + ' Z'


def spark(x, y, r=7, fill=GOLD):
    q = r * 0.22
    return P('M%s %s Q%s %s %s %s Q%s %s %s %s Q%s %s %s %s Q%s %s %s %s Z' % (
        f(x), f(y - r), f(x + q), f(y - q), f(x + r), f(y), f(x + q), f(y + q), f(x), f(y + r),
        f(x - q), f(y + q), f(x - r), f(y), f(x - q), f(y - q), f(x), f(y - r)), fill)


def glow(cx, cy, r, col=GOLD_TINT, steps=4, op=0.22):
    return ''.join(C(cx, cy, r * (1 - i / (steps + 1)), col, opacity=op) for i in range(steps))


def tufts(x, y, col, s=1.0):
    return P('M%s %s q%s %s %s %s M%s %s q%s %s %s %s M%s %s q%s %s %s %s' % (
        f(x), f(y), f(-2 * s), f(-7 * s), f(-5 * s), f(-11 * s), f(x + 3 * s), f(y), f(0), f(-9 * s), f(1 * s), f(-14 * s),
        f(x + 6 * s), f(y), f(2 * s), f(-7 * s), f(6 * s), f(-10 * s)), stroke=col, stroke_width=2.6 * s, stroke_linecap='round')


def flower(x, y, petal='#FFFFFF', centre=GOLD, r=4.2):
    out = [P('M%s %s v%s' % (f(x), f(y), f(r * 3)), stroke=GRASS_SHADE, stroke_width=2, stroke_linecap='round')]
    for k in range(5):
        a = k * 72 * math.pi / 180
        out.append(C(x + r * math.cos(a), y + r * math.sin(a), r * 0.62, petal))
    out.append(C(x, y, r * 0.55, centre))
    return ''.join(out)


def cloud(x, y, s=1.0, col=WHITE, op=0.95):
    return G([E(0, 8 * s, 36 * s, 13 * s, col), C(-14 * s, 0, 15 * s, col), C(10 * s, -5 * s, 19 * s, col),
              C(28 * s, 3 * s, 11 * s, col)], 'translate(%s %s)' % (f(x), f(y)), op)


def gull(x, y, col='#7FB9C9', s=1.0):
    return P('M%s %s q%s %s %s 0 q%s %s %s 0' % (f(x), f(y), f(7 * s), f(-8 * s), f(14 * s), f(7 * s), f(-8 * s), f(14 * s)),
             stroke=col, stroke_width=3 * s, stroke_linecap='round', stroke_linejoin='round')


def wavy_top(y, amp, period, w, h_bottom, col, phase=0):
    """A band whose top edge is a gentle wave (period in units), filled down to h_bottom."""
    d = 'M0 %s' % f(y)
    x = 0
    k = phase
    while x < w:
        d += ' q%s %s %s 0' % (f(period / 2), f(-amp if k % 2 == 0 else amp), f(period))
        x += period
        k += 1
    return P(d + ' V%s H0 Z' % f(h_bottom), col)


def cone(cx, base, h, half, lit, shade, trunk=None):
    out = [P(poly((cx - half, base), (cx, base - h), (cx + half, base)), lit),
           P(poly((cx, base - h), (cx + half, base), (cx + half * 0.12, base)), shade)]
    if trunk:
        out.insert(0, R(cx - half * 0.16, base - 2, half * 0.32, h * 0.1, trunk, rx=1.5))
    return ''.join(out)


def crate(x, y, w, h, body=WOOD_LIGHT, frame=WOOD):
    """A wooden crate seen from the front: frame, two slats and the cross brace."""
    t = max(2.5, w * 0.09)
    return ''.join([R(x, y, w, h, body, rx=2),
                    R(x, y, w, t, frame), R(x, y + h - t, w, t, frame), R(x, y, t, h, frame), R(x + w - t, y, t, h, frame),
                    P('M%s %s L%s %s' % (f(x + t), f(y + h - t), f(x + w - t), f(y + t)), stroke=frame, stroke_width=t * 0.9),
                    R(x + w * 0.55, y, w * 0.45, h, INK, opacity=0.07)])


def bollard(x, base, s=1.0, col='#3B3F6B', hi='#5B608F'):
    return ''.join([shadow(x, base, 13 * s, 3 * s), R(x - 7 * s, base - 16 * s, 14 * s, 16 * s, col, rx=2 * s),
                    E(x, base - 17 * s, 11 * s, 5 * s, col), E(x - 2 * s, base - 18 * s, 6 * s, 2.4 * s, hi),
                    R(x - 6 * s, base - 14 * s, 3.5 * s, 12 * s, hi, rx=1.5 * s, opacity=0.6)])


def orange_heap(x, base, w, h, col='#FFA46B', deep='#E37A1E', hi='#FFC79E'):
    """A heap of fruit drawn as one mound with a few highlights (not a row of countable balls)."""
    d = 'M%s %s Q%s %s %s %s Q%s %s %s %s Z' % (f(x), f(base), f(x + w * 0.1), f(base - h * 1.05), f(x + w * 0.5), f(base - h),
                                                f(x + w * 0.9), f(base - h * 1.05), f(x + w), f(base))
    bumps = ''.join(C(x + w * fx, base - h * fy, w * 0.13, col) for fx, fy in ((0.2, 0.62), (0.42, 0.86), (0.64, 0.84), (0.82, 0.58)))
    return ''.join([P(d, col), bumps, P('M%s %s Q%s %s %s %s V%s Z' % (f(x + w * 0.55), f(base), f(x + w * 0.9), f(base - h * 0.9),
                                                                       f(x + w), f(base), f(base)), deep, opacity=0.35),
                    C(x + w * 0.3, base - h * 0.72, w * 0.05, hi), C(x + w * 0.5, base - h * 0.92, w * 0.045, hi),
                    C(x + w * 0.2, base - h * 0.4, w * 0.04, hi)])


# ================================================================ Counting Hills (numbers)
def numbers_top():
    return [sun(1650, 34, 22), cloud(560, 34, 0.9), cloud(1010, 26, 0.7, op=0.85), cloud(1420, 40, 0.95), cloud(1960, 28, 0.75, op=0.85)]


def numbers_far():
    return [P('M0 128 Q110 66 230 112 Q350 52 480 108 Q610 70 730 112 Q860 50 1000 106 Q1130 66 1250 114 Q1370 56 1490 106 Q1550 88 1600 98 V200 H0 Z', '#D3EED6'),
            # a lone round tree on the far ridges, at the sides
            R(256, 78, 6, 22, '#C8B49A', rx=2), C(259, 70, 16, '#BFE4C4'), R(1366, 60, 6, 22, '#C8B49A', rx=2), C(1369, 52, 15, '#BFE4C4'),
            P('M0 156 Q150 104 310 146 Q470 98 630 144 Q790 108 950 146 Q1110 96 1270 142 Q1430 104 1600 136 V200 H0 Z', '#BCE3C2'),
            # a pale winding path up the near hill
            P('M840 200 Q880 170 940 160 Q1010 150 1040 132', stroke='#F3EBD2', stroke_width=7, stroke_linecap='round', opacity=0.9)]


def numbers_ground():
    out = [wavy_top(34, 9, 150, 2400, 100, GRASS), P('M0 84 Q600 72 1200 82 Q1800 92 2400 80 V100 H0 Z', GRASS_SHADE)]
    for x in (140, 520, 860, 1540, 1930, 2260):
        out.append(tufts(x, 60, GRASS_SHADE, 1.3))
    for x, y in ((330, 58), (700, 66), (1700, 62), (2080, 58)):
        out.append(flower(x, y))
    # a pale winding footpath along the middle (one ribbon, not a row of stones to count)
    out += [P('M820 100 Q900 70 1060 66 Q1220 62 1320 58 Q1420 54 1520 46 L1530 52 Q1430 64 1330 70 Q1230 76 1070 80 Q930 84 880 100 Z',
              '#F3EBD2'),
            P('M880 100 Q930 84 1070 80 Q1230 76 1330 70 Q1430 64 1530 52', stroke='#E6D9B8', stroke_width=2.4, opacity=0.8)]
    return out


def numbers_corner():
    return [P('M0 200 Q30 152 120 144 Q200 138 240 150 V200 Z', GRASS_SHADE),
            P('M10 200 Q40 160 120 152 Q200 146 240 158 V200 Z', GRASS),
            shadow(160, 160, 40, 7),
            R(152, 92, 16, 70, WOOD, rx=3), R(160, 92, 8, 70, WOOD_DARK, rx=3, opacity=0.4),
            P('M160 120 L140 100', stroke=WOOD, stroke_width=6, stroke_linecap='round'),
            C(160, 68, 50, TREE), C(122, 92, 26, TREE), C(196, 90, 28, TREE),
            P('M206 50 A50 50 0 0 1 182 112 Q200 118 214 106 Q228 88 224 72 Q220 56 206 50 Z', TREE_SHADE),
            P('M190 112 Q170 122 150 116 Q170 132 196 118 Z', TREE_SHADE),
            E(140, 48, 14, 9, '#B6E6BF', transform='rotate(-30 140 48)'), E(118, 82, 7, 5, '#B6E6BF'),
            # a coral toadstool and a small bush
            R(66, 168, 8, 18, '#FFF3E6', rx=3), P('M54 170 Q70 146 86 170 Z', '#F46A5E'), C(64, 162, 2.6, WHITE), C(75, 158, 2.2, WHITE),
            C(36, 178, 14, '#7FC77A'), C(50, 182, 11, GRASS_SHADE), tufts(98, 190, GRASS_SHADE), flower(226, 176)]


def _step(x0, x1, top, base, front, topc, side, depth=12):
    return [P(poly((x1, top), (x1 + depth, top - depth), (x1 + depth, base - depth), (x1, base)), side),
            R(x0, top, x1 - x0, base - top, front),
            P(poly((x0, top), (x1, top), (x1 + depth, top - depth), (x0 + depth, top - depth)), topc),
            R(x0, top, 5, base - top, WHITE, opacity=0.16),
            R(x0, top, x1 - x0, 3.5, '#C94A42', opacity=0.4)]


STAIR = dict(front='#F46A5E', top='#FF9C90', side='#C94A42', base=186, w=34, depth=12)


def numbers_landmark():
    s = STAIR
    out = [shadow(104, 188, 92, 6), E(100, 189, 96, 6, GRASS, opacity=0.9)]
    for i in (3, 2, 1, 0):                  # columns from the tallest (left, the end side) to the lowest; drawn back to front
        x0 = 186 - s['w'] * (i + 1) - 12
        top = s['base'] - s['w'] * (i + 1)
        out += _step(x0, x0 + s['w'], top, s['base'], s['front'], s['top'], s['side'], s['depth'])
    # a wooden handrail climbing with the steps: a post on each step's back edge, the rail over them
    pts = []
    for i in range(4):
        x0 = 186 - s['w'] * (i + 1) - 12
        top = s['base'] - s['w'] * (i + 1)
        px, py = x0 + s['depth'] + 4, top - s['depth']
        out.append(P('M%s %s V%s' % (f(px), f(py), f(py - 26)), stroke=WOOD, stroke_width=3.2, stroke_linecap='round'))
        pts.append((px, py - 26))
    out.append(P('M%s %s L%s %s' % (f(pts[0][0] + 12), f(pts[0][1] + 12), f(pts[-1][0] - 4), f(pts[-1][1] - 4)), stroke=WOOD_LIGHT,
                 stroke_width=5.5, stroke_linecap='round'))
    out.append(P('M%s %s L%s %s' % (f(pts[0][0] + 12), f(pts[0][1] + 11), f(pts[-1][0] - 4), f(pts[-1][1] - 5)), stroke=WHITE,
                 stroke_width=1.6, stroke_linecap='round', opacity=0.5))
    out += [tufts(14, 188, GRASS_SHADE, 1.2), tufts(176, 189, GRASS_SHADE), flower(190, 178, r=3.4)]
    return out


def numbers_piece():
    """The fifth step, gold, on the end side of the staircase (the stair grows toward the end, the forward direction)."""
    s = STAIR
    x0, top = 186 - s['w'] * 5 - 12, s['base'] - s['w'] * 5
    x1 = x0 + s['w']
    d = s['depth']
    col3_top = s['base'] - s['w'] * 4
    return [glow(x0 + 18, top + 18, 34),
            P(poly((x1, top), (x1 + d, top - d), (x1 + d, col3_top - d), (x1, col3_top)), GOLD_DEEP),
            R(x0, top, s['w'], s['base'] - top, GOLD), R(x0, top, 5, s['base'] - top, WHITE, opacity=0.25),
            P(poly((x0, top), (x1, top), (x1 + d, top - d), (x0 + d, top - d)), '#FFE08A'),
            spark(x0 + 8, top + 22, 4.5, WHITE), spark(x1 + 20, top + 8, 5), spark(x0 + 22, top + 46, 3.6, WHITE)]


def burst(cx, cy, r0, r1, n=10, col=GOLD, deep=GOLD_DEEP, rot=0.0):
    """A ring of n tapering rays from radius r0 to r1 (a "ta-da" burst); each ray has a darker edge so it holds on pale skies."""
    out = []
    for k in range(n):
        a = math.radians(rot + 360 * k / n)
        w = math.radians(180 / n * 0.55)
        p = [(cx + r0 * math.cos(a - w), cy + r0 * math.sin(a - w)), (cx + r1 * math.cos(a), cy + r1 * math.sin(a)),
             (cx + r0 * math.cos(a + w), cy + r0 * math.sin(a + w))]
        out.append(P(poly(*p), col, stroke=deep, stroke_width=1.6, stroke_linejoin='round'))
    return ''.join(out)


def numbers_reacted():
    """The counting dot arrives on the top step: the dot is big and bold, a gold burst of rays stands round it above the stair
    (a new shape on the skyline, so the change reads at the 56 to 64 point header slot, not only a change of colour), and the
    whole top column lights gold. The motion (stage_reaction.dart) ends its hops at (68, 36), the dot's place here."""
    s = STAIR
    x0 = 186 - s['w'] * 4 - 12
    top = s['base'] - s['w'] * 4
    d = s['depth']
    cx, cy = x0 + 30, top - 17
    return [glow(cx, cy, 44),
            burst(cx, cy, 18, 32, 10, rot=-90),
            # the top column, lit: its front, its top and its side in gold
            R(x0, top, s['w'], s['base'] - top, GOLD, opacity=0.88),
            P(poly((x0 + s['w'], top), (x0 + s['w'] + d, top - d), (x0 + s['w'] + d, s['base'] - d), (x0 + s['w'], s['base'])), GOLD_DEEP,
              opacity=0.9),
            P(poly((x0, top), (x0 + s['w'], top), (x0 + s['w'] + d, top - d), (x0 + d, top - d)), '#FFE08A'),
            R(x0, top, 5, s['base'] - top, WHITE, opacity=0.3),
            # the dot: coral with a thick ink ring, standing on the step
            E(cx, top - 4, 12, 3, INK, opacity=0.18),
            C(cx, cy, 14, '#F46A5E', stroke=INK, stroke_width=3.4), C(cx - 4.5, cy - 4.5, 4, WHITE, opacity=0.75),
            spark(cx + 44, cy + 26, 7), spark(cx - 30, cy + 46, 5.5, WHITE)]


# ================================================================ Colour Bay (colors): the most vivid room, colour at the edges
# (2026-11-15, QA of Stage 1: the neutral bay read as washed out). A sunny turquoise bay with golden sand: a rainbow over the
# far islet at the end side, a sailboat with a striped sail, a rainbow parasol, a painter's easel and a red bucket in the corner, a
# coral scallop shell over a turquoise rock pool as the landmark. The middle of the stage stays light (a pale sky and pale shallow
# water), so a colour laid on the stage keeps its contrast; every picture there has its ink outline, so colour is never the only cue.
RAINBOW = ('#FF5A5F', '#FF9F1C', '#FFD93D', '#5BCB6A', '#3E9BEA', '#9B6BE0')
BAY = dict(horizon='#2FB5C8', sea='#84DBE0', shallow='#B6EEE8', foam='#FFFFFF', land='#86D49B', landShade='#62BE7E',
           sand='#FFE0A0', wet='#F6C981', sandShade='#EDB866', rock='#F2C98A', rockShade='#D9A563', water='#35BCD0',
           waterLit='#8EE3EA', shell='#FF9E80', shellLit='#FFC2A8', shellDeep='#E8735A', palm='#3FAE6A', palmShade='#2E8E55',
           trunk='#B07A52', wood='#C98F5E', woodShade='#A26C46', star='#FF6F61', starDeep='#E0493E')


def rainbow_arc(cx, base, r_out, band, op=1.0):
    """A rainbow standing on `base`: six bands from red (outside) to violet (inside)."""
    out = []
    for i, col in enumerate(RAINBOW):
        r = r_out - band * (i + 0.5)
        out.append(P('M%s %s A%s %s 0 0 1 %s %s' % (f(cx - r), f(base), f(r), f(r), f(cx + r), f(base)), stroke=col,
                     stroke_width=band + 0.6))
    return G(out, op=op)


def palm(x, base, h, s=1.0, trunk=None, leaf=None, shade=None):
    b = BAY
    trunk, leaf, shade = trunk or b['trunk'], leaf or b['palm'], shade or b['palmShade']
    tx, ty = x + 10 * s, base - h
    out = [P('M%s %s Q%s %s %s %s' % (f(x), f(base), f(x - 2 * s), f(base - h * 0.55), f(tx), f(ty)), stroke=trunk, stroke_width=5 * s,
             stroke_linecap='round')]
    for dx, dy, col in ((-24, 2, shade), (24, 4, shade), (-20, -10, leaf), (22, -8, leaf), (2, -16, leaf)):
        out.append(P('M%s %s q%s %s %s %s q%s %s %s %s Z' % (f(tx), f(ty), f(dx * 0.5 * s), f((dy - 10) * s), f(dx * s), f(dy * s),
                                                          f(-dx * 0.45 * s), f(-4 * s), f(-dx * s), f(-dy * s)), col))
    return ''.join(out)


def colors_far():
    b = BAY
    out = [R(0, 80, 1600, 120, b['sea']), R(0, 80, 1600, 12, b['horizon']), R(0, 92, 1600, 8, '#5CCCD6'),
           P('M0 150 Q400 140 800 148 Q1200 156 1600 146 V200 H0 Z', b['shallow']),
           # green headlands at the far sides
           P('M0 82 Q60 40 150 50 Q230 58 300 82 Z', b['land']), P('M0 82 Q90 62 180 66 Q250 70 300 82 Z', b['landShade'], opacity=0.5),
           P('M1330 82 Q1410 48 1490 54 Q1560 60 1600 66 V82 Z', b['land'])]
    # the rainbow, its foot on a small sandy islet with a palm (end side, left: over the landmark's corner)
    out += [rainbow_arc(560, 80, 84, 9, 0.9),
            P('M470 84 Q520 66 590 70 Q640 74 664 84 Z', b['sand']), P('M470 84 Q560 78 664 84 Z', b['wet']),
            palm(560, 72, 40, 1.0)]
    for x, y, w in ((150, 112, 60), (700, 104, 44), (1220, 116, 70), (380, 132, 54), (1040, 136, 60), (820, 166, 64), (1420, 170, 56)):
        out.append(P('M%s %s q%s -6 %s 0' % (f(x), f(y), f(w / 2), f(w)), stroke=WHITE, stroke_width=3.4, stroke_linecap='round',
                     opacity=0.9))
    # a sailboat with a striped sail (red, yellow, blue), sailing toward the end side
    sail = [P('M2 -56 L2 -6 L30 -6 Z', '#FFD93D'), P('M2 -56 L2 -40 L11 -40 Z', '#FF5A5F'), P('M2 -28 L2 -6 L30 -6 L20 -28 Z', '#3E9BEA'),
            P('M-2 -48 L-2 -6 L-24 -6 Z', WHITE), P('M-2 -48 L-2 -32 L-10 -32 Z', '#FF5A5F', opacity=0.85)]
    out.append(G([P('M-32 0 L32 0 L23 13 L-23 13 Z', '#FF5A5F'), R(-32, 0, 64, 3.5, WHITE), R(-1.6, -58, 3.2, 58, '#7A4E32')] + sail +
                 [P('M-36 16 q8 -3 16 0 q8 3 16 0 q8 -3 16 0 q8 3 16 0', stroke=WHITE, stroke_width=2.4, stroke_linecap='round')],
                 'translate(960 102)'))
    return out


def colors_ground():
    b = BAY
    out = [R(0, 30, 2400, 70, b['sand']), R(0, 30, 2400, 13, b['wet']), R(0, 84, 2400, 16, b['sandShade'], opacity=0.45),
           P('M0 32 ' + ''.join('q30 -9 60 0 ' for _ in range(40)), stroke=WHITE, stroke_width=5.5, stroke_linecap='round')]
    # three finds on the sand, far apart and all different (nothing to count): a starfish, a pink cone shell, a blue sea glass
    out.append(starfish(760, 70, 13))
    out += [P('M1460 80 Q1468 58 1486 56 Q1478 70 1484 82 Z', '#F48FB1'), P('M1468 78 Q1474 64 1484 58', stroke='#D96490',
            stroke_width=1.6), E(1180, 78, 9, 5.5, '#7EC8F0'), E(1178, 76, 4, 2, WHITE, opacity=0.7)]
    return out


def starfish(cx, cy, r, col=None, deep=None, rot=-8):
    b = BAY
    col, deep = col or b['star'], deep or b['starDeep']
    pts = []
    for k in range(10):
        a = math.radians(rot - 90 + k * 36)
        rr = r if k % 2 == 0 else r * 0.45
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    d = 'M%s %s ' % (f(pts[0][0]), f(pts[0][1])) + ' '.join('L%s %s' % (f(x), f(y)) for x, y in pts[1:]) + ' Z'
    return ''.join([P(d, col, stroke=col, stroke_width=r * 0.28, stroke_linejoin='round'),
                    C(cx, cy, r * 0.22, deep), C(cx - r * 0.3, cy - r * 0.35, r * 0.09, WHITE, opacity=0.8)])


def colors_corner():
    b = BAY
    out = []
    # a rainbow beach parasol (six wedges), its pole stuck in the sand
    wedges = []
    cx, top, rim = 172, 22, 64
    xs = [110, 131, 151, 172, 193, 213, 234]
    for i, col in enumerate(RAINBOW):
        x0, x1 = xs[i], xs[i + 1]
        wedges.append(P('M%s %s L%s %s Q%s %s %s %s Z' % (f(cx), f(top), f(x0), f(rim), f((x0 + x1) / 2), f(rim - 7), f(x1), f(rim)), col))
    out += [P('M176 196 L170 30', stroke=b['woodShade'], stroke_width=5, stroke_linecap='round')] + wedges + [
        P('M%s %s Q%s %s %s %s' % (f(xs[0]), f(rim), f(cx), f(top - 26), f(xs[-1]), f(rim)), stroke=WHITE, stroke_width=2.2, opacity=0.35),
        C(cx, top - 2, 4, b['woodShade'])]
    out.append(shadow(106, 196, 60, 5))
    # the painter's easel with its canvas: three bold paint blots (red, yellow, blue) and a green stroke, no picture to name
    out += [P('M106 40 L120 192', stroke=b['woodShade'], stroke_width=7, stroke_linecap='round'),
            P('M104 36 L70 196 M104 36 L138 196', stroke=b['wood'], stroke_width=8, stroke_linecap='round'),
            R(58, 126, 94, 9, b['wood'], rx=3), R(58, 132, 94, 3, b['woodShade']),
            R(62, 48, 86, 76, '#E9D7BE', rx=3), R(67, 53, 76, 66, WHITE, rx=2),
            P('M78 66 q8 -8 18 -2 q8 6 2 14 q-6 8 -16 4 q-10 -6 -4 -16 Z', '#FF5A5F'),
            P('M108 62 q12 -6 20 4 q6 10 -4 16 q-12 4 -18 -4 q-4 -10 2 -16 Z', '#FFD93D'),
            P('M90 92 q12 -6 22 2 q8 10 -2 18 q-12 6 -20 -2 q-6 -10 0 -18 Z', '#3E9BEA'),
            P('M118 104 q8 -8 18 -4', stroke='#5BCB6A', stroke_width=6, stroke_linecap='round'),
            R(96, 32, 16, 18, b['wood'], rx=3)]
    # a red bucket with a yellow spade at the easel's foot
    out += [P('M160 160 h40 l-5 32 q-1 5 -6 5 h-18 q-5 0 -6 -5 Z', '#FF5A5F'), R(158, 156, 44, 7, '#E0393F', rx=3),
            P('M162 160 Q180 140 198 160', stroke='#7A4E5A', stroke_width=2.2),
            R(166, 166, 5, 24, WHITE, rx=2.5, opacity=0.45),
            P('M206 134 L194 182', stroke='#F0A500', stroke_width=4.4, stroke_linecap='round'),
            P('M188 176 q-4 14 4 18 q10 2 12 -12 Z', '#FFD93D'),
            starfish(30, 186, 12, rot=10)]
    return out


def colors_landmark():
    """A giant coral scallop shell standing behind a round turquoise rock pool, a starfish on the rim and a pearl."""
    b = BAY
    cx, cy = POOL['cx'], POOL['cy']
    out = [shadow(100, 190, 92, 7)] + shell_fan(lambda i: b['shell'] if i % 2 == 0 else b['shellLit'])
    out += [P('M%s %s A%s %s 0 0 1 %s %s' % (f(cx - 52), f(cy - 6), f(52), f(50), f(cx + 52), f(cy - 6)), stroke=WHITE, stroke_width=3,
              opacity=0.5),
            # the hinge's two ears
            P('M%s %s l-16 0 l4 -12 Z M%s %s l16 0 l-4 -12 Z' % (f(cx - 6), f(cy - 4), f(cx + 6), f(cy - 4)), b['shellDeep']),
            # the pool in front: a rim of warm sandstone and the turquoise water
            E(cx, cy + 4, 90, 24, b['rockShade']), E(cx, cy, 86, 21, b['rock']),
            E(cx + 2, cy + 1, 70, 14, b['water']), E(cx - 6, cy - 2, 52, 8, b['waterLit']),
            P('M%s %s q10 -4 20 0 M%s %s q8 -3 16 0' % (f(cx - 34), f(cy - 1), f(cx + 16), f(cy + 5)), stroke=WHITE, stroke_width=2.4,
              stroke_linecap='round', opacity=0.9),
            starfish(cx - 70, cy + 4, 13, rot=14),
            # a pearl on the rim
            C(cx + 74, cy - 10, 8, WHITE), C(cx + 72, cy - 12, 2.6, '#F1EEF6'), E(cx + 74, cy - 2, 7, 2, INK, opacity=0.12)]
    return out


def shell_fan(colour_of, R0=94, n=9):
    """The scallop's fan: ribs from the hinge with a scalloped rim; `colour_of(i)` colours rib i (0 = the end side)."""
    cx, cy = POOL['cx'], POOL['cy']
    hinge = (cx, cy - 6)
    out = []
    for i in range(n):
        a0 = math.pi + i * math.pi / n
        a1 = math.pi + (i + 1) * math.pi / n
        p0 = (hinge[0] + R0 * math.cos(a0), hinge[1] + R0 * 0.95 * math.sin(a0))
        p1 = (hinge[0] + R0 * math.cos(a1), hinge[1] + R0 * 0.95 * math.sin(a1))
        mid = (a0 + a1) / 2
        pm = (hinge[0] + R0 * 1.08 * math.cos(mid), hinge[1] + R0 * 1.03 * math.sin(mid))
        out.append(P('M%s %s L%s %s Q%s %s %s %s Z' % (f(hinge[0]), f(hinge[1]), f(p0[0]), f(p0[1]), f(pm[0]), f(pm[1]), f(p1[0]), f(p1[1])),
                     colour_of(i)))
    # the ribs' grooves
    for i in range(1, n):
        a = math.pi + i * math.pi / n
        out.append(P('M%s %s L%s %s' % (f(hinge[0] + 18 * math.cos(a)), f(hinge[1] + 18 * math.sin(a)), f(hinge[0] + R0 * 0.96 * math.cos(a)),
                                       f(hinge[1] + R0 * 0.92 * math.sin(a))), stroke=INK, stroke_width=1.6, opacity=0.14))
    return out


def colors_piece():
    """The new swirl in the pool: the rainbow's colours, shown only in the celebration (after the last answer)."""
    cx, cy = POOL['cx'], POOL['cy']
    out = [glow(cx, cy, 46)]
    for i, col in enumerate(('#FF5A5F', '#FFD93D', '#3E9BEA', '#5BCB6A')):
        r = 40 - i * 9
        out.append(P('M%s %s A%s %s 0 1 1 %s %s' % (f(cx - r), f(cy), f(r), f(r * 0.3), f(cx + r * 0.8), f(cy)), stroke=col,
                     stroke_width=6, stroke_linecap='round'))
    return out + [spark(cx + 46, cy - 26, 6), spark(cx - 40, cy - 22, 4.5)]


SHELL_RAINBOW = ('#FF5A5F', '#FF7F3E', '#FF9F1C', '#FFD93D', '#8FD45C', '#5BCB6A', '#3EB8D8', '#3E9BEA', '#9B6BE0')


def colors_reacted():
    """The reaction's end state: the whole shell lights up in the rainbow's colours (it covers the shell exactly, so even a corner of
    it shows the change), a splash crown stands in the pool with two ripple rings, and sparks: a change of shape, not only of colour."""
    cx, cy = POOL['cx'], POOL['cy']
    b = BAY
    out = [glow(cx, cy - 50, 70, GOLD_TINT, 4, 0.3)] + shell_fan(lambda i: SHELL_RAINBOW[i])
    out += [P('M%s %s A%s %s 0 0 1 %s %s' % (f(cx - 52), f(cy - 6), f(52), f(50), f(cx + 52), f(cy - 6)), stroke=WHITE, stroke_width=4,
              opacity=0.7),
            # the pool again in front of the lit shell (the overlay is drawn over the whole landmark)
            E(cx, cy + 4, 90, 24, b['rockShade']), E(cx, cy, 86, 21, b['rock']),
            E(cx + 2, cy + 1, 70, 14, b['water']), E(cx - 6, cy - 2, 52, 8, b['waterLit']),
            starfish(cx - 70, cy + 4, 13, rot=14), C(cx + 74, cy - 10, 8, WHITE), C(cx + 72, cy - 12, 2.6, '#F1EEF6'),
            # ripple rings on the water
            E(cx, cy + 2, 60, 12, 'none', stroke=WHITE, stroke_width=3.2, opacity=0.95),
            E(cx, cy + 2, 36, 7.5, 'none', stroke=INK, stroke_width=2.4, opacity=0.35),
            # the splash crown: a ring of droplets thrown up from the middle of the pool
            P('M%s %s q-6 -18 -16 -22 q10 2 14 12 q-2 -16 4 -28 q4 14 2 28 q4 -12 14 -12 q-10 8 -12 22 Z' % (f(cx - 6), f(cy + 1)), WHITE),
            P('M%s %s q-6 -18 -16 -22 q10 2 14 12 q-2 -16 4 -28 q4 14 2 28 q4 -12 14 -12 q-10 8 -12 22 Z' % (f(cx - 6), f(cy + 1)),
              stroke='#35BCD0', stroke_width=2, opacity=0.6),
            C(cx - 22, cy - 30, 4, WHITE, stroke='#35BCD0', stroke_width=1.6), C(cx + 20, cy - 36, 3.4, WHITE, stroke='#35BCD0', stroke_width=1.6),
            C(cx + 2, cy - 44, 3, WHITE, stroke='#35BCD0', stroke_width=1.6),
            spark(cx - 64, cy - 88, 9), spark(cx + 66, cy - 80, 7), spark(cx + 10, cy - 104, 5.5, WHITE)]
    return out


# ================================================================ Shape Forest (shapes)
def shapes_far():
    out = []
    back = [(30, 92), (95, 112), (150, 84), (215, 120), (280, 96), (345, 116), (405, 90), (470, 124), (535, 98), (600, 114),
            (660, 88), (725, 120), (790, 102), (855, 118), (915, 92), (980, 122), (1045, 98), (1110, 116), (1170, 90),
            (1235, 124), (1300, 100), (1365, 114), (1425, 92), (1490, 120), (1555, 98), (1610, 110)]
    for x, h in back:
        out.append(fir(x, 160, h, h * 0.28, '#D3EDD8', '#C5E5CC', tiers=3))
    out.append(R(0, 156, 1600, 44, '#C8E8CD'))
    front = [(0, 118), (80, 96), (170, 132), (250, 104), (340, 126), (430, 98), (1180, 124), (1270, 100), (1350, 134), (1440, 104),
             (1520, 124), (1600, 100), (560, 86), (1060, 90)]
    for x, h in front:
        out.append(fir(x, 186, h, h * 0.29, '#B9E2C2', '#A8D9B4', tiers=3, trunk='#CDBCA2'))
    return out + [R(0, 184, 1600, 16, '#B9E2C2')]


def shapes_ground():
    out = [wavy_top(30, 5, 90, 2400, 100, GRASS), P('M0 86 Q1200 74 2400 86 V100 H0 Z', GRASS_SHADE)]
    for x in (160, 600, 980, 1460, 1820, 2240):
        out.append(tufts(x, 62, GRASS_SHADE, 1.2))
    for x, y in ((420, 66), (1640, 70), (2060, 60)):
        out.append(flower(x, y, petal='#FFFFFF'))
    for x in (760, 2120):                        # a toadstool, now and then
        out += [R(x - 3, 52, 7, 14, '#FFF3E6', rx=2.5), P('M%s 54 Q%s 36 %s 54 Z' % (f(x - 12), f(x), f(x + 12)), '#E9796A'), C(x - 3, 47, 2, WHITE)]
    return out


def shapes_corner():
    # back: a slim fir at the start edge; middle: a clipped sphere bush; front: a limestone cube and a log
    out = [fir(204, 186, 166, 32, '#4CB673', '#2E8A55', tiers=4, trunk=WOOD),
           shadow(140, 188, 44, 6), C(140, 150, 38, '#2E8A55'), C(136, 146, 35, '#4CB673'),
           P('M171 140 A35 35 0 0 1 110 170 Q150 178 168 160 Z', '#2E8A55', opacity=0.55),
           E(122, 130, 10, 6, WHITE, opacity=0.35, transform='rotate(-30 122 130)')]
    cx, cy, a = 56, 160, 26                      # the cube: top, lit side, shaded side
    out += [shadow(56, 192, 36, 5),
            P(poly((cx - a, cy - a * 0.55), (cx, cy - a * 1.1), (cx + a, cy - a * 0.55), (cx, cy)), '#F4ECDB'),
            P(poly((cx - a, cy - a * 0.55), (cx, cy), (cx, cy + a * 1.15), (cx - a, cy + a * 0.6)), '#DCCDAE'),
            P(poly((cx, cy), (cx + a, cy - a * 0.55), (cx + a, cy + a * 0.6), (cx, cy + a * 1.15)), '#C2AE88')]
    out += [R(88, 176, 56, 20, '#C08A5E', rx=10), E(144, 186, 8, 10, '#E7C9A0'), E(144, 186, 4.5, 6, 'none', stroke='#C08A5E', stroke_width=1.6),
            tufts(8, 196, GRASS_SHADE, 1.2), tufts(166, 197, GRASS_SHADE)]
    return out


TREE_MAIN = dict(cx=96, base=178, h=160, half=36)


def shapes_landmark():
    t = TREE_MAIN
    return [shadow(100, 188, 80, 6), E(100, 186, 86, 9, GRASS),
            fir(t['cx'], t['base'] + 4, t['h'], t['half'], '#3DB574', '#24834F', tiers=4, trunk='#A0643A'),
            C(152, 176, 11, '#4CB673'), C(150, 174, 9, '#6CCB93'), tufts(40, 190, GRASS_SHADE, 1.2), tufts(176, 190, GRASS_SHADE)]


def shapes_piece():
    return [glow(166, 120, 40), fir(166, 186, 112, 26, '#3DB574', '#24834F', tiers=3, trunk='#A0643A'), spark(166, 62, 8), spark(190, 96, 4.5)]


def shapes_reacted():
    return [fir(34, 188, 64, 17, '#5BC487', '#2E9A5E', tiers=2, trunk='#A0643A'), spark(34, 114, 5), spark(56, 132, 3.6)]


# ================================================================ Riddle Grotto (logic)
def logic_top():
    rock, deep, dark = '#D9CFEE', '#C2B4E2', '#AE9ED6'
    out = [P('M0 0 H2400 V22 ' + ''.join('Q%s %s %s %s ' % (f(2400 - 50 - i * 100), f(34 if i % 3 else 26), f(2400 - 100 - i * 100), f(22))
                                          for i in range(24)) + 'H0 Z', rock),
           P('M0 0 H2400 V9 H0 Z', deep)]
    xs = [(60, 34, 13), (140, 62, 18), (230, 24, 10), (300, 48, 15), (380, 78, 20), (470, 30, 11), (540, 56, 16), (630, 22, 9),
          (700, 44, 14), (790, 70, 19), (880, 28, 10), (950, 50, 15), (1040, 24, 9), (1110, 64, 18), (1200, 36, 12), (1290, 74, 20),
          (1380, 26, 10), (1450, 52, 16), (1540, 30, 11), (1620, 68, 19), (1710, 26, 10), (1790, 46, 14), (1880, 76, 20),
          (1970, 28, 10), (2050, 54, 16), (2140, 24, 9), (2220, 66, 18), (2310, 32, 12), (2380, 48, 15)]
    for x, l, w in xs:
        out += [P('M%s 20 Q%s %s %s %s Q%s %s %s 20 Z' % (f(x - w), f(x - w * 0.35), f(20 + l * 0.65), f(x), f(20 + l),
                                                        f(x + w * 0.35), f(20 + l * 0.65), f(x + w)), rock),
                P('M%s 20 Q%s %s %s %s Q%s %s %s 20 Z' % (f(x + w * 0.05), f(x + w * 0.15), f(20 + l * 0.6), f(x), f(20 + l),
                                                        f(x + w * 0.35), f(20 + l * 0.65), f(x + w)), dark, opacity=0.6),
                C(x, 20 + l - 1.5, 2.6, '#EFEAF8')]
    for x in (520, 1180, 1840):                  # glowing crystals hanging from the ceiling
        out += [glow(x, 50, 30, GOLD_TINT, 3, 0.4),
                P(poly((x - 10, 18), (x - 8, 44), (x, 62), (x + 8, 44), (x + 10, 18)), '#B9A2F7'),
                P(poly((x, 62), (x + 8, 44), (x + 10, 18), (x + 2, 18)), '#8A5CF0', opacity=0.6), spark(x - 4, 38, 4, WHITE)]
    return out


def logic_far():
    wall, wall2 = '#E7E0F5', '#DDD4EF'
    out = [P('M0 70 Q200 40 420 64 Q640 30 860 58 Q1080 36 1300 62 Q1460 44 1600 60 V200 H0 Z', wall)]
    # an arch open onto a pale sea (the map's chalk sea-cave), at the start side of the centre
    out += [P('M960 200 V120 A56 56 0 0 1 1072 120 V200 Z', '#D9EEF5'),
            R(960, 168, 112, 32, '#C6E6EF'), P('M980 182 q12 -6 24 0 q12 6 24 0 q12 -6 24 0', stroke=WHITE, stroke_width=3, stroke_linecap='round'),
            P('M948 200 V120 A68 68 0 0 1 1084 120 V200 H1072 V120 A56 56 0 0 0 960 120 V200 Z', wall2)]
    for x in (300, 1360):                        # columns where a stalactite met a stalagmite
        out += [P('M%s 60 Q%s 130 %s 200 H%s Q%s 130 %s 60 Z' % (f(x - 22), f(x - 6), f(x - 26), f(x + 26), f(x + 6), f(x + 22)), wall2)]
    for x, h in ((140, 40), (520, 30), (640, 56), (820, 34), (1200, 44), (1480, 36), (1560, 58)):
        out.append(P('M%s 200 Q%s %s %s %s Q%s %s %s 200 Z' % (f(x - h * 0.36), f(x - 4), f(200 - h * 0.8), f(x), f(200 - h),
                                                              f(x + 4), f(200 - h * 0.8), f(x + h * 0.36)), wall2))
    return out


def logic_ground():
    out = [wavy_top(30, 4, 160, 2400, 100, SAND), P('M0 86 Q1200 78 2400 88 V100 H0 Z', SAND_SHADE)]
    for x, y, r in ((200, 70, 9), (520, 80, 7), (1620, 74, 8), (1990, 82, 10), (2280, 68, 7)):
        out += [E(x, y, r * 1.4, r, ROCK_SHADE), E(x - 1, y - 2, r * 1.15, r * 0.7, ROCK)]
    for i, x in enumerate(range(880, 1560, 76)):     # shells in a pattern: pink, gold, pink, gold
        col, dark = ('#F4A7B4', '#D9788A') if i % 2 == 0 else (GOLD, '#D9A21F')
        out += [P('M%s 66 A10 10 0 0 1 %s 66 Z' % (f(x - 10), f(x + 10)), col),
                P('M%s 66 v-8 M%s 66 l-6 -6 M%s 66 l6 -6' % (f(x), f(x), f(x)), stroke=dark, stroke_width=1.6, stroke_linecap='round')]
    return out


def crystal(x, base, h, w, col, deep, tilt=0):
    pts = [(x - w, base), (x - w, base - h * 0.72), (x, base - h), (x + w, base - h * 0.72), (x + w, base)]
    return G([P(poly(*pts), col), P(poly((x, base - h), (x + w, base - h * 0.72), (x + w, base), (x + w * 0.15, base)), deep),
              P('M%s %s L%s %s' % (f(x - w * 0.5), f(base - h * 0.7), f(x - w * 0.5), f(base - h * 0.2)), stroke=WHITE, stroke_width=2,
                stroke_linecap='round', opacity=0.6)], 'rotate(%s %s %s)' % (f(tilt), f(x), f(base)))


def logic_corner():
    return [P('M240 0 V200 H168 Q196 160 186 118 Q176 72 204 36 Q216 18 214 0 Z', ROCK_SHADE),
            P('M240 0 V200 H190 Q210 156 202 116 Q194 76 220 40 Q232 20 232 0 Z', ROCK),
            glow(96, 162, 64), shadow(96, 194, 64, 6),
            E(96, 186, 58, 14, ROCK_SHADE), E(94, 182, 52, 11, ROCK),
            crystal(60, 184, 56, 11, '#D6C6FA', '#B9A2F7', -16), crystal(132, 184, 64, 12, '#D6C6FA', '#B9A2F7', 14),
            crystal(96, 182, 96, 16, '#B9A2F7', '#8A5CF0'), crystal(118, 186, 44, 9, '#8A5CF0', '#6B3FD1', 8),
            spark(80, 96, 5, WHITE), spark(150, 120, 4, GOLD)]


DOOR = dict(x0=56, x1=144, top=36, base=186, slots=(62, 90, 118, 146), slot=22)


def _shape(kind, cx, cy, s, col):
    if kind == 'circle':
        return C(cx, cy, s * 0.42, col)
    if kind == 'square':
        return R(cx - s * 0.36, cy - s * 0.36, s * 0.72, s * 0.72, col, rx=2)
    return P(poly((cx - s * 0.42, cy + s * 0.34), (cx, cy - s * 0.4), (cx + s * 0.42, cy + s * 0.34)), col)


DOOR_SHAPES = (('circle', '#F46A5E'), ('square', '#F59E1B'), ('triangle', '#34A86A'))


def logic_landmark():
    d = DOOR
    cx = (d['x0'] + d['x1']) / 2
    r = (d['x1'] - d['x0']) / 2
    out = [shadow(100, 190, 84, 6),
           # the chalk arch around the door, with a keystone
           P('M%s %s V%s A%s %s 0 0 1 %s %s V%s Z' % (f(d['x0'] - 22), f(d['base']), f(d['top'] + r), f(r + 22), f(r + 22), f(d['x1'] + 22),
                                                    f(d['top'] + r), f(d['base'])), '#EFE2C4'),
           P('M%s %s V%s A%s %s 0 0 0 %s %s L%s %s V%s Z' % (f(d['x1'] + 22), f(d['base']), f(d['top'] + r), f(r + 22), f(r + 22),
                                                           f(cx + 18), f(d['top'] - 20), f(cx + 12), f(d['top'] - 6), f(d['base'])), '#D9C59C', opacity=0.55),
           P(poly((cx - 10, d['top'] - 24), (cx + 10, d['top'] - 24), (cx + 7, d['top'] - 4), (cx - 7, d['top'] - 4)), '#F8F0DD'),
           # the door
           P('M%s %s V%s A%s %s 0 0 1 %s %s V%s Z' % (f(d['x0']), f(d['base']), f(d['top'] + r), f(r), f(r), f(d['x1']), f(d['top'] + r), f(d['base'])), '#9B74F2'),
           P('M%s %s V%s A%s %s 0 0 0 %s %s V%s Z' % (f(d['x1']), f(d['base']), f(d['top'] + r), f(r), f(r), f(cx + 4), f(d['top'])
                                                    , f(d['base'])), '#7E52E0', opacity=0.55),
           P('M%s %s V%s M%s %s V%s' % (f(d['x0'] + 18), f(d['top'] + 22), f(d['base']), f(d['x1'] - 18), f(d['top'] + 22), f(d['base'])),
             stroke='#7E52E0', stroke_width=2.2, opacity=0.7),
           C(d['x1'] - 12, 134, 4.5, GOLD), C(d['x1'] - 13, 133, 1.6, WHITE, opacity=0.7)]
    for i, y in enumerate(d['slots']):           # four slots top to bottom: circle, square, triangle, and the empty fourth
        out.append(R(cx - d['slot'] / 2 - 3, y - d['slot'] / 2 - 3, d['slot'] + 6, d['slot'] + 6, '#F7F3FF', rx=6))
        if i < 3:
            out.append(_shape(DOOR_SHAPES[i][0], cx, y, d['slot'], DOOR_SHAPES[i][1]))
        else:
            out.append(R(cx - d['slot'] / 2, y - d['slot'] / 2, d['slot'], d['slot'], 'none', rx=4, stroke='#B9A2F7', stroke_width=2,
                         stroke_dasharray='4 3'))
    out += [E(d['x0'] - 16, 186, 12, 7, ROCK_SHADE), E(d['x0'] - 17, 184, 10, 5.5, ROCK),
            crystal(d['x1'] + 26, 188, 26, 6, '#B9A2F7', '#8A5CF0', 10)]
    return out


def logic_piece():
    d = DOOR
    cx = (d['x0'] + d['x1']) / 2
    y = d['slots'][3]
    return [glow(cx, y, 26), R(cx - d['slot'] / 2 - 3, y - d['slot'] / 2 - 3, d['slot'] + 6, d['slot'] + 6, GOLD_TINT, rx=6,
                               stroke=GOLD, stroke_width=2.5),
            _shape('circle', cx, y, d['slot'], '#F46A5E'), spark(cx + 20, y - 14, 5)]


def logic_reacted():
    d = DOOR
    cx = (d['x0'] + d['x1']) / 2
    r = (d['x1'] - d['x0']) / 2
    out = [glow(cx, 110, 92, GOLD_TINT, 4, 0.3),
           P('M%s %s V%s A%s %s 0 0 1 %s %s V%s' % (f(d['x0'] - 2), f(d['base']), f(d['top'] + r), f(r + 2), f(r + 2), f(d['x1'] + 2),
                                                  f(d['top'] + r), f(d['base'])), stroke=GOLD, stroke_width=5, opacity=0.9)]
    for i in range(3):
        y = d['slots'][i]
        out += [R(cx - d['slot'] / 2 - 4, y - d['slot'] / 2 - 4, d['slot'] + 8, d['slot'] + 8, GOLD_TINT, rx=7, stroke=GOLD, stroke_width=3),
                _shape(DOOR_SHAPES[i][0], cx, y, d['slot'], DOOR_SHAPES[i][1])]
    return out + [spark(d['x1'] + 10, d['top'] + 6, 6), spark(d['x0'] - 10, d['top'] + 30, 4.5)]


# ================================================================ Robot Harbour (cs)
def cs_top():
    return [cloud(700, 30, 0.8), cloud(1690, 24, 0.95), gull(1040, 30, '#5FB3C2'), gull(1074, 42, '#5FB3C2', 0.8)]


def cs_far():
    out = [P('M0 92 Q90 58 200 70 Q300 80 360 92 Z', '#CFE6DA'), P('M1300 92 Q1380 70 1470 74 Q1540 78 1600 88 V92 Z', '#D3E8DD'),
           R(0, 92, 1600, 108, SEA1), R(0, 92, 1600, 10, '#C2ECEC')]
    # a distant container ship
    out.append(G([P('M-70 0 H74 L62 18 H-60 Z', '#A9C8EC'), R(-58, -14, 22, 14, '#F0C1B6'), R(-34, -14, 22, 14, '#B7E0DB'),
                  R(-10, -14, 22, 14, '#F5DDA6'), R(14, -14, 22, 14, '#B7E0DB'), R(40, -30, 18, 30, '#E4EEF8'), R(44, -26, 10, 5, '#A9C8EC')],
                 'translate(610 96)'))
    # a lighthouse on its breakwater
    out.append(G([P('M-70 0 Q-30 -12 0 -10 Q40 -14 80 0 Z', '#CFCADD'), P('M-9 -10 L-7 -78 H7 L9 -10 Z', '#FFFFFF'),
                  P('M0 -78 H7 L9 -10 H2 Z', '#EEF0F7'),
                  R(-8.2, -40, 16.4, 10, '#F4AEA2'), R(-7.4, -64, 14.8, 9, '#F4AEA2'), R(-9, -90, 18, 12, '#FFF0C2'),
                  R(-11, -79, 22, 3, '#B9C2D6'), P('M-11 -90 Q0 -106 11 -90 Z', '#F4AEA2')], 'translate(1110 100)'))
    # a small boat moored near the quay
    out.append(G([P('M-34 0 H34 L26 14 H-26 Z', '#E8705A'), R(-34, 0, 68, 4, WHITE), R(-12, -16, 24, 16, WHITE, rx=2),
                  R(-8, -12, 7, 6, '#BFE3F5'), R(3, -12, 7, 6, '#BFE3F5'), R(-2, -30, 4, 14, '#3B3F6B')], 'translate(860 118)'))
    for x, y in ((150, 120), (380, 140), (700, 150), (960, 118), (1240, 140), (1420, 124)):
        out.append(P('M%s %s q10 -6 20 0 q10 6 20 0' % (f(x), f(y)), stroke=WHITE, stroke_width=3.2, stroke_linecap='round', opacity=0.85))
    return out


def cs_ground():
    out = [R(0, 20, 2400, 6, WOOD), R(0, 26, 2400, 42, WOOD_LIGHT),
           P(''.join('M%s 26 V68 ' % f(x) for x in range(60, 2400, 120)), stroke=WOOD, stroke_width=2.4),
           P('M0 46 H2400', stroke=WOOD, stroke_width=1.6, opacity=0.6),
           R(0, 68, 2400, 32, '#A26C46'), R(0, 68, 2400, 4, WOOD_DARK)]
    for x in range(200, 2400, 400):              # tyre fenders on the quay's face
        out += [E(x, 84, 13, 11, '#3B3A5A'), E(x, 84, 6, 4.5, '#A26C46'), P('M%s 70 V74' % f(x), stroke='#3B3A5A', stroke_width=3)]
    for i, x in enumerate((540, 1060, 1580, 2100)):
        out.append(bollard(x, 44, 1.2))
        if i == 1:                               # one bollard has its rope
            out.append(P('M%s 26 Q%s 34 %s 44 Q%s 54 %s 60' % (f(x - 10), f(x - 4), f(x + 40), f(x + 70), f(x + 120)),
                         stroke='#E8D3A8', stroke_width=4, stroke_linecap='round'))
    return out


def cs_corner():
    # containers stacked in a grid (the programmer's blocks), and a bollard with a coil of rope
    out = [shadow(156, 196, 84, 6)]

    def box_(x, y, w, h, c, cd):
        lines = ''.join('M%s %s v%s ' % (f(x + w * k / 7), f(y + 5), f(h - 10)) for k in range(1, 7))
        return [R(x, y, w, h, c, rx=3), P(lines, stroke=cd, stroke_width=2, opacity=0.5), R(x, y + h - 5, w, 5, INK, opacity=0.18),
                R(x + w * 0.6, y, w * 0.4, h, INK, opacity=0.06)]
    out += box_(74, 150, 82, 44, '#E8705A', '#B9493A') + box_(158, 150, 82, 44, '#2BA39B', '#1D7A73')
    out += box_(116, 104, 82, 44, '#F2B33D', '#C98A1A') + box_(176, 58, 64, 44, '#5B8DEF', '#3A68C4')
    out += [bollard(40, 196, 1.6), E(40, 166, 14, 5, 'none', stroke='#E8D3A8', stroke_width=4),
            E(40, 170, 15, 5.5, 'none', stroke='#D9BF8C', stroke_width=4)]
    return out


CRANE = dict(legL=(26, 38), legR=(150, 162), beam=40, trolleyX=92, hookY=118, base=186)


def cs_landmark():
    """A gantry crane on the quay (the map's crane): two braced legs on wheels, the top beam, the cab, the trolley, cable and hook."""
    c = CRANE
    blue, deep = '#2F7FE0', '#1F63C7'
    (a0, a1), (b0, b1) = c['legL'], c['legR']
    top, base = c['beam'], c['base']
    out = [shadow(96, 190, 90, 6)]
    for x0, x1 in (c['legL'], c['legR']):
        out += [R(x0, top + 8, x1 - x0, base - top - 16, blue), R((x0 + x1) / 2, top + 8, (x1 - x0) / 2, base - top - 16, deep),
                R(x0 - 8, base - 12, x1 - x0 + 16, 7, deep, rx=2),
                C(x0 - 2, base - 3, 5, '#3B3F6B'), C(x1 + 2, base - 3, 5, '#3B3F6B'), C(x0 - 2, base - 3, 2, '#9AA3C7'), C(x1 + 2, base - 3, 2, '#9AA3C7')]
    # cross bracing between the legs (high up, under the beam) and a lower tie
    out += [P('M%s %s L%s %s M%s %s L%s %s' % (f(a1), f(top + 14), f(b0), f(top + 46), f(a1), f(top + 46), f(b0), f(top + 14)),
              stroke=blue, stroke_width=3.5),
            R(a1, top + 44, b0 - a1, 5, blue)]
    # the top beam, reaching past both legs, with its lattice
    out += [R(8, top - 6, 184, 14, blue, rx=3), R(8, top + 4, 184, 4, deep),
            P(''.join('M%s %s L%s %s ' % (f(x), f(top - 4), f(x + 10), f(top + 4)) for x in range(14, 186, 14)), stroke=WHITE,
              stroke_width=1.6, opacity=0.45),
            # the cab under the beam, start side
            R(118, top + 8, 30, 22, blue, rx=3), R(133, top + 8, 15, 22, deep, rx=3), R(122, top + 12, 12, 10, '#DEEBFC', rx=2),
            R(123, top + 13, 4, 8, WHITE, opacity=0.7),
            # the trolley, the cable and the hook
            R(c['trolleyX'] - 11, top + 8, 22, 9, INK, rx=2), C(c['trolleyX'] - 6, top + 8, 2.5, '#9AA3C7'), C(c['trolleyX'] + 6, top + 8, 2.5, '#9AA3C7'),
            P('M%s %s V%s' % (f(c['trolleyX']), f(top + 17), f(c['hookY'])), stroke=INK, stroke_width=2.2),
            R(c['trolleyX'] - 7, c['hookY'] - 2, 14, 7, GOLD, rx=2),
            P('M%s %s v8 a5 5 0 1 1 -8 3' % (f(c['trolleyX']), f(c['hookY'] + 5)), stroke=INK, stroke_width=3, stroke_linecap='round')]
    return out


def big_crate(x, y, w, h, body, frame, lit):
    """A big slatted crate for the harbour's reaction and piece: a thick frame, three planks, a diagonal brace, lit on the left,
    edged in its frame colour so it reads at the phone's 56 pt landmark (Bing image search "crane hook lifting wooden crate slings")."""
    t = w * 0.085
    planks = ''.join('M%s %s H%s ' % (f(x + t), f(y + h * k / 3), f(x + w - t)) for k in (1, 2))
    return ''.join([R(x - 2, y - 2, w + 4, h + 4, frame, rx=5), R(x, y, w, h, body, rx=3),
                    P(planks, stroke=frame, stroke_width=2.6, opacity=0.55),
                    P('M%s %s L%s %s' % (f(x + t), f(y + h - t), f(x + w - t), f(y + t)), stroke=frame, stroke_width=t * 0.95),
                    R(x, y, w, t, frame), R(x, y + h - t, w, t, frame), R(x, y, t, h, frame), R(x + w - t, y, t, h, frame),
                    R(x + t, y + t, w * 0.16, h - 2 * t, lit, opacity=0.55),
                    R(x + w * 0.6, y, w * 0.4, h, INK, opacity=0.07)])


def _hook(x, y):
    """The crane's hook block and hook at (x, y) (the block's top)."""
    return ''.join([R(x - 8, y, 16, 8, GOLD, rx=2), R(x - 8, y + 6, 16, 2, GOLD_DEEP),
                    P('M%s %s v7 a6 6 0 1 1 -10 4' % (f(x), f(y + 8)), stroke=INK, stroke_width=3.4, stroke_linecap='round')])


def cs_piece():
    """The celebration's piece: a gold crate set on the quay under the hook, glowing."""
    c = CRANE
    x0, x1, top, base = 52, 132, 120, 178
    return [glow(92, 150, 54), shadow(92, 180, 48, 4),
            P('M%s %s V%s' % (f(c['trolleyX']), f(c['beam'] + 17), f(top - 22)), stroke=INK, stroke_width=2.2),
            _hook(c['trolleyX'], top - 22),
            big_crate(x0, top, x1 - x0, base - top, GOLD, GOLD_DEEP, '#FFF1C4'),
            spark(92, 149, 9, WHITE), spark(x1 + 12, top - 6, 7), spark(x0 - 12, top + 6, 5)]


def cs_reacted():
    """The reaction's end state: a big orange crate set down on the quay between the legs, its four slings up to the lowered hook
    (photographs of crane lifts: the slings meet at the hook in a pyramid). It is about half the landmark's width."""
    c = CRANE
    x = c['trolleyX']
    x0, x1, top, base = 44, 144, 112, 178
    hook = top - 30
    return [glow(94, 140, 60, GOLD_TINT, 4, 0.3), shadow(94, 180, 56, 4),
            P('M%s %s V%s' % (f(x), f(c['beam'] + 17), f(hook)), stroke=INK, stroke_width=2.2),
            # the back slings (behind the crate's top), then the crate, then the front slings
            P('M%s %s L%s %s M%s %s L%s %s' % (f(x - 2), f(hook + 14), f(x0 + 18), f(top + 2), f(x + 2), f(hook + 14), f(x1 - 18),
                                                 f(top + 2)), stroke='#E0762A', stroke_width=2.6),
            big_crate(x0, top, x1 - x0, base - top, '#FFB35C', '#E0762A', '#FFE0B8'),
            P('M%s %s L%s %s M%s %s L%s %s' % (f(x - 3), f(hook + 14), f(x0 + 4), f(top + 3), f(x + 3), f(hook + 14), f(x1 - 4),
                                                 f(top + 3)), stroke=INK, stroke_width=3, stroke_linecap='round'),
            _hook(x, hook),
            spark(x1 + 14, top - 10, 9), spark(x0 - 10, top - 4, 6.5), spark(x + 26, top - 30, 5, WHITE)]


# ================================================================ Market Village (math)
# 2026-11-15 (QA of Stage 1: "pale and empty next to the new Colour Bay"): a busy covered market at the edges, a calm wall in the
# middle. Strong colour only where activity content never sits: the awning and its garland at the top (above 16% of the stage),
# the stalls' produce at the foot of the arcade and the crates on the paving (below 80%), the corner and the landmark. Between
# 15% and 80% every colour is light (relative luminance 0.44 or more, so ink #2B2350 keeps 7:1 on it): the honey wall, the arches'
# shade and the stalls' pastel awnings. References: the Mahane Yehuda photographs (see the docstring; looked at again on
# 2026-11-15): produce heaped in sloping one-colour blocks at the front of each stall, striped and plain awnings, stacked crates,
# brass lamps under the arched roof.
MARKET_FRUIT = (('#E5484D', '#B8323A', '#F6AEB0'), ('#FF9F43', '#D9762A', '#FFD6AE'), ('#6FBF4A', '#4E9A33', '#B8E39A'),
                ('#FFD84D', '#E0A21A', '#FFF1B8'), ('#8B5BB0', '#5C3480', '#C7A8E0'))
MARKET_AWNINGS = ('#FFA894', '#7FD6CB', '#FFD054', '#A9DC7E', '#C4AEF5', '#FFB774')
PENNANTS = ('#F46A5E', '#FFC83D', '#2BA39B', '#8FD45C', '#9B6BE0', '#3E9BEA')


def math_top():
    # the roof's light steel trusses, seen under the front awning (pale: they reach 22% of the stage)
    out = [R(0, 60, 2400, 4, '#CBD3E3')]
    for x in range(0, 2400, 120):
        out += [P('M%s 62 L%s 100 M%s 62 L%s 100' % (f(x), f(x + 60), f(x + 120), f(x + 60)), stroke='#CBD3E3', stroke_width=3),
                R(x + 58, 62, 4, 38, '#C2CBDD')]
    sw = 80
    for i in range(30):
        x = i * sw
        orange = i % 2 == 0
        c = '#F59E1B' if orange else '#FFFFFF'
        cd = '#E08A0E' if orange else '#EFE3D1'
        out += [R(x, 0, sw, 50, c), R(x + sw * 0.66, 0, sw * 0.34, 50, cd),
                P('M%s 50 a%s 20 0 0 0 %s 0 Z' % (f(x), f(sw / 2), f(sw)), c),
                P('M%s 50 a%s 20 0 0 1 %s 0' % (f(x), f(sw / 2), f(sw)), 'none')]
        out.append(P('M%s 50 a%s 20 0 0 0 %s 0' % (f(x), f(sw / 2), f(sw)), stroke='#C9760A', stroke_width=2, opacity=0.35))
    out += [R(0, 0, 2400, 10, '#C9760A', opacity=0.55), R(0, 47, 2400, 4, '#C9760A', opacity=0.25)]
    # a garland of pennants under the awning, sagging between hooks 400 apart (a festive line, not a row to count: it runs on
    # past every edge of the stage)
    for h0 in range(0, 2400, 400):
        d = 'M%s 47 Q%s 59 %s 47' % (f(h0), f(h0 + 200), f(h0 + 400))
        out.append(P(d, stroke='#B07A52', stroke_width=2, opacity=0.8))
        for k in range(11):
            t = (k + 0.5) / 11
            x = h0 + 400 * t
            y = 47 + 2 * t * (1 - t) * 12
            c = PENNANTS[(h0 // 400 * 11 + k) % len(PENNANTS)]
            out.append(P(poly((x - 10, y), (x + 10, y), (x, y + 13)), c))
            out.append(P(poly((x + 2, y), (x + 10, y), (x, y + 13)), INK, opacity=0.1))
    return out


def stall_heap(x, base, w, h, col, deep, hi):
    """One sloping block of one fruit at the front of a stall: a mound with a few round bumps on its top and a shade."""
    d = 'M%s %s L%s %s Q%s %s %s %s Z' % (f(x), f(base), f(x + w * 0.08), f(base - h * 0.7), f(x + w * 0.5), f(base - h * 1.25),
                                          f(x + w), f(base - h * 0.45))
    bumps = ''.join(C(x + w * fx, base - h * fy, w * 0.11, col) for fx, fy in ((0.2, 0.82), (0.4, 0.95), (0.6, 0.88), (0.8, 0.66)))
    return ''.join([P(d + ' V%s Z' % f(base), col), bumps, P('M%s %s Q%s %s %s %s V%s Z' % (f(x + w * 0.62), f(base), f(x + w * 0.9),
                    f(base - h * 0.62), f(x + w), f(base - h * 0.45), f(base)), deep, opacity=0.4),
                    C(x + w * 0.3, base - h * 0.88, w * 0.04, hi), C(x + w * 0.55, base - h * 0.98, w * 0.035, hi)])


def math_far():
    """The covered market across the aisle: its high vaulted roof with a skylight (pale, 34% to 54% of the stage), then the
    arcade of honey limestone with a stall in every arch (the pastel awnings at about 66% to 72%), and the stalls' produce in
    full colour at the arcade's foot, below 80%."""
    roof, rib, pane, wall, course, arch, inner = '#E6EAF3', '#D2D9E8', '#F6F9FD', '#F8DDB4', '#EFCD9C', '#ECCFA0', '#E3C38F'
    out = [R(0, 0, 1600, 60, roof)]
    for x in range(0, 1600, 100):                    # the vault's ribs and, between them, the skylight's panes
        out += [R(x + 14, 8, 72, 22, pane, rx=3), R(x + 14, 8, 72, 4, WHITE, rx=2, opacity=0.8),
                R(x - 3, 0, 6, 60, rib), P('M%s 60 Q%s 40 %s 60' % (f(x + 3), f(x + 50), f(x + 97)), stroke=rib, stroke_width=4)]
    out += [R(0, 0, 1600, 4, rib), R(0, 54, 1600, 8, '#EFD8AE'), R(0, 60, 1600, 140, wall), R(0, 60, 1600, 4, '#E2C38E')]
    for y in (78, 96):                               # the limestone's courses, broken by the arches
        out.append(R(0, y, 1600, 1.6, course, opacity=0.8))
    for n, x in enumerate(range(40, 1600, 200)):     # the arcade: in every arch a stall of its own
        aw = MARKET_AWNINGS[n % len(MARKET_AWNINGS)]
        out += [P('M%s 200 V104 A60 60 0 0 1 %s 104 V200 Z' % (f(x), f(x + 120)), arch),
                P('M%s 200 V110 A52 52 0 0 1 %s 110 V200 Z' % (f(x + 8), f(x + 112)), inner),
                P('M%s 104 A66 66 0 0 1 %s 104' % (f(x - 6), f(x + 126)), stroke='#FCEBD0', stroke_width=8),
                R(x + 12, 104, 96, 18, WHITE)]
        for i in range(4):
            out.append(R(x + 12 + i * 24, 104, 12, 18, aw))
        out += [P('M%s 122 ' % f(x + 12) + ''.join('a6 6 0 0 0 12 0 ' for _ in range(8)) + 'Z', aw),
                R(x + 12, 101, 96, 4, '#E2C79C'), R(x + 14, 128, 3, 30, '#DDBB86'), R(x + 103, 128, 3, 30, '#DDBB86')]
        # the counter and its produce in sloping one-colour blocks (below 80% of the stage: full colour)
        out.append(R(x + 14, 154, 92, 46, '#C99A6B'))
        for k in range(3):
            c, cd, hi = MARKET_FRUIT[(n * 2 + k) % len(MARKET_FRUIT)]
            out.append(stall_heap(x + 16 + k * 30, 156, 28, 13, c, cd, hi))
    for x in (230, 630, 1030, 1430):                 # brass lamps hanging from the cornice between the arches, a warm glow round each
        out += [P('M%s 62 V78' % f(x), stroke='#D6B98C', stroke_width=2), C(x, 88, 13, GOLD_TINT, opacity=0.6),
                P('M%s 78 h18 l-4 12 h-10 Z' % f(x - 9), '#F2CB72'), R(x - 3, 90, 6, 3, '#FFE7A0')]
    return out


def math_ground():
    out = [R(0, 22, 2400, 78, '#EBD3A6')]
    for row, (y, h, off) in enumerate(((26, 30, 0), (60, 38, 50))):
        for x in range(-100 + off, 2400, 100):
            out.append(R(x + 3, y, 94, h - 4, '#F5E3C2', rx=8))
            out.append(R(x + 3, y + h - 9, 94, 5, '#E8CFA1', rx=2.5, opacity=0.7))
    out.append(R(0, 22, 2400, 4, '#DDBE8A'))
    # crates of produce standing on the paving, out at both sides (never under the middle of the stage)
    for x0, fruits in ((700, (0, 2)), (1560, (1, 4))):
        out.append(shadow(x0 + 80, 82, 92, 6))
        for k, i in enumerate(fruits):
            c, cd, hi = MARKET_FRUIT[i]
            x = x0 + k * 84
            out += [orange_heap(x + 4, 52, 74, 22, c, cd, hi), crate(x, 46, 82, 36)]
    # a lemon and an orange rolled away, and a leaf
    out += [C(1010, 86, 7, '#FFD84D'), C(1008, 84, 2, '#FFF1B8'), C(1392, 84, 8, '#FF9F43'), C(1389, 81, 2.2, '#FFD6AE'),
            P('M1200 90 q12 -10 24 -2 q-12 8 -24 2 Z', '#6FBF4A')]
    return out


def sack(x, base, w, h, heap, heap_deep):
    """A burlap sack with its top rolled down and a cone of spice heaped in it."""
    return ''.join([P('M%s %s Q%s %s %s %s H%s Q%s %s %s %s Z' % (f(x), f(base), f(x - 4), f(base - h * 0.6), f(x + 4), f(base - h),
                                                                 f(x + w - 4), f(x + w + 4), f(base - h * 0.6), f(x + w), f(base)), '#D9B98A'),
                    P('M%s %s Q%s %s %s %s V%s Z' % (f(x + w * 0.6), f(base), f(x + w + 4), f(base - h * 0.6), f(x + w - 4),
                                                     f(base - h), f(base)), '#B08A5E', opacity=0.45),
                    E(x + w / 2, base - h, w / 2 + 3, 6, '#C9A472'),
                    P(poly((x + 2, base - h), (x + w / 2, base - h - h * 0.55), (x + w - 2, base - h)), heap),
                    P(poly((x + w / 2, base - h - h * 0.55), (x + w - 2, base - h), (x + w * 0.62, base - h)), heap_deep, opacity=0.5)])


def math_corner():
    out = [shadow(124, 196, 112, 6)]
    # behind: three sacks of spices heaped in cones (paprika, turmeric, cinnamon)
    out += [sack(8, 156, 40, 40, '#E2533F', '#B23A2A'), sack(50, 152, 40, 44, '#F2B632', '#C98A10'),
            sack(196, 156, 38, 38, '#C46A3A', '#94461E')]
    # two crates of fruit and a woven basket of grapes on top
    out += [orange_heap(40, 156, 82, 30), crate(36, 150, 88, 46), orange_heap(130, 156, 80, 28, '#9CCB5B', '#76A93A', '#C3E39A'),
            crate(126, 150, 86, 46)]
    out += [P('M98 150 Q96 112 106 104 H182 Q192 112 190 150 Z', '#D7A27A'),
            P(''.join('M%s 106 L%s 148 ' % (f(x), f(x - 6)) for x in range(112, 188, 12)), stroke=WOOD, stroke_width=2, opacity=0.6),
            P('M100 124 H188 M99 138 H189', stroke=WOOD, stroke_width=2, opacity=0.6),
            orange_heap(106, 106, 76, 22, '#8B5BB0', '#5C3480', '#B58BD1'),
            P('M118 104 Q144 64 170 104', stroke=WOOD, stroke_width=4)]
    # in front: a watermelon on the ground, its stripes along its length
    out += [shadow(36, 198, 30, 4), E(36, 186, 30, 14, '#3E8E3A'),
            P('M10 184 Q36 176 62 184 M8 190 Q36 182 64 190', stroke='#8FD45C', stroke_width=3, opacity=0.8),
            E(28, 180, 9, 3.5, '#B8E39A', opacity=0.6)]
    return out


STALL = dict(jar=(124, 76, 40, 44), heapX=20, counter=120)


def math_landmark():
    s = STALL
    out = [shadow(100, 190, 94, 6),
           R(12, 34, 8, 154, WOOD), R(180, 34, 8, 154, WOOD), R(184, 34, 4, 154, WOOD_DARK, opacity=0.5)]
    # the striped awning: a sloping canopy of stripes, then a scalloped valance in the same stripes
    out.append(P(poly((10, 8), (190, 8), (196, 46), (4, 46)), '#FFFFFF'))
    n = 8
    for i in range(n):
        if i % 2:
            continue
        xt0, xt1 = 10 + 180 * i / n, 10 + 180 * (i + 1) / n
        xb0, xb1 = 4 + 192 * i / n, 4 + 192 * (i + 1) / n
        out += [P(poly((xt0, 8), (xt1, 8), (xb1, 46), (xb0, 46)), '#F59E1B'),
                P(poly((xt0 + (xt1 - xt0) * 0.66, 8), (xt1, 8), (xb1, 46), (xb0 + (xb1 - xb0) * 0.66, 46)), '#E08A0E')]
    sw = 192 / n
    for i in range(n):
        x = 4 + i * sw
        c = '#F59E1B' if i % 2 == 0 else '#FFFFFF'
        out += [R(x, 44, sw, 10, c), P('M%s 54 a%s 10 0 0 0 %s 0 Z' % (f(x), f(sw / 2), f(sw)), c)]
    out += [P('M4 54 ' + ''.join('a%s 10 0 0 0 %s 0 ' % (f(sw / 2), f(sw)) for _ in range(n)), stroke='#C9760A', stroke_width=1.8, opacity=0.5),
            P(poly((10, 8), (190, 8), (196, 46), (4, 46)), 'none', stroke='#C9760A', stroke_width=2, stroke_linejoin='round', opacity=0.45),
            R(4, 43, 192, 3, '#C9760A', opacity=0.4), R(8, 3, 184, 8, '#C9760A', rx=3)]
    # the counter, a heap of oranges on it, and the glass jar (empty until the coin drops in)
    out += [R(6, s['counter'], 188, 11, WOOD), R(10, s['counter'] + 11, 180, 57, WOOD_LIGHT),
            P(''.join('M%s %s V%s ' % (f(x), f(s['counter'] + 13), f(s['counter'] + 66)) for x in (55, 100, 145)), stroke=WOOD, stroke_width=2.6),
            R(100, s['counter'] + 11, 90, 57, INK, opacity=0.06),
            orange_heap(s['heapX'], s['counter'], 92, 40)]
    jx, jy, jw, jh = s['jar']
    out += [P('M%s %s h%s v%s q0 6 -6 6 h%s q-6 0 -6 -6 Z' % (f(jx), f(jy + 6), f(jw), f(jh - 12), f(-(jw - 12))), '#E6F2F6', opacity=0.92),
            P('M%s %s h%s v%s q0 6 -6 6 h%s q-6 0 -6 -6 Z' % (f(jx), f(jy + 6), f(jw), f(jh - 12), f(-(jw - 12))), 'none', stroke='#B5CBD6', stroke_width=1.6),
            R(jx - 3, jy, jw + 6, 9, '#9CB8C8', rx=3), R(jx + 5, jy + 13, 6, jh - 22, WHITE, opacity=0.85)]
    return out


def math_piece():
    s = STALL
    x, y = s['heapX'] + 46, s['counter'] - 50
    return [glow(x, y, 28), C(x, y, 14, '#FFA46B'), P('M%s %s A14 14 0 0 0 %s %s Z' % (f(x), f(y - 14), f(x), f(y + 14)), '#E37A1E', opacity=0.3),
            C(x - 5, y - 5, 3.6, '#FFC79E'), P('M%s %s q6 -8 14 -6 q-4 8 -14 6 Z' % (f(x), f(y - 13)), '#5BA35A'), spark(x + 24, y - 18, 6)]


def coin_flat(cx, cy, rx=9.0):
    """A gold coin lying flat: its edge, its face and a glint (no numeral: the app draws numerals, never a picture)."""
    ry = rx * 0.42
    return ''.join([E(cx, cy + ry * 0.45, rx, ry, '#C98A10'), E(cx, cy, rx, ry, GOLD, stroke='#C98A10', stroke_width=1.2),
                    E(cx - rx * 0.3, cy - ry * 0.25, rx * 0.32, ry * 0.32, '#FFE7A0')])


def math_reacted():
    """The coin drops in and the jar is full: gold to the brim and a heap of coins standing up out of its mouth, the lid pushed
    up and tipped on top, a gold burst behind (the jar's outline grows, so the change reads at the 56 to 64 point header slot,
    not only as a change of colour). The motion (stage_reaction.dart) drops its coin at (144, 108), inside this gold."""
    jx, jy, jw, jh = STALL['jar']
    cx = jx + jw / 2
    body = 'M%s %s h%s v%s q0 6 -6 6 h%s q-6 0 -6 -6 Z' % (f(jx), f(jy + 6), f(jw), f(jh - 12), f(-(jw - 12)))
    out = [glow(cx, jy + 18, 46), burst(cx, jy + 20, 30, 42, 12, rot=-75)]
    # the jar, full: the glass with gold inside it to the brim, coin edges stacked in it, the glass's sheen over the gold
    out += [P(body, '#E6F2F6'), P(body, GOLD), P(body, 'none', stroke='#C98A10', stroke_width=2)]
    for y in range(jy + 16, jy + jh - 2, 7):
        out.append(P('M%s %s q%s 4 %s 0' % (f(jx + 2), f(y), f((jw - 4) / 2), f(jw - 4)), stroke='#C98A10', stroke_width=1.6, opacity=0.8))
    out += [R(jx + 5, jy + 13, 6, jh - 22, WHITE, opacity=0.55)]
    # the heap standing out of the mouth (it covers the lid's place)
    out.append(P('M%s %s Q%s %s %s %s Q%s %s %s %s Z' % (f(jx - 4), f(jy + 10), f(jx + 2), f(jy - 5), f(cx), f(jy - 9),
                                                         f(jx + jw - 2), f(jy - 5), f(jx + jw + 4), f(jy + 10)), GOLD,
                 stroke='#C98A10', stroke_width=1.8, stroke_linejoin='round'))
    for (dx, dy, rx) in ((-12, 6, 9), (10, 7, 9), (-2, 2, 10), (-13, -1, 7.5), (12, 0, 8), (1, -5, 8.5)):
        out.append(coin_flat(cx + dx, jy + dy, rx))
    # the lid, pushed off: it leans on the jar's start side, standing on the counter
    out += [G([R(-22, -4.5, 44, 9, '#9CB8C8', rx=3), R(-22, -4.5, 44, 3, WHITE, rx=1.5, opacity=0.45)],
              'translate(%s %s) rotate(-72)' % (f(jx + jw + 7), f(STALL['counter'] - 21))),
            spark(jx + jw + 16, jy - 4, 7), spark(jx - 12, jy + 2, 5.5, WHITE)]
    return out


# ================================================================ the language rooms (eng, heb, rus)
WIN = dict(eng=('#2C6FB8', '#3E8EDE'), heb=('#D25E4E', '#F07F6E'), rus=('#6D49B3', '#8A63D2'))
GLASS_SKY, GLASS_LIT, SUN = '#DDF1FC', '#FFE7A0', GOLD
SILL_Y = 164


def _sill(col='#FFFFFF', shade='#C9D3E2'):
    return [R(26, SILL_Y + 15, 148, 5, shade, rx=2, opacity=0.7),
            P('M46 %s h14 v4 q0 8 -8 10 Z M154 %s h-14 v4 q0 8 8 10 Z' % (f(SILL_Y + 14), f(SILL_Y + 14)), shade),
            R(20, SILL_Y, 160, 15, shade, rx=4), R(20, SILL_Y, 160, 11, col, rx=4)]


def _glass(course):
    """The window's glass outline (the reaction lights exactly this shape)."""
    if course == 'eng':
        return C(100, 92, 52, '%s')
    if course == 'heb':
        return P('M58 %s V80 A42 42 0 0 1 142 80 V%s Z' % (f(SILL_Y - 4), f(SILL_Y - 4)), '%s')
    return R(46, 34, 108, SILL_Y - 38, '%s', rx=4)


def _bars(course, col):
    if course == 'eng':
        return P('M100 40 V144 M48 92 H152', stroke=col, stroke_width=8)
    if course == 'heb':
        return P('M100 38 V160 M58 104 H142', stroke=col, stroke_width=7)
    return P('M100 34 V160 M46 97 H154', stroke=col, stroke_width=8)


def window_landmark(course):
    frame, lit = WIN[course]
    out = []
    if course == 'eng':
        out += [C(100, 92, 68, frame), P('M47 49 A68 68 0 0 1 153 49 A60 60 0 0 0 47 49 Z', lit, opacity=0.8),
                C(100, 92, 52, GLASS_SKY)]
    elif course == 'heb':
        out += [P('M42 %s V80 A58 58 0 0 1 158 80 V%s Z' % (f(SILL_Y), f(SILL_Y)), frame),
                P('M42 80 A58 58 0 0 1 100 22 V30 A50 50 0 0 0 50 80 V%s H42 Z' % f(SILL_Y), lit, opacity=0.7),
                P('M58 %s V80 A42 42 0 0 1 142 80 V%s Z' % (f(SILL_Y - 4), f(SILL_Y - 4)), GLASS_SKY)]
    else:
        out += [R(32, 20, 136, SILL_Y - 16, frame, rx=10), R(32, 20, 136, 8, lit, rx=4, opacity=0.8), R(32, 20, 8, SILL_Y - 16, lit, rx=4, opacity=0.8),
                R(46, 34, 108, SILL_Y - 38, GLASS_SKY, rx=4)]
    # outside: a soft hill and a cloud (each window its own view)
    view = {'eng': [cloud(80, 70, 0.55), P('M52 128 Q100 104 150 124 A52 52 0 0 1 52 128 Z', '#BFE4C4')],
            'heb': [cloud(80, 64, 0.5), P('M58 150 Q80 118 104 126 Q124 110 142 132 V160 H58 Z', '#E9D6BC'),
                    P('M104 126 Q124 110 142 132 V160 H120 Q128 140 104 126 Z', '#DCC5A6')],
            'rus': [cloud(120, 62, 0.55), P('M46 140 Q100 116 154 134 V160 H46 Z', '#BFE4C4'), C(70, 132, 9, '#A8D8B2'), R(69, 132, 2, 12, '#C8B49A')]}[course]
    out += view
    out.append(_bars(course, frame))
    if course == 'eng':
        out.append(C(100, 92, 52, 'none', stroke=frame, stroke_width=3))
    return out + _sill()


def window_piece(course):
    if course == 'eng':                           # a daisy in a pot
        petals = [E(134 + 7 * math.cos(a), 106 + 7 * math.sin(a), 4.6, 2.6, WHITE,
                    transform='rotate(%s %s %s)' % (f(a * 57.2958), f(134 + 7 * math.cos(a)), f(106 + 7 * math.sin(a))))
                  for a in [k * 0.785 for k in range(8)]]
        return [glow(132, 140, 30), P('M120 %s h26 l-3 22 h-20 Z' % f(SILL_Y - 22), '#E39A7B'), R(118, SILL_Y - 26, 30, 6, '#D9866A', rx=2),
                P('M133 %s Q131 120 134 108' % f(SILL_Y - 26), stroke='#5BA35A', stroke_width=3),
                E(126, 128, 7, 3.5, '#76B96A', transform='rotate(30 126 128)')] + petals + [C(134, 106, 4, GOLD), spark(156, 96, 5)]
    if course == 'heb':                           # a paper boat, folded from a drawing sheet, on the sill
        y = SILL_Y
        return [glow(132, y - 18, 32),
                P('M100 %s L164 %s L152 %s H112 Z' % (f(y - 16), f(y - 16), f(y)), '#FFFFFF'),
                P('M100 %s L164 %s L152 %s H112 Z' % (f(y - 16), f(y - 16), f(y)), 'none', stroke='#C9D3E2', stroke_width=2, stroke_linejoin='round'),
                P('M132 %s L132 %s L158 %s Z' % (f(y - 16), f(y - 54), f(y - 16)), '#F1EEF6', stroke='#C9D3E2', stroke_width=2, stroke_linejoin='round'),
                P('M132 %s L132 %s L108 %s Z' % (f(y - 16), f(y - 54), f(y - 16)), '#FFFFFF', stroke='#C9D3E2', stroke_width=2, stroke_linejoin='round'),
                P('M112 %s q6 -6 12 0 q6 6 12 0 q6 -6 12 0' % f(y - 8), stroke=CORAL, stroke_width=2.6, stroke_linecap='round'),
                spark(164, y - 50, 5)]
    return [glow(134, 130, 32), P('M122 %s h24 l-3 24 h-18 Z' % f(SILL_Y - 24), '#B9A2F7'), R(120, SILL_Y - 28, 28, 6, '#9C84E0', rx=2),
            P('M134 %s Q132 110 136 86' % f(SILL_Y - 28), stroke='#5BA35A', stroke_width=3),
            P('M134 126 q-14 -4 -16 -16 q12 2 16 16 Z', '#76B96A'),
            P('M128 88 q8 -14 16 0 q-2 10 -8 10 q-6 0 -8 -10 Z', '#F7A8C4'), P('M136 78 q4 6 0 20', stroke='#E78AAE', stroke_width=1.5),
            spark(156, 80, 5)]


def window_reacted(course):
    frame, _ = WIN[course]
    g = _glass(course) % GLASS_LIT
    sun = [C(100, 124 if course != 'heb' else 132, 20, SUN)]
    rays = P(''.join('M%s %s L%s %s ' % (f(100 + 26 * math.cos(a)), f(124 - 26 * math.sin(a)),
                                         f(100 + 36 * math.cos(a)), f(124 - 36 * math.sin(a)))
                     for a in [k * 0.6 + 0.3 for k in range(5)]), stroke=GOLD_DEEP, stroke_width=3.5, stroke_linecap='round')
    # the sun rises inside the glass: clipped to the glass shape
    cid = 'glass-%s' % course
    out = ['<defs><clipPath id="%s">%s</clipPath></defs>' % (cid, _glass(course) % '#000'), g,
           '<g clip-path="url(#%s)">%s</g>' % (cid, ''.join(sun + [rays])), _bars(course, frame)]
    if course == 'eng':
        out.append(C(100, 92, 52, 'none', stroke=frame, stroke_width=3))
    return out


# -- English: Pip the budgie's reading nook (round window, a bookshelf, Pip's perch stand)
def eng_top():
    out = [R(0, 0, 2400, 12, WHITE), R(0, 12, 2400, 4, '#D3E0EF')]
    for k in range(8):                           # a garland of round paper lanterns (the round window's shape)
        x0 = k * 300
        out.append(P('M%s 16 Q%s 52 %s 16' % (f(x0), f(x0 + 150), f(x0 + 300)), stroke='#B9C7D9', stroke_width=2))
        cx = x0 + 150
        col = ('#FFFFFF', '#FFF1C4', '#D8E7F7')[k % 3]
        out += [P('M%s 34 V42' % f(cx), stroke='#B9C7D9', stroke_width=2), C(cx, 58, 16, col),
                P('M%s 44 Q%s 58 %s 72 M%s 44 Q%s 58 %s 72' % (f(cx - 6), f(cx - 11), f(cx - 6), f(cx + 6), f(cx + 11), f(cx + 6)),
                  stroke='#C9D6E6', stroke_width=1.4), R(cx - 5, 40, 10, 4, '#B9C7D9', rx=1)]
    return out


def eng_far():
    out = [R(0, 80, 1600, 120, '#D9E6F5'), R(0, 76, 1600, 8, WHITE), R(0, 84, 1600, 3, '#C6D7EC')]
    out.append(P(''.join('M%s 88 V200 ' % f(x) for x in range(12, 1600, 26)), stroke='#CBDBEE', stroke_width=2))
    return out


def eng_ground():
    out = [R(0, 6, 2400, 12, WHITE), R(0, 18, 2400, 3, '#C6D7EC'), R(0, 21, 2400, 79, '#E2B48C')]
    out.append(P('M0 44 H2400 M0 70 H2400', stroke=WOOD, stroke_width=1.6, opacity=0.6))
    out.append(P(''.join('M%s 21 V44 M%s 44 V70 M%s 70 V100 ' % (f(x), f(x + 90), f(x + 40)) for x in range(30, 2400, 180)),
                 stroke=WOOD, stroke_width=1.6, opacity=0.6))
    # a rectangular rug with a soft border and a fringe (no row of small shapes: nothing to count)
    out += [P(''.join('M%s 52 v-5 M%s 96 v5 ' % (f(x), f(x)) for x in range(960, 1442, 12)), stroke='#C9D6E6', stroke_width=2),
            R(950, 52, 500, 44, '#9FBEE2', rx=6), R(958, 57, 484, 34, '#DCE8F6', rx=4)]
    out += [R(966, 62, 468, 24, 'none', rx=3, stroke='#B5CDEB', stroke_width=3), R(976, 72, 448, 4, '#C9DAF0', rx=2)]
    return out


BOOKS = ['#F07F6E', '#FFC83D', '#5BB6E0', '#8FD3A0', '#B9A2F7', '#F4A7B4', '#3E8EDE']


def bookshelf(x, y, w, h, shelves, wood=WOOD_LIGHT, back='#B98A5E'):
    out = [shadow(x + w / 2, y + h, w * 0.6, 5), R(x, y, w, h, wood, rx=3), R(x + 6, y + 6, w - 12, h - 12, back)]
    sh = (h - 12) / shelves
    k = 0
    for s in range(shelves):
        by = y + 6 + sh * (s + 1)
        out.append(R(x + 6, by - 4, w - 12, 5, wood))
        bx = x + 9
        while bx < x + w - 16:
            bw = 7 + (k * 5) % 5
            bh = sh - 12 - (k * 7) % 9
            col = BOOKS[k % len(BOOKS)]
            if k % 6 == 4:                       # now and then a book leans
                out.append(R(bx, by - 4 - bh, bw, bh, col, rx=1.5, transform='rotate(-14 %s %s)' % (f(bx), f(by - 4))))
                bx += bw + 8
            else:
                out += [R(bx, by - 4 - bh, bw, bh, col, rx=1.5), R(bx, by - 4 - bh + 4, bw, 2.5, WHITE, opacity=0.5)]
                bx += bw + 2
            k += 1
    return out


def eng_corner():
    out = bookshelf(130, 70, 96, 126, 3)
    out += [C(178, 52, 17, '#5BB6E0'), P('M168 44 q8 -4 10 4 q-2 8 -10 6 Z M182 56 q8 -2 8 6 q-6 4 -8 -6 Z', '#8FD3A0'),
            P('M178 70 V68 M164 70 H192', stroke=WOOD, stroke_width=3), P('M160 52 A18 18 0 0 0 196 52', stroke=WOOD, stroke_width=2.4)]
    # Pip's perch stand: a base, a pole, a T-perch, a ring toy and a little bell
    out += [shadow(62, 196, 32, 4), E(62, 191, 28, 7, WOOD), E(62, 189, 24, 5, WOOD_LIGHT),
            P('M62 190 V56', stroke=WOOD, stroke_width=8, stroke_linecap='round'),
            P('M20 58 H104', stroke=WOOD_LIGHT, stroke_width=11, stroke_linecap='round'), P('M22 55 H102', stroke=WHITE, stroke_width=2, opacity=0.4,
                                                                                         stroke_linecap='round'),
            P('M32 62 V86 M92 62 V92', stroke='#9FB2CB', stroke_width=2.4),
            C(32, 100, 14, 'none', stroke='#F07F6E', stroke_width=5.5),
            P('M84 92 q8 -14 16 0 v5 h-16 Z', GOLD), C(92, 100, 3, GOLD_DEEP), R(90, 86, 4, 4, '#9FB2CB')]
    return out


# -- Hebrew: the hyrax's drawing room (arched window, pegged drawings of practice lines, an easel, a jar of pencils)
def heb_top():
    """A twine across the wall with the hyrax's practice sheets pegged on it, one at the low point of each sag (wavy lines,
    zigzags, loops: strokes, never letters or pictures that a Find item could ask for)."""
    out = []
    for k in range(7):
        x0 = k * 360
        out.append(P('M%s 6 Q%s 34 %s 6' % (f(x0), f(x0 + 180), f(x0 + 360)), stroke='#C9A27A', stroke_width=2.4))
        cx, cy = x0 + 180, 22
        rot = (-4, 3, -2, 5)[k % 4]
        kind = k % 3
        stroke = ('M%s %s q7 -9 14 0 q7 9 14 0 q7 -9 14 0' % (f(cx - 21), f(cy + 36)) if kind == 0 else
                  'M%s %s l7 -11 l7 11 l7 -11 l7 11 l7 -11 l7 11' % (f(cx - 21), f(cy + 41)) if kind == 1 else
                  'M%s %s c4 -14 14 -14 12 0 c-2 9 -12 5 -5 -7 c7 -12 17 -7 14 5' % (f(cx - 16), f(cy + 42)))
        out.append(G([R(cx - 30, cy + 6, 60, 66, WHITE, rx=2), R(cx - 30, cy + 64, 60, 8, '#F1E7DD'),
                      P(stroke, stroke=(CORAL, '#5BB6E0', '#8A63D2')[kind], stroke_width=3.4, stroke_linecap='round', stroke_linejoin='round'),
                      R(cx - 3.5, cy, 7, 14, WOOD, rx=2)], 'rotate(%s %s %s)' % (rot, f(cx), f(cy))))
    return out


def heb_far():
    stone, joint, cap = '#F7EBD6', '#EADAC0', '#FBF3E4'
    out = [R(0, 88, 1600, 112, joint), R(0, 80, 1600, 10, cap)]
    for row, y in enumerate((92, 124, 156, 188)):
        off = 0 if row % 2 == 0 else 46
        for x in range(-92 + off, 1600, 92):
            out.append(R(x + 3, y, 86, 28, stone, rx=6))
    return out


def heb_ground():
    out = [R(0, 14, 2400, 86, '#E3D6C4'), R(0, 10, 2400, 6, '#D6C4AA')]
    for row, (y, h, off) in enumerate(((18, 34, 0), (56, 44, 60))):
        for x in range(-120 + off, 2400, 120):
            out.append(R(x + 3, y, 114, h - 4, '#EEE3D2', rx=5))
    return out


def heb_corner():
    out = [shadow(112, 196, 70, 5),
           # the easel with a big sheet of practice lines
           P('M116 40 L128 194', stroke='#B98A5E', stroke_width=6, stroke_linecap='round'),
           P('M112 34 L80 196 M112 34 L146 196', stroke=WOOD_LIGHT, stroke_width=7, stroke_linecap='round'),
           R(72, 126, 82, 8, WOOD_LIGHT, rx=3),
           R(74, 46, 78, 78, WHITE, rx=2), R(113, 46, 39, 78, '#F6F1EA'),
           P('M82 70 q8 -12 16 0 q8 12 16 0 q8 -12 16 0 q8 12 16 0', stroke=CORAL, stroke_width=3.4, stroke_linecap='round'),
           P('M84 100 l8 -12 l8 12 l8 -12 l8 12 l8 -12 l8 12', stroke='#5BB6E0', stroke_width=3.4, stroke_linecap='round', stroke_linejoin='round'),
           R(106, 38, 12, 10, WOOD, rx=2),
           # a small stool with a jar of big pencils
           R(172, 168, 44, 8, WOOD_LIGHT, rx=3), P('M178 176 L174 196 M210 176 L214 196', stroke=WOOD, stroke_width=4, stroke_linecap='round'),
           P('M180 130 h28 v36 q0 4 -4 4 h-20 q-4 0 -4 -4 Z', '#E6F2F6'), R(182, 136, 4, 26, WHITE, opacity=0.8)]
    for k, (x, col, tilt) in enumerate(((186, CORAL, -10), (193, GOLD, -2), (200, '#5BB6E0', 6), (206, '#8FD3A0', 14))):
        out.append(G([R(x - 3, 96, 6, 40, col, rx=1), P(poly((x - 3, 96), (x, 86), (x + 3, 96)), '#F3D9B5'),
                      P(poly((x - 1, 89), (x, 86), (x + 1, 89)), INK)], 'rotate(%s %s 136)' % (tilt, f(x))))
    # a woven floor basket with rolled sheets of paper
    out += [shadow(36, 196, 30, 4), P('M10 160 h52 l-6 34 h-40 Z', '#D7A27A'),
            P('M14 170 H58 M16 182 H56', stroke=WOOD, stroke_width=2, opacity=0.6),
            G([R(16, 128, 10, 36, WHITE, rx=5), R(28, 122, 10, 42, '#FFF6E8', rx=5), R(40, 132, 10, 32, WHITE, rx=5)], 'rotate(-6 36 160)'),
            E(21, 128, 5, 2.4, '#EDE3D6'), E(33, 122, 5, 2.4, '#EDE3D6'), E(45, 132, 5, 2.4, '#EDE3D6')]
    return out


# -- Russian: the giraffe's tall room (square window, panelled wall, a tall plant, a floor lamp, two pendant lamps)
def rus_top():
    out = [R(0, 0, 2400, 12, WHITE), R(0, 12, 2400, 4, '#DCD2EC')]
    for x in (780, 1620):
        out += [P('M%s 16 V46' % f(x), stroke='#A99BC4', stroke_width=2.4),
                C(x, 74, 22, GOLD_TINT, opacity=0.7),
                P('M%s 70 Q%s 44 %s 44 Q%s 44 %s 70 Z' % (f(x - 32), f(x - 30), f(x), f(x + 30), f(x + 32)), '#FFF3D6'),
                P('M%s 70 Q%s 44 %s 44 Q%s 46 %s 70 Z' % (f(x + 6), f(x + 8), f(x), f(x + 28), f(x + 32)), '#F4E3BC'),
                R(x - 32, 67, 64, 6, '#8A63D2', rx=2), C(x, 77, 6, GOLD)]
    return out


def rus_far():
    out = [R(0, 92, 1600, 108, '#E5DCF3'), R(0, 86, 1600, 8, WHITE), R(0, 94, 1600, 3, '#D3C7E8')]
    for x in range(20, 1600, 120):
        out.append(R(x, 112, 96, 96, 'none', rx=6, stroke='#D6CAEB', stroke_width=3))
    return out


def rus_ground():
    out = [R(0, 6, 2400, 12, WHITE), R(0, 18, 2400, 3, '#D3C7E8'), R(0, 21, 2400, 79, '#DDB08A')]
    p = ''
    for x in range(0, 2400, 40):                 # herringbone parquet
        p += 'M%s 21 l20 20 l-20 20 l20 20 l-20 20 ' % f(x)
    out.append(P(p, stroke=WOOD, stroke_width=1.6, opacity=0.55))
    # a rug: fringe, a violet border, a cream field with two broad soft bands
    rug = [P(''.join('M%s 48 v-6 M%s 98 v6 ' % (f(x), f(x)) for x in range(946, 1456, 10)), stroke='#D6C6A8', stroke_width=2.2),
           R(936, 46, 528, 54, '#B9A2F7', rx=6), R(946, 53, 508, 40, '#F1E7D4', rx=4),
           R(946, 60, 508, 8, '#F4A7B4', opacity=0.75), R(946, 78, 508, 8, '#B9A2F7', opacity=0.6),
           P('M1200 56 l14 17 l-14 17 l-14 -17 Z', '#8A63D2', opacity=0.55)]
    return out + rug


def rus_corner():
    out = [shadow(170, 196, 40, 5),
           # a tall leafy plant in a tall pot (the giraffe likes tall things)
           P('M148 140 h48 l-6 56 h-36 Z', '#B9A2F7'), R(144, 134, 56, 10, '#9C84E0', rx=3), P('M172 144 h24 l-6 52 h-18 Z', '#8A63D2', opacity=0.35),
           P('M172 136 Q168 80 178 22', stroke='#5BA35A', stroke_width=4, stroke_linecap='round'),
           P('M171 110 Q142 104 132 80 Q160 80 171 110 Z', '#6FBF8C'), P('M174 86 Q206 82 216 56 Q186 58 174 86 Z', '#4CB673'),
           P('M173 62 Q148 52 144 26 Q170 32 173 62 Z', '#4CB673'), P('M177 34 Q196 16 214 18 Q202 40 177 34 Z', '#6FBF8C'),
           P('M172 128 Q198 126 208 104 Q184 104 172 128 Z', '#4CB673'),
           # a floor lamp with a drum shade, lit softly
           shadow(64, 196, 26, 4), E(64, 192, 20, 5, '#6D49B3'), P('M64 190 V60', stroke='#6D49B3', stroke_width=4.5),
           C(64, 62, 32, GOLD_TINT, opacity=0.6), P('M40 32 h48 l9 32 h-66 Z', '#FFF3D6'), P('M64 32 h24 l9 32 h-33 Z', '#F4E3BC'),
           R(31, 62, 66, 5, '#8A63D2', rx=2), R(40, 30, 48, 5, '#8A63D2', rx=2),
           # a stack of two floor cushions
           E(110, 188, 26, 8, '#F4A7B4'), E(110, 178, 22, 7, '#B9A2F7'), E(110, 176, 18, 5, '#D6C6FA')]
    return out


def sun(x, y, r=24, body='#FFE08A', core='#FFD25A', halo=GOLD_TINT, rays=True):
    """A soft sun for the top band: a halo, short rounded rays, a two-tone disc."""
    out = [glow(x, y, r * 2.4, halo, 4, 0.35)]
    if rays:
        out.append(P(''.join('M%s %s L%s %s ' % (f(x + r * 1.35 * math.cos(a)), f(y + r * 1.35 * math.sin(a)),
                                                 f(x + r * 1.75 * math.cos(a)), f(y + r * 1.75 * math.sin(a)))
                             for a in [k * math.pi / 5 for k in range(10)]), stroke=body, stroke_width=r * 0.22, stroke_linecap='round'))
    return ''.join(out + [C(x, y, r, body), C(x - r * 0.12, y - r * 0.12, r * 0.78, core), C(x - r * 0.4, y - r * 0.4, r * 0.2, WHITE, opacity=0.6)])


def fir(cx, base, h, w, lit, shade, tiers=3, trunk=None):
    """A fir or cypress in rounded tiers (so it reads as a tree, not as a geometric triangle); lit on the left.
    Tier 0 is the top one; each lower tier is wider and starts lower; the upper tiers are drawn over the lower ones."""
    out = []
    if trunk:
        out.append(R(cx - w * 0.13, base - h * 0.07, w * 0.26, h * 0.1, trunk, rx=1.5))
    top = base - h
    n = max(1, tiers)
    for j in range(n - 1, -1, -1):
        t = j / max(1, n - 1)
        tt = top + j * h * 0.2
        tb = top + h * (0.45 + 0.49 * t) if n > 1 else base - h * 0.06
        tw = w * (0.55 + 0.45 * t) if n > 1 else w
        out.append(P('M%s %s L%s %s L%s %s Q%s %s %s %s Z' % (f(cx - tw), f(tb), f(cx), f(tt), f(cx + tw), f(tb), f(cx), f(tb + tw * 0.34),
                                                            f(cx - tw), f(tb)), lit))
        out.append(P('M%s %s L%s %s Q%s %s %s %s Z' % (f(cx), f(tt), f(cx + tw), f(tb), f(cx + tw * 0.45), f(tb + tw * 0.26),
                                                     f(cx + tw * 0.06), f(tb + tw * 0.3)), shade))
    return ''.join(out)


def colors_top():
    # a bright sun, white clouds and a kite in the rainbow's colours (all within the band's middle, so every stage shape shows them)
    kite = G([P('M0 -20 L14 0 L0 22 L-14 0 Z', '#FF5A5F'), P('M0 -20 L14 0 L0 0 Z', '#FFD93D'), P('M-14 0 L0 0 L0 22 Z', '#3E9BEA'),
              P('M0 0 L14 0 L0 22 Z', '#5BCB6A'), P('M0 -20 V22 M-14 0 H14', stroke='#7A4E32', stroke_width=1.4, opacity=0.6),
              P('M0 22 q-6 10 4 16 q10 6 2 18', stroke='#7A4E32', stroke_width=1.6, stroke_linecap='round'),
              P('M2 36 l-6 -4 l0 8 Z M2 36 l6 -4 l0 8 Z', '#9B6BE0')], 'translate(900 30) rotate(-14)')
    return [sun(1560, 34, 22, '#FFD93D', '#FFC21A', '#FFF1C4'), cloud(640, 34, 0.9), cloud(1240, 28, 0.7), cloud(1980, 36, 0.9),
            kite, gull(1080, 40, '#5FB3C2'), gull(1112, 52, '#5FB3C2', 0.8)]


POOL = dict(cx=100, cy=164)


def shapes_top():
    return [sun(1660, 34, 22), cloud(640, 32, 0.85), cloud(1220, 24, 0.65, op=0.85), cloud(1990, 34, 0.85)]


# ================================================================ writing the files
DRAW = {
    'numbers': dict(top=numbers_top, far=numbers_far, ground=numbers_ground, corner=numbers_corner, landmark=numbers_landmark,
                    piece=numbers_piece, reacted=numbers_reacted),
    'colors': dict(top=colors_top, far=colors_far, ground=colors_ground, corner=colors_corner, landmark=colors_landmark,
                   piece=colors_piece, reacted=colors_reacted),
    'shapes': dict(top=shapes_top, far=shapes_far, ground=shapes_ground, corner=shapes_corner, landmark=shapes_landmark,
                   piece=shapes_piece, reacted=shapes_reacted),
    'logic': dict(top=logic_top, far=logic_far, ground=logic_ground, corner=logic_corner, landmark=logic_landmark,
                  piece=logic_piece, reacted=logic_reacted),
    'cs': dict(top=cs_top, far=cs_far, ground=cs_ground, corner=cs_corner, landmark=cs_landmark, piece=cs_piece, reacted=cs_reacted),
    'math': dict(top=math_top, far=math_far, ground=math_ground, corner=math_corner, landmark=math_landmark,
                 piece=math_piece, reacted=math_reacted),
    'eng': dict(top=eng_top, far=eng_far, ground=eng_ground, corner=eng_corner, landmark=lambda: window_landmark('eng'),
                piece=lambda: window_piece('eng'), reacted=lambda: window_reacted('eng')),
    'heb': dict(top=heb_top, far=heb_far, ground=heb_ground, corner=heb_corner, landmark=lambda: window_landmark('heb'),
                piece=lambda: window_piece('heb'), reacted=lambda: window_reacted('heb')),
    'rus': dict(top=rus_top, far=rus_far, ground=rus_ground, corner=rus_corner, landmark=lambda: window_landmark('rus'),
                piece=lambda: window_piece('rus'), reacted=lambda: window_reacted('rus')),
}
SIZE = dict(top=(2400, 100), far=(1600, 200), ground=(2400, 100), corner=(240, 200), landmark=(200, 200), piece=(200, 200), reacted=(200, 200))


def room_svg(room, part):
    fn = DRAW[room][part]
    if fn is None:
        return None
    w, h = SIZE[part]
    return doc(w, h, fn(), '%s %s' % (room, part))


def main():
    os.makedirs(OUT, exist_ok=True)
    n = 0
    for room in ROOMS:
        for part in SIZE:
            s = room_svg(room, part)
            if s is None:
                continue
            with open(os.path.join(OUT, '%s_%s.svg' % (room, part)), 'w', encoding='utf-8', newline='\n') as fh:
                fh.write(s)
            n += 1
    print('%d files' % n)


if __name__ == '__main__':
    main()
