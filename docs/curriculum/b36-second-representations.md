# B-36 part D: a second way of showing each of the 75 one-way skills (spec)

Curriculum-expert (Knowledge Agent), 2026-11-01, worktree `D:\nitznutz-next`, branch `next-pack`. Plan: `docs/milestones/B36.md`
(approved by the owner on 2026-11-01: decision 1, about 2 items for each of the 75 skills, Band A first; decision 2, LOG-A-01
as LOG-A-09's prerequisite, which is part E). The style follows `docs/knowledge/b15-content-spec.md`. **Existing templates
only. No syllabus change.** Measured on `content/starter` of this branch: 100 skills, 968 activities; `graph.report()` lists
75 skills "in only one representation" (48 pictorial, 12 symbolic, 10 concrete, 4 story, 1 embodied; Band A 37, Band B 38)
and LOG-A-09 "not connected".

## 0. How to read this

- **One row per new item: 150 items**, 2 for every skill. Band A first (section 2), then Band B (section 3).
- **Ids are appended, never renumbered.** Band A: `b36.<skill>.<n>` (as `b15.<skill>.<n>` in B-15). Band B: the skill's own
  prefix and the next free number (`b.colb01.10`, `x.mathb16.9`), as B-38 did with `b.shpb08.10`. If another part of B-36
  appends to the same skill first, the build takes the next free number; the order of this spec stays.
- **Adds** is the representation label the item gets from the rule of B-15 §2 (`tools/author.py` `representation()`):
  concrete (the child moves or touches: sort, build, give, count, balance-fill, shop, robot moved), pictorial (a picture to
  read: tap with pictures, spot with pictures, number line), symbolic (numerals, signs or arrows only), embodied (trace),
  story (an authored tale; allowed only for listed skills, section 1 G7). Every row adds a label the skill does not have yet.
- **Prompt intent** is plain English. The hebrew-text-editor writes the words (all `"review": "needs-editor"`). "Pattern" means
  an existing prompt pattern with new values.
- **r** = the right answer. **Tags** use the pack's names and the 8 tags of decision 3 (M-MUL-ADD, M-OP-SWAP, M-TIME-SEQ,
  M-NUM-NAME, M-SHP-NAME, M-RULE-ONE, M-SEQ-SCRIPT, M-ASSOC-LOOK), which part C builds; an item that uses one of them is
  built after part C. In a drag or build template there are no options: the one tag of the answer covers every misplacement,
  and the setup says what the child does and what "right" is.
- **E1** marks two wrong answers with the same tag in a skill that watches one misconception (decision 4).
- **Check** is `checkType`. None of the 75 skills is core (no skill of the list is a prerequisite of 3 or more), so fresh
  mastery needs 1 representation and 1 check; the new items cannot block mastery (section 8).
- **Lesson** follows the B-15 rule: the item joins the last lesson (by `sequence`) that has its skill. A Band A lesson that would
  pass 8 items, and (new here, my call as owner of session composition) a Band B lesson that would pass 12, continues in a
  lesson of its own, `<lesson>-1-b36`, with the same title and celebration line, placed right after it on the path.
- **B-40 hints**: for `tap_answer` the picture family of the skill (TA-1 count ... TA-12 clock and money, plan §5.1); for the
  other templates the template's ladder (`app/lib/content/hint_ladder.dart`): give (goal card, hands, demo), count (light each,
  hands, demo), sort (each place, next picture with its sample, demo), share (each place, first round, demo), build (walk the
  row, model cell, demo), balance (each pan, cube towers, demo), number line (start and landmarks, first hop, demo), robot
  (robot and goal, first arrow or first leg, demo), shop (price and counter, first coin, demo), trace (first stroke, whole
  stroke, demo), spot (walk the row, the spot family's other way, demo). "(new entry)" means the skill is not yet in the
  family table and must be added (G5).

## 1. What the build needs first (app-developer, unless named)

| # | Change | For |
|---|---|---|
| G1 | `build` takes a `tag` (today `k_build` hard-codes M-PAT-COPY) | NUM-A-13, LOG-A-04, LOG-A-06, LOG-A-08, LOG-A-10, CS-A-01, MATH-A-05, COL-B-02, LOG-B-01, LOG-B-02, LOG-B-04, MATH-B-14 |
| G2 | `count_tap` takes the item's own `tags` per option value (as `pick` and `numeral_to_set` do) | MATH-A-01, MATH-A-02 (the first group, or the start, is M-CNT-CARD, with part B's join and take-away lines) |
| G3 | `pay` takes a `misconception` (the answer's general tag) besides `countMisconception` | MATH-B-16 |
| G4 | `numeral_to_set` takes its own `prompt` (`qty(0)` gives "אֵין אַף…" inside "אֵיפֹה יֵשׁ…", which is not Hebrew), and a `pick` set option takes an arrangement (`fish*13` drawn as two ten-frames, not a line) | NUM-A-14, NUM-B-05, NUM-B-08 |
| G5 | Family tables. `tap_answer` (`hint_ladder.dart` `_tapFamilyOfSkill` and `tools/hint_lines.py` `FAMILY`): NUM-A-06 count, NUM-A-09 count, MATH-A-03 compare, SHP-A-06 shapes, LOG-A-05 pattern, NUM-B-04 count, NUM-B-05 numerals, NUM-B-07 numerals, MATH-B-17 clockMoney; NUM-A-14 with a numeral on the stage goes to numerals, as NUM-A-07 does (`tapFamilyOf`). `spot_error` (`spot_plans.dart`): NUM-B-13 numbers, LOG-B-08 sort | all new tap and spot items of those skills |
| G6 | An empty set is drawn as an empty ten-frame (or an empty plate), on a tile and on the stage, so "zero" is something to see, not a blank tile (with the design-director, D6) | NUM-A-14, MATH-B-07 |
| G7 | `content_lints_test.dart` `_storySkills` gains NUM-A-12, LOG-A-07 and COL-B-01 (their new items are authored stories, section 4); qa-engineer | 6 items |
| G8 | Band A balance, Band A builds without a model, and Band A robot plans need Band A hint lines (no right or left, no "לֹא" question); hebrew-text-editor, via `hint_lines.py` | NUM-A-11, NUM-A-13, LOG-A-08, LOG-A-10, CS-A-01, MATH-A-05 |
| G9 | A build with no model: the hint-2 and demo pictures take the next piece from the palette in the order of `sequence` (the app already falls back to the palette); the places of an order-in-time build show 1, 2, 3 (plan B-40 §12.1); design-director checks | the builds of G1 without a model |

Nothing here changes the engine, the path rule or placement. A build whose model is shorter than its places continues the
repeating unit (`build_pattern_session.dart`), which is right for repeating patterns only; so the growing pattern (LOG-B-04)
is built **without** a model, never with a short one (the demo would repeat the unit and act out M-PAT-GROW).

## 2. Band A (37 skills, 74 items)

### 2.1 Numbers (9 skills, 18 items)

| Skill | New id | Template (kind) | Adds | Prompt intent | Options or setup (r = right) | Wrong answers: tag | Check | Lesson | B-40 hints | New picture / note |
|---|---|---|---|---|---|---|---|---|---|---|
| NUM-A-05 | b36.numa05.1 | give_n (give) | concrete | Put two fish in the bowl (pattern "give me N") | pile of 4 fish, target `bowl_empty`; r = exactly 2 in the bowl | took all: M-CNT-CARD | transfer | more-glances-1-b36 (new) | give: goal card (2 dots in a dice pattern), hands, demo | weights {NUM-A-05: 1, NUM-A-06: 0.5}. "Maker of small collections" (Clements & Sarama) |
| NUM-A-05 | b36.numa05.2 | give_n (give) | concrete | Put three birds in the nest | pile of 5 birds, target `nest_empty`; r = 3 | took all: M-CNT-CARD | practice | more-glances-1-b36 | give | as above |
| NUM-A-10 | b36.numa10.1 | give_n (give) | concrete | Put four apples in the basket | pile of 7, `basket_target`; r = 4 | took all: M-CNT-CARD | transfer | more-glances-1-b36 | give: L2 two hands (4, then 5 as a full hand: the finger pattern of the skill) | weights {NUM-A-10: 1, NUM-A-06: 0.5} |
| NUM-A-10 | b36.numa10.2 | give_n (give) | concrete | Put five ladybugs in the basket | pile of 8, `basket_target`; r = 5 | took all: M-CNT-CARD | practice | more-glances-1-b36 | give | as above |
| NUM-A-06 | b36.numa06.1 | tap_answer (pick) | pictorial | Here are seven fish. The cat asked for three. Which plate is right? | stage `group` fish ×7 (scatter); options sets fish ×3 (r), ×7, ×4 | 7: M-CNT-CARD (the whole pile); 4: M-CNT-DOUBLE | reverse | more-giving | TA-1 count (new entry) | the pile on the stage makes "took them all" visible, so the M-CNT-CARD line is true |
| NUM-A-06 | b36.numa06.2 | tap_answer (pick) | pictorial | Here are six birds. The duck asked for two. Which plate is right? | `group` bird ×6; sets bird ×2 (r), ×6, ×3 | 6: M-CNT-CARD; 3: M-CNT-DOUBLE | transfer | more-giving | TA-1 count | |
| NUM-A-07 | b36.numa07.1 | count_tap | concrete | Touch each one once and count (pattern); then "how many cats?" with numeral tiles | 4 cats (`cat_lit`), scatter; tiles 3, 4 (r), 5 | 3: M-CNT-SKIP; 5: M-CNT-DOUBLE | practice | match-numbers-sets-more | count: light each, hands, demo | `also` NUM-A-04. The set is counted by touch, then matched to its numeral |
| NUM-A-07 | b36.numa07.2 | count_tap | concrete | as above, butterflies | 5 butterflies; tiles 4, 5 (r), 6 | 4: M-CNT-SKIP; 6: M-CNT-DOUBLE | transfer | match-numbers-sets-more | count | |
| NUM-A-09 | b36.numa09.1 | tap_answer (set_to_numeral) | pictorial | How many chicks? Choose the number (pattern) | 8 chicks, scatter; numerals 7, 8 (r), 9 | 7: M-CNT-SKIP; 9: M-CNT-DOUBLE | practice | count-more-things | TA-1 count (new entry): L1 light each, L2 two hands (5 and 3) | counting without touching: harder (section 8) |
| NUM-A-09 | b36.numa09.2 | tap_answer (set_to_numeral) | pictorial | How many ducks? Choose the number | 9 ducks as a ten-frame; numerals 8, 9 (r), 10 | 8: M-CNT-SKIP; 10: M-CNT-DOUBLE | transfer | count-more-things | TA-1 count | the ten-frame shows 5 and 4 |
| NUM-A-11 | b36.numa11.1 | balance (scale, mode balance) | concrete | Put blocks until both sides are the same | left pan `block` ×3 (weight 1), right pan empty; r = 3 blocks added, the beam level | any wrong count: M-CNT-SIZE | practice | more-comparing-1-b15 | balance: each pan, cube towers (the two towers side by side = matching), demo | first balance in Band A (G8; section 8). No side word in the prompt |
| NUM-A-11 | b36.numa11.2 | balance (scale, mode balance) | concrete | as above | left `block` ×5; r = 5 | M-CNT-SIZE | transfer | more-comparing-1-b15 | balance | |
| NUM-A-12 | b36.numa12.1 | tap_answer (pick), `rep: story` | story | Three big frogs and five little chicks. The frog says: "We are more!" Is the frog right? | `group` frog ×3 at scale 1.5, `group2` chick ×5 at scale 0.7; tick, cross (r) | tick: M-CNT-SIZE (cue big) | error_spotting | more-comparing-1-b15 | TA-4 compare: L1 baseline (equal spacing), L2 pair lines, demo | authored story (section 4): a character's claim the child judges, the "oops" form of U5 |
| NUM-A-12 | b36.numa12.2 | tap_answer (pick), `rep: story` | story | The chicks stand close together, the frogs far apart. The chick says: "The frogs have more!" Is the chick right? | `group` chick ×5 in a tight line, `group2` frog ×4 scattered wide; tick, cross (r) | tick: M-CNT-SIZE (cue spread) | error_spotting | more-comparing-1-b15 | TA-4 compare | |
| NUM-A-13 | b36.numa13.1 | build_pattern (build, no model) | concrete | We build a line of chicks. The frog is second | 3 places, palette chick, frog; r = chick, frog, chick | M-ORD-CARD (G1; two frogs for "second" is the catalogue's signal) | practice | more-queues-and-zero-1-b36 (new) | build: walk the places from the first (left), next place, demo | own h3 (first, second, third, said with the hand) |
| NUM-A-13 | b36.numa13.2 | build_pattern (build, no model) | concrete | We build a line of ducks. The cat is third | 4 places, palette duck, cat; r = duck, duck, cat, duck | M-ORD-CARD | transfer | more-queues-and-zero-1-b36 | build | own h3 |
| NUM-A-14 | b36.numa14.1 | tap_answer (numeral_to_set, own prompt G4) | pictorial | Where are there zero fish? | stage numeral 0; sets fish ×1, ×0 (r), ×2, each as a ten-frame | 1: M-NUM-ZERO; 2: M-NUM-ZERO (E1) | reverse | more-queues-and-zero-1-b36 | TA-2 numerals (G5): L2 the numeral's dots beside it (none) | the empty set is an empty frame (G6, D6) |
| NUM-A-14 | b36.numa14.2 | tap_answer (numeral_to_set, own prompt) | pictorial | Where are there zero apples? | numeral 0; sets apple ×0 (r), ×3, ×1 | 3: M-NUM-ZERO; 1: M-NUM-ZERO (E1) | transfer | more-queues-and-zero-1-b36 | TA-2 numerals | |

### 2.2 Colours (4 skills, 8 items)

| Skill | New id | Template (kind) | Adds | Prompt intent | Options or setup (r = right) | Wrong answers: tag | Check | Lesson | B-40 hints | New picture / note |
|---|---|---|---|---|---|---|---|---|---|---|
| COL-A-01 | b36.cola01.1 | sort_drag (sort, rule colour) | concrete | Put each one with the ball of the same colour (no colour named: matching comes before naming) | bins `ball_red`, `ball_blue`; items balloon_red, bloom_blue, bloom_red, balloon_blue; r = red ones to the red ball | M-SORT-SHIFT (colour line: "the same colour, not the same thing") | practice | colours-again-2-b15 | sort: each bin, the next picture with a swatch beside each bin (P9), demo | |
| COL-A-01 | b36.cola01.2 | sort_drag (sort, rule colour) | concrete | as above, flowers as the samples | bins `bloom_yellow`, `bloom_green`; items ball_yellow, balloon_green, ball_green, balloon_yellow, banana_yellow | M-SORT-SHIFT | transfer | colours-again-2-b15 | sort | |
| COL-A-05 | b36.cola05.1 | sort_drag (sort, rule kind) | concrete | Bananas here, apples here | bins `banana_yellow`, `apple`; items banana_green, apple_green, banana_yellow, apple | M-COL-OBJECT ("things can be in several colours"; true whatever the bin) | practice | colours-of-things-again | sort | the green banana must join the yellow one |
| COL-A-05 | b36.cola05.2 | sort_drag (sort, rule kind) | concrete | as above, the green ones are the samples | bins `banana_green`, `apple_green`; items banana_yellow, apple, apple_green, banana_green | M-COL-OBJECT | transfer | colours-of-things-again | sort | |
| COL-A-06 | b36.cola06.1 | sort_drag (sort, rule colour) | concrete | Brown ones with the brown ball, grey ones with the grey ball | bins `ball_brown`, `ball_grey`; items balloon_brown, bloom_grey, bloom_brown, balloon_grey | M-COL-NAME ("the colours look alike; look again") | practice | colours-again-2-b15 | sort | |
| COL-A-06 | b36.cola06.2 | sort_drag (sort, rule colour) | concrete | Brown, grey and black, each to its ball | bins `ball_brown`, `ball_grey`, `ball_black`; items balloon_black, bloom_brown, balloon_grey, bloom_black, balloon_brown, bloom_grey | M-COL-NAME | transfer | colours-again-2-b15 | sort | the near hues of COL-A-06 |
| COL-A-07 | b36.cola07.1 | sort_drag (sort) | concrete | Put each one with the one that is just the same: the same thing and the same colour | bins `ball_red`, `balloon_red`, `ball_blue`; items ball_red, balloon_red, ball_blue, balloon_red, ball_red, ball_blue | M-COL-ONEATTR ("two things to check: what it is, and which colour") | practice | colour-sorting-again-1-b15 | sort: L2 the noun first, then the colour (plan §6) | a red balloon to the red ball, or a blue ball to the red ball, is the one-attribute error |
| COL-A-07 | b36.cola07.2 | sort_drag (sort) | concrete | as above | bins `bloom_yellow`, `balloon_yellow`, `bloom_green`; items bloom_yellow, balloon_yellow, bloom_green, balloon_yellow, bloom_yellow, bloom_green | M-COL-ONEATTR | transfer | colour-sorting-again-1-b15 | sort | |

### 2.3 Shapes (7 skills, 14 items)

| Skill | New id | Template (kind) | Adds | Prompt intent | Options or setup (r = right) | Wrong answers: tag | Check | Lesson | B-40 hints | New picture / note |
|---|---|---|---|---|---|---|---|---|---|---|
| SHP-A-01 | b36.shpa01.1 | sort_drag (sort, rule shape) | concrete | Put each shape with the same shape | bins `shape_circle` (red), `shape_square` (blue), `shape_triangle` (green); items circle_blue, square_green, triangle_red, circle_green, square_red, triangle_blue | M-SORT-SHIFT (shape line "the same colour, but we look for the same shape": true, because every item has the colour of another bin) | practice | shape-friends-again-1-b15 | sort: L2 the ghost outline beside each bin (P9) | colour lures by design |
| SHP-A-01 | b36.shpa01.2 | sort_drag (sort, rule shape) | concrete | as above | bins `shape_square_green`, `shape_triangle_red`; items square_red, triangle_green, shape_triangle (green), square_red | M-SORT-SHIFT (shape) | transfer | shape-friends-again-1-b15 | sort | |
| SHP-A-04 | b36.shpa04.1 | sort_drag (sort) | concrete | Rectangles here, squares here | bins `shape_rect`, `shape_square`; items rect_red, square_orange, rect_green, square_red, rect_yellow, square_yellow | M-SHP-SQRECT | practice | rectangle-again | sort | |
| SHP-A-04 | b36.shpa04.2 | sort_drag (sort) | concrete | as above | bins `shape_rect_blue`, `shape_square_blue`; items square_tilt, rect_orange, square_green, rect_red, square_yellow | M-SHP-SQRECT | transfer | rectangle-again | sort | the turned square is a transfer case |
| SHP-A-05 | b36.shpa05.1 | sort_drag (sort) | concrete | Put each thing with its shape | bins `shape_circle`, `shape_rect`, `shape_triangle`; items plate, window, sign, coin | M-SHP-NAME (decision 3 gives SHP-A-05 this tag; the M-SHP-PROTO line says "count the sides", untrue for a plate) | practice | shapes-around-us-again-1-b15 | sort: L2 the outline of each bin's shape beside the next picture | design check: the coin reads as a circle |
| SHP-A-05 | b36.shpa05.2 | sort_drag (sort) | concrete | as above | bins `shape_circle`, `shape_rect`; items clock_3, paper, plate, window | M-SHP-NAME | transfer | shapes-around-us-again-1-b15 | sort | design check: `paper` reads as a rectangle |
| SHP-A-06 | b36.shpa06.1 | tap_answer (pick) | pictorial | Which shape fits this empty place? | stage `group` outline_triangle_down (an empty outline, turned); options triangle_red (r), square_red, circle_red | square: M-SHP-ORIENT; circle: M-SHP-ORIENT (E1, as `b15.shpa01.1`) | practice | build-with-shapes-1-b36 (new) | TA-7 shapes (new entry): L2 the outline lifts and turns | **new** `outline_triangle_down` |
| SHP-A-06 | b36.shpa06.2 | tap_answer (pick) | pictorial | as above | `group` outline_square_tilt; options square_green (r), rect_green, triangle_green | rect: M-SHP-SQRECT; triangle: M-SHP-ORIENT (a point on top looks like a triangle's) | transfer | build-with-shapes-1-b36 | TA-7 shapes | **new** `outline_square_tilt` |
| SHP-A-07 | b36.shpa07.1 | sort_drag (sort) | concrete | Things that roll here, things that stand and stack here | bins `solid_sphere` (label "rolls"), `solid_box` ("stacks"); items ball_red, block, ball_blue, solid_cube | M-SHP-NAME with an own line (`tag_lines`): "a ball rolls; a box stands and can be stacked" | practice | roll-or-stack-again | sort: L2 the act-out (P10: the ball rolls, the box stands) | no catalogue tag fits a property error; fair fit |
| SHP-A-07 | b36.shpa07.2 | sort_drag (sort) | concrete | as above, other samples | bins `solid_cube` ("stacks"), `ball_red` ("rolls"); items solid_sphere, solid_box, ball_blue, block | M-SHP-NAME (own line) | transfer | roll-or-stack-again | sort | |
| SHP-A-08 | b36.shpa08.1 | sort_drag (sort) | concrete | Put each cat with the ball that is in the same place: on, in, next to | bins `pos_on`, `pos_in`, `pos_next` (labels: the words); items pos_cat_on, pos_cat_in, pos_cat_next | M-SPACE-WORD ("the word tells us where it is") | practice | where-is-it-again | sort: L1 each bin with its word, L2 act-out (P10) | a relation sorted across two objects; the drag of the curriculum row |
| SHP-A-08 | b36.shpa08.2 | sort_drag (sort) | concrete | as above: on, under, above | bins `pos_on`, `pos_under`, `pos_above`; items pos_cat_on, pos_cat_under, pos_cat_above | M-SPACE-WORD | transfer | where-is-it-again | sort | **new** `pos_cat_under`, `pos_cat_above` (the B-38 cat and basket) |
| SHP-A-10 | b36.shpa10.1 | sort_drag (sort) | concrete | Straight lines here, curved lines here | bins `line_straight`, `line_curved`; items line_straight_up, line_curved_arc, line_straight_flat, line_curved_wave | M-SHP-NAME (the line word not yet linked to its look; the editor checks that part C's line fits a line word) | practice | shapes-around-us-again-1-b15 | sort: L2 a straight stick laid along the next picture (plan §5.1 TA-7) | |
| SHP-A-10 | b36.shpa10.2 | sort_drag (sort) | concrete | Shapes with a curved line here, shapes with straight lines here | bins `line_curved`, `line_straight`; items shape_circle, shape_square, shape_triangle, shape_rect | M-SHP-NAME | transfer | shapes-around-us-again-1-b15 | sort | |

### 2.4 Logic (8 skills, 16 items)

| Skill | New id | Template (kind) | Adds | Prompt intent | Options or setup (r = right) | Wrong answers: tag | Check | Lesson | B-40 hints | New picture / note |
|---|---|---|---|---|---|---|---|---|---|---|
| LOG-A-02 | b36.loga02.1 | sort_drag (sort, rule colour) | concrete | Put the one that is different in the basket; the others go on the grass | bins `basket_empty` (label "basket"), `grass`; items ball_red, ball_red, ball_blue, ball_red; r = the blue ball in the basket | M-SORT-SHIFT (colour line) | practice | same-and-different-again-1-b15 | sort | the child moves the odd one out |
| LOG-A-02 | b36.loga02.2 | sort_drag (sort, rule shape) | concrete | as above | items circle_blue ×3, triangle_blue; r = the triangle in the basket | M-SORT-SHIFT (shape line: true, all four are blue) | transfer | same-and-different-again-1-b15 | sort | |
| LOG-A-04 | b36.loga04.1 | build_pattern (build, short model) | concrete | Here are a cat and a dog. Make them repeat, again and again | model cat, dog; 6 places; palette cat, dog; r = cat, dog ×3 | M-PAT-UNIT (G1) | practice | patterns-again-1-b15 | build: walk the row, P7 core box on the model, demo | the unit is the model: what a repeating pattern is |
| LOG-A-04 | b36.loga04.2 | build_pattern (build, short model) | concrete | as above | model fish, bird; 6 places; palette fish, bird, star; r = fish, bird ×3 | M-PAT-UNIT | transfer | patterns-again-1-b15 | build | |
| LOG-A-05 | b36.loga05.1 | tap_answer (pick) | pictorial | We copy this pattern. Our copy starts with a cat. What comes next in our copy? | `row` cat, dog, cat, dog (the model); options dog (r), cat | cat: M-PAT-COPY | practice | copy-patterns-1-b36 (new) | TA-8 pattern (new entry): L1 the model lit in rhythm, L2 core box | 2 options; the copy is read from the model in order |
| LOG-A-05 | b36.loga05.2 | tap_answer (pick) | pictorial | Our copy has fish, star. What comes now? | `row` fish, star, star, fish, star, star; options star (r), fish | fish: M-PAT-COPY | transfer | copy-patterns-1-b36 | TA-8 pattern | ABB: the order matters, not only the two things |
| LOG-A-06 | b36.loga06.1 | build_pattern (build, short model) | concrete | Copy the pattern, and make it longer | model cat, dog, cat, dog; 6 places; palette cat, dog; r = cat, dog ×3 | M-PAT-NEXT (G1) | practice | patterns-again-1-b15 | build: L2 the model cell above the place; past the model, the unit goes on | |
| LOG-A-06 | b36.loga06.2 | build_pattern (build, short model) | concrete | as above | model star_size_l, star_size_s, l, s; 6 places; palette l, s, m; r = l, s ×3 | M-PAT-NEXT | transfer | patterns-again-1-b15 | build | size pattern |
| LOG-A-07 | b36.loga07.1 | tap_answer (pick), `rep: story` | story | The fish swim in a line: big, small, big, small. One fish swam away. Which fish comes back? | `row` fish_size_l, s, l, ?, l, s; options fish_size_s (r), fish_size_l, fish_size_m | l: M-PAT-NEXT; m: M-PAT-UNIT | practice | fix-patterns-again | TA-8 pattern | authored story (section 4) |
| LOG-A-07 | b36.loga07.2 | tap_answer (pick), `rep: story` | story | Balloons for the party: red, yellow, red, yellow. The wind took one. Which balloon goes back? | `row` balloon_red, yellow, red, yellow, ?, yellow; options balloon_red (r), balloon_yellow, balloon_green | yellow: M-PAT-NEXT; green: M-PAT-UNIT | transfer | fix-patterns-again | TA-8 pattern | |
| LOG-A-08 | b36.loga08.1 | build_pattern (build, no model) | concrete | Put the story in order: first, then, at the end | 3 numbered places; palette chick, egg, egg_crack; r = egg, egg_crack, chick | M-SEQ-CAUSE (G1) | practice | stories-and-pairs-again-1-b15 | build: L1 the places 1, 2, 3 from the left, demo walks the story | the cards are moved, as on a table |
| LOG-A-08 | b36.loga08.2 | build_pattern (build, no model) | concrete | as above | palette rainbow, cloud, rain; r = cloud, rain, rainbow | M-SEQ-CAUSE | transfer | stories-and-pairs-again-1-b15 | build | |
| LOG-A-09 | b36.loga09.1 | sort_drag (sort) | concrete | Put each thing with what it goes with | bins `shoe`, `lock`, `paper`; items sock, key, pencil | M-ASSOC-LOOK (the pencil is long and thin like a key: putting it at the lock is going by the look) | practice | stories-and-pairs-again-1-b15 | sort | depends on part C (the tag) and part E (the link) |
| LOG-A-09 | b36.loga09.2 | sort_drag (sort) | concrete | as above | bins `bowl`, `brush`, `cloud`; items spoon, paste, rain | M-ASSOC-LOOK (the spoon has a handle like the brush) | transfer | stories-and-pairs-again-1-b15 | sort | |
| LOG-A-10 | b36.loga10.1 | build_pattern (build, no model) | concrete | Line the towers up from small to big | 3 places; palette tower_3, tower_1, tower_2; r = 1, 2, 3 | M-SER-ENDS (G1; "looking for the middle") | practice | by-size-again | build: L2 P8 baseline | the staircase repair of the catalogue, done by hand |
| LOG-A-10 | b36.loga10.2 | build_pattern (build, no model) | concrete | Line the fish up from big to small | palette fish_size_s, l, m; r = l, m, s | M-SER-ENDS | transfer | by-size-again | build | |

### 2.5 Robots, CS (3 skills, 6 items)

| Skill | New id | Template (kind) | Adds | Prompt intent | Options or setup (r = right) | Wrong answers: tag | Check | Lesson | B-40 hints | New picture / note |
|---|---|---|---|---|---|---|---|---|---|---|
| CS-A-01 | b36.csa01.1 | build_pattern (build, no model) | concrete | Put the hand-washing steps in order | 3 numbered places; palette step_soap, step_towel, step_tap; r = tap, soap, towel | M-SEQ-CAUSE | practice | step-by-step-again-1-b15 | build | unplugged sequencing cards (Bers 2020) |
| CS-A-01 | b36.csa01.2 | build_pattern (build, no model) | concrete | Put the tooth-brushing steps in order | palette step_rinse, step_paste, step_brush; r = paste, brush, rinse | M-SEQ-CAUSE | transfer | step-by-step-again-1-b15 | build | rinse is the cup of water of the teeth routine (B-15 addendum A1) |
| CS-A-03 | b36.csa03.1 | robot_path (robot, mode plan) | symbolic | Plan the robot's steps, then press go (CS-A-04 pattern) | board 3 × 2, robot (0, 1), flag (1, 0); solution up, then toward the flag | M-CS-OFF1 | practice | robot-moves-again | robot plan: L2 the first leg only (plan §6, CS-B-01 rule), demo | weights {CS-A-03: 1, CS-A-04: 0.5}. Each arrow card is one step: the next step of concreteness fading. Band A landmark words only |
| CS-A-03 | b36.csa03.2 | robot_path (robot, mode plan) | symbolic | as above | board 3 × 3, robot (1, 2), flag (1, 0); solution up, up | M-CS-OFF1 | transfer | robot-moves-again | robot plan | 2 steps, so the first leg is never the whole answer |
| CS-A-05 | b36.csa05.1 | sort_drag (sort) | concrete | Put each step with its routine: brushing teeth, washing hands | bins `step_brush` ("brushing teeth"), `step_soap` ("washing hands"); items step_paste, step_tap, step_rinse, step_towel | M-SEQ-SCRIPT (does not yet know the steps of the routine) | practice | step-by-step-again-1-b15 | sort | knowing what belongs to a script comes before spotting the step that does not (Nelson 1986) |
| CS-A-05 | b36.csa05.2 | sort_drag (sort) | concrete | as above, other samples | bins `step_paste`, `step_tap`; items step_brush, step_soap, step_rinse, step_towel | M-SEQ-SCRIPT | transfer | step-by-step-again-1-b15 | sort | |

### 2.6 Maths and money (6 skills, 12 items)

| Skill | New id | Template (kind) | Adds | Prompt intent | Options or setup (r = right) | Wrong answers: tag | Check | Lesson | B-40 hints | New picture / note |
|---|---|---|---|---|---|---|---|---|---|---|
| MATH-A-01 | b36.matha01.1 | count_tap (own prompt, G2) | concrete | There are two cats, and two more came. Touch each one and count | 4 cats; tiles 4 (r), 2, 5 | 2: M-CNT-CARD (the first group; part B's join line); 5: M-CNT-DOUBLE | practice | add-one-more-again | count: L2 two hands join | curriculum §4.7 says "concrete only" for MATH-A-01; until now it had none |
| MATH-A-01 | b36.matha01.2 | count_tap (own prompt) | concrete | There are three ladybugs, and two more came | 5 ladybugs; tiles 5 (r), 3, 6 | 3: M-CNT-CARD; 6: M-CNT-DOUBLE | transfer | add-one-more-again | count | |
| MATH-A-02 | b36.matha02.1 | count_tap (own prompt) | concrete | There were four ducks. One swam away. Touch and count the ducks that stayed | 3 ducks; tiles 3 (r), 4, 2 | 4: M-CNT-CARD (the start; part B's take-away line); 2: M-CNT-SKIP | practice | take-one-away-again | count | |
| MATH-A-02 | b36.matha02.2 | count_tap (own prompt) | concrete | There were five fish. One swam away | 4 fish; tiles 4 (r), 5, 3 | 5: M-CNT-CARD; 3: M-CNT-SKIP | transfer | take-one-away-again | count | |
| MATH-A-03 | b36.matha03.1 | tap_answer (pick) | pictorial | The cat got these, the dog got these. Did they get the same? | `group` apple ×3 (the cat's), `group2` apple ×1 (the dog's); tick, cross (r) | tick: M-SHARE-UNEQ | transfer | sharing-again | TA-4 compare (new entry): L1 baseline, L2 pair lines | judging a share, after doing one |
| MATH-A-03 | b36.matha03.2 | tap_answer (pick) | pictorial | as above | `group` star ×3 scattered, `group2` star ×3 in a line; tick (r), cross | cross: M-CNT-SIZE (cue spread) | transfer | sharing-again | TA-4 compare | |
| MATH-A-04 | b36.matha04.1 | sort_drag (sort, rule size) | concrete | Big ones here, small ones here | bins `ball_size_l`, `ball_size_s`; items apple_size_l, fish_size_s, star_size_l, apple_size_s, fish_size_l, star_size_s | M-SORT-SHIFT (size line, owner-approved P5) | practice | big-small-long-heavy-1-b36 (new) | sort: L1 P8 a common floor | across kinds |
| MATH-A-04 | b36.matha04.2 | sort_drag (sort, rule size) | concrete | as above, fish as the samples | bins `fish_size_l`, `fish_size_s`; items ball_size_s, star_size_l, apple_size_l, ball_size_l, star_size_s | M-SORT-SHIFT (size) | transfer | big-small-long-heavy-1-b36 | sort | |
| MATH-A-05 | b36.matha05.1 | build_pattern (build, no model) | concrete | Put the day in order, from the morning | 4 numbered places; palette time_noon, time_night, time_morning, time_evening; r = morning, noon, evening, night | M-TIME-SEQ (G1) | practice | my-day | build: L2 the sun's path (P10) | |
| MATH-A-05 | b36.matha05.2 | build_pattern (build, no model) | concrete | Start with the evening, and put the rest in order | 3 places; palette time_morning, time_evening, time_night; r = evening, night, morning | M-TIME-SEQ | transfer | my-day | build | the cycle: after the night comes the morning again |
| MATH-A-07 | b36.matha07.1 | sort_drag (sort, rule kind) | concrete | Put each one in its column of the picture graph | bins `apple`, `ball_red`; items apple, ball_red, apple, apple, ball_red | M-SORT-SHIFT (kind line "the same colour, but we look for the same thing": true, both are red) | practice | picture-graph-again | sort | making the graph is half of MATH-A-07 ("sorts and compares") |
| MATH-A-07 | b36.matha07.2 | sort_drag (sort, rule kind) | concrete | as above | bins `banana_yellow`, `ball_yellow`; items banana_yellow, ball_yellow, ball_yellow, banana_yellow, ball_yellow, ball_yellow | M-SORT-SHIFT (kind; both yellow) | transfer | picture-graph-again | sort | |

## 3. Band B (38 skills, 76 items)

### 3.1 Numbers (13 skills, 26 items)

| Skill | New id | Template (kind) | Adds | Prompt intent | Options or setup (r = right) | Wrong answers: tag | Check | Lesson | B-40 hints | New picture / note |
|---|---|---|---|---|---|---|---|---|---|---|
| NUM-B-01 | b.numb01.10 | number_line (numline, place) | pictorial | The frog wants to stand on fourteen. Touch the place (NUM-B-13 pattern) | line 10 to 20, labels 10, 20; target 14 | any other place: M-CNT-SEQ; the mirror place 16: M-NL-DIR | practice | count-to-20-more | number line: start and landmarks, first hop from 10, demo | the counting words laid on a path (Siegler & Ramani 2008) |
| NUM-B-01 | b.numb01.11 | number_line (numline, place) | pictorial | as above, seventeen | line 10 to 20, labels 10, 15, 20; target 17 | M-CNT-SEQ; mirror 13: M-NL-DIR | transfer | count-to-20-more | number line | |
| NUM-B-02 | b.numb02.10 | number_line (numline, place) | pictorial | The frog wants to stand on thirty | line 15 to 35, labels 15, 25, 35; target 30 | M-CNT-DECADE; mirror 20: M-NL-DIR | practice | count-to-30-more | number line | crossing 29 to 30; starts from 25 (curriculum row) |
| NUM-B-02 | b.numb02.11 | number_line (numline, place) | pictorial | The frog wants to stand on twenty | line 10 to 30, labels 10, 15, 30; target 20 | M-CNT-DECADE (20 is the middle, so no mirror tag) | transfer | count-to-30-more | number line | crossing 19 to 20; starts from 15 |
| NUM-B-03 | b.numb03.11 | number_line (numline, jump) | pictorial | The frog counts down like a rocket: from ten, three hops back. Where will it land? | line 0 to 10; start 10, hops [−3]; target 7 | M-CNT-SEQ; mirror 3: M-NL-DIR | predict | rocket-countdown | number line: L2 one hop back | the values go down along the row (plan B-40 §12.1) |
| NUM-B-03 | b.numb03.12 | number_line (numline, jump) | pictorial | from seven, three hops back | start 7, hops [−3]; target 4 | M-CNT-SEQ; mirror 6: M-NL-DIR | predict | rocket-countdown | number line | "also starts from 7" (curriculum row) |
| NUM-B-04 | b.numb04.12 | tap_answer (set_to_numeral) | pictorial | How many fish? Choose the number | 13 fish as two ten-frames; numerals 12, 13 (r), 14 | 12: M-CNT-SKIP; 14: M-CNT-DOUBLE | practice | many-things-more | TA-1 count (new entry): L2 the ten-frames (P4) | |
| NUM-B-04 | b.numb04.13 | tap_answer (set_to_numeral) | pictorial | How many ladybugs? | 16 ladybugs as two ten-frames; 15, 16 (r), 17 | 15: M-CNT-SKIP; 17: M-CNT-DOUBLE | transfer | many-things-more | TA-1 count | |
| NUM-B-05 | b.numb05.11 | tap_answer (pick, set arrangement G4) | pictorial | Here are twenty fish. The cat asked for twelve. Which plate is right? | `group` fish ×20 (two frames); sets fish ×12 (r), ×20, ×13, as ten-frames | 20: M-CNT-CARD; 13: M-CNT-DOUBLE | reverse | give-up-to-20 | TA-2 numerals (new entry): L2 P4 | as NUM-A-06; design check: three tiles of two frames on the phone |
| NUM-B-05 | b.numb05.12 | tap_answer (pick) | pictorial | Here are twenty birds. The duck asked for sixteen | `group` bird ×20; sets ×16 (r), ×20, ×15 | 20: M-CNT-CARD; 15: M-CNT-SKIP | transfer | give-up-to-20 | TA-2 numerals | |
| NUM-B-07 | x.numb07.21 | tap_answer (pick) | pictorial | Where is the three written the right way? | options glyph_3 (r), glyph_3_rev, glyph_8 | mirror 3: M-NUM-REV; 8: M-NUM-NAME | practice | write-from-the-dot-0-4 (its 0 to 4 lesson, not the last one) | TA-2 numerals (new entry): L2 P9 the numeral on its own, as on the number path | **new** `glyph_3`, `glyph_3_rev`, `glyph_8`. Left-facing digits are the ones children reverse (Fischer 2011) |
| NUM-B-07 | x.numb07.22 | tap_answer (pick) | pictorial | Where is the seven written the right way? | glyph_7 (r), glyph_7_rev, glyph_1 | mirror 7: M-NUM-REV; 1: M-NUM-NAME | transfer | write-from-the-dot-5-9 | TA-2 numerals | **new** `glyph_7`, `glyph_7_rev`, `glyph_1` |
| NUM-B-08 | b.numb08.15 | tap_answer (pick) | pictorial | Which plate has this many? (the numeral is read, not said) | stage numeral 13; sets fish ×13 (r, two frames), ×3, ×14 | 3: M-NUM-TEEN (sees the ones only; the line "there is a ten, and how many more?" fits); 14: M-CNT-SEQ | practice | read-the-teens-more | TA-2 numerals: L2 a full frame and ones, "1" under the ten | voice off: the prompt must not say the number |
| NUM-B-08 | b.numb08.16 | tap_answer (pick) | pictorial | as above | numeral 17; stars ×17 (r), ×7, ×16 | 7: M-NUM-TEEN; 16: M-CNT-SEQ | transfer | read-the-teens-more | TA-2 numerals | |
| NUM-B-10 | b.numb10.11 | tap_answer (pick) | pictorial | Which number is bigger, nine or six? | `group` apple ×9 as a ten-frame, `group2` apple ×6 as a ten-frame drawn at scale 1.5; numerals 9 (r), 6 | 6: M-CNT-SIZE (cue big) | practice | which-is-bigger-more | TA-4 compare: L2 two cube towers | the objects come back as the repair picture; 2 options |
| NUM-B-10 | b.numb10.12 | tap_answer (pick) | pictorial | Which number is smaller, four or seven? | `group` ×4 at scale 1, `group2` ×7 at scale 0.7; numerals 4 (r), 7 | 7: M-CNT-SIZE (cue small) | reverse | which-is-bigger-more | TA-4 compare | |
| NUM-B-11 | b.numb11.19 | number_line (numline, place) | pictorial | Put the frog on the number that is one more than six | line 0 to 10, labels 0, 6, 10; target 7 | M-CNT-SEQ; mirror 3: M-NL-DIR | practice | one-more-one-less-1-b36 (new) | number line: L2 first hop from 0 (it does not give 7) | place, not jump: a jump of one would be shown whole at L2 |
| NUM-B-11 | b.numb11.20 | number_line (numline, place) | pictorial | Put the frog on the number that is one less than nine | labels 0, 9, 10; target 8 | M-CNT-SEQ; mirror 2: M-NL-DIR | reverse | one-more-one-less-1-b36 | number line | |
| NUM-B-13 | b.numb13.22 | spot_error (spot) | symbolic | A friend wrote the numbers of the frog's line, and one is in the wrong place. Where is it? (NUM-B-11 spot pattern) | cells 0, 1, 2, 3, 8, 5, 6; wrong = 8 (index 4) | M-NL-SPACE (8 next to 3 is the catalogue's "places 5 near 9") | error_spotting | frog-jumps | spot numbers family (new entry): L2 a right path under the row | the order of the line without its picture |
| NUM-B-13 | b.numb13.23 | spot_error (spot) | symbolic | as above | cells 4, 5, 6, 2, 8, 9, 10; wrong = 2 (index 3) | M-NL-SPACE | error_spotting | frog-jumps | spot numbers | |
| NUM-B-14 | b.numb14.11 | balance (scale, mode balance) | concrete | Six on this pan, two on that one. Add blocks until the scale is level | left `block` ×6, right `block` ×2; r = add 4 | M-PART-MISS (adds the whole: the beam leans the other way) | practice | split-numbers-more | balance: L2 cube towers, the missing part as empty places | part-part-whole by hand; no right or left word |
| NUM-B-14 | b.numb14.12 | balance (scale, mode balance) | concrete | as above | left ×8, right ×3; r = add 5 | M-PART-MISS | transfer | split-numbers-more | balance | |
| NUM-B-17 | b.numb17.13 | tap_answer (pick) | pictorial | Count the socks in twos. How many socks? | `group` sock ×10 as a ten-frame (its columns are pairs); numerals 10 (r), 8, 12 | 8: M-CNT-SKIP (a pair missed); 12: M-CNT-DOUBLE (a pair twice) | practice | tens-and-twos-1-b36 (new) | TA-3 sequence: L2 hops of 2 | |
| NUM-B-17 | b.numb17.14 | number_line (numline, jump) | pictorial | The frog jumps in twos: from four, two jumps. Where will it land? | line 0 to 20; start 4, hops [2, 2]; target 8 | M-CNT-SEQ; mirror 12: M-NL-DIR | predict | tens-and-twos-1-b36 | number line: L2 the first jump of two | counting by tens has no picture yet (section 4) |
| NUM-B-18 | b.numb18.11 | sort_drag (share) | concrete | Share the socks between the cat and the dog, the same for each | 8 socks; bins cat, dog; r = 4 each | M-SHARE-UNEQ | practice | pairs | share: each friend, first round, demo | even = shares into two equal groups; correct line names "even" (editor) |
| NUM-B-18 | b.numb18.12 | sort_drag (share) | concrete | as above, shoes | 6 shoes; r = 3 each | M-SHARE-UNEQ | transfer | pairs | share | odd numbers cannot be dealt (the validator refuses an uneven share), section 8 |

### 3.2 Colours (3 skills, 6 items)

| Skill | New id | Template (kind) | Adds | Prompt intent | Options or setup (r = right) | Wrong answers: tag | Check | Lesson | B-40 hints | New picture / note |
|---|---|---|---|---|---|---|---|---|---|---|
| COL-B-01 | b.colb01.10 | tap_answer (pick), `rep: story` | story | The frog wants to paint its house green. It has blue paint. Which paint does it add? | `group` ball_blue; options ball_yellow (r), ball_red, ball_green | red: M-COL-MIX; green (the colour it wants): M-COL-MIX (E1) | practice | mix-colours-more | TA-6 colour: L2 the colour wheel with the empty mix slot | authored story (section 4) |
| COL-B-01 | b.colb01.11 | tap_answer (pick), `rep: story` | story | The cat mixes red paint and yellow paint for its ball. What colour will the ball be? | `group` ball_red, `group2` ball_yellow; options ball_orange (r), ball_red, ball_purple | red ("the stronger colour wins"): M-COL-MIX; purple: M-COL-MIX (E1) | predict | mix-colours-more | TA-6 colour | |
| COL-B-02 | b.colb02.13 | build_pattern (build, no model) | concrete | Put them in order, from light to dark | 3 places; palette shade_blue_3, shade_blue_1, shade_blue_2; r = 1, 2, 3 | M-SER-ENDS with an own line (`tag_lines`): "the middle is not the lightest and not the darkest" | practice | middle-shade | build: L2 P8 shade strip | the shared M-SER-ENDS line speaks of small and big (section 10) |
| COL-B-02 | b.colb02.14 | build_pattern (build, no model) | concrete | as above | palette shade_green_2, shade_green_3, shade_green_1; r = 1, 2, 3 | M-SER-ENDS (own line) | transfer | middle-shade | build | |
| COL-B-03 | b.colb03.11 | sort_drag (sort) | concrete | Blue ones here, red ones here, light or dark | bins `shade_blue_2`, `shade_red_2`; items shade_blue_1, shade_red_3, shade_blue_3, shade_red_1, ball_blue, ball_red | M-COL-SHADE with an own line naming no colour: "light or dark, it is the same colour" | practice | same-colour-shades-more | sort: L2 P9 the shade strip beside each bin | |
| COL-B-03 | b.colb03.12 | sort_drag (sort) | concrete | as above, green and purple | bins `shade_green_2`, `shade_purple_2`; items shade_green_1, shade_purple_3, shade_green_3, shade_purple_1 | M-COL-SHADE (own line) | transfer | same-colour-shades-more | sort | |

### 3.3 Shapes (6 skills, 12 items)

| Skill | New id | Template (kind) | Adds | Prompt intent | Options or setup (r = right) | Wrong answers: tag | Check | Lesson | B-40 hints | New picture / note |
|---|---|---|---|---|---|---|---|---|---|---|
| SHP-B-01 | b.shpb01.11 | sort_drag (sort) | concrete | Put each shape with the shape that has as many sides | bins `shape_triangle` ("three sides"), `shape_quad` ("four sides"); items triangle_thin, square_tilt, triangle_down, rect, triangle_red, square_orange | M-SHP-PROTO ("count the sides") | practice | polygon-detectives-more | sort: L2 the sides lit and counted | thin and turned members on purpose |
| SHP-B-01 | b.shpb01.12 | sort_drag (sort) | concrete | as above, three bins | bins triangle, quad, pentagon; items triangle_thin, rect, pentagon, square, triangle_down | M-SHP-PROTO | transfer | polygon-detectives-more | sort | |
| SHP-B-02 | b.shpb02.11 | trace (glyph triangle, guide full) | embodied | Follow each side of the triangle with your finger, one side after another | strokes of `triangle`; done when traced | no wrong answer (a trace); no direction tag | practice | count-sides-more | trace: first side, whole stroke, demo that counts the sides | own h3 and correct line: "three sides" (editor). One-to-one for sides, by the body |
| SHP-B-02 | b.shpb02.12 | trace (glyph square, guide start) | embodied | as above, the square, from the dot only | strokes of `square` | no wrong answer | transfer | count-sides-more | trace | |
| SHP-B-03 | b.shpb03.8 | sort_drag (sort) | concrete | All sides the same here; long and short sides here | bins `shape_square_green` ("all sides equal"), `shape_rect_green` ("long and short sides"); items square_tilt, rect_blue, square_red, rect_orange, square_yellow, rect_red | M-SHP-SQRECT | practice | square-or-rectangle | sort: L2 the sides compared | |
| SHP-B-03 | b.shpb03.9 | sort_drag (sort) | concrete | as above | bins `shape_square`, `shape_rect`; items rect_yellow, square_blue, rect_green, square_orange, square_tilt | M-SHP-SQRECT | transfer | square-or-rectangle | sort | |
| SHP-B-04 | b.shpb04.10 | sort_drag (sort) | concrete | Closed shapes with straight sides here; all the others here | bins `shape_pentagon` (label: closed, straight sides), `shape_open` (label: not); items triangle, shape_curved, hexagon, quad, line_curved_arc | M-SHP-CLOSED (its line covers both the gap and the curved side) | practice | closed-shapes-more | sort | |
| SHP-B-04 | b.shpb04.11 | sort_drag (sort) | concrete | as above | bins `shape_square`, `shape_curved`; items shape_open_quad, pentagon, shape_open, triangle_thin, circle | M-SHP-CLOSED | transfer | closed-shapes-more | sort | **new** `shape_open_quad` (four straight sides, one gap) |
| SHP-B-08 | b.shpb08.11 | sort_drag (sort) | concrete | Put each thing with the solid it is shaped like | bins `solid_cylinder`, `solid_cone`, `solid_sphere`; items obj_can, obj_party_hat, ball_red, obj_drum | M-SHP-NAME | practice | solids-more | sort: L2 the solid turns and shows its faces | **new** `obj_can`, `obj_party_hat`, `obj_drum`. Solids in the child's world |
| SHP-B-08 | b.shpb08.12 | sort_drag (sort) | concrete | as above | bins `solid_box`, `solid_cylinder`, `solid_sphere`; items obj_gift, obj_can, ball_blue | M-SHP-NAME | transfer | solids-more | sort | **new** `obj_gift`. No cube, until the owner reads the B-38 cube texts (decision 9) |
| SHP-B-09 | x.shpb09.7 | sort_drag (sort) | concrete | Put each solid on the shape it leaves in the sand | bins `shape_circle`, `shape_square`; items solid_cylinder, solid_cube | M-SHP-FACE | practice | solid-and-face | sort: L2 the solid "stamps" | each solid has one bin it can leave; no pyramid (audit F9) |
| SHP-B-09 | x.shpb09.8 | sort_drag (sort) | concrete | as above | bins `shape_square`, `shape_rect`, `shape_circle`; items solid_cube, solid_box, solid_cone | M-SHP-FACE | transfer | solid-and-face | sort | no cylinder here: it leaves a circle and a rectangle |

### 3.4 Logic (6 skills, 12 items)

| Skill | New id | Template (kind) | Adds | Prompt intent | Options or setup (r = right) | Wrong answers: tag | Check | Lesson | B-40 hints | New picture / note |
|---|---|---|---|---|---|---|---|---|---|---|
| LOG-B-01 | b.logb01.11 | build_pattern (build, short model) | concrete | Copy the pattern and make it longer | model frog, chick, chick, frog, chick, chick; 8 places; palette frog, chick, bird; r = the model, then frog, chick | M-PAT-NEXT | practice | longer-patterns-more | build | ABB |
| LOG-B-01 | b.logb01.12 | build_pattern (build, short model) | concrete | as above | model apple, fish, star ×2; 8 places; palette apple, fish, star; r = the model, then apple, fish | M-PAT-NEXT | transfer | longer-patterns-more | build | ABC |
| LOG-B-02 | b.logb02.7 | build_pattern (build, long model) | concrete | Build only the little part that repeats | model red, red, blue, red, red, blue (balls); 3 places; palette red, blue, yellow; r = red, red, blue | M-PAT-UNIT | practice | broken-pattern | build: L2 P7 core box | the catalogue's repair "wrap the core", by hand |
| LOG-B-02 | b.logb02.8 | build_pattern (build, long model) | concrete | as above | model cat, dog, star, cat, dog, star; 3 places; r = cat, dog, star | M-PAT-UNIT | transfer | broken-pattern | build | |
| LOG-B-04 | b.logb04.9 | build_pattern (build, no model) | concrete | Build a stair of towers: each one is one taller | 4 places; palette tower_3, tower_1, tower_4, tower_2; r = 1, 2, 3, 4 | M-PAT-GROW ("each tower is one taller") | practice | growing-towers | build: L2 the counts 1, 2, 3 under the places | no short model (section 1) |
| LOG-B-04 | b.logb04.10 | build_pattern (build, no model) | concrete | as above, start with the tower of two | 4 places; palette tower_5, tower_2, tower_4, tower_3, tower_6; r = 2, 3, 4, 5 | M-PAT-GROW | transfer | growing-towers | build | step 1 only, so the shared line stays true |
| LOG-B-06 | b.logb06.9 | sort_drag (sort) | concrete | A friend began to sort. Look at the two boxes, and sort the rest the same way | bins `shape_circle_red`, `shape_circle_blue` (both circles: the rule is colour); items square_red, triangle_blue, square_blue, triangle_red | M-RULE-ONE (looked at one sample, not at both) | practice | find-the-rule | sort: L2 P9 rule card | the rule is found by comparing the two samples, then used |
| LOG-B-06 | b.logb06.10 | sort_drag (sort) | concrete | as above | bins `shape_square_red`, `shape_triangle_red` (both red: the rule is shape); items square_blue, triangle_green, square_yellow, triangle_blue | M-RULE-ONE | transfer | find-the-rule | sort | |
| LOG-B-08 | b.logb08.7 | spot_error (spot) | pictorial | The rule: if it is a circle, it goes in the box. Here is the box. Which one is in it by mistake? | cells circle_red, circle_blue, square_red, circle_green; wrong = the square (index 2) | M-RULE-ONE (did not check the rule on each one) | error_spotting | if-then | spot sort family (new entry): L2 the rule card beside each cell | |
| LOG-B-08 | b.logb08.8 | spot_error (spot) | pictorial | The rule: if it is blue, it goes in the box | cells square_blue, triangle_blue, circle_red, circle_blue; wrong = index 2 | M-RULE-ONE | error_spotting | if-then | spot sort | |
| LOG-B-09 | b.logb09.9 | sort_drag (sort) | concrete | Not red and not a circle: into the box. All the others: onto the grass | bins `basket_empty`, `grass`; items square_blue (box), circle_blue, square_red, triangle_green (box), circle_red | M-LOG-NOT | practice | not-this-not-that | sort: L2 clue 1 only (those that are red fade), demo clue 2 | deduction done by hand |
| LOG-B-09 | b.logb09.10 | sort_drag (sort) | concrete | Not blue and not a square | items triangle_green (box), square_green, triangle_blue, circle_red (box), square_blue | M-LOG-NOT | transfer | not-this-not-that | sort | |

### 3.5 Robots, CS (1 skill, 2 items)

| Skill | New id | Template (kind) | Adds | Prompt intent | Options or setup (r = right) | Wrong answers: tag | Check | Lesson | B-40 hints | New picture / note |
|---|---|---|---|---|---|---|---|---|---|---|
| CS-B-04 | b.csb04.7 | robot_path (robot, mode direct) | concrete | Oops: one arrow of the program went down instead of up, and the robot stopped here. Bring it to the flag the short way, and fix only that | board 4 × 3, robot (2, 2), flag (2, 0); solution up, up | M-CS-OFF1 | transfer | fix-the-program | robot: L2 a ghost robot takes one step | fixing only the wrong part, by hand, against M-CS-FIXALL; the debug mode is a template proposal (section 4) |
| CS-B-04 | b.csb04.8 | robot_path (robot, mode direct) | concrete | The program said left where it should say right | board 4 × 2, robot (1, 1), flag (3, 1); right, right | M-CS-OFF1 | transfer | fix-the-program | robot | Band B may use right and left (CS-B-01 does) |

### 3.6 Maths and money (9 skills, 18 items)

| Skill | New id | Template (kind) | Adds | Prompt intent | Options or setup (r = right) | Wrong answers: tag | Check | Lesson | B-40 hints | New picture / note |
|---|---|---|---|---|---|---|---|---|---|---|
| MATH-B-06 | b.mathb06.11 | balance (scale, mode balance) | concrete | Ten on this pan, seven on that one. Add blocks until it is level | left `block` ×10, right ×7; r = add 3 | M-PART-MISS (adds ten) | practice | make-ten-more | balance: L2 towers | design check: ten blocks on one pan on the phone |
| MATH-B-06 | b.mathb06.12 | balance (scale, mode balance) | concrete | as above | left ×10, right ×4; r = add 6 | M-PART-MISS | transfer | make-ten-more | balance | |
| MATH-B-07 | b.mathb07.9 | tap_answer (pick) | pictorial | Five apples, and zero more. How many now? | `group` apple ×5, `group2` apple ×0 (an empty frame, G6); numerals 5 (r), 0, 6 | 0: M-NUM-ZERO; 6: M-NUM-ZERO (as `b.mathb07.1`) | practice | zero-sums | TA-5 add | |
| MATH-B-07 | b.mathb07.10 | tap_answer (pick) | pictorial | Four fish, and all four swam away. How many are left? | `group` fish ×4; numerals 0 (r), 1, 4 | 1: M-NUM-ZERO; 4: M-CNT-CARD (the start; part B's take-away line) | predict | zero-sums | TA-5 add | |
| MATH-B-08 | b.mathb08.15 | tap_answer (pick) | pictorial | Eight apples, and five more. How many in all? | `group` apple ×8 and `group2` apple ×5, each as a ten-frame; numerals 13 (r), 3, 12 | 3: M-OP-SWAP (took away); 12: M-CNT-DOUBLE | practice | to-twenty-more | TA-5 add: L2 fill the first frame to ten | the ten-frame model of the curriculum's ladder 2 |
| MATH-B-08 | b.mathb08.16 | tap_answer (pick) | pictorial | Fourteen stars; five flew away. How many are left? | `group` star ×14 as two frames; numerals 9 (r), 19, 14 | 19: M-OP-SWAP (added); 14: M-CNT-CARD (the start) | transfer | to-twenty-more | TA-5 add | |
| MATH-B-10 | b.mathb10.9 | sort_drag (share) | concrete | Share eight fish between the cat and the dog, the same for each | 8 fish; bins cat, dog; r = 4 each | M-SHARE-UNEQ | practice | equal-groups | share | sort holds 8 pictures at most |
| MATH-B-10 | b.mathb10.10 | sort_drag (share) | concrete | Share six apples among the cat, the dog and the duck | 6 apples; 3 bins; r = 2 each | M-SHARE-UNEQ | transfer | equal-groups | share | |
| MATH-B-14 | b.mathb14.12 | build_pattern (build, no model) | concrete | Put the days in order, from Sunday | 4 places; palette day_3, day_1, day_4, day_2; r = 1, 2, 3, 4 | M-TIME-SEQ | practice | days-of-the-week-1-b36 (new) | build: L2 P6 week strip | the day cards are symbols, but the child moves them |
| MATH-B-14 | b.mathb14.13 | build_pattern (build, no model) | concrete | From Thursday to Shabbat | 3 places; palette day_7, day_5, day_6; r = 5, 6, 7 | M-TIME-SEQ | transfer | days-of-the-week-1-b36 | build | |
| MATH-B-16 | x.mathb16.9 | shop_pay (pay, G3) | concrete | It costs five shekels. Pay exactly | price 500; purse ₪5 ×1, ₪2 ×1, ₪1 ×2, 10 ag ×2 (the rest is ₪4.20, so only the ₪5 coin pays) | wrong value: M-MONEY-SIZE; five coins for five shekels: M-MONEY-COUNT | practice | know-the-coins-more | shop: L1 price and counter, L2 first coin, demo | knowing the coin is the task, paying is its use |
| MATH-B-16 | x.mathb16.10 | shop_pay (pay) | concrete | It costs ten shekels. Pay exactly | price 1000; purse ₪10, ₪5, ₪2, ₪1, ½₪, one each (without the ₪10: ₪8.50) | M-MONEY-SIZE (the ₪5 coin is bigger than the ₪10); M-MONEY-COUNT | transfer | know-the-coins-more | shop | |
| MATH-B-17 | x.mathb17.12 | tap_answer (pick) | pictorial | How much money is there? | `chart` coin_s5 ×1, coin_s2 ×1, coin_s1 ×1; numerals 8 (r), 3, 7 | 3: M-MONEY-COUNT (counted the coins; the catalogue's own signal); 7: M-CNT-SKIP | practice | pay-exactly-more | TA-12 clock and money (new entry): L2 each coin's value beside it | |
| MATH-B-17 | x.mathb17.13 | tap_answer (pick) | pictorial | as above | `chart` coin_s10 ×1, coin_s2 ×2; numerals 14 (r), 3, 12 | 3: M-MONEY-COUNT; 12: M-CNT-SKIP | transfer | pay-exactly-more | TA-12 | |
| MATH-B-18 | b.mathb18.10 | tap_answer (pick) | pictorial | There are seven fish in all. We see three; the others hide behind the stone. How many are hiding? | `group` fish ×3, `group2` stone ×1; numerals 4 (r), 7, 10 | 7: M-PART-MISS (the whole); 10: M-OP-SWAP (added) | practice | missing-number | TA-5 add: L2 part-whole, a frame of 7 with 3 shaded | the equation □ + 3 = 7 as a picture; no "=" shown, so not M-EQ-OPER |
| MATH-B-18 | b.mathb18.11 | tap_answer (pick) | pictorial | Nine in all, we see five | fish ×5, stone; numerals 4 (r), 9, 14 | 9: M-PART-MISS; 14: M-OP-SWAP | transfer | missing-number | TA-5 add | |
| MATH-B-19 | x.mathb19.12 | sort_drag (sort, rule kind) | concrete | Put each one in its column | bins `apple`, `ball_red`; items apple, ball_red, apple, apple, ball_red, apple | M-SORT-SHIFT (kind; both red) | practice | read-the-chart-more | sort | making the pictograph (curriculum: "makes and reads") |
| MATH-B-19 | x.mathb19.13 | sort_drag (sort, rule kind) | concrete | as above, three columns | bins `banana_yellow`, `ball_yellow`, `star` (all yellow); items banana_yellow, ball_yellow, star, star, banana_yellow, ball_yellow | M-SORT-SHIFT (kind) | transfer | read-the-chart-more | sort | |

## 4. Skills with no fitting template

Every skill has its 2 items above; none is skipped. Three skills have no template that shows their idea in a second way
honestly, so they get **authored story items** (a character's problem told in words, R3 of §5.5), which the approved plan
allows without an owner decision. G7 adds them to the lint's story list.

| Skill | Why no template fits | What it gets now | Template proposal (later, optional) |
|---|---|---|---|
| NUM-A-12 | No template counts two groups by touch and then compares them; a balance would teach "big = heavy" (M-MEAS-BIG) | 2 stories: a character's claim that the bigger or spread-out group is "more", judged by the child (U5, the Band A "oops" form) | **TP-1 pair_drag**: drag each thing of one group onto one of the other; the leftovers glow; then tap where there are more. It is the catalogue's R1 repair for M-CNT-SIZE and would also serve NUM-A-11, MATH-A-07 and MATH-B-19 |
| LOG-A-07 | Fixing a pattern by hand needs a row with one wrong piece to swap; `build_pattern` has no pre-filled places, and a broken row as its model would make the hint light the wrong piece | 2 stories: a member of the line leaves (a fish swims away, the wind takes a balloon) and the child says who comes back | **TP-2 build_pattern fix mode**: places pre-filled from the model, one wrong; the child swaps it |
| COL-B-01 | No paint-mixing template (the catalogue's repair: a tub, predict, mix, see) | 2 stories: a character wants a colour and chooses the paint, or predicts the mix | **TP-3 mix tub**: drag two paints into a tub, predict, then see the mix |

Three more skills get an existing template whose fit is fair, not strong. They need no decision now; the proposal is for later.

| Skill | What it gets | The weak point | Template proposal (later, optional) |
|---|---|---|---|
| NUM-A-05, NUM-A-10 | give_n "put 2 (3, 4, 5) in the bowl": making a small set, the "maker of small collections" level of the subitising trajectory | a child can count out instead of seeing the number, so the evidence is weaker | **TP-4 flash then make**: a group flashes, then the child makes the same number |
| CS-B-04 | robot direct: from where a buggy program left it, the child brings the robot to the flag the short way | the program itself is not shown on the board | **TP-5 robot debug mode**: a stored program runs and stops at the surprise; the child taps the wrong arrow and fixes it (§5.5 ladder 3, check U5) |
| NUM-B-17 | counting by twos twice (socks; jumps of two) | counting by tens has no picture: the number line has no tick step, and 0 to 100 has 101 ticks | **TP-6** a `tickStep` on `number_line` (10s on 0 to 100) |

## 5. Totals

| Land | Band A skills | Band A items | Band B skills | Band B items | Items |
|---|---|---|---|---|---|
| Numbers | 9 | 18 | 13 | 26 | 44 |
| Colours | 4 | 8 | 3 | 6 | 14 |
| Shapes | 7 | 14 | 6 | 12 | 26 |
| Logic | 8 | 16 | 6 | 12 | 28 |
| Robots (CS) | 3 | 6 | 1 | 2 | 8 |
| Maths and money | 6 | 12 | 9 | 18 | 30 |
| **All** | **37** | **74** | **38** | **76** | **150** |

**By template** (counted from the tables, section 9): sort_drag sort 48, tap_answer 37 (6 of them stories), build_pattern 24,
number_line 9, balance 6, count_tap 6, give_n 4, sort_drag share 4, spot_error 4, robot_path 4, shop_pay 2, trace 2.
**By representation added:** concrete 96, pictorial 42, story 6, symbolic 4, embodied 2.
**Lessons:** 130 items join 60 existing lessons; 8 new continuation lessons hold the other 20: Band A `more-glances-1-b36` (4),
`more-queues-and-zero-1-b36` (4), `copy-patterns-1-b36` (2), `build-with-shapes-1-b36` (2), `big-small-long-heavy-1-b36` (2);
Band B `days-of-the-week-1-b36`, `one-more-one-less-1-b36`, `tens-and-twos-1-b36` (2 each). The largest lessons after this:
Band A 8 (`same-and-different-again-1-b15`, `my-day`), Band B 12 (`give-up-to-20`, `pairs`, `rocket-countdown`).
**Activities in the pack after part D:** 968 + 150 = 1,118 (plus whatever parts B and C append); `content_lints_test` pins the
count (part G).

## 6. New pictures (design-director)

**15 new sprites**, drawn as originals in the pack's style (look at real references first, as for the coins), plus 3 drawing
rules and 4 checks.

| # | Sprite(s) | For | What it must show |
|---|---|---|---|
| D1 | `outline_triangle_down`, `outline_square_tilt` | SHP-A-06 | an empty dashed outline (the "shadow" of the shape builder), turned; no colour, so colour gives nothing away |
| D2 | `pos_cat_under`, `pos_cat_above` | SHP-A-08 | the B-38 cat and basket: the cat under the basket, the cat above it (not touching), the basket in the same place as in `pos_cat_on` |
| D3 | `glyph_3`, `glyph_3_rev`, `glyph_8`, `glyph_7`, `glyph_7_rev`, `glyph_1` | NUM-B-07 | the numerals in the trace stroke style; `_rev` is the exact mirror image; all the same size and weight, so only the direction differs |
| D4 | `shape_open_quad` | SHP-B-04 | four straight sides with one clear gap at a corner, like `shape_open` |
| D5 | `obj_can`, `obj_drum`, `obj_party_hat`, `obj_gift` | SHP-B-08 | a tin can and a toy drum (cylinders), a party hat (cone), a wrapped gift (box, not a cube); plain, one object each |
| D6 | rule: an empty set | NUM-A-14, MATH-B-07 | a set or group of 0 shows an empty ten-frame (or empty plate), on a tile and on the stage (with G6) |
| D7 | rule: numbered places | the order-in-time builds (LOG-A-08, CS-A-01, MATH-A-05, MATH-B-14) | places show 1, 2, 3 (4), left to right (plan B-40 §12.1) |
| D8 | rule: Band A balance | NUM-A-11 | pans and blocks big enough for a 3-year-old's tap; the level beam must read as "the same" |
| C1–C4 | checks | SHP-A-05, NUM-B-05, MATH-B-06, SHP-A-07 | `coin` and `paper` read as a circle and a rectangle; three tiles of two ten-frames fit the phone; ten blocks fit one pan; `block` reads as a cube that stacks |

## 7. New Hebrew (hebrew-text-editor)

All `needs-editor`, words by the editor, final before the B-45 voicing. Roughly 150 prompts (about 45 are an existing pattern
with new values), 150 correct lines, about 60 own h3 lines (every build without a model, the stories, the trace, the
balance, the shop items), about 60 bin labels, the Hebrew names of the 15 new sprites, and 3 own tag lines: COL-B-02 (M-SER-ENDS
for shades), COL-B-03 (M-COL-SHADE naming no colour), SHP-A-07 (M-SHP-NAME: rolls and stacks). Band A rules: one instruction,
no right or left, no "לֹא" question, no speed word. Band A balance, no-model builds and robot plans need their hint lines (G8).
The NUM-B-08 prompts must not say the number. The NUM-B-18 correct line names "even" (`זוּגִי`).

## 8. Risks

| Risk | What we do |
|---|---|
| **Difficulty shifts.** Some new forms are harder than the skill's usual one: counting 8 to 16 without touching (NUM-A-09, NUM-B-04), the first balance in Band A (NUM-A-11), builds of 6 to 8 places (LOG-A-04, LOG-A-06, LOG-B-01), two facts in one Band A prompt (NUM-A-13, LOG-A-05) | authored difficulty = the median of the skill's items, +0.05 for a template the child meets for the first time in that land, −0.05 for count and give items the child knows; the M3 simulator runs on the new pack (plan §8); the owner's phone test watches NUM-A-11 and NUM-A-13 with the younger child |
| **Mastery thresholds.** None of the 75 skills is core, so fresh mastery needs 1 representation and 1 check (`params.dart`): the new items add successes and check types (reverse, predict, error_spotting) and cannot block mastery. `mastery_reachable_test` with `QA_OPEN=true` should stay 100 of 100 | the app-developer runs it; any skill that drops comes back to me |
| **Evidence spread to another skill.** NUM-A-05 and NUM-A-10 give items count for NUM-A-06 at 0.5; CS-A-03 plans for CS-A-04 at 0.5 | small weights, by design (B-15 G3); a child who counts out instead of subitising still gets NUM-A-05 credit (TP-4 later) |
| **The engine's choices change.** The representation bandit (`representation.dart`) now has two ways for 75 skills, and the switching rule (after 2 errors the next item uses another representation, §5.5) can work at last. Band A priors favour concrete, so the new sorts and builds will be chosen often | that is the intent (Ainsworth 2006); QA checks every new tag has a line and a re-teach |
| **Hands-on is not automatically understood.** Children can treat a manipulative as an object, not a symbol for the idea (Uttal, Scudder & DeLoache 1997); manipulatives help most with guidance (Carbonneau, Marley & Selig 2013) | every concrete item keeps a spoken rule and the B-40 ladder; the second item of each skill is a transfer |
| **Part dependencies.** Items with the 8 new tags need part C first; LOG-A-09 needs part E for `graph.report()` to be empty; MATH-A-01/02, MATH-B-07/08 use part B's M-CNT-CARD lines | build order: A, B, C, then D, then E (plan §4) |
| **Even only.** NUM-B-18's share items can only show even numbers | its tap items keep the odd cases |
| **Story items** (NUM-A-12, LOG-A-07, COL-B-01) are close to their pictorial items in look; the story is the difference | evidence on story framing for these skills is thin; TP-1 to TP-3 are the stronger forms |
| **Lesson length.** Band B lessons of 12 items at the cap | the continuation lessons above; 2-item continuation lessons are short, as in B-15 |

## 9. Self-check

Run on this file's tables (a script parses the 150 rows of sections 2 and 3) against `content/starter` of this branch,
2026-11-01.

- **The list is the right one:** the rows name exactly the 75 skills that `graph.report()`'s rule finds (a skill whose items, by
  any weight, use one representation); none is missing, none is extra. 150 ids, all distinct, none already in the pack.
- **Every skill has 2 or more representations after these items: yes, 75 of 75.** For every skill the label its new items add is
  not among the labels its items have today, so each skill ends with exactly 2. With part E (LOG-A-09's prerequisite),
  `graph.report()` is then empty.
- **Every new wrong answer carries a tag: yes.** Every choice item with 3 options has 2 tagged wrong answers (distinct tags,
  or E1 where the skill watches one misconception: NUM-A-14, COL-B-01, MATH-B-07 item 1; SHP-A-06 item 1, whose skill watches
  no tag yet, follows the B-15 precedent `b15.shpa01.1`, two M-SHP-ORIENT); every 2-option item
  tags its wrong answer; every drag, build, balance, number line, robot, shop and spot item has its answer tag. The 2 trace
  items (SHP-B-02) have no wrong answer to tag.
- **Counts:** Band A 74, Band B 76; by land as in section 5. No existing lesson passes 8 items (Band A) or 12 (Band B).
- **Lines:** every tag named has a line in the pack or in part B or C, and each line was checked to be true for the item (the
  sort lures by colour where the shared M-SORT-SHIFT line says "the same colour"; own lines where a shared one would be wrong:
  COL-B-02, COL-B-03, SHP-A-07).

## 10. Found on the way (existing content, not part D)

- **COL-B-02** `b.colb02.9` to `.12` (the middle shade): the M-SER-ENDS line says "not the smallest and not the biggest", size
  words for a shade task. Give them the own line of `b.colb02.13` (`tag_lines`).
- **COL-B-03** green, red and purple items (`b.colb03.3` to `.8`, `.10`): the M-COL-SHADE line says "light blue and dark blue
  are both blue". Give them the colour-free line of `b.colb03.11`.
- The shared M-SORT-SHIFT lines for a shape or kind rule start "it is the same colour, but…": true only when the misplaced
  picture has the colour of the wrong bin. Every new sort above is built so; a lint for it would help (qa-engineer).

## 11. Hand-offs (for the board)

- **app-developer:** G1 to G6 and G9, then the 150 items in `content/units/*.json` (Band A) and `tools/band_b*.py` (Band B),
  each appended and in its lesson; regenerate; `graph.report()` empty once part E is in; mastery 100 of 100 with
  `QA_OPEN=true`, remove the skip.
- **design-director:** D1 to D8 and C1 to C4 (section 6).
- **hebrew-text-editor:** section 7, and the two line fixes of section 10.
- **qa-engineer:** G7 (story list); at part H, a sample of every new kind at all three hint levels on phone, SE and tablet.
- **owner:** nothing to decide for part D. TP-1 to TP-6 are optional later proposals.

## 12. Sources

- Ainsworth, S. (2006). DeFT: a conceptual framework for learning with multiple representations. *Learning and Instruction*, 16, 183–198.
- Fyfe, E. R., McNeil, N. M., Son, J. Y., & Goldstone, R. L. (2014). Concreteness fading in mathematics and science instruction. *Educational Psychology Review*, 26, 9–25.
- Clements, D. H., & Sarama, J. (2014). *Learning and teaching early math: the learning trajectories approach* (2nd ed.). Routledge (subitising: the "maker of small collections"; comparing by matching).
- Siegler, R. S., & Ramani, G. B. (2008). Playing linear numerical board games promotes low-income children's numerical development. *Developmental Science*, 11, 655–661.
- Rittle-Johnson, B., Fyfe, E. R., Loehr, A. M., & Miller, M. R. (2015). Beyond numeracy in preschool: adding patterns to the equation. *Early Childhood Research Quarterly*, 31, 101–112 (the repeating unit).
- Fischer, J.-P. (2011). Mirror writing of digits and (capital) letters in the typically developing child. *Cortex*, 47, 759–762 ([PubMed 21377665](https://www.pubmed.gov/21377665/)): 5 to 6 year olds reverse mainly the left-facing digits 1, 2, 3, 7 and 9. I read the abstract and a summary only; the studies are of children who write left to right, and whether Hebrew readers reverse the same digits is open.
- Nelson, K. (1986). *Event knowledge: structure and function in development.* Erlbaum (routines as scripts).
- Bers, M. U. (2020). *Coding as a playground* (2nd ed.). Routledge (sequencing cards, debugging by stepping).
- Uttal, D. H., Scudder, K. V., & DeLoache, J. S. (1997). Manipulatives as symbols: a new perspective on the use of concrete objects to teach mathematics. *Journal of Applied Developmental Psychology*, 18, 37–54.
- Carbonneau, K. J., Marley, S. C., & Selig, J. P. (2013). A meta-analysis of the efficacy of teaching mathematics with concrete manipulatives. *Journal of Educational Psychology*, 105, 380–400.
- Carpenter, T. P., Fennema, E., Franke, M. L., Levi, L., & Empson, S. B. (2015). *Children's mathematics: cognitively guided instruction* (2nd ed.). Heinemann (join, separate and part-whole stories).
