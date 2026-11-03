# B-38: three picture decisions (curriculum-expert, 2026-11-01)

The last three questions from the B-15 picture hand-offs, decided for the next signed pack (B-36). Previews looked at: the
B-38 sheet and the phone previews `where_a08_*`, `match_solids`, `robot_old`, `robot_2x4`, `robot_3x4`.

## 1. SHP-A-08 transfer items move to the cat and the basket (done in content)

**Decision: yes.** `b15.shpa08.1` and `b15.shpa08.2` are `check: transfer` items; the B-15 spec (`docs/knowledge/b15-content-spec.md`,
SHP-A-08 row) asked for "a new pair of objects (a cat and a basket)". With the ball and the box they are the same pictures as the
six `shp.where.*` items, so they test recall of a picture, not transfer of the word.

A second reason, found in the previews: the old tiles do not share one reference object. `pos_above`, `pos_on` and `pos_next` show
a box, `pos_under` a table and `pos_in` a bin. In the old `b15.shpa08.1` ("above the box") the "under" tile is a table, and in
`b15.shpa08.2` ("under the table") the "in" and "above" tiles are a box and a bin: a child can reject a distractor by the noun,
without the position word. The three cat tiles share one cat and one basket, so only the relation differs, which is what
M-SPACE-WORD needs.

Words: the cat set has in, on and next to (§4 SHP-A-08: עַל, מִתַּחַת, בְּתוֹךְ, לְיַד, מֵעַל). "In" and "on" are the first spatial
words children acquire (then under, then next to; Clark 1973; Johnston and Slobin 1979), so they are a fair transfer probe at 3 to 4.
Above and under stay covered by `shp.where.above` and `shp.where.under`.

| id | prompt (draft) | options (o1, o2, o3) | correct | tags |
|---|---|---|---|---|
| b15.shpa08.1 | אֵיפֹה הֶחָתוּל? בְּתוֹךְ הַסַּל. | pos_cat_on, pos_cat_in, pos_cat_next | o2 in | on, next: M-SPACE-WORD |
| b15.shpa08.2 | אֵיפֹה הֶחָתוּל? עַל הַסַּל. | pos_cat_next, pos_cat_in, pos_cat_on | o3 on | next, in: M-SPACE-WORD |

Changed in `content/units/shapes.json` (the two items, and `names` for the three `pos_cat_*` labels), regenerated with
`tools/author.py` (only the two activity files change; `tools/test_generators.py` passes). The pack's `review` stays `needs-editor`.

**To the hebrew-text-editor** (all drafts, not final): the two prompts, the two correct lines (`כֵּן! הֶחָתוּל בְּתוֹךְ הַסַּל.`,
`כֵּן! הֶחָתוּל עַל הַסַּל.`), the two h3 lines (they must say how to see it, answer last: in = the basket is all around the cat; on =
the basket is closed and the cat sits on top of it), and the shared M-SPACE-WORD line `fb.space_word` ("הַמִּלָּה אוֹמֶרֶת אֵיפֹה
הַכַּדּוּר"), which now names the wrong animal for these two items: word it without the object, or per item. The master-table rows
for `activity.b15.shpa08.*` are now stale.

**To the app-developer:** the B-40 hint `_position` (`app/lib/play/hints/tap_plans.dart`) reads `asset:pos_<where>`; `pos_cat_in`
gives `cat_in`, so these items fall back to the generic hint. Strip `cat_`, keep the duck as the toy (it is not the tile's cat,
as the rule there says), and draw the named object, the basket (`basket_empty` for "in"; for "on" a closed basket like the tile's,
from the design-director). Voice lines `vo:b15.shpa08.{1,2}.{prompt,correct,h3}` go to the B-45 batch.

**Later (design-director, not the next pack):** one reference object for the whole `pos_*` set, so `shp.where.under` ("under the
table", with box tiles beside it) can no longer be answered by the noun.

## 2. `solid_cube`: where box versus cube matters

The distinction is a Band B naming goal (SHP-B-08 lists קֻבִּיָּה and תֵּבָה as two solids; §8.1). In Band A (SHP-A-07) the property
matters, not the name: does it roll or stack. The pack has no cube item at all today, so SHP-B-08's "names the cube" is untested.

| id | change | reason |
|---|---|---|
| x.shpb09.4 | replace `solid_sphere` ↔ `shape_circle` with `solid_cube` ↔ `shape_square` | **wrong content**: a sphere has no flat face, so "the flat shape on it" has no answer for it |
| b.shpb08.5 ("where is the box?") | replace the distractor `solid_cylinder` with `solid_cube` (tag M-SHP-PROTO, "a box is any box") | box versus cube is the contrast the two words exist for |
| new SHP-B-08 item "אֵיפֹה הַקֻּבִּיָּה?" | `solid_cube`, `solid_box`, `solid_pyramid` | the cube is never asked for; needs an editor prompt |
| x.shpb09.1 or .2 | optional: add `solid_cube` ↔ `shape_square` as a fourth pair beside the box ↔ rectangle | square face versus rectangle face is the face lesson of the two solids |
| b15.shpa07.2 ("what can we stack?") | optional: `solid_cube` (a block, קֻבִּיָּה) in place of `solid_box` | transfer of "stacks" to a second flat-faced object; Band A label is the everyday word for a toy block |

**Done (2026-11-01, on the coordinator's request):** `x.shpb09.4` is cube ↔ square; `b.shpb08.5` offers the cube (tag
M-SHP-SQRECT); the new `b.shpb08.10` "אֵיפֹה הַקֻּבִּיָּה?" offers the box (M-SHP-SQRECT) and a flat square (M-SHP-FACE: the face taken
for the solid), in the lesson `solids-more`; `b15.shpa07.2` stacks the cube (a transfer item, so a new object fits it), with a
process h3. `solid_cube` is in `NAMES` (`tools/band_b.py`), the unit asset lists and `pack.json`. All Hebrew is a draft,
needs-editor; the changed text-ready rows are held in `tools/test_hebrew_sources.py` (`HELD`) until the editor's rows catch up.
The `x.shpb09.1`/`.2` fourth pair was not added.

Keep `solid_box` everywhere else. The SHP-B-09 box ↔ rectangle pairs are right now that the box is long and low (in the old
drawing the box looked like a cube, which made box ↔ rectangle look wrong; see `match_solids`). The generator lists
(`tools/band_b2.py` line 214, `tools/band_b3.py` line 248) and the new item are the app-developer's; `solid_cube` is not yet
listed in `content/starter/pack.json` (the SVG is there).

## 3. Robot boards with 4 rows: option (a), the layout

**Decision: (a), a taller stage with the arrow pad beside the grid.** Do not change the boards.

Boards with 4 rows: `b15.csa03.1`, `b15.csa03.2` (3×4), and `b.csb01.1`, `.2`, `.4`, `.6`, `.8` (4×4), `.5`, `.7` (5×4): 9 boards,
7 of them CS-B-01 (not 8; `b.csb01.3` is 5×3).

Why (b) is worse for teaching: the difficulty of a robot path for young children is its number of steps, its number of turns, and
how many of the steps are left and right. With 3 rows the vertical travel is at most 2, so every board either gets shorter (easier
than the band's step) or moves steps from up and down to left and right, which raises the left-right load in Bands A and B, where
left and right are still unreliable (PLAN.md bands). The staircases of `b.csb01.6`, `.7`, `.8` (three alternating turns) need 4
rows. So (b) changes every solution and the difficulty of all 9 boards. The previews show the room is there: the phone stage is a
short strip with empty space under the arrow row.

**To the app-developer:** the taller stage and the 2×2 arrow pad beside the grid (cells at least about 44 pt on a phone, the
arrows never mirrored), with the design-director's layout. **To the owner:** nothing to decide; no syllabus change.
