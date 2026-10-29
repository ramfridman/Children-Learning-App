"""Draws the world map scenes of the home screen: the 7 lands on the phone strips and on the taller tablet portrait scene (B-23).

    python tools/make_home_map.py

Writes (deterministic: the same input files give the same bytes):
  app/assets/art/scenes/home_phone.svg            2102 x 393   the phone world strip (pans sideways, home island at the right end)
  app/assets/art/scenes/home_phone_se.svg         1834 x 375   the same strip for the iPhone SE
  app/assets/art/scenes/home_tablet_portrait.svg   820 x 1580  the tablet portrait scene (scrolls up, Market Village at the top)
The tablet landscape scene (home_tablet_landscape.svg) is not touched.

What is kept exactly: the approved boards 10, 12 and 25 (frozen copies in tools/home_map_src/, the files the app shipped before
B-23). Their islands, hosts, clouds, sparkles and paths are copied element for element and only moved (phone +1250, SE +1167
to the right; portrait +400 down), so Nitzi's island, Counting Hills, Colour Bay and the other approved islands look the same.
The sea waves are redrawn over the whole scene on the same 120 x 38 grid and in the same phase, so old and new parts join
without a seam. The hosts on the new islands are the cast's own pictures (design/assets/kubi.svg, timi.svg, tzaadon.svg,
pnina.svg), drawn at 0.1 like the hosts already on the boards.

What is new, drawn here in plain shapes (our own drawings; nothing traced or copied, no text or numerals, no franchise look):
  Shape Forest (Kubi): two columnar cypress cones, a clipped sphere bush, a cube rock of pale limestone, and a small pond in
    which the bush is mirrored (the symmetry pond of design-spec 3.2).
  Riddle Grotto (Timi): a pale chalk cliff with soft horizontal layers and a round-topped arch opening onto blue water, a few
    darker boulders at its foot, and a row of shells in a pattern (pink, gold, pink, gold).
  Robot Harbour (Tza'adon): a blue gantry crane (two legs, a top beam, a trolley, a cable, a hanging box), a stack of
    containers in a grid, and a plank pier on posts.
  Market Village (Grandma Pnina): a stall with a scalloped striped awning and heaps of round fruit in colour blocks, and a
    clock tower of honey limestone in three tiers with ledges, arched windows, a clock face with two hands (no numerals; a
    clock is never mirrored) and a pointed slate-green roof with a gold ball.
  Plus the dotted path between all 7 lands, a sailboat, clouds and sparkles across the new sea.

References looked at on 2026-10-29 (facts and photographs; the look is ours):
  Rosh HaNikra grottoes, https://en.wikipedia.org/wiki/Rosh_HaNikra_grottoes and the photograph "The Elephant foot rock at
    Rosh hanikra" (Wikimedia Commons, https://commons.wikimedia.org/wiki/Category:Rosh_HaNikra_grottoes): white-cream chalk
    cliff, soft horizontal layering, a rounded arch at the waterline, darker boulders, clear blue water.
  Jaffa Clock Tower, https://en.wikipedia.org/wiki/Jaffa_Clock_Tower and its lead photograph (Jaffa_Clock_Tower,_2019_(03).jpg):
    a square tower of honey-coloured limestone in three tiers divided by cornices, tall arched windows, a white clock face on
    the top tier, a pointed dark green roof with a finial.
  Carmel Market, Tel Aviv, photograph "128488 tel aviv carmel market" (PikiWiki Israel, Wikimedia Commons) and Mahane Yehuda
    Market, https://en.wikipedia.org/wiki/Mahane_Yehuda_Market: produce heaped in sloping blocks of one colour each (orange,
    green, dark purple), awnings over the stalls.
  Port of Haifa, photograph "Containers in Port of Haifa.jpg" (Wikimedia Commons): a blue gantry crane over rows of stacked
    containers in muted red, teal, blue and yellow.
  Mediterranean cypress, https://en.wikipedia.org/wiki/Cupressus_sempervirens: the planted form is a narrow dark green spire
    (our cone tree); clipped box balls and limestone blocks for the sphere and the cube.
  Our approved boards: design/renders/04-world-map.png, 10-phone-home.png, 12-phone-se-home.png, 22-tablet-home-landscape.png,
    25-tablet-home-portrait.png (island style, palette, sign places, path dots, boat).
"""
import os
import re

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
SRC = os.path.join(ROOT, 'tools', 'home_map_src')
OUT = os.path.join(ROOT, 'app', 'assets', 'art', 'scenes')
CAST = os.path.join(ROOT, 'design', 'assets')

# Palette: design/tokens.json › color.world, plus the colours the approved boards already use.
SEA, WAVE, FOAM = '#A8E3E3', '#6CCBCD', '#FFFFFF'
SAND, SAND_SHADE, GRASS, GRASS_SHADE = '#F6DDB0', '#E8C48A', '#A8DB8F', '#86C474'
WOOD, WOOD_LIGHT, CORAL, GOLD, INK = '#B07A52', '#D7A27A', '#F07F6E', '#FFC83D', '#3B2C85'


def f(v):
    """A number as the boards write it: no trailing zeros."""
    s = ('%.2f' % v).rstrip('0').rstrip('.')
    return '0' if s == '-0' else s


def el(tag, **a):
    attrs = ' '.join('%s="%s"' % (k.rstrip('_').replace('_', '-'), f(v) if isinstance(v, (int, float)) else v) for k, v in a.items())
    return '<%s %s/>' % (tag, attrs)


def g(body, x=0, y=0, s=1, opacity=None):
    t = 'translate(%s %s)' % (f(x), f(y)) + ('' if s == 1 else ' scale(%s)' % f(s))
    return '<g transform="%s"%s>%s</g>' % (t, '' if opacity is None else ' opacity="%s"' % f(opacity), ''.join(body))


# ---------------------------------------------------------------- reading the approved boards
def read_board(name):
    s = open(os.path.join(SRC, name), encoding='utf-8').read()
    head = re.match(r'<svg [^>]*>', s).group(0)
    label = re.search(r'aria-label="([^"]*)"', head).group(1)
    body = s[len(head):s.rindex('</svg>')]
    body = re.sub(r'^<rect x="0" y="0" [^>]*></rect>', '', body)                       # the sea rectangle: redrawn
    body = re.sub(r'<path d="M-?[\d.]+ -?[\d.]+ q15 -8 30 0 q15 8 30 0"[^>]*></path>', '', body)  # the waves: redrawn
    return label, body


def cast(name, x, y):
    """A host from the cast sheet at 0.1 of its 512 canvas (51 points), its top-left corner at x, y."""
    s = open(os.path.join(CAST, name + '.svg'), encoding='utf-8').read()
    inner = s[s.index('>', s.index('<svg')) + 1:s.rindex('</svg>')]
    return '<g transform="translate(%s %s) scale(0.1)">%s</g>' % (f(x), f(y), inner)


# ---------------------------------------------------------------- sea, paths, sky bits
def waves(w, h, ox, oy):
    """The boards' waves: rows 38 apart, every 120 along, odd rows shifted 60. ox, oy move the grid with the old art."""
    out = []
    r0 = -((oy + 20) // 38) - 1
    r = r0
    while 20 + oy + 38 * r < h + 20:
        y = 20 + oy + 38 * r
        off = 60 if r % 2 else 0
        k = -((ox + off) // 120) - 1
        while ox + off + 120 * k < w + 10:
            x = ox + off + 120 * k
            if x > -70:
                out.append('<path d="M%s %s q15 -8 30 0 q15 8 30 0" stroke="%s" stroke-width="3" stroke-linecap="round" fill="none" opacity="0.55"/>'
                           % (f(x), f(y), WAVE))
            k += 1
        r += 1
    return out


def dots(d, width=5, dash='2 12'):
    return ('<path d="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round" '
            'stroke-dasharray="%s" opacity="0.9"/>' % (d, FOAM, width, dash))


def hop(x1, y1, x2, y2, sag=50):
    """A dotted hop from the right island to the left one, dipping into the sea like the boards' paths."""
    return dots('M%s %s C%s %s %s %s %s %s' % (f(x1), f(y1), f(x1 - 50), f(y1 + sag), f(x2 + 50), f(y2 + sag), f(x2), f(y2)))


def cloud(x, y, s=1.0, opacity=0.8):
    return g([el('ellipse', cx=0, cy=8 * s, rx=34 * s, ry=14 * s, fill=FOAM), el('circle', cx=-12 * s, cy=0, r=14 * s, fill=FOAM),
              el('circle', cx=10 * s, cy=-4 * s, r=18 * s, fill=FOAM)], x, y, opacity=opacity)


def sparkle(x, y, r=7):
    q = r * 0.22
    return el('path', d='M%s %s Q%s %s %s %s Q%s %s %s %s Q%s %s %s %s Q%s %s %s %s Z' % (
        f(x), f(y - r), f(x + q), f(y - q), f(x + r), f(y), f(x + q), f(y + q), f(x), f(y + r),
        f(x - q), f(y + q), f(x - r), f(y), f(x - q), f(y - q), f(x), f(y - r)), fill=GOLD)


def boat(x, y, s=1.0):
    """A small sailboat (board 04): orange and white sails, a wooden hull."""
    return g([el('path', d='M-26 0 L26 0 L18 12 L-18 12 Z', fill='#B9875A'),
              el('path', d='M-24 0 L24 0 L22 3 L-22 3 Z', fill='#D7A27A'),
              el('rect', x=-1.5, y=-44, width=3, height=44, fill='#8A5F3E'),
              el('path', d='M-2 -42 L-2 -4 L-24 -4 Z', fill='#FF8A1F'),
              el('path', d='M2 -44 L2 -4 L22 -4 Z', fill=FOAM),
              el('path', d='M2 -44 L2 -4 L9 -4 Z', fill='#E6E1F0')], x, y, s)


def gull(x, y):
    return el('path', d='M%s %s q8 -9 16 0 q8 -9 16 0' % (f(x), f(y)), fill='none', stroke='#3FAFB3', stroke_width=3.5,
              stroke_linecap='round', stroke_linejoin='round')


# ---------------------------------------------------------------- an island in the boards' layers
def island_base(R, ry):
    """The boards' island in local coordinates (0, 0 = the sand's centre): sea halo, foam rim, sand edge, sand, grass."""
    k = ry / 64.4
    return [el('ellipse', cx=0, cy=19.6 * k, rx=1.08 * R, ry=1.1087 * ry, fill=WAVE, opacity=0.6),
            el('ellipse', cx=0, cy=8.4 * k, rx=1.02 * R, ry=1.0326 * ry, fill=FOAM, opacity=0.85),
            el('ellipse', cx=0, cy=5.6 * k, rx=R, ry=ry, fill=SAND_SHADE),
            el('ellipse', cx=0, cy=0, rx=0.98 * R, ry=0.9348 * ry, fill=SAND),
            el('ellipse', cx=0, cy=-8.4 * k, rx=0.82 * R, ry=0.7174 * ry, fill=GRASS_SHADE),
            el('ellipse', cx=0, cy=-12.6 * k, rx=0.8 * R, ry=0.6522 * ry, fill=GRASS)]


# Landmarks: local coordinates for an island of R 124 (phone); y 0 is the sand's centre, the grass top is near y -56.
def shapes_landmark():
    out = []
    # Two cypress spires (cones): a lit left half and a shaded right half.
    for (bx, by, w, h) in ((-76, 6, 24, 66), (-48, 2, 19, 48)):
        out += [el('path', d='M%s %s L%s %s L%s %s Z' % (f(bx - w / 2), f(by), f(bx), f(by - h), f(bx + w / 2), f(by)), fill='#34A86A'),
                el('path', d='M%s %s L%s %s L%s %s Z' % (f(bx), f(by - h), f(bx + w / 2), f(by), f(bx + w * 0.08), f(by)), fill='#1E7F4C', opacity=0.5),
                el('rect', x=bx - 2, y=by - 1, width=4, height=5, rx=1.5, fill=WOOD)]
    # The pond, with the sphere bush mirrored in it.
    out += [el('ellipse', cx=36, cy=26, rx=22, ry=7.5, fill='#5FB8DE'),
            el('ellipse', cx=36, cy=27.5, rx=10, ry=4.5, fill='#2E8A55', opacity=0.45),
            el('path', d='M22 25 q6 -2 12 0', fill='none', stroke=FOAM, stroke_width=1.8, stroke_linecap='round', opacity=0.8)]
    # Sphere bush.
    out += [el('ellipse', cx=36, cy=12, rx=12, ry=3, fill='#2B2350', opacity=0.14),
            el('circle', cx=36, cy=-2, r=14, fill='#2E8A55'),
            el('circle', cx=34, cy=-4, r=12, fill='#4CB673'),
            el('ellipse', cx=29, cy=-9, rx=4.5, ry=3, fill=FOAM, opacity=0.35, transform='rotate(-30 29 -9)')]
    # Cube rock of pale limestone: top, lit side, shaded side.
    cx, cy, a = 72, 2, 11
    out += [el('path', d='M%s %s L%s %s L%s %s L%s %s Z' % (f(cx - a), f(cy - a * 0.55), f(cx), f(cy - a * 1.1), f(cx + a), f(cy - a * 0.55), f(cx), f(cy)), fill='#F4ECDB'),
            el('path', d='M%s %s L%s %s L%s %s L%s %s Z' % (f(cx - a), f(cy - a * 0.55), f(cx), f(cy), f(cx), f(cy + a * 1.15), f(cx - a), f(cy + a * 0.6)), fill='#DCCDAE'),
            el('path', d='M%s %s L%s %s L%s %s L%s %s Z' % (f(cx), f(cy), f(cx + a), f(cy - a * 0.55), f(cx + a), f(cy + a * 0.6), f(cx), f(cy + a * 1.15)), fill='#C2AE88')]
    return out


def grotto_landmark():
    out = []
    # The chalk cliff: a lumpy headland, taller on the left, lit on the left and shaded on its right flank.
    cx, base, rx = -22, 12, 60
    out.append(el('ellipse', cx=cx, cy=base + 2, rx=rx + 6, ry=6, fill='#2B2350', opacity=0.12))
    out.append(el('path', d='M-86 12 C-90 -12 -84 -38 -70 -48 C-62 -64 -44 -72 -30 -64 C-18 -76 4 -70 12 -54 '
                            'C26 -50 40 -30 40 12 Z', fill='#EFE2C4'))
    out.append(el('path', d='M12 -54 C26 -50 40 -30 40 12 L22 12 C26 -8 24 -30 12 -54 Z', fill='#D9C59C'))
    out.append(el('path', d='M-30 -64 C-24 -58 -22 -52 -24 -46 C-14 -54 -4 -62 12 -54 C4 -70 -18 -76 -30 -64 Z', fill='#F8F0DD'))
    # Soft layers in the chalk: short wavy strokes that follow the rock, not rings.
    for (x1, y1, x2, y2) in ((-80, -24, -40, -30), (-24, -34, 18, -28), (-82, -2, -48, -6), (6, -10, 34, -4), (-66, -46, -34, -52)):
        out.append(el('path', d='M%s %s q%s 4 %s %s' % (f(x1), f(y1), f((x2 - x1) / 2), f(x2 - x1), f(y2 - y1)),
                      fill='none', stroke='#CDB585', stroke_width=2, stroke_linecap='round', opacity=0.75))
    # The arch, with the sea inside.
    ax, aw, top = cx - 4, 20, base - 40
    out += [el('path', d='M%s %s L%s %s A%s %s 0 0 1 %s %s L%s %s Z' % (f(ax - aw), f(base), f(ax - aw), f(top + aw), f(aw), f(aw), f(ax + aw), f(top + aw), f(ax + aw), f(base)), fill=INK),
            el('path', d='M%s %s L%s %s L%s %s L%s %s Z' % (f(ax - aw), f(base), f(ax - aw), f(base - 9), f(ax + aw), f(base - 9), f(ax + aw), f(base)), fill='#4FA9D9'),
            el('path', d='M%s %s q5 -2.5 10 0 q5 2.5 10 0' % (f(ax - 12), f(base - 5)), fill='none', stroke=FOAM, stroke_width=1.8, stroke_linecap='round', opacity=0.85)]
    # Boulders at the foot of the cliff.
    out += [el('ellipse', cx=cx - rx + 2, cy=base + 1, rx=10, ry=6.5, fill='#C9B184'),
            el('ellipse', cx=cx + rx - 4, cy=base + 3, rx=8, ry=5, fill='#C9B184'),
            el('ellipse', cx=cx + rx + 8, cy=base + 6, rx=5.5, ry=3.8, fill='#B39A6B')]
    # Shells in a pattern along the shore: pink, gold, pink, gold, pink.
    for i, x in enumerate((-58, -42, -26, -10, 6)):
        col = '#F4A7B4' if i % 2 == 0 else GOLD
        dark = '#D9788A' if i % 2 == 0 else '#D9A21F'
        y = 30
        out += [el('path', d='M%s %s A6 6 0 0 1 %s %s Z' % (f(x - 6), f(y), f(x + 6), f(y)), fill=col),
                el('path', d='M%s %s L%s %s M%s %s L%s %s M%s %s L%s %s' % (f(x), f(y), f(x), f(y - 5.5), f(x), f(y), f(x - 3.6), f(y - 4), f(x), f(y), f(x + 3.6), f(y - 4)),
                   fill='none', stroke=dark, stroke_width=1.2, stroke_linecap='round')]
    return out


def harbour_landmark():
    out = []
    blue, blue_dark = '#2F7FE0', '#1F63C7'
    # Containers stacked in a grid: 3 at the bottom, 2, then 1.
    w, h = 17, 10
    rows = (((-78, -1), ('#D9644F', '#2BA39B', '#5B8DEF')), ((-69.5, -11), ('#F2B33D', '#D9644F')), ((-61, -21), ('#2BA39B',)))
    out.append(el('ellipse', cx=-52, cy=10, rx=30, ry=4, fill='#2B2350', opacity=0.12))
    for (x0, y0), cols in rows:
        for i, c in enumerate(cols):
            x = x0 + i * (w + 0.5)
            out += [el('rect', x=x, y=y0, width=w, height=h, rx=1.5, fill=c),
                    el('rect', x=x, y=y0 + h - 2.2, width=w, height=2.2, fill='#2B2350', opacity=0.18),
                    el('path', d='M%s %s v%s M%s %s v%s M%s %s v%s' % (f(x + 4.5), f(y0 + 2), f(h - 5), f(x + 8.5), f(y0 + 2), f(h - 5), f(x + 12.5), f(y0 + 2), f(h - 5)),
                       fill='none', stroke='#2B2350', stroke_width=1, opacity=0.2)]
    # The gantry crane: two legs, a top beam reaching out over the sea, a trolley, a cable and a box.
    out += [el('rect', x=6, y=-62, width=5, height=70, rx=1, fill=blue),
            el('rect', x=44, y=-62, width=5, height=70, rx=1, fill=blue_dark),
            el('path', d='M11 -30 L44 -50 M11 -50 L44 -30', fill='none', stroke=blue, stroke_width=2.2),
            el('rect', x=-4, y=-68, width=92, height=7, rx=2, fill=blue),
            el('rect', x=-4, y=-63, width=92, height=2, fill=blue_dark),
            el('rect', x=60, y=-61, width=10, height=5, rx=1, fill='#2B2350'),
            el('path', d='M65 -56 L65 -36', fill='none', stroke='#2B2350', stroke_width=1.6),
            el('rect', x=57, y=-36, width=16, height=10, rx=1.5, fill='#F2B33D'),
            el('rect', x=57, y=-28.2, width=16, height=2.2, fill='#2B2350', opacity=0.18),
            el('rect', x=4, y=6, width=9, height=4, rx=1, fill='#2B2350', opacity=0.6),
            el('rect', x=42, y=6, width=9, height=4, rx=1, fill='#2B2350', opacity=0.6)]
    # A plank pier on posts, out into the sea at the front right.
    out += [el('rect', x=88, y=40, width=4, height=12, rx=1, fill='#8A5F3E'),
            el('rect', x=110, y=36, width=4, height=12, rx=1, fill='#8A5F3E'),
            el('path', d='M70 34 L118 26 L119 33 L71 41 Z', fill=WOOD_LIGHT),
            el('path', d='M82 32 L83 39 M94 30 L95 37 M106 28 L107 35', fill='none', stroke=WOOD, stroke_width=1.2)]
    return out


def market_landmark():
    out = []
    # The stall: posts, a counter with heaps of fruit in colour blocks, a scalloped striped awning.
    out += [el('ellipse', cx=-50, cy=10, rx=34, ry=4, fill='#2B2350', opacity=0.12),
            el('rect', x=-81, y=-38, width=3.5, height=46, rx=1, fill=WOOD),
            el('rect', x=-22, y=-38, width=3.5, height=46, rx=1, fill=WOOD),
            el('rect', x=-84, y=-6, width=68, height=15, rx=2, fill=WOOD_LIGHT),
            el('rect', x=-84, y=3, width=68, height=6, rx=2, fill='#B98A5E')]
    heaps = (('#FF9A3C', '#E37A1E'), ('#9CCB5B', '#76A93A'), ('#7B4A9E', '#5C3480'))
    for i, (c, cd) in enumerate(heaps):
        bx = -77 + i * 21
        for (dx, dy) in ((0, 0), (6.5, 0), (13, 0), (3.2, -5.5), (9.8, -5.5), (6.5, -11)):
            out += [el('circle', cx=bx + dx + 0.6, cy=-9.5 + dy + 0.8, r=3.6, fill=cd), el('circle', cx=bx + dx, cy=-9.5 + dy, r=3.4, fill=c)]
    stripe = 10
    for i in range(7):
        x = -87 + i * stripe
        c = CORAL if i % 2 == 0 else '#FFF6E8'
        out += [el('rect', x=x, y=-46, width=stripe, height=12, fill=c),
                el('path', d='M%s %s A5 5 0 0 0 %s %s Z' % (f(x), f(-34), f(x + stripe), f(-34)), fill=c)]
    out.append(el('rect', x=-88, y=-49, width=72, height=4, rx=2, fill='#D9604F'))
    # The clock tower: three tiers of honey limestone, ledges, arched windows, the clock, a pointed roof and a gold ball.
    tx, base = 58, 8
    tiers = ((26, 26), (23, 22), (21, 20))         # (width, height) bottom to top
    y = base
    for n, (w, h) in enumerate(tiers):
        x0 = tx - w / 2
        out += [el('rect', x=x0, y=y - h, width=w, height=h, fill='#EBCB91'),
                el('rect', x=tx + w * 0.18, y=y - h, width=w * 0.32, height=h, fill='#D8B072')]
        if n == 0:
            out.append(el('path', d='M%s %s L%s %s A4.5 4.5 0 0 1 %s %s L%s %s Z' % (f(tx - 4.5), f(y), f(tx - 4.5), f(y - 11), f(tx + 4.5), f(y - 11), f(tx + 4.5), f(y)), fill='#6B4F8A'))
        elif n == 1:
            for wx in (tx - 5.5, tx + 2.5):
                out.append(el('path', d='M%s %s L%s %s A1.5 1.5 0 0 1 %s %s L%s %s Z' % (f(wx), f(y - 4), f(wx), f(y - 14), f(wx + 3), f(y - 14), f(wx + 3), f(y - 4)), fill='#6B4F8A'))
        else:
            cy = y - h / 2
            out += [el('circle', cx=tx, cy=cy, r=7.4, fill=FOAM, stroke=INK, stroke_width=1.6)]
            for (ddx, ddy) in ((0, -5), (5, 0), (0, 5), (-5, 0)):
                out.append(el('circle', cx=tx + ddx, cy=cy + ddy, r=0.9, fill=INK))
            out += [el('path', d='M%s %s L%s %s' % (f(tx), f(cy), f(tx - 2.6), f(cy - 2.6)), fill='none', stroke=INK, stroke_width=1.8, stroke_linecap='round'),
                    el('path', d='M%s %s L%s %s' % (f(tx), f(cy), f(tx + 3.8), f(cy - 3.8)), fill='none', stroke='#D62F2F', stroke_width=1.3, stroke_linecap='round'),
                    el('circle', cx=tx, cy=cy, r=1.1, fill=INK)]
        y -= h
        out.append(el('rect', x=tx - w / 2 - 2, y=y - 1.5, width=w + 4, height=3.5, rx=1, fill='#F7E4BD'))
    # Roof and finial.
    out += [el('path', d='M%s %s L%s %s L%s %s Z' % (f(tx - 12.5), f(y - 1.5), f(tx), f(y - 28), f(tx + 12.5), f(y - 1.5)), fill='#3F7F70'),
            el('path', d='M%s %s L%s %s L%s %s Z' % (f(tx), f(y - 28), f(tx + 12.5), f(y - 1.5), f(tx + 3), f(y - 1.5)), fill='#2F655A'),
            el('path', d='M%s %s L%s %s' % (f(tx), f(y - 28), f(tx), f(y - 33)), fill='none', stroke='#2F655A', stroke_width=1.5),
            el('circle', cx=tx, cy=y - 35, r=3, fill=GOLD)]
    return out


NEW = {
    'shapes': (shapes_landmark, 'kubi', (-30, -43)),
    'logic': (grotto_landmark, 'timi', (40, -47)),
    'robots': (harbour_landmark, 'tzaadon', (-26, -44)),
    'market': (market_landmark, 'pnina', (-14, -44)),
}


def new_island(land, cx, cy, R=124, ry=67, s=1.0):
    draw, host, (hx, hy) = NEW[land]
    k = ry / 67
    body = island_base(R, ry) + [g(draw(), 0, 0, s)] + [cast(host, hx * s, hy * s + (k - 1) * 10)]
    return '<g id="island-%s">%s</g>' % (land, g(body, cx, cy))


def svg(w, h, label, parts):
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" role="img" aria-label="%s">' % (w, h, label)
            + el('rect', x=0, y=0, width=w, height=h, fill=SEA) + ''.join(parts) + '</svg>\n')


# ---------------------------------------------------------------- the three scenes
def phone_strip(src, out, W, H, shift, cy_low, cy_high, spacing, R, ry):
    """A world strip: today's approved board at the right end (moved by `shift`), the 4 new lands to its left.
    Colour Bay keeps its place; shapes, logic, robots and market follow `spacing` apart, alternating high and low."""
    label, old = read_board(src)
    if 'board12' in src:
        # B-26 design review (docs/design/b26-step2-review.md section 4): the sparkle at (413.5, 112.5) sat half under the map
        # bubble's top edge and looked like a glitch; it moves to the open sea left of the bubble (same size, same shape).
        spark = re.search(r'<path d="M413\.5 105\.5 Q[^"]*" fill="#FFC83D" ></path>', old).group(0)
        old = old.replace(spark, sparkle(280, 112.5, 7))
    colours_x = (70 if 'board10' in src else 22) + shift
    xs = {'shapes': colours_x - spacing, 'logic': colours_x - 2 * spacing, 'robots': colours_x - 3 * spacing, 'market': colours_x - 4 * spacing}
    cys = {'shapes': cy_high, 'logic': cy_low, 'robots': cy_high, 'market': cy_low}
    parts = waves(W, H, shift % 120, 0)
    # The dotted path: Colour Bay to Shape Forest, and on to the market.
    chain = [(colours_x, cy_low)] + [(xs[k], cys[k]) for k in ('shapes', 'logic', 'robots', 'market')]
    for (x1, y1), (x2, y2) in zip(chain, chain[1:]):
        parts.append(hop(x1 - 96, y1 + 14, x2 + 96, y2 + 18))
    for k in ('shapes', 'logic', 'robots', 'market'):
        parts.append(new_island(k, xs[k], cys[k], R, ry))
    # Sky and sea bits over the new part (the old part keeps its own).
    sk = colours_x - 70
    parts += [cloud(sk - 1000, 50), cloud(sk - 520, 62, 0.85), cloud(sk - 120, 46, 0.9),
              sparkle(sk - 860, 126), sparkle(sk - 300, 136, 6), sparkle(sk - 1130, 150, 6),
              boat(sk - 650, 160, 0.9), gull(sk - 1210, 140), gull(sk - 1180, 128)]
    parts.append('<g id="board" transform="translate(%s 0)">%s</g>' % (f(shift), old))
    write(out, svg(W, H, label, parts))
    return xs, cys, colours_x


def portrait(src, out, W, H, D):
    """The tablet portrait scene: board 25 moved down by D, Market Village drawn in the new band at the top."""
    label, old = read_board(src)
    parts = waves(W, H, 0, D)
    mx, mcy = 560, 270
    parts.append(dots('M370 585 C340 500 410 400 470 300', width=6, dash='2 14'))
    parts.append(new_island('market', mx, mcy, 114, 66, 1.08))
    parts += [cloud(150, 150, 1.1, 0.9), cloud(720, 300, 0.9), boat(170, 330, 1.1), sparkle(330, 210, 8), sparkle(760, 210, 7),
              gull(250, 372), gull(282, 360)]
    parts.append('<g id="board" transform="translate(0 %s)">%s</g>' % (f(D), old))
    write(out, svg(W, H, label, parts))
    return mx, mcy


def write(name, text):
    with open(os.path.join(OUT, name), 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(text)


if __name__ == '__main__':
    print('phone', phone_strip('board10_home_phone.svg', 'home_phone.svg', 2102, 393, 1250, 262, 248, 280, 124, 67))
    print('phoneSE', phone_strip('board12_home_phone_se.svg', 'home_phone_se.svg', 1834, 375, 1167, 258, 244, 252, 120, 65))
    print('portrait', portrait('board25_home_tablet_portrait.svg', 'home_tablet_portrait.svg', 820, 1580, 400))
