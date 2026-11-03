# The Russian course: templates needed

*Owner: russian-language-teacher, with the curriculum-expert (shared engine) and the app-developer (code). Draft 2026-11-03. Plan only.*
*What exists was read from `app/lib/play/*_session.dart` (the template sessions) and `docs/curriculum.md` §6.2 (the catalogue). Skill ids are in `docs/languages/russian/syllabus.md`.*

## 1. What every Russian activity needs from the app (cross-cutting)
1. **A Cyrillic font** beside Heebo and Secular One (owner's decision 1; the design-director chooses it; requirements in `voice-brief.md` › Font requirement).
2. **Left-to-right isolated runs** for every Russian word, syllable, tile row and sentence inside the right-to-left screens; tile rows, the syllable slide, the sound-scheme boxes and the vowel strip always run left to right, whatever the app language (as the matching and pattern templates already do).
3. **Split audio**: a Hebrew instruction clip and a Russian target clip, played in sequence (`.claude/skills/pronunciation-spec/SKILL.md` §3). The lesson voice code must queue clips from two voice ids if one voice does not speak both.
4. **Content checks** in the validator: Russian text only Cyrillic (plus U+0301 only where a skill shows stress); ё never replaced by е in Russian text; decodable items use only letters taught (by group, syllabus §3); a stress mark is never on ё.
5. **Russian misconception tags** (syllabus §11) in the misconception catalogue.

## 2. Existing templates that can carry Russian content

| Template (code) | Exists in | Russian use | Skills | Change needed |
|---|---|---|---|---|
| T01 tap the answer (`tap_answer` 1.1) | `app/lib/play/tap_answer_session.dart` | hear a word → tap its picture; hear a sound → tap the letter; letter → picture; same / different; rhyme choice; colour, animal, food | A-01…A-14, A-17, A-19, A-20, B-01…B-07, B-10, B-11, B-18, B-20…B-22, C-01…C-06, C-26, C-29 | **Text answers on tiles in Cyrillic** (a letter, a syllable, a word, a phrase) with the new font, LTR; the prompt can be a Russian clip after the Hebrew clip. Probably content plus a small text-tile option. |
| T02 count and tap (`count_tap` 1.0) | `count_tap_session.dart` | counting in Russian (оди́н, два …) | A-10, A-11 | Russian number clips; nothing else. |
| T03 sort and drag (`sort_drag`) | `sort_drag_session.dart` | sort pictures by first sound, by hard / soft, by мой / моя́ / моё, by syllable count; tidy-up of toys | A-08, B-03, B-10, B-12, B-13, B-16 | Bin labels as Cyrillic text or coloured chips; content only otherwise. |
| T04 trace (`trace`) | `trace_session.dart` (strokes are content: a list of strokes in a 100 × 100 box; `guide: start`; full guide after three mistakes) | trace printed Cyrillic capital and small letters | B-24 | **Stroke data for 66 letter forms** (33 capitals, 33 small; ё and й with their marks as separate strokes). Code: none expected. |
| T05 build the pattern (`build_pattern`) | `build_pattern_session.dart` | copy a shown word with letter tiles (a first step before spelling from sound) | B-25 (scaffold), C-16 (scaffold) | Tiles as Cyrillic letters; content. |
| T14 flash (`flash`) | `flash_session.dart` | **not used** for reading: the flash is about a glance, and reading is never timed. Possibly a "look again" sight-word game later. | — | — |
| T16 match pairs (`match_pairs`) | `match_pairs_session.dart` | capital ↔ small letter; letter ↔ picture; word ↔ picture; word ↔ check word (вода́ ↔ во́ды) | B-18, B-20…B-22, C-01…C-06, C-21 | Faces as Cyrillic text tiles. |
| T21 spot the mistake (`spot_error`) | `spot_error_session.dart` | a friend's wrong tile in a word, a wrong chip in a sound scheme, жы in a word, a misread syllable in a table | B-15, B-25, C-08, C-16, C-18, C-19 | Cells as Cyrillic tiles or chips; content. |

Not used for Russian: T07 robot, T08 balance, T09 number line, T10 shape builder, T17 shop, T18 clock, `give_n` (could later serve "дай мне три я́блока", C-28).

## 3. New templates

| # | Template | What the child does | Skills | Notes for the design-director and app-developer |
|---|---|---|---|---|
| R1 | **Sound scheme** (звукова́я схе́ма; Elkonin boxes) | Hears a word stretched sound by sound; drags a chip into each box; then colours the chips red (vowel), blue (hard), green (soft); later marks the stressed vowel | B-09, B-12…B-17, A-19 (one-box version) | The method's core [ZHU]. Boxes left to right; the picture of the word above; tap-tap for drags. Classifiers: wrong count of sounds; vowel coloured as consonant; soft as hard (M-RUS-HARDSOFT); stress on the last syllable by default (M-RUS-STRESS). |
| R2 | **Syllable slide** (слия́ние) | Drags a consonant tile along a track to a vowel tile; the voice says the consonant as it slides (ммм…) and the merged syllable as they meet (ма); then the child chooses which syllable they heard or which picture it starts | B-19, B-20…B-22, C-01…C-07 | The track always runs left to right. Stops (к, т, п) do not stretch: the voice says only the merged syllable. Classifier: letter-name reading (M-RUS-NAME). |
| R3 | **Vowel strip** | A word or syllable with one vowel place; the child slides a strip of vowel letters (in pairs а–я, о–ё, у–ю, ы–и, э–е) to change the word and hears it (мал → мял, кот → кит) | C-07, B-21 | From Zhurova's vowel strip [ZHU]. Also the hint at level 2 for M-RUS-HARDSOFT. |
| R4 | **Spell with tiles** (разрезна́я а́збука) | Hears a word; builds it from letter tiles (with a few distractor tiles) left to right; a filled slot can be emptied by a tap | B-25, C-16, C-17, C-18, C-19, C-20, C-21, C-22, C-23 | Shares slots and palette with T05, but the model is heard, not shown. Classifiers: reversed order (M-RUS-RTL), ь missing, жы / шы, devoicing, unstressed vowel as heard. |
| R5 | **Read and find** | Reads a syllable, word or sentence shown in Cyrillic (no audio until asked) and taps the picture | B-23, C-09, C-10, C-12, C-13 | Could be a T01 mode (text prompt, picture answers). The "read to me" button is a hint and lowers the credit. Must never be timed. |
| R6 | **Listen and do** (TPR) | Hears a command or a sentence in Russian and makes the friend do it in a scene: tap the action, drag the thing (Положи́ мяч на стол) | A-03, A-04, A-14, B-05, B-06 | A scene with draggable things and two or three action buttons. |
| R7 | **Story reader** | A picture book of 3–10 pages; the voice reads with the words lit as they are read (karaoke); in Band C the child reads first and taps a word to hear it; one or two questions after | A-16, B-08, C-13, C-14, C-30 | Shared reading [MOL]. Word-level timing per clip (the voice director will say whether ElevenLabs timestamps can be used, or it is marked by hand). Questions use T01. |
| R8 | **Say it with me** (echo) | The voice says a word or phrase; a pause for the child; the voice says it again; the child may tap "I said it" | A-15, B-08, C-30, all vocabulary | No recording, no recogniser, no score (syllabus §8). Optional later: a Russian recogniser (owner question 4). |
| R9 | **Sentence builder** | Puts 2–5 word tiles in order to match a picture or a heard sentence; the ending tiles show agreement choices (кра́сный / кра́сная) | B-02, B-07, C-15, C-23, C-24, C-27, C-28 | Tiles left to right; capital and full stop as tiles in C-15. |
| R10 | **Write from memory** | Writes a letter (later a short word) on a blank box with no guide; recognised by comparing strokes with the letter's stroke data | B-26, C-22 | A T04 extension: a `guide: none` mode and a recogniser tolerant of child shapes; the help ladder brings back the start dot, then the full guide. [JAM] is the reason this matters. |
| R11 | **Placement game** | The five staircases of syllabus §7.3 with T01, R4 and R5 items, plus the parent questionnaire in the parent area | placement | Reuses the existing placement frame (`docs/curriculum.md` §10.1) if the engine has one by then. |

## 4. Order of building (proposal for the milestone plan)
1. Font, LTR runs, split audio, validator checks (§1).
2. T01 text tiles, T03, T16 with Russian content: Band A oral and first sound play.
3. R1 sound scheme, R2 syllable slide, T04 letter strokes: Band B core.
4. R4 tiles, R5 read and find, R3 vowel strip: early reading and spelling.
5. R6, R7, R9, R10, R8, R11.

Hand-off: the curriculum-expert decides how these sit in the shared engine for all three languages (the English and Hebrew courses will likely need R1, R2, R4, R5, R7 too).
