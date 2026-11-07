# Band A of the three courses: how the content becomes signed packs

Owner: app-developer. Date: 2026-11-07. Status: **the pipeline is built and the teachers' Band A is in the packs: every template has a recipe (194 activities in English, 157 in Hebrew, 457 in Russian, 117 of them teach screens); the own name, the print direction, the teach screens of the Russian routes and a font for one item were added the same day; what still waits is in section 2.4.** Applies the owner's request of 2026-11-07 (the Languages island must become playable: ENG-1, HEB-1, RUS-1) to `frame.md` §1.5 and §6, `docs/milestones/L0.md`, `L4.md`, `L-course.md` and `L5.md` §9 ("the language pack generator is built with the Band A packs").

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
* **Lesson.** `id` (the lesson is `<course>.<id>`, at most 40 characters), `title` (Hebrew), `items` (this unit's item ids, or `<skill slug>.<id>` for another unit's), `celebration` (a line id, else the default), `minutes`, `sequence`. **The order of the path is the order of the files and of the lessons in them**; name the files `01-`, `02-`… in the order the child should meet them (a lesson may set `sequence`). Put in a lesson the items to *learn*; the checks and probes stay outside it (they come as the revisits and the placement).
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

* **Built the same day (2026-11-07, second step):** Hebrew **A-11** (the child's own name, 5 items) and **A-12** (print direction, 7 items) are in the Hebrew pack (sections 2.5 and 2.7); the Russian **teach screens** (117) and the route filter (section 2.6); **a font per item** (section 2.8); the hotspots of a listen-and-do are no longer drawn at rest (section 2.9); the shapes of A-10 are pictures (two stand-ins, below).
* **What a route still cannot do** (Russian). Only the teach screens follow the route. The rest of the teachers' route records stays in the unit files and is not read: the item a heritage child starts from (`from`), the order of the lessons for a route (`order`), what is weighted up (`weight`), the say step *picture first* for a heritage child (`say`; the app's say step is echo first for every child), the embodied step after each right tap (`embodied`), and the single hearing of the six words of RUS-A-20 for a heritage child (no teach screen is shown to it, and nothing replaces it). They need a path and a lesson builder that know the route; a lesson that a route skips would be an empty lesson today.
* **Heart and flower of Hebrew A-10** (items t05 and s06): Heebo has neither the heart nor the flower, and Secular One has no flower (it drew an empty box), so **no card of A-10 is a text character any more**: the star of s02 is the picture `star`, and the two cards that wanted ♥ and ✿ are the picture `shape-triangle` (t05) and `star` (s06) **as stand-ins**. The two pictures `shape-heart` and `shape-flower` are for the design-director (the same ink and weight as `shape-dot`, 256 by 256); the day they are in `content/languages/pictures` the two cards go back to the teacher's shapes (`units/08-letters-or-not.json`, then `python tools/lang_pack.py heb`).
* **Items left out of the packs because a clip or a picture is missing**, for the voice-and-sound-director and the design-director: the ten animal-sound items of RUS-A-05 (23 to 32) need the clips `sfx-cat` … `sfx-wolf` in the Russian clip table; the six "find it in the room" items of RUS-A-13 (01 to 06, they stay LS01 taps) need the scene `scene-room` with the three things drawn into it (the table has the places, not the things).
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

### 2.6 Teach screens and routes (Russian)

The teachers' unit files carry `teach` (the new words of the skill, in sets of 4 to 6) and `routes` (what each route is served). They are now data the app reads:

* `course.json` says the picture of each teach word (`teachPictures`, 116 words, from the pictures the course's own items use for them) and the lines of a teach screen (`defaults.teach`: `frame` f03, `heard`, `together`).
* The generator makes **a teach screen for each word**: a `say_it` activity (LS09, echo: the picture, the word, a pause, the word again) with `answer.teach`, id `<course>.<skill>.tcNN`. It is **unscored, writes nothing, has no microphone and no help** ("I said it" goes on), is not an item of any lesson, and **the engine does not see it** (not in its catalogue, no representation counted for the skill).
* A lesson has `teach`: the sets, each with the routes that are shown it. A set goes before the first lesson whose prompts ask one of its words (a set no lesson asks by word, the body parts, goes before the lesson of its own number). `lesson.teach[].routes` may name only `new` and `reader`: **a heritage speaker is never shown a teach screen**: the schema refuses the route, the generator never writes it, and `PackContent.itemsFor` refuses it as well.
* Lesson building: `PackContent.itemsFor(lesson, route:)` gives the teach screens of the sets the route is shown, then the lesson's items; `LessonController(route:)` plays that. A route not set yet counts as a new learner. A record `"reader": {"as": "new"}` serves the reader as the new learner (a reader placed past the skill never reaches its lessons; the others have not met the words); `"as": "heritage"` serves it as a heritage speaker (RUS-A-16 to A-20 and A-20's pairs).

The routes record is now structured (`{"new": {...}, "heritage": {"teach": false, "from": "04", ...}, "reader": {"as": "new"}}`; the teachers' prose is in `note`). What of it the app does not read is in section 2.4.

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
| `tools/test_lang_pack.py` (80) | the committed pack sources and voice plans are exactly what the course files give (twice over, on a copy); the derived fields; 40 rules the generator checks before the builder (lines, clips, pictures, tags, options, ladders, ids, lessons, placement, versions); the §1.5 invariants in the written files (one course, tutor off, every distractor tagged, `needs-editor`) |
| `app/test/language_packs_build_test.dart` | each course's source through the **real** pack builder and validator (F5 and §1.5), signed, verified, read as the app reads a pack: no warnings, one course through and through, the tutor off, every line pending and planned, shared pictures; a broken copy is refused (cross-course prerequisite, tutor on, untagged distractor, wrong course, foreign tag, wrong id, missing picture); the bundled-pack guard (skipped until the owner signs the packs) |
| `app/test/bundled_language_packs_test.dart` | file-name discovery; nothing installed for a family with no language on; installed once; not over a newer copy; repaired when damaged; a stranger's signature leaves only that course out; a wrong name cannot stand for another course; the provider installs on turning a language on and does not read again for another switch |
| `app/test/language_band_a_templates_test.dart` | one sample of every kind of activity of the real packs (a tap with a stage, sound buttons, a tap-all, the six modes of listen and do, a puppet's bubble and personal turn, say it, a chant, the drum, a story heard and one that asks, a count, pairs, a sort, a story line, the pre-writing path) opens on the lesson screen on the phone and the tablet; `NN_SHOTS=<folder>` writes a picture of each |
| `app/test/second_target_clip_test.dart` | a line with two target clips, and a misconception that lists up to 60 skills |
| `app/test/lesson_routes_test.dart` (14) | what a route plays (a new learner and a reader are shown the teach screens first, a heritage speaker never, in no lesson), the 117 teach screens (unscored, no attempt, not an item, not in the engine), the controller, four broken sources refused |
| `app/test/own_name_test.dart` (19) | the name as it is printed, the rules NAME-FIRST and NAME-LENGTH and the look-alike row, every name of the list as a child's name, the fallbacks, the pack holds no name, the name never leaves the phone, the screen on the phone and the tablet |
| `app/test/read_page_test.dart` (14) | the zones and follow items of the pack, nothing drawn at rest, the zones on the right and left of the print, the tags, the hints, the reading of a page word by word; `NN_SHOTS=<folder>` writes a picture of each state |
| `app/test/display_font_test.dart` (5) | Heebo and Secular One by scope, the two items that ask for it, another course refuses it |
| `tools/test_lang_pack_more.py` (21, run by `test_lang_pack.py`) | the teach screens and routes, the own-name items, the print-direction items, the font |
| `app/test/language_pilot_test.dart` | the **playthrough**: for each course, door, course home, the placement visit (a wrong touch at each probe, so that the first lesson stays next), first lesson to the celebration, back home, with every answer written as a row of the course (pack `lang-<course>`, ids only); a wrong touch is the diagnosed error of its distractor; goldens of the first activity on the phone and the tablet (`app/test/goldens/pilot_<course>_first_<board>.png`) |

CI: add `python3 -I -X utf8 tools/test_lang_pack.py` next to `tools/test_generators.py` in `.github/workflows/ci.yml` (infrastructure-engineer).

## 6. For the teachers, in order

1. Copy the pilot's unit file of your course, keep the first skill, and add the skills of your `band-a-content.md` in the order of the path (`01-`, `02-`…). The item tables map one to one: the item's frame line, clip, options, right answer, distractor tags, ladder.
2. Add the lines you use to `course.json` `lines` (the Hebrew of your §2, with its `voice` text) and the tags (your §3) to `tags`.
3. Run `python tools/lang_pack.py <course>`; fix what it says; run the Dart tests of §5 (the pack builder runs the real validator).
4. Items whose template has no recipe yet: write them as `raw`, or tell the app-developer which template comes next.
5. A picture that is missing is the design-director's to draw (the generator names it).
