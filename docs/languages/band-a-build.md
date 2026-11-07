# Band A of the three courses: how the content becomes signed packs

Owner: app-developer. Date: 2026-11-07. Status: **the pipeline is built and proved on a pilot (one skill and one lesson per course, text only). The three language teachers write the rest.** Applies the owner's request of 2026-11-07 (the Languages island must become playable: ENG-1, HEB-1, RUS-1) to `frame.md` §1.5 and §6, `docs/milestones/L0.md`, `L4.md`, `L-course.md` and `L5.md` §9 ("the language pack generator is built with the Band A packs").

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
| `defaults` | `frame` (the Hebrew line every item says unless it names one), `ladder`, `celebration` (a line id), `rep`, `minutes`, `retention`, `pictureLabel` | |
| `lines` | **The Hebrew lines** of the course, by id: `{"he": "…with nikud…", "voice": "…text for the voice…", "review": "text-ready"}`. Ids are lower case letters, digits and hyphens (the teacher's `he-ins-listen-tap`, `i-find`, `ok-3`, `f01`). `he` is the caption and the text of the clip; `voice` goes to the voice plan only. | |
| `feedback` | `right`: a list of praise lines (item *n* of the course says line *n* mod the list length), `wrong`: the first-error line, `unsure`, and `byTag`: a line per tag slug that the first error says when that tag's distractor was touched | |
| `ladders` | Hint ladders by name, **exactly 3 steps**: `{"line", "action", "target"}`. Actions: `replay_prompt_slow`, `highlight_objects_sequentially`, `show_fingers`, `worked_example` (level 2 must change the representation: the app's hint ladder draws the picture for it, B-40) | |
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
* **Item, kind `raw`.** For any other template (LS08, LS09, LS10, LS11, LS12, LS03 drum, `count_tap`, pairs) until it has a recipe: `{"id": …, "kind": "raw", "activity": {the activity document}}` with the template's own fields. The generator sets `schema`, `id`, `course`, `domain`, `band`, `review` and `skills` (the unit's skill unless the document names them); the pack builder checks the rest exactly as for any activity. Each recipe is added by the app-developer when the first unit needs it (the order of the batches: LS10, LS11, LS12, LS08, LS03, LS09, `count_tap`).
* **Lesson.** `id` (the lesson is `<course>.<id>`, at most 40 characters), `title` (Hebrew), `items` (this unit's item ids, or `<skill slug>.<id>` for another unit's), `celebration` (a line id, else the default), `minutes`, `sequence`. **The order of the path is the order of the files and of the lessons in them**; name the files `01-`, `02-`… in the order the child should meet them (a lesson may set `sequence`). Put in a lesson the items to *learn*; the checks and probes stay outside it (they come as the revisits and the placement).
* **Doc.** A gate (`gate/v1`) or other whole documents the course needs. The generator adds `schema`, `review` and `course`.

### 2.3 `placement.json` (frame §3.2)

```json
{"perVisit": 8, "thanks": "he-fb-right-1", "celebration": "he-bye",
 "strands": [{"id": "o", "start": [{"answer": "knowsLetters", "equals": "some", "level": 1}],
              "levels": [{"items": ["a01.p01"], "assumes": ["ENG-A-01"]}, {"items": ["a01.p02"], "assumes": ["ENG-A-03"]}]}]}
```
Probes are ordinary `tap` items with `"purpose": "probe"`, written as `<skill slug>.<id>`. At least 2 levels a strand, at most 6 probes a level (the validator's limits). The pilot has no placement (a placement needs the syllabus's staircase); it was proved on a scratch copy of the English pilot with two probe items and one two-level strand, which the real pack builder accepted.

### 2.4 What the format cannot say yet (said plainly)

* **One Hebrew clip and one target clip per line.** The teachers' longer feedback chains (English `he-fb-thats` + the chosen word + `he-fb-listen-again` + the right word; Hebrew praise after the word) are written as the two clips that matter: the diagnostic line, then the right word. The order of a line is always Hebrew first, then the target.
* **Only `tap` has a recipe.** The other templates are `raw` documents. The first batches that need them name the template and the app-developer writes its recipe, so no teacher writes raw JSON for long.
* **No placement in the pilot, no teach screens or routes** (new learner, heritage, reader): the app has no route data yet; the items are the same for every route.
* **Hebrew in the generator is always `needs-editor`** (CLAUDE.md). A document becomes `approved` only when the hebrew-text-editor says so; there is no approved flag yet (the starter pack's approval list, `hebrew-master.csv`, has no language rows).
* **Option labels** (for TalkBack) are the generic "picture" until a `pictureLabel` or an option's own `label` is written.

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
| `tools/test_lang_pack.py` (65) | the committed pack sources and voice plans are exactly what the course files give (twice over, on a copy); the derived fields; 40 rules the generator checks before the builder (lines, clips, pictures, tags, options, ladders, ids, lessons, placement, versions); the §1.5 invariants in the written files (one course, tutor off, every distractor tagged, `needs-editor`) |
| `app/test/language_packs_build_test.dart` | each course's source through the **real** pack builder and validator (F5 and §1.5), signed, verified, read as the app reads a pack: no warnings, one course through and through, the tutor off, every line pending and planned, shared pictures; a broken copy is refused (cross-course prerequisite, tutor on, untagged distractor, wrong course, foreign tag, wrong id, missing picture); the bundled-pack guard (skipped until the owner signs the packs) |
| `app/test/bundled_language_packs_test.dart` | file-name discovery; nothing installed for a family with no language on; installed once; not over a newer copy; repaired when damaged; a stranger's signature leaves only that course out; a wrong name cannot stand for another course; the provider installs on turning a language on and does not read again for another switch |
| `app/test/language_pilot_test.dart` | the **playthrough**: for each course, door, course home, first lesson to the celebration, back home, with every answer written as a row of the course (pack `lang-<course>`, ids only); a wrong touch is the diagnosed error of its distractor; goldens of the first activity on the phone and the tablet (`app/test/goldens/pilot_<course>_first_<board>.png`) |

CI: add `python3 -I -X utf8 tools/test_lang_pack.py` next to `tools/test_generators.py` in `.github/workflows/ci.yml` (infrastructure-engineer).

## 6. For the teachers, in order

1. Copy the pilot's unit file of your course, keep the first skill, and add the skills of your `band-a-content.md` in the order of the path (`01-`, `02-`…). The item tables map one to one: the item's frame line, clip, options, right answer, distractor tags, ladder.
2. Add the lines you use to `course.json` `lines` (the Hebrew of your §2, with its `voice` text) and the tags (your §3) to `tags`.
3. Run `python tools/lang_pack.py <course>`; fix what it says; run the Dart tests of §5 (the pack builder runs the real validator).
4. Items whose template has no recipe yet: write them as `raw`, or tell the app-developer which template comes next.
5. A picture that is missing is the design-director's to draw (the generator names it).
