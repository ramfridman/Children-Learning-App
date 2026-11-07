# M10 batch C1: the items that wait for batch step 3

The maths teacher, 2026-11-06; prepared in the generator 2026-11-07 (QA-C1-5). Batch C1 (docs/milestones/M10.md §4.1, §4.2, §7) is in
content with only the items that today's sessions draw. The items below need a mode that no session draws yet (security review of step
0: `qa_m10s0_undrawn_modes_test.dart` fails on any `scene.picture` or `answer.type: number` in content).

**State (2026-11-07): written in `tools/band_c.py`, out of content.** The items of §1 to §3 that today's schema can say are in
`numbers_c1_waiting` and `math_c1_waiting`, behind the table `DRAWN` at the top of the C1 section (`base_ten`, `hundred_chart`,
`number`, all False). `tools/test_check_maths.py` (class `C1Deferred`) builds them in memory with every mode on, runs
`check_maths` strict over them (0 WRONG, RULE, AMBIG, UNCHECKED), checks that none is in `content/` and that switching a mode on
renumbers no drawn item (each waiting item comes after every drawn item of its skill, and they have lessons of their own:
`blocks-tens-and-ones`, `hundred-chart`, `write-numbers`, `type-the-answer`).

**To switch a mode on** (the app-developer, in the commit whose session draws it): set its `DRAWN` entry True, take its check off
`qa_m10s0_undrawn_modes_test.dart`, run `python -I tools/regen_content.py`, then `python -I -X utf8 tools/check_maths.py --ids c.
--strict` and the content tests. For the two pictures, `tools/author.py` `k_pick` must first copy the item's `picture` into the scene
(one line, as `k_number` does: `if 'picture' in a: scene['picture'] = a['picture']`); the test carries it by hand until then.

The checker reads all three modes (`tools/check_maths.py`): base-ten blocks are 10 × tens + ones and M-PV-FACE also gives every
block counted as one (7 for 34); the hundred chart's answer is its one blank cell, the caption must fit the lit cells (ten more, ten
less, the column, "after", or a lit neighbour), and M-HC-ROW gives the next cell in the row; a number answer is recomputed from its
row, its picture or the one number of its caption, every expected wrong number must reproduce its tag, and every rule must name its
tag (`smaller_from_larger` M-SUB-SMALLBIG and `added_instead` M-OP-SWAP only on a subtraction, `face_value` M-PV-FACE,
`forgot_the_ten` and `off_by_ten` M-REGROUP-FORGET).

Hebrew in the specs is a draft in the plural address, `needs-editor`; = is read שָׁוֶה. None of it is voiced.

## 1. `scene.picture` `base_ten` (X1): hundreds flats, tens rods, ones cubes

The R1/R2 of place value (P13 in the hint ladders). Tens are drawn left of ones (LTR isolate); the digits are never on the picture.

| Skill | Picture (`tens`, `ones`) | Question | Answer | Wrong options and tags |
|---|---|---|---|---|
| NUM-C-03 | 3, 4 | כַּמָּה קֻבִּיּוֹת יֵשׁ כָּאן? | 34 | 7 M-PV-FACE (counts rods as ones), 43 M-NUM-REV, 304 M-PV-ZERO |
| NUM-C-03 | 5, 0 (zero holds a place) | כַּמָּה קֻבִּיּוֹת יֵשׁ כָּאן? | 50 | 5 M-PV-ZERO, 500 M-PV-ZERO (see below) |
| NUM-C-03 | 2, 7, one rod lit | כַּמָּה שָׁוֶה הַמּוֹט הַזֶּה? | 10 | 1 M-PV-FACE (the rod is "one"), 100 M-PV-ZERO |
| NUM-C-03 | 6, 2 | אֵיזֶה מִסְפָּר בָּנוּ? (U2, blocks → digits; check `transfer`) | 62 | 26 M-NUM-REV, 602 M-PV-ZERO, 8 M-PV-FACE |
| NUM-C-03 | 4, 3 vs 3, 4 (two pictures, choice of pictures) | אֵיפֹה שְׁלוֹשִׁים וְאַרְבַּע? | the picture 3, 4 | the picture 4, 3 M-NUM-REV |
| NUM-C-04 | 4, 1 and 3, 9 (two towers) | אֵיזֶה מִסְפָּר גָּדוֹל יוֹתֵר? | 41 | 39 M-PV-FACE |
| NUM-C-04 | 5, 8 and 4, 3 (the lucky-right pair) | אֵיזֶה מִסְפָּר גָּדוֹל יוֹתֵר? | 58 | 43 M-PV-FACE |
| MATH-C-03 | 4 rods + 3 rods | כַּמָּה זֶה? (row `40 + 30 = ?`) | 70 | 7 M-PV-FACE, 700 M-PV-ZERO, 10 M-OP-SWAP |
| MATH-C-03 | 7 rods, 4 crossed out | כַּמָּה נִשְׁאַר? (row `70 − 40 = ?`) | 30 | 3 M-PV-FACE, 300 M-PV-ZERO, 110 M-OP-SWAP |

Prepared: the rows 34, 50 and 62 (`c.numc03.18` to `.20` when on). The recogniser and the M-PV-FACE rule are in `check_maths`.

**The 50 row, decided (2026-11-07):** on blocks, 5 is the five rods counted as five ones, which is M-PV-FACE exactly (the same rule
that gives 7 for 34), and 500 is the zero written twice, M-PV-ZERO. So the two distractors carry two distinct tags, the B-15 E1 rule
holds and no exception is needed (no question for the curriculum-expert).

Not prepared, because the picture schema (tap_answer 1.4 `scene.picture`) cannot say them yet; each needs a field from the
app-developer first: the lit rod ("how much is this rod worth?": a `lit` or `highlight` rod index on `base_ten`), the two towers
of NUM-C-04 and the choice of pictures (a second picture, or pictures as options), and MATH-C-03's two groups of rods and rods
crossed out (two pictures, or a `crossed` count). The keypad rows 40 + 30 and 90 − 50 of §3 teach the same facts meanwhile.

## 2. `scene.picture` `hundred_chart` (X1): a 10 × 10 chart, cells `lit` or `blank`

| Skill | Picture | Question | Answer | Wrong options and tags |
|---|---|---|---|---|
| NUM-C-09 | lit 34, blank 44 | עֶשֶׂר יוֹתֵר מִשְּׁלוֹשִׁים וְאַרְבַּע. אֵיזֶה מִסְפָּר בַּמִּשְׁבֶּצֶת הָרֵיקָה? | 44 | 35 M-HC-ROW, 24 M-OP-SWAP, 43 M-NUM-REV |
| NUM-C-09 | lit 57, blank 47 | עֶשֶׂר פָּחוֹת. אֵיזֶה מִסְפָּר בַּמִּשְׁבֶּצֶת הָרֵיקָה? | 47 | 56 M-HC-ROW, 67 M-OP-SWAP |
| NUM-C-09 | lit 6, 16, 26, blank 36 | מָה הַמִּסְפָּר הַבָּא בַּטּוּר? | 36 | 27 M-HC-ROW, 63 M-NUM-REV |
| NUM-C-09 | blank 58 between lit 48 and 68 (predict) | מָה מִסְתַּתֵּר כָּאן? | 58 | 49 M-HC-ROW, 85 M-NUM-REV |
| NUM-C-01 | a row 31 … 40 with 37 blank | אֵיזֶה מִסְפָּר חָסֵר? | 37 | 36 M-CNT-SEQ, 47 M-CNT-DECADE |
| NUM-C-01 | the end of a row, 40 lit, the next row's first cell blank | מַה בָּא אַחֲרֵי אַרְבָּעִים? | 41 | 50 M-CNT-DECADE, 42 M-CNT-SEQ |

Hint L2 of the family (M10 §7.2): a ten-rod laid down the column. The pointer of L3 moves one row down saying "ten more".

Prepared: all six (`c.numc09.13` to `.16`, `c.numc01.13` and `.14` when on). Changed from the table: the first row drops 43 (the
reversal of the lit 34 is no likely answer to "ten more than 34"; QA-C1-2 review), so it has 35 M-HC-ROW and 24 M-OP-SWAP. 50 after
40 is M-CNT-DECADE (after a whole ten the next ten word comes out: 39, 40, 50); `check_maths` now accepts it.

## 3. `answer.type: number` (X3): the keypad, read left to right

Every item lists its expected wrong numbers with tags and the rule classifiers (`tools/band_c.py` `number_item`).

| Skill | Row or question | Value | `expected` | `rules` |
|---|---|---|---|---|
| NUM-C-02 | כִּתְבוּ אֶת הַמִּסְפָּר עֶשְׂרִים וְשָׁלוֹשׁ | 23 | 32 M-NUM-REV, 203 M-PV-ZERO | |
| NUM-C-02 | כִּתְבוּ אֶת הַמִּסְפָּר שִׁשִּׁים | 60 | 6 M-PV-ZERO, 600 M-PV-ZERO | |
| NUM-C-02 | כִּתְבוּ אֶת הַמִּסְפָּר אַרְבָּעִים וָשֶׁבַע | 47 | 74 M-NUM-REV, 407 M-PV-ZERO | |
| NUM-C-03 | `? = 30 + 4` | 34 | 304 M-PV-ZERO, 43 M-NUM-REV | face_value M-PV-FACE |
| NUM-C-03 | `58 = ? + 8` | 50 | 5 M-PV-FACE, 66 M-EQ-OPER | |
| MATH-C-01 | `8 + 7 = ?` | 15 | 14 M-CNT-DOUBLE, 8 M-CNT-CARD, 1 M-OP-SWAP | |
| MATH-C-01 | `9 + 6 = ?` | 15 | 14 M-CNT-DOUBLE, 9 M-CNT-CARD, 3 M-OP-SWAP | |
| MATH-C-01 | `15 − 7 = ?` | 8 | 22 M-OP-SWAP, 9 M-CNT-DOUBLE, 12 M-SUB-SMALLBIG | smaller_from_larger M-SUB-SMALLBIG, added_instead M-OP-SWAP |
| MATH-C-01 | `13 − 6 = ?` | 7 | 19 M-OP-SWAP, 8 M-CNT-DOUBLE, 13 M-SUB-SMALLBIG | smaller_from_larger, added_instead |
| MATH-C-01 | `7 + ? = 16` (reverse) | 9 | 23 M-EQ-OPER, 16 M-EQ-OPER, 10 M-CNT-DOUBLE | |
| MATH-C-02 | `15 − ? = 9` | 6 | 24 M-OP-SWAP, 15 M-EQ-OPER | added_instead M-OP-SWAP |
| MATH-C-02 | `? − 6 = 9` | 15 | 3 M-OP-SWAP, 9 M-EQ-OPER | |
| MATH-C-03 | `40 + 30 = ?` | 70 | 7 M-PV-FACE, 700 M-PV-ZERO, 10 M-OP-SWAP | off_by_ten M-REGROUP-FORGET is not used (no regrouping) |
| MATH-C-03 | `90 − 50 = ?` | 40 | 4 M-PV-FACE, 400 M-PV-ZERO, 140 M-OP-SWAP | added_instead M-OP-SWAP |

Prepared: all rows but one (`c.numc02.13` to `.15`, `c.numc03.21` and `.22`, `c.mathc01.27` to `.31`, `c.mathc02.13` and `.14`,
`c.mathc03.13` and `.14` when on). Changed: `9 + 6` is `9 + 5 = 14` (13 M-CNT-DOUBLE, 9 M-CNT-CARD, 4 M-OP-SWAP), so that every fact
item of MATH-C-01 is in one of its fact families (`variantGroup` `fact-a-b`; setCoverage asks for each family once). The
`9 = 15 − ?` row below is not prepared: it waits for the true-or-false card with its `6 − 15 = 9` sentence.

Number entry is also the place for the M-SUB-ORDER diagnostic of MATH-C-02 (M10 §4.2: "6 − 15 = 9 accepted"). A choice item cannot
show it without a true-or-false sentence card; I recommend a keypad item `9 = 15 − ?` with 24 M-OP-SWAP and a `spot_error` sentence
`6 − 15 = 9` once T25 or a true/false card exists. Until then MATH-C-02 watches M-OP-SWAP and M-EQ-OPER only (its skill file says so).

## 4. `number_line` 0 to 100 with a tolerance (X5)

NUM-C-06 in content places numbers on windows of twenty (40 to 60, labels at the ends and the middle ten), because today's line takes
only an exact tick and 101 ticks do not fit a phone. The skill as written (curriculum §4: "error ≤ 8") needs X5:

| Item | Line | Labels | Target | Tolerance | Tags |
|---|---|---|---|---|---|
| place | 0 to 100, ticks of 10 | 0, 100 | 70 | 8 | 30 M-NL-DIR (mirrored), 7 M-PV-FACE |
| place | 0 to 100 | 0, 50, 100 | 23 | 8 | 77 M-NL-DIR |
| place | 0 to 100 | 0, 100 | 45 | 8 | 55 M-NL-DIR |
| place | 0 to 100 | 0, 100 | 88 | 8 | 12 M-NL-DIR, 8 M-PV-FACE |
| estimate (predict) | 0 to 100, the frog stands on an unlabelled tick near 60 | 0, 100 | 60 | 8 | 40 M-NL-DIR |

When X5 is drawn, these replace four of the window items (keep two windows for the transfer check). Not prepared: the number line
schema has no tolerance yet, and X5 is not in the app-developer's step-3 work (base_ten, hundred_chart and the keypad).
