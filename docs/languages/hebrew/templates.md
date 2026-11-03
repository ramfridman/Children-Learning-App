# The Hebrew course: activity templates

Owner: hebrew-language-teacher (what each template must teach). The code is the app-developer's, the layout and pictures the design-director's, and the engine frame the curriculum-expert's. Status: **approved by the owner on 2026-11-03**, and moved onto the shared Languages templates the same day (`docs/languages/frame.md` §2 and §5.4). Nothing is built.
Skills: `syllabus.md`. Evidence: `docs/research/hebrew-course-2026-11-03.md`. Band A items: `band-a-content.md`.

## 1. What exists today in `app/lib` (read 2026-11-03, branch `languages-team`)

The activity types are registered in `app/lib/content/models.dart` (`Activity.fromJson`): `count_tap`, `tap_answer`, `flash`, `sort_drag`, `build_pattern`, `robot_path`, `shape_builder`, `number_line`, `balance`, `spot_error`, `match_pairs`, `shop_pay`, `clock_set`, `trace`, `give_n`. Their sessions are in `app/lib/play/*_session.dart`.

What matters for a language course:
- **`tap_answer` (T01)** draws its options as **pictures only**. `ChoiceOption.label` is used for the screen reader and for voice matching, not drawn (`tap_answer_session.dart` `_option`: `PackSvg(a.assets.svg(o.sprite!))`). Its scene can show a picture group, a numeral, a row or a chart, but **not a written word or sentence**. An option has **no sound of its own**: the only sound is the prompt (`Spoken.vo`).
- **`match_pairs` (T16)** draws a face as a coin, a **numeral as text** (`AppText.fixed`) or a picture, so text faces are a small step from there.
- **`sort_drag` (T03)** draws each bin's **label as text** under its picture. Items are pictures only.
- **`trace` (T04)** checks finger strokes against stored paths in a 100 × 100 box: coverage, staying near the path, starting at the start, and a direction misconception when a stroke is drawn from the end. It has two guide modes, the full dotted path or the start dot with the first direction, and a worked example (a dot walks the path). It has **no letter paths**, **no "copy from a model" mode** and **no "write from memory" mode** (no path shown at all).
- **`spot_error` (T21)** cells are `asset:`, `n:`, `dir:` or `op:`. There is **no text cell**.
- **`build_pattern` (T05)** fills slots with dragged tiles. It could order story pictures, but it has no text tiles.
- **`flash` (T14)** shows a picture briefly. **It must never be used for reading**: there is no speed in the child's space (CLAUDE.md), and "read fast" would test speed, not decoding.
- **Text with nikud:** `app/lib/design/app_text.dart` already sets the nikud rules (line height ≥ 1.7, no letter spacing, Heebo or Secular One). Every text tile in a Hebrew lesson must go through it.

## 2. The templates the course uses (the shared ids)

The course's own proposals (H1 to H6, N1 to N7) are now the shared Languages templates **LS01 to LS14** of `frame.md` §2.3, built once for the three courses on the foundations F1 to F9 (frame §2.1). The substance of each is unchanged unless the table says so. Every template keeps the shared rules of `docs/curriculum.md` §6.1 and frame §2.3:
- tap first; the microphone is optional and never "wrong";
- a three-step hint ladder that changes the representation at step 2 and ends with "show me";
- a replay button;
- big targets;
- no timer;
- at least two tagged distractors;
- right to left (F1) and Heebo with nikud (F2; `docs/languages/fonts.md` §2: Heebo passed the audit, 700 for letter tiles, 500 for pointed words);
- Band A presentation: at most 3 choices and one instruction at a time.

| Shared id | Was | Template | Hebrew settings and what changes | Skills (`syllabus.md`) |
|---|---|---|---|---|
| **LS01** | H1, H2, H3, H5, H6 | **Text and sound options** (an extension of `tap_answer`, `sort_drag`, `match_pairs`, `spot_error` and `build_pattern`) | (a) **Text faces:** a letter, a CV unit, a word, a sentence or a final form, drawn big with nikud. (b) **A sound per option:** a speaker on each option plays its own clip, so a pre-reader can compare words and pictures. (c) **Audio-only options** (sound buttons with no picture). (d) **A text stem:** a written word or sentence to read, with picture options; "read it to me" is hint level 1 (credit 0.8). (e) **Cloze:** a sentence with a gap and 3 word tiles. (f) **Sequence:** picture or text tiles into slots **right to left** (the old H6). Sort bins can show a letter as their sign (the old H2); match faces can be text (the old H3); `spot_error` gets a `txt:` cell (the old H5). Up to 4 options in Bands B and C, 3 in A | A-02, A-03, A-05, A-07, A-10, A-11, A-12, A-13, B-01–B-11, B-14–B-17, B-19–B-23, C-01–C-13, C-15–C-18, C-20, C-22, C-25 |
| **LS02** | H4 | **Write a letter** (an extension of `trace`) | Unchanged in substance. (a) **Stroke data** (F6): 27 print forms (22 letters and 5 finals) and 27 script forms, with start, direction and order, the hanging top line and the "basement" for ק ך ן ף ץ; drawn by the design-director inside Heebo 700's shapes for print, from school references for script (`fonts.md` §5). (b) **Three modes:** `trace` (exists: full guide or start dot), `copy` (the model beside an empty box), `memory` (no model; the voice says the sound or the name). (c) A **free-stroke check** for copy and memory; feedback at the end of a stroke only. (d) **Mastery of a writing skill needs memory-mode evidence** (decision 4). (e) Pre-writing strokes for A-14 in trace mode. (f) Print in Band B, script in Band C (decision 23); a parent pencil card for every handwriting skill | A-14, B-24.Sn–B-26.Sn, B-27, C-26, C-27 |
| **LS03** | N2 | **Sound boxes** (`sound_boxes`) | The unit is the syllable, then the CV unit or a consonant (body plus coda). Tokens are laid **right to left**. **Drum mode** in Band A (tap a drum once per syllable); a puppet says units for the child to blend; letters can appear on tokens from B-09 on. Classifiers: a count of ±1 → `M-HEB-SYLL`; a CV given for a C → `M-HEB-CV-FOR-C` | A-08, A-09, B-08, B-12, B-13 |
| **LS04** | N3 (the show-me part) | **Blend slide**, mode `units` | A long pointed word is read CV unit by CV unit as each unit lights, right to left, then whole. It is the **"show me" (level 3) of every Hebrew decoding item**. Classifier: `M-HEB-ORDER` | C-06; level 3 of every DEC skill |
| **LS05** | N3 (the wheel) | **Change one part**: the CV wheel (*גלגל סימני ניקוד*) | Put a sign on a letter and hear the unit; turn the wheel to change the letter or the sign. Modes `explore` (the unscored teaching screen of each step S1–S8) and `make` ("make the unit you hear", scored). It is the **level-2 hint of every Hebrew decoding item**. Classifiers: `M-HEB-VOWEL-SKIP`, `-VOWEL-OU`, `-VOWEL-SHAPE`, `M-HEB-DOT` | B-19, B-21, C-01–C-05; level 2 of every DEC skill |
| **LS06** | N4 | **Build a word** (`build_word`) | Letter tiles or CV tiles into slots **right to left**; each slot sounds when filled. Modes `units` (build from CV units, reading support), `dictation` (hear a word, build it), `own_name` (on the device only, decision 25; writes no tile codes). Three outcomes: **exact**, **sound-right** (every sound shown, with a homophone letter or a missing vowel letter, from the author's closed list for the item: `M-HEB-HOMOPHONE`; in B-28 also `M-HEB-PARTIAL`), **not yet**. Sound-right counts as success in B-28 and C-19 and as not yet in C-21 and C-22 (frame §3.3.5). The final form is taken automatically (B-28) or checked (C-20) | B-27, B-28, C-06, C-19–C-22 |
| **LS07** | N5 (the builder) | **Build a sentence** (`build_sentence`) | Word cards into a line right to left, with spaces; gender and number choices on a card (`M-HEB-AGREE`); the author lists every correct order. The cloze of the old N5 is LS01 (e) | C-10, C-23, C-24 |
| **LS08** | N1, N6 | **Story** (`story`) | Modes `listen` (narrated; tap a picture to hear its word), `dialogic` (planned pauses with an LS01 question; the answer is recast by the voice), `read_along` (each word lights as it is read), `read_first` (the child reads; a tap on a word plays it after trying), `echo` (the voice reads a phrase, the child repeats it). A target-word card (picture, meaning, use) and a parent co-play card at the end. **Reading in a story is unscored** (decision 22); its questions are scored. **New (frame §5.1, decision 1 CHANGED):** in `echo` and `read_along`, when the parent turned voice on for the Hebrew course, the child may tap the microphone and say the phrase; the per-word matcher (LS09) answers **confident** ("שָׁמַעְתִּי: …", the word named) or **unsure** ("בּוֹאוּ נֹאמַר יַחַד" and the voice models it). It is still **unscored**: no mastery evidence, no misconception, nothing lowered; at most one more try, by a tap; no audio stored or sent. The parent's optional check of reading aloud stays in the parent area (decision 22) | A-01, A-02, A-12, A-13, B-01, B-04, B-06, B-18, C-11, C-12, C-15, C-18; S11 reading practice |
| **LS09** | N6 (the speaking part) | **Say it with me** (`say_it`) | Optional in this course: the voice says a word with its picture, a pause, the voice again. With voice on: per-word confident or unsure, as in LS08. Hebrew is the child's first language and the course has no speaking strand, so it is **practice only**, never evidence. The picture tap after it is a scored listening item when the author marks it | A-02 (optional echo of the story's target words) |
| **LS11** | (A-04) | **Listen and do** (`listen_do`) | Hear a command and drag a thing to a place in a scene ("שִׂימוּ אֶת הַכַּדּוּר עַל הַכִּסֵּא"). The embodied version (the child does it and taps "done") is never counted alone. Classifier: the wrong place → `M-HEB-PREP`; the two objects swapped → `M-HEB-ROLE-SWAP` | A-04 |
| **LS12** | N7 | **Sing along** (`sing_along`) | An original rhyme said or sung with a beat; **rhyme mode**: a pause at the line end with 2–3 picture choices to complete it (scored, as LS01). Melodies need the owner's OK (decision 3); the letter-name song is his decision too | A-06, A-07; the letter-name song |
| **LS13** | (syllabus §9) | **Placement game** | Two strands, **L** (oral language and phonological awareness) and **C** (the code), each a staircase with its own entry; the parent's one question sets where C starts, never the result; probes are LS01, LS03 and LS06 items with `purpose: probe` | syllabus §9 |
| **LS14** | (C-24) | **Writing tray** (later, optional) | An on-screen Hebrew letter tray, right to left, with final forms. Free text is never scored, stored past the activity or synced | C-24 (later) |

**Not used by this course:** LS10 (puppet talk). Its personal-turn mode (decision 10) is for the foreign-language courses, where "what's your name?" is the language being learnt; in a first-language course it would be a personal question with no teaching purpose, so HEB-1 has none. T14 `flash` is never used for reading (frame §2.2).

**Counts:** this course uses 13 of the 14 shared templates (all but LS10): 2 extensions (LS01, LS02) and 11 new (LS03–LS09, LS11–LS14). Band A needs LS01, LS02 (trace mode, which exists), LS03 (drum), LS08 (`listen`, `dialogic`), LS09 (optional), LS11 and LS12: wave 1 of frame §2.5, plus LS02 trace, which is built today.

## 3. What each template must teach (the teacher's requirements)

- **Right to left everywhere,** and the order of units lights up right to left. A child who reads left to right is caught by `M-HEB-ORDER` distractors.
- **The CV unit is always heard as one sound** (`voice-brief.md` §3). A letter alone is heard by its sound only where that sound can be stretched. Otherwise the letter is heard inside a CV unit or a word (decision 21).
- **Every letter is introduced whole** (decision 16, CHANGED; frame §5.3): its shape, sound, name and writing in one introduction (LS01 for name and sound, LS02 trace for writing), as one bundle per group (`B-14.Sn`, `B-15.Sn`, `B-24.Sn`). Blending always uses the sound, never the name.
- **Every text tile is the editor's text** (nikud final, never generated at runtime). Tiles use Heebo at reading size, never smaller than the size the design-director sets per band. **Qamats qatan** is not taught as a sign and no decoding item before S10 shows one; a **bare holam next to a shin or sin dot** waits until S9 (`syllabus.md` §3, the font audit's two points).
- **Distractors** come from the families of `syllabus.md` §5. Every item has at least two tagged distractors, and every word distractor is a **real word** or a CV unit, never a non-word, except in LS12 "nonsense rhyme" play (Ministry: nonsense rhymes are fine in gan).
- **No speed:** no timer, no "fast", no exposure limit for reading.
- **Hint ladder per decoding item:** (1) replay and point to the first unit; (2) LS05, the CV wheel, for the unit the child missed (a new representation); (3) "show me": LS04 `units`, the voice reads unit by unit while each lights, then the whole word, then the child taps.
- **Hint ladder per writing item:** (1) the start dot and direction; (2) the stroke drawn slowly once (motion); (3) trace mode.
- **Speech, where the microphone is used** (LS08 `echo` and `read_along`, LS09): only with the parent's voice switch for this course, only on a tap; confident or unsure, never wrong; no evidence; no audio or transcript kept (frame §5.1).

## 4. The questions to the curriculum-expert: answered (frame §7)

1. **Sub-skills per letter group:** each group is its own skill node with a dotted id (`HEB-B-14.S1` …), with its own BKT, revisits and prerequisites; the plain id is a roll-up (no BKT; mastered when all groups are; as a prerequisite it means "all groups"). The same for B-15, B-24, B-25 and B-26, and `B-14.Sn`, `B-15.Sn`, `B-24.Sn` form a bundle (frame §3.3.2, §3.3.3). Applied in `syllabus.md`.
2. **The sound-right outcome:** the engine stays three-valued; LS06 classifies exact / sound-right / not yet against the author's closed list per item, and each skill says whether sound-right counts as `correct` (B-28, C-19) or `incorrect` (C-21, C-22). A new attempt field `detail` (`exact`, `sound_right`) feeds the parent view; the response code is tile indexes only (frame §3.3.5).
3. **Two placement strands:** yes; LS13 takes any number of strands per course (frame §3.2).
4. **The Languages frame:** one land with a door per course, its own path, progress, placement and voice, the course id on everything, no link to the other lands or courses (frame §1).

## 5. Hand-offs (to be routed by the orchestrator)

- **app-developer:** the shared templates in the frame's waves (L1 LS01; L4 the Band A templates; L5 LS02 copy and memory, LS03 full, LS05, LS04, LS06; L6 LS07, LS08 reading modes), with the Hebrew settings above; the per-word matcher in LS08 `echo`.
- **design-director:** the Hebrew print and script stroke data (F6); layouts of the Hebrew text tiles; the Band A pictures (`band-a-content.md` §2).
- **curriculum-expert:** the new Band A tags in `syllabus.md` §5 for the catalogue (and the suggested MEANING family).
- **qa-engineer:** once per finished template (owner rule, 2026-10-30).
