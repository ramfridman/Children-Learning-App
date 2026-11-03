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


PARTS = {'batch4a': part_a}


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
