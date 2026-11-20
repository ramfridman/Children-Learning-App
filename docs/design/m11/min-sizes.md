# Minimum sizes in the child's space, and the pattern-strip sort redesign (M11)

Design director, 2026-11-16, branch `lands-ux` at 0be96cf0. A spec and an audit: nothing in `app/` changed. The developer builds from
sections 2 and 3, the QA engineer automates section 5.

**Why.** The owner, looking at `app/test/goldens/sortstrip_phone_sorted.png`: *"the images look very small ... we must make sure everything
looks good and not too small to see or read in any of the devices"*. He is right. In that screen one animal in a card in a bin is
**9 pt** wide, one animal in a tray card **17 pt**, the bin labels **13 pt**. Half the phone is empty. And the tablet draws the same
26 pt cards in a 584 × 300 card in the middle of a 1180 × 820 screen. The audit (section 4) found the same pattern in many templates:
the content a child has to see, count or touch is drawn at a size chosen to fit a 330 × 128 stage, and tablets keep the phone's sizes.

Files:
- this spec: `docs/design/m11/min-sizes.md`
- mocks (rendered from the real `content/starter/strip_*.svg`, `tick.svg`, `cross.svg`, the Riddle Grotto backdrop and Nitzi):
  `docs/design/m11/min-sizes/strip_sort_phone.png`, `strip_sort_phoneSE.png`, `strip_sort_phone_t13.png`, `strip_sort_tabletL.png`,
  `strip_sort_tabletP.png` (script: `make_strip_sort_mocks.py`)
- contact-sheet tool for the audit: `docs/design/m11/min-sizes/make_sheets.py` (the sheets themselves are scratch, not committed)

---

## 1. Basis

### 1.1 How big a point is to a child
- 1 pt is 0.156 mm on a phone (163 pt per inch) and 0.192 mm on a 10th-gen iPad (132 pt per inch) (design-spec §6.1). A child holds a
  phone at about 30 cm and looks at a tablet from about 40 cm, so **one point is about the same angle on both: 1.7 to 1.8 minutes of arc**.
  So a legibility floor in points is the same on every board. Tablets do not need a lower floor. They have more room and should use it
  (1.4).
- Acuity at 3 to 4 is about 6/12 (20/40): a letter or a simple symbol is just recognisable at 10 minutes of arc. Comfortable, fast
  recognition needs about three times the threshold. This "acuity reserve" is the rule of thumb in low-vision reading research
  (Whittaker and Lovie-Kitchin), so 30 minutes of arc, which is **about 17 pt**. That is the smallest a *distinguishing feature*
  should be: a cat's ear against a dog's, the digit on a coin, a tick against a cross. An object whose feature is about half its size
  needs about **34 pt**, which is where the existing token **`component.stagePicture.min` = 40** sits.
- Touch: design-spec §6.1 and `tokens.touch`: Band A has a minimum control of 64 and answers of 96 / 112. Bands B and C have a minimum
  control of 56 and answers of 88 / 104 and 64 / 80. Miss rates rise sharply under about 6 mm (Anthony 2013), which is 38 pt on a phone.

### 1.2 What the well-sized templates already do (measured from code and goldens)

| Template / token | Size | Where |
|---|---|---|
| Answer tile, P1 and P2 / P3 / P4 | 96 / 88 / 80 phone, 112 / 104 / 96 tablet | `tokens.stage.P*.tile`, `StageSpec.tile` |
| Numeral on a tile | 56 / 48 / 40 phone, 72 / 64 / 56 tablet | `tokens.stage.P*.numeral` |
| Caption in the bubble | 26 / 24 / 22 phone, 24 / 22 / 20 SE, 32 / 30 / 28 tablet (floor −2) | `tokens.stage.P*.caption` |
| A picture on the stage | at least 40 | `TokenComponent.stagePictureMin` |
| Name label (land sign, avatar) | 18 phone, 20 tablet, line height 1.7 | `tokens.type.label` |
| Badge numeral | 16 phone, 18 tablet | `tokens.type.badge` |
| LS01 reading sizes (languages) | letter 56 / 72, word 40 / 48 (Band A) | `tokens.type.target` |
| Language count in place | object cell at least 64 (QA-BA-6), tall stage for 5 to 10 objects | `count_tap_session.dart` `_language` |
| Meet picture / picture choice on a phone | picture 166 wide on a 377 × 253 stage | `withPictureStage`, `withMeetStage` in `choice_row.dart` |
| Base-ten cube | 12.7 phone, 19 to 20 tablet (target 19) | `docs/design/c1-blocks.md` §5 |

These are the sizes children already read well in this app. The rules below put everything else at or near them.

### 1.3 The room each board has (from `ActivitySpec`, `app/lib/child/activity_shell.dart`)
- **Phone 852 × 393.** Stage 71,96 330 × 128. Answer band 71,244 534 wide, to the no-hotspot line at 369. The bubble is at 413..603
  × 104..236 and the guide at 617..793. The free play area is an L shape: the stage plus the answer band, **534 × 268 less the bubble**.
- **Phone SE 667 × 375.** Stage 16,86 270 × 104, answer band 8,214 480 wide, to 351.
- **Tablet landscape 1180 × 820.** Stage card 288,230 584 × 300, tiles at 554. **The 264 points left of the card and everything
  under the tiles (about 570..776) are empty on every activity.**
- **Tablet portrait 820 × 1180.** Stage card 24,372 772 × 300, tiles at 696. **design-spec §7.3 says this stage is "square-ish at about
  772 × 560". The build has 300. Everything from about 800 to 1136 is empty on every activity.**

### 1.4 Tablets use their room
The floors in section 2 are the same in points on every board. On a tablet each element's **tablet target** is about 1.3 to 1.4 times
the phone floor, and the stage grows to reach it (2.3). A tablet showing phone sizes in a sea of space is a defect (severity S3), even
when every element is above its floor.

---

## 2. The rules

### 2.1 Sizes (points; pictures never scale with the text size; text at 1.3 is the size × 1.3 where it fits, see 2.2)

| # | Element | Phone and SE floor | Tablet floor | Tablet target | Notes |
|---|---|---|---|---|---|
| R1 | **Picture to identify**: an object whose identity is the content or the answer (which animal, which shape, which solid, a picture on a tile, a bin's sample, a cloze's context picture) | **40** | 40 | **56** | `stagePicture.min`. A size item that is small on purpose (seriation, "small") keeps its smallest at **24** or more (32 on tablets); the exact family, its big-member floor and the tower cube are in **9.2 D1** (replaces this note's open end, 2026-11-20). |
| R2 | **Detail inside a composite**: one animal or ball of a pattern strip, one counted thing that is not touched one by one (a set on a tile, apples on a stall, pictures in a chart, things on a balance pan, a ten-frame dot) | **24** | 24 | **32** | Base-ten cubes keep c1-blocks' 12.7 / 19 (they are counted by rods); see owner decision 3. |
| R3 | **Counted object that is touched one by one** | drawn **40**, touch square **64** (A) / 56 (B, C) | same | drawn 56, touch 80 | The touch square is the object's cell, never `max(object, 48)`. |
| R4 | **Draggable tile** | the look's tile (`StageSpec.tile`): 96 / 88 / 80; never under the band's `minControl` | 112 / 104 / 96 | same | A wide card keeps the tile's height and grows in width until its detail meets R2. A **word tile of a language course read at Band C** follows the course band's token, 64 / 80 (9.2 D2, 2026-11-20). P0 (M12): 112 on every board. |
| R5 | **Item shown inside a bin / plate / slot** (what has been sorted or placed) | square **40**; a wide card at the size where its detail meets R2 (a 2.5:1 strip: **170 × 68**) | same | square 56; strip 250 × 100 | When the bin cannot show all at that size, it shows the newest one(s) at that size and **piles** the rest under the newest with a **count badge** (3.4). It never shrinks them. |
| R6 | **Label in Hebrew with nikud** (a bin's or zone's label, a card's word) | **18**, weight **500**, line height 1.7 (`type.label`) | 20 | **24** | `font.niqqudRules.maxWeightBelow24pt` = 500. Pre-readers read the mark (R9), and the label is voiced. |
| R7 | **Numeral the child reads** on a number line, clock face, coin, price tag, counter or badge | **20** (a coin's own digit **18**) | 24 | **28** (clock 32) | Weight 800, LTR. Dots under a numeral (a quantity hint): dot **7** or more with a gap of 3, groups of five. |
| R8 | **Bubble / host caption** | the look's caption, never under caption − 2 (P1 phone 26 → 24, SE 24 → 22) | 32 → 30 | as token | Unchanged; the frame already fits it (`captionFloor`). |
| R9 | **Mark or icon that carries meaning** (tick or cross of a bin, an arrow in a robot program, the speaker) | **32** (`icon.lg`); in a program strip **28** | 40 | **48** | An icon squeezed by a `FittedBox` must still meet this. |
| R10 | **Line / tick a child aims at** (number-line tick, trace path) | tick spacing **24**; tick 4 × 20, major 6 × 28; a trace figure **200** tall | spacing 32 | trace 360 | |
| R11 | **Gaps** | the look's gap (`StageSpec.gap`) between targets; 8 between pictures inside a group | same | | |

### 2.2 Text size 1.3
- Pictures, cards, marks and lines keep their size at any text size.
- Labels (R6) and numerals that are text (R7) grow up to × 1.3 **where the box lets them**. Otherwise they keep the largest scale that
  fits one line, never under 1.0. That is the rule `SortDragSession.labelScale` already has; extend it to every label. A label may
  take a second line only when the box has the height of two lines at 1.7.
- A box grows for its text before a picture gives up room. The picture may give up room only down to its floor, never below it.
- The bubble keeps its box and fits its caption (`captionFloor`), as it does today (`m11_room_*_phone_text_1_3`).

### 2.3 Use of the stage
- **S1, phone: an empty answer band is a waste.** A screen whose answer band (y 244..369) holds nothing, or only a small row of
  controls, takes the room with a layout that already exists in `choice_row.dart`:
  - `withTallStage`: the stage 71,96 330 × 253. Use it when nothing is under the stage (count while counting, trace, give,
    number-line place, the host's Show greeting).
  - `withPictureStage`: 24,96 377 × 253. Use it when pictures stand on the stage with no tiles.
  - `withMeetStage`: stage 24,96 377 × 260, plus a column of tiles under the bubble at 413,256, 192 wide. Use it for a big stage with
    one to three small controls (clock −/+/✓, a deck of cards, "I said it").
  - SE: the same three exist, with SE numbers.
- **S2, tablet landscape:** the stage card starts at the margin (`withWideStage`: 24 → 872, 848 wide). It is at least **848 × 400**
  when the tiles take one row (stage 230..630, tiles at 654), and 848 × 300 with a second row of tiles under it.
- **S3, tablet portrait:** the stage card is **772 × 520** (372 → 892), as design-spec §7.3 asks, with the tiles at 916. A screen
  with two rows of tiles keeps 772 × 420 and puts the tiles at 816.
- **S4:** after layout, no empty band under the last row of a screen may be taller than **25 % of the board's height** (phone 98,
  tablet landscape 205, tablet portrait 295). Exceptions are a celebration and a Show greeting whose stage is the room's window.
- **S5:** inside a stage, a template's content (its bins, its line, its clock, its group) fills at least **70 %** of the stage's
  shorter side. It never sits at a fixed phone size in the middle of a tablet card.
- **S6 (added 2026-11-20, 9.3 T1):** a stage that would hold **only the backdrop** while the answers wait outside it gives its room to
  the answers: they stand **in** the stage (phone picture stage 377 × 253: three tiles of 112, two of 144; SE: two over one at the look's tile, or two of 120; tablet L card: three of 200;
  tablet P card: three of 208), and nothing stands under it.

---

## 3. The pattern-strip sort, redesigned (LOG-A-04, `sort_drag` with wide cards)

### 3.1 What is wrong today (measured, `sort_drag_session.dart` and `sortstrip_*` goldens)
A strip is `viewBox 120 × 48`. Each animal or ball takes about 0.143 of the card's width (17.2 of 120). So **an animal is 0.36 × the
card's height**.

| Board | Tray card | Animal in the tray | Card in a bin | Animal in a bin | Bin label |
|---|---|---|---|---|---|
| phone | 117 × 47 (tile 123.5 × 84) | **17** | 65 × 26 | **9.3** | 13 pt, weight 700 |
| phone SE | 104 × 42 (tile 110 × 84) | **15** | 65 × 26 | **9.3** | 13 pt, weight 700 |
| tablet L | 130 × 52 (tile 136 × 84) | **19** | 65 × 26 | **9.3** | 13 pt, weight 700 |
| tablet P | 177 × 71 (tile 183 × 84) | 25 | 65 × 26 | **9.3** | 13 pt, weight 700 |

The causes in code: `binBands` fixes `itemSide` at 26 (22 in a low bin) on every board, with `wideItem` 2.5. `_trayHeight` is 84 and
`_trayWidth` is `tilesWidth / n − 10`. The label is `band.label − 4` = 13 at weight 700, which breaks R6 and the nikud weight rule.
The bins share a 330 × 128 phone stage side by side.

### 3.2 The design
- **Phones: two shelves, not two bins side by side.** The stage takes the start column from the top bar to the no-hotspot line
  (`withMeetStage`'s stage). The two bins become shelves stacked top to bottom, the first rule on top. Each shelf has a **sign column
  on its start side** (right): the mark (tick / cross: the rule's sample picture) with the label under it. The rest of the shelf is
  the **card well**.
- **A shelf shows its newest card at full size and piles the earlier ones under it** (an edge of each peeks out, up and to the end
  side, at most two edges). From two cards a **count badge** (white numeral on an ink circle, LTR) sits on the pile's corner. The
  child sees what went in last, and how many went in.
- **The tray on phones is a deck** in the column under the bubble (`withMeetStage`'s tile column). One card is on top as a wide
  answer tile, and the waiting cards show as edges under it (at most two). The child sorts one card at a time. That is one decision
  per move, which suits Band A, and it is the only way a phone shows a card whose animals are 24 pt or more. The hints that point at
  "the next picture in the tray" point at the top card.
- **Tablets: two bins side by side on a wide card.** Each bin has a header row (mark and label side by side) and a well that shows one
  row of cards (landscape) or two rows (portrait) at full size, then piles. The tray is a 2-column grid of wide tiles under the card
  (two rows for four cards, three rows for six).
- **The drag copy** (`Draggable.feedback`) is the size of the tray card, at opacity 0.9, lifted 6 and scaled 1.04. The shelf or bin
  under it rings with `hintHalo` (5). A drop anywhere in the shelf or bin counts (it is all one target). Tap-then-tap is unchanged.
- **Never mirrored**: a strip reads left to right as drawn (`matchTextDirection` false), as today.
- Everything else is unchanged: the Show, the hints' order, "not yet", the guided bin, reduce-motion.

### 3.3 Numbers per board (all in points; see the mocks)

| | phone 852 × 393 | phone SE 667 × 375 | tablet L 1180 × 820 | tablet P 820 × 1180 |
|---|---|---|---|---|
| Stage | 24,96 377 × 260, scene, no card (`withMeetStage`) | 24,86 264 × 256 (`withMeetStage` SE) | card 24,230 848 × 270 (`withWideStage`, inner 816 × 238) | card 24,372 772 × 420 (inner 740 × 388) |
| Bins | 2 shelves 361 × 116, inset 8, gap 12 | 2 shelves 252 × 116, inset 6, gap 12 | 2 bins 394 × 222 side by side, inset 8, gap 12 | 2 bins 356 × 372, inset 8, gap 12 |
| Bin look | paper 0.9, radius 16, border 3 hairline (5 `hintHalo` / `notYetRing` when lit) | same | same | same |
| Mark (tick / cross) | 44, in a sign column 72 wide (100 at text 1.3) | 40, sign column 60 | 48, in a header row 60 high | 48, header 60 |
| Label | 18 pt w500, h1.7, under the mark (23.4 at 1.3) | 18 pt w500 (stays 18 at 1.3: no room) | 24 pt w500 beside the mark | 24 pt w500 |
| Card in a bin | **190 × 76** (animal 27) | **170 × 68** (animal 24) | **300 × 120** (animal 43) | **280 × 112** (animal 40) |
| Rows shown, then pile | 1 | 1 | 1 | 2 |
| Pile edges | 6 up and 6 to the end side, at most 2, opacity 0.82 / 0.64 | 5 | 6 | 6 |
| Count badge (shown when cards are piled) | circle 32, numeral 20 w800 | 30 / 20 | 40 / 24 | 40 / 24 |
| Tray | deck: wide `AnswerTile` **184 × 88** at 417,270 | deck: tile **196 × 86** at 306,250 | 2-column grid, tiles **300 × 112**, gaps 24 / 16, from x 136, y 524 | grid, tiles **340 × 128**, gaps 24 / 16, from x 58, y 816 |
| Card in the tray | **176 × 70** (animal 25) | **188 × 75** (animal 27) | **250 × 100** (animal 36) | **300 × 120** (animal 43) |
| Lowest point | 358 (+ deck edges 12), above 369 | 336, above 351 | 764 for four cards (≤ 776) | 1088 for four cards (≤ 1136) |
| Drag copy | 176 × 70 | 188 × 75 | 250 × 100 | 300 × 120 |

The first bin (the language's first) is at the top on phones and at the right on tablets. The tray's first tile is at the right.

### 3.4 Every `sort_drag`, not only strips (square pictures)
The same boards serve every sort, so no template has a 26-pt picture in a bin.
- **Phone:** the shelves for two bins. For three bins, three shelves 361 × 76 with **one** sample in a 52 box and the label
  **beside** it (9.2 D3 replaces "a 40-pt sample in the sign column", 2026-11-20), items 48 in the well. Items in a shelf are **48** (R5 × 1.2), 8 apart, in one row, then a pile with the badge. The deck tile is the look's tile
  (96 / 88 / 80) in the column under the bubble.
- **SE:** shelves 252 wide; items 44.
- **Tablet L:** bins side by side (2 or 3) on the 848 card. Sample 96, items **64** in rows. The tray is one row of the look's tiles
  (112) under the card, or two rows of 104 for seven or more.
- **Tablet P:** card 772 × 420, items **64**, the tray is one row of 112 (two rows from six).
- A **share** (plates for friends): the same, the plates are the bins. A plate shows its cards in a row of 40 (phone) or 56 (tablet)
  with a count badge, because the count is what the child compares.
- The tally of sticks (`_TallyPainter`) stays a tally. Its sticks are 9 wide on the phone's 116-high shelf and 12 on tablets.

### 3.5 For the developer (sort_drag_session.dart, no logic change beyond the deck)
- `layoutFor`: phones use `withMeetStage` (or a new `withSortBoard` with the numbers above), tablets `withWideStage` plus the heights
  of 3.3.
- Replace `binRect` / `binBands` with a board-aware layout: shelves on phones, bins on tablets. The card and item sizes come from the
  table, not from `itemSide` 26 / `wideItem` 2.5. Drop the `itemSide ≥ 16` fallback (a card is never shrunk; it piles).
- The label: `AppText.fixed(size: 18 | 24, weight: 500, lineHeight: 1.7)`, scaled by `labelScale` (floor 1.0).
- The tray: on phones, a deck widget (the top item is the `Draggable`, the rest are edges); `_trayTip` points at the top card. On
  tablets, a `Wrap` of 2 (strips) or a row of the look's tiles (squares).
- Keep the keys: `sort-stage`, `sort-tray`, `item-<id>`, `bin-<id>`, `bin-label-<id>`, `bin-strip-<id>`, `bin-sample`. Add `bin-card-<id>`
  for each card drawn in a bin, `bin-pile-<bin>` and `bin-count-<bin>` (the badge).
- Update `sort_strip_test.dart`: its expectations (84-tall tiles, 2.5 × 26 cards) encode today's sizes. The new ones are in 5.2.

### 3.6 What I looked at
I looked at the five mocks at 1:1. In the phone's sorted state the fish and birds in the shelf card (190 × 76) and the cats and dogs in
the deck card (176 × 70) can be told apart at a glance: the ears, the tails, the fins. At 9 pt in today's golden they are brown and
blue blobs. SE at 170 × 68 is at the floor: still clearly a cat and a dog, but no smaller. Tablets show them large (36 to 43 pt).
The 1.3 mock shows the labels at 23.4 in a 100-wide sign column with the cards unchanged. I cannot see a real phone; the owner can.

---

## 4. Audit

**What I looked at:** contact sheets of every `stage2_*` (94), `sortstrip_*` (8) and `m11_*` (82) golden; every `unit_*` template golden
on phone and tablet landscape (92); `robot_*_phone_se` (12); `logic_*` (8); `c1*_phoneSE` (14); the tablet-portrait goldens of
`lesson_*`, `hint_*`, `c1*`, `sortstrip`, `stage2` (33); `ls01r_*_phoneSE` (24 of 27; the last three of the sheet order were not viewed). I opened at full size: `sortstrip_phone_sorted`, `sortstrip_tabletL_sorted`, `sortstrip_phoneSE_sorted`,
`stage2_numline_turn_phone`, `stage2_shop_turn_phone`, `stage2_robot_turn_phone`, `m11_celebration_numbers_phone`,
`m11_room_math_alone_phone`, `m11_room_math_show_phone_text_1_3`, `m11_room_logic_show_tablet_landscape`, `unit_chart_most_phone`,
`unit_clock_set_phone`, `unit_match_numbers_phone`, `lesson_6_celebration_tablet_portrait`. Sizes are measured from the code (cited)
or from these 1:1 PNGs (1 px = 1 pt).

**Not viewed one by one:** the 260 `hint_*` phone goldens (they are the same templates as the `unit_*` ones, plus the hint's picture;
every template finding below applies to its hint goldens), the `ls02`–`ls13` language goldens (built to `languages-l5-ls01.md`'s
reading sizes and QA'd per template), the `home`, `course`, `parent`, `hall`, `ceremony` screens. A second pass should sheet them with
`make_sheets.py`.

**Severity.** **S1:** what the child must see, count or touch is under its floor (it blocks the activity for a young child).
**S2:** under the floor but still usable, or a text or numeral under its rule. **S3:** wasted room (S1 to S5 of 2.3).

### S1 — content too small to see, count or touch (12)

| # | Goldens | What is too small (measured) | Fix (numbers) |
|---|---|---|---|
| A1 | `sortstrip_*_sorted`, `sortstrip_*_tray` | Animal in a bin card **9.3** (all boards). Animal in a tray card 17 / 15 / 19 / 25. Label 13 w700 | Section 3 |
| A2 | Every sort: `stage2_anyshape_*` (24), `stage2_closedshapes_*`, `countsides_*`, `polygondetectives_*`, `rectangle_*`, `rollorstack_*`, `shapesaroundus_*`, `solidandface_*`, `solids_*`, `squareorrectangle_*` (handover / turn / together), `unit_drag_sort*`, `unit_drag_share`, `logic_bins_*`, `hint_sort_*`, `hint_share_l3` | A sorted item in a bin is **26** (22 in a low bin) on **every board, tablets included** (`binBands.itemSide`). The bin label is **13 pt w700** (11 in a low bin): 9–10 px Hebrew letters with nikud. On tablets a 276 × 284 bin holds 26-pt items | 3.4: items in bins 48 phone, 44 SE, 64 tablets; labels 18 / 24 w500; the sort board of 3.3 |
| A3 | `unit_clock_set_phone`, `stage2_clock_show_phone`, `stage2_clock_turn_phone`, `hint_clock_l*`, `hint_tapb_hour_*` (phone) | Clock side `min(stage) − 8` = **120** → numerals `0.23 r` = **13.8** pt; SE 96 → **11** pt. Bottom 40 % empty | `withMeetStage` for the clock: phone stage 377 × 260 → side 252, r 126, numerals **29**. −/+/✓ in the tile column (3 pebbles 56, gap 12 = 192). SE: stage 264 × 256 → side 248, numerals 28. Tablets: side ≥ 380 on the taller stage (numerals 43). Rule R7: numerals ≥ 20 → side ≥ 174 |
| A4 | `unit_chart_more_*`, `unit_chart_most_*`, `hint_tapb_chart_*`, `hint_tapb_chart_total_*`, `hint_tapb_bars_*` | Pictures in a column **12–16** (phone), **≈ 20** on tablet L | Phone: the chart takes `withMeetStage`'s stage (377 × 260); 8 pictures per column fit at 26 (R2 24 ✓). The answer tiles cannot then stay under the stage, so either the 3 picture tiles become 3 × 56 in the column (Band B, under the 88 tile) or the chart is drawn in **rows** on phones (3 rows of 64, pictures 36). **Needs the curriculum-expert** (row against column). Tablets: card 848 × 400, pictures 40 |
| A5 | `unit_balance_compare_*`, `hint_balance_*`, `hint_measure_heavy_*`, `stage2_balance_*` | Things on the pans **10–12** (stars, boats) on the phone, **≈ 20** tablet. Cubes 14 | Pan items in rows of at most 3, **26** each on the phone (2 rows = 54 high on a 110-wide pan), **40** on tablets; the scale fills 90 % of the stage's width |
| A6 | `unit_same_or_not_phone` | Two sets of 5 apples at **12** | Each set in a dice / 2-row group, apples **28**, the two sets 140 wide each on the 330 stage |
| A7 | `unit_math_add_*`, `m11_room_math_alone_phone`, `m11_room_math_reacted_phone` | Counted apples **14** (unit) and **22** on the stall (room) | Apples **32** on the phone (R2 floor 24, and they are the sum), 48 tablet; the stall's busy crates under them at 40 % opacity |
| A8 | `unit_numeral_to_set_*`, `unit_more_big_things_*`, `unit_match_numbers_*`, `hint_tapb_pairs_*` | Sets on tiles **12–16** (birds, apples): `SpriteGroup` `line` with `lineSlots` 4 in a 96 tile → cell 20 | In a tile: ≤ 3 in a row with a cell of `inner / 3` (≈ 27, drawn 24); 4–6 as dice (2 rows); 7–10 as a ten-frame in a tile 1.6 × wide. Never under 24 (R2) |
| A9 | `stage2_counttap_*`, `unit_count_seven_*`, `lesson_2/3/4_*`, `hint_count_*`, `hint_qa_count_*` | Maths count-tap: `objectSize = clamp(0.34 h, 36, 60)` → phone 43.5 box, drawn apple / ladybird **≈ 22–24**; **touch `max(object, 48)` = 48** on the phone and **60** on tablets, under Band A's 64 | Use the language rule (`CountLayout._language`) for maths too: object cell ≥ 64, drawn `0.84 × cell` (≥ 48), touch = cell (≤ 96); `withTallStage` while counting when count ≥ 5 on phones (as `_tallWhileCounting` does for languages) |
| A10 | `unit_trace_numeral_*`, `unit_trace_start_only_*`, `hint_trace_l3*`, `stage2_tracetheshapes_*` | The figure to trace is **≈ 60–80** tall in an 80 × 80 pad (phone); the bottom half is empty | `withTallStage` (as `letter_write_session` does): pad 236 tall on the phone, numeral **≥ 200** (R10); SE 228; tablets 360+ on the taller card |
| A11 | `ls01r_story_*` (phone, SE), `ls01r_story_set_heb_*` | Story cards ≈ 90 × 55, the characters in them **≈ 14**; the stage above them is empty | `withLs01Zones`'s answer zone for 3 cards **170 × 128** (phone, characters ≈ 40) / 150 × 112 (SE); tablets 240 × 180 |
| A12 | `unit_shape_small_*` | Shapes on wide tiles **≈ 10** | If "small" is the point, the smallest is **24** (R1 exception) and the others 40+; otherwise 40 |

### S2 — under a floor but usable, or text and numerals under their rule (11)

| # | Goldens | What (measured) | Fix |
|---|---|---|---|
| B1 | `stage2_numline_*`, `unit_number_line_*`, `hint_numberline_*`, `c1b_estimate_line_*` | Labels **17 pt** fixed on every board (`number_line_session.dart` l. 539). Tick spacing **14.5** on 0–20 (phone). The marker's badge **≈ 12**. On 0–100, labels ≈ 10 px tall on the tablet | Labels **20** phone / **28** tablet. Ticks 4 × 20, major 6 × 28. Phone: the line in the answer band, 24,244 581 × 112 (spacing 0–20 = 26.6; 0–10 = 53), the scene above. Marker 40, badge numeral 20. 0–100: labels only at 0, 50, 100 and the target's ten |
| B2 | `stage2_robot_*`, `unit_robot_plan_*`, `robot_plan_*_phone_se`, `hint_robot_*` | The program strip is **30** high and its arrows (`Icon` 28 in a `FittedBox`) are drawn **≈ 16**; empty slots **≈ 12** | Strip **44** high, arrows **28** (never scaled down: fewer per row, or a second row), empty slot 20. Tablets 56 / 40. (design-spec §7.4 asks for a **vertical** strip; the build is horizontal. That is the developer's and curriculum-expert's call, noted here) |
| B3 | `stage2_shop_*`, `unit_shop_pay_*`, `unit_math_shop_*`, `unit_match_coins_*`, `hint_shop_*`, `hint_match_coin_*`, `hint_tapb_coins_*` | Coins in a purse **≈ 30** (1 ₪) to 34 (2 ₪) in `shop_pay` and `match_coins` (in `stage2_shop` 42 / 50). Digits on coins **≈ 13**. Price tag numerals ≈ 16 | Keep the real ratios (1 ₪ 18 mm : 2 ₪ 21.6 : 5 ₪ 24 : 10 ₪ 23): **1 ₪ 48, 2 ₪ 58, 5 ₪ 64, 10 ₪ 61** on phones, × 1.33 on tablets. Touch square 64. The digit on a coin ≥ 18 (R7). Price tags 24 / 32. The apple for sale ≥ 40 |
| B4 | `m11_room_cs_*`, `m11_room_math_*`, `unit_next_number_*`, `unit_chart_more_*`, `unit_set_to_numeral_*`, `c1_block_lit_rod_*` ("10 ........."), `stage2_*` tiles with dots | The dots under a numeral **≈ 5–6** | Dot **7**, gap 3, in groups of five (a gap of 7 between groups); 10 dots = 2 × 5 = 99 wide, which fits an 88+ tile. Or drop the dots where the numeral is the answer |
| B5 | `unit_drag_pattern_*`, `hint_pattern_*`, `stage2_pattern_*` (OK at 60) | `unit_drag_pattern`: row pictures **≈ 26**, empty slots **≈ 26** circles (drop targets) on the 330 stage | The row in two lines (`withStageAtLeast` as the 2-row pattern does), cells **52**, pictures 40, slot 52 with a snap of 1.5 × |
| B6 | `stage2_give_*`, `lesson_5_*`, `c1b_give_frame_*` | Apples to give **≈ 20**; `c1b_give_frame` (SE): 20 apples at **≈ 10**, ten-frame cells ≈ 12 | Give: apples 36 on the tall stage. Give-frame: frame cells **24** (two frames 250 wide), tray apples **28** in rows of 5 |
| B7 | `unit_set_to_numeral_*`, `lesson_3/4_*_tablet_*`, `hint_qa_count_l3_tablet_portrait`, `logic_spot_8_cells_phone_se` | Things to look at and count **≈ 20–24** (stars, butterflies, ladybirds; cats and dogs on SE) | R2: 24 floor, **32** on tablets; tablets get the 1.3× from the taller card (S2, S3) |
| B8 | `ls01r_sounds_*_phoneSE`, `ls01r_cloze_*_phoneSE` | A bin's header picture **≈ 24**; the cloze's context picture (chair) **≈ 28** | R1: 40 |
| B9 | `c1` hint cards (`docs/design/c1-blocks.md`, "Hint cards in Layout T ... exempt from the 12-point floor") | Cubes **9.1** (phone) and **7.7** (SE) at hint level 3 | Owner decision 3 |
| B10 | `lesson_6_celebration_tablet_portrait` (and the pre-M11 celebration on tablets) | Card 520 wide in an 820 board, characters ≈ 90 | Card 640 wide on tablets, as `RoomCelebrationCard` does (`tablet ? 640`); characters 160 |
| B11 | All sort trays (`_traySide`): `unit_drag_sort_three_*` and others | Tray tiles `clamp(tilesWidth / n − 10, 44, 84)`: never the look's 96 / 112, down to 44 with many items (under Band A's 64) | The look's tile; on phones the deck (3.2), on tablets one or two rows of the look's tile (3.4) |

### S3 — wasted room (3; each covers many goldens)

| # | Goldens | What | Fix |
|---|---|---|---|
| C1 | Every `*_tablet_landscape` / `*_tabletL` / `*_tabletLandscape` activity (unit, hint, stage2, m11, logic, lesson, c1) | The card is 584 × 300 at x 288: **264 pt empty at its start side** (only a landmark stands there in a room) and **≈ 200–250 pt empty under the tiles**. Contents keep phone sizes (bins 26, number-line labels 17, counted things 20) | 2.3 S2: `withWideStage` for every template, a card of 848 × 400 with one row of tiles (tiles at 654), and contents scaled to the card (S5). A room's landmark moves into the card's end-bottom corner, as on phones |
| C2 | Every `*_tablet_portrait` / `*_tabletP` / `*_tabletPortrait` activity | Card 772 × 300 (design-spec §7.3: 772 × 560); **≈ 330 pt empty** at the bottom | 2.3 S3: card 772 × 520, tiles at 916 |
| C3 | Phone screens with an empty answer band: `stage2_counttap_*`, `stage2_give_*`, `stage2_numline_*`, `stage2_tracetheshapes_*`, `stage2_*_show_phone` greetings, `m11_room_*_show_phone` (host greeting), `unit_number_line_place_phone`, `unit_flash_dice_phone`, `unit_trace_*`, `ls01r_story_*` | 330 × 128 stage over a **≈ 130 pt empty** band | 2.3 S1: `withTallStage` / `withPictureStage` per screen (A3, A9, A10, B1, A11). The host's greeting may keep its window (S4 exception) |

**Counts: S1 12, S2 11, S3 3 (26 findings, each a family of goldens).**

### 4.1 Top ten (what to build first)
1. **A1 + A2 + B11: the sort board (section 3)**, every `sort_drag` on four boards. It is the owner's screenshot and the most frequent
   Stage 2 template.
2. **A9: count-tap touch squares 48 / 60, under 64.** A Band A floor is broken.
3. **A3: clock numerals 13.8 / 11.**
4. **A4: picture graphs at 12–16** (with the curriculum-expert).
5. **A8 + A6 + A7: counted sets at 12–16** (`SpriteGroup` line cells).
6. **A5: balance pans at 10–12.**
7. **A10: trace pad 80 × 80.**
8. **C1 + C2: tablets keep phone sizes** (`withWideStage` and the 520-tall portrait card everywhere).
9. **B1: number line labels 17, spacing 14.5.**
10. **B3: coins 30 pt with 13-pt digits.**

---

## 5. Checklist for an automated test (qa-engineer)

A test per template family that opens the item on each of `boards` (`test/support/c1_screens.dart`: phone 852 × 393, phoneSE 667 × 375,
tabletL 1180 × 820, tabletP 820 × 1180) at text size 1.0 and 1.3 (`MediaQuery.textScaler`), and checks with `tester.getRect` /
`tester.getSize`. Phone and SE thresholds are the same; tablets have their own.

### 5.1 Generic (every activity golden test can call one helper, `expectMinSizes(tester, board)`)
- Every `AnswerTile` (`Key('answer-tile')`): height ≥ the look's tile (P1/P2 96 phone, 112 tablet; P3 88 / 104; P4 80 / 96), and
  hit area ≥ `minControl` (64 Band A, 56 B/C).
- Every `PackSvg` / `SvgPicture` that is a stage picture or a tile's picture: shorter side ≥ 40 (tablet ≥ 40, flag < 56 as a warning),
  except widgets marked as composites (below) and the scene backdrop (`BoxFit.cover`).
- Every `Text` whose style has nikud content inside the stage or a bin: font size ≥ 18 phone / 20 tablet, `fontWeight` ≤ w500 when
  the size is < 24, `height` ≥ 1.7.
- Every numeral `Text` in a stage (digits only): size ≥ 20 phone / 24 tablet (a coin's digit ≥ 18).
- **Room use (S4):** the union of the rects of `Key('…-stage')` and the tile row ends no more than 25 % of the board's height above
  the board's bottom safe line (phone 98, tabletL 205, tabletP 295), except the celebration and Show greeting.
- **Tablet card (S2, S3):** the stage rect is ≥ 848 wide on tabletL, and ≥ 520 tall on tabletP (≥ 420 with two rows of tiles).
  Amended 2026-11-20 (9.6): "two rows" is read at the item's **start** (D4); Layout T has no card and is measured on its tile row (D12).

### 5.2 Per template (keys exist today unless marked new)

| Template | Measure | Phone / SE | Tablet L / P |
|---|---|---|---|
| sort (`sort_drag`) | `bin-card-<id>` (new) height for a strip; its width / height = 2.5 | ≥ 68 (phone 76) | ≥ 100 (P 112) |
| | square item in a bin (`bin-card-<id>`) | ≥ 44 (phone 48) | ≥ 64 |
| | tray card inside `item-<id>`: the `SvgPicture` height for a strip | ≥ 68 | ≥ 100 |
| | `bin-label-<id>` font size / weight | ≥ 18, ≤ w500 | ≥ 24, ≤ w500 |
| | `bin-sample` side | ≥ 40 | ≥ 56 |
| | `bin-count-<bin>` (new) exists when a bin holds more cards than it shows; numeral ≥ 20 | ✓ | ≥ 24 |
| | no card in a bin narrower than the table (a pile, not a shrink): `bin-card-*` rects all equal | ✓ | ✓ |
| count-tap | touch square per object (`count-stage` children) | ≥ 64 (Band A) | ≥ 64 |
| | drawn object side | ≥ 40 | ≥ 56 |
| clock | `clock-face` side | ≥ 174 (→ numerals ≥ 20) | ≥ 240 |
| number line | `line-stage` tick spacing (width / range) | ≥ 24 | ≥ 32 |
| | label font | ≥ 20 | ≥ 28 |
| balance | each picture on a pan (`scale-blocks` children) | ≥ 24 | ≥ 32 |
| chart (`stage-chart`, `tap-chart`) | each picture | ≥ 24 | ≥ 32 |
| set on a tile (`tap-groups`, match pairs) | each sprite of a `SpriteGroup` | ≥ 24 | ≥ 32 |
| robot | each arrow `Icon` in `robot-program` (rendered size after `FittedBox`) | ≥ 28 | ≥ 40 |
| shop | each coin in `purse` | ≥ 48 (1 ₪) | ≥ 64 |
| | `price` numeral | ≥ 24 | ≥ 32 |
| trace | `trace-stage` height | ≥ 220 | ≥ 360 |
| give | `give-tray` pictures | ≥ 32 | ≥ 48 |
| story / order | a card's picture | ≥ 40 | ≥ 56 |

The sizes of a `SvgPicture` inside a composite (a strip, a set) are measured on the widget that holds the composite. The test
multiplies by the composite's detail share (a strip: 0.143 of the width), so the check is on the detail, not on the box.

---

## 6. Decisions for the owner

1. **On phones, a sort's tray becomes a deck: one card at a time** (3.2). It is the only way a phone shows the pattern cards with 24 pt
   animals, and it is calmer for 3- to 4-year-olds. The earlier sorted cards pile in their shelf with a number badge. Mock:
   `docs/design/m11/min-sizes/strip_sort_phone.png`. Tablets keep showing all the cards.
2. **Every tablet screen grows** (C1, C2): the landscape card from 584 to 848 wide and up to 400 tall, the portrait card from 300 to
   520 tall. This changes the look of every tablet golden, and the owner should see a batch after the build.
3. **The c1-blocks hint card exemption** (cubes 9.1 pt phone, 7.7 SE at hint level 3, accepted earlier in `c1-blocks.md`): keep it (the cubes are
   read in tens there) or ask for a bigger card that covers the tiles while the hint shows.
4. **Picture graphs on phones** (A4): bars in rows on phones, columns on tablets? This one goes to the curriculum-expert first.

## 7. Hand-offs
- **app-developer:** section 3 (sort board), then A3, A9, A10, A8, A5, A6, A7, B1–B8, C1–C3, in the order of 4.1, with the goldens
  named in each row to update.
- **curriculum-expert:** A4 (rows or columns on phones), B2 (vertical program strip per design-spec §7.4), A12 (is "small" a
  deliberate size item?).
- **qa-engineer:** section 5 as `test/min_sizes_test.dart`, once the sort board lands, then per template as each fix lands.
- **hebrew-text-editor:** none. The labels keep their words, at 18 / 24 pt w500.

---

## 8. Addendum 2026-11-17

Design director, branch `lands-ux` at 7e7b17aa, after the developer's round 1 (`docs/agents/dev-report-2026-11-17.md`). It is a spec
and a review only; nothing in `app/` changed. The owner said yes to section 6, decisions 1 to 3, so phones sort one card at a time,
every tablet screen grows, and **the c1-blocks hint-card exemption is dropped**.

Mocks (script `min-sizes/make_addendum_mocks.py`, drawn over the round-1 goldens taken from 7e7b17aa with `git show`):
`min-sizes/add_b9_hint_card_phone.png`, `add_size_bins_phone.png`, `add_numline_phone.png`, `add_numline_tabletL.png`,
`add_balance_phone.png`, `add_ten_tiles_phone.png`. Review sheets: `min-sizes/review-round1/` (8.4, 8.5).
`make_sheets.py` now takes `GOLD=<dir>` so it can sheet a frozen snapshot.

### 8.1 B9: the hint card of a where-is item on tiles (Layout T), with no exemption
**The rule.** A hint card draws its blocks at **the tiles' cube u** (c1-blocks 4.7, one u per item): 12.7 on the phone and 13.2 on the
SE, never under 12. On phones it does this by drawing the **rods lying down**. A lying rod is 10 u long and 1 u thick, so four tens
need 4 u of height and not 10.3 u. The box stays where the developer put it (between the top bar and 16 over the tiles), so nothing
else on the screen moves.

| | Phone | Phone SE | Tablet L | Tablet P |
|---|---|---|---|---|
| Card box | 262 × 104 (95, 92) | 230 × 96 | as built (cube 19.6) | as built (cube 20.1) |
| u | **12.7** (the tiles') | **13.2** | as built, standing rods | as built, standing rods |
| Rods | lying, left to right, tens stacked **4** apart | lying, **3** apart | standing | standing |
| Ones | a lying 5-frame (rows of five, 1 apart, rows 2 apart), **14** to the right of the tens, bottom-aligned with them | same | as built | as built |
| The number | on top, **20 w800 LTR**, ink, no badge (today a 10-pt badge) | 20 | 28 | 28 |
| Fit (4 tens, 9 ones, Layout T's limit) | 210 × 91 in 246 × 96 | 214 × 90 in 218 × 90 | | |
| Level 2 (a digit beside one rod and one cube) | one lying rod, the digits 28 w800 beside the rod and the cube | 24 | as built | as built |

- Level 3 counts the rods as "ten, twenty, thirty": each lying rod lights as one piece, then each one-cube lights in turn. A cube of
  12.7 or more is big enough to light one by one.
- **Never mirrored.** Tens come first at the left, so the card reads 3 then 4, the same order as the digits.
- The rods on the tiles stand up and the ones in the card lie down. The voice line already says "three rods and four cubes", and a lying
  rod is the same ten linked cubes. The mock shows the two side by side. This is the one real design choice in this addendum (8.8).
- For the developer: the hint card's `BaseTenPicture` gets `orientation: lying` and the item's `sharedUnit`. Test
  (`hint_tap_c1_test.dart`): the hint card's u equals the tiles' u and is ≥ 12 on SE, at every level, for every Layout T item.
  The exemption paragraph in `docs/design/c1-blocks.md` §10 is superseded by this section. I did not edit that file because it is
  outside this task's scope; the orchestrator can add a pointer.

### 8.2 The size rule's samples (big and small) and its items
**What is wrong.** `ball_size_s` draws its ball at 0.35 of the box, so its ink is about 27 % of the box. In the 64 sign box that is
**17 pt**, and in a 48 well box it would be **13**. A bigger box only makes the empty margin bigger.

**The design.** Size is relative, so a sign shows **both sizes**: the rule's own size is drawn fully, and the other size stands beside it
as a ghost at opacity **0.3**. Both are drawn with **`ball_size_l`** (the full-box art) at two box sizes. A sign never uses the
`_s` / `_m` sprites. The items in a well keep **the tray's scale**, so a small ball stays small next to a big one, and neither is
shrunk to the 48 of a square item.

| | Phone (2 shelves 361 × 116) | Phone SE (252 × 116) | Tablet L | Tablet P |
|---|---|---|---|---|
| Sign | column **104** wide (was 72) | column **96** | header row **80** high | header 80 |
| Boxes (ink) | **31 / 62** (24 / 48), 6 apart | **31 / 56** (24 / 44) | **40 / 80** (31 / 62), beside the 24-pt label | same |
| Label | 18 w500 h1.7 under the pair | 18 | 24 beside | 24 |
| Item in the well | the tray's box **88** (small ink 24, big 69); one shown, then a pile with the badge | 86 | **112** (small 30) | 112 |
| Three sizes (big, middle, small) | three shelves 361 × 76: boxes 31 / 46 / 62 in a row, label at its side, column 160 | 30 / 44 / 56 | 40 / 60 / 80 | same |

The same applies to every `*_size_*` set (apple, fish, star): only `*_size_l` is drawn in a sign, and it is drawn at the box sizes above.
Mock: `add_size_bins_phone.png`.

### 8.3 The number line, the numeral-to-set stage, the balance, ten on a tile

**Phone number line (the empty top left).** The line stays in the answer band (24,244, 581 × 112, as built). The top left gets a
**number sign**, and the bubble moves beside it. Mock: `add_numline_phone.png`.
- Sign: a paper card **24,100 160 × 132** (border hairline 3, radius 16). SE: 16,86 120 × 120.
- Place and estimate: the number to find, **64 w800 LTR** (SE 48). Two digits fit; "47" on 0–100 also fits at 64.
- Jump and back: the start numeral **56** on top, and under it **one arc per hop**, 28 wide, 12 high, stroke 4, `skyDeep`, with an
  arrowhead, in rows of five. Forward arcs run left to right and back arcs right to left. They point the way the marker moves, and RTL
  never flips them. SE: 48, arcs 22 wide in rows of four.
- Bubble: 196..603 × 100..232 at the look's caption, never under its floor (24 phone). SE: 148..476.
- Marker: a **56** box standing on the line (the frog's ink is about 44; today it is 30). Hop arcs on the line rise at most 40 above it.
- Hint hop numbers: chips 32 with the digit 20 w800, over each arc's top (today 10–12).
- The sign repeats the prompt: the number said, or the start and the hops said. It never shows the answer. **Curriculum-expert to
  confirm** that showing the target on a place item is wanted (it helps a child who forgot the spoken number).

**Tablet number line.** Mock: `add_numline_tabletL.png`.

| | Tablet L | Tablet P |
|---|---|---|
| Card | 24,230 848 × 400 (was the 584 card for place / jump) | 24,372 772 × 520 |
| Line | at **0.75** of the card (y 530), from 80 to 816; 0–10 spacing 73.6, 0–20 36.8 | at 0.72 (y 746), 64..756; 0–10 69, 0–20 34.6 |
| Ticks, labels | 4 × 24, labelled 6 × 32; labels **28** w800 | same |
| Marker | **80** box (today 52, frog ink 30) | 80 |
| Sign | 220 × 160 in the card's top left (56, 262): numeral **72**, arcs 40 wide, stroke 5 | 220 × 160 |
| Hops on the line | arcs up to 120 high, hint chips 40 with digit 24 | same |

**Numeral-to-set and set-to-numeral stages** (`unit_set_to_numeral_*`, `tap_count`, `hint_tap_count_*`, `hint_tap_add_*`). Things
to count (R2), in cells, five to a row, at most two rows, centred:
- phone: cell **52**, thing 40 (stage 330 × 128 holds 2 × 5 = 260 × 104)
- SE: cell 48, thing 36
- tablet L: card **848 × 400** (`withBigStage`), cell **96**, thing 64, tiles 3 × 112 under the card at 654
- tablet P: card 772 × 520, cell 104, thing 72, tiles at 916

A number tile shown on the stage (the "5" card in `tap_add`) is 72 tall with numeral 48, and 96 / 64 on tablets.

**A5, the balance, refined after round 1.** Mock: `add_balance_phone.png`. Round 1 moved the answer tiles of other templates into the
192-wide column under the bubble, which holds only two 88 tiles. A balance has three (←, =, →), so its tiles stand **in a row under the
bubble and the guide**: the guide's figure ends by y 245 on every phone golden, and the band under it is empty on every phone screen.

| | Phone | Phone SE | Tablet L | Tablet P |
|---|---|---|---|---|
| Stage | 24,96 377 × 260 (`withMeetStage`) | 24,86 264 × 256 | card 24,230 848 × 400 | card 24,372 772 × 520 |
| Pivot, post | (212.5, 236), post to 342, base 124 wide | (156, 220) | centre, 0.4 of the card from the top | same |
| Beam (between the pans' centres) | **191**, tilt ≤ 6° | 148 | 520 | 470 |
| Pans | level trays **170** × 10 on a 16 stem (a tray stays level as the beam tilts) | 124 | 300 | 280 |
| Things on a pan | **30** box (ink ≥ 24), rows of **five**, 4 apart, up to three rows (15) | **28** (ink 23, the SE floor), rows of four, three rows | **44**, rows of five, 8 apart | 44 |
| Answer tiles | 3 × **88** at x 413 / 513 / 613, y 262 | 3 × 88 at 300 / 396 / 492, y 236 | 3 × 112 under the card at 654, centred | at 916 |
| Arrows | icon 40, ← points at the left pan; never mirrored | 36 | 48 | 48 |

Hint hands point at the tiles' centres. The "−/+" of `balance_weigh` use the same row, as two tiles.

**Ten pictures on one tile** (a set of 7 to 10; today about 19). Mock: `add_ten_tiles_phone.png`. The floor is on the **ink**. The
app's round sprites (apple, ball, star) fill about 0.75 of their box, so a 24-pt ink needs a **32** cell. A set on a tile is laid
out by its count:

| Count | Layout in the tile | Phone tile | SE tile | Tablet tile (cell × 1.25) |
|---|---|---|---|---|
| 1–2 | one row, cell 40 | 96 × 96 | 88 × 88 | 112 |
| 3–4 | 2 × 2, cell 38 | 96 × 96 | 88 (cell 36) | 112 |
| 5–6 | 3 × 2, cell 36 | **128** × 96 | 120 × 88 | 160 × 112 |
| 7–10 | a **5 × 2 frame**, cell **32** (gaps 1 / 2) | **177** × 96 | 172 × 88 | **224** × 112 |

- A row of up to three 177 tiles takes the **wide answer band 24..605** (555 with 12 gaps), as the number line does.
- SE: three 172 tiles need 532, so they use **8..651** under the guide. The guide's figure ends by y 205, and the SE tiles start at 214.
- Four or more sets of 7–10 do not fit a phone. That is a content rule: at most three such options (curriculum-expert, validator).
- **Never a pile with a count** for a set whose quantity is the question. A pile with a badge is only for things whose count is not the
  answer: the cards sorted into a bin, the things already bought, the plates of a share (where the badge is the point).
- `tileGroup` (`sprite_group.dart`) changes: cell from the table, not `inner / 3`; the tile's width comes from its count. In a row
  of tiles, all tiles take the width of the widest one.
- 2026-11-20 (9.2 D9): the 5 × 2 frame is also the layout of a **group of 7 to 10 on the stage** ("line" arrangement), on every board,
  and the hint hand reads the object centres from the same layout function.

### 8.4 design-spec §7.4 and §8: the robot program strip (B2)
Updated in `docs/design-spec.md` (§7.4 "Robot coding" row and §8 "Robot program strip" row): horizontal, left to right from a start dot,
never mirrored, arrows 28 (40 on tablets), strip 44 (56 on tablets), wrapping to a second row that also runs left to right. The source is
the curriculum decision in `docs/milestones/M11-stage2.md` §11.8. Round 1 has not built it yet (`stage2_robot_turn_phone`: the strip is
30, its arrows about 18, no start dot).

### 8.5 Review of round 1, as built
Sheets (snapshot of 7e7b17aa, at 0.5): `review-round1/sort_00..03`, `clock_00`, `count_00..02`, `sets_00..01`, `trace_00`,
`numline_00..01`, `coins_00..02`, `celebration_00..01`. I opened 1:1: `sortstrip_phone_sorted`, `sortstrip_phoneSE_sorted`,
`sortstrip_tabletL_sorted`, `sortstrip_tabletP_sorted`, `unit_drag_sort_phone`, `unit_drag_sort_three_phone`,
`unit_drag_sort_three_tablet_landscape`, `stage2_anyshape_turn_tabletL`, `hint_clock_l3_phone`, `unit_clock_set_tablet_landscape`,
`stage2_counttap_turn_phone`, `lesson_2_count_three_answers_phone`, `ls01_count_answer_phone`, `hint_count_l3_phone`,
`unit_match_numbers_phone`, `unit_more_big_things_phone`, `unit_set_to_numeral_phone`, `unit_number_line_jump_phone`,
`unit_shop_pay_phone`, `unit_shop_pay_tablet_landscape`, `stage2_shop_turn_phone`, `lesson_6_celebration_tablet_landscape`,
`m11_celebration_numbers_phone_se`.

**What passes.** The sort board is right on all four boards: an animal in a bin card is 27 / 24 / 43 / 40, a tray animal 25 / 27 / 36 /
43, labels 18 / 24 w500, piles with badges, and no empty band over the S4 limit (tablet L 180, P 235). Count-tap objects are 40–45 pt
(the stage2 ladybirds), and the count badge numeral is 26. The clock numerals are about 26 on the phone and 36 on tablet L, with a 356
face. The trace pad is 247 on the phone (figure about 200) and 360 on tablets. Number-line labels are 20 / 28, with tick spacing 53.7 on
0–10. Coins on the phone purse are 48 / 56 with digits about 22. The m11 celebration on SE is 22 / 18 pt.

**What still fails (16: S1 1, S2 12, S3 3).**

| # | Sev | Goldens | Measured | Fix (numbers) |
|---|---|---|---|---|
| V1 | S1 | `unit_match_numbers_*`, `hint_match_l3_*`, `hint_tap_numerals_l3_phone`, `unit_more_big_things_*` (sets on tiles) | A8 sized the **box** (cell 27); the apple's **ink** is about 0.74 of it, so **18–20** pt. Birds on tiles about 16 | 8.3, "Ten pictures on one tile": a cell of 32 or more by count, tile width by count |
| V2 | S2 | Every frame with no look: `unit_*`, `hint_*`, `lesson_*`. Measured: `hint_count_l3_phone` **17**, `hint_tapb_ten_more_l3_phone` 17, `hint_tapb_after_l3_phone` 17, `unit_number_line_jump_phone` **21**, `hint_shop_l3_phone` about **14**, `hint_shop_l3_phone_se` about **13** | `activity_frame.dart` l. 338: `min: look == null ? 14 : …`, so a long hint line shrinks to 14 | Floor with no look: **22 phone, 20 SE, 28 tablet** (P3's −2). The bubble first grows down to the tiles' top − 12, then widens to the start side over empty stage. If it still does not fit, the hebrew-text-editor shortens the line (lines over 3 at the floor are listed by a test) |
| V3 | S2 | `unit_clock_set_*`, `hint_clock_*`, `stage2_clock_*` (all boards) | The **minute hand runs through the "12"**: numerals are centred at 0.68 r, and the minute hand reaches 0.86 r over them | Numerals centred at **0.78 r**; minute hand **0.62 r**, hour 0.45 r; hands painted under the numerals, and each numeral gets a 3-pt paper halo |
| V4 | S2 | `hint_clock_l3_phone` (hand over the bubble's last two lines), `hint_share_l3_phone` (over "עַכְשָׁו תּוֹרְכֶם"), `hint_count_l3_*` (the hand hides the apple it counts), `hint_shop_l3_*` | Hand 60 × 85 laid on the caption or on its target | A hint hand never overlaps the bubble or its target. The tip stops **8 outside the target's edge**. When the target is under the bubble, the hand comes from below (tip up). Test: the hand's rect and the bubble's rect do not intersect |
| V5 | S2 | `unit_more_big_things_*` | Small apples on purpose, ink **18** (R1 small floor 24); the stage above is an **empty landscape** | Phone: the two set tiles stand on the picture stage (24,96 377 × 253), each 176 × 160, small ink 30, big 56; nothing under. Tablets: tiles 224 × 160 on the 848 card |
| V6 | S2 | `unit_shop_pay_tablet_landscape`, `hint_shop_l3*_tablet_*`, `unit_shop_pay_phone`, `stage2_shop_*`, `hint_shop_l3_*` | Tablet coins **47 / 56** (expected 64 / 77: the "third larger" did not take; the card is still 584). Apple for sale **24** on the phone and 40 on the tablet; the hint's item (a yellow block) **16**. Price numeral 20 on tablets | Tablet: `withBigStage` and coins × 1.333 (1 ₪ 64, 2 ₪ 77, 5 ₪ 85, 10 ₪ 81). Item for sale **40** phone / 64 tablet. Price numeral 24 / 32 |
| V7 | S2 | `unit_match_coins_*`, `hint_match_coin_*`, `hint_tapb_coins_*` | Coins on tiles **30–34**, digits about **14** (coin rule 18) | Coin on a tile at the real ratio with 5 ₪ = 80 (1 ₪ 60, 2 ₪ 72, 10 ₪ 77), digits ≥ 20; tablet 5 ₪ 96 |
| V8 | S2 | `lesson_2_count_three_answers_tablet_*`, `lesson_3/4_*_tablet_*`, `hint_count_l3_tablet_landscape` | The target (flower, basket) about **40** and its count badge digit about **14** on tablets | Tablet target **72**, badge 40 with digit 24 (the phone's 26 badge is fine) |
| V9 | S2 | `unit_drag_sort_three_phone`, `unit_drag_sort_three_tablet_landscape`, `stage2_anyshape_turn_tabletL` | A three-shelf sample is a pair at **30** each (R1 40). Tablet samples are a pair at **40–44** (target 56). A sorted shape in a tablet bin is **52** (rule 64), and the tray tiles 96 (tablet 104 / 112) | A three-shelf sign shows **one** sample at 40. Tablet header: one sample 72 (or a pair of 56). Tablet items 64; tray tiles at the look's tablet size |
| V10 | S2 | every size sort (`*_size_*` samples) | Small sample ink **17**; small item in a well about 13 (computed) | 8.2 |
| V11 | S2 | `lesson_6_celebration_tablet_*` | Nitzi 125 tall, the hero cameo **70** on its pebble (the report says 160) | Both cameos 160 tall on tablets, 112 on phones |
| V12 | S2 | `unit_trace_*`, `hint_trace_l3_*`, `stage2_tracetheshapes_*` | The start dot the child aims at is **14** (tablet 16); guide dots 6 | Start dot **28** with a 40 halo ring (tablet 36 / 52), as R10's aim target |
| V13 | S2 | Hint chips: `hint_clock_l3_*` (16), `hint_count_l3_*` (16), `hint_numberline_jump/back/place_l3_*` (**10–12**), `hint_tap_count_l3`, `hint_tap_numerals_l3`, `hint_tapb_sides_l3`, `hint_tapb_corners_l3`, `hint_robot_l3` (14), `hint_spot_n_l3_card` (12) | The circled count numbers of a hint, digits **10–16** | Chip **32**, digit **20** w800 LTR (tablet 40 / 24); it stands outside the thing it counts |
| V14 | S3 | `unit_number_line_*_phone`, `stage2_numline_*`, `c1b_estimate_line_phone*` | The top left is empty (24..290 × 96..236); the marker frog's ink is **30** | 8.3 (number sign, marker 56) |
| V15 | S3 | `unit_number_line_*_tablet_*`, `c1b_estimate_line_tablet*`, `hint_numberline_jump_l3_tablet_landscape` | The marker box is 52 (ink 30). The line sits in the bottom third of the card with two thirds empty sky (S5) | 8.3, tablet table |
| V16 | S3 | `lesson_3_scattered_midway_tablet_landscape` (220 empty under the card, limit 205), `lesson_3/4_*_tablet_portrait` (about **330**, limit 295), `unit_count_seven_tablet_landscape` (180) | While counting there are no tiles, so the room under the card is empty | On tablets the count's answer tiles stand **inside the card's bottom band** (a row 136 high), and the card reaches the bottom line while counting: landscape 24,230 848 × 534, portrait 24,372 772 × 728. The card never changes size between counting and answering |

### 8.6 The audit, extended (hints, languages, screens)
Sheets: `review-round1/audit_hint_l3_phone_00..05` (every hint family at its last level on the phone, 71), `audit_hint_tablet_00..05`
(all 42 tablet hints), `audit_lang_phone_00..05`, `audit_lang_tabL_00..05`, `audit_lang_tabP_00..04`, `audit_lang_se_00`,
`audit_lang_l7_00..01`, `audit_screens_home_00..02`, `audit_screens_course_00..01`, `audit_screens_hall_00`,
`audit_screens_parent_00`. Findings already in §4 (A4, B2, B4, B5, C1, C2) or in 8.5 (captions V2, chips V13, hands V4) are not
repeated. The language and screen pass was done with a second design-director run on the same snapshot. It measured glyph ink, so
its text sizes are ±1 pt.

**New findings: 22 (S1 5, S2 15, S3 2).**

| # | Sev | Goldens | Measured | Fix |
|---|---|---|---|---|
| HX1 | S1 | `hint_tap_add_l3_phone` (stars **12**), `hint_flash_l3_phone` (apples 14), `hint_tap_count_l3_phone` (ladybirds 14), `hint_tapb_pairs_l*_phone` (shoes **16**) | Counted things on the 330 × 128 stage | 8.3 numeral-to-set table (thing 40 in 52 cells). Pairs: shoes 40, a pair 88 wide, three pairs to a row |
| HX2 | S1 | `hint_tapb_after_l3` (digits **14** in 28 × 30 cards), `hint_tap_sequence_l3`, `hint_tapb_take_one_l3` (1..10 strip, digits about **10**), `hint_tapb_skip_l3` (10..100, about **9**) | Number strips squeezed to fit the stage | Cards **44 × 48**, digit **24** w800 LTR, gap 4; show a **window of seven** around the target (the rest as a fading edge). Skip counting shows its own row (10, 20 … 100) on two rows of five. Tablets 56 × 60 / 28 |
| HX3 | S1 | `hint_tapb_add_more_l3` (rods about **9**), `hint_tapb_sentence_l3` / `_part_l3` (cubes 9), `hint_tapb_ten_more_l3` (11), `hint_tapb_growing_l3` (tower cubes in tiles about 10), `hint_tapb_bars_l3` / `hint_tapb_to_ten_card_l3` (14), `hint_tapb_whole_parts_l3` (16) | Base-ten and cube pictures in Band B hints under the c1 floor of 12 | One u per item (c1-blocks 4.7) of at least **14** on phones (19 on tablets). Rods lie down where the height is short (8.1). A cube tower on a tile has at most 6 cubes of 14, or it shows a count |
| L1 | S1 | `ls10_personal_family_*` (all boards) | 8 answer bubbles of 56 with pictures **32–36**. On the phone the second row is cut at y 275 by the stage, and the skip pebble (84..138 × 282..336) covers it. 8 choices is over `maxChoices` (A 3, B 4) | At most **4 at a time** on tiles of 88 (phone) / 104, pictures 56 / 72, a 64 "more" pebble, the prompt picture 64. Tablets: 2 rows × 4 tiles of 112 on the 848 × 400 card |
| L2 | S1 | `ls13_probe_*`, `ls13_thanks_*`, `l7_find_layout_3_*`, `l7_find_first_text13_phoneSE`, `l7_trail_12_*` (phone, SE) | Pictures to tell apart on the 330 × 128 stage: trail figures 37–41 wide, the SE doors 64 × 95 with a 36 parrot, the telling detail (a pose, a wave) about **10**. The answer band is empty (phone 123, SE 115; limits 98, 94) | `withPictureStage` 377 × 253 (SE 264 × 256): 3 pictures 110 wide with gaps of 24, or 2 at 150; trail figures ≥ 120 tall |
| HX4 | S2 | `hint_share_l3_phone` | The plate's apples about **22**, badge 24 | §3.4 share: a plate shows its items at 40 with the badge 32 / 20 |
| HX5 | S2 | `hint_spot_p_l3_card_phone` | Animals in the cards about **30** (R1 40) | Cards 56 with the animal 44, three to a row |
| HX6 | S2 | `hint_tapb_week_*` | The calendar icons about **22**; the days marked by 3-pt dots | Calendar 48, day dots 6 with gap 3; the numeral of the day (if shown) 20 |
| L3 | S2 | `ls08_question/row`, `ls10_bubbles*`, `ls12_ends/rhyme` (side speaker **44**), `ls03b_*` (card speaker **30–32**) | Under the touch floor (56 B / 64 A) | Side speaker 56 (64 Band A), icon 32; card speaker 48 with hit slop to 64 |
| L4 | S2 | `ls10_personal_age_*` | Numeral answers are 56 circles with numerals about **32** | `AnswerTile` 96 / 112, numeral 56 / 72 |
| L5 | S2 | `ls05_wheel_*`, `ls04_stem_wheel_heb_*` | Nikud chips 46–54. The made unit in the centre is about **40**, smaller than the wheel letters (48) | Chips 56 (64 Band A); centre tile 104 × 88, letter 56 (tablet 64) |
| L6 | S2 | `l7_meet_*_lookC_letters_*` | The word in a chip is about **24–25** (Band C word 34 / 40) | The band's word size, chip 56 high |
| L7 | S2 | `ls02_word_heb_*` | Writing pad 190 × 190, writing band **103** (the trace pad is 250) | `withTallStage` 330 × 253 pad, the 46 boxes above it |
| L8 | S2 | `ls03_taps/drum/hands_*` | Beat dots **18**, hands about 20 (R2 24 / 32) | Dots 28 / 40, gap 12 |
| H1 | S2 | `home_island_*` | Landmark labels (גְּבִיעִים, מַדְבֵּקוֹת, …) about **14** (tablet L 15) on the sand, no plate | 18 w500 h1.7 (24 tablets) on a sign plate, like the land signs |
| H2 | S2 | `home_*` | Nitzi's map bubble about **16** | 20 phone, 24 tablet |
| H3 | S2 | `island_counting_*`, `island_colors_*` | Legend (מִתְרַגְּלִים / יוֹדְעִים / …) about **11–12**; path icons 43 × 29 | Legend 18 w500 (or icons only, voiced); path icons 40 tall |
| H4 | S2 | `hall_*` (phone) | Land row labels about 15–16; "2/4" counts about 14; medal titles 21 at **w700 with nikud** (the rule is ≤ w500 under 24); descriptions 16 | Row label 18 w500; count 20 w800 LTR; title 24 w700 (or 20 w500); description 18 |
| H5 | S2 | `ceremony_prize_phone` | Prize-card labels about 15–16 | 18 w500 |
| H6 | S2 | `progress_view`, `gate_*` (parent area) | Row and status text about **13–14**; the gate subtitle 13–14 in grey | Parent text **16** minimum, grey only at 16 + |
| L9 | S3 | `ls08_question_tabletPortrait` (320 empty, limit 295; tiles 96), `ls03b_*`, `ls08_row`, `ls10_bubbles*`, `ls11_buttons`, `ls12_ends/rhyme` tablet portrait (about 400–530 empty) | C2 for the language templates | Card 772 × 520, tiles at 916 at 104 / 112, pictures 72 / 80 |
| H7 | S3 | `course_home_eng_invite_tabletLandscape` (and phone) | Path node "6" cut at the board edge (1136..1180+) | Fit the nodes inside the island (gap 40), or make the path scroll with an edge peek |

(Tablet landscape language screens in the 584 card, `ls02`, `ls03`, `ls10`–`ls13`, are C1 again. The tablet hints keep phone sizes
in phone-size cards, for example `hint_qa_teens_l2_tablet_portrait` with 16-pt ten-frame cells in a 772 card and `hint_robot_l3_tablet_landscape` with
60-pt grid cells. That is also C1 / C2 and is not counted again.)

### 8.7 Top ten (what to build next, after the rest of section 4)
1. **V2** the caption floor of frames with no look: 13–17 pt text on most `unit_*` / `hint_*` / `lesson_*` screens.
2. **L1** `ls10_personal_family`: answers cut off and covered on the phone.
3. **V1 + HX1** counted things at 12–20 (sets on tiles by ink; things on the stage at 40).
4. **HX2** number strips with 9–14 pt digits.
5. **L2** picture choices on the 330 × 128 stage in `ls13` / `l7` find and trail.
6. **HX3 + 8.1** base-ten in hints under 12 (one u per item, lying rods).
7. **V13 + V4** hint chips at 10–16 and hands over the caption or the target.
8. **V6 + V7** coins on tablets (not grown) and on tiles (digit 14).
9. **V14 + V15** the number line (sign, marker 56 / 80, tablet line at 0.75).
10. **L3 + L4** speakers and numeral answers under the touch floor in the language lessons.

### 8.8 For the owner, the hand-offs, and what I did not see
- **Needs the owner (one design choice): B9.** On a phone, the hint card of a where-is item draws the rods **lying down** at the tiles'
  cube (12.7), while the rods on the tiles stand. The alternative is a card that covers the tiles while the hint shows, but then the
  child cannot compare the card with the tiles. **Recommendation: lying rods.** Open `docs/design/m11/min-sizes/add_b9_hint_card_phone.png`.
- **app-developer:** 8.1–8.3 and V1–V16, then HX1–HX6, L1–L9, H1–H7 in the order of 8.7. The goldens are named in each row.
- **curriculum-expert:** the number sign (does a place item show its target numeral?); the size signs with the other size as a ghost;
  at most three set options of 7–10 on phones; `ls10_personal_family` at most four at a time; skip-count strips on two rows.
- **hebrew-text-editor:** hint lines that need more than three lines at the floor (V2 lists them once the test exists); the hall's
  medal titles at w500 / 20 if they stay under 24.
- **qa-engineer:** add to `min_sizes_test.dart`: the caption floor with no look; ink (not box) for sets on tiles; hint chips ≥ 20;
  the hand never on the bubble; the hint card's u equals the tiles'; the language speaker ≥ 56.
- **What I did not look at.** A real phone or tablet. The ls* `text_1_3` variants (none exist except two l7 ones). 63 of the 75
  language SE goldens. `hall_friend_phone`, `alerts_view` and `parent_language*`, seen only on a sheet. The hint goldens below level 3
  on the phone, except the ones on the round-1 sheets. **Placeholder art seen:** the friend figure on `ceremony_*` / `hall_friend` is a
  head-and-body stand-in. The balance, arcs, cubes and signs in the mocks are plain shapes for size, not final art.

---

## 9. Rulings of 2026-11-20 on round 3

Design director, branch `lands-ux` at 4a4a39bf, after the developer's round 3 (`docs/agents/dev-report-2026-11-20.md`, section D). A
spec only; nothing in `app/` changed. Each ruling has one answer and the numbers a developer builds and the size test measures. Where
it replaces an earlier rule, the earlier rule now points here (R1, R4, 2.3 S6, 3.4, 5.1, 8.3).

**What I looked at.** The 16 rebuilt sheets `after/<board>_templates_00..03.png` at full size. Then the same 42 shots re-rendered from
the round-3 tree at 1 pixel = 1 point (`min_sizes_shots_test.dart` with `SHOTS_DIR` in a scratch folder, no file in `app/` changed),
opened 1:1: phone `drag_sort_three`, `logic_size`, `shape_small`, `match_numbers`, `shop_pay`, `builder_train`, `build_pattern`,
`match_coins`; SE `builder_train`; tablet L `colour_find`, `drag_sort`; tablet P `match_coins`. Goldens 1:1: `c1_chart_picture_start_phone`,
`c1_chart_picture_start_phoneSE`, `c1_blocks_on_tiles_start_phone`. Sheet only: the round-2 `phoneSE_language_00`. The numbers of the map
(`app/test/support/min_sizes_known.dart`) and the content (`content/starter/activity.*.json`) were read for every ruling that cites them.
**Not looked at:** a real device; `sing_along`, `puppet_talk`, `listen_do`, `story` screens (no shot of them exists in round 3); the
`_shows_` and most `_language_` sheets (round 2).

Mocks (script `min-sizes/rulings/make_rulings_mocks.py`, bases in `rulings/base/` are the round-3 shots):
`rulings/ruling_d3_three_shelf_phone.png`, `rulings/ruling_t2_match_card_tabletP.png`, `rulings/ruling_t2_match_card_tabletL.png`,
`rulings/ruling_t1_empty_stage_tabletL.png`. Each is "before" (the build) beside "after" at 1:1. I checked all four PNGs.

**[CB]** marks a ruling that touches Colour Bay's templates (tap_answer, sort_drag, build_pattern; spot_error is listed once). These are
built first, because M12's pilot is Colour Bay (`docs/milestones/M12.md`).

### 9.1 How the rulings keep room for M12
- **P0 (under 3):** two answers of **112 or more on every board**. Wherever a ruling below says "the look's tile", P0 means 112; on the
  picture stage of S6 a P0 answer is **144** (phone), 240 (tablets).
- **The S burst** (delight 4.1.3) flies 100 pt (140 tablets) from the tile over whatever is near. Nothing here puts a control within
  12 of an answer tile, and nothing here moves into the guide column (phone x 617..793 above y 245): the companion's jump and Goni (M12
  pilot, in the guide's place) keep it. The one new control under the guide (D8, the shop's ✓) is Band B/C only, never in Colour Bay.
- The tablet sort bin's ghost (T3) is not drawn for M12's "colour houses": there the house is the drawing.

### 9.2 The conflicts D1 to D12

**D1 The size family against the floor of 40. Ruling: the rule changes, with an exact family, and the art layout changes for towers and
for count-against-size items.**
- *Why not "draw the biggest at 120":* a 96 tile cannot hold it, and the size is the content: a small ball **must** look small next to a
  big one. A small ball of 24 pt ink is 3.7 mm at 30 cm (42 minutes of arc): a whole ball, no fine feature to read, clearly seen. That
  is R2's detail floor, and it is enough for an object whose identity is "a ball, red, small".
- **The family** (what the test treats as size-on-purpose): a sprite named `*_size_s`, `*_size_m`, `*_size_l` or `tower_<n>`, and a
  `group`/`group2` whose `scale` differs from the other group of the same item with the same sprite (`c.numb10.*`). Nothing else.
- **SIZE_SMALL** (replaces PIC_ID / BIN_INK for the family's smaller members): ink ≥ **24** phone and SE, ≥ **32** tablets.
- **SIZE_BIG:** the family's largest member on the same screen has ink ≥ **56** phone and SE, ≥ **80** tablets, and ≥ **1.6 ×** the
  smallest's ink (the difference stays visible; it also catches a fit that flattens the sizes). The largest is held to PIC_ID as well.
- **Geometry:** a size item keeps the tray's scale (8.2). Its box on phones is the look's tile (96 / 88): `ball_size_s` draws its ink at
  about 0.27 of the box, so 24 to 26 ink, and `_l` 66 to 72. On tablets the box of a size item is **120** (small ink 32, big 90), also in a
  well. `InkFit` is never used on a family member (it is not today: keep it so).
- **Towers** (`tower_1` … `tower_7`, `b.logb04.*`, `b.logb11.*`): the detail is the cube. **TOWER_U:** one cube's side u ≥ **14** phone
  and SE, ≥ **16** tablets, the same u for every tower of the item. A tower tile is the look's width and `max(look tile, tallest × u + 16)`
  high: seven cubes are a tile 114 high on a phone (band 250..364, under 369) and 128 on a tablet; on tablet L the card of such an item is
  848 × **392** so the tiles stand at 646 and end at 774. `tower_1` (one cube) is then a 14 / 16 square, held to TOWER_U, not to PIC_ID.
- **Count against size** (`c.numb10.*`: eight small stars against five big, M-CNT-SIZE): the two groups stand **one above the other** on
  the stage. Small set: the 5 × 2 frame of 8.3, cell **32** (ink 24), 160 × 64. Big set: one row, cell **52** (ink 40), 5 × 52 = 260 wide,
  so the big set is still the *longer* row (the misleading cue the item is about). 64 + 8 + 52 = 124 fits the phone's 128 stage. SE: the
  stage grows to 140 (`withStageAtLeast`, tiles lower, last row ends 351). Tablets: cells 44 / 72 (ink 32 / 56).
- **The one-star tile of `fewer.stars.*`:** a set of one that stands beside sets of more, in one comparison, is a **set** (R2, 24 / 32),
  not a lone picture (R1). All sets of a comparison use the cell of the largest set (fair size, as drawn today). 29 passes.

**D2 Language Band C tiles, token 64 / 80 against the look's 88 / 104. Ruling: the rule changes (R4 amended).** A tile whose content is a
**word or a letter chip** in a language course read at Band C (parent band 2) is **64** high on phones and SE, **80** on tablets
(`TokenTouch.band[C]`), as wide as its word + 2 × 16 (at least 64), touch ≥ 56, and its word at the band's word size (**34** phone / **40**
tablet, line height 1.7 where it has nikud). Why a child still reads it: the reader is 6 to 8, the word is the content and it is at its
reading size, and 64 is 10 mm, above the 56 floor of Bands B and C. Five word tiles of 88 do not fit the SE's 484 zone; five of 64 do. A
language tile that carries a **picture** keeps the look's tile (88 / 104).

**D3 The phone's three-shelf sort. Ruling: the layout changes. Mock: `rulings/ruling_d3_three_shelf_phone.png`.**
- A shelf of a three-bin sort on a phone (361 × 76, at y 104 / 186 / 268, gap 6) shows **one** sample, whatever the bin's `count`: box
  **52** (ink ≥ 40; `InkFit` may widen it for a flat picture, up to 64 wide), at inset 8 from the start edge, vertically centred.
- The **label beside the sample** on its end side, 18 w500 h1.7 (30.6 high fits the 76), in a box as wide as the word (max 96; at text
  1.3 the box grows to 120 and the well gives way), then a hairline 2 × 56.
- The well (about 199 wide): items **48**, gap 8, four shown, then the pile with the badge (32 / 20).
- A sample's `count` is a category marker in every three-bin sort of the pack (`log.sortdrag.three`, `x.mathb19.*`). **Content rule
  (curriculum-expert, validator):** a sort whose bins differ only by how many things the sample shows never has three bins on a phone.
- SE: the same with shelves 252 × 76, sample 48, items 44. Tablets keep their bins (T3).

**D4 Portrait tablet sort, card 420 against 520. Ruling: the rule changes (5.1 amended) and the card never changes height in an item.**
- The tray on tablet P is **one row** when `n × tile + (n − 1) × 12 ≤ 772` (six squares of 112 = 732; six of 104 = 684), and the card
  is then **772 × 520**. Square trays of seven or more and every strip tray (2 × 2 grid of 340 × 128) are two rows, and the card is
  **772 × 420 for the whole item**, also after the tray has emptied to one row. A card that shrinks or grows mid-item moves the bins
  under a dragging finger.
- Test: STAGE_CARD on tabletP reads the tray's rows **at the item's start** (the `item` slice) and applies that floor to the `sorted`
  slice of the same item.

**D5 Shape-builder pieces of 19 to 25; palettes of six or seven on a phone. Ruling: layout and content change; the slot is a detail.**
- **Shape builder tray: one tile per kind.** Pieces of the same sprite are **one tile** with a count badge (32 / 20) while more than one
  is left (the deck and pile language of the sort). Decoys are tiles too. The pack's largest tray is then **5** (`shp.build.face`,
  `b15.shpa06.1`; the train has 4: rectangle, two squares, circle × 4). **Content rule:** at most 5 tray kinds.
- **Placing:** a drag that ends anywhere on the stage snaps to the **nearest free slot of that kind** (the silhouette's place is shown by
  the snap; precision is not the skill). P0 (M12): one tap places it. The engine's answer is unchanged (the app-developer's code).
- **Phone stage:** 24,96 **377 × 148** (`withStageAtLeast`, the tray row at 256..352 in the wide band 24..605); SE 8,86 **278 × 157**
  (tray 255..351 in 8..651). The composite fills the stage less an 8 inset. The train's wheel is then a 48 box (ink about 38).
- **A slot or a placed piece is a detail of a composite** (R2): **BUILD_SLOT** ink ≥ 24 phone and SE, ≥ 32 tablets (replaces PIC_ID on
  the stage of `shape_builder`). The tray tile is the look's tile (TILE_H unchanged).
- **build_pattern palettes [CB]** (`b.colb06.*`: six colour balls): the palette uses the **wide band** (phone 24..605, SE 8..651) at the
  look's tile with gap **10** (phone: 6 × 88 + 5 × 10 = 578) or 12 (SE: 588). Band A (P1, 96) palettes are at most 5 on phones (528).
  **Content rule:** a palette has at most 6 (B, C) and 4 (A) pictures (the pack holds this today; the validator should keep it).

**D6 The smallest phone's count of ten. Ruling: the layout changes; the floor stays 64.** While counting, the SE stage is 8,86 **282 × 245**.
Seven to ten objects stand in a **4 × 3 grid of rectangular cells** (after an 8 inset: 66.5 × 76.3), rows left to right, top row first;
each object's touch square is **64**, centred in its cell, its box 54 (ink ≥ 40). The **target** (flower, basket) is **in the grid**, in
cell 12 (bottom row, right end), drawn 72 high; it no longer takes a column of the stage's width. Five and six: 3 × 2 + the target in a
third column of the bottom row (3 × 3 when it is closer to square). The phone keeps its layout (it passes). `CountLayout._cells` gets
rectangular cells and the target as a cell; the touch square is `min(cell w, cell h, 96)`.

**D7 The hundred chart's numerals of 12 to 17. Ruling: the layout changes.**
- Every numeral in a chart cell (the given number, the "?" slot, a hint's number) is a **chip centred on its cell**, larger than the
  cell where it must be: phone and SE chip **40 × 32** (48 × 32 for three digits), numeral **20** w800 LTR; tablets chip 52 × 40, numeral
  **24**, with cells of 56 or more (numeral 28). The chip covers the edges of its blank neighbours; it never covers another chip.
- The phone's window is **10 × 3 rows** (the given number's row, the target's, and one more for context) in the 330 × 128 stage: cells 31
  × 37. SE: the stage widens to 8..290 (282), cells 26.6 × 34. Tablets: 10 × 4 rows or more in the card (848 → cells 80).
- The blank grid lines keep their size: they are a structure, not something read.
- **Curriculum-expert to confirm** a 3-row window on phones (the 4-row window of today does not fit 32-high chips).

**D8 Coins shrunk in the purse. Ruling: a second row, by kind; no fewer coins.** The 16-coin purses are Band C's tens and ones
(`c.numc03.*`: eight 10 ₪ and eight 1 ₪).
- **Phone:** the purse is two rows, the larger kind on top: 10 ₪ at **61** (gap 6), 1 ₪ at **48** (gap 8): 8 × 61 + 7 × 6 = 530, from x 24,
  rows at y 248 and 317, ending 365. The ✓ moves **under the guide**: the look's tile (80 Band C, 88 Band B) at x 580, y 262. A Band B purse
  of mixed coins (at most 7) stays one row at the real ratio (1 ₪ 48, 2 ₪ 58, 5 ₪ 64, 10 ₪ 61: 420 wide plus the ✓ at its end).
- **SE:** the same rows from x 8, 8 × 61 + 7 × 4 = 516; rows at 222 and 291, ending 339; the ✓ at 548,236.
- **Tablets:** the purse stands **inside the card**, in its bottom band (item and price over it): 10 ₪ **81**, 1 ₪ **64** (5 ₪ 85, 2 ₪ 77),
  8 × 81 + 7 × 8 = 704, the two rows 157 high; the ✓ is the look's tile under the card, centred. The Show `blocks-tens-and-ones` too.
- **Content rule (curriculum-expert, validator):** at most **8 coins of a kind** and at most **2 kinds** in a Band C purse; a Band B
  purse at most 7 coins. The pack holds this today.

**D9 Sets of seven to ten in a line (22 pt on SE). Ruling: build the 5 × 2 frame of 8.3 everywhere, and the hint follows the layout.**
A group of 7 to 10 with arrangement `line` is a 5 × 2 frame on tiles **and on the stage** (phone cell 32, SE 32 in a 172 tile, stage SE
cell 48 when it is the only group). The hint never computes positions from a line: it asks the group's layout for each object's centre
(one function, used by the picture and the hint), and its hand tip stops 8 under the object (it comes from below, V4). **Curriculum-expert
to confirm** the order of a frame for counting hints: top row 1 to 5 left to right, then the bottom row (the ten-frame's fill order).

**D10 Captions under the floor (the hebrew-text-editor's). The layout help I give:**
- **Phone:** the bubble may grow **down to y 244** (the tiles of a row under the bubble start at 256), so its largest box is 413..603 ×
  96..244: three lines at the floor (24 × 1.7) and the padding. **SE:** down to the top of the tiles − 12. **Tablets:** two lines, the
  bubble up to 560 wide.
- The bubble never covers the stage, the guide or the companion, and the caption never shrinks under its floor: a line that needs more
  than **three lines at the floor on a phone** (two on a tablet) goes on a list the test prints (CAPTION_LINES), and the editor shortens
  it. As a rough budget for the editor: about **13 letters a line** at 24 pt on a phone (nikud marks not counted), so about **38** for
  a question.
- P0 (M12) has no caption at all.

**D11 The hand over the bubble (level 3 of the clock, the balance, a chart). Ruling: V4 stands, built exactly.** The hint hand's box never
intersects the bubble's box; its tip stops 8 outside the target's edge; when the target is under the bubble or in the tile column, the hand
comes **from below**, tip up. The test keeps HAND_BUBBLE as it is (150 square points over the bubble's text).

**D12 The Band C blocks-on-tiles card (Layout T, `c.numc02.*`, 584 × 264). Ruling: on tablets Layout T has no card; the tiles take its
place.** Landscape: three tiles **264 × 400** from 24,230 (gap 28; 848 wide). Portrait: three tiles **236 × 520** from 24,372 (gap 32).
The cube u follows c1-blocks (≥ 19, at most 26; today's u where it is larger). Nothing under them (S4 holds: L 190, P 288). STAGE_CARD is
replaced for Layout T by "the tile row is ≥ 800 wide (L) / 740 (P) and ≥ 400 / 520 high".

### 9.3 What the sheets show that the test does not catch

| # | Where | What I see | Ruling |
|---|---|---|---|
| T1 [CB] | tablet L and P `colour_find`, `shape_small`, `shape_where`, `next_number`, `ordinal`, `math_time`, `more_big_things`, the first step of a seriation `build_pattern` (`b.colb02.*`: "which is darkest?"); the same on phones, smaller | An **empty landscape** of 848 × 400 (772 × 520) with three 104 tiles under it. On a phone a 330 × 128 strip of sky. The eye goes to the empty picture. | **Fix (S6, mock `ruling_t1_empty_stage_tabletL.png`).** When the stage holds only its backdrop, the answers stand **in** it. Phone: picture stage 24,96 377 × 253, three tiles **112** (gap 12, centred, 360 wide) or two of **144** (P0 included); SE (picture stage 24,86 264 × 245): three answers stand **two over one** at the look's tile (96 / 88, gap 12, 204 × 204), two answers side by side at **120**. Tablet L: three of **200** (gap 40) in the 848 × 400 card; P: three of **208** (gap 32). Picture 0.72 of the tile. Nothing under the stage. The answers keep their keys and their order. Test: **EMPTY_STAGE** (S3): a stage whose pieces are only the backdrop while answer tiles stand outside it. |
| T2 | tablet `match_coins`, `match_numbers`, `match_solids` (match_pairs) | Three 136 faces in the middle of a big white card, coins 42 to 56 in them, the answers under the card. | **Fix (mocks `ruling_t2_match_card_tabletP.png`, `…_tabletL.png`).** Both rows inside one card. P: card 24,372 **772 × 600**, faces **216** (gap 24) over answers **176**, rows 64 apart, the block centred. L: card 24,230 **848 × 534**, faces **200** over **160**, rows 48 apart. Four pairs: `min(216, (inner − 3 × 24) / 4)`. Coins on faces at the real ratio with 5 ₪ = 0.74 × face (P 160 / 144 / 120). Sets on faces by the 8.3 table × face / 112. Phones keep their layout, with the coins on a face at V7 (5 ₪ 80, 1 ₪ 60). Test: MATCH_FACE, a tablet face ≥ 160. |
| T3 [CB] | tablet `drag_sort`, `drag_share`, `drag_sort_three` | Large empty bins, the sample a 44 pair in a corner, the label beside it. | **Fix.** Header row 88: sample **72** (one picture; a pair of 56 only when the count is the rule), label 24 w500 beside it. Well: items **96** when the sort has 8 items or fewer (64 for more), rows of 3 (L bin inner 378: 336), two rows then the pile. Until the first card lands, the empty well shows the sample as a **ghost**, 120, opacity 0.18, centred (key `bin-ghost`, exempt from BIN_INK; not drawn for M12's colour houses). The big bin stays: it is a forgiving drop target. |
| T4 | every tablet screen with content on the stage | The answer tiles (112 / 104 / 96) look small on the sheet under the big card. | **Fine.** At 1:1 a 112 tile is 21.5 mm at 40 cm (3.1 degrees), more than a phone's 96 at 30 cm (2.9). Only the picture in it must be 0.72 of the tile. |
| T5 | tablet `shop_pay` | A 220 apple and a big empty purse place; the coins 46 to 56 in a row under the card. | **Fix with D8:** the purse in the card's bottom band; the item for sale 120 (L) / 140 (P) in the card's top start corner with its price (32). |
| T6 | phone, SE, tablets `same_or_not` | Apples of 14 (phone) scattered; the right-hand set in a row of 6 at about 14. | **Fix (A6, still open):** each set in a two-row group (3 + 2, or 3 + 3), cell 48 (thing 36), the two groups 144 wide each with 24 between, on the 330 stage; SE cell 40; tablets cell 80. |
| T7 | phone `math_add` | Apples of about 22 on a big empty sky. | **Fix (A7, still open):** apples 32 phone, 48 tablets, in the 8.3 numeral-to-set cells (phone cell 52 for one group). |
| T8 [CB] | phone, SE `b.colb01.*` ("red and yellow make…"): two single balls on the stage at 35 (SE 23) | A single picture per group is a picture to identify. | **Fix:** a group of **one** on the stage is drawn as a stage picture: box 72 (ink ≥ 56) phone, 64 SE, 120 tablets. |
| T9 [CB] | SE `b15.cola06.*`, `b.colb04.*` (spot_error, 26 to 30) | Four cells in one row of the SE stage. | **Fix:** on SE, four cells stand **2 × 2** in the start-column stage (cells 110, picture ink ≥ 56). |
| T10 | phone and SE `builder_train` | Seven tray tiles squeezed to 73 / 64; the gray train in a strip. | D5 (one tile per kind, stage 377 × 148). |

### 9.4 The untouched templates and the unbuilt addendum: confirmed, with changes

| Item | Still wanted? | Change |
|---|---|---|
| **8.1 lying rods** (B9 hint card) | Yes, as written (the owner chose it, 8.8). | None. |
| **8.2 size signs with both sizes** | Yes. | The tablet well box is **120** (D1), not 112. |
| **8.3 number sign** (phone 160 × 132, tablet 220 × 160) | Yes. | None; the curriculum-expert's yes on showing the target is still open. |
| **8.3 refined balance** | Yes. | Band A (P1) tiles are **96** (`math.size.heavy`, TILE_H 88): phone 413 / 521 / 629, y 262; SE 300 / 404 / 508, y 236. A lone thing on a pan is a stage picture (box 52, ink ≥ 40: `b.mathb13.11`, 21 / 30 today); two or more are details (30 box, ink ≥ 24). |
| **8.3 5 × 2 frame** | Yes, and wider (D9: also on the stage). | None. |
| balance (116) | Yes: the refined balance. | As above. |
| match_pairs (85) | Yes. | T2 on tablets; V7 coins on phone faces; D2 for language word tiles; 8.3 cells for sets on faces. |
| flash (77) | Yes. | Phone and SE: the **picture stage** (377 × 253 / 264 × 245) while the group shows, as count does while counting; the answer tiles come into the band after the cover. The hint pictures read the stage rect from the layout (never a hard-coded 128). |
| sing_along (93) | Yes, not viewed by me. | L2's rule: the verse pictures stand on the picture stage, each ≥ 110 wide and ink ≥ 40 (SE today 12.8). |
| puppet_talk (24) | Yes, not viewed by me. | L1's rule: the puppet's pictures 56 / 72 on tiles of 88 / 104. |
| listen_do (6), story (6) | Yes, small. | listen_do: captions (D10). story on SE: `withTallStage` (A11's zones), empty band 96 against 94. |

### 9.5 What the size test must change (for the qa-engineer)

| # | Rule | Change | Boards and floors |
|---|---|---|---|
| 1 | PIC_ID, BIN_INK on the size family | Family members (D1's list) are measured by **SIZE_SMALL** (the smaller) and **SIZE_BIG** (the largest; also PIC_ID) | SMALL ≥ 24 phone/SE, ≥ 32 tablets; BIG ≥ 56 / 80 and ≥ 1.6 × the smallest |
| 2 | new **TOWER_U** | `tower_<n>` sprites: one cube's side, same for all towers of the item; replaces PIC_ID on towers | ≥ 14 phone/SE, ≥ 16 tablets |
| 3 | PIC_ID on a set of one | A set of one in a comparison of sets is PIC_DETAIL (R2) | 24 / 32 |
| 4 | TILE_H for language word tiles | A word or letter tile of a course read at Band C is held to `TokenTouch.band[C]` | 64 phone/SE, 80 tablets; word size ≥ 34 / 40; touch ≥ 56 |
| 5 | STAGE_CARD, tablet P sort | "Two rows of tiles" read at the item's start; the `sorted` slice takes the start's floor | 420 or 520 |
| 6 | STAGE_CARD, Layout T | Replaced by the tile row: width and height | ≥ 800 × 400 (L), ≥ 740 × 520 (P) |
| 7 | new **BUILD_SLOT** | A slot or placed piece in a `shape_builder` stage; replaces PIC_ID there | ≥ 24 phone/SE, ≥ 32 tablets |
| 8 | new **EMPTY_STAGE** (S3) | A stage that holds only its backdrop while answer tiles stand outside it | fails on every board |
| 9 | new **MATCH_FACE** | A match_pairs face on a tablet | ≥ 160 |
| 10 | new **CAPTION_LINES** (report, not a failure) | Lines that need more than 3 lines at the floor on a phone (2 on a tablet) | printed list for the editor |
| 11 | TILE_H for P0 | When the P0 look exists (M12) | ≥ 112 on every board |
| 12 | BIN_INK exemption | The ghost of an empty tablet bin (`bin-ghost`) | exempt |
| 13 | unchanged | COUNT_TOUCH (64), COIN (48 / 64), NUMERAL (20 / 24), HAND_BUBBLE, CAPTION, BIN_ITEM | as they are; D6, D7, D8, D11 are built to meet them |

### 9.6 What to build, in order (for the app-developer)

Colour Bay first (M12's pilot), then by how many children see it and how far under the floor it is.

| Step | What | Rulings | Templates |
|---|---|---|---|
| 1 [CB] | An empty stage gives its room to the answers (S6), with P0's 144 / 240 | T1 | tap_answer (and the seriation first step of build_pattern) |
| 2 [CB] | Single pictures on the stage are stage pictures | T8 | tap_answer |
| 3 [CB] | Palettes of six in the wide band, gap 10 / 12 | D5 (palette) | build_pattern |
| 4 [CB] | Tablet bins: header 88, sample 72, items 96, the ghost; the tablet P card fixed per item | T3, D4 | sort_drag |
| 5 [CB] | Three shelves on phones: one sample, label beside | D3 | sort_drag |
| 6 [CB] | SE spot cells 2 × 2 | T9 | spot_error |
| 7 | The size family: tray scale, tablet box 120, towers by cube, count-against-size stacked | D1, 8.2 | sort_drag, build_pattern, tap_answer, spot_error |
| 8 | Coins in two rows by kind; ✓ under the guide; tablet purse in the card | D8, T5, V6 | shop_pay |
| 9 | The tablet match board | T2, V7 | match_pairs |
| 10 | The SE count grid with the target in it | D6 | count_tap |
| 11 | The 5 × 2 frame on tiles and stage; the hint reads the layout | D9, 8.3 | tap_answer, flash, balance_b |
| 12 | Sets and apples still small: same_or_not, math_add | T6, T7 | tap_answer |
| 13 | The shape builder: one tile per kind, snap, stage 377 × 148 | D5 | shape_builder |
| 14 | Chart chips and the 3-row window | D7 | number_line (Band C), tap_answer charts |
| 15 | Layout T without a card on tablets | D12 | tap_answer (Band C) |
| 16 | Hands from below; the bubble grows to 244 | D11, D10 | hints, frame |
| 17 | The refined balance (with the P1 tiles of 96), the number sign, the lying rods | 8.3, 8.1, 9.4 | balance, number_line, hints |
| 18 | flash picture stage; sing_along, puppet_talk, story (L1, L2, A11) | 9.4 | flash, language templates |

Each step updates its goldens and re-runs the four board files with `MIN_SIZES_OUT` (QA note section 11). QA runs once at the end of
steps 1 to 6 (the Colour Bay set) and once at the end.

### 9.7 For the owner, the hand-offs, and what is open
- **Needs the owner (one look):** T1 changes how a plain question looks on every board: the answer pictures move up into the empty
  picture and become large (tablet 200). Open `docs/design/m11/min-sizes/rulings/ruling_t1_empty_stage_tabletL.png`. Recommendation: yes.
- **curriculum-expert:** D3 (no three-bin sort by count on phones); D5 (a drop snaps to the nearest slot of its kind; at most 5 tray kinds;
  palettes ≤ 6 / 4); D7 (a 3-row window of the hundred chart on phones); D8 (≤ 8 coins of a kind, ≤ 2 kinds); D9 (the frame's counting
  order); D1 (count against size: the big set at 1.6 to 1.75 × the small, still the longer row).
- **hebrew-text-editor:** D10 (the CAPTION_LINES list, about 13 letters a line on a phone).
- **qa-engineer:** 9.5.
- **app-developer:** 9.6.
- **Open, not decided here:** whether the tablet target sizes of 1.4 (R1 56, R2 32) should be asserted as warnings (QA decision 3 of
  its note): not needed for these rulings; I would leave it for after step 18.
