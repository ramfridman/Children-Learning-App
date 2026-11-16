"""Mocks of the redesigned pattern-strip sort (LOG-A-04, docs/design/m11/min-sizes.md section 3), one per board, drawn at real size in
points with the app's own pictures (content/starter/strip_*.svg, tick.svg, cross.svg), the Riddle Grotto backdrop and the cast, and
rendered by headless Chrome:

    python docs/design/m11/min-sizes/make_strip_sort_mocks.py

  strip_sort_phone.png      phone 852 x 393: start (the deck of four in the tray) and sorted (three in the shelves, one in the tray)
  strip_sort_phoneSE.png    phone SE 667 x 375: the same two states
  strip_sort_phone_t13.png  phone at text size 1.3 (the sign column widens from 72 to 100, the cards keep their size)
  strip_sort_tabletL.png    tablet landscape 1180 x 820: sorted, two left in the 2 x 2 tray
  strip_sort_tabletP.png    tablet portrait 820 x 1180: sorted, the "repeats" bin holding two rows, one left in the tray

The numbers are the ones of the spec's tables (section 3.3); the frame (controls, trail, bubble, guide) is make_m11_boards.py's, which reads
ActivitySpec. Reference for the developer, not a screenshot of the running app.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..'))
import make_m11_boards as M   # noqa: E402

PICS, CAST, C = M.PICS, M.CAST, M.C
box, img, esc = M.box, M.img, M.esc
ROOM = M.ROOM['logic']
PROMPT = 'הַסֵּדֶר חוֹזֵר שׁוּב וְשׁוּב? מְמַיְּנִים.'
YES, NO = 'חוֹזֵר', 'לֹא חוֹזֵר'
STRIP = {k: os.path.join(PICS, 'strip_%s.svg' % k) for k in ('cat_dog', 'fish_bird', 'red_blue_slip', 'mixed_balls')}

# ---- the numbers of section 3.3 ---------------------------------------------------------------------------------------------
L = {
    'phone': dict(stage=(24, 96, 377, 260), card=False, inset=8, gap=12, orient='shelves', sign=72, sign13=100, mark=44, label=18,
                  binCard=(190, 76), rows=1, edge=6, badge=(32, 20), tray=dict(kind='deck', x=417, y=270, w=184, h=88, card=(176, 70))),
    'phoneSE': dict(stage=(24, 86, 264, 256), card=False, inset=6, gap=12, orient='shelves', sign=60, sign13=60, mark=40, label=18,
                    binCard=(170, 68), rows=1, edge=5, badge=(30, 20), tray=dict(kind='deck', x=306, y=250, w=196, h=86, card=(188, 75))),
    'tabletL': dict(stage=(24, 230, 848, 270), card=True, inset=8, gap=12, orient='bins', head=60, mark=48, label=24,
                    binCard=(300, 120), rows=1, edge=6, badge=(40, 24), tray=dict(kind='grid', cols=2, x0=136, y=524, w=300, h=112, gx=24,
                                                                                   gy=16, card=(250, 100))),
    'tabletP': dict(stage=(24, 372, 772, 420), card=True, inset=8, gap=12, orient='bins', head=60, mark=48, label=24,
                    binCard=(280, 112), rows=2, edge=6, badge=(40, 24), tray=dict(kind='grid', cols=2, x0=58, y=816, w=340, h=128, gx=24,
                                                                                   gy=16, card=(300, 120))),
}


def strip_card(name, x, y, w, h):
    return img(STRIP[name], x, y, w, h)


def deck_edges(x, y, w, h, n, step):
    """n cards lying under the top one, each `step` up and to the end side (left), so that the pile reads as more than one."""
    out = []
    for k in range(min(n, 2), 0, -1):
        out.append(box(x - k * step, y - k * step, w, h, 'background:#fff;border:1.8px solid %s;border-radius:%dpx;opacity:%.2f' % (
            C['ink'], h * 8 / 48, 1 - 0.18 * k)))
    return out


def badge(cx, cy, d, font, n):
    return [box(cx - d / 2, cy - d / 2, d, d, 'border-radius:50%%;background:%s;border:2.5px solid #fff;box-shadow:0 2px 4px '
                'rgba(43,35,80,.25);display:flex;align-items:center;justify-content:center' % C['ink'],
                '<span dir="ltr" style="font:800 %dpx/1 H;color:#fff">%d</span>' % (font, n))]


def label(text, x, y, w, font, lines=1):
    return [box(x, y, w, font * 1.7 * lines, 'display:flex;align-items:center;justify-content:center;text-align:center',
                '<span dir="rtl" lang="he" style="font:500 %dpx/1.7 H;color:%s">%s</span>' % (font, C['ink'], esc(text)))]


def bin_box(x, y, w, h, lit=False):
    return box(x, y, w, h, 'background:rgba(255,255,255,.9);border:%dpx solid %s;border-radius:16px' % (
        5 if lit else 3, C['sparkDeep'] if lit else C['hairline']))


def pile(o, x, y, w, h, names):
    """The cards of one bin in its well (x, y, w, h): as many rows as the board's `rows`, the rest under the last one as a pile, and the
    count badge from two cards."""
    cw, ch = o['binCard']
    out = []
    if not names:
        return out
    rows = min(o['rows'], len(names))
    under = len(names) - rows
    total_h = rows * ch + (rows - 1) * 10 + (min(under, 2) * o['edge'])
    top = y + (h - total_h) / 2 + min(under, 2) * o['edge']
    left = x + (w - cw) / 2 + min(under, 2) * o['edge'] / 2
    for r in range(rows):
        cy = top + r * (ch + 10)
        if r == rows - 1 and under:
            out += deck_edges(left, cy, cw, ch, under, o['edge'])
        out.append(strip_card(names[len(names) - rows + r], left, cy, cw, ch))
    if under:
        d, f = o['badge']
        out += badge(left - min(under, 2) * o['edge'] + 4, top - min(under, 2) * o['edge'] + 4, d, f, len(names))
    return out


def stage_parts(b, sorted_yes, sorted_no, t13=False, lit=None):
    o = L[b]
    M.B[b]['stage'] = o['stage']
    M.B[b]['card'] = o['card']

    def inner(ix, iy, iw, ih):
        out = []
        p, g = o['inset'], o['gap']
        if o['orient'] == 'shelves':
            sh = (ih - 2 * p - g) / 2
            sw = iw - 2 * p
            sign = o['sign13'] if t13 else o['sign']
            font = o['label'] * (1.3 if t13 and o['sign13'] > o['sign'] else 1)
            for k, (lab, mark, names) in enumerate(((YES, 'tick.svg', sorted_yes), (NO, 'cross.svg', sorted_no))):
                sx, sy = ix + p, iy + p + k * (sh + g)
                out.append(bin_box(sx, sy, sw, sh, lit == k))
                # the sign column on the start side (right): the mark, the label under it (two lines where one does not fit)
                cx = sx + sw - sign / 2 - 4
                lines = 1
                block = o['mark'] + 2 + font * 1.7 * lines
                ty = sy + (sh - block) / 2
                out.append(img(os.path.join(PICS, mark), cx - o['mark'] / 2, ty, o['mark'], o['mark']))
                out += label(lab, cx - sign / 2, ty + o['mark'] + 2, sign, font, lines)
                wx, ww = sx + 8, sw - sign - 16
                out += pile(o, wx, sy + 6, ww, sh - 12, names)
        else:
            bw = (iw - 2 * p - g) / 2
            bh = ih - 2 * p
            for k, (lab, mark, names) in enumerate(((YES, 'tick.svg', sorted_yes), (NO, 'cross.svg', sorted_no))):
                bx = ix + iw - p - (k + 1) * bw - k * g      # the first bin at the right (the language's way)
                by = iy + p
                out.append(bin_box(bx, by, bw, bh, lit == k))
                # header: the mark and the label side by side, centred
                lw = o['label'] * 0.55 * len(lab) + 8
                hx = bx + (bw - (o['mark'] + 10 + lw)) / 2
                out.append(img(os.path.join(PICS, mark), hx + lw + 10, by + (o['head'] - o['mark']) / 2 + 4, o['mark'], o['mark']))
                out += label(lab, hx, by + (o['head'] - o['label'] * 1.7) / 2 + 4, lw, o['label'])
                out += pile(o, bx + 12, by + o['head'], bw - 24, bh - o['head'] - 8, names)
        return out
    return M.stage(b, ROOM, inner, landmark=False)


def tray_parts(b, names, dragging=None):
    t = L[b]['tray']
    out = []
    cw, ch = t['card']

    def tile(x, y, w, h, name, sel=False):
        o = [box(x, y, w, h, 'background:#fff;border:4px solid %s;border-radius:24px;box-shadow:0 6px 0 %s,0 6px 16px rgba(43,35,80,.14)' % (
            C['spark'] if sel else C['hairline'], C['lip']))]
        o.append(strip_card(name, x + (w - cw) / 2, y + (h - ch) / 2, cw, ch))
        return o
    if t['kind'] == 'deck':
        if not names:
            return out
        under = len(names) - 1
        for k in range(min(under, 2), 0, -1):
            out.append(box(t['x'] + k * 6, t['y'] + k * 6, t['w'], t['h'], 'background:#fff;border:3px solid %s;border-radius:24px;'
                           'box-shadow:0 4px 0 %s' % (C['hairline'], C['lip'])))
        out += tile(t['x'], t['y'], t['w'], t['h'], names[0])
    else:
        for i, n in enumerate(names):
            r, c = divmod(i, t['cols'])
            # right to left: the first tile at the right
            x = t['x0'] + (t['cols'] - 1 - c) * (t['w'] + t['gx'])
            y = t['y'] + r * (t['h'] + t['gy'])
            out += tile(x, y, t['w'], t['h'], n)
    return out


def board(b, yes, no, tray, t13=False, caption=''):
    W, H = M.B[b]['W'], M.B[b]['H']
    parts = M.base(b, ROOM)
    parts += stage_parts(b, yes, no, t13)
    parts += tray_parts(b, tray)
    parts += M.bubble(b, PROMPT)   # the frame fits the caption in its box at any text size (captionFloor)
    parts += M.alone(b)
    return (parts, W, H, caption)


def main():
    out = []
    jobs = [
        ('phone', [
            board('phone', [], [], ['cat_dog', 'red_blue_slip', 'fish_bird', 'mixed_balls'],
                  caption='phone START: stage 24,96 377x260 (two shelves 361x116); tray deck under the bubble: tile 184x88 at 417,270, '
                          'card 176x70 (animal 25 pt), two cards waiting show as edges.'),
            board('phone', ['cat_dog', 'fish_bird'], ['red_blue_slip'], ['mixed_balls'],
                  caption='phone SORTED: a shelf shows its last card 190x76 (animal 27 pt), the earlier one as an edge, badge 32 with "2" '
                          '(20 pt). Sign column 72: tick/cross 44, label 18 pt w500.'),
        ], 'strip_sort_phone.png', 1744),
        ('phoneSE', [
            board('phoneSE', [], [], ['cat_dog', 'red_blue_slip', 'fish_bird', 'mixed_balls'],
                  caption='phone SE START: stage 24,86 264x256 (shelves 252x116); tray deck: tile 196x86 at 306,250, card 188x75 (animal 27 pt).'),
            board('phoneSE', ['cat_dog', 'fish_bird'], ['red_blue_slip'], ['mixed_balls'],
                  caption='phone SE SORTED: shelf card 170x68 (animal 24 pt), sign column 60: mark 40, label 18 pt.'),
        ], 'strip_sort_phoneSE.png', 1394),
        ('phone13', [
            board('phone', ['cat_dog', 'fish_bird'], ['red_blue_slip'], ['mixed_balls'], t13=True,
                  caption='phone, TEXT SIZE 1.3: the labels 23.4 pt in a sign column of 100; the cards keep 190x76; the bubble keeps its box (the frame fits its caption).'),
        ], 'strip_sort_phone_t13.png', 892),
        ('tabletL', [
            board('tabletL', ['cat_dog', 'fish_bird'], ['red_blue_slip'], ['mixed_balls'],
                  caption='tablet landscape SORTED: wide card 24,230 848x270 (withWideStage), bins 394x222, header 60 (mark 48 + label 24 pt), '
                          'card 300x120 (animal 43 pt), badge 40 / 24 pt; tray 2x2 tiles 300x112 at y 524, card 250x100 (animal 36 pt).'),
        ], 'strip_sort_tabletL.png', 1200),
        ('tabletP', [
            board('tabletP', ['cat_dog', 'fish_bird'], ['red_blue_slip'], ['mixed_balls'],
                  caption='tablet portrait SORTED: card 24,372 772x420, bins 356x372, two rows of 280x112 (animal 40 pt); '
                          'tray 2x2 tiles 340x128 at y 816, card 300x120 (animal 43 pt).'),
        ], 'strip_sort_tabletP.png', 840),
    ]
    for _, boards, name, width in jobs:
        M.page(boards, os.path.join(HERE, name), width)


if __name__ == '__main__':
    main()
