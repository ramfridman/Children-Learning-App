"""F6 for Hebrew: the 22 letters and 5 finals in print (כתב דפוס, Band B: B-24 to B-26) and in the school script (כתב יד,
Band C: C-25 to C-27), on the hanging top line, with the ascender of ל and the "basement" for ק ך ן ף ץ. Print paths
are centre lines inside Heebo 700 (the app's Hebrew letter tiles; fonts.md section 2). Script has no font: these paths ARE
the script letters (fonts.md section 5), drawn once and used for the static letter, the print-script match, tracing and
the stroke animation. Built by tools/make_letter_strokes.py; format in docs/languages/strokes.md.
Status of both sets: needs-teacher (hebrew-language-teacher).

References looked at on 2026-11-04 (facts only; every path is our own, nothing traced):
  Print (direction and order):
  - Israeli kindergarten and first-grade print-formation charts, all three agreeing: the gan-li.co.il ruler "סרגל צורת
    כתיבת אותיות הדפוס" (א to ה with numbered arrows), the "עט לכתוב" poster "צורת הכתיבה – אותיות דפוס" (all 27 forms
    with numbered arrows; read letter by letter at 3x zoom), and the workbook "ראשית כתיבה – כיווני האותיות דפוס"
    (cashcow.co.il pages; ב with numbered start dots). What they teach: every stroke starts at the top; a line along the
    top goes LEFT TO RIGHT; a down stroke goes top to bottom; a base goes RIGHT TO LEFT (ב's base, which sticks out to the
    right, goes left to right); a corner is turned without lifting (ב: across, then down; כ נ ר ד: across then down);
    a detached part (ה ק left leg, the inner hook of פ ף) is its own stroke, drawn after the main shape; ס goes round
    clockwise from its top-left; the order runs from the top line down and the right side before the left.
  - The Ministry's line "right to left and top to bottom" (hebrew/band-a-content.md, A-14 notes) as the order of a word.
  - Heebo 700's own shapes: each glyph measured in Chrome (canvas measureText on app/assets/fonts/Heebo-Variable.ttf at
    weight 700) and drawn on a 50-unit grid, so every centre line sits inside the tile letter (checked with --fit).
  Script (shapes and direction groups):
  - The handwriting set of Wikimedia Commons ("Hebrew letter ... handwriting.svg", the 27 forms on the Wikipedia page
    "Cursive Hebrew"), the yo-yoo.co.il print/script chart "סרגל אותיות כתב ודפוס", and the "עיצוב בחינוך" practice
    sheet "אותיות כתב" (scribd), whose green start marks show where א ב ג ד ה begin.
  - The teacher's direction groups (hebrew/syllabus.md, C-26): arch ר ה ת ח ק ב; falling י ו מ נ ן; "the rest (shapes
    from the design-director)". The arch letters start on the LEFT and go over the top clockwise (the sheet's start marks
    for ב and ה); the c-like curves (the right part of א, ס, ט) go anticlockwise, as the numerals do in the app.
Choices the teacher checks are listed in docs/languages/strokes.md section 5.3.
"""
import types

from make_letter_strokes import Form, S, top_start

METRICS = {'א': (47, 641, 594, 0), 'ב': (16, 531, 594, 0), 'ג': (0, 391, 594, 16), 'ד': (16, 531, 594, 0), 'ה': (63, 563, 594, 0), 'ו': (31, 250, 594, 0), 'ז': (31, 359, 594, 0), 'ח': (78, 578, 594, 0), 'ט': (78, 594, 594, 16), 'י': (16, 266, 594, -250), 'כ': (31, 484, 594, 16), 'ך': (31, 438, 594, 203), 'ל': (31, 516, 750, 0), 'מ': (47, 609, 609, 0), 'ם': (78, 578, 594, 0), 'נ': (16, 328, 594, 16), 'ן': (31, 234, 594, 203), 'ס': (31, 594, 609, 16), 'ע': (16, 547, 594, 16), 'פ': (63, 578, 594, 16), 'ף': (63, 547, 594, 203), 'צ': (16, 563, 594, 0), 'ץ': (16, 563, 594, 203), 'ק': (78, 578, 594, 203), 'ר': (16, 438, 594, 0), 'ש': (78, 781, 594, 31), 'ת': (0, 578, 594, 16)}

EM, BASE = 92.0, 76.0
NAMES = dict(zip('אבגדהוזחטיכךלמםנןסעפףצץקרשת',
                 ['alef', 'bet', 'gimel', 'dalet', 'he', 'vav', 'zayin', 'het', 'tet', 'yod', 'kaf', 'kaf-final', 'lamed', 'mem',
                  'mem-final', 'nun', 'nun-final', 'samekh', 'ayin', 'pe', 'pe-final', 'tsadi', 'tsadi-final', 'qof', 'resh',
                  'shin', 'tav']))
FINALS = 'ךםןףץ'


def _line(units):
    return round(BASE - units * EM / 1000.0, 1)


GUIDES = {'ascender': _line(750), 'top': _line(594), 'base': BASE, 'basement': _line(-203)}
T, B, A, BM = 'top', 'base', 'ascender', 'basement'
SHORT = {'kind': 'short'}


def _head(name, font, inset):
    h = {'set': name, 'courses': ['heb'], 'review': 'needs-teacher', 'reviewer': 'hebrew-language-teacher', 'box': 100, 'ink': 9,
         'em': EM, 'baseline': BASE, 'guides': dict(GUIDES), 'solidGuides': ['top', 'base'], 'inset': inset,
         'direction': 'rtl', 'generator': 'tools/make_letter_strokes.py (paths: tools/strokes_hebrew.py)'}
    if font:
        h['font'] = {'family': 'Heebo', 'weight': 700, 'file': 'app/assets/fonts/Heebo-Variable.ttf', 'css': 'HB'}
        h['metrics'] = METRICS
    return h


def heb(prefix, ch, sits, *strokes, **meta):
    return Form('%s.%s' % (prefix, NAMES[ch]), ch, list(strokes), sits, name=NAMES[ch], final=ch in FINALS, **meta)


# ---------------------------------------------------------------------------------------------------- print (Heebo 700)
def p(ch, sits, *strokes, **meta):
    return heb('hebrew-print', ch, sits, *strokes, **meta)


PRINT_FORMS = [
    p('א', (T, B), S('M 128 545 L 535 48'), S('M 545 545 C 540 460 505 410 430 360', **SHORT),
      S('M 290 352 C 200 300 145 250 142 180 L 142 40')),
    p('ב', (T, B), S('M 80 524 L 310 524 C 360 524 383 495 383 445 L 383 70'), S('M 60 56 L 490 56')),
    p('ג', (T, None), S('M 105 524 L 268 524 L 268 300 L 322 40'), S('M 262 230 C 230 120 160 62 45 60')),
    p('ד', (T, B), S('M 60 524 L 485 524'), S('M 347 524 L 347 40')),
    p('ה', (T, B), S('M 105 524 L 360 524 C 430 524 478 480 478 410 L 478 40'), S('M 140 290 L 140 40', **SHORT)),
    p('ו', (T, B), S('M 70 524 L 163 524 L 163 40')),
    p('ז', (T, B), S('M 75 524 L 320 524', **SHORT), S('M 150 524 L 212 40')),
    p('ח', (T, B), S('M 150 524 L 380 524 C 440 524 488 480 488 420 L 488 40'), S('M 150 524 L 150 40')),
    p('ט', (T, B), S('M 316 482 C 322 530 370 545 420 545 C 480 545 513 500 513 430 L 513 240 C 513 120 440 48 332 48 '
                     'C 225 48 152 120 152 205'), S('M 152 545 L 152 215')),
    p('י', (T, None), S('M 60 524 L 184 524 L 184 290')),
    p('כ', (T, B), S('M 90 524 L 394 524 L 394 220 C 394 110 330 56 220 56 L 75 56')),
    p('ך', (T, BM), S('M 70 524 L 365 524 L 365 -165')),
    p('ל', (A, B), S('M 101 715 L 101 524 L 450 524 L 231 40')),
    p('מ', (T, B), S('M 70 500 C 150 540 250 556 330 556 C 450 556 521 480 521 380 L 521 56 L 390 56'),
      S('M 205 470 C 185 360 165 200 150 40')),
    p('ם', (T, B), S('M 152 524 L 500 524 L 500 56 L 165 56'), S('M 152 524 L 152 56')),
    p('נ', (T, B), S('M 95 524 L 243 524 L 243 170 C 243 90 200 56 130 56 L 60 56')),
    p('ן', (T, BM), S('M 70 524 L 157 524 L 157 -165')),
    p('ס', (T, B), S('M 60 495 C 140 530 230 545 300 545 C 440 545 515 470 515 330 L 515 250 C 515 120 430 52 300 52 '
                     'C 190 52 143 120 143 230 L 143 420')),
    p('ע', (T, B), S('M 468 545 L 468 230 C 468 110 380 45 260 45 C 170 45 100 55 50 75'), S('M 130 545 L 262 100')),
    p('פ', (T, B), S('M 95 524 L 400 524 C 460 524 503 480 503 420 L 503 220 C 503 110 430 56 300 56 L 110 56'),
      S('M 125 467 C 105 420 100 330 130 290 C 160 250 220 240 275 240')),
    p('ף', (T, BM), S('M 100 524 L 470 524 L 470 -165'), S('M 118 467 C 100 400 98 300 120 268 C 150 240 220 240 280 245')),
    p('צ', (T, B), S('M 100 545 L 480 56 L 90 56'), S('M 474 545 L 340 285')),
    p('ץ', (T, BM), S('M 100 545 L 300 330 C 330 290 344 250 344 200 L 344 -165'), S('M 472 545 L 330 340', **SHORT)),
    p('ק', (T, BM), S('M 115 524 L 400 524 C 460 524 492 480 492 420 L 492 240 C 492 120 420 56 320 56 L 290 56'),
      S('M 160 300 L 160 -165')),
    p('ר', (T, B), S('M 55 524 L 250 524 C 310 524 353 480 353 420 L 353 40')),
    p('ש', (T, B), S('M 707 545 L 707 260 C 707 120 600 45 450 45 C 330 45 230 70 151 105'), S('M 151 545 L 151 110'),
      S('M 428 545 L 428 300 C 428 250 415 215 395 190')),
    p('ת', (T, B), S('M 90 524 L 400 524 C 465 524 503 480 503 410 L 503 40'),
      S('M 235 480 C 195 425 178 360 178 300 L 178 170 C 178 90 140 56 90 56 L 45 56')),
]

PRINT = types.SimpleNamespace(SET=_head('hebrew-print', True, 5.2), FORMS=PRINT_FORMS, start_rule=top_start)


# ---------------------------------------------------------------------------------------------------- script (our model)
ARCH = 'arch'          # the teacher's group: start on the left, over the top clockwise, down the right (ר ה ת ח ק ב)
FALL = 'falling'       # the teacher's group: falling from the top (י ו מ נ ן)
ROUND = 'round'        # proposed: a c-like curve, anticlockwise from the top (א ס ט ש ם)
WAVE = 'wave'          # proposed: two bowls one under the other, like a 3 (ג ז ד צ)
LOOP = 'loop'          # proposed: a loop or curl at the top or bottom (ל ע ף ץ)
TEACHER_GROUPS = {ARCH: 'ר ה ת ח ק ב', FALL: 'י ו מ נ ן'}
MIDDLE = 'ש is written like an e: it starts in the middle, goes up and round'
FOOT = 'an arch letter that starts at its foot, bottom left, and goes up and over (the arch movement)'


def s(ch, group, sits, *strokes, **meta):
    proposed = not (group in TEACHER_GROUPS and ch in TEACHER_GROUPS[group])
    return heb('hebrew-script', ch, sits, *strokes, group=group, groupProposed=proposed, **meta)


SCRIPT_FORMS = [
    s('א', ROUND, (T, B), S('A 420 300 150 235 50 310'), S('M 235 575 L 115 55')),
    s('ב', ARCH, (T, B), S('M 120 470 C 150 550 240 568 320 568 C 440 568 500 500 500 380 L 500 120 C 500 70 470 45 430 45 L 60 45')),
    s('ג', WAVE, (T, B), S('M 170 520 C 230 575 380 580 400 500 C 420 420 280 360 200 300 C 120 240 100 120 180 70 C 260 30 420 40 540 70')),
    s('ד', WAVE, (T, B), S('M 120 560 L 360 560 C 420 560 440 520 400 480 L 280 380 C 380 370 440 310 440 230 C 440 130 370 60 290 55')),
    s('ה', ARCH, (T, B), S('M 110 480 C 140 550 230 568 310 568 C 430 568 490 500 490 380 L 490 45'), S('M 150 330 L 150 45')),
    s('ו', FALL, (T, B), S('M 320 568 L 290 45')),
    s('ז', WAVE, (T, B), S('M 180 520 C 240 575 380 575 390 490 C 400 420 300 370 240 300 C 190 240 180 140 230 45')),
    s('ח', ARCH, (T, B), S('M 120 45 L 120 400 C 120 510 200 568 300 568 C 420 568 480 500 480 380 L 480 45', startOk=FOOT)),
    s('ט', ROUND, (T, B), S('M 260 568 C 160 450 110 300 150 160 C 190 50 380 30 450 130 C 490 190 480 280 440 330')),
    s('י', FALL, (T, None), S('M 300 568 L 280 390', **SHORT)),
    s('כ', ARCH, (T, B), S('M 140 520 C 200 570 300 570 360 560 C 460 540 500 460 500 300 C 500 140 420 50 300 45 C 230 42 170 55 120 80')),
    s('ך', ARCH, (T, BM), S('M 120 520 C 180 568 260 568 330 568 C 440 568 480 510 480 420 L 480 -165')),
    s('ל', LOOP, (A, B), S('M 480 700 C 440 760 340 760 300 690 C 260 620 250 450 240 250 C 235 130 200 50 140 45 '
                          'C 90 42 70 90 90 140 C 110 190 160 200 210 180')),
    s('מ', FALL, (T, B), S('M 480 568 L 360 45 L 220 568 L 100 45')),
    s('ם', ROUND, (T, B), S('M 420 545 C 340 575 200 575 150 480 C 100 380 100 200 160 110 C 220 30 380 30 440 110 '
                           'C 500 190 500 390 480 450 C 465 500 450 525 428 540')),
    s('נ', FALL, (T, B), S('M 220 540 C 260 570 320 560 330 520 L 330 140 C 330 70 280 45 200 45 L 100 45')),
    s('ן', FALL, (T, BM), S('M 300 568 L 290 -165')),
    s('ס', ROUND, (T, B), S('A 300 306 190 262 90 450')),
    s('ע', LOOP, (T, B), S('M 470 540 C 420 360 300 200 260 120 C 230 60 280 30 320 70 C 360 110 300 300 150 540', loop=True)),
    s('פ', ARCH, (T, B), S('M 150 470 C 190 550 260 568 320 568 C 440 568 500 480 500 320 C 500 150 420 45 300 45 '
                          'C 190 45 120 110 120 200 C 120 280 180 320 250 310 C 300 300 320 260 300 220')),
    s('ף', LOOP, (T, BM), S('M 330 440 C 250 450 180 500 200 560 C 220 620 380 620 400 540 C 420 460 300 420 270 330 L 255 -165')),
    s('צ', WAVE, (T, B), S('M 130 500 C 170 560 240 568 300 568 C 400 568 450 520 450 450 C 450 380 390 330 300 320 '
                          'C 410 310 470 250 470 170 C 470 80 390 45 290 45 C 210 45 150 55 110 80')),
    s('ץ', LOOP, (T, BM), S('M 160 560 C 180 440 250 380 330 360 C 420 340 460 420 420 480 C 380 540 300 470 290 380 L 270 -165', loop=True)),
    s('ק', ARCH, (T, BM), S('M 120 520 C 170 568 250 568 320 568 C 430 568 490 500 490 400 L 490 200'), S('M 180 380 L 180 -165')),
    s('ר', ARCH, (T, B), S('M 110 500 C 160 560 230 568 300 568 C 420 568 480 500 480 400 L 480 45')),
    s('ש', ROUND, (T, B), S('M 130 290 C 250 300 420 380 420 470 C 420 540 350 568 290 568 C 180 568 92 450 92 300 '
                           'C 92 140 200 45 320 45 C 400 45 460 70 500 110', startOk=MIDDLE)),
    s('ת', ARCH, (T, B), S('M 60 45 C 120 45 160 80 170 160 C 180 300 200 520 300 565 C 400 600 480 520 480 400 L 480 45', startOk=FOOT)),
]


def script_start(form, i, st):
    """Arch letters start on the left of the letter (the first stroke); every other stroke starts at its top."""
    if form.get('group') == ARCH and i == 0:
        xs = [q[0] for q in st['_dense']]
        if st['_dense'][0][0] > (min(xs) + max(xs)) / 2:
            return 'an arch letter starts on the left and goes over the top; this one starts on the right'
        if st.get('startOk'):
            return None
    return top_start(form, i, st)


SCRIPT = types.SimpleNamespace(SET=_head('hebrew-script', False, 3.5), FORMS=SCRIPT_FORMS, start_rule=script_start)
SCRIPT.SET['groups'] = {ARCH: 'start on the left, over the top clockwise, down the right (the teacher\'s arch group)',
                        FALL: 'fall from the top (the teacher\'s falling group)',
                        ROUND: 'proposed: a c-like curve, anticlockwise from the top',
                        WAVE: 'proposed: two bowls one under the other, like a 3',
                        LOOP: 'proposed: a loop or a curl'}

SPECS = [PRINT, SCRIPT]
