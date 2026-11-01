# B-38 verification (PR 26, branch `b38-pictures`, commit b5ad5f0)

Date 2026-11-01. QA engineer. Nothing committed; temporary render tests were written, run and deleted.

## What ran
- `flutter analyze`: no issues. `dart format --set-exit-if-changed` on `sprite_group.dart` and `sprite_group_test.dart`: 0 changed.
- `flutter test` on sprite_group, hint_tap_b_golden, hint_tap_golden, hint_tap_band_b, hint_tap_families, hint_pointer, golden_screens: 129 passed, 0 failed. (The full suite of 3,004 was green before the commit; not re-run.)
- `python -I -X utf8 tools/test_hebrew_sources.py`: 10 tests OK, exit 0. `python -I -X utf8 tools/test_generators.py`: 28 tests OK, exit 0.
- CI: a probe unittest that fails exits 1 under `python -I -X utf8`. `ci.yml` has no `continue-on-error`, no `|| true`, no custom `shell:`; so a failing test fails the step and the job. Confirmed by reading and by the probe, not by a run on GitHub.

## 1. Ten-frame
Content that uses it (starter and units): 4 `b.mathb06.*` (counts 5, 8, 9, 3), 7 `b.numb16.*` (a full frame of 10 beside a frame of 1 to 9, `group` + `group2`), 4 `flash.frame.*` (3, 4, 5, 5), 2 `more.spread.*` (a `ten_frame` option tile), 6 `flash.dice.*` (counts 1 to 5, so no frame). No content has a dice over 6, a ten-frame over 10, or a single group over 10.

PNGs reviewed (all in the scratchpad `shots/`): numb16.9 on phone, SE, both tablets (base) and hint levels 1, 2, 3 on SE, tablet landscape, tablet portrait; mathb06.5 SE base; more.spread.fish phone, more.spread.stars tablet landscape; flash.frame.3 SE, .4 tablet landscape, .5 phone, .5b tablet portrait; sheets of counts 1 to 20 (ten_frame and dice) at the phone box. Goldens read: `hint_tapb_to_ten_l1..l3_phone`, `hint_tapb_add_more_l1..l3_phone`.

Passed:
- The frame and every picture stay inside the group box at counts 1 to 20, in seven box sizes (phone, SE, tablet pair or single, an option tile). Each picture sits in its own cell, the top row first from the left.
- Two frames (10 and n) stand left to right, never mirrored (`tap-groups` is LTR).
- The B-40 hint pictures (their own ten-frames at levels 2 and 3) cover the base frame with their backdrop. No leak and no overlap. The level 1 glow rings sit on the base cells.
- Ten-frame for numb16 and mathb06 is the intended picture of the skill. Flash frames are better with the board (a full top row reads as five). A dice over 6 as a ten-frame is sensible for subitising, but no content uses it; **curriculum check**: forbid dice over 6 in the schema or keep it as a fallback.

## Defects
| id | sev | where | owner |
|---|---|---|---|
| QA-38-1 | major (curriculum decision) | `content/starter/activity.more.spread.fish.json` and `.stars.json`, option o2 (`ten_frame`); drawn by `app/lib/play/sprite_group.dart:180-185` | curriculum-expert |
| QA-38-2 | minor, latent | `sprite_group.dart:131`; schema `activity.tap_answer.schema.json:217-221` allows counts to 20 | app-developer, with curriculum-expert |
| QA-38-3 | minor, latent | `sprite_group.dart:96` (`side = cell * 0.78 * scale`) | app-developer |
| QA-38-4 | minor | `.github/workflows/ci.yml:34` | infrastructure-engineer |

- QA-38-1: the correct answer in both "where are more" items is always the only option on a framed board (the other, the spread one, has no board). A child can now pick by "the one with the box". The spread cue (NUM-A-12, M-CNT-SIZE) is weakened. Fix: draw no board for an option tile, or give both options the board.
- QA-38-2: a single group of 11 to 20 is one tall frame of 3 to 4 rows, not two frames; the cell is 16 px (picture 12.5 px) on SE for 16 to 20. Never shown today. Fix: two frames side by side (second one LTR) or limit the schema to 10.
- QA-38-3: `scale` up to 1.6 (schema) makes a picture larger than its cell (1.25 cells) and overlaps the lines. All content uses scale 1.
- QA-38-4: the job is still named "forbidden files" but now runs the Hebrew and generator tests; rename so a red check says what failed. The two python runs also leave `tools/__pycache__` (untracked), harmless on CI.

Not checked: a real phone, sound, a child's hands, a GitHub run of the new CI steps.
