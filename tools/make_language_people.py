"""Batch 3 of the shared Languages pictures: the people and characters (docs/languages/pictures.md section 4.2), drawn from
the model sheet the owner approved on 2026-11-03 (docs/design/languages/characters_model_sheet.png,
tools/make_language_characters.py, whose people, Pip and Sasha this module reuses).

    python tools/make_language_people.py           # writes the SVGs
    python tools/make_language_people.py --sheet   # and one contact sheet per part (pictures_batch3a.png, ...)

Writes content/languages/pictures/<id>.svg, 256 x 256, like the objects; a crop of a bigger drawing is scaled into the
canvas and clipped to it, so nothing crosses the viewBox. Same rules as the rest of the set: no text, no franchise look,
no real person, no tears (a soft frown), any clothes on anyone.

References: those of the model sheet (tools/make_language_characters.py: children's and adults' heights by age, the
cast's boards, the Wikipedia Budgerigar photographs and a Commons close-up of a budgerigar's head: the round crown that
runs into the throat, fine dark bars on the crown, the cere over a short hooked beak, the violet-blue cheek patch, the
black throat spots); the door of tools/make_languages_art.py for Pip's door.
"""
import math
import os
import pathlib
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_language_characters as ch  # noqa: E402
import make_language_pictures as m  # noqa: E402

ROOT = m.ROOT
OUT = m.OUT
LANG = os.path.join(ROOT, 'app', 'assets', 'art', 'languages')
INK, WHITE, CREAM = m.INK, m.WHITE, m.CREAM
f = ch.f
P, L, E, RR = ch.P, ch.L, ch.E, ch.RR
CARD = {'mother': '#DDF3E6', 'father': '#DEEBFC', 'grandmother': '#ECE3FE', 'grandfather': '#EDE6F7', 'sister': '#FEEFD6',
        'brother': '#FFE3DF', 'baby': '#FCE1F0', 'cousin': '#DDF3E6', 'mika': '#FFF3C2'}


def canvas(parts, crop=None, bg=None, clip=True):
    """parts drawn in their own coordinates; crop = (x, y, w, h) of that drawing, fitted into 0..256 and centred."""
    out = []
    if bg:
        out.append('<rect x="8" y="8" width="240" height="240" rx="28" fill="%s"/>' % bg)
    if crop:
        x, y, w, h = crop
        k = 256.0 / max(w, h)
        tx, ty = (256 - w * k) / 2 - x * k, (256 - h * k) / 2 - y * k
        g = '<g transform="translate(%s %s) scale(%s)">%s</g>' % (f(tx), f(ty), f(k), ''.join(parts))
    else:
        g = ''.join(parts)
    if clip:
        if bg:
            out.append('<clipPath id="frame"><rect x="8" y="8" width="240" height="240" rx="28"/></clipPath>')
        else:
            out.append('<clipPath id="frame"><rect x="0" y="0" width="256" height="256"/></clipPath>')
        g = '<g clip-path="url(#frame)">%s</g>' % g
    out.append(g)
    return compact('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">'
                   '<g stroke-linejoin="round" stroke-linecap="round">%s</g></svg>\n' % ''.join(out))


def compact(text):
    """Smaller files: the round joins and caps are set once on the outer group, and numbers keep one decimal at most
    (whole numbers when the decimal is small; the drawings are scaled down, so nothing visible moves)."""
    import re
    for a in (' stroke-linejoin="round" stroke-linecap="round"', ' stroke-linecap="round" stroke-linejoin="round"',
              ' stroke-linecap="round"', ' stroke-linejoin="round"'):
        text = text.replace(a, '')
    text = text.replace('<g >', '<g>')
    text = text.replace('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256"><g>',
                        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">'
                        '<g stroke-linejoin="round" stroke-linecap="round">', 1)

    def num(mm):
        v = float(mm.group(0))
        r = round(v)
        return str(int(r)) if abs(v - r) < 0.25 else ('%.1f' % v).rstrip('0').rstrip('.')
    return re.sub(r' d="([^"]*)"', lambda dm: ' d="%s"' % re.sub(r'-?\d+\.\d+', num, dm.group(1)), text)


def standing(sp, expr='smile', extra=()):
    return [ch.shadow(sp['hr'] * 1.6)] + ch.person_front(sp, expr) + list(extra)


def full_crop(sp, pad=10):
    H, r = sp['H'], sp['hr']
    top = H + r * 0.3 + pad
    return (-top / 2, -top, top, top + 14)


def portrait_crop(sp):
    H, r = sp['H'], sp['hr']
    hc = -H + r
    return (-r * 2.3, hc - r * 1.6, r * 4.6, r * 4.6)


# ---- extra people of the courses (made with the model sheet's person) ----------------------------------------------

EXTRA = {
    'cousin': dict(id='cousin', H=146, hr=28, skin=2, hair='short', hairc='#9C4A22', top='#36A852', bottom='shorts', bottomc='#5E5A70',
                   shoes='#E53935', extras=set()),
    'girl': dict(id='girl', H=140, hr=28, skin=1, hair='ponytail', hairc='#B57A3C', dress='#8A5CF0', shoes='#E04F9E', extras=set()),
    'boy': dict(id='boy', H=142, hr=28, skin=5, hair='curls', hairc='#2A2030', top='#2F7FE0', bottom='shorts', bottomc='#E53935',
                shoes='#3A3550', extras=set()),
    'teacher': dict(id='teacher', H=216, hr=26, skin=3, hair='short', hairc='#2A2030', top='#F59E1B', bottom='skirt', bottomc='#3B5FB8',
                    shoes='#7A4A24', extras={'glasses'}, adult=True),
    'neighbour': dict(id='neighbour', H=206, hr=25, skin=2, hair='bun', hairc='#C9C5D4', top='#1A9E9A', bottom='skirt', bottomc='#5E5A70',
                      shoes='#3A3550', extras=set(), adult=True),
}


def note(x, y, s=1.0, col='#8A5CF0'):
    """A music note (a picture of a sound, not a letter)."""
    return [E(x, y, 9 * s, 7 * s, col, 2.5), L('M %s %s L %s %s' % (f(x + 8 * s), f(y), f(x + 8 * s), f(y - 34 * s)), INK, 3),
            P('M %s %s Q %s %s %s %s' % (f(x + 8 * s), f(y - 34 * s), f(x + 22 * s), f(y - 28 * s), f(x + 20 * s), f(y - 16 * s)), 'none', 3)]


def sing_mouth(sp):
    r, hc = sp['hr'], -sp['H'] + sp['hr']
    return [E(0, hc + r * 0.5, r * 0.16, r * 0.2, ch.MOUTH, 2.5), E(0, hc + r * 0.58, r * 0.09, r * 0.07, '#F28AA0', 0)]


def singer(sp):
    """A person singing: an open round mouth over the smile, hands together, notes rising."""
    parts = standing(sp, 'smile')
    r, hc = sp['hr'], -sp['H'] + sp['hr']
    parts += [E(0, hc + r * 0.48, r * 0.3, r * 0.14, ch.SKIN[sp['skin']], 0)]
    parts += sing_mouth(sp)
    parts += note(r * 1.4, hc - r * 0.2, 0.9) + note(r * 2.1, hc - r * 1.0, 0.7, '#E04F9E')
    return parts


# ---- Pip ------------------------------------------------------------------------------------------------------------

def host_parts(course):
    text = open(os.path.join(LANG, 'host_%s.svg' % course), encoding='utf-8').read()
    return [text[text.index('>') + 1:text.rindex('</svg>')]]


def recolour(parts, table):
    s = ''.join(parts)
    for a, b in table.items():
        s = s.replace(a, b)
    return [s]


def pip_bust(expr, extra=()):
    return canvas(ch.pip_head(expr) + list(extra), crop=(0, 16, 512, 512))


def pip_cold():
    hat = ['<path d="M 150 120 C 150 40, 362 40, 362 120 Z" fill="#E5484D" stroke="%s" stroke-width="5"/>' % INK,
           '<rect x="136" y="106" width="240" height="44" rx="16" fill="%s" stroke="%s" stroke-width="5"/>' % (CREAM, INK),
           '<circle cx="256" cy="44" r="26" fill="%s" stroke="%s" stroke-width="5"/>' % (CREAM, INK)]
    scarf = ['<path d="M 130 360 C 190 400, 322 400, 382 360 L 392 404 C 330 446, 182 446, 120 404 Z" fill="#2F7FE0" stroke="%s" stroke-width="5"/>' % INK,
             '<path d="M 300 400 L 340 400 L 352 500 L 310 500 Z" fill="#2F7FE0" stroke="%s" stroke-width="5"/>' % INK,
             '<path d="M 304 432 L 344 432 M 306 462 L 348 462" stroke="%s" stroke-width="8"/>' % CREAM]
    flakes = []
    for x, y, r in ((60, 80, 18), (450, 140, 14), (40, 300, 12), (470, 330, 16)):
        flakes.append('<path d="%s" fill="none" stroke="#5BB8E0" stroke-width="5" stroke-linecap="round"/>'
                      % ''.join('M %d %d L %.1f %.1f ' % (x, y, x + r * math.cos(k * math.pi / 3), y + r * math.sin(k * math.pi / 3)) for k in range(6)))
    shiver = ['<path d="M 96 200 q -10 10 0 20 q 10 10 0 20 M 416 200 q 10 10 0 20 q -10 10 0 20" fill="none" stroke="#B8B0D0" stroke-width="6" stroke-linecap="round"/>']
    head = ch.pip_head('frown')
    # the hat goes on the tilted head: insert it before the head group closes
    head = head[:-1] + hat + [head[-1]] if head[-1] == '</g>' else head + hat
    return canvas(head + scarf + flakes + shiver, crop=(0, 16, 512, 512))


DOOR_BLUE, DOOR_DARK = '#3E8EDE', '#2C6FB8'
STONE, STONE_SHADE, STONE_EDGE = '#F6EAD2', '#E3D0AC', '#CDB585'


def open_door():
    """The English door, open (the same arch, stone and colours as app/assets/art/languages/door_eng_open.svg)."""
    return ['<ellipse cx="120" cy="290" rx="100" ry="9" fill="%s" opacity="0.12"/>' % INK,
            '<path d="M30 284 L30 108 A90 90 0 0 1 210 108 L210 284 Z" fill="%s"/>' % STONE_SHADE,
            '<path d="M30 284 L30 108 A90 90 0 0 1 196 70 L196 284 Z" fill="%s"/>' % STONE,
            '<rect x="24" y="278" width="192" height="12" rx="4" fill="%s"/>' % STONE_EDGE,
            '<path d="M108 18 L132 18 L128 40 L112 40 Z" fill="%s"/>' % STONE_EDGE,
            '<path d="M52 278 L52 116 A68 68 0 0 1 188 116 L188 278 Z" fill="#FFC83D"/>',
            '<path d="M64 278 L64 120 A56 56 0 0 1 176 120 L176 278 Z" fill="#FFE08A"/>',
            '<path d="M86 278 L86 132 A34 34 0 0 1 154 132 L154 278 Z" fill="#FFF3C4"/>',
            '<path d="M52 278 L52 112 Q60 90 76 84 L76 270 Z" fill="%s"/>' % DOOR_DARK,
            '<path d="M58 270 L58 116 Q64 100 72 96 L72 266 Z" fill="%s"/>' % DOOR_BLUE]


def pip_arrive():
    pip = '<g transform="translate(36 96) scale(0.36)">%s</g>' % host_parts('eng')[0]
    return canvas(open_door() + [pip], crop=(4, 6, 232, 290))


def pip_back():
    """Pip from behind: green back and folded wings, the barred crown, the long blue tail, a small red backpack, one wing
    raised in a wave over the shoulder."""
    c = ch.PIP
    out = ['<path d="M 236 380 L 214 470 Q 236 486 256 470 L 276 380 Z" fill="%s"/>' % c['tail'],
           '<ellipse cx="256" cy="314" rx="100" ry="122" fill="%s"/>' % c['green_d'],
           '<ellipse cx="256" cy="308" rx="94" ry="118" fill="%s"/>' % c['green']]
    out += ch.pip_wing(196, 320, 46, 96, 8)
    out += ch.pip_wing(392, 190, 32, 78, 36)
    out += ['<rect x="214" y="244" width="84" height="96" rx="22" fill="#E5484D" stroke="%s" stroke-width="5"/>' % INK,
            '<rect x="230" y="290" width="52" height="30" rx="10" fill="#F28084" stroke="%s" stroke-width="4"/>' % INK,
            '<path d="M 222 250 C 214 214, 234 204, 236 232 M 290 250 C 298 214, 278 204, 276 232" fill="none" stroke="%s" stroke-width="7"/>' % INK]
    out += ['<circle cx="256" cy="166" r="88" fill="%s"/>' % c['face'], '<circle cx="256" cy="162" r="84" fill="%s"/>' % c['yellow']]
    out.append('<path d="M 176 196 C 196 240, 316 240, 336 196 C 330 232, 300 252, 256 252 C 212 252, 182 232, 176 196 Z" fill="%s"/>' % c['green'])
    for k in range(5):
        y = 110 + k * 22
        half = 46 + k * 9
        out.append('<path d="M %d %d q %d 8 %d 0 q %d 8 %d 0 q %d 8 %d 0" fill="none" stroke="%s" stroke-width="3.5" stroke-linecap="round" opacity="0.6"/>'
                   % (256 - half, y, half / 3, half * 2 / 3, half / 3, half * 2 / 3, half / 3, half * 2 / 3, INK))
    for x in (226, 286):
        out += ['<path d="M %d 424 L %d 452" fill="none" stroke="%s" stroke-width="10" stroke-linecap="round"/>' % (x, x, c['feet'])]
    return out


def pip_leave():
    pip = '<g transform="translate(66 92) scale(0.34)">%s</g>' % ''.join(pip_back())
    return canvas(open_door() + [pip], crop=(4, 6, 232, 290))


def pip_holds():
    """A little puppet theatre: the curtains open on an empty, lit middle (the object picture is put there by the app),
    and Pip beside it, one wing raised to present it."""
    out = ['<rect x="22" y="40" width="212" height="170" rx="10" fill="#C98F52" stroke="%s" stroke-width="4"/>' % INK,
           '<rect x="40" y="58" width="176" height="134" rx="6" fill="#FFF3C4" stroke="%s" stroke-width="3"/>' % INK,
           '<ellipse cx="128" cy="180" rx="60" ry="8" fill="%s" opacity="0.12"/>' % INK]
    for sx in (-1, 1):
        out.append('<g transform="translate(128 0) scale(%d 1) translate(-128 0)">' % sx)
        out.append('<path d="M 40 58 L 86 58 C 76 90, 70 130, 82 168 C 70 176, 52 180, 40 192 Z" fill="#E5484D" stroke="%s" stroke-width="3"/>' % INK)
        out.append('<path d="M 52 70 C 50 110, 52 150, 60 176 M 66 66 C 62 100, 62 140, 70 170" fill="none" stroke="#B8282A" stroke-width="3"/>')
        out.append('<rect x="72" y="160" width="16" height="10" rx="4" fill="#FFC83D" stroke="%s" stroke-width="2"/>' % INK)
        out.append('</g>')
    out.append('<path d="M 22 40 L 234 40 L 234 64 Q 128 80 22 64 Z" fill="#B8282A" stroke="%s" stroke-width="3"/>' % INK)
    pip = '<g transform="translate(150 118) scale(0.26)">%s</g>' % host_parts('eng')[0]
    return canvas(out + [pip])


BUDGIE_BLUE = {'#6CC24A': '#5B8BEF', '#4E9F33': '#3E6FD9', '#93D96B': '#9DBBF7', '#3C7F2A': '#2E4FA8', '#FFD93D': '#FFFFFF',
               '#E9C22C': '#E2DEEC'}
BUDGIE_YELLOW = {'#6CC24A': '#FFD93D', '#4E9F33': '#E9C22C', '#93D96B': '#FFE98A', '#3C7F2A': '#C9A21C', '#3E6FD9': '#8EC3F0',
                 '#5B8BEF': '#B8DCF7'}
BUDGIE_GREY = {'#6CC24A': '#A9A6BC', '#4E9F33': '#86839A', '#93D96B': '#C9C6D8', '#3C7F2A': '#6E6B80', '#FFD93D': '#F1EFF6',
               '#E9C22C': '#D8D5E4'}


def pip_family():
    """Pip's own family of budgerigars (the English personal turn: "This is my family"): grandpa (grey, a cap), grandma
    (blue, round glasses), dad (blue), mum (yellow), Pip (green) and the baby (a small fluffy one)."""
    host = host_parts('eng')[0]
    out = ['<ellipse cx="128" cy="150" rx="122" ry="8" fill="#B5DFA0"/>', '<ellipse cx="128" cy="232" rx="110" ry="10" fill="#8CCB6B"/>']
    # (centre x, ground y, scale): the four grown-ups behind, Pip and the baby in front
    birds = ((38, 150, 0.2, BUDGIE_GREY, 'cap'), (98, 146, 0.2, BUDGIE_BLUE, 'glasses'), (158, 150, 0.21, BUDGIE_BLUE, ''),
             (218, 146, 0.2, BUDGIE_YELLOW, ''), (104, 232, 0.17, {}, ''), (164, 232, 0.11, BUDGIE_YELLOW, 'fluff'))
    for x, y, k, table, acc in birds:
        art = recolour([host], table)[0] if table else host
        extra = ''
        if acc == 'cap':
            extra = ('<path d="M 166 110 C 170 60, 340 60, 346 110 Z" fill="#7A7490"/><rect x="150" y="100" width="150" height="20" rx="10" '
                     'fill="#5E5A70" transform="rotate(-6 225 110)"/>')
        elif acc == 'glasses':
            extra = ('<circle cx="218" cy="160" r="30" fill="none" stroke="%s" stroke-width="8"/><circle cx="298" cy="160" r="30" fill="none" '
                     'stroke="%s" stroke-width="8"/><path d="M 248 156 L 268 156" stroke="%s" stroke-width="8"/>' % (INK, INK, INK))
        elif acc == 'fluff':
            extra = '<path d="M 236 82 q 6 -30 20 -24 q 4 -24 20 -10" fill="none" stroke="#E9C22C" stroke-width="10" stroke-linecap="round"/>'
        out.append('<g transform="translate(%s %s) scale(%s)">%s%s</g>' % (f(x - 256 * k), f(y - 466 * k), f(k), art, extra))
    return canvas(out)


# ---- the family cards ----------------------------------------------------------------------------------------------

def portrait(sp):
    return canvas(ch.person_front(sp, 'happy'), crop=portrait_crop(sp), bg=CARD.get(sp['id'], '#EDE6F7'))


def family_all():
    back = ['grandfather', 'grandmother', 'father', 'mother']
    front = ['sister', 'brother', 'mika', 'baby']
    parts = []
    for i, pid in enumerate(back):
        sp = ch.BY_ID[pid]
        parts.append('<g transform="translate(%s -40)">%s</g>' % (f(-150 + i * 100), ''.join(standing(sp, 'happy'))))
    for i, pid in enumerate(front):
        sp = ch.BY_ID[pid]
        parts.append('<g transform="translate(%s 0)">%s</g>' % (f(-150 + i * 100), ''.join(standing(sp, 'happy'))))
    return canvas(parts, crop=(-210, -280, 420, 296), bg='#FFF3C2')


def prefixed(parts, tag):
    """An object picture's elements with its clip ids made unique, so two pictures can share one SVG."""
    import re
    text = ''.join(parts)
    return re.sub(r'(id="|url\(#)(c\d+)', lambda mm: mm.group(1) + tag + mm.group(2), text)


def fam_pet():
    cat = '<g transform="translate(-6 40) scale(0.62)">%s</g>' % prefixed(m.cat().parts, 'cat')
    dog = '<g transform="translate(96 40) scale(0.62)">%s</g>' % prefixed(m.dog().parts, 'dog')
    return canvas([dog, cat], bg='#FEEFD6')


def fam_someone():
    soft = '#D9CCF5'
    return canvas(['<circle cx="128" cy="96" r="40" fill="%s"/>' % soft,
                   '<path d="M 52 236 C 52 168, 86 142, 128 142 C 170 142, 204 168, 204 236 Z" fill="%s"/>' % soft,
                   '<path d="M 128 214 C 92 190, 98 160, 118 162 C 124 162, 128 168, 128 172 C 128 168, 132 162, 138 162 '
                   'C 158 160, 164 190, 128 214 Z" fill="#E04F9E" stroke="%s" stroke-width="3"/>' % INK], bg='#ECE3FE')


# ---- the parts ------------------------------------------------------------------------------------------------------

def part_a():
    fam = ch.BY_ID
    out = {
        'pip-happy': pip_bust('happy'), 'pip-sad': pip_bust('frown'), 'pip-cold': pip_cold(), 'pip-holds': pip_holds(),
        'pip-arrive': pip_arrive(), 'pip-leave': pip_leave(), 'pip-family': pip_family(),
    }
    for pid in ('mother', 'father', 'grandmother', 'grandfather', 'brother', 'sister', 'baby'):
        out['fam-' + pid] = portrait(fam[pid])
    out['fam-all'] = family_all()
    out['fam-cousin'] = portrait(EXTRA['cousin'])
    out['fam-pet'] = fam_pet()
    out['fam-someone'] = fam_someone()
    out['girl'] = canvas(standing(EXTRA['girl']), crop=full_crop(EXTRA['girl']))
    out['boy'] = canvas(standing(EXTRA['boy']), crop=full_crop(EXTRA['boy']))
    out['girl-sing'] = canvas(singer(EXTRA['girl']), crop=(-110, -205, 200, 214))
    return out



# ---- posed people (batch 3b): the model sheet's person with jointed arms and legs ------------------------------------
# A limb is a round-capped stroke (the ink edge, then its colour), so a person can clap, wave, run or sit and still look
# exactly like the model sheet in its rest pose. Angles are degrees from straight down; in the front view a positive
# angle swings the limb outward, in the side view (facing left) forward.

def limb(pts, col, w):
    d = 'M ' + ' L '.join('%s %s' % (f(x), f(y)) for x, y in pts)
    return [L(d, INK, w + 2 * ch.SW), L(d, col, w)]


def chain(x, y, segs, side, view):
    """Points of a jointed limb from (x, y): segs = [(length, angle), ...], each angle added to the last."""
    pts, a = [(x, y)], 0.0
    for length, da in segs:
        a += da
        rad = math.radians(a)
        dx = (side * math.sin(rad)) if view == 'front' else (-math.sin(rad))
        x, y = x + length * dx, y + length * math.cos(rad)
        pts.append((x, y))
    return pts


def head_block(sp, expr, view, tilt=0):
    H, r, hc, body, sh, hip, tw, lw, aw, arm = ch.geometry(sp)
    skin = ch.SKIN[sp['skin']]
    out = ['<g transform="rotate(%s 0 %s)">' % (f(tilt), f(hc + r))]
    if view == 'front':
        out.append(RR(-r * 0.24, hc + r * 0.7, r * 0.48, sh - hc - r * 0.6, r * 0.2, skin))
        out += ch.hair_back_front(sp, r, hc)
        out += [E(sx * r * 0.98, hc + r * 0.12, r * 0.2, r * 0.24, skin) for sx in (-1, 1)]
        out.append(E(0, hc, r, r * 1.02, skin))
        out += ch.hair_top_front(sp, r, hc)
        out += face(sp, r, hc, expr)
        if 'glasses' in sp['extras']:
            out += [E(sx * r * 0.36, hc + r * 0.1, r * 0.24, r * 0.24, 'none', 2.5) for sx in (-1, 1)]
            out.append(L('M %s %s Q 0 %s %s %s' % (f(-r * 0.12), f(hc + r * 0.06), f(hc), f(r * 0.12), f(hc + r * 0.06)), INK, 2.5))
    else:
        out.append(RR(-r * 0.2, hc + r * 0.7, r * 0.44, sh - hc - r * 0.6, r * 0.2, skin))
        hs = ch.hair_side(sp, r, hc)
        if sp['hair'] in ('bun', 'ponytail', 'curls'):
            out.append(hs.pop(0))
        out.append(E(r * 0.05, hc, r, r * 1.02, skin))
        out.append(E(-r * 0.98, hc + r * 0.14, r * 0.15, r * 0.15, skin))
        out.append(P('M %s %s C %s %s, %s %s, %s %s' % (f(r * 0.2), f(hc - r * 0.06), f(r * 0.46), f(hc - r * 0.12), f(r * 0.48), f(hc + r * 0.36),
                                                       f(r * 0.22), f(hc + r * 0.32)), skin, 2.5))
        out += hs
        out += ch.face_side(r, hc)
        if expr in ('happy', 'laugh'):
            out.append(P('M %s %s Q %s %s %s %s Z' % (f(-r * 0.92), f(hc + r * 0.44), f(-r * 0.78), f(hc + r * 0.72), f(-r * 0.56), f(hc + r * 0.48)), ch.MOUTH, 2))
        if 'glasses' in sp['extras']:
            out.append(E(-r * 0.52, hc + r * 0.04, r * 0.24, r * 0.24, 'none', 2.5))
            out.append(L('M %s %s L %s %s' % (f(-r * 0.28), f(hc), f(r * 0.2), f(hc - r * 0.02)), INK, 2.5))
    out.append('</g>')
    return out


def face(sp, r, hc, expr):
    if expr in ('happy', 'frown', 'smile', 'think'):
        return ch.face_front(r, hc, expr)
    ex, ey, er = r * 0.36, hc + r * 0.1, r * 0.13
    out = [E(sx * r * 0.58, hc + r * 0.36, r * 0.17, r * 0.1, ch.CHEEK, 0, op=0.6) for sx in (-1, 1)]
    if expr in ('closed', 'laugh', 'shiver'):
        out += [L('M %s %s Q %s %s %s %s' % (f(sx * ex - er * 1.1), f(ey), f(sx * ex), f(ey + er * 1.1 * (1 if expr == 'closed' else -1)),
                                             f(sx * ex + er * 1.1), f(ey)), INK, 3) for sx in (-1, 1)]
    else:
        lx = {'look': er * 0.45, 'lookleft': -er * 0.5, 'sing': 0}.get(expr, 0)
        for sx in (-1, 1):
            out.append(E(sx * ex + lx, ey, er, er * 1.15, INK, 0))
            out.append('<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % (f(sx * ex + lx - er * 0.35), f(ey - er * 0.4), f(er * 0.38), WHITE))
    mw, my = r * 0.26, hc + r * 0.46
    if expr == 'laugh':
        out.append(P('M %s %s Q 0 %s %s %s Z' % (f(-mw * 1.1), f(my - 3), f(my + mw * 1.6), f(mw * 1.1), f(my - 3)), ch.MOUTH, 2.5))
        out.append(P('M %s %s Q 0 %s %s %s Z' % (f(-mw * 0.6), f(my + mw * 0.7), f(my + mw * 1.4), f(mw * 0.6), f(my + mw * 0.7)), '#F28AA0', 0))
    elif expr == 'sing':
        out.append(E(0, my + 2, r * 0.15, r * 0.19, ch.MOUTH, 2.5))
    elif expr == 'shiver':
        out.append(L('M %s %s l %s %s l %s %s l %s %s l %s %s' % (f(-mw * 0.8), f(my + 3), f(mw * 0.4), f(-5), f(mw * 0.4), f(5), f(mw * 0.4), f(-5),
                                                               f(mw * 0.4), f(5)), INK, 2.5))
    elif expr == 'eat':
        out.append(E(0, my + 2, r * 0.14, r * 0.12, ch.MOUTH, 2.5))
    else:
        out.append(L('M %s %s Q 0 %s %s %s' % (f(-mw * 0.7), f(my), f(my + mw * 0.7), f(mw * 0.7), f(my)), ch.MOUTH, 2.5))
    return out


def posed(sp, view='front', arms=((8, 0), (8, 0)), legs=((3, 0), (3, 0)), lift=0, expr='smile', tilt=0, lean=0, flat=None,
          props_back=(), props_front=(), reach=None, visor=None, behind=(), palms=False):
    """A person in a pose. arms/legs: (shoulder or hip angle, elbow or knee bend) for (left, right) in the front view or
    (far, near) in the side view; lift raises the body (a jump); lean tilts the body forward (side view)."""
    H, r, hc, body, sh, hip, tw, lw, aw, arm = ch.geometry(sp)
    skin = ch.SKIN[sp['skin']]
    top = sp.get('top') or sp.get('dress') or sp.get('romper')
    shorts = sp.get('bottomc') if sp.get('bottom') == 'shorts' else None
    trousers = sp.get('bottomc') if sp.get('bottom') == 'trousers' else None
    ua, fa = arm * 0.52, arm * 0.5
    th, sn = (-hip) * 0.5, (-hip) * 0.5 - lw * 0.15
    out = [ch.shadow(r * (1.6 if lift == 0 else 1.1))] + list(props_back)
    out.append('<g transform="translate(0 %s)">' % f(-lift))
    if view == 'front':
        hips = [(-(tw * 0.03 + lw / 2), hip), ((tw * 0.03 + lw / 2), hip)]
        shoulders = [(-(tw / 2 - aw * 0.25), sh + aw * 0.55), ((tw / 2 - aw * 0.25), sh + aw * 0.55)]
        sides = (-1, 1)
    else:
        hips = [(lw * 0.2, hip), (-lw * 0.2, hip)]
        shoulders = [(aw * 0.3, sh + aw * 0.55), (-aw * 0.1, sh + aw * 0.55)]
        sides = (1, 1)

    def dimc(c, dim):
        return m.mix(c, INK, 0.2) if dim and c and c.startswith('#') else c

    def draw_leg(i, dim):
        (b1, b2), (x0, y0), s = legs[i], hips[i], sides[i]
        pts = chain(x0, y0, [(th, b1), (sn, b2)], s, view)
        o = limb(pts, dimc(trousers or skin, dim), lw)
        if shorts:
            mid = (pts[0][0] + (pts[1][0] - pts[0][0]) * 0.55, pts[0][1] + (pts[1][1] - pts[0][1]) * 0.55)
            o += limb([pts[0], mid], dimc(shorts, dim), lw + 2)
        fx, fy = pts[-1]
        dx = (s * lw * 0.2) if view == 'front' else (-lw * 0.35)
        o.append(E(fx + dx, fy + lw * 0.1, lw * (0.66 if view == 'front' else 0.8), lw * 0.32, dimc(sp['shoes'] or skin, dim)))
        return o

    def draw_arm(i, dim):
        (a1, a2), (x0, y0), s = arms[i], shoulders[i], sides[i]
        k = (reach or {}).get(i, 1.0)
        ku, kf = k if isinstance(k, tuple) else (k, k)
        k = ku
        pts = chain(x0, y0, [(ua * ku, a1), (fa * kf, a2)], s, view)
        long_sleeve = sp.get('adult') and not sp.get('vest')
        o = limb(pts, dimc(top if long_sleeve else skin, dim), aw)
        if not long_sleeve:
            t = 0.55 / k
            mid = (pts[0][0] + (pts[1][0] - pts[0][0]) * t, pts[0][1] + (pts[1][1] - pts[0][1]) * t)
            o += limb([pts[0], mid], dimc(top, dim), aw + 3)
        hx, hy = pts[-1]
        hd = []
        if visor is not None and visor == i:     # a hand held flat over the brow, fingers pointing across
            hd.append(RR((hx - aw * 1.05) if view == 'front' else hx - aw * 2.0, hy - aw * 0.32, aw * 2.1, aw * 0.64, aw * 0.3, skin))
        elif flat is not None and flat == i:      # a palm held up, fingers up (stop)
            hd.append(RR(hx - aw * 0.42, hy - aw * 1.55, aw * 0.84, aw * 1.9, aw * 0.4, skin))
            hd.append(RR(hx - aw * 0.95, hy - aw * 0.75, aw * 0.6, aw * 0.36, aw * 0.18, skin))
        elif palms:                               # an open palm seen from the side, fingers up (clap)
            hd.append(RR(hx - aw * 0.38, hy - aw * 1.25, aw * 0.76, aw * 1.6, aw * 0.36, skin))
        else:
            hd.append(E(hx, hy, aw * 0.62, aw * 0.62, dimc(skin, dim)))
        return o + hd, (hx, hy), o, hd

    hands = {}
    far_arm = draw_arm(0, True)[0] if view == 'side' else []
    late = []
    if view == 'side':
        out += draw_leg(0, True)
    for i in ((0, 1) if view == 'front' else (1,)):
        out += draw_leg(i, False)
    if shorts and view == 'front':
        out.append(RR(-tw / 2 + 1, hip - body * 0.06, tw - 2, lw * 0.95, lw * 0.4, shorts))
    out.append('<g transform="rotate(%s 0 %s)">' % (f(lean), f(hip)))
    out += far_arm
    if sp.get('dress'):
        hem = hip + (-hip) * 0.42
        w0 = tw if view == 'front' else tw * 0.6
        out.append(P('M %s %s L %s %s C %s %s, %s %s, %s %s L %s %s Z'
                     % (f(-w0 / 2), f(sh + 4), f(-w0 * 0.78), f(hem), f(-w0 * 0.3), f(hem + 6), f(w0 * 0.3), f(hem + 6), f(w0 * 0.78), f(hem),
                        f(w0 / 2), f(sh + 4)), sp['dress']))
    elif sp.get('bottom') == 'skirt':
        w0 = tw if view == 'front' else tw * 0.64
        out.append(P('M %s %s L %s %s L %s %s L %s %s Z' % (f(-w0 / 2), f(hip - 6), f(-w0 * 0.72), f(-H * 0.1), f(w0 * 0.72), f(-H * 0.1),
                                                            f(w0 / 2), f(hip - 6)), sp['bottomc']))
        out.append(RR(-w0 / 2, sh, w0, hip - sh + body * 0.05, w0 * 0.3, top))
    else:
        w0 = tw if view == 'front' else tw * 0.64
        out.append(RR(-w0 / 2, sh, w0, hip - sh + body * 0.05, w0 * 0.3, top))
    for i in behind:      # an arm that goes behind the head: the arm first, its hand after the head
        _, hands[i], arm_only, hand_only = draw_arm(i, False)
        out += arm_only
        late += hand_only
    out += head_block(sp, expr, view, tilt)
    for i in ((0, 1) if view == 'front' else (1,)):
        if i in behind:
            continue
        o, hands[i], _, _ = draw_arm(i, False)
        out += o
    out += late
    out.append('</g>')
    out += list(props_front)
    out.append('</g>')
    return out


def motion(x, y, r, vertical=False, n=2):
    """Motion arcs beside something that moves (a clap, a wave, a nod)."""
    out = []
    for k in range(n):
        rr = r + k * 9
        if vertical:
            out.append(L('M %s %s Q %s %s %s %s' % (f(x - rr), f(y - 6), f(x), f(y - rr * 0.5 - 6), f(x + rr), f(y - 6)), '#B8B0D0', 4))
        else:
            out.append(L('M %s %s Q %s %s %s %s' % (f(x - rr * 0.4), f(y - rr), f(x - rr * 0.9), f(y), f(x - rr * 0.4), f(y + rr)), '#B8B0D0', 4))
            out.append(L('M %s %s Q %s %s %s %s' % (f(x + rr * 0.4), f(y - rr), f(x + rr * 0.9), f(y), f(x + rr * 0.4), f(y + rr)), '#B8B0D0', 4))
    return out


MIKA = ch.BY_ID['mika']


def mika_crop(pad=0):
    return (-95 - pad, -186 - pad, 190 + 2 * pad, 200 + 2 * pad)


def side_chair(x, seat_y, w=50):
    wood, dark = '#C98F52', '#A8743C'
    return [RR(x - w / 2, seat_y, w, 8, 3, wood), RR(x + w / 2 - 8, seat_y - 52, 8, 60, 3, dark),
            RR(x - w / 2 + 2, seat_y + 6, 7, -seat_y - 6, 3, wood), RR(x + w / 2 - 9, seat_y + 6, 7, -seat_y - 6, 3, wood)]


def front_chair(seat_y, w=62):
    wood, dark = '#C98F52', '#A8743C'
    return [RR(-w / 2, seat_y - 62, w, 60, 6, dark), RR(-w / 2 - 4, seat_y - 4, w + 8, 10, 4, wood),
            RR(-w / 2, seat_y + 4, 8, -seat_y - 4, 3, wood), RR(w / 2 - 8, seat_y + 4, 8, -seat_y - 4, 3, wood)]


def dust(x, y):
    return [E(x + dx, y + dy, rr, rr * 0.8, '#E3D6C6', 2.5) for dx, dy, rr in ((0, 0, 10), (16, -6, 8), (30, 2, 6))]


def ground(y=0, w=240, col='#B5DFA0'):
    return ['<ellipse cx="0" cy="%s" rx="%s" ry="10" fill="%s"/>' % (f(y + 4), f(w / 2), col)]


def act(name):
    sp = MIKA
    H, r, hc, body, sh, hip, tw, lw, aw, arm = ch.geometry(sp)
    if name == 'clap':
        parts = posed(sp, arms=((10, -110), (10, -110)), reach={0: (1.4, 1.25), 1: (1.4, 1.25)}, palms=True, expr='happy')
        top_y = -51 - aw * 1.3
        parts += [L('M 0 %s L 0 %s M -8 %s L -15 %s M 8 %s L 15 %s M -10 %s L -18 %s M 10 %s L 18 %s'
                    % (f(top_y - 3), f(top_y - 10), f(top_y - 1), f(top_y - 7), f(top_y - 1), f(top_y - 7),
                       f(top_y + 8), f(top_y + 6), f(top_y + 8), f(top_y + 6)), '#E04F9E', 3)]
    elif name == 'jump':
        parts = posed(sp, arms=((150, 15), (150, 15)), legs=((25, -50), (25, -50)), lift=26, expr='laugh')
        parts += [L('M -30 -6 L -40 6 M 0 -2 L 0 10 M 30 -6 L 40 6', '#B8B0D0', 4)]
    elif name == 'listen':
        parts = posed(sp, arms=((8, 0), (155, 148)), expr='closed', tilt=-6)
        parts += [L('M 56 %s q 10 10 0 20 M 66 %s q 14 14 0 28' % (f(hc - 4), f(hc - 8)), '#B8B0D0', 4)]
    elif name == 'look':
        boat = '<g transform="translate(-108 -150) scale(0.16)">%s</g>' % prefixed(m.boat('blue').parts, 'bt')
        sea = ['<path d="M -130 -112 L -40 -112" stroke="#8FD3F4" stroke-width="5"/>']
        parts = sea + [boat] + posed(sp, arms=((140, 95), (8, 0)), expr='lookleft', tilt=5, reach={0: (1.5, 2.22)}, visor=0, behind=(0,))
    elif name == 'sit':
        seat = hip + (-hip) * 0.5
        parts = posed(sp, view='side', arms=((10, -20), (10, -40)), legs=((90, -90), (90, -90)), lift=-(-hip) * 0.5 + lw * 0.1,
                      props_back=side_chair(18, seat - lw * 0.1 + 2))
    elif name == 'stand':
        parts = posed(sp, arms=((160, 10), (160, 10)), expr='happy', props_back=front_chair(-38, 70))
    elif name == 'stop':
        parts = posed(sp, view='side', arms=((4, 0), (90, 0)), legs=((1, 0), (-1, 0)), flat=1, expr='smile')
        px = -aw * 0.1 - arm * 1.02
        parts += [L('M %s %s l -10 0 M %s %s l -12 0 M %s %s l -10 0' % (f(px - 14), f(sh - 6), f(px - 14), f(sh + 6), f(px - 14), f(sh + 18)), '#B8B0D0', 4)]
    elif name == 'wave':
        parts = posed(sp, arms=((8, 0), (140, 28)), expr='happy') + motion(62, -150, 12)
    elif name == 'run':
        parts = posed(sp, view='side', arms=((-40, 80), (50, 70)), legs=((-40, 60), (50, -70)), lean=-8, lift=8, expr='happy')
        parts += [L('M 40 -110 L 70 -110 M 46 -90 L 80 -90 M 40 -70 L 66 -70', '#B8B0D0', 4)]
    elif name == 'walk':
        parts = posed(sp, view='side', arms=((-18, 20), (22, 20)), legs=((-18, 4), (20, -8)))
    elif name == 'take':
        ball = '<g transform="translate(-62 -30) scale(0.13)">%s</g>' % prefixed(m.ball('red').parts, 'ball')
        ball = '<g transform="translate(-44 -30) scale(0.12)">%s</g>' % prefixed(m.ball('red').parts, 'ball')
        parts = posed(sp, view='side', arms=((40, 0), (52, 0)), legs=((-10, 14), (30, -40)), lean=-34, lift=-3) + [ball]
    return canvas(parts, crop=mika_crop())


# ---- greetings, a gift, yes and no ---------------------------------------------------------------------------------

def gate(x0=-110, x1=110, open_left=True):
    wood, dark = '#C98F52', '#A8743C'
    out = []
    for x in range(int(x0), int(x1) + 1, 22):
        if -30 < x < 30:
            continue
        out.append(P('M %d -10 L %d -86 L %d -96 L %d -86 L %d -10 Z' % (x - 7, x - 7, x, x + 7, x + 7), wood, 2.5))
    out += [RR(x0 - 6, -78, 84, 9, 3, dark), RR(x1 - 78, -78, 84, 9, 3, dark), RR(x0 - 6, -40, 84, 9, 3, dark), RR(x1 - 78, -40, 84, 9, 3, dark)]
    out += [RR(-38, -110, 12, 104, 4, dark), RR(26, -110, 12, 104, 4, dark)]
    out += [P('M -26 -96 L -60 -84 L -60 -16 L -26 -8 Z', wood, 2.5)]
    return out


def mika_arrive():
    return canvas(ground(0, 240) + gate() + posed(MIKA, arms=((8, 0), (140, 28)), expr='happy') + motion(62, -150, 12), crop=(-120, -196, 240, 212))


def mika_leave():
    body = posed(MIKA, view='side', arms=((-18, 20), (-150, -20)), legs=((-18, 4), (20, -8)), expr='happy')
    walker = '<g transform="translate(0 0) scale(-1 1)">%s</g>' % ''.join(body)
    return canvas(ground(0, 240) + gate() + [walker], crop=(-120, -196, 240, 212))


def mika_gift():
    apple = '<g transform="translate(-24 -102) scale(0.19)">%s</g>' % prefixed(m.apple().parts, 'ap')
    giver = [L('M 140 -80 L 52 -86', INK, 22 + 6), L('M 140 -80 L 52 -86', '#2F7FE0', 22), E(44, -86, 13, 12, ch.SKIN[2])]
    return canvas(posed(MIKA, arms=((20, -100), (20, -100)), expr='laugh') + [apple] + giver, crop=(-100, -196, 220, 212))


def mika_nod(yes):
    sp = MIKA
    H, r, hc = sp['H'], sp['hr'], -sp['H'] + sp['hr']
    parts = posed(sp, expr='happy' if yes else 'smile', tilt=10 if yes else 0)
    col = '#B8B0D0'
    for sx in (-1, 1):
        x = sx * r * 1.55
        if yes:   # up and down beside the head
            parts += [L('M %s %s L %s %s' % (f(x), f(hc - r * 0.6), f(x), f(hc + r * 0.6)), col, 5),
                      L('M %s %s l -7 9 M %s %s l 7 9' % (f(x), f(hc - r * 0.6), f(x), f(hc - r * 0.6)), col, 5),
                      L('M %s %s l -7 -9 M %s %s l 7 -9' % (f(x), f(hc + r * 0.6), f(x), f(hc + r * 0.6)), col, 5)]
        else:     # side to side beside the head
            parts += [L('M %s %s Q %s %s %s %s' % (f(x - sx * 4), f(hc - r * 0.5), f(x + sx * 12), f(hc), f(x - sx * 4), f(hc + r * 0.5)), col, 5),
                      L('M %s %s l %s -2 l %s 9' % (f(x - sx * 4), f(hc + r * 0.5), f(-sx * 10), f(sx * 2)), col, 5)]
    return canvas(parts, crop=(-r * 2.4, hc - r * 1.9, r * 4.8, r * 4.8))


# ---- the English scenes --------------------------------------------------------------------------------------------

def scene_icecream():
    cone = [P('M 58 -6 L 86 -14 L 76 6 Z', '#E2A85C', 2.5), P('M 30 -2 C 26 -22, 60 -24, 64 -6 C 56 4, 36 6, 30 -2 Z', '#F7A8C4', 2.5),
            E(40, -14, 3, 3, '#E53935', 0), E(52, -10, 2.5, 2.5, '#4CAF50', 0)]
    return canvas(ground(0, 240) + posed(MIKA, expr='frown', tilt=8, arms=((10, 0), (10, 0))) + cone, crop=(-110, -196, 220, 212))


def scene_present():
    import make_language_pictures_b2 as b2
    box = ['<g transform="translate(-36 -100) scale(0.28)">%s</g>' % prefixed(b2.present().parts, 'pr')]
    confetti = [E(x, y, 5, 3, c, 0) for x, y, c in ((-60, -170, '#E53935'), (64, -160, '#FFC83D'), (-74, -120, '#2F7FE0'), (80, -120, '#36A852'),
                                                 (-40, -186, '#8A5CF0'), (40, -184, '#E04F9E'))]
    return canvas(confetti + posed(MIKA, arms=((26, -96), (26, -96)), expr='laugh') + box, crop=(-110, -200, 220, 214))


def scene_snow():
    sp = dict(MIKA)
    H, r, hc = sp['H'], sp['hr'], -sp['H'] + sp['hr']
    hat = [P('M %s %s C %s %s, %s %s, %s %s Z' % (f(-r * 1.0), f(hc - r * 0.45), f(-r * 0.9), f(hc - r * 1.5), f(r * 0.9), f(hc - r * 1.5), f(r * 1.0), f(hc - r * 0.45)), '#E5484D'),
           RR(-r * 1.08, hc - r * 0.62, r * 2.16, r * 0.34, r * 0.14, CREAM), E(0, hc - r * 1.42, r * 0.22, r * 0.22, CREAM)]
    scarf = [RR(-r * 0.9, hc + r * 0.86, r * 1.8, r * 0.36, r * 0.16, '#2F7FE0'), RR(r * 0.2, hc + r * 1.0, r * 0.36, r * 1.1, r * 0.14, '#2F7FE0')]
    flakes = []
    for x, y, rr in ((-80, -170, 8), (70, -180, 7), (-60, -90, 6), (86, -100, 8), (-90, -40, 6), (60, -40, 5)):
        flakes.append(L(''.join('M %d %d L %.1f %.1f ' % (x, y, x + rr * math.cos(k * math.pi / 3), y + rr * math.sin(k * math.pi / 3)) for k in range(6)), '#5BB8E0', 3))
    body = posed(sp, expr='shiver', arms=((20, -100), (20, -100)))
    body = body[:-1] + hat + scarf + [body[-1]]
    shake = [L('M -46 -120 q -8 8 0 16 q 8 8 0 16 M 46 -120 q 8 8 0 16 q -8 8 0 16', '#B8B0D0', 4)]
    return canvas(['<ellipse cx="0" cy="4" rx="130" ry="16" fill="#F4F8FF" stroke="#CFE3F5" stroke-width="3"/>'] + body + flakes + shake,
                  crop=(-110, -200, 220, 214))


def scene_walk():
    tree = ['<g transform="translate(-2 -118) scale(0.42)">%s</g>' % prefixed(__import__('make_language_pictures_b2').tree().parts, 'tr')]
    path = ['<path d="M -130 4 C -60 -10, 60 -10, 130 4 L 130 16 L -130 16 Z" fill="#E8D9B8"/>']
    return canvas(tree + path + posed(MIKA, view='side', arms=((-18, 20), (22, 20)), legs=((-18, 4), (20, -8))), crop=(-110, -196, 220, 212))


# ---- grown-ups of the courses ---------------------------------------------------------------------------------------

def teacher_sing():
    t, g, b = EXTRA['teacher'], EXTRA['girl'], EXTRA['boy']
    parts = ['<g transform="translate(0 0)">%s</g>' % ''.join(posed(t, arms=((30, -40), (140, 30)), expr='sing'))]
    parts.append('<g transform="translate(-86 0)">%s</g>' % ''.join(posed(g, expr='sing', arms=((10, 0), (10, 0)))))
    parts.append('<g transform="translate(86 0)">%s</g>' % ''.join(posed(b, expr='sing', arms=((10, 0), (10, 0)))))
    parts += note(70, -200, 0.9) + note(-70, -186, 0.8, '#E04F9E')
    return canvas(parts, crop=(-130, -240, 260, 254))


def plain_door():
    return [RR(-60, -170, 120, 172, 10, '#E3D0AC'), RR(-46, -158, 92, 160, 8, '#FFE08A'),
            P('M -46 2 L -46 -158 L -26 -150 L -26 -4 Z', '#9C6B3C'), E(-34, -80, 3, 3, '#FFC83D', 1.5)]


def neighbour_arrive():
    n = EXTRA['neighbour']
    bag = [RR(-58, -100, 30, 34, 6, '#F2D3A0'), L('M -52 -100 Q -43 -118 -34 -100', INK, 3)]
    return canvas(['<g transform="translate(-40 0)">%s</g>' % ''.join(plain_door())] + posed(n, arms=((10, 0), (140, 28)), expr='happy', props_front=bag)
                  + motion(66, -190, 12), crop=(-120, -240, 240, 254))


def neighbour_leave():
    n = EXTRA['neighbour']
    body = posed(n, view='side', arms=((-18, 20), (-150, -20)), legs=((-18, 4), (20, -8)), expr='happy')
    walker = '<g transform="translate(30 0) scale(-1 1)">%s</g>' % ''.join(body)
    return canvas(['<g transform="translate(-50 0)">%s</g>' % ''.join(plain_door())] + [walker], crop=(-120, -240, 240, 254))


def part_b():
    out = {'teacher-sing': teacher_sing(), 'neighbour-arrive': neighbour_arrive(), 'neighbour-leave': neighbour_leave()}
    for a in ('clap', 'jump', 'listen', 'look', 'sit', 'stand', 'stop', 'wave', 'run', 'walk', 'take'):
        out['act-' + a] = act(a)
    out.update({'mika-arrive': mika_arrive(), 'mika-leave': mika_leave(), 'mika-gift': mika_gift(), 'mika-yes': mika_nod(True),
                'mika-no': mika_nod(False), 'mika-icecream': scene_icecream(), 'mika-present': scene_present(), 'mika-snow': scene_snow(),
                'mika-walk': scene_walk()})
    return out



# ---- Mika's body, the close-ups, the faces and the mouth shapes (batch 3c) ------------------------------------------

GLOW = '#FFC83D'


def glow(cx, cy, rx, ry):
    return ['<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" opacity="0.14"/>' % (f(cx), f(cy), f(rx), f(ry), GLOW),
            '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="none" stroke="%s" stroke-width="5" opacity="0.9"/>' % (f(cx), f(cy), f(rx), f(ry), WHITE),
            '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="none" stroke="%s" stroke-width="2.5"/>' % (f(cx), f(cy), f(rx), f(ry), '#F59E1B')]


def nose(r, hc):
    """Mika's small soft nose (the body words need one; the cast's faces leave it out)."""
    return [P('M %s %s Q %s %s %s %s' % (f(-r * 0.09), f(hc + r * 0.26), f(0), f(hc + r * 0.36), f(r * 0.09), f(hc + r * 0.26)), 'none', 2.5)]


def open_hand(x, y, ang, sp, scale=1.0):
    """An open hand, palm to the viewer, five fingers spread, pointing along ang (degrees from straight down)."""
    aw = ch.geometry(sp)[8] * scale
    skin = ch.SKIN[sp['skin']]
    out = ['<g transform="translate(%s %s) rotate(%s)">' % (f(x), f(y), f(ang))]
    for k, (a, ln) in enumerate(((-58, 0.78), (-22, 1.0), (0, 1.08), (22, 1.0), (44, 0.86))):
        rad = math.radians(a)
        x1, y1 = aw * 0.95 * ln * math.sin(rad), aw * 0.4 + aw * 0.95 * ln * math.cos(rad)
        out += limb([(0, aw * 0.25), (x1, y1)], skin, aw * 0.34)
    out.append(E(0, aw * 0.18, aw * 0.62, aw * 0.58, skin))
    out.append('</g>')
    return out


def toes(x, y, lw):
    return [E(x + dx * lw, y + lw * 0.18, lw * 0.13, lw * 0.11, ch.SKIN[MIKA['skin']], 1.8) for dx in (-0.42, -0.2, 0.02, 0.22, 0.4)]


def mika_open(arms, expr='happy', props_front=(), feet=True):
    """Mika in the front view with open hands (fingers) and bare feet with toes."""
    sp = MIKA
    H, r, hc, body, sh, hip, tw, lw, aw, arm = ch.geometry(sp)
    parts = posed(sp, arms=arms, expr=expr)
    ua, fa = arm * 0.52, arm * 0.5
    extra = []
    for i, s in ((0, -1), (1, 1)):
        x0, y0 = s * (tw / 2 - aw * 0.25), sh + aw * 0.55
        pts = chain(x0, y0, [(ua, arms[i][0]), (fa, arms[i][1])], s, 'front')
        a = arms[i][0] + arms[i][1]
        extra += open_hand(pts[-1][0], pts[-1][1] - aw * 0.15, -s * a, sp)
    if feet:
        for s in (-1, 1):
            x = s * (tw * 0.03 + lw / 2)
            extra += toes(x + s * lw * 0.2, -lw * 0.2, lw)
    return parts[:-1] + nose(r, hc) + extra + list(props_front) + [parts[-1]]


def grin(r, hc):
    mw, my = r * 0.34, hc + r * 0.44
    return [P('M %s %s Q 0 %s %s %s Z' % (f(-mw), f(my - 3), f(my + mw * 1.2), f(mw), f(my - 3)), ch.MOUTH, 2.5),
            P('M %s %s L %s %s Q 0 %s %s %s Z' % (f(-mw * 0.86), f(my - 1), f(mw * 0.86), f(my - 1), f(my + mw * 0.36), f(-mw * 0.86), f(my - 1)), WHITE, 1.5),
            L(''.join('M %s %s L %s %s ' % (f(x), f(my - 1), f(x), f(my + mw * 0.24)) for x in (-mw * 0.4, 0, mw * 0.4)), '#D8D3E6', 1.5)]


BODY_ARMS = ((32, 4), (32, 4))


def mika_body():
    sp = MIKA
    H, r, hc = sp['H'], sp['hr'], -sp['H'] + sp['hr']
    parts = mika_open(BODY_ARMS, expr='smile')
    parts = parts[:-1] + [E(0, hc + r * 0.5, r * 0.36, r * 0.2, ch.SKIN[sp['skin']], 0)] + grin(r, hc) + [parts[-1]]
    return canvas(parts, crop=BODY_CROP)


BODY_CROP = (-84, -152, 168, 166)


def hotspots():
    """The tap areas of mika-body.svg in its 0..256 canvas: circles (cx, cy, r) or rectangles (x, y, w, h); no two
    overlap, so any three of them can glow in an item (the Russian rule; English uses 8, Russian 11)."""
    sp = MIKA
    H, r, hc, body, sh, hip, tw, lw, aw, arm = ch.geometry(sp)
    x, y, w, h = BODY_CROP
    k = 256.0 / max(w, h)
    tx, ty = (256 - w * k) / 2 - x * k, (256 - h * k) / 2 - y * k

    def pt(px, py):
        return round(px * k + tx, 1), round(py * k + ty, 1)

    def circ(px, py, rr):
        cx, cy = pt(px, py)
        return {'circle': [cx, cy, round(rr * k, 1)]}

    def rect(px, py, pw, ph):
        x0, y0 = pt(px, py)
        return {'rect': [x0, y0, round(pw * k, 1), round(ph * k, 1)]}

    ua, fa = arm * 0.52, arm * 0.5
    hand_pts = []
    for i, s in ((0, -1), (1, 1)):
        pts = chain(s * (tw / 2 - aw * 0.25), sh + aw * 0.55, [(ua, BODY_ARMS[i][0]), (fa, BODY_ARMS[i][1])], s, 'front')
        hand_pts.append(pts)
    spots = {
        'hair': rect(-r * 0.9, hc - r * 1.2, r * 1.8, r * 0.5),
        'head': rect(-r * 0.75, hc - r * 0.66, r * 1.5, r * 0.4),
        'eyes': rect(-r * 0.62, hc - r * 0.12, r * 1.24, r * 0.31),
        'nose': circ(0, hc + r * 0.3, r * 0.1),
        'mouth': rect(-r * 0.4, hc + r * 0.44, r * 0.8, r * 0.38),
        'teeth': rect(-r * 0.4, hc + r * 0.44, r * 0.8, r * 0.38),
        'ears': [circ(-r * 1.02, hc + r * 0.12, r * 0.24), circ(r * 1.02, hc + r * 0.12, r * 0.24)],
        'arms': [circ((q[0][0] + q[1][0]) / 2, (q[0][1] + q[1][1]) / 2 + aw * 0.2, aw * 0.72) for q in hand_pts],
        'hands': [circ(q[2][0], q[2][1] + aw * 0.4, aw * 1.05) for q in hand_pts],
        'fingers': [circ(q[2][0], q[2][1] + aw * 0.4, aw * 1.05) for q in hand_pts],
        'tummy': rect(-tw * 0.3, sh + body * 0.16, tw * 0.6, body * 0.22),
        'belly': rect(-tw * 0.3, sh + body * 0.16, tw * 0.6, body * 0.22),
        'legs': rect(-tw * 0.48, hip + lw * 0.6, tw * 0.96, (-hip) * 0.55),
        'feet': rect(-tw * 0.62, -lw * 0.6, tw * 1.24, lw * 0.85),
    }
    note_ = ('Tap areas of mika-body.svg in its 256 x 256 canvas. teeth = mouth (the picture grins), hands = fingers, '
             'tummy = belly (one place, two courses\' words). Regions of different parts never overlap.')
    check_apart(spots)
    return {'picture': 'mika-body', 'note': note_, 'areas': spots}


def check_apart(spots):
    """No two body parts' tap areas overlap (their bounding boxes, a safe test); the alias pairs share one place."""
    same = {frozenset(('mouth', 'teeth')), frozenset(('hands', 'fingers')), frozenset(('tummy', 'belly'))}
    boxes = {}
    for name, a in spots.items():
        for one in (a if isinstance(a, list) else [a]):
            if 'rect' in one:
                x, y, w, h = one['rect']
            else:
                cx, cy, rr = one['circle']
                x, y, w, h = cx - rr, cy - rr, 2 * rr, 2 * rr
            boxes.setdefault(name, []).append((x, y, x + w, y + h))
    names = sorted(boxes)
    for i, a in enumerate(names):
        for b in names[i + 1:]:
            if frozenset((a, b)) in same:
                continue
            for p in boxes[a]:
                for q in boxes[b]:
                    assert p[2] <= q[0] or q[2] <= p[0] or p[3] <= q[1] or q[3] <= p[1], ('overlap', a, b, p, q)


def close_up(which):
    sp = MIKA
    H, r, hc, body, sh, hip, tw, lw, aw, arm = ch.geometry(sp)
    base = mika_open(BODY_ARMS, expr='happy')
    if which == 'head':
        return canvas(base + glow(0, hc, r * 1.22, r * 1.22), crop=(-r * 2.0, hc - r * 1.8, r * 4.0, r * 4.0))
    if which == 'eyes':
        return canvas(base + glow(0, hc + r * 0.1, r * 0.72, r * 0.3),
                      crop=(-r * 1.1, hc - r * 0.9, r * 2.2, r * 2.2))
    if which == 'ears':
        return canvas(base + glow(-r * 1.0, hc + r * 0.12, r * 0.3, r * 0.34) + glow(r * 1.0, hc + r * 0.12, r * 0.3, r * 0.34),
                      crop=(-r * 1.6, hc - r * 1.4, r * 3.2, r * 3.0))
    if which == 'nose':
        return canvas(base + glow(0, hc + r * 0.3, r * 0.2, r * 0.18), crop=(-r * 1.0, hc - r * 0.6, r * 2.0, r * 2.0))
    if which == 'mouth':
        return canvas(base + glow(0, hc + r * 0.55, r * 0.42, r * 0.28), crop=(-r * 1.0, hc - r * 0.3, r * 2.0, r * 2.0))
    if which == 'hands':
        up = mika_open(((150, 10), (150, 10)), expr='happy')
        return canvas(up, crop=(-r * 2.1, hc - r * 2.5, r * 4.2, r * 3.4))
    if which == 'feet':
        return canvas(base + glow(-tw * 0.3, -lw * 0.2, lw * 0.95, lw * 0.6) + glow(tw * 0.3, -lw * 0.2, lw * 0.95, lw * 0.6),
                      crop=(-tw * 0.95, -tw * 1.15, tw * 1.9, tw * 1.4))
    if which == 'tummy':
        return canvas(base + glow(0, sh + body * 0.27, tw * 0.46, body * 0.15), crop=(-tw * 1.15, sh - body * 0.12, tw * 2.3, tw * 2.0))


def face_card(expr, props_back=(), props_front=(), arms=((8, 0), (8, 0)), hat=False, scarf=False):
    sp = MIKA
    H, r, hc = sp['H'], sp['hr'], -sp['H'] + sp['hr']
    parts = posed(sp, expr=expr, arms=arms, props_back=props_back)
    add = nose(r, hc)
    if hat:
        add += [P('M %s %s C %s %s, %s %s, %s %s Z' % (f(-r * 1.0), f(hc - r * 0.45), f(-r * 0.9), f(hc - r * 1.5), f(r * 0.9), f(hc - r * 1.5),
                                                       f(r * 1.0), f(hc - r * 0.45)), '#E5484D'),
                RR(-r * 1.08, hc - r * 0.62, r * 2.16, r * 0.34, r * 0.14, CREAM), E(0, hc - r * 1.42, r * 0.22, r * 0.22, CREAM)]
    if scarf:
        add += [RR(-r * 0.9, hc + r * 0.86, r * 1.8, r * 0.36, r * 0.16, '#2F7FE0'), RR(r * 0.2, hc + r * 1.0, r * 0.36, r * 1.0, r * 0.14, '#2F7FE0')]
    parts = parts[:-1] + add + list(props_front) + [parts[-1]]
    return canvas(parts, crop=(-r * 2.3, hc - r * 1.7, r * 4.6, r * 4.6))


def thumb_up(x, y, sp):
    aw = ch.geometry(sp)[8]
    skin = ch.SKIN[sp['skin']]
    return [RR(x - aw * 0.7, y - aw * 0.5, aw * 1.4, aw * 1.2, aw * 0.4, skin), RR(x - aw * 0.25, y - aw * 1.5, aw * 0.5, aw * 1.2, aw * 0.25, skin)]


def mika_faces():
    sp = MIKA
    H, r, hc, body, sh, hip, tw, lw, aw, arm = ch.geometry(sp)
    out = {'mika-happy': face_card('laugh'), 'mika-sad': face_card('frown')}
    tx, ty = tw / 2 + aw * 1.2, sh - aw * 0.4
    out['mika-fine'] = face_card('smile', arms=((8, 0), (40, 140)), props_front=thumb_up(tx - 6, ty + 6, sp))
    flakes = [L(''.join('M %d %d L %.1f %.1f ' % (x, y, x + 6 * math.cos(k * math.pi / 3), y + 6 * math.sin(k * math.pi / 3)) for k in range(6)), '#5BB8E0', 2.5)
              for x, y in ((-50, -150), (50, -160), (-56, -96), (58, -100))]
    out['mika-cold'] = face_card('shiver', hat=True, scarf=True, props_front=flakes + [L('M -44 -118 q -6 6 0 12 q 6 6 0 12 M 44 -118 q 6 6 0 12 q -6 6 0 12', '#B8B0D0', 3)])
    sun = ['<g transform="translate(-64 -170) scale(0.16)">%s</g>' % prefixed(__import__('make_language_pictures_b2').sun().parts, 'sun')]
    drop = [P('M %s %s C %s %s, %s %s, %s %s C %s %s, %s %s, %s %s Z' % (f(r * 0.62), f(hc - r * 0.5), f(r * 0.52), f(hc - r * 0.3), f(r * 0.5), f(hc - r * 0.18),
                                                                    f(r * 0.62), f(hc - r * 0.14), f(r * 0.74), f(hc - r * 0.18), f(r * 0.72), f(hc - r * 0.3),
                                                                    f(r * 0.62), f(hc - r * 0.5)), '#8FD3F4', 2)]
    fan = motion(r * 1.5, hc + r * 0.2, 8)
    out['mika-hot'] = face_card('smile', arms=((8, 0), (150, 40)), props_back=sun, props_front=drop + fan)
    sandwich = [P('M -16 -96 L 22 -96 L 22 -86 L -16 -86 Z', '#F2D3A0', 2.5), P('M -18 -86 L 24 -86 L 24 -82 L -18 -82 Z', '#5DB85A', 2),
                P('M -16 -82 L 22 -82 L 22 -72 L -16 -72 Z', '#F2D3A0', 2.5)]
    seat = hip + (-hip) * 0.5
    eat = posed(sp, view='side', arms=((40, 90), (52, 96)), legs=((90, -90), (90, -90)), lift=-(-hip) * 0.5 + lw * 0.1, expr='smile',
                props_back=side_chair(18, seat - lw * 0.1 + 2))
    eat = eat[:-2] + ['<g transform="translate(%s %s)">%s</g>' % (f(-r * 0.95 - 3), f(hc + r * 0.62 + 84), ''.join(sandwich))] + eat[-2:]
    out['mika-eat'] = canvas(eat, crop=mika_crop())
    return out


# ---- mouth shapes for the Russian sound hints (A-19, A-20) -----------------------------------------------------------

def mouth_card(kind):
    skin = ch.SKIN[MIKA['skin']]
    out = ['<path d="M 8 0 L 248 0 L 248 140 C 248 214, 196 252, 128 252 C 60 252, 8 214, 8 140 Z" fill="%s" stroke="%s" stroke-width="5"/>' % (skin, INK),
           '<ellipse cx="54" cy="96" rx="26" ry="15" fill="%s" opacity="0.6"/><ellipse cx="202" cy="96" rx="26" ry="15" fill="%s" opacity="0.6"/>' % (ch.CHEEK, ch.CHEEK),
           '<path d="M 104 52 C 104 30, 152 30, 152 52 C 152 62, 104 62, 104 52 Z" fill="%s" stroke="%s" stroke-width="3.5"/>' % (m.mix(skin, INK, 0.12), INK),
           '<ellipse cx="118" cy="40" rx="5" ry="3" fill="%s" opacity="0.5"/>' % WHITE]
    lip = '#B35A5A'
    if kind == 'lips':      # m: lips pressed together, a little puffed
        out.append('<path d="M 70 150 Q 128 164 186 150 Q 128 176 70 150 Z" fill="%s" stroke="%s" stroke-width="5"/>' % (lip, INK))
        out.append('<path d="M 70 150 Q 128 160 186 150" fill="none" stroke="%s" stroke-width="5"/>' % INK)
    elif kind == 'teeth':   # s: a smile with the teeth together
        out.append('<path d="M 64 140 Q 128 128 192 140 Q 180 184 128 186 Q 76 184 64 140 Z" fill="%s" stroke="%s" stroke-width="5"/>' % (ch.MOUTH, INK))
        out.append('<path d="M 74 142 Q 128 132 182 142 L 178 160 Q 128 168 78 160 Z" fill="%s" stroke="%s" stroke-width="3"/>' % (WHITE, INK))
        out.append('<path d="M 80 160 Q 128 168 176 160 L 172 174 Q 128 180 84 174 Z" fill="%s" stroke="%s" stroke-width="3"/>' % (WHITE, INK))
    elif kind == 'round':   # sh: lips rounded and pushed forward
        out.append('<ellipse cx="128" cy="160" rx="40" ry="34" fill="%s" stroke="%s" stroke-width="5"/>' % (lip, INK))
        out.append('<ellipse cx="128" cy="160" rx="20" ry="16" fill="%s"/>' % ch.MOUTH)
        out.append('<path d="M 118 152 L 138 152" stroke="%s" stroke-width="4"/>' % WHITE)
    elif kind == 'tongue':  # n: mouth a little open, the tongue tip up behind the top teeth
        out.append('<path d="M 76 140 Q 128 130 180 140 Q 172 198 128 200 Q 84 198 76 140 Z" fill="%s" stroke="%s" stroke-width="5"/>' % (ch.MOUTH, INK))
        out.append('<path d="M 86 142 Q 128 134 170 142 L 166 154 Q 128 160 90 154 Z" fill="%s"/>' % WHITE)
        out.append('<path d="M 96 196 C 96 170, 112 156, 128 156 C 144 156, 160 170, 160 196 Z" fill="#F28AA0" stroke="%s" stroke-width="3"/>' % INK)
    elif kind == 'trill':   # r: the tongue tip trilling, with little lines of movement
        out.append('<path d="M 72 136 Q 128 126 184 136 Q 176 204 128 206 Q 80 204 72 136 Z" fill="%s" stroke="%s" stroke-width="5"/>' % (ch.MOUTH, INK))
        out.append('<path d="M 82 138 Q 128 130 174 138 L 170 150 Q 128 156 86 150 Z" fill="%s"/>' % WHITE)
        out.append('<path d="M 100 200 C 100 176, 116 164, 124 160 L 132 160 C 140 164, 156 176, 156 200 Z" fill="#F28AA0" stroke="%s" stroke-width="3"/>' % INK)
        out.append('<path d="M 112 160 L 104 150 M 128 156 L 128 146 M 144 160 L 152 150" stroke="%s" stroke-width="4"/>' % '#F28AA0')
        out += ['<path d="M %d 170 q -10 8 0 16 M %d 170 q 10 8 0 16" fill="none" stroke="#B8B0D0" stroke-width="5"/>' % (x0, x1) for x0, x1 in ((50, 206),)]
    elif kind == 'smile':   # soft sounds: a wide smile
        out.append('<path d="M 46 132 Q 128 126 210 132 Q 196 186 128 190 Q 60 186 46 132 Z" fill="%s" stroke="%s" stroke-width="5"/>' % (ch.MOUTH, INK))
        out.append('<path d="M 60 136 Q 128 130 196 136 L 190 152 Q 128 160 66 152 Z" fill="%s" stroke="%s" stroke-width="3"/>' % (WHITE, INK))
        out.append('<path d="M 60 120 Q 46 128 44 140 M 196 120 Q 210 128 212 140" fill="none" stroke="%s" stroke-width="4"/>' % INK)
    elif kind == 'puzzled':  # y: lips spread, a little open, the friend puzzled (one brow up)
        out.append('<path d="M 70 150 Q 128 138 186 152 Q 176 178 128 178 Q 80 176 70 150 Z" fill="%s" stroke="%s" stroke-width="5"/>' % (ch.MOUTH, INK))
        out.append('<path d="M 82 152 Q 128 144 174 154 L 170 160 Q 128 158 86 158 Z" fill="%s"/>' % WHITE)
        out += ['<circle cx="%d" cy="%d" r="%d" fill="%s" stroke="%s" stroke-width="4"/>' % (x, y, rr, WHITE, INK)
                for x, y, rr in ((206, 40, 8), (226, 22, 11))]
    return canvas(out, clip=True)


MOUTHS = (('lips', 'mouth-lips'), ('teeth', 'mouth-teeth'), ('round', 'mouth-round'), ('tongue', 'mouth-tongue'), ('trill', 'mouth-trill'),
          ('smile', 'mouth-smile'), ('puzzled', 'mouth-puzzled'))


def part_c():
    out = {'mika-body': mika_body()}
    for w in ('head', 'eyes', 'ears', 'nose', 'mouth', 'hands', 'feet', 'tummy'):
        out['body-' + w] = close_up(w)
    out.update(mika_faces())
    for kind, name in MOUTHS:
        out[name] = mouth_card(kind)
    import json
    with open(os.path.join(OUT, 'mika-body.hotspots.json'), 'w', encoding='utf-8', newline='\n') as fh:
        json.dump(hotspots(), fh, ensure_ascii=False, indent=1)
        fh.write('\n')
    return out


PARTS = {'batch3a': part_a, 'batch3b': part_b, 'batch3c': part_c}


def main():
    os.makedirs(OUT, exist_ok=True)
    for tag, make in PARTS.items():
        pics = make()
        for name, text in pics.items():
            assert len(text.encode('utf-8')) < 40000, (name, len(text))
            with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
                fh.write(text)
        print(tag, 'wrote', len(pics))
        if '--sheet' in sys.argv:
            out = os.path.join(ROOT, 'docs', 'design', 'languages', 'pictures_%s.png' % tag)
            m.sheet(list(pics), out)
            print('sheet', os.path.relpath(out, ROOT))


if __name__ == '__main__':
    main()
