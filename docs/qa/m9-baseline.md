# QA baseline of `m9-content` (board item B-6)

**By:** the QA agent, 2026-10-28. **Branch:** `m9-content`, local HEAD `9767a0a` (clean before this work). **Pack:** starter 0.8.0 (100 skills, 767 activities, 160 lessons, 44 misconceptions, 15 templates). Nothing in `app/lib/` was changed; the goldens and the publish test vector were not regenerated.

## 1. What ran

| Command (where) | Result | Time |
|---|---|---|
| `flutter test --no-pub --reporter failures-only` (app/, the whole suite, before QA's new files) | **994 passed, 0 failed, 0 skipped** ("All tests passed!", exit 0) | 21 min 43 s (23:05 to 23:26) |
| `dart analyze` (app/) | No issues found | 6 s |
| `dart format --output=none --set-exit-if-changed .` (app/) | 264 files, 0 changed | 3 s |
| `deno task check` (repo root, deno 2.9.6): fmt, lint, check, test | 178 passed, 0 failed, 7 ignored (the real-database integration tests, which need the local Postgres of CI) | 11 s |
| QA's new `test/template_sessions_playthrough_test.dart` | 8 passed (number line 19 activities, balance 18, spot the mistake 32, match pairs 17, shop 9, clock 8, trace 26, each at every place it is played; plus the cycle check) | about 2 s |
| QA's new `test/qa_open_defects_test.dart` with `--dart-define=QA_OPEN=true` | **8 of 8 fail, as intended** (QA-1 to QA-6, QA-13 and QA-14) | |
| The same file without the define (as in CI) | 8 skipped, nothing fails | |

### Slowest test files (for the CI `app` job, run 40760468617 hit 30 minutes)

Measured locally from the JSON file reporter of the full run (16 cores, `--concurrency` default). "Tests" is the sum of the test times in the file; "load" is compiling and loading the file.

| File | Tests | Sum of test times | Load | Slowest test |
|---|---|---|---|---|
| `starter_pack_test.dart` | 14 | **1,129 s (18.8 min)** | 7 s | **865 s**: "one changed byte anywhere ... (every 31st byte here)"; **260 s**: "every single byte ... (all bytes with NN_EXHAUSTIVE=1 or in CI)", which flips every 97th byte locally |
| `app_flow_test.dart` | 22 | 143 s | 5 s | 9.6 s |
| `golden_screens_test.dart` | 18 | 135 s | 8 s | 10.4 s |
| `voice_gen_test.dart` | 24 | 83 s | 8 s | 48.0 s: "the command line plan prints the number of characters" (28.5 s for "generate refuses unless the count typed ...") |
| `voice_in_test.dart` | 14 | 79 s | 14 s | 10.4 s |
| `push_test.dart` | 9 | 71 s | 11 s | 11.6 s |
| `tutor_lesson_test.dart` | 9 | 66 s | 13 s | 14.2 s |
| `lesson_flow_test.dart` | 7 | 53 s | 11 s | 10.4 s |
| `prizes_screen_test.dart` | 6 | 51 s | 4 s | 12.1 s |
| `lesson_golden_test.dart` | 4 | 41 s | 13 s | 11.9 s |
| `playthrough_test.dart` | 6 | 40 s | 6 s | 20.0 s (the stage on every screen) |
| `unit_golden_test.dart` | 2 | 24 s | 6 s | 12.4 s (phone), 11.6 s (tablet) |
| All 75 files | 994 | 2,354 s | 634 s | |

**Reading:** the two byte-flip tests are 48 % of all test time and, running in one file, set the wall time: the rest of the suite was done by 23:09 and the last 17 minutes were that one file. Each flip costs about 7.5 ms (a full copy and verification of the 3.5 MB pack). With `CI=true` the second test flips all 3,505,610 bytes: about 26,000 s (7 hours) on this PC, so on CI it can only end at its own 10-minute timeout, as a failure, after the first test has already taken about 15 minutes or more on a 4-core runner. That alone explains run 40760468617 reaching 30 minutes. Data file: the JSON reporter output (`flutter test --file-reporter json:<file>`), summarised by QA with a short script; the infrastructure-engineer can reproduce it the same way.

## 2. Coverage map: M9 §1 "done when" and §5 against the tests

| Criterion | What proves it today | What no test proves |
|---|---|---|
| 1. About 95 skills, about 300 activities, about 2,400 items, all through the validator | The validator runs over every file when the pack is built and again when it is installed (`pack_validation.dart`; 61 broken-file cases in `content_validation_test.dart`); `starter_pack_test.dart` proves the bundled pack is the one built from `content/starter` and verifies; `publish_test.dart` counts 767 items and 44 misconceptions; `playthrough_test.dart` checks every prerequisite exists and every activity is in a lesson. QA added: the skill graph has no cycle (`template_sessions_playthrough_test.dart`). | No test states the promised totals (100 skills, 160 lessons) or an item count (the "2,400 items" of §1 is not defined anywhere in the pack: an activity is one item). The validator refuses only a skill that needs itself; a longer cycle was not checked until QA's test. |
| 2. 12 templates playable by tap, drag and voice | 15 templates exist. Tap paths: every template (`drag_templates_test.dart`, `lesson_flow_test.dart`, the M2 to M5 files). Drag paths: sort, build a pattern, shape builder (`tester.dragFrom`), trace (`startGesture`). Voice: tap answer, count and tap, flash, give N (`voice_*_test.dart`). Classifiers: each wrong answer and its tag in `drag_templates_test.dart` and, for every activity of the seven newest templates, through the real session in QA's new test. Goldens: `unit_*` on the phone and tablet landscape (90 PNGs). | **Goldens on tablet portrait and on the small phone (phone SE, stage 270 by 104) exist for no M9 template**; §5 asks for "both tablet ways". The clock's drag is tested only by single taps (`tapAt`), never by a drag gesture. The number line, balance, spot the mistake, match, shop and clock have no voice path (by design; not written down as "voice does not make sense here"). No test checks a touch target size against design-spec §6.1 on any M9 template. |
| 3. Every activity passes the headless playthrough | `playthrough_test.dart` plays every activity of every lesson through the real lesson controller: each wrong move with its line, the ladder of help to the top, the lamp, "I'm not sure", every lesson to its celebration; every stage is built on a phone and both tablet shapes without an exception. | For 11 of the 15 templates the playthrough's moves are **synthetic**: `submitPlacement(right: true)` and `submitPlacement(tag: a.wrongTag)` go round the template, so they cannot show that the real session can reach the right answer or that a real wrong move produces the tag (the tag coverage check is true by construction). QA's new test closes this for number line, balance, spot the mistake, match pairs, shop, clock and trace; **sort, build a pattern, robot path and shape builder are still synthetic**. The stage check builds each stage but never answers it (its name says "can be answered"), never checks for content clipped outside the stage (a `Wrap` that overflows throws nothing, see QA-4), and skips the small phone. "Every feedback line reached" is checked only for the line of each tag, not for the hint lines of the sessions' own help (rings, ghost hands, the walking dot). |
| 4. Hebrew reviewed | `starter_pack_test.dart`: every document is still `needs-editor` and none is `approved`; `source_rules_m1_test.dart` for `he.dart`; the validator's niqqud rule for Bands A and B. | The §5 test ("a line marked approved cannot differ from the reviewed text") does not exist; nothing is approved yet, so it has nothing to check. No test reads `docs/review/hebrew-master.csv` or counts what is still open. |
| 5. Voices for every line of the release | `starter_pack_test.dart` asserts the starter pack ships **no** recording yet (every line pending); `voice_test.dart` and `voice_fallback_test.dart` prove the fallbacks. | The §5 test (every `vo` id has a recording in every shipped voice pack, or is listed as text-only) does not exist. |
| 6. Art | The validator refuses a missing picture id (`checkAsset`, with broken-file cases). | No placeholder list is produced or checked. |
| 7. Release gate (§6) | CI's six jobs (not run by QA; see B-9), the network-hosts and source-rule tests, `gitleaks` and OSV in CI. | Everything else on the §6 list is manual or not started (caps re-checked live, the release keystore, iOS, the privacy text, the deletion path end to end, two weeks of child testing, the repository made private). |

## 3. Defects (ranked), each with the owner of the fix

Failing tests are in `app/test/qa_open_defects_test.dart` (skipped unless `--dart-define=QA_OPEN=true`); the owner of the fix removes `skip: _open` when it passes.

| Id | Sev. | What | Evidence | Owner |
|---|---|---|---|---|
| QA-1 | major | **Trace counts mistakes again after the help is at its top.** `TraceSession.end()` has no `controller.guided` branch, so every wrong stroke after the third is written as `incorrect` and `errors` keeps growing. M9 §14 rule 2: "a wrong drop is never counted twice once the help is at its top"; the other 14 templates keep it. | test QA-1 | app-developer |
| QA-2 | major | **Trace reads the finger a little off.** `toBox` divides by the outer side of the box, the painter draws inside its 4-point border (`side - 8`), and the touch is measured from inside the border: a finger on the painted start dot (36, 30) is read 3.1 box units off (measured), and at the far end (54, 90) about 7 units (computed: the error is the point times 8 / side). The error grows across the box; the tolerance is 12. On the phone (box 122 points) that is more than half the tolerance at the far side. | test QA-2; `trace_session.dart:191-216` | app-developer |
| QA-3 | major | **Match pairs: a set of one is a big picture, sets of 2 and 3 are tiny.** `_content` draws one picture full size and a set with `SpriteGroup`: measured on the phone stage, one apple 80 points wide, each apple of three 17 points. In `x.numa07.*` (numeral to set) the misconception is M-CNT-SIZE, which this picture teaches. M9 §13 fair-size rule. | test QA-3; `unit_match_numbers_phone.png`, `_tablet_landscape.png` | app-developer (sizes from design-director) |
| QA-4 | major | **Shop on the phone: coins vanish below the counter.** The counter holds two rows; with all the coins of `x.mathb17.2` on it (seven, as a child exploring does) the third row is outside the counter and clipped by the stage. Those coins are paid but cannot be seen or taken back. Six of the nine shop activities have six or seven coins. | test QA-4 | app-developer, design-director |
| QA-5 | major | **"Show me" and the lamp work during the praise.** After a right answer the frame keeps the eye and the lamp live for the 1.6-second praise pause (`lesson_screen.dart:441-443`, the controller has no guard): a tap writes `unsure` after `correct` for the same activity (engine evidence), cuts the praise line and says the "not sure" line. Every template. | test QA-5 | app-developer |
| QA-6 | major | **Number line, place mode: the frog is not on the screen.** With no start, the marker is drawn at `_x(from) - 1.5 × marker`, which is left of the stage's clip on every screen. 13 activities ask about "the frog". | test QA-6; `unit_number_line_place_phone.png`, `_tablet_landscape.png` | app-developer, design-director |
| QA-7 | major | **Balance: what lies on the pans cannot be counted.** The groups share one row per pan: about 5-point pictures on the phone and 10 on the tablet, floating halfway above the plates; the pans do not hang from the beam. `b.mathb09.*` asks the child to compare 5 + 4 with 3 + 2. | `unit_balance_compare_phone.png`, `_tablet_landscape.png` | design-director (spec), app-developer |
| QA-8 | major | **Balance, a sum compared: the level beam gives a wrong cue.** With `hideTilt` the beam stays level until the answer. A level scale means "the same": it gives the answer away in the four "same" items and points to "same" (tagged M-EQ-OPER) in the four others. | `b.mathb09.1` to `.8`; golden above | curriculum-expert, design-director |
| QA-9 | major | **Targets on the phone's 330 by 128 stage are far below design-spec §6.1** (Band B: answers 80 points, any control 56): number line 0 to 20 has ticks 14.3 points apart (6 activities); the rocket's fins and the house's door in the shape builder are about 15 points wide; spot-the-mistake cells about 50; the clock's numerals about 12 points high; the chart's pictures about 14; the trace box 122 points with a thin grey guide. The room below the stage is empty for trace, number line and spot the mistake. | goldens `unit_number_line_*`, `unit_builder_*`, `unit_clock_set_phone`, `unit_chart_*_phone`, `unit_trace_*_phone` | design-director |
| QA-10 | major | **The land paths ignore the band.** `nextLessonId` sorts a land's lessons by `sequence` only: the Band A lessons `match-numbers-sets` and `-more` (NUM-A-07) are lessons 48 and 49 of 49 in Counting Hills, after every Band B lesson; tracing shapes (SHP-A-02, Band A) is 23 and 24 of 25. A 3-year-old meets number lines to 20 before them. It also puts every new template 23 to 49 lessons deep, so the owner's phone check cannot reach them (see the phone script). | `next_lesson.dart`; the lesson files' `sequence` | curriculum-expert (order); app-developer (a dev-flavour "open a lesson" for the phone check) |
| QA-11 | minor | **Clock: an untouched clock is tagged M-CLOCK-HANDS.** `x.mathb15.1`, the first question of `set-the-clock`, starts at twelve; pressing the tick without moving anything writes "reads the long hand as the hour". `drag_templates_test.dart` asserts this as intended. Also at twelve the long hand is hidden behind the short one. | `drag_templates_test.dart:768-770`; `unit_clock_set_*.png` | curriculum-expert (start hour), app-developer |
| QA-12 | minor | **Chart: columns and tiles disagree.** On the phone the apple column and the red-ball column look the same (14-point pictures). The answer tiles run right to left (ball, banana, apple) under columns that run left to right (apple, banana, ball). Design-spec §8 leaves the category order "to validate". | `unit_chart_most_phone.png`, `_tablet_landscape.png` | design-director, curriculum-expert |
| QA-13 | minor | **Trace: a wrong second stroke wipes a right first stroke** (`finished.clear()` on every mistake). `x.numb07.5` and `.15` (the 4) have two strokes. | test QA-13 (marked as a design decision) | design-director decides, app-developer |
| QA-14 | minor | **English screen-reader labels in the child space:** `minus`, `plus`, `pay`, `check`, `back an hour`, `forward an hour`, `half past`, `undo`, `go`, and `left`, `same`, `right` built from ids (balance). TalkBack would read English in a Hebrew-only app. | test QA-14 (finds the literal ones) | app-developer, hebrew-text-editor (words) |
| QA-15 | major (CI) | **The pack's byte-flip tests grow with the square of the pack.** The pack is now 3.5 MB. `starter_pack_test.dart` "every 31st byte" makes about 113,000 full copies and verifications; "every single byte" runs every byte (3.5 million) when `CI=true`, which cannot finish inside its own 10-minute timeout. Measured: 865 s and 260 s locally (section 1). | `starter_pack_test.dart:67-94`; timing table above | infrastructure-engineer (CI), app-developer (the test: flip a fixed sample, or flip inside each entry once) |

Smaller things seen, not filed: the match faces have no scene background and are flat cards, not the clay answer tiles; in `know-the-coins` the coin itself shows the number to match; the balance `weigh` mode cannot be failed (plus until level); the shop prompt breaks "ה-וי" across two lines on the phone; on tablet landscape the tiles overlap the bottom of the stage card by about 20 points (all templates, from the frame's `tilesTop - 12`); the program strip of the robot is horizontal under the stage, where design-spec §7.4 asks for a vertical strip.

## 4. Functional review of the sessions (`app/lib/play/*_session.dart`)

Read for every template: the right path, wrong paths and tags, the help at each level, the guided state, rapid taps, drag against touch, leaving mid-activity, a second mistake during the "not yet" pause.

- **Rapid taps and a second mistake during the pause:** every session takes no move while `_busy` (from the answer until the end of the 1-second "not yet" pause, and for good after a right answer), so a second tap is dropped, not counted. Proven for the seven newest templates by QA's new test (each wrong move writes exactly one record) and by `drag_templates_test.dart`. Not implemented: the design-spec §6.4 holdover filter (a second touch within 300 ms and 24 points is ignored). Where a touch is an answer, `_busy` absorbs the second touch. Where a touch only changes the state it matters: a double tap on a match face selects and deselects it (nothing seems to happen); a double tap on a coin puts it on the counter and then puts on the next coin, which the purse's `Wrap` slides under the finger; a double tap on the clock's plus moves two hours. Not tested anywhere.
- **The help during the pause:** `TemplateSession` delays a hint that comes with a mistake until the pause is over, so the help never fights the "not yet".
- **Leaving mid-activity:** the session cancels all its timers on `dispose`, and the lesson screen disposes the session and the controller; the voice stops (`stopFor`). A lesson left mid-way is ended as `home`. Not tested for the new templates in the real screen (only `voice_in_test.dart` and `lesson_flow_test.dart` for the older ones).
- **Rotation:** the session lives as long as the activity (keyed by its index), and the stage is rebuilt for the new room, so state survives a tablet turning. A drag or a stroke in progress during the turn is lost (the gesture is cancelled); not tested.
- **Drag against touch:** sort, build a pattern and the shape builder take both and are tested both ways. The clock takes a drag, a touch and the arrows; only touch and arrows are tested. Trace is drag only (right: a tap is not a stroke). Number line, balance, spot, match and shop are touch only, which is right for them.
- **Guided state:** after the third mistake only the right move is taken in 14 templates; trace is the exception (QA-1). In the shop the coins of a wrong try stay on the counter when guided and the lit coins exclude them, so the help can show an incomplete way.

**Risks for the lesson flow:**
1. The path ignores the band (QA-10).
2. The eye and the lamp are live during the praise (QA-5); the same holds for the replay button (it replaces the praise with the question).
3. After a right answer `controller.next` runs from the session's timer, so the lesson moves on only while the session lives; home during the praise ends the visit as `home` (right), and nothing else can move the lesson on, so a session that never calls `next` (a template bug) would leave the child on a praised activity with only the home button. No test guards this for all templates; QA's new test checks the right answer is written, not that `next` follows.
4. A lesson whose activity cannot be finished by its own session would pass the playthrough (synthetic moves) for sort, pattern, robot and builder; the validator covers some of this (the shop's price, the clock's start), not all (a robot flag that cannot be reached, a slot that no piece fits).
5. The warm-up places only the lessons it asked about; an older child still walks the whole path.

## 5. Visual audit: PNGs opened

Phone: `unit_trace_numeral`, `unit_trace_start_only`, `unit_builder_house`, `unit_builder_train`, `unit_builder_rocket`, `unit_chart_most`, `unit_chart_more`, `unit_shop_pay`, `unit_match_coins`, `unit_match_numbers`, `unit_match_solids`, `unit_clock_set`, `unit_number_line_place`, `unit_number_line_jump`, `unit_balance_compare`, `unit_spot_numbers`, `unit_robot_plan`, `unit_drag_sort_three`. Tablet landscape: `unit_trace_numeral`, `unit_builder_rocket`, `unit_chart_most`, `unit_shop_pay`, `unit_count_seven` (for comparison), `unit_number_line_place`, `unit_balance_compare`, `unit_match_numbers`, `unit_clock_set`.

Not opened: the other `unit_*` PNGs of the earlier parts (colours, logic, shapes, money, flash, robot direct, drag sort, share, pattern on the tablet), and the M1 to M8 goldens. No tablet-portrait or small-phone PNG exists for any M9 template, so neither was reviewed.

## 6. What QA did not check

The real phone (B-10), sound and voice, a child's hands, TalkBack, frame times, the CI run itself (B-9), the pgTAP suite, the four older drag templates through their real sessions, every `unit_*` PNG (section 5), Hebrew wording (the hebrew-text-editor's area), and whether the curriculum's answer keys are right beyond "the session can reach them".

## 7. Re-verification, 2026-10-29 (board items B-11 and B-12)

**Branch** `m9-content`, local HEAD `5e8fab6` (fixes in `dd040cd`, `dc76c0f`, `5e8fab6`). Nothing in `app/lib/` was changed by QA; every mutation below was undone with `git checkout` and `git diff` was clean after each.

### What ran

| Command (app/ unless said) | Result | Time |
|---|---|---|
| `flutter test --no-pub --dart-define=QA_OPEN=true test/qa_open_defects_test.dart` | **QA-1 to QA-6: 6 pass**; QA-13 and QA-14 fail, as they should (still open) | 6 s |
| `flutter test --no-pub --reporter failures-only` (whole suite) | **1,038 passed, 0 failed, 2 skipped** (QA-13, QA-14) | **4 min 49 s** (was 21 min 43 s) |
| `dart analyze` | No issues found | 7 s |
| `dart format --output=none --set-exit-if-changed .` | 270 files, 0 changed | 2 s |
| `deno task check` (repo root, deno 2.9.6) | **179 passed, 0 failed, 7 ignored** (the real-database tests) | 12 s |
| `starter_pack_test.dart` + `zip_store_test.dart` (sampled mode) | 43 passed. "every 31st byte": **41 s** (was 865 s); "every single byte" sampled (every 97th): **14 s** (was 260 s); the oracle test on the real pack 10 s | 64 s |
| `NN_EXHAUSTIVE=1 flutter test --no-pub test/starter_pack_test.dart` | **14 passed, 0 failed**: every byte of the 3.5 MB pack changed in turn and refused (`tried == bytes.length`), 16 worker isolates | **20 min 51 s** for the file (the every-byte test 1,208 s = 20.1 min, under its 60-minute timeout; the every-31st test 39 s) |

### The defects

| Id | Verdict | Evidence |
|---|---|---|
| QA-1 | **closed** | The QA-1 test passes; `TraceSession.end()` now has the `controller.guided` branch (nothing written, the way shown again). |
| QA-2 | **closed** | The QA-2 test passes for the start and the end point of the path (tolerance 1 box unit; it read 3.1 off before). The developer's one change to the test, `await pause(tester)` after `g.cancel()`, is legitimate: a cancelled touch ends the pan, so `end()` judges a two-point stroke as a "not yet" and the session takes no touch for the 1-second pause; without the pause the second probe (the far end, where the old error was largest) would be dropped and fail on `isNotEmpty`, for a reason that has nothing to do with QA-2. The assertion itself is unchanged. (QA's original file was never committed, so it was compared with the description in section 3 and the failing run of the old code, which failed this same assertion.) |
| QA-3 | **closed**, new minor QA-16 | The QA-3 test passes: every picture of every set is drawn for the largest set (`lineSlots`). `unit_match_numbers_phone.png` opened: one, two and three apples are the same size. But all of them are now the small size (about 17 points in a card about 90 points wide): see QA-16. |
| QA-4 | **closed** | The QA-4 test passes: all seven coins of `x.mathb17.2` stay inside the counter and the stage. The coins shrink together (`CoinFace.fitScale`, down to a quarter at the least). Measured on the phone with a scratch test (not kept) over the five `pay-exactly` questions, every coin on the counter: the smallest touch box is 38.4 points (with seven coins), against 49.2 for the smallest coin in the purse. Below design-spec §6.1's 56 for a control, as the purse already is: part of QA-9, not a new defect. |
| QA-5 | **closed** | The QA-5 test and the new `lesson_controller_test` pass; the controller's `solved` flag makes the lamp and "not sure" do nothing after a right answer (no write, the praise kept, `actionNonce` unchanged). Mutation: removing the guard in `unsure()` fails both tests (`['correct', 'unsure']`); removing it in `showHint()` fails the controller test (the praise line replaced by a hint). The replay button during the praise (section 4, risk 2) was not part of QA-5 and was not checked. |
| QA-6 | **closed** | The QA-6 test passes; `unit_number_line_place_phone.png` opened: the frog waits in the top left corner of the stage, clear of the line, before an answer. |
| QA-10 | **split**: the dev access is **closed**; the path order stays **open** (curriculum-expert, board B-15) | `app_flow_test`: in the dev flavour a long press on the version opens the dev page, "Open any lesson" lists every lesson once and opens the clock lesson on its first activity, and home comes back to the list. The prod claim holds by two tests: the long press does nothing in prod ("the dev page is hidden in the prod flavour", the only link to the dev pages) and `DevLessonsPage` shows only a placeholder in prod even if pushed directly. `nextLessonId` still ignores the band. |
| QA-13, QA-14 | open (out of scope) | Still fail with `QA_OPEN=true`, skipped otherwise. |
| QA-15 | **closed** (the test part; the CI run is the infrastructure-engineer's) | See "The every-byte change" below. |

### The new tests: do they prove what they claim?

- **`response_contract_test.dart` (SEC-1).** It plays the real session of all 15 templates over every activity, right and wrong, and checks each written code against the server's pattern, which is tied to `testvectors/wire-patterns.json` (and the Deno test sends the same examples through `sync-push`). A last test checks every template of the pack was played. Mutation: the clock writes the old `3:30` again: "clock: every hour" fails (codes refused) and "every template ... was played" fails (it does not contain `clock_set`). Proves it.
- **`sync_engine_test.dart`, "a row the server will not take"** (with a fake server that refuses a whole batch for one bad field, like the real one). Mutation 1, no one-by-one retry (a refused batch marks all its rows refused): both tests fail (`pushedEvents` 2 instead of 5; 3 refused instead of 0). Mutation 2, the retry treats every failure as a refusal (`catch (_)`): "a failure during the one-by-one retry marks nothing as refused" fails (2 refused instead of 0). Proves it. Note: the fake's "lost answer" is a `StateError`; the real gateway's network errors were not checked to be something other than `bad_request`.
- **`lesson_controller_test.dart` (QA-5)**: see QA-5 above.
- **`sprite_group_test.dart` (`lineSlots`)**: checks the cell width and the centres for 1 and 3 with 4 and 3 slots. It proves the layout rule; the size on the screen is proven by the QA-3 test.
- **`app_flow_test.dart` (QA-10)**: see QA-10 above.

### The every-byte change (B-12)

- **The oracle** `app/test/support/zip_store_reference.dart` is the reader, writer, CRC-32 and name rule of `e6971fb:app/lib/content/zip_store.dart` exactly: compared by a script after removing comments and white space and the `reference` prefix of the four function names, the two are identical. It imports only `ZipEntry`, `ZipException` and `ZipLimits` from the production file, and `ZipLimits` did not change in `5e8fab6`.
- **The exhaustive test** still asserts `tried == bytes.length` (`tried` counts only refused packs, and any accepted offset fails the test before); the workers take each offset exactly once (worker w takes w·step, (w + workers)·step, ...), and each worker checks its copy is the genuine pack again at the end. The sampled mode asserts more than 300 refused.
- **The timeouts now fire.** With the 10-minute timeout of the every-31st test set to 5 seconds (test code, undone after), the test failed with "Test timed out after 5 seconds". The file itself still ran to 39 s, as the worker isolates finish their loops before the run ends: on CI a timeout fails the test, but does not stop the work at that moment.

### New defect

| Id | Sev. | What | Evidence | Owner |
|---|---|---|---|---|
| QA-16 | minor | **Match pairs: the sets are fair now, but small.** After the QA-3 fix every picture is drawn as one of the largest set in a line of `max(count, lineSlots)` cells: in `x.numa07.1` each apple is about 17 points in a card about 90 points wide on the phone, and the single apple is as small as the others. A 3-year-old counts these (NUM-A-07, Band A). The pictures could fill the card for the largest set (about 25 to 28 points for three). | `unit_match_numbers_phone.png` | design-director (size), app-developer |

### Not checked this round

The real phone (B-10, the script is updated for the dev flavour), sound, TalkBack, the CI run itself, the pgTAP suite, the coins on the counter on the tablet, the replay button during the praise, and whether the dev lesson page works with two children on the phone.

PNGs opened this round: `unit_match_numbers_phone`, `unit_match_numbers_tablet_landscape` (the same small apples, about 16 points in 95-point cards), `unit_number_line_place_phone`, `unit_number_line_place_tablet_landscape`. Seen, not filed: on the tablet the waiting frog is about 30 points in a stage about 550 by 270, alone in the corner; a child may not see it as the frog of the question (design-director, with QA-16).

## 8. Re-verification of B-20 (SEC-12), 2026-10-29

**Branch** `m9-content`, local HEAD `2235ac2` (clean before this work). Nothing in `app/lib/`, `content/`, `supabase/` or `testvectors/` was changed by QA; every mutation below was undone with `git checkout` and `git diff` was clean after each. The 22-minute exhaustive byte test was **not** run (the CI run of `2235ac2` runs it).

### What ran

| Command (app/ unless said) | Result | Time |
|---|---|---|
| `flutter test --no-pub --reporter failures-only` (whole suite, before QA's additions) | **1,052 passed, 0 failed, 2 skipped** (QA-13, QA-14) | 4 min 50 s |
| `dart analyze` | No issues found (also after QA's additions) | 7 s |
| `dart format --output=none --set-exit-if-changed .` | 271 files, 0 changed (272 with QA's new file, 0 changed) | 3 s |
| `deno task check` (repo root, deno 2.9.6) | **180 passed, 0 failed, 7 ignored** (the real-database tests) | 9 s |
| The ten touched test files again, after every mutation was undone and with QA's additions | 216 passed, 4 skipped (QA-13, 14, 17, 18) | 1 min 24 s |
| `flutter test --no-pub --dart-define=QA_OPEN=true test/qa_open_defects_test.dart` | QA-1 to QA-6 pass; QA-13, QA-14, **QA-17, QA-18 fail, as intended** | 2 s |

### Mutations: do the new tests prove what they claim?

| Mutation (product code, undone after) | Tests that failed | Verdict |
|---|---|---|
| The brake off: a batch refused event by event is marked refused again (`false &&` on the mismatch rule in `_send`) | "a server that refuses every event of a batch ..." (`refusedEvents` 6, expected 0) and "a lone event refused before the server took anything ..." | proves it |
| Only the lone-event half removed (`events.length > 1` alone) | "a lone event refused before the server took anything ..." | proves it |
| `understood` ignored (every lone refused event is a mismatch) | "a lone event refused after the server took a batch ... is marked" | proves it |
| A mismatch batch marked as sent (`inThisCall` filled anyway) | the two mismatch tests (the rows no longer wait) | proves it |
| The reset removed (`_resendRefusedOncePerVersion` not called) | "rows refused under an older format are sent again once ..." (`pushedEvents` 0, expected 2) | proves it |
| The reset every round (the version check off) | the same test (9 pushes, expected 5) and SEC-1's "sent once more on its own, then never again" | proves it |
| The reset leaves awards marked (the `rewards` update removed from `unmarkRefusedBySync`) | **nothing failed**; with QA's new test, "an award refused under an older format is sent again once ..." (`revisit_mission_sync_test.dart`) fails | gap, closed by QA's test |
| Lesson id bound back to 81 (`_lessonId` in `schemas.dart`) | `content_validation_test` (41 characters accepted) and `wire_format_test` (schema bound 81 > 40) | proves it |
| Only the lesson file's own id back to `_id` (81), the manifest kept at 40 | `wire_format_test` only (the validation test sees the manifest's error first, as its comment says) | proves it |
| `content/schemas/lesson.schema.json` back to 81 | `pack_builder_test` "JSON Schema files ... each is current" | proves it |
| The mission id with capitals again (`'mission-$skillId'`) | `wire_format_test` "every pack field ... fits" (and QA's new mission test); `world_screens_test` and `sync_engine_test` pass, as the sync's `wireLessonId` lower-cases it anyway | proves it |
| The SHA-256 check off in `pack_verify.dart` | "one changed byte in any file ..., with the checksums repaired, is refused by that file's hash" | proves it |
| The signature check off in `pack_verify.dart` | both "... manifest.json / manifest.sig, with the checksums repaired, is refused by the signature" (stage `manifest`, and accepted) | proves it |
| (Deno) `sync-push`'s `lesson_id` widened to 41 | "sync-push: every key, value and range it takes is the one in testvectors/wire-patterns.json" | proves it |

Read, not mutated: `zip_store_test` pins the four `ZipLimits` constants (a plain equality); `response_contract_test` only follows the renamed `data_fields` key; the sampled byte test now asserts the exact count `(bytes.length + 96) ~/ 97` instead of "more than 300", which is stronger.

### The revisit mission (the one change a child can see)

- `missionFor` makes `mission-<skill in lower case>`; the visit was already `mission:<skill in lower case>` (`lesson_screen.dart`). A mission's lesson id is used in exactly one place, `attempt.lessonId` (`lesson_controller.dart:516`), then the wire (`wireLessonId`) and the pull. Nothing looks a mission up by its id: the lesson screen gets the `Lesson` object itself; the bell flag's key, the island's growth and the bell come from the skill id and the engine (`eventOf` does not read `lessonId`); stickers are given only for `lesson:` visits; the only reader of `attempt.lessonId` is the warm-up (`placement`, lower case). No code builds or compares a mission id with capitals any more (searched `app/lib`, `supabase/functions`, `tools`).
- Rows written by an older build (`mission-NUM-A-03`) stay so on that phone and go lower-cased on the wire; nothing on the phone reads them by that id.
- **New test** `app/test/revisit_mission_sync_test.dart`: a mission made from the real pack for NUM-A-03 is played through the real `LessonController` and the app's own `attemptSinkProvider` (one "not yet", then every activity right, to the celebration); every answer is written as `mission-num-a-03` with its visit; the strict fake server (which refuses what `sync-push` would) takes every answer and the visit, nothing refused; a second phone gets the same answers under the same id and the visit `mission:num-a-03`. The existing `world_screens_test` mission test only opens the first activity.

### New defects

| Id | Sev. | What | Evidence | Owner |
|---|---|---|---|---|
| QA-17 | minor (security-engineer to rate; SEC-12 was low) | **The brake does not hold when the batch mixes types.** A gateway that does not know a key every answer carries (here `duration_ms`) still takes a visit or an award in the same batch, so the batch is not "all refused", and every answer in it is marked refused. A real batch is up to 40 events, answers first, then the visit and any award: after a normal lesson it is almost always mixed, so the case SEC-12 is about is mostly not braked. The answers come back only when `engineVersion` goes up, which nothing does after a server-side misdeploy (it is the constant 1). PLAN's wording ("takes none of the events of a batch") is what was built; the gap is in the rule. | `qa_open_defects_test.dart` QA-17: `['a.1', 'a.2', 'a.3']` marked refused | security-engineer (the rule), app-developer |
| QA-18 | minor (rare, but the device's sync of events stops for good, silently) | **A full batch of rows that are bad on their own stops every later answer from syncing.** Rows go oldest first by local id; when a whole batch is refused event by event it is a "mismatch": nothing is marked, the round stops, and the next round takes the same batch. The one value the device still sends unchecked is the phone's clock (`at`, `started_at`, `ended_at` must lie in 2017 to 2099): 40 answers made with a wrong clock (an offline tablet reset to 2010) before any sync stall that device's answers, visits and awards until a new build. Before `2235ac2` they were marked refused and the rest went on. Contradicts PLAN "one bad row never stops the sync". | QA-18: after three rounds the two good answers were never sent (`[]`) | app-developer (for example clamp or drop out-of-range times at the boundary, or count mismatches), security-engineer |

Seen, not filed: during a real mismatch each round makes 1 + 40 calls (the one-by-one retry); at one round every 5 minutes that is about 490 calls an hour against `sync-push`'s 600 per device per hour. A round after the limit fails like a network error and marks nothing, so no harm beyond log noise.

### Not checked this round

The exhaustive every-byte run (CI), the real phone, that the deployed gateway is the version this build expects, a real network error during the one-by-one retry, two real phones of one family, a bell flag on the phone (it cannot be made to appear on demand), and the pgTAP suite. The whole suite was not run again after QA's two new files; the ten touched files were (above).
