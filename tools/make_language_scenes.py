"""Batch 4 of the shared Languages pictures: the story pages, the place pictures, the scenes and course pieces, the
action key poses and the composites (docs/languages/pictures.md section 4.3).

    python tools/make_language_scenes.py           # writes the SVGs
    python tools/make_language_scenes.py --sheet   # and one contact sheet per part (pictures_batch4a.png, ...)

Story pages are 384 x 216 (16:9; the story player fits them to its stage); every other picture is 256 x 256 like the
objects. Each page is built from the set's own drawings (the objects of batches 1 and 2, the approved people of batch 3,
the hosts and the app's cast for Nitzi, Kubi and friends), so a cat on a story page is the cat of the word items and the
characters stay on model. Pages are kept uncluttered for a 3-year-old: a plain sky and ground, the one or two things the
line talks about, and nothing else. No text, no letters or numerals in any picture.

References: the drawings this module reuses carry their own (tools/make_language_pictures.py, _b2.py, _people.py,
make_language_characters.py, make_languages_art.py); the story texts and the pictures they ask for are the teachers'
(docs/languages/english/band-a-content.md ENG-A-15, hebrew/band-a-content.md section 5, russian/band-a-content.md
RUS-A-16 with russian/pronunciation.csv st1 to st3).
"""
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_language_pictures as m  # noqa: E402
import make_language_pictures_b2 as b2  # noqa: E402
import make_language_characters as ch  # noqa: E402
import make_language_people as pe  # noqa: E402

ROOT, OUT = m.ROOT, m.OUT
INK, WHITE, CREAM = m.INK, m.WHITE, m.CREAM
f = ch.f
P, L, E, RR = ch.P, ch.L, ch.E, ch.RR
CAST = os.path.join(ROOT, 'design', 'assets')
LANG = os.path.join(ROOT, 'app', 'assets', 'art', 'languages')
W, H = 384, 216
_n = [0]


def tag():
    _n[0] += 1
    return 'k%d' % _n[0]


def page(parts, bg):
    body = ''.join(bg + parts)
    text = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">'
            '<clipPath id="page"><rect x="0" y="0" width="%d" height="%d" rx="18"/></clipPath>'
            '<g clip-path="url(#page)" stroke-linejoin="round" stroke-linecap="round">%s</g></svg>\n' % (W, H, W, H, W, H, body))
    return compact(text)


def compact(text):
    """As make_language_people.compact: round joins and caps once on the outer group, short numbers in paths."""
    for a in (' stroke-linejoin="round" stroke-linecap="round"', ' stroke-linecap="round" stroke-linejoin="round"',
              ' stroke-linecap="round"', ' stroke-linejoin="round"'):
        text = text.replace(a, '')
    text = text.replace('<g clip-path="url(#page)">', '<g clip-path="url(#page)" stroke-linejoin="round" stroke-linecap="round">', 1)

    def num(mm):
        v = float(mm.group(0))
        r = round(v)
        return str(int(r)) if abs(v - r) < 0.25 else ('%.1f' % v).rstrip('0').rstrip('.')
    return re.sub(r' d="([^"]*)"', lambda dm: ' d="%s"' % re.sub(r'-?\d+\.\d+', num, dm.group(1)), text)


# ---- backgrounds ---------------------------------------------------------------------------------------------------

def garden(path=False):
    out = ['<rect x="0" y="0" width="%d" height="%d" fill="#DFF1FB"/>' % (W, H),
           '<path d="M 0 140 C 90 128, 290 128, 384 140 L 384 216 L 0 216 Z" fill="#B5DFA0"/>']
    if path:
        out.append('<path d="M 0 196 C 120 172, 260 172, 384 190 L 384 216 L 0 216 Z" fill="#EADBB8"/>')
    return out


def kitchen():
    return ['<rect x="0" y="0" width="%d" height="%d" fill="#FFF3E0"/>' % (W, H),
            '<rect x="0" y="0" width="%d" height="22" fill="#FCE1F0"/>' % W,
            '<rect x="0" y="168" width="%d" height="48" fill="#E8C590"/>' % W,
            '<rect x="0" y="164" width="%d" height="8" fill="#C98F52"/>' % W]


def lake():
    return ['<rect x="0" y="0" width="%d" height="%d" fill="#DFF1FB"/>' % (W, H),
            '<path d="M 0 118 C 120 110, 270 110, 384 118 L 384 216 L 0 216 Z" fill="#8FD3F4"/>',
            '<path d="M 0 118 C 120 110, 270 110, 384 118" fill="none" stroke="#5BB8E0" stroke-width="3"/>']


def snow():
    return ['<rect x="0" y="0" width="%d" height="%d" fill="#E6F0FA"/>' % (W, H),
            '<path d="M 0 150 C 100 136, 280 136, 384 150 L 384 216 L 0 216 Z" fill="#FFFFFF" stroke="#CFE3F5" stroke-width="3"/>']


def beach():
    return ['<rect x="0" y="0" width="%d" height="%d" fill="#CFEFFF"/>' % (W, H),
            '<rect x="0" y="110" width="%d" height="40" fill="#5BB8E0"/>' % W,
            '<path d="M 0 150 C 120 140, 270 140, 384 150 L 384 216 L 0 216 Z" fill="#F7E2B0"/>']


def room():
    return ['<rect x="0" y="0" width="%d" height="%d" fill="#F4EEFB"/>' % (W, H),
            '<rect x="0" y="160" width="%d" height="56" fill="#E3D6C6"/>' % W, '<rect x="0" y="156" width="%d" height="6" fill="#C9B89A"/>' % W]


# ---- placing drawings ----------------------------------------------------------------------------------------------

def unique(text, t):
    return re.sub(r'(id="|url\(#)([a-z]*\d+)', lambda mm: mm.group(1) + t + mm.group(2), text)


def obj(pic, x, y, s, flip=False, rot=0, ground=232, air=False):
    """An object picture (256 canvas, its ground near y 232) standing with its bottom centre at (x, y); air=True leaves
    out its ground shadow (a ball in the air, a jumping dog)."""
    parts = [q for q in pic.parts if not (air and 'opacity="0.12"' in q and q.startswith('<ellipse'))]
    inner = unique(''.join(parts), tag())
    sx = -s if flip else s
    return '<g transform="translate(%s %s) rotate(%s) scale(%s %s) translate(-128 %s)">%s</g>' % (f(x), f(y), f(rot), f(sx), f(s), f(-ground), inner)


def asset(path, x, y, s, flip=False, drop=None, ground=466, rot=0):
    text = open(path, encoding='utf-8').read()
    inner = text[text.index('>', text.index('<svg')) + 1:text.rindex('</svg>')]
    inner = inner.replace('fill="rgba(43,35,80,0.14)"', 'fill="#2B2350" opacity="0.14"')
    if drop:
        for d in drop:
            inner = inner.replace(d, '')
    sx = -s if flip else s
    return '<g transform="translate(%s %s) rotate(%s) scale(%s %s) translate(-256 %s)">%s</g>' % (f(x), f(y), f(rot), f(sx), f(s), f(-ground), unique(inner, tag()))


def person(parts, x, y, s, flip=False):
    sx = -s if flip else s
    return '<g transform="translate(%s %s) scale(%s %s)">%s</g>' % (f(x), f(y), f(sx), f(s), unique(''.join(parts), tag()))


def bounce(pts, r=2.6, col='#E53935'):
    """A dotted bounce path through the points (dots, not a dash pattern)."""
    out = []
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        for k in range(1, 7):
            t = k / 7.0
            x = x0 + (x1 - x0) * t
            y = y0 + (y1 - y0) * t - math.sin(math.pi * t) * abs(x1 - x0) * 0.35
            out.append('<circle cx="%s" cy="%s" r="%s" fill="%s" opacity="0.55"/>' % (f(x), f(y), f(r), col))
    return out


def lines(x, y, n=3, dx=18, gap=9, col='#B8B0D0'):
    return [L('M %s %s l %s 0' % (f(x), f(y + k * gap), f(dx - k * 3)), col, 3.5) for k in range(n)]


def hearts(x, y, s=1.0):
    return ['<path d="M %s %s c -6 -5 -12 -10 -8 -15 c 3 -3 7 -1 8 2 c 1 -3 5 -5 8 -2 c 4 5 -2 10 -8 15 Z" fill="#E04F9E" '
            'stroke="%s" stroke-width="2" transform="scale(1)"/>' % (f(x), f(y), INK)]


def swirl(x, y, r):
    return [L('M %s %s A %s %s 0 1 1 %s %s' % (f(x - r), f(y), f(r), f(r * 0.5), f(x + r * 0.7), f(y + r * 0.2)), '#B8B0D0', 3)]


def sleep_bubbles(x, y):
    return [E(x + dx, y - dy, rr, rr, WHITE, 2.5) for dx, dy, rr in ((0, 0, 5), (12, 14, 7), (28, 32, 10))]


def flakes(pts, col='#5BB8E0'):
    return [L(''.join('M %d %d L %.1f %.1f ' % (x, y, x + r * math.cos(k * math.pi / 3), y + r * math.sin(k * math.pi / 3)) for k in range(6)), col, 2.5)
            for x, y, r in pts]


def closed_eye(x, y, r, skin):
    return [E(x, y, r * 1.2, r * 1.3, skin, 0), L('M %s %s Q %s %s %s %s' % (f(x - r), f(y), f(x), f(y + r * 0.9), f(x + r), f(y)), INK, 3)]


PIP = os.path.join(LANG, 'host_eng.svg')
NITZI = os.path.join(CAST, 'nitzi-idle.svg')
NITZI_JOY = os.path.join(CAST, 'nitzi-celebrate.svg')
KUBI = os.path.join(CAST, 'kubi.svg')
KUBI_PARTY_HAT = ('<path d="M96 270 L150 262 L116 172 Z" fill="#FF9E8A" />', '<path d="M108 238 L134 234 L128 218 L112 222 Z" fill="#FFF6E8" />',
                  '<path d="M114 206 L124 204 L120 194 Z" fill="#FFF6E8" />', '<circle cx="116" cy="170" r="13" fill="#FFC83D" />')


def red_ball(x, y, s=0.17, air=True):
    return obj(m.ball('red'), x, y, s, air=air)


def shadow_at(x, y, rx):
    return '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" opacity="0.12"/>' % (f(x), f(y), f(rx), f(rx * 0.12), INK)


# ---- the English story "Bounce, Ball!" (Pip, the red ball, the cat, the duck, the frog, the dog) --------------------

def en_story():
    out = {}
    out['story-bounce-1'] = page([asset(PIP, 300, 196, 0.3), red_ball(206, 150)] + bounce([(270, 120), (206, 128)]), garden(True))
    out['story-bounce-2'] = page([obj(m.cat(), 170, 196, 0.5), red_ball(110, 96)] + bounce([(300, 150), (200, 120), (110, 70)]), garden(True))
    pond = ['<ellipse cx="200" cy="186" rx="110" ry="22" fill="#8FD3F4" stroke="#5BB8E0" stroke-width="3"/>']
    out['story-bounce-3'] = page(pond + [obj(m.duck(), 200, 200, 0.4), red_ball(80, 104)] + bounce([(330, 150), (230, 110), (80, 80)]), garden())
    out['story-bounce-4'] = page([obj(b2.frog(), 200, 204, 0.5), red_ball(200, 40)] + bounce([(330, 150), (200, 20), (70, 150)]), garden())
    dog_jump = obj(m.dog(), 200, 170, 0.5, rot=-16, air=True)
    out['story-bounce-5'] = page([shadow_at(206, 200, 56), dog_jump, red_ball(140, 112, 0.14)] + lines(250, 130) + bounce([(340, 120), (146, 96)]),
                                 garden(True))
    out['story-bounce-6'] = page([obj(m.dog(), 160, 200, 0.5), asset(PIP, 262, 200, 0.3, flip=True), red_ball(214, 202, 0.12, air=False)]
                                 + hearts(214, 70) + hearts(236, 52), garden(True))
    return out


# ---- the Hebrew stories ---------------------------------------------------------------------------------------------

def rabbit_kick():
    p = m.rabbit()
    leg = m.Pic()
    leg.shaded('M 100 210 C 80 214, 50 212, 30 202 C 24 198, 26 190, 34 190 C 56 194, 80 194, 98 190 Z', '#B8A08A', '#95806A', k=4)
    p.parts = leg.parts[:] + p.parts
    return p


def he_story1():
    out = {}
    tree = obj(b2.tree(), 70, 178, 0.6)
    bush = lambda x, s=0.5: obj(b2.bush(), x, 186, s)
    out['s1-p1'] = page([tree, bush(320), obj(m.rabbit(), 170, 200, 0.5, flip=True), red_ball(236, 202, 0.14, air=False)], garden())
    out['s1-p2'] = page([tree, bush(320), obj(rabbit_kick(), 170, 200, 0.5, flip=True), red_ball(268, 50, 0.14)]
                        + bounce([(234, 196), (268, 62)]) + lines(226, 182, 2, 16), garden())
    out['s1-p3'] = page([tree, red_ball(250, 168, 0.14), bush(322, 0.6), obj(m.rabbit(), 170, 200, 0.5, flip=True)], garden())
    cat_in_bush = [obj(m.cat(), 300, 200, 0.52, flip=True), bush(250, 0.62), red_ball(272, 204, 0.12, air=False)]
    out['s1-p4'] = page([tree] + cat_in_bush, garden())
    out['s1-p5'] = page([obj(m.rabbit(), 120, 200, 0.5, flip=True), obj(m.cat(), 270, 200, 0.5), red_ball(196, 70, 0.14)]
                        + bounce([(150, 150), (196, 80), (244, 150)]) + hearts(196, 36), garden())
    return out


def apron(x, y, s):
    return ['<g transform="translate(%s %s) scale(%s)"><path d="M -34 -60 L 34 -60 L 40 0 C 44 30, 46 60, 44 80 L -44 80 C -46 60, -44 30, -40 0 Z" '
            'fill="#F46A5E" stroke="%s" stroke-width="5"/><rect x="-22" y="20" width="44" height="28" rx="6" fill="%s" stroke="%s" stroke-width="4"/></g>'
            % (f(x), f(y), f(s), INK, CREAM, INK)]


def he_story2():
    out = {}
    nitzi = lambda x, s=0.4, joy=False: asset(NITZI_JOY if joy else NITZI, x, 166, s)
    out['s2-p1'] = page([obj(m.oven(), 300, 168, 0.5), nitzi(150)] + apron(150, 116, 0.42), kitchen())
    stream = ['<path d="M 200 52 C 196 80, 192 100, 190 132" fill="none" stroke="#C9C3D9" stroke-width="13"/>',
              '<path d="M 200 52 C 196 80, 192 100, 190 132" fill="none" stroke="%s" stroke-width="9"/>' % WHITE]
    out['s2-p2'] = page([obj(b2.flour(), 236, 92, 0.32, rot=-40)] + stream + [obj(m.egg(), 150, 100, 0.16), obj(m.bowl(), 190, 170, 0.46),
                                  obj(m.spoon(), 320, 174, 0.3)] + lines(150, 64, 2, 0) , kitchen())
    out['s2-p3'] = page([nitzi(190)] + apron(190, 116, 0.42) + [obj(m.bowl(), 190, 178, 0.5), obj(m.spoon(), 206, 150, 0.32, rot=20)]
                        + swirl(190, 142, 34), kitchen())
    tin = ['<rect x="130" y="112" width="70" height="26" rx="6" fill="#AEB5C6" stroke="%s" stroke-width="4"/>' % INK,
           '<rect x="136" y="104" width="58" height="14" rx="6" fill="#F2D3A0" stroke="%s" stroke-width="3"/>' % INK]
    out['s2-p4'] = page([obj(m.oven(), 250, 168, 0.56)] + tin + lines(96, 116, 2, 24) + [obj(m.bowl(), 70, 172, 0.34)], kitchen())
    out['s2-p5'] = page([nitzi(110, 0.34, joy=True), asset(os.path.join(CAST, 'goni.svg'), 290, 166, 0.3), asset(os.path.join(CAST, 'timi.svg'), 200, 120, 0.22),
                         '<rect x="140" y="150" width="104" height="14" rx="5" fill="#C98F52" stroke="%s" stroke-width="3"/>' % INK,
                         obj(m.cake(), 192, 156, 0.34)], kitchen())
    return out


def kubi(x, y, s, hat=True, wave=False):
    out = [asset(KUBI, x, y, s, drop=KUBI_PARTY_HAT)]
    if hat:   # the story's hat (the `hat` picture) on Kubi's head (head centre 122, 300 on Kubi's 512 canvas)
        hx, hy = x + (122 - 256) * s, y + (284 - 466) * s
        out.append(obj(m.hat(), hx, hy, s * 0.62, ground=196))
    return out


def boat_with(x, y, s, rot=0, who=()):
    """Kubi's little rowing boat (`boat-2` without its water), with who sitting in it behind the hull."""
    hull = b2.boat_2()
    hull.parts = [q for q in hull.parts if '#8FD3F4' not in q and '#3FB6D9' not in q and 'stroke="#FFFFFF"' not in q]
    return ['<g transform="translate(%s %s) rotate(%s)">' % (f(x), f(y), f(rot))] + list(who) + [obj(hull, 0, 0, s, ground=186)] + ['</g>']


def he_story3():
    out = {}
    out['s3-p1'] = page(boat_with(190, 150, 0.7, 0, kubi(10, -14, 0.3)), lake())
    wind = [L('M 30 60 C 90 56, 140 50, 180 40 C 200 34, 204 18, 192 16', '#8FBFE0', 6), L('M 20 96 C 90 92, 150 90, 210 80', '#8FBFE0', 6)]
    out['s3-p2'] = page(wind + boat_with(170, 156, 0.7, -8, kubi(10, -14, 0.3, hat=False)) + [obj(m.hat(), 286, 70, 0.28, rot=24)], lake())
    ripples = [E(290, 150, 46, 8, 'none', 3, stroke='#5BB8E0'), E(290, 150, 70, 12, 'none', 2.5, stroke='#BFE6F7')]
    out['s3-p3'] = page(boat_with(120, 156, 0.62, 0, kubi(10, -14, 0.28, hat=False)) + ripples + [obj(m.hat(), 290, 154, 0.26)], lake())
    out['s3-p4'] = page(boat_with(110, 156, 0.62, 0, kubi(10, -14, 0.28, hat=False)) + [obj(m.hat(), 236, 150, 0.24), obj(m.fish(), 246, 188, 0.2)]
                        + lines(290, 176, 2, 18), lake())
    jump = obj(m.fish(), 290, 160, 0.22, rot=-30)
    out['s3-p5'] = page(boat_with(150, 156, 0.66, 0, kubi(10, -14, 0.3)) + [jump] + hearts(260, 70) + [E(290, 156, 36, 6, 'none', 3, stroke='#5BB8E0')], lake())
    return out


def part_a():
    out = en_story()
    out.update(he_story1())
    out.update(he_story2())
    out.update(he_story3())
    return out



# ---- the Russian stories (RUS-A-16): a dog and a ball, a hedgehog and an apple, a girl and her hat --------------------

def with_closed_eye(pic, x, y, r, skin):
    """The same animal asleep: its eye closed (a skin patch and a curved lid line)."""
    p = m.Pic()
    p.parts = pic.parts + closed_eye(x, y, r, skin)
    return p


def bitten_apple():
    p = m.apple()
    p.parts = p.parts + ['<path d="M 196 96 C 172 104, 170 138, 196 150 C 210 140, 214 108, 196 96 Z" fill="#FFF6E8" stroke="%s" stroke-width="4"/>' % INK]
    return p


GIRL = pe.EXTRA['girl']
GIRL_WINTER = dict(GIRL, dress=None, top='#E5484D', long=True, bottom='trousers', bottomc='#3B5FB8', shoes='#5E5A70')
GIRL_WINTER.pop('dress')


def warm_hat(sp):
    r, hc = sp['hr'], -sp['H'] + sp['hr']
    return [P('M %s %s C %s %s, %s %s, %s %s Z' % (f(-r * 1.0), f(hc - r * 0.45), f(-r * 0.9), f(hc - r * 1.5), f(r * 0.9), f(hc - r * 1.5),
                                                   f(r * 1.0), f(hc - r * 0.45)), '#EF6F5E'),
            RR(-r * 1.08, hc - r * 0.62, r * 2.16, r * 0.34, r * 0.14, CREAM), E(0, hc - r * 1.42, r * 0.22, r * 0.22, CREAM)]


def girl(expr='smile', arms=((8, 0), (8, 0)), sp=None, hat=False):
    sp = sp or GIRL_WINTER
    parts = pe.posed(sp, expr=expr, arms=arms)
    if hat:
        parts = parts[:-1] + warm_hat(sp) + [parts[-1]]
    return parts


def ru_stories():
    out = {}
    dog_skin = '#D9A066'
    out['st1-p1'] = page([obj(m.dog(), 150, 198, 0.5), red_ball(270, 200, 0.16, air=False)], garden())
    run = obj(m.dog(), 170, 188, 0.5, rot=-10, air=True)
    puffs = [E(x, y, rr, rr * 0.8, '#EADBB8', 2.5) for x, y, rr in ((262, 194, 9), (280, 188, 7), (294, 196, 5))]
    out['st1-p2'] = page([shadow_at(176, 200, 50), run, red_ball(56, 200, 0.14, air=False)] + puffs + lines(270, 136, 3, 26), garden())
    out['st1-p3'] = page([obj(m.dog(), 200, 198, 0.52), red_ball(166, 140, 0.11, air=False)] + hearts(236, 70) + hearts(262, 50), garden())
    bed = ['<ellipse cx="200" cy="186" rx="96" ry="26" fill="#8A5CF0" stroke="%s" stroke-width="4"/>' % INK,
           '<ellipse cx="200" cy="180" rx="78" ry="16" fill="#B9A2F7"/>']
    out['st1-sleep'] = page(bed + [obj(with_closed_eye(b2.dog_2(), 80, 72, 7, dog_skin), 200, 196, 0.5)] + sleep_bubbles(250, 70), room())
    out['st1-cat'] = page([obj(m.cat(), 170, 198, 0.5), red_ball(250, 200, 0.16, air=False)], garden())
    out['st2-p1'] = page([obj(b2.hedgehog(), 200, 200, 0.5)] + lines(300, 160, 3, 24), garden())
    out['st2-p2'] = page([obj(b2.hedgehog(), 230, 200, 0.5), obj(m.apple(), 110, 200, 0.26)]
                         + [L('M 150 120 l -10 -14 M 162 114 l 0 -18 M 174 120 l 10 -14', '#F59E1B', 4)], garden())
    out['st2-p3'] = page([obj(b2.hedgehog(), 230, 200, 0.5), obj(bitten_apple(), 150, 202, 0.2)] + hearts(190, 96), garden())
    out['st2-sleep'] = page([obj(with_closed_eye(b2.hedgehog(), 68, 176, 6, '#E8D2B0'), 200, 200, 0.5)] + sleep_bubbles(140, 110), garden())
    out['st2-bear'] = page([obj(b2.bear(), 220, 200, 0.6), obj(bitten_apple(), 150, 162, 0.16, air=True)], garden())
    sky_flakes = flakes([(40, 40, 7), (110, 70, 6), (300, 40, 8), (350, 96, 6), (70, 120, 5), (250, 80, 5)])
    out['st3-p1'] = page(sky_flakes + [person(girl(), 192, 192, 0.85)], snow())
    out['st3-p2'] = page(sky_flakes + [person(girl('shiver', arms=((20, -100), (20, -100))), 192, 192, 0.85)]
                         + [L('M 140 90 q -8 8 0 16 q 8 8 0 16 M 244 90 q 8 8 0 16 q -8 8 0 16', '#B8B0D0', 4)], snow())
    out['st3-p3'] = page(sky_flakes + [person(girl('happy', hat=True), 192, 192, 0.85)] + hearts(250, 60), snow())
    sun = obj(b2.sun(), 330, 90, 0.3, air=True)
    out['st3-beach'] = page([sun, person(girl('happy', sp=GIRL), 160, 196, 0.85)], beach())
    out['st3-boy'] = page([person(pe.posed(pe.EXTRA['boy'], expr='happy'), 170, 196, 0.85), red_ball(240, 200, 0.16, air=False)], garden())
    return out



# ---- the Hebrew place pictures (A-04: on, in, under, next to; and the role swaps) -----------------------------------

def tile(parts):
    """A 256 picture of a small scene with a soft floor, so on, under and next to read at 64 px."""
    body = ''.join(['<ellipse cx="128" cy="226" rx="120" ry="14" fill="#EDE6F7"/>'] + parts)
    text = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">'
            '<clipPath id="page"><rect x="0" y="0" width="256" height="256"/></clipPath>'
            '<g clip-path="url(#page)" stroke-linejoin="round" stroke-linecap="round">%s</g></svg>\n' % body)
    return compact(text)


def sub(pic, a, b=None):
    p = m.Pic()
    p.parts = pic.parts[a:b]
    return p


def bird_alone():
    b = m.bird()
    p = m.Pic()
    p.parts = [q for q in b.parts if '#9C6B3C' not in q and '#6DBE5A' not in q]
    return p


def open_box(front=True, back=True):
    k, s, top = '#D9A866', '#B8874A', '#E8C08A'
    out = []
    if back:
        out += [P('M 60 118 L 196 118 L 210 96 L 74 96 Z', s), P('M 60 118 L 30 86 L 70 80 L 96 110 Z', top),
                P('M 196 118 L 226 86 L 186 80 L 160 110 Z', top)]
    if front:
        out += [P('M 60 118 L 196 118 L 196 214 L 60 214 Z', k), P('M 196 118 L 210 96 L 210 194 L 196 214 Z', s)]
    return out


def place():
    out = {}

    def ball(x, y, s=0.32, air=False):
        return obj(m.ball('red'), x, y, s, air=air)

    def box(x, y, s=0.58, air=False):
        return obj(b2.box(), x, y, s, air=air)

    out['place-ball-on-box'] = tile([box(128, 230), ball(124, 162, 0.36, air=True)])
    out['place-box-on-ball'] = tile([ball(128, 232, 0.4), box(130, 166, 0.5, air=True)])
    out['place-ball-in-box'] = tile(open_box(front=False) + [obj(m.ball('red'), 128, 150, 0.36, air=True)] + open_box(back=False))
    basket = b2.basket()
    out['place-cat-in-basket'] = tile([obj(basket, 128, 230, 0.8), obj(m.cat(), 128, 196, 0.44), obj(sub(basket, 3, 10), 128, 230, 0.8)])
    out['place-basket-on-cat'] = tile([obj(m.cat(), 128, 230, 0.5), obj(sub(basket, 3, 10), 128, 146, 0.8, rot=180, ground=110)])
    out['place-cat-by-basket'] = tile([obj(basket, 80, 230, 0.56), obj(m.cat(), 192, 230, 0.4)])
    chair = b2.chair()
    out['place-dog-under-chair'] = tile([obj(chair, 128, 232, 0.92), obj(m.dog(), 124, 228, 0.33)])
    out['place-dog-on-chair'] = tile([obj(chair, 128, 232, 0.92), obj(b2.dog_2(), 120, 152, 0.36)])
    out['place-dog-by-chair'] = tile([obj(chair, 90, 232, 0.72), obj(m.dog(), 196, 230, 0.36)])
    boat = m.boat('blue')
    out['place-bird-on-boat'] = tile([obj(boat, 128, 232, 0.82), obj(bird_alone(), 70, 166, 0.3)])
    out['place-boat-on-bird'] = tile([obj(bird_alone(), 128, 236, 0.9), obj(boat, 136, 112, 0.34)])
    out['place-bird-in-boat'] = tile([obj(boat, 128, 232, 0.82), obj(bird_alone(), 96, 204, 0.3), obj(sub(boat, 11), 128, 232, 0.82)])
    bowl = m.bowl()
    out['place-apple-in-bowl'] = tile([obj(bowl, 128, 230, 0.8), obj(m.apple(), 128, 166, 0.36, air=True), obj(sub(bowl, 2, 8), 128, 230, 0.8)])
    out['place-bowl-on-apple'] = tile([obj(m.apple(), 132, 230, 0.4), obj(sub(bowl, 2, 10), 132, 164, 0.8, rot=180, ground=100)])
    out['place-apple-by-bowl'] = tile([obj(bowl, 90, 230, 0.6), obj(m.apple(), 196, 230, 0.36)])
    return out


# ---- the Russian LS11 scenes, the new contexts, the bin box and the thumbs ---------------------------------------------

SPOTS = {}


def scene(name, parts, bg, spots):
    SPOTS[name] = spots
    return page(parts, bg)


def russian_scenes():
    out = {}
    win = [RR(250, 26, 96, 80, 8, WHITE), RR(258, 34, 80, 64, 4, '#BFE6F7'), L('M 298 34 L 298 98 M 258 66 L 338 66', WHITE, 6),
           RR(250, 26, 96, 80, 8, 'none')]
    shelf = [RR(30, 70, 120, 10, 4, '#C98F52')]
    rug = ['<ellipse cx="192" cy="190" rx="150" ry="22" fill="#B9A2F7" opacity="0.6"/>']
    out['scene-room'] = scene('scene-room', win + shelf + rug, room(),
                              {'spots': [[40, 20, 70, 50], [150, 120, 70, 70], [270, 120, 70, 70]],
                               'note': 'three places for the object pictures: on the shelf, on the rug, by the window'})
    out['scene-garden'] = scene('scene-garden', [obj(b2.tree(), 330, 170, 0.5), obj(b2.bush(), 50, 176, 0.4)], garden(True),
                                {'spots': [[70, 80, 70, 110], [160, 80, 70, 110], [250, 80, 70, 110]],
                                 'note': 'three places for the family pictures, standing on the path'})
    cloth = ['<path d="M 30 140 L 354 140 L 380 210 L 4 210 Z" fill="#FFFFFF" stroke="%s" stroke-width="4"/>' % INK]
    cloth += ['<path d="M %d 140 L %d 210" stroke="#E5484D" stroke-width="10" opacity="0.8"/>' % (x, x + (x - 192) // 6) for x in range(52, 354, 40)]
    out['scene-picnic'] = scene('scene-picnic', cloth + [obj(b2.plate(), 300, 196, 0.36)], garden(),
                                {'spots': [[40, 140, 60, 60], [110, 140, 60, 60], [180, 140, 60, 60]], 'target': [262, 150, 76, 50],
                                 'note': "three foods on the cloth; the target is the friend's plate"})
    tb = [RR(250, 110, 110, 80, 8, '#E5484D'), RR(244, 100, 122, 18, 6, '#B8282A'), P('M 250 100 L 230 64 L 250 60 L 270 98 Z', '#F28084'),
          E(305, 150, 16, 16, '#FFC83D', 3)]
    out['scene-toybox'] = scene('scene-toybox', tb, room(),
                                {'spots': [[30, 130, 60, 60], [100, 130, 60, 60], [170, 130, 60, 60]], 'target': [250, 100, 110, 90],
                                 'note': 'three toys on the floor; the target is the toy box'})
    return out


def button(c, s, up=True):
    """A round pebble button with a clay lip and a white thumb (up: green; down: a calm blue, never red, never a cross)."""
    hand = ['<g transform="%s">' % ('translate(0 0)' if up else 'rotate(180 128 124)'),
            P('M 92 112 L 92 172 L 152 172 C 164 172, 172 164, 170 152 L 176 124 C 178 112, 170 106, 160 106 L 138 106 L 142 80 '
              'C 144 64, 124 58, 120 74 L 112 104 Z', WHITE, 5),
            RR(74, 110, 22, 64, 8, WHITE), L('M 140 126 L 172 126 M 140 142 L 170 142 M 140 158 L 168 158', '#D8D3E6', 3), '</g>']
    return [E(128, 132, 96, 96, s, 0), E(128, 122, 96, 96, c, 5)] + hand


def context_and_pieces():
    out = {}
    bench = [RR(150, 176, 90, 10, 4, '#C98F52'), RR(150, 160, 90, 8, 4, '#C98F52'), RR(158, 184, 8, 30, 3, '#8F6230'), RR(224, 184, 8, 30, 3, '#8F6230')]
    park = ['<rect x="0" y="0" width="256" height="256" fill="#DFF1FB"/>', '<path d="M 0 170 C 80 160, 180 160, 256 170 L 256 256 L 0 256 Z" fill="#B5DFA0"/>',
            '<path d="M 0 236 C 80 214, 170 214, 256 228 L 256 256 L 0 256 Z" fill="#EADBB8"/>', obj(b2.tree(), 210, 176, 0.46)]
    out['ctx-bush-park'] = tile(park + bench + [obj(b2.bush(), 84, 214, 0.52)])
    snowman = [E(128, 196, 54, 46, WHITE), E(128, 118, 40, 36, WHITE), E(116, 112, 4, 4, INK, 0), E(140, 112, 4, 4, INK, 0),
               P('M 126 122 L 150 128 L 126 130 Z', '#FF8A3D', 2.5), E(128, 180, 4, 4, INK, 0), E(128, 200, 4, 4, INK, 0),
               L('M 84 170 L 56 146 M 172 170 L 200 146', '#7A4A24', 5)]
    out['ctx-hat-snowman'] = tile(snowman + [obj(m.hat(), 128, 98, 0.44, ground=196)])
    wind = [L('M 10 70 C 50 66, 80 60, 110 50 C 124 44, 126 30, 116 28', '#8FBFE0', 6), L('M 0 110 C 50 106, 90 104, 130 96', '#8FBFE0', 6)]
    sail = m.boat('green')
    sail.parts = [q.replace('Q 186 110 206 160', 'Q 236 96 214 160') for q in sail.parts]
    out['ctx-wind-sail'] = tile(wind + [obj(sail, 140, 236, 0.86)])
    out['bin-box'] = tile(open_box(front=False) + open_box(back=False) + [RR(84, 134, 88, 64, 8, WHITE)])
    out['thumb-up'] = tile(button('#36A852', '#237A3A', up=True))
    out['thumb-down'] = tile(button('#5C8DDB', '#3E6FC2', up=False))
    return out


def part_c():
    out = place()
    out.update(russian_scenes())
    out.update(context_and_pieces())
    import json
    with open(os.path.join(OUT, 'scenes.spots.json'), 'w', encoding='utf-8', newline='\n') as fh:
        json.dump({'note': 'Places in the 384 x 216 scene backgrounds where the app puts pictures (x, y, w, h); the target is the drop place.',
                   'scenes': SPOTS}, fh, ensure_ascii=False, indent=1)
        fh.write('\n')
    return out



# ---- the Hebrew action animations (A-02): two key poses each, played by the app ------------------------------------
# SVG in the app has no animation, so each action is two pictures of the same scene, frame a (the start) and frame b
# (the action), drawn on one ground so nothing jumps but the moving part. The app plays them as in actions.anim.json:
# a for 500 ms, b for 700 ms, three times, then it rests on b (with reduce-motion: b only).

def grass_tile(parts, water=False):
    bg = ['<rect x="0" y="0" width="256" height="256" fill="#DFF1FB"/>']
    if water:
        bg.append('<path d="M 0 120 C 80 112, 180 112, 256 120 L 256 256 L 0 256 Z" fill="#8FD3F4"/>')
        bg.append('<path d="M 0 120 C 80 112, 180 112, 256 120" fill="none" stroke="#5BB8E0" stroke-width="3"/>')
    else:
        bg.append('<path d="M 0 170 C 80 160, 180 160, 256 170 L 256 256 L 0 256 Z" fill="#B5DFA0"/>')
    text = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">'
            '<clipPath id="page"><rect x="0" y="0" width="256" height="256" rx="20"/></clipPath>'
            '<g clip-path="url(#page)" stroke-linejoin="round" stroke-linecap="round">%s</g></svg>\n' % ''.join(bg + parts))
    return compact(text)


def kitchen_tile(parts):
    bg = ['<rect x="0" y="0" width="256" height="256" fill="#FFF3E0"/>', '<rect x="0" y="196" width="256" height="60" fill="#E8C590"/>',
          '<rect x="0" y="192" width="256" height="8" fill="#C98F52"/>']
    text = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">'
            '<clipPath id="page"><rect x="0" y="0" width="256" height="256" rx="20"/></clipPath>'
            '<g clip-path="url(#page)" stroke-linejoin="round" stroke-linecap="round">%s</g></svg>\n' % ''.join(bg + parts))
    return compact(text)


def stir_frames(cook, x0, bowl_pic, s_bowl=0.6):
    """Someone stirring: the spoon leans left in frame a and right in frame b, the batter swirls."""
    out = []
    for lean in (-18, 22):
        spoon = obj(m.spoon(), 128 + lean * 0.6, 174, 0.38, rot=40 + lean)
        parts = cook + [obj(bowl_pic, 128, 214, s_bowl), spoon] + swirl(128, 168, 30)
        out.append(kitchen_tile(parts))
    return out


def actions():
    out = {}
    MIKA_BOY = pe.EXTRA['boy']
    # the rabbit kicks the ball
    out['act-he-kick-rabbit-a'] = grass_tile([obj(m.rabbit(), 150, 226, 0.6), red_ball(70, 226, 0.18, air=False)])
    out['act-he-kick-rabbit-b'] = grass_tile([obj(rabbit_kick(), 150, 226, 0.6), red_ball(46, 120, 0.16)] + bounce([(70, 216), (46, 130)]))
    # the cat searches in a bush
    out['act-he-search-cat-a'] = grass_tile([obj(b2.bush(), 80, 230, 0.6), obj(m.cat(), 196, 228, 0.5)])
    out['act-he-search-cat-b'] = grass_tile([obj(m.cat(), 150, 228, 0.5), obj(b2.bush(), 96, 230, 0.6)]
                                            + [L('M 60 120 l -6 -10 M 76 112 l 0 -12 M 92 118 l 6 -10', '#B8B0D0', 3.5)])
    # Nitzi stirs a bowl (Nitzi behind the bowl, an apron on)
    nitzi = [asset(NITZI, 128, 196, 0.5)] + apron(128, 150, 0.44)
    a, b = stir_frames(nitzi, 128, m.bowl())
    out['act-he-stir-nitzi-a'], out['act-he-stir-nitzi-b'] = a, b
    # a fish swims (to the left, the reading direction of the Hebrew page)
    for k, (x, tail) in enumerate(((168, 8), (96, -8))):
        bub = [E(x + 70 + dx, 150 - dy, rr, rr, 'none', 2.5, stroke='#5BB8E0') for dx, dy, rr in ((0, 0, 5), (10, 18, 4), (4, 34, 3))]
        out['act-he-swim-fish-%s' % 'ab'[k]] = grass_tile([obj(m.fish(), x, 214, 0.5, rot=tail, air=True)] + bub, water=True)
    # the check scenes: a boy kicks, a duck swims, a girl searches in a box, the mother stirs a pot
    for k, (legs, ballxy) in enumerate(((((-10, 10), (-30, 20)), (60, 226)), (((-10, 10), (70, -10)), (34, 120)))):
        boy = pe.posed(MIKA_BOY, view='side', arms=((-30, 20), (30, 20)), legs=legs, expr='happy')
        extra = bounce([(60, 216), (34, 130)]) if k else []
        out['act-he-kick-boy-%s' % 'ab'[k]] = grass_tile([person(boy, 150, 228, 1.1), red_ball(ballxy[0], ballxy[1], 0.16, air=bool(k))] + extra)
    for k, x in enumerate((170, 100)):
        rip = [E(x + 60, 196, 26, 5, 'none', 2.5, stroke=WHITE), E(x + 84, 196, 16, 4, 'none', 2.5, stroke=WHITE)]
        out['act-he-swim-duck-%s' % 'ab'[k]] = grass_tile([obj(m.duck(), x, 226, 0.5)] + rip, water=True)
    girl_sp = pe.EXTRA['girl']
    for k, (lean, arm) in enumerate(((0, ((8, 0), (30, 0))), (-30, ((20, 0), (50, 0))))):
        g = pe.posed(girl_sp, view='side', arms=arm, legs=((-6, 4), (6, -4)), lean=lean, expr='smile')
        box_back = open_box(front=False)
        box_front = open_box(back=False)
        scene_ = ['<g transform="translate(-10 40) scale(0.62)">%s</g>' % ''.join(box_back)]
        scene_ += [person(g, 166, 228, 1.0)]
        scene_ += ['<g transform="translate(-10 40) scale(0.62)">%s</g>' % ''.join(box_front)]
        out['act-he-search-girl-%s' % 'ab'[k]] = grass_tile(scene_)
    mum = ch.BY_ID['mother']
    cook = [person(pe.posed(mum, arms=((20, -110), (20, -110)), expr='happy'), 128, 266, 1.0)]
    pot = b2.pot()   # the pot without its lid: the lid, its knob and its highlight left out
    pot.parts = [q for q in pot.parts if 'C 40 64' not in q and 'M 122 52' not in q and 'Q 90 72' not in q]
    a, b = stir_frames(cook, 128, pot, 0.56)
    out['act-he-stir-mother-a'], out['act-he-stir-mother-b'] = a, b
    return out


ANIM = {
    'note': ('Each Hebrew action (A-02) is two key poses of one scene. Play a for 500 ms, then b for 700 ms, three times, '
             'and rest on b; a 150 ms cross-fade between them. With reduce-motion on, show b only. No sound is tied to the frames.'),
    'actions': {
        'kick-rabbit': {'word': 'בּוֹעֵט', 'frames': ['act-he-kick-rabbit-a', 'act-he-kick-rabbit-b']},
        'search-cat': {'word': 'מְחַפֶּשֶׂת', 'frames': ['act-he-search-cat-a', 'act-he-search-cat-b']},
        'stir-nitzi': {'word': 'מְעַרְבֶּבֶת', 'frames': ['act-he-stir-nitzi-a', 'act-he-stir-nitzi-b']},
        'swim-fish': {'word': 'שׂוֹחֶה', 'frames': ['act-he-swim-fish-a', 'act-he-swim-fish-b']},
        'kick-boy': {'word': 'בּוֹעֵט', 'frames': ['act-he-kick-boy-a', 'act-he-kick-boy-b'], 'check': True},
        'swim-duck': {'word': 'שׂוֹחֶה', 'frames': ['act-he-swim-duck-a', 'act-he-swim-duck-b'], 'check': True},
        'search-girl': {'word': 'מְחַפֶּשֶׂת', 'frames': ['act-he-search-girl-a', 'act-he-search-girl-b'], 'check': True},
        'stir-mother': {'word': 'מְעַרְבֶּבֶת', 'frames': ['act-he-stir-mother-a', 'act-he-stir-mother-b'], 'check': True},
    },
    'timing_ms': {'a': 500, 'b': 700, 'crossfade': 150, 'repeat': 3},
}


# ---- the composites: sets for counting, drum strips, big and small --------------------------------------------------

def composite(parts, w=256, h=256):
    text = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">'
            '<g stroke-linejoin="round" stroke-linecap="round">%s</g></svg>\n' % (w, h, w, h, ''.join(parts)))
    return compact(text)


DICE = {1: [(0, 0)], 2: [(-1, -1), (1, 1)], 3: [(-1, -1), (0, 0), (1, 1)], 4: [(-1, -1), (1, -1), (-1, 1), (1, 1)],
        5: [(-1, -1), (1, -1), (0, 0), (-1, 1), (1, 1)]}


def composites():
    out = {}
    for n in range(1, 6):   # balls in the dice pattern, the same size in every set
        out['set-balls-%d' % n] = composite([obj(m.ball('red'), 128 + dx * 62, 160 + dy * 62, 0.26, air=True) for dx, dy in DICE[n]])
    for n in range(1, 6):   # identical yellow ducklings in a row, evenly spaced, the same size in every set
        gap = 74   # a 384 x 216 strip, so five fit in a row at a size a child can count
        x0 = 192 - gap * (n - 1) / 2
        out['set-ducks-%d' % n] = composite([obj(m.duckling(), x0 + k * gap, 156, 0.32) for k in range(n)], 384, 216)
    for n in range(1, 5):   # one to four drums in a row, the same 384 x 216 strip
        gap = 92
        x0 = 192 - gap * (n - 1) / 2
        out['drum-strip-%d' % n] = composite([obj(m.drum(), x0 + k * gap, 156, 0.36) for k in range(n)], 384, 216)
    out['dog-big'] = composite(['<ellipse cx="96" cy="150" rx="88" ry="74" fill="#FFC83D" opacity="0.25"/>',
                                obj(m.dog(), 96, 226, 0.66), obj(m.dog(), 204, 226, 0.3)])
    out['ball-pair'] = composite([obj(m.ball('red'), 92, 226, 0.58), obj(m.ball('red'), 204, 226, 0.26)])
    return out


def part_d():
    out = actions()
    out.update(composites())
    import json
    with open(os.path.join(OUT, 'actions.anim.json'), 'w', encoding='utf-8', newline='\n') as fh:
        json.dump(ANIM, fh, ensure_ascii=False, indent=1)
        fh.write('\n')
    return out


PARTS = {'batch4a': part_a, 'batch4b': ru_stories, 'batch4c': part_c, 'batch4d': part_d}


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
            m.sheet(list(pics), out)
            print('sheet', os.path.relpath(out, ROOT))


if __name__ == '__main__':
    main()
