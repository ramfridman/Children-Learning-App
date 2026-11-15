# M11 Stage 1: nine rooms, the host as teacher, a celebration per place, the stage that reacts (design spec)

Owner: design-director. Date: 2026-11-14. Status: **spec for the app-developer** (steps 1.1, 1.3, 1.4, 1.5 of `docs/milestones/M11.md`, approved by the owner on 2026-11-14) and the pose sheet for step 1.2. The host sample (Nekudi's three poses) waits for the owner's eye before the other 24 drawings are made.

Built on: `docs/milestones/M11.md` (§0 to §3 and the owner's answers in §9); `docs/design-spec.md` §3.2 (lands, hosts, landmarks), §4.9 (role slots, rig contract), §6, §7, §8, §9 (palette, colour-blind rules, §9.3 Colour Bay), §10 (motion, celebration tiers); `design/tokens.json`; `app/lib/child/activity_shell.dart` (`ActivitySpec`, the four boards), `app/lib/play/activity_frame.dart` (`ActivityFrame`, `LessonCelebration`), the goldens `lesson_2_count_three_answers_*`, `lesson_6_celebration_phone`, `hint_robot_*`, `hint_sort_*`, `c1b_give_frame_phone`; `docs/design/l7-meet-find.md` on `origin/languages-teach-first`; the art in `app/assets/art/world/`, `app/assets/art/languages/`, `design/assets/`.

Boards (`docs/design/m11/make_m11_boards.py`; every board at its real size in points with the app's art and fonts, rendered by headless Chrome; red captions are for the team; every Hebrew line on them is a sample for the hebrew-text-editor):

| File | What it shows |
|---|---|
| `docs/design/m11/counting_hills_phone.png` | Counting Hills on the phone: Show (Nekudi teaches, the companion watches), Alone (the companion asks), the stage reaction's end state, the celebration |
| `docs/design/m11/robot_harbour_phone.png` | Robot Harbour on the phone: Show (predict, then watch), Alone (grid and arrow palette), the celebration |
| `docs/design/m11/host_beat_boards.png` | one host beat (Counting Hills Show) on phone, phone SE, tablet landscape and tablet portrait, with the exact boxes |
| `docs/design/m11/nine_rooms.png`, `nine_rooms_grey.png` | the nine rooms side by side (host beat, empty stage), in colour and in greyscale |
| `docs/design/m11/nekudi_poses.png` | Nekudi's still and the three new poses: full size with baseline and centre, at the phone size on her room's tint, and as 48 pt silhouettes |
| `docs/design/m11/room_<room>.png` (9: `numbers`, `colors`, `shapes`, `logic`, `cs`, `math`, `eng`, `heb`, `rus`) | one room each: the host beat with the stage empty; three pictures straight on the backdrop (phone); a ten-frame, the reaction's end state (phone stage x2); the tall robot stage with a 4 x 3 grid; the tablet landscape host beat (x0.75); the celebration with the new piece; the tablet portrait stage with three pictures |

---

## 1. The spec in one page

1. **Two places in the friend's corner.** The corner (start side, where the guide stands today) is where the talking happens. Its **front** holds whoever owns the current beat, at full size, with the bubble's tail at its mouth. Its **back place**, half a step behind on the outer side and smaller, holds the companion while the host teaches. The companion never leaves the corner; the host comes into it to teach and steps out when it is the child's turn.
2. **Who owns which beat** (the owner's decision of 2026-11-14): the **host** owns the greeting, the Show (the worked example or predict-then-watch, including the child's last step in it), the lead-in of each Together item, and the cheer. The **companion** owns every child's turn: the Together item after its lead-in, Alone, Use, every hint and every feedback line, as today. The host is not on screen during the child's turns.
3. **The tail always points at whoever is talking.** One bubble, one speaker at a time; the speaker is in `talk`, the other in `listen` looking at the speaker. A companion feedback line inside a host beat (the microphone's "heard" line on a Meet screen) moves the tail to the companion in the back place; nobody moves.
4. **The host does not stand at the stage edge** (the plan's first idea). On a phone the stage is 330 by 128 and every template fills it; a host there would cover the task. The **landmark** has a place of its own instead (section 3.4), always on the screen and clear of the stage's content, and it is where the stage reacts.
5. **A room is told apart by shape first**: each room has its own backdrop silhouette (round hills, a forest of cones, a cave, a harbour, an awning, three rooms with three windows), its own landmark, and its own trail socket shape (stair, drop, tree, puzzle piece, nut, orange, porthole, arch, square window). Colour (the domain tint on the screen, the domain colour on the stage's rim) is the third cue, never the only one. The greyscale board shows all nine apart.
6. **Colour Bay is the most vivid room** (changed 2026-11-15 after QA of Stage 1 found the neutral bay washed out). Its colour lives at the edges: a rainbow over the far islet, a sailboat with a striped sail, a kite, a rainbow parasol, an easel with paint blots and a red bucket in the corner, a coral scallop shell over a turquoise pool. The middle of its stage stays light (a pale sky, pale shallow water), every picture laid on the stage keeps its ink outline, and the tiles stay `paper`, so colour is never the only cue. Its frame takes the domain's own colours like the other lands (screen `colors.tint`, rim `colors.fill`, lip `colors.deep`). Goni is no longer grey (the owner's decision of 2026-11-15): he has his own mint skin and, after a right answer, takes the colour the child found (section 5.2).
7. **The stage reacts after every right answer**, at any hint level and after a worked example: a short (at most 900 ms) motion at the landmark, then an end state that lasts until the item leaves. Never before the answer, never on a wrong one, never counted or kept. Reduce motion shows the end state only.
8. **The celebration is the room's window**: the lesson's card shows the room's backdrop, the landmark gaining one piece, the host and the companion celebrating side by side, the sticker, the praise line and one way home.
9. **Art**: the room art is drawn (2026-11-14, owner's request for richer rooms): per room a layered backdrop (far, ground, top bands and a corner cluster), a richer landmark, its celebration piece and its reaction end state, 63 SVGs in `app/assets/art/rooms/` from `tools/make_room_art.py`; Goni's recolourable still and poses in `app/assets/art/hosts/` (section 5.2). Still to make: 24 more host poses (step 1.2, another run) and 9 stage pointers (cut from the show poses, a tool step). Nine colour values for the course rooms go into the tokens. Only the sky or wall gradient and the trail sockets stay code-drawn.

---

## 2. The host and the companion

### 2.1 The beats of a lesson

| Part | Front (speaker's place) | Back place | Bubble's tail | Microphone | The host's hand |
|---|---|---|---|---|---|
| **Greeting** (first screen of a lesson or mission, before its first item) | host, `wave` then `talk` | companion, `listen` | host | none | |
| **Show** (unscored; the worked example, or predict-then-watch) | host, `show` while its hand acts, `talk` between | companion, `listen` | host | none (a Show has no spoken answer) | the host's pointer acts in the stage (2.4) |
| **The child's last step of the Show** | host, `listen` (waits); "let's look again" on a wrong touch is the host's | companion | host | none | |
| **Together: the lead-in** (the host does the first part) | host, `show` | companion | host | none yet | the host's pointer does the first part |
| **Together: the child's part** | companion (the host steps out, 2.5) | empty | companion | as today | the B-40 hint hand, if a hint is asked |
| **Alone, Use** | companion | empty | companion | as today | B-40 hint hand |
| **Hints, feedback, idle prompts** | companion | (host, only inside a host beat) | companion | | |
| **Celebration** | both, side by side in the card (section 4) | | the praise line is the companion's (as today); the host's cheer is its own edge line | | |

- **The two hands mean two things**: the host's pointer (its own limb, section 7.4) shows how; the white B-40 glove is a hint. A child never sees the glove during a Show, nor the host's pointer during Alone.
- **Revisit missions and warm-ups** keep their shapes and their room; the host greets and cheers, there is no Show, so the host is on screen only at the two ends.
- **Tapping a character** replays the line that character said last (the existing `onReplay`); a character that has said nothing on this screen replays the current question. Neither is ever a scored target.

### 2.2 The places, per board (board points; boxes are the square character boxes of the rig, baseline at 472/512 of the box)

| Board | Companion alone (today's guide box) | Host in front | Companion in the back place | Bubble's right edge in a host beat (today) | Bubble's max width in a host beat (today) |
|---|---|---|---|---|---|
| Phone 852 × 393 | 617, 80, 176 | **597, 88, 168** | **697, 158, 96** | **591** (603) | **178** (190) |
| Phone SE 667 × 375 | 490, 66, 150 | **478, 74, 144** | **565, 128, 86** | **470** (476) | **170** (176) |
| Tablet landscape 1180 × 820 | 896, 150, 260 | **872, 150, 260** | **1004, 250, 152** | **932**, `bubbleRight` 248 (956, 224) | 600 |
| Tablet portrait 820 × 1180 | 596, 112, 200 | **572, 128, 184** | **680, 190, 116** | **566**, `bubbleRight` 254 (596, 224) | **410** (440) |

- The host and the companion stand on **one ground line** (the baselines match within 2 points), the companion drawn **behind** the host (lower z), so the pair reads as two friends standing together, not a stack.
- Everything else of the frame (controls, trail, stage, tiles, microphone) keeps its place. The microphone is never shown in a host beat except on a Meet screen (section 6), and the back place is clear of it on every board (phone mic 661, 260 to 749, 348; the back place ends at y 254).
- **The host's mouth** (the tail's target) comes from its pose file's `mouth` anchor (section 7.2), not from Nitzi's `mouthShare` 0.576: Nekudi's mouth is at 0.52 of her box.
- **The tail ends at the speaker** (QA's D4). In a room the bubble holds its **right edge** (the speaker's side), so a short line stays beside the speaker. The small pointer on its end edge points at the speaker's mouth when the mouth is level with the bubble (the phones, the portrait tablet); when the speaker stands lower than the bubble's bottom by more than 32 points (the landscape tablet: the bubble stands above the card, the corner is taller), the tail is a **wedge** from the bubble's bottom, at its end, to a tip that stops 0.2 of the speaker's width short of the mouth (`BubbleTail`). The same for the companion alone. On a phone the bubble also keeps 6 points from the stage (its 4 point rim and 2 more), including when a long line makes it wider (`fitBubble`'s `spillSkip`); with the rooms off it may touch the stage's edge, as before.
- The bubble's narrower width in a host beat goes through the frame's own `fitBubble` (it shrinks the font to the floor, then grows down). Host lines on the phones should hold **two lines at the band's size** (about six words); the hebrew-text-editor gets this limit (section 11).
- Reference: `host_beat_boards.png` shows all four boards with these numbers; nothing overlaps the bubble, the stage or the controls.

### 2.3 Device notes

- **Phone and SE**: the host is a little smaller than the companion alone (168 against 176) so that the pair fits the corner; its out-held hand reaches toward the bubble and stops 6 points short of it.
- **Tablet landscape**: the corner is tall, so the pair stands in it at the guide's height; the landmark moves out of the stage to the empty column at the stage's end side (section 3.4), which is where the stage reacts.
- **Tablet portrait**: the guide strip is wide, so the pair stands side by side at its start; the bubble gives up 30 points of width for the host beat only.

### 2.4 The host's pointer in the stage

In a Show and a Together lead-in the worked example is acted by the host's own limb tip (its `hand` group cut from the show pose, section 7.4), entering the stage from the stage's bottom edge, as the B-40 hands do ("hands from below"). Its tip is the touch point; it moves pieces exactly as the hint-3 worked example does today (same paths, same timing), and it stops before the last step so the child does it. On the boards: Nekudi's leg points at the eighth place of the ten-frame.

### 2.5 Entrances, exits, hand-overs (motion in section 5)

- **Host enters** (greeting, the first host beat after a child's turn): it walks in from the start edge (right) to the front, the companion stepping back to the back place at the same time.
- **Host hands over** (the end of a Show, the end of a Together lead-in): the host says its hand-over line ("now you!"), turns to the child, then walks out at the start edge while the companion steps forward and grows into the front, so the child sees the friend come to help.
- **Between two host beats with no child's turn between them** (the Show's screens, a Meet set): nobody moves.

---

## 3. The nine rooms

### 3.1 The table

Domain tokens are `color.domain.<d>.{fill, deep, tint}`. The course values are new tokens (3.6).

| Room | Screen (frame) | Stage rim (phones 4 pt, tablet card border 4 pt; card lip 6 pt) | Backdrop (3.2) | Landmark (3.4) | Trail socket (3.3) | Host | Celebration piece (4) | Stage reaction (5) |
|---|---|---|---|---|---|---|---|---|
| **Counting Hills** (Numbers) | `numbers.tint` #FFE3DF | `numbers.fill`; lip `numbers.deep` | **round hills**: pale far hills and a footpath, grass with flowers, a sun; corner: a round tree on a mound | `rooms/numbers_landmark.svg`: four 3D coral steps with a handrail | **stair** (the row climbs 1.4 pt per socket toward the end) | Nekudi | a fifth, gold step at the end side | a dot hops up the steps, the top step lights |
| **Colour Bay** (Colours) | `colors.tint` #FCE1F0 | `colors.fill` #E04F9E; lip `colors.deep` #B4337C | **a sunny bay, the most vivid room**: a clear blue sky, a bright sun, clouds and a rainbow kite; a turquoise sea (deep at the horizon, pale in the shallows) with a rainbow standing on a sandy islet with a palm (end side) and a sailboat with a red, yellow and blue sail; golden sand with foam, a starfish, a pink shell, a sea glass; corner: a rainbow parasol, an easel with red, yellow and blue paint blots, a red bucket with a yellow spade, a starfish | `rooms/colors_landmark.svg`: a giant coral scallop shell behind a round turquoise rock pool with a sandstone rim, a starfish and a pearl | **drop** | Goni, his own **mint skin**; after a right answer he takes the found colour (5.2) | a rainbow swirl in the pool | the whole shell lights up in the rainbow's colours, a splash crown and two ripple rings in the pool |
| **Shape Forest** (Shapes) | `shapes.tint` #DDF3E6 | `shapes.fill`; `shapes.deep` | **a forest of firs**: two rows of pale tiered firs (rounded tiers, so they read as trees, not as triangles), grass, a sun; corner: a fir, a clipped sphere bush, a limestone cube, a log | `rooms/shapes_landmark.svg`: a tall tiered cypress and a small sphere bush | **tree** (triangle on a trunk) | Kubi | a second fir at the start side | a small fir grows at the end side of the landmark |
| **Riddle Grotto** (Logic) | `logic.tint` #ECE3FE | `logic.fill`; `logic.deep` | **a cave**: a lilac ceiling with stalactites of many lengths and three glowing crystals, a pale back wall with columns and an arch open onto the sea, a sand floor with shells in a pink-gold pattern; corner: the cave's side wall and a crystal cluster | `rooms/logic_landmark.svg`: a violet door in a chalk arch, four slots top to bottom: circle, square, triangle, and an empty dashed fourth | **puzzle piece** | Timi | the fourth slot fills with a circle (the pattern goes on) | the door's three shapes light one after another, the door glows |
| **Robot Harbour** (CS) | `cs.tint` #DEEBFC | `cs.fill`; `cs.deep` | **a harbour**: sky, clouds and gulls, a `sea1` sea with a container ship, a lighthouse on its breakwater and a moored boat, a plank quay with bollards, a rope and tyre fenders; corner: stacked containers and a bollard | `rooms/cs_landmark.svg`: a blue gantry crane on wheels with its cab, trolley, cable and hook | **nut** (hexagon with a hole) | Tza'adon | a gold crate on the quay | the crate is set on the quay under the hook (straps to the hook) |
| **Market Village** (Math) | `math.tint` #FEEFD6 | `math.fill`; `math.deep` | **a covered market**: a striped awning with scallops across the top, a pale stone arcade with stalls in its arches and hanging lamps, stone paving; corner: crates of oranges and pears, a basket of grapes. No clock anywhere (the land teaches time) | `rooms/math_landmark.svg`: a stall with a striped awning, a heap of oranges and an empty glass jar | **orange** (round with a leaf) | Grandma Pnina | an orange on top of the heap | a coin drops into the jar |
| **English** | `eng.tint` #E1ECF8 (new) | `eng.fill` #2C6FB8; `eng.deep` #1F5590 | **Pip's reading nook**: a cornice with round paper lanterns, beadboard wainscot, floorboards and a bordered rug; corner: Pip's perch stand (T-perch, ring, bell) and a bookshelf with a globe | `rooms/eng_landmark.svg`: the **round window** with a sill | **porthole** (ring) | Pip the budgie (`languages/host_eng.svg`) | a daisy in a pot on the sill | the window lights (warm glass, a soft sun) |
| **Hebrew** | `heb.tint` #FBE4DF (new) | `heb.fill` #D25E4E; `heb.deep` #A63A2C | **Alfi the hyrax's drawing room** (Alfi, אַלְפִי, owner's name 2026-11-15, from אלף-בית): practice sheets (wavy lines, zigzags, loops; never letters) pegged on a twine, a limestone lower wall, stone tiles; corner: an easel with practice lines, a stool with a jar of big pencils, a basket of rolled paper | `rooms/heb_landmark.svg`: the **arched window** (a rocky hill outside) with a sill | **arch** | the hyrax (`host_heb.svg`) | a paper boat on the sill | the window lights |
| **Russian** | `rus.tint` #EBE3F7 (new) | `rus.fill` #6D49B3; `rus.deep` #55358F | **Gosha the giraffe's tall room** (Gosha, גּוֹשָׁה, male, owner's name 2026-11-15): two pendant lamps, panelled lower wall, herringbone parquet and a bordered rug; corner: a tall leafy plant, a floor lamp, two floor cushions | `rooms/rus_landmark.svg`: the **square window** (four panes) with a sill | **square window** | the giraffe (`host_rus.svg`) | a tall flower in a pot on the sill | the window lights |

- **The default** (an activity whose domain is unknown, the dev pages): today's cream frame, the meadow, round sockets, no landmark, no host.
- **Nothing to count, nothing to find by accident**: no backdrop has a row of small repeated objects in the stage's working area (Counting Hills' stepping stones became one footpath; the English rug has no ring pattern; the Hebrew sheets are one per twine sag, with strokes only), no clock face (Market Village), no letters or numerals anywhere. Shape Forest's firs are drawn in rounded tiers so that "tap the triangle" never points at a tree (curriculum-expert to confirm).
- **Contrast**: every screen tint is light (L* above 88); `ink` on any of them is above 11:1 (Colour Bay's #FCE1F0: 11.8:1; on the bubble's `paper` 14.4:1; on its stage, where no text stands: the sky 9.9:1 to 13.3:1, the sea 7.8:1 at its deepest middle band, the sand 11.3:1); the bubble, the tiles and the trail pill stay `paper`. The rim never changes with an answer (it is the room, not a state): right is still the gold ring and check, not-yet the lilac ring and wobble.
- **Colour never carries an answer outside Colour Bay**: the room's colour is constant for the whole lesson, behind every answer alike.
- **Content on the backdrop**: the middle band of every backdrop (from 15% to 80% of the stage's height) stays light and low in chroma, so a teaching colour drawn straight on the stage (apples, balls, pattern tiles) keeps its contrast; the colourful parts (awning, trees, walls, landmark) live at the stage's edges.

### 3.2 The backdrops (layered art, step 1.1)

The backdrop replaces `asset:meadow` (1,189 of the pack's activities) when the activity is in a room; any other `background` (`bin_box`, `nest_empty`, the `stroke_*` pictures) is kept. It is built (`RoomBackdrop`) in the stage's own size from a code-drawn gradient and five SVG layers. **No layer is ever stretched**: each keeps its aspect and the stage's rounded clip crops it, so one set of files serves the phone (2.6:1), the SE, both tablets (2.1:1 and 2.8:1), the celebration window (3.5:1) and the tall robot stage (1.2:1).

**Source of truth**: the SVG files in `app/assets/art/rooms/`, generated by `tools/make_room_art.py` (its `SKY` and `LAYERS` are the numbers below; the boards script imports them, so boards and art never drift). The developer copies the numbers, never redraws the art.

| Order | Layer | File | Box (fractions of the stage's inner size) |
|---|---|---|---|
| 1 | sky or wall | code: vertical gradient `SKY[room]` | the whole stage |
| 2 | far band | `<room>_far.svg` (1600 x 200) | height 0.66 H, bottom on the stage's bottom, centred, width = height x 8 (cropped) |
| 3 | ground band | `<room>_ground.svg` (2400 x 100) | height 0.22 H, bottom, centred, width = height x 24 (cropped) |
| 4 | top band | `<room>_top.svg` (2400 x 100) | height 0.22 H, top, centred (cropped) |
| 5 | corner cluster | `<room>_corner.svg` (240 x 200) | height 0.52 H, at most 0.30 W wide (rooms: 0.64 H, at most 0.32 W); 6 in from the start (right) edge, 2 up |

The gradients (top, bottom): numbers `skyTop` → `skyBottom`; colors #A9DEF9 → #EAF8FD (2026-11-15; was #FFFFFF → #F5F2F8); shapes `skyTop` → #EAF7EE; logic #F7F3FF → `logic.tint`; cs `skyTop` → #EEF6FD; math #FFF8EC → `math.tint`; eng #F4F8FD → `eng.tint`; heb #FEF6F3 → `heb.tint`; rus #F8F4FD → `rus.tint`.

With `flutter_svg`: each layer is an `SvgPicture.asset` in a `Positioned` of the computed box inside a `ClipRRect` of the stage's radius (phone 24, tablet card inner 16, celebration 20). Four pictures per stage (the landmark is not one of them, 3.4); they are static, so wrap the stack in a `RepaintBoundary`. The files use no filters and no masks; one clip path (the course windows' reaction).

The art keeps the rule of 3.1: the middle band (15% to 80% of the height) is light and low in chroma; colour lives at the edges and corners. Checked on every room board with a ten-frame, three pictures laid straight on the stage and the 4 x 3 robot grid. No ambient motion in the backdrops in this stage (one focal motion at a time, design-spec §10.1).

### 3.3 The trail (step 1.1, `ProgressTrail`)

- The socket's size, gap and the pill are unchanged (20, 8, 36 high). Only the socket's **shape** changes, by room: the paths are `TRAIL` in the board script, each in a 20 by 20 box.
- States: to come = the shape in `mist`; the current = the shape outlined in `ink` 2.2 on `paper`; done = the shape in `sparkTint` with a `sparkDeep` 1.2 outline and the **gold four-point spark** inside, so done still reads by the spark, in every room.
- **Counting Hills only**: socket *i* (from the start side) sits 1.4 × *i* points higher, so the trail climbs like the staircase (8 sockets rise 9.8, inside the pill).
- It still fills right to left (design-spec §8).

### 3.4 The landmark

The landmark is **always on the screen, whole, in a place of its own**: never under the stage's content (where the first build put it, and where a reaction could not be seen: QA's D1), never over the content or over a touch target, on every board and for every layout the templates give the stage. It has a guaranteed least size of **56 board points on its short side** (the small phone's header slot; 64 on the other boards). The place is worked out by `LandmarkSlot` from the board and the item's layout only (never the line in the bubble, never whether a host is in front), so the landmark does not move while an item is on.

| Board | Where | Size |
|---|---|---|
| Phone | the **header**, between the progress trail and the home button, level with the buttons. The trail's room ends before it (`ActivitySpec.trailRoom` with `endReserve`: the trail is 72 points shorter, and a long lesson shows its window of sockets sooner) | 64 |
| Phone SE | the same | 56 |
| Tablet landscape (the six lands and the three courses alike) | **beside the card**, in the empty column at its end (left) side, standing on its bottom line, 24 from the card (the default card at x 288: x 114 to 264, y 384 to 534), with a ground shadow (`world.shadow`, lands only). A template with a wide card (24 to 872) or a tall one leaves no column: the first free place down the end-side margin (x 24), nearest to the card's bottom line first, smaller as the room allows (150, 127, 105, 82) | 150 |
| Tablet portrait | the first free place down the end-side margin, under the tiles (the card, the bubble's column and the microphone fill the rest above): x 24 to 142, y 808 to 926 | 118 |
| Any board with no free place | the header's slot, as on a phone | 64 |

- **What it keeps clear of** (each with its tap margin and 4 points to spare): the header's buttons, the trail, the bubble's column, the stage and its rim or card, the box of the answer tiles, the corner with the guide and the host pair, the microphone and its confirm buttons. The reaction's glow stays inside its box and the 1.15 bounce is at most 8 points out of it.
- The old placements (the stage's end-bottom corner behind the content; a land's landmark outside the card on the landscape tablet only) are gone: the backdrop has no landmark layer, the corner's end-bottom corner stays empty, and a course's window no longer hangs on the wall of its stage but stands in the same place as a land's landmark.
- The landmark files replace the map icons (`world/stair.svg` and the others stay for the map). The course windows are files too (`eng_landmark.svg`, round; `heb_landmark.svg`, arched; `rus_landmark.svg`, square, four panes), each with a sill for its celebration piece and a view outside (a hill, a cloud).
- **Piece and reaction are overlays in the landmark's own box**: `<room>_piece.svg` and `<room>_reacted.svg` are drawn at the landmark's exact rect, over it. The reaction motion (5.1) animates the overlay in (fade, scale from the landmark's bottom centre, the dot's hop); its end state is the file.

### 3.5 Frames on the tablets

The stage card stays `paper` with radius 28; it gains a **4 pt border** in the room's rim colour, and its 6 pt lip becomes the room's `deep` (Colour Bay: the `cardLip`). The backdrop fills the card's inner box (16 in) with radius 16.

### 3.6 Tokens to add (the developer runs `dart run tool/gen_tokens.dart`)

```json
"color": { "course": {
  "eng": { "fill": "#2C6FB8", "deep": "#1F5590", "tint": "#E1ECF8", "window": "round" },
  "heb": { "fill": "#D25E4E", "deep": "#A63A2C", "tint": "#FBE4DF", "window": "arch" },
  "rus": { "fill": "#6D49B3", "deep": "#55358F", "tint": "#EBE3F7", "window": "square" },
  "$note": "The language rooms (M11). fill = the door's panel in app/assets/art/languages/door_<c>.svg; deep carries white text at >= 5:1; tint = the room's screen."
}}
"layout": { "<board>": { "hostFront": [x, y, size], "companionBack": [x, y, size], "hostBubbleRight": n } }
```

with the numbers of 2.2. The fills are the doors' own panel colours; white on each `deep` is above 5:1 (eng 7.6, heb 6.4, rus 9.2).

---

## 4. The celebration per room (step 1.4, `LessonCelebration`)

| | Phone, phone SE | Tablets |
|---|---|---|
| Card | width min(board − 80, 520), radius 28, **4 pt border in the room's rim**, lip 6 in the room's `deep`, `e3` | width 640 |
| The room's window (top of the card) | 12 inside, full width, **140 high** (SE 124), radius 20: the room's backdrop (3.2, without its landmark) | 220 high |
| Landmark | 104 at the window's end side, on its ground, with a `sparkTint` glow; its **new piece** (`<room>_piece.svg`) drawn over it in the same box; a course window hangs on the wall at 0.66 of the window's height, 6 from its top | 160 |
| Host, `celebrate` pose | the box is the biggest (150 at most, 220 on a tablet) in which the **whole pose** is inside the window with 4 points of air above its hop: the figure spans 8 to 474 of the box's 512 (measured on all 36 pictures; the giraffe's celebrate is the tallest) and the hop lifts it 7% of the box, so the phone's box is 130, the small phone's 114, a tablet's 205; centred a little to the end side, feet 8 points above the window's bottom | up to 205 |
| Companion, `celebrate` | nine tenths of the host's box (117 on the phone), beside the host on the start side, on the same ground line | 185 |
| Sticker (if earned) | as today (88 die-cut), at the window's top start corner | as today |
| Praise line | Heebo 600, 26 (tablet 32), centred, under the window | |
| Home | the spark pebble, **72** (tablet 88) | |
| Scrim | `scrim`, as today | |

- **The host's box never reaches more than 10 points above the window** (2026-11-15, QA found heads cut): phone 150 in 140, tablets 236 in 220 (`150 * k`), and **phone SE 134** (not 150) in its 124 window. Every celebrate pose keeps its whole figure at y ≥ 72 of its 512 artboard (section 7.2), so with these boxes nothing is cut, at rest or at the top of the hop (7% of the box). Looked at in a simulation of the window: `docs/design/m11/celebration_windows.png` (the four rows: phone at rest, phone at the hop's top, SE with 150, SE with 134).
- The card's total height on the phone is 140 + 12 + 46 + 10 + 78 + 20 = 306 plus 24 padding: it fits 393 and the SE's 375 with the line on one line; a two-line praise line takes the window down to 116.
- The host says its cheer (an edge line, voiced later; text until then) after the companion's praise line, never over it.
- `board_celebration()` in the script is the reference; `counting_hills_phone.png` and `robot_harbour_phone.png` show it.

---

## 5. Motion

All durations by the band's `transition` (A 450, B 350, C 280) unless written; entrances `springOut` with the band's overshoot, exits `exit`, nothing faster than 3 Hz, one focal motion at a time. Reduce motion (`MediaQuery.disableAnimations`) replaces every movement with a cross-fade of at most 120 ms or the end state.

| Moment | Motion | Reduce motion |
|---|---|---|
| Host enters | walks in from the start edge to the front: x from off-screen to its box, two small hops (squash 0.94 / stretch 1.04 on each landing); at the same time the companion moves to the back place and scales to its box (`standard`), turning to `listen` | the host fades in at the front, the companion fades to the back place (120 ms) |
| Host hands over | host `talk` → a nod, then walks out to the start edge (`exit`); the companion grows to the front with the band's overshoot | cross-fade 120 ms |
| Host's pointer | as the B-40 worked-example hand today (same path and timing); it enters from the stage's bottom edge and leaves the same way | it appears at each place it touches, no travel |
| Speaker change inside a beat (tail moves) | the tail slides along the bubble's edge 120 ms; the new speaker lifts 6 and goes `talk` | the tail jumps |
| **Stage reaction** | see 5.1 | the end state appears (fade 120 ms) |
| Celebration | the card as today; then the landmark's new piece draws as a dashed outline (300 ms) and fills with a 1.1 squash (300 ms); host and companion hop twice (two × 400 ms), one after the other, not together; the sticker pops as today | the card with everything in its end state, one `sparkTint` glow on the new piece |

### 5.1 The stage reaction (step 1.5)

- **When**: on the answer's correct feedback, 220 ms after the check badge pops (so the child sees the check first), on every solved item: at any hint level, after a worked example finished by the child, after the last step of a Show. **Never** before the answer is accepted, never on a wrong one, never on a background tap.
- **How long**: at most **900 ms**, then the **end state** stays until the item leaves (the page turn takes it away). The next item starts with the plain landmark: **nothing accumulates**, nothing is counted, nothing is lost.
- **Where**: at the landmark, which stands in its own place (3.4) and is drawn at rest too. For its duration it is scaled 1.0 → 1.15 → 1.0 around its bottom centre, with a `sparkTint` glow that stays inside its box; the end state stays on it.
- **One focal motion**: the reaction waits for the tier-1 correct motion to end and never runs during a voiced line's first word.

| Room | Motion (≤ 900 ms) | End state |
|---|---|---|
| Counting Hills | a coral dot (`numbers.fill`, ink outline) hops up the four steps (4 × 150 ms), the top step fills `spark` (300 ms) | `numbers_reacted.svg`: the dot on the lit top step |
| Colour Bay | a white drop falls from the shell's rim into the pool (300 ms), the shell's ribs light up in the rainbow's colours from the end side to the start side (9 × 40 ms) while a splash crown rises and two ripple rings grow (600 ms) | `colors_reacted.svg`: the rainbow shell, the splash crown, two rings and three sparks; it covers the whole shell, so even a corner of the landmark left uncovered shows the change, by shape (splash, rings, sparks) as well as by colour |
| Shape Forest | a small fir grows from the ground at the landmark's end side, scale from its base 0 → 1.1 → 1 | `shapes_reacted.svg`: the small fir |
| Riddle Grotto | the door's circle, square and triangle light in turn, top to bottom (3 × 200 ms), then the door's arch glows (300 ms) | `logic_reacted.svg`: the three lit shapes and the glowing arch |
| Robot Harbour | a crate rises on the hook's line and the trolley sets it on the quay between the legs (lift 500 ms, set 200 ms, squash) | `cs_reacted.svg`: a big orange crate (100 of the box's 200 wide, 66 high: about 28 by 18 points at the phone's 56-point landmark, 40 by 26 at the tall robot stage's 79) on the quay between the legs, four slings up to the lowered hook, sparks. It needs the landmark drawn above the stage's content for the reaction (3.4), or it is hidden by the robot grid |
| Market Village | a gold coin arcs into the jar on the stall (500 ms), the jar bounces | `math_reacted.svg`: the coin in the jar |
| English, Hebrew, Russian | the window's glass warms from the sky to #FFE7A0 and a sun rises in it (600 ms) | `<course>_reacted.svg`: the lit window with its sun |

The reaction's sound (a chime, a per-land instrument) is item 6, later; the voice-and-sound-director gets the timings above.

### 5.2 Goni's colours: the chameleon moment (the owner's decision of 2026-11-15)

The owner: Goni, drawn in grey stripes in Colour Bay until now, "should get colour, since he's a chameleon maybe he can change colours". Kept simple: **one resting look of his own, and one moment after a right answer.**

**Resting look ("mint").** Skin #7FD3B0 (his approved body colour, the same on the door, the map and the stickers), shade #5DB894 (far legs, tail), four darker bands #3E9E80, a pale belly and jaw line #C9EFDD, and a dark-teal outline #2B7A63 round his whole silhouette (6 of 512, about 2 points at the phone's 168 box). Mint is none of the 11 lesson colours (CIE76 ΔE from the nearest, green #4CAF50: 37; from white 41; from grey 43), so he never looks like an answer. His eyes (cream rings with an outline in his rim tone, ink pupils), mouth (lip pink, ink inside), cheek, plum beret (with its own darker edge #7A2C52), sparks and shadow never change colour. The old pastel crest (peach, cream, blue, lilac) is gone from his skin: four colours on the host during a colour question were four distractors. His rainbow now comes out only when he is happy (the ripple).

**The moment.** After a right answer is accepted, and only then, his skin becomes the colour the child just found: skin, shade, stripes, belly and outline all change together, by one table (below), and he goes to `celebrate` at the same time, so the change always comes with a shape change (the leap, the closed happy eyes, the open mouth) and the check badge: **colour is never the only cue**. He holds the colour while the praise is said and then eases back to mint.

- **Which colour**: the correct option's picture names it: the last `_` part of its sprite id (`asset:balloon_red` → red), the same lookup as `_colourOf` in `app/lib/play/hints/spot_plans.dart`, against the 11 names of `hintColours`. **Exactly one name** → that skin. **No name or several** (sorting into bins, rainbow order, shades such as `shade_blue_2`, a pattern) → the **rainbow ripple** instead. A mix whose single answer is a colour picture (`purple`) takes that colour like any other item.
- **When Goni is on screen** (section 2.1: the host is not on screen during the child's turns): (a) the child's last step of a Show; (b) the lesson's celebration card, where he takes the lesson's colour: the one skin if every scored item of the lesson resolved to the same name, else the ripple ("all the colours you found").
- **The rainbow ripple**: his skin stays mint and his four bands and the four spots on his tail take the rainbow (`rainbowOrder`: red, orange, yellow, green, blue, purple; band *i* has colour *(i + k) mod 6*, band 0 nearest the head), stepping k = 0, 1, 2, 3 every 350 ms with a 120 ms cross-fade between steps (under 3 Hz, section 5), then holding k = 3 through the praise. It runs from his head to his tail, a direction of his body, not of reading, so it never mirrors.

| Skin | skin | shade | stripes | belly | outline (rim) |
|---|---|---|---|---|---|
| **mint (resting; the sentinels in the files)** | #7FD3B0 | #5DB894 | #3E9E80, #3E9E81, #3E9E82, #3E9E83 | #C9EFDD | #2B7A63 |
| red | #E5484D | #B8323A | #9A2630 | #F6AEB0 | #7A1C24 |
| orange | #FF9F43 | #D9762A | #B85E1C | #FFD6AE | #8C4512 |
| yellow | #FFD84D | #E0A21A | #C98A10 | #FFF1B8 | #8A5E0A |
| green | #4CAF50 | #2F8A3A | #23702D | #AEDDB0 | #1A5422 |
| blue | #2F7FE0 | #1F5DB0 | #184A8E | #A9CBF5 | #123A70 |
| purple | #9B6BDF | #7246B8 | #5A3596 | #D6C4F3 | #432672 |
| pink | #F48FB1 | #D9668F | #C04E78 | #FCD6E3 | #94345A |
| brown | #8A5A2B | #66401C | #4E3014 | #C9A27C | #3A230E |
| black | #2B2540 | #171424 | #4C4568 | #3E3858 | #9A93BA |
| white | #FFFFFF | #E2DEEC | #CFC9DF | #F4F2F8 | #8A82A6 |
| grey | #9AA0B4 | #767C92 | #5F6579 | #CDD0DA | #474C5E |

Skin and shade are the activity pictures' own fill and shade (`tools/make_logic_sprites.py` `COLOURS`, the same values as `hintColours`), so Goni turns exactly the colour of the balloon the child tapped, not a near one. The four stripe sentinels differ only in their last digit (they look the same); in a skin all four map to the one stripe colour, in the ripple each takes its own. **Outline rules**: the rim is always well darker than the skin (2.5:1 to 4.1:1 on its own skin), except on **black**, where rim, stripes and belly are lighter (the rim 5:1 on the black skin), so his bands, his edge and his closed-mouth line show; **white** gets a lilac-grey rim (#8A82A6, 3.6:1 on white) so he stands out on the pale tint, sky and sand. Every line drawn on his skin (the closed mouth, the edge of the open mouth, the eye rings) is in the rim tone, so it follows the skin. The table is in `docs/design/m11/make_host_poses.py` (`GONI_SKINS`, `goni_map`), which also prints these numbers.

**Timing.**

| | Show's last step (on the stage) | Celebration card |
|---|---|---|
| In | the colour cross-fades in **250 ms** (`standard`), starting with the check badge, together with the pose change to `celebrate` **without the hop** (the stage reaction at the landmark is this moment's motion, section 5.1) | the colour cross-fades in **250 ms** at the start of his first hop |
| Hold | through the praise line | until the card closes (it never goes back on the card) |
| Out | **400 ms** cross-fade back to mint (`standard`), the pose back to `talk` or `idle`, as soon as the praise ends, and **always before the next item's prompt**: if the page turns first, he is mint on the next page (no fade) | |
| Ripple | 4 steps × 350 ms (120 ms cross-fades), then holds k = 3; out as above | the same, during and after the hops |
| Reduce motion | a plain cross-fade in (250 ms) and out (400 ms); **no ripple**: one still rainbow frame (k = 0) fades in and out | the end state (the skin or the k = 0 frame), no fade |

**Never**: before the answer is accepted, on a wrong answer, during the question, the host's own Show steps or the Together lead-in, on a tap on Goni (he is never a target), or carried into the next item. The voice-and-sound-director gets these timings (a soft shimmer under the 250 ms change would fit; no new sound is asked for here).

**Mechanism (no new package, the least code).** `flutter_svg` 2.3.2 (already in `pubspec.yaml`) has `ColorMapper`, which swaps colours while the SVG is parsed: `SvgPicture(SvgAssetLoader(asset, colorMapper: mapper))`. The four files keep the sentinel colours above (listed in each file's header comment), so with no mapper they draw mint, which is also how the door, the map and the stickers see him. No string replacement and no tint filter (a `ColorFilter` would also tint his eyes and beret, and cannot give a black Goni a lighter outline).

**Build list (app-developer):**
1. `HostSpec.goni`: drop `safe: true`, so `asset()` gives `assets/art/hosts/goni_<pose>.svg` (the four files are there). Delete the four `goni_*_safe.svg` and the `goniColorSafe` token group when nothing uses them.
2. A `GoniSkin extends ColorMapper` (const, `==` and `hashCode` on its name and ripple step, because the SVG cache keys on the mapper): `substitute()` returns the table's colour for the 8 sentinels and every other colour unchanged. Skins: the 11 lesson names; ripple steps 0 to 3.
3. `HostView` gets an optional `skin` (null = mint). The picture's `AnimatedSwitcher` key becomes (pose, skin); its duration is 250 ms when a skin comes in, 400 ms when mint comes back, 120 ms between ripple steps (a pose-only change stays 140 ms). Reduce motion: the same cross-fades, no ripple. The celebrate hop is skippable (off in the Show's last step).
4. The answer colour: one function from the item (the correct option's sprite id → a name in `hintColours`, else null = ripple), reusing `_colourOf` (moved where both can use it). The card's colour: the single name if all the lesson's scored items share it, else the ripple.
5. The trigger: the correct path's single reaction hook (section 9, item 6) also sets Goni's skin when the room is Colour Bay and the host is on screen (the Show's last step); the celebration card passes the lesson's skin. Never set on a wrong answer, never before acceptance.
6. Hold and release: clear the skin when the praise line ends (its audio, or its text time when there is no clip), and unconditionally on the page turn, so the next item always starts mint.
7. Precache: when a Colour Bay lesson starts, warm the SVG cache for `celebrate` and `talk` in the skins that lesson can need, and the 4 ripple frames (`svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null))`), so a change never shows an empty frame while parsing.
8. Tests and goldens: `GoniSkin` maps all 8 sentinels and leaves ink, lip, tongue, beret, eye ring and spark alone; the skin is null on a wrong answer, before acceptance and on the next item; goldens `m11_goni_celebrate_red_phone`, `_white_phone`, `_black_phone`, `_ripple_phone`, `_ripple_reduce_motion_phone` (end states), and `m11_room_colors_show_phone` re-taken (mint instead of grey).

**Built (2026-11-15, app-developer).** Items 1 to 8 are in `app/lib/rooms/goni_skin.dart` (`GoniSkin`, `answerColour`, `skinForAnswer`, `skinForLesson`, `skinsForLesson`, `precacheGoni`), `app/lib/rooms/host_view.dart` (`HostView.skin`: the picture's key is (pose, skin); 250 ms in, 400 ms out, 120 ms between ripple steps, 140 ms for a pose alone; a host that appears wearing a skin arrives in mint and takes it a frame later, or has it at once with reduce motion; the ripple is stepped by the view's own clock, 350 ms a step, holding step 3, and is step 0 only with reduce motion) and `app/lib/play/goni_moment.dart` (`goniSkinFor`, which is the controller's `solved` after a right answer to a scored item, in Colour Bay only, and `goniCardSkin`). The four `goni_*_safe.svg` files are deleted; the `goniColorSafe` token group is still in `design/tokens.json` (the design-director's file; nothing in the app reads it). One point to know: in Stage 1 the host stands in front only at the greeting and the cheer, so the answer-colour hook (`_scene` passes `goniSkinFor` to the host's view) is wired and tested but is seen in a lesson only when Stage 2's Show puts Goni on screen after a right answer; what a child sees now is the lesson's card, and `m11_goni_after_answer_red_phone` is the composed frame of what the Show's last step will look like. The celebrate hop is skippable (`HostView.hop: false`), for the Show's last step.

Looked at: `docs/design/m11/goni_colours.png` (the four poses in mint on `colors.tint`, on paper and on the map's cream; celebrate in the 11 lesson colours and the ripple frame at 196 px; all 12 at 96 px in colour and in grey; talk and still in white, black, yellow, grey and pink on the tint and on the bay's sand), `goni_poses.png`, and the still, the ripple frame and a white `show` at 512 px. Not looked at: the running app, the motion itself, a real phone. Still to do: Goni on the four home maps (and their language variants) and stickers 01 and 08 still has the old pastel crest; they take the mint look the next time `tools/make_home_map.py` and the sticker art are re-run (his body colour is already the same).

---

## 6. With the language rebuild (L7 Meet and Find)

One system: the course rooms are three of the nine rooms; a course lesson's **Meet** is its Show (the host's), **Recall, Find and Use** are the child's turns (the companion's). Points of `docs/design/l7-meet-find.md` that must change:

1. **§3.1 beats, the Guide column**: the speaker of M0 to M5 is the **course host** in the front, the companion in the back place in `listen`. M0's `wave` becomes the host's entrance (2.5) on the first screen of a set.
2. **§3.1 M4 "let's say it together"** (f03) is today the companion's clip; in a Meet it becomes the **host's** line (three new host lines, one per course, needs-editor; text until voiced). The companion keeps f03 for every other use.
3. **§3.1 M6 close**: the microphone's `heard` and `together` lines stay the **companion's** (feedback); the tail moves to the companion in the back place (2.1 rule 3). "I said it" still closes silently.
4. **§3.6 idle**: the idle prompt re-voices the host's M4 line; the hand stays absent.
5. **§4.1 layout**: "the frame's pieces do not move" becomes "the frame's pieces do not move between the screens of a set"; in a Meet the corner holds the pair (2.2) and the bubble's right edge and width take the host-beat values (phone 591 and 178: the bubble may grow down to about 240 as L7 allows, it keeps clear of "I said it" at 256 by the frame's own rule). "I said it" and the microphone keep their L7 places; the back place is clear of both on every board.
6. **§4.1 Meet stage**: the Meet card stands on the course's backdrop (3.2); on the phones the strip column covers the window landmark's corner; the tablet portrait's taller card (420) keeps the window inside its backdrop at the end-bottom.
7. **§6 Find**: unchanged in behaviour; the host is not on screen. The hand-over (2.5) happens between the last Meet screen of a set and the first Find screen, inside the normal activity transition.
8. **§7 motion**: add the host's entrance (first Meet screen of a set) and the hand-over before Find; between the Meet screens of a set nobody moves (as L7 already says for the frame).
9. **§1 point 4 and §10.6, one socket per set**: the socket takes the course's shape (porthole, arch, square window).
10. **§12 goldens**: every Meet golden gains the host in front and the companion behind, on the course backdrop; regenerate them after both branches merge (M11 §8 order: L7 first).
11. **§2 speaking badge**: unchanged; the host has no pointer on a Meet screen (the picture speaks for itself).

Recall (the warm-up of old words) is a child's turn: companion only.

---

## 7. The pose sheet (step 1.2: 27 drawings, Nekudi's 3 done)

### 7.1 The three poses

| Pose | Used in | What it shows |
|---|---|---|
| `talk` | greeting, Show between actions, lead-ins, hand-over | mouth open (dark interior, pink tongue, design-spec §4.1), the end-side hand raised in a small explaining gesture, eyes toward the end side |
| `show` | whenever the host's pointer acts | the **worked-example hand** held out level toward the end side (the task), the head turned and the eyes on that hand, the body leaning 3° toward it; the other hand **at rest inside the figure's outline** (it must never reach a friend standing behind) |
| `celebrate` | the celebration card | a hop (feet 22 above the baseline, the shadow stays on it, smaller), both hands up, happy closed eyes, open smile; one species-true flourish (Nekudi's shell halves lift and her wings peek out, as a ladybird's do before it flies) |

`idle` stays the existing still (`design/assets/<host>.svg`); `listen` (the host's wait in the child's last Show step) is the still with the eyes turned to the stage: the developer uses the still for both until the full rig (Rive) exists.

### 7.2 The artboard and the anchors (design-spec §4.9.2, unchanged)

- 512 × 512, baseline y 472, centre x 256, the figure at most 400 high (**`celebrate`: everything, sparks too, at y ≥ 72**, so it stays inside the celebration window, section 4; `make_host_poses.py` scales a taller celebrate pose about (256, 472) until it fits, Nekudi's sample by hand: Gosha 0.85, Tza'adon 0.87, Alfi 0.90, Kubi 0.90, Nekudi 0.92, Pip 0.95, Pnina 0.96); **faces left** (front or ¾ with the gaze to the left), never mirrored at runtime (a `flip` would mirror the hand).
- Same palette as the still (`color.character.<host>`), at most six fills plus `ink` and white, no outline (the cast's stills have none), one shade tone. No text, no letters, no numerals in a pose.
- Each file names its groups: `head`, `mouth`, `hand` (show only), and the body parts. The anchors are written in an XML comment in each file and copied into the host pack:

| Anchor | Nekudi talk | Nekudi show | Nekudi celebrate | Rule for every host |
|---|---|---|---|---|
| `mouth` (tail target) | 256, 268 | 252, 262 | — | the centre of the open mouth |
| `hand` (pointer tip) | — | 46, 310 | — | the tip of the worked-example limb, at 50% to 65% of the height, x ≤ 72 |
| `feet` | 256, 466 | 250, 466 | 256, 466 (shadow) | on the baseline |
| `burst` | — | — | 256, 104 (fitted, below) | above the head |

### 7.3 The worked-example hand of each host

| Host | Limb | References to look at before drawing |
|---|---|---|
| Nekudi (ladybug) | end-side front leg, the ball foot is the tip | done (below) |
| Goni (chameleon) | front foot, its two bundled toes | chameleon feet (zygodactyl grip), tail curl |
| Kubi (tortoise) | front leg, three blunt nails | tortoise forelimbs (scaled, elephant-like), shell scutes |
| Timi (octopus) | a free arm's curled tip, suckers on its underside | octopus arm tips and sucker rows |
| Tza'adon (robot) | arm with a round two-part gripper | toy robot arms (only his own design) |
| Grandma Pnina (pelican) | wing tip, the primaries fanned like fingers | pelican wings in flight and folded, pouch |
| Pip (budgie) | wing tip, primaries fanned | budgerigar wing bars and flight feathers |
| Alfi (the hyrax) | **the tip of its coral pencil** (it already holds it) | rock hyrax paws and posture |
| Gosha (the giraffe) | front hoof | giraffe legs, cloven hooves, ossicones |

### 7.4 Files

- Drawings: `design/assets/<host>-talk.svg`, `-show.svg`, `-celebrate.svg` (lands: `nekudi`, `goni`, `kubi`, `timi`, `tzaadon`, `pnina`; courses: `host-eng`, `host-heb`, `host-rus`). The bundled copies: `app/assets/art/hosts/<host>_<pose>.svg`.
- **Generated, not drawn**: the stage pointer `app/assets/art/hosts/<host>_hand.svg`, cut from the show pose's `hand` group, scaled to a 64 by 64 box with the tip at the top (a small tool, the developer's, once the poses exist); Goni's four files `app/assets/art/hosts/goni_{idle,talk,show,celebrate}.svg` are written by `docs/design/m11/make_host_poses.py goni` together with `design/assets/goni*.svg` (the same files), in his recolourable skin (5.2); the old `goni_<pose>_safe.svg` (grey) are retired: the tool no longer writes them, and the developer deletes them when `HostSpec.goni` stops using them. `world/pool_safe.svg` is not needed: Colour Bay's landmark is its own drawing (since 2026-11-15 a vivid one).

### 7.5 Nekudi's sample (this run)

Files: `design/assets/nekudi-talk.svg`, `design/assets/nekudi-show.svg`, `design/assets/nekudi-celebrate.svg`. Looked at in `docs/design/m11/nekudi_poses.png`: at 280 px beside the still, at the phone's 168 on her tint, and as 48 pt silhouettes (each pose reads as her, and the three differ). References (2026-11-14, nothing traced): Wikipedia "Coccinella septempunctata" and "Coccinellidae" (domed oval elytra meeting at a straight suture, short jointed legs with a knee, clubbed antennae, hard elytra covering the folded hind wings); photographs of walking seven-spot ladybirds reaching a leg onto a grass blade, and of take-off with the elytra lifted apart and the clear wings unfolding (Bing image search). What changed from the still, on purpose: her legs now bend at a knee, and in `celebrate` her shell opens a little to show her wings.

---

## 8. Right to left

- The interface is right to left: the corner at the start (right), the host entering and leaving at the start edge, the back place on the outer (start) side, the trail filling from the right.
- Never mirrored: the ten-frame (fills left to right), number lines, clocks, the robot's arrows and its program (read left to right, absolute directions), the pose files (a host faces the task, left; its hand would swap if mirrored). The staircase landmark already rises toward the end (left), the forward direction of the interface, and its trail climbs the same way.
- English and Russian words stay in their left-to-right isolated chips (L7); the room changes nothing there.

---

## 9. For the app-developer (not obvious from the tables)

1. **The room comes from the activity's domain** (the skill id's land: NUM, COL, SHP, LOG, CS, MATH) or the course (`eng`, `heb`, `rus`); one `RoomSpec` (tint, rim, deep, backdrop painter, landmark, trail shape, host id, reaction) looked up once per lesson. A Today's Adventure stop takes the room of its own land.
2. **The backdrop swap is by value**: `asset:meadow` → the room's painter; any other background stays.
3. **Who speaks is a field of the beat**, not of the screen: `speaker: host | companion`, set by `lesson_controller.dart` from the part (Show, the Together lead-in, the greeting and the cheer are host; everything else companion). The frame draws the pair when the speaker is the host or when a host beat is not finished, and the companion alone otherwise. The tail's target is the speaker's `mouth` anchor in board points.
4. **The microphone is never shown in a host beat of a land lesson**; in a Meet it appears at M4 as L7 says. A Together item shows its microphone only after the hand-over.
5. **The host's pointer replaces the B-40 hand only in host beats**; the hint ladder in a child's turn keeps the glove.
6. **The reaction hook**: one call on the template sessions' "correct" path (after the check badge), the same for all templates; it is not called by the worked example's own moves, only when the item is solved. A test: the reaction count per item is 1 on a right answer and 0 on a wrong one; it never shows on the next item.
7. **Until a host's poses exist** (24 drawings to come) the frame uses the host's still for all three poses; the layout does not change when the poses land (same artboard and anchors).
8. **Goni in Colour Bay** has colour (the owner's decision of 2026-11-15): his normal files in his mint skin, recoloured by the app after a right answer; the build list is in section 5.2. The companion's `colorSafe` skin in Colour Bay is unchanged (not part of this decision).
9. **Voice**: every host line shows as text until the owner voices it (M11 §9 Q2). The pair still moves at the beats, so a lesson without host clips looks and paces the same.
10. **Assets**: add `assets/art/rooms/` and `assets/art/hosts/` to `pubspec.yaml`; 63 room files plus 4 Goni files.
11. **Accessibility**: the host is announced once at the greeting ("<host's name>", a label from `he.dart`, needs-editor); the landmark and the reaction are decoration (excluded from semantics); the trail's label is unchanged (it counts items, not shapes).

---

## 10. Goldens to add (developer; QA re-runs them in step 1.6)

In a new `app/test/golden_m11_rooms_test.dart`:

1. `m11_room_<room>_show_<board>`: the host beat (host in front, companion behind, empty stage with backdrop and landmark, the trail with 2 of 6 done): 9 rooms × phone, phoneSE, tabletLandscape = 27; plus tabletPortrait for Counting Hills and English.
2. `m11_room_<room>_alone_phone`: the companion alone, the same room: 9.
3. `m11_room_<room>_reacted_phone`: the reaction's end state after a right tap: 9; and `m11_room_numbers_reacted_phone_reduce_motion` (reduce motion on, same picture).
4. `m11_celebration_<room>_phone`: 9; plus `_phoneSE` and `_tabletLandscape` for Counting Hills and Robot Harbour.
5. `m11_meet_eng_m3_phone` and `_tabletPortrait` (after L7 merges): the course host in front on a Meet screen with the strip.
6. A **greyscale check** (a test, not a golden): the 27 host-beat goldens converted to grey differ pairwise by more than a set share of pixels within each board (acceptance criterion 1).
7. A text-scale 1.3 run of `m11_room_numbers_show_phone` with the longest host line: the bubble clear of the stage and of the pair.

---

## 11. Missing art and other hand-offs

**Art (design-director, model Opus, after the owner's yes on the Nekudi sample):**

| What | Count | Notes |
|---|---|---|
| Host poses | **24** (8 hosts × 3) | Nekudi's 3 done here; references per 7.3 first |
| Celebration growth pieces | 9, **drawn** | `app/assets/art/rooms/<room>_piece.svg` |
| Reaction end states | 9, **drawn** (the crate and the jar among them) | `app/assets/art/rooms/<room>_reacted.svg` |
| Backdrops | 9 rooms x 4 layers, **drawn** | `<room>_far.svg`, `_ground.svg`, `_top.svg`, `_corner.svg` |
| Richer landmarks | 9, **drawn** (6 lands and 3 windows) | `<room>_landmark.svg` |
| Goni, recolourable | 4, **drawn** (2026-11-15) | `app/assets/art/hosts/goni_<pose>.svg`; the 11 skins and the ripple are colour mappings (5.2) |
| Stage pointers | 9, to generate | after the poses; a tool step |

**Hand-offs:**
- **app-developer**: sections 2, 3, 4, 5, 9; the tokens of 3.6; goldens of section 10.
- **hebrew-text-editor**: the host lines (greeting, hand-over "now you!", cheer: the ~90 edge lines of step 1.3) hold **two lines at the band's size in a 178-point bubble on the phone** (about six words); the three host versions of "let's say it together" (6.2); the hosts' names as screen-reader labels.
- **voice-and-sound-director**: the motion timings of section 5 (entrance about 450 ms, hand-over, reaction ≤ 900 ms starting 220 ms after the check) for the later chime; the host's cheer comes after the companion's praise line, never over it.
- **curriculum-expert**: confirm that the child's last step of a Show is the host's beat (a wrong touch there is the host's "let's look again", not the companion's not-yet), and that a Meet is the course's Show.
- **qa-engineer**: step 1.6 with section 10.
- **Needs the owner**: `docs/design/m11/nekudi_poses.png` (the host sample, before the other 24 drawings), `docs/design/m11/counting_hills_phone.png`, `docs/design/m11/robot_harbour_phone.png`, `docs/design/m11/nine_rooms.png`. One decision is his to confirm: the host teaches **from the friend's corner** (in front, with the companion behind), not from the stage's edge as the plan first said (reason in 1.4).

---

## 12. What I looked at, and what I did not

**Room art run (2026-11-14, second run).** Looked at, at full size: the nine `room_<room>.png` boards (every cell), `nine_rooms.png` and `nine_rooms_grey.png`, `counting_hills_phone.png`, `robot_harbour_phone.png`, and a contact sheet of every landmark with its piece and reaction and every corner at 200 px. Fixed on the way: corners clipped by the stage's rounded corner (now 6 in), Colour Bay's boulder that read as a ghost (now a scallop shell), firs that read as plain triangles (now tiered), the harbour's thin jib crane (now the map's gantry crane), the stall's awning stripes lost on white, a row of four stepping stones, a ring-pattern rug and nine pegged sheets that a child could count, the Russian rug that read as a grille. References (nothing traced): photographs of container and fishing harbours (gantry cranes, containers, bollards, fenders, a lighthouse), Mahane Yehuda stalls, the Soreq stalactite cave, cypress and fir woods, kindergarten reading corners; facts from Wikipedia (Stalactite, Cupressus sempervirens). Not looked at: the art inside the running app, the motion, the real phone.


Looked at, at full size: every board above (the four Counting Hills phone boards, the three Robot Harbour boards, the host beat on all four boards, the nine rooms in colour and grey) and Nekudi's sheet; an enlarged crop of the reaction's end state and the stair trail. Fixed on the way: the show pose's resting hand reached the companion's face (moved inside her outline); the portrait pair overlapped the bubble (host moved to 572 and 184); the Show's tray covered the landmark on the phone (smaller frame). The goldens `lesson_2_count_three_answers_{phone, tablet_landscape, tablet_portrait}`, `lesson_6_celebration_phone`, `activity_phone_se`, `c1b_give_frame_phone`, `hint_robot_l2_phone`, `hint_robot_l3_tablet_landscape`, `hint_sort_l3_{phone, tablet_portrait}`, and the hosts, doors and landmarks as a contact sheet.

Not looked at: anything in the running app (no Flutter run or test was made); motion (the boards are still frames); the real phone (the owner can). The boards place the frame's pieces at the measured `ActivitySpec` numbers, but a bubble that the frame shrinks or grows may sit a few points differently on a device. Tza'adon on the Robot Harbour boards is his still (his poses are not drawn yet); Goni and the pool in Colour Bay are simulated with a desaturation filter until their safe files exist.

**Fix run (2026-11-15, after QA of Stage 1).** Redrawn: Grandma Pnina the pelican (still and three poses, also on the four home maps, their language variants and sticker 04), Colour Bay's backdrop, landmark, piece and reaction (now the most vivid room), Robot Harbour's piece and reaction (a big crate). Every celebrate pose now fits the celebration window (y ≥ 72). References: `tools/make_room_art.py` and `docs/design/m11/make_host_poses.py` docstrings (Wikipedia "Great white pelican" and "Pelican"; Bing photographs of standing, spreading and close-up pelicans and their feet; colourful beaches with parasols and striped sails; crane lifts with slings). Looked at: `pnina_poses.png`, `room_colors.png`, `room_cs.png`, `room_math.png`, `nine_rooms.png`, the four Pnina files at 360 px, contact sheets of the Colour Bay and harbour landmark parts at 220 px, the nine celebrate poses with the y 72 line, a simulation of the celebration window (phone, hop, SE), the two tablet landscape maps. Not looked at: the app's goldens (regenerated by the orchestrator after the developer's layout fix), the running app, the real phone. For the developer: Colour Bay's `RoomSpec` takes `colors.tint`, `colors.fill`, `colors.deep` and the sky #A9DEF9 → #EAF8FD; the SE celebration host box 134 (section 4); Pnina's mouth anchors are unchanged (talk 150, 232; show 140, 238).
