"""Draws the activity pictures of the starter pack in the house style into content/starter, under the ids the lessons
already use and on their old canvases (100 x 100; flower_target 160 x 200; the empty scenes 400 x 225), so no activity
changes. Started as the Riddle Grotto (Logic land) redraw of the 2026-11-06 sweep; since the owner's word that day
("redraw all the old drawings also so everything would look better and would fit") it is the one generator of them all:

    python tools/make_logic_sprites.py                   # writes the SVGs
    python tools/make_logic_sprites.py --sheet [batch]   # also the old-against-new contact sheets in docs/design/logic-sweep/
                                                         # (batches: logic-2, shapes, numbers, math, colours, forest, robot, towers; "first")

Batch logic-1: duck (and duck_lit), bird (and bird_lit), chick, rule_size, rule_shape, rule_colour, plate, brush, paste,
balloon_<colour> (11 colours); new: umbrella, bin_basket, bin_grass, clue_not_colour, clue_not_shape, clue_not_<red|blue|
green|yellow|orange> and clue_not_<circle|square|triangle> (docs/knowledge/logic/sweep-2026-11-06.md, D1, D3 to D8, D13,
D15). Batch logic-2: tower_1 to tower_8 (one cube size for all eight), cat, dog, fish, apple, apple_green, star, frog,
sock, shoe, key, lock, spoon, bowl, pencil, paper, cloud, rain, rainbow, egg, egg_crack, plant_seed/sprout/flower, tick,
cross, ball_<colour> (11), the size families <ball|star|apple|fish>_size_<s|m|l>, the lit twins. Batch shapes: the 32
shape_* pictures (the old geometry, point for point). Batch numbers: ladybug, butterfly (and their lit twins),
basket_target, flower_target, nest_empty, bowl_empty, basket_empty. Batch math: block, coin, stick_long, stick_short,
stone, feather, banana_yellow, banana_green, time_<morning|noon|evening|night>, day_1 to day_7, clock_1 to clock_12.
The list of every picture and what is still to redraw: docs/design/logic-sweep/old-style-inventory.md.

tools/make_unit_sprites.py and tools/make_picture_sprites.py only run this file now, so a re-run of an old generator
cannot bring an old drawing back. Colour Bay, Shape Forest and Robot Harbour are batches colours, forest and robot.

The Languages pictures (tools/make_language_pictures.py and _b2.py) are reused for the things both draw (lang() below):
the same drawing with a thicker outline and a closer crop, so a cat is one cat in the whole app. A change there shows
here on the next run.

Style: the house style of docs/art/art-brief.md section 3, as in tools/make_language_pictures.py, scaled for a
100 x 100 canvas that is shown from 24 to 90 points: the ink outline #2B2350 at 3 units (about 2 px on a tile), one
soft shade tone per shape (the shape shifted toward the top-left light, clipped to itself), one white highlight at
55 percent, dot eyes with a white spark and pink cheeks on the animals, a soft ground shadow. The three birds face
left like the Languages animals. Every bird differs from the others by its outline, not only by its colour:
the duck is long and low, floating on water, with a flat bill; the bird is slim and upright on a twig, with a thin
pointed beak and a long tail; the chick is a round ball of fluff seen from the front, on two legs.
The colour cards (rule_colour, clue_not_<colour>) show a crayon, never a drop (an orange drop under a "no" sign
reads as "no fire"). Colour sets (balloons) keep the hues of make_picture_sprites.py COLOURS, so Colour Bay teaches the same colours.
SVG 1.1 subset only (paths, circles, ellipses, rects, groups, transforms, a simple clipPath); no text, no filter.

Our own drawings in plain shapes: nothing traced or copied, no brand, no franchise look, no letter or numeral.
References looked at on 2026-11-06 (facts and photographs; the look is ours):
  Duck: https://en.wikipedia.org/wiki/Mallard (body two thirds of the length, broad flat bill, upturned tail) and the
    Wikimedia Commons media search "mallard duck swimming" (long low boat-shaped body sitting in the water, round head
    on a short neck, flat spatula bill, the tail tip raised). Drawn as a white farm duck (Pekin, as the Languages duck)
    so it is never a second yellow bird next to the chick.
  Bird: https://en.wikipedia.org/wiki/European_robin (a small songbird, orange-red breast, whitish belly) and the
    Commons search "eastern bluebird perched" (blue head, back, wings and long tail, rust-orange throat and breast,
    white belly, a thin short dark bill, thin dark legs gripping a twig or wire, the body upright and slanted).
  Chick: Commons search "newly hatched chicken chick" (a round ball of yellow down, a tiny pointed beak, small dark eyes,
    thin pale-orange legs, bits of the egg shell next to it).
  Toothbrush and toothpaste: Commons search "toothbrush toothpaste tube" (a long handle with a grip, a narrow neck, a
    head with rows of bristle tufts standing up; a soft tube crimped flat at one end with ridges, a shoulder, a
    nozzle with a round cap, the paste squeezed out as a ribbon, often white with a coloured band).
  Balloon: Commons search "red balloon string" (a latex balloon is egg-shaped, wider at the top, with a small tied
    knot at the bottom and a long string hanging in a wave).
  Umbrella: Commons search "open umbrella rain" (a dome of eight panels with a scalloped edge between the ribs, a tip
    on top, a straight shaft and a hooked handle).
  Basket: Commons search "wicker basket empty" (woven bands, a thick rolled rim, an arched handle, wider at the top).
  Plate: Commons search "empty dinner plate" (seen from the side of a table a plate is a wide flat ellipse: a rim, a
    shallow well, the thickness of the edge showing below; a coloured band on the rim is common on children's plates).
  Crayon: the wax crayons of any kindergarten (a pointed tip, a paper wrapper with bands, a flat end).
  Towers: the stacking cubes of a counting tower (Unifix and wooden toy cubes): square cubes of one size, stacked on a
    base, one colour per place.
References for the second batch, looked at on 2026-11-06:
  Ladybird: https://en.wikipedia.org/wiki/Coccinella_septempunctata (orange-red wing cases with seven black spots, one
    on the seam with a white patch on each side of it, three on each wing case; a black head shield with a white spot at
    each front corner; black legs) and the Commons search "seven-spot ladybird" (a round red dome split down the middle).
  Padlock and key: https://en.wikipedia.org/wiki/Padlock (a body, a U-shaped shackle, the keyhole) and the Commons
    search "brass padlock key" (a brass body with rounded corners, a silver steel shackle, a key with a round bow and a
    hole, a straight shaft and the cut teeth at its end).
  Sneaker: https://en.wikipedia.org/wiki/Sneakers (a flexible sole of dense rubber) and the Commons search "sneaker
    shoe" (a canvas sneaker from the side: a white rubber sole and toe cap, a canvas upper, laces crossing over the
    tongue through eyelets, the collar opening at the heel). No brand mark.
  Seedling: the Commons search "seedling" (two round seed leaves on a thin pale stem coming out of a mound of soil).
  Clock: an ordinary wall clock (twelve marks, the long minute hand and the short hour hand turning clockwise); calendar
    page: an ordinary wall calendar (two binder rings, a coloured band at the top). Sticks, stone, feather, coin, the
    nest, the sky at four times of day: drawn from what they look like outdoors; the coin is not a real coin.
  The Languages pictures reused here carry their own references (tools/make_language_pictures.py and _b2.py).
References for the plain path robot, looked at on 2026-11-07 (photographs; the look is ours):
  Robot: the Wikimedia Commons media searches "wind-up robot toy" and "tin toy robot" (the generic tin wind-up toy
    robots of the 1950s to 1970s: a box head on a short neck, a single antenna, round lens eyes, a small grille mouth,
    plates or bolts at the sides of the head, a box body with a chest panel of dials and lights, ribbed arms with
    pincer hands, short legs on flat boots). The many photographs of one well-known film robot in those searches were
    left out; nothing is taken from any one toy or character.
"""
import os
import pathlib
import re
import subprocess
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
OUT = os.path.join(ROOT, 'content', 'starter')
SHEET = os.path.join(ROOT, 'docs', 'design', 'logic-sweep', 'sprites-2026-11-06.png')
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'

INK = '#2B2350'
WHITE = '#FFFFFF'
PINK = '#FF9DB0'
SW = 3  # the outline on a 100 x 100 canvas
GLOW = '<circle cx="50" cy="50" r="48" fill="#FFE680" opacity="0.75"/>'

# The colour names of make_picture_sprites.py, with a shade tone for each (the fill moved toward ink).
COLOURS = {
    'red': ('#E5484D', '#B8323A'), 'blue': ('#2F7FE0', '#1F5DB0'), 'yellow': ('#FFD84D', '#E0A21A'),
    'green': ('#4CAF50', '#2F8A3A'), 'orange': ('#FF9F43', '#D9762A'), 'purple': ('#9B6BDF', '#7246B8'),
    'pink': ('#F48FB1', '#D9668F'), 'black': ('#2B2540', '#171424'), 'white': ('#FFFFFF', '#E2DEEC'),
    'brown': ('#8A5A2B', '#66401C'), 'grey': ('#9AA0B4', '#767C92'),
}


class Pic:
    """One picture: a list of elements and a counter for its clip ids."""

    def __init__(self):
        self.parts = []
        self.n = 0

    def add(self, s):
        self.parts.append(s)
        return self

    def body(self):
        return ''.join(self.parts)

    def path(self, d, fill, sw=SW, stroke=INK, op=None, extra=''):
        o = ' opacity="%s"' % op if op is not None else ''
        st = (' stroke="%s" stroke-width="%s" stroke-linejoin="round" stroke-linecap="round"' % (stroke, sw)
              if sw else '')
        return self.add('<path d="%s" fill="%s"%s%s%s/>' % (d, fill, st, o, extra))

    def fillp(self, d, fill, op=None):
        return self.path(d, fill, sw=0, op=op)

    def line(self, d, color=INK, w=SW, op=None):
        o = ' opacity="%s"' % op if op is not None else ''
        return self.add('<path d="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round" '
                        'stroke-linejoin="round"%s/>' % (d, color, w, o))

    def outlined_line(self, d, color, w):
        """A thick stroke with an ink edge (a twig, a handle, a string)."""
        self.line(d, INK, w + 2 * SW)
        return self.line(d, color, w)

    def hl(self, d, w=3):
        return self.line(d, WHITE, w, op=0.55)

    def shaded(self, d, fill, shade, k=4.5, sw=SW):
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

    def shadow(self, cx, cy, rx, ry=None):
        return self.add('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" opacity="0.13"/>'
                        % (cx, cy, rx, ry or max(2.5, rx * 0.16), INK))

    def eye(self, cx, cy, r=3.2):
        self.add('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>' % (cx, cy, r, round(r * 1.15, 1), INK))
        return self.add('<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % (round(cx - r * 0.35, 1), round(cy - r * 0.4, 1),
                                                                       round(r * 0.38, 1), WHITE))

    def cheek(self, cx, cy, rx=4, ry=2.6):
        return self.add('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" opacity="0.6"/>' % (cx, cy, rx, ry, PINK))


def svg(body):
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">%s</svg>\n' % body)


# ---- the three birds ---------------------------------------------------------------------------------------------

def duck():
    """A white farm duck floating on a strip of water, facing left: long low body, raised tail, flat orange bill."""
    p = Pic()
    p.fillp('M4 74 Q50 68 96 74 L96 88 Q50 94 4 88 Z', '#8FD3F4')
    body = 'M22 62 C22 50 36 46 54 49 C68 51 79 47 89 37 C94 52 90 76 68 80 L36 80 C27 80 22 72 22 62 Z'
    p.shaded(body, WHITE, '#E3DFEA')
    neck = 'M44 58 C38 50 41 42 41 32 C41 21 34 14 26 14 C16 14 11 22 12 29 C13 37 20 42 22 58 Z'
    p.shaded(neck, WHITE, '#E3DFEA', k=3.5)
    wing = 'M44 63 C51 54 72 54 80 60 C72 71 54 73 44 63 Z'
    p.shaded(wing, WHITE, '#E3DFEA', k=3)
    p.line('M56 61 Q64 64 72 61', '#D4CEE0', 2)
    p.path('M14 26 C8 25 2 28 1 31 C2 35 9 36 16 33 Z', '#FF9F43')
    p.line('M3 31 Q9 31 15 30', '#D9762A', 1.6)
    p.eye(24, 24)
    p.cheek(27, 31, 3.2, 2.2)
    p.hl('M30 18 Q35 20 37 25', 2.4)
    # the water in front of the body, so the duck sits in it
    p.fillp('M4 78 Q26 74 50 77 Q74 80 96 76 L96 88 Q50 94 4 88 Z', '#8FD3F4')
    p.line('M14 84 Q22 81 30 84 M60 86 Q68 83 76 86', WHITE, 2, op=0.7)
    return p.body()


def bird():
    """A small songbird (blue back, orange breast) perched on a twig, facing left: slim, thin pointed beak, long tail."""
    p = Pic()
    p.outlined_line('M4 82 Q50 76 96 81', '#8A5A2B', 4)
    p.path('M78 79 C80 71 88 68 94 70 C92 77 85 80 78 79 Z', '#4CAF50', sw=2.4)
    tail = 'M58 58 L86 74 C88 76 86 80 83 79 L54 68 Z'
    p.shaded(tail, '#3E7FD6', '#2A5FAE', k=2)
    body = ('M24 31 C25 21 33 16 41 18 C49 20 53 28 57 36 C63 46 66 55 64 62 C60 70 50 72 42 70 '
            'C32 67 27 58 26 49 C25 43 23 38 24 31 Z')
    cid = p.shaded(body, '#4D8FE0', '#2F6CC0', k=3.5, sw=0)
    p.clipped(cid, '<path d="M16 34 C30 36 40 46 46 76 L10 76 Z" fill="#F28A45"/>'
                   '<path d="M34 62 C40 64 46 70 48 76 L30 76 Z" fill="#FFFFFF"/>')
    p.path(body, 'none')
    wing = 'M41 34 C51 35 60 45 62 57 C53 58 44 51 41 34 Z'
    p.shaded(wing, '#3E7FD6', '#2A5FAE', k=2.5)
    p.line('M47 44 Q53 48 56 54', '#2A5FAE', 1.6)
    p.path('M25 27 L13 30.5 L25 33 Z', '#3A3650', sw=2)
    p.eye(31, 26, 2.9)
    p.hl('M34 20 Q40 21 44 26', 2.2)
    # legs gripping the twig
    p.line('M42 69 L40 78 M48 70 L48 78', INK, 2.4)
    p.line('M36 79 Q40 76 44 79 M45 79 Q48 76 52 79', INK, 2)
    return p.body()


def chick_outline(cx=50, cy=55, r=27, bumps=22, d=1.1):
    """A round body with a soft fluffy edge: small arcs bulging out between points on a circle."""
    import math
    pts = [(cx + r * math.cos(2 * math.pi * k / bumps - math.pi / 2), cy + r * math.sin(2 * math.pi * k / bumps - math.pi / 2))
           for k in range(bumps)]
    s = 'M%.1f %.1f' % pts[0]
    for k in range(bumps):
        a, b = pts[k], pts[(k + 1) % bumps]
        mx, my = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
        ox, oy = mx - cx, my - cy
        n = (ox * ox + oy * oy) ** 0.5
        s += ' Q%.1f %.1f %.1f %.1f' % (mx + ox / n * d * 2, my + oy / n * d * 2, b[0], b[1])
    return s + ' Z'


def chick():
    """A newly hatched chick seen from the front: a round ball of yellow fluff on two thin legs."""
    p = Pic()
    p.shadow(50, 91, 30, 3.6)
    p.line('M41 80 L40 90 M59 80 L60 90', '#E39A3A', 3)
    p.line('M34 91 L40 89 L46 91 M54 91 L60 89 L66 91', '#E39A3A', 2.4)
    p.path('M18 56 C10 58 10 68 18 70 C21 66 22 60 18 56 Z', '#F7C531', sw=2.4)
    p.path('M82 56 C90 58 90 68 82 70 C79 66 78 60 82 56 Z', '#F7C531', sw=2.4)
    p.shaded(chick_outline(), '#FFD84D', '#F2B800', k=4)
    p.path('M47 28 C45 22 48 18 51 20 C50 23 50 25 50 28 M50 28 C51 22 56 20 58 23 C55 24 53 26 52 29', 'none', sw=2.4)
    p.eye(41, 49)
    p.eye(59, 49)
    p.cheek(35, 58)
    p.cheek(65, 58)
    p.path('M45 56 L50 53 L55 56 L50 61 Z', '#FF9F43', sw=2)
    p.hl('M35 36 Q41 32 47 32', 2.6)
    return p.body()


# ---- towers of cubes -----------------------------------------------------------------------------------------------

# From the bottom up, in every tower: red, orange, yellow, green, blue, purple, then pink and brown for the +2 items
# (pink is lighter than red and purple, brown darker than orange and red, so the eight stay apart also in lightness).
CUBES = ['#E5484D', '#FF9F43', '#FFD84D', '#4CAF50', '#4DA3FF', '#9B6BDF', '#F48FB1', '#8A5A2B']
CUBE_SHADE = ['#B8323A', '#D9762A', '#E0A21A', '#2F8A3A', '#2F7FE0', '#7246B8', '#D9668F', '#66401C']
TOWER_MAX = 8
TOWER_W, TOWER_H = 100, 220  # a tall canvas of its own, so a cube is 24 units wide and all eight still fit one scale
GROUND = 208
CUBE = 24.0


def tower(n):
    """n square cubes of one size on a ground line, the same colours from the bottom up in every tower (100 x 220)."""
    p = Pic()
    k = CUBE / 14.8  # the cube of the first drawing was 14.8 units; its details scale with it
    p.shadow(50, GROUND + 2.5, 30, 3.6)
    p.line('M18 %s L82 %s' % (GROUND, GROUND), INK, 3.6)
    x = 50 - CUBE / 2
    for i in range(n):
        y = GROUND - CUBE * (i + 1)
        p.add('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="%.1f" fill="%s"/>'
              % (x, y, CUBE, CUBE, 2.2 * k, CUBE_SHADE[i]))
        p.add('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="%.1f" fill="%s"/>'
              % (x, y, CUBE - 2.6 * k, CUBE - 2.6 * k, 2 * k, CUBES[i]))
        p.add('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="%.1f" fill="none" stroke="%s" stroke-width="3.4"/>'
              % (x, y, CUBE, CUBE, 2.2 * k, INK))
        p.add('<rect x="%.2f" y="%.2f" width="%.1f" height="%.1f" rx="1.6" fill="%s" opacity="0.6"/>'
              % (x + 2.6 * k, y + 2.6 * k, 3.2 * k, 3.2 * k, WHITE))
    return p.body()


# ---- the three rule cards of LOG-B-06: each changes one thing only ------------------------------------------------

NEUTRAL = ('#B4B8C8', '#9095AA')


def crayon(cx, cy, c, s, rot=0, scale=1.0):
    """A wax crayon standing up: a pointed tip, a paper wrapper with two bands, a flat end (the colour itself)."""
    p = Pic()
    p.n = int(cx * 10 + cy)  # clip ids unique inside one picture
    tip = 'M-7 -20 L-3 -33 C-2 -35 2 -35 3 -33 L7 -20 Z'
    p.shaded(tip, c, s, k=1.5, sw=2.4)
    body = 'M-8 -21 H8 V22 C8 24 6.5 25 5 25 H-5 C-6.5 25 -8 24 -8 22 Z'
    cid = p.shaded(body, c, s, k=2.5, sw=0)
    p.clipped(cid, '<path d="M-9 -12 H9 V16 H-9 Z" fill="%s" opacity="0.28"/>'
                   '<path d="M-9 -9 H9 M-9 13 H9" stroke="%s" stroke-width="2" fill="none"/>' % (WHITE, s))
    p.path(body, 'none', sw=2.6)
    p.hl('M-4 -6 V8', 2.2)
    return '<g transform="translate(%s %s) rotate(%s) scale(%s)">%s</g>' % (cx, cy, rot, scale, p.body())


def rule_colour():
    """Colour: the same crayon three times, in three colours (only the colour changes)."""
    p = Pic()
    p.shadow(50, 86, 40, 3.2)
    for cx, (c, s) in zip((22, 50, 78), (COLOURS['red'], COLOURS['blue'], COLOURS['yellow'])):
        p.add(crayon(cx, 56, c, s, scale=1.05))
    return p.body()


def rule_shape():
    """Shape: a circle, a square and a triangle of one size and one grey (only the shape changes)."""
    p = Pic()
    p.shadow(50, 82, 42, 3.2)
    p.shaded('M19 44 A13 13 0 1 1 18.99 44 Z', NEUTRAL[0], NEUTRAL[1], k=3)
    p.shaded('M38 44 H62 V68 H38 Z', NEUTRAL[0], NEUTRAL[1], k=3)
    p.shaded('M81 42 L95 69 H67 Z', NEUTRAL[0], NEUTRAL[1], k=3)
    return p.body()


def rule_size():
    """Size: the same grey ball small and big on one line, a ruler beside them and its marks at their tops."""
    p = Pic()
    p.shadow(44, 86, 40, 3)
    p.line('M6 85 H74', INK, 2.6)
    # the ruler
    p.path('M80 14 H94 V85 H80 Z', '#FFD84D')
    for k, y in enumerate(range(22, 84, 8)):
        p.line('M80 %d H%d' % (y, 87 if k % 2 else 90), INK, 1.8)
    # the dashed marks of the two heights
    p.add('<path d="M14 65 H80 M52 37 H80" fill="none" stroke="%s" stroke-width="1.8" stroke-dasharray="3 3" '
          'opacity="0.55"/>' % INK)
    p.shaded('M14 65 A10 10 0 1 1 13.99 65 Z', NEUTRAL[0], NEUTRAL[1], k=2.4)
    p.hl('M8 73 Q9 69 12 68', 2.2)
    p.shaded('M52 37 A24 24 0 1 1 51.99 37 Z', NEUTRAL[0], NEUTRAL[1], k=4.5)
    p.hl('M36 56 Q37 47 44 43', 3)
    return p.body()


# ---- things that go together (LOG-A-09) ------------------------------------------------------------------------------

def plate():
    """A plate seen across the table: a wide ellipse with a blue band on the rim, a shallow well, its edge below."""
    p = Pic()
    p.shadow(50, 78, 44, 5)
    p.path('M6 58 A44 19 0 0 0 94 58 L94 54 L6 54 Z', '#DCD3EC')
    p.add('<ellipse cx="50" cy="54" rx="44" ry="19" fill="%s" stroke="%s" stroke-width="%s"/>' % (WHITE, INK, SW))
    p.add('<ellipse cx="50" cy="54" rx="37.5" ry="15" fill="none" stroke="#4DA3FF" stroke-width="2.4"/>')
    p.add('<ellipse cx="50" cy="55.5" rx="25" ry="9.5" fill="#F1EEF8" stroke="#CFC8E0" stroke-width="1.8"/>')
    p.add('<path d="M30 52 Q40 48 52 48" fill="none" stroke="#FFFFFF" stroke-width="2.6" stroke-linecap="round"/>')
    p.hl('M16 50 Q24 42 40 39', 2.6)
    return p.body()


def brush(over=''):
    """A toothbrush on a slant: a handle with a grip, a narrow neck, a head with bristle tufts standing up."""
    p = Pic()
    p.shadow(50, 84, 38, 3)
    g = Pic()
    handle = 'M4 56 C4 51 8 49 14 49 L56 50 C60 50 62 52 66 52 L74 52 L74 57 L66 57 C62 57 60 59 56 59 L14 60 C8 60 4 59 4 56 Z'
    g.n = 10
    g.shaded(handle, '#4DA3FF', '#2F7FE0', k=2)
    g.path('M16 52.5 L40 53 C42 53 42 56.5 40 56.5 L16 57 C13 57 13 52.5 16 52.5 Z', '#BFE3FF', sw=1.8)
    head = 'M72 50 C72 48 74 47 76 47 L94 47 C96 47 97 48.5 97 50.5 L97 56 C97 57.5 96 58.5 94 58.5 L76 58.5 C74 58.5 72 57.5 72 56 Z'
    g.shaded(head, '#4DA3FF', '#2F7FE0', k=1.5)
    for k, x in enumerate((75, 80, 85, 90)):
        g.path('M%s 47 L%s 33 C%s 31 %s 31 %s 33 L%s 47 Z' % (x, x, x, x + 4, x + 4, x + 4),
               '#FFFFFF' if k % 2 == 0 else '#CDEBFF', sw=1.8)
    g.add(over)
    p.add('<g transform="rotate(-22 50 52) translate(-2 4)">%s</g>' % g.body())
    return p.body()


def paste():
    """A toothpaste tube: the flat crimped end, the round body, the nozzle, a ribbon of paste, the cap lying by it."""
    p = Pic()
    p.shadow(52, 84, 40, 3)
    g = Pic()
    tube = 'M30 44 C34 40 40 38 46 38 L84 32 L84 68 L46 62 C40 62 34 60 30 56 Z'
    cid = g.shaded(tube, WHITE, '#E3DFEA', k=3, sw=0)
    g.clipped(cid, '<path d="M54 30 L66 30 L66 70 L54 70 Z" fill="#2F7FE0"/>'
                   '<path d="M70 30 L74 30 L74 70 L70 70 Z" fill="#4CC3A5"/>')
    g.path(tube, 'none')
    g.path('M82 30 L92 29 L92 71 L82 70 Z', '#E3DFEA')
    g.line('M85 32 V68 M88.5 31.5 V68.5', '#B8B3C8', 1.6)
    g.path('M22 45 L30 44 L30 56 L22 55 Z', '#E3DFEA')
    g.hl('M40 43 Q60 39 80 36', 2.6)
    # the paste: a white ribbon with a blue stripe coming out of the nozzle
    g.outlined_line('M22 50 C15 50 12 45 15 41 C18 37 24 39 23 34', WHITE, 7)
    g.line('M20 50.5 C15.5 50 13 46.5 15 42.5', '#4DA3FF', 2)
    p.add('<g transform="rotate(-10 50 50) translate(0 2)">%s</g>' % g.body())
    # the cap
    p.shaded('M12 74 H26 V86 C26 88 24 89 22 89 H16 C14 89 12 88 12 86 Z', '#2F7FE0', '#1F5DB0', k=2)
    p.line('M16 76 V86 M19 76 V86 M22 76 V86', '#BFE3FF', 1.3)
    return p.body()


def balloon(c, s):
    """A latex balloon: egg-shaped, wider at the top, a tied knot, a long wavy string."""
    p = Pic()
    p.line('M50 72 C44 78 56 82 50 88 C46 92 52 95 50 99', INK, 1.8)
    shape = 'M50 4 C66 4 77 17 77 32 C77 49 63 62 51.5 64.5 L48.5 64.5 C37 62 23 49 23 32 C23 17 34 4 50 4 Z'
    p.shaded(shape, c, s, k=5)
    p.path('M45.5 71 L50 64 L54.5 71 C52 72.6 48 72.6 45.5 71 Z', c, sw=2.4)
    p.add('<ellipse cx="38" cy="22" rx="5" ry="9" fill="%s" opacity="0.55" transform="rotate(25 38 22)"/>' % WHITE)
    return p.body()


def umbrella():
    """An open umbrella: a dome of panels in two colours with a scalloped edge, a tip, a shaft and a hooked handle."""
    p = Pic()
    p.shadow(50, 92, 22, 2.8)
    p.outlined_line('M50 40 L50 82 C50 92 38 92 38 84', '#8A5A2B', 3)
    edge = 'M6 52 Q17 44 28 52 Q39 44 50 52 Q61 44 72 52 Q83 44 94 52'
    dome = 'M6 52 C6 28 26 12 50 12 C74 12 94 28 94 52 ' + edge[edge.index('Q'):].replace('Q83 44 94 52', '')
    dome = ('M6 52 C6 28 26 12 50 12 C74 12 94 28 94 52 Q83 44 72 52 Q61 44 50 52 Q39 44 28 52 Q17 44 6 52 Z')
    cid = p.shaded(dome, '#FFC83D', '#E0A21A', k=4, sw=0)
    p.clipped(cid, '<path d="M50 12 L6 56 L28 56 Z" fill="#2F7FE0"/><path d="M50 12 L50 56 L72 56 Z" fill="#2F7FE0"/>'
                   '<path d="M50 12 L44 0 L20 0 L6 30 L6 56 Z" fill="#1F5DB0" opacity="0"/>')
    p.path(dome, 'none')
    p.line('M50 12 L28 52 M50 12 L50 52 M50 12 L72 52', INK, 1.8)
    p.line('M50 12 L50 5', INK, 3.4)
    p.hl('M16 38 Q24 24 38 18', 2.8)
    return p.body()


# ---- bins of LOG-B-08 (read at bin-card size) ------------------------------------------------------------------------

def bin_basket():
    """An empty woven basket seen from the front: an arched handle, a rolled rim with the dark opening, woven bands."""
    p = Pic()
    p.shadow(50, 92, 36, 3)
    p.outlined_line('M24 46 C24 10 76 10 76 46', '#B57B3F', 4)
    p.add('<ellipse cx="50" cy="46" rx="37" ry="8" fill="#7A4F26"/>')
    body = 'M14 47 C30 53 70 53 86 47 L79 86 C78.5 89 76.5 91 73 91 L27 91 C23.5 91 21.5 89 21 86 Z'
    cid = p.shaded(body, '#D9A066', '#B57B3F', k=3, sw=0)
    p.clipped(cid, ''.join('<path d="M10 %d Q50 %d 90 %d" fill="none" stroke="#B57B3F" stroke-width="2"/>' % (y, y + 5, y)
                           for y in (60, 70, 80)) +
              ''.join('<path d="M%d 50 L%d 92" fill="none" stroke="#C48A4E" stroke-width="1.6"/>' % (x, x + (50 - x) // 9)
                      for x in (26, 38, 50, 62, 74)))
    p.path(body, 'none')
    p.add('<ellipse cx="50" cy="46" rx="37" ry="8" fill="none" stroke="%s" stroke-width="%s"/>' % (INK, SW))
    p.path('M13 46 C13 41 87 41 87 46 C87 49 86 50 84 50', 'none', sw=0)
    p.add('<ellipse cx="50" cy="46" rx="37" ry="8" fill="none" stroke="#C98F52" stroke-width="2" opacity="0.9" '
          'transform="translate(0 -1.2)"/>')
    p.hl('M24 58 Q26 72 28 84', 2.4)
    return p.body()


def bin_grass():
    """A patch of lawn: a low green mound with a thick row of grass blades growing up from it and two daisies."""
    p = Pic()
    p.shadow(50, 90, 44, 3)
    blades = [(10, 22, -4), (17, 30, 2), (24, 24, -3), (31, 34, 3), (38, 27, -2), (45, 36, 2), (52, 29, -3),
              (59, 37, 3), (66, 28, -2), (73, 33, 3), (80, 25, -3), (87, 21, 2)]
    for x, h, lean in blades:  # the back row, darker
        base = 70
        p.path('M%s %s Q%s %s %s %s Q%s %s %s %s Z' % (x - 4, base, x - 3 + lean, base - h * 0.55, x + lean * 1.8,
                                                     base - h, x + 1 + lean, base - h * 0.5, x + 4, base), '#3E9A47', sw=2)
    mound = 'M4 78 C6 66 26 62 50 62 C74 62 94 66 96 78 C94 86 74 89 50 89 C26 89 6 86 4 78 Z'
    p.shaded(mound, '#7ED17F', '#5BB65E', k=3)
    for x, h, lean in ((12, 14, 2), (22, 18, -2), (34, 15, 3), (62, 16, -2), (76, 19, 2), (88, 13, -2)):
        base = 78
        p.path('M%s %s Q%s %s %s %s Q%s %s %s %s Z' % (x - 3, base, x - 2 + lean, base - h * 0.55, x + lean * 1.6,
                                                     base - h, x + 1 + lean, base - h * 0.5, x + 3, base), '#5BB65E', sw=1.8)
    for fx, fy, r in ((47, 70, 3.4), (70, 66, 2.8)):  # two daisies
        for dx, dy in ((0, -1), (0.95, -0.31), (0.59, 0.81), (-0.59, 0.81), (-0.95, -0.31)):
            p.add('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s" stroke="%s" stroke-width="1.3"/>'
                  % (fx + dx * r * 1.2, fy + dy * r * 1.2, r, WHITE, INK))
        p.add('<circle cx="%s" cy="%s" r="%.1f" fill="#FFC83D" stroke="%s" stroke-width="1.1"/>' % (fx, fy, r * 0.85, INK))
    p.hl('M16 72 Q30 66 46 66', 2.4)
    return p.body()


# ---- clue cards of LOG-B-09: a value under a "no" sign ---------------------------------------------------------------

def card(inner):
    p = Pic()
    p.add('<rect x="5" y="5" width="90" height="90" rx="16" fill="#FFFFFF" stroke="%s" stroke-width="%s"/>' % (INK, SW))
    p.add(inner)
    # the "no" sign: a ring and a slash, red with an ink edge so it reads over any colour, also in grey
    ring = '<circle cx="50" cy="50" r="36" fill="none" stroke="%s" stroke-width="%s"/>'
    slash = '<path d="M25.5 25.5 L74.5 74.5" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round"/>'
    p.add(ring % (INK, 8.5) + slash % (INK, 8.5) + ring % ('#E5484D', 4.6) + slash % ('#E5484D', 4.6))
    return p.body()


def clue_colour(c, s):
    """Not this colour: a crayon of the colour, slanted against the slash so both stay visible."""
    return card(crayon(50, 52, c, s, rot=38, scale=1.15))


def clue_shape(kind):
    p = Pic()
    d = {'circle': 'M50 30 A21 21 0 1 1 49.99 30 Z', 'square': 'M31 32 H69 V70 H31 Z', 'triangle': 'M50 27 L73 71 H27 Z',
         'shapes': None}[kind]
    if d:
        p.shaded(d, NEUTRAL[0], NEUTRAL[1], k=3.5)
    else:  # the generic card: the three shapes, small
        for dd in ('M30 36 A9 9 0 1 1 29.99 36 Z', 'M59 27 H77 V45 H59 Z', 'M50 52 L61 72 H39 Z'):
            p.shaded(dd, NEUTRAL[0], NEUTRAL[1], k=2)
    return card(p.body())


def clue_any_colour():
    """The generic colour card: three small crayons (some colour), under the sign."""
    inner = ''.join(crayon(cx, 54, *COLOURS[n], rot=0, scale=0.72) for cx, n in ((32, 'red'), (50, 'yellow'), (68, 'blue')))
    return card(inner)


CLUE_COLOURS = ('red', 'blue', 'green', 'yellow', 'orange')
CLUE_SHAPES = ('circle', 'square', 'triangle')


def mix(a, b, t):
    """The colour t of the way from a to b."""
    ca = [int(a[i:i + 2], 16) for i in (1, 3, 5)]
    cb = [int(b[i:i + 2], 16) for i in (1, 3, 5)]
    return '#%02X%02X%02X' % tuple(round(x + (y - x) * t) for x, y in zip(ca, cb))


def deep(c):
    """The shade tone of a fill (toward ink); white gets the soft lilac of the house style."""
    return '#E2DEEC' if c.upper() == WHITE else mix(c, INK, 0.24)


# ---- the Languages drawings at sprite size ---------------------------------------------------------------------------
#
# Things the Languages courses already draw (tools/make_language_pictures.py and _b2.py: a cat, a dog, a fish, an apple,
# a star, a ball, a frog, a sock, a spoon, a bowl, a pencil, an egg, rain, a rainbow, a butterfly, a banana) are the same
# drawing here, so a cat is one cat in the whole app. They are drawn on a 256 canvas for 64 points; here they are shown
# from 24 to 90 points, so the ink outline is made thicker (4 -> 7.5 units, the 3 units of this file at 100) and the
# picture is cropped a little closer (the 236 units from (10, 14)).

LANG_VIEW = (10, 14, 236)


def lang(name, colour=None, recolour=(), over='', view=LANG_VIEW, hues=None):
    """The body of a Languages picture on the 100 canvas. recolour: (old hex, new hex) pairs; over: more shapes in the
    256 units of the picture, drawn on top; hues: {colour: (fill, shade, band)} for the coloured sets (the ball)."""
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import make_language_pictures as lp
    import make_language_pictures_b2 as lb
    ink = lp.INK
    path0, line0, oline0 = lp.Pic.path, lp.Pic.line, lp.Pic.outlined_line
    hues0, band0 = dict(lp.HUES), dict(lp.BAND)

    def path(self, d, fill, sw=4, stroke=ink, op=None):
        return path0(self, d, fill, sw + 3.5 if stroke == ink and sw and sw >= 3 else sw, stroke, op)

    def line(self, d, color=ink, w=4, op=None):
        return line0(self, d, color, w + 3 if color == ink and w >= 3 else w, op)

    def outlined_line(self, d, color, w):
        line0(self, d, ink, w + 14)
        return line0(self, d, color, w)

    lp.Pic.path, lp.Pic.line, lp.Pic.outlined_line = path, line, outlined_line
    try:
        for c, (f, s, b) in (hues or {}).items():
            lp.HUES[c], lp.BAND[c] = (f, s), b
        table = dict(lp.OBJECTS)
        for part in lb.PARTS.values():
            table.update(part)
        table.update({k: v[0] for k, v in lp.COLOURED.items()})
        pic = table[name](colour) if colour else table[name]()
    finally:
        lp.Pic.path, lp.Pic.line, lp.Pic.outlined_line = path0, line0, oline0
        lp.HUES.clear(), lp.HUES.update(hues0), lp.BAND.clear(), lp.BAND.update(band0)
    body = ''.join(pic.parts).replace('id="c', 'id="L').replace('url(#c', 'url(#L')
    for old, new in recolour:
        body = re.sub(re.escape(old), new, body, flags=re.I)
    x, y, s = view
    return '<g transform="scale(%s) translate(%s %s)">%s%s</g>' % (round(100 / s, 5), -x, -y, body, over)


def ball(name):
    """The rubber play ball of the Languages courses (round, matte, a two-tone band), in the Colour Bay hues."""
    f, s = COLOURS[name]
    band = {'yellow': mix(f, '#F08A00', 0.4), 'white': '#E4E0EE', 'black': mix(f, WHITE, 0.2)}.get(name, mix(f, s, 0.75))
    return lang('ball', name, hues={name: (f, s, band)})


def sized(body, k):
    """The same drawing smaller, about the middle of the canvas (every size of a thing is drawn in one box)."""
    return '<g transform="translate(50 50) scale(%s) translate(-50 -50)">%s</g>' % (k, body)


# ---- the Riddle Grotto things still to draw (2026-11-06, second batch) --------------------------------------------------

def cloud():
    """One white cumulus cloud: a flat-ish base and four round puffs, the shade on the underside."""
    p = Pic()
    d = ('M18 74 C7 74 4 60 14 55 C11 42 24 34 35 40 C38 26 56 20 66 32 C76 26 90 34 88 47 C98 50 98 66 88 72 '
         'C86 74 84 74 82 74 Z')
    p.shaded(d, WHITE, '#D3DCEC', k=4.5)
    p.line('M24 66 Q50 70 80 66', '#D3DCEC', 2.2)
    p.hl('M26 48 Q30 41 37 42', 2.8)
    p.hl('M48 33 Q54 28 61 31', 2.6)
    return p.body()


def shoe():
    """A child's canvas sneaker from the side, toe to the left: white rubber sole and toe cap, laces over the tongue."""
    p = Pic()
    p.shadow(50, 88, 44, 3.2)
    upper = ('M8 70 C5 60 11 52 24 50 C36 48 46 42 52 33 L56 23 C58 19 63 19 65 23 C69 30 77 31 84 27 '
             'C88 25 92 27 92 32 L93 70 Z')
    cid = p.shaded(upper, '#E5484D', '#B8323A', k=3.5, sw=0)
    p.clipped(cid, '<path d="M0 72 C0 56 12 50 24 51 C27 58 27 66 24 72 Z" fill="#FFFFFF"/>'
                   '<path d="M24 51 C27 58 27 66 24 72" fill="none" stroke="%s" stroke-width="2"/>'
                   '<path d="M58 21 C63 30 76 33 90 28 L94 34 C78 38 64 36 56 26 Z" fill="#7A2A2E"/>'
                   '<path d="M86 30 L95 30 L95 52 L86 50 Z" fill="#B8323A"/>' % INK)
    p.path(upper, 'none')
    # the tongue and the laces: three white bars across the vamp, eyelets at their ends
    p.path('M50 34 C52 26 54 20 58 19 C60 22 60 30 58 38 Z', '#F07A7E', sw=2.2)
    for k in range(3):
        x, y = 34 + k * 7.5, 49 - k * 6.2
        p.outlined_line('M%.1f %.1f L%.1f %.1f' % (x - 4, y - 4, x + 5, y + 5), WHITE, 2.6)
    for k in range(3):
        x, y = 34 + k * 7.5, 49 - k * 6.2
        p.add('<circle cx="%.1f" cy="%.1f" r="1.4" fill="%s"/>' % (x + 5, y + 5, INK))
    sole = 'M4 70 H94 C96 70 97 72 97 74 V78 C97 81 95 83 92 83 H10 C6 83 4 80 4 77 Z'
    cid = p.shaded(sole, WHITE, '#E3DFEA', k=2)
    p.line('M8 76 H92', '#E5484D', 1.8)
    p.hl('M14 58 Q18 54 24 53', 2.2)
    p.hl('M62 36 Q72 38 82 34', 2)
    return p.body()


def key():
    """A brass door key, a little tilted: a round bow with a hole, a long shaft, the teeth under its end."""
    p = Pic()
    p.shadow(52, 82, 38, 3)
    g = Pic()
    g.n = 20
    g.shaded('M62 55 V65 H67 V61 H72 V67 H78 V61 H83 V65 H90 V55 Z', '#F2C14E', '#C99A2E', k=1.5)
    g.shaded('M36 45 H89 C91 45 92 46 92 48 V52 C92 54 91 55 89 55 H36 Z', '#F2C14E', '#C99A2E', k=2)
    ring = 'M10 50 A15 15 0 1 1 40 50 A15 15 0 1 1 10 50 Z'
    g.line(ring, INK, 15)
    g.line(ring, '#F2C14E', 9)
    g.line('M16.5 58 A9.6 9.6 0 0 0 34 56', '#C99A2E', 3)
    g.hl('M14 42 Q18 37 24 36', 2.6)
    g.hl('M44 48 H84', 2)
    p.add('<g transform="rotate(-18 50 50) translate(0 2)">%s</g>' % g.body())
    return p.body()


def lock():
    """A brass padlock: a steel shackle in a U, a rounded body, a keyhole."""
    p = Pic()
    p.shadow(50, 92, 32, 3)
    p.outlined_line('M33 52 V34 C33 14 67 14 67 34 V52', '#C9CFDD', 7)
    p.line('M30.5 34 C31 22 38 17 44 16', WHITE, 2, op=0.7)
    body = 'M18 52 C18 46 22 43 28 43 H72 C78 43 82 46 82 52 V80 C82 86 78 89 72 89 H28 C22 89 18 86 18 80 Z'
    p.shaded(body, '#FFC83D', '#E0A21A', k=4)
    p.line('M22 52 H78', '#E0A21A', 2)
    p.path('M45 75 L47.5 64 A6 6 0 1 1 52.5 64 L55 75 Z', INK, sw=0)
    p.hl('M25 58 V76', 3)
    return p.body()


def paper():
    """A sheet of writing paper, a little tilted: a folded corner and faint ruled lines (no writing)."""
    p = Pic()
    p.shadow(52, 92, 30, 3)
    g = Pic()
    sheet_d = 'M24 8 H68 L80 20 V90 H24 Z'
    cid = g.shaded(sheet_d, WHITE, '#E3DFEA', k=2.5, sw=0)
    g.clipped(cid, ''.join('<path d="M30 %d H74" stroke="#9CCBEA" stroke-width="2"/>' % y for y in (34, 46, 58, 70, 82)) +
              '<path d="M34 24 V90" stroke="#F4A3B4" stroke-width="1.6"/>')
    g.path(sheet_d, 'none')
    g.path('M68 8 V20 H80 Z', '#E3DFEA', sw=2.4)
    p.add('<g transform="rotate(-6 52 50)">%s</g>' % g.body())
    return p.body()


SOIL = ('#8A5A2B', '#66401C')


def soil(p):
    mound = 'M6 86 C12 74 32 68 50 68 C68 68 88 74 94 86 C94 91 90 93 84 93 H16 C10 93 6 91 6 86 Z'
    p.shadow(50, 94, 44, 2.6)
    p.shaded(mound, *SOIL, k=3)
    for x, y in ((24, 82), (40, 87), (62, 84), (76, 88), (52, 78)):
        p.add('<circle cx="%s" cy="%s" r="1.6" fill="#5A3818"/>' % (x, y))
    p.hl('M18 79 Q30 72 42 71', 2.2)


def plant_seed():
    """A bean seed lying in a little dip on a mound of soil (nothing has grown yet)."""
    p = Pic()
    soil(p)
    p.add('<ellipse cx="50" cy="69" rx="15" ry="3.4" fill="#4A2E14"/>')
    seed = 'M37 64 C36 55 46 51 54 53 C63 55 66 63 61 67 C56 71 39 71 37 64 Z'
    p.shaded(seed, '#E8C48A', '#C9965A', k=2)
    p.line('M47 60 Q51 58 55 60', '#A9743C', 1.8)
    p.hl('M42 59 Q45 55 50 55', 1.8)
    return p.body()


def stem(p, top):
    p.outlined_line('M50 72 C48 %s 52 %s 50 %s' % (top + 22, top + 12, top), '#5BB65E', 3.4)


def leaf(p, d):
    p.shaded(d, '#7ED17F', '#4CAF50', k=2)


def plant_sprout():
    """The seed has sprouted: a pale stem out of the soil and the two round seed leaves open at its top."""
    p = Pic()
    soil(p)
    stem(p, 42)
    leaf(p, 'M50 43 C42 30 26 30 20 38 C26 48 42 50 50 43 Z')
    leaf(p, 'M50 43 C58 30 74 30 80 38 C74 48 58 50 50 43 Z')
    p.line('M48 43 Q36 38 26 38 M52 43 Q64 38 74 38', '#4CAF50', 1.6)
    return p.body()


def plant_flower():
    """The plant has grown: a tall stem with two leaves and a pink flower with a yellow middle."""
    p = Pic()
    soil(p)
    stem(p, 26)
    leaf(p, 'M50 58 C42 48 28 48 22 54 C28 62 42 64 50 58 Z')
    leaf(p, 'M50 48 C58 38 72 38 78 44 C72 52 58 54 50 48 Z')
    import math
    for k in range(5):
        a = math.radians(-90 + 72 * k)
        cx, cy = round(50 + 10.5 * math.cos(a), 2), round(22 + 10.5 * math.sin(a), 2)
        p.shaded("M%.2f %.2f A8.5 8.5 0 1 1 %.2f %.2f Z" % (cx - 8.5, cy, cx - 8.5, cy + 0.02), '#F48FB1', '#D9668F', k=1.6)
    p.shaded('M43.5 22 A6.5 6.5 0 1 1 43.5 22.01 Z', '#FFD84D', '#E0A21A', k=1.4)
    return p.body()


def egg_crack():
    """The egg of the Languages courses with a zigzag crack round its middle (it is about to hatch)."""
    crack = ('<path d="M 54 150 L 78 138 L 94 156 L 114 134 L 130 154 L 150 134 L 168 152 L 186 138 L 202 148" fill="none" '
             'stroke="%s" stroke-width="7" stroke-linejoin="round" stroke-linecap="round"/>' % INK)
    return lang('egg', over=crack)


def tick():
    """Yes: a green disc with a white check mark (the check and the cross also differ in shape, not only in colour)."""
    p = Pic()
    p.shaded('M8 50 A42 42 0 1 1 92 50 A42 42 0 1 1 8 50 Z', '#4CAF50', '#2F8A3A', k=4)
    p.hl('M20 36 Q26 22 40 16', 3)
    p.outlined_line('M29 52 L44 66 L72 35', WHITE, 9)
    return p.body()


def cross():
    """Not the same: a red disc with a white cross."""
    p = Pic()
    p.shaded('M8 50 A42 42 0 1 1 92 50 A42 42 0 1 1 8 50 Z', '#E5484D', '#B8323A', k=4)
    p.hl('M20 36 Q26 22 40 16', 3)
    p.outlined_line('M34 34 L66 66 M66 34 L34 66', WHITE, 9)
    return p.body()


# ---- the shapes (Shape Forest, and the coloured shapes of Colour Bay and Riddle Grotto) ------------------------------
#
# The geometry is the old one, point for point (a triangle stays the same triangle); the house style adds the ink
# outline, a shade tone and, on the four basic shapes, a highlight. The fills are the old fills.

SHAPE_COLOURS = {'red': '#E5484D', 'blue': '#2F7FE0', 'green': '#4CAF50', 'yellow': '#FFC531', 'orange': '#FF9F43'}


def poly_d(n, r=38, rot=-90):
    import math
    pts = [(50 + r * math.cos(math.radians(rot + 360 * k / n)), 52 + r * math.sin(math.radians(rot + 360 * k / n)))
           for k in range(n)]
    return 'M' + ' L'.join('%.1f %.1f' % q for q in pts) + ' Z'


SHAPE_D = {
    'circle': ('M12 50 A38 38 0 1 1 88 50 A38 38 0 1 1 12 50 Z', 'M24 36 Q30 22 44 18'),
    'square': ('M14 18 C14 15.5 15.5 14 18 14 H82 C84.5 14 86 15.5 86 18 V82 C86 84.5 84.5 86 82 86 H18 C15.5 86 14 84.5 '
               '14 82 Z', 'M22 26 V44'),
    'triangle': ('M50 12 L90 84 H10 Z', 'M44 30 L30 56'),
    'rect': ('M6 32 C6 29.5 7.5 28 10 28 H90 C92.5 28 94 29.5 94 32 V68 C94 70.5 92.5 72 90 72 H10 C7.5 72 6 70.5 6 68 Z',
             'M14 38 V54'),
}


def shape(kind, fill):
    p = Pic()
    d, hl = SHAPE_D[kind]
    p.shaded(d, fill, deep(fill), k=4)
    p.hl(hl, 3.4)
    return p.body()


def shape_other(d, fill, k=3.5):
    p = Pic()
    p.shaded(d, fill, deep(fill), k=k)
    return p.body()


def shape_open():
    """Not a shape: a line that does not close (the old points; an ink edge round a red stroke)."""
    p = Pic()
    p.outlined_line('M12 84 L50 14 L88 84 L24 84', '#E5484D', 7)
    return p.body()


def shape_bodies():
    out = {}
    for kind in ('circle', 'square', 'triangle', 'rect'):
        for name, c in SHAPE_COLOURS.items():
            out['shape_%s_%s' % (kind, name)] = shape(kind, c)
    out.update({'shape_circle': shape('circle', '#E5484D'), 'shape_square': shape('square', '#2F7FE0'),
                'shape_triangle': shape('triangle', '#4CAF50'), 'shape_rect': shape('rect', '#FF9F43')})
    out['shape_square_tilt'] = '<g transform="rotate(45 50 50)">%s</g>' % shape_other(SHAPE_D['square'][0], '#2F7FE0')
    out['shape_triangle_thin'] = shape_other('M50 6 L66 92 H34 Z', '#4CAF50', k=2.5)
    out['shape_triangle_down'] = shape_other('M10 16 H90 L50 88 Z', '#4CAF50')
    out['shape_pentagon'] = shape_other(poly_d(5), '#9B6BDF')
    out['shape_hexagon'] = shape_other(poly_d(6), '#FF9F43')
    out['shape_quad'] = shape_other(poly_d(4, 40, -45), '#4CAF50')
    out['shape_curved'] = shape_other('M12 84 Q50 -10 88 84 Z', '#4DA3FF')
    out['shape_open'] = shape_open()
    return out


# ---- Counting Hills ---------------------------------------------------------------------------------------------------

def ladybug():
    """A seven-spot ladybird seen from above, head up: a red dome split down the middle, three black spots on each wing
    case and one on the seam, a black head shield with two white patches, a little face, six short legs."""
    p = Pic()
    p.shadow(50, 92, 30, 3)
    for side in (-1, 1):
        for y, dx in ((44, 6), (60, 8), (76, 6)):
            p.line('M%s %s L%s %s' % (50 + side * 30, y, 50 + side * (36 + dx), y + 4 * (1 if y > 50 else -1)), INK, 3)
    p.line('M44 18 Q40 10 34 8 M56 18 Q60 10 66 8', INK, 2.4)
    p.add('<circle cx="34" cy="8" r="2.4" fill="%s"/><circle cx="66" cy="8" r="2.4" fill="%s"/>' % (INK, INK))
    p.shaded('M33 26 C33 16 41 12 50 12 C59 12 67 16 67 26 C67 32 60 34 50 34 C40 34 33 32 33 26 Z', '#3A3650', '#22202F',
             k=2)
    p.eye(43.5, 22, 2.6)
    p.eye(56.5, 22, 2.6)
    p.path('M47 28 Q50 30.5 53 28', 'none', sw=1.8, stroke=WHITE)
    shell = 'M18 58 C18 38 32 30 50 30 C68 30 82 38 82 58 C82 78 68 92 50 92 C32 92 18 78 18 58 Z'
    cid = p.shaded(shell, '#E5484D', '#B8323A', k=4, sw=0)
    spots = ((50, 36, 6), (33, 48, 6), (67, 48, 6), (28, 66, 6.5), (72, 66, 6.5), (40, 81, 5.5), (60, 81, 5.5))
    p.clipped(cid, ''.join('<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % (x, y, r, INK) for x, y, r in spots) +
              '<path d="M38 33 C40 31 42 31 44 33 M56 33 C58 31 60 31 62 33" stroke="#FFFFFF" stroke-width="2.6" '
              'fill="none" stroke-linecap="round"/>')
    p.path(shell, 'none')
    p.line('M50 31 V91', INK, 2.6)
    p.hl('M25 52 Q28 41 38 36', 3)
    return p.body()


def flower_target():
    """The big flower the butterflies fly to (160 x 200): a tall stem, two leaves, six pink petals, a yellow middle."""
    import math
    p = Pic()
    p.add('<ellipse cx="80" cy="196" rx="34" ry="3.4" fill="%s" opacity="0.13"/>' % INK)
    p.outlined_line('M80 100 Q88 150 80 194', '#3E9A47', 6)
    p.shaded('M84 150 C96 132 120 132 128 142 C118 156 98 160 84 150 Z', '#5BB65E', '#3E9A47', k=3, sw=4)
    p.shaded('M80 172 C68 156 44 156 36 166 C46 180 66 182 80 172 Z', '#5BB65E', '#3E9A47', k=3, sw=4)
    for k in range(6):
        a = math.radians(-90 + 60 * k)
        cx, cy = 80 + 29 * math.cos(a), 62 + 29 * math.sin(a)
        p.shaded("M%.2f %.2f A21 21 0 1 1 %.2f %.2f Z" % (cx - 21, cy, cx - 21, cy + 0.02), '#FF8EC0', '#E0609E', k=4, sw=4)
    p.shaded('M60 62 A20 20 0 1 1 60 62.01 Z', '#FFD84D', '#E0A21A', k=3, sw=4)
    for x, y in ((74, 56), (86, 58), (80, 68), (72, 66), (88, 67)):
        p.add('<circle cx="%s" cy="%s" r="2" fill="#E0A21A"/>' % (x, y))
    p.add('<path d="M64 34 Q68 22 80 19" fill="none" stroke="#FFFFFF" stroke-width="4.4" stroke-linecap="round" '
          'opacity="0.55"/>')
    return p.body()


def scene_svg(body):
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 225" width="400" height="225">%s</svg>\n' % body


def nest_empty():
    """An empty bird's nest on a branch, against the sky (the picture of none: nothing in the nest)."""
    p = Pic()
    p.add('<rect width="400" height="225" fill="#CDEBFF"/>'
          '<path d="M0 182 C110 170 290 170 400 182 V225 H0 Z" fill="#A8DC8C"/>'
          '<path d="M0 196 C120 188 280 188 400 196 V225 H0 Z" fill="#8CCB6B"/>')
    p.outlined_line('M-10 160 C80 150 190 160 260 156 C300 154 330 146 360 132', '#8A5A2B', 10)
    p.outlined_line('M300 151 C316 162 330 166 346 164', '#8A5A2B', 6)
    p.shaded('M340 160 C352 150 370 150 376 158 C368 168 352 170 340 160 Z', '#7ED17F', '#4CAF50', k=3, sw=3.6)
    p.shaded('M246 130 C260 118 280 120 284 130 C274 140 256 140 246 130 Z', '#7ED17F', '#4CAF50', k=3, sw=3.6)
    nest = 'M110 118 C112 156 150 168 200 168 C250 168 288 156 290 118 C258 128 142 128 110 118 Z'
    cid = p.shaded(nest, '#B9844B', '#8A5A2B', k=6, sw=0)
    p.clipped(cid, ''.join('<path d="M%d %d Q%d %d %d %d" fill="none" stroke="%s" stroke-width="3" stroke-linecap="round"/>'
                           % (x, y, x + 40, y + 12, x + 86, y - 2, c)
                           for x, y, c in ((104, 132, '#7A4F26'), (150, 142, '#D9A066'), (96, 150, '#D9A066'),
                                           (200, 128, '#7A4F26'), (180, 156, '#7A4F26'), (226, 146, '#D9A066'),
                                           (120, 160, '#7A4F26'), (240, 132, '#D9A066'))))
    p.path(nest, 'none', sw=4.5)
    p.add('<ellipse cx="200" cy="118" rx="90" ry="15" fill="#5E3B1A" stroke="%s" stroke-width="4.5"/>' % INK)
    p.add('<ellipse cx="200" cy="122" rx="70" ry="9" fill="#4A2E14"/>')
    for x0, y0, x1, y1 in ((108, 116, 92, 104), (126, 110, 118, 96), (272, 110, 286, 98), (290, 118, 308, 110),
                           (160, 106, 152, 98), (238, 106, 248, 98)):
        p.outlined_line('M%d %d L%d %d' % (x0, y0, x1, y1), '#B9844B', 3.4)
    p.add('<path d="M130 112 Q160 104 196 104" fill="none" stroke="#D9A066" stroke-width="3.4" stroke-linecap="round"/>')
    p.hl('M126 140 Q140 156 170 162', 4)
    return p.body()


def bowl_empty():
    """An empty bowl on a kitchen table (nothing in it). Kept in the band the phone's stage shows (y 35 to 190)."""
    p = Pic()
    p.add('<rect width="400" height="225" fill="#FFF1CC"/>'
          '<path d="M0 150 H400 V225 H0 Z" fill="#E7C98F"/><path d="M0 150 H400 V158 H0 Z" fill="#F2DCAE"/>')
    p.add('<g transform="translate(85 -26) scale(2.3)">%s</g>' % lang('bowl'))
    return p.body()


def basket_empty():
    """An empty woven basket on the grass (the bin_basket drawing: its dark opening shows there is nothing in it)."""
    p = Pic()
    p.add('<rect width="400" height="225" fill="#E6F6D8"/>'
          '<path d="M0 156 C120 148 280 148 400 156 V225 H0 Z" fill="#8CCB6B"/>')
    p.add('<g transform="translate(98 -18) scale(2.04)">%s</g>' % bin_basket())
    return p.body()


# ---- Market Village and the maths things (measure, weigh, time, days) ---------------------------------------------------

def block():
    """A wooden toy block seen from the front, for the balance: square, a sunk panel, the shade on its lower right."""
    p = Pic()
    face = 'M14 22 C14 17 17 14 22 14 H78 C83 14 86 17 86 22 V78 C86 83 83 86 78 86 H22 C17 86 14 83 14 78 Z'
    p.shaded(face, '#FFC83D', '#E0A21A', k=5)
    p.path('M29 33 C29 30.5 30.5 29 33 29 H67 C69.5 29 71 30.5 71 33 V67 C71 69.5 69.5 71 67 71 H33 C30.5 71 29 69.5 29 67 Z',
           '#FFE08A', sw=2.2, stroke='#E0A21A')
    p.hl('M21 30 V52', 3)
    return p.body()


def day(n):
    """A page of a wall calendar with n dots (one for each day): two rings at the top, a blue band, no numerals."""
    p = Pic()
    p.shadow(50, 95, 34, 2.4)
    card = 'M10 22 C10 19 12 17 15 17 H85 C88 17 90 19 90 22 V87 C90 90 88 92 85 92 H15 C12 92 10 90 10 87 Z'
    cid = p.shaded(card, WHITE, '#E3DFEA', k=2.5, sw=0)
    p.clipped(cid, '<path d="M0 0 H100 V35 H0 Z" fill="#4DA3FF"/><path d="M0 35 H100 V37 H0 Z" fill="#2F7FE0"/>')
    p.path(card, 'none')
    for x in (30, 70):
        p.outlined_line('M%d 12 V25' % x, '#C9CFDD', 3.4)
    for k in range(n):
        p.add('<circle cx="%d" cy="%d" r="6.2" fill="%s"/>' % (23 + (k % 4) * 18, 52 + (k // 4) * 22, INK))
    return p.body()


def clock(hour):
    """A wall clock at an hour: a blue rim, twelve marks, the long hand up at 12, the short thick hand on the hour. Never
    mirrored (the hands turn clockwise in the picture as on a real clock); no numerals (the app draws them if needed)."""
    import math
    p = Pic()
    p.shaded('M4 50 A46 46 0 1 1 96 50 A46 46 0 1 1 4 50 Z', '#2F7FE0', '#1F5DB0', k=3.5)
    p.shaded('M12 50 A38 38 0 1 1 88 50 A38 38 0 1 1 12 50 Z', WHITE, '#E9E5F2', k=2.5, sw=2.2)
    for k in range(12):
        a = math.radians(k * 30)
        r0 = 28 if k % 3 == 0 else 31
        p.line('M%.1f %.1f L%.1f %.1f' % (50 + r0 * math.sin(a), 50 - r0 * math.cos(a), 50 + 34 * math.sin(a),
                                          50 - 34 * math.cos(a)), INK, 3.2 if k % 3 == 0 else 2.2)
    a = math.radians(hour % 12 * 30)
    p.outlined_line('M50 50 L%.1f %.1f' % (50 + 18 * math.sin(a), 50 - 18 * math.cos(a)), '#E5484D', 5.5)
    p.outlined_line('M50 50 L50 20', '#4DA3FF', 3)
    p.add('<circle cx="50" cy="50" r="4.6" fill="%s"/><circle cx="48.8" cy="48.8" r="1.4" fill="%s"/>' % (INK, WHITE))
    p.hl('M16 34 Q22 20 36 13', 3)
    return p.body()


def time_card(sky, inner):
    p = Pic()
    card = 'M4 14 C4 8 8 4 14 4 H86 C92 4 96 8 96 14 V86 C96 92 92 96 86 96 H14 C8 96 4 92 4 86 Z'
    p.n = 1
    p.add('<clipPath id="tc"><path d="%s"/></clipPath>' % card)
    p.add('<g clip-path="url(#tc)"><path d="M0 0 H100 V100 H0 Z" fill="%s"/>%s</g>' % (sky, inner))
    p.path(card, 'none')
    return p.body()


def sun_disc(cx, cy, r, fill='#FFC83D', shade='#E0A21A', rays=True):
    import math
    p = Pic()
    p.n = 40
    if rays:
        for k in range(8):
            a = math.radians(k * 45 + 22.5)
            p.line('M%.1f %.1f L%.1f %.1f' % (cx + (r + 4) * math.cos(a), cy + (r + 4) * math.sin(a),
                                              cx + (r + 9) * math.cos(a), cy + (r + 9) * math.sin(a)), fill, 3.4)
    p.shaded('M%s %s A%s %s 0 1 1 %s %s Z' % (cx - r, cy, r, r, cx - r, cy + 0.01), fill, shade, k=2.5, sw=2.6)
    return p.body()


def time_morning():
    """Morning: a pale peach sky, the sun just up over the hills on the left."""
    return time_card('#FFE3C2', '<path d="M0 0 H100 V60 H0 Z" fill="#FFD9A8" opacity="0.0"/>' + sun_disc(28, 66, 14) +
                     '<path d="M0 70 C24 62 52 64 100 74 V100 H0 Z" fill="#8CCB6B"/>'
                     '<path d="M0 82 C40 74 70 76 100 84 V100 H0 Z" fill="#6FB85A"/>')


def time_noon():
    """Noon: a blue sky, the sun high in the middle, one small cloud."""
    cloud_d = 'M60 46 C56 46 55 41 59 40 C59 35 65 33 68 36 C70 31 78 31 80 36 C84 35 88 38 86 42 C89 43 88 46 85 46 Z'
    return time_card('#8FD3F4', sun_disc(50, 28, 13) +
                     '<path d="%s" fill="#FFFFFF" stroke="%s" stroke-width="2.4" stroke-linejoin="round"/>' % (cloud_d, INK) +
                     '<path d="M0 76 C30 70 70 70 100 76 V100 H0 Z" fill="#8CCB6B"/>'
                     '<path d="M0 86 C40 80 70 82 100 88 V100 H0 Z" fill="#6FB85A"/>')


def time_evening():
    """Evening: an orange sky, the sun going down behind the hills on the right."""
    return time_card('#FFB38A', '<path d="M0 40 H100 V100 H0 Z" fill="#FFC9A0"/>' +
                     sun_disc(72, 68, 14, '#FF8A3D', '#D9692A', rays=False) +
                     '<path d="M0 72 C40 64 70 66 100 72 V100 H0 Z" fill="#6E9F58"/>'
                     '<path d="M0 84 C30 78 70 78 100 86 V100 H0 Z" fill="#5A8A48"/>')


def time_night():
    """Night: a dark blue sky, a crescent moon and stars, dark hills."""
    stars = ''.join('<path d="M%s %s l1.4 3.4 3.4 1.4 -3.4 1.4 -1.4 3.4 -1.4 -3.4 -3.4 -1.4 3.4 -1.4 Z" fill="#FFF3C2"/>'
                    % (x, y - 4.8) for x, y in ((22, 22), (36, 48), (82, 58), (14, 54), (50, 16)))
    moon = 'M70 14 C58 16 52 28 56 40 C60 50 72 54 82 50 C72 48 64 40 64 30 C64 22 66 17 70 14 Z'
    return time_card('#2B3A6B', stars + '<path d="%s" fill="#FFF3C2" stroke="%s" stroke-width="2.6" stroke-linejoin="round"/>'
                     % (moon, INK) + '<path d="M0 76 C30 70 70 70 100 78 V100 H0 Z" fill="#3E5A48"/>'
                     '<path d="M0 88 C40 82 70 84 100 90 V100 H0 Z" fill="#2F4A3A"/>')


def coin():
    """A plain gold coin (not a real one; the Israeli coins are make_coin_sprites.py): a rim, a raised ring, a shine."""
    p = Pic()
    p.shaded('M10 50 A40 40 0 1 1 90 50 A40 40 0 1 1 10 50 Z', '#FFC83D', '#E0A21A', k=4)
    p.add('<circle cx="50" cy="50" r="29" fill="none" stroke="#E0A21A" stroke-width="3"/>'
          '<circle cx="50" cy="50" r="31.5" fill="none" stroke="#FFE08A" stroke-width="1.6"/>')
    p.hl('M22 38 Q28 24 42 19', 3.2)
    return p.body()


def stick(x0, x1):
    """A straight wooden stick from x0 to x1 (the lengths are the teaching: the long one 92, the short one 44 units),
    bark lines along it and the pale cut wood at both ends."""
    p = Pic()
    p.shadow((x0 + x1) / 2, 64, (x1 - x0) / 2, 2.4)
    d = 'M%s 44 H%s C%s 44 %s 47 %s 50 C%s 53 %s 56 %s 56 H%s C%s 56 %s 53 %s 50 C%s 47 %s 44 %s 44 Z' % (
        x0 + 3, x1 - 3, x1 - 1, x1, x1, x1, x1 - 1, x1 - 3, x0 + 3, x0 + 1, x0, x0, x0, x0 + 1, x0 + 3)
    cid = p.shaded(d, '#C98F52', '#9E6A35', k=1.5, sw=0)
    p.clipped(cid, '<path d="M%s 48 H%s M%s 52.5 H%s" stroke="#9E6A35" stroke-width="1.4" stroke-dasharray="9 5"/>'
              % (x0 + 6, x1 - 8, x0 + 12, x1 - 4))
    p.path(d, 'none', sw=2.6)
    p.add('<ellipse cx="%s" cy="50" rx="2.2" ry="4.4" fill="#F2D7A6" stroke="%s" stroke-width="1.6"/>' % (x1 - 2.4, INK))
    p.hl('M%s 46.5 H%s' % (x0 + 6, x0 + (x1 - x0) * 0.45), 1.6)
    return p.body()


def stone():
    """A heavy grey stone: a rounded lump lying on the ground, a few specks."""
    p = Pic()
    p.shadow(50, 81, 40, 3.4)
    d = 'M12 72 C8 54 24 36 44 32 C64 28 82 36 89 52 C95 66 88 78 74 80 L24 81 C17 81 13 78 12 72 Z'
    p.shaded(d, '#9AA0B4', '#6E7488', k=4.5)
    for x, y, r in ((36, 58, 2), (58, 50, 1.6), (70, 66, 2.2), (46, 70, 1.4), (26, 66, 1.4)):
        p.add('<circle cx="%s" cy="%s" r="%s" fill="#767C92"/>' % (x, y, r))
    p.hl('M24 52 Q30 40 44 37', 3.2)
    return p.body()


def feather():
    """A light feather: a curved shaft, a soft vane on both sides with two little splits."""
    p = Pic()
    p.shadow(50, 90, 30, 2.4)
    vane = ('M22 84 C14 66 22 40 44 24 C56 15 70 11 80 10 C82 20 80 34 72 46 L64 46 C66 52 60 60 52 64 L46 62 '
            'C44 70 34 80 22 84 Z')
    p.shaded(vane, '#CDEBFF', '#9CCBEA', k=3)
    p.line('M16 92 C30 70 50 40 80 10', '#7FB6D9', 2.6)
    p.line('M16 92 L22 84', INK, 2.6)
    p.hl('M30 52 Q36 38 48 28', 2.6)
    return p.body()


def banana(fill, shade, stripe):
    return lang('banana', recolour=(('#FFD84D', fill), ('#E5B52A', shade), ('#E0B02A', stripe)))


# ---- Colour Bay: flowers, shades, the sun --------------------------------------------------------------------------------
#
# The petals and the shade discs keep the exact hex of their colour (COLOURS, and the two flower_* files' own red #D62F2F
# and yellow #FFD43B): the colour is the content. The shade discs get no shade crescent (a darker edge would change the
# shade being taught), only the outline and a highlight.

def flower_head(p, cx, cy, petal, shade, centre, r=11.5, dist=13.5):
    import math
    for k in range(5):
        a = math.radians(-90 + 72 * k)
        x, y = round(cx + dist * math.cos(a), 2), round(cy + dist * math.sin(a), 2)
        p.shaded('M%.2f %.2f A%s %s 0 1 1 %.2f %.2f Z' % (x - r, y, r, r, x - r, y + 0.02), petal, shade, k=2)
    p.shaded('M%.2f %.2f A8.5 8.5 0 1 1 %.2f %.2f Z' % (cx - 8.5, cy, cx - 8.5, cy + 0.02), centre, deep(centre), k=1.6)
    p.hl('M%s %s Q%s %s %s %s' % (cx - 5, cy - 2, cx - 4, cy - 5, cx - 1, cy - 6), 1.8)


def bloom(petal, shade=None, centre='#FFD84D'):
    """A garden flower: a green stem with a leaf, five round petals in the colour, a round middle."""
    p = Pic()
    p.shadow(50, 95, 18, 2.4)
    p.outlined_line('M50 50 Q54 74 50 94', '#4CAF50', 4)
    p.shaded('M52 76 C60 64 76 64 82 70 C76 80 62 84 52 76 Z', '#6BCB6E', '#4CAF50', k=2)
    p.line('M54 75 Q66 70 78 70', '#4CAF50', 1.6)
    flower_head(p, 50, 34, petal, shade or deep(petal), '#FF9F43' if petal.upper() in ('#FFD84D', '#FFD43B') else centre,
                r=13, dist=15.5)
    return p.body()


def shade_disc(c):
    """One shade of a colour, as a round dab of paint: the exact colour, an ink outline, a highlight."""
    p = Pic()
    p.add('<circle cx="50" cy="50" r="38" fill="%s" stroke="%s" stroke-width="%s"/>' % (c, INK, SW))
    p.hl('M24 40 Q28 26 42 20', 3.4)
    return p.body()


# ---- Shape Forest: solids, positions, lines, a window and a sign ----------------------------------------------------------

def solid_box():
    """A box (cuboid) seen from above a corner: the light top, the left and right faces in two shades."""
    p = Pic()
    p.shadow(50, 92, 36, 3)
    p.path('M50 10 L88 28 L50 46 L12 28 Z', '#E0B070')
    p.path('M12 28 L50 46 L50 90 L12 72 Z', '#C98F52')
    p.path('M88 28 L50 46 L50 90 L88 72 Z', '#A8743C')
    p.hl('M24 29 L48 18', 2.6)
    return p.body()


def solid_cone():
    """A cone: a point on top, a round base seen a little from above."""
    p = Pic()
    p.shadow(50, 88, 36, 3)
    body = 'M50 10 L84 80 A34 10 0 0 1 16 80 Z'
    cid = p.shaded(body, '#E5484D', '#B02A2E', k=6, sw=0)
    p.clipped(cid, '<path d="M50 10 L84 80 A34 10 0 0 1 60 89 Z" fill="#B02A2E" opacity="0.45"/>')
    p.path(body, 'none')
    p.hl('M42 30 L28 64', 3)
    return p.body()


def solid_cylinder():
    """A cylinder standing up: the light round top, the straight side, the round bottom edge."""
    p = Pic()
    p.shadow(50, 90, 36, 3)
    side = 'M20 24 V76 A30 10 0 0 0 80 76 V24 Z'
    cid = p.shaded(side, '#4DA3FF', '#2F7FE0', k=5, sw=0)
    p.clipped(cid, '<path d="M64 20 H84 V92 H64 Z" fill="#2F7FE0" opacity="0.5"/>')
    p.path(side, 'none')
    p.add('<ellipse cx="50" cy="24" rx="30" ry="10" fill="#9ED0EC" stroke="%s" stroke-width="%s"/>' % (INK, SW))
    p.hl('M28 38 V70', 3)
    return p.body()


def solid_sphere():
    """A ball-shaped solid: round from every side, the shade low on the right, a highlight."""
    p = Pic()
    p.shadow(50, 91, 30, 3)
    p.shaded('M12 50 A38 38 0 1 1 88 50 A38 38 0 1 1 12 50 Z', '#9B6BDF', '#7246B8', k=7)
    p.add('<ellipse cx="36" cy="34" rx="9" ry="6" fill="#FFFFFF" opacity="0.55" transform="rotate(-30 36 34)"/>')
    return p.body()


def solid_pyramid():
    """A pyramid on a square base, seen from a corner: two faces, the lit one and the shaded one."""
    p = Pic()
    p.shadow(50, 92, 38, 3)
    p.path('M50 10 L10 78 L50 90 Z', '#FFC531')
    p.path('M50 10 L90 78 L50 90 Z', '#E39A00')
    p.hl('M44 26 L24 62', 2.6)
    return p.body()


def red_ball(cx, cy, r):
    """The red ball of the position pictures (a plain play ball: round, a band, a highlight)."""
    p = Pic()
    p.n = int(cx * 7 + cy)
    d = 'M%s %s A%s %s 0 1 1 %s %s A%s %s 0 1 1 %s %s Z' % (cx - r, cy, r, r, cx + r, cy, r, r, cx - r, cy)
    cid = p.shaded(d, '#E5484D', '#B8323A', k=r * 0.14, sw=0)
    p.clipped(cid, '<path d="M%s %s Q%s %s %s %s L%s %s Q%s %s %s %s Z" fill="#C93A40"/>' % (
        cx - r, cy - r * 0.15, cx, cy + r * 0.45, cx + r, cy - r * 0.25, cx + r, cy + r * 0.2, cx, cy + r * 0.9, cx - r,
        cy + r * 0.3))
    p.path(d, 'none')
    p.hl('M%s %s Q%s %s %s %s' % (cx - r * 0.6, cy - r * 0.2, cx - r * 0.5, cy - r * 0.6, cx - r * 0.1, cy - r * 0.7),
         max(2, r * 0.16))
    return p.body()


def crate(x, y, w, h):
    """A wooden crate: planks across its front, the shade on the right."""
    p = Pic()
    p.n = int(x * 3 + y * 5 + w)
    d = 'M%s %s H%s V%s H%s Z' % (x, y, x + w, y + h, x)
    cid = p.shaded(d, '#C98F52', '#A8743C', k=3, sw=0)
    p.clipped(cid, ''.join('<path d="M%s %s H%s" stroke="#A8743C" stroke-width="2"/>' % (x, yy, x + w)
                           for yy in [y + h * f for f in (0.36, 0.68)]) +
              '<path d="M%s %s H%s" stroke="#E0B070" stroke-width="3"/>' % (x, y + 2, x + w))
    p.path(d, 'none')
    return p.body()


def pos_on():
    """On: the ball on top of the crate."""
    return Pic().shadow(50, 94, 40, 3).body() + crate(14, 58, 72, 34) + red_ball(50, 40, 18)


def pos_under():
    """Under: the ball under a little table."""
    p = Pic()
    p.shadow(50, 93, 42, 3)
    p.add(red_ball(50, 74, 16))
    p.path('M14 38 H21 V90 H14 Z', '#8A5A2B')
    p.path('M79 38 H86 V90 H79 Z', '#8A5A2B')
    p.shaded('M8 32 C8 30.5 9.5 29 11 29 H89 C90.5 29 92 30.5 92 32 V38 C92 39.5 90.5 40 89 40 H11 C9.5 40 8 39.5 8 38 Z',
             '#A9743C', '#8A5A2B', k=1.5)
    p.hl('M16 32.5 H60', 2)
    return p.body()


def pos_in():
    """In: the ball inside an open box, its lower half hidden by the front."""
    p = Pic()
    p.shadow(50, 94, 40, 3)
    p.add('<path d="M14 48 H86 L84 52 H16 Z" fill="#7A4F26"/>')
    p.add(red_ball(50, 46, 20))
    d = 'M12 48 H88 L80 92 H20 Z'
    cid = p.shaded(d, '#C98F52', '#A8743C', k=3, sw=0)
    p.clipped(cid, '<path d="M0 64 H100 M0 78 H100" stroke="#A8743C" stroke-width="2"/>'
                   '<path d="M0 50 H100" stroke="#E0B070" stroke-width="3"/>')
    p.path(d, 'none')
    return p.body()


def pos_next():
    """Next to: the ball beside the crate, both on the ground."""
    return Pic().shadow(50, 94, 44, 3).body() + crate(8, 52, 40, 40) + red_ball(74, 74, 18)


def pos_above():
    """Above: the ball high over the crate, not touching it (its shadow on the crate shows it floats)."""
    p = Pic()
    p.shadow(50, 94, 40, 3)
    p.add(crate(14, 62, 72, 30))
    p.add('<ellipse cx="50" cy="63" rx="12" ry="2.4" fill="%s" opacity="0.18"/>' % INK)
    p.add(red_ball(50, 20, 14))
    return p.body()


def line_pic(d, colour):
    """A line of the line pictures: the old path, a stroke with an ink edge."""
    p = Pic()
    p.outlined_line(d, colour, 8)
    return p.body()


def window():
    """A window seen from inside: a wooden frame with a cross bar, four panes of sky with a cloud, a sill."""
    p = Pic()
    p.add('<path d="M13 17 H87 V83 H13 Z" fill="#CDEBFF"/>')
    p.add('<path d="M56 34 C53 34 52 30 55 29 C55 25 60 24 62 27 C64 23 70 24 70 28 C73 28 74 33 71 34 Z" fill="#FFFFFF"/>')
    p.line('M20 60 L34 46 M24 70 L44 50', WHITE, 2.4, op=0.7)
    frame = ('M10 14 H90 V86 H10 Z M15 19 V47.5 H47.5 V19 Z M52.5 19 V47.5 H85 V19 Z M15 52.5 V81 H47.5 V52.5 Z '
             'M52.5 52.5 V81 H85 V52.5 Z')
    p.add('<path d="%s" fill="#A9743C" fill-rule="evenodd" stroke="%s" stroke-width="2.6" stroke-linejoin="round"/>' % (frame, INK))
    p.path('M6 86 H94 V92 C94 93 93 94 92 94 H8 C7 94 6 93 6 92 Z', '#C98F52', sw=2.6)
    p.hl('M13 22 V44', 1.8)
    return p.body()


def sign():
    """A warning sign: a yellow triangle with rounded corners, an orange edge and a big exclamation mark (two shapes, not
    a letter)."""
    p = Pic()
    d = 'M50 10 L92 84 H8 Z'
    p.add('<path d="%s" fill="#E39A00" stroke="%s" stroke-width="14" stroke-linejoin="round"/>' % (d, INK))
    p.add('<path d="%s" fill="#FFC531" stroke="#E39A00" stroke-width="8" stroke-linejoin="round"/>' % d)
    p.path('M46 38 C46 35.5 48 34 50 34 C52 34 54 35.5 54 38 L52.5 62 C52.4 63.6 51.4 64.5 50 64.5 C48.6 64.5 47.6 63.6 '
           '47.5 62 Z', INK, sw=0)
    p.add('<circle cx="50" cy="73" r="4.6" fill="%s"/>' % INK)
    return p.body()


# ---- Robot Harbour ---------------------------------------------------------------------------------------------------------

def robot():
    """The robot of the paths: a plain toy robot, nobody in particular (the owner, 2026-11-07: not Tza'adon the
    Robot Harbour host, and nothing that reads as him). A wind-up tin toy seen from the front, so it never faces a way
    on the path: a boxy silver head with a red ball on its antenna and a bolt-plate at each side, two round lens eyes
    and a small light grille mouth, a ribbed neck, a box body with a cream panel holding a dial and two lights,
    ribbed arms hanging down to orange pincer claws, two short legs on orange boots. Tza'adon is blue and rounded,
    with a dark screen face, cyan eyes, a sprout, round ears and the circle, triangle and square buttons; this robot
    has none of them. The character file design/assets/tzaadon.svg is not changed."""
    import math
    p = Pic()
    steel, steel_d = '#D3D8E3', '#A3AABD'
    org, org_d = '#FF9F43', '#D9762A'
    p.shadow(50, 95, 27, 2.8)
    # legs and boots
    for x in (37, 54):
        p.shaded('M%s 76 H%s V89 H%s Z' % (x, x + 9, x), steel, steel_d, k=1.5, sw=2.4)
        p.line('M%s 81 H%s M%s 85 H%s' % (x + 1.5, x + 7.5, x + 1.5, x + 7.5), INK, 1.6)
        p.shaded('M%s 94 V91 C%s 88 %s 87 %s 87 H%s C%s 87 %s 88 %s 91 V94 Z'
                 % (x - 3, x - 3, x - 1.5, x + 1, x + 8, x + 10.5, x + 12, x + 12), org, org_d, k=1.5, sw=2.4)
    # arms: ribbed tubes from the shoulders down to the pincer claws
    for sx, hx in ((29, 20), (71, 80)):
        p.outlined_line('M%s 54 L%s 70' % (sx, hx), steel, 6)
        for t in (0.3, 0.55, 0.8):
            cx, cy = sx + (hx - sx) * t, 54 + 16 * t
            p.line('M%s %s L%s %s' % (round(cx - 3.2, 1), round(cy + 1.4 * (1 if hx < sx else -1), 1),
                                      round(cx + 3.2, 1), round(cy - 1.4 * (1 if hx < sx else -1), 1)), INK, 1.4)
        # a C claw opening downward: an annulus with a gap of 70 degrees at the bottom
        cx, cy, ro, ri = hx, 75, 5.6, 2.6
        a0, a1 = math.radians(90 + 35), math.radians(90 - 35 + 360)
        pt = lambda r, a: '%s %s' % (round(cx + r * math.cos(a), 2), round(cy + r * math.sin(a), 2))
        d = 'M%s A%s %s 0 1 1 %s L%s A%s %s 0 1 0 %s Z' % (pt(ro, a0), ro, ro, pt(ro, a1), pt(ri, a1), ri, ri, pt(ri, a0))
        p.path(d, org, sw=2.2)
    # body
    body = 'M30 54 C30 51 32 49 35 49 H65 C68 49 70 51 70 54 V74 C70 77 68 79 65 79 H35 C32 79 30 77 30 74 Z'
    p.shaded(body, steel, steel_d, k=2.5)
    p.path('M37 56 C37 55 38 54 39 54 H61 C62 54 63 55 63 56 V70 C63 71 62 72 61 72 H39 C38 72 37 71 37 70 Z',
           '#FFF1CF', sw=2)
    p.add('<circle cx="45" cy="63" r="5.2" fill="#FFFFFF" stroke="%s" stroke-width="1.8"/>' % INK)
    p.line('M45 63 L48 60', INK, 1.6)
    p.add('<circle cx="56" cy="59.5" r="2.4" fill="#4CAF50" stroke="%s" stroke-width="1.4"/>'
          '<circle cx="56" cy="66.5" r="2.4" fill="#E5484D" stroke="%s" stroke-width="1.4"/>' % (INK, INK))
    for x, y in ((33.5, 52.5), (66.5, 52.5), (33.5, 75.5), (66.5, 75.5)):
        p.add('<circle cx="%s" cy="%s" r="1.1" fill="%s" opacity="0.55"/>' % (x, y, INK))
    # neck
    p.path('M44 44 H56 V50 H44 Z', steel_d, sw=2.2)
    p.line('M44.5 47 H55.5', INK, 1.4)
    # antenna
    p.line('M50 16 V7', INK, 4.2)
    p.line('M50 16 V7', steel_d, 1.8)
    p.add('<circle cx="50" cy="6" r="4.4" fill="#E5484D" stroke="%s" stroke-width="2.2"/>' % INK)
    p.add('<circle cx="48.6" cy="4.6" r="1.3" fill="#FFFFFF" opacity="0.8"/>')
    # bolt-plates at the sides of the head
    for x in (20.5, 74.5):
        p.path('M%s 24 H%s V36 H%s Z' % (x, x + 5, x), org, sw=2.2)
        p.line('M%s 28 H%s M%s 32 H%s' % (x + 1, x + 4, x + 1, x + 4), org_d, 1.4)
    # head
    head = 'M25 20 C25 17 27 15 30 15 H70 C73 15 75 17 75 20 V40 C75 43 73 45 70 45 H30 C27 45 25 43 25 40 Z'
    p.shaded(head, steel, steel_d, k=2.5)
    for x in (39, 61):
        p.add('<circle cx="%s" cy="28" r="7" fill="%s" stroke="%s" stroke-width="2.2"/>' % (x, org, INK))
        p.add('<circle cx="%s" cy="28" r="4.6" fill="#FFFFFF"/>' % x)
        p.eye(x, 28, 2.8)
    p.path('M43 37 C43 36 43.6 35.6 44.4 35.8 Q50 37.4 55.6 35.8 C56.4 35.6 57 36 57 37 V38.4 C57 39.4 56.4 40 55.6 '
           '40.2 Q50 41.9 44.4 40.2 C43.6 40 43 39.4 43 38.4 Z', '#EEF1F6', sw=1.8)
    p.line('M47.3 37.3 V40.5 M52.7 37.3 V40.5', INK, 1.2)
    p.hl('M29 21 Q30 18 34 18', 2.2)
    return p.body()


def flag():
    """The goal flag: a wooden pole in a small mound, a red pennant waving from its top."""
    p = Pic()
    p.shadow(40, 93, 22, 2.6)
    p.shaded('M18 92 C20 84 30 80 40 80 C50 80 60 84 62 92 Z', '#7ED17F', '#5BB65E', k=2, sw=2.6)
    p.outlined_line('M34 88 V10', '#8A5A2B', 4.4)
    pennant = 'M36 12 C50 10 62 18 84 20 C70 26 60 34 58 44 C50 40 44 42 36 46 Z'
    p.shaded(pennant, '#E5484D', '#B8323A', k=2.5)
    p.line('M40 18 C52 18 60 22 72 22', '#F47A7E', 2)
    p.add('<circle cx="34" cy="9" r="4.4" fill="#FFC83D" stroke="%s" stroke-width="2.4"/>' % INK)
    return p.body()


def grass_cell():
    """A square of lawn for the robot's path: one cell, the grass reaching both edges so a row of cells joins up."""
    p = Pic()
    p.add('<path d="M0 66 C20 62 80 62 100 66 V100 H0 Z" fill="#5BB65E"/>')
    for x in range(5, 100, 10):
        h = 18 + (x * 7) % 9
        p.path('M%s 68 Q%s %s %s %s Q%s %s %s 68 Z' % (x - 4, x - 2, 68 - h * 0.6, x + 1, 68 - h, x + 1, 68 - h * 0.5,
                                                     x + 4), '#7ED17F' if x % 2 else '#6BCB6E', sw=1.4, stroke='#3E9A47')
    p.add('<path d="M0 64 C20 60 80 60 100 64" fill="none" stroke="%s" stroke-width="2.4"/>' % INK)
    p.add('<path d="M0 78 Q50 74 100 78 M0 90 Q50 86 100 90" fill="none" stroke="#4CAF50" stroke-width="2" opacity="0.7"/>')
    return p.body()


def step_tap():
    """Open the tap: a chrome basin tap with a round handle, water running down into the white basin."""
    p = Pic()
    p.path('M2 84 C20 92 80 92 98 84 V100 H2 Z', '#FFFFFF', sw=2.6)
    p.add('<ellipse cx="50" cy="88" rx="30" ry="4" fill="#BFE3FF"/>')
    p.outlined_line('M60 50 C62 68 60 78 60 88', '#8FD3F4', 6)
    p.line('M58.5 56 C60 66 59 76 59 84', WHITE, 1.8, op=0.8)
    spout = 'M14 40 C14 30 22 24 34 24 H54 C62 24 66 30 66 38 V48 H54 V40 C54 38 53 37 51 37 H30 C28 37 26 39 26 42 Z'
    p.shaded(spout, '#D7DCE8', '#9AA0B4', k=2.5)
    p.path('M10 40 H30 V48 C30 50 29 51 27 51 H13 C11 51 10 50 10 48 Z', '#B7BCCD', sw=2.6)
    p.path('M28 12 H40 V24 H28 Z', '#B7BCCD', sw=2.6)
    p.shaded('M22 12 C22 8 26 6 34 6 C42 6 46 8 46 12 C46 15 42 16 34 16 C26 16 22 15 22 12 Z', '#D7DCE8', '#9AA0B4', k=1.5)
    p.add('<circle cx="34" cy="11" r="3" fill="#4DA3FF" stroke="%s" stroke-width="1.6"/>' % INK)
    p.hl('M20 34 Q26 28 36 28', 2.4)
    return p.body()


def step_soap():
    """Soap your hands: a pink bar of soap with three bubbles above it."""
    p = Pic()
    p.shadow(50, 84, 38, 3)
    bar = 'M14 56 C14 46 20 42 30 42 H70 C80 42 86 46 86 56 V64 C86 74 80 78 70 78 H30 C20 78 14 74 14 64 Z'
    p.shaded(bar, '#F48FB1', '#D9668F', k=3.5)
    p.path('M24 52 C24 49 26 48 30 48 H70 C74 48 76 49 76 52 V58 C76 61 74 62 70 62 H30 C26 62 24 61 24 58 Z',
           '#F8B0C8', sw=0)
    p.hl('M22 56 Q22 48 30 46', 2.6)
    for cx, cy, r in ((30, 28, 8), (48, 20, 6), (62, 30, 4.5)):
        p.add('<circle cx="%s" cy="%s" r="%s" fill="#FFFFFF" fill-opacity="0.6" stroke="%s" stroke-width="2.2"/>'
              % (cx, cy, r, INK))
        p.add('<path d="M%s %s Q%s %s %s %s" fill="none" stroke="#8FD3F4" stroke-width="1.6" stroke-linecap="round"/>'
              % (cx - r * 0.6, cy - r * 0.1, cx - r * 0.5, cy - r * 0.6, cx - r * 0.05, cy - r * 0.65))
    return p.body()


def step_paste():
    """Put paste on the brush: the toothbrush with a ribbon of paste on its bristles and the tube above, squeezing."""
    paste_ribbon = ('<path d="M73 31 C78 26 82 34 87 29 C91 25 94 31 97 28" fill="none" stroke="%s" stroke-width="9.5" '
                    'stroke-linecap="round" stroke-linejoin="round"/>'
                    '<path d="M73 31 C78 26 82 34 87 29 C91 25 94 31 97 28" fill="none" stroke="#FFFFFF" stroke-width="5" '
                    'stroke-linecap="round" stroke-linejoin="round"/>'
                    '<path d="M75 31 C79 28 82 33 87 30" fill="none" stroke="#4DA3FF" stroke-width="1.6" '
                    'stroke-linecap="round"/>' % INK)
    tube = '<g transform="translate(80 -1) scale(-0.4 0.4)">%s</g>' % paste()  # the tube squeezing it, over the head
    return brush(over=paste_ribbon) + tube


def step_brush():
    """Brush your teeth: the toothbrush with foam bubbles on its bristles."""
    foam = ''.join('<circle cx="%s" cy="%s" r="%s" fill="#FFFFFF" stroke="%s" stroke-width="1.8"/>' % (x, y, r, INK)
                   for x, y, r in ((76, 30, 4.5), (83, 26, 5.5), (91, 29, 4.5), (87, 20, 3.4), (96, 24, 3), (79, 21, 2.6)))
    return brush(over=foam)


def towel():
    """Dry your hands: the striped towel of the Languages courses, hanging on its rail."""
    return lang('towel-striped')


def rinse():
    """Rinse: a glass of water (the Languages glass)."""
    return lang('water')


LIT = ('duck', 'bird', 'cat', 'dog', 'fish', 'apple', 'star', 'ladybug', 'butterfly')
APPLE = (('#E53935', '#E5484D'), ('#B8282A', '#B8323A'))  # the Languages apple in the red of make_picture_sprites
APPLE_GREEN = (('#E53935', '#8BC34A'), ('#B8282A', '#5E9A2E'))
SIZES = (('s', 0.4), ('m', 0.68), ('l', 1.0))
BALL_SIZES = (('s', 0.35), ('m', 0.65), ('l', 1.0))
CANVAS = {**{'tower_%d' % k: (TOWER_W, TOWER_H) for k in range(1, TOWER_MAX + 1)}, 'flower_target': (160, 200), 'nest_empty': (400, 225), 'bowl_empty': (400, 225), 'basket_empty': (400, 225)}


def build():
    """Every picture as {id: svg text}, by land. Canvases other than 100 x 100 are in CANVAS."""
    pics = {'duck': duck(), 'bird': bird(), 'chick': chick()}
    for k in range(1, TOWER_MAX + 1):
        pics['tower_%d' % k] = tower(k)
    pics.update({'rule_colour': rule_colour(), 'rule_shape': rule_shape(), 'rule_size': rule_size(),
                 'plate': plate(), 'brush': brush(), 'paste': paste(), 'umbrella': umbrella(),
                 'bin_basket': bin_basket(), 'bin_grass': bin_grass(),
                 'clue_not_colour': clue_any_colour(), 'clue_not_shape': clue_shape('shapes')})
    for name, (c, s) in COLOURS.items():
        pics['balloon_' + name] = balloon(c, s)
    for name in CLUE_COLOURS:
        pics['clue_not_' + name] = clue_colour(*COLOURS[name])
    for name in CLUE_SHAPES:
        pics['clue_not_' + name] = clue_shape(name)
    # Riddle Grotto, second batch (also the counted things of Counting Hills and the maths land)
    pics.update({'cat': lang('cat'), 'dog': lang('dog'), 'fish': lang('fish'), 'star': lang('star'),
                 'apple': lang('apple', recolour=APPLE), 'apple_green': lang('apple', recolour=APPLE_GREEN),
                 'frog': lang('frog'), 'sock': lang('sock'), 'spoon': lang('spoon'), 'bowl': lang('bowl'),
                 'pencil': lang('pencil'), 'egg': lang('egg'), 'egg_crack': egg_crack(), 'rain': lang('rain'),
                 'rainbow': lang('rainbow'), 'cloud': cloud(), 'shoe': shoe(), 'key': key(), 'lock': lock(),
                 'paper': paper(), 'plant_seed': plant_seed(), 'plant_sprout': plant_sprout(),
                 'plant_flower': plant_flower(), 'tick': tick(), 'cross': cross()})
    for name in COLOURS:
        pics['ball_' + name] = ball(name)
    for thing in ('star', 'apple', 'fish'):
        for tag, k in SIZES:
            pics['%s_size_%s' % (thing, tag)] = sized(pics[thing], k)
    for tag, k in BALL_SIZES:
        pics['ball_size_' + tag] = sized(pics['ball_red'], k)
    pics.update(shape_bodies())
    # Counting Hills
    pics.update({'ladybug': ladybug(), 'butterfly': lang('butterfly'), 'basket_target': bin_basket(),
                 'flower_target': flower_target(), 'nest_empty': nest_empty(), 'bowl_empty': bowl_empty(),
                 'basket_empty': basket_empty()})
    # the maths land
    pics.update({'block': block(), 'coin': coin(), 'stick_long': stick(4, 96), 'stick_short': stick(28, 72),
                 'stone': stone(), 'feather': feather(), 'time_morning': time_morning(), 'time_noon': time_noon(),
                 'time_evening': time_evening(), 'time_night': time_night(),
                 'banana_yellow': banana('#FFD84D', '#E5B52A', '#E0B02A'),
                 'banana_green': banana('#8BC34A', '#6A9E34', '#6A9E34')})
    for k in range(1, 8):
        pics['day_%d' % k] = day(k)
    for h in range(1, 13):
        pics['clock_%d' % h] = clock(h)
    # Colour Bay
    for name, (c, s) in COLOURS.items():
        pics['bloom_' + name] = bloom(c, s)
    pics.update({'flower_red': bloom('#D62F2F'), 'flower_yellow': bloom('#FFD43B'), 'sun': lang('sun')})
    for name, levels in SHADES.items():
        for k, c in enumerate(levels, start=1):
            pics['shade_%s_%d' % (name, k)] = shade_disc(c)
    # Shape Forest
    pics.update({'solid_box': solid_box(), 'solid_cone': solid_cone(), 'solid_cylinder': solid_cylinder(),
                 'solid_sphere': solid_sphere(), 'solid_pyramid': solid_pyramid(), 'pos_on': pos_on(),
                 'pos_under': pos_under(), 'pos_in': pos_in(), 'pos_next': pos_next(), 'pos_above': pos_above(),
                 'window': window(), 'sign': sign()})
    for name, (d, c) in LINES.items():
        pics[name] = line_pic(d, c)
    # Robot Harbour
    pics.update({'robot': robot(), 'flag': flag(), 'grass': grass_cell(), 'step_tap': step_tap(), 'step_soap': step_soap(),
                 'step_rinse': rinse(), 'step_towel': towel(), 'step_paste': step_paste(), 'step_brush': step_brush()})
    out = {}
    for k, v in pics.items():
        w, h = CANVAS.get(k, (100, 100))
        out[k] = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">%s</svg>\n'
                  % (w, h, w, h, v))
    for name in LIT:
        out[name + '_lit'] = svg(GLOW + pics[name])
    return out


NEW = (['umbrella', 'bin_basket', 'bin_grass', 'clue_not_colour', 'clue_not_shape']
       + ['clue_not_' + c for c in CLUE_COLOURS] + ['clue_not_' + s for s in CLUE_SHAPES] + ['tower_7', 'tower_8'])

# The batches of the contact sheets (old against new), by land.
SHAPE_IDS = (['shape_%s_%s' % (k, c) for k in ('circle', 'square', 'triangle', 'rect') for c in SHAPE_COLOURS]
             + ['shape_circle', 'shape_square', 'shape_triangle', 'shape_rect', 'shape_square_tilt', 'shape_triangle_thin',
                'shape_triangle_down', 'shape_pentagon', 'shape_hexagon', 'shape_quad', 'shape_curved', 'shape_open'])
SHADES = {'blue': ('#CFE6FF', '#5AA6F2', '#1F4E9C'), 'green': ('#D7F2C8', '#5BBE5A', '#2A6F2F'),
          'red': ('#FFD0D0', '#E5484D', '#8E1B22'), 'purple': ('#E6D8FA', '#9B6BDF', '#52308F')}  # light, middle, dark
LINES = {  # the old paths and colours of the line pictures
    'line_straight': ('M12 82 L88 18', '#2F7FE0'), 'line_curved': ('M12 80 C 30 10, 70 10, 88 80', '#E5484D'),
    'line_straight_flat': ('M10 50 L90 50', '#2F7FE0'), 'line_curved_wave': ('M8 50 C 22 20, 36 80, 50 50 S 78 20, 92 50', '#E5484D'),
    'line_straight_up': ('M50 10 L50 90', '#2F7FE0'), 'line_curved_arc': ('M20 86 C 6 40, 40 10, 86 20', '#E5484D'),
}
BATCHES = {
    'logic-2': ('Riddle Grotto, second batch: the towers to 8, the Logic things, the balls and the sizes',
                ['tower_%d' % k for k in range(1, TOWER_MAX + 1)] +
                ['cat', 'dog', 'fish', 'apple', 'apple_green', 'star', 'frog', 'sock', 'shoe', 'key', 'lock', 'spoon',
                 'bowl', 'pencil', 'paper', 'cloud', 'rain', 'rainbow', 'egg', 'egg_crack', 'plant_seed', 'plant_sprout',
                 'plant_flower', 'tick', 'cross'] + ['ball_' + c for c in COLOURS] +
                ['%s_size_%s' % (t, s) for t in ('ball', 'star', 'apple', 'fish') for s in 'sml'] +
                ['cat_lit', 'dog_lit', 'fish_lit', 'apple_lit', 'star_lit']),
    'shapes': ('The shapes (Shape Forest, and the coloured shapes of Colour Bay and Riddle Grotto)', SHAPE_IDS),
    'numbers': ('Counting Hills: the ladybird, the butterfly, the targets and the empty scenes',
                ['ladybug', 'ladybug_lit', 'butterfly', 'butterfly_lit', 'basket_target', 'flower_target',
                 'nest_empty', 'bowl_empty', 'basket_empty']),
    'math': ('The maths land: the balance block, the coin, sticks, stone and feather, times of day, days, clocks, bananas',
             ['block', 'coin', 'stick_long', 'stick_short', 'stone', 'feather', 'banana_yellow', 'banana_green',
              'time_morning', 'time_noon', 'time_evening', 'time_night'] + ['day_%d' % k for k in range(1, 8)] +
             ['clock_%d' % h for h in range(1, 13)]),
    'colours': ('Colour Bay: the flowers in eleven colours, the two flower cards, the shades, the sun',
                ['bloom_' + c for c in COLOURS] + ['flower_red', 'flower_yellow', 'sun'] +
                ['shade_%s_%d' % (c, k) for c in SHADES for k in (1, 2, 3)]),
    'forest': ('Shape Forest: the solids, the position pictures, the lines, the window and the sign',
               ['solid_box', 'solid_cone', 'solid_cylinder', 'solid_sphere', 'solid_pyramid', 'pos_on', 'pos_under', 'pos_in',
                'pos_next', 'pos_above', 'window', 'sign'] + list(LINES)),
    'robot': ('Robot Harbour: the robot, the flag, the grass path cell, the steps of washing and brushing',
              ['robot', 'flag', 'grass', 'step_tap', 'step_soap', 'step_rinse', 'step_towel', 'step_paste', 'step_brush']),
    'towers': ('The towers on their tall canvas (100 x 220)', ['tower_%d' % k for k in range(1, TOWER_MAX + 1)]),
}


BASE = 'c146c0a3'  # the commit before the redraw: the "old" column of the contact sheet

REDRAWN = (['duck', 'bird', 'chick'] + ['tower_%d' % k for k in range(1, 7)] + ['rule_size', 'rule_shape', 'rule_colour',
           'plate', 'brush', 'paste'] + ['balloon_' + c for c in COLOURS])


def _old(name, tmp):
    """The file as it was at BASE, written next to the sheet's html (None for a new id)."""
    r = subprocess.run(['git', 'show', '%s:content/starter/%s.svg' % (BASE, name)], cwd=ROOT, capture_output=True)
    if r.returncode:
        return None
    f = os.path.join(tmp, 'old_' + name + '.svg')
    with open(f, 'wb') as fh:
        fh.write(r.stdout)
    return pathlib.Path(f).as_uri()


def sheet(out=SHEET):
    """Old against new for every redrawn and new id: on an answer tile at 90 and 60 px, and on the stage at 44 and
    28 px (the phone's stage is 330 x 128 points); then the three birds as solid silhouettes, the six towers in a row,
    and the balloons next to the ball."""
    tmp = os.path.join(os.path.dirname(out), '_sheet')
    os.makedirs(tmp, exist_ok=True)
    new = lambda n: (pathlib.Path(OUT) / (n + '.svg')).as_uri()

    def tile(u, px):
        return ('<div class="t" style="width:%dpx;height:%dpx"><img src="%s" style="width:%dpx;height:%dpx"></div>'
                % (px + 22, px + 22, u, px, px)) if u else '<div class="t none" style="width:%dpx;height:%dpx">new</div>' % (px + 22, px + 22)

    def stage(u):
        if not u:
            return '<div class="st none">new</div>'
        return '<div class="st"><img src="%s" style="width:44px;height:44px"><img src="%s" style="width:28px;height:28px"></div>' % (u, u)

    rows = []
    for n in REDRAWN + NEW:
        o = _old(n, tmp)
        rows.append('<div class="r"><div class="n">%s</div>%s%s<div class="arrow">&#8594;</div>%s%s%s</div>'
                    % (n, tile(o, 60), stage(o), tile(new(n), 90), tile(new(n), 60), stage(new(n))))
    half = (len(rows) + 1) // 2
    sil = ''.join('<div class="t" style="width:112px;height:112px"><img class="sil" src="%s" style="width:90px;height:90px"></div>'
                  % new(n) for n in ('duck', 'bird', 'chick'))
    sil_old = ''.join('<div class="t" style="width:112px;height:112px"><img class="sil" src="%s" style="width:90px;height:90px"></div>'
                      % _old(n, tmp) for n in ('duck', 'bird', 'chick'))
    towers = ''.join(tile(new('tower_%d' % k), 60) for k in range(1, 7))
    towers_old = ''.join(tile(_old('tower_%d' % k, tmp), 60) for k in range(1, 7))
    balloons = ''.join('<img src="%s" style="width:60px;height:60px">' % new('balloon_' + c) for c in COLOURS)
    balloons += '<img src="%s" style="width:60px;height:60px;margin-left:24px">' % (pathlib.Path(OUT) / 'ball_red.svg').as_uri()
    css = ('body{margin:0;padding:16px;background:#FFF6E8;font:13px sans-serif;color:#2B2350;width:1368px}'
           'h1{font-size:18px;margin:0 0 4px}h2{font-size:14px;margin:14px 0 6px}.cols{display:flex;gap:24px}'
           '.r{display:flex;align-items:center;gap:8px;height:120px;border-bottom:1px solid #EDE6F7}'
           '.n{width:118px;font-weight:bold;font-size:12px}.arrow{font-size:20px;color:#8A5CF0}'
           '.t{background:#fff;border-radius:16px;box-shadow:0 3px 0 #DCD3EC;display:flex;align-items:center;justify-content:center;'
           'flex:none}.none{color:#B9A2F7;font-size:12px}'
           '.st{width:96px;height:64px;border-radius:12px;display:flex;align-items:flex-end;justify-content:space-around;'
           'padding-bottom:4px;flex:none;background:linear-gradient(#E3F2FB 0 62%,#A8DC8C 62% 100%)}'
           '.st.none{align-items:center;background:#EDE6F7}.sil{filter:brightness(0)}.row{display:flex;gap:10px;align-items:center}')
    html = ('<html><head><style>%s</style></head><body><h1>Riddle Grotto sprites, 2026-11-06: old (left) and new (right)</h1>'
            '<div>Per row: the old picture on a 60 px tile and on the stage (44 and 28 px), then the new one on a 90 px and a '
            '60 px tile and on the stage.</div><div class="cols"><div>%s</div><div>%s</div></div>'
            '<h2>The three birds as solid silhouettes (old above, new below): the outline alone must tell them apart</h2>'
            '<div class="row">%s</div><div class="row" style="margin-top:8px">%s</div>'
            '<h2>tower_1 to tower_6 in a row (old above, new below), one scale, one colour order from the bottom</h2>'
            '<div class="row">%s</div><div class="row" style="margin-top:8px">%s</div>'
            '<h2>The eleven balloons, and the ball (ball_red, not redrawn) beside them, at 60 px</h2><div class="row">%s</div>'
            '</body></html>' % (css, ''.join(rows[:half]), ''.join(rows[half:]), sil_old, sil, towers_old, towers, balloons))
    page = os.path.join(tmp, 'sheet.html')
    with open(page, 'w', encoding='utf-8') as fh:
        fh.write(html)
    h = 120 * half + 720
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
                    '--allow-file-access-from-files', '--screenshot=' + out, '--window-size=1400,%d' % h,
                    pathlib.Path(page).as_uri()], check=True, capture_output=True)
    for f in os.listdir(tmp):
        os.remove(os.path.join(tmp, f))
    os.rmdir(tmp)


def batch_sheet(tag):
    """Old against new for one batch: each picture on an answer tile at 90 and 60 px and on the stage at 44 and 28 px
    (the phone's stage is 330 x 128 points), old on the left, new on the right; then the set in a row at stage size."""
    title, ids = BATCHES[tag]
    out = os.path.join(os.path.dirname(SHEET), 'sheet-%s-2026-11-06.png' % tag)
    tmp = os.path.join(os.path.dirname(out), '_sheet_' + tag)
    os.makedirs(tmp, exist_ok=True)
    new = lambda n: (pathlib.Path(OUT) / (n + '.svg')).as_uri()

    def img(u, px):
        return '<img src="%s" style="width:%dpx;height:%dpx;object-fit:contain">' % (u, px, px)

    def side(u):
        if not u:
            return '<div class="t none" style="width:112px;height:112px">new</div>' * 2 + '<div class="st none">new</div>'
        return ('<div class="t" style="width:112px;height:112px">%s</div><div class="t" style="width:82px;height:82px">%s</div>'
                '<div class="st">%s%s</div>' % (img(u, 90), img(u, 60), img(u, 44), img(u, 28)))

    rows = ['<div class="r"><div class="n">%s</div>%s<div class="arrow">&#8594;</div>%s</div>' % (n, side(_old(n, tmp)), side(new(n)))
            for n in ids]
    half = (len(rows) + 1) // 2
    strip = ''.join(img(new(n), 44) for n in ids)
    strip_old = ''.join(img(_old(n, tmp), 44) for n in ids if _old(n, tmp))
    css = ('body{margin:0;padding:16px;background:#FFF6E8;font:13px sans-serif;color:#2B2350;width:1568px}'
           'h1{font-size:18px;margin:0 0 4px}h2{font-size:14px;margin:14px 0 6px}.cols{display:flex;gap:20px}'
           '.r{display:flex;align-items:center;gap:6px;height:124px;border-bottom:1px solid #EDE6F7}'
           '.n{width:104px;font-weight:bold;font-size:11px;overflow-wrap:anywhere}.arrow{font-size:18px;color:#8A5CF0}'
           '.t{background:#fff;border-radius:16px;box-shadow:0 3px 0 #DCD3EC;display:flex;align-items:center;'
           'justify-content:center;flex:none}.none{color:#B9A2F7;font-size:12px}'
           '.st{width:96px;height:64px;border-radius:12px;display:flex;align-items:flex-end;justify-content:space-around;'
           'padding-bottom:4px;flex:none;background:linear-gradient(#E3F2FB 0 62%,#A8DC8C 62% 100%)}'
           '.st.none{align-items:center;background:#EDE6F7}'
           '.strip{display:flex;flex-wrap:wrap;gap:4px;padding:6px;border-radius:12px;'
           'background:linear-gradient(#E3F2FB 0 62%,#A8DC8C 62% 100%)}')
    html = ('<html><head><style>%s</style></head><body><h1>%s (2026-11-06): old (left) against new (right)</h1>'
            '<div>Each side: a 90 px and a 60 px answer tile, then the stage at 44 and 28 px.</div>'
            '<div class="cols"><div>%s</div><div>%s</div></div>'
            '<h2>The whole batch at 44 px on the stage, old above, new below</h2><div class="strip">%s</div>'
            '<div class="strip" style="margin-top:8px">%s</div></body></html>'
            % (css, title, ''.join(rows[:half]), ''.join(rows[half:]), strip_old, strip))
    page = os.path.join(tmp, 'sheet.html')
    with open(page, 'w', encoding='utf-8') as fh:
        fh.write(html)
    h = 124 * half + 140 + 2 * (52 * (len(ids) // 30 + 1)) + 60
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
                    '--allow-file-access-from-files', '--screenshot=' + out, '--window-size=1600,%d' % h,
                    pathlib.Path(page).as_uri()], check=True, capture_output=True)
    for f in os.listdir(tmp):
        os.remove(os.path.join(tmp, f))
    os.rmdir(tmp)
    return out


def main():
    pics = build()
    for name, text in pics.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(text)
    print('wrote', len(pics), 'pictures to', os.path.relpath(OUT, ROOT))
    if '--sheet' in sys.argv:  # --sheet [batch ...]: the batch sheets (all when none is named); "first" is today's first
        os.makedirs(os.path.dirname(SHEET), exist_ok=True)
        tags = [a for a in sys.argv[sys.argv.index('--sheet') + 1:] if not a.startswith('-')] or list(BATCHES)
        for tag in tags:
            if tag == 'first':
                sheet()
                print('sheet', os.path.relpath(SHEET, ROOT))
            else:
                print('sheet', os.path.relpath(batch_sheet(tag), ROOT))


if __name__ == '__main__':
    main()
