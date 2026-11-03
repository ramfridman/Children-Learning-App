"""Draws the shared pictures of the three Languages courses (English, Hebrew, Russian), batch 1: the 40 single objects
used by the most items across the courses (docs/languages/pictures.md, section 3).

    python tools/make_language_pictures.py            # writes the SVGs
    python tools/make_language_pictures.py --sheet    # also renders the contact sheet with headless Chrome

Writes (deterministic): content/languages/pictures/<id>.svg, 256 x 256, one picture per real object, reused by every course
that names it (a cat is a cat in all three languages). Colour sets (ball, balloon, boat) are one drawing, recoloured, so
the pictures of a "same set" differ only in the colour taught. The contact sheet is docs/design/languages/pictures_batch1.png
(each picture at 200 and at 64 pixels, the smallest size an option is shown at).

The style is the house style of docs/art/art-brief.md section 3 (the hosts in tools/make_languages_art.py are the model):
flat shapes, the ink outline #2B2350, one soft shade tone per shape (drawn as the shape shifted toward the light, clipped
to itself), one white highlight at 55 percent, dot eyes with a white spark and pink cheeks on the animals, a soft ground
shadow. Animals stand in side view facing left (the reading direction of the Hebrew page; one flag, FACE_LEFT, mirrors
them all if the teachers ask for the other side). SVG 1.1 subset only (paths, circles, ellipses, rects, groups,
transforms, simple clipPath); no text, no filter, no mask.

Our own drawings in plain shapes: nothing traced or copied, no brand, no franchise look, no letter or numeral inside a
picture (the toy blocks carry shapes, the book cover a little landscape).

References looked at on 2026-11-03 (facts and photographs; the look is ours):
  Cow: https://en.wikipedia.org/wiki/Holstein_Friesian (black-and-white pied coat, horned or dehorned) and the Wikimedia
    Commons search "Holstein cow" (photographs of cows standing side-on in grass: white body with black patches, pink
    muzzle and udder, short pale horns, ears sideways, tail with a dark tuft).
  Rabbit and hare: https://en.wikipedia.org/wiki/European_rabbit (greyish-brown fur, white underparts and tail underside,
    long hind feet, long black whiskers; a hare has longer legs and black ear tips). One sitting rabbit serves Hebrew
    arnav and Russian zayats (see pictures.md for the teachers' check).
  Bird: https://en.wikipedia.org/wiki/House_sparrow (grey crown, chestnut nape, pale cheek, black bib, warm brown back
    with dark streaks, short tail, stout conical bill). Drawn as a small brown songbird, so it never looks like Pip.
  Cheese: https://en.wikipedia.org/wiki/Emmental_cheese (a yellow cheese whose holes are its defining feature).
  Teddy bear: Wikimedia Commons search "teddy bear toy" (honey-brown plush, lighter muzzle and inner ears, round ears,
    stitched nose, often a ribbon at the neck).
  Toy drum: Wikimedia Commons search "toy drum" (a short cylinder with a light skin, bright rims, a zigzag of coloured
    triangles round the shell, two sticks with round heads).
  Toy blocks: Wikimedia Commons search "toy blocks" (bright cubes, an inset panel on each face; ours carry shapes, never
    letters or numerals).
  Pig: Wikimedia Commons search "domestic pig" (pink, a flat round snout with two nostrils, ears that flop forward, a
    curly tail, short legs).
  Duck: Wikimedia Commons search "Pekin duck" (white body, orange bill, upturned tail, sits low on water). The counting
    duckling is a yellow downy duckling with a flat duck bill, so it is never confused with the Hebrew chick (efroach).
  Mouse: Wikimedia Commons search "house mouse" (grey-brown, large round ears, pointed pink nose, long thin tail).
  Horse: Wikimedia Commons search "horse standing side" (bay horse: brown body, dark mane, tail and lower legs, a long
    head, upright ears).
  Elephant: Wikimedia Commons search "african elephant side" (grey, a big ear on the side of the head, the trunk hanging
    to the ground, pillar legs, a thin tail with a tuft, small tusks).
  Play ball (redrawn 2026-11-03 for the owner: it looked like a balloon without a string): Wikimedia Commons searches
    "playground ball" and "rubber ball toy" (matte red rubber balls on grass, a pebbled "stipple" finish, a small
    self-sealing valve) and retailer descriptions of rubber playground balls (laminated rubber cover, stipple finish,
    self-sealing valve; e.g. https://www.marchants.com/rubber-playground-ball-8-1-2/). Ours: matte, a two-tone band with
    seams, faint pebbles, a valve, sitting on the ground with a contact shadow, perfectly round.
  Everyday things (apple, balloon, banana, boat, bowl, bread, cake, car, cat, cucumber, dog, doll, egg, fish,
    glass of juice, milk and water, hats, kite, oven, scarf, shirt, soup, spoon) are drawn from what they look like in
    any Israeli or Russian kitchen, toy box or park; colours checked against the brief of each course.
"""
import math
import os
import subprocess
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
OUT = os.path.join(ROOT, 'content', 'languages', 'pictures')
SHEET = os.path.join(ROOT, 'docs', 'design', 'languages', 'pictures_batch1.png')
BALLS = os.path.join(ROOT, 'docs', 'design', 'languages', 'ball_vs_balloon.png')
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'

INK = '#2B2350'
WHITE = '#FFFFFF'
CREAM = '#FFF6E8'
PINK = '#FF9DB0'
FACE_LEFT = True

# Pure, named hues for the colour sets (the same in every course). Blue is a medium-dark blue: Russian sinij is never
# light blue (light blue is goluboj, another colour word).
HUES = {
    'red': ('#E53935', '#B8282A'), 'blue': ('#2459C6', '#183F92'), 'yellow': ('#FFD23F', '#E0A21A'),
    'green': ('#36A852', '#237A3A'), 'white': ('#FFFFFF', '#E2DEEC'), 'black': ('#3A3650', '#22202F'),
}


class Pic:
    """One picture: a list of elements and a counter for its clip ids."""

    def __init__(self):
        self.parts = []
        self.n = 0

    def add(self, s):
        self.parts.append(s)
        return self

    def svg(self):
        return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">%s</svg>\n'
                % ''.join(self.parts))

    # -- shapes --------------------------------------------------------------------------------------------------
    def path(self, d, fill, sw=4, stroke=INK, op=None):
        o = ' opacity="%s"' % op if op is not None else ''
        st = (' stroke="%s" stroke-width="%s" stroke-linejoin="round" stroke-linecap="round"' % (stroke, sw)
              if sw else '')
        return self.add('<path d="%s" fill="%s"%s%s/>' % (d, fill, st, o))

    def fillp(self, d, fill, op=None):
        return self.path(d, fill, sw=0, op=op)

    def line(self, d, color=INK, w=4, op=None):
        o = ' opacity="%s"' % op if op is not None else ''
        return self.add('<path d="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round" '
                        'stroke-linejoin="round"%s/>' % (d, color, w, o))

    def outlined_line(self, d, color, w):
        """A thick stroke with an ink edge (a tail, a mast, a straw)."""
        self.line(d, INK, w + 7)
        return self.line(d, color, w)

    def hl(self, d, w=7):
        return self.line(d, WHITE, w, op=0.55)

    def shaded(self, d, fill, shade, k=11, sw=4):
        """The shape in its fill with a soft shade crescent on the side away from the light (top left)."""
        self.n += 1
        cid = 'c%d' % self.n
        self.add('<clipPath id="%s"><path d="%s"/></clipPath>' % (cid, d))
        self.fillp(d, shade)
        self.add('<g clip-path="url(#%s)"><path d="%s" fill="%s" transform="translate(%s %s)"/></g>'
                 % (cid, d, fill, -k, round(-k * 0.8, 1)))
        if sw:
            self.path(d, 'none', sw)
        return cid

    def clipped(self, cid, inner):
        return self.add('<g clip-path="url(#%s)">%s</g>' % (cid, inner))

    def eye(self, cx, cy, r=6.5):
        self.add('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>' % (cx, cy, r, round(r * 1.15, 1), INK))
        return self.add('<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % (round(cx - r * 0.35, 1), round(cy - r * 0.4, 1),
                                                                       round(r * 0.36, 1), WHITE))

    def cheek(self, cx, cy, rx=8, ry=5):
        return self.add('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" opacity="0.6"/>' % (cx, cy, rx, ry, PINK))

    def shadow(self, cx=128, cy=238, rx=84, ry=8):
        return self.add('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" opacity="0.12"/>' % (cx, cy, rx, ry, INK))


def ell(cx, cy, rx, ry):
    """An ellipse as a path, so it can be shaded and clipped like any shape."""
    return ('M %s %s A %s %s 0 1 0 %s %s A %s %s 0 1 0 %s %s Z'
            % (cx - rx, cy, rx, ry, cx + rx, cy, rx, ry, cx - rx, cy))


def rrect(x, y, w, h, r):
    return ('M %s %s L %s %s Q %s %s %s %s L %s %s Q %s %s %s %s L %s %s Q %s %s %s %s L %s %s Q %s %s %s %s Z'
            % (x + r, y, x + w - r, y, x + w, y, x + w, y + r, x + w, y + h - r, x + w, y + h, x + w - r, y + h,
               x + r, y + h, x, y + h, x, y + h - r, x, y + r, x, y, x + r, y))


def facing(p):
    """Side-view animals are drawn facing left; FACE_LEFT=False mirrors them."""
    if not FACE_LEFT:
        p.parts = ['<g transform="translate(256 0) scale(-1 1)">'] + p.parts + ['</g>']
    return p


# ---- animals -------------------------------------------------------------------------------------------------------

def cat():
    c, s = '#F2A25C', '#D97E36'
    p = Pic()
    p.shadow(cx=140, rx=88)
    p.outlined_line('M 200 222 C 238 222, 246 184, 222 164', c, 15)
    body = 'M 96 120 C 74 150, 70 206, 92 226 L 200 226 C 228 222, 230 176, 210 150 C 190 122, 140 108, 96 120 Z'
    cid = p.shaded(body, c, s)
    p.clipped(cid, '<path d="M 98 132 C 84 162, 88 198, 100 226 L 124 226 C 120 190, 118 156, 114 128 Z" fill="%s"/>'
              % CREAM)
    p.shaded(ell(182, 192, 36, 31), c, s)
    p.path(rrect(96, 166, 20, 62, 9), c)
    p.path(rrect(120, 168, 20, 60, 9), c)
    p.line('M 102 222 L 102 228 M 108 222 L 108 228 M 126 222 L 126 228 M 132 222 L 132 228', INK, 2.5)
    for d in ('M 60 82 L 66 28 L 104 58 Z', 'M 106 54 L 144 28 L 150 78 Z'):
        p.path(d, c)
    p.fillp('M 70 70 L 72 44 L 94 60 Z', '#F7B6C6')
    p.fillp('M 116 56 L 138 42 L 142 70 Z', '#F7B6C6')
    p.shaded(ell(104, 96, 52, 45), c, s)
    p.line('M 100 54 L 101 66 M 112 53 L 112 66 M 124 56 L 122 67', s, 5)
    p.fillp(ell(94, 114, 24, 14), CREAM)
    p.eye(80, 92, 7)
    p.eye(114, 92, 7)
    p.path('M 87 106 L 101 106 L 94 114 Z', '#F28AA0', 2.5)
    p.line('M 94 114 Q 94 121 86 122 M 94 114 Q 95 121 103 122', INK, 3)
    p.line('M 74 112 L 42 106 M 74 117 L 44 122 M 116 112 L 146 106 M 116 117 L 144 122', INK, 2, op=0.7)
    p.cheek(68, 108)
    p.cheek(124, 108)
    p.hl('M 66 74 Q 78 58 98 54')
    return facing(p)


def dog():
    c, s, ear = '#D9A066', '#B77D45', '#8C5A2E'
    p = Pic()
    p.shadow(cx=140, rx=92)
    p.outlined_line('M 208 138 C 230 128, 236 102, 224 84', c, 12)
    p.path(rrect(108, 150, 18, 78, 8), s)
    p.path(rrect(190, 150, 18, 78, 8), s)
    cid = p.shaded(ell(154, 150, 68, 38), c, s)
    p.clipped(cid, '<path d="%s" fill="%s"/>' % (ell(104, 168, 26, 22), CREAM))
    p.path(rrect(86, 156, 22, 72, 9), c)
    p.path(rrect(170, 156, 22, 72, 9), c)
    p.fillp(ell(97, 224, 13, 6), CREAM)
    p.fillp(ell(181, 224, 13, 6), CREAM)
    p.line('M 104 116 Q 118 138 112 160', INK, 16)
    p.line('M 104 116 Q 118 138 112 160', '#2F7FE0', 10)
    p.path(ell(113, 165, 7, 7), '#FFC83D', 3)
    p.shaded(ell(82, 100, 40, 38), c, s)
    p.path('M 18 112 C 18 98, 34 96, 50 98 C 68 100, 78 110, 76 124 C 74 136, 60 140, 44 138 C 28 136, 18 126, 18 112 Z',
           CREAM)
    p.path(ell(30, 106, 9, 7), INK, 0)
    p.add('<circle cx="27" cy="103" r="2.5" fill="%s"/>' % WHITE)
    p.path('M 44 128 Q 44 146 52 146 Q 60 144 58 128 Z', '#FF8FA3', 3)
    p.line('M 32 122 Q 44 132 64 124', INK, 3)
    p.eye(70, 88, 7)
    p.path('M 94 64 C 122 60, 130 96, 120 128 C 114 138, 100 132, 100 120 C 98 100, 90 82, 94 64 Z', ear)
    p.cheek(82, 112)
    p.hl('M 56 76 Q 66 62 86 60')
    return facing(p)


def fish():
    c, s, fin = '#FF9F43', '#E07B22', '#F46A5E'
    p = Pic()
    p.path('M 178 128 L 232 84 C 222 112, 222 146, 232 172 Z', fin)
    p.path('M 88 88 C 104 50, 152 56, 166 98 Z', fin)
    p.path('M 118 166 C 130 186, 156 190, 164 178 C 152 170, 136 166, 118 166 Z', fin)
    body = 'M 24 128 C 50 78, 140 72, 194 126 C 140 184, 50 178, 24 128 Z'
    cid = p.shaded(body, c, s)
    p.clipped(cid, '<path d="M 20 140 C 70 170, 150 170, 200 130 L 200 200 L 20 200 Z" fill="#FFD08A"/>')
    for x in (104, 128, 152):
        p.line('M %d 110 Q %d 122 %d 134' % (x, x + 10, x), s, 3, op=0.8)
    p.line('M 70 100 Q 84 128 70 156', s, 4)
    p.path(ell(50, 114, 11, 11), WHITE, 3)
    p.eye(48, 115, 6)
    p.line('M 26 132 Q 32 137 40 135', INK, 3)
    p.path('M 100 138 C 112 152, 132 158, 140 148 C 130 140, 114 136, 100 138 Z', fin, 3)
    for cx, cy, r in ((18, 94, 6), (28, 70, 4.5), (14, 52, 3.5)):
        p.path(ell(cx, cy, r, r), 'none', 2.5, stroke='#5BB8E0')
    p.hl('M 48 96 Q 70 82 100 80')
    return facing(p)


def cow():
    w, s, blk, pink = '#FFFFFF', '#E3DFEA', '#2E2A3E', '#F6A6B9'
    p = Pic()
    p.fillp(ell(128, 230, 112, 11), '#8CCB6B')
    p.line('M 30 230 L 26 218 M 40 230 L 42 216 M 214 230 L 210 218 M 226 230 L 230 218', '#5BA84A', 3)
    p.line('M 214 116 C 230 140, 228 168, 220 186', INK, 5)
    p.path(ell(220, 192, 7, 11), blk, 3)
    p.path(rrect(100, 150, 18, 78, 8), s)
    p.path(rrect(186, 150, 18, 78, 8), s)
    body = 'M 66 116 C 70 98, 96 92, 130 94 L 186 94 C 212 94, 222 112, 220 140 C 218 166, 204 176, 180 176 L 92 176 C 72 176, 62 156, 66 116 Z'
    cid = p.shaded(body, w, s)
    p.clipped(cid, '<path d="M 118 90 C 146 96, 156 128, 136 142 C 114 150, 98 122, 104 100 Z" fill="%s"/>'
                   '<path d="M 176 112 C 196 104, 222 118, 222 140 C 210 158, 186 152, 176 136 C 170 126, 170 118, 176 112 Z" fill="%s"/>'
                   '<path d="M 150 160 C 160 150, 178 156, 176 176 L 148 176 Z" fill="%s"/>' % (blk, blk, blk))
    p.path('M 156 174 C 154 194, 184 194, 182 174 Z', pink, 3)
    p.line('M 162 190 L 162 196 M 176 190 L 176 196', INK, 3)
    for x in (80, 166):
        p.path(rrect(x, 160, 20, 68, 8), w)
        p.path(rrect(x, 216, 20, 12, 4), blk, 3)
    for x in (100, 186):
        p.path(rrect(x, 216, 18, 12, 4), blk, 3)
    p.path('M 84 76 C 100 64, 118 70, 114 82 C 106 88, 92 86, 84 76 Z', w)
    p.fillp('M 92 77 C 100 72, 108 74, 108 80 C 102 82, 96 81, 92 77 Z', pink)
    p.path('M 66 66 C 64 50, 72 40, 80 42 C 76 50, 74 58, 76 68 Z', '#FFF0C8', 3)
    head = 'M 26 106 C 22 84, 36 64, 58 62 C 80 60, 94 74, 94 96 C 94 118, 84 134, 64 138 C 42 142, 28 128, 26 106 Z'
    hid = p.shaded(head, w, s)
    p.clipped(hid, '<path d="M 60 60 C 82 58, 96 74, 94 92 C 82 90, 70 80, 60 60 Z" fill="%s"/>' % blk)
    p.path(ell(42, 120, 24, 18), pink, 3)
    p.path(ell(34, 118, 4, 5), INK, 0)
    p.path(ell(50, 118, 4, 5), INK, 0)
    p.eye(62, 90, 6.5)
    p.cheek(70, 108)
    p.hl('M 96 104 Q 112 98 140 98')
    return facing(p)


def mouse():
    c, s = '#A9A6BC', '#86839A'
    p = Pic()
    p.shadow(cx=130, rx=88)
    p.line('M 200 206 C 238 202, 244 164, 222 152', INK, 9)
    p.line('M 200 206 C 238 202, 244 164, 222 152', '#F2A9B8', 4)
    body = 'M 30 170 C 56 140, 92 112, 140 112 C 190 112, 216 150, 208 190 C 204 210, 186 220, 160 220 L 92 220 C 64 220, 40 196, 30 170 Z'
    cid = p.shaded(body, c, s)
    p.clipped(cid, '<path d="%s" fill="#D8D5E4"/>' % ell(110, 222, 70, 24))
    p.shaded(ell(150, 100, 25, 25), c, s, k=6)
    p.fillp(ell(150, 102, 14, 14), '#F7B6C6')
    p.shaded(ell(112, 106, 31, 31), c, s, k=6)
    p.fillp(ell(112, 108, 19, 19), '#F7B6C6')
    p.path(ell(98, 220, 13, 6), '#F7B6C6', 3)
    p.path(ell(150, 220, 13, 6), '#F7B6C6', 3)
    p.path(ell(62, 206, 9, 6), '#F7B6C6', 3)
    p.eye(70, 148, 6.5)
    p.path(ell(30, 170, 7, 6), '#F28AA0', 3)
    p.line('M 40 166 L 10 156 M 40 172 L 12 178 M 44 168 L 22 146', INK, 2, op=0.7)
    p.cheek(78, 168)
    p.hl('M 120 124 Q 150 116 178 128')
    return facing(p)


def duck():
    w, s = '#FFFFFF', '#E3DFEA'
    p = Pic()
    p.fillp('M 14 196 Q 128 180 242 196 L 242 230 Q 128 242 14 230 Z', '#8FD3F4')
    neck = 'M 106 154 C 100 130, 112 110, 112 86 C 112 62, 96 50, 82 50 C 60 50, 52 68, 54 84 C 56 100, 64 118, 62 154 Z'
    p.shaded(neck, w, s, k=8)
    body = 'M 60 160 C 60 128, 96 116, 150 120 C 190 122, 214 110, 228 90 C 234 128, 222 186, 160 196 L 96 196 C 72 196, 60 182, 60 160 Z'
    p.shaded(body, w, s)
    wing = 'M 112 150 C 130 130, 182 130, 198 148 C 182 172, 140 176, 112 150 Z'
    p.shaded(wing, w, s, k=7)
    p.line('M 140 150 Q 160 158 184 150 M 132 142 Q 156 146 180 140', s, 3)
    p.path('M 58 74 C 40 72, 20 80, 18 88 C 22 96, 44 96, 62 92 Z', '#FF9F43')
    p.line('M 20 88 C 32 86, 46 86, 60 84', '#D9692A', 2.5)
    p.eye(76, 72, 6.5)
    p.cheek(84, 88)
    p.fillp('M 14 192 Q 70 184 128 192 T 242 192 L 242 230 Q 128 242 14 230 Z', '#8FD3F4')
    p.line('M 14 192 Q 70 184 128 192 T 242 192', '#3FB6D9', 4)
    p.line('M 40 214 L 70 214 M 150 220 L 186 220', WHITE, 4, op=0.8)
    p.hl('M 62 62 Q 72 52 88 54')
    return facing(p)


def duckling():
    c, s = '#FFD84D', '#F0B429'
    p = Pic()
    p.shadow(cx=134, rx=74)
    p.path('M 108 204 L 94 226 L 108 222 L 116 230 L 124 220 L 120 204 Z', '#FF9F43', 3)
    p.path('M 150 204 L 140 228 L 154 222 L 162 230 L 170 220 L 162 204 Z', '#FF9F43', 3)
    p.path('M 196 140 L 222 122 L 214 152 Z', c)
    p.shaded(ell(142, 160, 66, 52), c, s)
    p.shaded('M 126 156 C 146 136, 186 140, 196 160 C 182 182, 146 184, 126 156 Z', c, s, k=6)
    p.shaded(ell(90, 104, 42, 40), c, s)
    p.line('M 82 64 C 80 54, 88 50, 92 58 M 92 64 C 94 52, 102 52, 100 62', INK, 3)
    p.path('M 52 102 C 38 102, 28 110, 30 118 C 38 124, 54 122, 64 116 Z', '#FF9F43')
    p.eye(78, 96, 7)
    p.cheek(86, 116)
    p.hl('M 62 82 Q 72 68 92 66')
    return facing(p)


def bird():
    c, s = '#B88655', '#92653A'
    p = Pic()
    p.path('M 14 196 C 80 186, 170 190, 242 174 L 244 190 C 170 206, 80 204, 16 212 Z', '#9C6B3C')
    p.path('M 210 182 C 216 160, 238 152, 246 160 C 240 176, 222 184, 210 182 Z', '#6DBE5A', 3)
    p.path('M 44 202 C 34 186, 18 184, 10 190 C 16 204, 32 208, 44 202 Z', '#6DBE5A', 3)
    p.path('M 168 136 L 208 128 L 202 142 L 212 152 L 166 158 Z', '#6E4E32')
    p.line('M 104 182 L 98 198 M 120 184 L 118 198', '#C08A6A', 5)
    body = 'M 58 120 C 58 86, 92 70, 124 78 C 168 90, 190 130, 172 162 C 160 184, 120 190, 96 182 C 70 172, 58 148, 58 120 Z'
    cid = p.shaded(body, c, s)
    p.clipped(cid, '<path d="%s" fill="#EADFCB"/>'
                   '<path d="M 50 104 C 58 72, 100 62, 128 80 C 110 92, 84 96, 64 112 Z" fill="#8E8A9A"/>'
                   '<path d="%s" fill="#F7F1E6"/><path d="%s" fill="#3A3340"/>'
              % (ell(104, 166, 44, 24), ell(86, 116, 16, 11), ell(66, 128, 8, 9)))
    p.path(body, 'none')
    p.path('M 110 118 C 140 108, 174 128, 180 152 C 152 160, 120 150, 110 118 Z', '#8A5E36')
    p.line('M 126 132 Q 146 140 168 144', '#F3E6D0', 4)
    p.line('M 136 120 L 146 126 M 150 126 L 160 132', '#5E3F22', 3)
    p.path('M 60 102 L 36 112 L 60 120 Z', '#4A4458', 3)
    p.eye(78, 100, 6)
    p.cheek(90, 124, 6, 4)
    p.hl('M 70 84 Q 88 72 112 76')
    return facing(p)


def rabbit():
    c, s = '#B8A08A', '#95806A'
    p = Pic()
    p.shadow(cx=146, rx=84)
    p.shaded('M 112 84 C 112 40, 126 12, 138 14 C 152 18, 144 58, 130 88 Z', c, s, k=6)
    p.shaded('M 88 88 C 76 46, 82 14, 96 14 C 112 16, 114 56, 110 92 Z', c, s, k=6)
    p.fillp('M 92 80 C 86 50, 90 26, 97 26 C 105 28, 106 56, 104 82 Z', '#F2B6C2')
    body = 'M 92 132 C 70 160, 74 214, 104 226 L 192 226 C 224 222, 228 176, 206 150 C 184 124, 130 118, 92 132 Z'
    cid = p.shaded(body, c, s)
    p.clipped(cid, '<path d="M 94 140 C 82 170, 88 206, 104 226 L 128 226 C 120 196, 116 164, 112 138 Z" fill="%s"/>' % CREAM)
    p.path(ell(216, 186, 16, 15), WHITE)
    p.shaded(ell(176, 190, 36, 31), c, s)
    p.path(ell(150, 224, 38, 9), '#D8C6B4')
    p.path(ell(102, 222, 14, 8), '#D8C6B4')
    p.path(ell(124, 224, 14, 8), '#D8C6B4')
    p.shaded(ell(90, 112, 42, 35), c, s)
    p.fillp(ell(64, 124, 16, 11), CREAM)
    p.path(ell(52, 116, 6, 5), '#F28AA0', 2.5)
    p.line('M 52 121 Q 52 128 46 129 M 52 121 Q 54 128 60 129', INK, 2.5)
    p.line('M 60 122 L 30 116 M 60 126 L 32 132', INK, 2, op=0.7)
    p.eye(80, 104, 7)
    p.cheek(94, 124)
    p.hl('M 66 92 Q 78 80 98 78')
    return facing(p)


def pig():
    c, s, dark = '#F7A8B8', '#E07F96', '#B05C72'
    p = Pic()
    p.shadow(cx=138, rx=92)
    p.line('M 216 128 C 236 122, 238 104, 226 104 C 214 104, 218 120, 234 116', INK, 7)
    p.line('M 216 128 C 236 122, 238 104, 226 104 C 214 104, 218 120, 234 116', c, 3)
    p.path(rrect(104, 170, 20, 58, 8), s)
    p.path(rrect(188, 170, 20, 58, 8), s)
    p.shaded('M 60 120 C 64 90, 110 82, 150 84 C 200 86, 222 114, 220 146 C 218 178, 190 190, 150 190 L 104 190 C 70 190, 56 160, 60 120 Z',
             c, s)
    for x in (84, 168):
        p.path(rrect(x, 172, 22, 56, 8), c)
        p.path(rrect(x, 216, 22, 12, 4), dark, 3)
    for x in (104, 188):
        p.path(rrect(x, 216, 20, 12, 4), dark, 3)
    p.shaded(ell(70, 122, 42, 40), c, s)
    p.path(ell(34, 132, 17, 21), '#F48AA2')
    p.path(ell(30, 124, 3.5, 6), INK, 0)
    p.path(ell(38, 140, 3.5, 6), INK, 0)
    p.path('M 74 90 C 80 66, 98 62, 108 66 C 106 84, 96 100, 84 104 Z', c)
    p.fillp('M 82 90 C 86 76, 96 72, 102 74 C 100 86, 94 94, 86 96 Z', '#F48AA2')
    p.eye(62, 110, 6.5)
    p.line('M 52 150 Q 62 158 74 152', INK, 3)
    p.cheek(80, 138)
    p.hl('M 48 100 Q 58 86 76 84')
    return facing(p)


def horse():
    c, s, mane = '#A8683A', '#86502A', '#4A2E1E'
    p = Pic()
    p.shadow(cx=146, rx=88)
    p.path('M 206 100 C 236 114, 242 160, 228 200 C 216 172, 212 140, 198 118 Z', mane)
    p.path(rrect(102, 150, 16, 80, 7), s)
    p.path(rrect(184, 150, 16, 80, 7), s)
    p.shaded('M 84 110 C 92 94, 120 92, 150 94 L 186 94 C 212 94, 220 120, 216 142 C 212 164, 194 170, 176 170 L 104 170 C 86 170, 78 140, 84 110 Z',
             c, s)
    for x in (86, 168):
        p.path(rrect(x, 150, 18, 80, 8), c)
        p.path(rrect(x, 212, 18, 18, 5), mane, 3)
    for x in (102, 184):
        p.path(rrect(x, 212, 16, 18, 5), mane, 3)
    p.shaded('M 82 128 C 74 98, 64 74, 62 54 L 100 46 C 106 70, 114 92, 124 118 L 124 134 Z', c, s, k=7, sw=0)
    p.line('M 84 120 C 74 98, 64 74, 62 54', INK, 4)
    head = 'M 100 44 C 98 32, 86 26, 74 30 C 60 34, 40 68, 28 86 C 22 98, 28 110, 42 110 C 56 110, 68 98, 76 88 C 88 78, 102 62, 100 44 Z'
    hid = p.shaded(head, c, s, k=7)
    p.clipped(hid, '<path d="M 66 40 C 56 58, 44 76, 36 92 L 44 96 C 54 80, 64 62, 72 44 Z" fill="%s"/>'
                   '<path d="%s" fill="#7A4524"/>' % (CREAM, ell(34, 100, 14, 12)))
    p.path(head, 'none')
    p.path(ell(30, 98, 3, 4), INK, 0)
    p.path('M 84 34 L 88 12 L 98 34 Z', c, 3)
    p.path('M 100 34 C 114 60, 124 86, 126 112 C 114 106, 104 84, 90 58 C 86 48, 92 38, 100 34 Z', mane)
    p.path('M 76 30 C 84 20, 96 22, 100 30 C 92 34, 84 36, 76 30 Z', mane, 3)
    p.eye(70, 54, 6)
    p.line('M 30 106 Q 38 112 48 108', INK, 2.5)
    p.hl('M 118 102 Q 140 96 170 98')
    return facing(p)


def elephant():
    c, s = '#A8A9BC', '#8A8BA0'
    p = Pic()
    p.shadow(cx=140, rx=94)
    p.line('M 212 120 C 226 140, 224 160, 218 170', INK, 4)
    p.path('M 214 166 L 224 168 L 218 182 Z', INK, 2)
    p.path(rrect(112, 150, 28, 78, 12), s)
    p.path(rrect(190, 150, 26, 78, 12), s)
    p.shaded('M 72 120 C 76 80, 120 64, 160 66 C 206 68, 226 100, 222 140 C 218 172, 196 180, 172 180 L 104 180 C 84 180, 70 156, 72 120 Z',
             c, s)
    for x in (90, 168):
        p.path(rrect(x, 150, 30, 78, 12), c)
        p.line('M %d 226 Q %d 220 %d 226 M %d 226 Q %d 220 %d 226' % (x + 4, x + 9, x + 14, x + 15, x + 20, x + 25),
               '#E8E6F0', 3)
    p.shaded(ell(78, 102, 44, 42), c, s)
    p.shaded('M 46 108 C 34 140, 30 176, 40 202 C 46 212, 60 210, 58 198 C 52 176, 54 150, 64 128 Z', c, s, k=6)
    p.line('M 44 150 L 54 152 M 42 166 L 52 168 M 44 182 L 54 184', s, 3)
    p.path('M 52 136 C 42 150, 34 152, 26 150 C 34 144, 42 138, 46 128 Z', CREAM, 3)
    eid = p.shaded('M 94 70 C 132 56, 154 96, 144 136 C 136 162, 106 164, 94 144 C 86 120, 84 90, 94 70 Z', c, s, k=6)
    p.clipped(eid, '<path d="M 102 82 C 128 76, 142 104, 134 132 C 128 148, 110 148, 104 136 C 98 118, 96 98, 102 82 Z" '
                   'fill="#C9B8C8" opacity="0.6"/>')
    p.eye(64, 94, 6.5)
    p.cheek(72, 116)
    p.hl('M 48 82 Q 60 66 82 62')
    return facing(p)


# ---- food and drink ------------------------------------------------------------------------------------------------

def apple():
    p = Pic()
    p.shadow(rx=72)
    p.outlined_line('M 128 78 Q 130 52 142 40', '#7A4A24', 6)
    body = 'M 128 80 C 104 58, 50 66, 52 132 C 54 192, 100 230, 128 214 C 156 230, 202 192, 204 132 C 206 66, 152 58, 128 80 Z'
    p.shaded(body, '#E53935', '#B8282A', k=14)
    p.shaded('M 136 58 C 150 34, 184 34, 194 46 C 178 64, 150 68, 136 58 Z', '#4CAF50', '#2F8A3E', k=5)
    p.line('M 142 56 Q 164 48 186 46', '#2F8A3E', 2.5)
    p.hl('M 76 112 Q 80 90 98 80', 9)
    p.add('<circle cx="76" cy="128" r="4.5" fill="%s" opacity="0.55"/>' % WHITE)
    return p


def banana():
    p = Pic()
    p.shadow(cx=132, rx=80)
    body = 'M 40 92 C 50 176, 150 216, 214 166 C 222 158, 218 148, 208 152 C 150 178, 84 150, 66 88 C 62 78, 42 78, 40 92 Z'
    p.shaded(body, '#FFD84D', '#E5B52A', k=8)
    p.line('M 58 110 C 82 162, 150 190, 206 164', '#E0B02A', 4)
    p.path('M 42 86 L 36 62 L 50 58 L 60 82 Z', '#9C7A3C', 3)
    p.path(ell(214, 162, 7, 6), '#5B4320', 3)
    p.hl('M 62 104 C 74 136, 104 160, 140 172', 7)
    return p


def bread():
    crust, s = '#D99A4E', '#B06E2A'
    p = Pic()
    p.shadow(rx=96)
    body = 'M 30 176 C 26 120, 88 90, 130 90 C 186 90, 232 118, 226 176 C 222 196, 196 206, 128 206 C 60 206, 34 196, 30 176 Z'
    p.shaded(body, crust, s, k=12)
    for dx in (0, 46, 92):
        p.path('M %d 154 C %d 128, %d 112, %d 106 C %d 120, %d 138, %d 160 Z'
               % (66 + dx, 78 + dx, 96 + dx, 110 + dx, 104 + dx, 92 + dx, 76 + dx), '#F6D9A4', 3)
    p.add(''.join('<circle cx="%d" cy="%d" r="2.5" fill="%s" opacity="0.7"/>' % (x, y, CREAM)
                  for x, y in ((90, 104), (150, 98), (184, 112), (60, 124))))
    p.hl('M 50 150 Q 66 118 100 104', 8)
    return p


def egg():
    p = Pic()
    p.shadow(rx=64)
    body = 'M 128 32 C 176 32, 206 110, 204 160 C 202 202, 168 228, 128 228 C 88 228, 54 202, 52 160 C 50 110, 80 32, 128 32 Z'
    p.shaded(body, '#FFFDF7', '#E9E0CF', k=14)
    p.hl('M 84 110 Q 92 72 116 56', 9)
    return p


def cake():
    side, sside, top = '#F7A8C4', '#E07BA0', CREAM
    p = Pic()
    p.path(ell(128, 212, 108, 20), WHITE)
    p.fillp(ell(128, 210, 92, 14), '#EDE6F7')
    body = 'M 44 112 L 44 194 C 44 220, 212 220, 212 194 L 212 112 Z'
    cid = p.shaded(body, side, sside, k=12)
    p.clipped(cid, '<path d="M 40 156 C 40 176, 216 176, 216 156" fill="none" stroke="%s" stroke-width="9"/>' % top)
    p.fillp(ell(128, 112, 84, 24), top)
    p.path('M 44 112 C 44 128, 52 142, 58 134 C 64 126, 70 150, 80 146 C 88 142, 90 132, 98 138 C 106 146, 116 150, 128 142 '
           'C 140 136, 146 150, 158 146 C 168 142, 166 132, 176 136 C 186 140, 190 150, 200 140 C 206 132, 212 128, 212 112 Z',
           top, 3)
    p.line('M 44 112 A 84 24 0 0 1 212 112', INK, 4)
    for cx, cy in ((98, 106), (128, 98), (158, 106)):
        p.path('M %d %d C %d %d, %d %d, %d %d C %d %d, %d %d, %d %d Z'
               % (cx, cy + 14, cx - 14, cy + 4, cx - 10, cy - 8, cx, cy - 4, cx + 10, cy - 8, cx + 14, cy + 4, cx, cy + 14),
               '#E53935', 3)
        p.fillp('M %d %d L %d %d L %d %d L %d %d Z' % (cx - 8, cy - 6, cx, cy - 12, cx + 8, cy - 6, cx, cy - 2), '#4CAF50')
    p.hl('M 56 150 L 56 186', 7)
    return p


def glass(liquid, lshade, ltop, sw_top=0):
    """A drinking glass (cup of milk, juice, water); the liquid fills it to below the rim."""
    p = Pic()
    p.shadow(rx=64)
    g = 'M 72 66 L 184 66 L 172 222 C 170 228, 86 228, 84 222 Z'
    p.fillp(g, '#E9F6FD')
    cid = p.shaded('M 76 92 L 180 92 L 172 216 C 170 220, 86 220, 84 216 Z', liquid, lshade, k=10, sw=0)
    p.path(ell(128, 92, 52, 9), ltop, sw_top or 0)
    p.path(g, 'none')
    p.path(ell(128, 66, 56, 8), '#F4FBFF', 4)
    p.line('M 88 84 L 98 206', WHITE, 6, op=0.7)
    return p, cid


def milk():
    p = Pic()
    p.shadow(cx=118, rx=100)
    # the carton: white, a blue top band and wave, no text, no brand
    p.path(rrect(54, 46, 36, 14, 3), WHITE)
    p.path('M 36 94 L 52 58 L 92 58 L 108 94 Z', '#4D9BE6')
    cid = p.shaded('M 36 94 L 108 94 L 108 214 L 36 214 Z', WHITE, '#E2DEEC', k=8)
    p.clipped(cid, '<path d="M 30 94 L 114 94 L 114 116 Q 92 130 72 118 T 30 120 Z" fill="#4D9BE6"/>')
    p.path('M 36 94 L 108 94 L 108 214 L 36 214 Z', 'none')
    # the glass of milk in front
    g = 'M 104 94 L 206 94 L 196 222 C 194 228, 116 228, 114 222 Z'
    p.fillp(g, '#E9F6FD')
    p.shaded('M 108 114 L 202 114 L 194 216 C 192 220, 118 220, 116 216 Z', WHITE, '#E6E2EE', k=8, sw=0)
    p.path(ell(155, 114, 47, 8), WHITE, 3, stroke='#D8D3E6')
    p.path(g, 'none')
    p.path(ell(155, 94, 51, 7), '#F4FBFF', 4)
    p.line('M 118 108 L 126 204', '#CFE6F5', 6)
    return p


def juice():
    p, cid = glass('#FFA53A', '#F08A1C', '#FFC067')
    # straw (behind the rim line, in the glass) and an orange slice on the rim
    p.outlined_line('M 146 92 L 162 34 L 186 26', WHITE, 9)
    p.line('M 150 78 L 153 66 M 156 56 L 159 44 M 168 31 L 178 28', '#E53935', 9)
    p.path('M 52 70 A 30 30 0 0 1 112 70 Z', '#FFA53A')
    p.fillp('M 60 68 A 22 22 0 0 1 104 68 Z', '#FFD08A')
    p.line('M 82 68 L 82 48 M 82 68 L 66 56 M 82 68 L 98 56', '#FFA53A', 3)
    return p


def water():
    p, cid = glass('#BFE6F7', '#9DD3EE', '#DFF3FC', sw_top=0)
    p.path('M 216 90 C 204 108, 198 120, 198 130 C 198 142, 206 150, 216 150 C 226 150, 234 142, 234 130 '
           'C 234 120, 228 108, 216 90 Z', '#8FD3F4')
    p.hl('M 206 132 Q 206 122 212 114', 5)
    p.line('M 150 120 L 154 196', WHITE, 5, op=0.7)
    return p


def cheese():
    top, front, hole = '#FFE07A', '#FFC93C', '#E8A920'
    p = Pic()
    p.shadow(cx=130, rx=96)
    tp = 'M 34 150 L 204 72 L 224 104 Z'
    fr = 'M 34 150 L 224 104 L 224 164 L 34 210 Z'
    fid = p.shaded(fr, front, '#E8AE22', k=8, sw=0)
    p.clipped(fid, ''.join('<path d="%s" fill="%s"/>' % (ell(x, y, rx, ry), hole)
                           for x, y, rx, ry in ((88, 168, 13, 11), (150, 162, 9, 8), (190, 132, 12, 10), (196, 160, 7, 6),
                                                (60, 196, 8, 7), (122, 196, 11, 9))))
    tid = p.shaded(tp, top, '#F7D35A', k=5, sw=0)
    p.clipped(tid, ''.join('<path d="%s" fill="%s"/>' % (ell(x, y, rx, ry), hole)
                           for x, y, rx, ry in ((150, 104, 12, 5), (196, 94, 7, 3), (112, 126, 7, 3))))
    p.path('M 116 130 A 14 9 0 0 0 144 124 Z', hole, 0)
    p.path(fr, 'none')
    p.path(tp, 'none')
    p.line('M 224 104 L 224 164', '#D99A1E', 7)
    p.path(fr, 'none')
    p.hl('M 48 152 L 120 134', 6)
    return p


def cucumber():
    g, s = '#3E8E41', '#2A6A2E'
    p = Pic()
    p.shadow(rx=96)
    body = 'M 36 150 C 36 118, 98 74, 170 60 C 208 52, 230 72, 218 98 C 206 126, 130 172, 78 186 C 50 194, 36 176, 36 150 Z'
    cid = p.shaded(body, g, s, k=8)
    p.clipped(cid, '<path d="M 50 140 C 90 110, 140 84, 200 74" fill="none" stroke="#8BC34A" stroke-width="6" opacity="0.7"/>'
                   '<path d="M 62 166 C 110 140, 160 112, 210 92" fill="none" stroke="#8BC34A" stroke-width="5" opacity="0.6"/>'
              + ''.join('<circle cx="%d" cy="%d" r="3" fill="#CDE8A5" opacity="0.9"/>' % (x, y)
                        for x, y in ((80, 130), (120, 108), (160, 90), (100, 150), (140, 128), (182, 108), (66, 160))))
    p.path(body, 'none')
    p.path('M 214 70 C 222 62, 232 62, 236 70 C 230 76, 222 78, 216 76 Z', '#6B8E2E', 3)
    p.path(ell(184, 182, 40, 34), g)
    p.path(ell(184, 182, 33, 27), '#D9F2B8', 0)
    p.fillp(ell(184, 182, 16, 13), '#C2E59A')
    p.add(''.join('<ellipse cx="%.1f" cy="%.1f" rx="3" ry="5" fill="%s" transform="rotate(%d %.1f %.1f)"/>'
                  % (184 + 15 * c, 182 + 12 * s_, CREAM, a, 184 + 15 * c, 182 + 12 * s_)
                  for a, c, s_ in ((0, 0, -1), (60, 0.87, -0.5), (120, 0.87, 0.5), (0, 0, 1), (60, -0.87, 0.5),
                                   (120, -0.87, -0.5))))
    p.hl('M 60 140 Q 90 112 130 92', 7)
    return p


def soup():
    p = Pic()
    p.shadow(rx=90)
    for x in (98, 128, 158):
        p.line('M %d 64 C %d 54, %d 46, %d 36 C %d 26, %d 18, %d 10' % (x, x - 8, x + 8, x, x - 8, x + 8, x),
               '#B8B0D0', 5, op=0.7)
    p.path(ell(128, 214, 40, 8), '#3E6FC2')
    body = 'M 30 118 C 32 182, 82 216, 128 216 C 174 216, 224 182, 226 118 Z'
    cid = p.shaded(body, '#5C8DDB', '#3E6FC2', k=10)
    p.clipped(cid, '<path d="M 36 150 C 80 172, 176 172, 220 150" fill="none" stroke="%s" stroke-width="8" opacity="0.8"/>'
              % WHITE)
    p.path(ell(128, 118, 98, 26), WHITE)
    p.fillp(ell(128, 120, 86, 20), '#F4A340')
    p.add(''.join('<circle cx="%d" cy="%d" r="%s" fill="%s" stroke="%s" stroke-width="2"/>' % (x, y, r, f, INK)
                  for x, y, r, f in ((86, 116, 7, '#FF7A2E'), (118, 126, 7, '#FF7A2E'), (162, 114, 7, '#FF7A2E'),
                                     (102, 108, 4, '#4CAF50'), (140, 112, 4, '#4CAF50'), (176, 126, 4, '#4CAF50'),
                                     (70, 124, 4, '#4CAF50'))))
    p.add(''.join('<rect x="%d" y="%d" width="11" height="9" rx="2" fill="#FFE7A8" stroke="%s" stroke-width="2"/>' % (x, y, INK)
                  for x, y in ((136, 124), (92, 124), (186, 112))))
    p.outlined_line('M 150 118 L 214 48', '#D7DCE6', 9)
    p.path(ell(220, 42, 12, 9), '#D7DCE6', 4)
    p.hl('M 44 140 Q 56 172 84 192', 7)
    return p


# ---- toys and things -----------------------------------------------------------------------------------------------

def mix(a, b, t):
    """a blended toward b by t (0..1), as #RRGGBB."""
    a, b = a.lstrip('#'), b.lstrip('#')
    return '#' + ''.join('%02X' % round(int(a[k:k + 2], 16) * (1 - t) + int(b[k:k + 2], 16) * t) for k in (0, 2, 4))


# The play ball's band: a deeper tone of the same hue, so the ball stays one named colour, the band still shows at
# 64 px, and the blue ball never carries a light-blue stripe (Russian sinij is not goluboj).
BAND = {'red': mix(HUES['red'][0], HUES['red'][1], 0.75), 'blue': mix(HUES['blue'][0], HUES['blue'][1], 0.8),
        'yellow': mix(HUES['yellow'][0], '#F08A00', 0.4), 'green': mix(HUES['green'][0], HUES['green'][1], 0.8),
        'white': '#E4E0EE', 'black': mix(HUES['black'][0], WHITE, 0.2)}


def ball(c='red'):
    """A children's rubber play ball sitting on the ground: matte (no gloss), a curved two-tone band with seams round
    its middle, a pebbled surface, a small valve; perfectly round (the balloon is the oval one, with a knot and string)."""
    f, s = HUES[c]
    band = BAND[c]
    p = Pic()
    p.shadow(cy=224, rx=78, ry=10)
    p.add('<ellipse cx="128" cy="222" rx="40" ry="6" fill="%s" opacity="0.22"/>' % INK)
    body = ell(128, 130, 92, 92)
    cid = p.shaded(body, f, s, k=14, sw=0)
    band_d = 'M 26 100 C 82 150, 174 150, 230 96 L 230 146 C 174 200, 82 200, 26 150 Z'
    seam = '#000000' if c != 'black' else '#FFFFFF'
    p.clipped(cid,
              '<path d="%s" fill="%s"/>' % (band_d, band)
              + '<path d="M 26 160 C 82 210, 174 210, 230 156 L 230 240 L 26 240 Z" fill="%s" opacity="0.25"/>' % s
              + '<path d="M 26 100 C 82 150, 174 150, 230 96 M 26 150 C 82 200, 174 200, 230 146" fill="none" '
                'stroke="%s" stroke-width="3" opacity="0.35"/>' % seam
              + '<path d="M 26 92 C 82 142, 174 142, 230 88 M 26 158 C 82 208, 174 208, 230 154" fill="none" '
                'stroke="%s" stroke-width="2" opacity="0.18"/>' % seam
              + ''.join('<circle cx="%d" cy="%d" r="1.6" fill="%s" opacity="0.16"/>' % (x, y, seam)
                        for x in range(46, 214, 14) for y in range(52, 218, 14)
                        if (x - 128) ** 2 + (y - 130) ** 2 < 84 ** 2 and (x // 14 + y // 14) % 2 == 0)
              + '<path d="%s" fill="%s" opacity="0.2"/>' % (ell(96, 86, 34, 24), mix(f, WHITE, 0.5)))
    p.path(ell(150, 70, 5, 5), mix(s, INK, 0.3), 2.5, stroke=mix(s, INK, 0.5))
    p.path(body, 'none')
    return p


def balloon(c='red'):
    f, s = HUES[c]
    p = Pic()
    p.line('M 128 192 C 112 210, 144 226, 126 250', INK, 3)
    body = 'M 128 14 C 178 14, 202 56, 200 100 C 198 148, 162 180, 128 184 C 94 180, 58 148, 56 100 C 54 56, 78 14, 128 14 Z'
    p.shaded(body, f, s, k=14)
    p.path('M 118 194 L 128 182 L 138 194 Z', f)
    p.hl('M 88 66 Q 96 42 118 34', 10)
    p.add('<circle cx="84" cy="86" r="5" fill="%s" opacity="0.55"/>' % WHITE)
    return p


def boat(c='red'):
    f, s = HUES[c]
    p = Pic()
    p.outlined_line('M 128 40 L 128 170', '#8A5A2B', 6)
    p.shaded('M 136 46 Q 186 110 206 160 L 136 160 Z', WHITE, '#E7E2F0', k=6)
    p.shaded('M 120 60 Q 92 120 66 160 L 120 160 Z', CREAM, '#EADFCB', k=6)
    p.path('M 128 30 L 154 38 L 128 46 Z', f, 3)
    hull = 'M 36 164 L 220 164 C 212 196, 190 212, 162 212 L 94 212 C 66 212, 44 196, 36 164 Z'
    cid = p.shaded(hull, f, s, k=8)
    p.clipped(cid, '<path d="M 30 176 L 226 176" stroke="%s" stroke-width="6" opacity="0.85"/>' % WHITE)
    for x in (98, 128, 158):
        p.path(ell(x, 192, 7, 7), '#DFF3FC', 3)
    p.fillp('M 12 204 Q 36 194 60 204 T 108 204 T 156 204 T 204 204 T 244 202 L 244 234 Q 128 246 12 234 Z', '#8FD3F4')
    p.line('M 12 204 Q 36 194 60 204 T 108 204 T 156 204 T 204 204 T 244 202', '#3FB6D9', 4)
    p.line('M 40 222 L 70 222 M 170 226 L 204 226', WHITE, 4, op=0.8)
    return p


def car():
    f, s = '#EF5350', '#C62F2F'
    p = Pic()
    p.shadow(cy=216, rx=104)
    body = 'M 22 168 C 22 146, 34 136, 58 132 L 80 132 L 102 96 C 106 90, 112 88, 120 88 L 176 88 C 186 88, 192 92, 198 100 L 218 132 C 232 136, 238 148, 236 168 C 236 178, 230 184, 222 184 L 32 184 C 26 184, 22 178, 22 168 Z'
    p.shaded(body, f, s, k=10)
    p.path('M 90 132 L 110 100 C 112 97, 115 96, 118 96 L 144 96 L 144 132 Z', '#BFE6F7', 3)
    p.path('M 152 96 L 176 96 C 182 96, 186 99, 189 104 L 205 132 L 152 132 Z', '#BFE6F7', 3)
    p.line('M 148 138 L 148 178 M 124 146 L 136 146 M 168 146 L 180 146', INK, 3.5)
    p.path(ell(30, 152, 6, 9), '#FFE08A', 3)
    p.path(rrect(226, 146, 10, 14, 3), '#FFC83D', 3)
    for x in (70, 190):
        p.path(ell(x, 184, 26, 26), '#3A3550')
        p.path(ell(x, 184, 11, 11), '#C9CFDD', 3)
    p.hl('M 112 92 L 170 92', 5)
    p.hl('M 40 142 Q 60 136 80 138', 6)
    return p


def doll():
    hair, skin, dress = '#E8743B', '#F2C9A0', '#8A5CF0'
    p = Pic()
    p.shadow(rx=80)
    p.shaded(ell(128, 86, 54, 52), hair, '#C85A26', k=6)
    for x in (70, 186):
        p.shaded(ell(x, 108, 18, 22), hair, '#C85A26', k=5)
        p.line('M %d 96 Q %d 108 %d 120' % (x - 6, x, x - 6), '#C85A26', 2.5)
    p.path('M 76 90 L 66 82 L 66 98 Z', '#2F7FE0', 3)
    p.path('M 180 90 L 190 82 L 190 98 Z', '#2F7FE0', 3)
    for x in (90, 138):
        lid = p.shaded(rrect(x, 176, 28, 46, 12), WHITE, '#E2DEEC', k=4)
        p.clipped(lid, ''.join('<rect x="%d" y="%d" width="28" height="7" fill="#E04F9E"/>' % (x, y)
                               for y in (184, 198, 212)))
        p.path(rrect(x, 176, 28, 46, 12), 'none')
        p.path(ell(x + 14, 224, 19, 10), '#E53935')
    p.path('M 96 136 C 76 146, 68 168, 72 182 C 76 192, 90 190, 92 180 C 92 166, 98 154, 106 146 Z', skin)
    p.path('M 160 136 C 180 146, 188 168, 184 182 C 180 192, 166 190, 164 180 C 164 166, 158 154, 150 146 Z', skin)
    did = p.shaded('M 98 128 L 158 128 L 184 196 C 160 208, 96 208, 72 196 Z', dress, '#6C40D0', k=8)
    p.clipped(did, ''.join('<circle cx="%d" cy="%d" r="4.5" fill="%s"/>' % (x, y, CREAM)
                           for x, y in ((104, 150), (132, 146), (150, 166), (118, 174), (90, 188), (166, 190), (138, 192))))
    p.path('M 104 128 L 128 144 L 152 128 Z', CREAM, 3)
    p.shaded(ell(128, 92, 42, 40), skin, '#E0AE84', k=6)
    p.path('M 86 88 C 88 54, 168 54, 170 88 C 156 72, 142 70, 128 78 C 114 70, 100 72, 86 88 Z', hair)
    p.eye(112, 98, 6)
    p.eye(144, 98, 6)
    p.add('<circle cx="100" cy="112" r="8" fill="#F48FB1" opacity="0.8"/><circle cx="156" cy="112" r="8" fill="#F48FB1" opacity="0.8"/>')
    p.line('M 116 114 Q 128 124 140 114', INK, 3)
    p.line('M 112 132 L 116 132 M 122 134 L 126 134 M 132 134 L 136 134 M 142 132 L 146 132', INK, 2)
    p.hl('M 98 66 Q 110 56 128 56', 6)
    return p


def drum():
    shell, sshell = '#E5484D', '#B92B2B'
    p = Pic()
    p.shadow(cy=226, rx=96)
    body = 'M 42 112 L 42 190 C 42 216, 214 216, 214 190 L 214 112 Z'
    cid = p.shaded(body, shell, sshell, k=10)
    tri = ''.join('<path d="M %.1f 186 L %.1f 134 L %.1f 186 Z" fill="#FFD23F" stroke="%s" stroke-width="2.5"/>'
                  % (x, x + 11, x + 22, INK) for x in range(42, 214, 22))
    p.clipped(cid, tri)
    p.path(body, 'none')
    p.line('M 42 190 C 42 216, 214 216, 214 190', INK, 16)
    p.line('M 42 190 C 42 216, 214 216, 214 190', '#FFC83D', 10)
    p.path(ell(128, 112, 86, 26), CREAM, 14, stroke=INK)
    p.path(ell(128, 112, 86, 26), 'none', 8, stroke='#FFC83D')
    p.fillp(ell(128, 112, 78, 20), CREAM)
    p.outlined_line('M 152 116 L 68 56', '#C98F52', 7)
    p.outlined_line('M 104 116 L 188 56', '#C98F52', 7)
    p.path(ell(66, 54, 11, 11), '#2F7FE0')
    p.path(ell(190, 54, 11, 11), '#2F7FE0')
    p.hl('M 56 130 L 56 176', 6)
    return p


def teddy():
    c, s, light = '#C98A4B', '#A86B33', '#EBC48F'
    p = Pic()
    p.shadow(rx=92)
    for x in (80, 176):
        p.shaded(ell(x, 50, 23, 23), c, s, k=5)
        p.fillp(ell(x, 52, 12, 12), light)
    p.path('M 80 132 C 54 142, 46 178, 62 190 C 76 198, 92 176, 98 152 Z', c)
    p.path('M 176 132 C 202 142, 210 178, 194 190 C 180 198, 164 176, 158 152 Z', c)
    bid = p.shaded(ell(128, 168, 56, 54), c, s)
    p.clipped(bid, '<path d="%s" fill="%s"/>' % (ell(128, 176, 34, 32), light))
    for x in (82, 174):
        p.shaded(ell(x, 212, 32, 22), c, s, k=5)
        p.fillp(ell(x + (-8 if x < 128 else 8), 214, 15, 14), light)
    p.shaded(ell(128, 90, 54, 50), c, s, k=9)
    p.path(ell(128, 110, 25, 18), light)
    p.path('M 117 100 Q 128 93 139 100 Q 136 110 128 111 Q 120 110 117 100 Z', INK, 0)
    p.line('M 128 111 L 128 118 M 119 120 Q 128 127 137 120', INK, 3)
    p.eye(104, 84, 7)
    p.eye(152, 84, 7)
    p.cheek(96, 104)
    p.cheek(160, 104)
    p.path('M 128 142 L 104 130 L 106 156 Z', '#2F7FE0', 3)
    p.path('M 128 142 L 152 130 L 150 156 Z', '#2F7FE0', 3)
    p.path(ell(128, 143, 7, 7), '#2F7FE0', 3)
    p.hl('M 88 62 Q 102 46 124 44', 8)
    return p


def book():
    cover, s = '#2F7FE0', '#1F5FB0'
    p = Pic()
    p.shadow(cy=236, rx=84)
    p.path('M 196 50 L 212 60 L 212 226 L 196 216 Z', CREAM)
    p.line('M 202 70 L 202 214 M 207 74 L 207 218', '#DCD3EC', 2)
    p.path('M 60 216 L 196 216 L 212 226 L 76 226 Z', CREAM)
    cid = p.shaded(rrect(56, 36, 140, 180, 8), cover, s, k=8)
    p.clipped(cid, '<rect x="50" y="30" width="18" height="190" fill="%s"/>' % s)
    p.path(rrect(56, 36, 140, 180, 8), 'none')
    pid = p.shaded(rrect(82, 62, 96, 96, 10), '#DEEBFC', '#C7DCF5', k=4)
    p.clipped(pid, '<circle cx="152" cy="90" r="13" fill="#FFC83D"/>'
                   '<path d="M 76 150 Q 110 108 146 136 Q 164 120 186 140 L 186 170 L 76 170 Z" fill="#34A86A"/>'
                   '<path d="M 100 126 L 116 112 L 132 126 L 132 146 L 100 146 Z" fill="#FF8A3D" stroke="%s" stroke-width="2.5"/>'
              % INK)
    p.path(rrect(82, 62, 96, 96, 10), 'none', 3)
    p.path('M 160 216 L 160 242 L 167 235 L 174 242 L 174 216 Z', '#E53935', 3)
    p.hl('M 74 52 L 74 196', 6)
    return p


def blocks():
    p = Pic()
    p.shadow(cy=226, rx=100)

    def cube(x, y, sz, f, s, top, glyph):
        d = sz * 0.28
        p.path('M %s %s L %s %s L %s %s L %s %s Z' % (x, y, x + d, y - d, x + sz + d, y - d, x + sz, y), top)
        p.path('M %s %s L %s %s L %s %s L %s %s Z' % (x + sz, y, x + sz + d, y - d, x + sz + d, y + sz - d, x + sz, y + sz), s)
        p.path(rrect(x, y, sz, sz, 6), f)
        p.path(rrect(x + 10, y + 10, sz - 20, sz - 20, 6), 'none', 3, stroke=WHITE)
        p.add(glyph)

    cube(30, 138, 78, '#E5484D', '#B92B2B', '#F28084',
         '<path d="M 69 156 L 75 170 L 90 171 L 78 181 L 82 196 L 69 188 L 56 196 L 60 181 L 48 171 L 63 170 Z" '
         'fill="#FFD23F" stroke="%s" stroke-width="3" stroke-linejoin="round"/>' % INK)
    cube(124, 138, 78, '#2F7FE0', '#1F5FB0', '#6FA8EC',
         '<circle cx="163" cy="177" r="19" fill="%s" stroke="%s" stroke-width="3"/>' % (WHITE, INK))
    cube(76, 52, 78, '#FFC83D', '#E0A21A', '#FFE08A',
         '<path d="M 115 70 L 136 108 L 94 108 Z" fill="#34A86A" stroke="%s" stroke-width="3" stroke-linejoin="round"/>' % INK)
    return p


def kite():
    p = Pic()
    p.fillp('M 18 206 C 18 190, 36 184, 48 190 C 54 176, 78 176, 84 192 C 98 190, 104 206, 92 212 L 26 212 C 18 212, 18 210, 18 206 Z',
            '#DEEBFC')
    p.line('M 150 100 Q 92 150 30 246', INK, 2, op=0.6)
    tail = 'M 150 178 C 142 200, 122 196, 112 214 S 92 238, 70 232'
    p.line(tail, INK, 3)
    for (x, y, col) in ((136, 196, '#E5484D'), (110, 214, '#FFD23F'), (88, 232, '#2F7FE0')):
        p.path('M %d %d L %d %d L %d %d Z M %d %d L %d %d L %d %d Z'
               % (x, y, x - 12, y - 8, x - 12, y + 8, x, y, x + 12, y - 8, x + 12, y + 8), col, 2.5)
    pts = {'t': (150, 20), 'r': (216, 92), 'b': (150, 178), 'l': (84, 92), 'c': (150, 92)}
    quads = (('t', 'r', '#FFD23F'), ('r', 'b', '#2F7FE0'), ('b', 'l', '#34A86A'), ('l', 't', '#E53935'))
    for a, b, col in quads:
        (x1, y1), (x2, y2), (cx, cy) = pts[a], pts[b], pts['c']
        p.fillp('M %d %d L %d %d L %d %d Z' % (x1, y1, x2, y2, cx, cy), col)
    p.line('M 150 20 L 150 178 M 84 92 L 216 92', INK, 3)
    p.path('M 150 20 L 216 92 L 150 178 L 84 92 Z', 'none')
    p.hl('M 140 36 L 100 82', 6)
    return p


def hat_warm():
    f, s = '#EF6F5E', '#CF4F40'
    p = Pic()
    p.shadow(cy=222, rx=92)
    dome = 'M 52 168 C 50 96, 84 58, 128 58 C 172 58, 206 96, 204 168 Z'
    did = p.shaded(dome, f, s, k=12)
    ribs = ''.join('<path d="M %d 168 Q %d 110 128 58" fill="none" stroke="#F49A8C" stroke-width="3" opacity="0.8"/>'
                   % (x, (x + 128) // 2) for x in (64, 84, 104, 152, 172, 192))
    p.clipped(did, ribs + '<path d="M 40 112 L 216 112 L 216 132 L 40 132 Z" fill="%s"/>' % CREAM)
    p.path(dome, 'none')
    cuff = rrect(38, 158, 180, 46, 10)
    cid = p.shaded(cuff, CREAM, '#E9DFD2', k=6)
    p.clipped(cid, ''.join('<path d="M %d 160 L %d 202" stroke="#E3D6C6" stroke-width="4"/>' % (x, x) for x in range(50, 214, 12)))
    p.path(cuff, 'none')
    pom = ''.join('Q %.1f %.1f %.1f %.1f ' % (128 + 30 * math.cos(a + 0.26), 46 + 30 * math.sin(a + 0.26),
                                             128 + 24 * math.cos(a + 0.52), 46 + 24 * math.sin(a + 0.52))
                  for a in [k * 0.5236 for k in range(12)])
    p.shaded('M 152 46 ' + pom + 'Z', CREAM, '#E9DFD2', k=5)
    p.hl('M 70 120 Q 80 84 110 68', 8)
    return p


def scarf():
    """A striped knitted scarf hanging over a wooden peg, both ends down, fringed."""
    f, s = '#F59E1B', '#D97E0A'
    p = Pic()
    p.shadow(cy=236, rx=70)
    stripes = ''.join('<path d="M 40 %d L 220 %d" stroke="%s" stroke-width="9"/>' % (y, y - 12, CREAM) for y in (120, 150, 180))
    for d in ('M 104 50 C 94 96, 86 150, 80 206 L 120 212 C 122 160, 126 104, 132 60 Z',
              'M 128 56 C 142 104, 160 150, 178 200 L 214 186 C 194 136, 170 90, 156 48 Z'):
        cid = p.shaded(d, f, s, k=6)
        p.clipped(cid, stripes)
        p.path(d, 'none')
    p.line('M 84 210 L 82 228 M 94 211 L 93 229 M 104 212 L 104 230 M 114 212 L 115 230', f, 5)
    p.line('M 182 200 L 188 216 M 192 196 L 199 212 M 202 192 L 210 207 M 210 189 L 219 203', f, 5)
    p.path(rrect(84, 22, 88, 20, 8), '#C98F52')
    p.path(ell(128, 32, 6, 6), '#8A5A2B', 3)
    p.shaded('M 98 58 C 100 30, 158 28, 160 54 C 150 64, 138 66, 128 62 C 118 66, 106 66, 98 58 Z', f, s, k=4)
    p.hl('M 100 80 Q 94 130 90 190', 6)
    return p


def hat():
    straw, s = '#F2C94C', '#D9A92A'
    p = Pic()
    p.shadow(cy=206, rx=104)
    bid = p.shaded(ell(128, 168, 110, 32), straw, s, k=8)
    p.clipped(bid, '<path d="%s" fill="none" stroke="%s" stroke-width="3" opacity="0.6"/>' % (ell(128, 168, 92, 24), s))
    crown = 'M 74 168 C 72 110, 92 74, 128 74 C 164 74, 184 110, 182 168 C 156 180, 100 180, 74 168 Z'
    cid = p.shaded(crown, straw, s, k=10)
    p.clipped(cid, '<path d="M 60 140 C 100 152, 156 152, 196 140 L 196 164 C 156 176, 100 176, 60 164 Z" fill="#2F7FE0"/>')
    p.path(crown, 'none')
    p.line('M 74 142 C 100 152, 156 152, 182 142', INK, 3)
    p.path('M 170 150 L 196 140 L 192 166 Z', '#2F7FE0', 3)
    p.hl('M 92 132 Q 96 100 116 86', 7)
    return p


def shirt():
    f, s = '#26A69A', '#1C7E75'
    p = Pic()
    p.shadow(cy=230, rx=70)
    d = 'M 92 40 C 104 54, 152 54, 164 40 L 214 64 L 196 114 L 176 106 L 176 218 L 80 218 L 80 106 L 60 114 L 42 64 Z'
    p.shaded(d, f, s, k=10)
    p.path('M 92 40 C 104 66, 152 66, 164 40 C 152 54, 104 54, 92 40 Z', s, 3)
    p.line('M 58 104 L 74 98 M 198 104 L 182 98', s, 4)
    p.hl('M 96 80 L 96 196', 7)
    return p


def bowl():
    f, s = '#7EC8E8', '#4FA9D0'
    p = Pic()
    p.shadow(cy=220, rx=82)
    p.path(ell(128, 212, 42, 9), s)
    body = 'M 28 110 C 30 178, 80 214, 128 214 C 176 214, 226 178, 228 110 Z'
    cid = p.shaded(body, f, s, k=12)
    p.clipped(cid, '<path d="M 36 142 C 70 164, 186 164, 220 142" fill="none" stroke="%s" stroke-width="7" opacity="0.8"/>'
              % WHITE)
    p.path(body, 'none')
    p.path(ell(128, 110, 100, 26), WHITE)
    p.fillp('M 36 112 A 92 20 0 0 0 220 112 A 92 14 0 0 1 36 112 Z', '#E4F3FA')
    p.hl('M 44 132 Q 56 168 86 188', 7)
    return p


def oven():
    body, s = '#ECE8F4', '#D3CCE2'
    p = Pic()
    p.shadow(cy=226, rx=104)
    p.path(rrect(52, 206, 16, 14, 3), '#7A7490', 3)
    p.path(rrect(188, 206, 16, 14, 3), '#7A7490', 3)
    p.shaded(rrect(40, 36, 176, 174, 12), body, s, k=8)
    p.path(rrect(40, 36, 176, 30, 10), '#DCD3EC')
    for x in (70, 104, 152, 186):
        p.path(ell(x, 51, 8, 8), '#7A7490', 3)
        p.line('M %d 45 L %d 51' % (x, x), WHITE, 2.5)
    p.path(rrect(58, 80, 140, 100, 8), '#4A3A6A')
    p.fillp(rrect(66, 88, 124, 84, 6), '#5C4A80')
    p.line('M 74 98 Q 82 92 90 98 T 106 98 T 122 98 T 138 98 T 154 98 T 170 98 T 182 98', '#FF8A3D', 4)
    p.line('M 66 140 L 190 140', '#B8B0D0', 4)
    p.line('M 76 140 L 76 150 M 180 140 L 180 150', '#B8B0D0', 3)
    p.add('<rect x="66" y="88" width="124" height="84" rx="6" fill="#FFB35A" opacity="0.18"/>')
    p.path('M 50 180 L 206 180 L 228 214 L 28 214 Z', '#DCD3EC')
    p.path('M 74 186 L 182 186 L 194 206 L 62 206 Z', '#8FA0C8', 3)
    p.line('M 40 214 L 216 214', INK, 4)
    p.hl('M 54 74 L 54 168', 6)
    return p


def spoon():
    """A table spoon: an oval bowl and a handle that widens to its end, lying on the diagonal."""
    f, s = '#D7DCE6', '#AEB5C6'
    p = Pic()
    p.shadow(cy=230, rx=80)
    p.add('<g transform="rotate(-40 128 128)">')
    p.shaded('M 122 100 C 120 140, 114 186, 114 212 C 114 228, 142 228, 142 212 C 142 186, 136 140, 134 100 Z', f, s, k=4)
    p.shaded(ell(128, 64, 30, 46), f, s, k=8)
    p.fillp(ell(128, 66, 21, 35), '#C3C9D6', op=0.6)
    p.hl('M 110 50 Q 112 32 124 26', 6)
    p.hl('M 126 120 L 122 200', 4)
    p.add('</g>')
    return p


OBJECTS = {
    'cat': cat, 'dog': dog, 'fish': fish, 'cow': cow, 'mouse': mouse, 'duck': duck, 'duckling': duckling,
    'bird': bird, 'rabbit': rabbit, 'pig': pig, 'horse': horse, 'elephant': elephant,
    'apple': apple, 'banana': banana, 'bread': bread, 'egg': egg, 'cake': cake, 'milk': milk, 'juice': juice,
    'water': water, 'cheese': cheese, 'cucumber': cucumber, 'soup': soup,
    'car': car, 'doll': doll, 'drum': drum, 'teddy': teddy, 'book': book, 'blocks': blocks, 'kite': kite,
    'hat-warm': hat_warm, 'scarf': scarf, 'hat': hat, 'shirt': shirt, 'bowl': bowl, 'oven': oven, 'spoon': spoon,
}
COLOURED = {  # one drawing, recoloured; the plain id is the red one
    'ball': (ball, ('red', 'blue', 'yellow', 'green', 'white', 'black')),
    'balloon': (balloon, ('red', 'blue', 'yellow', 'green')),
    'boat': (boat, ('red', 'blue', 'yellow', 'green')),
}


def build():
    """All pictures as {file id: svg text}, in a fixed order."""
    out = {}
    for name, draw in OBJECTS.items():
        out[name] = draw().svg()
    for name, (draw, colours) in COLOURED.items():
        out[name] = draw('red').svg()
        for c in colours:
            out['%s-%s' % (name, c)] = draw(c).svg()
    return out


def sheet(ids, out=SHEET, cols=8):
    """The contact sheet: each picture on a white card at 200 px, and the whole set again at 64 px."""
    import pathlib
    big = ''.join('<div class="c"><img src="%s"><span>%s</span></div>' % ((pathlib.Path(OUT) / (i + '.svg')).as_uri(), i)
                  for i in ids)
    small = ''.join('<img class="s" src="%s">' % (pathlib.Path(OUT) / (i + '.svg')).as_uri() for i in ids)
    w = cols * 212 + 24
    rows = (len(ids) + cols - 1) // cols
    h = rows * 236 + 24 + ((len(ids) + 2 * cols - 1) // (2 * cols)) * 76 + 60
    html = ('<html><body style="margin:0;padding:12px;background:#FFF6E8;width:%dpx;font:13px sans-serif;color:#2B2350">'
            '<style>.c{display:inline-block;width:200px;margin:6px;text-align:center}.c img{width:200px;height:200px;'
            'background:#fff;border-radius:16px}.s{width:64px;height:64px;margin:6px;background:#fff;border-radius:10px}'
            '</style>%s<div style="margin-top:12px;width:%dpx">%s</div></body></html>' % (w - 24, big, cols * 2 * 76, small))
    tmp = out + '.html'
    with open(tmp, 'w', encoding='utf-8') as fh:
        fh.write(html)
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
                    '--allow-file-access-from-files', '--screenshot=' + out, '--window-size=%d,%d' % (w, h),
                    pathlib.Path(tmp).as_uri()], check=True, capture_output=True)
    os.remove(tmp)


def main():
    os.makedirs(OUT, exist_ok=True)
    pics = build()
    for name, text in pics.items():
        assert len(text.encode('utf-8')) < 40000, name
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(text)
    print('wrote', len(pics), 'pictures to', os.path.relpath(OUT, ROOT))
    if '--sheet' in sys.argv:
        sheet(list(pics))
        print('sheet', os.path.relpath(SHEET, ROOT))
        sheet(['ball-%s' % c for c in COLOURED['ball'][1]] + ['balloon-%s' % c for c in COLOURED['balloon'][1]], BALLS, cols=6)
        print('sheet', os.path.relpath(BALLS, ROOT))


if __name__ == '__main__':
    main()
