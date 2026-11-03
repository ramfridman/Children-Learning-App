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


PARTS = {'batch3a': part_a}


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
