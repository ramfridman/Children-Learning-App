# Audit of starter pack 0.8.0 (board B-5)

Curriculum-expert (Knowledge Agent), 2026-10-28, branch `m9-content`. Nothing in the syllabus, the content, the texts or the code was changed. Everything below is a proposal for the orchestrator and the owner.

What was audited: `content/starter/` (100 skills, 767 activities, 160 lessons, 44 misconceptions) against `docs/curriculum.md` §3 to §6, plus the code that decides how the content is played: `app/lib/world/next_lesson.dart`, `world/placement.dart`, `play/lesson_controller.dart`, `play/tap_answer_session.dart`, `play/shop_pay_session.dart`, `engine/engine.dart`, `engine/graph.dart` and `engine/params.dart`. The counts come from small Python scripts run over the pack. They are kept in the session scratchpad and are not committed.

How sure each statement is:
- **[measured]** counted over every file of the pack;
- **[read]** I read the file or the code;
- **[source]** taken from a cited source;
- **[guess]** my own judgement, with no measurement behind it.

## 1. Coverage per land and band [measured]

| Land | Band A in the curriculum | Band A in the pack | Band A activities | Band B in the curriculum | Band B in the pack | Band B activities |
|---|---|---|---|---|---|---|
| Numbers | 14 | 14 | 109 | 18 | 14 | 159 |
| Colours | 8 | 7 | 45 | 7 | 5 | 36 |
| Shapes | 10 | 9 | 59 | 13 | 6 | 42 |
| Logic | 10 | 10 | 60 | 12 | 7 | 39 |
| Computer science | 7 | 4 | 24 | 10 | 2 | 14 |
| Money and Maths | 7 | 7 | 42 | 19 | 15 | 148 |
| **Total** | **56** | **51** | **339** | **79** | **49** | **438** |

- **Band A skills not in the pack (5):** COL-A-08, CS-A-02, CS-A-06, CS-A-07 and SHP-A-09.
- **Band B skills not in the pack (30):** COL-B-05 and 07; CS-B-02, 03 and 05 to 10; LOG-B-03, 05, 07, 10 and 12; MATH-B-04, 05, 11 and 12; NUM-B-06, 09, 12 and 15; SHP-B-05, 06, 07 and 10 to 13.
- **Activities, skills and lessons:** every pack skill has at least 3 activities, and every activity sits in a lesson.
- **Structure:** every prerequisite exists, and the graph has no cycle.
- **Share of activities per land against the curriculum's time shares (§3.4):**
  - In Band B, Numbers and Maths hold 70% of the activities (the plan says 50%), and Computer science holds 3% (the plan says 15%).
  - In Band A, Computer science holds 7% (the plan says 15%).
  - Robot Harbour is the thinnest land in both bands.

## 2. Findings, ranked (15)

They are ranked by severity: wrong content first, then misleading pictures and diagnosis, then weak help. Each finding names the agent that owns the fix.

### F1. Wrong content: the cardinality line names the wrong number (owner: app-developer, with the hebrew-text-editor) [measured]
- **What is wrong:** all 22 `give_n` activities use the shared `vo:fb.card` line. It says "לָקַחְנוּ אֶת כֻּלָּם. הַפֶּרַח רוֹצֶה רַק אַרְבָּעָה" ("we took them all; the flower wants only four"). It is copied from the butterflies lesson, the only one where it is true.
- **Where it is wrong:**
  - in 17 activities the number is wrong: "give me 13 apples" (`b.numb05.1` to `.8`, 13 to 20 things) and 2, 3 or 5 things (`give.*`, `math.shop.*`);
  - in 21 activities there is no flower on the screen.
- **Why it matters:** the line contradicts the number the child was asked for, at the moment the child is being taught that the number decides.
- **It passed review:** the text editor marked the row `text-ready` (row 2973 of `hebrew-master.csv`), so it would be voiced as it is.
- **Fix:** a line built from the activity's own number and noun, or one neutral line ("לָקַחְנוּ אֶת כֻּלָּם. צָרִיךְ רַק חֵלֶק: סוֹפְרִים וְעוֹצְרִים בַּמִּסְפָּר.", a draft marked `needs-editor`).
- **Before any voicing:** hold the `vo:fb.card` rows at `proposed`.

### F2. Fresh mastery cannot be reached on 89 of the 100 skills (owner: curriculum-expert for the content; app-developer and qa-engineer for the guard) [measured + read]
- **The rule in the engine** (`engine.dart` `_checkFresh`, `params.dart`), which follows curriculum §4.1:
  - fresh mastery needs at least 1 passed understanding check (2 for a core skill);
  - a core skill also needs 2 representations.
- **What the pack has:**
  - 89 skills have no activity whose `checkType` is anything but `practice`;
  - 96 skills have activities in one representation only;
  - 11 of the 12 core skills (NUM-A-01 to 04, NUM-A-08, COL-A-02 and 03, LOG-A-01, SHP-A-03, MATH-B-01 and 03) have a single representation.
- **What follows:** for those skills the plant never passes the seedling, durable mastery and the spaced checks never start, and the switch-representation rule (`avoidRepresentation`) has nothing to switch to.
- **The engine already warns about it:** `graph.report()` lists exactly this ("has items in only one representation"), but no test runs it on the real pack.
- **The representation labels are often wrong:**
  - every robot activity is labelled `embodied`, but the robot on a screen is concrete or pictorial;
  - 91 tap-a-picture items are labelled `concrete`, but nothing in them can be moved;
  - NUM-A-01 and 02 are declared `embodied, story` and taught only with `symbolic`.
- **Fix:**
  1. Author at least one U1 or U4 check per skill with the existing templates (give-N after count, the reverse question, predict the robot's end).
  2. Correct the labels.
  3. Give each core skill a second representation.
  4. QA turns `graph.report()` into a pack test.
  5. QA adds a simulator test that every skill can reach fresh mastery.

### F3. Activities that teach a different skill from the one they credit (owner: curriculum-expert, then app-developer for the generators) [read]
| Skill | What the curriculum asks | What the activities do |
|---|---|---|
| NUM-A-01 and 02 (the first skills on the path) | Say the counting words, in a song and in tap-along counting | Tap the numeral that comes after a number ("מָה בָּא אַחֲרֵי אַרְבַּע?") |
| COL-B-04 | Sort by colour **and** shape in a 2×2 grid | 4 single-attribute sorts into 2 bins, which is COL-A-04 again |
| LOG-B-02 | Find the pattern unit (the core) | "One does not fit": fixing a pattern, which is LOG-A-07 at a longer length |
| LOG-B-08 | If-then rules | A colour sort phrased as "if…" |
| CS-A-05 | Spot the wrong step in a sequence | Odd one out among three step pictures (no sequence is shown) |

- **NUM-A-01 and 02:** answering needs reading numerals, which is NUM-A-08, a skill that comes after them. The "number after" question is also a later counting level than reciting [guess, from Clements and Sarama's counting trajectory].
- **What follows:** mastery is credited for skills the child never showed.

### F4. Tags that point the diagnosis at the wrong misconception (owner: curriculum-expert for the tables; app-developer for per-move classifiers) [measured + read]
- **COL-B-01:** both wrong answers are tagged M-COL-MIX, but they are colours that no "stronger colour wins" child would pick (red + yellow gives blue or green). The diagnostic distractor must be one of the two colours that are mixed.
- **Wrong tag, then the right one:**
  - LOG-B-08 is tagged M-SORT-SHIFT; it should be M-IF-REVERSE, which no activity can reach.
  - LOG-B-11 (seriation) is tagged M-PAT-COPY; it should be M-SER-ENDS.
  - NUM-A-07 (match a numeral to a set) is tagged M-CNT-SIZE; M-CNT-SKIP, M-CNT-DOUBLE or M-NUM-REV fit.
  - NUM-B-16 tags "1" as M-NUM-TEEN, but picking 1 for "15 = 10 + ?" is a face-value error.
  - MATH-B-13 tags M-MEAS-BIG on balances of identical blocks.
  - CS-B-04 tags any wrong tap as M-CS-FIXALL, but a tap is not "clearing the program".
- **Drag templates:** `sort_drag`, `match_pairs`, `spot_error` and `balance` give every wrong move of an activity one tag, even the first drop of a sort (where no rule can have "shifted"). With the evidence rule (score ≥ 1.5 over 2 items), random slips can make a misconception active and send the child to the wrong repair [guess about the effect; the rule is read from the engine].
- **The catalogue has drifted:**
  - the pack uses M-LOG-NOT and M-PART-MISS, where curriculum §5.2 has M-NOT and M-PPW;
  - M-NUM-WRITE and M-SHP-FACE are new, and not in §5.2;
  - M-ADD-RECOUNT has a misconception file but no activity can reach it.

### F5. Tagged distractors: the §5.3 rule is met by 39 of the 469 items with 3 or more choices (owner: curriculum-expert for the tables; qa-engineer for the lint) [measured]
- **Items with 3 or more choices that fail the rule:** 430 of 469 do not have two distinct tagged distractors.
  - 181 have no tag at all: all of MATH-B-01 (join and take away), 03, 06, 07, 08 (within 20), 10 and 14, SHP-B-08, COL-B-02, LOG-B-06, LOG-A-09, CS-A-05, the numeral picks of NUM-A-08, and more.
  - 210 have one tag.
- **Two-choice items:** 64 of 80 are untagged.
- **The worst case is arithmetic:** the wrong answers are n ± 1 with no meaning. A 9 − 5 item offers 5 (the number taken away) untagged, and never 9 ("nothing was taken") or 14 ("added instead").
- **Watch-for tags never reached** in the skill they belong to (curriculum §4): M-NUM-REV in NUM-A-07 and 08, M-NUM-TEEN in NUM-B-08, M-COL-SHADE in COL-B-02, M-SHP-PROTO in SHP-A-05 and SHP-B-01, M-SORT-SHIFT in LOG-A-02, M-IF-REVERSE, M-SER-ENDS, M-ADD-RECOUNT, M-MEAS-ALIGN, M-SUB-ORDER, M-NUM-ZERO in MATH-B-07, and M-SHARE-UNEQ in MATH-B-10.
- **The validator does not catch it:** it checks this only for counting activities (M9 §12), not the full A2 rule.

### F6. Order and prerequisites (owner: curriculum-expert for `sequence` and the prerequisites; app-developer for the gate) [measured + read]
- **The path ignores mastery.** A land's path is every lesson that touches the domain, sorted by `sequence` (`next_lesson.dart`). "Finished" means played to the end, not mastered, and the band is not consulted. So:
  - a 3-year-old who plays the 20 Band A Numbers lessons once walks straight into "count to 20" and the number line;
  - on the Numbers path, the butterflies lesson (NUM-A-03) comes before NUM-A-01, its prerequisite;
  - two Band A lessons sit after every Band B lesson of their land: `match-numbers-sets` (NUM-A-07, positions 47 and 48 of 49) and `trace-the-shapes` (SHP-A-02, positions 22 and 23 of 25).
- **Missing skills were bypassed instead of built.**
  - **NUM-B-06 (read 0 to 10) is missing.** NUM-B-07, NUM-B-10, MATH-B-03 and MATH-B-16 were rewired to NUM-A-08 (numerals 1 to 5). Nothing teaches or checks 0 and 6 to 10 as symbols, yet Band B tiles show them everywhere.
  - **NUM-B-09 (ten-frames) is missing.** NUM-B-16 (teens as ten and ones) and MATH-B-06 (make ten) were rewired around it, so the structure they depend on is never taught.
  - **Other rewiring:**
    - LOG-B-06 and 08 point to LOG-A-03 and LOG-B-06, because LOG-B-05 (2×2) is missing;
    - CS-B-04 points to CS-B-01, because CS-B-03 (predict the end) is missing;
    - CS-A-03 points to SHP-A-08, because SHP-A-09 is missing.

### F7. Placement counts a guess as "knows the lesson" (owner: app-developer, with the rule from me) [read]
- **The rule today** (`placement.dart` `placedLessons`): one right answer at the first try, with no help, on the middle item of a lesson marks the whole lesson finished.
- **Why that is a problem:** most middle items have 2 or 3 choices, so a guess passes 33 to 50% of the time. Curriculum §4.1 says a 2- or 3-choice item never counts alone.
- **Proposed rule:**
  - use an open item (give, drag, trace, number line, shop) or two different items of the lesson's skill;
  - never place past a lesson whose prerequisites were not shown.

### F8. Misleading pictures on the balance (owner: design-director for the pictures; curriculum-expert for the scenes) [read]
- **MATH-B-09 (= means "same as") shows the wrong thing on a balance.** It shows "3 apples + 4 stars against 5 fish + 2 ducks" on a balance. A real balance weighs, so different things with equal counts would not balance: the picture teaches that a balance counts.
  - Fix: use identical cubes ("number blocks"), which is what curriculum Ladder 4 asks for.
- **MATH-B-13 (weight) has nothing that tests "bigger means heavier."** 6 of its 10 items compare identical blocks (this is counting). The stone and the feather are drawn at about the same size, so M-MEAS-BIG is never challenged.
  - Fix: a big light thing against a small heavy thing (a balloon against a stone, a pillow against a key).
- **Band B is asked to use right and left words.** The balancing prompts say "הַצַּד הַיְמָנִי", and right and left are a skill (SHP-B-12) that is not built yet.

### F9. Misleading pictures of solids (owner: design-director; hebrew-text-editor for Q7) [read]
- **One picture, two names.** The `solid_box` sprite is an isometric cube. It is called קֻבִּיָּה in SHP-A-07 (roll or stack) and תֵּבָה in SHP-B-08 and 09. There is no cube sprite at all, so a child learns two names for one picture.
- **Fix:** a cuboid with shoe-box proportions for תֵּבָה, and a separate cube.
- **An arguable answer:** in `x.shpb09.*` the pyramid has a square base, and "rectangle" is the box's answer. A child who pairs the pyramid with the rectangle shape is geometrically right but scored wrong.
  - Fix: show the stamp (the face that touches the table), or use a triangular pyramid.

### F10. Pictures that hide the idea (owner: curriculum-expert for the scenes; design-director for the frames) [measured]
- **NUM-B-16 hides the ten.** It shows 11 to 19 identical sprites in one line on a 330 × 128 point stage, so the ten is invisible. The question ("שְׁבַע עֶשְׂרֵה הוּא עֶשֶׂר וְעוֹד כַּמָּה?") can also be answered from the number word alone, with no quantity sense.
  - Fix: use the existing `ten_frame` arrangement, as a full frame plus the extras.
- **MATH-B-10 (equal groups) has an empty scene.** Six activities say "three plates, three ducks on each" and show nothing: multiplication by ear for a 5-year-old.
  - Fix: until T22 exists, a `scene.chart` with one column per plate would draw the groups.
- **MATH-B-01 shows no change.** The take-away items show only the starting set; the "take away" is never seen.

### F11. Answers that can be argued (owner: curriculum-expert) [read]
- `cs.wrong.teeth3`: the "doesn't belong" in tooth brushing is the tap, but a tap is used for brushing.
- `cs.routine.teeth.first`: the answer is "paste first", and the tagged "cup of water first" is a real family routine.
- `cs.wrong.teeth2`: the towel.
- `x.shpb09.*`: the pyramid's faces (F9).
- **Fix:** replace these items with steps that have one defensible order.

### F12. Weak help: hint level 2 rarely changes the representation (owner: app-developer for rendering; curriculum-expert for the texts; qa-engineer for the lint) [measured + read]
- **One generic line.** 434 of the 766 second hints are the same sentence, "נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד", and 69 more are "צַעַד אַחַר צַעַד". The first one also plays on number sentences, days of the week and words, where there is nothing to look at.
- **Hint actions draw nothing in `tap_answer`.** It holds 521 activities (68% of the pack), and every hint action only pulses all the choices (`onHint() => _pulseAll()`). So `show_fingers`, `highlight_objects_sequentially` and `worked_example` show no fingers, no sequence and no example.
- **The escalation** (`lesson_controller.dart`):
  - the 1st mistake gets the diagnostic line, the 2nd mistake jumps to hint 2 (hint 1 is reached only with the lamp), and the 3rd mistake gets hint 3;
  - with 3 choices, two wrong taps leave only the answer, so the worked example usually comes after the answer has been forced;
  - with 2 choices the answer is forced after one mistake.
  - The question was "does hint 3 give the answer away too early". It does not: it comes too late to teach.
- **Many hint-3 lines are not worked examples:**
  - "הַגָּלִיל — נִסְתַּכֵּל עַל הַצּוּרָה שֶׁלּוֹ" names the answer and shows nothing;
  - "show me" for SHP-B-08 and the colour items is a sentence, not a demonstration.
- **Fix:**
  1. `tap_answer` renders each hint action (fingers counting beside the set, each object lit in turn, the guide pointing at the answer and saying why).
  2. Hint-2 texts are written per kind of activity.
  3. A lint refuses a hint-2 caption that is shared across more than one kind.

### F13. Band rules broken (owner: curriculum-expert, with the hebrew-text-editor) [measured]
- **Right and left words in Band A.** 12 Band A robot activities say ימינה and שמאלה in hint 3; PLAN.md says Band A hears landmarks ("לְכִוּוּן הָעֵץ").
- **Negation in Band A prompts.** CS-A-05 (6 items) and SHP-A-07 (2 items) ask "מָה לֹא…", which curriculum §8.3 rules out for Band A.
- **Right and left words in Band B.** The four MATH-B-13 balancing prompts (F8) use "the right side".

### F14. Missing addend, MATH-B-18 (owner: app-developer for G1; hebrew-text-editor; see the B-2 view, question 3) [read]
- **Hint 3 counts all.** It counts 1 to 7 ("count all") and then says "tap 4" without showing where the 4 came from.
- **One misconception is missing.** The distractor of a child who adds the two numbers that are shown (3 + 7 = 10, M-PPW) is not offered, and 5 is untagged.
- **The full proposal** is in `hebrew-questions-teaching-view.md` §2.

### F15. Difficulty inside a skill is a ramp by position, not by item (owner: curriculum-expert for the tables; app-developer for the generator) [measured]
- **How it is set:** the Band B `authored` difficulty is 0.37 + 0.07 × the item's position, capped at 0.9, whatever the item is.
- **Examples:**
  - in MATH-B-08 the first item, 8 + 5 (crossing ten), is 0.37, and 17 − 2 (no crossing) is 0.9;
  - in NUM-B-13 the 0 to 10 line items and the items placing 13, 17 and 18 share the 0.9 cap.
- **Why it matters:** placement picks each lesson's "middle" item by this number, and the engine's knowledge estimate weighs it.
- **Fix:** compute difficulty from the item's features (number size, crossing ten, set size, arrangement, number of choices).

### Checked and found right
- **Coins:** the shop draws each coin at its real diameter, and the colours match the real coins: 10 agorot and ½ ₪ gold; ₪1, ₪2 and ₪5 silver, the ₪5 with twelve sides; ₪10 with a gold centre in a silver ring. Compared with the coin table in [Wikipedia, Israeli new shekel](https://en.wikipedia.org/wiki/Israeli_new_shekel) [source].
- **Size tricks:** the NUM-A-12 items put the bigger-looking set on the wrong side, as M-CNT-SIZE needs.
- **Number lines and arrows:** they are drawn left to right.
- **Teen digits:** NUM-B-08 tags the reversed digits (12 against 21) as M-NUM-REV.
- **The clock:** the 12 o'clock distractor is tagged M-CLOCK-HANDS.

## 3. What to build next for the family release

**The children's real ages are not written in any file I could read** (CLAUDE.md, PROGRESS.md, PLAN.md, M9.md, the memory notes): every file says "ages 3 to 8". The order below assumes the likely split, a younger child in gan (3 to 4, Band A) and an older one in gan hova or grade 1 to 2 (5 to 7, Band B). The owner should confirm it (Needs the owner, 1).

### Step 0: before any voicing or new skill (content only, no new template)
1. **F1:** fix the cardinality line.
2. **F2:** add one check per skill, correct the representation labels, and give each core skill a second representation.
3. **F5:** add tagged distractors to the arithmetic tables (`tools/band_b.py`: MATH-B-01, 03, 06, 07, 08 and 10).
4. **F6 and F7:** fix the path order and placement.

### Band A of every land, for the younger child (round-robin, owner decision Q4)
| # | Skill | How | Template |
|---|---|---|---|
| A1 | NUM-A-01 and 02, counting words (re-taught; F3) | Count along with the guide, one tap per word, a song | **T24 sound and move** (or a count-along mode of `count_tap`) |
| A2 | SHP-A-09: between, in front of, behind, up, down | Pictures only | `tap_answer` + art |
| A3 | CS-A-06: "the robot made a mistake" | Watch a run and touch where it went wrong | `robot_path` playback mode or `spot_error` with the grid |
| A4 | CS-A-07: repeat a dance (pre-loop) | Copy a short dance pattern | **T24** or `build_pattern` with move icons |
| A5 | CS-A-02: follow a spoken 1 to 2 step body instruction | Body moves | **T24** |
| A6 | COL-A-08: colour by a key | A first step now as numeral ↔ colour pairs; full colouring later | `match_pairs` now, a paint mode later |

### Band B, in the order a 5 to 6-year-old needs it
| # | Skill | Why now | Template |
|---|---|---|---|
| B1 | NUM-B-06: read 0 to 10 | A prerequisite gap under four built skills (F6) | `tap_answer` (exists) |
| B2 | NUM-B-09: ten-frames, flashed | The base of make ten, the teens and splitting numbers; then redraw NUM-B-14, NUM-B-16 and MATH-B-06 and 08 with frames | `flash` + `ten_frame` (exists) |
| B3 | MATH-B-04: count on from the larger number | The step from counting all to counting on; it makes M-ADD-RECOUNT reachable | `flash` with a covered group ("5 in the cup"), a small option |
| B4 | LOG-B-05: sort by two attributes (2×2) | A prerequisite of COL-B-04, LOG-B-06, 07 and 08 | `sort_drag` with 4 bins, a small option |
| B5 | MATH-B-11 and 12: compare lengths and measure with units | Kindergarten curriculum: measuring with arbitrary units; grade 1 milestone: length | **T19 measure it** |
| B6 | MATH-B-10: equal groups (re-taught; F10) | A picture of the groups, then dealing | `scene.chart` now; **T22 arrays and groups** for the real thing |
| B7 | NUM-B-12: ordinals to the tenth | Kindergarten goal to the sixth, extension to the tenth | `tap_answer` row |
| B8 | CS-B-03, 05 and 06: predict the end, find the repeating part, the repeat block | An understanding check (U1) for Robot Harbour, the thinnest land | `robot_path` modes, `spot_error` |
| B9 | SHP-B-12, then CS-B-02 and SHP-B-11: right and left with the wrist anchor, then turns | The order of PLAN.md's right-and-left rule | `tap_answer` + avatar art, then `robot_path` turns |
| B10 | COL-B-07 and COL-B-05: a colour picture graph, colour codes | Cheap | `tap_answer` chart, `sort_drag` |
| B11 | SHP-B-10 (symmetry), SHP-B-05 to 07, SHP-B-13 (maps) | Kindergarten geometry | a mirror template; `shape_builder` options; maps later |
| B12 | NUM-B-15 (estimate), LOG-B-03, 07, 10 and 12, CS-B-07 to 10 | Later | small options, a sudoku template |

### Unbuilt templates in priority order
1. **T24 sound and move:**
   - it is the only way to give Band A the embodied representation it lacks entirely;
   - it unlocks NUM-A-01 and 02 properly, plus CS-A-02, CS-A-07 and LOG-B-03;
   - no camera and no stored audio; the child taps "done".
2. **T19 measure it:**
   - it unlocks MATH-B-11 and 12, the kindergarten and grade 1 measurement goals, and later MATH-C-17;
   - it needs the gap and overlap classifier (M-MEAS-GAP) and the ruler-from-1 classifier (M-RULER-1).
3. **T22 arrays and groups:**
   - it gives MATH-B-10 its concrete form now and is the core of Band C multiplication;
   - if the older child is 7 to 8, move it to first place.
4. **T25 explain it:**
   - it gives the U6 checks that core skills need (F2);
   - until it exists, U1 and U4 checks can be authored with the existing templates, so it is not blocking.
5. **T11 mix the colours:**
   - it gives COL-B-01 a predict, mix, see representation (repair R1 of M-COL-MIX);
   - today mixing is only a picture pick.
6. **T23 fraction fold:**
   - Band C (MATH-C-14) and SHP-B-07 (cutting a shape);
   - after the family release.
7. **T12 speak the answer:**
   - last: voice answers already work inside the templates, and children's speech recognition is still unmeasured (M5, to-do P4).

## 4. Syllabus changes I propose (for the owner, through the orchestrator)
1. **Re-specify** NUM-A-01 and 02, COL-B-04, LOG-B-02, LOG-B-08 and CS-A-05 so their activities teach the skill named (F3). This touches the app-developer (generators), the design-director (pictures) and the hebrew-text-editor (texts).
2. **Restore the curriculum's prerequisites** by building NUM-B-06, NUM-B-09 and LOG-B-05 first, instead of rewiring around them (F6).
3. **Bring the catalogue in line:** rename M-LOG-NOT to M-NOT and M-PART-MISS to M-PPW (or update §5.2), and add M-NUM-WRITE and M-SHP-FACE to §5.2 with their signal and repair.
4. **Engine rules** (my specification; the app-developer implements):
   - the path skips a lesson whose skills are not yet unlocked (`isUnlocked`, unlock bar 0.8) or are above the child's placed band;
   - placement needs an open item or two items (F7).

## 5. What I did not check
- **The app on a phone or a tablet, and the goldens:** I did not run either, and I made no claim about how a picture looks on screen except what its SVG says. The stone and feather sizes, and the cube that looks like a box, were read from the SVG.
- **Tests and the simulator:** I did not run `flutter test` (as briefed) or the simulator. F2 and F12 are read from the code, not observed: QA should prove them with a test.
- **The texts:** I did not read every activity, only one of each kind in full plus every family with a counting problem. The Hebrew wording belongs to the text editor.
- **The Ministry PDFs:** I could not extract the text of the Ministry's kindergarten mathematics PDF (`Math3.pdf`) or its geometry guide. Their terms are cited only through a search engine's summary (see the B-2 document).
