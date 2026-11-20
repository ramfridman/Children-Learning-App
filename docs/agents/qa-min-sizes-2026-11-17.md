# QA: the automatic minimum-size test of the child's space (M11), 2026-11-17

QA engineer. Branch `lands-ux`, tip `cadc6004`, the test files are new and **uncommitted** (untracked in `app/test/`). Nothing under `app/lib` was
touched, no workflow was edited, nothing was committed. This is the focused deliverable for the owner's rule of 2026-11-16 ("not too small to see or
read in any of the devices"), not the Stage 2 QA pass.

**The test works and today it fails 5,959 measurements** (S1 3937, S2 1531, S3 491 over four boards; the severity is the design's: S1 content too
small to see, count or touch; S2 under a floor but usable, or text and numerals under their rule; S3 wasted room). They are all recorded in one map
(`app/test/support/min_sizes_known.dart`), which each board file asserts **exactly**: a new failure, a fixed one, or a changed value or count fails
the run (shown below, section 7).

## 1. What was written

| File | What |
|---|---|
| `app/test/min_sizes_test.dart` | The quick part, about 7 s, no screen: the floors are the design's numbers (the tokens), every one of the 1,328 activities is in exactly one layout group and every template/band/Show has a group, the hint families reach every template, every kind of Show has a lesson, the map of known failures is well formed and names things that exist, and it prints the summary table (`MINSIZES-SUMMARY`). |
| `app/test/min_sizes_phone_test.dart`, `min_sizes_phone_se_test.dart`, `min_sizes_tablet_l_test.dart`, `min_sizes_tablet_p_test.dart` | The screens, one file per board (so that the CI shards can take them apart). 24 tests each. Each asserts the map for its board and prints one `MINSIZES` line per slice. |
| `app/test/support/min_sizes_measure.dart` | Reads the live widget tree: every text (as drawn: font size x text scale x any FittedBox shrink), every picture (its **ink**, from `inkBoxOf`, not its box), answer tiles with their touch area, draggables, icons, hands, keyed rects. |
| `app/test/support/min_sizes_rules.dart` | The 31 rules (section 3) and the judge. |
| `app/test/support/min_sizes_catalogue.dart` | The layout fingerprint (section 2). |
| `app/test/support/min_sizes_run.dart`, `min_sizes_suite.dart` | The runner, the openers (lesson, Show in its room, language course) and the comparison with the map. |
| `app/test/support/min_sizes_known.dart` | **The one map of known failures**: key `board|look|text size|kind|screen|RULE`, value (rule, worst measured, floor, how many pieces). 5,959 entries. |

The two pre-existing files `min_sizes_shots_test.dart` and `min_sizes_round2_test.dart` were left alone. The scratch folder `app/test/tmp_probe/` is removed.

## 2. How coverage works

Each activity is opened on the real lesson screen (`LessonScreen`, a one-item mission), settled for 1.4 s (a check of 80 screens at 1.4 s against 5.4 s found
no difference), read, judged and closed. Four boards (phone 852x393, phone SE 667x375, tablet landscape 1180x820, tablet portrait 820x1180), text sizes 1.0
and 1.3 (`textScaleFactorTestValue`). The child's **look** follows the activity's band: Band A is P1 (tile 96/112), B is P3 (88/104), C is P4 (80/96).

| Slice (`kind` in the key) | What is opened | Per board |
|---|---|---|
| `item` | **Every activity of the pack that is not a Show (1,224 of 1,328)**, at 1.0 and at 1.3, each in the look of its band | 2,448 screens |
| `sorted` | The same sorts after two or three cards were dragged into their bins (the pile, the badge, the cards in a bin) | 310 |
| `hint1`, `hint2`, `hint3` | 78 hint families (one activity of each family of the hint goldens, the Band C families, and every template), the lamp pressed once, twice, three times. A hint slice lists only what the hint **adds or makes worse** than the activity's own screen | 234 |
| `show-host`, `show-turn` | The Show of every kind of lesson (11 Show templates x the bands they exist in = 22 lessons), in its room with the host at work (10.5 s) and at the child's turn (22 s), at both text sizes | 88 |
| `lang`, `lang-lesson` | The three real courses (eng, heb, rus) built from `content/languages`: the first activity of each layout, the heaviest (most text) of each layout, and every tenth by id (not the say-it Meet items: they need their lesson), plus the **first screen of the lessons** (the Meet screen with the opener said, the first Find, the first Use) of a representative lesson of each kind and every fifth lesson. Parent band 0 at 1.0, band 2 at 1.0 and at 1.3 | 1,122 |

About **4,200 screens a board, 16,800 in all**. Why every activity and not one of each layout: I first built a layout fingerprint (template, version, band, number of
options, set sizes, arrangement, bin counts, number-line range, the class of each picture; 472 groups for 1,328 activities, 397 of items and 75 of Shows) and opened
the first activity of each. A sweep of **every** activity then compared each one with its representative: **9 to 15 in 100 of the others failed a rule set that the
representative did not** (phone, P1: 47 of 309 others in 22 of 155 layouts; P3: 37 of 401; P4: 0 of 117; SE P1 62 of 309; tablet L P1 29, tablet P P1 33). What a
fingerprint cannot see is the words (a hint line that is too long for the caption floor) and which picture is drawn (a bird has more ink in its box than a ball).
The sweep is cheap (about 0.1 s a screen), so the test opens everything instead. The fingerprint is kept for the language screens and for the coverage check in
`min_sizes_test.dart`. **Language coverage is by sample, not complete** (the 1,768 language activities are not all opened); a sweep of them is a hand-off to do before the
language Stage 2 pass.

Looks: the language lessons run in the child profile of the test rig (P3), with the parent's band 0 or 2 changing the reading sizes.

## 3. The rules (all thresholds in points; same on every board unless a tablet value is given)

| Rule | Sev | Design | What is measured (floor) |
|---|---|---|---|
| TILE_H | S1 | R4, 5.1 | answer tile height under the look's tile (96/88/80 phone, 112/104/96 tablet); the controls (clock, robot arrows, keypad, undo) are held to the minimum control instead |
| TILE_HIT | S1 | R4, 6.1 | touch area of a tile or control under the look's minimum control (64 for P1/P2, 56 for P3/P4) |
| DRAG | S1 | R4 | a draggable's shorter side under the minimum control |
| CHROME | S1 | 6.1 | lamp, home, mic, "show me" under the minimum control |
| PIC_ID | S1 | R1 | a picture to identify (a lone picture, or one on a tile): the ink under 40 |
| PIC_DETAIL | S1 | R2 | a detail in a composite (a set, a pan, a chart, several pictures on a tile): the ink under 24 (32 on tablets for pans, charts and sets on tiles); a pattern-strip animal is 0.143 of the card width |
| COUNT_OBJ, COUNT_TOUCH | S1 | R3, A9 | a counted object touched one by one: the drawn ink under 40; its touch square under the minimum control |
| BIN_ITEM | S1 | R5, 3.4 | an item shown in a bin, its box under 48 (44 SE, 64 tablet) |
| BIN_STRIP | S1 | R5, A1 | a pattern card in a bin or the tray under 68 high (100 on tablets) |
| BIN_SAMPLE | S1 | R1, 5.2 | a bin's sample picture box under 40 (56 on tablets) |
| BIN_INK | S1 | R1/R5 | the drawn ink of a bin sample or of an item in a bin under 40 (the box is not what the child sees) |
| CLOCK_FACE, GIVE_TRAY | S1, S2 | A3, B6 | clock face under 174 (240); a give-tray picture under 32 (48) |
| LABEL_SIZE, LABEL_WEIGHT, LABEL_LINE | S2 | R6, 9.4 | Hebrew text outside the bubble under 18 (20 on tablets); heavier than w500 under 24; pointed text with a line height under 1.7 |
| LATIN_SIZE | S2 | R6 | English or Russian text of the child under 18 (20) |
| NUMERAL | S2 | R7 | a numeral the child reads under 20 (24) |
| NUMLINE_LABEL, NUMLINE_TICKS | S2 | B1 | number-line labels under 20 (28); spacing of the labels per unit under 24 (32), on lines of 20 units or fewer |
| CAPTION | S2 | R8, V2 | the bubble's caption under the look's caption minus 2 (P1 24, P3 22, P4 20; SE 22, 20, 18; tablet 30, 28, 26) |
| ICON | S2 | R9 | the glyph on a control tile (keypad, undo, clock, balance) under 32 (40) |
| ICON_PROGRAM, ROBOT_STRIP | S2 | R9, B2 | an arrow in the robot's program under 28 (40); the strip under 44 high (56) |
| COIN, PRICE | S2 | B3 | a coin in the purse under 48 across (64); the price numeral under 24 (32) |
| TRACE_PAD | S2 | A10 | trace pad under 220 high (360) |
| HAND_BUBBLE | S2 | V4 | the hint hand's box covers 150 square points or more of a paragraph of the bubble |
| STAGE_CARD | S3 | C1, C2 | tablet stage card narrower than 848 (landscape) or lower than 520 (portrait; 420 with two rows of tiles); the card is the stage plus its 16 point rim |
| EMPTY_BAND | S3 | C3, S4 | the empty band under the last content taller than 25 % of the board (98 / 94 / 205 / 295); on a tablet the card counts as content |
| LAYOUT_ERROR | S1 | - | the framework reported an error (an overflow stripe) while the screen was laid out |

Measures and tolerances, so the numbers can be read: a picture's size is its **ink** as drawn (the SVG's ink box from `inkBoxOf`, through the fit and any
transform), as the side of the square of the same area, and not less than half of its longest side (a line has no area); tolerance 1 pt. Sizes of text, tiles and
touch areas: tolerance 0.5 pt. A text's size is what is drawn: it includes the system's text scale and any FittedBox shrink above it. The backdrop (`BoxFit.cover`),
the companion, the hint hand and the bubble's own text are not pictures or labels of the child's task; nothing else is exempt.

**Rules that pass everywhere today** (no failing measurement on any board): TILE_HIT, DRAG, BIN_STRIP, LABEL_SIZE, LABEL_LINE, LATIN_SIZE, NUMLINE_LABEL, CLOCK_FACE, PRICE, TRACE_PAD, GIVE_TRAY, CHROME. So the clock face, the trace pad, the number-line labels, the price, the give tray,
the pattern-strip cards, the drag sizes, the touch areas of all tiles and the frame's controls are verified at or above their floors.

## 4. Run time and CI

Asserted runs, one file at a time on this Windows PC (wall clock, including about 10 s of compile and the loading of the three course packs): phone 3m11s, phoneSE 3m16s, tabletL 3m18s, tabletP 3m15s. `min_sizes_test.dart` takes
about 7 s. About 14 minutes of CPU in all, 4 files of about 3.3 minutes each; before the move to "every activity" the same files took 2 m 35 s each.

**For the infrastructure-engineer (hand-off; I did not edit workflows or `tools/ci/test-shard.py`):**
1. `tools/ci/test-shard.py` gives an unlisted file the default weight 8 s, so these four would be placed as if they were nothing. Add `min_sizes_phone_test.dart`, `min_sizes_phone_se_test.dart`, `min_sizes_tablet_l_test.dart` and `min_sizes_tablet_p_test.dart`, each with weight 200, to `WEIGHTS`.
2. The CI shards have a 20-minute limit and shard 1 timed out once on PR 62. Adding 13 minutes of CPU to three shards is about 4 minutes each on a 6-worker machine, so it is **not safe on the present three shards**: add a fourth shard (`shard: [1, 2, 3, 4]`) or raise the timeout to 25 minutes.
3. The values in the map were produced on Windows. A value that depends on text metrics (a numeral shrunk to fit a tile, a caption fitted to its bubble) may differ by a fraction of a point on Linux. The comparison tolerates 0.5 pt in the value and none in the count. Run the four files once on CI; if they print `MOVED`/`NEW` lines, send them back and I will re-baseline from the CI numbers.

## 5. The totals

| Board | S1 | S2 | S3 | Total |
|---|---:|---:|---:|---:|
| phone | 1301 | 460 | 188 | 1949 |
| phoneSE | 1561 | 663 | 193 | 2417 |
| tabletL | 486 | 215 | 32 | 733 |
| tabletP | 589 | 193 | 78 | 860 |
| **all** | **3937** | **1531** | **491** | **5959** |

By rule and board (a failing measurement is one rule on one screen at one text size, with the worst value of the screen; the same defect on 100 activities counts 100):

| Rule | Sev | phone | phoneSE | tabletL | tabletP | Total |
|---|---|---:|---:|---:|---:|---:|
| TILE_H | S1 | 299 | 293 | 219 | 316 | 1127 |
| BIN_INK | S1 | 480 | 483 | 62 | 62 | 1087 |
| PIC_ID | S1 | 279 | 358 | 68 | 68 | 773 |
| CAPTION | S2 | 241 | 290 | 0 | 0 | 531 |
| EMPTY_BAND | S3 | 188 | 193 | 0 | 26 | 407 |
| ICON | S2 | 86 | 86 | 86 | 86 | 344 |
| PIC_DETAIL | S1 | 78 | 198 | 32 | 32 | 340 |
| BIN_ITEM | S1 | 70 | 67 | 67 | 67 | 271 |
| NUMERAL | S2 | 61 | 73 | 61 | 61 | 256 |
| COUNT_TOUCH | S1 | 52 | 86 | 4 | 6 | 148 |
| NUMLINE_TICKS | S2 | 0 | 140 | 0 | 0 | 140 |
| COUNT_OBJ | S1 | 41 | 74 | 0 | 4 | 119 |
| ICON_PROGRAM | S2 | 24 | 24 | 20 | 20 | 88 |
| ROBOT_STRIP | S2 | 24 | 24 | 20 | 20 | 88 |
| STAGE_CARD | S3 | 0 | 0 | 32 | 52 | 84 |
| COIN | S2 | 18 | 20 | 26 | 4 | 68 |
| BIN_SAMPLE | S1 | 0 | 0 | 28 | 28 | 56 |
| LAYOUT_ERROR | S1 | 2 | 2 | 6 | 6 | 16 |
| LABEL_WEIGHT | S2 | 2 | 2 | 2 | 2 | 8 |
| HAND_BUBBLE | S2 | 4 | 4 | 0 | 0 | 8 |

By slice: item 3938, sorted 1028, lang 417, hint3 237, show 236, hint2 96, hint1 7.

## 6. Where the failures are, against what the developer and the designer said

**Claimed done, measured not done** (the developer's reports of 2026-11-17 and 17b; the failing screens are in the tables):
- **A9 count-and-tap** (round 1: "touch 64 or more for 3 to 8 objects"): COUNT_TOUCH and COUNT_OBJ fail on every board. The touch squares of the maths count-tap are 54, 43, 36, 27 and 21 for 4, 5, 6, 8 and 10 objects on a phone in the activities `b15.numa01.2` to `b15.numa02.3`, and the Show `many-things` (13 things) has squares of 16 and things of 12. The stage was not made tall for those counts.
- **B2 robot strip** (round 2: "strip 44, arrows 28"): ROBOT_STRIP and ICON_PROGRAM fail on every board. On a phone the strip is 28 high and the arrows are drawn at 19.6 (a FittedBox shrinks the 44 box); on a tablet 48 and 28 against 56 and 40.
- **C1/C2 "every tablet lesson has the grown card"**: STAGE_CARD fails on 84 screens: 64 are Band C items (`c.mathc03.*`, `c.numc02.*`: 584 x 300 on landscape, 264 high on portrait) and 20 are sorts in portrait (420 against 520: the design allows 420 only with two rows of tiles).
- **V13 hint chips** (listed as not built): confirmed, 12 to 14 pt on phones and 19.6 on tablets against 20 / 24 (the design asks 32 and 40 chips with a digit of 20 / 24).
- **A4/A8 sets on tiles, the sort board**: the sort board numbers of section 3 of the design are met (the strip cards, labels 18/24 w500, the tray tiles of the new boards), but the **ink** of a picture in a bin is far under 40: BIN_INK is the largest S1 family. Items drawn from line shapes and thin shapes are the worst.

**Failures the design audit did not list** (the audit's own ids are in the last column of the tables; "MISSED" means no id):
- **An overflow stripe in the robot Show** `longer-robot-paths` (P3, on both phone boards, "A RenderFlex overflowed by 162 pixels on the right"), and a 28-pixel overflow in the number-line items `c.numc06.3, .4, .5, .6, .12, .17` at text size 1.3 on both tablets. The first is on the screen the child watches while the host plays.
- **A bold nikud label under 24** (w700 at 22 pt, `שָׁלוֹשׁ`) in the same robot Show: it breaks the nikud weight rule (R6; the design listed it only for the trophy hall, H4).
- **The glyph on the keypad of Band C maths** (26 pt, 18 % under on a phone, 35 % on a tablet) and **the robot's undo glyph** (28 phone, 36 tablet).
- **Tiles under the look that the design did not list**: the shape builder's tray tile (84, down to 60.6 on the SE for a train, against 96/88), the pattern palette tile on tablets (96 against 112), the two-row 56 tiles of Band A set tiles (see decision 1), and the language tiles (64 and 80 against the look's 88 and 104).
- **The pictures of spot-the-error** (`b15.shpa03.3`, `b.logb11.4`: 22 to 26 across against 40), **the ink of the shapes on the shape-builder** and **thin shapes** (R1 as ink; the audit measured boxes).
- **Small stars of 6 pt on the SE** in `c.numb10.1` to `.3` (eight small stars against five big, on purpose; the rule for a size item that is small on purpose is 24, A12).
- **The number line on the SE**: 140 screens at 21.4 pt a unit against 24 (the design's B1 table is for the phone; the SE line is 472 wide).

**Failures the audit did list that the test now measures** and that are still open: V2 (CAPTION, 531 measurements: 398 are the question's own line on the activity's first screen, 133 are hint and feedback lines; the lines shrink to 14 to 23 pt against floors of 18 to 24), V4 (HAND_BUBBLE: 8, the clock and the balance hints at level 3 and the chart hint `x.mathb19.7`), B1, B3/V6 (COIN, the item for sale), B6 (give), C3 (EMPTY_BAND, 407), V10 and A2 (BIN_ITEM, BIN_SAMPLE, BIN_INK).

**Decisions that are not mine** (the rule and the design disagree, the test follows the checklist and says so):
1. **TILE_H 56 in the tile column** (TILE_H is the biggest family, 1,127 measurements: tap_answer 358, of which 188 are exactly 56; sort_drag 273, the language trays at 64/80; build_pattern 244, the palette; shape_builder 204, the builder tray; match_pairs 32; balance 8; robot 8): the three answer tiles of the chart, set and "how many" activities of Bands A and B stand in a column under the bubble at 56 pt (touch 64). Design 5.1 says an answer tile is the look's tile (96/88); design A4 accepts 56 for charts. The test enforces 5.1. The design-director decides: either the exception for the column is written into 5.1 (and the rule is lowered to the minimum control for that column), or the tiles grow.
2. **Section 2 and checklist 5.2 differ** for a few numbers (a bin item: R5 says 40, 3.4 and 5.2 say 48/44/64; a bin sample: R1 says 40, 5.2 says 40/56; tablet pans and sets: R2 24, 5.2 32). The test applies 5.2 for the named template checks and section 2 elsewhere; BIN_INK holds the section 2 floor on the ink in any case.
3. **Tablet targets** (R1 56, R2 32, R7 28) are not asserted, only the floors (and the 5.2 numbers): the tablet floor column of the design is the same as the phone's.
4. **NUMLINE_TICKS** is only asked for lines of 20 units or fewer (a 0 to 100 line cannot have 24 pt a unit; the design says labels at 0, 50, 100 and the target's ten).

## 7. The test proves its own claims

A map entry removed, one changed and one invented on the phone Band C slice gave exactly:
`NEW   phone|P4|1.0|item|c.mathc01.1|PIC_DETAIL`, `MOVED phone|P4|1.0|item|c.mathc01.21|PIC_DETAIL: the map says 24.0 (16x), now 21.0`, `FIXED phone|P4|1.0|item|c.numc01.1|TILE_H: no longer failing, remove it from knownFailures`.
All four boards then passed with the map restored (24 tests each). A fix removes its lines; a regression adds a `NEW` line and fails.

## 8. What the test cannot measure (audit findings not covered; a person or a drawn shot must look)

- **The hint hand over its target or over the stage** (V4): only the hand's box over the bubble's text is measured (a proxy: the hand's box has a transparent margin).
- **S5, content filling 70 % of the stage's shorter side**, and **V14/V15** (the empty top left of the phone number line, the number line in the lower third of a tablet card): EMPTY_BAND measures the band under the last row, not the holes inside a stage.
- **Things painted, not built from widgets**: the number-line ticks (R10: 4 x 20, 6 x 28), the marker's hop arcs and chips, the clock's hands (V3, a hand through the "12"), the trace start dot (V12, 14 against 28), the balance's beam and pans, the dots under a numeral (B4), the base-ten cubes and rods (B9/HX3, under 12), the robot grid cells, the coin's digit (outlined paths: only the coin's size is measured).
- **Text over a picture, a stretched picture, colour as the only cue, contrast, mirrored maths** (the existing golden tests and a person look at these).
- **The celebration** (V11, B10), **the home island, the hall, the ceremony, the parent area, the course home** (H1 to H7), **the language speakers and the speaker pebbles** (L3), **the ls10 family screen answers** (L1: puppet-talk screens are sampled, the personal-turn rows are not), **L4 to L9** (not rules of this test yet).
- **A real device.** All sizes are in points on the four test boards; a 1.3 text size is the test's textScaler, not a phone's setting.

## 9. The known failures, by template and board (worst case of each rule, ordered by how far under the floor)

How to read: "worst" is the smallest measured value against its floor (for EMPTY_BAND, LABEL_WEIGHT and HAND_BUBBLE the largest against the limit); "failing screens" counts the
screens of every slice (look, text size, item, sorted, hints, Shows, language) that fail that rule on that board; "worst case" names the slice and the screen. Every one of
the 5,959 entries is in `app/test/support/min_sizes_known.dart` with its own id; this table is the grouped view, made by a script from the same numbers.

### sort_drag (1900 failing measurements)

| Rule | Sev | Board | Worst (measured / floor) | Short by | Failing screens | Worst case (slice, screen) | Design id |
|---|---|---|---|---|---|---|---|
| BIN_INK | S1 | phoneSE | 8.8 / 40.0 | 78% | 483 | P1 1.0 sorted shp.solid.stacks.blue | V10 / V9 / B8 / A2 |
| BIN_INK | S1 | phone | 9.6 / 40.0 | 76% | 480 | P1 1.0 sorted shp.solid.stacks.blue | V10 / V9 / B8 / A2 |
| BIN_INK | S1 | tabletL | 12.8 / 40.0 | 68% | 62 | P1 1.0 sorted shp.solid.stacks.blue | V10 / V9 / B8 / A2 |
| BIN_INK | S1 | tabletP | 12.8 / 40.0 | 68% | 62 | P1 1.0 sorted shp.solid.stacks.blue | V10 / V9 / B8 / A2 |
| PIC_ID | S1 | phone | 16.8 / 40.0 | 58% | 28 | P1 1.0 sorted b15.shpa07.2 | R1 (no single audit id) |
| PIC_ID | S1 | phoneSE | 16.8 / 40.0 | 58% | 28 | P1 1.0 sorted b15.shpa07.2 | R1 (no single audit id) |
| PIC_ID | S1 | tabletL | 20.0 / 40.0 | 50% | 26 | P1 1.0 item b15.shpa07.2 | R1 (no single audit id) |
| PIC_ID | S1 | tabletP | 20.0 / 40.0 | 50% | 26 | P1 1.0 item b15.shpa07.2 | R1 (no single audit id) |
| BIN_ITEM | S1 | phoneSE | 28.7 / 44.0 | 35% | 67 | P1 1.0 item log.sortdrag.animals | A2 / V9 (item in a bin) |
| BIN_ITEM | S1 | tabletP | 44.5 / 64.0 | 30% | 67 | P1 1.0 item log.sortdrag.three | A2 / V9 (item in a bin) |
| BIN_ITEM | S1 | phone | 34.0 / 48.0 | 29% | 70 | P1 1.0 item log.sortdrag.three | A2 / V9 (item in a bin) |
| TILE_H | S1 | phone | 64.0 / 88.0 | 27% | 52 | B2-eng 1.0 lang eng.a01.x01 | B11 (tray tile under the look) |
| TILE_H | S1 | phoneSE | 64.0 / 88.0 | 27% | 52 | B2-eng 1.0 lang eng.a01.x01 | B11 (tray tile under the look) |
| BIN_ITEM | S1 | tabletL | 48.8 / 64.0 | 24% | 67 | B0-heb 1.0 lang heb.a07.so-r2 | A2 / V9 (item in a bin) |
| TILE_H | S1 | tabletL | 80.0 / 104.0 | 23% | 36 | B2-eng 1.0 lang eng.a01.x01 | B11 (tray tile under the look) |
| TILE_H | S1 | tabletP | 80.0 / 104.0 | 23% | 133 | B2-eng 1.0 lang eng.a01.x01 | B11 (tray tile under the look) |
| STAGE_CARD | S3 | tabletP | 420.0 / 520.0 | 19% | 20 | P1 1.0 sorted log.pat.no.mixed | C1 / C2 (card not grown) |
| CAPTION | S2 | phoneSE | 18.0 / 22.0 | 18% | 57 | P1 1.0 hint3 math.share.apples | V2 (caption floor); the editor shortens the line |
| CAPTION | S2 | phone | 20.0 / 24.0 | 17% | 28 | P1 1.0 hint3 math.share.apples | V2 (caption floor); the editor shortens the line |
| BIN_SAMPLE | S1 | tabletL | 48.0 / 56.0 | 14% | 28 | P1 1.0 item log.pat.no.mixed | V10 / V9 / B8 / A2 |
| BIN_SAMPLE | S1 | tabletP | 48.0 / 56.0 | 14% | 28 | P1 1.0 item log.pat.no.mixed | V10 / V9 / B8 / A2 |

### tap_answer (1400 failing measurements)

| Rule | Sev | Board | Worst (measured / floor) | Short by | Failing screens | Worst case (slice, screen) | Design id |
|---|---|---|---|---|---|---|---|
| HAND_BUBBLE | S2 | phone | 4289.0 / 150.0 | n/a | 1 | P3 1.0 hint3 x.mathb19.7 | V4 |
| HAND_BUBBLE | S2 | phoneSE | 3441.7 / 150.0 | n/a | 1 | P3 1.0 hint3 x.mathb19.7 | V4 |
| EMPTY_BAND | S3 | phoneSE | 185.0 / 93.8 | 97% over | 11 | B0-eng 1.0 lang eng.a05.pr1 | C3 (phone) |
| PIC_DETAIL | S1 | phoneSE | 6.0 / 24.0 | 75% | 112 | P3 1.0 item c.numb10.3 | A6 / A7 / A8 / V1 (sets and charts) |
| EMPTY_BAND | S3 | phone | 169.0 / 98.2 | 72% over | 11 | B0-eng 1.0 lang eng.a05.pr1 | C3 (phone) |
| PIC_DETAIL | S1 | phone | 9.1 / 24.0 | 62% | 50 | P3 1.0 item c.numb10.3 | A6 / A7 / A8 / V1 (sets and charts) |
| STAGE_CARD | S3 | tabletP | 264.0 / 520.0 | 49% | 32 | P4 1.3 item c.numc02.19 | C1 / C2 (card not grown) |
| PIC_ID | S1 | phoneSE | 22.2 / 40.0 | 45% | 73 | P1 1.0 hint2 shp.where.above | V1 / A8 / V5 (a single picture on a tile or the stage) |
| TILE_H | S1 | phone | 56.0 / 96.0 | 42% | 178 | P1 1.0 item b15.matha01.1 | A4 / 8.3 (56 tiles in the column; rule 5.1 says the look tile: DECISION) |
| NUMERAL | S2 | phoneSE | 11.7 / 20.0 | 42% | 37 | P4 1.0 hint2 c.numc01.5 | R7 (no single audit id) |
| PIC_DETAIL | S1 | tabletP | 19.1 / 32.0 | 40% | 32 | P3 1.0 item c.numb10.3 | A6 / A7 / A8 / V1 (sets and charts) |
| PIC_ID | S1 | phone | 23.9 / 40.0 | 40% | 65 | P1 1.0 item math.size.long | V1 / A8 / V5 (a single picture on a tile or the stage) |
| PIC_DETAIL | S1 | tabletL | 19.3 / 32.0 | 40% | 32 | P1 1.0 item b15.numa12.2 | A6 / A7 / A8 / V1 (sets and charts) |
| TILE_H | S1 | phoneSE | 56.0 / 88.0 | 36% | 172 | P3 1.0 item b.mathb10.4 | A4 / 8.3 (56 tiles in the column; rule 5.1 says the look tile: DECISION) |
| ICON | S2 | tabletL | 26.0 / 40.0 | 35% | 66 | P4 1.0 item c.mathc01.11 | MISSED (keypad glyph) |
| ICON | S2 | tabletP | 26.0 / 40.0 | 35% | 66 | P4 1.0 item c.mathc01.11 | MISSED (keypad glyph) |
| EMPTY_BAND | S3 | tabletP | 388.0 / 295.0 | 32% over | 26 | P4 1.0 item c.mathc03.15 | C1 / C2 / V16 (tablet) |
| STAGE_CARD | S3 | tabletL | 584.0 / 848.0 | 31% | 32 | P4 1.0 item c.mathc03.15 | C1 / C2 (card not grown) |
| NUMERAL | S2 | phone | 13.9 / 20.0 | 30% | 27 | P4 1.0 hint3 c.mathc02.1 | V13 (hint chip) |
| CAPTION | S2 | phone | 17.0 / 24.0 | 29% | 73 | P1 1.0 hint3 more.apples.2v4 | V2 (caption floor); the editor shortens the line |
| PIC_ID | S1 | tabletL | 28.9 / 40.0 | 28% | 18 | P1 1.0 item math.size.long | V1 / A8 / V5 (a single picture on a tile or the stage) |
| PIC_ID | S1 | tabletP | 28.9 / 40.0 | 28% | 18 | P1 1.0 item math.size.long | V1 / A8 / V5 (a single picture on a tile or the stage) |
| CAPTION | S2 | phoneSE | 16.0 / 22.0 | 27% | 83 | P1 1.0 hint3 more.apples.2v4 | V2 (caption floor); the editor shortens the line |
| TILE_H | S1 | tabletL | 80.0 / 104.0 | 23% | 4 | B2-heb 1.0 lang heb.a10.t03 | MISSED (tile under the look) |
| TILE_H | S1 | tabletP | 80.0 / 104.0 | 23% | 4 | B2-heb 1.0 lang heb.a10.t03 | MISSED (tile under the look) |
| ICON | S2 | phone | 26.0 / 32.0 | 19% | 66 | P4 1.0 item c.mathc01.11 | MISSED (keypad glyph) |
| ICON | S2 | phoneSE | 26.0 / 32.0 | 19% | 66 | P4 1.0 item c.mathc01.11 | MISSED (keypad glyph) |
| NUMERAL | S2 | tabletL | 19.6 / 24.0 | 18% | 22 | P1 1.0 hint2 log.story.plant.mid | V13 (hint chip) |
| NUMERAL | S2 | tabletP | 19.6 / 24.0 | 18% | 22 | P1 1.0 hint2 log.story.plant.mid | V13 (hint chip) |

### build_pattern (370 failing measurements)

| Rule | Sev | Board | Worst (measured / floor) | Short by | Failing screens | Worst case (slice, screen) | Design id |
|---|---|---|---|---|---|---|---|
| PIC_ID | S1 | phone | 22.2 / 40.0 | 45% | 19 | P1 1.0 item log.size.apples.last | R1 (no single audit id) |
| PIC_ID | S1 | phoneSE | 22.2 / 40.0 | 45% | 19 | P1 1.0 item log.size.apples.last | R1 (no single audit id) |
| PIC_ID | S1 | tabletL | 22.2 / 40.0 | 45% | 18 | P1 1.0 item log.size.apples.last | R1 (no single audit id) |
| PIC_ID | S1 | tabletP | 22.2 / 40.0 | 45% | 18 | P1 1.0 item log.size.apples.last | R1 (no single audit id) |
| PIC_DETAIL | S1 | phoneSE | 13.7 / 24.0 | 43% | 16 | P3 1.0 item b.logb01.3 | R2 (no single audit id) |
| TILE_H | S1 | phoneSE | 64.0 / 88.0 | 27% | 6 | P3 1.0 item b.colb06.1 | MISSED (palette tile under the look) |
| TILE_H | S1 | phone | 73.0 / 88.0 | 17% | 6 | P3 1.0 item b.colb06.1 | MISSED (palette tile under the look) |
| CAPTION | S2 | phone | 20.0 / 24.0 | 17% | 18 | P1 1.0 hint3 log.next.colours | V2 (caption floor); the editor shortens the line |
| TILE_H | S1 | tabletL | 96.0 / 112.0 | 14% | 116 | P1 1.0 show-host by-size | MISSED (palette tile under the look) |
| TILE_H | S1 | tabletP | 96.0 / 112.0 | 14% | 116 | P1 1.0 show-host by-size | MISSED (palette tile under the look) |
| CAPTION | S2 | phoneSE | 19.0 / 22.0 | 14% | 18 | P1 1.0 hint3 log.next.colours | V2 (caption floor); the editor shortens the line |

### robot_path (360 failing measurements)

| Rule | Sev | Board | Worst (measured / floor) | Short by | Failing screens | Worst case (slice, screen) | Design id |
|---|---|---|---|---|---|---|---|
| LAYOUT_ERROR | S1 | phone | 0.0 / 1.0 | 100% | 2 | P3 1.0 show-host longer-robot-paths | MISSED (overflow stripe) |
| LAYOUT_ERROR | S1 | phoneSE | 0.0 / 1.0 | 100% | 2 | P3 1.0 show-host longer-robot-paths | MISSED (overflow stripe) |
| LABEL_WEIGHT | S2 | phone | 700.0 / 500.0 | 40% over | 2 | P3 1.0 show-host longer-robot-paths | MISSED (w700 nikud label under 24, the robot Show) |
| LABEL_WEIGHT | S2 | phoneSE | 700.0 / 500.0 | 40% over | 2 | P3 1.0 show-host longer-robot-paths | MISSED (w700 nikud label under 24, the robot Show) |
| LABEL_WEIGHT | S2 | tabletL | 700.0 / 500.0 | 40% over | 2 | P3 1.0 show-host longer-robot-paths | MISSED (w700 nikud label under 24, the robot Show) |
| LABEL_WEIGHT | S2 | tabletP | 700.0 / 500.0 | 40% over | 2 | P3 1.0 show-host longer-robot-paths | MISSED (w700 nikud label under 24, the robot Show) |
| ROBOT_STRIP | S2 | phone | 28.0 / 44.0 | 36% | 24 | P3 1.0 show-host longer-robot-paths | B2 (dev round 2 says DONE) |
| ROBOT_STRIP | S2 | phoneSE | 28.0 / 44.0 | 36% | 24 | P3 1.0 show-host longer-robot-paths | B2 (dev round 2 says DONE) |
| ICON_PROGRAM | S2 | tabletL | 28.0 / 40.0 | 30% | 20 | P1 1.0 item cs.robot.plan.1 | B2 (dev round 2 says DONE) |
| ICON_PROGRAM | S2 | tabletP | 28.0 / 40.0 | 30% | 20 | P1 1.0 item cs.robot.plan.1 | B2 (dev round 2 says DONE) |
| ICON_PROGRAM | S2 | phone | 19.6 / 28.0 | 30% | 24 | P3 1.0 show-host longer-robot-paths | B2 (dev round 2 says DONE) |
| ICON_PROGRAM | S2 | phoneSE | 19.6 / 28.0 | 30% | 24 | P3 1.0 show-host longer-robot-paths | B2 (dev round 2 says DONE) |
| NUMERAL | S2 | tabletL | 19.6 / 24.0 | 18% | 2 | P1 1.0 hint2 cs.robot.plan.2 | V13 (hint chip) |
| NUMERAL | S2 | tabletP | 19.6 / 24.0 | 18% | 2 | P1 1.0 hint2 cs.robot.plan.2 | V13 (hint chip) |
| CAPTION | S2 | phoneSE | 18.1 / 22.0 | 18% | 28 | P1 1.3 item cs.robot.plan.1 | V2 (caption floor); the editor shortens the line |
| PIC_ID | S1 | phoneSE | 33.2 / 40.0 | 17% | 14 | P1 1.0 item cs.robot.direct.6 | R1 (no single audit id) |
| CAPTION | S2 | phone | 20.0 / 24.0 | 17% | 28 | P1 1.0 item cs.robot.plan.1 | V2 (caption floor); the editor shortens the line |
| TILE_H | S1 | tabletL | 88.0 / 104.0 | 15% | 4 | P3 1.0 show-host longer-robot-paths | MISSED (tile under the look) |
| TILE_H | S1 | tabletP | 88.0 / 104.0 | 15% | 4 | P3 1.0 show-host longer-robot-paths | MISSED (tile under the look) |
| ROBOT_STRIP | S2 | tabletL | 48.0 / 56.0 | 14% | 20 | P1 1.0 item cs.robot.plan.1 | B2 (dev round 2 says DONE) |
| ROBOT_STRIP | S2 | tabletP | 48.0 / 56.0 | 14% | 20 | P1 1.0 item cs.robot.plan.1 | B2 (dev round 2 says DONE) |
| ICON | S2 | phone | 28.0 / 32.0 | 12% | 20 | P1 1.0 item cs.robot.plan.1 | MISSED (undo glyph) |
| ICON | S2 | phoneSE | 28.0 / 32.0 | 12% | 20 | P1 1.0 item cs.robot.plan.1 | MISSED (undo glyph) |
| ICON | S2 | tabletL | 36.0 / 40.0 | 10% | 20 | P1 1.0 item cs.robot.plan.1 | MISSED (undo glyph) |
| ICON | S2 | tabletP | 36.0 / 40.0 | 10% | 20 | P1 1.0 item cs.robot.plan.1 | MISSED (undo glyph) |
| PIC_ID | S1 | phone | 37.6 / 40.0 | 6% | 10 | P3 1.0 show-host longer-robot-paths | R1 (no single audit id) |

### count_tap (353 failing measurements)

| Rule | Sev | Board | Worst (measured / floor) | Short by | Failing screens | Worst case (slice, screen) | Design id |
|---|---|---|---|---|---|---|---|
| EMPTY_BAND | S3 | phoneSE | 185.0 / 93.8 | 97% over | 29 | B0-eng 1.0 lang eng.a04.i06 | C3 (phone) |
| COUNT_TOUCH | S1 | phoneSE | 11.8 / 56.0 | 79% | 86 | P3 1.0 show-host many-things | A9 (dev round 1 says DONE) |
| COUNT_OBJ | S1 | phoneSE | 8.6 / 40.0 | 78% | 74 | P3 1.0 show-host many-things | A9 (dev round 1 says DONE) |
| EMPTY_BAND | S3 | phone | 169.0 / 98.2 | 72% over | 29 | B0-eng 1.0 lang eng.a04.i06 | C3 (phone) |
| COUNT_TOUCH | S1 | phone | 16.5 / 56.0 | 71% | 52 | P3 1.0 show-host many-things | A9 (dev round 1 says DONE) |
| COUNT_OBJ | S1 | phone | 12.0 / 40.0 | 70% | 41 | P3 1.0 show-host many-things | A9 (dev round 1 says DONE) |
| CAPTION | S2 | phoneSE | 15.0 / 22.0 | 32% | 11 | P1 1.0 hint3 count.apples.7 | V2 (caption floor); the editor shortens the line |
| CAPTION | S2 | phone | 17.0 / 24.0 | 29% | 11 | P1 1.0 hint3 count.apples.7 | V2 (caption floor); the editor shortens the line |
| NUMERAL | S2 | tabletL | 19.6 / 24.0 | 18% | 3 | P1 1.0 hint3 count.apples.7 | V13 (hint chip) |
| NUMERAL | S2 | tabletP | 19.6 / 24.0 | 18% | 3 | P1 1.0 hint3 count.apples.7 | V13 (hint chip) |
| COUNT_TOUCH | S1 | tabletP | 48.0 / 56.0 | 14% | 6 | P3 1.0 show-host many-things | A9 (dev round 1 says DONE) |
| COUNT_OBJ | S1 | tabletP | 35.0 / 40.0 | 12% | 4 | P3 1.0 show-host many-things | A9 (dev round 1 says DONE) |
| COUNT_TOUCH | S1 | tabletL | 53.8 / 56.0 | 4% | 4 | P3 1.0 show-host many-things | A9 (dev round 1 says DONE) |

### shape_builder (292 failing measurements)

| Rule | Sev | Board | Worst (measured / floor) | Short by | Failing screens | Worst case (slice, screen) | Design id |
|---|---|---|---|---|---|---|---|
| PIC_ID | S1 | phoneSE | 15.0 / 40.0 | 62% | 36 | P1 1.0 item b15.shpa06.1 | A12 / R1 (shapes in the builder) |
| PIC_ID | S1 | phone | 18.9 / 40.0 | 53% | 34 | P1 1.0 item b15.shpa06.1 | A12 / R1 (shapes in the builder) |
| TILE_H | S1 | phoneSE | 60.6 / 96.0 | 37% | 51 | P1 1.0 item shp.build.train | MISSED (builder tray tile 84 under the look) |
| TILE_H | S1 | phone | 68.3 / 96.0 | 29% | 51 | P1 1.0 item shp.build.train | MISSED (builder tray tile 84 under the look) |
| PIC_DETAIL | S1 | phoneSE | 17.1 / 24.0 | 29% | 10 | P1 1.0 item shp.build.tree | R2 (no single audit id) |
| TILE_H | S1 | tabletL | 84.0 / 112.0 | 25% | 51 | P1 1.0 show-host build-with-shapes | MISSED (builder tray tile 84 under the look) |
| TILE_H | S1 | tabletP | 84.0 / 112.0 | 25% | 51 | P1 1.0 show-host build-with-shapes | MISSED (builder tray tile 84 under the look) |
| EMPTY_BAND | S3 | phoneSE | 108.4 / 93.8 | 16% over | 4 | P1 1.0 item shp.build.train | C3 (phone) |
| PIC_DETAIL | S1 | phone | 21.5 / 24.0 | 10% | 2 | P1 1.0 item shp.build.tree | R2 (no single audit id) |
| CAPTION | S2 | phoneSE | 21.0 / 22.0 | 5% | 2 | P1 1.0 hint2 shp.build.house | V2 (caption floor); the editor shortens the line |

### spot_error (280 failing measurements)

| Rule | Sev | Board | Worst (measured / floor) | Short by | Failing screens | Worst case (slice, screen) | Design id |
|---|---|---|---|---|---|---|---|
| EMPTY_BAND | S3 | phoneSE | 185.0 / 93.8 | 97% over | 104 | P1 1.0 item b15.cola02.5 | C3 (phone) |
| EMPTY_BAND | S3 | phone | 169.0 / 98.2 | 72% over | 112 | P1 1.0 item b15.cola02.5 | C3 (phone) |
| NUMERAL | S2 | phoneSE | 10.5 / 20.0 | 48% | 4 | P1 1.0 hint2 b15.numa01.4 | R7 (no single audit id) |
| PIC_ID | S1 | phoneSE | 21.8 / 40.0 | 45% | 41 | P1 1.0 item b15.shpa03.3 | MISSED (spot-the-error pictures) |
| PIC_ID | S1 | phone | 25.6 / 40.0 | 36% | 13 | P3 1.0 item b.logb11.4 | MISSED (spot-the-error pictures) |
| NUMERAL | S2 | phone | 14.6 / 20.0 | 27% | 2 | P1 1.0 hint2 b15.numa01.4 | R7 (no single audit id) |
| NUMERAL | S2 | tabletL | 21.0 / 24.0 | 12% | 2 | P1 1.0 hint2 b15.numa01.4 | R7 (no single audit id) |
| NUMERAL | S2 | tabletP | 21.0 / 24.0 | 12% | 2 | P1 1.0 hint2 b15.numa01.4 | R7 (no single audit id) |

### shop_pay (249 failing measurements)

| Rule | Sev | Board | Worst (measured / floor) | Short by | Failing screens | Worst case (slice, screen) | Design id |
|---|---|---|---|---|---|---|---|
| PIC_ID | S1 | phoneSE | 21.1 / 40.0 | 47% | 52 | P3 1.0 show-host pay-exactly | V6 (item for sale) |
| COIN | S2 | phoneSE | 30.7 / 48.0 | 36% | 20 | P4 1.0 item c.numc03.14 | B3 / V6 |
| PIC_ID | S1 | phone | 25.8 / 40.0 | 36% | 52 | P3 1.0 show-host pay-exactly | V6 (item for sale) |
| COIN | S2 | phone | 32.9 / 48.0 | 31% | 18 | P4 1.0 item c.numc03.14 | B3 / V6 |
| COIN | S2 | tabletL | 53.1 / 64.0 | 17% | 26 | P4 1.0 show-host blocks-tens-and-ones | B3 / V6 |
| CAPTION | S2 | phoneSE | 17.0 / 20.0 | 15% | 44 | P3 1.0 item x.mathb17.1 | V2 (caption floor); the editor shortens the line |
| CAPTION | S2 | phone | 19.0 / 22.0 | 14% | 23 | P3 1.0 hint3 x.mathb17.6 | V2 (caption floor); the editor shortens the line |
| NUMERAL | S2 | tabletL | 22.0 / 24.0 | 8% | 5 | P3 1.0 show-host pay-exactly | R7 (no single audit id) |
| NUMERAL | S2 | tabletP | 22.0 / 24.0 | 8% | 5 | P3 1.0 show-host pay-exactly | R7 (no single audit id) |
| COIN | S2 | tabletP | 59.6 / 64.0 | 7% | 4 | P4 1.0 item c.numc03.14 | B3 / V6 |

### number_line (244 failing measurements)

| Rule | Sev | Board | Worst (measured / floor) | Short by | Failing screens | Worst case (slice, screen) | Design id |
|---|---|---|---|---|---|---|---|
| LAYOUT_ERROR | S1 | tabletL | 0.0 / 1.0 | 100% | 6 | P4 1.3 item c.numc06.12 | MISSED (overflow stripe) |
| LAYOUT_ERROR | S1 | tabletP | 0.0 / 1.0 | 100% | 6 | P4 1.3 item c.numc06.12 | MISSED (overflow stripe) |
| NUMERAL | S2 | phone | 12.3 / 20.0 | 38% | 26 | P1 1.0 show-host counting-words | V13 (hint chip) |
| NUMERAL | S2 | phoneSE | 13.6 / 20.0 | 32% | 26 | P1 1.0 show-host counting-words | V13 (hint chip) |
| NUMERAL | S2 | tabletL | 19.6 / 24.0 | 18% | 20 | P1 1.0 show-host counting-words | V13 (hint chip) |
| NUMERAL | S2 | tabletP | 19.6 / 24.0 | 18% | 20 | P1 1.0 show-host counting-words | V13 (hint chip) |
| NUMLINE_TICKS | S2 | phoneSE | 21.4 / 24.0 | 11% | 140 | P3 1.0 item b.mathb08.1 | B1 |

### balance (116 failing measurements)

| Rule | Sev | Board | Worst (measured / floor) | Short by | Failing screens | Worst case (slice, screen) | Design id |
|---|---|---|---|---|---|---|---|
| HAND_BUBBLE | S2 | phone | 4319.3 / 150.0 | n/a | 2 | P3 1.0 hint3 b.mathb13.7 | V4 |
| HAND_BUBBLE | S2 | phoneSE | 3884.4 / 150.0 | n/a | 2 | P3 1.0 hint3 b.mathb13.7 | V4 |
| PIC_ID | S1 | phoneSE | 21.0 / 40.0 | 48% | 20 | P3 1.0 item b.mathb13.11 | R1 (no single audit id) |
| PIC_ID | S1 | phone | 30.1 / 40.0 | 25% | 20 | P3 1.0 item b.mathb13.11 | R1 (no single audit id) |
| CAPTION | S2 | phone | 18.0 / 22.0 | 18% | 32 | P3 1.0 hint3 b.mathb09.5 | V2 (caption floor); the editor shortens the line |
| CAPTION | S2 | phoneSE | 17.0 / 20.0 | 15% | 30 | P3 1.0 hint3 b.mathb09.5 | V2 (caption floor); the editor shortens the line |
| TILE_H | S1 | phone | 88.0 / 96.0 | 8% | 4 | P1 1.0 item math.size.heavy | MISSED (tile under the look) |
| TILE_H | S1 | phoneSE | 88.0 / 96.0 | 8% | 4 | P1 1.0 item math.size.heavy | MISSED (tile under the look) |
| PIC_DETAIL | S1 | phoneSE | 22.2 / 24.0 | 8% | 2 | P3 1.0 item b.mathb13.5 | A5 |

### give_n (96 failing measurements)

| Rule | Sev | Board | Worst (measured / floor) | Short by | Failing screens | Worst case (slice, screen) | Design id |
|---|---|---|---|---|---|---|---|
| PIC_DETAIL | S1 | phoneSE | 16.0 / 24.0 | 33% | 50 | P3 1.0 item b.mathb06.1 | B6 |
| NUMERAL | S2 | phoneSE | 15.9 / 20.0 | 20% | 2 | P1 1.0 hint3 give.butterflies.4 | V13 (hint chip) |
| NUMERAL | S2 | tabletL | 19.6 / 24.0 | 18% | 2 | P1 1.0 hint3 give.butterflies.4 | V13 (hint chip) |
| NUMERAL | S2 | tabletP | 19.6 / 24.0 | 18% | 2 | P1 1.0 hint3 give.butterflies.4 | V13 (hint chip) |
| PIC_DETAIL | S1 | phone | 19.8 / 24.0 | 17% | 18 | P3 1.0 item b.mathb06.1 | B6 |
| CAPTION | S2 | phone | 20.0 / 24.0 | 17% | 10 | P1 1.0 hint1 give.butterflies.4 | V2 (caption floor); the editor shortens the line |
| NUMERAL | S2 | phone | 17.2 / 20.0 | 14% | 2 | P1 1.0 hint3 give.butterflies.4 | V13 (hint chip) |
| CAPTION | S2 | phoneSE | 19.0 / 22.0 | 14% | 10 | P1 1.0 hint1 give.butterflies.4 | V2 (caption floor); the editor shortens the line |

### sing_along (93 failing measurements)

| Rule | Sev | Board | Worst (measured / floor) | Short by | Failing screens | Worst case (slice, screen) | Design id |
|---|---|---|---|---|---|---|---|
| PIC_ID | S1 | phoneSE | 12.8 / 40.0 | 68% | 63 | B0-heb 1.0 lang heb.a06.c-v357 | B8 / L2 (language pictures) |
| PIC_ID | S1 | phone | 21.2 / 40.0 | 47% | 30 | B0-heb 1.0 lang heb.a07.u-r2 | B8 / L2 (language pictures) |

### match_pairs (85 failing measurements)

| Rule | Sev | Board | Worst (measured / floor) | Short by | Failing screens | Worst case (slice, screen) | Design id |
|---|---|---|---|---|---|---|---|
| NUMERAL | S2 | tabletL | 13.0 / 24.0 | 46% | 3 | P1 1.0 hint3 x.numa07.1 | B4 / V13 (numeral on a set tile) |
| NUMERAL | S2 | tabletP | 13.0 / 24.0 | 46% | 3 | P1 1.0 hint3 x.numa07.1 | B4 / V13 (numeral on a set tile) |
| NUMERAL | S2 | phone | 13.0 / 20.0 | 35% | 3 | P1 1.0 hint3 x.numa07.1 | B4 / V13 (numeral on a set tile) |
| NUMERAL | S2 | phoneSE | 13.0 / 20.0 | 35% | 3 | P1 1.0 hint3 x.numa07.1 | B4 / V13 (numeral on a set tile) |
| TILE_H | S1 | phone | 64.0 / 88.0 | 27% | 8 | B2-eng 1.0 lang eng.a05.m01 | MISSED (tile under the look) |
| TILE_H | S1 | phoneSE | 64.0 / 88.0 | 27% | 8 | B2-eng 1.0 lang eng.a05.m01 | MISSED (tile under the look) |
| TILE_H | S1 | tabletL | 80.0 / 104.0 | 23% | 8 | B2-eng 1.0 lang eng.a05.m01 | MISSED (tile under the look) |
| TILE_H | S1 | tabletP | 80.0 / 104.0 | 23% | 8 | B2-eng 1.0 lang eng.a05.m01 | MISSED (tile under the look) |
| CAPTION | S2 | phoneSE | 17.0 / 22.0 | 23% | 3 | P1 1.0 hint3 x.numa07.1 | V2 (caption floor); the editor shortens the line |
| PIC_DETAIL | S1 | phone | 18.7 / 24.0 | 22% | 8 | P1 1.0 item x.numa07.5 | R2 (no single audit id) |
| PIC_DETAIL | S1 | phoneSE | 18.7 / 24.0 | 22% | 8 | P1 1.0 item x.numa07.5 | R2 (no single audit id) |
| PIC_ID | S1 | phoneSE | 31.6 / 40.0 | 21% | 6 | P3 1.0 item x.mathb16.4 | R1 (no single audit id) |
| CAPTION | S2 | phone | 20.0 / 24.0 | 17% | 14 | P1 1.0 hint3 x.numa07.1 | V2 (caption floor); the editor shortens the line |
| PIC_ID | S1 | phone | 35.2 / 40.0 | 12% | 2 | B2-heb 1.0 lang heb.a07.10 | B8 / L2 (language pictures) |

### flash (81 failing measurements)

| Rule | Sev | Board | Worst (measured / floor) | Short by | Failing screens | Worst case (slice, screen) | Design id |
|---|---|---|---|---|---|---|---|
| EMPTY_BAND | S3 | phoneSE | 185.0 / 93.8 | 97% over | 39 | P1 1.0 item b15.numa05.1 | C3 (phone) |
| EMPTY_BAND | S3 | phone | 169.0 / 98.2 | 72% over | 36 | P1 1.0 item b15.numa05.1 | C3 (phone) |
| NUMERAL | S2 | phoneSE | 11.9 / 20.0 | 40% | 1 | P1 1.0 hint3 flash.dice.3 | V13 (hint chip) |
| NUMERAL | S2 | phone | 14.0 / 20.0 | 30% | 1 | P1 1.0 hint3 flash.dice.3 | V13 (hint chip) |
| NUMERAL | S2 | tabletL | 19.6 / 24.0 | 18% | 1 | P1 1.0 hint3 flash.dice.3 | V13 (hint chip) |
| NUMERAL | S2 | tabletP | 19.6 / 24.0 | 18% | 1 | P1 1.0 hint3 flash.dice.3 | V13 (hint chip) |
| CAPTION | S2 | phoneSE | 18.0 / 22.0 | 18% | 1 | P1 1.0 hint3 flash.dice.3 | V2 (caption floor); the editor shortens the line |
| CAPTION | S2 | phone | 21.0 / 24.0 | 12% | 1 | P1 1.0 hint3 flash.dice.3 | V2 (caption floor); the editor shortens the line |

### puppet_talk (24 failing measurements)

| Rule | Sev | Board | Worst (measured / floor) | Short by | Failing screens | Worst case (slice, screen) | Design id |
|---|---|---|---|---|---|---|---|
| PIC_ID | S1 | phone | 30.8 / 40.0 | 23% | 6 | B0-eng 1.0 lang eng.a08.p01 | B8 / L2 (language pictures) |
| PIC_ID | S1 | phoneSE | 30.8 / 40.0 | 23% | 6 | B0-eng 1.0 lang eng.a08.p01 | B8 / L2 (language pictures) |
| PIC_ID | S1 | tabletL | 30.8 / 40.0 | 23% | 6 | B0-eng 1.0 lang eng.a08.p01 | B8 / L2 (language pictures) |
| PIC_ID | S1 | tabletP | 30.8 / 40.0 | 23% | 6 | B0-eng 1.0 lang eng.a08.p01 | B8 / L2 (language pictures) |

### listen_do (6 failing measurements)

| Rule | Sev | Board | Worst (measured / floor) | Short by | Failing screens | Worst case (slice, screen) | Design id |
|---|---|---|---|---|---|---|---|
| CAPTION | S2 | phoneSE | 18.7 / 20.0 | 7% | 3 | B2-heb 1.3 lang heb.a10.u-l2 | V2 (caption floor); the editor shortens the line |
| CAPTION | S2 | phone | 20.7 / 22.0 | 6% | 3 | B2-heb 1.3 lang heb.a10.u-l2 | V2 (caption floor); the editor shortens the line |

### story (6 failing measurements)

| Rule | Sev | Board | Worst (measured / floor) | Short by | Failing screens | Worst case (slice, screen) | Design id |
|---|---|---|---|---|---|---|---|
| EMPTY_BAND | S3 | phoneSE | 96.4 / 93.8 | 3% over | 6 | B0-heb 1.0 lang heb.a12.04 | C3 (phone) |

### clock_set (4 failing measurements)

| Rule | Sev | Board | Worst (measured / floor) | Short by | Failing screens | Worst case (slice, screen) | Design id |
|---|---|---|---|---|---|---|---|
| HAND_BUBBLE | S2 | phoneSE | 4840.6 / 150.0 | n/a | 1 | P3 1.0 hint3 x.mathb15.1 | V4 |
| HAND_BUBBLE | S2 | phone | 4606.5 / 150.0 | n/a | 1 | P3 1.0 hint3 x.mathb15.1 | V4 |
| NUMERAL | S2 | tabletL | 19.6 / 24.0 | 18% | 1 | P3 1.0 hint3 x.mathb15.1 | V13 (hint chip) |
| NUMERAL | S2 | tabletP | 19.6 / 24.0 | 18% | 1 | P3 1.0 hint3 x.mathb15.1 | V13 (hint chip) |


## 10. Defects (hand-offs; none is fixed by me)

The map is the defect list of the sizes; these are the items that need a person's decision or that the design audit had not seen. Owners by the routing rules.

| Id | Sev | What | Owner |
|---|---|---|---|
| QA-M1 | major | Overflow stripe in the robot Show `longer-robot-paths` on the phone and the SE (162 px right) | app-developer |
| QA-M2 | major | Overflow (28 px at the bottom) in the Band C number-line items `c.numc06.3/.4/.5/.6/.12/.17` at text size 1.3 on both tablets | app-developer |
| QA-M3 | minor | Bold (w700) nikud label under 24 in the robot Show | design-director |
| QA-M4 | major | A9 count-tap touch squares 21 to 54 pt for 4 to 10 objects on phones (Band A look), 16 for the 13-thing Show; claimed done | app-developer (and curriculum-expert for the largest counts) |
| QA-M5 | major | B2 robot strip drawn 28 high with arrows 19.6 on phones; claimed done | app-developer |
| QA-M6 | major | The ink of pictures in bins and on bin samples far under 40 (BIN_INK 1,087), line shapes and thin shapes worst | design-director (art), app-developer |
| QA-M7 | major | Band C screens keep the old tablet card (584 x 300 landscape, 264 high portrait) | app-developer |
| QA-M8 | major | Decision 1 above: 56 pt answer tiles in the tile column against the look's tile | design-director |
| QA-M9 | minor | Keypad and undo glyphs under 32/40; shape-builder tray tile 84 down to 60.6; palette tile 96 on tablets; language tiles 64/80 | design-director, app-developer |
| QA-M10 | major | Bubble captions that shrink under the look's floor, down to 14 pt (V2, CAPTION 531; 398 of them are the question's own line, e.g. `c.mathb04.11` 16.8 on a phone) | hebrew-text-editor (shorten the lines) |

## 11. How to run it and how to change the map

- One board: `flutter test test/min_sizes_phone_test.dart` (3 m 20 s). The quick part: `flutter test test/min_sizes_test.dart`. Never two at once.
- To see the table of a slice without asserting, set `MIN_SIZES_OUT=<folder>` (a folder that exists): each slice appends `<board>.txt` (map lines) and `<board>_detail.txt` (the worst piece of each failing screen, tab separated). Set `MIN_SIZES_DEBUG=1` to print the number of pieces read on every screen.
- **When a fix lands**: run the board files with `MIN_SIZES_OUT`, take the `<board>.txt` lines as the new map for that board (the keys are sorted), run the files once more without it, and the run must be green. A fix that makes a measurement pass but leaves its line in the map fails with `FIXED`.
- Commands run for this note: `dart format` and `flutter analyze` on the new files (0 issues); `flutter test test/min_sizes_test.dart` (6 passed); the four board files with the map (24 passed each, 96 in all, no failure, no skip); the map-mutation run of section 7. No full `flutter test` was run (not asked); no `flutter_tester` is left running.
