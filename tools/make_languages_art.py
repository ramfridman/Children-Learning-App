"""Draws the Languages island (frame.md section 1.1 and 1.2): the island on the four home maps, its sign icon, the three
course hosts and their doors (docs/design/languages-island.md).

    python tools/make_languages_art.py

Writes (deterministic):
  app/assets/art/scenes/home_phone_lang.svg             2382 x 393   phone strip with 8 lands (home moved 280 right)
  app/assets/art/scenes/home_phone_se_lang.svg          2086 x 375   SE strip with 8 lands (home moved 252 right)
  app/assets/art/scenes/home_tablet_landscape_lang.svg  1180 x 820   landscape board, Market Village 50 left, the island top right
  app/assets/art/scenes/home_tablet_portrait_lang.svg    820 x 1720  portrait scene, 140 more sea at the bottom, the island there
  app/assets/art/ui/land_languages.svg                  the 24 point sign icon (two speech bubbles)
  app/assets/art/languages/host_eng.svg, host_heb.svg, host_rus.svg       the hosts on the cast's 512 canvas
  app/assets/art/languages/door_<course>.svg, door_<course>_open.svg     each door with its host, 240 x 300
  app/assets/art/languages/speaker.svg                  the small "hear it" mark in a hello bubble
The 7-land scenes (home_phone.svg, ...) are not touched: they stay the map when every language is off.

What is drawn (our own drawings in plain shapes; nothing traced or copied, no text or letters inside any picture, no flag,
no franchise look, no real person):
  The island (the companion hosts it, so there is no host on the map): a small house of pale limestone whose roof is an
    open book (two curved pages on a coral cover), three arched doors in the three course colours (blue, coral, violet,
    told apart also by their windows: round, arched, square), three small empty speech bubbles rising over the roof with a
    wavy line inside, a round tree and flowers.
  The hosts, one per course, chosen with no national symbol or stereotype (frame.md 1.2: a language is not a country), none
  from the banned list of design-spec 4 (bear, elephant, red panda, hummingbird, dog, monkey, owl, electric mouse), and
  each with its own silhouette at 48 px:
    English (eng): a budgerigar, a bird that can learn to say words: green body, yellow face and forehead, fine dark bars
      on the nape, black throat spots, violet-blue cheek patches, blue cere, a short hooked olive-grey beak, dark scalloped
      wings with yellow edges, a long blue tail, two toes forward and two back. It waves one wing.
    Hebrew (heb): a rock hyrax: a round grey-brown loaf with no neck, small round dark-rimmed ears, a pale patch above each
      eye, a cream muzzle and chin, long dark whiskers, short legs with soft padded feet. It holds a big coral pencil.
    Russian (rus): a giraffe: a long neck with a short mane, two ossicones with dark tufts, sideways ears, a pale muzzle,
      orange-brown patches with cream lines between them, a tail with a dark tuft. Chibi proportions so it fits the canvas.
  The doors: an arched door in a limestone frame, planked, with a gold knob and its window; the open version shows the
    leaf swung back and a warm light inside. The host stands in front.

References looked at on 2026-11-03 (facts and photographs; the look is ours):
  Rock hyrax, https://en.wikipedia.org/wiki/Rock_hyrax and its lead photograph "Hyrax on the Rocks" (Wikimedia Commons,
    CC BY-SA 4.0): squat heavy body, thick grey-brown fur, short rounded ears with a dark rim, pointed head, pale eyebrow
    patch and pale chin, long black whiskers, flat soft padded feet.
  Budgerigar, https://en.wikipedia.org/wiki/Budgerigar and the photograph "Melopsittacus undulatus mex180102" (two males,
    Wikimedia Commons, CC BY-SA 4.0): light green body, yellow face, black throat spots, blue cere, scalloped black and
    yellow wings, cobalt tail, olive-grey bill, zygodactyl feet; can mimic speech.
  Giraffe, https://en.wikipedia.org/wiki/Giraffe and its lead photograph: orange-brown patches with cream lines, two
    tufted ossicones, short upright mane, long neck, tail ending in a dark tuft.
  Our own boards and generator (tools/make_home_map.py, design/renders/04-world-map.png) for the island layers, palette,
    path dots and waves.
"""
import os
import re

import make_home_map as hm
from make_home_map import el, f, g

ROOT = hm.ROOT
SCENES = hm.OUT
UI = os.path.join(ROOT, 'app', 'assets', 'art', 'ui')
LANG = os.path.join(ROOT, 'app', 'assets', 'art', 'languages')
SRC = hm.SRC

INK, FOAM, GOLD, CORAL = hm.INK, hm.FOAM, hm.GOLD, hm.CORAL
SHADOW = 'rgba(43,35,80,0.14)'

# The three course colours (doors, bubble outlines). Never the only cue: each door also has its own window shape and host.
COURSE = {
    'eng': {'door': '#3E8EDE', 'door_dark': '#2C6FB8', 'window': 'round'},
    'heb': {'door': '#F07F6E', 'door_dark': '#D25E4E', 'window': 'arch'},
    'rus': {'door': '#8A63D2', 'door_dark': '#6D49B3', 'window': 'square'},
}
STONE, STONE_SHADE, STONE_EDGE = '#F6EAD2', '#E3D0AC', '#CDB585'


# ---------------------------------------------------------------- the island landmark
def door_small(x, base, w, h, course):
    """A small arched door for the map: x is its centre, base its bottom."""
    c = COURSE[course]
    r = w / 2
    out = [el('path', d='M%s %s L%s %s A%s %s 0 0 1 %s %s L%s %s Z' % (f(x - r), f(base), f(x - r), f(base - h + r), f(r), f(r), f(x + r), f(base - h + r), f(x + r), f(base)), fill=c['door']),
           el('path', d='M%s %s L%s %s A%s %s 0 0 1 %s %s L%s %s Z' % (f(x + r * 0.2), f(base), f(x + r * 0.2), f(base - h + r * 0.02), f(r), f(r), f(x + r), f(base - h + r), f(x + r), f(base)), fill=c['door_dark'], opacity=0.35),
           el('circle', cx=x + r * 0.5, cy=base - h * 0.42, r=1.4, fill=GOLD)]
    wy = base - h + r + 2
    if c['window'] == 'round':
        out.append(el('circle', cx=x, cy=wy, r=r * 0.42, fill='#FFF3C4'))
    elif c['window'] == 'arch':
        ww = r * 0.42
        out.append(el('path', d='M%s %s L%s %s A%s %s 0 0 1 %s %s L%s %s Z' % (f(x - ww), f(wy + 3), f(x - ww), f(wy - 1), f(ww), f(ww), f(x + ww), f(wy - 1), f(x + ww), f(wy + 3)), fill='#FFF3C4'))
    else:
        out.append(el('rect', x=x - r * 0.4, y=wy - r * 0.4, width=r * 0.8, height=r * 0.8, rx=1, fill='#FFF3C4'))
    return out


def speech_bubble(x, y, w, h, stroke, tail_dx=-6, sw=2.2):
    """An empty speech bubble with a wavy line inside (a sound, not a letter)."""
    r = h / 2
    body = 'M%s %s L%s %s A%s %s 0 0 1 %s %s L%s %s A%s %s 0 0 1 %s %s Z' % (
        f(x - w / 2 + r), f(y - r), f(x + w / 2 - r), f(y - r), f(r), f(r), f(x + w / 2 - r), f(y + r),
        f(x - w / 2 + r), f(y + r), f(r), f(r), f(x - w / 2 + r), f(y - r))
    tx = x + tail_dx
    return [el('path', d='M%s %s L%s %s L%s %s Z' % (f(tx - 4), f(y + r - 1), f(tx + 3), f(y + r - 1), f(tx - 6), f(y + r + 7)), fill=FOAM, stroke=stroke, stroke_width=sw, stroke_linejoin='round'),
            el('path', d=body, fill=FOAM, stroke=stroke, stroke_width=sw),
            el('path', d='M%s %s L%s %s L%s %s Z' % (f(tx - 5), f(y + r - 2.4), f(tx + 4), f(y + r - 2.4), f(tx - 3), f(y + r + 2)), fill=FOAM),
            el('path', d='M%s %s q%s %s %s 0 q%s %s %s 0 q%s %s %s 0' % (f(x - w * 0.3), f(y), f(w * 0.1), f(-h * 0.22), f(w * 0.2), f(w * 0.1), f(h * 0.22), f(w * 0.2), f(w * 0.1), f(-h * 0.22), f(w * 0.2)),
               fill='none', stroke=stroke, stroke_width=sw * 0.8, stroke_linecap='round')]


def languages_landmark():
    """Local coordinates for an island of R 124 (phone); y 0 is the sand's centre, the grass top is near y -56.
    Everything tall stays between x -97 and +45; on the phones it is also moved left (dx -8 at scale 1.15, -10 at 1.0), so
    the friend's welcome bubble at its widest stays 15 / 11 clear of the roof (docs/design/languages-island.md section 3)."""
    out = []
    # Round tree on the left, flowers.
    out += [el('rect', x=-84, y=-14, width=5, height=18, rx=2, fill=hm.WOOD),
            el('circle', cx=-82, cy=-24, r=15, fill='#4CB673'),
            el('circle', cx=-79, cy=-27, r=11, fill='#6FCB86'),
            el('ellipse', cx=-82, cy=5, rx=14, ry=3, fill='#2B2350', opacity=0.12)]
    for (fx, fy, c) in ((-60, 14, '#F4A7B4'), (-52, 20, GOLD), (36, 18, '#F4A7B4'), (44, 12, GOLD)):
        out += [el('circle', cx=fx, cy=fy, r=2.6, fill=c), el('circle', cx=fx, cy=fy, r=1, fill='#FFF6E8')]
    # The house: limestone walls, lit left and shaded right.
    x0, x1, top, base = -42, 32, -32, 8
    out += [el('ellipse', cx=-5, cy=base + 2, rx=44, ry=5, fill='#2B2350', opacity=0.14),
            el('rect', x=x0, y=top, width=x1 - x0, height=base - top, fill=STONE),
            el('rect', x=x1 - 14, y=top, width=14, height=base - top, fill=STONE_SHADE),
            el('rect', x=x0 - 2, y=base - 3, width=x1 - x0 + 4, height=4, rx=1.5, fill=STONE_EDGE)]
    # Three arched doors (from the right in reading order: English, Hebrew, Russian; the same order as the door screen).
    for x, course in ((19, 'eng'), (-5, 'heb'), (-29, 'rus')):
        out += door_small(x, base - 1, 15, 26, course)
    # The roof: an open book. A coral cover under two curved white pages, the spine in the middle.
    cx, ry_ = -5, top
    out += [el('path', d='M%s %s Q%s %s %s %s Q%s %s %s %s L%s %s Q%s %s %s %s Q%s %s %s %s Z' % (
                f(cx - 50), f(ry_ + 3), f(cx - 26), f(ry_ - 15), f(cx), f(ry_ - 6), f(cx + 26), f(ry_ - 15), f(cx + 50), f(ry_ + 3),
                f(cx + 50), f(ry_ + 7), f(cx + 26), f(ry_ - 9), f(cx), f(ry_ - 1), f(cx - 26), f(ry_ - 9), f(cx - 50), f(ry_ + 7)), fill=CORAL),
            # left page
            el('path', d='M%s %s Q%s %s %s %s L%s %s Q%s %s %s %s Z' % (f(cx - 47), f(ry_ + 1), f(cx - 25), f(ry_ - 20), f(cx), f(ry_ - 10), f(cx), f(ry_ - 4), f(cx - 25), f(ry_ - 13), f(cx - 47), f(ry_ + 4)), fill=FOAM),
            # right page, a touch shaded
            el('path', d='M%s %s Q%s %s %s %s L%s %s Q%s %s %s %s Z' % (f(cx + 47), f(ry_ + 1), f(cx + 25), f(ry_ - 20), f(cx), f(ry_ - 10), f(cx), f(ry_ - 4), f(cx + 25), f(ry_ - 13), f(cx + 47), f(ry_ + 4)), fill='#F1EADF'),
            el('path', d='M%s %s L%s %s' % (f(cx), f(ry_ - 10), f(cx), f(ry_ - 3)), fill='none', stroke='#D9604F', stroke_width=1.6, stroke_linecap='round')]
    for k in (0, 1, 2):
        dy = 4 + k * 3.2
        out += [el('path', d='M%s %s Q%s %s %s %s' % (f(cx - 40 + k * 2), f(ry_ - 2 - dy * 0.2 + k * 0.8), f(cx - 24), f(ry_ - 16 + dy), f(cx - 6), f(ry_ - 9 + dy * 0.7)), fill='none', stroke='#C9C3D9', stroke_width=1.1, stroke_linecap='round'),
                el('path', d='M%s %s Q%s %s %s %s' % (f(cx + 40 - k * 2), f(ry_ - 2 - dy * 0.2 + k * 0.8), f(cx + 24), f(ry_ - 16 + dy), f(cx + 6), f(ry_ - 9 + dy * 0.7)), fill='none', stroke='#C9C3D9', stroke_width=1.1, stroke_linecap='round')]
    # Three speech bubbles rising over the roof, outlined in the course colours.
    out += speech_bubble(-40, -66, 22, 13, COURSE['rus']['door'], tail_dx=5)
    out += speech_bubble(-6, -80, 24, 14, COURSE['heb']['door'], tail_dx=-3)
    out += speech_bubble(28, -64, 22, 13, COURSE['eng']['door'], tail_dx=-7)
    return out


def languages_island(cx, cy, R=124, ry=67, s=1.0, dx=0):
    """The island; its landmark is drawn at scale s and moved dx from the sand's centre (on the phones a little to the
    left, away from the friend's bubble)."""
    body = hm.island_base(R, ry) + [g(languages_landmark(), dx, 0, s)]
    return '<g id="island-languages">%s</g>' % g(body, cx, cy)


# ---------------------------------------------------------------- top-level elements of a board
def split_elements(body):
    """The top-level elements of an SVG body, in order."""
    out, depth, start = [], 0, 0
    for m in re.finditer(r'<(/?)(\w+)([^>]*?)(/?)>', body):
        close, _tag, _attrs, selfc = m.groups()
        if close:
            depth -= 1
        elif depth == 0:
            start = m.start()
        if not close and not selfc:
            depth += 1
        if depth == 0:
            out.append(body[start:m.end()])
    return out


def first_x(e):
    m = re.search(r'(?:cx|x)="(-?[\d.]+)"|d="M(-?[\d.]+)|translate\((-?[\d.]+)', e)
    return float(next(v for v in m.groups() if v is not None)) if m else 0.0


# ---------------------------------------------------------------- phones: home moves right, the island takes its place
def phone_strip_lang(src, out, W, H, shift, D, home_from, cy_low, cy_high, spacing, R, ry, se):
    label, old = hm.read_board(src)
    if se:
        spark = re.search(r'<path d="M413\.5 105\.5 Q[^"]*" fill="#FFC83D" ></path>', old).group(0)
        old = old.replace(spark, hm.sparkle(280, 112.5, 7))
    els = split_elements(old)
    home = [e for e in els if first_x(e) >= home_from and not e.startswith('<g transform')]
    rest = [e for e in els if e not in home]
    colours_x = (70 if not se else 22) + shift
    xs = {'shapes': colours_x - spacing, 'logic': colours_x - 2 * spacing, 'robots': colours_x - 3 * spacing, 'market': colours_x - 4 * spacing}
    cys = {'shapes': cy_high, 'logic': cy_low, 'robots': cy_high, 'market': cy_low}
    parts = hm.waves(W, H, shift % 120, 0)
    chain = [(colours_x, cy_low)] + [(xs[k], cys[k]) for k in ('shapes', 'logic', 'robots', 'market')]
    for (x1, y1), (x2, y2) in zip(chain, chain[1:]):
        parts.append(hm.hop(x1 - 96, y1 + 14, x2 + 96, y2 + 18))
    for k in ('shapes', 'logic', 'robots', 'market'):
        parts.append(hm.new_island(k, xs[k], cys[k], R, ry))
    sk = colours_x - 70
    parts += [hm.cloud(sk - 1000, 50), hm.cloud(sk - 520, 62, 0.85), hm.cloud(sk - 120, 46, 0.9),
              hm.sparkle(sk - 860, 126), hm.sparkle(sk - 300, 136, 6), hm.sparkle(sk - 1130, 150, 6),
              hm.boat(sk - 650, 160, 0.9), hm.gull(sk - 1210, 140), hm.gull(sk - 1180, 128)]
    parts.append('<g id="board" transform="translate(%s 0)">%s</g>' % (f(shift), ''.join(rest)))
    # The island where Counting Hills was (board x of counting + shift), and a hop from home to it.
    lx = (360 if not se else 268) + shift + D
    home_x = (640 if not se else 520) + shift + D
    hop_y = 282 if not se else 278
    parts.append(hm.dots('M%s %s C%s %s %s %s %s %s' % (f(home_x - 90), f(hop_y), f(home_x - 150), f(hop_y + 50), f(lx + 140), f(hop_y + 50), f(lx + 80), f(hop_y)), width=5, dash='2 12'))
    parts.append(languages_island(lx, cy_low, R + (4 if not se else 0), ry + (1 if not se else 2), 1.15 if not se else 1.0, -8 if not se else -10))
    parts += [hm.sparkle(lx - 70, 120, 6)]
    parts.append('<g id="home" transform="translate(%s 0)">%s</g>' % (f(shift + D), ''.join(home)))
    hm.write(out, hm.svg(W, H, label, parts))
    return lx, home_x


# ---------------------------------------------------------------- tablet portrait: 140 more sea at the bottom
def portrait_lang(out, W, H, D=400):
    label, old = hm.read_board('board25_home_tablet_portrait.svg')
    parts = hm.waves(W, H, 0, D)
    parts.append(hm.dots('M370 585 C340 500 410 400 470 300', width=6, dash='2 14'))
    parts.append(hm.new_island('market', 560, 270, 114, 66, 1.08))
    parts += [hm.cloud(150, 150, 1.1, 0.9), hm.cloud(720, 300, 0.9), hm.boat(170, 330, 1.1), hm.sparkle(330, 210, 8), hm.sparkle(760, 210, 7),
              hm.gull(250, 372), hm.gull(282, 360)]
    # The new bottom band: a hop from home down to the island, then the island, a boat and a gull.
    parts.append(hm.dots('M470 1488 C440 1550 410 1580 336 1578', width=6, dash='2 14'))
    parts.append(languages_island(232, 1580, 104, 56, 0.98))
    parts += [hm.boat(650, 1660, 1.0), hm.gull(520, 1610), hm.gull(552, 1598), hm.sparkle(430, 1690, 7), hm.sparkle(56, 1490, 6)]
    parts.insert(len(parts) - 7, '<g id="board" transform="translate(0 %s)">%s</g>' % (f(D), old))
    hm.write(out, hm.svg(W, H, label, parts))


# ---------------------------------------------------------------- tablet landscape: Market Village 50 left, the island at the top right
MARKET_DX = -50


def landscape_lang(out):
    s = open(os.path.join(SCENES, 'home_tablet_landscape.svg'), encoding='utf-8').read()
    head = re.match(r'<svg [^>]*>', s).group(0)
    els = split_elements(s[len(head):s.rindex('</svg>')])
    path_i = next(i for i, e in enumerate(els) if e.startswith('<path d="M1000 560 C900'))
    # Market Village is the run of elements from its sea halo (cx 900) to the last one of its stall, all between x 800 and 1000.
    first = next(i for i, e in enumerate(els) if e.startswith('<ellipse cx="900"'))
    market = []
    for i in range(first, len(els)):
        if els[i].startswith('<g') or not 800 <= first_x(els[i]) <= 1000:
            break
        market.append(i)
    host = next(i for i, e in enumerate(els) if e.startswith('<g transform="translate(945 235.6)'))
    gull = next(i for i, e in enumerate(els) if e.startswith('<path d="M1150 420'))
    els[path_i] = els[path_i].replace('C720 180 820 220 880 280', 'C720 180 %s 220 %s 280' % (f(820 + MARKET_DX), f(880 + MARKET_DX)))
    for i in market + [host]:
        els[i] = '<g transform="translate(%s 0)">%s</g>' % (f(MARKET_DX), els[i])
    els[gull] = ''
    clouds = next(i for i, e in enumerate(els) if e.startswith('<g opacity="0.9"><ellipse cx="160"'))
    new = [hm.dots('M1004 334 C990 384 966 430 954 486', width=6, dash='2 14'),
           languages_island(1082, 292, 88, 50, 0.84)]
    els[clouds:clouds] = new
    hm.write(out, head + ''.join(els) + '</svg>\n')
    return len(market)


# ---------------------------------------------------------------- the sign icon
def sign_icon():
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
            '<path d="M10 4.5 h9 a3 3 0 0 1 3 3 v4.5 a3 3 0 0 1 -3 3 h-0.5 l0.8 3 l-3.6 -3 h-5.7 a3 3 0 0 1 -3 -3 v-4.5 a3 3 0 0 1 3 -3 Z" '
            'fill="none" stroke="#2B2350" stroke-width="2.2" stroke-linejoin="round"/>'
            '<path d="M5 9 h8 a3 3 0 0 1 3 3 v4 a3 3 0 0 1 -3 3 h-5 l-3.8 3 l0.9 -3 h-0.1 a3 3 0 0 1 -3 -3 v-4 a3 3 0 0 1 3 -3 Z" fill="#2B2350"/>'
            '<path d="M4.6 14 q1.3 -1.6 2.6 0 q1.3 1.6 2.6 0 q1.3 -1.6 2.6 0" fill="none" stroke="#FFF6E8" stroke-width="1.5" stroke-linecap="round"/>'
            '</svg>\n')


def speaker_icon():
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
            '<path d="M3 9.5 h3.5 l5 -4.5 v14 l-5 -4.5 h-3.5 Z" fill="#2B2350" stroke="#2B2350" stroke-width="1.5" stroke-linejoin="round"/>'
            '<path d="M15 9 q2 3 0 6 M18 6.5 q4 5.5 0 11" fill="none" stroke="#2B2350" stroke-width="2.2" stroke-linecap="round"/>'
            '</svg>\n')


# ---------------------------------------------------------------- the hosts (512 canvas, the cast's style)
def host_heb():
    """Rock hyrax with a coral pencil."""
    fur, fur_d, cream, pale, rim = '#A98A6E', '#8C6F55', '#EADBC6', '#F4EADC', '#5E4634'
    out = [el('ellipse', cx=256, cy=466, rx=150, ry=11, fill=SHADOW)]
    # body (a loaf) with its shade, belly
    out += [el('ellipse', cx=248, cy=338, rx=142, ry=124, fill=fur_d),
            el('ellipse', cx=258, cy=330, rx=138, ry=122, fill=fur),
            el('ellipse', cx=256, cy=372, rx=82, ry=78, fill=cream)]
    # feet
    for x in (196, 316):
        out += [el('ellipse', cx=x, cy=448, rx=40, ry=18, fill=fur_d),
                el('ellipse', cx=x, cy=452, rx=26, ry=9, fill='#5C4330', opacity=0.55)]
        for dx in (-16, 0, 16):
            out.append(el('circle', cx=x + dx, cy=440, r=6.5, fill='#C9A07E'))
    # ears: small, round, dark-rimmed, set high at the back of the head
    for x in (178, 334):
        out += [el('circle', cx=x, cy=116, r=22, fill=rim), el('circle', cx=x, cy=118, r=14, fill='#E2A79C')]
    # head: no neck; wide at the top and narrowing to a pointed snout (a rounded wedge)
    head = 'M146 186 Q144 98 256 94 Q368 98 366 186 Q356 250 256 286 Q156 250 146 186 Z'
    out += [el('path', d=head, fill=fur_d, transform='translate(-6 6)'),
            el('path', d=head, fill=fur),
            el('ellipse', cx=304, cy=134, rx=30, ry=12, fill=FOAM, opacity=0.18, transform='rotate(-20 304 134)')]
    # pale patches over the eyes
    for x in (208, 304):
        out.append(el('ellipse', cx=x, cy=160, rx=24, ry=10, fill=pale, transform='rotate(%s %s 160)' % (8 if x < 256 else -8, x)))
    # muzzle and chin: a cream wedge to the nose
    out += [el('path', d='M200 220 Q256 196 312 220 Q300 262 256 282 Q212 262 200 220 Z', fill=cream),
            el('ellipse', cx=256, cy=290, rx=30, ry=10, fill=pale)]
    # eyes
    for x in (212, 300):
        out += [el('ellipse', cx=x, cy=190, rx=15, ry=18, fill=INK),
                el('circle', cx=x - 5, cy=183, r=5.5, fill=FOAM), el('circle', cx=x + 4, cy=197, r=2.6, fill=FOAM)]
    # nose at the snout's tip and the mouth
    out += [el('path', d='M242 246 Q256 239 270 246 Q266 258 256 260 Q246 258 242 246 Z', fill=INK),
            el('ellipse', cx=252, cy=246, rx=4.5, ry=2.2, fill=FOAM, opacity=0.5),
            el('path', d='M256 260 L256 266 M240 268 Q248 276 256 267 Q264 276 272 268', fill='none', stroke=INK, stroke_width=4.5, stroke_linecap='round', stroke_linejoin='round')]
    # whiskers
    for side in (-1, 1):
        for k, dy in enumerate((-6, 4, 14)):
            x1 = 256 + side * 36
            out.append(el('path', d='M%s %s q%s %s %s %s' % (f(x1), f(258 + dy), f(side * 24), f(-4 + k * 3), f(side * 52), f(-8 + k * 8)), fill='none', stroke='#3E2E22', stroke_width=2.4, stroke_linecap='round', opacity=0.8))
    # cheeks
    out += [el('ellipse', cx=186, cy=226, rx=15, ry=8, fill='#F4A7B4', opacity=0.8), el('ellipse', cx=326, cy=226, rx=16, ry=9, fill='#F4A7B4', opacity=0.8)]
    # the pencil, held across the belly, point down to the left
    out.append('<g transform="rotate(-32 256 360)">' + ''.join([
        el('rect', x=170, y=344, width=150, height=30, rx=4, fill=CORAL),
        el('rect', x=170, y=360, width=150, height=14, rx=3, fill='#D9604F'),
        el('rect', x=320, y=344, width=16, height=30, fill='#C9C3D9'),
        el('rect', x=336, y=344, width=22, height=30, rx=8, fill='#F4A7B4'),
        el('path', d='M170 344 L136 359 L170 374 Z', fill='#F2C58F'),
        el('path', d='M147 354 L136 359 L147 364 Z', fill=INK)]) + '</g>')
    # paws over the pencil
    out += [el('ellipse', cx=210, cy=380, rx=24, ry=19, fill=fur), el('ellipse', cx=306, cy=328, rx=24, ry=19, fill=fur),
            el('path', d='M196 384 q6 6 12 0 q6 6 12 0', fill='none', stroke=fur_d, stroke_width=3, stroke_linecap='round'),
            el('path', d='M292 332 q6 6 12 0 q6 6 12 0', fill='none', stroke=fur_d, stroke_width=3, stroke_linecap='round')]
    return out


def host_eng():
    """Budgerigar waving one wing."""
    green, green_d, belly, yellow = '#6CC24A', '#4E9F33', '#93D96B', '#FFD93D'
    out = [el('ellipse', cx=256, cy=466, rx=110, ry=11, fill=SHADOW)]
    # tail, long and blue, behind
    out += [el('path', d='M270 372 L372 470 Q364 486 346 482 L248 392 Z', fill='#3E6FD9'),
            el('path', d='M272 382 L356 462 Q350 470 340 468 L258 396 Z', fill='#5B8BEF')]
    # body
    out += [el('ellipse', cx=250, cy=314, rx=104, ry=124, fill=green_d),
            el('ellipse', cx=258, cy=308, rx=100, ry=122, fill=green),
            el('ellipse', cx=262, cy=336, rx=62, ry=84, fill=belly)]
    # the far wing, folded (dark scallops edged yellow)
    def wing(cx, cy, rx, ry, rot):
        w = [el('ellipse', cx=cx, cy=cy, rx=rx, ry=ry, fill='#3C7F2A', transform='rotate(%s %s %s)' % (f(rot), f(cx), f(cy)))]
        for k in range(4):
            yy = cy - ry * 0.55 + k * ry * 0.34
            w.append(el('path', d='M%s %s q%s %s %s 0 q%s %s %s 0' % (f(cx - rx * 0.6), f(yy), f(rx * 0.3), f(ry * 0.22), f(rx * 0.6), f(rx * 0.3), f(ry * 0.22), f(rx * 0.6)),
                        fill='none', stroke=yellow, stroke_width=5, stroke_linecap='round', transform='rotate(%s %s %s)' % (f(rot), f(cx), f(cy))))
        return w
    out += wing(170, 318, 42, 92, 12)
    # the near wing, raised in a wave
    out += wing(384, 214, 32, 78, 34)
    # feet: two toes forward each
    for x in (222, 290):
        out += [el('path', d='M%s 424 L%s 450' % (f(x), f(x)), fill='none', stroke='#8EA3C4', stroke_width=10, stroke_linecap='round'),
                el('path', d='M%s 450 l-16 10 M%s 450 l16 10 M%s 450 l0 14' % (f(x), f(x), f(x)), fill='none', stroke='#8EA3C4', stroke_width=8, stroke_linecap='round')]
    # head: yellow face, barred nape
    out += [el('circle', cx=252, cy=168, r=88, fill='#E9C22C'),
            el('circle', cx=258, cy=164, r=86, fill=yellow)]
    out.append(el('ellipse', cx=300, cy=118, rx=24, ry=10, fill=FOAM, opacity=0.3, transform='rotate(-25 300 118)'))
    # cheek patches and throat spots
    out += [el('ellipse', cx=190, cy=210, rx=17, ry=12, fill='#5B6FD6'), el('ellipse', cx=326, cy=210, rx=17, ry=12, fill='#5B6FD6')]
    for x, y in ((212, 238), (234, 246), (278, 246), (300, 238)):
        out.append(el('circle', cx=x, cy=y, r=7, fill=INK))
    # eyes with a pale ring
    for x in (218, 298):
        out += [el('circle', cx=x, cy=160, r=21, fill='#FFF7D6'),
                el('circle', cx=x, cy=161, r=16, fill=INK),
                el('circle', cx=x - 5, cy=154, r=5.5, fill=FOAM), el('circle', cx=x + 5, cy=167, r=2.5, fill=FOAM)]
    # cere and beak (short, hooked)
    out += [el('rect', x=240, y=178, width=34, height=14, rx=7, fill='#4F8FE8'),
            el('path', d='M236 192 Q257 186 278 192 Q276 214 257 226 Q238 214 236 192 Z', fill='#9A9C86'),
            el('path', d='M257 226 Q262 216 264 206', fill='none', stroke='#6F7160', stroke_width=3, stroke_linecap='round')]
    return out


def host_rus():
    """Giraffe in chibi proportions."""
    base, patch, line, mane, tuft, muzzle = '#F8D9A0', '#D9823B', '#FCEBC8', '#B8612A', '#6B3E1E', '#FBEBCD'
    out = [el('ellipse', cx=256, cy=466, rx=128, ry=11, fill=SHADOW)]
    # tail with tuft
    out += [el('path', d='M352 330 Q384 352 380 392', fill='none', stroke='#E8B26A', stroke_width=8, stroke_linecap='round'),
            el('ellipse', cx=380, cy=402, rx=10, ry=16, fill=tuft)]
    # legs (back two darker), hooves
    for x, c in ((200, '#E8B26A'), (316, '#E8B26A'), (226, base), (290, base)):
        out += [el('rect', x=x - 15, y=370, width=30, height=86, rx=12, fill=c),
                el('rect', x=x - 15, y=440, width=30, height=18, rx=6, fill='#5C3A22')]
    # body
    out += [el('ellipse', cx=258, cy=344, rx=112, ry=66, fill='#E8B26A'),
            el('ellipse', cx=262, cy=338, rx=108, ry=62, fill=base)]
    for (px, py, rx, ry) in ((200, 330, 26, 20), (258, 316, 24, 18), (318, 332, 26, 20), (232, 366, 20, 13), (292, 368, 20, 13)):
        out.append(el('ellipse', cx=px, cy=py, rx=rx, ry=ry, fill=patch))
    # neck (rising, slightly to the right), mane along its back
    out += [el('path', d='M214 330 L226 170 Q256 150 286 170 L300 330 Z', fill='#E8B26A'),
            el('path', d='M220 330 L232 170 Q258 154 284 170 L296 330 Z', fill=base),
            el('path', d='M286 172 Q298 250 300 318', fill='none', stroke=mane, stroke_width=11, stroke_linecap='round')]
    for (px, py, rx, ry) in ((248, 300, 18, 14), (268, 262, 14, 12), (246, 228, 14, 11), (266, 196, 11, 9)):
        out.append(el('ellipse', cx=px, cy=py, rx=rx, ry=ry, fill=patch))
    # ossicones with tufts
    for x in (226, 290):
        out += [el('rect', x=x - 7, y=48, width=14, height=46, rx=7, fill='#E8B26A'), el('circle', cx=x, cy=48, r=13, fill=tuft)]
    # ears sideways
    out += [el('ellipse', cx=164, cy=110, rx=38, ry=16, fill='#E8B26A', transform='rotate(18 164 110)'),
            el('ellipse', cx=168, cy=111, rx=26, ry=9, fill='#F4C2B4', transform='rotate(18 168 111)'),
            el('ellipse', cx=350, cy=110, rx=38, ry=16, fill='#E8B26A', transform='rotate(-18 350 110)'),
            el('ellipse', cx=346, cy=111, rx=26, ry=9, fill='#F4C2B4', transform='rotate(-18 346 111)')]
    # head (front) and muzzle
    out += [el('ellipse', cx=254, cy=130, rx=74, ry=66, fill='#E8B26A'),
            el('ellipse', cx=258, cy=126, rx=72, ry=64, fill=base),
            el('ellipse', cx=230, cy=86, rx=16, ry=11, fill=patch), el('ellipse', cx=292, cy=92, rx=12, ry=9, fill=patch),
            el('ellipse', cx=258, cy=172, rx=54, ry=36, fill=muzzle),
            el('ellipse', cx=240, cy=168, rx=5, ry=7, fill='#8A5634'), el('ellipse', cx=276, cy=168, rx=5, ry=7, fill='#8A5634'),
            el('path', d='M236 188 Q258 204 280 188', fill='none', stroke=INK, stroke_width=6, stroke_linecap='round')]
    # eyes with lashes
    for x in (222, 294):
        out += [el('ellipse', cx=x, cy=124, rx=15, ry=19, fill=INK),
                el('circle', cx=x - 5, cy=117, r=6, fill=FOAM), el('circle', cx=x + 4, cy=131, r=2.6, fill=FOAM)]
        for k in (-1, 0, 1):
            out.append(el('path', d='M%s 106 l%s -10' % (f(x + k * 8), f(k * 5)), fill='none', stroke=INK, stroke_width=3.5, stroke_linecap='round'))
    out += [el('ellipse', cx=192, cy=158, rx=13, ry=8, fill='#F4A7B4', opacity=0.8), el('ellipse', cx=324, cy=158, rx=13, ry=8, fill='#F4A7B4', opacity=0.8)]
    return out


HOSTS = {'eng': host_eng, 'heb': host_heb, 'rus': host_rus}
LABEL = {'eng': 'host of the English course', 'heb': 'host of the Hebrew course', 'rus': 'host of the Russian course'}


def host_svg(course):
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" role="img" aria-label="%s">' % LABEL[course]
            + ''.join(HOSTS[course]()) + '</svg>\n')


# ---------------------------------------------------------------- the doors (240 x 300), each with its host in front
HOST_IN_DOOR = {'eng': (120, 300, 0.36), 'heb': (120, 302, 0.38), 'rus': (120, 300, 0.40)}  # centre x, bottom y, scale


def door_svg(course, opened):
    c = COURSE[course]
    out = [el('ellipse', cx=120, cy=290, rx=100, ry=9, fill=SHADOW)]
    # limestone frame: an arch with a key stone, lit left and shaded right
    out += [el('path', d='M30 284 L30 108 A90 90 0 0 1 210 108 L210 284 Z', fill=STONE_SHADE),
            el('path', d='M30 284 L30 108 A90 90 0 0 1 196 70 L196 284 Z', fill=STONE),
            el('rect', x=24, y=278, width=192, height=12, rx=4, fill=STONE_EDGE),
            el('path', d='M108 18 L132 18 L128 40 L112 40 Z', fill=STONE_EDGE)]
    for (x1, y1, x2, y2) in ((30, 170, 50, 170), (30, 230, 50, 230), (190, 170, 210, 170), (190, 230, 210, 230), (48, 52, 62, 66), (192, 52, 178, 66)):
        out.append(el('path', d='M%s %s L%s %s' % (f(x1), f(y1), f(x2), f(y2)), fill='none', stroke=STONE_EDGE, stroke_width=3, stroke_linecap='round'))
    # the opening
    opening = 'M52 278 L52 116 A68 68 0 0 1 188 116 L188 278 Z'
    if opened:
        out += [el('path', d=opening, fill='#FFC83D'),
                el('path', d='M64 278 L64 120 A56 56 0 0 1 176 120 L176 278 Z', fill='#FFE08A'),
                el('path', d='M86 278 L86 132 A34 34 0 0 1 154 132 L154 278 Z', fill='#FFF3C4'),
                # the leaf swung back against the left side: a narrow trapezoid in the door colour
                el('path', d='M52 278 L52 112 Q60 90 76 84 L76 270 Z', fill=c['door_dark']),
                el('path', d='M58 270 L58 116 Q64 100 72 96 L72 266 Z', fill=c['door'])]
    else:
        out += [el('path', d=opening, fill=c['door']),
                el('path', d='M120 278 L120 48 A68 68 0 0 1 188 116 L188 278 Z', fill=c['door_dark'], opacity=0.28)]
        for x in (86, 120, 154):
            out.append(el('path', d='M%s 64 L%s 278' % (f(x), f(x)) if x != 120 else 'M120 48 L120 278', fill='none', stroke=c['door_dark'], stroke_width=3, opacity=0.55))
        # hinges, knob
        for y in (130, 236):
            out.append(el('rect', x=52, y=y, width=34, height=8, rx=3, fill='#3B2C85', opacity=0.55))
        out += [el('circle', cx=168, cy=196, r=7, fill=GOLD), el('circle', cx=166, cy=194, r=2.5, fill=FOAM, opacity=0.7)]
        # the window: round, arched or square (the door's own shape)
        if c['window'] == 'round':
            out += [el('circle', cx=120, cy=96, r=22, fill='#FFF3C4', stroke=c['door_dark'], stroke_width=5),
                    el('path', d='M98 96 L142 96 M120 74 L120 118', fill='none', stroke=c['door_dark'], stroke_width=4)]
        elif c['window'] == 'arch':
            out += [el('path', d='M100 118 L100 92 A20 20 0 0 1 140 92 L140 118 Z', fill='#FFF3C4', stroke=c['door_dark'], stroke_width=5),
                    el('path', d='M120 72 L120 118', fill='none', stroke=c['door_dark'], stroke_width=4)]
        else:
            out += [el('rect', x=100, y=74, width=40, height=40, rx=6, fill='#FFF3C4', stroke=c['door_dark'], stroke_width=5),
                    el('path', d='M100 94 L140 94 M120 74 L120 114', fill='none', stroke=c['door_dark'], stroke_width=4)]
    # the doorstep and the host in front
    out.append(el('rect', x=46, y=276, width=148, height=8, rx=3, fill='#D7C29A'))
    hx, hb, sc = HOST_IN_DOOR[course]
    out.append('<g transform="translate(%s %s) scale(%s)">%s</g>' % (f(hx - 256 * sc), f(hb - 470 * sc), f(sc), ''.join(HOSTS[course]())))
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 300" role="img" aria-label="door of the %s course%s">'
            % ({'eng': 'English', 'heb': 'Hebrew', 'rus': 'Russian'}[course], ', open' if opened else '') + ''.join(out) + '</svg>\n')


def write_to(folder, name, text):
    os.makedirs(folder, exist_ok=True)
    with open(os.path.join(folder, name), 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(text)


if __name__ == '__main__':
    print('phone', phone_strip_lang('board10_home_phone.svg', 'home_phone_lang.svg', 2382, 393, 1250, 280, 560, 262, 248, 280, 124, 67, False))
    print('phoneSE', phone_strip_lang('board12_home_phone_se.svg', 'home_phone_se_lang.svg', 2086, 375, 1167, 252, 440, 258, 244, 252, 120, 65, True))
    portrait_lang('home_tablet_portrait_lang.svg', 820, 1720)
    print('landscape market elements moved', landscape_lang('home_tablet_landscape_lang.svg'))
    write_to(UI, 'land_languages.svg', sign_icon())
    write_to(LANG, 'speaker.svg', speaker_icon())
    for course in ('eng', 'heb', 'rus'):
        write_to(LANG, 'host_%s.svg' % course, host_svg(course))
        write_to(LANG, 'door_%s.svg' % course, door_svg(course, False))
        write_to(LANG, 'door_%s_open.svg' % course, door_svg(course, True))
