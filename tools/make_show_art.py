"""The Show's hand: the art a host uses to demonstrate on the stage in a Show or a Together lead-in (M11 Stage 2, the Shape
Forest pilot; spec: docs/design/m11-rooms.md section 13). Writes

    app/assets/art/hosts/kubi_hand.svg        Kubi's pointer: his front leg reaching up into the stage, three blunt nails,
                                              the tip (the touch point) at (32, 3) of its 64 x 300 box;
                                              the leg fades out over its last 90 units
    app/assets/art/show/ant_a.svg, ant_b.svg  the ant that walks round an outline (two steps of its legs), seen from above,
                                              heading up; the app turns it along the path. 64 x 64, centre (32, 34)
    app/assets/art/show/turn_back.svg,        the "turn it round" orbit arrow of a solid, in two layers: the back half goes
                        turn_front.svg        under the solid, the front half (with the arrow head) over it. 120 x 44
    app/assets/art/show/rotate_cw.svg,        the "turn the piece" arrow of the shape builder, clockwise and counterclockwise
                        rotate_ccw.svg        (two files: the app never mirrors one into the other). 64 x 64
    app/assets/art/show/sand_tray.svg         the tray of sand the solids are pressed into (seen from above). 200 x 120
    app/assets/art/show/sand_print_<circle|rect|square|triangle>.svg   the print a face leaves in the sand, 100 x 100
    app/assets/art/show/outlines.json         the sides of every picture a Show traces, counts, walks or lays sticks on, in the
                                              picture's own 100 x 100 units, from the same geometry as the pictures

    python tools/make_show_art.py            # writes the files
    python tools/make_show_art.py --check    # fails if a written file differs (for CI, later)

Colour: the Show's marks are the host's, not a hint's and not a success: a white core with an edge in the room's deep
colour. The files carry Shape Forest's deep (#1E7F4C, color.domain.shapes.deep) as the edge; another room maps that one
value to its own deep when it draws them (the same colour mapping as Goni's skins). Hints stay sky, success stays gold.

Style: the house style of tools/make_logic_sprites.py (ink #2B2350 outline, one shade tone, one white highlight), no text,
no numerals (the count badges' numerals are drawn by the app in Heebo, left to right).

References looked at on 2026-11-15 (facts and photographs; every drawing is our own, nothing traced):
  Ant: https://en.wikipedia.org/wiki/Ant (head with elbowed antennae, the mesosoma that carries all six legs, a narrow
    node-like petiole, the large gaster) and a Bing image search "ant top view dorsal photo" (seen from above: a round
    head, the antennae bent forward at the elbow, a slim thorax, a small waist bead, an oval gaster; the front legs
    reach forward, the middle ones out to the side, the hind ones back). Drawn as a friendly red-brown ant with two dot
    eyes, the way it is drawn for small children; a walking ant moves three legs at a time (front and back of one side,
    the middle of the other), which the two frames alternate.
  Kubi's leg: his own show pose (design/assets/kubi-show.svg: the leg colour #BFD38A, the scale dots #9FB86C, the three
    cream nails #F3DDB8) and the references of that pose (tortoise forelimbs: scaled, columnar, blunt nails).
  Sand prints: photographs of children's sand play and of shapes pressed into wet sand (Bing "shape imprint in sand"):
    a print is a sunk copy of the face, darker, with its shadow on the edge nearest the light and a bright lip on the far
    edge.
"""
import json
import math
import os
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_logic_sprites as S   # noqa: E402  (the pictures' own geometry)

SHOW = os.path.join(ROOT, 'app', 'assets', 'art', 'show')
HOSTS = os.path.join(ROOT, 'app', 'assets', 'art', 'hosts')
INK, WHITE = S.INK, S.WHITE
DEEP = '#1E7F4C'   # the room's deep (Shape Forest); other rooms map this one value


def svg(w, h, body):
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %g %g" width="%g" height="%g">%s</svg>\n' % (w, h, w, h, body)


# ---- Kubi's pointer --------------------------------------------------------------------------------------------------------

def kubi_hand():
    """His front leg from below: a columnar, scaled leg in his own green that widens toward the body (as a tortoise's
    forelimb does), a soft fold at the wrist, a broad round foot and three blunt cream nails pointing up; the middle
    nail's tip is the touch point (32, 3). An edge in his shell's dark green (#6E9E7E) keeps it clear of the stage's grass
    and sky (the cast's stills have no outline; this is a tool on the stage, as the B-40 hand is)."""
    leg, scale, nail, edge = '#BFD38A', '#9FB86C', '#F3DDB8', '#6E9E7E'
    limb = 'M20 36 C18 70 15 130 14 300 H50 C49 130 46 70 44 36 Z'
    b = ['<defs><linearGradient id="f" x1="0" y1="0" x2="0" y2="300" gradientUnits="userSpaceOnUse">'
         '<stop offset="0.7" stop-color="#FFFFFF" stop-opacity="1"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>'
         '</linearGradient><mask id="m"><rect width="64" height="300" fill="url(#f)"/></mask>'
         '<clipPath id="k"><path d="%s"/></clipPath></defs><g mask="url(#m)">' % limb,
         '<path d="%s" fill="%s"/>' % (limb, leg),
         '<g clip-path="url(#k)"><path d="M37 36 C40 80 43 140 44 300 H60 V30 Z" fill="%s" opacity="0.6"/>' % scale]
    for row, y in enumerate(range(62, 300, 16)):                 # scales: staggered rounded plates, wider lower down
        w = 20 + min(y - 60, 140) * 0.1
        xs = (32 - w / 2 + 4, 32 + w / 2 - 4) if row % 2 else (32 - w / 4, 32 + w / 4)
        for x in xs:
            b.append('<path d="M%.1f %.1f q4.5 -5 9 0 q-4.5 4 -9 0 Z" fill="%s" opacity="0.9"/>' % (x - 4.5, y, scale))
    b.append('</g><path d="%s" fill="none" stroke="%s" stroke-width="3" stroke-linejoin="round"/></g>' % (limb, edge))
    b.append('<path d="M21 50 Q32 56 43 50 M21.5 56 Q32 61 42.5 56" fill="none" stroke="%s" stroke-width="2" '
             'stroke-linecap="round" opacity="0.8"/>' % scale)                       # the folds at the wrist
    b.append('<path d="M11 32 C11 18 20 13 32 13 C44 13 53 18 53 32 C53 42 44 46 32 46 C20 46 11 42 11 32 Z" fill="%s" '
             'stroke="%s" stroke-width="3"/>' % (leg, edge))                     # the broad foot
    b.append('<path d="M14 36 C20 44 44 44 50 36 C46 41 18 41 14 36 Z" fill="%s" opacity="0.8"/>' % scale)
    for cx, cy, rot in ((19, 15.5, -28), (32, 9.5, 0), (45, 15.5, 28)):   # three blunt nails, the middle one the tip
        b.append('<path d="M%.1f %.1f C%.1f %.1f %.1f %.1f %.1f %.1f C%.1f %.1f %.1f %.1f %.1f %.1f Z" '
                 'transform="rotate(%s %s %s)" fill="%s" stroke="#C9A878" stroke-width="2"/>'
                 % (cx - 5, cy + 5, cx - 5, cy - 3, cx - 3, cy - 6.5, cx, cy - 6.5, cx + 3, cy - 6.5, cx + 5, cy - 3,
                    cx + 5, cy + 5, rot, cx, cy, nail))
    b.append('<path d="M19 28 Q22 20 31 19" fill="none" stroke="#FFFFFF" stroke-width="2.6" stroke-linecap="round" opacity="0.6"/>')
    return svg(64, 300, ''.join(b))


# ---- the ant ---------------------------------------------------------------------------------------------------------------

ANT_BODY, ANT_SHADE = '#B5532F', '#8E3B1F'


def ant(step):
    """Seen from above, heading up, centred on (32, 34). step 0 or 1: which three legs reach forward (a tripod walk:
    the front and hind legs of one side with the middle leg of the other)."""
    b = []
    legs = []
    for side in (-1, 1):
        for k, (kx, ky, fx, fy) in enumerate(((8, -5, 12, -14), (11, 0, 18, 1), (9, 5, 14, 15))):
            fwd = ((k != 1) == (side < 0)) == (step == 0)
            dy = -3 if fwd else 3
            y0 = 22 + k * 3.2
            legs.append('M%s %.1f L%.1f %.1f L%.1f %.1f' % (32 + side * 3, y0, 32 + side * kx, y0 + ky + dy * 0.5,
                                                            32 + side * fx, y0 + fy + dy))
    b.append('<path d="%s" fill="none" stroke="%s" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>'
             % (' '.join(legs), INK))
    sway = 1.2 if step else -1.2                                   # antennae: out from the head, forward at the elbow
    b.append('<path d="M28.5 9 L22.5 6 L20.5 %.1f M35.5 9 L41.5 6 L43.5 %.1f" fill="none" stroke="%s" stroke-width="2.4" '
             'stroke-linecap="round" stroke-linejoin="round"/>' % (0.5 + sway, 0.5 - sway, INK))
    for cx, cy, rx, ry in ((32, 46, 9.5, 12), (32, 32.3, 2.3, 2.3), (32, 23.5, 4.4, 6.2), (32, 12.5, 7.4, 6.8)):
        b.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" stroke="%s" stroke-width="2.2"/>' % (cx, cy, rx, ry, ANT_BODY, INK))
        if ry > 10:                                                 # the shade low on the gaster, and its highlight
            b.append('<ellipse cx="35" cy="51" rx="4.6" ry="5" fill="%s" opacity="0.5"/>' % ANT_SHADE)
            b.append('<path d="M26.5 49 Q26 42 29 38" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" opacity="0.5"/>')
    for x in (28.8, 35.2):                                                     # the eyes, with a spark
        b.append('<circle cx="%s" cy="11" r="2.1" fill="%s"/><circle cx="%s" cy="10.3" r="0.75" fill="#FFFFFF"/>' % (x, INK, x - 0.6))
    return svg(64, 64, '<g transform="translate(0 3)">%s</g>' % ''.join(b))


# ---- arrows -----------------------------------------------------------------------------------------------------------------

def mark_line(d, w=7):
    """A Show mark stroke: the room's deep edge with a white core (as the trace line)."""
    return ('<path d="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round"/>'
            '<path d="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round"/>'
            % (d, DEEP, w, d, WHITE, round(w * 0.45, 2)))


def head(x, y, ang, s=9):
    """A filled arrow head at (x, y) pointing at angle ang (degrees, 0 = right)."""
    a = math.radians(ang)
    pts = [(x + s * math.cos(a), y + s * math.sin(a)),
           (x + s * 0.9 * math.cos(a + 2.4), y + s * 0.9 * math.sin(a + 2.4)),
           (x + s * 0.9 * math.cos(a - 2.4), y + s * 0.9 * math.sin(a - 2.4))]
    d = 'M%.2f %.2f L%.2f %.2f L%.2f %.2f Z' % (pts[0] + pts[1] + pts[2])
    return '<path d="%s" fill="%s" stroke="%s" stroke-width="3" stroke-linejoin="round"/>' % (d, WHITE, DEEP)


def turn_layers():
    """An orbit round the solid's waist (a turn about the upright axis): the back half thin, dotted and pale (it passes
    behind the solid), the front half a full mark with its head at the right: the front of the solid moves right. A turn
    is a direction in the world, not in the text, so it is the same in the right-to-left interface."""
    back = svg(120, 44, '<path d="M8 22 A52 14 0 0 1 112 22" fill="none" stroke="%s" stroke-width="4" stroke-dasharray="2 7" '
                        'stroke-linecap="round" opacity="0.7"/>' % DEEP)
    front = svg(120, 44, mark_line('M8 22 A52 14 0 0 0 102 31', 7) + head(104, 30, -12))
    return back, front


def rotate(cw):
    """A three-quarter circle with its head: the piece turns this way (in the picture's plane). The head follows the
    circle's own direction at its end."""
    c, r = (32, 33), 20
    start, end = -90, (-90 + 250) if cw else (-90 - 250)
    ex, ey = c[0] + r * math.cos(math.radians(end)), c[1] + r * math.sin(math.radians(end))
    d = 'M%.2f %.2f A%s %s 0 1 %d %.2f %.2f' % (c[0], c[1] - r, r, r, 1 if cw else 0, ex, ey)
    tangent = end + (90 if cw else -90)
    return svg(64, 64, mark_line(d, 7) + head(ex + 2 * math.cos(math.radians(tangent)), ey + 2 * math.sin(math.radians(tangent)),
                                          tangent, 10))


# ---- sand --------------------------------------------------------------------------------------------------------------------

SAND, SAND_DEEP, SAND_LIP, SAND_SHADOW = '#F6DDB0', '#E2BF86', '#FCEFD3', '#C9A36A'


def sand_tray():
    b = ['<rect x="4" y="10" width="192" height="104" rx="20" fill="%s" opacity="0.13"/>' % INK,
         '<rect x="4" y="4" width="192" height="106" rx="20" fill="#C98F52" stroke="%s" stroke-width="3"/>' % INK,
         '<rect x="4" y="4" width="192" height="106" rx="20" fill="none" stroke="#E0B070" stroke-width="3" '
         'transform="translate(2 2) scale(0.98)" opacity="0.7"/>',
         '<rect x="16" y="15" width="168" height="84" rx="12" fill="%s" stroke="#A8743C" stroke-width="2.4"/>' % SAND,
         '<path d="M18 26 Q18 17 28 17 H172" fill="none" stroke="%s" stroke-width="4" opacity="0.8"/>' % SAND_SHADOW]
    for x, y in ((40, 40), (70, 78), (120, 34), (152, 70), (100, 60), (58, 58), (168, 44), (132, 88), (30, 86)):
        b.append('<circle cx="%s" cy="%s" r="1.4" fill="%s"/>' % (x, y, SAND_SHADOW))
    return svg(200, 120, ''.join(b))


PRINT_D = {
    'circle': 'M14 50 A36 36 0 1 1 86 50 A36 36 0 1 1 14 50 Z',
    'rect': 'M8 28 H92 V72 H8 Z',
    'square': 'M17 17 H83 V83 H17 Z',
    'triangle': 'M50 12 L90 84 H10 Z',
}


def sand_print(kind):
    """The face pressed into the sand: a bright lip pushed up round it (lower right, toward the viewer), the sunk face a
    shade darker, its own shadow along the inside of the upper left edge."""
    d = PRINT_D[kind]
    body = ('<clipPath id="p"><path d="%s"/></clipPath>'
            '<path d="%s" fill="none" stroke="%s" stroke-width="7" stroke-linejoin="round" transform="translate(1.5 1.5)"/>'
            '<path d="%s" fill="%s" stroke="#CFAA70" stroke-width="2" stroke-linejoin="round"/>'
            '<g clip-path="url(#p)"><path d="%s" fill="none" stroke="%s" stroke-width="7" stroke-linejoin="round" '
            'transform="translate(2.5 2.5)" opacity="0.85"/></g>' % (d, d, SAND_LIP, d, SAND_DEEP, d, SAND_SHADOW))
    return svg(100, 100, body)


# ---- the outlines the Show traces ---------------------------------------------------------------------------------------------

def _poly_pts(d):
    """The corners of an M/L/H/V/Z path (no curves)."""
    import re
    pts, x, y = [], 0.0, 0.0
    for cmd, args in re.findall(r'([MLHVZ])([^MLHVZ]*)', d):
        n = [float(v) for v in args.replace(',', ' ').split()]
        if cmd in 'ML':
            x, y = n[0], n[1]
        elif cmd == 'H':
            x = n[0]
        elif cmd == 'V':
            y = n[0]
        else:
            continue
        pts.append([round(x, 2), round(y, 2)])
    return pts


def _rot(pts, deg, c=(50, 50)):
    a = math.radians(deg)
    return [[round(c[0] + (x - c[0]) * math.cos(a) - (y - c[1]) * math.sin(a), 2),
             round(c[1] + (x - c[0]) * math.sin(a) + (y - c[1]) * math.cos(a), 2)] for x, y in pts]


def outlines():
    """Per picture id: its sides in the picture's 100 x 100 units, in the order the host goes round them (starting at the
    top, clockwise on the screen). Kinds: "poly" (closed: side i runs from pts[i] to pts[i+1], the last back to the
    first), "open" (a polyline that does not close: the gap is between the last point and the first), "dome" (a
    quadratic curve from p0 over c to p1, then the straight foot back), "ellipse" (cx, cy, rx, ry), "line" (a path of
    the line pictures, as their own d). The rounded corners of the square and the rectangle are traced as sharp corners
    1.5 units inside the ink (the trace's 7-unit stroke covers the rounding)."""
    sq = [[14, 14], [86, 14], [86, 86], [14, 86]]
    out = {
        'shape_square': {'kind': 'poly', 'pts': sq},
        'shape_rect': {'kind': 'poly', 'pts': [[6, 28], [94, 28], [94, 72], [6, 72]]},
        'shape_triangle': {'kind': 'poly', 'pts': [[50, 12], [90, 84], [10, 84]]},
        'shape_square_tilt': {'kind': 'poly', 'pts': _rot(sq, 45)},
        'shape_triangle_thin': {'kind': 'poly', 'pts': [[50, 6], [66, 92], [34, 92]]},
        'shape_triangle_down': {'kind': 'poly', 'pts': [[10, 16], [90, 16], [50, 88]]},
        'shape_pentagon': {'kind': 'poly', 'pts': _poly_pts(S.poly_d(5))},
        'shape_hexagon': {'kind': 'poly', 'pts': _poly_pts(S.poly_d(6))},
        'shape_quad': {'kind': 'poly', 'pts': _poly_pts(S.poly_d(4, 40, -45))},
        'shape_trapezoid': {'kind': 'poly', 'pts': [[27, 28], [73, 28], [93, 72], [7, 72]]},
        'shape_triangle_half': {'kind': 'poly', 'pts': [[14, 14], [86, 86], [14, 86]]},
        'shape_circle': {'kind': 'ellipse', 'e': [50, 50, 38, 38]},
        'shape_oval': {'kind': 'ellipse', 'e': [50, 50, 42, 27]},
        'shape_open': {'kind': 'open', 'pts': [[12, 84], [50, 14], [88, 84], [24, 84]]},
        'shape_curved': {'kind': 'dome', 'q': [[12, 84], [50, -10], [88, 84]]},
        'plate': {'kind': 'ellipse', 'e': [50, 54, 44, 19]},
        'window': {'kind': 'poly', 'pts': [[10, 14], [90, 14], [90, 86], [10, 86]]},
        'sign': {'kind': 'poly', 'pts': [[50, 10], [92, 84], [8, 84]]},
        # the solids' features the turn and the stamp point at
        'solid_cone': {'kind': 'solid', 'point': [50, 10], 'base': [50, 80, 34, 10]},
        'solid_cylinder': {'kind': 'solid', 'top': [50, 24, 30, 10], 'base': [50, 76, 30, 10]},
        'can': {'kind': 'solid', 'top': [50, 22, 29, 8.5], 'base': [50, 80, 29, 8.5]},
        'party_hat': {'kind': 'solid', 'point': [50, 13], 'base': [50, 80, 31, 9]},
        'solid_box': {'kind': 'solid', 'face': [[50, 10], [88, 28], [50, 46], [12, 28]]},
    }
    for k in ('red', 'blue', 'green', 'yellow', 'orange'):
        for base in ('shape_square', 'shape_rect', 'shape_triangle', 'shape_circle', 'shape_oval', 'shape_trapezoid',
                     'shape_triangle_half'):
            out['%s_%s' % (base, k)] = dict(out[base], same=base)
    for name, (d, _) in S.LINES.items():
        out[name] = {'kind': 'line', 'd': d}
    return out


def build():
    files = {os.path.join(HOSTS, 'kubi_hand.svg'): kubi_hand(),
             os.path.join(SHOW, 'ant_a.svg'): ant(0), os.path.join(SHOW, 'ant_b.svg'): ant(1),
             os.path.join(SHOW, 'rotate_cw.svg'): rotate(True), os.path.join(SHOW, 'rotate_ccw.svg'): rotate(False),
             os.path.join(SHOW, 'sand_tray.svg'): sand_tray()}
    back, front = turn_layers()
    files[os.path.join(SHOW, 'turn_back.svg')] = back
    files[os.path.join(SHOW, 'turn_front.svg')] = front
    for k in PRINT_D:
        files[os.path.join(SHOW, 'sand_print_%s.svg' % k)] = sand_print(k)
    files[os.path.join(SHOW, 'outlines.json')] = json.dumps(
        {'schema': 'show-outlines/v1', 'units': 'the picture viewBox, 100 x 100', 'by': 'tools/make_show_art.py',
         'pictures': outlines()}, indent=1, sort_keys=True) + '\n'
    return files


def main():
    files = build()
    os.makedirs(SHOW, exist_ok=True)
    bad = []
    for path, text in files.items():
        if '--check' in sys.argv:
            if not os.path.exists(path) or open(path, encoding='utf-8').read() != text:
                bad.append(path)
            continue
        with open(path, 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(text)
    if bad:
        sys.exit('out of date: ' + ', '.join(os.path.relpath(p, ROOT) for p in bad))
    print('%s %d files' % ('checked' if '--check' in sys.argv else 'wrote', len(files)))


if __name__ == '__main__':
    main()
