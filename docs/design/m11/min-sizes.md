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
| R1 | **Picture to identify**: an object whose identity is the content or the answer (which animal, which shape, which solid, a picture on a tile, a bin's sample, a cloze's context picture) | **40** | 40 | **56** | `stagePicture.min`. A size item that is small on purpose (seriation, "small") keeps its smallest at **24** or more. |
| R2 | **Detail inside a composite**: one animal or ball of a pattern strip, one counted thing that is not touched one by one (a set on a tile, apples on a stall, pictures in a chart, things on a balance pan, a ten-frame dot) | **24** | 24 | **32** | Base-ten cubes keep c1-blocks' 12.7 / 19 (they are counted by rods); see owner decision 3. |
| R3 | **Counted object that is touched one by one** | drawn **40**, touch square **64** (A) / 56 (B, C) | same | drawn 56, touch 80 | The touch square is the object's cell, never `max(object, 48)`. |
| R4 | **Draggable tile** | the look's tile (`StageSpec.tile`): 96 / 88 / 80; never under the band's `minControl` | 112 / 104 / 96 | same | A wide card keeps the tile's height and grows in width until its detail meets R2. |
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
- **Phone:** the shelves for two bins. For three bins, three shelves 361 × 76 (a 40-pt sample in the sign column, items 48 in the
  well). Items in a shelf are **48** (R5 × 1.2), 8 apart, in one row, then a pile with the badge. The deck tile is the look's tile
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
