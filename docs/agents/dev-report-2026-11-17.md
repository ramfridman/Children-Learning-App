# Developer report, M11 minimum sizes round (branch `lands-ux`, tree on top of 88c1df50, nothing committed)

No process of mine is still running. The last full `flutter test` finished (output: `C:\Users\ramfr\AppData\Local\Temp\claude\969a235f793dc09c\9decf8b8-49be-4395-93f0-a072d041fa15\scratchpad\full_final.txt`). No `flutter_tester` is left.

## Result in one paragraph
The sort board (section 3), A3, A8, A9, A10, B1, B3 and the W1/V2 changes are built. A4, A5, A6, A7, A11, A12, B2, B4-B9 and tablet growth for the other templates are NOT built. Final full run: **6,922 passed, 31 skipped, 2 failed** (both expected, named in D). Analyzer 0 issues, format clean.

## A. Close-out of the previous round (items 1-6, all done)
1. V6 waivers: 14 new ones in `tagWaivers`. This round I removed `b.mathb10.4`, `.5`, `.6`, `.8` (they carry M-GRP-ONE now); the "waived taps are exactly the failing ones" test is green.
2. `give_n` numeral: schema, validator (`_giveNumeral`) and `author.py`, template version 1.3. `show.apples.3` and `show.birds.4` were turned back into `give` specs in `content/units/counting-hills.json` (editor to be told: a unit edit). `BandCTest.test_the_bubble_shows_the_sentence_a_question_says_over_blocks` is green. Review of the new `tools/check_maths.py` give_n rule (bubble equals `answer.n + scene.prefilled`): it agrees with `author.py` (`n:%d` of n + prefilled). No change needed.
3. Re-pins of golden and layout tests: done earlier.
4. The five lands are in `arcDomains` (all six lands now). V4/V6/V7 = 0.
5. The editor's tests were left alone.
6. The close-out full run and per-land Show counts were reported in that round; this round's counts are in D.

## B. Built, per finding (before -> after, points)

### Sort board (section 3; A1, A2, B11): DONE
New `app/lib/play/sort_board.dart` (`SortBoard`, `SortTray`, `SortBinBody`, `CountBadge`, `SortTally`, `sortMark`), wired into `app/lib/play/sort_drag_session.dart`.
- Phones: stage is the whole start column (377x260; SE 264x256); two or three shelves from the top, sign column at the start side (rule's sample 44/40, label under it); well beside it. The newest card is shown at full size; earlier ones pile under it (up to two edges) with a count badge from two cards. Tray is a deck under the bubble: top card is a wide answer tile (184x88; SE 196x86; the look's tile for square pictures), waiting cards are two edges; one card at a time. Hints and the host act on the top card (`_deckOrder`).
- Tablets: card 848 wide from the margin (portrait 772), 270 tall for strips (portrait 420), 400 (portrait 520) for square pictures with one row of tiles. Two bins side by side with a header row (mark and label, 24 pt) and a well of full-size cards. Tray: grid of wide tiles (300x112; portrait 340x128; three columns from five cards) or a row of the look's tile (two rows from seven).
- Drag copy = card size, 0.9, lifted 6, scale 1.04.
- Sizes: animal in a bin card 9.3 -> 27 (phone), 24 (SE), 43 (tablet L), 40 (tablet P). Animal in a tray card 17/15/19/25 -> 25/27/36/43. Square item in a bin 26 (22 low) -> 48/44/64. Bin label 13 pt w700 -> 18 pt (24 tablet) w500, line height 1.7, grows with the text size where its box allows, never below its own size.
- A size rule's samples (big and small ball) get a larger box (64 phone/60 SE/96 tablet) because the small one's ink is a third of its box; its ink is about 17 pt on a phone, under the R1 exception floor of 24 (needs new art or a different bin layout: design-director).
- Keys: `sort-stage`, `sort-tray`, `item-<id>`, `bin-<id>`, `bin-label-<id>`, `bin-strip-<id>` is gone (the label strip no longer exists), `bin-sample`, new `bin-card-<id>`, `bin-pile-<bin>`, `bin-count-<bin>`, `tray-card-<id>`.
- Host: lifted card on a phone is capped at 150 (`_spotSide`) so the shelves stay in view and a ball has a way to roll.
- Tests: `sort_strip_test.dart` (the table on four boards, pile and badge, never mirrored), `sort_label_scale_test.dart` (every bin label of every sort on four boards at 1.0/1.15/1.3: >=18/24, w500, height 1.7, never cut, no overflow), `hint_band_a_test.dart`, `logic_layout_test.dart` (updated for the new geometry).

### The 12 severe + 11 medium findings (order of 4.1)
| Finding | Status | Before -> after |
|---|---|---|
| A9 count-tap | DONE | Touch square `max(object,48)` (60 tablet) -> the object's cell (<=96): 64 or more for 3-8 objects on the phone's tall stage, about 59 for 9-10. Drawn object about 22-24 -> 0.84 of the cell. Target to fly to capped at 110. Phone uses the tall stage from 4 objects. Computed from geometry, not measured for every count. |
| A3 clock | DONE | Numerals 13.8 (SE 11) -> about 28. Face 252 across on a phone (meet stage). Controls 56 pt tiles with 4 pt margin in the column under the bubble (two rows of two with the half tile). Tablet card 400 (portrait 520). |
| A4 picture graphs | NOT DONE | Decision of the curriculum-expert (columns, 26 pt pictures, tiles in a column beside the chart) not built. |
| A8 sets on tiles | DONE | Cell 20 (picture 17) -> 27 (picture about 25) for 3-9 pictures; ten stays about 19 on a 96 tile (`tileGroup` in `sprite_group.dart`, used by tap-answer tiles and match-pairs). |
| A6, A7 | NOT DONE | |
| A5 balance | NOT DONE | Needs a taller scale and a tile column; hint hand tips depend on the tile sizes. |
| A10 trace pad | DONE | Pad 122 -> 247 on a phone, figure about 200; tablet card 400/520. |
| B1 number line | DONE | Labels 17 -> 20 (tablet 28). Tick spacing 0-20: 14 -> about 26 phone, 38 tablet. Ticks 4x18 -> 4x20, labelled 6x28. Phone stage is the answer band (24,244,581x112; SE 472x124). |
| B3 coins | DONE | Purse scale 1.111: 1 shekel 48, 2 shekels 58, 5 shekels 64, 10 shekels 61 (a third larger on tablets); shrinks only as far as the rows need to stay above the no-hotspot line. Tap margin 3 -> 4. Counter's `most` 0.8 -> 1.111. match_coins tiles not changed. |
| A11, A12, B2, B4, B5, B6, B7, B8 | NOT DONE | A12 (small on purpose, smallest >=24) and B2 (horizontal strip, arrows 28, strip 44) have curriculum-expert decisions but are not built. |
| B9 c1-blocks hint-card cubes | NOT DONE | The spec offers "keep it" or "a bigger card" and does not say how: design-director. |
| B10 celebration | DONE (not measured) | Pre-M11 celebration card on tablets 520 -> 640 wide, cameo 112 -> 160, text 26 -> 32. |
| B11 sort tray tiles | DONE | Tray tiles `clamp(..,44,84)` -> the look's tile / deck. |
| C1, C2 tablet growth | PARTLY | Only for sort, clock, count, trace and number line (`withBigStage` in `choice_row.dart`: card 848 wide from the margin, 400 tall; portrait 772x520). Every other template unchanged. |
| C3 empty answer band | PARTLY | Count (tall stage), trace, clock, number line only. |

### W1 and V2
- W1: 396 -> **159**. Rules in `app/lib/content/w1_words.dart` (`w1CountingRanges` NUM-A-01 to 5, A-02 to 10, B-01 to 20, B-02 to 30, C-01 to 100; `w1IsCounting` with the "and" prefix; `w1Sequences`; spelling variants) and `metBeforeAsked` (right option only in a number tap; one unknown word allowed when the card's picture is an everyday object; sequences as sets). Both switches confirmed. `test/arc_checks_test.dart` pins 159.
- V2: a second Show of a skill on one template is allowed when each Show of it is named by a lesson's `parts.show` (test added).
- Remaining W1 by class (for the curriculum-expert): colour names (about 60: COL-A-01..07, COL-B-02..04, LOG-A-01/02/03/06, LOG-B-01/06/09); size words (LOG-A-02, A-03, A-06, A-10, MATH-A-04); shape plurals/names (COL-B-04, LOG-B-06, LOG-B-09); counting words in skills whose prerequisites hold no counting skill (MATH-B-01/02/03/06, CS-A-04, CS-B-01, NUM-B-06/09/14, MATH-A-07 "four fish"); object plurals (MATH-B-19 11, NUM-B-06 7, NUM-A-08); tower labels (LOG-A-10, LOG-B-04); ordinal/day spellings (MATH-B-14 "Friday").

### Pins and other
- `tools/test_hebrew_sources.py::test_table_counts`: rows 17,110; changed-and-done 963 (measured; 960 once the CE's three generator wordings land).
- `app/test/content_lints_test.dart`: 1,328 activities (3 new NUM-A-09), 13 known new gaps (`b.mathb10.8` removed), 64 old gaps (was 67).
- `docs/audio/voicing-groups.json` regenerated with `tools/voicing_groups.py` (new `vo:host.timi.show.log_b_06.predict`).
- `activity_frame.dart`: a phone stage that starts at or below y 200 (the number line) makes the bubble keep clear of it and widen to the start side; the four `bubble_over_stage_*` pins stay at 0.
- Docs: `docs/PLAN.md` (a minimum-sizes build-detail bullet), `docs/milestones/M11-stage2.md` section 11.9.

## C. Golden contact sheets (scratch, outside the repo; may be overwritten)
Base: `C:\Users\ramfr\AppData\Local\Temp\claude\969a235f793dc09c\9decf8b8-49be-4395-93f0-a072d041fa15\scratchpad\sheets\`
- phone: `phone_00.png`, `phone_01.png`
- phoneSE: `phoneSE_00.png`
- tabletL: `tabletL_00.png`
- tabletP: `tabletP_00.png`
About 263 golden PNGs changed (the update run rewrote 653; about 390 that were noise or text-only under 3% outside my template families were restored). I looked at the strip goldens on all four boards and at the phone clock, count, number line, trace, shop, sort goldens and the tablet-L set. Weak spots: on the phone number line the top-left of the screen is empty; on tablets the number-line marker stays at 52 and the numeral-to-set stage stays small.

## D. Full-test counts
- `flutter test --reporter failures-only` (final run, nothing else running): **6,922 passed, 31 skipped, 2 failed**:
  1. `starter_pack_test.dart`: "the pack was built from the sources in content/starter and nothing else" (expected: pack not rebuilt after the content changes).
  2. `voice_text_test.dart`: "every line the pack asks for has a row and an unchanged caption" (editor's rows, e.g. `vo:fb.almost`).
- Earlier update-golden run of the same tree: 6,921 passed, 3 failed (the two above plus `voice_gen_batches_test`, fixed by regenerating `docs/audio/voicing-groups.json`).
- Python: `test_arc_build` 6 OK, `test_generators` 43 OK, `test_check_maths` 78 OK, `test_hebrew_sources` 30 run, 2 failed (`test_done_rows_have_ui_text`, `test_proposed_rows_keep_their_text`: the CE's `band_b` wording "אֵיזֶה מִסְפָּר" against the table's "מִי"; editor/CE).
- `flutter analyze`: 0 issues. `dart format --set-exit-if-changed`: clean. `deno task check` not run (nothing under `supabase/` changed).

## E. Hand-offs
- curriculum-expert: the W1 classes above; B2/A12/A4 are decided but still to be built by me; tell the editor that `counting-hills.json` was edited.
- design-director: B9 (hint-card cubes), size-rule sample ink under 24, number-line phone empty top-left, tablet number-line marker, balance tile column (A5).
- qa-engineer: `test/min_sizes_test.dart` per section 5, when you want the verify round.
- security-engineer: none (no gateway, auth, crypto, pack or sync change).

## F. Files
New: `app/lib/play/sort_board.dart`.
Changed (`app/lib/play/`): `sort_drag_session.dart`, `choice_row.dart`, `clock_set_session.dart`, `count_tap_session.dart`, `number_line_session.dart`, `trace_session.dart`, `shop_pay_session.dart`, `sprite_group.dart`, `tap_answer_session.dart`, `match_pairs_session.dart`, `activity_frame.dart`. (`app/lib/content/`): `arc_checks.dart`, `w1_words.dart`.
Tests changed: `sort_strip_test`, `sort_label_scale_test`, `hint_band_a_test`, `hint_ladder_test`, `hint_part5_test`, `logic_layout_test`, `arc_checks_test`, `content_lints_test`; `tools/test_hebrew_sources.py`.
Docs: `docs/PLAN.md`, `docs/milestones/M11-stage2.md`; `docs/audio/voicing-groups.json`.
