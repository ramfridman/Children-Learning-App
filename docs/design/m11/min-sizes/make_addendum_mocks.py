"""Mocks for the addendum of 2026-11-17 to docs/design/m11/min-sizes.md, drawn at real size in points over the goldens of the
round-1 build (taken from commit 7e7b17aa with `git show`, so the mocks do not move while the live goldens change), with the app's own
pictures (content/starter/*.svg) and fonts (Heebo), rendered by headless Chrome:

    python docs/design/m11/min-sizes/make_addendum_mocks.py

  add_b9_hint_card_phone.png   B9: the hint card of a where-is item on tiles, rods lying down at the tiles' cube (34 on the phone board,
                               then the cards for 49 on the phone and 34 / 49 on the SE at 1:1)
  add_size_bins_phone.png      the size rule's signs (a bright ball beside a ghost of the other size) and the well at the tray's scale
  add_numline_phone.png        the phone number line: a number sign in the top-left, the bubble beside it, a 56 marker (jump and place)
  add_numline_tabletL.png      the tablet number line: card 848 x 400, line at 0.7 of the card, labels 28, marker 80, sign 200 x 140
  add_balance_phone.png        A5 refined: the meet stage 377 x 260, pans 150 wide with 26-pt things in rows of five, the three answer
                               tiles (88) in a row under the bubble and the guide
  add_ten_tiles_phone.png      a set of seven to ten on a tile: a 5 x 2 frame of 32-pt cells in a tile 177 x 96, three tiles across the
                               wide answer band (24..605)

Nothing here is traced or copied: the balance, the arcs, the cubes and the cards are plain shapes; the pictures are the app's own.
Reference for the developer, not a screenshot of the running app.
"""
import os
import pathlib
import subprocess
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..', '..', '..'))
PICS = os.path.join(ROOT, 'content', 'starter')
FONTS = os.path.join(ROOT, 'app', 'assets', 'fonts')
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'
COMMIT = '7e7b17aa'
TMP = tempfile.mkdtemp(prefix='addmock_')

C = dict(cream='#FFF6E8', paper='#FFFFFF', ink='#2B2350', inkSoft='#5A5378', hairline='#E6DDF0', lip='#DCD3EC', sky='#8FD3F4',
         skyDeep='#5BB6E0', skyTint='#E3F4FC', spark='#FFC83D', sparkDeep='#E0A21A', grass='#A8DB8F', grassShade='#86C474',
         wood='#B07A52', woodDeep='#8A5A33', sea='#1A9E9A')


def uri(p):
    return pathlib.Path(p).as_uri()


def golden(name):
    """The golden as committed in round 1 (a file in a temp folder)."""
    out = os.path.join(TMP, name)
    data = subprocess.run(['git', 'show', '%s:app/test/goldens/%s' % (COMMIT, name)], cwd=ROOT, check=True, capture_output=True).stdout
    with open(out, 'wb') as fh:
        fh.write(data)
    return out


def pic(name):
    return os.path.join(PICS, name + '.svg')


def box(x, y, w, h, style='', inner=''):
    return '<div style="position:absolute;left:%.1fpx;top:%.1fpx;width:%.1fpx;height:%.1fpx;box-sizing:border-box;%s">%s</div>' % (
        x, y, w, h, style, inner)


def img(path, x, y, w, h, extra=''):
    return '<img src="%s" style="position:absolute;left:%.1fpx;top:%.1fpx;width:%.1fpx;height:%.1fpx;%s">' % (uri(path), x, y, w, h,
                                                                                                               extra)


def svg(x, y, w, h, body):
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %g %g" style="position:absolute;left:%.1fpx;top:%.1fpx;width:%.1fpx;'
            'height:%.1fpx;overflow:visible">%s</svg>') % (w, h, x, y, w, h, body)


def text(x, y, w, h, t, size, weight=500, align='center', rtl=True, color=None, line=1.7):
    return box(x, y, w, h, 'display:flex;align-items:center;justify-content:%s;text-align:%s' % (
        {'center': 'center', 'right': 'flex-end', 'left': 'flex-start'}[align], align),
        '<span dir="%s" style="font:%d %dpx/%.2f H;color:%s">%s</span>' % ('rtl' if rtl else 'ltr', weight, size, line,
                                                                          color or C['ink'], t))


def note(x, y, w, t, size=13):
    return box(x, y, w, 20, 'font:600 %dpx/1.3 sans-serif;color:#B23A3A' % size, t)


def tile(x, y, w, h, inner='', lit=False):
    return box(x, y, w, h, 'background:#fff;border:2px solid %s;border-radius:20px;box-shadow:0 5px 0 %s;display:flex;align-items:center;'
               'justify-content:center' % (C['skyDeep'] if lit else C['hairline'], C['lip']), inner)


def render(out, w, h, parts):
    css = ("@font-face{font-family:H;src:url('%s');font-weight:100 900}" % uri(os.path.join(FONTS, 'Heebo-Variable.ttf')))
    doc = ('<html><head><meta charset="utf-8"><style>%s body{margin:0;width:%dpx;height:%dpx;position:relative;background:#fff;'
           'overflow:hidden}</style></head><body>%s</body></html>') % (css, w, h, ''.join(parts))
    p = os.path.join(TMP, os.path.basename(out) + '.html')
    with open(p, 'w', encoding='utf-8') as fh:
        fh.write(doc)
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
                    '--allow-file-access-from-files', '--virtual-time-budget=5000', '--screenshot=' + out,
                    '--window-size=%d,%d' % (w, h), uri(p)], check=True, capture_output=True)
    print(os.path.basename(out))


# ---- cubes (block_art.dart: CubeColours.sky for a hint picture) ------------------------------------------------------------------
def cube(x, y, u, body=None, edge=None, shine=None):
    body, edge = body or C['sky'], edge or C['skyDeep']
    shine = shine or '#C9EAF9'
    r = max(1.5, u * 0.14)
    return ('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="%.2f" fill="%s" stroke="%s" stroke-width="%.2f"/>'
            '<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="%.2f" fill="%s"/>') % (
        x + 0.6, y + 0.6, u - 1.2, u - 1.2, r, body, edge, max(1.0, u * 0.09), x + u * 0.22, y + u * 0.2, u * 0.32, u * 0.16, r * 0.5,
        shine)


def rod_lying(x, y, u):
    """A rod of ten linked cubes lying down, left to right (never mirrored), one u thick."""
    out = ['<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="%.2f" fill="%s"/>' % (x - 0.8, y - 0.8, 10 * u + 1.6, u + 1.6, u * .2,
                                                                                       C['skyDeep'])]
    out += [cube(x + i * u, y, u) for i in range(10)]
    return ''.join(out)


def hint_card(x, y, w, h, n, u, label_size=20):
    """The where-is hint card: the number (LTR, w800) on top, the tens lying one under another at the left, the ones in a frame of five
    lying beside them; all at the tiles' cube u."""
    tens, ones = divmod(n, 10)
    gap_t = 4 if u > 13 else 3
    tens_h = tens * u + (tens - 1) * gap_t
    ones_rows = 1 if ones <= 5 else 2
    ones_w = min(ones, 5) * u + (min(ones, 5) - 1) * 1
    ones_h = ones_rows * u + (ones_rows - 1) * 2
    block_w = 10 * u + 14 + ones_w
    label_h = label_size * 1.2
    top = y + (h - (label_h + 4 + tens_h)) / 2
    left = x + (w - block_w) / 2
    parts = [box(x, y, w, h, 'background:%s;border:3px solid %s;border-radius:16px' % (C['skyTint'], C['sky']))]
    parts.append(text(x, top, w, label_h, str(n), label_size, 800, rtl=False, line=1.2))
    body = []
    by = top + label_h + 4
    for t in range(tens):
        body.append(rod_lying(left, by + t * (u + gap_t), u))
    ox, oy = left + 10 * u + 14, by + tens_h - ones_h
    for k in range(ones):
        r, c = divmod(k, 5)
        body.append(cube(ox + c * (u + 1), oy + r * (u + 2), u))
    parts.append(svg(0, 0, 1, 1, ''.join(body)))
    return parts


def mock_b9():
    W, H = 852, 393 + 180
    p = [box(0, 0, W, H, 'background:%s' % C['cream']), img(golden('c1_blocks_on_tiles_l3_phone.png'), 0, 0, 852, 393)]
    p.append(box(88, 86, 238, 116, 'background:%s' % C['cream']))   # the old card (9.1-pt cubes); the hand is kept at its right
    p.append(box(318, 86, 42, 72, 'background:%s' % C['cream']))
    p += hint_card(95, 92, 262, 104, 34, 12.7)
    p.append(note(8, 400, 840, 'B9 mock. Phone board: the hint card 262 x 104 (same box), 34 as lying rods at u = 12.7 (the tiles\' cube), '
                              'numeral 20 w800 LTR. Below at 1:1: 49 on the phone card, 34 and 49 on the SE card 230 x 96 (u 13.2).'))
    p += hint_card(16, 436, 262, 104, 49, 12.7)
    p += hint_card(300, 440, 230, 96, 34, 13.2)
    p += hint_card(552, 440, 230, 96, 49, 13.2)
    p.append(note(16, 544, 262, 'phone 262 x 104, 49, u 12.7', 12))
    p.append(note(300, 544, 230, 'SE 230 x 96, 34, u 13.2', 12))
    p.append(note(552, 544, 230, 'SE 230 x 96, 49, u 13.2', 12))
    render(os.path.join(HERE, 'add_b9_hint_card_phone.png'), W, H, p)


def size_sign(x, y, w, big_bright, word):
    """A size rule's sign: the ball of its size bright, the other size a ghost beside it (size is relative), the word under it."""
    s, b = 31, 62   # ball_size_l drawn in these boxes: ink about 24 and 48
    row_w = s + 6 + b
    left = x + (w - row_w) / 2
    out = [img(pic('ball_size_l'), left, y + b - s, s, s, 'opacity:%s' % ('0.3' if big_bright else '1')),
           img(pic('ball_size_l'), left + s + 6, y, b, b, 'opacity:%s' % ('1' if big_bright else '0.3'))]
    out.append(text(x, y + b + 2, w, 31, word, 18, 500))
    return out


def mock_size_bins():
    W, H = 852, 393 + 40
    p = [box(0, 0, W, H, 'background:%s' % C['cream']), img(golden('unit_drag_sort_phone.png'), 0, 0, 852, 393)]
    # redraw the stage: sky over grass, two shelves
    p.append(box(24, 96, 377, 260, 'border-radius:24px;background:linear-gradient(%s 0 62%%, %s 62%% 100%%)' % (C['skyTint'], C['grass'])))
    for i, (yy, word, big) in enumerate(((104, 'גָּדוֹל', True), (232, 'קָטָן', False))):
        p.append(box(32, yy, 361, 116, 'background:rgba(255,255,255,.92);border:3px solid %s;border-radius:16px' % C['hairline']))
        p += size_sign(289, yy + 10, 100, big, word)
    # the wells keep the tray's scale: an 88 box (the small ball's ink 24, the big one's 69)
    p.append(img(pic('ball_size_l'), 189, 116, 88, 88))
    p.append(img(pic('ball_size_s'), 189, 244, 88, 88))
    # the deck tile: the next ball at the tray's scale
    p.append(box(462, 266, 94, 94, 'background:%s' % C['cream']))
    p.append(tile(466, 270, 88, 88, '<img src="%s" style="width:88px;height:88px">' % uri(pic('ball_size_s'))))
    p.append(note(8, 400, 840, 'Size rule: sign column 104 wide; ball_size_l drawn in boxes 31 and 62 (ink 24 and 48), the other size at '
                              '0.3; label 18 w500. Wells and deck at the tray\'s 88 box (small ink 24).'))
    render(os.path.join(HERE, 'add_size_bins_phone.png'), W, H, p)


def hop_arcs(x, y, n, step, height, color, stroke=4):
    out = []
    for i in range(n):
        x0, x1 = x + i * step, x + (i + 1) * step
        out.append('<path d="M %.1f %.1f Q %.1f %.1f %.1f %.1f" fill="none" stroke="%s" stroke-width="%d" stroke-linecap="round"/>' % (
            x0 + 3, y, (x0 + x1) / 2, y - height * 1.6, x1 - 3, y, color, stroke))
        out.append('<path d="M %.1f %.1f l -9 -6 M %.1f %.1f l 1 -10" stroke="%s" stroke-width="%d" stroke-linecap="round"/>' % (
            x1 - 3, y, x1 - 3, y, color, stroke))
    return ''.join(out)


def number_line(x0, x1, y, lo, hi, tick, major, label, lw=4):
    step = (x1 - x0) / (hi - lo)
    out = ['<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="%d" stroke-linecap="round"/>' % (
        x0 - 6, y, x1 + 6, y, C['ink'], lw + 1)]
    labels = []
    for i in range(hi - lo + 1):
        xx = x0 + i * step
        t, m = (major, 6) if True else (tick, 4)
        out.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="%d"/>' % (xx, y - t / 2, xx, y + t / 2,
                                                                                                      C['ink'], m))
        labels.append(text(xx - 30, y + major / 2 + 2, 60, label * 1.3, str(lo + i), label, 800, rtl=False, line=1.3))
    return out, labels, step


BUBBLE = 'הַצְּפַרְדֵּעַ עוֹמֶדֶת עַל שְׁתַּיִם וְקוֹפֶצֶת שְׁלוֹשָׁה צְעָדִים קָדִימָה. עַל אֵיזֶה מִסְפָּר הִיא תִּנְחַת?'


def bubble(x, y, w, h, t, size, tail_y):
    return [box(x, y, w, h, 'background:#fff;border-radius:24px;box-shadow:0 4px 0 %s;padding:10px 18px;display:flex;align-items:center;'
                'justify-content:flex-end' % C['lip'],
                '<span dir="rtl" style="font:500 %dpx/1.7 H;color:%s;text-align:right">%s</span>' % (size, C['ink'], t)),
            svg(x + w - 2, tail_y - 12, 16, 24, '<path d="M0 0 L14 12 L0 24 Z" fill="#fff"/>')]


def sign_jump(x, y, w, h, start, hops, numeral, arc_step, arc_h, stroke):
    """The number sign of a jump item: where the marker starts (a numeral, LTR) on top, and the hops it makes under it (one arc per hop,
    left to right, at most five in a row)."""
    parts = [box(x, y, w, h, 'background:#fff;border:3px solid %s;border-radius:16px' % C['hairline'])]
    parts.append(text(x, y + 8, w, numeral * 1.15, str(start), numeral, 800, rtl=False, line=1.15))
    rows = [min(5, hops - 5 * r) for r in range((hops + 4) // 5)]
    body = []
    for r, k in enumerate(rows):
        left = x + (w - k * arc_step) / 2
        body.append(hop_arcs(left, y + 8 + numeral * 1.15 + 6 + arc_h * 1.2 + r * (arc_h * 1.2 + 10), k, arc_step, arc_h, C['skyDeep'],
                             stroke))
    parts.append(svg(0, 0, 1, 1, ''.join(body)))
    return parts


def sign_place(x, y, w, h, n, numeral):
    return [box(x, y, w, h, 'background:#fff;border:3px solid %s;border-radius:16px' % C['hairline']),
            text(x, y, w, h, str(n), numeral, 800, rtl=False, line=1.2)]


def mock_numline_phone():
    W, H = 852, 393 + 175
    p = [box(0, 0, W, H, 'background:%s' % C['cream']), img(golden('unit_number_line_jump_phone.png'), 0, 0, 852, 393)]
    p.append(box(18, 92, 600, 280, 'background:%s' % C['cream']))
    p += sign_jump(24, 100, 160, 132, 2, 3, 56, 28, 12, 4)
    p += bubble(196, 100, 407, 132, BUBBLE, 24, 170)
    p.append(box(24, 244, 581, 112, 'border-radius:24px;background:linear-gradient(%s 0 78%%, %s 78%% 100%%)' % (C['skyTint'],
                                                                                                                   C['grass'])))
    lines, labels, step = number_line(46, 583, 316, 0, 10, 20, 24, 20)
    p.append(svg(0, 0, 1, 1, ''.join(lines)))
    p += labels
    fx = 46 + 2 * step
    p.append(img(pic('frog'), fx - 28, 256, 56, 56))
    p.append(note(8, 398, 840, 'Phone number line (jump): number sign 160 x 132 at 24,100 (start numeral 56 w800 LTR, one arc per hop under it, '
                              '28 wide, stroke 4, rows of five); bubble 196..603 at 24 pt; marker 56; labels 20; spacing 53.7.'))
    p += sign_place(24, 424, 160, 132, 3, 64)
    p += sign_jump(200, 424, 160, 132, 7, 8, 56, 28, 12, 4)
    p.append(note(376, 450, 470, 'Left: a place item, the number to find, 64 w800 LTR (the prompt says it too).'))
    p.append(note(376, 472, 470, 'Right: a jump of 8 from 7 on 0..20: arcs in rows of five.'))
    p.append(note(376, 494, 470, 'Estimate 0..100: the same sign with the target (\u201c47\u201d) at 64.'))
    render(os.path.join(HERE, 'add_numline_phone.png'), W, H, p)


def mock_numline_tablet():
    W, H = 1180, 820
    p = [img(golden('unit_number_line_jump_tablet_landscape.png'), 0, 0, 1180, 820)]
    p.append(box(0, 229, 904, 591, 'background:%s' % C['cream']))
    p.append(box(24, 230, 848, 400, 'background:#fff;border-radius:24px;box-shadow:0 6px 0 %s' % C['lip']))
    p.append(box(40, 246, 816, 368, 'border-radius:16px;background:linear-gradient(%s 0 80%%, %s 80%% 100%%)' % (C['skyTint'],
                                                                                                                  C['grass'])))
    p += sign_jump(56, 262, 220, 160, 2, 3, 72, 40, 16, 5)
    lines, labels, step = number_line(80, 816, 530, 0, 10, 24, 32, 28, lw=5)
    p.append(svg(0, 0, 1, 1, ''.join(lines)))
    p += labels
    fx = 80 + 2 * step
    p.append(img(pic('frog'), fx - 40, 446, 80, 80))
    p.append(note(40, 652, 820, 'Tablet L: card 24,230 848 x 400; line at y 530 (0.75 of the card), 0..10 spacing 73.6, ticks 6 x 32, '
                               'labels 28 w800; marker 80.'))
    p.append(note(40, 674, 820, 'Sign 220 x 160 at the card top-left: start numeral 72, one arc per hop (40 wide, stroke 5); hops '
                               'drawn above the line up to 120 tall.'))
    p.append(note(40, 696, 820, 'Tablet P: card 24,372 772 x 520; line at 0.72 of the card; spacing 67; labels 28; marker 80; sign 220 x 160.'))
    render(os.path.join(HERE, 'add_numline_tabletL.png'), W, H, p)


def mock_balance():
    W, H = 852, 393 + 40
    p = [box(0, 0, W, H, 'background:%s' % C['cream']), img(golden('unit_balance_compare_phone.png'), 0, 0, 852, 393)]
    p.append(box(18, 88, 386, 300, 'background:%s' % C['cream']))
    p.append(box(150, 236, 460, 157, 'background:%s' % C['cream']))
    p.append(box(24, 96, 377, 260, 'border-radius:24px;background:linear-gradient(%s 0 78%%, %s 78%% 100%%)' % (C['skyTint'],
                                                                                                                 C['grass'])))
    import math
    cx, py, half, tilt = 212.5, 236, 95.5, math.radians(6)
    dx, dy = half * math.cos(tilt), half * math.sin(tilt)
    left, right = (cx - dx, py + dy), (cx + dx, py - dy)
    body = ['<path d="M %.1f 346 L %.1f 346 L %.1f 330 L %.1f 330 Z" fill="%s"/>' % (cx - 62, cx + 62, cx + 40, cx - 40, C['woodDeep']),
            '<rect x="%.1f" y="%.1f" width="12" height="%.1f" rx="4" fill="%s"/>' % (cx - 6, py, 332 - py, C['wood']),
            '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="10" stroke-linecap="round"/>' % (
                left[0] - 8, left[1] + 8 * math.sin(tilt), right[0] + 8, right[1] - 8 * math.sin(tilt), C['wood'])]
    for (ex, ey) in (left, right):
        body.append('<rect x="%.1f" y="%.1f" width="8" height="16" fill="%s"/>' % (ex - 4, ey - 18, C['woodDeep']))
        body.append('<rect x="%.1f" y="%.1f" width="170" height="10" rx="5" fill="%s" stroke="%s" stroke-width="2"/>' % (
            ex - 85, ey - 28, C['sea'], '#0F6E6A'))
    body.append('<circle cx="%.1f" cy="%.1f" r="9" fill="%s" stroke="%s" stroke-width="2"/>' % (cx, py, C['spark'], C['sparkDeep']))
    p.append(svg(0, 0, 1, 1, ''.join(body)))

    def row(ex, ey, names):
        n = len(names)
        x0 = ex - (n * 30 + (n - 1) * 4) / 2
        return [img(pic(nm), x0 + i * 34, ey, 30, 30) for i, nm in enumerate(names)]
    p += row(left[0], left[1] - 28 - 30, ['star'] * 5) + row(left[0], left[1] - 28 - 64, ['fish'] * 4)
    p += row(right[0], right[1] - 28 - 30, ['star'] * 3) + row(right[0], right[1] - 28 - 64, ['fish'] * 2)
    arrows = {'l': '<path d="M30 20 H10 M18 11 L9 20 L18 29" ', 'e': '<path d="M10 15 H30 M10 25 H30" ',
              'r': '<path d="M10 20 H30 M22 11 L31 20 L22 29" '}
    for i, k in enumerate(('l', 'e', 'r')):
        ic = '<svg viewBox="0 0 40 40" width="40" height="40">%sfill="none" stroke="%s" stroke-width="4" stroke-linecap="round" ' \
             'stroke-linejoin="round"/></svg>' % (arrows[k], C['ink'])
        p.append(tile(413 + i * 100, 262, 88, 88, ic))
    p.append(note(8, 400, 840, 'A5: stage 24,96 377 x 260; beam 191 between the pans\' centres, tilt 6\u00b0; trays 170 wide (level); '
                              'things 30 (ink 24+), rows of five, 4 apart, up to three rows; tiles 88 at 413 / 513 / 613, y 262; arrows never mirror.'))
    render(os.path.join(HERE, 'add_balance_phone.png'), W, H, p)


def frame_tile(x, y, n, cell=32, w=177, h=96, name='apple'):
    parts = [tile(x, y, w, h)]
    gx = x + (w - (5 * cell + 4)) / 2
    gy = y + (h - (2 * cell + 2)) / 2
    for k in range(n):
        r, c = divmod(k, 5)
        parts.append(img(pic(name), gx + c * (cell + 1), gy + r * (cell + 2), cell, cell))
    return parts


def mock_ten_tiles():
    W, H = 852, 393 + 40
    p = [box(0, 0, W, H, 'background:%s' % C['cream']), img(golden('unit_match_numbers_phone.png'), 0, 0, 852, 393)]
    p.append(box(60, 100, 340, 120, 'background:%s' % C['cream']))
    p.append(box(14, 230, 600, 120, 'background:%s' % C['cream']))
    for i, n in enumerate((7, 10, 9)):
        p.append(tile(97 + i * 108, 112, 96, 96, '<span dir="ltr" style="font:800 56px/1 H;color:%s">%d</span>' % (C['ink'], n)))
        p += frame_tile(37 + i * 189, 252, (9, 7, 10)[i])
    p.append(note(8, 400, 840, 'A set of 7 to 10 on a tile: a 5 x 2 frame of 32-pt cells (apple ink about 24), tile 177 x 96; three tiles '
                              'with 12 gaps across 24..605 (555 wide). Never a pile with a count: the quantity is the answer.'))
    render(os.path.join(HERE, 'add_ten_tiles_phone.png'), W, H, p)


if __name__ == '__main__':
    mock_b9()
    mock_size_bins()
    mock_numline_phone()
    mock_numline_tablet()
    mock_balance()
    mock_ten_tiles()
