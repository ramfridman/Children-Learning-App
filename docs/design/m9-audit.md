# M9 design audit (board B-8)

Design-director, 2026-10-28, branch `m9-content`. A review: nothing in the app, the tokens or the pictures was changed. Every finding below was made by opening the existing golden PNGs in `app/test/goldens/` (none were regenerated) and, where a number is quoted, by reading the layout constants in `app/lib/child/activity_shell.dart` (`ActivitySpec`) and the sprite generators.

## 0. What I looked at, and what I did not

**Opened and looked at (39 PNGs):** `home_phone`, `home_tablet_landscape`, `home_tablet_portrait`, `island_counting_phone`, `island_counting_tablet_landscape`, `island_colors_phone`, `island_colors_tablet_landscape`, `land_island_decorated_phone`, `activity_phone`, `activity_phone_se`, `activity_tablet_landscape`, `activity_tablet_portrait`, `lesson_2_count_three_answers_phone`, `lesson_2_count_three_answers_tablet_portrait`, `lesson_5_give_two_phone`, `lesson_6_celebration_phone`, `coins_sheet`, and the `unit_*` goldens: `trace_numeral` (phone, tablet), `trace_start_only` (phone), `builder_house` (phone, tablet), `builder_rocket`, `builder_train`, `chart_more`, `chart_most` (phone, tablet), `clock_set` (phone, tablet), `shop_pay` (phone, tablet), `match_coins`, `match_solids`, `balance_compare`, `number_line_jump` (phone), `number_line_place` (tablet), `spot_numbers`, `drag_sort_three`, `drag_share`, `drag_pattern`, `robot_plan` (phone, tablet), `robot_direct`, `logic_next`, `logic_pattern_yes_no`, `logic_size`, `flash_dice`, `count_seven`, `numeral_to_set`, `ordinal`, `zero`, `colour_sort`, `colour_banana`, `shape_where`, `shape_small`, `math_time`, `math_shop`, `math_add`, `more_big_things`, `cs_routine`.

**Not looked at:** the tablet-landscape twin of most `unit_*` goldens (I opened it for the eight new templates and the robot), `unit_drag_sort`, `unit_colour_find`, `unit_flash_covered`, `unit_logic_sort`, `unit_match_numbers`, `unit_next_number`, `unit_same_or_not`, `unit_set_to_numeral`, `unit_shape_rect`, `unit_balance_compare_tablet_landscape`, the other lesson goldens, the picker, Friends' Beach, the sticker island, the Trophy Hall, the ceremony, the parent area, the voice-mic goldens. **There are no `unit_*` goldens for tablet portrait or for the iPhone SE**, so no template has been seen at 820 by 1180 or on the SE's 270 by 104 stage. I cannot see the real phone; sizes below are in points read off the 852 by 393 board, and how a finger meets them on the Samsung is for the owner to feel.

## 1. Findings, ranked by severity (15)

Severity: **High** = a child of the band cannot do it or the app breaks a standing rule; **Medium** = works but confuses, or teaches something wrong; **Low** = polish.

### F1. High. The phone stage is too small for every template that is answered *on* the stage
`ActivitySpec.phone.stage` is `Rect(71, 96, 330, 128)` for every template; the 330 by 216 room below it (`tilesTop 244`) is empty whenever a template has no answer row. Measured on the goldens:

| Template (golden) | What the child touches on the stage | Size now | Band floor (design-spec §6.1) |
|---|---|---|---|
| `count_tap` (`unit_count_seven_phone`) | each apple, Band A | ~24 pt | 64 pt |
| `give_n` (`lesson_5_give_two_phone`) | each butterfly to drag, Band A | ~24 pt | 64 pt |
| `number_line` (`unit_number_line_jump_phone`) | a tick, 0 to 10 | 29 pt apart, numerals ~10 pt | 56 pt |
| `spot_error` (`unit_spot_numbers_phone`) | a number tile | ~50 pt | 56 pt (answer 80) |
| `build_pattern` (`unit_drag_pattern_phone`) | an empty slot, Band A | ~44 pt | 64 pt |
| `trace` (`unit_trace_numeral_phone`) | the whole numeral | box ~115 pt, numeral ~95 pt tall, dots 6 pt | numeral should be about 200 pt |
| `clock_set` (`unit_clock_set_phone`) | the hour hand / face | face ~118 pt, numerals ~10 pt | face about 220 pt |
| `balance` (`unit_balance_compare_phone`) | reads the pans | pan things ~6 pt | 24 pt to be counted |
| `tap_answer` + chart (`unit_chart_more_phone`) | counts pictures in columns | ~12 pt | 20 pt |
| `robot_path` (`unit_robot_direct_phone`) | arrow pebbles, Band A | ~56 pt | 64 pt |

Fix: two more stage modes in `ActivitySpec` (spec in §2), chosen by the template. Owner of the constants: design-director; the template choosing its mode: **app-developer**.

### F2. High. "Who is third in the queue?" has no queue (`unit_ordinal_phone`)
The stage is an empty meadow; the four animals stand as answer tiles with no front, no counter, nobody facing anywhere. Third from the right (RTL) is the cat; third from the left is the dog. The child cannot know which is meant, and the right answer depends on a direction nobody showed. Fix: the queue stands on the stage with a clear front (a stall or a gate at the start side, the animals facing it, the first one touching it), the animals themselves are the targets (72 pt each, tall mode), and the direction is the curriculum's decision. Owners: **curriculum-expert** (which end is "first", RTL by design-spec §8 "first card at the right"), **app-developer** (ordinal as an on-stage row with a front marker), design-director (the front picture).

### F3. High. Speed language in the flash activities
24 captions in 12 activities say "הִסְתַּכְּלוּ מַהֵר!" ("look fast!"), e.g. `unit_flash_dice_phone`. CLAUDE.md and design-spec §5.4 ("no 'faster!' lines") forbid urgency. Fix: a calm opener, e.g. "הִסְתַּכְּלוּ טוֹב…" ("look carefully"), worded by the **hebrew-text-editor**, with the **curriculum-expert** confirming the flash still teaches subitising without the word. Also the flash's covered state washes the meadow white with the hill line still showing through; use the plain paper stage (F11).

### F4. High. The "no" answer is a red disc with a white X (`content/starter/cross.svg`, `unit_logic_pattern_yes_no_phone`)
The art brief (§2.3) says "no red crosses"; design-spec §1.4 says "no red X"; and the pair is red versus green (`tick.svg` is `#4CAF50`), which §9.1 avoids. The shapes differ, which saves colour-blind children, but the rule is broken in 25 activities. Fix (mine, next wave): `tick` = gold `spark` disc with an ink check; `cross` = `mist` disc with an ink "not the same" sign (two rounded strokes, ink, no red). Same ids, so no lesson changes. Owner: design-director.

### F5. High. The land islands show other lands' drawings, a stair legend everywhere, and tiny objects on the phone
`island_counting_*` shows cone trees, paint pools, robot docks, pattern doors and market stalls on Counting Hills; `island_colors_*` shows stalls and docks in Colour Bay. The cause: `worldObject` is typed per skill in the content tables (`tools/band_b.py` line 176 onward: NUM-B-01 to 04 are `cone-tree`), choosing from the 7 placeholder drawings for variety. A child learns "this island is about trees". The legend (`land_screen.dart`, `_sample`, `objectId: 'stair'`) shows the counting stair on every land. On the phone Colour Bay draws 13 objects in one row at ~30 pt with ~60 pt pitch (Band A tap floor 64), and the island itself is a flat tinted oval (no scene yet).
Fix: (a) every skill of a land takes its land's own drawing family (`app/assets/world/objects.json` › `domains`) until the illustrator's 24 families arrive; a validator rule refuses a `worldObject` from another land (**app-developer** for the rule, **curriculum-expert** to clear the `world` column in `tools/band_b*.py`); (b) the legend draws the land's own object (**app-developer**: `_sample(stage)` takes `objectsJson.domains[land]`); (c) object size floor 64 pt on the phone: at most 2 rows of 9 on a phone, otherwise the island pans horizontally like the map (design-spec §5.3), and the current lesson's object glows. Island scenes are illustrator work (P9, art brief §6.2).

### F6. Medium-high. The clock: hands cross the 12, "−" and "+" look like sums, hands are too alike (`unit_clock_set_*`)
On both sizes the blue minute hand runs through the numeral 12 and the red hour hand is almost as long as it. The two controls are a minus and a plus sign, the maths symbols the child meets in the next activity. Fix in §3 (T18). Owner: **app-developer** (the clock is drawn in code), curriculum-expert to confirm the turn arrows.

### F7. Medium. On tablets the answer row overlaps the stage card, and the stage uses a third of the screen
`tabletLandscape.stage` ends at y 530 but `tilesTop` is 520; `tabletPortrait.stage` ends at 672 but `tilesTop` is 662: every tile and tray covers the card's bottom edge by 10 pt (`unit_builder_house_tablet_landscape`, `unit_clock_set_tablet_landscape`, `lesson_2_count_three_answers_tablet_portrait`). The stage is 584 by 300 on a 1180 by 820 screen and 772 by 300 in portrait, where design-spec §7.3 asks for about 772 by 560; the lower 40 per cent of both tablet screens is empty. Fix: the constants in §2. Owner: design-director (constants in `ActivitySpec`, a visual change I may make), then **qa-engineer** re-runs the goldens.

### F8. Medium. The pictograph is hard to read and its answers are in the opposite order (`unit_chart_*`)
Pictures in the columns are ~12 pt on the phone; there is no cell grid and no category picture under each column, so the column is only identified by its own tiny pictures; on `chart_most` the apple column and the red-ball column are both red and round (only a 3 pt stem differs); and the columns read left to right (apple, banana, ball) while the answer tiles read right to left (ball, banana, apple), so the tile under a column is not that column. Fix in §3 (chart). Owners: **app-developer**, **curriculum-expert** (no two categories of the same colour and outline in one chart).

### F9. Medium. Pictures that give the answer away or are ambiguous
- `unit_shape_where_phone` ("where is the ball? under the table"): only the right tile has a table; the two wrong tiles show a ball over and on a plank. The child can find the table, not "under". All three tiles must show the same table.
- `unit_math_time_phone` ("which is morning?"): the "morning" sun low on a peach sky is the same picture as an evening sun. Needs a cue that is not the sun's height alone (sun at the start side with a rooster or breakfast; evening with lamps lit and the moon rising).
- `unit_match_solids_phone`: a square pyramid has a square face too; matching it only to the triangle is ambiguous.
- `unit_colour_banana_phone`: the green banana is a thin curved stroke, not a banana; `step_towel` in `unit_cs_routine_phone` is a striped blue rectangle nobody would call a towel.
Owners: **curriculum-expert** (what each picture must teach), design-director (redraw, §4).

### F10. Medium. The shape builder's silhouettes are see-through and have no piece outlines (`unit_builder_*`)
The silhouette is translucent grey, so the meadow's hill line shows through the house body (`unit_builder_house_tablet_landscape`); the pieces of a silhouette are not outlined, so the house reads as one grey shape and the child cannot see that the roof is a triangle; the rocket's fins are ~15 pt slots; the train has 7 tray tiles. Fix in §3 (T10). Owner: **app-developer**.

### F11. Medium. The meadow is behind everything, even when the stage is empty or abstract
`meadow` is the background of 754 activities. Behind a number line the line crosses the hill edge; behind the balance, the chart, the builder and the spot-the-mistake row the hills compete with the content. In at least eight goldens the stage holds **nothing but the meadow** (`ordinal`, `shape_where`, `shape_small`, `math_time`, `colour_banana`, `cs_routine`, `more_big_things`, `logic_*`), so a child looks at an empty picture for the question. Fix: (a) abstract templates (number line, balance, chart, builder, trace, spot, robot, clock, match pairs) use a plain `paper` stage with a 2 pt `mist` border; (b) a `tap_answer` whose stage has no group and no row hides the stage and the tiles move up and grow (§3, T01). Owner: **app-developer**.

### F12. Medium. Two direction rules disagree with design-spec §8
- **Pattern rows.** Design-spec §8 says pattern rows *mirror* (read right to left, the empty slot at the left end). The built templates draw them left to right with the "?" at the right end (`unit_logic_next_phone`), following the decision in M9 §14 point 4. Either can be right; the spec and the build must agree, and the child must meet one direction everywhere (patterns, stories, queues, "first, then, last").
- **Robot program strip.** Design-spec §7.4 and §8 (the curriculum lead's decision against M-DIR-RTL) say the program strip is **vertical, top to bottom**, beside the grid, with a 2 by 2 arrow palette. `unit_robot_plan_*` draws a horizontal row of five slots under the grid and four arrows in a row.
Needs the owner, through the **curriculum-expert** (one rule for sequences), then **app-developer**.

### F13. Medium. The balance cannot be read on the phone, and its answers are abstract arrows (`unit_balance_compare_phone`)
The pans are flat boards with things ~6 pt tall; the answer is one of three tiles ←, =, →. "Left arrow" means "the left pan is heavier", which a five-year-old must translate. Fix in §3 (T08): the pans are the answer targets. Owners: **app-developer**, **curriculum-expert** (confirm tapping the heavier pan teaches the same).

### F14. Medium. Shop and coins: a "disabled" button, a muddy counter, coins below the touch floor, one coin shape wrong
- `unit_math_shop_phone`: the ✓ tile is grey, which reads as disabled; design-spec §9.5 has no disabled state in the child space.
- `unit_shop_pay_*`: the counter is a translucent brown box with the hill showing through; the 1 shekel coin is ~40 pt, the 2 shekel ~50 pt (floor 56).
- `coins_sheet.png`: the 5 shekel coin is drawn with a **wavy (scalloped) edge**; the real coin is **12-sided** with straight edges (checked again today on the Wikipedia table of the new shekel: "₪5, 24 mm, cupronickel, 12-sided"). A child who holds a real 5 knows it by its corners.
- `unit_math_shop_phone` still pays with the plain gold placeholder `coin`, not the real coins.
- The caption of `shop_pay` breaks "הַ-וִי" across two lines on the phone.
Owners: **app-developer** (✓ state, counter, coin scale), design-director (5 shekel edge in `tools/make_coin_sprites.py`), **hebrew-text-editor** (the "הַ-וִי" wording, and the ₪ placement in the price tag, which I could not judge at golden size).

### F15. Medium. Colour Bay's pictures do not use the teaching colours
`tools/make_picture_sprites.py` tints balls, balloons and flowers with its own `COLOURS` (red `#E5484D`, blue `#2F7FE0`, green `#4CAF50`, purple `#9B6BDF` ...), not the teaching palette in `design/tokens.json` › `color.teach` (red `#D62F2F`, blue `#2563D9`, green `#3CB55A`, purple `#7B3FC4` ...), which design-spec §9.3 chose for lightness spread so confusable pairs also differ in lightness. The sprites' blue is the CS domain colour. No colour-helper symbols are drawn either (§9.3). Fix (mine, next wave): the generator reads `color.teach` from the tokens and re-tints; same ids. Then the **curriculum-expert** checks the red/green and blue/purple items again.

**Also noted (not ranked):** the counting badge sits on top of the flower it counts (`lesson_2_*`, `lesson_5_*`); the robot on the grid is a grey placeholder rather than Tza'adon; the `shape_small` triangle is ~12 pt (too small to recognise even when "small" is the point: floor 32 pt); the sort bins label their rule with a Hebrew word in ~11 pt and a ~12 pt picture (pre-readers need the picture at 40 pt); on the home map the "+" pebble overlaps Nitzi's island and her speech bubble covers the island's landmark.

## 2. Layout constants: the stage modes (for F1 and F7)

All numbers are board points. The answer sizes come from `tokens.touch` (A 96/112, B 80/96; gaps A 24/32, B 16/24).

**Phone 852 by 393** (safe rect x 59 to 793, bottom safe 21, no hotspot in the bottom 24):

```
 standard (today)                 tall (no answer row)              wide (proposal, needs the owner's eye)
 +--------------------------+     +--------------------------+      +----------------------------------+
 | stage 330x128 | bubble |N|     | stage 330x244 | bubble |N|      | bubble 534 wide, max 2 lines  |N |
 | tiles 534 wide         |m|     |               |        |m|      | stage 534x140                 |m |
 +--------------------------+     +--------------------------+      +----------------------------------+
```

| Mode | Stage | Tiles | Used by |
|---|---|---|---|
| `standard` | `Rect(71, 96, 330, 128)` | top 244, width 534 | tap_answer with tiles, sort_drag, build_pattern, shape_builder, match_pairs, shop_pay |
| `tall` | `Rect(71, 96, 330, 244)` (bottom 340) | none | count_tap, give_n (target on stage, tray in the stage's lower band), spot_error, trace, clock_set, flash (already), ordinal row |
| `wide` | bubble `Rect(71, 96, 534, ≤ 92)` (2 lines at 22 pt × 1.7 + 16), stage `Rect(71, 198, 534, 142)` | none | number_line, balance, chart with category answers |

Phone SE 667 by 375: `standard` `Rect(16, 86, 270, 104)` (today), `tall` `Rect(16, 86, 270, 228)`, `wide` bubble `Rect(16, 86, 464, ≤ 88)`, stage `Rect(16, 184, 464, 130)`.

`wide` moves the question above the stage instead of beside it; it changes board 13, so it needs a mock and the owner's look before it is built. `tall` changes nothing the child already knows and can be built now.

**Tablet landscape 1180 by 820:** stage `Rect(96, 236, 776, 380)`, `tilesTop 648` (bottom 760, under the 776 hotspot line), tiles width 776. **Tablet portrait 820 by 1180:** stage `Rect(24, 372, 772, 560)`, `tilesTop 964`. Rule for every class: `tilesTop = stage.bottom + touch.gap.tablet` (never less), which removes the overlap in F7.

## 3. One layout spec per template, the hardest for a small child first

Each is buildable as written; "A" and "B" are the bands; phone numbers first, tablet in brackets.

1. **T04 `trace`** (Band B numerals, Band A shapes). `tall` mode. Trace box 200 by 228 centred in the stage (tablet 360 by 360). The path is drawn as a soft lane: `mist` stroke 28 pt wide for A, 22 pt for B (tablet 40 / 32), round caps, with today's dots on its centre line at 10 pt (tablet 14). Start dot 32 pt `spark` with a small ink arrow (12 pt) showing the first stroke's direction; end dot 20 pt `mist` ring. Tolerance = half the lane + 8 pt. Start-only mode keeps the lane at 12 per cent ink so the size of the numeral is known. Plain `paper` stage.
2. **T01 `count_tap`** (A). `tall` mode. Objects 64 pt (hitSlop 12), gap 16, at most 4 by 3 on the phone (4 × 64 + 3 × 16 = 304; 3 × 64 + 2 × 16 = 224); 13 or more objects only on tablets (96 pt). A decorative basket is dropped on the phone. The count badge sits **below** the object it counts (y + 4), 32 pt, never on it.
3. **T02 `give_n`** (A). `tall` mode. Target (flower, basket) 120 by 120 at the stage's start side (right, x 281 to 401); the givable things wait in two rows on the end side at 64 pt (3 × 64 + 2 × 16 = 224 wide, 2 rows = 144); the count badge 40 pt under the target; ✓ stays the 96 pt tile in its own place under the mic's column (x 525, y 252), not in a tray.
4. **T07 `robot_path`** (A, B). Grid cells 40 pt on the phone (4 by 3 = 172 by 128), 96 pt on tablet; the robot is Tza'adon's small sprite at 36 pt (tablet 80), never a grey placeholder. Arrow pebbles 64 pt for A, 56 for B, gap 16, as a **2 by 2 palette** beside the run button (§7.4); in `plan`, a **vertical program strip** of up to 8 slots (slot 48 by 28, arrow 20 pt) at the stage's end side (left), playhead moving down (pending F12's decision; until then keep today's row but at 28 pt slots). Delete is a 56 pt pebble with an "undo" curl, not a keyboard backspace glyph.
5. **T09 `number_line`** (B). `wide` mode when built; until then `tall`. Line from x + 24 to x + w − 24; numerals Heebo 800, 20 pt (tablet 28), under the ticks; the target of a touch is the **nearest tick to the touch's x anywhere in the stage** (a 48 by 140 column per tick on `wide`, 30 by 244 on `tall`), and a 56 pt lens with the numeral appears above the finger on touch-down, committed on release. In `jump` each hop is drawn as a dashed arc as the frog moves. The line never mirrors: 0 at the left.
6. **T08 `balance`** (B). `wide` mode when built, `tall` until then. Pans are open trays 132 by 44 with their things in up to two rows at 24 pt (5 per row); the beam 6 pt ink. The answer is the **pan itself**: each pan with its column is a 140 by 120 target; "the same" is a 64 pt pebble with "=" centred under the fulcrum. In `balance` mode the blocks wait as 64 pt tiles. When `hideTilt`, the beam stays level as today.
7. **T05 `build_pattern`** (A). `standard`. Model row 40 pt pictures; the slots directly under each model item, 60 by 60 with a 2 pt dashed `ink` 35 per cent ring and no "?" (an empty socket reads as "something goes here"); at most 5 per row on the phone (5 × 60 + 4 × 7 = 328), 8 on tablet (88 pt); snap radius 1.5 × 60. Palette tiles 96 (A) in the answer row.
8. **T10 `shape_builder`** (A, B). `standard` (tablet: stage 776 by 380). Plain `paper` stage. Each slot is drawn opaque `mist` with its own 2 pt dashed `ink` 35 per cent outline, so the parts of the picture show; the picture is fitted to 120 pt tall on the phone (340 on tablet); the smallest slot is never under 32 pt (a picture whose parts would be smaller is tablet-only); a dropped piece snaps to the nearest free slot of its shape within 1.5 × tile. Tray tiles 72 (A) / 64 (B), gap 12, at most 6 on the phone (the train: 5 parts and 1 decoy).
9. **T03 `sort_drag`** (A). `standard`. Up to 3 bins of 100 by 116 with 15 pt gaps; the bin's rule picture is 44 pt at its top (today ~12 pt), the Hebrew word only as a 16 pt caption under it for B; tray tiles 72, gap 12, up to 6 (6 × 72 + 5 × 12 = 492).
10. **T18 `clock_set`** (B). `tall` mode. Face 220 pt diameter (tablet 340) at the stage's start side; numerals Heebo 800 20 pt (tablet 30) at 80 per cent of the radius; hour hand ink, 10 pt wide, 48 per cent of the radius, rounded tip; minute hand `seaDeep`, 5 pt, 70 per cent of the radius (it never reaches the numerals); hands drawn under the numerals' circle of text. Controls in a column on the end side: ↻ (clockwise, moves forward) 64 pt, ↺ 64 pt, ✓ 80 pt, gaps 12 (total 232). No "−" or "+". The clock never mirrors.
11. **T21 `spot_error`** (B). `tall` mode. Tiles 64 pt, gap 12, up to 5 per row on the phone (5 × 64 + 4 × 12 = 368 does not fit 330: use 56 and gap 12, 5 × 56 + 4 × 12 = 328), two rows when there are 6 to 10; tablet 96. A number row draws a faint ink arrow (left to right, 14 pt, 25 per cent) under it on first show, so the reading direction is visible; arrows never mirror. Plain `paper` stage.
12. **T17 `shop_pay`** (B). `standard`. The counter is an opaque `paper` tray 150 by 112 at the stage's end side with a 3 pt dashed ink 35 per cent rim; the price tag 48 pt numerals in an LTR isolate on a `spark` tag at the start side with the thing to buy at 72 pt. Coins at their real relative size with the smallest (1 shekel, 18 mm) at 56 pt (that is 3.1 pt per mm: ½ shekel 81, 10 agorot 68, 2 shekels 67, 5 shekels 75, 10 shekels 72); notes 64 pt tall at their own width ratio. At most 5 coins and the ✓ on the phone, 7 on tablet. ✓ is a `sunset` pebble 80 pt that is never grey; a tap on an empty counter gets a spoken nudge, not a dead button.
13. **T16 `match_pairs`** (A, B). `standard`. Faces 88 pt (A) / 80 (B), gap 16, at most 4 per row on the phone (4 × 88 + 3 × 16 = 400 fits the 534 tile width); a joined pair is drawn as a 4 pt line in the pair's colour between the two faces **and** the same small number badge (so colour is never the only cue); coins inside faces at the real relative size of the `shop_pay` rule, scaled down together.
14. **T01 `tap_answer`** (all bands, and the chart). When the scene has no group, row or numeral (F11), the stage is hidden and the tiles move up to y 120 and grow to 120 pt (A) / 104 (B) on the phone. Rows of pictures: 40 pt, at most 6 on the phone. **Chart:** `tall` mode for "which has most" (each column with its category picture at the base, 56 pt, is the target, at least 88 pt wide; no tiles), `standard` for numeric answers with at most 5 cells per column on the phone (cell 20 pt, gap 4) in a light `mist` grid, more on tablet only; columns and any tiles always in the same left-to-right order.
15. **T14 `flash`**. Already uses the tall room. Objects at least 40 pt; the covered state is a `mist` card with the guide's "eyes closed" pebble, over a plain `paper` stage (no white wash over the meadow). Wording per F3.

## 4. Placeholder inventory, by land

Counts are uses in `content/starter/activity.*.json` (`asset:` references), measured today. "Visible" is how much a child sees it: **very** = on most activities of the land, **often**, **sometimes**.

| Land | Placeholder pictures (uses) | Visible |
|---|---|---|
| **Every land** | `meadow` stage background (754); `tick` and `cross` (25 each); `basket_target` (46) | very |
| **Every land, world** | skill drawings `stair`, `pool`, `cone-tree`, `pattern-door`, `dock`, `stall`, `sprout` (`app/assets/art/world/`, one per skill on every island); the island itself is a flat oval (no scene); decorations `deco_10` lantern and `deco_30` fountain; medal glyphs `try-again`, `bug-fixer`; `ceremony/podium` | very |
| Counting Hills (numbers) | `fish` (100), `ladybug` (25), `frog` (19), `sock` (12), lit twins (`fish_lit`, `star_lit`, `ladybug_lit`, `apple_lit`, `butterfly_lit`, `duck_lit`, `dog_lit`, `cat_lit`, `bird_lit`), `butterfly`, `flower_target`, `nest_empty`, `bowl_empty` | very |
| Market Village (maths) | `apple` (99), `duck` (69), `block` (17), `banana_yellow` (8), `clock_1` to `clock_11` (11), `day_1` to `day_7` (33), `time_morning/noon/evening/night` (18), `coin` generic (6), `stone`, `feather`, `stick_long/short`. Not placeholders: the real coins and notes `coin_*`, `note_*` (drawn from references) | very |
| Riddle Grotto (logic) | `ball_*` colours (~300), `star` (105), `cat` (67), `dog` (56), `bird` (28), `balloon_*`, tinted `shape_*`, `tower_1` to `6` (69), `rule_colour/shape/size` (18), `plant_seed/sprout/flower`, `ball/star/fish/apple_size_*`, `shoe`, `key`, `lock`, `egg`, `egg_crack`, `chick`, `brush`, `bowl`, `spoon`, `rain`, `cloud`, `rainbow`, `pencil`, `paper` | very |
| Colour Bay (colours) | `ball_*` (~90), `balloon_*` (~45), `shade_*` (78), `bloom_*` (~35), `banana_green`, `flower_red/yellow`, `sun`, `apple_green` | very |
| Shape Forest (shapes) | `shape_*` (~150), `solid_*` (41), `pos_above/in/next/on/under` (18), `line_*` (12), `window`, `sign`, `plate` | very |
| Robot Harbour (CS) | `robot` (20), `flag` (20), `step_soap/brush/tap/rinse/towel/paste` (36) | very |

Not used by any activity today: `bloom_black`, `bloom_white`, `clock_10`, `clock_12`, `shape_rect_yellow` (the real coins and notes are drawn by the app from the shop's ids, not from `asset:` references).

The cast (Nitzi, the six hosts, the heroes, the family packs), the stickers 1 to 12, the trophies, medals other than the two glyphs, and the UI pebbles are approved art, not placeholders.

### Replacement order (most visible and most misleading first)

| # | What | Why first | References to look at before drawing | Who |
|---|---|---|---|---|
| 1 | `tick`, `cross` | breaks a rule (F4) | none (symbols) | design-director |
| 2 | Teaching-colour tint of every colour sprite (F15) | Colour Bay teaches the wrong hues | `design/tokens.json` › `color.teach` | design-director |
| 3 | `meadow` split: plain `paper` stage for abstract templates; a calmer meadow (lower hill line, out of the middle 60 per cent) for scenes | on 754 activities | photographs of Israeli spring hills (Wikimedia Commons, Galilee in March) for the hill shapes and greens | design-director |
| 4 | The counting set: `apple`, `fish`, `duck`, `ladybug`, `star`, `cat`, `dog`, `bird`, `butterfly`, `frog`, `ball`, each with its lit twin | the most counted things; must read at 24 pt and look good in a row of four | photographs and facts: seven-spot ladybird (*Coccinella septempunctata*: red, seven black spots, black head with white patches), mallard duckling, goldfish, common frog, cabbage white and painted lady butterflies, a red apple with leaf, house sparrow; read on Wikipedia and Commons | design-director now; the illustrator may restyle |
| 5 | `robot` → Tza'adon's small sprite | every CS activity; a host already exists | `design/assets/tzaadon*` (our own) | design-director |
| 6 | Pictures that teach wrong (F9): `pos_*` with one real table, `time_morning/evening`, `banana_green/yellow`, `step_towel`, `solid_pyramid` | they mislead | photographs: a child's wooden table; sunrise with breakfast table, sunset with lamps; Cavendish banana (green and ripe); a hand towel on a hook; a square pyramid and a triangular one | design-director, with the curriculum-expert's list of what each must show |
| 7 | 5 shekel coin edge: 12 straight sides (F14) | a real feature is wrong | Wikipedia, Israeli new shekel, coin table ("12-sided"), read 2026-10-28; Bank of Israel coin page for the photograph | design-director |
| 8 | Skill drawings per land (24 families, sketch and colour) | every island | the art brief §6.1 themes | **illustrator** (P9 batch 1 and 2); until then I draw per-land variants of the 7 (stair with 3 to 10 steps, pool in the skill's colour ...) so no island shows another land's object |
| 9 | Island scenes (7), decorations, medal glyphs, podium, stickers 13 to 36, confetti | big, looked at for minutes | art brief §6.2 to §6.6 | **illustrator** (P9) |
| 10 | The remaining logic, shapes and maths things (`tower_*`, `rule_*`, `day_*`, `clock_*`, `shade_*`, `shape_*`, `solid_*`, `line_*`) | plain but readable | photographs of wooden block towers, an analogue kitchen clock, paint chips | design-director, then illustrator if the budget allows |

Nothing was drawn in this wave: none of these is plainly broken in the sense of failing to render; F4 and F15 are the next drawing jobs, on the orchestrator's go.
