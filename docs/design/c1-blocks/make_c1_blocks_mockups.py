"""Mockups of docs/design/c1-blocks.md: the Band C base-ten blocks redrawn so that a rod is visibly ten of the same cubes, at 1x scale of
the real boards (phone SE 667x375, phone 852x393, tablet landscape 1180x820), rendered by headless Chrome into
docs/design/c1-blocks/*.png.

    python docs/design/c1-blocks/make_c1_blocks_mockups.py

Each PNG is the board at 1 px = 1 pt with a strip of team notes under it (the notes are for the team, never in the app). Shown full
screen on a phone in landscape, the board part is the real size.

The frame numbers (bubble, guide, controls, stage, tiles) are app/lib/child/activity_shell.dart (ActivitySpec); the new stage and tile
boxes are the ones c1-blocks.md specifies. The blocks are drawn with the rules of c1-blocks.md section 4 (one cube for rods and ones).

References looked at before drawing (2026-11-07), none copied or traced:
- The Math Learning Center, Number Pieces (apps.mathlearningcenter.org/number-pieces): a ten is drawn as ten unit squares in the same
  yellow as the loose ones, with a dark line at every join; looked at in the built-in browser.
- Base-ten (Dienes) blocks: 1 cm unit cubes, the ten-rod is ten units long with a groove at each unit (Wikipedia, "Base ten blocks").
- Linking cubes (snap cubes): ten one-colour cubes pressed together read as a stick with a notch at each join.
- Bundles of ten craft sticks held by a rubber band, and ten-frames (2 x 5), for the two alternatives.
"""
import os
import pathlib
import subprocess
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..', '..'))
UI = os.path.join(ROOT, 'app', 'assets', 'art', 'ui')
FONT = os.path.join(ROOT, 'app', 'assets', 'fonts', 'Heebo-Variable.ttf')
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'

# Tokens (design/tokens.json)
INK = '#2B2350'
CREAM = '#FFF6E8'
PAPER = '#FFFFFF'
HAIR = '#E6DDF0'
LIP = '#DCD3EC'
SPARK = '#FFC83D'
SPARK_DEEP = '#E0A21A'
SPARK_TINT = '#FFF1C4'
SKY_TOP = '#CDEFFF'
GRASS = '#A8DB8F'
GRASS2 = '#86C474'
NOTE = '#B23A3A'

# One cube for everything (c1-blocks.md 4.1): body, the joins and edge, the shine, the side face.
SCHEMES = {
    # the edge is seaDeep half-way to ink (#1D485D): 3.0:1 against the body, so every join shows (seaDeep alone is 1.85:1)
    'sea': dict(body='#1A9E9A', edge='#1D485D', shine='#7FD3CF', side='#13827E'),
    'spark': dict(body='#FFC83D', edge='#A35A00', shine='#FFE7A3', side='#E8A92A'),
}

# Boards: the frame pieces of ActivitySpec, in board points.
BOARDS = {
    'phoneSE': dict(W=667, H=375, ctrl=64, eye=(16, 8), hint=(96, 8), home=(667 - 16 - 64, 8), trail=(333, 22),
                    bubble=(300, 92, 176), font=22, guide=(490, 66, 150), stage=(16, 86, 270, 104), tiles=(8, 214, 480),
                    top=80, card=False),
    'phone': dict(W=852, H=393, ctrl=64, eye=(59, 12), hint=(147, 12), home=(852 - 59 - 64, 12), trail=(344, 26),
                  bubble=(413, 104, 190), font=26, guide=(617, 80, 176), stage=(71, 96, 330, 128), tiles=(71, 244, 534),
                  top=88, card=False),
    'tabletL': dict(W=1180, H=820, ctrl=72, eye=(24, 24), hint=(112, 24), home=(1180 - 24 - 72, 24), trail=(590, 38),
                    bubble=('r', 224, 112, 600), font=28, guide=(896, 150, 260), stage=(288, 230, 584, 300), tiles=(288, 554, 584),
                    top=112, card=True),
}
NO_HOTSPOT = 24      # tokens.touch.bottomNoHotspot
HIT_SLOP_C = 8       # design-spec 6.1, Band C
TILE_BORDER = 4      # TokenBorder.thick
TILE_LIP = 6
BLOCK_MARGIN = 5     # inside a block tile, besides the border


def uri(path):
    return pathlib.Path(path).as_uri()


# ---------------------------------------------------------------------------------------------------------------------------------
# The blocks (c1-blocks.md section 4)

ROD_GAP = 0.5        # between two rods, in cubes
GROUP_GAP = 1.2      # between the tens and the ones
LOOSE_GAP = 0.3      # between two loose cubes


CROSS_GAP = 0.6      # extra, before the first crossed rod


def blocks_size(tens, ones, crossed=0):
    """Width and height of a number's blocks, in cubes (u = 1)."""
    w = 0.0
    if tens:
        w += tens + (tens - 1) * ROD_GAP + (CROSS_GAP if 0 < crossed < tens else 0)
    if ones:
        if tens:
            w += GROUP_GAP
        w += 1 if ones <= 5 else 2 + LOOSE_GAP
    col = min(ones, 5)
    h = 10.0 if tens else (col + (col - 1) * LOOSE_GAP if ones else 0)
    return w, h


def cube(x, y, u, s, loose=True):
    """One cube, loose or in a rod: the same rounded square, a side face on the right, a shine on top, a dark edge."""
    sw = max(1.2, 0.09 * u)
    r = 0.2 * u
    side = 0.16 * u
    out = []
    if loose:
        out.append('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="%.2f" fill="%s"/>' % (x, y, u, u, r, s['side']))
    out.append('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="%.2f" fill="%s" stroke="%s" stroke-width="%.2f"/>'
               % (x + sw / 2, y + sw / 2, u - sw - (side if loose else 0), u - sw, r, s['body'], s['edge'], sw))
    out.append('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="%.2f" fill="%s" opacity="0.8"/>'
               % (x + 0.2 * u, y + 0.17 * u, u * 0.42, max(1.2, 0.13 * u), 0.06 * u, s['shine']))
    return ''.join(out)


def rod(x, y, u, s):
    """Ten cubes stuck together: a dark spine behind them shows at every join (a notch on both sides), and one continuous side face
    down the right makes the ten one thing."""
    sw = max(1.2, 0.09 * u)
    side = 0.16 * u
    out = ['<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="%.2f" fill="%s"/>' % (x + 0.12 * u, y + 0.1 * u, u - 0.24 * u, 10 * u - 0.2 * u, 0.1 * u, s['edge'])]
    out.append('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="%.2f" fill="%s"/>' % (x + u - side - sw, y + 0.15 * u, side + sw, 10 * u - 0.3 * u, 0.12 * u, s['side']))
    for k in range(10):
        out.append(cube(x, y + k * u, u, s, loose=False).replace('width="%.2f"' % (u - sw), 'width="%.2f"' % (u - sw - side), 1))
    return ''.join(out)


def blocks(tens, ones, u, scheme='sea', lit=0, crossed=0, pad=None):
    """An inline SVG of a number's blocks, tens on the left, ones on the right in a 2 x 5 frame filled from the bottom, left column
    first. [lit] rods from the left glow; [crossed] rods from the right are taken away."""
    s = SCHEMES[scheme]
    w, h = blocks_size(tens, ones, crossed)
    p = pad if pad is not None else (0.4 * u if lit else 0.15 * u)
    W, H = w * u + 2 * p, h * u + 2 * p
    out = ['<svg xmlns="http://www.w3.org/2000/svg" width="%.1f" height="%.1f" viewBox="0 0 %.2f %.2f" style="overflow:visible">' % (W, H, W, H)]
    x = p
    for i in range(tens):
        ry = p
        if crossed and i == tens - crossed and i > 0:
            x += CROSS_GAP * u     # the rods taken away stand a little apart from the rods that are left
        if i < lit:
            out.append('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="%.2f" fill="%s" opacity="0.55"/>' % (x - 0.65 * u, ry - 0.65 * u, 2.3 * u, 11.3 * u, 0.9 * u, SPARK))
            out.append('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="%.2f" fill="%s"/>' % (x - 0.35 * u, ry - 0.35 * u, 1.7 * u, 10.7 * u, 0.6 * u, SPARK_TINT))
            out.append('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="%.2f" fill="none" stroke="%s" stroke-width="%.2f"/>' % (x - 0.35 * u, ry - 0.35 * u, 1.7 * u, 10.7 * u, 0.6 * u, SPARK_DEEP, max(2.5, 0.2 * u)))
        is_crossed = i >= tens - crossed
        g = rod(x, ry, u, s)
        out.append('<g opacity="%s">%s</g>' % ('0.32' if is_crossed else '1', g))
        if is_crossed:
            # a tall X that stays inside the rod's own gaps (0.62 u to each side), so that crossed rods never run together
            cx, cy, ax, ay = x + u / 2, ry + 5 * u, 0.45 * u, 1.3 * u
            for wdt, col in ((max(4.2, 0.34 * u), PAPER), (max(2.4, 0.19 * u), INK)):
                out.append('<path d="M%.2f %.2fL%.2f %.2fM%.2f %.2fL%.2f %.2f" stroke="%s" stroke-width="%.2f" stroke-linecap="round"/>'
                           % (cx - ax, cy - ay, cx + ax, cy + ay, cx + ax, cy - ay, cx - ax, cy + ay, col, wdt))
        x += u * (1 + ROD_GAP)
    if tens:
        x += u * (GROUP_GAP - ROD_GAP)
    floor = p + h * u
    for k in range(ones):
        col, row = (0, k) if k < 5 else (1, k - 5)
        cx = x + col * u * (1 + LOOSE_GAP)
        cy = floor - (row + 1) * u - row * LOOSE_GAP * u
        out.append(cube(cx, cy, u, s))
    out.append('</svg>')
    return ''.join(out), W, H


# ---------------------------------------------------------------------------------------------------------------------------------
# The alternatives (c1-blocks.md section 7)

def bundles(tens, ones, s_w, length):
    """Ten craft sticks side by side held by a band (a bundle), loose sticks beside them."""
    wood, wedge, band = '#EBC98A', '#A8772F', '#D9692A'
    gap_in, gap_b, gap_l = 0.18 * s_w, 1.6 * s_w, 0.7 * s_w
    bw = 10 * s_w + 9 * gap_in
    W = tens * bw + max(0, tens - 1) * gap_b + (2.4 * s_w if tens and ones else 0) + ones * s_w + max(0, ones - 1) * gap_l + 4
    H = length + 4
    out = ['<svg xmlns="http://www.w3.org/2000/svg" width="%.1f" height="%.1f">' % (W, H)]
    x = 2
    sw = max(0.8, 0.12 * s_w)
    for _ in range(tens):
        for k in range(10):
            sx = x + k * (s_w + gap_in)
            out.append('<rect x="%.2f" y="2" width="%.2f" height="%.2f" rx="%.2f" fill="%s" stroke="%s" stroke-width="%.2f"/>' % (sx, s_w, length, s_w / 2, wood, wedge, sw))
        out.append('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="%.2f" fill="%s"/>' % (x - 1.5, 2 + length * 0.44, bw + 3, max(3, length * 0.1), 2, band))
        x += bw + gap_b
    if tens and ones:
        x += 2.4 * s_w - gap_b
    for k in range(ones):
        out.append('<rect x="%.2f" y="2" width="%.2f" height="%.2f" rx="%.2f" fill="%s" stroke="%s" stroke-width="%.2f"/>' % (x, s_w, length, s_w / 2, wood, wedge, sw))
        x += s_w + gap_l
    out.append('</svg>')
    return ''.join(out), W, H


def tenframes(tens, ones, c, cols):
    """Each ten a full ten-frame (2 x 5 dots), the ones a frame of its own; frames in a grid of [cols], read like text left to right."""
    frames = [10] * tens + ([ones] if ones else [])
    g = 0.6 * c
    rows = (len(frames) + cols - 1) // cols
    W = cols * 5 * c + (cols - 1) * g + 4
    H = rows * 2 * c + (rows - 1) * g + 4
    out = ['<svg xmlns="http://www.w3.org/2000/svg" width="%.1f" height="%.1f">' % (W, H)]
    for i, n in enumerate(frames):
        fx = 2 + (i % cols) * (5 * c + g)
        fy = 2 + (i // cols) * (2 * c + g)
        out.append('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="%.2f" fill="#FFFFFF" stroke="#5A5378" stroke-width="1.4"/>' % (fx, fy, 5 * c, 2 * c, 0.15 * c))
        for k in range(1, 5):
            out.append('<path d="M%.2f %.2fV%.2f" stroke="#5A5378" stroke-width="0.9"/>' % (fx + k * c, fy, fy + 2 * c))
        out.append('<path d="M%.2f %.2fH%.2f" stroke="#5A5378" stroke-width="0.9"/>' % (fx, fy + c, fx + 5 * c))
        for k in range(n):
            col, row = (k, 0) if k < 5 else (k - 5, 1)
            out.append('<circle cx="%.2f" cy="%.2f" r="%.2f" fill="#1A9E9A" stroke="#0F6E6A" stroke-width="1"/>' % (fx + (col + 0.5) * c, fy + (row + 0.5) * c, 0.36 * c))
    out.append('</svg>')
    return ''.join(out), W, H


# ---------------------------------------------------------------------------------------------------------------------------------
# The frame

def pebble(x, y, size, icon):
    return ('<div style="position:absolute;left:%dpx;top:%dpx;width:%dpx;height:%dpx;border-radius:50%%;background:#fff;'
            'box-shadow:0 6px 0 %s,0 6px 16px rgba(43,35,80,.14)"><img src="%s" style="position:absolute;left:%dpx;top:%dpx;width:32px;height:32px"></div>'
            % (x, y, size, size, LIP, uri(os.path.join(UI, icon)), (size - 32) // 2, (size - 32) // 2))


def frame(b, text, bubble_top=None):
    B = BOARDS[b]
    wrap = ''
    if B['card']:
        # the tablet bubble is 600 wide: the phone's line breaks do not apply
        text, wrap = text.replace('<br>', ' '), ';white-space:normal'
    out = [pebble(*B['eye'], B['ctrl'], 'eye.svg'), pebble(*B['hint'], B['ctrl'], 'hint.svg'), pebble(*B['home'], B['ctrl'], 'home_palm.svg')]
    tx, ty = B['trail']
    out.append('<div style="position:absolute;left:%dpx;top:%dpx;width:44px;height:36px;border-radius:18px;background:#fff;box-shadow:0 2px 6px rgba(43,35,80,.1)">'
               '<div style="position:absolute;left:12px;top:8px;width:16px;height:16px;border-radius:50%%;border:2.5px solid %s"></div></div>' % (tx - 22, ty, INK))
    gx, gy, gs = B['guide']
    out.append('<img src="%s" style="position:absolute;left:%dpx;top:%dpx;width:%dpx;height:%dpx">' % (uri(os.path.join(UI, 'nitzi.svg')), gx, gy, gs, gs))
    bub = B['bubble']
    font = B['font']
    if bub[0] == 'r':
        pos = 'right:%dpx;top:%dpx;max-width:%dpx' % (bub[1], bubble_top or bub[2], bub[3])
    else:
        pos = 'left:%dpx;top:%dpx;min-width:%dpx' % (bub[0], bubble_top or bub[1], bub[2])
    out.append('<div class="bubble" style="position:absolute;%s;font-size:%dpx%s">%s<div class="tail"></div></div>' % (pos, font, wrap, text))
    return ''.join(out)


def meadow(x, y, w, h, radius=24):
    return ('<svg style="position:absolute;left:%dpx;top:%dpx" width="%d" height="%d"><defs><clipPath id="m%d%d"><rect width="%d" height="%d" rx="%d"/></clipPath></defs>'
            '<g clip-path="url(#m%d%d)"><rect width="%d" height="%d" fill="%s"/><rect y="%d" width="%d" height="%d" fill="#E3F4FC"/>'
            '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="%s"/><ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="%s"/></g></svg>'
            % (x, y, w, h, x, y, w, h, radius, x, y, w, h, SKY_TOP, h * 0.25, w, h * 0.5,
               w * 0.28, h * 1.08, w * 0.62, h * 0.42, GRASS, w * 0.85, h * 1.12, w * 0.6, h * 0.38, GRASS2))


def tile(x, y, w, h, inner, selected=False):
    border = INK if selected else HAIR
    return ('<div style="position:absolute;left:%.1fpx;top:%.1fpx;width:%.1fpx;height:%.1fpx;box-sizing:border-box;border:%dpx solid %s;border-radius:28px;'
            'background:#fff;box-shadow:0 %dpx 0 %s,0 6px 16px rgba(43,35,80,.14);display:flex;align-items:center;justify-content:center">%s</div>'
            % (x, y, w, h, TILE_BORDER, border, TILE_LIP, LIP, inner))


def numeral(n, font):
    return '<span style="font:800 %dpx/1 Heebo;color:%s;direction:ltr">%s</span>' % (font, INK, n)


def numeral_font(nums, tile_w, base):
    """The size the widest numeral of the item fits the tile in (numeralFontOf): every numeral of the item at it."""
    room = tile_w - 2 * TILE_BORDER - 16
    widest = max(len(str(n)) for n in nums)
    return min(base, int(room / (0.6 * widest)))


def numeral_row(b, nums, top, tile=96):
    """Numeral tiles in one row, centred in the board's tiles box, read right to left (the first option at the right)."""
    B = BOARDS[b]
    left, _, width = B['tiles']
    n = len(nums)
    slot = tile + 24
    x0 = left + (width - n * slot) / 2 + 12
    f = numeral_font(nums, tile, 56 if b != 'tabletL' else 64)
    out = []
    for i, num in enumerate(reversed(nums)):
        out.append(globals()['tile'](x0 + i * slot, top, tile, tile, numeral(num, f)))
    return ''.join(out)


def note(x, y, text, color=NOTE, size=11):
    return '<div style="position:absolute;left:%dpx;top:%dpx;font:600 %dpx/1.3 sans-serif;color:%s;white-space:nowrap">%s</div>' % (x, y, size, color, text)


def dim(x, y, w, h, label, color=NOTE):
    """A dashed box round something measured, with its size."""
    return ('<div style="position:absolute;left:%.1fpx;top:%.1fpx;width:%.1fpx;height:%.1fpx;border:1px dashed %s;box-sizing:border-box"></div>' % (x, y, w, h, color)
            + note(x, y - 13, label, color, 10))


def page(W, H, body, notes, note_h=64):
    return ('<!doctype html><html><head><meta charset="utf-8"><style>@font-face{font-family:Heebo;src:url("%s")}'
            'html,body{margin:0;padding:0}body{width:%dpx;height:%dpx;background:#f2f2f2;font-family:Heebo}'
            '.board{position:relative;width:%dpx;height:%dpx;background:%s;overflow:hidden}'
            '.bubble{background:#fff;border-radius:22px;padding:8px 16px;box-sizing:border-box;direction:rtl;text-align:right;white-space:nowrap;font-weight:500;line-height:1.7;color:%s;box-shadow:0 6px 16px rgba(43,35,80,.14)}'
            '.tail{position:absolute;right:-9px;top:50%%;margin-top:-9px;width:0;height:0;border-top:9px solid transparent;border-bottom:9px solid transparent;border-left:11px solid #fff}'
            '.notes{position:relative;width:%dpx;height:%dpx;background:#fff;border-top:1px solid #ccc;font:600 11px/1.45 sans-serif;color:#333;padding:6px 10px;box-sizing:border-box}'
            '</style></head><body><div class="board">%s</div><div class="notes">%s</div></body></html>'
            % (uri(FONT), W, H + note_h, W, H, CREAM, INK, W, note_h, body, notes))


def render(name, html, W, H):
    with tempfile.NamedTemporaryFile('w', suffix='.html', delete=False, encoding='utf-8') as f:
        f.write(html)
        path = f.name
    out = os.path.join(HERE, name)
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
                    '--window-size=%d,%d' % (W, H), '--screenshot=%s' % out, uri(path)], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.unlink(path)
    print('wrote', out)


# ---------------------------------------------------------------------------------------------------------------------------------
# Layouts (c1-blocks.md section 5)

# Layout T raises the phone bubble to the old stage's top line (phone 104 to 96, SE 92 to 86), so the tiles gain 8 and 6 points.
T_BUBBLE_TOP = {'phone': 96, 'phoneSE': 86}


def bubble_bottom(b, lines, top=None):
    B = BOARDS[b]
    if top is None:
        top = B['bubble'][2] if B['bubble'][0] == 'r' else B['bubble'][1]
    return top + lines * B['font'] * 1.7 + 16


def stage_layout(b):
    """S: a picture on the stage, numeral tiles in a row under it. The tile row sits as low as the bottom band allows; the stage takes
    all the height from the top bar to 12 above the tiles."""
    B = BOARDS[b]
    if B['card']:
        x, y, w, h = B['stage']
        return dict(stage=(x, y, w, h), inner=(x + 16, y + 16, w - 32, h - 32), tiles_top=B['tiles'][1])
    tiles_top = B['H'] - NO_HOTSPOT - HIT_SLOP_C - 96
    x, _, w, _ = B['stage']
    y = B['top']
    h = tiles_top - 12 - y
    return dict(stage=(x, y, w, h), inner=(x, y, w, h), tiles_top=tiles_top)


def unit_for(box_w, box_h, pictures, cap):
    """The one cube size every picture of an item draws with: the largest that fits each picture in its box, capped per board."""
    u = cap
    for tens, ones, lit in pictures:
        w, h = blocks_size(tens, ones)
        p = 0.8 if lit else 0.3
        u = min(u, box_w / (w + p), box_h / (h + p))
    return u


CAP = {'phoneSE': 22, 'phone': 22, 'tabletL': 28}


def stage_item(b, text, pictures, nums, lines=1, scheme='sea', label=''):
    """A picture of blocks (or two, side by side) on the stage and numeral options."""
    B = BOARDS[b]
    L = stage_layout(b)
    sx, sy, sw, sh = L['stage']
    ix, iy, iw, ih = L['inner']
    body = []
    if B['card']:
        body.append('<div style="position:absolute;left:%dpx;top:%dpx;width:%dpx;height:%dpx;border-radius:28px;background:#fff;box-shadow:0 6px 0 %s,0 6px 16px rgba(43,35,80,.14)"></div>' % (sx, sy, sw, sh, LIP))
        body.append(meadow(ix, iy, iw, ih, 18))
    else:
        body.append(meadow(sx, sy, sw, sh))
    margin = 6
    n = len(pictures)
    cell_w = (iw - 2 * margin - (n - 1) * 16) / n
    u = unit_for(cell_w, ih - 2 * margin, [(t, o, l) for (t, o, l, c) in pictures], CAP[b])
    for i, (t, o, lit, crossed) in enumerate(pictures):
        svg, w, h = blocks(t, o, u, scheme, lit, crossed)
        cx = ix + margin + i * (cell_w + 16) + cell_w / 2
        if n > 1:
            # two numbers: each on a mat of its own, so the child sees two groups
            body.append('<div style="position:absolute;left:%.1fpx;top:%.1fpx;width:%.1fpx;height:%.1fpx;border-radius:16px;background:rgba(255,255,255,.6)"></div>'
                        % (ix + margin + i * (cell_w + 16) - 4, iy + margin - 2, cell_w + 8, ih - 2 * margin + 4))
        body.append('<div style="position:absolute;left:%.1fpx;top:%.1fpx">%s</div>' % (cx - w / 2, iy + ih - margin - h, svg))
    body.append(numeral_row(b, nums, L['tiles_top']))
    body.append(frame(b, text))
    body.append(dim(sx, sy, sw, sh, 'stage %dx%d' % (sw, sh)))
    return ''.join(body), u


def options_item(b, text, options, lines=2, scheme='sea'):
    """Blocks on the option tiles; nothing on the stage. The tiles take the stage's height: from 12 below the bubble down to the
    bottom band."""
    B = BOARDS[b]
    left, _, width = B['tiles']
    n = len(options)
    if B['card']:
        x, y, w, h = B['stage']
        top, bottom = y, B['H'] - NO_HOTSPOT - HIT_SLOP_C
        left, width = x, w
    else:
        top = bubble_bottom(b, lines, T_BUBBLE_TOP[b]) + 12
        bottom = B['H'] - NO_HOTSPOT - HIT_SLOP_C
    tile_w = min(260, (width - n * 24) / n)
    box_w = tile_w - 2 * (TILE_BORDER + BLOCK_MARGIN)
    box_h = bottom - top - 2 * (TILE_BORDER + BLOCK_MARGIN)
    u = unit_for(box_w, box_h, [(t, o, 0) for (t, o) in options], CAP[b])
    th = min(bottom - top, 10 * u + 0.3 * u + 2 * (TILE_BORDER + BLOCK_MARGIN))
    # phones: the tiles stand on the bottom line (no room to spare); tablets: centred in the card's room
    ty = top + (bottom - top - th) / 2 if B['card'] else bottom - th
    x0 = left + (width - n * (tile_w + 24)) / 2 + 12
    body = []
    for i, (t, o) in enumerate(reversed(options)):
        svg, w, h = blocks(t, o, u, scheme)
        inner = '<div style="position:absolute;left:%.1fpx;bottom:%.1fpx">%s</div>' % ((tile_w - 2 * TILE_BORDER - w) / 2, BLOCK_MARGIN, svg)
        body.append(tile(x0 + i * (tile_w + 24), ty, tile_w, th, inner).replace('display:flex', 'display:block'))
    body.append(frame(b, text, T_BUBBLE_TOP.get(b)))
    body.append(dim(x0, ty, tile_w, th, 'tile %dx%d' % (tile_w, th)))
    return ''.join(body), u


def mm(u, b):
    """A size in points as millimetres on the device class, and as minutes of arc at 25 cm."""
    per = 0.192 if b == 'tabletL' else 0.156
    import math
    return u * per, math.degrees(math.atan(u * per / 250)) * 60


def cube_note(b, u, extra=''):
    m, arc = mm(u, b)
    dev = {'phoneSE': 'iPhone SE (667x375)', 'phone': 'iPhone 16 (852x393)', 'tabletL': 'iPad landscape (1180x820)'}[b]
    return ('<b>%s</b> &nbsp; cube = <b>%.1f pt</b> (%.1f mm on this device, %d arcmin at 25 cm); joins %.1f pt; loose gap %.1f pt. %s'
            % (dev, u, m, round(arc), max(1.2, 0.09 * u), LOOSE_GAP * u, extra))


def board_png(name, b, body, notes):
    B = BOARDS[b]
    render(name, page(B['W'], B['H'], body, notes), B['W'], B['H'] + 64)


def tablets():
    main(('tabletL',), extras=False)


def main(boards=('phoneSE', 'phone', 'tabletL'), extras=True):
    q34 = 'אֵיפֹה הַמִּסְפָּר<br>שְׁלוֹשִׁים וְאַרְבַּע?'
    qhow = 'כַּמָּה קֻבִּיּוֹת יֵשׁ<br>כָּאן?'
    qcmp = 'אֵיזֶה מִסְפָּר גָּדוֹל<br>יוֹתֵר? מִסְתַּכְּלִים עַל<br>הַמּוֹטוֹת וְעַל הַקֻּבִּיּוֹת.'
    qlit = 'כַּמָּה שָׁוֶה הַמּוֹט<br>שֶׁזּוֹהֵר?'
    qleft = 'כַּמָּה נִשְׁאַר?'
    sizes = {}
    for b in boards:
        body, u = options_item(b, q34, [(4, 3), (3, 4), (0, 7)])
        sizes[(b, 'where34')] = u
        board_png('%s_where34.png' % b, b, body, cube_note(b, u, 'Layout T: blocks on the tiles, the tiles take the empty stage\'s height (12 under the bubble to %d).' % (BOARDS[b]['H'] - 32)) +
                  '<br>c.numc03.25: options 4 rods + 3, 3 rods + 4, 7 loose (right to left). Every option draws the same cube.')
        body, u = stage_item(b, qhow, [(3, 4, 0, 0)], [304, 43, 7, 34])
        sizes[(b, 'howmany34')] = u
        board_png('%s_howmany34.png' % b, b, body, cube_note(b, u, 'Layout S: the picture on the stage, the numeral row as low as the bottom band allows.') +
                  '<br>34 = 3 rods + 4 cubes. The cap for this board is %d pt, so a small number is not drawn larger than a big one.' % CAP[b])
        body, u = stage_item(b, qhow, [(9, 8, 0, 0)], [98, 89, 17, 908])
        sizes[(b, 'howmany98')] = u
        board_png('%s_howmany98.png' % b, b, body, cube_note(b, u, 'Worst case: 98 = 9 rods + 8 cubes, the widest picture of C1.') +
                  '<br>The cube size is set by the stage height (10 cubes) for every number up to 99 on these boards; the width has room.')
        body, u = stage_item(b, qcmp, [(4, 1, 0, 0), (3, 9, 0, 0)], [41, 39, 14])
        sizes[(b, 'compare')] = u
        board_png('%s_compare41_39.png' % b, b, body, cube_note(b, u, 'Two pictures side by side, 41 on the left, 39 on the right (left to right, as the numbers are written).') +
                  '<br>c.numc04.13. Both pictures share one cube size.')
        body, u = stage_item(b, qlit, [(2, 7, 1, 0)], [1, 10, 100])
        sizes[(b, 'lit')] = u
        board_png('%s_litrod.png' % b, b, body, cube_note(b, u, 'The lit rod: a warm glow round it and a dark-gold ring (a shape, not only a colour); its cubes stay the same cubes.') +
                  '<br>c.numc03.24: 2 rods + 7 cubes, the first rod lit.')
        body, u = stage_item(b, qleft, [(7, 0, 0, 4)], [3, 300, 30, 110])
        sizes[(b, 'crossed')] = u
        board_png('%s_crossed.png' % b, b, body, cube_note(b, u, 'Crossed out (taken away): the rods fade to a third, stand 0.6 u apart from the rods left, and each has a tall ink X with a white edge.') +
                  '<br>c.mathc03.17: 70 take away 40; the four rods at the right are crossed.')
    if extras:
        close_up()
        demo()
        alternatives()
    for k, v in sorted(sizes.items()):
        print('%-10s %-10s u = %.1f' % (k[0], k[1], v))


def tablet_where34():
    body, u = options_item('tabletL', 'אֵיפֹה הַמִּסְפָּר<br>שְׁלוֹשִׁים וְאַרְבַּע?', [(4, 3), (3, 4), (0, 7)])
    board_png('tabletL_where34.png', 'tabletL', body, cube_note('tabletL', u, 'Layout T: blocks on the tiles; on a tablet the tiles stand in the middle of the room of the card (230 to 788).') +
              '<br>c.numc03.25: options 4 rods + 3, 3 rods + 4, 7 loose (right to left). Every option draws the same cube.')


def crossed_boards():
    for b in ('phoneSE', 'phone', 'tabletL'):
        body, u = stage_item(b, 'כַּמָּה נִשְׁאַר?', [(7, 0, 0, 4)], [3, 300, 30, 110])
        board_png('%s_crossed.png' % b, b, body, cube_note(b, u, 'Crossed out (taken away): the rods fade to a third, stand 0.6 u apart from the rods left, and each has a tall ink X with a white edge.') +
                  '<br>c.mathc03.17: 70 take away 40; the four rods at the right are crossed.')
        print(b, 'crossed u = %.1f' % u)


def close_up():
    """The cube, a loose cube and a rod at 1x, 2x and 3x, in the two colourways (the owner picks), with the lit and crossed states."""
    u0 = 13
    row_h = 10 * u0 * 3 + 70
    W, H = 1060, 2 * row_h + 40
    body = [note(20, 10, 'One cube for all (c1-blocks.md 4), u = 13 pt. 1x is the size in points; 2x and 3x are how a phone with 2x or 3x pixels draws it.', INK, 13)]
    for r, scheme in enumerate(('sea', 'spark')):
        y0 = 40 + r * row_h
        body.append(note(20, y0, 'colourway "%s"' % scheme, INK, 12))
        x = 20
        floor = y0 + 30 + 10 * u0 * 3
        for zoom, (t, o) in ((1, (2, 7)), (2, (2, 7)), (3, (1, 3))):
            u = u0 * zoom
            svg, w, h = blocks(t, o, u, scheme)
            body.append('<div style="position:absolute;left:%dpx;top:%dpx">%s</div>' % (x, floor - h, svg))
            body.append(note(x, floor + 8, '%dx' % zoom, NOTE, 11))
            x += w + 40
        for lit, crossed, lab in ((1, 0, 'lit (2x)'), (0, 1, 'crossed (2x)')):
            svg, w, h = blocks(1, 0, u0 * 2, scheme, lit=lit, crossed=crossed)
            body.append('<div style="position:absolute;left:%dpx;top:%dpx">%s</div>' % (x, floor - h, svg))
            body.append(note(x, floor + 8, lab, NOTE, 11))
            x += w + 40
    render('cube_closeup.png', '<!doctype html><html><head><meta charset="utf-8"><style>body{margin:0;width:%dpx;height:%dpx;background:#fff;position:relative}</style></head><body>%s</body></html>' % (W, H, ''.join(body)), W, H)


def demo():
    """The lesson-opening demonstration on the phone's stage (Layout S, 330 x 165): ten loose cubes are counted, glide into a column
    and snap into a rod. Five frames, in board points."""
    b = 'phone'
    L = stage_layout(b)
    sx, sy, sw, sh = L['stage']
    u = 13.5   # the column with its last small gaps (10 cubes and 9 gaps of 0.15) fits the 165 stage; the rod after it is the same size
    s = SCHEMES['sea']
    W, H = 5 * (sw + 16) + 16, sh + 110
    body = []
    floor = sh - 6
    for f in range(5):
        ox = 16 + f * (sw + 16)
        body.append(meadow(ox, 30, sw, sh))
        parts = []
        if f in (0, 1):
            # ten loose cubes in a 2 x 5 frame, filled from the bottom; in frame 1 the counting has reached 7 (lit cubes lifted)
            x = sw / 2 - u * 1.15
            for k in range(10):
                col, row = (0, k) if k < 5 else (1, k - 5)
                cx = x + col * u * (1 + LOOSE_GAP)
                cy = floor - (row + 1) * u - row * LOOSE_GAP * u
                lift = 0
                if f == 1 and k < 7:
                    parts.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="%.1f" fill="%s" opacity="0.6"/>' % (cx - 2, cy - 2, u + 4, u + 4, 0.3 * u, SPARK))
                parts.append(cube(cx, cy - lift, u, s))
            if f == 1:
                parts.append('<text x="%.1f" y="%.1f" font-family="Heebo" font-weight="800" font-size="30" fill="%s" text-anchor="middle">7</text>' % (sw / 2 + 60, 60, INK))
        elif f == 2:
            # gliding into one column, a gap still between them
            x = sw / 2 - u / 2
            for k in range(10):
                cy = floor - (k + 1) * u - k * 0.15 * u
                dx = (k % 2) * 0.35 * u
                parts.append(cube(x + dx, cy, u, s))
        elif f == 3:
            # snapped: the rod, a soft ring of light for 400 ms
            x = sw / 2 - u / 2
            parts.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="%.1f" fill="#FFFFFF" opacity="0.7"/>' % (x - 0.5 * u, floor - 10 * u - 0.5 * u, 2 * u, 11 * u, 0.8 * u))
            parts.append(rod(x, floor - 10 * u, u, s))
        else:
            x = sw / 2 - u / 2 - 40
            parts.append(rod(x, floor - 10 * u, u, s))
            parts.append('<rect x="%.1f" y="%.1f" width="72" height="72" rx="20" fill="#fff" stroke="%s" stroke-width="4"/>' % (sw / 2 + 10, floor - 100, HAIR))
            parts.append('<text x="%.1f" y="%.1f" font-family="Heebo" font-weight="800" font-size="44" fill="%s" text-anchor="middle">10</text>' % (sw / 2 + 46, floor - 48, INK))
        body.append('<svg style="position:absolute;left:%dpx;top:30px" width="%d" height="%d">%s</svg>' % (ox, sw, sh, ''.join(parts)))
        cap = ['1. Ten loose cubes (0 to 0.6 s)', '2. Counted aloud, 1 to 10, each lights (0.5 s each)', '3. They glide into one column (stagger 40 ms, 500 ms)',
               '4. Snap: the gaps close (120 ms), one soft click, a ring of light', '5. "Ten cubes are one rod": the rod and its numeral'][f]
        body.append(note(ox, 8, cap, INK, 11))
    body.append(note(16, sh + 44, 'Phone stage of Layout S (330 x 165), u = 13.5 pt here (the gliding column needs room for its gaps). About 9 s in all; reduce-motion: the cubes light 1 to 10 in place, then cross-fade (300 ms) to the rod.', NOTE, 11))
    body.append(note(16, sh + 62, 'Then the rod slides to the left of the stage and the first item starts. The reverse (a rod breaks into ten) is the hint for "how much is the rod worth" and for taking away.', NOTE, 11))
    render('demo_snap_phone.png', '<!doctype html><html><head><meta charset="utf-8"><style>@font-face{font-family:Heebo;src:url("%s")}body{margin:0;width:%dpx;height:%dpx;background:%s;position:relative}</style></head><body>%s</body></html>'
           % (uri(FONT), W, H, CREAM, ''.join(body)), W, H)


def alternatives():
    """The two other models of a ten at the same scale, on phone SE (the smallest board), Layout S, for 34 and 98, beside the rods."""
    b = 'phoneSE'
    L = stage_layout(b)
    sx, sy, sw, sh = L['stage']
    m = 6
    bw, bh = sw - 2 * m, sh - 2 * m
    rows = []
    for (t, o) in ((3, 4), (9, 8)):
        # rods of cubes
        u = unit_for(bw, bh, [(t, o, 0)], CAP[b])
        r_svg, rw, rh = blocks(t, o, u)
        # bundles: the stick width that fits; sticks as long as the stage allows
        sticks = t * (10 + 9 * 0.18) + max(0, t - 1) * 1.6 + (2.4 if t and o else 0) + o + max(0, o - 1) * 0.7
        s_w = (bw - 4) / sticks
        b_svg, bw2, bh2 = bundles(t, o, s_w, bh - 4)
        # ten-frames: the grid of columns that gives the largest cell
        best = None
        for cols in (1, 2, 3, 4):
            frames = t + (1 if o else 0)
            rws = (frames + cols - 1) // cols
            c = min((bw - 4) / (cols * 5 + (cols - 1) * 0.6), (bh - 4) / (rws * 2 + (rws - 1) * 0.6))
            if best is None or c > best[0]:
                best = (c, cols)
        f_svg, fw, fh = tenframes(t, o, best[0], best[1])
        rows.append(((t, o), (r_svg, rw, rh, u), (b_svg, bw2, bh2, s_w), (f_svg, fw, fh, best[0])))
    W, H = 3 * (sw + 30) + 30, 2 * (sh + 60) + 60
    body = [note(20, 8, 'The three models of a ten on the phone SE stage of Layout S (%d x %d), at 1x. Top: 34. Bottom: 98.' % (sw, sh), INK, 13)]
    for r, ((t, o), rod_, bun, tf) in enumerate(rows):
        y = 40 + r * (sh + 60)
        for c, (svg, w, h, size, label) in enumerate(((rod_[0], rod_[1], rod_[2], rod_[3], 'rods of ten cubes: cube %.1f pt'),
                                                       (bun[0], bun[1], bun[2], bun[3], 'bundles of ten sticks: stick %.1f pt wide'),
                                                       (tf[0], tf[1], tf[2], tf[3], 'ten-frames: cell %.1f pt, dot %.1f pt'))):
            x = 20 + c * (sw + 30)
            body.append(meadow(x, y, sw, sh))
            body.append('<div style="position:absolute;left:%.1fpx;top:%.1fpx">%s</div>' % (x + (sw - w) / 2, y + sh - m - h, svg))
            txt = label % ((size, size * 0.72) if c == 2 else size)
            body.append(note(x, y + sh + 8, txt, NOTE, 11))
    render('alternatives_phoneSE.png', '<!doctype html><html><head><meta charset="utf-8"><style>@font-face{font-family:Heebo;src:url("%s")}body{margin:0;width:%dpx;height:%dpx;background:%s;position:relative}</style></head><body>%s</body></html>'
           % (uri(FONT), W, H, CREAM, ''.join(body)), W, H)
    # The bundles and the ten-frames as options of "where is 34" on phone SE (Layout T), beside the rods.
    B = BOARDS[b]
    top = bubble_bottom(b, 2, T_BUBBLE_TOP[b]) + 12
    bottom = B['H'] - NO_HOTSPOT - HIT_SLOP_C
    tile_w = (B['tiles'][2] - 3 * 24) / 3
    box_w, box_h = tile_w - 18, bottom - top - 18
    opts = [(4, 3), (3, 4), (0, 7)]
    W2, H2 = 3 * (tile_w * 3 + 72) + 40, (bottom - top) + 70
    body = []
    for c, kind in enumerate(('rods', 'bundles', 'frames')):
        ox = 20 + c * (tile_w * 3 + 72 + 10)
        if kind == 'rods':
            u = unit_for(box_w, box_h, [(t, o, 0) for t, o in opts], CAP[b])
            pics = [blocks(t, o, u) for t, o in opts]
            lab = 'rods: cube %.1f pt' % u
        elif kind == 'bundles':
            s_w = min((box_w - 4) / (t * (10 + 9 * 0.18) + max(0, t - 1) * 1.6 + (2.4 if t and o else 0) + o + max(0, o - 1) * 0.7) for t, o in opts)
            pics = [bundles(t, o, s_w, box_h - 4) for t, o in opts]
            lab = 'bundles: stick %.1f pt wide' % s_w
        else:
            c_ = min(min((box_w - 4) / 5, (box_h - 4) / ((t + (1 if o else 0)) * 2 + (t + (1 if o else 0) - 1) * 0.6)) for t, o in opts)
            pics = [tenframes(t, o, c_, 1) for t, o in opts]
            lab = 'ten-frames: cell %.1f pt' % c_
        for i, (svg, w, h) in enumerate(reversed(pics)):
            inner = '<div style="position:absolute;left:%.1fpx;bottom:%.1fpx">%s</div>' % ((tile_w - 8 - w) / 2, 5, svg)
            body.append(tile(ox + i * (tile_w + 24), 30, tile_w, bottom - top, inner).replace('display:flex', 'display:block'))
        body.append(note(ox, 8, lab + ' (tiles %dx%d, as on the SE board)' % (tile_w, bottom - top), NOTE, 11))
    render('alternatives_options_phoneSE.png', '<!doctype html><html><head><meta charset="utf-8"><style>body{margin:0;width:%dpx;height:%dpx;background:%s;position:relative}</style></head><body>%s</body></html>'
           % (W2, H2, CREAM, ''.join(body)), W2, H2)


if __name__ == '__main__':
    import sys
    only = sys.argv[1:]
    if not only:
        main()
    for name in only:
        globals()[name]()
