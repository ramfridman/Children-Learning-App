"""F6 for Russian: the 33 capital and 33 small print letters (печатные буквы; print only, decision D13), drawn as centre
lines inside Nitznutz Letters Bold (Andika 7 with the two-storey Cyrillic а; docs/languages/fonts.md), on three lines
and the descender line (д ц щ р у ф). The marks of Ё ё and Й й are strokes of their own (frame F6). Built by
tools/make_letter_strokes.py; format in docs/languages/strokes.md. Status: teacher-checked (russian-language-teacher,
2026-11-05; decisions in docs/languages/strokes.md section 5.2).

The stroke ORDER follows the Russian print models (russian-language-teacher, 2026-11-05). Russian pre-school print
copybooks write a print letter element by element (по элементам), lifting the pen at every corner: the sticks first,
each from the top down, then the lines across, each from left to right, then the small marks (feet, tails, flags). Read
for this, facts only:
  - An unnamed published print copybook reproduced on deti-i-mama.ru ("Печатные буквы прописи для дошкольников",
    2022-01-09; pages 2 to 32, one capital a page, every element numbered with an arrow): А Б В Г Д Е Ж З И Й К Л М Н О
    П Р С Т У Ф Х Ц Ч Ш Щ Ъ Ы Э Ю Я.
  - A second copybook, "Печатные буквы" (reproduced on deti-i-mama.ru, pages 13 to 57: Г Ж К Л Н П С Х Ц Э), with
    numbered arrows; it agrees with the first on every letter shown except the upper arm of К.
  - Т. П. Воронина, "Прописи для дошкольников. Пишем печатные буквы" (Феникс, ISBN 978-5-222-41554-2), the author's
    method note on proza.ru (2022-03-08): the parts of a print letter are written top to bottom and left to right, one
    element at a time; М written in one go, climbing up and down, is named as the wrong way.
  Capitals only are numbered in these books; the small letters that have the capital's shape (в г д ж з и й к л м н п
  т ц ч ш щ ъ ы ь э ю я, р's stick and bowl, у, ф) follow their capital. а б е have their own shapes (see below).

References looked at on 2026-11-04 by the design-director (the shapes; every path is our own, drawn on the font's
measures, nothing traced):
  - The course itself: docs/languages/russian/syllabus.md (LS02 trace, copy, memory; print only, D13; the ten letter groups;
    the descenders д щ ц у р named in frame.md section 2.3).
  - Russian pre-school print copybooks (прописи печатных букв): Strekoza "Пишем печатные буквы. Классические прописи"
    (strecoza.ru, sample pages К Л М Н), the ot2do7.ru print-letter tracing sheets (А to Й, print shapes on a grid), and
    the general rule of those books: every letter starts at the top, a straight stick (палочка) first, then the lines
    across, left to right, and round letters from the top.
  - The font's own shapes: each glyph measured in Chrome (canvas measureText on app/assets/fonts/NitznutzLetters-Bold.ttf)
    and drawn on a 50-unit grid (Д with its feet, Л with its hooked leg, the two-storey а, б with its flag), so every
    centre line sits inside the letter the tile shows (checked with --fit).
Choices the teacher checks are listed in docs/languages/strokes.md section 5.2.
"""
from make_letter_strokes import Form, S, top_start

# measured in Chrome: (left, right, top, bottom-below-baseline) of each glyph's ink, in font units (1000 to the em)
METRICS = {'А': (16, 688, 719, 0), 'Б': (63, 625, 719, 16), 'В': (63, 641, 719, 16), 'Г': (63, 547, 719, 0), 'Д': (16, 859, 719, 234), 'Е': (63, 547, 719, 0), 'Ё': (63, 547, 984, 0), 'Ж': (78, 1031, 734, 0), 'З': (31, 563, 734, 16), 'И': (63, 719, 719, 0), 'Й': (31, 688, 969, 0), 'К': (63, 672, 734, 0), 'Л': (16, 719, 719, 16), 'М': (63, 844, 719, 0), 'Н': (63, 688, 719, 0), 'О': (31, 688, 734, 16), 'П': (94, 688, 719, 0), 'Р': (63, 594, 719, 0), 'С': (31, 625, 734, 16), 'Т': (16, 594, 719, 0), 'У': (0, 578, 719, 16), 'Ф': (31, 703, 766, 16), 'Х': (16, 641, 719, 0), 'Ц': (94, 797, 719, 234), 'Ч': (47, 609, 719, 0), 'Ш': (94, 922, 719, 0), 'Щ': (94, 1063, 719, 234), 'Ъ': (0, 766, 719, 16), 'Ы': (63, 828, 719, 16), 'Ь': (63, 609, 719, 16), 'Э': (31, 609, 734, 16), 'Ю': (63, 984, 734, 16), 'Я': (47, 641, 719, 0), 'а': (47, 547, 516, 16), 'б': (31, 531, 766, 16), 'в': (63, 563, 516, 16), 'г': (63, 500, 500, 0), 'д': (0, 703, 500, 219), 'е': (31, 500, 516, 16), 'ё': (31, 500, 766, 16), 'ж': (31, 828, 516, 0), 'з': (47, 484, 516, 16), 'и': (63, 594, 500, 0), 'й': (63, 594, 719, 0), 'к': (63, 563, 516, 0), 'л': (16, 563, 500, 16), 'м': (63, 688, 500, 0), 'н': (63, 594, 500, 0), 'о': (31, 531, 516, 16), 'п': (78, 578, 500, 0), 'р': (47, 563, 516, 250), 'с': (31, 469, 516, 16), 'т': (16, 547, 500, 0), 'у': (0, 531, 500, 250), 'ф': (31, 672, 734, 250), 'х': (16, 563, 500, 0), 'ц': (63, 672, 500, 219), 'ч': (16, 469, 500, 0), 'ш': (63, 797, 500, 0), 'щ': (63, 906, 500, 219), 'ъ': (0, 656, 500, 16), 'ы': (63, 766, 500, 16), 'ь': (63, 547, 500, 16), 'э': (47, 469, 516, 16), 'ю': (78, 797, 516, 16), 'я': (16, 531, 516, 0)}

EM, BASE = 76.0, 76.0


def _line(units):
    return round(BASE - units * EM / 1000.0, 1)


SET = {
    'set': 'cyrillic',
    'courses': ['rus'],
    'review': 'teacher-checked',
    'reviewer': 'russian-language-teacher',
    'box': 100,
    'ink': 9,
    'em': EM,
    'baseline': BASE,
    'guides': {'cap': _line(719), 'x': _line(500), 'base': BASE, 'descender': _line(-250)},
    'solidGuides': ['base'],
    'font': {'family': 'Nitznutz Letters', 'weight': 700, 'file': 'app/assets/fonts/NitznutzLetters-Bold.ttf', 'css': 'NL'},
    'metrics': METRICS,
    'inset': 4.6,
    'direction': 'ltr',
    'generator': 'tools/make_letter_strokes.py (paths: tools/strokes_cyrillic.py)',
}

C, X, D = 'cap', 'x', 'descender'
DOT = {'kind': 'dot'}
SHORT = {'kind': 'short'}
BAR = 'the model starts е on its bar, at the middle, then goes round'
NAMES = dict(zip('АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ',
                 ['a', 'be', 've', 'ge', 'de', 'ye', 'yo', 'zhe', 'ze', 'i', 'i-kratkoye', 'ka', 'el', 'em', 'en', 'o', 'pe',
                  'er', 'es', 'te', 'u', 'ef', 'kha', 'tse', 'che', 'sha', 'shcha', 'tvyordy-znak', 'y', 'myagky-znak', 'e',
                  'yu', 'ya']))


def up(ch, sits, *strokes, **meta):
    return Form('cyrillic.%s.cap' % NAMES[ch], ch, list(strokes), sits, name=NAMES[ch], case='upper', **meta)


def lo(ch, sits, *strokes, **meta):
    return Form('cyrillic.%s' % NAMES[ch.upper()], ch, list(strokes), sits, name=NAMES[ch.upper()], case='lower', **meta)


UPDIAG = 'Russian print model: the sticks first, then the diagonal from the foot of the first stick up to the top of the second'

# Order (russian-language-teacher, 2026-11-05): sticks top-down first, then the lines across left to right, then feet,
# tails and flags; a bowl or a half is its own stroke from where it leaves the stick. Sources at the top of this file.
FORMS = [
    up('А', (C, 'base'), S('M 352 660 L 74 40'), S('M 352 660 L 630 40'), S('M 185 228 L 520 228')),
    up('Б', (C, 'base'), S('M 143 660 L 143 58'), S('M 143 660 L 590 660'),
       S('M 143 395 L 360 395 C 500 395 566 320 566 225 C 566 125 500 58 360 58 L 143 58')),
    up('В', (C, 'base'), S('M 143 660 L 143 58'),
       S('M 143 660 L 340 660 A 340 525 180 135 90 -90 L 143 390'),
       S('M 143 390 L 360 390 A 360 224 214 166 90 -90 L 143 58')),
    up('Г', (C, 'base'), S('M 143 660 L 143 40'), S('M 143 660 L 520 660')),
    up('Д', (C, D), S('M 395 660 C 375 450 310 250 215 80'), S('M 654 660 L 654 58'), S('M 395 660 L 654 660', **SHORT),
       S('M 80 56 L 787 56 L 787 -185'), S('M 80 56 L 80 -185', **SHORT)),
    up('Е', (C, 'base'), S('M 143 660 L 143 58'), S('M 143 660 L 515 660'), S('M 143 372 L 478 372'), S('M 143 58 L 520 58')),
    up('Ё', (C, 'base'), S('M 143 660 L 143 58'), S('M 143 660 L 515 660'), S('M 143 372 L 478 372'), S('M 143 58 L 520 58'),
       S('M 225 905 L 225 900', **DOT), S('M 400 905 L 400 900', **DOT)),
    up('Ж', (C, 'base'), S('M 551 680 L 551 40'),
       S('M 95 690 C 170 705 215 610 265 500 C 330 420 420 400 470 362'), S('M 470 362 C 420 320 280 300 172 40'),
       S('M 1007 690 C 932 705 887 610 837 500 C 772 420 682 400 632 362'), S('M 632 362 C 682 320 822 300 930 40')),
    up('З', (C, 'base'), S('A 280 520 190 150 140 -90 L 190 370'), S('M 190 370 L 290 370 A 290 205 205 165 90 -150')),
    up('И', (C, 'base'), S('M 143 660 L 143 40'), S('M 639 660 L 639 40'), S('M 143 40 L 639 660', startOk=UPDIAG)),
    up('Й', (C, 'base'), S('M 111 660 L 111 40'), S('M 607 660 L 607 40'), S('M 111 40 L 607 660', startOk=UPDIAG),
       S('M 245 905 C 275 815 445 815 475 905', **SHORT)),
    up('К', (C, 'base'), S('M 143 660 L 143 40'), S('M 612 690 C 537 705 492 610 442 500 C 407 430 347 380 237 362'),
       S('M 237 362 C 347 345 427 300 595 40')),
    up('Л', (C, 'base'), S('M 298 660 C 290 400 240 200 170 110 C 130 65 90 58 45 60'), S('M 623 660 L 623 40'),
       S('M 298 660 L 623 660', **SHORT)),
    up('М', (C, 'base'), S('M 143 660 L 143 40'), S('M 764 660 L 764 40'), S('M 143 660 L 453 120'), S('M 740 660 L 453 120')),
    up('Н', (C, 'base'), S('M 143 660 L 143 40'), S('M 608 660 L 608 40'), S('M 143 365 L 608 365')),
    up('О', (C, 'base'), S('A 360 359 270 327 90 450')),
    up('П', (C, 'base'), S('M 174 660 L 174 40'), S('M 608 660 L 608 40'), S('M 174 660 L 608 660')),
    up('Р', (C, 'base'), S('M 143 660 L 143 40'), S('M 143 660 L 340 660 A 340 497 196 163 90 -90 L 143 334')),
    up('С', (C, 'base'), S('A 340 359 253 327 46 314')),
    up('Т', (C, 'base'), S('M 305 660 L 305 40'), S('M 58 660 L 552 660')),
    up('У', (C, 'base'), S('M 495 670 L 330 200 C 300 110 250 45 170 45 C 130 45 100 50 70 60'), S('M 85 670 L 300 250')),
    up('Ф', (None, 'base'), S('M 375 735 L 375 30'), S('A 371 385 270 230 90 270'), S('A 371 385 270 230 90 -90')),
    up('Х', (C, 'base'), S('M 78 660 L 580 40'), S('M 580 660 L 78 40')),
    up('Ц', (C, D), S('M 174 660 L 174 58'), S('M 630 660 L 630 58'), S('M 174 58 L 740 58 L 740 -185')),
    up('Ч', (C, 'base'), S('M 529 660 L 529 40'), S('M 127 660 L 127 450 C 127 340 200 300 320 300 C 410 300 480 315 529 340')),
    up('Ш', (C, 'base'), S('M 174 660 L 174 58'), S('M 508 660 L 508 58'), S('M 842 660 L 842 58'), S('M 174 58 L 842 58')),
    up('Щ', (C, D), S('M 174 660 L 174 58'), S('M 508 660 L 508 58'), S('M 842 660 L 842 58'), S('M 174 58 L 990 58 L 990 -185')),
    up('Ъ', (C, 'base'), S('M 260 660 L 260 58'),
       S('M 260 395 L 480 395 C 620 395 690 320 690 225 C 690 125 620 58 480 58 L 260 58'), S('M 40 660 L 260 660', **SHORT)),
    up('Ы', (C, 'base'), S('M 143 660 L 143 58'), S('M 143 395 L 330 395 C 460 395 520 320 520 225 C 520 125 460 58 330 58 L 143 58'),
       S('M 748 660 L 748 40')),
    up('Ь', (C, 'base'), S('M 143 660 L 143 58'), S('M 143 395 L 360 395 C 490 395 549 320 549 225 C 549 125 490 58 360 58 L 143 58')),
    up('Э', (C, 'base'), S('A 300 359 250 327 136 -136'), S('M 210 365 L 540 365')),
    up('Ю', (C, 'base'), S('M 143 660 L 143 40'), S('M 143 362 L 430 362', **SHORT), S('A 682 359 250 327 90 450')),
    up('Я', (C, 'base'), S('M 561 660 L 360 660 C 230 660 175 595 175 500 C 175 400 240 335 360 335 L 561 335'),
       S('M 561 660 L 561 40'), S('M 330 335 C 250 300 190 200 125 40')),

    lo('а', (X, 'base'), S('M 110 385 C 170 440 230 458 290 458 C 400 458 448 400 448 330 L 448 120 C 448 75 460 50 478 35'),
       S('M 448 268 L 280 268 C 165 268 105 205 105 150 C 105 80 155 38 220 38 C 320 38 400 85 448 150')),
    lo('б', (None, 'base'), S('M 518 690 C 400 682 262 668 192 600 C 130 540 102 450 102 300 L 102 240 A 282 234 180 200 180 510')),
    lo('в', (X, 'base'), S('M 143 462 L 143 52'),
       S('M 143 452 L 330 452 C 420 452 460 412 460 355 C 460 295 420 258 330 258 L 143 258'),
       S('M 143 258 L 345 258 C 445 258 488 212 488 150 C 488 85 440 52 330 52 L 143 52')),
    lo('г', (X, 'base'), S('M 143 462 L 143 40'), S('M 143 445 L 480 445')),
    lo('д', (X, D), S('M 290 445 C 280 320 230 170 165 75'), S('M 522 445 L 522 52'), S('M 290 445 L 522 445', **SHORT),
       S('M 70 52 L 640 52 L 640 -185'), S('M 70 52 L 70 -185', **SHORT)),
    lo('е', (X, 'base'), S('M 112 262 L 446 262 A 270 250 180 216 4 310', startOk=BAR)),
    lo('ё', (X, 'base'), S('M 112 262 L 446 262 A 270 250 180 216 4 310', startOk=BAR),
       S('M 190 690 L 190 685', **DOT), S('M 345 690 L 345 685', **DOT)),
    lo('ж', (X, 'base'), S('M 431 462 L 431 40'),
       S('M 60 452 C 120 470 160 420 200 350 C 230 300 330 290 395 257'), S('M 395 257 C 330 225 220 200 117 40'),
       S('M 802 452 C 742 470 702 420 662 350 C 632 300 532 290 467 257'), S('M 467 257 C 532 225 642 200 745 40')),
    lo('з', (X, 'base'), S('M 92 415 C 160 452 225 462 285 462 C 385 462 435 418 435 362 C 435 300 380 257 290 257 L 190 257'),
       S('M 190 257 L 300 257 C 405 257 460 210 460 150 C 460 75 390 38 280 38 C 200 38 130 52 80 75')),
    lo('и', (X, 'base'), S('M 143 462 L 143 40'), S('M 514 462 L 514 40'), S('M 143 40 L 514 462', startOk=UPDIAG)),
    lo('й', (X, 'base'), S('M 143 462 L 143 40'), S('M 514 462 L 514 40'), S('M 143 40 L 514 462', startOk=UPDIAG),
       S('M 210 680 C 238 605 420 605 448 680', **SHORT)),
    lo('к', (X, 'base'), S('M 143 462 L 143 40'), S('M 520 452 C 460 470 420 420 380 350 C 350 300 250 290 190 257'),
       S('M 190 257 C 250 225 360 200 490 40')),
    lo('л', (X, 'base'), S('M 245 445 C 240 300 210 160 160 95 C 125 52 90 50 50 52'), S('M 483 445 L 483 40'),
       S('M 245 445 L 483 445', **SHORT)),
    lo('м', (X, 'base'), S('M 143 462 L 143 40'), S('M 608 462 L 608 40'), S('M 143 462 L 375 110'), S('M 608 462 L 375 110')),
    lo('н', (X, 'base'), S('M 143 462 L 143 40'), S('M 514 462 L 514 40'), S('M 143 255 L 514 255')),
    lo('о', (X, 'base'), S('A 281 250 197 216 42 402')),
    lo('п', (X, 'base'), S('M 158 462 L 158 40'), S('M 498 445 L 498 40'), S('M 158 445 L 498 445')),
    lo('р', (X, D), S('M 127 462 L 127 -210'), S('M 127 400 A 305 250 178 210 150 -150')),
    lo('с', (X, 'base'), S('A 262 250 196 216 42 318')),
    lo('т', (X, 'base'), S('M 282 445 L 282 40'), S('M 40 445 L 525 445')),
    lo('у', (X, D), S('M 449 462 L 182 -200'), S('M 79 462 L 263 162')),
    lo('ф', (None, D), S('M 347 700 L 347 -215'), S('A 347 244 252 205 90 270'), S('A 347 244 252 205 90 -90')),
    lo('х', (X, 'base'), S('M 78 462 L 500 38'), S('M 500 462 L 78 38')),
    lo('ц', (X, D), S('M 143 462 L 143 52'), S('M 514 462 L 514 52'), S('M 143 52 L 610 52 L 610 -185')),
    lo('ч', (X, 'base'), S('M 389 462 L 389 40'), S('M 96 462 L 96 330 C 96 250 160 215 250 215 C 320 215 360 228 389 245')),
    lo('ш', (X, 'base'), S('M 143 462 L 143 52'), S('M 430 462 L 430 52'), S('M 717 462 L 717 52'), S('M 143 52 L 717 52')),
    lo('щ', (X, D), S('M 143 462 L 143 52'), S('M 430 462 L 430 52'), S('M 717 462 L 717 52'), S('M 143 52 L 846 52 L 846 -185')),
    lo('ъ', (X, 'base'), S('M 210 445 L 210 52'),
       S('M 210 270 L 400 270 C 520 270 576 220 576 150 C 576 82 520 52 400 52 L 210 52'), S('M 30 445 L 210 445', **SHORT)),
    lo('ы', (X, 'base'), S('M 143 462 L 143 52'), S('M 143 270 L 290 270 C 410 270 466 220 466 150 C 466 82 410 52 290 52 L 143 52'),
       S('M 686 462 L 686 40')),
    lo('ь', (X, 'base'), S('M 143 462 L 143 52'), S('M 143 270 L 310 270 C 430 270 487 220 487 150 C 487 82 430 52 310 52 L 143 52')),
    lo('э', (X, 'base'), S('A 230 250 184 216 140 -140'), S('M 125 252 L 360 252', **SHORT)),
    lo('ю', (X, 'base'), S('M 158 462 L 158 40'), S('M 158 265 L 370 265', **SHORT), S('A 549 250 175 213 90 450')),
    lo('я', (X, 'base'), S('M 444 450 L 290 450 C 180 450 133 400 133 345 C 133 285 185 240 290 240 L 444 240'),
       S('M 444 462 L 444 40'), S('M 285 240 C 200 205 145 130 100 36', **SHORT)),
]


def start_rule(form, i, s):
    return top_start(form, i, s)
