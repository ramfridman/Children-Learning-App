# English course: activity templates needed

Owner: english-language-teacher (what each activity must teach). Code and template design: app-developer; layout: design-director; shared engine and numbering: curriculum-expert. Date: 2026-11-03. Status: **plan for the owner's OK; nothing built.**

Looked at: `app/lib/content/models.dart` (the 14 template kinds a pack can hold: `count_tap`, `tap_answer`, `flash`, `sort_drag`, `build_pattern`, `robot_path`, `shape_builder`, `number_line`, `balance`, `spot_error`, `match_pairs`, `shop_pay`, `clock_set`, `trace`), `app/lib/play/*_session.dart`, `app/lib/speech/` and `docs/curriculum.md` §6.2 (the T01-T25 catalogue; T06, T11-T13, T15, T19, T20, T22-T25 are not built). Skill ids are in `syllabus.md`.

## 1. What every English activity needs (shared, before any English template)

These are changes to the shared app, not templates. They are proposals for the app-developer and design-director, through the orchestrator.

| # | Need | Why | Today in the app |
|---|---|---|---|
| S1 | **English text in isolated left-to-right runs** (words, letter tiles, sentences) inside the right-to-left screens; slots, tiles and sound buttons ordered **left to right** | English is read left to right (syllabus M-ENG-DIR); `PLAN.md` direction rules | Captions are Hebrew only: `_caption` reads one element with `t` always `he` (`models.dart`). Option labels are Hebrew. |
| S2 | **A sound on every English option** (tap a picture or a word to hear it), separate from the prompt | Listening items need the word, not only the prompt; pre-readers | Options have `label` and `speech` (accepted spoken words), no per-option clip. |
| S3 | **Two-clip lines**: a Hebrew frame clip and an English target clip played in sequence (and the English clip reusable) | `pronunciation-spec` §3: split mixed-language lines; `voice-brief.md` | One `vo:` clip per line. |
| S4 | **A Latin teaching font** with a single-storey a and g, clear b d p q, and a four-line writing guide | Decision 1 (approved in principle); Heebo's Latin a is double-storey, which children do not write | Heebo and Secular One only. The design-director chooses and shows it to the owner. |
| S5 | **Letter tiles as an option type** (a grapheme, one or two letters, in the teaching font) | Letter-sound, build-a-word, spot-the-spelling | Options are sprites, numerals or sets. |
| S6 | **No English voice answers yet**: the voice path stays off for English answers; tap always works | The recogniser is Hebrew-only (`sherpa_engine.dart`); unclear speech is never wrong | Voice answers use Hebrew accept-lists (`answer_matcher.dart`). |
| S7 | **A language and course id on skills and progress** (`ENG-…`), so English has its own path and progress | `docs/languages/README.md` rule 5 | The engine is shared (curriculum-expert owns the frame). |
| S8 | **Letter stroke data**: model strokes (start, direction, order) for 26 lowercase and 26 capital letters in the teaching font, in the trace template's 100 by 100 box, with the four lines | B-19, C-13, C-15 | `trace` takes strokes in a 100 by 100 box with a direction misconception: fits. |

## 2. Existing templates the English course reuses

All need S1-S6. Ids are from `docs/curriculum.md` §6.2.

| Template | Built as | English uses (skills) | What it needs beyond S1-S6 |
|---|---|---|---|
| **T01 Tap the answer** | `tap_answer` | Listen and tap (A-01…A-11, A-16, B-01…B-07, B-10, C-20, C-26); **minimal pairs "same or different?"** (B-11); oral blending: robot talk → picture (B-14); **letter-sound** both ways (B-16, B-17, C-01…C-03); **read and choose** word, phrase or sentence → picture (B-21, C-04…C-11, C-17); **gap-fill** from a word bank (C-22); story questions (A-15, C-21, C-25) | An **audio-option mode** (options are sound buttons, not pictures, for "same or different?" and "which word did you hear?"); a **text prompt** shown in an LTR run (read-and-choose, gap-fill); letter tiles as options (S5). |
| **T02 Count and tap** | `count_tap` | Count in English (A-04, B-02) | English number words on each tap; Hebrew voice answers off (S6). |
| **T03 Drag to sort** | `sort_drag` | Sort by first sound, by rhyme, by vowel sound, by spelling (B-12, B-13, C-07, C-09, C-12); sort meaning groups (A-08, B-07); put the cat "under" the table (B-06) | Bins labelled by a picture, a sound button or a grapheme tile. |
| **T04 Trace** | `trace` | Letter formation (B-19, C-13, C-15); write a letter or a short word without a guide (C-16, C-23); pre-writing paths | Letter stroke data (S8); four-line guide; a `guide: none` mode (the path is checked but not shown) and a larger canvas for words. |
| **T05 Build the pattern** | `build_pattern` | Alphabet order (B-22, Band C) | Letter tiles (S5), left-to-right slots. |
| **T14 Flash** | `flash` | Optional "quick look" at a tricky word (C-11) | A mode where the word stays until the child taps (no time pressure in Band B; Band C optional). Low priority. |
| **T16 Match pairs** | `match_pairs` | Picture-picture with sound (A-05, A-09); colour-word, picture-word (B-01, B-04, C-04, C-26); capital-lowercase (C-13); word-word (B-21) | Faces that are an English word or a letter (S1, S5) with a sound. |
| **T18 Clock setter** | `clock_set` | "It's three o'clock." (C-20) | The English time line heard (S3). |
| **T21 Spot the mistake** | `spot_error` | Odd one out by first sound (B-13); fix the spelling (C-03, C-16); fix the sentence: missing capital or full stop (C-13, C-14) | Cells that are letter tiles or word tiles in an LTR row. |

**Existing reused: 9 templates** (T01, T02, T03, T04, T05, T14, T16, T18, T21).

## 3. New templates (proposed)

Numbered `LT01`-`LT11` (language templates) because the Hebrew and Russian courses are likely to need most of them too. The final ids and the shared design are the curriculum-expert's and app-developer's. Each follows `docs/curriculum.md` §6.1: tap path always, error classifiers with tags, hint ladder, knobs.

| Id | Template | What the child does | Skills | Right answer and error classifiers | Knobs | Priority |
|---|---|---|---|---|---|---|
| **LT01** | **Listen and do** (TPR) | Hears "Touch your nose!" / "Jump!"; taps the body part on a friend, or does the action and taps "done" (like T24 Sound & move, which is in the catalogue but not built) | A-02, A-06, A-14, B-05, B-10 | Tap version scored (the right hotspot); action version self-report, never counted alone. Classifier: `wrong_part` → M-ENG-L1-GUESS | number of steps (1-2), hotspots, speed of the line | 1 (stage 1) |
| **LT02** | **Sing and say along** | A short original song or chant plays with pictures that light on each key word; the child taps the picture as it is sung, or just joins in | A-01, A-13, B-22 | Not scored (practice); an optional tap on the lit picture | song id, tap-along on/off, repeat count | 1 (stage 1) |
| **LT03** | **Story listen** | A 4-8 page original picture story with a repeated line; tap a picture to hear its word; then T01 questions | A-15, C-25 | Questions scored through T01; the story itself practice | pages, repeated line, questions | 1 (stage 1-2) |
| **LT04** | **Say it** (echo) | Hears a word or chunk, then says it in the pause, then taps the picture to go on | A-12, and every new word | Unscored (S6); the following tap is scored as listening. If an English recogniser is approved later, it may confirm but never mark wrong | pause length, model repeat, slow version | 1 (stage 1) |
| **LT05** | **Puppet talk** (role-play) | A puppet asks ("How are you?", "Can I have an apple, please?"); the child picks the answer bubble (picture-supported, the English heard on tap), the puppet answers; the child may echo | A-17, B-08, B-09, C-19 | The bubble that fits the scene. Classifiers: `copula_missing`, `do_missing`, `wrong_chunk` → M-ENG-COPULA, M-ENG-DO, M-ENG-WORDORDER-Q. **Never asks the child's own details** | number of turns, bubbles (2-3), picture support | 2 (stage 2) |
| **LT06** | **Sound boxes** | Hears a word, drags a token into a box for each sound (Elkonin boxes), left to right; later says which box holds a given sound | B-15, C-05 | Token count = phoneme count. Classifiers: `one_per_syllable` → M-ENG-SEG-SYLL; `cluster_short` → M-ENG-CLUSTER | word length 2-4 sounds, boxes shown or not | 2 (stage 2-3) |
| **LT07** | **Sound buttons** (blend a word) | A written word with a dot under each sound (a bar under sh, ee…); the child slides a finger left to right, each sound plays, the word plays; then picks its picture | B-18, C-04…C-10 | The picture. Classifiers: `reversed_word` → M-ENG-DIR; `first_letter_match` → M-ENG-FIRSTLETTER-GUESS; `vowel_swap` → M-ENG-AE-E / M-ENG-VOWEL-SKIP; `digraph_split` | grapheme set, word list, buttons shown or faded, slide required or tap | 2 (stage 3-4) |
| **LT08** | **Build a word** | Hears a word (with its picture); drags letter tiles from a tray into left-to-right slots; each slot sounds when filled | B-20, C-05, C-08, C-16 | The exact spelling. Classifiers: `vowel_missing` → M-ENG-VOWEL-SKIP; `mirrored_order` → M-ENG-DIR; `c_k_swap` → M-ENG-C-K; `vowel_wrong` → M-ENG-AE-E | slots shown or not, extra tiles 0-3, digraph tiles, add-the-e mode | 2 (stage 3-4) |
| **LT09** | **Sentence builder** | Word tiles (with a sound on tap) go into a left-to-right line to match a picture; the capital word first, the full stop or question mark last | C-14, C-18, C-23 | The one order that is right (alternatives listed by the author when two orders are correct). Classifiers: `adj_after_noun` → M-ENG-ADJ-ORDER; `no_is` → M-ENG-COPULA; `no_full_stop` → M-ENG-PUNCT; `lowercase_start` → M-ENG-CASE | words 3-7, distractor tile, punctuation tiles | 3 (stage 6) |
| **LT10** | **Decodable reader** | A short book (one sentence a page) of only taught sounds and tricky words; the child reads, may tap a word to hear it after trying; a read-along mode lights each word as the voice reads; then T01 questions | C-21, C-24 | Questions scored through T01; reading practice unscored. The validator checks every word against the taught grapheme set (lesson-review §3) | pages, grapheme set, tap-to-hear on/off, read-along | 3 (stage 6-7) |
| **LT11** | **Letter tray writing** (later) | An on-screen lowercase letter tray (alphabetical, LTR) to write a word or a short sentence about a picture, free or with a word bank | C-23 (later), creative writing | Constrained items checked against the answer; a free mode is never scored. Free text stays on the device and is never synced (devices send ids and enums only: `CLAUDE.md` security rule 2) | word bank, free or constrained | 4 (after stage 7; optional) |

**New: 11 templates** (LT01-LT11), of which LT11 is optional and later. Built order follows the stages: LT01-LT04 for stage 1, LT05-LT06 for stage 2, LT07-LT08 for stages 3-4, LT09-LT10 for stages 6-7.

## 4. Totals
- **Existing reused: 9** (T01, T02, T03, T04, T05, T14, T16, T18, T21), with the shared needs S1-S8 and the per-template additions in §2.
- **New: 11** (LT01-LT11; LT11 optional).
- **Templates in the catalogue not used by English:** T07 robot path, T08 balance, T09 number line, T10 shape builder, T17 shop and pay (the shop role-play is LT05 with pictures, not coins), and the unbuilt T06, T11-T13, T15, T19, T20, T22-T25 (T24's idea is LT01; T12's voice-first idea waits for owner decision 4).

## 5. Hand-offs this file creates
- **curriculum-expert**: the LT ids and whether LT01-LT10 are shared Languages templates; S7 (course id in the engine).
- **design-director**: S1 (LTR runs in RTL screens), S4 (Latin teaching font and four lines), the layouts of LT01-LT10 on phone and tablet, the mouth pictures for the new sounds.
- **app-developer**: S1-S3, S5, S6, S8 and the templates, after the owner's OK and a milestone plan.
- **voice-and-sound-director**: S3 (two-clip lines) and `voice-brief.md`.
