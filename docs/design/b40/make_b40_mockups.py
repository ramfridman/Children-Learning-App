"""B-40 visual hint ladder: mock frames for the owner (design-director, 2026-10-30). Not app code.

Draws each hint level on the real phone frame (852 x 393 board points): the top bar and the companion are taken from the
approved golden `app/test/goldens/unit_colour_find_phone.png`; the stage, the tiles, the hint pictures and the pointing hand
are drawn here as plain SVG shapes, with the activity pictures from `content/starter/*.svg` (the app's own sprites).
The speech bubble is left WITHOUT words on purpose: every frame must be understood with the sound off and no reading.

    python docs/design/b40/make_b40_mockups.py        (needs Google Chrome; writes docs/design/b40/*.png)

References looked at before drawing (facts, not copied images):
- Ten-frame convention: fill the top row first, from the left, then the bottom row; a full row is "five"
  (Illustrative Mathematics K unit 5 lesson 10; Van de Walle, cited in the SANC ten-frames reading, ru.ac.za).
- Number path: Siegler & Ramani's linear board game, equal squares numbered 1-10 left to right (IES WWC study 73675).
- Number Frames (Math Learning Center): five-, ten- and double ten-frames, single counters or stacks of 5 and 10.
- Finger counting: the five-and-more structure on two hands (Wikipedia, "Finger-counting", read 2026-10-30).
- Pointing: Alibali & DiRusso 1999 (a puppet pointing for the child helps counting), the curriculum plan's source.
- The hand, fingers, swatch, frames, strips, towers and badges are our own drawings in plain shapes. No text in a picture
  except the numerals the app itself draws on badges and tiles (Heebo).
"""
import os
import subprocess
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..'))
OUT = os.path.join(ROOT, 'docs', 'design', 'b40')
TMP = os.environ.get('B40_TMP', os.path.join(tempfile.gettempdir(), 'b40_mock_html'))
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'
SPR = 'file:///' + os.path.join(ROOT, 'content', 'starter').replace('\\', '/') + '/'
GOLD = 'file:///' + os.path.join(ROOT, 'app', 'test', 'goldens').replace('\\', '/') + '/'
FONT = 'file:///' + os.path.join(ROOT, 'app', 'assets', 'fonts', 'Heebo-Variable.ttf').replace('\\', '/')

# tokens (design/tokens.json)
CREAM, PAPER, INK, INKSOFT, MIST, HAIR, LIP = '#FFF6E8', '#FFFFFF', '#2B2350', '#5A5378', '#EDE6F7', '#E6DDF0', '#DCD3EC'
SKY, SKYDEEP, SKYTINT, SPARK, SPARKTINT, SPARKDEEP = '#8FD3F4', '#5BB6E0', '#E3F4FC', '#FFC83D', '#FFF1C4', '#E0A21A'
ANNO = '#A79BC8'  # mock-only annotation colour (motion arrows); never drawn by the app

W, H = 852, 393
STAGE = (71, 96, 330, 128)
TILE_TOP, TILE_W, TILE_H = 248, 92, 86


# ---------------------------------------------------------------- primitives
def img(name, x, y, w, h, opacity=1.0, extra=''):
    return '<image href="%s%s.svg" x="%.1f" y="%.1f" width="%.1f" height="%.1f" opacity="%.2f" %s/>' % (
        SPR, name, x, y, w, h, opacity, extra)


def text(x, y, s, size=13, weight=700, fill=INK, anchor='middle', extra=''):
    return '<text x="%.1f" y="%.1f" font-family="Heebo" font-weight="%d" font-size="%d" fill="%s" text-anchor="%s" %s>%s</text>' % (
        x, y, weight, size, fill, anchor, extra, s)


def halo_circle(cx, cy, r, strong=True):
    w = 4 if strong else 3
    return ('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="none" stroke="%s" stroke-width="10" stroke-opacity=".35" filter="url(#soft)"/>'
            '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s" fill-opacity=".45" stroke="%s" stroke-width="%d"/>') % (
        cx, cy, r, SKY, cx, cy, r, SKYTINT, SKY, w)


def halo_rect(x, y, w, h, rx=18):
    return ('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="%d" fill="none" stroke="%s" stroke-width="12" stroke-opacity=".35" filter="url(#soft)"/>'
            '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="%d" fill="none" stroke="%s" stroke-width="5"/>') % (
        x - 4, y - 4, w + 8, h + 8, rx + 4, SKY, x - 4, y - 4, w + 8, h + 8, rx + 4, SKY)


def badge(cx, cy, n, r=11, big=False):
    if big:
        r = 17
    return ('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s" stroke="%s" stroke-width="2.5"/>' % (cx, cy, r, PAPER, SKYDEEP)
            + text(cx, cy + r * 0.42, str(n), size=int(r * 1.25), weight=800))


def hand(x, y, s=0.85, rot=0, ripple=True):
    """The one neutral pointing hand (D1): sky-tint fill, sky-deep outline, fingertip at (x, y), arriving from the
    upper right (the guide's side in RTL). No cuff, no glove stitching: it must not read as any cartoon glove."""
    st = 'fill="%s" stroke="%s" stroke-width="%.1f" stroke-linejoin="round"' % (SKYTINT, SKYDEEP, 2.6 / s)
    g = ['<g transform="translate(%.1f %.1f) rotate(%d) scale(%.2f)">' % (x, y, rot, s)]
    if ripple:
        g.append('<circle cx="0" cy="0" r="10" fill="none" stroke="%s" stroke-width="2.5" opacity=".9"/>' % SKY)
        g.append('<circle cx="0" cy="0" r="17" fill="none" stroke="%s" stroke-width="2" opacity=".45"/>' % SKY)
    g.append('<rect x="5" y="-80" width="18" height="30" rx="8" %s/>' % st)          # wrist
    g.append('<rect x="-8" y="-58" width="34" height="34" rx="12" %s/>' % st)        # back of the hand
    g.append('<circle cx="13" cy="-22" r="6.5" %s/>' % st)                          # curled middle
    g.append('<circle cx="20" cy="-24" r="6" %s/>' % st)                            # curled ring
    g.append('<circle cx="25.5" cy="-28" r="5" %s/>' % st)                          # curled little finger
    g.append('<ellipse cx="-8" cy="-36" rx="5" ry="10" transform="rotate(-38 -8 -36)" %s/>' % st)  # thumb, along the index
    g.append('<rect x="-6.5" y="-42" width="13" height="43" rx="6.5" %s/>' % st)    # index finger, long
    g.append('<rect x="-3.5" y="-9" width="7" height="6" rx="3" fill="%s"/>' % PAPER)  # nail highlight
    g.append('</g>')
    return ''.join(g)


def counting_hand(x, y, raised, right=False, s=1.0):
    """A hand for counting (D2), seen from the back, fingers up, origin at the wrist centre. The left hand stands on the
    left with its thumb toward the middle; the right hand mirrors it. Fingers rise index, middle, ring, little, thumb."""
    st = 'fill="%s" stroke="%s" stroke-width="2" stroke-linejoin="round"' % (SPARKTINT, INK)
    order = ['index', 'middle', 'ring', 'little', 'thumb']
    up = set(order[:raised])
    fx = {'little': -14, 'ring': -5, 'middle': 4, 'index': 13}
    fh = {'little': 22, 'ring': 29, 'middle': 32, 'index': 29}
    g = ['<g transform="translate(%.1f %.1f) scale(%s %.2f)">' % (x, y, ('-%.2f' % s) if right else ('%.2f' % s), s)]
    for f in ['little', 'ring', 'middle', 'index']:
        hgt = fh[f] if f in up else 7
        fill = SPARK if f in up else SPARKTINT
        g.append('<rect x="%.1f" y="%.1f" width="8.6" height="%.1f" rx="4.3" fill="%s" stroke="%s" stroke-width="2"/>' % (
            fx[f] - 4.3, -36 - hgt + 4, hgt + 6, fill, INK))
    if 'thumb' in up:
        g.append('<rect x="14" y="-36" width="8.6" height="24" rx="4.3" transform="rotate(38 18 -14)" fill="%s" stroke="%s" stroke-width="2"/>' % (SPARK, INK))
    else:
        g.append('<ellipse cx="17" cy="-17" rx="4.5" ry="8" transform="rotate(-25 17 -17)" %s/>' % st)  # folded thumb, behind
    g.append('<rect x="-19" y="-38" width="38" height="38" rx="13" %s/>' % st)
    g.append('</g>')
    return ''.join(g)


def ten_frame(x, y, cell, n, counter=None, counter_scale=0.8):
    o = ['<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="4" fill="%s" stroke="%s" stroke-width="2.5"/>' % (
        x, y, cell * 5, cell * 2, PAPER, INK)]
    for i in range(1, 5):
        o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="1.5"/>' % (x + i * cell, y, x + i * cell, y + 2 * cell, INK))
    o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="1.5"/>' % (x, y + cell, x + 5 * cell, y + cell, INK))
    for k in range(n):
        cx, cy = x + (k % 5 + 0.5) * cell, y + (k // 5 + 0.5) * cell
        if counter:
            w = cell * counter_scale
            o.append(img(counter, cx - w / 2, cy - w / 2, w, w))
        else:
            o.append('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s"/>' % (cx, cy, cell * 0.3, INK))
    return ''.join(o)


def arrow(d, label=None, lx=0, ly=0):
    s = '<path d="%s" fill="none" stroke="%s" stroke-width="1.8" stroke-dasharray="5 4" marker-end="url(#ah)"/>' % (d, ANNO)
    if label:
        s += text(lx, ly, label, size=10, weight=600, fill=ANNO)
    return s


def hint_card(x, y, w, h):
    return '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="18" fill="%s" stroke="%s" stroke-width="3"/>' % (
        x, y, w, h, SKYTINT, SKY)


def stage(content='', hills=True, dim=None):
    x, y, w, h = STAGE
    s = ['<clipPath id="stg"><rect x="%d" y="%d" width="%d" height="%d" rx="22"/></clipPath>' % STAGE,
         '<g clip-path="url(#stg)"><rect x="%d" y="%d" width="%d" height="%d" fill="url(#skyg)"/>' % STAGE]
    if hills:
        s.append('<ellipse cx="%d" cy="%d" rx="200" ry="40" fill="#A8D98A"/>' % (x + 70, y + h + 8))
        s.append('<ellipse cx="%d" cy="%d" rx="210" ry="36" fill="#8CC56E"/>' % (x + 300, y + h + 14))
    s.append(content)
    if dim:
        s.append(dim)
    s.append('</g>')
    return ''.join(s)


def dim_except(holes):
    """Dims the stage slightly except round the targets (P1): a cream veil with holes. Never used on the tiles."""
    m = ['<mask id="dm"><rect x="0" y="0" width="%d" height="%d" fill="white"/>' % (W, H)]
    for (cx, cy, r) in holes:
        m.append('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="black"/>' % (cx, cy, r))
    m.append('</mask>')
    return ''.join(m) + '<rect x="%d" y="%d" width="%d" height="%d" fill="%s" fill-opacity=".5" mask="url(#dm)"/>' % (STAGE + (CREAM,))


def tile(cx, inner='', dim=False, halo=False, top=TILE_TOP, w=TILE_W, h=TILE_H):
    x = cx - w / 2
    s = []
    if halo:
        s.append(halo_rect(x, top, w, h + 6))
    s.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="18" fill="%s"/>' % (x, top + 6, w, h, LIP))
    s.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="18" fill="%s" stroke="%s" stroke-width="2"/>' % (x, top, w, h, PAPER, HAIR))
    s.append(inner)
    if dim:
        s.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="18" fill="%s" fill-opacity=".6"/>' % (x - 1, top - 1, w + 2, h + 8, CREAM))
    return ''.join(s)


def num_tile_inner(cx, n, top=TILE_TOP):
    s = text(cx, top + 52, str(n), size=46, weight=800)
    for k in range(n):
        s += '<circle cx="%.1f" cy="%.1f" r="3.4" fill="%s"/>' % (cx - (n - 1) * 4.5 + k * 9, top + 70, INKSOFT)
    return s


def bubble():
    s = ['<rect x="413" y="109" width="190" height="104" rx="22" fill="%s"/>' % HAIR,
         '<rect x="413" y="104" width="190" height="104" rx="22" fill="%s"/>' % PAPER,
         '<path d="M603 168 L617 178 L603 188 Z" fill="%s"/>' % PAPER]
    # a muted speaker: the line is spoken, but the frame must work without it
    s.append('<g transform="translate(572 124)" fill="none" stroke="%s" stroke-width="2" stroke-linecap="round">'
             '<path d="M0 4 h5 l6 -5 v18 l-6 -5 h-5 z" fill="%s"/><path d="M15 0 l8 10 M23 0 l-8 10"/></g>' % (ANNO, ANNO))
    for i, (x0, x1) in enumerate([(430, 562), (440, 588), (470, 588)]):
        s.append('<rect x="%d" y="%d" width="%d" height="9" rx="4.5" fill="%s"/>' % (x0, 150 + i * 20, x1 - x0, MIST))
    return ''.join(s)


DEFS = ('<defs><filter id="soft" x="-30%%" y="-30%%" width="160%%" height="160%%"><feGaussianBlur stdDeviation="3"/></filter>'
        '<linearGradient id="skyg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#DDF0FA"/><stop offset="1" stop-color="#EEF8FD"/></linearGradient>'
        '<marker id="ah" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">'
        '<path d="M0 0 L10 5 L0 10 z" fill="%s"/></marker></defs>') % ANNO


def phone_frame(body, hint_on=True, base='unit_colour_find_phone.png', cover=True):
    s = ['<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">' % (W, H, W, H), DEFS,
         '<image href="%s%s" x="0" y="0" width="%d" height="%d"/>' % (GOLD, base, W, H)]
    if cover:
        s.append('<rect x="30" y="86" width="598" height="307" fill="%s"/>' % CREAM)
    if hint_on:
        s.append('<circle cx="179" cy="44" r="37" fill="none" stroke="%s" stroke-width="5"/>' % SKY)
    s.append(bubble())
    s.append(body)
    s.append('</svg>')
    return ''.join(s)


# ---------------------------------------------------------------- M1 count_tap: 7 apples, two hands; 13 stars, two ten-frames
APPLES = [(109, 130), (164, 128), (218, 130), (268, 132), (111, 187), (216, 185), (267, 191)]


def apples(lit=(), sz=34):
    o = []
    for i, (x, y) in enumerate(APPLES):
        if i in lit:
            o.append(halo_circle(x, y, 21, strong=True))
        o.append(img('apple', x - sz / 2, y - sz / 2, sz, sz))
    return ''.join(o)


def m1():
    f = []
    # L1: the apples glow one after another (no numbers), apple 4 glowing now
    body = stage(apples(lit=(3,)) + ''.join(
        '<circle cx="%d" cy="%d" r="4" fill="%s"/>' % (x + 15, y - 16, SKYDEEP) for (x, y) in APPLES[:3]))
    body += arrow('M120 112 C140 100 150 100 158 110', None) + arrow('M175 110 C190 100 200 100 210 110')
    body += arrow('M228 112 C240 100 250 102 258 112')
    f.append(('L1 Look here: light each one',
              'Each apple glows in turn, slowly, a small sky dot stays on the ones already lit. It says: touch every apple, one at a time.',
              phone_frame(body)))
    # L2: two hands, 5 and 2, in a hint card in the free answer area; every apple has its finger's dot
    body = stage(apples() + ''.join('<circle cx="%d" cy="%d" r="4" fill="%s"/>' % (x + 15, y - 16, SKYDEEP) for (x, y) in APPLES))
    body += hint_card(150, 238, 260, 110)
    body += counting_hand(235, 336, 5, s=1.15) + counting_hand(325, 336, 2, right=True, s=1.15)
    body += arrow('M268 205 C268 225 300 240 314 262', None)
    f.append(('L2 Another way: two hands',
              'Under the apples a card opens with two hands; a finger rises for every apple that lights (a full hand, then two more). It says: the apples are as many as these fingers.',
              phone_frame(body)))
    # L2 for 11-20 (NUM-B-04): 13 stars regroup into a full frame and a frame with 3
    stars = [(100 + (k % 7) * 40, 118 + (k // 7) * 52) for k in range(13)]
    body = stage(''.join(img('star', x - 14, y - 14, 28, 28, opacity=.35) for (x, y) in stars))
    body += hint_card(118, 236, 330, 116)
    body += ten_frame(132, 256, 30, 10, counter='star') + ten_frame(290, 256, 30, 3, counter='star')
    body += arrow('M250 172 C250 205 220 230 205 252')
    f.append(('L2 for 11 to 20: two ten-frames',
              'The 13 stars fly down, one by one, into frames: one frame fills up, three go in the next. It says: a full frame and three more.',
              phone_frame(body)))
    # L3: the hand touches each apple; a number badge stays on each; the last number grows
    lit = ''.join(badge(x + 15, y - 16, i + 1) for i, (x, y) in enumerate(APPLES[:6]))
    body = stage(apples(lit=(6,)) + lit + badge(282, 175, 7)
                 + '<rect x="318" y="112" width="64" height="64" rx="18" fill="%s" stroke="%s" stroke-width="3"/>' % (PAPER, SKY)
                 + text(350, 160, '7', size=44, weight=800))
    body += arrow('M292 170 C305 160 310 150 316 146') + hand(262, 196, s=0.8)
    f.append(('L3 Watch me, then you',
              'The hand touches every apple and a small number stays on each; the last number glides into a big card beside the group and stays (that many apples). Then the hand leaves, the small numbers fade, and it is the child\'s turn.',
              phone_frame(body)))
    return 'b40_m1_count_tap_fingers_tenframe', 'M1 count_tap (NUM-A-09: 7 apples; NUM-B-04: 13 stars)', f


# ---------------------------------------------------------------- M2 tap_answer TA-1: how many butterflies?
BUTTER = [(180, 130), (232, 172), (272, 116)]


def butterflies(lit=(), dimmed=False):
    o = [img('flower_red', 300, 108, 92, 108)]
    for i, (x, y) in enumerate(BUTTER):
        if i in lit:
            o.append(halo_circle(x, y, 23))
        o.append(img('butterfly', x - 20, y - 20, 40, 40))
    return ''.join(o)


def tiles_432(halo3=False, dim_others=False):
    return (tile(218, num_tile_inner(218, 4), dim=dim_others) + tile(338, num_tile_inner(338, 3), halo=halo3)
            + tile(458, num_tile_inner(458, 2), dim=dim_others))


def m2():
    f = []
    body = stage(butterflies(lit=(1,)), dim=dim_except([(x, y, 26) for (x, y) in BUTTER]))
    body += '<circle cx="%d" cy="%d" r="4" fill="%s"/>' % (BUTTER[0][0] + 16, BUTTER[0][1] - 17, SKYDEEP)
    body += arrow('M160 140 C180 160 190 165 196 166') + arrow('M226 156 C240 140 246 130 250 126')
    body += tiles_432()
    f.append(('L1 Look here: the things to count',
              'The flower and grass fade a little; the butterflies glow one after another, with no numbers. The tiles do not change. It says: these are what we count, each one once.',
              phone_frame(body)))
    # L2: a hand on the stage raises a finger as each butterfly lights; a sky line pairs each butterfly with its finger
    body = stage(butterflies() + hint_card(78, 102, 82, 120).replace('rx="18"', 'rx="16"')
                 + counting_hand(118, 212, 3, s=1.3)
                 + ''.join('<path d="M%d %d Q %d %d %d %d" fill="none" stroke="%s" stroke-width="3.5" stroke-dasharray="1 7" stroke-linecap="round"/>' % (
                     x - 18, y, (x + 120) / 2, y - 10, tx, ty, SKYDEEP)
                     for (x, y), (tx, ty) in zip(BUTTER, [(135, 133), (123, 129), (112, 133)])))
    body += tiles_432()
    f.append(('L2 Another way: fingers',
              'A small hand stands at the side of the scene; each butterfly glows and a dotted line runs from it to a finger that rises. It says: one finger for each butterfly. The tiles still look the same.',
              phone_frame(body)))
    # L3: the hand counts with badges, the last number grows, flies to its tile; then the tile keeps a halo
    body = stage(butterflies() + ''.join(badge(x + 17, y - 17, i + 1) for i, (x, y) in enumerate(BUTTER[:2]))
                 + badge(272 + 20, 116 - 4, 3, big=True))
    body += arrow('M292 132 C310 190 350 205 345 238')
    body += tiles_432(halo3=True, dim_others=True)
    body += hand(338, 252, s=0.8)
    f.append(('L3 Watch me, then you (and the halo that stays)',
              'The hand touches each butterfly, numbers appear, the last one grows and glides down onto the tile with the same number, which keeps a sky halo; the other tiles fade. The child taps it.',
              phone_frame(body)))
    return 'b40_m2_tap_answer_count', 'M2 tap_answer, count a group (TA-1: how many butterflies?)', f


# ---------------------------------------------------------------- M3 colour: which balloon is red?
def balloon_tile(cx, colour, **kw):
    return tile(cx, img('balloon_' + colour, cx - 30, TILE_TOP + 10, 60, 66), **kw)


def swatch(cx, cy, r=26, colour='#D62F2F', lip='#A82020'):
    """A paint blob (D8) in the teaching colour, with the colour's helper symbol (red = heart) in white (design-spec 9.3)."""
    blob = None
    heart = ('<path d="M{0} {1} c-3 -6 -13 -5 -13 3 c0 6 8 11 13 15 c5 -4 13 -9 13 -15 c0 -8 -10 -9 -13 -3 z" fill="#FFFFFF" fill-opacity=".9"/>'
             ).format(cx, cy - 3)
    return ('<circle cx="%d" cy="%d" r="%d" fill="%s"/><circle cx="%d" cy="%d" r="%d" fill="%s" stroke="%s" stroke-width="2"/>' % (cx, cy + 4, r, lip, cx, cy, r, colour, PAPER)) + heart


def m3():
    f = []
    body = stage('', hills=True)
    body += balloon_tile(218, 'blue') + balloon_tile(338, 'red', halo=False) + balloon_tile(458, 'yellow', halo=True)
    body += arrow('M470 236 C440 226 380 226 350 236', None) + arrow('M326 236 C300 226 250 226 230 236')
    f.append(('L1 Look here: each one, slowly (needs the word)',
              'The tiles glow one after another, right to left, as each colour is named. Sound off, this only says: look at every balloon. The colour itself lives in the word, so L2 is the first hint that works with no sound.',
              phone_frame(body)))
    body = stage(hint_card(186, 108, 100, 104) + swatch(236, 160, r=30))
    body += balloon_tile(218, 'blue') + balloon_tile(338, 'red') + balloon_tile(458, 'yellow')
    f.append(('L2 Another way: the colour itself',
              'A paint blob of the asked colour (with its helper heart) appears on the empty stage. It says: find a balloon that looks like this. No tile is marked.',
              phone_frame(body)))
    body = stage('')
    body += balloon_tile(218, 'blue', dim=True) + balloon_tile(338, 'red', halo=True) + balloon_tile(458, 'yellow', dim=True)
    body += '<g opacity=".35">' + swatch(458, 236, r=18) + '</g>' + swatch(338, 236, r=22)
    body += arrow('M450 216 C430 196 370 196 352 212', None) + hand(300, 296, s=0.8, rot=-30)
    f.append(('L3 Watch me, then you',
              'The paint blob slides over each balloon in turn; on the one with the same colour it sticks, that tile keeps a sky halo and the others fade. The hand points; the child taps.',
              phone_frame(body)))
    return 'b40_m3_colour_swatch', 'M3 tap_answer, colour naming (TA-6, COL-A-02: which balloon is red?)', f


# ---------------------------------------------------------------- M4 number line jump: the frog on 2 jumps 3
NL_X0, NL_DX, NL_Y = 93, 28.6, 182


def number_line(dim_but=None):
    x0, dx, y = NL_X0, NL_DX, NL_Y
    o = ['<line x1="%.1f" y1="%d" x2="%.1f" y2="%d" stroke="%s" stroke-width="4" stroke-linecap="round"/>' % (x0 - 4, y, x0 + 10 * dx + 4, y, INK)]
    for i in range(11):
        o.append('<line x1="%.1f" y1="%d" x2="%.1f" y2="%d" stroke="%s" stroke-width="3"/>' % (x0 + i * dx, y - 9, x0 + i * dx, y + 5, INK))
        o.append(text(x0 + i * dx, y + 22, str(i), size=16, weight=700))
    return ''.join(o)


def hop(a, b, n=None, ghost=False):
    x1, x2 = NL_X0 + a * NL_DX, NL_X0 + b * NL_DX
    s = '<path d="M%.1f %d Q %.1f %d %.1f %d" fill="none" stroke="%s" stroke-width="3" stroke-linecap="round" %s/>' % (
        x1, NL_Y - 16, (x1 + x2) / 2, NL_Y - 82, x2, NL_Y - 16, SKYDEEP, 'stroke-dasharray="2 6" opacity=".6"' if ghost else '')
    if n:
        s += badge((x1 + x2) / 2, NL_Y - 52, n, r=9)
    return s


def dots_pill(cx, cy, used, total=3):
    s = '<rect x="%.1f" y="%.1f" width="%.1f" height="22" rx="11" fill="%s" stroke="%s" stroke-width="2.5"/>' % (
        cx - total * 9 - 4, cy - 11, total * 18 + 8, PAPER, SKY)
    for k in range(total):
        x = cx - (total - 1) * 9 + k * 18
        s += '<circle cx="%.1f" cy="%.1f" r="5.5" fill="%s" stroke="%s" stroke-width="2"/>' % (x, cy, INK if k >= used else PAPER, INK)
    return s


def m4():
    f = []
    sx = NL_X0 + 2 * NL_DX
    tick_halo = lambda t: halo_rect(NL_X0 + t * NL_DX - 11, NL_Y - 10, 22, 38, rx=10)
    frog = lambda t, op=1.0: img('frog', NL_X0 + t * NL_DX - 15, NL_Y - 32, 30, 30, opacity=op)
    body = stage(number_line() + tick_halo(2) + frog(2), dim=dim_except([(sx, NL_Y + 4, 22), (sx, NL_Y - 18, 22)]))
    body += dots_pill(sx, 116, 0)
    f.append(('L1 Look here: where we start, how far we hop',
              'Everything fades except the frog on its tick, which glows, and a little card over the frog with three dots (the size of the jump). It says: start here, and three is the jump.',
              phone_frame(body)))
    body = stage(number_line() + frog(2, .25) + hop(2, 3, 1) + frog(3) + dots_pill(NL_X0 + 3 * NL_DX, 110, 1))
    f.append(('L2 Together: the first hop',
              'The frog makes one hop to the right; a sky arc with 1 stays behind, and one of the three dots empties. It stops there. It says: hop like this, two dots are left.',
              phone_frame(body)))
    t5 = NL_X0 + 5 * NL_DX
    body = stage(number_line() + tick_halo(5) + hop(2, 3, 1) + hop(3, 4, 2) + hop(4, 5, 3) + frog(5, .3) + frog(2))
    body += hand(t5, NL_Y - 9, s=0.7)
    f.append(('L3 Watch me, then you',
              'The frog hops three times, counted 1, 2, 3 on the arcs, and lands on a tick that glows; then the frog goes back to its start and the arcs and glow stay faint. The child taps the glowing tick.',
              phone_frame(body)))
    return 'b40_m4_number_line_jump', 'M4 number_line, jump mode (NUM-B-13: the frog on 2 hops 3)', f


# ---------------------------------------------------------------- M5 clock_set: set the clock to 3
CX, CY, CR = 236, 160, 58


def clock(hour_angle_deg=0, glow_hour_hand=False, ring3=False, ghost3=False, badges=()):
    import math
    o = []
    o.append('<circle cx="%d" cy="%d" r="%d" fill="%s" stroke="%s" stroke-width="6"/>' % (CX, CY, CR, PAPER, INK))
    for h in range(1, 13):
        a = math.radians(h * 30 - 90)
        o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="2.5"/>' % (
            CX + (CR - 4) * math.cos(a), CY + (CR - 4) * math.sin(a), CX + (CR - 11) * math.cos(a), CY + (CR - 11) * math.sin(a), INK))
        if h == 3 and ring3:
            o.append(halo_circle(CX + (CR - 21) * math.cos(a), CY + (CR - 21) * math.sin(a) - 0.5, 11))
        o.append(text(CX + (CR - 21) * math.cos(a), CY + (CR - 21) * math.sin(a) + 5, str(h), size=13, weight=700))
    for (h, n) in badges:
        a = math.radians(h * 30 - 90)
        o.append(badge(CX + (CR + 16) * math.cos(a), CY + (CR + 16) * math.sin(a), n, r=9))
    # long hand on 12, faded at L1 so the short hand stands out
    o.append('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="3" stroke-linecap="round" opacity="%s"/>' % (
        CX, CY, CX, CY - 46, INKSOFT, '.35' if glow_hour_hand else '1'))
    if ghost3:
        o.append('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="9" stroke-linecap="round" opacity=".55"/>' % (CX, CY, CX + 30, CY, SKY))
    a = math.radians(hour_angle_deg - 90)
    ex, ey = CX + 30 * math.cos(a), CY + 30 * math.sin(a)
    if glow_hour_hand:
        o.append('<line x1="%d" y1="%d" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="18" stroke-linecap="round" stroke-opacity=".6"/>' % (CX, CY, ex, ey, SKY))
    o.append('<line x1="%d" y1="%d" x2="%.1f" y2="%.1f" stroke="#D84A4A" stroke-width="8" stroke-linecap="round"/>' % (CX, CY, ex, ey))
    o.append('<circle cx="%d" cy="%d" r="6" fill="%s"/>' % (CX, CY, INK))
    return ''.join(o)


def clock_buttons(halo_plus=False):
    def btn(cx, inner, halo=False):
        x = cx - 34
        s = halo_rect(x, 246, 68, 68) if halo else ''
        return s + ('<rect x="%d" y="252" width="68" height="64" rx="18" fill="%s"/>' % (x, LIP)
                    + '<rect x="%d" y="246" width="68" height="64" rx="18" fill="%s" stroke="%s" stroke-width="2"/>' % (x, PAPER, HAIR) + inner)
    minus = '<line x1="228" y1="278" x2="256" y2="278" stroke="%s" stroke-width="4" stroke-linecap="round"/>' % INK
    plus = ('<line x1="324" y1="278" x2="352" y2="278" stroke="%s" stroke-width="4" stroke-linecap="round"/>' % INK
            + '<line x1="338" y1="264" x2="338" y2="292" stroke="%s" stroke-width="4" stroke-linecap="round"/>' % INK)
    tick = '<path d="M420 278 l10 10 l18 -20" fill="none" stroke="%s" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/>' % INK
    return btn(242, minus) + btn(338, plus, halo_plus) + btn(434, tick)


def target_card(x, y, n, glow=False):
    s = halo_rect(x, y, 50, 50, rx=14) if glow else ''
    return s + '<rect x="%d" y="%d" width="50" height="50" rx="14" fill="%s" stroke="%s" stroke-width="3"/>' % (x, y, SKYTINT, SKY) + text(x + 25, y + 37, str(n), size=32, weight=800)


def m5():
    f = []
    body = clock(0, glow_hour_hand=True) + target_card(98, 136, 3) + clock_buttons()
    f.append(('L1 Look here: the short hand, and the number we want',
              'The short hand glows and the long hand fades; beside the clock a small card shows the 3 from the question. It says: this is the hand to move, and this is the number.',
              phone_frame(body)))
    body = clock(0, ring3=True) + target_card(98, 136, 3, glow=True) + clock_buttons()
    body += '<path d="M148 160 C200 205 250 190 266 168" fill="none" stroke="%s" stroke-width="2.5" stroke-dasharray="1 6" stroke-linecap="round"/>' % SKYDEEP
    f.append(('L2 Another way: find the same number on the clock',
              'A dotted line runs from the card to the 3 on the dial, and that 3 gets a ring. It says: the hand must point at this 3. The buttons are not marked.',
              phone_frame(body)))
    body = clock(0, ghost3=True, badges=((1, 1), (2, 2), (3, 3))) + target_card(98, 136, 3) + clock_buttons(halo_plus=True)
    body += hand(345, 283, s=0.8)
    f.append(('L3 Watch me, then you',
              'The hand presses plus three times; the short hand steps 1, 2, 3 with a number at each step and arrives at 3; it goes back to 12 and a faint sky hand stays on 3. The child presses plus.',
              phone_frame(body)))
    return 'b40_m5_clock_hand', 'M5 clock_set (MATH-B-15: set the clock to 3)', f


# ---------------------------------------------------------------- M6 shop_pay: pay 8 shekels with 5, 2, 2, 1, 1
COINS = [(165, 's1', 40), (215, 's1', 40), (270, 's2', 46), (328, 's2', 46), (392, 's5', 52)]
TRAY = (212, 104, 180, 112)


def slots(filled, x0=222, y0=124, d=26):
    o = []
    for k in range(8):
        cx, cy = x0 + (k % 5) * d + 12, y0 + (k // 5) * 34 + 12
        if k < filled:
            o.append('<circle cx="%d" cy="%d" r="10" fill="%s" stroke="%s" stroke-width="2"/>' % (cx, cy, SPARK, SPARKDEEP))
        else:
            o.append('<circle cx="%d" cy="%d" r="10" fill="%s" stroke="%s" stroke-width="2" stroke-dasharray="3 3"/>' % (cx, cy, PAPER, INK))
    return ''.join(o)


def shop_stage(inner, price_glow=False):
    x, y, w, h = TRAY
    s = '<rect x="%d" y="%d" width="%d" height="%d" rx="18" fill="#DCC6AE" stroke="%s" stroke-width="3"/>' % (x, y, w, h, '#E6DDF0')
    s += img('apple', 120, 112, 46, 46)
    if price_glow:
        s += halo_rect(112, 172, 62, 32, rx=16)
    s += ('<rect x="112" y="172" width="62" height="32" rx="16" fill="%s"/>' % PAPER
          + '<g>' + text(143, 196, '8&#8362;', size=21, weight=800) + '</g>')
    return stage(s + inner)


def coins(skip=(), halo=()):
    o = []
    for i, (cx, name, d) in enumerate(COINS):
        if i in skip:
            o.append('<circle cx="%d" cy="278" r="%d" fill="none" stroke="%s" stroke-width="2" stroke-dasharray="3 4"/>' % (cx, d / 2, HAIR))
            continue
        if i in halo:
            o.append(halo_circle(cx, 278, d / 2 + 4))
        o.append(img('coin_' + name, cx - d / 2, 278 - d / 2, d, d))
    tick = ('<rect x="450" y="252" width="68" height="64" rx="18" fill="%s"/><rect x="450" y="246" width="68" height="64" rx="18" fill="%s" stroke="%s" stroke-width="2"/>'
            '<path d="M470 278 l10 10 l18 -20" fill="none" stroke="%s" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/>') % (LIP, PAPER, HAIR, INK)
    return ''.join(o) + tick


def m6():
    f = []
    body = shop_stage(slots(0), price_glow=True) + coins()
    body += arrow('M176 188 C195 188 205 160 228 150')
    f.append(('L1 Look here: the price, as places to fill',
              'The price tag glows and the counter shows eight empty coin places (a row of five and three more). It says: we must fill all of these.',
              phone_frame(body)))
    body = shop_stage(slots(5) + '<path d="M226 150 v6 h126 v-6" fill="none" stroke="%s" stroke-width="3"/>' % SKYDEEP + img('coin_s5', 352, 112, 36, 36) + badge(370, 158, 5, r=10)) + coins(skip=(4,))
    f.append(('L2 Together: the biggest coin that fits',
              'The guide puts the 5 on the counter: five places light up under it, three stay empty. It stops. It says: here is five, fill the three that are left.',
              phone_frame(body)))
    body = shop_stage(slots(8) + badge(372, 120, 8, big=True)) + coins(skip=(), halo=(0, 2, 4))
    body += hand(392, 300, s=0.75)
    f.append(('L3 Watch me, then you',
              'The coins go on one by one (5, then 2, then 1), each fills its places and the running number grows 5, 7, 8; all places glow. The coins go back and keep a soft halo; the child pays.',
              phone_frame(body)))
    return 'b40_m6_coins_grouping', 'M6 shop_pay (MATH-B-17: pay 8 shekels exactly)', f


# ---------------------------------------------------------------- M7 balance: 5+4 against 3+2, the tilt hidden
def cube(x, y, s=11, fill='#F59E1B', glow=False):
    g = '<rect x="%.1f" y="%.1f" width="%d" height="%d" rx="2" fill="none" stroke="%s" stroke-width="6" stroke-opacity=".7"/>' % (x - 1, y - 1, s + 2, s + 2, SKY) if glow else ''
    return g + '<rect x="%.1f" y="%.1f" width="%d" height="%d" rx="2" fill="%s" stroke="#A35A00" stroke-width="1.5"/>' % (x, y, s, s, fill)


def balance(tilt=0.0, lit_side=None, peg=True, towers=False):
    import math
    o = []
    bx, by, half, hang = 236, 106, 116, 82
    o.append('<rect x="230" y="%d" width="12" height="%d" fill="#C9A27A"/>' % (by, 214 - by))
    o.append('<rect x="200" y="210" width="72" height="8" rx="3" fill="#C9A27A"/>')
    a = math.radians(tilt)
    lx, ly = bx - half * math.cos(a), by - half * math.sin(a)
    rx_, ry = bx + half * math.cos(a), by + half * math.sin(a)
    o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="8" stroke-linecap="round"/>' % (lx, ly, rx_, ry, INK))
    if peg:
        o.append('<rect x="226" y="%d" width="20" height="14" rx="4" fill="%s"/>' % (by + 4, INKSOFT))
    for side, (px, py), n in (('L', (lx, ly), 9), ('R', (rx_, ry), 5)):
        o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="2"/>' % (px, py, px, py + hang, INKSOFT))
        o.append('<rect x="%.1f" y="%.1f" width="80" height="7" rx="3" fill="#C9A27A"/>' % (px - 40, py + hang))
        for k in range(n):
            if towers:
                o.append(cube(px - 4 - 14, py + hang - 8 * (k + 1), s=8, glow=(n == 9 and k >= 5)))
            else:
                cx, cy = px - 32 + (k % 5) * 13, py + hang - 12 * (k // 5 + 1)
                o.append(cube(cx, cy, glow=(lit_side == side)))
    if towers:
        y5 = by + hang - 40
        o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="3" stroke-dasharray="2 6" stroke-linecap="round"/>' % (lx - 30, y5, rx_ + 6, y5, SKYDEEP))
    return ''.join(o)


def m7():
    f = []
    arrows_tiles = (tile(218, '<path d="M240 291 h-44 M210 277 l-14 14 l14 14" fill="none" stroke="%s" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>' % INK)
                    + tile(338, '<path d="M318 284 h40 M318 298 h40" stroke="%s" stroke-width="5" stroke-linecap="round"/>' % INK)
                    + tile(458, '<path d="M436 291 h44 M466 277 l14 14 l-14 14" fill="none" stroke="%s" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>' % INK))
    body = stage(balance(lit_side='L')) + arrows_tiles
    body += arrow('M150 140 C200 92 280 92 330 140', None)
    f.append(('L1 Look here: one side, then the other',
              'The beam is held level by a small peg. The cubes on the left pan glow together, then the cubes on the right. It says: look at both piles.',
              phone_frame(body)))
    # L2: both piles stand up as towers on one floor (in the stage), the extra part of the taller tower glows
    o = [stage(balance(towers=True))]
    body = ''.join(o) + arrows_tiles
    f.append(('L2 Another way: two towers, one floor',
              'On each pan the cubes stack into one tower; the pans are level, so the towers stand on one floor. A dotted line runs from the top of the short tower across to the tall one, and the cubes above the line glow. It says: this side has more.',
              phone_frame(body)))
    arrows_l3 = (tile(218, '<path d="M240 291 h-44 M210 277 l-14 14 l14 14" fill="none" stroke="%s" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>' % INK, halo=True)
                 + tile(338, '<path d="M318 284 h40 M318 298 h40" stroke="%s" stroke-width="5" stroke-linecap="round"/>' % INK, dim=True)
                 + tile(458, '<path d="M436 291 h44 M466 277 l14 14 l-14 14" fill="none" stroke="%s" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>' % INK, dim=True))
    body = stage(balance(tilt=-6, peg=False)) + arrows_l3 + hand(222, 254, s=0.8)
    body += arrow('M150 200 C150 225 180 240 200 250')
    f.append(('L3 Watch me, then you',
              'The peg slides out and the beam tips slowly down on the heavier side; the hand goes from the low pan to the arrow that points the same way, which keeps a halo. The child taps it.',
              phone_frame(body)))
    return 'b40_m7_balance', 'M7 balance, compare with the tilt hidden (MATH-B-09 style: 5+4 against 3+2)', f


# ---------------------------------------------------------------- M0 the visual grammar and the shared pictures P1-P12
def m0():
    cw, ch = 210, 150
    cells = []

    def cell(i, title, inner):
        x, y = (i % 4) * cw, (i // 4) * ch
        return ('<g transform="translate(%d %d)"><rect x="6" y="6" width="%d" height="%d" rx="16" fill="%s" stroke="%s" stroke-width="2"/>' % (
            x, y, cw - 12, ch - 12, PAPER, HAIR) + text(cw / 2, 30, title, size=13, weight=700) + inner + '</g>')
    cells.append(cell(0, 'P1 spotlight', '<rect x="20" y="42" width="170" height="90" rx="12" fill="url(#skyg)"/>'
                      + '<rect x="20" y="42" width="170" height="90" rx="12" fill="%s" fill-opacity=".5"/>' % CREAM
                      + halo_circle(105, 88, 26) + img('frog', 85, 68, 40, 40)))
    cells.append(cell(1, 'P2 light each', ''.join(img('apple', 30 + k * 40, 70, 34, 34) for k in range(4))
                      + halo_circle(127, 87, 21) + img('apple', 110, 70, 34, 34)
                      + ''.join('<circle cx="%d" cy="70" r="4" fill="%s"/>' % (62 + k * 40, SKYDEEP) for k in range(2))))
    cells.append(cell(2, 'P3 two hands (5 and k)', counting_hand(75, 130, 5, s=1.1) + counting_hand(140, 130, 3, right=True, s=1.1)))
    cells.append(cell(3, 'P4 ten-frames', ten_frame(22, 60, 16, 10) + ten_frame(110, 60, 16, 4) + text(105, 120, '(counters fill like the number path, from the left)', size=9, weight=500, fill=INKSOFT)))
    p5 = ''.join(img('fish', 30 + k * 34, 46, 28, 28) for k in range(5)) + ''.join(img('duck', 30 + k * 34, 100, 28, 28) for k in range(3))
    p5 += ''.join('<line x1="%d" y1="76" x2="%d" y2="100" stroke="%s" stroke-width="2.5" stroke-dasharray="1 4" stroke-linecap="round"/>' % (44 + k * 34, 44 + k * 34, SKYDEEP) for k in range(3))
    p5 += halo_circle(146, 60, 15) + halo_circle(180, 60, 15) + img('fish', 132, 46, 28, 28) + img('fish', 166, 46, 28, 28)
    cells.append(cell(4, 'P5 pair lines', p5))
    p6 = ''.join('<rect x="%d" y="74" width="17" height="24" fill="%s" stroke="%s" stroke-width="1.5"/>' % (20 + k * 17, MIST if k % 2 else PAPER, INK) + text(28.5 + k * 17, 91, str(k + 1), size=10) for k in range(10))
    p6 += '<path d="M62 70 Q 71 50 80 70" fill="none" stroke="%s" stroke-width="2.5"/>' % SKYDEEP + '<path d="M79 70 Q 88 50 97 70" fill="none" stroke="%s" stroke-width="2.5"/>' % SKYDEEP
    cells.append(cell(5, 'P6 number path 1-10', p6 + text(105, 122, 'never mirrored: 1 at the left', size=9, weight=500, fill=INKSOFT)))
    row = ['red', 'blue', 'red', 'blue', 'red', 'blue']
    p7 = ''.join(img('ball_' + c, 22 + k * 28, 70, 24, 24) for k, c in enumerate(row))
    p7 += ''.join('<path d="M%d 100 v6 h50 v-6" fill="none" stroke="%s" stroke-width="2.5"/>' % (24 + k * 56, SKYDEEP) for k in range(3))
    cells.append(cell(6, 'P7 core bracket', p7 + '<rect x="190" y="66" width="0" height="0"/>'))
    p8 = '<line x1="30" y1="120" x2="30" y2="50" stroke="%s" stroke-width="3" stroke-dasharray="4 3"/>' % SKYDEEP
    p8 += '<rect x="32" y="62" width="120" height="14" rx="6" fill="#C98B4E"/><rect x="32" y="92" width="80" height="14" rx="6" fill="#C98B4E"/>'
    cells.append(cell(7, 'P8 baseline (one start line)', p8))
    p9 = swatch(60, 92, r=26) + '<rect x="120" y="60" width="64" height="64" rx="8" fill="none" stroke="%s" stroke-width="3" stroke-dasharray="6 4"/>' % SKYDEEP
    cells.append(cell(8, 'P9 sample: swatch, ghost', p9))
    p10 = '<rect x="80" y="76" width="56" height="40" rx="6" fill="#C98B4E"/>' + img('ball_red', 94, 50, 28, 28) + img('ball_blue', 140, 92, 24, 24)
    cells.append(cell(9, 'P10 act out (on, next to)', p10))
    p11 = ''
    p11 += '<line x1="24" y1="104" x2="186" y2="104" stroke="%s" stroke-width="3"/>' % INK
    p11 += ''.join('<line x1="%d" y1="98" x2="%d" y2="110" stroke="%s" stroke-width="2"/>' % (30 + k * 30, 30 + k * 30, INK) for k in range(6))
    p11 += '<path d="M60 96 Q 75 66 90 96" fill="none" stroke="%s" stroke-width="3"/>' % SKYDEEP + badge(75, 62, 1, r=9)
    p11 += img('frog', 84, 76, 24, 24).replace('x="76.0"', 'x="77.0"').replace('y="74.0"', 'y="72.0"')
    cells.append(cell(10, 'P11 first step together', p11))
    cells.append(cell(11, 'P12 the pointing hand', hand(110, 120, s=0.95)))
    body = ''.join(cells)
    svg = '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d">%s%s</svg>' % (4 * cw, 3 * ch, DEFS, body)
    return svg, 4 * cw, 3 * ch


# ---------------------------------------------------------------- page assembly and render
CSS = ("@font-face{font-family:Heebo;src:url('%s')}body{margin:0;background:#F6F1FA;font-family:Heebo;color:%s;width:%dpx}"
       "h1{font-size:20px;margin:14px 20px 4px}p.n{font-size:12px;margin:0 20px 10px;color:%s}"
       ".lv{margin:10px 20px 4px;font-size:15px;font-weight:800}.ck{margin:0 20px 6px;font-size:12.5px;line-height:1.35;color:%s}"
       ".fr{margin:0 20px 6px;border:1px solid #DCD3EC;width:%dpx;height:%dpx;background:%s}") % (FONT, INK, W + 40, INKSOFT, INKSOFT, W, H, CREAM)
NOTE = ('Phone 852 x 393 (iPhone 16 landscape). Bubbles left blank on purpose: each frame must work with the sound off. '
        'Thin grey dashed arrows show motion and exist only in this mock.')


def render(name, title, frames):
    os.makedirs(TMP, exist_ok=True)
    parts = ['<!doctype html><meta charset="utf-8"><style>%s</style><h1>%s</h1><p class="n">%s</p>' % (CSS, title, NOTE)]
    for (lv, check, svg) in frames:
        parts.append('<div class="lv">%s</div><div class="ck">Without words or sound: %s</div><div class="fr">%s</div>' % (lv, check, svg))
    height = 70 + len(frames) * (H + 78)
    html = os.path.join(TMP, name + '.html')
    with open(html, 'w', encoding='utf-8') as fh:
        fh.write(''.join(parts))
    shoot(html, os.path.join(OUT, name + '.png'), W + 40, height)


def shoot(html, png, w, h):
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
                    '--allow-file-access-from-files', '--virtual-time-budget=3000', '--window-size=%d,%d' % (w, h),
                    '--screenshot=' + png, 'file:///' + html.replace('\\', '/')], check=True, capture_output=True)


def main():
    for fn in (m1, m2, m3, m4, m5, m6, m7):
        render(*fn())
    svg, w, h = m0()
    html = os.path.join(TMP, 'b40_m0_shared_pictures.html')
    with open(html, 'w', encoding='utf-8') as fh:
        fh.write('<!doctype html><meta charset="utf-8"><style>%s</style><h1>The shared hint pictures P1 to P12</h1>'
                 '<p class="n">Grammar the child learns: a sky glow = look here (L1); a sky card with a new picture = another way (L2); '
                 'the sky hand = watch me (L3). Nothing is red, nothing marks an answer before L3.</p><div style="margin:0 20px">%s</div>' % (CSS, svg))
    shoot(html, os.path.join(OUT, 'b40_m0_shared_pictures.png'), w + 40, h + 90)


if __name__ == '__main__':
    main()
