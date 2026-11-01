# B-36 part H: QA of the next content pack, starter 0.11.0 (qa-engineer, 2026-11-01)

Branch `next-pack` at `4216286` (code `48b8567`). Plan: `docs/milestones/B36.md` section 5. One pass, no commit, no push. Everything
was run in a **scratch copy** (`...\scratchpad\b36h\repo`, outside the repo) with a throw-away key (deleted at the end); the real
worktree was only read, apart from the test files and this record named in section 9.

## 1. Verdict

**The pack is correct and the whole suite is green against a throw-away-signed 0.11.0. Part H is not closed: 3 open majors (all
are hint pictures or hint lines on the phone and the small phone; none changes an answer key, a tag, a lesson or a text), 6 open
minors (QA-B36-4, 5, 6, 8, 9, 10; 7 is closed by QA).** The majors have a failing test each (skipped in a normal run, section 9), so the owner of each fix
has a proof. The pack itself (answers, tags, lessons, texts, regeneration, voices) has no defect; QA-B36-1 and 3 are partly
the B-40 hint pictures and lines that were already in the 0.10.0 pack (QA-B36-1: about 35 older items; QA-B36-3: 134 older cases), so the
orchestrator may decide to ship 0.11.0 and fix them in the next pack. That is his call, not QA's.

| Item of B36.md section 5 | Result |
|---|---|
| 1 whole suite, throw-away 0.11.0 + part K package | **pass** (first run 3,059 passed, 4 skipped, 0 failed; second run, with QA's test files, 3,061 passed, 7 skipped, 0 failed) |
| 2 `graph.report()` empty, mastery 100 of 100 with `QA_OPEN=true`, content lints, ratchet lower | **pass** |
| 3 every new item: right answer right, wrong answers tagged as specified, level 2 changes the picture, level 3 a worked example with the answer last, in a lesson, `review` set | **pass** (150 new items + the B-38 items; one note: `b15.shpa07.2` has a wrong answer with no tag, by the spec) |
| 4 PNGs on phone, SE and both tablets, all three hint levels, the new hint plans | **fail**: 3 majors (QA-B36-1, 2, 3) and 5 picture minors (QA-B36-4, 5, 8, 9, 10), sections 4 and 5 |
| 5 the hint line says what the hint picture shows (60 sampled) | **fail, minor**: the level 2 line of 9 second-way items is the generic "look slowly at all of them" (QA-B36-6); the level 3 lines match their pictures |
| 6 Hebrew source tests, generator tests, regeneration twice, no owner-approved row lost | **pass** |
| 7 voice-answer audit for every new tap item | **pass** (the three calls of the app-developer: section 7) |

## 2. What ran (all in the scratch copy unless it says "real")

| Command | Result |
|---|---|
| `pack_builder keygen --out <scratch>\throwaway.key --replace-public` (scratch copy only), `pack_builder build ..\content\starter --key <throw-away>` | `Built assets\packs\starter-0.11.0.nnpack: 5304508 bytes, manifest sha256 4b86fe23f8980d36c4a1e745b8d5169cfda6c3f30cf0a6be7fb5e084d36ee823`: **both match the expected values**; 14 `WARNING` lines, all "its spoken number begins the number of another option" (one kind, as announced). `verify` of the pack: `OK: starter 0.11.0 is genuine`. |
| `pack_builder build-character ..\content\characters\nitzi --key <throw-away>` | the bundled Nitzi pack re-signed with the same key (the app takes one key for every pack), as in `b3-b15-verification.md` section 2 |
| `apply-k.ps1 -Worktree <scratch>` | the 148 prepared files copied (18 sources, tests and the publish vector, 130 goldens); `starter-0.10.0.nnpack` removed. The vector says 0.11.0, the same sha256, 1,118 items, 52 misconceptions. |
| `flutter analyze` (scratch) | No issues found |
| `dart format --output=none --set-exit-if-changed .` (scratch, after apply-k) | **exit 1: `test\engine\engine_adapter_test.dart` was not formatted** (QA-B36-7, minor, **fixed by QA** in the K package, see 8) |
| `flutter test` (whole suite, scratch, first run) | **3,059 passed, 4 skipped, 0 failed** (19.3 min). The 4 skips are the open M9 defects QA-13, QA-14, QA-17, QA-18 of `qa_open_defects_test.dart`, as before. |
| `flutter test --dart-define=QA_OPEN=true mastery_reachable_test engine_adapter_test content_lints_test` | all passed; printed `F2: 0 of 100 skills cannot reach fresh mastery (0 lack an understanding check, 0 lack a representation, 0 are core); graph.report() has 0 lines` |
| `flutter test --dart-define=QA_OPEN=true qa_open_defects_test.dart` | the same 4 old defects fail as before (QA-13, 14, 17, 18); nothing new |
| `python -I -X utf8 tools/test_hebrew_sources.py` (real) | Ran 10 tests, OK |
| `python -I -X utf8 tools/test_generators.py` (real) | Ran 58 tests, OK |
| `python tools/regen_content.py` run twice on a copy of `tools`, `content`, `docs` | 1,895 files; the first run equals the committed files (0 differences), the second run equals the first (0 differences) |
| `flutter test` (whole suite, scratch, second run after QA's own test files and the format fix) | see section 2a |
| `deno task check` | **not run**: no TypeScript changed in this part; the Deno suite reads the publish vector on CI (part K) |

### 2a. Second whole run

After QA's two test files were added (`qa_b36_open_defects_test.dart`, the pronunciation test in `voice_gen_test.dart`) and the
format fix, with `flutter analyze` (No issues found) and `dart format --set-exit-if-changed .` (368 files, 0 changed, exit 0):
**3,061 passed, 7 skipped, 0 failed** (about 26 min). The 7 skips are the 4 old defects (QA-13, 14, 17, 18) and QA's 3 open
tests of this pass (QA-B36-1, 2, 3, skipped unless `QA_OPEN=true`). The 2 new passing tests are the "hand on the answer in the last
step only" test and the "two" respelling test.

## 3. Item by item

### 3.1 Item 2: graph, mastery, lints

- `graph.report()` has 0 lines; every one of the 100 skills can reach fresh mastery; the skip of the mastery test is gone.
- `content_lints_test`: the story skills gained NUM-A-12, LOG-A-07, COL-B-01; the explained gaps of the new items went from 21 to 7;
  the old gaps from 310 to 202. **Independent count** from the JSON: 209 tap, count and flash items with 3 or more options have fewer
  than two tagged wrong answers = 202 + 7. The ratchet is lower, and honest.

### 3.2 Item 3: the new items (150 + `b15.shpa08.1/.2`, `x.shpb09.4`, `b.shpb08.5`, `b.shpb08.10`, `b15.shpa07.2`)

Checked from the JSON (script in the QA scratchpad, `audit_items.py` and `audit_pairs.py`), against the spec rows of
`docs/curriculum/b36-second-representations.md`, and by the suites:

- every one of the 150 has exactly the tags its spec row names (set level), and **50 of 50 option-level pairs** ("7: M-CNT-CARD;
  4: M-CNT-DOUBLE") are on the option the spec says; no right option carries a tag;
- the right answer is right and every wrong move gets its line: `playthrough_test` plays every activity of every lesson (each wrong
  option, the ladder to its top, "not sure", then right, then the celebration) and the coverage test finds every tag produced and
  every tag with a line;
- hints: 3 per item, levels 1, 2, 3, level 3 is `worked_example` in all 150; `hint_qa_test` finds no tap item on the generic question
  card at level 2; my own test (section 9) shows that for 25 tap items on all four boards **levels 1 and 2 have no hand, and in
  level 3 the hand is on the right tile in the last step only** ("no answer framed or marked early");
- every one of the 150 is in a lesson and has `"review": "needs-editor"`; none is `proposed` in the review table (3,348 rows
  `owner-approved`, 10,282 `text-ready`, 1 `unchanged`);
- B-38: `b15.shpa08.1/.2` (cat in, on), `x.shpb09.4`, `b.shpb08.5`, `b.shpb08.10`, `b15.shpa07.2` have their tags (SQRECT, FACE, NAME,
  SPACE-WORD). Note: `b15.shpa07.2` ("what can we stack?", cube or sphere) has two options and the wrong one carries no tag. It is
  the known E2 case of the spec (no catalogue tag fits), not new.
- NUM-B-16: the odd items are two ten-frames, the even ones are the sentence `12 = 10 + ?`; the wrong options are `10+k`
  (M-NUM-TEEN), `1` (M-NUM-REV, the tens digit taken for the ones, as `b15-content-spec.md` 4 says) and `10` (M-CNT-CARD). Consistent.
  The even ones have a hint defect, QA-B36-2.

### 3.3 Item 6: Hebrew sources and approved rows

All 3,233 rows of `docs/review/b36-approved-rows.tsv` are present in `hebrew-master.csv`, still `owner-approved`, with the same
text, screen text and voice text (the row's own hash, `b36_hash` of `hebrew_voice_review.py`, recomputed for all 3,233: 0 differ).

## 4. Defects (hand-offs)

Ids are `QA-B36-n`. The failing test of each is in `app/test/qa_b36_open_defects_test.dart` (skipped unless `QA_OPEN=true`):

    cd app; flutter test --no-pub --dart-define=QA_OPEN=true test/qa_b36_open_defects_test.dart

The owner of the fix removes `skip: _open` from its test when the fix is in.

### QA-B36-1 (major): the sample that glides over the answer tiles is under the speech bubble in the last step

- **Owner of the fix:** design-director (where the sample stands) with app-developer; hebrew-text-editor only if the answer is a shorter level 3 line.
- **Where:** `app/lib/play/hints/tap_plans.dart:399-428` (`_sample`, the box `above(i)` at 417-418 stands on the top edge of each tile);
  used by `tap_plans_c.dart:68` (`_writtenNumeral`) and `tap_plans.dart:447`, `:483`, `:1115` (colour, shapes, copy).
- **Items:** new: `x.numb07.21`, `x.numb07.22` (NUM-B-07), `b36.shpa06.1`, `b36.shpa06.2` (SHP-A-06). Older, same fault: about 35 more
  (COL-A-01 to 07, COL-B-03, SHP-A-01 to 05, 10, SHP-B-08, LOG-A-01, LOG-A-09). 79 cases (item times board) in the test.
- **Repro:** phone or small phone, open `x.numb07.21`, press the lamp three times. In the worked example the numeral "3" glides over
  the tiles; the right tile is the first option, so a right-to-left row puts it at the right end, right under the bubble: the
  "3" is half hidden in the last two steps while the hand presses the tile. Tablets are fine (the sample is whole, the hand covers
  a corner of it: polish).
- **Expected:** `docs/design-spec.md` 6/7 and the B-40 rule "nothing covered": the sample stays whole. **Actual:** under the bubble.
- **Evidence:** `docs/qa/b36-qa1-numb07-sample-under-bubble-phone.png`, `...-se.png`; QA scratchpad `png2\sheet_x.numb07.21__phone.png`.
- **Failing test:** "QA-B36-1: in the last step of a sample plan the sample is not under the speech bubble on a phone" (79 cases).

### QA-B36-2 (major): the hand of the symbolic NUM-B-16 worked example is behind the eye button

- **Owner of the fix:** design-director (the empty places sit in the stage's top left corner, or the hand comes from below, as
  `HandFrom.below` does for the shop) with app-developer.
- **Where:** `app/lib/play/hints/tap_plans_b.dart:481` (`_sentence`, level 3).
- **Items:** `b.numb16.2`, `.4`, `.6`, `.8` (the `12 = 10 + ?` items) on the phone and the small phone. A scan of all 53 tap items of
  the new and B-38 sets on four boards finds no other.
- **Repro:** small phone or phone, `b.numb16.2`, lamp three times: the hand that counts the empty places (the little blocks at the
  top left of the stage) is behind the eye button of the top bar; the child sees a sliver of a finger and the "2" badge.
- **Expected:** the demonstration can be seen. **Actual:** hand mostly hidden, counted places 7 points wide.
- **Evidence:** `docs/qa/b36-qa2-numb16-hand-under-top-bar-phone.png`; tablets show it correctly (`png4t\sheet_b.numb16.2__tabL.png`).
- **Failing test:** "QA-B36-2: the hand of the symbolic NUM-B-16 worked example is not under the top bar on a phone".

### QA-B36-3 (major on the small phone, minor on the phone): level 3 lines too long for the speech bubble

- **Owner of the fix:** hebrew-text-editor (shorter lines, 4 lines at most) or design-director (more room); curriculum-expert decides if a step may go.
- **Where:** `content/starter/activity.*.json` hints[2] (generated by `tools/hint_lines.py`) and prompts of 4 items;
  `app/lib/play/activity_frame.dart:77` (`fitFont` goes down to 14 and then gives up).
- **Count:** at the smallest font, with 8 points of room: 134 lines do not fit at the base of this branch (`e5d74c7`: 133 small phone, 1 phone)
  and **318 do now** (small phone: 288 level-3 lines and 4 prompts, phone: 26 level-3 lines). Worst: `b.mathb03.14` on the small phone (7 lines,
  66 points over). The 1,142 rewritten hint lines roughly doubled it.
- **Repro:** small phone, `b36.numa14.2`, lamp three times: five lines; the bubble is taller than its room and its last line lies
  over the top of the right answer tile (the right one). Also `b.numb16.2`.
- **Expected:** a line fits its bubble (`docs/design-spec.md` 7, "Heebo, line height 1.7"; no text clipped or covered). **Actual:** overlap.
- **Evidence:** `docs/qa/b36-qa3-bubble-over-tile-se.png`.
- **Failing test:** "QA-B36-3: every prompt and level-3 line fits the speech bubble at the smallest font on the phone and the small phone" (318 cases).

### Minor

| Id | Owner | Where and what | Evidence |
|---|---|---|---|
| QA-B36-4 | design-director | `tap_plans_c.dart:166-167` (`_hiddenPart`, MATH-B-18, `b.mathb18.10`, `.11`): the frame card of levels 2 and 3 half covers the stage's own picture. Phone: two of the three fish and the stone are under the card and **one fish is left standing beside it**; tablet: a fish is cut by the card's edge and the stone half shows. Cover the whole picture or none. No test (the object rectangles are private to the plan). | `docs/qa/b36-qa4-mathb18-card-covers-stage-phone.png`, `png3\sheet_b.mathb18.10__tabL.png` |
| QA-B36-5 | design-director | `tap_plans_c.dart:101` (`_inTwos`, NUM-B-17, `b.numb17.13`): in the last step the big answer badge "10" is drawn over the counted badges "4" and "6" and the tops of two columns. | `docs/qa/b36-qa5-numb17-answer-badge-covers-counts-phone.png` |
| QA-B36-6 | hebrew-text-editor, with curriculum-expert | The level 2 line of 9 second-way items is the generic "נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד" while the picture is new: `b36.numa06.1/.2` (the asked number on fingers), `x.numb07.21/.22` (the numeral written), `b.numb17.13` (rings 2, 4, 6...), `x.mathb17.12/.13` (the value of each coin), `b.mathb18.10/.11` (the whole as a frame), and `b.shpb08.10`. `tools/hint_lines.py` (family table). Their level 3 lines match. (The older count items have the same generic line over the fingers card, so this is a polish, not a regression.) | the sheets of section 5 |
| QA-B36-7 | app-developer, infrastructure-engineer | **Closed by QA.** `D:\nitznutz-k-0.11.0\app\test\engine\engine_adapter_test.dart` was not `dart format` clean (one long test name), so `apply-k.ps1` would have turned the CI format step red. I formatted it with the repo's page width (13 changed lines, test names and expectations unchanged). | `dart format --set-exit-if-changed .` exit 0 afterwards |
| QA-B36-8 | design-director | `tap_plans_c.dart:134` (`money`, `x.mathb17.12/.13`, level 2): each value badge sits on the rim of the **next** coin, so "5" reads as belonging to the coin "2", and it repeats the number printed on the coin. Put the badge below the coin, or show the running sum already at level 2. | `png2\sheet_x.mathb17.12__phone.png` |
| QA-B36-10 | design-director | `tap_plans_c.dart:50-57` and `_zero` (NUM-A-14, `b36.numa14.1`, `.2`, levels 2 and 3, **both tablets**): the empty ten-frame card is smaller than the big "0" of the stage, so the top of the "0" shows above the card as a dark cap. On the phone the numeral is not there. Cover the numeral or draw the card over a clear stage. | `docs/qa/b36-qa10-numa14-zero-numeral-peeks-above-card-tablet.png`, `png3\sheet_b36.numa14.1__tabP.png` |
| QA-B36-9 | design-director | `b15.shpa08.1/.2` (cat in, on): the level 2 picture (a basket with a tiny duck, about 40 points in a card of 150) is small to read. | `png4p\sheet_b15.shpa08.1__phone.png` |

## 5. PNGs looked at

Rendered with a scratch test (`qa_b36h_render_test.dart`, not kept) through the real lesson screen, the lamp pressed for each level, on
**phone 852x393, small phone 667x375, tablet landscape 1180x820, tablet portrait 820x1180**; one image per level (base, level 1 in
the glow, level 2 at rest, level 3 at four moments with the last one on the answer). All under
`C:\Users\ramfr\AppData\Local\Temp\claude\D--nitznutz-content\4a388da1-7f7b-422e-8f53-18c381ca669b\scratchpad\b36h\`
(not in the repo; the six that prove a defect are copied to `docs/qa/`). 328 renders for the 12 new-plan items and 896 for 36 more items.

**The new hint plans of `tap_plans_c.dart`** (contact sheets `png2\sheet_<id>__<device>.png`, tablets `png3\sheet_<id>__tabL|tabP.png`):

| Plan | Items | Sheets opened |
|---|---|---|
| NUM-A-06 plate in a pile | `b36.numa06.1`, `.2` | `png\sheet_b36.numa06.1__phone.png`, `png3\sheet_b36.numa06.1__tabL.png` |
| NUM-A-14 zero | `b36.numa14.1`, `.2` | `png\sheet_b36.numa14.1__phone.png`, `png2\sheet_b36.numa14.2__se.png` |
| NUM-B-07 numeral | `x.numb07.21`, `.22` | `png2\sheet_x.numb07.21__phone.png`, `png3\sheet_x.numb07.21__tabL.png`, `png2\sheet_x.numb07.22__se.png` |
| NUM-B-17 count in twos | `b.numb17.13` | `png2\sheet_b.numb17.13__phone.png`, `png3\sheet_b.numb17.13__tabL.png` |
| MATH-B-17 coin chart | `x.mathb17.12`, `.13` | `png2\sheet_x.mathb17.12__phone.png`, `png2\sheet_x.mathb17.13__se.png` |
| MATH-B-18 hidden part | `b.mathb18.10`, `.11` | `png2\sheet_b.mathb18.10__phone.png`, `png3\sheet_b.mathb18.10__tabL.png` |

**Read:** rows run left to right and nothing is mirrored (the ten-frames, the number path, the robot grid, the coin chart, the
counts 2, 4, 6, 8, 10 and the sums 5, 7, 8 all ascend left to right; the numeral glyphs `glyph_3` and `glyph_7` are the right way, the
`_rev` ones are the wrong options). In none of the six plans is a right answer framed, lit or marked before its last step: level 1 lights
things in turn (tiles included), level 2 has no hand, level 3 puts the hand on the answer last. Nothing is clipped except
as the defects say. Not opened (rendered, passed the script checks): `b.numb17.14` (a number-line item), `b.mathb18.11`,
`b36.numa06.2` on the tablets, SE and tablet portrait of `b36.numa06.1`, `b36.numa14.1` and `x.mathb17.12`.

**Also looked at, all four devices rendered and the phone, small phone and at least one tablet opened:** NUM-B-16 (`b.numb16.1`, `.2`, `.9`,
`.10` : `png4p\sheet_b.numb16.9__phone.png`, `png4p\sheet_b.numb16.2__se.png`, `png4t\sheet_b.numb16.2__tabL.png`), the cat items
(`b15.shpa08.1`: `png4p\sheet_b15.shpa08.1__phone.png`, `png4t\sheet_b15.shpa08.1__tabP.png`; `b15.shpa08.2`, `b36.shpa08.1`),
the cube items (`b.shpb08.10`: `png4p\sheet_b.shpb08.10__phone.png`, `png4t\sheet_b.shpb08.10__tabP.png`; `x.shpb09.4`, `b.shpb08.5`,
`b15.shpa07.2`), and a sample of every new kind: give, count, balance, build (with no model, days, growing towers), number line,
robot (Band A and `b.csb04.7`), shop, sort (colours, shapes, share), spot, trace, story, the mixing item, the shape fit. The 44
items of the mosaics `png4p\mosaic0..2.png` and `png5\mosaic0..1.png` (level 2 and the middle of level 3 on the phone) were read
against their lines.

**Hint line against picture (item 5):** 64 items were read line by line against the picture (about 20 at full size, 44 in the mosaics);
the findings are QA-B36-6 (generic level 2 line) and the lines of QA-B36-3. The level 3 lines of the six new plans say what the
picture shows: "we count in twos: 2, 4, 6, 8, 10", "we write three in two arches that open to the left", "we add what is written on each
coin", "we see three, in all seven, what is missing: four", "we look for a frame with no fish; when there is nothing the number is
zero", "we count and stop". None says a number the picture does not show.

## 6. Coverage map (criterion to proof)

| Criterion | Proof |
|---|---|
| the pack builds, signs, verifies with one key, equal bytes | `pack_builder build/verify`; `starter_pack_test`, `publish_test` (vector 0.11.0 sha4b86fe23...) |
| every skill can reach mastery, `graph.report()` empty | `mastery_reachable_test` (3 tests), `engine_adapter_test` |
| each new item's tags are the spec's | `audit_items.py`, `audit_pairs.py` (QA scratchpad); `content_lints_test` ratchet (202 + 7, independently counted 209) |
| every wrong move has a line, every tag a line | `playthrough_test` (lines 140-245) |
| every item has 3 hints, none generic at level 2, the hand only at level 3 and on the answer last | `hint_ladder_test`, `hint_qa_test`, `hint_second_way_test`, **new** `qa_b36_open_defects_test` first test |
| every new tap item can be answered by voice or is off for a reason | `qa_voice_answer_audit_test` (1,118 items, 331 spoken) |
| Hebrew sources, generators, regeneration | `test_hebrew_sources.py`, `test_generators.py`, `regen_content.py` x2, the approved-rows recount |
| the voice respelling of "two" | **new** test in `voice_gen_test.dart` (section 7) |
| **no coverage:** the hint pictures against the speech bubble, the top bar and the pictures they explain | **new** open tests QA-B36-1, 2, 3 (before this there was no test of the bubble's fit at all) |
| not covered by any test: QA-B36-4, 5, 8, 9 (need the plan's private rectangles) | PNGs only |

## 7. The voice questions

**The audit and the three calls of the app-developer** (`qa_voice_answer_audit_test.dart`, the K version): of the 43 new choice items
19 are spoken (13 `tap_answer`, 6 `count_tap`) and 24 are not, each for the rule of `voice-answer-by-activity.md`; the audit's three
tests (each spoken option has words of its own and no two sound alike; saying an option is heard as that option only; the flag agrees with the rule
for all 1,118 items) pass.

- **`b.mathb07.9` ("five apples and zero, how many now?", answer five) in the reviewed list: agree.** It is `b.mathb07.1` in other
  words: a sum that keeps a number, which the curriculum-expert kept (QA-21). The list is the place where a new such item has to be
  looked at, and it was.
- **`b.numb10.11` and `.12` ("which is bigger, nine or six?") in the reviewed list: agree.** The prompt names both numbers, so saying one
  is a real choice and a child who repeats the last word gets the wrong one, the same as a tap; it is not the echo of QA-21 (where the
  prompt names the answer alone). The curriculum-expert should confirm it in one line.
- **`b36.shpa06.1` and `.2` as fit tasks with the mic off: agree.** All the other items of SHP-A-06 (the five shape-builders and
  `b15.shpa06.1/.2`) are mic-off; the skill is the fit of a turned shape, not its name. One thing for the developer: the new
  `_echoItems` comment cites "a decision for the curriculum-expert to confirm"; it should be closed in `voice-answer-by-activity.md`,
  because the set is named "echo" and these are not echoes.

**`content/voices.json` › `pronunciation`** (`שְׁתַּיִם` and `שתיים` become `שתַּיִם`, round 4, spelling D) was **not** covered by a test with
the real file (the existing tests used a made-up table). I added one to `app/test/voice_gen_test.dart`: for every character of
`voices.json` it checks the table itself (both keys, written with escapes so no editor can reorder the marks), that the pointed form
(shin, sheva, shin dot as the pack writes it, 660 times) and the plain form both come out as `שתַּיִם` in the request, that a prefix
follows (`וּשְׁתַּיִם`), that the other words of the line do not change, that a second pass changes nothing, and that `שְׁתֵּים` (the "two"
before "twelve", 92 times) is **left alone**. It passes (55 passed, 2 skipped in the file). Two further facts: the plain form occurs
only twice in the pack's texts, the pointed 660 times; D was not heard in hero-son's voice or at the start of a sentence (the owner's
own note), which no test can settle.

## 8. What I could not check

The real phone and a child's hands; the sound; the hand's timing in motion (a still image of each step was taken, not a video;
`b36.csa03.1`'s highlighted arrow looked one step behind the path badge in one frame, which may be only the moment I took it, so
it is not filed); the tablets of `b.numb17.14` and the second items of the new plans (rendered, not opened); `deno task check`;
`flutter test` in the real worktree (it is red by design until the signed pack is bundled; part K's pins fix that).

## 9. Files QA wrote or changed

- `app/test/qa_b36_open_defects_test.dart` (new): the passing "answer last" test and the three open defect tests.
- `app/test/voice_gen_test.dart`: the pronunciation test of section 7.
- `D:\nitznutz-k-0.11.0\app\test\engine\engine_adapter_test.dart`: formatted (QA-B36-7).
- six PNGs `docs/qa/b36-qa*.png`.
- this record.

Nothing was committed. The throw-away key was deleted (section 10).

## 10. Clean-up

The throw-away key `...\scratchpad\b36h\throwaway.key` and the scratch copy's public key were removed at the end;
`%USERPROFILE%\nitznutz-secrets` was never read; `--replace-public` was used only in the scratch copy; nothing was published.
