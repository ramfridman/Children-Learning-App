# Nitznutz: art brief for an illustrator

Version 1, 2026-10-28. Written for the owner to hand to an illustrator or a small studio. Everything an artist needs is here or in the folders named below. Prices, timeline and contract are the owner's to agree; this document only says **what to make and how to deliver it**.

## 1. The product in one minute

Nitznutz (נִיצְנוּץ, "a spark") is a Hebrew learning app for children aged 3 to 8. It teaches counting, colours, shapes, logic, first computer-science ideas and money through small, warm activities. The child is accompanied by a friendly companion (a character they choose), collects stickers, grows a little world, and wins trophies that come only from understanding that lasted. There are no ads, no purchases, no timers and no streaks. The app runs on phones (landscape) and tablets, in Hebrew, right to left.

**How it should feel:** calm, kind, bright, a little funny, never loud. Think a picture book that reacts when you touch it. A three-year-old and an eight-year-old should both want to touch every picture.

## 2. The rules that cannot bend

1. **Original work only.** No franchise characters, no look-alikes of existing characters, no imitation of any real person's face or voice. Your reference images must be your own or licensed for this use.
2. **No text inside the art.** The app writes all words (Hebrew, right to left) itself. Convert any lettering to nothing: leave the space empty. Numbers and mathematical signs are also drawn by the app.
3. **Never scary, never sad, never "wrong".** No sharp teeth, no tears, no red crosses, no sad faces. A thing that is "not yet" looks sleepy or pale, never broken.
4. **Maths is never mirrored.** Number lines, clocks, robot arrows and counted rows keep their direction in right-to-left screens. Do not paint a direction that has to flip.
5. **Fits every child.** Skin tones, hair and clothes of people vary; do not draw one default child. Animals and made-up creatures are welcome and are often best.
6. **Calm colour.** Use the palette in section 4. Saturated colour in small doses, large areas soft. Enough contrast for a child who is tired.

## 3. Look and style

The look already exists in the project's design boards. Match it; do not restyle it.

- **Shapes:** flat vector shapes, rounded corners, friendly proportions (big head, big eyes, soft limbs).
- **Outline:** dark ink (`#2B2350`) outline only where it helps reading (the small friends and objects); large soft shapes (islands, sea, sky) have none.
- **Shading:** one soft shade tone and one highlight per object, no gradients that look airbrushed, no textures. A white highlight stroke at 55 percent opacity (see the trophy bowl) is part of the house style.
- **Faces:** simple dot eyes with a white spark, small smile, pink cheeks. Expressive but quiet.
- **A little imperfection is welcome:** tilted tiles, a leaning flag. Nothing should look like a template.

**Look at these first** (all in the repository, folder names exact):

| What | Where |
|---|---|
| All screens as pictures | `design/renders/01` to `36` (`.png`) and `design/boards/INDEX.md` |
| The cast of friends and heroes | `design/assets/` (`goni`, `kubi`, `nekudi`, `pnina`, `timi`, `tzaadon`, `hero-*`, `nitzi-*`) |
| Trophies, medals, scarves, rosette, podium | `design/renders/31`, `32`, `33`; the files in `app/assets/art/trophies`, `medals`, `prizes`, `ceremony` |
| The world map | `design/renders/04`, `10`, `22` |
| Every colour and size | `design/tokens.json` |
| Pieces that are **placeholders to replace** | `app/assets/art/world/*.svg`, `decorations/deco_10.svg` and `deco_30.svg` (lantern, fountain), `medals/medal_try-again.svg` and `medal_bug-fixer.svg` (glyphs only) |

## 4. Palette

Use these first. Other colours are allowed in small amounts, but they must sit well beside them.

| Name | Hex | Used for |
|---|---|---|
| ink | `#2B2350` | outlines, eyes, text |
| cream / paper | `#FFF6E8` / `#FFFFFF` | backgrounds, cards |
| mist / cardLip | `#EDE6F7` / `#DCD3EC` | empty places, soft shadows |
| spark / sparkDeep | `#FFC83D` / `#E0A21A` | gold, highlights, buttons |
| sunset / sunsetDeep | `#FF8A3D` / `#D9692A` | the "go on" button |
| sea / sky | `#1A9E9A` / `#8FD3F4` | water, air |
| night / lilac | `#3B2C85` / `#B9A2F7` | trophy bases, ceremony stage |
| Numbers | fill `#F46A5E`, tint `#FFE3DF` | Counting Hills |
| Colours | fill `#E04F9E`, tint `#FCE1F0` | Colour Bay |
| Shapes | fill `#34A86A`, tint `#DDF3E6` | Shape Forest |
| Logic | fill `#8A5CF0`, tint `#ECE3FE` | Riddle Grotto |
| Computer science | fill `#2F7FE0`, tint `#DEEBFC` | Robot Harbour |
| Money | fill `#F59E1B`, tint `#FEEFD6` | Market Village |

## 5. How to deliver

**Format.** One SVG file for every picture. SVG 1.1 only; the app draws it with Flutter's SVG renderer, which does **not** support everything.

- **Allowed:** paths, rectangles, circles, ellipses, polygons, groups, `transform`, solid fills, strokes, linear and radial gradients (sparingly), opacity, `clipPath` (simple).
- **Not allowed:** `<text>` (outline it or leave it out), `filter` (blur, drop shadow), `mask`, blend modes, CSS classes or `<style>`, embedded raster images, external references, fonts, scripts, animation tags.
- **Size:** under 40 KB per file; fewer than 400 nodes where possible. Round coordinates to one decimal.
- **Canvas:** the sizes in section 6. Draw inside the canvas with 4 percent of padding. The picture must read when shown at 64 points tall.
- **Layers and names:** group parts that will move or change (section 7) and give each group an `id` such as `body`, `fruit`, `flag`. Keep ids lowercase with dashes.
- **File names:** exactly as in the tables (`kind_id.svg`, lowercase, dashes). A `.png` preview at 1024 pixels beside each file. The editable source (`.ai`, `.afdesign`, Figma or similar) is part of the delivery.
- **Rights:** the owner receives full, exclusive, perpetual rights for the app and its updates, including the right to change the work. If any AI tool was used in any step, say so before starting; the owner decides whether that is acceptable.

**Process.** First, three **sample pieces** for approval of the style before the rest: one skill drawing in its stages (section 6.1), one sticker, one island scene. Then the full set in the order of section 8, with two rounds of corrections for each batch.

## 6. What to make

### 6.1 Skill drawings (the biggest job, and the one that matters most)

Every skill a child learns is one small picture standing on its land. It **grows** as understanding grows: first a pale pencil sketch, then full colour, then full colour with fruit and a golden star. The app makes the stages from your drawing (fade, add star and fruit), so a **single colour drawing** works; but a hand-made **sketch version** (line only, ink at 35 percent, with the main shapes empty) is better than a faded copy, and is requested.

Each drawing should be a small, friendly, self-contained thing that fits the land and can be touched: it is tapped to show what the skill is and, when a check is due, a bell flag appears on it. Leave room at the top for the flag (right) and the dry leaf (left).

- **Canvas:** 512 by 512, the picture standing at the bottom centre, a soft ground shadow ellipse included, about 80 percent of the canvas tall.
- **Files:** `world/<id>.svg` (colour) and `world/<id>_sketch.svg` (line only).
- **Quantity:** the first content release has about **95 skills in six lands**. Ask for **24 families (4 per land)**, each family drawn so it can be recoloured or changed a little (a different number of steps, a different colour of paint) to serve about four skills. If the budget allows, one **unique drawing per skill** is better. The ids are given by the owner with the skill list (one list per land) at the start of the work.
- **Themes (not a rule, a direction):**
  - Counting Hills: stairs, ladders, hill paths, stacked stones, baskets of fruit, a row of flags.
  - Colour Bay: paint pools, boats with sails of mixed colour, brushes, rainbows in the spray.
  - Shape Forest: trees with shaped leaves, a cone tree, a round stone, a square house, a path of triangles.
  - Riddle Grotto: cave doors with patterns, lanterns, puzzle pieces, a key and a lock, an owl.
  - Robot Harbour: a dock grid, a crane, a small robot, a ship of blocks, an arrow sign.
  - Market Village: stalls with striped roofs, coins, scales, baskets, a till.
- **Today's placeholders** (to be replaced): `stair`, `pool`, `cone-tree`, `pattern-door`, `dock`, `stall`, `sprout` in `app/assets/art/world/`.

### 6.2 Islands (backgrounds)

One scene for each of the six lands and one for Nitzi's own island. The child looks at it for minutes: calm, with a little to discover. Drawn in separate layers so the app can move them gently: sky, far sea, near sea with foam, the island (sand edge, grass), a few set pieces (a lighthouse, a tree, a hut) that are **not** skills.

- **Canvas:** 1180 by 820 (tablet landscape). It is cropped for phones, so keep the important things inside the middle 852 by 393 area.
- **Files:** `scenes/island_<land>.svg` with groups `sky`, `sea-far`, `sea-near`, `island`, `props`, `foam`. Lands: `counting`, `colors`, `shapes`, `logic`, `robots`, `market`, `nitzi`.
- **Free space:** leave the central grass area open (about 700 by 330) for the skill drawings, and 120 points free at the top (title) and bottom (buttons).
- **The world map (home screen) is separate from these scenes** (B-23). On phones it is one strip of all 7 islands that pans sideways, home island at the right end: 2102 by 393 (phone) and 1834 by 375 (iPhone SE), islands 280 (SE 252) apart, each island about 250 by 140 with its landmark and host. On a tablet in portrait it is one 820 by 1580 scene that scrolls up, Market Village at the top; tablet landscape stays one 1180 by 820 screen. Deliver the map at these sizes as `scenes/home_phone.svg`, `home_phone_se.svg`, `home_tablet_portrait.svg`, `home_tablet_landscape.svg`, with the islands at the same centres as today's placeholders (`tools/make_home_map.py` prints them), so the signs and tap areas still fit. No text or numerals in the picture; the clock tower's clock has hands only.

### 6.3 Stickers and the Sticker Island

A sticker is given for every lesson the child finishes. They are collected as tilted white tiles. The first 12 are the cast of friends (already drawn). The first content release has more than a hundred lessons, so ask for **36 designs in all**: 24 new ones. Groups: friendly animals, little made-up creatures, gentle objects (a kite, a paper boat, a lantern), and the heroes in new poses. Each is one character or object, front or three-quarter view, a cheerful pose.

- **Canvas:** 512 by 512, the figure centred with a soft ground shadow. Files `stickers/sticker_13.svg` to `sticker_36.svg`.

### 6.4 Trophies, medals and the Hall

The trophy cups, their glyphs and the medals already exist for the starter content and are good. To make:

- **Medal glyphs:** a clear, one-colour glyph (24 by 24 box, dark `#3B2C85` on white disc) for "Try again" (a circular arrow, redraw), "Bug fixers" (a bug, redraw) and for new medals the owner will name. About **8 more habit medals** over time.
- **Island decorations:** redraw the lantern and the fountain and make **9 more** (a bench, a bridge, a windmill, a kite pole, a bird bath and so on), each earned at a number of skills understood (10, 20, 30 ...). Canvas 256 by 256, files `decorations/deco_<n>.svg`.
- **Trophy stands for the seven lands:** optional, a small sign or plinth in the land's colour, 120 by 40.

### 6.5 The companion's prizes

Prizes are worn by the companion. Today a plain scarf is drawn by code. To make: **a scarf, a cap and a pair of glasses (a "fun accessory"), in three colour sets**, drawn so each fits **every one of the nine characters** (they are drawn differently: a ladybug, a turtle, a fox, an octopus, a robot and the three children). Draw each prize as a separate layer with an **anchor point** at the neck or head and a width in percent of the character's canvas; the owner will give you the nine character files with their sizes (`design/assets` and `content/characters`).

- **Files:** `prizes/<item>_<colourset>.svg` (for example `scarf_sky.svg`), 256 by 256, anchor marked with a small circle in a group `anchor` (it is deleted at build time).

### 6.6 The ceremony

A short celebration when a trophy or medal is won: dimmed room, a cone of light, a podium, the cup spinning in, confetti, sparkles. To make:

- **Podium:** three variants (bronze, silver, gold), 360 by 150, replacing today's plain wooden podium.
- **Light cone:** one soft shape (no blur: three nested translucent cones), 600 by 800.
- **Confetti and sparkles:** a sheet of **12 shapes** (ribbons, circles, stars, curls) in the palette, each 48 by 48, one file per shape `ceremony/confetti_<n>.svg`; and **4 sparkle shapes** `ceremony/spark_<n>.svg`.

### 6.6b Counting things (the activity sprites, M9)

The lessons count and compare "things", so these simple pictures appear many times on a small stage (down to 24 points tall, in groups of up to 10, sometimes as small ones next to big ones). Each must be a **single clear shape**, readable at a glance, with a friendly face only where it is an animal. Each comes with a **lit twin** (a soft glow, used when a child touches it while counting). The current files are plain placeholders in `content/starter/` (made by `tools/make_unit_sprites.py`); deliver the real ones under the **same ids** and they replace the placeholders with no change to any lesson.

| Id | What | Notes |
|---|---|---|
| `ladybug`, `star`, `apple`, `fish`, `bird`, `duck`, `cat`, `dog` | counted things and the animals of a queue | each also as `<id>_lit`; the animals must look good in a row of four |
| `tick`, `cross` | "yes" and "not the same" answers | no red-versus-green only: also a different shape |
| `basket_target` | where things are put when a child gives some | open top |
| `nest_empty`, `bowl_empty`, `basket_empty` | an **empty** nest, bowl and basket (the picture of "none", so zero must be easy to see) | full stage backgrounds, 16:9, the middle free |

More of these arrive with each new unit (the list is kept in `content/units/*.json` under `assets`).

### 6.7 Buttons and small signs

The child's buttons are round "pebbles" with a clay lip, with a picture on them. Restyle only if your style asks for it; keep each picture one dark colour on a light disc (or white on orange): `ui/`: book, bottle, eye, hint, home (a palm island), lock, microphone, plus, spark, sticker, play, speaker, back. Also: a **bell flag** and a **dry leaf** for the revisit marker (today `world/bell_flag.svg`, `leaf_dry.svg`), a **golden star** and **fruit** (`world/star_gold.svg`, `fruit.svg`).

## 7. Motion (specify now, decide the technology later)

Nothing in the app is still. Please deliver **keyframe poses** that make these moves possible, as separate groups or extra files; the owner and the developer will choose how to play them (a small animation library or sprite swaps; a new library needs the owner's approval first).

| Move | Length | What changes |
|---|---|---|
| Skill drawing grows (sketch to colour to fruit) | 1.2 s | the line drawing fills with colour, the fruit pops in one by one, the golden star drops from above with a small bounce |
| Skill drawing idle | 4 s loop | a gentle sway of leaves, flags, sails, steam; one small thing that blinks or twinkles |
| Bell flag | 1.6 s loop | the flag waves, the leaf droops a little |
| Sticker arrives | 0.6 s | pops in with a small overshoot, a sparkle, the corner "peels" down |
| Trophy shine | 0.8 s | a diagonal glint across the cup |
| Medal swing | 1 s | the ribbon swings once and settles |
| Companion reacts | 0.9 s each | cheer (arms up), wave, think, a small hop (the nine characters already have poses; new ones only for what the app lacks) |

Provide, for each moving object: the still colour version, the parts as groups (for example `body`, `leaf-left`, `leaf-right`, `flag`), and for each move a one-line note of how far and how long. A sheet of timing notes per object is enough.

## 8. Quantities and order of work

| Batch | What | Count | When needed |
|---|---|---|---|
| 0 | Three sample pieces for style approval | 3 | first |
| 1 | Skill drawings and sketches for the first land (Counting Hills) and its island scene | about 16 skills + 1 scene | before the content release |
| 2 | Skill drawings, sketches and scenes for the other five lands | about 80 skills + 6 scenes | with the content |
| 3 | Stickers 13 to 36 | 24 | with the content |
| 4 | Ceremony pieces, podiums, confetti, sparkles | about 20 | after batch 1 |
| 5 | Island decorations and medal glyphs | about 20 | after batch 1 |
| 6 | Companion prizes for nine characters | 3 items x 3 colours x 9 | last |
| 7 | Motion notes and extra poses | per object | alongside each batch |

## 9. Acceptance checklist (the owner ticks each batch)

- [ ] Every file opens in a browser and in the app without errors; none uses a forbidden feature (section 5).
- [ ] Still readable at 64 points tall on a phone, and at 256 on a tablet.
- [ ] Palette and outline match the existing boards; the batch looks like one hand made it.
- [ ] No text, no franchise look-alike, nothing scary or sad, no mirrored maths.
- [ ] Names and ids exactly as in the tables; previews and sources delivered.
- [ ] Sizes and file counts as agreed; the central free space of each island respected.
- [ ] A child of 3 and a child of 8 each pointed at something in it and smiled.
