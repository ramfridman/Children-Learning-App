# L5-3, L5-4, L5-5: LS03 `boxes`, LS05 `change_part`, LS04 `blend_slide`, layout spec

Owner: design-director. Date: 2026-11-07. Status: **spec for the app-developer** (steps L5-3, L5-4 and L5-5 of `docs/milestones/L5.md`, approved by the owner on 2026-11-06).
Built on: `docs/milestones/L5.md` §4, §5.3, §5.4, §5.5, §5.9 and §9; `docs/languages/frame.md` §2.1 (F1, F2) and §2.3 (LS03, LS04, LS05, the 2-choice rule, free response); the three courses' `templates.md` and `band-b-pilot.md` (the real items: eng B-15 b01 to b03 and B-18.G1 r01 to r05, heb B-19 and B-20 with the S1 wheel, rus B-19 with the boxes, the merge and the strip as a hint); `docs/design/languages-l5-ls01.md` (the zones S and A, the Band B sizes, the reading sizes, the states, the hint grammar and the house rule); `docs/design/languages-l4-layout.md` §5 (the drum); `docs/design-spec.md` §6, §8, §9.2, §9.3, §10; `design/tokens.json`; `app/lib/play/sound_boxes_session.dart`, `choice_row.dart` (`withLs01Zones`, `withTallStage`), `ls01_tiles.dart`, `hint_hand.dart`; the goldens `ls03_drum_*`, `ls03_hands_*`, `ls01r_stem_*`, `ls01r_sort_*`.

Mockups (made by `docs/design/l5/make_l5_templates_mockups.py`, which reuses the L5-1 generator's frame, tiles, fonts and overflow check: real fonts, the app's own pictures, each board at its real size in points, headless Chrome; every sheet prints `bad=0`, no text leaves its box):

| File | What it shows |
|---|---|
| `docs/design/l5/ls03_count_phones.png` | LS03 count step: English phonemes and Hebrew CV units (right to left) on the phone; Russian and a "not yet" on the SE |
| `docs/design/l5/ls03_colour_stress_which_phones.png` | the colour step (Russian кит, рыба), the stress step (рыба), the which-box step (English /n/), phone and SE |
| `docs/design/l5/ls03_tabletLandscape.png`, `ls03_tabletPortrait.png` | the steps on both tablet shapes (colour, which, Hebrew count, stress) |
| `docs/design/l5/ls03_hints.png` | hint level 1 (the word slowly), level 2 (mouth pictures for phonemes; claps for CV units), level 3 (the hand lays a token) |
| `docs/design/l5/ls03_colour_marks_cvd.png` | the three stamps and a coloured scheme seen as drawn, in grey and with deuteranopia, protanopia and tritanopia simulated; the token and place states |
| `docs/design/l5/ls05_wheel_phones.png`, `ls05_wheel_tablets.png` | the Hebrew wheel, `explore` (the S1 wheel, 7 letters, 3 signs) and `make` (B-19.4), all four boards |
| `docs/design/l5/ls05_strip_phones.png`, `ls05_strip_tablets.png` | the Russian vowel strip, `explore` (кот / кит with their pictures; м with а я о ё у ю) and `make` (B-21 ли), all four boards |
| `docs/design/l5/ls05_as_hint.png` | LS05 as level 2 of a decoding item (L5 §5.9): the small wheel in the stem's stage (VOWEL-SKIP, LETTER-MIX), the strip (Russian B-19) |
| `docs/design/l5/ls04_graphemes_phones.png`, `ls04_graphemes_tablets.png` | LS04 `graphemes`: at rest, mid-slide, a digraph bar, after the choice |
| `docs/design/l5/ls04_merge_phones.png`, `ls04_merge_tablets.png` | LS04 `merge`: at rest, sliding, the choice from three sound buttons, joined after the choice |
| `docs/design/l5/ls04_units_l3_phones.png`, `ls04_units_l3_tablets.png` | the Hebrew level-3 demonstration (`units`) inside a decoding item's stem: the friend slides, then points |

Labels in red, dashed zones and dotted hit areas are for the team, never in the app. **Every Hebrew bubble line on the mockups is my sample only** (needs-editor); the words are the teachers' (`band-b-pilot.md`) or stand-ins where the picture is not drawn yet (pot, top, pig for pan, nap, pin).

---

## 1. The spec in one page

1. **The frame and the zones are L5-1's** (`languages-l5-ls01.md` §2): the stage zone S (what the item is about) and the answer zone A (what the child touches), the same boards, the same Band B sizes (tiles 88 / 104, gaps 16 / 24, hit slop 12), the same reading sizes. Two templates add a board of their own: the **wheel** uses the whole left part of the board as one tall stage (a dial does not fit a 148-high stage), and the **slide** puts its knob track inside S.
2. **LS03 `boxes`: the boxes grow with the child's count.** There is a rail with room for 6 places in A (the same for every item at Band B, so it says nothing about the word); a place appears for each token laid, and one dashed "next" place after the last. The tokens come from a **bowl** in S (tap the bowl, or drag a token out); **"that's all"** (the drum's check) sits beside the bowl. The rail never shows how many sounds there are.
3. **The Russian colours are never colour alone.** Each colour has a shape mark, on the stamp and on the chip: **vowel red with a note** (a vowel can be sung, the level-2 test), **hard consonant blue with a square block**, **soft consonant green with a smile** (the level-2 mouth of a soft consonant). Checked in grey and in three simulated colour deficiencies (`ls03_colour_marks_cvd.png`): under deuteranopia red and green become the same olive, and only the note and the smile tell them apart. That is why the marks are not optional.
4. **LS05 Hebrew: one wheel of letters and one row of signs.** A half dial (the classroom wheel standing on its panel) carries the letters; the current letter stands at the top under the pointer; the **unit made is in the hub at the stem size**; the signs are a row of sign beads on the panel. A tap on any part brings it in (the dial turns); a drag turns the dial. Two rings of 56-point beads do not fit a phone (section 4.1 says why), so the signs left the inner ring.
5. **LS05 Russian: the frame card in S, the vowel strip in A.** The vowel in the window is the strip's chosen tile, both framed in lilac; a tap on a tile, or a finger slid along the strip, changes it and the result plays. Vowels are in pair order (а я, о ё, у ю, ы и, э е), each pair on one pale pill, left to right always.
6. **LS04: a knob on a wire.** The word at the slide size, a mark under each part (a dot under one letter, a bar under a digraph or a Hebrew CV unit) threaded on a track, and a sea-coloured **knob** that the finger slides in the course's direction; each part lights and sounds as the knob passes. A tap on the knob slides it by itself (the tap path). Russian `merge` slides the consonant tile itself to the vowel tile. **The choice is the scored part; in a scored item the whole never plays before the choice** (L5 §5.5).
7. **Never "wrong" for sound.** Nothing is red, nothing buzzes; a count off by one hears its tag's line and the tokens go home; a count off by two is a retry with no tag; a sign with no sound (א, בּ, ת with no sign) makes the hub shake gently and plays nothing. Nothing is timed.
8. **The hint ladder** keeps B-40's grammar and the house rule (no option is lit or named before level 3). Where each level is drawn is in section 6; what it shows is the curriculum's (L5 §5.3 to §5.5, the pilots' ladders).

---

## 2. Shared rules

### 2.1 Boards

All values are board points (`BoardClass`): **phone 852 x 393** (landscape), **phone SE 667 x 375** (landscape, the binding board), **tablet landscape 1180 x 820**, **tablet portrait 820 x 1180**. (The brief said "phone 667 x 375"; in this project that is the phone SE; the phone is 852 x 393, `app/lib/design/board.dart`.) The frame's own pieces (controls, trail, the guide and her bubble) are `ActivitySpec` and do not move. **None of these templates has a say step, so the microphone is not drawn**; the zones still end where L5-1 ends them (A to x 605 on the phone and 508 on the SE), so a later voice step can come back without moving anything.

| Board | S (x, y, w, h), as L5-1 | A (x, y, w, h), as L5-1 | Bottom band | Bubble box (ends at most at) |
|---|---|---|---|---|
| Phone | 24, 96, 377, 148 | 24, 252, 581, 117 | 369 | 413, 104, 190, 132 (y 236) |
| Phone SE | 24, 86, 262, 144 | 24, 238, 484, 113 | 351 | 300, 92, 176, 118 (y 210) |
| Tablet landscape | 288, 230, 584, 300 | 194, 554, 772, 242 | 796 | 356, 112, 600, 112 |
| Tablet portrait | 24, 372, 772, 300 | 24, 684, 772, 472 | 1156 | 156, 152, 440, 208 |

For the developer: LS03 and LS04 use **`withLs01Zones(base, band)`** as they are. LS05 adds **`withLs05Board(base, mode)`**: for the wheel, the stage is the board's left part from S's top to the bottom band less 8 (phone 24, 96, 377, 265; SE 24, 86, 270, 257; the tablets as in section 4.1), with the region under the bubble free for the make controls; for the strip it is `withLs01Zones` unchanged.

### 2.2 Sizes (Band B presentation; Bands A and C where the template allows them)

| Piece | Band B phone / SE / tablet | Note |
|---|---|---|
| A place on the LS03 rail | 80 x 88 / 72 x 88 / 104 x 104 (portrait 112 x 112) | the hit areas meet in the gaps: 92 x 112 / 80 x 112 / 120 x 128 |
| An LS03 token | 64 / 56 / 88 (portrait 96) | a circle in its place |
| The bowl, "that's all", the which-step sound | 96, 72, 72 / 80, 64, 64 / 140, 96, 96 | all at least the Band B control (56) |
| A colour stamp | 64 / 56 / 88 (portrait 96) | gaps 16 / 8 / 24 |
| A wheel letter bead, letter size | 60 at 48 pt / 56 at 48 pt / 88 at 64 pt (portrait 96) | the letter at the band's letter size, line height 1.0 (bare letters, no marks) |
| A wheel sign bead | 56 / 56 / 88 (portrait 96) | |
| The wheel's hub card, unit size | 100 x 84 at 46 pt / 80 x 80 at 42 pt / 240 x 150 at 72 pt (portrait 280 x 170 at 80 pt) | never below the band's stem size (42 / 50); line height 1.7 |
| A strip tile (Russian) | 88 / 72 / 104 | letter 48 / 48 / 64 pt; 4 apart inside a pair (6 on tablets), 16 / 12 / 24 between pairs |
| The frame card's cells (Russian) | 88 / 80 / 120 (portrait 128) | letter 48 / 48 / 64 pt |
| The slide size (LS04), English and Russian / Hebrew | 56 / 52 / 96 pt; 46 / 44 / 80 pt | never below the stem size; the tablets' tall stage takes a bigger word, easier to slide under; Hebrew line height 1.7, target 1.3 |
| The slide knob | 56 / 56 / 72 | the Band B control floor; its hit area adds 12 |
| A merge tile (Russian) | 88 / 80 / 120 (portrait 128), track 150 / 86 / 220 (300) | letter 48 / 48 / 64 pt |
| Picture and sound-button options | the L5-1 tiles: 88 / 88 / 104, gap 24 | `ChoiceRow` |

- **Band A presentation** (a 3- or 4-year-old placed on Band B content, frame §3.1): LS03 boxes only (LS04 and LS05 are reading, never under Band A). Places 88 x 96, tokens 72, **a rail of 5** (the SE holds 5 x 88 + 4 x 8 = 472); the validator then needs `answer.count` at most 4.
- **Band C presentation**: places 64 x 80 on the SE (72 x 80 on the phone), tokens 52, **a rail of 7** (7 x 64 + 6 x 6 = 484, the SE's A exactly); `answer.count` at most 6. The slide size is 52 / 48 / 80 (target), 44 / 42 / 64 (Hebrew).
- **The rule for the validator** (with the developer): an LS03 item's `answer.count` is at most the rail's places less one, for every presentation band its course allows (Band B: 5), so that "one more" can always be laid. Russian B-15's longest schemes (5 sounds) fit; a 6-sound word is Band C.

### 2.3 Direction

| Thing | English, Russian | Hebrew course | Why |
|---|---|---|---|
| LS03 rail: the first place, the next place | at the left; it grows to the right | at the right; it grows to the left | F1 (`rowDirectionOf`) |
| LS03 stage: the picture | at S's start (left) | at S's start (right) | the word first, then what to do with it |
| LS05 wheel: the next letter in reading order | | towards the left of the top | the dial turns the way a Hebrew row reads |
| LS05 sign row | | first sign at the right | F1 |
| LS05 strip and frame card | left to right, always (Russian) | | rus `templates.md`: "the vowel strip always runs left to right" |
| LS04 track, arrow, knob's rest | the knob rests at the left, the arrow points right | the knob rests at the right, the arrow points left | the slide is the reading direction; **the arrow is a reading arrow of the course, not a UI arrow**, so the app's right-to-left UI never flips it |
| LS04 `merge` | the consonant tile at the left slides right | | always left to right |
| Option rows | as L5-1 | | |
| The bubble, the guide, the controls | right to left, as everywhere | | the UI is Hebrew |

For the developer: each of these widgets builds its row inside a `Directionality` of the **course** (left to right for `eng` and `rus`), not the app's ambient right to left, so a `Row` is never flipped twice. English and Russian text are isolated runs (`TargetText`), Hebrew course text is `CourseText` with line height 1.7 whenever a mark is present.

### 2.4 States and feedback (shapes as well as colours)

The L5-1 states (idle, lit, chosen, not yet, correct, shown) hold, with these additions (see `ls03_colour_marks_cvd.png`):

| State | What it looks like | Cue that is not colour | Timing (Band B base 350 ms) |
|---|---|---|---|
| **next place** (LS03) | a dashed `lilacDeep` 3 pt box, half-white | dashed against solid | appears 120 ms after a token lands |
| **laid** (LS03) | a white place, `hairline` 4, the clay lip, the token in it | the token | the token flies from the bowl on an arc in 280 ms; a soft "tok" on landing (≤ 50 ms, the voice-and-sound-director's sound) |
| **stamped** (LS03 colour) | the chip filled with its colour and its white mark | the mark | the colour spreads from the centre in 220 ms, the mark pops (scale 0 to 1.1 to 1) |
| **stress** (LS03) | an `ink` stress sign (a slanted bar 7 pt thick) above the place | the sign | drawn in 200 ms |
| **current** (LS05) | the wheel's letter at the top in a `lilacDeep` 5 pt ring under the pointer; a sign bead or strip tile lifted 5 with a `lilacDeep` ring; the hub card or window framed `lilacDeep` | position and ring | |
| **sounding** (LS04) | a `skyTint` column behind the part and its mark, the mark grown and `skyDeep` | the column and the bigger mark | while the part's clip plays |
| **passed** (LS04) | the mark stays `skyDeep` | | until the slide ends |
| **shake** (LS05, a unit with no sound) | the hub card swings ±3 degrees twice | motion | 300 ms; reduce-motion: a lilac border for 400 ms |

- **Correct**: the L5-1 correct state (spark fill, check badge), the tier-1 celebration, the solved item stays in view.
- **Not yet**: the L5-1 wobble (6 pt, 360 ms) and the lilac ring, then the pieces go home on an arc (400 ms). **No red, no buzzer, no cross, ever.** A sound or a count is never called wrong; the tag's line says what to listen for.
- **Reduce motion**: every flight becomes a fade in place (200 ms), the dial jumps to its new place with a 150 ms fade, the knob still follows the finger (it is the child's own movement), the auto-slide shows each part lit in turn without the knob moving.
- **Pending clips** (L5 §7, every clip is pending today): a pending clip is silent and the template waits the fixed pause (L4 D-5); every part, unit and sound **still lights in turn**, so every screen plays and can be tested with every clip pending.

---

## 3. LS03 sound boxes, mode `boxes` (L5-3)

**What the child must understand without reading:** "here is the word (the picture); put one token in for each sound (or part) you hear; tell me when you're done." Then, by the item's steps: "colour each one", "which one is the strong one?", "where is this sound?". The one obvious next step is always lit by the instruction's own target: the bowl at the count step, the stamps at the colour step, the raised vowels at the stress step, the sound button at the which step.

### 3.1 Layout per board (laid out for a left-to-right course; the Hebrew course mirrors every x inside its zone)

| Board | Picture (start of S) | Count step: bowl, "that's all" | Colour step: picture, stamps (vowel, hard, soft) | Which step: the sound | Rail in A |
|---|---|---|---|---|---|
| Phone | 30, 110, 120 | 211, 122, 96; 323, 134, 72 | picture 120; stamps from x 171, y 138, 64, gap 16 | 323, 134, 72 | 6 places of 80 x 88, gap 12, from x 44 (total 540), y 264; tokens 64 |
| Phone SE | 30, 114, 88 | 126, 118, 80; 216, 126, 64 | **the picture shrinks to 56** (30, 130); stamps from x 96, y 130, 56, gap 8 | 216, 126, 64 | 6 of 72 x 88, gap 8, from x 30 (472), y 250; tokens 56 |
| Tablet landscape | 304, 280, 200 | 596, 310, 140; 760, 332, 96 | stamps from x 544, y 336, 88, gap 24 | 760, 332, 96 | 6 of 104 x 104, gap 16, from x 228 (704), y 566; tokens 88 |
| Tablet portrait | 40, 412, 220 | 492, 442, 160; 684, 450, 96 | stamps from x 428, y 474, 96, gap 32 | 684, 450, 96 | 6 of 112 x 112, gap 16, from x 34 (752), y 700; tokens 96 |

- **The picture** is the word's sprite on a white card (radius 20, the clay lip) with a small speaker badge at its corner; a touch on it plays the word again (the replay). It never leaves the stage while the item is on screen.
- **The rail** is a soft `mist` groove (radius 24) the width of 6 places, behind the places, so the child sees where tokens go without seeing how many. A place exists only for a token laid; the dashed next place stands after the last; with 6 laid there is no next place (the rail is full, and the bowl does nothing more, with no sound of refusal).
- **The tokens** are plain counters in a warm tan (`#F2C894` with a `#C98B4E` rim and a white inner ring; **a new token, `color.languages.token`**, for the developer to add): not one of the scheme's three colours, not a feedback colour, so a tan token means "not coloured yet". The ink-ringed white token I drew first read as the letter o; I changed it.
- **The bowl** is a shallow bowl seen from the front with three tokens in it and its rim in front of them (drawn in code as a shape, `ls03_count_phones.png`); it never empties.

### 3.2 The count step

- **Playing:** a tap on the bowl sends one token on an arc to the next place; a drag takes a token out of the bowl, and a drop anywhere on the rail (snap radius 1.25 x the place, Band B) lands it in the next place; a drop elsewhere floats it home with no sound. A tap on any laid token takes one back (the last place empties: tokens are all alike, so the strip simply shortens from its end). Laying a token plays only the "tok", **never the unit's own clip** (it would tell the child when to stop).
- **"That's all"** (the drum's check pebble) checks the count. It does nothing with no token laid. With `controller.guided` and a wrong count, the tokens go home without a check (as the drum does).
- **Right:** the places light one after another from the start, each with its unit clip (or the fixed pause when pending), then the check badge on the last place; then the next step comes in (the bowl and "that's all" fade out in 280 ms, the next step's tools fade in, the bubble says the next line). The tokens stay where they are.
- **One more or one fewer:** the tag's line (from `classify`), the rail wobbles once, all tokens go home; the child lays them again. **Off by two or more:** the same motion, the line "let's listen again" (no tag), no evidence (frame §2.3). In a probe the one answer is written either way, as the drum does.
- **Response:** the count, `n=3` (the rest of the code is added by the later steps: `n=3.c=brb.s=1.w=2`).

### 3.3 The colour step (Russian only)

- The tokens stay in their places, still tan. Three **stamps** stand in S, always in this order from the course's start: **vowel (red, a note)**, **hard (blue, a square)**, **soft (green, a smile)**. The order is the order of the Russian sound-scheme teaching (vowels first), and it never changes between items, so the place is a cue too.
- **Playing (tap-then-tap, both ways):** tap a stamp (chosen: lifted, the ink ring), then tap chips to stamp them, one after another; or tap a chip (chosen), then a stamp. A drag of a stamp onto a chip also stamps it. A stamped chip can be stamped again with another colour.
- **The step checks itself when every chip has a colour** (as tap-all does, L5-1 §7.7): the wrongly coloured chips wobble and turn tan again, the right ones keep their colour, and the child stamps again. The tags come from `classify` (a vowel coloured as a consonant → `M-RUS-VOWEL-CONS`; soft for hard or the reverse → `M-RUS-HARDSOFT`).
- **The marks** (white, 0.62 of the chip; drawn as shapes, never a font glyph): the note (a filled head and stem with one flag), the square (a rounded block), the smile (an arc, 12 of 100 thick, round caps). They stand out in grey and under every simulation (`ls03_colour_marks_cvd.png`). A stamp also speaks its kind when touched for the first time in an activity ("a vowel", "hard", "soft": three short Hebrew lines for the hebrew-text-editor, voiced like every line).
- **Response:** the colour letters in place order, `c=gr b`-style: `r` vowel, `b` hard, `g` soft (as L5 §5.3: `c=brb`).

### 3.4 The stress step (Russian B-17, only in a skill flagged `stress`)

- The chips keep their colours. **Only the vowel chips are raised** (lifted 5, the clay lip); the consonant chips rest at 40% opacity and are not targets. A tap on a vowel chip puts the stress sign over its place (the Russian school's mark, above the scheme, not on the letter); the step checks on that tap. Not yet: the sign fades, the chip wobbles; `M-RUS-STRESS` when the last syllable was chosen.
- Why only the vowels are targets: stress sits on a vowel, and the child is not asked that here; a tap on a consonant could only be a slip. The scheme stays fully visible.
- **Response:** `s=` the place number (1 based).

### 3.5 The which-box step (all three courses)

- S holds the picture and **the sound to find** (a sky speaker pebble at the step's tool place); the bubble's carrier line plays, then the sound's clip; a touch on the pebble plays the sound again.
- Every place is a target (its place and token together); a tap checks. Not yet: the place wobbles; the tag comes from `classify` (`which=3` → `M-ENG-DIR` and `M-RUS-NOTFIRST` in the pilots).
- **Response:** `w=` the place number, counted from the course's start (so `w=1` is the right-most place in Hebrew).

### 3.6 Hints (LS03)

| Step | Level 1 (look here) | Level 2 (another way) | Level 3 (watch me, then you) |
|---|---|---|---|
| count | the picture lights (sky ring) and the slow clip plays (`word.slow`: units stretched with pauses) | **a sky card over S**, one card per unit, each lighting as its unit plays: **syllable and CV units: a pair of clapping hands**; **phonemes: the mouth picture of the sound** (L5 §5.3). The card covers S only while it plays (about 1 s per unit), then fades; the rail is never touched | the hand takes a token from the bowl to the next place as each unit plays, then touches "that's all"; then the tokens go home and the child does it |
| colour | each chip lights in turn, left to right, with its sound | the "can you sing it?" card over S: the lit chip's sound with its mouth picture beside one of the three marks (an open singing mouth and the note; closed lips and the square; the smile and the smile) | the hand stamps the first wrong chip; the child does the rest |
| stress | the word slowly, the vowels lit in turn | the friend "calls from far away" (L5 §5.3): Nitzi in the sky card with her hands at her mouth, the word called with its stress drawn out; no place is lit | the hand puts the sign over the stressed vowel |
| which | the sound to find plays again, the speaker pebble lit | the tokens light one by one with their sounds in the course's direction (the pilots' HL-BOXES), and the sound to find again after them | the hand taps the right place |

- **The mouth pictures**: the app has seven (`mouth-lips`, `-round`, `-smile`, `-teeth`, `-tongue`, `-trill`, `-puzzled`, drawn earlier from articulation references). The mockup uses teeth for /s/, round for /ʌ/ and tongue for /n/ in "sun". **Still missing** for the Band B pilots: an open jaw for /æ/ and /a/ (а), lips pressed for /p/ /b/ /m/ (lips is close: lips together but relaxed), and the lower lip under the teeth for /f/ /v/ (ENG-2a, B-11). Each is a picture by id (`mouth-open`, `mouth-press`, `mouth-bite`), drawn from photographs as the seven were; I add them with ENG-2a's pictures. A unit whose mouth picture does not exist shows the token lit alone (never a wrong mouth).
- **The clapping hands** are `hand_left_5.svg` and `hand_right_5.svg` turned towards each other (the drum's hands are icons; the developer may reuse the drum's widget).

### 3.7 Not in this template

`drum` stays as built (L4 §5). Letters on the tokens (Hebrew from B-09, frame LS03 "later") are not drawn: when they come, the letter sits on the token at the letter size and the token grows to the place.

---

## 4. LS05 change one part (L5-4)

### 4.1 The Hebrew wheel (*גלגל סימני ניקוד*)

**What the child must understand:** "these letters go round; these are the signs; the letter at the top with the sign I pick makes the sound in the middle." In `explore` every turn plays; in `make` the child turns until it sounds like the voice, then says "that's it".

**Why one ring and a row** (and not the classroom tool's two rings): two concentric rings of 56-point beads with 5 signs on the inner ring need a ring of radius 148 (inner 84, 45 degrees apart, plus a bead and a gap), a dial 352 wide and 210 tall above its centre; the phone's stage is 265 tall but its result would have nowhere to go, and the SE's (270 wide) cannot hold it at all. The signs are fewer and simpler than the letters, so they lie on the panel as a row, and the hub is free for the result at the stem size. The wheel is still a wheel: the letters go round, and the parts that turn past the panel come back on the other side.

| Board | Dial centre (x, y), ring radius | Letter bead (size, letter) | Step | Hub card (w x h, unit size) | Sign row (bead, top, gap) | Make: target, "that's it" |
|---|---|---|---|---|---|---|
| Phone | 212, 270; r 136 | 60, 48 pt | 30 deg (7 slots) | 100 x 84, 46 pt | 56, y 284, 16 | 429, 262, 72; 521, 262, 72 (under the bubble) |
| Phone SE | 190, 270; r 120 | 56, 48 pt | 30 deg | 80 x 80, 42 pt | 56, y 288, 8 | 352, 262, 64; 436, 262, 64 |
| Tablet landscape | 560, 600; r 250 | 88, 64 pt | 30 deg | 240 x 150, 72 pt | 88, y 624, 24 | 272, 664, 96; 752, 664, 96 (the panel's ends) |
| Tablet portrait | 410, 830; r 300 | 96, 64 pt | 30 deg | 280 x 170, 80 pt | 96, y 860, 24 | 112, 1000, 96; 612, 1000, 96 |

- **The dial** is the top half of a white disc (`hairline` 4, an inner cream band where the beads run, a faint `mist` ring line through their centres) standing on a `mist` **panel** with the clay lip that runs to the bottom band less 8. The lower half is "behind the panel".
- **The current letter** stands at the top (90 degrees) in a `lilacDeep` 5 pt ring under an ink pointer; a dashed `lilacDeep` line runs from it down to the hub: "this letter and this sign make this". The next letters in reading order stand towards the left (Hebrew), the earlier ones to the right, 30 degrees apart; a wheel with 7 letters or more is a loop (all 7 visible on every board), a shorter one only shifts its letters.
- **The hub card** (white, `lilacDeep` 4, radius 22) shows the composed unit (the letter with its sign, typeset by Heebo, line height 1.7) at no less than the stem size; a touch on it plays the unit.
- **The sign row** (first sign at the right): each sign bead shows a dashed box (where a letter goes) with the sign under it, **drawn as a shape** (qamats a small T, patah a bar, hiriq a dot; "no sign" the box alone). Never a lone combining mark in a font: a mark with no base is drawn differently, or as a dotted circle, by different text engines. The current sign is lifted with a `lilacDeep` ring.
- **Holds** at most 8 letters (all visible to 7) and up to 5 signs on the phones in one row (5 x 56 + 4 x 12 = 328, inside the panel); the SE holds 4 signs in its row (4 x 56 + 3 x 8 = 248). Band B's widest wheel is S3 (a: ָ ַ, i: ִ, shva: ְ, and no sign = 5), so the SE's S3 wheel moves "no sign" onto the letter ring's panel end, or the S3 teaching screen shows 4 signs: **a question for the curriculum-expert** (section 9). `make` has at most 4 parts in all (L5 §5.4): always visible.
- **Playing:** a tap on a letter turns the dial until it is at the top (350 ms, spring-out with overshoot 1.04; the result plays when the turn ends); a one-finger drag along the dial turns it with the finger and snaps to the nearest letter on release (the drag is optional, the tap is the path); a tap on a sign bead lifts it and the hub changes. **A unit with no sound** (א, בּ, ת with no sign, heb pilot §14 item 5): the hub shows the bare letter, shakes gently and plays nothing.
- **`explore`** (unscored): no check and no target; every change plays its result (`parts[].result.clip`). The bubble's line invites turning; the guide waits. Nothing is written (L5 §10 item 4).
- **`make`** (scored): the target plays after the instruction (the bubble line, then the unit). **The bubble shows the carrier line only, never the target's text** (written, it would make the item a matching task; my first mockup wrote it, corrected); **the target pebble** (sky, the speaker) plays it again; **"that's it"** (the check pebble) answers with the current parts. Right: the hub turns correct (spark, the check badge), the result plays once more. Not yet: the hub wobbles, the tag's line (the chosen distractor part's tag), and the wheel stays where it is (the child goes on from there).
- **Response:** the part ids, `p1.p4`.
- **The make controls** sit under the bubble on the phones (that region is free below y 236 / 210 and left of the guide), at the panel's two ends on the tablets.
- **The bubble line on the SE must stay at 2 lines**: the dial's 30-degree bead stands at y 182 under the bubble's third line. A note for the hebrew-text-editor (section 9).

**Hints (make):** level 1, the target again and then the child's current result (L5 §5.4), the hub lit; level 2, the key-word picture whose first unit it is (heb) appears in a sky card at S's free corner (under the bubble on the phones, beside the dial on the tablets), the target unit lit in it; level 3, the hand turns the dial to the right letter and taps the right sign, the result plays, then the wheel turns back and the child makes it.

### 4.2 The wheel as level 2 of a Hebrew decoding item (L5 §5.9, `ls05_as_hint.png`)

- It **takes S's place** in the text stem (L5-1 §7.8), inside a sky card, and the options in A stay live: a touch on an option answers.
- **Small and with only the part that changes:** the letters for LETTER-MIX (the chosen letter and the target, under a fixed ָ), the signs for VOWEL-SKIP (no sign and ָ, under the fixed letter). The ring then carries letters or sign beads. The unit made stands beside it at the stem size in a `lilacDeep` card.
- Sizes: phone ring r 70, beads 48 (letters 34 pt), 45 degrees; SE r 54, beads 40 (30 pt), 50 degrees; tablets r 140, beads 76 (52 pt). These beads are not answer targets (the friend turns the wheel; a touch on the unit card plays it again), so they may be below the control floor.
- **Motion:** the friend's hand turns it from the child's choice to the target, each position heard, then back to the target, which stays; about 2.5 s; then the bubble's line asks again.

### 4.3 The Russian vowel strip (*слоговое окошко*)

**What the child must understand:** "this is the word with a window; the vowels below go in the window; slide along them and hear the word change."

| Board | Frame card in S (cells, letters), centred | Strip in A (tiles, inside a pair, between pairs), y | Make: target, "that's it" in A | Explore: the word's picture in A |
|---|---|---|---|---|
| Phone | 88, 48 pt | 88; 4; 16; y 264 | 72 at A's start and end (x 32 and 525), y 272 | 88 at A's end |
| Phone SE | 80, 48 pt | 72; 4; 12; y 254 | 56 at x 32 and 444, y 262 | 72 at A's end |
| Tablet landscape | 120, 64 pt | 104; 6; 24; y 566 | 96 | 140 |
| Tablet portrait | 128, 64 pt | 104; 6; 24; y 700 | 96 | 160 |

- **The frame card** (white, an ink 4 pt border, radius 22, the clay lip) holds the frame's letters in cells, and the **window**: a `lilacDeep` 5 pt framed cell with a pale lilac fill showing the current vowel. A touch on the card plays the current result.
- **The strip**: the item's vowel parts in pair order (а я, о ё, у ю, ы и, э е; only the parts the item has), a pair on one pale `mist` pill, 4 pt apart inside a pair and 16 between pairs, so the hard-soft pairs read as pairs. The current tile is lifted with the same `lilacDeep` ring as the window. **The strip never hides a vowel behind the frame** (my first drawing slid the strip behind the card, and the neighbours of the window were hidden: changed).
- **Playing:** a tap on a tile makes it current (it lifts, the window's vowel changes with a 120 ms fade) and the result plays. **A finger slid along the strip** ("slide and listen") makes each tile current as it passes; the result plays for the tile the finger rests on (no new tile for 200 ms) or lifts from, so a fast slide does not stack clips. This is the slide of the classroom strip, and it is optional.
- **`explore`**: every change plays; a result that is a word with a picture (`parts[].result.sprite`, кот / кит) shows that picture at A's end side, which changes with it (meaning changes with one letter). `make`: the target pebble at A's start, "that's it" at A's end, the strip between; scored as the wheel.
- **Response:** the part ids.
- **English** (Band C, optional, L5 §5.4): the same strip widget with Latin tiles (pan, pen, pin: a, e, i). "Add the e" is a frame with an empty end cell and a strip of one tile ("e") and an empty tile ("no e"). Not drawn now.

**Hints (make):** level 1, the target again and then the current result, the card lit; level 2, the mouth picture (a smile for a soft consonant, L5 §5.4) in a sky card at the free corner of S; level 3, the hand slides to the right tile, the result plays, the strip goes back, the child makes it.

**As level 2 of a Russian decoding item** (rus B-19 hint, `ls05_as_hint.png`, third board): in S's sky card the frame card (cells 52, 36 pt; 96 and 56 pt on tablets) stands above the strip (tiles 48; 84 on tablets), both centred; these are shown, not answer targets; the friend's hand slides а, о, у under м and each is heard (FB27); the options in A stay live.

---

## 5. LS04 blend slide (L5-5)

**What the child must understand:** "slide the green-blue button under the word in the direction of the arrow, and the word says its sounds; then touch its picture." The one obvious next step at the start is the knob; at the first item of an activity the knob gives two soft pulses (not a hint level, just the affordance; never again in that activity).

### 5.1 `graphemes` (English) and `units` (Hebrew): the knob on a wire

- **The page** is S's inner area, white, radius 20. On it: the word at the **slide size** (section 2.2), typeset whole (letters never spaced apart, so the child reads the real word), centred; under it the **track**, an 8 pt `mist` wire (10 on tablets) from the knob's rest to an arrowhead (`inkSoft`) past the word's end; on the wire **a mark under each part**: a 16 pt dot (`inkSoft`, white rim) under a one-letter part, a 14 pt bar under a digraph (sh, ck) or a Hebrew CV unit (the unit's width less 12). The parts' boxes come from the shaped text (`TextPainter.getBoxesForSelection` per part), never from equal shares.
- **The knob**: a 56 pt `sea` disc (72 on tablets) with the `seaDeep` clay lip and a white chevron in the course's direction, resting 0.75 knob before the word's start. Its hit area adds 12. The vertical budget on the phone: line 73 (56 x 1.3) + 2 + knob 56 = 131 of S's inner 136; Hebrew 46 x 1.7 = 78 + 2 + 56 = 136.
- **Playing:** the child drags the knob along the wire (one finger; only the movement along the track counts, up to 40 pt off it). When the knob's centre enters a part's span, that part **sounds and lights** (the sounding state). A stretched part (`stretch: true`, a continuant) keeps sounding until the next part starts (the next clip starts with a 60 ms cross-fade; the voice-and-sound-director sets the fade); a clipped stop plays whole. Moving back plays nothing (the knob can go back). On release the knob glides home in 400 ms; marks passed stay `skyDeep` until the next slide.
- **The tap path:** a tap on the knob slides it by itself at the slow pace (each part for its clip's length, or 700 ms when pending).
- **From the wrong end:** a drag that starts at the arrow end and moves back plays nothing; the knob gives two pulses. No line, no evidence: the slide is practice.
- **The choice** is the L5-1 row in A (pictures for English and Hebrew, `ChoiceRow`); it is live from the start (the tap path always works). **In a scored item only the parts play before the choice; the whole plays after it** (L5 §5.5), and after any choice, as the pilots' ladders say. A part with no clip lights in silence and the stretched whole is the level-1 replay (credit 0.8, L5 §5.5).
- **Response:** the option, as `tap_answer`. The slides write nothing.

### 5.2 `merge` (Russian)

- **S** holds two tiles on a track: the first part (the consonant of ма, the vowel of ом) at the left, the second at the right, a dashed `lilacDeep` track with an arrow between them (phone 88 tiles, track 150; SE 80, 86; tablets 120, 220 / 128, 300). The first tile carries a short `sea` grip under it (the same colour as the slide knob: "this is what you move").
- **Playing:** the child drags the first tile to the second; during the drag the held part plays (`snd-m` stretched, "ммм…"; a stop is silent while it moves); when the tiles meet (within 12 pt) the second part sounds; in a teaching screen and at level 3 the merged syllable (`mg-ma`) plays instead. A `sea` stretch line under the moving tile shows the held sound. A tap on the first tile slides it by itself. On release before meeting, the tile glides back. After meeting, the tiles stay touching.
- **The choice:** three sound buttons in A (LS01 (c): the speaker on a tile, the "heard" waves once played). **The merged syllable plays only after the choice** (L5 §5.5); then the two tiles join into one tile (280 ms) and it plays.
- Always left to right (rus `templates.md`).

### 5.3 The Hebrew level-3 demonstration (`units` inside a decoding item, `ls04_units_l3_*.png`)

The "show me" of every Hebrew decoding item (L5 §5.9, heb `templates.md` §3):
1. The stem page **becomes the slide page** in place (280 ms): the word grows from the stem size to the slide size, the unit bars and the track appear under it, the knob at its right-hand rest. The options in A stay where they are.
2. **The friend's hand drags the knob from right to left** at the slow pace; each CV unit lights (the sky column) as its clip plays (a final ָה lights as one unit with its letter, heb pilot §5.8); then the whole word plays and the bars join into one bar under the word (`ls04_units_l3_*.png`, the second board of each).
3. The hand moves to the right picture and taps it; the halo stays on it (B-40 level 3), and the child taps it.
About 4 s with clips, about 3 s pending. The same page serves the English re-teach of `M-ENG-DIR` (level 2 of an English stem: the slide with each sound lit, `graphemes`) and the stand-alone `units` items of Band C.

### 5.4 Hints (LS04)

| Mode | Level 1 | Level 2 | Level 3 |
|---|---|---|---|
| graphemes | the knob slides by itself slowly, each part lit as it sounds (the parts only, never the whole) | a sky card over S: each sound as a token with its mouth picture, left to right (the LS03 level-2 card); for `M-ENG-DIR` the start dot lit and the left-start line first | the hand slides, the whole plays, the hand points to the picture (halo stays) |
| merge | the tile slides by itself slowly, the held part and the second part | the vowel strip (section 4.3, compact) in S; for a NAME error the name and the sound lines first | the hand slides, the merged syllable plays, the hand points to the sound button |
| units | the knob slides by itself slowly | the small wheel on the unit missed (section 4.2) | section 5.3 |

---

## 6. Hints: where each level is drawn (summary)

| Template | Level 1 (look here) | Level 2 (another way) | Level 3 (watch me, then you) |
|---|---|---|---|
| LS03 count | the picture lit, the word slowly | the sky card over S: claps (syllable, CV) or mouths (phoneme), one card per unit | the hand lays the tokens, touches "that's all" |
| LS03 colour | the chips lit in turn with their sounds | "can you sing it?" with the mouth and the mark | the hand stamps the first wrong chip |
| LS03 stress | the vowels lit in turn | the friend calls the word from far away | the hand puts the stress sign |
| LS03 which | the sound pebble lit | the tokens lit in turn with their sounds | the hand taps the place |
| LS05 wheel, make | the target, then the current result | the key-word picture in a sky card | the hand turns and taps, then the child |
| LS05 strip, make | the target, then the current result | the mouth (smile for soft) in a sky card | the hand slides, then the child |
| LS04 | the slow auto-slide, parts only | mouths / the strip / the small wheel | the hand slides, the whole, the hand points |

While any hint shows, the hint pebble wears its sky ring (B-40). The house rule holds: no option, place or tile is lit or named as the answer before level 3. In LS03 the places the child laid are her own work, not options; lighting them in turn at level 1 and 2 of the colour and which steps names none of them.

---

## 7. Per device: what changes and what does not

- **Phone:** LS03 and LS04 in S and A (L5-1 zones); the wheel on the left two-thirds with the make controls under the bubble; the strip's frame in S and the strip in A.
- **Phone SE:** the binding board. LS03's rail of 6 places is 72 wide each and the colour step's picture shrinks to 56 so the three stamps fit at 56; the wheel's hub is 80 x 80; the bubble line of LS05 must stay at 2 lines.
- **Tablet landscape:** S is the card as today; the LS03 rail and the LS04 options are centred under it in A; the wheel stands across S and A (its panel at y 600 to 796).
- **Tablet portrait:** as the landscape, more room under A; the wheel's centre at y 830.
- **Split screen:** the board follows the window (`boardClassFor`), as everywhere.

---

## 8. For the app-developer (the build list)

1. **LS03 `boxes`** in `sound_boxes_session.dart` (or a sibling `sound_boxes_boxes.dart`): the rail with its growing places, the dashed next place, the bowl, "that's all" (reuse the drum's check), the steps in the item's order, the stamps with their marks (`ls03_marks.dart`: the three marks as `CustomPainter` shapes, sizes as section 3.3), the stress sign, the which-step sound pebble; the placements of section 3.1 as a `_BoxesZones` table per `BoardClass`, mirrored for Hebrew; the response code `n=…c=…s=…w=…`. The token colour as a new token in `design/tokens.json` (`color.languages.token`: value `#F2C894`, lip `#C98B4E`), through `tool/gen_tokens.dart`.
2. **LS05 `change_part`**: `withLs05Board`; the dial (`CustomPainter` for the half disc and panel, beads as widgets on the ring, the turn as an `AnimationController` on the angle), the hub card, the sign row with signs drawn as shapes (`sign_marks.dart`); the strip (`frame card` + `strip row`, the scrub with the 200 ms rest rule); `explore` writes nothing; `make` with the target and "that's it".
3. **The hint-borrowing mechanism** (L5 §5.9): `hints.level2.show` / `level3.show` opens the small wheel, the compact strip or the slide page inside S of the borrowing item, with the options in A live; one widget each, shared with the full templates.
4. **LS04 `blend_slide`**: the slide page (the word, the marks from the shaped text's part boxes, the wire, the knob and its drag along one axis, the tap auto-slide), `merge` (the moving tile, the join), the choice row; the whole only after the choice in a scored item; silent lighting for a part with no clip.
5. **Direction:** each row built inside the course's `Directionality` (section 2.3).
6. **Goldens** on the four boards, at Band B, each in the courses it serves: LS03 count (eng, heb), colour (rus), stress (rus), which (eng), a "not yet"; LS03 at Band A on the SE (rail of 5) and Band C on the SE (rail of 7); the wheel `explore` and `make` (heb); the strip `explore` and `make` (rus); LS04 `graphemes` at rest and mid-slide (eng), `merge` (rus), the level-3 demonstration (heb); the small wheel and the compact strip as level 2 in a stem. Look at each as a picture.

---

## 9. Hand-offs

- **app-developer:** section 8, from this file, the mockups and their generator.
- **curriculum-expert** (please confirm or change; each is drawn as I recommend):
  1. **LS03's count step grows its boxes** (a rail of 6 at Band B with no empty boxes shown) rather than showing a row of empty boxes: shown boxes would give the count away and make the count step a matching task.
  2. **Laying a token plays only a "tok"**, never the unit's sound; the units are heard when the count is right, and in the hints.
  3. **The colour step checks itself** when every chip has a colour (as tap-all), the wrong chips go back to tan.
  4. **The stress step makes only the vowels targets.**
  5. **The marks**: vowel = a note, hard = a square, soft = a smile (tied to the level-2 tests). Please ask the russian-language-teacher whether a Russian kindergarten child would read them that way; the colours stay the school's.
  6. **The Hebrew wheel is one ring of letters and a row of signs** (section 4.1), not two rings.
  7. **The SE's S3 wheel** (5 signs): "no sign" at the panel's end, or 4 signs on the S3 teaching screen? (Band B's S3 is shva, B-23.)
  8. The S1 wheel of the Hebrew pilot has 7 letters and 3 signs (10 parts) in `explore`, while L5 §5.4's validator says `explore` up to 6 parts: I drew the pilot's 10 (they fit: 7 on the ring, 3 in the row). Please settle the number (I suggest: up to 8 letters and 5 signs).
  9. For `merge` with a stop (т, к): in a scored item the tile moves in silence and only the vowel sounds on meeting (the data's clips decide). Please confirm.
- **hebrew-text-editor:** the bubble lines on the mockups are my samples (needs-editor): עִגּוּל לְכָל צְלִיל., עִגּוּל לְכָל חֵלֶק., צִבְעוּ אֶת הָעִגּוּלִים., אֵיזֶה צְלִיל חָזָק?, בְּאֵיזוֹ קֻפְסָה הַצְּלִיל?, סוֹבְבוּ אֶת הַגַּלְגַּל, וְהַקְשִׁיבוּ., סוֹבְבוּ עַד שֶׁתִּשְׁמְעוּ:, הַזִּיזוּ אֶת הַפַּס, וְהַקְשִׁיבוּ., עֲשׂוּ אֶת מָה שֶׁשְּׁמַעְתֶּם., הַחְלִיקוּ מִשְּׂמֹאל לְיָמִין., אֵיזוֹ מִלָּה זֹאת?, הַחְלִיקוּ לְפִי הַחֵץ., מָה שְׁמַעְתֶּם?, תִּרְאוּ אֵיךְ., הִסְתַּכְּלוּ עַל הַפֶּה., מוֹחֲאִים כַּפַּיִם., הַקְשִׁיבוּ לְאַט. The pilots' own lines win where they exist. Three short new lines are needed for the stamps (a vowel, hard, soft, section 3.3). On the phone SE an LS05 line must fit 2 lines of the bubble (section 4.1).
- **voice-and-sound-director:** the timings of sections 2.4, 3.2, 4.1, 4.3 and 5.1 to agree: the "tok" of a laid token and of a stamp, the cross-fade of a stretched part into the next (60 ms proposed), the 200 ms rest before a scrubbed strip tile plays, the slow auto-slide pace (a part's clip, or 700 ms pending), the shake of a unit with no sound (no sound at all).
- **qa-engineer:** once the developer is done: the four boards for each template and step, the direction table (section 2.3), nothing clipped (nikud in the hub and on the slide, the Russian ё and й on tiles, the English descender of p), the hit areas inside their zones and never overlapping, the rail never showing a count, the greyscale check of the colour step, every template playable with every clip pending.
- **Needs the owner:** nothing to decide (the plan leaves none of these choices to him). If he wants to see it: `docs/design/l5/ls03_colour_stress_which_phones.png`, `ls05_wheel_phones.png`, `ls04_graphemes_phones.png` (the phone is the top-left board of each).

---

## 10. What I looked at, and what I did not

- **References** (before drawing, 2026-11-07; looked at and read, nothing copied or traced; the list is also at the top of the generator): Elkonin boxes (Wikipedia; understood.org; readingvine.com; the iOS app "Elkonin Boxes"); the Russian sound scheme (kindergarten guides for teachers and parents: red vowel, blue hard, green soft, the stress sign or a bell); the Russian vowel chart and the syllable window strips (image search, "слоговое окошко лента гласных": а о у ы э over я ё ю и е); the printed Hebrew nikud wheels (image search, "גלגל ניקוד אותיות": letters on the outer disc, signs on the inner one, read at a window; the coloured "spin the wheel" sector wheels noted as a look to avoid, a prize wheel being about chance); English phonics sound buttons (dots and bars under CVC words, then a sweep to blend); articulation mouth cards.
- **Looked at**, every sheet at full size: `ls03_count_phones.png`, `ls03_colour_stress_which_phones.png`, `ls03_tabletLandscape.png`, `ls03_tabletPortrait.png`, `ls03_hints.png`, `ls03_colour_marks_cvd.png`, `ls05_wheel_phones.png`, `ls05_wheel_tablets.png`, `ls05_strip_phones.png`, `ls05_strip_tablets.png`, `ls05_as_hint.png`, `ls04_graphemes_phones.png`, `ls04_graphemes_tablets.png`, `ls04_merge_phones.png`, `ls04_merge_tablets.png`, `ls04_units_l3_phones.png`, `ls04_units_l3_tablets.png`; and the goldens `ls03_drum_phone`, `ls01r_stem_heb_phoneSE`, `ls01r_sort_eng_tabletPortrait` (today's style). Three first drawings were changed after looking: the ink-ring token (read as the letter o), the two-ring wheel (the result card covered the sign ring and the beads overlapped), the strip sliding behind the frame card (it hid the window's neighbours).
- **Not looked at:** the app (nothing is built), a real phone or tablet, the motion itself, reduce-motion, any sound. Chrome draws text as Flutter will, but the developer's goldens are the proof.
- **Placeholder art:** the bowl, the tokens, the stamps and their marks, the stress sign, the dial, the sign shapes, the knob and the track are template art drawn in code (final). The pictures pot, top and pig stand in for the pilots' pan, nap, pin and tap (not drawn yet; they come with ENG-2b's pictures); three mouth pictures are missing (section 3.6).
