# Nitznutz (נִיצְנוּץ): Design & UX Specification

**Role:** Design & UX Lead · **Status:** v1.0 for merge into the product plan · **Date:** October 2026
**Companion files:**
- `design/tokens.json`: the single source of truth for every colour, type, spacing, radius, elevation, touch, motion and voice value. The Flutter theme imports it, and every artboard copies values from it.
- `design/assets/`: character SVG masters.
- `design/boards/`: 27 HTML artboards (see `boards/INDEX.md`), with PNG renders in `design/renders/`.

**Reference devices:** iPhone 16 landscape 852×393 (safe areas 59/59/21), iPhone SE 667×375, and iPad 10th gen 1180×820 / 820×1180.

This document defines the app's experience: the world, characters, screens, interaction rules, design system, motion, sound and testing plan. It uses the shared working decisions (Bands A/B/C, six domains, tap-first with optional voice, gender rules, LTR maths inside RTL screens, no dark patterns). Assumptions are flagged with **[Assumption]**. Decisions for the product owner are collected in §16.

---

## 1. Experience vision and design principles

**Vision.** A child opens the app and finds a small, glowing archipelago that is *theirs*. A curious little star‑jerboa called Nitzi is waiting there. Everything the child learns makes the islands grow: a staircase rises on Counting Hills, a new colour pours into the bay, a lighthouse lamp comes on. The learning is real and well sequenced, and the world is the visible proof of it. Parents trust the app because nothing in it is trying to trick their child.

**Design principles** (each one is testable):

1. **Learning is the toy.** The fun comes from the thinking itself: counting the ladybug's spots, steering the robot, mixing paint. Rewards decorate learning but never replace it, and no activity is a reflex game with a quiz bolted on (Hirsh‑Pasek's "minds‑on, not just hands‑on" [[APS]](#17-sources)).
2. **Hear it, see it, never need to read it.** Every instruction is spoken first and shown as icons and pictures. Text is support (with nikud) and is never the only channel. A replay button is on every child screen.
3. **One thing moves at a time.** While Nitzi speaks, the scene holds still. Motion and sound point at what matters and never compete with it. Distracting "bells and whistles" hurt learning [[Register/Sesame]](#17-sources).
4. **Real understanding, at the child's own pace.**
   - There are no countdowns or speed pressure in *any* band.
   - Replay, more thinking time, "show me" and "I'm not sure" are always available, and asking for help is welcomed like a good answer.
   - When something doesn't click, Nitzi **tries another way** (objects, a picture, a number line, a story) instead of repeating louder.
   - Mistakes are safe: a gentle wobble with no red X, buzzer or lives, and the line "גַּם טָעוּת הִיא צַעַד!" ("A mistake is also a step!").
5. **The world grows because you understood, and shines when it lasts.**
   - World‑building is the main reward and maps to mastery.
   - Earlier lands "call for help" weeks later. Passing these playful revisits gives a building its **golden star**, the visible sign of durable understanding.
6. **Big, forgiving and predictable.** Touch targets are sized in millimetres per band. The app ignores resting hands and repeated taps, and drags can be replaced by tap‑then‑tap. The same control always sits in the same place.
7. **Your voice is welcome, never required.** Speaking to Nitzi is a delight, with ears that perk up and a tail that glows with the child's voice. Every item can still be answered by tap, and when Nitzi doesn't understand, she blames her own ears.
8. **Calm endings, no hooks.** Sessions end with a dusk ritual, not a cliff‑hanger. There are no streak threats, guilt‑tripping characters, countdowns or "come back for a prize" lures [[Michigan]](#17-sources).
9. **Made for here.** The app is Hebrew‑native, not translated: right‑to‑left flow, real nikud, shekels, the shuk, a Negev‑desert hero, and maths written the way Israeli classrooms write it.
10. **Grown‑ups are partners.** Co‑play prompts, real‑world missions and a plain‑Hebrew dashboard turn screen time into shared time, building on the "socially interactive" pillar and the value of joint media engagement [[Sesame/JGCC]](#17-sources).

---

## 2. Name and brand

### 2.1 Name options (all original coinages or common words; trademark search required, see §16)

| # | Name | Meaning | Why kids will say it |
|---|------|---------|----------------------|
| 1 | **נִיצְנוּץ** (*Nitznutz*) | "A twinkle, a sparkle" | A bouncy, reduplicated sound (nitz‑nutz) that echoes the mascot's name, Nitzi. It names the core mechanic, since the world lights up as you learn. |
| 2 | **אִי־פֶּלֶא** (*I‑Pele*) | "Wonder Island" (pun: אִי means island) | It is short and descriptive, and parents understand it instantly. Kids are less likely to *say* it unprompted. |
| 3 | **הוֹפְּלָה** (*Hopla*) | The exclamation for a little hop or landing | Kids already shout it, and it fits a hopping jerboa. Risk: it sits close to the "Hop!" kids' TV brand. |
| 4 | **נִיצִי** (*Nitzi*) | The mascot's name, from נִיצוֹץ ("spark") | The easiest of all to say. It ties the brand to the character, but it is weaker as a "world" name. |
| 5 | **סַקְרָנִיָּה** (*Sakraniya*) | "Curiosity‑land" | A charming place‑name coinage with a good meaning for parents, but it is long for a 3‑year‑old. |

**Recommendation: נִיצְנוּץ (Nitznutz).** The mascot is **נִיצִי** (Nitzi), and the world is **אִיֵּי נִיצְנוּץ** ("the Nitznutz Islands"). Children will naturally ask for "Nitzi", and that works as the brand nickname.

**Tagline:** **כָּל צַעַד מֵאִיר** ("Every step lights up").

### 2.2 Wordmark direction
- Set in **Secular One** (Hebrew), with letters individually baseline‑bounced (±3% of cap height), so the word looks like it is hopping. The wordmark is drawn with niqqud (נִיצְנוּץ) for children and without it for adult contexts.
- A small **4‑point spark** replaces the dot area above the second נ, and Nitzi's tail‑spark is the brand's only "logo glyph".
- Colourways: night‑ink letters on cream (primary), cream on night‑indigo (secondary), and a single‑colour version for embossing and print.
- App icon: Nitzi's head and ears on a deep‑teal circle, with the gold spark at the top‑left. It is readable at 29 pt, and the ear silhouette carries recognition.
- See **01‑brand** artboard.

---

## 3. The world and story

### 3.1 Narrative hook
> One night a shooting star splashed into a warm, quiet sea. Out hopped **Nitzi**, a little *star‑jerboa* with giant ears, whose tail‑tip still holds a spark of starlight. She landed on a tiny island with a single tree. "If we learn things together," she says, "my spark can jump. And wherever it lands, something grows!"

The hook is a *home being built together*, not a rescue. Nitzi is never sad, sick or in danger because of the child. This deliberately avoids the "parasocial pressure" pattern, where characters guilt children into playing [[Michigan]](#17-sources).

### 3.2 World map: אִיֵּי נִיצְנוּץ (the Nitznutz Islands)
An illustrated archipelago at golden hour, seen in a gentle top‑down/¾ view. **Progress runs right→left (RTL "forward")**: the home island sits at the right of the map, and new lands unfold leftwards.

| Land (Hebrew) | English | Domain | Host friend | Landmark / signature |
|---|---|---|---|---|
| **הָאִי שֶׁל נִיצִי** | Nitzi's Island (home) | — | Nitzi | Tree‑house, spark lighthouse, the beach where the daily bottle arrives |
| **גִּבְעוֹת הַסְּפִירָה** | Counting Hills | Numbers | Nekudi (ladybug) | The number staircase 1–10 grows step by step; dot‑pattern stepping stones |
| **מִפְרַץ הַצְּבָעִים** | Colour Bay | Colours | Goni (chameleon) | Paint waterfall, rainbow arch, mixing pools |
| **יַעַר הַצּוּרוֹת** | Shape Forest | Shapes | Kubi (tortoise) | Cone trees, sphere bushes, cube rocks, a symmetry pond |
| **מְעָרַת הַחִידוֹת** | Riddle Grotto | Logic | Timi (octopus) | Sea cave with pattern doors and sorting shells |
| **נְמַל הָרוֹבּוֹטִים** | Robot Harbour | Computer Science | Tza'adon (robot) | Grid docks, a crane, a lighthouse path |
| **כְּפַר הַשּׁוּק** | Market Village | Math | Grandma Pnina (pelican) | Striped awnings, clock tower, scales, shekel coins |

Each land has its own **silhouette, colour, glyph and character**, so a land is never identified by colour alone (§9.2).

### 3.3 World‑building as the main reward
- **Growth is mapped to skills.** Every curriculum skill (defined by the content agent) owns one *growth object* in its land. For example, *counting to 5* builds steps 1–5 of the Counting Hills staircase, and *primary + primary mixing* fills the first mixing pool. When the skill reaches "practising", the object appears as a sketchy outline. At "mastered", it is drawn in full colour with a Tier‑3 celebration (§10.3).
- **Not‑yet‑built areas are sketches, not padlocks.** Future objects appear as soft, dashed pencil outlines, as if Nitzi had drawn a plan. This invites curiosity ("what will be there?") without the feeling of being locked out.
- **Friends move in.** The first lesson in a land brings its host to the land. Later milestones bring visitors (Nekudi visiting the market, Goni painting Kubi's shell), which makes the world feel alive and connected across domains.
- **Revisits as play: "קְרִיאוֹת עֶזְרָה" (calls for help).** Spaced retrieval is staged as the world asking the child for help. Spaced sessions with effortful recall beat massed practice for children's long‑term retention [[Spaced learning]](#17-sources).
  - **What a call looks like.** When a mastered skill is due for a check (scheduled adaptively by the learning engine's memory model, FSRS‑style, per child and per skill), its growth object raises a **help flag**: a small wooden sign with a bell, plus the host friend waving. A board is missing from the Counting Hills bridge, Grandma Pnina's garden "needs counting", or the paint pool in Colour Bay has faded to pastel.
  - **What happens.** Tapping the flag opens a 3–5 item mini‑mission that mixes the old skill into a fresh context.
  - **Nothing ever breaks or decays as a threat.** The object keeps all its colour while it waits. The flag is an invitation, not damage.
  - **Limits.** At most two calls for help show at once, and Today's Adventure warm‑up stop draws from them first.
- **Golden stars for lasting understanding.** **Durable mastery** means passing a delayed check at least **7 days** after mastery, on a *different item* than the ones practised. It gives the object a **golden star**: a gold rim and a small star pennant that twinkles once per visit. The land's sign gains a star counter, so the map shows *understood and remembered* at a glance. If a revisit reveals a gap, the host says "בּוֹאוּ נִתְאַמֵּן יַחַד!" and the skill quietly re‑enters practice through "try another way" (§5.4.1). The object stays built, and the star waits for next time.
- **Seasons and calendar.** Light seasonal dressing (autumn sea mist, winter rain puddles, spring flowers) follows the Israeli year. Holiday dressing is optional and parent‑controlled **[Assumption]**, so it respects the full range of Israeli families.

### 3.4 Daily rhythm: "בַּקְבּוּק הַבֹּקֶר" (the morning bottle)
1. **Arrival.** On the first launch of the day, a glass bottle bobs to Nitzi's beach. The child taps it, and a hand‑drawn map scroll unrolls: **הַהַרְפַּתְקָה שֶׁל הַיּוֹם** ("Today's Adventure"), with **3 stops** (about 8–12 minutes in total).
2. **Stops.** The three stops are a warm‑up (review/spaced repetition), a new skill, and a playful apply‑it activity (creative or a mini‑story). The content agent owns the sequencing logic, and this spec owns the presentation.
3. **Free exploring.** After the adventure, or instead of it, every unlocked land is open. The adventure is an invitation, never a gate.
4. **Dusk wind‑down.** At the end of the session, the sky turns violet. The sparks earned today rise from Nitzi's tail and join into a small **constellation** in the "Sky Journal" (יוֹמַן הַשָּׁמַיִם), shaped after what was practised: a triangle after shapes, a staircase after counting. Nitzi yawns, says goodnight and curls up (§5.7).

---

## 4. Characters

**Design rules for the whole cast:**
- Each character is built from simple primitives (circle, oval, rounded square, triangle) and has a **unique silhouette** that is readable at 48 px as a black fill.
- They are flat‑shaded with a single shadow tone and drawn in parts ready for Rive rigging (separate ears, eyes, mouth, limbs, tails and props).
- Front or ¾ views are used for talkers, so the mouth is visible for lip‑sync.
- Pre‑recorded lines are gender‑neutral toward the child (plural imperative). Each character has a fixed grammatical gender for its *own* speech.
- None of the cast is a bear, elephant, red panda, hummingbird, dog, monkey, owl or electric mouse, so they stay clear of known kids' casts.

### 4.1 Nitzi (נִיצִי): mascot and AI tutor (she/her)
- **Species/look:** an original "star‑jerboa" (יַרְבּוֹעַ־כּוֹכָב), inspired by the Negev desert jerboa. She has an apricot‑sand coat, a cream face mask and belly, enormous oval ears with pink inner ears, huge friendly eyes, long jumping feet, a teal neckerchief, and a thin tail ending in a **golden star‑spark**.
- **Silhouette:** two tall ovals over a round head on a pear body, with a long tail ending in a star. It reads from across a room.
- **Personality:** endlessly curious, a little clumsy, quick to giggle, and genuinely impressed by the child. She is a big‑sister / favourite‑gan‑teacher energy, not a know‑it‑all. She asks as many questions as she answers.
- **Role in learning:** the child's tutor and companion. She gives every instruction, hosts the daily adventure, offers hints in three steps (§5.4), listens to spoken answers, and models thinking aloud ("hmm, let me count again…"). She is the only character driven by the AI tutor. Friends speak short pre‑recorded lines.
- **Voice direction:** a female actor in her 20s–30s with a warm, bright, slightly husky tone, as if smiling while speaking. She should use natural, standard Israeli Hebrew with crisp diction and avoid shrill "kids' TV" pitch. Band A delivery is slow, with a pause after each key word ("כַּמָּה… פְּרָחִים?"). Bands B–C use a natural conversational pace. Laughs, gasps and "hmm"s are recorded as a reusable library.
- **Catchphrases** (pre‑recorded, neutral):
  - "הוֹפּ־הוֹפּ, בּוֹאוּ נַתְחִיל!" ("Hop‑hop, let's start!")
  - "אֲנִי מַקְשִׁיבָה בְּכָל הָאָזְנַיִם!" ("I'm listening with all my ears!"), which is the voice‑answer signature
  - "נִיצוֹץ קָטָן, רַעְיוֹן גָּדוֹל!" ("Little spark, big idea!")
  - "גַּם טָעוּת הִיא צַעַד!" ("A mistake is also a step!")
- **Why the ears matter:** the listening state is the safest‑feeling moment in the app. When the mic opens, her ears **rise and swivel toward the child** and her inner ears glow, and **her tail‑spark brightens with the child's live voice level**. Children see that they are being heard, which matters because young children escalate volume and repetition when they are unsure a device hears them [[Quack]](#17-sources).
- **Key expressions and poses** (art in `assets/nitzi-*.svg`, sheet on board **02**):
  - **idle:** gentle smile, slow breathing, blinks every 2–6 s, ear twitches.
  - **talking:** mouth driven by visemes; small head bobs on stressed syllables.
  - **listening:** ears tall and forward, a cupped paw at one ear, eyes wide and soft, tail‑spark pulsing with voice level.
  - **thinking:** eyes up and to the side, a paw on her chin, one ear folding over, three "thought dots" pulsing.
  - **encouraging:** a thumbs‑up paw, raised brows and a warm closed smile.
  - **celebrating:** a hop with squash and stretch, arms up, eyes squeezed happy, and a tail‑spark burst.
  - **sleepy:** ears drooping like a blanket, slow blinks, a yawn, a dim tail‑spark and floating "z" shapes.
  - **surprised:** ears shoot straight up, round eyes, an "O" mouth and fur puffing for 2 frames.
- **Lip‑sync design:** the mouth sits on the cream face mask with no fur overlap, a dark interior and a pink tongue shape. It has 10 interchangeable mouth shapes (§10.4).

### 4.2 Nekudi (נְקוּדִי): Numbers host (she/her)
- **Look:** a round coral‑red ladybug with a dark indigo head, big white eyes and ball‑tipped antennae. Her **spots can rearrange** into dice and ten‑frame patterns, which makes her a walking subitizing tool. Silhouette: a circle on a circle with two antennae.
- **Personality:** bubbly, quick, loves lining things up and counting *everything*.
- **Voice:** a light, quick female voice with a rhythmic counting cadence.
- **Catchphrases:** "אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, נְקוּדָה!", "כָּל נְקוּדָה נִסְפֶּרֶת!"
- **Role:** she demonstrates counting (touching each spot), jumps along the number line, and turns her spots into quantities.
- **Key poses:** waving; counting (one leg pointing at her spots); hopping; spot‑shuffle.

### 4.3 Goni (גּוֹנִי): Colours host (he/him)
- **Look:** a chubby, side‑view chameleon with rainbow bands across his back, a spiral tail, a turret eye and a little magenta artist's beret. Silhouette: a teardrop body with a spiral tail.
- **Personality:** a dreamy, gentle artist who gasps at beautiful colours and loves "what if we mix…?"
- **Voice:** a soft male tenor, unhurried and wonder‑filled.
- **Catchphrases:** "וָאוּ, אֵיזֶה צֶבַע!", "מָה יִקְרֶה אִם נְעַרְבֵּב?"
- **Role:** he changes body colour to match the colour being taught, models mixing, and narrates shades (light/dark).
- **Key poses:** admiring; colour‑shift; painting with his tail.

### 4.4 Kubi (קוּבִּי): Shapes host (he/him)
- **Look:** a side‑view tortoise whose shell is a mosaic of triangles, squares, circles and hexagons, wearing a striped **cone** party hat. Silhouette: a dome with a head and a cone.
- **Personality:** slow, steady, a cosy builder who says "let's look carefully" and never rushes.
- **Voice:** a deep, warm, slow male voice.
- **Catchphrases:** "לְאַט לְאַט, צוּרָה וְעוֹד צוּרָה", "בּוֹנִים בְּיַחַד!"
- **Role:** his shell tiles pop out to become puzzle pieces. He models spatial language (מֵעַל, מִתַּחַת, לְיַד) and symmetry.
- **Key poses:** peeking; building; shell‑tile pop.

### 4.5 Timi (תִּימִי): Logic host (she/her)
- **Look:** a lilac octopus with a magnifying glass in one tentacle and a puzzle piece in another, and a different object in each arm, so she is literally *sorting*. Silhouette: a dome with curling arms.
- **Personality:** a curious little detective who whispers "secrets" (patterns) and giggles when one is found.
- **Voice:** a playful, slightly breathy female voice that drops to a stage whisper.
- **Catchphrases:** "יֵשׁ פֹּה סוֹד… בּוֹאוּ נְגַלֶּה!", "שְׁמוֹנֶה זְרוֹעוֹת, רַעְיוֹן אֶחָד!"
- **Role:** patterns, sorting, odd‑one‑out, if‑then. She holds items up for comparison.
- **Key poses:** inspecting; sorting with many arms; "aha!" with tentacles up.

### 4.6 Tza'adon (צַעֲדוֹן): Computer Science host (he/him)
- **Look:** a small blue robot with a rounded‑square body and a dark screen face whose cyan eyes change shape. **A green sprout grows from his antenna.** His chest buttons are a circle, triangle and square (shape‑coded, not colour‑coded). Silhouette: a rounded square with a sprout.
- **Personality:** literal‑minded and earnest. He does *exactly* what he is told, which is the whole joke and the whole lesson in debugging.
- **Voice:** a warm male voice with clipped rhythm and a very light vocoder at most. Intelligibility first.
- **Catchphrases:** "צַעַד, וְעוֹד צַעַד, בִּיפּ־בּוּפּ!", "תְּנוּ לִי הוֹרָאוֹת!"
- **Role:** he executes the child's programs on the grid. When a program goes wrong he bumps into a crate *gently* and looks puzzled, which invites debugging.
- **Key poses:** waving; stepping; turning; "bonk" (puzzled).

### 4.7 Grandma Pnina (סַבְתָא פְּנִינָה): Math host (she/her)
- **Look:** a side‑view pelican with round glasses, a teal apron with a coin pocket, a flower in her crest, and a pouch that carries Jaffa oranges. Silhouette: a big beak and pouch on a pear body.
- **Personality:** a warm shuk‑stall savta. She is generous, funny and full of stories, and every story hides a sum.
- **Voice:** an older female actor (60s+) with a warm, smoky laugh and a market‑caller lilt.
- **Catchphrases:** "אוֹי, אֵיזֶה יֹפִי!", "בּוֹאוּ, בּוֹאוּ, יֵשׁ תַּפּוּזִים!"
- **Role:** she sets word problems, weighing and measuring, shekel shopping, the clock tower, and fruit‑stand graphs.
- **Key poses:** selling; weighing; storytelling.

### 4.8 Child avatars
Child avatars are simple round child portraits with selectable skin tones (6), hair styles (10, including curls, braids, buns, short, kippa and headscarf options), glasses, and a background colour + glyph. They are used in the profile picker and dashboard. Avatars are not real photos.

### 4.9 Character pack system (pluggable cast)
The owner will keep adding characters, so **no screen references a specific character**. Screens reference **role slots**, and a *character pack* fills them. A new character drops into every existing view without any redesign. The board is **06‑character‑system**.

#### 4.9.1 Role slots

| Slot | Where it appears | Default filler | Box (phone / tablet, pt) | Anchors used |
|---|---|---|---|---|
| **Guide** (מַדְרִיךְ) | Guide rail in every activity; speaks all instructions; drives voice listening states; AI tutor voice | Nitzi | 176×220 / 260×320 (compact "peek": 120×120) | `bubble`, `mic`, `hand`, `eyes` |
| **Domain friend** (חָבֵר הָאִי) | Hosts a land; appears on the lesson path, intros, error‑spotting play | Nekudi, Goni, Kubi, Timi, Tza'adon, Pnina | 140×160 / 200×230 | `bubble`, `hand`, `feet` |
| **Activity helper** (עוֹזֵר) | Small in‑scene actor: carries objects, demonstrates "show me", walks the robot path | Domain friend or hero | 96×96 / 140×140 | `hand`, `feet`, `prop` |
| **Celebration cameo** (הוֹפָעַת חֲגִיגָה) | Tier‑2/3 celebrations; leaps in from the end side | Child's companion | 220×260 / 340×400 | `feet`, `burst` |
| **Map companion** (בֶּן לְוָיָה) | Walks/hops beside the child's avatar on the world map; points at calls for help | Child's companion | 72×88 / 110×130 | `feet`, `point` |
| **Collectible** (מַדְבֵּקָה) | Sticker card and Sticker Island figurine | Every character | 120×120 / 160×160 die‑cut | `center` |

#### 4.9.2 Shared rig and animation contract
Every *full pack* (Rive) character must provide:
- **States** (identical names for every character): `idle`, `talk`, `listen`, `think`, `encourage`, `celebrate`, `surprised`, `sleepy`. Optional extras are `wave`, `point`, `carry` and `oops`.
- **Lip‑sync:** the same 10 Hebrew visemes (§10.4) on a nested `Mouth` artboard, plus a `jawOpen` fallback.
- **Inputs/view‑model properties:** `mood`, `viseme`, `jawOpen`, `voiceLevel`, `lookX/lookY`, triggers `poke`, `correct`, `tryAgain`, `celebrateS/M/L`; and events `celebrateDone`, `pokeDone`.
- **Bounding box:** the artboard is 512×512 with the character standing on a **baseline at y = 472**, centred on x = 256, and filling no more than 400 px tall. Each slot then scales uniformly, and nothing is ever stretched.
- **Anchor points** (named Rive nodes, tracked at runtime):

| Anchor | What attaches there |
|---|---|
| `bubble` | Speech‑bubble tail target, upper start side of the head |
| `hand` | Held objects (an answer card, a hint lamp) |
| `eyes` | Gaze target origin |
| `mic` | Where the listening glow and level ring attach, by the ear/head |
| `feet` | Ground contact for shadows and landing dust |
| `burst` | Celebration particle origin |
| `point` | Fingertip or tip, for pointing at targets |

- **Facing:** characters face **left** (toward the task) by default. A `flip` property mirrors the art but not text or props.
- **Safe colour zone (so characters never clash with Colours lessons):**
  - A character's large fills (≥ 15% of its area) must stay **out of the ten teaching hues' "answer zones"**: within ΔE2000 < 12 of any teaching colour in §9.3.
  - Characters use softened or offset hues instead. Nitzi is apricot, not orange `#FF8A1F`; Tza'adon is a slate‑blue `#5B8DEF` panel plus white, not teaching blue.
  - **During Colours activities, the Guide slot switches to its `colorSafe` skin**: a desaturated variant at ≤ 35% chroma on the body, with the original face. Small accents are allowed.
  - A lint script checks every pack's palette against this rule.

#### 4.9.3 Requirements for a new character (full pack)
- **Art:**
  - **Silhouette test:** recognisable as a black fill at 48 px, and distinct from every existing pack silhouette in a side‑by‑side lineup.
  - **Style:** flat shapes with one shadow tone and the clay lip; 2.5–4 pt `ink` outline optional but consistent within the pack.
  - **Palette:** ≤ 6 fills plus `ink` and white, passing the safe colour zone; grey‑scale distinguishable from the other characters.
  - **Expressions:** all 8 states plus a sticker pose.
- **Voice:**
  - A voice‑direction sheet.
  - A **core VO set of about 120 lines**: greetings, the 30 Tier‑1 praise lines, 12 "not yet" lines, 10 hint openers, 8 "try another way" openers, 6 "I'm not sure" responses, 6 explain‑back prompts, wind‑down and goodnight. All are in neutral plural form.
  - 2–3 catchphrases.
  - If the character can fill the Guide slot, it also needs a TTS voice profile for AI lines in both address forms.
- **Personality card:** 3 adjectives, what the character loves, how it reacts to mistakes (always kind), and one comic flaw.
- **Originality check:** the character must be cleared for resemblance to existing IP before merge.

#### 4.9.4 Lite packs: owner‑supplied images, animated procedurally
A **lite pack** lets the owner add a character from a small set of still images, with no Rive work. The app animates the stills procedurally, so the character works in every role slot.

> **Rights note:** owner‑supplied art for personal/family use is the owner's responsibility. Built‑in, store‑distributed content contains only our original cast and the hero squad. If the app goes commercial, lite packs based on third‑party characters must be licensed or removed. The pack loader marks lite packs as "family" (not distributed) by default.

**Image checklist (7 images per character):**

| # | File | Pose | Notes |
|---|---|---|---|
| 1 | `idle.png` | Neutral, friendly, facing slightly left | Also used for the sticker and map companion |
| 2 | `talk_closed.png` | Same pose, mouth closed | Must align pixel‑for‑pixel with 3 |
| 3 | `talk_open.png` | Same pose, mouth open ("ah") | Only the mouth area may differ from 2 |
| 4 | `celebrate.png` | Arms up / jump pose | Used for Tier‑2/3 cameos |
| 5 | `think.png` | Hand on chin, eyes up | Used for the thinking state and "try another way" |
| 6 | `listen.png` | Hand to ear, leaning in | Used for the voice listening state |
| 7 | `encourage.png` | Thumbs up / warm smile | Used for not‑yet and hint moments |

`surprised` and `sleepy` are derived procedurally from `idle` (a scale pop, or eyes dimmed with a sway).

**Image requirements:**
- **Format:** **PNG or WebP with a transparent background**, sRGB, **1024×1024 px** square canvas.
- **Framing:** full body, standing on a **baseline at y = 944 px**, horizontally centred, and **max 800 px tall**. Keep a 64 px **safe margin** on all sides (no art outside it, so bounces never clip).
- **Head box:** the head sits within the top 45% of the figure. The mouth centre is marked in the pack manifest (`mouth: [x, y]`).
- **Consistency:** the same scale and position across all 7 images, so swaps don't jump. The pack tool validates this by comparing alpha bounding boxes (tolerance ±16 px).
- **Size:** each file ≤ 400 KB. The app generates 3 downscaled sizes on import.
- **Manifest:** `pack.json` holds the name in Hebrew with nikud, the grammatical gender of the character's own speech, the mouth point, a dominant colour (checked against the safe colour zone; the app auto‑tints the slot background if needed) and an optional TTS voice choice.

**Procedural motion recipe:**

| Motion | Recipe |
|---|---|
| Idle breathing | scaleY 1.00↔1.02, scaleX 1.00↔0.99, 2.4 s sine, pivot at the feet. Plus a ±1.5° sway at 3.1 s, so it never looks mechanical |
| Blink substitute | None (stills); instead a tiny 4 px "head bob" every 3–6 s |
| Talking | Swap `talk_closed`/`talk_open` driven by the **voice amplitude envelope**: open when RMS > threshold (−32 dBFS), with a 60 ms minimum hold to avoid flicker. Add a 1–2 px vertical bob on syllable peaks |
| Listening | `listen` image + lean 4° toward the stage + the standard listening glow ring at the `mic` anchor (an auto‑placed head‑box corner) pulsing with the child's voice level |
| Thinking | `think` image + a slow 2° tilt + the standard three thought dots |
| Encourage | `encourage` image + a quick squash (0.94/1.06, 120 ms) and settle |
| Celebrate | Anticipation squash (0.9/1.1, 100 ms) → `celebrate` image jumps 40 px on an arc with stretch (0.95/1.08) → landing squash (1.08/0.92, 90 ms) → settle with overshoot. The standard spark burst comes from the top‑centre |
| Surprised | `idle` scale pop 1.0→1.12→1.0 (200 ms) + 6 px hop |
| Sleepy | `idle` with 25% darkening, a 4° slow sway (4 s) and the standard "z" particles |
| Entrance | Hop in from the end side: 3 hops on an arc with squash on each landing, 600 ms |
| Exit | Hop out toward the end side, 450 ms. Alternative: a "pop" scale‑to‑0 with a spark puff |
| Shadow | A procedural ellipse under the feet, which scales inversely with jump height |

The same recipe is used for Reduce Motion: no jumps, only cross‑fades between stills.

#### 4.9.5 Choosing a favourite: the companion
- **When.** After the first adventure (not at first launch, so the child first meets Nitzi), the child is invited to the **"Friends' Beach"** (חוֹף הַחֲבֵרִים).
- **What the child sees.** All available characters stand in a row, built‑in and hero squad first. Tapping one makes it do its `celebrate` and say its catchphrase. Tapping the **heart pedestal** chooses it.
- **What the companion does.** It becomes the child's **companion**:
  - it fills the **Map companion** and **Celebration cameo** slots;
  - it appears as a "helper" in "show me" demos;
  - **optionally (parent setting, default on)** it fills the **Guide** slot for pre‑recorded lines.

  Nitzi remains the AI tutor voice unless the companion's pack provides an approved TTS voice profile.
- **Changing it.** The child can change their companion any time on Friends' Beach, with no cost and no locks. New packs added by the parent appear there with a gentle "new friend!" bubble.
- **Parent control.** Parents can hide packs per child and set which packs may fill the Guide slot.

### 4.10 The Hero Squad (חוּלְיַת הַגִּבּוֹרִים): original starter pack
**Brief.** Four kid superheroes whose *superpowers are learning powers*. They are an alternative companion set for children who love heroes. They are fully original:
- no spiders or webs, no armoured suits, no green giants, no ice or snow‑queen sisters, no blue alien pets;
- capes are optional and soft;
- the palettes avoid the red/gold, red/blue and green/purple combinations associated with famous heroes.

Each hero wears a **sky‑pocket cape** (a short rounded cape with a pocket for collected sparks) and a squad badge: a 4‑point spark inside a hexagon. Their poses are energetic and full‑body, and each has a unique headgear silhouette.

| Hero | Who | Look | Learning power (domain) | Personality | Role in learning |
|---|---|---|---|---|---|
| **מוֹרִי־מַפְצִיל** "Mori the Splitter" (*Mori HaMafzil*) | Boy, about 7, curly dark hair, goggles on forehead | Deep‑navy suit, peach belt with a "+/−" buckle, short mint cape, teal goggles | **Split & Join** (Math/Numbers): claps once and a group splits into parts; claps twice and parts join. Shows 5 = 2 + 3, and makes and breaks tens | Bouncy, loud‑laugh, a bit impatient, learning to slow down | Number bonds, addition and subtraction, place value; error‑spotting "who split it wrong?" |
| **נוֹגָה רוֹאַת־הַדְּפוּסִים** "Noga Pattern‑Seer" (*Noga Ro'at HaDfusim*) | Girl, about 6, two puffy buns, brown skin | Lilac suit with coral trim, a *kaleidoscope visor* that shows repeating shapes, peach cape | **Pattern Sight** (Logic): her visor makes the repeating unit glow, and she can "see what comes next" | Calm, observant, giggles when she spots a secret | Patterns, sequences, odd‑one‑out, sorting; models explain‑back ("I saw the part that repeats") |
| **אֵיתָן מְשַׁנֶּה־גֹּדֶל** "Eitan Size‑Shifter" (*Eitan Meshaneh‑Godel*) | Boy, about 5, straight black hair, uses a sporty wheelchair with star‑spoke wheels | Soft salmon suit with a cream ruler stripe, navy round helmet with a tiny star antenna, star‑spoke wheels | **Shrink & Grow** (Shapes/Measurement): makes shapes bigger or smaller while keeping their shape; shows symmetry by "folding" the air | Brave, gentle, loves building, a careful measurer | Shape attributes, scaling, measuring and comparing, symmetry, spatial words |
| **שִׁירָה מְצַיֶּרֶת־דְּרָכִים** "Shira Path‑Painter" (*Shira Metzayeret Drachim*) | Girl, about 8, straight hair in a long braid, glasses | Sea‑green and cream suit, coral paint‑roller wand with a navy handle, cream cape | **Path Painting** (Computer Science + Colours): paints arrow paths on the ground that friends must follow exactly; mixes paint colours for each loop | Organised, inventive, likes "instructions that work"; laughs at her own bugs | Sequences, loops, debugging (fixing her painted path); colour mixing in creative CS tasks |

**Learning‑power rule:** each power is a **visible representation** that the "try another way" ladder can call on. Mori's split/join *is* the part‑whole model, and Noga's visor *is* the highlighted repeating unit. A child whose companion is a hero gets that hero as the *animator* of the alternative representation, which makes "another way" feel like a superpower moment.

**Voice:** child or teen voice actors (under supervision and with permissions), or young adults who can play kid voices naturally. They use energetic but clear diction, with catchphrases:
- Mori: "מְפַצְּלִים וּמְחַבְּרִים!"
- Noga: "רָאִיתִי אֶת הַסּוֹד!"
- Eitan: "גָּדוֹל, קָטָן — אוֹתָהּ צוּרָה!"
- Shira: "צַעַד אַחַר צַעַד, וְהַדֶּרֶךְ מוּכָנָה!"

Art is in `assets/hero-*.svg`, and the board is **07‑hero‑squad**.

### 4.11 Family characters (חֲבֵרֵי הַמִּשְׁפָּחָה): personal lite packs
**Brief.** Two original characters made for the owner's own children, so the app feels like *theirs*. Both are **lite packs** (§4.9.4) marked `availability.distribution: "personal"` and `personalUseOnly: true`. They are never store‑distributed. Both are fully original and avoid every §4.10 exclusion: no spiders/webs, armour, giant strongmen, red+gold / red+blue / green+purple schemes, blue or purple big‑eared aliens, ice/snow royalty, snowflake capes or braided princess looks. The board is **30‑family‑characters**, and the packs are in `design/family-pack/<id>/` (7 SVG + 7 PNG at 1024², plus `pack.json`).

**Personalisation.** Names use the placeholder **[שם]**, which the parent fills in. The hero's skin, skin shade and hair are separate named fills (`class="skin"`, `"skin-shade"`, `"hair"`; values in `pack.json → palette.personalise`), so they can be recoloured to match the child before the PNGs are re‑exported.

| | **[שם] הַמְּזַנֵּק** "[Name] the Leaper" (`hero-son`, he/him) | **[שם] (default זוֹהֲרִית), שׁוּעָלוֹן־כּוֹכָב** "starlight fox‑dragon" (`friend-daughter`, she/her) |
|---|---|---|
| **Who** | A kid superhero, about 6, who *is* the child | A small magical creature the child adopts and names |
| **Look** | Lagoon‑blue suit (`#3A7FA0`) with a cream belt and a number‑line hop emblem. A **star‑visor** (a headband with a big spark‑star crest and two lime speed fins) and a lime **scarf‑cape** (`#B6E36A`) whose two long tails fly behind him. **Lime jet sneakers** with sky‑blue jet puffs. Silhouette: a star on top, scarf tails behind, chunky shoes | Round peach body (`#FFC9A8`), a cream fox muzzle and belly with a coral heart, pointed fox ears, two tiny lilac horn nubs, a spark star on her forehead, small lilac wings, and a big swirling **rainbow‑ribbon tail** in pastel bands with a fluffy cream tip. One cheeky fang. Silhouette: fox ears over a round body with a big tail curl |
| **Learning power** | **קְפִיצַת מִסְפָּרִים "Number Leap"** (Numbers): his jet sneakers leap along the number line, counting on from any number and skip‑counting by 2s, 5s and 10s. Each landing lights its number. "Try another way" can call him to *show* a sum as hops | **מִכְחוֹל־זָנָב "Tail‑Brush"** (Colours, Logic): her tail paints sparkles in the air. Sparkles repeat to show a pattern (the repeating unit glows), and two touching sparkles **mix** into a new colour, shown with its name |
| **Personality** | Brave, bouncy and proud of every landing. Comic flaw: sometimes over‑leaps and has to count back, laughing | Mischievous, cuddly and sparkly. Giggles, whispers "secrets", and loves surprises. Comic flaw: paints sparkles on everything, including Nitzi |
| **Catchphrases** | "קְפִיצָה, וְעוֹד קְפִיצָה — הִגַּעְנוּ!"<br>"קוֹפְצִים בִּשְׁתַּיִם: שְׁתַּיִם, אַרְבַּע, שֵׁשׁ!" | "נִצְנוּץ, נִצְנוּץ — מָה בָּא עַכְשָׁו?"<br>"שְׁנֵי צְבָעִים, הוֹפּ — צֶבַע חָדָשׁ!" |
| **Voice (ElevenLabs, designed)** | An Israeli boy of about 7: bright, sporty and confident, never shouting, with a springy counting rhythm | A young girl's voice for a magical creature: soft, warm and giggly, with a whisper for pattern "secrets"; never shrill |
| **Motion** | `bounciness 0.85`, `idleSway 1.5°`; entrance = one long **leap** with jet puffs | `bounciness 0.7`, `idleSway 2°`; entrance = **flutter‑hop** with a sparkle trail |
| **Safe colour** (§4.9.2) | Large fills min ΔE2000 = 13.8 (suit vs blue) | Large fills min ΔE2000 = 13.9 (cream vs white). Ribbon bands are each < 15% |

**Pack QA** (from `pack.json → qa`): all 7 stills share one alpha bounding box within ±14 px. `talk_open` differs from `talk_closed` only in the mouth box. Every PNG is ≤ 400 KB. The mouth points are hero `[0.445, 0.5]` and friend `[0.391, 0.551]`.

### 4.12 Family friends (עוֹד חֲבֵרִים לַמִּשְׁפָּחָה): six more personal lite packs
**Brief.** The owner asked for look‑alikes of famous franchise characters, and we declined. Instead there are six **original** personal lite packs in the §4.11 pipeline:
- three kid heroes for the son;
- two adventurous sisters and a cheeky creature friend for the daughter.

All six follow every §4.10/§4.11 exclusion: no masks covering the face, no spiders, webs or web patterns, no red+blue / red+gold / green+purple schemes, no armour or metal suits, no muscle giants, no ice or snow powers, no crowns, gowns or braids, and no blue or purple big‑eared aliens or koala‑like creatures.

Each pack has the **resemblance check** recorded in this section. Two details were changed during design because they drifted toward known characters:
- **Tzuri:** spiky hair + orange top + forehead band became a rounded crop with one curl.
- **Romi:** pink top + shorts on an explorer became a poncho with a bucket hat.

Each pack is in `design/family-pack/<id>/` (7 SVG + 7 PNG at 1024², baseline 944, pose bboxes within ±16 px, `talk_open` differs only in the mouth) with a `pack.json` (`character-lite/v1`, `distribution: "personal"`, `personalUseOnly: true`). Kids' skin, skin shade and hair are named fills (`class="skin" / "skin-shade" / "hair"`). The board is **36‑family‑friends**.

| id | Name (gender) | For | Look | Learning power | Catchphrases |
|---|---|---|---|---|---|
| `climber-tzuri` | **צוּרִי הַמְּטַפֵּס** (he) | son | Sunset‑orange tee (`#F49A7A`), teal climbing trousers, striped side‑knotted headband, a coiled climbing rope, a number‑wall badge, chalk‑dust hands, face fully visible | **קִיר הַמִּסְפָּרִים** Number Wall (Numbers): climbs a hundreds wall, where one hold across is +1 and one row up is +10; skip‑counts by 2, 5 and 10 | "עוֹד שׁוּרָה לְמַעְלָה — עוֹד עֶשֶׂר!" · "יָד, רֶגֶל, מִסְפָּר — מְטַפְּסִים!" |
| `tower-tamir` | **תָּמִיר הַמִּגְדָּל** (he) | son | Round, gentle kid in a mustard block‑pattern tunic (`#D9A441`), navy trousers, a soft navy beanie with a pom‑pom, and a pastel unit‑block tower beside him that grows when he celebrates | **מִגְדַּל קֻבִּיּוֹת** Block Tower (Shapes/measurement): measures and compares with stacked unit blocks ("how many blocks tall?") | "קֻבִּיָּה עַל קֻבִּיָּה — כַּמָּה גָּבוֹהַּ?" · "מִי יוֹתֵר גָּבוֹהַּ? בּוֹאוּ נִבְנֶה וְנִרְאֶה!" |
| `inventor-gali` | **גַּלִּי הַמַּמְצִיאָה** (she) | son | Coral fabric overalls (`#FF9F8A`) over a mint shirt, a tool belt, a backwards coral cap, a pencil behind her ear, and a tan gadget backpack with fanned triangle wings and a circle wheel. Fabric, not armour | **תִּיק הַצּוּרוֹת** Shape Pack (CS + Shapes): unfolds shapes and builds machines in numbered steps; she debugs her own build orders | "קְלִיק, קְלָאק — צוּרָה!" · "יֵשׁ לִי רַעְיוֹן! צַעַד רִאשׁוֹן…" |
| `weaver-keshet` | **קֶשֶׁת אוֹרֶגֶת הַצְּבָעִים** (she), older sister | daughter | Short curly honey‑brown bob with a star clip, sea‑green tunic (`#45B3A0`), a peach travel cloak (`#FFB89A`) with a cream lining, pockets and a resting hood, and pastel ribbons | **סִרְטֵי צֶבַע** Colour Ribbons (Colours): twists ribbons together to weave mixes, and weaves in white or dark thread for lighter and darker shades | "בּוֹאִי, אֲחוֹתִי — נֶאֱרֹג קֶשֶׁת!" · "קְצָת לָבָן — וְהַצֶּבַע מִתְבַּהֵר!" |
| `compass-romi` | **רוֹמִי וְהַמַּצְפֵּן** (she), younger sister | daughter | Drawn 10% smaller. Pigtail puffs under a sunflower bucket hat, a rose poncho (`#F0B2B8`) with a sunflower zig‑zag hem, a striped shirt, sunflower leggings, chunky explorer boots, freckles, and a big compass | **מַצְפֵּן הַצַּעַד הַבָּא** Next‑Step Compass (Logic): the needle wobbles, then points to what comes next or which step goes first | "הַמַּצְפֵּן אוֹמֵר: לְכָאן!" · "קֹדֶם זֶה, אַחַר כָּךְ זֶה — וְהִגַּעְנוּ!" |
| `alien-jili` | **גִּ'ילִי** (he), a "jelly‑alien" | daughter | A small apricot jelly dome (`#FFBE8C`) with a scalloped cream rim, a shine and bubbles, two springy antennae with glowing star tips, tiny mint wings, nub arms, and three‑toed feet. No ears | **בּוּעוֹת שִׁתּוּף** Sharing Bubbles (Math): blows bubbles that each hold the same amount, for fair sharing, equal groups and halves | "בְּלוּבּ־בְּלוּבּ! לְכָל אֶחָד אוֹתוֹ דָּבָר!" · "אֲנִי מִתְפַּצֵּל לִשְׁנַיִם — וְחוֹזֵר!" |

- **Safe colour:** large fills are min ΔE2000 ≥ 12.4 from every teaching colour.
- **Voice:** each `pack.json → tts.style` gives ElevenLabs pitch, rate and a voice note for a designed (not cloned) voice.
- **Motion:** each pack has its own `motion` profile, from Tamir's soft `bounciness 0.55` to Jili's `jelly-bounce` at `1.0`.

---

## 5. Information architecture and flows

```
Launch ─┬─ First launch → Parent Setup (adult UI) ─→ Voice permission (parent) ─→ Profile created
        └─ Returning   → Profile Picker (kids) ─→ Home / World Map
Home / World Map ─┬─ Today's Adventure (3 stops: revisit → new → apply) ─→ Activity × n ─→ Celebration ─→ back to Map
                  ├─ Call for help (revisit flag on a past land) ─→ 3–5 item mission ─→ golden star / back to practice
                  ├─ Land (one domain) ─→ Lesson path ─→ Activity loop (+ try another way, explain‑back, error‑spotting)
                  ├─ Friends' Beach (choose companion from character packs)
                  ├─ Sticker Island ("הָאִי שֶׁלִּי") and Sky Journal
                  └─ [Parent Gate] ─→ Parent Area (dashboard · settings · profiles · subscription)
Any child screen ─→ Wind‑down (time limit / end of adventure) ─→ Rest screen
```

### 5.1 First launch: parent setup (adult UI, Hebrew without nikud)
1. **Welcome:** one adult screen ("This setup is for grown‑ups") with the parent‑style visual language (§13).
2. **Child's name** (text field) and **age** (3–8 as big chips). Age sets the starting band per domain, and the content agent's placement can adjust it later.
3. **How should Nitzi speak to the child?** ("איך ניצי תפנה אל הילד/ה?") with three radio cards, each showing a sample sentence:
   - masculine: "כל הכבוד, אתה אלוף!"
   - feminine: "כל הכבוד, את אלופה!"
   - plural/neutral: "כל הכבוד, אתם אלופים!"

   This setting drives AI‑generated lines only. Pre‑recorded lines are always neutral.
4. **Avatar:** the parent can pick an avatar, or tap "let the child choose" to hand the device over.
5. **Voice answers** (optional, §5.9).
6. **Session limit** (default 20 minutes with a soft wind‑down) and a **parent PIN** (optional, in addition to the gate).
7. **Done:** "Hand the device to [name]". Nitzi greets the child by name.

**Assumption:** the child's name is spoken by TTS in Nitzi's voice. See §16 for the voice cloning and consent decision.

### 5.2 Profile picker (siblings)
- Large avatar cards (Band A size) with the name in nikud underneath. Nitzi asks: "עִם מִי נְשַׂחֵק הַיּוֹם?" ("Who shall we play with today?").
- Tapping a card makes it hop and Nitzi says the name. The app then goes straight to that child's islands, with no confirmation step.
- "Add child" is a small "+" card that leads to the parent gate. Kids cannot create or delete profiles.
- With one child, the picker is skipped. The avatar in the Home top corner returns to the picker.

### 5.3 Home / world map
- **Layout:** the map pans horizontally on phones (one finger, with inertia) and shows nearly the whole archipelago on tablets. The home island starts in view.
- **Elements:**
  - the floating **Today's Adventure bottle**, the primary call to action, which bobs and has a 3‑stop preview;
  - land islands, each a large tap target with a wooden sign, glyph and host;
  - the **Sticker Island** button (a book icon) at the end side;
  - the child's avatar at the start corner;
  - a small grey **Parents** button at the far end corner, styled like adult UI.
- **Land tap:** the camera glides to the land, the host waves, and the **lesson path** opens: a winding path of 5–8 stepping stones. The current stone glows. Completed stones show the growth object they built, and future stones are sketches.

### 5.4 The activity loop
**instruction → attempt → feedback → hint → success**

1. **Instruction (audio first).**
   - Nitzi gives a one‑sentence goal ("כַּמָּה פְּרָחִים יֵשׁ?") while the scene is still. A pointing gesture or highlight shows *where*.
   - The caption appears with nikud. Band A captions are short; Band C may get two lines.
   - Replay is always available: tap Nitzi or the speaker bubble.
2. **Attempt.** Input is tap, drag, trace or voice. Objects respond to touch‑down within one frame: they lift, squash slightly and make a soft "tok".
3. **Feedback.**
   - **Correct:** a Tier‑1 micro‑celebration (≤ 0.8 s), and the correct answer stays visible.
   - **Not yet:** the object wobbles (±6°, 3 cycles, 360 ms) and floats back. Nitzi says a neutral, specific line ("כִּמְעַט! בּוֹאוּ נִסְפֹּר שׁוּב"). Nothing is lost.
4. **Hint ladder.** The ladder is offered, never forced. It starts after two "not yet"s, or when the child taps "I'm not sure":
   - (a) re‑voice the instruction with emphasis;
   - (b) a scaffolding hint, such as the counted items getting number badges or the target outline glowing;
   - (c) **"let's try another way"**: a change of representation (§5.4.1), not more of the same.

   The "I'm not sure" button *is* the hint lamp. When a hint is available it glows `sky`, so there is a single help entry point.

   The child always finishes the item themselves, so there is no "skip to answer". Hinted items are logged as "supported" for mastery tracking.
5. **Success and transition.** A spark flies from the answer to the progress trail at the top of the screen. After 5–8 items, the activity ends with a Tier‑2 celebration and a sticker.

**Always‑available self‑pacing controls** (present on every activity screen, sized as child controls; see board **19**):
- **Replay** (speaker bubble): hear the question again, unlimited.
- **"Show me" (תַּרְאוּ לִי, an eye icon):** Nitzi demonstrates a *similar* item (not the current one) step by step. The child then tries the real item.
- **"I'm not sure" (לֹא בָּטוּחַ/ה, a question‑mark cloud with a little hand):**
  - Tapping it is celebrated, not penalised. It gives a soft chime, a Tier‑1 sparkle on the cloud, and Nitzi saying "שְׁאֵלָה מְצֻיֶּנֶת! בּוֹאוּ נִסְתַּכֵּל יַחַד" ("Great question! Let's look together").
  - The app then opens the next rung of the hint ladder, or "try another way" if the ladder is used up.
  - Using it never lowers stars, never interrupts the trail and is never shown to the child as a count. Parents see it as a positive signal ("asks for help when unsure").
- **No time pressure, ever.** There are no countdowns and no "faster!" lines. The idle ladder (§6.3) only offers help and never hurries. A child who sits and thinks for 40 s is thinking, not failing.

#### 5.4.1 "Let's try another way" (בּוֹאוּ נְנַסֶּה דֶּרֶךְ אַחֶרֶת)
When a child struggles (two not‑yets, or "I'm not sure" after hints, or a gap found in a revisit), Nitzi **changes the representation** instead of repeating louder. This follows the concrete → pictorial → abstract progression [[CPA]](#17-sources) and, importantly, can step *back* down it.

**Representation ladder** (per skill; the content agent defines the sequence, and design gives every rung a consistent look):

| Rung | Look | Example: "3 + 2" | Example: "which is longer?" |
|---|---|---|---|
| 1 · Symbols | Numerals in an LTR isolate on a paper card | `3 + 2 = ?` | Two strips with measurements |
| 2 · Real objects | Draggable 3D‑ish objects with soft shadows that the child moves | 3 oranges + 2 oranges in Grandma Pnina's basket | Two snakes the child can lay side by side |
| 3 · Picture / model | A ten‑frame, dot cards, a bar model | Dots filling a ten‑frame | Snakes become strips on a grid |
| 4 · Number line / path | Nekudi hops along the line (0 at left) | Hop to 3, then 2 hops more | Count grid squares |
| 5 · Mini‑story | A 3‑panel story with a friend | "Kubi had 3 shells, found 2 more…" | Which friend's scarf reaches the ground? |

**Transition: a "magic flip", designed to feel like a fun new angle, not a failure:**
1. **Nitzi's cue.** Nitzi's ears do a playful "aha" twitch, and she says "רֶגַע! יֵשׁ לִי רַעְיוֹן — בּוֹאוּ נְנַסֶּה דֶּרֶךְ אַחֶרֶת!" ("Wait! I have an idea, let's try another way!"), with a 300 ms tail‑spark burst.
2. **The flip (≈ 700 ms).** The current card **flips like a paper card**. On the flip side is the same question in the new representation, while the numbers literally "pour" into objects (each digit dissolves into that many items that hop into place).
3. **The badge.** A small **"דֶּרֶךְ חֲדָשָׁה" (new way) badge**, a lens glyph with the representation's icon, sits on the card. Tapping it flips back, so children can compare both views (bridging representation).
4. **No "wrong" residue.** The previous not‑yet state is cleared, the progress trail is untouched and no failure SFX plays. The flip uses the *discovery* sound (a glissando up), the same one used when a new land opens. The moment is framed as an unlock.
5. **The bridge back.** After success in the new representation, the card flips back to the original form for one *bridging* item, so the child connects the two ("the 3 oranges and 2 oranges, here they are as 3 + 2!").
6. **Tracking.** The engine records which representation unlocked the skill. The parent area shows it as "what helped" (§13).

#### 5.4.2 Explain‑back: "אֵיךְ יְדַעְתֶּם?" ("How did you know?"), Bands B–C
- **When.** After a correct answer on roughly 1 in 4 items of a *new* skill (never on every item), Nitzi leans in curiously: "וָאוּ! אֵיךְ יְדַעְתֶּם?" She is genuinely curious, not testing.
- **Show it (tap/drag):** the child re‑enacts the reasoning on a small "explain tray", for example dragging the 3 and 2 oranges together, hopping along the number line, or pointing at the pattern's repeating unit. Nitzi narrates what she sees back ("אָה, חִבַּרְתֶּם 3 וְעוֹד 2!").
- **Tell it (voice, if enabled):** the AI tutor listens for the key idea (e.g., "counted on", "it repeats"). It reflects it back in simple words, and is always positive even if the explanation is partial.
- **Skip.** A friendly skip ("אוֹמַר לָךְ אַחַר כָּךְ" / a play arrow) is always available. Explain‑back never blocks progress or costs anything.
- **Why.** Explaining one's reasoning is a well‑studied learning booster, especially when paired with conceptual instruction [[Self‑explanation]](#17-sources). It also gives the tutor evidence of *understanding*, not just correct answers.

#### 5.4.3 Error‑spotting play: "!אוּפְּס, מִי יְתַקֵּן"
- **Who makes the mistake.** A friend character (most often Tza'adon the robot, sometimes Grandma Pnina "forgetting" a coin) makes a visible, silly mistake on purpose.
  - The robot's program walks him into a puddle.
  - Pnina counts 4 oranges as 5.
  - A pattern has one bead out of place.
- **What the child does.** Find it (tap the wrong step or bead), then fix it (drag the right piece in).
- **Tone.** Comic, never mocking. The friend laughs at himself ("בִּיפּ־בּוּפּ… טָעִיתִי!") and thanks the child warmly, which shows that mistakes are normal and fixable.
- **Placement.** Used in every domain from Band B. For CS it is the core of debugging.

### 5.5 Lesson and activity structure
A lesson is 1–3 activities (3–6 minutes). Each activity has 5–8 items, and difficulty adapts within the activity (content agent). The progress trail shows sparks filling **right→left**.

### 5.6 Pause and exit
- **Home** (an island icon, start corner) is available on every activity screen. Tapping it once shows a tiny "go home?" bubble with two big buttons: island = go, play arrow = stay. This prevents accidental exits without needing a dialog.
- **Partial progress is kept.** Returning resumes on the same item.

### 5.7 Session end: the wind‑down
1. **Heads‑up.** When a limit is set, about 2 minutes before it a **sun icon** on the top bar starts sinking toward a horizon line. The cue is non‑numeric, and pre‑readers understand it.
2. **Finish the activity.** The current activity is never cut off mid‑item.
3. **Dusk ritual (≈ 30 s, skippable by parent only).**
   - The sky turns violet, lanterns light, and the sparks of today rise into the Sky Journal constellation.
   - Nitzi says a neutral goodnight ("אֵיזֶה יוֹם! הַנִּיצוֹצוֹת שֶׁלָּנוּ עָלוּ לַשָּׁמַיִם. לַיְלָה טוֹב!"), yawns and curls up.
   - Music changes to the lullaby variant.
4. **Rest screen.** Nitzi sleeps. The map is dimmed but visible. Continuing past the limit requires the parent gate.
5. **No lures.** There is no "come back tomorrow for a prize", no notifications to the child, and nothing is lost by not returning.

### 5.8 Parent area (behind the gate)
- **Gate:** the instruction is shown as Hebrew text *without* nikud, plus an arithmetic answer above Band C level (e.g., "כמה זה 14 × 6?") on a shuffled number pad, *or* the parent PIN if one was set. This arithmetic gate supersedes the "2‑second hold" idea in tech.md, because children can do holds.
  - After 3 failures there is a 30 s cool‑down with a calm illustration.
  - Hold‑to‑open gestures are not used, since children can do them.
  - The gate is a speed bump, not security. Purchases also use the platform's own authentication.
- **Inside:** the dashboard, profiles, settings, co‑play tips, subscription and support (§13).

### 5.9 Voice permission flow (asked of the parent, never the child)
1. **Pre‑permission screen (in setup).**
   - It explains in plain Hebrew: "Children can answer Nitzi by speaking. Audio is used only to understand the answer and is not stored."
   - The exact data policy comes from the tech/privacy agent. Under COPPA‑style guidance, audio used only to replace typed input and deleted immediately is the low‑risk pattern [[Fenwick/FTC]](#17-sources).
   - Two equal buttons: "Allow voice answers" / "Not now".
2. **OS prompt.** The OS microphone prompt appears only after "Allow".
3. **If denied or skipped:**
   - The mic button is **absent** from the child's space, not greyed out, so a child never meets a dead button.
   - A settings toggle can re‑enable it later, with a deep link to OS settings if needed.
4. **Changing it later.** Parents can switch **Voice answers** and the **AI tutor** off independently at any time. If the AI tutor is off, Nitzi uses only pre‑recorded and templated lines (the rule‑based tutor). Voice answers still work, because recognition is on‑device. If voice answers are off, the mic is hidden.

### 5.10 Offline state
- **Downloaded content keeps working.** Lands are downloaded as packs (installed with the app on first run where possible). Downloaded lands are fully playable offline, including tap answers and pre‑recorded VO.
- **Voice offline.** Hebrew speech recognition runs **on‑device by default** (an ivrit.ai model via sherpa‑onnx, per tech.md), so **the mic keeps working offline**. Only the AI tutor's dynamic lines need the network. Offline, the rule‑based tutor (pre‑recorded and templated lines) covers feedback, hints and "try another way", and the child sees no difference in controls.
- **Not‑yet‑downloaded lands** rest under a soft sea‑fog. Tapping one gets Nitzi's line "הַגֶּשֶׁר נָח עַכְשָׁו, בּוֹאוּ נְשַׂחֵק כָּאן!" ("The bridge is resting now, let's play here!") and a glow toward a playable land.
- **Messaging.** No error dialogs appear in the child space. The parent area shows a small "offline" chip and a download manager.

---

## 6. Interaction design rules for ages 3–8

### 6.1 Touch targets per band
Sizes are set **physically (mm)** and converted per device. 1 pt is about 0.156 mm on iPhone/iPad mini (163 pt/in) and about 0.192 mm on full‑size iPad (132 pt/in). Android dp is about 0.159 mm.

NN/g's adult minimum is 1 × 1 cm [[NN/g]](#17-sources). Research with children shows miss rates rise sharply below about 6 mm and that "the younger the child, the larger the targets" must be [[Anthony 2013]](#17-sources). The band sizes therefore sit well above the adult minimum.

| | **Band A (3–4)** | **Band B (5–6)** | **Band C (7–8)** |
|---|---|---|---|
| Primary answer target (phone / tablet) | **96 / 112 pt** (≈ 15 / 21 mm) | **80 / 96 pt** (≈ 12.5 / 18 mm) | **64 / 80 pt** (≈ 10 / 15 mm) |
| Any child control (minimum, engineering floor) | **64 pt** | **56 pt** | **56 pt** |
| Gap between targets (phone / tablet) | 24 / 32 pt | 16 / 24 pt | 12 / 16 pt (never < 12) |
| Hit area beyond visual edge (`hitSlop`) | +12 pt each side | +10 pt | +8 pt |
| Drag snap radius | 1.5 × target | 1.25 × target | 1 × target |
| Max simultaneous choices | 3 (more objects allowed for counting) | 4 | 5 (keypad allowed) |
| Edge rules | No drag targets within 24 pt of any edge; no hotspots in the bottom 24 pt band | same | same |

**Edge targets:** misses on targets near the screen edge mostly land in the gutter, so edge‑adjacent targets extend their hit area *to* the edge [[Anthony 2013]](#17-sources).

### 6.2 Gestures per band

| Gesture | A | B | C |
|---|---|---|---|
| Tap | ✓ primary | ✓ | ✓ |
| One‑finger drag (with tap‑then‑tap alternative) | ✓ big objects, magnetic snap | ✓ | ✓ incl. reordering |
| Trace (numerals, shapes, paths) | ✓ wide tolerance, guide rails | ✓ medium tolerance | ✓ |
| Ordered tap sequences (CS programs) | ✓ up to 3 steps | ✓ up to 8 | ✓ with loops |
| Keypad number entry | — | — | ✓ |
| Swipe / flick | ✗ (map pans only) | map only | map + carousels |
| Long‑press | **✗** | ✗ | optional "peek" only, never required |
| Double‑tap | ✗ (treated as one tap) | ✗ | ✗ |
| Pinch / multi‑finger | **✗** | ✗ | ✗ |
| Tilt / shake | ✗ | ✗ | ✗ |

Pinching and flicking are hard for preschoolers, while tapping is the most intuitive gesture [[Sesame/JGCC]](#17-sources). No content gesture is ever required beyond tap and one‑finger drag. Every drag has a **tap‑then‑tap** alternative (tap the object, then tap the destination), which also supports motor and switch access.

### 6.3 Feedback latency, replay and idle prompts
- **Feedback timing:**
  - Touch‑down feedback (lift, squash, "tok") within **≤ 50 ms** (target: next frame).
  - Answer feedback starts **≤ 250 ms** after release.
  - The AI tutor shows *thinking* within **≤ 100 ms**. At **1.5 s** a pre‑recorded filler ("הממ… רֶגַע…") plays. At the **3.0 s** hard timeout, the rule‑based tutor answers instead (aligned with tech.md).
- **Replay:** a speaker bubble sits beside Nitzi's head on every screen, and tapping Nitzi also replays. Replays are unlimited and never penalised.
- **Idle ladder (offers, never hurries).** These timings are for Band A. Bands B–C use longer timings, because silence there usually means thinking:
  - 8 s: the target gently pulses.
  - 15 s: the instruction is re‑voiced with a pointing gesture.
  - 30 s: "רוֹצִים רֶמֶז, אוֹ לַחְשֹׁב עוֹד קְצָת?" ("Want a hint, or think a little more?"), offered with the glowing "I'm not sure" button and a "thinking" cloud. The child can pick "think more", and Nitzi sits down beside them and hums.
  - 120 s: soft pause.

  The app never nags, scolds or uses urgency language.

### 6.4 Error tolerance
- **Holdover filter.** Ignore a second touch within 300 ms and 24 pt of an accepted touch. Repeated taps on the just‑accepted target are common among young children [[Anthony 2013]](#17-sources), and the threshold is tunable.
- **Resting hands and palms.**
  - Ignore touches with a major radius above about 30 pt.
  - Ignore touches that stay stationary for more than 1 s within 40 pt of the bottom edge.
  - For drags, track only the first finger, and ignore extra touches rather than cancelling the drag.
- **No navigation or destructive targets in the bottom corners.** Children rest wrists along the bottom edge [[Sesame/JGCC]](#17-sources). Navigation lives in the top corners, and large intentional targets such as the mic keep at least 24 pt above the bottom safe area.
- **Background taps are free.** Taps on scenery trigger playful reactions (a fish jumps), never "wrong" feedback. Only answer objects evaluate.
- **Drops outside zones.** Dropping outside a valid zone floats the object home with no sound of failure.
- **No time pressure, in any band.** There are no timers, countdowns or speed scores. Fluency is measured silently by the engine and is never shown to the child as a clock.

### 6.5 No text dependency for pre‑readers
- Every instruction, label, button and feedback line is voiced. Every icon is concrete (an island for home, a speaker for replay, a book for stickers).
- Text is never the only cue. It appears as captions with full nikud in Bands A–B, and with full nikud by default in Band C (the parent can switch to partial nikud).
- Every button that a child can see speaks its name on first touch‑down in Band A ("hover‑speak"). The action fires on release.

### 6.6 Voice answers (optional)
**Model: tap‑to‑talk with automatic end‑pointing.**
- **Why not open mic:** an open mic causes false triggers from siblings and TV, is a privacy concern, and gives no clear turn‑taking cue.
- **Why not hold‑to‑talk:** holding is a long‑press, which is banned for Band A.

**How it works:**
1. **Idle.** The mic button (with two little jerboa ears) sits under Nitzi. It appears only when the parent enabled voice, the item accepts a spoken answer, and the on‑device Hebrew ASR model is installed (it works offline).
2. **Tap → Listening.** An earcon plays ("bloop‑up"). Nitzi's ears shoot up and turn toward the child, and Nitzi says "אֲנִי מַקְשִׁיבָה…" the first few times (then only the earcon). The button grows into a ring with **live level bars**, and Nitzi's inner ears and tail‑spark glow with the voice amplitude.
3. **End‑pointing.**
   - Listening stops automatically after 1.5 s of silence (Band A: 2.0 s, because young children pause mid‑answer).
   - A tap on the button also stops it.
   - The maximum window is 8 s.
4. **Thinking.** Nitzi's thinking pose and pulsing dots appear while the app checks the answer.
5. **Understood.** If the answer is recognised (correct or not), it is echoed visibly. The heard word appears in a bubble ("שֶׁבַע?") and the matching answer card lights up, then normal feedback follows.
6. **Didn't understand (never "wrong"):**
   - **Attempt 1:** Nitzi tilts her head. "אוּפְּס, הָאָזְנַיִם שֶׁלִּי הִתְבַּלְבְּלוּ! אֶפְשָׁר לְהַגִּיד שׁוּב?" ("Oops, my ears got mixed up! Can you say it again?")
   - **Attempt 2:** Nitzi shows *partial understanding*, either "שָׁמַעְתִּי ׳שֶׁבַע׳, נָכוֹן?" with yes/no thumbs, or "אֶפְשָׁר גַּם לִלְחֹץ עַל הַתְּשׁוּבָה" with the answer cards glowing. Revealing partial understanding mirrors how parents repair children's speech [[Quack]](#17-sources).
   - **Then:** the item switches to tap quietly. The child is never asked more than twice.
7. **Recognition policy.**
   - Accept number words in both genders (שָׁלוֹשׁ/שְׁלוֹשָׁה), digits, approximate pronunciations and child phonology (e.g., /r/ variations).
   - Never correct the child's pronunciation in Bands A–B.

---

## 7. Orientation and responsive layout

### 7.1 Decision: **phones locked to landscape; tablets support both orientations**
- **Phones: landscape only (locked).**
  - Preschoolers naturally hold devices in landscape [[Sesame/JGCC]](#17-sources).
  - Landscape gives width for the RTL "guide → task" flow (guide on the right, the task flowing left) and for drag‑and‑drop between a tray and a target.
  - It matches children's mental model of games and video.
  - Both landscape rotations are supported.
- **Tablets: landscape *and* portrait (required).** Android 16 ignores orientation locks on displays ≥ 600 dp, and iPadOS 27 drops `UIRequiresFullScreen`, so every tablet screen has a **wide** and a **tall** layout variant (§7.3). Landscape is the primary design, and portrait is fully supported.
- **Foldables and split‑screen:** the window size class decides the variant (the device type does not). Compact height uses the phone layout, and widths ≥ 600 dp use the tablet layout.

### 7.2 Device classes and safe areas (logical pt/dp, from `tokens.json → layout.devices`)

| Class | Reference size | Safe areas | Notes |
|---|---|---|---|
| **Phone** (reference) | **iPhone 16: 852×393** landscape | **59 pt start + 59 pt end** (camera cut‑out; symmetric so rotation doesn't shift the layout), **21 pt bottom** (home indicator), 0 top | Background bleeds to all edges; every interactive element sits inside the safe rect (734×372) |
| **Phone SE** (smallest supported) | **iPhone SE 3: 667×375** landscape | None from the OS; we apply a **16 pt** margin | Uses the `phoneSE` layout tokens (narrower rail, 80 pt top bar). Proven on board **12** |
| **Tablet landscape** | **iPad 10th gen: 1180×820** | 24 pt top (status), 20 pt bottom (home indicator) | Wide variant |
| **Tablet portrait** | **iPad 10th gen: 820×1180** | 24 pt top, 20 pt bottom | Tall variant |

Phones in landscape have a *compact height*, so two‑pane layouts that stack vertically are avoided [[Android size classes]](#17-sources).

**Hard rules from engineering (enforced in code review against the boards):**
- **Tap targets:** ≥ 64 dp in Band A and ≥ 56 dp in Bands B–C, with ≥ 12 dp gaps (`tokens.touch`).
- **Drag targets:** none within **24 dp of any screen edge**, and no hotspots in the bottom 24 dp band.
- **Stage aspect:** the activity stage supports **4:3 to 19.5:9**.

### 7.3 Layout grid and variants
**Phone, wide (852×393 reference; safe rect x 59–793, y 0–372):**
- **Top bar** (height 88; controls at y 12): **Home** sits at the start corner (right, inside the safe area). The **progress trail** is centred over the stage. The end corner holds the self‑pacing cluster in activities, or the Parents button on Home.
- **Guide rail** (start side, 176 pt wide): the guide character, the speaker/replay bubble and the mic button.
- **Stage** (the rest, about 534 pt): a 6‑column grid with 12 pt gutters.
- **Compact‑guide mode** (rail 120 pt, guide "peek") is used on dense screens such as robot coding and Band C maths.

**Phone SE (667×375):** 16 pt margins, a 152 pt rail (compact 112 pt) and an 80 pt top bar. The answer size stays at the band token; only the gaps and the scene shrink.

**Tablet, wide (1180×820):** a 112 pt top bar, a 260 pt guide rail and a stage on a 12‑column grid with 20 pt gutters. A **toolbox** column (240 pt, end side) holds manipulatives (ten‑frame, number line, colour wheel) and a co‑play prompt card. The extra space becomes a *think space*, not just bigger buttons.

**Tablet, tall (820×1180):**
- The guide moves to a **guide strip** across the top: 220 pt high, with the guide at the start side, the caption beside it and the mic at the end side.
- The stage sits below it, square‑ish at about 772×560.
- The toolbox becomes a horizontal **tray** at the bottom (above the 24 pt no‑hotspot band).
- The world map scrolls vertically in portrait, with the archipelago re‑composed as a winding chain from the top‑right to the bottom‑left.

**Illustrated scenes** are authored at 2388×1668 with a centred 16:9 "safe action area". Phones crop the top and bottom of a 19.5:9 extension, tablets show the full 4:3, and portrait uses a separately composed crop. Interactive objects always live inside the safe action area.

### 7.4 How key screens adapt

| Screen | Phone (wide) | Tablet landscape (wide) | Tablet portrait (tall) |
|---|---|---|---|
| World map | Pans horizontally, about 2.5 lands visible, edge peeks hint at more | Nearly the whole archipelago, light pan | Vertical scroll; lands chained top→bottom |
| Activity | Rail + stage; 3 answers in one row | Rail + stage + toolbox | Guide strip + stage + bottom tray |
| Robot coding | Compact guide; 5×3 grid; **vertical program strip** (top → bottom, start marker 1) on the end side of the grid; 2×2 arrow palette + run button beside it | 6×5 grid; vertical strip + palette beside it | Grid on top; vertical strip and palette below, side by side |
| Celebration | Full‑bleed overlay, sticker card centred | Plus a world‑growth vignette | Vignette above the card |
| Sticker Island | Diorama plus a drawer from the end side | Diorama plus a persistent drawer | Drawer at the bottom |
| Parent dashboard | Single column | Two columns (board **24**) | Single column, wider cards |

---

## 8. Right‑to‑left rules

Principle (Apple): *flip what follows reading order; keep what refers to absolute direction or to time on a clock* [[WWDC22]](#17-sources), [[Material bidi]](#17-sources).

| Element | Rule |
|---|---|
| Navigation, back | **Mirrors.** Back/home sits at the top‑right and points →. "Next/continue" points ← and sits at the end side. |
| Progress trail | **Mirrors.** It fills right → left. |
| Lesson path, world progression | **Mirrors.** The start is at the right and new lands unfold leftwards. |
| Story sequences, timelines, "first/then/last" cards | **Do not mirror** (owner and curriculum-expert, 2026-10-30, B-40 §12): the first card is at the left, like every other row in the stage, so no row ever runs the other way. |
| Pattern rows ("what's next?") | **Do not mirror** (2026-10-30, B-40 §12): the row reads left → right and the empty slot is at the right end, the same way as the number path and number sequences; a repeating pattern gives the same answer from either end. |
| Carousels and pagination | **Mirror.** Swipe left‑to‑right to go forward (platform RTL default). |
| **Number line** | **Does not mirror.** 0 is at the left and values increase to the right, as in Israeli maths textbooks. |
| **Equations and expressions** | **Do not mirror.** They are rendered as an LTR isolate: `3 + 4 = 7`. **Division is written `12 : 3`** (the Israeli school convention), never ÷. **`<` and `>` appear only inside LTR maths isolates** (`3 < 5`), so bidi mirroring can never flip them. |
| Column arithmetic, place‑value charts | **Do not mirror.** Ones are at the right, as in school. |
| **Clocks** (analogue and digital) | **Never mirror.** Hands move clockwise, and digital time is an LTR isolate `7:30`. |
| **Robot‑coding arrows** | **Absolute, do not mirror.** ← means "move left on screen". Turn blocks use clockwise ↻ / anticlockwise ↺ glyphs with a robot silhouette. |
| Robot **program strip** | **Vertical, read top → bottom** (a stack of command cards) with a numbered start marker (1) at the top. This avoids the RTL‑vs‑LTR ambiguity behind misconception M‑DIR‑RTL (curriculum lead's decision). The run playhead moves downward. On phone it sits on the stage's end side (left), next to the grid, with the arrow palette beside it. |
| Charts, graphs | Numeric axes keep standard maths orientation (y‑axis at left, values up). Category order in picture graphs follows the textbook convention **[to validate with content team]**. |
| Media controls (lullaby/video, if any) | **Do not mirror** [[Material bidi]](#17-sources). |
| Characters | They face **left** (toward the task) by default. |
| Icons | Directional icons (arrows, a speaker's waves, a book's opening side) mirror. Physical objects, the search/magnifier and checkmarks do not. |

**Mixed Hebrew/number text:**
- Wrap every number, equation, time and price in a bidi isolate (`<bdi>`, `dir="ltr"`, or Unicode FSI/PDI).
- Format money and numbers with the **he‑IL locale formatter**, never by string concatenation. Minus, percent and ₪ placement differ in RTL [[WWDC22]](#17-sources).
- Never apply letter‑spacing to pointed (nikud) text.
- Spoken maths follows Hebrew number grammar (gendered numerals), which the content/VO team owns.

---

## 9. Visual design system

**Style:** "sunlit paper cut‑outs". Shapes are flat with rounded geometry, there is one shadow tone per colour, and there is a soft "clay lip" (a darker 4–6 pt bottom edge) on everything pressable. The palette is warm and saturated but not neon, on cream paper.

### 9.1 Palette
All values live in **`design/tokens.json`** (the single source of truth, which the Flutter theme imports). The table below is a summary.

**Core neutrals:**

| Token | Hex | Use |
|---|---|---|
| `cream` | `#FFF6E8` | App background, paper |
| `paper` | `#FFFFFF` | Cards |
| `ink` | `#2B2350` | All primary text and outlines (13.4:1 on cream) |
| `inkSoft` | `#5A5378` | Secondary text (6.7:1 on cream) |
| `mist` | `#EDE6F7` | Wells, empty sockets |
| `parentBg` | `#F6F1FA` | Parent‑area background |

**Brand:**

| Token | Hex | Use |
|---|---|---|
| `spark` | `#FFC83D` | The spark, success glow (never text) |
| `sunset` | `#FF8A3D` | Primary kid CTA fill (ink label, 6.1:1); not used in Colours activities |
| `sea` / `seaDeep` | `#1A9E9A` / `#0F6E6A` | Mic and listening; teal surfaces with white text (6.1:1) |
| `sky` | `#8FD3F4` | Hint glow |
| `night` | `#3B2C85` | Dusk, parent headers (white text 11.1:1) |
| `lilac` | `#B9A2F7` | "Not yet" ring |
| `gold` | `#F5B700` | Golden star (always star‑shaped) |

**Domain colours** (always paired with a glyph; `deep` carries white text at ≥ 5:1):

| Domain | Fill | Deep | Tint | Glyph |
|---|---|---|---|---|
| Numbers | `#F46A5E` | `#B4233A` | `#FFE3DF` | Dot trio |
| Colours | `#E04F9E` | `#B4337C` | `#FCE1F0` | Drop |
| Shapes | `#34A86A` | `#1E7F4C` | `#DDF3E6` | Triangle |
| Logic | `#8A5CF0` | `#6B3FD1` | `#ECE3FE` | Puzzle piece |
| CS | `#2F7FE0` | `#1F63C7` | `#DEEBFC` | Chevrons |
| Math | `#F59E1B` | `#A35A00` | `#FEEFD6` | Plus |

**Feedback semantics avoid red/green:**
- *correct* = `spark` glow + check badge + rising chime;
- *not yet* = wobble + `lilac` ring + soft "boing";
- *hint* = `sky` halo.

Apple's guidance is that status must never be red‑vs‑green alone; shape and icon must carry it [[Apple DWCA]](#17-sources).

**Character palettes** are in `tokens.color.character`. Every large character fill was checked against the teaching colours with ΔE2000 (§4.9.2): all pass at ≥ 12.

### 9.2 Colour‑blind‑safe strategy
About **1 in 12 boys** has a colour‑vision deficiency, and most are undiagnosed in early childhood [[Apple Education]](#17-sources). Expect one in nearly every gan class.

1. **UI never relies on colour alone.** Domains, feedback, states and characters all carry a shape, glyph or position as well. Every screen is tested in greyscale (Apple's recommended check) and with deuteranopia/protanopia/tritanopia simulation.
2. **Functional colours come from an Okabe‑Ito‑informed set** with large luminance gaps between neighbours [[Okabe‑Ito]](#17-sources).

### 9.3 Keeping the Colours lessons accessible (colour *is* the content)
- **Tap‑to‑hear.** Every colour swatch, paint pot and object speaks its colour name on tap, as a learning aid *and* an accessible channel.
- **Teaching palette chosen for luminance spread.** Every confusable pair also differs in lightness:
  - אָדֹם `#D62F2F`, כָּתֹם `#FF8A1F`, צָהֹב `#FFD43B`, יָרֹק `#3CB55A`, כָּחֹל `#2563D9`, סָגֹל `#7B3FC4`, וָרֹד `#FF8EC0`, חוּם `#8A5A33`, שָׁחֹר `#1F1F24`, לָבָן `#FFFFFF`.
  - Early sorting tasks pair colours with large lightness differences first, and red/green discrimination is never a gate to progression.
- **"Colour helper" symbols.** An optional parent setting, and auto‑suggested, adds a small consistent symbol to each teaching colour:
  - red = heart, orange = sun, yellow = star, green = leaf, blue = drop, purple = grapes, pink = flower, brown = nut, black = moon, white = cloud.
  - They are shown inside swatches and on paint pots (see board **16**).
  - The symbols are **[Assumption]** original. ColorADD is an established alternative that could be licensed (§16).
- **Gentle detection.** If a child's errors consistently match a CVD confusion axis (e.g., red↔green, blue↔purple) across sessions, the app takes three steps:
  - it auto‑enables colour helpers;
  - it adapts item selection;
  - it shows the parent a careful, non‑diagnostic note: "ייתכן שכדאי לבדוק ראיית צבעים אצל רופא/ת עיניים".
- **Mixing lessons** use real paint behaviour (subtractive) and show the result *and* its name. Each mix also shows the lightness change.

### 9.4 Typography
**Hebrew support and niqqud quality.**
- **Subset and glyph check:** the Hebrew subset and the niqqud glyphs were confirmed in the font files of Rubik, Varela Round, Fredoka, Heebo, Assistant, Alef, Secular One, Suez One and Playpen Sans Hebrew [[Fontsource]](#17-sources).
- **But glyphs are not enough. Mark *positioning* matters:**
  - The Open Siddur font survey puts **Rubik** and **Fredoka** in its "severely broken niqqud" tier, with general diacritic positioning errors [[Open Siddur]](#17-sources).
  - It lists Heebo, Assistant, Alef, Varela Round, Secular One and Suez One in the "niqqud only" tier, with no positioning errors noted.
  - Noto Sans Hebrew has full support but **no Latin digits**.
- **Our own test:** we rendered the engineering stress string **כׇּל הַכָּבוֹד · שֻׁלְחָן · בְּקֻבּוּץ · אֳנִיָּה** in Chromium at 52 and 110 px.
  - Rubik shows kubutz and hataf marks crowding and misaligned under narrow letters.
  - Heebo (500/700), Assistant, Alef and Secular One place all marks cleanly.

**Decision: Rubik and Fredoka are not used anywhere** (not even for unvocalised labels, so one family pair serves every string).

| Role | Font | Why |
|---|---|---|
| Display (wordmark, titles, celebration words) | **Secular One** (400, single weight) | Bold, friendly, slightly rounded Hebrew forms with clean niqqud. It has personality without the broken marks of Fredoka |
| Text (captions with niqqud, numerals, buttons, all parent UI) | **Heebo** 400/500/700/800 | Clear print letterforms that match what children learn to read, clean niqqud, many weights, and Latin digits that match the Hebrew |

Fallback chain: `'Heebo', 'Assistant', sans-serif` and `'Secular One', 'Heebo', sans-serif`. Playpen Sans Hebrew was rejected because its handwritten forms (e.g., ם, ב) differ from print.

**Sizes (phone pt / tablet pt; full set in `tokens.type`):**

| Style | Band A | Band B | Band C | Parent |
|---|---|---|---|---|
| Caption with niqqud (Heebo 500, lh 1.7) | 26 / 32 | 22 / 28 | 20 / 24 | — |
| Activity numerals (Heebo 800) | 56 / 72 | 48 / 64 | 40 / 56 | — |
| Titles (Secular One) | 32 / 44 | 30 / 40 | 28 / 36 | Heebo 800, 28 |
| Body (Heebo 400) | — | — | — | 16 (min 13) |

**Niqqud rendering rules:**
- **Spacing and clipping:** line‑height ≥ 1.7 for pointed text (marks above and below must not collide or clip), and no `overflow:hidden` on pointed text boxes.
- **Encoding and spelling:** store text as NFC, and never use Unicode presentation forms (U+FB1D–FB4F). Use standard modern niqqud spelling, reviewed by a Hebrew language editor.
- **Weights:** use real font weights, never synthetic bold, since synthetic bold smears dagesh. Pointed text below 24 pt uses Heebo 500 at most.
- **QA:** every caption string is rendered in CI with the stress‑string check (kamatz katan, hataf kamatz, kubutz, shin/sin dots, and dagesh in ו/ה/ש).

### 9.5 Components (board **05**; sizes from `tokens.component`)
Every screen is built only from these components.
- **Pebble button** (`pebbleButton`).
  - A circle of 64 pt (A) or 56 pt (B/C) with a fill plus a 6 pt darker lip (`elevation.lip.rest`).
  - Pressed: moves down 4 pt, the lip shrinks to 2 pt, and it springs back with the band overshoot.
  - Icon‑only for kids, with a voiced label and an `aria-label`.
  - Variants: Home (island), Replay (speaker), Not‑sure / hint (question cloud that glows `sky` when a hint is ready), Show‑me (eye), Parents (grey, adult style).
- **Answer card** (`answerCard`).
  - White, radius 28, 4 pt border, 6 pt lip and e2 shadow. Size is the band's `touch.answer` (A 96, B 80, C 64 on phone).
  - States: idle; pressed (scale 0.94); selected (ink ring + 6 pt lift); correct (gold rim + check badge + sparkle); not‑yet (lilac ring + wobble, then back to idle).
  - There is no disabled state in the child space; unavailable choices are removed.
- **Mic button** (`voice.micButton`).
  - A `sea` circle with a mic glyph and two small rounded ears. Size: A 88, B 80, C 72 on phone; 104/96/88 on tablet.
  - States: idle, listening (level ring + 5 bars), thinking, understood (check pulse), didn't‑understand (ears tilt). See board **28**.
- **Speaker / replay bubble:** a pebble button that sits at the guide's `bubble` anchor.
- **Caption pill:** paper, radius 24, padding 16/8, with Heebo 500 at the band size and line‑height 1.7.
- **Progress trail:** 5–8 sockets of 20 pt with 8 pt gaps, in a pill of 36 pt height. It fills right→left. A filled socket shows a gold 4‑point spark, so progress reads by shape.
- **Land sign:** a wooden board with radius 12, a 3 pt ink outline, a domain glyph and a name with niqqud.
- **Help flag** (revisit): a small post with a bell and a `sky` pennant.
- **Golden star:** a 5‑point `gold` star with an ink outline, on a pennant.
- **Sticker:** a 6 pt white die‑cut border with radius 24 and e2 shadow, plus a peel corner when new.
- **"New way" badge:** a `sky` pill with a lens glyph and the representation icon.
- **Parent controls:** height 44, radius 12, Heebo 700 16, grey and night palette. They are visibly "adult" [[Register/Sesame]](#17-sources).

### 9.6 Iconography and illustration
- **Icons:** 2.5–3 pt rounded strokes plus a solid fill, built on a 24/32/48 grid. They are concrete objects, never abstract UI metaphors (an island for home, not a house; a speaker for replay).
- **Illustration:** layered paper‑cut planes.
  - The sea uses wave‑line patterns rather than gradients.
  - Light comes from the top‑right (the start side), and shadows fall to the bottom‑left.
  - Islands have a sand rim, grass top and one landmark each.
  - Unbuilt items are dashed pencil outlines in `ink` at 35%.
- **Diversity:** child avatars and background townsfolk reflect Israeli diversity: skin tones, hair and head coverings, glasses, wheelchairs on the market street.

---

## 10. Motion design

### 10.1 Principles
- **Squash and stretch on everything alive:** characters, pebble buttons and answer cards. Volume is conserved (scaleX × scaleY ≈ 1).
- **Anticipation before every big move.** Nitzi crouches 80–120 ms before a hop, and a card dips before flying to the trail.
- **Follow‑through and overlap.** Ears, scarf, tail‑spark and antennae lag 2–4 frames behind the body.
- **Arcs, not straight lines,** for anything thrown or flying (sparks, stickers).
- **One focal motion at a time** (principle 3). During voice‑over, ambient motion drops to under 20% amplitude.

**Timing per band:**

| | Band A | Band B | Band C |
|---|---|---|---|
| Base transition | 450 ms | 350 ms | 280 ms |
| Overshoot | Larger (1.12) | 1.08 | Subtle (1.04) |

- **Easing:** entrances use `cubic-bezier(.2,.9,.25,1.15)` (spring‑out), exits use `cubic-bezier(.5,0,.75,0)`, and loops use sine.
- **Safety:** nothing flashes faster than 3 Hz. The app respects OS **Reduce Motion**, which replaces flights with fades and celebrations with a single glow.

### 10.2 Micro‑interactions and transitions
- **Touch‑down:** lift + 0.94 squash + "tok" (≤ 50 ms).
- **Drag:** the object scales to 1.08, tilts toward the movement direction (±8°) and casts a larger shadow. Valid drop zones breathe (scale 1.0↔1.04, 900 ms loop).
- **Snap:** a magnet pull over the last 120 ms, a 1.1 squash, a "click‑pop" and a light haptic.
- **Correct:** a 120 ms squash, a ✓ badge pop (scale 0→1.2→1, 220 ms) and a sparkle ring. A spark arcs to the trail (500 ms) and the socket "drinks" it.
- **Not yet:** a wobble (±6°, 3 cycles, 360 ms total, decaying) and a lilac ring fade. The object floats home on an arc (400 ms).
- **Screen transitions:**
  - Map → land is a camera glide with depth parallax (600 ms).
  - Activity → activity is a "page turn" of paper planes moving right→left (450 ms), so the RTL direction is felt.
- **Idle life:** blinking, breathing and occasional ear twitches. Background life (waves, birds) runs at under 15% of the screen and pauses during instructions.

### 10.3 Celebration tiers
Celebrations never cover the learning. In Bands B–C, the solved item stays visible during celebrations.

| Tier | When | Duration | What happens |
|---|---|---|---|
| **1 · small** | Each correct item | ≤ 0.8 s | ✓ badge, sparkle ring, spark → trail, Nitzi nod + one of ~30 short lines ("יֵשׁ!", "בְּדִיּוּק!") |
| **2 · medium** | End of activity/lesson | 2–3 s | Nitzi hops, the host friend joins, domain‑glyph confetti, sticker reveal card (see board **20**) |
| **3 · big** | Skill mastered / new growth object / band‑up | 5–7 s, tap to skip after 1.5 s | The camera flies to the land, the growth object draws itself in, then fills with colour with squash and stretch, the friends dance, and a spark fountain plays. About once every 3–5 sessions, so it stays special |

### 10.4 Rive character spec (Nitzi; the same pattern applies to the cast)

**Files and artboards:**
- **File:** `nitzi.riv`. Artboard `Nitzi` (512×512), plus a nested artboard `NitziMouth` for visemes and `NitziPeek` (head‑only crop for compact mode).
- **Control:** use **Data Binding view‑model properties**. Rive has deprecated raw state‑machine inputs in favour of Data Binding [[Rive]](#17-sources). The names below work as either.

**State machine `Main`, layers:**
1. **Body:** Idle ↔ Talking ↔ Listening ↔ Thinking ↔ Encouraging ↔ Celebrating ↔ Sleepy ↔ Surprised, selected by `mood` (number enum 0–7), with 150–250 ms blends.
2. **Mouth:** selected by `viseme` (0–9). Mouth switches cross‑fade in 40 ms. `jawOpen` (0–100) is an amplitude fallback when phoneme timing is unavailable.
3. **Eyes:** a blink loop (random 2–6 s via an engine timer → `blink` trigger), `lookX`/`lookY` (−100…100) blend, and `eyeShape` (open / happy‑closed / sleepy / wide).
4. **Ears:** additive. `earPerk` (0–100) raises and turns the ears, and `voiceLevel` (0–100) drives the inner‑ear glow and tremble.
5. **Tail‑spark:** `sparkGlow` (0–100) and a `sparkBurst` trigger.

**Triggers and events:**
- Triggers: `poke` (tap reaction), `correct`, `tryAgain`, `celebrateS/M/L`, `yawn`, `surprise`.
- `band` (0/1/2) scales energy (amplitude × 1.25 / 1 / 0.85).
- Events emitted: `hopLanded`, `celebrateDone` and `pokeDone`, for syncing sound effects and haptics.

**Hebrew viseme set (10 mouths):**

| # | Viseme | Hebrew sounds |
|---|---|---|
| 0 | Rest | — |
| 1 | Closed (M/B/P) | מ, בּ, פּ |
| 2 | Lip‑teeth (F/V) | פ, ב, ו |
| 3 | Open A | קָמָץ/פַּתָּח "a" |
| 4 | Mid E | סֶגּוֹל/צֵירֵה "e" |
| 5 | Spread I | חִירִיק "i", also י |
| 6 | Round O | חוֹלָם "o" |
| 7 | Small round U | שׁוּרוּק/קֻבּוּץ "u" |
| 8 | Teeth (dental/sibilant) | ס, שׁ, צ, ז, ת, ד, ט, נ, ל |
| 9 | Back‑open (gutturals/R) | ח, כ, ר, ע, ג, ק, ה |

**Lip‑sync timing:**
- **Pre‑recorded VO:** phoneme timings come from forced alignment during production, with hand‑tweaked hero lines. This is the same approach Duolingo uses to drive Rive visemes from timing data rather than video [[Duolingo]](#17-sources).
- **AI lines:** use the TTS engine's phoneme/viseme timestamps where available, and otherwise `jawOpen` from the audio envelope with vowel‑shape cycling.

---

## 11. Sound design and voice‑over

**Music:**
- **Instrumentation:** warm acoustic: ukulele, marimba, glockenspiel, soft hand percussion, with a light Mediterranean colour (oud plucks and darbuka brushes in the market).
- **Main theme:** 4 bars, 100 bpm.
- **Land variants:**

| Land | Lead instruments |
|---|---|
| Counting Hills | Marimba |
| Colour Bay | Kalimba and strings |
| Shape Forest | Woodblocks and pizzicato |
| Riddle Grotto | Celesta and harp |
| Robot Harbour | Soft mallets and gentle synth blips |
| Market Village | Oud, accordion and claps |

- **Wind‑down:** a 70 bpm lullaby variant.
- **During activities:** music drops to a bed (or off, as a parent option).

**SFX palette (consistent earcons):**

| Event | Sound |
|---|---|
| Tap | Wooden "tok" |
| Pick‑up | Rising "bloop" |
| Snap | "Click‑pop" |
| Correct | 3‑note rising pentatonic chime (6 pitch variants to avoid fatigue) |
| Not‑yet | Soft low "boing" (never a buzzer) |
| Hint | Twinkle |
| Spark to trail | Glass bell |
| Mic open / close | "Bloop‑up" / "bloop‑down" |
| Scenery taps | Small character sounds (a fish splash, a bird chirp) |

**Voice casting:** see §4. Record all cast lines in neutral plural forms. Record each Nitzi line in Band A (slow) and Band B/C (natural) reads. Use a native Israeli casting director and a Hebrew language editor in the booth for nikud‑accurate pronunciation.

**Mixing rules:**
- **VO always ducks music** by 14 dB (attack 120 ms, release 600 ms) and ducks ambient sound fully.
- **No SFX starts within 150 ms of a VO onset.** SFX play under VO at −6 dB.
- **Loudness targets:** VO −16 LUFS integrated, music bed about −28 LUFS, true peak ≤ −1 dBTP.
- **Parent volume:** separate parent sliders for Music / Effects / Voice.
- **Ducking timing:** device media volume is respected, and the game ducks *itself* when the mic opens (music fully off while listening).

**Haptics:**
- Light impact on pick‑up and snap, and a "success" notification haptic on correct. *Not‑yet* has no haptic, so it never feels like a punishment.
- Never continuous. Parent toggle, and the system settings are respected.

---

## 12. Rewards and motivation

1. **World growth** (main reward, §3.3): tied to mastery, visible and permanent. **Golden stars** on buildings reward *lasting* understanding, through revisits passed weeks later. They are the most prestigious thing in the world, and they cannot be earned by speed or volume.
2. **Understanding moments are celebrated too.** Using "I'm not sure", solving after "try another way", explaining back and fixing a friend's mistake each earn their own Tier‑1 sparkle and a special spark colour in the Sky Journal. Asking for help is never a lesser path.
3. **Stickers:**
   - **Earning:** one sticker per completed lesson, themed to the land.
   - **Sticker Island ("הָאִי שֶׁלִּי"):** stickers go on a personal island diorama where the child can place, resize (tap‑cycle three sizes, no pinch) and arrange them freely. This is pure creative agency.
   - **Not yet earned:** stickers appear as soft silhouettes, never with prices.
4. **Sky Journal:** a constellation for each session, a calm record of "what I learned".
5. **Friend moments:** friends visit other lands after milestones, for small story beats that reward exploring.
6. **Gentle streaks, "the weekly garden" (גִּנַּת הַשָּׁבוּעַ):**
   - Each day the child plays, a flower blooms in a 7‑bed garden, and 3 days in a week brings a bonus song.
   - **Nothing wilts, resets with a penalty or counts down.** Missed days are simply empty soil.
   - No loss‑aversion and no notifications to the child [[Michigan]](#17-sources).
7. **Never in the child space:** prices, store, "buy more", ads, external links, social sharing, leaderboards, randomised loot, or timers that pressure. This matches the Kids Category rules on links and purchases [[Apple Kids]](#17-sources).
8. **Praise style:** specific and effort‑based ("סָפַרְתֶּם כָּל פֶּרַח בְּזֶהִירוּת!"), not "you're so smart". AI praise uses the chosen gender form.

### 12.1 Awards & Trophy Hall (הֵיכַל הַגְּבִיעִים)
Boards: **31** (phone hall), **32** (phone ceremony) and **33** (tablet hall). The hall is a sunlit room with bunting, arched windows and wooden shelves, one shelf per land. The child's companion (here the family hero, §4.11) stands on a pedestal and presents every new prize.

**Rules (non‑negotiable):**
- Every prize is **earned through learning**.
- Every prize is **shown in advance**: its silhouette and how to earn it are always visible, so there is no random loot and no surprise boxes.
- Prizes are **never bought** and **never lost**. Nothing decays, expires or is taken back, and a revisit gap never removes a trophy (§3.3).
- Speed, volume and streaks never earn a prize. Rapid guessing earns nothing (§13.1).

**Trophies per land** (bronze → silver → gold, placed right→left, the RTL "forward"):

| Trophy | Earned when | Ties to |
|---|---|---|
| **גְּבִיעַ אָרָד** Bronze | The land's first growth objects are built (its first skills reach "practising") | §3.3 world growth |
| **גְּבִיעַ כֶּסֶף** Silver | **Half** of the land's skills are durable (golden star) | §3.3 durable mastery |
| **גְּבִיעַ זָהָב** Gold | **Every** skill in the land is durable | §3.3 golden stars |

Each cup carries its land's glyph on a white plaque, so colour is never the only cue (§9.2). Gold adds a star finial.

**Special trophies and medals for good learning habits** (the medal shelf, "מֵדַלְיוֹת שֶׁל הֶרְגֵּלִים טוֹבִים"):
- **אֹמֶץ לִשְׁאֹל** "Brave to ask": the first "I'm not sure".
- **מְתַקְּנֵי בָּאגִים** "Bug fixers": fixed Tza'adon's program 5 times.
- **אֵיךְ יָדַעְתִּי** "How I knew": the first explain‑back (§5.4.2).
- **גִּנָּה פּוֹרַחַת** "Garden in bloom": a full 7‑flower weekly garden (§12.6). This is the only time‑based medal. It celebrates showing up, and a missed day never removes anything.

Further medals (for example "first golden star" or "10 calls for help answered") follow the same rule: one clear, visible learning behaviour.

**Prizes for the companion** (tab "לֶחָבֵר"):
- **Costumes and accessories:** new scarf‑cape colours for the hero, or new ribbon colours for the fox‑dragon's tail. All of them pass the safe‑colour rule (§4.9.2).
- **Island decorations** (flags or lanterns for Sticker Island).
- **A new dance** for the companion's `celebrate` moment.

Each prize is linked to a named trophy or medal ("רִקּוּד חָדָשׁ: גְּבִיעַ זָהָב רִאשׁוֹן").

**The ceremony** (board 32; a Tier‑3 moment, §10.3):
1. The hall dims to `night` at about 78%, and a warm spotlight cone falls on a pedestal.
2. The trophy **spins in** with a ¾ turn (ghost frames, spin arcs and a squash on landing, about 900 ms), while confetti falls in brand colours.
3. The companion plays `celebrate` and says a presenting line ("הִנֵּה הוּא — בִּשְׁבִילְכֶם!").
4. A one‑line memory of what was learned appears, with the land glyph. If the trophy unlocks a companion prize, a "וְגַם לֶחָבֵר" card shows it, worn by the companion.
5. Continue is always available. Reduce Motion swaps the spin for a cross‑fade, and parents can switch the ceremony off (§13.1).

**In the hall:**
- **Tapping a trophy replays its moment.** A popover shows the trophy, a tiny representation of the skill (for example a ten‑frame showing 7 + 3), a **one‑line memory** with an icon, and play/listen buttons. The line is spoken on tap, for pre‑readers.
- **Locked items** are soft `mist` silhouettes with a dashed `sketch` outline, never padlocks or prices. One progress chip per shelf shows the next trophy (golden star icon + "4/6"). The tablet also shows a one‑line "how to earn" ("הַבָּא: כָּל הָאִי עִם כּוֹכָב"). Medals show "3/5" and a how‑to line.
- **Real‑world rewards from parents.** In the parent area (§13.1), a parent can attach a real‑world reward to any trophy or medal, for example "כשתזכו בגביע הזהב, נלך לגלידה". In the hall it appears as a **pink rosette ribbon with an ice‑cream icon** pinned to that trophy, plus the full text on tablet ("כְּשֶׁתִּזְכּוּ בַּגָּבִיעַ הַזָּהָב — נֵלֵךְ לְגְלִידָה!"). The text is written by the parent, shown with nikud when auto‑vocalisation is available, and read aloud on tap. It is a promise between family members, so the app never fulfils, sells or tracks it.

---

## 13. Parent area UX (see board **24**)
**Visual language:** calm adult UI. It uses Heebo, no niqqud, a cream and white card layout, `night` headers, and full VoiceOver/TalkBack support with Dynamic Type.

**Dashboard:**
- **Per‑child tabs** with avatars.
- **"This week" summary:**
  - minutes played per day (a bar chart with exact values labelled);
  - adventures completed;
  - newest growth object.
- **Skill understanding in plain Hebrew,** grouped by domain with the domain glyph. Each skill is a "can‑do" statement ("סופרת עד 10 ומצביעה על כל פריט"). The verb form follows the child's chosen form.
  - **Four statuses,** each with an icon *and* a word, never colour alone:

    | Status (Hebrew) | Meaning | Icon |
    |---|---|---|
    | **הבינה** | Understood, and a revisit was passed weeks later | Tree with a gold star |
    | **מתרגלת** | Practising | Sapling |
    | **כדאי לחזור** | Due for a revisit | Circular arrow with a bell |
    | **מצאנו פער** | Gap found | Small magnifier with a sprout |

  - **"What the app is doing about it"** appears as one plain line under every skill that is not yet understood. For example:
    - "בפעם הבאה ננסה עם חפצים אמיתיים במקום מספרים"
    - "ניצי תחזור לזה בעוד 3 ימים, דרך 'קריאת עזרה' בגבעות הספירה"
  - **"What helped"** names the representation that unlocked the skill (e.g., "ציר המספרים עזר לה להבין חיבור").
  - **Signals of good learning habits:** "Asked for help when unsure (7 times this week)" and "Explained how she knew" are presented as strengths.
  - **Never shown:** speed, time per item or raw error counts, so parents don't pressure for speed.
  - **For each gap:** a co‑play idea to try at home.
- **"What's next"** shows the upcoming skills.
- **"Noticed"** shows gentle, actionable observations (e.g., "Often counts the same item twice: try counting objects together and moving each one aside").
- **Co‑play tip of the week:** a real‑world activity tied to what was learned ("בדרך לגן: חפשו יחד 3 דברים עגולים").

**Settings:**
- Voice answers on/off; AI tutor on/off (independently); address form per child (masculine/feminine/plural); session limit (10/15/20/30/none) and "rest hours"; music/effects/voice volumes; nikud level (Band C); colour helper; reduce motion; haptics.
- Band override per domain, with the recommendation shown.
- Content downloads.
- Privacy and data: what is stored, delete child data, export a report.
- Subscription and purchases, which exist only here.

**Notifications to parents:** off by default. If enabled, a single weekly summary is sent, never "your child misses Nitzi!"

### 13.1 Analytics & alerts (boards **34** and **35**)
**Analytics (board 34), per child tab** (`[ילד/ה]` in the boards):
- **Minutes per day this week:** a bar chart with every value labelled and a dashed daily‑limit line. Minutes past the limit are hatched, not coloured, so the chart works in greyscale. Weekly total and days played.
- **Skills by status per domain:** stacked bars in the four §13 statuses (הבינ/ה, מתרגל/ת, כדאי לחזור, מצאנו פער). Each segment has a count, and the legend pairs colour with the status icon.
- **Mastery growth over 8 weeks:** two lines, plotted right→left like every chart in the app. "Understood" uses `sea` with ring markers, and "remembered after a week" uses gold with star markers. End values are labelled.
- **What helped:** the representation → skill pairs that unlocked understanding ("מסגרת עשר ← חיבור עד 10 · עזר 4 מתוך 5").
- **Misconceptions found and resolved:** each one gets a plain‑language statement, a status chip (נפתר / בתהליך / חדש, each with an icon) and one line about what is being done.
- **Habits:** asked for help, explained "how I knew", tried another way, fixed the robot's bug. Each is a count with the change from last week, presented as strengths.
- **Still never shown:** speed, time per item or raw error counts.

**Alerts (board 35, feed).** Every alert has a **severity chip** with an icon *and* a word, a time, a factual line, and a **"מה לעשות"** line with one concrete suggestion.

| Alert | Severity | What the app already did |
|---|---|---|
| Played past the daily limit, or tried during rest hours | לתשומת לב | Let the started activity finish (or stopped at once, per setting). Bedtime lock: Nitzi says goodnight |
| Repeated failed parent‑gate attempts (5 in 2 min) | חשוב | Locked the gate for 10 min; play continues normally |
| Rapid random guessing to farm rewards | מידע | Gave no rewards (prizes come only from understanding); slowed down and offered "show me" |
| Frustration loop (repeated misses, then rapid taps) | לתשומת לב | Switched to "try another way" and offered a short break |
| Inappropriate words said to the tutor | לתשומת לב | Nitzi answered calmly and offered a break. The parent sees the exact line |
| A worrying disclosure to the tutor (sadness, exclusion, possible harm) | חשוב | Nitzi listened, validated the feeling and suggested telling a parent. She never probes or promises secrecy |

- **Disclosure alerts are written gently.** They suggest a calm, open conversation without interrogation, and name where to turn if there is concern for safety (the gan teacher, the counsellor or the paediatrician).
- **Privacy:** only the single flagged line is kept, for 30 days, then deleted. Full conversations are never stored for parents.
- **No alerts are ever shown to the child.**

**Controls (board 35):**
- **Time:** a daily limit for weekdays and weekends, allowed hours, and what happens at the limit ("finish the activity" or "stop now").
- **Bedtime lock:** start and end times. Nitzi says goodnight and the app locks.
- **Voice / AI:** voice answers, the AI tutor, free conversation (off by default: learning talk only), and alerts on inappropriate words.
- **Allowed characters per child:** Nitzi, the Hero Squad and family packs (§4.11).
- **Reward settings:** the trophy ceremony (it can always be skipped), prizes for the companion, and showing locked items.
- **Real‑world rewards:** a list of trophy or medal → promise pairs. These are added and edited here and shown to the child as a ribbon (§12.1).
- **Alert channels:** in app and/or **push to the parent's phone**, set per severity, plus the weekly summary. Push stays **off by default**. During setup the parent is offered push for "חשוב" alerts only.

---

## 14. Accessibility and inclusion
- **Vision:**
  - colour strategy (§9.2–9.3);
  - text contrast ≥ 4.5:1 everywhere (including large text);
  - a high‑contrast theme (ink outlines on all objects);
  - Dynamic Type and screen‑reader support in the parent area;
  - in the child space, VoiceOver users get object labels ("שלושה פרחים") and the activity's audio instructions.
- **Motor:**
  - mm‑based targets and tap‑then‑tap for every drag;
  - adjustable hold‑still tolerance;
  - Switch Control / Switch Access scanning order defined per screen (start side first);
  - an optional "bigger targets" setting that bumps the child one band larger.
- **Hearing:**
  - every VO line is captioned (with nikud);
  - visual equivalents for every earcon (✓ badge, wobble, glow);
  - haptics for success.
- **Speech:**
  - voice is optional;
  - the recogniser accepts approximations;
  - children with speech delays or stutters are never corrected or timed out harshly (end‑pointing is extended to 3 s in the "patient listening" option).
- **Cognitive and neurodiversity:**
  - predictable routines (same screen anatomy everywhere);
  - transition warnings (the sinking sun);
  - a calm mode with no background music, reduced SFX and no Tier‑3 celebrations;
  - no time limits in tasks;
  - one instruction at a time.
- **Seizure safety:** nothing flashes at more than 3 Hz, and there are no full‑screen white flashes.
- **Culture and family diversity:**
  - avatars and townsfolk reflect the range of Israeli families, including religious and secular, Ethiopian‑, Russian‑ and Arab‑Israeli families;
  - holiday content is opt‑in;
  - the gender choice includes a plural option;
  - stories avoid assuming a particular family structure.
- **Learning Hebrew:** the clear VO and nikud also serve children for whom Hebrew is a second language. Recognition should tolerate accents.

---

## 15. Usability testing with children

| | Band A (3–4) | Band B (5–6) | Band C (7–8) |
|---|---|---|---|
| **Method** | Observation of parent‑child dyads in natural settings (home, gan corner); Wizard‑of‑Oz voice (a researcher voices Nitzi live) | Observation + short structured play tasks + Hebrew smiley‑meter / "again‑again" table; peer tutoring (child teaches a friend) | Constructive interaction (pairs), light think‑aloud, short post‑task interview |
| **Session** | 15–20 min, with breaks; parent present | 20–25 min | 25–30 min |
| **Children per round** | 6–8 | 6–8 | 5–6 |

Simple observation is most reliable for preschoolers. Smileyometer‑style tools are reliable from about 5–6, and pairs and peer tutoring work well at 6–8 [[Usability methods review]](#17-sources). Dyads put young children at ease, and sessions should be short and framed as "ideas for a game", not a test [[UX Collective]](#17-sources).

**What to observe** (coded from video and the app's touch logs):
- **First‑attempt success, and hesitation** of more than 3 s before the first touch.
- **Behaviour cues:**
  - glances to the parent, meaning they don't know what to do;
  - accidental and holdover touches, from the logs;
  - wrist‑rest touches;
  - drag drops released early.
- **Understanding:**
  - replay‑button use (good if used, bad if needed every time);
  - whether children understood Nitzi without the caption.
- **Voice:** whether children speak after the mic opens, how they react to "didn't understand", and volume escalation [[Quack]](#17-sources).
- **Delight markers:**
  - smiles, laughs, talking to characters, "again!";
  - spontaneous return to a land;
  - tapping scenery to explore.
- **Drop‑off markers:**
  - turning away, sighs, covering ears, rapid random tapping (frustration);
  - asking to stop.

**Cadence:**

| Phase | Rounds | Focus |
|---|---|---|
| Discovery | 1 round (8 families, home visits) | Device habits, holding posture, how families share devices |
| Prototype | Every 2 weeks (paper → clickable → Rive builds) | Toca Boca's approach of testing on paper first applies: "if they laugh, it's probably good" [[Toca Boca/JGCC]](#17-sources) |
| Alpha | Monthly lab rounds + a **2‑week home diary study** (20 families) | Retention, delight decay and parent trust |
| Post‑launch | Quarterly rounds + analytics (first‑party, aggregate only, no third‑party SDKs in the child space [[Apple Kids]](#17-sources)) | — |

**Ethics:** parental consent and child assent ("you can stop any time"). A Hebrew‑speaking researcher trained with young children runs sessions. No video leaves the research team. Families receive a thank‑you gift, and the child gets a small physical toy.

**Sample:** recruit across the centre and periphery, religious and secular, Hebrew as a first and second language, and children with CVD (screened by the parent's report).

---

## 16. Open decisions (for the product owner)
1. **Final name** (Nitznutz recommended), with an Israeli trademark search (classes 9, 41) and App Store and Google Play name availability.
2. **Mascot species and gender.** Nitzi the star‑jerboa is she/her, so her first‑person speech is feminine. The alternative is a male Nitzi. This changes casting.
3. **Cast size.** Six land hosts are recommended. Fewer (e.g., 4, with Nitzi hosting Numbers and Math) would cut VO and animation cost by about 30% but weaken land identity.
4. **Child's name in VO:** TTS in a cloned Nitzi voice (needs the actor's written consent and the tech agent's sign‑off), or a generic greeting plus the name on screen only.
5. **Colour helper symbols:** our original set or a ColorADD licence.
6. **Chart conventions** in Math (category order in picture graphs) need confirmation against Israeli textbooks by the content team.
7. **Holiday and seasonal content scope** and how it is presented for all family backgrounds.
8. **Offline voice (resolved with tech):** Hebrew ASR is on‑device (ivrit.ai via sherpa‑onnx), so the mic stays available offline. Still open: the minimum device spec for on‑device ASR on older Android tablets, and what the UI does if the model is still downloading (the proposal is to hide the mic until it is ready).
9. **Parent gate type:** an arithmetic gate (default) vs PIN only vs OS authentication.
10. **Phone support for Band A:** phones are fully supported, but the app could *recommend* tablets for ages 3–4 at setup.
11. **Music licensing:** a commissioned score (recommended) vs library music.
12. **Companion as Guide:** may a child's chosen companion (including the hero squad) replace Nitzi as the voice of pre‑recorded instructions by default? The recommendation is yes, while Nitzi stays the AI voice.
13. **Lite packs from third‑party IP:** these are family use only. A commercial launch needs licences, or the packs must be removed, so a legal review is needed before any distribution.
14. **Hero squad voice casting:** child actors or adults playing kids. Child actors need Israeli child‑performer permits.
15. **Revisit timing (resolved with tech):** timing is adaptive, from the learning engine's FSRS‑style memory model. The golden star means durable mastery: a delayed check passed at least 7 days after mastery, on a different item. Still open: how many calls for help may queue per land (the proposal is at most 2 on the map at once).

---

## 17. Sources
Pages opened and relied on:

- [NN/g: Touch Targets on Touchscreens](https://www.nngroup.com/articles/touch-target-size/) **[NN/g]**
- [Anthony et al. 2013, Understanding the differences in how children and adults interact with touchscreens (JPUC)](https://lisa-anthony.com/wp-content/uploads/2013/04/anthony-et-al-jpuc2013.pdf) **[Anthony 2013]**
- [Anthony et al. 2019, Physical dimensions of children's touchscreen interactions: MTAGIC (preprint)](https://init.cise.ufl.edu/wp-content/uploads/sites/378/2019/03/anthony-et-al-IJHCS2019-MTAGIC-final-preprint.pdf)
- [MTAGIC project summary (UF INIT Lab)](https://init.cise.ufl.edu/?p=2686)
- [TIDRC: Touchscreen Interaction Design Recommendations for Children (UF INIT Lab)](https://init.cise.ufl.edu/?p=2368)
- [APS: Putting Education in "Educational" Apps (Hirsh‑Pasek et al.)](https://www.psychologicalscience.org/publications/educational-apps.html) **[APS]**
- [Joan Ganz Cooney Center: Best Practices: Designing Touch Tablet Experiences for Preschoolers (Sesame Workshop)](https://joanganzcooneycenter.org/?p=19607) **[Sesame/JGCC]**
- [Licensing International: Sesame Workshop shares tips for touch screen content](https://licensinginternational.org/news/sesame-workshop-shares-tips-for-creating-touch-screen-content-for-preschoolers)
- [The Register: Muppets launch App Store guide for little fingers](https://www.theregister.com/software/2012/12/20/muppets-launch-app-store-guide-for-little-fingers/1054821) **[Register/Sesame]**
- [Joan Ganz Cooney Center: The App Fairy talks to Toca Boca (transcript)](https://joanganzcooneycenter.org/?p=18640) **[Toca Boca/JGCC]**
- [The 74: Learning and growing with Khan Academy Kids](https://www.the74million.org/zero2eight/learning-and-growing-with-khan-academy-kids/)
- [Common Sense Media: Duolingo ABC review](https://www.commonsensemedia.org/app-reviews/duolingo-abc-learn-to-read)
- [Common Sense Media: Lingokids review](https://www.commonsensemedia.org/app-reviews/lingokids-play-and-learn)
- [The Horn Book: Endless Numbers app review](https://www.hbook.com/story/endless-numbers-app-review)
- [Wikipedia: DragonBox](https://en.wikipedia.org/wiki/DragonBox)
- [ScratchJr design in practice: low floor… (Int. J. Child‑Computer Interaction, 2023)](https://sites.bc.edu/devtech/wp-content/uploads/sites/181/2023/07/ScratchJr-design-in-practice-Low-fl_2023_International-Journal-of-Child-Com.pdf)
- [Material Design (v1): Bidirectionality](https://m1.material.io/usability/bidirectionality.html) **[Material bidi]**
- [Apple WWDC22: Get it right (to left)](https://developer.apple.com/videos/play/wwdc2022/10107/) **[WWDC22]**
- [Apple: Differentiate Without Color Alone evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/differentiate-without-color-alone-evaluation-criteria) **[Apple DWCA]**
- [Apple Education Community: Colour blindness, one in every classroom](https://education.apple.com/story/250012484) **[Apple Education]**
- [Okabe‑Ito colour‑blind‑safe palette (NYU Siegal Lab)](https://siegal.bio.nyu.edu/color-palette/) **[Okabe‑Ito]**
- [Michigan Medicine: Design tricks commonly used to monetize young children's app use](https://www.michiganmedicine.org/health-lab/design-tricks-commonly-used-monetize-young-childrens-app-use) **[Michigan]**
- [GoodBarber: Apple Kids Category guideline 1.3 requirements](https://www.goodbarber.com/help/apple-rejection-r100/apple-rejection-apps-for-kids-a365/) **[Apple Kids]**
- [Fenwick: FTC COPPA guidance on recording children's voices](https://www.fenwick.com/insights/publications/ftcs-new-coppa-guidance-on-recording-childrens-voices-five-tips-for-app-developers-and-toymakers-to-comply) **[Fenwick/FTC]**
- [Cheng et al., "Why doesn't it work?" Voice‑driven interfaces and young children's communication repair strategies (IDC 2018)](https://faculty.washington.edu/alexisr/quack.pdf) **[Quack]**
- [Explorations of Voice User Interfaces for 3 to 4 Year Old Children (U. Iowa)](https://storycarnival.cs.uiowa.edu/public/research/Explorations%20of%20Voice%20User%20Interfaces%20for%203%20to%204%20Year%20Old%20Children.pdf)
- [Duolingo blog: How we made our World Characters talk (visemes in Rive)](https://blog.duolingo.com/world-character-visemes) **[Duolingo]**
- [Rive docs: Inputs (deprecated in favour of Data Binding)](https://rive.app/docs/runtimes/inputs) **[Rive]**
- [Android Developers: Use window size classes](https://developer.android.com/develop/ui/compose/layouts/adaptive/use-window-size-classes) **[Android size classes]**
- [Fontsource package metadata (npm registry), e.g. @fontsource/heebo](https://registry.npmjs.org/@fontsource/heebo/latest) **[Fontsource]**: subsets checked for Rubik, Varela Round, Fredoka, Heebo, Assistant, Alef, Secular One, Suez One, Playpen Sans Hebrew; niqqud glyph coverage verified in the font files
- [Open Siddur Project: Open‑source Unicode Hebrew fonts, sorted by diacritic support](https://opensiddur.org/help/fonts/) **[Open Siddur]**
- [UX Collective: Reflections from usability testing with preschoolers](https://uxdesign.cc/reflections-from-usability-testing-with-preschoolers-740b27641601) **[UX Collective]**
- [Take Care: A Study on Usability Evaluation Methods for Children (arXiv)](https://arxiv.org/pdf/1212.0647) **[Usability methods review]**
- [Singapore MOE: Using the Concrete‑Pictorial‑Abstract (CPA) approach](https://nel.moe.edu.sg/la/numeracy/how-can-you-do-it-/using-concrete-pictorial-abstract--cpa--approach/) **[CPA]**
- [Vanderbilt: Explaining basic concepts behind math problems improves children's learning (Rittle‑Johnson & Mathews)](https://news.vanderbilt.edu/2009/04/10/you-do-the-math-explaining-basic-concepts-behind-math-problems-improves-childrens-learning-77421/) **[Self‑explanation]**
- [Parenting Science: Spaced learning, what's the best schedule for children's lessons?](https://parentingscience.com/spaced-learning) **[Spaced learning]**
