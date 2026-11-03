# The Languages island: the map, the doors, the parent pages (F8)

Owner of this doc: design-director. Date: 2026-11-03. Status: **ART DRAWN, SPEC READY for the owner's look, then for the
app-developer.** Source: `docs/languages/frame.md` §1.1 to §1.4 (approved by the owner on 2026-11-03, Q-F3 "next to the
home island; the design-director shows options"). Nothing here is wired yet.

Everything below is drawn by `tools/make_languages_art.py` (sources in its header). The previews in
`docs/design/languages/` were rendered by headless Chrome with the app's own SVGs and fonts; they are previews, not
goldens. The fixed buttons (Parents, avatar, pill) are stand-ins drawn at the boards' sizes.

## 1. Where the island sits (Q-F3)

### 1.1 Two maps, chosen by one flag
- **Every language off:** the map is exactly today's 7-land map (`home_phone.svg` ... and today's `_HomeSpec` values). Its
  goldens do not change. Frame §1.1: the land is hidden.
- **At least one language on:** the 8-land map: four new scenes `home_*_lang.svg` and the four `_HomeSpec` variants in §2.

Why two maps and not an island laid over the old one: on a phone the island has to sit *in* the strip, so a hidden
island would leave a 280 point hole of sea next to home. Two maps keep both cases clean, and the 7-land one is already
built and tested.

### 1.2 Options I looked at (recommendation first)
| | Phone and SE | Tablet landscape | Tablet portrait | Verdict |
|---|---|---|---|---|
| **A. Beside home** (drawn) | between home and Counting Hills; home moves one step right, every other island keeps its world place | top right, between Market Village (moved 50 left) and the avatar corner, right above home, a smaller island (R 88) | a new band of sea at the bottom (+140), the island down and left of home | **recommended**: next to home on every board, in the start view on every board |
| B. Second from home | between Counting Hills and Colour Bay; the start view keeps home and Counting, the new island is the half peek | the centre, where the sailboat is | between Counting Hills and Colour Bay (re-spacing the zigzag) | the start view changes least, but the island is only a half peek on phones, and on portrait every approved island moves |
| C. At the far end | after Market Village | anywhere free | at the top | rejected by the frame (§1.1: not at the far end; it will be visited often) |

What A costs: on phones Counting Hills becomes the half peek at the start (its whole sign stays on screen, pinned 12 / 8
inside the edge, as Colour Bay's is today). On tablet landscape Market Village moves 50 to the left (its island, stall,
tower, Grandma Pnina and the path's end; nothing else moves). On portrait the start view shows 140 more at the bottom, so
Robot Harbour's island passes under the pill at the start; its sign stays 52 clear below the pill.

**Needs the owner:** open `docs/design/languages/map_phone.png`, `map_phoneSE.png`, `map_tabletLandscape.png`,
`map_tabletPortrait.png` and `map_phone_whole.png`. Is option A what you imagined? Do you like the island (a little house
whose roof is an open book, three doors, three speech bubbles)?

## 2. The 8-land numbers (`_HomeSpec` variants)

Everything not listed is exactly today's value for that board. World coordinates as in `docs/design/phone-map-7-lands.md`.

### 2.1 Phone (`home_phone_lang.svg`, 2382 x 393)
`worldWidth` **2382** (2102 + 280). Start view (scroll offset 0, RTL) = world x 1530..2382. Home and everything that
belongs to it move **+280**; every other island keeps its world x.

| Land | sign `left` | `top` | on screen at start | notes |
|---|---|---|---|---|
| nitzi | **2170** | 320 | 640 (as today) | `homeSignLeft` **2050**, `homeSignRight` **2258** |
| languages | **1890** | 320 | 360 | centred; tap 1770..2010 |
| counting | 1610 | 320 | 80 (half island) | **`labelLeft: 1530 + 12`, `labelMaxWidth: 230`** (the pinned edge sign, as Colour Bay had) |
| colors | 1320 | 320 | off | **centred** now (no `labelLeft`) |
| shapes, logic, robots, market | 1040, 760, 480, 200 | 320 | off | unchanged |

`tapWidth` 240 (gaps: home/languages 40, languages/counting 40). Companion `companionLeft` **2139**, `companionTop` 154.
"+" pebble **2270**, 268. `bubbleRight` 212 and `bubbleTop` 112 are measured from the world's right edge and stay. The
mouth bubble and the B-42 welcome follow the companion, as today.

### 2.2 Phone SE (`home_phone_se_lang.svg`, 2086 x 375)
`worldWidth` **2086** (1834 + 252). Start view = world x 1419..2086. Home moves **+252**.

| Land | `left` | `top` | at start | notes |
|---|---|---|---|---|
| nitzi | **1939** | 314 | 520 (as today) | `homeSignLeft` **1829**, `homeSignRight` **2016** |
| languages | **1687** | 314 | 268 | centred; tap 1577..1797 |
| counting | 1435 | 314 | 16 (half island) | **`labelLeft: 1419 + 8`, `labelMaxWidth: 156`** |
| colors | 1189 | 314 | off | **centred** now |
| shapes, logic, robots, market | 937, 685, 433, 181 | 314 | off | unchanged |

`tapWidth` 220 (gaps 32). Companion **1903**, 164.6. "+" **2028**, 256. At text scale 1.3 the Counting sign is held to
156 (it scales down, as Colour Bay's did) and stays 19 clear of the Languages sign (1602..1772); the Languages sign is
57 clear of the home sign's box.

### 2.3 Tablet landscape (`home_tablet_landscape_lang.svg`, 1180 x 820, no scroll)
| Land | `left` | `top` | tap area (left..right, top) |
|---|---|---|---|
| market | **850** (was 900) | 372 | **736..964**, 222 |
| robots | 640 | 276 | 532..**720**, 126 (was ..756) |
| languages | **1082** | **372** | **984..1180** (to the screen edge, §6.1 edge rule), 222..382 |
| the others | as today | | as today |

Every gap between tap areas is 16 or more (robots/market 16, market/languages 20). The avatar (1076..1156 x 24..104) is 118
above the Languages tap area. Companion, "+", bubble, welcome band: unchanged.

### 2.4 Tablet portrait (`home_tablet_portrait_lang.svg`, 820 x 1720)
`worldHeight` **1720** (1580 + 140), the new sea at the **bottom**; every existing world y stays. Start view (offset 0,
`reverse: true`) = world y 540..1720.

| Land | `left` | `top` | at start | tap |
|---|---|---|---|---|
| languages | **232** | **1652** | 1112 | 112..352 x 1502..1662 |
| robots | 300 | 716 | 176 (52 below the pill's bottom 124) | as today |
| the others | as today | | today's value minus 140 on screen | |

Companion, "+", bubble and welcome band keep their world numbers.

### 2.5 For all four
- `Land.languages` (label `He.landLanguages`, icon `land_languages`), drawn only in the 8-land spec. It is not a
  `TrophyLand` and has no growth objects on the map.
- Use a different `PageStorageKey` for the two maps (`'home-map'` and `'home-map-lang'`): a stored offset of one world
  is wrong in the other.
- Tap order of the doors is not the map's business: the Languages tap opens the door screen (§4), or the only course
  straight away when one language is on.

## 3. Collision checks (what I measured in the previews)

| Check | phone | SE | landscape | portrait |
|---|---|---|---|---|
| No sign touches another (gap at 1.0 / at 1.3) | 123 / 75 | 34 / 19 | 100 / 67 (Market and Languages); Robot Harbour and Market 35 at 1.3 | 200+ |
| No sign under the pill or avatar at the start | yes | yes | yes | yes (Robot Harbour's sign 52 below the pill) |
| **B-42 welcome bubble** never covers the island's landmark or sign | the bubble's widest left edge is at screen 418, the roof ends at 403 | left edge 313, roof ends 302 | the band (760..1005 x 426..660) is left of and below the sign (1012..1153 x 372..408; 1.3: 997..1167 x 372..419, 7 above the band) | the band starts at x 376; the island ends at 336 |
| No tap area overlaps another or a fixed button | gaps 40 | gaps 32 | gaps 16 and 20 | gaps 96+ |

The welcome bubble on the phones still lies over the island's sand at the bubble's lower left, as it lies over Counting
Hills' sand today; it covers no landmark, sign or tap target that it did not cover before (the bubble ignores touches).
Previews: `map_*_welcome_1.3.png` (phones: a four-row welcome at 1.3 at its widest, 210 / 190; tablets: the B-42 band
drawn). The phone numbers use the friend's mouth at (0.44, 0.55) of its picture, read off today's goldens; the qa-engineer
re-measures them on the real goldens. On the phones the landmark is drawn 8 / 10 left of the island's centre for this margin.

## 4. The door screen

**Goal:** the child picks a language without reading. Each door is a host, a coloured door with its own window shape,
and "hello" in the language's own script, which the child can hear.

### 4.1 States
1. **Three or two languages on:** the door screen.
2. **One language on:** no door screen. The map's Languages tap opens that course directly (frame §1.2).
3. **None on:** no island on the map (§1.1).
4. **A door opening** (after a tap): `door_<c>_open.svg` replaces the closed door, the host's hello plays, then the course
   opens (§4.4).

No locked, grey or "coming soon" door, ever (frame §1.2).

### 4.2 Layout (all boards)
- Background: the land screen's island (`_IslandPainter`) in the Languages colours: sea `worldSea1`, sand `#F6DDB0`,
  grass `#A8DB8F`.
- Back pebble at the start corner (`PositionedDirectional(start: 16, top: 8)`, 48, `home_palm.svg`): back to the map. The
  name chip at the top centre (as `LandScreen`): `He.landLanguages`.
- The companion, the land's host, in the end corner (bottom left): `left` 16, `bottom` 8, square of the size below. It
  breathes and blinks; it speaks only the idle line (§4.5).
- **Order of the doors, fixed** (frame §1.2): in Hebrew alphabetical order of the languages' names, read from the start
  (right): **English (אנגלית), Hebrew (עברית), Russian (רוסית)**. Not sorted by use. With two doors on, the same order.
- Each door unit = its hello bubble above the door art (`door_<c>.svg`, 240 x 300 viewBox, drawn at width `door`, height
  `1.25 x door`). The whole unit (bubble, door, host) is one tap target: the rectangle of §4.2.1.

| Board | `door` (w x h) | gap (3 doors / 2) | bubble top, height | door top | companion | row |
|---|---|---|---|---|---|---|
| phone 852 x 393 | 184 x 230 | 32 / 64 | 84, 52 | 146 | 104 | centred in x 128..836 (left of the companion's corner): x 174..790 |
| phoneSE 667 x 375 | 160 x 200 | 24 / 48 | 80, 48 | 138 | 88 | centred in x 112..651: x 117.5..645.5 |
| tablet landscape 1180 x 820 | 264 x 330 | 56 / 112 | 200, 68 | 278 | 160 | centred: x 138..1042 |
| tablet portrait 820 x 1180 | 240 x 300 | 24 / 48 | 380, 72 | 462 | 160 | centred: x 26..794 |

Every door unit is far above the band A target (96 / 112 pt), and the gaps between the tap rectangles below are above band
A's 24 / 32.

### 4.2.1 The tap rectangle of a door (QA-L0-2)
A door's tap area is **one rectangle: its bubble, its door and its host, and nothing round them**. The friend in the corner,
the grass, the sand, the sea, the title chip and the space between two doors open no door. It replaces the L0 unit, which
was a column as high as the board (its `Stack` had only positioned children). The art keeps its place (the door box of §4.2,
`door` x `1.25 x door`, and the bubble above it); only the hit area is this rectangle, and the art may paint a little
outside it (`Clip.none`).

The rule, for each door, from its door box (left `L`, width `door`):
- **Left and right:** the stone frame's visible edge plus band A's 12 slop. The door art is drawn from x 20 to 220 of its
  240 viewBox, so the frame starts `door / 12` inside the box; the rectangle is the box inset by `round(door / 12) - 12` on
  each side: **3** (phone), **1** (SE), **10** (tablet landscape), **8** (tablet portrait).
- **Top:** the bubble's top (`bubbleTop`), with no slop upward, so the back pebble and the title chip stay clear (on the
  phone the English rectangle is then 28 below the pebble; with a 12 slop it would be 16, under band A's 24).
- **Bottom:** the door box's bottom (the host's shadow), but never in the bottom 24 band of the screen (§6.1 edge rule):
  `min(doorTop + 1.25 x door, boardHeight - 24)`. On the phone that cuts only the shadow (the doorstep ends at y 368.3).
- No door is edge-adjacent (the narrowest gutter is 34, on tablet portrait, more than 24), so none extends to the edge.
- **The bubble stays inside its rectangle:** its maximum width is the rectangle's width (178 / 158 / 244 / 224) instead of
  `door + gap - 8`; above that the word scales down (FittedBox), as today. At text scale 1.0 the widest bubble ("Привет")
  is about 153 / 143 / 194 / 204 wide, so nothing scales down today.
- The door's `Semantics` button has the same rectangle.

The rectangles in board points, `left..right` and `top..bottom`, listed from the left of the screen. The doors read from the
start (the right): **English is the rightmost**, then Hebrew, then Russian; with two doors on, the same order (the left one
is Russian if Russian is on, otherwise Hebrew; the right one is English if English is on, otherwise Hebrew).

| Board | 3 doors, x: Russian · Hebrew · English | 2 doors, x: left · right | y (all) | size w x h | gap between rectangles (3 / 2) |
|---|---|---|---|---|---|
| phone 852 x 393 | **177..355 · 393..571 · 609..787** | **269..447 · 517..695** | **84..369** | 178 x 285 | 38 / 70 |
| phoneSE 667 x 375 | **118.5..276.5 · 302.5..460.5 · 486.5..644.5** | **198.5..356.5 · 406.5..564.5** | **80..338** | 158 x 258 | 26 / 50 |
| tablet landscape 1180 x 820 | **148..392 · 468..712 · 788..1032** | **280..524 · 656..900** | **200..608** | 244 x 408 | 76 / 132 |
| tablet portrait 820 x 1180 | **34..258 · 298..522 · 562..786** | **154..378 · 442..666** | **380..762** | 224 x 382 | 40 / 64 |

What lies outside every rectangle, measured on each board:
- **The friend** (`left 16, bottom 8`, the `companion` square): phone 16..120 x 281..385 is 57 left of the Russian
  rectangle; SE 16..104 x 279..367 is 14.5 left of it (the friend is not a target, so band A's gap between targets does not
  apply; a tap on the friend opens nothing); tablet landscape 16..176 x 652..812 is 44 below every rectangle; tablet
  portrait 16..176 x 1012..1172 is 250 below.
- **The back pebble** (`start 16, top 8`, 48): phone 788..836 x 8..56 is 28 above the English rectangle; SE 603..651 x
  8..56 is 24 above it; on the tablets it is 144 or more above.
- **The grass, sand and sea** above the bubbles, below the doors and between two rectangles.

Tests (the app-developer's, then the qa-engineer's three QA-L0-2 proofs): on each board, with three and with two doors, a
tap 1 point inside each corner of a rectangle opens that door; a tap 1 point outside each side opens none; a tap on the
friend's centre, on the grass below the doors and on the sea above them opens none.

### 4.3 The hello bubble
- `BoardBubble` style: paper, radius 20, padding 16 (start) / 14 (end), a tail 18 wide and 12 high centred under it,
  pointing at its door. Inside, in a row that runs left to right: the word, then a gap of 8, then `speaker.svg`
  (`0.8 x` the word's size, 75 % opacity).
- The word, an isolated run in its own direction and locale (fonts.md §6):
  - English `Hello`: Nitznutz Letters 500, `Locale('en')`, LTR.
  - Hebrew `שָׁלוֹם`: Heebo 700, line height 1.7, RTL.
  - Russian `Привет`: Nitznutz Letters 500, `Locale('ru')`, LTR, no stress mark (a greeting, not a reading item; the
    Russian teacher confirms).
- Sizes: Hebrew 24 (phone), 22 (SE), 32 (landscape), 34 (portrait); English and Russian 1.1 x those (26.4, 24.2, 35.2,
  37.4). The bubble is never wider than its door's tap rectangle (§4.2.1: 178 / 158 / 244 / 224); above that the word
  scales down (FittedBox), so two bubbles never touch at text scale 1.3.
- The words are drafts: Hebrew → hebrew-text-editor, English → english-language-teacher, Russian →
  russian-language-teacher.

### 4.4 Taps, timing, motion
- **Tap a door unit** (anywhere in its rectangle, §4.2.1): at once the door art cross-fades to `door_<c>_open.svg` (200 ms), the bubble pulses
  (scale 1 → 1.06 → 1, 240 ms, a gold ring `spark` 4 wide while the clip plays), and the course's teaching voice says the
  hello clip. When the clip ends, after 250 ms, the course opens with the usual route transition. If the clip is missing,
  the course opens 600 ms after the tap.
- While a door is opening, taps on other doors are ignored; the back pebble always works (it stops the clip).
- **Reduce motion:** no cross-fade or pulse; the open door art replaces the closed one at once; the gold ring stays on
  while the clip plays.
- Hearing hello without going in is not a separate target (one tap = one obvious result for a 3-year-old). A child who
  wants to hear it again goes back with "home" in the course.
- **Leaving a course:** the course's back pebble returns to the door screen when two or more languages are on, to the map
  when one is on. Every course resumes where it was (frame §1.2).
- The first entry to a course starts its placement visit (LS13); that is the course's screen, not this one.

### 4.5 Idle and voice
- On arrival the companion says one line (draft `He.languagesDoorsHello`, needs-editor; voiced in the B-45 batch by the
  companion's voice, frame §1.3: the land is hosted by the companion). No text on screen.
- After 10 s with no tap, the three bubbles pulse once, one after another from the start (240 ms each, 120 ms apart), with
  no sound. Then nothing more. No timer, no countdown, nothing that hurries.
- Semantics: each door unit `Semantics(button: true, label: <language name>)`, the names `He.langEnglish`, `He.langHebrew`,
  `He.langRussian` (drafts below). The hello word is excluded from semantics (the label says the language).

Previews: `doors_phone.png`, `doors_phoneSE.png`, `doors_tabletLandscape.png`, `doors_tabletPortrait.png`,
`doors_phone_opening_heb.png`, `doors_phone_two.png`, `doors_tabletPortrait_two.png`.

## 5. The hosts (`app/assets/art/languages/host_*.svg`, the cast's 512 canvas)

Chosen with no national symbol or stereotype (a language is not a country, frame §1.2), none from the banned list
(design-spec §4), each with its own silhouette:

| Course | Host | What makes it readable |
|---|---|---|
| English | a **budgerigar**, a bird that learns to say words | green body, yellow face, black throat spots, long blue tail, one wing raised in a wave |
| Hebrew | a **rock hyrax** (common in Israel's rocky places, never a national emblem) | a round loaf with no neck, a pointed snout, small dark-rimmed ears, pale patches over the eyes, a big coral pencil |
| Russian | a **giraffe** | long neck, two tufted ossicones, sideways ears, orange patches with cream lines |

They stand in front of their doors in `door_*.svg`. Names, gender of speech and voices are not decided: frame §1.3 gives the
voice to each course's teaching voice (the voice-and-sound-director's pilots), and the names go to the hebrew-text-editor.
**Needs the owner:** `docs/design/languages/doors_tabletLandscape.png`: are these the three hosts you want? If the D6
fallback (two characters per course) is chosen, the second one is a separate drawing.

**Inside the viewBox (QA-L0-3, 2026-11-03):** every element of the six door SVGs, the three hosts, `speaker.svg` and
`land_languages.svg` was measured (headless Chrome: paths sampled along their length, ellipses round their outline, through
every transform, plus half the stroke): nothing crosses its viewBox. The budgerigar's tail now slants back and ends above
the ground line (canvas y 462), and each host stands with its ground at y 294 of the door's 300, so the lowest thing drawn
(the host's shadow) ends at 297 and the door's own shadow at 299. Before, the tail reached 304.6 and the three hosts'
shadows (and the hyrax's feet) 302.8 to 304.7. The door goldens change a little (the hosts are 6 to 8 higher).

Placeholder status: these hosts are drawn as finished cast art, not rigged; mouth shapes (visemes) and poses come later
with the illustrator (P9) or Rive.

## 6. The parent pages (frame §1.4)

Parent visual language as today (`parentBg`, cards with radius 16 and a hairline border, the `night` header, switches,
outlined 44 high buttons, Heebo). Previews: `parent_languages_list_tablet_portrait.png`, `parent_languages_list_phone.png`,
`parent_language_page_rus_tablet_portrait.png`, `parent_language_progress_eng_tablet_portrait.png`.

### 6.1 Rules page of a child: the "Languages" card
- One row per language (the same order as the doors), 56 high: the switch at the start, the language's name (16 / 700),
  under it a state line that says it in words, not only by the switch's colour (`פועלת · יש לה דלת באי השפות` /
  `כבויה · אין לה דלת. כל מה שנלמד נשמר`), and a chevron at the end that opens the language's page.
- A line under the card's title: turning a language off hides its door and keeps everything learned.
- Turning a language on for the first time with Russian opens the home-language questionnaire after the switch (Russian
  syllabus §7.3).

### 6.2 A language's page (one per language)
Cards, top to bottom: **the language** (on / off switch, as in the list); **lesson settings** (the switches of frame §1.4
for that course, each with a one-line explanation): voice answers (says the microphone opens only on the child's tap,
nothing is kept or sent, and that turning it on downloads the recogniser), personal questions in lessons, and per course:
English "oral only", Russian "letters before age 5" and "stress marks on screen" (shows the route default), Hebrew "parent
check of reading aloud"; **the home-language questionnaire** (Russian, a button); **progress in <language>** (a button to
§6.3). Switches are the existing parent switch, 52 x 32, in a row of 56.

### 6.3 Progress in a language
- The same view as a domain's progress, per course and per strand (English: listening and speaking, sounds and letters,
  reading, writing; the teachers give the strand lists).
- Per strand: its name, "we start here: level N" (frame §1.4; the parent may move it one level, a later control), one bar
  of the strand's skills split by status, and **a line of words with the counts** (learning 3 · understood 4 · understood
  and remembered 2 · worth a revisit 1), so the bar is never the only cue. A legend above uses colour **and** the words.
  Status colours: learning `lilac`, understood `sky`, remembered `gold`, revisit `sunset`.
- Cards after it: **gates** (English oral gate, Russian letters gate) with a word chip "open" / "not yet"; **speaking**
  shown only as "practised" or "said" chips, with the line "this is not a score"; **what to notice** (misconceptions found
  and fixed, with their parent text; English or Russian examples in an LTR isolate in Nitznutz Letters); **play together**
  (the co-play cards; Hebrew handwriting cards); for Hebrew, the optional reading-aloud check.
- **Never:** a streak, a "days in a row", "you haven't practised", minutes compared, a chart of one language beside
  another, or one sibling beside another. No per-language time chart (the child's play time stays on the child's main
  progress page, as today).

## 7. New strings (all `"review": "needs-editor"`; English and Russian words to their teachers)
| Key | Draft | Where |
|---|---|---|
| `landLanguages` | אִי הַשָּׂפוֹת | map sign, door screen chip |
| `landLanguagesSemantics` | אי השפות | screen reader |
| `langEnglish`, `langHebrew`, `langRussian` | אנגלית, עברית, רוסית | door labels, parent rows |
| `languagesDoorsHello` | (the editor writes it: the companion invites the child to choose a door) | door screen, voiced |
| `helloEng`, `helloHeb`, `helloRus` | Hello · שָׁלוֹם · Привет | hello bubbles (clips: the course voices) |
| parent texts | the card titles, state lines and switch explanations in the previews | parent pages |

## 8. Assets (all in `pubspec.yaml`: `assets/art/languages/` added; scenes and ui were already listed)
| File | What |
|---|---|
| `app/assets/art/scenes/home_phone_lang.svg`, `home_phone_se_lang.svg`, `home_tablet_landscape_lang.svg`, `home_tablet_portrait_lang.svg` | the 8-land maps |
| `app/assets/art/ui/land_languages.svg` | the 20 point sign icon (two speech bubbles) |
| `app/assets/art/languages/door_eng.svg`, `door_heb.svg`, `door_rus.svg` and `door_*_open.svg` | the doors with their hosts (240 x 300) |
| `app/assets/art/languages/host_eng.svg`, `host_heb.svg`, `host_rus.svg` | the hosts alone (512 x 512) |
| `app/assets/art/languages/speaker.svg` | the hear mark in a hello bubble |

The 7-land scenes are untouched. `make_languages_art.py` reads `tools/home_map_src/` and the landscape scene, so it must be
re-run after any change to `make_home_map.py` or the landscape scene. Run: `python tools/make_languages_art.py` (from the
repo root or `tools/`; no package needed).

## 9. Hand-offs
- **app-developer:** the `_HomeSpec` variants of §2 and the map switch of §1.1 (`home_screen.dart`); the door screen (§4, a
  new `child/languages_doors.dart`); the Languages card, language pages and progress view (§6) in the parent area; the
  fonts of §10. Tests: all 8 `sign-<land>` and `land-tap-<land>` on each board in the 8-land map, the start views of §2,
  tap areas ≥ 64 wide and the gaps of §3, the 7-land map unchanged when all languages are off, one-language-on opens the
  course, the door order, no locked door. Goldens to add: `home_*_lang.png` on the four boards, `home_phone_lang_end.png`,
  `languages_doors_*.png` (four boards, three and two doors), the parent pages on phone and tablet portrait.
- **hebrew-text-editor:** the strings of §7 and the parent texts in the previews.
- **english-language-teacher, russian-language-teacher (through the curriculum-expert):** "Hello" and "Привет" on the
  doors (Russian without a stress mark), the strand names on the progress page.
- **voice-and-sound-director:** the three hello clips (each course's teaching voice) and the companion's door line, in the
  B-45 batch; the door's open sound, if any, fits inside the 200 ms cross-fade.
- **qa-engineer:** after the wiring, the checks of §3 at text scale 1.0 and 1.3 on the four boards.

## 10. Nitznutz Letters in the app (fonts.md §8, built)
Built by `tools/make_letters_font.py`: `app/assets/fonts/NitznutzLetters-Medium.ttf` (59,808 bytes) and
`NitznutzLetters-Bold.ttf` (60,048 bytes), with `OFL-NitznutzLetters.txt` and `FONTLOG-NitznutzLetters.txt`; family
`NitznutzLetters` (500, 700) in `pubspec.yaml`. Checked: U+0430 → the two-storey `a`, U+0061 → `a.SngStory`, all 66
Russian letters and U+0301 present, no "Andika" or "SIL" anywhere in the files' bytes, the stylistic sets removed (so
`ss01` cannot be switched on), the build deterministic. Sheet: `docs/languages/fonts/nitznutz_letters_build1.png`.
For the app-developer: load the family in `test/support/harness.dart` (`loadAppFonts`), add the two TTFs and the OFL file to
the "font files and their licences are bundled" test, and add the font tests of fonts.md §8.5.
