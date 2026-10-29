# B-26: Nitzi's home (the child's island)

Status: **PROPOSAL, waits for the owner's OK** (2026-10-29). Plan step only: no app code, no final art, nothing paid.
Owner of this doc: design-director. Board item: B-26. Wording: hebrew-text-editor. Voice: voice-and-sound-director.
Wiring: app-developer. Checks: qa-engineer. The owner's binding decisions: the home island's sign opens a small home
screen where the companion greets the child and where the Trophy Hall, the stickers and today's adventure live together;
the island is named after the **child** ("הָאִי שֶׁל <name>"), per profile, on screen only; nothing timed, no streaks, no
guilt, no purchases.

## 1. References first

Kids' app hubs (read 2026-10-29; help pages, store listings and reviews, no screenshots copied):

| What I looked at | What it does | What we take / avoid |
|---|---|---|
| Khan Academy Kids ([help: characters' rooms](https://khankids.zendesk.com/hc/en-us/articles/360006764812), [overview](https://learn.khanacademy.org/khan-academy-kids/.)) | Home screen with the guide characters; tapping one opens its room with its toys and a collection that grows as the child learns; the Library is a book icon in a corner; one big play button starts the learning path. | A character's home as the place where the child's collection lives; a **book** means "things to look at"; one big obvious "play" object. |
| Sago Mini World ([review](https://toddler-games.pages.dev/review/sago-mini-world-the-calmer-cousin-to-toca-boca-by-design-and-by-economics), [App Store](https://apps.apple.com/app/id874425722)) | A hub of big icons; the review praises big targets and an obvious exit home, and criticises a hub that needs 3 taps before play. | Count the taps to play (ours: 2 from the map, section 2); the way back is always the same button in the same place. |
| Toca Life World ([parents' page](https://tocaboca.com/for-parents/toca-life-world/)) | The map is the hub; a building is a place to visit. | A building = a place (the lighthouse = the Trophy Hall). Its shop button is what we never do. |
| ABCmouse "My Room" / hamster ([Common Sense](https://www.commonsensemedia.org/website-reviews/abcmousecom), [support](https://support.abcmouse.com/hc/de/articles/360048194113-Where-can-we-find-the-items-we-have-earned-or-purchased)) | A room decorated by spending tickets earned in lessons. | **Avoided**: no currency, no spending, no shop in the home; trophies and stickers are shown, never bought. |

Real objects for the drawings (facts read now; photographs are looked at in the drawing step, before any SVG, as the
owner's rule asks):
- **Lighthouse** = the Trophy Hall: [Jaffa Light](https://en.wikipedia.org/wiki/Jaffa_Light): a short cylindrical tower
  with four ribs, a gallery and a lantern, painted in red and white horizontal bands. The map's lighthouse is already red
  and white banded; the close-up keeps that, adds the gallery rail and a warm lantern.
- **Bottle** = today's adventure: [message in a bottle](https://en.wikipedia.org/wiki/Message_in_a_bottle): a glass
  bottle with a cork and a rolled paper inside, washed up on the sand (design-spec §3.4: it arrives on the home beach).
- **House**: the map's own red-roof house (boards 10, 12, 22, 25), close up with a porch the companion stands on, so the
  child recognises the island from the map. (Spec §3.2 says "tree-house"; the approved map art draws a house on the
  ground. I keep the map's look; the illustrator may raise it into a tree later.)
- Our own boards: 10 and 12 (phone home), 21 (Sticker Island), 31 and 33 (Trophy Hall), 22 and 25 (tablet home).

## 2. What is on the screen, and what moves

The screen is a close-up of the child's island. Four things, nothing else: the **bottle** (today's adventure, the one
obvious next step, at the start side), the **companion** at its house door (greets), the **book** (stickers), the
**lighthouse** (Trophy Hall). Plus the back button and the island's name. Who greets: the child's map companion (the
role resolver, design-spec §4: screens never name a character), Nitzi until the child picks another friend.

What exists today on the map (`home_screen.dart`) and what happens to it:

| Item on the map today | What it does today | Recommendation | Alternative |
|---|---|---|---|
| Home island sign "הָאִי שֶׁל נִיצִי" | **nothing** (no tap area) | **Opens the home.** Text becomes the child's island (section 4). | none |
| Trophy pebble "גְּבִיעִים" + its glow | opens the Hall | **MOVES** into the home as the lighthouse. Its "something waits" glow moves to the home sign on the map. | STAYS on the map and is also in the home (linked twice) |
| Stickers pebble "מַדְבֵּקוֹת" | opens the album | **MOVES** into the home as the book. | STAYS and is also in the home |
| Golden-stars chip | shows a number | **STAYS** under the avatar (it is about the lands, not a place) | moves onto the lighthouse |
| Yellow book button (end corner) | **nothing** (`onPressed: () {}`) | **REMOVED** (its job, the sticker book, is now in the home); Parents stays alone | becomes a second door to the stickers (the spec's original "book = stickers") |
| Today's Adventure pill | **nothing** (no tap; 3 static dots) | **STAYS** as the map's primary call to action, **linked**: a tap opens the home, where the bottle bobs | starts the adventure directly (one tap less, no greeting) |
| Bubble "{child}, הַבַּקְבּוּק הִגִּיעַ!" | text | STAYS (it now points to something real: the bottle at home) | — |
| Companion + its "+" (Friends' Beach) | greet / choose a friend | STAY on the map, unchanged | — |
| Avatar (switch child), Parents | | STAY on the map only (no parent button in the home) | — |

Trade-offs, one line each:
- **Recommendation (the home is the hub):** a calmer map top (two pebbles and a dead button fewer, which also relieves
  QA-19's crowded phone top) and one place for "my things", at the cost of one more tap to reach the Hall or the album.
- **Alternative (the home is a shortcut):** nothing to relearn and no golden churn on the map, at the cost of two ways to
  the same place and a dead book button that stays.

The bottle: the three-stop daily plan does not exist (M8 Q5 deferred it; M9 left it out). Until it does, the bottle opens
**one stop: the next lesson the engine suggests** (which one is the curriculum-expert's call), and the pill's three dots
are hidden (they promise progress that is not there). From the map: pill (or the island) → home → bottle = 2 taps to
play; from inside the home, 1.

Navigation: map → home → Hall / album / lesson; each of those comes back to the **home** (the back button pops one
level); the home's back button returns to the map. A ceremony earned in a lesson started from the bottle plays when the
child returns to the home (`_maybeCeremony` there, as on the map). Android back = the back button.

## 3. Layout on the four boards

Board coordinates (x from the left edge, y from the top), like `phone-map-7-lands.md`. All rectangles are tap areas;
the picture is drawn inside with `BoxFit.contain` (never stretched). Labels (`_Labelled` style, 14 bold, line height
1.7) sit under the target and are not tappable. Previews (wireframes, not art):
`docs/design/previews/nitzi_home_phone.png`, `..._phoneSE.png`, `..._tabletLandscape.png`, `..._tabletPortrait.png`.

Fixed on every board:
- **Back to the map**: the same pebble as Land, Hall and Sticker screens (`home_palm.svg`, spark fill, semantics
  `landBackSemantics` "חזרה למפה"), `PositionedDirectional(start: 16, top: 8)`, 48 drawn + 12 slop = 72 tap on phones;
  `start: 24, top: 24/32`, 64 + 12 on tablets. The start corner is where the avatar is on the map: same corner, "go back".
- **Island name** (the title): the home sign style (wood, ink border 3, radius 12, `land_nitzi.svg` glyph), centred at
  the top; font 22 phone, 20 SE, 28 tablets, bold, line height 1.7 (height about 43 / 40 / 54). Max width: phone 660,
  SE 475, landscape 940, portrait 580. Always the **full** name: shrinks to 18, then wraps to two lines (there is room on
  every board above the targets).
- **Bubble**: beside the companion's head on the start side, tail to the mouth; max width phone 260, SE 230,
  landscape 356, portrait 296 (each ends 16 / 24 inside the edge); up to two lines at 18 / 17 / 24 (the editor's draft "שָׁלוֹם, {child}! בְּרוּכִים הַבָּאִים הַבַּיְתָה." takes two
  lines on phones; the two-line bubble ends at y 165 phone and 169 SE, clear of the bottle); a name too long for it
  uses the shortened form (section 4).
- Nothing tappable in the bottom 24 (§6.1 edge rule); gutters 16 phone, 24 tablet.

| Target | phone 852 x 393 | phoneSE 667 x 375 | tablet landscape 1180 x 820 | tablet portrait 820 x 1180 |
|---|---|---|---|---|
| bottle (today's adventure) | 600, 192, 160 x 144 | 468, 188, 136 x 136 | 900, 480, 200 x 200 | 500, 760, 220 x 200 |
| companion (greets) | 380, 160, 160 x 160 | 304, 172, 132 x 132 | 600, 380, 240 x 240 | 300, 380, 240 x 240 |
| book (stickers) | 208, 216, 128 x 120 | 168, 212, 112 x 112 | 360, 516, 176 x 176 | 150, 780, 176 x 176 |
| lighthouse (Hall) | 32, 88, 128 x 248 | 24, 84, 112 x 240 | 80, 220, 200 x 480 | 48, 200, 160 x 440 |
| bubble (left, top) | 548, 100 | 420, 104 | 800, 296 | 500, 300 |
| house (scene only) | 330, 64, 250 x 270 | 286, 80, 180 x 252 | 560, 180, 340 x 520 | 250, 160, 340 x 480 |

Checks on these numbers: every target is at least 112 (Band A primary is 96 phone / 112 tablet; the companion on the SE
is 132); gaps between targets are at least 24 on phones (SE: 32, 24, 32) and 60 on tablets; the lowest target ends at
336 (phone), 324 (SE), 700 (landscape), 960 (portrait), all above the bottom-24 band; labels end above it too.

Order and RTL: the screen reads from the start (right): back, title, **bottle**, companion, book, lighthouse; semantics
follow the same order. The primary object is the first one the eye meets after the back button and the nearest to
the companion's waving hand. Portrait puts the companion and the lighthouse in the upper half and the beach row (bottle at
the start side, book) at the thumbs. Nothing on this screen is LTR: no numerals, no maths, no arrows. A Latin-letter
name is isolated (U+2068 ... U+2069) inside the Hebrew line.

## 4. The sign (map strip and home title)

Text: "הָאִי שֶׁל" + the name, exactly as the parent typed it (`profiles.name`, 1 to 40 characters, no nikud field
today); the hebrew-text-editor owns the final words. Today's sign: Heebo 700, 18, line height 1.7, padding 8, border 3,
glyph 20 + gap 4, so **sign width = text width + 46**; one line, 36.6 high (unchanged on the strip).

**Width box per board** (world x on the map, where the home sign may stand): inside the home island's tap area and 12
clear of the "+" pebble's tap area (it is level with the sign on phones):

| Board | sign centre | box (world x) | max sign | **max text** |
|---|---|---|---|---|
| phone | 1890 | 1770 .. 1978 | 208 | **162** |
| phoneSE | 1687 | 1577 .. 1764 | 187 | **141** |
| tablet landscape | 1010 | 890 .. 1130 | 240 | **194** |
| tablet portrait | 600 | 480 .. 720 | 240 | **194** |

Placement rule: `left = clamp(centre - w/2, boxLeft, boxRight - w)`: centred under the island while it fits, then held
at the box's right edge and grown leftwards (into the free sea towards Counting, whose sign ends at 1689 / 1514).

**Fit rule** (measured with the screen's own `TextScaler`, so QA-19's large text goes through the same steps):
1. The full line at 18; if too wide, 17, 16, 15 (never below 15).
2. Still too wide at 15: the hebrew-text-editor's shortening (`docs/agents/b26-hebrew.md` §1.4: whole parts first, then
   letters, always with `…`), keeping the longest name that fits at 15, then back through step 1 (it may grow to 18).
3. The name is empty or only invisible characters: the **fallback** sign (below).
The semantics label always carries the full line with the full name; the home title always shows the full name.

Why measured and not a letter count: the editor's "at most 10 clusters" gives up to about 232 for ten wide letters at
18 (my measure: 10 × ש = 155 + 63.5 + 46 = 264); the boxes are 208 (phone) and 187 (SE), so a count that is safe on
every board would be 6 letters (phone) and 5 (SE), which would cut common names such as אלכסנדרה. Measuring keeps
nearly every real name whole and stays inside the box on every board; the widget does it (the developer's §3.4).

Measured in Heebo 700 (headless Chrome, the app's own font file): "הָאִי שֶׁל" plus a space is 63.5 at 18 and 52.9 at
15; an average Hebrew letter is 10.2 at 18 and 8.5 at 15; the widest (ש) 15.5 and 12.9. Name length that fits before
step 2 (letters, a hyphen counts as one):

| Board | at 18, typical / worst case | at 15, typical / worst case |
|---|---|---|
| phone | 9 / 6 | 12 / 8 |
| phoneSE | 7 / 5 | 10 / 6 |
| tablets | 12 / 8 | 16 / 10 |

Rendered and looked at (`docs/design/previews/home_sign_names_phone.png` and `..._phoneSE.png`, the real map scene with
the sign drawn in the app's style):

| Name | phone | phoneSE |
|---|---|---|
| נועה | full, 18, sign 145 | full, 18, 145 |
| אלכסנדרה | full, 18, 190 (held at the right edge) | full, 17, 182 |
| אביגיל-אלכסנדרה | shortened to "אביגיל", 18, 161 (with `…` about 170) | the same |
| Alexandra (Latin) | full, 18, 191 | full, 17, 183 |
| שלי | full, 18, 141 | full, 18, 141 |
| no name | fallback, 18, 111 | fallback, 18, 111 |

On tablets: "אביגיל-אלכסנדרה" fits whole at 17; a 20-letter double name is shortened. (The previews drew step 2 as
the bare first part, before I read the editor's `…` rule; the `…` adds about 9 at 18.)

**Fallback** (no usable name): proposed "הָאִי שֶׁלִּי" ("my island", like the album's "הַמַּדְבֵּקוֹת שֶׁלִּי"),
65 wide at 18, fits everywhere. Spec §5.2 called Sticker Island "הָאִי שֶׁלִּי"; with the album moving onto this island
the two become the same place, so the name no longer clashes. The editor may choose otherwise.

**Without nikud**: the fixed words keep their nikud and the name stays as typed (no nikud is ever added to a name;
a reviewed spelling with nikud only if the parent sets one later). The line height of 1.7 already leaves room for marks,
so a vocalised name is not cut. Looked at: the bare name next to "הָאִי שֶׁל" sits on the same baseline and reads as one
sign. **No prefix letter is ever attached to the name** (לְ, בְּ, הַ, וְ, שֶׁ, מִ, כְּ): its vowel depends on the name's
first sound, which an unvocalised name does not give, and names that begin with such a letter (הדר, מיכל, לאה, שלי)
read wrongly. Every pattern keeps the name a separate word ("שֶׁל {child}", "{child}," as a call). "האי של שלי" (the
name Shelly) reads like "the island of mine": for the editor.

**Something waits in the Hall** (the glow that leaves the map's trophy pebble): the home sign gets the same soft glow
(`0xAAFFD45C`, blur 20, spread 4) and a 24 trophy badge (`trophy_gold.svg` on a paper disc) on its top-start corner,
overlapping the border (no extra width); the label adds "גביע חדש מחכה" (`trophyNewSemantics`). Colour is not the only
cue: the badge is a shape. Inside the home, the lighthouse lantern shows the same trophy in its window and a warm halo.

## 5. Motion and sound

- **Entry**: the standard page transition; then the companion plays `wave` once (the map companion's own wave, about
  1.2 s) and goes back to `idle` breathing. It waves on every entry from the map, not when the child comes back from the
  Hall, the album or a lesson. Tapping it waves again (as on the map).
- **Bottle**: a gentle bob, ±4 vertical and ±3°, 2.4 s ease-in-out, looping like the companion's breath (ambient, not a
  clock: nothing counts, nothing ends). Under reduce-motion: still.
- **Lighthouse**: a static halo when something waits; no blinking, no rotating beam.
- **Touch**: every target squashes on touch-down within one frame (0.96) and opens on release; a drag never opens.
- **Bubble**: shown on entry and stays while the child is there; never disappears on a timer.
- Nothing is timed: no countdown, no "come back tomorrow", no streak, no lost or missed state. The bottle is an
  invitation; an empty day shows the same calm island.
- **Sound (flag, not decided):** whether the entry wave says a voiced greeting (today's map greet plays
  `vo:core.greeting.hello`), whether it says the child's name (the per-name line the owner allowed, SEC-5 rules), and
  the soft effects (a cork "plink", a page rustle) are the **voice-and-sound-director's** call. The design works silently:
  the greeting is the wave and the bubble.
- The future "daily welcome" (PROGRESS, later ideas) belongs here: the bubble is its place. Not in B-26.

## 6. Art

New (one generator, `tools/make_nitzi_home.py`, sources in its header, no text or numerals inside any picture, no
franchise look, no real person):

| File | What | Size (viewBox) |
|---|---|---|
| `app/assets/art/scenes/nitzi_home_phone.svg` | sea, beach, grass, the house with a porch, palm, path | 852 x 393 |
| `.../nitzi_home_phone_se.svg` | same scene, SE board | 667 x 375 |
| `.../nitzi_home_tablet_landscape.svg` | same scene | 1180 x 820 |
| `.../nitzi_home_tablet_portrait.svg` | same scene, beach row at the bottom | 820 x 1180 |
| `app/assets/art/home/lighthouse.svg` | red and white bands, ribs, gallery, lantern with a window | tall, 1 : 2.2 |
| `app/assets/art/home/bottle_big.svg` | glass bottle, cork, rolled paper, wet-sand shadow | 1 : 1 |
| `app/assets/art/home/sticker_book.svg` | a closed album on a tree stump (a real sticker is laid on its cover in code) | 1 : 1 |

Reused: the companion (`CharacterView`), `home_palm.svg` (back), `land_nitzi.svg` (glyph), `trophy_gold.svg` (badge
and lantern), `sticker_01.svg` (album cover), `bottle.svg` (the pill icon, unchanged). The scenes keep the map's
colours (`worldSea1`, the board sand and grass) so map and home feel like one place. All of it is placeholder art until
the illustrator (to-do P9); files are named by id, so real art drops in without code.

Effort (my own work): references and photographs 0.5 day; the generator, 4 scenes and 3 objects 1.5 days; contact
sheet, previews and fixes 0.5 day; reviewing the goldens after the wiring 0.5 day. About **3 days**.

## 7. Open questions for the owner (with my recommendation)

1. **Move the Hall and stickers off the map into the home?** Recommended: yes (section 2), the map keeps the avatar,
   stars, pill, Parents and the "+". Alternative: keep both on the map as well.
2. **The yellow book on the map does nothing today.** Recommended: remove it. Alternative: make it open the stickers.
3. **The pill.** Recommended: it stays on the map and opens the home. Alternative: it starts the adventure directly.
4. **What the bottle does until the three-stop plan exists.** Recommended: one stop, the engine's next suggested lesson,
   with the pill's three dots hidden until there are stops. Alternative: build the three-stop plan inside B-26 (a bigger
   item for the curriculum-expert and the app-developer).
5. **Who greets at home.** Recommended: the child's chosen companion (as on the map). Alternative: always Nitzi.
6. **Tapping the companion on the map.** Recommended: it keeps greeting; the island and its sign open the home. The
   companion covers most of the home island on the phone, so the open part is the palm side (about 89 x 160), the sand
   under it and the sign. Alternative: the companion's tap opens its home (and greets there).
7. **A name too long for the phone sign.** Recommended: shrink to 15 first, then the editor's shortening with `…`
   ("אביגיל…"), the full name in the home title. Alternative: the fallback "הָאִי שֶׁלִּי".
