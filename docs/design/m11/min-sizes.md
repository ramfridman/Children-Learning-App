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
