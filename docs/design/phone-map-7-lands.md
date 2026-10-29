# B-23: all 7 lands on the home map (phone, phone SE, tablet portrait)

Status: **ART DONE, SPEC FINAL, ready to wire** (2026-10-29). Owner's decision 2026-10-29: Option A (a strip that pans
sideways) on phone and phoneSE, and the tablet portrait map in the same item (a taller scene that scrolls vertically,
Market Village at the top). Tablet landscape is unchanged (its scene and golden must not change).
Owner of this doc: design-director. Board item: B-23. Wiring: app-developer. Goldens: qa-engineer.

## 1. What was wrong

| Board class | Board | Signs on the map before | Missing |
|---|---|---|---|
| phone (board 10) | 852 x 393 | nitzi, counting, colors (half cut) | shapes, logic, robots, market |
| phoneSE (board 12) | 667 x 375 | counting, nitzi | colors, shapes, logic, robots, market |
| tabletLandscape (board 22) | 1180 x 820 | all 7 | none |
| tabletPortrait (board 25) | 820 x 1180 | 6 | market |

The spec already asked for this: design-spec §5.3 (the map pans horizontally on phones), §7.4 (about 2.5 lands visible,
edge peeks hint at more), §7.3 (portrait scrolls vertically), §3.2 and §8 (progress runs right to left, home island at the
right, new lands unfold leftwards), §6.2 (Band A may pan the map).

Option B (two rows, no scrolling) was rejected: islands shrink to about 150 x 70 and the §3.3 growth objects, stars and
help flags become specks. A vertically scrolling phone map and paging arrows were rejected too (see the git history of
this file for the full comparison).

## 2. The scenes (drawn, `tools/make_home_map.py`)

| File | viewBox | What |
|---|---|---|
| `app/assets/art/scenes/home_phone.svg` | `0 0 2102 393` | phone world strip, 7 islands, home at the right end |
| `app/assets/art/scenes/home_phone_se.svg` | `0 0 1834 375` | SE world strip |
| `app/assets/art/scenes/home_tablet_portrait.svg` | `0 0 820 1580` | portrait scene, board 25 moved down 400, Market Village on top |
| `app/assets/art/scenes/home_tablet_landscape.svg` | `0 0 1180 820` | **unchanged** |

`BoardSvg` draws with `BoxFit.contain`, so each scene must be given exactly its viewBox size (`worldWidth` x board height
on phones, 820 x `worldHeight` on portrait), or it is squeezed.

The approved art is kept exactly: the generator copies boards 10, 12 and 25 element for element from frozen copies in
`tools/home_map_src/` (the files the app shipped before B-23) and only moves them (phone +1250 x, SE +1167 x, portrait
+400 y; checked: the copied block is byte-identical inside the new files). The waves are redrawn over the whole scene on
the boards' own 120 x 38 grid in the same phase, so the waves in each start view are the same set as on the approved board
(checked) and the new sea joins without a seam. The generator is deterministic (two runs, same bytes).

Island centres (sand centre, world points), for the illustrator and the tests:

| land | phone | phoneSE | tablet portrait |
|---|---|---|---|
| nitzi | 1890, 262 | 1687, 258 | 600, 1400 |
| counting | 1610, 262 | 1435, 258 | 260, 1300 |
| colors | 1320, 262 | 1189, 258 | 600, 1140 |
| shapes | 1040, 248 | 937, 244 | 230, 960 |
| logic | 760, 262 | 685, 258 | 600, 760 |
| robots | 480, 248 | 433, 244 | 300, 630 |
| market | 200, 262 | 181, 258 | 560, 270 |

The four new islands (our own drawings from real references, sources in the generator's header; hosts are the cast's own
pictures at 0.1 like the hosts already on the boards):

- **Shape Forest** (Kubi): two cypress spires (cones), a clipped sphere bush mirrored in a small pond, a limestone cube.
- **Riddle Grotto** (Timi): a pale chalk headland with soft layers and a round-topped arch onto blue water (Rosh HaNikra),
  boulders at its foot, a row of shells in a pattern pink-gold-pink-gold-pink.
- **Robot Harbour** (Tza'adon): a blue gantry crane with a trolley and a hanging box (Port of Haifa), a 3-2-1 stack of
  containers, a plank pier.
- **Market Village** (Grandma Pnina): a stall with a scalloped striped awning and heaps of round fruit in colour blocks
  (Carmel / Mahane Yehuda), and a three-tier honey limestone clock tower (Jaffa) with a clock that has hands only.

No text or numerals inside any picture, no franchise look, no real person.

## 3. Phone and phoneSE: the strip

### 3.1 What scrolls and what stays

| Fixed (board coordinates, exactly as today) | Scrolls with the strip (world coordinates) |
|---|---|
| avatar, stickers / hall / stars row under it | scene SVG |
| book + Parents | the 7 signs and their 7 tap areas |
| Today's Adventure pill | companion, its "+" pebble, the speech bubble |

### 3.2 Scroll behaviour

- Horizontal, one finger, inertia, `BouncingScrollPhysics`. No snapping, no auto-scroll, no nudge animation, no timer.
- Start: the right end of the strip (home island). Under the app's RTL `Directionality` a horizontal scroll view starts at
  its right end, so offset 0 is the start view; do not set `reverse`.
- `PageStorageKey('home-map')`: coming back from a land shows where the child was; a cold start shows home.
- A drag that starts on a sign or tap area pans and does not open the land; a still tap opens it.
- The start view is today's board plus the full Colour Bay sign (it was cut): the half island and the path off the left
  edge are the "more this way" cue (§7.4).

### 3.3 Numbers

`_Sign(land, left, top)`, all `centred: true` (the non-centred phone sign goes away). Tap area of a land: `left -
tapWidth/2`, `top - 150`, `tapWidth` x 160 (as today, only the width is per board).

**phone**: viewport 852 x 393, `worldWidth` **2102**, start view = world x 1250..2102, `tapWidth` **240** (gaps 40).

| land | left | top | x on screen at start | x on screen panned fully left |
|---|---|---|---|---|
| nitzi | 1890 | 320 | 640 (as today) | off |
| counting | 1610 | 320 | 360 (as today) | off |
| colors | 1320 | 320 | 70 (half island peek) | off |
| shapes | 1040 | 320 | off | off |
| logic | 760 | 320 | off | 760 |
| robots | 480 | 320 | off | 480 |
| market | 200 | 320 | off | 200 |

**phoneSE**: viewport 667 x 375, `worldWidth` **1834**, start view = world x 1167..1834, `tapWidth` **220** (Counting and
Colour Bay are 246 apart on the approved board 12, so 220 keeps the gap at 26; every other gap is 32).

| land | left | top | x on screen at start | x on screen panned fully left |
|---|---|---|---|---|
| nitzi | 1687 | 314 | 520 (as today) | off |
| counting | 1435 | 314 | 268 (as today) | off |
| colors | 1189 | 314 | 22 (half island and half sign peek) | off |
| shapes | 937 | 314 | off | off |
| logic | 685 | 314 | off | 685 (half, peek) |
| robots | 433 | 314 | off | 433 |
| market | 181 | 314 | off | 181 |

All sign tops are level (320 / 314) although the new islands alternate high and low in the art: a level row keeps every
tap area 20 points or more below the fixed stickers pebbles when the strip passes under them.

**Companion, "+", bubble** (world coordinates):

| | phone | phoneSE |
|---|---|---|
| `companionLeft`, `companionTop` (153.6 square) | 1859, 154 | 1651, 164.6 |
| "+" pebble 48 (`plusLeft`, `plusTop`), new fields | **1990, 268** (was 1972.6, 259.6) | **1776, 256** (was 1764.6, 270.2) |
| bubble | **at the board place**: `right` 212 from the world's right edge, `top` 112 | **at the board place**: `right` 154, `top` 112 (was 140 / 118) |

Why (the M9 audit note "the + overlaps Nitzi's island and the bubble covers its landmark"): beside the mouth, the bubble
covered Nitzi's palm, which is the island's glyph on its sign; at the board's own place (board 10, approved) it sits in
the open sea above the islands, 28 below the pill and clear of the stickers. The "+" moved off the lighthouse base and
onto the sand rim at the companion's feet, 25 from the Nitzi sign on the phone. On the SE it is 19 from the Nitzi sign
horizontally and 10 above it (about 21 corner to corner) and 10 from the screen edge: that corner is the tightest place on
the SE; it was 7 before. The tail of the bubble keeps today's shape (right side), as on board 10.

## 4. Tablet portrait: the tall scene

- Scene 820 x **1580** (`worldHeight` 1580 = 1180 + 400). Board 25 is moved down 400; Market Village is drawn in the new
  band at the top, with the dotted path from Robot Harbour up to it, a boat, clouds, gulls.
- Vertical scroll, one finger, inertia, `BouncingScrollPhysics`, `PageStorageKey('home-map')`. **Start at the bottom**
  (home): set `reverse: true` on the vertical `SingleChildScrollView`, so offset 0 shows world y 400..1580, which is
  exactly today's board 25 (only the path rising off the top edge is new: that is the cue to scroll up).
- Fixed vs scrolling layers: the same split as the phone (avatar, stickers row, book + Parents, pill fixed).
- Scrolled fully up, the market tower's gold ball (world y about 164) sits about 34 below the pill's lip; the market tap
  area (440..680 x 206..366) is 12 left of the stickers row and 36 below its pebbles.

| land | left | top (world) | top on screen at start |
|---|---|---|---|
| nitzi | 600 | 1510 | 1110 (as today) |
| counting | 260 | 1396 | 996 |
| colors | 600 | 1230 | 830 |
| shapes | 230 | 1054 | 654 |
| logic | 600 | 848 | 448 |
| robots | 300 | 716 | 316 |
| market | 560 | 356 | off (above) |

`tapWidth` 240 (gaps 60). Companion `companionLeft` 590, `companionTop` **1289.2** (889.2 + 400). "+" and bubble: as today,
moved down 400 ("+" 703.6, 1394.8; bubble beside the mouth, measured from `worldWidth` / `worldHeight`). The portrait
bubble still covers Nitzi's palm and house as before: there is no free sea beside the companion on that board without
moving islands the owner approved; left for the illustrator's map (open item).

## 5. Tablet landscape

Unchanged: `worldWidth` 1180, `worldHeight` 820, no scroll view needed (or a scroll view whose child is exactly the board,
which cannot move), signs, companion, "+" and bubble exactly as today. Its golden must not change.

## 6. Accessibility

- Each sign keeps `Semantics(label: land name)`; each tap area gets `Semantics(button: true, label: land.label.text)`,
  so a screen reader reaches lands that are off screen (the scroll view exposes its scroll actions). The "+" keeps
  `He.friendsSemantics`. The scene keeps `He.homeMapSemantics`. No new Hebrew string.
- Colour is never the cue: each land keeps its own silhouette, landmark, host and glyph (§3.2, §9.2).
- Nothing moves by itself; reduce-motion has nothing to switch off.

## 7. Previews I rendered and looked at

`docs/design/previews/` (headless Chrome, Heebo from `app/assets/fonts`; the fixed buttons are stand-in shapes, the pill
text wraps on the SE only because my stand-in pill is narrower than the real one):
`home_phone_start.png`, `home_phone_end.png`, `home_phone_strip.png` (tap areas dashed), `home_phoneSE_start.png`,
`home_phoneSE_end.png`, `home_phoneSE_strip.png`, `home_tabletPortrait_start.png`, `home_tabletPortrait_top.png`,
`home_tabletPortrait_full.png`, and the four new islands at 2x: `new_islands_2x_a.png` (market, harbour),
`new_islands_2x_b.png` (grotto, forest). These are previews, not goldens: the real check is the Flutter goldens after the
wiring.

## 8. Hand-offs

**app-developer** (`app/lib/child/home_screen.dart`; do not change the SVGs):
1. `_HomeSpec`: add `worldWidth`, `worldHeight`, `scrollAxis` (`Axis.horizontal` phone/SE, `Axis.vertical` portrait,
   none for landscape), `tapWidth`, `plusLeft`, `plusTop`, `bubbleAtBoardPlace` (true phone/SE, false tablets).
   Values: phone 2102 / 393 / horizontal / 240 / 1990 / 268 / true; SE 1834 / 375 / horizontal / 220 / 1776 / 256 / true
   (and `bubbleRight` 154, `bubbleTop` 112); landscape 1180 / 820 / none / 240 / 1088.6 / 556 / false (today's
   companion + 113.6, + 105.6); portrait 820 / 1580 / vertical / 240 / 703.6 / 1394.8 / false.
2. Signs and companion from sections 3.3 and 4 (portrait signs and companion +400; all phone signs `centred: true`).
3. `build()`: inside the existing `BoardCanvas`, a world layer `Positioned.fill(SingleChildScrollView(key:
   PageStorageKey('home-map'), scrollDirection: scrollAxis, reverse: scrollAxis == Axis.vertical, physics:
   BouncingScrollPhysics(), child: SizedBox(worldWidth, worldHeight, Stack(scene BoardSvg sized worldWidth x
   worldHeight, tap areas, signs, companion, "+", bubble))))`, then the fixed layer (avatar, stickers row, book +
   Parents, pill) on top. Paint order inside the world: scene, tap areas, signs, **then** companion, "+", bubble, so a
   future Nitzi tap area never swallows taps on the companion or the "+".
4. `_bubble()`: when `bubbleAtBoardPlace`, `Positioned(right: bubbleRight, top: bubbleTop)` in world coordinates;
   otherwise today's mouth rule with `right: worldWidth - rightEdge`, `bottom: worldHeight - bottomEdge`.
5. Tap areas: width `tapWidth`, `Semantics(button: true, label: land.label.text)`.
6. Tests (`board_geometry_test.dart`): replace "three signs", "board 12 shows two lands" and "board 25 has six lands" with:
   all 7 `sign-<land>` exist on phone, SE and portrait; start views put nitzi and counting where the table says; after a
   full pan / scroll the avatar, pill, book and Parents rects are unchanged; land tap areas >= 64 wide and >= 24 apart
   on phone and SE; landscape numbers unchanged.

**qa-engineer** (after the wiring):
- Update: `home_phone.png`, `home_phone_se.png` (Colour Bay sign, bubble, "+"), `home_tablet_portrait.png` (path off the
  top), `companion_home_hero_phone.png`, and any other golden that shows the phone home (`companion_friends_phone.png`,
  `hall_friend_phone.png` if it does): look at each diff, nothing but those changes is expected.
- Add: `home_phone_end.png`, `home_phone_se_end.png` (panned fully left), `home_tablet_portrait_top.png` (scrolled up).
- Must stay byte-identical: `home_tablet_landscape.png`.
- For each board class and each of the 7 lands: from home, bring `land-tap-<land>` into view (`ensureVisible` or a drag),
  tap it, expect that land's island screen with the real pack. A drag starting on a sign must not open the land.
- Until the wiring lands, the current home goldens fail on phone, SE and portrait (the SVGs are already the new size).

**Needs the owner**: open `docs/design/previews/home_phone_end.png`, `new_islands_2x_a.png`, `new_islands_2x_b.png` and
`home_tabletPortrait_top.png`: are the four new lands what you imagined? The new islands are drawn with more detail than
the older tablet islands (the grotto is a chalk arch, not a grey dome; the market has a clock tower in tiers); tablet
landscape keeps its simpler versions unless you want them brought in line (a later item).
