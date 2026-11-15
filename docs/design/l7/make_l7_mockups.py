"""Mockups of docs/design/l7-meet-find.md (L7-4): the Meet screen on the four boards, and the Find wrong tap on the phone.
Each board is drawn at its real size in points with the app's own pictures and fonts, then shown at half size, by headless Chrome:

    python docs/design/l7/make_l7_mockups.py

writes docs/design/l7/meet_boards.png and docs/design/l7/find_wrong_tap.png.

The frame's fixed pieces (controls, bubble, guide, microphone) are those of app/lib/child/activity_shell.dart as measured for
docs/design/languages-l5/make_l5_ls01_mockups.py (BOARDS there); the Meet zones and sizes are this spec's. Red labels and dashed
zones are for the team, never in the app. Every Hebrew line and every target word is a sample (needs-editor; the teachers'
choice of words). Pictures: content/languages/pictures, content/languages/heb/pack/s1_p1.svg (story 1, page 1) and
design/assets/nitzi-*.svg, all drawn earlier from references. No new drawing is made here, so no new reference is cited.
"""
import html as htmlmod
import os
import pathlib
import subprocess
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..', '..'))
PICS = os.path.join(ROOT, 'content', 'languages', 'pictures')
HEBPACK = os.path.join(ROOT, 'content', 'languages', 'heb', 'pack')
CAST = os.path.join(ROOT, 'design', 'assets')
UI = os.path.join(ROOT, 'app', 'assets', 'art', 'ui')
FONTS = os.path.join(ROOT, 'app', 'assets', 'fonts')
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'
SCALE = 0.5


def uri(p):
    return pathlib.Path(p).as_uri()


FONT_CSS = """
@font-face{font-family:L;src:url('%s');font-weight:500}
@font-face{font-family:H;src:url('%s');font-weight:100 900}
""" % (uri(os.path.join(FONTS, 'NitznutzLetters-Medium.ttf')), uri(os.path.join(FONTS, 'Heebo-Variable.ttf')))

C = dict(cream='#FFF6E8', paper='#FFFFFF', ink='#2B2350', mist='#EDE6F7', hairline='#E6DDF0', lip='#DCD3EC', spark='#FFC83D',
         sparkDeep='#E0A21A', skyTint='#E3F4FC', sky='#8FD3F4', lilac='#B9A2F7', sea='#1A9E9A', seaDeep='#0F6E6A')

BOARDS = {
    'phone': dict(W=852, H=393, tablet=False, ctrl=64, home=(729, 12), bubble=(413, 104, 190, 132), font=26,
                  guide=(617, 80, 176), mic=(661, 260, 88)),
    'phoneSE': dict(W=667, H=375, tablet=False, ctrl=64, home=(587, 8), bubble=(300, 92, 176, 118), font=22,
                    guide=(490, 66, 150), mic=(521, 226, 88)),
    'tabletLandscape': dict(W=1180, H=820, tablet=True, ctrl=72, home=(1084, 24), bubble=(356, 112, 600, 112), font=28,
                            guide=(896, 150, 260), mic=(978, 672, 96)),
    'tabletPortrait': dict(W=820, H=1180, tablet=True, ctrl=72, home=(724, 32), bubble=(156, 152, 440, 208), font=28,
                           guide=(596, 112, 200), mic=(44, 172, 96)),
}
NAMES = {'phone': 'phone 852 x 393', 'phoneSE': 'phone SE 667 x 375', 'tabletLandscape': 'tablet landscape 1180 x 820',
         'tabletPortrait': 'tablet portrait 820 x 1180'}

# The Meet board of the spec (section 4.1): the stage S, the strip column, the picture area and the "I said it" box.
MEET = {
    'phone': dict(S=(24, 96, 377, 260), thumb={'A': 64, 'B': 56, 'C': 56}, sgap=12, tiles=(413, 252, 192), tile=(184, {'A': 96, 'B': 88, 'C': 80})),
    'phoneSE': dict(S=(24, 86, 264, 256), thumb={'A': 64, 'B': 56, 'C': 56}, sgap=8, tiles=(300, 238, 208), tile=(184, {'A': 96, 'B': 88, 'C': 80})),
    'tabletLandscape': dict(S=(288, 230, 584, 300), pad=16, thumb={'A': 88, 'B': 88, 'C': 88}, sgap=16, tiles=(194, 566, 772), tile=(200, {'A': 112, 'B': 104, 'C': 96})),
    'tabletPortrait': dict(S=(24, 372, 772, 420), pad=16, thumb={'A': 88, 'B': 88, 'C': 88}, sgap=16, tiles=(24, 816, 772), tile=(200, {'A': 112, 'B': 104, 'C': 96})),
}

SPEAKER = ('<svg viewBox="0 0 48 48" width="%d" height="%d"><path d="M8 18h8l10-8v28l-10-8H8z" fill="#2B2350" stroke="#2B2350" '
           'stroke-width="2" stroke-linejoin="round"/><path d="M31 17c3 3.5 3 10.5 0 14M36 12c6 6.5 6 17.5 0 24" fill="none" '
           'stroke="#2B2350" stroke-width="3.2" stroke-linecap="round"/></svg>')
# "I said it" glyph: a head in profile with two sound lines (Material record_voice_over in the app; drawn here only to show the place).
VOICE = ('<svg viewBox="0 0 48 48" width="%d" height="%d"><circle cx="18" cy="17" r="8" fill="#2B2350"/><path d="M4 42c0-8 6-13 14-13s14 5 14 13z" '
         'fill="#2B2350"/><path d="M33 9c3 3 3 9 0 12M38 5c5 5 5 15 0 20" fill="none" stroke="#2B2350" stroke-width="3.2" stroke-linecap="round"/></svg>')


def esc(t):
    return htmlmod.escape(t)


def box(x, y, w, h, style='', inner=''):
    return '<div style="position:absolute;left:%.1fpx;top:%.1fpx;width:%.1fpx;height:%.1fpx;box-sizing:border-box;%s">%s</div>' % (
        x, y, w, h, style, inner)


def img(path, x, y, w, h, extra=''):
    return '<img src="%s" style="position:absolute;left:%.1fpx;top:%.1fpx;width:%.1fpx;height:%.1fpx;object-fit:contain;%s">' % (
        uri(path), x, y, w, h, extra)


def label(x, y, text, color='#B23A3A', size=13, anchor='left'):
    tx = 'transform:translateX(-100%);' if anchor == 'right' else ''
    return '<div style="position:absolute;left:%.1fpx;top:%.1fpx;font:600 %dpx sans-serif;color:%s;white-space:nowrap;%s">%s</div>' % (
        x, y, size, color, tx, esc(text))


def he(text, size):
    return '<span dir="rtl" lang="he" style="font-family:H;font-weight:500;font-size:%dpx;line-height:1.7;color:#2B2350;white-space:normal">%s</span>' % (size, esc(text))


def chip(word, lang, size):
    return ('<div style="margin-top:6px;display:flex;justify-content:center"><span lang="%s" dir="ltr" style="unicode-bidi:isolate;'
            'font-family:L;font-weight:500;font-size:%dpx;line-height:1.3;color:#2B2350;background:#fff;border:2px solid %s;border-radius:999px;'
            'padding:0 14px">%s</span></div>') % (lang, size, C['hairline'], esc(word))


HELP = {'phone': ((59, 12), (147, 12)), 'phoneSE': ((16, 8), (96, 8)), 'tabletLandscape': ((24, 24), (112, 24)),
        'tabletPortrait': ((24, 32), (112, 32))}


def frame(b, title, pose='talk', bubble=None, chip_html='', speaker_bubble=False, mic=True, trail=(1, 4), help=False):
    """The lesson frame: home; the lamp and "show me" only on a scored item ([help]: a Find has them, a Meet screen never), the trail, the
    guide's bubble (text, or the speaker bubble when captions are hidden), the guide."""
    B = BOARDS[b]
    out = [box(0, 0, B['W'], B['H'], 'background:%s;border:1px solid #C9C3D9' % C['cream'])]
    s = B['ctrl']
    if help:
        for (hx, hy), icon in zip(HELP[b], ('eye.svg', 'hint.svg')):
            out.append(box(hx, hy, s, s, 'border-radius:50%%;background:#FFFFFF;box-shadow:0 6px 0 %s' % C['lip']))
            out.append(img(os.path.join(UI, icon), hx + s / 2 - 16, hy + s / 2 - 16, 32, 32))
    x, y = B['home']
    out.append(box(x, y, s, s, 'border-radius:50%%;background:#FFFFFF;box-shadow:0 6px 0 %s' % C['lip']))
    out.append(img(os.path.join(UI, 'home_palm.svg'), x + s / 2 - 16, y + s / 2 - 16, 32, 32))
    done, total = trail
    tw = 24 + total * 22
    tx = B['W'] / 2 - tw / 2
    ty = y + s / 2 - 18
    out.append(box(tx, ty, tw, 36, 'background:#fff;border-radius:18px;box-shadow:0 2px 6px rgba(43,35,80,.1)'))
    for i in range(total):
        cx = tx + tw - 12 - 20 - i * 22   # fills from the right: the screen is right to left
        if i < done:
            out.append(box(cx, ty + 8, 20, 20, 'border-radius:50%%;background:%s' % C['spark']))
        elif i == done:
            out.append(box(cx, ty + 8, 20, 20, 'border-radius:50%%;border:2.5px solid %s;background:#fff' % C['ink']))
        else:
            out.append(box(cx, ty + 8, 20, 20, 'border-radius:50%%;background:%s' % C['mist']))
    bx, by, bw, bh = B['bubble']
    if speaker_bubble:
        sz = 64 if not B['tablet'] else 72
        out.append(box(bx + bw - sz, by, sz, sz, 'background:#fff;border-radius:22px;box-shadow:0 6px 16px rgba(43,35,80,.14);display:flex;'
                       'align-items:center;justify-content:center', SPEAKER % (34, 34)))
    elif bubble:
        out.append(box(bx, by, bw, bh, 'overflow:visible;display:flex;justify-content:flex-end;align-items:flex-start',
                       '<div dir="rtl" style="max-width:100%%;background:#fff;border-radius:18px;padding:8px 16px;box-sizing:border-box;'
                       'box-shadow:0 6px 16px rgba(43,35,80,.14);text-align:right">%s%s</div>' % (he(bubble, B['font']), chip_html)))
    gx, gy, gs = B['guide']
    out.append(img(os.path.join(CAST, 'nitzi-%s.svg' % pose), gx, gy, gs, gs))
    if mic:
        mx, my, ms = B['mic']
        out.append(box(mx, my, ms, ms, 'border-radius:50%%;background:%s;box-shadow:0 6px 0 %s' % (C['sea'], C['seaDeep'])))
        out.append(img(os.path.join(UI, 'mic.svg'), mx + ms / 2 - 20, my + ms / 2 - 20, 40, 40))
    out.append(box(0, B['H'] - 24, B['W'], 24, 'background:repeating-linear-gradient(45deg,#EDE6F7 0 6px,#FFF6E8 6px 12px)'))
    out.append(label(8, B['H'] - 19, '%s  |  %s' % (NAMES[b], title), '#2B2350', 13))
    return out


def badge(cx, cy, d=40):
    """The speaking badge: the sound disc of SpeakerMark (sky tint, hairline rim, the speaker with its waves); not a button."""
    return box(cx - d / 2, cy - d / 2, d, d, 'border-radius:50%%;background:%s;border:2px solid %s;display:flex;align-items:center;'
               'justify-content:center;box-shadow:0 2px 6px rgba(43,35,80,.12)' % (C['skyTint'], C['hairline']), SPEAKER % (d * 0.6, d * 0.6))


def card(x, y, w, h, pic, speaking=False, focus=None):
    """The Meet picture card: paper, radius 28, a 2 pt lip-coloured rim, 12 pt inside; the picture fills it in its own aspect."""
    out = [box(x, y, w, h, 'background:#fff;border:2px solid %s;border-radius:28px;box-shadow:0 6px 0 %s,0 6px 16px rgba(43,35,80,.14)' % (C['lip'], C['lip']))]
    out.append(img(pic, x + 12, y + 12, w - 24, h - 24))
    if focus:
        fx, fy, fw, fh = focus
        iw, ih = w - 24, h - 24
        out.append(box(x + 12 + fx * iw, y + 12 + fy * ih, fw * iw, fh * ih, 'border:4px solid %s;border-radius:18px' % C['spark']))
    if speaking:
        out.append(badge(x + w - 10, y + 10))   # the top start corner (right, in the right-to-left interface)
    return out


def thumb(x, y, s, pic):
    return [box(x, y, s, s, 'background:#fff;border:2px solid %s;border-radius:16px;box-shadow:0 4px 0 %s' % (C['hairline'], C['lip'])),
            img(pic, x + 6, y + 6, s - 12, s - 12)]


def said_tile(b, look, cx=None):
    M = MEET[b]
    tx, ty, tw = M['tiles']
    w, hs = M['tile']
    h = hs[look]
    x = (cx - w / 2) if cx else tx + (tw - w) / 2
    y = ty + (6 if not BOARDS[b]['tablet'] else 0)
    size = 28 if not BOARDS[b]['tablet'] else 32
    inner = '<div style="display:flex;align-items:center;gap:8px;direction:rtl">%s%s</div>' % (VOICE % (32, 32), he('אָמַרְתִּי', size).replace('font-weight:500', 'font-weight:600'))
    return [box(x, y, w, h, 'background:#fff;border:4px solid %s;border-radius:28px;box-shadow:0 6px 0 %s,0 6px 16px rgba(43,35,80,.14);display:flex;'
                'align-items:center;justify-content:center' % (C['hairline'], C['lip']), inner),
            label(x, y + h + 10, 'I said it  %d x %d' % (w, h))]


def meet(b, look, pic, strip, wide=False, speaking=False, focus=None):
    """The Meet stage: the strip column at the end side (left), the picture card centred in the rest of S."""
    M = MEET[b]
    x, y, w, h = M['S']
    out = []
    if BOARDS[b]['tablet']:
        out.append(box(x, y, w, h, 'background:#fff;border-radius:36px;box-shadow:0 6px 0 %s,0 6px 16px rgba(43,35,80,.14)' % C['lip']))
        p = M['pad']
        x, y, w, h = x + p, y + p, w - 2 * p, h - 2 * p
    out.append(box(x, y, w, h, 'border:1.5px dashed rgba(178,58,58,0.5);border-radius:6px'))
    t = M['thumb'][look]
    g = M['sgap']
    n = len(strip)
    sh = n * t + (n - 1) * 12
    for i, s in enumerate(strip):
        out += thumb(x, y + (h - sh) / 2 + i * (t + 12), t, s)
    ax, aw = x + t + g, w - t - g
    if wide:
        cw = min(aw, (h - 24) * 16 / 9 + 24)
        ch = (cw - 24) * 9 / 16 + 24
    else:
        cw = ch = min(aw, h, 420)
    cx, cy = ax + (aw - cw) / 2, y + (h - ch) / 2
    out += card(cx, cy, cw, ch, pic, speaking, focus)
    out.append(label(cx, cy - 16, 'picture card %d x %d' % (cw, ch)))
    out.append(label(x, y + h + 2, 'strip %d' % t))
    return out


def meet_sheet():
    P = lambda n: os.path.join(PICS, n + '.svg')
    boards = []
    # 1. Phone, look A (3-4), English: the second word of the set, its child's turn. Captions hidden: the speaker bubble.
    o = frame('phone', 'Meet, eng, look A, word 2 of 2, M5 your turn', pose='listen', speaker_bubble=True, trail=(1, 4))
    o[1:1] = meet('phone', 'A', P('pip-leave'), [P('pip-arrive')])
    o += said_tile('phone', 'A')
    boards.append((o, 852, 393))
    # 2. Phone SE, look B (5-6), Russian: the third word, M2 the Hebrew meaning, in the bubble because captions show; no chip (letters closed).
    o = frame('phoneSE', 'Meet, rus, look B, word 3 of 3, M2 meaning', pose='talk', bubble='בְּעִבְרִית: אַבָּא.', trail=(1, 5))
    o[1:1] = meet('phoneSE', 'B', P('fam-father'), [P('fam-mother'), P('fam-grandmother')])
    boards.append((o, 667, 375))
    # 3. Tablet landscape, look B, Hebrew course: the story picture with the part the word names, H2 the explanation.
    o = frame('tabletLandscape', 'Meet page, heb, look B, H2 explanation (story 1, page 1)', pose='talk',
              bubble='שִׂיחַ הוּא כְּמוֹ עֵץ קָטָן וְנָמוּךְ.', trail=(1, 4))
    o[1:1] = meet('tabletLandscape', 'B', os.path.join(HEBPACK, 's1_p1.svg'), [P('ball')], wide=True, focus=(0.67, 0.5, 0.32, 0.38))
    boards.append((o, 1180, 820))
    # 4. Tablet portrait, look C (7-8), English with the letters gate open: M4 "let's say it together" + the word, the chip under the line.
    o = frame('tabletPortrait', 'Meet, eng, look C, letters open, M4 together', pose='talk', bubble='בּוֹאוּ נֹאמַר יַחַד.',
              chip_html=chip('goodbye', 'en', 31), trail=(1, 4))
    o[1:1] = meet('tabletPortrait', 'C', P('pip-leave'), [P('pip-arrive')], speaking=True)
    o += said_tile('tabletPortrait', 'C')
    boards.append((o, 820, 1180))
    return boards


def find_stage(b, pics, states, lilac_fade=None):
    """Find on a phone: the pictures stand on the stage, which takes the whole left column (spec section 6.4): x 24 to 401, y 96 to 349
    on the phone; x 24 to 288, y 86 to 331 on the SE. English runs left to right (the course's direction)."""
    S = {'phone': (24, 96, 377, 253), 'phoneSE': (24, 86, 264, 245)}[b]
    x, y, w, h = S
    out = [box(x, y, w, h, 'background:linear-gradient(#E3F4FC,#F3FAFD);border-radius:24px'),
           box(x, y, w, h, 'border:1.5px dashed rgba(178,58,58,0.5);border-radius:6px')]
    n = len(pics)
    gap = 32 if n == 2 else 24
    side = min((w - 12 - gap * (n - 1)) / n, h - 40, 170)
    total = n * side + (n - 1) * gap
    for i, (pic, st) in enumerate(zip(pics, states)):
        px = x + (w - total) / 2 + i * (side + gap)
        py = y + (h - side) / 2
        if st == 'speaking':
            out.append(box(px - 6, py - 6 - 6, side + 12, side + 12, 'border-radius:50%%;background:%s;border:5px solid %s' % (C['mist'], C['ink'])))
            out.append(img(pic, px + 6, py, side - 12, side - 12, 'transform:scale(1.04)'))
            out.append(badge(px + side - 2, py - 2, 40))
            continue
        if st == 'settle':
            a = lilac_fade or 1
            out.append(box(px - 6, py - 6, side + 12, side + 12, 'border-radius:50%%;background:rgba(185,162,247,%.2f);border:5px solid rgba(185,162,247,%.2f)' % (0.22 * a, a)))
        if st == 'right':
            out.append(box(px - 6, py - 6 - 6, side + 12, side + 12, 'border-radius:50%%;background:rgba(255,200,61,0.22);border:5px solid %s' % C['spark']))
            out.append(img(pic, px + 6, py, side - 12, side - 12))
            out.append(badge(px + side - 2, py - 2, 40))
            continue
        out.append(img(pic, px + 6, py + 6, side - 12, side - 12))
    out.append(label(x + 4, y + h + 3, 'stage %d,%d %dx%d, pictures %d' % (x, y, w, h, side)))
    return out


def find_sheet():
    P = lambda n: os.path.join(PICS, n + '.svg')
    two = [P('pip-arrive'), P('pip-leave')]
    q = 'הַקְשִׁיבוּ וְגַעוּ בַּתְּמוּנָה.'
    boards = []
    o = frame('phone', 'Find, 2 choices: 1 asked ("hello")', pose='listen', bubble=q, mic=False, trail=(2, 6), help=True)
    o[1:1] = find_stage('phone', two, ['idle', 'idle'])
    boards.append((o, 852, 393))
    o = frame('phone', '2 wrong tap: the picture says "goodbye" (speaking)', pose='listen', bubble=q, mic=False, trail=(2, 6), help=True)
    o[1:1] = find_stage('phone', two, ['idle', 'speaking'])
    boards.append((o, 852, 393))
    o = frame('phone', '3 settle and ask: "and where is ... hello?"', pose='talk', bubble='וְאֵיפֹה...?', mic=False, trail=(2, 6), help=True)
    o[1:1] = find_stage('phone', two, ['idle', 'settle'], lilac_fade=0.6)
    boards.append((o, 852, 393))
    o = frame('phone', '4 right: it says "hello", gold, the praise', pose='celebrate', bubble='יֹפִי!', mic=False, trail=(2, 6), help=True)
    o[1:1] = find_stage('phone', two, ['right', 'idle'])
    boards.append((o, 852, 393))
    three = [P('mika-arrive'), P('mika-leave'), P('pip-happy')]
    o = frame('phone', '3 choices (lesson 2): wrong tap, speaking', pose='listen', bubble=q, mic=False, trail=(3, 7), help=True)
    o[1:1] = find_stage('phone', three, ['idle', 'speaking', 'idle'])
    boards.append((o, 852, 393))
    o = frame('phoneSE', 'SE, 2 choices: wrong tap, speaking', pose='listen', bubble=q, mic=False, trail=(2, 6), help=True)
    o[1:1] = find_stage('phoneSE', two, ['speaking', 'idle'])
    boards.append((o, 667, 375))
    return boards


def page(boards, out_png, per_row):
    tmp = tempfile.mkdtemp(prefix='l7_')
    rows, cur = [], []
    for bd in boards:
        cur.append(bd)
        if len(cur) == per_row:
            rows.append(cur)
            cur = []
    if cur:
        rows.append(cur)
    body = ''
    width = 0
    height = 0
    for r in rows:
        rw = sum(int(w * SCALE) + 16 for _, w, _ in r) + 16
        rh = max(int(h * SCALE) for _, _, h in r) + 16
        width = max(width, rw)
        height += rh
        body += '<div style="white-space:nowrap;padding:8px 0 0 8px">' + ''.join(
            '<div style="display:inline-block;vertical-align:top;margin:0 8px 8px 0;width:%dpx;height:%dpx;overflow:hidden">'
            '<div style="position:relative;width:%dpx;height:%dpx;transform:scale(%s);transform-origin:0 0">%s</div></div>' % (
                int(w * SCALE), int(h * SCALE), w, h, SCALE, ''.join(parts)) for parts, w, h in r) + '</div>'
    doc = '<html><head><meta charset="utf-8"><style>%s</style></head><body style="margin:0;background:#fff">%s</body></html>' % (FONT_CSS, body)
    path = os.path.join(tmp, 'p.html')
    with open(path, 'w', encoding='utf-8') as fh:
        fh.write(doc)
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1', '--allow-file-access-from-files',
                    '--virtual-time-budget=8000', '--screenshot=' + out_png, '--window-size=%d,%d' % (width + 8, height + 8), uri(path)],
                   check=True, capture_output=True)
    print(out_png)


if __name__ == '__main__':
    page(meet_sheet()[:2], os.path.join(HERE, 'meet_phones.png'), 2)
    page(meet_sheet()[2:], os.path.join(HERE, 'meet_tablets.png'), 2)
    page(find_sheet(), os.path.join(HERE, 'find_wrong_tap.png'), 3)
