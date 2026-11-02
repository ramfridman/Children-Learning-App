# QA verification: B-45, the map-card line is voiced

2026-11-02, qa-engineer. Worktree `D:\nitznutz-childline`, branch `b45-childline-play` at 1fea824 (6c86adb the feature, b45-voicing-plan 2e4384b merged in). Feature: a tap on a land-map picture (`land_screen.dart`) or on an earned star's line in the Trophy Hall (`trophy_hall.dart`) says `vo:core.skill.<id>` (`skillLineVoiceId`) through the VoiceDirector; the `skill` part pack (100 lines) is prefetched when the screen opens.

**Verdict: PASS. No blocker, no major. Three minor findings (QA-B45-CL-1 to -3), . One thing only the Samsung can confirm: real sound (below).**

## What ran

| Command | Result |
|---|---|
| `flutter analyze` (app) | No issues found (after my tests were added) |
| `dart format --output=none --set-exit-if-changed .` | 385 files, 0 changed |
| `flutter test` (whole suite, once, alone, at 1fea824 before my files) | 3,223 passed, 4 skipped, 1 failed: only the known `starter_pack_test` "the pack was built from the sources in content/starter and nothing else" |
| The developer's `skill_line_voice_test`, `childline_voice_test`, `world_screens_test` and my 4 files, run again after my additions | 74 passed, 0 failed |
| `python tools/test_hebrew_sources.py` | 15 tests OK |
| `dart run tool/voice_gen.dart plan nitzi` (free) | 18 packs, 4,166 lines; `voice-nitzi-part-skill` 100 lines, about 5.9 MiB, 202 files; each friend 57 lines |
| An independent Python check (not the developer's) | 100 `core.skill.*` lines in `content/lines/core.he.json`; each equals its skill's `childLine` in `content/starter/skill.*.json`; no stray line; no skill without one |

Not run: `deno task check` (nothing under `supabase/` changed), anything that touches ElevenLabs or its key. No real clip exists yet, so every sound in the tests is a mock made through the real pack builder with a throw-away key.

## New tests (mine, untracked or modified, in `app/test/`)

- `qa_b45_childline_layout_test.dart` (25 tests): the real 100 childLines of the bundled starter pack, on the four boards (phone 852x393, phoneSE 667x375, tablet landscape 1180x820, tablet portrait 820x1180), text scale 1.0 and 1.3. Land card: every land, its longest line, no overflow, card on screen, card covers no back button, play button or legend. Hall: three longest and three shortest star lines, the card scrolls, each line is reachable by scrolling and tappable, the replay button is reachable. Writes PNGs only with `QA_B45_SHOTS=1`.
- `qa_b45_voice_packs_end_to_end_test.dart` (+5 tests, through the real installer): all 100 ids are in `voice-nitzi-part-skill` and that pack holds only them; not resident until the prefetch, then heard at once, replace and stop work; each of the 100 plays its own sound; a friend says a card line in the narrator's voice and its director prefetches the narrator's skill pack; a damaged skill pack is silence for all 100 lines, no error, shared lines still play.
- `qa_b45_only_child_space_speaks_test.dart` (1 test, source rule): only the nine child-space / lesson / shell files reach the voice director or player. Nothing in `lib/parent`, `auth`, `device`, `sync`, `net`, `security`, `push`, `tutor` or `ui/dev` does.

Mutation checks (restored after; `git status -- lib` is clean): removing `stopFor(this)` in `LandScreen.dispose` fails the developer's "leaving the island stops the line"; replacing the hall card's `SingleChildScrollView` with a `Padding` fails 16 of my hall tests ("overflowed by 82 pixels" at phone 1.0 is the developer's figure; 100 to 252 pixels at the other sizes and text 1.3).

## Acceptance points

| Point | Proof |
|---|---|
| Tap on a land picture says the line, caption on the card | `childline_voice_test`, my layout test |
| Another tap replaces, never two together; second tap on the same stops (land: card closes) | `childline_voice_test` (land and hall) |
| Leaving stops; choosing another trophy, tab or the replay stops it | `childline_voice_test`, mutation above |
| A missing clip is silent, shows its card, stops the one before, no error | `childline_voice_test` |
| Prefetch of the `skill` pack when the screen opens, once; hall only with an earned star | `childline_voice_test`, real installer test |
| Hall card scrolls (no overflow 82 px at 852x393); last star line and replay reachable; large text 1.3 | my hall tests on all four boards, scroll extents 82 to 252 pt on phones, 0 on tablets |
| No overflow, card text not covered, on four boards at 1.0 and 1.3 | my land tests; card covers no control at 1.0 on any board; PNGs below |
| 100 lines equal their `childLine` | Dart `skill_line_voice_test`, Python `test_hebrew_sources`, my independent script |
| A friend (any of nine) says it in the narrator's voice | my end-to-end test |
| No screen outside the child space speaks | my source-rule test |
| No child audio, no mic, no timer, no streak | The change touches no mic, recorder, network or timer code (diff of `app/lib`: land_screen, trophy_hall, voice_lines only) |

## PNGs looked at (`docs/qa/`)

`b45-childline-land-phone-1.0-counting`, `-land-phoneSE-1.3-counting`, `-land-tabletP-1.3-logic`, `-hall-phone-1.3-top`, `-hall-phone-1.3-bottom`, `-hall-phoneSE-1.3-top`, `-hall-phoneSE-1.3-bottom`, `-hall-phone-1.3-short-top`, `-hall-tabletL-1.3-top`, `-hall-tabletP-1.3-short-top`; the other PNGs the test made (38) I checked by the numbers it prints, and removed. Nikud is not cut, the one-line card fits on every board at 1.0, the hall card scrolls and its replay button is reachable. No overflow stripe, no stretched picture.

## Defects (hand-offs)

All three are minor; none blocks this feature. QA-B45-CL-1 and -3 exist on `main` too (large text only); QA-B45-CL-2 is in the feature's own new row.

- **QA-B45-CL-1 (minor, design-director).** `app/lib/child/land_screen.dart:217` card at `top: 70`, `:245` title pill at `top: 12`. At text scale 1.3 the card is 89 pt tall, reaches 7 pt into the land-title pill (PNG `land-phoneSE-1.3-counting`) and, on phones, hides the top row of pictures (up to 14 on phoneSE, counting land; card bottom 159, picture room starts at 146). Repro: `QA_B45_SHOTS=1 flutter test test/qa_b45_childline_layout_test.dart`, notes printed per land. Test: the 1.3 title check is soft in my test (`QA-B45-CL-1` comment); make it hard when fixed. Expected: card clear of the title and the picture room (design-spec section 7).
- **QA-B45-CL-2 (minor, design-director).** `app/lib/child/trophy_hall.dart:507-525` the star-line tap row is `Padding(top 6, bottom 6)` around one 16 pt line: 39 pt high at 1.0 and 47 pt at 1.3 when the line is one line (LOG-B-08, LOG-B-09, LOG-A-02: 9 to 21 characters), below the 56 pt child-control floor (design-spec 6.1). Two-line rows are 66 pt or more. Also no visible sign that the line is tappable (a gold star only). Repro: my "shortest lines" hall tests print the rows. Fix: a minimum row height of 56 pt (a `ConstrainedBox`) and, if the design director agrees, a small speaker mark.
- **QA-B45-CL-3 (minor, design-director, large text only).** Trophy Hall shelf label of the first shelf ("גִּבְעוֹת הַסְּפִירָה" and its 28/28 chip) is cut at the top at text 1.3 on phone and phoneSE (PNGs `hall-phone-1.3-bottom`, `hall-phoneSE-1.3-top`); the label column is taller than the row. Not in this change.

## Only the Samsung can confirm

1. Real sound: that a tap on a picture and on a hall star line is audible, in the companion's voice and in the narrator's when the companion is a friend (no real clip exists yet; the owner's paid run of the 100 lines, about 2,306 characters, comes first).
2. Latency of the first tap after the `skill` pack (about 6 MiB) is read from disk, and that a quick second tap or leaving the island mid-line is clean on the real player.
3. That a child discovers the star line in the hall is tappable (QA-B45-CL-2).
4. Text scale 1.3 on the device's own font setting (QA-B45-CL-1, -3).

## Re-verification after the design-director's fix (60cd404), 2026-11-02

Ran: `flutter analyze` clean, format 385 files 0 changed, my layout test and `childline_voice_test` and the source rule (44 passed, with the tightened checks), full `flutter test` 3,260 passed, 4 skipped, 1 failed (only the known `starter_pack_test`). Ten PNGs in `docs/qa/` regenerated from the fixed build and opened.

- **QA-B45-CL-1: CLOSED.** The card sits between the title and the pictures at every board and both text scales: bottom at 142 pt (1.0) or 137 pt (1.3, one row), no picture under it, no control covered.
- **QA-B45-CL-2: CLOSED.** No hall star row is under 56 pt (64 pt rows, shortest lines included), at all four boards and both scales; every row is scrollable into reach and tapped.
- **QA-B45-CL-3: CLOSED.** The shelf-name cut was my test's scroll; the new test checks the name whole when the hall opens, on all boards at 1.3.
- **QA-B45-CL-4 (new, minor, design-director, large text only).** `trophy_hall.dart:140` the hall title "היכל הגביעים" ends 4 pt from the "גביעים" tab pill at text 1.3 on phoneSE 667x375 (title left 357.7, pill right 353.6). Fine at 1.0 (gap 103 pt) and on the 852x393 phone at 1.3 (189 pt). Older than this feature. Measured with a throw-away test (not kept).
