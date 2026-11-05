"""Mockups of docs/design/languages-l4-layout.md (QA-L4-1, -3, -8, -9): each board drawn at its real size in points with the
app's own pictures, rendered by headless Chrome into docs/design/languages-l4/*.png.

    python docs/design/languages-l4/make_l4_mockups.py

The boards' numbers are those of app/lib/child/activity_shell.dart (ActivitySpec) and app/lib/play/choice_row.dart
(withTallStage); the new positions are the spec's. Labels on the mockups are for the team, never in the app.
"""
import json
import os
import pathlib
import subprocess
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..', '..'))
PICS = os.path.join(ROOT, 'content', 'languages', 'pictures')
CAST = os.path.join(ROOT, 'design', 'assets')
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'

# (width, height), and the activity frame's fixed pieces of ActivitySpec, in board points
BOARDS = {
    'phone': dict(W=852, H=393, home=(852 - 59 - 64, 12), eye=(59, 12), hint=(147, 12), ctrl=64, bubble=(413, 104, 190, 132),
                  guide=(617, 80, 176), mic=(661, 260, 88), stage=(71, 96, 330, 128), tall=(71, 96, 330, 253), tiles=(71, 244, 534)),
    'phoneSE': dict(W=667, H=375, home=(667 - 16 - 64, 8), eye=(16, 8), hint=(96, 8), ctrl=64, bubble=(300, 92, 176, 118),
                    guide=(490, 66, 150), mic=(521, 226, 88), stage=(16, 86, 270, 104), tall=(16, 86, 270, 245), tiles=(8, 214, 480)),
    'tabletLandscape': dict(W=1180, H=820, home=(1180 - 24 - 72, 24), eye=(24, 24), hint=(112, 24), ctrl=72, bubble=(356, 112, 600, 112),
                            guide=(896, 150, 260), mic=(978, 672, 96), stage=(288, 230, 584, 300), tall=(288, 230, 584, 546), tiles=(288, 554, 584)),
    'tabletPortrait': dict(W=820, H=1180, home=(820 - 24 - 72, 32), eye=(24, 32), hint=(112, 32), ctrl=72, bubble=(156, 152, 440, 208),
                           guide=(596, 112, 200), mic=(44, 172, 96), stage=(24, 372, 772, 300), tall=(24, 372, 772, 764), tiles=(24, 696, 772)),
}
SPEC = {   # the positions this spec sets
    'card': {'phone': (413, 248, 96, 96), 'phoneSE': (300, 222, 96, 96), 'tabletLandscape': (136, 300, 130, 130), 'tabletPortrait': 'band'},
    'question': {'phone': dict(stage=(71, 96, 330, 128), row_y=244, gap_ts=6, gap=15, x0=74),
                 'phoneSE': dict(stage=(16, 86, 270, 116), row_y=220, gap_ts=4, gap=8, x0=6)},
    'drum': {   # in stage coordinates of the tall stage, LTR (RTL mirrors x)
        'phone': dict(pic=(8, 8, 96), drum=(159, 8, 116), hands=(132, 34), dots=(182, 18, 8), check=(246, 169, 72), band=(8, 234)),
        'phoneSE': dict(pic=(8, 8, 80), drum=(129, 8, 100), hands=(116, 30), dots=(158, 14, 4), check=(186, 161, 72), band=(8, 174)),
        'tabletLandscape': dict(pic=(12, 12, 150), drum=(253, 16, 240), hands=(280, 44), dots=(350, 32, 12), check=(476, 438, 96), band=(12, 464)),
        'tabletPortrait': dict(pic=(12, 12, 180), drum=(332, 16, 300), hands=(340, 50), dots=(420, 36, 12), check=(664, 656, 96), band=(12, 652)),
    },
}


def uri(path):
    return pathlib.Path(path).as_uri()


def box(x, y, w, h, style='', inner='', cls=''):
    return '<div class="%s" style="position:absolute;left:%spx;top:%spx;width:%spx;height:%spx;%s">%s</div>' % (cls, x, y, w, h, style, inner)


def img(path, x, y, w, h, extra=''):
    return '<img src="%s" style="position:absolute;left:%spx;top:%spx;width:%spx;height:%spx;object-fit:contain;%s">' % (uri(path), x, y, w, h, extra)


def label(x, y, text, color='#B23A3A'):
    return '<div style="position:absolute;left:%spx;top:%spx;font:11px sans-serif;color:%s;white-space:nowrap">%s</div>' % (x, y, color, text)


def frame(b, title):
    """The activity frame of a board: the controls, the trail, the guide's bubble, the guide and the microphone."""
    B = BOARDS[b]
    out = [box(0, 0, B['W'], B['H'], 'background:#FFF6E8;border:1px solid #C9C3D9')]
    for k in ('home', 'eye', 'hint'):
        x, y = B[k]
        out.append(box(x, y, B['ctrl'], B['ctrl'], 'border-radius:50%;background:#FFFFFF;border:2px solid #DCD3EC'))
    x, y, w, h = B['bubble']
    out.append(box(x, y, w, h, 'border:2px dashed #B9A2F7;border-radius:18px;background:rgba(255,255,255,0.6)'))
    out.append(label(x + 6, y + 4, 'bubble (max)', '#6C40D0'))
    gx, gy, gs = B['guide']
    out.append(img(os.path.join(CAST, 'nitzi-idle.svg'), gx, gy, gs, gs))
    mx, my, ms = B['mic']
    out.append(box(mx, my, ms, ms, 'border-radius:50%;background:#FFFFFF;border:2px solid #DCD3EC'))
    out.append(label(mx + 8, my + ms / 2 - 6, 'mic', '#6C40D0'))
    out.append(box(0, B['H'] - 24, B['W'], 24, 'background:repeating-linear-gradient(45deg,#EDE6F7 0 6px,#FFF6E8 6px 12px)'))
    out.append(label(8, 4 if b.startswith('phone') else 6, title, '#2B2350'))
    return out


def page(boards_html, out_png, width):
    tmp = tempfile.mkdtemp(prefix='l4_')
    body = ''.join('<div style="position:relative;display:inline-block;margin:10px;width:%dpx;height:%dpx">%s</div>' % (w, h, ''.join(parts))
                   for parts, w, h in boards_html)
    html = '<html><body style="margin:0;background:#FFFFFF;width:%dpx">%s</body></html>' % (width, body)
    path = os.path.join(tmp, 'p.html')
    with open(path, 'w', encoding='utf-8') as fh:
        fh.write(html)
    height = 0
    row_w, row_h = 0, 0
    for _, w, h in boards_html:
        if row_w + w + 20 > width:
            height += row_h + 20
            row_w, row_h = 0, 0
        row_w += w + 20
        row_h = max(row_h, h)
    height += row_h + 30
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1', '--allow-file-access-from-files',
                    '--screenshot=' + out_png, '--window-size=%d,%d' % (width, height), uri(path)], check=True, capture_output=True)


# ---- QA-L4-1 and -2: the body map ------------------------------------------------------------------------------------

COLS = {'head': '#E53935', 'tummy': '#2F7FE0', 'belly': '#2F7FE0', 'feet': '#36A852', 'hands': '#8A5CF0', 'fingers': '#8A5CF0',
        'arms': '#F59E1B', 'legs': '#1A9E9A', 'ears': '#E04F9E', 'eyes': '#C99A00', 'nose': '#3A3650', 'hair': '#795548', 'mouth': '#B23A3A'}


def body_map():
    d = json.load(open(os.path.join(PICS, 'mika-body.hotspots.json'), encoding='utf-8'))
    side = 233   # the phone SE's scene, the smallest
    boards = []
    for item in ('ENG-A-06 i01', 'ENG-A-06 i06', 'rus.a03.05', 'rus.a03.10'):
        it = d['items'][item]
        parts = [img(os.path.join(PICS, 'mika-body.svg'), 0, 20, side, side)]
        for name in it['parts']:
            for x, y, w, h in d['parts'][name]:
                c = COLS[name]
                parts.append(box(round(x * side), round(20 + y * side), round(w * side), round(h * side),
                                 'background:%s33;border:2px solid %s;box-sizing:border-box' % (c, c)))
                parts.append(label(round(x * side) + 3, round(20 + y * side) + 2, '%s %d pt' % (name, round(w * side)), c))
        parts.append(label(0, 2, '%s on the body (phone SE, scene %d pt)' % (item, side), '#2B2350'))
        boards.append((parts, side, side + 24))
    page(boards, os.path.join(HERE, 'body_map_on_body.png'), 2 * (side + 24))
    # an item shown as close-up cards, on the phone board
    b = 'phone'
    B = BOARDS[b]
    parts = frame(b, 'ENG-A-06 i03 "Touch your ears!" as close-up cards (phone)')
    x, y, w, h = B['stage']
    parts.append(box(x, y, w, h, 'border:2px dashed #8FBFE0;border-radius:12px'))
    parts.append(img(os.path.join(PICS, 'mika-body.svg'), x + (w - 116) / 2, y + 6, 116, 116))
    tx, ty, tw = B['tiles']
    cards = d['items']['ENG-A-06 i03']['cards']
    x0 = tx + (tw - (3 * 96 + 2 * 24)) / 2
    for i, c in enumerate(cards):
        parts.append(box(x0 + i * 120, ty, 96, 96, 'background:#FFFFFF;border:3px solid #DCD3EC;border-radius:18px;box-sizing:border-box',
                         '<img src="%s" style="width:88px;height:88px;margin:1px">' % uri(os.path.join(PICS, c + '.svg'))))
        parts.append(label(x0 + i * 120 + 2, ty + 98, '%s 96 pt' % c))
    page([(parts, B['W'], B['H'])], os.path.join(HERE, 'body_map_as_cards_phone.png'), B['W'] + 20)


# ---- QA-L4-3: where the close-up card sits -------------------------------------------------------------------------

def closeup_slots():
    boards = []
    for b, B in BOARDS.items():
        parts = frame(b, 'QA-L4-3 close-up card, %s' % b)
        x, y, w, h = B['tall']
        parts.append(box(x, y, w, h, 'border:2px dashed #8FBFE0;border-radius:12px'))
        slot = SPEC['card'][b]
        if slot == 'band':   # portrait: the scene leaves a band at the bottom for the card
            side = h - 150
            sx, sy = x + (w - side) / 2, y + 6
            card = (x + w - 6 - 130, y + side + 12, 130, 130)
        else:
            side = min(w, h) - 12
            sx, sy = x + (w - side) / 2, y + (h - side) / 2
            card = slot
        parts.append(box(sx, sy, side, side, 'background:#F4F8FF;border:1px solid #CFE3F5'))
        parts.append(img(os.path.join(PICS, 'chair.svg'), sx + side * 0.1, sy + side * 0.1, side * 0.8, side * 0.8))
        for zx, zy, zw, zh, tag in ((0.4, 0.04, 0.5, 0.26, 'on'), (0.05, 0.62, 0.3, 0.3, 'next to'), (0.4, 0.66, 0.5, 0.3, 'under')):
            parts.append(box(sx + zx * side, sy + zy * side, zw * side, zh * side, 'border:3px solid #FFC83D;border-radius:14px;box-sizing:border-box'))
            parts.append(label(sx + zx * side + 4, sy + zy * side + 3, 'place: ' + tag, '#B26B00'))
        cx, cy, cw, ch_ = card
        parts.append(box(cx, cy, cw, ch_, 'background:#FFFFFF;border:4px solid #FFC83D;border-radius:16px;box-sizing:border-box',
                         '<img src="%s" style="width:%dpx;height:%dpx">' % (uri(os.path.join(PICS, 'chair.svg')), cw - 8, ch_ - 8)))
        parts.append(label(cx, cy + ch_ + 2, 'close-up card %dx%d at %d,%d' % (cw, ch_, cx, cy)))
        boards.append((parts, B['W'], B['H']))
    page(boards[:2], os.path.join(HERE, 'closeup_card_phones.png'), 852 + 667 + 60)
    page(boards[2:], os.path.join(HERE, 'closeup_card_tablets.png'), 1180 + 820 + 60)


# ---- QA-L4-8: the question picture --------------------------------------------------------------------------------

def question():
    boards = []
    for b in ('phone', 'phoneSE'):
        B = BOARDS[b]
        q = SPEC['question'][b]
        for rtl in (False, True):
            parts = frame(b, 'QA-L4-8 story question, %s, %s' % (b, 'Hebrew (right to left)' if rtl else 'English'))
            x, y, w, h = q['stage']
            parts.append(box(x, y, w, h, 'border:2px dashed #8FBFE0;border-radius:12px'))
            ph = h - 12
            pw = round(ph * 16 / 9)
            parts.append(img(os.path.join(PICS, 'story-bounce-3.svg'), x + (w - pw) / 2, y + 6, pw, ph))
            parts.append(label(x + 4, y + h + 2, 'page %dx%d pt (16:9)' % (pw, ph)))
            opts = ['duck', 'cat', 'frog']
            if rtl:
                opts = opts[::-1]
            unit = 96 + q['gap_ts'] + 64
            for i, o in enumerate(opts):
                ox = q['x0'] + i * (unit + q['gap'])
                tile_x, spk_x = (ox + 64 + q['gap_ts'], ox) if rtl else (ox, ox + 96 + q['gap_ts'])
                parts.append(box(ox - 3, q['row_y'] - 3, unit + 6, 102, 'background:#ECE3FE;border-radius:26px'))
                parts.append(box(tile_x, q['row_y'], 96, 96, 'background:#FFFFFF;border:3px solid #DCD3EC;border-radius:18px;box-sizing:border-box',
                                 '<img src="%s" style="width:86px;height:86px;margin:2px">' % uri(os.path.join(PICS, o + '.svg'))))
                parts.append(box(spk_x, q['row_y'] + 16, 64, 64, 'background:#DEEBFC;border-radius:50%;border:2px solid #8FBFE0;box-sizing:border-box'))
                parts.append(label(spk_x + 14, q['row_y'] + 40, 'spk 64', '#1F5FB0'))
            parts.append(label(q['x0'], q['row_y'] + 100, 'tile 96 + %d + speaker 64, %d between options; row %d to %d' %
                               (q['gap_ts'], q['gap'], q['x0'], q['x0'] + 3 * unit + 2 * q['gap'])))
            boards.append((parts, B['W'], B['H']))
    page(boards, os.path.join(HERE, 'question_phones.png'), 852 + 40)


# ---- QA-L4-9: the drum --------------------------------------------------------------------------------------------

def drum():
    boards = []
    for b, B in BOARDS.items():
        d = SPEC['drum'][b]
        for rtl in (False, True):
            if b.startswith('tablet') and rtl:
                continue
            parts = frame(b, 'QA-L4-9 drum, %s, %s' % (b, 'Hebrew' if rtl else 'English'))
            X, Y, W, H = B['tall']
            parts.append(box(X, Y, W, H, 'border:2px dashed #8FBFE0;border-radius:12px'))

            def mx(x, w):
                return X + (W - x - w if rtl else x)

            px, py, ps = d['pic']
            parts.append(img(os.path.join(PICS, 'banana.svg'), mx(px, ps), Y + py, ps, ps))
            dx, dy, ds = d['drum']
            parts.append(img(os.path.join(PICS, 'drum.svg'), mx(dx, ds), Y + dy, ds, ds))
            parts.append(box(mx(dx, ds), Y + dy, ds, ds, 'border:2px solid #2F7FE0;border-radius:50%;box-sizing:border-box'))
            b0, b1 = d['band']
            band_x = mx(b0, b1 - b0)
            hy, hh = d['hands']
            parts.append(box(band_x, Y + hy, b1 - b0, hh, 'border:1px dotted #36A852'))
            for k in range(3):
                parts.append(box(band_x + (b1 - b0) / 2 - 57 + k * 38, Y + hy + 2, 30, hh - 4, 'background:#36A85299;border-radius:8px'))
            oy, os_, og = d['dots']
            parts.append(box(band_x, Y + oy, b1 - b0, os_, 'border:1px dotted #F59E1B'))
            n = 9
            start = band_x + (b1 - b0 - (n * os_ + (n - 1) * og)) / 2
            for k in range(n):
                parts.append(box(start + k * (os_ + og), Y + oy, os_, os_, 'background:#FFC83D;border-radius:50%'))
            cx, cy, cs = d['check']
            parts.append(box(mx(cx, cs), Y + cy, cs, cs, 'background:#FFFFFF;border:3px solid #2B2350;border-radius:50%;box-sizing:border-box'))
            parts.append(label(mx(cx, cs) + 6, Y + cy + cs / 2 - 6, 'done %d' % cs))
            parts.append(label(band_x, Y + oy + os_ + 2, 'hands and dots stay in this band; nine dots fit', '#B26B00'))
            boards.append((parts, B['W'], B['H']))
    page(boards[:4], os.path.join(HERE, 'drum_phones.png'), 852 + 40)
    page(boards[4:], os.path.join(HERE, 'drum_tablets.png'), 1180 + 820 + 60)


if __name__ == '__main__':
    body_map()
    closeup_slots()
    question()
    drum()
    print('mockups in', os.path.relpath(HERE, ROOT))
