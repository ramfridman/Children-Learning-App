# M12 Delight: the visual and interaction half (design-director)

**Status:** proposal for the owner's OK. Docs only, nothing built. The sound half is the voice-and-sound-director's
`docs/milestones/M12-sound-notes.md`; this document gives it the timing hooks (section 4.1.6).
**Why:** on 2026-11-19 the owner played the dev build with his 2-year-old daughter and said: "this app is not a child friendly at all.. The
sounds are very robotic.. no celebrations, nothing that makes the child excited when he plays the app."
**What was on his phone:** `D:/nitznutz-stage1` at fb39dc08 (M11 Stage 1). Everything below about feedback and celebration is also true of
the `lands-ux` tip (cadc6004): Stage 2 did not touch `stage_reaction.dart`, `room_celebration.dart`, `character_view.dart`,
`AnswerTile` or the praise pause. Stage 2 adds the Show before the first item, so the tip is slower to the first touch, not faster.

Storyboards (each frame is a real phone board, 852 x 393 points, drawn with the app's own art; generator `make_delight_boards.py`):
- `right_answer_count_phone.png`: today's right answer, then the new one frame by frame, the try-again and reduce motion.
- `party_counting_hills_phone.png`: today's lesson-end card, then the party in Counting Hills.
- `map_tap_phone.png`: today's map, then the tap toys, today's island calling a small child, and the glide into the room.
- `colour_bay_pilot_phone.png`: **the pilot land.** Today's Colour Bay item, then a P0 colour item, its right answer (Goni turns the colour),
  the errorless try-again, Goni's paint pots (free play) and the Colour Bay party.

**Colour Bay is the worked example and the pilot** (the owner played it with his daughter; section 1.4 walks it item by item, section 4.7
is the pilot). Every step of 4.6 ships in Colour Bay first, is played there by the owner and his daughter, and only then goes to the
other lands. The sound half (`docs/milestones/M12-sound-notes.md`) found that the app has no sound but the voice, read flat; this plan
uses its kit and event names (4.1.6) and does not repeat its audit.

---

## 1. The honest audit: what a child sees and feels

### 1.1 The first two minutes, moment by moment (fb39dc08, phone)

| Moment | What the child sees and can do | What moves, how long, how big | Any reward? |
|---|---|---|---|
| Opening the app | A plain cream screen while the database, pack and characters load (`app.dart` `_Root`: `ColoredBox(cream)`). | Nothing. No character, no sound. | No |
| Choosing who plays | The picker: avatar faces; she must find her own face. | The chosen card lifts. | No |
| The map | A still painted scene (`home_phone.svg`), land signs with **text**, an orange "today's adventure" pill with **text**, a bubble with **text** ("…, what is in the bottle?"), a grown-up "Parents" button with a lock. | The companion breathes (3.4 s sway, ±2.5 %) and waves once (1.6 s). The bottle bobs. | No |
| Touching the map | Only the land tap areas, the companion, the "+" and the pill answer. **The sea, the clouds, the palms, the islands' pictures and any land not ready do nothing at all.** | A tapped companion waves (1.6 s) and may say a line. | No |
| Entering a land | `LandScreen`: a flat oval island, the skills as small objects (88 down to **44** pt) on stones, a **text** title, a **text** legend ("practising / knowing / remembering"), a 72 pt Play pebble with a **text** label. A first visit shows grey sketches. Tapping an object opens a **text** card at 15–18 pt. | Nothing moves. Default page route (no glide). | No |
| The lesson starts | The host's greeting screen: at least **3 s** and until its voice ends (a tap skips it). On the tip a **Show** follows for a skill she is new to (a demonstration to watch; only the reminder Show skips on a touch). | The host talks. | No |
| The first item | The question is voiced and written in the bubble. On a count item she taps the butterflies: each lights, wiggles 1.3x for 250 ms and flies to the flower (550 ms). **This is the best-feeling moment in the app today.** | Objects 40 pt and up. | — |
| A tap on an answer tile | `AnswerTile` is a `GestureDetector.onTap`: **no pressed state at all**, nothing happens under the finger until it lifts and the answer is judged. | — | — |
| A right answer | The tile turns pale yellow, a **28 pt** tick appears at its corner (no pop). The companion (176 pt) changes to its celebrate picture and hops **10 % of its box (17 pt)** for 900 ms with **seven sparks of about 6 pt**. The room's landmark reacts, but on a phone it is the **64 pt picture in the header**, in the far corner, 220 ms later. A voice line. Next item after 1.6 s. | ≤ 1.1 s, all of it far from her finger except the tile's colour. | A voice line and a colour change. **No sound effect, no haptic, nothing on the stage.** |
| A wrong answer | A lilac ring on the tile (number tiles do not even wobble; only the language tiles do). The companion's encourage picture, a voice line, the first hint picture. | Little. | — |
| A hint / idle | After 2 s still (Band A) the question is said again, its place rings once (1.2 s) and a hand points into the stage. | Calm, correct. | — |
| A drag (sort, give-N) | Precise drags, or a two-step "tap the thing, then tap the place". The dragged thing does not lift, tilt or snap. | — | — |
| The end of the lesson | A white card on a **grey veil** over the lesson: a 140 pt window with the host and the companion (~130 pt) in celebrate poses, the landmark's new piece fading in with a 10 % squash, the sticker (88 pt) popping into the window's corner, **two lines of text** and one home button. | The piece: 900 ms. The sticker: an elastic pop. | The sticker, small, in a corner. **No confetti, no sound effect, nothing to touch but "home".** |
| A sticker / a medal / an island object | The sticker goes to the book in the child's home without being seen to go there. Medals and trophies get the one real ceremony in the app (`ceremony_screen.dart`: spotlight, spinning cup, confetti), but only for **lasting understanding**, which takes days. | — | Not in a first session. |

**Time from opening the app to the first touch that teaches:** four taps (face, island, Play, then the item) and, after the loading screen,
at least about 8 to 12 seconds of watching and listening on fb39dc08 (3 s+ greeting, the item's voiced question), and on the tip more,
because a full Show plays first for a new skill (an estimate from the code's pauses; the owner can time it on the phone). **Before that the
only things that answer a touch are the face card, the companion's wave and the press of a pebble button.**

### 1.2 Why he saw "no celebrations"
1. **The one celebration is at the end of a lesson**, a card with text, and a 2-year-old may never get there: Stage 1 lessons had many
   items, the greeting and the hints take time, and a toddler leaves after a minute or two. Even when she gets there, it is a still card
   on a grey veil with a button.
2. **The right-answer feedback is designed to be calm** (M11 rooms spec 5.1: "a short motion of at most 900 ms", "it is not counted"),
   and on a phone the room's reaction is a 64 pt picture in the top corner. Her eyes are on her finger.
3. **There is no sound effect and no haptic anywhere in the app** (searched: no `HapticFeedback`, no sfx player; the only audio is voice
   clips). So the voice line is the whole reward, and when the voice sounds robotic, the whole reward feels robotic.
4. **design-spec section 10 promised far more and it was never built.** 10.2 specifies a touch-down squash with a "tok", a drag that
   lifts and tilts, drop zones that breathe, a snap with a magnet and a haptic, a correct-answer badge pop with a sparkle ring and a spark
   that flies to the trail, a wobble for "not yet", a camera glide from map to land and a page turn between items. 10.3 specifies three
   celebration tiers, with "domain-glyph confetti" at the end of a lesson and a growth object that draws itself in. Built: the pressed lip
   of a pebble button, the companion's small hop, the landmark reaction, the ceremony for trophies. **The gap is the problem, not the spec.**

### 1.3 The five harshest findings
1. **Nothing answers a touch at the moment of the touch.** Answer tiles have no pressed state; the map's sea, clouds and islands ignore
   her; a land that is not ready swallows the tap. For a 2-year-old, a touch that does nothing is a broken toy.
2. **A right answer is a colour change and a voice line.** No sound effect, no haptic, no burst, nothing near her finger; the room's
   reaction is a 64 pt picture in the corner of a phone.
3. **The only party is a text card at the end, after a long road.** Grey veil, two lines she cannot read, one button. Real confetti
   exists only for trophies, which need days of lasting understanding.
4. **Too much reading and watching before playing.** Text signs, a text pill, a text legend, a text object card, a 3 s greeting and on the
   tip a Show; four taps through three screens before the first item. The land screen is a parent's progress view shown to a child.
5. **Nothing to do just for fun.** No free play, no toy that has no right answer, nothing to decorate, no way to play with the companion
   beyond a wave. Everything is a lesson, so everything can be "not yet".

### 1.4 Colour Bay as she met it (fb39dc08), item by item
The owner: "the sound only says a very not exciting phrase on which color is this.. nothing that makes a child excited at all", and "some
of the things she did fine and others wasn't very understandable to her and I had to help her." The content is `content/starter/`
`lesson.colour-match.json` (the first Colour Bay lesson on the path, sequence 2) and `lesson.colour-names.json` (sequence 3); Stage 1 played
them as written, after Goni's greeting, with the companion asking every item and Goni gone from the screen until the end card. (The tip's
`content/units/arc/colour-bay.arc.json` adds a Show before them and orders the same items; the items themselves did not change.)

**The pattern of every item:** a stage picture or nothing, a voiced question in the bubble, three picture tiles under the stage. Right: the
tile turns pale, a 28 pt tick, the companion's hop, and the feedback line, which is **always a label**: "כֵּן! זֶה בָּלוֹן אָדֹם." ("Yes! This is a
red balloon."), read flat. That is the "not exciting phrase" he heard: it is the same sentence shape on all fourteen items and it is the only
reward. Wrong: one of three general lines, then hint 1 "בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה" ("let's listen to the question again"), hint 2 "let's
look slowly at all of them, one by one" with the tiles lit in turn, hint 3 the worked example. All lines speak to "you" in the plural.

| # | Item (lesson) | What is asked, and how | What a 2–3 year-old must understand and do | Where an adult likely stepped in |
|---|---|---|---|---|
| 1 | `col.match.red` (match) | A red **ball** on the stage. "אֵיפֹה אוֹתוֹ צֶבַע?" ("Where is the same colour?"). Tiles: orange balloon, red **balloon**, blue **ball**. | The word "same colour" (abstract); to ignore that the answer is a different thing (a balloon) and to tell red from **orange**; to look from the stage down to the tiles. | **Very likely.** A toddler matches the *thing*: the blue ball is the natural answer, and it is set as the trap (`M-SORT-SHIFT`). Red against orange is a boundary young children still get wrong. The first item of the land is its hardest kind. |
| 2 | `col.match.blue` | Blue ball; tiles purple balloon, red ball, blue balloon. | The same, with blue against **purple**. | Likely (purple is a late word and close to blue). |
| 3 | `col.match.yellow` | Yellow ball; orange balloon, yellow balloon, blue ball. | Yellow against orange. | Possible. |
| 4 | `col.match.green` | Green **flower**; red flower, blue ball, green **ball**. | The same thing (a flower) is now the wrong answer. | Likely: the rule "same thing is wrong" was never shown. |
| 5 | `col.name.red.ball` | No model. "Where is the red ball?"; red balloon, red ball, orange ball. | **Two words at once**, the thing and its colour (`M-COL-ONEATTR`), and red against orange. | Likely: two attributes at once is beyond most 2-year-olds. |
| 6 | `col.name.blue.balloon` | "Where is the blue balloon?"; green balloon, blue balloon, blue ball. | Two words at once again. | Possible. |
| 7–12 | `colour-names`: yellow flower (vs yellow ball, orange flower), green ball, red balloon (vs orange), **orange** ball (vs red and yellow), **purple** balloon (vs blue and pink), **pink** flower (vs red and purple) | The same "where is the [colour] [thing]?" shape. | Six colour words in one lesson, each set against its **nearest** neighbours. | The orange, purple and pink items: very likely. These are the "fine" and "not understandable" mix he describes: red, blue, yellow, green with far distractors go; near pairs and two-word questions do not. |
| 13–14 | `b15.cola02.1` / `.2` (sort_drag) | "מְמַיְּנִים לְפִי צֶבַע: אָדֹם לְכָאן, וְכָחֹל לְכָאן." ("Sort by colour: red here and blue here.") Two bins with a **text** label and a sample; four things to drag. | The word "sort", "here" said twice without a pointing hand, a drag to a bin or tap-then-tap. | **Very likely**: the sentence points at two places that the voice cannot show, and a toddler's drag ends short. |

**Why it confused her, in one line:** the first Colour Bay lesson asks a 2-year-old to match a colour **across different things**, against
its **nearest** colour, from an abstract word ("same", "else", "sort"), with nobody showing her first, and it pays her with a label. Children
understand the basic colour words from about two and a half to three and a half years and keep confusing the boundaries (red and orange,
blue and purple) for a long time ([colour-word learning, review](https://pmc.ncbi.nlm.nih.gov/articles/PMC6001535)). So a 2-year-old
should first meet one colour at a time, on the same thing, against a far colour, and be shown before she is asked (section 4.7; the
content side is the curriculum-expert's, hand-off H3).

**What already works and should stay:** big clear pictures of balls, balloons and flowers; one question per screen; Goni, a chameleon who
changes colour, is the best idea in the land (`goni_skin.dart` already recolours him), but today he only does it on the end card.

---

## 2. She is 2: what the youngest end needs

She is below the app's 3 to 8 range. What a 2-year-old needs (Nacher and colleagues' studies of 2 to 3 year-olds on tablets: they can tap
and drag, but precise endings, double taps and long presses fail; NN/g: targets of at least 2 x 2 cm, and children under 6 do not notice
subtle feedback; Kirkorian 2016: 24 to 36 month-olds learn from a touch screen when the touch is **specific** and points at what matters):

- **Cause and effect first:** every touch anywhere makes something happen, at once, big, with a sound. No dead zones.
- **No fail state:** nothing she does is "wrong". A miss shows the right thing glowing (errorless), and the item goes on.
- **Huge targets, one step:** 2 choices, 112 pt targets, a tap instead of a drag, never "tap this, then tap there".
- **Short loops:** 5 to 10 seconds from the question to the joy, then again. A lesson of three items, then a party.
- **No text and no waiting:** voice and pictures only; a greeting of at most 2 seconds; a Show of at most 6 seconds that any touch skips.
- **A grown-up beside her:** the AAP advises that 18 to 24 month-olds use only high-quality media **with a parent** who plays along and
  reteaches, and 2 to 5 year-olds about an hour a day, co-played. The design should invite the parent in (section 5), not replace them.

**Recommendation: no separate "little ones" app or mode, but a fifth look stage, P0 (under 3;0), inside a far more playful Band A.**
The app already has look stages P1 to P4 (`engine/presentation.dart`) that change sizes, choices, caps and pauses; P0 is one more row of
numbers plus a few switches. Everything in sections 4.1 to 4.4 (touch, burst, party, toys) is for **every** child, because the older
ones lack it too; P0 only turns the dials further:

| Dial | P1 today | **P0 (new)** |
|---|---|---|
| Choices | 3 | **2** |
| Answer target | 96, slop 16 | **112**, slop 16 |
| Screens per visit (`arcScreensByStage`) | 5 | **3**, then the party |
| Greeting | ≥ 3 s, voice to its end | **≤ 2 s**, any touch skips |
| Show | full for a new skill | **≤ 6 s, any touch skips**; the Together item carries the teaching |
| Drag templates | drag or tap-then-tap | **one tap: the thing jumps to its place by itself** (it still counts as the child's move) |
| After a "not yet" | hint ladder | **errorless**: the right answer glows at once; on the second touch it is right |
| Land screen | shown | **skipped**: the island on the map opens the lesson straight away (map, glide, room) |
| Text on her screens | captions per look | **none** (caption off; the bubble shows only a picture of the speaker's mouth) |
| Celebration size | S per item | **S on every item is one step bigger** (more particles, the companion's jump every time) |

What P0 teaches and which skills it serves is the curriculum-expert's (hand-off H3). A child turns 3 and moves to P1 by her birthday,
as the other stages do.

---

## 3. Research: eagerness without manipulation

What the best preschool apps and the research agree on, and what it means for Nitznutz. Original ideas only: no franchise's characters,
art or signature effects; our particles are our rooms' own glyphs (the trail shapes), our characters are our cast.

| Principle | Evidence | For us |
|---|---|---|
| **Active, engaged, meaningful, social** | Hirsh-Pasek et al. 2015, the "four pillars" of educational apps: active (minds-on), engaged (not distracted), meaningful (linked to the child's life), socially interactive, inside a learning goal. | Touch must do something that **matters to the content** (the counted butterflies fly up, not a random firework on the side). Invite the parent (section 5). |
| **Juice: immediate, layered feedback** | Jonasson and Purho, "Juice it or lose it" (2012): the same game feels alive when every action gets easing, squash, particles, sound and a little screen motion. Later critics: juice needs moderation and context. | One shared juice layer (4.1), **sized to the moment** (S, M, L), never on top of the learning while she thinks. |
| **Fun features must be tied to the content** | Takacs, Swart and Bus 2015, meta-analysis of 43 studies: animation, music and sound effects that fit the story **helped**; hotspots and games that did not **distracted**, most of all for children from less stimulating homes. | Inside an item, nothing tappable that is not the content. The fun toys live on the map, in the party, in free play and in the home. Inside the item, the content itself reacts (the stage comes alive). |
| **Toddlers learn from specific contingency** | Kirkorian, Choi and Pempek 2016 (n = 116, 24–36 months): touch-screen contingency helped the youngest learn a word only when the touch was **specific** to the important thing on screen. | For P0 the touch is on the object that teaches (the butterfly, the colour), and the reaction comes from that object. |
| **Toys, not tests, for the youngest** | Toca Boca: "toys, not games", no rules, scores, timers or levels; a good toy needs no instructions. Sago Mini: open-ended play without fear of consequence, built on Montessori; but playtesters asked "what should I do?", so they added characters with gentle requests. | A free-play corner per land (4.3) with no right or wrong, where the host makes gentle invitations ("can you make it red?") that need no answer. |
| **Characters with emotion; collecting** | Khan Academy Kids (free, no ads): original animal characters, items earned by finishing lessons are given to the characters, each character's room shows the collection growing. NN/g: children under 6 miss **subtle** expressions, so emotion must be big and bodily. | Real emotion poses, whole-body, big (4.1.4); stickers she collects herself at the party (4.2) and decorations she places on her island (4.3). |
| **Praise the effort, not the child** | Gunderson et al. 2013: process praise ("you counted carefully") to 1 to 3 year-olds predicted a growth mindset and approach to challenge five years later; person praise did not. | A bigger moment for **right after trying again** (4.1.3), and the companion's lines praise the doing. Never bigger for speed or for a run of right answers. |
| **What not to do** | Radesky et al. 2022 (JAMA Network Open), apps used by 3 to 5 year-olds: most had manipulative design: parasocial pressure ("come back tomorrow"), fabricated time pressure, navigation constraints, lures to play longer. | None of that: no streaks, no "come back", no lure on the way out, no reward for days in a row, no timer. The party ends calmly and leaving costs nothing (4.2). |
| **Media for 2-year-olds is co-played** | AAP / HealthyChildren: 18–24 months only high-quality media with a parent who plays and reteaches; 2–5 years about an hour a day, co-viewed. | A party and toys a parent and child play together (two can tap); the parent area later shows "what she played" so the parent can reteach. |

Sources:
[Hirsh-Pasek et al. 2015, APS summary](https://www.psychologicalscience.org/publications/educational-apps.html) ·
[Juice it or lose it (Game feel, Wikipedia)](https://en.wikipedia.org/wiki/Game_feel) ·
[GDC Vault: Juice It or Lose It](https://gdcvault.com/play/1016487/contactUs) ·
[Takacs, Swart and Bus 2015 (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC4647204) ·
[Kirkorian, Choi and Pempek 2016](https://koeunchoi.github.io/publication/2016-03-28-word-learning-touchscreens) ·
[Nacher et al., multi-touch gestures for pre-kindergarten children](https://riunet.upv.es/bitstream/handle/10251/64752/IJHCS-Nacher.pdf?sequence=2) ·
[NN/g: children's UX and physical development](https://www.nngroup.com/articles/children-ux-physical-development/) ·
[Toca Boca: toys, not games (Kill Screen)](https://www.killscreen.com/secret-smart-kids-entertainment-give-them-toy-not-game/) ·
[Sago Mini: letter to parents](https://sagomini.com/article/sago-mini-letter-to-parents/) ·
[Sago Mini Jinja's Garden (Apple Developer)](https://developer.apple.com/news/?id=3t6o5jec) ·
[Khan Academy Kids characters](https://khankids.zendesk.com/hc/en-us/articles/360049358751-Learn-more-about-the-characters-inside-Khan-Academy-Kids) ·
[Gunderson et al. 2013 (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC3655123) ·
[Radesky et al. 2022 (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC9206186/) ·
[AAP / HealthyChildren: media for babies, toddlers and preschoolers](https://healthychildren.org/English/family-life/Media/Pages/Healthy-Digital-Media-Use-Habits-for-Babies-Toddlers-Preschoolers.aspx)

---

## 4. The plan

All sizes in points on the phone board (852 x 393) unless said; tablet landscape and portrait in brackets. Timings are Band A; Band B
x 0.85, Band C x 0.7 (design-spec 10.1). Every motion has a reduce-motion version (`MediaQuery.disableAnimations`): no flight, no
particles, no jumps; a 120 ms fade to the end state, the pose change, and the same sound. Nothing flashes faster than 3 Hz. Nothing is
drawn with a new package: particles are a `CustomPainter` over cached `ui.Picture`s of the glyph SVGs; Rive stays for later (owner Q6).

### 4.1 The juice layer (one shared layer, every template)

New code lives in `app/lib/design/juice/` so every template gets it from the frame, not by copying.

#### 4.1.1 Touch: every touchable thing gives at once
- `Pressable` (promote the press target of `home_island_screen.dart`, which already "gives a little the moment it is touched"):
  on pointer **down** scale 0.94 (B 0.96, C 0.97) in 60 ms ease-out and the clay lip presses; on **up** spring back to 1.0 through
  1.04 (180 ms, overshoot curve of design-spec 10.1). Wrap: `AnswerTile`, `PebbleButton` (its lip press stays), every counted or
  placed object, map toys, land objects, the party's stickers and toys.
- `Feel.touch()` on the same down: the sound hook `touch` ("tok") and `HapticFeedback.selectionClick()` (owner Q2).
- A touch on the empty stage or empty screen in the child's space: a small sparkle at the finger (6 sparks, radius 0 → 30, 300 ms,
  `BurstLayer` size XS), no sound, never mistaken for an answer. P0: also a soft "plip".

#### 4.1.2 Pick up, drag and snap
- **Pick up:** scale 1.08, shadow blur 6 → 16 and offset 2 → 8, tilt toward the motion (±8°, eased by the x velocity), `pickUp` sound.
- **While dragging:** every valid target breathes 1.0 ↔ 1.04 (900 ms sine loop), the nearest one glows (`sparkTint`).
- **Snap:** a release within **1.5 x the target's radius** (Band A; B 1.25) counts as on it: a 120 ms magnet pull, a 1.1 squash, `snap`
  sound and `HapticFeedback.lightImpact()`. A release elsewhere floats home on an arc in 400 ms (`floatHome` sound), never "wrong".
- **P0:** no drag; one tap on the thing and it flies to its place by itself on an arc (450 ms), as if she dragged it.

#### 4.1.3 Right answer: the small burst (S), every right answer, at most 1.2 s, never blocks
Storyboard `right_answer_count_phone.png`, frames 1 to 5.

| t (ms) | What | Numbers |
|---|---|---|
| 0 | The chosen tile **pops**: 1.0 → 1.16 → 1.0, 280 ms spring; fills `sparkTint`; ring `correctGlow`. The **badge** grows from 28 to **36** (44 on tablets) and pops 0 → 1.2 → 1 in 220 ms. | `TokenComponent` new: `badgeCorrect` 36 / 44 |
| 0 | A **pop ring** (two strokes, spark and white) grows from the tile's edge 0 → 30 pt and fades in 300 ms. | |
| 0 | The **burst**: 16 pieces (P0 20, B 12, C 10) of the room's own glyph (its trail shape: stair, drop, tree, puzzle, nut, orange, porthole, arch, square) mixed with stars and sparks, in the room's rim colour and the spark, sky, lilac, grass and sunset tokens; 20–28 pt (28–36); fly out radius 0 → 100 (140) with ease-out in 600 ms, spin ±90°, fade from 350 ms. | ≤ 24 live particles; one `CustomPainter` |
| 0 | `Feel.right()`: the `right` sound (a sparkle, the sound director's) and `HapticFeedback.lightImpact()`. | |
| 80 | A **spark flies** from the tile to the next socket of the trail on an arc (control point 120 pt toward the start side), 500 ms ease-in-out, a short trail of 3 fading copies. | the trail exposes its socket rects |
| 120 | The **companion cheers**: one move from the variety bag (4.1.5): a real **jump** of 25 % of its height with an anticipation squash (0.9 / 1.1, 100 ms) and a landing squash (1.08 / 0.92, 90 ms), or a clap, a wiggle, a spin-in-place rock. The sparks of `character_view.dart` grow to 5 % of the box and to 10 pieces. | today: 10 %, 3.5 % |
| 200 | **The stage comes alive**: the item's own pictures react (4.1.7): the counted butterflies flutter up and settle; on templates without objects the stage's content does one happy bounce (1.0 → 1.03 → 1.0, 300 ms). | |
| 220 | The landmark reacts as today (its 900 ms motion), in its slot. | unchanged |
| 580 | The socket **drinks** the spark: scale 1 → 1.4 → 1, 300 ms, glow; `sparkLand` sound. | |
| ≤ 1200 | Everything has ended. The next item still comes at the praise pause (P1 1.6 s) exactly as today; **no touch is blocked** at any time, and a touch during the burst sparkles (4.1.1). | |

**Effort moment (S+):** a right answer **after a "not yet"** on the same item gets one extra: the companion's high-five pose toward the
child and a line that praises the trying (hebrew-text-editor, voice director). This is the only thing that makes a burst bigger. Speed,
a run of right answers, days in a row: never.

**Reduce motion** (frame 7): one warm glow round the tile (120 ms fade), the badge, the socket filled, the celebrate pose; same sound.

#### 4.1.4 Not yet: a gentle try-again that invites
Frame 6. The tile rocks shyly ±6°, three times, decaying, 360 ms (design-spec 10.2), its lilac ring fades over 300 ms, and it **stays a
choice**; a dragged thing floats home. No cross, no red, no buzzer, no haptic. The companion takes its **oops** pose (a smiling shrug; to
draw, `encourage` until then) and its line invites ("let's count again!"); the first hint picture comes as today. P0: the right answer
glows at once (errorless).

#### 4.1.5 Variety, so it never repeats exactly
A `VarietyBag<T>` (shuffled, never one of the last two again) for: the burst's pattern (ring, fountain upward, two poppers from the
tile's sides, spiral), the companion's move, the praise line (the sound director's ~30 short lines), the party toy's colours, the map
toys' fish and birds. Per child, kept in memory only.

#### 4.1.6 Sound and haptic hooks (with the voice-and-sound-director)
One `Feel` service is the single place where a motion event meets its sound (the sound director's `SfxPlayer` and kit,
`M12-sound-notes.md` 3b and 3c) and its haptic, and it knows reduce-motion, Calm mode and the parent's switches. The sound names are the
sound director's; the times are mine, so sound and motion meet on the same frame:

| Motion event (this plan) | When | Sound (sound notes 3b) | Haptic |
|---|---|---|---|
| touch-down | pointer down on anything touchable | `tap` (3 pitches) | light (`selectionClick`) |
| pick up / snap / float home | 4.1.2 | `pickup` / `snap` / `drop` | light / medium-light / none |
| count tap n | each counted object | `count n` | light |
| right answer, burst t 0 | 4.1.3 | `correct` (6 variants, never twice in a row) | success (`lightImpact`) |
| spark lands in the socket | t 580 | a soft tick inside the `correct` tail (no new file needed) | none |
| companion lands its jump (`hopLanded`) | t ≈ 120 + 420 | (the sound notes' hook) | none |
| not yet, rock t 0 | 4.1.4 | `again` (never a buzzer) | none |
| hint | the hint's picture | `hint` | none |
| party opens / sticker in / last confetti (`celebrateDone`) | 4.2.2 | `lessonEnd`, the land's `stinger`, `sticker` | success on the opening only |
| a toy or a character reacts (`pokeDone` at its end) | 4.3, 4.2.2 | the toy's sound, the host's giggle clip | light |

**One naming of the three sizes for both halves:** S = every right answer, M = the end of a lesson (the party), L = a milestone (a skill
understood for good, a trophy). The sound notes call the lesson end "L" and a sticker "M"; I ask the director to take these three names so
the developer meets one vocabulary (hand-off H2). The voice always wins (ducking), at most two effects overlap, touch sounds are throttled
(sound notes 3c); motion is never throttled, so a mash of taps still sparkles everywhere.

#### 4.1.7 The stage comes alive, and the characters feel
- **Stage joy** (`TemplateSession.joy(Duration at)`, a new optional hook; default: the stage content's one bounce): count and give-N:
  the counted things flutter or hop up 14 to 26 pt and settle (staggered 60 ms); choice and tap-answer: the item's picture does a happy
  hop of 8 % of its size; sort and match: the placed things wiggle in their bins; robot: the robot does a two-step dance; clock: the
  hands spin once round to the time (only after the answer); colour items: the coloured thing glows its colour. Never before the answer
  and never on a wrong one.
- **Each room's little creature** (art, 4.5): a room-own animal that peeks in from the stage's edge on every third right answer (bird in
  Counting Hills, fish in Colour Bay, squirrel in Shape Forest, firefly in Riddle Grotto, gull in Robot Harbour, cat in the Market,
  and one per language room), 600 ms in, 600 ms out. Variety, not a reward that grows.
- **Characters with real emotion:** the companion and the host use whole-body poses (NN/g: small faces are missed). Existing:
  companion idle, talk, listen, think, encourage, celebrate, surprised, sleepy, wave; hosts idle, talk, show, celebrate. To draw: 4.5.

### 4.2 Celebration redesign

#### 4.2.1 Every right answer: the S burst (4.1.3).

#### 4.2.2 The end of a lesson: a real party in the land's own place (M), storyboard `party_counting_hills_phone.png`
No card and no grey veil: the party happens in the room.

| t | What | Numbers |
|---|---|---|
| 0–450 ms | **The room opens:** the stage grows into the whole screen (Band A base transition, spring-out); the buttons, trail and tiles slide off; the backdrop fills the board at its aspect (`backdrop()` layers, never stretched). `partyStart`. | |
| 0.5–1.5 s | **Friends jump in** from the end side (left; the reading direction's end): the host **240** pt (tablet L 400, P 340) and the companion **210** (360, 300), and dance (two dance frames each, 400 ms per frame; until drawn, the celebrate pose bouncing). **Confetti** of the room's glyphs and sparks rains for 2.5 s: about 50 pieces, 20–32 pt (28–40). | ≤ 60 live particles |
| 1.5–2.5 s | **The new piece:** the landmark stands big at the end side (**190** pt; 300 / 260) and builds its new piece (the existing `piece` art, a draw-in of 600 ms and a 1.1 squash) with a fountain of stars. | |
| 2.0 s | **The sticker** flies out of the landmark on an arc and lands in front of her, **150** pt (220 / 200), rocking ±4° slowly: it waits for her finger. | |
| her tap | It spins into her **sticker book**, which appears at the start corner (88 pt, bottom right) and bounces open; `stickerIn`. **She did the last step of the reward herself.** No tap within 6 s: it flies in by itself. | |
| from 2.5 s | **The home pebble** (88 pt, spark colour) comes up at the bottom middle. **The touch party** is on: every tap anywhere bursts the room's glyphs; tapping the host or the companion gives a giggle and one of three silly moves; the land's own toy (4.2.3) plays. | |
| after 20 s still | **Calm:** the confetti stops, the friends wave, the home pebble glows softly. Nothing ends by itself; nothing is lost by leaving; there is no countdown and no "stay" lure. | |
| the cheer | The host's cheer and the companion's praise are **voiced** (as today); their text appears only for P2 and up, small, at the top. | |

A lesson that ended because it was time to rest gets no party: the calm goodbye of today, in the room, with the characters waving.

**Reduce motion:** the room at full size, the landmark with its piece, both friends in their celebrate poses, the sticker already in
front of her; a tap fades it into the book. No confetti, no flights; the same sounds.

#### 4.2.3 Each land's own party toy (variety between lands, and inside a land)
| Land | The toy (taps during the party) |
|---|---|
| Counting Hills | Balloons carrying 1 to 5 dots float up; a tap pops one into stairs and sparks and Nekudi counts the pops aloud. |
| Colour Bay | Paint drops fall where she taps and splash in a colour; Goni turns that colour. |
| Shape Forest | Shapes drop where she taps and stack into a tower that wobbles and stands. |
| Riddle Grotto | Fireflies light where she taps; three in a row make a pattern that repeats itself in light. |
| Robot Harbour | The crane drops a crate where she taps; the robot dances on it. |
| Market Village | Oranges and apples rain into Grandma Pnina's basket, which she lifts higher each time. |
| English, Hebrew, Russian rooms | Kites, birds and bubbles fly out of the room's window; the host says the word of each (a known word). |

#### 4.2.4 A milestone (L): new growth on the island, a skill understood for good, a trophy
Keep the trophy ceremony (it is good). Add: when the child next opens the map after a skill reached lasting understanding, the camera
glides to that island and the skill's object **draws itself in** (sketch stroke 800 ms, then colour floods from the bottom with a 1.1
squash, 600 ms), the host dances beside it, a spark fountain; tap to go on after 1.5 s; at most once per visit (design-spec 10.3 tier 3).

#### 4.2.5 A new sticker, medal or island object anywhere
Always seen arriving: flown to its book or shelf, never silently added. The sticker book in the child's home wiggles until it is opened.

### 4.3 Things to do just for fun
None of these writes an attempt, a result or any evidence (the `unscored` path of `LessonController` already exists, SEC-LC-2).

1. **A map where everything answers** (`map_tap_phone.png`): about 12 tap toys in the scene, each ≤ 1 s with its sound: clouds puff and
   sprinkle drops; the sea makes a splash ring and every second tap a fish or a bird jumps; palms shake; the lighthouse turns its beam;
   the boat toots; the rainbow shimmers; each land's landmark plays its own room reaction **on touch-down** and the land opens on the
   finger's lift; a land that is not ready still reacts and the companion says "soon" (voice). The companion has five moves on tap
   (giggle-spin, jump, peekaboo, a sneeze of sparkles, a high-five), tickled twice she laughs harder. Map toys sit outside the land tap
   areas, and a pan that starts on a toy still pans.
2. **A free-play corner in every land** (a toy-box pebble beside Play on the land screen, and for P0 a toy box on the map's island):
   the existing templates without a right answer, the host making gentle invitations that need no answer:
   Counting Hills: tap to hang apples on a tree and Nekudi counts them; tap one to take it and she counts down. Colour Bay: paint
   balloons and Goni from pots. Shape Forest: stamp shapes into a picture. Riddle Grotto: string beads and Timi continues the pattern.
   Robot Harbour: drive the robot freely with the arrows and push crates. Market Village: fill a basket and Pnina names each fruit.
   Language rooms: tap the room's things and the host says their words. **Colour Bay first** (owner Q5).
3. **Decorate the island:** the island objects and decorations she earned (and her stickers, as little flags) go on her home island;
   drag or, for P0, tap from a tray of large items (96 pt) to **magnet spots** (no precision), and they stay.
4. **The companion's home:** in the child's home (B-26), the friend at its door can be **tickled** (giggle), **fed** a fruit from the
   Market (munch), **dressed** with the scarves already in `rewards/outfits.dart`, and **put to bed** (sleepy pose, lights dim; a nice
   way to end a session). No needs, no hunger, nothing that gets sad if she does not come back (Radesky's "parasocial pressure").

### 4.4 First run for a tiny child: joy in under 10 seconds
1. **0 s, loading:** not a blank cream screen: the bundled Nitzi pops in at the centre (300 ms) and **answers touches while the app
   loads** (giggle, wave).
2. **Picker:** faces at 160 pt; a tapped face jumps and her name is said (voiced first names are allowed, owner's 2026-10-25 choice).
   One child on the device: no picker.
3. **Map:** the companion greets her by name (voice), and for P0 and P1 **today's island calls** after 3 s still: it hops gently every
   4 s and a path of light runs from the companion to it (frame 5); the companion points and says "let's go!".
4. **One tap** on that island: the 600 ms glide into the room (frame 6). P0 and P1 skip the land screen and the long greeting (≤ 2 s).
5. **The first item** is a Together item whose objects take a touch **during** its question line.

Target: **a touch that answers within 3 s of the app showing anything** (the loading companion), **the first item in under 10 s**,
two taps (face, island). On the tip with a Show for a new skill, P0's Show is at most 6 s and any touch skips it.

### 4.5 What art must be drawn
All as SVG in the existing style (the same outlines and clay shading as `design/assets/nekudi-*.svg`), drawn by me from real references
for anything real (the owner's rule), at the cast's 512 artboard with the same anchors (`feet`, `mouth`, `burst`). Sizes follow
`docs/design/m11/min-sizes.md`: characters in the party ≥ 200 pt on the phone; particles are decoration, 20 pt and up on the phone;
every face readable at 96 pt.

| Set | Items | Count | Notes |
|---|---|---|---|
| Companion poses (Nitzi first) | cheer-jump (airborne), clap a / b, dance a / b, giggle, oops (shrug smile), proud (sticker held up), high-five (paw toward the child), peekaboo a / b, tickled, sparkle-sneeze | **13** | Other companions from the packs: the same 13 each, later. |
| Host poses (9 hosts) | dance a / b, delight (happy gasp), oops (friendly shrug), tickled | **45** | `make_host_poses.py` pipeline; Goni's recolourable files too. |
| Room glyph confetti | each room's trail glyph in 3 cut shapes (flat, turned, half) | **27** | Small SVGs, cached as pictures. |
| Shared particles | star, spark, round dot, streamer, ring, drop | **6** | |
| Room creatures | one per room, peek-in and wave | **9 x 2 = 18** | Original animals, from photographs (bird, fish, squirrel, firefly, gull, cat …). |
| Party toys | Counting balloons (existing `balloon_*` + dots), paint splashes 4, shape tower pieces (existing shapes), fireflies 2, crate 2, fruit (existing), kites 3 | **about 15 new** | |
| Map toys | cloud puff 2, drops, splash rings 2, fish jump 3 colours, bird take-off 2, palm shake 2, lighthouse beam, boat 2, rainbow shimmer | **about 18** | |
| UI | sticker book (big), toy-box pebble, home-pebble glow, effort high-five spark | **4** | |
| Colour Bay pilot (first) | paint splash blots 6, paint pot 1 (filled by the app in any colour), colour houses 4 | **11** | Goni's existing four poses suffice to start. |
| **Total** | | **about 157 drawings** | Colour Bay's first, then the order of 4.6. |

### 4.6 Order of work (most joy for the least work first)
Each step ships on its own, is played on the phone by the owner, and gets the qa-engineer once when finished.

| Step | What | App-developer | Voice and sound | Owner | Art (me) |
|---|---|---|---|---|---|
| **1. Touch and the S burst** | `Pressable` on every tile, object and pebble; `Feel` with haptics; `BurstLayer` with the room glyphs; spark to the trail and the socket drink; stage bounce; the not-yet rock; badge 36. | `design/juice/` (Pressable, Feel, BurstLayer, SparkFlight, VarietyBag), `AnswerTile`, `ProgressTrail` socket rects, `ActivityFrame` layer, `TemplateSession.joy` default. About 3 days. | 7 sounds: touch, right, sparkFly, sparkLand, notYet, pickUp, snap. | Haptics on by default? (Q2). Plays it. | 27 glyph confetti + 6 particles. |
| **2. The party** | Full-screen room party, existing celebrate poses bouncing, confetti, tap-to-collect sticker into the book, touch party sparkles and giggles, calm state, reduce motion. Replaces `LessonCelebration` / `RoomCelebrationCard` for a finished lesson. | About 3 days. | partyStart, confetti, stickerIn, pop, giggle; a short party sting per land (later). | Q3, Q4. | Sticker book. |
| **3. Little ones (P0) and the fast first run** | P0 row in `presentation.dart`; skip the land screen for P0/P1; greeting ≤ 2 s; touch-skips Show ≤ 6 s; one-tap placement; errorless; loading companion; today's island calls. | About 3 days. | Short lines for "let's go!", "soon". | Q1, Q8. | Path-of-light, island hop (code). |
| **4. The map comes alive** | 12 map toys, companion's five moves. | About 2 days. | 12 toy sounds. | — | 18 map toys. |
| **5. Real emotion** | Wire the new poses: jump, clap, dance, oops, high-five, giggle; the effort moment S+. | 1 day after the art. | High-five and effort lines. | Approve the pose sheet. | 13 Nitzi poses, then 45 host poses. |
| **6. Each land its own** | The 9 party toys and the 9 room creatures; stage joy per template. | About 3 days. | Per-land toy sounds. | — | Creatures, toys. |
| **7. Free play** | Colour Bay paint corner first (unscored), then one per land. | About 2 days for the first, 1 each after. | Ambient bed per corner. | Q5. | Pots, splashes. |
| **8. Her island and her friend's home** | Decorating with magnet spots; tickle, feed, dress, bedtime; milestone growth draw-in. | About 3 days. | Munch, tickle, lullaby. | — | Tray items, bedtime. |

Steps 1 and 2 alone answer "no celebrations" and "nothing exciting"; step 3 answers "not child friendly" for a 2-year-old.

Every step ships in **Colour Bay first** (4.7), and goes to the other lands once the owner has played it there with his daughter.

### 4.7 The pilot: Colour Bay, worked through
Storyboard `colour_bay_pilot_phone.png`. Colour Bay is the right pilot: it is where she struggled, its host is a chameleon who already
changes colour in code (`GoniSkin`, eleven colours and a rainbow ripple), colour is the one content a 2-year-old can learn from touching
alone, and its toys (paint, splashes) are the easiest cause-and-effect to draw.

**What changes, in the order it ships:**
1. **Goni stays in the room for every item** (the host pair of the Show, in the host's place, 168 pt on the phone; the companion beside him,
   smaller). Today he leaves after the greeting. He is the one who reacts to colour.
2. **The right answer turns Goni the colour she found** (frame 2): at t 120 of the S burst his skin goes to the colour in 250 ms
   (`GoniSkin`'s own timing) and he jumps; he goes back to mint when the next item starts. The burst's glyph is the bay's drop, and a
   **paint splash** of that colour (an irregular blot, 156 pt, ink outline) bursts under the tile and fades in 600 ms. The stage's picture of
   the same colour bobs. Reduce motion: Goni's colour changes, no splash flight, no jump.
3. **The line after a right answer celebrates and links** instead of labelling: "אָדֹם! כְּמוֹ הַבָּלוֹן!" ("Red! Like the balloon!"), from a pool
   of short lines per colour, varied (hebrew-text-editor, voice director). The label stays for the hint, where it teaches.
4. **P0 and P1 items for colour, one idea at a time** (frame 1; the content is the curriculum-expert's, H3): Goni **names first and then
   asks** ("red! the balloon is red. where else is red?"); the two answers are **the same thing in two far colours** (a red ball and a blue
   ball), 112 pt each; near colours (orange, purple, pink, grey), two-word questions ("the red ball") and "same colour on a different thing"
   wait for P2. The four first colours: red, blue, yellow, green.
5. **The try-again is errorless for P0** (frame 3): the tapped ball rocks and Goni names it ("this is blue"), then the right one glows and he
   points ("here is red!"); her next touch is a full right answer with the whole burst. P1 keeps its hint ladder, with hint 1 replaced by
   Goni pointing at the stage's model (a picture, not "let's listen again").
6. **The sort items become "feed the colour houses"** for P0 and P1: one bin per colour drawn as a little house painted that colour, no
   text label, Goni's hand showing the first one; P0 places by one tap (4.1.2). The sentence "red here and blue here" goes; the voice
   names one thing at a time ("the red ball goes to the red house").
7. **Goni's paint pots** (frame 4), the first free-play corner: four pots (red, yellow, blue, green; 100 pt; never smaller than the P0
   target) under a big Goni on the bay's backdrop. A tap on a pot splashes him that colour and he says it; a second pot in a row paints his
   stripes; a tap on Goni makes him giggle and go back to mint. Nothing is asked, nothing is scored. Reached from a toy-box pebble on the
   Colour Bay island (and for P0 straight from the map's island, beside the lesson).
8. **The Colour Bay party** (frame 5): the room opens, Goni (240 pt) dances and his skin runs through the colours she found in the lesson
   (`GoniSkin.ripple`); every tap throws a splash in the next colour and he names it; the pool landmark gets its piece; the sticker flies to
   her as in 4.2.2.

**The first Colour Bay visit for a 2-year-old, second by second (target):**
0 s the map, the bay's island hops (4.4) · 1 s her tap, the glide · 2 s Goni waves and says "hello! I'm Goni, I change colour!" and turns
red, yellow, blue in a row (his greeting, ≤ 2 s, any touch skips) · 4 s the first item: a red balloon on the stage, two balls; Goni:
"red! where else is red?" · about 6 s her tap: splash, Goni red, "red! like the balloon!" · then two more items (blue, yellow) · about
40 s the party · then the paint pots if she wants them. Three items, three colours, three times Goni changes, one party, under a minute.

**What the pilot needs:** app-developer: steps 1 and 2 of 4.6 wired in Colour Bay, Goni in the host place during items, the colour
switch at the burst, the splash, the paint-pot corner (step 7 brought forward for this land), the "colour houses" bins. Voice and sound:
Goni's per-colour lines and greeting, `correct`, `again`, `tap`, a splash sound, the bay's stinger. Hebrew editor: the lines above,
singular address for P0 (owner Q9). Curriculum: the P0/P1 colour item set (H3). Me: the splash blots (6), the paint pot, the colour houses
(4), the party splashes; Goni's existing four poses are enough to start, his dance frames come in step 5.

### 4.8 Checks for the qa-engineer (once per finished step)
- Every touchable widget in the child's space gives on pointer down (a widget test per template: scale < 1 within 60 ms of down).
- The S burst ends by 1200 ms; the next touch is accepted at every moment of it; the next item comes at the praise pause unchanged.
- Particles: at most 24 live (S) and 60 (party); frame time on the slowest test phone under 16 ms through the burst (profile build).
- Reduce motion: goldens of the end states (`right_answer_reduce_motion`, `party_reduce_motion`) with no particles.
- No flash over 3 Hz; no burst grows with speed, a run or days (a test that reads `Feel`'s inputs: only the event and "after a miss").
- Party: no countdown, no auto-leave, home always reachable from 2.5 s; free play writes no attempt.

---

## 5. How we will know it worked (for the owner, with his own children)

Tests cannot measure delight. Play with each child for one sitting, sit beside them and only help when asked, and note:

| Watch for | Today (2026-11-19) | After step 2 | After step 3 |
|---|---|---|---|
| Does she **laugh or squeal** in the first minute? When? | | | |
| Does she **tap things that are not the task** (the sea, the friend)? Does something answer? | | | |
| After a right answer, does she **look up at you** or **say something** ("again!", "look!")? | | | |
| Does she **repeat** a thing on purpose (pops balloons, tickles the friend again)? | | | |
| Does she **finish a lesson** (reach the party)? How long did it take? | | | |
| At the party: does she **tap the sticker** herself? Does she want to **see her book**? | | | |
| After a "not yet", does she **try again** or leave? Any sign of upset? | | | |
| **How long** until she leaves on her own? Does she **ask for it** later or the next day? | | | |
| Anything that **frightened, confused or bored** her (a sound too loud, a wait too long)? | | | |
| Her older brother or sister (the 3–8 range): the same questions, and "is it for babies?" | | | |
| **Colour Bay:** does she **say a colour word** herself (copying Goni) during or after? Does she point at a red thing in the room? | | | |
| **Colour Bay:** on which items did **you** have to help? (Write the item: the red ball, the sort, …) | | | |
| **Paint pots:** how many pots does she tap before she leaves? Does she **name** a colour before Goni does? | | | |

Good signs: laughter in the first minute, taps on purpose to see a thing again, reaching the party, asking for it later. Bad signs:
tapping hard and fast at nothing (a touch that does nothing), looking away during the waits, leaving at a "not yet". A short video of
the first two minutes (kept by the owner, never sent anywhere) is the best evidence for the next round.

---

## 6. Questions only the owner can answer
1. **P0 for under 3:** a fifth look stage set by the birthday (section 2), rather than a separate mode. OK?
2. **Haptics:** a light tap on touches and right answers, on by default, with a parent switch in Rules. OK? (No vibration on "not yet".)
3. **The sticker at the party:** she taps it into her book herself (it flies in by itself after 6 s). OK?
4. **The party has no end time:** it calms after 20 s still and waits for "home". OK, or should it go home by itself after a while?
5. **Free play writes no progress at all** (no evidence, nothing in the parent area but "played in Colour Bay"). OK, and Colour Bay first?
6. **Rive:** the jumps and dances are drawn as SVG poses and moved in code now; Rive (approved in principle) waits until a `.riv` file
   exists. Keep it so for M12?
7. **Who draws the ~157 pictures:** I draw them now in the cast's style from references (as the hosts and coins were), and the
   illustrator (P9) replaces them later by file name. OK?
8. **The land screen for the youngest:** P0 and P1 go from the map straight into the lesson (the island close-up stays for P2 and up and
   for the parent). OK?
9. **"You" for one child:** every line today speaks to a group ("סְפַרְתֶּם", "בּוֹאוּ"). For P0 and P1, should the lines speak to one child
   (and then, by the parent's setting, as a boy or a girl), or stay plural? It changes how warm the voice feels.
10. **Colour Bay is the pilot:** every step ships there first and you play it with her before it goes to the other lands. OK?

## 7. Hand-offs
- **H1 → app-developer:** steps 1 to 8 of 4.6, starting with step 1 (`design/juice/`, `AnswerTile`, `ProgressTrail`, `ActivityFrame`,
  `TemplateSession.joy`), then step 2 (the party replacing `LessonCelebration` / `RoomCelebrationCard` for a finished lesson). Exact
  numbers: 4.1.1 to 4.1.7 and 4.2.2. Goldens to add: the S burst end state and the party end state on the four boards, reduce motion.
- **H2 → voice-and-sound-director:** the motion times of 4.1.6 and 4.2.2 against your kit and hooks (`hopLanded` at t ≈ 540 of the S
  burst, `celebrateDone`, `pokeDone`); please take the shared names S / M / L (S every right answer, M the lesson-end party, L a
  milestone). For the Colour Bay pilot first: Goni's greeting and per-colour lines, a splash sound, the bay's stinger.
- **H3 → curriculum-expert (Colour Bay first):** the P0 and P1 colour items of 4.7 (one colour at a time, the same thing in two far
  colours, Goni names before he asks, red, blue, yellow, green first; near colours, two-word questions and "same colour on a different
  thing" moved to P2); "colour houses" instead of text-labelled sort bins; the errorless try-again; then what P0 serves in every land;
  what each free-play corner may teach without testing; that the stage joy (4.1.7) never shows the answer before it is given.
- **H4 → hebrew-text-editor:** the right-answer lines that celebrate and link ("אָדֹם! כְּמוֹ הַבָּלוֹן!") instead of the label "כֵּן! זֶה …",
  varied per colour; Goni's greeting; process praise and the effort line; "let's go!", "soon"; the party's cheers; singular address for
  P0/P1 if the owner says so (Q9). All voiced; none needed as text for P0 and P1.
- **H5 → qa-engineer:** the checks of 4.8, once per finished step.
- **Needs the owner:** section 6, and the four storyboards (paths at the top).

## 8. What I looked at, and what I did not
- Code at fb39dc08 and at the tip: `rooms/room_celebration.dart`, `rooms/stage_reaction.dart`, `rooms/moments.dart`,
  `rooms/landmark_slot.dart`, `play/lesson_screen.dart`, `play/lesson_controller.dart`, `play/activity_frame.dart`,
  `play/count_tap_session.dart`, `play/template_session.dart`, `play/lesson_arc.dart`, `play/idle_ladder.dart`,
  `characters/character_view.dart`, `child/companion_views.dart`, `child/home_screen.dart`, `child/land_screen.dart`,
  `child/ceremony_screen.dart`, `design/components.dart`, `app/app.dart`, `engine/presentation.dart`; design-spec section 10.
- Goldens: `m11_celebration_numbers_phone.png`, `m11_room_numbers_reacted_phone.png`, `lesson_2_count_three_answers_phone.png` (both
  trees), `stage2_counttap_turn_phone.png`, `home_phone.png`, `land_island_phone.png`, and for Colour Bay `unit_colour_sort_phone.png`,
  `hint_tap_colour_model_l1_phone.png`, `m11_room_colors_alone_phone.png` (fb39dc08).
- Colour Bay content at fb39dc08: every Band A colour lesson in `content/starter/` (`colour-match`, `colour-names`, `more-colours`,
  `colour-sorting`, `colours-of-things`, the `-again` and `b15` ones), item by item with prompts, options, feedback and hints; the tip's
  `content/units/arc/colour-bay.arc.json` (Shows and lesson plans); `rooms/goni_skin.dart`; `docs/milestones/M12-sound-notes.md`.
- My four storyboards, every frame, after rendering.
- Not seen: the real phone, the loading time, the sound, how long the greeting voice and a full Show really last, and the child. The
  owner can see all of these; the timings in 1.1 that depend on them are estimates from the code.
- Placeholder art: every pose marked "to draw" on the boards stands in with the nearest existing pose; the map toys and the party toys
  are sketched, not final art.
