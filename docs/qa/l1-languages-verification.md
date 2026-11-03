# QA record: milestone L1, text, direction and fonts (F1, F5, LS01, count and tap in a course)

Date: 2026-11-03. Verified by: qa-engineer. Branch `languages-l1`, worktree `D:\nitznutz-lang2`, head `245db5c` (before this record).
Plan: `docs/milestones/L1.md` (section 1 "done when", section 6 deferrals). Frame: `docs/languages/frame.md` 2.1 (F1, F5), 2.2, 2.3
(LS01, the two-choice rule). Fonts: `docs/languages/fonts.md` 6 and 8. Material: the three Band A batches
(`docs/languages/{english,hebrew,russian}/band-a-content.md` and their `pronunciation.csv` tables).

**Verdict: all five acceptance criteria PASS as written. Four defects: two major (QA-L1-1, QA-L1-2) and two minor (QA-L1-3,
QA-L1-4), each with a failing test that is skipped until the fix.** Nothing blocks the merge of L1 itself (no content pack uses
the new faces yet). QA-L1-1 and QA-L1-2 must be fixed before the first content that uses text tiles (HEB-A-11 and every reading
skill): QA-L1-1 makes a short own name stand out from its distractors, and QA-L1-2 is under the design-spec's touch floor.

## 1. What ran

| Command | Result |
|---|---|
| `flutter analyze` (in `app/`) | No issues found |
| `dart format --output=none --set-exit-if-changed .` | 414 files, 0 changed |
| `flutter test` (whole suite, once, before my files were added) | **+3608 passed, 0 failed, 3 skipped** (18 min 46 s). The 3 skips are old (two open-defect proofs behind `QA_OPEN`, one Windows-only voice-tool test) |
| My two new files: `qa_l1_language_test.dart`, `qa_l1_open_defects_test.dart` | **+29 passed, 0 failed, 8 skipped** (the 8 are the open-defect proofs) |
| The open-defect file with `--dart-define=QA_OPEN=true` | **8 of 8 fail**, as they must until the fixes |
| `deno fmt --check`, `deno lint`, `deno check --frozen supabase/functions/ tools/gen-testvector.ts`, `deno test --frozen ...` (Deno 2.9.6, the scratchpad copy) | fmt 108 files ok, lint 106 files ok, check ok, **198 passed, 0 failed, 7 ignored** (the 7 need a database) |
| pgTAP | not run: no Docker here, and L1 touches no migration, function or policy (`git diff --name-only 2a85689..HEAD -- supabase .github app/pubspec.yaml app/pubspec.lock app/network_hosts.json` is empty) |

The full run is of the branch as built; the two QA files were added after it and change no product file, so the sum is 3608 + 29
passed and 3 + 8 skipped. I did not run the full suite a second time. L1.md section 8 says the Deno suite was not run: it was, now.

## 2. Acceptance criteria of L1 section 1

| # | Criterion | Verdict | Proof |
|---|---|---|---|
| 1 | **F1.** A course has a direction; rows of tiles, stage pictures and the hint geometry follow it; a target word is an isolated LTR run; a prompt never prints it inline (`TargetChip`, `Spoken.show`); a Hebrew line holding a target word is refused; numbers and arrows never mirror; every land unchanged | PASS | `course_text_test.dart` (the direction of each course; `CourseText` per course; `isolateLtr`; "numbers and arrows in a target run are not mirrored"; the chip is its own row under the line on four boards; "rows follow the course": hint tiles, stage pictures and the real tiles, first tile left in English and right in Hebrew and in a land); `ls01_lesson_test.dart` "no Latin letter ever stands in the Hebrew caption"; `language_checks_test.dart` "no Latin or Cyrillic inside a Hebrew frame line" (caption and title, language pack and lands). Goldens read (section 4): English and Russian rows run left to right, the Hebrew row right to left with its first tile at the right and its speaker at the right (reading-start corner), the chip stands on its own line under the Hebrew line. **Every land unchanged:** `git diff --name-only 2a85689..HEAD -- app/test/goldens` lists only the 28 `ls01_*` files; the full suite is green with every existing golden. New here: 29 more tests, among them the chip with all 195 real Hebrew frame lines of the three batches on the four boards (section 3) |
| 2 | **F5.** Each rule refuses a broken fixture and accepts the valid one; messages name file and path; `eng`/`rus`/`heb` script purity; look-alikes; no Latin or Cyrillic in a Hebrew frame line; decodable words; every distractor tagged; no accent tag on a distractor; the tag catalogue; the 2-choice rule | PASS | `language_checks_test.dart` (one group per rule, a valid fixture first for each course so each case fails for its one reason; every message path is asserted `file › path`). **New, on real material:** section 3. The two-choice rule matches frame 2.3 point by point (section 3.4) |
| 3 | **LS01.** Text tiles with a speaker; a tile with no clip works; sound-only tiles; the caption after the answer (rus, reader, Band B or C, never Band A); two-clip lines Hebrew then target; option text through `TargetText` only | PASS (with QA-L1-1 and QA-L1-2) | `ls01_test.dart`: text tiles per course (family, locale, direction, order), "a tile with no clip has no speaker, still works, and shows its text", the speaker plays its own clip and does not answer, a tap beside it answers, a sound button plays its clip and answers, hints replay the buttons in order, a picture says its word, a mic answer plays no clip over the child; the caption policy as a pure function (9 cases); `ls01_lesson_test.dart` (the prompt is the Hebrew clip then the target clip, the replay says both, a target with no recording leaves the frame clip, the praise is two clips, `sayClips` order and skips). **New:** `qa_l1_language_test.dart` runs the policy as the lesson screen wires it, on a real `LessonScreen`, with the child's age and settings: Russian reader age 3-4 no word, age 5-6 and 7-8 the word, a parent's Band A override no word, the new and heritage routes and "no route yet" no word, English never. `TargetText` only: the only file that names `NitznutzLetters` or `targetFontFamily` is `design/target_text.dart` (grep of `lib/`; `source_rules_m1_test.dart` enforces it), and `OptionTextFace`, `RevealCaption` and `TargetChip` all go through `CourseText`, which goes through `TargetText` for English and Russian and Heebo for Hebrew |
| 4 | **Count and tap in a course.** Number clip per tap, unscored, no tag; a double tap lights and restarts the count; the "how many?" step is scored on sound-only tiles | PASS | `count_tap_course_test.dart`: valid pack for each course; refused with no clips, a wrong clip count, any trace tag, an option with no clip; each tap plays the next number word and writes nothing; the same object twice lights it, restarts, writes no evidence and no tag; a core tag that got past the validator is never written; the options are sound buttons (no numeral, dots or picture); a wrong button writes its tag once and does not recount; a hint replays the buttons; "how many?" is two clips; the buttons follow the course direction. Golden `ls01_count_answer_*` read |
| 5 | Analyzer, format, whole suite, goldens on the four boards looked at; PLAN.md updated | PASS | section 1; section 4; `docs/PLAN.md` gains four paragraphs (F1, F5 and the validator fields, LS01, count and tap) in the L1 commits |

## 3. The F5 checks on the teachers' real material, and the two-choice rule

`qa_l1_language_test.dart` reads the real tables (`pronunciation.csv` of each course, the batch files themselves) at run time.

1. **Script purity on the real words.** English: all 223 `shown` values are clean. Russian: all word rows of `pronunciation.csv` pass,
   and so does every Cyrillic run (more than 1,000 words, more than 100 with a stress mark) of `russian/band-a-content.md`: every
   stress mark follows a vowel and none follows yo. Hebrew: every word row passes and is fully pointed. The rows the rules refuse are
   exactly the ones that are not tile text: a sound in brackets (`[м]`), a placeholder (`{puppet}`), a verse with its line break
   (`/`), a gap (`…`), a dash and a quotation. The test checks that their ids belong to a known non-tile kind (`snd-`, `ch-`,
   `rh<n>`, `heb-a-u-` and so on). See note N3 for the day those faces are built.
2. **Look-alike sweep, both ways.** Every English word with a look-alike letter, with each such letter in turn swapped for its Cyrillic
   twin (230 swaps), is refused and names the Latin letter; every Russian word with a Cyrillic letter that looks Latin, swapped for
   the Latin twin, is refused and names the Cyrillic one.
3. **Decodable, against an oracle.** With the letters м а л н о taught, exactly the real Russian syllables (`syl-*` rows) made of those
   letters are accepted and every other is refused with "cannot be read yet at RUS-A-05"; HEB-A-10's letters ב ר ת are readable
   when taught, and a card with an untaught letter is refused and named.
4. **The two-choice rule against frame 2.3, point by point.** 3 choices: every distractor tagged, so two tagged (two may share a tag:
   tested). 2 choices: one tagged distractor (tested). Allowed only when (1) the skill has 3-choice items too, or is binary and
   balanced (yes = no, same = different: tested); (2) 2-choice items are at most half the skill's items (exactly half passes, one more
   is refused: tested on the shape of ENG-A-16, 6 two-choice and 6 three-choice items); (3) a 2-choice item is never a check alone:
   a check of two choices must be in a binary skill, name its partner, and the partner must name it back, be of the same skill,
   be a check of two choices and answer the opposite side (all five failures tested, plus a pair with no `pole`). Free-response
   modes are outside it. I found no point where the code is looser or stricter than the text.
5. **The bubble with a word in its chip, with the real frame lines.** All 195 pointed Hebrew lines of the three batches (the `he-*`,
   `F..` and `i-*` tables), each with an English word in the chip, on the four boards in Band A: no overflow, the chip inside the
   bubble, and the chip's bottom edge at most 4 pt below the top edge of the tiles (the tightest are the two nine-word lines on the
   phone SE: 3 pt; see QA-L1-4).

## 4. The 28 `ls01_*` goldens, all opened

Looked at with the Read tool, on four boards each: `eng_letters`, `eng_words`, `rus_words`, `heb_words`, `sound_chip`, `caption`,
`count_answer` (7 scenes x 4 boards = 28). What I checked and found:

- **No overflow stripe, no cut text, no nikud clipped** on any board. The long word "elephant" fits its tile on the phone SE with
  about 10 pt either side. Hebrew words (כֶּלֶב, חָתוּל, סוּס) show full nikud at line height 1.7.
- **Direction.** English and Russian tiles run left to right, speaker at the left corner; Hebrew right to left, first tile at the right,
  speaker at the right corner. The pictures of the Russian caption scene run left to right with the right one first at the left.
- **Fonts.** English and Russian are in the teaching font, Hebrew in Heebo. The Russian stress mark shows on the tiles
  (`ма́ма`, `па́па`, `ба́ба`) and is absent from the caption (`роза`), because the reader route's display default is no marks:
  correct per `showsStress`.
- **The chip** stands alone on its own line under the Hebrew line, centred in the bubble (the Hebrew above is right-aligned: a
  cosmetic mismatch, note N4). It is "three" (a word, no punctuation).
- **Count scene.** The flower (the big disc) with the counter "3" at its foot, the three small objects, then three sound buttons
  (a speaker and nothing else). On the phone SE the counter's pill is cut flat at the foot of the stage; the core golden
  `lesson_2_count_three_answers_phone.png` does the same, so it is the existing counter, unchanged.
- **The ball.** No `ls01_*` golden draws a ball (the fixtures use flowers, a butterfly and plain discs), so the redrawn ball
  (b81718f) is not in any of them. I looked at `docs/design/languages/ball_vs_balloon.png`: the new ball reads as a matte
  rubber play ball, never a balloon, in all six colours.
- **Fixture pictures are flat discs**, so picture aspect ratio and stretching cannot be judged from these goldens; that is for the
  first golden with real pictures (L2).
- **Existing land goldens unchanged:** see criterion 1.
- **Tile touch areas.** Tiles are 96 pt square (or wide, up to 220) with a 12 pt margin: the existing tokens. The speaker is not
  (QA-L1-2). The gap between tiles is 24 pt, which on a tablet in Band A is below the spec's 32; this is the existing tile row
  of every land (the same 24 in `lesson_2_count_three_answers_tablet_*`), not new in L1.

## 5. Defects

| Id | Severity | Title | Owner | Failing test (skipped until fixed) |
|---|---|---|---|---|
| QA-L1-1 | major | A word of one or two letters is set as a letter (bold, full size) beside Medium words, so it stands out | app-developer, with design-director | `qa_l1_open_defects_test.dart` "QA-L1-1" (English, Russian, Hebrew names) |
| QA-L1-2 | major | The speaker on a text tile is 48 pt to touch; the floor is 64 (Band A) and 56 (B, C) | design-director (the size), app-developer | "QA-L1-2" (three bands) |
| QA-L1-3 | minor | The decodable check does not normalise the order of Hebrew marks on a letter | app-developer | "QA-L1-3" |
| QA-L1-4 | minor | Phone SE: a nine-word line with a chip leaves the bubble 11 pt under the tiles and the chip's border 3 pt under | design-director | "QA-L1-4" |

### QA-L1-1 (major)
- **Where:** `app/lib/play/option_faces.dart` `isSingleLetter` (at most two letters, marks excluded), used by `OptionTextFace` for each
  tile and by `TapGeometry.tileWidthOf`.
- **Steps:** a tap item of text tiles `on`, `cat`, `sun` (English); `да`, `нет`, `мама` (Russian); `דָּן`, `נוֹעָה`, `יַעַל` (Hebrew), on any board.
- **Expected:** frame 2.3 LS01 (a): the same face for every option of an item. HEB-A-11 ("recognise your own written name"): the names are two to five
  letters and the child's name must not be told by its look.
- **Actual:** the two-letter option is Heebo or Nitznutz Letters 700 at 56, the others 500 at 30.8 (`on` against `cat`: 56 against 30.8). Evidence:
  my renders `ls01`-style on the phone and SE (not committed): `on` is twice the size and bold, `да` and `דָּן` likewise. In the Band A batches the real
  words with two letters are: Hebrew דָּג צָב כַּף סַל גַּג יָם עֵץ אַף (8 picture words), Russian ёж, and the names בן, בר, דן, חן, טל, פז, גיל... of HEB-A-11.
- **Fix:** decide the face once for the item: letter face only when every option is a single letter or a digraph; otherwise the word face.

### QA-L1-2 (major)
- **Where:** `app/lib/play/option_faces.dart` `SpeakerMark` (`disc` 36, `touch` 48), L1.md section 3 ("the speaker's touch area 48").
- **Expected:** design-spec 6.1: "any child control (minimum, engineering floor)": 64 pt in Band A, 56 in B and C. The tile around it (96) leaves room for a 56 to 64 pt target in its corner only if the
  word's room shrinks; that is the design-director's choice.
- **Actual:** 48 in every band. A child who aims at the speaker and lands beside it answers the tile (tested by the builder as intended), so a miss is an answer.
  Not a loss (a "not yet" is never held against the child) but a spec floor broken in the new control.

### QA-L1-3 (minor)
- **Where:** `app/lib/content/scripts.dart` `plainWord`, `decodes`.
- **Steps:** `decodes(dalet+qamats+dagesh+gimel, {dalet+dagesh+qamats, gimel})` and the reverse (the two orders of the same grapheme).
- **Expected:** the same grapheme, whichever order the marks were typed in. **Actual:** false both ways; the pack is refused with "its letters are taught, but not in this
  order", which sends the author to the wrong problem. The editor's text is canonical (all 279 rows of the Hebrew table are NFC), so it bites on a hand-typed `graphemes` list.
- **Fix:** put the Hebrew marks of a letter in canonical order before comparing (and in `unpointedHebrewWords`).

### QA-L1-4 (minor)
- **Where:** phone SE (667 by 375), `BoardBubble` with a `TargetChip`, `fitFont` already at its floor of 14.
- **Steps:** `he-ins-how-many` ("כַּמָּה יֵשׁ? הַקְשִׁיבוּ לַכַּפְתּוֹרִים, וּגְעוּ בַּמִּסְפָּר הַנָּכוֹן.") or the Hebrew welcome line, with a word on show.
- **Actual:** the bubble body ends at 225, the tiles start at 214; the chip ends at 217. The tile paints over the lip of the bubble and 3 pt of the chip's border. Nothing the child reads is lost.
- **Fix:** a place for the chip that does not stack under a long line, or a shorter line (hebrew-text-editor).

## 6. Notes for later milestones (not defects)

- **N1. Hebrew single letters are small.** A Hebrew letter on a tile with a speaker is scaled down more than an English one (Heebo's 1.7 line height has to fit into the room above the speaker), so it looks smaller and sits high in its tile (seen in a render of ב ר ת next to b d p; not measured in points). Known (L1.md section 6, optical centring); the design-director's numbers come with the Band B letter templates.
- **N2. Digits in a Hebrew tile.** `textProblems` refuses a digit in every course, but D-9 says only English and Russian tiles. HEB-A-10 ("letters or numerals") has the cards 5, 7, 0, 1, 2, 9 and the shapes ● ○ △ ⭐ ♥ ✿ as text cards of `sort_drag`. When the `sort_drag` text face is built, decide whether a numeral card is `text` (then the digit rule must allow it in `heb`) or a picture.
- **N3. The punctuation list** (`space ' - . , : ! ?`) refuses `…`, `—`, `/`, `"` and the curly apostrophe `’` (with the message "other letter"). The Russian rhymes, the Hebrew syllable strips (`בָּ… נָ… נָה`), gaps and quotations of the batches use them. Fine for L1's tiles (the tables' `shown` for tile words has none); the LS04, LS05 and LS08 builds will need the list widened.
- **N4.** The chip is centred in a bubble whose Hebrew line is right-aligned.
- **N5. "Tap all the letters"** (HEB-A-10.3 to .5) is a multi-select tap, which `tap_answer` does not have. It is not on L1.md's deferred list, so it should be added to it.
- **N6.** In the scored "how many?" step the replay button replays the counting prompt (with the objects lighting), not the "how many?" line (D-4: "the replay replays the question only", the existing behaviour of `replayPrompt`); the hint is what plays the buttons again.
- **N7.** The `shown` column of the three tables was used as the source of tile text; the real packs' option texts are the next thing to run through the same checks (L2, L3).

## 7. Not checked

The real phone and a child's hands; the sound of any clip (the fixtures' clips are files that name their line); real pictures (the goldens use fixture discs, so aspect ratio and stretching are not judged); pgTAP (no Docker, and L1 touches no migration); the parent switch for the caption (D-10: no screen yet).

## 8. Files

New: `app/test/qa_l1_language_test.dart` (29 tests, all pass), `app/test/qa_l1_open_defects_test.dart` (8 tests, skipped until fixed), this record.
No product file is touched.
