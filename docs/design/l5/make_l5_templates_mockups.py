"""Mockups of docs/design/l5-templates.md (L5-3 LS03 `boxes`, L5-4 LS05 `change_part`, L5-5 LS04 `blend_slide`): each board drawn at
its real size in points with the app's own pictures and the real fonts (Heebo for the interface and the Hebrew course, Nitznutz Letters
for English and Russian), rendered by headless Chrome into docs/design/l5/*.png.

    python docs/design/l5/make_l5_templates_mockups.py

It reuses the drawing helpers, the colours, the boards and the Band sizes of the L5-1 generator
(docs/design/languages-l5/make_l5_ls01_mockups.py), so the frame, the tiles and the check for text that leaves its box are the same.
A red outline on a mockup would mark a text that overflows its box; the script prints "bad=0" for each sheet when there is none.

References looked at before drawing (2026-11-07; looked at and read, nothing copied or traced; every shape here is drawn in plain
CSS or SVG):
- Elkonin sound boxes (D. B. Elkonin's method): one box per sound, a token pushed into each box as the sound is said, tokens of
  different colours for consonants and vowels in later steps, then letters in the boxes. Wikipedia "Elkonin boxes"; understood.org
  "Elkonin sound boxes: an evidence-based literacy strategy"; readingvine.com; the iOS app "Elkonin Boxes" (its practice mode shows
  the right number of boxes, which is why the count step here grows its boxes one by one and never shows how many there are).
- The Russian sound scheme (звуковая схема): red for a vowel, blue for a hard consonant, green for a soft one, laid out in order,
  the stressed vowel marked with a stress sign (some kindergartens use a bell or a black chip). Kindergarten guides for teachers and
  parents found by search (mdou142.edu.yar.ru, ds88-belgorod "Что такое звуковой анализ слова", the "Игры, обучающие детей звуковому
  анализу слова" handout).
- The Russian vowel chart and the syllable window (слоговое окошко): the hard-row vowels а о у ы э above the soft-row vowels я ё ю и е,
  and a consonant card with a window through which a strip of vowels slides; images of classroom strips (Bing image search,
  "слоговое окошко лента гласных").
- The Hebrew nikud wheel (גלגל ניקוד אותיות): two discs on one pin, the letters round the outer disc and the vowel signs on the
  inner one, read where the two line up; images of the printed classroom wheels (Bing image search "גלגל ניקוד אותיות"). The
  coloured "spin the wheel" sector wheels in the same results were noted as a look to avoid: a prize wheel is about chance.
- English phonics "sound buttons": a dot under each one-letter sound and a bar under a digraph, pressed in order and then swept with
  a finger to blend (images: "phonics sound buttons dots and dashes", CVC flashcards).
- Mouth pictures for phonemes (articulation cards): a close-up of the lips, teeth and tongue for each sound (images: "phoneme mouth
  articulation picture cards"). The app already has seven mouth pictures (content/languages/pictures/mouth-*.svg); the mockups use
  them, and the spec lists the ones still missing.

Every Hebrew line and every word here is a sample only (the bubble lines are needs-editor; the words are the teachers' choice).
Labels in red (zones, sizes, hit areas) are for the team, never in the app.
"""
import importlib.util
import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..', '..'))
_spec = importlib.util.spec_from_file_location('ls01', os.path.join(ROOT, 'docs', 'design', 'languages-l5', 'make_l5_ls01_mockups.py'))
m = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(m)

C, BOARDS, NAMES, SIZES = m.C, m.BOARDS, m.NAMES, m.SIZES
C.setdefault('seaDeep', '#0F6E6A')
box, img, label, text_span, ui_text, tile, foot, zones = m.box, m.img, m.label, m.text_span, m.ui_text, m.tile, m.foot, m.zones
stage_bg, stage_inner, row_positions, uri, esc, width = m.stage_bg, m.stage_inner, m.row_positions, m.uri, m.esc, m.width
PICS, CAST, UI = m.PICS, m.CAST, m.UI
HINTS = os.path.join(ROOT, 'app', 'assets', 'art', 'hints')
SPEAKER_SVG, WAVES, CHECK_SVG = m.SPEAKER_SVG, m.WAVES, m.CHECK_SVG

TEACH = dict(red=('#D62F2F', '#A82020'), blue=('#2563D9', '#1A47A8'), green=('#3CB55A', '#2A8C44'))
TOKEN, TOKEN_LIP, TOKEN_RING = '#F2C894', '#C98B4E', 'rgba(255,255,255,0.65)'
KIND_COLOUR = {'vowel': 'red', 'hard': 'blue', 'soft': 'green'}
W_ = {b: (BOARDS[b]['W'], BOARDS[b]['H']) for b in BOARDS}


def rtl(course):
    return course == 'heb'


def mir(x, w, zx, zw, course):
    """x of a box laid out for a left-to-right course, mirrored inside its zone for the Hebrew course."""
    return zx + zw - (x - zx) - w if rtl(course) else x


def frame(b, bubble_text, title):
    """The activity frame of the L5-1 mockups without the microphone (no template here has a say step)."""
    parts = m.frame(b, bubble_text, title)
    B = BOARDS[b]
    mx, my, ms = B['mic']
    # drop the microphone's disc and icon (the L5-1 frame draws it); the answer zones still end before its place
    return [p for p in parts if ('left:%.1fpx;top:%.1fpx;width:%.1fpx' % (mx, my, ms)) not in p and 'mic.svg' not in p]


# ---- shared marks and pieces ------------------------------------------------------------------------------------------------
def mark_svg(kind, size, color='#FFFFFF'):
    """The shape mark of each colour of the Russian sound scheme: never colour alone (design-spec 9.2).
    vowel = a note (a vowel can be sung: the level-2 test "can you sing it?"); hard = a square block; soft = a smile (the level-2
    picture of a soft consonant is the smiling mouth)."""
    if kind == 'vowel':
        g = ('<ellipse cx="40" cy="70" rx="17" ry="13" transform="rotate(-22 40 70)" fill="%s"/>'
             '<rect x="51" y="20" width="9" height="52" rx="4" fill="%s"/>'
             '<path d="M56 21 C70 24 78 34 76 48 C72 40 66 36 58 35 Z" fill="%s"/>') % (color, color, color)
    elif kind == 'hard':
        g = '<rect x="27" y="27" width="46" height="46" rx="7" fill="%s"/>' % color
    else:
        g = '<path d="M24 42 Q50 80 76 42" fill="none" stroke="%s" stroke-width="12" stroke-linecap="round"/>' % color
    return '<svg viewBox="0 0 100 100" width="%d" height="%d">%s</svg>' % (size, size, g)


def chip(x, y, d, kind=None, lifted=False, lit=False, dim=False, ghost=False):
    """A token. kind None: the plain token of the count step (white, an ink ring: a counter); else coloured with its white mark."""
    out = []
    dy = -5 if lifted else 0
    if lit:
        out.append(box(x - 9, y - 9 + dy, d + 18, d + 18, 'border-radius:50%%;border:8px solid rgba(143,211,244,0.55)'))
    if kind is None:
        # a plain counter (a wooden token): warm tan, not one of the scheme's colours, not a feedback colour
        style = 'background:%s;border:4px solid %s;box-shadow:0 %dpx 0 %s' % (TOKEN, TOKEN_LIP, 6 if lifted else 4, TOKEN_LIP)
        inner = box(d * 0.2, d * 0.2, d * 0.6 - 8, d * 0.6 - 8, 'border-radius:50%%;border:3px solid %s' % TOKEN_RING)
    else:
        fill, lip = TEACH[KIND_COLOUR[kind]]
        style = 'background:%s;border:4px solid %s;box-shadow:0 %dpx 0 %s' % (fill, lip, 6 if lifted else 3, lip)
        inner = '<div style="position:absolute;left:0;top:0;width:100%%;height:100%%;display:flex;align-items:center;justify-content:center">%s</div>' % mark_svg(kind, int(d * 0.62))
    op = 'opacity:0.45;' if ghost else ('opacity:0.4;' if dim else '')
    out.append(box(x, y + dy, d, d, 'border-radius:50%%;position:absolute;%s;%s' % (style, op), inner))
    return out


def pebble(x, y, s, inner, fill='#FFFFFF', lip=None, ring=None, lit=False):
    """A round control (the app's pebble button): white, the clay lip."""
    out = []
    if lit:
        out.append(box(x - 8, y - 8, s + 16, s + 16, 'border-radius:50%;border:8px solid rgba(143,211,244,0.55)'))
    if ring:
        out.append(box(x - 7, y - 9, s + 14, s + 14, 'border-radius:50%%;border:4px solid %s' % ring))
    out.append(box(x, y, s, s, 'border-radius:50%%;background:%s;box-shadow:0 6px 0 %s;display:flex;align-items:center;justify-content:center' % (fill, lip or C['lip']), inner))
    return out


def speaker(s, waves=True):
    return SPEAKER_SVG % (int(s * 0.55), int(s * 0.55), WAVES if waves else '')


def check_btn(x, y, s, lit=False):
    return pebble(x, y, s, '<svg viewBox="0 0 24 24" width="%d" height="%d"><path d="M5 12.5l4.2 4.2L19 7" fill="none" stroke="#2B2350" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>' % (s * 0.55, s * 0.55), lit=lit)


def picture_card(x, y, s, pic, lit=False, label_text=None, waves=False):
    """The word's picture on the stage: white, framed, radius 20; a touch plays the word (the replay)."""
    out = []
    if lit:
        out.append(box(x - 8, y - 8, s + 16, s + 16, 'border-radius:28px;border:8px solid rgba(143,211,244,0.55)'))
    out.append(box(x, y, s, s, 'background:#fff;border-radius:20px;border:3px solid %s;box-shadow:0 4px 0 %s' % (C['hairline'], C['lip'])))
    out.append(img(os.path.join(PICS, pic), x + 6, y + 6, s - 12, s - 12))
    sp = max(26, s * 0.24)
    out.append(box(x + s - sp + 6, y + s - sp + 6, sp, sp, 'border-radius:50%%;background:%s;border:2px solid #fff;display:flex;align-items:center;justify-content:center' % C['skyTint'],
                   SPEAKER_SVG % (sp * 0.6, sp * 0.6, WAVES if waves else '')))
    if label_text:
        out.append(label(x + s / 2, y + s + 6, label_text, '#B23A3A', 10, 'mid'))
    return out


def hand(x, y, s=64, rot=0):
    """The pointing hand of level 3 (app/assets/art/hints/hand_point.svg, viewBox 102 x 142), its fingertip at (x, y)."""
    w = s * 102 / 142
    return '<img src="%s" style="position:absolute;left:%.1fpx;top:%.1fpx;width:%.1fpx;height:%.1fpx;transform:rotate(%ddeg);transform-origin:50%% 0%%">' % (
        uri(os.path.join(HINTS, 'hand_point.svg')), x - w / 2, y, w, s, rot)


def sky_card(x, y, w, h):
    return box(x, y, w, h, 'background:%s;border:3px solid %s;border-radius:22px;box-shadow:0 6px 16px rgba(43,35,80,.14)' % (C['skyTint'], C['sky']))


# ================================================================================================================================
# LS03 sound boxes, mode `boxes`
# ================================================================================================================================
# Per board, laid out for a left-to-right course (Hebrew mirrors every x inside its zone). Board points.
LS03 = {
    'phone': dict(pic=(30, 110, 120), pile=(211, 122, 96), check=(323, 134, 72), med=(30, 110, 120), stamps=(171, 138, 64, 16),
                  sound=(323, 134, 72), place=(80, 88), gap=12, token=64, rowy=264),
    'phoneSE': dict(pic=(30, 114, 88), pile=(126, 118, 80), check=(216, 126, 64), med=(30, 130, 56), stamps=(96, 130, 56, 8),
                    sound=(216, 126, 64), place=(72, 88), gap=8, token=56, rowy=250),
    'tabletLandscape': dict(pic=(304, 280, 200), pile=(596, 310, 140), check=(760, 332, 96), med=(304, 280, 200), stamps=(544, 336, 88, 24),
                            sound=(760, 332, 96), place=(104, 104), gap=16, token=88, rowy=566),
    'tabletPortrait': dict(pic=(40, 412, 220), pile=(492, 442, 160), check=(684, 450, 96), med=(40, 412, 220), stamps=(428, 474, 96, 32),
                           sound=(684, 450, 96), place=(112, 112), gap=16, token=96, rowy=700),
}
CAPACITY = 6  # places on the rail in Band B, the same for every item (so it tells nothing about the word)


def rail_places(b, course, n_places=CAPACITY):
    g = LS03[b]
    pw, ph = g['place']
    zx, zy, zw, zh = BOARDS[b]['A']
    total = CAPACITY * pw + (CAPACITY - 1) * g['gap']
    x0 = zx + (zw - total) / 2
    out = []
    for i in range(n_places):
        x = x0 + i * (pw + g['gap'])
        out.append((mir(x, pw, zx, zw, course), g['rowy'], pw, ph))
    return out, (mir(x0, total, zx, zw, course), g['rowy'], total, ph)


def rail(b, course, tokens, step='count', next_box=True, colours=None, stress=None, chosen=None, lit=None, correct=False,
         notyet=None, lifted_vowels=False, kinds=None):
    """The rail of places in A: a soft groove the width of 6 places; a box with its token for each token laid; one dashed "next"
    place after the last at the count step. tokens: how many are laid."""
    g = LS03[b]
    pw, ph = g['place']
    places, (rx, ry, rw, rh) = rail_places(b, course)
    out = [box(rx - 8, ry - 6, rw + 16, rh + 12, 'background:%s;border-radius:24px' % C['mist'])]
    for i in range(tokens):
        x, y, w, h = places[i]
        border = C['spark'] if correct else (C['lilac'] if notyet and i in notyet else C['hairline'])
        bg = C['sparkTint'] if correct else '#FFFFFF'
        if chosen == i:
            out.append(box(x - 7, y - 7, w + 14, h + 14, 'border:4px solid %s;border-radius:24px' % C['ring']))
        if lit == i:
            out.append(box(x - 8, y - 8, w + 16, h + 16, 'border:8px solid rgba(143,211,244,0.55);border-radius:26px'))
        out.append(box(x, y, w, h, 'background:%s;border:4px solid %s;border-radius:18px;box-shadow:0 4px 0 %s' % (bg, border, C['lip'])))
        # hit area: the place plus half the gap at each side and 12 above and below
        out.append(box(x - g['gap'] / 2, y - 12, w + g['gap'], h + 24, 'border:1px dotted rgba(108,64,208,0.5);border-radius:22px'))
        kind = colours[i] if colours else None
        d = g['token']
        lift = lifted_vowels and kinds and kinds[i] == 'vowel'
        out += chip(x + (w - d) / 2, y + (h - d) / 2 + 4, d, kind, lifted=lift, dim=(lifted_vowels and kinds and kinds[i] != 'vowel'))
        if stress == i:
            out.append('<svg style="position:absolute;left:%.1fpx;top:%.1fpx" width="30" height="26" viewBox="0 0 30 26"><path d="M9 22 L22 5" stroke="%s" stroke-width="7" stroke-linecap="round"/></svg>' % (x + w / 2 - 13, y - 24, C['ink']))
        if notyet and i in notyet:
            out.append(box(x - 13, y + h / 2 - 14, 8, 28, 'border-left:3px solid %s;border-radius:50%%' % C['lilac']))
            out.append(box(x + w + 5, y + h / 2 - 14, 8, 28, 'border-right:3px solid %s;border-radius:50%%' % C['lilac']))
    if correct:
        x, y, w, h = places[tokens - 1]
        cx = x + w - 20 if not rtl(course) else x - 8
        out.append(box(cx, y - 10, 30, 30, 'background:%s;border-radius:50%%;display:flex;align-items:center;justify-content:center' % C['spark'], CHECK_SVG))
    if step == 'count' and next_box and tokens < CAPACITY:
        x, y, w, h = places[tokens]
        out.append(box(x, y, w, h, 'border:3px dashed %s;border-radius:18px;background:rgba(255,255,255,0.5)' % C['lilacDeep']))
    return out


def pile(x, y, s, lit=False):
    """The bowl of tokens: a shallow bowl with three tokens in it, its front rim over them; the whole bowl is the target (a tap
    sends one token to the next place; a token can also be dragged out of it)."""
    out = []
    if lit:
        out.append(box(x - 8, y - 8, s + 16, s + 16, 'border-radius:50%;border:8px solid rgba(143,211,244,0.55)'))
    svg = ('<svg style="position:absolute;left:%.1fpx;top:%.1fpx" width="%.1f" height="%.1f" viewBox="0 0 100 100">'
           '<ellipse cx="50" cy="56" rx="47" ry="22" fill="%s" stroke="%s" stroke-width="3"/>'
           '<circle cx="34" cy="50" r="17" fill="%s" stroke="%s" stroke-width="3.5"/><circle cx="34" cy="50" r="10" fill="none" stroke="#fff" stroke-opacity=".65" stroke-width="2.5"/>'
           '<circle cx="64" cy="50" r="17" fill="%s" stroke="%s" stroke-width="3.5"/><circle cx="64" cy="50" r="10" fill="none" stroke="#fff" stroke-opacity=".65" stroke-width="2.5"/>'
           '<circle cx="49" cy="38" r="17" fill="%s" stroke="%s" stroke-width="3.5"/><circle cx="49" cy="38" r="10" fill="none" stroke="#fff" stroke-opacity=".65" stroke-width="2.5"/>'
           '<path d="M3 56 C6 90 94 90 97 56 C90 74 10 74 3 56 Z" fill="#FFFFFF" stroke="%s" stroke-width="3"/>'
           '<path d="M10 70 C30 86 70 86 90 70" fill="none" stroke="%s" stroke-width="5" stroke-linecap="round"/></svg>') % (
        x, y, s, s, C['mist'], C['hairline'], TOKEN, TOKEN_LIP, TOKEN, TOKEN_LIP, TOKEN, TOKEN_LIP, C['hairline'], C['lip'])
    out.append(svg)
    return out


def stamp(x, y, s, kind, chosen=False):
    fill, lip = TEACH[KIND_COLOUR[kind]]
    out = []
    if chosen:
        out.append(box(x - 5, y - 11, s + 10, s + 10, 'border-radius:50%%;border:4px solid %s' % C['ring']))
    dy = -6 if chosen else 0
    out.append(box(x, y + dy, s, s, 'border-radius:50%%;background:%s;box-shadow:0 6px 0 %s;display:flex;align-items:center;justify-content:center' % (fill, lip), mark_svg(kind, int(s * 0.64))))
    return out


def ls03_scene(b, course, word, pic, step, laid, kinds=None, colours=None, stress=None, chosen_stamp=None, bubble='', title='',
               hint=None, which_lit=None, correct=False, notyet=None, mouths=None, hint_units=None, hint_lit=None):
    B = BOARDS[b]
    g = LS03[b]
    sx0, sy0, sw0, sh0 = B['S']
    out = frame(b, bubble, title)
    out += stage_bg(b)

    def at(xx, w):
        return mir(xx, w, sx0, sw0, course)
    if step == 'colour':
        px, py, ps = g['med']
    else:
        px, py, ps = g['pic']
    out += picture_card(at(px, ps), py, ps, pic, lit=(hint == 1), waves=(hint == 1))
    if step == 'count':
        x, y, s = g['pile']
        out += pile(at(x, s), y, s)
        x, y, s = g['check']
        out += check_btn(at(x, s), y, s)
        out.append(label(at(x, s) + s / 2, y + s + 6, '"that\'s all" %d' % s, '#B23A3A', 10, 'mid'))
        out.append(label(at(g['pile'][0], g['pile'][2]) + g['pile'][2] / 2, g['pile'][1] + g['pile'][2] + 2, 'tokens %d' % g['pile'][2], '#B23A3A', 10, 'mid'))
    elif step == 'colour':
        x, y, s, gap = g['stamps']
        for i, k in enumerate(['vowel', 'hard', 'soft']):
            xx = x + i * (s + gap)
            out += stamp(at(xx, s), y, s, k, chosen=(chosen_stamp == k))
        out.append(label(at(x, 3 * s + 2 * gap) + (3 * s + 2 * gap) / 2, y + s + 6, 'stamps %d, gap %d' % (s, gap), '#B23A3A', 10, 'mid'))
    elif step == 'which':
        x, y, s = g['sound']
        out += pebble(at(x, s), y, s, speaker(s), fill=C['skyTint'])
        out.append(label(at(x, s) + s / 2, y + s + 6, 'the sound again %d' % s, '#B23A3A', 10, 'mid'))
    rail_kw = dict(colours=colours, stress=stress, lifted_vowels=(step == 'stress'), kinds=kinds, correct=correct, notyet=notyet)
    if step == 'which':
        rail_kw['chosen'] = which_lit
    out += rail(b, course, laid, step=step, **rail_kw)
    pw, ph = g['place']
    out.append(foot(b, 'place %dx%d (hit %dx%d), gap %d, token %d; rail of %d' % (pw, ph, pw + g['gap'], ph + 24, g['gap'], g['token'], CAPACITY)))
    if hint == 2 and (mouths or hint_units):
        # level 2: a sky card over the stage with one picture per unit, each lit as its unit plays (never on the rail)
        x0, y0, w0, h0 = stage_inner(b)
        out.append(sky_card(x0, y0, w0, h0))
        n = len(mouths or hint_units)
        cs = min(h0 - 28, (w0 - 24 - (n - 1) * 8) / n)
        xs, _ = row_positions([cs] * n, x0, w0, 8, course)
        for i, xx in enumerate(xs):
            yy = y0 + (h0 - cs) / 2
            on = hint_lit == i
            out.append(box(xx, yy, cs, cs, 'background:#fff;border-radius:16px;border:%dpx solid %s;%s' % (4 if on else 2, C['skyDeep'] if on else C['hairline'], '' if on or (hint_lit is not None and i < hint_lit) else 'opacity:0.5')))
            if mouths:
                out.append(img(os.path.join(PICS, mouths[i]), xx + 4, yy + 4, cs - 8, cs - 8))
            else:
                hs = cs * 0.42
                out.append(img(os.path.join(HINTS, 'hand_left_5.svg'), xx + cs / 2 - hs * 0.82, yy + cs * 0.14, hs * 0.9, hs * 0.9 * 174 / 112, 'transform:rotate(28deg);transform-origin:100% 100%'))
                out.append(img(os.path.join(HINTS, 'hand_right_5.svg'), xx + cs / 2 - hs * 0.08, yy + cs * 0.14, hs * 0.9, hs * 0.9 * 174 / 112, 'transform:rotate(-28deg);transform-origin:0% 100%'))
        out.append(label(x0 + 6, y0 + h0 - 16, 'level 2: one card per unit, lit as it plays', '#B23A3A', 10))
    out += zones(b)
    return out


def ls03_hint3(b, course):
    """Level 3 of the count step: the hand takes a token from the bowl to the next place (a ghost token on its way), the voice says
    each unit as its token lands; then the tokens go back and the child does it."""
    out = ls03_scene(b, course, 'sun', 'sun.svg', 'count', 1, bubble='תִּרְאוּ אֵיךְ.', title='LS03 boxes, count, hint level 3 (eng)')
    g = LS03[b]
    x, y, s = g['pile']
    places, _ = rail_places(b, course)
    px, py, pw, ph = places[1]
    d = g['token']
    gx, gy = (x + s / 2 + px + pw / 2) / 2 - d / 2, (y + s + py) / 2 - d / 2 - 10
    out += chip(gx, gy, d, ghost=True)
    out.append('<svg style="position:absolute;left:0;top:0;overflow:visible" width="1" height="1"><path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f" fill="none" stroke="%s" stroke-width="3" stroke-dasharray="6 6"/></svg>' % (
        x + s / 2, y + s * 0.5, gx + d, gy - 20, px + pw / 2, py + 10, C['skyDeep']))
    out.append(hand(gx + d / 2 + 6, gy + d * 0.55, 70, -14))
    return out


# ================================================================================================================================
# LS05 change one part: the Hebrew wheel and the Russian strip
# ================================================================================================================================
SIGN_DRAW = {
    # a vowel sign drawn under a dashed place-holder box (never a lone combining mark in a font): shapes in a 40 x 16 box
    'qamats': '<rect x="9" y="1" width="22" height="5.5" rx="2.5"/><rect x="17" y="4" width="6" height="11" rx="2.5"/>',
    'patah': '<rect x="9" y="4" width="22" height="6" rx="3"/>',
    'hiriq': '<circle cx="20" cy="7" r="4.5"/>',
    'none': '',
}
SIGN_CHAR = {'qamats': 'ָ', 'patah': 'ַ', 'hiriq': 'ִ', 'none': ''}


def sign_face(sign, s):
    """A sign part: a dashed box where the letter goes and the sign under it; "no sign" is the dashed box alone."""
    bw = s * 0.40
    return ('<div style="display:flex;flex-direction:column;align-items:center;gap:%dpx;margin-top:%dpx">'
            '<div style="width:%dpx;height:%dpx;border:3px dashed %s;border-radius:6px"></div>'
            '<svg viewBox="0 0 40 16" width="%d" height="%d" fill="%s">%s</svg></div>') % (
        max(2, s * 0.04), s * 0.08, bw, bw, C['inkSoft'], bw * 1.25, bw * 0.5, C['ink'], SIGN_DRAW[sign])


# The wheel: one ring of letter beads on a half dial (the classroom wheel standing on its panel, the lower half hidden behind the
# panel), the current letter at the top under the pointer, the unit made in the hub card at the stem size, and the signs as a row
# of sign beads on the panel. Per board: centre, ring radius, bead, bead letter size, hub card, unit size, sign bead and row top,
# and (make) the target speaker and the check.
LS05W = {
    'phone': dict(c=(212, 270), ro=136, bo=60, font=48, hub=(100, 84), unit=46, bs=56, sy=284, sgap=16, step=30,
                  target=(429, 262, 72), check=(521, 262, 72)),
    'phoneSE': dict(c=(190, 270), ro=120, bo=56, font=48, hub=(80, 80), unit=42, bs=56, sy=288, sgap=8, step=30,
                    target=(352, 262, 64), check=(436, 262, 64)),
    'tabletLandscape': dict(c=(560, 600), ro=250, bo=88, font=64, hub=(240, 150), unit=72, bs=88, sy=624, sgap=24, step=30,
                            target=(272, 664, 96), check=(752, 664, 96)),
    'tabletPortrait': dict(c=(410, 830), ro=300, bo=96, font=64, hub=(280, 170), unit=80, bs=96, sy=860, sgap=24, step=30,
                           target=(112, 1000, 96), check=(612, 1000, 96)),
}


def ring_offsets(n, cur, slots):
    """Where each part stands: its step from the top. A wheel with as many parts as slots (or more) is a loop (the parts that turn
    past the panel come back on the other side); a short one simply moves its parts along."""
    if n >= slots:
        return [((k - cur + n // 2) % n) - n // 2 for k in range(n)]
    return [k - cur for k in range(n)]


def dial(cx, cy, ro, bo, step, items, cur, face, course='heb', pointer=True, panel_w=None, panel_h=None, hit=True):
    out = []
    R = ro + bo / 2 + 8
    out.append(box(cx - R, cy - R, 2 * R, R, 'background:#FFFFFF;border:4px solid %s;border-bottom:none;border-radius:%dpx %dpx 0 0;box-shadow:inset 0 0 0 %dpx %s' % (
        C['hairline'], R, R, bo / 2 + 12, '#FFF9EF')))
    # a faint ring line through the beads, and the pin
    out.append(box(cx - ro, cy - ro, 2 * ro, ro, 'border:3px solid %s;border-bottom:none;border-radius:%dpx %dpx 0 0' % (C['mist'], ro, ro)))
    pw = panel_w or 2 * R + 28
    ph = panel_h or 20
    out.append(box(cx - pw / 2, cy - 4, pw, ph, 'background:%s;border-radius:16px;box-shadow:0 6px 0 %s' % (C['mist'], C['lip'])))
    slots = int(180 // step) + 1
    offs = ring_offsets(len(items), cur, slots)
    for it, off in zip(items, offs):
        a = 90 + off * step * (1 if course == 'heb' else -1)  # the next part in reading order stands towards the end side
        if not (0 <= a <= 180):
            continue
        ang = math.radians(a)
        x = cx + ro * math.cos(ang) - bo / 2
        y = cy - ro * math.sin(ang) - bo / 2
        is_cur = off == 0
        if hit:
            out.append(box(x - 6, y - 6, bo + 12, bo + 12, 'border-radius:50%;border:1px dotted rgba(108,64,208,0.5)'))
        out.append(box(x, y, bo, bo, 'border-radius:50%%;background:#fff;border:%dpx solid %s;box-shadow:0 4px 0 %s;display:flex;align-items:center;justify-content:center;overflow:hidden' % (
            4 if is_cur else 3, C['ink'] if is_cur else C['hairline'], C['lip']), face(it, bo), cls='tilebox'))
    if pointer:
        ww = bo + 14
        out.append(box(cx - ww / 2, cy - ro - bo / 2 - 7, ww, ww, 'border:5px solid %s;border-radius:50%%' % C['lilacDeep']))
        out.append('<svg style="position:absolute;left:%.1fpx;top:%.1fpx" width="26" height="16" viewBox="0 0 26 16"><path d="M2 2 H24 L13 14 Z" fill="%s"/></svg>' % (
            cx - 13, cy - ro - bo / 2 - 24, C['ink']))
    return out


def sign_row(cx, y, bs, gap, signs, cur, course='heb', hit=True):
    out = []
    n = len(signs)
    total = n * bs + (n - 1) * gap
    xs, _ = row_positions([bs] * n, cx - total / 2, total, gap, course)
    for k, (sgn, x) in enumerate(zip(signs, xs)):
        on = k == cur
        if on:
            out.append(box(x - 6, y - 6 - 5, bs + 12, bs + 12, 'border-radius:50%%;border:4px solid %s' % C['lilacDeep']))
        if hit:
            out.append(box(x - gap / 2, y - 10, bs + gap, bs + 20, 'border-radius:22px;border:1px dotted rgba(108,64,208,0.5)'))
        out.append(box(x, y - (5 if on else 0), bs, bs, 'border-radius:50%%;background:#fff;border:%dpx solid %s;box-shadow:0 %dpx 0 %s;display:flex;align-items:center;justify-content:center' % (
            4 if on else 3, C['ink'] if on else C['hairline'], 6 if on else 4, C['lip']), sign_face(sgn, bs)))
    return out


def ls05_wheel(b, letters, signs, cur_l, cur_s, mode='explore', bubble='', title='', lit_hub=False):
    B = BOARDS[b]
    g = LS05W[b]
    out = frame(b, bubble, title)
    cx, cy = g['c']
    ro, bo = g['ro'], g['bo']
    panel_h = B['H'] - 24 - 8 - cy + 4
    out += dial(cx, cy, ro, bo, g['step'], letters, cur_l, lambda t, s: text_span(t, 'heb', g['font'], bold=True, lineh=1.0), panel_h=panel_h)
    # the hub: the unit made, at the stem size; a touch plays it
    hw, hh = g['hub']
    unit = letters[cur_l] + SIGN_CHAR[signs[cur_s]]
    hx, hy = cx - hw / 2, cy - hh - 2
    if lit_hub:
        out.append(box(hx - 8, hy - 8, hw + 16, hh + 16, 'border-radius:26px;border:8px solid rgba(143,211,244,0.55)'))
    out.append(box(hx, hy, hw, hh, 'background:#fff;border:4px solid %s;border-radius:22px;box-shadow:0 4px 0 %s;display:flex;align-items:center;justify-content:center' % (C['lilacDeep'], C['lip']),
                   text_span(unit, 'heb', g['unit']), cls='tilebox'))
    # a short line from the window to the hub: "these two make this"
    out.append(box(cx - 2, cy - ro + bo / 2 + 8, 4, ro - bo / 2 - hh - 22, 'background:repeating-linear-gradient(180deg,%s 0 6px,transparent 6px 11px)' % C['lilacDeep']))
    out += sign_row(cx, g['sy'], g['bs'], g['sgap'], signs, cur_s)
    out.append(foot(b, 'ring r %d, letter beads %d (%d pt), step %d deg; signs %d; unit %d pt' % (ro, bo, g['font'], g['step'], g['bs'], g['unit'])))
    if mode == 'make':
        x, y, s = g['target']
        out += pebble(x, y, s, speaker(s), fill=C['skyTint'])
        out.append(label(x + s / 2, y + s + 6, 'the target again', '#B23A3A', 10, 'mid'))
        x, y, s = g['check']
        out += check_btn(x, y, s)
        out.append(label(x + s / 2, y + s + 6, '"that\'s it"', '#B23A3A', 10, 'mid'))
    return out


# The Russian strip: the frame card (the consonant, the window, the rest) in the stage, and the vowel strip in the answer zone; the
# vowel in the window is the strip's chosen tile (both framed lilac); a tap on a tile, or a finger slid along the strip, changes it.
LS05S = {
    'phone': dict(cell=88, font=48, tile=88, pin=4, pgap=16, row=264, ctl=72, pic=88),
    'phoneSE': dict(cell=80, font=48, tile=72, pin=4, pgap=12, row=254, ctl=56, pic=72),
    'tabletLandscape': dict(cell=120, font=64, tile=104, pin=6, pgap=24, row=566, ctl=96, pic=140),
    'tabletPortrait': dict(cell=128, font=64, tile=104, pin=6, pgap=24, row=700, ctl=96, pic=160),
}
PAIR_OF = {'а': 0, 'я': 0, 'о': 1, 'ё': 1, 'у': 2, 'ю': 2, 'ы': 3, 'и': 3, 'э': 4, 'е': 4}


def frame_card(x, y, cell, letters, vowel, font, lit=False):
    out = []
    w = len(letters) * cell
    if lit:
        out.append(box(x - 8, y - 8, w + 16, cell + 16, 'border:8px solid rgba(143,211,244,0.55);border-radius:30px'))
    out.append(box(x, y, w, cell, 'background:#fff;border:4px solid %s;border-radius:22px;box-shadow:0 6px 0 %s' % (C['ink'], C['lip'])))
    for i, t in enumerate(letters):
        cx = x + i * cell
        if t == '_':
            out.append(box(cx + 6, y + 6, cell - 12, cell - 12, 'background:%s;border:5px solid %s;border-radius:16px;display:flex;align-items:center;justify-content:center' % (
                '#F6F1FD', C['lilacDeep']), text_span(vowel, 'rus', font, bold=True, lineh=1.0), cls='tilebox'))
        else:
            out.append(box(cx, y, cell, cell, 'display:flex;align-items:center;justify-content:center', text_span(t, 'rus', font, bold=True, lineh=1.0), cls='tilebox'))
    return out


def strip_row(x0, w0, y, tile_s, pin, pgap, parts, cur, font, hit=True):
    """The vowel strip: tiles in their pair order, left to right (always), a pair on one pale pill."""
    widths = []
    for k in range(len(parts)):
        widths.append(tile_s)
    gaps = [pin if PAIR_OF[parts[k]] == PAIR_OF[parts[k - 1]] else pgap for k in range(1, len(parts))]
    total = sum(widths) + sum(gaps)
    x = x0 + (w0 - total) / 2
    xs = []
    for k in range(len(parts)):
        xs.append(x)
        x += tile_s + (gaps[k] if k < len(gaps) else 0)
    out = []
    k = 0
    while k < len(parts):
        j = k
        while j + 1 < len(parts) and PAIR_OF[parts[j + 1]] == PAIR_OF[parts[k]]:
            j += 1
        out.append(box(xs[k] - 6, y - 6, xs[j] + tile_s - xs[k] + 12, tile_s + 12, 'background:%s;border-radius:%dpx' % ('#E4D9F5', tile_s / 3)))
        k = j + 1
    for k, (v, x) in enumerate(zip(parts, xs)):
        on = k == cur
        if on:
            out.append(box(x - 6, y - 11, tile_s + 12, tile_s + 12, 'border:5px solid %s;border-radius:24px' % C['lilacDeep']))
        if hit:
            g = gaps[k] if k < len(gaps) else pin
            out.append(box(x - 2, y - 12, tile_s + 4, tile_s + 24, 'border:1px dotted rgba(108,64,208,0.5);border-radius:18px'))
        out.append(box(x, y - (5 if on else 0), tile_s, tile_s, 'background:#fff;border:4px solid %s;border-radius:20px;box-shadow:0 %dpx 0 %s;display:flex;align-items:center;justify-content:center' % (
            C['hairline'], 6 if on else 4, C['lip']), text_span(v, 'rus', font, bold=True, lineh=1.0), cls='tilebox'))
    return out, xs, total


def ls05_strip(b, frame_text, parts, cur, mode='explore', pics=None, bubble='', title=''):
    course = 'rus'
    B = BOARDS[b]
    g = LS05S[b]
    out = frame(b, bubble, title)
    out += stage_bg(b)
    x0, y0, w0, h0 = stage_inner(b)
    letters = list(frame_text)
    cw = len(letters) * g['cell']
    out += frame_card(x0 + (w0 - cw) / 2, y0 + (h0 - g['cell']) / 2, g['cell'], letters, parts[cur], g['font'])
    out.append(label(x0 + (w0 - cw) / 2, y0 + (h0 - g['cell']) / 2 - 14, 'frame card, cells %d, %d pt' % (g['cell'], g['font']), '#B23A3A', 10))
    zx, zy, zw, zh = B['A']
    ctl = g['ctl']
    word = frame_text.replace('_', parts[cur])
    if mode == 'make':
        sx, sw = zx + ctl + 24, zw - 2 * (ctl + 24)
    elif pics:
        sx, sw = zx, zw - g['pic'] - 24
    else:
        sx, sw = zx, zw
    o, xs, total = strip_row(sx, sw, g['row'], g['tile'], g['pin'], g['pgap'], parts, cur, g['font'])
    out += o
    if mode == 'make':
        y = g['row'] + (g['tile'] - ctl) / 2
        out += pebble(zx + 8, y, ctl, speaker(ctl), fill=C['skyTint'])
        out.append(label(zx + 8 + ctl / 2, y + ctl + 6, 'the target again', '#B23A3A', 10, 'mid'))
        out += check_btn(zx + zw - 8 - ctl, y, ctl)
        out.append(label(zx + zw - 8 - ctl / 2, y + ctl + 6, '"that\'s it"', '#B23A3A', 10, 'mid'))
    elif pics and word in pics:
        p = g['pic']
        out += picture_card(zx + zw - p - 4, g['row'] + (g['tile'] - p) / 2, p, pics[word])
        out.append(label(zx + zw - p / 2 - 4, g['row'] - 18, 'the word made', '#B23A3A', 10, 'mid'))
    out.append(foot(b, 'strip tiles %d, %d inside a pair, %d between pairs; controls %d' % (g['tile'], g['pin'], g['pgap'], ctl)))
    out += zones(b)
    return out


def strip_compact(b, frame_text, parts, cur, hand_at=None):
    """Level 2 of a Russian decoding item (the vowel strip in the stage; the friend slides it, a touch on the frame plays it)."""
    x0, y0, w0, h0 = stage_inner(b)
    tab = BOARDS[b]['tablet']
    cell, tl, font = (52, 48, 36) if not tab else (96, 84, 56)
    out = [sky_card(x0, y0, w0, h0)]
    letters = list(frame_text)
    cw = len(letters) * cell
    top = y0 + (h0 - (cell + 16 + tl)) / 2 + 4
    out += frame_card(x0 + (w0 - cw) / 2, top, cell, letters, parts[cur], font)
    o, xs, total = strip_row(x0, w0, top + cell + 16, tl, 4, 12, parts, cur, font, hit=False)
    out += o
    if hand_at is not None:
        out.append(hand(xs[hand_at] + tl * 0.8, top + cell + 16 + tl * 0.5, 40 if not tab else 70, -30))
    out.append(label(x0 + 6, y0 + 4, 'level 2: the vowel strip (the friend slides it)', '#B23A3A', 10))
    return out


# ================================================================================================================================
# LS04 blend slide
# ================================================================================================================================
# the slide size (a text face of its own, never below the band's stem size) and the knob
LS04 = {
    'phone': dict(t=56, he=46, knob=56, track=8),
    'phoneSE': dict(t=52, he=44, knob=56, track=8),
    'tabletLandscape': dict(t=96, he=80, knob=72, track=10),
    'tabletPortrait': dict(t=96, he=80, knob=72, track=10),
}


def slide_page(b, course, parts, marks, knob_at=0.0, lit=None, done=None, hand_on=False, demo=False, size=None, region=None):
    """The word on its page: the parts at the slide size, a mark under each (a dot under one letter, a bar under a digraph or a
    unit), the marks are beads on a wire (the track) with an arrow at its end, and the knob that the finger slides along it.
    knob_at: 0 at the start dot, 1 at the end. lit: the index of the part now sounding. done: parts already passed."""
    B = BOARDS[b]
    g = LS04[b]
    x0, y0, w0, h0 = region or stage_inner(b)
    out = [box(x0, y0, w0, h0, 'background:#fff;border-radius:20px;border:3px solid %s' % C['hairline'])]
    size = size or (g['he'] if course == 'heb' else g['t'])
    ws = [width(p, course, size) for p in parts]
    total = sum(ws)
    lh = 1.7 if course == 'heb' else 1.3
    lineh = size * lh
    knob = g['knob']
    gap_v = 2
    block_h = lineh + gap_v + knob
    ty = y0 + (h0 - block_h) / 2
    wx = x0 + (w0 - total) / 2
    # part boxes, in the course's direction
    pxs = []
    if rtl(course):
        x = wx + total
        for w in ws:
            x -= w
            pxs.append(x)
    else:
        x = wx
        for w in ws:
            pxs.append(x)
            x += w
    for i, (p, x, w) in enumerate(zip(parts, pxs, ws)):
        on = lit == i
        passed = done is not None and i in done
        if on:
            # the part now sounding: a soft sky column from the letter down to its mark
            out.append(box(x - 4, ty + lineh * 0.22, w + 8, lineh * 0.78 + gap_v + knob / 2 + 12, 'background:%s;border-radius:14px' % C['skyTint']))
        out.append(box(x, ty, w, lineh, 'display:flex;align-items:center;justify-content:center;overflow:visible', text_span(p, course, size, color=C['ink']), cls='tilebox'))
    # the track: a wire through the marks, from the start (the knob's rest) to an arrow at the end
    track_y = ty + lineh + gap_v + knob / 2
    start_x = (wx - knob * 0.75) if not rtl(course) else (wx + total + knob * 0.75)
    end_x = (wx + total + 22) if not rtl(course) else (wx - 22)
    lx, rx = min(start_x, end_x), max(start_x, end_x)
    out.append(box(lx, track_y - g['track'] / 2, rx - lx, g['track'], 'background:%s;border-radius:4px' % C['mist']))
    if not rtl(course):
        out.append('<svg style="position:absolute;left:%.1fpx;top:%.1fpx" width="22" height="26" viewBox="0 0 22 26"><path d="M2 2 L20 13 L2 24 Z" fill="%s"/></svg>' % (end_x - 4, track_y - 13, C['inkSoft']))
    else:
        out.append('<svg style="position:absolute;left:%.1fpx;top:%.1fpx" width="22" height="26" viewBox="0 0 22 26"><path d="M20 2 L2 13 L20 24 Z" fill="%s"/></svg>' % (end_x - 18, track_y - 13, C['inkSoft']))
    joined = demo and done is not None and len(done) == len(parts) and knob_at >= 1.0
    if joined:
        # the whole word heard: the marks join into one bar under the word
        out.append(box(wx + 6, track_y - 7, total - 12, 14, 'border-radius:7px;background:%s;border:3px solid #fff' % C['skyDeep']))
    for i, (x, w, mk) in enumerate(zip(pxs, ws, marks)):
        if joined:
            break
        on = lit == i
        passed = done is not None and i in done
        col = C['skyDeep'] if (on or passed) else C['inkSoft']
        if mk == 'dot':
            d = 20 if on else 16
            out.append(box(x + w / 2 - d / 2, track_y - d / 2, d, d, 'border-radius:50%%;background:%s;border:3px solid #fff' % col))
        else:
            out.append(box(x + 6, track_y - 7, w - 12, 14, 'border-radius:7px;background:%s;border:3px solid #fff' % col))
    # the knob: sea, the clay lip, a white chevron in the course's direction
    kx = start_x + (end_x - 22 * (1 if not rtl(course) else -1) - start_x) * knob_at
    chev = 'M9 6 L17 13 L9 20' if not rtl(course) else 'M17 6 L9 13 L17 20'
    out.append(box(kx - knob / 2, track_y - knob / 2, knob, knob, 'border-radius:50%%;background:%s;box-shadow:0 5px 0 %s;display:flex;align-items:center;justify-content:center' % (C['sea'], C['seaDeep']),
                   '<svg viewBox="0 0 26 26" width="%d" height="%d"><path d="%s" fill="none" stroke="#fff" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/></svg>' % (knob * 0.5, knob * 0.5, chev)))
    out.append(box(kx - knob / 2 - 12, track_y - knob / 2 - 12, knob + 24, knob + 24, 'border-radius:50%;border:1px dotted rgba(108,64,208,0.5)'))
    if hand_on:
        out.append(hand(kx + 4, track_y + 4, 64 if not BOARDS[b]['tablet'] else 84, -20 if not rtl(course) else 20))
    out.append(label(x0 + 8, y0 + 4, 'slide size %d pt, knob %d%s' % (size, knob, ', level 3: the friend slides' if demo else ''), '#B23A3A', 10))
    return out


def pic_options(b, course, pics, states, sounds=False):
    B = BOARDS[b]
    S = SIZES['B'][B['tablet']]
    zx, zy, zw, zh = B['A']
    w = S['tile']
    xs, _ = row_positions([w] * len(pics), zx, zw, S['gapSq'], course)
    out = []
    for x, p, st in zip(xs, pics, states):
        if sounds:
            inner = '<div style="display:flex;align-items:center;justify-content:center">%s</div>' % (SPEAKER_SVG % (52, 52, WAVES if p else ''))
        else:
            inner = '<img src="%s" style="width:%dpx;height:%dpx">' % (uri(os.path.join(PICS, p)), w - 12, w - 12)
        out += tile(x, B['row'], w, w, inner, st, hit=(x - 12, B['row'] - 12, w + 24, w + 24))
    return out, xs, w


def ls04_scene(b, course, mode, parts, marks, options, states, bubble, title, knob_at=0.0, lit=None, done=None, sounds=False,
               hand_on=False, point_to=None, demo=False):
    B = BOARDS[b]
    out = frame(b, bubble, title)
    out += stage_bg(b)
    out += slide_page(b, course, parts, marks, knob_at, lit, done, hand_on=hand_on, demo=demo)
    o, xs, w = pic_options(b, course, options, states, sounds)
    out += o
    if point_to is not None:
        out.append(hand(xs[point_to] + w / 2, B['row'] + w * 0.62, 66 if not B['tablet'] else 84, 0))
    S = SIZES['B'][B['tablet']]
    out.append(foot(b, 'options %d, gap %d' % (w, S['gapSq'])))
    out += zones(b)
    return out


MERGE = {
    'phone': dict(tile=88, track=150, font=48),
    'phoneSE': dict(tile=80, track=86, font=48),
    'tabletLandscape': dict(tile=120, track=220, font=64),
    'tabletPortrait': dict(tile=128, track=300, font=64),
}


def ls04_merge(b, cons, vowel, t=0.0, fused=False, states=('idle', 'idle', 'idle'), bubble='', title='', heard=(True, True, True)):
    """rus `merge`: the consonant tile slides along the track to the vowel tile (left to right, always)."""
    course = 'rus'
    B = BOARDS[b]
    g = MERGE[b]
    out = frame(b, bubble, title)
    out += stage_bg(b)
    x0, y0, w0, h0 = stage_inner(b)
    tl, tr = g['tile'], g['track']
    total = 2 * tl + tr
    sx = x0 + (w0 - total) / 2
    ty = y0 + (h0 - tl) / 2 - 4
    vx = sx + tl + tr
    if not fused:
        # the track: dashed, with an arrow pointing at the vowel
        out.append(box(sx + tl / 2, ty + tl / 2 - 3, tl / 2 + tr, 6, 'background:repeating-linear-gradient(90deg,%s 0 10px,transparent 10px 18px)' % C['lilacDeep']))
        out.append('<svg style="position:absolute;left:%.1fpx;top:%.1fpx" width="22" height="26" viewBox="0 0 22 26"><path d="M2 2 L20 13 L2 24 Z" fill="%s"/></svg>' % (vx - 24, ty + tl / 2 - 13, C['lilacDeep']))
        out += tile(vx, ty, tl, tl, text_span(vowel, course, g['font'], bold=True, lineh=1.2), 'idle')
        cx = sx + tr * t
        if t > 0:
            # the held sound, drawn as a stretch line behind the moving tile
            out.append(box(sx + tl / 2, ty + tl + 8, cx - sx, 6, 'background:%s;border-radius:3px' % C['sea']))
        out += tile(cx, ty, tl, tl, text_span(cons, course, g['font'], bold=True, lineh=1.2), 'chosen' if t > 0 else 'idle')
        out.append(box(cx + tl / 2 - 16, ty + tl - 4, 32, 18, 'border-radius:9px;background:%s' % C['sea']))
        out.append(label(sx, ty - 16, 'tiles %d, track %d; the first tile is dragged (or tapped)' % (tl, tr), '#B23A3A', 10))
    else:
        fw = tl * 1.6
        fx = x0 + (w0 - fw) / 2
        out += tile(fx, ty, fw, tl, text_span(cons + vowel, course, g['font'], bold=True, lineh=1.2), 'correct')
        out.append(label(fx, ty - 16, 'after the choice: the two tiles join, the merged syllable plays', '#B23A3A', 10))
    o, xs, w = pic_options(b, course, list(heard), states, sounds=True)
    out += o
    out.append(foot(b, 'sound buttons %d (LS01 c); the merged syllable only after the choice' % w))
    out += zones(b)
    return out


# ================================================================================================================================
# The text stem with a borrowed hint screen in S (L5 9.5: level 2 the wheel or the strip, level 3 the slide)
# ================================================================================================================================
def mini_wheel(b, items, kind, cur, unit, hand_on=None):
    """Level 2 of a Hebrew decoding item: the same wheel, small, carrying only the part that changes (the letters for LETTER-MIX,
    the signs for VOWEL-SKIP), and the unit made beside it at the stem size. The friend turns it (a demonstration); a touch on the
    unit card plays it again."""
    x0, y0, w0, h0 = stage_inner(b)
    tab = BOARDS[b]['tablet']
    out = [sky_card(x0, y0, w0, h0)]
    if tab:
        ro, bo, step, font = 140, 76, 45, 52
    elif b == 'phoneSE':
        ro, bo, step, font = 54, 40, 50, 30
    else:
        ro, bo, step, font = 70, 48, 45, 34
    R = ro + bo / 2 + 8
    S = SIZES['B'][tab]
    us = S['stem']['he']
    uw = width(unit, 'heb', us) + 40
    uh = us * 1.7 + 8
    group = 2 * R + 14 + uw
    gx = x0 + (w0 - group) / 2
    cx = gx + group - R  # the wheel at the start side (right), the unit it makes after it (left)
    total_h = 18 + bo / 2 + ro + 12
    cy = y0 + (h0 - total_h) / 2 + 18 + bo / 2 + ro
    face = (lambda t, s: text_span(t, 'heb', font, bold=True, lineh=1.0)) if kind == 'letter' else (lambda t, s: sign_face(t, s))
    out += dial(cx, cy, ro, bo, step, items, cur, face, pointer=True, panel_w=2 * R + 8, panel_h=12, hit=False)
    ux = gx
    uy = y0 + (h0 - uh) / 2
    out.append(box(ux, uy, uw, uh, 'background:#fff;border:4px solid %s;border-radius:18px;display:flex;align-items:center;justify-content:center' % C['lilacDeep'], text_span(unit, 'heb', us), cls='tilebox'))
    if hand_on is not None:
        a = math.radians(90 + hand_on * step)
        hx = cx + ro * math.cos(a)
        hy = cy - ro * math.sin(a) + bo * 0.2
        out.append(hand(hx, hy, 48 if not tab else 76, -10))
    out.append(label(x0 + 6, y0 + 2, 'level 2: the wheel on the part missed (the friend turns it)', '#B23A3A', 10))
    return out


def stem_scene(b, course, stem, pics, bubble, title, borrowed=None, states=None, point_to=None):
    B = BOARDS[b]
    out = frame(b, bubble, title)
    out += stage_bg(b)
    out += borrowed
    o, xs, w = pic_options(b, course, pics, states or ['idle'] * len(pics))
    out += o
    if point_to is not None:
        out.append(hand(xs[point_to] + w / 2, B['row'] + w * 0.62, 66 if not B['tablet'] else 84, 0))
    out += zones(b)
    return out


# ================================================================================================================================
# The colour-blind check sheet for the LS03 stamps and chips
# ================================================================================================================================
def cvd_sheet():
    W, H = 1180, 560
    out = [box(0, 0, W, H, 'background:%s;border:1px solid #C9C3D9' % C['cream'])]
    out.append(label(16, 12, 'LS03 colour step: the three stamps and a coloured scheme (кит: soft к, vowel и, hard т), seen as is, in grey, and with the three colour-vision deficiencies', '#2B2350', 14))
    filters = [('as drawn', 'none'), ('greyscale', 'grayscale(1)'), ('deuteranopia (sim.)', 'url(#deut)'), ('protanopia (sim.)', 'url(#prot)'), ('tritanopia (sim.)', 'url(#trit)')]
    svgdefs = ('<svg width="0" height="0" style="position:absolute"><defs>'
               '<filter id="deut"><feColorMatrix type="matrix" values="0.367 0.861 -0.228 0 0  0.280 0.673 0.047 0 0  -0.012 0.043 0.969 0 0  0 0 0 1 0"/></filter>'
               '<filter id="prot"><feColorMatrix type="matrix" values="0.152 1.053 -0.205 0 0  0.115 0.786 0.099 0 0  -0.004 -0.048 1.052 0 0  0 0 0 1 0"/></filter>'
               '<filter id="trit"><feColorMatrix type="matrix" values="1.256 -0.077 -0.179 0 0  -0.078 0.931 0.148 0 0  0.005 0.691 0.304 0 0  0 0 0 1 0"/></filter>'
               '</defs></svg>')
    out.append(svgdefs)
    for i, (name, f) in enumerate(filters):
        x = 16 + i * 232
        inner = []
        for k, kind in enumerate(['vowel', 'hard', 'soft']):
            inner += stamp(10 + k * 72, 20, 60, kind)
        for k, kind in enumerate(['soft', 'vowel', 'hard']):
            inner.append(box(8 + k * 72, 120, 64, 72, 'background:#fff;border:4px solid %s;border-radius:16px' % C['hairline']))
            inner += chip(8 + k * 72 + 6, 120 + 10, 52, kind)
        inner.append('<svg style="position:absolute;left:%dpx;top:%dpx" width="30" height="26" viewBox="0 0 30 26"><path d="M9 22 L22 5" stroke="%s" stroke-width="7" stroke-linecap="round"/></svg>' % (8 + 72 + 32 - 13, 104, C['ink']))
        out.append(box(x, 50, 220, 210, 'background:#fff;border-radius:18px;filter:%s' % f, ''.join(inner)))
        out.append(label(x + 110, 266, name, '#2B2350', 12, 'mid'))
    # the count-step token states
    out.append(label(16, 304, 'Token and place states (count step): every one is a shape or a motion as well as a colour', '#2B2350', 14))
    states = [('next place: dashed', 'next'), ('a token laid', 'laid'), ('not yet: wobble', 'notyet'), ('right: lit, the check', 'correct'), ('hint: a place lit', 'lit'), ('chosen: ring', 'chosen')]
    for i, (name, st) in enumerate(states):
        x = 24 + i * 190
        y = 340
        if st == 'next':
            out.append(box(x, y, 80, 88, 'border:3px dashed %s;border-radius:18px;background:rgba(255,255,255,0.5)' % C['lilacDeep']))
        else:
            if st == 'lit':
                out.append(box(x - 8, y - 8, 96, 104, 'border:8px solid rgba(143,211,244,0.55);border-radius:26px'))
            if st == 'chosen':
                out.append(box(x - 7, y - 7, 94, 102, 'border:4px solid %s;border-radius:24px' % C['ring']))
            bd = {'laid': C['hairline'], 'notyet': C['lilac'], 'correct': C['spark'], 'lit': C['hairline'], 'chosen': C['hairline']}[st]
            out.append(box(x, y, 80, 88, 'background:%s;border:4px solid %s;border-radius:18px;box-shadow:0 4px 0 %s' % (C['sparkTint'] if st == 'correct' else '#fff', bd, C['lip'])))
            out += chip(x + 8, y + 16, 64, None)
            if st == 'notyet':
                out.append(box(x - 13, y + 30, 8, 28, 'border-left:3px solid %s;border-radius:50%%' % C['lilac']))
                out.append(box(x + 85, y + 30, 8, 28, 'border-right:3px solid %s;border-radius:50%%' % C['lilac']))
            if st == 'correct':
                out.append(box(x + 60, y - 10, 30, 30, 'background:%s;border-radius:50%%;display:flex;align-items:center;justify-content:center' % C['spark'], CHECK_SVG))
        out.append(label(x + 40, y + 100, name, '#2B2350', 11, 'mid'))
    out.append(label(16, 470, 'Stress (rus B-17): the stress sign stands over the chosen vowel; only the vowel chips are raised (lifted, with the lip) in that step.', '#5A5378', 12))
    out.append(label(16, 490, 'Marks: vowel = a note (it can be sung), hard = a square block, soft = a smile. They tell the three apart in grey and under every simulation.', '#5A5378', 12))
    return out, W, H


# ================================================================================================================================
def strings():
    s = set()
    for t in ['sun', 'pot', 'sh', 'p', 'o', 't', 'к', 'и', 'т', 'м', 'а', 'ма', 'л', 'ы', 'я', 'о', 'у', 'ё', 'ю', 'е', 'э', 'р', 'б', 'с']:
        s.add(('L', 500, t))
        s.add(('L', 700, t))
    for t in ['אַ', 'בָּא', 'אַבָּא', 'שָׁ', 'ר', 'שָׁר', 'לָ', 'ל', 'רָ', 'מ', 'שׁ', 'א', 'בּ', 'ת', 'מָ', 'בָּ', 'נָ', 'נָה', 'בָּנָנָה', 'שָׁא']:
        s.add(('H', 500, t))
        s.add(('H', 700, t))
    return s


def main():
    m.measure(strings())
    P = os.path.join(HERE)
    # ---------------- LS03 ----------------
    eng_kinds = ['c', 'vowel', 'c']
    sheets = []
    a = [
        (ls03_scene('phone', 'eng', 'sun', 'sun.svg', 'count', 2, bubble='עִגּוּל לְכָל צְלִיל.', title='LS03 boxes, count step (eng sun, phonemes)'), *W_['phone']),
        (ls03_scene('phone', 'heb', 'בָּנָנָה', 'banana.svg', 'count', 2, bubble='עִגּוּל לְכָל חֵלֶק.', title='LS03 boxes, count step (heb, CV units, right to left)'), *W_['phone']),
        (ls03_scene('phoneSE', 'rus', 'кит', 'whale.svg', 'count', 3, bubble='עִגּוּל לְכָל צְלִיל.', title='LS03 count (rus кит), three laid'), *W_['phoneSE']),
        (ls03_scene('phoneSE', 'eng', 'sun', 'sun.svg', 'count', 4, bubble='עִגּוּל לְכָל צְלִיל.', title='not yet: one more (n=4)', notyet=[0, 1, 2, 3]), *W_['phoneSE']),
    ]
    m.page(a, os.path.join(P, 'ls03_count_phones.png'), 1780)
    rus_kit = ['soft', 'vowel', 'hard']
    a = [
        (ls03_scene('phone', 'rus', 'кит', 'whale.svg', 'colour', 3, kinds=rus_kit, colours=['soft', 'vowel', None], chosen_stamp='hard', bubble='צִבְעוּ אֶת הָעִגּוּלִים.', title='LS03 colour step (rus кит): blue stamp chosen'), *W_['phone']),
        (ls03_scene('phoneSE', 'rus', 'рыба', 'fish.svg', 'colour', 4, kinds=['hard', 'vowel', 'hard', 'vowel'], colours=['hard', 'vowel', None, None], chosen_stamp='hard', bubble='צִבְעוּ אֶת הָעִגּוּלִים.', title='LS03 colour (rus рыба)'), *W_['phoneSE']),
        (ls03_scene('phone', 'rus', 'рыба', 'fish.svg', 'stress', 4, kinds=['hard', 'vowel', 'hard', 'vowel'], colours=['hard', 'vowel', 'hard', 'vowel'], stress=1, bubble='אֵיזֶה צְלִיל חָזָק?', title='LS03 stress step (rus B-17): vowels raised'), *W_['phone']),
        (ls03_scene('phoneSE', 'eng', 'sun', 'sun.svg', 'which', 3, bubble='בְּאֵיזוֹ קֻפְסָה הַצְּלִיל?', title='LS03 which box (eng /n/)', which_lit=2), *W_['phoneSE']),
    ]
    m.page(a, os.path.join(P, 'ls03_colour_stress_which_phones.png'), 1780)
    a = [
        (ls03_scene('tabletLandscape', 'rus', 'кит', 'whale.svg', 'colour', 3, kinds=rus_kit, colours=['soft', None, None], chosen_stamp='vowel', bubble='צִבְעוּ אֶת הָעִגּוּלִים.', title='LS03 colour (rus кит)'), *W_['tabletLandscape']),
        (ls03_scene('tabletLandscape', 'eng', 'sun', 'sun.svg', 'which', 3, bubble='בְּאֵיזוֹ קֻפְסָה הַצְּלִיל?', title='LS03 which box (eng)'), *W_['tabletLandscape']),
    ]
    m.page(a, os.path.join(P, 'ls03_tabletLandscape.png'), 2400)
    a = [
        (ls03_scene('tabletPortrait', 'heb', 'בָּנָנָה', 'banana.svg', 'count', 2, bubble='עִגּוּל לְכָל חֵלֶק.', title='LS03 count (heb, right to left)'), *W_['tabletPortrait']),
        (ls03_scene('tabletPortrait', 'rus', 'рыба', 'fish.svg', 'stress', 4, kinds=['hard', 'vowel', 'hard', 'vowel'], colours=['hard', 'vowel', 'hard', 'vowel'], stress=1, bubble='אֵיזֶה צְלִיל חָזָק?', title='LS03 stress (rus)'), *W_['tabletPortrait']),
    ]
    m.page(a, os.path.join(P, 'ls03_tabletPortrait.png'), 1700)
    a = [
        (ls03_scene('phone', 'eng', 'sun', 'sun.svg', 'count', 1, bubble='הִסְתַּכְּלוּ עַל הַפֶּה.', title='LS03 count, hint level 2 (phonemes: mouths)', hint=2, mouths=['mouth-teeth.svg', 'mouth-round.svg', 'mouth-tongue.svg'], hint_lit=1), *W_['phone']),
        (ls03_scene('phoneSE', 'heb', 'בָּנָנָה', 'banana.svg', 'count', 0, bubble='מוֹחֲאִים כַּפַּיִם.', title='hint 2 (CV units: claps)', hint=2, hint_units=[1, 2, 3], hint_lit=2), *W_['phoneSE']),
        (ls03_scene('phone', 'eng', 'sun', 'sun.svg', 'count', 0, bubble='הַקְשִׁיבוּ לְאַט.', title='LS03 count, hint level 1 (the word slowly)', hint=1), *W_['phone']),
        (ls03_hint3('phoneSE', 'eng'), *W_['phoneSE']),
    ]
    m.page(a, os.path.join(P, 'ls03_hints.png'), 1780)
    st, sw, sh = cvd_sheet()
    m.page([(st, sw, sh)], os.path.join(P, 'ls03_colour_marks_cvd.png'), 1200)

    # ---------------- LS05 ----------------
    S1L = ['מ', 'ל', 'שׁ', 'ר', 'א', 'בּ', 'ת']
    S1S = ['qamats', 'patah', 'none']
    a = [
        (ls05_wheel('phone', S1L, S1S, 1, 0, 'explore', bubble='סוֹבְבוּ אֶת הַגַּלְגַּל, וְהַקְשִׁיבוּ.', title='LS05 the wheel, explore (heb S1)'), *W_['phone']),
        (ls05_wheel('phoneSE', ['ל', 'ר'], ['qamats', 'none'], 1, 1, 'make', bubble='סוֹבְבוּ עַד שֶׁתִּשְׁמְעוּ:', title='LS05 the wheel, make (heb B-19.4)'), *W_['phoneSE']),
        (ls05_wheel('phoneSE', S1L, S1S, 0, 0, 'explore', bubble='סוֹבְבוּ אֶת הַגַּלְגַּל.', title='LS05 the wheel, explore'), *W_['phoneSE']),
        (ls05_wheel('phone', ['ל', 'ר'], ['qamats', 'none'], 0, 0, 'make', bubble='סוֹבְבוּ עַד שֶׁתִּשְׁמְעוּ:', title='LS05 make: the target made', lit_hub=True), *W_['phone']),
    ]
    m.page(a, os.path.join(P, 'ls05_wheel_phones.png'), 1780)
    a = [
        (ls05_wheel('tabletLandscape', S1L, S1S, 2, 0, 'explore', bubble='סוֹבְבוּ אֶת הַגַּלְגַּל, וְהַקְשִׁיבוּ.', title='LS05 wheel explore'), *W_['tabletLandscape']),
        (ls05_wheel('tabletPortrait', ['ל', 'ר'], ['qamats', 'none'], 0, 1, 'make', bubble='סוֹבְבוּ עַד שֶׁתִּשְׁמְעוּ:', title='LS05 wheel make'), *W_['tabletPortrait']),
    ]
    m.page(a, os.path.join(P, 'ls05_wheel_tablets.png'), 2060)
    a = [
        (ls05_strip('phone', 'к_т', ['о', 'и'], 1, 'explore', pics={'кот': 'cat.svg', 'кит': 'whale.svg'}, bubble='הַזִּיזוּ אֶת הַפַּס, וְהַקְשִׁיבוּ.', title='LS05 the vowel strip, explore (rus кот / кит)'), *W_['phone']),
        (ls05_strip('phone', 'л_', ['а', 'я', 'ы', 'и'], 2, 'make', bubble='עֲשׂוּ אֶת מָה שֶׁשְּׁמַעְתֶּם.', title='LS05 strip, make (rus B-21: ли)'), *W_['phone']),
        (ls05_strip('phoneSE', 'л_', ['а', 'я', 'ы', 'и'], 3, 'make', bubble='עֲשׂוּ אֶת מָה שֶׁשְּׁמַעְתֶּם.', title='LS05 strip, make (rus)'), *W_['phoneSE']),
        (ls05_strip('phoneSE', 'к_т', ['о', 'и'], 0, 'explore', pics={'кот': 'cat.svg', 'кит': 'whale.svg'}, bubble='הַזִּיזוּ אֶת הַפַּס.', title='LS05 strip explore'), *W_['phoneSE']),
    ]
    m.page(a, os.path.join(P, 'ls05_strip_phones.png'), 1780)
    a = [
        (ls05_strip('tabletLandscape', 'м_', ['а', 'я', 'о', 'ё', 'у', 'ю'], 2, 'explore', bubble='הַזִּיזוּ אֶת הַפַּס, וְהַקְשִׁיבוּ.', title='LS05 strip explore (rus м_)'), *W_['tabletLandscape']),
        (ls05_strip('tabletPortrait', 'л_', ['а', 'я', 'ы', 'и'], 3, 'make', bubble='עֲשׂוּ אֶת מָה שֶׁשְּׁמַעְתֶּם.', title='LS05 strip make'), *W_['tabletPortrait']),
    ]
    m.page(a, os.path.join(P, 'ls05_strip_tablets.png'), 2060)
    # as level 2 of a decoding item (L5 5.9): the wheel (heb) and the strip (rus) take the stage's place, the options stay live
    a = [
        (stem_scene('phone', 'heb', 'שָׁר', ['girl-sing.svg', 'cat.svg', 'fish.svg'], 'קִרְאוּ וּבַחֲרוּ תְּמוּנָה.', 'LS01 text stem, hint 2 = the wheel (VOWEL-SKIP: the signs turn)',
                    borrowed=mini_wheel('phone', ['none', 'qamats'], 'sign', 1, 'שָׁ', hand_on=-1)), *W_['phone']),
        (stem_scene('phoneSE', 'heb', 'שָׁר', ['girl-sing.svg', 'cat.svg', 'fish.svg'], 'קִרְאוּ וּבַחֲרוּ.', 'hint 2 = the wheel (LETTER-MIX: the letters turn)',
                    borrowed=mini_wheel('phoneSE', ['שׁ', 'ר'], 'letter', 0, 'שָׁ')), *W_['phoneSE']),
        (stem_scene('phone', 'rus', 'ма', ['cow.svg', 'cat.svg', 'fish.svg'], 'קִרְאוּ וּבַחֲרוּ.', 'LS01 text stem, hint 2 = the vowel strip (rus B-19)',
                    borrowed=strip_compact('phone', 'м_', ['а', 'о', 'у'], 0, hand_at=1)), *W_['phone']),
        (stem_scene('tabletLandscape', 'heb', 'שָׁר', ['girl-sing.svg', 'cat.svg', 'fish.svg'], 'קִרְאוּ וּבַחֲרוּ תְּמוּנָה.', 'hint 2 = the wheel (tablet)',
                    borrowed=mini_wheel('tabletLandscape', ['none', 'qamats'], 'sign', 1, 'שָׁ', hand_on=-1)), *W_['tabletLandscape']),
    ]
    m.page(a, os.path.join(P, 'ls05_as_hint.png'), 2060)

    # ---------------- LS04 ----------------
    a = [
        (ls04_scene('phone', 'eng', 'graphemes', ['p', 'o', 't'], ['dot', 'dot', 'dot'], ['pot.svg', 'top.svg', 'pig.svg'], ['idle'] * 3,
                    'הַחְלִיקוּ מִשְּׂמֹאל לְיָמִין.', 'LS04 graphemes (eng pot): mid-slide, o sounding', knob_at=0.55, lit=1, done=[0]), *W_['phone']),
        (ls04_scene('phoneSE', 'eng', 'graphemes', ['p', 'o', 't'], ['dot', 'dot', 'dot'], ['pot.svg', 'top.svg', 'pig.svg'], ['idle'] * 3,
                    'הַחְלִיקוּ מִשְּׂמֹאל לְיָמִין.', 'LS04 graphemes, at rest'), *W_['phoneSE']),
        (ls04_scene('phone', 'eng', 'graphemes', ['sh', 'o', 'p'], ['bar', 'dot', 'dot'], ['pot.svg', 'top.svg', 'pig.svg'], ['idle'] * 3,
                    'הַחְלִיקוּ מִשְּׂמֹאל לְיָמִין.', 'a digraph: one bar under sh (Band C sample)', knob_at=0.15, lit=0), *W_['phone']),
        (ls04_scene('phoneSE', 'eng', 'graphemes', ['p', 'o', 't'], ['dot', 'dot', 'dot'], ['pot.svg', 'top.svg', 'pig.svg'], ['correct', 'dim', 'dim'],
                    'אֵיזוֹ מִלָּה זֹאת?', 'after the choice: the whole word', knob_at=1.0, done=[0, 1, 2]), *W_['phoneSE']),
    ]
    m.page(a, os.path.join(P, 'ls04_graphemes_phones.png'), 1780)
    a = [
        (ls04_scene('tabletLandscape', 'eng', 'graphemes', ['p', 'o', 't'], ['dot', 'dot', 'dot'], ['pot.svg', 'top.svg', 'pig.svg'], ['idle'] * 3,
                    'הַחְלִיקוּ מִשְּׂמֹאל לְיָמִין.', 'LS04 graphemes', knob_at=0.55, lit=1, done=[0]), *W_['tabletLandscape']),
        (ls04_scene('tabletPortrait', 'eng', 'graphemes', ['p', 'o', 't'], ['dot', 'dot', 'dot'], ['pot.svg', 'top.svg', 'pig.svg'], ['idle'] * 3,
                    'הַחְלִיקוּ מִשְּׂמֹאל לְיָמִין.', 'LS04 graphemes'), *W_['tabletPortrait']),
    ]
    m.page(a, os.path.join(P, 'ls04_graphemes_tablets.png'), 2060)
    a = [
        (ls04_merge('phone', 'м', 'а', 0.55, bubble='הַחְלִיקוּ לְפִי הַחֵץ.', title='LS04 merge (rus ма): м held as it slides'), *W_['phone']),
        (ls04_merge('phoneSE', 'м', 'а', 0.0, bubble='הַחְלִיקוּ לְפִי הַחֵץ.', title='LS04 merge, at rest', heard=(False, False, False)), *W_['phoneSE']),
        (ls04_merge('phone', 'м', 'а', fused=True, states=('correct', 'dim', 'dim'), bubble='מָה שְׁמַעְתֶּם?', title='after the choice: joined'), *W_['phone']),
        (ls04_merge('phoneSE', 'м', 'а', 1.0, states=('idle', 'chosen', 'idle'), bubble='מָה שְׁמַעְתֶּם?', title='the choice (3 sound buttons)'), *W_['phoneSE']),
    ]
    m.page(a, os.path.join(P, 'ls04_merge_phones.png'), 1780)
    a = [
        (ls04_merge('tabletLandscape', 'м', 'а', 0.5, bubble='הַחְלִיקוּ לְפִי הַחֵץ.', title='LS04 merge'), *W_['tabletLandscape']),
        (ls04_merge('tabletPortrait', 'м', 'а', 0.0, bubble='הַחְלִיקוּ לְפִי הַחֵץ.', title='LS04 merge'), *W_['tabletPortrait']),
    ]
    m.page(a, os.path.join(P, 'ls04_merge_tablets.png'), 2060)
    # the Hebrew level-3 demonstration (units), inside the text stem of a decoding item
    fam = ['fam-father.svg', 'fam-grandfather.svg', 'fam-mother.svg']

    def units_demo(b, k, lit, done, point=None, states=None, bubble='תִּרְאוּ אֵיךְ.'):
        return stem_scene(b, 'heb', 'אַבָּא', fam, bubble, 'LS04 units as hint level 3 (heb B-20 אַבָּא)',
                          borrowed=slide_page(b, 'heb', ['אַ', 'בָּא'], ['bar', 'bar'], k, lit, done, hand_on=(point is None), demo=True),
                          states=states, point_to=point)
    a = [
        (units_demo('phone', 0.28, 0, [], None), *W_['phone']),
        (units_demo('phoneSE', 1.0, None, [0, 1], 0, ['lit', 'idle', 'idle']), *W_['phoneSE']),
        (units_demo('tabletLandscape', 0.7, 1, [0], None), *W_['tabletLandscape']),
        (units_demo('tabletPortrait', 1.0, None, [0, 1], 0, ['lit', 'idle', 'idle']), *W_['tabletPortrait']),
    ]
    m.page(a[:2], os.path.join(P, 'ls04_units_l3_phones.png'), 1560)
    m.page(a[2:], os.path.join(P, 'ls04_units_l3_tablets.png'), 2060)


if __name__ == '__main__':
    main()
