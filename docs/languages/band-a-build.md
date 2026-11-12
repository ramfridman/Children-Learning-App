# Band A of the three courses: how the content becomes signed packs

Owner: app-developer. Date: 2026-11-07. Status: **the pipeline is built and the teachers' Band A is in the packs: every template has a recipe (194 activities in English, 157 in Hebrew, 463 in Russian, 123 of them teach or hearing screens); the own name, the print direction, the teach screens of the Russian routes and a font for one item were added the same day, and the routes of 2.6.1 (a reader served by its oral route, the hearing screens, the say step picture first) and the batch-6 pictures in the third step; what still waits is in section 2.4.** Applies the owner's request of 2026-11-07 (the Languages island must become playable: ENG-1, HEB-1, RUS-1) to `frame.md` §1.5 and §6, `docs/milestones/L0.md`, `L4.md`, `L-course.md` and `L5.md` §9 ("the language pack generator is built with the Band A packs").

## 1. What existed, and what was missing

**Existed (merged on `main`):**

| Part | Where |
|---|---|
| The course id on every document, `lang-<course>` pack ids, the manifest's `course`, one signed pack per course | `content/schemas.dart`, `content/pack_validation.dart`, `engine/course.dart` (L0) |
| The invariants of frame §1.5 and the F5 content checks (script purity, tagged distractors, 2-choice limits, set coverage, the tag catalogue, the tutor off) | `content/pack_validation.dart`, `content/language_checks.dart`, `content/scripts.dart` (L0, L1) |
| Installing and loading a language pack beside the starter pack, `installedLanguages`, `languagePack(course)` | `content/pack_installer.dart`, `content/content_repository.dart` |
| The island, the doors, the course home reading a pack (path, "what is next", placement invitation), the lesson screen with `course`, the guards, Today's Adventure, parent progress | L0, L-course (`child/course_home.dart`, `app/language_providers.dart`, `play/lesson_screen.dart`) |
| The templates Band A needs: LS01 tap (`tap_answer` 1.3), LS09 `say_it`, LS08 `story`, LS10 `puppet_talk`, LS11 `listen_do`, LS12 `sing_along`, LS03 drum (`sound_boxes`), LS13 placement, `count_tap` | L1, L3, L4 |
| `pack_builder build <folder>`: it builds and signs **any** pack folder, so a course pack was already buildable by hand | `app/tool/pack_builder.dart` |
| The shared pictures (`content/languages/pictures`, 360 files), the pronunciation tables (`docs/languages/<course>/pronunciation.csv`), the teachers' Band A batches (`band-a-content.md`) | design-director, voice-and-sound-director, teachers |

**Missing (built now):**

1. No source folder for a course pack, and no generator: the teachers' batches were tables in Markdown and the fixtures in `app/test/support/course_packs.dart` were Dart. `tools/author.py` makes the maths lands' packs; nothing did the same for a course.
2. No command that builds the pack of a course from its source (the right folder, the id and course checked, the old bundled version removed).
3. **No bundled pack and no way to load one.** `languagePacksProvider` only listed what was already installed, and the code said "language packs are never bundled". Nothing could ever put a pack on a phone except the dev page.
4. No test on real course content: the validator tests ran on fixtures only.
5. No playthrough of a real pack, and no render of a real lesson.

## 2. The authoring format (what each teacher writes)

Everything a teacher writes is JSON in his own folder. One generator, `tools/lang_pack.py`, serves the three courses; the course only changes the files it reads.

```
content/languages/<course>/                 eng, heb, rus
  course.json                               the course: pack version, Hebrew lines, feedback, hint ladders, tags, defaults
  units/<NN>-<name>.json                    one file per skill: the skill, its items, its lessons (read in file-name order)
  placement.json                            the placement game (optional, frame §3.2)
  pack/                                     GENERATED: the flat pack source, committed like content/starter (never edited)
  voice-plan.json                           GENERATED: every clip the pack names, with its text (for the voice-and-sound-director)
docs/languages/<course>/pronunciation.csv   the clip table (already there): every target-language clip an item plays
content/languages/pictures/<id>.svg         the shared pictures (already there)
```

`python tools/lang_pack.py eng` (or `heb`, `rus`, `all`) reads the files, says **every** problem at once (file, item, what to fix), and only then writes `pack/` and `voice-plan.json`. `--check` writes nothing and exits 1 if the committed files are out of date (a test does the same). Nothing is voiced and nothing is paid.

### 2.1 `course.json`

| Key | What | Example |
|---|---|---|
| `course` | `eng`, `heb` or `rus`; must match the folder | `"eng"` |
| `pack` | `version` (semantic, **raise it for every pack that is signed after a change**, see §4) and `minAppVersion` | `{"version": "0.1.0", "minAppVersion": "0.5.0"}` |
| `defaults` | `frame` (the Hebrew line every item says unless it names one), `ladder`, `celebration` (a line id), `rep`, `minutes`, `retention`, `pictureLabel`, `soundLabel`, `pageAlt`, and the line ids the recipes use: `pass` (the puppet's "that's OK"), `heard` and `together` (the say step), `answerPrompt` ("how many?") | |
| `lines` | **The Hebrew lines** of the course, by id: `{"he": "…with nikud…", "voice": "…text for the voice…", "review": "text-ready"}`. Ids are lower case letters, digits and hyphens (the teacher's `he-ins-listen-tap`, `i-find`, `ok-3`, `f01`). `he` is the caption and the text of the clip; `voice` goes to the voice plan only. | |
| `feedback` | `right`: a list of praise lines (item *n* of the course says line *n* mod the list length), `wrong`: the first-error line, `unsure`, and `byTag`: a line per tag slug that the first error says when that tag's distractor was touched | |
| `ladders` | Hint ladders by name, **exactly 3 steps**: `{"line", "action", "target"}`. A step may say `"orLine"`: the line it says when its `@gloss` has none (a first language has no gloss). Actions: `replay_prompt_slow`, `highlight_objects_sequentially`, `show_fingers`, `worked_example` (level 2 must change the representation: the app's hint ladder draws the picture for it, B-40) | |
| `glosses` | target clip → the line that says what it means (for `"line": "@gloss"` in a ladder) | `{"en-hello": "he-gl-hello"}` |
| `tags` | The misconception catalogue of the course, by slug: `id` (`<course>.<strand>.<slug>`), `kind` (`diagnostic`, `on_the_way`, `accent`, `practice`), `family` (frame §4.1), `parentText` (Hebrew, for the parent), `homeActivity` (Hebrew, optional), `preferredRepresentations`, `repair` (item ids, optional). A tag no item uses is left out of the pack. | |

A step of `feedback` or of a ladder is a line id, or `{"line": …, "target": …, "show": true}`. Placeholders: **line** `@frame` (the item's own question) and `@gloss` (the gloss of the item's word); **target** `@target` (the item's word), `@slow` (its `-slow` clip if the table has one, else the word). A spoken line is **one Hebrew clip, then at most one target-language clip** (frame F3).

### 2.2 `units/<NN>-<name>.json`

```json
{
  "skill":   {"id": "ENG-A-01", "strand": "lis", "title": "בְּרָכוֹת", "prerequisites": [{"skill": "ENG-A-00"}]},
  "items":   [ {"id": "i01", "kind": "tap", "target": "en-hello", "options": ["pip-arrive", "pip-leave"], "wrong": {"pip-leave": "sem"}} ],
  "lessons": [ {"id": "greet-1", "title": "בְּרָכוֹת", "items": ["i01", "i02"]} ],
  "docs":    [ {"kind": "gate", "id": "eng.oral", "doc": {"requires": ["ENG-A-06"], "holds": ["ENG-B-01"]}} ]
}
```

* **Skill.** `id` has the course in capitals (`ENG-A-01`; the band letter is the band of every item); `strand` is the parent page's strand (2 to 4 letters, as in `L-course.md` §4); `title` is Hebrew. The generator fills what it can derive: `representations` and `misconceptions` from the skill's items, the course, the domain `languages`, the retention defaults. A skill may carry the engine fields of L0 (`bundle`, `setCoverage`, `soundRight`, `letters`, `writing`, `graphemes`, `tricky`, `binary`, `masteryRequires`, `worldObject`, `childLine`); they go through unchanged.
* **Item, kind `tap`** (LS01, the child hears the clip and touches the picture or letter). `id` (lower case, digits, hyphens; the activity is `<course>.<skill slug>.<id>`, for example `eng.a01.i01`). `options`: 2 or 3 entries, each a picture id (the file name in `content/languages/pictures` without `.svg`, so `pip-arrive`), `"text:ב"` for a letter or mark tile, or `{"pic": …, "clip": …}` for a picture that plays its own word. `right` is the first option unless it says another. **`wrong` gives every distractor its tag slug** (frame §2.3: each carries the error it reveals). `target`: the clip id (a row of the course's `pronunciation.csv`) played after the Hebrew frame; `show: true` puts its text in a chip; `frame`: another Hebrew line; `purpose`: `learn` (default), `practice`, `probe`, `repair` or `check` (a check is a transfer item: `check` sets `checkType` to `transfer`); `rep`; `ladder`; `variant` (the variant group; the word by default); `difficulty`; `alt` (the screen-reader text). The generator writes the rest: the scoring (a 2-option item allows one retry), `maxAttempts`, the credit by hint level, **the tutor off** (frame §1.6), the hint ladder, the feedback, the voice ids, the file shape.
* **The other kinds** (each is a recipe in `tools/lang_recipes*.py`; the teacher writes the same things as for a tap, the recipe adds the layout and the file shape). Common fields: `id`, `purpose`, `frame`, `rep`, `ladder` (a name, or three steps written in the item), `after` (the clip or two clips the right answer's praise ends with), `feedback` (`right`, `wrong`, `unsure`, `byTag`: lines of this item that replace the course's), `hintWord` (the clip hints and praise name when the prompt must not say it), `target` and `target2` (the one or two clips after the frame line).

| Kind | Template | What the teacher writes | What the recipe does |
|---|---|---|---|
| `tap` | LS01 tap | as above, and `stage` (a picture, or `{"box", "front"}`: a picture with a thing in front), options that are only a sound (`{"clip": …}`), `letters` (tap-all: the right cards, `face` letter), `pole`, `pairWith`, `after`, `feedback` | the stage is `scene.group` of one picture; tap-all is `tap_answer` 1.4; a two-option item allows one retry |
| `listen_do` | LS11 | `mode` `buttons` (action pictures), `hotspots` (parts of a picture, by name), `cards` (the same as close-up cards), `drag` (things taken to a place), `place` (one thing to a place) or `embodied` (`clips`); `picture`, `target`, `options`, `right`, `wrong`, `thing` | the touch areas come from the picture's own map (`*.hotspots.json`, `scenes.areas.json`); a body item whose parts are too close to touch becomes `cards` by the map's own decision; things wait in a rail at the start side |
| `puppet` | LS10 | `mode` `bubble` (`prompt`: the puppet's one or two clips; `options`: bubbles with a picture or only a sound) or `personal` (`topic`, `cards`, `cardClips`, `reply`, `pass`); `then`: a `say` step after a bubble | the right bubble's clip is the puppet's answer; a personal turn is practice, no tag, a pass that is always there |
| `say` | LS09 | `picture`, `clip` (the word), `forms` and `foils` (else the clip's text and none), `heard`, `together`; `then`: a `tap` (a scored touch on 2 or 3 pictures after the say step) | `say_it`, never wrong; with `then` two activities `<id>` and `<id>t`, which a lesson plays in order |
| `chant` | LS12 | `lines` (clips), `pictures` (`pic` and `clip`) | the pictures whose word a line says light while it is said |
| `drum` | LS03 | `word`, `slow`, `picture`, `beats`, `oneMore`, `oneFewer` (tags) | free response; one more and one fewer taps are the tags, any other count is a retry |
| `story` | LS08 | `mode` `listen` (`pages`, `words`) or `dialogic` (`pages`, `pauseAfter`, `question`, `options`, `recast`) | a thing in a page says its word when the picture has a `*.hotspots.json`; the recast ends the praise |
| `count` | T02 | `objects`, `count`, `clips`, `answerPrompt`, `options` (`clip` and `value`) | the counting taps are practice; "how many?" is on sound buttons; the lit picture of a thing is made from it (a drawn `<picture>-lit.svg` is used when there is one) |
| `pairs` | LS01 pairs | `pairs` (`[picture, picture, clip]` or by `cards`), `wrong` (`"a+b": tag`) | two rows; the bottom row stands one place along; each bottom face carries the tag of what joined it |
| `sort` | LS01 sort | `bins` (`label` clip, `picture`), `cards` (`pic`, `text` or `clip`, with `bin`), `traps` or `wrong` | bins say their name; a card put in a wrong bin carries its tag |
| `sequence` | LS01 story line | `tiles`, `clips`, `wrong` | the tiles start one place along; `answer.order` is the right order |
| `trace` | T04 (practice, E-1) | `scene` (a picture of `strokes/prewriting-<course>-a14.json`), `guide`, `tag` | the path comes from the stroke file |
| `name`, `name-letter` | LS01 tap, `tap_answer` 1.5 (Hebrew A-11) | `options`: what each option is made of at run time (`own`, `first`, `length` in a choice of names; `first`, `lookalike`, `last` in a row of letters of the name), `wrong` (a tag to change), `font` | **no name is in the file**: the unit holds `ownName` (the closed list of names and the look-alike pairs of letters with their tags) and the app makes the options from the child's first name when the lesson opens, on the device only (section 2.5) |
| `page-zones`, `follow` | LS08 `story` 1.1, modes `zones` and `follow` (Hebrew A-12) | `page` (a picture), `clip` (the clip of the page's text), `zones` (2 or 3 places of the page, with `line1-start`, where reading starts), `wrong` | the text is the clip's `shown` text, one sentence to a line; a `follow` page gives each word a clip cut from the page's clip by its timing, listed in `voice-plan.json` as `cutClips` (nothing of them is voiced) |

A spoken line is now **one Hebrew clip, then one or two target-language clips** (`target`, `target2`): a question and its answer, or the two sounds of a same-or-different item. A misconception document may list **up to 60 skills** (it was 10; eng.lis.sem names 12 skills of Band A alone).

* **Item, kind `raw`.** For a template that has no recipe: `{"id": …, "kind": "raw", "activity": {the activity document}}` with the template's own fields. The generator sets `schema`, `id`, `course`, `domain`, `band`, `review` and `skills`; the pack builder checks the rest exactly as for any activity. No unit uses it now.
* **Teach screens and routes** (Russian, section 2.6): `teach` (the new words of the skill, in sets of clip ids) and `routes` (what each route is served). **Own name** (Hebrew A-11): `ownName`. **A font for one item**: `"font": "display"` on any item (Secular One, Hebrew only).
* **Lesson.** `id` (the lesson is `<course>.<id>`, at most 40 characters), `title` (Hebrew), `items` (this unit's item ids, or `<skill slug>.<id>` for another unit's), `celebration` (a line id, else the default), `minutes`, `sequence`. **The order of the path is the order of the files and of the lessons in them**; name the files `01-`, `02-`… in the order the child should meet them (a lesson may set `sequence`). Put in a lesson the items to *learn*; the checks and probes stay outside it (the checks come as the **check visit** of section 7.4 and the revisits, the probes as the placement; a question about the story or chant just heard may stay in its lesson, marked `"inLesson": true`).
* **Doc.** A gate (`gate/v1`) or other whole documents the course needs. The generator adds `schema`, `review` and `course`.

### 2.3 `placement.json` (frame §3.2)

```json
{"perVisit": 8, "thanks": "he-fb-right-1", "celebration": "he-bye",
 "strands": [{"id": "o", "start": [{"answer": "knowsLetters", "equals": "some", "level": 1}],
              "levels": [{"items": ["a01.p01"], "assumes": ["ENG-A-01"]}, {"items": ["a01.p02"], "assumes": ["ENG-A-03"]}]}]}
```
Probes are ordinary `tap` items with `"purpose": "probe"`, written as `<skill slug>.<id>`. At least 2 levels a strand, at most 6 probes a level (the validator's limits). The pilot has no placement (a placement needs the syllabus's staircase); it was proved on a scratch copy of the English pilot with two probe items and one two-level strand, which the real pack builder accepted.

### 2.4 What the format cannot say yet (said plainly, 2026-11-07)

Every Band A template has a recipe (§2.2). What is still not in the packs, and why:

* **Built the same day (2026-11-07, second step):** Hebrew **A-11** (the child's own name, 5 items) and **A-12** (print direction, 7 items) are in the Hebrew pack (sections 2.5 and 2.7); the Russian **teach screens** (117) and the route filter (section 2.6); **a font per item** (section 2.8); the hotspots of a listen-and-do are no longer drawn at rest (section 2.9).
* **Built the same day (third step):** the Russian routes of section 2.6.1 (R1 to R6: a reader served by its oral route, the hearing screens of A-20, the say step picture first, the invariant and its guards); the **heart and the flower** of Hebrew A-10 (t05 and s06 are the pictures `shape-heart` and `shape-flower`; no card of A-10 is a text character or a stand-in any more); and the **six "find it in the room" items of RUS-A-13**, now LS11 hotspots on the rooms `scene-room-ball`, `-cat`, `-mouse`, `-hat`, `-apple` and the garden family `scene-garden-family`, each ending its praise with the "Вот …!" clip. Item 06 asks with `f01` ("listen, and touch the picture"), not `f19`, which says "in the room": the hebrew-text-editor may want a line for "in the garden". Not needed for Band A, and staying in the unit files as the teachers' notes, not read: `from`, `order`, `weight`, `embodied`, the A-16 to A-19 pacing notes and the extension of A-15 to every word of A-02 to A-09 (reasons in `docs/languages/russian/routes-band-a.md` section 2.2). Still open from the routes note: the order of the lessons of A-10 and A-11 (the teacher's), and the wording of `f07` after the request in A-14 item 11 (the editor's).
* **Items left out of the packs because a clip is missing**, for the voice-and-sound-director: the ten animal-sound items of RUS-A-05 (23 to 32) need the clips `sfx-cat` … `sfx-wolf` in the Russian clip table.
* **Things the teachers asked for that the schema holds only in part:** the two pauses of one Hebrew story are two items (each plays the story to its own pause; the teacher's one item with two pauses has no place in `story`); a story's word cards and the parent card are not in the pack; the A-02 action pictures play as their second frame only (the two-frame animation has no activity field); `box opens` in the English guessing game and Pip holding the object (`pip-holds` with a picture in his hands) are not drawn; the Hebrew story-order item has one tag, not two (`order` for a reversed line and `story_order` for a swap; the document takes one); the Russian rhymes are heard twice as chants (the chant clip is one line and a chant has two lines at least), and the word-pair hint of their gap items (two target clips after one Hebrew clip, a pair for each option) is not built; the English embodied steps play the first two clips of their list; the Russian same-or-different buttons are the friend nodding and shaking the head (no same / different icons are drawn); the Russian yes-or-no items show the thing the friend holds or points at without the friend; Hebrew A-10 has no text character left (see above): the shapes are pictures.
* **Touch areas the app-developer measured** from the drawings, for the design-director to refine (`content/languages/pictures/scenes.areas.json`): the on, under, by and in places of the chair, box, table and bed, the target of the picnic, the toy box, Pip and the friend's body. The areas of the body, the doll, the big and small dog and ball and the bounce story are the design-director's own.
* **Hebrew in the generator is always `needs-editor`** (CLAUDE.md), and so are the lines the recipes add (the pass line, the page and picture labels, the titles of the extra lessons).
* **Option labels** (for TalkBack) are the generic "picture" or "sound" until a `pictureLabel` or an option's own `label` is written.

### 2.5 The child's own name (Hebrew A-11, `tap_answer` 1.5, `answer.type` `name`)

A pack holds **the rules and a closed list of 52 names, never a name**. An item says what each option is made of (`own`, `first`, `length`; or `first`, `lookalike`, `last`), the unit's `ownName` holds `names` and `pairs` (the eight look-alike pairs of letters, each with its `heb.pk.shape_*` tag), and the validator holds the item to it (Hebrew, Band A, no face and no clip on an option, no spoken answer, the right source, a closed list with no repeat). When the lesson opens `play/name_options.dart` (`OwnName`) makes the options **on the device** from the profile's first name:

* the name is cleaned as everywhere (`displayChildName`), its first word is taken, **nikud is removed** (the other names carry none, so a pointed name would be a cue), and it must be 2 to 8 Hebrew letters; otherwise the companion's name stands in, and then the house character's (ניצי), so that an item always has a face (decision 25's fallback);
* **NAME-FIRST**: a name of the list with the same first letter (another length when there is one); when none starts so, the name of the look-alike letter, with that pair's tag. **NAME-LENGTH**: as many letters and another first letter, never the NAME-FIRST name; the nearest length for a name longer than any in the list. Never the child's own name;
* a row of letters: the first letter (right), its look-alike (the tag of its pair is found at run time) and the last letter (`order`); a name whose last letter is its first or its look-alike, or that has no look-alike, passes the item to the companion's name;
* what is made is an ordinary choice of texts (`answer.type` `choice`), so the tile, the hint ladder, the tags and the retry are the existing ones. **The name stays on the phone**: it is never logged, written, stored, synced, sent, shown to the tutor or voiced; an answer is recorded as the id of the option (`o1`). `test/own_name_test.dart` proves it (the row of an attempt has no Hebrew letter; the source of `name_options.dart` touches no log, network, database or voice; the only callers are the lesson screen and the controller's fallback). The security-engineer reviews it.

Names print in Heebo 500 (not 700: the shared tile face has one weight for words); the check A-11.4 is in Secular One (section 2.8).

### 2.6 Teach screens and routes (Russian; every course from L7)

**Amended 2026-11-12 (L7; the rule the build follows, built in step L7-4; frame §2.3 LS09 teach mode, §3.5.1).** What this section says of Russian becomes the rule of **every course**, with four changes:

* **Every course has teach screens** (the Meet screens). English and Hebrew get `teachPictures` and `defaults.teach` as Russian has them; `lang_routes.py` already runs for every course, and an unset route is served as `new`.
* **A teach set may stand anywhere in a lesson.** A set says `before`: the lesson item it precedes (none: before the first item). `itemsFor` gives the lesson's items with each set's screens in front of its `before` item, and the validator checks that every `before` names an item of the lesson. This replaces "a set goes before the first lesson whose prompts ask one of its words" and "the screens of the sets, then the lesson's items" below: a lesson is authored as `recall`, `meet`, `find` and `use`, and the generator flattens it, so the Meet screens come after the Recall items.
* **A set is 2 to 3 words** (it was 4 to 6), one Meet screen per word.
* **The Meet screen** gains the Hebrew meaning, said once (eng, rus: the word's `gloss`; heb: a Hebrew explanation line), and a tap on the picture replays the word. The lesson keeps the words its Meet screens introduced, for frame §3.3.10.

Unchanged: a heritage speaker never sees a teach screen (hearing screens instead, 2.6.1); a teach screen writes nothing and is not in the engine's catalogue; R5 below, read as "a route adds screens before or between a lesson's items".

The teachers' unit files carry `teach` (the new words of the skill, in sets of 4 to 6) and `routes` (what each route is served). They are now data the app reads:

* `course.json` says the picture of each teach word (`teachPictures`, 116 words, from the pictures the course's own items use for them) and the lines of a teach screen (`defaults.teach`: `frame` f03, `heard`, `together`).
* The generator makes **a teach screen for each word**: a `say_it` activity (LS09, echo: the picture, the word, a pause, the word again) with `answer.teach`, id `<course>.<skill>.tcNN`. It is **unscored, writes nothing, has no microphone and no help** ("I said it" goes on), is not an item of any lesson, and **the engine does not see it** (not in its catalogue, no representation counted for the skill).
* A lesson has `teach`: the sets, each with the routes that are shown it and its mode (2.6.1 R2). A set goes before the first lesson whose prompts ask one of its words (a set no lesson asks by word, the body parts, goes before the lesson of its own number). A `teach` set names only `new`: **a heritage speaker is never shown a teach screen**: the validator refuses the route, the generator never writes it, and `PackContent.itemsFor` refuses it as well.
* Lesson building: `PackContent.itemsFor(lesson, route:)` gives the screens of the sets the served route is shown, then the lesson's items; `LessonController(route:)` plays that. A route not set yet counts as a new learner. The reader is resolved before the lesson is built, per skill, by `servedRoute` (2.6.1 R1): the record `"reader": {"as": "oral"}` (A-01 to A-15) serves it by strand 1 of its placement, `"as": "heritage"` (A-16 to A-20) as a heritage speaker.

The routes record is structured (`{"new": {"say": "echo"}, "heritage": {"hear": true, "say": "picture", "from": "04", ...}, "reader": {"as": "oral"}}`; the teachers' prose is in `note`). What of it the app does not read is in section 2.4.

#### 2.6.1 Routes (decided 2026-11-07, built the same day)

Decided by the curriculum-expert; the reasons and sources are in `docs/languages/russian/routes-band-a.md`. **Built in the third step**; where the build differs from the plan below, the note "*As built*" says how. Nothing here changes mastery or evidence (frame §3.3.7), and nothing is voiced except the one new line of R3.

**R1. The served route.** A pure function decides how the child is served in a skill:

```
servedRoute(route, skill, assumed, placement) -> "new" | "heritage"
  "heritage"        -> "heritage"
  "new" or null     -> "new"
  "reader"          -> skill.readerAs == "heritage"  -> "heritage"
                       otherwise ("oral")            -> strand1PastFirstLevel ? "heritage" : "new"
strand1PastFirstLevel = the placement has a strand "1", and every skill in its levels[0].assumes is in LanguageCourse.assumed
```

* Data: a skill field `readerAs`, either `"oral"` (the default) or `"heritage"`. The generator writes it from the unit's `routes.reader.as`. The teachers' files change `"as": "new"` to `"as": "oral"` in units 01 to 15 (russian-language-teacher, or the developer with the teacher's OK), and units 16 to 20 keep `"heritage"`. After that the generator refuses `"new"` there. The validator allows `readerAs` only in `rus`.
* Before strand 1 has stopped, and in a pack with no placement, a reader is served `new`.
* *As built:* `content/served_route.dart` (`servedRoute`, `strandOnePastFirstLevel`); a first level that assumes nothing is never "past". The served route is used by `PackContent.itemsFor` and by the say step (R4), and nowhere else. The stress marks, the caption after the answer (`caption_policy.dart`) and the letters gate (`routeBypass`) keep reading the parent's route itself.
* A lesson's skill is the skill of its first item (every Russian Band A lesson has one skill). A say step's skill is its activity's first skill. Revisit lessons (`courseMission`) have no screens and are not affected.

**R2. Teach sets get a mode.** `lesson.teach[]` becomes `{"items": [...], "routes": [...], "mode": "teach" | "hear"}`, with `mode` defaulting to `teach`.

* A `teach` set holds teach screens (`tcNN`, echo, as built). Its `routes` may name only `new` (`reader` is no longer a value: R1 resolves a reader before the lesson is built).
* A `hear` set holds hearing screens (`thNN`, R3). Its `routes` may name only `heritage`.
* The rule "a heritage speaker is never shown a teach screen" stays, in the schema, the generator and `itemsFor`. A hearing screen is not a teach screen.
* `itemsFor(lesson, route: served)` gives the screens of every set whose `routes` holds the served route, then the lesson's items.
* Authoring: the unit's `routes.heritage` says `"hear": true` (RUS-A-20 only; it replaced `"teach": false`, which a heritage record no longer needs). The generator then makes one hearing screen per teach word. *As built:* every lesson entry is written with its `mode`. **Each one goes before the first lesson whose prompts ask its word**, not all before the first lesson: лук, люк, мышка and мишка before `pairs-1`; рысь and рис before `pairs-2`. In A-20 that is 6 screens.

**R3. The hearing screen.**

* Id: `<course>.<skill>.thNN` (the number of the teach screen of the same word).
* Template `say_it`, with `answer` set to `{"type": "say_it", "scored": false, "teach": true, "hear": true}`. The scene is the word's teach picture (`teachPictures`).
* Prompt: the new line `defaults.hear.frame`, then the word clip. The line is `f41`: `{"he": "הַקְשִׁיבוּ:", "voice": "הקשיבו:", "review": "needs-editor"}`, a draft for the hebrew-text-editor, then one clip for the voice-and-sound-director.
* What it does: the line and the word play once. There is no microphone, no "I said it" and no second hearing after the pause. The replay button plays the word again, as often as the child likes. The picture goes on once the word has finished playing. Like a teach screen it writes nothing, is not an item of any lesson, and is not in the engine's catalogue. *As built:* the word is not shown as text (a hearing is by ear); the picture appears when `untilQuiet` says the voice has ended (after 8 s at the latest, so a voice that never ends cannot hold the child); a touch on the picture goes on after 0.4 s with no praise, because the praise names the word and the word is to be heard once.
* Validator: `hear` is allowed only with `teach: true`, only in `rus`, and only in a `hear` set.

**R4. The say step's order.** Every `say_it` activity that is not a teach or hearing screen gets two more fields:

```json
"say": { "...": "as now",
         "order": {"new": "echo", "heritage": "picture"},
         "pictureFirst": {"vo": "vo:rus.f06", "caption": [{"t": "he", "v": "מַה זֶּה? נַסּוּ לְהַגִּיד בְּרוּסִית."}]} }
```

* **The echo prompt becomes the `together` line (f03) and the word**, as on a teach screen. Today all 28 of these steps open with f06 and the word, which asks the child to try and gives the answer in the same breath.
* Generator: the course default is `defaults.sayOrder = {"new": "echo", "heritage": "picture"}`. A unit may override it with `routes.<route>.say`, `"echo"` or `"picture"`. **RUS-A-15 sets `new` to `picture`**, so all of A-15 is picture first for every child. The teachers' strings "picture first" in A-01 and A-14 become `"picture"`. `pictureFirst` is f06 by default, and f07 ("מָה עוֹנִים לֶחָבֵר?") for a say step that is the `then` of a puppet bubble (A-01 04s and 05s, A-14 10s and 11s). An item may name its own line.
* Player: the order is echo while the visit's quiet fallback is on. Otherwise it is `say.order[served]`, or echo when that is missing. *As built:* `LessonController` decides when the step begins (`pictureFirst`) and says the question alone; the course default carries `defaults.pictureFirst` (f06) and `defaults.afterBubble` (f07); only a course with `defaults.sayOrder` (Russian) writes the fields, and the validator allows them only there.
* **Picture first:**
  1. The `pictureFirst` line plays alone, with no target clip.
  2. The microphone (when on) and the "I said it" button are there from the start.
  3. After `SayItSession.pause` the voice says the word, unless the child has already been heard (the heard line says the word itself). *As built:* the pause starts when the question has ended (the question takes about 3 s and the pause is the child's), the word's chip shows as the word is said, and "I said it" does not stop the word: the child who tapped it has still not heard it.
  4. From then on the step is the echo step as built: the child may say it, and the picture goes on.
* **Echo** stays as built. Teach screens are always echo. Evidence is the same in both orders.

**R5. The invariant (no code; a test holds it).** A route adds screens before a lesson's items (from L7, 2026-11-12: before or between them, at a set's `before` item) and sets the order of a say step. It never removes, adds or reorders a lesson's items. So every lesson has the same items for every route, the path, its stones, "what is next" and the finished counts do not depend on the route, and Band A needs no route-aware path. The unit fields `from`, `order`, `weight`, `embodied` and the pacing notes of A-16 to A-19 stay as the teachers' notes. The generator reads them as notes, and the teacher may fold them into `note` at the next edit. Building one of them later (the first candidate is the A-16 heritage skip of the listen-first readings) means an exception to this invariant and its own guard.

**R6. Guards (built: `app/test/lesson_routes_test.dart` for 1 to 4, `app/test/route_screens_test.dart` for 5 and the screens; 6 waits for LS03 1.1 boxes).**
1. For every lesson of the Russian pack and each served route, `itemsFor` is that route's screens followed by `itemsOf(lesson)` (from L7: the screens at their `before` items, and the lesson's items in their order when the screens are taken out; the guard follows in step L7-4). The `itemsOf` part is the same for both routes, and it is never empty.
2. A heritage child gets no `teach` screen anywhere, and gets hearing screens only before `pairs-1` (4) and `pairs-2` (2).
3. `servedRoute` table: a reader with strand 1 not stopped, stopped at its first level, or past it, crossed with an `oral` skill (A-03) and a `heritage` skill (A-17).
4. No say step's echo prompt is f06. No `pictureFirst` has a target clip. A-15 is `picture` for both routes. A-01 and A-14 are `echo` for `new` and `picture` for `heritage`. The quiet fallback turns picture first into echo.
5. A hearing screen writes nothing, has no microphone, and plays the word once unless the child replays it.
6. When LS03 1.1 boxes is built: a count named by an exact `classify` key is tagged with it at any distance, and any other count off by two or more writes nothing (the note, §3).

### 2.7 Print direction (Hebrew A-12, `story` 1.1 modes `zones` and `follow`)

One page of a story that **shows its text** (`scene.pages[0].lines`: lines of words, set in Heebo at 34, one sentence to a line, right-aligned) under its picture. Nothing is drawn on the page at rest: the zones are places of the print, not buttons.

* **zones** ("where do we start reading?"): the touch places are the right end (`line1-start`, the right answer) and the left end of a line, and the picture; each wrong place carries its tag (`order`, `print_picture`). A zone is a third of the line, never narrower than a control.
* **follow**: the voice reads one word and waits for a touch on it, then the next, right to left. A right touch on a word on the way is a step (nothing is written); the last right touch is the answer the lesson scores. A touch on another word is `order` and on the picture `print_picture`; the due word is read again, and the reading does not move on.
* Hints: level 1 the reading arrow over the first line, from its start to its end; level 2 the page is read while a finger moves under its words from the right to the left (a `follow` page lights each word as it is read); level 3 the finger rests on the place to touch.
* The clip of each word of a `follow` page is **cut from the clip of the page by its timing** (`vo:heb.heb_a_s1_p5_w1` ...), so none is voiced of its own: `voice-plan.json` lists them under `cutClips`, apart from `targetClips`, with the clip they come from. The voice-and-sound-director cuts them when the page is recorded.

### 2.8 A font for one item

`font: "display"` on an activity (any template) sets the item's Hebrew course text in Secular One (A-10.6 and A-11.4, the transfer check of the same letters and names in the display face). The schema has the field, the validator refuses it outside the Hebrew course, `Activity.displayFont` reads it, and the lesson screen puts a `DisplayFontScope` round the activity, which `CourseText` reads (Secular One has one weight, so a bold request is a plain one).

### 2.9 Listen and do: nothing on the picture at rest (owner's phone test, 2026-11-07)

The hotspots of LS11 were drawn as a translucent outline at rest, and the face zone made Mika's face look like a mask. **Now nothing is drawn on a part at rest**; a hint's light, the child's choice, or the help at its top draws a ring (an outline, never a fill) on it, so a face is never covered. The L4 spec said "glowing parts"; this changes it by the owner's observation. The places of a `place` item and the target of a `drag` are drop places and keep their faint glow.

## 3. The pilot (proved end to end)

One skill with one lesson per course, taken from the teachers' batches with the approved pictures; every clip is pending (`voPending`; the voice plans list them).

| Course | Skill | Lesson | Items | From |
|---|---|---|---|---|
| English | ENG-A-01 greetings | `eng.greet-1` (5 items) | i01 to i06 (i03 and i06 are checks) | `english/band-a-content.md` §4 |
| Hebrew | HEB-A-02 new words from stories | `heb.words-1` (4 items) | the four words of story 2 and story 1 (bush, flour, bowl, oven), with their word cards for hint 2 | `hebrew/band-a-content.md` §4, §5 |
| Russian | RUS-A-01 greetings | `rus.greet-1` (3 items) | 01 to 03 (03 is a check) | `russian/band-a-content.md` §4 |

The Hebrew parent texts of the English and Hebrew tags (`parentText`) are the developer's drafts (the batches leave them to the content batch); they are `needs-editor` like everything else.

## 4. How a course pack is built, signed and bundled

**Build (anyone).** From the repository root, then `app/`:

```
python tools/lang_pack.py all            # the pack sources, from the teachers' files
cd app
dart run tool/pack_builder.dart build-language all --key <a key file> --out <a folder>
```

`build-language <eng|heb|rus|all>` builds the pack of the course from `content/languages/<course>/pack` with the same builder and validator as the starter pack (the validator runs all of frame §1.5 and the F5 checks; a problem stops the build before anything is signed), checks the id is `lang-<course>`, writes `lang-<course>-<version>.nnpack` to `--out` (default `assets/packs`, the app's bundle) and removes an older version of that course from the folder. Tests sign with a throw-away key.

**Sign (the owner only; his key never leaves his PC).** In PowerShell, at `D:\nitznutz-languages-band-a\app` (or his checkout's `app` folder) after the team has merged the sources and raised `pack.version` in each `course.json`:

```powershell
python ..\tools\lang_pack.py all --check
if ($?) { dart run tool/pack_builder.dart build-language all }
dart run tool/pack_builder.dart verify assets/packs/lang-eng-0.1.0.nnpack
dart run tool/pack_builder.dart verify assets/packs/lang-heb-0.1.0.nnpack
dart run tool/pack_builder.dart verify assets/packs/lang-rus-0.1.0.nnpack
```

The key is read from `%USERPROFILE%\nitznutz-secrets\pack-signing.key`, the same file as for the starter pack; the first command stops if the committed sources are not what the teachers' files give; the three `verify` lines check each file against the public key inside the app (they print `OK`). The three `.nnpack` files in `app\assets\packs` are then committed by the orchestrator. **Nothing is published to the server**: `content-publish` refuses a language pack by design (L0 SEC-L0-4), and the packs are in the app. (Replace `0.1.0` by the version in `course.json`.)

**Why the version matters.** The installer never changes the contents of an installed version, and the app does not re-install a bundled pack whose version is not newer than the installed one. So every signed pack needs a new `pack.version`; a test (`language_packs_build_test.dart`, "the packs bundled in the app") fails if a bundled pack's version is not the version of its sources or its files differ from them.

**How the app bundles and loads them** (`content/bundled_packs.dart`, `content/content_repository.dart` `languagePacks`, `app/language_providers.dart`):

* `assets/packs/lang-<course>-<version>.nnpack` is in the bundle (the whole folder is an asset already; the starter pack is untouched and still loaded as before). The app finds them by **file name** only (the newest per course) and trusts nothing in the name: the file goes through the verifying installer (signature first, every hash, then the content rules) like any pack.
* **A family that has turned no language on installs and reads nothing**: the pack of a language is installed the first time some child has it on (`FamilyLanguages.coursesOn`), unless the phone already holds that version or a newer one (an update that arrived first). The door still needs the language **on for the child and its pack installed** (frame §1.1, L0 §11); nothing in the other lands changes.
* Every installed language pack is read back and proven again at each start (as before). An installed copy that no longer proves itself is put right from the bundle once; a pack that still does not prove itself, or a bundled file the installer refuses, leaves **only that course** out. Switching any other setting of a language does not read the packs again; only a change in which languages are on does.
* Cost: a pack is read whole into memory when its language is on (the open issue "packs are read whole"; the pilot packs are 36 to 60 KB). The full Band A packs with pictures are expected to be about 0.5 to 1.5 MB each; the lazy read is the next step if a phone measurement shows a delay.

## 5. The tests

| Test | What it proves |
|---|---|
| `tools/test_lang_pack.py` (116 with the next row) | the committed pack sources and voice plans are exactly what the course files give (twice over, on a copy); the derived fields; 40 rules the generator checks before the builder (lines, clips, pictures, tags, options, ladders, ids, lessons, placement, versions); the §1.5 invariants in the written files (one course, tutor off, every distractor tagged, `needs-editor`) |
| `app/test/language_packs_build_test.dart` | each course's source through the **real** pack builder and validator (F5 and §1.5), signed, verified, read as the app reads a pack: no warnings, one course through and through, the tutor off, every line pending and planned, shared pictures; a broken copy is refused (cross-course prerequisite, tutor on, untagged distractor, wrong course, foreign tag, wrong id, missing picture); the bundled-pack guard (skipped until the owner signs the packs) |
| `app/test/bundled_language_packs_test.dart` | file-name discovery; nothing installed for a family with no language on; installed once; not over a newer copy; repaired when damaged; a stranger's signature leaves only that course out; a wrong name cannot stand for another course; the provider installs on turning a language on and does not read again for another switch |
| `app/test/language_band_a_templates_test.dart` | one sample of every kind of activity of the real packs (a tap with a stage, sound buttons, a tap-all, the six modes of listen and do, a puppet's bubble and personal turn, say it, a chant, the drum, a story heard and one that asks, a count, pairs, a sort, a story line, the pre-writing path) opens on the lesson screen on the phone and the tablet; `NN_SHOTS=<folder>` writes a picture of each |
| `app/test/second_target_clip_test.dart` | a line with two target clips, and a misconception that lists up to 60 skills |
| `app/test/lesson_routes_test.dart` (38) | what a route plays (a new learner is shown the teach screens first, a heritage speaker never, in no lesson, and hears the six words of A-20 once before the lesson that asks them), R5 and R6.1 for every lesson and each served route, `servedRoute` by strand 1 and by the skill (R6.3), the 117 teach screens and 6 hearing screens (unscored, no attempt, not an item, not in the engine), the order of the 28 say steps (R6.4), the controller (picture first, the quiet fallback, the route of the step's own skill, a hearing screen), a dozen broken sources refused |
| `app/test/route_screens_test.dart` (16) | on the lesson screen with the real pack and fake clips: the hearing screen (no microphone, no "I said it", the picture after the word, the replay says it again, nothing written), the say step picture first (the question alone, the pause after it, the word and its chip, "I said it"), echo for a new learner and an unmoved reader, the rooms of RUS-A-13 and the heart and flower of A-10 on the phone and the tablet; `NN_SHOTS=<folder>` writes a picture of each |
| `app/test/own_name_test.dart` (19) | the name as it is printed, the rules NAME-FIRST and NAME-LENGTH and the look-alike row, every name of the list as a child's name, the fallbacks, the pack holds no name, the name never leaves the phone, the screen on the phone and the tablet |
| `app/test/read_page_test.dart` (14) | the zones and follow items of the pack, nothing drawn at rest, the zones on the right and left of the print, the tags, the hints, the reading of a page word by word; `NN_SHOTS=<folder>` writes a picture of each state |
| `app/test/display_font_test.dart` (5) | Heebo and Secular One by scope, the two items that ask for it, another course refuses it |
| `tools/test_lang_pack_more.py` (run by `test_lang_pack.py`) | the teach screens and routes (10), the routes of 2.6.1 (13: `readerAs`, the hearing screens and the lessons they go before, the say order and its overrides, the invariant), the own-name items, the print-direction items, the font |
| `app/test/language_pilot_test.dart` | the **playthrough**: for each course, door, course home, the placement visit (a wrong touch at each probe, so that the first lesson stays next), first lesson to the celebration, back home, with every answer written as a row of the course (pack `lang-<course>`, ids only); a wrong touch is the diagnosed error of its distractor; goldens of the first activity on the phone and the tablet (`app/test/goldens/pilot_<course>_first_<board>.png`) |

| `tools/test_lang_band_a_rules.py` (run by `test_lang_pack.py`, 25) | the QA decisions in the generator: no chip in Band A, reverse items and their ladder, no check in a lesson without `inLesson`, picture bins, and the same on the committed packs |
| `app/test/engine/check_visit_test.dart` (25), `app/test/check_visit_world_test.dart` (16) | the check visit: readiness, items, a failed check, two failed visits, pairs; where it stands in the course stop and in Today's Adventure |
| `app/test/language_band_a_rules_test.dart` | no chip in a built Band A pack, HEB-A-14 (met after 05 to 08, never fresh), what the engine does not know of a course |
| `app/test/qa_band_a_mastery_test.dart` | QA's proofs: every skill can be fresh, and a child who follows the course stop reaches fresh mastery of every skill in 19, 27 and 36 days |
| `app/test/count_tall_stage_test.dart`, `bin_geometry_test.dart`, `read_page_test.dart` | the layouts of `docs/design/languages-band-a-qa.md` sections 3, 4.2 and 5.2 |
| `app/test/qa_band_a_shots_test.dart`, `qa_band_a_sizes_test.dart` | QA's diagnostics (pictures and sizes of every kind on four boards): a half-hour run, so they run only with `NN_SHOTS=<folder>` or `NN_QA_VISUAL=1`; the suite keeps the quick guard that no sample is a teach or hearing screen |

CI: add `python3 -I -X utf8 tools/test_lang_pack.py` next to `tools/test_generators.py` in `.github/workflows/ci.yml` (infrastructure-engineer).

## 6. For the teachers, in order

1. Copy the pilot's unit file of your course, keep the first skill, and add the skills of your `band-a-content.md` in the order of the path (`01-`, `02-`…). The item tables map one to one: the item's frame line, clip, options, right answer, distractor tags, ladder.
2. Add the lines you use to `course.json` `lines` (the Hebrew of your §2, with its `voice` text) and the tags (your §3) to `tags`.
3. Run `python tools/lang_pack.py <course>`; fix what it says; run the Dart tests of §5 (the pack builder runs the real validator).
4. Items whose template has no recipe yet: write them as `raw`, or tell the app-developer which template comes next.
5. A picture that is missing is the design-director's to draw (the generator names it).

## 7. QA decisions 2026-11-07

Decided by the curriculum-expert on the qa-engineer's report on Languages Band A (proof tests `app/test/qa_band_a_mastery_test.dart`, `qa_band_a_shots_test.dart`, `qa_band_a_sizes_test.dart`, untracked). **Nothing here changes the syllabus**: no skill is added, removed, split, merged or reordered, no band changes, and the mastery rule of curriculum §10.2 stays as it is. Items are added and re-marked inside existing skills. New Hebrew is `"review": "needs-editor"`; new English and Russian rows are drafts for their teachers, who may change a word or a distractor as long as they keep the rule the row serves. **R** = needed before the packs are signed for the family; **L** = later.

### 7.1 Summary

| # | QA point | Decision | Reason in one line | Who | Pri. |
|---|---|---|---|---|---|
| D1 | QA-BA-1 | No target-language text in any Band A item: no chip anywhere | Band A presentation has no reading; letters come after the oral gate (eng) and the letters gate (rus), and in Hebrew only in A-10 to A-12 | app-developer | R |
| D2 | QA-BA-2 | The rule stays (a core skill needs 2 check **types**). The 8 skills get **reverse** checks, and the 4 with one representation get a second one | curriculum §5.6 and frame §3.3 give no language exception; the two directions of a word are two kinds of knowing | teachers | R |
| D3 | QA-BA-3 | A **check visit**: an engine-planned short mission, on a later day, for a skill whose lessons are done and that is not fresh yet | Fresh mastery needs a check and a second day, and nothing in a course gives either today | app-developer | R |
| D4 | QA-BA-4 | HEB-A-14 gets `writing: practised`, and the engine counts a start-dot trace (T04) as practised | rule E-1 (a trace node is met once practised); today it can never be met | Hebrew teacher, app-developer | R |
| D5 | QA-BA-7 | Picture signs on the bins of HEB-A-05 **and HEB-A-10** (A-10 has the same fault) | a pre-reader cannot read אֶחָד or אוֹתִיּוֹת; the bin still says its word on a touch | design-director, Hebrew teacher | R |
| D6 | QA-BA-8 | Two new A-16 probes (a balanced yes / no pair) in level 4 | the plan's level assumes A-16, and a learn item is never a probe | English teacher | R |
| D7 | Counts | All confirmed; one Hebrew lesson of 8 items is split | the extra items are unscored say steps and chants, probes or spare checks, with no new words | Hebrew teacher | L |
| D8 | homeActivity | Needed: 31 Hebrew drafts | curriculum §5 and frame §4.1 give every tag a home activity, and English and Russian have them | Hebrew teacher, hebrew-text-editor | R |
| D9 | (found in this review) | Fix 6 kinds of wrong content and 7 smaller faults (7.9) | some checks can be passed without the language, or ask a word that was never taught | teachers, design-director, app-developer | R / L |

**Coverage now** (pack, without teach screens):

| Course | Skills | Items | Learn | Practice | Checks | Probes | Lessons |
|---|---|---|---|---|---|---|---|
| English | 17 | 194 | 120 | 26 | 38 | 10 | 40 |
| Hebrew | 14 | 157 | 98 | 17 | 30 | 12 | 31 |
| Russian | 20 | 340 (+ 123 teach or hearing screens) | 235 | 40 | 44 | 21 | 66 |

Core skills: ENG A-01, A-03, A-05; RUS A-01, A-04, A-12, A-15, A-20; Hebrew has none.

**After 7.2 to 7.9:** English has 17 more items, Russian 13 more, and Hebrew none (field changes only). Every skill can then reach fresh mastery through its lessons and check visits. HEB-A-14 is met when practised and never becomes fresh, by design.

### 7.2 D1 (QA-BA-1): no target text in Band A

**Rule.** An activity of a Band A skill never prints a target-language word, chunk or letter: no `show` on a prompt, say step, teach screen, hearing screen, hint or feedback step.
- **Exceptions:** Hebrew A-10 to A-12, whose content *is* letters, the child's name and print. They stay as authored now; none of them uses `show`.
- **Kept:** the Russian reader's caption after the answer (`caption_policy.dart`). It is the one place a Band A word may still appear, and it already requires Band B or C presentation and the reader route.
- **Amended 2026-11-12 (L7, C1 of `docs/design/l7-meet-find.md` §3.2): the Meet screen.** A Meet screen (frame §2.3, LS09 teach mode) of any skill, Band A included, may show its word as a chip **only** to a child whose letters gate for that course is open (by level, by age or by "letters together with words"), and only as that spec says: never with look A, never on the picture, never before the word and its meaning have been heard (from M3; Hebrew from H3), and only when captions are shown. Every other Band A screen keeps this rule. Why: both reasons below fall away once the gate is open; the print no longer runs ahead of the gate, and a child with letters can use a new word's spelling to remember it (Rosenthal and Ehri 2008). The chip still never comes first, so the word stays a thing heard.
- **No parent switch is added.** None exists, Band A has no reading, and a child who reads gets Band B or C presentation.
- **Band B:** whether an item shows a chip is decided with the Band B packs. It is authored per item and is never a default.

**Reason.**
- The frame and the curriculum forbid it: frame §3.1 and curriculum §10.9 (no reading under Band A presentation; letters only in Hebrew A-10 to A-12); `fonts.md` §6 ("prompts never print the target word"); D17 (no Russian letters before age 5); the English oral gate.
- The evidence: seeing a word's spelling helps a child learn it only when the child can decode the script (orthographic facilitation, Rosenthal & Ehri 2008), and pre-readers barely look at the print on a page at all (Evans & Saint-Aubin 2005, eye tracking).
- So the chip gives a 3-year-old nothing, and it puts Latin and Cyrillic print ahead of the gates that hold it back.

**Changes (app-developer).**
1. `tools/lang_recipes_talk.py` `recipe_say` (line 86): `show` defaults to false for every say step, teach screen and hearing screen. Drop the default that shows a single word.
2. The generator refuses `show: true` on an item, a `then`, a feedback step or a ladder step of any skill whose band is A, and says so plainly in its problem list.
3. The picture-first say step (2.6.1 R4 step 3) then shows no chip. Nothing else in the player changes.
4. Regenerate the three packs. Expected: no activity with a chip in any course (0 of 194 English, 0 of 157 Hebrew, 0 of 463 Russian; today 8, 8 and 142).
5. Tests that expect the chip are changed to expect none (`route_screens_test.dart` "the word and its chip", and any other the developer finds).

### 7.3 D2 (QA-BA-2): the second check type and the second representation

**The rule stays.** Curriculum §5.6 says a core skill (a prerequisite of 3 or more skills, or marked ●) needs two **different** checks. The engine reads this as two check types, which is right. Frame §3.3 says curriculum §10.2 applies to the courses unchanged, so there is no ground for a language exception.

**The second type is `reverse` (U4) for all eight skills.**
- **Forward items** play the word, and the child finds its picture (from the form to the meaning).
- **A reverse item** shows the picture, and the child finds its word among three heard words (from the meaning to the form).
- **Why reverse:**
  - The two directions are two different strengths of knowing a word, and finding the form for a meaning is the harder one (Laufer & Goldstein 2004). That study was of older learners, so for 3- and 4-year-olds the evidence is thin.
  - Choosing among sound buttons is already Band A practice in both courses: the scored "how many?" step of ENG-A-04 and RUS-A-10.
  - For the two speaking skills (ENG-A-12, RUS-A-15), a reverse item is also the nearest tap-only stand-in for naming, since speech is never a check (frame §5.1).

**The reverse item (one format for both courses).**
- Kind `tap`:
  - `stage`: the picture;
  - `options`: three sound buttons `{"clip": …}`, the right one first;
  - `wrong`: a tag on each wrong button;
  - `purpose: "check"`, `check: "reverse"`;
  - `hintWord`: the right clip (praise and the level-3 hint name it).
- Frame: "which word fits the picture?". Russian uses `f38`, which is `text-ready`. English gets the new line `he-ins-which-word`: the same Hebrew, as a clip in the English voice.
- Ladder `HL-REV`, new in both `course.json` files, so that **no hint before level 3 says the right word**:
  1. `{"line": "he-hint-again" (rus "f02"), "action": "highlight_objects_sequentially"}`: the three buttons light and play in turn, slowly.
  2. `{"line": "@gloss", "orLine": "he-hint-again" (rus "f02"), "action": "replay_prompt_slow"}`: the picture's Hebrew name (the meaning in the first language: a new representation), then the buttons again.
  3. `{"line": "he-hint-showme", "action": "worked_example", "target": "@target"}`: the right button plays and lights, and the child touches it.
- Feedback: `{"wrong": "he-fb-check", "byTag": {each tag of the item: "he-fb-check"}}`. A first error then names no option (the course's byTag lines may name the target).
- Never red and green in one colour item; the stage counts as one of the colours.
- In no lesson: the item is served by the check visit (7.4).

**Per skill.**

| Skill | Second check type (new or re-marked items) | Second representation | Lessons |
|---|---|---|---|
| ENG-A-01 | i10, i11 reverse | already has 2 (story and pictorial) | greet-1 becomes `[i01, i02, i09, i04, i05]`: the check i03 leaves, and the new learn item i09 teaches "Hi" |
| ENG-A-03 | i11, i12 reverse | embodied: i09, i10 (LS11 drag) | col-2 becomes `[i05, i06, i09, i10]` |
| ENG-A-05 | i13, i14 reverse; i11, i12 transfer (drag) | embodied: i09, i10 (LS11 drag) | new lesson `ani-3` `[i09, i10, m01, m02]` |
| RUS-A-01 | 09, 10 reverse | already has 3 | greet-1 becomes `[01, 02, 11]`; greetings-more gains 07 |
| RUS-A-04 | 14, 15 reverse | already has 2 | none |
| RUS-A-12 | 04 re-marked `check: "reverse"` (it already goes from the picture to the answer) | story: 01, 02, 03 become LS10 bubbles | none |
| RUS-A-15 | 27, 28 reverse; 25, 26 transfer (find in a room) | already has 2 | none (07t, 12t, 21t become learn items) |
| RUS-A-20 | 21, 22 reverse | embodied: 23, 24 (LS11 find in the room) | pairs-2 becomes `[05, 06, 17, 23, 24]` |

**Why these representations.**
- **ENG-A-03 and A-05:** the drag to Pip that ENG-A-08 already uses. It is acting on the thing named, the course's TPR mode (syllabus [Asher69]). The things to drag exist. The drop scene is new: `pip-basket`, Pip whole beside an open toy basket, with the drop target on the basket. A balloon or a cow does not belong in the food bowl of `pip-feed`, and `pip-happy` is a bust whose face would be the target (the design-director's note of batch 7).
- **RUS-A-12:** its question-and-answer items are a dialogue, which is what LS10 is for (frame §3.3.1: story means inside a dialogue).
- **RUS-A-20:** the room `scene-room-mouse` already holds a teddy (мишка), a mouse (мышка) and a cat, so the contrast is heard in a new place. A room item keeps the recipe's `embodied`, as the rooms of RUS-A-13 do.

The exact rows are in 7.10 (English) and 7.12 (Russian).

### 7.4 D3 (QA-BA-3): the check visit

**What is wrong.**
- A course is played as lessons in a fixed order, and the checks are in no lesson.
- The revisit mission (`courseMission`, `Engine.dueChecks`) is offered only for a skill that is already fresh, and fresh needs a passed check.
- A child who finishes a skill's lessons on one day has all its successes on that one day, and fresh needs two days.
- So no Band A skill can become fresh, whatever the child does. In QA's test a perfect child reaches 2 of 17 English skills, 0 of 14 Hebrew and 1 of 20 Russian.

**Decision: an engine-planned check visit**, a short mission of one skill on a later day.
- It is the course's form of what the session builder already does in the lands, where a learning skill's checks are served in the focus part of a session.
- It keeps the checks off the day the skill was taught, so a check is retrieval after a delay, not an echo of the lesson (spacing and retrieval practice: Cepeda et al. 2006; Karpicke & Roediger 2008).
- It is not a test and is never called one. To the child it is a visit, like a revisit.

**C-1. When a skill is ready for a check visit.** All of these hold:
1. the skill is started and not fresh, and it is not a `writing: practised` node;
2. every lesson of the course path that teaches it (`lesson.skillIds`) has been finished at least once, **or** placement assumed it and it has not been verified yet (frame §3.2: an assumed skill is verified by retrieval within 2 weeks);
3. no item of the skill was answered today (its last lesson or check visit was on an earlier day);
4. something of its fresh evidence is missing: a check type, a representation, a word of its set, successes, the second day, or the estimate.

**C-2. Where it comes in the course stop** (`courseStopFor`, the course home's pebble, `startCourseVisit`):
1. the placement visit, when it is due (as today);
2. a due revisit of a fresh skill (as today; at most one a day);
3. **a check visit**: at most one a day per course. The skill whose last lesson was finished longest ago comes first, then the path order;
4. the next lesson on the path.

**How it fits in:**
- At most one mission (a revisit or a check visit) opens a visit. After it, the course home offers the next lesson, as after a revisit today.
- Nothing is locked: the child can still touch any stone.
- **Today's Adventure:** a check visit takes the revisit slot of the rule (frame §3.7: "a revisit first once a day"). That changes `todays-adventure-rule.md`, and frame §3.7 says such a change needs the owner's OK, so **the orchestrator asks the owner**. Inside the course home no owner decision is needed: it is an engine rule.

**C-3. What it holds.** Three to five items under Band A presentation (5 to 8 for Band B, up to 12 for Band C; frame §3.1). All are of the one skill, since checks are not interleaved in Band A (frame §3.5). The order:
1. **a warm-up**: an easy learn item of the skill that was already answered right (the highest chance of success), never a check;
2. **the checks**: one `purpose: check` item for each check type the skill still lacks (2 types for a core skill, 1 otherwise):
   - prefer a word not answered in the skill's last visit, and a representation not passed yet;
   - a balanced pair (`pairWith`) is one check, served as its two items one after the other;
   - never a check marked `inLesson`;
3. **coverage**: a learn item for each word of the set not yet answered right without a hint, while there is room;
4. **a missing representation** (core skills): one learn item in it, if steps 2 and 3 did not bring one;
5. **an ending on a success**: if the last answer was wrong, an easy item of the skill (curriculum §10.3).

A skill that lacks only days, successes or the estimate gets the warm-up, one check (a different item of a type it has already passed), and up to three learn items.

**C-4. After a failed check.**
- The check type stays missing. Nothing is shown to the child as a failure, and the parent page says "learning".
- The next check visit (on a later day) opens with a learn item in another representation than the failed check's (curriculum §5.5: re-teach by changing the representation), then a different item of the same check type.
- After two check visits in a row with a failed check, the course stop offers the skill's last lesson again before the next check visit.

**C-5. Balanced pairs.** Frame §2.3 requires them, and the validator holds them, but **the engine does not**: `pairWith` appears nowhere in `engine/`. Today ENG-A-16 i05 and i06 each count as a check on their own, at a chance of 1 in 2.
- The engine credits a paired check's type only when both items of the pair are right, at hint level 0, in the same visit.
- One half right alone is an ordinary success, not a check.

**C-6. Checks and lessons.** The generator refuses a `purpose: check` item in a lesson unless the item says `"inLesson": true`.
- `inLesson` is for a question about the story or chant just heard, which makes no sense without it (RUS-A-16 06 and 09).
- Such a check is a new text each time, a transfer by design, and a check visit never serves it alone.

**Changes (app-developer).**
1. The check visit, beside `courseMission` (for example `checkVisit(course, skillId)`). Its items are chosen by a pure function of the engine, as `missionItemIds` is.
2. Its place in `courseStopFor` and `startCourseVisit` (C-2).
3. C-5 in the engine: `ItemMeta` gains the partner's id.
4. C-6 in `tools/lang_pack.py`.
5. `Engine.dueChecks` stays as it is (fresh skills only).

### 7.5 D4 (QA-BA-4): HEB-A-14

**Decision.** HEB-A-14 is met once each of its four strokes (down, across, arch, circle) has been traced right once with the start dot only (items 05 to 08) at hint level 0 or 1, or when placement assumed it. It is never fresh, probed or checked (syllabus row A-14; `writing-mastery.md` §2.2; rule E-1).

**Why two changes are needed.**
1. The skill does not say `writing: practised`, so `Engine.isMet` treats it as an ordinary skill.
2. Even with the field, the skill would never be met:
   - `_practised` reads `practiceGroupsOf`, which holds only items with `startGuide`;
   - the adapter sets `startGuide` only for an LS02 `LetterWriteActivity`;
   - A-14's items are T04 `trace` items, so the set is empty.

In Band A nothing depends on A-14. In Band B `HEB-B-24.Sn` does, so without the fix the S1 letter bundle would wait for ever.

**Changes.**
- **Hebrew teacher**, `content/languages/heb/units/12-pre-writing-strokes.json`:
  - the skill gets `"writing": "practised"`;
  - item 09 (the door, a combined stroke) gets `"guide": "full"`. It is practice, not one of the four strokes the skill needs, and a full path suits a three-stroke figure at ages 3 to 4. If the teacher wants to keep its start dot, she says so, and the developer adds a "never required" flag instead.
- **app-developer:**
  - `content/engine_adapter.dart` sets `startGuide` for a T04 `trace` activity whose `scene.guide` is `"start"` (items 05 to 08), as it does for LS02;
  - if the validator refuses `writing: practised` on a skill with T04 items, it is changed to allow it.
- **Tests:** QA's test `heb: HEB-A-14 … is met once its strokes are traced` then passes. Add: the skill is not met after 01 to 04 alone, and it is never fresh.

### 7.6 D5 (QA-BA-7): picture signs on the bins

Both Hebrew sorts with bins print a word on each bin:
- HEB-A-05: `אֶחָד`, `הַרְבֵּה`;
- HEB-A-10, which was not in QA's list: `אוֹתִיּוֹת`, `דְּבָרִים אֲחֵרִים`. A-10's exception covers letters as things to sort, not words to read on a bin.

HEB-A-03 already does it the right way, with an example picture on each bin.

- **The design-director draws four signs:**
  - `sign-one`: one round dot;
  - `sign-many`: a loose cluster of 6 or 7 dots, not a dice pattern (so "many" is not a number), with the same dot size and colour as `sign-one`, so the single dot is never drawn bigger or brighter;
  - `sign-letters`: an open book page with lines of print too small to read;
  - `sign-other`: a box holding a ball, a crayon drawing and a block;
  - on all four: no readable letter or digit, the two signs of a pair equal in size and weight, and colour never the cue;
  - the first drafts of `sign-one` and `sign-many` (in the working tree on 2026-11-07: a plate with one orange ball, and a plate heaped with about 20) are a good idea, and they may replace the dots. But the single ball has radius 30 and the heaped ones 18, and the ball must be the same size on both plates, or the "one" plate reads as the bigger amount. A heap of 6 or 7 balls is enough for "many".
- **The Hebrew teacher:**
  - `units/11-one-and-many.json`, items 07 and 09: `{"id": "one", "label": "heb-a-bin-one", "picture": "sign-one"}` and `{"id": "many", "label": "heb-a-bin-many", "picture": "sign-many"}`;
  - `units/08-letters-or-not.json`, items s01, s02 and s06: `"picture": "sign-letters"` and `"sign-other"`;
  - the label clips stay: a bin says its word on a touch.
- **The app-developer:** a bin with a picture shows no text (as in A-03), and the generator refuses a Band A bin without a picture.

### 7.7 D6 (QA-BA-8) and D7 (counts)

**D6.** Level 4 of strand O becomes `{"items": ["a11.pr1", "a11.pr2", "a16.pr1", "a16.pr2"], "assumes": ["ENG-A-11", "ENG-A-16"]}` (a level holds at most 6 probes).
- `eng.a16.i04` is a learn item and stays one.
- The two new probes are a balanced yes / no pair (A-16 is binary by nature, frame §2.3), so the chance of guessing both right is 1 in 4.
- The rows are in 7.10.

**D7. The item counts above the plan are all confirmed.** The extra activities are unscored say steps or chants, probes, or spare checks (a delayed check needs another item), and none brings a word outside its skill's set:
- HEB-A-02: 18 scored items, as planned, plus 8 LS09 say steps;
- HEB-A-07: 2 extra checks;
- HEB-A-10: a first step of single 3-choice taps (one decision at a time, a sound Band A scaffold), and 5 probes;
- HEB-A-13: 1 extra check and 2 extra items;
- RUS-A-03 and A-04: 1 extra item each;
- RUS-A-17: 5 chants on top of 5 scored taps.

**One lesson is trimmed.** `heb.words-from-stories-more` (8 say steps) becomes two lessons, because Band A plays 3 to 5 items an activity (frame §3.1). Their titles are `needs-editor`.
- `say-1`: say-siach, say-kemach, say-keara, say-tanur;
- `say-2`: say-sira, say-kova, say-ruach, say-kadur.

**To split at the next edit (L):** these lessons have 6 or more scored items: `eng.beat-more` (8 drums), `rus.first-sound-more`, `rus.hard-soft-more1`, `rus.syllables-more1`, `rus.syllables-more2`, `rus.what-who-more1`.

### 7.8 D8: home activities for the Hebrew tags

**They are needed.**
- Curriculum §5 and frame §4.1 give every tag a parent text **and** a home activity.
- English has them for 6 of 6 tags and Russian for 12 of 12; Hebrew has 0 of 31, and the parent page should not look different by course.
- Several Hebrew parent texts already end with advice ("כְּדַאי לִמְחֹא כַּף…"). That advice moves into `homeActivity`, so the parent text says what was seen and the home activity says what to play.

**Rules for the 31 drafts** (in `content/languages/heb/course.json`, `tags.<slug>.homeActivity`, by the Hebrew teacher):
- one short game with things found at home, in 1 or 2 sentences, addressed to the parent in the plural (שַׂחֲקוּ, אִמְרוּ);
- no screen, nothing to buy, no test words, and no label for the child;
- one shared pattern for the 8 `shape_*` tags, with the two letters named;
- each marked `needs-editor`; the hebrew-text-editor makes them final.

### 7.9 D9: what this review found besides QA's points

**Wrong content** (most severe first):
1. **The two checks of ENG-A-05 (m01, m02) can be passed by sight.** The cat card matches the second cat picture with no English at all. They become learn items (7.10), and the skill's checks are the drag and reverse items.
2. **Some checks come straight after the voice says the word.** RUS-A-15 07t, 12t and 21t and ENG-A-12 i07t and i08t are the taps of a say step, in a lesson, right after the word was modelled (also in the picture-first order, R4 step 3). They measure echo, not knowing. They become learn items, and the skills get checks that stand alone (7.10, 7.12).
3. **RUS-A-04 07 checks a command the skill never teaches.** "возьми мяч" is not in the set (иди, беги, прыгай, хлопай, сядь, встань). See 7.12.
4. **Some set words are met for the first time in a check** (they have no learn item in any lesson):
   - English: A-01 Hi (fixed by i09), A-06 feet and tummy, A-07 grandpa;
   - Russian: A-01 до свидания (fixed by 11), A-02 девочка and семья, A-05 жираф and кит, A-06 the white and the black ball, A-11 десять.

   **The rule: a check may use a new picture of a taught word, never a new word.**
   - For each word, the teacher adds a learn item to a lesson, or shows where the word is taught (in another skill's lesson). A Russian teach set is not enough, because it serves only the new-learner route.
   - Known words in a new phrase (ENG-A-08 "Give me the bread") are a transfer and stay.
5. **RUS-A-01 07 can be passed by echo.** The neighbour says "До свидания", and the right bubble is the same words. It becomes a learn item; the skill's checks are 03 and the reverse items 09 and 10.
6. **A balanced pair counts as a check by one half** (C-5).

**Misleading pictures:**

7. The bins of HEB-A-10 print words (D5).
8. HEB-A-10 items 01 to 07 and p1 to p5 draw the shapes as text characters (● ▲ ○ △), against the decision of 2026-11-07 (section 2.4). The Hebrew teacher uses the pictures `shape-dot`, `shape-triangle`, `shape-ring` and `shape-triangle-open`, as t05 and s06 already do, and the design-director checks that they read as shapes at tile size.
9. In ENG-A-01 i07 and i08 (and RUS-A-01 04 to 06), the bubble pictures show the situation: a bubble shows Pip arriving on a scene where Pip leaves, so the answer can be found by looking. These are learn items, so this is minor (L). The fix is sound-only bubbles, or one neutral bubble picture for all; the teachers decide with the design-director.

**Weak hints:**

10. In RUS-A-12 01 to 04, hint level 2 repeats the instruction (f17), so the representation does not change. It should use `@gloss` of the right answer's word (L).
11. On the usual ladders, a reverse item would say its answer at level 1 (`@slow`). That is why `HL-REV` exists (7.3).

**Other:**

12. In ENG-A-03 and A-05, the second distractor is a same-set neighbour (the pig for the cat, the yellow balloon for the red one), but it is tagged `l1_guess`. By the syllabus (§8) it is `sem`: `l1_guess` is a familiar picture from **another** set. The English teacher re-tags them (L); the new items here already use `sem`.
13. **An observation for the orchestrator** (not decided here, since it touches every land): `EngineParams.freshRepresentations` is 1 for a non-core skill, while curriculum §4.1 (standard evidence, condition 3) and frame §3.3 require at least 2 representations for every skill. Today 18 Band A language skills have only one representation (14 after this section), and so do some maths skills. Changing the parameter or the curriculum is a separate decision with the app-developer.

### 7.10 English (english-language-teacher), `content/languages/eng/`

**`course.json`:**
- `lines` + `"he-ins-which-word": {"he": "אֵיזוֹ מִלָּה מַתְאִימָה לַתְּמוּנָה?", "voice": "איזו מילה מתאימה לתמונה?", "review": "needs-editor"}`
- `lines` + `"he-ins-give-it": {"he": "הַקְשִׁיבוּ, וְגִרְרוּ לְפִיפּ:", "voice": "הקשיבו, וגררו לפיפ:", "review": "needs-editor"}`. What it must make clear: hear the English word, then drag the picture it names to Pip.
- `ladders` + `HL-REV` (7.3).

**`units/01-greetings.json` (ENG-A-01):**
- \+ `{"id": "i09", "kind": "tap", "target": "en-hi", "options": ["pip-arrive", "pip-leave", "mika-eat"], "wrong": {"pip-leave": "sem", "mika-eat": "l1_guess"}}`
- \+ i10, reverse: `stage` `mika-arrive`; options `en-hi`, `en-goodbye`, `en-bye`; wrong `sem`, `sem`.
- \+ i11, reverse: `stage` `pip-leave`; options `en-goodbye`, `en-hello`, `en-hi`; wrong `sem`, `sem`.
- Lesson `greet-1`: `["i01", "i02", "i09", "i04", "i05"]`. i03 stays a check, out of the lesson.

**`units/03-colors.json` (ENG-A-03):**
- \+ i09: `{"kind": "listen_do", "mode": "drag", "frame": "he-ins-give-it", "rep": "embodied", "ladder": "HL-PIC", "picture": "pip-basket", "target": "en-red", "options": ["balloon-red", "balloon-blue", "balloon-yellow"], "wrong": {"balloon-blue": "sem", "balloon-yellow": "sem"}}`
- \+ i10: the same with `en-blue`; options `balloon-blue`, `balloon-yellow`, `balloon-green`.
- \+ i11, reverse: `stage` `balloon-yellow`; options `en-yellow`, `en-blue`, `en-red`.
- \+ i12, reverse: `stage` `boat-green`; options `en-green`, `en-blue`, `en-yellow` (no red with green).
- Lesson `col-2`: `["i05", "i06", "i09", "i10"]`.

**`units/05-animals.json` (ENG-A-05):**
- m01 and m02: `purpose` becomes `learn` (7.9 item 1).
- \+ i09, drag, `en-duck`: options `duck`, `bird`, `dog`; wrong `sem`, `sem` (as in A-03).
- \+ i10, drag, `en-cow`: options `cow`, `pig`, `fish`; wrong `sem`, `sem`.
- \+ i11, drag check (transfer, with the second poses), `en-bird`: options `bird-2`, `duck-2`, `cat-2`.
- \+ i12, drag check (transfer, with the second poses), `en-dog`: options `dog-2`, `cat-2`, `cow-2`.
- \+ i13, reverse: `stage` `cat-2`; options `en-cat`, `en-dog`, `en-pig`.
- \+ i14, reverse: `stage` `frog-2`; options `en-frog`, `en-fish`, `en-duck`.
- New lesson `ani-3` after `ani-2`: `["i09", "i10", "m01", "m02"]`; its title is `needs-editor`.

**`units/12-say-a-word.json` (ENG-A-12):**
- i07 and i08: `then.purpose` becomes `learn`.
- \+ i09, reverse: `stage` `apple`; options `en-apple`, `en-banana`, `en-bread`.
- \+ i10, reverse: `stage` `ball`; options `en-ball`, `en-drum`, `en-book`.

**`units/13-chants.json` (ENG-A-13):**
- i01, i02 and i04: `purpose` becomes `learn`.
- i03 and i05 stay checks (words met in a chant and asked by a picture on a later day: a transfer), and they leave lesson `chant-2`, which becomes `["c03", "c04", "i04", "c05"]`.

**`units/16-yes-no.json` (ENG-A-16), two probes:**
- \+ pr1: `{"kind": "tap", "purpose": "probe", "frame": "he-ins-thumbs", "target": "en-isit-dog", "stage": "dog", "options": ["thumb-up", "thumb-down"], "wrong": {"thumb-down": "yesno"}, "pole": "yes", "ladder": "HL-YN", "after": "en-yes"}`
- \+ pr2: the same with `target` `en-isit-cat`, `stage` `duck`; options `thumb-down`, `thumb-up`; wrong `{"thumb-up": "yesno"}`; `pole` `no`; `after` `en-no`.

**`placement.json`:** level 4 as in D6.

**Also:**
- 7.9 item 4: ENG-A-06 feet and tummy, ENG-A-07 grandpa.
- Later (L): 7.9 item 12 (tags), the split of `beat-more`, 7.9 item 9 (bubble pictures).
- Every clip above is already in `pronunciation.csv`, and every picture exists except `pip-basket` (the design-director's).

### 7.11 Hebrew (hebrew-language-teacher), `content/languages/heb/`

- `units/12-pre-writing-strokes.json`: D4.
- `units/11-one-and-many.json` items 07 and 09, and `units/08-letters-or-not.json` items s01, s02 and s06: D5.
- `units/08-letters-or-not.json` items 01 to 07 and p1 to p5 (A-10): the shape pictures (7.9 item 8).
- `units/01-words-from-stories.json`: split `words-from-stories-more` (D7).
- `course.json`: the 31 `homeActivity` drafts (D8).
- No new items. Hebrew has no core skill, so D2 does not apply; its checks reach the child through the check visit (D3).

### 7.12 Russian (russian-language-teacher), `content/languages/rus/`

Reverse items use frame `f38` and ladder `HL-REV`. Add `HL-REV` to `course.json` as in 7.3, with `f02` as the line of its first two steps.

**`units/01-greetings.json` (RUS-A-01):**
- \+ `{"id": "11", "kind": "tap", "frame": "f39", "target": "w-do-svidanija", "options": ["neighbour-leave", "neighbour-arrive", "mika-gift"], "wrong": {"neighbour-arrive": "sem", "mika-gift": "sem"}}`
- Lesson `greet-1`: `["01", "02", "11"]`. 03 stays a check, out of the lesson.
- 07: `purpose` becomes `learn`, and it is added to `greetings-more` (7.9 item 5).
- \+ 09, reverse: `stage` `neighbour-leave`; options `w-do-svidanija`, `w-privet`, `w-poka`; wrong `{"w-privet": "sem", "w-poka": "tyvy"}`.
- \+ 10, reverse: `stage` `mika-arrive`; options `w-privet`, `w-poka`, `w-do-svidanija`; wrong `sem`, `sem`.

**`units/04-commands.json` (RUS-A-04):**
- \+ 14, reverse: `stage` `act-jump`; options `w-prygaj`, `w-hlopaj`, `w-begi`; wrong `{"w-hlopaj": "sound", "w-begi": "sem"}`.
- \+ 15, reverse: `stage` `act-sit`; options `w-sjad`, `w-vstan`, `w-idi`; wrong `sem`, `sem`.
- 07: the teacher chooses one of two fixes:
  - teach "возьми" (a learn item in a lesson, and the word added to the set); or
  - change its target to a taught command shown in a new picture (for example `w-idi` with `mika-walk`).

**`units/12-what-who.json` (RUS-A-12):**
- 04: add `"check": "reverse"`.
- 01, 02 and 03 become LS10 bubbles and stay in `what-who-more1`:
  - `kind` `puppet`, `mode` `bubble`, `frame` `f07`, `rep` `story`;
  - `picture` = their present stage (`ball`, `cat`, `apple`);
  - `prompt` = their present target (`["ch-chto-eto"]`, `["ch-kto-eto"]`, `["ch-chto-eto"]`);
  - options and tags unchanged.
- Later (L): 7.9 item 10.

**`units/15-say-it.json` (RUS-A-15):**
- 07, 12 and 21: `then.purpose` becomes `learn`.
- \+ 25: `{"kind": "listen_do", "mode": "hotspots", "frame": "f19", "purpose": "check", "picture": "scene-room-ball", "target": "w-mjach", "options": ["ball", "balloon", "doll"], "wrong": {"balloon": "sem", "doll": "sem"}}`. Not the mouse room, which RUS-A-20 23 and 24 use for the same word.
- \+ 26: the same on `scene-room-cat` with `w-koshka`; options `cat`, `dog`, `porridge`; wrong `sem`, `sem`.
- \+ 27, reverse: `stage` `teddy`; options `w-mishka`, `w-mysh`, `w-kukla`; wrong `{"w-mysh": "sound", "w-kukla": "sem"}`.
- \+ 28, reverse: `stage` `hat-warm`; options `w-shapka`, `w-sharf`, `w-kurtka`; wrong `{"w-sharf": "sound", "w-kurtka": "sem"}`.

**`units/20-hard-soft.json` (RUS-A-20):**
- \+ 21, reverse: `stage` `onion`; options `mp-luk`, `mp-ljuk`, `w-zhuk`; wrong `{"mp-ljuk": "hardsoft", "w-zhuk": "sound"}`.
- \+ 22, reverse: `stage` `teddy`; options `w-mishka`, `w-myshka`, `w-knizhka`; wrong `{"w-myshka": "yi", "w-knizhka": "sound"}`.
- \+ 23: `{"kind": "listen_do", "mode": "hotspots", "frame": "f19", "picture": "scene-room-mouse", "target": "w-mishka", "options": ["teddy", "mouse", "cat"], "wrong": {"mouse": "yi", "cat": "sound"}}`
- \+ 24: the same with `w-myshka`; options `mouse`, `teddy`, `cat`; wrong `{"teddy": "yi", "cat": "sound"}`.
- Lesson `pairs-2`: `["05", "06", "17", "23", "24"]`. The teach and hearing screens of мишка and мышка already come before `pairs-1`.

**`units/16-story.json` (RUS-A-16):** 06 and 09 get `"inLesson": true` (C-6).

**Also:**
- 7.9 item 4: A-02, A-05, A-06, A-11.
- Later (L): the five long lessons (D7), and 7.9 item 9 (the bubble pictures of 04 to 06).
- Every clip above is already in `pronunciation.csv`, and every picture exists.

### 7.13 The others

- **app-developer:**
  - D1 (7.2), D3 (7.4: the check visit, C-5 pairs, C-6), D4 (7.5), and the bin rule of D5;
  - `HL-REV` support: a `tap` with sound-only options, a `stage`, no `target`, and a `hintWord` whose `@gloss` resolves (per-item `feedback` overrides already exist);
  - regenerate the packs after the teachers' edits, and run the Dart tests of section 5.
- **design-director** (working on pictures now):
  - the four bin signs (D5), with the ball the same size in `sign-one` and `sign-many`;
  - `pip-basket` (7.3): Pip whole beside an open toy basket, with the drop target on the basket and the rail clear of him, as in `pip-feed`;
  - a check of the A-10 shape pictures at tile size (7.9 item 8);
  - hotspot entries for the new room items: `rus.a20.23` and `rus.a20.24` on `scene-room-mouse` (the teddy, the mouse and the cat each a separate target of at least the minimum size), `rus.a15.25` on `scene-room-ball` and `rus.a15.26` on `scene-room-cat`;
  - later (L): the bubble pictures (7.9 item 9).
- **hebrew-text-editor:** the two English-course lines (7.10), the titles of `ani-3`, `say-1` and `say-2`, and the 31 home activities (D8).
- **voice-and-sound-director:**
  - two new Hebrew clips in the English teaching voice (`he-ins-which-word`, `he-ins-give-it`) and the clips of the new titles; no new target clip;
  - the generator regenerates the voice plans;
  - every paid step is the owner's.
- **qa-engineer** (once, when the batch is done), guards to add or change:
  - the flow test of `qa_band_a_mastery_test.dart` follows the course stop: lessons, then check visits on later days. Expected: every skill fresh, except HEB-A-14, which is met and never fresh;
  - no `show` in any Band A activity;
  - every core skill has at least 2 check types among its checks and at least 2 representations among its lesson items;
  - no check in a lesson unless it is marked `inLesson`;
  - every word of a set skill has a learn item in a lesson;
  - no hint or first-error line before level 3 of a reverse item plays its right clip;
  - a paired check is credited only when both halves are right;
  - HEB-A-14 is met after items 05 to 08, not after 01 to 04;
  - the bins of a Band A sort have pictures and no text.
- **orchestrator:** asks the owner about the Today's Adventure slot of the check visit (7.4 C-2). 7.9 item 13 stays open.

### 7.15 Built (app-developer, 2026-11-07)

What was built for 7.13, and what the build found. The PLAN.md bullet "Build detail (Languages Band A, the QA decisions D1 to D5)" says the same in one paragraph.

| Decision | Built | Where | Proof |
|---|---|---|---|
| D1 | `recipe_say` shows nothing by default; the generator refuses any `show` in a Band A skill's activity (Hebrew A-10 to A-12 aside), whatever way it was written | `tools/lang_recipes_talk.py`, `lang_routes.py` (the hearing-screen override is gone), `lang_pack.py` `_no_chips` | `tools/test_lang_band_a_rules.py` `NoChipTest`, `CommittedPacksTest`; `language_band_a_rules_test.dart` (0 activities with a chip in the three packs); `route_screens_test.dart` now expects no chip |
| D2 | `reverse` in the recipes: stage, sound-only options, `HL-REV`, a clip-less item's word is its `hintWord`; the generator refuses a reverse item that plays the right clip in its prompt, hints 1 and 2 or first-error line, that is not a check, has no picture or has picture options | `tools/lang_recipes.py` `check_reverse`, `head` | `ReverseItemTest`; the app already played sound-only options of a tap (the generic hint of `tap_answer_session.dart`) |
| D3, C-1 to C-5 | the check visit, pairs and the failed-check rules | `engine/check_visit.dart`, `engine/state.dart` `CheckTrail`, `engine/engine.dart`, `world/check_visits.dart`, `world/course_path.dart` `courseCheckVisit`, `world/adventure_adapter.dart`, `world/todays_adventure.dart`, `app/course_visit.dart` | `engine/check_visit_test.dart` (25), `check_visit_world_test.dart` (16), `todays_adventure_languages_test.dart` |
| D3, C-6 | a check in a lesson is refused unless `"inLesson": true` | `tools/lang_pack.py` `_no_checks_in` | `ChecksAndLessonsTest`, `CommittedPacksTest` |
| D3, Today's Adventure | the check visit takes the revisit slot after every revisit of a mastered skill (owner's OK 2026-11-07) | `todays-adventure-rule.md` section 15 | `check_visit_world_test.dart`, `todays_adventure_languages_test.dart` |
| D4 | `startGuide` for a T04 trace with the start dot; the validator accepts `writing: practised` on T04 items | `content/engine_adapter.dart`, `content/ls02_checks.dart` | `language_band_a_rules_test.dart` (not met after 01 to 04, met after 05 to 08, never fresh) |
| D5 | a Band A bin has a picture (a letter in A-10 to A-12 aside); a bin with a picture shows no text | `tools/lang_recipes_more.py` `check_bin_sign`, `play/ls01_sort_session.dart` | `BinSignTest`, `CommittedPacksTest` |

**How the check visit is chosen** (the rules are 7.4; these are the choices the build made). A skill is **taught** when every lesson of the path that names it is finished or placed, or placement assumed it (`taughtSkills`). Of the ready skills of a course the one whose last answer is oldest goes first, then the path's order, and at most one visit a day per course (`Visit.check`, a revisit visit whose lesson id ends with `-check`). The visit holds at most 5, 8 or 12 items for Band A, B or C (`checkVisitMax`) and at least 3 when the skill has them. "Ends on a success" is planned, not reacted to: the plan ends on a learn item the child already got right when it would end on a check. A balanced pair is taken whole or not at all. The check type "failed" and the "two failed visits" are kept per skill in the engine's replay (`CheckTrail`), so nothing is stored.

**What the build found, beyond 7.1 to 7.13.**
1. **Items that write no answer were counted as words of a set.** A chant, a story only heard, a personal turn, a movement and a say step of a skill that is not a speaking one are no evidence, but their variant groups counted in the set coverage, so RUS-A-01 to A-04 and ENG-A-17 could never be fresh for a real child (QA's first test answered those items, which the real app never records). The engine catalogue no longer holds them (`engine_adapter.dart`). A word that only the say steps of a *speaking* skill ask (ENG-A-17's "how are you" answers) is not one that fresh mastery waits for either: without the microphone nothing could cover it (`Catalog.coverageGroupsOf`).
2. **The two-choice half counted probes** (frame 2.3), which refused ENG-A-16 once its two yes and no probes were added (8 of 14). Probes are not evidence of mastery, so the half is counted over the other items (`language_checks.dart`; frame 2.3 says so). **Confirmed by the curriculum-expert (7.16).** The other way would have been two more three-choice items in ENG-A-16.
3. **Counts of 5 to 10, the SE's bins and the print page** are built as the design-director specified (`docs/design/languages-band-a-qa.md`), with one limit: the corner speaker is Band A's and for cards that are pictures or letters.
4. **QA's flow test follows the course stop** (7.13): every skill fresh, HEB-A-14 met, in 19, 27 and 36 days of three visits (Hebrew, English, Russian; about one check visit a day). It also needed the engine facts above.

### 7.16 Confirmations (curriculum-expert, 2026-11-08)

1. **The two-choice half counts non-probe items only: confirmed.** No three-choice items are added to ENG-A-16.
   - The rule exists to keep two-choice items to at most half of a skill's *evidence*: frame §2.3 calls it "the authoring side of the engine's 2-choice guard, which caps them at 50% of the success evidence".
   - A probe is never evidence: the engine counts no probe as a success. It is played only in placement, never in a lesson, a check visit or a revisit.
   - Counted over the items that are evidence, ENG-A-16 has 6 two-choice items of 12, exactly half, and balanced: 3 "yes" and 3 "no" among i01 to i06, plus the pair pr1 / pr2.
   - Two more three-choice items would add screen time for a counting artefact and teach nothing new.
   - Guard for this: a two-choice **probe** still needs its balanced partner in the same placement level (pr1 with pr2), so a strand never moves on one coin-flip.
2. **The "unsure" step of a reverse item never plays the right word: confirmed.** All 17 reverse items in the packs pass, checked on the generated activities:
   - English (8 items): `he-hint-again` with no target clip;
   - Russian (8 items): `f38` with no target clip;
   - `rus.a12.04`: `f17` with no target clip.

   The course default ("listen again" plus the target) would give the answer away, so the override is right. Taps never return "unsure" today (only speech does), but the item must hold for when it can. The generator's `check_reverse` should refuse a reverse item whose `unsure` names the right clip, as it already does for the prompt, hints 1 and 2 and the first-error line (a one-line addition for the app-developer, if not already there).
3. **The developer's choices in the check visit: both accepted.**
   - **A placed child gets the check visit of an assumed skill the day after placement.** This is the earliest day C-1.3 allows, since the probes were answered that day. It is the retrieval check that frame §3.2 asks for within 2 weeks.
     - With one check visit a day per course, a child who was placed high and has more than about 14 assumed skills cannot have them all checked within 2 weeks.
     - That is acceptable: an assumed skill keeps its prior (0.85), and nothing waits for the check. No change is needed. If it shows up in use, the first thing to try is to allow a second check visit on a day when the child plays a second visit.
   - **"Ends on a success" is planned, not reactive.** When the plan would end on a check, its last item is a learn item the child has already answered right. This keeps curriculum §10.3 as closely as a fixed list can, because the easiest known item comes last.
     - If even that item is answered wrong, the visit still ends with the course's celebration and no failure signal. Nothing is added after it: no loop, and no "one more".
     - One condition: the closing item is a learn item the child already got right with no hint, and never a check.

### 7.14 Sources

**In the repo:**
- `docs/curriculum.md` §4.1, §5.5, §5.6, §10.2, §10.3, §10.9;
- `frame.md` §2.3 and §3.1 to §3.7;
- `fonts.md` §6;
- `writing-mastery.md` §2.2;
- `hebrew/syllabus.md` (row A-14);
- the three `band-a-content.md` files.

**Research:**
- Laufer, B. & Goldstein, Z. (2004). Testing vocabulary knowledge: size, strength, and computer adaptiveness. *Language Learning* 54(3), 399–436. Recognition and recall, in both directions, form a hierarchy. The learners were older, so applying it at ages 3 to 4 is an inference.
- Rosenthal, J. & Ehri, L. C. (2008). The mnemonic value of orthography for vocabulary learning. *Journal of Educational Psychology* 100(1), 175–191.
- Evans, M. A. & Saint-Aubin, J. (2005). What children are looking at during shared storybook reading. *Psychological Science* 16(11), 913–920.
- Cepeda, N. J. et al. (2006). Distributed practice in verbal recall tasks. *Psychological Bulletin* 132(3), 354–380.
- Karpicke, J. D. & Roediger, H. L. (2008). The critical importance of retrieval for learning. *Science* 319, 966–968.
