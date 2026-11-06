# Old-style sprite inventory (2026-11-06)

After the first Riddle Grotto redraw the owner asked: "redraw all the old drawings also so everything would look better
and would fit." This file lists every picture in `content/starter/` (the starter pack). For each one it gives the number
of activities that use it, the lands they are in, a priority (P1: 20 activities or more, P2: 5 to 19, P3: under 5) and
its status. The Languages pictures in `content/languages/pictures/` were already in the house style. The characters are
out of scope.

**Where it stands: done, except the `meadow` background.** One generator, `tools/make_logic_sprites.py`, draws all 221
pictures under their old ids, so no activity changes. `tools/make_unit_sprites.py` and `tools/make_picture_sprites.py`
now only run that generator, so re-running either cannot bring an old drawing back. The coins and notes come from
`tools/make_coin_sprites.py`; they were already drawn in the new style and were not touched. `meadow` is the background
of almost every activity. It is an island background, so it is left for the illustrator's island art (art brief 6.2).

How the pictures are drawn:
- Things the Languages courses already draw (cat, dog, fish, apple, star, ball, frog, sock, spoon, bowl, pencil, egg,
  rain, rainbow, butterfly, banana, sun, towel, glass of water) reuse that same drawing, with a thicker ink outline for
  the small stage. A cat is one cat across the whole app.
- Everything else is drawn in the same style in the generator.
- Where colour is the content, the old hex value is kept: balls, balloons, flowers (`bloom_*`, `flower_red` #D62F2F,
  `flower_yellow` #FFD43B), shades, coloured shapes, apples, bananas.
- The shade discs have no shade crescent, because a darker edge would change the shade being taught.
- `robot` is drawn as Tza'adon, the Robot Harbour host, in a small front view. He walks the paths in the design spec.
  The character file `design/assets/tzaadon.svg` is unchanged.
- Arrows and robot steps are not part of these pictures; the clocks never mirror.

Canvases: 100 x 100, except `tower_1` to `tower_8` (100 x 220, so a cube is 24 units wide and all eight towers share one
scale), `flower_target` (160 x 200) and the empty scenes (400 x 225).

Batches and their contact sheets (old against new; tile 90 and 60 px, stage 44 and 28 px). All are in
`docs/design/logic-sweep/`:

| Batch | Sheet | Pictures |
|---|---|---|
| logic-1 | `sprites-2026-11-06.png` | duck, bird, chick, rule cards, plate, brush, paste, balloons, umbrella, bins, clue cards |
| logic-2 | `sheet-logic-2-2026-11-06.png` | the Logic things, the eleven balls, the size families, the lit twins |
| towers | `sheet-towers-2026-11-06.png` | tower_1 to tower_8 on the tall canvas |
| shapes | `sheet-shapes-2026-11-06.png` | the 32 flat shapes |
| numbers | `sheet-numbers-2026-11-06.png` | ladybug, butterfly, basket_target, flower_target, the empty nest, bowl and basket |
| math | `sheet-math-2026-11-06.png` | block, coin, sticks, stone, feather, bananas, times of day, days, clocks |
| colours | `sheet-colours-2026-11-06.png` | bloom_* (11), flower_red, flower_yellow, sun, shade_* (12) |
| forest | `sheet-forest-2026-11-06.png` | solid_* (5), pos_* (5), line_* (6), window, sign |
| robot | `sheet-robot-2026-11-06.png` | robot, flag, grass (a path cell that joins its neighbours), step_* (6) |

## The list (still old first, then by use)

| id | activities | lands (activities per land) | priority | status |
|---|---|---|---|---|
| `fish` | 74 | maths (measure, time, money) 29, Counting Hills 29, Riddle Grotto 16 | P1 | redrawn 2026-11-06 (logic-2) |
| `apple` | 72 | maths (measure, time, money) 32, Counting Hills 25, Riddle Grotto 14, Colour Bay 1 | P1 | redrawn 2026-11-06 (logic-2) |
| `star` | 70 | maths (measure, time, money) 29, Counting Hills 22, Riddle Grotto 19 | P1 | redrawn 2026-11-06 (logic-2) |
| `ball_red` | 67 | Colour Bay 34, Riddle Grotto 23, maths (measure, time, money) 7, Shape Forest 3 | P1 | redrawn 2026-11-06 (logic-2) |
| `basket_target` | 62 | Counting Hills 54, maths (measure, time, money) 8 | P1 | redrawn 2026-11-06 (numbers) |
| `duck` | 55 | maths (measure, time, money) 27, Counting Hills 20, Riddle Grotto 8 | P1 | redrawn 2026-11-06 (logic-1) |
| `ball_blue` | 53 | Colour Bay 29, Riddle Grotto 21, Shape Forest 3 | P1 | redrawn 2026-11-06 (logic-2) |
| `ball_green` | 41 | Colour Bay 28, Riddle Grotto 13 | P1 | redrawn 2026-11-06 (logic-2) |
| `cat` | 38 | Riddle Grotto 17, Counting Hills 13, maths (measure, time, money) 8 | P1 | redrawn 2026-11-06 (logic-2) |
| `ball_yellow` | 36 | Colour Bay 25, Riddle Grotto 11 | P1 | redrawn 2026-11-06 (logic-2) |
| `dog` | 33 | Riddle Grotto 14, Counting Hills 11, maths (measure, time, money) 8 | P1 | redrawn 2026-11-06 (logic-2) |
| `frog` | 32 | Counting Hills 25, maths (measure, time, money) 6, Riddle Grotto 1 | P1 | redrawn 2026-11-06 (logic-2) |
| `cross` | 29 | Counting Hills 13, Shape Forest 8, Riddle Grotto 6, Colour Bay 2 | P1 | redrawn 2026-11-06 (logic-2) |
| `tick` | 29 | Counting Hills 13, Shape Forest 8, Riddle Grotto 6, Colour Bay 2 | P1 | redrawn 2026-11-06 (logic-2) |
| `bird` | 27 | Counting Hills 14, maths (measure, time, money) 7, Riddle Grotto 6 | P1 | redrawn 2026-11-06 (logic-1) |
| `flag` | 26 | Robot Harbour 26 | P1 | redrawn 2026-11-06 (robot) |
| `robot` | 26 | Robot Harbour 26 | P1 | redrawn 2026-11-06 (robot) |
| `shape_circle_red` | 26 | Riddle Grotto 11, Shape Forest 8, Colour Bay 7 | P1 | redrawn 2026-11-06 (shapes) |
| `shape_triangle` | 26 | Shape Forest 26 | P1 | redrawn 2026-11-06 (shapes) |
| `shape_circle` | 25 | Shape Forest 25 | P1 | redrawn 2026-11-06 (shapes) |
| `ball_orange` | 22 | Colour Bay 22 | P1 | redrawn 2026-11-06 (logic-2) |
| `shape_square` | 22 | Shape Forest 22 | P1 | redrawn 2026-11-06 (shapes) |
| `ladybug` | 21 | Counting Hills 15, maths (measure, time, money) 6 | P1 | redrawn 2026-11-06 (numbers) |
| `shape_circle_blue` | 19 | Riddle Grotto 10, Shape Forest 6, Colour Bay 3 | P2 | redrawn 2026-11-06 (shapes) |
| `solid_box` | 19 | Shape Forest 19 | P2 | redrawn 2026-11-06 (forest) |
| `shape_rect` | 18 | Shape Forest 18 | P2 | redrawn 2026-11-06 (shapes) |
| `shape_square_red` | 18 | Riddle Grotto 10, Colour Bay 4, Shape Forest 4 | P2 | redrawn 2026-11-06 (shapes) |
| `balloon_red` | 17 | Colour Bay 11, Riddle Grotto 5, maths (measure, time, money) 1 | P2 | redrawn 2026-11-06 (logic-1) |
| `shape_square_blue` | 17 | Riddle Grotto 8, Shape Forest 6, Colour Bay 3 | P2 | redrawn 2026-11-06 (shapes) |
| `shape_triangle_red` | 17 | Riddle Grotto 11, Shape Forest 4, Colour Bay 2 | P2 | redrawn 2026-11-06 (shapes) |
| `shape_open` | 15 | Shape Forest 15 | P2 | redrawn 2026-11-06 (shapes) |
| `shape_triangle_green` | 15 | Shape Forest 9, Riddle Grotto 4, Colour Bay 2 | P2 | redrawn 2026-11-06 (shapes) |
| `shape_circle_green` | 14 | Shape Forest 6, Riddle Grotto 5, Colour Bay 3 | P2 | redrawn 2026-11-06 (shapes) |
| `shape_triangle_blue` | 14 | Riddle Grotto 9, Shape Forest 4, Colour Bay 1 | P2 | redrawn 2026-11-06 (shapes) |
| `balloon_yellow` | 13 | Colour Bay 9, Riddle Grotto 4 | P2 | redrawn 2026-11-06 (logic-1) |
| `chick` | 13 | Counting Hills 6, Riddle Grotto 4, maths (measure, time, money) 3 | P2 | redrawn 2026-11-06 (logic-1) |
| `sock` | 13 | Counting Hills 8, Riddle Grotto 5 | P2 | redrawn 2026-11-06 (logic-2) |
| `tower_2` | 13 | Riddle Grotto 13 | P2 | redrawn 2026-11-06 (logic-2) |
| `balloon_blue` | 12 | Colour Bay 10, maths (measure, time, money) 1, Riddle Grotto 1 | P2 | redrawn 2026-11-06 (logic-1) |
| `balloon_green` | 12 | Colour Bay 7, Riddle Grotto 5 | P2 | redrawn 2026-11-06 (logic-1) |
| `tower_1` | 12 | Riddle Grotto 12 | P2 | redrawn 2026-11-06 (logic-2) |
| `tower_3` | 12 | Riddle Grotto 12 | P2 | redrawn 2026-11-06 (logic-2) |
| `tower_4` | 12 | Riddle Grotto 12 | P2 | redrawn 2026-11-06 (logic-2) |
| `shape_circle_yellow` | 11 | Shape Forest 6, Colour Bay 3, Riddle Grotto 2 | P2 | redrawn 2026-11-06 (shapes) |
| `tower_5` | 11 | Riddle Grotto 11 | P2 | redrawn 2026-11-06 (logic-2) |
| `butterfly` | 10 | Counting Hills 9, maths (measure, time, money) 1 | P2 | redrawn 2026-11-06 (numbers) |
| `shape_square_green` | 10 | Riddle Grotto 6, Colour Bay 2, Shape Forest 2 | P2 | redrawn 2026-11-06 (shapes) |
| `step_brush` | 10 | Robot Harbour 10 | P2 | redrawn 2026-11-06 (robot) |
| `step_soap` | 10 | Robot Harbour 10 | P2 | redrawn 2026-11-06 (robot) |
| `bloom_red` | 9 | Colour Bay 9 | P2 | redrawn 2026-11-06 (colours) |
| `solid_cone` | 9 | Shape Forest 9 | P2 | redrawn 2026-11-06 (forest) |
| `solid_cylinder` | 9 | Shape Forest 9 | P2 | redrawn 2026-11-06 (forest) |
| `ball_purple` | 8 | Colour Bay 8 | P2 | redrawn 2026-11-06 (logic-2) |
| `banana_yellow` | 8 | maths (measure, time, money) 6, Colour Bay 2 | P2 | redrawn 2026-11-06 (math) |
| `bloom_blue` | 8 | Colour Bay 8 | P2 | redrawn 2026-11-06 (colours) |
| `bloom_orange` | 8 | Colour Bay 8 | P2 | redrawn 2026-11-06 (colours) |
| `coin` | 8 | maths (measure, time, money) 8 | P2 | redrawn 2026-11-06 (math) |
| `shape_curved` | 8 | Shape Forest 8 | P2 | redrawn 2026-11-06 (shapes) |
| `shape_pentagon` | 8 | Shape Forest 8 | P2 | redrawn 2026-11-06 (shapes) |
| `shape_rect_orange` | 8 | Shape Forest 8 | P2 | redrawn 2026-11-06 (shapes) |
| `step_rinse` | 8 | Robot Harbour 8 | P2 | redrawn 2026-11-06 (robot) |
| `step_tap` | 8 | Robot Harbour 8 | P2 | redrawn 2026-11-06 (robot) |
| `apple_lit` | 7 | Counting Hills 5, maths (measure, time, money) 2 | P2 | redrawn 2026-11-06 (logic-2) |
| `ball_size_l` | 7 | Riddle Grotto 7 | P2 | redrawn 2026-11-06 (logic-2) |
| `block` | 7 | maths (measure, time, money) 7 | P2 | redrawn 2026-11-06 (math) |
| `bloom_yellow` | 7 | Colour Bay 7 | P2 | redrawn 2026-11-06 (colours) |
| `day_5` | 7 | maths (measure, time, money) 7 | P2 | redrawn 2026-11-06 (math) |
| `shade_blue_1` | 7 | Colour Bay 7 | P2 | redrawn 2026-11-06 (colours) |
| `shade_red_3` | 7 | Colour Bay 7 | P2 | redrawn 2026-11-06 (colours) |
| `shape_quad` | 7 | Shape Forest 7 | P2 | redrawn 2026-11-06 (shapes) |
| `shape_rect_red` | 7 | Shape Forest 4, Riddle Grotto 2, Colour Bay 1 | P2 | redrawn 2026-11-06 (shapes) |
| `shape_square_tilt` | 7 | Shape Forest 7 | P2 | redrawn 2026-11-06 (shapes) |
| `shape_square_yellow` | 7 | Shape Forest 5, Colour Bay 2 | P2 | redrawn 2026-11-06 (shapes) |
| `shoe` | 7 | Riddle Grotto 5, Counting Hills 2 | P2 | redrawn 2026-11-06 (logic-2) |
| `solid_pyramid` | 7 | Shape Forest 7 | P2 | redrawn 2026-11-06 (forest) |
| `solid_sphere` | 7 | Shape Forest 7 | P2 | redrawn 2026-11-06 (forest) |
| `step_paste` | 7 | Robot Harbour 7 | P2 | redrawn 2026-11-06 (robot) |
| `step_towel` | 7 | Robot Harbour 7 | P2 | redrawn 2026-11-06 (robot) |
| `tower_6` | 7 | Riddle Grotto 7 | P2 | redrawn 2026-11-06 (logic-2) |
| `ball_black` | 6 | Colour Bay 6 | P2 | redrawn 2026-11-06 (logic-2) |
| `ball_size_s` | 6 | Riddle Grotto 6 | P2 | redrawn 2026-11-06 (logic-2) |
| `balloon_orange` | 6 | Colour Bay 6 | P2 | redrawn 2026-11-06 (logic-1) |
| `bin_basket` | 6 | Riddle Grotto 6 | P2 | redrawn 2026-11-06 (logic-1) |
| `bin_grass` | 6 | Riddle Grotto 6 | P2 | redrawn 2026-11-06 (logic-1) |
| `rule_colour` | 6 | Riddle Grotto 6 | P2 | redrawn 2026-11-06 (logic-1) |
| `rule_shape` | 6 | Riddle Grotto 6 | P2 | redrawn 2026-11-06 (logic-1) |
| `shade_blue_3` | 6 | Colour Bay 6 | P2 | redrawn 2026-11-06 (colours) |
| `shade_green_1` | 6 | Colour Bay 6 | P2 | redrawn 2026-11-06 (colours) |
| `shade_green_3` | 6 | Colour Bay 6 | P2 | redrawn 2026-11-06 (colours) |
| `shade_purple_1` | 6 | Colour Bay 6 | P2 | redrawn 2026-11-06 (colours) |
| `shade_purple_3` | 6 | Colour Bay 6 | P2 | redrawn 2026-11-06 (colours) |
| `shade_red_1` | 6 | Colour Bay 6 | P2 | redrawn 2026-11-06 (colours) |
| `shape_hexagon` | 6 | Shape Forest 6 | P2 | redrawn 2026-11-06 (shapes) |
| `shape_square_orange` | 6 | Shape Forest 4, Riddle Grotto 1, Colour Bay 1 | P2 | redrawn 2026-11-06 (shapes) |
| `shape_triangle_thin` | 6 | Shape Forest 6 | P2 | redrawn 2026-11-06 (shapes) |
| `star_size_s` | 6 | Riddle Grotto 5, maths (measure, time, money) 1 | P2 | redrawn 2026-11-06 (logic-2) |
| `stone` | 6 | maths (measure, time, money) 6 | P2 | redrawn 2026-11-06 (math) |
| `time_noon` | 6 | maths (measure, time, money) 6 | P2 | redrawn 2026-11-06 (math) |
| `bloom_green` | 5 | Colour Bay 5 | P2 | redrawn 2026-11-06 (colours) |
| `butterfly_lit` | 5 | Counting Hills 5 | P2 | redrawn 2026-11-06 (numbers) |
| `cat_lit` | 5 | Counting Hills 5 | P2 | redrawn 2026-11-06 (logic-2) |
| `day_4` | 5 | maths (measure, time, money) 5 | P2 | redrawn 2026-11-06 (math) |
| `day_6` | 5 | maths (measure, time, money) 5 | P2 | redrawn 2026-11-06 (math) |
| `day_7` | 5 | maths (measure, time, money) 5 | P2 | redrawn 2026-11-06 (math) |
| `duck_lit` | 5 | Counting Hills 5 | P2 | redrawn 2026-11-06 (logic-1) |
| `feather` | 5 | maths (measure, time, money) 5 | P2 | redrawn 2026-11-06 (math) |
| `fish_lit` | 5 | Counting Hills 5 | P2 | redrawn 2026-11-06 (logic-2) |
| `grass` | 5 | Robot Harbour 4, Colour Bay 1 | P2 | redrawn 2026-11-06 (robot) |
| `key` | 5 | Riddle Grotto 4, maths (measure, time, money) 1 | P2 | redrawn 2026-11-06 (logic-2) |
| `ladybug_lit` | 5 | Counting Hills 5 | P2 | redrawn 2026-11-06 (numbers) |
| `plate` | 5 | Shape Forest 4, Riddle Grotto 1 | P2 | redrawn 2026-11-06 (logic-1) |
| `pos_above` | 5 | Shape Forest 5 | P2 | redrawn 2026-11-06 (forest) |
| `pos_in` | 5 | Shape Forest 5 | P2 | redrawn 2026-11-06 (forest) |
| `pos_on` | 5 | Shape Forest 5 | P2 | redrawn 2026-11-06 (forest) |
| `pos_under` | 5 | Shape Forest 5 | P2 | redrawn 2026-11-06 (forest) |
| `shade_blue_2` | 5 | Colour Bay 5 | P2 | redrawn 2026-11-06 (colours) |
| `shade_green_2` | 5 | Colour Bay 5 | P2 | redrawn 2026-11-06 (colours) |
| `shade_purple_2` | 5 | Colour Bay 5 | P2 | redrawn 2026-11-06 (colours) |
| `shade_red_2` | 5 | Colour Bay 5 | P2 | redrawn 2026-11-06 (colours) |
| `shape_circle_orange` | 5 | Shape Forest 3, Colour Bay 2 | P2 | redrawn 2026-11-06 (shapes) |
| `shape_rect_blue` | 5 | Shape Forest 4, Riddle Grotto 1 | P2 | redrawn 2026-11-06 (shapes) |
| `shape_triangle_down` | 5 | Shape Forest 5 | P2 | redrawn 2026-11-06 (shapes) |
| `star_lit` | 5 | Counting Hills 5 | P2 | redrawn 2026-11-06 (logic-2) |
| `star_size_l` | 5 | Riddle Grotto 4, maths (measure, time, money) 1 | P2 | redrawn 2026-11-06 (logic-2) |
| `time_night` | 5 | maths (measure, time, money) 5 | P2 | redrawn 2026-11-06 (math) |
| `ball_white` | 4 | Colour Bay 4 | P3 | redrawn 2026-11-06 (logic-2) |
| `balloon_black` | 4 | Colour Bay 4 | P3 | redrawn 2026-11-06 (logic-1) |
| `bowl_empty` | 4 | Counting Hills 4 | P3 | redrawn 2026-11-06 (numbers) |
| `day_1` | 4 | maths (measure, time, money) 4 | P3 | redrawn 2026-11-06 (math) |
| `day_3` | 4 | maths (measure, time, money) 4 | P3 | redrawn 2026-11-06 (math) |
| `dog_lit` | 4 | Counting Hills 4 | P3 | redrawn 2026-11-06 (logic-2) |
| `fish_size_s` | 4 | Riddle Grotto 3, maths (measure, time, money) 1 | P3 | redrawn 2026-11-06 (logic-2) |
| `flower_target` | 4 | Counting Hills 4 | P3 | redrawn 2026-11-06 (numbers) |
| `lock` | 4 | Riddle Grotto 4 | P3 | redrawn 2026-11-06 (logic-2) |
| `nest_empty` | 4 | Counting Hills 4 | P3 | redrawn 2026-11-06 (numbers) |
| `plant_seed` | 4 | Riddle Grotto 4 | P3 | redrawn 2026-11-06 (logic-2) |
| `pos_next` | 4 | Shape Forest 4 | P3 | redrawn 2026-11-06 (forest) |
| `sign` | 4 | Shape Forest 4 | P3 | redrawn 2026-11-06 (forest) |
| `time_morning` | 4 | maths (measure, time, money) 4 | P3 | redrawn 2026-11-06 (math) |
| `window` | 4 | Shape Forest 4 | P3 | redrawn 2026-11-06 (forest) |
| `apple_green` | 3 | Colour Bay 2, Riddle Grotto 1 | P3 | redrawn 2026-11-06 (logic-2) |
| `apple_size_l` | 3 | Riddle Grotto 3 | P3 | redrawn 2026-11-06 (logic-2) |
| `apple_size_s` | 3 | Riddle Grotto 3 | P3 | redrawn 2026-11-06 (logic-2) |
| `ball_brown` | 3 | Colour Bay 3 | P3 | redrawn 2026-11-06 (logic-2) |
| `ball_grey` | 3 | Colour Bay 3 | P3 | redrawn 2026-11-06 (logic-2) |
| `ball_pink` | 3 | Colour Bay 3 | P3 | redrawn 2026-11-06 (logic-2) |
| `ball_size_m` | 3 | Riddle Grotto 3 | P3 | redrawn 2026-11-06 (logic-2) |
| `balloon_grey` | 3 | Colour Bay 3 | P3 | redrawn 2026-11-06 (logic-1) |
| `balloon_purple` | 3 | Colour Bay 3 | P3 | redrawn 2026-11-06 (logic-1) |
| `banana_green` | 3 | Colour Bay 3 | P3 | redrawn 2026-11-06 (math) |
| `bird_lit` | 3 | Counting Hills 3 | P3 | redrawn 2026-11-06 (logic-1) |
| `bloom_brown` | 3 | Colour Bay 3 | P3 | redrawn 2026-11-06 (colours) |
| `bloom_grey` | 3 | Colour Bay 3 | P3 | redrawn 2026-11-06 (colours) |
| `bloom_purple` | 3 | Colour Bay 3 | P3 | redrawn 2026-11-06 (colours) |
| `clue_not_circle` | 3 | Riddle Grotto 3 | P3 | redrawn 2026-11-06 (logic-1) |
| `clue_not_square` | 3 | Riddle Grotto 3 | P3 | redrawn 2026-11-06 (logic-1) |
| `coin_s1` | 3 | maths (measure, time, money) 3 | P3 | new style already (make_coin_sprites.py), not touched |
| `day_2` | 3 | maths (measure, time, money) 3 | P3 | redrawn 2026-11-06 (math) |
| `egg` | 3 | Riddle Grotto 3 | P3 | redrawn 2026-11-06 (logic-2) |
| `egg_crack` | 3 | Riddle Grotto 3 | P3 | redrawn 2026-11-06 (logic-2) |
| `fish_size_l` | 3 | Riddle Grotto 2, maths (measure, time, money) 1 | P3 | redrawn 2026-11-06 (logic-2) |
| `paste` | 3 | Riddle Grotto 3 | P3 | redrawn 2026-11-06 (logic-1) |
| `plant_flower` | 3 | Riddle Grotto 3 | P3 | redrawn 2026-11-06 (logic-2) |
| `plant_sprout` | 3 | Riddle Grotto 3 | P3 | redrawn 2026-11-06 (logic-2) |
| `rain` | 3 | Riddle Grotto 3 | P3 | redrawn 2026-11-06 (logic-2) |
| `shape_triangle_yellow` | 3 | Shape Forest 3 | P3 | redrawn 2026-11-06 (shapes) |
| `time_evening` | 3 | maths (measure, time, money) 3 | P3 | redrawn 2026-11-06 (math) |
| `balloon_brown` | 2 | Colour Bay 2 | P3 | redrawn 2026-11-06 (logic-1) |
| `balloon_pink` | 2 | Colour Bay 2 | P3 | redrawn 2026-11-06 (logic-1) |
| `balloon_white` | 2 | Colour Bay 2 | P3 | redrawn 2026-11-06 (logic-1) |
| `basket_empty` | 2 | Counting Hills 2 | P3 | redrawn 2026-11-06 (numbers) |
| `bloom_pink` | 2 | Colour Bay 2 | P3 | redrawn 2026-11-06 (colours) |
| `bowl` | 2 | Riddle Grotto 2 | P3 | redrawn 2026-11-06 (logic-2) |
| `brush` | 2 | Riddle Grotto 2 | P3 | redrawn 2026-11-06 (logic-1) |
| `cloud` | 2 | Riddle Grotto 2 | P3 | redrawn 2026-11-06 (logic-2) |
| `clue_not_blue` | 2 | Riddle Grotto 2 | P3 | redrawn 2026-11-06 (logic-1) |
| `clue_not_green` | 2 | Riddle Grotto 2 | P3 | redrawn 2026-11-06 (logic-1) |
| `clue_not_red` | 2 | Riddle Grotto 2 | P3 | redrawn 2026-11-06 (logic-1) |
| `clue_not_triangle` | 2 | Riddle Grotto 2 | P3 | redrawn 2026-11-06 (logic-1) |
| `line_curved` | 2 | Shape Forest 2 | P3 | redrawn 2026-11-06 (forest) |
| `line_curved_arc` | 2 | Shape Forest 2 | P3 | redrawn 2026-11-06 (forest) |
| `line_curved_wave` | 2 | Shape Forest 2 | P3 | redrawn 2026-11-06 (forest) |
| `line_straight` | 2 | Shape Forest 2 | P3 | redrawn 2026-11-06 (forest) |
| `line_straight_flat` | 2 | Shape Forest 2 | P3 | redrawn 2026-11-06 (forest) |
| `line_straight_up` | 2 | Shape Forest 2 | P3 | redrawn 2026-11-06 (forest) |
| `rainbow` | 2 | Riddle Grotto 2 | P3 | redrawn 2026-11-06 (logic-2) |
| `shape_rect_green` | 2 | Shape Forest 2 | P3 | redrawn 2026-11-06 (shapes) |
| `shape_rect_yellow` | 2 | Shape Forest 2 | P3 | redrawn 2026-11-06 (shapes) |
| `shape_triangle_orange` | 2 | Shape Forest 2 | P3 | redrawn 2026-11-06 (shapes) |
| `spoon` | 2 | Riddle Grotto 2 | P3 | redrawn 2026-11-06 (logic-2) |
| `stick_long` | 2 | maths (measure, time, money) 2 | P3 | redrawn 2026-11-06 (math) |
| `stick_short` | 2 | maths (measure, time, money) 2 | P3 | redrawn 2026-11-06 (math) |
| `tower_7` | 2 | Riddle Grotto 2 | P3 | redrawn 2026-11-06 (logic-2) |
| `apple_size_m` | 1 | Riddle Grotto 1 | P3 | redrawn 2026-11-06 (logic-2) |
| `bloom_white` | 1 | Colour Bay 1 | P3 | redrawn 2026-11-06 (colours) |
| `clock_1` | 1 | maths (measure, time, money) 1 | P3 | redrawn 2026-11-06 (math) |
| `clock_11` | 1 | maths (measure, time, money) 1 | P3 | redrawn 2026-11-06 (math) |
| `clock_2` | 1 | maths (measure, time, money) 1 | P3 | redrawn 2026-11-06 (math) |
| `clock_3` | 1 | maths (measure, time, money) 1 | P3 | redrawn 2026-11-06 (math) |
| `clock_4` | 1 | maths (measure, time, money) 1 | P3 | redrawn 2026-11-06 (math) |
| `clock_5` | 1 | maths (measure, time, money) 1 | P3 | redrawn 2026-11-06 (math) |
| `clock_6` | 1 | maths (measure, time, money) 1 | P3 | redrawn 2026-11-06 (math) |
| `clock_7` | 1 | maths (measure, time, money) 1 | P3 | redrawn 2026-11-06 (math) |
| `clock_8` | 1 | maths (measure, time, money) 1 | P3 | redrawn 2026-11-06 (math) |
| `clock_9` | 1 | maths (measure, time, money) 1 | P3 | redrawn 2026-11-06 (math) |
| `clue_not_orange` | 1 | Riddle Grotto 1 | P3 | redrawn 2026-11-06 (logic-1) |
| `clue_not_yellow` | 1 | Riddle Grotto 1 | P3 | redrawn 2026-11-06 (logic-1) |
| `coin_h50` | 1 | maths (measure, time, money) 1 | P3 | new style already (make_coin_sprites.py), not touched |
| `coin_s10` | 1 | maths (measure, time, money) 1 | P3 | new style already (make_coin_sprites.py), not touched |
| `coin_s5` | 1 | maths (measure, time, money) 1 | P3 | new style already (make_coin_sprites.py), not touched |
| `fish_size_m` | 1 | Riddle Grotto 1 | P3 | redrawn 2026-11-06 (logic-2) |
| `flower_red` | 1 | Colour Bay 1 | P3 | redrawn 2026-11-06 (colours) |
| `flower_yellow` | 1 | Colour Bay 1 | P3 | redrawn 2026-11-06 (colours) |
| `paper` | 1 | Riddle Grotto 1 | P3 | redrawn 2026-11-06 (logic-2) |
| `pencil` | 1 | Riddle Grotto 1 | P3 | redrawn 2026-11-06 (logic-2) |
| `star_size_m` | 1 | Riddle Grotto 1 | P3 | redrawn 2026-11-06 (logic-2) |
| `sun` | 1 | Colour Bay 1 | P3 | redrawn 2026-11-06 (colours) |
| `tower_8` | 1 | Riddle Grotto 1 | P3 | redrawn 2026-11-06 (logic-2) |
| `umbrella` | 1 | Riddle Grotto 1 | P3 | redrawn 2026-11-06 (logic-1) |
| `bloom_black` | 0 | (not used by any activity) | P3 | redrawn 2026-11-06 (colours) |
| `clock_10` | 0 | (not used by any activity) | P3 | redrawn 2026-11-06 (math) |
| `clock_12` | 0 | (not used by any activity) | P3 | redrawn 2026-11-06 (math) |
| `clue_not_colour` | 0 | (not used by any activity) | P3 | redrawn 2026-11-06 (logic-1) |
| `clue_not_shape` | 0 | (not used by any activity) | P3 | redrawn 2026-11-06 (logic-1) |
| `coin_a10` | 0 | (not used by any activity) | P3 | new style already (make_coin_sprites.py), not touched |
| `coin_s2` | 0 | (not used by any activity) | P3 | new style already (make_coin_sprites.py), not touched |
| `note_100` | 0 | (not used by any activity) | P3 | new style already (make_coin_sprites.py), not touched |
| `note_20` | 0 | (not used by any activity) | P3 | new style already (make_coin_sprites.py), not touched |
| `note_200` | 0 | (not used by any activity) | P3 | new style already (make_coin_sprites.py), not touched |
| `note_50` | 0 | (not used by any activity) | P3 | new style already (make_coin_sprites.py), not touched |
| `rule_size` | 0 | (not used by any activity) | P3 | redrawn 2026-11-06 (logic-1) |
| `meadow` | 950 | Counting Hills 297, maths (measure, time, money) 232, Riddle Grotto 135, Shape Forest 130, Colour Bay 108, Robot Harbour 48 | P1 (background) | OLD, hand-made file (no generator) |
