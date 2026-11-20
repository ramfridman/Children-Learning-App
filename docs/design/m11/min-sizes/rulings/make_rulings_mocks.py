"""Mocks for section 9 of docs/design/m11/min-sizes.md (the rulings of 2026-11-20 on round 3), drawn at real size in points, each beside
the screen as it is built today, with the app's own pictures (content/starter/*.svg) and font (Heebo), rendered by headless Chrome:

    python docs/design/m11/min-sizes/rulings/make_rulings_mocks.py

  ruling_d3_three_shelf_phone.png   D3: the phone's three-shelf sort. Before: a pair of 30-pt samples with the label under them in a
                                    76-high shelf. After: ONE sample in a 52 box (ink 44) and the label beside it, items 48 in the well.
  ruling_t2_match_card_tabletP.png  T2: the tablet match board. Before: three 136 faces in the middle of a 772 x 520 card, coins 42-56,
                                    the answers under the card. After: both rows inside one card (772 x 600), faces 216 / 176,
                                    coins at their real ratio (5 = 160).
  ruling_t2_match_card_tabletL.png  T2 on the landscape tablet: card 848 x 534, faces 200 / 160.
  ruling_t1_empty_stage_tabletL.png T1: a question whose stage holds nothing (Colour Bay's "where is the red balloon?"). Before: an empty
                                    848 x 400 landscape over three 104 tiles. After: the answers stand in the card, three of 200.

The base images in rulings/base/ are the round-3 build (branch lands-ux at 4a4a39bf) rendered by app/test/min_sizes_shots_test.dart at
1 pixel = 1 point. Nothing is traced or copied; the coins, balls and balloons are the app's own drawings. A reference for the developer and
the owner, not a screenshot of the running app.
"""
import os
import pathlib
import subprocess
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..', '..', '..', '..'))
PICS = os.path.join(ROOT, 'content', 'starter')
FONTS = os.path.join(ROOT, 'app', 'assets', 'fonts')
BASE = os.path.join(HERE, 'base')
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'
TMP = tempfile.mkdtemp(prefix='rulingmock_')

C = dict(cream='#FFF6E8', paper='#FFFFFF', ink='#2B2350', hairline='#E6DDF0', lip='#DCD3EC', skyTint='#E3F4FC', grass='#A8DB8F',
         grassShade='#86C474', note='#B23A3A', lilac='#B9A6E0')


def uri(p):
    return pathlib.Path(p).as_uri()


def pic(name):
    return os.path.join(PICS, name + '.svg')


def box(x, y, w, h, style='', inner=''):
    return '<div style="position:absolute;left:%.1fpx;top:%.1fpx;width:%.1fpx;height:%.1fpx;box-sizing:border-box;%s">%s</div>' % (
        x, y, w, h, style, inner)


def img(path, x, y, w, h, extra=''):
    return '<img src="%s" style="position:absolute;left:%.1fpx;top:%.1fpx;width:%.1fpx;height:%.1fpx;%s">' % (uri(path), x, y, w, h,
                                                                                                               extra)


def text(x, y, w, h, t, size, weight=500, align='center', rtl=True, color=None, line=1.7):
    return box(x, y, w, h, 'display:flex;align-items:center;justify-content:%s;text-align:%s' % (
        {'center': 'center', 'right': 'flex-end', 'left': 'flex-start'}[align], align),
        '<span dir="%s" style="font:%d %dpx/%.2f H;color:%s;white-space:nowrap">%s</span>' % (
            'rtl' if rtl else 'ltr', weight, size, line, color or C['ink'], t))


def note(x, y, w, t, size=14):
    return box(x, y, w, 40, 'font:600 %dpx/1.35 sans-serif;color:%s' % (size, C['note']), t)


def tile(x, y, w, h, inner='', radius=20):
    return box(x, y, w, h, 'background:#fff;border:2px solid %s;border-radius:%dpx;box-shadow:0 5px 0 %s;display:flex;align-items:center;'
               'justify-content:center' % (C['hairline'], radius, C['lip']), inner)


def badge(cx, cy, n, d=32, size=20):
    return box(cx - d / 2, cy - d / 2, d, d, 'background:%s;border-radius:50%%;display:flex;align-items:center;justify-content:center;'
               'border:2px solid #fff' % C['ink'], '<span style="font:800 %dpx/1 H;color:#fff">%d</span>' % (size, n))


def render(out, w, h, parts):
    css = "@font-face{font-family:H;src:url('%s');font-weight:100 900}" % uri(os.path.join(FONTS, 'Heebo-Variable.ttf'))
    doc = ('<html><head><meta charset="utf-8"><style>%s body{margin:0;width:%dpx;height:%dpx;position:relative;background:#fff;'
           'overflow:hidden}</style></head><body>%s</body></html>') % (css, w, h, ''.join(parts))
    p = os.path.join(TMP, os.path.basename(out) + '.html')
    with open(p, 'w', encoding='utf-8') as fh:
        fh.write(doc)
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
                    '--allow-file-access-from-files', '--virtual-time-budget=5000', '--screenshot=' + out,
                    '--window-size=%d,%d' % (w, h), uri(p)], check=True, capture_output=True)
    print(os.path.basename(out))


def frame_copy(base, ox, oy, w, h):
    """The built screen as the base of an 'after' panel: the parts that do not change (controls, bubble, guide) stay."""
    return img(os.path.join(BASE, base), ox, oy, w, h)


# ---- D3: the phone's three-shelf sort ----------------------------------------------------------------------------------------------------
def shelf(ox, oy, x, y, w, h, sample, label, items):
    """A shelf: the sign on the start (right) side (one sample in a 52 box, the label beside it at 18 w500), a hairline, the well."""
    parts = [box(ox + x, oy + y, w, h, 'background:rgba(255,255,255,0.92);border:3px solid %s;border-radius:16px' % C['hairline'])]
    sx = x + w - 8 - 52
    parts.append(img(pic(sample), ox + sx, oy + y + (h - 52) / 2, 52, 52))
    parts.append(text(ox + sx - 8 - 70, oy + y, 70, h, label, 18, align='right'))
    line_x = sx - 8 - 70 - 8
    parts.append(box(ox + line_x, oy + y + 10, 2, h - 20, 'background:%s' % C['hairline']))
    ix = line_x - 8 - 48
    for i, it in enumerate(items):
        parts.append(img(pic(it), ox + ix - i * 56, oy + y + (h - 48) / 2, 48, 48))
    return parts


def mock_d3():
    W, H = 852, 393
    parts = [img(os.path.join(BASE, 'phone_drag_sort_three.png'), 0, 30, W, H),
             note(4, 4, W, 'BEFORE (round 3): a pair of samples at 30, the label under them, items 41 (the shelf is 76 high)')]
    ox, oy = W + 24, 30
    parts += [frame_copy('phone_drag_sort_three.png', ox, oy, W, H),
              box(ox + 24, oy + 96, 377, 262, 'background:%s;border-radius:24px' % C['skyTint']),
              box(ox + 24, oy + 290, 377, 68, 'background:%s;border-radius:0 0 24px 24px' % C['grass'])]
    parts += shelf(ox, oy, 32, 104, 361, 76, 'apple', 'תַּפּוּחַ', ['apple', 'apple'])
    parts += shelf(ox, oy, 32, 186, 361, 76, 'star', 'כּוֹכָב', ['star'])
    parts += shelf(ox, oy, 32, 268, 361, 76, 'fish', 'דָּג', [])
    parts.append(note(ox + 4, 4, W, 'AFTER (D3): one sample, box 52 (ink 44), label 18 w500 beside it; items 48 in the well, 4 then a pile'))
    parts.append(note(4, H + 40, 2 * W, 'Shelves 361 x 76 at x 32, y 104 / 186 / 268 (gap 6). Sign column 146 from the start edge: '
                      'inset 8, sample 52, gap 8, label box 70, gap 8, hairline 2. Well 199 wide: four items of 48 (gap 8), then the pile '
                      'with the count badge (32 / 20). Every label is voiced; a sample stands for its kind.', 13))
    render(os.path.join(HERE, 'ruling_d3_three_shelf_phone.png'), 2 * W + 24, H + 90, parts)


# ---- T2: the tablet match board ------------------------------------------------------------------------------------------------------------
COIN_RATIO = {'coin_s1': 18 / 24, 'coin_s2': 21.6 / 24, 'coin_s5': 1.0, 'coin_s10': 23 / 24}


def face_coin(x, y, side, coin, five):
    d = five * COIN_RATIO[coin]
    return [tile(x, y, side, side, radius=28), img(pic(coin), x + (side - d) / 2, y + (side - d) / 2, d, d)]


def face_numeral(x, y, side, n, size):
    return tile(x, y, side, side, '<span style="font:800 %dpx/1 H;color:%s" dir="ltr">%d</span>' % (size, C['ink'], n), radius=26)


def match_board(ox, oy, card, top, bottom, five, numeral, coins, nums, gap_rows):
    cx, cy, cw, ch = card
    parts = [box(ox + cx, oy + cy, cw, ch, 'background:#fff;border-radius:28px;box-shadow:0 6px 0 %s' % C['lip'])]
    n = len(coins)
    total_h = top + gap_rows + bottom
    y_top = cy + (ch - total_h) / 2
    gap = 24
    x0 = cx + (cw - (n * top + (n - 1) * gap)) / 2
    for i, c in enumerate(coins):
        parts += face_coin(ox + x0 + i * (top + gap), oy + y_top, top, c, five)
    x1 = cx + (cw - (n * bottom + (n - 1) * gap)) / 2
    for i, k in enumerate(nums):
        parts.append(face_numeral(ox + x1 + i * (bottom + gap), oy + y_top + top + gap_rows, bottom, k, numeral))
    return parts


def mock_t2(board, base, W, H, card, top, bottom, five, numeral, gap_rows, label):
    parts = [img(os.path.join(BASE, base), 0, 40, W, H),
             note(4, 4, W, 'BEFORE (round 3): faces 136 in the middle of the card, coins 42 to 56, the answers under the card')]
    ox, oy = W + 32, 40
    parts += [img(os.path.join(BASE, base), ox, oy, W, H),
              box(ox, oy + card[1] - 8, card[0] + card[2] + 28, H - card[1] + 8, 'background:%s' % C['cream'])]
    parts += match_board(ox, oy, card, top, bottom, five, numeral, ['coin_s1', 'coin_s2', 'coin_s5'], [2, 5, 1], gap_rows)
    # a matched pair: the number badge (36) at the start-top corner of both faces
    parts.append(note(ox + 4, 4, W, label))
    render(os.path.join(HERE, 'ruling_t2_match_card_%s.png' % board), 2 * W + 32, H + 50, parts)


# ---- T1: an empty stage gives its room to the answers ------------------------------------------------------------------------------------
def mock_t1():
    W, H = 1180, 820
    parts = [img(os.path.join(BASE, 'tabletL_colour_find.png'), 0, 40, W, H),
             note(4, 4, W, 'BEFORE (round 3): an empty 848 x 400 landscape, the three answers 104 under it')]
    ox, oy = W + 32, 40
    parts += [img(os.path.join(BASE, 'tabletL_colour_find.png'), ox, oy, W, H),
              box(ox, oy + 640, 900, 180, 'background:%s' % C['cream'])]
    side, gap = 200, 40
    x0 = 24 + (848 - (3 * side + 2 * gap)) / 2
    y0 = 230 + (400 - side) / 2 + 20
    for i, name in enumerate(['balloon_red', 'balloon_blue', 'ball_red']):
        parts.append(tile(ox + x0 + i * (side + gap), oy + y0, side, side,
                          '<img src="%s" style="width:%dpx;height:%dpx">' % (uri(pic(name)), side * 0.72, side * 0.72), radius=32))
    parts.append(note(ox + 4, 4, W, 'AFTER (T1): the answers stand in the card: three tiles of 200 (gap 40), pictures 144; nothing under'))
    render(os.path.join(HERE, 'ruling_t1_empty_stage_tabletL.png'), 2 * W + 32, H + 50, parts)


if __name__ == '__main__':
    mock_d3()
    mock_t2('tabletP', 'tabletP_match_coins.png', 820, 1180, (24, 372, 772, 600), 216, 176, 160, 104, 64,
            'AFTER (T2): one card 772 x 600, faces 216 over answers 176, coins at the real ratio (5 = 160, 2 = 144, 1 = 120)')
    mock_t2('tabletL', 'tabletL_match_coins.png', 1180, 820, (24, 230, 848, 534), 200, 160, 148, 96, 48,
            'AFTER (T2): one card 848 x 534, faces 200 over answers 160, coins 5 = 148, 2 = 133, 1 = 111')
    mock_t1()
