# B-40: the visual hint ladder, design spec (step 2)

**Status:** a design for the owner's approval, with the curriculum plan `docs/curriculum/b40-visual-hint-ladder.md`. No app code has changed. Author: the design-director, 2026-10-30.
**Decided by the owner on 2026-10-30:** all seven questions of the plan, yes (picture at the first mistake; two-choice items one retry then the demo; the halo stays after the demo; no answer in hints 1 and 2; colours and shapes turn naming into matching at hint 2; one neutral pointing hand; Band A before the family release).
**The owner's requirement this spec is built to:** every hint is a picture a 3-year-old understands **with the sound off and without reading**. The spoken line goes along with the picture; it never carries the hint alone.

Mockups (phone 852 × 393, drawn on the approved frame; the bubbles are blank on purpose, to test "no sound"):

| File | What it shows |
|---|---|
| `docs/design/b40/b40_m0_shared_pictures.png` | The visual grammar and the 12 shared pictures P1 to P12 |
| `docs/design/b40/b40_m1_count_tap_fingers_tenframe.png` | count_tap: L1 light each, L2 two hands (7), L2 two ten-frames (13), L3 the hand counts |
| `docs/design/b40/b40_m2_tap_answer_count.png` | tap_answer, count a group (TA-1): all three levels, and the halo that stays |
| `docs/design/b40/b40_m3_colour_swatch.png` | tap_answer, colour naming (TA-6): look at each, the swatch, the swatch sticks |
| `docs/design/b40/b40_m4_number_line_jump.png` | number_line jump: start and hop size, the first hop, the three hops |
| `docs/design/b40/b40_m5_clock_hand.png` | clock_set: the short hand and the target, find the 3, the hand presses plus |
| `docs/design/b40/b40_m6_coins_grouping.png` | shop_pay: the price as places, the biggest coin, the coins one by one |
| `docs/design/b40/b40_m7_balance.png` | balance, hidden tilt: both piles, two towers on one floor, the beam is let go |

They are made by `docs/design/b40/make_b40_mockups.py` (headless Chrome; the top bar and the companion come from the golden `unit_colour_find_phone.png`, the activity pictures are the app's own sprites in `content/starter/`).

---

## 1. The visual grammar (one rule a child can learn)

Each level has its own look, the same in every activity, so the child learns what each kind of help means:

| Level | It looks like | It means | It never does |
|---|---|---|---|
| **L1 Look here** | A **sky glow** on parts of the question; the rest of the stage fades a little | "Look at this" | Glow, dim or move an answer option (tile, bin, coin, cell) |
| **L2 Another way / together** | A **sky hint card** with a new picture (hands, ten-frame, swatch, towers, empty places), or the guide does **one** step | "Here is another way to see it" | Show the final answer; make one option bigger or brighter |
| **L3 Watch me, then you** | The **sky pointing hand** runs the whole process; the answer appears **last**; then the turn comes back with a soft halo on the answer (owner Q3) | "Watch me, now you" | Skip the process and jump to the answer |

While any hint is showing, the hint pebble (the cloud with "?") wears a sky ring 5 pt wide, so the child connects the lamp with the help.

**Colour:** every hint mark is sky (`feedback.hintHalo` #8FD3F4 rings, `skyTint` #E3F4FC fills, `skyDeep` #5BB6E0 lines and the hand's outline). Nothing in a hint is red, and there is no green-against-red anywhere. Things already counted get a small `skyDeep` dot; things filled (coin places) turn `spark`, the same gold as success in the app. The not-yet lilac stays only for the wrong-tap wobble.

**Colour-blind safety:** every hint is also a shape or a motion (ring, card, line, hand, tower). The colour swatch carries its helper symbol (red = heart, design-spec §9.3).

---

## 2. Rules for every hint picture

### 2.1 Where it is drawn (never over the answers)

| Device | L1 | L2 | L3 |
|---|---|---|---|
| **Phone** (stage 330 × 128 at x 71, y 96; tiles below it at y 248) | Inside the stage only | **(a)** If the template has no tiles under the stage (count_tap, give_n, flash, trace) the hint card opens **in the free answer area** (max 320 × 112, its top 14 pt under the stage). **(b)** Otherwise it lives **inside the stage**: either a card at the stage's end side (left), up to 90 × 120, or the stage's own objects move into the new picture (they fly, so the child sees they are the same things). | The hand works in the stage; it enters the answer area only at the very end, its fingertip on the **top edge** of the answer tile (the body of the hand stays above the tile, never over its content), then leaves. |
| **Phone SE** (667 × 375) | Same, scaled with the stage height | Same; minimum sizes in §2.3 still hold; if a card does not fit at its minimum, the objects transform in place instead | Same |
| **Tablet landscape** (stage card about 552 × 268) | Inside the stage | The scene **stays** and the hint card stands **beside it** at the stage's end side (left), about 40% of the stage width, so the child sees the question and the new picture together | As phone, larger hand |
| **Tablet portrait** | Inside the stage | The card goes **under** the scene inside the stage (the stage is square-ish) | As phone |

Hard rules for the app:
1. No hint layer is hit-testable (`IgnorePointer`), so a hint never steals a tap from an answer.
2. Nothing of a hint is drawn over a tile's content before L3; at L3 only the hand's fingertip and the halo touch a tile.
3. Nothing of a hint enters the bottom 24 pt band, or the companion's rail.
4. A hint picture never changes the size, brightness or position of one answer option before the end of L3.

### 2.2 Motion (calm, slow, and still with reduce-motion)

| | Band A | Band B |
|---|---|---|
| One "light each" step (glow on, dwell) | 250 ms spring-out on, 700 ms dwell, then the next | 200 ms on, 550 ms dwell |
| An object flying into a new picture (L2) | 450 ms arc, 150 ms between objects | 350 ms arc, 120 ms between |
| The hand moving between targets (L3) | 450 ms arc; a 120 ms press (4 pt down, a sky ripple r 10 then 17 fading in 400 ms) | 350 ms; 100 ms press |
| Pace of a demo | One step per spoken word; the voice-and-sound-director gives word onsets; at most 8 s in all | At most 10 s |

- Easing from `motion.easing` (springOut for arrivals, standard for moves). Nothing pulses faster than 1 Hz (the token limit is 3 Hz; hints stay well under it).
- Every motion **comes to rest** and the picture **stays still** after it, so a child who looked away a moment later still sees it. Glows of L1 fade 1.5 s after the line ends, but the small "already counted" dots stay until the child taps. L2 cards stay while the item is open. After L3: the halo on the answer stays (owner Q3); the counting badges fade 600 ms after the hand leaves.
- **Reduce motion (OS setting):** no flights and no arcs; each step **appears in place** with a 200 ms fade, in the same order and on the same word onsets; the hand appears still at each target in turn (no travel); glows are static rings; the balance beam is drawn already tipped; the clock hand steps (no sweep). The child sees the same pictures in the same order.

### 2.3 Sizes (board points)

| Element | Phone | Tablet | Notes |
|---|---|---|---|
| Halo ring | 4 stroke + a 10 soft glow at 35%; 6 beyond the target | 5 + 14 | `hintHalo` |
| Fade of the rest (P1) | `cream` at 50% over the stage only, holes 8 beyond each target | same | never over tiles |
| "Counted" dot | r 4, `skyDeep`, at the object's top end corner | r 5 | |
| Number badge | r 11 (numeral Heebo 800, 14) | r 14 (18) | paper fill, `skyDeep` 2.5 ring, LTR numerals |
| Big count card (cardinal) | 64 × 64, numeral 44 | 88 × 88, numeral 60 | paper, `hintHalo` 3 ring |
| Pointing hand | 44 × 66 (fingertip is the anchor) | 60 × 90 | min 40 tall on SE |
| Counting hands | 46 × 84 each, 44 apart | 64 × 116, 60 apart | min 40 × 72 |
| Ten-frame cell | 30 (min 24) | 44 | ink 2.5 frame, 1.5 lines |
| Number path square | 28 × 36 (min 22) | 44 × 56 | |
| Hint card | radius 18, `skyTint`, `hintHalo` 3, padding 12 | radius 24 | |
| Swatch dab | r 30 with helper symbol | r 44 | |
| Cubes (balance, towers) | 10 (min 8) | 16 | |

---

## 3. The shared pictures (P1 to P12, design items D1 to D12)

See `b40_m0_shared_pictures.png`.

| # | Picture | Drawn as | Motion, and its reduce-motion still | RTL |
|---|---|---|---|---|
| P1 | **Spotlight** | Halo ring on the target; the rest of the stage fades to 50% | Ring grows from 0.8 to 1.0 in 250 ms; still: the ring | — |
| P2 | **Light each** | A halo moves from object to object; a small sky dot stays on each one visited. **No numbers and no number words at L1** (§6, F2) | One step per 950 ms (A); still: rings appear one by one | **Left to right, top row first, everywhere in the stage**: loose objects, pattern cells, sequences, orders in time, frames and paths. A row's walk ends on the gap at the right end. The program strip goes top to bottom (§8a) |
| P3 | **Two hands** (D2) | Hands seen from the back, fingers up, warm `sparkTint` with ink outline; a raised finger is `spark`, a folded one a short stub. The left hand fills first (five), then the right hand. Fingers rise index, middle, ring, little, thumb (how children show their age; F12) | A finger rises (200 ms) as its object lights; a dotted sky line from the object to the finger for 600 ms (one-to-one) | Hands are a maths picture: five on the left, more on the right; never mirrored |
| P4 | **Ten-frames** (D3) | 2 × 5 frame, ink; counters are the activity's own pictures at 80% of a cell (Band A) or ink dots (Band B). Full frame + ones frame side by side | Objects fly one by one into the next cell; still: they appear | Fill the top row from the left, then the bottom row from the left (as the number path). F4 |
| P5 | **Pair lines** (D4) | Dotted `skyDeep` lines (3, dash 1-6, round caps) between partners; the unpaired ones get a halo | Lines draw one at a time (300 ms) | — |
| P6 | **Number path** (D5) | Equal squares, numerals in them, 1 at the left (Siegler and Ramani's board); hop arcs `skyDeep` 3; landmark squares 5 and 10 a little taller | A marker hops square to square | Never mirrored |
| P7 | **Core bracket** (D6) | An open bracket under each copy of the unit; the copies lift and stack under each other | Brackets draw in turn | Left to right: the first copy at the left, and the others stack under it (§8a) |
| P8 | **Baseline** (D7) | A dotted start line; things slide to it; for towers, one floor | Slide 450 ms | Start line at the row's start |
| P9 | **Sample** (D8) | Colour: a round paint dab of the teaching colour with its helper symbol. Shape: a ghost outline (`skyDeep` dashed 3). Rule cards: the existing `rule_*` sprites. Coin: the coin with its value badge | The sample glides to each option in turn and **sticks only at L3** | — |
| P10 | **Act out** (D9) | A small scene made of the question's own objects (the box and the ball of the tiles), in the stage | 2 to 3 s, then still | F10 |
| P11 | **First step** | The guide (or the activity's own actor: frog, robot, coin) does one step, and a trace of it stays (an arc with 1, a lit row, one sorted picture) | One step, then still | Patterns: the leftmost empty slot. Path: one hop to the right (to the left only when counting back). Timeline: slot 1, at the left (§8a) |
| P12 | **Pointing hand** (D1) | One neutral hand for every companion: `skyTint` fill, `skyDeep` 2.6 outline, index finger long and down, the other fingers curled, a short wrist, **no cuff and no glove stitching** (it must not look like any cartoon glove); it arrives from the upper right, the guide's side | §2.2; still: the hand appears at each target | The hand is not mirrored per target; it always comes from the guide's side |

The counting hands (P3) and the pointing hand (P12) are drawn **differently on purpose**: the warm hands are "fingers to count", the sky hand is "the helper's pointer". A child must never count the pointer's fingers.

---

## 4. The ladder per template (visual spec)

Each row: what appears, where, and how L1, L2 and L3 differ. "Card" is the sky hint card of §2.1. Numbers are board points on the phone unless said.

| Template | L1 look here | L2 another way / together | L3 watch me, then you | Mockup |
|---|---|---|---|---|
| **count_tap** | P2 on the objects, no numbers; the counted dot stays | ≤ 10: P3 two hands in a card in the free answer area (320 × 110), one finger per lit object. 11 to 20: the objects fly into P4 two frames (cell 30) in the same card | Hand touches each object, a badge stays on each; the last badge glides into a big count card (64) at the stage's end side; hand leaves, badges fade | M1 |
| **give_n** | P1 on the plate, and N as the numeral **with its dots** in a card beside the plate (the goal) | ≤ 10: P3 hands showing N in the answer-area card; 11 to 20: P4 with N empty cells drawn on the plate (places to fill) | Hand moves N objects one by one, counting with badges; the plate's cells fill; then they go back | (as M1, M6) |
| **flash** | The group again, 2 × longer | NUM-A-10: the same number as P3 hands; NUM-A-05: the dots slide into a row (P8) | The dots light one by one with badges, then gather; the numeral tile gets the halo last | — |
| **trace** | The start dot and the first arrow pulse; only the first segment glows | The walking dot over the whole stroke, slower, leaving a sky trail | Hand traces stroke by stroke; the trail fades; the child traces | — |
| **sort_drag (sort)** | P1 on each bin's sample picture in turn, and the rule card | P9: the next picture's attribute (swatch, outline) glides past each bin's sample, without stopping at any | Hand drags **one** picture into its bin, then hands back | — |
| **sort_drag (share)** | P1 on each friend's plate in turn | P11: one round dealt (one each), then stop | Hand deals all; then they go back | — |
| **build_pattern** | P2 along the row in rhythm, ending on the empty slot (where, not what) | P7 brackets on the unit; for copy items the model cell above the next slot glows | Hand reads the row, the unit slides to the gap, the piece appears last | — |
| **match_pairs** | P1 on the first unmatched card | The representation per skill: dots under the numeral, the coin's value badge, the solid "stamps" its face | Hand draws **one** line, then hands back | — |
| **shape_builder** | P1 on the next empty outline | The outline lifts as a ghost (P9), turns slowly beside the tray | One piece flies into its slot | — |
| **number_line** (jump) | Rest fades; the start tick (tick + numeral) glows; a pill of **dots** for the hop size above the actor | P11: one hop with an arc and badge 1; one dot of the pill empties; the actor stays there | The actor hops each unit (badges 1, 2, 3), lands; the target tick glows; the actor goes back to the start; arcs and glow stay faint; hand points at the tick | M4 |
| **number_line** (place) | 0, 5 and 10 glow, with a small sky arrow under the line pointing right | P11: one hop from 0, counted | The walk to the target, with badges; then back | — |
| **robot_path** | P1 on the robot's face (heading) and the goal; Band A also the landmark | P11: a ghost robot does one step, its footprint stays | The run with numbered footprints; reset | — |
| **shop_pay** | The price glows, and the counter shows **N empty coin places** (rows of five) | P11: the biggest coin that fits goes on; its places turn gold under a bracket; the rest stay empty | Coins go on one by one, each fills its places, a running badge 5, 7, 8; all places gold; coins go back with a soft halo | M6 |
| **clock_set** | The short hand glows and the long hand fades; a card with the target numeral stands beside the clock (the question, not the answer) | A dotted line from the card to the same numeral on the dial, which gets a ring | Hand presses + step by step; the short hand steps with a badge at each hour; then back; a faint sky target hand stays | M5 |
| **balance** (hidden tilt) | Each pan's cubes glow together, left pan then right | **Towers:** each pan's cubes stack into one tower on its pan (the pans are level, so one floor); a dotted line from the short tower's top across to the tall one; the cubes above the line glow | The peg slides out, the beam tips slowly (1200 ms); hand goes from the low pan to the arrow that points that way | M7 |
| **balance** (tilt shown) | A dotted level line across the beam's pivot makes the tilt visible | Towers, as above | As above, without the peg |
| **balance** (weigh) | P2 on each pan | Pair lines between the pans' cubes in two rows **under** the balance (inside the stage); the missing ones are empty outlines | Blocks go on one by one | — |
| **balance** (equations, MATH-B-09) | P1 on the two sides of = | Cubes appear above each number (a stack per number) | As above | — |
| **spot_error** | P2 across the row in its order | By family, no cell marked: a correct number path under the row (counts), brackets (patterns), the rule card beside each cell (sorts), cubes over numbers (sentences), the ghost robot (programs) | The walk stops at the wrong cell; the right one appears beside it (sky card); then the child taps | — |
| **tap_answer** | By family (§5) | By family | By family: the process with the hand; the answer appears last and glides to its tile; the tile keeps the halo, the others fade to 60% | M2, M3 |

---

## 5. tap_answer families: where each picture goes on the phone

tap_answer always has tiles under the stage, so L2 lives in the stage (§2.1 b).

| Family | L1 | L2 (in the stage) | L3 |
|---|---|---|---|
| TA-1 count a group | P2 on the objects, no numbers | P3 one hand in a card at the stage's end side (82 × 120) with dotted lines object → finger; above 10: objects fly into P4 frames | Badges, the last one grows and glides to its tile (M2) |
| TA-2 numerals | P1 on the numeral; its dots appear under it | P6 path 1 to 5 walking to N (A); teens: a full frame plus ones (B) | The quantity is built, then the hand goes to the tile |
| TA-3 sequence | P1 on the gap; the given numbers glow **without being said in order** | P6 path with the gap's square empty; fingers for Band A | The walk lands on the gap |
| TA-4 compare | P8 the two groups line up in two rows, equal spacing (removes the size cue) | P5 pair lines; the unpaired glow | Pairs one by one, the leftovers counted, the tile last |
| TA-5 add, take away | Replay the action; sentences: P1 on the sign | P3 or P4 as the plan; cubes over numbers | Same picture, ending on the result |
| TA-6 colour | P2 on the tiles, right to left, with the word (needs the sound, F1); COL-A-01: P1 on the model | P9 swatch dab in the empty stage (M3) | The swatch glides over each tile and sticks to the match |
| TA-7 shapes | Naming: P2 on the tiles (needs the sound, F1); matching: P1 on the model | P9 ghost outline of the named shape, turning; corners and sides lit and counted (B) | The outline glides over each option and fits one |
| TA-8 pattern rows | P2 in rhythm, ending on the "?" | P7 brackets | The unit slides to the gap |
| TA-9 same, odd one out | P1 on the model or the group | P9 rule card beside the group; options compared in turn | The comparison finishes; the one left glows |
| TA-10 order in time | P1 on the first picture | A timeline of 3 to 4 numbered slots in the stage (`day_*` cards for the week) | The guide walks the timeline |
| TA-11 measure | P8 the objects slide to one start line | Cube sticks along each (long/short); a small seesaw (heavy/light) | The comparison is made |
| TA-12 clock, money | Clock: the short hand glows, the long one fades. Coin: the coin grows and shows its value | Clock: the short hand extends as a dotted ray to its numeral. Coin: its value beside a same-size coin of another value | The hand runs along the hand to the number |

---

## 6. Checks and flags: what will NOT be clear to a young child visually, and the alternative

| # | In the curriculum plan | Why it will not work visually | What I designed instead |
|---|---|---|---|
| F1 | TA-6 and TA-7 naming items, L1 "the tiles lit in turn with the word" (also numeral names, day names, ordinals) | The question **is a word**. With the sound off, L1 can only say "look at each one". There is no way to show "red" without showing a red sample, which is L2 | Kept as designed, honestly marked "needs the word" (M3, L1). The first fully visual hint for naming items is L2 (swatch, ghost outline). **Owner decision 1** |
| F2 | TA-1 and TA-3 L1 "P2 ... with the count words"; TA-3 "the given numbers light as they are said, from the start" | Counting aloud at L1 *is* the answer: the last number word is the count (owner Q4) | L1 lights each object **without numbers or number words** (M1, M2). Counting with badges happens only at L3. The hebrew-text-editor's L1 lines must not count |
| F3 | TA-1 L2 fingers for 1 to 5 | Three raised fingers alone are a second picture of the answer | The fingers rise **one per lit object, with a dotted line from the object to the finger**, so it reads as "count another way", and the child still finds the numeral (M2 L2) |
| F4 | P4 ten-frames "fill the top row first, from the left" | The classroom reason ("like reading a book") is reversed in Hebrew | Keep left to right, the same as the number path and the LTR maths rule; the voice never says "like reading". curriculum-expert to confirm with Israeli kindergarten materials |
| F5 | §1 "pattern rows ... drawn left to right"; P7 | design-spec §8 says pattern rows **mirror** (read right to left, gap at the left end), but the app draws them left to right with the "?" on the right (golden `unit_logic_next_phone.png`) | **Resolved 2026-10-30 (§8a):** every row in the stage runs left to right, with the gap at the right end. The app stays as drawn, and design-spec §8 changes |
| F6 | balance L2 "P5 pairs the blocks of the two pans" | On the phone's 330 × 128 stage, lines between the pans cross the post and the beam: a tangle | **Towers on the pans with a level line** (P8): the extra part of the tall tower glows (M7 L2) |
| F7 | clock_set L1 "the short hand and the 12 for the long hand" | Sound off, the child does not know *which* number is wanted | L1 adds a small card with the target numeral beside the clock (an echo of the question); L2 links the card to the same numeral on the dial (M5) |
| F8 | shop_pay L1 "the price as that many ₪1 dots under it" | Dots under the tag are a second number to read; they do not grow into L2 and L3 | The price becomes **empty coin places on the counter** (rows of five); L2 and L3 fill them, so the child always sees how much is left (M6) |
| F9 | number_line L1 "the hop size as fingers or dots" | Fingers are too small on the phone stage and do not show progress | A pill of dots over the actor; each hop empties one dot (M4) |
| F10 | P10 act-out scenes (on, under, next to; the sun's path; pouring paints) | Hardest to read without words on a 330 × 128 stage, and a new scene adds objects the child must sort out | Act out with the question's **own** objects only, 2 to 3 s, then still; each scene needs its own small storyboard and the owner's look before it is built |
| F11 | count_tap L1 "each object wiggles in turn" (today) | A wiggle can read as "the apple is alive", not "count me" | A sky glow plus a dot that stays on visited objects (M1 L1) |
| F12 | P3 finger order (not stated) | — | Index, middle, ring, little, thumb (how children show 1, 2, 3); curriculum-expert to confirm |
| F13 | Phone stage 330 × 128 for every L2 | Two hands, two frames or a path do not fit beside the scene | §2.1: the free answer area (count_tap, give_n, flash, trace) or objects that **fly** into the new picture, so the link to the question is kept |

---

## 7. What the app-developer needs (per template)

Shared, built once (A4): a `HintLayer` in `app/lib/play/hints/` drawn above the stage, `IgnorePointer`, given the stage `room` and the target rects by the template, with the sizes of §2.3 as constants in `design/tokens.json` (new group `hint`: `haloStroke`, `haloGlow`, `badgeR`, `countCard`, `handH`, `fingerHandH`, `frameCell`, `pathSquare`, `cardRadius`, `dabR`, `cube`) and the timings of §2.2 (new `motion.hint`: `lightDwellA/B`, `flyA/B`, `stagger`, `handMove`, `handPress`, `fadeLinger`). Widgets: `Spotlight`, `LightEach`, `CountingHands` (replaces `FingersHint`), `TenFrames` (reuse `sprite_group.dart` ten_frame layout), `PairLines`, `NumberPath`, `CoreBracket`, `Baseline`, `SampleSwatch` / `GhostOutline`, `HintCard`, `PointerHand` (the hand from `make_b40_mockups.py hand()`, as a painter or an SVG asset `app/assets/art/ui/hint_hand.svg` I will draw), `CountBadge`, `CountCard`. Each with a widget key per picture for the tests (`hint-p1` ... `hint-p12`), and a reduce-motion path (`MediaQuery.disableAnimations`).

| Template | L1 builds | L2 builds | L3 builds | Golden to add (phone, tablet L) |
|---|---|---|---|---|
| count_tap | LightEach(objects) | HintCard(answerArea) + CountingHands(n) or TenFrames(n) | PointerHand path + CountBadge per object + CountCard | `hint_count_l2_hands`, `_l2_frames`, `_l3` |
| give_n | Spotlight(plate) + goal card | CountingHands / TenFrames with empty cells | PointerHand moving N | `hint_give_l1`, `_l2` |
| tap_answer | per family (§5) | HintCard(stage end side) or objects fly | PointerHand, CountBadge, answer glides to tile, tile halo stays, others 60% | one per family at L2 and L3 |
| number_line | Spotlight(start tick + numeral) + dot pill | one hop + arc + badge, pill dot empties | all hops, target tick halo stays, actor back | `hint_numberline_jump_l1..l3` |
| clock_set | glow on short hand, long hand 35% opacity, target card | dotted link card → dial numeral + ring | PointerHand on +, stepping hand with badges, ghost target hand | `hint_clock_l1..l3` |
| shop_pay | price halo + empty places (rows of 5) | one coin placed, its places gold, bracket | coins one by one, running badge, coins back with halo | `hint_shop_l1..l3` |
| balance | cubes glow per pan | towers per pan + level line + glow above it | peg out, slow tilt, PointerHand to arrow tile | `hint_balance_l1..l3` |
| sort, pattern, match, builder, robot, spot_error, flash, trace | as §4 | as §4 | as §4 | L2 and L3 each |

Engine (A3, A6): the guided state starts with the L3 demo; the halo and the 60% fade come after it; the first mistake shows L1, the second L2 (two-choice items: the first mistake shows L2, then the demo).

Text (hebrew-text-editor): each line describes exactly what is drawn, at the moment it is drawn; L1 lines never count (F2).
Sound (voice-and-sound-director): word onsets for the L3 lines, so the hand moves on the words; a soft "tok" on each hand press, the same at every level.

---

## 8. Decisions for the owner

1. **Naming items with the sound off (F1).** For colour, shape, numeral and day names, L1 can only show "look at each one"; the meaning is in the word. (a) Keep it: L2 (the swatch, the outline) is the first fully visual hint. *Recommended*, because it keeps your answer to Q5. (b) Show the sample already at L1 for naming items.
2. **Pattern rows (F5).** design-spec §8 says right to left with the gap on the left; the app draws them left to right with the gap on the right. Which one? Hints follow whichever you choose.
3. **The look of the helping hand and the counting hands** (`b40_m0_shared_pictures.png`, P3 and P12): a sky hand for pointing, warm hands for counting.

## 8a. Owner answers 2026-10-30

1. **Naming items with the sound off:** "it's OK" (option a). L1 for colour, shape, numeral and day names is "look at each one" with the word, and L2 (the swatch, the outline) is the first picture hint.
2. **Pattern rows:** "do it in the only way that won't be confusing to the children." The curriculum-expert decided this (curriculum plan §12.1). **Every row inside the stage is drawn left to right in the LTR isolate. The first cell is at the left, and the "?" or the next empty slot is at the right end. Rows never mirror.** The rule is the same for:
   - picture, colour and shape patterns (AB, ABB, ABC; shade ramps, rainbow and size order),
   - growing patterns,
   - number sequences (counting back too: the values go down along the row),
   - order-in-time rows (slot 1 at the left, numbered).

   The reason is that the app already draws every row, the number line, the ten-frame and the number path left to right. A single mirrored kind would put the "?" on opposite sides for the same question. Navigation (the lesson path, the progress trail, back and next) still mirrors. The robot program strip stays vertical.
3. **The hands:** they look good. The mock hands become the art (§9).

**Changes that follow:**
- **design-spec §8**, owned by the design-director: the rows "Pattern rows" and "Story sequences, timelines, first/then/last cards" become **Does not mirror: left to right in the LTR isolate, the gap or the next slot at the right end**.
- **The start cue (A8 in the plan):** when an item opens, the row's cells appear one by one from the left, about 120 ms each, with the gap last. With reduce-motion, a still sky start dot sits under the first cell. Israeli preschoolers tend to count from the right, so the start must be shown, not assumed.
- **P2:** left to right everywhere in the stage.
- **P7:** the first copy is at the left.
- **P11:** the leftmost empty slot, a hop to the right, and slot 1 at the left.
- **F4:** the ten-frame fills from the left, which is consistent with this rule.
- **App code and pack items:** no change to the direction.

## 9. What I looked at, and what is still placeholder

- Looked at: all eight PNGs above, and a 3× zoom of the hands. Not looked at: a real phone, tablet renders of the hints (the tablet placement in §2.1 is specified, not drawn), SE renders, reduce-motion.
- References (facts only, no images copied): ten-frame fill order (Illustrative Mathematics K unit 5 lesson 10; Van de Walle via the SANC ten-frames reading); the Number Frames app (Math Learning Center); Siegler and Ramani's linear number board (IES WWC study 73675); finger counting by five and more (Wikipedia, "Finger-counting"); pointing helps counting (Alibali and DiRusso 1999, in the curriculum plan).
- Placeholder: the pointing hand, the counting hands, the swatch dab and the towers are mock drawings; the hand will become `app/assets/art/ui/hint_hand.svg` (and a still version) before A4; until the illustrator's art (to-do P9), these shapes are what ships.
