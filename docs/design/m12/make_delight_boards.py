"""Storyboards of docs/design/m12/delight.md (M12, "delight"): what a right answer, the end of a lesson and a touch on the map
should feel like. Every frame is a real phone board (852 x 393 points, ActivitySpec of app/lib/child/activity_shell.dart) drawn
with the app's own rooms, characters, pictures and fonts through the M11 board toolkit (../m11/make_m11_boards.py), rendered by
headless Chrome:

    python docs/design/m12/make_delight_boards.py

  right_answer_count_phone.png   Band A count item in Counting Hills: today's right answer (the golden), then the new small burst
                                 frame by frame (0, 120, 350, 800, 1200 ms), the gentle try-again and the reduce-motion version.
  party_counting_hills_phone.png The end of a lesson: today's card (the golden), then the party in the room, the sticker the child
                                 taps, the touch party, the calm, and the reduce-motion version.
  map_tap_phone.png              The map: today (the golden), then tap toys (cloud, sea, companion, a land's landmark), today's
                                 island calling a small child, and the glide into the room.

These are storyboards for the developer and the owner, not screenshots. Poses that do not exist yet are stood in for by the closest
existing pose and named in the red caption ("to draw"). The confetti uses the rooms' own trail glyphs (the stair of Counting Hills),
the balloons are content/starter/balloon_*.svg, the fish and bird content/starter/fish.svg and bird.svg. Nothing is copied from any
other app: the only references are the motion rules of docs/design-spec.md section 10 and the research list in delight.md section 3.
Hebrew on the boards is a sample for the hebrew-text-editor, not final text.
"""
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'm11'))
import make_m11_boards as M   # noqa: E402

ROOT = M.ROOT
C, B = M.C, M.B
box, img, svg_at, esc, uri = M.box, M.img, M.svg_at, M.esc, M.uri
CAST, ART, PICS = M.CAST, M.ART, M.PICS
GOLD_TIP = os.path.join(ROOT, 'app', 'test', 'goldens')
ROOM = M.ROOM['numbers']
TEAM = '#B23A3A'
W, H = 852, 393

# ---- small pieces ---------------------------------------------------------------------------------------------------------


def finger(x, y, label='tap'):
    """Where the child's finger is: a soft disc and a ring (a storyboard mark, not app art)."""
    return [svg_at(x - 26, y - 26, 52, 52, '<circle cx="26" cy="26" r="22" fill="rgba(43,35,80,.16)"/>'
                   '<circle cx="26" cy="26" r="22" fill="none" stroke="%s" stroke-width="2.5" stroke-dasharray="5 4"/>' % TEAM),
            box(x + 20, y + 14, 80, 16, 'font:700 12px/16px sans-serif;color:%s' % TEAM, esc(label))]


def note(x, y, text, w=220, align='left'):
    return box(x, y, w, 40, 'overflow:visible;font:700 17px/1.25 sans-serif;color:%s;text-align:%s;white-space:pre-wrap;'
               'text-shadow:0 0 3px #fff,0 0 3px #fff' % (TEAM, align), esc(text))


def glyph(x, y, s, shape, fill, rot=0, stroke=None, alpha=1.0):
    st = ' stroke="%s" stroke-width="1.4" stroke-linejoin="round"' % stroke if stroke else ''
    return svg_at(x - s / 2, y - s / 2, s, s, '<g fill="%s"%s opacity="%.2f">%s</g>' % (fill, st, alpha, shape), '0 0 20 20',
                  'transform:rotate(%ddeg)' % rot)


STAIR = M.TRAIL['stair']
STAR = '<path d="M10 0.8 L12.6 7 L19.2 7.4 L14 11.6 L15.8 18.2 L10 14.5 L4.2 18.2 L6 11.6 L0.8 7.4 L7.4 7 Z"/>'
SPARK4 = '<path d="M10 1 Q11.2 8.8 19 10 Q11.2 11.2 10 19 Q8.8 11.2 1 10 Q8.8 8.8 10 1 Z"/>'
DOT = '<circle cx="10" cy="10" r="8"/>'
PALETTE = [ROOM['rim'], C['spark'], C['sky'], C['lilac'], '#7BD389', C['sunset']]


def burst(cx, cy, r, n=12, seed=1, size=(16, 22), alpha=1.0, shapes=(STAIR, STAR, SPARK4, DOT)):
    """The small burst: room glyphs and sparks on a ring of radius r round (cx, cy)."""
    rnd = random.Random(seed)
    out = []
    for i in range(n):
        a = 2 * math.pi * i / n + rnd.uniform(-0.18, 0.18)
        rr = r * rnd.uniform(0.82, 1.12)
        s = rnd.uniform(*size)
        out.append(glyph(cx + rr * math.cos(a), cy + rr * math.sin(a), s, shapes[i % len(shapes)], PALETTE[i % len(PALETTE)],
                         rot=rnd.randint(-40, 40), stroke=C['ink'] if shapes[i % len(shapes)] is STAIR else None, alpha=alpha))
    return out


def rain(x0, x1, y0, y1, n, seed=3, size=(14, 24), alpha=1.0):
    rnd = random.Random(seed)
    out = []
    for i in range(n):
        shape = (STAIR, STAR, SPARK4, DOT, STAIR)[i % 5]
        out.append(glyph(rnd.uniform(x0, x1), rnd.uniform(y0, y1), rnd.uniform(*size), shape, PALETTE[i % len(PALETTE)],
                         rot=rnd.randint(-60, 60), stroke=C['ink'] if shape is STAIR else None, alpha=alpha))
    return out


def arc_point(x0, y0, x1, y1, lift, t, dx=0):
    mx, my = (x0 + x1) / 2 + dx, min(y0, y1) - lift
    return ((1 - t) ** 2 * x0 + 2 * (1 - t) * t * mx + t * t * x1, (1 - t) ** 2 * y0 + 2 * (1 - t) * t * my + t * t * y1)


def path_arc(x0, y0, x1, y1, lift, dashed=True, color=TEAM, width=2.5, dx=0):
    mx, my = (x0 + x1) / 2 + dx, min(y0, y1) - lift
    minx, miny = min(x0, x1, mx) - 10, min(y0, y1, my) - 10
    w, h = abs(max(x0, x1, mx) - minx) + 20, abs(max(y0, y1) - miny) + 20
    d = 'M%g %g Q%g %g %g %g' % (x0 - minx, y0 - miny, mx - minx, my - miny, x1 - minx, y1 - miny)
    return svg_at(minx, miny, w, h, '<path d="%s" fill="none" stroke="%s" stroke-width="%g" stroke-linecap="round"%s/>' % (
        d, color, width, ' stroke-dasharray="6 6"' if dashed else ''))


def spark_at(x, y, s=26):
    return svg_at(x - s / 2, y - s / 2, s, s, '<g fill="%s" stroke="%s" stroke-width="1">%s</g>' % (C['spark'], C['sparkDeep'], SPARK4),
                  '0 0 20 20')


def ttile(x, y, s, text, state='idle', sx=1.0, sy=1.0, rot=0, lift=0):
    """An answer tile (components.dart AnswerTile) with a transform: squash, pop, wobble. state: idle, correct, notYet."""
    border = {'idle': C['hairline'], 'correct': '#FFB800', 'notYet': '#B9A2F7'}[state]
    fill = C['sparkTint'] if state == 'correct' else '#fff'
    dots = '<div style="display:flex;gap:4px;justify-content:center;margin-top:4px">%s</div>' % ''.join(
        '<span style="width:7px;height:7px;border-radius:50%%;background:%s;display:inline-block"></span>' % C['inkSoft']
        for _ in range(int(text)))
    inner = '<div style="text-align:center">%s%s</div>' % (M.numeral(text, 52), dots)
    out = [box(x, y - lift, s, s, 'background:%s;border:4px solid %s;border-radius:28px;box-shadow:0 %dpx 0 %s,0 6px 16px rgba(43,35,80,.14);'
               'display:flex;align-items:center;justify-content:center;transform:scale(%g,%g) rotate(%gdeg);transform-origin:50%% 100%%' % (
                   fill, border, 6 if lift >= 0 else 3, C['lip'], sx, sy, rot), inner)]
    return out


def badge(x, y, s=36, scale=1.0):
    return [box(x - s / 2, y - s / 2, s, s, 'background:%s;border-radius:50%%;border:3px solid #fff;box-shadow:0 2px 6px rgba(43,35,80,.2);'
                'display:flex;align-items:center;justify-content:center;transform:scale(%g)' % (C['spark'], scale),
                '<svg viewBox="0 0 24 24" width="%d" height="%d"><path d="M5 12.5l4.2 4.2L19 7" fill="none" stroke="#2B2350" stroke-width="3.2" '
                'stroke-linecap="round" stroke-linejoin="round"/></svg>' % (s * 0.62, s * 0.62))]


# ---- the count item (Band A, P1 look on the phone) ----------------------------------------------------------------------------
TS, TG = 96, 24                          # P1 tile and its gap (B-29)
TX0 = 71 + (534 - (3 * TS + 2 * TG)) / 2
TY = 244
TILES = ['4', '3', '2']                  # the numeral row keeps the template's order (left to right, maths is LTR)
TCX = [TX0 + i * (TS + TG) + TS / 2 for i in range(3)]
GX, GY, GS = B['phone']['guide']
LM = (644, 12, 64)                        # the header's landmark slot on the phone (LandmarkSlot.headerBox)
BUTTERFLY = os.path.join(PICS, 'butterfly.svg')
FLOWER = os.path.join(PICS, 'flower_target.svg')


def socket_xy(n, i):
    w = n * 20 + (n - 1) * 8 + 16
    cx, top = B['phone']['trail']
    x0 = cx - w / 2
    return x0 + w - 8 - 20 - i * 28 + 10, top + 18


def count_board(done=2, flap=0.0, lit=False, bubble_text='כַּמָּה פַּרְפָּרִים יֵשׁ עַל הַפֶּרַח?', guide='nitzi-idle.svg', guide_lift=0,
                guide_scale=1.0, tiles=None, trail_glow=None, landmark_lit=False):
    out = M.base('phone', ROOM, n=5, done=done)
    sx, sy, sw, sh = B['phone']['stage']

    def inner(ix, iy, iw, ih):
        parts = [img(FLOWER, ix + iw - 120, iy + 10, 84, 105)]
        # the three counted butterflies sit on the flower; with flap > 0 they lift and open (the stage is happy)
        for k, (dx, dy) in enumerate(((-62, 18), (-104, 52), (-40, 64))):
            up = flap * (14 + 6 * k)
            parts.append(img(BUTTERFLY, ix + iw - 120 + 42 + dx, iy + dy - up, 44, 44,
                             'transform:scaleX(%g) rotate(%ddeg)' % (1 - 0.35 * flap * (k % 2), int(8 * flap * (1 if k % 2 else -1)))))
        parts.append(box(ix + iw - 98, iy + ih - 44, 40, 40, 'background:#fff;border-radius:50%;box-shadow:0 2px 6px rgba(43,35,80,.15);'
                         'display:flex;align-items:center;justify-content:center', M.numeral('3', 24)))
        return parts

    out += M.stage('phone', ROOM, inner, landmark=False)
    # the header's landmark (the stage reaction's place on a phone today)
    out.append(img(os.path.join(M.ROOMART, 'numbers_landmark.svg'), *LM[:2], LM[2], LM[2]))
    if landmark_lit:
        out.append(img(os.path.join(M.ROOMART, 'numbers_reacted.svg'), *LM[:2], LM[2], LM[2]))
    out.append(M.character(os.path.join(CAST, guide), GX - (guide_scale - 1) * GS / 2, GY - guide_lift - (guide_scale - 1) * GS, GS * guide_scale))
    if bubble_text:
        out += M.bubble('phone', bubble_text, tail_y=46)
    for i, t in enumerate(TILES):
        spec = (tiles or {}).get(t, {})
        out += ttile(TX0 + i * (TS + TG), TY, TS, t, **spec)
    if trail_glow is not None:
        x, y = socket_xy(5, trail_glow)
        out.append(box(x - 22, y - 22, 44, 44, 'border-radius:50%;background:radial-gradient(rgba(255,200,61,.85) 0%, rgba(255,200,61,0) 70%)'))
    return out


def right_answer_sheet():
    cells = []
    cells.append(([img(os.path.join(GOLD_TIP, 'm11_room_numbers_reacted_phone.png'), 0, 0, W, H)], W, H,
                  'TODAY (fb39dc08 and lands-ux tip, the same code): the tile turns pale yellow and a 28 pt tick appears (no pop);\n'
                  'the companion hops 17 pt with seven ~6 pt sparks; the 64 pt landmark in the header grows 15 %; a voice line.\n'
                  'No sound effect, no haptic, nothing on the stage. Next item after 1.6 s.'))
    i3 = TILES.index('3')
    # 0 ms: touch-down
    f = count_board(tiles={'3': dict(sx=1.04, sy=0.9, lift=-3)})
    f += finger(TCX[i3], TY + 60, 'touch-down')
    f.append(note(20, 352, 'touch-down: squash 0.94, lip pressed (≤ 50 ms), "tok", light haptic', 600))
    cells.append((f, W, H, '1 · 0 ms TOUCH: every tile and every counted object gives under the finger at once (before the answer is known).'))
    # 120 ms: pop and burst
    f = count_board(tiles={'3': dict(state='correct', sx=1.16, sy=1.16)}, guide='nitzi-celebrate.svg')
    f.append(svg_at(TCX[i3] - 80, TY + TS / 2 - 80, 160, 160, '<circle cx="80" cy="80" r="74" fill="none" stroke="#FFC83D" stroke-width="5" opacity=".75"/>'
                    '<circle cx="80" cy="80" r="62" fill="none" stroke="#fff" stroke-width="3" opacity=".9"/>'))
    f += burst(TCX[i3], TY + TS / 2, 100, n=16, seed=4, size=(20, 28))
    f += badge(TCX[i3] + TS / 2 - 2, TY - 2, 36, 1.2)
    f.append(note(20, 352, 'pop 1→1.16→1 (280 ms), badge 36 pt, 16 room glyphs fly out', 640))
    cells.append((f, W, H, '2 · 120 ms POP + BURST: the tile pops and fills, the badge pops, a ring of Counting Hills stairs and sparks bursts\n'
                           'from the tile (16 to 24 pt, gone by 700 ms). Every right answer, every land, in its own glyph.'))
    # 350 ms: the spark flies to the trail, the companion jumps, the butterflies lift
    sxk, syk = socket_xy(5, 2)
    f = count_board(tiles={'3': dict(state='correct')}, guide='nitzi-celebrate.svg', guide_lift=44, flap=1.0)
    f += badge(TCX[i3] + TS / 2 - 2, TY - 2, 36)
    f += burst(TCX[i3], TY + TS / 2, 124, n=14, seed=4, alpha=0.45, size=(12, 16))
    f.append(path_arc(TCX[i3], TY, sxk, syk + 12, 40, dx=-260))
    px, py = arc_point(TCX[i3], TY, sxk, syk + 12, 40, 0.45, dx=-260)
    f.append(spark_at(px, py, 34))
    f.append(box(GX + 40, GY + GS - 22, GS - 80, 14, 'border-radius:50%;background:rgba(43,35,80,.18)'))
    f.append(note(GX - 30, GY + GS + 2, 'jump 44 pt\n(to draw: cheer-jump)', 230))
    f.append(note(20, 352, 'spark arcs to the trail; butterflies flutter up', 600))
    cells.append((f, W, H, '3 · 350 ms FLY: a spark flies from the tile to the next socket of the trail; the companion jumps (a real jump, 25 %\n'
                           'of its height, not 10 %); the stage itself answers: the three butterflies flutter up off the flower.'))
    # 800 ms: land, socket drinks, landmark, praise
    f = count_board(done=3, tiles={'3': dict(state='correct')}, guide='nitzi-celebrate.svg', flap=0.4, trail_glow=2,
                    bubble_text='יֵשׁ! שְׁלוֹשָׁה!', landmark_lit=True)
    f += badge(TCX[i3] + TS / 2 - 2, TY - 2, 36)
    f += burst(LM[0] + 32, LM[1] + 32, 40, n=8, seed=9, size=(10, 14))
    f.append(note(20, 352, 'socket drinks the spark; landmark reacts; praise', 600))
    cells.append((f, W, H, '4 · 800 ms LAND: the socket fills with a little bounce; the landmark reacts as today; the companion lands with a\n'
                           'squash; a short praise line (voice-and-sound-director, about 30 of them, never the same twice in a row).'))
    # 1200 ms: calm; free taps make sparkles
    f = count_board(done=3, tiles={'3': dict(state='correct')}, guide='nitzi-celebrate.svg', bubble_text='יֵשׁ! שְׁלוֹשָׁה!', landmark_lit=True)
    f += badge(TCX[i3] + TS / 2 - 2, TY - 2, 36)
    f += finger(190, 160, 'free tap')
    f += burst(190, 160, 30, n=6, seed=11, size=(10, 14), shapes=(STAR, SPARK4))
    f.append(note(20, 352, 'burst over; free taps sparkle until the next item', 620))
    cells.append((f, W, H, '5 · 1200 ms DONE: the burst never blocks; the next item comes at the praise pause as today. A touch on the stage\n'
                           'while waiting gives a little sparkle (never a sound that sounds like "right").'))
    # try again
    i4 = TILES.index('4')
    f = count_board(tiles={'4': dict(state='notYet', rot=-6)}, guide='nitzi-encourage.svg', bubble_text='בּוֹאוּ נִסְפֹּר שׁוּב!')
    f.append(path_arc(TCX[i4] - 30, TY + 10, TCX[i4] + 30, TY + 10, 14, color=C['lilac']))
    f.append(note(20, 352, 'shy rock ±6°, 3 times, 360 ms; lilac ring', 600))
    f.append(note(GX - 30, GY + GS + 2, 'to draw:\noops-giggle', 230))
    cells.append((f, W, H, '6 · NOT YET: the tile rocks shyly and stays (no cross, no red, no buzzer); the companion shrugs and smiles and\n'
                           'invites ("let\'s count again!"); the hint picture comes as today. The next touch is free at once.'))
    # reduce motion
    f = count_board(done=3, tiles={'3': dict(state='correct')}, guide='nitzi-celebrate.svg', bubble_text='יֵשׁ! שְׁלוֹשָׁה!', trail_glow=2,
                    landmark_lit=True)
    f += badge(TCX[i3] + TS / 2 - 2, TY - 2, 36)
    f.append(box(TX0 + i3 * (TS + TG) - 10, TY - 10, TS + 20, TS + 20, 'border-radius:36px;background:radial-gradient(rgba(255,200,61,.5) 0%, rgba(255,200,61,0) 72%)'))
    cells.append((f, W, H, '7 · REDUCE MOTION: one warm glow round the tile (120 ms fade), the badge, the socket filled, the celebrate pose;\n'
                           'no flight, no particles, no jump. The sound and the praise line are the same.'))
    M.page(cells, os.path.join(HERE, 'right_answer_count_phone.png'), 1690, scale=0.62)


# ---- the party at the end of a lesson -----------------------------------------------------------------------------------------
NEKUDI = os.path.join(CAST, 'nekudi-celebrate.svg')
NITZI_C = os.path.join(CAST, 'nitzi-celebrate.svg')
STICKER = os.path.join(ART, 'stickers', 'sticker_04.svg')
BOOK = os.path.join(ART, 'ui', 'sticker.svg')
BALLOONS = ['balloon_red', 'balloon_yellow', 'balloon_blue', 'balloon_green', 'balloon_purple']


def room_full(extra=None):
    out = [box(0, 0, W, H, 'background:%s;border:1px solid #C9C3D9' % ROOM['tint'])]
    out.append(svg_at(0, 0, W, H, M.backdrop('numbers', W, H)))
    return out


def landmark_big(x, y, s, piece=True, glow=True, room='numbers'):
    out = []
    if glow:
        out.append(box(x - 30, y - 30, s + 60, s + 60, 'border-radius:50%;background:radial-gradient(rgba(255,241,196,.95) 0%, rgba(255,241,196,0) 68%)'))
    out.append(img(os.path.join(M.ROOMART, '%s_landmark.svg' % room), x, y, s, s))
    if piece:
        out.append(img(os.path.join(M.ROOMART, '%s_piece.svg' % room), x, y, s, s))
    return out


def home_pebble(x, y, s=88, glow=False):
    out = []
    if glow:
        out.append(box(x - 16, y - 16, s + 32, s + 32, 'border-radius:50%;background:radial-gradient(rgba(255,200,61,.7) 0%, rgba(255,200,61,0) 70%)'))
    out += M.pebble(x, y, s, 'home_palm.svg', C['spark'], C['sparkDeep'])
    return out


def balloon(x, y, s, name, dots, pop=False):
    if pop:
        return burst(x + s / 2, y + s * 0.4, s * 0.55, n=10, seed=dots, size=(12, 18))
    out = [img(os.path.join(PICS, name + '.svg'), x, y, s, s)]
    # the app draws the dots (and, for the older children, the numeral) on the balloon; a pre-reader counts the dots
    k = s * 0.09
    for i in range(dots):
        r, c = divmod(i, 3)
        out.append(box(x + s * 0.5 - (min(dots - r * 3, 3) * k * 1.6) / 2 + c * k * 1.6, y + s * 0.26 + r * k * 1.7, k, k,
                       'border-radius:50%;background:#fff;border:1.5px solid #2B2350'))
    return out


def party_sheet():
    cells = []
    cells.append(([img(os.path.join(GOLD_TIP, 'm11_celebration_numbers_phone.png'), 0, 0, W, H)], W, H,
                  'TODAY: a white card on a grey veil over the lesson. A 140 pt window with Nekudi and the companion (~130 pt),\n'
                  'the stair\'s new piece fades in with a 10 % squash, two lines a 2-year-old cannot read, one button home.\n'
                  'No confetti, no sound effect, nothing to touch but the button. The sticker sits in the window\'s corner.'))
    # 1 the room opens
    f = room_full()
    f.append(box(71 - 4, 96 - 4, 338, 136, 'border:3px dashed %s;border-radius:28px' % TEAM))
    for (x0, y0, x1, y1) in ((67, 92, 10, 10), (405, 92, 842, 10), (67, 232, 10, 383), (405, 232, 842, 383)):
        f.append(svg_at(min(x0, x1), min(y0, y1), abs(x1 - x0) + 1, abs(y1 - y0) + 1,
                        '<path d="M%g %g L%g %g" stroke="%s" stroke-width="2" stroke-dasharray="5 5"/>' % (
                            x0 - min(x0, x1), y0 - min(y0, y1), x1 - min(x0, x1), y1 - min(y0, y1), TEAM)))
    f += landmark_big(60, 190, 150, piece=False, glow=False)
    f.append(note(430, 300, '0–450 ms: the stage grows to\nthe whole screen; no grey veil', 400))
    cells.append((f, W, H, '1 · 0 s THE ROOM OPENS: the lesson\'s own stage widens to the whole screen. The child stays in the place she\n'
                           'played in; nothing covers it.'))
    # 2 friends jump in, confetti
    f = room_full()
    f += landmark_big(40, 200, 150, piece=False)
    f += rain(20, 830, 10, 300, 52, seed=7, size=(20, 32))
    f.append(M.character(NEKUDI, 300, 120, 240))
    f.append(M.character(NITZI_C, 500, 150, 210))
    f.append(path_arc(860, 300, 560, 200, 80))
    f.append(note(560, 8, 'to draw: 2 dance frames\nper host and companion', 290))
    cells.append((f, W, H, '2 · 0.5–1.5 s FRIENDS JUMP IN: Nekudi (240 pt) and the companion (210 pt) leap in from the end side and dance;\n'
                           'stair-and-spark confetti rains in the land\'s colours for 2.5 s (about 50 pieces, 20 to 32 pt). A party sting.'))
    # 3 the new piece and the sticker arrives
    f = room_full()
    f += rain(20, 830, 250, 392, 18, seed=8, alpha=0.8)
    f += landmark_big(40, 120, 190)
    f += burst(40 + 95, 120 + 40, 70, n=10, seed=12, shapes=(STAR, SPARK4), size=(14, 20))
    f.append(M.character(NEKUDI, 240, 150, 200))
    f.append(M.character(NITZI_C, 670, 170, 180))
    f.append(path_arc(150, 120, 480, 220, 90))
    f.append(box(470, 205, 150, 150, 'background:#fff;border-radius:34px;box-shadow:0 8px 0 #E6DDF0,0 10px 24px rgba(43,35,80,.22);'
                 'transform:rotate(-6deg)', '<img src="%s" style="width:130px;height:130px;margin:10px">' % uri(STICKER)))
    f.append(note(600, 330, 'sticker 150 pt, rocking:\n"tap me" (no words)', 260))
    cells.append((f, W, H, '3 · 1.5–2.5 s THE NEW PIECE: the landmark (now 190 pt) builds its golden step with a spark fountain; a sticker\n'
                           'flies out of it and lands in front of the child, big, rocking gently. It waits for her finger.'))
    # 4 the child taps the sticker: it flies into her book
    f = room_full()
    f += landmark_big(40, 120, 190)
    f.append(M.character(NEKUDI, 320, 150, 200))
    f.append(M.character(NITZI_C, 600, 120, 180))
    f += finger(495, 275, 'tap')
    f.append(path_arc(495, 260, 800, 330, 160))
    f.append(box(640, 60, 86, 86, 'background:#fff;border-radius:22px;box-shadow:0 6px 16px rgba(43,35,80,.2);transform:rotate(14deg)',
                 '<img src="%s" style="width:72px;height:72px;margin:7px">' % uri(STICKER)))
    f.append(box(756, 290, 88, 88, 'background:#fff;border-radius:24px;box-shadow:0 6px 0 #E6DDF0', '<img src="%s" style="width:64px;height:64px;margin:12px">' % uri(BOOK)))
    f.append(note(560, 225, 'into her book\n("whoosh")', 190))
    cells.append((f, W, H, '4 · HER TAP: the sticker spins into her sticker book (88 pt, bottom start corner), which bounces; the companion cheers.\n'
                           'She did the last step of the reward herself. (No tap within 6 s: the sticker flies in by itself.)'))
    # 5 touch party
    f = room_full()
    f += landmark_big(40, 120, 190)
    f.append(M.character(NEKUDI, 330, 150, 200))
    f.append(M.character(NITZI_C, 560, 175, 170, 'transform:rotate(-8deg)'))
    for k, (x, y, s) in enumerate(((230, 20, 100), (440, 10, 96), (520, 60, 100), (690, 20, 98), (760, 130, 90))):
        f += balloon(x, y, s, BALLOONS[k], k + 1, pop=(k == 2))
    f += finger(570, 100, 'pop!')
    f.append(note(600, 165, 'Nekudi counts\nthe pops aloud', 240))
    f.append(note(20, 350, 'tap a friend: a giggle and a silly move (to draw)', 600))
    cells.append((f, W, H, '5 · TOUCH PARTY (Counting Hills\' own toy): balloons carrying 1 to 5 dots float up; a tap pops one into confetti and\n'
                           'Nekudi counts it. Every tap anywhere sparkles. Each land has its own toy (delight.md 4.2).'))
    # 6 calm
    f = room_full()
    f += landmark_big(40, 120, 190)
    f.append(M.character(os.path.join(CAST, 'nekudi-talk.svg'), 240, 150, 200))
    f.append(M.character(os.path.join(CAST, 'nitzi-wave.svg'), 600, 160, 180))
    f += home_pebble(454, 286, 88, glow=True)
    f.append(note(20, 330, 'home 88 pt; glows after\n20 s still; no countdown', 300))
    cells.append((f, W, H, '6 · CALM: after 20 s without a touch the confetti stops and the friends wave; the home pebble glows. Nothing\n'
                           'ends by itself and nothing is lost by leaving. Tapping the land again starts the party toy again.'))
    # 7 reduce motion
    f = room_full()
    f += landmark_big(40, 120, 190)
    f.append(M.character(NEKUDI, 240, 150, 200))
    f.append(M.character(NITZI_C, 600, 170, 180))
    f.append(box(440, 40, 120, 120, 'background:#fff;border-radius:30px;box-shadow:0 6px 16px rgba(43,35,80,.2)', '<img src="%s" style="width:104px;height:104px;margin:8px">' % uri(STICKER)))
    f += home_pebble(454, 286, 88)
    cells.append((f, W, H, '7 · REDUCE MOTION: the whole room, the landmark with its piece, both friends in their celebrate poses, the sticker\n'
                           'already in place; a tap on it fades it into the book. No confetti, no flights; the sound is the same.\n'))
    M.page(cells, os.path.join(HERE, 'party_counting_hills_phone.png'), 1690, scale=0.62)


# ---- the map ------------------------------------------------------------------------------------------------------------------
MAP = os.path.join(GOLD_TIP, 'home_phone.png')
FISH = os.path.join(PICS, 'fish.svg')
BIRD = os.path.join(PICS, 'bird.svg')


def map_base(extra_style=''):
    return [img(MAP, 0, 0, W, H, extra_style)]


def map_sheet():
    cells = []
    cells.append((map_base(), W, H, 'TODAY: a still picture. Only the land areas, the companion (a 1.6 s wave), the "+" and the bottle pill take a\n'
                                  'touch; a touch on the sea, a cloud, a palm or a land that is not ready does nothing at all.'))
    # cloud
    f = map_base()
    f.append(box(230, 44, 84, 46, 'border-radius:40px;background:#fff;opacity:.95;transform:scale(1.25)'))
    for k in range(5):
        f.append(svg_at(236 + k * 16, 100 + (k % 2) * 14, 14, 18, '<path d="M7 1 Q12 9 7 17 Q2 9 7 1 Z" fill="%s"/>' % C['sky'], '0 0 14 18'))
    f += finger(272, 66, 'tap')
    f.append(note(330, 96, 'puff 1.25 (300 ms),\ndrops sparkle, "pff"', 260))
    cells.append((f, W, H, '1 · A CLOUD: puffs, sprinkles a few drops that sparkle where they land; it drifts on. ≤ 1 s, a soft sound.'))
    # sea / fish
    f = map_base()
    f.append(svg_at(60, 178, 70, 24, '<ellipse cx="35" cy="12" rx="32" ry="9" fill="none" stroke="#fff" stroke-width="3"/>'
                    '<ellipse cx="35" cy="12" rx="18" ry="5" fill="none" stroke="#fff" stroke-width="2.5" opacity=".7"/>'))
    f.append(path_arc(95, 188, 190, 170, 90, color='#fff'))
    f.append(img(FISH, 120, 88, 60, 60, 'transform:rotate(-30deg)'))
    f += finger(95, 190, 'tap the sea')
    f.append(note(200, 100, 'fish jumps (700 ms),\nsplash rings, "bloop"', 260))
    cells.append((f, W, H, '2 · THE SEA: wherever she taps the water, a splash ring, and every second tap a fish (or a bird from the sky) jumps.\n'
                           'Three fish colours, never the same twice in a row.'))
    # companion
    f = map_base()
    f.append(svg_at(600, 150, 180, 170, '<path d="M30 40 Q10 85 30 130 M150 40 Q170 85 150 130" fill="none" stroke="%s" stroke-width="4" '
                    'stroke-linecap="round" stroke-dasharray="3 9"/>' % C['spark']))
    f += burst(688, 210, 80, n=9, seed=21, shapes=(STAR, SPARK4), size=(16, 22))
    f += finger(690, 262, 'tap')
    f.append(note(430, 96, '1 of 5 moves, to draw:\ngiggle-spin, jump,\npeekaboo, sparkle-sneeze,\nhigh-five', 230))
    cells.append((f, W, H, '3 · THE COMPANION: a giggle and one of five moves, each with its own sound; tickle twice and she laughs harder.\n'
                           'Her bubble says the child\'s name aloud (the voice, not text she must read).'))
    # landmark
    f = map_base()
    for k, (x, y) in enumerate(((430, 280), (412, 262), (394, 244), (376, 226))):
        f.append(svg_at(x - 9, y - 9 - 12, 18, 18, '<circle cx="9" cy="9" r="8" fill="%s" stroke="#2B2350" stroke-width="2" opacity="%.2f"/>' % (
            C['sunset'], 0.35 + 0.2 * k), '0 0 18 18'))
    f += burst(372, 214, 40, n=8, seed=5, size=(12, 18))
    f += finger(392, 262, 'tap')
    f.append(note(440, 110, 'the room\'s own reaction\non touch-down; opens\non the finger\'s lift', 270))
    cells.append((f, W, H, '4 · A LAND\'S LANDMARK: answers on touch-down with its own reaction (the same as in its room), and opens when the finger\n'
                           'lifts. A land that is not ready still reacts and the companion says "soon" (voice): a touch is never lost.'))
    # beckon
    f = map_base()
    f.append(box(236, 196, 256, 150, 'border-radius:50%;border:5px solid rgba(255,200,61,.85);box-shadow:0 0 30px rgba(255,200,61,.8)'))
    f.append(svg_at(480, 170, 170, 90, '<path d="M160 60 Q90 -10 14 62" fill="none" stroke="#FFC83D" stroke-width="6" stroke-dasharray="2 12" stroke-linecap="round"/>'
                    '<path d="M24 44 L12 64 L34 70" fill="none" stroke="#FFC83D" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>'))
    f.append(note(20, 100, 'P0/P1, 3 s still: the\nisland hops gently, a\npath of light from the\nfriend; "let\'s go!" (voice)', 240))
    cells.append((f, W, H, '5 · TODAY\'S ISLAND CALLS: for the youngest, the friend shows the way with a path of light and a hop of the island.\n'
                           'One tap and she is in. No arrow text, no pill to read.'))
    # glide
    f = [box(0, 0, W, H, 'overflow:hidden', '<img src="%s" style="position:absolute;left:-440px;top:-440px;width:%dpx;height:%dpx">' % (
        uri(MAP), W * 2.4, H * 2.4))]
    f.append(box(0, 0, W, H, 'background:radial-gradient(rgba(255,255,255,0) 40%, rgba(255,246,232,.85) 100%)'))
    f.append(note(20, 350, '600 ms glide into the island (design-spec 10.2)', 700))
    cells.append((f, W, H, '6 · THE GLIDE: the map flies into the island and the room appears out of it (600 ms). P0 and P1 skip the island\n'
                           'screen and the long greeting: from this tap to the first thing to touch in under 4 s.\n\n'))
    M.page(cells, os.path.join(HERE, 'map_tap_phone.png'), 1690, scale=0.62)


# ---- Colour Bay, the pilot land ---------------------------------------------------------------------------------------------
CROOM = M.ROOM['colors']
DROP = M.TRAIL['drop']
GONI = {p: os.path.join(ART, 'hosts', 'goni_%s.svg' % p) for p in ('idle', 'talk', 'show', 'celebrate')}
# GoniSkin (app/lib/rooms/goni_skin.dart): the sentinel colours of the mint look, and the tones of a lesson colour
_GONI_SENT = ['7FD3B0', '5DB894', '3E9E80', '3E9E81', '3E9E82', '3E9E83', 'C9EFDD', '2B7A63']
_GONI_TONES = {'red': ('E5484D', 'B8323A', '9A2630', 'F6AEB0', '7A1C24'), 'blue': ('2F7FE0', '1F5DB0', '184A8E', 'A9CBF5', '123A70'),
               'yellow': ('FFD84D', 'E0A21A', 'C98A10', 'FFF1B8', '8A5E0A'), 'green': ('4CAF50', '2F8A3A', '23702D', 'AEDDB0', '1A5422')}


def goni(pose, colour=None):
    """Goni in a pose, in his mint look or recoloured as GoniSkin does (skin, shade, the four stripes, belly, rim)."""
    import base64
    text = open(GONI[pose], encoding='utf-8').read()
    if colour:
        skin, shade, stripe, belly, rim = _GONI_TONES[colour]
        for sent, to in zip(_GONI_SENT, (skin, shade, stripe, stripe, stripe, stripe, belly, rim)):
            text = text.replace('#' + sent, '#' + to).replace('#' + sent.lower(), '#' + to)
    return 'data:image/svg+xml;base64,' + base64.b64encode(text.encode('utf-8')).decode('ascii')


def goni_at(pose, x, y, s, colour=None, extra=''):
    return '<img src="%s" style="position:absolute;left:%.1fpx;top:%.1fpx;width:%.1fpx;height:%.1fpx;%s">' % (goni(pose, colour), x, y, s, s, extra)


def pic_tile(x, y, s, picture, state='idle', sc=1.0, rot=0):
    border = {'idle': C['hairline'], 'correct': '#FFB800', 'notYet': '#B9A2F7', 'glow': '#FFB800'}[state]
    fill = C['sparkTint'] if state in ('correct', 'glow') else '#fff'
    return [box(x, y, s, s, 'background:%s;border:4px solid %s;border-radius:28px;box-shadow:0 6px 0 %s,0 6px 16px rgba(43,35,80,.14);'
                'transform:scale(%g) rotate(%gdeg);transform-origin:50%% 100%%' % (fill, border, C['lip'], sc, rot),
                '<img src="%s" style="width:%dpx;height:%dpx;margin:%dpx">' % (uri(os.path.join(PICS, picture + '.svg')), s - 28, s - 28, 10))]


P0T, P0G = 112, 40                         # P0: two answers of 112 with a wide gap
P0X = 71 + (534 - (2 * P0T + P0G)) / 2
P0Y = 240


def colour_board(line, goni_pose='talk', goni_colour=None, tiles=(('ball_blue', 'idle', 1.0, 0), ('ball_red', 'idle', 1.0, 0)),
                 balloon_lift=0, done=1, lit=False, buddy='nitzi-listen.svg'):
    out = M.base('phone', CROOM, n=3, done=done)
    sx, sy, sw, sh = B['phone']['stage']

    def inner(ix, iy, iw, ih):
        return [img(os.path.join(PICS, 'balloon_red.svg'), ix + iw / 2 - 55, iy + 6 - balloon_lift, 110, 110)]

    out += M.stage('phone', CROOM, inner, landmark=False)
    out.append(img(os.path.join(M.ROOMART, 'colors_landmark.svg'), *LM[:2], LM[2], LM[2]))
    if lit:
        out.append(img(os.path.join(M.ROOMART, 'colors_reacted.svg'), *LM[:2], LM[2], LM[2]))
    hx, hy, hs = B['phone']['host']
    bx, by, bs = B['phone']['buddy']
    out.append(M.character(os.path.join(CAST, buddy), bx, by, bs))
    out.append(goni_at(goni_pose, hx, hy, hs, goni_colour))
    if line:
        out += M.bubble('phone', line, right=B['phone']['hostBubbleRight'], tail_y=40,
                        maxw=B['phone']['bubble']['w'] - (B['phone']['bubble']['right'] - B['phone']['hostBubbleRight']))
    for i, (picture, state, sc, rot) in enumerate(tiles):
        out += pic_tile(P0X + i * (P0T + P0G), P0Y, P0T, picture, state, sc, rot)
    return out


def pot(x, y, s, colour):
    return svg_at(x, y, s, s, '<ellipse cx="50" cy="90" rx="34" ry="6" fill="rgba(43,35,80,.15)"/>'
                  '<path d="M18 34 H82 L76 86 Q50 94 24 86 Z" fill="#fff" stroke="#2B2350" stroke-width="4" stroke-linejoin="round"/>'
                  '<ellipse cx="50" cy="34" rx="32" ry="10" fill="%s" stroke="#2B2350" stroke-width="4"/>'
                  '<path d="M66 36 Q70 52 64 60 Q60 52 62 40 Z" fill="%s" stroke="#2B2350" stroke-width="3" stroke-linejoin="round"/>' % (
                      colour, colour), '0 0 100 100')


def splash(cx, cy, r, colour, seed=1):
    rnd = random.Random(seed)
    pts = []
    n = 14
    for i in range(n):
        a = 2 * math.pi * i / n
        rr = r * (1.0 if i % 2 == 0 else rnd.uniform(0.55, 0.75))
        pts.append('%.1f %.1f' % (r + rr * math.cos(a), r + rr * math.sin(a)))
    dots = ''.join('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s"/>' % (
        r + r * 1.35 * math.cos(a), r + r * 1.35 * math.sin(a), r * 0.12, colour) for a in (0.4, 1.9, 3.3, 4.6, 5.6))
    return svg_at(cx - r, cy - r, 2 * r, 2 * r, '<path d="M%s Z" fill="%s" stroke="#2B2350" stroke-width="2" stroke-linejoin="round"/>%s' % (
        ' L'.join(pts), colour, dots), '0 0 %g %g' % (2 * r, 2 * r))


STAGE1_SORT = os.path.normpath(os.path.join(ROOT, '..', 'nitznutz-stage1', 'app', 'test', 'goldens', 'unit_colour_sort_phone.png'))


def colour_sheet():
    cells = []
    cells.append(([img(STAGE1_SORT if os.path.exists(STAGE1_SORT) else os.path.join(GOLD_TIP, 'unit_colour_sort_phone.png'), 0, 0, W, H)], W, H,
                  'TODAY (fb39dc08), Colour Bay, "who else is red?": three red balls, then a balloon, a ball and a flower. The child must\n'
                  'ignore what the thing is and match only its colour, from a word ("else") she may not know. Right: "yes! this is a red\n'
                  'balloon" in a flat voice, a pale tile. Goni, the land\'s host, is not on the screen during the items.'))
    # 1 meet: Goni shows red
    f = colour_board('אָדֹם! הַבָּלוֹן אָדֹם. אֵיפֹה עוֹד אָדֹם?', goni_pose='show')
    f.append(note(20, 360, 'P0: Goni names it first; 2 answers of 112 pt; same thing, only the colour differs', 760))
    cells.append((f, W, H, '1 · P0 ITEM: Goni stays in the room and NAMES the colour before he asks ("red! the balloon is red. where else is\n'
                           'red?"). Two balls that differ only in colour, red against blue (far apart), 112 pt each. One idea at a time.'))
    # 2 right: Goni turns red, splash, balloon bobs
    f = colour_board('אָדֹם! כְּמוֹ הַבָּלוֹן!', goni_pose='celebrate', goni_colour='red',
                     tiles=(('ball_blue', 'idle', 1.0, 0), ('ball_red', 'correct', 1.14, 0)), balloon_lift=10, lit=True, buddy='nitzi-celebrate.svg')
    cx = P0X + (P0T + P0G) + P0T / 2
    f.insert(len(f) - 2, splash(cx, P0Y + P0T / 2, 78, '#E5484D', seed=2))
    f += burst(cx, P0Y + P0T / 2, 110, n=16, seed=6, size=(20, 28), shapes=(DROP, STAR, SPARK4, DROP))
    f += badge(cx + P0T / 2, P0Y, 36, 1.2)
    f.append(note(20, 360, 'paint splash under the tile, drops fly; Goni turns red and jumps; the balloon bobs', 760))
    cells.append((f, W, H, '2 · RIGHT: a red paint splash bursts under the ball and drops fly out (the bay\'s own glyph); GONI TURNS RED and\n'
                           'jumps (his skin already does this on the end card, GoniSkin); the balloon on the stage bobs. Then "red! like the balloon!".'))
    # 3 not yet: errorless
    f = colour_board('זֶה כָּחֹל. הִנֵּה הָאָדֹם!', goni_pose='show',
                     tiles=(('ball_blue', 'notYet', 1.0, -6), ('ball_red', 'glow', 1.06, 0)))
    f.insert(len(f) - 2, box(P0X + (P0T + P0G) - 14, P0Y - 14, P0T + 28, P0T + 28, 'border-radius:40px;background:radial-gradient(rgba(255,200,61,.55) 0%, rgba(255,200,61,0) 70%)'))
    f.append(note(20, 360, 'P0: no "wrong": it names what she touched, then the red one glows', 760))
    cells.append((f, W, H, '3 · NOT YET (P0, errorless): the blue ball rocks shyly and Goni names it ("this is blue"), then the red one glows\n'
                           'and he points: "here is red!" Her next touch on it is a full right answer with the whole burst.'))
    # 4 paint corner
    f = M.base('phone', CROOM, n=3, done=0)
    f = [f[0]]
    f.append(svg_at(40, 40, 772, 230, M.backdrop('colors', 772, 230), extra='border-radius:28px;overflow:hidden'))
    f.append(goni_at('celebrate', 330, 40, 220, 'blue'))
    f.append(splash(470, 170, 34, '#2F7FE0', seed=4))
    for k, (col, name) in enumerate((('#E5484D', 'red'), ('#FFD84D', 'yellow'), ('#2F7FE0', 'blue'), ('#4CAF50', 'green'))):
        f.append(pot(206 + k * 120, 256, 100, col))
    f += finger(476, 300, 'tap a pot')
    f += M.pebble(760, 12, 64, 'home_palm.svg')
    f.append(note(20, 364, 'no question, no right or wrong: tap a pot, Goni turns that colour and says it', 800))
    cells.append((f, W, H, '4 · GONI\'S PAINT POTS (free play, the first corner): four pots of 100 pt; a tap splashes Goni in that colour and he\n'
                           'says its name ("blue!"); two pots in a row mix on his stripes. Pure cause and effect, and the colour word every time.'))
    # 5 party
    f = [box(0, 0, W, H, 'background:%s' % CROOM['tint']), svg_at(0, 0, W, H, M.backdrop('colors', W, H))]
    f += landmark_big(30, 150, 170, room='colors')
    for k, (x, y, col) in enumerate(((250, 70, '#E5484D'), (420, 40, '#FFD84D'), (560, 110, '#2F7FE0'), (700, 60, '#4CAF50'), (330, 250, '#9B6BDF'))):
        f.append(splash(x, y, 30 + 6 * (k % 3), col, seed=k + 10))
    f += rain(200, 840, 0, 200, 22, seed=13, size=(18, 28))
    f.append(goni_at('celebrate', 330, 120, 240, 'yellow'))
    f.append(M.character(NITZI_C, 600, 160, 200))
    f += finger(560, 110, 'tap')
    f.append(note(20, 360, 'party: paint lands where she taps; Goni cycles the colours she found', 760))
    cells.append((f, W, H, '5 · COLOUR BAY PARTY: the room opens, Goni (240 pt) dances and his skin runs through the colours she found\n'
                           '(GoniSkin.ripple exists); every tap throws a paint splash in the next colour and Goni names it.\n\n\n'))
    M.page(cells, os.path.join(HERE, 'colour_bay_pilot_phone.png'), 1690, scale=0.62)


if __name__ == '__main__':
    right_answer_sheet()
    party_sheet()
    map_sheet()
    colour_sheet()
