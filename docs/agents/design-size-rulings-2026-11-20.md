# Design director: the size rulings of 2026-11-20 on round 3

Branch `lands-ux` at 4a4a39bf, worktree `D:/nitznutz-lands`. A decisions-and-documents run: nothing under `app/lib` or `app/test` changed,
nothing committed. The rulings are in `docs/design/m11/min-sizes.md` **section 9** (with the earlier rules they replace edited: R1, R4,
2.3 S6 new, 3.4, 5.1, 8.3).

## Files
- `docs/design/m11/min-sizes.md`: section 9 (rulings, the table for the qa-engineer 9.5, the build order 9.6), pointers in R1, R4, S6, 3.4, 5.1, 8.3.
- `docs/design/m11/min-sizes/rulings/make_rulings_mocks.py` (new) and its four PNGs, each "before" (the round-3 build) beside "after" at 1:1:
  `ruling_d3_three_shelf_phone.png`, `ruling_t2_match_card_tabletP.png`, `ruling_t2_match_card_tabletL.png`, `ruling_t1_empty_stage_tabletL.png`.
- `docs/design/m11/min-sizes/rulings/base/` (new): four round-3 shots used as the mocks' bases.

## The rulings, one line each ([CB] = Colour Bay's templates, built first)
- **D1** Rule changes: the size family (`*_size_[sml]`, `tower_<n>`, groups of different `scale` with the same sprite) is held to SIZE_SMALL 24 / 32 and SIZE_BIG 56 / 80 and ≥ 1.6 × the smallest; size items keep the tray scale (tablet box 120); towers by cube u ≥ 14 / 16 (tile grows, tablet L card 392); `c.numb10` sets stacked (small 5 × 2 at cell 32, big row at cell 52); a set of one in a comparison is a set (R2), so `fewer.stars` passes.
- **D2** Rule changes: a language word or letter tile read at Band C is 64 / 80 (the course band's token), word 34 / 40, touch ≥ 56; picture tiles keep the look.
- **D3 [CB]** Layout changes: three shelves on a phone show ONE sample (box 52) with the label beside it; items 48; no three-bin sort by count on a phone.
- **D4 [CB]** Rule changes: tablet P sort card is 520 with a one-row tray (up to six squares, gap 12) and 420 for the whole item when the tray starts with two rows; the test reads the start.
- **D5 [CB for palettes]** Palettes of six in the wide band at the look's tile (gap 10 / 12; Band A ≤ 5); shape builder: one tray tile per kind with a count badge (≤ 5 kinds), a drop snaps to the nearest free slot of its kind, phone stage 377 × 148 (SE 278 × 157), a slot is a detail (BUILD_SLOT 24 / 32).
- **D6** Layout changes, floor stays 64: SE count stage 282 × 245, a 4 × 3 grid of rectangular cells with touch squares of 64 and the target in cell 12.
- **D7** Layout changes: every numeral in a chart cell is a chip (40 × 32, numeral 20; tablets 52 × 40, 24); phone window 10 × 3 rows; SE stage 282 wide.
- **D8** A second row by kind, no fewer coins: phone 10 ₪ 61 over 1 ₪ 48, the ✓ under the guide; tablets purse inside the card (81 / 64); content ≤ 8 of a kind, ≤ 2 kinds.
- **D9** Build the 5 × 2 frame on tiles and on the stage; the hint reads object centres from the same layout function, hand from below.
- **D10** Editor's; layout help: the phone bubble may grow down to y 244 (3 lines at the floor, about 13 letters a line), tablets 2 lines up to 560 wide; a CAPTION_LINES report lists what still needs shortening.
- **D11** V4 exactly: the hand never on the bubble, tip 8 outside the target, from below when the target is under the bubble; the test stays.
- **D12** Layout changes: on tablets Layout T has no card; three tiles 264 × 400 (L) / 236 × 520 (P); STAGE_CARD replaced by a tile-row check.
- **T1 [CB]** (not caught by the test) an empty stage gives its room to the answers (new rule S6): phone 3 × 112 or 2 × 144 in the picture stage, SE two over one, tablets 3 × 200 / 208 in the card; new test EMPTY_STAGE.
- **T2** the tablet match board: both rows in one card (P 772 × 600, faces 216 over 176; L 848 × 534, 200 over 160), coins at the real ratio; new test MATCH_FACE ≥ 160.
- **T3 [CB]** tablet bins: header 88, sample 72, items 96 (≤ 8 items), rows of 3, a 0.18 ghost of the sample in an empty well (not for M12's colour houses).
- **T4** tablet answer tiles under a full stage: fine (a 112 tile at 40 cm is a larger angle than a phone's 96 at 30 cm).
- **T5** tablet shop: purse in the card (with D8). **T6** same_or_not, **T7** math_add: A6 / A7 are still unbuilt; numbers given. **T8 [CB]** a single picture on the stage (`b.colb01`) is a stage picture (72 / 64 / 120). **T9 [CB]** SE spot_error cells 2 × 2.
- **Untouched templates and the addendum (9.4):** all still wanted. Changes: the 8.2 tablet well box is 120; the refined balance gets P1 tiles of 96 and a lone thing on a pan is a stage picture; flash uses the picture stage while the group shows; sing_along and puppet_talk follow L2 / L1 (not viewed by me).
- **Order (9.6):** steps 1 to 6 are Colour Bay (T1, T8, D5 palette, T3 + D4, D3, T9), then D1, D8, T2, D6, D9, T6/T7, D5 builder, D7, D12, D11/D10, the addendum, the remaining templates. QA once after step 6 and once at the end.

## What I could not decide, and why
- D7's 3-row window, D9's counting order in the frame, D3's "no three-bin sort by count", D5's snap and the tray/palette caps, D8's coin caps, D1's size ratio: each is decided on the design side but needs the curriculum-expert's yes (they change what the child sees of the content).
- sing_along, puppet_talk, listen_do, story: no round-3 shot of them exists; the rulings point to L1, L2, A11 without my having looked.
- Whether the tablet targets (R1 56, R2 32) should become warnings in the test: left for after the build order.

## Needs the owner (one look)
1. T1: plain questions (no picture on the stage) show the answers large inside the picture instead of small under an empty landscape, on every board. Open `D:/nitznutz-lands/docs/design/m11/min-sizes/rulings/ruling_t1_empty_stage_tabletL.png`. Recommendation: yes.

## Hand-offs
- **app-developer:** min-sizes.md 9.6 in order (Colour Bay first), with the geometry of 9.2 to 9.4; logic it owns: the shape builder's snap and per-kind tray (D5), the count grid with the target as a cell (D6), the layout function shared by group drawing and hint (D9), the card fixed per item (D4).
- **qa-engineer:** min-sizes.md 9.5 (new SIZE_SMALL, SIZE_BIG, TOWER_U, BUILD_SLOT, EMPTY_STAGE, MATCH_FACE, CAPTION_LINES; changed TILE_H for language word tiles and P0, STAGE_CARD for tablet P sorts and Layout T; the bin ghost exemption). Then verify after step 6 and at the end.
- **curriculum-expert:** D1 (count against size, big set 1.6 to 1.75 ×), D3, D5, D7, D8, D9, as listed above and in 9.7.
- **hebrew-text-editor:** D10, the CAPTION_LINES list once the test prints it (about 13 letters a line, about 38 for a question, on a phone).

## What I looked at
The 16 sheets `docs/design/m11/min-sizes/after/<board>_templates_00..03.png`; a fresh 1:1 render of the 42 shots of `app/test/min_sizes_shots_test.dart` on four boards into my scratch folder (the test writes only to `SHOTS_DIR`; nothing in `app/` changed), opened 1:1: phone `drag_sort_three`, `logic_size`, `shape_small`, `match_numbers`, `shop_pay`, `builder_train`, `build_pattern`, `match_coins`; SE `builder_train`; tablet L `colour_find`, `drag_sort`; tablet P `match_coins`. Goldens 1:1: `c1_chart_picture_start_phone`, `c1_chart_picture_start_phoneSE`, `c1_blocks_on_tiles_start_phone`. The round-2 sheet `phoneSE_language_00`. The M12 storyboard `docs/design/m12/colour_bay_pilot_phone.png`. My four mock PNGs, each checked. Not seen: a real device, the language and Show sheets beyond one, the four language templates named above.

References: no real-world drawing was made (the mocks use the app's own coins, balls, balloons and fruit). Placeholder art still in use where these rulings touch: the coin and shape sprites are the app's own generated art; nothing new drawn.

No permission rule refused an action. No package, nothing paid, no secrets.
