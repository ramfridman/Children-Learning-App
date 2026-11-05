# QA record: milestone L4, the Band A templates (LS08 story, LS11 listen_do, LS12 sing_along, LS10 puppet_talk, LS03 drum, LS13 placement)

Date: 2026-11-04. Verified by: qa-engineer. Branch `languages-l4`, worktree `D:\nitznutz-lang4`, head `117769e` (before this record).
Plan: `docs/milestones/L4.md` (section 3 "acceptance criteria, per template", section 7 "deferred", section 9 "built").
Frame: `docs/languages/frame.md` 2.3 (the six templates), 3.2 (placement), 5.2 (personal turns). Material: the three Band A batches
(`docs/languages/{english,hebrew,russian}/band-a-content.md`) and the picture set `content/languages/pictures`.

**Verdict: the milestone builds, and every acceptance item that is a rule PASSES (unscored steps, tags, the 2-choice and accent
rules, the probe, the staircase, the personal turns and their switch, the arrows, no red, no "wrong", no timer word, existing
goldens). Ten defects: eight major (QA-L4-1, -2, -3, -4, -6, -7, -8, -9) and two minor (QA-L4-5, QA-L4-10).** None is a crash, a data
leak or a child-safety break (no blocker).
QA-L4-6 (a drum retry written as an incorrect attempt) and QA-L4-1, -2 (the body hotspots, which ENG-A-06 and RUS-A-03 need) should be
fixed before any course content uses these templates; QA-L4-7 is a content change that costs nothing.

**Update 2026-11-06 (section 10): QA-L4-1 to QA-L4-10 are all CLOSED** on `languages-course-home` (L4 with the fixes of `acdecdf`,
`cbfca03` and `c589f54` merged). Two new defects came from playing the real body map: QA-L4-11 (minor) and QA-L4-12 (major, three Russian
items refused by the validator).

## 1. What ran

| Command | Result |
|---|---|
| `flutter analyze` (in `app/`) | No issues found |
| `dart format --output=none --set-exit-if-changed .` | 441 files, 0 changed |
| `dart run tool/pack_builder.dart schema --check` | "The JSON Schema files in ../content/schemas are up to date." |
| `flutter test` (whole suite, once, before my files were added; 19 min 03 s) | **+3897 passed, 0 failed, 3 skipped** (the 3 skips are old: two open-defect proofs behind `QA_OPEN`, one Windows-only voice-tool test). The working tree was clean afterwards: no golden was rewritten |
| My two new files, `qa_l4_language_test.dart` and `qa_l4_open_defects_test.dart` (run together) | **+38 passed, 0 failed, 12 skipped** (the 12 are the open-defect proofs) |
| The open-defect file with `--dart-define=QA_OPEN=true` | **12 of 12 fail**, as they must until the fixes (12 tests for 10 defects: QA-L4-1 and QA-L4-4 have two each) |
| `python -I tools/qa_check_language_pictures.py content/languages/pictures` (new script, section 4) | 335 files: see section 4 |
| A scratch `flutter test` that loads all 335 pictures with `vg.loadPicture(SvgStringLoader(...))` (not committed) | loaded 335, failed 0, warnings 0 |
| Deno, pgTAP | not run: L4 touches no gateway, function, migration or policy (`git diff --name-only 8ccdd59..HEAD -- supabase .github` shows none; the task said Deno is not needed) |

The full run is of the branch as built; my two files were added after it and change no product file, so the sum is 3897 + 38 passed
and 3 + 12 skipped. I did not run the full suite a second time.

**Existing goldens unchanged:** `git diff --name-status 8ccdd59..HEAD -- app/test/goldens` lists 92 `A` (added) and no `M` or `D`;
the 92 are `ls03_*`, `ls08_*`, `ls10_*`, `ls11_*`, `ls12_*`, `ls13_*` (23 scenes x 4 boards). The edits to `hint_qa_test.dart`,
`placement_test.dart` and `playthrough_test.dart` only add a `_ => throw` case for the new templates (no test weakened).

## 2. The real items, played

`qa_l4_language_test.dart` builds items of the three batches as fixture items (their ids, options, tags with the engine ids of
frame 4.2, the real pictures of `content/languages/pictures`, the real hotspot map `mika-body.hotspots.json`) and plays them through
the sessions on the lesson-screen frame, or through `LessonScreen` with the real database.

| Template | Real items played | Result |
|---|---|---|
| LS08 | ENG-A-15 s01 (six pages, the listen story, a word touched); ENG-A-15 d01 (pause on page 3, cat gives `eng.lis.story_recall`, frog `eng.lis.sem`, the recast, three more pages); HEB story 1 s1-q1 (five pages, pause after page 3, `heb.ol.story_seen`, `heb.ol.story_world`; the arrow points left, the options run right to left); s1-q2 (pause after page 4) | PASS |
| LS11 | ENG-A-06 i01, i02, i03 (hotspots on the real map: head, eyes, ears; the nose does not validate, QA-L4-1); ENG-A-02 i09 (buttons: the friend shows the chosen action) and e01 (embodied: writes nothing); HEB-A-04.1 (place the ball: `heb.ol.prep`); RUS a07.22 (picnic drag by touching the thing, then the plate: `rus.voc.sound`) | PASS, with QA-L4-1, -2, -3 |
| LS12 | ENG-A-13 c01 (the hello chant, four lines in order, writes nothing, ends the lesson); HEB-A-06.2 (the clock verse: whole, up to the gap, the three pictures, `heb.pa.allit`, `heb.lis.sem` stands in for `heb.ol.sem`, the whole verse after the answer) | PASS |
| LS10 | ENG-A-17 i05 (Pip asks Mika, three bubbles); ENG-A-01 p01 (name), A-04 p01 (age 3 to 9, seven cards), A-08 p01 (likes): the pass, a card and "I said it" each leave no attempt and end the turn | PASS; the ten-card family turn is refused (QA-L4-10) |
| LS03 | ENG-A-14 cat (1), apple (2), banana (3): one more `eng.pa.syll`, one fewer `eng.pa.weak_syll`; HEB-A-08 banana: both are `heb.pa.syll` | PASS; a count off by two is QA-L4-6 |
| LS13 | The nine tap probes of ENG section 5 make a valid four-level strand; the tenth, A-06 i04, is an LS11 hotspot and is refused (QA-L4-7) | PASS (the refusal is the point) |

Not played because no template can hold them (all in the batches, none on the deferred list of L4.md section 7): HEB-A-09's second
representation (the drum strip, tapped in order, each tap plays its syllable: a blend, not a count); two-place body parts (QA-L4-2);
the Hebrew drum level 2 ("the friend's jaw drops once per beat") against the build's clapping hands (a content alignment, note N6).
The fixture pack has only the skills `XXX-A-01` and `XXX-A-02`, so every real item here carries the second one.

## 3. Acceptance items of L4.md, one by one

| # | Item | Verdict | Proof |
|---|---|---|---|
| 1 | **Unscored steps write nothing** (listen story, chant, embodied, personal) | PASS | On the rig: each leaves `attempts` empty and the lesson goes on. On `LessonScreen` with the real database: a lesson of a chant, an embodied step, a personal pass and a heard story leaves no attempt and no alert (`acceptance: unscored steps write nothing`). `completePractice` never calls `_record` (`lesson_controller.dart` 561-568). Frame 5.2 asks for "an attempt row with an empty response"; the build writes none, which is stronger (L4.md D-3) |
| 2 | **Hint ladders: level 2 changes the representation in every template** | PASS (levels 1 and 2); level 3 has QA-L4-4 and QA-L4-5 | Story: level 1 the answering page again, level 2 the pages in a row (`story-row`). Listen_do: level 2 the close-up card (`do-closeup`), in all four choice modes. Sing: level 1 the end word, level 2 the end word before each option (six clips, in order), level 3 lights the answer. Puppet: level 1 the line then each bubble slowly, level 2 `puppet-key`. Drum: level 1 the slow word, level 2 one hand per beat (3 hands for 3 beats), level 3 the friend drums. `HintLadder.problemWith` is null for all five |
| 3 | **Distractors: every one tagged, under frame 2.3** | PASS | The validator refuses an untagged third option, with the file and path, in a story pause, a hotspot command, a button command, a rhyme gap and a bubble (`every distractor is tagged`); an accent tag on a distractor is refused. Personal-turn cards carry no tag. The real wrong answers give the catalogue tags (section 2) |
| 4 | **Drum**: one more or one fewer maps to the course's tags; any other count is a retry with no tag; at most 9 taps count | PASS for the tags and the cap; FAIL for "no evidence" (QA-L4-6) | Banana, counts 1, 2, 4 to 9 and 12: 2 gives `eng.pa.weak_syll`, 4 `eng.pa.syll`, the others an empty tag; 12 taps are held at 9 (`n=9`). Hebrew: both are `heb.pa.syll`. The dots are drawn and no digit is on the screen. The attempt of a count off by two is written as `incorrect` and escalates the hints; L4.md 3 (LS03.2) says "no tag and no evidence" |
| 5 | **Placement follows frame 3.2 exactly** | PASS | A reference written from the frame text (not from the code) agrees with `Staircase` on 4000 random answer sequences (entry level and number of probes). Two right go up, one wrong goes down; 2 reversals or 8 items; the highest level with at least 2/3 right minus one; two misses at the floor stop at once (asked = 2, entry 0); a questionnaire start above the floor is not a promise (`startingAt(2)` goes down on two misses); `PlacementGame.next(doneThisVisit: 8)` is null, the strands run in order, oral first. Speech is never a probe: a probe with `voiceAnswer` is refused ("speech is never a probe"). See notes N1 for the one place the code is wider than the text |
| 6 | **A probe shows no result to the child** | PASS | On `LessonScreen` a probe has no lamp and no "show me" (the replay stays). A tap probe answered right and answered wrong leaves the identical bubble, voice (`vo:eng.placement.thanks`), feedback kind, `solved`, tile state, hint level and error count. A drum probe with 3, 2 and 6 taps leaves one identical state and ends after its one answer. Goldens `ls13_probe` and `ls13_thanks` read |
| 7 | **Personal turns: the pass is always in reach, nothing is kept, the parent switch both ways** | PASS | The pass is on screen for the name, age (7 cards) and likes turns on the phone; a card, "I said it" and the pass each end the turn and leave no attempt. On `LessonScreen` with the real database: switch on, the pass ends the turn, nothing is stored; switch off, no card and no pass appear, the puppet answers for itself, the lesson goes on alone, nothing is stored. The pass is a 76 pt target. Note N5 (the cards scroll on the phones) and QA-L4-10 |
| 8 | **Page-turn arrows point the reading direction, never mirrored** | PASS | English and Russian: `arrow_forward`, at the right end corner; Hebrew: `arrow_back`, at the left end corner; each painted with an explicit `TextDirection.ltr`. Goldens `ls08_page` (arrow right), `ls08_heb_page` (arrow left) read |
| 9 | **No red, no "wrong", no timer word in the child-space source** | PASS | Over the nine new files: no timer, countdown, streak or stopwatch in code; no `Colors.red`; no "wrong" or Hebrew word for a mistake in any string; the three tokens the new files use (`notYetRing` #B9A2F7, `correctGlow`, `hintHalo`) are not red; the seven new `He` labels are neutral. One comment, `choice_session.dart` line 92 ("the timer is the session's own"), has the word; the existing rule skips comments (`source_rules_m1_test.dart`) and it scans only `lib/child`. No code uses it |
| 10 | **Goldens** | PASS with findings | 32 of the 92 opened (section 5); QA-L4-3, -8, -9 and notes N3 to N5 come from them |
| 11 | **Existing goldens unchanged** | PASS | Section 1 |

## 4. The 335 pictures of `content/languages/pictures`

By `tools/qa_check_language_pictures.py` (new, committed; exit code 1 on any problem). The rule is `docs/art/art-brief.md` section 5.
The loader is `flutter_svg` 2.3.2 (`vector_graphics_compiler` 1.3.2); its parser knows `rgba()`, `clipPath`, `use`, `symbol`, gradients.

- **Allowed features only: PASS.** All 335 use only `svg`, `g`, `path`, `rect`, `circle`, `ellipse`, `polygon` and `clipPath`; no
  `text`, `style`, `filter`, `mask`, `image`, `use`, gradient, `href`, `class` or `style` attribute. Path commands M L Q C Z A T S and
  their lower-case forms; transforms translate, rotate, scale. Fills are hex, `none`, and `rgba(43,35,80,0.14)` in 3 files
  (`pip-arrive`, `pip-family`, `pip-holds`; supported by the loader). All 335 load in `flutter_svg` with no warning.
- **Size under 40 KB: PASS.** The largest is `fam-all.svg`, 33,512 bytes. None is at or over 40,960 bytes.
- **Inside the viewBox: PASS with 1 file past a 2 percent tolerance, and it is intended.** ViewBoxes are `0 0 256 256` (286 files) and
  `0 0 384 216` (49 scenes). With paths flattened, transforms and clip paths applied and half a stroke added, 332 files are exactly
  inside. The other three: `balloon-big` 7.8 units past the bottom (3 percent: its string runs off the bottom edge on purpose,
  `docs/languages/pictures.md` 4.1), `house-roof` 2.5 past the top (1 percent, the glow), `rainbow` 2.2 past the left and 1.0 past the
  right (under 1 percent). All three are clipped by the picture's own box.

## 5. The goldens read (32 of 92, at least one per template on every board)

Opened with the Read tool: `ls08_page` (phone, tablet landscape), `ls08_heb_page` (phone), `ls08_question` (phone, SE, tablet portrait),
`ls08_row` (phone, SE), `ls11_hotspots` (phone, tablet portrait), `ls11_closeup` (phone), `ls11_drag` (SE), `ls11_place_heb` (phone),
`ls11_buttons` (tablet landscape), `ls12_chant` (phone), `ls12_chant_heb` (tablet portrait), `ls12_rhyme` (SE), `ls12_ends` (phone),
`ls10_bubbles` (SE), `ls10_bubbles_heb` (tablet landscape), `ls10_personal_age` (SE), `ls10_personal_family` (phone),
`ls03_drum` (phone), `ls03_taps` (phone, SE, tablet landscape), `ls03_hands` (phone, SE), `ls03_drum_heb` (tablet portrait),
`ls13_probe` (phone), `ls13_thanks` (SE, tablet portrait).

What I looked for and found:
- **No overflow stripe, no cut text, no nikud clipped** in any of them; Hebrew bubbles show full nikud at line height 1.7; no red; no
  digit near the drum (dots only); no timer.
- **Direction.** Hebrew rows run right to left and the arrow and the check mark stand at the left end corner; English at the right.
- **Real pictures** keep their aspect ratio (cat, duck, frog, dog, rabbit, banana, bear, teddy, table); none stretched.
- **The phone SE stage at a story pause and a puppet question, flagged by the builder, is small, and so is the phone's:** the picture
  the question is about is 61 pt on the phone and 53 pt on the SE (256 pt on both tablets). QA-L4-8.
- **The drum.** The check mark overlaps the drum's tap area by 31 x 20 pt on the phone and 54 x 20 pt on the SE (a drum tap in that
  corner is a "that's all"), and on the SE the third clapping hand is under the check mark. QA-L4-9. The drum itself is a plain disc
  (a banana beside a pale plate-like circle; `drum.svg` exists in the picture set), note N4.
- **The level 2 close-up card** of `ls11_closeup` sits over the scene's top right corner, on the bear's right ear and the head ring,
  and its crop of the head is cut off with a white strip. It also covers the place a `place` item names at the top right (QA-L4-3).
- **Hotspot rings** are a faint 12 percent tint: a part "glows" only when lit by a hint; fixture geometry, not content.
- **The page-turn arrow overlaps the picture's corner** on the phone and the tablet (over the cat's haunch, the ball's edge): by
  design, a corner button on the stage; the design-director's pass (note N5).
- **Pages in a row** (`ls08_row`) are about 30 pt thumbnails in 150 x 48 pills on the phone.
- **Personal family turn** on the phone shows the first row of cards and the top of a second (clipped): it scrolls (L4.md 9 says so).

## 6. Defects

| Id | Severity | Title | Owner | Failing test (skipped until fixed; run with `--dart-define=QA_OPEN=true`) |
|---|---|---|---|---|
| QA-L4-1 | major | The real body map's hotspots are 8 to 60 pt (the band's floor is 64) and the nose is refused by the validator | design-director (the map, a close-up for the face), app-developer (a padded hit area, the validator floor) | `qa_l4_open_defects_test.dart` "QA-L4-1" (two tests) |
| QA-L4-2 | major | A body part with two places (ears, hands, arms, fingers) cannot be one option: `at` is one rectangle | app-developer, with curriculum-expert | "QA-L4-2" |
| QA-L4-3 | major | The level 2 close-up card is fixed at the top right of the scene and can cover the place the child must touch | design-director (where it goes), app-developer | "QA-L4-3" |
| QA-L4-4 | major | Level 3 asked for with the lamp (or "show me") marks no answer in the choice templates; only three mistakes do | app-developer | "QA-L4-4" (two tests) |
| QA-L4-5 | minor | The rhyme ladder's level 3 does not play the whole verse (acceptance LS12.3, HEB-A-06) | app-developer | "QA-L4-5" |
| QA-L4-6 | major | A drum count off by two or more is written as an `incorrect` attempt and escalates the hints; the plan says "a retry with no tag and no evidence" | app-developer; curriculum-expert to confirm that a retry writes nothing | "QA-L4-6" |
| QA-L4-7 | major (content) | The English batch's placement probe ENG-A-06 i04 is an LS11 hotspot, which frame 2.3 (LS13) and the validator refuse | curriculum-expert, with the english-language-teacher (use A-06 i09, the LS01 "nose", or allow hotspot probes) | "QA-L4-7" |
| QA-L4-8 | major | On the phones the picture a question is about is a 53 to 61 pt thumbnail (story pause, puppet bubble, rhyme verse) | design-director, app-developer | "QA-L4-8" |
| QA-L4-9 | major | On the phones the drum's check mark overlaps its tap area, and on the SE covers the third clapping hand | design-director, app-developer | "QA-L4-9" |
| QA-L4-10 | minor (content or template) | The English family turn (ENG-A-07 p01) has 10 cards; the schema takes 8 and the phones show 4 | curriculum-expert (two turns, or 8 cards) or app-developer | "QA-L4-10" |

### QA-L4-1 (major)
- **Where:** `listen_do` hotspots (`listen_do_session.dart` `_hotspot`); `pack_validation.dart` `_at` (a share of 0.04 to 1.0); the map `content/languages/pictures/mika-body.hotspots.json`.
- **Steps:** build ENG-A-06 i01 to i08 from the design-director's map (rects and circles of the 256 canvas) and open them on a phone.
- **Expected:** design-spec 6.1: any child control is 64 pt at least in Band A; ENG-A-06 i04 is a placement probe (so the nose must exist).
- **Actual:** the stage is 241 pt on the phone, so head is 60 x 16, eyes 50 x 12, mouth 32 x 15, hands 40 x 40, feet 81 x 20, tummy 39 x 27 (the SE and the tablets in the test reason); the nose (r = 4.3 of 256) is 3.4 percent and the validator refuses it ("0.03359375 is outside 0.04 to 1.0"). The runtime does not widen a hit area.
- **Fix:** a hit area padded to the floor without overlapping a neighbour, or a close-up picture for the face; the nose cannot be a separate 64 pt target on a phone at all, so the batch may need a face close-up. A decision for the design-director and the curriculum-expert.

### QA-L4-2 (major)
- **Steps:** an option with `at` as two rectangles (the map has two for ears, hands, arms, fingers): the schema says "expected an object, found a list".
- **Expected:** "touch your ears" accepts either ear (ENG-A-06 i02, i03, i06; RUS-A-03 i04, i05, i13).
- **Actual:** only one place can be named, so the other ear is a dead touch (and if the author covers both with one rectangle it overlaps the head).

### QA-L4-3 (major)
- **Steps:** HEB-A-04.1 shape: `place` mode, the right place at the top right (`at(0.4, 0.04, 0.5, 0.26)`), two wrong places, then touch the centre of the right place.
- **Expected:** a hint never takes the answer out of reach.
- **Actual:** after the second mistake (level 2) the `do-closeup` card (top 6, right 6, up to 130 pt) lies over the centre of the right place; a touch there goes to the card, which does nothing. Part of the place stays touchable at its left edge. The fixtures of the builder use this geometry.

### QA-L4-4 (major)
- **Steps:** a puppet bubble, a dialogic story and a hotspot command: tap the lamp three times with no mistake.
- **Expected:** "level 3 shows the answer" (L4.md 3: LS08.3, LS10.3, LS11.3); `HintPicture.demonstration` has `marksAnswer`.
- **Actual:** `controller.answerShown` is `guided && _demoDone`, and the lamp does not set `guided`, so level 3 only pulses the tiles. The answer is marked only after the allowed mistakes. The old templates draw a pointing hand at level 3 whatever the path.

### QA-L4-5 (minor)
- **Steps:** a rhyme, three mistakes, level 3.
- **Expected:** "level 3 the whole verse with the right picture lit" (L4.md LS12.3; HEB-A-06 hint 3).
- **Actual:** the picture is lit (halo) and the verse is not played; the heard clips are the pairs of level 2. The whole verse plays only after the right answer.

### QA-L4-6 (major)
- **Steps:** banana (3 beats), drum 5 times (or 1, or 9), "that's all".
- **Expected:** L4.md 3 (LS03.2): "any other count is a retry with no tag and no evidence"; frame 2.3: "a retry with no tag".
- **Actual:** `submitPlacement(right: false, tag: '')` writes `incorrect:n=5`, counts an error and shows hint 1; three such counts end guided. A 3-year-old who drums at random or hammers the drum gets evidence against the skill; the tests of the builder assert the `incorrect` row as intended.
- **Fix:** no attempt and no hint step for a count that is not within one of the word's; the dots clear for another try. If the engine wants the evidence, the plan and frame must say so.

### QA-L4-7 (major, content)
- **Where:** `docs/languages/english/band-a-content.md`, section 4 ENG-A-06 row `i04 **P** | LS11 hotspot` and section 5 ("Level 3: A-02 i04, A-04 i08, A-06 i04").
- **Actual:** the only probe of ten that is not an LS01 tap; frame 2.3 LS13 says probes are "LS01, LS03 and LS06 items", and `probeTemplates` is `tap_answer` and `sound_boxes`, so a placement document naming it is refused ("is a listen_do: a probe is a tap item or a drum item", shown by `acceptance: the English strand O`).
- **Fix:** name A-06 i09 (LS01 "nose") as the level 3 probe.

### QA-L4-8 (major)
- **Steps:** the question of a dialogic story or a bubble, on the phone and the phone SE.
- **Actual:** `story-page-1` and `puppet-scene` are 61 pt (phone) and 53 pt (SE) wide; 256 pt on the tablets. The pictured page is the thing the question is about (ENG-A-15 d01 "Who is it?" is answered from the picture of page 3). The sing-along verse's pictures are the same size.
- **Expected:** a picture a child must look at is at least a tile (96 pt). The builder listed it as small (L4.md 9); it is a defect for a child of 3 on a phone.

### QA-L4-9 (major)
- **Steps:** the drum, tapped 3 times, on the phone and the SE; level 2 on the SE.
- **Actual:** `drum-done` overlaps `drum` by 31 x 20 pt on the phone and 54 x 20 pt on the SE (a tap there is "that's all", and with QA-L4-6 a premature count is written); the third `Icons.back_hand_rounded` is under the check mark on the SE.

### QA-L4-10 (minor)
- **Where:** ENG-A-07 p01 (10 cards: mom, dad, baby, brother, sister, grandma, grandpa, cousin, pet, someone else), the schema `answer.options: 10 items is outside 0 to 8`; the phone shows 4 cards, the SE 3, before the child scrolls.

## 7. Notes for later milestones (not defects)

- **N1. The floor rule is wider than its text.** Frame 3.2: "a strand whose first two probes fail at its floor stops at once". `Staircase` stops after any two consecutive misses at level 0 (for example right, wrong, wrong; or two right, then down and two misses). The outcome is the same entry (the floor) in the cases I tried and no child gets eight failures; the frame text could say "two misses in a row at the floor".
- **N2. "The verse plays twice, then stops".** The build plays the verse whole, then up to the gap (two playings, the second cut). If the Hebrew batch's "plays twice before its first pause" means two whole playings, the pack's `whole` clip list can carry the verse twice; no code change.
- **N3. The pass button's icon is `skip_next`, painted left to right**, so it points right in a Hebrew course too (reading direction left). It is not a page turn; the design-director may want it neutral.
- **N4. The drum is a plain disc and the word's picture sits at the left in Hebrew** (the code comment says "start corner"; `left: 8`). The picture set has `drum.svg`; the placement of the picture in RTL is a design decision.
- **N5. Chant pictures are 8 pt apart and the lit one grows by 8 percent**, so on a tablet portrait the tiles touch; the arrow of a story overlaps the picture's corner; the family turn scrolls. Design-director's pass.
- **N6. The Hebrew drum ladder says the friend's jaw drops at level 2; the build claps hands** (as the English and Russian ladders say). Align one of them.
- **N7. HEB-A-09's drum strip** (tap the drums in order, each plays its syllable) is a Band A representation that no L4 template holds and L4.md section 7 does not list; add it to the deferred list for the Hebrew course milestone.
- **N8. `LessonScreen._personalAllowed`** reads `ref.read(languagesProvider).value` and falls back to the default `personal: true` when the settings have not loaded. If a lesson could start before they load, a parent's "off" would be ignored for that turn. I could not make it happen (the provider is loaded long before any lesson; the course home that starts a lesson is still the L0 placeholder), so it is not filed; the course milestone that connects the home to the lesson should make the lesson wait for the settings.
- **N9. Fixture limits.** The fixture pack holds only skills `XXX-A-01` and `XXX-A-02`, and its own `lis.sem` clashes with `heb.ol.sem` (my Hebrew items use `heb.lis.sem` for it); no real pack exists yet, so the batch ids were not run through a real builder.
- **N10. Frame 5.2 vs D-3:** frame says a personal turn writes "an attempt row with an empty response"; the build writes no row at all. Stronger and fine; the frame text should follow.

## 8. Not checked

The real phone and a child's hands (every target above is measured on the test boards, not touched); the sound of any clip (fake clips); the
"we start here" parent line and the provider that joins placement to the engine (deferred in L4.md 9: `StrandProgress.startLevel` is not wired); the
questionnaire screens; `read_along` and auto-advance (deferred); pgTAP and Deno (nothing changed); a second full run of the suite.

## 9. Files

New: `app/test/qa_l4_language_test.dart` (38 tests, all pass), `app/test/qa_l4_open_defects_test.dart` (12 tests, all run since 2026-11-05), `app/test/qa_l4_reverify_test.dart` (2026-11-06, 30 tests),
`tools/qa_check_language_pictures.py`, this record. No product file is touched.

## 10. Re-verification, 2026-11-06 (branch `languages-course-home`, head `4c49c37`)

Verified by: qa-engineer. The design spec is `docs/design/languages-l4-layout.md`; the body map is
`content/languages/pictures/mika-body.hotspots.json` version 2. The developer's proofs of section 6 now run in every build (the
`skip: _open` is gone from all 12; I checked the diff against `0d435c4`: the tests were adapted to the redrawn map, none was weakened,
and QA-L4-10's test now asserts 8 cards and QA-L4-7's reads the corrected batch). I then played the real items and measured the spec's
numbers in a new file, `app/test/qa_l4_reverify_test.dart` (30 tests: 28 run, 2 skipped as open defects).

### 10.1 What ran

| Command | Result |
|---|---|
| `flutter analyze` | No issues found |
| `dart format --output=none --set-exit-if-changed .` | 462 files, 0 changed |
| `dart run tool/pack_builder.dart schema --check` | "The JSON Schema files in ../content/schemas are up to date." |
| `flutter test` (the whole suite, once, before my two new files; 19 min 34 s) | **+4073 passed, 0 failed, 3 skipped** (old: `mastery_reachable_test` 1 and `qa_open_defects_test` 2). Working tree clean afterwards: no golden was rewritten |
| `deno task check` (fmt, lint, check, test) | exit 0, **198 passed, 0 failed, 7 ignored** |
| The five SEC-L4 files, `qa_l4_open_defects_test.dart` and `l4_layout_test.dart` (run together) | **+112 passed, 0 failed** (`ls10_personal_safety`, `unscored_steps`, `staircase`, `ls13_placement`, `course`) |
| `qa_l4_open_defects_test.dart` alone | **12 of 12 run and pass** (was 12 skipped) |
| My new `qa_l4_reverify_test.dart` | **+28 passed, 2 skipped** (QA-L4-11 and QA-L4-12, open); with `--dart-define=QA_OPEN=true` both **fail**, as they must |
| My new `qa_l_course_test.dart` (course screens, see `l-course-verification.md`) | +28 passed |

### 10.2 The ten defects, one by one

| Id | Verdict | Proof (what I checked beyond the developer's test) |
|---|---|---|
| QA-L4-1 | **CLOSED** | The map has every area of at least 72/256 (0.2812), inside the picture; the validator floor `minBandAHotspot` is 0.2812 for a Band A hotspot and refuses a smaller one. All 8 ENG-A-06 and 14 RUS-A-03 items built from the real JSON: every body item has every place of every option at least 64 pt each way and apart on all four boards (phone, SE, tablet landscape and portrait); the nose has an area; every cards item shows tiles of 96 pt on the phones and 112 on the tablets. The three parts of a `show: body` item never overlap (by the map's own numbers). Follow-up: QA-L4-12 (the validator refuses three items) |
| QA-L4-2 | **CLOSED** | `at` takes one rectangle or 1 to 4; either ear, arm, hand or finger place answers `correct:o1` (every place of the right part touched on all four boards); several places are refused outside `hotspots` and `cards`; in cards mode a wrong card rings its own part and at level 2 the right card rings both ears |
| QA-L4-3 | **CLOSED** | Hotspots, place and drag, on all four boards, English and Hebrew: after two mistakes the card (96 pt on the phones, 130 on the tablets) is on the board, outside the scene, and clear of the bubble, the lamp, the eye and every target. Goldens `ls11_closeup_*` read: phone (413, 248), SE (300, 222), tablet landscape left of the scene, tablet portrait in the band under the scene at the end corner. No white strip in the crop |
| QA-L4-4 | **CLOSED** | The lamp three times marks the answer in `place`, `buttons` and `cards` (listen_do) as well as the three the developer tested (bubble, dialogic story, hotspots) |
| QA-L4-5 | **CLOSED** | The rhyme at level 3 plays the whole verse (`full`) |
| QA-L4-6 | **CLOSED** | 5 taps then "that's all": no attempt, no hint step, the dots clear; then the right count: one attempt, `correct`, hint 0; 4 keeps `eng.pa.syll`, 2 keeps `eng.pa.weak_syll`; five retries of 6 taps in a row write nothing and the lesson does not end |
| QA-L4-7 | **CLOSED** | All ten probe rows of the English batch are LS01, LS03 or LS06 |
| QA-L4-8 | **CLOSED** | Measured against section 4: the page is 206 x 116 on the phone and 185 x 104 on the SE (16:9 kept; 256 or more wide on the tablets), the stage keeps its height, each speaker is at the end of its tile in the course's direction (right in English, left in Hebrew), the last speaker stays clear of the guide; the tiles are 96 pt (phones) and 112 pt (tablets). Goldens `ls08_question_*`, `ls10_bubbles_heb_phone`, `ls12_rhyme_phoneSE` read |
| QA-L4-9 | **CLOSED** | The drum's zones against the table of section 5, English and Hebrew (every x mirrored), on all four boards: picture, drum, hands row, dots row and check mark each within 2.5 pt of the spec; the check mark and the drum never overlap (the stage box on the tablets is the spec's stage less a 16 pt padding). Goldens `ls03_drum_*`, `ls03_hands_*` read. The Hebrew picture is at the start (right) corner: note N4 is answered |
| QA-L4-10 | **CLOSED** | The family turn has 8 cards |

### 10.3 The decision to confirm: `buttons` at level 2

**CONFIRMED.** At level 0 and 1 the friend stands (no reaction), at level 2 (after two mistakes) the friend does the right action on the
stage, there is no close-up card in `buttons` mode, the two wrong touches were written as `incorrect:o2`, `incorrect:o3` (the shown action
is not an attempt) and a later touch on a button shows that button's action. It is the same information the old card gave (the right
option's sprite), in the same place as the representation of the other templates' level 2 ("the friend does it"), so it changes the
representation and gives the answer no earlier than the other templates do. Test: `qa_l4_reverify_test.dart` "the decision".

### 10.4 New defects

| Id | Severity | Title | Owner | Failing test (skipped until fixed; run with `--dart-define=QA_OPEN=true`) |
|---|---|---|---|---|
| QA-L4-11 | minor (validator gap) | A Band A `place` option (and a `drag` target or thing) can be any size from 0.04 of the picture: only `hotspots` has the 64 pt floor | app-developer (the floor in `_listenDo` for `place` and `drag`), with design-director (the value: 0.2812 as for hotspots, or 0.2747 = 64/233) | `qa_l4_reverify_test.dart` "QA-L4-11 (open)" |
| QA-L4-12 | major (content blocked) | The pack validator refuses three real items of the real map, RUS-A-03 06, 10 and 14: the nose (or belly) and the right arm touch edge to edge (0.3594 + 0.2812 = 0.6406) and `_overlap` reads the float sum as an overlap | app-developer (a tolerance of 0.001 in `_overlap`, as `reaches outside` has) or design-director (move the areas by 0.001) | `qa_l4_reverify_test.dart` "QA-L4-12 (open)" |

**QA-L4-11.** Evidence: `app/test/goldens/ls11_place_heb_phoneSE.png`: the "next to" place is 57 x 59 pt and the "under" place 115 x 60 pt on
the SE, both under the 64 pt floor, and the validator takes them. Steps: a `place` item of band A with an option at `{x:0.5, y:0.04, w:0.1,
h:0.1}` (23 pt on the SE). Expected: design-spec 6.1, any child control is 64 pt at least in Band A (QA-L4-1 holds hotspots to it). Actual:
no message. No real item is built from this yet (HEB-A-04.1 uses `place`), so no child can meet it today.

**QA-L4-12.** Steps: build `rus.a03.06`, `.10` or `.14` from the map (`arms` right place x 0.6406 beside `nose` or `belly` at x 0.3594, w 0.2812).
Expected: the map's note says the areas of an item on the body "never overlap" and its generator counts touching as apart. Actual:
`answer.options[2].at: overlaps answer.options[1].at: a touch must mean one thing`. The pack build would fail for these three items.

### 10.5 The goldens read for this section (Read tool, each PNG opened)

- All four boards: `ls11_closeup_*`.
- Drum: `ls03_drum_phone`, `_phoneSE`, `_tabletLandscape`, `ls03_drum_heb_phone`, `_heb_tabletPortrait`, `ls03_hands_phoneSE`,
  `_tabletLandscape`, `ls03_taps_tabletPortrait`.
- Questions and pictures: `ls08_question_phone`, `_phoneSE`, `_tabletLandscape`, `ls08_row_phone`, `ls08_page_tabletPortrait`,
  `ls08_heb_page_phoneSE`, `ls10_bubbles_heb_phone`, `ls10_personal_age_phone`, `ls10_personal_family_phoneSE`, `ls12_rhyme_phoneSE`,
  `ls12_chant_heb_phone`, `ls12_ends_tabletLandscape`.
- Commands: `ls11_hotspots_phoneSE`, `_tabletPortrait`, `ls11_place_heb_phoneSE`, `ls11_drag_phone`.

That is 28 of the 62 L4 goldens that changed since my first record (the others are the same templates on the other boards;
they were measured by the tests above, not opened).

Found: no overflow stripe, no cut text or nikud, no red, no stretched picture; the check mark is alone at the end corner of the drum on
every board; the cards stand outside the scenes. Noted, none a defect (design pass):
- **N11.** On the tablet portrait the scene of `listen_do` stays 614 square at the top of its stage and leaves an empty white band of 150 pt
  under it when no card is shown (`ls11_hotspots_tabletPortrait`): by design (section 3), but it looks unfinished.
- **N12.** On the SE the question row starts 6 pt from the screen edge (`ls08_question_phoneSE`): the spec's number; tight.
- **N5 (unchanged).** The page-turn arrow still overlaps the picture's corner (`ls08_heb_page_phoneSE`: over the ball's lower left).
- The drum is still a plain disc; `drum.svg` exists (the other half of N4).
- The personal cards on the phone are drawn as 56 pt circles inside a footprint of at least 64 (measured: every card and the pass are 64 pt or
  more on all four boards, `qa_l4_reverify_test.dart`).

### 10.6 Not checked

The real phone and a child's hands (everything is measured on the test boards); sound; HEB-A-09's drum strip (N7) is still a deferred
representation; whether a 3-year-old's random drumming writing nothing is enough evidence for the skill is a curriculum decision.
