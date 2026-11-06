# L5-1: the rest of LS01, layout spec (text faces, sound cards, tap-all, text stem, cloze, sequence)

Owner: design-director. Date: 2026-11-06. Status: **spec for the app-developer** (step L5-1 of `docs/milestones/L5.md`, approved by the owner on 2026-11-06).
Built on: `docs/milestones/L5.md` §4 and §5.1, `docs/languages/frame.md` §2.1 (F1, F2), §2.3 (LS01) and §3.1, `docs/languages/fonts.md` §6, `docs/design/languages-l4-layout.md` (ChoiceRow, `withSideSpeakers`, the board zones), `docs/design/b40-visual-hints.md` (the hint grammar), `docs/research/age-fit-design.md` §1 and §2 (Band B sizes), `design/tokens.json`, `app/lib/child/activity_shell.dart` (`ActivitySpec`), `app/lib/play/choice_row.dart`, `app/lib/play/option_faces.dart`, `app/lib/design/course_text.dart` and `target_text.dart`. The three Band B pilot files (`docs/languages/*/band-b-pilot.md`) were read for the real counts (a Hebrew tap-all row of 5, a Hebrew pairs item of 4, text stems of 1 unit to 2 units).

Mockups (made by `docs/design/languages-l5/make_l5_ls01_mockups.py`: the real fonts, the app's own pictures, each board at its real size in points, headless Chrome; a check in the page outlines in red any text that leaves its box, and no mockup has one):

| File | What it shows |
|---|---|
| `docs/design/languages-l5/ls01_sort_text.png` | sort with text faces, English and Hebrew, phone and tablet landscape |
| `docs/design/languages-l5/ls01_cloze.png` | cloze, English and Hebrew, phone and tablet landscape |
| `docs/design/languages-l5/ls01_sequence.png` | sequence (the story line), English and Hebrew, phone and tablet landscape |
| `docs/design/languages-l5/ls01_phoneSE.png` | the binding board: sort (English), cloze (Hebrew), sequence (English) on the phone SE |
| `docs/design/languages-l5/ls01_tabletPortrait.png` | sort (Hebrew), cloze filled (English), sequence (Hebrew) on the tablet portrait |
| `docs/design/languages-l5/ls01_more_modes_phones.png` | text stem with hint 1 (English, Hebrew), tap-all (Hebrew A-10.3, Band A, phone and SE), spot with letter cells (English), pairs one at a time (Russian), sort with sound cards (Hebrew A-05.7, Band A) |
| `docs/design/languages-l5/ls01_states.png` | every state of a text tile, a sound card, the cloze gap and a story-line place, and the marks most at risk of clipping (Russian stress, Й, Ё, Hebrew nikud, English descenders) |

Labels, dashed zones and dotted hit areas on the mockups are for the team, never in the app. **Every Hebrew line and every word on them is a sample** (the bubble lines are `needs-editor`; the words are the teachers' choice).

---

## 1. The spec in one page

1. **Two zones per board for every LS01 mode below**: the **stage zone S** (what the question is about: bins, a stem, a sentence, the item now, the replay) and the **answer zone A** (what the child touches or moves). On the phones both zones are **wider than today's stage and tile box**, because a text at reading size needs the room: the phone's stage runs from x 24 (was 71) and is 148 high (was 128); the answer zone runs from x 24 to 605 under the stage and the guide's bubble. The frame (controls, trail, bubble, guide, microphone) does not move.
2. **One reading size per band and board** for each kind of text (letter, word, line, stem). A text face **is never drawn smaller than its reading size**: no `FittedBox` shrink, no ellipsis, no wrapped or hyphenated word. A tile grows in width instead; if the row cannot hold the tiles, **the item is refused at authoring time** by a fit check against the phone SE, the binding board (section 4).
3. **Tiles hold one line.** Only the stage wraps text (a sentence stem, a cloze), and only at spaces, to at most 2 or 3 lines by board and script (section 4.4).
4. **Direction:** every row, bin order, story line and sentence follows the course's reading direction: English and Russian left to right, the Hebrew course right to left. A numeral or a shape card inside a Hebrew row stays a left-to-right tile (`MathIsolate`); no arrow is drawn in these modes. The sequence of a language course follows the course's direction; the lands' timelines keep their left-to-right rule (section 5).
5. **States** are the app's: idle, lit (hint ring), chosen, not yet, correct, plus three new ones that are shapes as well as colours: a sound card's **heard** waves, a story-line place's **set** bead, the cloze **gap** dashed then solid (section 6). Nothing is timed.
6. **Three interaction decisions** I take for the child's sake and send to the curriculum-expert to confirm (section 11): **pairs with text faces are played one item at a time**; **tap-all finishes by itself** when as many cards are picked as there are right ones; **sequence is a story line the child taps in order** (the first, then the next), in one row at the largest size the board allows.

---

## 2. Boards and zones

All values are board points (`BoardClass`). The frame's own pieces are `ActivitySpec` and stay as they are.

| Board | Stage zone S (x, y, w, h) | Answer zone A (x, y, w, h) | Row drawn at (y), Band B | What bounds it |
|---|---|---|---|---|
| **Phone** 852 x 393 | 24, 96, 377, 148 (was 71, 96, 330, 128) | 24, 252, 581, 117 | 264 (tiles 88: hit area 252 to 364) | the bubble starts at x 413 and ends at most at y 236, so S may go down to 244 left of it; the guide at x 617 and the microphone at 661 end A at 605; the bottom band starts at 369 |
| **Phone SE** 667 x 375 | 24, 86, 262, 144 (was 16, 86, 270, 104) | 24, 238, 484, 113 | 250 (hit 238 to 350) | the bubble at x 300; the guide's feet at y 216 and x 490; the microphone at x 521 ends A at 508; the bottom band at 351 |
| **Tablet landscape** 1180 x 820 | 288, 230, 584, 300 (the card, unchanged) | 194, 554, 772, 242, centred under the stage; **A-wide** 24, 554, 942, 242 for the story line | 566 (tiles 104) | the microphone at x 978 (y 672 to 768) ends A at 966 |
| **Tablet portrait** 820 x 1180 | 24, 372, 772, 300 (the card, unchanged) | 24, 684, 772, 472 (room for 3 rows) | 696 | the bottom band at 1156 |

- **Edges:** every drag source and drop target is inside the 24 pt edge band (`edgeNoDrag`) and above the bottom band (`bottomNoHotspot`). The phones' zones start at x 24 for that reason.
- **The stage on the phones** is drawn as it is today (the scene directly, sky tint, radius 24); on the tablets it is the white card with its 16 pt lip padding. Inside S the content keeps 6 pt (phones) or 16 pt (tablets) from the edge.
- **Band A** has taller tiles (96 and 112): on the phone the row is drawn at y 258 and S ends at 244; on the SE the row is at 240 and **S is 136 high** (to 222) so the hit area of the row clears it. Band C (80 and 96) uses the Band B rows.
- **A second row on the tablet landscape** (tap-all of 6 Band A cards, a sort tray of 6 words) needs S 12 shorter (230 to 518): rows at 548 and 676. The phones never get a second row in A.
- For the developer: these are a new board variant, **`withLs01Zones(ActivitySpec base, Band band)`**, next to `withSideSpeakers` and `withTallStage` in `choice_row.dart`. It returns the stage S and the tiles box A above (for the tablet landscape the A-wide box when the template asks for it). `withSideSpeakers` stays for a row whose options have speakers (section 7.1).

---

## 3. Sizes per band (the reading sizes)

**The band is the course's presentation band** (`engine/presentation.dart`), not the content's band letter. Sizes are drawn sizes in points; the hit area adds the slop.

### 3.1 Tiles, gaps and hit areas

| | Band A, phone / tablet | **Band B, phone / tablet** | Band C, phone / tablet |
|---|---|---|---|
| Tile height (a letter tile is square) | 96 / 112 | **88 / 104** | 80 / 96 |
| Gap between square tiles | 24 / 32 | **24 / 24** | 24 / 16 |
| Gap between wide tiles (a word, wider than tile + 24) | 24 / 32 | **16 / 24** | 12 / 16 |
| Hit area | the tile, plus half the gap on each side, plus 12 above and below; neighbours' hit areas meet in the middle of the gap and never overlap | | |
| Hit area of a square tile | 120 x 120 / 144 x 136 | **112 x 112 / 128 x 128** | 104 x 104 / 112 x 120 |
| Inner padding of a word tile (each side) | 14 / 16 | **14 / 16** | 12 / 14 |
| Corner radius, border | `radius.xl` 28, `border.thick` 4 (`AnswerTile` as today) | | |

Band B is age-fit §1 for ages 5 and 6 (drawn 88 / 104, hit at least 112, gaps 16 / 24). **`design/tokens.json` still has Band B answers at 80 / 96 with a 10 slop**; no child screen reads those values today (age-fit §5.3). I recommend the token change below with this build, so the LS01 sizes and the tokens are one source.

### 3.2 Text sizes (the floor: never drawn smaller)

Target text is English or Russian in Nitznutz Letters through `TargetText` (Medium 500 for words, Bold 700 for a letter tile, line height 1.3); Hebrew course text is Heebo through `CourseText` (500 for words, 700 for a letter tile, line height 1.7 whenever a mark is present). English and Russian are 1.1 times the Hebrew size, rounded up to an even point (fonts.md §6); the two then have the same letter body (Hebrew letter height 0.575 em, Andika x-height 0.498 em).

| Kind | What it is | Band A ph / tab | **Band B ph / tab** | Band C ph / tab |
|---|---|---|---|---|
| **letter** | a tile or a bin sign with 1 or 2 letters and no more: ב, בָּ, s, sh, ck, ма, Й | 56 / 72 | **48 / 64** | 40 / 56 |
| **word** (Hebrew / English and Russian) | a word or a short phrase on a tile: כֶּלֶב, cat, a cat, ко́шка | 40 / 48 (Hebrew only) | **34 / 40 Hebrew; 38 / 44 target** | 30 / 36; 34 / 40 |
| **line** | a sentence on the stage (a stem of more than one word, a cloze) | 34 / 40 (Hebrew only) | **30 / 36; 34 / 40** | 26 / 32; 30 / 36 |
| **stem** | a stem of one word, unit or letter, alone on the stage | 48 / 56 | **42 / 50; 48 / 56** | 38 / 46; 42 / 50 |
| **kept** | a card already sorted, a pair already made (nothing is asked of it) | 26 / 32 | **26 / 32; 28 / 36** | 24 / 28; 26 / 32 |

- The letter size is the band's numeral size (`type.kid.numeral`), so a letter and a numeral tile look alike in weight.
- At Band B a word's letter body is about 3 mm on a phone and 4.2 mm on a tablet (1 pt is 0.156 mm on a phone and 0.19 mm on an iPad), close to the print of a first reader held at a book's distance.
- **The kept size is the band's caption size** (age-fit §2): never below it. It is the only text below the reading size, and only for a thing the child no longer has to read.
- A single letter with no marks is set at line height 1.2 in its tile or sign (there are no marks to keep apart); anything with nikud or a stress mark keeps its script's line height. Russian `U+0301` and the breve of Й sit inside an 88 tile at 38 and 48 pt (checked, `ls01_states.png`, last row).
- **Band A never shows English or Russian text** (frame §3.1); the Band A target sizes are listed only so a parent's per-course choice cannot land on an undefined size.

### 3.3 The token change (for the developer, with `tool/gen_tokens.dart`)

```json
"touch": { "B": { "answer": { "phone": 88, "tablet": 104 }, "hitSlop": 12, "...": "the rest unchanged" } },
"type": { "kid": { "target": {
  "$note": "LS01 reading sizes (docs/design/languages-l5-ls01.md 3.2). he = the Hebrew course in Heebo; t = English and Russian in Nitznutz Letters. A text face is never drawn below these.",
  "letter": { "A": { "phone": 56, "tablet": 72 }, "B": { "phone": 48, "tablet": 64 }, "C": { "phone": 40, "tablet": 56 } },
  "word":   { "A": { "he": [40, 48], "t": [44, 54] }, "B": { "he": [34, 40], "t": [38, 44] }, "C": { "he": [30, 36], "t": [34, 40] } },
  "line":   { "A": { "he": [34, 40], "t": [38, 44] }, "B": { "he": [30, 36], "t": [34, 40] }, "C": { "he": [26, 32], "t": [30, 36] } },
  "stem":   { "A": { "he": [48, 56], "t": [54, 62] }, "B": { "he": [42, 50], "t": [48, 56] }, "C": { "he": [38, 46], "t": [42, 50] } },
  "kept":   { "A": { "he": [26, 32], "t": [28, 36] }, "B": { "he": [26, 32], "t": [28, 36] }, "C": { "he": [24, 28], "t": [26, 32] } }
} } }
```

(Pairs are `[phone, tablet]`.) The generator does not know this shape yet; that is the developer's part.

---

## 4. Text fit: wrapping and overflow

### 4.1 The rules

1. **A tile holds one line.** A word, a unit or a short phrase never wraps inside a tile, is never hyphenated, never cut, never ends in an ellipsis and is never shrunk below its reading size. `OptionTextFace`'s `FittedBox(scaleDown)` stays only as the last safety net of section 4.5.
2. **All text tiles of one row have one width**: the widest text plus the padding on both sides, and at least the square tile. The row does not tell which word is long by giving it a longer tile than its neighbours need, and it looks calm.
3. **A row is centred in its zone** and runs in the course's direction. It fits when *n* x (tile width + gap) is no more than the zone's width (the outer tiles' hit areas stay in the zone).
4. **Sentences wrap only at spaces** (the stem, the cloze): never inside a word, never with a hyphen, at the line size, start-aligned (left in English and Russian, right in Hebrew), the block centred in its column. The cloze gap is one unbreakable piece that is as wide as the widest option plus 16. Hebrew punctuation stays at the end of its own line (the sentence is one right-to-left run); an English or Russian sentence is one isolated left-to-right run (`TargetText`), never inline with Hebrew.
5. **A text that does not fit is a content error**, found by the fit check (section 4.3) before a pack is built. The author then uses fewer options, a shorter word, or two options of a binary skill.

### 4.2 The fit table (Band B; the widest text a tile can hold, in em of the word size)

Measured with the real fonts (`make_l5_ls01_mockups.py` prints it). The word size is 38 pt English and Russian and 34 pt Hebrew on the phones, 44 and 40 on the tablets.

| Board (zone width) | 2 options | 3 options | 4 options |
|---|---|---|---|
| **Phone SE (484), binding** | **5.21 em target, 5.82 em Hebrew** (198 pt) | **3.09 em, 3.45 em** (117 pt) | **2.03 em, 2.26 em** (77 pt) |
| Phone (581) | 6.49, 7.25 | 3.94, 4.40 | 2.66, 2.98 |
| Tablets (772) | 7.50, 8.25 | 4.58, 5.03 | 3.11, 3.42 |

Real words (em, Medium): cat 1.49, map 2.00, duck 2.20, frog 1.95, rabbit 2.88, "the map" 3.80, elephant 4.11; кот 1.65, мама 2.57, ко́шка 3.04, соба́ка 3.29, маши́на 3.90; דָּג 0.94, כֶּלֶב 1.60, חָתוּל 2.07, אַבָּא 1.83, פַּרְפַּר 2.26, מִטְרִיָּה 2.67, אֲבַטִּיחַ 2.73.

What that means for Band B content:
- **English CVC words and the tricky words** fit 4 options on every board when they are 4 letters or fewer and have no w or m doubled ("duck" at 2.20 needs 3 options).
- **Russian 1- and 2-syllable reading words** (RUS-B-23) fit 3 options (ко́шка 3.04 is the edge on the SE). Three-syllable words (соба́ка, маши́на) are Band C reading or picture options.
- **Hebrew words** of Band B fit 3 options with room and mostly 4.
- **Bands A and C**: Band C words (34 / 30 pt, 80 tiles, gap 12) allow about 2.5 em in 4 options on the SE; Band A has no target text.

### 4.3 The fit check (a content test)

A Flutter test (proposal: `app/test/content/text_fit_test.dart`) lays out every text face of every LS01 item of every language pack with `TextPainter`, the real font files and the item's course, at the reading size of each presentation band the course allows, and checks it against the SE's zone (the formulas of 4.1 with the numbers of sections 2 and 3). It fails with the item id, the text, its width and the limit. It also checks the stem and cloze line counts of 4.4. It is a test, not a runtime measure, so no device ever meets a text that does not fit.

### 4.4 Lines on the stage (at most)

| | Phone | Phone SE | Tablets |
|---|---|---|---|
| Stem of more than one word, English and Russian (34 pt, 44 a line) | 2 lines, column 365 | 2 lines, column 250 | 3 lines |
| Stem, Hebrew (30 pt, 51 a line) | 2 lines | 2 lines | 3 lines |
| Cloze with its picture, English and Russian | **3 lines**, column 257 beside a picture of 88 | 3 lines, column 166 beside 64 | 3 lines, column 332 (landscape) or 520 (portrait) beside 200 |
| Cloze with its picture, Hebrew | **2 lines** | 2 lines | 3 lines |

The mockups show "The dog is ___ the chair." in 3 lines on the phone, 2 on the tablet landscape and 1 on the tablet portrait, and "הַכֶּלֶב ___ עַל הַכִּסֵּא." in 2 lines on the phone, the SE and the tablet landscape.

### 4.5 Runtime safety net (should never fire)

If a text still does not fit (an unchecked pack in development): the row first gives up equal widths (each tile its own width); if it still does not fit, the text scales down to no less than 0.9 of its reading size; then it is clipped inside its tile, never outside. In debug builds an assertion names the item. A golden of each mode on the SE with the longest allowed text guards the rule.

---

## 5. Direction

| Thing | English, Russian | Hebrew course | Why |
|---|---|---|---|
| A row of tiles (options, cards, cells, the tray) | first at the left | first at the right | F1: the course's reading direction (`rowDirectionOf`) |
| Sort bins | first bin at the left | first bin at the right | the same |
| Kept chips inside a bin | from the bin's left | from the bin's right | the same |
| The pile of waiting cards | at the row's right end | at the row's left end | the end side |
| The story line (sequence) | starts at the left; the start flag at the left end | starts at the right; the flag at the right end | a story is read in the course's direction (L5 §5.1 (f), `hebrew/templates.md`: "right to left") |
| A sentence (stem, cloze) | one left-to-right isolated run, start-aligned left | one right-to-left run, start-aligned right | F1 |
| A numeral or a shape card in a Hebrew row (A-10) | | its glyph is a left-to-right tile (`MathIsolate`, as `AnswerTile` already does); only the order of the row is right to left | maths never mirrors |
| The speaker, the check, the flag | | the speaker and the check are not mirrored (icons); the flag points along the line, so it faces left in Hebrew (it is the line's direction, not a mirrored picture) | |
| The interface (controls, bubble, guide, trail) | right to left as everywhere | | the UI is Hebrew |

**One rule to write down in design-spec §8** (mine to edit; not done in this step): B-40 §8a made every timeline and story sequence in the **lands** left to right in the LTR isolate (the curriculum-expert's rule for maths and logic). **A language course's sequence follows its course direction instead**, so the Hebrew course's story line runs right to left. The two never meet on one screen.

---

## 6. States (every one is a shape as well as a colour)

See `ls01_states.png`. Colours are tokens; motion follows §10 of the design spec and is off under reduce-motion except where said.

| State | Tile | Cue that is not colour | Timing |
|---|---|---|---|
| **idle** | paper, `hairline` border 4, the clay lip | | |
| **lit** (a hint looks here) | a sky ring outside the tile: `hintHalo` at 45% 8 pt wide plus a 3 pt `sky` line | the wide soft ring | appears in 200 ms; stays while the hint line plays. **Never on an option at level 1** (B-40); used on a stem, a sentence's word, a bin sign, a sort card being held, the item now |
| **chosen** | lifted 6, a 4 pt `selectedRing` (ink) ring 3 out | lifted and ringed | on touch-down (within 50 ms) |
| **picked** (tap-all) | as chosen, plus a 26 pt ink dot with a white rim at the tile's top end corner | the dot | on touch-down; a second tap un-picks |
| **not yet** | `notYetRing` (lilac) border, a 2-swing wobble of 6 pt, then back to idle | the wobble | 360 ms; reduce-motion: the lilac border for 600 ms, no wobble |
| **correct** | `sparkTint` fill, `spark` border, the check badge at the top end corner | the check | with the tier-1 celebration |
| **shown** (level 3, the answer appears last) | the right tile chosen-and-lit, the others at 35% opacity | the others fade | as `ChoiceRow.answerShown` today |
| **heard** (sound card) | the speaker with its two sound waves; before the first play there are no waves | the waves | the waves draw while the clip plays (the "playing" state is heard + lit) |
| **set** (story-line place) | the tile's border `lilacDeep` 4; the bead under it filled `lilacDeep`; the path drawn in `lilacDeep` from the start flag to it | the filled bead and the drawn path | the tile slides into place in 280 ms (reduce-motion: it appears there) |
| **gap** (cloze) | empty: a 3 pt dashed `lilacDeep` box, as tall as the line; filled: the same box solid, with the word in it; right: `sparkTint`, `spark` border and the check | dashed against solid; the check | the word flies from its tile to the gap in 280 ms, and the tile stays behind dimmed to 35% |

Nothing here is timed for the child: no countdown, no "too slow", no speed. The only waits are the fixed pauses the app already has for a pending clip (L4 D-5).

---

## 7. The modes

Each mode: what is where on each board, the sizes, how it is played, its states and where each hint level is drawn. **What a hint shows is the curriculum's** (L5 §5.1 and §5.9, the pilot files' hint ladders); this section fixes where it goes and what it looks like, in B-40's grammar: level 1 "look here" (a sky glow on the question, never on an option), level 2 "another way" (a sky card or the stage's own objects changing), level 3 "watch me, then you" (the pointing hand does it, the answer last, then the halo stays).

### 7.1 Text faces on tap options (built in L1; the fit rules apply)

The L1 row (`ChoiceRow`) takes the reading sizes of section 3 and the fit rules of section 4 instead of `tileFont * 0.55` and `scaleDown`. With a speaker on each option the phones keep L4's `withSideSpeakers` pill (tile plus speaker on one lilac pill); the speaker's 64 then counts in the row's width: 3 options on the SE take 3 x (W + 4 + 64) + 2 x 8 of 484, so a word tile beside its speaker is at most 88 wide and holds 1.58 em (60 pt) on the SE and 2.0 em on the phone (tile 104, speaker 6 apart, options 15 apart). An item with longer words has no speakers on its options (the option's clip then plays on a touch, as today). The fit check counts the speaker.

### 7.2 Sort with text faces (`sort_drag`, `ls01_sort_text.png`, `ls01_phoneSE.png`)

| | Phone | Phone SE | Tablet landscape | Tablet portrait |
|---|---|---|---|---|
| Bins (2 or 3) in S | 2: 178 x 136 each, 8 apart; 3: 116 x 136 | 2: 121 x 132; 3: 78 x 132 | 2: 268 x 268, 16 apart; 3: 173 x 268 | 2: 362 x 268; 3: 236 x 268 |
| Sign on the bin's top (a white pill, the clay lip 3) | 58 high | 58 | 84 | 84 |
| Kept chips (under the sign, in one row, caption size, `mist` fill, radius 14) | 44 high | 44 | 56 | 56 |
| Cards in A (letter or word, at reading size) | up to 5 squares, or 4 words of up to 2.66 em | up to 4 squares, or 3 words of up to 3.09 em | up to 6 | up to 6 a row |

- **The sign** is a letter at the letter size (no marks: line height 1.2), a pointed unit or a word of up to 4 letters at the word size, a picture, or a sound button. A sign wider than its bin less 12 is refused by the fit check. With 3 bins on the SE a sign is one letter or a picture.
- **The bin's sound**: a bin with a clip has a 44 pt speaker disc at its bottom end corner (touch 56); a touch on it plays the sign's clip and does not drop anything.
- **The tray shows as many cards as fit** in A after the pile's place (56 wide) is kept; **the rest wait in a pile at the row's end side** (two card edges, not a target). When a card is sorted, the next slides in from the pile (280 ms). Today's sort shows every card at 44 to 84 points; at reading size they cannot all show on a phone, and one fewer thing to look at is calmer.
- **Playing:** drag a card to a bin, or tap the card (chosen) and then tap the bin (`tap-then-tap`); the drop snap radius is 1.25 x the card (Band B). A card dropped in a bin becomes a kept chip there. A chip touched again comes back to the tray (the child may change their mind; the response code is the last state).
- **Not yet** (the item is checked when the last card is sorted, as today): the chips that are in the wrong bin wobble and fly back to the tray; the right ones stay.
- **Hints:** level 1, the signs light one after the other while each sign's clip plays; level 2, each sign changes in place to the new representation (a letter sign shows its key-word picture beside it, a sound sign its mouth picture), so no card covers a bin; level 3, the hand carries one card to its bin from below, then the halo stays on that bin.
- **Response code**: the card index per bin, as today.

### 7.3 Sound cards in a sort (`ls01_more_modes_phones.png`, last board)

- A sound card is a square tile at the band's size with the speaker alone on it (52 pt glyph, no picture, no text). Its state shows whether it has been **heard** (the waves) so the child can tell which ones are still unknown; it carries no other mark that could become a meaningless clue.
- **A tap plays the card and picks it up** (chosen); a tap on a bin then drops it. A tap on the chosen card plays it again. Dragging plays it at the start of the drag.
- In a bin it becomes a kept chip with the speaker (44 or 56 square); a tap on a chip plays it (and a second tap brings it back to the tray).
- **Hints:** level 1, the held card plays again slowly and the two signs light in turn; level 2, the sign that matches lights with its picture growing to 1.25 (another way: the picture of "one" and "many" side by side); level 3, the hand plays the card, then carries it to its bin.

### 7.4 Pairs with text faces, one at a time (`match_pairs`, `ls01_more_modes_phones.png`, Russian)

**Why a change:** two rows of 3 or 4 tiles at reading size do not fit the phones (the SE's stage holds 2 squares of 112, the phone's 3). The pilot has a Hebrew pairs item of 4 letter-name pairs.
- **The item now** sits at S's start side, square, 120 on the phones (letter at 1.25 x the letter size) and 200 on the tablets. It can be a letter, a word, a picture or a sound card.
- **Its partners** are the option row in A (2 to 4, as a tap row with the fit rules). A touch on the right one makes the pair; the pair flies to S's end side as a kept pair chip (the two faces with a short `lilacDeep` bar between them, at the kept size), and the next item comes. The last pair makes itself, as in every pairs item.
- A wrong touch is not yet on that tile; the item now stays.
- **Hints:** level 1, the item now lights and plays its clip; level 2, it changes to its other representation beside itself (a letter shows its key-word picture, a capital its small letter); level 3, the hand takes the right partner to it.
- **Response code**: the pairing, as today (`a1.b3…`). The land's two-row `match_pairs` stays for picture items.

### 7.5 Spot with text cells (`spot_error`, `txt:`)

- **S** holds the model: the picture (and its word, heard on a touch) the cells should match, centred, as large as S allows (136 on the phone).
- **A** holds the cells, a row of letters, units or words at reading size, the tap targets (up to 4 in Band B, as `maxChoices`; 5 in Band C on the tablets, 4 on the phones).
- A touch on a cell chooses it; the item is checked on that touch (one cell is wrong).
- **Hints:** level 1, the model's word plays slowly and each sound is drawn as a sky bead over its cell in turn (the cells themselves do not light); level 2, the model's own spelling appears in a sky card over S, cell above cell, so the child compares "same, same, different"; level 3, the hand touches the wrong cell, then the right letter appears in it.

### 7.6 Order tiles with text (`build_pattern` with text faces)

- S holds the row: cells of 52 x 64 on the phones (72 x 88 on the tablets), a letter or unit at the letter size, 8 apart, and the gap slot (dashed, the same size) at the row's end in the course's direction. The phone holds 6 cells, the SE 4. Cells are not targets; the slot is a drop target.
- A holds the tiles (the letter tiles of section 3).
- Hints are the existing build_pattern ladder (B-40 table: the row in rhythm, brackets on the unit, the hand). Not drawn in the mockups.

### 7.7 Tap-all (`ls01_more_modes_phones.png`, Hebrew A-10.3 on the phone and the SE)

- Cards (letters, numerals, shapes, a mirrored-letter picture) are square tiles at the band's size. **A is filled first**; cards that do not fit go to **S's end side**, and **S's start side holds the "what to find" sound** (a 64 pt speaker: the instruction's target again). Capacity at Band B: phone 5 in A + 2 in S; SE 4 + 1; tablets 6 a row. A row of 6 (the most L5 allows) fits every board. Band A (96 tiles): phone 4 + 2, SE 4 + 1.
- **Playing:** a tap picks a card (picked state); a second tap un-picks it. **When as many cards are picked as there are right ones, the item checks itself**: right if exactly the right ones are picked; otherwise the wrong picked cards wobble and un-pick, the right picked ones stay, and the child goes on. No "done" button (a meta-decision a 3- or 4-year-old does not need; A-10 is Band A). This gives away how many to find; it does not give away which (section 11, to confirm).
- **Response code**: the indexes picked, in the order picked.
- **Hints:** level 1, the target lights big in S's start corner (the pilot's HL-TAPALL: "the target letter appears big above the row"); level 2, that letter glides over each card in turn and settles only on the right ones (the look-alikes are left uncovered); level 3, the hand picks the first right card, then the child picks the rest.

### 7.8 Text stem (`tap_answer` with `scene.stem`; `ls01_more_modes_phones.png`, first two boards)

- **S** holds the stem on a white page (radius 20, `hairline` 3, padding 24 at the sides), centred. One word, unit or letter at the **stem size**; a phrase or sentence at the **line size**, up to the lines of 4.4. No speaker on the page: "read it to me" is hint level 1 (L5 §5.1), and the child is asked to try first.
- **A** holds the options: pictures (square tiles at the band size, the picture inset 6), sound buttons, or text tiles under the fit rules.
- **Hints:** level 1, "read it to me": the stem's clip plays and the page lights; **each word gets a 6 pt `skyDeep` bar under it while it is read** (with every clip pending, the bar walks the words in even steps); the credit is 0.8. Level 2: the borrowed screen (`hints.level2.show`), the LS05 wheel (Hebrew), the LS04 slide (English), the vowel strip (Russian): it **takes S's place** while it is shown, with the stem inside it, and the options in A stay live; a touch on an option answers. Level 3: the borrowed demonstration (`blend_slide`), then the hand points to the answer and the halo stays.

### 7.9 Cloze (`scene.cloze`; `ls01_cloze.png`)

- **S**: the picture (square, framed white, radius 18) at the course's start side, **88 on the phone, 64 on the SE, 200 on the tablets**, and the sentence beside it in the rest of S at the line size, start-aligned, vertically centred, with the **gap** in place of the missing word (section 6). Without a picture the sentence takes the whole of S, centred.
- **A**: the 3 word tiles (fit rules; each the gap's word size).
- **Playing:** a tap on a tile (or a drag to the gap) puts its word in the gap, and the tile stays dimmed in the row. The item checks at once. Not yet: the word wobbles in the gap and flies back; the gap is empty again.
- **Hints:** level 1, the sentence is read with a short pause at the gap and the gap lights (each word's bar, as the stem); level 2, the picture grows to fill S (the sentence fades) with the part the gap is about ringed in sky (the dog and the seat of the chair), then the sentence comes back; level 3, the hand carries the right word to the gap.
- The SE's 64 picture is the smallest picture in these modes; it carries meaning only together with the sentence and grows to the whole of S at hint level 2.

### 7.10 Sequence: the story line (`build_pattern` slots with `answer.order`; `ls01_sequence.png`)

**Why one row:** a row of slots and a tray of the same pictures cannot both fit on a phone at a size a child can read a picture at (the bubble takes the phones' upper right). One row of places, already holding the pictures in a shuffled order, uses the whole width of A. It matches "first, then, at the end", the words the course already has (`i-first`, `seq-1` to `seq-3`).
- **The line**: n places in A (A-wide on the tablet landscape), each holding one picture at its own aspect (a story page is 16:9, a picture 1:1, a letter tile square), all the same size, centred; under them a 6 pt `mist` path with a 16 pt bead under each place, and the **start flag** (a short `ink` pole with a `sea` pennant) standing on the path at the start end.
- **Sizes, 16:9 pages, Band B (4 places):** phone 129 x 73, SE 105 x 59, tablet landscape 212 x 119, tablet portrait 169 x 95. With 3 places: phone 156 x 88, SE 145 x 82. Picture tiles may be up to 120 high on the tablets.
- **Where the line stands:** the path is 22 below the pictures. On the phones the line is placed so the path's beads end at least 2 above the bottom band (path at most at y 359 on the phone, 341 on the SE); with 3 places of 88 that puts the pictures at y 252 on the phone and 240 on the SE, so **S ends at 236 (phone) and 224 (SE) in this mode** (it holds only the replay and the level 2 card). The mockups show 4 places, drawn at the standard row.
- **Playing:** the voice asks what happened first. **A tap on a picture moves it to the first place that is not set** (it swaps with the picture there) and sets that place (section 6). The next tap sets the next place. When one place is left, it sets itself and the order is checked. A drag of a picture to the next place does the same; a drop anywhere else springs back. A tap on a set picture un-sets it and every place after it (they keep their pictures).
- **Not yet:** the whole line wobbles once and every place is unset; the pictures stay where they are (nothing reshuffles).
- **Right:** the places turn correct one by one from the start, with the voice's "first, then, at the end".
- **S** holds the story's replay (a 64 or 80 pt speaker: hear the story again) and, at hint level 2, the sky card "first, then, at the end": three beads on a path with the course's direction, each lighting with its line.
- **Hints:** level 1, each picture lights in turn while its page's key line plays (the story again, short); level 2, the card in S as above, and the first picture lights; level 3, the hand taps the pictures in story order, the line is checked as right, then every place is unset and the child does it.
- **Response code**: the picture ids in the order set.
- **The limit:** in Band B a scored sequence of story pages has **at most 4 places** (5 would be 80 x 45 on the SE). Square pictures and letter tiles may have 5 on the tablets, 4 on the phones. Band A: 3 places (A-13). See section 11.

---

## 8. Hints: where each level is drawn (summary)

| Mode | Level 1 (look here) | Level 2 (another way) | Level 3 (watch me) |
|---|---|---|---|
| sort, text | the signs light in turn | each sign shows its other representation in place | the hand carries one card |
| sort, sound | the held card again, the signs light | the matching sign's picture grows | the hand plays and carries |
| pairs | the item now lights and plays | the item's other representation beside it, in S | the hand brings the partner |
| spot | sound beads over the cells | the model's spelling in a sky card over S | the hand touches the wrong cell |
| tap-all | the target big at S's start | the target glides over each card | the hand picks the first |
| text stem | read it to me, a bar under each word (credit 0.8) | the borrowed screen takes S's place | the borrowed demonstration, then the hand |
| cloze | the sentence read, the gap lit | the picture fills S, the part ringed | the hand carries the word |
| sequence | each picture lights with its line | the "first, then, at the end" card in S | the hand taps the order |

While any hint shows, the hint pebble wears its 5 pt sky ring (B-40). No hint lights or dims an option before level 3.

---

## 9. Per device: what changes and what does not

- **Phones:** S and A as in section 2 (both wider than today's stage and tile box). The guide's bubble, the guide, the controls and the microphone keep their places. Everything is one row in A.
- **Phone SE:** the binding board for the fit check; the cloze picture is 64; a story line of 4 pages is 105 x 59.
- **Tablet landscape:** S is the card as today; A is centred under it (772 wide), and the story line uses A-wide (24 to 966). A second row needs S 12 shorter.
- **Tablet portrait:** S as today; A has room for 3 rows, used only by the sort tray and tap-all of 6 when a row is full.
- **Split screen:** the board follows the window (`boardClassFor`), so a half-width tablet is laid out as a phone or a phone SE.

---

## 10. For the app-developer (the build list)

1. `withLs01Zones(base, band)` in `choice_row.dart` (section 2); the sessions of sort, pairs, spot, build_pattern and tap_answer use it for language items. The lands keep today's boards.
2. Tokens (section 3.3) and their generator; `AppLayout` reads `touch.B` 88 / 104 with slop 12.
3. A text tile that never shrinks: `OptionTextFace` takes the reading size from the band, the course and the kind (letter or word); the row computes one equal width (section 4.1); `FittedBox` only as section 4.5's net, with the debug assertion.
4. Sort: bins with signs, the bin's speaker, kept chips, the tray with its pile; sound cards (heard state); tap-then-tap for both.
5. Pairs one at a time (section 7.4), tap-all with picked and the self-check (7.7), spot with `txt:` cells (7.5), build_pattern text cells (7.6).
6. Text stem page with the word bars of hint level 1 and the borrowed level 2 screen in S (7.8, L5 §5.9).
7. Cloze: the sentence wrapped at spaces in its column, the gap as one unbreakable piece, the word's flight (7.9).
8. The story line (7.10): places, path, beads, start flag, set and unset, the swap, the self-check.
9. The fit check test (section 4.3).
10. Goldens on the four boards for each mode, in English and Hebrew (and Russian for pairs and stress), at Band B; the SE also at Band A for tap-all and sound sort; one golden per mode with the longest text the fit check allows.

---

## 11. Hand-offs

- **app-developer:** section 10, from this file and the mockups. The generator `docs/design/languages-l5/make_l5_ls01_mockups.py` prints the fit table from the real fonts.
- **curriculum-expert** (please confirm or change; each is drawn as I recommend):
  1. **Pairs with text faces played one item at a time** (7.4) instead of two rows: the same pairs, one decision at a time.
  2. **Tap-all checks itself** when as many cards are picked as there are right ones (7.7): it gives away the count, not the cards. The alternative is a "that's all" check button (as the drum), which costs a place in the row on the SE.
  3. **Sequence as a story line tapped in order** (7.10), with **at most 4 story pages in Band B** (HEB-B-05 "retell with 4 to 5 pictures": the retell may show 5, the scored sequence uses 4).
  4. **The Hebrew course's sequence runs right to left** while the lands' timelines stay left to right (section 5). Hebrew `templates.md` already says so; design-spec §8 will say so after your OK.
  5. The level 2 pictures of section 8 are the places I give the hints you already wrote; the content of each stays yours.
- **hebrew-text-editor:** the bubble lines in the mockups are mine and are samples only: לְאֵיזֶה סַל?, אֵיזוֹ מִלָּה חֲסֵרָה?, מָה קָרָה קֹדֶם? (the Band A batch has its own `i-first` line, which wins), קִרְאוּ וּבַחֲרוּ תְּמוּנָה., אֵיזוֹ אוֹת לֹא נְכוֹנָה?, מָה הוֹלֵךְ עִם זֶה?, אֶחָד אוֹ הַרְבֵּה?. Nothing in the app takes them from this file. Also: the bubble on the phone SE is 176 wide at 22 pt, so a Band B instruction line longer than about 2 short lines will cover more of the guide's bubble area than the boards planned; please keep LS01 lines short.
- **qa-engineer:** once the developer is done, verify on the four boards: no text below its reading size (the fit test and the goldens), nothing clipped (nikud, stress, Й, descenders), the row directions of section 5, the states of section 6, and that hit areas never overlap or leave their zone.
- **Needs the owner:** nothing to decide. If he wants to see it: `docs/design/languages-l5/ls01_sort_text.png`, `ls01_cloze.png`, `ls01_sequence.png` (the phone is the top row of each).

---

## 12. What I looked at, and what I did not

- **Looked at**, at full size and with 1.4 to 2 times zooms: every mockup listed at the top; the goldens `ls01_eng_words_phone`, `ls01_heb_words_phoneSE`, `hint_sort_l3_phone`, `hint_sort_l3_phone_se`, `hint_sort_l3_tablet_landscape`, `hint_pattern_l3_phone`, `hint_match_l3_phone`, `hint_spot_sentence_l2_phone`, `hint_qa_pattern_l2_tablet_portrait` and `hint_qa_pattern_l3_phone_se` (today's layouts, to keep what works). In the mockups I checked: no red overflow mark; the nikud of בָּנָנָה, שֻׁלְחָן, גְּלִידָה, מַפָּה and the Russian stress and Й breve not cut; the Hebrew rows, bins, story line and sentences starting at the right and the English ones at the left; the numeral 2 and the shapes not mirrored in the Hebrew row; pictures at their own aspect (16:9 pages, square objects), none stretched.
- **Not looked at:** the app itself (nothing is built), a real phone or tablet, reduce-motion, the hint levels in motion, or Chrome's text against Flutter's (the two shape and break text alike, but the developer's goldens are the proof). The shapes ○ and △ on the A-10 cards are a font glyph in the mockup; in the app they are drawn shapes, as the Band A batch says.
- **Placeholder art:** none new. The mockups use the existing pictures (story pages `story-bounce-*` and `s1-p*`, `place-dog-on-chair`, `act-*`, `cat`, `fish`, `duck`, `dog`, `set-ducks-*`) and `nitzi-idle.svg`. A key-word picture for each letter (level 2 of several modes) comes with the pilot slices' picture lists.
