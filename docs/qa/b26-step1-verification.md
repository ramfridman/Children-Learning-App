# QA verification: B-26 step 1 (the island's words and `homeIslandName`)

2026-10-29, qa-engineer. Worktree `D:\nitznutz-b26`, branch `b26-nitzi-home`, uncommitted changes on top of `c2db667`.
Plan: `docs/milestones/B26.md` (decisions 1 to 8); texts: `docs/agents/b26-hebrew.md` §1.5 and §3.

**Verdict.** Step 1 passes. No blocker, no major. One minor code defect (QA-22, a contrived input), one test gap that
QA fixed in test code (QA-23), and doc nits for the editor (QA-24).

## What ran

| Command (in `app/` unless said) | Result |
|---|---|
| `flutter analyze` | No issues found (before and after QA's test files) |
| `dart format --output=none --set-exit-if-changed` on the 3 changed Dart files, then on `.` | 0 changed, exit 0 (281 files with QA's) |
| `flutter test` (whole suite, as delivered) | 1235 passed, 8 skipped (the older open QA tests), 0 failed, 7 min 37 s; 1235 = 1184 (B-23/B-24 record) + 51 |
| `flutter test` (whole suite, with QA's file and the QA-23 fix) | 1247 passed (1235 + QA's 12), 9 skipped (+ QA-22), 0 failed, 7 min 31 s |
| `flutter test test/home_island_name_test.dart` | 51 passed |
| `flutter test test/qa_b26_home_island_name_test.dart` | 12 passed, 1 skipped (QA-22) |
| the same with `--dart-define=QA_OPEN=true` | 1 failed (QA-22, as expected) |
| `flutter test test/source_rules_m1_test.dart` (with the QA-23 fix) | 13 passed |
| `python tools/export-hebrew-review.py`, then `python tools/hebrew_voice_review.py` (repo root) | 9,522 rows; master text-ready 9,456, proposed 43, unchanged 23. `hebrew-master.csv`, `hebrew-review.csv`, `hebrew-review.md` and `hebrew-elevenlabs-review.md` byte-identical to the delivered files; `hebrew-elevenlabs-review.csv` differed only in line endings and was restored with `git checkout` |

## Checks

1. **Texts.** All 10 new `Str` entries compared code point by code point with the §3.1 table of `b26-hebrew.md`
   (script, not by eye): all match, including the two rewrites (`nitziHomeHi` `זֶה הַבַּיִת שֶׁלִּי.`, `nitziHomeBottle`
   `בַּבַּקְבּוּק יֵשׁ הַרְפַּתְקָה. בּוֹאוּ נִפְתַּח אוֹתוֹ.`). Each is declared once, in the child block. Pointed iff
   `nikud: true` (the 8 child texts pointed, the 2 `*Semantics` plain); all in NFC; no direction, control or odd
   characters. No `nitziHomeBack`. `home_island_name.dart` has no Hebrew letter at all; the source rule "every Hebrew
   string lives in he.dart" passes. `{child}` is the only new placeholder.
2. **Review tables.** The 8 lexicon rows (the tens and `מאה`) are B-24's words, never exported before; the editor
   records reading them (`hebrew-notes.md`). The 10 new rows and `homeBubble` are `proposed` through `PENDING`.
3. **`homeIslandName` / `shortenName`, beyond the developer's cases** (`app/test/qa_b26_home_island_name_test.dart`):
   24 clusters (title and semantics whole), 25 (title cut to 23 + `…`, sign and semantics whole), 40 and 200
   (Hebrew with nikud, Latin, many parts, decomposed accents); names that are only a geresh, a hyphen, a maqaf,
   digits, Arabic-Indic digits, emoji, a ZWJ family, a flag, nikud without a letter, a braille blank (all the
   fallback); precomposed and decomposed accents (one cluster per letter); emoji with skin tone and flags; RTL, LTR
   marks, embeddings, isolates and a stray U+2069 mixed in (all removed, one isolate only, it closes the string);
   pointed names at every maximum 3 to 14; a combining mark on a space or hyphen; `{child}`, `{child}{child}`,
   `{companion}` and `א $1 \0 {}` as names (shown as typed, once); maximum 3, 4, 5, 7, 16, 1000, 2^62; maximum 2, 1, 0,
   -1, -2^62 throw `RangeError` (also for an empty name); 5,000 random names from a 43-symbol alphabet with controls,
   bidi marks, nikud, gereshes, emoji and U+3164. Proven for every result: never throws (except the documented
   `RangeError`), at most the maximum clusters with the `…`, a prefix of whole clusters (never a letter without its
   nikud; the first dropped code point is never a combining mark), never ends on a separator, no letter loses its
   geresh (except QA-22), the cleaned name has no `Cf`/`Cc`, no double space, no outer space; the title's name is at
   most 24 clusters; the isolate is only on the sign and the title, the semantics is plain and whole.
4. **How strong the developer's tests are** (9 product mutations of `home_island_name.dart`, each restored from a
   copy; the file is untracked): geresh drop, trailing-separator drop, two-letter part rule, `<=` fit, the range
   check, the format-character and control clean-up, the space-run collapse: all caught by `home_island_name_test`.
   **Not caught: `titleMaxClusters` 24 → 25** (the developer tests 24 and 40, never 25); QA's 25-cluster test catches
   it.
5. **Nothing outside step 1.** `git status`: `he.dart`, the new lib and test file, the review tables, the tool, three
   docs under `docs/agents/`; untracked `docs/research/` (another agent). No screen, golden, pack, sync, gateway,
   `pubspec.*`, lock file, `.github` or test-vector change (`git diff --stat HEAD` on those paths is empty).

## Defects

| id | severity | owner | what | proof | done when |
|---|---|---|---|---|---|
| QA-22 | minor | app-developer | `_firstLetters` steps back over one geresh only. With two gereshes typed in a row and the cut on the second, the letter before them is shown without its geresh: `shortenName("אבגדה''וליה", 7)` gives `אבגדה…` (rule §1.4 step 2: a letter is never shown without its geresh). A contrived input; no real name has it. Fix: step back while `clusters[end]` is a geresh, then one more. | `qa_b26_home_island_name_test.dart` group "QA-22 (open)", `--dart-define=QA_OPEN=true` (fails) | the test passes and its `skip: _open` is removed |
| QA-23 | minor (test gap), **fixed by QA** | qa-engineer | `source_rules_m1_test` "child-space text never reaches a child as adult text" matched one-line entries only, so 8 child strings spread over lines by the formatter were never checked, 3 of them new (`nitziHomeTreasures`, `nitziHomeBottle`, `nitziHomeBottleDone`; also `listenMixed`, `medalBraveAskerHow`, `restGoodbye`, `stickersEmptyChild`, `trophyComing`). The pattern now takes several lines and the test checks that it matched every entry of the block (116 of 116). | Mutation: `nitziHomeBottle` made plain without `nikud:` passes the old rule and fails the new one | done (test code only) |
| QA-24 | nit (doc) | hebrew-text-editor | `b26-hebrew.md` after decision 4: §3.1 still says "Nitzi's bubble" (welcome, treasures) and lists `nitziHomeBack` `לַמַּפָּה`, which is not added (the home uses the back pebble and `landBackSemantics`); §5 Q8 still quotes `אֲנִי נִיצִי. אֲנִי גָּרָה פֹּה.`; §1.4 still says 10 clusters where decision 5 replaced the fixed count. | the doc lines | the doc says "the friend", marks `nitziHomeBack` dropped, Q8 and 1.4 point to the decisions |

## Observations (not step-1 defects)

- The count is in grapheme clusters, so a letter with any number of combining marks counts as one: a name of a few
  letters with dozens of stacked marks always "fits" and draws a tall stack. And U+3164 (Hangul filler) is a letter
  (`Lo`) that draws nothing, so a name of only U+3164 is "named" and the sign reads `הָאִי שֶׁל ` with an empty name.
  Only a parent can type the name on the device. Suggested for B-28 (one name rule everywhere): the app-developer and
  the security-engineer decide whether the form refuses invisible letters and caps marks per letter.
- Decision 5 says the fallback is used "only when the name is empty"; the code (and the editor's §1.3) also uses it
  for a name with no letter (`2018`, an emoji). The orchestrator may want to say so in the plan.
- `PENDING` replaces the `homeBubble` row's old Q6 comment with its own (which says "Q6 still stands"); the full Q6
  text is still in `hebrew-notes.md`.

## Not checked

The real phone, sound, a child's hands, iOS; how the sign looks (step 2 draws it; no golden changes in step 1);
`deno task check` (nothing under `supabase/` changed).
