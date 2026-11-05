"""The nine pre-writing stroke scenes of Hebrew A-14 (docs/languages/hebrew/band-a-content.md, HEB-A-14; LS02 trace mode
with shapes), drawn now that the stroke directions are settled with the letter stroke data (F6, docs/languages/strokes.md).

    python tools/make_stroke_scenes.py           # writes the pictures and the stroke data
    python tools/make_stroke_scenes.py --sheet   # and the contact sheet docs/design/languages/strokes_scenes_a14.png

Each scene is three things:
  * the picture under the trace box (content/languages/pictures/stroke-<scene>.svg, 256 x 256, the box's own square):
    where the path starts and where it leads (a cloud and a flower, a road and a house), with the path's own band kept
    clear and pale, so the app's dotted guide and green start dot read on it;
  * the thing the finger takes along the path (mover-<thing>.svg, 256 x 256, drawn facing left like every side-view
    picture of the set), which the app moves for hint 2 ("the thing on the path moves slowly along it once") and with the
    finger; `orient` says how it turns: none, face (mirrored to face the way the stroke goes from its start to its end),
    tangent (turns with the path,
    seen from above) or tangent-upright (turns with the path and is mirrored rather than turned upside down);
  * the stroke data, in the trace template's 100 x 100 box (content/languages/strokes/prewriting-heb-a14.json), ready for
    `scene.strokes` of the existing `trace` activity.
The door (A-14.9) has no mover: the child draws the door frame, and `stroke-door-done.svg` (the door in its frame) is
shown when the three strokes are done.

Directions (data, not pictures, so the teacher's answer changes one line): down; across from right to left; the arch
from the LEFT foot, up and over to the right (ARCH_FROM; the brief's first guess was from the right, see strokes.md
section 5.3: both school models start the arch letters on the left and draw the top lines left to right); the circle
anticlockwise from the top (CIRCLE, as the brief and the app's numerals 0, 6, 8, 9); the door down, across right to
left, down. A hill, a fence, a pond and a stone look the same from both sides, so a changed direction needs no new
picture; the house and the jetty stand on the left, where the right-to-left road and water lead.

Style and rules: the approved house style of the Languages pictures (docs/art/art-brief.md; tools/make_language_pictures.py
and make_language_scenes.py, whose drawings are reused: the car, the boat, the rabbit, the ball and the fish are the
objects of the word items). No text, no letters or numerals. References looked at on 2026-11-04 for the new drawings:
  - Seven-spot ladybird (Coccinella septempunctata), Wikipedia and Wikimedia Commons photographs from above: a red domed
    shell split down the middle, seven black spots (three on each side and one across the split, near the head), a black
    head with two white patches, six short black legs. Drawn from above as a simple oval with that pattern.
  - Raindrop: the familiar teardrop shape (a falling drop is really round; the teardrop is the picture-book convention
    children know), light blue with a white highlight.
  - Wooden jetty and picket fence: Wikimedia Commons searches "wooden jetty lake" (planks on posts standing in the water)
    and "white picket fence" (pointed pickets on two rails).
  - Flowers: a tulip (Commons "Tulipa red", a cup of petals on a long stem with two long leaves) and a daisy-like flower
    (Commons "Bellis perennis", white petals round a yellow middle) for the two rain scenes.
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_language_pictures as m  # noqa: E402
import make_language_scenes as sc  # noqa: E402
import make_letter_strokes as ls  # noqa: E402

ROOT, OUT = m.ROOT, m.OUT
INK, WHITE = m.INK, m.WHITE
DATA = os.path.join(ROOT, 'content', 'languages', 'strokes', 'prewriting-heb-a14.json')
SHEET = os.path.join(ROOT, 'docs', 'design', 'languages', 'strokes_scenes_a14.png')
K = 2.56                      # box units to picture pixels
f = sc.f

ARCH_FROM = 'left'            # 'left' (proposed, from the school models) or 'right' (the brief's first guess)
CIRCLE = 'ccw'                # 'ccw' from the top (the brief) or 'cw'

SKY, GRASS, GRASS_D, WATER, WATER_D = '#DFF1FB', '#B5DFA0', '#8CC77A', '#8FD3F4', '#5BB8E0'


def svg(parts):
    body = ''.join(parts)
    text = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">'
            '<clipPath id="page"><rect x="0" y="0" width="256" height="256" rx="16"/></clipPath>'
            '<g clip-path="url(#page)" stroke-linejoin="round" stroke-linecap="round">%s</g></svg>\n' % body)
    return sc.compact(text)


def P(d, fill, sw=4, stroke=INK, op=None):
    o = ' opacity="%s"' % op if op is not None else ''
    s = ' stroke="%s" stroke-width="%s"' % (stroke, sw) if sw else ''
    return '<path d="%s" fill="%s"%s%s/>' % (d, fill, s, o)


def L(d, col=INK, w=4, op=None):
    return P(d, 'none', w, col, op)


def E(cx, cy, rx, ry, fill, sw=4, stroke=INK, op=None):
    return P(m.ell(cx, cy, rx, ry), fill, sw, stroke, op)


# ---------------------------------------------------------------------------------------------------- backgrounds
def sky_ground(ground_y=212, col=GRASS):
    return ['<rect x="0" y="0" width="256" height="256" fill="%s"/>' % SKY,
            '<path d="M 0 %d C 70 %d, 186 %d, 256 %d L 256 256 L 0 256 Z" fill="%s"/>' % (ground_y, ground_y - 6, ground_y - 6, ground_y, col),
            '<path d="M 0 %d C 70 %d, 186 %d, 256 %d" fill="none" stroke="%s" stroke-width="3"/>' % (ground_y, ground_y - 6, ground_y - 6, ground_y, GRASS_D)]


def cloud(cx, cy, s=1.0, col=WHITE):
    d = ('M {a} {b} C {c} {b}, {c} {d}, {e} {d} C {e2} {f}, {g} {f}, {h} {d2} C {i} {j}, {k} {l}, {m2} {b} Z').format(
        a=f(cx - 52 * s), b=f(cy + 16 * s), c=f(cx - 70 * s), d=f(cy - 6 * s), e=f(cx - 40 * s), e2=f(cx - 34 * s), f=f(cy - 40 * s),
        g=f(cx + 6 * s), h=f(cx + 14 * s), d2=f(cy - 22 * s), i=f(cx + 40 * s), j=f(cy - 34 * s), k=f(cx + 74 * s), l=f(cy - 6 * s),
        m2=f(cx + 52 * s))
    return [P(d, col, 4), L('M %s %s Q %s %s %s %s' % (f(cx - 40 * s), f(cy - 18 * s), f(cx - 30 * s), f(cy - 30 * s), f(cx - 16 * s), f(cy - 30 * s)), WHITE, 5, 0.9),
            '<path d="M %s %s L %s %s" stroke="#D8E8F4" stroke-width="5" opacity="0.8"/>' % (f(cx - 44 * s), f(cy + 9 * s), f(cx + 44 * s), f(cy + 9 * s))]


def tulip(cx, top, col='#E53935', shade='#B71C1C', ground=226):
    out = [L('M %s %s C %s %s, %s %s, %s %s' % (f(cx), f(ground), f(cx - 2), f(top + 60), f(cx + 2), f(top + 40), f(cx), f(top + 26)), '#4C9A2A', 6),
           P('M %s %s C %s %s, %s %s, %s %s C %s %s, %s %s, %s %s Z' % (f(cx), f(ground - 4), f(cx - 30), f(ground - 20), f(cx - 34), f(ground - 46),
                                                                    f(cx - 26), f(ground - 60), f(cx - 14), f(ground - 40), f(cx - 8), f(ground - 20), f(cx), f(ground - 4)), '#6DBB4A', 3),
           P('M %s %s C %s %s, %s %s, %s %s C %s %s, %s %s, %s %s Z' % (f(cx), f(ground - 8), f(cx + 24), f(ground - 26), f(cx + 30), f(ground - 50),
                                                                    f(cx + 24), f(ground - 62), f(cx + 12), f(ground - 40), f(cx + 6), f(ground - 22), f(cx), f(ground - 8)), '#6DBB4A', 3)]
    cup = ('M %s %s C %s %s, %s %s, %s %s L %s %s L %s %s L %s %s L %s %s L %s %s C %s %s, %s %s, %s %s Z'
           % (f(cx - 24), f(top + 4), f(cx - 26), f(top + 24), f(cx - 16), f(top + 34), f(cx), f(top + 34), f(cx + 16), f(top + 34),
              f(cx + 26), f(top + 24), f(cx + 24), f(top + 4), f(cx + 12), f(top + 14), f(cx), f(top), f(cx - 12), f(top + 14),
              f(cx - 24), f(top + 4), f(cx - 24), f(top + 4)))
    out += [P(cup, col, 4), L('M %s %s L %s %s' % (f(cx), f(top + 6), f(cx), f(top + 30)), shade, 3, 0.7),
            L('M %s %s Q %s %s %s %s' % (f(cx - 18), f(top + 12), f(cx - 19), f(top + 22), f(cx - 12), f(top + 28)), WHITE, 4, 0.55)]
    return out


def daisy(cx, cy, ground=226):
    out = [L('M %s %s C %s %s, %s %s, %s %s' % (f(cx), f(ground), f(cx + 4), f(cy + 30), f(cx - 4), f(cy + 20), f(cx), f(cy)), '#4C9A2A', 6),
           P('M %s %s C %s %s, %s %s, %s %s C %s %s, %s %s, %s %s Z' % (f(cx), f(ground - 6), f(cx - 28), f(ground - 16), f(cx - 32), f(ground - 34),
                                                                    f(cx - 24), f(ground - 40), f(cx - 12), f(ground - 26), f(cx - 6), f(ground - 16), f(cx), f(ground - 6)), '#6DBB4A', 3)]
    for k in range(12):
        a = math.radians(k * 30)
        x, y = cx + 15 * math.cos(a), cy + 15 * math.sin(a)
        out.append('<g transform="translate(%s %s) rotate(%s)">%s</g>' % (f(x), f(y), f(k * 30), P(m.ell(0, 0, 11, 6), WHITE, 3)))
    out += [E(cx, cy, 11, 11, '#FFC83D', 3.5), E(cx - 3, cy - 3, 3.5, 3, WHITE, 0, op=0.7)]
    return out


def house_left(x0, base):
    """A small house on the left edge, its door facing the road (the right)."""
    w, h = 64, 70
    out = [P(m.rrect(x0, base - h, w, h, 4), '#FFE3B3', 4),
           P('M %s %s L %s %s L %s %s Z' % (f(x0 - 10), f(base - h + 2), f(x0 + w / 2), f(base - h - 40), f(x0 + w + 10), f(base - h + 2)), '#E8742A', 4),
           P(m.rrect(x0 + 34, base - 40, 20, 40, 3), '#9A6B3C', 3.5), E(x0 + 49, base - 20, 2.5, 2.5, '#FFC83D', 2),
           P(m.rrect(x0 + 8, base - 56, 18, 18, 3), '#BFE6F7', 3.5), L('M %s %s L %s %s' % (f(x0 + 17), f(base - 56), f(x0 + 17), f(base - 38)), INK, 2.5),
           L('M %s %s L %s %s' % (f(x0 - 2), f(base - h - 12), f(x0 + 20), f(base - h - 30)), WHITE, 5, 0.5)]
    return out


def road_scene():
    out = sky_ground(150)
    out += ['<path d="M 0 166 L 256 166 L 256 206 L 0 206 Z" fill="#C9C4D6"/>',
            L('M 0 166 L 256 166 M 0 206 L 256 206', '#A39DB5', 3)]
    out += ['<path d="M %d 186 L %d 186" stroke="%s" stroke-width="4" opacity="0.8"/>' % (x, x + 16, WHITE) for x in (96, 140, 184, 228)]
    out += house_left(4, 166)
    out += [E(214, 110, 22, 20, '#6DBB4A', 4), L('M 214 128 L 214 150', '#8A5A2B', 6)]
    out += [P('M 30 236 q 8 -10 16 0 M 200 240 q 8 -10 16 0', 'none', 3, GRASS_D)]
    return out


def jetty_scene():
    out = ['<rect x="0" y="0" width="256" height="256" fill="%s"/>' % SKY,
           '<path d="M 0 150 L 256 150 L 256 256 L 0 256 Z" fill="%s"/>' % WATER,
           L('M 0 150 L 256 150', WATER_D, 3)]
    out += [L('M %d %d q 10 -6 20 0 q 10 6 20 0' % (x, y), WHITE, 3, 0.8) for x, y in ((120, 214), (176, 232), (60, 236), (196, 196))]
    for x in (10, 34, 58):
        out.append(P(m.rrect(x, 150, 9, 52, 2), '#8A5A2B', 3))
    out.append(P(m.rrect(0, 138, 74, 14, 3), '#C98F52', 4))
    out += [L('M %d 140 L %d 150' % (x, x), '#8A5A2B', 2.5) for x in (18, 36, 54)]
    out += [E(70, 128, 7, 7, '#E8742A', 3), L('M 70 135 L 70 138', INK, 3)]
    out += cloud(196, 52, 0.6) + cloud(60, 40, 0.45)
    return out


def hill_scene():
    out = sky_ground(212)
    hill = 'M 40 214 C 52 150, 92 118, 128 118 C 164 118, 204 150, 216 214 Z'
    out += [P(hill, '#9ED48A', 4), P('M 70 170 q 6 -8 12 0 M 150 150 q 6 -8 12 0 M 120 190 q 6 -8 12 0', 'none', 3, GRASS_D),
            L('M 76 150 C 92 132, 108 126, 122 124', WHITE, 6, 0.4)]
    out += [E(30, 236, 8, 6, '#FFC83D', 3), E(226, 238, 8, 6, '#F28AA0', 3)]
    out += cloud(206, 40, 0.42)
    return out


def fence_scene():
    out = sky_ground(212)
    pickets = []
    for x in range(98, 166, 14):
        pickets.append(P('M %d 214 L %d 152 L %d 140 L %d 152 L %d 214 Z' % (x, x, x + 5, x + 10, x + 10), WHITE, 3.5))
    out += [P(m.rrect(90, 164, 82, 9, 3), '#F4EEFB', 3.5), P(m.rrect(90, 192, 82, 9, 3), '#F4EEFB', 3.5)] + pickets
    out += [E(40, 236, 8, 6, '#FFC83D', 3), E(220, 236, 8, 6, '#FFC83D', 3)]
    out += cloud(56, 44, 0.42)
    return out


def pond_scene():
    out = ['<rect x="0" y="0" width="256" height="256" fill="%s"/>' % GRASS]
    out += [P('M %d %d q 6 -8 12 0' % (x, y), 'none', 3, GRASS_D) for x, y in ((24, 30), (220, 40), (30, 228), (214, 232), (128, 244))]
    out += [E(128, 134, 56, 52, WATER, 4), E(128, 134, 56, 52, 'none', 3, WATER_D),
            P('M 104 122 C 100 108, 118 100, 128 110 L 118 124 Z', '#6DBB4A', 3), E(150, 150, 12, 8, '#6DBB4A', 3),
            L('M 96 152 q 10 -6 20 0 M 136 118 q 10 -6 20 0', WHITE, 3, 0.8)]
    out += [E(232, 120, 9, 7, '#F28AA0', 3), E(22, 140, 9, 7, '#FFC83D', 3)]
    return out


def stone_scene():
    out = ['<rect x="0" y="0" width="256" height="256" fill="%s"/>' % WATER]
    out += [L('M %d %d q 10 -6 20 0 q 10 6 20 0' % (x, y), WHITE, 3, 0.75) for x, y in ((16, 24), (196, 30), (14, 232), (200, 236))]
    out += [E(28, 128, 7, 5, '#C9C4D6', 3), E(230, 110, 6, 4, '#C9C4D6', 3), E(220, 150, 5, 4, '#B8B0D0', 3)]
    stone = 'M 92 140 C 88 112, 110 96, 132 98 C 158 100, 172 118, 168 140 C 166 162, 146 172, 126 170 C 104 168, 94 158, 92 140 Z'
    out += [P(stone, '#A39DB5', 4), P('M 104 122 C 112 108, 130 104, 146 108', 'none', 5, WHITE, 0.45),
            P('M 112 154 C 126 160, 146 158, 158 146', 'none', 3, '#7E7896', 0.7), E(124, 92, 10, 4, '#6DBB4A', 3)]
    return out


def door_scene(done=False):
    out = ['<rect x="0" y="0" width="256" height="256" fill="#FFE3B3"/>',
           P('M -10 40 L 128 -6 L 266 40 L 266 52 L -10 52 Z', '#E8742A', 4)]
    for y in range(76, 214, 28):
        out.append(L('M 0 %d L 66 %d M 190 %d L 256 %d' % (y, y, y, y), '#F2CF94', 3))
    out += [P(m.rrect(60, 216, 136, 14, 3), '#C9C4D6', 4), '<rect x="0" y="230" width="256" height="26" fill="%s"/>' % GRASS,
            L('M 0 230 L 256 230', GRASS_D, 3)]
    for x in (22, 234):
        out += [P('M %d 230 L %d 198 L %d 198 L %d 230 Z' % (x - 14, x - 18, x + 18, x + 14), '#C98F52', 3.5),
                E(x, 184, 18, 16, '#6DBB4A', 3.5), E(x - 6, 178, 4, 4, '#F28AA0', 2.5), E(x + 7, 186, 4, 4, '#FFC83D', 2.5)]
    if done:
        out += [P(m.rrect(80, 80, 96, 136, 6), '#C98F52', 5), P(m.rrect(94, 96, 68, 46, 4), '#B07A44', 3),
                P(m.rrect(94, 154, 68, 46, 4), '#B07A44', 3), E(150, 152, 6, 6, '#FFC83D', 3),
                L('M 88 90 L 88 200', WHITE, 4, 0.35)]
    return out


# ---------------------------------------------------------------------------------------------------- movers
def raindrop():
    return ['<g transform="translate(128 128)">'
            + P('M 0 -78 C 18 -46, 52 -8, 52 26 C 52 58, 28 78, 0 78 C -28 78, -52 58, -52 26 C -52 -8, -18 -46, 0 -78 Z', '#5BB8E0', 6)
            + P('M -26 16 C -26 -6, -14 -26, -4 -40', 'none', 10, WHITE, 0.6) + '</g>']


def ladybird():
    """Seen from above, head up (the app turns it with the path)."""
    out = ['<g transform="translate(128 134)">']
    for side in (-1, 1):
        for y in (-26, 6, 36):
            out.append(L('M %d %d L %d %d' % (side * 44, y, side * 70, y + side * 0 - 10), INK, 7))
    out += [E(0, -56, 30, 24, '#2B2350', 0), E(-12, -62, 7, 6, WHITE, 0), E(12, -62, 7, 6, WHITE, 0),
            E(0, 8, 56, 66, '#E53935', 6), L('M 0 -54 L 0 74', INK, 5)]
    for x, y, r in ((-28, -16, 11), (28, -16, 11), (-34, 28, 12), (34, 28, 12), (-16, 54, 9), (16, 54, 9), (0, -40, 10)):
        out.append(E(x, y, r, r, INK, 0))
    out += [P('M -40 -20 C -36 -40, -22 -52, -8 -54', 'none', 8, WHITE, 0.5), '</g>']
    return out


def from_pic(pic, drop=()):
    parts = [q for q in pic.parts if not any(d in q for d in drop) and not ('opacity="0.12"' in q and q.startswith('<ellipse'))]
    return parts


MOVERS = {
    'raindrop': (raindrop, 'none'),
    'car': (lambda: from_pic(m.car()), 'face'),
    'boat': (lambda: from_pic(m.boat('red'), drop=('#8FD3F4', '#3FB6D9', 'M 40 222 L 70 222')), 'face'),
    'rabbit': (lambda: from_pic(m.rabbit()), 'face'),
    'ladybird': (ladybird, 'tangent'),
    'ball': (lambda: from_pic(m.ball('red'), drop=('opacity="0.22"',)), 'none'),
    'fish': (lambda: from_pic(m.fish()), 'tangent-upright'),
}


# ---------------------------------------------------------------------------------------------------- the nine items
def arch(apex):
    a, b = (16, 84) if ARCH_FROM == 'left' else (84, 16)
    return 'M %d 76 C %d 46 %d %d 50 %d C %d %d %d 46 %d 76' % (a, a, 50 - (50 - a) * 0.6, apex, apex, 50 + (b - 50) * 0.6, apex, b, b)


def circle():
    # box units, y down: angle -90 is the top; going to -180 (the left) first is anticlockwise on the screen
    return 'A 50 52 30 30 -90 -450' if CIRCLE == 'ccw' else 'A 50 52 30 30 -90 270'


def box_path(d):
    return ls.parse(d)


ITEMS = [
    # id, picture, mover, guide, [strokes as box paths]
    ('A-14.1', 'stroke-rain-tulip', 'raindrop', 'full', ['M 50 24 L 50 70']),
    ('A-14.2', 'stroke-road-house', 'car', 'full', ['M 86 72 L 26 72']),
    ('A-14.3', 'stroke-hill', 'rabbit', 'full', [arch(30)]),
    ('A-14.4', 'stroke-pond', 'ladybird', 'full', [circle()]),
    ('A-14.5', 'stroke-rain-daisy', 'raindrop', 'start', ['M 50 24 L 50 70']),
    ('A-14.6', 'stroke-jetty', 'boat', 'start', ['M 86 63 L 30 63']),
    ('A-14.7', 'stroke-fence', 'ball', 'start', [arch(30)]),
    ('A-14.8', 'stroke-stone', 'fish', 'start', [circle()]),
    ('A-14.9', 'stroke-door', None, 'start', ['M 69 31 L 69 82', 'M 69 31 L 31 31', 'M 31 31 L 31 82']),
]


def backgrounds():
    return {
        'stroke-rain-tulip': svg(sky_ground(228) + cloud(128, 38, 0.72) + tulip(128, 186, ground=232)),
        'stroke-rain-daisy': svg(sky_ground(228, '#C6E6A8') + cloud(128, 38, 0.72, '#F4F8FC') + daisy(128, 202, ground=232)),
        'stroke-road-house': svg(road_scene()),
        'stroke-hill': svg(hill_scene()),
        'stroke-pond': svg(pond_scene()),
        'stroke-jetty': svg(jetty_scene()),
        'stroke-fence': svg(fence_scene()),
        'stroke-stone': svg(stone_scene()),
        'stroke-door': svg(door_scene()),
        'stroke-door-done': svg(door_scene(True)),
    }


def stroke_entry(d):
    segs = box_path(d)
    pts = ls.dense(segs)
    pts = [(x, y) for x, y in pts]
    st = {'kind': 'line', 'd': ' '.join(ls._fmt(g) for g in ls._join(segs)), 'points': ls.polyline(pts)}
    st['start'], st['end'] = st['points'][0], st['points'][-1]
    st['moves'] = ls.moves(segs)
    return st, pts


def check(items):
    out = []
    for it in items:
        for i, (st, pts) in enumerate(it['_strokes']):
            if any(not (ls.EDGE <= x <= 100 - ls.EDGE and ls.EDGE <= y <= 100 - ls.EDGE) for x, y in pts):
                out.append('%s stroke %d leaves the box' % (it['id'], i + 1))
            if ls.length(pts) < ls.MIN_TRACE:
                out.append('%s stroke %d is too short to trace' % (it['id'], i + 1))
            if len(st['points']) > ls.MAX_POINTS:
                out.append('%s stroke %d has too many points' % (it['id'], i + 1))
            if ls.self_crossings(pts):
                out.append('%s stroke %d crosses itself' % (it['id'], i + 1))
    return out


def build_items():
    items = []
    for iid, pic, mover, guide, paths in ITEMS:
        strokes = [stroke_entry(d) for d in paths]
        it = {'id': iid, 'skill': 'HEB-A-14', 'picture': pic, 'mover': 'mover-' + mover if mover else None,
              'orient': MOVERS[mover][1] if mover else None, 'guide': guide,
              'strokes': [s for s, _ in strokes], 'scenePoints': [s['points'] for s, _ in strokes]}
        if iid == 'A-14.9':
            it['done'] = 'stroke-door-done'
        it['_strokes'] = strokes
        items.append(it)
    return items


def sheet(items, pics):
    import pathlib
    cells = []
    for it in items:
        for size in (200, 122):
            dots = []
            for i, (st, pts) in enumerate(it['_strokes']):
                for q in ls.resample(pts, 5.0):
                    dots.append('<circle cx="%.1f" cy="%.1f" r="2.3" fill="#2B2350" opacity="0.4"/>' % q)
                x, y = st['start']
                dots.append('<circle cx="%s" cy="%s" r="4.5" fill="#5CC98A"/>' % (x, y))
                if len(it['_strokes']) > 1:
                    dots.append('<text x="%s" y="%s" font-family="Arial" font-weight="700" font-size="5" fill="#FFFFFF" text-anchor="middle">%d</text>' % (x, y + 1.8, i + 1))
                dots.append(ls._arrow(pts, '#2B2350'))
            mover = ''
            if it['mover']:
                st, pts = it['_strokes'][0]
                for frac in ((0.0, 0.5, 1.0) if size == 200 else (0.0,)):
                    q = ls.resample(pts, 0.5)
                    idx = min(len(q) - 1, int(frac * (len(q) - 1)))
                    a, b = q[max(0, idx - 2)], q[min(len(q) - 1, idx + 2)]
                    ang = math.degrees(math.atan2(b[1] - a[1], b[0] - a[0]))
                    tr = 'translate(%.1f %.1f)' % q[idx]
                    o = it['orient']
                    if o == 'face' and st['end'][0] > st['start'][0]:
                        tr += ' scale(-1 1)'
                    elif o == 'tangent':
                        tr += ' rotate(%.1f)' % (ang + 90)
                    elif o == 'tangent-upright':
                        tr += ' rotate(%.1f)' % (ang + 180) if abs(ang) > 90 else ' rotate(%.1f) scale(-1 1)' % ang
                    op = 1.0 if frac == 0 else 0.45
                    mover += ('<g transform="%s" opacity="%s"><image href="%s" x="-11" y="-11" width="22" height="22"/></g>'
                              % (tr, op, (pathlib.Path(OUT) / (it['mover'] + '.svg')).as_uri()))
            cells.append('<div class="c"><svg viewBox="0 0 100 100" width="%d" height="%d"><image href="%s" x="0" y="0" width="100" height="100"/>%s%s</svg>'
                         '<span>%s %s</span></div>' % (size, size, (pathlib.Path(OUT) / (it['picture'] + '.svg')).as_uri(), ''.join(dots), mover,
                                                       it['id'], '' if size == 200 else '(phone size)'))
    extra = ''.join('<div class="c"><img src="%s" width="122" height="122"><span>%s</span></div>' % ((pathlib.Path(OUT) / (n + '.svg')).as_uri(), n)
                    for n in ['stroke-door-done'] + ['mover-' + k for k in MOVERS])
    html = ('<html><body style="margin:0;padding:12px;background:#FFF6E8;width:1520px;font:13px Arial;color:#2B2350">'
            '<style>.c{display:inline-block;margin:6px;text-align:center;vertical-align:bottom}.c svg,.c img{display:block;border-radius:10px;background:#fff}</style>'
            '<h3 style="margin:4px 6px">HEB-A-14 stroke scenes: picture, dotted guide, green start dot, the mover at the start (and faint at the middle and end)</h3>'
            '%s<div>%s</div></body></html>' % (''.join(cells), extra))
    tmp = SHEET + '.html'
    with open(tmp, 'w', encoding='utf-8') as fh:
        fh.write(html)
    import subprocess
    subprocess.run([ls.CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
                    '--allow-file-access-from-files', '--virtual-time-budget=4000', '--screenshot=' + SHEET, '--window-size=1544,1100',
                    pathlib.Path(tmp).as_uri()], check=True, capture_output=True)
    os.remove(tmp)


def main():
    pics = backgrounds()
    for name, (draw, _) in MOVERS.items():
        pics['mover-' + name] = svg(draw()).replace('<clipPath id="page"><rect x="0" y="0" width="256" height="256" rx="16"/></clipPath>', '').replace(' clip-path="url(#page)"', '')
    for name, text in pics.items():
        assert len(text.encode('utf-8')) < 40000, name
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(text)
    items = build_items()
    problems = check(items)
    doc = {'schema': 'nitznutz.strokes.scenes/1', 'skill': 'HEB-A-14', 'review': 'needs-teacher', 'reviewer': 'hebrew-language-teacher',
           'box': 100, 'directions': {'down': 'top to bottom', 'across': 'right to left', 'arch': 'from the %s foot, up and over' % ARCH_FROM,
                                     'circle': ('anticlockwise' if CIRCLE == 'ccw' else 'clockwise') + ' from the top', 'door': 'down, across right to left, down'},
           'orient': {'none': 'never turns', 'face': 'mirrored to face the way the stroke goes, start to end (drawn facing left)',
                      'tangent': 'turns with the path (seen from above, drawn head up)',
                      'tangent-upright': 'turns with the path; mirrored instead of upside down (drawn facing left)'},
           'generator': 'tools/make_stroke_scenes.py',
           'items': [{k: v for k, v in it.items() if not k.startswith('_')} for it in items]}
    text = json.dumps(doc, ensure_ascii=False, indent=1)
    import re
    text = re.sub(r'\[\s+(-?\d+),\s+(-?\d+)\s+\]', r'[\1, \2]', text)
    text = re.sub(r'\[\s+((?:\[\d+, \d+\],?\s*)+)\]', lambda mm: '[' + re.sub(r',\s+', ', ', mm.group(1).strip()) + ']', text)
    with open(DATA, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(text + '\n')
    print('wrote %d pictures and %d items (%s)' % (len(pics), len(items), os.path.relpath(DATA, ROOT)))
    if '--sheet' in sys.argv:
        sheet(items, pics)
        print('sheet', os.path.relpath(SHEET, ROOT))
    for p in problems:
        print('CHECK', p)
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
