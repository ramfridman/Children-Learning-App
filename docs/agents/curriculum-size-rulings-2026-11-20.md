# Curriculum expert: the teaching verdicts on the size rulings of 2026-11-20

Branch `lands-ux` at e87d43f7, worktree `D:/nitznutz-lands`. A decisions run on `docs/design/m11/min-sizes.md` §9.2 (D1, D3, D5, D7, D8,
D9). Nothing in `app/`, `content/` or `tools/` changed; nothing committed. Every verdict is on teaching grounds only; the numbers of the
layout stay the design-director's.

| Ruling | Verdict | Re-cut later (ids) |
|---|---|---|
| D7 chart window of 3 rows | **YES with a change** (which rows; one item needs 4) | `c.numc09.15` |
| D9 sets of 7 to 10 in a 5 x 2 frame | **YES with a change** (bottom row left-aligned; order fixed) | `b.mathb06.9` |
| D3 one sample per shelf | **YES with a change** (count bins draw a tally) | none (the two Shows need the tally, not a re-cut) |
| D5 shape builder snap, tray, palettes | **NO to "nearest slot of that kind"**; YES to the tray and the palette caps | none |
| D8 purse caps | **YES as ruled**; no item breaks the cap. Three items to re-cut for diagnosis | `c.numc03.4`, `c.numc03.15`, `c.numc03.16` (and `c.numc03.14` low) |
| D1 size families, `c.numb10` stacked | **YES with a change** (3-size step floor; the big row always the longest) | none (layout only) |

---

## 1. D7, the hundred chart's 3-row window on phones: YES with a change

**Why it still teaches.** What `c.numc01.13-16` and `c.numc09.13-17` teach lives in the chart's columns of ten: "ten more is the cell
under it, ten less the cell above it, a column keeps its ones digit", and in a row: "after 40 comes 41 at the start of the next row".
A window that is still **ten columns wide** keeps all of that: the child sees whole rows of ten, so "one row down = ten more" stays
true and visible. What a window must never do is cut off a given number, the empty cell, or the one row the re-teach points at.

**The rule (for the app-developer, in `ChartSpec.around` on phones):** three rows: the row of the given number, with the row above and
the row below it. When the given numbers stand on both sides of the empty cell (`c.numc09.16`), the rows of all of them. Never clip a
lit or blank cell. Keep the decade order (rows top to bottom, 1 to 100, LTR, never mirrored, §8.6 rule 1).

| Item | Lit / blank | Rows the window holds | Why these |
|---|---|---|---|
| `c.numc01.13` | 31-40 lit, 37 blank | **21-50** | the row counted along, with a row on each side |
| `c.numc01.14` | 40 → 41 | **21-50** | 40 ends a row and 41 starts the next: both rows needed; 30 → 31 above models the same wrap; distractor 50 is visible at the end of 41-50 |
| `c.numc01.15` | 69 → 70 | **51-80** | 70 ends its row; distractor 71 (start of next row) and 60 (end of the row above) both in view |
| `c.numc01.16` | 34 → 35 | **21-50** | |
| `c.numc09.13` | 34 → 44 (ten more) | **21-50** | 24 (the M-OP-SWAP distractor, ten less) is in view, so the re-teach can point "that one is above, ten less" |
| `c.numc09.14` | 57 → 47 (ten less) | **41-70** | 67 (M-OP-SWAP) in view |
| `c.numc09.15` | 6, 16, 26 → 36 | **1-40: four rows** | see below |
| `c.numc09.16` | 48, 68 → 58 | **41-70** | exactly its three rows |
| `c.numc09.17` | 62 → 72 | **51-80** | 52 (M-OP-SWAP) in view |

**Hint cards of the column items without a chart on the stage** (`c.numc09.6`, `.7`, `.8`, drawn by `_hundredChart` through `_chartOf`):
today `ChartSpec.around` gives them 6 rows, and `c.numc09.8` the whole chart; with 32-high chips that cannot fit the phone. On phones
the hint card shows **the gap's row and the two nearest rows holding a given number**: `.6` 21-50 (26 / ? / 46), `.7` 21-50 (24 / ? / 44),
`.8` 61-90 (69, 79, ?). That is exactly the "above is ten less, below is ten more" picture the hint is for.

**The one item that needs more: `c.numc09.15`** ("what is the next number in the column?", 6, 16, 26 → 36) spans four rows. Three given
terms are what make it a pattern (the +10 step is seen twice before the child extends it; with two terms it is one difference). So:
keep the item, and on phones give it the 148-high stage that D5 already gives the shape builder (`withStageAtLeast`; 4 rows of 37, chips
of 32 fit), and the 157 stage on SE. Only if the design-director refuses that, re-cut it to lit `[16, 26]`, blank `[36]` (same options and
tags). **Content rule for the validator:** a chart item's lit and blank cells span at most 3 rows, or 4 with the tall stage.

**No item needs the whole chart.** One change for first meetings (priority low, M11 or later): in the lesson `hundred-chart`, the first
chart item (`c.numc09.13`, the Together item) opens on a phone with the whole 10 x 10 chart for a moment, the window's rows lit, then
zooms into the window. The numerals of the whole chart need not be readable; the child sees "a hundred, in rows of ten" once, and that
the window is a part of it. The Show `show.num-c-09` is a number line, so nothing else shows the whole chart on a phone.

## 2. D9, sets of 7 to 10 in a 5 x 2 frame: YES with a change

**The counting order the hint must follow:** top row first, **left to right, 1 to 5**; then the bottom row, **left to right from the
same left edge, 6 to 10**. The hand goes back to the left edge between the rows (a Z, never a snake).

**The change:** the bottom row is **left-aligned under cells 1, 2, 3 ...**, not centred (today `groupLayout('rows5')` centres the last row).
Eight must read as "five and three", with the two missing cells at the right end, exactly as on a ten-frame. Centring the bottom row
hides the five-structure and the "how many to ten" gap, and makes the hand's path ambiguous.

**Why this order:** it is the ten-frame's fill order, which the app already draws (`groupLayout('ten_frame')` fills row by row from the
left) and which the flash ten-frames of NUM-B-09 and the make-ten items use; it keeps maths structures LTR, like the number line
(curriculum §8.6 rule 1); and it lands "5" at the end of the top row, which is what lets a child see 7 as 5 and 2 (conceptual
subitising, Clements 1999; ten-frames, Bobis 1996). The child's own counting order is never judged (order-irrelevance principle,
Gelman and Gallistel 1978): the hint models one systematic order, it does not require it.

**Is the frame right for every such item?** Yes for every `line` group of 7 to 10 in tap_answer, flash and balance; the content ids:
`b.mathb01.10-12`, `b.mathb02.3-6`, `b.numb14.5-8`, `b15.numa09.3`, and the small set of `c.numb10.1-3` (D1). For take-away and
part-whole (`b.mathb01`, `b.mathb02`, `b.numb14`) the frame is a better picture than a line: removing 5 is "the top row", the
ten-frame strategy Band B is meant to reach. For Band A `b15.numa09.3`, two even rows are the step between a line and a scatter in the
counting trajectory (Clements and Sarama, Counter (10)); fine.

**What must not become a frame (and D9 does not touch, keep it so):**
- **Scatter on purpose**, never converted: the NUM-A-09 counting items (`count.*`, `b15.numa09.1-2`, `b.mathb01.14`: keeping track in a
  scatter is the skill) and the even/odd items `b.numb18.4, .5, .8, .10` (the child does the pairing; two rows of five would show
  odd/even ready-made).
- **count_tap lines** (`b15.numa02.2-3`, `c.numb06.16-17`) are laid out by `CountLayout`, not by D9; they keep a line (a single path
  for Band A's first counts to 10). D6's SE grid (rows of 4, left to right, top row first) is acceptable there, because each tap marks
  what is counted.

**Re-cut later:** `b.mathb06.9` ("seven shekels, how many more to make ten?", MATH-B-06): it must be a real `ten_frame` **with its
board and the three empty cells**, not a frame without its board; the empty cells are the picture of the answer that MATH-B-06's
representation (ten-frame) is about. Change `arrangement` to `ten_frame` in its generator table.

## 3. D3, one sample per shelf on a phone: YES with a change

**One sample is enough to state the rule for every category sort we have.** The bin's rule is carried by the sample's kind and the
label (and the voice names it); the second copy in `log.sortdrag.three` and `show.math-a-07` (count 2) only marks "a group of", which
the shelf itself already says. Checked: every three-bin sort in the pack (27 items) uses `count` 1 or 2 as a category marker, **except
two**:

- `show.shp-b-01` (bins: 4, 5, 6 `stick_long`: quadrilateral, pentagon, hexagon) and `show.shp-b-02` (3, 4, 5 sticks: "three sides"
  ...). Here the number of sticks **is** the rule (count the sides, then name it). One stick would erase what the Show teaches.

**What a phone shows for a bin whose rule is a count:** the sample box draws **N upright sticks side by side, a tally** (InkFit may widen
it to 64: six sticks at stroke 4 and gap 5 are 49 wide), each stick at least 36 high. Not one stick with a numeral badge: the Show says
"I count the sides one by one", and the sticks are the sides. No bin by count holds more than 6, and none is Band A.

**Content rule for the validator (replaces the wording in D3):** bins that share a sprite and differ only in `count` are a sort by
count: on a phone the sample is drawn as a tally of N (N ≤ 6); N > 6 is refused. A Band A sort by count, if one is ever authored, has
two bins on a phone.

**Also checked, no change:** the share sorts (`b.mathb10.2`, `.7`, `b15.matha03.1-2`) judge the count in each bin; their fair share is 1
or 2, under the 4 a well shows one by one, so the pile and badge only appear when a share is already clearly unequal. Keep the 4
individually drawn items as the floor for share sorts.

## 4. D5, the shape builder and the palettes: NO to the snap as ruled; YES to the tray and the palette caps

**The snap "to the nearest free slot of that kind" removes the item's thinking.** Bringing a piece to the outline that fits it **is** the
skill: SHP-A-01 matches a shape to its hole, SHP-A-06 fills an outline puzzle piece by piece (the "piece assembler" level of the
shape-composition trajectory, Clements and Sarama). If every drop flies home, the child only drags shapes onto the stage. It also
switches off the diagnosis of every `shp.match.*` item: the rectangle dropped on the square hole (M-SHP-SQRECT, a `pieceTags` entry
with a `slot`) would fly to the rectangle's hole, and the open or curved shape tried in a hole (M-SHP-CLOSED) or the oval in the circle's
hole (M-SHP-PROTO) would never be placed anywhere, so never seen.

**Instead (the app-developer's code; the engine stays as it is):**
1. A drop is taken by the free slot **under it or nearest to it within a reach** of about half that slot's size and at least 24 pt
   (on a phone; precision is forgiven, place is not).
2. If two free slots are within reach and one fits the piece (`ShapeBuilderActivity.fits`, by shape class, not by sprite or colour),
   the fitting one takes it: this forgives the small slots of `shp.build.face` without hiding a misconception, because the holes of the
   `shp.match.*` items stand far enough apart that two are never within reach.
3. A slot that does not fit judges the drop as today (`tagFor`: the misconception, then the bounce back).
4. A drop within reach of no slot goes back to the tray, uncounted (an unclear move is never wrong).
5. Several identical slots (the train's four wheels, the four squares of `b.shpb06.4`): any free one is equally right; the nearest takes it.

**The tray: YES.** One tile per kind with a count badge is fine: the number of pieces is given by the prompt where it matters
(`b.shpb06.1` "from two squares", `b.shpb06.4` "from four squares"), so the badge gives nothing away. Group tiles by the sprite as
ruled (the train's yellow and red squares are two tiles; both fit either square slot, by class). Maximum today is 5 kinds
(`shp.build.face`, `b15.shpa06.1`, five `shp.match.*` items); the cap of 5 holds. For Band A a small stack of copies reads better than a
numeral to a 3-year-old (the design-director's choice).

**Orientation:** unchanged by D5. Rotation already snaps (SHP-A-06's note); turning a piece is not asked anywhere in the pack today.

**P0 (M12) "one tap places it":** acceptable as play for under-3s, but such a tap is not evidence of SHP-A-01 or SHP-A-06 and must not
count toward their mastery.

**Palettes: YES.** No Band A pattern needs 6, or 5: the largest Band A palette is 4 (`cs.wrong.teeth`, `.teeth2`, `.wash`, `.wash2`,
`log.story.egg.then`, `math.time.evening`, `show.cs-a-05`, `show.math-a-05`); counts by band: A 2 (9), 3 (26), 4 (8); B 3 (9), 4 (13),
5 (6), 6 (4). Band B needs 6 for the rainbow (`b.colb06.1, .3, .4`) and the seriation of six towers (`b.logb11.3`). The caps (6 for B
and C, 4 for A) are right: a Band A pattern's unit is 2 or 3 pictures plus one distractor.

## 5. D8, the purse: YES as ruled

**No `shop_pay` item breaks the cap today** (25 items checked): Band C purses hold at most 8 of a kind and 2 kinds (tens and ones);
Band B purses at most 7 coins. Tens over ones in two rows is a sound picture of place value (one row per place, the Show
`blocks-tens-and-ones` does the same).

**Three items to re-cut, not for the cap but because the cap is reached in a way that blinds a classifier** (all within the cap
after the re-cut):

| Item | Price, purse | Problem | Re-cut |
|---|---|---|---|
| `c.numc03.4` | 82; 8 tens, 5 ones | "paid reversed" (28 = 2 tens + 8 ones) cannot be paid; all 8 tens must be used | price **72**, purse 8 tens + 8 ones (reversed 27 payable, a spare ten) |
| `c.numc03.16` | 81; 8 tens, 4 ones | reversed 18 needs 8 ones; all tens used | price **71**, purse 8 tens + 8 ones |
| `c.numc03.15` | 27; 4 tens, 8 ones | reversed 72 needs 7 tens | purse **8 tens** + 8 ones |
| `c.numc03.14` (low) | 68; 8 tens, 8 ones | all 8 ones must be used (no choice left in that kind) | price **65** (keep the purse) |

**Rule for the generator table (Band C, two kinds):** a price whose reversal is a classifier must be payable reversed from the purse,
and each kind keeps at least one spare coin (choosing how many is the evidence). With 8 of a kind, prices stay ≤ 79 and their ones
digit ≤ 7. (`c.numc03.17`, price 33, has a reversal equal to itself, so its classifier never fires; harmless, but a different price
would use it.)

## 6. D1, size families and `c.numb10`: YES with a change

**Is 1.6 enough to see "bigger" at a glance? Yes, for two sizes.** 1.6 times the width is about 2.6 times the area; young children's
size and number comparisons work at far finer ratios (number: about 3:4 at age 3, Halberda and Feigenson 2008; area acuity develops
on its own course, Odic 2018, and I did not verify an area figure for age 3, so the claim rests on the number figure as a conservative
stand-in). The art the family uses is far above the floor anyway: `*_size_s/m/l` are drawn at 0.35 / 0.65 / 1.0 (large is 2.9 x
small), and D1's geometry gives 24-26 against 66-72 ink.

**The change: a floor for the middle.** Seriation items with three sizes (`log.size.middle`, `log.size.middle.down`, the
`b15.loga*` and `b15.matha04*` rows, `show.log-a-10`, `show.math-a-04`) ask for "the middle one", which depends on each step, not only
on the ends. Add to SIZE_BIG: in a family of three on one screen, **each neighbouring step ≥ 1.4 x** (so the largest ≥ 2 x the
smallest). Today's art passes (1.86 and 1.54); the rule catches a fit that squeezes the middle.

**`c.numb10` stacked: the question is unchanged, with one condition.** Stacking the small set (5 x 2 frame) over the big set (one row)
keeps both the lure M-CNT-SIZE is about (the big things look like more) and the question "which number is bigger?", and with both sets
starting at the **same left edge** it invites one-to-one matching, the very re-teach of M-CNT-SIZE (R1 in §5.2). The drawn size ratio
falls from the content's 2.5 (scale 0.6 vs 1.5) to about 1.7 (ink 24 vs 40): still "small stars against big stars" at a glance; keep
it at 1.6 to 1.75 as ruled.

**The condition: the big row must always be the longer row.** The lure is "bigger or more spread out" (M-CNT-SIZE). At cell 52 the
big set of `c.numb10.4` (3 big against 6 small) is 156 wide against the small frame's 160, and `c.numb10.1` (4 big) only 208: the lure
weakens or vanishes. So the big set is spread over **at least 1.5 x the small set's width** whatever its count (phone 260, the width
D1 gives five; tablets in proportion), its things keeping their size. Hints count the small set in the D9 frame order and the big row
left to right.

---

## Report

### Done
Wrote this file. Nothing else changed: no code, no content, no generator table, no commit.

### Proof
Read `min-sizes.md` §9 and the design report; read every cited item in `content/starter/`: the 9 hundred-chart items and the 3 column
items' hint path (`app/lib/play/stage_pictures.dart` `ChartSpec.around`, `app/lib/play/hints/tap_plans_c.dart` `_chartOf`,
`_hundredChart`); all 106 groups of 7 to 10 in the pack (20 `line`, 15 `ten_frame`, 14 `scatter`, 56 unset) and `groupLayout` in
`app/lib/play/sprite_group.dart`; all 27 sorts with three bins; all 25 shape_builder items with `fits` and `tagFor`
(`app/lib/content/models.dart`) and the drop code (`shape_builder_session.dart`); all 75 build_pattern palettes; all 25 shop_pay
purses against the caps and the `paid_digits` / `paid_reversed` classifiers; the four `c.numb10` items and the size sprites' scales.
Not looked at: the mock PNGs, any device or golden; the M12 P0 design beyond §9.1.

### Hand-offs
- **design-director:** D7 the window rows per item and the 148 / 157 stage for `c.numc09.15` (or say no, then the re-cut stands);
  the optional whole-chart zoom of the lesson's first chart; D9 the bottom row left-aligned; D3 the tally sample for count bins;
  D1 the big row spread to ≥ 1.5 x the small set's width and the three-size step floor.
- **app-developer:** D7 `ChartSpec.around` on phones (3 rows, the rules above) and the hint card's rows for `c.numc09.6-8`; D9
  `rows5` left-aligned and the hint order; D5 the snap rules 1 to 5 (not "of that kind"); the generator re-cuts later:
  `b.mathb06.9` (ten_frame), `c.numc03.4`, `.15`, `.16`, `.14`, and `c.numc09.15` only if the tall stage is refused.
- **qa-engineer:** guard: a chart window never clips a lit or blank cell; `shp.match.*` keeps a wrong placement possible (a test that
  drops the rectangle on the square hole and gets M-SHP-SQRECT); the D3 tally rule; the three-size step ≥ 1.4; the purse spare-coin and
  reversal rule.

### Needs the owner
Nothing.

### Open
- The tally sample and the D5 snap reach are my teaching rules; the exact pixels are the design-director's.
- I cited from memory: Gelman and Gallistel 1978 (counting principles), Clements 1999 (subitising), Bobis 1996 (ten-frames), Clements
  and Sarama (learning trajectories: counting, shape composition), Halberda and Feigenson 2008 (number acuity, about 3:4 at age 3,
  seen only in a search summary); Odic 2018 (Child Development: area and number develop independently) found by search, its area figures
  not read.

Sources searched: [Odic 2018, Number develops independently of area, length, density, time](https://odic.psych.ubc.ca/files/pdfs/Odic%20(2018)%20Number%20develops%20independently%20of%20area,%20length,%20density,%20time.pdf)
(abstract-level only; the PDF text could not be read). The 3:4-at-age-3 figure for Halberda and Feigenson 2008 came from a search
summary of a review; I did not open the review, so treat it as known-from-literature, not verified here.

No permission rule refused an action. Nothing paid, no package, no secret.
