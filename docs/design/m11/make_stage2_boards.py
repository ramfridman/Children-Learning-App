"""Preview sheets of the M11 Stage 2 Shape Forest art (docs/design/m11-rooms.md section 13), drawn at real size in points with
the app's own pictures, rooms and fonts and rendered by headless Chrome:

    python docs/design/m11/make_stage2_boards.py

  stage2_shapes.png        the oval, the trapezoid and the half-square triangle beside the shape family, on tiles and at stage
                           size, in colour and in grey; the two tap items they serve on the phone; two halves making a square;
                           the rocket of shp.build.rocket as it is and with one triangle sprite.
  stage2_solids.png        the five solids as real things beside the abstract solids, in colour and grey, and the SHP-B-08 and
                           B-09 sorts with them on the phone.
  stage2_show_motions.png  storyboards of each Show motion (trace, count, sticks, ant walk, push and stack, turn, stamp,
                           the sorter's hole and the turn of a piece) on the phone, a key frame of each on the tablet, and
                           the whole host beat with Kubi's show pose and his pointer on the phone and the tablet.

Only the layout numbers of make_m11_boards.py (ActivitySpec) are used; the bins, tiles and pointer are drawn as the
section 13 spec says, so this is the reference for the developer, not a screenshot of the running app.
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import make_m11_boards as M   # noqa: E402

ROOT = M.ROOT
PICS, ART, CAST = M.PICS, M.ART, M.CAST
SHOW = os.path.join(ART, 'show')
HAND = os.path.join(ART, 'hosts', 'kubi_hand.svg')
ROOM = M.ROOM['shapes']
DEEP = ROOM['deep']
C = M.C
box, img, svg_at, esc = M.box, M.img, M.svg_at, M.esc
ARC = json.load(open(os.path.join(ROOT, 'content', 'units', 'arc', 'shape-forest.arc.json'), encoding='utf-8'))
SHOWS = {s['id']: s for s in ARC['shows']}
OUTL = json.load(open(os.path.join(SHOW, 'outlines.json'), encoding='utf-8'))['pictures']

# tile and pointer sizes per board (section 13.3)
TILE = {'phone': 84, 'tabletL': 112}
PTR_W = {'phone': 34, 'tabletL': 48}
BADGE_R = {'phone': 11, 'tabletL': 14}


def pic(name):
    return os.path.join(PICS, name + '.svg')


def sprite_of(ref):
    return ref.split(':', 1)[1]


# ---- the frame of a sort or a build -------------------------------------------------------------------------------------------

def bins_inner(bins, b):
    """The bins as white cards across the stage (as the template draws them): a sample picture and the label on top,
    the dropped things below. Returns inner(ix, iy, iw, ih) and a dict of each bin's body box."""
    where = {}

    def inner(ix, iy, iw, ih):
        out = []
        n = len(bins)
        gap = 8 if b == 'phone' else 14
        bw = (iw - gap * (n + 1)) / n
        bh = ih - 2 * gap
        for i, bn in enumerate(bins):
            x = ix + iw - gap - (i + 1) * bw - i * gap            # the first bin at the start side (right)
            y = iy + gap
            out.append(box(x, y, bw, bh, 'background:rgba(255,255,255,.92);border:3px solid %s;border-radius:16px' % C['hairline']))
            hs = 24 if b == 'phone' else 34
            fs = 14 if b == 'phone' else 18
            if bn.get('count'):
                body = (x + 6, y + 6, bw - 12, bh - 12)
            else:
                out.append(box(x + 4, y + 4, bw - 8, hs + 4, 'display:flex;align-items:center;justify-content:center;gap:6px;'
                               'direction:rtl', '<img src="%s" style="width:%dpx;height:%dpx">'
                               '<span dir="rtl" lang="he" style="font:600 %dpx/1.7 H;color:%s">%s</span>' % (
                                   M.uri(pic(sprite_of(bn['sprite']))), hs, hs, fs, C['ink'], esc(bn.get('label', '')))))
                body = (x + 6, y + hs + 10, bw - 12, bh - hs - 16)
            if bn.get('count'):
                out += stick_row(bn['count'], (body[0], body[1], body[2], body[3] - fs * 1.7), b)
                out.append(box(x, y + bh - fs * 1.9 - 4, bw, fs * 1.9, 'text-align:center', '<span dir="rtl" lang="he" '
                               'style="font:600 %dpx/1.7 H;color:%s">%s</span>' % (fs, C['ink'], esc(bn.get('label', '')))))
            where[bn['id']] = body
        return out
    return inner, where


def stick_row(n, body, b):
    """A count bin: n sticks standing side by side (a tally: "this many sides"), the label under them."""
    x, y, w, h = body
    sw = 7 if b == 'phone' else 9
    sh = h * 0.62
    step = min(16 if b == 'phone' else 22, (w - 20) / max(n, 1))
    x0 = x + w / 2 - step * (n - 1) / 2
    out = []
    for i in range(n):
        out.append(stick_v(x0 + i * step, y + 4, sw, sh))
    return out


def stick_v(cx, top, sw, sh):
    """A wooden stick standing up (stick_long turned upright): code-drawn, as the bin and the lifted sides use it."""
    return svg_at(cx - sw / 2 - 2, top - 2, sw + 4, sh + 4,
                  '<rect x="2" y="2" width="%g" height="%g" rx="%g" fill="#C98F52" stroke="%s" stroke-width="1.6"/>'
                  '<path d="M%g 6 V%g" stroke="#E0B070" stroke-width="1.4" stroke-linecap="round"/>'
                  % (sw, sh, sw / 2, C['ink'], 2 + sw * 0.3, sh - 2))


def stick_between(p, q, k=1.0, w=6):
    """A stick lying from p to q (board points)."""
    return svg_at(0, 0, 1, 1, '<path d="M%g %g L%g %g" stroke="%s" stroke-width="%g" stroke-linecap="round"/>'
                  '<path d="M%g %g L%g %g" stroke="#C98F52" stroke-width="%g" stroke-linecap="round"/>' % (
                      p[0], p[1], q[0], q[1], C['ink'], w + 3, p[0], p[1], q[0], q[1], w), view='0 0 1 1')


def tile_row(items, b, y=None):
    """The answer tiles under the stage (centred in the tile band). items: list of sprite names or None (an empty place).
    Returns parts and the picture box of each tile."""
    tx, ty, tw = M.B[b]['tiles']
    s = TILE[b]
    gap = 18 if b == 'phone' else 24
    total = len(items) * s + (len(items) - 1) * gap
    x0 = tx + (tw - total) / 2
    out, boxes = [], []
    for i, it in enumerate(items):
        x = x0 + total - s - i * (s + gap)                      # right to left: the first item at the start side
        yy = y if y is not None else ty + 4
        p = s * 0.76
        pb = (x + (s - p) / 2, yy + (s - p) / 2, p, p)
        boxes.append(pb)
        if it is None:
            out.append(box(x, yy, s, s, 'border:3px dashed %s;border-radius:28px' % C['lip']))
            continue
        out.append(M.tile(x, yy, s, ''))
        out.append(img(pic(it), *pb))
    return out, boxes


def at(pb, ux, uy):
    """A point of a picture (its own 100 units) in board points."""
    x, y, w, h = pb
    return x + ux / 100 * w, y + uy / 100 * h


# ---- the Show marks --------------------------------------------------------------------------------------------------------

def trace(pb, d, b, partial=None):
    """The trace line on a picture: the room's deep edge, a white core (section 13.2)."""
    x, y, w, h = pb
    k = 100 / w
    ew, cw = (7 if b == 'phone' else 10) * k, (3.4 if b == 'phone' else 4.8) * k
    dash = ''
    if partial is not None:
        dash = ' pathLength="100" stroke-dasharray="%g 200"' % partial
    return svg_at(x, y, w, h, '<path d="%s" fill="none" stroke="%s" stroke-width="%g" stroke-linecap="round" '
                              'stroke-linejoin="round"%s/><path d="%s" fill="none" stroke="#FFFFFF" stroke-width="%g" '
                              'stroke-linecap="round" stroke-linejoin="round"%s/>' % (d, DEEP, ew, dash, d, cw, dash),
                  view='0 0 100 100')


def side_d(name, i):
    o = OUTL[name]
    pts = o['pts']
    p, q = pts[i], pts[(i + 1) % len(pts)]
    return 'M%g %g L%g %g' % (p[0], p[1], q[0], q[1])


def badge(cx, cy, n, b):
    r = BADGE_R[b]
    return box(cx - r, cy - r, 2 * r, 2 * r, 'background:#fff;border:2.5px solid %s;border-radius:50%%;display:flex;'
               'align-items:center;justify-content:center;box-shadow:0 2px 0 %s' % (DEEP, C['lip']),
               '<span dir="ltr" style="font:800 %dpx/1 H;color:%s">%d</span>' % (14 if b == 'phone' else 18, C['ink'], n))


def side_badge(name, pb, i, n, b):
    o = OUTL[name]
    pts = o['pts']
    p, q = pts[i], pts[(i + 1) % len(pts)]
    cx = sum(v[0] for v in pts) / len(pts)
    cy = sum(v[1] for v in pts) / len(pts)
    mx, my = (p[0] + q[0]) / 2, (p[1] + q[1]) / 2
    dx, dy = mx - cx, my - cy
    L = math.hypot(dx, dy) or 1
    off = (BADGE_R[b] + 3) / pb[2] * 100
    return badge(*at(pb, mx + dx / L * off, my + dy / L * off), n=n, b=b)


def pointer(tip, b, angle=-30, away=None):
    """Kubi's pointer: the tip (32, 3) of its 64 x 300 box on the target. The leg points away from the middle of the thing
    it acts on (away: that middle, in board points), so it never lies across the shape: from below, or from his own side
    (the right, up to 30 degrees above level) for a side that faces up; without a middle it leans toward his corner."""
    if away is not None:
        dx, dy = tip[0] - away[0], tip[1] - away[1]
        want = math.degrees(math.atan2(-dx, dy))                 # the leg along the outward direction
        lo, hi = -120, 45                                         # from below, or from his side (right), never from the left top
        if lo <= want <= hi:
            angle = want
        else:
            dist = lambda a, b2: abs((a - b2 + 180) % 360 - 180)
            angle = lo if dist(want, lo) < dist(want, hi) else hi
    w = PTR_W[b]
    h = w * 300 / 64
    tx, ty = tip[0] - w * 32 / 64, tip[1] - h * 3 / 300
    return img(HAND, tx, ty, w, h, 'transform:rotate(%gdeg);transform-origin:%gpx %gpx;z-index:5' % (angle, w * 32 / 64, h * 3 / 300))


def mid_of(pb, name):
    o = OUTL.get(name, {})
    pts = o.get('pts')
    if pts:
        return at(pb, sum(v[0] for v in pts) / len(pts), sum(v[1] for v in pts) / len(pts))
    return at(pb, 50, 50)


def point_on(pb, name, ux, uy, b):
    return pointer(at(pb, ux, uy), b, away=mid_of(pb, name))


def gap_ring(c, b):
    r = 9 if b == 'phone' else 12
    return box(c[0] - r, c[1] - r, 2 * r, 2 * r, 'border:2.5px dashed %s;border-radius:50%%;background:rgba(255,255,255,.55)' % DEEP)


def ant_at(c, angle, b, frame='a'):
    s = 26 if b == 'phone' else 34
    return img(os.path.join(SHOW, 'ant_%s.svg' % frame), c[0] - s / 2, c[1] - s * 34 / 64, s, s,
               'transform:rotate(%gdeg);transform-origin:50%% %g%%;z-index:4' % (angle, 34 / 64 * 100))


def home_dot(c, b):
    r = 5 if b == 'phone' else 6.5
    return box(c[0] - r, c[1] - r, 2 * r, 2 * r, 'background:#fff;border:2.5px solid %s;border-radius:50%%' % DEEP)


def motion_note(x, y, w, text):
    return box(x, y, w, 40, 'font:600 11px/1.3 sans-serif;color:#B23A3A', esc(text))


# ---- a board: the frame, the bins, the tiles and the marks -----------------------------------------------------------------------

def spot_box(b, k=1.0):
    """The show spot: the middle of the stage, where the host holds up the thing it demonstrates (section 13.1)."""
    x, y, w, h = M.B[b]['stage']
    if M.B[b]['card']:
        x, y, w, h = x + 16, y + 16, w - 32, h - 32
    s = (h - (20 if b == 'phone' else 36)) * k
    return x + (w - s) / 2, y + (h - s) / 2, s, s


def veil(b):
    x, y, w, h = M.B[b]['stage']
    if M.B[b]['card']:
        x, y, w, h = x + 16, y + 16, w - 32, h - 32
    return box(x, y, w, h, 'background:rgba(255,255,255,.5);border-radius:%dpx' % (24 if b == 'phone' else 16))


def sort_board(b, show, tiles, marks, done=None, host=True, line=None, spot=None):
    """A Show screen of a sort: bins from the arc's scene, the tiles (None for an item already sorted), marks(boxes,
    where) -> parts drawn over everything. done: {bin id: [sprites]} already in a bin. spot: (tile index, sprite): that
    thing is held up in the show spot (its tile shows an empty place, the bins wait under a veil); its box is then
    boxes[index]."""
    out = M.base(b, ROOM, n=6, done=1)
    inner, where = bins_inner(show['scene']['bins'], b)
    out += M.stage(b, ROOM, inner, landmark=False)
    for bid, sprites in (done or {}).items():
        x, y, w, h = where[bid]
        s = min(h * 0.8, w / max(len(sprites), 1) - 4)
        for i, sp in enumerate(sprites):
            out.append(img(pic(sp), x + w - (i + 1) * (s + 4), y + (h - s) / 2, s, s))
    if spot is not None:
        tiles = list(tiles)
        tiles[spot[0]] = None
    tparts, boxes = tile_row(tiles, b)
    out += tparts
    if spot is not None:
        out.append(veil(b))
        sb = spot_box(b)
        if spot[1]:
            out.append(img(pic(spot[1]), *sb))
        boxes[spot[0]] = sb
    if host:
        out += M.duo(b, ROOM, os.path.join(CAST, 'kubi-show.svg'))
        if line:
            hb = M.B[b]
            mouth = hb['host'][1] + 0.58 * hb['host'][2]
            out += M.bubble(b, line, right=hb['hostBubbleRight'], tail_y=max(18, mouth - hb['bubble']['top'] - 11),
                            maxw=hb['bubble']['w'] - (hb['bubble']['right'] - hb['hostBubbleRight']))
    out += marks(boxes, where)
    return out


def crop(parts, x, y, w, h):
    return [box(0, 0, w, h, 'overflow:hidden', '<div style="position:absolute;left:%gpx;top:%gpx;width:2000px;height:2000px">%s</div>'
                % (-x, -y, ''.join(parts)))]


PH_CROP = (56, 82, 566, 270)      # the phone's stage and tiles (x, y, w, h)
TL_CROP = (270, 212, 620, 470)    # the tablet landscape's card and tiles


# ---- stage2_shapes.png -----------------------------------------------------------------------------------------------------------

FAMILY = ['shape_circle', 'shape_oval', 'shape_square', 'shape_square_tilt', 'shape_rect', 'shape_trapezoid', 'shape_quad',
          'shape_triangle', 'shape_triangle_thin', 'shape_triangle_down', 'shape_triangle_half', 'shape_pentagon',
          'shape_hexagon', 'shape_curved', 'shape_open']
NEW = {'shape_oval', 'shape_trapezoid', 'shape_triangle_half'}


def family_strip(grey=False):
    W, H = 1500, 200
    out = [box(0, 0, W, H, 'background:%s' % ROOM['tint'])]
    for i, n in enumerate(FAMILY):
        x = 12 + i * 98
        out.append(box(x, 10, 88, 88, 'background:#fff;border-radius:22px;border:3px solid %s;%s' % (
            DEEP if n in NEW else C['hairline'], 'filter:grayscale(1)' if grey else '')))
        out.append(img(pic(n), x + 11, 21, 66, 66, 'filter:grayscale(1)' if grey else ''))
        # at stage size on the room's backdrop: 44 and 28 points
        out.append(svg_at(x, 106, 88, 56, M.backdrop('shapes', 88, 56)))
        out.append(img(pic(n), x + 4, 112, 44, 44, 'filter:grayscale(1)' if grey else ''))
        out.append(img(pic(n), x + 54, 126, 28, 28, 'filter:grayscale(1)' if grey else ''))
        out.append(box(x, 166, 88, 30, 'font:600 10px/1.2 sans-serif;color:%s;text-align:center;overflow-wrap:anywhere' % (
            DEEP if n in NEW else C['inkSoft']), esc(n.replace('shape_', ''))))
    return out, W, H


def colours_strip():
    W, H = 1500, 110
    out = [box(0, 0, W, H, 'background:%s' % ROOM['tint'])]
    x = 12
    for kind in ('oval', 'trapezoid', 'triangle_half'):
        for c in ('', '_red', '_blue', '_green', '_yellow', '_orange'):
            out.append(box(x, 10, 72, 72, 'background:#fff;border-radius:18px;border:3px solid %s' % C['hairline']))
            out.append(img(pic('shape_%s%s' % (kind, c)), x + 9, 19, 54, 54))
            out.append(box(x, 86, 72, 20, 'font:600 9px/1.2 sans-serif;color:%s;text-align:center' % C['inkSoft'],
                           esc((kind + c).replace('triangle_half', 'half'))))
            x += 80
        x += 22
    return out, W, H


def tap_board(b, line, items, grey=False):
    out = M.base(b, ROOM, n=6, done=2)
    out += M.stage(b, ROOM, None, landmark=True)
    out += M.alone(b)
    out += M.bubble(b, line, tail_y=46)
    parts, boxes = tile_row(items, b)
    out += parts
    if grey:
        return ['<div style="position:absolute;left:0;top:0;filter:grayscale(1)">%s</div>' % ''.join(out)]
    return out


def halves_board():
    """SHP-B-06 with the half-square triangle: the square as one shadow, one half in its place, the other half turning
    180 degrees on its way in (rotate arrow)."""
    b = 'phone'
    out = M.base(b, ROOM, n=6, done=3)

    def inner(ix, iy, iw, ih):
        s = ih - 20
        x0 = ix + iw - s - 40
        y0 = iy + 10
        parts = [svg_at(x0, y0, s, s, '<path d="M14 14 H86 V86 H14 Z" fill="#B8BCCB" opacity="0.75"/>', view='0 0 100 100'),
                 img(pic('shape_triangle_half_blue'), x0, y0, s, s)]
        # the second half on its way: turned part of the way (90 of 180), with the rotate arrow
        gx = ix + 30
        parts.append(img(pic('shape_triangle_half_blue'), gx, y0 + 8, s * 0.82, s * 0.82, 'transform:rotate(100deg)'))
        parts.append(img(os.path.join(SHOW, 'rotate_cw.svg'), gx + s * 0.82 * 0.18, y0 + 8 + s * 0.82 * 0.18, s * 0.82 * 0.64,
                         s * 0.82 * 0.64))
        return parts
    out += M.stage(b, ROOM, inner, landmark=False)
    out += M.duo(b, ROOM, os.path.join(CAST, 'kubi-show.svg'))
    return out


def rocket(slots, W, H, colour_note=None):
    """shp.build.rocket assembled (in colour), each slot as the template places it (the visible box of each kind)."""
    out = []
    for s in slots:
        x, y, w, h = s['x'] * W, s['y'] * H, s['w'] * W, s['h'] * H
        out.append(img(pic(sprite_of(s['sprite'])), x, y, w, h, 'transform:rotate(%gdeg)' % s['rot']))
    return out


def rocket_panel():
    act = json.load(open(os.path.join(PICS, 'activity.shp.build.rocket.json'), encoding='utf-8'))
    slots = act['scene']['slots']
    H = 220
    W = H * act['scene']['aspect']
    out = [box(0, 0, 1500, 330, 'background:%s' % ROOM['tint'])]

    def panel(x, sl, title, pieces, shadow=False):
        p = [box(x, 10, W + 40, H + 20, 'background:#fff;border-radius:20px')]
        inner = rocket(sl, W, H)
        if shadow:
            inner = ['<div style="filter:brightness(0) opacity(.28)">%s</div>' % ''.join(inner)]
        p.append('<div style="position:absolute;left:%gpx;top:20px;width:%gpx;height:%gpx">%s</div>' % (x + 20, W, H, ''.join(inner)))
        p.append(box(x, H + 34, W + 40, 40, 'font:600 11px/1.3 sans-serif;color:#B23A3A', esc(title)))
        tx = x + W + 60
        for i, sp in enumerate(pieces):
            p.append(box(tx + (i % 3) * 66, 20 + (i // 3) * 70, 60, 60, 'background:#fff;border-radius:16px;border:3px solid %s' % C['hairline']))
            p.append(img(pic(sp), tx + (i % 3) * 66 + 8, 28 + (i // 3) * 70, 44, 44))
        return p

    out += panel(10, slots, 'as built: one grey shadow (what the child sees), nose 36 red, fins 34 green', [], shadow=True)
    out += panel(230, slots, 'as built, in colour: the pieces are told apart only by colour, which the shadow does not show',
                 ['shape_rect_orange', 'shape_triangle_red', 'shape_circle_blue', 'shape_triangle_green', 'shape_triangle_green'])
    fixed = []
    for s in slots:
        s = dict(s)
        if 'triangle' in s['sprite']:
            k = 36 / 34 if 'green' in s['sprite'] else 1
            cx, cy = s['x'] + s['w'] / 2, s['y'] + s['h'] / 2
            s['w'], s['h'] = s['w'] * k, s['h'] * k
            s['x'], s['y'] = cx - s['w'] / 2, cy - s['h'] / 2
            s['sprite'] = 'asset:shape_triangle_red'
        fixed.append(s)
    out += panel(700, fixed, 'proposed: one sprite (shape_triangle_red) and one size (36) for the nose and both fins, so any '
                             'triangle fits any triangle place',
                 ['shape_rect_orange', 'shape_triangle_red', 'shape_circle_blue', 'shape_triangle_red', 'shape_triangle_red'])
    return out, 1500, 330


def shapes_sheet():
    fam, fw, fh = family_strip()
    famg, _, _ = family_strip(grey=True)
    col, cw, ch = colours_strip()
    rk, rw, rh = rocket_panel()
    M.page([
        (fam, fw, fh, 'The shape family on 88 pt tiles and on the Shape Forest stage at 44 and 28 pt; the three new ones have a green '
                      'ring. Same outline (ink 3 of 100), same shade and highlight, the house palette.'),
        (famg, fw, fh, 'The same in grey: the oval, the trapezoid and the half triangle are told from the circle, the rectangle and '
                       'the triangle by their outline alone.'),
        (col, cw, ch, 'The new kinds in their plain fill and the five shape colours (the plain oval is red like shape_circle, the '
                      'plain trapezoid orange like shape_rect, so colour never gives the answer away).'),
        (tap_board('phone', 'אֵיפֹה הָעִגּוּל?', ['shape_oval', 'shape_circle', 'shape_square_red']), 852, 393,
         'phone, lesson size: "where is the circle?" with the oval as the second honest distractor (both red).'),
        (tap_board('phone', 'אֵיפֹה הַמַּלְבֵּן?', ['shape_trapezoid', 'shape_triangle_orange', 'shape_rect']), 852, 393,
         'phone, lesson size: "where is the rectangle?" with the trapezoid (four sides, no square corner).'),
        (tap_board('phone', 'אֵיפֹה הָעִגּוּל?', ['shape_oval', 'shape_circle', 'shape_square_red'], grey=True), 852, 393,
         'the same in grey (colour-blind check): the oval still reads as not round.'),
        (halves_board(), 852, 393, 'phone, SHP-B-06 with shape_triangle_half_blue: the square as one shadow, one half in, the '
                                   'other half turning 180 degrees on its way (rotate_cw).'),
        (rk, rw, rh, 'shp.build.rocket (data from activity.shp.build.rocket.json, each slot at its x, y, w, h, rot).'),
    ], os.path.join(HERE, 'stage2_shapes.png'), 1784)


# ---- stage2_solids.png ----------------------------------------------------------------------------------------------------------

PAIRS = [('can', 'solid_cylinder', 'cylinder: a tin of sweet corn'), ('party_hat', 'solid_cone', 'cone: a party hat'),
         ('ball_red', 'solid_sphere', 'sphere: the play ball (existing)'), ('gift_box', None, 'box: a gift box'),
         ('dice', 'solid_box', 'cube: a dice'), ('pyramid_egypt', 'solid_pyramid', 'pyramid: a pyramid of Egypt')]


def solids_strip(grey=False):
    W, H = 1500, 236
    out = [box(0, 0, W, H, 'background:%s' % ROOM['tint'])]
    f = 'filter:grayscale(1)' if grey else ''
    for i, (thing, solid, cap) in enumerate(PAIRS):
        x = 12 + i * 246
        out.append(box(x, 10, 112, 112, 'background:#fff;border-radius:24px;border:3px solid %s' % (C['hairline'] if thing == 'ball_red' else DEEP)))
        out.append(img(pic(thing), x + 12, 22, 88, 88, f))
        if solid:
            out.append(box(x + 122, 34, 84, 84, 'background:#fff;border-radius:20px;border:3px solid %s' % C['hairline']))
            out.append(img(pic(solid), x + 132, 44, 64, 64, f))
        out.append(svg_at(x, 132, 226, 60, M.backdrop('shapes', 226, 60)))
        out.append(img(pic(thing), x + 8, 138, 48, 48, f))
        out.append(img(pic(thing), x + 64, 156, 30, 30, f))
        if solid:
            out.append(img(pic(solid), x + 120, 138, 48, 48, f))
        out.append(box(x, 198, 226, 36, 'font:600 11px/1.3 sans-serif;color:%s' % C['ink'], esc(cap)))
    return out, W, H


def solids_sort(b, sid, tiles):
    show = dict(SHOWS[sid])
    return sort_board(b, show, tiles, lambda boxes, where: [], host=False)


def solids_sheet():
    s, w, h = solids_strip()
    g, _, _ = solids_strip(grey=True)
    show8 = SHOWS['show.shp-b-08']
    M.page([
        (s, w, h, 'The real things (green ring) beside the abstract solid they stand for, at 88 and 64 pt on tiles and at 48 and 30 pt '
                  'on the stage.'),
        (g, w, h, 'The same in grey: each thing keeps its solid\'s form (two round ends, one point, flat faces and straight edges).'),
        (solids_sort('phone', 'show.shp-b-08', ['can', 'party_hat', 'ball_red']), 852, 393,
         'phone, SHP-B-08 "by name" with the real things in the tiles (the arc\'s upgrade): bins cylinder, cone, sphere.'),
        (sort_board('phone', dict(show8, scene=dict(show8['scene'], bins=[
            {'id': 'b1', 'sprite': 'asset:solid_box', 'label': 'קֻבִּיָּה'}, {'id': 'b2', 'sprite': 'asset:gift_box', 'label': 'תֵּבָה'},
            {'id': 'b3', 'sprite': 'asset:solid_pyramid', 'label': 'פִּירָמִידָה'}])),
            ['dice', 'gift_box', 'pyramid_egypt'], lambda bx, wh: [], host=False), 852, 393,
         'phone, the cube, box and pyramid line the arc waits for: the dice, the gift box, the pyramid in the tiles (bin labels are '
         'samples for the editor; no abstract long box exists, solid_box is drawn as a cube).'),
        (solids_sort('phone', 'show.shp-b-09', ['can', 'gift_box', 'party_hat']), 852, 393,
         'phone, SHP-B-09 "the face it stamps": bins circle and rectangle, the real things in the tiles.'),
        (solids_sort('tabletL', 'show.shp-b-08', ['can', 'party_hat', 'ball_red']), 1180, 820,
         'tablet landscape, SHP-B-08 with the real things.'),
    ], os.path.join(HERE, 'stage2_solids.png'), 1784)


# ---- stage2_show_motions.png ---------------------------------------------------------------------------------------------------

def m_trace(b, f, line=None):
    """SHP-A-03: Kubi holds the thin triangle up in the show spot and runs his hand along each side (each side lights and
    stays); then the open figure: the line stops at the gap."""
    show = SHOWS['show.shp-a-03']
    tiles = ['shape_triangle_thin', 'shape_triangle_down', 'shape_open', 'shape_triangle_red']
    if f == 3:
        tiles = [None, 'shape_triangle_down', 'shape_open', 'shape_triangle_red']

    def marks(boxes, where):
        out = []
        if f in (1, 2):
            pb = boxes[0]
            n = 1 if f == 1 else 3
            for i in range(n - 1):
                out.append(trace(pb, side_d('shape_triangle_thin', i), b))
            pts = OUTL['shape_triangle_thin']['pts']
            out.append(trace(pb, side_d('shape_triangle_thin', n - 1), b, partial=60))
            p, q = pts[n - 1], pts[n % 3]
            out.append(point_on(pb, 'shape_triangle_thin', p[0] + (q[0] - p[0]) * 0.6, p[1] + (q[1] - p[1]) * 0.6, b))
        else:
            pb = boxes[2]
            out.append(trace(pb, 'M24 84 L88 84 L50 14 L12 84', b))
            out.append(gap_ring(at(pb, 18, 84), b))
            out.append(point_on(pb, 'shape_open', 12, 84, b))
        return out
    done = {'b1': ['shape_triangle_thin']} if f == 3 else None
    spot = (0, 'shape_triangle_thin') if f < 3 else (2, 'shape_open')
    return sort_board(b, show, tiles, marks, done=done, spot=spot, line=line)


def m_count(b, f, line=None):
    """SHP-B-02: in the show spot each side lights and takes a number badge as Kubi counts; the triangle goes to the
    3-stick bin, and the next shape comes up."""
    show = SHOWS['show.shp-b-02']
    tiles = ['shape_triangle_down', 'shape_square_tilt', 'shape_rect_green'] if f < 3 else [None, 'shape_square_tilt', 'shape_rect_green']
    name = 'shape_triangle_down' if f < 3 else 'shape_square_tilt'

    def marks(boxes, where):
        out = []
        pb = boxes[0 if f < 3 else 1]
        npts = len(OUTL[name]['pts'])
        n = {1: 1, 2: 3, 3: 2}[f]
        for i in range(n):
            out.append(trace(pb, side_d(name, i), b))
            out.append(side_badge(name, pb, i, i + 1, b))
        pts = OUTL[name]['pts']
        k = n % npts
        out.append(point_on(pb, name, *[(pts[n - 1][j] + pts[k][j]) / 2 for j in (0, 1)], b=b))
        return out
    done = {'b1': ['shape_triangle_down']} if f == 3 else None
    return sort_board(b, show, tiles, marks, done=done, spot=(0, name) if f < 3 else (1, name), line=line)


def stage_inner(b):
    x, y, w, h = M.B[b]['stage']
    return (x + 16, y + 16, w - 32, h - 32) if M.B[b]['card'] else (x, y, w, h)


def m_sticks(b, f):
    """SHP-A-04: in the show spot a stick lies on each side of the long rectangle; then the rectangle slides to the stage's
    start side and the sticks line up at its end side from one start line: two long, two short. It is not a square."""
    show = SHOWS['show.shp-a-04']
    tiles = ['shape_square_tilt', 'shape_rect', 'shape_square_red'] if f < 3 else ['shape_square_tilt', None, 'shape_square_red']

    def marks(boxes, where):
        out = []
        pts = OUTL['shape_rect']['pts']
        w = 6 if b == 'phone' else 9
        if f == 1:
            pb = boxes[1]
            for i in range(4):
                out.append(stick_between(at(pb, *pts[i]), at(pb, *pts[(i + 1) % 4]), w=w))
            out.append(point_on(pb, 'shape_rect', 50, 72, b))
        elif f == 2:
            ix, iy, iw, ih = stage_inner(b)
            sx0, sy0, ss, _ = spot_box(b)
            pb = (ix + iw - ss - 10, sy0, ss, ss)                 # the rectangle at the start side
            out.append(img(pic('shape_rect'), *pb))
            out.append(trace(pb, 'M6 28 H94 V72 H6 Z', b))
            gap = 14 if b == 'phone' else 24
            L = ss * 0.88
            sx = ix + 14
            sy = sy0 + ss / 2 - 1.5 * gap
            out.append(svg_at(sx - 5, sy - 10, 6, 3 * gap + 20, '<path d="M3 2 V%g" stroke="%s" stroke-width="2.5" '
                              'stroke-dasharray="1 6" stroke-linecap="round"/>' % (3 * gap + 18, DEEP), view='0 0 6 %g' % (3 * gap + 20)))
            for i, l in enumerate([L, L, L / 2, L / 2]):
                y = sy + i * gap
                out.append(stick_between((sx + 4, y), (sx + 4 + l, y), w=w))
        return out
    done = {'b2': ['shape_rect']} if f == 3 else None
    spot = {1: (1, 'shape_rect'), 2: (1, None), 3: None}[f]
    return sort_board(b, show, tiles, marks, done=done, spot=spot)


def m_walk(b, f):
    """SHP-B-04: in the show spot an ant walks round the outline: home again on the pentagon (closed), out through the gap
    of the open one."""
    show = SHOWS['show.shp-b-04']
    tiles = ['shape_pentagon', 'shape_open', 'shape_curved', 'shape_hexagon'] if f < 3 else [None, 'shape_open', 'shape_curved', 'shape_hexagon']

    def marks(boxes, where):
        out = []
        if f < 3:
            pb = boxes[0]
            pts = OUTL['shape_pentagon']['pts']
            out.append(home_dot(at(pb, *pts[0]), b))
            n = 2 if f == 1 else 5
            d = 'M%g %g ' % tuple(pts[0]) + ' '.join('L%g %g' % tuple(pts[(i + 1) % 5]) for i in range(n))
            out.append(trace(pb, d, b))
            if f == 1:
                p, q = pts[2], pts[3]
                c = (p[0] + (q[0] - p[0]) * 0.4, p[1] + (q[1] - p[1]) * 0.4)
                ang = math.degrees(math.atan2(q[1] - p[1], q[0] - p[0])) + 90
                out.append(ant_at(at(pb, *c), ang, b))
            else:
                out.append(ant_at(at(pb, pts[0][0], pts[0][1] - 9), 0, b, 'b'))
        else:
            pb = boxes[1]
            out.append(trace(pb, 'M12 84 L50 14 L88 84 L24 84', b))
            out.append(gap_ring(at(pb, 18, 84), b))
            out.append(ant_at(at(pb, -2, 92), -100, b))
        return out
    done = {'b1': ['shape_pentagon']} if f == 3 else None
    spot = (0, 'shape_pentagon') if f < 3 else (1, 'shape_open')
    return sort_board(b, show, tiles, marks, done=done, spot=spot)


def m_push(b, f):
    """SHP-A-07: the same push for both, from the end side toward the start side (where "rolls" is): the ball rolls away
    into its bin, the block only wobbles; then the block stacks on the bin's box."""
    show = SHOWS['show.shp-a-07']

    def marks(boxes, where):
        out = []
        if f == 1:
            pb = boxes[0]
            out.append(pointer(at(pb, 2, 60), b, angle=40))
        elif f == 2:
            x, y, w, h = where['b1']
            s = min(h * 0.8, w / 2 - 4)
            out.append(svg_at(x + w - s - 4 - s * 0.7, y + (h - s) / 2 + s * 0.2, s * 0.6, s * 0.6,
                              '<path d="M28 6 H4 M26 15 H0 M28 24 H6" stroke="%s" stroke-width="3" stroke-linecap="round" '
                              'opacity=".6"/>' % DEEP, view='0 0 30 30'))
            pb = boxes[1]
            out.append(pointer(at(pb, 2, 55), b, angle=40))
            out.append(svg_at(pb[0] + pb[2] + 2, pb[1] + 8, 10, pb[3] - 16, '<path d="M2 0 Q10 50 2 100" stroke="%s" stroke-width="3" '
                              'fill="none" stroke-linecap="round" opacity=".55"/>' % DEEP, view='0 0 10 100'))
        return out
    if f == 1:
        return sort_board(b, show, ['ball_blue', 'block', 'ball_yellow'], marks, spot=(0, 'ball_blue'))
    if f == 2:
        return sort_board(b, show, ['ball_blue', 'block', 'ball_yellow'], marks, done={'b1': ['ball_blue']},
                          spot=(1, 'block'))
    return sort_board(b, show, [None, None, 'ball_yellow'], marks, done={'b1': ['ball_blue'], 'b2': ['block']})


def m_turn(b, f):
    """SHP-B-08 with the real things: in the show spot each turns slowly as it is named (an orbit arrow round its waist):
    the one point of the hat (a ring), the two circles of the can (traced)."""
    show = SHOWS['show.shp-b-08']
    tiles = ['can', 'party_hat', 'ball_red'] if f < 3 else [None, 'party_hat', 'ball_red']

    def turned(pb, layer):
        x, y, w, h = pb
        return img(os.path.join(SHOW, 'turn_%s.svg' % layer), x - w * 0.14, y + h * 0.5, w * 1.28, w * 1.28 * 44 / 120)

    def marks(boxes, where):
        out = []
        if f == 1:
            pb = boxes[1]
            out.append(turned(pb, 'front'))
            out.append(gap_ring(at(pb, 50, 9), b))
        elif f == 2:
            pb = boxes[0]
            out.append(trace(pb, 'M21 22 A29 8.5 0 1 0 79 22 A29 8.5 0 1 0 21 22 Z', b))
            out.append(trace(pb, 'M21 80 A29 8.5 0 0 0 79 80', b))
            out.append(turned(pb, 'front'))
        return out
    done = {'b1': ['can']} if f == 3 else None
    spot = {1: (1, 'party_hat'), 2: (0, 'can'), 3: None}[f]
    out = sort_board(b, show, tiles, marks, done=done, spot=spot)
    if spot:   # the back half of the orbit goes under the thing: put it just before the thing's picture
        sb = spot_box(b)
        back = img(os.path.join(SHOW, 'turn_back.svg'), sb[0] - sb[2] * 0.14, sb[1] + sb[3] * 0.5, sb[2] * 1.28, sb[2] * 1.28 * 44 / 120)
        i = next(k for k, v in enumerate(out) if 'rgba(255,255,255,.5)' in v)   # the veil; the held thing comes next
        out.insert(i + 1, back)
    return out


def m_stamp(b, f):
    """SHP-B-09 with the real things: the tray of sand comes into the show spot; the can presses down and lifts, its face
    stays as a print (traced); then it goes to the circle bin."""
    show = SHOWS['show.shp-b-09']
    tiles = ['can', 'gift_box', 'party_hat'] if f < 3 else [None, 'gift_box', 'party_hat']

    def marks(boxes, where):
        out = []
        sx, sy, ss, _ = spot_box(b)
        trw = ss * 1.7
        trh = trw * 120 / 200
        trx, tr_y = sx + ss / 2 - trw / 2, sy + ss - trh + (6 if b == 'phone' else 10)
        if f < 3:
            out.append(img(os.path.join(SHOW, 'sand_tray.svg'), trx, tr_y, trw, trh))
        pw = ss * 0.42
        pcx, pcy = trx + trw / 2, tr_y + trh * 0.52
        ps = ss * 0.62
        if f == 2:
            out.append(img(os.path.join(SHOW, 'sand_print_circle.svg'), pcx - pw / 2, pcy - pw / 2, pw, pw))
            out.append(svg_at(pcx - pw / 2, pcy - pw / 2, pw, pw, '<circle cx="50" cy="50" r="36" fill="none" stroke="%s" stroke-width="11"/>'
                              '<circle cx="50" cy="50" r="36" fill="none" stroke="#fff" stroke-width="5"/>' % DEEP, view='0 0 100 100'))
            out.append(img(pic('can'), trx + trw - ps * 0.9, sy - ps * 0.05, ps, ps))
            out.append(pointer((trx + trw - ps * 0.2, sy + ps * 0.5), b, angle=-30))
        if f == 1:
            out.append(img(pic('can'), pcx - ps / 2, pcy - ps * 0.9, ps, ps, 'transform:scaleY(0.96);transform-origin:50% 100%'))
            out.append(pointer((pcx + ps * 0.36, pcy - ps * 0.45), b, angle=-30))
        return out
    done = {'b1': ['can']} if f == 3 else None
    return sort_board(b, show, tiles, marks, done=done, spot=(0, None) if f < 3 else None)


def builder_board(b, f):
    """Shape builder Shows: (1) SHP-A-01: Kubi's finger circles the round hole of the sorter before the circle drops in;
    (2) the turn of a piece: a fin of the rocket turns (rotate_ccw) to its place; (3) SHP-B-06 with the half triangles."""
    out = M.base(b, ROOM, n=6, done=1)

    def inner(ix, iy, iw, ih):
        parts = []
        if f == 1:
            sc = SHOWS['show.shp-a-01']['scene']
            H = ih - 16
            W = H * sc['aspect']
            x0, y0 = ix + iw - W - 30, iy + 8
            for s in sc['slots']:
                x, y, w, h = x0 + s['x'] * W, y0 + s['y'] * H, s['w'] * W, s['h'] * H
                parts.append('<div style="position:absolute;left:%gpx;top:%gpx;width:%gpx;height:%gpx;filter:brightness(0) opacity(.3)">'
                             '<img src="%s" style="width:100%%;height:100%%"></div>' % (x, y, w, h, M.uri(pic(sprite_of(s['sprite'])))))
            s = sc['slots'][0]
            pb = (x0 + s['x'] * W, y0 + s['y'] * H, s['w'] * W, s['h'] * H)
            parts.append(trace(pb, 'M12 50 A38 38 0 1 1 88 50 A38 38 0 1 1 12 50', b, partial=75))
            parts.append(pointer(at(pb, 50 + 38 * math.cos(math.radians(-10)), 50 + 38 * math.sin(math.radians(-10))), b))
        elif f == 2:
            act = json.load(open(os.path.join(PICS, 'activity.shp.build.rocket.json'), encoding='utf-8'))
            sc = act['scene']
            H = ih - 12
            W = H * sc['aspect']
            x0, y0 = ix + iw - W - 30, iy + 6
            for s in sc['slots']:
                x, y, w, h = x0 + s['x'] * W, y0 + s['y'] * H, s['w'] * W, s['h'] * H
                filled = s['id'] in ('s1', 's2', 's3', 's5')
                parts.append('<div style="position:absolute;left:%gpx;top:%gpx;width:%gpx;height:%gpx;transform:rotate(%gdeg);%s">'
                             '<img src="%s" style="width:100%%;height:100%%"></div>' % (
                                 x, y, w, h, s['rot'], '' if filled else 'filter:brightness(0) opacity(.3)',
                                 M.uri(pic(sprite_of(s['sprite'])) if filled else pic(sprite_of(s['sprite'])))))
            s = sc['slots'][3]
            w, h = s['w'] * W, s['h'] * H
            gx, gy = x0 - w * 1.25, y0 + s['y'] * H - 4
            parts.append('<div style="position:absolute;left:%gpx;top:%gpx;width:%gpx;height:%gpx;transform:rotate(-12deg)">'
                         '<img src="%s" style="width:100%%;height:100%%"></div>' % (gx, gy, w, h, M.uri(pic('shape_triangle_red'))))
            parts.append(img(os.path.join(SHOW, 'rotate_ccw.svg'), gx - w * 0.15, gy - h * 0.15, w * 1.3, h * 1.3))
            parts.append(pointer((gx + w * 0.5, gy + h * 0.75), b))
        else:
            s = ih - 20
            x0 = ix + iw - s - 40
            y0 = iy + 10
            parts.append(svg_at(x0, y0, s, s, '<path d="M14 14 H86 V86 H14 Z" fill="#000" opacity="0.3"/>', view='0 0 100 100'))
            parts.append(img(pic('shape_triangle_half_blue'), x0, y0, s, s))
            gx = ix + 40
            parts.append(img(pic('shape_triangle_half_blue'), gx, y0 + 6, s * 0.86, s * 0.86, 'transform:rotate(120deg)'))
            parts.append(img(os.path.join(SHOW, 'rotate_cw.svg'), gx + s * 0.1, y0 + 6 + s * 0.1, s * 0.66, s * 0.66))
            parts.append(pointer((gx + s * 0.43, y0 + 6 + s * 0.8), b))
        return parts
    out += M.stage(b, ROOM, inner, landmark=False)
    tiles = {1: ['shape_triangle'], 2: ['shape_triangle_red'], 3: ['shape_triangle_half_blue']}[f]
    tp, _ = tile_row(tiles, b)
    out += tp
    out += M.duo(b, ROOM, os.path.join(CAST, 'kubi-show.svg'))
    return out


MOTIONS = [
    ('trace', 'TRACE a side (A-03, A-05, A-10, B-05; the sorter\'s hole of A-01)', m_trace,
     ['1. the pointer\'s tip runs along side 1; the line draws behind it', '2. sides 1 and 2 stay lit; side 3 on its way',
      '3. the open figure: the line stops at the gap, a dashed ring pulses there']),
    ('count', 'COUNT the sides one by one (B-01, B-02)', m_count,
     ['1. side 1 lights, badge 1 pops outside it', '2. three sides, badges 1 2 3: "three"', '3. the triangle sits in the 3-stick bin; '
                                                                                           'the square: 1, 2 ...']),
    ('sticks', 'STICKS on the sides, lined up to compare (A-04, B-03)', m_sticks,
     ['1. a stick lies on each side of the long rectangle', '2. the shape slides to the start side, the sticks line up at the end side: two long, two short',
      '3. the rectangle in "not a square"; the sticks fade as it goes']),
    ('walk', 'The ANT WALK round the outline (B-04)', m_walk,
     ['1. the ant starts at its home dot and walks; the walked sides light', '2. home again on the pentagon: a small hop',
      '3. the open figure: the ant walks out through the gap (dashed ring)']),
    ('push', 'PUSH and STACK (A-07)', m_push,
     ['1. the same push, from the end side: the pointer behind the ball', '2. the ball rolled into "rolls"; the block, pushed, stays (a wobble)',
      '3. the block stacked on the bin\'s box; the child\'s turn']),
    ('turn', 'TURN a solid round (B-08, with the real things)', m_turn,
     ['1. the hat turns (orbit arrow round its waist); a ring at its one point', '2. the can turns; its two circles are traced',
      '3. the can in "cylinder"']),
    ('stamp', 'STAMP in the sand (B-09)', m_stamp,
     ['1. the can presses into the tray (squash 0.96)', '2. it lifts; the circle print stays and is traced',
      '3. the can in the circle bin; the print stays till the item ends']),
    ('build', 'The BUILDER: the hole, the turn of a piece, two halves (A-01, A-06, B-06)', builder_board,
     ['1. A-01: the finger circles the round hole before the circle drops in', '2. a fin turns (rotate_ccw) to its place',
      '3. B-06: half a square in, the other half turns 180 on its way']),
]


def motions_sheet():
    cells = []
    for key, title, fn, notes in MOTIONS:
        for f in (1, 2, 3):
            parts = crop(fn('phone', f), *PH_CROP)
            cells.append((parts, PH_CROP[2], PH_CROP[3], ('%s\n' % title if f == 1 else '\n') + 'phone ' + notes[f - 1]))
        tl = crop(fn('tabletL', 2), *TL_CROP)
        cells.append((tl, TL_CROP[2], TL_CROP[3], 'tablet landscape, frame 2'))
    # the whole host beat: Kubi's show pose in the corner, his pointer in the scene
    key = lambda sid, role: next(l['text'] for l in SHOWS[sid]['lines'] if l['role'] == role)
    whole = [(m_trace('phone', 1, line=key('show.shp-a-03', 'open')), 852, 393,
              'phone, the whole host beat: Kubi in front (show pose, 168), the companion behind, his open line in the bubble; '
              'the thing is held up in the show spot (the bins wait under a veil), his pointer comes from below.'),
             (m_trace('phone', 2, line=key('show.shp-a-03', 'key')), 852, 393,
              'phone, the same with the KEY line of show.shp-a-03 (12 words). This board does not shrink the font as fitBubble does, '
              'but 12 words are far over the two lines of the host bubble at the band size (hebrew-text-editor).'),
             (m_count('tabletL', 2, line=key('show.shp-b-02', 'key')), 1180, 820, 'tablet landscape, the whole host beat (count), '
                                                                                  'with its key line.')]
    M.page(whole + cells, os.path.join(HERE, 'stage2_show_motions.png'), 4 * (PH_CROP[2] + 20) + 120, scale=1.0)


def main():
    shapes_sheet()
    solids_sheet()
    motions_sheet()


if __name__ == '__main__':
    main()
