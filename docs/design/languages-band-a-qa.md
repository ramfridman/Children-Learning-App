# Languages Band A: the design fixes of QA's visual defects (2026-11-07)

Design-director, for QA-BA-5, 6, 7, 9 and 10 (QA's renders in `D:\nn-qa-shots*`) and the curriculum-expert's picture list
(`docs/languages/band-a-build.md` 7.6, 7.12 and 7.13). Sections 1 to 5 say what is done; the **specs for the app-developer** are 3.3,
4.2 and 5.2, and the **edits for the teachers** are 1.3 and 6. Sizes are in points; "phone" is the 852 x 393 board, "SE" 667 x 375.

## 1. QA-BA-5: Pip and the box

### 1.1 Done
- **`pip-feed`** (new picture, `tools/make_language_pictures_band_a.py`, batch 7): Pip whole, crown to toes, on the right of the square
  (x 124 to 250 of 256), his head bent toward an empty bowl at his feet, beak open. The food rail (x 5 to 79) never touches him.
  **`pip-basket`**: the same Pip beside an open toy basket (7.3).
- Their drop target (`scenes.areas.json`, `@target`): `[0.3125, 0.4688, 0.3906, 0.4922]`, the bowl or basket and the room above it
  (80 to 180 by 120 to 246 units). A right piece is carried to its centre, so it sits in the bowl, under the beak: nothing waits on his face.
- **The drop target is not drawn at rest** (`listen_do_session.dart`, `_targetFace`): no filled box over the picture, ever. While a
  piece is held or selected (the tap path), a 4-point outline in `hintHalo` with no fill shows where it goes. A target with its own
  sprite shows only the sprite. This also clears `mika-body`, `scene-picnic` and `scene-toybox`.
- **The sorting bin** (`bin-box`, HEB-A-03 04 to 09): redrawn as an open carton that fills its square with a big white label
  (`BIN_LABEL` = 0.2, 0.41, 0.56, 0.46), the classroom way of labelling a bin with a picture of its contents. On the stage it is
  drawn **whole** (contain, a square of the stage's height less 12), with the group (the elephant, the banana, the shirt) in the label
  (`tap_answer_session.dart`, `binLabel`; the two constants change together). The cover fit that cut the flaps and the bottom is gone.

### 1.2 Looked at
`D:\...\scratchpad\ddba\big2.png` (pip-feed at 1000 px), `docs/design/languages/pictures_batch7a.png` (the batch at 200 and 64 px).
Not looked at in the app: pip-feed on the stage (the items still name `pip-happy`, 1.3).

### 1.3 Teachers (I did not edit units)
- `content/languages/eng/units/08-food.json` items i09, i10, i11, i12: `"picture": "pip-happy"` -> `"picture": "pip-feed"`.
- The new 7.3 drag-to-Pip items of ENG-A-03 and A-05: `"picture": "pip-basket"`.
- Then `python tools/lang_pack.py eng`.

## 2. QA-BA-6: Band A sizes

### 2.1 Done
- **A picture the question stands on gets the stage; the answers go to tiles** (`models.dart`, `TapAnswerActivity.optionsInTiles`): in a
  language course, a `tap_answer` with a `group` (rus.a12.09 "is it a cat?", eng.a07.i08 the family, heb.a03.04 to 09 the bin) answers on
  the 96 tiles under the stage, and the group has the whole stage (phone: about 104 high, was 20 to 28). Lands are unchanged.
- **Counting in place** (`count_tap_session.dart`, `CountLayout._language`): a language count whose target is `asset:blank` gives the
  objects the stage less a 56 strip for the counter, in 1 to 3 rows, whichever makes them largest; each object's touch square is its
  cell (at most 96) and two squares never overlap. Phone: 2 to 4 objects get 64 or more (was 48); tablets 96 (was 60).
- **Speakers**: a puppet bubble's speaker under its tile is 64 on every board (`choice_row.dart`; the room under a tile is 64); a sort
  bin's speaker is 64 wherever a bin is at least 150 wide (tablets, and the phone's two bins of 178), the phone's sign pill then 64 high
  (`ls01_chips.dart`). The SE's bins (121) keep 52: section 4.

### 2.2 What is still under 64 after this
Phone and SE counts of 5 to 10 (RUS-A-10, A-11), and the SE's bin speakers. Specs 3 and 4.2.

## 3. Spec for the app-developer: counts of 5 to 10 on the phones
**Built 2026-11-07** (`count_tap_session.dart`: `layoutFor`, `buildBoardLayer`; `CountLayout._language` tries up to four rows; test `count_tall_stage_test.dart`: phone cells 64 or more, the SE's 58 or more, none touching, the stage given back at the question, hint 2's card in the close-up slot outside the stage). It applies to a language count in place of 5 or more on the phones; the tablets are unchanged. The SE's ten objects are 4 rows of 3.
`CountTapSession.layoutFor`: while the objects are counted (`!answering`) and the count is in place (`CountLayout.countsInPlace`), use
`withTallStage(base)` (phone about 330 x 253, SE 262 x 245); at the question, the usual board. `CountLayout._language` then gives 10
objects cells of 64.5 on the phone (3 rows of 4) and 58 on the SE (4 rows of 3); 5 to 8 get 64 or more on both. The objects slide to their
new cells as the stage shrinks (their `AnimatedPositioned`, 550 ms; none with reduce motion). Hint 2's counting card opens in the answer
area, which the tall stage takes: give it the close-up slot of `ListenDoSession.closeUpSlot` (phone x 413 y 248 side 96, SE x 300
y 222), outside the stage. Goldens: `ls01_count_answer_*`, and a new `count_ten_counting_{phone,phoneSE}`.

## 4. The SE's sort bins
**Built 2026-11-07 (4.2), with one limit.** The corner speaker is 64 and under the sign (`BinGeometry.cornerSpeaker`, `chipRoomFor`, `ls01_sort_session.dart`); the sign has the whole row, and the chips keep out of the 70-wide end side. It holds in **Band A and where no card is a word** (`BinGeometry.bigSpeakersFor`): a text chip of Band B or C (a word of 45 to 80 points, "pan", "lemon") does not fit the 39 points a corner speaker leaves the chips of an SE bin (121 wide, 54 high), and the fit check (`text_fit_test`) refuses it, so Bands B and C, and a Band A sort whose cards are words (the old Hebrew fixture), keep the 52 speaker beside the sign. Band A's own cards are pictures and single letters, so every real Band A sort has the corner speaker on the SE. The SE's chip room is about 39 by 54, so the pictures of a bin with three or more cards are about 39 wide: the design-director may want to look at `heb.a03.01` on the SE with all its cards in the bin. Test: `bin_geometry_test.dart`.

### 4.1 Why not done
On the SE two bins are 121 wide: a 64 speaker beside the sign leaves 29 for it, and the Band A letter is 37 (`golden_ls01_rest_test`'s fit
check refuses it).

### 4.2 Spec for the app-developer
On a bin narrower than 150 (`BinGeometry.binWidth`), the speaker leaves the sign's row and stands in the chips' room at the end corner
(bottom, in the course's direction), 64 square, 6 from the bin's inner edges; the sign then has the whole row (121 - 24 = 97). The chips'
plan (`_chipPlan`) keeps out of that 64 x 64 corner (the last row ends 70 before the end side). Then `speakerTouch` is 64 everywhere and
`_roomy` goes. When D5 lands (Band A bins show a picture and no text), the picture sign is 64 high and 64 wide and the same rule holds.
Goldens: `ls01r_sort_*_phoneSE`, `ls01r_sounds_*_phoneSE`.

## 5. QA-BA-9 and QA-BA-10: the story pages

### 5.1 Done
- **The arrow is never over the picture** (`story_session.dart`, `storyPagePlace`): when the centred page would lie under the turn arrow
  (72, 12 from the bottom and end edges), the page is fitted to the room above the arrow (top centre) or beside it at the start side,
  whichever keeps it larger. The phone's 16:9 page becomes 279 x 157 above the arrow; a square page stands beside it.
- **The finger of hint 3 no longer covers the first letters** (`read_page_session.dart`, `_guide`): the resting finger comes from the
  upper right like every pointing hand, its tip on the top of the first letter, the hand above the line (it ends 6 past the line's start,
  inside the stage's padding of 8). The moving finger of level 2 is unchanged.

### 5.2 Spec for the app-developer: one sentence to a line on the phones (A-12 follow and zones)
**Built 2026-11-07** (`read_page_session.dart`: `zoned`, `layoutFor` uses `withLs01Zones` on the phones, the picture is the stage, the print is the answer zone's tiles, `_ReadPrint`, `_FollowLine(oneRow:)`). Where the two lines are taller than the zone (the SE's 123) the block is scaled down, never cut. Tests in `read_page_test.dart`: the print is under the stage, every line is one row, every word is 48 high or more, the tablet keeps the tall stage.
The SE's tall stage is 262 wide, and a five-word sentence at the print size (34, line height 1.7) is about 560 wide, so it wraps into a
narrow column that is then scaled down. On the phones only, `ReadPageSession.layoutFor` uses `withLs01Zones(base, Band.a)`: the picture
in S (phone 24, 96, 377 x 148; SE 24, 86, 262 x 136), and the print as the tiles in A (phone x 24, y 258, 581 wide; SE x 24, y 240, 484
wide), one line of the page to one row, no `Wrap` (each line a `Row` of its words in a `FittedBox` scaleDown that only shrinks a line wider
than A). Two lines then fit at 0.87 on the SE and at full size on the phone. The tablets keep the tall stage. Hints: the zones of
`_ZoneLine` and the fingers move with their line (they are in the line's own `Stack`). Goldens: `read_page_*` follow and zones, phone and SE.

## 6. QA-BA-7 and 7.6: the bin signs

Drawn (batch 7, `pictures_batch7a.png`): `sign-one` and `sign-many`, the same blue bowl with one orange marble and with a loose heap of
seven, **every marble the same size (r 22)**, so "one" is never the bigger thing; `sign-letters` (an open book whose lines of print are
too small to read) and `sign-other` (an open carton holding a red ball, a crayon drawing and a toy block), the two the same size and
weight. No letter or digit in any. Teachers: HEB-A-05 items 07 and 09 as 7.6 says (`"picture": "sign-one"`, `"sign-many"`); HEB-A-10
s01, s02 and s06 already name `sign-letters` and `sign-other`. The developer: a bin with a picture shows no text (7.6): **built** (the generator refuses a Band A bin with no picture, and `_sign` draws the picture first whatever else the bin holds).

**A-10's shapes**: no unit or pack has a shape character left (searched `content/languages` for the shape and star characters); items 01
to 07, p1 to p5, t03 to t05, s01, s02 and s06 use `shape-dot`, `shape-ring`, `shape-triangle`, `shape-triangle-open`, `shape-heart`,
`shape-flower` and `star`. All seven read as shapes at 84 and at 44 (`scratchpad\ddba\shapes96.png`, `shapes44.png`). No edit is needed.

## 7. RUS rooms reused (7.12)
`scene-room-mouse.hotspots.json` items `rus.a20.23` (teddy, mouse, cat) and `rus.a20.24` (mouse, teddy, cat); `scene-room-ball` item
`rus.a15.25` (ball, balloon, doll); `scene-room-cat` item `rus.a15.26` (cat, dog, porridge); all `show: body`. The three areas of each
room are at least 72 of 256 units (65.5 on the SE's 233 scene) and never meet (checked by `share_map`).
