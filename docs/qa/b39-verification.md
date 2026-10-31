# B-39 Today's Adventure: QA verification (qa-engineer, 2026-10-31)

Scope: rule `docs/curriculum/todays-adventure-rule.md` sections 0, 10, 11, 13 against `world/todays_adventure.dart`, `lesson_path.dart`, `adventure_adapter.dart`, `_openTodaysAdventure` in `app/lib/app/app.dart`.

## Ran
- `flutter test` on the three B-39 files: 61 passed, 0 failed (57 from the developer plus 4 added by QA). `flutter analyze`: no issues. `dart format --set-exit-if-changed`: 0 changed. Whole suite not rerun (developer: 2630 green).
- `git diff --stat origin/main`: only `app.dart`, `next_lesson.dart`, `placement.dart`, `docs/PLAN.md` changed, plus 3 new lib files and 3 test files. Pack, `supabase/`, sync, gateway, `network_hosts.json`, lock files untouched.

## Rules (read rule, then code)
1. One stop, nothing changes unless tapped: code and flow test (db counts unchanged). 2/3 revisit once a day, then 2 lessons: `revisitAllowed`, rows 8, 10-12, 26. 4/5 run of 3, then lowest level, recency, map order: rows 5-7, 25, 40-step chain test. 6 rest after a stumble and reviewed-today: rows 13-16, 20, 24, plus QA random property. 7 brand-new: rows 1-3, QA band B warm-up flow test. 8 replay: rows 18, 19. 9 pure: source test (no clock, no Random, only award and lesson_path imports), shuffle test. 10 params table: row 28 (no stage parameter, declared).
- Pebble and bottle share `nextOnPath`; `_playLand` recomputes, so they cannot disagree. Revisits use `engine.dueChecks`, the map bells' own list.
- Child safety: no timer, streak or guilt words in the new files; no Hebrew added.
- Edge: empty pack gives `none` (row 27; app returns without opening anything); a land with no lesson is not open (no per-land lock exists).

## Added by QA
UTC day-turn test (adapter); random "resting lesson only as last resort" property; band B warm-up first from the bottle; quick double touch opens one lesson.

## Defects
None blocking. See report for the two minor, pre-existing notes (placementDue; UTC day turn).

---

## Addendum: the bottle's five lines and the per-land warm-up (commit b998180; qa-engineer, 2026-10-31)

### Ran (worktree `D:\nitznutz-b39`)
- `flutter analyze`: no issues. `dart format --set-exit-if-changed .`: 0 changed (318 files).
- `flutter test` on `adventure_line_test`, `placement_test`, `source_rules_m1_test`, `todays_adventure_flow_test` and the new `qa_b39_adventure_line_test`: 39 passed, 0 failed, 1 skipped (the open QA test). With `--dart-define=QA_OPEN=true` the QA test fails as intended (QA-B39-1). The whole suite was not rerun (the developer reports it green).

### `{land}` cannot carry personal data: pass
- It is filled in one file (`child/adventure_line.dart`), with `landName(land).text` and `landSemanticsName(land).text`; `land` is a `TrophyLand` enum taken from the stop, never a string from the child, the pack or a server.
- `source_rules_m1_test.dart` pins (1) the set of placeholders, `child` staying the only personal one, (2) every `'land':` fill in `lib/` (exactly those two), (3) the six arms of each name function are `He.land*` constants. A fill written with double quotes or a `replaceAll('{land}', ...)` would escape (2); (1) would still list any new placeholder name, and the grep covers all of `lib/`. Accepted.
- The voice id `vo:core.adventure.<reason>.<land>` carries only the reason and the land; `tools/hebrew_voice_review.py` voices each line once per land name, so the child's name never reaches a vendor through it.

### Per-land warm-up (`world/placement.dart`): pass
- A warm-up answer counts for a land only when its activity is in that land's warm-up and in no other land's. The shared first activity of Counting Hills and Colour Bay counts for neither: a child who left right after it sees the warm-up again (harmless: it never blocks and ends gently).
- Tests: the Counting Hills warm-up played leaves Colour Bay and the four other lands due; the Colour Bay one played uses up only its own; flow: a band B child sent on to Colour Bay gets Colour Bay's warm-up (its `itemIds`, not Counting Hills'); a band A child gets none in any land (`ageBand >= 1` in `_playLand`).
- Not covered: a pack update that changes the warm-up's activity ids makes the old answers stop counting (the warm-up is offered once more). Minor, no test.

### Can the child see or hear the line? No: QA-B39-1 (major)
- `_openTodaysAdventure` (`app/lib/app/app.dart:327-336`) sets the line and calls `_openStop` in the same continuation, with no await between. Measured by `app/test/qa_b39_adventure_line_test.dart`: the line is in the bubble in one frame and the lesson page is pushed the next, 16 ms later. On a phone the lesson then fades in over it for 300 ms or more (not measured on the real phone). A child of 3 to 8 who cannot read pointed Hebrew cannot take it in, and the line is cleared when the child comes back.
- Sound: no clip `vo:core.adventure.*` is in any pack (the line is silent), and a clip would be cut at once by the lesson's own question (`lesson_screen.dart:312`, `_director.say`, which replaces the playing line).
- The flow tests read the bubble with `skipOffstage: false`, while the lesson is on top, so they pass although the child never sees it. They prove the text is chosen, not that it is shown.
- A better way: hold the stop back for the line. With a clip, wait until it ends (capped at about 4 s); without one, keep the bubble up for about 2 s with the friend and the bottle still (no countdown, no bar). Or: the bottle's tap shows the line and a glowing "go", and a second tap (the bubble or the bottle) opens the stop. Or hand the line to the lesson as its first caption and voice. Whichever is chosen, remove `skip: _open` from the QA test.

### `none`: covered by the unit test only (QA-B39-2, minor)
- At the app level `none` happens only when the pack has no lesson in any land (an empty or damaged pack). The bottle then does nothing: no sound, no movement, a dead tap. No flow test (the harness has no pack override). Suggest a flow test with an empty pack and a small response (the friend waves).
- The `line` notifier (`app.dart:276`) is never disposed. Minor.

### Defects
| id | severity | owner | where |
|---|---|---|---|
| QA-B39-1 | major | app-developer (voice-and-sound-director for the clips) | `app/lib/app/app.dart:327-336`; failing test `app/test/qa_b39_adventure_line_test.dart` (run with `QA_OPEN=true`) |
| QA-B39-2 | minor | app-developer | `app/lib/app/app.dart:276, 338-348` |
