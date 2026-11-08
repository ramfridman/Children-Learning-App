# M10 batch C1: the items that wait for batch step 3

The maths teacher, 2026-11-06; prepared in the generator 2026-11-07 (QA-C1-5). Batch C1 (docs/milestones/M10.md §4.1, §4.2, §7) is in
content with only the items that today's sessions draw. The items below need a mode that no session draws yet (security review of step
0: `qa_m10s0_undrawn_modes_test.dart` fails on any `scene.picture` or `answer.type: number` in content).

**State (2026-11-07, round 2): C1 is complete. Section 6 lists what is now in content; section 7 (QA-C1b-5) gives M-ADD-RECOUNT its diagnostic item and makes the coverage a CI gate.** Before that, **step 3 (2026-11-07): in content.** The app-developer drew the three modes and the new fields of the blocks picture (`litRods`,
`crossedRods`, `scene.picture2`, `answer.options[].picture`) and switched every `DRAWN` entry on (commit d648af2b). The maths teacher
then wrote the items that need the new fields and the items that criterion 2 and criterion 7 still lacked (section 5). `tools/author.py`
`k_pick` carries `picture` and `picture2` into the scene and takes an option of blocks as `{'key', 'picture', 'label'}`; its
representation is pictorial and it needs tap_answer 1.4. `tools/test_check_maths.py` (class `C1Deferred`) now checks that every mode is
drawn, that every waiting item is in content exactly as the generator writes it, and that the items on disk pass `check_maths --strict`.

The history of the switch-on, kept for the next batch that adds a mode: the app-developer sets the mode's `DRAWN` entry True in the
commit whose session draws it, takes its check off `qa_m10s0_undrawn_modes_test.dart`, runs `python -I tools/regen_content.py`, then
`python -I -X utf8 tools/check_maths.py --ids c. --strict` and the content tests. A waiting item comes after every drawn item of its
skill, so switching a mode on renumbers no item.

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
`6 − 15 = 9` once T25 or a true/false card exists. **Done in round 2 (section 6):** the keypad `9 = 15 − ?` is c.mathc02.15 and the true-or-false card c.mathc02.16 to .19; MATH-C-02 now watches M-SUB-ORDER too.

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

When X5 is drawn, these replace four of the window items (keep two windows for the transfer check). **Done in round 2 (section 6)**, with
the changes said there.

## 5. Step 3 (2026-11-07): the items the new fields allow, and the gaps of criteria 2 and 7

Every answer, distractor and tag rule below is recomputed by `check_maths` (0 WRONG, RULE, AMBIG, UNCHECKED over `--ids c.`). New rules:
a lit rod is what the caption asks about when it says "the rod" (10 × `litRods`; M-PV-FACE is the rod counted as one); two pictures with no
row are a comparison of their two numbers (both must be on a tile; M-PV-FACE is the ones-first pick of the two); over a sentence,
`picture2` is the second number of a sum and `crossedRods` the number taken away; blocks on a tile are read as their number (its label
must say it; for "where is 34?" M-PV-FACE is the digits as loose cubes, 7); the middle of two marks of a line (`40 ? 50`) is solved as a
row, and M-NL-SPACE is the mark next to an end.

| Id | Skill | Item | Answer | Wrong options and tags |
|---|---|---|---|---|
| c.numc03.24 | NUM-C-03 | blocks 2, 7 with one rod lit: כַּמָּה שָׁוֶה הַמּוֹט שֶׁזּוֹהֵר? | 10 | 1 M-PV-FACE, 100 M-PV-ZERO |
| c.numc03.25 | NUM-C-03 | blocks on the tiles: אֵיפֹה הַמִּסְפָּר שְׁלוֹשִׁים וְאַרְבַּע? | 3 rods 4 cubes | 4 rods 3 cubes M-NUM-REV, 7 cubes M-PV-FACE |
| c.numc02.18 to .20 | NUM-C-02 | blocks on the tiles: 37, 60 and 52 (transfer) | the blocks of the number | 73 M-NUM-REV; 6 cubes M-PV-ZERO; 25 M-NUM-REV and 7 cubes M-PV-FACE |
| c.numc04.13 to .16 | NUM-C-04 | two numbers of blocks side by side, numerals on the tiles (`compare-blocks`) | 41; 27 (smaller); 52; 53 (transfer, was 64, section 8) | 39, 31, 48, 49 M-PV-FACE; 14, 72, 25, 35 M-NUM-REV |
| c.mathc03.15, .16 | MATH-C-03 | 4 rods beside 3 rods, said אַרְבָּעִים וְעוֹד שְׁלוֹשִׁים; 3 beside 5, `30 + 50` (`tens-blocks`; no row since section 8) | 70; 80 | 7, 8 M-PV-FACE; 700, 800 M-PV-ZERO; 10, 20 M-OP-SWAP |
| c.mathc03.17, .18 | MATH-C-03 | 7 rods, 4 crossed out, said שִׁבְעִים פָּחוֹת אַרְבָּעִים; 6 rods, 2 crossed, `60 − 20` (transfer; no row since section 8) | 30; 40 | 3, 4 M-PV-FACE; 300, 400 M-PV-ZERO; 110, 80 M-OP-SWAP |
| c.mathc02.15 | MATH-C-02 | keypad `9 = 15 − ?` (= first) | 6 | 24 M-OP-SWAP, 15 M-EQ-OPER; rule added_instead |
| c.numc03.26 to .28 | NUM-C-03 | pay 34, 52, 60 shekels with tens and ones coins (concrete; the purse allows no other way) | the price | M-MONEY-COUNT |
| c.mathc01.32, .33 | MATH-C-01 | the balance: 8 + 7 against 10, 9 + 5 against 10, add blocks (concrete; families 8-7 and 9-5) | 5; 4 | M-EQ-OPER |
| c.numb06.15, .16 | NUM-B-06 | count by touch, then the numeral (concrete) | 6; 9 | 9, 6 M-NUM-REV; 7 M-CNT-DOUBLE, 8 M-CNT-SKIP |
| c.numb09.15, .16 | NUM-B-09 | count by touch (concrete; count_tap has no ten-frame) | 8; 7 | the neighbours, M-CNT-SKIP and M-CNT-DOUBLE |
| c.numc06.14 to .16 | NUM-C-06 | the middle of two marks, `40 ? 50`, `20 ? 40`, `30 ? 40` (symbolic, `middle`) | 45; 30; 35 | 41, 21, 31 M-NL-SPACE; 90, 60, 70 M-EQ-OPER (its own line) |
| c.numc01.15, c.numc09.17 | NUM-C-01, C-09 | the chart: after 69 (end of a row); ten more than 62 | 70; 72 | 60 M-CNT-DECADE, 71 M-CNT-SEQ; 63 M-HC-ROW, 52 M-OP-SWAP |
| c.numc02.16, .17; c.numc03.23 | NUM-C-02, C-03 | keypad: write 58, write 81; `? = 70 + 6` | 58; 81; 76 | 85, 18, 67 M-NUM-REV; 508, 801, 706 M-PV-ZERO; face_value |
| c.numb01.3, .4; c.numb10.3, .4 | NUM-B-01, B-10 | two jumps; two more size traps (`size-trap`) | 13, 17; 8, 6 | the line's tags; M-CNT-SIZE |

The 58 and 43 towers of §1 are not written: the ones-first reading picks 58 too, so the one wrong tile would carry no tag; the lucky-right
item of M-PV-FACE in NUM-C-04 stays `58 > ?`.

What step 3 still lacked (X5, the M-SUB-ORDER card, NUM-B-09's ten-frame and six gaps of criterion 3) is done in section 6.

## 6. Round 2 (2026-11-07): the last pieces of C1

The app-developer drew the last fields (commit f02c57f9): number_line 1.1 (`scene.tickStep`, `answer.tolerance`; the validator refuses a
line that does not end on a tick, a tolerance on a jump or as wide as the line, and a mirror inside the tolerance), give_n 1.1
(`scene.frame`, a ten-frame target) and the true-or-false card (a tap_answer whose row is a whole sentence, the tick and the cross on the
tiles). `tools/author.py` `template_version` gives number_line 1.1 for `tickStep` or `tolerance` and give_n 1.1 for `frame`; `k_numline`
writes both fields (the mirror tag only when the mirror is more than twice the tolerance away, the validator's rule) and takes an item's
own hint 2; `k_give` writes `frame`, extra classifiers and an item's own hints. `tools/check_maths.py` reads the new items: the tolerance
line (the right region is the target ± the tolerance; WRONG for a step that does not end the line or a tolerance off a place item, RULE for
a mirror tag inside twice the tolerance or one other than M-NL-DIR, AMBIG for a written number inside the right region, RULE for a written
target; M-NL-DIR is lucky-right when the mirrored touch lands in the region), the true-or-false card (the tick is right when the sentence
is true; M-SUB-ORDER only on the tick of a false take-away that is true the other way round, M-EQ-OPER only on the cross of a true sentence
whose = is not just before its answer; M-SUB-ORDER is lucky-right on a true take-away card), and M-CNT-DECADE is now lucky-right on "after
34" (the next number or the one before, neither at a ten). Tests: `tools/test_check_maths.py` class `C1Last`. Every answer and tag below is
recomputed by `check_maths --ids c. --strict` (0 WRONG, RULE, AMBIG, UNCHECKED over 237 items).

| Id | Skill | Item | Answer | Wrong answers and tags |
|---|---|---|---|---|
| c.numc06.3 | NUM-C-06 | line 0 to 100, ticks of ten, 0, 50 and 100 written: about 23 (X5, tolerance 8) | 15 to 31 | the mirror 77 ± 8 M-NL-DIR; any other miss M-NL-SPACE |
| c.numc06.4 to .6 | NUM-C-06 | the same line, only 0 and 100 written: about 70, 35, 88 | the target ± 8 | the mirror (30, 65, 12) ± 8 M-NL-DIR; any other miss M-NL-SPACE |
| c.numc06.17 | NUM-C-06 | the same, about 64 (the second lesson ends on the whole line) | 56 to 72 | 36 ± 8 M-NL-DIR; any other miss M-NL-SPACE |
| c.mathc02.16, .18 | MATH-C-02 | true or false: `6 − 15 = 9`, `8 − 17 = 9` | the cross | the tick M-SUB-ORDER (15 − 6 and 17 − 8 are 9) |
| c.mathc02.17 | MATH-C-02 | true or false: `9 = 15 − 6` (= first; lucky-right for M-SUB-ORDER) | the tick | the cross M-EQ-OPER |
| c.mathc02.19 | MATH-C-02 | true or false: `8 + 6 = 6 + 8` (an addition can be turned round, a take-away cannot) | the tick | the cross M-EQ-OPER |
| c.numb09.15, .16 | NUM-B-09 | fill a ten-frame with 8 stars, 7 ducks, from a jar of ten (give_n 1.1, concrete) | 8; 7 | all ten M-CNT-CARD; fewer M-CNT-DOUBLE (two numbers for one); more M-CNT-SKIP (one put down uncounted) |
| c.numc01.16 | NUM-C-01 | the chart, 34 lit: what comes after 34? (lucky-right for M-CNT-DECADE; two options) | 35 | 36 M-CNT-SEQ |
| c.numc02.21 | NUM-C-02 | keypad: write 55 (lucky-right for M-NUM-REV) | 55 | 505, 550 M-PV-ZERO |
| c.numb06.17 | NUM-B-06 | count 8 birds by touch, then the numeral (lucky-right for M-NUM-REV: 8 turned is 8) | 8 | 7 M-CNT-SKIP, 9 M-CNT-DOUBLE |
| c.mathc01.34 | MATH-C-01 | `17 − 4 = ?` (no ten to open; lucky-right for M-SUB-SMALLBIG; its own family, 13 + 4) | 13 | 21 M-OP-SWAP, 14 M-CNT-DOUBLE |

Changes from section 4: 45 is 35, because the mirror of 45 (55) is inside the tolerance (|100 − 2 × 45| = 10 ≤ 16): a child who runs the
line from the right would be marked right and M-NL-DIR could not show (the validator refuses it). The fifth row is 64 on the same line,
since the number_line template has no "which number does the frog stand on?" reading mode for the predict row. The miss tag is
M-NL-SPACE, not M-PV-FACE: the session gives every miss outside the tolerance and the mirror one tag, and a miss on a 0 to 100 line is
the line read with unequal gaps (the logarithmic placement of young children, Siegler and Opfer 2003), not digits read by face value.

The four windows 60 to 80, 80 to 100, 30 to 50 and 70 to 90 became c.numc06.3 to .6 (no other id moved); the two counts by touch of
NUM-B-09 became the ten-frames under the same ids (a row of five, then the rest, is the structure the flash items ask the child to see).
Lessons: line-to-100 is the two windows of twenty with three marks, the two with the ends only, then the four estimates; line-to-100-more
is the jumps, the middle of a line, the middles of two marks and the fifth estimate (8 and 9 items). fact-families is split: its first 8
items, and fact-families-more with the other 4 and the four cards (8 and 8). The lucky-right items join hundred-chart (9), write-numbers
(9), read-numerals-more (9) and facts-to-18-again (11). The misconception record M-SUB-ORDER is new in the pack (parent text, home
activity, its child line `vo:fb.sub_order`).

The coverage of every watched tag over `--ids c.` (`check_maths --coverage`) now has a diagnostic item and, where the tag's error can give
a right answer, a lucky-right item. Since QA-C1b-5 this is a gate: `check_maths --ids c. --coverage --strict` (CI, hygiene job, next to
the C1 gate) fails when a watched tag of a skill with c.* items has no diagnostic item anywhere in the pack, unless the tag is in
`NOT_ITEM_OBSERVABLE` with its reason (empty today). A classifier (give_n `took_all`) and a keypad rule (`face_value`) count as recording
their tag.

## 7. QA-C1b-5 (2026-11-07): M-ADD-RECOUNT gets its diagnostic item

Decided: **an item, not a dropped tag.** MATH-B-04 *is* the move from counting all to counting on (curriculum §4; Clements and Sarama's
"Counting On" level), so dropping its one watched tag would leave the skill watching nothing. The tag stays, and the item that makes a
recount visible in a tap-only, untimed setting is the hidden-collection task (Steffe and Cobb 1988; curriculum §5.2 R2 "a hidden cup"):
the larger number is in a closed basket, said and not drawn, and only the ones added are drawn. A child who can only count all from one
has nothing to count but the drawn ones and taps their number. With every set drawn (the six sentence items) counting all still gives the
sum, so there the tag can only be lucky-right; `check_maths` now refuses M-ADD-RECOUNT on a distractor of an item where nothing is hidden.

| Id | Item (tap_answer 1.1, one group drawn) | Answer | Wrong options and tags |
|---|---|---|---|
| c.mathb04.11 | בַּסַּל הַסָּגוּר יֵשׁ שִׁבְעָה תַּפּוּחִים. מוֹסִיפִים לַסַּל עוֹד שְׁנֵי תַּפּוּחִים. (2 apples drawn) | 9 | 2 M-ADD-RECOUNT, 7 M-CNT-CARD, 10 M-CNT-DOUBLE |
| c.mathb04.12 | the same with 8 stars in the basket and 3 drawn | 11 | 3 M-ADD-RECOUNT, 8 M-CNT-CARD, 12 M-CNT-DOUBLE |

Both join the lesson count-on-big (12 items). A right answer is no proof of counting on (a child can make the seven on the fingers and
count all), so the rule `lucky` counts every sum of MATH-B-04 as lucky-right for the tag (8 items); the slower trace signal of §5.2 stays
the engine's. What a recount looks like when it is not visible in the answer (time, taps) is still a trace classifier for the app-developer.

Left outside C1 (the pack-wide `--coverage --strict`): MATH-B-01 and MATH-B-08 watch M-ADD-RECOUNT with no item (the closed basket fits
both; Band B generator), and MATH-B-10 watches M-SHARE-UNEQ with no item. NUM-B-01 M-CNT-SEQ passes the C gate through its 9 Band B
items (b.numb01.*).

Not C1: the place-value mat (T26) of NUM-C-03 and X5's `open` mode are batch C2.

## 8. Every cube countable (2026-11-07): the compare transfer and the sentences over rods

The owner's rule for the C1 blocks is a cube of at least 12 pt on every board (`docs/design/c1-blocks.md` sections 2 and 5). Two cases
broke it, and the content changed, not the rule:

- **c.numc04.16** compared 64 with 59 (six rods beside five, 11.0 pt on the phone SE, waived). Now **53 against 49** (5 rods and 3 cubes,
  4 rods and 9 cubes): each picture keeps the compare limit (at most 4 tens, or 5 tens with 5 ones or fewer). What it checks is the
  same: the ones-first reading picks 49 (9 > 3, M-PV-FACE, the tens tell first), 35 is 53 read the other way round (M-NUM-REV, smaller
  than the answer as 46 was), and the tens differ by one with the ones pulling the other way, as 64/59 did. 12.7 pt on SE, 14.9 on the
  phone, 24.9 on tablets. The waiver list is empty.
- **c.mathc03.15 to .18** drew a number sentence row under the rods, which left the cubes about 8 pt on phones. The row is gone; the
  blocks have the stage (Layout S) and the sentence is **said in the question**: אַרְבָּעִים וְעוֹד שְׁלוֹשִׁים. כַּמָּה זֶה? and
  שִׁבְעִים פָּחוֹת אַרְבָּעִים. כַּמָּה נִשְׁאַר? (the Band B form "x וְעוֹד y. כַּמָּה זֶה?"). The child hears the sentence while
  looking at its rods (the first number left, as it is written), and the right answer says it back with שָׁוֶה. The written sentence is
  not lost: the same sentences 40 + 30 and 70 − 40 are the symbolic items c.mathc03.1 and .5 of the lesson before (whole-tens), so the
  link between the rods and the symbols runs across the two lessons. A split (a blocks item, then a sentence item) was not chosen: it
  would only repeat .1 and .5. 13.9 pt on SE, 14.9 on the phone, 24.9 on tablets. The tags and options did not change.

`check_maths` reads a sentence said over blocks with no row (`said_sentence`: one וְעוֹד or פָּחוֹת between the only two numbers of the
question) and checks it against the pictures as it checks a row (`sentence_blocks`), and a take-away must ask כַּמָּה נִשְׁאַר; M-OP-SWAP
now has a rule (the other operation: 40 + 30 gives 10, 70 − 40 gives 110), which every tagged item of the pack keeps.

Proposal, not built: a bubble that can show a short LTR sentence beside the spoken question (`40 + 30 = ?` in an isolated maths run) would
let the blocks item show the symbols too; that is a template change for the app-developer and the design-director, the owner's call.
