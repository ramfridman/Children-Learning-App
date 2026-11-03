"""Batch 2 of the shared Languages pictures (docs/languages/pictures.md section 5): the drawings, in parts of about 40.
Run tools/make_language_pictures.py, which imports this module, writes every SVG and (with --sheet) one contact sheet
per part: docs/design/languages/pictures_batch2a.png, ...

Same house style and rules as batch 1 (see the docstring of make_language_pictures.py). Each picture is drawn so it
cannot be taken for its nearest neighbour at 64 px (the owner's ball-and-balloon rule): the wolf is grey with a long
muzzle and a hanging tail, the fox orange with black socks and a white tail tip, the lynx tawny and spotted with ear
tufts and a stub tail, the tomcat a striped grey cat; the rooster has a tall comb and an arched dark tail, the hen is
brown with a short tail; the orange shows a cut half, the tomato a green star on top, the apple a stem and leaf; soup is a
blue bowl of broth with steam, porridge a white bowl of thick oats with butter and an upright wooden spoon, rice a white
dome of grains in a coral bowl; shoes are low with laces, boots reach the knee; the big balloon is round, the small one
oval.

References looked at on 2026-11-03 (facts and photographs; the look is ours):
  Part a (Russian animals, food, clothes, toys):
    Lynx: Wikimedia Commons search "Eurasian lynx" (tawny coat with dark spots, black ear tufts, a facial ruff, long legs,
      big paws, a short black-tipped tail).
    Fox: Commons "red fox standing" (orange coat, white throat and chest, black lower legs and ear backs, a big bushy
      tail with a white tip, a slim pointed muzzle).
    Wolf: Commons "grey wolf standing" (grey with a pale face, throat and belly, long legs, upright pointed ears, a long
      muzzle, a bushy tail carried low).
    Hedgehog: Commons "European hedgehog" (a dome of brown spines with pale tips, a pointed pale face, a black nose,
      small ears, short legs).
    Squirrel: https://en.wikipedia.org/wiki/Red_squirrel (red-brown back, creamy-white belly, ear tufts, a long bushy
      tail, sits upright).
    Rooster and hen: https://en.wikipedia.org/wiki/Chicken (the male's comb and wattles are larger; the hen's comb is
      smaller) and its photograph of a cock and a hen side by side.
    Spinning top: Commons "spinning top toy humming" (the classic metal humming top: a wide striped body, a point below,
      a plunger handle with a knob on top).
    Ring stacker (pirámidka), goat, bear, giraffe, whale, beetle, foods, clothes, pencil, manhole: what they look like in
      any Russian or Israeli home, market, park or street; the giraffe after the Wikipedia facts used for the host
      (tools/make_languages_art.py), drawn with real proportions so it is not the chibi host.
"""
import math

import make_language_pictures as m
from make_language_pictures import INK, WHITE, CREAM, Pic, ell, rrect, facing

PINKY = '#F7B6C6'


def bumpy(cx, cy, rx, ry, n, amp, a0=0.0):
    """A scalloped ellipse (fur, wool, a pompom, a bush)."""
    pts = []
    for k in range(n + 1):
        a = a0 + 2 * math.pi * k / n
        pts.append((cx + rx * math.cos(a), cy + ry * math.sin(a)))
    d = 'M %.1f %.1f' % pts[0]
    for k in range(n):
        a = a0 + 2 * math.pi * (k + 0.5) / n
        qx, qy = cx + rx * (1 + amp) * math.cos(a), cy + ry * (1 + amp) * math.sin(a)
        d += ' Q %.1f %.1f %.1f %.1f' % (qx, qy, pts[k + 1][0], pts[k + 1][1])
    return d + ' Z'


def spiky(cx, cy, rx, ry, n, amp, a0=0.0):
    """A star-edged ellipse (the hedgehog's spines)."""
    d = ''
    for k in range(2 * n):
        a = a0 + math.pi * k / n
        r = 1 + (amp if k % 2 else 0)
        d += ('M' if k == 0 else ' L') + ' %.1f %.1f' % (cx + rx * r * math.cos(a), cy + ry * r * math.sin(a))
    return d + ' Z'


def legs(p, xs, top, h, w, fill, hoof=None, r=7):
    for x in xs:
        p.path(rrect(x, top, w, h, r), fill)
        if hoof:
            p.path(rrect(x, top + h - 12, w, 12, 4), hoof, 3)


# ---- part a: Russian animals ---------------------------------------------------------------------------------------

def cat_tomcat():
    return m.cat('#A6A4B8', '#84829A', tabby='#66637C')


def dog_shaggy():
    c, s = '#D9CBB0', '#B9A98C'
    p = Pic()
    p.shadow(cx=140, rx=92)
    p.shaded(bumpy(216, 106, 20, 28, 9, 0.22, 0.3), c, s, k=5)
    legs(p, (108, 188), 150, 78, 18, s)
    cid = p.shaded(bumpy(152, 150, 70, 40, 18, 0.1), c, s)
    for x in (88, 168):
        p.path(rrect(x, 158, 22, 70, 9), c)
        p.path(bumpy(x + 11, 222, 14, 7, 8, 0.25), c, 3)
    p.shaded(bumpy(80, 102, 42, 40, 16, 0.1), c, s)
    p.path('M 18 116 C 18 102, 34 100, 50 102 C 68 104, 76 114, 74 126 C 72 138, 58 142, 42 140 C 28 138, 18 128, 18 116 Z',
           '#EFE5D2')
    p.path(ell(28, 110, 9, 7), INK, 0)
    p.path('M 44 130 Q 44 146 52 146 Q 60 144 58 130 Z', '#FF8FA3', 3)
    p.line('M 32 126 Q 44 134 62 128', INK, 3)
    p.eye(64, 98, 6)
    p.path('M 44 92 Q 52 76 62 90 Q 70 72 80 88 Q 90 72 100 88 Q 108 78 114 92 C 112 72, 96 58, 76 60 C 58 62, 44 76, 44 92 Z',
           s, 3)
    p.path('M 100 74 C 124 68, 134 100, 124 132 C 118 142, 104 136, 104 122 C 100 104, 94 88, 100 74 Z', s)
    p.line('M 108 96 L 112 120 M 116 92 L 120 116', '#9C8C70', 3)
    p.hl('M 120 118 Q 150 108 190 116')
    return facing(p)


def rooster():
    p = Pic()
    p.shadow(cx=130, rx=70)
    p.path('M 148 136 C 160 70, 222 40, 240 88 C 226 72, 194 82, 178 134 Z', '#2E5D4B')
    p.path('M 158 146 C 192 86, 244 98, 236 150 C 222 126, 196 124, 176 152 Z', '#2B2E44')
    p.path('M 166 156 C 212 132, 240 164, 222 194 C 214 172, 194 164, 172 170 Z', '#E07B22')
    p.line('M 112 196 L 108 226 M 140 196 L 142 226', '#F2B233', 6)
    p.line('M 96 228 L 120 228 M 132 228 L 154 228 M 108 226 L 100 220 M 142 226 L 136 218', '#F2B233', 5)
    cid = p.shaded(ell(128, 160, 54, 42), '#C8452B', '#9E3320')
    p.shaded('M 112 148 C 132 132, 172 138, 178 160 C 160 182, 126 182, 112 148 Z', '#E8A13A', '#C98420', k=5)
    p.line('M 132 158 Q 150 166 170 160', '#C98420', 3)
    p.shaded('M 84 92 C 100 86, 126 102, 132 132 C 120 152, 96 152, 82 134 Z', '#F2A23C', '#D9822A', k=5)
    p.path('M 68 78 Q 68 54 80 64 Q 84 44 96 60 Q 104 44 110 66 Q 116 74 102 80 Z', '#E53935')
    p.shaded(ell(88, 94, 24, 22), '#E8742E', '#C8521C', k=5)
    p.path('M 74 108 C 66 124, 80 134, 88 116 Z', '#E53935', 3)
    p.path('M 66 90 L 46 98 L 66 104 Z', '#FFC83D', 3)
    p.eye(82, 88, 5.5)
    p.hl('M 96 140 Q 108 128 130 124', 6)
    return facing(p)


def hen():
    p = Pic()
    p.shadow(cx=132, rx=74)
    p.line('M 116 200 L 114 226 M 146 200 L 148 226', '#F2B233', 6)
    p.line('M 102 228 L 124 228 M 138 228 L 160 228', '#F2B233', 5)
    p.shaded('M 180 132 C 196 104, 220 104, 222 122 C 214 142, 200 152, 190 162 Z', '#8F5726', '#6E3F1A', k=4)
    p.shaded(ell(134, 164, 62, 44), '#B5763C', '#8F5726')
    p.shaded('M 116 156 C 136 138, 180 144, 188 166 C 168 188, 132 188, 116 156 Z', '#A06630', '#83501F', k=5)
    p.line('M 138 166 Q 156 174 176 168', '#83501F', 3)
    p.shaded('M 84 108 C 100 100, 124 116, 128 140 C 116 158, 94 156, 82 140 Z', '#B5763C', '#8F5726', k=4)
    p.path('M 74 88 Q 76 76 84 82 Q 90 74 96 86 Z', '#E53935', 3)
    p.shaded(ell(88, 106, 24, 22), '#B5763C', '#8F5726', k=5)
    p.path('M 74 120 C 70 128, 78 134, 84 124 Z', '#E53935', 3)
    p.path('M 66 102 L 48 108 L 66 114 Z', '#FFC83D', 3)
    p.eye(82, 100, 5.5)
    p.cheek(92, 116, 6, 4)
    p.hl('M 96 150 Q 110 138 134 134', 6)
    return facing(p)


def goat():
    w, s = '#FFFFFF', '#E3DFEA'
    p = Pic()
    p.shadow(cx=142, rx=88)
    p.path('M 206 108 L 222 90 L 216 114 Z', w, 3)
    legs(p, (104, 184), 150, 78, 14, s, '#5B5068')
    p.shaded('M 72 120 C 76 102, 104 98, 136 100 L 184 100 C 206 100, 216 116, 212 140 C 208 160, 196 168, 176 168 L 96 168 C 78 168, 68 146, 72 120 Z',
             w, s)
    legs(p, (88, 168), 152, 76, 16, w, '#5B5068')
    p.shaded('M 82 128 C 80 108, 72 92, 62 80 L 86 68 C 94 84, 104 98, 114 110 Z', w, s, k=5)
    p.path('M 66 60 C 68 40, 86 30, 100 38 C 86 42, 78 50, 76 64 Z', '#C9B48A', 3)
    p.shaded('M 86 72 C 88 58, 74 50, 60 54 C 46 58, 32 74, 32 88 C 32 98, 42 102, 52 98 C 66 94, 84 86, 86 72 Z', w, s, k=4)
    p.path('M 82 64 C 96 58, 110 62, 108 70 C 98 74, 88 72, 82 64 Z', w, 3)
    p.path('M 40 96 C 38 112, 44 122, 50 114 C 50 106, 50 100, 48 96 Z', '#DCD8E4', 3)
    p.path(ell(36, 86, 4, 3), PINKY, 2)
    p.eye(60, 70, 5.5)
    p.cheek(66, 84, 6, 4)
    p.hl('M 98 106 Q 120 100 150 102')
    return facing(p)


def wolf():
    c, s, pale = '#9A98AC', '#7E7B90', '#E6E3EE'
    p = Pic()
    p.shadow(cx=142, rx=92)
    p.shaded('M 204 116 C 232 128, 238 176, 222 198 C 212 182, 206 156, 194 136 Z', c, s, k=5)
    legs(p, (104, 184), 148, 80, 15, s)
    cid = p.shaded('M 76 112 C 84 96, 112 92, 144 94 L 186 96 C 210 98, 216 120, 210 142 C 204 160, 190 166, 172 166 L 100 166 C 80 166, 70 140, 76 112 Z',
                   c, s)
    p.clipped(cid, '<path d="%s" fill="%s"/>' % (ell(130, 172, 60, 18), pale))
    legs(p, (88, 168), 150, 78, 17, c)
    p.path('M 70 76 L 74 44 L 90 72 Z', c)
    p.fillp('M 75 70 L 77 54 L 85 70 Z', '#5E5B70')
    hid = p.shaded('M 98 110 C 98 82, 82 68, 64 70 L 28 92 C 20 96, 20 108, 30 110 L 64 116 C 78 128, 96 124, 98 110 Z', c, s, k=6)
    p.clipped(hid, '<path d="M 20 104 L 70 106 C 80 112, 86 122, 96 120 L 96 140 L 20 140 Z" fill="%s"/>' % pale)
    p.path('M 98 110 C 98 82, 82 68, 64 70 L 28 92 C 20 96, 20 108, 30 110 L 64 116 C 78 128, 96 124, 98 110 Z', 'none')
    p.path('M 84 74 L 94 46 L 102 80 Z', c)
    p.path(ell(25, 99, 7, 6), INK, 0)
    p.line('M 30 110 L 52 112', INK, 2.5)
    p.eye(64, 88, 5.5)
    p.hl('M 110 100 Q 140 92 180 98')
    return facing(p)


def fox():
    c, s, white, black = '#E8762B', '#C55A18', '#FFF6E8', '#2E2A3E'
    p = Pic()
    p.shadow(cx=142, rx=94)
    tid = p.shaded('M 192 132 C 228 118, 252 148, 240 178 C 230 200, 196 194, 184 170 Z', c, s, k=6)
    p.clipped(tid, '<path d="%s" fill="%s"/>' % (ell(240, 180, 22, 20), white))
    p.path('M 192 132 C 228 118, 252 148, 240 178 C 230 200, 196 194, 184 170 Z', 'none')
    for x in (108, 182):
        p.path(rrect(x, 150, 14, 78, 6), s)
        p.path(rrect(x, 196, 14, 32, 6), black, 3)
    cid = p.shaded(ell(148, 142, 62, 30), c, s)
    p.clipped(cid, '<path d="%s" fill="%s"/>' % (ell(100, 158, 22, 20), white))
    for x in (92, 166):
        p.path(rrect(x, 150, 16, 78, 7), c)
        p.path(rrect(x, 192, 16, 36, 7), black, 3)
    p.path('M 70 88 L 70 54 L 90 82 Z', c)
    p.fillp('M 72 68 L 71 56 L 80 70 Z', black)
    hid = p.shaded('M 104 116 C 104 92, 86 80, 70 84 L 30 108 C 24 112, 26 120, 34 120 L 70 126 C 88 136, 104 130, 104 116 Z', c, s, k=6)
    p.clipped(hid, '<path d="M 24 116 L 72 118 C 84 124, 92 132, 104 128 L 104 150 L 24 150 Z" fill="%s"/>' % white)
    p.path('M 104 116 C 104 92, 86 80, 70 84 L 30 108 C 24 112, 26 120, 34 120 L 70 126 C 88 136, 104 130, 104 116 Z', 'none')
    p.path('M 86 84 L 94 52 L 106 88 Z', c)
    p.fillp('M 90 70 L 94 56 L 100 74 Z', black)
    p.path(ell(28, 112, 6, 5), INK, 0)
    p.eye(68, 100, 5.5)
    p.hl('M 110 120 Q 140 110 180 116')
    return facing(p)


def bear():
    c, s, muz = '#8A5A34', '#6B4426', '#C49A6C'
    p = Pic()
    p.shadow(cx=142, rx=96)
    legs(p, (110, 196), 150, 78, 26, s, r=11)
    p.shaded('M 66 140 C 66 104, 96 84, 136 84 C 150 70, 176 72, 190 86 C 214 96, 226 124, 220 152 C 216 172, 200 180, 180 180 L 92 180 C 74 180, 66 162, 66 140 Z',
             c, s)
    for x in (82, 170):
        p.path(rrect(x, 156, 30, 72, 12), c)
        p.line('M %d 226 L %d 222 M %d 226 L %d 222 M %d 226 L %d 222' % (x + 6, x + 6, x + 14, x + 14, x + 22, x + 22),
               CREAM, 2.5)
    p.path('M 220 120 C 230 116, 234 126, 226 132 Z', c, 3)
    p.shaded(ell(84, 96, 13, 13), c, s, k=3)
    p.fillp(ell(84, 97, 6, 6), muz)
    p.shaded(ell(66, 126, 40, 34), c, s, k=6)
    p.shaded(ell(62, 100, 12, 12), c, s, k=3)
    p.path(ell(36, 140, 22, 16), muz)
    p.path(ell(22, 134, 8, 6), INK, 0)
    p.line('M 24 146 Q 32 152 42 148', INK, 3)
    p.eye(56, 118, 6)
    p.hl('M 120 92 Q 150 80 186 90')
    return facing(p)


def hedgehog():
    p = Pic()
    p.shadow(cx=134, rx=94, cy=232)
    p.add('<clipPath id="ground"><rect x="0" y="0" width="256" height="214"/></clipPath><g clip-path="url(#ground)">')
    p.path(spiky(146, 170, 84, 62, 26, 0.17, math.pi), '#6E5034')
    p.path(spiky(146, 172, 72, 52, 22, 0.16, math.pi + 0.1), '#9A764F', 0)
    p.add(''.join('<path d="M %.1f %.1f L %.1f %.1f" stroke="#D9BE94" stroke-width="3" stroke-linecap="round"/>'
                  % (146 + 30 * math.cos(a), 174 + 22 * math.sin(a), 146 + 62 * math.cos(a), 174 + 46 * math.sin(a))
                  for a in [math.pi * (1.05 + 0.11 * k) for k in range(9)]))
    p.add('</g>')
    p.path('M 62 214 L 230 214', INK, 4)
    face = 'M 100 168 C 86 150, 60 152, 30 182 C 26 188, 28 194, 36 194 L 92 214 C 108 214, 112 186, 100 168 Z'
    p.shaded(face, '#E8D2B0', '#CDB28A', k=5)
    p.path(ell(28, 186, 7, 6), INK, 0)
    p.eye(68, 176, 5.5)
    p.path(ell(90, 166, 8, 7), '#CDB28A', 3)
    p.cheek(72, 194, 6, 4)
    p.path(ell(110, 218, 12, 7), '#CDB28A', 3)
    p.path(ell(196, 218, 12, 7), '#CDB28A', 3)
    return facing(p)


def squirrel():
    c, s, belly = '#C8642A', '#A44E1E', '#F3E1C4'
    p = Pic()
    p.shadow(cx=140, rx=84)
    p.shaded('M 146 218 C 214 214, 238 162, 214 112 C 200 82, 214 54, 192 38 C 230 40, 252 90, 240 124 C 258 172, 226 230, 150 226 Z',
             c, s, k=7)
    p.line('M 214 70 Q 230 96 226 124', s, 4)
    bid = p.shaded('M 112 118 C 86 140, 84 198, 104 222 L 164 222 C 176 196, 168 146, 142 122 Z', c, s, k=7)
    p.clipped(bid, '<path d="M 106 132 C 90 156, 94 196, 106 222 L 132 222 C 130 190, 128 156, 124 130 Z" fill="%s"/>' % belly)
    p.path('M 112 118 C 86 140, 84 198, 104 222 L 164 222 C 176 196, 168 146, 142 122 Z', 'none')
    p.path(ell(150, 220, 30, 10), c)
    p.path(ell(98, 152, 13, 15), '#9C6B3C', 3)
    p.path('M 86 140 C 92 132, 104 132, 110 140 Z', '#6B4426', 3)
    p.path('M 84 158 C 90 150, 100 150, 106 156 L 104 166 C 96 172, 88 168, 84 158 Z', c, 3)
    p.path('M 100 76 L 104 44 L 120 72 Z', c)
    p.line('M 104 46 L 100 34 M 104 46 L 108 34', '#7A3A16', 3)
    p.shaded(ell(108, 98, 32, 27), c, s, k=5)
    p.fillp(ell(92, 108, 14, 10), belly)
    p.path(ell(78, 102, 5, 4), INK, 0)
    p.eye(98, 92, 6)
    p.cheek(106, 108, 6, 4)
    p.hl('M 196 56 Q 214 78 218 104', 6)
    return facing(p)


def giraffe():
    base, patch, mane = '#F6E3B8', '#D9893A', '#A8662A'
    p = Pic()
    p.shadow(cx=160, rx=70)
    p.line('M 206 110 C 216 130, 216 150, 212 166', INK, 3)
    p.path('M 208 162 L 218 166 L 210 180 Z', INK, 2)
    for x in (132, 200):
        p.path(rrect(x, 124, 11, 104, 5), '#E8CFA0')
    nid = p.shaded('M 112 110 L 62 40 C 60 30, 74 22, 82 30 L 140 104 Z', base, '#E8CFA0', k=5)
    p.clipped(nid, ''.join('<path d="%s" fill="%s"/>' % (ell(x, y, 9, 7), patch)
                           for x, y in ((84, 50), (98, 66), (112, 84), (124, 98), (76, 40))))
    p.path('M 112 110 L 62 40 C 60 30, 74 22, 82 30 L 140 104 Z', 'none')
    p.line('M 84 30 L 140 100', mane, 6)
    bid = p.shaded('M 116 100 C 140 90, 196 92, 208 106 C 216 120, 208 134, 192 136 L 128 136 C 112 134, 106 108, 116 100 Z',
                   base, '#E8CFA0', k=6)
    p.clipped(bid, ''.join('<path d="%s" fill="%s"/>' % (ell(x, y, 11, 9), patch)
                           for x, y in ((132, 108), (154, 104), (176, 106), (196, 114), (144, 126), (166, 124), (188, 128))))
    p.path('M 116 100 C 140 90, 196 92, 208 106 C 216 120, 208 134, 192 136 L 128 136 C 112 134, 106 108, 116 100 Z', 'none')
    for x in (120, 188):
        p.path(rrect(x, 126, 12, 102, 5), base)
        p.path(rrect(x, 218, 12, 10, 3), '#6B4426', 2.5)
    for x in (132, 200):
        p.path(rrect(x, 218, 11, 10, 3), '#6B4426', 2.5)
    p.line('M 66 22 L 64 10 M 76 20 L 78 8', '#A8662A', 4)
    p.path(ell(64, 9, 4, 4), '#5A3E26', 2)
    p.path(ell(78, 7, 4, 4), '#5A3E26', 2)
    p.shaded('M 82 26 C 78 14, 58 12, 50 20 C 38 30, 30 40, 34 48 C 40 54, 56 50, 68 44 C 80 40, 86 34, 82 26 Z',
             base, '#E8CFA0', k=4)
    p.path('M 84 20 C 92 14, 100 16, 98 22 C 92 26, 88 24, 84 20 Z', base, 3)
    p.fillp(ell(40, 44, 9, 6), '#E8CFA0')
    p.path(ell(36, 42, 2, 2), INK, 0)
    p.eye(58, 28, 4.5)
    return facing(p)


def whale():
    c, s, belly = '#3C7FC9', '#2A5F9E', '#BFE0F5'
    p = Pic()
    for d in ('M 84 84 C 74 60, 60 50, 48 52', 'M 90 82 C 92 56, 98 44, 108 40', 'M 87 82 C 84 60, 84 44, 86 30'):
        p.line(d, '#8FD3F4', 6)
    p.add(''.join('<circle cx="%d" cy="%d" r="5" fill="#8FD3F4"/>' % xy for xy in ((46, 52), (110, 38), (86, 28))))
    body = ('M 24 152 C 24 110, 70 88, 128 90 C 170 92, 196 112, 210 138 L 238 112 C 244 128, 240 150, 232 158 '
            'C 238 170, 238 190, 234 200 L 206 170 C 186 192, 150 202, 110 200 C 60 198, 24 186, 24 152 Z')
    cid = p.shaded(body, c, s, k=10)
    p.clipped(cid, '<path d="M 20 160 C 60 196, 150 200, 206 168 L 206 210 L 20 210 Z" fill="%s"/>' % belly
              + ''.join('<path d="M %d 176 Q %d 186 %d 194" fill="none" stroke="#8FBFE0" stroke-width="3"/>' % (x, x + 6, x + 4)
                        for x in (56, 80, 104, 128, 152)))
    p.path(body, 'none')
    p.path('M 100 168 C 110 186, 132 194, 140 184 C 132 174, 116 168, 100 168 Z', s, 3)
    p.line('M 30 158 Q 60 170 92 162', INK, 3)
    p.eye(60, 140, 6)
    p.cheek(74, 156, 7, 4)
    p.fillp('M 8 212 Q 128 198 248 212 L 248 240 Q 128 250 8 240 Z', '#8FD3F4')
    p.line('M 8 212 Q 70 204 128 212 T 248 212', '#3FB6D9', 4)
    p.hl('M 54 112 Q 84 96 124 96', 7)
    return facing(p)


def beetle():
    g, s = '#2FA36B', '#1E7A4E'
    p = Pic()
    p.shadow(cy=232, rx=70)
    for y, dx in ((110, 0), (140, 8), (172, 4)):
        p.line('M 96 %d L %d %d L %d %d' % (y, 58 - dx, y - 12, 50 - dx, y + 14), INK, 6)
        p.line('M 160 %d L %d %d L %d %d' % (y, 198 + dx, y - 12, 206 + dx, y + 14), INK, 6)
    p.line('M 118 50 C 110 34, 96 26, 84 28 M 138 50 C 146 34, 160 26, 172 28', INK, 4)
    p.shaded(ell(128, 58, 20, 16), '#2E3A40', '#1E262A', k=3)
    p.shaded(ell(128, 86, 36, 22), g, s, k=5)
    el = 'M 88 104 C 88 94, 168 94, 168 104 C 174 160, 158 208, 128 216 C 98 208, 82 160, 88 104 Z'
    p.shaded(el, g, s, k=9)
    p.line('M 128 100 L 128 214', INK, 3)
    p.hl('M 104 120 Q 100 150 108 184', 7)
    p.hl('M 112 80 Q 122 74 136 74', 4)
    return p


def lynx():
    c, s, spot = '#C9A06A', '#A8804E', '#7A5A36'
    p = Pic()
    p.shadow(cx=142, rx=92)
    p.path('M 206 112 L 226 100 L 232 118 L 210 126 Z', c)
    p.fillp('M 222 102 L 226 100 L 232 118 L 226 120 Z', INK)
    legs(p, (106, 184), 148, 76, 18, s)
    for x in (106, 184):
        p.path(ell(x + 9, 224, 14, 7), s, 3)
    cid = p.shaded('M 80 116 C 88 100, 116 96, 146 98 L 184 100 C 206 102, 214 120, 208 142 C 202 162, 188 166, 170 166 L 100 166 C 82 166, 74 140, 80 116 Z',
                   c, s)
    p.clipped(cid, ''.join('<circle cx="%d" cy="%d" r="5" fill="%s"/>' % (x, y, spot)
                           for x, y in ((112, 112), (136, 108), (160, 110), (184, 114), (124, 132), (150, 130), (176, 134),
                                        (198, 130), (140, 150), (166, 152))))
    p.path('M 80 116 C 88 100, 116 96, 146 98 L 184 100 C 206 102, 214 120, 208 142 C 202 162, 188 166, 170 166 L 100 166 C 82 166, 74 140, 80 116 Z', 'none')
    for x in (88, 166):
        p.path(rrect(x, 150, 20, 72, 8), c)
        p.path(ell(x + 10, 224, 15, 7), c, 3)
    p.path('M 58 78 L 62 46 L 78 72 Z', c)
    p.line('M 62 46 L 60 30', INK, 4)
    p.path('M 80 74 L 92 44 L 98 78 Z', c)
    p.line('M 92 44 L 94 28', INK, 4)
    p.path('M 46 106 L 38 134 L 54 126 L 60 144 L 72 128 L 86 140 L 92 116 Z', '#F3E6CF', 3)
    p.shaded(ell(74, 102, 36, 32), c, s, k=5)
    p.fillp(ell(54, 114, 16, 12), '#F3E6CF')
    p.path('M 40 106 L 50 106 L 45 112 Z', '#E0939E', 2.5)
    p.line('M 45 112 Q 45 118 38 119 M 45 112 Q 46 118 52 119', INK, 2.5)
    p.line('M 36 114 L 14 110 M 36 118 L 16 124', INK, 2, op=0.7)
    p.eye(60, 96, 6)
    p.line('M 72 82 L 76 90 M 82 82 L 84 90', spot, 3)
    p.hl('M 116 104 Q 146 96 184 104')
    return facing(p)


# ---- part a: food and drink ----------------------------------------------------------------------------------------

def orange():
    o, s = '#FF9A1F', '#E07A10'
    p = Pic()
    p.shadow(cx=140, rx=96)
    cid = p.shaded(ell(104, 128, 74, 74), o, s, k=12)
    p.clipped(cid, ''.join('<circle cx="%d" cy="%d" r="2.2" fill="#FFC067"/>' % (x, y)
                           for x in range(48, 178, 16) for y in range(70, 200, 16) if (x // 16 + y // 16) % 2))
    p.path(ell(104, 128, 74, 74), 'none')
    p.outlined_line('M 104 56 L 106 44', '#7A4A24', 5)
    p.shaded('M 108 46 C 120 26, 150 26, 158 38 C 142 54, 120 56, 108 46 Z', '#4CAF50', '#2F8A3E', k=4)
    p.path(ell(184, 186, 50, 46), o)
    p.path(ell(184, 186, 42, 38), '#FFE7B8', 0)
    p.fillp(ell(184, 186, 36, 32), '#FFB347')
    p.line(''.join('M 184 186 L %.1f %.1f ' % (184 + 36 * math.cos(a), 186 + 32 * math.sin(a))
                   for a in [k * math.pi / 4 for k in range(8)]), '#FFE7B8', 3)
    p.path(ell(184, 186, 5, 5), '#FFE7B8', 0)
    p.hl('M 54 110 Q 60 82 84 66', 9)
    return p


def pear():
    p = Pic()
    p.shadow(rx=72)
    body = ('M 128 50 C 144 50, 150 72, 152 92 C 156 112, 200 130, 196 180 C 192 220, 152 232, 128 232 '
            'C 104 232, 64 220, 60 180 C 56 130, 100 112, 104 92 C 106 72, 112 50, 128 50 Z')
    cid = p.shaded(body, '#C6D84A', '#9DB236', k=12)
    p.clipped(cid, ''.join('<circle cx="%d" cy="%d" r="2" fill="#8A9A2E" opacity="0.7"/>' % xy
                           for xy in ((100, 160), (132, 140), (150, 190), (116, 204), (170, 168), (90, 190))))
    p.path(body, 'none')
    p.outlined_line('M 128 52 Q 128 36 138 26', '#7A4A24', 5)
    p.shaded('M 134 40 C 146 22, 174 22, 182 32 C 168 46, 146 50, 134 40 Z', '#4CAF50', '#2F8A3E', k=4)
    p.hl('M 80 168 Q 80 140 100 124', 8)
    return p


def grapes():
    g, s = '#7E4FB8', '#5E3590'
    p = Pic()
    p.shadow(rx=60)
    p.outlined_line('M 128 66 Q 126 46 138 34', '#7A4A24', 6)
    p.shaded('M 132 50 C 150 22, 196 24, 210 44 C 196 50, 192 64, 176 66 C 162 70, 142 64, 132 50 Z', '#5DB85A', '#3E8E41', k=5)
    p.line('M 140 52 Q 170 44 200 44', '#3E8E41', 2.5)
    rows = ((76, (92, 120, 148, 176)), (104, (78, 106, 134, 162)), (132, (92, 120, 148)), (160, (98, 126, 154)),
            (188, (112, 140)), (214, (126,)))
    for y, xs in rows:
        for x in xs:
            p.shaded(ell(x + 6, y, 16, 16), g, s, k=4)
            p.add('<circle cx="%d" cy="%d" r="3.5" fill="%s" opacity="0.55"/>' % (x, y - 6, WHITE))
    return p


def watermelon():
    p = Pic()
    p.shadow(cx=140, rx=104)
    wid = p.shaded(ell(104, 120, 86, 66), '#3E9E46', '#2A6E31', k=10)
    p.clipped(wid, ''.join('<path d="M %d 50 C %d 90, %d 150, %d 190" fill="none" stroke="#2A6E31" stroke-width="9"/>'
                           % (x, x - 10, x + 10, x - 4) for x in (52, 84, 116, 148, 180)))
    p.path(ell(104, 120, 86, 66), 'none')
    p.path('M 92 158 A 76 70 0 0 0 244 158 Z', '#3E9E46')
    p.fillp('M 100 158 A 68 62 0 0 0 236 158 Z', '#F4F0D8')
    sid = p.shaded('M 106 158 A 62 56 0 0 0 230 158 Z', '#F2545B', '#D63A43', k=5, sw=0)
    p.clipped(sid, ''.join('<ellipse cx="%d" cy="%d" rx="3" ry="5" fill="%s"/>' % (x, y, '#2B2540')
                        for x, y in ((130, 172), (154, 184), (180, 188), (206, 180), (168, 168), (142, 196), (196, 202))))
    p.line('M 92 158 L 244 158', INK, 4)
    p.hl('M 46 96 Q 56 74 80 62', 8)
    return p


def tomato():
    p = Pic()
    p.shadow(rx=84)
    body = 'M 128 74 C 172 70, 214 100, 212 148 C 210 196, 172 222, 128 222 C 84 222, 46 196, 44 148 C 42 100, 84 70, 128 74 Z'
    p.shaded(body, '#E8402E', '#B92B20', k=13)
    p.line('M 100 82 Q 92 110 96 130 M 156 82 Q 164 110 160 130', '#B92B20', 3, op=0.6)
    star = ''.join(('M' if k == 0 else 'L') + ' %.1f %.1f ' % (128 + (42 if k % 2 == 0 else 12) * math.cos(-math.pi / 2 + k * math.pi / 5),
                                                             82 + (20 if k % 2 == 0 else 7) * math.sin(-math.pi / 2 + k * math.pi / 5))
                   for k in range(10)) + 'Z'
    p.path(star, '#4CAF50', 3)
    p.outlined_line('M 128 78 L 130 56', '#4CAF50', 6)
    p.hl('M 70 128 Q 76 100 98 88', 9)
    return p


def potato():
    c, s = '#C99A5B', '#A47A40'
    p = Pic()
    p.shadow(cx=134, rx=104)
    b = 'M 136 124 C 148 92, 204 90, 226 118 C 244 144, 230 182, 200 188 C 170 194, 140 176, 136 152 Z'
    bid = p.shaded(b, c, s, k=7)
    a = 'M 36 172 C 30 134, 76 108, 122 114 C 168 120, 194 148, 186 182 C 180 212, 138 224, 94 218 C 54 212, 40 198, 36 172 Z'
    aid = p.shaded(a, c, s, k=10)
    for cid, pts in ((bid, ((190, 120), (212, 150), (176, 160))), (aid, ((80, 150), (124, 140), (150, 182), (100, 196), (60, 182)))):
        p.clipped(cid, ''.join('<path d="M %d %d q 5 -4 10 0" fill="none" stroke="#7A5A2E" stroke-width="3" stroke-linecap="round"/>'
                               % xy for xy in pts))
    p.hl('M 56 156 Q 66 132 92 124', 7)
    return p


def bowl_body(p, f, s, band=None):
    body = 'M 30 120 C 32 182, 82 216, 128 216 C 174 216, 224 182, 226 120 Z'
    p.path(ell(128, 214, 40, 8), s)
    cid = p.shaded(body, f, s, k=10)
    if band:
        p.clipped(cid, band)
    p.path(body, 'none')


def porridge():
    p = Pic()
    p.shadow(rx=90)
    p.outlined_line('M 150 120 L 178 22', '#C98F52', 9)
    bowl_body(p, WHITE, '#E2DEEC', '<path d="M 36 150 C 80 172, 176 172, 220 150" fill="none" stroke="#2F7FE0" stroke-width="7"/>'
              + ''.join('<circle cx="%d" cy="%d" r="5" fill="#2F7FE0"/>' % (x, 178 if 60 < x < 196 else 168)
                        for x in (70, 100, 128, 156, 186)))
    p.path(ell(128, 120, 98, 26), WHITE)
    p.fillp(ell(128, 122, 86, 20), '#F2DDB0')
    p.add(''.join('<ellipse cx="%d" cy="%d" rx="7" ry="4" fill="#E2C690"/>' % xy
                  for xy in ((78, 120), (100, 130), (170, 116), (190, 126), (140, 132), (60, 126))))
    p.path('M 104 112 L 130 108 L 136 122 L 110 126 Z', '#FFE27A', 3)
    p.fillp('M 108 126 C 112 132, 126 132, 132 124 Z', '#FFE27A')
    p.outlined_line('M 150 120 L 154 106', '#C98F52', 9)
    p.hl('M 44 140 Q 56 172 84 192', 7)
    return p


def rice():
    p = Pic()
    p.shadow(rx=84)
    dome = 'M 50 144 C 50 94, 92 66, 128 66 C 164 66, 206 94, 206 144 Z'
    did = p.shaded(dome, WHITE, '#E9E5F1', k=8)
    p.clipped(did, ''.join('<ellipse cx="%d" cy="%d" rx="5" ry="2.5" fill="#DCD5E8" '
                           'transform="rotate(%d %d %d)"/>' % (x, y, (x * 37 + y * 53) % 180, x, y)
                           for x in range(62, 200, 15) for y in range(78, 144, 12) if (x + y) % 2 == 0))
    p.path(dome, 'none')
    body = 'M 40 140 C 42 192, 88 216, 128 216 C 168 216, 214 192, 216 140 Z'
    p.path(ell(128, 214, 36, 7), '#C8473C')
    cid = p.shaded(body, '#F46A5E', '#C8473C', k=9)
    p.clipped(cid, '<path d="M 44 160 C 80 178, 176 178, 212 160" fill="none" stroke="%s" stroke-width="6" opacity="0.8"/>' % CREAM)
    p.path(body, 'none')
    p.hl('M 74 112 Q 84 86 108 76', 6)
    return p


def onion():
    p = Pic()
    p.shadow(rx=78)
    p.line('M 116 214 L 110 230 M 124 216 L 122 232 M 132 216 L 134 232 M 140 214 L 146 230', '#E8D9B8', 4)
    body = ('M 128 50 C 136 72, 150 86, 172 104 C 204 130, 206 186, 174 210 C 156 222, 100 222, 82 210 '
            'C 50 186, 52 130, 84 104 C 106 86, 120 72, 128 50 Z')
    cid = p.shaded(body, '#D99A4B', '#B47830', k=11)
    p.clipped(cid, ''.join('<path d="M 128 56 C %d 110, %d 170, 128 218" fill="none" stroke="#B47830" stroke-width="3" opacity="0.7"/>'
                           % (128 + dx, 128 + dx * 1.3) for dx in (-60, -32, 32, 60)))
    p.path(body, 'none')
    p.outlined_line('M 128 54 C 124 38, 130 26, 142 20', '#B47830', 5)
    p.hl('M 76 150 Q 80 122 100 106', 8)
    return p


def cup_and_saucer(p, drink, top):
    p.path(ell(128, 208, 98, 18), WHITE)
    p.fillp(ell(128, 206, 60, 9), '#EDE6F7')
    p.line('M 186 124 C 230 120, 232 176, 176 172', INK, 18)
    p.line('M 186 124 C 230 120, 232 176, 176 172', WHITE, 10)
    body = 'M 50 110 L 196 110 C 194 172, 166 202, 123 202 C 80 202, 52 172, 50 110 Z'
    cid = p.shaded(body, WHITE, '#E2DEEC', k=9)
    p.clipped(cid, '<path d="M 50 126 L 196 126" stroke="#2F7FE0" stroke-width="7"/>')
    p.path(body, 'none')
    p.path(ell(123, 110, 73, 13), WHITE)
    p.fillp(ell(123, 112, 64, 9), drink)
    p.fillp(ell(110, 110, 26, 4), top)
    return cid


def tea():
    p = Pic()
    p.shadow(cy=222, rx=96)
    for x in (98, 126, 154):
        p.line('M %d 92 C %d 82, %d 74, %d 64 C %d 54, %d 46, %d 36' % (x, x - 8, x + 8, x, x - 8, x + 8, x),
               '#B8B0D0', 5, op=0.75)
    cup_and_saucer(p, '#B5651D', '#D08A42')
    p.line('M 84 108 C 76 120, 70 132, 66 144', INK, 2)
    p.path(rrect(54, 142, 22, 18, 3), '#FFC83D', 2.5)
    p.hl('M 64 140 Q 72 176 98 192', 6)
    return p


def cup_cold():
    p = Pic()
    p.shadow(cy=222, rx=96)
    cid = cup_and_saucer(p, '#8FD3F4', '#BFE6F7')
    for x, y, a in ((92, 92, -14), (122, 86, 10), (150, 94, -6)):
        p.add('<rect x="%d" y="%d" width="26" height="24" rx="5" fill="#E9F8FF" stroke="%s" stroke-width="3" '
              'transform="rotate(%d %d %d)"/>' % (x, y, INK, a, x + 13, y + 12))
    p.clipped(cid, ''.join('<path d="M %d %d l 0 -10 M %d %d l 0 10 M %d %d l -10 0 M %d %d l 10 0" stroke="#8FD3F4" '
                           'stroke-width="3" stroke-linecap="round"/>' % ((x, y) * 4) for x, y in ((80, 160), (150, 172), (118, 148))))
    sx, sy = 214, 52
    p.line(''.join('M %d %d L %.1f %.1f ' % (sx, sy, sx + 20 * math.cos(k * math.pi / 3), sy + 20 * math.sin(k * math.pi / 3))
                   for k in range(6)), '#5BB8E0', 5)
    p.hl('M 64 140 Q 72 176 98 192', 6)
    return p


def carrot():
    p = Pic()
    p.shadow(cx=140, rx=84)
    for d in ('M 74 76 C 56 56, 44 30, 50 18 C 66 30, 76 52, 82 72 Z', 'M 82 72 C 80 44, 86 20, 100 14 C 104 34, 98 58, 90 76 Z',
              'M 70 82 C 48 76, 26 58, 22 44 C 40 46, 60 62, 72 76 Z'):
        p.shaded(d, '#5DB85A', '#3E8E41', k=4)
    body = 'M 70 72 C 90 62, 112 68, 120 82 L 218 214 C 220 222, 212 226, 206 222 L 66 112 C 54 98, 56 80, 70 72 Z'
    cid = p.shaded(body, '#FF8A2E', '#E06A10', k=8)
    p.clipped(cid, ''.join('<path d="M %d %d l 16 -6" stroke="#E06A10" stroke-width="3" stroke-linecap="round"/>' % xy
                           for xy in ((96, 108), (124, 138), (150, 160), (176, 184), (110, 90))))
    p.path(body, 'none')
    p.hl('M 78 88 Q 96 82 110 92', 6)
    return p


def strawberry():
    p = Pic()
    p.shadow(rx=92)
    berry = 'M 0 -40 C 32 -44, 50 -10, 32 22 C 20 44, 6 56, 0 58 C -6 56, -20 44, -32 22 C -50 -10, -32 -44, 0 -40 Z'
    for tx, ty, a, sc in ((96, 128, -14, 1.15), (170, 156, 12, 1.0)):
        p.add('<g transform="translate(%d %d) rotate(%d) scale(%s)">' % (tx, ty, a, sc))
        p.shaded(berry, '#E53935', '#B8282A', k=7)
        p.add(''.join('<ellipse cx="%d" cy="%d" rx="2.2" ry="3.4" fill="#FFE27A"/>' % xy
                      for xy in ((-16, -14), (4, -18), (20, -6), (-24, 6), (-4, 2), (14, 14), (-12, 22), (6, 30), (-2, 44))))
        p.path('M 0 -40 L -24 -48 L -10 -36 L -18 -58 L 0 -42 L 18 -58 L 10 -36 L 24 -48 Z', '#4CAF50', 3)
        p.outlined_line('M 0 -46 L 2 -62', '#4CAF50', 4)
        p.add('</g>')
    p.hl('M 70 116 Q 72 96 86 86', 6)
    return p


def cookie():
    p = Pic()
    p.shadow(rx=90)
    edge = bumpy(128, 128, 90, 88, 22, 0.035)
    cid = p.shaded(edge, '#E2A85C', '#C1863A', k=10)
    chips = ((92, 86), (150, 76), (186, 120), (112, 132), (160, 156), (80, 170), (128, 192), (60, 120))
    p.clipped(cid, ''.join('<path d="M %d %d l 9 -5 l 7 7 l -4 9 l -10 0 Z" fill="#5A3A22" stroke="#3E2616" stroke-width="2"/>' % xy
                           for xy in chips)
              + ''.join('<circle cx="%d" cy="%d" r="2.2" fill="#F3C98A"/>' % xy
                        for xy in ((70, 100), (130, 106), (176, 96), (100, 160), (190, 168), (146, 216), (140, 136))))
    p.path(edge, 'none')
    p.add(''.join('<circle cx="%d" cy="%d" r="%s" fill="#C1863A"/>' % xy for xy in ((218, 216, 4), (230, 206, 3), (34, 222, 3))))
    return p


# ---- part a: clothes -----------------------------------------------------------------------------------------------

def dress():
    f, s = '#B58AF0', '#9466D8'
    p = Pic()
    p.shadow(cy=232, rx=86)
    d = ('M 100 38 C 110 50, 146 50, 156 38 L 178 48 L 200 82 L 178 96 L 166 86 L 164 118 L 208 214 '
         'C 168 230, 88 230, 48 214 L 92 118 L 90 86 L 78 96 L 56 82 L 78 48 Z')
    cid = p.shaded(d, f, s, k=10)
    p.clipped(cid, '<path d="M 40 110 L 216 110 L 216 128 L 40 128 Z" fill="#E04F9E"/>'
                   '<path d="M 50 204 C 90 218, 166 218, 206 204" fill="none" stroke="%s" stroke-width="5" opacity="0.8"/>' % CREAM)
    p.path(d, 'none')
    p.path('M 100 38 C 108 58, 124 60, 128 52 C 132 60, 148 58, 156 38 C 146 50, 110 50, 100 38 Z', CREAM, 3)
    p.path('M 128 118 L 112 132 L 116 112 Z M 128 118 L 144 132 L 140 112 Z', '#E04F9E', 3)
    p.hl('M 100 134 Q 88 170 76 204', 7)
    return p


def jacket():
    f, s = '#F28C28', '#D06E12'
    p = Pic()
    p.shadow(cy=232, rx=90)
    p.path('M 96 52 C 92 20, 164 20, 160 52 C 150 66, 106 66, 96 52 Z', s)
    d = ('M 62 66 C 82 54, 98 50, 108 48 L 148 48 C 158 50, 174 54, 194 66 L 224 154 L 196 164 L 184 128 '
         'L 184 222 L 72 222 L 72 128 L 60 164 L 32 154 Z')
    cid = p.shaded(d, f, s, k=10)
    p.clipped(cid, '<rect x="20" y="206" width="216" height="20" fill="%s"/>' % s
              + '<path d="M 26 140 L 60 152 L 56 166 L 22 154 Z M 230 140 L 196 152 L 200 166 L 234 154 Z" fill="%s"/>' % s)
    p.path(d, 'none')
    p.line('M 128 50 L 128 222', INK, 4)
    p.line(''.join('M 124 %d L 132 %d ' % (y, y) for y in range(62, 214, 12)), '#C9CFDD', 2.5)
    p.path(rrect(122, 54, 12, 16, 3), '#C9CFDD', 2.5)
    p.line('M 86 170 L 110 162 M 170 170 L 146 162', INK, 3.5)
    p.hl('M 90 80 L 90 196', 7)
    return p


def trousers():
    f, s = '#3B6FD8', '#2A55B0'
    p = Pic()
    p.shadow(cy=232, rx=84)
    d = 'M 72 40 L 184 40 L 198 222 L 146 222 L 130 104 L 126 104 L 110 222 L 58 222 Z'
    cid = p.shaded(d, f, s, k=8)
    p.clipped(cid, '<rect x="60" y="36" width="140" height="18" fill="%s"/>' % s
              + '<path d="M 56 210 L 112 210 M 144 210 L 200 210" stroke="%s" stroke-width="4"/>' % CREAM)
    p.path(d, 'none')
    p.line('M 92 40 L 92 54 M 128 40 L 128 54 M 164 40 L 164 54', INK, 3)
    p.line('M 80 62 Q 96 78 106 62 M 176 62 Q 160 78 150 62', INK, 3)
    p.line('M 128 54 L 128 100', INK, 3)
    p.hl('M 80 70 L 72 200', 7)
    return p


SOCK = ('M 96 30 L 150 30 L 150 140 C 150 150, 154 156, 160 160 L 200 186 C 220 198, 214 228, 188 226 '
        'L 140 220 C 112 216, 96 196, 96 170 Z')


def draw_sock(p, transform=''):
    p.add('<g transform="%s">' % transform)
    cid = p.shaded(SOCK, WHITE, '#E2DEEC', k=7)
    p.clipped(cid, ''.join('<rect x="80" y="%d" width="90" height="12" fill="#E5484D"/>' % y for y in (62, 90, 118))
              + '<path d="%s" fill="#E5484D"/>' % ell(196, 206, 26, 22)
              + '<path d="%s" fill="#E5484D"/>' % ell(118, 208, 26, 22)
              + '<rect x="90" y="26" width="70" height="20" fill="#E5484D"/>'
              + ''.join('<path d="M %d 28 L %d 46" stroke="#B92B2B" stroke-width="3"/>' % (x, x) for x in range(104, 150, 9)))
    p.path(SOCK, 'none')
    p.add('</g>')


def sock():
    p = Pic()
    p.shadow(cy=234, rx=70)
    draw_sock(p)
    p.hl('M 106 60 L 106 168', 6)
    return p


def socks():
    p = Pic()
    p.shadow(cy=234, rx=96)
    draw_sock(p, 'translate(-34 14) scale(0.9)')
    draw_sock(p, 'translate(52 4) scale(0.9)')
    return p


SHOE = ('M 40 204 L 40 120 C 40 108, 52 100, 64 100 L 104 100 C 112 100, 118 106, 120 114 L 128 150 '
        'C 160 156, 200 164, 214 182 C 222 192, 220 204, 210 204 Z')


def draw_shoe(p, transform, f, s):
    p.add('<g transform="%s">' % transform)
    p.path(rrect(34, 198, 186, 14, 6), '#4A3A30')
    p.shaded(SHOE, f, s, k=7)
    p.line('M 130 152 C 150 158, 160 174, 160 194', s, 3)
    p.line('M 96 112 L 120 128 M 96 128 L 122 142 M 98 144 L 126 156 M 120 112 L 98 128 M 122 128 L 100 142', CREAM, 4)
    p.add(''.join('<circle cx="%d" cy="%d" r="2.5" fill="%s"/>' % xy for xy in ((96, 112, INK), (96, 128, INK), (98, 144, INK))))
    p.line('M 40 180 L 214 186', s, 3, op=0.6)
    p.add('</g>')


def shoes():
    p = Pic()
    p.shadow(cy=226, rx=110)
    draw_shoe(p, 'translate(24 -24) scale(0.92)', '#7E5430', '#5E3C20')
    draw_shoe(p, 'translate(-12 6)', '#9C6B3C', '#7A4E28')
    return p


BOOT = 'M 70 26 L 140 26 L 142 146 C 174 152, 206 164, 216 186 C 222 198, 216 208, 206 208 L 64 208 L 64 36 Z'


def draw_boot(p, transform, f, s):
    p.add('<g transform="%s">' % transform)
    p.path(rrect(58, 202, 166, 14, 6), '#3A3550')
    cid = p.shaded(BOOT, f, s, k=8)
    p.clipped(cid, '<rect x="60" y="20" width="90" height="22" fill="%s"/>' % s)
    p.path(BOOT, 'none')
    p.line('M 142 150 C 160 156, 170 176, 168 196', s, 3)
    p.add('</g>')


def boots():
    p = Pic()
    p.shadow(cy=230, rx=108)
    draw_boot(p, 'translate(30 -8) scale(0.92)', '#2F8F5A', '#1E6E42')
    draw_boot(p, 'translate(-14 10) scale(0.96)', '#36A86A', '#237A4A')
    return p


MITTEN = ('M -30 40 L -30 -22 C -30 -58, 30 -58, 30 -22 L 30 40 Z')
THUMB = 'M -30 4 C -48 -2, -56 -24, -46 -34 C -38 -40, -28 -30, -28 -20 Z'


def mittens():
    f, s = '#8A5CF0', '#6C40D0'
    p = Pic()
    p.shadow(cy=232, rx=96)
    p.line('M 84 200 C 100 238, 160 238, 176 204', '#B9A2F7', 4)
    for tx, ty, a, flip in ((84, 120, -10, 1), (172, 128, 10, -1)):
        p.add('<g transform="translate(%d %d) rotate(%d) scale(%d 1)">' % (tx, ty, a, flip))
        p.shaded(THUMB, f, s, k=3)
        cid = p.shaded(MITTEN, f, s, k=7)
        p.clipped(cid, '<rect x="-40" y="-6" width="80" height="12" fill="%s"/>' % CREAM)
        p.path(MITTEN, 'none')
        p.path(rrect(-34, 40, 68, 28, 8), CREAM)
        p.line(''.join('M %d 44 L %d 64 ' % (x, x) for x in range(-26, 30, 8)), '#D8CBE8', 3)
        p.add('</g>')
    return p


# ---- part a: toys and a street thing -------------------------------------------------------------------------------

def balloon_big():
    p = Pic()
    p.line('M 128 214 C 112 226, 144 236, 124 252', INK, 3)
    p.line('M 128 214 C 112 226, 144 236, 124 252', '#FFC83D', 1.5)
    p.shaded(ell(128, 108, 102, 102), '#FF8A3D', '#D9692A', k=16)
    p.path('M 118 218 L 128 206 L 138 218 Z', '#FF8A3D')
    p.hl('M 62 70 Q 74 40 104 26', 11)
    p.add('<circle cx="58" cy="96" r="5.5" fill="%s" opacity="0.55"/>' % WHITE)
    return p


def pencil():
    p = Pic()
    p.shadow(cy=234, rx=80)
    p.add('<g transform="rotate(45 128 128)">')
    p.path('M 110 44 L 146 44 L 128 2 Z', '#F2D7A6')
    p.path('M 121 18 L 135 18 L 128 2 Z', '#3A3550', 0)
    cid = p.shaded(rrect(110, 44, 36, 140, 3), '#FFC83D', '#E0A21A', k=5)
    p.clipped(cid, '<path d="M 122 44 L 122 184 M 134 44 L 134 184" stroke="#E0A21A" stroke-width="3"/>')
    p.path(rrect(110, 44, 36, 140, 3), 'none')
    p.path(rrect(108, 182, 40, 18, 3), '#C9CFDD')
    p.line('M 108 188 L 148 188 M 108 194 L 148 194', '#9AA0B4', 2.5)
    p.path('M 108 198 L 148 198 L 148 214 C 148 226, 108 226, 108 214 Z', '#F48FB1')
    p.add('</g>')
    return p


def top():
    p = Pic()
    p.shadow(cy=232, rx=60)
    p.line('M 30 150 Q 22 128 32 104 M 226 150 Q 234 128 224 104', '#B8B0D0', 4)
    p.path(rrect(120, 34, 16, 78, 6), '#C9CFDD')
    p.path(ell(128, 30, 14, 14), '#E53935')
    body = 'M 40 120 C 40 96, 216 96, 216 120 C 216 152, 162 196, 128 222 C 94 196, 40 152, 40 120 Z'
    cid = p.shaded(body, '#FFC83D', '#E0A21A', k=10)
    bands = (('#E53935', 122, 136), ('#2F7FE0', 148, 160), ('#E53935', 172, 182))
    p.clipped(cid, ''.join('<rect x="30" y="%d" width="200" height="%d" fill="%s"/>' % (y0, y1 - y0, col) for col, y0, y1 in bands))
    p.path(body, 'none')
    p.path(ell(128, 112, 86, 20), '#FFE08A')
    p.path(ell(128, 112, 20, 6), '#9AA0B4', 3)
    p.path('M 122 220 L 134 220 L 128 234 Z', '#9AA0B4', 3)
    p.hl('M 60 122 Q 72 150 100 178', 7)
    return p


def stacker():
    p = Pic()
    p.shadow(cy=232, rx=86)
    p.path(rrect(122, 56, 12, 150, 5), '#E8C590')
    rings = (('#E53935', '#B8282A', 64, 190), ('#FF8A3D', '#D9692A', 56, 164), ('#FFC83D', '#E0A21A', 48, 140),
             ('#36A852', '#237A3A', 40, 116), ('#2F7FE0', '#1F5FB0', 32, 94))
    p.shaded(rrect(50, 200, 156, 24, 10), '#C98F52', '#A8743C', k=4)
    for f, s, rx, cy in rings:
        p.shaded(ell(128, cy, rx, 14), f, s, k=4)
    p.shaded(ell(128, 66, 22, 20), '#8A5CF0', '#6C40D0', k=4)
    p.hl('M 116 56 Q 120 50 128 48', 4)
    p.hl('M 76 186 Q 92 178 110 178', 5)
    return p


def manhole():
    p = Pic()
    ground = ell(128, 140, 120, 84)
    gid = p.shaded(ground, '#D8D3E2', '#C3BDD0', k=6, sw=0)
    p.clipped(gid, ''.join('<path d="M %d 40 L %d 240" stroke="#BDB6CC" stroke-width="3"/>' % (x, x - 20) for x in range(20, 280, 40))
              + ''.join('<path d="M 0 %d L 256 %d" stroke="#BDB6CC" stroke-width="3"/>' % (y, y + 4) for y in range(70, 230, 34)))
    cover = ell(128, 136, 88, 60)
    cid = p.shaded(cover, '#76728A', '#5A566E', k=6)
    p.clipped(cid, ''.join('<path d="M %d 60 L %d 220" stroke="#9A96AC" stroke-width="4"/>' % (x, x + 60) for x in range(-20, 260, 22))
              + ''.join('<path d="M %d 60 L %d 220" stroke="#9A96AC" stroke-width="4"/>' % (x, x - 60) for x in range(0, 300, 22)))
    p.path(ell(128, 136, 72, 48), 'none', 4, stroke='#5A566E')
    p.path(cover, 'none')
    p.path(ell(98, 120, 6, 4), '#3A3550', 0)
    p.path(ell(158, 152, 6, 4), '#3A3550', 0)
    return p


PART_A = {
    'cat-tomcat': cat_tomcat, 'dog-shaggy': dog_shaggy, 'rooster': rooster, 'hen': hen, 'goat': goat, 'wolf': wolf,
    'fox': fox, 'bear': bear, 'hedgehog': hedgehog, 'squirrel': squirrel, 'giraffe': giraffe, 'whale': whale,
    'beetle': beetle, 'lynx': lynx,
    'orange': orange, 'pear': pear, 'grapes': grapes, 'watermelon': watermelon, 'tomato': tomato, 'potato': potato,
    'porridge': porridge, 'rice': rice, 'onion': onion, 'tea': tea, 'cup-cold': cup_cold, 'carrot': carrot,
    'strawberry': strawberry, 'cookie': cookie,
    'dress': dress, 'jacket': jacket, 'trousers': trousers, 'socks': socks, 'sock': sock, 'shoes': shoes, 'boots': boots,
    'mittens': mittens,
    'balloon-big': balloon_big, 'pencil': pencil, 'top': top, 'stacker': stacker, 'manhole': manhole,
}

PARTS = {'batch2a': PART_A}
