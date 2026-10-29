# QA verification: B-23 (7 lands on the map) and B-24 (the mic only where speaking is the answer)

2026-10-29, qa-engineer. Worktree `D:\nitznutz-b23-b24`, branch `b23-b24-phone-map-mic` at `59c104f`, rebased on main with CI stages 1 and 2. Pack `starter-0.9.0`, app 0.5.0+5.

**Re-verified the same day after the QA-21 amendment.** NUM-B-16 (`b.numb16.1` to `.9`) is now false. Pack 0.9.0 was rebuilt in place with manifest sha256 `8bb34ac3…`, and is not published. The totals are now 258 true and 509 false.

**Verdict.** B-24 passes. B-23 passes, with the known notes listed below. QA-20 and QA-21 are closed. QA-19 stays open: it is older than these changes and has a failing test. Nothing in B-23 or B-24 blocks the merge.

## What ran

| Command (in `app/` unless said) | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed .` | 278 files, 0 changed, exit 0 |
| `flutter analyze` | No issues found |
| `flutter test` (whole suite, with QA's two new files), after the amendment | 1184 passed, 8 skipped (4 older open defects, 4 QA-19), 0 failed, 7 min 19 s |
| `flutter test` before the amendment | 1183 passed, 8 skipped, 0 failed |
| `flutter test test/playthrough_test.dart` | 6 passed |
| `NN_FLIP_SHARD=0/6 flutter test test/starter_pack_test.dart` | 19 passed: one sixth of every byte of 0.9.0 flipped and refused, version 0.9.0, install, CRC-repaired flips |
| `flutter test --dart-define=QA_OPEN=true test/qa_b23_b24_screens_test.dart --plain-name QA-19` | 4 failed (QA-19, as expected; re-run after the amendment) |
| `deno task check` (repo root) | NOT RUN: `deno` is not on this PC's PATH. B-23 and B-24 do not touch `supabase/`. |

Before QA's files were added, the whole suite gave 1143 passed, 4 skipped (the open defects in `qa_open_defects_test.dart`) and 0 failed.

## New QA tests (test code only)

- `app/test/qa_voice_answer_audit_test.dart` (5 tests): the checks run over all 767 activities.
  - The flag matches a rule this test works out from each activity's template, prompt and options. It never uses the activity id or the developer's tables. The result is 258 true and 509 false. The rule includes the amendment: a numeral answer is an echo when the prompt names the teen it is the first word of (answer + 10). Only the NUM-B-16 prompts meet that condition.
  - The flag is a real boolean in every activity, and is true only on tap_answer, count_tap or flash.
  - The real session the lesson builds (TapAnswerSession, CountTapSession or FlashSession) gives every option of each true activity words of its own. No two options share a word or a phonetic key, there is no yes or no word, and each label option answers to a word of its own label.
  - All 3010 spoken forms (each option's label, accept-words, number words and digits) were run through the real `AnswerMatcher`. Each one was heard as its own option: accept when it is the right answer, a check first when it is wrong.
  - The true activities whose answer is already in the prompt are pinned to the 6 that the curriculum-expert kept (QA-21).
- `app/test/qa_b23_b24_screens_test.dart` (39 tests: 35 run, the 4 of QA-19 skipped):
  - 138 kinds of question (template × skill × variant × flag) cover all 15 templates. Each was opened through the real `LessonScreen` with voice on: `lesson-mic` is drawn exactly when `voiceAnswer` is true, and the 12 hand-answered templates never prepare the mic.
  - With voice off, there is no mic on the spoken activities either.
  - At a system text scale of 1.3: on all 4 boards, all 7 signs are drawn and the 6 learning lands open. Four lessons without a mic (pick.red.flower, b.numb08.1, b.numb13.1, give.butterflies.4) draw with no overflow on phone and phoneSE.
  - On screens that are not one of the four boards (640×360, 568×320, 800×360, 960×412), the map is scaled, every land opens with a tap, and a drag that starts on a sign moves the map and opens nothing.
  - For a screen reader: every land's tap area is a button with the land's name, also when it is off screen, the map offers a scroll action, and Nitzi's island has no button.

## Criteria

**B-24**
- Exactly 258 true and 509 false (267 and 500 before the amendment). tap_answer 218/303, count_tap 28/0, flash 12/0, the other 12 templates 0/206. Per-skill counts as in the doc. Proven by the developer's test and, separately, by QA's rule test.
- Mic iff flag: QA mounted 138 kinds through the real screen (above).
- Accept-lists are not empty and are distinct, there are no yes or no options, and the matcher was run end to end (above).
- The doc and the developer differ about the 7 extra Band A overrides (`math.add.apples/fish/stars/ducks`, `math.take.apples/fish/stars`). The content confirms them: each asks "כמה עכשיו?" or "כמה נשארו?", has numeral options, and is the same question as the `madd` and `mtake` items that are true by default. The doc's own table (MATH-A-01 6, MATH-A-02 6) needs all 12. The doc's prose listed only 10 overrides: QA-20, now closed (the doc lists all 17).
- The 3-part rule:
  - Part 3 (distinct short options) holds for all 258.
  - Part 1 (a word the prompt does not say), read literally, failed for 15 arithmetic items (QA-21). The curriculum-expert turned off the 9 NUM-B-16 echoes and kept 6 sums, and the rule in the doc now says so.
  - No true activity is a "where is the number…?" or a "choose the numeral" question: NUM-A-07, NUM-A-08 and NUM-B-08 are all false.
- How strong the developer's tests are. QA made 7 product mutations, each restored with `git checkout`:

  | Mutation | Caught by |
  |---|---|
  | M1: drop `!activity.voiceAnswer` in `_mic` | voice_in_test (6 tests), QA screens test (13) |
  | M2: drop the `couldGoOn` guard | voice_answer_test (8) |
  | M3: let a two-word number's words count alone | answer_matcher_test (2), voice_answer_test (5), QA audit (1) |
  | M4: keep words that options share | voice_answer_rules_test (4); the pack no longer verifies |
  | M5: drop the yes/no validator rule | voice_answer_rules_test (2) |
  | M6: drop the map's `PageStorageKey` | **not caught**: see Open |
  | M7: `reverse: true` on the horizontal strip | board_geometry_test (6), home_map_test (2) |

**B-23**
- Every learning land opens by a real tap after `ensureVisible`, on all 4 boards: the developer's home_map_test (24 tests). QA repeated it at text scale 1.3 and on 4 non-board sizes.
- Nitzi's island has no tap area (owner's decision, board B-26).
- A drag that starts on a sign opens nothing. The fixed layer does not move. RTL is right: offset 0 is home, and the strip does not use `reverse` (mutation M7 is caught).
- The tap areas are at least 64 wide. The gaps are 40 on the phone and 26 on phoneSE, with the "+" 42.3 and 31.3 from the Nitzi sign.
- Each land has a semantic label (QA test).
- `home_tablet_landscape.png` is byte-identical (`git diff HEAD~1 --quiet`).

## PNGs looked at

- **Goldens:** home_phone, home_phone_end, home_phone_se, home_phone_se_end, home_tablet_portrait, home_tablet_portrait_top, companion_home_hero_phone (and its old version), companion_friends_phone and hall_friend_phone (neither shows the home), voice_mic_ready_phone and voice_mic_confirm_phone (and the old confirm), voice_mic_listening_tablet_portrait, voice_mic_confirm_tablet_portrait, voice_mic_ready_tablet_landscape (and its old version), voice_mic_tap_instead_tablet_landscape, unit_colour_banana_tablet_landscape (for comparison).
- **Design previews:** new_islands_2x_a, new_islands_2x_b, home_phone_strip, home_phoneSE_strip. QA did not open home_phone_start, home_phone_end, home_phoneSE_start, home_phoneSE_end, home_tabletPortrait_start, home_tabletPortrait_top or home_tabletPortrait_full; the goldens of the same views were reviewed instead.
- **QA renders at text scale 1.3:** home_phone and home_phoneSE.
- **Found:**
  - No overflow stripes and no text inside pictures.
  - The market clock has hands only and is drawn as art, so it cannot mirror.
  - The signs read RTL, the islands keep their aspect ratio, and the fonts are Heebo and Secular One.
  - The new mic goldens show the colour question; the old ones showed "where is the red flower?" with a mic, which was the B-24 defect itself.
- **Known (reported, not failed):**
  - On the phone, the Colour Bay sign is cut at the left edge at start (about 5 pt; on phoneSE about half, which is the designed peek).
  - On the tablet in landscape the tap areas are 0 apart (colors/shapes, logic/robots) and 20 apart (robots/market), as before B-23.
  - On the tablet in portrait, the bubble covers Nitzi's island.
  - On tablets the tile row overlaps the bottom of the card by about 10 pt. This was so before B-24 too (see unit_colour_banana).

## Defects and follow-ups

| id | severity | owner | what | proof | done when |
|---|---|---|---|---|---|
| QA-19 | major (accessibility; older than B-23) | design-director (the rule), app-developer | At a system text scale of 1.3, the daily pill on the phone board overflows: 9.8 pt on the right, the bottle icon is covered and the title is clipped. On all boards the child's card of the profile picker overflows 2 to 3 pt at the bottom (`profile_picker.dart:124`). Nothing overflows at 1.15. The board screens use fixed board sizes but do not clamp `textScaler`. | `qa_b23_b24_screens_test.dart` group "QA-19 (open)", run with `--dart-define=QA_OPEN=true` (4 fail) | the 4 tests pass and their `skip: _open` is removed |
| QA-20 | minor (doc), **closed** | curriculum-expert | `docs/knowledge/voice-answer-by-activity.md` names 10 Band A `pick` overrides; the content has 17 (the 7 math.add and math.take items above). The flags are right; only the text is wrong. | `qa_voice_answer_audit_test.dart` rule test (passes on the content) | Closed: the doc lists all 17 with the rule (its section "Where the flag lives"). |
| QA-21 | decision, **closed** | curriculum-expert | 15 true activities had their number answer already in the prompt. The decision (amendment QA-21): `b.numb16.1`–`.9` are an echo and are now false; `b.mathb07.1/.2/.3/.6`, `b.mathb06.1` and `b.numb02.6` are sums and stay true. | `qa_voice_answer_audit_test.dart`: the rule gives false for NUM-B-16, the counts are 258 and 509, and the reviewed list holds the 6 | Closed: all pass in the full suite after the amendment. |

## Not checked

- The real phone: the owner's Samsung (strip panning by finger, inertia, the mic look on the device, ASR on a child's speech).
- Sound, and a child's hands.
- `deno task check` (deno is not installed here).
- `NN_EXHAUSTIVE=1` (the full every-byte test; one CI shard was run instead).
- iOS.

## Open

- **M6:** home_map_test's "coming back from a land, the map is where the child left it" also passes without the `PageStorageKey`. The home route stays mounted under the land, so the test proves the behaviour but not the key. Today's behaviour is right; if the home is ever rebuilt (for example a profile switch), nothing would catch losing the position.
- `board_geometry_test`'s `fixedRects` leaves out the stickers and trophies row (its `pumpHome` has no `onStickers`). The app-level tests do show the row in place.
- The 3% golden tolerance hid a stale `companion_home_hero_phone.png`: the old golden had no labelled stickers and trophies row, which came with M8. Consider a smaller tolerance for the home goldens (infrastructure-engineer, with QA).
