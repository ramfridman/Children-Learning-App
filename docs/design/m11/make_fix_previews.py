"""Preview sheets of the second Stage 1 fix round (2026-11-15), rendered by headless Chrome:

    python docs/design/m11/make_fix_previews.py

  goni_everywhere.png   every bundled place where Goni appears, before (the commit BEFORE, his old pastel crest) and after (his mint
                        look, docs/design/m11-rooms.md section 5.2): the four home maps and their language variants (a close-up
                        at 3x and at real size), the first sticker, and his four poses in Colour Bay.
  reactions_small.png   the nine landmarks resting and reacted at 56 and 64 points (the header slot) and at 200; Counting Hills and
                        Market Village also as they were before.
  market_closeup.png    Market Village's backdrop alone on the phone stage at 2x, and the stage with three coins on it.
The room board docs/design/m11/room_math.png comes from make_m11_boards.py (room_page).
"""
import os
import re
import subprocess
import tempfile

import make_m11_boards as M

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = M.ROOT
ART = M.ART
BEFORE = '8f2bdab1'          # the commit before this round
TMP = tempfile.mkdtemp(prefix='fix2_')


def before(rel):
    """The file as it was at BEFORE, written to a temporary file."""
    out = os.path.join(TMP, rel.replace('/', '_'))
    data = subprocess.run(['git', 'show', '%s:%s' % (BEFORE, rel)], cwd=ROOT, capture_output=True, check=True).stdout
    with open(out, 'wb') as fh:
        fh.write(data)
    return out


def goni_at(path):
    """Where Goni stands in a scene: the 0.1 group that holds his skin colour, plus every translate of the groups round it."""
    s = open(path, encoding='utf-8').read()
    i = s.upper().index('#7FD3B0')
    stack = []
    for m in re.finditer(r'<g( [^>]*)?>|</g>', s[:i]):
        if m.group(0) == '</g>':
            stack.pop()
        else:
            t = re.search(r'translate\(([-\d.]+)[ ,]+([-\d.]+)\)', m.group(0))
            stack.append((float(t.group(1)), float(t.group(2))) if t else (0.0, 0.0))
    return sum(x for x, _ in stack), sum(y for _, y in stack)


def size(path):
    w, h = re.search(r'viewBox="0 0 ([\d.]+) ([\d.]+)"', open(path, encoding='utf-8').read()).groups()
    return float(w), float(h)


def crop(path, cx, cy, w, h, k):
    """A window of w x h scene points round (cx, cy), drawn at k."""
    sw, sh = size(path)
    return ('<div style="position:relative;width:%dpx;height:%dpx;overflow:hidden;border-radius:8px;border:1px solid #ddd">'
            '<img src="%s" style="position:absolute;left:%.1fpx;top:%.1fpx;width:%dpx;height:%dpx;transform:scale(%g);'
            'transform-origin:0 0"></div>' % (w * k, h * k, M.uri(path), -(cx - w / 2) * k, -(cy - h / 2) * k, sw, sh, k))


def cap(t, w=None):
    return '<div style="font:600 12px/1.35 sans-serif;color:#2B2350;margin:4px 0 2px;%s">%s</div>' % (
        'width:%dpx' % w if w else '', M.esc(t))


def render(html, out, w, h):
    p = os.path.join(TMP, os.path.basename(out) + '.html')
    with open(p, 'w', encoding='utf-8') as fh:
        fh.write('<html><head><meta charset="utf-8"><style>%s body{margin:0;background:#fff;padding:12px;width:%dpx}'
                 '.row{display:flex;gap:14px;align-items:flex-start;margin-bottom:10px}</style></head><body>%s</body></html>' % (
                     M.FONT_CSS, w - 24, html))
    subprocess.run([M.CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
                    '--allow-file-access-from-files', '--virtual-time-budget=6000', '--screenshot=' + out,
                    '--window-size=%d,%d' % (w, h), M.uri(p)], check=True, capture_output=True)
    print(os.path.relpath(out, ROOT))


def goni_everywhere():
    html = ['<div style="font:700 17px sans-serif;color:#2B2350;margin-bottom:8px">Goni everywhere: before (left pair, his old '
            'pastel crest) and after (right pair, mint with teal stripes and outline); each pair is a 3x close-up and the real '
            'size (0.1 of his 512 artboard, 51 points, like every host on the map)</div>']
    scenes = ['home_phone', 'home_phone_se', 'home_tablet_landscape', 'home_tablet_portrait']
    for sc in scenes:
        for var in ('', '_lang'):
            rel = 'app/assets/art/scenes/%s%s.svg' % (sc, var)
            now = os.path.join(ROOT, rel)
            old = before(rel)
            x, y = goni_at(now)
            cx, cy = x + 28, y + 36
            html.append('<div class="row">%s%s%s%s%s</div>' % (
                cap(rel.split('/')[-1], 150), crop(old, cx, cy, 110, 70, 3), crop(old, cx, cy, 110, 70, 1),
                crop(now, cx, cy, 110, 70, 3), crop(now, cx, cy, 110, 70, 1)))
    rel = 'app/assets/art/stickers/sticker_01.svg'
    html.append('<div class="row">%s' % cap('sticker_01.svg (the first sticker, the album and the home island)', 150))
    for p in (before(rel), os.path.join(ROOT, rel)):
        for s in (160, 64):
            html.append('<div style="width:%dpx;height:%dpx;background:#FFF6E8;border-radius:12px;border:1px solid #ddd">'
                        '<img src="%s" style="width:100%%;height:100%%"></div>' % (s, s, M.uri(p)))
    html.append('</div>')
    html.append('<div class="row">%s' % cap('Colour Bay host poses (already mint since the first fix round; unchanged)', 150))
    for pose in ('idle', 'talk', 'show', 'celebrate'):
        html.append('<div style="width:130px;height:130px;background:#FCE1F0;border-radius:12px"><img src="%s" style="width:100%%;'
                    'height:100%%"></div>' % M.uri(os.path.join(ART, 'hosts', 'goni_%s.svg' % pose)))
    html.append('</div>')
    html.append(cap('Left as they are: the approved design boards (design/boards/*.dc.html, records), the frozen board copies in '
                    'tools/home_map_src/ (the generator swaps him on the way out) and the Hebrew course picture s2_p5.svg inside '
                    'the signed lang-heb pack (content/languages/heb/pack/; its source content/languages/pictures/s2-p5.svg too).',
                    1180))
    render(''.join(html), os.path.join(HERE, 'goni_everywhere.png'), 1220, 2290)


def reactions_small():
    html = ['<div style="font:700 17px sans-serif;color:#2B2350;margin-bottom:8px">The nine landmarks, resting and reacted (the '
            'end state), at 56 and 64 points (the header slot) and at 200, on each room\'s screen tint</div>']
    rows = [(r, None) for r in M.ROOMS]
    rows.insert(1, (M.ROOM['numbers'], before('app/assets/art/rooms/numbers_reacted.svg')))
    rows.insert(7, (M.ROOM['math'], before('app/assets/art/rooms/math_reacted.svg')))
    for r, old in rows:
        key = r['key']
        lm = os.path.join(M.ROOMART, '%s_landmark.svg' % key)
        re_ = old or os.path.join(M.ROOMART, '%s_reacted.svg' % key)
        cells = [cap('%s%s' % (r['en'], ' (BEFORE)' if old else ''), 150)]
        for s, on in ((56, False), (56, True), (64, False), (64, True), (200, False), (200, True)):
            cells.append('<div style="position:relative;width:%dpx;height:%dpx;background:%s;border-radius:8px">'
                         '<img src="%s" style="position:absolute;inset:0;width:100%%;height:100%%">%s</div>' % (
                             s, s, r['tint'], M.uri(lm),
                             '<img src="%s" style="position:absolute;inset:0;width:100%%;height:100%%">' % M.uri(re_) if on else ''))
        html.append('<div class="row" style="align-items:center%s">%s</div>' % (
            ';opacity:.75' if old else '', ''.join(cells)))
    render(''.join(html), os.path.join(HERE, 'reactions_small.png'), 1060, 2560)


def market_closeup():
    room = M.ROOM['math']
    w, h = 660, 254
    plain = M.stage_only(room, w + 8, h + 8)
    coins = M.stage_only(room, w + 8, h + 8, inner=M.three_pictures('math'))
    parts = [(M.scaled(plain, w + 8, h + 8, 2), (w + 8) * 2, (h + 8) * 2,
              'Market Village, phone stage at 2x, empty: the vaulted roof and skylight, the arcade with a stall in every arch '
              '(pastel awnings in the calm middle), produce at the arcade\'s foot, crates on the paving, the garland under the '
              'awning, the spice sacks and the watermelon in the corner.'),
             (M.scaled(coins, w + 8, h + 8, 2), (w + 8) * 2, (h + 8) * 2,
              'The same with three coins on it (the hardest case: pictures straight on the backdrop).')]
    M.page(parts, os.path.join(HERE, 'market_closeup.png'), (w + 8) * 2 + 40)


if __name__ == '__main__':
    goni_everywhere()
    reactions_small()
    market_closeup()
