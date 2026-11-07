"""Batch 5 of the shared Languages pictures: what the three teachers still needed for Band A
(docs/languages/english/band-a-pictures-needed.md, docs/languages/hebrew/band-a-pictures-needed.md, and the Russian units'
waiting lists: content/languages/rus/pending/11-numbers-6-10.json and content/languages/rus/units/03-body.json).

    python tools/make_language_pictures_band_a.py           # writes the SVGs and the tap-area maps
    python tools/make_language_pictures_band_a.py --sheet   # and the contact sheets (pictures_batch5a.png, ...)

Writes content/languages/pictures/<id>.svg (256 x 256 like the objects) and, next to a picture with tap areas,
<id>.hotspots.json in the version-2 format of mika-body.hotspots.json (shares of the picture, a list of rectangles per part):

- the Hebrew "many" sets (HEB-A-05): set-cats, set-dogs, set-dolls, set-teddies, set-cakes, set-pizzas, set-horses,
  set-donkeys, set-boats, set-planes, set-eggs, set-apples. Each is the singular picture's own drawing, three to five times, in
  one natural group (back row, front row, a little overlap), never a counting layout, all the same size;
- the Russian ten-frames (RUS-A-11): set-tenframe-5 to set-tenframe-10, red play balls (the ball of set-balls-1 to 5) in a
  2 x 5 frame, filled the standard way: the top row left to right, then the bottom row left to right. Five is a full top row,
  so 6 to 10 read as "five and some more" at a glance. The frame is maths, so it is drawn left to right in every course and
  never mirrored (CLAUDE.md, design-spec 8). 5 is drawn too: RUS-A-11 item 06 uses it as the distractor of 6;
- the English lit sprites for count_tap (ENG-A-04 i06, i07): duckling-lit and ball-lit, the same drawing in the same place as
  duckling and ball, with the soft gold glow of a touched object behind it (as content/starter/*_lit.svg);
- the Russian doll (RUS-A-03 items 12 to 15): doll-body, the doll of doll.svg sitting on a rug with its legs out and its arms
  open, its head large like a rag doll's, so that ears, eyes and arms (item 13), legs, arms and nose (14) and belly, head and legs
  (15) each have a 72-unit place that does not touch the others; item 12 (nose, mouth and eyes, which cannot be 64 pt apart on
  any face) is three close-up cards, doll-eyes, doll-nose and doll-mouth, as on Mika (docs/design/languages-l4-layout.md 2);
- the tap-area maps of dog-big and ball-pair (ENG-A-10 i01 to i04: the big and the small one) and of story-bounce-2 to -5
  (ENG-A-15 s01: the word said when its picture is touched);
- shape cards for HEB-A-10 (letters or not): shape-dot, shape-ring, shape-triangle, shape-triangle-open, the four marks
  U+25CF, U+25CB, U+25B2 and U+25B3 drawn as pictures, because Heebo (and Secular One) has no glyph for any of them.

Batch 6 (2026-11-07, contact sheet pictures_batch6a.png):
- the Russian rooms for RUS-A-13 items 01 to 05 (Где ...? LS11 scene search): scene-room-ball, -cat, -mouse, -hat, -apple, one
  square room (the listen_do scene is a square) with the item's three things drawn into their places, and a tap-area map each
  (parts named by the option's picture id); scene-garden-family for item 06 (papa, mama, babushka of the approved family,
  standing in the garden) with its map;
- the tap-area maps of the Russian story pages st1-p1 (sobaka, mjach) and st2-p1 (jozhik) for RUS-A-16 01 and 04;
- shape-heart and shape-flower for HEB-A-10 t05 and s06, in ink at the weight of shape-dot (U+2665 and U+273F as pictures).

Same house style as batches 1 to 4 (tools/make_language_pictures.py): flat shapes, the ink outline, one soft shade, a white
highlight, no text, no numeral, no franchise look.

References looked at on 2026-11-07 (facts and photographs; the drawings are ours, nothing traced):
  Ten-frame: classroom ten-frames and counters (Bing image search "ten frame counters classroom": white plastic or card frames,
    2 rows of 5 square cells with dark lines, round red, blue or yellow counters) and the fill convention: top row first, left to
    right, then the bottom row (Kendall Hunt / Illustrative Mathematics kindergarten unit 5 lesson 10,
    https://im.kendallhunt.com/k5/teachers/kindergarten/unit-5/lesson-10/lesson.html; Math Recovery "Fill the Board to 10").
  Rag doll: https://en.wikipedia.org/wiki/Rag_doll (stuffed cloth body and head, simple features, patchwork clothes),
    Wikimedia Commons search "rag doll" and Bing image search "rag doll sitting legs apart front view" (photographs of cloth
    dolls sitting with the legs straight out in a V, a big round head, yarn hair in bunches, rosy cheeks, a dress, striped
    stockings and little shoes; the arms soft and a little out). Ours keeps doll.svg's colours (orange yarn hair, blue bows,
    a purple dress with cream dots, pink-striped socks, red shoes), with the bunches high so the ears show.
  Giving an apple (the Russian spasibo picture, redrawn in tools/make_language_people.py): Bing image search "grandmother giving
    apple to child illustration" (a grown-up bends a little toward the child and holds the apple out at the child's chest
    height; the child reaches for it).
  Children's room (batch 6): Bing image search "children's bedroom illustration window wall shelf round rug toys" (picture-book
    rooms: a window with short curtains and a sill, a wall shelf on brackets, an oval rug on a board floor, a skirting board,
    toys on the rug and the shelf, a cat on the sill). The lying scarf: a knitted scarf dropped on a floor lies folded in two,
    the fringed ends side by side (an S would read as a snake); its colours are scarf.svg's.
  Heart and florette: the glyphs U+2665 and U+273F as Windows draws them (Segoe UI Symbol, rendered in Chrome): a filled heart
    of two round lobes and a point; five round filled petals round a small open centre. Ours are drawn from circles and curves.
  The objects in the sets carry the references of their own drawings (tools/make_language_pictures.py and _b2.py).
"""
import json
import math
import re
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_language_pictures as m  # noqa: E402
import make_language_pictures_b2 as b2  # noqa: E402
import make_language_scenes as sc  # noqa: E402
import make_language_people as pe  # noqa: E402
import make_language_characters as ch  # noqa: E402

ROOT, OUT = m.ROOT, m.OUT
INK, WHITE, CREAM = m.INK, m.WHITE, m.CREAM
f = pe.f
P, L, E, RR = pe.P, pe.L, pe.E, pe.RR
HIT = 72            # a listen_do area: 72 of 256 units is 65.5 pt on the phone SE's 233 pt scene square
STORY_HIT = 96      # a story page area: 96 of 384 (and of 216) units is 64.5 pt on the SE's 258 x 145 pt page (tall stage)
GLOW_FILL, GLOW_RING = '#FFE680', '#FFC83D'


def obj(pic, x, y, s, flip=False):
    return sc.obj(pic, x, y, s, flip=flip)


# ---- the Hebrew "many" sets (HEB-A-05) -------------------------------------------------------------------------------
# (x, y) is the bottom centre of each copy; back row first, so the front copies overlap the back ones.

def group(pic_fn, spots, s):
    return sc.composite([obj(pic_fn(), x, y, s) for x, y in spots])


MANY = {
    'set-cats': (m.cat, 0.52, [(98, 150), (186, 156), (62, 240), (152, 244)]),
    'set-dogs': (m.dog, 0.54, [(96, 152), (190, 160), (134, 244)]),
    'set-dolls': (m.doll, 0.5, [(96, 146), (180, 152), (62, 240), (150, 244)]),
    'set-teddies': (m.teddy, 0.56, [(88, 156), (176, 150), (132, 246)]),
    'set-cakes': (m.cake, 0.52, [(84, 148), (174, 142), (130, 236)]),
    'set-pizzas': (b2.pizza, 0.54, [(82, 136), (176, 128), (128, 226)]),
    'set-horses': (m.horse, 0.56, [(94, 154), (186, 148), (136, 246)]),
    'set-donkeys': (b2.donkey, 0.56, [(94, 154), (186, 148), (136, 246)]),
    'set-boats': (lambda: m.boat('red'), 0.5, [(94, 150), (180, 146), (66, 244), (162, 246)]),
    'set-planes': (b2.plane, 0.54, [(92, 120), (186, 168), (104, 238)]),
    'set-eggs': (m.egg, 0.42, [(68, 150), (130, 144), (192, 150), (98, 238), (164, 242)]),
    'set-apples': (m.apple, 0.42, [(66, 150), (128, 144), (190, 150), (96, 238), (162, 242)]),
}


def many_sets():
    return {pid: group(fn, spots, s) for pid, (fn, s, spots) in MANY.items()}


# ---- the Russian ten-frames (RUS-A-11) -------------------------------------------------------------------------------

TF_X, TF_Y, TF_CELL = 14, 82, 45.6      # the cells: 5 x 45.6 = 228 wide (14 to 242), 2 x 45.6 = 91.2 high (82 to 173)


def counter(cx, cy, r):
    """The red play ball of set-balls, without its ground shadows, centred at (cx, cy) with radius r."""
    pic = m.ball('red')
    parts = [q for q in pic.parts if not (q.startswith('<ellipse') and 'opacity=' in q)]
    # the pebbled finish is too fine to see at counter size (and would make ten balls a heavy file): left out
    parts = [re.sub(r'<circle cx="\d+" cy="\d+" r="1.6"[^>]*/>', '', q) for q in parts]
    k = r / 92.0
    return '<g transform="translate(%s %s) scale(%s) translate(-128 -130)">%s</g>' % (f(cx), f(cy), f(k), sc.unique(''.join(parts), sc.tag()))


def ten_frame(n):
    x, y, c = TF_X, TF_Y, TF_CELL
    w, h = 5 * c, 2 * c
    parts = ['<rect x="%s" y="%s" width="%s" height="%s" rx="10" fill="%s" opacity="0.12"/>' % (f(x + 2), f(y + 8), f(w), f(h), INK),
             P(m.rrect(x - 8, y - 8, w + 16, h + 16, 16), '#B9A2F7', 4),     # the tray, a soft lilac plastic frame
             P(m.rrect(x, y, w, h, 8), WHITE, 0)]                              # the cells, white
    grid = ''.join('M %s %s L %s %s ' % (f(x + k * c), f(y), f(x + k * c), f(y + h)) for k in range(1, 5))
    grid += 'M %s %s L %s %s' % (f(x), f(y + c), f(x + w), f(y + c))
    parts.append(L(grid, INK, 3.5))
    parts.append(P(m.rrect(x, y, w, h, 8), 'none', 4))
    for k in range(n):   # top row left to right, then the bottom row left to right (never mirrored)
        row, col = divmod(k, 5)
        parts.append(counter(x + col * c + c / 2, y + row * c + c / 2, c * 0.4))
    return sc.composite(parts)


def ten_frames():
    return {'set-tenframe-%d' % n: ten_frame(n) for n in range(5, 11)}


# ---- the lit sprites for count_tap (ENG-A-04) ------------------------------------------------------------------------

def lit(pic, cx, cy, r):
    """The object as drawn, with the soft gold glow of a touched object behind it (the object does not move)."""
    halo = ['<circle cx="%s" cy="%s" r="%s" fill="%s" opacity="0.75"/>' % (f(cx), f(cy), f(r), GLOW_FILL),
            '<circle cx="%s" cy="%s" r="%s" fill="none" stroke="%s" stroke-width="7" opacity="0.85"/>' % (f(cx), f(cy), f(r - 4), GLOW_RING)]
    return pe.compact('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">'
                      '<g stroke-linejoin="round" stroke-linecap="round">%s</g></svg>\n' % ''.join(halo + pic.parts))


def lit_sprites():
    return {'duckling-lit': lit(m.duckling(), 128, 136, 115), 'ball-lit': lit(m.ball('red'), 128, 132, 115)}


# ---- the doll for RUS-A-03 items 12 to 15 ----------------------------------------------------------------------------

HAIR, HAIR_S, SKIN, SKIN_S, DRESS, DRESS_S, BOW = '#E8743B', '#C85A26', '#F2C9A0', '#E0AE84', '#8A5CF0', '#6C40D0', '#2F7FE0'


def doll_parts(rug=True):
    p = m.Pic()
    if rug:
        p.add('<ellipse cx="128" cy="228" rx="122" ry="26" fill="#FCE1F0" stroke="#F4B6D2" stroke-width="3"/>')
        p.add('<ellipse cx="128" cy="228" rx="100" ry="18" fill="none" stroke="#F4B6D2" stroke-width="3" stroke-dasharray="2 9"/>')
    p.shadow(cy=226, rx=96, ry=9)
    # legs: straight out in a V from the hips, pink-striped socks, red shoes with the soles to the viewer
    for hx, ax in ((116, 58), (140, 198)):
        hy, ay = 190, 226
        ang = math.atan2(ay - hy, ax - hx)
        ux, uy, nx, ny = math.cos(ang), math.sin(ang), -math.sin(ang), math.cos(ang)
        leg = 'M %s %s L %s %s' % (hx, hy, ax, ay)
        p.line(leg, INK, 26 + 7)
        p.line(leg, SKIN, 26)
        t0 = 0.5
        sx, sy = hx + (ax - hx) * t0, hy + (ay - hy) * t0
        p.line('M %s %s L %s %s' % (f(sx), f(sy), ax, ay), WHITE, 26)
        for t in (0.62, 0.76, 0.9):
            x0, y0 = hx + (ax - hx) * t, hy + (ay - hy) * t
            p.line('M %s %s L %s %s' % (f(x0 - nx * 12), f(y0 - ny * 12), f(x0 + nx * 12), f(y0 + ny * 12)), '#E04F9E', 5)
        p.add('<path d="M %s %s L %s %s M %s %s L %s %s" fill="none" stroke="%s" stroke-width="3.5"/>'
              % (f(sx + nx * 13), f(sy + ny * 13), f(ax + nx * 13), f(ay + ny * 13), f(sx - nx * 13), f(sy - ny * 13),
                 f(ax - nx * 13), f(ay - ny * 13), INK))
        cx, cy = ax + ux * 10, ay + uy * 10
        rot = math.degrees(ang) + 90
        p.add('<g transform="translate(%s %s) rotate(%s)">%s%s</g>' % (f(cx), f(cy), f(rot), P(m.ell(0, 0, 17, 22), '#E53935', 4),
                                                                       P(m.ell(0, 3, 9, 13), '#B8282A', 0)))
    # arms: soft and open, out to the sides, a little down
    for sx_, hx_, hy_ in ((100, 38, 166), (156, 218, 166)):
        arm = 'M %s 146 Q %s %s %s %s' % (sx_, (sx_ + hx_) / 2, 146, hx_, hy_)
        p.line(arm, INK, 24 + 7)
        p.line(arm, SKIN, 24)
        p.path(m.ell(hx_, hy_, 15, 14), SKIN)
    # the dress, a collar
    did = p.shaded('M 100 132 L 156 132 C 166 150, 178 174, 182 196 C 158 208, 98 208, 74 196 C 78 174, 90 150, 100 132 Z',
                   DRESS, DRESS_S, k=8)
    p.clipped(did, ''.join('<circle cx="%d" cy="%d" r="4.5" fill="%s"/>' % (x, y, CREAM)
                           for x, y in ((112, 150), (140, 146), (126, 168), (152, 172), (98, 184), (160, 190), (130, 192), (90, 194))))
    for x in (106, 150):   # short puffed sleeves over the shoulders
        p.path(m.ell(x, 142, 14, 11), DRESS)
    p.path('M 104 132 L 128 150 L 152 132 Z', CREAM, 3)
    # hair behind the head, the two high bunches with bows
    p.shaded(m.ell(128, 78, 60, 56), HAIR, HAIR_S, k=6)
    for x, d in ((70, -1), (186, 1)):
        p.shaded(m.ell(x, 38, 22, 20), HAIR, HAIR_S, k=5)
        p.line('M %d 28 Q %d 38 %d 48' % (x - 6 * d, x + 2 * d, x - 6 * d), HAIR_S, 2.5)
        p.path('M %d 52 L %d 42 L %d 62 Z' % (x - 4 * d, x - 18 * d, x - 18 * d), BOW, 3)
        p.path('M %d 52 L %d 42 L %d 62 Z' % (x - 4 * d, x + 10 * d, x + 10 * d), BOW, 3)
        p.path(m.ell(x - 4 * d, 52, 5, 5), BOW, 3)
    # ears, the face
    for x in (75, 181):
        p.path(m.ell(x, 92, 13, 16), SKIN, 4)
        p.fillp(m.ell(x + (2 if x < 128 else -2), 93, 6, 9), '#F4A9B8')
    p.shaded(m.ell(128, 88, 48, 46), SKIN, SKIN_S, k=6)
    p.path('M 80 84 C 78 26, 178 26, 176 84 C 162 66, 144 62, 128 70 C 112 62, 94 66, 80 84 Z', HAIR)
    p.line('M 104 62 L 102 72 M 128 64 L 128 72 M 152 62 L 154 72', HAIR_S, 2.5)
    p.eye(110, 90, 6.5)
    p.eye(146, 90, 6.5)
    p.add('<circle cx="98" cy="108" r="8" fill="#F48FB1" opacity="0.8"/><circle cx="158" cy="108" r="8" fill="#F48FB1" opacity="0.8"/>')
    p.path(m.ell(128, 102, 5, 4), '#E89A7A', 2.5)          # a little stitched button nose
    p.line('M 116 114 Q 128 124 140 114', INK, 3)
    return p.parts


# Where the doll's parts are (256 units, x, y, w, h); every area at least 72 x 72, padded round the drawn part.
DOLL_AREAS = {
    'head': [[72, 28, 112, 84]],
    'ears': [[20, 40, 72, 72], [164, 40, 72, 72]],
    'eyes': [[92, 40, 72, 72]],
    'nose': [[92, 64, 72, 72]],
    'mouth': [[92, 76, 72, 72]],
    'arms': [[0, 112, 92, 72], [164, 112, 92, 72]],
    'belly': [[92, 136, 72, 72]],
    'legs': [[12, 184, 80, 72], [164, 184, 80, 72]],
}
DOLL_ITEMS = {'rus.a03.12': ('nose', 'mouth', 'eyes'), 'rus.a03.13': ('ears', 'eyes', 'arms'),
              'rus.a03.14': ('legs', 'arms', 'nose'), 'rus.a03.15': ('belly', 'head', 'legs')}
DOLL_CARDS = {'eyes': 'doll-eyes', 'nose': 'doll-nose', 'mouth': 'doll-mouth', 'ears': 'doll-ears', 'arms': 'doll-arms',
              'head': 'doll-head', 'belly': 'doll-belly', 'legs': 'doll-legs'}


def overlap(a, b):
    return not (a[0] + a[2] <= b[0] or b[0] + b[2] <= a[0] or a[1] + a[3] <= b[1] or b[1] + b[3] <= a[1])


def check_areas(areas, wmax, hmax, hit):
    for name, rects in areas.items():
        for x, y, w, h in rects:
            assert w >= hit and h >= hit and x >= 0 and y >= 0 and x + w <= wmax and y + h <= hmax, (name, x, y, w, h)


def doll_map():
    check_areas(DOLL_AREAS, 256, 256, HIT)
    items = {}
    for item, parts in DOLL_ITEMS.items():
        apart = all(not overlap(p, q) for i, a in enumerate(parts) for b in parts[i + 1:] for p in DOLL_AREAS[a] for q in DOLL_AREAS[b])
        items[item] = {'parts': list(parts), 'show': 'body' if apart else 'cards'}
        if not apart:
            items[item]['cards'] = [DOLL_CARDS[p] for p in parts]
    assert [i for i, v in items.items() if v['show'] == 'cards'] == ['rus.a03.12'], items
    return {
        'picture': 'doll-body',
        'version': 2,
        'note': ("Touch areas of doll-body.svg (the doll of doll.svg sitting on a rug: RUS-A-03 items 12 to 15, the second "
                 "representation after Mika) as shares of the picture's side (x, y, w, h from the top left), as mika-body.hotspots.json. "
                 "Ears, arms and legs have two areas, either of which is the part. Every area is at least 72 of the 256 units (65.5 pt on "
                 "the phone SE). The three areas of an item shown on the doll never overlap; item 12 (nose, mouth, eyes) cannot be 64 pt "
                 "apart on a face and is shown as the three close-up cards doll-nose, doll-mouth, doll-eyes. hot.belly is 'belly'."),
        'minShare': round(HIT / 256.0, 4),
        'sceneSide': pe.BOARD_SIDE,
        'parts': {k: [[round(v / 256.0, 4) for v in r] for r in rects] for k, rects in DOLL_AREAS.items()},
        'cards': {k: v for k, v in DOLL_CARDS.items() if k in ('eyes', 'nose', 'mouth')},
        'items': items,
    }


def doll_pictures():
    base = doll_parts()
    face = doll_parts(rug=False)
    out = {'doll-body': pe.canvas(base, clip=False)}
    out['doll-eyes'] = pe.canvas(face + pe.glow(128, 90, 34, 16), crop=(62, 30, 132, 132))
    out['doll-nose'] = pe.canvas(face + pe.glow(128, 102, 12, 11), crop=(72, 46, 112, 112))
    out['doll-mouth'] = pe.canvas(face + pe.glow(128, 117, 20, 12), crop=(72, 58, 112, 112))
    return out


# ---- tap areas of the English pictures -------------------------------------------------------------------------------

def share_map(picture, areas, w, h, hit, note, items=None):
    check_areas(areas, w, h, hit)
    names = list(areas)
    for i, a in enumerate(names):    # no two areas of one picture overlap (each is a word or an answer of its own)
        for b in names[i + 1:]:
            assert not any(overlap(p, q) for p in areas[a] for q in areas[b]), (picture, a, b)
    out = {'picture': picture, 'version': 2, 'note': note, 'size': [w, h],
           'minShare': [round(hit / float(w), 4), round(hit / float(h), 4)],
           'parts': {k: [[round(r[0] / float(w), 4), round(r[1] / float(h), 4), round(r[2] / float(w), 4), round(r[3] / float(h), 4)]
                         for r in rects] for k, rects in areas.items()}}
    if items:
        out['items'] = items
    return out


BIG_SMALL_NOTE = ("Touch areas as shares of the picture's width and height (x, y, w, h from the top left), version 2 like "
                  "mika-body.hotspots.json; at least 72 of the 256 units (65.5 pt on the phone SE's 233 pt scene square); the two "
                  "never overlap. ENG-A-10 i01 to i04 (LS11 listen_do hotspots: the big one and the small one).")
STORY_NOTE = ("Touch areas of the page's words (scene.pages[].words[].at of the LS08 story) as shares of the page's width and "
              "height (x, y, w, h from the top left). Every area is at least 96 of the 384 x 216 units, 64.5 pt on the phone SE "
              "where the tall stage shows the page 258 x 145 pt; no two overlap. ENG-A-15 s01 uses the parts its words list names.")


def english_maps():
    out = {}
    out['dog-big'] = share_map('dog-big', {'big': [[4, 84, 160, 156]], 'small': [[164, 150, 88, 88]]}, 256, 256, HIT, BIG_SMALL_NOTE,
                               {i: {'parts': ['big', 'small'], 'show': 'body'} for i in ('ENG-A-10 i01', 'ENG-A-10 i02')})
    out['ball-pair'] = share_map('ball-pair', {'big': [[16, 88, 144, 148]], 'small': [[164, 156, 84, 84]]}, 256, 256, HIT,
                                 BIG_SMALL_NOTE, {i: {'parts': ['big', 'small'], 'show': 'body'} for i in ('ENG-A-10 i03', 'ENG-A-10 i04')})
    pages = {   # measured from the drawn pages (the bounding boxes of the placed drawings), padded to at least 96 units
        'story-bounce-2': {'cat': [[132, 88, 102, 120]], 'ball': [[34, 24, 98, 100]]},
        'story-bounce-3': {'duck': [[150, 104, 108, 104]], 'ball': [[30, 36, 100, 100]]},
        'story-bounce-4': {'frog': [[144, 104, 116, 108]], 'ball': [[150, 0, 100, 100]]},
        'story-bounce-5': {'dog': [[122, 60, 136, 134]], 'ball': [[24, 46, 98, 100]]},
    }
    for pid, areas in pages.items():
        out[pid] = share_map(pid, areas, 384, 216, STORY_HIT, STORY_NOTE)
    return out


# ---- the HEB-A-10 shape cards (letters or not) ----------------------------------------------------------------------
# Drawn in ink like a letter tile's glyph, at the weight of a Heebo Bold letter, centred, so a card reads beside a letter tile.

def shape_cards():
    tri = 'M 128 58 L 202 190 L 54 190 Z'
    return {
        'shape-dot': sc.composite([E(128, 128, 64, 64, INK, 0)]),
        'shape-ring': sc.composite(['<circle cx="128" cy="128" r="58" fill="none" stroke="%s" stroke-width="16"/>' % INK]),
        'shape-triangle': sc.composite([P(tri, INK, 10)]),
        'shape-triangle-open': sc.composite(['<path d="M 128 70 L 194 186 L 62 186 Z" fill="none" stroke="%s" stroke-width="15"/>' % INK]),
    }



# ---- batch 6: the Russian rooms (RUS-A-13 01 to 05), the family in the garden (06), the heart and the flower ------------
# A listen_do scene is a square (the app draws the picture in its scene square and reads the areas as shares of its side), so
# the rooms are 256 x 256, not the 384 x 216 background `scene-room`: one room (the lilac wall, the window with its sill and
# curtains, the wall shelf, the rug), with the item's three things drawn into it, each in a place of its own: on the shelf, on
# the window sill, on the rug or on the floor by the window. Where the right one stands changes from item to item.

WALL, FLOOR, SKIRT, WOOD, WOOD_S = '#F4EEFB', '#E3D6C6', '#C9B89A', '#C98F52', '#A8743C'
CURTAIN, CURTAIN_S, RUG = '#FFD66B', '#E9B93A', '#B9A2F7'
MARK = '--mark' in sys.argv     # wrap each thing in <g data-thing> (only to measure the drawings; never in the files)


def thing(name, svg):
    return '<g data-thing="%s">%s</g>' % (name, svg) if MARK else svg


def room_bg(shelf=True, peg=False):
    out = ['<rect x="0" y="0" width="256" height="256" fill="%s"/>' % WALL]
    out += ['<circle cx="%d" cy="%d" r="2.6" fill="#E6DAF5"/>' % (x + (16 if (y // 32) % 2 else 0), y)
            for y in range(16, 172, 32) for x in range(8, 256, 32)]                          # a quiet dotted wallpaper
    out += ['<rect x="0" y="178" width="256" height="78" fill="%s"/>' % FLOOR]
    out += [L('M 0 %d L 256 %d' % (y, y), '#D3C3AF', 2.5) for y in (200, 226)]               # the floor boards
    out += [L('M %d %d l 0 %d' % (x, y0, h), '#D3C3AF', 2.5) for x, y0, h in ((70, 180, 20), (190, 200, 26), (120, 226, 30))]
    out += ['<rect x="0" y="171" width="256" height="9" fill="%s"/>' % SKIRT, L('M 0 180 L 256 180', '#B5A383', 2)]
    # the window: a white frame, the sky with one cloud, the cross bars, two short curtains on a rod, a white sill
    out += [RR(150, 22, 94, 80, 7, WHITE), RR(158, 30, 78, 64, 3, '#BFE6F7', 0),
            '<path d="M 172 52 C 170 44, 182 40, 186 46 C 190 38, 204 40, 202 50 C 210 50, 210 60, 202 60 L 174 60 C 166 60, 166 52, 172 52 Z" '
            'fill="#FFFFFF"/>',
            L('M 197 30 L 197 94 M 158 62 L 236 62', WHITE, 6), RR(158, 30, 78, 64, 3, 'none', 2.5), RR(150, 22, 94, 80, 7, 'none')]
    for x0, d in ((140, 1), (254, -1)):
        out.append(P('M %d 16 L %d 16 C %d 40, %d 70, %d 96 C %d 100, %d 100, %d 96 C %d 70, %d 40, %d 16 Z'
                     % (x0, x0 + 20 * d, x0 + 22 * d, x0 + 14 * d, x0 + 18 * d, x0 + 10 * d, x0 + 2 * d, x0, x0 - 2 * d, x0 + 2 * d, x0),
                     CURTAIN, 3))
        out.append(L('M %d 24 C %d 50, %d 74, %d 92' % (x0 + 9 * d, x0 + 11 * d, x0 + 8 * d, x0 + 9 * d), CURTAIN_S, 2.5))
    out += [L('M 134 15 L 256 15', INK, 4), E(134, 15, 4, 4, WOOD, 2.5)]
    out += [RR(142, 100, 112, 10, 4, WHITE, 3)]
    if shelf:   # the wall shelf: a plank on two brackets
        out += [P('M 24 101 L 40 101 L 24 120 Z', WOOD_S, 3), P('M 96 101 L 80 101 L 96 120 Z', WOOD_S, 3), RR(10, 92, 100, 10, 4, WOOD, 3)]
    if peg:     # a coat peg on the wall instead of the shelf
        out += [RR(36, 30, 48, 12, 5, WOOD, 3), E(60, 40, 6, 6, WOOD_S, 3)]
    out += [E(128, 224, 106, 24, RUG, 3),
            '<ellipse cx="128" cy="224" rx="88" ry="17" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-dasharray="2 9" opacity="0.85"/>']
    return out


def lying_scarf():
    """The scarf of scarf.svg (orange, cream stripes, fringed ends) lying on the rug folded in two: the fold at one side, the two
    fringed ends side by side at the other, the way a scarf is dropped on a floor (a lazy S would read as a snake)."""
    f_, s_ = '#F59E1B', '#D97E0A'
    d = 'M 186 206 C 150 198, 86 196, 74 214 C 66 232, 140 238, 190 230'
    out = ['<ellipse cx="134" cy="236" rx="66" ry="6" fill="%s" opacity="0.12"/>' % INK,
           '<path d="%s" fill="none" stroke="%s" stroke-width="27" stroke-linecap="butt"/>' % (d, INK),
           '<path d="%s" fill="none" stroke="%s" stroke-width="20" stroke-linecap="butt"/>' % (d, s_),
           '<path d="%s" fill="none" stroke="%s" stroke-width="13" stroke-linecap="butt" transform="translate(-1 -2)"/>' % (d, f_),
           '<path d="%s" fill="none" stroke="%s" stroke-width="20" stroke-linecap="butt" stroke-dasharray="7 15" stroke-dashoffset="-10"/>'
           % (d, CREAM)]
    for (x, y), (cx, cy) in (((186, 206), (150, 198)), ((190, 230), (140, 238))):   # the ends: an ink edge, the fringe beyond it
        ux, uy = x - cx, y - cy
        n = math.hypot(ux, uy)
        ux, uy = ux / n, uy / n
        nx, ny = -uy, ux
        out.append(L('M %s %s L %s %s' % (f(x - nx * 13), f(y - ny * 13), f(x + nx * 13), f(y + ny * 13)), INK, 3.5))
        fr = ''.join('M %s %s l %s %s ' % (f(x + nx * k + ux * 4), f(y + ny * k + uy * 4), f(ux * 10), f(uy * 10)) for k in (-9, -3, 3, 9))
        out.append(L(fr, INK, 7))
        out.append(L(fr, f_, 3.5))
    return ''.join(out)


SHELF, SILL, RUG_AT = 93, 101, 232        # where things stand: the shelf top, the sill top, the middle of the rug

ROOMS = {   # picture: the item, the room's furniture, the three things (the option's pic id and its drawing in place)
    'scene-room-ball': ('rus.a13.01', dict(shelf=True), [
        ('doll', lambda: obj(m.doll(), 60, SHELF, 0.4)),
        ('balloon', lambda: obj(m.balloon('red'), 198, SILL + 8, 0.36)),
        ('ball', lambda: obj(m.ball('red'), 124, RUG_AT, 0.32))]),
    'scene-room-cat': ('rus.a13.02', dict(shelf=True), [
        ('porridge', lambda: obj(b2.porridge(), 60, SHELF, 0.38)),
        ('cat', lambda: obj(m.cat(), 198, SILL, 0.36)),
        ('dog', lambda: obj(m.dog(), 124, RUG_AT, 0.46))]),
    'scene-room-mouse': ('rus.a13.03', dict(shelf=True), [
        ('teddy', lambda: obj(m.teddy(), 60, SHELF, 0.38)),
        ('cat', lambda: obj(m.cat(), 88, RUG_AT, 0.44)),
        ('mouse', lambda: obj(m.mouse(), 210, 246, 0.32))]),
    'scene-room-hat': ('rus.a13.04', dict(shelf=False, peg=True), [
        ('jacket', lambda: sc.obj(b2.jacket(), 60, 122, 0.4, air=True)),
        ('hat-warm', lambda: obj(m.hat_warm(), 198, SILL + 4, 0.34)),
        ('scarf', lying_scarf)]),
    'scene-room-apple': ('rus.a13.05', dict(shelf=True), [
        ('milk', lambda: obj(m.milk(), 60, SHELF, 0.38)),
        ('apple', lambda: obj(m.apple(), 198, SILL + 2, 0.3)),
        ('pear', lambda: obj(b2.pear(), 124, RUG_AT, 0.36))]),
}


def rooms():
    return {pid: sc.composite(room_bg(**bg) + [thing(name, draw()) for name, draw in things])
            for pid, (item, bg, things) in ROOMS.items()}


def garden_square():
    return ['<rect x="0" y="0" width="256" height="256" fill="#DFF1FB"/>',
            '<path d="M 0 150 C 70 140, 190 140, 256 150 L 256 256 L 0 256 Z" fill="#B5DFA0"/>',
            '<path d="M 0 230 C 80 212, 180 212, 256 226 L 256 256 L 0 256 Z" fill="#EADBB8"/>',
            obj(b2.bush(), 24, 160, 0.34), obj(b2.bush(), 236, 158, 0.3)]


FAMILY_AT = (('father', 50), ('mother', 128), ('grandmother', 206))
FAMILY_SCALE = 0.84


def family_garden():
    parts = garden_square()
    for pid, x in FAMILY_AT:
        body = ''.join(pe.standing(ch.BY_ID[pid], 'happy'))
        parts.append(thing(pid, '<g transform="translate(%s 238) scale(%s)">%s</g>' % (f(x), f(FAMILY_SCALE), sc.unique(body, sc.tag()))))
    return {'scene-garden-family': sc.composite(parts)}


# ---- the HEB-A-10 heart and flower (t05 and s06; Heebo has no glyph for U+2665 or U+273F) ------------------------------

def heart_flower():
    heart = ('M 128 198 C 104 180, 52 150, 52 104 C 52 76, 72 58, 96 58 C 112 58, 123 67, 128 80 '
             'C 133 67, 144 58, 160 58 C 184 58, 204 76, 204 104 C 204 150, 152 180, 128 198 Z')
    petals = [E(128 + 40 * math.cos(math.radians(-90 + 72 * k)), 132 + 40 * math.sin(math.radians(-90 + 72 * k)), 35, 35, INK, 0)
              for k in range(5)]
    return {'shape-heart': sc.composite([P(heart, INK, 6)]),
            'shape-flower': sc.composite(petals + [E(128, 132, 44, 44, INK, 0), E(128, 132, 19, 19, WHITE, 0)])}


# The rooms' touch areas (256 units, x, y, w, h), measured from the drawn things (their bounding boxes in the browser, shadows
# included) and padded to at least 72 x 72; the top places (shelf or peg, window) end at y 120 and the floor places start at 136
# or lower, so no two areas of a room meet.
TOP_LEFT, WINDOW, ON_RUG = [8, 4, 108, 116], [140, 8, 112, 112], [56, 136, 136, 112]
ROOM_AREAS = {
    'scene-room-ball': {'doll': [TOP_LEFT], 'balloon': [WINDOW], 'ball': [ON_RUG]},
    'scene-room-cat': {'porridge': [TOP_LEFT], 'cat': [WINDOW], 'dog': [ON_RUG]},
    'scene-room-mouse': {'teddy': [TOP_LEFT], 'cat': [[36, 136, 106, 112]], 'mouse': [[148, 164, 104, 88]]},
    'scene-room-hat': {'jacket': [[8, 20, 108, 108]], 'hat-warm': [WINDOW], 'scarf': [[52, 140, 160, 108]]},
    'scene-room-apple': {'milk': [TOP_LEFT], 'apple': [WINDOW], 'pear': [ON_RUG]},
}
FAMILY_AREAS = {'father': [[10, 44, 80, 204]], 'mother': [[90, 44, 78, 204]], 'grandmother': [[168, 56, 82, 192]]}
ROOM_NOTE = ("Touch areas of the things drawn into the room (RUS-A-13 %s, LS11 scene search: Где ...? and a touch on the thing), as "
             "shares of the picture's width and height (x, y, w, h from the top left), version 2 like doll-body.hotspots.json. A part "
             "is named by the option's picture id. Every area is at least 72 of the 256 units (65.5 pt on the phone SE's 233 pt scene "
             "square); the three never overlap, so the item is shown on the scene (show: body).")
# The Russian story pages (RUS-A-16 01 and 04): a part is named by its word's clip without the 'w-' (the recipe looks up
# 'w-sobaka', then 'sobaka'). Measured as for story-bounce, padded to at least 96 of the 384 x 216 units.
RU_STORY_AREAS = {
    'st1-p1': {'sobaka': [[88, 102, 120, 110]], 'mjach': [[222, 120, 96, 96]]},
    'st2-p1': {'jozhik': [[140, 112, 126, 102]]},
}


def russian_maps():
    out = {}
    for pid, areas in ROOM_AREAS.items():
        item = ROOMS[pid][0]
        names = [n for n, _ in ROOMS[pid][2]]
        assert sorted(names) == sorted(areas), pid
        out[pid] = share_map(pid, areas, 256, 256, HIT, ROOM_NOTE % item.split('.')[-1], {item: {'parts': names, 'show': 'body'}})
    out['scene-garden-family'] = share_map('scene-garden-family', FAMILY_AREAS, 256, 256, HIT, ROOM_NOTE.replace(
        'the things drawn into the room', 'the family standing in the garden') % '06',
        {'rus.a13.06': {'parts': ['mother', 'father', 'grandmother'], 'show': 'body'}})
    for pid, areas in RU_STORY_AREAS.items():
        out[pid] = share_map(pid, areas, 384, 216, STORY_HIT, STORY_NOTE.replace('ENG-A-15 s01 uses', 'RUS-A-16 01 and 04 use'))
    return out


PARTS = {'batch5a': many_sets, 'batch5b': ten_frames, 'batch5c': lambda: dict(lit_sprites(), **doll_pictures(), **shape_cards()),
         'batch6a': lambda: dict(rooms(), **family_garden(), **heart_flower())}


def write_json(name, data):
    with open(os.path.join(OUT, name), 'w', encoding='utf-8', newline='\n') as fh:
        json.dump(data, fh, ensure_ascii=False, indent=1)
        fh.write('\n')


def main():
    for name, make in PARTS.items():
        pics = make()
        for pid, text in pics.items():
            assert len(text.encode('utf-8')) < 60000, (pid, len(text))
            with open(os.path.join(OUT, pid + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
                fh.write(text)
        print(name, 'wrote', len(pics))
        if '--sheet' in sys.argv:
            out = os.path.join(ROOT, 'docs', 'design', 'languages', 'pictures_%s.png' % name)
            m.sheet(list(pics), out, cols=6)
            print('sheet', os.path.relpath(out, ROOT))
    write_json('doll-body.hotspots.json', doll_map())
    for pid, data in dict(english_maps(), **russian_maps()).items():
        write_json(pid + '.hotspots.json', data)
    print('wrote the tap-area maps')


if __name__ == '__main__':
    main()
