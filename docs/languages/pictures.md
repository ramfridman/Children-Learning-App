# The Languages courses: one shared picture set

Owner: design-director. Date: 2026-11-03. Status: **batch 1 drawn (40 objects: 51 pictures in 54 files); the rest is a plan.** For the
teachers of the three courses, the curriculum-expert, the app-developer and the owner.

Built from the three Band A batches: `english/band-a-content.md` §6 (111 briefs), `hebrew/band-a-content.md` §2 and §5
(91 objects, 14 plural sets, 8 action animations, 15 story pages, 9 stroke scenes) and `russian/band-a-content.md` §5
(116 words, the stories of A-16 and the scenes of A-03, A-07 to A-09 and A-13). Rules: `docs/art/art-brief.md` (style, SVG
subset, no text in a picture, nothing scary), the owner's drawing rule (real references first, then our own drawing, the
sources written in the generator), original characters only.

## 1. How the set works

- **One picture per real object, for every course that names it.** A cat is `cat` in English (cat), Hebrew (חָתוּל, and
  the story's חֲתוּלָה) and Russian (ко́шка). The item tables keep their own ids for now (`pic.cat`, `pic.fam.mother`); the
  "Courses" columns below map each id to its shared file, so the app-developer can rename in one pass when the packs are
  built (or keep a per-course alias table).
- **Where the files live.** `content/languages/pictures/<id>.svg`, 256 x 256, made by `tools/make_language_pictures.py`
  (like `content/starter`, where today's activity art lives, and outside the app bundle, so it travels in the signed
  `lang-<course>` packs). The three packs share one picture folder; how a picture used by two courses is packed (in each
  pack, or a shared `lang-pictures` pack) is the app-developer's call.
- **A colour set is one drawing, recoloured** (ball, balloon, boat): the pictures of a "same set" differ only in the
  feature taught. The colours are pure, named hues and the same in every course; **blue is a medium-dark blue
  (`#2459C6`)**, never light blue, so Russian си́ний is right (light blue is голубо́й). Red and green never meet in one
  colour item (the teachers' rule); the shapes do not help there, the item tables do.
- **Second looks (`-2`)** for English match pairs are a second drawing of the same thing (another pose), never a mirror.
- **Composites** (sets of 1 to 5 ducks or balls, drum strips, a big dog beside a small one, a ball on a box) are made by
  the generator from the drawn objects, so a set is always the same duck.
- **Facing.** Animals stand in side view facing **left**: the Hebrew batch asks for "the object facing right where it
  moves (the reading direction)", and the reading direction of a Hebrew page runs to the left, so the two halves of that
  line disagree. I drew left (forward on a right-to-left page); one flag in the generator (`FACE_LEFT`) turns every animal
  round. **For the hebrew-language-teacher:** left or right?
- **Status column:** **drawn** (batch 1, in the folder now), **starter** (an existing file in `content/starter` fits),
  **to draw** (later batches).

## 2. Characters (course-specific, all original)

| Who | Course | Look | Proposal |
|---|---|---|---|
| **Pip** | English: the puppet and host | The English host already drawn on the door (`app/assets/art/languages/host_eng.svg`): a budgerigar, green body, yellow face, black throat spots, violet-blue cheek patches, scalloped wings, a long blue tail. "Pip" fits a small bird (a chick's peep). | Pip **is** the budgerigar host (English §1 calls Pip "the English puppet and host"; the door shows the host). Pip's pictures are expression poses of that drawing: happy, sad (a soft frown, no tear: art brief §2), cold (a knitted hat and scarf, a few snowflakes), holds (a curtain opens on the object), arrives and leaves through the same arched door as the door art. Pip catches and hugs the dog in the story. |
| **Mika** | English (Pip's friend) and **Russian ("the friend", הֶחָבֵר)** | A child of about 5, gender-neutral, warm brown skin, a round head of short dark curls (a clear "hair" area), dot eyes with a spark, pink cheeks; base clothes a plain yellow T-shirt and teal shorts, **bare feet** (so feet, toes, socks and shoes all read); five clearly separate fingers on each hand. A grin variant shows the teeth. | **One friend for both courses.** English Mika and the Russian friend do the same things (clap, jump, sit, stand, arrive, leave, show body parts, get dressed), so one character gives one set of pictures (§4.2) and one hotspot map. The Russian lines never name or gender the friend, which fits. The Russian friend cannot be the child's own companion: the nine companions include an octopus, a turtle and a robot, which have no hair, fingers or legs to tap. **For both teachers to confirm.** |
| **The family** | Russian (A-02, A-12, A-13), Hebrew (אַבָּא, סָבָא, סַבְתָּא), **English (family words)** | One original family: mother (olive skin, black hair in a bun, a green top), father (olive skin, short brown hair, a short beard, a blue shirt), grandmother (grey hair, round glasses, a lilac cardigan: the Russian brief), grandfather (grey hair, a flat cap: the Russian brief), older brother about 9 (taller, a red T-shirt), older sister about 9 (a ponytail, an orange dress), the baby (a toddler with no clear gender, a white romper). Ages clear by height, grey hair, glasses and the cap. | **One family for the three courses** (7 portraits + the whole family). For English I propose it is **Mika's family** (Mika is a child; Pip is a bird), and Pip's own family is one picture of budgerigars for the personal turn ("This is my family"). That needs the english-language-teacher's OK (the briefs say "Pip's"). The cousin, the pet card and "someone else" are English extras. |
| **The Russian puppet** | Russian (`{puppet}` in `ch-menja-zovut`, LS10 puppet talk) | The Russian host already drawn on the door (`host_rus.svg`): a giraffe, long neck with a short mane, two tufted ossicones, orange-brown patches with cream lines. | The puppet **is** the giraffe host, as Pip is the English host. **Name proposal: Са́ша (Sasha).** It is the most common Russian name used for both boys and girls, so it keeps the Russian voice rule (the voice never reveals its own gender, syllabus §6); two open syllables with sounds Hebrew has (סָשָׁה), easy for a 3-year-old; no meaning or clash in Hebrew, not the name of any franchise character, and nothing in the course uses it. Alternatives if the teachers prefer: **Же́ня** (also both genders; ж is a new sound for a Hebrew child) or **Ля́ля** (baby-talk, but reads as a girl). Names I set aside: Ми́ша (the 1980 bear mascot and the teddy word ми́шка), Ку́зя and Фи́ля (puppet and cartoon characters), Шу́ра (שׁוּרָה, a row), Ти́ша (close to תִּשְׁעָה), Ту́ки (תּוּכִּי, a parrot), Ди́ня (дыня, the ы/и pair taught in A-20), Ми́ла (מִלָּה, a word). The russian-language-teacher and the owner confirm; the name goes into `pronunciation.csv` (`ch-menja-zovut`) and the voice plan. |
| **The hyrax** | Hebrew host | `host_heb.svg` (exists). | Hebrew A-09 says "the puppet parrot says the syllables": I propose the Hebrew host (the rock hyrax) says them, so there is no second parrot next to English Pip. **For the hebrew-language-teacher.** |
| Nitzi, Kubi | Hebrew stories 2 and 3 | The existing cast (`design/assets/nitzi-*.svg`, `kubi.svg`). | Reused as they are. |
| The neighbour | Russian A-01.06, .07 | A friendly older grown-up (not family): grey bun, a shopping bag with a loaf, a coat. | New, 2 pictures. |
| A girl, a boy | Russian (де́вочка, ма́льчик, "about 5, alone, not from the family"); Hebrew (יַלְדָּה, a girl singing) | Two children of about 5, different skin tones from Mika and the family. | 3 pictures (the Hebrew girl is a singing pose). |

## 3. Batch 1: the 40 objects used by the most items (drawn)

Counted by script over the item tables (English §4 and Russian §4 by picture id; Hebrew §4 and §5 by the word, so the
Hebrew counts are close, not exact). A colour set counts once. Files: `content/languages/pictures/<id>.svg`.

| # | Id (files) | E | H | R | Courses (their ids) | Reference (looked at 2026-11-03) |
|---|---|---|---|---|---|---|
| 1 | `ball`, `ball-red`, `ball-blue`, `ball-yellow`, `ball-green`, `ball-white`, `ball-black` | 12 | 19 | 15 | E pic.ball, ball-red/-blue/-yellow; H כַּדּוּר (red; yellow); R мяч, the A-06 object colours | everyday play ball; one drawing in six named hues |
| 2 | `cat` | 11 | 18 | 16 | E pic.cat; H חָתוּל, חֲתוּלָה; R ко́шка | ginger house cat sitting |
| 3 | `dog` | 8 | 7 | 13 | E pic.dog; H כֶּלֶב; R соба́ка | friendly tan dog standing, a collar |
| 4 | `apple` | 7 | 8 | 13 | E, R pic.apple; H תַּפּוּחַ | red apple, stem and leaf |
| 5 | `boat`, `boat-red`, `-blue`, `-yellow`, `-green` | 17 | 10 | 0 | E pic.boat, boat-colours; H סִירָה | small sailing boat on water; hull in four hues |
| 6 | `balloon`, `balloon-red`, `-blue`, `-yellow`, `-green` | 18 | 1 | 5 | E balloon colours; H בָּלוֹן; R ша́рик (A-06 may use them) | a toy balloon on a string |
| 7 | `fish` | 4 | 8 | 10 | E, R pic.fish; H דָּג | a generic orange river fish with fins (never a clownfish) |
| 8 | `banana` | 8 | 4 | 8 | all three | a yellow banana |
| 9 | `teddy` | 5 | 1 | 12 | E pic.teddy; H דֻּבִּי; R ми́шка | Commons "teddy bear toy" |
| 10 | `bread` | 8 | 1 | 9 | all three | an oval loaf with three scores |
| 11 | `milk` | 6 | 1 | 11 | E, R pic.milk; H חָלָב | a glass of milk and a plain carton (R brief), no text |
| 12 | `car` | 10 | 0 | 6 | E, R pic.car | a toy-like red car, side view |
| 13 | `cow` | 6 | 0 | 10 | E, R pic.cow | Wikipedia Holstein Friesian; Commons "Holstein cow" |
| 14 | `doll` | 0 | 3 | 13 | H בֻּבָּה; R ку́кла | a rag doll: yarn pigtails, stitched smile, striped stockings |
| 15 | `duckling` | 16 | 0 | 0 | E set-ducks-1 to 5 (the counted ducks) | Commons "Pekin duck" (ducklings); a flat duck bill so it is not the Hebrew chick |
| 16 | `drum` | 7 | 4 | 0 | E pic.drum, the drum strips; H A-08 strips | Commons "toy drum" |
| 17 | `mouse` | 0 | 0 | 15 | R мышь, мы́шка | Commons "house mouse" |
| 18 | `cake` | 6 | 9 | 0 | E pic.cake; H עוּגָה | a round two-layer cake, no candles |
| 19 | `egg` | 5 | 8 | 2 | all three | a white hen's egg |
| 20 | `duck` | 10 | 0 | 4 | E pic.duck; R у́тка | Commons "Pekin duck" (white, orange bill, on water) |
| 21 | `juice` | 5 | 0 | 9 | E, R pic.juice | a glass of orange juice, a straw, an orange slice |
| 22 | `bird` | 8 | 4 | 2 | E, R pic.bird; H צִפּוֹר | Wikipedia House sparrow; brown, so never Pip |
| 23 | `rabbit` | 0 | 10 | 3 | H אַרְנָב; R за́яц | Wikipedia European rabbit (hare: longer legs, black ear tips) |
| 24 | `book` | 6 | 0 | 7 | E pic.book; R кни́га, кни́жка | a closed picture book, a landscape on the cover, no title |
| 25 | `water` | 5 | 0 | 5 | E, R pic.water | a glass of clear water and a drop (R brief) |
| 26 | `hat-warm` | 0 | 0 | 10 | R ша́пка (and Pip and Mika cold) | a knitted hat with a pompom and a ribbed cuff |
| 27 | `scarf` | 0 | 0 | 10 | R шарф (and the cold faces) | a striped knitted scarf over a peg, fringed |
| 28 | `elephant` | 1 | 4 | 5 | E, R pic.elephant; H פִּיל (and the A-03 animals bin) | Commons "african elephant side" |
| 29 | `hat` | 0 | 9 | 0 | H כּוֹבַע (plain; story 3) | a brimmed sun hat with a band |
| 30 | `bowl` | 0 | 9 | 0 | H קְעָרָה (a mixing bowl) | a deep mixing bowl, empty |
| 31 | `oven` | 0 | 9 | 0 | H תַּנּוּר (door open) | a kitchen oven, knobs with no numerals, door open |
| 32 | `kite` | 6 | 3 | 0 | E pic.kite; H STORY-WORLD "a kite" | a diamond kite with a bowed tail |
| 33 | `cheese` | 0 | 0 | 8 | R сыр | Wikipedia Emmental (yellow, holes) |
| 34 | `pig` | 4 | 0 | 4 | E, R pic.pig | Commons "domestic pig" |
| 35 | `soup` | 0 | 1 | 7 | R суп; H A-02.14 "a bowl of soup" | a bowl of vegetable soup, a spoon, steam |
| 36 | `cucumber` | 0 | 0 | 7 | R огуре́ц | a whole cucumber and a slice |
| 37 | `blocks` | 0 | 0 | 7 | R ку́бики | Commons "toy blocks"; shapes on the faces, no letters |
| 38 | `spoon` | 0 | 7 | 0 | H כַּף | a steel table spoon |
| 39 | `horse` | 0 | 4 | 3 | H סוּס; R ло́шадь | Commons "horse standing side" (a bay) |
| 40 | `shirt` | 0 | 3 | 4 | H חֻלְצָה (plain; the A-03 clothes bin); R футбо́лка | a plain teal T-shirt |

Contact sheet (every file at 200 px, then at 64 px): `docs/design/languages/pictures_batch1.png`.

## 4. The whole set

Every unique picture of the three Band A batches, by group. E, H, R = English, Hebrew, Russian.

### 4.1 Shared objects (173)

**Animals (42).**

| Id | Courses | Status | Notes and reference to look up |
|---|---|---|---|
| `cat` | E H R | drawn | |
| `cat-2` | E (pairs) | to draw | a second pose (lying, tail curled) |
| `cat-tomcat` | R кот | to draw | "a big striped tomcat": grey tabby, bigger than `cat`; never in one item with `cat` (R rule) |
| `dog` | E H R | drawn | |
| `dog-2` | E | to draw | sitting |
| `dog-shaggy` | R пёс | to draw | a shaggy friendly dog (the chant) |
| `fish` | E H R | drawn | |
| `bird` | E H R | drawn | |
| `bird-2` | E | to draw | flying |
| `duck` | E R | drawn | |
| `duck-2` | E | to draw | standing on the bank |
| `duckling` | E (sets) | drawn | |
| `cow` | E R | drawn | |
| `cow-2` | E | to draw | grazing |
| `pig` | E R | drawn | |
| `frog` | E (and story page 4) | to draw | a green frog sitting; Wikipedia "Frog" (`content/starter/frog.svg` is a counting placeholder) |
| `frog-2` | E | to draw | leaping |
| `elephant` | E H R | drawn | |
| `horse` | H R | drawn | |
| `rabbit` | H R | drawn | **for the russian-language-teacher:** one sitting rabbit serves за́яц too (no black ear tips); a true hare is one more picture if you want it |
| `rabbit-tail` | H זָנָב | to draw | `rabbit` with the tail lit (a composite) |
| `mouse` | R | drawn | |
| `rooster` | H R | to draw | big red comb and tail (R brief) |
| `hen` | R | to draw | brown hen, small comb |
| `goat` | R | to draw | white goat, beard, small horns |
| `wolf`, `fox`, `bear`, `hedgehog`, `squirrel`, `whale`, `beetle`, `lynx` | R | to draw | bear: a real brown bear, not a toy (R brief); lynx: ear tufts, short tail; hedgehog also the story |
| `giraffe` | R | to draw | a realistic-proportion giraffe, so it differs from the chibi host Са́ша |
| `camel`, `donkey`, `butterfly`, `tortoise`, `ant`, `chick`, `sheep`, `bat` | H | to draw | chick: a round yellow chicken chick with a pointed beak (not the duckling); sheep: woolly white (A-03.7); butterfly also the kite look-alike (A-03.9); bat: friendly, never scary |

**Food and drink (30).** `apple`, `banana`, `bread`, `egg`, `cake`, `milk`, `juice`, `water`, `cheese`, `soup`, `cucumber`
(drawn); `strawberry` (H תּוּת, R клубни́ка: two or three berries), `carrot` (H R), `cookie` (H עוּגִיָּה, R пече́нье: a round
biscuit), `pizza`, `pita` (round and pale, so it can trap with the plate, A-03.5), `flour` (a bag with some spilt), `sugar`
(a bowl of cubes), `olive` (green, a leaf) for H; `orange`, `pear`, `grapes`, `watermelon`, `tomato`, `potato`, `porridge`,
`rice` (a bowl of white rice), `onion` for R; `tea` (a mug of tea with steam: R чай **and** E cup-hot), `cup-cold` (E: ice
and frost). (to draw)

**Clothes (18).** `hat`, `hat-warm`, `scarf`, `shirt` (drawn); `hat-cat-ears`, `shirt-striped` (blue-white), `dress-strawberries`,
`apron`, `sandal`, `swimsuit` for H; `dress` (plain), `jacket`, `trousers`, `socks`, `sock` (one), `shoes`, `boots`, `mittens`
for R. (to draw) The dress for R stays plain, so it never traps with the strawberries of A-07.

**Toys and play (36).** `ball` x 6 colours, `balloon` x 4 colours, `boat` x 4 colours, `car`, `doll`, `teddy`, `drum`,
`book`, `blocks`, `kite` (drawn); `ball-2`, `boat-2`, `car-2`, `drum-2`, `kite-2`, `bike` and `bike-2` for E;
`balloon-big` (R шар), `pencil` (R; starter `pencil.svg` is a placeholder), `top`, `stacker` for R; `teddy-nose` (H אַף: the
teddy's face, nose lit), `kite-butterfly` (H), `present` (H מַתָּנָה **and** E pic.box, the gift box; the app draws the "?"),
`wool` (H, a ball of white wool). (to draw)

**House, kitchen and things (27).** `bowl`, `oven`, `spoon` (drawn); `cup` (H כּוֹס, a plain cup), `chair`, `table`, `pot`,
`fork`, `fridge`, `plate` (also the R picnic plate), `towel-striped`, `umbrella`, `bed`, `box`, `basket`, `cupboard`,
`window`, `clock` (hands only, no numerals), `house` (H בַּיִת, R дом), `house-roof` (H גַּג: the house, roof lit), `tent`,
`pram`, `soap-bubble`, `needle`, `thread` (a reel), `ring` for H; `manhole` (R люк). (to draw)

**Vehicles (3).** `ship`, `plane`, `rocket` (flying to the moon) for H. (to draw)

**Nature (11).** `star`, `moon`, `sea`, `tree`, `bush` (round, green), `wind` (leaves and a hat blown sideways), `rain`,
`clouds`, `sun`, `rainbow`, `cave` for H. (to draw)

**Colour patches (6).** `col-red`, `col-blue` (medium-dark), `col-yellow`, `col-green`, `col-white` (grey edge), `col-black`
for R: a paint splash, the same shape in every colour. (to draw)

### 4.2 People and characters (66)

| Group | Pictures | Count |
|---|---|---|
| The family (shared) | `fam-mother`, `fam-father`, `fam-grandmother`, `fam-grandfather`, `fam-brother`, `fam-sister`, `fam-baby`, `fam-all`; E extras `fam-cousin`, `fam-pet` (a cat and a dog), `fam-someone` (a soft outline and a heart) | 11 |
| Other people | `girl`, `boy` (R), `girl-sing` (H), `teacher-sing` (H מוֹרָה with children), `neighbour-arrive`, `neighbour-leave` (R) | 6 |
| Pip (E) | `pip-happy`, `pip-sad`, `pip-cold`, `pip-holds`, `pip-arrive`, `pip-leave`, `pip-family` (budgerigars, the personal turn) | 7 |
| Mika, the friend (E and R) | actions `act-clap`, `act-jump`, `act-listen`, `act-look`, `act-sit`, `act-stand`, `act-stop`, `act-wave` (E and R), `act-run`, `act-walk`, `act-take` (R); `mika-body` (one hotspot map for E's 8 parts and R's 11: hair, head, eyes, ears, nose, mouth, teeth, arms, fingers, belly, legs; in an item only 3 glow and **no two hotspots overlap**, the R rule); close-ups `body-head`, `-eyes`, `-ears`, `-nose`, `-mouth`, `-hands`, `-feet`, `-tummy` (E); faces `mika-happy`, `-sad`, `-fine`, `-cold`, `-hot`, `-eat` (E); `mika-arrive`, `mika-leave` (E and R приве́т, пока́); `mika-gift` (R спаси́бо: handed an apple); `mika-yes`, `mika-no` (R да, нет: nodding, shaking the head); scenes `mika-icecream`, `-present`, `-snow`, `-walk` (E); mouth shapes for the R hints (A-19, A-20): lips closed, teeth, round, tongue up, trill, wide smile, puzzled | 42 |

The sad faces are a soft frown with no tear (art brief §2: no tears); **for the english-language-teacher**, the English
brief asks for "a small tear". The counting hints of R A-10 and A-11 (fingers) reuse `app/assets/art/hints/hand_*`.
Pip, Mika and the family need the owner's eye on a model sheet before their poses are drawn (batch 3).

### 4.3 Scenes, stories and course pieces (94)

| Group | Pictures | Count |
|---|---|---|
| English story "Bounce, Ball!" | `story-bounce-1` to `-6` (Pip, the red `ball`, `cat`, `duck`, `frog`, `dog`) | 6 |
| Hebrew stories | `s1-p1` to `p5` (the rabbit's ball), `s2-p1` to `p5` (Nitzi bakes a cake), `s3-p1` to `p5` (Kubi's hat) | 15 |
| Russian stories | `st1-p1` to `p3` (a dog and a ball), `st2` (a hedgehog finds an apple), `st3` (a cold girl finds her hat), and the six wrong frames `st1-sleep`, `st1-cat`, `st2-sleep`, `st2-bear`, `st3-beach`, `st3-boy` | 15 |
| Hebrew actions (A-02, short animations) | the rabbit kicks, the cat searches, Nitzi stirs, a fish swims; the second scene: a boy kicks, a duck swims, and two more | 8 |
| Hebrew stroke scenes (A-14) | rain from a cloud to a flower (2), a car to its house, a rabbit over a hill, a ladybird round a pond, a boat to its jetty, a ball over a fence, a fish round a stone, a door | 9 |
| Hebrew place pictures (A-04 LS01) | 5 items x 3 (ball on a box, box on a ball, ball in a box; cat in a basket ...; dog and chair; bird and boat; apple and bowl), made from the object pictures | 15 |
| Hebrew new contexts (A-02.13 to .16) | a bush in a park, a hat on a snowman, wind in a boat's sail (the bowl of soup is `soup`) | 3 |
| Russian LS11 scenes | a room (A-13), the family in a garden (A-13.06), a picnic cloth (A-07), a toy box (A-08) | 4 |
| Course pieces | `bin-box` (H A-03: an open box, its typical member's picture on the front), `thumb-up`, `thumb-down` (E: green thumb up; thumb down in a calm blue, never red, never a cross) | 3 |
| Composites made by the generator | `set-balls-1` to `5`, `set-ducks-1` to `5`, `drum-strip-1` to `4` (E; H uses 1 to 3), `dog-big` (a big and a small dog), `ball-pair` (a big and a small ball) | 16 |

Not pictures: the speech bubble (LS10, a component), the age cards and every numeral, letter and print mark (H A-10 to
A-12; drawn by the app in Heebo), the windows of R A-12 (a component around object pictures).

### 4.4 Count

| Group | Unique pictures | Drawn |
|---|---|---|
| Shared objects (4.1) | 173 (42 + 30 + 18 + 36 + 27 + 3 + 11 + 6) | 51 (the 40 objects; the ball, balloon and boat sets give 14 colour pictures) |
| People and characters (4.2) | 66 | 0 (the three hosts on the doors exist and are not counted) |
| Scenes, stories and course pieces (4.3) | 94 | 0 |
| **Total** | **333** | **51** (54 files: `ball`, `balloon` and `boat` are aliases of their red pictures) |

Of the 333, 16 are composites the generator makes from drawn pictures, so **317 are drawings**: **51 drawn, 266 left**
(122 objects, 66 people and characters, 78 scenes and pieces), plus the 16 composites.

## 5. The next batches

1. **Batch 2, objects (122):** the rest of §4.1, the R animals and food first (the biggest R skills, A-05 and A-07),
   then the H things of A-06, A-07 and A-09 (rhyme pairs), then the E second looks. Same generator.
2. **Batch 3, characters:** a model sheet of Mika and the family (front, side, colours, hotspot map) for the owner and the
   teachers, then Pip's poses, Mika's 42 pictures, the family portraits (66 in all).
3. **Batch 4, scenes and stories (78, and the 16 composites):** the 36 story pages, 8 actions, 9 stroke scenes (after the stroke directions F6 are
   settled), the place pictures, the R scenes.

## 6. Open questions

- **hebrew-language-teacher:** animals facing left or right (§1); the hyrax instead of a parrot in A-09 (§2).
- **english-language-teacher:** Pip is the budgerigar host; the family is Mika's, Pip's own family one budgerigar picture
  (§2); no tear on the sad faces (§4.2).
- **russian-language-teacher and the owner:** the puppet's name (Са́ша, §2); Mika as the friend (§2); one rabbit for
  за́яц (§4.1).
- **curriculum-expert:** that `rabbit` (H, R), `present` (H gift, E box) and `tea` (R чай, E hot) teach the right thing
  with one picture each.
- **app-developer:** the picture folder and how the three packs share it (§1); the per-course id aliases.
