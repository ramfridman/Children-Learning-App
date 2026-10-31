# B-40: a visual hint ladder for every activity (plan, step 1)

**Status:** a plan for the owner's approval. No code and no content have changed. Author: the curriculum-expert, 2026-10-30.
**Measured on:** branch `b34-bubble-mouth` (main e051746 plus a home-screen fix). Starter pack 0.10.0: 967 activities, 15 templates. Code read: `app/lib/play/*_session.dart`, `lesson_controller.dart`, `content/models.dart`. Content read: `content/starter/activity.*.json`, the schemas, and `tools/author.py` and `tools/band_b*.py`, where the hint actions are set.
**The owner's finding (2026-10-30):** after several wrong answers, most lessons give no visual hint and no visual guidance. Only some do.

---

## 0. In one paragraph

Only **70 of 967** activities (count_tap and give_n) have a ladder whose picture changes at each level without showing the answer early, and **35** of those 70 draw the wrong number of fingers. **635** activities (66%) draw nothing at any hint level: 625 of the 626 `tap_answer` and 10 of the 20 `balance`. **211** more draw a picture, but it is the answer (or one step of it) at hint 1 or 2: sort, pattern, match, shape builder, number line, robot, shop, clock, balance with a hidden tilt, and spot-the-error. This breaks PLAN.md: "never reveal the answer before the third hint". **42** show the same picture at every level (flash 16, trace 26). On top of this, the engine shows no picture at the first mistake, and with 3 choices the second mistake leaves only the answer untried, so in practice the ladder arrives after the answer is already forced (audit F12). The plan has five parts:
1. One shared set of 12 hint pictures.
2. A level-aware hint in every template: look here, then another way or together, then watch me and you finish.
3. Twelve picture families for `tap_answer`.
4. Moving every picture that marks the answer to level 3, where it becomes the last step of a demonstration.
5. Fixing the finger hand first, because it shows a wrong number.

---

## 1. The rule this plan designs to

| Level | What the child gets | Picture rule | Source of the rule |
|---|---|---|---|
| 1 **Look here** | The prompt again, slower. A sky-blue halo shows *where to look*: the gap, the group, the start, the model, the rule. | It may light the parts of the *question*. It never marks or dims an answer option. | PLAN.md (slower replay); curriculum §5.5 ("H1 may replay slowly"); signalling and cueing research |
| 2 **Another way, or together** | The same problem in a new representation (fingers, ten-frame, number path, pairing lines, rule card, swatch), or the guide does the *first step* of the procedure and hands back. | It changes the representation or adds a model (§5.5, §9.2). It may leave the child one small step, such as counting the leftovers. It never shows the final answer. | §5.5 switching rule; concrete-pictorial-abstract and concreteness fading |
| 3 **Watch me, then you** | A worked example: the guide's pointer runs the whole process with the words, and the answer appears only as the **last** step. Then the turn comes back and the child makes the final move. | The answer is the end of a demonstration, never the first thing shown. | PLAN.md; §9.2 ("the child then makes the final correct action themselves"); worked-example research |

**Shared constraints:**
- A hint is a sky-blue halo (`TokenColors.hintHalo`, `skyTint`), never red.
- No timer and no countdown. Every cue is short motion that comes to rest. With reduce-motion on, a still version of the same picture is shown.
- The words of the hint describe exactly what is drawn. A line that says "this one" needs a pointer on screen.
- Colour never carries the answer outside Colour Bay.
- Numbers, number paths, every row in the stage (patterns, growing patterns, sequences, orders in time) and robot arrows are drawn left to right in an LTR isolate, with the gap or the next slot at the right end. They are never mirrored (decided 2026-10-30, §12.1).

**How the ladder is reached today** (`lesson_controller.dart`):
- **Hint 1** comes only from the lamp or from "show me".
- **The 1st mistake** gets the diagnostic line only, with no picture.
- **The 2nd mistake** gets hint 2.
- **The 3rd mistake** gets hint 3, and the activity becomes `guided`.
- **The effect:**
  - With 3 choices (510 `tap_answer`), the 2nd mistake leaves one untried choice.
  - With 2 choices (106), the answer is known after one mistake, yet 105 of them still allow 3 attempts, against §9.2 ("one retry").

So the picture must come earlier (owner question 1), and it must explain *why*, not *which*.

---

## 2. Today's state (measured)

### 2.1 What each template draws for a hint (code)

| Template | n | What `onHint` draws (the same at every level unless noted) | L1 | L2 | L3 |
|---|---|---|---|---|---|
| tap_answer | 626 | It pulses the choices in turn, but only choices drawn on the stage pulse. 625 have their choices on tiles (`optionsInTiles`), so nothing moves. After the 3rd mistake the right tile gets the halo and the others dim, with no demonstration. | none | none | none (answer halo only) |
| count_tap | 44 | L1: each object wiggles in turn. L2: a finger hand. L3: the guide counts every object and hands back. | look | fingers* | demo |
| give_n | 26 | L1: every object in the pile wiggles. L2: a finger hand. L3: the guide gives N and puts them back. | weak | fingers* | demo |
| flash | 16 | The group is shown again for twice as long; L3 keeps it on. `show_fingers` at L2 is ignored. | same | same | same |
| trace | 26 | A dot walks along the next stroke. | same | same | same |
| sort_drag (sort) | 25 | The first picture in the tray **and its bin** get the halo. | answer | answer | answer |
| sort_drag (share) | 8 | L1 and L2: nothing. L3: the guide deals the pictures. | none | none | demo |
| build_pattern | 15 | The next slot **and the right palette tile**. | answer | answer | answer |
| match_pairs | 17 | The next unmatched **pair**. | answer | answer | answer |
| shape_builder | 7 | The next slot **and the piece that fits**. | answer | answer | answer |
| number_line | 25 | The marker walks from the start **to the target**, leaving a trail. | answer | answer | demo |
| robot_path | 22 | L1 and L2: the next arrow card lights (one step of the solution). L3: the robot runs the solution. | step | step | demo |
| shop_pay | 11 | The **coins of the solution** get the halo. | answer | answer | answer |
| clock_set | 8 | Faint **target hands** on the dial. | answer | answer | answer |
| balance | 20 | `revealed = true`. 10 compare items with a hidden tilt: the beam leans (the answer). 6 compare items with the tilt already visible, and 4 weigh items: nothing changes. | answer / none | answer / none | answer / none |
| spot_error | 71 | L1: nothing. L2 and L3: the **wrong cell** gets a ring (the answer). Meanwhile the hint-2 text says "look slowly, step by step". | none | answer | answer |

\* **Wrong content.** `FingersHint` (`count_tap_session.dart`) has one hand of five fingers. For counts of 6 to 20 it raises five and stays there, while the voice counts on to 7 or 18. This affects 35 activities: count_tap NUM-A-02 ×3, NUM-A-09 ×10, NUM-B-04 ×11 and MATH-B-01 ×1, and give_n NUM-B-05 ×10. The ids are in appendix C.

### 2.2 Counts per template

The columns sum to 967. "Ladder fits" means a different picture at each level with no answer before L3.

| Template | n | No visual at any level | Answer (or a step) before L3 | Same picture at every level | Ladder fits | Note |
|---|---|---|---|---|---|---|
| tap_answer | 626 | **625** | 0 | 0 | 0 | 1 more (`pick.red.flower`) has one hint only, a stage pulse |
| spot_error | 71 | 0 | **71** | 0 | 0 | the answer at L2 |
| count_tap | 44 | 0 | 0 | 0 | 44 | 25 with the finger bug |
| sort_drag | 33 | 0 | **25** | 0 | 0 | the 8 share items have a picture at L3 only |
| trace | 26 | 0 | 0 | 26 | 0 | the right picture, no progression |
| give_n | 26 | 0 | 0 | 0 | 26 | L1 weak; 10 with the finger bug |
| number_line | 25 | 0 | **25** | 0 | 0 | full demo at L1 |
| robot_path | 22 | 0 | **22** | 0 | 0 | one step at L1 |
| balance | 20 | **10** | **10** | 0 | 0 | |
| match_pairs | 17 | 0 | **17** | 0 | 0 | |
| flash | 16 | 0 | 0 | 16 | 0 | |
| build_pattern | 15 | 0 | **15** | 0 | 0 | |
| shop_pay | 11 | 0 | **11** | 0 | 0 | |
| clock_set | 8 | 0 | **8** | 0 | 0 | |
| shape_builder | 7 | 0 | **7** | 0 | 0 | |
| **Total** | **967** | **635** | **211** | **42** | **70** | +8 share, +1 one-hint |

### 2.3 Per land and band

| Land | Band | n | No visual at any level | Answer before L3 | Fits |
|---|---|---|---|---|---|
| Counting Hills (NUM) | A | 139 | 68 | 14 | 41 |
| | B | 175 | 99 | 35 | 21 |
| Colour Bay (COL) | A | 66 | 53 | 12 | 0 |
| | B | 42 | 31 | 11 | 0 |
| Shape Forest (SHP) | A | 79 | 60 | 13 | 0 |
| | B | 51 | 42 | 9 | 0 |
| Riddle Grotto (LOG) | A | 84 | 63 | 21 | 0 |
| | B | 51 | 32 | 19 | 0 |
| Robot Harbour (CS) | A | 32 | 16 | 16 | 0 |
| | B | 16 | 2 | 14 | 0 |
| Market Village (MATH) | A | 54 | 40 | 0 | 6 |
| | B | 178 | 129 | 47 | 2 |
| **Band A** | | **454** | **300** | **76** | 47 |
| **Band B** | | **513** | **335** | **135** | 23 |

"Fits" is count_tap plus give_n, as in §2.2; it includes the 35 with the finger bug. Trace (26) and flash (16) are not counted there, because they show the same picture at every level.

### 2.4 The hint texts that go with these pictures

- **Hint 2 is a generic line on 619 activities.** 503 use "נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד" and 116 use "נִסְתַּכֵּל לְאַט, צַעַד אַחַר צַעַד". That includes number sentences, days of the week and words, where there is nothing to "look at one by one" (audit F12).
- **128 hint-3 lines point with words and nothing on screen** ("זֶה פֶּרַח צָהֹב… לִלְחֹץ עָלָיו"): 127 in tap_answer and 1 in flash. The child cannot know which one "this" is.
- **About 289 hint-3 lines state the answer in four words or fewer before "עַכְשָׁו תּוֹרְכֶם".** That is an answer, not a worked example: tap_answer 231, spot_error 23, flash 16, build_pattern 8, balance 8, robot 2, give_n 1. The count is a heuristic: four words or fewer before "עַכְשָׁו".
- **spot_error has text and picture the wrong way round.** The hint-2 text does not reveal the answer, but the hint-2 picture rings it.

---

## 3. One shared set of hint pictures

Today the schema has four actions (`replay_prompt_slow`, `highlight_objects_sequentially`, `show_fingers`, `worked_example`), and each template ignores most of them. This plan proposes one set of pictures that every template draws in its own stage, so a family is built once and reused. The exact names, and whether they become new `action` values or a `show` field with a `target`, are the app-developer's choice. The schema then gets a template version bump.

| # | Hint picture | What it draws | Level | Exists today |
|---|---|---|---|---|
| P1 | **spotlight(target)** | A sky-blue halo on a part of the question (gap, group, model, start, goal, price, hour hand, rule); the rest dims slightly | 1 | colour token only |
| P2 | **light_each(target)** | Lights the things one at a time, in order, with the count or name words. Targets: objects, cells, sides and corners, ticks, columns, program steps | 1–2 | count_tap wiggle only |
| P3 | **fingers(n)** | Two hands up to 10, in the 5-and-k structure. Above 10 it becomes P4 | 2 | one hand, wrong above 5 |
| P4 | **ten_frame** | Regroups a set into one or two ten-frames (or a dice pattern for ≤6) | 2 | `sprite_group` has `ten_frame` and `dice` layouts |
| P5 | **pair_lines** | One-to-one lines between two rows, sets or columns; the unpaired ones glow | 2 | none |
| P6 | **number_path** | A numbered strip, left to right, with the given numbers marked and hop arcs | 1–3 | the number_line stage only |
| P7 | **core_box** | Brackets around the repeating unit, with the unit's copies lined up under each other | 2 | none |
| P8 | **baseline** | Slides items to a common start line, or a common floor | 1–2 | none |
| P9 | **sample** | The attribute on its own: a colour swatch, a ghost shape outline, a rule card (`rule_colour`, `rule_shape`, `rule_size` exist), a coin's value | 2 | rule-card sprites only |
| P10 | **act_out** | A tiny scene that acts out a word: under or on a box, a ball rolling, two paints poured, the sun's path through the day | 2 | none |
| P11 | **first_step** | The guide does step 1 of the procedure (one hop, one arrow, one coin, one sorted picture, one slot) and hands back | 2 | robot step; others draw the full answer |
| P12 | **pointer_demo** | The worked example: a pointing hand runs the process in time with the hint-3 words, the answer appears last, then the scene resets for the child | 3 | count_tap, give_n, robot, share and trace have demos without a pointer |

**The guided state** (after the 3rd mistake) should begin with P12. The halo on the right tile and the dimming of the others come only at the end of the demonstration, not instead of it (owner question 3).

---

## 4. The ladder per template

These are the defaults. Where the best picture for a skill differs from the default, it is listed in §6. The size is the app work only, after the shared pictures exist: S ≤ 0.5 day, M 1–2 days, L 3–5 days.

| Template (n) | L1 look here | L2 another way / together | L3 watch me, then you | Size |
|---|---|---|---|---|
| **tap_answer** (626) | By family, §5 | By family, §5 | By family, §5: P12 with the pointer, the answer last | L in total; S–M per family |
| **count_tap** (44) | Keep: light each object in turn (P2) | **P3** two hands up to 10 (NUM-A-09, NUM-A-02); **P4** two ten-frames for 11–20 (NUM-B-04) | Keep the demo; add the pointer, and hold the last number word ("…seven: seven ladybugs") (cardinality) | S |
| **give_n** (26) | Replace the whole-pile wiggle: **spotlight** the plate, and show N as a numeral with its dots beside it (the goal) | P3 (≤10) or **P4** with N empty cells on the plate (11–20) | Keep the demo, with the pointer and the count words | S |
| **flash** (16) | Keep: show the group again, longer | **Representation change:** NUM-A-10 shows the same number as a finger pattern (P3); NUM-A-05 lines the dots up in a row (P2) | The group stays; each dot is lit and counted (P2), then the dots "hug" into one group; the numeral tile glows last | S |
| **trace** (26) | The start dot and the first arrow pulse; only the **first segment** lights (where and which way) | Today's walking dot over the whole stroke, slower, leaving a sky-blue trail | The guide traces the whole numeral or shape stroke by stroke with the words ("down, then round"); the trail fades and the child traces | S |
| **sort_drag, sort** (25) | **spotlight** each bin's sample picture in turn, and the rule card (P9) when the rule is given | **P9 sample:** the next picture's relevant attribute (its colour, outline or kind) beside each bin's, compared in turn; no bin is marked | P12: the guide sorts **one** picture, saying why ("red, so to the red box"), then hands back | M |
| **sort_drag, share** (8) | **spotlight** the friends' plates one at a time ("one for each") | **P11:** the guide deals the first round only (one each) and stops | Keep the deal demo; add the pointer | S |
| **build_pattern** (15) | **light_each** of the model or row in rhythm, ending on the next empty slot (where, not what) | **P7 core_box** on the unit; for copy items, the model cell that lines up with the next slot gets the halo (one-to-one copying) | P12: read the row aloud, the unit slides to the gap, the next piece appears in the slot, the turn comes back | M |
| **match_pairs** (17) | **spotlight** the first unmatched left card ("start with this one") | Representation change per skill (§6): dots under the numeral (NUM-A-07), the coin's value (MATH-B-16), the solid "stamps" its face (SHP-B-09) | P12: the guide draws **one** line, saying why, and hands back | M |
| **shape_builder** (7) | **spotlight** the next empty outline (where) | **P9:** that outline lifts off as a ghost, turns slowly and floats beside the tray; the child compares | P12: one piece flies into its slot, then the turn comes back | S |
| **number_line** (25) | Place mode: **spotlight** 0, the direction arrow and the landmark ticks (0, 5, 10). Jump mode: the start tick and the hop size as fingers or dots | **P11:** the marker hops **one** unit from 0 (place) or from the start (jump), counting, and stops | Keep the walk to the target, with the pointer and the count; reset | S |
| **robot_path** (22) | **spotlight** the robot's face (its heading) and the goal; Band A also the landmark | **P11:** today's next-arrow light plus a ghost robot doing that one step (level 2 only) | Keep the run; add a numbered footprint per step; reset | S |
| **shop_pay** (11) | **spotlight** the price tag, with the price as that many ₪1 dots under it | **P11:** the guide puts the **largest coin that fits** on the counter, says the running total, stops | P12: the coins go on one by one with the running total ("five… seven… eight shekels"), then return; the child pays | M |
| **clock_set** (8) | **spotlight** the short hand (the one to move) and the 12 for the long hand ("the long hand stays on 12") | **P9:** the numeral from the question gets a halo on the dial ("find the 3 on the clock") | P12: the short hand sweeps from 12 to the number, counting the hours, then resets | S |
| **balance** (20) | Compare: **light_each** on the blocks of the left pan, then the right (P2). Tilt already shown: a level line across the beam makes the tilt visible | Compare: **P5** pairs the blocks of the two pans. Equations (MATH-B-09): cubes appear above each number. Weigh: pair lines show what is missing, and the child counts | P12: the beam is released slowly ("the scale tells us"), then the child taps; weigh: the blocks go on one by one | M |
| **spot_error** (71) | **light_each** across the row, in reading order, with the words of the rule (count, pattern, program) | By family, §5.2; no cell is marked | P12: the walk stops at the wrong cell, shows what should be there beside it, then the turn comes back | M |

---

## 5. Picture families inside the templates that hold many skills

### 5.1 tap_answer: 12 families (626 activities)

| Family (A / B) | Skills | L1 look here | L2 another way / together | L3 watch me (answer last) |
|---|---|---|---|---|
| **TA-1 Count a group → numeral** (20 / 12) | NUM-A-03, A-04, A-07 (set→numeral), A-14, MATH-A-06, SHP-B-02, CS-A-04, CS-B-01 (steps to the flag) | P2: each object, side or square lights in turn (a start dot for sides, M-CNT-DOUBLE) | P3 fingers ≤10 or P4 regroup to a dice or ten-frame pattern; zero (NUM-A-14): an empty ten-frame | Pointer counts all, holds the last word, then the matching tile glows |
| **TA-2 Numeral named / numeral → set** (12 / 14) | NUM-A-07 (numeral→set), NUM-A-08, NUM-B-08 | P1 on the numeral, with its dots appearing beside it | Band A: P6 a 1–5 path walks to N. NUM-B-08 teens: P4 a full ten-frame plus ones, with "1" under the ten and the ones digit under the ones (M-NUM-REV, M-NUM-TEEN) | The quantity is built, then the pointer goes to the tile or set that matches |
| **TA-3 Number sequence and position** (22 / 44) | NUM-A-01, A-02, A-13 (ordinal), NUM-B-01, B-02, B-03, B-11, B-17 | P6 the path appears, and the given numbers light as they are said, from the start (or the start of the line for ordinals) | Band A: P3 fingers in time. B-02: the 19→20 or 29→30 crossing marked. B-17: a hundred-chart column or hops of 10 and 2. B-03: the path walks backwards. Ordinal: labels "first, second…" | The walk lands on the gap; the number or picture glows last |
| **TA-4 Compare quantities** (26 / 31) | NUM-A-11, A-12, MATH-A-07, NUM-B-10, NUM-B-18, MATH-B-19 | P8: the two groups line up in two rows with equal spacing (removes the size cue, M-CNT-SIZE); for charts, columns on one floor | P5 pair lines, the unpaired glow. NUM-B-10 (no objects): two cube towers. NUM-B-18: pair into twos, the lone one glows | Pairs drawn one by one, the leftovers counted, then the right choice glows |
| **TA-5 Add, take away, part-whole** (16 / 106) | MATH-A-01, A-02, MATH-B-01, B-02, B-03, B-06, B-07, B-08, B-10, B-18, NUM-B-14, NUM-B-16 | Replay the action (the bird lands, the fish swims away). For sentences: P1 on the operation sign (M-EQ-OPER, M-SUB-ORDER) | Band A: P3 fingers join or fold. B-01: count on (the first group "hugs" into its number, the rest light on). B-06, B-08, B-16: P4 ten-frames (fill to ten). B-02, B-18: part-whole (the known part shaded, the empties counted). B-03: cubes above the numbers. B-10: skip-count labels | P12 with the same picture as L2, ending on the result; the tile glows last |
| **TA-6 Colour** (54 / 31) | COL-A-01…07, COL-B-01, B-02, B-03 | P2 the tiles lit in turn with the colour word said slowly. COL-A-01 match: P1 on the model | P9 a swatch of the named colour beside the guide (naming → matching, the prerequisite COL-A-01). A-07 two attributes: the non-dolls fade first (noun), the colour comes later. B-01: a colour wheel with the mix slot empty between its two parents. B-02, B-03: a light-to-dark shade strip | The swatch slides over each tile and sticks to the match. B-01: pour, stir, the colour appears, then the tile glows |
| **TA-7 Shapes and space** (60 / 32) | SHP-A-01…05, A-07, A-08, A-10, SHP-B-01, B-03, B-04, B-08, B-09 | A-01: P1 on the model. Naming: P2 the tiles in turn with the name | P9 a ghost outline of the named shape (A-03: it turns to every orientation). B-01, B-03: corners or sides lit and counted, equal sides ticked. A-10: a straight stick laid along each line. A-07: a ball rolls, a box stands (P10). A-08: the guide acts "under" or "on" with a box (P10). B-08: the solid turns slowly and shows its faces | The outline or stick slides over each option and fits the right one; the tile glows |
| **TA-8 Pattern and order rows** (28 / 18) | LOG-A-04, A-06, A-07, A-10, LOG-B-01, B-04 | P2 the row lit in rhythm from the left, ending on the "?" | P7 core_box (A-04: "does a unit repeat?"). B-04 growing: counts under each step (1, 2, 3). Seriation A-10: P8 baseline, then neighbours compared | Read the row aloud, the unit slides to the gap, the right picture appears; the tile glows |
| **TA-9 Same, odd one out, rules** (27 / 14) | LOG-A-01, A-02, A-03, A-09, LOG-B-06, B-09 | P1 on the model, or on the whole group ("which one is different?") | P9 rule card (colour, shape or size) beside the group, and each option compared to the model in turn. B-09: the first clue applied (those that are red fade) | The second clue, or the comparison, finishes; the one left glows |
| **TA-10 Order in time** (28 / 11) | CS-A-01, CS-A-05, LOG-A-08, MATH-A-05, MATH-B-14 | P1 on the first picture or the start ("what happens first?") | P6-style timeline: 3 or 4 numbered slots, left to right. MATH-A-05: the sun's path across the sky (P10). MATH-B-14: a week strip of 7 day cards | The guide walks the timeline with the words; the missing or wrong step glows last |
| **TA-11 Measure** (8 / 0) | MATH-A-04 | P8: the objects slide to one start line or floor (M-MEAS-ALIGN) | Long and short: a stick of cubes along each. Heavy and light: a small seesaw (P10) | The comparison is made; the tile glows |
| **TA-12 Clock and money** (0 / 12) | MATH-B-15, MATH-B-16 | Clock: P1 on the short, thick hand, with the long hand faded (M-CLOCK-HANDS). Coin: the coin grows and turns to show its number | Clock: the short hand extends as a dotted ray to its numeral. Coin: its value beside a same-size coin of another value (M-MONEY-SIZE) | Pointer along the hand to the number, said aloud, then the tile glows |

### 5.2 spot_error: 5 families (71 activities)

| Family (n) | Skills | L1 | L2 | L3 |
|---|---|---|---|---|
| Count and sequence rows (21) | NUM-A-01, A-02, A-03, A-08, NUM-B-03, B-11, B-17 | P2 each cell read in order | P6 a correct number path under the row, cell by cell, so the mismatch is visible but not marked | The walk stops at the cell, shows the right number beside it, then the turn comes back |
| Pattern rows (13) | LOG-A-04, A-07, LOG-B-02, B-11, COL-B-06 | P2 the row in rhythm | P7 core_box on each repeat (the broken unit stands out); seriation and rainbow: P8 baseline or the colour order strip | As above |
| Sort errors (21) | COL-A-02, A-03, A-06, COL-B-04, LOG-A-01, LOG-B-06, SHP-A-02, A-03, SHP-B-01, B-03, B-04, B-08 | P1 on the rule ("only circles") | P9 the rule card or swatch beside each cell in turn | As above |
| Number sentences (8) | MATH-B-03, MATH-B-09 | P1 on the operation and equals signs | Cubes above each number; for =, a balance picture | As above |
| Programs (8) | CS-A-05, CS-B-04 | P2 the steps lit in order; the robot ghost follows them | P7 core_box on the program's repeat ("up, right") | As above |

---

## 6. Skills whose best picture differs from the template default

| Skill (template, n) | Different picture, and why |
|---|---|
| NUM-A-09, NUM-A-02 (count_tap, 13) | L2: two hands (5 and k), not one. Five-structure; fixes the wrong picture |
| NUM-B-04 (count_tap, 11), NUM-B-05 (give_n, 10) | L2: two ten-frames (P4). Fingers do not scale to 20; ten-structure is the Band B idea (NUM-B-16) |
| NUM-A-05 vs NUM-A-10 (flash) | 1–3: the dots line up and are counted; 4–5: the finger pattern (the skill names both dice and finger patterns) |
| NUM-A-12 (tap, 8) | L1 must line both sets up with **equal spacing**. The distractor is size or crowding, so a picture that keeps the sizes keeps the misconception (M-CNT-SIZE) |
| MATH-A-03 (sort share, 8) | L2 deals one round only. The skill is the "one for you, one for you" procedure, not the bins |
| CS-A-03 (robot direct, Band A, 8) | L1 uses the landmark word, never right or left (Band A rule); L2 is a ghost robot doing one step |
| CS-B-01 (robot plan, 4: b.csb01.1, .3, .5, .7) | Decided 2026-10-31 (option b). L2 is the **first leg only**: from the start square (or from the end of the child's plan, when that plan is the start of the stored solution), the next run of same-direction arrows of the stored solution, one numbered footprint per square (1, 2, …, or continuing the plan's numbers), the ghost robot on the last footprint, that run's arrow lit. It ends at the first turn and never covers more than half the steps; the rest is the child's. The whole row-then-column way would be the answer, and these ways are staircases, not one row and one column, so it would also disagree with L3. L3 unchanged: its footprints 1…k are the same squares. Direct-mode CS-B-01 items (.2, .4, .6, .8) keep the generic one-step ghost |
| NUM-B-13 jump items, MATH-B-01, MATH-B-03 (number_line, 11) | L1 shows the hop size as dots or fingers above the start tick; L2 does the first unit hop |
| MATH-B-09 (balance, 8; spot, 4) | Cubes above each number (back from symbol to picture: concreteness fading in reverse, as a repair) |
| MATH-B-13 weigh (balance, 4) | Pair lines between pans; the child counts what is missing |
| MATH-B-18 (tap, 9) | Part-whole picture, not count-all (audit F14): the known part shaded in a ten-frame and the empties counted up to the whole |
| NUM-B-16 (tap, 11) | As specified in B-15 (`b15-content-spec.md` §4): full frame plus ones (H33a) or ten fingers plus k (H33b). Needs F12 |
| LOG-B-09 (tap, 8) | Deduction in two steps: clue 1 at L2, clue 2 at L3. Both clues at once would be the answer |
| COL-A-07 (tap, 8) | The noun first (the non-dolls fade), the colour second. The misconception is attending to one attribute (M-COL-ONEATTR) |
| SHP-A-08 (tap, 8) | Act out the position word with the guide and a box (P10). A shaded region on the options would point at the answer |
| SHP-B-02 (tap, 10) | A start dot on one corner, then each side lit with its number (one-to-one, M-CNT-DOUBLE in shapes) |

---

## 7. What each choice needs

### 7.1 From design (design-director)

| # | Picture or motion | For |
|---|---|---|
| D1 | A **pointing hand** in sky-blue outline for P11 and P12, one neutral hand for all companions (owner question 6), with a still version for reduce-motion | all |
| D2 | **Two finger hands** (5 + 5) in the style of `FingersHint` | count, give, sequence, add |
| D3 | **Ten-frame overlay** style (frame, counters, a full frame and a ones frame side by side; B-38 already asks for the ten-frame outline) | count B, give B, teens, add via ten, part-whole |
| D4 | **Pair line** style and the "unpaired" glow | compare, even and odd, chart, balance |
| D5 | **Number path strip** 0–20 (and a hundred-chart column), with the hop arc and a landmark tick | sequences, compare numbers, number line |
| D6 | **Core bracket** and the stacked-unit layout | patterns, spot patterns, programs |
| D7 | **Baseline** (start line and floor) | measure, seriation, charts |
| D8 | **Swatch pot**, **ghost outline** style, the rule cards in hint use, and the coin value badge | colour, shape, sort, money |
| D9 | **Act-out mini scenes:** on, under, in, next to and above with a box (5); a ball rolls and a box stands (2); pouring two paints and stirring (3 mixes); the sun's path through morning, noon, evening and night (4); a small seesaw | SHP-A-08, SHP-A-07, COL-B-01, MATH-A-05, MATH-A-04 |
| D10 | **Timeline slots** (3–4 numbered) and a **week strip** of the 7 existing day cards | TA-10 |
| D11 | **Clock:** the short hand highlighted and the dotted ray to the numeral; the hour sweep | clock_set, MATH-B-15 |
| D12 | The **level line** across the balance beam | balance |

Every picture follows the hint colour rule: sky-blue, never red, nothing that makes one option bigger or brighter before level 3.

### 7.2 From the hint text (hebrew-text-editor; final before the voicing B-45)

| # | Change | How many |
|---|---|---|
| T1 | **New hint-2 lines per family** that say what the new picture shows ("we'll put them in a ten-frame", "we'll match them one with one", "the part that repeats is…"). Shared lines with no number where possible | about 35 shared lines replace the generic hint 2 on 619 activities; per-item lines only where a number is said |
| T2 | **Hint-3 lines become a process, with the answer last** (the words in time with the pointer: "one, two, three… three ducks. Now you") | about 289 bare-answer lines, including the 128 that say "this one" with nothing on screen |
| T3 | **Hint-1 lines that name the spotlight** ("look at the gap", "look at the short hand"), where L1 now shows something | about 20 shared lines |
| T4 | **Finger lines above 5** say "five, and one more…", and the teen lines say "ten, and…" | 35 items |
| T5 | **The spot_error hint 3** keeps its rule sentence, and the walk stops at the cell | 71 |

All of these are drafts marked `"review": "needs-editor"`. Voicing waits for B-45, and nothing is voiced twice.

### 7.3 From the app (app-developer)

| # | Change | Size |
|---|---|---|
| A1 | `onHint` in every template reads the **level** and the hint's picture (and its target), not one action for all levels. Schema: new picture values, or `show` plus `target` on a hint; template versions bumped; `tools/author.py` and `band_b*.py` write them | M |
| A2 | **No answer before L3:** remove answer-marking from L1 and L2 in sort, pattern, match, shape builder, number line, robot, shop, clock, balance and spot_error, and make it the end of the L3 demo | M |
| A3 | **The guided state** starts with the demonstration; the halo and dimming come after it | S |
| A4 | **Shared hint pictures P1–P12** as widgets or painters reusable by every stage (`sprite_group.dart` already lays out ten-frames and dice) | L |
| A5 | **tap_answer** draws its family's picture on the stage over the group, row or chart (F12, hand-off H-B) | L |
| A6 | **Engine timing** (if the owner agrees): the first mistake shows the L1 picture with the diagnostic line; 2-choice items have one retry, then the demo | S |
| A7 | **Validator** refuses a level-1 or level-2 picture that marks the answer, and a hint whose picture is the same as the level below | S |
| A8 | **Row entrance** (added 2026-10-30, §12.1): in `tap_answer` rows, `build_pattern` and `spot_error`, the cells appear one by one from the left (about 120 ms each) with the gap last. With reduce-motion they all appear at once, with a still sky start dot under the first cell. The direction stays left to right (no change) | S |

### 7.4 Tests (qa-engineer)

- Every activity's hint at each level changes the stage (a widget key per picture).
- No level-1 or level-2 hint puts the hint halo or a selection on the correct option, bin, coin, cell or hands.
- The fingers shown equal the number counted.
- A golden per template at L2 and L3.
- The headless playthrough (`playthrough_test.dart`) runs the full ladder on one item of each family.

---

## 8. Build order (highest gap and impact first, Band A first, as decided in Q4)

| Step | What | Activities helped | Band | App size | Needs first |
|---|---|---|---|---|---|
| 1 | **Fix the wrong picture:** two hands to 10, ten-frames above 10 (P3, P4) | 35 | A, B | S | D2, D3, T4 |
| 2 | **Level-aware hints, the guided state, no answer before L3** (A1–A3, A6, A7) | 211 + every guided item | all | M | owner questions 1–4 |
| 3 | **The shared pictures P1, P2, P5, P6, P9, P12** (the ones used most) | – | – | L | D1, D4, D5, D8 |
| 4 | **tap_answer Band A:** TA-7 shapes (60), TA-6 colour (54), TA-4 compare (26), TA-1 count (20), TA-3 sequence (22), TA-8 rows (28), TA-10 time (28), TA-9 same and odd (27), TA-5 add (16), TA-2 numerals (12), TA-11 measure (8), and the one-hint warm-up `pick.red.flower` | 301 | A | L (S–M per family) | D9, D10; T1–T3 for these families |
| 5 | **Band A templates:** sort and share, build_pattern, match_pairs, shape_builder, robot A, spot_error A, flash L2, give_n L1, trace L1, count_tap pointer | 153 | A | M | D6, D7 |
| 6 | **tap_answer Band B:** TA-5 operations (106) first, then TA-3 (44), TA-4 (31), TA-6 (31), TA-7 (32), TA-8 (18), TA-2 (14), TA-9 (14), TA-1 (12), TA-12 (12), TA-10 (11) | 325 | B | L | D3, D5, D11; T1–T3 |
| 7 | **Band B templates:** number_line, spot_error B, balance, shop_pay, clock_set, robot B, trace B, build_pattern B, match_pairs B, sort B (count_tap B and give_n B are covered by steps 1 and 2) | 165 | B | M | D11, D12 |

Steps 1 to 5 cover every Band A activity (454 = 301 + 153). Steps 6 and 7 follow Band B in the order the children need it. The total app work is roughly 4 to 6 weeks of the app-developer's time, the larger share in A4 and A5. This is a rough estimate. The design work is about 12 picture sets. The text work is about 55 shared lines and about 300 hint-3 rewrites before B-45.

---

## 9. Questions only the owner can decide

1. **Show a picture at the first mistake?** Today the first mistake gets only a voice line, and with 3 choices the second mistake leaves only the answer untried, so the pictures come too late to teach.
   - *Recommendation:* yes. The first mistake shows the L1 picture with its diagnostic line, the second shows L2, the third the worked example.
2. **Two-choice items (106): one retry, then the worked example?** Curriculum §9.2 says so, but 105 allow 3 attempts.
   - *Recommendation:* yes. After one mistake, L2, then the demo.
3. **After the worked example, does the answer keep its halo while the child taps it?** The alternative is that the scene resets fully and the child finds the answer again.
   - *Recommendation:* keep a soft halo after the demo, so the item ends in the child's own success (§9.2). The credit is already lowered by the hint level.
4. **Take the answer out of hints 1 and 2 in the 211 drag, set and spot activities?** Today a 3-year-old who taps the lamp is shown the answer at once.
   - *Recommendation:* yes, to keep PLAN.md's rule. "Do the first step together" at L2 keeps Band A moving.
5. **For colours and shapes, may L2 turn naming into matching** (a swatch of "red", a ghost outline of "triangle")? It is a step down to the prerequisite skill, not the answer.
   - *Recommendation:* yes.
6. **The pointer for demonstrations:** one neutral sky-blue hand for every companion, or a hand or paw drawn for each companion?
   - *Recommendation:* one neutral hand. It is cheaper, consistent and clear, and the companion still speaks.
7. **Scope for the family release:** build steps 1 to 5 (the engine fix and all of Band A) before the release, and Band B (steps 6 and 7) after?
   - *Recommendation:* yes, in line with Q4.

---

## 10. Sources

- **Counting principles:** Gelman, R. & Gallistel, C. R. (1978). *The Child's Understanding of Number.* Harvard University Press. One-to-one, stable order and cardinality are why L1 lights the objects in turn and L3 holds the last word.
- **Pointing:** Alibali, M. W. & DiRusso, A. A. (1999). The function of gesture in learning to count: more than keeping track. *Cognitive Development* 14(1), 37–56. Children counted more accurately when they pointed **or when a puppet pointed for them**; this supports the guide's pointer (P2, P12). [abstract](https://pubmed.ncbi.nlm.nih.gov/10552922)
- **Learning trajectories:** Clements, D. H. & Sarama, J. (2021). *Learning and Teaching Early Math: The Learning Trajectories Approach* (3rd ed.). Routledge. Comparison by matching before counting (P5), subitising and five- and ten-structures (P3, P4), shapes by attributes rather than prototypes (P9, sides and corners), and composing shapes.
- **Subitising:** Clements, D. H. (1999). Subitizing: what is it? Why teach it? *Teaching Children Mathematics* 5(7), 400–405.
- **Number lines and board games:** Siegler, R. S. & Ramani, G. B. (2008, 2009). Playing linear number board games improves young children's numerical understanding. *Developmental Science* 11(5); *Journal of Educational Psychology* 101(3). These support the left-to-right number path (P6).
- **Concreteness fading:** Fyfe, E. R., McNeil, N. M., Son, J. Y. & Goldstone, R. L. (2014). Concreteness fading in mathematics and science instruction: a systematic review. *Educational Psychology Review* 26, 9–25. L2 goes back to a more concrete picture as repair.
- **Worked examples:** Renkl, A. (2014). Toward an instructionally oriented theory of example-based learning. *Cognitive Science* 38(1); Atkinson, R. K., Renkl, A. & Merrill, M. M. (2003). Transitioning from studying examples to solving problems. *Journal of Educational Psychology* 95(4). Show the process, then hand back the last step.
- **Scaffolding and contingent help:** Wood, D., Bruner, J. S. & Ross, G. (1976). The role of tutoring in problem solving. *Journal of Child Psychology and Psychiatry* 17(2). The least help first, more after failure.
- **Cueing:** de Koning, B. B., Tabbers, H. K., Rikers, R. M. J. P. & Paas, F. (2009). Towards a framework for attention cueing in instructional animations. *Educational Psychology Review* 21(2). A spotlight guides attention without adding content (L1).
- **Help-seeking and bottom-out hints:** Aleven, V. & Koedinger, K. R. (2000). Limitations of student control: do students know when they need help? *ITS 2000.* Hints that give the answer early invite clicking through. This is why the answer is kept to the end of L3.
- **Unplugged and robot programming for young children:** Bers, M. U. (2020). *Coding as a Playground* (2nd ed.). Routledge. It supports stepping through one step at a time and debugging by walking the program (the robot and program families).
- **Where the evidence is thin:** the exact ordering of L1 and L2 per family is a design judgement built from these sources, not a tested sequence. The engine's per-child representation bandit (§10.5) should be allowed to learn which L2 picture works best per skill family.

---

## 11. Design (step 2, the design-director, 2026-10-30)

The owner answered yes to all seven questions in §9 on 2026-10-30. The visual spec is in **`docs/design/b40-visual-hints.md`**, with mockups on the phone frame in `docs/design/b40/`. It covers:
- the visual grammar (L1 a sky glow, L2 a sky card or one step, L3 the sky hand),
- placement, motion, reduce-motion and sizes,
- P1 to P12 and the ladder for each template and each tap_answer family,
- a "without words or sound" check for each mockup,
- what the app-developer needs.

It changes this plan in the following places (design §6):
- **F2:** L1 never counts aloud or shows numbers (TA-1, TA-3).
- **F6:** balance L2 uses towers on the pans with a level line, not pair lines across the pans.
- **F7:** clock_set L1 adds a card with the target numeral.
- **F8:** shop_pay L1 shows the price as empty coin places on the counter.
- **F9:** number_line L1 shows the hop size as a pill of dots, not fingers.
- **F4, F12:** the curriculum-expert confirms the ten-frame direction and the finger order.

Open for the owner (design §8), answered below in §12:
1. Naming items with the sound off.
2. The direction of pattern rows: spec §8 and the app disagree.
3. The look of the hands.

## 12. Owner answers 2026-10-30

1. **Naming items with the sound off:** "it's OK". Colour, shape, numeral and day names get their first picture hint at L2 (the swatch, the outline); L1 is "look at each one" with the word.
2. **Pattern rows:** "do it in the only way that won't be confusing to the children." The curriculum-expert's decision is below.
3. **The hands:** they look good.

### 12.1 The direction of rows (curriculum-expert decision, 2026-10-30)

**The test.** Where does the child's eye start, where is the next empty place, and does any row in the app ever run the opposite way to another one? The last point decides. Inside the stage the app already draws every row left to right: the number line, the ten-frame, the number path (P6), count rows, `tap_answer` rows (116 activities, patterns and orders), `build_pattern` (15) and `spot_error` (71). Turning only the picture patterns to right to left would make the "?" sit at the left in the Logic land and at the right in the Numbers land, for the same question "מַה בָּא אַחַר כָּךְ?". It would also make the L2 path under a growing or counting row run against the row.

**One rule for every row inside the stage:** it is drawn left to right in the LTR isolate. The first cell is at the left, and the "?" or the next empty place is at the right end. It is never mirrored.

| Kind | Rule | Reason |
|---|---|---|
| Picture, colour and shape patterns (AB, ABB, ABC; also shade ramps, rainbow and size order) | Left to right, gap at the right end | A repeating unit has the same answer read from either end, so only consistency matters, and every other row in the app runs left to right |
| Growing patterns (LOG-B-04: 1, 2, 3 …) | Left to right, gap at the right end | At L2 the counts 1, 2, 3 stand under the steps like the number path (P6), and the row must grow the same way as that path |
| Number sequences (2, 4, 6, __; counting on, counting back, skip counting) | Left to right, gap at the right end. Counting back too (9, 8, 7, __): the values go down along the row | A number sequence is a piece of the number line, which goes left to right in Israeli maths books and in this app |
| Order in time (first, then, last; the week strip), for consistency | Left to right, slot 1 at the left, the slots numbered | It uses the same `tap_answer` row and `spot_error` row as the patterns. The numbers 1, 2, 3 show where to start without any reading |

**Not changed:** navigation (the lesson path, the progress trail, back and next) still mirrors, because it is outside the stage and is not maths. The robot program strip stays vertical. Clocks and robot arrows never mirror.

**The eye start.** Israeli preschoolers mostly count a row of objects from the right (Shaki, Fischer & Göbel 2012), so the start at the left has to be shown, not assumed. Brief directional modelling changes young children's counting direction (Göbel, McCrink, Fischer & Shaki 2018), so a cue that is the same every time is enough:
- When an item opens, the row's cells appear one by one from the left (about 120 ms each), and the gap appears last. With reduce-motion they all appear at once, and a small sky start dot is shown under the first cell.
- L1 (P2) always begins at the leftmost cell and ends on the gap.
- No line says left, right, or "like reading" (Band A and B rule).

**Evidence is thin on one point.** I found no Ministry of Education source that fixes the direction of kindergarten picture patterns. Israeli worksheets differ, and the kindergarten programme (Math3.pdf) lists patterns without a direction. The decision rests on consistency inside the app and on the left-to-right number line, not on a school rule.

**What changes:**
- **Code and content:** the direction itself needs no change. The `tap_answer` `_row`, `build_pattern` (a touch fills the first empty place, the leftmost) and `spot_error` are already left to right, and no pack activity says left or right in a pattern or sequence. There is one new small item for the app-developer, **A8** (S): the row's cells appear in order from the left when the item opens, as described above.
- **design-spec §8** (the design-director): the rows "Pattern rows" and "Story sequences, timelines, first/then/last cards" change from *Mirror* to **Does not mirror: left to right in the LTR isolate, the gap or the next slot at the right end**.
- **Hint pictures:**
  - P2 runs left to right, top row first, everywhere in the stage. This includes loose objects, so that L1 and the L3 count go the same way within one item. Order irrelevance means any order gives the right count.
  - P6 is unchanged.
  - P7 brackets go left to right, with the first copy at the left. The copies stack under the first.
  - P11 fills the leftmost empty slot in `build_pattern`. On the path it hops to the right, or to the left for counting back. In a timeline it fills slot 1, at the left.
  - The F4 ten-frame fill (top row, from the left) follows the same rule.

Sources: Shaki, S., Fischer, M. H. & Göbel, S. M. (2012), "Direction counts: a comparative study of spatially directional counting biases in cultures with different reading directions", *J. Experimental Child Psychology* 112 (https://cris.iucc.ac.il/en/publications/direction-counts-a-comparative-study-of-spatially-directional-cou/). Göbel, S. M., McCrink, K., Fischer, M. H. & Shaki, S. (2018), "Observation of directional storybook reading influences young children's counting direction" (https://cris.iucc.ac.il/en/publications/observation-of-directional-storybook-reading-influences-young-chi/). I read only the abstracts and a review (Frontiers in Psychology 2015, 10.3389/fpsyg.2015.00215), not the full texts. Ministry kindergarten mathematics programme: https://meyda.education.gov.il/files/Tochniyot_Limudim/KdamYesodi/Math3.pdf. Siegler & Ramani (2008, 2009) for the left-to-right number path (§10).

---

## Appendix A: the 635 activities with no visual hint at any level

Format: land | band | skill | template | count | ids. The 625 tap_answer items have their choices on tiles, where the pulse is not drawn. The 10 balance items are the 6 compare items whose tilt is already shown and the 4 weigh items.

| Land | Band | Skill | Template | n | Activity ids |
|---|---|---|---|---|---|
| Colour Bay | A | COL-A-01 | tap_answer | 8 | b15.cola01.1, b15.cola01.2, col.match.blue, col.match.green, col.match.green2, col.match.red, col.match.red2, col.match.yellow |
| Colour Bay | A | COL-A-02 | tap_answer | 7 | b15.cola02.3, b15.cola02.4, col.name.blue.balloon, col.name.green.ball, col.name.red.ball, col.name.red.near, col.name.yellow.flower |
| Colour Bay | A | COL-A-03 | tap_answer | 10 | b15.cola03.3, b15.cola03.4, col.name.black, col.name.orange, col.name.orange2, col.name.pink, col.name.pink2, col.name.purple, col.name.purple2, col.name.white |
| Colour Bay | A | COL-A-04 | tap_answer | 6 | col.sort.blue, col.sort.green, col.sort.orange, col.sort.pink, col.sort.red, col.sort.yellow |
| Colour Bay | A | COL-A-05 | tap_answer | 8 | b15.cola05.1, b15.cola05.2, col.world.apple, col.world.apple.red, col.world.banana, col.world.banana.ripe, col.world.grass, col.world.sun |
| Colour Bay | A | COL-A-06 | tap_answer | 6 | col.name.brown, col.name.brown2, col.name.brown3, col.name.grey, col.name.grey2, col.name.grey.flower |
| Colour Bay | A | COL-A-07 | tap_answer | 8 | b15.cola07.1, b15.cola07.2, col.find.blue.ball, col.find.green.balloon, col.find.red.ball, col.find.red.balloon, col.find.yellow.balloon, col.find.yellow.flower |
| Colour Bay | B | COL-B-01 | tap_answer | 9 | b.colb01.1, b.colb01.2, b.colb01.3, b.colb01.4, b.colb01.5, b.colb01.6, b.colb01.7, b.colb01.8, b.colb01.9 |
| Colour Bay | B | COL-B-02 | tap_answer | 12 | b.colb02.1, b.colb02.2, b.colb02.3, b.colb02.4, b.colb02.5, b.colb02.6, b.colb02.7, b.colb02.8, b.colb02.9, b.colb02.10, b.colb02.11, b.colb02.12 |
| Colour Bay | B | COL-B-03 | tap_answer | 10 | b.colb03.1, b.colb03.2, b.colb03.3, b.colb03.4, b.colb03.5, b.colb03.6, b.colb03.7, b.colb03.8, b.colb03.9, b.colb03.10 |
| Counting Hills | A | NUM-A-01 | tap_answer | 6 | next.after.1, next.after.2, next.after.3, next.after.4, next.before.4, next.before.5 |
| Counting Hills | A | NUM-A-02 | tap_answer | 7 | next.after.5, next.after.6, next.after.8, next.after.9, next.before.7, next.before.9, next.before.10 |
| Counting Hills | A | NUM-A-03 | tap_answer | 2 | b15.numa03.1, b15.numa03.2 |
| Counting Hills | A | NUM-A-04 | tap_answer | 2 | b15.numa04.1, b15.numa04.2 |
| Counting Hills | A | NUM-A-07 | tap_answer | 7 | numeral.apples.2, numeral.bugs.5, numeral.fish.4, numeral.stars.3, show.apples.3, show.birds.4, show.stars.5 |
| Counting Hills | A | NUM-A-08 | tap_answer | 9 | b15.numa08.1, b15.numa08.2, pick.numeral.1, pick.numeral.2, pick.numeral.2b, pick.numeral.3, pick.numeral.4, pick.numeral.4b, pick.numeral.5 |
| Counting Hills | A | NUM-A-11 | tap_answer | 10 | b15.numa11.1, b15.numa11.2, fewer.stars.4v1, fewer.stars.4v2, more.apples.2v4, more.ducks.5v3, more.fish.3v5, same.apples.4v5, same.bugs.3v3, same.fish.2v2 |
| Counting Hills | A | NUM-A-12 | tap_answer | 8 | b15.numa12.1, b15.numa12.2, fewer.big.ducks, fewer.big.fish, more.big.apples, more.big.stars, more.spread.fish, more.spread.stars |
| Counting Hills | A | NUM-A-13 | tap_answer | 9 | b15.numa13.1, b15.numa13.2, ordinal.first, ordinal.first.of4, ordinal.last, ordinal.second, ordinal.second.of4, ordinal.third, ordinal.third.of4 |
| Counting Hills | A | NUM-A-14 | tap_answer | 8 | b15.numa14.1, b15.numa14.2, nonzero.bowl.1, nonzero.nest.2, zero.basket, zero.basket.b, zero.bowl, zero.nest |
| Counting Hills | B | NUM-B-01 | tap_answer | 9 | b.numb01.1, b.numb01.2, b.numb01.3, b.numb01.4, b.numb01.5, b.numb01.6, b.numb01.7, b.numb01.8, b.numb01.9 |
| Counting Hills | B | NUM-B-02 | tap_answer | 9 | b.numb02.1, b.numb02.2, b.numb02.3, b.numb02.4, b.numb02.5, b.numb02.6, b.numb02.7, b.numb02.8, b.numb02.9 |
| Counting Hills | B | NUM-B-03 | tap_answer | 8 | b.numb03.1, b.numb03.2, b.numb03.3, b.numb03.4, b.numb03.5, b.numb03.6, b.numb03.7, b.numb03.8 |
| Counting Hills | B | NUM-B-08 | tap_answer | 14 | b.numb08.1, b.numb08.2, b.numb08.3, b.numb08.4, b.numb08.5, b.numb08.6, b.numb08.7, b.numb08.8, b.numb08.9, b.numb08.10, b.numb08.11, b.numb08.12, b.numb08.13, b.numb08.14 |
| Counting Hills | B | NUM-B-10 | tap_answer | 10 | b.numb10.1, b.numb10.2, b.numb10.3, b.numb10.4, b.numb10.5, b.numb10.6, b.numb10.7, b.numb10.8, b.numb10.9, b.numb10.10 |
| Counting Hills | B | NUM-B-11 | tap_answer | 12 | b.numb11.7, b.numb11.8, b.numb11.9, b.numb11.10, b.numb11.11, b.numb11.12, b.numb11.13, b.numb11.14, b.numb11.15, b.numb11.16, b.numb11.17, b.numb11.18 |
| Counting Hills | B | NUM-B-14 | tap_answer | 10 | b.numb14.1, b.numb14.2, b.numb14.3, b.numb14.4, b.numb14.5, b.numb14.6, b.numb14.7, b.numb14.8, b.numb14.9, b.numb14.10 |
| Counting Hills | B | NUM-B-16 | tap_answer | 11 | b.numb16.1, b.numb16.2, b.numb16.3, b.numb16.4, b.numb16.5, b.numb16.6, b.numb16.7, b.numb16.8, b.numb16.9, b.numb16.10, b.numb16.11 |
| Counting Hills | B | NUM-B-17 | tap_answer | 6 | b.numb17.7, b.numb17.8, b.numb17.9, b.numb17.10, b.numb17.11, b.numb17.12 |
| Counting Hills | B | NUM-B-18 | tap_answer | 10 | b.numb18.1, b.numb18.2, b.numb18.3, b.numb18.4, b.numb18.5, b.numb18.6, b.numb18.7, b.numb18.8, b.numb18.9, b.numb18.10 |
| Market Village | A | MATH-A-01 | tap_answer | 8 | b15.matha01.1, b15.matha01.2, math.add.apples, math.add.ducks, math.add.fish, math.add.fish2, math.add.stars, math.add.stars2 |
| Market Village | A | MATH-A-02 | tap_answer | 8 | b15.matha02.1, b15.matha02.2, math.take.apples, math.take.apples2, math.take.ducks, math.take.fish, math.take.fish2, math.take.stars |
| Market Village | A | MATH-A-04 | tap_answer | 8 | b15.matha04.1, b15.matha04.2, math.size.big, math.size.heavy, math.size.light, math.size.long, math.size.short, math.size.small |
| Market Village | A | MATH-A-05 | tap_answer | 6 | math.time.after, math.time.before, math.time.evening, math.time.morning, math.time.night, math.time.noon |
| Market Village | A | MATH-A-06 | tap_answer | 2 | b15.matha06.1, b15.matha06.2 |
| Market Village | A | MATH-A-07 | tap_answer | 8 | b15.matha07.1, b15.matha07.2, math.graph.apples, math.graph.apples2, math.graph.ducks, math.graph.fish, math.graph.stars, math.graph.stars2 |
| Market Village | B | MATH-B-01 | tap_answer | 14 | b.mathb01.1, b.mathb01.2, b.mathb01.3, b.mathb01.4, b.mathb01.5, b.mathb01.6, b.mathb01.7, b.mathb01.8, b.mathb01.9, b.mathb01.10, b.mathb01.11, b.mathb01.12, b.mathb01.15, b.mathb01.16 |
| Market Village | B | MATH-B-02 | tap_answer | 12 | b.mathb02.1, b.mathb02.2, b.mathb02.3, b.mathb02.4, b.mathb02.5, b.mathb02.6, b.mathb02.7, b.mathb02.8, b.mathb02.9, b.mathb02.10, b.mathb02.11, b.mathb02.12 |
| Market Village | B | MATH-B-03 | tap_answer | 10 | b.mathb03.1, b.mathb03.2, b.mathb03.3, b.mathb03.4, b.mathb03.5, b.mathb03.6, b.mathb03.7, b.mathb03.8, b.mathb03.15, b.mathb03.16 |
| Market Village | B | MATH-B-06 | tap_answer | 10 | b.mathb06.1, b.mathb06.2, b.mathb06.3, b.mathb06.4, b.mathb06.5, b.mathb06.6, b.mathb06.7, b.mathb06.8, b.mathb06.9, b.mathb06.10 |
| Market Village | B | MATH-B-07 | tap_answer | 8 | b.mathb07.1, b.mathb07.2, b.mathb07.3, b.mathb07.4, b.mathb07.5, b.mathb07.6, b.mathb07.7, b.mathb07.8 |
| Market Village | B | MATH-B-08 | tap_answer | 14 | b.mathb08.1, b.mathb08.2, b.mathb08.3, b.mathb08.4, b.mathb08.5, b.mathb08.6, b.mathb08.7, b.mathb08.8, b.mathb08.9, b.mathb08.10, b.mathb08.11, b.mathb08.12, b.mathb08.13, b.mathb08.14 |
| Market Village | B | MATH-B-10 | tap_answer | 8 | b.mathb10.1, b.mathb10.2, b.mathb10.3, b.mathb10.4, b.mathb10.5, b.mathb10.6, b.mathb10.7, b.mathb10.8 |
| Market Village | B | MATH-B-13 | balance | 10 | b.mathb13.1, b.mathb13.2, b.mathb13.3, b.mathb13.4, b.mathb13.5, b.mathb13.6, b.mathb13.7, b.mathb13.8, b.mathb13.9, b.mathb13.10 |
| Market Village | B | MATH-B-14 | tap_answer | 11 | b.mathb14.1, b.mathb14.2, b.mathb14.3, b.mathb14.4, b.mathb14.5, b.mathb14.6, b.mathb14.7, b.mathb14.8, b.mathb14.9, b.mathb14.10, b.mathb14.11 |
| Market Village | B | MATH-B-15 | tap_answer | 10 | b.mathb15.1, b.mathb15.2, b.mathb15.3, b.mathb15.4, b.mathb15.5, b.mathb15.6, b.mathb15.7, b.mathb15.8, b.mathb15.9, b.mathb15.10 |
| Market Village | B | MATH-B-16 | tap_answer | 2 | x.mathb16.7, x.mathb16.8 |
| Market Village | B | MATH-B-18 | tap_answer | 9 | b.mathb18.1, b.mathb18.2, b.mathb18.3, b.mathb18.4, b.mathb18.5, b.mathb18.6, b.mathb18.7, b.mathb18.8, b.mathb18.9 |
| Market Village | B | MATH-B-19 | tap_answer | 11 | x.mathb19.1, x.mathb19.2, x.mathb19.3, x.mathb19.4, x.mathb19.5, x.mathb19.6, x.mathb19.7, x.mathb19.8, x.mathb19.9, x.mathb19.10, x.mathb19.11 |
| Riddle Grotto | A | LOG-A-01 | tap_answer | 8 | b15.loga01.3, b15.loga01.4, log.same.apple, log.same.balloon, log.same.bird, log.same.cat, log.same.duck, log.same.star |
| Riddle Grotto | A | LOG-A-02 | tap_answer | 8 | b15.loga02.1, b15.loga02.2, log.odd.animal, log.odd.ball, log.odd.bird, log.odd.colour, log.odd.fruit, log.odd.thing |
| Riddle Grotto | A | LOG-A-03 | tap_answer | 3 | log.sort.animal, log.sort.balloon, log.sort.colour |
| Riddle Grotto | A | LOG-A-04 | tap_answer | 6 | log.pat.no.mixed, log.pat.no.things, log.pat.yes.animals, log.pat.yes.colours, log.pat.yes.fish, log.pat.yes.green |
| Riddle Grotto | A | LOG-A-06 | tap_answer | 8 | b15.loga06.1, b15.loga06.2, log.next.animals, log.next.balloons, log.next.balls, log.next.colours, log.next.pets, log.next.stars |
| Riddle Grotto | A | LOG-A-07 | tap_answer | 6 | log.fix.animals, log.fix.balloons, log.fix.balls, log.fix.colours, log.fix.pets, log.fix.things |
| Riddle Grotto | A | LOG-A-08 | tap_answer | 8 | b15.loga08.1, b15.loga08.2, log.story.egg.first, log.story.egg.then, log.story.plant.first, log.story.plant.last, log.story.plant.mid, log.story.weather.last |
| Riddle Grotto | A | LOG-A-09 | tap_answer | 8 | b15.loga09.1, b15.loga09.2, log.pair.bowl, log.pair.brush, log.pair.key, log.pair.pencil, log.pair.shoe, log.pair.sock |
| Riddle Grotto | A | LOG-A-10 | tap_answer | 8 | b15.loga10.1, b15.loga10.2, log.size.apples.last, log.size.fish.first, log.size.last, log.size.middle, log.size.middle.down, log.size.stars |
| Riddle Grotto | B | LOG-B-01 | tap_answer | 10 | b.logb01.1, b.logb01.2, b.logb01.3, b.logb01.4, b.logb01.5, b.logb01.6, b.logb01.7, b.logb01.8, b.logb01.9, b.logb01.10 |
| Riddle Grotto | B | LOG-B-04 | tap_answer | 8 | b.logb04.1, b.logb04.2, b.logb04.3, b.logb04.4, b.logb04.5, b.logb04.6, b.logb04.7, b.logb04.8 |
| Riddle Grotto | B | LOG-B-06 | tap_answer | 6 | b.logb06.1, b.logb06.2, b.logb06.3, b.logb06.4, b.logb06.5, b.logb06.6 |
| Riddle Grotto | B | LOG-B-09 | tap_answer | 8 | b.logb09.1, b.logb09.2, b.logb09.3, b.logb09.4, b.logb09.5, b.logb09.6, b.logb09.7, b.logb09.8 |
| Robot Harbour | A | CS-A-01 | tap_answer | 8 | b15.csa01.1, b15.csa01.2, cs.routine.teeth.first, cs.routine.teeth.last, cs.routine.teeth.middle, cs.routine.wash.first, cs.routine.wash.last, cs.routine.wash.middle |
| Robot Harbour | A | CS-A-04 | tap_answer | 2 | b15.csa04.1, b15.csa04.2 |
| Robot Harbour | A | CS-A-05 | tap_answer | 6 | cs.wrong.teeth, cs.wrong.teeth2, cs.wrong.teeth3, cs.wrong.wash, cs.wrong.wash2, cs.wrong.wash3 |
| Robot Harbour | B | CS-B-01 | tap_answer | 2 | b.csb01.9, b.csb01.10 |
| Shape Forest | A | SHP-A-01 | tap_answer | 8 | b15.shpa01.1, b15.shpa01.2, shp.match.circle, shp.match.circle.blue, shp.match.square, shp.match.square.orange, shp.match.triangle, shp.match.triangle.green |
| Shape Forest | A | SHP-A-02 | tap_answer | 8 | b15.shpa02.1, b15.shpa02.2, shp.name.circle, shp.name.mix, shp.name.square, shp.name.square.yellow, shp.name.triangle, shp.name.triangle.green |
| Shape Forest | A | SHP-A-03 | tap_answer | 6 | shp.any.big.circle, shp.any.down, shp.any.small, shp.any.small.square, shp.any.thin, shp.any.tilt |
| Shape Forest | A | SHP-A-04 | tap_answer | 8 | b15.shpa04.1, b15.shpa04.2, shp.rect.blue, shp.rect.find, shp.rect.green, shp.rect.long, shp.rect.square, shp.square.orange |
| Shape Forest | A | SHP-A-05 | tap_answer | 6 | shp.world.circle, shp.world.plate.shape, shp.world.rect, shp.world.sign.shape, shp.world.triangle, shp.world.window.shape |
| Shape Forest | A | SHP-A-07 | tap_answer | 8 | b15.shpa07.1, b15.shpa07.2, shp.solid.rolls, shp.solid.rolls.blue, shp.solid.stacks, shp.solid.stacks.blue, shp.solid.which, shp.solid.which2 |
| Shape Forest | A | SHP-A-08 | tap_answer | 8 | b15.shpa08.1, b15.shpa08.2, shp.where.above, shp.where.in, shp.where.in2, shp.where.next, shp.where.on, shp.where.under |
| Shape Forest | A | SHP-A-10 | tap_answer | 8 | b15.shpa10.1, b15.shpa10.2, shp.line.curved, shp.line.curved2, shp.line.curved3, shp.line.straight, shp.line.straight2, shp.line.straight3 |
| Shape Forest | B | SHP-B-01 | tap_answer | 8 | b.shpb01.1, b.shpb01.2, b.shpb01.3, b.shpb01.4, b.shpb01.5, b.shpb01.6, b.shpb01.7, b.shpb01.8 |
| Shape Forest | B | SHP-B-02 | tap_answer | 10 | b.shpb02.1, b.shpb02.2, b.shpb02.3, b.shpb02.4, b.shpb02.5, b.shpb02.6, b.shpb02.7, b.shpb02.8, b.shpb02.9, b.shpb02.10 |
| Shape Forest | B | SHP-B-03 | tap_answer | 6 | b.shpb03.1, b.shpb03.2, b.shpb03.3, b.shpb03.4, b.shpb03.5, b.shpb03.6 |
| Shape Forest | B | SHP-B-04 | tap_answer | 8 | b.shpb04.1, b.shpb04.2, b.shpb04.3, b.shpb04.4, b.shpb04.5, b.shpb04.6, b.shpb04.7, b.shpb04.8 |
| Shape Forest | B | SHP-B-08 | tap_answer | 8 | b.shpb08.1, b.shpb08.2, b.shpb08.3, b.shpb08.4, b.shpb08.5, b.shpb08.6, b.shpb08.7, b.shpb08.8 |
| Shape Forest | B | SHP-B-09 | tap_answer | 2 | x.shpb09.5, x.shpb09.6 |

## Appendix B: the 211 activities whose hint shows the answer (or a step of it) before level 3

Format: land | band | skill | template | today's L1/L2/L3 | count | ids.

| Land | Band | Skill | Template | L1/L2/L3 | n | Activity ids |
|---|---|---|---|---|---|---|
| Colour Bay | A | COL-A-02 | sort_drag | answer/answer/answer | 2 | b15.cola02.1, b15.cola02.2 |
| Colour Bay | A | COL-A-02 | spot_error | none/answer/answer | 2 | b15.cola02.5, b15.cola02.6 |
| Colour Bay | A | COL-A-03 | sort_drag | answer/answer/answer | 2 | b15.cola03.1, b15.cola03.2 |
| Colour Bay | A | COL-A-03 | spot_error | none/answer/answer | 2 | b15.cola03.5, b15.cola03.6 |
| Colour Bay | A | COL-A-04 | sort_drag | answer/answer/answer | 2 | b15.cola04.1, b15.cola04.2 |
| Colour Bay | A | COL-A-06 | spot_error | none/answer/answer | 2 | b15.cola06.1, b15.cola06.2 |
| Colour Bay | B | COL-B-04 | sort_drag | answer/answer/answer | 4 | b.colb04.1, b.colb04.2, b.colb04.3, b.colb04.4 |
| Colour Bay | B | COL-B-04 | spot_error | none/answer/answer | 2 | b.colb04.5, b.colb04.6 |
| Colour Bay | B | COL-B-06 | build_pattern | answer/answer/answer | 4 | b.colb06.1, b.colb06.2, b.colb06.3, b.colb06.4 |
| Colour Bay | B | COL-B-06 | spot_error | none/answer/answer | 1 | b.colb06.5 |
| Counting Hills | A | NUM-A-01 | spot_error | none/answer/answer | 2 | b15.numa01.4, b15.numa01.5 |
| Counting Hills | A | NUM-A-02 | spot_error | none/answer/answer | 2 | b15.numa02.4, b15.numa02.5 |
| Counting Hills | A | NUM-A-03 | spot_error | none/answer/answer | 1 | b15.numa03.5 |
| Counting Hills | A | NUM-A-07 | match_pairs | answer/answer/answer | 7 | x.numa07.1, x.numa07.2, x.numa07.3, x.numa07.4, x.numa07.5, x.numa07.6, x.numa07.7 |
| Counting Hills | A | NUM-A-08 | spot_error | none/answer/answer | 2 | b15.numa08.3, b15.numa08.4 |
| Counting Hills | B | NUM-B-03 | spot_error | none/answer/answer | 2 | b.numb03.9, b.numb03.10 |
| Counting Hills | B | NUM-B-11 | spot_error | none/answer/answer | 6 | b.numb11.1, b.numb11.2, b.numb11.3, b.numb11.4, b.numb11.5, b.numb11.6 |
| Counting Hills | B | NUM-B-13 | number_line | answer/answer/demo | 21 | b.numb13.1, b.numb13.2, b.numb13.3, b.numb13.4, b.numb13.5, b.numb13.6, b.numb13.7, b.numb13.8, b.numb13.9, b.numb13.10, b.numb13.11, b.numb13.12, b.numb13.13, b.numb13.14, b.numb13.15, b.numb13.16, b.numb13.17, b.numb13.18, b.numb13.19, b.numb13.20, b.numb13.21 |
| Counting Hills | B | NUM-B-17 | spot_error | none/answer/answer | 6 | b.numb17.1, b.numb17.2, b.numb17.3, b.numb17.4, b.numb17.5, b.numb17.6 |
| Market Village | B | MATH-B-01 | number_line | answer/answer/demo | 2 | b.mathb01.17, b.mathb01.18 |
| Market Village | B | MATH-B-03 | number_line | answer/answer/demo | 2 | b.mathb03.13, b.mathb03.14 |
| Market Village | B | MATH-B-03 | spot_error | none/answer/answer | 4 | b.mathb03.9, b.mathb03.10, b.mathb03.11, b.mathb03.12 |
| Market Village | B | MATH-B-09 | balance | answer/answer/answer | 8 | b.mathb09.1, b.mathb09.2, b.mathb09.3, b.mathb09.4, b.mathb09.5, b.mathb09.6, b.mathb09.7, b.mathb09.8 |
| Market Village | B | MATH-B-09 | spot_error | none/answer/answer | 4 | b.mathb09.9, b.mathb09.10, b.mathb09.11, b.mathb09.12 |
| Market Village | B | MATH-B-13 | balance | answer/answer/answer | 2 | b.mathb13.11, b.mathb13.12 |
| Market Village | B | MATH-B-15 | clock_set | answer/answer/answer | 8 | x.mathb15.1, x.mathb15.2, x.mathb15.3, x.mathb15.4, x.mathb15.5, x.mathb15.6, x.mathb15.7, x.mathb15.8 |
| Market Village | B | MATH-B-16 | match_pairs | answer/answer/answer | 6 | x.mathb16.1, x.mathb16.2, x.mathb16.3, x.mathb16.4, x.mathb16.5, x.mathb16.6 |
| Market Village | B | MATH-B-17 | shop_pay | answer/answer/answer | 11 | x.mathb17.1, x.mathb17.2, x.mathb17.3, x.mathb17.4, x.mathb17.5, x.mathb17.6, x.mathb17.7, x.mathb17.8, x.mathb17.9, x.mathb17.10, x.mathb17.11 |
| Riddle Grotto | A | LOG-A-01 | sort_drag | answer/answer/answer | 2 | b15.loga01.1, b15.loga01.2 |
| Riddle Grotto | A | LOG-A-01 | spot_error | none/answer/answer | 2 | b15.loga01.5, b15.loga01.6 |
| Riddle Grotto | A | LOG-A-03 | sort_drag | answer/answer/answer | 5 | b15.loga03.1, b15.loga03.2, log.sortdrag.animals, log.sortdrag.colour, log.sortdrag.three |
| Riddle Grotto | A | LOG-A-04 | spot_error | none/answer/answer | 2 | b15.loga04.1, b15.loga04.2 |
| Riddle Grotto | A | LOG-A-05 | build_pattern | answer/answer/answer | 8 | b15.loga05.1, b15.loga05.2, log.copy.animals, log.copy.balloons, log.copy.colours, log.copy.green, log.copy.pets, log.copy.three |
| Riddle Grotto | A | LOG-A-07 | spot_error | none/answer/answer | 2 | b15.loga07.1, b15.loga07.2 |
| Riddle Grotto | B | LOG-B-02 | spot_error | none/answer/answer | 6 | b.logb02.1, b.logb02.2, b.logb02.3, b.logb02.4, b.logb02.5, b.logb02.6 |
| Riddle Grotto | B | LOG-B-06 | spot_error | none/answer/answer | 2 | b.logb06.7, b.logb06.8 |
| Riddle Grotto | B | LOG-B-08 | sort_drag | answer/answer/answer | 6 | b.logb08.1, b.logb08.2, b.logb08.3, b.logb08.4, b.logb08.5, b.logb08.6 |
| Riddle Grotto | B | LOG-B-11 | build_pattern | answer/answer/answer | 3 | b.logb11.1, b.logb11.2, b.logb11.3 |
| Riddle Grotto | B | LOG-B-11 | spot_error | none/answer/answer | 2 | b.logb11.4, b.logb11.5 |
| Robot Harbour | A | CS-A-03 | robot_path | answer/answer/demo | 8 | b15.csa03.1, b15.csa03.2, cs.robot.direct.1, cs.robot.direct.2, cs.robot.direct.3, cs.robot.direct.4, cs.robot.direct.5, cs.robot.direct.6 |
| Robot Harbour | A | CS-A-04 | robot_path | answer/answer/demo | 6 | cs.robot.plan.1, cs.robot.plan.2, cs.robot.plan.3, cs.robot.plan.4, cs.robot.plan.5, cs.robot.plan.6 |
| Robot Harbour | A | CS-A-05 | spot_error | none/answer/answer | 2 | b15.csa05.1, b15.csa05.2 |
| Robot Harbour | B | CS-B-01 | robot_path | answer/answer/demo | 8 | b.csb01.1, b.csb01.2, b.csb01.3, b.csb01.4, b.csb01.5, b.csb01.6, b.csb01.7, b.csb01.8 |
| Robot Harbour | B | CS-B-04 | spot_error | none/answer/answer | 6 | b.csb04.1, b.csb04.2, b.csb04.3, b.csb04.4, b.csb04.5, b.csb04.6 |
| Shape Forest | A | SHP-A-02 | spot_error | none/answer/answer | 2 | b15.shpa02.3, b15.shpa02.4 |
| Shape Forest | A | SHP-A-03 | sort_drag | answer/answer/answer | 2 | b15.shpa03.1, b15.shpa03.2 |
| Shape Forest | A | SHP-A-03 | spot_error | none/answer/answer | 2 | b15.shpa03.3, b15.shpa03.4 |
| Shape Forest | A | SHP-A-06 | shape_builder | answer/answer/answer | 7 | b15.shpa06.1, b15.shpa06.2, shp.build.face, shp.build.house, shp.build.rocket, shp.build.train, shp.build.tree |
| Shape Forest | B | SHP-B-01 | spot_error | none/answer/answer | 2 | b.shpb01.9, b.shpb01.10 |
| Shape Forest | B | SHP-B-03 | spot_error | none/answer/answer | 1 | b.shpb03.7 |
| Shape Forest | B | SHP-B-04 | spot_error | none/answer/answer | 1 | b.shpb04.9 |
| Shape Forest | B | SHP-B-08 | spot_error | none/answer/answer | 1 | b.shpb08.9 |
| Shape Forest | B | SHP-B-09 | match_pairs | answer/answer/answer | 4 | x.shpb09.1, x.shpb09.2, x.shpb09.3, x.shpb09.4 |

## Appendix C: the 35 activities whose finger hint shows 5 for a bigger number

| Skill | Template | n | Activity ids |
|---|---|---|---|
| MATH-B-01 | count_tap | 1 | b.mathb01.14 |
| NUM-A-02 | count_tap | 3 | b15.numa02.1, b15.numa02.2, b15.numa02.3 |
| NUM-A-09 | count_tap | 10 | b15.numa09.1, b15.numa09.2, count.apples.7, count.birds.10, count.cats.7, count.dogs.8, count.fish.9, count.ladybugs.10, count.ladybugs.6, count.stars.8 |
| NUM-B-04 | count_tap | 11 | b.numb04.1 to b.numb04.11 |
| NUM-B-05 | give_n | 10 | b.numb05.1 to b.numb05.10 |
