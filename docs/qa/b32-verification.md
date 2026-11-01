# QA verification: B-32 (one safeChildName, the sync guard, the parent-list row)

2026-11-01, qa-engineer. Worktree `D:\nitznutz-b32`, branch `b32-name-safety`, uncommitted, on `origin/main`. Follow-up of `docs/qa/b28-verification.md` (QA-B28-1, -2, -3).

**Verdict: PASS, with three minor findings (QA-B32-1 to -3); none blocks the merge.**

## What ran

| Command (in `app/`) | Result |
|---|---|
| `flutter analyze --no-pub` | No issues found |
| `dart format --output=none --set-exit-if-changed .` | 358 files, 0 changed |
| `flutter test child_name_safety child_name qa_b28 sync_engine` | 92 passed, 0 failed |
| `flutter test sync_wiring revisit_mission_sync alerts alerts_flow reward_service qa_alert_tiers` and the home-island and source-rule files | 406 passed, 0 failed (includes the 3 home-island goldens; none changed) |
| Throwaway probe test (names below) and 4 throwaway renders of the parent list | passed; files deleted afterwards |

Not run: the whole `flutter test` (the developer's 2,994 was not re-run), any `deno` test (`deno` is not installed here, so `child_name_vectors_test.ts` was not run against the new vectors), the real phone.

## Criteria

1. **One `safeChildName`: pass.** `child_form.dart:50` (`validateChildName`), `fitChildNameForServer` (`child_name.dart:72`), `_pull` (`sync_engine.dart:645`) and `homeIslandName` (`home_island_name.dart:135`) all call it. The probe confirmed these pass: ז'אן, ז׳אן (U+05F3), בת-אל, בת־אל (maqaf), צ״ל, ג'ורג', יִצְחָק, a shin with dagesh, dot and vowel, בִּנְיָמִין, כֹּהֵן. These are refused: U+061C, U+200B/C/D, U+00AD, U+2063, U+180E, U+FFF9, tag characters, lone surrogates (both halves), U+2800, U+3164, a lone U+034F or U+FE0F, marks only, a 4-mark stack, and four marks with a zero-width space between them (no bypass). Tab and new line are refused in the form (Cc) and become a space on the island.
2. **Sync guard: pass.** `unsyncedAttempts/Sessions/Rewards/Alerts(except:)`, `_childrenNotOnServer` (`sync_engine.dart:268`). Tests cover a failed `child-put` over two rounds (nothing sent, `failing` set works), then all four kinds go after the first good one; the child is saved in the same round before `sync-push`; an unsendable child stays held while another goes and a gate alert (no child) is not held; a non-parent device holds nothing. A pulled child gets its `profile_pushed_` key (`sync_engine.dart:669`), so a second parent phone does not hold its rows.
3. **QA-B28-1, -2: pass.** `skip` and `_open` are gone; the tests run and pass. QA-B28-3 also runs and passes.
4. **QA-B28-3: pass for real names, with a note.** PNGs (360 by 740): `docs/qa/b32-parent-list-legacy-1.0.png`, `-1.3.png`, `-40letters-1.3.png`. The legacy line is on its own full-width row under the buttons, two lines at 1.0 and 1.3, no cut word. A 34-unit name with spaces wraps at word boundaries, no word cut. Only an unbroken 40-letter name (the extreme legacy case) is cut inside the word: 3 lines of 4 to 5 letters at 1.0, 5 lines of 3 letters at 1.3. Acceptable; see QA-B32-2.
5. **Messages: pass, no new strings.** `He.setupNameBadChars` is the same text as in B-28 and is already `needs-editor` (`docs/review/hebrew-review.md:190`). It is calm and in Hebrew.

## Findings

- **QA-B32-1 (minor, hebrew-text-editor).** `child_form.dart:58`: `setupNameBadChars` says only "no < or > and no invisible characters", but the form now also refuses a pile of 4 or more nikud marks, which the message does not explain. Proposed: add "ובלי יותר משלוש נקודות על אות".
- **QA-B32-2 (minor, design-director).** `parent_area.dart:273`: the name still shares its row with two buttons, so a name without spaces over about 9 letters wraps in a 65 to 86 pt column, mid-word at scale 1.3. Only pre-B-28 names (25 to 40 units) or a 24-letter single word. Fix by putting the buttons under a long name, if wanted.
- **QA-B32-3 (minor, security-engineer / app-developer, accepted risk).** `sync_engine.dart:273`: a parent-device child whose `child-put` never succeeds keeps its rows unsent without limit (no cap or age). Private-use characters (U+E000) pass `safeChildName`. Both are theoretical.
