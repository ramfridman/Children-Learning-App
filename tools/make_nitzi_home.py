"""Draws the child's home (B-26, "Nitzi's home"): the close-up scene of the home island on the four boards and its three objects.

    python tools/make_nitzi_home.py

Writes (deterministic: the same script gives the same bytes):
  app/assets/art/scenes/nitzi_home_phone.svg              852 x 393   the close-up scene, phone board
  app/assets/art/scenes/nitzi_home_phone_se.svg           667 x 375   the same scene, phoneSE board
  app/assets/art/scenes/nitzi_home_tablet_landscape.svg  1180 x 820   tablet landscape board
  app/assets/art/scenes/nitzi_home_tablet_portrait.svg    820 x 1180  tablet portrait board (the beach row at the bottom)
  app/assets/art/home/lighthouse.svg     100 x 220  the Trophy Hall: a banded tower on its rocks, gallery, lantern window
  app/assets/art/home/bottle_big.svg     100 x 100  today's adventure: a glass bottle with a cork and a rolled letter
  app/assets/art/home/sticker_book.svg   100 x 100  the sticker album standing on a driftwood stump

The scenes hold only the place: sea, the island (sand, wet sand, grass), the house with its porch (the companion stands on it,
drawn by the app), the palm, the rocks the lighthouse stands on, a path of stepping stones, flowers, shells and sparkles. The
three objects are separate files the app draws in their tap areas (docs/design/nitzi-home.md section 3, BoxFit.contain,
Alignment.bottomCenter), so real art drops in by file name. No text and no numerals in any picture; no franchise look; no
real person. The palette is the map's own (tools/make_home_map.py, design/tokens.json), so the map and the home are one place.

References looked at on 2026-10-29 (facts and photographs; nothing traced or copied, the look is ours; notes in
docs/design/nitzi-home-references.md):
  Message in a bottle: "Message Bottle on Sand.jpg" (Snapwire, CC0) and "Message in a bottle (12407730413).jpg" (Susanne
    Nilsson, CC BY-SA 2.0), Wikimedia Commons; https://en.wikipedia.org/wiki/Message_in_a_bottle. A clear, slightly green
    glass bottle lying on its side, half sunk in wet sand that is darker than the dry sand; a cork or cap; the rolled paper
    shows as a pale cylinder through the glass, often tied with a ribbon; one long bright highlight along the glass.
  Lighthouse: "Portland Bill. Dorset. (4793113146).jpg" (Amanda Slater, Wikimedia Commons) and the Jaffa Light photographs
    (https://en.wikipedia.org/wiki/Jaffa_Light, Commons search "Jaffa lighthouse"). A tower that narrows towards the top,
    painted in wide red and white bands; a dark gallery deck with a railing; a glazed lantern with thin bars; a dark domed
    cap with a small ball; small windows in a line; a door at the foot; it stands on rocks at the water's edge.
  Beach book box: "Little Free Library at Bella Beach.jpg" (Rick Obst, CC BY 4.0, Wikimedia Commons) and other Little Free
    Library photographs: a small wooden box on a single wooden post near the beach, books standing with coloured spines. We
    keep the idea (a book on a piece of wood at the beach) and draw one album on a stump, the clearest "book" for a child.
  Tree stumps: Commons search "tree stump rings": a pale cut top with rings, darker bark sides in vertical strips, roots
    flaring at the foot.
  A small island close up: https://en.wikipedia.org/wiki/Cay (Heron Island photograph) and "Kem Beach aerial view Phu Quoc
    Island Vietnam.jpg" (Vivu Vietnam, CC BY-SA 4.0): pale turquoise shallows around the island, a bright foam line at the
    shore, a darker band of wet sand, dry pale sand, then the green with a soft edge; palms lean out over the sand.
  Our approved boards: design/renders/10-phone-home.png, 22-tablet-home-landscape.png, 25-tablet-home-portrait.png (the home
    island's red-roof house, palm and red-and-white lighthouse, the island layers, waves and sparkles).
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_home_map import (SEA, WAVE, FOAM, SAND, SAND_SHADE, GRASS, GRASS_SHADE, WOOD, WOOD_LIGHT, CORAL, GOLD, INK,  # noqa: E402
                           el, f, g, sparkle, waves, gull)

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
SCENES = os.path.join(ROOT, 'app', 'assets', 'art', 'scenes')
HOME = os.path.join(ROOT, 'app', 'assets', 'art', 'home')

CORAL_DEEP, WALL, WALL_SHADE = '#D9604F', '#FFFBF4', '#F0E3D2'
WET_SAND, ROCK, ROCK_SHADE, ROCK_LIGHT = '#E2BE86', '#C9B79A', '#A8957A', '#DDD0B8'
LEAF, LEAF_DEEP, TRUNK, TRUNK_RING = '#6FBF8C', '#4FA374', '#B07A52', '#946140'
GLASS_SKY, SHADOW = '#8FD3F4', '#2B2350'


def ellipse(cx, cy, rx, ry, fill, **a):
    return el('ellipse', cx=cx, cy=cy, rx=rx, ry=ry, fill=fill, **a)


def path(d, fill, **a):
    return el('path', d=d, fill=fill, **a)


def write(folder, name, text):
    os.makedirs(folder, exist_ok=True)
    with open(os.path.join(folder, name), 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(text)


def svg(w, h, label, parts, sea=True):
    head = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %s %s" role="img" aria-label="%s">' % (f(w), f(h), label)
    bg = el('rect', x=0, y=0, width=w, height=h, fill=SEA) if sea else ''
    return head + bg + ''.join(parts) + '</svg>\n'


# ---------------------------------------------------------------- scene pieces
def island(sand, grass):
    """The map's island layers, close up: sea halo, foam rim, sand edge, sand, grass shade, grass (all ellipses)."""
    cx, cy, rx, ry = sand
    gx, gy, grx, gry = grass
    return [ellipse(cx, cy + 0.06 * ry, rx * 1.05, ry * 1.08, WAVE, opacity=0.6),
            ellipse(cx, cy + 0.03 * ry, rx * 1.015, ry * 1.03, FOAM, opacity=0.85),
            ellipse(cx, cy + 0.02 * ry, rx, ry, SAND_SHADE),
            ellipse(cx, cy, rx * 0.985, ry * 0.97, SAND),
            ellipse(gx, gy + 0.05 * gry, grx * 1.02, gry * 1.02, GRASS_SHADE),
            ellipse(gx, gy, grx, gry, GRASS)]


def wet_sand(cx, cy, rx, ry):
    """Darker wet sand where the last wave reached, with a lacy foam edge on its sea side."""
    out = [ellipse(cx, cy, rx, ry, WET_SAND, opacity=0.75)]
    n = 6
    d = 'M%s %s' % (f(cx - rx * 0.9), f(cy + ry * 0.55))
    for i in range(n):
        x0 = cx - rx * 0.9 + (1.8 * rx) * i / n
        x1 = cx - rx * 0.9 + (1.8 * rx) * (i + 1) / n
        d += ' Q%s %s %s %s' % (f((x0 + x1) / 2), f(cy + ry * (0.95 if i % 2 else 0.75)), f(x1), f(cy + ry * 0.55))
    out.append(path(d, 'none', stroke=FOAM, stroke_width=max(2.5, ry * 0.12), stroke_linecap='round', opacity=0.9))
    return out


def stones(points, s):
    """Flat stepping stones from the porch towards the bottle."""
    out = []
    for (x, y) in points:
        out += [ellipse(x, y + 2 * s, 13 * s, 5.5 * s, SHADOW, opacity=0.12),
                ellipse(x, y, 13 * s, 5.5 * s, '#EDE4D3'),
                ellipse(x - 2 * s, y - 1.2 * s, 7 * s, 2.4 * s, '#FFFFFF', opacity=0.5)]
    return out


def tuft(x, y, s):
    return path('M%s %s l%s %s M%s %s l0 %s M%s %s l%s %s' % (f(x - 2 * s), f(y), f(-3 * s), f(-7 * s), f(x), f(y), f(-9 * s),
                                                           f(x + 2 * s), f(y), f(3 * s), f(-7 * s)),
                'none', stroke=GRASS_SHADE, stroke_width=2.2 * s, stroke_linecap='round')


def flowers(x, y, s, col):
    """A small clump: a leafy mound and three five-petal flowers."""
    out = [ellipse(x, y + 2 * s, 16 * s, 6 * s, GRASS_SHADE)]
    for (dx, dy) in ((-8, -3), (6, -6), (0, 2)):
        cx, cy = x + dx * s, y + dy * s
        for k in range(5):
            a = math.radians(90 + 72 * k)
            out.append(el('circle', cx=cx + 3.4 * s * math.cos(a), cy=cy - 3.4 * s * math.sin(a), r=2.6 * s, fill=col))
        out.append(el('circle', cx=cx, cy=cy, r=2 * s, fill=GOLD if col != GOLD else '#FFFFFF'))
    return out


def bush(x, y, s):
    return [ellipse(x, y + 10 * s, 26 * s, 6 * s, SHADOW, opacity=0.1),
            el('circle', cx=x - 13 * s, cy=y, r=12 * s, fill='#58B06F'),
            el('circle', cx=x + 12 * s, cy=y + 1 * s, r=11 * s, fill='#58B06F'),
            el('circle', cx=x, cy=y - 7 * s, r=15 * s, fill='#6CC283'),
            ellipse(x - 5 * s, y - 13 * s, 5 * s, 3 * s, '#FFFFFF', opacity=0.3)]


def shell(x, y, s, col='#F4A7B4', dark='#D9788A'):
    return [path('M%s %s A%s %s 0 0 1 %s %s Z' % (f(x - 7 * s), f(y), f(7 * s), f(7 * s), f(x + 7 * s), f(y)), col),
            path('M%s %s L%s %s M%s %s L%s %s M%s %s L%s %s' % (f(x), f(y), f(x), f(y - 6 * s), f(x), f(y), f(x - 4.2 * s),
                                                               f(y - 4.6 * s), f(x), f(y), f(x + 4.2 * s), f(y - 4.6 * s)),
                 'none', stroke=dark, stroke_width=1.3 * s, stroke_linecap='round')]


def starfish(x, y, s):
    pts = []
    for k in range(10):
        a = math.radians(-90 + 36 * k)
        r = (8 if k % 2 == 0 else 3.6) * s
        pts.append('%s %s' % (f(x + r * math.cos(a)), f(y + r * math.sin(a) * 0.8)))
    return [path('M' + ' L'.join(pts) + ' Z', '#FF9A6B', stroke='#E9774A', stroke_width=1.2 * s, stroke_linejoin='round')]


def rocks(cx, base, w, foam=True):
    """The rocky foot the lighthouse stands on: w is about the width of the drawn tower. With foam it stands at the water's
    edge (phones, landscape); without, on a rocky knoll inland (portrait, where the island is tall)."""
    s = w / 100
    out = [ellipse(cx, base + 4 * s, 66 * s, 13 * s, FOAM, opacity=0.9)] if foam else [ellipse(cx, base + 4 * s, 64 * s, 10 * s, SHADOW, opacity=0.1)]
    return out + [
            ellipse(cx - 34 * s, base - 2 * s, 24 * s, 15 * s, ROCK_SHADE),
            ellipse(cx + 36 * s, base, 22 * s, 13 * s, ROCK_SHADE),
            ellipse(cx - 6 * s, base - 8 * s, 44 * s, 18 * s, ROCK),
            ellipse(cx - 14 * s, base - 16 * s, 22 * s, 7 * s, ROCK_LIGHT),
            ellipse(cx + 30 * s, base - 4 * s, 16 * s, 9 * s, ROCK),
            ellipse(cx - 52 * s, base + 4 * s, 12 * s, 7 * s, ROCK),
            path('M%s %s q%s %s %s 0 q%s %s %s 0' % (f(cx - 64 * s), f(base + 12 * s), f(8 * s), f(-5 * s), f(16 * s),
                                                    f(8 * s), f(5 * s), f(16 * s)),
                 'none', stroke=FOAM, stroke_width=3 * s, stroke_linecap='round')][:None if foam else -1]


def palm(bx, by, tx, ty, s):
    """A palm leaning out: a curved trunk with ring marks, six drooping fronds, three coconuts. s = 1 is the phone's size."""
    out = [ellipse(bx + 10 * s, by + 3 * s, 26 * s, 6 * s, SHADOW, opacity=0.1)]
    cx1, cy1 = bx + (tx - bx) * 0.15 + 14 * s, by + (ty - by) * 0.5
    out.append(path('M%s %s Q%s %s %s %s' % (f(bx), f(by), f(cx1), f(cy1), f(tx), f(ty)), 'none', stroke=TRUNK,
                    stroke_width=10 * s, stroke_linecap='round'))
    for k in range(1, 7):
        t = k / 7.5
        x = (1 - t) ** 2 * bx + 2 * (1 - t) * t * cx1 + t * t * tx
        y = (1 - t) ** 2 * by + 2 * (1 - t) * t * cy1 + t * t * ty
        out.append(path('M%s %s l%s %s' % (f(x - 4.6 * s), f(y), f(9.2 * s), f(-1.5 * s)), 'none', stroke=TRUNK_RING,
                        stroke_width=1.6 * s, stroke_linecap='round'))
    L = 58 * s

    def leaf(angle, length, col, mirror):
        d = 'M0 0 C%s %s %s %s %s %s C%s %s %s %s 0 0 Z' % (
            f(length * 0.3), f(-length * 0.3), f(length * 0.78), f(-length * 0.24), f(length), f(length * 0.2),
            f(length * 0.68), f(-length * 0.02), f(length * 0.3), f(length * 0.06))
        rib = 'M0 0 C%s %s %s %s %s %s' % (f(length * 0.3), f(-length * 0.2), f(length * 0.7), f(-length * 0.14),
                                           f(length * 0.96), f(length * 0.16))
        tr = 'translate(%s %s)%s rotate(%s)' % (f(tx), f(ty), ' scale(-1 1)' if mirror else '', f(angle))
        return '<g transform="%s">%s%s</g>' % (tr, path(d, col), path(rib, 'none', stroke=LEAF_DEEP, stroke_width=1.6 * s,
                                                                        stroke_linecap='round', opacity=0.8))
    out += [leaf(-30, L * 0.8, LEAF_DEEP, True), leaf(-30, L * 0.8, LEAF_DEEP, False),
            leaf(5, L, LEAF, True), leaf(5, L, LEAF, False), leaf(-62, L * 0.75, LEAF, True), leaf(-58, L * 0.75, LEAF, False)]
    for (dx, dy) in ((-5, 5), (5, 6), (0, 10)):
        out.append(el('circle', cx=tx + dx * s, cy=ty + dy * s, r=5 * s, fill='#8A5F3E'))
    return out


def house(x, y, w, h, door_cx):
    """The map's red-roof house, close up: chimney, tiled gable roof with a round window, white walls, two windows with
    flower boxes, an arched door (behind the companion) and a plank porch the companion stands on."""
    out = []
    s = w / 250
    roof_base = y + 0.42 * h
    wall_top, wall_bot = roof_base - 4 * s, y + 0.86 * h
    wl, wr = x + 0.06 * w, x + 0.94 * w
    # Shadow on the grass.
    out.append(ellipse(x + w / 2, wall_bot + 6 * s, w * 0.56, 16 * s, SHADOW, opacity=0.12))
    # Chimney (behind the roof).
    out += [el('rect', x=x + 0.66 * w, y=y + 0.09 * h, width=0.09 * w, height=0.2 * h, fill='#E8D6C0'),
            el('rect', x=x + 0.645 * w, y=y + 0.08 * h, width=0.12 * w, height=0.035 * h, rx=2 * s, fill='#CDB79D')]
    # Walls with a shaded right side.
    out += [el('rect', x=wl, y=wall_top, width=wr - wl, height=wall_bot - wall_top, fill=WALL),
            el('rect', x=x + 0.8 * w, y=wall_top, width=wr - x - 0.8 * w, height=wall_bot - wall_top, fill=WALL_SHADE),
            el('rect', x=wl, y=wall_bot - 10 * s, width=wr - wl, height=10 * s, fill='#E9DCCB')]
    # Windows with flower boxes, on both sides of the door.
    for cx in (x + 0.19 * w, x + 0.81 * w):
        ww, wh, wy = 0.15 * w, 0.17 * h, y + 0.53 * h
        out += [el('rect', x=cx - ww / 2 - 3 * s, y=wy - 3 * s, width=ww + 6 * s, height=wh + 6 * s, rx=4 * s, fill=WOOD),
                el('rect', x=cx - ww / 2, y=wy, width=ww, height=wh, rx=2.5 * s, fill=GLASS_SKY),
                path('M%s %s v%s M%s %s h%s' % (f(cx), f(wy), f(wh), f(cx - ww / 2), f(wy + wh * 0.45), f(ww)), 'none',
                     stroke=WOOD, stroke_width=3 * s),
                el('rect', x=cx - ww / 2 + 3 * s, y=wy + 3 * s, width=ww * 0.3, height=wh * 0.3, rx=2 * s, fill='#FFFFFF',
                   opacity=0.45),
                el('rect', x=cx - ww / 2 - 5 * s, y=wy + wh + 3 * s, width=ww + 10 * s, height=9 * s, rx=2 * s, fill=WOOD_LIGHT)]
        for k in range(4):
            fx = cx - ww / 2 + (k + 0.5) * (ww / 4)
            out += [el('circle', cx=fx, cy=wy + wh + 2 * s, r=4.2 * s, fill=(CORAL, GOLD, '#F4A7B4', GOLD)[k]),
                    el('circle', cx=fx, cy=wy + wh + 2 * s, r=1.5 * s, fill='#FFFFFF', opacity=0.8)]
    # The door (mostly behind the companion): wood planks under an arch, a gold knob.
    dw, dt = 0.25 * w, y + 0.47 * h
    out += [path('M%s %s L%s %s A%s %s 0 0 1 %s %s L%s %s Z' % (f(door_cx - dw / 2 - 4 * s), f(wall_bot), f(door_cx - dw / 2 - 4 * s),
                                                               f(dt + dw / 2), f(dw / 2 + 4 * s), f(dw / 2 + 4 * s),
                                                               f(door_cx + dw / 2 + 4 * s), f(dt + dw / 2), f(door_cx + dw / 2 + 4 * s),
                                                               f(wall_bot)), TRUNK_RING),
            path('M%s %s L%s %s A%s %s 0 0 1 %s %s L%s %s Z' % (f(door_cx - dw / 2), f(wall_bot), f(door_cx - dw / 2), f(dt + dw / 2),
                                                               f(dw / 2), f(dw / 2), f(door_cx + dw / 2), f(dt + dw / 2),
                                                               f(door_cx + dw / 2), f(wall_bot)), WOOD),
            path('M%s %s V%s M%s %s V%s' % (f(door_cx - dw / 6), f(dt + 6 * s), f(wall_bot), f(door_cx + dw / 6), f(dt + 6 * s),
                                          f(wall_bot)), 'none', stroke=TRUNK_RING, stroke_width=2 * s, opacity=0.6),
            el('circle', cx=door_cx + dw * 0.32, cy=(dt + wall_bot) / 2 + 10 * s, r=3.5 * s, fill=GOLD)]
    # Roof: eaves wider than the walls, the right slope in shade, rows of tiles, the round gable window.
    rl, rr, apex = x - 0.02 * w, x + 1.02 * w, (x + w / 2, y)
    out += [path('M%s %s L%s %s L%s %s Z' % (f(rl), f(roof_base), f(apex[0]), f(apex[1]), f(rr), f(roof_base)), CORAL),
            path('M%s %s L%s %s L%s %s Z' % (f(apex[0]), f(apex[1]), f(rr), f(roof_base), f(apex[0] + 0.06 * w), f(roof_base)),
                 CORAL_DEEP, opacity=0.55)]
    for k in (0.38, 0.62, 0.84):
        yy = y + (roof_base - y) * k
        half = (w * 0.52) * k
        out.append(path('M%s %s L%s %s' % (f(apex[0] - half + 6 * s), f(yy), f(apex[0] + half - 6 * s), f(yy)), 'none',
                        stroke=CORAL_DEEP, stroke_width=2.4 * s, stroke_linecap='round', opacity=0.4))
    out += [el('rect', x=rl - 2 * s, y=roof_base - 3 * s, width=rr - rl + 4 * s, height=8 * s, rx=4 * s, fill=CORAL_DEEP),
            el('circle', cx=apex[0], cy=y + 0.24 * h, r=0.075 * w, fill=WOOD),
            el('circle', cx=apex[0], cy=y + 0.24 * h, r=0.058 * w, fill=GLASS_SKY),
            path('M%s %s h%s M%s %s v%s' % (f(apex[0] - 0.058 * w), f(y + 0.24 * h), f(0.116 * w), f(apex[0]), f(y + 0.24 * h - 0.058 * w),
                                          f(0.116 * w)), 'none', stroke=WOOD, stroke_width=2.4 * s)]
    # The porch: a plank deck in front of the house, wider than the door, two posts' feet, the front face.
    pl, pr, pt, pb = x - 0.02 * w, x + 1.02 * w, wall_bot - 2 * s, y + h - 12 * s
    out += [path('M%s %s L%s %s L%s %s L%s %s Z' % (f(pl + 8 * s), f(pt), f(pr - 8 * s), f(pt), f(pr), f(pb), f(pl), f(pb)), WOOD_LIGHT),
            el('rect', x=pl, y=pb, width=pr - pl, height=10 * s, rx=2 * s, fill=WOOD)]
    n = 7
    for k in range(1, n):
        xt = pl + 8 * s + (pr - pl - 16 * s) * k / n
        xb = pl + (pr - pl) * k / n
        out.append(path('M%s %s L%s %s' % (f(xt), f(pt), f(xb), f(pb)), 'none', stroke=WOOD, stroke_width=1.4 * s, opacity=0.55))
    return out


# ---------------------------------------------------------------- the four boards
# Tap areas from docs/design/nitzi-home.md section 3 (x, y, w, h); the scene draws only what stands behind them. Sparkles and
# gulls keep out of the title's widest box (text scale 1.3) and the back pebble, so none is ever half hidden by them.
BOARDS = {
    'phone': dict(
        file='nitzi_home_phone.svg', W=852, H=393, s=1.0,
        sand=(440, 222, 425, 150), grass=(432, 200, 362, 114),
        house=(330, 64, 250, 270), companion=(380, 160, 160, 160), lighthouse=(32, 88, 128, 248),
        book=(208, 216, 128, 120), bottle=(600, 192, 160, 144),
        palm=(270, 214, 238, 96), wet=(690, 342, 92, 20), stones=((566, 322), (590, 334)),
        flowers=((300, 270, CORAL), (176, 200, GOLD), (600, 150, '#F4A7B4')), bushes=((612, 118, 0.9), (318, 112, 0.7)),
        tufts=((200, 150), (640, 210), (560, 120), (290, 160), (720, 180)), shells=((450, 356, 0.9), (196, 345, 0.8)),
        starfish=((560, 358, 0.9),), sparkles=((40, 30, 7), (836, 92, 6), (810, 260, 6)),
        gulls=((34, 74), (60, 64))),
    'phone_se': dict(
        file='nitzi_home_phone_se.svg', W=667, H=375, s=0.82,
        sand=(342, 214, 335, 146), grass=(336, 193, 286, 112),
        house=(286, 80, 180, 252), companion=(304, 172, 132, 132), lighthouse=(24, 96, 112, 228),
        book=(168, 212, 112, 112), bottle=(468, 188, 136, 136),
        palm=(222, 206, 198, 118), wet=(536, 330, 76, 18), stones=((452, 314), (468, 326)),
        flowers=((262, 270, CORAL), (150, 196, GOLD), (480, 160, '#F4A7B4')), bushes=((496, 124, 0.7),),
        tufts=((168, 150), (520, 210), (440, 120), (590, 220)), shells=((360, 340, 0.8), (160, 334, 0.7)),
        starfish=((440, 344, 0.8),), sparkles=((30, 40, 6), (640, 250, 5)),
        gulls=((24, 74), (48, 64))),
    'tablet_landscape': dict(
        file='nitzi_home_tablet_landscape.svg', W=1180, H=820, s=1.5,
        sand=(610, 470, 590, 300), grass=(600, 425, 500, 212),
        house=(560, 180, 340, 520), companion=(600, 380, 240, 240), lighthouse=(80, 220, 200, 480),
        book=(360, 516, 176, 176), bottle=(900, 480, 200, 200),
        palm=(420, 470, 372, 262), wet=(1000, 700, 140, 30), stones=((860, 660), (896, 684)),
        flowers=((470, 470, CORAL), (330, 390, GOLD), (930, 420, '#F4A7B4'), (1010, 330, CORAL)),
        bushes=((960, 300, 1.2), (500, 290, 1.0)),
        tufts=((350, 330), (520, 600), (1000, 470), (900, 260), (1080, 400), (300, 480)),
        shells=((600, 740, 1.3), (330, 730, 1.1), (760, 760, 1.0)), starfish=((820, 730, 1.3),),
        sparkles=((60, 100, 9), (420, 130, 8), (1110, 170, 9), (1130, 560, 8), (60, 770, 8), (1140, 790, 7)),
        gulls=((130, 130), (166, 116), (1000, 120))),
    'tablet_portrait': dict(
        file='nitzi_home_tablet_portrait.svg', W=820, H=1180, s=1.4,
        sand=(430, 640, 405, 430), grass=(424, 500, 360, 272),
        house=(250, 160, 340, 480), companion=(300, 380, 240, 240), lighthouse=(48, 200, 160, 440),
        book=(150, 780, 176, 176), bottle=(500, 760, 220, 200),
        palm=(706, 690, 734, 440), wet=(610, 1002, 140, 28), stones=((520, 676), (520, 714)),
        flowers=((420, 712, CORAL), (240, 700, GOLD), (650, 300, '#F4A7B4')), rock_foam=False,
        bushes=((660, 600, 1.1), (180, 690, 0.9)),
        tufts=((110, 420), (690, 340), (380, 730), (620, 560), (250, 300), (740, 520)),
        shells=((360, 1000, 1.2), (130, 980, 1.0), (470, 1040, 1.0)), starfish=((400, 1050, 1.2),),
        sparkles=((60, 130, 9), (760, 160, 8), (40, 1100, 8), (780, 1110, 8), (790, 700, 7)),
        gulls=((90, 200), (124, 186))),
}

LH_W, LH_H = 100, 220  # the lighthouse picture's viewBox


def drawn_lighthouse(rect):
    """Where the lighthouse picture lands in its tap area (BoxFit.contain, Alignment.bottomCenter): centre x, width, bottom."""
    x, y, w, h = rect
    k = min(w / LH_W, h / LH_H)
    return x + w / 2, LH_W * k, y + h


def scene(b):
    W, H, s = b['W'], b['H'], b['s']
    parts = waves(W, H, 0, 0)
    for (x, y) in b['gulls']:
        parts.append(gull(x, y))
    for (x, y, r) in b['sparkles']:
        parts.append(sparkle(x, y, r))
    parts += island(b['sand'], b['grass'])
    wx, wy, wrx, wry = b['wet']
    parts += wet_sand(wx, wy, wrx, wry)
    for (x, y) in b['tufts']:
        parts.append(tuft(x, y, s))
    for (x, y, sc) in b['bushes']:
        parts += bush(x, y, sc * s)
    for (x, y, col) in b['flowers']:
        parts += flowers(x, y, s, col)
    for (x, y, sc) in b['shells']:
        parts += shell(x, y, sc * s)
    for (x, y, sc) in b['starfish']:
        parts += starfish(x, y, sc * s)
    parts += stones(b['stones'], s)
    bx, by, tx, ty = b['palm']
    parts += palm(bx, by, tx, ty, s)
    hx, hy, hw, hh = b['house']
    cx, cy, cw, ch = b['companion']
    parts += house(hx, hy, hw, hh, cx + cw / 2)
    lcx, lw, lb = drawn_lighthouse(b['lighthouse'])
    parts += rocks(lcx, lb, lw * 1.05, b.get('rock_foam', True))
    return svg(W, H, 'הָאִי שֶׁל הַיֶּלֶד', parts)


# ---------------------------------------------------------------- the three objects
def lighthouse():
    """100 x 220. Lantern window (where the app may show the trophy): x 35..65, y 36..60."""
    out = []
    # Rocks at the foot.
    out += [ellipse(50, 212, 46, 7, SHADOW, opacity=0.12),
            ellipse(22, 206, 18, 11, ROCK_SHADE), ellipse(80, 207, 17, 10, ROCK_SHADE),
            ellipse(50, 202, 34, 12, ROCK), ellipse(42, 196, 16, 4.5, ROCK_LIGHT)]
    # Tower: narrower at the top, six bands (red, white, red, white, red, white from the top), shade on the right.
    top, bot, tw, bw = 74, 200, 36, 54

    def xl(yy):
        return 50 - (tw + (bw - tw) * (yy - top) / (bot - top)) / 2

    def band(y0, y1, col):
        return path('M%s %s L%s %s L%s %s L%s %s Z' % (f(xl(y0)), f(y0), f(100 - xl(y0)), f(y0), f(100 - xl(y1)), f(y1),
                                                       f(xl(y1)), f(y1)), col)
    step = (bot - top) / 6
    for i in range(6):
        out.append(band(top + i * step, top + (i + 1) * step + (0.4 if i < 5 else 0), CORAL if i % 2 == 0 else WALL))
    out.append(path('M%s %s L%s %s L%s %s L%s %s Z' % (f(62), f(top), f(100 - xl(top)), f(top), f(100 - xl(bot)), f(bot), f(66),
                                                       f(bot)), SHADOW, opacity=0.1))
    # Windows in a line and the door.
    for wy in (100, 146):
        out += [el('rect', x=46, y=wy, width=8, height=12, rx=4, fill=INK), el('rect', x=47.5, y=wy + 2, width=2.5, height=4, rx=1.2,
                                                                                fill='#FFFFFF', opacity=0.5)]
    out += [path('M42 200 L42 182 A8 8 0 0 1 58 182 L58 200 Z', WOOD), path('M44 200 L44 183 A6 6 0 0 1 56 183 L56 200 Z', '#C48A5E'),
            el('circle', cx=54, cy=191, r=1.4, fill=GOLD)]
    # Gallery deck and railing.
    out += [el('rect', x=24, y=66, width=52, height=9, rx=3, fill=INK),
            el('rect', x=26, y=52, width=48, height=3, rx=1.5, fill=INK)]
    for k in range(9):
        x = 27.5 + k * 5.6
        out.append(el('rect', x=x, y=54, width=1.6, height=13, fill=INK))
    # Lantern: base ring, warm glass with a soft glow, frame and two thin bars, the domed cap and its ball.
    out += [el('rect', x=33, y=58, width=34, height=8, rx=2, fill=CORAL_DEEP),
            el('rect', x=35, y=36, width=30, height=24, rx=3, fill='#FFE7A3'),
            ellipse(50, 48, 11, 9, '#FFF6D6'),
            el('rect', x=35, y=36, width=30, height=24, rx=3, fill='none', stroke=INK, stroke_width=2.4),
            path('M45 36.5 V59.5 M55 36.5 V59.5', 'none', stroke=INK, stroke_width=1.2, opacity=0.55),
            path('M30 38 Q30 18 50 14 Q70 18 70 38 Z', CORAL),
            path('M50 14 Q70 18 70 38 L58 38 Q58 22 50 14 Z', CORAL_DEEP, opacity=0.6),
            el('rect', x=28, y=35, width=44, height=4, rx=2, fill=CORAL_DEEP),
            path('M50 14 V6', 'none', stroke=INK, stroke_width=2),
            el('circle', cx=50, cy=6, r=4, fill=GOLD)]
    return svg(LH_W, LH_H, 'מִגְדַּלּוֹר', out, sea=False)


def bottle_big():
    """100 x 100: the bottle lying in wet sand, its neck up towards the end side, a rolled letter with a ribbon inside."""
    out = [ellipse(50, 84, 42, 9, WET_SAND, opacity=0.9),
           ellipse(52, 82, 32, 5, SHADOW, opacity=0.12)]
    body = []
    # Glass: a long rounded body, a shoulder and neck, a lip ring, the cork.
    body += [el('rect', x=10, y=44, width=62, height=34, rx=16, fill='#D3F1EA', opacity=0.95),
             path('M66 48 Q78 50 80 56 L80 66 Q78 72 66 74 Z', '#D3F1EA', opacity=0.95),
             el('rect', x=78, y=54, width=12, height=14, rx=3, fill='#D3F1EA'),
             el('rect', x=88, y=52.5, width=4, height=17, rx=2, fill='#B9E6DC'),
             el('rect', x=91, y=55, width=8, height=12, rx=2.5, fill='#C98B5B'),
             el('rect', x=96, y=55, width=3, height=12, rx=1.5, fill='#A86E44')]
    # The rolled letter inside (no writing), tied with a coral ribbon.
    body += [el('rect', x=20, y=51, width=46, height=20, rx=9, fill='#FFF4D6'),
             ellipse(22, 61, 4.6, 9.5, '#F3E3B8'),
             path('M22 56.5 a3 4.5 0 1 1 0 9', 'none', stroke='#D9C590', stroke_width=1.2),
             el('rect', x=41, y=51, width=5, height=20, fill=CORAL),
             ellipse(38.6, 51, 4.6, 2.8, CORAL, transform='rotate(-20 38.6 51)'),
             ellipse(48.4, 51, 4.6, 2.8, CORAL, transform='rotate(20 48.4 51)'),
             el('circle', cx=43.5, cy=51, r=2, fill=CORAL_DEEP)]
    # The glass edge and highlights on top of everything inside.
    body += [el('rect', x=10, y=44, width=62, height=34, rx=16, fill='none', stroke='#7CC3B6', stroke_width=2.4),
             path('M66 48 Q78 50 80 56 L80 66 Q78 72 66 74', 'none', stroke='#7CC3B6', stroke_width=2.4),
             el('rect', x=78, y=54, width=12, height=14, rx=3, fill='none', stroke='#7CC3B6', stroke_width=2),
             el('rect', x=17, y=47.5, width=17, height=3.6, rx=1.8, fill='#FFFFFF', opacity=0.85),
             el('rect', x=53, y=47.5, width=9, height=3.6, rx=1.8, fill='#FFFFFF', opacity=0.85),
             el('circle', cx=64, cy=49.5, r=1.8, fill='#FFFFFF', opacity=0.85),
             el('rect', x=80, y=56.5, width=7, height=2.4, rx=1.2, fill='#FFFFFF', opacity=0.8)]
    out.append('<g transform="rotate(-24 52 62)">%s</g>' % ''.join(body))
    out += shell(16, 90, 0.9)
    return svg(100, 100, 'בַּקְבּוּק', out, sea=False)


def sticker_book():
    """100 x 100: the album standing on a stump, its spine on the right as a Hebrew book's is, the pages showing on the left.
    The cover panel (where the app lays a sticker) is x 33..63, y 19..49."""
    out = [ellipse(51, 94, 40, 6, SHADOW, opacity=0.12)]
    # The stump: roots, bark in strips, the cut top with rings.
    out += [path('M22 95 Q28 90 28 82 L28 68 L74 68 L74 82 Q74 90 82 95 Z', '#9C6B45'),
            path('M36 70 V93 M48 70 V95 M60 70 V94 M68 70 V90', 'none', stroke='#7E5434', stroke_width=2, stroke_linecap='round',
                 opacity=0.7),
            ellipse(51, 68, 23.5, 6.5, '#E7C796'),
            ellipse(51, 68, 15, 4, 'none', stroke='#C9A06A', stroke_width=1.2),
            ellipse(51, 68, 7, 2, 'none', stroke='#C9A06A', stroke_width=1.2)]
    # The pages' edge on the left, then the cover, then the spine on the right.
    out += [path('M28 10 L22 14 L22 70 L28 67 Z', '#FFF6E8'),
            path('M22 22 L28 19 M22 32 L28 29 M22 42 L28 39 M22 52 L28 49 M22 62 L28 59', 'none', stroke='#E2D6C2',
                 stroke_width=1.2),
            el('rect', x=26, y=8, width=48, height=60, rx=4, fill='#5B8DEF'),
            el('rect', x=68, y=8, width=8, height=60, rx=3, fill='#3F6FD1'),
            path('M68 16 H76 M68 60 H76', 'none', stroke=GOLD, stroke_width=2.2),
            path('M26 12 L26 8 L31 8 Z M26 64 L26 68 L31 68 Z', GOLD),
            el('rect', x=31, y=17, width=34, height=34, rx=6, fill='#2F66C9', opacity=0.35),
            el('rect', x=33, y=19, width=30, height=30, rx=5, fill='#FFF6E8'),
            el('rect', x=28, y=11, width=36, height=3, rx=1.5, fill='#FFFFFF', opacity=0.3)]
    # A ribbon bookmark hanging over the stump.
    out += [path('M58 66 L58 80 L60.5 77 L63 80 L63 66 Z', CORAL)]
    return svg(100, 100, 'אַלְבּוֹם מַדְבֵּקוֹת', out, sea=False)


if __name__ == '__main__':
    for key, b in BOARDS.items():
        write(SCENES, b['file'], scene(b))
        print(key, b['file'])
    write(HOME, 'lighthouse.svg', lighthouse())
    write(HOME, 'bottle_big.svg', bottle_big())
    write(HOME, 'sticker_book.svg', sticker_book())
    print('objects: lighthouse.svg bottle_big.svg sticker_book.svg')
