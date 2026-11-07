# C1 base-ten blocks: a rod that is visibly ten, cubes a child can count

Design note by the design-director, 2026-11-07, for the owner's feedback on the Band C base-ten items (c.numc03.25 "אֵיפֹה הַמִּסְפָּר
שְׁלוֹשִׁים וְאַרְבַּע?" and the "how many" items). Mockups in `docs/design/c1-blocks/`, made by
`docs/design/c1-blocks/make_c1_blocks_mockups.py` (headless Chrome, boards at 1 px = 1 pt). Status: proposal, needs the owner's eye
(section 9); nothing in `app/` is changed.

## 1. What the owner saw, measured

Measured on the PNGs the owner looked at (pixel runs, 1 px = 1 pt):

| Picture | Rod cube | Loose cube | Problem |
|---|---|---|---|
| `qa-c1b/r/phone/c.numc03.25_a_start.png` (blocks on the tiles) | **7 pt** wide, rod about 62 pt tall | **6–7 pt** in the rod options, **18–19 pt** in the "7 loose" option | the loose cubes of one option are 2.7 times the cubes of the next; the rod is teal and the cubes yellow, so nothing says a rod is ten of those cubes |
| `app/test/goldens/c1_blocks_picture_start_phone.png` (blocks on the stage) | 12–13 pt, joins a 0.7 pt line at 60 % alpha | 11–12 pt | the joins cannot be seen at 1x; again two colours; the stage is 128 pt tall, so the rods fill it with no room to grow |

So the owner's two questions have two causes: (1) the rod does not look like ten of the loose cubes (other colour, joins invisible, other
size), and (2) on the tiles the cubes are 6–7 pt, about 1 mm on a phone, which no young child can count.

## 2. How big must a cube be? (the measure)

Facts used:

- **Device scale**: 1 pt = 0.156 mm on an iPhone (163 pt per inch), about 0.159 mm on Android (1 dp), 0.192 mm on a full-size iPad
  (design-spec 6.1).
- **Viewing distance**: children hold phones close: a mean of **24 cm**, 21 cm for small content, against 40–50 cm for adults
  ([ARVO 2020, reported by Healio](https://www.healio.com/news/ophthalmology/20200520/childrens-viewing-behavior-with-mobile-devices-may-affect-myopia-development);
  a conference result). A 2023 study of children's viewing distance recommends at least **18-pt text on smartphones** to keep 33 cm
  ([BMJ Paediatrics Open 2023](https://doaj.org/article/350f7eb9e664429bba8aec044ad52314)). This note uses 25 cm.
- **Acuity is not the limit**: by 8 years single-letter acuity is adult (threshold stroke 0.81 arcmin; 1.05 arcmin at 5 years).
- **Crowding is the limit**: children's crowding distance is about **2.5–2.8 times the adult one** (7.0 to 7.8 stroke widths at 5, 8 and
  11 years against 2.8 for adults) and is still immature at 11 (Jeon, Hamid, Maurer and Lewis 2010, *J. Exp. Child Psychology* 107(4),
  423–437, [doi:10.1016/j.jecp.2010.05.009](https://doi.org/10.1016/j.jecp.2010.05.009)). Things packed edge to edge run together for a
  child long after each one alone is easy to see. Counting a row of identical cubes is exactly that case.
- **Touch**: cubes are not touch targets; the answers are (design-spec 6.1, Anthony 2013). A child cannot touch each cube of a rod at any
  phone size (ten cubes of a fingertip's width would be taller than the screen), so the app counts a rod with the child (section 6).
- **What a base-ten app does**: The Math Learning Center's Number Pieces draws a ten as ten unit squares in the same yellow as the loose
  ones with a dark line at every join (looked at 2026-11-07, [apps.mathlearningcenter.org/number-pieces](https://apps.mathlearningcenter.org/number-pieces/));
  wooden Dienes rods have a groove at each unit ([Base ten blocks](https://en.wikipedia.org/wiki/Base_ten_blocks)).

The rule this note sets (u = the side of one cube, in pt):

| | u | On a phone | At 25 cm | Why |
|---|---|---|---|---|
| **Floor (never below)** | **12 pt** | 1.9 mm | 26 arcmin | about the cap height of 18-pt text, the smallest text the 2023 study accepts for children on a phone; about 30 times the 8-year-old acuity stroke |
| **Target on phones** | **14 pt or more** | 2.2 mm | 30 arcmin | each cube clearly its own square at arm's length |
| **Tablets** | **19 pt or more** | 3.6 mm (iPad) | 50 arcmin | the room is there |
| Joins and gaps | join line max(1.2 pt, 0.09 u) at 3:1 contrast, plus a notch; loose gap 0.3 u (3.6 to 4.5 pt) | | | the crowding result: the boundary between two cubes must be a contour, not a hairline |

## 3. The decision in one line

**A rod is ten real cubes stuck together, the same cube (same colour, size and drawing) as the loose ones, with every join visible; a short
opening demonstration shows ten loose cubes snapping into a rod; the layouts give the blocks the stage's full height so a cube is
13–15 pt on phones and 19–25 pt on tablets, never under 12.**

## 4. The drawing (for `stage_pictures.dart`, `BaseTenLayout` and `_BlocksPainter`)

See `cube_closeup.png` (1x, 2x, 3x, both colourways, lit and crossed).

4.1 **One cube for everything.** A rounded square, corner radius 0.2 u, a dark edge max(1.2, 0.09 u), a shine on top (a bar 0.42 u by
max(1.2, 0.13 u) at 0.2 u, 0.17 u, 80 %), and a side face 0.16 u on the right. Loose cubes and the cubes in a rod are the same drawing at
the same u.

4.2 **A rod is ten of them.** The ten cubes touch (no gap). Behind them a spine (inset 0.12 u, the edge colour) shows through the rounded
corners, so every join is a dark line with a notch on both sides; one continuous side face (0.16 u) runs down the right of the whole rod,
which makes the ten one thing. A rod is never drawn as one long bar with lines on it.

4.3 **Colour.** One colourway for ones and tens (and the flats of C2, later). Recommended **"sea"**: body `sea` #1A9E9A, edge #1D485D
(`seaDeep` mixed half-way to `ink`: 3.0:1 against the body, where `seaDeep` alone gives only 1.85:1), shine #7FD3CF, side #13827E. The
alternative **"spark"** (yellow body, edge `math.deep` #A35A00, joins 3.4:1) reads like Number Pieces, but yellow on the meadow's grass
is 1.03:1 and the lit rod's gold glow would be gold on gold. The owner picks (section 9). The hint keeps drawing the whole picture in
`sky` as today.

4.4 **Order and grouping.** Tens left, ones right, as the digits are written (LTR inside the picture, design-spec 8: the number decides).
Rods 0.5 u apart; 1.2 u between the tens and the ones. **The ones stand in a 2 by 5 frame**, filled from the bottom, the left column first
(5 then the rest), loose gap 0.3 u, bottom-aligned with the rods. So 7 reads as 5 and 2, 9 as 5 and 4 (the five-structure the child knows
from the Band B ten-frames), and 10 loose cubes would fill the frame, the same ten as a rod. This replaces "ones stand in threes"
(`_cubeStep` 1.3).

4.5 **The lit rod** (c.numc03.24 "...הַמּוֹט שֶׁזּוֹהֵר"): the rod keeps its cubes; behind it a glow (inflate 0.65 u, `spark` at 55 %), a
tint (inflate 0.35 u, `sparkTint`) and a ring (`sparkDeep`, max(2.5, 0.2 u)). The ring is a shape, so the cue is not colour alone (9.3).
The unit fit counts 0.4 u of padding round a picture with a lit rod.

4.6 **Crossed rods** (taken away, c.mathc03.17): the crossed rods (from the right) stand 0.6 u further from the rods that are left (the
two groups the child compares), each at 32 % opacity with a tall X on its middle that stays inside the rod's own gaps: half-width
0.45 u, half-height 1.3 u, `paper` under-stroke max(4.2, 0.34 u), `ink` stroke max(2.4, 0.19 u), round caps. (Today's X is 2.2 u wide,
so four crossed rods run into one "XXXX"; my first drawing at 1.24 u wide still did, so the X is narrower now.) The layout adds the
0.6 u to the picture's width.

4.7 **One u per item.** Every block picture of an item (both stage pictures, all option tiles) draws with one u, the largest that fits
each picture in its box (today's `sharedUnit`, but applied to loose-only options too: the golden shows 19 pt loose cubes beside 7 pt rod
cubes). Capped at **22 pt on phones, 28 pt on tablets**, so a small number is not drawn larger than a big one on the next screen.

## 5. Layouts (for `TapAnswerSession.layoutFor` and `ActivitySpec`)

Numbers from `activity_shell.dart`. "Bottom" is the board height less the 24 pt no-hotspot band less the 8 pt Band C hit slop
(phone 361, SE 343, tablet landscape 788).

### 5.1 Layout S: blocks on the stage, numeral options (how many, lit rod, crossed, compare)

The stage takes all the height between the top bar and the tile row; the tile row goes as low as the bottom band allows.

| Board | Stage (x, y, w, h) | Tiles top (96 tall) | u | Was |
|---|---|---|---|---|
| Phone SE | 16, **80**, 270, **155** | **247** (was 214) | **13.9** (lit 13.2) | stage 104 tall |
| Phone | 71, **88**, 330, **165** | **265** (was 244) | **14.9** (lit 14.2) | stage 128 tall |
| Tablet landscape | unchanged (288, 230, 584, 300 card) | unchanged (554) | **24.9** (lit 23.7) | |
| Tablet portrait | unchanged (24, 372, 772, 300 card) | unchanged (696) | 24.9 (computed, not mocked) | |

- The stage top is the top bar's height (`layout.phone.topBar.height` 88, `phoneSE` 80); the eye and hint pebbles end at 76 and 72.
- Inside the stage: a margin of 6, the blocks centred and standing on the grass (bottom-aligned).
- **Up to 99 fits on every board.** u is set by the height (ten cubes): 98 needs 16.75 u of width, 233 pt on SE at 13.9, and SE has
  258.
- **Two pictures (compare)**: two cells 16 apart, each on its own white mat (60 %, radius 16), first number on the left. Each number is
  at most 4 tens with more than 5 ones, or 5 tens with 5 or fewer (on SE a cell is 121 wide; 89 against 98 would need u = 7). A bigger
  comparison needs another representation (curriculum).
- Option (owner's choice, not mocked): numeral tiles 80 tall instead of 96 under a block picture on phones (Band C phone minimum is 64)
  give the stage 16 more: u 16.4 on the phone, 15.4 on SE.

### 5.2 Layout T: blocks on the option tiles, nothing on the stage (where is 34)

The stage is not drawn; the tiles take its height, from 12 below the bubble to the bottom.

| Board | Bubble top | Tiles (3 options) | u |
|---|---|---|---|
| Phone SE | **86** (was 92) | top = bubble bottom + 12 (189 for two lines), bottom 343, 136 wide | **13.2** |
| Phone | **96** (was 104) | top = bubble bottom + 12 (212 for two lines), bottom 361, 154 wide | **12.7** |
| Tablet landscape | unchanged | the card's room: 288 to 872, top 230, bottom 788, 170 wide | **19.1** |
| Tablet portrait | unchanged | 24 to 796, top 372, 233 wide | 26.9 (computed) |

- The tile is as tall as its blocks need (10.3 u + 18), every option the same size; on phones it stands on the bottom line, on tablets
  it is centred in the card's room (there the width, 170, sets u).
- The bubble moves up 8 (phone) or 6 (SE) to the old stage's top line; its tail still meets Nitzi's mouth (to check, B-34).
- **Load-bearing limits** (else u falls under 12): the prompt fits **two lines** in the phone bubble (190 at 26 pt) and the SE bubble
  (176 at 22 pt); at most **3 options**; each option at most **4 tens** (SE: 1.5 T + 3.3 cubes wide in a 118 pt box). With **2 options**
  up to 8 tens fit. A "where is" item with bigger numbers uses Layout S the other way round (the curriculum's call).
- Phone T (12.7) is under the 14 target but over the floor; that is the honest maximum with the guide and bubble where they are. The ones
  are the cubes a child counts there (at most 9, in the 5-frame), and the rod is counted with the child (section 6).

### 5.3 A check, so no item ships below the floor

`tools/check_maths.py` (or the pack validator) computes u for every block item on phone SE, phone and tablet with these layouts and fails
an item under 12 pt; a widget test asserts `BaseTenLayout.unit >= 12` on SE for every C1 block item.

## 6. Making "a rod is ten" visible: the demonstration and the hints

See `demo_snap_phone.png` (five frames on the phone stage).

1. Ten loose cubes in the 2 by 5 frame (0.6 s).
2. Counted aloud 1 to 10, each cube lights (a spark glow) as its number is said, about 0.5 s each; the numeral drawn by the app above.
3. They glide into one column (stagger 40 ms, 500 ms ease-out).
4. **Snap**: the gaps close (120 ms), one soft click, a ring of light for 400 ms.
5. "Ten cubes are one rod" (line to be written), the rod and a "10" tile; then the rod slides left and the first item begins.

About 9 s. When: at the opening of each C1 lesson with blocks for the child's first three such lessons, then a 2 s version (steps 3 to
4 only, no counting). The same demonstration is the "show me" (eye) of a rod item. **Reduce motion**: the cubes light 1 to 10 in place,
then a 300 ms cross-fade to the rod. Nothing timed for the child, no speed language.

The reverse, a rod breaking into ten loose cubes, is the hint picture for "how much is the rod worth" and for taking away. Hint level 3
of a rod item counts the rod's cubes with the child: each cube of the rod lights in turn while the voice counts 1 to 10 (possible because
each cube is at least 12 pt and has its own edge).

## 7. The two alternatives, at the same scale

`alternatives_phoneSE.png` (Layout S on phone SE, 34 and 98) and `alternatives_options_phoneSE.png` (Layout T on SE, the 34 options).

| Model | 34 on the SE stage | 98 on the SE stage | 34 as options (SE) | For it | Against it |
|---|---|---|---|---|---|
| **Rods of ten cubes** (recommended) | cube 13.9 | cube 13.9 | cube 13.2 | the digits' order (3 rods then 4 cubes = 34); the same cube as the ones; the ones in a 5-frame; grows into the flat of 100 (C2); what the C1 items, hints and lines already say (כׇּל מוֹט הוּא עֶשֶׂר קֻבִּיּוֹת) | a rod is "pregrouped": the demonstration has to show it being made |
| Bundles of ten sticks with a band | stick 5.5 wide | **stick 1.9 wide** | **stick 2.0 wide** | groupable, a classroom favourite; the band is a clear "this is a ten" | ten sticks side by side are 11 stick widths, so 9 bundles do not fit a phone; sticks in a bundle touch, so they cannot be counted; fails the floor at 98 and as options |
| Ten-frames (each ten a full frame) | cell 24, dot 17 | cell 14.2, dot 10.2 | cell 10.7 | known from Band B; the five-structure; compact (a ten is 5 by 2, not 1 by 10), so large at small numbers | the frames are read in rows, not as tens then ones, so 34 does not look like "3 then 4"; a full frame is a box holding ten, not one thing you can count as one; options fall under the floor (10.7); the dots are smaller than the cells |

**Recommendation: rods of ten linked cubes.** They are the only model that keeps the place-value order of the digits, fits 98 on the
smallest phone at a countable size, and matches the items and lines already written. The two strengths of the others are taken into it:
the groupable "ten ones make a ten" (bundles) becomes the snap demonstration, and the five-structure (ten-frames) becomes the 2 by 5
frame of the ones. Van de Walle's teaching text (*Elementary and Middle School Mathematics*, the place-value chapter) distinguishes
groupable models (sticks, linking cubes) from pregrouped ones (base-ten pieces) and advises that the pregrouped rod only means ten to a
child who has seen ten ones become it ([a chapter summary](https://sites.google.com/view/brown2024/book/chapters-9-10/chapter-10); I
could not open the book itself, so this is a paraphrase to be confirmed by the curriculum-expert). Drawing the rod as linked cubes and
showing the snap is how a pregrouped picture borrows that.

## 8. What changes per device (summary)

| | Phone SE | Phone | Tablet landscape | Tablet portrait |
|---|---|---|---|---|
| Layout S stage | 270 x 155 at y 80 | 330 x 165 at y 88 | card unchanged | card unchanged |
| Layout S tiles top | 247 | 265 | 554 | 696 |
| Layout S u | 13.9 | 14.9 | 24.9 | 24.9 |
| Layout T bubble top | 86 | 96 | unchanged | unchanged |
| Layout T u | 13.2 | 12.7 | 19.1 | 26.9 |
| u cap | 22 | 22 | 28 | 28 |

## 9. For the owner

Open these at real size (on the phone in landscape, full screen, the board part is 1:1 for an 852-wide phone; on a monitor everything is
about 1.7 times larger than on the phone):

- `docs/design/c1-blocks/phone_where34.png`, `phoneSE_where34.png`, `tabletL_where34.png`
- `docs/design/c1-blocks/phone_howmany34.png`, `phoneSE_howmany34.png`, `tabletL_howmany34.png`
- `docs/design/c1-blocks/phone_howmany98.png`, `phoneSE_howmany98.png`, `tabletL_howmany98.png` (the worst case)
- `docs/design/c1-blocks/phone_compare41_39.png`, `phoneSE_compare41_39.png`, `tabletL_compare41_39.png`
- `docs/design/c1-blocks/phone_litrod.png`, `phoneSE_litrod.png`, `tabletL_litrod.png`
- `docs/design/c1-blocks/phone_crossed.png`, `phoneSE_crossed.png`, `tabletL_crossed.png`
- `docs/design/c1-blocks/cube_closeup.png`, `demo_snap_phone.png`, `alternatives_phoneSE.png`, `alternatives_options_phoneSE.png`

Decisions: (1) rods of linked cubes (recommended) or another model; (2) colourway "sea" (recommended) or "spark"; (3) the opening
demonstration; (4) optional 80-tall numeral tiles under a block picture on phones (+1.5 pt).
