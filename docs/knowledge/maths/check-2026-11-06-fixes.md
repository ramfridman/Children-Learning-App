# Machine check of today's pack, 2026-11-06 (M10 step 0.5), with its fixes

By the Maths Teacher and the CS Teacher. This is the copy of `docs/knowledge/maths/check-2026-11-06.md` (branch `m10-checkers`) on branch `hebrew-review`, where the fixes were made. Sections 1 to 7 and the owner's W3 decision are the findings as they were written; **section 8, at the end, lists every change made for them** (id, before, after, why) and the checker counts before and after.

## How it was checked

```
python -I tools/check_maths.py --list      # 919 maths items: numbers, math, shapes, logic, colors
python -I tools/check_robot.py --list      # 48 Robots items, 22 of them grid tasks run on the simulator
python -I tools/test_check_maths.py        # 20 tests, OK
python -I tools/test_check_robot.py        # 12 tests, OK
```

- **`check_maths`** recomputes every answer from the item's own data: the numbers in the caption, the counts drawn, the `n:`/`op:` cells, the sprites (shape, colour, size, tower, shade, day, clock, coin) and the SVG outline of a shape (sides and side lengths). It then checks that no distractor is also right, that each distractor carries the tag §5.3 asks for and that a numeric tag gives its distractor (M-CNT-DOUBLE is n+1 or n+2; `smallbig(52, 27) = 35`), that the numbers stay in the skill's range (curriculum §4) and the options in the band's limit (PLAN.md: 3, 4, 5), that every spoken option label names what its picture shows, and that the maths stays left to right (number lines grow to the right, number sentences are true read left to right, and the app's renderers keep their LTR isolate).
- **`check_robot`** runs every program the way `robot_path_session.dart` does: absolute arrows, a step off the grid is not taken, right means the robot ends on the flag. It finds the shortest way by breadth-first search and checks the solution, `maxSteps`, the band's step limit and any distractor program. It is ready for robot v2 (M10 X10): obstacles, walls, a 6 × 6 grid, `facing` with forward and turns, `repeat` blocks, `predict` and `debug`. The field names are a proposal; the app-developer confirms them when X10 is built.
- **Proof that the rules bite.** Every choice item was run again with its marked answer moved to each distractor in turn. All 1,240 moves were caught except the 4 items that already have a second right answer (b.logb06.1 to .4). The 218 moves on the other templates (a target ±1, a swapped pair, another bin, another hour, another cell) were all caught, except the 4 `b.mathb09` spot items, where any cell can be the wrong one (see A3). All 88 moves on the Robots items were caught. The real-pack tests run this check again every time.

## Counts

| | Items | Read by a rule | WRONG | RULE | AMBIG | NOTE | UNCHECKED |
|---|---|---|---|---|---|---|---|
| Maths (check_maths) | 919 | 919 | 10 items | 431 items (457 findings) | 19 items | 96 items | 0 |
| Robots (check_robot) | 48 | 48 (22 simulated) | 0 | 16 items | 0 | 6 items | 0 |

Both checkers exit 1 today, because of the RULE findings. 405 of the 447 RULE items are untagged distractors, which B-36 is already repairing on `next-pack`.

---

## 1. Wrong content (fix before Band C reuses these skills)

| # | Item(s) | What is wrong | Why it matters | Fix (for the owner of the item) |
|---|---|---|---|---|
| W1 | **x.shpb09.4** (SHP-B-09) | The item pairs a **sphere** (כַּדּוּר) with the **circle** as "the flat shape on it". A sphere has no flat face: a stamp in the sand leaves a point, not a circle. | It teaches a false property of the sphere, in the skill about faces. | Replace the sphere with a cylinder or a cone, or drop the circle. |
| W2 | **b.logb06.1, .2, .3, .4** (LOG-B-06) | "מַה מְשֻׁתָּף לְכֻלָּם?" (*what do they all share?*): the three shapes are all drawn the **same size**, so "the size" (rule_size) is also right. In .1 and .2 the answer is the colour, and in .3 and .4 the shape. Items .5 and .6 are fine: there, the objects really differ in kind. | Two right answers, and only one is accepted. A child who notices the equal sizes is marked wrong. | Draw the three in different sizes (`*_size_s/m/l`), or drop the size option. |
| W3 | **b15.shpa04.1, b15.shpa04.2, shp.rect.find, shp.rect.blue, shp.rect.green** (SHP-A-04, Band A) | "אֵיפֹה הַמַּלְבֵּן?" (*where is the rectangle?*) marks the **square** wrong and tags it **M-SHP-SQRECT**. But a square *is* a rectangle. The catalogue defines M-SHP-SQRECT as "thinks a square is not a rectangle", and the pack's own b.shpb03.7 accepts a square as a rectangle. | The item rewards the misconception it is meant to repair, and it disagrees with SHP-B-03. | Use a distractor that is not a rectangle (a triangle or a circle), or use the B-03 wording "מַלְבֵּן שֶׁלֹּא כׇּל הַצְּלָעוֹת שָׁווֹת". If Band A keeps the informal "long box" sense, the curriculum-expert writes that down in §4 and the tag comes off. |

## 2. Ambiguous items (a child could fairly read them another way)

| # | Item(s) | The other reading | Fix |
|---|---|---|---|
| A1 | **b.logb02.3, b.logb02.6** (LOG-B-02, find the unit) | Each row can be read with one mistake in two ways. In .3 the row is apple fish star apple fish apple apple fish: the core can be apple-fish-star (the item's answer, cell 5) or apple-fish-apple (then the lone star, cell 2, is the mistake). .6 is the same with cat and dog. The lone star is the more natural pick, and the item marks it wrong. | Show the unit at least twice before the break, and make the wrong cell one that is not unique in the row. |
| A2 | **b.shpb03.1, .3, .5** (SHP-B-03) | "לְאֵיזוֹ צוּרָה כׇּל הַצְּלָעוֹת שָׁווֹת?" (*which shape has all sides equal?*): the triangle sprite `shape_triangle` has sides of 82, 82 and 80 units. They look equal, so the triangle looks right too. | Use `shape_triangle_thin` (clearly unequal sides) or a rectangle as the distractor. |
| A3 | **b.mathb09.9, .10, .11, .12** (MATH-B-09) | "…וְאֶחָד מֵהֶם לֹא מַתְאִים. אֵיפֹה הַטָּעוּת?" (*one of them does not fit; where is the mistake?*): in 7 = 5 + 3, changing the 7, the 5 or the 3 makes it true. The caption does not say which number is wrong, and the app accepts only one cell. The b.mathb03 spot items avoid this: they say "הַתְּשׁוּבָה לֹא נְכוֹנָה" (*the answer is wrong*). | Name the result in the caption, or accept every cell that can be fixed. |
| A4 | **b15.numa13.1, b15.numa13.2, ordinal.first, ordinal.first.of4, ordinal.last, ordinal.second.of4, ordinal.third, ordinal.third.of4** (NUM-A-13) | "מִי שֵׁנִי בַּתּוֹר?" (*who is second in the queue?*): the queue is just the row of tiles. It is drawn left to right, and nothing shows where the line begins (no shop, no door, no direction the animals face). A Hebrew-reading child counts from the right and taps the mirror tile. | Draw the head of the line (a door or a counter at the start), with the animals facing it, and keep the tiles in that order. The design-director draws it. |
| A5 | **log.same.balloon** (LOG-A-01) | "אֵיפֹה אוֹתוֹ הַדָּבָר?" (*where is the same thing?*): here the blue balloon is marked wrong. In b15.loga01.3, "the same thing" is a green apple for a red apple, which is the same kind in another colour. By that rule, the blue balloon is right here too. | Decide one meaning for the skill (the same kind, or identical) and use the same distractor logic in all its items. |
| A6 | **b.numb05.8** (NUM-B-05) | "תְּנוּ לִי עֶשְׂרִים דָּגִים" (*give me 20 fish*) from a pile of exactly 20. Taking the whole pile is right, so the item cannot show M-CNT-CARD, and a child who grabs everything is marked as knowing. | Make the pile bigger than 20 (the band's range allows the pile to be bigger than the target), or ask for fewer. |

## 3. Robots (check_robot)

| # | Item(s) | Finding | Severity | Fix |
|---|---|---|---|---|
| R1 | **b.csb01.6** (CS-B-01, direct) | The stored solution is up, right, up, right, up, **left**: 6 steps where 4 reach the flag. The hints' worked example walks this solution, so it shows the child a detour (right, then back left). | rule (misleading) | Solution: right, up, up, up (or any 4-step way). |
| R2 | **cs.robot.plan.3, .4, .6** (CS-A-04, Band A plans) | Plans of 4 steps. CS-A-04 is "plans a 2–3 step path", and Band A plans 3 steps (PLAN.md › gestures). | rule (unfit) | Move the flag one square nearer, or move these items to CS-B-01. |
| R3 | 12 items of CS-A-01 and CS-A-05 (`cs.routine.*`, `cs.wrong.*`) | Distractors without a tag (3 options need two tagged distractors). | rule | B-36. |
| — | All 22 grid tasks | Every solution stays on the grid, reaches the flag and fits `maxSteps`. Every task can be solved within its limit. Every flag can be reached. | pass | |
| — | b15.csa03.1, .2, cs.robot.direct.3 to .6 | Band A direct control with 4 or 5 moves. This is allowed (one arrow at a time, not a program), so it is a note only. | note | |
| — | Distractor programs | Today's pack has none (robot_path v1 has no options). The rule is ready and tested for X10 `predict` and `debug` (each distractor must end elsewhere, bump, or stop short). | — | |

The CS-B-04 repeat-and-debug items (b.csb04.1 to .6) each have exactly one wrong card, and it is the marked one. The step-counting rows (b15.csa04.1, .2, b.csb01.9, .10) count correctly, and their M-CS-OFF1 distractor is the count that includes the start square. The routine items (CS-A-01, CS-A-05) are in the right order.

## 4. Rule findings (tags, range, band limits)

**Tags that do not give their distractor (15).** These mislead the engine's diagnosis: they would send a child to the wrong repair.

- **b.mathb03.1, .2, .3, .4, .15, b.mathb08.1 to .8** (13 items): the answer **minus one** is tagged **M-CNT-DOUBLE**. Double counting gives n+1 or n+2, so these should be M-CNT-SKIP. For example, 3 + 4 = 7 with the distractor 6 tagged M-CNT-DOUBLE.
- **b.mathb07.6**: 0 + 0 with the distractor 2 tagged M-NUM-ZERO. No zero rule gives 2.
- **b.numb08.10**: "where is 11?" with the distractor 1 tagged M-NUM-TEEN. The teen error gives 110 or "10 then 1", not 1.

**Numbers outside the skill's range (12 findings, 10 items).**
- **b.numb10.3, .4, .7, .8, .9, .10**: NUM-B-10 compares numbers ≤ 10 (curriculum §4), and these use 11 to 31. b.numb10.9 compares 31 and 13.
- **x.numa07.5, .6**: NUM-A-07 numerals go to 5; these use 6.
- **b.numb16.10, .11** (distractors 41 and 71) and **b.mathb08.14** (distractor 24) go above Band B's 20. They are reversal or sum distractors, so whether to allow them is a policy question for the curriculum-expert.

**Too many options for Band A (10).** b15.numa13.1, .2, ordinal.first.of4, ordinal.second.of4, ordinal.third.of4, ordinal.last, col.find.blue.ball, col.find.green.balloon, col.find.red.balloon and col.find.yellow.flower show 4 options. Band A shows at most 3.

**Two distractors with the same tag in a skill that watches no tag or several (27).** b.mathb14.1 to .11 (M-CNT-SEQ twice; MATH-B-14 watches no tag), b15.cola02.3, .4, b15.numa08.2, b15.shpa01.1, log.same.apple, .balloon, .bird, .cat, .duck, .star, and shp.any.big.circle, .down, .small, .small.square, .thin, .tilt. Two of these are also wrong diagnoses. In b15.shpa01.1, M-SHP-ORIENT sits on a square and a circle offered for a triangle. In shp.any.big.circle, M-SHP-SIZE sits on a triangle and a square offered for a circle. Neither choice reveals that error.

**Distractors without a tag (405 items in 62 skills: 393 maths and 12 Robots; 131 of the items have no tag at all).** This is the known B-36 gap. The full list by skill comes from `python -I tools/check_maths.py --list | findstr tag-missing`. The biggest skills are MATH-B-01, MATH-B-08 and NUM-B-11 (12 each), NUM-B-08 (11), and MATH-B-02, MATH-B-03, MATH-B-15, NUM-B-10 and NUM-B-18 (10 each). Every item of LOG-A-02, LOG-A-04, LOG-A-06, LOG-A-07, LOG-A-09, SHP-A-07, SHP-A-10, SHP-B-01, SHP-B-08 and NUM-A-13 is short of tags.

**Notes.** M-PART-MISS (56 uses), M-NUM-WRITE (20), M-LOG-NOT (16) and M-SHP-FACE (7) have records but are not in the §5.2 catalogue: the M-PPW and M-NOT renames of B-36 cover the first and the third. Five number lines (b.mathb01.17, b.numb13.3, .13, .17, .20) have no `mirrorMisconception` (M-NL-DIR).

## 5. Misconceptions covered and missing

The pack uses 43 tags. Three tags that a skill watches have no item at all:
- **MATH-B-10: M-SHARE-UNEQ**. Repair: a sharing item with an unequal split as the distractor.
- **NUM-B-10: M-CNT-SIZE**. These items show no objects, so the tag cannot show. The skill's "watch" list should drop it, or the skill needs a picture item.
- **MATH-B-01 and B-08: M-ADD-RECOUNT**. This is a strategy seen in the tap log, not a distractor, so it is fine.

The rule that every tag needs a "lucky" item (§5.3), where the misconception happens to give the right answer, cannot be checked on Bands A and B: their sums have no column work. It is wired for Band C through the tag rules (for example `smallbig(58, 23) = 35` = the right answer).

## 6. What was NOT checked

- Hints and their pictures (the B-40 test and lint own those), voice accept-lists, `trace` strokes and `shape_builder` layouts (marked n/a: they have no maths answer to recompute).
- How the pictures really look on the phone. Counts, sprites and SVG geometry were read from the files, not looked at as rendered PNGs. The LTR check reads the content and confirms that each renderer declares `TextDirection.ltr`. The goldens remain the proof of how it looks.
- Semantic tables (which object goes with which, a routine's order, the colour of the sun, what rolls) are small tables in the checker and encode common sense, not a source.
- Outside sources were not opened today. Every rule here comes from `docs/curriculum.md` §4, §5.2 and §5.3, `docs/milestones/M10.md` (acceptance 3, 4 and 6, X10) and `docs/PLAN.md` › Learners & age bands.

## 7. Using the checkers as the Band C gate

`python -I tools/check_maths.py --band C --strict` and `python -I tools/check_robot.py --band C --strict` must exit 0 for a Band C batch: no WRONG, RULE, AMBIG or UNCHECKED finding. In strict mode an item no rule understands fails, so every new Band C item kind needs its rule in the checker (or structured fields) before the batch can pass. The qa-engineer adds both commands and both test files to CI (`python3 -I -X utf8 tools/test_check_maths.py`, `tools/test_check_robot.py`), next to `test_hebrew_sources.py`.

## Owner decision on W3 (2026-11-06)

A square is a rectangle (owner: "Yes, but we need to make sure it is not confusing the child"). So: no item marks the square wrong for "rectangle" or tags it M-SHP-SQRECT. In Band A, "where is the rectangle?" items show no square at all (neither the answer nor a distractor), so the young child meets no hidden rule; the inclusive idea ("a square is a special rectangle") is taught on its own in Band B (b.shpb03.7 and its lesson), with its own picture and words.

---

## 8. The fixes (2026-11-06, branch `hebrew-review`)

Made in the sources only (`content/units/*.json` for Band A, `tools/band_b.py`, `band_b2.py`, `band_b3.py` for Band B, `tools/author.py`), then `python tools/regen_content.py`, `python tools/export-hebrew-review.py`, `python tools/hebrew_voice_review.py`. One file has no spec and is its own source: `content/starter/skill.COL-A-02.json` (an M2 file, edited by hand as `regen_content.py` says). No voice command was run and nothing was spent. The 405 untagged distractors are B-36 and were not touched, except where a false tag had to come off (marked "untagged" below).

### 8.1 Wrong content

| # | Item(s) | Before | After | Why |
|---|---|---|---|---|
| W1 | x.shpb09.4 (`band_b3.py`) | sphere – circle, pyramid – triangle, box – rectangle | **cone** – circle, pyramid – triangle, box – rectangle | A sphere has no flat face. |
| W2 | b.logb06.1 to .4 (`band_b2.py`) | options colour, shape, size (the three shapes are drawn the same size) | options **colour and shape** only; .5 and .6 (the size rule) keep three | "The size" was a second right answer. Shapes in three sizes need new art (design-director); then the size option can come back. |
| W3 | shp.rect.find, shp.rect.long (`shapes.json`) | rectangle, **square** (M-SHP-SQRECT), circle | rectangle, **triangle**, circle (no tag) | Owner: a square is a rectangle, and Band A rectangle items show no square. |
| W3 | shp.rect.blue, shp.rect.green | others square and circle / triangle and square | others **triangle and circle** | same |
| W3 | b15.shpa04.1, .2 | rectangle and square (tagged) | rectangle and **circle** / **triangle** (no tag) | same |
| W3 | `author.py` › `k_shape` | a square offered for "the rectangle" was tagged M-SHP-SQRECT automatically | only a rectangle offered for "the square" is tagged; a square offered for "the rectangle" stops the build (assert) | so the rule cannot come back |
| W3 | b.shpb03.2, .4, .6 (`band_b2.py`) | the square tagged M-SHP-SQRECT; `כֵּן! בְּמַלְבֵּן יֵשׁ צְלָעוֹת אֲרֻכּוֹת וּצְלָעוֹת קְצָרוֹת.` and `בְּמַלְבֵּן שְׁתֵּי צְלָעוֹת אֲרֻכּוֹת וּשְׁתֵּי צְלָעוֹת קְצָרוֹת…` | square **untagged** (the question asks for a rectangle whose sides are not all equal, so it stays wrong there); `כֵּן! בַּמַּלְבֵּן הַזֶּה יֵשׁ צְלָעוֹת אֲרֻכּוֹת וּצְלָעוֹת קְצָרוֹת.` and `בַּמַּלְבֵּן הַזֶּה שְׁתֵּי צְלָעוֹת אֲרֻכּוֹת וּשְׁתֵּי צְלָעוֹת קְצָרוֹת. עַכְשָׁו תּוֹרְכֶם.` | M-SHP-SQRECT is "thinks a square is not a rectangle": picking the square here does not show it. "In a rectangle there are long and short sides" is false for a square; "this rectangle" is true. **needs-editor** |
| W3 | the shared M-SHP-SQRECT line (`shapes.json` › `tagFeedback`; 13 rows) | `בְּרִבּוּעַ כׇּל הַצְּלָעוֹת שָׁווֹת. בְּמַלְבֵּן יֵשׁ צְלָעוֹת אֲרֻכּוֹת וּקְצָרוֹת.` | `בְּרִבּוּעַ כׇּל הַצְּלָעוֹת שָׁווֹת. בַּמַּלְבֵּן הַזֶּה יֵשׁ צְלָעוֹת אֲרֻכּוֹת וּקְצָרוֹת.` | Every remaining use is a rectangle picked as "the square"; the line speaks of that rectangle. Same voice id (`vo:fb.shp_sqrect`): its clip must be voiced again. **needs-editor** |
| W3 | b.shpb03.7 (spot "collects only rectangles", `band_b2.py`) | the shared line | its own line `vo:fb.sqrect.square_is_rect`: `גַּם רִבּוּעַ הוּא מַלְבֵּן: מַלְבֵּן שֶׁכׇּל הַצְּלָעוֹת שֶׁלּוֹ שָׁווֹת. בּוֹאוּ נִסְפֹּר אֶת הַצְּלָעוֹת בְּכׇל צוּרָה.` | A tap on the square here *is* "a square is not a rectangle", so the line teaches the inclusive idea (owner: taught on its own in Band B). It ends in a strategy, with no `לֹא` (owner Q2). **needs-editor** |

### 8.2 Ambiguous items

| # | Item(s) | Before | After | Why |
|---|---|---|---|---|
| A1 | b.logb02.3 (`band_b2.py`) | apple fish star apple fish **apple** apple fish (break at cell 5) | apple fish star apple fish star **star** fish (break at cell 6) | The unit is shown twice before the break, and the wrong picture (star) is not unique, so one reading is left. |
| A1 | b.logb02.6 | cat dog **cat** cat dog star … (break at cell 2) | cat dog star cat dog star cat **star** (break at cell 7) | same |
| A2 | b.shpb03.1, .3, .5 | distractor `shape_triangle` (sides 82, 82, 80) | `shape_triangle_thin` (its name added to Band B's `NAMES`) | The plain triangle looks equal-sided. |
| A3 | b.mathb09.9 to .12 (`band_b.py`) | `7 = 5 + 3` and so on, wrong cell 4, caption `חָבֵר כָּתַב מִסְפָּרִים, וְאֶחָד מֵהֶם לֹא מַתְאִים. אֵיפֹה הַטָּעוּת?` | `8 = 3 + 4`, `6 = 5 + 2`, `10 = 6 + 3`, `8 = 4 + 5`, wrong cell **0** (the answer, written first); caption `חָבֵר כָּתַב תַּרְגִּיל, וְהַתְּשׁוּבָה לֹא נְכוֹנָה. אֵיפֹה הַטָּעוּת?` (MATH-B-03's reviewed caption) | The caption names the result, so one cell is right. The answer on the left is MATH-B-09's own idea (U5), and a tap on the last number is the M-EQ-OPER signal. The hint and the correct line already said `z שָׁוֶה x וְעוֹד y`. **For the editor**: does `הַתְּשׁוּבָה` read right when the answer is written first? |
| A4 | the 8 NUM-A-13 queue items | | **not fixed here**: a picture (design-director, 8.10) | The tiles need a visible head of the line. |
| A5 | log.same.balloon and LOG-A-01 (`logic.json`) | "the same thing" was identical in six items, the same kind in b15.loga01.3 and .4 | **the same kind** everywhere: log.same.balloon no longer offers the blue balloon | One meaning, the one the transfer and sorting items use. |
| A6 | b.numb05.8 (`band_b.py`) | give 20 fish from a pile of 20 | give **19** fish from 20 | Taking the whole pile is never right, so M-CNT-CARD can show (curriculum §4: N ≤ 20, so the pile does not grow). |

### 8.3 Robots

| # | Item(s) | Before | After | Why |
|---|---|---|---|---|
| R1 | b.csb01.6 (`band_b2.py`) | up, right, up, right, up, left (6 steps; its worked example walked the detour) | **up, right, up, up** (4, the shortest; CS-B-01 is 4 to 6 steps) | The hint now shows the shortest way. |
| R2 | cs.robot.plan.3 (`robots.json`) | flag at (3, 1): right ×3, up | flag at (2, 1): **right, right, up** | CS-A-04 plans 2 to 3 steps. |
| R2 | cs.robot.plan.4 | flag at (2, 2): right ×2, down ×2 | flag at (1, 2): **right, down, down** | same |
| R2 | cs.robot.plan.6 | flag at (3, 0): right ×2, up ×2 | flag at (2, 0): **right, up, up** | same |

### 8.4 Mis-tags (15)

| Item(s) | Before | After | Why |
|---|---|---|---|
| b.mathb03.1 to .4, .15 | sum − 1 tagged M-CNT-DOUBLE | **M-CNT-SKIP** (the subtraction items keep M-CNT-DOUBLE on the result + 1) | Counting on with the start counted gives one less: a miss (§5.2: n−1). Its line `אוּלַי פִּסְפַּסְנוּ אֶחָד? בּוֹאוּ נִבְדֹּק.` is reviewed text. |
| b.mathb08.1 to .8 | same | **M-CNT-SKIP** | same |
| b.mathb07.6 | 0 + 0 with 2 tagged M-NUM-ZERO | **9 − 0**: 0 and 8, both M-NUM-ZERO | No zero rule gives 2; the template's n − 0 traps are honest. |
| b.numb08.10 | "where is 11?": 1 tagged M-NUM-TEEN | 1 **untagged** (12 keeps M-CNT-SEQ) | §5.2's M-NUM-TEEN is "as heard" (110). The pack's own parent text for M-NUM-TEEN ("reads a teen as one digit only") does describe the 1: a catalogue question (8.10). |

### 8.5 Numbers out of range (10 items)

| Item(s) | Before | After | Choice |
|---|---|---|---|
| b.numb10.3, .4, .7, .8, .9, .10 | 12 v 8, 15 v 17, 14 v 11, 19 v 20, 13 v 31, 18 v 8 | 8 v 6, 9 v 10, 10 v 7, 7 v 8, **1 v 10**, 2 v 5 | **Conservative, as curriculum §4 says: NUM-B-10 compares numbers ≤ 10.** 1 v 10 keeps the digit trap of 13 v 31. |
| x.numa07.5, .6 | sets 2, 4, 6 and 4, 5, 6 | 2, 4, 5 and 1, 4, 5 | NUM-A-07 is numerals 1 to 5. |
| b.numb16.10, .11 | ten and 4 / 7: options 14, **41**, 10 / 17, **71**, 10 | 14, **4**, 10 / 17, **7**, 10 (both parts M-PART-MISS) | **Conservative: no Band B option above 20.** The reversal belongs to NUM-B-08. |
| b.mathb08.14 (and .13) | 9 + ? = 15 (options 6, 15, **24**); 8 + ? = 13 (5, 13, **21**) | **8 + ? = 12** (4, 12, 20) and **6 + ? = 11** (5, 11, 17) | Same choice. .13's 21 was inside the checker's +2 margin but above 20, so it went too. Both still cross ten. |

### 8.6 Band A shows at most 3 options (10)

| Item(s) | Before | After |
|---|---|---|
| ordinal.first.of4, .second.of4, .third.of4, ordinal.last, b15.numa13.1, .2 | a queue of four | a queue of three (the ids stay, so a child's progress stays) |
| col.find.red.balloon, .blue.ball, .green.balloon, .yellow.flower | four options, the fourth untagged | the untagged fourth (a flower, or a ball of a third colour) removed; the two tagged distractors stay |

### 8.7 Two distractors under one tag (27)

| Item(s) | Before | After | Why |
|---|---|---|---|
| b15.cola02.3, .4 | two M-COL-NAME; COL-A-02 watched no tag | `skill.COL-A-02.json` watches **M-COL-NAME** | Curriculum §4 gives COL-A-02 exactly this tag (and M-COL-NAME's record already lists COL-A-02). The two items stay as they are. |
| b15.numa08.2 | options 3, 2, 1, both M-CNT-SKIP | **3, 2, 4**: M-CNT-SKIP and M-CNT-DOUBLE | one short and one over |
| b15.shpa01.1 | square and circle, both M-SHP-ORIENT, for an upside-down triangle | **tilted square** (M-SHP-ORIENT: matched by the point, not the shape), circle (untagged), triangle | A plain square or circle does not show orientation; the tilted square does. The circle has no honest tag. |
| shp.any.tilt | rectangle and circle, both M-SHP-ORIENT | rectangle **M-SHP-SQRECT** (a long rectangle taken for the square, as in curriculum §7.5 item 8), circle M-SHP-ORIENT | distinct and true |
| shp.any.thin | rectangle, circle, both M-SHP-PROTO | **open figure M-SHP-CLOSED**, circle M-SHP-PROTO | the open three-line figure is the classic "triangle" lure |
| shp.any.down | square, circle, both M-SHP-ORIENT | **open figure M-SHP-CLOSED**, circle M-SHP-ORIENT | same |
| shp.any.small | circle, square, both M-SHP-SIZE | circle M-SHP-SIZE, **curved figure M-SHP-CLOSED** | as SHP-B-04 tags the curved figure |
| shp.any.small.square | circle, triangle, both M-SHP-SIZE | circle M-SHP-SIZE, **rectangle M-SHP-SQRECT** | a rectangle taken for the square |
| shp.any.big.circle | triangle and square, both M-SHP-SIZE | square M-SHP-SIZE, triangle **untagged** | No sprite gives a second honest error for a circle (an oval would: 8.10). |
| log.same.apple, .balloon, .bird, .cat, .duck, .star | three options, two M-COL-ONEATTR | **two options**: the same kind and one lure, M-COL-ONEATTR (the same-colour thing where there is one) | LOG-A-01 is the first logic skill (age 3), and b15.loga01.3 and .4 already have two options. With two options §5.3 asks for one tag. |
| b.mathb14.1 to .11 | the named day and the skipped day, both M-CNT-SEQ | the skipped day M-CNT-SEQ, the named day **untagged** | Answering with the day the question names is not a counting-order error, and §5.2 has no tag for it (8.10). |

### 8.8 Lines and tests touched for the fixes

- `tools/hebrew_voice_review.py`: `MATHS_CHECK_ROWS`, 59 rows added to `PENDING`, so they are `proposed` (**needs-editor**) in `docs/review/hebrew-master.csv` until the editor has read them: the new numbers in reviewed templates (b.numb05.8, b.numb10.*, b.mathb07.6, b.mathb08.13 and .14, the robot hints of b.csb01.6 and cs.robot.plan.6), the W3 lines (13 rows of the shared M-SHP-SQRECT line, the 6 "this rectangle" rows, b.shpb03.7's own line) and the moved A3 caption (8 rows).
- `tools/test_hebrew_sources.py`: the table pin is 12,751 rows (26 option rows fewer) and 1,296 done-and-changed rows (12 corrected rows now carry the corrected template's text).
- `app/test/content_lints_test.dart`: the §5.3 gap pin is 320 (+14 where a false second tag came off: b.mathb14.1 to .11, b.numb08.10, b15.shpa01.1, shp.any.big.circle; −4 where LOG-B-06 offers two options).

### 8.9 Counts before and after

`python -I tools/check_maths.py --dir <this worktree>/content/starter --list` and the same for `check_robot.py` (both from `D:\nitznutz-m10chk\tools`):

| | WRONG | RULE | AMBIG | NOTE | UNCHECKED |
|---|---|---|---|---|---|
| Maths, before (this branch) | 10 items | 457 findings, 431 items (393 tag-missing, 27 tag-distinct, 15 tag-rule, 12 range, 10 options) | 19 | 104 findings, 96 items | 3 |
| Maths, after | **0** | 409 items, all tag-missing (B-36) | 6 (A4, the queue picture) | 106 findings, 96 items | 3 |
| Robots, before | 0 | 16 (12 tag-missing, 3 band, 1 detour) | 0 | 6 | 0 |
| Robots, after | **0** | 12, all tag-missing (B-36, R3) | 0 | 6 (Band A direct control, allowed) | 0 |

The 3 UNCHECKED are col.world.sun, .grass and .banana.ripe: the editor's pass of today changed `אֵיזֶה צֶבַע` to `מַה צֶּבַע`, and the checker's colour rule still looks for the old words (a one-line fix in `check_maths.py` on `m10-checkers`; the items were right when they were checked). tag-missing went from 393 to 409: the 16 items above where a false tag came off or a Band A square left. The 2 new NOTEs are M-PART-MISS (a record, renamed M-PPW by B-36) on b.numb16.10 and .11.

### 8.10 Still open (hand-offs)

- **design-director**: (1) A4, the NUM-A-13 queue: a head of the line (a door or a counter) at its start, the animals facing it, the tiles in that order, never mirrored; 8 items (b15.numa13.1, .2, ordinal.first, .first.of4, .last, .second.of4, .third, .third.of4). (2) Shapes in three sizes (`shape_*_size_s/m/l`), so LOG-B-06 .1 to .4 can offer "the size" again. (3) An oval and a non-square rhombus, for honest second distractors (M-SHP-PROTO, curriculum §7.5 item 8) in shp.any.big.circle and shp.any.tilt.
- **hebrew-text-editor**: the 59 `proposed` rows of 8.8 (the three new W3 texts, the A3 caption in front of an answer written first, and the template rows with new numbers). Also: M-COL-ONEATTR's line `יֵשׁ שְׁנֵי דְּבָרִים לִבְדֹּק: מַה זֶּה, וְאֵיזֶה צֶבַע.` is used in LOG-A-01, where the colour does not matter (a green apple is "the same thing"), so LOG-A-01 may want a line of its own. And the SHP-B-03 lesson title `רִבּוּעַ אוֹ מַלְבֵּן` and celebration `אַתֶּם מַבְחִינִים בֵּין רִבּוּעַ לְמַלְבֵּן` read as if they were two kinds; under W3 they could say what the lesson teaches (a square is a special rectangle). Not changed here.
- **voice-and-sound-director**: `vo:fb.shp_sqrect` keeps its id with a new text, and `vo:fb.sqrect.square_is_rect` is new; the changed items' prompts and hints join the next voicing batch (the owner runs it).
- **curriculum-expert** (proposals for the owner): (1) curriculum §4 SHP-A-04 still says "tells it from a square informally"; after W3 it is "recognises a rectangle; Band A shows no square beside it", and §5.2 M-SHP-SQRECT's signal could read "picks a long rectangle for the square, or leaves the square out of the rectangles". (2) A catalogue tag for answering with the day the question names (MATH-B-14, 11 items), or MATH-B-14 watching M-CNT-SEQ. (3) M-NUM-TEEN's signal could include "hears only the ones: picks 1 for 11", as the pack's parent text already says. (4) The §5.3 pin of `content_lints_test.dart` moved to 320.
- **orchestrator**: the pack sources changed, so `starter_pack_test` › "the pack was built from the sources" stays red until the owner signs the next pack (as for the Hebrew review).
