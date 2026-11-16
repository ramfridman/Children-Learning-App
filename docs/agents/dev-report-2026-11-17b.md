# Developer report, M11 minimum sizes round 2 (branch `lands-ux`, tree on top of 7e7b17aa, nothing committed)

No process of mine is still running; no `flutter_tester` is left. The editor's files (`content/units/**`, arc JSON, `docs/review/*`, `tools/hebrew_voice_review.py`, `tools/test_hebrew_sources.py`) and the design-director's (`min-sizes.md` section 8, `design-spec.md`, `make_sheets.py`, `add_*.png`) are modified in the tree and are not mine; I did not touch them.

## Result in one paragraph
Built from the round-1 list: A4, A5 (scale and tiles; the refined pans not), A6, A7, A8, A11, A12, B2, B4, B5, B6, B7, B8, C1/C2/C3 for every template (one change for every tablet lesson), the round-1 weak spots (number-line marker, ten on a tile) except the phone number-line top-left, and from the addendum 8.7: V2, V3, V1/HX1 (sets by ink and by count), V6 (price and item for sale), plus the c1-blocks pointer. NOT built: 8.1 lying rods (B9), 8.2 size-rule signs with both sizes, the phone number sign and the tablet number-line sign, V4, V5, V7, V8 to V16, HX2 to HX6, L1 to L9, H1 to H7 (list in section F). Full run at the end: see section D.

## A. Per finding: done or not, measured before -> after (points)
Measurement: sizes of drawn pictures were read off the 1:1 shots of `test/min_sizes_shots_test.dart` (the ink of the picture, not its box, where a picture was cut to its ink); box sizes are from the geometry. "phone / SE / tabletL / tabletP".

| Finding | Status | Before -> after |
|---|---|---|
| C1, C2 tablet growth, every template | DONE | `withGrownCard` (`choice_row.dart`), applied in `lesson_screen.dart` to the board before any `layoutFor`: card 584x300 at x 288 -> **848x400** from x 24 (portrait 772x300 -> **772x520**), tiles under it. Meet stage, Ls01 zones, clock follow it. Tall size tiles (towers, 168) give the card up to 366 so they stay over the no-hotspot line. A room's landmark on tabletL moved to the start side above the card (105 across; there is no column at the start side now) |
| C3 empty answer band (phone) | DONE for the templates below | chart, balance, group-with-numerals, give, pattern use the room under the stage |
| A4 picture graphs | DONE | pictures 12-16 -> **33** (7 in a column; 47 for 5) phone, 33 SE, 49 tabletL, 66 tabletP; three answer tiles 56 (hit 64) in the column under the bubble (`ActivitySpec.withTiles`) |
| A5 balance | PARTLY | things on a pan 10-12 -> **28-30** (phone, stars and apples; read off the shot), about 24-26 SE, 60+ tablets (`_ScaleBox.extra`: taller upright, longer strings, cells in rows from the floor). Tiles 3x88 in a row under the bubble and the guide (x 413/513/613, y 262; SE 300/396/492, y 236), hand tips follow (`hint_part5_test` updated). NOT built: the 8.3 beam of 191, level trays, rows of five |
| A6 same-or-not | DONE | apples 12 -> about 28 (cut to ink, Meet stage); two sets of one sort use the ink crop |
| A7 add | DONE | apples 14 -> **28 wide, 31 tall** (phone shot) |
| A8, V1 sets on tiles | DONE | birds/apples on tiles about 16-20 -> about **34 wide** (phone); `tileGroup` by count (1-2 in a row, 3-4 two a row, 5-6 three, 7-10 two rows of five) and `tileWidthFor` 96/128/177 (a quarter more on a tablet); the wide band 24..605 (SE 8..651) for set tiles; match-pairs faces 96 phone / 136 tablet and cut to ink. Ten on a tile: 19 -> rows of five, cell 31 on a 170 tile (picture about 26 on the ink; not measured on a drawn shot: no pack item has ten on a tile in the unit shots) |
| A11 story cards | PARTLY | card max height 88 -> 104 phone (82 -> 84 SE), 120 -> 180 tablet: width-limited to about 183x103 on a phone, so a character is about 26 (was about 20), not the 40 of the spec (a 16:9 page in a third of 581) |
| A12 shape small | DONE | smallest shape about 10 -> **35**, the others 60 (options that are one thing each stand alone in a cell as large as the tile allows) |
| B2 robot strip | DONE | strip 30 -> **44**, arrows about 16 -> **28**, empty slots 12 -> 20, start dot 10, wrap to a second row left to right (gap 0 keeps 8 steps in one row on the SE); tablet 56 / 40; tablet arrow tiles 58 -> 80 |
| B4 dots | DONE | dot 5 -> **7**, gap 3, rows of five (ten = 47 x 17) |
| B5 drag pattern | DONE | stage 330 -> 377 wide on a phone: cells 52 -> 60, pictures about 36 -> about 42 on the ink |
| B6 give | DONE | phone stage 128 -> 157 (SE 104 -> 145), a Show the tall stage; pile cut to ink (about 24 -> 35 for twenty on the SE; read off the shot only for the frame item) |
| B7 | DONE with A6/A7 | stars on the Meet stage 20 -> about 50; tablets get the grown card |
| B8 | DONE | the bin's sign picture and the cloze's picture are cut to their ink (`inkedSvg`); not measured on a golden |
| V2 caption floor | DONE | no-look frames 14 -> **22 phone / 20 SE / 28 tablet** (`activity_frame.dart`); `course_text_test` allowed up to 24 more height than the board's limit (this encoded the old rule) |
| V3 clock | DONE | numerals at 0.78 r in a 3-pt paper halo over the hands, minute hand 0.86 -> 0.62 r, hour 0.5 -> 0.45 r, ticks 0.91-0.97 r |
| V6 coins/tablet | PARTLY | with the grown card the coins are 64 / 77 on tabletL (the "third larger" took); price numeral 24 -> 32 on tablets, item for sale cut to ink. NOT built: coins on tiles V7 |
| V11 celebration | NOT DONE | not looked at on the new goldens (see F) |
| V16 count card on tablets | NOT DONE | |
| Weak spots | PARTLY | number-line marker 52 -> **56 phone / 80 tablet**, a tablet's line at 0.75 of its card, pad 40; the phone number line's empty top left: NOT built (the number sign, 8.3) |
| B9 lying rods | NOT DONE | |
| 8.2 size signs both sizes | NOT DONE | |

Tablet screens now show the content at the grown card's scale for: tap_answer rows and tiles, group stages, chart, balance (things 60+), match_pairs (faces 136), give, pattern, robot (cells 118, tiles 80), shape builder, trace, clock, number line, sort, shop (coins 64-85). Not scaled up: the tiles' own size stays the look's (112 on a tablet) and some content that has a fixed art size (the builder's shapes) is as the stage lets it be.

## B. Contact sheets (in the repo, `docs/design/m11/min-sizes/after/`)
Made by `docs/design/m11/min-sizes/make_sheets.py` from the final tree: `<board>_templates_NN.png` (every unit template of the unit shots on the board, 42 on each of the four boards), `<board>_shows_NN.png` (the host's Show screens of the nine rooms and of Shape Forest on the boards that have goldens: phone has the eight Stage 2 players too), `<board>_language_NN.png` (the `ls01r` screens, 27 per board, and the L7/LS10/LS13 phone ones). Boards: `phone`, `phoneSE`, `tabletL`, `tabletP`. I looked at every sheet of the phone and tabletL templates, tabletP templates 0 and 2, the tabletL and phone Shows, phone language 0, and opened single shots at full size for balance, chart, math_add, set_to_numeral, drag_pattern, shape_small and robot. Not opened one by one: tabletP language, SE shows/language, tabletP shows (they follow the same code paths as the sheets I did open). The tool is `app/test/min_sizes_shots_test.dart` (does nothing without `SHOTS_DIR`).

## C. Goldens
The update run rewrote 718; 139 that changed under 1% outside my template families were restored with `git checkout` (home, hall, ceremony, c1 blocks, signs, most `ls*`); 579 changed goldens remain (all tablets, the templates above, SE). After the last code changes the robot tablet goldens (`unit_robot_plan_tablet_landscape`, `hint_robot_l3_tablet_landscape`, `robot_layout_golden`) were regenerated. Pixel diff per file was measured with `GoldenFileComparator` against the committed ones.

## D. Test counts
`flutter test --reporter failures-only`, one run at the end with nothing else running: **6,934 passed, 35 skipped, 1 failed**. The failure is `starter_pack_test.dart` "the pack was built from the sources in content/starter and nothing else" (expected: the pack is not rebuilt after the content changes). The editor's `voice_text_test` passed in this run. An earlier full run of this round (before the last fixes) had 6 failures: the robot tablet goldens (3.9 and 4.1 %), the playthrough on both tablets (the robot's row of controls overflowed a 584 board), `robot_layout_test` (tablet hand) and the starter pack; all fixed except the starter pack. `flutter analyze`: 0 issues. `dart format --set-exit-if-changed`: clean (754 files). `deno task check`: not run (nothing under `supabase/` changed). The headless playthrough (`playthrough_test.dart`) passes on all boards.

## E. Tests
New: `app/test/min_sizes_round2_test.dart` (11: the grown card, tileGroup/tileWidthFor/spriteRects, dots, robot strip), `app/test/min_sizes_shots_test.dart` (a tool). Changed because they encoded the old geometry: `hint_band_a_test` (pattern stage now 377 wide: expected places use the laid-out board), `hint_part5_test` (balance tiles 88/6), `m11_rooms_test` (landmark on tabletL), `course_text_test` (bubble up to 24 over its limit at the new caption floor). No test was weakened to pass; each change is the rule that changed.

## F. NOT DONE (for a third round), by id
- 8.1 / B9: lying rods in the hint card (needs `BaseTenPicture orientation: lying`, `hint_tap_c1_test`); the c1-blocks.md pointer is added.
- 8.2 / V9 / V10: the size rule's signs with both sizes (ghost at 0.3, `ball_size_l` only); a three-shelf sign shows one sample at 40; tablet header sample 72.
- 8.3: phone number sign (160x132 at 24,100; bubble 196..603) and the tablet sign (220x160); hint hop chips 32/40; balance beam 191, level trays, rows of five; numeral-to-set cells 52 phone (96 tablet) exactly as the table (built by ink and by count, not by this table); tile of the "5" card in `tap_add`.
- V4 hand over the bubble/target; V5 `more_big_things` on the picture stage; V7 coins on tiles (digit 20); V8 count target 72 on tablets; V11 celebration hero 160 on tablet landscape (not examined); V12 trace start dot 28; V13 hint chips 32/20; V14 phone number line top left; V15 tablet number-line sign; V16 count card with tiles inside the card.
- HX1 pairs (shoes 40); HX2 number strips; HX3 base-ten hint cubes under 12; HX4 share plates; HX5; HX6.
- L1 `ls10_personal_family` (answers cut off on the phone), L2 `ls13`/`l7` find and trail pictures, L3 speakers 56, L4, L5, L6, L7, L8, L9; H1 to H7 (home, hall, ceremony, parent text).
- A11: the characters in a story card are about 26 on a phone, not the 40 of the spec (it needs a larger card than a third of the row); the curriculum-expert/design-director to decide (two rows?).
- Not measured on a drawn shot: A8 ten on a tile, B6 give frame on the SE, B8.

## G. Hand-offs
- qa-engineer: verify the round (tablet screens, the chart/balance/robot/group layouts, V2, V3). `test/min_sizes_test.dart` per `min-sizes.md` section 5 and 8.8 is still not written.
- design-director: the number sign (8.3) and 8.1/8.2 need building and then a look; the story card question (A11); V11 not examined.
- curriculum-expert: the number sign on a place item (8.3: does it show the target?), at most three 7-10 set options on a phone (a validator rule).
- security-engineer: none (no gateway, auth, crypto, pack, sync or log change).

## H. Files
New: `app/test/min_sizes_round2_test.dart`, `app/test/min_sizes_shots_test.dart`, `docs/design/m11/min-sizes/after/*.png`.
Changed (`app/lib/`): `child/activity_shell.dart` (`withTiles`, `tileSize`/`tileFont` in `withStageAndTiles`), `play/choice_row.dart` (`withGrownCard`, Meet/Ls01 follow it), `play/lesson_screen.dart`, `play/activity_frame.dart` (V2), `play/tap_answer_session.dart` (chart, group, wide set tiles, singles, tall tiles, inked sets, numeral tile fit), `play/balance_session.dart`, `play/robot_path_session.dart`, `play/match_pairs_session.dart`, `play/give_n_session.dart`, `play/build_pattern_session.dart`, `play/clock_set_session.dart`, `play/number_line_session.dart`, `play/count_tap_session.dart` (`Dots`), `play/sprite_group.dart` (`rows2/3/5`, `tileWidthFor`), `play/shop_pay_session.dart`, `play/ls01_sequence_session.dart`, `play/ls01_sort_session.dart`, `play/ls01_tap_session.dart`, `play/hints/tap_geometry.dart`, `play/hints/tap_plans.dart` (`inkBoxOf` reads `scale() translate()`: the apple was cropped to a red sliver).
Tests: `course_text_test`, `hint_band_a_test`, `hint_part5_test`, `m11_rooms_test`.
Docs: `docs/PLAN.md` (one build-detail bullet), `docs/milestones/M11-stage2.md` section 11.10, `docs/design/c1-blocks.md` section 10 (pointer to min-sizes 8.1), `docs/agents/dev-report-2026-11-17b.md`.
