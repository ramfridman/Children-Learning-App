"""F6 for English: the 26 small and 26 capital print letters, drawn as centre lines inside Nitznutz Letters Bold (the app's
Latin teaching font, Andika 7 with the single-storey a and g; docs/languages/fonts.md), on the four lines. Built by
tools/make_letter_strokes.py; format in docs/languages/strokes.md. Status: needs-teacher (english-language-teacher).

References looked at on 2026-11-04 (facts only; every path is our own, drawn on the font's measures, nothing traced):
  - The course itself: docs/languages/english/syllabus.md section 3.1 and section 5 (the formation families c a d g o q /
    s e f / l i t j / r n m h b p k / u y / v w x z, the "2 o'clock" start of the round letters, anticlockwise; trace,
    copy, memory; "letter direction matters more than the order").
  - Handwriting Without Tears (Learning Without Tears) print charts: the lowercase formation chart and the Print Letter
    Group Posters (lwtears.com; a Blue Valley K-12 copy of "HWT Lowercase Letter Formation"): the Magic c letters c a d g
    o q s start with the same c stroke ("magic c, up like a helicopter, back down"); "big line down, up and over" for
    r n m h b p; i and j are a line down, then the dot; capitals start at the top, with frog jumps to the top again.
  - Zaner-Bloser manuscript conventions (pull down straight, circle back, slide right) as summarised in school letter
    formation charts (e.g. iblog.dearbornschools.org "Letter Formation Charts").
  - The font's own shapes: each glyph measured in Chrome (canvas measureText on app/assets/fonts/NitznutzLetters-Bold.ttf)
    and drawn on a 50-unit grid, so every centre line sits inside the letter the tile shows (checked with --fit).
Choices the teacher checks are listed in docs/languages/strokes.md section 5.1.
"""
from make_letter_strokes import Form, S, top_start

# measured in Chrome: (left, right, top, bottom-below-baseline) of each glyph's ink, in font units (1000 to the em)
METRICS = {'a': (47, 578, 516, 16), 'b': (47, 563, 781, 16), 'c': (31, 469, 516, 16), 'd': (47, 594, 781, 16), 'e': (31, 500, 516, 16), 'f': (16, 422, 797, 0), 'g': (47, 531, 516, 234), 'h': (47, 547, 781, 0), 'i': (63, 250, 766, 0), 'j': (-94, 266, 766, 234), 'k': (47, 563, 781, 0), 'l': (78, 234, 781, 0), 'm': (47, 797, 516, 0), 'n': (47, 547, 516, 0), 'o': (31, 531, 516, 16), 'p': (47, 563, 516, 250), 'q': (47, 547, 516, 250), 'r': (47, 484, 516, 0), 's': (47, 469, 516, 16), 't': (16, 406, 656, 16), 'u': (63, 578, 500, 16), 'v': (0, 547, 500, 0), 'w': (16, 750, 500, 0), 'x': (16, 563, 500, 0), 'y': (-16, 531, 500, 234), 'z': (47, 484, 500, 0), 'A': (16, 688, 719, 0), 'B': (63, 609, 719, 16), 'C': (31, 625, 734, 16), 'D': (63, 672, 719, 16), 'E': (63, 547, 719, 0), 'F': (63, 531, 719, 0), 'G': (31, 656, 734, 16), 'H': (63, 656, 719, 0), 'I': (63, 438, 719, 0), 'J': (16, 422, 719, 16), 'K': (63, 672, 719, 0), 'L': (63, 531, 719, 0), 'M': (63, 828, 719, 0), 'N': (63, 672, 719, 0), 'O': (31, 688, 734, 16), 'P': (63, 594, 719, 0), 'Q': (31, 750, 734, 125), 'R': (63, 656, 719, 0), 'S': (31, 563, 734, 16), 'T': (16, 594, 719, 0), 'U': (63, 641, 719, 16), 'V': (0, 703, 719, 0), 'W': (16, 1016, 719, 0), 'X': (16, 641, 719, 0), 'Y': (0, 656, 719, 0), 'Z': (31, 578, 719, 0)}

EM, BASE = 84.0, 72.0


def _line(units):
    return round(BASE - units * EM / 1000.0, 1)


SET = {
    'set': 'latin',
    'courses': ['eng'],
    'review': 'needs-teacher',
    'reviewer': 'english-language-teacher',
    'box': 100,
    'ink': 9,
    'em': EM,
    'baseline': BASE,
    'guides': {'ascender': _line(781), 'cap': _line(719), 'x': _line(500), 'base': BASE, 'descender': _line(-250)},
    'solidGuides': ['base'],
    'font': {'family': 'Nitznutz Letters', 'weight': 700, 'file': 'app/assets/fonts/NitznutzLetters-Bold.ttf', 'css': 'NL'},
    'metrics': METRICS,
    'inset': 5.0,
    'direction': 'ltr',
    'generator': 'tools/make_letter_strokes.py (paths: tools/strokes_latin.py)',
}

X, A, C, D = 'x', 'ascender', 'cap', 'descender'
DOT = {'kind': 'dot'}
BAR = 'the model starts e on its bar, at the middle, then goes round'
MAGIC = "d is a magic c letter: it starts at 2 o'clock on the bowl, goes up to the top line and back down"


def lo(ch, family, sits, *strokes, **meta):
    return Form('latin.%s' % ch, ch, list(strokes), sits, name=ch, case='lower', group=family, **meta)


def up(ch, sits, *strokes, **meta):
    return Form('latin.%s.cap' % ch.lower(), ch, list(strokes), sits, name=ch, case='upper', group='capitals', **meta)


FORMS = [
    # c a d g o q: magic c from 2 o'clock, anticlockwise (q is written with group 4 but keeps its family's movement)
    lo('c', 'c-round', (X, 'base'), S('A 262 250 196 216 42 318')),
    lo('a', 'c-round', (X, 'base'), S('A 288 245 182 213 58 360 L 470 468 L 482 40', retrace=True)),
    lo('d', 'c-round', (A, 'base'), S('A 305 245 208 213 50 360 L 514 735 L 514 40', retrace=True, startOk=MAGIC)),
    lo('g', 'c-round', (X, D), S('A 273 262 175 205 55 360 L 448 462 L 448 -100 C 448 -185 380 -192 290 -192 '
                                  'C 210 -192 150 -180 105 -160', retrace=True)),
    lo('o', 'c-round', (X, 'base'), S('A 281 250 197 216 42 402')),
    lo('q', 'c-round', (X, D), S('A 285 245 182 213 50 360 L 467 468 L 467 -205', retrace=True)),
    # s e f
    lo('s', 's-e-f', (X, 'base'), S('A 262 360 152 106 30 270 A 258 144 160 110 90 -145')),
    lo('e', 's-e-f', (X, 'base'), S('M 112 262 L 446 262 A 270 250 180 216 4 310', startOk=BAR)),
    lo('f', 's-e-f', (A, 'base'), S('M 420 722 C 380 748 330 750 290 746 C 222 740 184 694 184 600 L 184 40'),
       S('M 40 440 L 362 440')),
    # l i t j: down strokes
    lo('l', 'down', (A, 'base'), S('M 156 735 L 158 40')),
    lo('i', 'down', (X, 'base'), S('M 157 462 L 157 40'), S('M 157 676 L 157 672', **DOT)),
    lo('t', 'down', (None, 'base'), S('M 172 612 L 172 130 C 172 62 210 38 270 38 C 320 38 360 55 392 78'),
       S('M 40 442 L 385 442')),
    lo('j', 'down', (X, D), S('M 162 462 L 162 -95 C 162 -170 125 -192 65 -192 C 15 -192 -25 -184 -55 -168'),
       S('M 164 676 L 164 672', **DOT)),
    # r n m h b p k: down, then up and over
    lo('r', 'down-up-over', (X, 'base'), S('M 127 470 L 127 40 L 127 320 C 160 420 240 456 330 456 C 400 456 445 446 474 428',
                                            retrace=True)),
    lo('n', 'down-up-over', (X, 'base'), S('M 127 462 L 127 40 L 127 330 C 155 420 225 456 300 456 C 410 456 467 400 467 310 '
                                            'L 467 40', retrace=True)),
    lo('m', 'down-up-over', (X, 'base'), S('M 127 462 L 127 40 L 127 330 C 150 425 205 456 265 456 C 365 456 422 405 422 320 '
                                            'L 422 40 L 422 320 C 422 405 482 456 570 456 C 668 456 717 405 717 320 L 717 40',
                                            retrace=True)),
    lo('h', 'down-up-over', (A, 'base'), S('M 127 735 L 127 40 L 127 330 C 155 420 225 456 300 456 C 410 456 467 400 467 310 '
                                            'L 467 40', retrace=True)),
    lo('b', 'down-up-over', (A, 'base'), S('M 127 735 L 127 40 L 127 330 A 305 250 178 210 150 -150', retrace=True)),
    lo('p', 'down-up-over', (X, D), S('M 127 462 L 127 -210 L 127 330 A 305 250 178 210 150 -150', retrace=True)),
    lo('k', 'down-up-over', (A, 'base'), S('M 127 735 L 127 40'), S('M 455 462 L 175 268 L 482 40')),
    # u y
    lo('u', 'u-y', (X, 'base'), S('M 143 462 L 143 190 C 143 95 210 42 300 42 C 400 42 498 95 498 210 L 498 462 L 498 40',
                                  retrace=True)),
    lo('y', 'u-y', (X, D), S('M 85 462 L 282 72'),
       S('M 452 462 L 238 -108 C 210 -172 168 -192 110 -192 C 72 -192 45 -186 22 -178')),
    # v w x z: slants
    lo('v', 'slants', (X, 'base'), S('M 62 462 L 273 38 L 485 462')),
    lo('w', 'slants', (X, 'base'), S('M 72 462 L 208 38 L 383 420 L 558 38 L 694 462')),
    lo('x', 'slants', (X, 'base'), S('M 78 462 L 500 38'), S('M 500 462 L 78 38')),
    lo('z', 'slants', (X, 'base'), S('M 92 452 L 445 452 L 100 48 L 452 48')),

    # capitals (C-13): start at the top; down strokes first, then the lines across, left to right
    up('A', (C, 'base'), S('M 352 660 L 74 40'), S('M 352 660 L 630 40'), S('M 185 228 L 520 228')),
    up('B', (C, 'base'), S('M 143 660 L 143 58'),
       S('M 143 660 L 330 660 A 330 529 176 143 90 -90 L 143 386 L 350 386 A 350 217 205 169 90 -90 L 143 58', retrace=True)),
    up('C', (C, 'base'), S('A 340 359 253 327 46 314')),
    up('D', (C, 'base'), S('M 143 660 L 143 58'), S('M 143 660 L 300 660 C 520 660 614 540 614 360 C 614 178 520 58 300 58 L 143 58')),
    up('E', (C, 'base'), S('M 143 660 L 143 58'), S('M 143 660 L 515 660'), S('M 143 372 L 478 372'), S('M 143 58 L 520 58')),
    up('F', (C, 'base'), S('M 143 660 L 143 40'), S('M 143 660 L 500 660'), S('M 143 362 L 462 362')),
    up('G', (C, 'base'), S('A 345 359 252 327 42 330 L 586 330 L 400 330')),
    up('H', (C, 'base'), S('M 143 660 L 143 40'), S('M 576 660 L 576 40'), S('M 143 365 L 576 365')),
    up('I', (C, 'base'), S('M 250 660 L 250 58'), S('M 98 660 L 402 660'), S('M 98 58 L 402 58')),
    up('J', (C, 'base'), S('M 336 660 L 336 232 C 336 92 270 34 180 34 C 120 34 80 52 58 88')),
    up('K', (C, 'base'), S('M 143 660 L 143 40'), S('M 600 660 L 200 345 L 300 268 L 612 40')),
    up('L', (C, 'base'), S('M 143 660 L 143 58 L 510 58')),
    up('M', (C, 'base'), S('M 143 660 L 143 40'), S('M 143 660 L 445 110 L 748 660 L 748 40')),
    up('N', (C, 'base'), S('M 143 660 L 143 40'), S('M 143 660 L 592 40 L 592 660')),
    up('O', (C, 'base'), S('A 360 359 270 327 90 450')),
    up('P', (C, 'base'), S('M 143 660 L 143 40'), S('M 143 660 L 340 660 A 340 497 196 175 90 -90 L 143 322')),
    up('Q', (C, None), S('A 384 359 296 327 90 450'), S('M 470 170 L 712 -78')),
    up('R', (C, 'base'), S('M 143 660 L 143 40'),
       S('M 143 660 L 330 660 C 450 660 510 605 510 505 C 510 405 450 338 330 338 L 160 338 L 572 40')),
    up('S', (C, 'base'), S('A 300 524 208 160 32 270 A 296 194 232 160 90 -148')),
    up('T', (C, 'base'), S('M 58 660 L 552 660'), S('M 305 660 L 305 40')),
    up('U', (C, 'base'), S('M 143 660 L 143 250 C 143 100 220 36 352 36 C 474 36 561 100 561 250 L 561 660')),
    up('V', (C, 'base'), S('M 62 660 L 352 42 L 642 660')),
    up('W', (C, 'base'), S('M 72 660 L 270 42 L 516 560 L 762 42 L 960 660')),
    up('X', (C, 'base'), S('M 78 660 L 580 40'), S('M 580 660 L 78 40')),
    up('Y', (C, 'base'), S('M 62 660 L 328 330'), S('M 596 660 L 328 330 L 328 40')),
    up('Z', (C, 'base'), S('M 92 660 L 528 660 L 88 58 L 538 58')),
]


def start_rule(form, i, s):
    return top_start(form, i, s)
