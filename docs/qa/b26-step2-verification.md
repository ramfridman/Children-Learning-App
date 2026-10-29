# QA verification: B-26 step 2 (the home sign on the map, the pill, the bubble)

2026-10-29, qa-engineer. Worktree `D:\nitznutz-b26`, branch `b26-nitzi-home`, step 2 uncommitted on top of `c379858`.
Plan: `docs/milestones/B26.md` (decisions 1, 2, 5); design: `docs/design/nitzi-home.md` sections 2 to 4; step 1 record:
`docs/qa/b26-step1-verification.md`. Read beside the design-director's render review `docs/design/b26-step2-review.md`
(written in parallel; its points 3 and 4 agree with QA-25, QA-26 and QA-27 below).

**Re-verification (same day, after the follow-up for QA-25/26/27 and the design review): see the last section.
B-26 step 2 may be committed.** QA-25, QA-26 and QA-27 are closed; one new minor (QA-29, open, skipped test) and QA-28
stay as follow-ups.

**Verdict (first pass).** The code of step 2 passes: the fit, the placement, the taps, the semantics and the bubble that only speaks
all hold on four boards at text scale 1.0, 1.15, 1.3 and 2.0 with 21 QA names. Before the commit, one golden must be
regenerated correctly (QA-27, the hero map golden lost its character). Two layout defects from the longer bubble line
on the tablets (QA-25, QA-26) go to the design-director's fix A/B. No blocker.

## What ran

| Command (in `app/` unless said) | Result |
|---|---|
| `flutter analyze` | No issues found |
| `dart format --output=none --set-exit-if-changed .` | 0 changed, exit 0 (282 files; 283 with QA's file) |
| `flutter test` (whole suite, as delivered) | **1330 passed, 8 skipped, 0 failed** (7 min 48 s). 1330 = 1247 (step 1 record) + 82 (`home_sign_test.dart`) + 1 (QA-22 no longer skipped; 9 skipped became 8) |
| `flutter test test/qa_b26_home_sign_test.dart` (QA's new file) | 354 passed, 2 skipped (QA-25, QA-26) |
| the same with `--dart-define=QA_OPEN=true`, the two open tests | both fail as expected (QA-25: bubble left 718.0 < 755; QA-26: gap 0.0 < 12) |
| `flutter analyze`, format, `flutter test` (whole suite, with QA's file; run last) | No issues; 283 files, 0 changed; **1684 passed, 10 skipped, 0 failed** (7 min 34 s) = 1330 + 354, skipped 8 + 2 |
| `python tools/export-hebrew-review.py`, then `python tools/hebrew_voice_review.py` (repo root) | 9,522 rows; master text-ready 9,456, proposed 43, unchanged 23. All five tables differ from HEAD in exactly one line, the `homeBubble` row, and the regenerated content equals the delivered content (same one-line diff before and after). The three CSVs are written with CRLF by the tools; `.gitattributes` (`eol=lf`) normalises them on commit, so nothing to restore |
| `flutter test --update-goldens test/companion_everywhere_test.dart --plain-name "pictures with a family character the map"` x3, and once for the whole file | QA-27 evidence; the delivered golden put back byte for byte, `companion_lesson_hero_phone.png` restored with `git checkout` |
| 5 product mutations of `home_screen.dart` (copy, mutate, run, restore, SHA-256 checked) | all caught (below) |

## Checks

1. **Texts.** `homeBubble` is the editor's line code point for code point (`docs/agents/hebrew-notes.md`), NFC, pointed,
   `nikud: true`; the master row is `proposed` with the editor's comment. Only that line of `he.dart` changed.
2. **Goldens, looked at** (each new PNG beside `git show HEAD:...`, pixel-diffed by region, crops at 2x and 3x):
   - `home_phone`, `home_phone_se`, `home_tablet_portrait`: differ only in the pill (no dots, text on the centre line)
     and the bubble line. `home_phone_end`, `home_phone_se_end`, `home_tablet_portrait_top`: only the pill.
   - `home_tablet_landscape`: the pill, the bubble, **and the Hall and sticker pebbles** (x 1028..1155, y 114..194).
     HEAD's file dates from 2026-10-27, before the Hall pebble (M8, 10-28): it was stale and passed under the 3 %
     tolerance. The new one is the true map. Not a step-2 change.
   - `companion_home_hero_phone`: pill, bubble, and the family character's picture (the dark red test square at
     654..717, 199..262) is gone: QA-27.
   - The 6 new `home_sign_*`: noa whole at 18 (centred), alexandra whole (18 phone, 17 SE, held at the box's right
     edge), avigail_alexandra `הָאִי שֶׁל אביגיל…` with the `…` at the left end (RTL), on the baseline. Nikud of the frame
     words whole; nothing clipped; clear of the "+" (24 to 40) and of the Counting sign (69 to 131). The SE "+" disc
     runs past the right edge (known, B-27).
   - Tablet landscape: the bubble (718..1006, 516..565) hides the two smallest Counting stairs (they end at 747): QA-25.
     Tablet portrait: the bubble (333..621, 955..1004) and the Counting sign (181..339, 996..1033) overlap by 6 x 8 as
     rectangles; on screen the rounded corners nearly touch: QA-26. At HEAD the bubble started at 790 / 405.
3. **Breaking the fit** (`app/test/qa_b26_home_sign_test.dart`, 336 cases: 4 boards x scales 1.0, 1.15, 1.3, 2.0 x 21
   names: geresh `ג'ורג'ינה`, curly gereshes in a 3-part name, hyphen, 3 parts with maqaf, Latin with accents and a
   hyphen, 20 x W, 1 letter, 2 letters, `Jo`, 6 / 9 / 12 / 40 x ש, nikud `נֹעָה` and a pointed double name, Latin plus
   Hebrew, spaces with RLM and LRE/PDF, `2018`, emoji, blank, empty). For every case: no exception other than a flex
   overflow, and **no overflowing flex except the daily pill (QA-19, open; phone at 1.3 and 2.0, 42 cases)**; the sign
   inside its box; the text drawn inside the sign; the size one of 18/17/16/15; the fallback only when the name has no
   letter; a shortened name is a start of the name, ends with `…`, never ends on a separator and never leaves a letter
   without its geresh; a shortened line is the longest form that fits at 15 (measured with QA's own painter), a whole
   line is at the largest size that fits; 12 clear of the "+" tap area; 24 clear of the Counting sign (at 2.0 only
   "not touching": there the Counting sign itself grows, gap 7.4 on the SE for every name, including the fallback;
   QA-19 territory); the screen reader gets the whole name on the sign and the tap area, never a `…`.
   At 2.0 the last guard (scale down) acts on 24 cases (phone 9, SE 15); the sign stays in its box and the text inside
   it; the sign's bottom stays on screen (phone 376 of 393).
4. **`onOpenHome` null** (four boards): no `land-tap-nitzi`, the sign says `הָאִי שֶׁל נִיצִי` at 18, the pill has no
   button flag and no tap action, taps on the pill and the sign do nothing. With **every** land listed as openable
   (Nitzi included), the home island never reaches `onOpenLand` (so `TrophyLand.values.byName` can never get `nitzi`),
   with and without `onOpenHome`. `app.dart` (`_openableLands`, `_openLand`) is unchanged and passes neither
   `homeIsland` nor `onOpenHome` yet (step 3).
5. **Taps.** On four boards the companion and the "+" keep their own taps over the home tap area, the sign opens home.
   A drag that starts on the sign (both directions), and on the pill, opens nothing on any board; on the phone it moves
   the map (offset > 100).
6. **The bubble only speaks** (the real app, `AppRig`, four boards): a hit test at its centre and both ends finds no
   render object of the bubble; it sits under an `IgnorePointer(ignoring: true)`; its words are still in the semantics
   tree (`find.bySemanticsLabel` finds them once). Its look is unchanged apart from the words (goldens).
7. **How strong the tests are** (mutations of `home_screen.dart`): bubble `IgnorePointer(ignoring: false)`; pill
   `button: true` always; no shortening in `fitHomeSign`; no clamp in the placement; Nitzi routed through
   `openableLands` again (the `land == Land.nitzi` line removed): each is caught. The first, second and fifth were run
   against the developer's `home_sign_test.dart` alone and it catches them; the third and fourth were run against both
   files together (dozens of failing tests each; not split by file).
8. **Nothing outside step 2.** Changed: `home_island_name.dart`, `home_screen.dart`, `he.dart` (one line), 8 goldens,
   2 test files, `PLAN.md` line 459, the 5 review tables; new: `home_sign_test.dart`, 6 goldens. No pack, sync, gateway,
   `supabase/`, `pubspec.*`, lock file, `.github`, `app.dart` or other screen. The Hall, sticker and book buttons are
   unchanged (the diff does not touch their block). Also in the worktree, from other agents during this check:
   `docs/milestones/B26.md` (a note), `docs/design/b26-step2-review.md`, `docs/milestones/B29.md`, `docs/research/`.
9. **`PLAN.md` line 459** matches the code (boxes, sizes, shortening, placement, semantics, `onOpenHome` null,
   no dots, the bubble). The QA-22 fix (`_firstLetters` steps back over every geresh, then one letter; `‘` and `` ` ``
   added as gereshes) passes QA's step-1 test, now unskipped.

## Defects

| id | severity | owner | what | proof | done when |
|---|---|---|---|---|---|
| QA-25 | major (look) | design-director (fix A with the hebrew-text-editor, fix B with the app-developer) | Tablet landscape: the longer bubble line covers the two smallest Counting Hills stairs (bubble left 718; stairs end 747; was 790). | `qa_b26_home_sign_test.dart` "QA-25 (open)", `--dart-define=QA_OPEN=true`: 718.0 < 755; `home_tablet_landscape.png` | the test passes unskipped; goldens regenerated |
| QA-26 | minor (look) | design-director (same fix) | Tablet portrait: the bubble and the Counting Hills sign overlap as rectangles (6 x 8); the rounded corners nearly touch (was 68 apart). | "QA-26 (open)": gap 0.0 < 12; `home_tablet_portrait.png` | the test passes unskipped |
| QA-27 | minor (test evidence), **fix before the commit** | app-developer | `companion_home_hero_phone.png` was regenerated with the test run alone; then the family character's picture is not drawn (in the whole file it is: the order decides when the image is ready). The delivered golden shows the map **without** the character the test is named for, and passes only because 4,096 px are 1.2 % (< 3 %). | Three isolated runs: no square; whole-file run: the square at 654..717, 199..262. Copies in the QA scratchpad | regenerate with `flutter test --update-goldens test/companion_everywhere_test.dart`, restore `companion_lesson_hero_phone.png` with `git checkout`, and check that the new PNG differs from HEAD only in the pill and the bubble |
| QA-28 | minor (test honesty) | qa-engineer (follow-up; infrastructure-engineer for the comparator) | The 3 % golden tolerance hides whole elements: `home_tablet_landscape.png` missed the M8 pebbles for a milestone, and QA-27's missing character passes either way; the hero test depends on test order. | this record | the hero test waits for its image (deterministic alone and in the file), and the map goldens use a tighter tolerance or a per-region check |

Not defects, for the record: the pill padding (design-director's minor fix, lands with QA-19); the 2.0 Counting-sign gap
on the SE (QA-19); the plan said step 2 removes the Hall and sticker pebbles and the book: the orchestrator's note in
`B26.md` now keeps the pebbles until step 4 and removes the book in step 2's follow-up.

## Not checked

The real phone and iPhone SE, sound, a child's hands, iOS; the sign on tablets as a picture (no tablet sign golden;
checked by geometry); `deno task check` (nothing under `supabase/` changed).

## Re-verification after the follow-up (2026-10-29, same day)

What the follow-up changed: the tablet bubble is at most 210 wide (`bubbleMaxWidth`) and breaks after `{child},` when
the line is wider (`_MapBubble`); `homeBubble` is now the editor's `{child}, מַה בַּבַּקְבּוּק?`; the dead book button is
gone (`home-book`, `clusterGap`, `bookSize`, `He.bookSemantics`, `assets/art/ui/book.svg`; the Parents button is held
in its old place by `parentsRowHeight`); QA-25 and QA-26 un-skipped (assertions unchanged); goldens regenerated by name,
new `home_long_name_tablet_landscape/portrait.png`; `tools/hebrew_voice_review.py` (the `homeBubble` comment),
`docs/agents/hebrew-notes.md`, `board_geometry_test.dart`, `golden_screens_test.dart`.

| Command (in `app/` unless said) | Result |
|---|---|
| `flutter analyze` | No issues found |
| `dart format --output=none --set-exit-if-changed .` | 283 files, 0 changed, exit 0 |
| `flutter test` (whole suite, as delivered) | **1693 passed, 8 skipped, 0 failed** (8 min 0 s): the developer's count |
| `python tools/export-hebrew-review.py`, then `python tools/hebrew_voice_review.py` (repo root) | **9,521 rows** (screens 331); master text-ready 9,455, proposed 43, unchanged 23. The five tables are byte-identical to the delivered ones; against HEAD they differ only in the `homeBubble` row and the removed `bookSemantics` row (plus the two count lines of `hebrew-review.md`'s summary) |
| `flutter test test/qa_b26_home_sign_test.dart --plain-name re-verification` (QA's new group) | 4 passed, 2 skipped (QA-29) |
| the same with `--dart-define=QA_OPEN=true`, `--plain-name QA-29` | both fail (3 and 4 lines on both tablets) |
| 4 product mutations of the bubble code, each against `home_sign_test`, `qa_b26_home_sign_test`, `board_geometry_test`, `golden_screens_test` (copy, mutate, run, restore, SHA-256 checked) | below |
| `flutter analyze`, format, `flutter test` (whole suite, with QA's updated file; run last) | No issues; 0 changed; **1697 passed, 10 skipped, 0 failed** = 1693 + 4, skipped 8 + 2 (QA-29) |

Checks:

1. **Text.** `homeBubble` is the editor's line in `hebrew-notes.md` code point for code point, NFC, pointed, `nikud:
   true`; `מַה` with patah before the dagesh (the editor's rule 4). The `?` stands at the left end (RTL), in every golden.
2. **Goldens, against HEAD** (pixel regions, then looked at): every home golden differs only in the book (gone: phone
   160..224 x 12..81, SE 109..173, tablets 133..205), the pill (no dots) and the bubble words; `home_tablet_landscape`
   also has the Hall and sticker pebbles (HEAD was stale, noted above). The Parents button is in no changed region on any
   of the 4 boards (unmoved; `board_geometry_test` checks it at left 59 / 16 / 24 / 24, centred on the old row).
   **`companion_home_hero_phone`**: the family character's dark red square is back (654..717, 199..262); against QA's
   whole-file render of the first pass it differs only in the book and the bubble. `companion_lesson_hero_phone.png` is
   unchanged (not in `git status`). Tablet landscape: the bubble (802..1006 with `נֹעָה`) leaves all five Counting stairs
   clear (they end at 747). Tablet portrait: the bubble starts at 417, 78 clear of the Counting sign.
   `home_long_name_tablet_*` (אלכסנדרה): two lines, `אלכסנדרה,` / `מַה בַּבַּקְבּוּק?`, right-aligned, 155 wide, nikud of line 2
   clear of line 1, the tail at the mouth; it grows up over the home island's palm crown (the design review's choice).
   **The nit for the design-director** (plain `נועה` breaks onto two lines on tablets): it gives exactly the
   `home_long_name` look (155 wide, a call then a question) and reads naturally; the pointed `נֹעָה` stays on one line
   (203.6). Fine as it is; the only cost is that most typed names give a two-line bubble on tablets.
3. **QA-25, QA-26, QA-27: closed.** QA-25 and QA-26 pass unskipped with the original assertions (left 802 >= 755; gap
   to the Counting sign 78 >= 12); QA-27's square is present.
4. **The book is gone everywhere**: no `home-book` (except the test asserting it is absent), `bookSemantics`,
   `bookSize`, `clusterGap` or `ui/book.svg` left in `app/`, `tools/` or `docs/`. Hall and sticker pebbles: their code
   block is untouched by the diff.
5. **The bubble, 9 names x 2 text scales x 4 boards** (QA's group "re-verification"; names as parents type them:
   `דן`, `נועה`, `נֹעָה`, `אלכסנדרה`, `אביגיל-אלכסנדרה`, `אביגיל אלכסנדרה`, `Alexandra`, 10 x ש, 24 letters; the friend's
   real mouth read from the app): on tablets never wider than 210; on phones always one line; always on screen; a touch
   at its centre never lands in it and opens nothing; no overflow except the known pill (QA-19, phone at 1.3).
   **Two lines are not always kept**: a name wider than the line (about 178 at 24) wraps itself: the double names and
   10 x ש take 3 lines, the 24-letter name 3 at 1.0 and 4 at 1.3 (broken inside the word). QA-29.
6. **Mutations** (each restored; the file's SHA-256 checked after the run):
   - no break after the name (`text: line`): caught by `home_sign_test` (3 tests); QA's file, `board_geometry_test`
     and **`golden_screens_test` pass** (the long-name goldens stay under the 3 % tolerance);
   - cap 300 instead of 210: caught by `home_sign_test` and QA's file; the goldens pass;
   - `IgnorePointer(ignoring: false)`: caught by `home_sign_test` and QA's file;
   - no cap on tablets (step 2's one-line bubble back): caught by `home_sign_test` and QA's file; **the goldens pass**.
   Every mutation is caught by at least one test. The goldens catch none, which is QA-28 again.

| id | severity | owner | what | proof | done when |
|---|---|---|---|---|---|
| QA-25 | closed | design-director, hebrew-text-editor, app-developer | the tablet bubble no longer covers the stairs | test passes unskipped | done |
| QA-26 | closed | same | the tablet bubble is clear of the Counting sign | test passes unskipped | done |
| QA-27 | closed | app-developer | the hero golden shows the character again | golden diff | done |
| QA-29 | minor (look) | design-director (rule), app-developer (code) | On tablets a name wider than the bubble's line wraps by itself: `אביגיל-אלכסנדרה`, `אביגיל אלכסנדרה` and 10 x ש give 3 lines; a 24-letter name 3 lines at 1.0 and 4 at 1.3, cut inside the word. The design review says never three lines. Suggested: in the bubble, shorten the name with `shortenName` (the sign's rule) to what fits one line of 178, as nitzi-home.md section 3 already asks for the home's bubble. | `qa_b26_home_sign_test.dart` "QA-29 (open)", `--dart-define=QA_OPEN=true` | both tests pass unskipped |
| QA-28 | minor (test honesty), open | qa-engineer, infrastructure-engineer | as above; now also: two bubble mutations (no break, no cap) pass every golden | this section | as above |

**May B-26 step 2 be committed? Yes.** Analyzer and format are clean, and the whole suite passes (1697 passed,
10 skipped). QA-22, QA-25, QA-26 and QA-27 are closed. QA-29 (long names on tablets, minor) and QA-28 (golden tolerance)
are follow-ups with skipped tests or records; neither is a blocker. Commit QA's `app/test/qa_b26_home_sign_test.dart`
with it.

Not checked in the re-verification: the real phone and tablet, sound, a child's hands, iOS; `deno task check`
(nothing under `supabase/`).
