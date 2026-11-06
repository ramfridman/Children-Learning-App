"""Mockups of docs/design/languages-l5-ls01.md (L5-1, the rest of LS01): each board drawn at its real size in points, with the
app's own pictures, the real fonts (Heebo for the interface and the Hebrew course, Nitznutz Letters for English and Russian lesson
text), rendered by headless Chrome into docs/design/languages-l5/*.png.

    python docs/design/languages-l5/make_l5_ls01_mockups.py

How it works: one Chrome pass measures every text at 100 px in its font and weight; the layout below then places tiles, bins,
gaps and lines with those widths and the spec's rules (zones per board, Band B sizes, equal tile widths, one line per tile,
wrapping only at spaces), and prints the fit table of section 4 of the spec; a second Chrome pass draws each sheet, and a check
in the page marks in red anything that overflows its box (no mockup here has a red mark).

The frame's fixed pieces are those of app/lib/child/activity_shell.dart (ActivitySpec); the zones and sizes are the spec's.
Labels on the mockups (zone names, sizes, dotted hit areas) are for the team, never in the app. Every Hebrew line and every
target word here is a sample only (needs-editor, and the teachers' choice of words); the layout is what is specified.
Pictures: content/languages/pictures (story pages, place-, act- and object pictures, all drawn earlier from references) and
design/assets/nitzi-idle.svg. No new drawing is made by this script, so it cites no new reference.
"""
import html as htmlmod
import json
import os
import pathlib
import re
import subprocess
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..', '..'))
PICS = os.path.join(ROOT, 'content', 'languages', 'pictures')
CAST = os.path.join(ROOT, 'design', 'assets')
UI = os.path.join(ROOT, 'app', 'assets', 'art', 'ui')
FONTS = os.path.join(ROOT, 'app', 'assets', 'fonts')
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'


def uri(p):
    return pathlib.Path(p).as_uri()


FONT_CSS = """
@font-face{font-family:L;src:url('%s');font-weight:500}
@font-face{font-family:L;src:url('%s');font-weight:700}
@font-face{font-family:H;src:url('%s');font-weight:100 900}
""" % (uri(os.path.join(FONTS, 'NitznutzLetters-Medium.ttf')), uri(os.path.join(FONTS, 'NitznutzLetters-Bold.ttf')),
       uri(os.path.join(FONTS, 'Heebo-Variable.ttf')))

# ---- colours (design/tokens.json) -----------------------------------------------------------------------------------
C = dict(cream='#FFF6E8', paper='#FFFFFF', ink='#2B2350', inkSoft='#5A5378', mist='#EDE6F7', hairline='#E6DDF0',
         lip='#DCD3EC', sparkTint='#FFF1C4', spark='#FFC83D', skyTint='#E3F4FC', sky='#8FD3F4', skyDeep='#5BB6E0',
         lilac='#B9A2F7', lilacDeep='#8A6FE0', sea='#1A9E9A', ring='#2B2350', logicTint='#ECE3FE')

# ---- the boards: frame (ActivitySpec) and the zones of this spec ------------------------------------------------------
BOARDS = {
    'phone': dict(W=852, H=393, tablet=False, ctrl=64, home=(852 - 59 - 64, 12), eye=(59, 12), hint=(147, 12),
                  bubble=(413, 104, 190, 132), font=26, guide=(617, 80, 176), mic=(661, 260, 88),
                  S=(24, 96, 377, 148), A=(24, 252, 581, 117), row=264),
    'phoneSE': dict(W=667, H=375, tablet=False, ctrl=64, home=(667 - 16 - 64, 8), eye=(16, 8), hint=(96, 8),
                    bubble=(300, 92, 176, 118), font=22, guide=(490, 66, 150), mic=(521, 226, 88),
                    S=(24, 86, 262, 144), A=(24, 238, 484, 113), row=250),
    'tabletLandscape': dict(W=1180, H=820, tablet=True, ctrl=72, home=(1180 - 24 - 72, 24), eye=(24, 24), hint=(112, 24),
                            bubble=(356, 112, 600, 112), font=28, guide=(896, 150, 260), mic=(978, 672, 96),
                            S=(288, 230, 584, 300), A=(194, 554, 772, 242), Awide=(24, 554, 942, 242), row=566),
    'tabletPortrait': dict(W=820, H=1180, tablet=True, ctrl=72, home=(820 - 24 - 72, 32), eye=(24, 32), hint=(112, 32),
                           bubble=(156, 152, 440, 208), font=28, guide=(596, 112, 200), mic=(44, 172, 96),
                           S=(24, 372, 772, 300), A=(24, 684, 772, 472), row=696),
}
NAMES = {'phone': 'phone 852 x 393', 'phoneSE': 'phone SE 667 x 375', 'tabletLandscape': 'tablet landscape 1180 x 820',
         'tabletPortrait': 'tablet portrait 820 x 1180'}

# ---- sizes per presentation band (spec section 3); phones share one set, tablets another ------------------------------
SIZES = {
    'B': {False: dict(tile=88, gapSq=24, gapWide=16, pad=14, slopV=12, letter=48, word=dict(he=34, t=38), line=dict(he=30, t=34),
                      stem=dict(he=42, t=48), chip=dict(he=26, t=28), chipH=44, sign=58, picMax=88),
          True: dict(tile=104, gapSq=24, gapWide=24, pad=16, slopV=12, letter=64, word=dict(he=40, t=44), line=dict(he=36, t=40),
                     stem=dict(he=50, t=56), chip=dict(he=32, t=36), chipH=56, sign=84, picMax=120)},
    'A': {False: dict(tile=96, gapSq=24, gapWide=24, pad=14, slopV=12, letter=56, word=dict(he=40, t=44), line=dict(he=34, t=38),
                      stem=dict(he=48, t=54), chip=dict(he=26, t=28), chipH=48, sign=64, picMax=96),
          True: dict(tile=112, gapSq=32, gapWide=32, pad=16, slopV=12, letter=72, word=dict(he=48, t=54), line=dict(he=40, t=44),
                     stem=dict(he=56, t=62), chip=dict(he=32, t=36), chipH=56, sign=84, picMax=128)},
    'C': {False: dict(tile=80, gapSq=24, gapWide=12, pad=12, slopV=12, letter=40, word=dict(he=30, t=34), line=dict(he=26, t=30),
                      stem=dict(he=38, t=42), chip=dict(he=24, t=26), chipH=44, sign=60, picMax=80),
          True: dict(tile=96, gapSq=16, gapWide=16, pad=14, slopV=12, letter=56, word=dict(he=36, t=40), line=dict(he=32, t=36),
                     stem=dict(he=46, t=50), chip=dict(he=28, t=32), chipH=52, sign=76, picMax=112)},
}


def fam(course):
    return 'H' if course == 'heb' else 'L'


def lh(course):
    return 1.7 if course == 'heb' else 1.3


def kind(course):
    return 'he' if course == 'heb' else 't'


def rtl(course):
    return course == 'heb'


# ---- measuring ---------------------------------------------------------------------------------------------------------
_EM = {}


def measure(items):
    """items: set of (family, weight, text). Fills _EM with widths in em, measured by Chrome in the real font files."""
    todo = [i for i in items if i not in _EM]
    if not todo:
        return
    tmp = tempfile.mkdtemp(prefix='l5m_')
    page = os.path.join(tmp, 'm.html')
    data = json.dumps(todo, ensure_ascii=False)
    with open(page, 'w', encoding='utf-8') as fh:
        fh.write('<html><head><meta charset="utf-8"><style>%s span{white-space:nowrap}</style></head><body><div id="o"></div><script>'
                 'const T=%s;for(const w of [500,700])for(const f of ["L","H"])document.fonts.load(w+" 40px "+f);'
                 'document.fonts.ready.then(()=>{const r=[];for(const [f,wt,t] of T){const s=document.createElement("span");'
                 's.style.font=wt+" 100px "+f;s.textContent=t;document.body.appendChild(s);r.push(s.getBoundingClientRect().width/100);s.remove();}'
                 'document.getElementById("o").textContent=JSON.stringify(r);});</script></body></html>' % (FONT_CSS, data))
    out = subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--allow-file-access-from-files', '--virtual-time-budget=8000',
                          '--dump-dom', uri(page)], capture_output=True, check=True).stdout.decode('utf-8')
    vals = json.loads(htmlmod.unescape(re.search(r'<div id="o">(.*?)</div>', out, re.S).group(1)))
    for i, v in zip(todo, vals):
        _EM[i] = v


def width(text, course, size, bold=False):
    return _EM[(fam(course), 700 if bold else 500, text)] * size


# ---- drawing primitives -------------------------------------------------------------------------------------------------
def esc(t):
    return htmlmod.escape(t)


def box(x, y, w, h, style='', inner='', cls=''):
    return '<div class="%s" style="position:absolute;left:%.1fpx;top:%.1fpx;width:%.1fpx;height:%.1fpx;box-sizing:border-box;%s">%s</div>' % (
        cls, x, y, w, h, style, inner)


def img(path, x, y, w, h, extra=''):
    return '<img src="%s" style="position:absolute;left:%.1fpx;top:%.1fpx;width:%.1fpx;height:%.1fpx;object-fit:contain;%s">' % (
        uri(path), x, y, w, h, extra)


def label(x, y, text, color='#B23A3A', size=11, anchor='left'):
    tx = 'transform:translateX(-100%);' if anchor == 'right' else ('transform:translateX(-50%);' if anchor == 'mid' else '')
    return '<div style="position:absolute;left:%.1fpx;top:%.1fpx;font:600 %dpx sans-serif;color:%s;white-space:nowrap;%s">%s</div>' % (
        x, y, size, color, tx, esc(text))


def text_span(text, course, size, bold=False, color=None, lineh=None):
    d = 'rtl' if rtl(course) else 'ltr'
    lang = {'heb': 'he', 'eng': 'en', 'rus': 'ru'}[course]
    return '<span class="fit" lang="%s" dir="%s" style="font-family:%s;font-weight:%d;font-size:%dpx;line-height:%s;white-space:nowrap;color:%s;unicode-bidi:isolate">%s</span>' % (
        lang, d, fam(course), 700 if bold else 500, size, lineh or lh(course), color or C['ink'], esc(text))


def ui_text(text, size, color=None):
    return '<span dir="rtl" lang="he" style="font-family:H;font-weight:500;font-size:%dpx;line-height:1.7;color:%s">%s</span>' % (
        size, color or C['ink'], esc(text))


CHECK_SVG = '<svg viewBox="0 0 24 24" width="20" height="20"><path d="M5 12.5l4.2 4.2L19 7" fill="none" stroke="#2B2350" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>'
SPEAKER_SVG = ('<svg viewBox="0 0 48 48" width="%d" height="%d"><path d="M8 18h8l10-8v28l-10-8H8z" fill="#2B2350" stroke="#2B2350" stroke-width="2" stroke-linejoin="round"/>'
               '%s</svg>')
WAVES = '<path d="M31 17c3 3.5 3 10.5 0 14M36 12c6 6.5 6 17.5 0 24" fill="none" stroke="#2B2350" stroke-width="3.2" stroke-linecap="round"/>'


def tile(x, y, w, h, inner, state='idle', hit=None, radius=28, fill=None):
    """An answer tile (AnswerTile): paper, a 4 pt hairline border, the clay lip; the states of spec section 6."""
    out = []
    if hit:
        hx, hy, hw, hh = hit
        out.append(box(hx, hy, hw, hh, 'border:1px dotted rgba(108,64,208,0.55);border-radius:%dpx' % (radius + 8)))
    dy = -6 if state == 'chosen' else 0
    border = {'idle': C['hairline'], 'chosen': C['hairline'], 'correct': C['spark'], 'notyet': C['lilac'], 'set': C['lilacDeep'],
              'lit': C['hairline'], 'dim': C['hairline']}[state]
    bg = fill or (C['sparkTint'] if state == 'correct' else C['paper'])
    op = 'opacity:0.35;' if state == 'dim' else ''
    if state == 'chosen':
        out.append(box(x - 7, y - 7 + dy, w + 14, h + 14, 'border:4px solid %s;border-radius:%dpx' % (C['ring'], radius + 7)))
    if state == 'notyet':
        # the wobble, drawn as two short motion arcs at the sides (in the app it is a 2-swing shake of 6 pt, reduce-motion: none)
        out.append(box(x - 14, y + h / 2 - 14, 8, 28, 'border-left:3px solid %s;border-radius:50%%' % C['lilac']))
        out.append(box(x + w + 6, y + h / 2 - 14, 8, 28, 'border-right:3px solid %s;border-radius:50%%' % C['lilac']))
    out.append(box(x, y + dy, w, h, 'background:%s;border:4px solid %s;border-radius:%dpx;box-shadow:0 6px 0 %s,0 6px 16px rgba(43,35,80,0.14);'
                   'display:flex;align-items:center;justify-content:center;overflow:hidden;%s' % (bg, border, radius, C['lip'], op), inner, cls='tilebox'))
    if state == 'lit':
        out.append(box(x - 4, y - 4, w + 8, h + 8, 'border:8px solid rgba(143,211,244,0.45);border-radius:%dpx' % (radius + 4)))
        out.append(box(x - 1, y - 1, w + 2, h + 2, 'border:3px solid %s;border-radius:%dpx' % (C['sky'], radius + 1)))
    if state == 'correct':
        out.append(box(x + w - 22, y - 6 + dy, 28, 28, 'background:%s;border-radius:50%%;display:flex;align-items:center;justify-content:center' % C['spark'], CHECK_SVG))
    return out


def frame(b, bubble_text, title, band='B'):
    B = BOARDS[b]
    out = [box(0, 0, B['W'], B['H'], 'background:%s;border:1px solid #C9C3D9' % C['cream'])]
    icons = {'home': 'home_palm.svg', 'eye': 'eye.svg', 'hint': 'hint.svg'}
    for k in ('home', 'eye', 'hint'):
        x, y = B[k]
        s = B['ctrl']
        out.append(box(x, y, s, s, 'border-radius:50%%;background:#FFFFFF;box-shadow:0 6px 0 %s' % C['lip']))
        out.append(img(os.path.join(UI, icons[k]), x + s / 2 - 16, y + s / 2 - 16, 32, 32))
    # the progress trail, centred (a pill with sockets, as board 13)
    tw = 150
    tx = B['W'] / 2 - tw / 2
    ty = B['eye'][1] + B['ctrl'] / 2 - 18
    out.append(box(tx, ty, tw, 36, 'background:#fff;border-radius:18px;box-shadow:0 2px 6px rgba(43,35,80,.1)'))
    for i in range(6):
        cx = tx + tw - 20 - 22 - i * 22  # fills from the start side (the right): the screen is right to left
        col = C['spark'] if i < 2 else C['mist']
        out.append(box(cx + 1, ty + 8, 20, 20, 'border-radius:50%%;background:%s' % col))
    bx, by, bw, bh = B['bubble']
    # the guide's bubble: its real text, in Heebo at the board's bubble size
    out.append(box(bx, by, bw, bh, 'border:1px dashed rgba(108,64,208,0.4);border-radius:18px'))
    out.append(box(bx, by, bw, 0, 'overflow:visible',
                   '<div dir="rtl" style="position:absolute;right:0;top:0;max-width:%dpx;background:#fff;border-radius:18px;padding:8px 16px;box-shadow:0 6px 16px rgba(43,35,80,.14);text-align:right">%s</div>' % (
                       bw, ui_text(bubble_text, B['font']))))
    gx, gy, gs = B['guide']
    out.append(img(os.path.join(CAST, 'nitzi-idle.svg'), gx, gy, gs, gs))
    mx, my, ms = B['mic']
    out.append(box(mx, my, ms, ms, 'border-radius:50%%;background:%s;box-shadow:0 6px 0 #0F6E6A' % C['sea']))
    out.append(img(os.path.join(UI, 'mic.svg'), mx + ms / 2 - 20, my + ms / 2 - 20, 40, 40))
    out.append(box(0, B['H'] - 24, B['W'], 24, 'background:repeating-linear-gradient(45deg,#EDE6F7 0 6px,#FFF6E8 6px 12px)'))
    out.append(label(8, B['H'] - 18, '%s  |  %s  |  Band %s' % (NAMES[b], title, band), '#2B2350', 12))
    return out


ROW_A = {'phone': 258, 'phoneSE': 240, 'tabletLandscape': 566, 'tabletPortrait': 696}   # Band A rows (96 or 112 high)


def row_top(b, band):
    """Where a row of tiles is drawn: Band B and C at the board's row; Band A (taller tiles) a little higher on the phones."""
    return ROW_A[b] if band == 'A' else BOARDS[b]['row']


def foot(b, text):
    """A size note for the team, in the board's bottom band at the right (the frame's title is at the left)."""
    B = BOARDS[b]
    return label(B['W'] - 8, B['H'] - 18, text, '#B23A3A', 11, 'right')


def zones(b, which=('S', 'A')):
    B = BOARDS[b]
    out = []
    for z in which:
        x, y, w, h = B[z]
        out.append(box(x, y, w, h, 'border:1.5px dashed rgba(178,58,58,0.55);border-radius:6px'))
        out.append(label(x + 4, y + h - 15 if z != 'S' else y - 14, '%s %d,%d %dx%d' % ({'S': 'stage', 'A': 'answers', 'Awide': 'answers (wide)'}[z], x, y, w, h)))
    return out


def stage_bg(b):
    x, y, w, h = BOARDS[b]['S']
    if BOARDS[b]['tablet']:
        return [box(x, y, w, h, 'background:#fff;border-radius:36px;box-shadow:0 6px 0 %s,0 6px 16px rgba(43,35,80,.14)' % C['lip']),
                box(x + 16, y + 16, w - 32, h - 32, 'background:linear-gradient(#E3F4FC,#F3FAFD);border-radius:24px')]
    return [box(x, y, w, h, 'background:linear-gradient(#E3F4FC,#F3FAFD);border-radius:24px')]


def stage_inner(b):
    x, y, w, h = BOARDS[b]['S']
    p = 16 if BOARDS[b]['tablet'] else 6
    return x + p, y + p, w - 2 * p, h - 2 * p


# ---- layout rules (spec section 4) --------------------------------------------------------------------------------------
def row_positions(widths, zone_x, zone_w, gap, course):
    """Centre a row of tiles in a zone with the given gap; the first item at the course's start side."""
    total = sum(widths) + gap * (len(widths) - 1)
    x = zone_x + (zone_w - total) / 2
    xs = []
    for w in widths:
        xs.append(x)
        x += w + gap
    if rtl(course):
        # the first item at the right: mirror the order of the positions, keep the widths with their items
        xs2 = []
        x = zone_x + (zone_w + total) / 2
        for w in widths:
            x -= w
            xs2.append(x)
            x -= gap
        xs = xs2
    return xs, total


def word_tile_width(texts, course, S, n, zone_w, letter=False):
    """Equal width for a row: the widest text plus padding, at least a square tile; with the cap the zone allows."""
    size = S['letter'] if letter else S['word'][kind(course)]
    need = max(width(t, course, size, bold=letter) for t in texts) + 2 * S['pad']
    w = max(S['tile'], need)
    gap = S['gapSq'] if w < S['tile'] + 24 else S['gapWide']
    cap = zone_w / n - gap
    return w, gap, cap, size


def options_row(b, course, texts, states, band='B', letter=False, zone='A', top=None, faces=None):
    B = BOARDS[b]
    S = SIZES[band][B['tablet']]
    zx, zy, zw, zh = B[zone]
    n = len(texts)
    w, gap, cap, size = word_tile_width([t for t in texts if t], course, S, n, zw, letter)
    fits = w <= cap + 0.01
    xs, total = row_positions([w] * n, zx, zw, gap, course)
    y = top if top is not None else B['row']
    out = []
    for i, (t, x) in enumerate(zip(texts, xs)):
        inner = faces[i] if faces else (sign_face(t, course, S) if letter else text_span(t, course, size))
        out += tile(x, y, w, S['tile'], inner, states[i], hit=(x - gap / 2, y - S['slopV'], w + gap, S['tile'] + 2 * S['slopV']))
    out.append(foot(b, 'tile %dx%d, gap %d, text %d pt%s' % (round(w), S['tile'], gap, size, '' if fits else '  DOES NOT FIT')))
    return out, xs, w, y, fits


# ---- the scenes ---------------------------------------------------------------------------------------------------------
SORT = {
    'eng': dict(bubble='לְאֵיזֶה סַל?', signs=['s', 't'], cards=['sat', 'sit', 'sip', 'tap', 'tin', 'tip'], sorted={0: 0},
                chosen=3),
    'heb': dict(bubble='לְאֵיזֶה סַל?', signs=['ב', 'מ'], cards=['בַּיִת', 'מַיִם', 'בָּנָנָה', 'מָרָק', 'בַּלּוֹן', 'מַפָּה'], sorted={0: 0},
                chosen=1),
}
CLOZE = {
    'eng': dict(bubble='אֵיזוֹ מִלָּה חֲסֵרָה?', before='The dog is', after='the chair.', options=['under', 'on', 'in'],
                pic='place-dog-on-chair.svg'),
    'heb': dict(bubble='אֵיזוֹ מִלָּה חֲסֵרָה?', before='הַכֶּלֶב', after='עַל הַכִּסֵּא.', options=['שׂוֹחֶה', 'יוֹשֵׁב', 'עָף'],
                pic='place-dog-on-chair.svg'),
}
SEQ = {
    'eng': dict(bubble='מָה קָרָה קֹדֶם?', pics=['story-bounce-3.svg', 'story-bounce-1.svg', 'story-bounce-4.svg', 'story-bounce-2.svg']),
    'heb': dict(bubble='מָה קָרָה קֹדֶם?', pics=['s1-p4.svg', 's1-p1.svg', 's1-p5.svg', 's1-p2.svg']),
}


def bins(b, course, signs, chips, band='B', lit=None, sign_pics=None):
    B = BOARDS[b]
    S = SIZES[band][B['tablet']]
    x0, y0, w0, h0 = stage_inner(b)
    n = len(signs)
    gap = 8 if not B['tablet'] else 16
    bw = (w0 - gap * (n - 1)) / n
    xs, _ = row_positions([bw] * n, x0, w0, gap, course)
    out = []
    for i, x in enumerate(xs):
        out.append(box(x, y0, bw, h0, 'background:rgba(255,255,255,0.88);border:3px solid %s;border-radius:22px' % C['hairline']))
        # the sign: a letter at the letter size, on a white pill across the bin's top
        sh = S['sign']
        sx, sy, sw = x + 6, y0 + 6, bw - 12
        inner = sign_face(signs[i], course, S) if not sign_pics else '<img src="%s" style="height:%dpx;width:%dpx;object-fit:cover">' % (uri(os.path.join(PICS, sign_pics[i])), sh - 6, bw - 24)
        out.append(box(sx, sy, sw, sh, 'background:#fff;border-radius:16px;box-shadow:0 3px 0 %s;display:flex;align-items:center;justify-content:center;overflow:hidden' % C['lip'], inner, cls='tilebox'))
        if lit == i:
            out.append(box(sx - 4, sy - 4, sw + 8, sh + 8, 'border:6px solid rgba(143,211,244,0.55);border-radius:20px'))
        # kept chips: the cards already sorted, at the band's caption size, in a row on the bin's floor
        cy = y0 + 6 + sh + 6
        ch = S['chipH']
        cx = x + 10 if not rtl(course) else x + bw - 10
        for t in chips.get(i, []):
            if t == '#sound':
                cw = ch
                inner = SPEAKER_SVG % (26, 26, WAVES)
            else:
                cw = width(t, course, S['chip'][kind(course)]) + 20
                inner = text_span(t, course, S['chip'][kind(course)])
            px = cx if not rtl(course) else cx - cw
            out.append(box(px, cy, cw, ch, 'background:%s;border-radius:14px;display:flex;align-items:center;justify-content:center;overflow:hidden' % C['mist'], inner, cls='tilebox'))
            cx = cx + cw + 6 if not rtl(course) else cx - cw - 6
        out.append(label(x + bw - 4, y0 + h0 + 2, 'bin %dx%d, sign %d' % (round(bw), round(h0), sh), '#B23A3A', 10, 'right'))
    return out


def has_marks(t):
    return any(0x0591 <= ord(ch) <= 0x05C7 or 0x0300 <= ord(ch) <= 0x036F for ch in t)


def sign_face(t, course, S):
    """A bin's sign: a letter with no marks at the letter size (line height 1.2: there are no marks to keep apart); a pointed
    letter, a unit or a short word at the word size with the course's own line height (1.7 for nikud)."""
    if len(t) <= 2 and not has_marks(t):
        return text_span(t, course, S['letter'], bold=True, lineh=1.2)
    return text_span(t, course, S['word'][kind(course)])


def scene_sort(b, course, band='B'):
    d = SORT[course]
    B = BOARDS[b]
    S = SIZES[band][B['tablet']]
    out = frame(b, d['bubble'], 'LS01 sort, text faces (%s)' % course)
    out += stage_bg(b)
    chips = {}
    for ci, bi in d['sorted'].items():
        chips.setdefault(bi, []).append(d['cards'][ci])
    out += bins(b, course, d['signs'], chips, band)
    # the tray: the cards not yet sorted, as many as the zone holds; the rest wait in a pile at the end side
    left = [c for i, c in enumerate(d['cards']) if i not in d['sorted']]
    zx, zy, zw, zh = B['A']
    w, gap, cap, size = word_tile_width(left, course, S, 1, zw)
    room = int((zw - 56 - gap) // (w + gap))  # 56: the pile's place
    shown = left[:room] if room < len(left) else left
    pile = len(left) - len(shown)
    states = ['chosen' if left.index(t) == d['chosen'] - 1 else 'idle' for t in shown]
    xs, total = row_positions([w] * len(shown), zx + (0 if not pile else (0 if rtl(course) else 0)), zw - (56 + gap if pile else 0), gap, course)
    if pile and rtl(course):
        xs = [x + 56 + gap for x in xs]
    y = B['row']
    for t, x, st in zip(shown, xs, states):
        out += tile(x, y, w, S['tile'], text_span(t, course, size), st, hit=(x - gap / 2, y - S['slopV'], w + gap, S['tile'] + 2 * S['slopV']))
    if pile:
        px = (zx + zw - 56) if not rtl(course) else zx
        for k in range(min(pile, 2)):
            out.append(box(px + 8 - k * 4, y + 14 + k * 5, 44, S['tile'] - 28, 'background:#fff;border:3px solid %s;border-radius:14px;box-shadow:0 3px 0 %s' % (C['hairline'], C['lip'])))
    out.append(foot(b, 'card %dx%d, gap %d, %d pt; shows %d%s' % (round(w), S['tile'], gap, size, len(shown), ', pile: %d waiting' % pile if pile else '')))
    out += zones(b)
    return out


def wrap_lines(tokens, course, size, colw, gapw):
    """Break a sentence only at spaces. tokens: list of str or ('gap', w). Returns lines of tokens."""
    space = width(' ', course, size) if (fam(course), 500, ' ') in _EM else size * 0.25
    lines, cur, curw = [], [], 0
    for t in tokens:
        tw = gapw if t == '#gap' else width(t, course, size)
        add = tw if not cur else curw + space + tw
        if cur and add > colw:
            lines.append(cur)
            cur, curw = [t], tw
        else:
            cur.append(t)
            curw = add
    if cur:
        lines.append(cur)
    return lines


def scene_cloze(b, course, band='B', filled=None):
    d = CLOZE[course]
    B = BOARDS[b]
    S = SIZES[band][B['tablet']]
    out = frame(b, d['bubble'], 'LS01 cloze (%s)' % course)
    out += stage_bg(b)
    x0, y0, w0, h0 = stage_inner(b)
    # the picture at the course's start side, as tall as the stage lets it be (a square picture), the sentence beside it
    ps = {'phone': 88, 'phoneSE': 64}.get(b, 200)
    px = x0 + 4 if not rtl(course) else x0 + w0 - 4 - ps
    out.append(box(px, y0 + (h0 - ps) / 2, ps, ps, 'background:#fff;border-radius:18px;border:3px solid %s' % C['hairline']))
    out.append(img(os.path.join(PICS, d['pic']), px + 4, y0 + (h0 - ps) / 2 + 4, ps - 8, ps - 8))
    colx = px + ps + 12 if not rtl(course) else x0 + 4
    colw = w0 - ps - 20
    size = S['line'][kind(course)]
    gapw = max(width(o, course, size) for o in d['options']) + 16
    gap_style = 'display:inline-flex;box-sizing:border-box;align-items:center;justify-content:center;width:%.0fpx;height:%.0fpx;vertical-align:middle;border-radius:12px;%s' % (
        gapw, size * 1.15, ('border:3px solid %s;background:#fff' % C['lilacDeep']) if filled else ('border:3px dashed %s;background:rgba(255,255,255,0.7)' % C['lilacDeep']))
    gap_html = '<span style="%s">%s</span>' % (gap_style, text_span(filled, course, size) if filled else '')
    sentence = esc(d['before']) + ' ' + gap_html + ' ' + esc(d['after'])
    lang = {'heb': 'he', 'eng': 'en'}[course]
    maxl = 2 if (rtl(course) and not B['tablet']) else 3
    out.append(box(colx, y0, colw, h0, 'display:flex;align-items:center', 
                   '<div class="fith" style="width:100%%;max-height:%dpx"><div lang="%s" dir="%s" style="font-family:%s;font-weight:500;font-size:%dpx;line-height:%s;color:%s;text-align:start;white-space:normal;overflow-wrap:normal;word-break:keep-all;hyphens:none" data-maxl="%d" data-lh="%.2f">%s</div></div>' % (
                       h0, lang, 'rtl' if rtl(course) else 'ltr', fam(course), size, lh(course), C['ink'], maxl, size * lh(course), sentence)))
    out.append(label(colx, y0 - 13 if not B['tablet'] else y0 + 2, 'sentence %d pt (at most %d lines here), column %d, gap %d' % (size, maxl, colw, gapw), '#B23A3A', 10))
    states = ['idle'] * 3
    if filled:
        states[d['options'].index(filled)] = 'dim'
    r, xs, w, y, fits = options_row(b, course, d['options'], states, band)
    out += r
    out += zones(b)
    return out


def scene_sequence(b, course, band='B', set_count=1):
    d = SEQ[course]
    B = BOARDS[b]
    S = SIZES[band][B['tablet']]
    out = frame(b, d['bubble'], 'LS01 sequence, the story line (%s)' % course)
    out += stage_bg(b)
    zone = 'Awide' if b == 'tabletLandscape' else 'A'
    zx, zy, zw, zh = B[zone]
    n = len(d['pics'])
    gap = S['gapWide']
    wmax = zw / n - gap
    h = min(S['picMax'], wmax * 9 / 16)
    w = h * 16 / 9
    xs, total = row_positions([w] * n, zx, zw, gap, course)
    y = B['row']
    # the order after the child's first tap: the picture of page 1 has gone to place 1 (it swapped with what was there)
    order = list(d['pics'])
    if set_count:
        first = 'story-bounce-1.svg' if course == 'eng' else 's1-p1.svg'
        i = order.index(first)
        order[0], order[i] = order[i], order[0]
    for k, (p, x) in enumerate(zip(order, xs)):
        st = 'set' if k < set_count else 'idle'
        out += tile(x, y, w, h, '<img src="%s" style="width:%.0fpx;height:%.0fpx;border-radius:14px;display:block">' % (uri(os.path.join(PICS, p)), w - 8, h - 8),
                    st, hit=(x - gap / 2, y - S['slopV'], w + gap, h + 2 * S['slopV'] + 22), radius=20)
    # the path: from the start flag at the course's start side to the end, a bead under each place
    py = y + h + 22
    x_start = xs[0] if not rtl(course) else xs[0] + w
    x_end = xs[-1] + w if not rtl(course) else xs[-1]
    lo, hi = min(x_start, x_end), max(x_start, x_end)
    lo, hi = (lo + 14, hi) if not rtl(course) else (lo, hi - 14)
    x_start = x_start + 14 if not rtl(course) else x_start - 14
    out.append(box(lo, py - 3, hi - lo, 6, 'background:%s;border-radius:3px' % C['mist']))
    for k, x in enumerate(xs):
        cx = x + w / 2
        if k < set_count:
            seg_lo, seg_hi = (min(x_start, cx), max(x_start, cx))
            out.append(box(seg_lo, py - 3, seg_hi - seg_lo, 6, 'background:%s;border-radius:3px' % C['lilacDeep']))
        filled = k < set_count
        out.append(box(cx - 8, py - 8, 16, 16, 'border-radius:50%%;background:%s;border:3px solid %s' % (C['lilacDeep'] if filled else '#fff', C['lilacDeep'] if filled else C['lip'])))
    # the start flag: a small pennant on a pole, pointing along the line (a shape, not a colour alone)
    # it stands on the path at the start end of the line, inside the row (never outside the zone)
    fx = x_start if not rtl(course) else x_start - 12
    flip = '' if not rtl(course) else 'transform:scaleX(-1);'
    out.append('<svg style="position:absolute;left:%.1fpx;top:%.1fpx;%s" width="12" height="20" viewBox="0 0 12 20"><rect x="0" y="1" width="3" height="19" rx="1.5" fill="#2B2350"/><path d="M3 1.5 L11.5 5.5 L3 9.5 Z" fill="#1A9E9A"/></svg>' % (fx, py - 18, flip))
    out.append(foot(b, 'picture %dx%d (16:9), gap %d, %d places' % (round(w), round(h), gap, n)))
    # the stage holds the story's replay and, at hint level 2, the "first, then, at the end" card (spec 7.8)
    x0, y0, w0, h0 = stage_inner(b)
    rs = 64 if not B['tablet'] else 80
    rx = x0 + (w0 - rs) / 2
    out.append(box(rx, y0 + (h0 - rs) / 2, rs, rs, 'border-radius:50%%;background:%s;border:2px solid %s;display:flex;align-items:center;justify-content:center' % (C['skyTint'], C['hairline']),
                   SPEAKER_SVG % (34, 34, WAVES)))
    out.append(label(rx + rs / 2, y0 + (h0 - rs) / 2 + rs + 4, 'the story again (replay)', '#B23A3A', 10, 'mid'))
    out += zones(b, ('S', zone))
    return out


# ---- more modes on the phone (spec section 7) ---------------------------------------------------------------------------
def scene_stem(b, course, band='B'):
    B = BOARDS[b]
    S = SIZES[band][B['tablet']]
    stem, pics, bub = (('I sit', ['act-run.svg', 'act-sit.svg', 'act-jump.svg'], 'קִרְאוּ וּבַחֲרוּ תְּמוּנָה.') if course == 'eng'
                       else ('דָּג', ['dog.svg', 'duck.svg', 'fish.svg'], 'קִרְאוּ וּבַחֲרוּ תְּמוּנָה.'))
    out = frame(b, bub, 'LS01 text stem, hint 1 "read it to me" (%s)' % course)
    out += stage_bg(b)
    x0, y0, w0, h0 = stage_inner(b)
    size = S['stem'][kind(course)]
    tw = width(stem, course, size) + 48
    th = size * lh(course) + 16
    sx = x0 + (w0 - tw) / 2
    sy = y0 + (h0 - th) / 2
    out.append(box(sx, sy, tw, th, 'background:#fff;border-radius:20px;border:3px solid %s;display:flex;align-items:center;justify-content:center' % C['hairline'], text_span(stem, course, size), cls='tilebox'))
    # hint level 1: the stem is read and each word lights in turn (sky glow on the page, a sky bar under the word being read)
    out.append(box(sx - 5, sy - 5, tw + 10, th + 10, 'border:7px solid rgba(143,211,244,0.5);border-radius:25px'))
    first = stem.split(' ')[0]
    fw = width(first, course, size)
    bx = sx + 24 if not rtl(course) else sx + tw - 24 - fw
    out.append(box(bx, sy + th - 14, fw, 6, 'background:%s;border-radius:3px' % C['skyDeep']))
    out.append(label(sx + tw / 2, sy - 16, 'stem %d pt; level 1 lights word by word' % size, '#B23A3A', 10, 'mid'))
    zx, zy, zw, zh = B['A']
    n = 3
    w = S['tile']
    xs, total = row_positions([w] * n, zx, zw, S['gapSq'], course)
    for x, p in zip(xs, pics):
        out += tile(x, B['row'], w, w, '<img src="%s" style="width:%dpx;height:%dpx">' % (uri(os.path.join(PICS, p)), w - 12, w - 12), 'idle',
                    hit=(x - 12, B['row'] - 12, w + 24, w + 24))
    out.append(foot(b, 'picture tile %d, gap %d' % (w, S['gapSq'])))
    out += zones(b)
    return out


def scene_tapall(b, band='A'):
    """HEB-A-10.3 (Band A presentation): tap all the letters. Five cards: two in the stage zone, three in the answer zone."""
    course = 'heb'
    B = BOARDS[b]
    S = SIZES[band][B['tablet']]
    out = frame(b, 'גְּעוּ בְּכׇל הָאוֹתִיּוֹת.', 'LS01 tap-all (heb A-10.3)', band)
    out += stage_bg(b)
    cards = ['א', '2', 'ס', '○', 'ל']
    picked = {0: 'chosen', 2: 'chosen'}
    t = S['tile']
    g = S['gapSq']
    zx, zy, zw, zh = B['A']
    capA = int(zw // (t + g))
    capS = int(stage_inner(b)[2] // (t + g))
    # the answer zone is filled first; what does not fit goes to the stage zone's end side, the "what to find" sign at its start
    nA = min(capA, len(cards))
    nS = len(cards) - nA
    rowS, rowA = cards[nA:], cards[:nA]
    x0, y0, w0, h0 = stage_inner(b)
    rs = 64
    sx = x0 + w0 - 8 - rs  # the start side of a Hebrew row is the right
    out.append(box(sx, y0 + (h0 - rs) / 2, rs, rs, 'border-radius:50%%;background:%s;border:2px solid %s;display:flex;align-items:center;justify-content:center' % (C['skyTint'], C['hairline']),
                   SPEAKER_SVG % (34, 34, WAVES)))
    out.append(label(sx + rs / 2, y0 + (h0 - rs) / 2 + rs + 2, 'what to find (again)', '#B23A3A', 10, 'mid'))
    xsS, _ = row_positions([t] * nS, x0, w0 - rs - 16, g, course)
    ys = y0 + (h0 - t) / 2
    for k, (c, x) in enumerate(zip(rowS, xsS)):
        i = nA + k
        face = sign_face(c, course, S) if c not in '2○' else ('<span style="font-family:H;font-weight:800;font-size:%dpx;line-height:1">%s</span>' % (S['letter'], c))
        out += tile(x, ys, t, t, face, picked.get(i, 'idle'), hit=(x - g / 2, ys - 12, t + g, t + 24))
        if picked.get(i) == 'chosen':
            out.append(box(x + t - 20, ys - 14, 26, 26, 'border-radius:50%%;background:%s;border:3px solid #fff' % C['ring']))
    xsA, _ = row_positions([t] * len(rowA), zx, zw, g, course)
    for j, (c, x) in enumerate(zip(rowA, xsA)):
        i = j
        face = sign_face(c, course, S) if c not in '2○' else ('<span style="font-family:H;font-weight:800;font-size:%dpx;line-height:1">%s</span>' % (S['letter'], c))
        out += tile(x, row_top(b, band), t, t, face, picked.get(i, 'idle'), hit=(x - g / 2, row_top(b, band) - 12, t + g, t + 24))
        if picked.get(i) == 'chosen':
            out.append(box(x + t - 20, row_top(b, band) - 14, 26, 26, 'border-radius:50%%;background:%s;border:3px solid #fff' % C['ring']))
    out.append(foot(b, 'tiles %d, gap %d: %d in the answers, %d in the stage zone' % (t, g, len(rowA), nS)))
    out += zones(b)
    return out


def scene_spot(b, band='B'):
    course = 'eng'
    B = BOARDS[b]
    S = SIZES[band][B['tablet']]
    out = frame(b, 'אֵיזוֹ אוֹת לֹא נְכוֹנָה?', 'LS01 spot, txt cells (eng)')
    out += stage_bg(b)
    x0, y0, w0, h0 = stage_inner(b)
    ps = h0 - 8
    out.append(img(os.path.join(PICS, 'cat.svg'), x0 + (w0 - ps) / 2, y0 + 4, ps, ps))
    out.append(label(x0 + w0 / 2, y0 - 2, 'the model: the picture (and its word, heard)', '#B23A3A', 10, 'mid'))
    r, xs, w, y, fits = options_row(b, course, ['c', 'a', 'p'], ['idle', 'idle', 'chosen'], band, letter=True)
    out += r
    out += zones(b)
    return out


def scene_match(b, band='B'):
    course = 'rus'
    B = BOARDS[b]
    S = SIZES[band][B['tablet']]
    out = frame(b, 'מָה הוֹלֵךְ עִם זֶה?', 'LS01 match, one at a time (rus)')
    out += stage_bg(b)
    x0, y0, w0, h0 = stage_inner(b)
    # the item now: big, at the start of the stage; the pairs done so far: small, at its end side
    t = min(h0 - 8, 120)
    cx = x0 + 8
    out += tile(cx, y0 + (h0 - t) / 2, t, t, text_span('М', course, int(S['letter'] * 1.25), bold=True), 'idle')
    out.append(label(cx + t / 2, y0 - 2, 'now: %d, letter %d pt' % (t, int(S['letter'] * 1.25)), '#B23A3A', 10, 'mid'))
    dx = x0 + w0 - 8 - 112
    out.append(box(dx, y0 + 30, 112, 60, 'background:%s;border-radius:16px;display:flex;align-items:center;justify-content:center;gap:10px' % C['mist'],
                   text_span('А', course, S['chip']['t'], bold=True) + '<span style="width:14px;height:3px;background:#8A6FE0;display:inline-block"></span>' + text_span('а', course, S['chip']['t'], bold=True), cls='tilebox'))
    out.append(label(dx + 56, y0 + 96, 'done pairs (kept, caption size)', '#B23A3A', 10, 'mid'))
    r, xs, w, y, fits = options_row(b, course, ['м', 'н', 'т'], ['idle', 'idle', 'idle'], band, letter=True)
    out += r
    out += zones(b)
    return out


def scene_soundsort(b, band='A'):
    course = 'heb'
    B = BOARDS[b]
    S = SIZES[band][B['tablet']]
    out = frame(b, 'אֶחָד אוֹ הַרְבֵּה?', 'LS01 sort, sound cards (heb A-05.7)', band)
    out += stage_bg(b)
    out += bins(b, course, ['', ''], {0: ['#sound']}, band, sign_pics=['set-ducks-1.svg', 'set-ducks-3.svg'])
    zx, zy, zw, zh = B['A']
    t = S['tile']
    g = S['gapSq']
    xs, _ = row_positions([t] * 3, zx, zw, g, course)
    faces = [SPEAKER_SVG % (52, 52, WAVES), SPEAKER_SVG % (52, 52, ''), SPEAKER_SVG % (52, 52, '')]
    states = ['chosen', 'idle', 'idle']
    for x, f, st in zip(xs, faces, states):
        out += tile(x, row_top(b, band), t, t, f, st, hit=(x - g / 2, row_top(b, band) - 12, t + g, t + 24))
    out.append(foot(b, 'sound card %d: waves = heard' % t))
    out += zones(b)
    return out


# ---- the states sheet (spec section 6) ------------------------------------------------------------------------------------
def states_sheet():
    W, H = 852, 600
    out = [box(0, 0, W, H, 'background:%s;border:1px solid #C9C3D9' % C['cream'])]
    S = SIZES['B'][False]
    out.append(label(12, 8, 'States of a Band B text tile on the phone (88 high, word 38 pt); the same on every board at its size', '#2B2350', 13))
    names = [('idle', 'idle'), ('lit', 'lit (sky ring)'), ('chosen', 'chosen (lifted, ring)'),
             ('notyet', 'not yet (wobble)'), ('correct', 'correct (check)'), ('dim', 'level 3 (others dim)')]
    x = 24
    for st, nm in names:
        w = width('tap', 'eng', 38) + 28
        w = max(88, w)
        out += tile(x, 50, w, 88, text_span('tap', 'eng', 38), st)
        out.append(label(x + w / 2, 152, nm.split(' (')[0], '#2B2350', 11, 'mid'))
        if '(' in nm:
            out.append(label(x + w / 2, 166, '(' + nm.split(' (')[1], '#5A5378', 10, 'mid'))
        x += w + 46
    # sound card states
    out.append(label(12, 196, 'Sound card (no picture): not yet heard, playing, heard', '#2B2350', 13))
    x = 24
    for waves, st, nm in [('', 'idle', 'not yet heard'), (WAVES, 'lit', 'playing'), (WAVES, 'idle', 'heard')]:
        out += tile(x, 226, 88, 88, SPEAKER_SVG % (52, 52, waves), st)
        out.append(label(x + 44, 326, nm, '#2B2350', 11, 'mid'))
        x += 140
    # the cloze gap and the story line's places
    out.append(label(450, 196, 'Cloze gap: empty, filled, right', '#2B2350', 13))
    gx = 450
    for nm, style, word in [('empty', 'border:3px dashed %s;background:rgba(255,255,255,0.7)' % C['lilacDeep'], ''),
                            ('filled', 'border:3px solid %s;background:#fff' % C['lilacDeep'], 'on'),
                            ('right', 'border:3px solid %s;background:%s' % (C['spark'], C['sparkTint']), 'on')]:
        out.append(box(gx, 236, 96, 40, style + ';border-radius:12px;display:flex;align-items:center;justify-content:center', text_span(word, 'eng', 34) if word else ''))
        out.append(label(gx + 48, 286, nm, '#2B2350', 11, 'mid'))
        if nm == 'right':
            out.append(box(gx + 80, 228, 24, 24, 'background:%s;border-radius:50%%;display:flex;align-items:center;justify-content:center' % C['spark'], CHECK_SVG))
        gx += 120
    out.append(label(12, 350, 'Story line place: not set, set (bead filled, path drawn to it), and the start flag', '#2B2350', 13))
    out.append(box(40, 400, 300, 6, 'background:%s;border-radius:3px' % C['mist']))
    out.append(box(40, 400, 150, 6, 'background:%s;border-radius:3px' % C['lilacDeep']))
    for k, cx in enumerate([90, 190, 290]):
        f = k < 2
        out.append(box(cx - 8, 395, 16, 16, 'border-radius:50%%;background:%s;border:3px solid %s' % (C['lilacDeep'] if f else '#fff', C['lilacDeep'] if f else C['lip'])))
    out.append('<svg style="position:absolute;left:22px;top:377px" width="14" height="30" viewBox="0 0 14 30"><rect x="1" y="2" width="3" height="27" rx="1.5" fill="#2B2350"/><path d="M4 3 L13 8 L4 13 Z" fill="#1A9E9A"/></svg>')
    out.append(label(90, 418, 'set', '#2B2350', 11, 'mid'))
    out.append(label(190, 418, 'set', '#2B2350', 11, 'mid'))
    out.append(label(290, 418, 'not set', '#2B2350', 11, 'mid'))
    out.append(label(450, 380, 'Every state is a shape as well as a colour:', '#2B2350', 12))
    for i, t in enumerate(['chosen = lifted + ring;  not yet = wobble;  correct = check badge',
                           'heard = sound waves;  set = filled bead + path;  lit = wide soft ring',
                           'gap = dashed box until filled, solid when filled']):
        out.append(label(450, 400 + i * 16, t, '#5A5378', 11))
    # marks at risk of clipping: Russian stress (U+0301) and Й, Ё; Hebrew nikud below and dagesh; English ascenders and descenders
    out.append(label(12, 470, 'Marks in a phone tile at the reading size (nothing may be cut): Russian stress and Й Ё, Hebrew nikud, English g y p', '#2B2350', 13))
    x = 24
    for t, c in [('ко́шка', 'rus'), ('Йо́д', 'rus'), ('ёж', 'rus'), ('שֻׁלְחָן', 'heb'), ('גְּלִידָה', 'heb'), ('jug', 'eng'), ('Й', 'rus')]:
        letter = len(t) == 1
        size = 48 if letter else (34 if c == 'heb' else 38)
        w = max(88, width(t, c, size, bold=letter) + 28)
        out += tile(x, 498, w, 88, sign_face(t, c, SIZES['B'][False]) if letter else text_span(t, c, size))
        x += w + 16
    return out, W, H


# ---- rendering ------------------------------------------------------------------------------------------------------------
CHECK_JS = """
document.fonts.ready.then(()=>{let bad=0;
 for(const s of document.querySelectorAll('.tilebox')){const r=s.getBoundingClientRect();for(const c of s.querySelectorAll('.fit')){const q=c.getBoundingClientRect();
   if(q.left<r.left-0.5||q.right>r.right+0.5||q.top<r.top-0.5||q.bottom>r.bottom+0.5){bad++;s.style.outline='4px solid red';}}}
 for(const s of document.querySelectorAll('.fitw')){if(s.scrollWidth>s.clientWidth+1){bad++;s.style.outline='4px solid red';}}
 for(const s of document.querySelectorAll('.fith')){const t=s.firstElementChild;const lines=Math.round(t.offsetHeight/parseFloat(t.dataset.lh));
   if(t.offsetHeight>s.parentElement.clientHeight+1||lines>parseInt(t.dataset.maxl)||t.scrollWidth>t.clientWidth+1){bad++;s.style.outline='4px solid red';}
   const tag=document.createElement('div');tag.textContent=lines+' lines';tag.style.cssText='position:absolute;right:2px;bottom:-14px;font:600 10px sans-serif;color:#B23A3A';s.parentElement.appendChild(tag);}
 document.title='bad='+bad;});
"""


def page(boards_html, out_png, width_px):
    tmp = tempfile.mkdtemp(prefix='l5_')
    body = ''.join('<div style="position:relative;display:inline-block;vertical-align:top;margin:10px;width:%dpx;height:%dpx">%s</div>' % (w, h, ''.join(parts))
                   for parts, w, h in boards_html)
    doc = '<html><head><meta charset="utf-8"><style>%s</style></head><body style="margin:0;background:#FFFFFF;width:%dpx">%s<script>%s</script></body></html>' % (
        FONT_CSS, width_px, body, CHECK_JS)
    path = os.path.join(tmp, 'p.html')
    with open(path, 'w', encoding='utf-8') as fh:
        fh.write(doc)
    height, row_w, row_h = 0, 0, 0
    for _, w, h in boards_html:
        if row_w + w + 20 > width_px:
            height += row_h + 20
            row_w, row_h = 0, 0
        row_w += w + 20
        row_h = max(row_h, h)
    height += row_h + 24
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1', '--allow-file-access-from-files',
                    '--virtual-time-budget=8000', '--screenshot=' + out_png, '--window-size=%d,%d' % (width_px, height), uri(path)], check=True, capture_output=True)
    dom = subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--allow-file-access-from-files', '--virtual-time-budget=8000', '--window-size=%d,%d' % (width_px, height),
                          '--dump-dom', uri(path)], check=True, capture_output=True).stdout.decode('utf-8')
    m = re.search(r'<title>(.*?)</title>', dom)
    print(os.path.basename(out_png), m.group(1) if m else 'no check')


def collect_strings():
    s = set()
    for c in ('eng', 'heb'):
        f = fam(c)
        for t in SORT[c]['cards'] + SORT[c]['signs'] + CLOZE[c]['options'] + CLOZE[c]['before'].split(' ') + CLOZE[c]['after'].split(' ') + [' ']:
            s.add((f, 500, t))
            s.add((f, 700, t))
    for t in ['ко́шка', 'Йо́д', 'ёж', 'jug', 'Й']:
        s.add(('L', 500, t))
        s.add(('L', 700, t))
    for t in ['שֻׁלְחָן', 'גְּלִידָה']:
        s.add(('H', 500, t))
    for t in ['I sit', 'I', 'sit', 'tap', 'c', 'a', 'p', 'М', 'А', 'а', 'м', 'н', 'т']:
        s.add(('L', 500, t))
        s.add(('L', 700, t))
    for t in ['דָּג', 'א', '2', 'ס', '○', 'ל']:
        s.add(('H', 500, t))
        s.add(('H', 700, t))
    # the fit table's sample words (spec section 4)
    for t in FIT_WORDS['t']:
        s.add(('L', 500, t))
    for t in FIT_WORDS['he']:
        s.add(('H', 500, t))
    return s


FIT_WORDS = {'t': ['cat', 'map', 'duck', 'frog', 'rabbit', 'the map', 'elephant', 'кот', 'мама', 'ко́шка', 'соба́ка', 'маши́на', 'черепа́ха'],
             'he': ['דָּג', 'כֶּלֶב', 'חָתוּל', 'אַבָּא', 'פַּרְפַּר', 'מִטְרִיָּה', 'אֲבַטִּיחַ']}


def fit_table():
    """The widest text (in em of the reading size) that fits n equal tiles in the answer zone of each board (spec section 4)."""
    print('\nFit table, Band B (max text width in em of the word reading size; zone, tile and gap as in the spec):')
    for b in ('phoneSE', 'phone', 'tabletPortrait', 'tabletLandscape'):
        B = BOARDS[b]
        S = SIZES['B'][B['tablet']]
        zw = B['A'][2]
        row = []
        for n in (2, 3, 4):
            g = S['gapWide']
            wcap = zw / n - g
            text = wcap - 2 * S['pad']
            row.append('n=%d: tile<=%d text<=%d (%.2f em EN/RU, %.2f em HE)' % (n, wcap, text, text / S['word']['t'], text / S['word']['he']))
        print('  %-16s zone %d: %s' % (b, zw, ';  '.join(row)))
    print('\nSample words, width at the phone word size (EN/RU 38, HE 34):')
    for t in FIT_WORDS['t']:
        print('  %-12s %.2f em  %4.0f pt' % (t, _EM[('L', 500, t)], _EM[('L', 500, t)] * 38))
    for t in FIT_WORDS['he']:
        print('  %-12s %.2f em  %4.0f pt' % (t, _EM[('H', 500, t)], _EM[('H', 500, t)] * 34))


def main():
    measure(collect_strings())
    fit_table()
    W = {b: (BOARDS[b]['W'], BOARDS[b]['H']) for b in BOARDS}
    print()
    for name, fn in (('ls01_sort_text', scene_sort), ('ls01_cloze', scene_cloze), ('ls01_sequence', scene_sequence)):
        boards = []
        for b in ('phone', 'tabletLandscape'):
            for c in ('eng', 'heb'):
                boards.append((fn(b, c), W[b][0], W[b][1]))
        page(boards, os.path.join(HERE, name + '.png'), 2420)
    small = [(scene_sort('phoneSE', 'eng'), *W['phoneSE']), (scene_cloze('phoneSE', 'heb'), *W['phoneSE']), (scene_sequence('phoneSE', 'eng'), *W['phoneSE']),
             (scene_sort('tabletPortrait', 'heb'), *W['tabletPortrait']), (scene_cloze('tabletPortrait', 'eng', filled='on'), *W['tabletPortrait']),
             (scene_sequence('tabletPortrait', 'heb'), *W['tabletPortrait'])]
    page(small[:3], os.path.join(HERE, 'ls01_phoneSE.png'), 2080)
    page(small[3:], os.path.join(HERE, 'ls01_tabletPortrait.png'), 2560)
    more = [(scene_stem('phone', 'eng'), *W['phone']), (scene_stem('phone', 'heb'), *W['phone']), (scene_tapall('phone'), *W['phone']),
            (scene_tapall('phoneSE'), *W['phoneSE']), (scene_spot('phone'), *W['phone']), (scene_match('phone'), *W['phone']),
            (scene_soundsort('phone'), *W['phone'])]
    page(more, os.path.join(HERE, 'ls01_more_modes_phones.png'), 1780)
    st, sw, sh = states_sheet()
    page([(st, sw, sh)], os.path.join(HERE, 'ls01_states.png'), 880)


if __name__ == '__main__':
    main()
