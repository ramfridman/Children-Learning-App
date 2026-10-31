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
