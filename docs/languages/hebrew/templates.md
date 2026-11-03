# The Hebrew course: activity templates

Owner: hebrew-language-teacher (what each template must teach). The code is the app-developer's, the layout and pictures the design-director's, and the engine frame the curriculum-expert's. Status: **draft for the owner's OK** (2026-11-03). Nothing is built.
Skills: `syllabus.md`. Evidence: `docs/research/hebrew-course-2026-11-03.md`.

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

## 2. The templates the course needs

"Reuse" means an existing template with the change named. "New" means a new activity type, with a schema and pack validation (`content/schemas/`), tests and goldens. Every template keeps the shared rules of `docs/curriculum.md` §6.1:
- tap first; voice optional and never wrong;
- a three-step hint ladder that changes the representation at step 2 and ends with "show me";
- a replay button;
- big targets;
- no timer.

| # | Template | Reuse or new | What changes | Skills (`syllabus.md`) |
|---|---|---|---|---|
| H1 | **Hear and choose / read and choose** | Reuse `tap_answer` | (a) **Text options:** a letter, a CV unit, a word, a sentence or a final form, drawn big with nikud, in the course font. (b) **A text stem:** a written word or sentence in the scene, to read, with pictures as options. (c) **A sound per option:** a speaker on each option plays its own clip, so a pre-reader can compare sounds and pictures with names. (d) Up to 4 options in B and C, 3 in A | A-02, A-05, A-07, A-11, B-01–B-04, B-06–B-11, B-14–B-16, B-19–B-23, C-01–C-13, C-15–C-17, C-22, C-25 |
| H2 | **Sort by sound, letter or meaning** | Reuse `sort_drag` | Items can be **text tiles** or pictures with a **speaker** (hear the word). Bins can show a **letter** as their sign | A-03, A-05, A-10, B-07, B-10, B-11, B-16, C-08, C-16 |
| H3 | **Match pairs** | Reuse `match_pairs` | A **text face** (letter, final form, script letter, word, pointed or unpointed) beside the numeral face; script faces drawn from the design-director's stroke set | B-02, B-16, B-17, C-13, C-25 |
| H4 | **Write a letter** | Reuse `trace`, extended | (a) **Letter paths:** 27 print forms (22 + 5 finals) and 27 script forms, with stroke order and direction, from the design-director. (b) **Three modes:** trace (exists); **copy** (the model beside an empty box, no path in the box); **memory** (no model; the voice says the sound or name). (c) Copy and memory need a **free-stroke check**: compare the child's strokes to the letter's strokes, with no path shown; the start and direction are checked as today. (d) Feedback at the end of a stroke only. (e) Pre-writing strokes for A-14 | A-14, B-24–B-27, C-26, C-27 |
| H5 | **Find the odd letter / fix the word** | Reuse `spot_error` | A **text cell** (`txt:`), so a row of letters or a word can hold the one to find or fix | B-16, C-20 |
| H6 | **Order the pictures or sentences** | Reuse `build_pattern` (or `T06` if built) | Picture or text tiles into slots **right to left** | A-13, B-05, C-11, C-18 |
| N1 | **Story player with dialogic pauses** | **New** | Narrated picture pages; optional word-by-word highlight. At planned pauses, an H1 question with picture answers; the answer is recast in the voice. A target-word card (picture, meaning, use). A parent co-play card at the end. No free speech scoring | A-01, A-02, A-12, A-13, B-01, B-04, B-06, B-18, C-15, C-18 |
| N2 | **Sound tokens: clap, blend, split** | **New** | A drum or tokens, one per syllable, CV unit or sound. Tokens are laid **right to left**. A puppet says units for the child to blend. The child drags a token per unit heard; letters can appear on tokens from B-09 on | A-08, A-09, B-08, B-12, B-13 |
| N3 | **The CV wheel** (*גלגל סימני ניקוד*) | **New** | Explicit teaching and practice of letter + vowel sign = CV unit: put a sign on a letter and hear the unit; turn the wheel to change the letter or the sign; "make the unit you hear". It is the teaching screen of each step S1–S8 and the step-2 hint of every decoding item | B-19, B-21, C-01–C-05; hints of all DEC skills |
| N4 | **Word builder** | **New** | Letter tiles or CV tiles dragged into a word **right to left**. Modes: (a) **build from units** (reading support); (b) **dictation** (hear a word, build it); (c) **own name** (the name's letters, on the device only). The check has three outcomes: **book spelling**, **sound-right** (every sound shown, with a homophone letter or a missing vowel letter, tag M-HEB-HOMOPHONE), and **not yet** (a sound missing or wrong). Sound-right counts as success for B-28 and C-19 and not for C-21 and C-22. The final form is taken automatically or checked, by mode (C-20) | B-27, B-28, C-06, C-19–C-22 |
| N5 | **Sentence builder and cloze** | **New** | Word cards into a sentence, right to left, with spaces; a sentence with a gap and 3 word choices; agreement check (the cards for gender and number) | C-10, C-23, C-24 |
| N6 | **Read along** | **New** | A pointed text with word-by-word highlight; listen, then read (echo reading); repeated reading. **Unscored.** An optional parent check in the parent area (owner decision 5); a mic only on a tap with the parent's switch, never stored or sent | A-12, B-18, C-11, C-12, S11 practice |
| N7 | **Rhyme and song** | **New** (or a mode of N1) | An original rhyme sung or said with a beat; at the line end a pause with 2–3 picture choices to complete it | A-06, A-07; the letter-name song |

**Counts:** 6 templates reused with changes (H1–H6), 7 new (N1–N7). H1, H4, N1, N3 and N4 carry most of the course and come first.

## 3. What each new template must teach (the teacher's requirements)

- **Right to left everywhere,** and the order of units lights up right to left. A child who reads left to right is caught by M-HEB-ORDER distractors.
- **The CV unit is always heard as one sound** (`voice-brief.md` §3). A letter alone is heard by its sound only where that sound can be stretched. Otherwise the letter is heard inside a CV unit or a word.
- **Every text tile is the editor's text** (nikud final, never generated at runtime). Tiles use the course font (`voice-brief.md` §6) at reading size, never smaller than the size the design-director sets per band.
- **Distractors** come from the families of `syllabus.md` §5. Every item has at least two tagged distractors, and every word distractor is a **real word** or a CV unit, never a non-word, except in N2 "nonsense rhyme" play (Ministry: nonsense rhymes are fine in gan).
- **No speed:** no timer, no "fast", no exposure limit for reading.
- **Hint ladder per decoding item:** (1) replay and point to the first unit; (2) the CV wheel for the unit the child missed (a new representation); (3) "show me": the voice reads unit by unit while each lights, then the whole word, then the child taps.
- **Hint ladder per writing item:** (1) the start dot and direction; (2) the stroke drawn slowly once; (3) trace mode.

## 4. Questions for the curriculum-expert (the shared engine)

1. **Sub-skills per letter group** (`HEB-B-14.S1` … `.S7`): can the engine track mastery per group under one skill id, or should each group be its own skill (about 14 more ids)?
2. **The "sound-right" outcome** in N4 is a third result (not right, not wrong). The engine and the response codes (`app/lib/play/response_code.dart`) need it.
3. **Two placement strands** in one course (L and C, `syllabus.md` §9).
4. **The Languages category frame:** a course outside the island lands, its own path and progress (`docs/languages/README.md`).

## 5. Hand-offs (to be routed by the orchestrator)

- **app-developer:** H1–H6 changes and N1–N7, after the owner's OK and a milestone plan; the free-stroke check for H4; the N4 three-outcome check.
- **design-director:** layouts on phone and tablet for N1–N7 and the text tiles; letter stroke paths (print and script); the font audit (`voice-brief.md` §6).
- **curriculum-expert:** §4.
- **qa-engineer:** once per finished template (owner rule, 2026-10-30).
