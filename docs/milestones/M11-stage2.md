# M11 Stage 2: show first, then together, then alone (the teaching spec for the six lands)

**Status:** **approved by the owner on 2026-11-15** (the four answers at the end). **Pilot 2.4a (Shape Forest) content done on 2026-11-15**, see §11; the developer builds 2.1 from `content/units/arc/shape-forest.arc.json` (§7.4). Written by the curriculum-expert on 2026-11-15 in the worktree `D:\nitznutz-lands` (branch `lands-ux`). It makes steps 2.1 to 2.5 and 2.7 of `docs/milestones/M11.md` buildable. It does not change a skill, a prerequisite or a mastery rule. Where it adds to M11 (the swap count, the Together evidence rule, the exempt list, the two small template extensions) it says so, and §9 asks the owner.

**Binding:** M11 §2 (the arc), §6 (criteria 5 to 8) and the owner's answers of 2026-11-14 (the host teaches the Show and the Together lead-ins in its own voice, and the companion asks, hints and gives feedback; caps as written; level before age; SHP-B-05 and B-06 join the path). L7-3 (a first meeting is not evidence). No timers, streaks or guilt. No paid voicing by any agent: every new line is text with a pending clip until the owner's voicing round.

All counts come from `content/starter` on this branch (1,206 land activities, 201 lessons, 112 skills), read with a throwaway script that is not in the repo.

---

## 0. In one page

1. **Every land lesson runs Recall, Show, Together, Alone, Use.** The host shows the idea once and stops before the last step, which the child does. Then comes one guided item. Then the child works alone, and the lesson ends with one item in a new setting.
2. **The child's level decides whether a Show plays; age decides only how it is paced.** A first meeting gets the full Show. A skill still being learned gets a short reminder the child can skip. A mastered skill gets no Show and no Together.
3. **Evidence.** A Show writes nothing. A Together item writes nothing on the first meeting and counts as a hinted answer (level 2) after that. Alone, Use and Recall are scored as today.
4. **Length caps by look stage:** at most 5 screens and about 3 minutes at P1, up to 9 screens and about 6 minutes at P4 (§2.5). Lessons today run 1 to 12 items.
5. **308 tap items change** with data only: 300 move to existing hands-on templates and 8 Band C fact items become typed answers. 265 of the 308 work today; 43 need the two small extensions of step 2.2. 7 more pick-only items that are not taps also change, and 8 new `shape_builder` activities make SHP-B-05 and B-06. With these changes every non-exempt skill meets the caps of M11 criterion 6, and every land and band is at 50% picks or less once the exempt skills are left out.
6. **New Hebrew:** about 416 host lines (about 21,500 letters without nikud), spread over the six land hosts, plus about 410 narrator lines for the changed items (about 22,700 letters).
7. **Pilot land: Shape Forest.** Today it picks the most (Band B is 100% picks). All its swaps work with no template change, so the pilot tests the arc on its own. It is small: 17 skills, 44 swaps and 8 new items.

---

## 1. Today, from the packs

| Land, band | Activities | `tap_answer` | Pick-only share | Lessons | Items per lesson (min / median / max) | `estimatedMinutes` |
|---|---|---|---|---|---|---|
| Counting Hills A | 139 | 68 | 71% | 26 | 1 / 5 / 8 | 3–6 |
| Counting Hills B | 216 | 123 | 67% | 32 | 4 / 6 / 12 | 3–6 (mostly 5) |
| Counting Hills C | 115 | 92 | 74% | 12 | 8 / 9 / 12 | 6–8 |
| Market A | 54 | 40 | 74% | 12 | 3 / 4.5 / 8 | 3–4 |
| Market B | 190 | 127 | 74% | 29 | 3 / 6 / 12 | 5–6 |
| Market C | 71 | 65 | 77% | 8 | 8 / 8.5 / 11 | 7–8 |
| Colour Bay A | 66 | 54 | 91% | 13 | 1 / 5 / 8 | 2–6 |
| Colour Bay B | 42 | 31 | 81% | 8 | 3 / 6 / 6 | 5 |
| Shape Forest A | 79 | 60 | 81% | 17 | 1 / 4 / 8 | 2–6 |
| Shape Forest B | 51 | 42 | 100% | 10 | 4 / 5 / 7 | 5 |
| Riddle Grotto A | 84 | 63 | 82% | 16 | 1 / 5 / 8 | 3–4 |
| Riddle Grotto B | 51 | 32 | 82% | 8 | 4 / 6 / 8 | 5 |
| Robot Harbour A | 32 | 16 | 56% | 7 | 2 / 5 / 8 | 4–5 |
| Robot Harbour B | 16 | 2 | 50% | 3 | 4 / 6 / 6 | 5 |

- The pick-only share counts `tap_answer` with a choice, `match_pairs`, `spot_error` and `flash`, as M11 criterion 6 does. Keypad answers (19 items, all Band C) are not picks.
- **No lesson opens with teaching.** First items: 155 picks (137 `tap_answer`, 9 `spot_error`, 5 `match_pairs`, 4 `flash`) and 46 others. The 125 activities marked `purpose: "learn"` (123 in Numbers) are played and scored like any other item.
- **Hints.** Hint level 2 is `highlight_objects_sequentially` in 1,029 activities and `show_fingers` in 176. §5.5 now limits lighting objects one by one to level 1 (step 2.3).
- **Weak diagnosis in the taps that stay.** Of the taps not swapped, 280 lack two tagged distractors: 203 three-option items have fewer than two tags, and 77 two-option items have their one distractor untagged. Examples: `b.mathb10.1` and `log.pair.sock` have no tags at all.
- **SHP-B-05 and SHP-B-06 are not in the pack yet:** no skill file, no activity (the owner's Q4 adds them).

---

## 2. The lesson arc

### 2.1 The five parts

| Part | What happens | Who speaks | Scored |
|---|---|---|---|
| **Recall** (0–1 item) | One item of an earlier skill: the lesson skill's prerequisite, or a skill of this land that is due by FSRS | companion | yes, as today |
| **Show** (1 screen) | The host does a worked example on the skill's main hands-on template, narrated, and **stops before the last step**. The child does that step. A wrong touch gets "let's look again" and the host's hand points; nothing is written. For predict-then-watch skills (below), the host first asks "what will happen?" and the child taps a guess (unscored); then the host runs it. | host | **never** |
| **Together** (1–2 items) | An ordinary activity of the skill played with a **lead**: the host does the first *k* steps with its hand, and the child finishes | host lead-in, then companion | see §2.2 |
| **Alone** (2–5 items) | Today's items, ordered by the fade rule (§5) | companion | yes |
| **Use** (0–1 item) | The idea in a new setting (a story R3, the shop, the robot) or an understanding check (U1–U6, often today's `spot_error`) | companion | yes |

**Predict-then-watch skills:** COL-B-01; LOG-A-04, A-05, A-06, A-07, B-01, B-02, B-04; every CS skill (A-01, A-03, A-04, A-05, B-01, B-04). Prediction before observation makes children commit to an idea and notice when it fails (White and Gunstone 1992).

**The lead, one meaning per template** (one engine mechanism: the template's worked-example player, stopped after *k* steps; the Show is the same player with *k* = all steps but the last):

| Template | One lead step |
|---|---|
| `give_n` | the host moves one object (a frame cell fills) |
| `count_tap` | the host touches one object and says its number |
| `sort_drag` | the host drops one item in its bin and says why ("three straight sides") |
| `build_pattern` | the host places one cell |
| `number_line` | the host makes one hop (the arc is drawn and the number said) |
| `balance` | the host puts one block on a pan |
| `shape_builder` | the host places one piece |
| `robot_path` | the host lays one arrow card |
| `shop_pay` | the host lays one coin |
| `tap_answer` (Together only) | the host says the strategy and the hint-1 picture shows before the child taps. No option is removed. |

### 2.2 Evidence, consistent with L7-3

- **Show:** writes nothing, ever (`purpose: "show"`). This widens `_writesNoAnswer` in `engine_adapter.dart`, as M11 2.1 planned.
- **Together on a first meeting** (a visit in which the full Show of this skill played): **writes nothing**: no `correct`, no `incorrect`, no tag. This follows L7-3 and the owner's L7 answer to Q1. The host has just done most of the item, so a right answer shows that the child copied the host, not what the child knows.
- **Together on a later visit:** the engine reads it as an answer given **at hint level 2**. This works like the copy rule in `engine.dart` `_effectiveHint`: it is evidence, at reduced weight, and it never counts towards the "independent correct" condition of mastery. A wrong answer writes its tag, because by then the child has met the skill.
- **Alone, Use and Recall are scored as today, also on a first meeting.** This differs from L7 on purpose:
  1. An Alone item is a new instance (other numbers, other objects), not the word the child heard seconds before.
  2. The tags of first attempts are the diagnosis that §5.3 needs (M-CNT-DOUBLE, M-SHP-PROTO).
  3. Fresh mastery already needs 4 to 6 independent right answers over at least 2 days, so one good visit cannot make a skill mastered.
  
  The owner decides this (Q4).
- A press on the host's "show me" hand during an Alone item is hint level 3 for that item (a worked example), never a wrong answer.

### 2.3 When a Show plays: by the child's level

The child's state on the skill comes from the engine (`SkillStatus`, the BKT estimate `p` and the last visit).

| State of the skill for this child | Show | Together | Alone starts at |
|---|---|---|---|
| `ready` or `notStarted` (first meeting) | **full** (no skip) | 1 item; a second if the first had a wrong touch | rung 0 (§5) |
| `learning` with p < 0.6, **or** the last visit ended with a worked example or two errors in a row, **or** 14 days or more since the skill was last practised | **reminder**: the full Show sped up, with its key line only, skippable by a touch | 1 item (hint level 2 evidence) | rung 0 |
| `learning`, p ≥ 0.6, last visit clean, fewer than 14 days | none: the host greets with the skill's name only | none | rung 1 |
| `freshMastery` or `durableMastery` | none (expertise reversal: worked examples get in the way of children who already know; Kalyuga and others 2003) | none | rung 2 |
| `needsRevisit` (revisit missions keep their shape, M11 §2) | none in the mission. The re-teach of §5.7 opens with the Show reminder **if** its representation differs from both the original teaching and the failed check; otherwise with a hint-3 worked example in a third representation (today's rule) | — | one rung below the failed check |
| `gap` (a diagnostic walk found a missing prerequisite) | the **prerequisite's full** Show, before its repair items | 1 item | rung 0 |
| Placement result "knows it" / "learning" | as `freshMastery` / as `learning` with p < 0.6 | | |
| On request (the host's hand button on Together and Alone screens) | the reminder (see §2.2 for the evidence) | | |

- **Age never decides whether a Show plays.** A 7-year-old new to SHP-B-01 gets the full Show; a 4-year-old who has mastered NUM-A-04 gets none.
- **Age decides the pacing only.** P1 and P2: one instruction per beat, at most 3 demonstrated moves, slower motion. P3 and P4: up to 2 moves per beat, at most 4 moves.
- **A lesson with two new skills** (32 lessons today have 2 or 3 skills) gets one full Show (the first new skill's). Any other new skill gets a reminder Show just before its first item. At most two Show screens per lesson.

### 2.4 The Show itself

- A Show is its own activity per skill: **114 new activities** (the 112 skills plus SHP-B-05 and B-06), reused by every lesson of the skill.
- Its template is the skill's main hands-on template from §3, including for skills whose Alone items stay picks (the Show of COL-A-02 is a `sort_drag`, even though most of its Alone items are taps).
- At most **3 host lines**:
  1. The opening: what we do.
  2. The key idea, the line the reminder replays.
  3. The hand-over: "now you put the last one".
  
  Predict-then-watch skills add 1 predict line.
- **Duration:** the full Show takes at most 25 seconds at P1 and P2 and 30 seconds at P3 and P4. The reminder takes at most 8 seconds.
- **Met before asked (a lighter version of L7-5):** the Show declares the words it teaches (`teaches`: shape names, colour names, ordinal words, solid names, day names). Every option label of a scored item of the skill must be in its own `teaches` or in an earlier skill's. The validator warns; it does not refuse.

### 2.5 Length caps by look stage (B-29: P1 to 3;5, P2 3;6–4;11, P3 5;0–6;5, P4 6;6 and up)

| Stage | Recall | Show | Together | Alone | Use | Screens at most | Target minutes |
|---|---|---|---|---|---|---|---|
| P1 | 0 | 1 | 1 | 2 | 0 | **5** | **≤ 3** |
| P2 | 0–1 | 1 | 1 | 3 | 0–1 | **6** | **≤ 4** |
| P3 | 1 | 1 | 1–2 | 3–4 | 1 | **8** | **≤ 5** |
| P4 | 1 | 1 | 1 | 4–5 | 1 | **9** | **≤ 6** |

- The host's greeting and the celebration are not counted.
- When the Show and Together are dropped (a mastered skill), Alone takes their places up to the screen cap.
- A lesson's authored Alone list is a **pool**: items the controller does not serve stay for the next lesson and for revisits.
- This replaces `itemsByStage` (3–4, 3–5, 5–8, 8–12) for land lessons only; missions, revisits, warm-ups and the language courses keep it.
- Today, P4 lessons serve up to 12 scored items. The arc serves at most 7 (Recall, 5 Alone, Use) after teaching. That is shorter, but the leftover items are spaced over later lessons and revisits instead of being done in one visit (Q1).

---

## 3. The best representation per skill family

Order inside a skill: concrete, then pictorial, then symbolic (concreteness fading; Fyfe and others 2014). Templates are existing ones; "(2.2)" marks the two small extensions of step 2.2.

### 3.1 Counting Hills (Nekudi): 36 skills

| Skill group | The host shows (Show) | Together | Carried by |
|---|---|---|---|
| Counting words: NUM-A-01, A-02, B-01, B-02, B-03, B-17, C-01 | The frog hops along a labelled track, one hop per word, and Nekudi says each word; at a decade (19→20) the hop crosses a marked ten. Count-back is the rocket on the same line, going left | Nekudi makes the first hops; the child makes the last | `number_line` jump (hops of 1, −1, 2, 10) |
| One-to-one and cardinality: A-03, A-04, A-06, A-09, B-04, B-05 | Nekudi touches each ladybug once (it lights), says the last number twice: "five: there are five" | Nekudi touches the first two | `count_tap`, `give_n` |
| Subitising: A-05, A-10, B-09 | A dot or finger pattern flashes; Nekudi says "I didn't count: I saw three". On a ten-frame: a full row is five, "and three more is eight" | Build the pattern on the frame; Nekudi lays the first row | `flash`, `give_n` frame (Clements 1999 on subitising; ten-frames: Bobis 1996) |
| Numerals: A-07, A-08, B-06, B-08 | The numeral goes on the basket; Nekudi puts that many apples in | Nekudi puts the first apple | `give_n` (numeral shown with `prompt.math`), `count_tap`; `number_line` place for teens |
| Comparing: A-11, A-12, B-10, C-04 | Two rows matched one to one; the one left over has "more" (A). Two numbers placed on the line: "further right is bigger" (B, C) | Nekudi places the first number | A: waits for Stage 3.1 (two ten-frames in rows); B, C: `number_line` place (Siegler and Ramani 2008: linear number games) |
| Ordinals: A-13 | Animals join a queue facing its front; Nekudi counts "first, second, third" | — | waits for Stage 3.2 (order cards) |
| Zero: A-14 | The birds fly from the nest: "none left, zero" | — | waits for Stage 3.1 |
| Number line: B-11, B-13, C-06, C-09 | One more is one hop right, one less one hop left; +10 is a long hop | Nekudi does the first hop | `number_line` |
| Part-whole: B-14 | The frame shows 5; "make it 8": three more go in, "5 and 3 is 8" | Nekudi puts one | `give_n` prefilled frame (2.2) |
| Teens and place value: B-16, C-02, C-03 | One full frame is ten; "and four more is fourteen". For C: ₪10 coins are tens, ₪1 coins are ones | Nekudi fills the ten | `give_n` prefilled frame (2.2); `shop_pay` with ₪10 and ₪1 (the rods of Stage 3.3 are the first rep later) |
| Even and odd: B-18 | Socks paired two by two: "everyone has a partner: even" | Nekudi pairs the first | `sort_drag` share, n/2 bins (even counts only; odd ones stay taps with the pairing at hint 2) |
| Writing: B-07 | as today (`trace`) | | `trace` |

### 3.2 Market Village (Grandma Pnina): 26 skills

| Skill group | The host shows | Together | Carried by |
|---|---|---|---|
| Join and take away: A-01, A-02, B-01, B-07 | A: acts it out with counters (Stage 3.1). B-01: the frog's hops on the line, "3 and 2 more" | Pnina makes the first hop | `number_line` jump; A-01, A-02, B-07 wait for 3.1 |
| Part-part-whole and make ten: B-02, B-06, NUM link B-09 | The frame holds 4 of 6; "how many more to make 6?": she adds them and counts | Pnina adds one | `give_n` prefilled frame (2.2) |
| Symbols: B-03, B-04, B-08, C-01, C-03 | `3 + 4` as start 3, hop 4. `8 + 5` as two hops: +2 to ten, then +3 (§5.5 Ladder 2, step 3). Count on from the larger. Tens: hops of ten | Pnina hops to ten; the child finishes | `number_line` jump; C-01 and C-02 fact fluency also as keypad answers (recall) |
| Equals and unknowns: B-09, B-18, C-02 | The balance: 7 blocks on one side, 3 on the other; she adds blocks until level: "3 and 4 is the same as 7" (§5.5 Ladder 4) | Pnina adds the first block | `balance` weigh (McNeil and Alibali 2005 on "=" as "the same as") |
| Equal groups: A-03, B-10 | 6 apples dealt onto 2 plates, one at a time | Pnina deals the first round | `sort_drag` share |
| Measure: A-04, B-13 | Feather and stone on the balance; the big one and the small one sorted | Pnina puts one | `balance` compare; `sort_drag` big/small |
| Time: A-05, B-14, B-15 | Morning, noon, evening, night laid in order. Days as cards in order from Sunday. Clock: as today | Pnina lays the first card | `build_pattern` fill in order (a start dot marks the first place, so the direction is shown, not assumed); `clock_set` |
| Money: A-06, B-16, B-17 | Real Israeli coins as they look; paying exactly; agorot and shekels sorted | Pnina lays the first coin | `give_n`, `shop_pay`, `sort_drag` |
| Data: A-07, B-19 | Sort the fruit into two columns, then "which column is taller?" | Pnina sorts the first | `sort_drag` (the columns of Stage 3.5 later) |

### 3.3 Colour Bay (Goni): 12 skills

| Skill group | The host shows | Together | Carried by |
|---|---|---|---|
| Match and name: A-01, A-02, A-03, A-06 | Goni puts red things (a ball, a flower, a balloon) in the red bucket and says "red" each time, so the word is heard on different objects | Goni puts the first | `sort_drag` (colour bins; decoys of the same object in another colour carry M-COL-ONEATTR) |
| Sort by colour ignoring shape: A-04, B-04 | Shapes of mixed form sorted by colour only | Goni sorts one | `sort_drag` (M-SORT-SHIFT) |
| Usual colours that vary: A-05 | Yellow and green bananas both go in the banana box | Goni puts one | `sort_drag` (M-COL-OBJECT) |
| Colour and noun: A-07 | "The blue flower" goes in the vase; blue balls and red flowers stay out | Goni shows one | `sort_drag` |
| Mixing: B-01 | Predict, then watch the tubs mix | — | taps (predict) until Stage 3.4 |
| Shades: B-02, B-03, B-06 | Three blues laid light to dark; a light and a dark blue both go in the blue bin | Goni lays the first | `build_pattern` in order; `sort_drag` (M-COL-SHADE) |

Colour carries the answer only here (M11 §7). Every sprite keeps its ink outline.

### 3.4 Shape Forest (Kubi): 15 skills + SHP-B-05, B-06

| Skill group | The host shows | Together | Carried by |
|---|---|---|---|
| Match: A-01 | A shape-sorter box: each shape goes in its hole | Kubi puts one | `shape_builder` |
| Name and any orientation: A-02, A-03, A-04, B-01, B-03 | Kubi runs a hand along a thin, upside-down triangle: "three straight sides, closed". It goes in the triangle basket; an open figure and a curved one stay out. A long thin rectangle is a rectangle; a tilted square is a square | Kubi sorts the first | `sort_drag` with non-prototypical examples and not-shapes (Clements and others 1999; Fisher and others 2013) |
| In the world: A-05 | A plate, a window and a sign sorted to circle, rectangle, triangle | Kubi sorts one | `sort_drag` |
| Straight and curved, polygons: A-10, B-04 | Kubi traces a side: straight or curved; closed or open | Kubi sorts one | `sort_drag` (M-SHP-CLOSED) |
| Count sides: B-02 | Kubi lights the sides one by one and counts them, then sorts by count | Kubi sorts one | `sort_drag` bins "3 sides", "4 sides" |
| Solids: A-07, B-08, B-09 | A ball rolls, a box stacks (no cylinder in Band A: it does both). Cones and cylinders shown as real objects. A solid is pressed in sand and its face is the stamp | Kubi does one | `sort_drag` (B-08 needs real-object sprites, DD) |
| Build: A-06, B-05, B-06 | A picture filled from tiles; two triangles make a square | Kubi places the first | `shape_builder` (8 new activities) |
| Positions: A-08 | The ball goes on, under, in the box | — | waits for a drag mode in the lands (§4.4) |

### 3.5 Riddle Grotto (Timi): 17 skills

| Skill group | The host shows | Together | Carried by |
|---|---|---|---|
| Same, odd one out, sort: A-01, A-02, A-03 | Timi gathers all the apples (red balls stay out: "round and red, but not an apple") | Timi puts one | `sort_drag` (M-COL-ONEATTR, M-SORT-SHIFT) |
| Is it a pattern: A-04 | Predict "does it repeat?", then Timi claps each tile: red-blue, red-blue | — | `sort_drag` "repeats / doesn't" (pattern-strip sprites, DD) |
| Copy, extend, fix: A-05, A-06, A-07, B-01 | Predict "what comes next?"; Timi lays two more tiles, then brackets the unit: red-blue, red-blue | Timi puts the next cell | `build_pattern` given cells (2.2). Patterning is a predictor of early maths and can be taught to preschoolers (Rittle-Johnson and others, 2015 onwards; the effect on later maths is still being studied) |
| Unit and growing: B-02, B-04 | Bracket the part that repeats; a tower grows by one each time | Timi builds the first | `build_pattern` (B-02 waits for an extension, §4.4) |
| Order: A-08, A-10, B-11 | Egg, cracked egg, chick: "first, then, at the end". Towers from small to big | Timi lays the first | `build_pattern` fill in order |
| Things that go together: A-09 | Sock with the shoe, spoon with the plate | Timi pairs one | `sort_drag` (partner bins) |
| Rules and clues: B-06, B-08, B-09 | Bins already show one sample each; "how did I sort?" "Not red and not a circle" | Timi sorts one | `sort_drag` (hidden rule from the bin samples) |

### 3.6 Robot Harbour (Tza'adon): 6 skills

| Skill group | The host shows | Together | Carried by |
|---|---|---|---|
| Steps of a routine: A-01, A-05 | Predict "what do we do first?"; then Tza'adon lays paste, brush, rinse in order. A soap card in tooth brushing is "oops" | Tza'adon lays the first | `build_pattern` in order; A-05 with given cells (2.2). Sequencing first, unplugged-style, before arrows (Bers 2018) |
| Direct control, plan, plan in a grid: A-03, A-04, B-01 | Predict "where will I stop?", then run the arrows | Tza'adon lays the first arrow | `robot_path` |
| Debug: B-04 | Predict, run, find the wrong arrow | — | `spot_error` until a robot "given program" mode (§4.4) |

---

## 4. The tap swaps

### 4.1 Which taps move and which stay

**A tap moves** when:
- the skill's act is *doing* something (count out, build, order, sort, place, balance, pay);
- the tap only asks for the result of an action the child could carry out; and
- an existing template carries out that action with the same numbers or objects.

The swapped activity:
- keeps its **id** and gets `revision + 1`;
- gets the new template's `variantGroup` (`give`, `sort`, `numline`, `build`, `scale`, `pay`, `shapebuild`, `count-tap`);
- gets a `representation` of `concrete` for objects moved and `pictorial` for `number_line`;
- carries **at least two misconception tags it can record**: decoy items for `sort_drag`; classifiers for `give_n` and `balance`; `misconception` and `mirrorMisconception` for `number_line`; palette tags for `build_pattern` (2.2). A skill whose §4 row lists no misconception uses the nearest catalogue tag that fits (M-COL-ONEATTR, M-SORT-SHIFT), or none.

**A tap stays** when:
1. **Recognition is the act:** naming a numeral, colour or shape when it is said; subitising; odd one out. These are the 11 skills with the 80% cap.
2. **It is a prediction** (COL-B-01, robot endpoints).
3. **It is the symbolic end of the fade:** fact items for children near mastery (Band B and C symbolic rows).
4. **Hiding is the point:** counting on from a closed basket (`c.mathb04.11`, `.12`).
5. **It is a check:** U3 transfer, U5 `spot_error`, U6 explain-back.
6. **Its hands-on form needs a Stage 3 template or a §4.4 extension** (the exempt list).

**Taps that stay must be well tagged.** Every three-option tap has at least two tagged distractors, and a two-option tap has its distractor tagged. 203 three-option taps and 77 two-option taps fail this today; they are fixed in the same CE run as their land. This needs no new voice: wrong answers play the shared misconception lines `vo:fb.*`.

**Band C recall:** 8 symbolic fact items of MATH-C-01 and C-02 become keypad answers (`answer.type: "number"` with tagged `expected` values, as the 19 Band C keypad items already do). Typing the answer is recall, not recognition. The retrieval benefit is larger for produced answers than for recognised ones (Kang, McDermott and Roediger 2007, adults; evidence in young children is thinner). A keypad answer is not a pick under criterion 6.

### 4.2 Counts (exact, per land and band)

| Land, band | Taps swapped | → template (count) | Need 2.2 | Other picks changed | Pick share after (all skills / without exempt) |
|---|---|---|---|---|---|
| Counting Hills A | **15** | number_line 7, give_n 5, count_tap 3 | 0 | 4 `flash` → `give_n` frame (NUM-A-05, A-10) | 57% / **42%** |
| Counting Hills B | **52** | number_line 33, give_n 15, sort_drag 4 | 12 | 2 `flash` → `give_n` frame (NUM-B-09) | **42%** |
| Counting Hills C | **28** | number_line 21, shop_pay 7 | 0 | — | **50%** |
| Market A | **13** | sort_drag 8, balance 2, build_pattern 3 | 0 | — | 50% / **29%** |
| Market B | **47** | number_line 17, give_n 10, sort_drag 11, build_pattern 5, balance 4 | 10 | — | 49% / **47%** |
| Market C | **20** | number_line 9, keypad 8, balance 2, shop_pay 1 | 0 | — | **49%** |
| Colour Bay A | **27** | sort_drag 27 | 0 | — | **50%** |
| Colour Bay B | **9** | build_pattern 5, sort_drag 4 | 0 | — | 60% / **48%** |
| Shape Forest A | **23** | sort_drag 19, shape_builder 4 | 0 | — | 52% / **46%** |
| Shape Forest B | **21** | sort_drag 21 | 0 | 1 `match_pairs` → `sort_drag` (SHP-B-09); **+8 new `shape_builder`** (SHP-B-05, B-06) | **49%** |
| Riddle Grotto A | **30** | sort_drag 14, build_pattern 16 | 8 | — | **46%** |
| Riddle Grotto B | **15** | build_pattern 9, sort_drag 6 | 9 | — | 53% / **47%** |
| Robot Harbour A | **8** | build_pattern 8 | 4 | — | **31%** |
| Robot Harbour B | 0 | — | 0 | — | 50% / **20%** |
| **Total** | **308** | sort_drag 114, number_line 87, build_pattern 46, give_n 30, shop_pay 8, balance 8, keypad 8, shape_builder 4, count_tap 3 | **43** | **7** changed, **8** new | |

- **"Need 2.2"** counts the items that cannot be played without an extension: `give_n` prefilled frames and `build_pattern` given cells. The 46 `build_pattern` swaps can all be played today, but their second tag (V6) comes with the palette tags of 2.2, and the 8 `balance` swaps' second tag comes with its classifiers.
- **By land:** Counting Hills 95, Market 80, Riddle Grotto 45, Shape Forest 44, Colour Bay 36, Robot Harbour 8.
- **The pack keeps 1,206 land activities, plus 114 Shows and 8 new `shape_builder` items.**
- **Why 308 and not M11's "about 180":** the caps the owner approved need it. The per-skill minimum alone is 313 picks, before the exempt skills are set aside.
- **Every swap, per skill:** the ids, the target template and the 2.2 marks are fixed in the plan the CE re-cuts from (the throwaway script). The per-skill counts:

| Land | Skill (swaps) |
|---|---|
| Counting Hills | NUM-A-01 3, A-02 3, A-07 6, A-08 3; B-01 3, B-02 4, B-03 4, B-06 3, B-08 3, B-09 3, B-10 6, B-11 8, B-14 4, B-16 5, B-17 5, B-18 4; C-01 6, C-02 4, C-03 7, C-04 6, C-09 5 |
| Market | MATH-A-04 6, A-05 3, A-07 4; B-01 4, B-02 5, B-03 5, B-04 2, B-06 5, B-08 6, B-10 4, B-14 5, B-16 2, B-18 4, B-19 5; C-01 8 (5 keypad), C-02 5 (3 keypad), C-03 7 |
| Colour Bay | COL-A-01 3, A-02 4, A-03 4, A-04 4, A-05 4, A-06 4, A-07 4; B-02 5, B-03 4 |
| Shape Forest | SHP-A-01 4, A-03 4, A-04 4, A-05 3, A-07 4, A-10 4; B-01 4, B-02 4, B-03 3, B-04 4, B-08 4, B-09 2 |
| Riddle Grotto | LOG-A-01 4, A-02 2, A-04 4, A-06 4, A-07 4, A-08 4, A-09 4, A-10 4; B-01 5, B-04 4, B-06 3, B-09 3 |
| Robot Harbour | CS-A-01 4, A-05 4 |

### 4.3 Worked examples (three per land, real ids)

**Counting Hills**
- `b.numb11.7` "add one more to three, how many now?" (symbolic tap) becomes **`number_line` jump**: 0–10, labels 0–10, `start: 3`, `hops: [1]`, `target: 4`, `misconception: M-CNT-SEQ`, `mirrorMisconception: M-NL-DIR`, `representation: pictorial`. One more is one hop to the right.
- `b.numb16.1` "eleven is ten and how many more?" becomes **`give_n` prefilled frame (2.2)**: the first frame is full (10). "Make eleven": the child adds 1. Classifiers: `took_more` → M-NUM-TEEN (adds eleven), `took_all` → M-CNT-CARD, `took_fewer` → M-PART-MISS.
- `show.apples.3` "where are three apples?" becomes **`give_n`**: the numeral 3 shows in `prompt.math`, the pile has 6 apples. Classifiers: `took_more` → M-CNT-DOUBLE, `took_fewer` → M-CNT-SKIP, `took_all` → M-CNT-CARD. This is the numeral-to-set direction (U4).

**Market Village**
- `b.mathb08.1` `8 + 5 = ?` becomes **`number_line`** 0–20: `start: 8`, `hops: [2, 3]` (to ten, then on), `target: 13`, M-CNT-SKIP, mirror M-NL-DIR.
- `b.mathb18.1` `3 + ? = 7` becomes **`balance` weigh**: left 7 blocks, right 3; the child adds blocks to level (4). With the balance classifiers of 2.2: adding 7 → M-EQ-OPER; adding 10 → M-PART-MISS.
- `b.mathb10.1` "2 plates, 3 apples each, how many?" (untagged today) becomes **`sort_drag` share**: 6 apples dealt to 2 plates, `misconception: M-SHARE-UNEQ`. The total is asked by the next item.

**Colour Bay**
- `col.sort.blue` "who else is blue?" becomes **`sort_drag`**, bins "blue" and "not blue". Items: a blue flower, a blue ball, a blue square → blue; a yellow balloon (the model's object, M-SORT-SHIFT) and a green balloon → not blue.
- `b.colb02.2` "which is the lightest?" becomes **`build_pattern` in order** (light to dark): palette `shade_blue_1..3` and one decoy, `shade_green_2` (palette tag M-COL-SHADE, 2.2). The pattern tag is M-SER-ENDS.
- `col.world.banana` becomes **`sort_drag`** "bananas / not bananas": `banana_green` and `banana_yellow` go in; `ball_yellow` (M-COL-OBJECT) and `ball_green` (M-COL-ONEATTR) stay out.

**Shape Forest**
- `shp.any.thin` becomes **`sort_drag`** "triangle / not a triangle". In: `shape_triangle_thin`, `shape_triangle_down`, a big and a tiny triangle. Out: `shape_open` (M-SHP-CLOSED), `shape_curved` (M-SHP-CLOSED), `shape_circle` (M-SHP-PROTO).
- `b.shpb04.2` (tick or cross on an open figure) becomes **`sort_drag`** "closed with straight sides / not". Items: a pentagon, `shape_square_tilt`, `shape_open` (M-SHP-CLOSED), `shape_curved` (M-SHP-CLOSED).
- `shp.match.circle` becomes **`shape_builder`** shape-sorter: three holes (circle, square, triangle) and one decoy (`shape_rect`, M-SHP-SQRECT). The current tag on the square option (M-COL-ONEATTR) is wrong for a shape-match item and goes.

**Riddle Grotto**
- `log.next.animals` cat, dog, cat, dog, cat, ? becomes **`build_pattern` given cells (2.2)**: the first five cells are given and the child places the next two (dog, cat). Palette dog, cat, duck; using cat first → M-PAT-NEXT (palette tag), duck → M-PAT-UNIT.
- `log.story.egg.first` becomes **`build_pattern` in order**: 3 places, palette `egg_crack`, `chick`, `egg`, sequence egg, crack, chick, M-SEQ-CAUSE.
- `log.same.apple` "where is another apple?" becomes **`sort_drag`** "apples / not apples": `apple`, `apple_green` in; `ball_red` (M-COL-ONEATTR) and `balloon_red` (M-COL-ONEATTR) out.

**Robot Harbour**
- `cs.routine.teeth.first` "what do we do first?" becomes **`build_pattern` in order**: `step_paste`, `step_brush`, `step_rinse`, M-SEQ-CAUSE.
- `cs.wrong.teeth` "what got here by mistake?" (untagged today) becomes **`build_pattern` given cells (2.2)**: paste, _, rinse are given; the palette holds `step_brush` and `step_soap` (palette tag M-SEQ-CAUSE). The intruder is found by fixing the routine.
- `cs.routine.wash.last` "what do we do at the end?" becomes **`build_pattern` in order**: `step_tap`, `step_soap`, `step_towel`, M-SEQ-CAUSE.

### 4.4 Exempt skills (listed by name, as criterion 6 requires)

| Skill | Why it waits | Where it lands |
|---|---|---|
| NUM-A-11, NUM-A-12 | Compare by matching needs two rows lined up | Stage 3.1 (two ten-frames as rows) |
| NUM-A-14, MATH-A-01, MATH-A-02, MATH-B-07 | Join, take away, and taking all away to zero | Stage 3.1 |
| NUM-A-13 | A queue with place words | Stage 3.2 (order cards) |
| COL-B-01 | Mix, pour, see | Stage 3.4 |
| SHP-A-08 | Position words need a drag into a place in a scene | **not in Stage 3:** proposal 2.2c, `listen_do` drag mode allowed in the lands (AD checks it is generic) |
| LOG-B-02 (all `spot_error`) | "Build the unit": a long model and a short row | **not in Stage 3:** proposal 2.2c, `build_pattern` with a model longer than its places |
| CS-B-04 (all `spot_error`) | Fixing a given program | **not in Stage 3:** proposal 2.2c, `robot_path` with given steps (the twin of `build_pattern` given cells) |

---

## 5. Hands-on by level: the fade rule

The rule uses only what the engine has: `SkillStatus`, the BKT estimate `p`, the item's `representation` tag, the hint level of each answer, and the switching rule of §5.5.

**Rungs:**
- `concrete` and `embodied` are **rung 0** (objects moved, the body).
- `pictorial` and `story` are **rung 1** (pictures and models, including `number_line` and ten-frame flashes).
- `symbolic` is **rung 2**.

**The rung of the next Alone item of skill S:**

| Child's state on S | Order of rungs inside the lesson |
|---|---|
| first meeting, or p < 0.4 | 0, 0, then 1 after two rung-0 right answers at hint level ≤ 1; no rung 2 |
| 0.4 ≤ p < 0.7 | 0 (one item), 1, 2 (one item) |
| learning, p ≥ 0.7 | 1, 2; rung 0 only after an error |
| `freshMastery` or `durableMastery` | 2, 1; never 0 first; U-checks preferred |

1. **Step down:** after a tagged wrong answer, or after a hint-3 worked example, the next item of S is one rung lower (not below 0). This is the §5.5 switching rule, given a direction.
2. **Step up again** after two right answers in a row at hint level ≤ 1.
3. **A missing rung:** when the pool has no item at the wanted rung, take the nearest more concrete rung while p < 0.7, and the nearest more symbolic one from p ≥ 0.7.
4. **The bandit of §10.5 still chooses among items of the same rung** (the child's best repair representation).
5. **Mastery conditions do not change.** "At least two representations" now holds by construction.
6. **Level, not age.** The rung comes from the child's state on S alone. A 7-year-old new to a skill starts at rung 0 with P4 pacing; a 4-year-old with fresh mastery starts at rung 2.
7. **A lesson may not starve the rule.** For each of its skills, a lesson's Alone pool holds at least one rung-0 item and one rung-1 item, and a rung-2 item when the skill has symbols (all NUM-B and NUM-C, MATH-B and MATH-C).

---

## 6. New host lines and voices (for the hebrew-text-editor and the voice-and-sound-director)

The host speaks the Show, the predict question, the Together lead-in and the hand-over. The companion and narrator speak everything else, as today. Line lengths are estimated from today's hint-3 lines: a mean of 54 letters without nikud (88 with).

| Line family | Per | Lines |
|---|---|---|
| **Show**: opening, key idea (also the reminder), hand-over of the last step | 3 per skill × 114 | 342 |
| **Predict** ("what will happen?") | predict-then-watch skills | 14 |
| **Together lead-ins**, generic per template ("I'll put the first one; you finish") | about 5 per host × 6 | 30 |
| **Hand-over to the companion** (Alone starts) | 3 per host × 6 | 18 |
| **"Show me" button replies** | 2 per host × 6 | 12 |
| **Total** | | **416** |

| Host (land) | Skills | Lines | Letters, no nikud (with nikud, about) |
|---|---|---|---|
| Nekudi (Counting Hills) | 36 | 118 | 6,300 (10,100) |
| Grandma Pnina (Market) | 26 | 88 | 4,650 (7,400) |
| Kubi (Shape Forest) | 17 | 61 | 3,150 (5,050) |
| Timi (Riddle Grotto) | 17 | 68 | 3,450 (5,550) |
| Goni (Colour Bay) | 12 | 47 | 2,400 (3,800) |
| Tza'adon (Robot Harbour) | 6 | 34 | 1,600 (2,550) |
| **All six** | 114 | **416** | **about 21,500 (about 34,500)** |

**Narrator lines** for the changed items (the existing lesson narrator's voice):
- 315 new prompts (the 308 swaps and the 7 other changed picks);
- one worked-example line per touched skill (73), because a hands-on template's level 3 animates the steps and one line per skill fits all its items;
- 24 lines for the 8 new SHP-B-05 and B-06 activities;
- about **410 lines and about 22,700 letters** in all (about 36,000 with nikud).

The correct-feedback lines are kept where they still say the fact ("yes, red and yellow make orange"). The CE marks those that must change, at most about 100.

**For the hebrew-text-editor:**
- Every line is a draft from the CE, marked `"review": "needs-editor"`.
- A Show line is one short sentence: present tense, first person plural or the host's "I", gender-neutral to the child ("עַכְשָׁו תּוֹרְכֶם", as the pack does today).
- One instruction per line at P1 and P2. No left and right words in Band A.
- The words in `teaches` appear in the Show lines exactly as the items say them.
- The CE gives the editor one file per land in the order of §8.

**For the voice-and-sound-director:** the host voices are the nine of the owner's answer to Q2. Until the owner's voicing round, a host line shows as a bubble with a pause, as L7's pending clips do.

---

## 7. Data, validator caps and acceptance criteria

### 7.1 What changes in the pack content

1. **114 new Show activities.** Each has `purpose: "show"`, the skill's hands-on template, `show.lines` (2 to 3 host clips), `show.predict` (optional, a choice of 2 to 3) and `teaches`. The id is `show.<skill>`, for example `show.shp-a-03`.
2. **308 activities re-cut** (template, scene, answer, prompt, hints, `representation`, `variantGroup`). Their ids are kept and `revision` goes up by one. 7 more picks change (6 `flash`, 1 `match_pairs`).
3. **SHP-B-05 and SHP-B-06** get skill files, 8 `shape_builder` activities and 2 lessons, and join the Shapes `sequence` after SHP-A-06.
4. **All 201 lessons** (203 with the new ones) are authored in parts: `recall` (1–2 candidate ids, served only if that skill has been started), `show`, `together` (`[{id, lead}]`, items reused from the pool), `alone` (the pool), `use`. The generator flattens them with part marks, as L7-4 (a) does for the courses.
5. **`hints[1]`** gets an R-code different from the activity's `representation` and from level 1, and names the B-40 picture actually drawn (M11 2.3).
6. **Taps that stay** are tagged (§4.1). The re-cut items carry a few new sprites (the design-director's list): about 6 pattern strips (LOG-A-04) and about 6 real-object solids (SHP-B-08).
7. **The starter pack is signed once, by the owner, at the end of Stage 2,** after QA. Lands are not released one by one: the pilot is shown on the dev build with the dev pack.

### 7.2 Validator rules (step 2.3, in `tools/author.py` and `pack_validation.dart`)

| Rule | The build refuses |
|---|---|
| V1 | a land lesson whose `show` part is missing, or whose first served item (after an optional `recall`) is not a `purpose: "show"` activity of one of its skills |
| V2 | a Show with a `tap_answer` template (except its optional `predict`), more than 3 host lines, no `handOver: "last"`, or a skill without exactly one Show |
| V3 | a `together` entry whose `lead` is 0 or not less than the item's number of steps, or whose item is not of the lesson's skills |
| V4 | a skill over its pick cap (60% A and B, 70% C, 80% for the 11 recognition skills; Shows not counted), or a land and band over 50% without the exempt skills; the exempt list is a named constant with the step each skill waits for |
| V5 | `hints[1]` whose R-code equals the activity's `representation` or level 1's |
| V6 | a re-cut or new hands-on activity that can record fewer than 2 misconception tags (§4.1), unless its skill lists none; a three-option tap with fewer than 2 tagged distractors; a two-option tap with an untagged distractor |
| V7 | a lesson pool without a rung-0 and a rung-1 item for each of its skills, or without a rung-2 item where the skill has symbols |
| W1 (warning) | a scored option label not in the skill's `teaches` or in an earlier skill's |

### 7.3 Acceptance criteria for Stage 2 (testable)

1. **No scored opener.** In a headless playthrough of every land and band (scripted child, clips pending), the first served item of every lesson after `recall` is a Show, and the Show writes no evidence (engine test). Extends M11 criterion 5.
2. **First meeting.** For a child new to a skill, the full Show plays and the Together item writes no `correct`, no `incorrect` and no tag. The same Together item in a later visit is recorded at hint level 2 and is not counted as independent (engine tests).
3. **Show by level, not age.** In a test, the same lesson served to a 4-year-old with `freshMastery` and to a 7-year-old with `notStarted` gives: no Show to the first, the full Show to the second.
4. **Reminder.** A `learning` skill with p < 0.6 gets a reminder that a touch skips, at most 8 seconds of host speech.
5. **Caps.** Screens served per lesson are at most 5, 6, 8 and 9 for P1 to P4 (the greeting and the celebration not counted), in every lesson of the playthrough.
6. **Pick-only caps.** V4 passes. The exempt list is exactly §4.4. The playthrough reports the share per skill and per land and band.
7. **Fade.** In a simulated child per land (`simulator.dart`):
   - a new skill's first two Alone items are rung 0;
   - after a tagged wrong answer, the next item of that skill is one rung lower;
   - a mastered skill's first Alone item is rung 2 where the pool has one.
8. **Hint 2.** V5 passes, and every hint-2 screen draws its picture (none falls back to a generic one). This is M11 criterion 7.
9. **Tags.** V6 passes. A swapped item's wrong answer in the playthrough records the tag its classifier names. This is M11 criterion 8.
10. **The Show stops for the child.** Every hands-on template's worked-example player stops before the last step in a Show, and after `lead` steps in a Together item (widget tests per template; reduce motion shows end states).
11. **SHP-B-05 and B-06** are on the Shapes path and each has 4 playable activities.
12. **Nothing else moves.** The skill graph, prerequisites, mastery rules, revisit missions, warm-ups and the language courses are unchanged (existing tests stay green).

### 7.4 Where the Show and the lesson parts live until the schema has them

The activity schema has no `purpose: "show"` and the lesson schema has no parts, so no generator writes them yet. Each land's Shows, host lines and lesson parts are authored in **`content/units/arc/<land>.arc.json`** (`schema: "lesson-arc-source/v0"`; Shape Forest first). No tool reads it yet; `content/units/arc/` is outside the generators' lists, so a regeneration leaves it alone. Its parts:

- `shows[]`: `id` (`show.<skill>`), `skill`, `band`, `template`, `representation`, `handOver: "last"`, `scene` (the template's scene in pack form), `steps[]` (`by: host|child`, then `item`+`bin` for `sort_drag`, `piece`+`slot` for `shape_builder`, `to` for the `listen_do` drag; `say: "key"` marks where the key line plays; `trace`, `count`, `sticks`, `walk`, `push`, `stack`, `turn`, `stamp` name the motion of the host's hand), `lines[]` (`role` open, key, handover; `vo` `vo:host.<host>.show.<skill>.<role>`; plain text, `needs-editor`), `predict` (null in Shape Forest), `reminder` (`line: "key"`, `maxSeconds: 8`), `teaches[]` (the words as the items label them), `picture` (for the design-director), `status`, and `upgrade` where a better form waits for a drawing.
- `hostLines[]`: the Together lead-in per template, the hand-over to the companion, the "show me" replies (`vo:host.<host>.together.*`, `.handover.*`, `.showme.*`).
- `lessons[]`: `recall` (candidate ids of the prerequisite skill), `show`, `secondShow` (a reminder before the second skill's first item), `together[]` (`id`, `lead`), `alone` (the pool, rung 0 first), `use`, `poolRungs`, and `v7` where the pool lacks a rung.
- `caps`: the stage caps of §2.5.

**What the developer adds to read it (2.1 and 2.3):**
1. Schema: `purpose: "show"` and the Show fields (`show.lines`, `show.steps`, `handOver`, `teaches`, `predict`) in the activity schema, or a `show` document kind; lesson parts in the lesson schema (`recall`, `show`, `together[{id, lead}]`, `alone`, `use`), with the generator flattening them for older readers (as L7-4 (a)).
2. A generator step that turns the arc file into pack files (Show activities, lessons in parts), and puts the host lines into the voice inventory as pending clips.
3. Validator V1 to V7 and W1 (§7.2), reading the parts; plus the two template records below.
4. The flow: the lead mechanism per template (the worked-example player stopped after `lead` steps; the Show stops before the last step), the evidence rules of §2.2, the Show gating of §2.3, the caps of §2.5.
5. **Template records the pilot needs (found while building it):** (a) `sort_drag` in the lands records `answer.misconception` for every wrong drop; it must record the dropped item's own `scene.items[].misconception` when it has one (the schema and the model already carry it), else the activity's. (b) `shape_builder` records one tag for any wrong piece; a decoy needs its own tag (the arc file and `shapes.json` carry them as `decoy_tags` and `pair_tags`, which the generator does not write yet). (c) Band A `shape_builder` items should outline each place (curriculum §4.4 "each piece is outlined"); today every place is one grey shadow, which is what SHP-B-05 wants, so A-06 and B-05 now look alike.

---

## 8. Build order (small steps) and the pilot

| Step | What | Owner | Size | Pack |
|---|---|---|---|---|
| 2.1 | Unscored Show (`purpose: "show"`); lesson parts; the lead mechanism (worked-example player stopped after *k* steps) in every hands-on template; the evidence rules of §2.2; the Show gating of §2.3; the stage caps of §2.5; the "show me" button | AD; SE reads the evidence change | medium–large | no |
| 2.2 | `build_pattern` given cells (extend, fix) and palette tags; `give_n` prefilled frame; `balance` weigh classifiers (`took_more`, `took_fewer`, `took_total`) | AD | small | no |
| 2.2c (proposal, Q3) | `robot_path` given steps; `build_pattern` model longer than its places; `listen_do` drag in the lands | AD | small | no |
| 2.3 | Validator V1 to V7 and W1; the fade rule in the session order (§5); `hints[1]` corrections | AD; CE the rules | small–medium | yes (at the end) |
| 2.4a | **Pilot: Shape Forest.** 17 Shows, 44 swaps, 1 `match_pairs` change, 8 new items, tags on the taps that stay; HE edits; DD makes the solid sprites; a headless playthrough; the owner sees it on the phone (dev pack) | CE, HE, DD | medium | dev pack only |
| 2.4b | Riddle Grotto and Robot Harbour (the predict-then-watch Shows and the 2.2 `build_pattern` extension): 23 Shows, 53 swaps | CE, HE, DD (strips) | medium | dev |
| 2.4c | Counting Hills: 36 Shows, 95 swaps, 6 flash changes | CE, HE | large | dev |
| 2.4d | Market Village: 26 Shows, 80 swaps | CE, HE | large | dev |
| 2.4e | Colour Bay: 12 Shows, 36 swaps | CE, HE | small | dev |
| 2.5 | Texts to `text-ready` for all six lands (one HE run per land, already inside 2.4) | HE | — | — |
| 2.7 | QA pass: the playthrough per land and band, criteria 1 to 12, the goldens of the Show and Together states | QA | medium | — |
| end | **The owner signs the starter pack once.** Voicing is a later round run by the owner (§6) | owner | — | **yes** |

**Why Shape Forest is the pilot:**
- It picks the most (Band B 100%, Band A 81%), so the change is easiest to see on the phone.
- Every one of its swaps works on today's templates (`sort_drag`, `shape_builder`), so the pilot tests the arc and the evidence rules (2.1) without waiting for 2.2.
- It is small (17 Shows, 44 swaps).
- It carries the owner's own decision (SHP-B-05 and B-06).
- The evidence for its form is strong: non-examples and non-prototypical shapes are what change children's shape concepts.

Counting Hills matters most to the children but is the largest batch. It goes third, after the pilot and the pattern lands have tested both template extensions.

---

## 9. Questions for the owner (each with my recommendation)

1. **Shorter lessons for the oldest.** At P4, a lesson serves at most 7 scored items after the Show and Together (today up to 12). The rest stay in the pool for later lessons and revisits, which spaces practice. *Recommended:* yes.
2. **308 changed items, not about 180.** The caps you approved need 308 tap changes plus 7 other picks: content only, same pack size. Eleven skills wait, as listed in §4.4. *Recommended:* yes, land by land after the pilot.
3. **Three small extensions not in M11 (2.2c):** robot "fix the program", `build_pattern` "build the repeating part", and a drag-into-place mode in the lands. They free CS-B-04, LOG-B-02 and SHP-A-08, which no Stage 3 template covers. *Recommended:* yes, in Stage 2, about one developer run.
4. **Evidence on a first meeting.** The Show and the first Together item count for nothing; the child's own Alone answers count as today, unlike the language courses, where the whole introduction visit counts for nothing. The reason: in maths each Alone item is a new problem, and its mistakes are the diagnosis. *Recommended:* yes.

---

## 10. Sources

- Fyfe, McNeil, Son and Goldstone 2014: concreteness fading.
- Kalyuga, Ayres, Chandler and Sweller 2003: the expertise reversal effect.
- Renkl 2014: worked examples.
- Carbonneau, Marley and Selig 2013: a meta-analysis of manipulatives.
- Clements 1999: subitising.
- Bobis 1996: ten-frames and number sense in kindergarten.
- Siegler and Ramani 2008, Ramani and Siegler 2008: linear number board games.
- Siegler and Booth 2004: number-line estimation.
- McNeil and Alibali 2005: the equals sign.
- Clements, Swaminathan, Hannibal and Sarama 1999; Fisher, Hirsh-Pasek, Newcombe and Golinkoff 2013: shape concepts and non-prototypical examples.
- Rittle-Johnson and colleagues (2015 onwards): repeating patterns in preschool. Patterning predicts later maths; how much teaching it causes later gains is still open.
- White and Gunstone 1992: predict, observe, explain.
- Bers 2018: coding and sequencing for young children.
- Fritz and others 2007: expanding retrieval in preschoolers (curriculum §5.7).
- Kang, McDermott and Roediger 2007: production vs recognition in retrieval practice (adults).
- Clements and Sarama 2014: learning trajectories.

Some citations were not re-checked online in this run (the search tool was unavailable): Bobis 1996, Kang and others 2007 and the patterning studies. They are given as commonly cited, and the curriculum-expert verifies them before §5.5 of `docs/curriculum.md` is amended.

## Owner decisions (2026-11-15)

The owner said yes to all four questions: (1) at most 7 scored items for ages 7 to 8; (2) 308 tap swaps, replacing the "about 180" of M11.md; (3) the three small template extensions (CS-B-04, LOG-B-02, SHP-A-08); (4) on a first meeting only the Show and the first Together item count for nothing, and the child's own answers are scored. Pilot land: Shape Forest. The three citations the curriculum-expert could not check online (Bobis 1996, Kang and others 2007, the patterning studies) stay unverified until checked.

## 11. Build status

| Step | Status (2026-11-15) |
|---|---|
| 2.1 Show, parts, lead, evidence, gating, caps | **built for the pilot (2026-11-15, app-developer)**: schema, `arc_build.py`, `lesson_arc.dart`, the controller and the two sort and shape sessions, the host's hand for Kubi; not yet: the "show me" hand button, a second Together item, the predict question, the motions push, stack, turn and stamp, other hosts' pointers; QA and the security-engineer's review still to come |
| 2.2, 2.2c template extensions | not started (2.2c frees SHP-A-08's Show) |
| 2.3 validator V1 to V7, W1, the fade rule | **built** in `arc_checks.dart` (§11.2's corrections as named waiver lists) and `lesson_arc.dart`; V5 reads a table of what each B-40 picture draws |
| **2.4a pilot: Shape Forest content** | **done by the curriculum-expert** (§11.1); Hebrew drafts wait for the hebrew-text-editor, drawings for the design-director |
| 2.4b to 2.4e, 2.5, 2.7, signing | not started |

### 11.1 What the pilot changed (content only, generators re-run)

- **Re-cut (same id, `revision: 2`):** Band A 23 taps (`sort_drag` 19: A-03 4, A-04 4, A-05 3, A-07 4, A-10 4; `shape_builder` 4: the A-01 shape sorter). Band B 20 taps and 2 `match_pairs`, all to `sort_drag` (B-01 4, B-02 4, B-03 3, B-04 4, B-08 4, B-09 3). In all **43 taps and 2 matches** (the plan said 44 and 1: B-09 keeps its stamp tap `x.shpb09.5`, a reverse check that a golden test pins, and re-cuts a second match instead; the share is 50% either way).
- **New:** SHP-B-05 and SHP-B-06, skill files, 8 `shape_builder` items (`b.shpb05.1` to `.4`, `b.shpb06.1` to `.4`; the last of each is a transfer check, so fresh mastery is reachable) and the lessons `one-shadow` and `shapes-make-shapes` (sequence 39 and 40, after the solids).
- **Taps that stay, given an honest second tag (13):** `b15.shpa01.1`, `.2` (a shape in the model's colour, not the answer's: M-COL-ONEATTR), `shp.name.triangle`, `.triangle.green`, `b.shpb01.4`, `.8` (the open figure and the dome: M-SHP-CLOSED twice), `shp.name.square`, `.square.yellow`, `b15.shpa02.2`, `shp.rect.square`, `shp.square.orange` (a second long rectangle: M-SHP-SQRECT twice), `shp.where.under` (above and on: M-SPACE-WORD), `b15.shpa02.1` (its own M-SHP-CLOSED line for "the circle").
- **Pick-only share now:** every Shape Forest skill at or under its cap (A-02 62% under the 80% recognition cap; A-08 exempt); Band A 52% (46% without A-08), Band B 49%.
- **Which ids:** not the first ones of each skill (the throwaway plan) but the taps with the fewest honest tags, keeping the owner's box-word item `b.shpb08.5` (hebrew-notes D6) and, where the count allowed, items pinned by tests.
- **Shows:** 17, one per skill, with 61 host lines for Kubi (1,522 letters without nikud, 1,984 characters); 16 play on today's templates once 2.1 lands, SHP-A-08's waits for 2.2c.
- **Generator changes (for the app-developer's review):** `author.py` writes an item's `revision`, lets a sort have no tag of its own, a family `h2` line and a picture's own tag, and lets a `shape_builder` item say its own question, hints and answer tag; `pick_spec` keeps `revision`. `check_maths.py` reads the Shape Forest property sorts (sides, closed, equal sides, straight, rolls, faces, the shape of a thing), so every re-cut item is recomputed: 0 WRONG, 0 UNCHECKED. **Reviewed by the app-developer (2026-11-15):** correct and in the house style; the switch `LAND_SORT_ITEM_TAGS` was taken out (the sort session and the validator now take the tag, so it is always written), `k_shapebuild` writes `decoy_tags` and `pair_tags` as `answer.pieceTags` (with a feedback line for each tag), `check_maths.py` knows the real-object solids (`gift_box`, `dice`, `can`, `party_hat`, `pyramid_egypt`), `band_b.py` names `gift_box`.

### 11.2 What turned out wrong in this spec

1. **"Every swap works on today's templates, with tags."** The swaps play, but their tags do not record: a sort of the lands records only `answer.misconception` (and the lands validator refuses a picture's own tag as a language-course field), and `shape_builder` cannot tag a decoy. Until §7.4 (5a) and (5b) land, a re-cut sort records one tag, a count sort none, and the shape sorter none. V6 cannot pass for the pilot before that.
2. **"Taps that stay get two tagged distractors."** 30 Shape Forest taps cannot get a second honest tag: tagging them anyway is the false diagnosis the maths check removed on 2026-11-06. They wait for: an oval (`shp.name.circle`, `.mix`, `b15.shpa02.1`, `shp.any.big.circle`), a four-sided shape that is not a rectangle (`shp.rect.find`, `b15.shpa04.1`), the owner's answer on a naming tag (the proposal M-SHP-NAME in curriculum §5.2: A-05 3, A-10 4, `b.shpb01.2`, `.6`, B-08 4), or no tag at all (A-07's four two-option items; B-03 `.1`, `.3`, `.5`, whose thin triangle shows no catalogued error). A-08's four are in the exempt skill.
3. **V6 should read** "fewer than two, or fewer than the catalogue tags that fit the item's act": A-05, A-07, A-10, B-05, B-06 and B-08 have hands-on items with no honest tag.
4. **V7 cannot hold** for skills whose only form is hands-on (SHP-A-06, B-05, B-06: `shape_builder` is always concrete) or whose lessons are all tracing (the two A-02 trace lessons take their rung 1 from the skill's taps by rule 3). Proposal: V7 exempts a skill with no pictorial form, or the build skills get one "which shapes make this picture?" pick each.
5. **SHP-A-06 and SHP-B-05 look alike today**: the template draws every place as one grey shadow, which is B-05's "no inner outlines"; A-06's "each piece outlined" needs an outline per place (§7.4 (5c)).
6. **SHP-B-06's own example** ("two triangles make a square") needs a half-square triangle; the pilot uses two squares, two rectangles, two triangles that make a four-sided shape, and four squares.
7. **SHP-B-08's hands-on form is weak until real objects are drawn**: of its named sorts only the balls carry the name to a real thing; the others match a solid to its own picture.
8. **Host lines are about half the estimate** (61 lines, 1,522 letters, not 3,150).

### 11.3 Hand-offs from the pilot

- **app-developer:** §7.4 items 1 to 5, the review of the generator changes of §11.1, and the pinned tests below.
- **design-director:** an oval; a four-sided shape that is not a rectangle; `shape_triangle_half`; real-object solids (a can, a party hat or traffic cone, a gift box, a dice, a toy pyramid); the Show motions in each Show's `picture` (the hand along the sides, sticks lifting off the sides, the ant walk, push and roll, the sand print, the finger round the sorter's hole); a golden check that a bin of 3 to 6 `stick_long` reads as "sides" at bin size. Found while checking the builds: in `shp.build.rocket` the nose (`shape_triangle_red`, 36) and the fins (`shape_triangle_green`, 34) are two sprites of nearly one size, so a red triangle dropped on a fin is "wrong" for a colour the grey shadow does not show; the fix is one sprite for all three (data, after its golden is redrawn).
- **hebrew-text-editor:** the 61 host lines (plain drafts in the arc file) and 173 narrator clips new or re-worded (4,810 letters, 10,457 characters with nikud), all `NOT READ` rows of `docs/review/hebrew-master.csv`. Six new rows came out `owner-approved` by the dagesh-after-מִ rule (`b.shpb06.1` to `.3` prompts and alt texts) and four `text-ready` by an identical reviewed text: they are drafts. The regenerated table also lists 64 app-string rows from the branch's earlier screens (not the pilot's). `x.shpb09.1` and `.4` say "stamp the solid" for a pyramid whose stamp is its square base: "on its side" would make the triangle true.
- **owner (via the orchestrator):** the naming tag M-SHP-NAME (curriculum §5.2).
- **Pinned tests now red because of the pilot's content (not the signature):** `content_lints_test.dart`, three tests: the source counts become 1,214 activities and 114 skills; `b15.shpa02.2` leaves the list of explained gaps (it has two tags now); the older gaps' pin goes from 326 to 297. `tools/test_hebrew_sources.py` `test_table_counts`: 15,912 rows. `docs/audio/voicing-groups.json` was re-run (`tools/voicing_groups.py`, free) so every new clip is in a group (shapes-A 250 ids, 7,496 characters; shapes-B 187, 7,364). **Red because the bundled pack is not re-signed:** `starter_pack_test.dart` "built from the sources". **Will go red at signing** (they read the signed pack): `hint_tap_families_test.dart` (the A-07 "solids" id lists name four re-cut items), `hint_tap_golden_test.dart` and `hint_qa_test.dart` (`shp.name.triangle` now offers the dome for the circle).
