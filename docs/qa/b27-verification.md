# B-27 follow-ups: QA verification (qa-engineer, 2026-10-31)

Branch `b27-followups`, commit 4b0c9ac on origin/main, worktree `D:\nitznutz-b27`.

## Ran
- `flutter analyze`: no issues. `dart format --set-exit-if-changed .`: 0 changed (309 files).
- `flutter test test/board_geometry_test.dart test/qa_b23_b24_screens_test.dart test/voice_test.dart`: 100 passed, 0 failed, 0 skipped. The QA-19 group now runs in every build (the `QA_OPEN` gate is gone from `qa_b23_b24_screens_test.dart`; 24 cases: scales 1.0, 1.3 and 1.5 on the four boards, with the title kept inside the pill).
- Whole suite not rerun (the developer reports it green).
- All 73 changed goldens were compared pixel by pixel with `origin/main` (a small script; differences over a threshold of 30 in summed RGB, bounding boxes noted below). Looked at with the image viewer: `home_phone`, `home_phone_se`, `home_tablet_portrait_top`, `lesson_2_count_three_answers_tablet_landscape`, `lesson_5_give_two_tablet_portrait`, `lesson_1_red_flower_tablet_portrait` (old and new), `lesson_1_red_flower_phone`, `unit_flash_dice_tablet_landscape` (old and new).

## Criteria
| Item | Result | Proof |
|---|---|---|
| QA-19 daily pill (`Flexible` + `FittedBox`) and profile cards (minimum height, grow) | pass | 24 cases, no overflow, title inside the pill |
| Audio: a failing `stop` or `play` no longer ends the queue or reaches the zone | pass | two tests in `voice_test.dart` (a refusing stop; a failing play with a failing stop, the next line plays) |
| The log holds no secret and no child data | pass | `Log.d('voice: stop failed (${e.runtimeType})')`: the type only, debug builds only (`kDebugMode`), scrubbed |
| The caption still shows after a failed play | pass | the test asserts `director.current == 'vo:b'`; `_current` is set before `play` and `_finish` keeps it |
| Colour Bay sign whole (phone, SE) | pass | `home_phone.png`: sign starts 12 inside the edge; `home_phone_se.png`: 8 inside; geometry test at scales 1.0 and 1.3 on four boards: no sign cut, none closer than 8 |
| Portrait Market sign | pass | sign at 348 in `home_tablet_portrait_top.png`, whole under its island |
| Landscape tap areas | pass | 16 apart or more (the touch rule asks 24: noted, a choice of the board), each holds its island's middle and its sign's centre; Colour Bay's reaches its rainbow (541) |
| Tablet `tilesTop` 554 and 696 | pass | tiles at least 12 below the card's lip and on screen; `lesson_2_..._landscape.png` and `lesson_5_give_two_tablet_portrait.png` show the row clear of the card |
| No golden changed beyond the fixes | partly: QA-B27-1 | below |

## Goldens: what changed outside the fixes (QA-B27-1, minor)
All differences are inside the expected areas for the fixes (the sign at x 0 to 166, y 320 to 356 on the phone; y 314 to 350 on the SE; the Market sign; the answer-tile row y 520 to 655 on tablet landscape, y 662 to 797 on portrait), plus catch-ups of goldens that were already stale on main (hidden by the 3 percent tolerance):
- The question-bubble text changed in nine tablet unit goldens (`chart_most`, `clock_set`, `flash_covered`, `flash_dice`, `logic_pattern_yes_no`, `match_solids`, `math_time`, `same_or_not`, `trace_numeral`): the pack 0.10.0 text had changed and the golden had not. Example: "הִסְתַּכְּלוּ מַהֵר!" became "הִסְתַּכְּלוּ טוֹב...".
- The microphone is gone from the tablet lesson goldens `lesson_1..5` (B-24: the mic only where speaking is the answer). The phone lesson goldens (`lesson_*_phone.png`) still show a mic that the app no longer draws; it stays under the tolerance (about 2.3 percent of the phone frame) and passes. The regeneration was right for the tablets, and the phone files are still stale.
- Noise: 6 to 31 pixels (bubble tail, one sparkle) in about fifteen files.
- No regression found: every other pixel is the same.
- Pre-existing, not in scope: in `unit_flash_dice_tablet_landscape.png` an apple lies across the card's lower edge (y 468 to 548 against the card's 530); the old golden is the same.

## Trial merge with `b40-visual-hints` (PR 16), in a throwaway worktree (removed)
- Conflicting files (binary, both sides regenerated): `app/test/goldens/unit_balance_compare_tablet_landscape.png`, `unit_math_add_tablet_landscape.png`, `unit_same_or_not_tablet_landscape.png`, `unit_set_to_numeral_tablet_landscape.png`.
- `app/lib/child/activity_shell.dart`, `docs/PLAN.md` and `docs/agents/board.md` merge cleanly (different hunks: B-40 changed the SE's `tilesLeft` and `tilesWidth`, B-27 the tablets' `tilesTop`).
- Semantic clash (QA-B27-2): with the four conflicts taken from B-27, B-40's tablet hint goldens fail because the answer tiles are 34 points lower. In a run of the seven hint golden files, 15 distinct goldens failed (3.0 to 4.7 percent): tablet landscape `hint_tap_colour_l3`, `hint_tap_compare_l1`, `hint_tap_pattern_l2`, `hint_tap_ordinal_l3`, `hint_tapb_mix_l3`, `hint_tapb_after_l2`, `hint_tapb_sentence_l3`, `hint_tapb_week_l2`, `hint_tapb_hour_l3`, `hint_builder_l2`, `hint_robot_l3`; tablet portrait `hint_qa_colour_l3`, `hint_qa_count_l3`, `hint_qa_ordinal_l3`, `hint_qa_pattern_l2`. A test stops at its first failing golden, so the list can be longer. Whichever branch lands second must regenerate the tablet hint and unit goldens after the merge and look at them (the hand must still point at the tiles).

## Defects
| id | severity | owner | where |
|---|---|---|---|
| QA-B27-1 | minor | infrastructure-engineer (the tolerance in `app/test/support/golden_comparator.dart`), app-developer (regenerate) | `app/test/goldens/lesson_*_phone*.png` still show a mic |
| QA-B27-2 | major for the merge | infrastructure-engineer / orchestrator | after merging PR 16: regenerate the tablet hint goldens, resolve four unit goldens |

Known and not fixed by B-27: the portrait bubble over Nitzi's island (needs the owner); the `PageStorageKey` test and a smaller golden tolerance (QA, still open).
