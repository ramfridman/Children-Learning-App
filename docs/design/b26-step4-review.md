# B-26 step 4: design review of the built home screen (design-director, 2026-10-30)

Reviewed: `HomeIslandScreen` as wired in the worktree `D:\nitznutz-b26` (branch `b26-nitzi-home`, uncommitted on top of
9c71110), against `docs/design/nitzi-home.md` (sections 2 to 6) and `docs/design/nitzi-home-references.md`.

**Looked at**
- The six new goldens `app/test/goldens/home_island_{phone,phone_se,tablet_landscape,tablet_portrait}.png` and
  `home_island_long_name_1.3_{phone_se,tablet_portrait}.png`.
- The changed map goldens `home_phone`, `home_phone_se`, `home_tablet_landscape`, `home_sign_alexandra_phone_se`,
  `companion_home_hero_phone`, each beside its HEAD version (`git show HEAD:...`).
- My own renders at 2x through the real app (`AppRig`, the real companion, a waiting trophy, a later sticker), from a
  throwaway test in the scratchpad (`review_render_test.dart`, not in the repo): נֹעָה at text scale 1.0 and 1.3 with
  something waiting in the Hall, 24 x ש at 1.0 and 1.3, "Alexandra Massimiliano" at 1.3, the map sign with the trophy
  badge, and the bottle at both ends of its bob (motion on), on all four boards; plus crops of the lantern, the badge,
  the Latin bubble and the titles. Then the same renders again after my art fix (section 4).
- Not looked at: the real phone or tablet (the owner can), TalkBack, the entry wave in motion (the goldens are taken with
  reduce motion), dark sea at night (there is none), the phone map at text scale 1.3 (it overflows before the home opens:
  QA-19, known, see D-8).

## 1. Per board

### Phone (852 x 393)
- **Hierarchy**: right to left the eye meets the back pebble, the title, then the bottle (biggest warm object at the
  start side, beside the friend's waving hand), the friend in its door, the book, the lighthouse. One obvious next step:
  the bottle. Good.
- **The friend's place**: standing on the porch in front of the arched door, the house behind it is the map's house close
  up; a child recognises "my island". Good.
- **Objects readable**: the tower (bands, gallery, lantern), the upright blue album with the sticker on its cover, the
  bottle with the rolled letter: three different shapes, none needs colour or reading. Labels sit centred under each,
  14 bold, nikud whole.
- **Title**: `הָאִי שֶׁל נֹעָה` on the wooden card, glyph on the start side, 22 pt, one line. 24 x ש at 1.3: 19 pt, one
  line, card 646.6 wide, clear of the back pebble.
- **Bubble**: two lines at 1.0 and 1.3, 16 inside the edge; its tail points left at the roof, about 80 pt above the
  friend's mouth (D-4). The friend is the only speaker on the screen, so the child still knows who talks.
- **Something waits**: the gold trophy in the lantern window in a warm halo reads at once, also at the phone's lantern
  size (trophy about 27 pt wide). It is a little larger than the window (D-6).
- **Nothing cut or crowded**: nothing clipped; before my fix a bush peeked over the bubble's top edge and the bottle's
  label sat on a patch of wet sand with a foam line through its letters' feet (fixed, section 4).
- **RTL**: right. Nothing on this screen is LTR; a Latin name sits in an isolate ("Alexandra Massimiliano" whole in the
  title; "Alexandra…" in the bubble with its "…" on the name's right, the step 3b rule).
- **Calm**: yes. No numbers, no timers, nothing blinking; the bob is slow and small.

### PhoneSE (667 x 375)
- Same order and reading as the phone; nothing overlaps at 1.0. At 1.3 the labels are lifted 4 pt into their objects'
  bottom edge (note 1) and the bottle's label comes within about 3 pt of the porch's bottom-right corner (D-7, cosmetic).
- Title: 20 pt one line for נֹעָה; 24 x ש takes two lines at 18 (1.0) and 15 (1.3): line 1 `הָאִי שֶׁל`, line 2 the
  whole name, glyph centred on the card; card 452.2 x 72 at 1.3 (designed 452.2 x 72.3).
- Bubble at 1.3: two lines, name shortened to `שששששש…`, ends 4 pt above the bottle's tap area, about 50 pt above the
  drawn glass (note 2).
- Before my fix the bubble covered a bush, a flower clump and a tuft; now it covers only roof and sea.

### Tablet landscape (1180 x 820)
- The most open board: big objects, labels at 18, wide gaps. The bubble reaches over the friend's tap area (by design: it
  ignores touches, a tap reaches the friend) without covering its face.
- Title 28 pt one line; 24 x ש at 1.3 is 27 pt, one line, card 915.8 wide.
- Before my fix a bush peeked over the bubble's top and a pink clump showed under it at 1.3; the bottle's foam line ran
  under its label. Fixed.

### Tablet portrait (820 x 1180)
- Upper half: lighthouse, house, friend; the beach row (book, bottle) at the thumbs, as designed. Reads well.
- 24 x ש at 1.3: title two lines at 18 (frame / whole name), card 550.6 x 86; the welcome takes three lines (note 3).
- Before my fix the three-line bubble hid the palm's crown (only frond tips showed under it), a pink clump peeked over
  the bubble, and a bush touched the "גְּבִיעִים" label. Fixed: the palm stands lower on the sand (base 716, 742; crown
  548), the bush moved under the label's band, the clump and a tuft were removed.

### The map (changed goldens)
- The top is calmer: the trophy and sticker pebbles and the dead yellow book button are gone; avatar, pill, Parents stay.
- The sign with something waiting: the glow, the trophy badge on its top-start corner (over the border, no extra width),
  readable on both phones. The badge has no ring (note 4).
- `companion_home_hero_phone`: only the pebbles left; the fixture's dark square companion is the test's stand-in.

### For the parent
The title shows the child's whole name as typed (never cut), the Latin name whole and in reading order; nothing on the
screen asks the parent for anything; the screen keeps the "no parent button in the home" decision.

## 2. The six developer notes

| # | Note | Verdict |
|---|---|---|
| 1 | SE at 1.3: labels would end at 355, past the bottom-24 band at 351, so they are lifted 4 pt into their object's bottom edge | **Accept.** Only the SE at 1.3; the 4 pt fall on the objects' own ground (rocks, stump foot, wet sand), the text stays legible, and the band rule is kept. Smaller labels would hurt more than a 4 pt overlap. |
| 2 | SE two-line welcome at 1.3 ends 4 pt above the bottle's tap area | **Accept.** The bubble ignores touches, so 4 pt is only visual, and the drawn glass is about 50 pt lower. |
| 3 | Tablets at larger text scales: the welcome may take a third line (still at least 16 above the bottle) to keep more of the name; always two lines at 1.0 | **Accept.** A longer part of the child's own name is worth a third line where there is room; seen at 1.3 portrait with 24 x ש: clear of the friend's face and the bottle. The orphan last word ("הַבַּיְתָה.") is fine for this text. My art no longer puts anything under the three-line box (section 4). Please write this into `nitzi-home.md` section 3 as the rule (I did not change the bubble line there beyond the art note). |
| 4 | The sign's trophy badge has no border (spec: a paper disc) | **Accept.** A paper disc does not need a ring; the trophy's dark base and gold cup are the shape cue and they read on the glow, on sand and over the friend's foot. Optional polish (D-5): a 1.5 to 2 pt ink ring would echo the sign's border and lift the disc off the pale glow. |
| 5 | The bottle bobs ±4 and ±3° every 2.4 s, still with reduce motion | **Accept.** Matches section 5; checked at 600 ms and 1800 ms and in the reduce-motion goldens. One art defect found with it: the bottle picture carried its own wet sand and shell, so the sand bobbed with the bottle. Fixed in the art (section 4); no code change. |
| 6 | Title card per section 3.1 (widths within 3 pt, heights within 0.5 pt per line) | **Accept.** Measured in my renders: phone 646.6 x 48, SE 452.2 x 72, landscape 915.8 x 66, portrait 550.6 x 86 at 1.3 (designed 646.6 x 48.0, 452.2 x 72.3, 915.5 x 65.7, 550.6 x 85.6). The name is never broken inside the word in the goldens, but see D-1. |

## 3. Defects

| Id | Severity | What | Owner |
|---|---|---|---|
| D-1 | **major if real** (unconfirmed) | In one scratch run that pumps many app instances in one test file and raises the text scale to 1.3 **after** the home is open, the title's fit and the painted text disagreed: the fit kept the base size (phone 22, SE 20, landscape 28, portrait 28) while the text was painted at 1.3, so the card took two lines and on SE and portrait the 24 x ש name was **broken between its letters** (`fitIslandTitle` chose a size that does not fit at 1.3). Reproduced twice in that full file; **not** reproduced when the same tests run alone, nor with `HomeIslandScreen` pumped directly and the scale changed live. So it may be a test-binding leak, but a parent who changes the system text size while the child is on the home would hit the same path. | qa-engineer to reproduce (open the home, then change the text scale; assert size, lines and the name on its own line); app-developer to fix if it reproduces |
| D-2 | minor (fixed, art) | Scene decorations under the bubble's box: a bush peeked over the bubble's top edge (phone, landscape), flower clumps peeked over or under it (portrait, landscape at 1.3), the portrait palm's crown hid behind the three-line bubble at 1.3. | design-director, **fixed** |
| D-3 | minor (fixed, art) | The bottle's label stood on a patch of wet sand with a foam line through its letters' feet on every board, while the bottle lay on dry sand above it; and the bottle picture's own wet sand and shell bobbed with the bottle. Now the ground is drawn by the scene exactly under the resting bottle, the foam edge ends above the label (phone 330 vs label 336, SE 317 vs 324, tablets 674 / 954 vs 680 / 960), and only the glass moves. Also on portrait a bush touched the "גְּבִיעִים" label: moved. | design-director, **fixed** |
| D-4 | minor | The bubble's tail points straight left at the roof, about 80 pt above the friend's mouth (phone; similar on all boards). Proposal: `BoardBubble` gets a tail position option (`tailCorner: bottomStart`, the same 22 pt rotated square placed at the bubble's bottom-left corner, offset 24 from the left edge and 8 below the bottom, so it points down-left at the friend's head); the home uses it on all four boards. No size or place of the bubble changes. Golden update: the four `home_island_*` and the two long-name goldens. | app-developer (component option), design-director (look at the renders after). **Follow-up 2026-10-30:** the corner nub was built and is in the six regenerated goldens. It is an 8 pt point aimed straight down at the roof or window (white on the pale wall on portrait), 108 to 163 pt from the mouth. Decision (c): a tapered wedge to a tip beside the friend's head; exact numbers in `nitzi-home.md` section 3 ("Bubble tail"). The bubble does not move. |
| D-5 | cosmetic | The map sign's trophy badge has no ring; on the pale glow its white edge is soft (contrast is carried by the trophy). Optional: a 1.5 to 2 pt `TokenColors.ink` border on the disc. | app-developer, only if the owner likes it |
| D-6 | cosmetic | The lantern trophy is 24 wide and so 28 high in a window 24 high (my spec's numbers: "0.8 of the width" did not check the height); it overlaps the window frame 2 pt top and bottom and sits in front of the bars. It still reads as "a trophy up there", and larger is better on the phone, so **keep it**; I note it so nobody "fixes" it by shrinking. | design-director (spec note), no change |
| D-7 | cosmetic | SE at 1.3: the bottle's label's first letters come within about 3 pt of the porch's bottom-right corner (scene art, not a tap area). Leave until the illustrator's scene. | design-director, later (P9) |
| D-8 | known, outside this step | On the phone at text scale 1.3 the map's daily pill overflows 9.8 pt (QA-19, board B-27), so the home cannot be reached at 1.3 in a test without opening it first at 1.0. | app-developer (QA-19) |
| D-9 | observation | The back pebble (`home_palm.svg`) and the title's glyph (`land_nitzi.svg`) are both a palm on an island, so on this one screen "back to the map" and "this is my island" share a picture. Kept on purpose (the same back pebble in the same corner on every screen, spec section 3); worth watching when the children use it: if they tap the back pebble expecting "home", consider a map glyph for the back pebble on every child screen. | owner's eye, later |

No Hebrew defect found: every text fits, nikud whole at 2x, no word broken (D-1 aside). Nothing for the
hebrew-text-editor from this review.

## 4. What I changed (art only)

`tools/make_nitzi_home.py` (my generator; deterministic, run twice, same bytes) and the five files it writes:
- `app/assets/art/home/bottle_big.svg`: glass only (no wet sand, shadow or shell).
- `app/assets/art/scenes/nitzi_home_{phone,phone_se,tablet_landscape,tablet_portrait}.svg`: a new `bottle_ground(rect)`
  draws the wet sand with its foam edge, the shadow and the shell under the bottle's resting place (from the tap area,
  `BoxFit.contain`, standing on the bottom edge); the old `wet` patches are gone; decorations out of the bubble's box
  (phone: bush 612,118, flowers 600,150 and tuft 560,120 removed, tuft 720,180 moved to 800,236; SE: bush, flowers and
  tuft 440,120 removed; landscape: bush 960,300, flowers 930,420 and 1010,330, tufts 1000,470 and 1080,400 removed;
  portrait: flowers 650,300 and tuft 690,340 removed, palm 706,690 -> 734,440 now 716,742 -> 730,548, bush 660,600 now
  645,655, bush 180,690 now 196,736, gold flowers 240,700 now 262,708).
- `docs/design/nitzi-home.md` section 3 (drawing the objects) and section 6 (the bottle's row) say so.

No app file, test or golden was touched. **The six `home_island_*` goldens are now stale** (the scenes and the bottle
changed); the map goldens are not affected (the map art did not change).

## 5. Final vs placeholder

- **Final**: the layout (tap areas, gaps, label rule, bubble boxes, the title rule and its card), the reading order, the
  file names and ids (`assets/art/home/*.svg`, `assets/art/scenes/nitzi_home_*.svg`), the overlays' positions in each
  picture's own coordinates, the motion (wave, bob, squash, static halo).
- **Placeholder** (mine, drawn from references, until the illustrator, to-do P9): the four island scenes, the lighthouse,
  the bottle, the sticker book. Reused placeholders: the companion's rig art, `home_palm.svg`, `land_nitzi.svg`,
  `trophy_gold.svg`, the sticker set. Real art drops in by file name; the illustrator must keep the lantern window at
  x 35..65, y 36..60 of 100 x 220, the cover panel at x 33..63, y 19..49 of 100 x 100, and the bottle standing on its
  picture's bottom edge with its ground left to the scene.
