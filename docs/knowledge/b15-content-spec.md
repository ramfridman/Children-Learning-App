# B-15 content spec: reachable mastery, honest labels, tagged wrong answers

Curriculum-expert (Knowledge Agent), 2026-10-30, worktree `D:\nitznutz-content`, branch `content-b3-b15`. For the app-developer to build in the generators (`tools/author.py`, `band_b*.py`, `content/units/*.json`), **existing templates only**. Measured on `content/starter` as of 2026-10-30 (767 activities, 100 skills). Nothing here changes the syllabus, the engine or the path (§6).

**Proof (part 1).** `app/test/mastery_reachable_test.dart` plays a child who answers every activity of a skill right, with no hint, once a day for 4 days, through the real `Engine` (`_checkFresh`, default `EngineParams`). **91 of 100 skills cannot reach fresh mastery**: 91 lack an understanding check (89 have none; NUM-A-04 and MATH-B-03 are core and have one type, they need two), 11 of the 12 core skills also lack a second representation, and `graph.report()` has 97 lines. The 9 reachable today are CS-B-04, LOG-B-02, MATH-A-06, MATH-B-09, NUM-A-06, NUM-A-07, NUM-B-05, NUM-B-11 and NUM-B-17. The two target tests (all 100 reachable; `graph.report()` empty) are skipped unless `--dart-define=QA_OPEN=true`; they fail now, and pass when this spec is built. Remove their `skip: _open` then.

**How to read the tables.** `chk` is `checkType`, `rep` is `representation`. `r` = right answer. Tags use the **pack's** names. "Pattern" = an existing prompt pattern of that kind with new values (no new wording; the editor checks agreement). `Hn` = a new Hebrew string, listed in §5. New activities are **appended** after the skill's existing ones, so every existing id keeps its number (the children's history refers to them). A check counts once it is passed once without a hint, so 1 to 2 items per check type are enough.

## 0. Generator changes this spec needs (app-developer)

| # | Change |
|---|---|
| G1 | Every builder reads `a.get('check', default)` and `a.get('rep', default)`; today most hard-code them. `k_spot` default check becomes `error_spotting` (it is U5, not U4). |
| G2 | The representation comes from the rule in §2, not from the kind. Each skill doc's `representations` = the set its activities really use. |
| G3 | `count_tap`, `numline`, `scale`, `sort` and `spot` accept any primary skill (`skill` + `also` weights), as `pick` does. |
| G4 | A per-item override of the shared tag line (`tag_lines: {tag: (vo, text)}`), for the number-sentence line of M-PART-MISS (H30). |
| G5 | MATH-B-10: the six items get `scene.chart` with one column per plate (`[{sprite, count: k}] × g`), before any new item is added (audit F10). |

## 1. Checks and second representations, per skill (part a and b)

Core skills (12) need two **different** check types and two representations; the others need one check. "Relabel" = an item that already is a check but is labelled `practice`. Totals at the end of the section.

### Numbers

| Skill | Core | Add (kind ×n, chk, rep: values → r; tags) | Hebrew |
|---|---|---|---|
| NUM-A-01 | yes | **rep:** `count_tap` ×3, chk transfer, concrete, line, skills {A-01:1, A-03:0.5}: 3 cats, 4 dogs, 5 ducks (count-along, the row's own evidence). count_tap needs a `_lit` picture, so only apple, bird, butterfly, cat, dog, duck, fish, ladybug and star. **chk 2:** `spot` ×2, error_spotting, symbolic: cells [1,2,4,4,5] wrong idx 2; [1,3,3,4,5] wrong idx 1; tag M-CNT-SEQ | prompt = NUM-B-11's "חָבֵר סָפַר מִסְפָּרִים, וְיֵשׁ בָּהֶם טָעוּת. אֵיפֹה הַטָּעוּת?" (no negation); h3 = the right count words + "עַכְשָׁו תּוֹרְכֶם." (pattern) |
| NUM-A-02 | yes | `count_tap` ×3 transfer concrete line: 6 ducks, 8 stars, 10 apples. `spot` ×2 error_spotting: [6,7,9,9,10] idx 2; [5,6,7,9,9] idx 3; M-CNT-SEQ | as A-01 |
| NUM-A-03 | yes | **rep:** `set_to_numeral` ×2, practice, pictorial, scatter: 4 butterflies, 5 ladybugs → {r, r+1 M-CNT-DOUBLE, r−1 M-CNT-SKIP}. **chk:** `count_tap` ×2 transfer, scatter, sprites it has not used (4 cats, 5 dogs); `spot` ×1 error_spotting [1,2,3,3,5] idx 3, M-CNT-DOUBLE | pattern; spot prompt as A-01 |
| NUM-A-04 | yes | **rep:** `set_to_numeral` ×2 pictorial line: 3 fish, 5 birds, tags as A-03. **chk 2:** `count_tap` ×2 transfer scatter (4 ducks, 3 stars). One more `give` (4 stars) stays reverse | pattern |
| NUM-A-05 | | `flash` ×2 transfer, arrangement `line` (it has dice, ten-frame and scatter): 2 frogs, 3 chicks → {r, r−1 M-CNT-SKIP, r+1 M-CNT-DOUBLE} | pattern |
| NUM-A-06 | | relabel its 7 `give` items chk **practice** (giving N is this skill's own task, not its reverse). Add `give` ×2 transfer: 4 fish from 9 into `bowl_empty`; 3 birds from 7 into `nest_empty` | pattern "תְּנוּ לִי…" |
| NUM-A-07 | | none (reachable) | |
| NUM-A-08 | yes | **rep + chk 1:** `numeral_to_set` ×2, reverse, pictorial, skills {A-08:1}: numeral 2 → sets {2, 3 M-CNT-DOUBLE, 1 M-CNT-SKIP}; numeral 3 → {3, 2 M-CNT-SKIP, 1 M-CNT-SKIP}; sets 1 to 3 only (subitised, so no counting skill is needed). **chk 2:** `spot` ×2 error_spotting symbolic: [1,5,3,4,5] idx 1; [1,2,3,4,2] idx 4; M-NUM-REV (2 and 5 are the mirror pair) | H2 |
| NUM-A-09 | | `count_tap` ×2 transfer scatter: 7 ducks, 9 butterflies | pattern |
| NUM-A-10 | | `flash` ×2 transfer `scatter`: 4 frogs, 5 chicks; tags as A-05 | pattern |
| NUM-A-11 | | `compare_more` ×2 transfer (unlike objects): 4 frogs vs 3 chicks spread wide (`scatter`), "more"; 2 options, the spread set tagged M-CNT-SIZE | pattern |
| NUM-A-12 | | `compare_more` ×2 transfer, new objects (curriculum row: "U3 transfer"): 5 small chicks vs 3 frogs at `scale` 1.5; the big set M-CNT-SIZE | pattern |
| NUM-A-13 | | `ordinal` ×2 transfer, a new queue (frog, chick, bird, fish): "second", "last"; option at position n counted from the back M-ORD-CARD, as `ordinal.second` | pattern |
| NUM-A-14 | | `pick` ×2 **predict**, story: group 3 birds → "all flew away" {0, 1 M-NUM-ZERO, 3 M-CNT-CARD}; group 2 fish {0, 1 M-NUM-ZERO, 2 M-CNT-CARD} | H1a, H1b |
| NUM-B-01 | | `next_number` before ×2 reverse: before 13 → {12, 21 M-NUM-REV, 14 M-CNT-SEQ}; before 18 → {17, 71 M-NUM-REV, 19 M-CNT-SEQ} | pattern "מַה בָּא לִפְנֵי…" |
| NUM-B-02 | | **relabel** `b.numb02.6`, `.7` (before 21, before 30) chk reverse | none |
| NUM-B-03 | | `spot` ×2 error_spotting: [10,9,7,7,6] idx 2; [8,7,6,4,4] idx 3; M-CNT-SEQ | as A-01 |
| NUM-B-04 | | `count_tap` ×2 transfer, sprites it has not used (with `_lit`): 14 ducks, 17 butterflies (two rows if `scatter` cannot hold them) | pattern |
| NUM-B-05 | | relabel its 8 `give` chk **practice** (as NUM-A-06). Add `give` ×2 transfer: 12 fish from 20 into `bowl_empty`, 16 birds from 20 into `nest_empty` | pattern |
| NUM-B-07 | | `trace` ×2 transfer, `guide: "start"` (only the start dot: the "dotted → free" step of the row): 2 and 5 | pattern |
| NUM-B-08 | | `pick` ×2 transfer, row [n:11, n:12, ?, n:14] → {13, 31 M-NUM-REV, 15 M-CNT-SEQ}; row [n:16, ?, n:18] → {17, 71 M-NUM-REV, 18 M-CNT-SEQ} | NUM-B-11's "missing number" pattern |
| NUM-B-10 | | `pick` ×2 reverse (the row's U4, "which is smaller?"), 2 options: 12 vs 21, 13 vs 31; the reversed one M-NUM-REV | H3 |
| NUM-B-11 | | none (reachable; its spots become error_spotting) | |
| NUM-B-13 | | **relabel** the 7 jump items (`b.numb13.13` to `.19`, "on which number will she land?") chk **predict** (U1). Add `numline` place ×2 transfer, 0 to 10, `labels: [0, 10]` only: place 5, place 8 | pattern |
| NUM-B-14 | | `pick` ×2 reverse (join the parts back): group 4 + group2 2 → {6, 4 M-PART-MISS, 7 M-CNT-DOUBLE}; 5 + 3 → {8, 5 M-PART-MISS, 9 M-CNT-DOUBLE} | H4 |
| NUM-B-16 | | see §4 | |
| NUM-B-17 | | none (reachable) | |
| NUM-B-18 | | `pick` ×2 transfer, shoes: 6 and 7 `shoe`, scatter | pattern |

### Colours, Computer science

| Skill | Core | Add | Hebrew |
|---|---|---|---|
| COL-A-01 | | `pick` ×2 transfer, target of a new object class: `ball_blue` → {bloom_blue, ball_red M-SORT-SHIFT, bloom_purple M-COL-NAME}; `balloon_yellow` → {ball_yellow, balloon_green M-SORT-SHIFT, ball_orange M-COL-NAME} | pattern |
| COL-A-02 | yes | **rep:** `sort` ×2 practice concrete, skills {COL-A-02:1}: red/blue, yellow/green (COL-A-04's sort, bins named by colour). **chk:** `pick` ×2 transfer to shapes (its practice uses balls, balloons and flowers): "the yellow shape" {circle_yellow, circle_green M-COL-NAME, circle_orange M-COL-NAME}, "the green shape" {square_green, square_blue M-COL-NAME, square_yellow M-COL-NAME}; `spot` ×2 error_spotting pictorial: [ball_red, ball_red, ball_orange, ball_red] idx 2 "only red"; [bloom_blue, bloom_purple, bloom_blue, bloom_blue] idx 1; M-COL-NAME | sort: COL-A-04 pattern; spot H6 |
| COL-A-03 | yes | as COL-A-02 with orange/red and black/white sorts; transfer "the orange shape" with square_orange and circle_orange {r, red M-COL-NAME, yellow M-COL-NAME}; spots [bloom_orange, bloom_orange, bloom_red, bloom_orange] idx 2 and [ball_black, ball_brown, ball_black, ball_black] idx 1, M-COL-NAME | as A-02 |
| COL-A-04 | | `sort` ×2 transfer concrete (a new form of the same rule, and its second representation): mixed objects into red/blue, yellow/green | pattern |
| COL-A-05 | | `pick` ×2 transfer, tick/cross: group `banana_green` "is this a banana?", group `apple_green` "is this an apple?" → tick; cross M-COL-OBJECT | H7a, H7b |
| COL-A-06 | | `spot` ×2 error_spotting (balls, balloons and flowers are all used): "only brown" [ball_brown, bloom_brown, ball_orange, balloon_brown] idx 2; "only grey" [ball_grey, balloon_grey, ball_white, bloom_grey] idx 2; M-COL-NAME | H6 |
| COL-A-07 | | `pick` ×2 transfer, blooms: "the blue flower" {bloom_blue, ball_blue M-COL-ONEATTR, bloom_purple M-COL-NAME}; "the red flower" {bloom_red, balloon_red M-COL-ONEATTR, bloom_orange M-COL-NAME} | pattern |
| COL-B-01 | | `pick` ×2 reverse: group ball_red, "red and which colour make orange?" {yellow, orange M-COL-MIX, blue M-COL-NAME}; ball_blue, "…make green?" {yellow, green M-COL-MIX, red M-COL-NAME} | H8a, H8b |
| COL-B-02 | | `pick` ×2 transfer, purple shades: "darkest", "lightest" (its practice is blue, green and red) | pattern |
| COL-B-03 | | `pick` ×2 transfer, purple shades: "where else is purple?" | pattern |
| COL-B-04 | | `spot` ×2 error_spotting pictorial: sorted by colour [circle_red, square_red, triangle_blue, rect_red] idx 2; by shape [circle_red, circle_blue, square_green, circle_yellow] idx 2; M-SORT-SHIFT | H9a, H9b |
| COL-B-06 | | `spot` ×1 error_spotting: rainbow [red, orange, purple, green, blue, purple] idx 2; M-PAT-COPY | H10 |
| CS-A-01 | | `pick` ×2 reverse ("right after"; it already has first, middle, last for both routines): teeth, after the paste → {brush, rinse M-SEQ-CAUSE, paste M-SEQ-CAUSE}; hands, after the soap → {rinse, towel M-SEQ-CAUSE, tap M-SEQ-CAUSE} (E1) | H11a, H11b |
| CS-A-03 | | `robot` ×2 transfer: new board shapes, cols 2 × rows 4 (start bottom, flag top), cols 4 × rows 2 (start top right, flag bottom left) | existing prompt |
| CS-A-04 | | `pick` ×2 **predict**, pictorial: row [robot, grass, grass, flag] → {3, 4 M-CS-OFF1, 2 M-CNT-SKIP}; row [robot, grass×3, flag] → {4, 5 M-CS-OFF1, 3 M-CNT-SKIP} (second representation too) | H12 |
| CS-A-05 | | `spot` ×2 error_spotting pictorial (the skill as the curriculum writes it): [step_paste, step_brush, step_soap, step_rinse] idx 2; [step_tap, step_soap, step_brush, step_towel] idx 2; M-SEQ-CAUSE | H13a, H13b |
| CS-B-01 | | gains a second representation by relabel (§2). `pick` ×2 predict as CS-A-04, rows of 5 and 6 steps | H12 |
| CS-B-04 | | none (reachable) | |

### Logic

| Skill | Core | Add | Hebrew |
|---|---|---|---|
| LOG-A-01 | yes | **rep:** `sort` ×2 practice concrete: apples/fish, cats/ducks ("each with the same thing"). **chk:** `pick` ×2 transfer, 2 options: target apple → {apple_green, ball_red M-COL-ONEATTR}; balloon_red → {balloon_blue, ball_red M-COL-ONEATTR}; `spot` ×2 error_spotting [apple, apple, fish, apple] idx 2, [duck, duck, duck, bird] idx 3; M-SORT-SHIFT | H14; spot H6 |
| LOG-A-02 | | `pick` ×2 transfer, odd one out by size: row [ball_size_l ×3, ball_size_s], row [star_size_s, star_size_l ×3] | pattern |
| LOG-A-03 | | `sort` ×2 transfer by size: big/small (`*_size_l`, `*_size_s`) | H15 |
| LOG-A-04 | | `spot` ×2 error_spotting: [cat, dog, cat, dog, dog, dog] idx 4; [ball_red, ball_blue, ball_red, ball_red, ball_red, ball_blue] idx 3; M-PAT-UNIT | H16 (LOG-B-02's prompt has "לֹא", ruled out in Band A) |
| LOG-A-05 | | `build` ×2 transfer, an ABB core it has not used: [fish, star, star, fish, star, star], [ball_red, ball_blue, ball_blue, ball_red, ball_blue, ball_blue] | pattern |
| LOG-A-06 | | `pick` ×2 transfer, size patterns: row [l, s, l, s, l, ?] → {s, l M-PAT-NEXT, m M-PAT-UNIT} | pattern |
| LOG-A-07 | | `spot` ×2 error_spotting: [fish, bird, fish, fish, fish, bird] idx 3; [ball_yellow, ball_blue, ball_yellow, ball_blue, ball_blue, ball_blue] idx 4; M-PAT-NEXT | H16 |
| LOG-A-08 | | `pick` ×2 reverse ("just before"): chick → {egg_crack, egg M-SEQ-CAUSE, chick M-SEQ-CAUSE}; flower → {plant_sprout, plant_seed M-SEQ-CAUSE, plant_flower M-SEQ-CAUSE} (E1) | H17a, H17b |
| LOG-A-09 | | `pick` ×2 transfer, pairs it has not used: plate → spoon; cloud → rain | pattern |
| LOG-A-10 | | `pick` ×2 transfer, towers (it uses balls, apples, fish and stars): [tower_1, tower_2, ?], [?, tower_2, tower_3]; options per §3 | pattern |
| LOG-B-01 | | `pick` ×2 transfer, new objects: ABB with fish/star, AAB with frog/chick | pattern |
| LOG-B-04 | | `pick` ×2 transfer, step 2: row [tower_1, tower_3, ?] → {tower_5, tower_1 M-PAT-GROW, tower_4 M-PAT-NEXT}; row [tower_2, tower_4, ?] → {tower_6, tower_2 M-PAT-GROW, tower_5 M-PAT-NEXT} | pattern |
| LOG-B-06 | | `spot` ×2 error_spotting: as COL-B-04 | H9a, H9b |
| LOG-B-08 | | `sort` ×2 transfer, the rule on shape: "if it is a circle…", "if it is a triangle…" | pattern |
| LOG-B-09 | | `pick` ×2 transfer, new pairs of "not": not yellow and not square; not green and not circle | pattern |
| LOG-B-11 | | `spot` ×2 error_spotting: towers [1,2,2,4,5] idx 2; [5,4,4,2,1] idx 2; M-SER-ENDS | H18 |

### Shapes, Money and Maths

| Skill | Core | Add | Hebrew |
|---|---|---|---|
| SHP-A-01 | | `pick` ×2 transfer, turned targets: `shape_triangle_down` → {triangle_green, square_green M-SHP-ORIENT, circle_green M-SHP-ORIENT}; `shape_square_tilt` → {square_red, rect_red M-SHP-SQRECT, circle_red M-SHP-ORIENT} | pattern |
| SHP-A-02 | yes | (already 2 reps). **chk:** `pick` ×2 transfer, coloured shapes: circle_green, square_orange, options per §3; `spot` ×2 error_spotting [circle, circle, square, circle] idx 2, [square, square, square, triangle] idx 3; M-SORT-SHIFT | spot H6 |
| SHP-A-03 | yes | **rep + chk 1:** `sort` ×2 transfer concrete, squares/circles including `shape_square_tilt` and two sizes | COL-B-04's "עַכְשָׁו מְמַיְּנִים לְפִי צוּרָה: עִגּוּלִים לְכָאן, וְרִבּוּעִים לְכָאן." |
| | | **chk 2:** `spot` ×2 error_spotting: [triangle, triangle_down, square, triangle_thin] idx 2; [square, square_tilt, square, circle] idx 3; M-SHP-ORIENT | H6 |
| SHP-A-04 | | `pick` ×2 transfer, 2 options: rect_orange vs square_orange, rect_yellow vs square_yellow; square M-SHP-SQRECT | pattern |
| SHP-A-05 | | **relabel** `shp.world.plate.shape` (and any "which shape does the … have?") chk reverse | none |
| SHP-A-06 | | `shapebuild` ×2 transfer: a train, a tree (layouts by the design-director) | H19a, H19b |
| SHP-A-07 | | `pick` ×2 transfer, solids instead of toys: rolls → {solid_sphere, solid_box}; stacks → {solid_box, solid_sphere} | pattern |
| SHP-A-08 | | `pick` ×2 transfer with a new pair of objects (a cat and a basket) in two positions; needs 2 pictures from the design-director (H-C), so it is the last row to build | pattern |
| SHP-A-10 | | `pick` ×2 transfer, 2 options: "which shape has a curved line?" circle vs square; circle vs triangle | H20 |
| SHP-B-01 | | `spot` ×2 error_spotting, "only triangles": [triangle, triangle, shape_open, triangle] idx 2, M-SHP-CLOSED; [triangle, triangle_thin, triangle_down, shape_open] idx 3, M-SHP-PROTO (a tap on the thin or turned one is the signal) | H6 |
| SHP-B-02 | | `pick` ×2 transfer, turned: `shape_square_tilt` (4 sides), `shape_triangle_down` (3) | pattern |
| SHP-B-03 | | `spot` ×1 error_spotting: "only rectangles" [rect, square, rect, triangle] idx 3. The square is right, so a tap on it is the M-SHP-SQRECT signal | H6 |
| SHP-B-04 | | `spot` ×1 error_spotting: "only closed shapes" [triangle, square, shape_open, pentagon] idx 2; M-SHP-CLOSED | H6 (noun H6c) |
| SHP-B-08 | | `spot` ×1 error_spotting: "only cylinders" [cylinder, cylinder, cone, cylinder] idx 2; M-SHP-FACE (they share the circle face) | H6 |
| SHP-B-09 | | `pick` ×1 reverse: "which solid leaves a circle in the sand?" {solid_cylinder, solid_box M-SHP-FACE, solid_sphere M-SHP-FACE}; never the pyramid (audit F9) | H21 |
| MATH-A-01 | | `madd` ×2 transfer, new objects: 2 frogs + 2, 3 chicks + 1 | pattern |
| MATH-A-02 | | `mtake` ×2 transfer, new objects: 4 frogs − 1, 5 chicks − 1 | pattern |
| MATH-A-03 | | `share` ×2 transfer, three friends: 6 apples, 3 fish among cat, dog, duck | H22a, H22b |
| MATH-A-04 | | `pick` ×2 transfer: "which fish is big?" fish_size_l vs fish_size_s; "which star is small?" | pattern |
| MATH-A-05 | | **relabel** `math.time.before` chk reverse | none |
| MATH-A-06 | | relabel its `give` items chk **practice** (paying one coin each is its task). `pick` ×2 reverse: "I have 3 coins, each apple costs one coin, how many apples?" group coin×3 → {3, 2 M-CNT-SKIP, 4 M-CNT-DOUBLE}; 4 coins → {4, 3, 5} | H23a, H23b |
| MATH-A-07 | | `pick` ×2 transfer, new objects; the fewer set drawn bigger (`scale` 1.5), tagged M-CNT-SIZE | pattern |
| MATH-B-01 | yes | **rep:** `count_tap` ×2 practice concrete (direct model of a join, R1): prompt = the join story text, 3 + 2 and 4 + 3 apples. **chk 1:** `pick` ×2 reverse (join, change unknown): group 3 apples, "now there are 5" → {2, 5 M-PART-MISS (the whole; line fb.part_miss), 3 M-CNT-DOUBLE}; 4 fish, "now 7" → {3, 7 M-PART-MISS, 4 M-CNT-DOUBLE}. (No "=" is shown in a story, so M-EQ-OPER, whose line explains the sign, is not used.) **chk 2:** `numline` jump ×2 transfer, 0 to 10: start 3 hops [2] → 5; start 4 hops [3] → 7 | count_tap: MATH-B-01 story text; H24; numline: NUM-B-13 jump pattern |
| MATH-B-02 | | `pick` ×2 reverse, as NUM-B-14 (H4): 2 in the basket + 5 outside → {7, 5 M-PART-MISS, 8 M-CNT-DOUBLE}; 3 + 6 → {9, 6 M-PART-MISS, 10 M-CNT-DOUBLE} | H4 |
| MATH-B-03 | yes | its 4 `spot` become error_spotting (chk 1). **rep:** `numline` jump ×2 practice pictorial: 2 hops 5 → 7; 6 hops 3 → 9. **chk 2:** `pick` ×2 reverse (the other orientation of `=`, R of M-EQ-OPER): row [?, op:=, n:3, op:+, n:4] → {7, 4 M-CNT-CARD, 6 M-CNT-DOUBLE}; [?, op:=, n:9, op:-, n:4] → {5, 9 M-CNT-CARD, 6 M-CNT-DOUBLE} | H25 |
| MATH-B-06 | | `pick` ×2 transfer, shekels (the U3 example of §5.6): group coin_s1×7 → {3, 10 M-PART-MISS, 7 M-CNT-CARD}; ×6 → {4, 10 M-PART-MISS, 6 M-CNT-CARD}. Also: 4 of its 8 practice items draw the group as `ten_frame` | H26 |
| MATH-B-07 | | `pick` ×2 reverse, MATH-B-18's pattern: row [n:6, op:+, ?, op:=, n:6] → {0, 6 M-EQ-OPER, 12 M-PART-MISS}; [n:4, op:+, ?, op:=, n:4] → {0, 4, 8} | pattern |
| MATH-B-08 | | `pick` ×2 reverse, MATH-B-18's pattern: 8 + ? = 13 → {5, 13 M-EQ-OPER, 21 M-PART-MISS}; 9 + ? = 15 → {6, 15, 24} | pattern |
| MATH-B-09 | | none (reachable; spots become error_spotting) | |
| MATH-B-10 | | after G5: `pick` ×2 reverse: 6 ducks, 2 on each plate, how many plates? chart [2,2,2] → {3, 6 M-CNT-CARD, 2 M-CNT-CARD}; 8 birds, 4 on each → {2, 8, 4} | H27 |
| MATH-B-13 | | gains a 2nd rep by relabel. `scale` compare ×2 **predict**, `hideTilt: true`: balloon_red (weight 1) vs stone (3); balloon_blue (1) vs key (2); the big light side M-MEAS-BIG | H28 |
| MATH-B-14 | | **relabel** `b.mathb14.10`, `.11` ("what was yesterday?", the reverse of "tomorrow") chk reverse | none |
| MATH-B-15 | | gains a 2nd rep by relabel; **relabel** its 8 `clock_set` items chk reverse (set the time = reading backwards) | none |
| MATH-B-16 | | `pick` ×2 transfer, 2 options, "which coin is worth more?": coin_h50 vs coin_s1 (→ s1); coin_s5 vs coin_s10 (→ s10); the bigger, lower coin M-MONEY-SIZE | H29 |
| MATH-B-17 | | `shop` ×2 transfer, new purses: price 7 with ₪5, ₪2, ₪1, ₪1; price 12 with ₪10, ₪2, ₪1 | pattern |
| MATH-B-18 | | `pick` ×2 transfer, the other orientation: row [n:7, op:=, n:3, op:+, ?] → {4, 7 M-EQ-OPER, 10 M-PART-MISS}; [n:9, op:=, n:5, op:+, ?] → {4, 9, 14} | H31 |
| MATH-B-19 | | `pick` ×2 reverse, options are the column pictures: chart [apple 4, banana 5, ball 6], "where are there 5?" → {banana, apple M-CNT-SKIP, ball M-CNT-DOUBLE}; chart [fish 3, star 2, duck 4], "3" → {fish, star M-CNT-SKIP, duck M-CNT-DOUBLE} | H32 |

**Totals (a, b).**
- **211 new activities:** 197 are understanding checks, 14 are there only for a second representation (NUM-A-03 2, NUM-A-04 2, COL-A-02 2, COL-A-03 2, LOG-A-01 2, MATH-B-01 2, MATH-B-03 2). By land: Numbers 62, Colours and Robots 41, Logic 36, Shapes 28, Maths 44.
- **Relabels to a check (no new item): 21** (NUM-B-02 2, NUM-B-13 7, SHP-A-05 1, MATH-A-05 1, MATH-B-14 2, MATH-B-15 8). The check labels that change kind are in §2.
- **A second representation for 22 skills:** all 11 core skills that lack one (by new items), 3 by relabel alone (CS-B-01, MATH-B-13, MATH-B-15) and 8 by a new check in another form (CS-A-04, COL-A-04, COL-B-04, COL-B-06, LOG-B-11, NUM-A-14, NUM-B-16, MATH-A-06).
- After this spec the simulator test should report 0 of 100. The app-developer runs it; any skill it still lists comes back to me.

## 2. Representation labels (part b): the rule G2 applies

| Template / kind | Label | Why |
|---|---|---|
| `count_tap`, `give_n`, `sort_drag`, `build_pattern`, `shape_builder`, `shop_pay`, `clock_set` | concrete | the child moves or touches each object (R1) |
| `balance` mode `balance` / mode `compare` | concrete / pictorial | adding blocks is moving; reading a tilt is a picture |
| `robot_path` mode `direct` / mode `plan` | concrete / symbolic | moving the robot is a manipulative; a program of arrows is a symbol system. **Never `embodied`** |
| `tap_answer` with a group, chart, picture options or picture row | pictorial | nothing can be moved (the 91 "concrete" taps) |
| `tap_answer` with numerals or `n:`/`op:` only | symbolic | |
| `spot_error` with `asset:` cells / with `n:`, `dir:`, `op:` cells | pictorial / symbolic | |
| `number_line`, `match_pairs`, `flash` | pictorial | the line is a diagram (R2) |
| `trace` | embodied | the finger draws the stroke (the one bodily form the app has) |

**Exceptions:** items authored as `story` keep `story` (CS-A-01, LOG-A-08, MATH-A-05, NUM-A-14); MATH-B-14's day cards are symbols, so they stay `symbolic`. **Skill declarations:** NUM-A-01 and 02 declare `embodied, story` but are taught `symbolic` (+ `concrete` after §1); G2 writes what is taught. **Count (measured with this rule on today's pack): 175 activity labels change** (85 tap concrete→pictorial, 6 tap concrete→symbolic, 17 tap symbolic→pictorial, 20 robot, 6 robot spots, 19 number line, 14 balance, 8 clock_set). **Check labels:** 32 `spot_error` reverse→error_spotting; `give_n` of NUM-A-06 (7), NUM-B-05 (8) and MATH-A-06 (6) reverse→practice; the 21 relabels to a check of §1. **74 check labels** in all.

## 3. Tagged wrong answers (part c): rules per skill

Rule of §5.3: every item with 3+ options has two distractors with **distinct** tags. Measured today: **193** items with 3+ options have no tag at all (the audit counted 181 on pack 0.8.0; the extra are count_tap and flash), 249 have one. This section fixes the 193; the tag line (`vo:fb.*`) of each tag is the existing one.

| Skill (untagged items) | Options rule → tags | Class |
|---|---|---|
| MATH-A-01 (6) | {r, first group x **M-CNT-CARD** (§5.3's own example: the first addend), r+1 **M-CNT-DOUBLE**} | R |
| MATH-A-02 (6) | {r, the start x M-CNT-CARD (nothing taken), r−1 M-CNT-SKIP} | R |
| MATH-B-01 (12) | join as MATH-A-01; take {r, x M-CNT-CARD, the part taken y **M-PART-MISS**}; if y = r use r+1 M-CNT-DOUBLE | R |
| MATH-B-03 (8), MATH-B-08 (12) | add {r, larger addend M-CNT-CARD, r−1 M-CNT-DOUBLE (counting on that counts the start: 3, 4, 5, 6)}; subtract {r, x M-CNT-CARD, r+1 M-CNT-DOUBLE (counting back that counts the start)}. The generator's x+y ("added instead", e.g. 13 for 9−4) is dropped until a tag exists (§6) | R |
| MATH-B-06 (8) | {10−n, 10 **M-PART-MISS** (answers with the whole; fb.part_miss fits these stories), n **M-CNT-CARD** (answers with the number already there)}; for n = 5 use 6 M-CNT-DOUBLE instead of n. These are stories with no "=", so not M-EQ-OPER | R |
| MATH-B-07 (6) | n−n: {0, 1 M-NUM-ZERO (refuses 0), n M-CNT-CARD}; n±0 and 0+n: **{n, 0 M-NUM-ZERO, n±1 M-NUM-ZERO}** (the board's "offer 0 on 5+0"); 0+0: {0, 1, 2} both M-NUM-ZERO | R for 2, E1 for 4 |
| MATH-B-19 (6) | totals {r, r−1 M-CNT-SKIP, r+1 M-CNT-DOUBLE}; most/least: the column drawn with bigger pictures M-CNT-SIZE, the other M-CNT-SIZE | R 2, E1 4 |
| NUM-A-05, NUM-A-10 (12) | {n, n−1 M-CNT-SKIP, n+1 M-CNT-DOUBLE} | R |
| NUM-A-14 nonzero (2) | {n, 0 M-NUM-ZERO (over-uses zero), n+1 M-CNT-DOUBLE} | R |
| NUM-A-02 `next.after.9` (1) | {10, 9 M-CNT-SEQ, 8 M-CNT-SEQ} (the skill's own pattern) | E1 |
| NUM-B-08 `b.numb08.10` (1) | {11, 1 M-NUM-TEEN (hears "אַחַת" first), 12 M-CNT-SEQ} | R |
| NUM-B-16 `b.numb16.1` (1) | see §4 | R |
| COL-A-01 (6) | {same colour other thing, same thing other colour **M-SORT-SHIFT** (the line fb.sort_shift says exactly this), neighbour hue **M-COL-NAME**} | R |
| COL-A-02 (4), COL-A-03 (1), COL-A-06 transfer | {target, same colour other thing **M-COL-ONEATTR**, same thing neighbour hue **M-COL-NAME**} (neighbours: red–orange–pink, blue–purple, green–blue, black–brown–grey, white–grey) | R |
| COL-A-05 (5) | find items {green apple, same colour other thing M-COL-ONEATTR, the "usual" colour on another thing M-COL-OBJECT}; "what colour is it" items {r, two neighbour hues M-COL-NAME} | R 3, E1 2 |
| COL-B-02 (11) | middle {X_2, X_1 M-SER-ENDS, X_3 M-SER-ENDS}; darkest/lightest {end, X_2 M-SER-ENDS, the other end M-COL-SHADE} (fit: weak) | E1 |
| LOG-A-01 (6) | {same thing, same colour other thing M-COL-ONEATTR, same kind other thing (duck for bird) M-COL-ONEATTR} | E1 |
| LOG-A-10 (2) | {r, the last shown repeated M-PAT-NEXT, the far end M-SER-ENDS} | R |
| LOG-B-01 (3) | {r, the last shown repeated M-PAT-NEXT, the element of the wrong place in the core M-PAT-UNIT} | R |
| SHP-A-01 (6) | {match, same colour other shape M-COL-ONEATTR, near-miss: rect for square M-SHP-SQRECT, `shape_open` for triangle and `shape_curved` for circle M-SHP-CLOSED} | R |
| MATH-B-14 (11) | {r, the day named M-CNT-SEQ, day ± 2 M-CNT-SEQ} | E1 |
| SHP-A-02 (6) | one near-miss as SHP-A-01 (M-SHP-SQRECT / M-SHP-CLOSED) + one other basic shape, untagged | E2 |
| NUM-A-08 (7) | 2 and 5: the mirror numeral M-NUM-REV + a neighbour, untagged; 1, 3, 4: no tag fits | E2 |
| MATH-B-10 (6) | {g×k, k (one plate) M-CNT-CARD, g+k untagged}; the right tag for g+k is M-MUL-ADD (§5.2, Band C, not in the pack) | E2 |
| CS-A-05 (6), LOG-A-09 (6), LOG-B-06 (6), MATH-A-05 (6), SHP-A-05 (6), SHP-B-08 (8) | no catalogue tag fits a wrong answer here; left untagged until the owner decides (§6) | E2 |

**Counts:** R = 94 items meet the rule; E1 = 42 items get two tagged distractors with the same tag (the skill's watch list has one misconception); E2 = 57 items stay below the rule (14 of them get one tag). **Newly tagged: 150 of the 193.** The new check items of §1 follow the same rules.

## 4. The B-27 items (part d)

**NUM-B-16 (`b.numb16.1` to `.9`, teens as ten and ones).**
- **Picture:** items 1, 3, 5, 7 and 9 (11, 13, 15, 17, 19): `group {count 10, arrangement ten_frame}` + `group2 {count k, ten_frame}`, rep pictorial. Items 2, 4, 6 and 8 (12, 14, 16, 18): no group, `row [n:1k, op:=, n:10, op:+, ?]`, rep symbolic. This gives the skill two representations now. **Both together** (two frames *and* the numeral on one stage) need a layout change in `tap_answer`, where the stage numeral and the row are drawn over the groups today (hand-off H-A below).
- **Options:** {k, 10+k **M-NUM-TEEN** (does not take the ten apart, line fb.num_teen), 1 **M-NUM-REV** (takes the tens digit for the ones, line fb.num_rev)}. For 11: {1, 11 M-NUM-TEEN, 10 M-PART-MISS (answers with the ten)}. The tag no longer sits on the option that is right in item 1.
- **Hint 2** changes the representation: pictorial items `highlight_objects_sequentially` on the second frame only, caption H33a; symbolic items `show_fingers` (ten, then k), caption H33b. Both draw nothing until `tap_answer` renders hint actions (audit F12, hand-off H-B).
- **Check:** `pick` ×2 reverse, frames 10 + 4 → {14, 41 M-NUM-REV, 10 M-PART-MISS}; 10 + 7 → {17, 71, 10}; H34. `voiceAnswer` stays false.

**MATH-B-07:** §3 (0 on n+0, tagged M-NUM-ZERO) and §1 (reverse check). **MATH-B-06:** §3 and §1.

**MATH-B-18 (D3):** every item {k, the total **M-EQ-OPER** (kept), a + total **M-PART-MISS**}, e.g. 3 + ? = 7 → {4, 7, 10}; the untagged n±1 goes. Its feedback for M-PART-MISS is H30 (G4), because the shared line fb.part_miss speaks of things "we saw" and fits only the stories. Hint 3 stays as the B-2 view proposes (needs F12).

## 5. New Hebrew (part e): English gloss + draft, all `"review": "needs-editor"`

Reused without change wherever the tables say "pattern" or name an existing line. **35 new patterns, 71 new strings** (a pattern with two values counts as two strings). No string has right/left words; the Band A ones (H1, H2, H6, H7, H11 to H17, H19 to H23, H35) have no "לֹא" question and no speed words.

| Id | Gloss | Draft |
|---|---|---|
| H1a, b | There were 3 birds in the nest and all flew away. How many are left? (fish: swam away) | הָיוּ שָׁלוֹשׁ צִפֳּרִים בַּקֵּן, וְכֻלָּן עָפוּ. כַּמָּה נִשְׁאֲרוּ? / הָיוּ שְׁנֵי דָּגִים, וְכֻלָּם שָׂחוּ לְהֵרָחֵק. כַּמָּה נִשְׁאֲרוּ? |
| H2 | A friend put the numbers in order and made a mistake. Where is it? | חָבֵר סִדֵּר אֶת הַמִּסְפָּרִים וְטָעָה. אֵיפֹה הַטָּעוּת? |
| H3 | Which number is smaller? | אֵיזֶה מִסְפָּר קָטָן יוֹתֵר? |
| H4 (×4) | There are {2 apples} in the basket and {4} outside. How many in all? | יֵשׁ {שְׁנֵי תַּפּוּחִים} בַּסַּל וְ{אַרְבָּעָה} בַּחוּץ. כַּמָּה יֵשׁ בְּסַךְ הַכֹּל? |
| H6 (×15) | Oops! A friend collected only {red ones}. Where is the mistake? | אוּפְּס! חָבֵר אָסַף רַק {אֲדֻמִּים}. אֵיפֹה הַטָּעוּת? (nouns: אֲדֻמִּים, כְּחֻלִּים, כְּתֻמִּים, שְׁחֹרִים, חוּמִים, אֲפֹרִים, תַּפּוּחִים, בַּרְוָזִים, עִגּוּלִים, רִבּוּעִים, מְשֻׁלָּשִׁים, מַלְבֵּנִים, מְחֻמָּשִׁים, צוּרוֹת סְגוּרוֹת, גְּלִילִים) |
| H7a, b | Is this a banana? / Is this an apple? | זוֹ בָּנָנָה? / זֶה תַּפּוּחַ? |
| H8a, b | Red and which colour make orange? (blue … green) | אָדֹם וְאֵיזֶה צֶבַע עוֹשִׂים כָּתֹם? / כָּחֹל וְאֵיזֶה צֶבַע עוֹשִׂים יָרֹק? |
| H9a, b | A friend sorted by colour (shape), and one is in the wrong place. Where is the mistake? | חָבֵר מִיֵּן לְפִי צֶבַע, וְאֶחָד לֹא בַּמָּקוֹם. אֵיפֹה הַטָּעוּת? / …לְפִי צוּרָה… |
| H10 | A friend built a rainbow, and one colour is in the wrong place. Where? | חָבֵר בָּנָה קֶשֶׁת, וְצֶבַע אֶחָד לֹא בַּמָּקוֹם. אֵיפֹה הַטָּעוּת? |
| H11a, b | We brush our teeth. What do we do right after the paste? / We wash our hands. What do we do right after the soap? | מְצַחְצְחִים שִׁנַּיִם. מָה עוֹשִׂים מִיָּד אַחֲרֵי הַמִּשְׁחָה? / רוֹחֲצִים יָדַיִם. מָה עוֹשִׂים מִיָּד אַחֲרֵי הַסַּבּוֹן? |
| H12 | How many steps to the flag? | כַּמָּה צְעָדִים עַד הַדֶּגֶל? |
| H13a, b | Oops! Is this how we brush teeth (wash hands)? Where is the mistake? | אוּפְּס! כָּכָה מְצַחְצְחִים שִׁנַּיִם? אֵיפֹה הַטָּעוּת? / אוּפְּס! כָּכָה רוֹחֲצִים יָדַיִם? אֵיפֹה הַטָּעוּת? |
| H14 | Put each one with the same thing. | שָׂמִים כָּל אֶחָד עִם אוֹתוֹ הַדָּבָר. |
| H15 | Sort: big ones here, small ones here. | מְמַיְּנִים: גְּדוֹלִים לְכָאן, וּקְטַנִּים לְכָאן. |
| H16 | Oops! The pattern has a mistake. Where is it? | אוּפְּס! יֵשׁ טָעוּת בַּסֵּדֶר. אֵיפֹה הִיא? |
| H17a, b | The chick came out (the flower bloomed). What happened just before? | הָאֶפְרוֹחַ יָצָא. מָה קָרָה רֶגַע לִפְנֵי? / הַפֶּרַח פָּרַח. מָה קָרָה רֶגַע לִפְנֵי? |
| H18 | A friend ordered the towers and made a mistake. Where is it? | חָבֵר סִדֵּר אֶת הַמִּגְדָּלִים וְטָעָה. אֵיפֹה הַטָּעוּת? |
| H19a, b | Build a train (a tree) from shapes. | בּוֹנִים רַכֶּבֶת מִצּוּרוֹת. / בּוֹנִים עֵץ מִצּוּרוֹת. |
| H20 | Which shape has a curved line? | לְאֵיזוֹ צוּרָה יֵשׁ קַו עָקֹם? |
| H21 | Which solid leaves a circle in the sand? | אֵיזֶה גּוּף מַשְׁאִיר עִגּוּל בַּחוֹל? |
| H22a, b | Share {six apples} between the cat, the dog and the duck; all get the same number. | מְחַלְּקִים {שִׁשָּׁה תַּפּוּחִים} בֵּין הֶחָתוּל, הַכֶּלֶב וְהַבַּרְוָז. לְכֻלָּם אוֹתוֹ מִסְפָּר. |
| H23a, b | I have {3} coins. Each apple costs one coin. How many apples can we buy? | יֵשׁ לִי {שְׁלוֹשָׁה} מַטְבְּעוֹת. כָּל תַּפּוּחַ עוֹלֶה מַטְבֵּעַ אֶחָד. כַּמָּה תַּפּוּחִים אֶפְשָׁר לִקְנוֹת? |
| H24 (×2) | There are {3 apples}. More came, and now there are {5}. How many came? | יֵשׁ {שְׁלוֹשָׁה תַּפּוּחִים}. בָּאוּ עוֹד, וְעַכְשָׁו יֵשׁ {חֲמִשָּׁה}. כַּמָּה בָּאוּ? |
| H25 (×2) | How much is {3} and {4}? (= first) | כַּמָּה שָׁוֶה שָׁלוֹשׁ וְעוֹד אַרְבַּע? / כַּמָּה שָׁוֶה תֵּשַׁע פָּחוֹת אַרְבַּע? |
| H26 (×2) | I have {7} shekels. How many more do I need to have ten? | יֵשׁ לִי {שִׁבְעָה} שְׁקָלִים. כַּמָּה עוֹד צָרִיךְ כְּדֵי שֶׁיִּהְיוּ עֲשָׂרָה? |
| H27 (×2) | {Six ducks}, {two} on each plate. How many plates? | {שִׁשָּׁה בַּרְוָזִים}, {שְׁנַיִם} עַל כָּל צַלַּחַת. כַּמָּה צַלָּחוֹת? |
| H28 | Which side will go down? We guess, then we see. | אֵיזֶה צַד יֵרֵד? מְנַחֲשִׁים, וְאָז רוֹאִים. |
| H29 | Which coin is worth more? | אֵיזֶה מַטְבֵּעַ שָׁוֶה יוֹתֵר? |
| H30 | (M-PART-MISS in a number sentence) We added both; but after the "equals" is already the whole. What is missing? | חִבַּרְנוּ אֶת שְׁנֵיהֶם, אֲבָל אַחֲרֵי הַ-שָׁוֶה כְּבָר כָּתוּב הַכֹּל. כַּמָּה חָסֵר? |
| H31 (×2) | {7} equals {3} and how many? | שֶׁבַע שָׁוֶה שָׁלוֹשׁ וְעוֹד כַּמָּה? / תֵּשַׁע שָׁוֶה חָמֵשׁ וְעוֹד כַּמָּה? |
| H32 (×2) | In which column are there {5}? | בְּאֵיזֶה עַמּוּד יֵשׁ {חָמֵשׁ}? |
| H33a | (hint 2, frames) The full frame is ten. Let's count only the other frame. | הַמִּסְגֶּרֶת הַמְּלֵאָה הִיא עֶשֶׂר. נִסְפֹּר רַק אֶת הַמִּסְגֶּרֶת הַשְּׁנִיָּה. |
| H33b | (hint 2, fingers) Ten fingers, and some more. How many more? | עֶשֶׂר אֶצְבָּעוֹת, וְעוֹד קְצָת. כַּמָּה עוֹד? |
| H34 (×2) | Ten and {four}. Which number is it? | עֶשֶׂר וְעוֹד {אַרְבַּע}. אֵיזֶה מִסְפָּר זֶה? |
| H35 (×3) | Where is the {yellow} shape? | אֵיפֹה הַצּוּרָה הַ{צְּהֻבָּה}? (צְּהֻבָּה, יְרֻקָּה, כְּתֻמָּה) |

New items take the correct line and hint 3 of their kind (`k_pick`'s "{r}. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו." and the count words for spots). **Two reused lines carry "לֹא" in Band A** and go to the editor: `k_spot`'s default hint 3 ("אֶחָד מֵהֶם לֹא מַתְאִים…") must not be used for Band A spots, and fb.sort_shift ("…לֹא אוֹתוֹ דָּבָר") now plays in COL-A-01.

## 6. Not in this spec, and the hand-offs

**Deliberately not done** (B-5, waiting for the owner): building NUM-B-06, NUM-B-09 and LOG-B-05; re-specifying NUM-A-01 and 02 (count-along), COL-B-04, LOG-B-02, LOG-B-08 and CS-A-05 (§1 gives them interim checks only); renaming tags; any new tag; MATH-B-04 before MATH-B-18. **Not mine here:** the path and placement rules (the B-26 session, `next_lesson.dart`, `placement.dart`); difficulty by item features (F15); the balance pictures (F8) and solids (F9), apart from H21 avoiding the pyramid.

**Owner decisions needed.**
1. **§5.3 for skills with one misconception (E1, 42 items):** accept two tagged distractors with the **same** tag when the skill's watch list has a single tag (my recommendation), or make those items two-option.
2. **E2 (57 items):** add catalogue tags in B-5 (an "added instead" tag for x+y, e.g. M-OP-SWAP; M-MUL-ADD into the pack for MATH-B-10; tags for pairs, days and times of day), or accept them untagged.
3. **Catalogue mismatch (B-5):** the pack has M-LOG-NOT and M-PART-MISS where §5.2 has M-NOT and M-PPW; M-NUM-WRITE and M-SHP-FACE are in the pack only. This spec uses the pack's names.

**Hand-offs (for the board).**
- **H-A, app-developer:** G1 to G5; then run `flutter test --dart-define=QA_OPEN=true test/mastery_reachable_test.dart` and send me any skill it still lists. Also `tap_answer`: draw the stage numeral or row **under** the groups when both are set (NUM-B-16 two frames + numeral). Band A spots must not use `k_spot`'s default hint 3.
- **H-B, app-developer (audit F12):** `tap_answer` renders hint actions; without it the level-2 hints of §4 change nothing on screen.
- **H-C, design-director:** a ten-frame outline (10 cells, empty ones visible) behind `ten_frame` groups; layouts for the train and the tree (H19); the board shapes 2×4 and 4×2 for CS-A-03.
- **H-D, hebrew-text-editor:** H1 to H35 (71 strings) and the generated strings of the "pattern" rows.
- **H-E, qa-engineer:** remove `skip: _open` from the two tests in `mastery_reachable_test.dart` when they pass; add a lint for §5.3 (3+ options: two tagged distractors, distinct unless the skill has one watch tag) and for §2's label rule.
- **H-F, engine (orchestrator → owner, not needed for this spec):** a check passed on a two-option item counts today; §4.1 says such an item "never counts alone". Proposed: a check counts only from an item with 0 or 3+ options, or after a second two-option check of the same type.

## Addendum after the Hebrew pass

Curriculum-expert, 2026-10-30, after `docs/knowledge/b15-hebrew.md` §5. Each decision below **replaces** the §1 row it names; everything else in §1 to §6 stands. Checked against the generator tables and `content/starter` (767 activities) on this branch.

### A1. CS-A-01 hands (H11b): the answer is the towel

The pack's hand-washing routine has three steps, tap, soap, towel (`cs.routine.wash.*`). `step_rinse` is the **cup of water** of the teeth routine (`כּוֹס מַיִם`), and `cs.wrong.wash3` teaches that it does *not* belong to hand-washing. So "rinse" would have contradicted an existing item. The answer is the step the child learned. Adding a rinse step is a syllabus change, so it is not done here.

| Item | Prompt | Options → r; tags | Correct line | h3 |
|---|---|---|---|---|
| CS-A-01 hands, `pick` reverse, story | H11b as the editor wrote it | {**step_towel**, step_tap M-SEQ-CAUSE (the step before, not after), step_soap M-SEQ-CAUSE (the anchor step itself)}; E1 | pattern of `cs.routine.wash.last`: `כֵּן! אַחֲרֵי הַסַּבּוֹן מְיַבְּשִׁים בְּמַגֶּבֶת.` (editor checks) | `cs.routine.wash.last`'s h3 unchanged (`קֹדֶם בָּרֶז, אַחַר כָּךְ סַבּוֹן, וּבַסּוֹף מַגֶּבֶת. … לִלְחֹץ עַל הַמַּגֶּבֶת.`) |

Teeth (H11a) stays as in §1: {step_brush, step_rinse M-SEQ-CAUSE, step_paste M-SEQ-CAUSE}. All six `step_*` sprites exist (tap, soap, towel, paste, brush, rinse), with names in `robots.json`.

### A2. SHP-B-09 (H21): two two-option items, no sphere

A ball pressed into sand leaves a round dent, and the cone's base is a circle too. Either one would be a second right answer, and the pyramid stays out (F9). So each item has the right solid and the box only, whose print is a square.

| Item | Options → r; tag | Text |
|---|---|---|
| SHP-B-09 `pick` reverse ×**2**, pictorial | (1) {**solid_cylinder**, solid_box M-SHP-FACE}; (2) {**solid_cone**, solid_box M-SHP-FACE} | editor's H21 unchanged for both; h3 = SHP-B-09's existing `מַטְבִּיעִים אֶת הַגּוּף וְרוֹאִים אֶת הַצּוּרָה שֶׁנִּשְׁאֶרֶת. עַכְשָׁו תּוֹרְכֶם.` |

Two items of the same check type, so they still count if the owner adopts H-F (a second two-option check of the same type). In Band B the box is labelled `תֵּבָה` (`NAMES`).

### A3. Rows that duplicate existing items: relabel or new values

Rule: **relabel** when the existing item is already the other *form* that the check needs, for example a reverse question in a skill that otherwise asks forwards. **Change the values** when the existing item is one of the skill's ordinary practice items, because passing a practice item is not transfer.

| Skill | §1 said | Found | Decision |
|---|---|---|---|
| COL-B-01 | add `pick` ×2 reverse (H8) | `b.colb01.7`, `.8`, `.9` ("red and … make orange; what is missing?") are the reverse form | **relabel `b.colb01.7`–`.9` chk reverse**; no new items |
| NUM-B-01 | add "before" ×2 reverse | `b.numb01.6`, `.7`, `.8` ask "what comes before" | **relabel `b.numb01.6`–`.8` chk reverse**; no new items |
| NUM-B-10 | add "which is smaller?" ×2 reverse (H3) | `b.numb10.5`, `.6`, `.7` ask "smaller" | **relabel `b.numb10.5`–`.7` chk reverse**; no new items |
| NUM-B-07 | add `trace` ×2 transfer, `guide: start`, 2 and 5 | `x.numb07.11`–`.20` are already the start-dot form | **relabel `x.numb07.13` (2) and `x.numb07.16` (5) chk transfer**; no new items |
| COL-B-03 | add purple "where else is purple?" ×2 | `b.colb03.7`, `.8` are purple practice; only 4 shade colours exist | `pick` ×2 transfer, **swatch to object** (a new form): group `shade_blue_1`, "אֵיפֹה עוֹד כָּחֹל?" → {**ball_blue**, ball_white M-COL-SHADE (light taken for white), ball_purple M-COL-NAME}; group `shade_red_3`, "אֵיפֹה עוֹד אָדֹם?" → {**ball_red**, ball_black M-COL-SHADE (dark taken for black: the catalogue's signal), ball_orange M-COL-NAME} |
| COL-B-02 | add purple darkest/lightest ×2 | `b.colb02.7`, `.8` are exactly that | `pick` ×**1** transfer, the purple **middle** (asked only for blue, green and red): {**shade_purple_2**, shade_purple_1 M-SER-ENDS, shade_purple_3 M-SER-ENDS}; existing "middle" prompt. Near transfer only (fit: weak) |
| LOG-B-09 | "not yellow and not square"; "not green and not circle" | the second is `b.logb09.6` | keep the first: {**shape_circle_green**, shape_square_green M-LOG-NOT, shape_circle_yellow M-LOG-NOT}; replace the second with "not orange and not triangle": {**shape_square_red**, shape_triangle_red M-LOG-NOT, shape_square_orange M-LOG-NOT}. Existing prompt pattern |
| SHP-A-06 | train and tree | `shp.build.train`, `shp.build.tree` exist | `shapebuild` ×2 transfer: **boat** and **car**, using the editor's ready lines `בּוֹנִים סִירָה מִצּוּרוֹת.` and `בּוֹנִים מְכוֹנִית מִצּוּרוֹת.` (call them H19c, H19d). The design-director draws the layouts, which replace train and tree in H-C |
| LOG-B-08 | the rule on shape: circle, triangle | `b.logb08.3` (circle) and `.4` (square) exist | `sort` ×2 transfer on shapes it has not used: **triangle** and **rectangle** (`אִם הַצּוּרָה מְשֻׁלָּשׁ…`, `אִם הַצּוּרָה מַלְבֵּן…`, existing pattern) |
| COL-A-01 | target `ball_blue` | `col.match.blue` already has it (balls and blooms are its targets) | target **`banana_yellow`** → {**bloom_yellow**, banana_green M-SORT-SHIFT, ball_orange M-COL-NAME}; `balloon_yellow` as §1 but {**ball_yellow**, balloon_green M-SORT-SHIFT, bloom_orange M-COL-NAME} |
| SHP-A-04 | rect vs square, orange and yellow | orange is in `shp.square.orange` | **yellow and red**: rect_yellow vs square_yellow, rect_red vs square_red; square M-SHP-SQRECT |
| CS-A-03 | boards 2×4 and 4×2 | 4×2 is `cs.robot.direct.4` | boards **2×4** (robot col 0 row 3, flag col 1 row 0) and **3×4** (robot col 2 row 3, flag col 0 row 0). Existing boards have at most 3 rows |
| NUM-B-04 | 14 ducks, 17 butterflies | ducks are `b.numb04.4` | **14 cats**, 17 butterflies |
| NUM-A-04 | count_tap 4 ducks, 3 stars | both are in its practice (`count.ducks.5`, `count.stars.4`) | **4 birds, 3 ladybugs** (`_lit` exists) |

Checked and not duplicates: NUM-A-03, 06, 09, 11 to 14; NUM-B-08, 13 (only labels [0, 10] is new: its sparse items use [0, 5, 10, 15, 20]), 18; LOG-A-01 to 10; LOG-B-01, 04; SHP-A-01, 07, 10; COL-A-04, 05, 07; MATH-A-04; MATH-B-16, 17 (price 7 exists, but with a different purse).

**New totals (replace §1's).**
- **203 new activities** (was 211): 189 checks and 14 second representations. By land: Numbers 56, Colours and Robots 38, Logic 36, Shapes 29, Maths 44.
- **32 relabels to a check** (was 21): §1's 21 plus COL-B-01 3, NUM-B-01 3, NUM-B-10 3 and NUM-B-07 2.
- §2's check-label total becomes **85** (was 74).

### A4. Compare and size rows (X1): masculine nouns, one noun per item

`k_compare_more` draws both sets with one `obj`, so §1's "unlike objects" would have needed a generator change, and frogs as the tagged set would have needed three feminine clips. Instead, each item uses **one new masculine noun** (chick, butterfly). The M-CNT-SIZE set is masculine, the shared D1 lines (`הֵם גְּדוֹלִים / קְטַנִּים / רְחוֹקִים זֶה מִזֶּה`) fit, and the prompt is the existing `אֵיפֹה יֵשׁ יוֹתֵר/פָּחוֹת {many}?`. The transfer is the new objects (curriculum NUM-A-12: "U3 transfer (new objects)").

| Skill | Item (`compare_more`, chk transfer, pictorial) | Trap → cue |
|---|---|---|
| NUM-A-11 | obj chick, ask more, options [4, 3], `arr {"3": "scatter"}` | 3 spread → spread |
| NUM-A-11 | obj butterfly, ask more, options [3, 5], `arr {"3": "scatter"}` | 3 spread → spread |
| NUM-A-12 | obj chick, ask more, options [3, 5], `scale {"3": 1.5}` | 3 big → big |
| NUM-A-12 | obj butterfly, ask fewer, options [5, 4], `scale {"5": 0.7}` | 5 small → small |
| MATH-A-07 | obj chick, ask more, options [2, 4], `scale {"2": 1.5}` | 2 big → big |
| MATH-A-07 | obj butterfly, ask fewer, options [5, 3], `scale {"5": 0.7}` | 5 small → small |

All have `trap: true` (tag M-CNT-SIZE). MATH-A-07's existing items keep `trap: false`. **X1a, X1b and X1c are not needed** (no two-noun prompt, no feminine size line). No other §1 row puts frogs on an M-CNT-SIZE set; frogs stay in flash, madd and mtake, and the ordinal queue, which have no size tag. **Rule from now on:** any option tagged M-CNT-SIZE that plays a cue line is a masculine set; MATH-B-19's tagged "bigger pictures" column (§3) is never the bananas.

### A5. fb.sort_shift: the line follows the item's sorting rule

| Band | Rule of the item | Line |
|---|---|---|
| A (COL-A-01 new, COL-A-04, LOG-A-01 spots, LOG-A-03, SHP-A-02 spots) | any | **today's** `vo:fb.sort_shift`, until the owner decides P2 to P4 |
| B (COL-B-04, LOG-B-06 spots H9a, LOG-B-08 `.1`, `.2`) | colour | today's `vo:fb.sort_shift` (it is true for a colour rule, and `לֹא` is allowed in Band B) |
| B (COL-B-04, LOG-B-06 spots H9b, LOG-B-08 `.3`, `.4` and the new triangle and rectangle) | shape | P4's text as `vo:fb.sort_shift.shape` |
| B | kind | P3's text as `vo:fb.sort_shift.kind` (no Band B kind item today; the generator supports it) |

Each item carries `rule: colour | shape | kind`, and the generator picks the line from it. **P1 stays out:** Band A spots keep today's `k_spot` h3 wherever §1 and the editor's X4 and X5 do not give one. This follows the brief. Note that this still breaks the rule in §5 and H-A, which says Band A spots must not use that line.

### A6. Nouns and names the new items need

The table entries copy existing rows. Only the four `OBJECTS` nouns are new; the editor already gave their forms in b15-hebrew §2.

| Sprite | g | one / many | Add to | Used by |
|---|---|---|---|---|
| chick | m | אֶפְרוֹחַ / אֶפְרוֹחִים | `objects` of `counting-hills.json` and `math.json` (band_b `OBJECTS` inherits them) | NUM-A-05, 10, 11, 12, 13; MATH-A-01, 02, 07; LOG-B-01 |
| butterfly | m | פַּרְפָּר / פַּרְפָּרִים | same | NUM-A-03, 09, 11, 12; MATH-A-07; NUM-B-04 |
| frog | f | צְפַרְדֵּעַ / צְפַרְדְּעִים | same | NUM-A-05, 10, 13; MATH-A-01, 02 |
| shoe | f | נַעַל / נַעֲלַיִם | band_b `OBJECTS` (as `sock`) | NUM-B-18 |

| Unit `names` | Add (copied from) |
|---|---|
| `logic.json` | apple_green, ball_red, ball_blue, ball_yellow, balloon_red, balloon_blue (colours' thing+colour rule); plate with `def` `הַצַּלַּחַת` (shapes.json); tower_1 to tower_6 (band_b `NAMES`) |
| `shapes.json` | solid_sphere `כַּדּוּר` m, shape_open, shape_curved (band_b `NAMES`) |
| `colours.json` | shape_circle_* and shape_square_* (shapes.json) |
| `math.json` | fish_size_l/s, star_size_l/s (logic.json) |
| band_b `NAMES` | key, balloon_red, balloon_blue (logic and colours); coin_h50, coin_s1, coin_s5, coin_s10 for MATH-B-16: the `COIN_OF` forms, plus a new `מַטְבֵּעַ שֶׁל חֲצִי שֶׁקֶל` (needs-editor) |

**`solid_box`:** Band A `shapes.json` already names it `קֻפְסָה` (Q7), and SHP-A-07's new items are built from it. Band B `NAMES` says `תֵּבָה` and is used only for Band B (SHP-B-08, 09). The generator must never merge band_b `NAMES` into a Band A unit.
