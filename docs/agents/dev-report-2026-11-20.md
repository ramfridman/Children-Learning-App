# Developer report, M11 minimum sizes, round 3 (branch `lands-ux`, tree on top of 7c69c5aa, nothing committed)

The target was the QA map `app/test/support/min_sizes_known.dart`. **It went from 5,959 failing measurements to 2,167** (3,792 lines removed, 0 added, 0 worse), by fixing root causes in `app/lib`. No test was loosened, no exemption was added, the map was rewritten only from the board runs (`MIN_SIZES_OUT`, as section 11 of the QA note says). The four boards and the quick part pass asserted against the new map (24 + 24 + 24 + 24 + 6 tests). Not everything is done: the list of what remains, with the reasons and the conflicts for the design-director, is in D and E. No process of mine is running, no `flutter_tester` is left, the scratch probe tests are removed.

## A. The map, before to after

By severity and board (before -> after):

| Board | S1 | S2 | S3 | Total |
|---|---:|---:|---:|---:|
| phone | 1301 -> 364 | 460 -> 272 | 188 -> 47 | 1949 -> 683 |
| phoneSE | 1561 -> 658 | 663 -> 338 | 193 -> 56 | 2417 -> 1052 |
| tabletL | 486 -> 167 | 215 -> 38 | 32 -> 8 | 733 -> 213 |
| tabletP | 589 -> 173 | 193 -> 16 | 78 -> 30 | 860 -> 219 |
| **all** | **3937 -> 1362** | **1531 -> 664** | **491 -> 141** | **5959 -> 2167** |

By template (the order of the brief):

| Template | Before | After | State |
|---|---:|---:|---|
| sort_drag | 1900 | 447 | bins, samples, cards, trays, share plates done; left: size-rule family, 3-shelf signs, language trays (D) |
| tap_answer | 1400 | 629 | tile column, keypad glyph, chips, stage picture sets done; left: sets on tiles, 100-chart, captions |
| build_pattern | 370 | 138 | palette tile done (tablet); left: size family, 6-picture palette on a phone, captions |
| robot_path | 360 | 80 | done (strip, arrows, undo, overflow, weight); left: captions, size pictures |
| count_tap | 353 | 95 | done on the phone; left: the smallest phone (46 + 27), captions |
| shape_builder | 292 | 84 | tray tiles on the wide band; the pieces in the stage (R1 40) not possible (D) |
| spot_error | 280 | 52 | stage and ring done; left: size towers, smallest phone |
| shop_pay | 249 | 151 | item for sale; left: coins, captions, numerals |
| number_line | 244 | 0 | done (smallest phone line, tablet overflow, chips) |
| balance | 116 | 116 | not touched |
| give_n | 96 | 82 | prefilled objects and chips; the smallest phone's frame still small |
| sing_along, match_pairs, flash, puppet_talk, listen_do, story | 295 | 291 | not touched (budget) |
| clock_set | 4 | 2 | chips |

By rule (before -> after): TILE_H 1127 -> 172, BIN_INK 1087 -> 135, PIC_ID 773 -> 593, CAPTION 531 -> 531 (the editor's, QA-M10), EMPTY_BAND 407 -> 105, ICON 344 -> 0, PIC_DETAIL 340 -> 334, BIN_ITEM 271 -> 55, NUMERAL 256 -> 58, COUNT_TOUCH 148 -> 46, NUMLINE_TICKS 140 -> 0, COUNT_OBJ 119 -> 27, ICON_PROGRAM 88 -> 0, ROBOT_STRIP 88 -> 0, STAGE_CARD 84 -> 36, COIN 68 -> 68, BIN_SAMPLE 56 -> 0, LAYOUT_ERROR 16 -> 0, LABEL_WEIGHT 8 -> 0, HAND_BUBBLE 8 -> 7.

## B. The root-cause fixes

1. **A picture is drawn cut to its ink and its box is as long as its ink needs** (new `app/lib/play/ink_fit.dart`, `InkFit`; BIN_INK -952, PIC_ID in sorts, BIN_ITEM, BIN_SAMPLE). The pack pictures stand in wide margins (a block lies flat in a square, a tower is a stick, a ball fills 0.72): the box was 48 and the ink 10 to 30. `InkFit.of(svg)` cuts the picture with the existing `inkedSvg`, reads its ink as the test does, and `boxFor` grows the box along the picture's long side until the ink is 42 (floor 40) within the room. Used by `sort_board.dart` for the cards in a bin (the card of a board is as big as the flattest or tallest picture of the sort needs), the samples of a bin, the tray's cards (deck and grid), a few pictures in a line as a sample (the group's cell is picture over 0.85), and by `count_tap_session.dart` for the counted objects and `give_n_session.dart` for the prefilled. Not for strips, not for a size rule (its small ball is small on purpose), not for tallies.
2. **The sort board follows the look.** A tray's tile is the look's tile on every board (the phone's strip deck was 88, a tablet's rows were look - 8 from six cards); where the cards do not fit one row on a tablet they stand in two and the card above is as tall as that leaves (`layoutFor`). A share's plates show their cards at the item's floor (48, 44 on the small phone, 64 on a tablet). A bin's sample is 56 on a tablet strip sort. A shelf of a phone with three or more bins and single samples (labels of 84 or less) puts its label beside the sample, because 76 high cannot hold a 41 picture and a line of 30. `_bigMark` (size rule) now needs a `*_size_[sml]` sprite: flat shape samples were taken for a size rule by their ink share.
3. **Answers in a row, not a column of 56** (TILE_H -955, with 4 and 5 below). A chart and a group-with-numerals on a phone keep the Meet stage and the answers are the look's tiles in one row under the bubble and the guide (`_tilesInARow`, 413 + n x (tile + 8); the guide's figure ends by y 245 and the band is empty). This is the stricter rule of the DECISION 1 conflict: it fits all four boards, so the 5.1 rule wins and the 56 exception is not needed.
4. **Palette and tray tiles are the look's tile** (`build_pattern_session.dart`, `shape_builder_session.dart`); the builder's tray takes the wide band (24 to 605, the small phone 8 to 651).
5. **The count has room** (COUNT_TOUCH -102, COUNT_OBJ -92, EMPTY_BAND). A line of objects ("arrangement: line") stands in the fewest rows that give a cell of 64 (ten in a row were 21 points to a thing; three rows of four are 71), the target flower is 80 for seven or more, and the stage is the picture stage (24 to 401, down to the edge where no hotspot may be) while counting, for every count (a phone's smallest: 16 to 286 tall, so the bubble keeps its room). The counting aid of hint 2 stands in the close-up slot on every phone count.
6. **Keypad and undo glyphs** 32 (44 on a tablet) (ICON -344). **Robot**: the empty place is a 20 ring (28), not an arrow, so ICON_PROGRAM is only arrows; `robot-program` is the padded strip box (44, 56); the undo glyph 32 (44).
7. **The host's guess tiles** (`show_predict.dart`): they were 88 wide + 24 each in a box of 210, three of them overflowed by 162 (QA-M1) and the label was w700 under 24 (QA-M3). Now the look's tile, a width of tile + 8, weight 500, centred over the template's box with an `OverflowBox`.
8. **The hint chip** (`HintBadge`, NUMERAL -198): 32 across with a numeral of 20 (40 and 24 on a tablet), by the board's size class, not by `hintScale`. Tile badges follow.
9. **Number line**: the smallest phone's line is 635 wide, 16 to 651, under the guide (its figure ends at 216; the stage starts at 218): 29 points a unit on 0 to 20 (NUMLINE_TICKS -140). A tick's label never wraps (`softWrap: false`, a 120-wide box): QA-M2, the 28-point overflow at text 1.3 on a tablet.
10. **Spot the error**: the phone stage is the whole start column (EMPTY_BAND -112 on the phone, 104 on the SE); the ring of the cell is painted over the margin and no longer takes 2 points from the picture, so a lit cell was 38.8 and an unlit one 42.2.
11. **Two sets of different sprites** that fill the same share of their box are cut to their ink too (`_sameInk`); the item for sale is `lineSlots: itemCount`.
12. **Tablet Band C blocks stage** has the grown card (`block_layout.dart`, `forStage`); the Band C blocks on tiles (`c.numc02`) keep their layout.
13. The sort hint's glide copy is the cut picture at 44 at least.

Files changed (`app/lib/play/`): `ink_fit.dart` (new), `sort_board.dart`, `sort_drag_session.dart`, `sprite_group.dart` (`groupCellFill`), `choice_row.dart` (`withWideTallStage`), `tap_answer_session.dart`, `build_pattern_session.dart`, `shape_builder_session.dart`, `count_tap_session.dart`, `give_n_session.dart`, `spot_error_session.dart`, `robot_path_session.dart`, `number_entry.dart`, `number_line_session.dart`, `show_predict.dart`, `shop_pay_session.dart`, `block_layout.dart`, `hints/hint_pictures.dart`. Docs: `docs/PLAN.md` (one build-detail bullet). The map: `app/test/support/min_sizes_known.dart`.

## C. Tests and checks

New: `app/test/min_sizes_round3_test.dart` (8 tests: `InkFit` on a round, a flat and a thin picture and the room limit; the chip 32/20 on the phone and the small phone, 40/24 on a tablet; ten objects in a line on the picture stage have a touch square of 64 or more, run left to right, and no two squares overlap).
Changed because they encoded the old geometry (each is the rule that changed, none weakened): `hint_band_a_test` (`BinMark` has `fit`; the spot-the-mistake card is placed by the laid-out stage), `robot_layout_test` (the steps are under the grid computed with the real strip, not the hard-coded 30). The four board files and `min_sizes_test.dart`: 6 + 24 x 4 passed against the new map. Goldens: 290 changed PNGs under `app/test/goldens` (the sorts, the counts, the charts, the robot, the hints, the tablet Band C blocks, the signs of spot the error); 44 that differed by under 0.2 percent of their pixels (anti-aliasing noise) were restored with `git checkout`. After-sheets: `docs/design/m11/min-sizes/after/<board>_templates_00..03.png` rebuilt from `app/test/min_sizes_shots_test.dart`; the Show and language sheets of round 2 are not rebuilt.
Looked at: phone sheets 0 to 2, phone SE sheet 1, tablet L sheet 1 and the shot of the three-shelf sort at 1:1. Good: ten and thirteen counted objects, the charts with their answers in a row, the sort shelves with a whole picture in the sign, the robot strip. Weak (listed): the three-shelf sort with a 2 or 3 picture sample still has 28-point pictures; the tablet match-pairs card is big and the faces in it are small; the empty tablet bins are large by design.

Commands (results in G): `flutter analyze` 0 issues; `dart format` clean; the full `flutter test --reporter failures-only`.

## D. What remains and why, with the conflicts for the design-director

I did not decide these by myself and did not touch the rules file.

1. **Floor 40 against "small on purpose 24" (R1, A12).** The size family (`*_size_*` balls, apples, stars, towers; seriation) is drawn small on purpose; the test holds its small picture to 40. Open for this reason: BIN_INK/PIC_ID in the size sorts (`math.size.*`, `b15.loga03.*`, `b15.matha04.*`), `log.size.*` tiles, `b.logb04.*`, spot-the-error towers (`b.logb11.*`), the 8 small stars of `c.numb10.1` to `.3` (PIC_DETAIL 9 to 20 on the phones). Either the test gets the exception of R1 (24 for the smallest of a size item) or the biggest is drawn at 120 and over. Also the one-star tile of `fewer.stars.*` is drawn as large as a star of the group of four (fair comparison) and so is 29 against 40.
2. **Language Band C tiles: token 64/80 against the look 88/104** (`TokenTouch.band[C]`, `Ls01Metrics.tileHeight`). TILE_H 96 in sort_drag, 32 in match_pairs, 16 in tap_answer. A row of five at 88 does not fit the small phone's zone (484). The token is the design-director's.
3. **The three-shelf phone sort with a 2 or 3 picture sample** (`log.sortdrag.three`, `x.mathb19.x`): a shelf is 76; a 48 box and an 18 point label with line height 1.7 do not both fit. I kept the label whole and the pictures at 41. BIN_ITEM 55 (phone 6, SE 11, tablets 30) and some BIN_INK. Options: two bins for such sorts, or a taller stage, or the label beside (done for single samples).
4. **Portrait sort card 420 with two rows of wide tiles** (design 3.3) against STAGE_CARD, which wants 520 when only one row of tiles remains after sorting: 20 entries in `tabletP`. Two rows of 128 under a 520 card do not fit above the edge where no hotspot may be.
5. **The pieces of a shape builder** in the stage are 19 to 25 (R1 40): they are composites of 6 to 8 shapes on a 330 x 128 stage; a bigger stage leaves no room for the tray. PIC_ID 62. Seven pieces at the look's tile do not fit 581 (build_pattern palette of six: TILE_H 12; builder: 6).
6. **The smallest phone's count**: ten objects have 56 (the phone 72); a Band A control is 64: COUNT_TOUCH 46, COUNT_OBJ 27 on the SE. The stage is 245 high.
7. **The hundred chart** of Band C (`c.numc01.x`, `c.numc09.x`): numerals of 12 to 17 in 25-point cells (NUMERAL on the stage, 58 in all).
8. **Coins** (COIN 68): the purse shrinks the coins to keep the rows over the no-hotspot line (33 against 48 for 16 coins on the phone; 53 against 64 on a tablet Show). Needs a second row layout or fewer coins (curriculum-expert).
9. **Sets on tiles and in groups on the smallest phone** (PIC_DETAIL 112 SE): a group of seven to ten in a line is 22 at 264 wide. The hint code places its hand by the line; the rows would move the hand tips, so I did not change the arrangement (needs the hint geometry to follow).
10. **CAPTION 531** is QA-M10, the hebrew-text-editor's (long lines shrink under the floor): not touched.
11. **HAND_BUBBLE 7** (hand over the bubble in the level 3 of a clock, a balance and a chart): the hand's travel, not a size.
12. **STAGE_CARD 36**: the Band C blocks on tiles (`c.numc02`, Layout T) keep their own card (584 x 264); the sort in portrait (item 4).

## E. Not built (nothing of the unbuilt addendum was built; budget)
8.1 lying rods (B9), 8.2 size-rule signs with both sizes, 8.3 the phone number sign (160 x 132) and the tablet sign, the refined balance (beam 191, level trays), and the 5 x 2 frame for 7 to 10 pictures on a tile (the round-2 `tileGroup` stays). Templates not touched: balance (116), sing_along (93), match_pairs (85), flash (77: the group card grows over the answer band, so a taller stage needs the hint geometry too), puppet_talk (24), listen_do (6), story (6). QA defects: M1, M2, M3, M5 fixed; M4 fixed except the smallest phone; M6 fixed except the size family; M7 partly (the Band C blocks stage; the blocks on tiles not); M8 fixed (the tiles are the look's); M9: keypad and undo fixed, the palette tile and the builder tray fixed except the counts in D5, the language tiles open (D2); M10 not mine.

## F. Hand-offs
- design-director: D1 to D5, D7, D8, and the look at the sheets (the three-shelf sign, the big empty tablet bins).
- hebrew-text-editor: CAPTION 531 (QA-M10).
- curriculum-expert: D8 (coins), D9 (the arrangement of a counted group of seven to ten).
- qa-engineer: verify the round per template (sorts, counts, chart rows, robot, guess tiles); the map is re-baselined, nothing else changed in the test files.
- security-engineer: none (no gateway, auth, crypto, pack, sync or log change).

## G. Full-test counts
One full `flutter test --reporter failures-only` at the end, nothing else running, on the final tree: **7,044 passed, 35 skipped, 1 failed**. The one failure is the expected `starter_pack_test.dart` "the pack was built from the sources in content/starter and nothing else" (the pack is not rebuilt). Before that, the four board files and `min_sizes_test.dart` were run asserted against the final map: 24 + 24 + 24 + 24 + 6 passed. `flutter analyze`: 0 issues. `dart format --output=none --set-exit-if-changed .`: 0 changed (767 files). `deno task check`: not run (nothing under `supabase/` changed). The headless playthrough (`playthrough_test.dart`) is part of the full run and passed. No `flutter_tester` is left running; `app/test/failures` (the golden diff folder, git-ignored) and the scratch probe tests were removed.
