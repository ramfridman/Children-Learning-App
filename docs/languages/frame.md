# The Languages category: the shared frame

Owner: **curriculum-expert** (head of curriculum). Date: 2026-11-03. Status: **approved by the owner on 2026-11-03 (§8). Nothing here is built.** The catalogue (§4) was settled the same day, after the three Band A content batches (§4.4); the engine rules are also in `docs/curriculum.md` §10.9.
The three courses (`english/`, `hebrew/`, `russian/`) are owned by their teachers. This file owns what they share: where the category sits in the app, one engine with a course id, one set of templates, placement, mastery, revisits and session shape, one misconception catalogue format, and the order of the milestones. It applies the owner's 27 decisions (`decisions-2026-11-03.md`, all APPROVED, three CHANGED).

Read with: `README.md` (the category's rules), `decisions-2026-11-03.md`, each course's `syllabus.md` and `templates.md`, `docs/research/{english,hebrew,russian}-course-2026-11-03.md`, `docs/curriculum.md` §5.7 and §10.

**Decision numbers** below (D1 to D27) are those of `decisions-2026-11-03.md`. **Line numbers** in §5.4 refer to the teachers' files as they are on branch `languages-team` on 2026-11-03.

---

## 0. The frame in one page

1. **One land, three courses.** The map gets one new land, the Languages island. At its entrance the child picks a language at one of three doors. Each door opens its own course: its own path, progress, mastery, placement and voice. A course never reads or writes another course's data (D5), and nothing in the other lands depends on any course (D4).
2. **A course id on everything.** Each skill, item, misconception tag, placement result, progress row and pack carries `course` (`eng`, `heb`, `rus`; the existing lands are `core`). The validator refuses any link across courses.
3. **One template set.** The teachers proposed 35 new or changed templates between them (English LT01 to LT11, Russian R1 to R11, Hebrew H1 to H6 and N1 to N7). They merge into **2 extensions of existing templates and 12 new templates (LS01 to LS14)**, each with one spec and per-language settings. They are built in three waves: Band A needs, then Band B, then Band C.
4. **The engine rules stay those of `docs/curriculum.md` §10.** Languages add six things: a *presentation band* (from age) separate from the *content level* (from mastery); per-group sub-skills with a derived roll-up; **letter bundles** (a letter's shape, sound, name and writing open together and count as one new skill); **set coverage** for word sets; a **sound-right** spelling outcome; and **course gates** (the English oral gate, the Russian letters gate).
5. **Speech (D1).** There is an on-device recogniser per language. The outcome is per word, and there are only two outcomes: **confident** (real praise) or **unsure** ("let's say it together" and a model of the word). Speech is never "wrong", never counts against a child, and never counts for reading skills. It gives limited evidence for speaking skills only.
6. **Personal questions (D10)** live only in authored lesson scripts: name, age, likes and family, never an address. The answer is used for the next line and then forgotten. It is not stored, synced, logged, or used to choose content. The AI tutor's rule is unchanged, and the AI tutor is off in language lessons anyway (§1.6).
7. **Every letter is taught whole (D16):** its shape, sound, name and writing are introduced together, in every language. Blending always uses sounds, never names.
8. **Order of work:** the shared foundations come first (the category shell, the course id, text and direction, fonts, two-clip audio, recognisers, the first template wave, the voice pilots). Then the three courses are built **in parallel**, Band A first (the owner's family-release rule Q4). Template waves 2 and 3 land just before the courses need them.

---

## 1. The category in the app

### 1.1 Where it sits on the child's map
- **One new land, not three.** The README calls Languages a *category*, and the child chooses the language at its entrance. One land keeps the map readable for a pre-reader, and it stays the same size whether a family turns on one language or three. The map goes from 7 lands to 8 (home plus 7).
- **The name** is a draft: "אי השפות" (*Languages Island*), `"review": "needs-editor"`.
- **The position** is the design-director's call; the owner sees it before it is built. The recommendation is to put it **next to the child's home island**, not at the far end of the strip. The Hebrew course carries early literacy for Bands B and C and will be visited often. The phone strip, the SE strip and the tablet scenes all change (`docs/design/phone-map-7-lands.md`).
- **Its host is the language's own teacher character** (§1.3). The land itself is hosted by the child's companion, who walks the child to the doors.
- **Growth works as on every land.** Each skill owns one object in its course's part of the island, for example a garden per language. The object is sketched while the skill is learning, coloured at fresh mastery, and gets a golden star at durable mastery. A due revisit raises the object's bell flag. Nothing decays or is taken away.
- **If a parent turns every language off,** the land is hidden from the map, as for "hidden domains" (PLAN.md › Controls).

### 1.2 Choosing a language (the child)
- **Doors.** The entrance shows one door per language the parent turned on, and nothing for a language that is off: no greyed door, no lock, no "coming soon" (no scarcity).
- **How a door is told apart.** Each door shows its host character, the word *hello* in the language's own script (שלום · Hello · Привет; the Hebrew needs-editor, the others need their teacher), and the language's teaching voice saying it on a first tap. **No national flags:** a language is not a country, and flags bring politics into a child's space.
- **One language on.** If only one language is on, tapping the land opens that course directly.
- **Switching.** The child leaves a course by the usual "home" button and may enter another door at any time. Switching loses nothing: each course resumes where it was. No line ever compares languages or says that one was not practised.
- **Order of the doors.** The order is fixed (the design-director's choice). It is not sorted by use, so a child does not learn that one language "comes first".
- **Placement.** The first time a child opens a course, its placement game (LS13, §3.2) is the first activity. It is framed as "a visit", with no result shown.

### 1.3 Voices and characters inside a course
- **Who speaks.** Inside a course, the **language's teaching voice** speaks every line: the Hebrew frame and the target language (README rule 3, D6). The child's companion is present on screen and reacts with animation and non-verbal sounds only.
  - This is a change to PLAN.md › "Every character speaks in its own voice, everywhere". The orchestrator updates PLAN.md once the owner approves this frame.
- **Clips.** Every mixed line is **two clips**, a Hebrew frame clip and a target clip, played in sequence (the teachers' S3, `pronunciation-spec` §3). A target clip is reusable, and its pronunciation spec belongs to its teacher.
- **If no single voice is excellent in both languages** (the D6 fallback), the frame accepts **two characters**: a Hebrew-speaking host and a native-speaking puppet friend. Never one character with two voices, because a voice change must be visible as a change of speaker. This is also the common "one person, one language" practice of bilingual homes. The evidence that children *need* it is mixed, so it is a fallback, not a goal.
- **The address form.** The recorded Hebrew frame lines are plural and gender-neutral for every profile, like every core line of the app (the hebrew-text-editor's rule, `docs/agents/hebrew-notes.md` §9.1: one clip per line, and no first-person verb or adjective with a gender, so any voice can say them). The profile's address form (masculine, feminine, plural) applies only to the AI tutor, which is off in language lessons (§1.6). Target-language lines keep the teachers' gender rules (the Russian voice never reveals its own gender, syllabus §6).

### 1.4 The parent area: a language on or off, and progress per language
**Controls** (one page per language, in the existing Controls area):

| Control | Courses | Default | Source |
|---|---|---|---|
| Language on or off | all | asked once at setup (see Q-F1 in §8) | README rule 5 |
| Voice answers in this language (the microphone, and the recogniser download) | all | off | D1; CLAUDE.md child safety |
| Personal questions in lessons (name, age, likes, family) | all | on | D10; the switch is my recommendation (Q-F2) |
| Oral only (no letters yet) | eng | off | D6 |
| Letters before age 5 | rus | off | D17 |
| Stress marks on screen | rus | per route (§3.3) | D15 |
| Parent check of reading aloud | heb | off | D22 |
| Home language questionnaire (enums only) | rus (the others may add one) | asked on first open | rus syllabus §7.3 |
| Russian-first instructions | rus | not in v1 | D12 |

**Turning a language off** hides its door and keeps all its data. Turning it back on resumes the course; nothing is reset.

**Progress per language** uses the same view as a domain:
- skills by status per strand (learning, fresh, durable, needs revisit);
- "we start here" per strand after placement (the parent may move it one level);
- the route (Russian: new learner, heritage or reader);
- the gates and whether they are open (English oral gate, Russian letters gate);
- speaking shown as **practised** or **said** (§5.1);
- misconceptions found and fixed, with their parent texts;
- the parent co-play cards (D9; the Hebrew handwriting cards, D23);
- for Hebrew, the optional reading-aloud check (D22).

The view has no streaks, no "you haven't practised", and no comparison between languages or between siblings.

### 1.5 The course id: courses never mix
**Data.**
- `course` is a field on skills (`SkillNode`), items (`ItemMeta`), misconception tags (`TagInfo`), placement results, progress rollups, rewards keys and packs.
  - Values: `eng`, `heb`, `rus`. The existing lands are `core`.
  - The skill id prefix already matches the course (`ENG-`, `HEB-`, `RUS-`). The validator checks that the two agree.
- Misconception engine ids are `<course>.<strand>.<slug>` (§4.2), so `M-ENG-DIR` becomes `eng.ph.dir`.
- Each course is **its own signed pack** (`lang-eng`, `lang-heb`, `lang-rus`). A pack contains its skills, items, tags, Hebrew frame clips, target clips, stroke data and pictures, and validates alone. It may use only app-wide assets (fonts, the shared picture library, the UI strings of the shell). The infrastructure-engineer decides whether packs are bundled or downloaded when a language is turned on. Recogniser models are downloaded only when that language's voice is turned on (§5.1).

**Invariants.** The validator refuses a pack, and a qa-engineer test guards each rule.
1. A prerequisite never crosses courses, nor goes between a course and `core`.
2. An item's skills, tags, `contradicts` and repair activities are all in its own course.
3. Evidence never flows across courses. A picture shared by two courses is two different items.
4. The representation profile (curriculum §10.5) is kept per child, **course** and strand.
5. A session, a revisit check or a repair never mixes courses (§3.5).
6. Placement is per course, and per strand inside a course (§3.2).
7. The band setting is per course: the parent's "band per domain" control gets one row per course.
8. Turning a course on or off changes nothing in any other course or land.
9. Response codes stay ids and numbers only: no letters, words or transcripts (CLAUDE.md security rule 2; `response_code.dart` pattern). Personal turns, own-name items and free writing write **no content** in `attempt.response` (§5.2, LS06, LS14).

### 1.6 The AI tutor in language lessons: off (RuleTutor only)
README rule 2 says no English or Russian text reaches a child without its teacher's approval, and no Hebrew without the hebrew-text-editor's. A model-generated line in the target language cannot meet that rule. The live validator checks Hebrew against the maths lexicon and cannot judge English, Russian or a Hebrew reading lesson's nikud.
- **What the hints are.** Hints in language lessons are the authored ladders, played by RuleTutor. `tutor-turn` refuses items whose course is not `core`; this is a gateway check for the security-engineer.
- **The talking companion.** "Talking to Nitzi" is not offered inside a course.
- **Later.** This can be reopened only by an owner decision with a target-language validator. It is not planned.

---

## 2. One shared template set

### 2.1 Shared foundations (before any language template)
These merge the teachers' cross-cutting needs: English S1 to S8, Russian §1, and Hebrew §1 and §3.

| # | Foundation | Per language | Replaces |
|---|---|---|---|
| F1 | **Direction-aware text runs.** Text in a course is an isolated run in its course's direction. Rows of tiles, slots, tokens and sound buttons follow the course's reading direction, not the UI's. | eng, rus: left to right; heb: right to left | eng S1; rus §1.2; heb §3 "right to left everywhere" |
| F2 | **Course fonts.** All text tiles go through `AppText`, with the nikud rules: line height 1.7 or more, no letter spacing. | eng: the Latin teaching font (single-storey a and g, clear b d p q; D8). rus: the Cyrillic font (D1). heb: Heebo if the design audit passes, else one open-licensed teaching font (D24) | eng S4; rus §1.1; heb voice-brief §6 |
| F3 | **Two-clip lines.** A Hebrew frame clip and a target clip in sequence, from one voice id or from two (§1.3). | all | eng S3; rus §1.3 |
| F4 | **Course id** in the engine, packs, progress and sync (§1.5). | all | eng S7; heb Q4 |
| F5 | **Content checks in the validator**: script per course (Latin; Cyrillic, plus U+0301 only where a skill shows stress; Hebrew with nikud from the editor's tables); ё never replaced by е, and no stress mark on ё; **decodable check** (every reading word uses only taught graphemes, or is a taught tricky word, per step or group); every distractor is tagged with a tag of its own course that is in the catalogue (§4.2) and is not an accent tag; the distractor rule of §2.3 (at least two tagged distractors, and the 2-choice rule); personal-turn rules (§5.2). | all | rus §1.4; eng LT10 note; heb §3 |
| F6 | **Letter stroke data** per script, in the trace box (100 × 100), with start, direction and order, and the guide lines of the script. | eng: 26 lowercase and 26 capitals, four lines. rus: 33 capitals and 33 small, ё and й marks as their own strokes. heb: 27 print forms (22 letters and 5 finals) and 27 script forms, with the hanging top line and the "basement" for ק ך ן ף ץ. The design-director draws all paths | eng S8; rus T04; heb H4(a) |
| F7 | **On-device recogniser per language** and the per-word matcher (§5.1). | heb: the existing `zipformer2-66m-streaming-he`. eng, rus: new models (the owner's OK for each; security review) | eng S6; rus R8; heb N6 |
| F8 | **The Languages land, its doors and the parent pages** (§1.1 to §1.4). | all | heb Q4 |
| F9 | **Engine additions** (§3): presentation band, sub-skills and roll-ups, bundles, set coverage, the sound-right outcome, gates, routes. | all | heb Q1 to Q3 |

### 2.2 Existing templates reused (with F1 to F3 and the LS01 extension only)
| Template | Language use | Courses |
|---|---|---|
| T02 `count_tap` | Counting in the target language (number clips per tap). **In a course, the counting taps are practice, never scored** (decided 2026-11-03): a skipped or double-tapped object is a counting error, which is maths and not the language, and the child selects no word while the app plays the clips. The scored step is T02's own last step, "how many?", answered from 3 **number-word options heard on a tap** (LS01 c); its distractors carry the course's number-word tags (rus `M-RUS-NUMWORD`, `-SOUND`; eng `M-ENG-SEM`). Representation `concrete` | eng (A-04, B-02), rus (A-10, A-11) |
| T18 `clock_set` | "It's three o'clock." | eng (C-20) |
| `give_n` | "Дай мне три яблока" (later) | rus (C-28, optional) |
| T14 `flash` | **Never for reading, in any course.** No exposure limit, no "quick look" with a timer. The English "the word stays until tapped" idea is a mode of LS01, not of `flash`. | none |

Not used by any course: T07 robot path, T08 balance, T09 number line, T10 shape builder and T17 shop. Unbuilt T24 (sound and move) is covered by LS11. Unbuilt T12 (voice-first) is covered by LS09.

### 2.3 The shared templates
Every template keeps the rules of curriculum §6.1, without exception:
- the tap path always works, and the microphone is optional;
- a three-step hint ladder in which **level 2 changes the representation** and level 3 is "show me";
- a replay button, big targets, no timer;
- at least two tagged distractors (every distractor tagged), with the 2-choice rule below;
- the course's direction (F1) and font (F2);
- Band-A presentation allows at most 3 choices and one instruction at a time.

**The 2-choice rule** (decided 2026-11-03, the Russian teacher's question; it matches what all three Band A batches do):
- An item with **3 choices** has two tagged distractors. The two may carry the **same tag** when one misconception explains both (one beat more and one beat fewer are both `M-HEB-SYLL`).
- An item with **2 choices** (yes / no, same / different, two names, the guided step of a 3-choice item) has **one** distractor, and it is tagged. This is allowed only when:
  1. the skill also has items with 3 choices, **or** the skill is binary by nature (yes / no, same / different), and its items are balanced (as many "yes" as "no" answers right, as many "same" as "different");
  2. 2-choice items are **at most half of the skill's scored items** (the authoring side of the engine's 2-choice guard, curriculum §10.2, which caps them at 50% of the success evidence);
  3. a 2-choice item is **never a check on its own**. An understanding check or a delayed check uses a 3-choice item, or, in a binary skill, a **balanced pair** (one item of each answer) that passes only if both are right (chance 1 in 4, not 1 in 2).
- A 2-choice item allows one retry only (curriculum §9.2), and a guided 2-choice item (the Hebrew "hidden second distractor") is a scaffold step that the engine credits as a 2-choice item.
- **Free-response modes** (LS02 trace, LS03 drum, LS06 build) have no fixed distractors. Their classifiers map each error they can name to a tag; an error they cannot name (a beat count off by 2, leaving a trace path) is a retry with no tag and no misconception evidence.

Inactivity prompts (§10.4) never fire while a clip or a story page is playing.

#### LS01 Text and sound options (an extension of `tap_answer`, `match_pairs`, `sort_drag`, `spot_error` and `build_pattern`)
- **What it adds.**
  - (a) **Text faces:** a letter, a grapheme (sh, ck), a CV unit (בָּ), a syllable (ма), a word, a phrase or a sentence. These are options, pair faces, bin labels, sortable items, `spot_error` cells (`txt:`) and `build_pattern` tiles.
  - (b) **A sound per option:** a speaker on each option plays its own clip, separate from the prompt.
  - (c) **Audio-only options:** sound buttons with no picture, for "same or different?" and "which word did you hear?".
  - (d) **A text stem:** a written word or sentence in the scene, to read, with picture options ("read and choose"). The "read it to me" button is hint level 1 and lowers the credit to 0.8.
  - (e) **Cloze:** a sentence with a gap and 3 word tiles.
  - (f) **Sequence:** picture or text tiles into slots in the course's direction (the Hebrew H6, ordering a story).
  - (g) **A caption after the answer** (decided 2026-11-03 for the Russian reader route; wave 1, last): once the child's answer to a listening item is accepted, the target word appears under its picture, in the course's font, with no demand and no score. It is shown **only after** the answer, so the item stays a listening item, and never under Band A presentation (§3.1). Settings: a per-course, per-route flag (rus `reader` with Band B or C presentation; off for every other route); stress marks follow the route's display default (§3.3.7); a parent can turn it off. Why: seeing a new word's spelling while learning it helps children remember the word (orthographic facilitation, Rosenthal and Ehri 2008), and a reader of Russian gets this at no cost. It reuses LS01's text face (a), so it adds no template; if wave 1 runs late it is the first thing to leave for wave 2, and RUS-1 does not wait for it.
- **Per language.**
  - Direction and font: F1 and F2.
  - heb: nikud always, from the editor's tables. Option sizes are never below the band's reading size, which the design-director sets.
  - rus: stress marks only where D15 allows.
  - eng: lowercase until C-13.
- **Classifiers.** The distractor's tag, as today.
- **Courses.** All three. This one extension carries most items in every course: eng T01, T03, T05, T16, T21; heb H1, H2, H3, H5, H6; rus T01, T03, T05, T16, T21, R5.

#### LS02 Write a letter (an extension of `trace`)
- **Three modes** (D4):
  - **trace**: the path shown, as today, with the full guide or the start dot;
  - **copy**: the model beside an empty box, no path in the box;
  - **memory**: no model; the voice says the sound or the name.
- **A free-stroke check for copy and memory.** The child's strokes are compared with the letter's stroke data (F6). The check covers the start, the direction, the order and the shape within a tolerance that the qa-engineer tunes on adult and child-like samples. Feedback comes at the **end of a stroke**, never during it.
- **A word canvas** for short words: larger, for a landscape phone or a tablet.
- **The ladder:** level 1 the start dot and arrow; level 2 the stroke drawn slowly once (a new representation: motion); level 3 trace mode.
- **Mastery of a writing skill** requires evidence in memory mode (D4: trace alone teaches little).
- **Per language.**
  - eng: four lines, families c a d g o / s e f / l i t j / r n m h b p k / u y / v w x z, and the "2 o'clock" start.
  - rus: print only (D13), three lines with descenders (д щ ц у р).
  - heb: print in Band B, script in Band C (D23), the top line, final forms below the line, and a parent pencil card for every handwriting skill.
  - Pre-writing strokes (heb A-14, eng W1) use trace mode with shapes.
- **Courses.** All three: eng B-19, C-13, C-15, C-16, C-23; heb A-14, B-24 to B-27, C-26, C-27; rus B-24, B-26, C-22, C-23. It replaces eng T04+S8, heb H4 and rus T04+R10.

#### LS03 Sound boxes (new, `sound_boxes`)
- **What the child does.** Hears a word (with its picture). Drags one token per **unit** into boxes in the course's direction. Then, depending on the mode:
  - says which box holds a given sound;
  - (rus) colours each token: red for a vowel, blue for a hard consonant, green for a soft one, then marks the stressed vowel;
  - (later) puts letters on the tokens.
- **Drum mode** (Band A): tap a drum once per syllable. Choosing "the strip with 3 beats" is LS01.
- **The unit per language.** eng: the phoneme (digraphs are one token). heb: the syllable, then the CV unit or a consonant (body plus coda, research R §4). rus: the phoneme, with colour.
- **Classifiers.** A count of ±1, mapped to the course's tag: in drum mode, eng one beat more → `M-ENG-SYLL`, one beat fewer → `M-ENG-WEAK-SYLL`; heb and rus either way → `M-HEB-SYLL`, `M-RUS-SYLL` (a count off by 2 or more is a retry with no tag); one token per syllable (`M-ENG-SEG-SYLL`, `M-HEB-SYLL`); a dropped cluster consonant (`M-ENG-CLUSTER`); a vowel coloured as a consonant; soft taken for hard (`M-RUS-HARDSOFT`); the last syllable stressed by default (`M-RUS-STRESS`); a CV given for a C (`M-HEB-CV-FOR-C`).
- **Response.** The count and the colours: `n=3.rbg`.
- **Courses.** All three: eng A-14, B-15, C-05 (LT06); heb A-08, A-09, B-08, B-12, B-13 (N2); rus A-18, A-19, B-09, B-12 to B-17 (R1).

#### LS04 Blend slide (new, `blend_slide`)
- **What the child does.** A written word or syllable with a mark under each grapheme (a bar under a digraph). The child slides a finger in the course's direction; each part sounds, then the whole word sounds. Then the child picks its picture or the syllable heard. The engine counts the choice; the slide is practice.
- **Modes.**
  - `graphemes` (eng sound buttons): continuous sounds are stretched into the next one, stops are clipped.
  - `merge` (rus syllable slide): the consonant tile slides to the vowel tile, the voice stretches it if it can be stretched ("ммм…ма"), and for a stop only the merged syllable is heard.
  - `units` (heb): a long pointed word is read CV unit by CV unit as each unit lights. This is also the "show me" of every Hebrew decoding item.
- **Classifiers.** Reading in the wrong direction (`M-ENG-DIR`, `M-RUS-RTL`, `M-HEB-ORDER`); first-letter guessing; vowel swap; a digraph split; a letter's name used in the blend (`M-RUS-NAME`, `M-ENG-LETTERNAME`).
- **Courses.** eng B-18, C-03 to C-10 (LT07); rus B-19 to B-22, C-01 to C-08 (R2); heb C-06 and the decoding ladder's level 3 (N3, the show-me part).

#### LS05 Change one part (new, `change_part`)
- **What the child does.** A frame with one changeable slot: a vowel sign under a Hebrew letter, a vowel letter after a Russian consonant, or an English vowel or a final e. The child turns a wheel or slides a strip, and hears the new unit or word each time.
- **Modes.** `explore` (unscored teaching screen) and `make` ("make the one you hear", scored).
- **Per language.**
  - heb: the CV wheel (גלגל סימני ניקוד). It is the teaching screen of each step S1 to S8 and the **level-2 hint of every Hebrew decoding item**.
  - rus: the vowel strip in pairs а–я, о–ё, у–ю, ы–и, э–е. It is the level-2 hint for `M-RUS-HARDSOFT`.
  - eng: the vowel swap pan, pen, pin (C-01), and "add the e" cap → cape (C-08). Optional for English.
- **Classifiers.** `M-HEB-VOWEL-SKIP`, `-VOWEL-OU`, `-VOWEL-SHAPE`, `-DOT`; `M-RUS-HARDSOFT`, `-YI`, `-YOT`; `M-ENG-AE-E`, `-E-SILENT`.
- **Courses.** heb B-19, B-21, C-01 to C-05 (N3, core); rus B-21, C-07 (R3); eng C-01, C-08 (optional).

#### LS06 Build a word (new, `build_word`)
- **What the child does.** Hears a word (with its picture) and drags tiles from a tray into slots in the course's direction. Each slot sounds when it is filled, and a tap empties a filled slot.
- **Tiles.** Letters, digraph tiles (eng), or CV tiles (heb), plus 0 to 3 extra tiles.
- **Modes.**
  - `dictation`: the word is heard, not shown.
  - `copy`: the word is shown (a scaffold; rus T05).
  - `units`: build from CV units (heb).
  - `own_name`: the child's name, on the device only (heb B-27, D25). It writes no tile codes; the response is `built` or empty.
  - `add_e` (eng).
- **Three outcomes**, one engine (the Hebrew Q2):
  - **exact**: the book spelling;
  - **sound-right**: every sound is shown, with a spelling the author listed for that item (a closed list, never worked out at runtime);
  - **not yet**: a sound is missing or wrong.
  - Whether sound-right counts as success is **set per skill** (§3.3.5). The child always hears "every sound is there!" for a sound-right answer. The book spelling is shown from the step where the course introduces it.
- **Sound-right per language.**
  - heb: a homophone letter or a missing vowel letter (`M-HEB-HOMOPHONE`); in B-28 also a partial spelling (`M-HEB-PARTIAL`).
  - eng: a spelling of a pattern not yet taught ("kat" before C-K, "berd" before C-09).
  - rus: written as heard, before the rule is taught ("дуп" before C-20, "вада" before C-21, "жыраф" before C-18).
- **Other classifiers.** `M-*-DIR` (mirrored order), `M-ENG-VOWEL-SKIP`, `M-ENG-C-K`, `M-RUS-SOFTSIGN`, `M-HEB-FINAL`.
- **Response.** Tile indexes in slot order, for example `0.3.1.2` (no letters).
- **Courses.** All three: eng B-20, C-05, C-08, C-16 (LT08); heb B-27, B-28, C-06, C-19 to C-22 (N4); rus B-25, C-16 to C-23 (R4, and T05 as a scaffold).

#### LS07 Build a sentence (new, `build_sentence`)
- **What the child does.** Puts word cards (each with a sound on tap) into a line in the course's direction, with a space between cards, to match a picture or a heard sentence.
- **Options per item.**
  - capital and punctuation tiles (eng, rus);
  - **agreement choices** on a card (rus красный / красная; heb gender and number);
  - a distractor card.
- **Correct answers.** The author lists every correct order, because two orders are sometimes right.
- **Classifiers.** `M-ENG-ADJ-ORDER`, `-COPULA`, `-PUNCT`, `-CASE`, `-WORDORDER-Q`; `M-HEB-AGREE`; `M-RUS-GENDER`, `-ACC`, `-NUMNOUN`.
- **Courses.** All three: eng C-14, C-18, C-23 (LT09); heb C-23, C-24 (N5); rus B-02, C-15, C-23, C-24, C-27, C-28 (R9).

#### LS08 Story (new, `story`)
- **What it is.** A picture book of 3 to 10 pages, original or a public-domain tale retold in our own words and pictures (D3, D18).
- **Modes.**
  - `listen`: narrated; tap a picture to hear its word; a repeated line.
  - `dialogic`: planned pauses with an LS01 question, and the answer recast by the voice.
  - `read_along`: each word lights as it is read (word timing per clip, from the voice-and-sound-director).
  - `read_first`: the child reads; after trying, a tap on a word plays it.
  - `echo`: the voice reads a phrase, the child repeats it (with LS09 per word if voice is on).
- **The end of a story.** A parent co-play card, and the questions (LS01).
- **Scoring.** Reading in the story is **unscored practice** (D22 applies in every course); the questions are scored.
- **The validator** runs the decodable check (F5) on `read_first` texts.
- **Courses.** All three: eng A-15, C-21, C-24, C-25 (LT03, LT10); heb A-01, A-02, A-12, A-13, B-01, B-04, B-06, B-18, C-11, C-12, C-15, C-18 (N1, N6); rus A-16, B-08, C-13, C-14, C-30 (R7).

#### LS09 Say it with me (new, `say_it`)
- **What the child does.** The voice says a word or chunk with its picture. There is a pause for the child, then the voice says it again.
- **With voice on** for this language (§5.1): the child taps the microphone and says it, and the per-word matcher returns **confident** or **unsure**.
- **With voice off:** an "I said it" tap, which is practice only.
- **Then** a tap on the picture to go on. This tap is a scored listening item when the author marks it.
- **Courses.** eng A-12 and every new word (LT04); rus A-15 and all vocabulary (R8); heb optional for oral language, and the speaking part of reading aloud (N6, unscored).

#### LS10 Puppet talk (new, `puppet_talk`)
- **What the child does.** A puppet speaks one turn ("How are you?", "Can I have an apple, please?", "Кто это?"). The child picks the answer bubble that fits the scene: 2 or 3 bubbles, picture-supported, each heard on tap. The puppet answers. The child may then say the bubble (an LS09 step).
- **Scoring.** The bubble choice is scored.
- **Personal turns** (D10, §5.2) are a mode of this template only, with the safeguards of §5.2.
- **Classifiers.** `M-ENG-COPULA`, `-DO`, `-WORDORDER-Q`; `M-RUS-ACC`, `-GENDER`.
- **Courses.** eng A-17, B-08, B-09, C-19 (LT05); rus A-14, C-27, C-30; heb personal turns only, if the teacher wants them.

#### LS11 Listen and do (new, `listen_do`)
- **What the child does.** Hears a command and makes the friend do it in a scene: tap a body part (hotspots), drag a thing to a place ("Положи мяч на стол"; "put the cat under the table"; "שים את הכדור על השולחן"), or tap one of 2 or 3 action buttons.
- **Embodied version.** The child does the action and taps "done". It is self-report and **never counted alone** (it is the representation `embodied`).
- **Classifier.** The wrong part or place, mapped to the course's tag.
- **Courses.** eng A-02, A-06, B-05, B-06, B-10 (LT01); rus A-03, A-04, A-14, B-05, B-06 (R6); heb A-04.

#### LS12 Sing along (new, `sing_along`)
- **What it is.** An original song, chant or rhyme. Pictures light on the key words, and the child taps the lit picture or simply joins in.
- **Rhyme mode:** a pause at the end of a line, with 2 or 3 picture choices to complete the rhyme (scored, as LS01).
- **Melodies need the owner's OK** (D3). An alphabet song on a public-domain tune is still a decision for him.
- **Courses.** eng A-01, A-13, B-22 (LT02); heb A-06, A-07 and the letter-name song (N7); rus A-17.

#### LS13 Placement game (new frame, `placement`)
- **What it is.** The shared staircase engine of §3.2. A course defines its **strands**, each a ladder of probe levels. Probes are ordinary LS01, LS03 and LS06 items with `purpose: probe` (no hints).
- **The parent questionnaire** (enums only) sets where each staircase **starts**, never the result.
- **The output** is the entry point per strand, with "assumed" priors.
- **Courses.** All three (eng §6.3, heb §9, rus R11 and §7.3).

#### LS14 Writing tray (new, `write_tray`; later, optional)
- **What the child does.** An on-screen letter tray in the course's script and direction, to write a word or a short sentence about a picture, with or without a word bank.
- **Scoring.** Constrained items are checked against the answer. **Free text is never scored, never stored past the activity, never synced.**
- **Courses.** eng C-23 later (LT11); heb C-24; rus C-24.

### 2.4 From the teachers' ids to the shared ids
| Shared | English | Hebrew | Russian |
|---|---|---|---|
| F1 to F9 | S1 to S8 | §1, §3, Q1 to Q4 | §1.1 to §1.5 |
| LS01 | T01, T03, T05, T16, T21 extensions; T14 "word stays" mode | H1, H2, H3, H5, H6 | T01, T03, T05, T16, T21 text tiles; R5 |
| LS02 | T04 + S8 (guide none) | H4 | T04 + R10 |
| LS03 | LT06 | N2 | R1 |
| LS04 | LT07 | N3 (show-me part) | R2 |
| LS05 | (new use: C-01, C-08) | N3 (wheel) | R3 |
| LS06 | LT08 | N4 | R4 |
| LS07 | LT09 | N5 | R9 |
| LS08 | LT03, LT10 | N1, N6 | R7 |
| LS09 | LT04 | N6 (speaking part) | R8 |
| LS10 | LT05 | (personal turns) | (A-14, C-27, C-30 role-play) |
| LS11 | LT01 | (A-04) | R6 |
| LS12 | LT02 | N7 | (A-17) |
| LS13 | §6.3 | §9 | R11 |
| LS14 | LT11 | (C-24) | (C-24) |

**Count:** 35 proposals become 2 extensions (LS01, LS02) and 12 new templates (LS03 to LS14; LS13 is a frame, LS14 is optional). Every LS template is used by at least two courses (LS05 is core for Hebrew and Russian, and optional for English).

### 2.5 Build order
| Wave | When | Templates | Why first |
|---|---|---|---|
| 0 | Before any course content | F1 to F9 | Everything depends on them |
| 1 (Band A of all three) | With the first course milestones | **LS01** → **LS09** (with the F7 recognisers) → **LS08** `listen` and `dialogic` → **LS11** → **LS12** → **LS10** → **LS03** drum mode → **LS13** → LS01 (g) caption after the answer (droppable to wave 2) | The owner's Q4: Band A of every land first. Band A in all three courses is listening, speaking, stories, songs and sound play. LS02 trace for Hebrew A-14 already exists. Until LS13 exists, the parent chooses the start ("from the beginning" or one step up). |
| 2 (Band B) | Before the first letter group | **LS02** copy and memory, with F6 stroke data → **LS03** full → **LS05** → **LS04** → **LS06** | D16: a letter's writing is introduced with its sound and name, so LS02 must be ready for the first letter. LS05 is Hebrew's core screen; LS04 and LS06 serve all three. |
| 3 (Band C) | Before sentences and texts | **LS07** → **LS08** `read_first` and `read_along` → (later) **LS14** | Sentences and texts come in stage 6 and later (eng), S9 and later (heb), and group 5 and later (rus) |

The qa-engineer verifies once per finished template (the owner's rule, 2026-10-30). The security-engineer reviews F4 (sync), F7 (models and microphone), LS06 `own_name`, LS10 personal turns and LS14.

---

## 3. Placement, mastery, revisits and session shape

### 3.1 Two bands: presentation and content
- **The presentation band** comes from the child's age bracket. It sets how a screen looks and paces:
  - targets and choices (Band A presentation: at most 3 choices, one instruction, no reading demand, no left and right words);
  - items per activity (3–5 / 5–8 / up to 12);
  - session length (8 / 12 / 15 minutes; a course may set a shorter default, as English Band A does with 6–8);
  - hint speed.
- **The content level** comes from mastery: which skill a child is on. A skill id's band letter is only where the skill is *usually* first taught.
- **The two are independent.** A 7-year-old new to English does `ENG-A-01` with Band C presentation: fewer items per skill, the same mastery evidence. A heritage 4-year-old may do Russian Band B sound work with Band A presentation.
- **Letters are never offered under Band A presentation**, except Hebrew A-10 to A-12 (print awareness and the child's own name).
- This is curriculum §4.1 ("placed by mastery, not by age") made explicit for the engine. It is a new field, `presentationBand`, per child and course, derived from age and overridable by the parent.

### 3.2 Placement
- **The shared rule** (curriculum §10.1, unchanged):
  - a staircase per strand: two right answers go up a level, one wrong answer goes down;
  - it stops after 2 reversals or **8 items per strand**;
  - the placement is the highest level with at least 2/3 right, **minus one unit**;
  - skipped skills are "assumed" (prior 0.85) and verified by interleaved retrieval within 2 weeks; a failed check becomes a normal target with no penalty shown;
  - every probe gets warm feedback, and no result is shown to the child;
  - the parent sees "we start here" per strand and can move it one level.
- **Language additions:**
  1. **A questionnaire answer** sets where a staircase starts, never where it ends.
  2. **A strand whose first two probes fail at its floor** stops at once, so a beginner does not get 8 failures.
  3. **The strands run across the first 2–3 visits**, oral first, never more than about 8 probe items in one visit.
  4. **Speech is never a placement probe** (§5.1). Speaking is set by the parent's answer.
  5. **A gate** (§3.3.6) is checked after placement. A child placed above a gate has it marked open.
- **Per course:**

| Course | Strands | Entry points | Notes |
|---|---|---|---|
| eng | **O** oral (listening, then chunks); **L** literacy, offered only to a child with Band B or C presentation whose parent ticked "knows some English letters" | E0 `ENG-A-01` · E1 stage 2 (stage 1 oral core assumed) · E2 `ENG-B-18` · E3 `ENG-C-01`/`C-02` · E4 `ENG-C-17` | The syllabus's "up to 10 items" becomes two strands of at most 8 each (§5.4) |
| heb | **L** oral language and phonological awareness; **C** code (letters, reading, writing) | P0 to P6 (syllabus §9): P0 A-01, A-06, A-08 (L) and A-10 (C) … P6 C-11 (C) | A P4+ reader's L strand still starts at the lowest unmastered oral skill of the age band |
| rus | **1** understanding · **2** sounds · **3** letters · **4** reading · **5** spelling; plus the **route** (new learner, heritage, reader) from the questionnaire and strand 1 | E0 `RUS-A-01` · E1 oral A-15 and B-01, PHO A-17 · E2 PHO B-09, LET B-18 · E3 REA B-23 (or C-01) · E4 REA C-08/C-12, WRI C-16 | Strands 3 to 5 are skipped for a child the questionnaire puts at "no letters"; the new-learner letters gate holds (D17) |

### 3.3 Mastery
Curriculum §10.2 applies unchanged: BKT, credit by hint level, fresh mastery (P(L) ≥ 0.95, at least 4 successes over at least 2 days, or 6 for core skills; at least 2 representations; at least 1 check, or 2 for core skills), durable mastery after a delayed check at least 7 days later with a different item, and the 2-choice guard (at most 50% of the evidence). The language additions:

**3.3.1 What the five representations mean in a language course.** This keeps the "≥ 2 representations" rule and the "level 2 changes the representation" rule meaningful.

| Representation | In a language course |
|---|---|
| `concrete` | Something the child moves: tokens (LS03), letter or word tiles (LS06, LS07), a wheel or strip (LS05) |
| `pictorial` | Hear, then choose a picture (LS01) |
| `story` | Inside a story, song, scene or dialogue (LS08, LS10, LS12) |
| `embodied` | Act it (LS11), trace or write it (LS02), say it (LS09) |
| `symbolic` | Written text: read and choose, a text stem, letter ↔ sound (LS01 text modes, LS04) |

**3.3.2 Per-group sub-skills and roll-ups** (the Hebrew Q1):
- A skill taught "group by group" is split into **real skill nodes with dotted ids**, one per group: `HEB-B-14.S1`, `.S2`, `.S4` … `.S7`; `RUS-B-24.G1` … `.G10`; `ENG-B-19.G1`, `.G2`; `ENG-C-15.G3` ….
- Each sub-skill has its own BKT, revisits and prerequisites. A decoding skill "for step Sn" depends on the sub-skills of S1 to Sn.
- The plain id (`HEB-B-14`) becomes a **roll-up**:
  - it has no BKT of its own;
  - it is fresh when all its sub-skills are fresh, and durable when all are durable;
  - as a prerequisite it means "all groups".
- `SkillNode.family` already ignores what follows the last hyphen, so the representation statistics are unaffected.

**3.3.3 Letter bundles (D16).**
- **What a bundle is.** The facets of one letter group that are introduced together form one bundle:
  - eng: `B-16` with `B-19.G1`; `B-17` with `B-19.G2`; `C-01` with `C-15.G3`; and so on;
  - heb: `B-14.Sn`, `B-15.Sn` and `B-24.Sn`;
  - rus: `B-18` with `B-24.G1`; `B-20` with `B-24.G2`; and so on.
- **How the engine treats it.**
  - A bundle unlocks as one: when the prerequisites of all its members reach 0.8.
  - Its members never require each other.
  - A bundle counts as **one** new skill against the limit of 2 per session.
  - Mastery is still tracked per member.
- **Copy and memory writing** (heb B-25 and B-26, rus B-26, eng memory mode) follow the bundle as ordinary next skills of the same group.

**3.3.4 Set coverage.**
- **The problem.** A word-set skill ("knows eight animals") could reach P(L) ≥ 0.95 on half the set.
- **The rule.** Fresh mastery also needs **each word of the set answered right at least once without a hint**, across the evidence. The same holds for letters inside a group skill.
- **Data.** Each word is a `variantGroup`. Items rotate words until coverage is met.
- **English rule kept.** At least 6 meaningful encounters of a word before the durable check of its set (eng syllabus §4.3).

**3.3.5 The sound-right outcome** (the Hebrew Q2). The engine stays three-valued (`correct`, `incorrect`, `unsure`), and LS06 maps the outcome per skill:
- **A skill that accepts sound-right** counts it as `correct`, records the tag as **on the way**, and gives no misconception evidence. These skills are heb B-28 and C-19; eng B-20 and the C-16 patterns not yet taught; rus B-25, and C-16 before C-18, C-20 and C-21.
- **A skill that teaches the convention** counts it as `incorrect`, with the tag as misconception evidence. These skills are heb C-21 and C-22; eng C-16 for taught patterns; rus C-18 to C-21.
- **New attempt field:** `detail` (`exact`, `sound_right`), an enum for the parent view ("spells every sound; learning book spelling").
- **In every case** the child's feedback names what is right first. Sound-right is never called wrong.

**3.3.6 Course gates.**
- **What a gate is.** A named condition on a set of skills, with fields: `skills` (fresh mastery required), `minAge` (a default), and a parent override switch.
- **The gates:**
  - **eng oral gate** (syllabus §6.2): A-01 to A-11, A-16, B-01, B-02, B-05, B-06, and B-12 to B-14 onset-rime. Fresh mastery is enough with Band C presentation. Never under Band A presentation. The parent's "oral only" switch keeps it closed (D6).
  - **rus letters gate** for new learners (D17): A-12 and three themes, and age 5 or more. The parent can override.
  - heb has no gate.
- **How gates act.** They hold back skills; they are never shown to the child as locks.

**3.3.7 Routes** (rus).
- **What a route is.** A per-child, per-course setting: `new`, `heritage` or `reader`. It is set by the questionnaire and strand 1 of placement, and the parent can change it.
- **What it changes:** skill priority weights (heritage: speaking, B-03, B-07, C-26, C-28); the gate (heritage and reader: no age gate); display defaults (stress marks, per D15 and rus §7.1).
- **What it never changes:** mastery rules.

**3.3.8 Speech evidence** (§5.1): limited, positive-only evidence for speaking skills, and none for any reading skill.
- **A speaking skill never blocks progress** (added 2026-11-03). The microphone is the parent's privacy choice, so a child must not be held back by it. When a speaking (SPK) skill is a prerequisite (eng A-12 → B-11; eng A-17 → B-08; rus A-01 → A-03, A-14, A-17; rus B-08 → C-27, C-30; checked by script on the three syllabi), it counts as met at **"practised"**: its practice set done (every word of its set met at least once in LS09, or by the "I said it" tap), whatever the microphone setting. Its own mastery is unchanged (§5.1).

**3.3.9 Two-choice items:** the rule of §2.3. The engine's 2-choice guard (curriculum §10.2) is unchanged; a check in a binary skill is a balanced pair.

### 3.4 Revisits
- **The schedule** is that of curriculum §5.7, unchanged: FSRS, about 1, 3, 7, 21 and 60 days, checks of 1 to 3 items interleaved into play with a different item and representation, and the re-teach after a failed check.
- **Language additions:**
  1. **Revisits stay inside their course.** A due English check is served in an English visit, or as an English stop of Today's Adventure (§3.7), never inside a Russian visit or a maths land.
  2. **Confusable pairs are revisited together.** A tag link `revisitWith` puts ב/כ, ד/ר, Н/И/П, b/d, ш/щ … in the same check (heb §10; rus §3 look-alikes; eng `M-ENG-BD`).
  3. **Every visit opens with retrieval** of earlier letters, words or a known song (all three syllabi). This is the warm-up segment.
  4. **Set coverage applies to checks.** A durable check of a word set uses words not used in its last practice.

### 3.5 Session shape
**A visit is one course.** A session started at a door, or a Today's Adventure stop in a course, contains only that course's items.

| Segment | Share | In a language visit |
|---|---|---|
| Warm-up | 1–2 items | The course's hello routine or song (LS12), and easy retrieval |
| Repair | ≤ 25% | Active misconceptions of this course, with the level-2 representation of §4 |
| Focus | 30–55% | 1 or 2 new skills (a bundle counts as one): a worked example, then guided, then independent |
| Revisit checks | 15–30% | Due checks of this course, interleaved across its strands in Bands B and C, and blocked in Band A |
| Delight | ~20% | A story, a song or a role-play; no new demands |

**Rules from the courses, kept:**
- **eng:** Band B never opens a new letter group and a new word set in the same visit. Session defaults 6–8, 10–12 and 12–15 minutes.
- **heb:** in Bands B and C a visit mixes one code activity, one listening or story activity, and one writing activity.
- **rus:** activities of 2–4, 4–7 and 6–10 minutes by presentation band.

**Unchanged:** the visit ends on success (the last item at p ≥ 0.85); there is no "one more?" prompt; the parent's daily limit ends the visit gracefully. The "mood check" of §10.3 (at least one domain the child chose) is met by the child having chosen the door.

### 3.6 Stuck and bored (curriculum §10.4), in a language course
- **Stuck** (3 errors in a row, or 2 "show me" in a row): switch to an easier related item of the **same course**, then to its delight segment. The next visit re-teaches with a new representation.
- **Repeated repairs** of the same code skill (heb §10): a gentle note in the parent area suggesting a talk with the gan teacher or the school. It gives no label.
- **Inactivity** counts only from the end of the last clip. Story pages and songs never trigger it.
- **Bored** (8 right in a row, fast, no hints): offer the next skill's challenge item. Fast-tracking runs the understanding check. Coverage (§3.3.4) still applies.

### 3.7 Today's Adventure
- **Each language turned on is a land** for the rule of curriculum §10.8 (`todays-adventure-rule.md`). The bottle can open a due language revisit or the next language lesson, under the same rules: a revisit first once a day; up to three lessons in the land played last; a lesson left after an error rests until the next day.
- **The rule's inputs gain** the course of each land and lesson.
- A course that is off is not a land.
- This is a change to the rule document (app-developer, after the owner's OK).

---

## 4. The misconception catalogue: one format for all three

### 4.1 The format
Every tag of every course becomes one record with these fields.

| Field | Meaning |
|---|---|
| `tag` | The teacher's id (`M-ENG-V-W`) |
| `id` | The engine id `<course>.<strand>.<slug>`: the course; the strand of the first skill that uses it (lowercase: eng `lis`, `spk`, `pa`, `ph`, `rd`, `wr`; heb `ol`, `pa`, `pk`, `dec`, `wr`; rus `lis`, `spk`, `voc`, `grm`, `pho`, `let`, `rea`, `wri`, `num`); the slug is the tag's remainder in lowercase with `-` → `_`. Example: `M-RUS-HARDSOFT` → `rus.pho.hardsoft`. **Precisely:** "the first skill" is the lowest skill id (band letter, then number) that names the tag in its syllabus row or in a content-batch item; a skill with a two-part strand (`LIS/SPK`, `PHO/LIS`) gives its first part; where no row names the tag (the Russian skill rows list no tags), the first skill is the one the tag's own row or template classifier points to (listed in §4.2). **An id is frozen once assigned**: a later change of skill order or strand never renames it |
| `course` | `eng`, `heb` or `rus` |
| `kind` | **diagnostic** (a wrong choice reveals it and counts as misconception evidence); **on-the-way** (accepted as success in early skills, §3.3.5; diagnostic in later ones); **accent** (speech only: never marked, never evidence, it only steers listening practice); **practice** (no signal in the app) |
| `family` | One of the 15 cross-course families below, for the parent view and shared re-teach screens. Never used to move evidence between courses |
| `skills` | The skills it traces back to, most likely first |
| `signal` | The distractor or classifier that catches it |
| `reteach` | The **level-2 representation** that repairs it (a different representation from the item's) |
| `repairActivities` | Item ids, filled by the content batch |
| `parentText`, `homeActivity` | Hebrew, written with the hebrew-text-editor (needs-editor), filled by the content batch |
| `revisitWith` | Look-alike or sound-alike partners to check together (§3.4) |

**Families:**

| Family | What it covers |
|---|---|
| **DIR** | direction |
| **NAME** | name for sound |
| **SHAPE** | look-alike letters |
| **STROKE** | letter formation |
| **CONTRAST** | sounds new to a Hebrew speaker |
| **SEGMENT** | counting and splitting units |
| **RHYME** | rhyme |
| **VOWEL** | vowel signs and vowel letters |
| **CODE** | spelling and reading conventions |
| **GRAMMAR** | grammar, and how a sentence is said (word order, agreement, place words, the plural, ты / вы) |
| **PRINT** | concepts of print: what print is (letters, not numerals, shapes or pictures, carry the words read), case, punctuation, spaces |
| **GUESS** | answering from **part of the evidence**: the first letter, part of a word's sound, a familiar picture, a name's length, the habit of always saying "yes" |
| **MEANING** | word meanings, categories and story understanding: a meaning neighbour taken for the word, grouping by theme or look instead of kind, who did what and in what order in a story (added 2026-11-03, §4.4) |
| **ACCENT** | speech-only differences |
| **FLUENCY** | reading fluency |

### 4.2 The catalogue (kind, family and engine id of every tag)
**Settled 2026-11-03**, after the three Band A batches (decisions and reasons in §4.4). The teachers' tables remain the source for each tag's signal, re-teach and `revisitWith` (eng syllabus §8, heb syllabus §5, rus syllabus §11); these tables add the kind, the family and the engine id. Each tag is defined **exactly once**.

**How the tables are made and checked.** A script reads the three syllabi and Band A batches, finds every tag a skill row or a batch item uses (the Hebrew batch's short tags, `[SEM]`, are `M-HEB-SEM`; `M-HEB-SHAPE-*` is the eight pair tags), works out each engine id by the §4.1 rule, and checks: every tag used is in exactly one row; every engine id is unique; every kind and family is in §4.1; no accent tag sits on a batch distractor. Run on 2026-11-03: **127 tags** (eng 56, heb 45, rus 26), **49 of them used in the Band A batches**; no duplicate, no unknown tag, no accent tag on a distractor. One finding: `M-RUS-COUNT` (20 uses in the Russian batch) is not adopted (§4.4), so those items change (§4.5). The script is to become a qa-engineer test over the content packs (§4.5).

"First skill" is the skill that fixes the engine id's strand. "Band A batch" marks the tags the batches use today. Rows are grouped by family.

**English** (56 tags; syllabus §8):

<!-- catalogue:eng:start -->
| Tag | Engine id | Kind | Family | First skill | Band A batch |
|---|---|---|---|---|---|
| M-ENG-DIR | `eng.ph.dir` | diagnostic | DIR | B-18 |  |
| M-ENG-WAS-SAW | `eng.rd.was_saw` | diagnostic | DIR | C-11 |  |
| M-ENG-LETTERNAME | `eng.pa.lettername` | diagnostic | NAME | B-13 |  |
| M-ENG-BD | `eng.ph.bd` | diagnostic | SHAPE | B-17 |  |
| M-ENG-LOOKALIKE | `eng.ph.lookalike` | diagnostic | SHAPE | B-16 |  |
| M-ENG-LINES | `eng.wr.lines` | diagnostic | STROKE | B-19 |  |
| M-ENG-STROKE-CW | `eng.wr.stroke_cw` | diagnostic | STROKE | B-19 |  |
| M-ENG-STROKE-RTL | `eng.wr.stroke_rtl` | diagnostic | STROKE | B-19 |  |
| M-ENG-AE-E | `eng.lis.ae_e` | diagnostic | CONTRAST | B-04 |  |
| M-ENG-IH | `eng.lis.ih` | diagnostic | CONTRAST | A-05 |  |
| M-ENG-NG | `eng.lis.ng` | diagnostic | CONTRAST | B-05 |  |
| M-ENG-S-Z | `eng.rd.s_z` | diagnostic (listening sort, C-12); accent in speech | CONTRAST | B-21 |  |
| M-ENG-SH-S | `eng.lis.sh_s` | diagnostic | CONTRAST | B-03 |  |
| M-ENG-TH | `eng.lis.th` | diagnostic | CONTRAST | A-04 |  |
| M-ENG-UH | `eng.ph.uh` | diagnostic | CONTRAST | C-01 |  |
| M-ENG-V-W | `eng.lis.v_w` | diagnostic | CONTRAST | B-02 |  |
| M-ENG-ADDVOWEL | `eng.spk.addvowel` | diagnostic | SEGMENT | A-12 |  |
| M-ENG-BLEND-LAST | `eng.pa.blend_last` | diagnostic | SEGMENT | B-14 |  |
| M-ENG-CLUSTER | `eng.ph.cluster` | diagnostic | SEGMENT | C-05 |  |
| M-ENG-SEG-SYLL | `eng.pa.seg_syll` | diagnostic | SEGMENT | B-15 |  |
| M-ENG-SYLL | `eng.pa.syll` | diagnostic | SEGMENT | A-14 | yes |
| M-ENG-WEAK-SYLL | `eng.pa.weak_syll` | diagnostic | SEGMENT | A-14 | yes |
| M-ENG-RHYME-ONSET | `eng.pa.rhyme_onset` | diagnostic | RHYME | B-12 |  |
| M-ENG-VOWEL-SKIP | `eng.ph.vowel_skip` | diagnostic | VOWEL | B-18 |  |
| M-ENG-C-K | `eng.ph.c_k` | on-the-way → diagnostic once the rule card is taught | CODE | B-17 |  |
| M-ENG-DIGRAPH-SPLIT | `eng.ph.digraph_split` | diagnostic | CODE | C-03 |  |
| M-ENG-E-SILENT | `eng.ph.e_silent` | diagnostic | CODE | C-08 |  |
| M-ENG-ER-SPELL | `eng.ph.er_spell` | on-the-way → diagnostic from C-09 | CODE | C-09 |  |
| M-ENG-OPEN | `eng.ph.open` | diagnostic | CODE | C-06 |  |
| M-ENG-OW | `eng.ph.ow` | diagnostic | CODE | C-10 |  |
| M-ENG-THE | `eng.rd.the` | diagnostic | CODE | B-21 |  |
| M-ENG-VOWELTEAM-SPLIT | `eng.ph.vowelteam_split` | diagnostic | CODE | C-07 |  |
| M-ENG-X | `eng.ph.x` | diagnostic | CODE | C-02 |  |
| M-ENG-Y-J | `eng.ph.y_j` | diagnostic | CODE | C-02 |  |
| M-ENG-ADJ-ORDER | `eng.lis.adj_order` | diagnostic | GRAMMAR | B-10 |  |
| M-ENG-ARTICLE | `eng.lis.article` | diagnostic | GRAMMAR | A-11 |  |
| M-ENG-COPULA | `eng.spk.copula` | diagnostic | GRAMMAR | A-17 |  |
| M-ENG-DO | `eng.spk.do` | diagnostic | GRAMMAR | B-08 |  |
| M-ENG-PLURAL | `eng.ph.plural` | diagnostic | GRAMMAR | C-12 |  |
| M-ENG-PREP | `eng.lis.prep` | diagnostic | GRAMMAR | B-06 |  |
| M-ENG-WORDORDER-Q | `eng.wr.wordorder_q` | diagnostic | GRAMMAR | C-18 |  |
| M-ENG-CASE | `eng.wr.case` | diagnostic | PRINT | C-13 |  |
| M-ENG-PUNCT | `eng.wr.punct` | diagnostic | PRINT | C-14 |  |
| M-ENG-SPACE | `eng.wr.space` | diagnostic | PRINT | C-14 |  |
| M-ENG-FIRSTLETTER-GUESS | `eng.ph.firstletter_guess` | diagnostic | GUESS | B-18 |  |
| M-ENG-L1-GUESS | `eng.lis.l1_guess` | diagnostic | GUESS | A-01 | yes |
| M-ENG-YESNO | `eng.lis.yesno` | diagnostic | GUESS | A-16 | yes |
| M-ENG-SEM | `eng.lis.sem` | diagnostic | MEANING | A-01 | yes |
| M-ENG-STORY-RECALL | `eng.lis.story_recall` | diagnostic | MEANING | A-15 | yes |
| M-ENG-AE | `eng.lis.ae` | accent | ACCENT | A-05 |  |
| M-ENG-H | `eng.lis.h` | accent | ACCENT | A-01 |  |
| M-ENG-O | `eng.ph.o` | accent | ACCENT | B-17 |  |
| M-ENG-R | `eng.lis.r` | accent | ACCENT | A-03 |  |
| M-ENG-SCHWA | `eng.lis.schwa` | accent | ACCENT | A-07 |  |
| M-ENG-W | `eng.lis.w` | accent | ACCENT | A-04 |  |
| M-ENG-WORD-BY-WORD | `eng.rd.word_by_word` | practice | FLUENCY | C-24 |  |
<!-- catalogue:eng:end -->

**Hebrew** (45 tags: 26 from the first syllabus, 18 added for Band A, and `M-HEB-SEM-READ` split from `M-HEB-SEM`; syllabus §5):

<!-- catalogue:heb:start -->
| Tag | Engine id | Kind | Family | First skill | Band A batch |
|---|---|---|---|---|---|
| M-HEB-ORDER | `heb.pk.order` | diagnostic | DIR | A-11 | yes |
| M-HEB-NAMESOUND | `heb.pk.namesound` | diagnostic | NAME | B-14 |  |
| M-HEB-MIRROR | `heb.wr.mirror` | diagnostic | SHAPE | B-25 |  |
| M-HEB-SHAPE-AZ | `heb.pk.shape_az` | diagnostic (`revisitWith` the pair) | SHAPE | A-11 | yes |
| M-HEB-SHAPE-BK | `heb.pk.shape_bk` | diagnostic (`revisitWith` the pair) | SHAPE | A-11 | yes |
| M-HEB-SHAPE-DR | `heb.pk.shape_dr` | diagnostic (`revisitWith` the pair) | SHAPE | A-11 | yes |
| M-HEB-SHAPE-GN | `heb.pk.shape_gn` | diagnostic (`revisitWith` the pair) | SHAPE | A-11 | yes |
| M-HEB-SHAPE-HXT | `heb.pk.shape_hxt` | diagnostic (`revisitWith` the pair) | SHAPE | A-11 | yes |
| M-HEB-SHAPE-SM | `heb.pk.shape_sm` | diagnostic (`revisitWith` the pair) | SHAPE | A-11 | yes |
| M-HEB-SHAPE-TM | `heb.pk.shape_tm` | diagnostic (`revisitWith` the pair) | SHAPE | A-11 | yes |
| M-HEB-SHAPE-VZN | `heb.pk.shape_vzn` | diagnostic (`revisitWith` the pair) | SHAPE | A-11 | yes |
| M-HEB-STROKE | `heb.wr.stroke` | diagnostic | STROKE | A-14 | yes |
| M-HEB-BLEND-FIRST | `heb.pa.blend_first` | diagnostic | SEGMENT | A-09 | yes |
| M-HEB-BLEND-LAST | `heb.pa.blend_last` | diagnostic | SEGMENT | A-09 | yes |
| M-HEB-CV-FOR-C | `heb.pa.cv_for_c` | diagnostic | SEGMENT | B-11 |  |
| M-HEB-PARTIAL | `heb.wr.partial` | on-the-way in B-28 → diagnostic in C-19 | SEGMENT | B-28 |  |
| M-HEB-SYLL | `heb.pa.syll` | diagnostic | SEGMENT | A-08 | yes |
| M-HEB-ALLIT | `heb.pa.allit` | diagnostic | RHYME | A-06 | yes |
| M-HEB-MATER | `heb.dec.mater` | diagnostic | VOWEL | C-01 |  |
| M-HEB-SHVA | `heb.dec.shva` | diagnostic | VOWEL | C-05 |  |
| M-HEB-VOWEL-OU | `heb.dec.vowel_ou` | diagnostic | VOWEL | C-02 |  |
| M-HEB-VOWEL-SHAPE | `heb.dec.vowel_shape` | diagnostic | VOWEL | C-03 |  |
| M-HEB-VOWEL-SKIP | `heb.dec.vowel_skip` | diagnostic | VOWEL | B-19 |  |
| M-HEB-DOT | `heb.dec.dot` | diagnostic | CODE | C-04 |  |
| M-HEB-FINAL | `heb.pk.final` | diagnostic (the final form is automatic in B-28) | CODE | B-17 |  |
| M-HEB-HOMOPHONE | `heb.wr.homophone` | on-the-way in B-28, C-19 → diagnostic in C-21, C-22 | CODE | B-28 |  |
| M-HEB-AGREE | `heb.ol.agree` | diagnostic | GRAMMAR | B-03 |  |
| M-HEB-PLURAL | `heb.ol.plural` | diagnostic | GRAMMAR | A-05 | yes |
| M-HEB-PREP | `heb.ol.prep` | diagnostic | GRAMMAR | A-04 | yes |
| M-HEB-ROLE-SWAP | `heb.ol.role_swap` | diagnostic | GRAMMAR | A-04 | yes |
| M-HEB-PRINT-NUM | `heb.pk.print_num` | diagnostic | PRINT | A-10 | yes |
| M-HEB-PRINT-PICTURE | `heb.pk.print_picture` | diagnostic | PRINT | A-12 | yes |
| M-HEB-PRINT-SHAPE | `heb.pk.print_shape` | diagnostic | PRINT | A-10 | yes |
| M-HEB-NAME-FIRST | `heb.pk.name_first` | diagnostic | GUESS | A-11 | yes |
| M-HEB-NAME-LENGTH | `heb.pk.name_length` | diagnostic | GUESS | A-11 | yes |
| M-HEB-SEM-READ | `heb.dec.sem_read` | diagnostic | GUESS | C-10 |  |
| M-HEB-SOUNDALIKE | `heb.ol.soundalike` | diagnostic | GUESS | A-02 | yes |
| M-HEB-CAT-ATYPICAL | `heb.ol.cat_atypical` | diagnostic | MEANING | A-03 | yes |
| M-HEB-CAT-LOOK | `heb.ol.cat_look` | diagnostic | MEANING | A-03 | yes |
| M-HEB-CAT-THEME | `heb.ol.cat_theme` | diagnostic | MEANING | A-03 | yes |
| M-HEB-SEM | `heb.ol.sem` | diagnostic | MEANING | A-02 | yes |
| M-HEB-STORY-ORDER | `heb.ol.story_order` | diagnostic | MEANING | A-13 | yes |
| M-HEB-STORY-ROLE | `heb.ol.story_role` | diagnostic | MEANING | A-01 | yes |
| M-HEB-STORY-SEEN | `heb.ol.story_seen` | diagnostic | MEANING | A-01 | yes |
| M-HEB-STORY-WORLD | `heb.ol.story_world` | diagnostic | MEANING | A-01 | yes |
<!-- catalogue:heb:end -->

**Russian** (26 tags: 16 of syllabus §11 and 10 of the 11 proposed with the Band A batch):

<!-- catalogue:rus:start -->
| Tag | Engine id | Kind | Family | First skill | Band A batch |
|---|---|---|---|---|---|
| M-RUS-RTL | `rus.rea.rtl` | diagnostic | DIR | B-19 |  |
| M-RUS-NAME | `rus.let.name` | diagnostic | NAME | B-18 |  |
| M-RUS-LATIN | `rus.let.latin` | diagnostic | SHAPE | B-18 |  |
| M-RUS-SHAPE | `rus.let.shape` | diagnostic (`revisitWith` the pair) | SHAPE | B-18 |  |
| M-RUS-HARDSOFT | `rus.pho.hardsoft` | diagnostic | CONTRAST | A-20 | yes |
| M-RUS-STRESS | `rus.pho.stress` | diagnostic | CONTRAST | B-17 |  |
| M-RUS-YI | `rus.pho.yi` | diagnostic | CONTRAST | A-20 | yes |
| M-RUS-NOTFIRST | `rus.pho.notfirst` | diagnostic | SEGMENT | A-19 | yes |
| M-RUS-SYLL | `rus.pho.syll` | diagnostic | SEGMENT | A-18 | yes |
| M-RUS-RHYME-ONSET | `rus.pho.rhyme_onset` | diagnostic | RHYME | A-17 | yes |
| M-RUS-DEVOICE | `rus.wri.devoice` | on-the-way → diagnostic from C-20 | CODE | B-25 |  |
| M-RUS-HUSH | `rus.wri.hush` | on-the-way → diagnostic from C-18 | CODE | B-25 |  |
| M-RUS-REDUCE | `rus.wri.reduce` | on-the-way → diagnostic from C-21 (and in C-11 listening) | CODE | B-25 |  |
| M-RUS-SOFTSIGN | `rus.let.softsign` | diagnostic in the C-02 ь items and from C-17 | CODE | C-02 |  |
| M-RUS-YOT | `rus.let.yot` | diagnostic | CODE | C-02 |  |
| M-RUS-ACC | `rus.grm.acc` | diagnostic | GRAMMAR | B-07 |  |
| M-RUS-GENDER | `rus.grm.gender` | diagnostic | GRAMMAR | B-03 |  |
| M-RUS-KTO | `rus.grm.kto` | diagnostic | GRAMMAR | A-12 | yes |
| M-RUS-NUMNOUN | `rus.grm.numnoun` | diagnostic | GRAMMAR | C-28 |  |
| M-RUS-TYVY | `rus.lis.tyvy` | diagnostic | GRAMMAR | A-01 | yes |
| M-RUS-SOUND | `rus.voc.sound` | diagnostic | GUESS | A-02 | yes |
| M-RUS-YESNO | `rus.grm.yesno` | diagnostic | GUESS | A-12 | yes |
| M-RUS-NUMWORD | `rus.num.numword` | diagnostic | MEANING | A-10 | yes |
| M-RUS-SEM | `rus.lis.sem` | diagnostic | MEANING | A-01 | yes |
| M-RUS-SEQ | `rus.lis.seq` | diagnostic | MEANING | A-16 | yes |
| M-RUS-R | `rus.lis.r` | accent | ACCENT | A-01 |  |
<!-- catalogue:rus:end -->

First skills set by hand (no skill row names these tags): `M-RUS-REDUCE`, `-DEVOICE`, `-HUSH` B-25 (the first LS06 skill that meets them as sound-right spellings); `-STRESS` B-17 (the "calling" skill of its re-teach); `-SHAPE`, `-LATIN`, `-NAME` B-18 (the first letter group); `-RTL` B-19 (the first LS04 slide); `-YOT`, `-SOFTSIGN` C-02 (я and ь are taught there); `-GENDER` B-03; `-ACC` B-07; `-NUMNOUN` C-28 (the skills of their re-teach); `-R` A-01 (the first say step); `M-HEB-SEM-READ` C-10 (the first reading item that uses it).

**Rules for every record.**
- **Accent tags** are never attached to a distractor and never reached by speech evidence (§5.1).
- **Grammar tags of heritage speakers** (`M-RUS-ACC`, `-GENDER`, `-NUMNOUN`) get parent texts that respect the home variety: "the school form", never "wrong Russian".

### 4.3 Gaps found (to the teachers)
| # | Course | Gap | Fix | Status (2026-11-03) |
|---|---|---|---|---|
| G1 | eng | `M-ENG-W` is used (B-04, B-05, C-20) and has no row | Add a row (w said as v alone, outside minimal pairs) or fold it into `M-ENG-V-W` | **Done**: its own row, accent |
| G2 | eng | `M-ENG-WAS-SAW` (C-11) has no row; it is written as an alias of `M-ENG-DIR` | Use `M-ENG-DIR` in C-11 | **Reversed**: it keeps its own row in family DIR (§4.4 E3) |
| G3 | eng | `M-ENG-AE / M-ENG-AE-E` share one row, but one is speech and one is choice | Two rows: AE accent, AE-E diagnostic | **Done** |
| G4 | rus | `M-RUS-R` and `M-RUS-SOFTSIGN` are named in §11 but have no row | Add both rows (signal, level-2 re-teach) | **Done**; the kind of SOFTSIGN is settled in §4.4 R4 |
| G5 | heb | Shape cues are English placeholders (syllabus §11) | With the hebrew-text-editor, before the content batch | **Done** by the teacher with the editor's wording; ע/צ, ג/נ and ט/מ keep "trace both" until the letterforms are fixed |
| G6 | all | No tag has `parentText` or `homeActivity` yet | Written with the content batch of each course, then by the editor | **Partly**: the Russian Band A tags have drafts (rus batch §3); English and Hebrew still to write |
| G7 | rus | `RUS-C-14` lists `C-27` as a prerequisite, a later number in the same band. This is not a cycle (checked by script: no cycles in any course, no missing prerequisite) | The path `sequence` must put C-27 before C-14 | Open (when the path is written) |

### 4.4 Decisions on the Band A batches (2026-11-03)
The three teachers sent their Band A batches with tag proposals and rule questions. Each decision below gives the reason, and the evidence where there is some.

**English**
- **E1. `M-ENG-SEM`: adopted, diagnostic, family MEANING** (the teacher proposed GUESS). Taking *cow* for *pig* while a set is being learnt is not a guessing strategy: the new word's meaning is not yet separate from its neighbour's, which is the normal state of a new word. Under GUESS the parent would read "guesses". It stays separate from `M-ENG-L1-GUESS` (a picture from another set, picked because it is familiar): together the two tell "does not know this word yet" from "is not listening to the English".
- **E2. `M-ENG-WEAK-SYLL`: adopted, diagnostic, SEGMENT.** The LS03 classifier maps one beat fewer to it and one beat more to `M-ENG-SYLL` (§2.3 LS03). The evidence is thin, as the teacher says: young English-speaking children leave out weak syllables, most of all a weak first syllable (banana → "nana"; Gerken 1994), and Hebrew has no reduced vowels, so an English schwa is easy to miss; no study measures this exact task. Two conditions:
  1. Every beat word is voiced with all its syllables audible ("every beat audible" in its pronunciation spec, confirmed by the listening check). Words whose count varies in ordinary speech (family, chocolate, camera, vegetable, different) are never beat items.
  2. In LS01 strip items the strips are centred on the right count when it is 2 or more (banana: 2, 3 or 4 beats), so each distractor is one beat away and carries the tag of its direction.
- **E3. `M-ENG-WAS-SAW`: stays its own tag** (my G2 proposal is withdrawn). Its signal (a whole tricky word, recognised by its look, read backwards in C-11 and C-17) and its re-teach (the tricky-word card with a left-to-right arrow and the first letter marked) differ from `M-ENG-DIR`'s (building or blending a decodable word from the right; the start dot and the slide). A different signal and a different repair make a separate record. The two share the family DIR and are revisited together (`revisitWith`). For the C-11 items (not Band A): the reversed word must be a real word that the sentence picture can show (on / no, tops / stop), or the distractor is wrong for a reason the child cannot see.
- **E4. The five vowels: adopted, with a limit.** a, e, i, o and u join §5.3's English list: their names are their long sounds (/eɪ/, /i/, /aɪ/, /oʊ/, /ju/), while the first sound taught is the short one (/æ/, /ɛ/, /ɪ/, /ɑ/, /ʌ/). Beginning spellers use letter names to write sounds (Read 1971), and names that contain a sound are the ones children lean on (Piasta and Wagner 2010), so the vowel's own name is the most likely wrong sound. **The limit:** the name is a NAME distractor (`M-ENG-LETTERNAME`) only where the target is the short sound (B-16 to C-07). From the open-syllable and final-e skills (C-06, C-08) the long sound is right ("the e makes the vowel say its name"); there the distractors are `M-ENG-OPEN` and `M-ENG-E-SILENT`.

**Hebrew**
- **H1. The 18 Band A tags: all adopted, all diagnostic**, with engine ids by the §4.1 rule. Families as the teacher proposed, except:
  - STORY-ROLE, -SEEN, -WORLD, -ORDER and CAT-THEME, -LOOK, -ATYPICAL go to the new **MEANING** family (H2), not GUESS;
  - **NAME-FIRST and NAME-LENGTH go to GUESS**, not PRINT. Knowing one's name by its first letter or its length is reading from a partial look, the way young children first "read" words before they use letters for sounds (Ehri 2005). The first letter of their own name is the letter children know best (Treiman and Broderick 1998), so NAME-FIRST is the expected cue to grow out of.
  - The others stay: SOUNDALIKE GUESS (part of a word's sound, as the first letter is part of a written word); PREP, ROLE-SWAP and PLURAL GRAMMAR; BLEND-FIRST and BLEND-LAST SEGMENT; PRINT-NUM, -SHAPE and -PICTURE PRINT, with PRINT widened to "concepts of print" (§4.1).
- **H2. MEANING: adopted as the 15th family.** Band A is mostly oral language in all three courses, and its errors are about meaning: a set neighbour, a category, a story event. None is a guessing strategy, and under GUESS a parent would read "your child guesses" about the normal state of a new word or a 3-year-old's way of grouping. With MEANING, GUESS keeps one sense (answering from part of the evidence). Members: eng SEM, STORY-RECALL; heb SEM, STORY-*, CAT-*; rus SEM, NUMWORD, SEQ.
- **H3. `M-HEB-SEM` is split in two.** Its row covered two errors with two repairs: in listening, hear the word again beside the two pictures; in reading, read again unit by unit. One tag must have one repair, and the parent texts differ ("still learning this word" and "chose from the picture instead of reading"). `M-HEB-SEM` stays the **listening** tag (MEANING; the batch's 34 uses do not change). **`M-HEB-SEM-READ`** (GUESS, `heb.dec.sem_read`) is the **reading** tag, first in C-10.
- **H4. The A-03 check: approved, with a condition.** The "say why" check could not carry two tagged distractors (its wrong options reveal nothing nameable), so the checks are A-03.7 to .9 (new pictures, an untypical member), and "why" stays unscored talk after the answer.
  - **The condition:** every scored odd-one-out **names its kind and shows the bin's picture** ("which one does not go in the animals box?"), never the bare "מִי לֹא שַׁיָּךְ?". With no kind named, the colour answer (A-03.4: the dog is the only one that is not yellow) and the theme answer are both defensible, and an unclear question must never make an answer wrong. Young children readily group things that go together; they look for things of one kind when the kind is named (Markman and Hutchinson 1984). So CAT-THEME and CAT-LOOK are evidence only in an item that named the kind.
  - "Not" is a load for 3-to-4-year-olds, so **at least one of a child's two A-03 checks is a sort** (an A-03.8 kind). The wording is the hebrew-text-editor's.

**Russian**
- **R1. The 11 proposed tags: 10 adopted, `M-RUS-COUNT` not.**
  - Families as the teacher proposed, except SEM, NUMWORD and SEQ to MEANING (H2). TYVY stays GRAMMAR (it is register; the parent view groups it with how sentences are said), and its parent text keeps the heritage rule ("the school form").
  - **Engine ids follow the §4.1 rule**, so four proposed ids change: `rus.voc.sem` → `rus.lis.sem`; `rus.voc.seq` → `rus.lis.seq`; `rus.voc.numword` → `rus.num.numword`; `rus.grm.tyvy` → `rus.lis.tyvy`.
  - **Why not COUNT.** A skipped or double-tapped object in count-and-tap is a one-to-one counting error. That is maths (the core land's `M-CNT-SKIP` and `M-CNT-DOUBLE`), not a gap in Russian, and while the child taps, the app plays the number words, so the child picks no Russian word at all. A course may not use a core tag (§1.5 invariant 2), and a course copy would put maths evidence into a Russian skill. So count-and-tap in a course is practice, and its scored step is the "how many?" choice of a number word (§2.2). The same applies to English A-04 i06 and i07, whose "T02 own classifier" would have put core tags into an English item. RUS-A-10 and A-11 keep two representations: count-then-choose is concrete, and number → set is pictorial.
  - **Number words and number knowledge.** A wrong set in a number → set item may mean the amount is not yet known in any language, not that the Russian word is unknown. The batch's representations are right and should stay: 1 to 3 in any arrangement, 4 and 5 as dice or finger patterns, 6 to 10 as ten-frames (5 and more). The NUMWORD parent text should say both ("the number word, or the amount itself, is still new").
- **R2. A 2-choice item may carry one tagged distractor: yes**, under the rule of §2.3. Checked by script on the batch: 38 Russian 2-choice items, all tagged.
  - Two skills are above half: **RUS-A-19 (6 of 11) and RUS-A-20 (10 of 16)**. Bring both to at most half, preferably with more picture minimal pairs (a20.01 to .06). Under Band A presentation, pointing to the picture of a heard word is the better evidence for a 3-to-4-year-old than a same / different judgement about syllables with no meaning. This is an assumption, to check in the owner's play tests.
  - **A tag that does not fit.** In same / different items, "different" for two identical clips (a20.11, .14, .16) is tagged `M-RUS-SOUND`, but no sound-alike explains it: it is an answer habit. `M-RUS-YESNO` is widened to "a two-way answer given by habit (да / нет, same / different)". The wrong answer on a "same" pair is YESNO; the wrong answer on a "different" pair keeps its contrast tag (HARDSOFT, YI, SOUND). The habit shows in the rate across a balanced set, as YESNO's signal already says.
- **R3. The reader route's caption after the answer: in wave 1**, as LS01 (g) (§2.3), last in the wave and droppable to wave 2. Reasons: it costs no template, it carries no demand and no score, and seeing a new word's spelling helps children remember it (Rosenthal and Ehri 2008). It appears only after the answer and never under Band A presentation.
- **R4. `M-RUS-SOFTSIGN` is diagnostic in the C-02 ь items as well: adopted.** C-02 teaches what ь does, and its items ask for the written word with or without ь for a heard word (конь / кон), so a wrong choice is evidence about the letter just taught. Two conditions:
  1. The tag's `skills` lists C-02, then the hard / soft listening skills B-13 and A-20, and `revisitWith` has `M-RUS-HARDSOFT`. A child who does not yet hear the soft end cannot choose ь, so repeated SOFTSIGN evidence first probes the listening (curriculum §5.3).
  2. No ь word is a spelling item before C-17 (B-25, C-16), so no sound-right ь outcome is needed. The F5 taught-grapheme check guards this.

### 4.5 Changes each teacher must make (through the orchestrator)
| Course | File and place | Change |
|---|---|---|
| eng | syllabus §8 | `M-ENG-SEM` and `M-ENG-STORY-RECALL`: family MEANING. `M-ENG-WAS-SAW`: add the C-11 condition (E3) |
| eng | syllabus §3.4 (the line on letters whose names do not carry their sound) | Keep the vowels; add the limit of E4 (short-sound targets only, B-16 to C-07; from C-06 and C-08 the name's sound is right) |
| eng | band-a-content ENG-A-04 i06, i07 | The counting taps become practice; add T02's "how many?" step with 3 number words heard on a tap (`M-ENG-SEM` on both distractors) as the scored part (§2.2); recount §7 |
| eng | band-a-content ENG-A-14 | i11 (banana): strips 2, 3, 4 (2 `WEAK-SYLL`, 4 `SYLL`). Drum rows list the classifier's outcomes: one-syllable words "2 beats (SYLL)"; i07 and i08 "2 beats (WEAK-SYLL); 4 beats (SYLL)". The beat words' pronunciation rows say "every beat audible" (E2) |
| eng | band-a-content §1, §7 and §8 | Mark the checks (C), as the Hebrew batch does. ENG-A-16's check is a balanced pair (§2.3). Add "no 2-choice item alone as a check" to the batch script |
| heb | syllabus §5 | Split `M-HEB-SEM`: the listening row stays; a new row `M-HEB-SEM-READ` (reading: "read again, unit by unit"). Band A tags: STORY-* and CAT-* family MEANING; NAME-FIRST and NAME-LENGTH GUESS. The note proposing MEANING becomes "adopted" |
| heb | syllabus §6 HEB-C-10 | Tag `M-HEB-SEM-READ` instead of `M-HEB-SEM` |
| heb | band-a-content A-03, §3 line i-odd | The scored odd-one-out prompts name the kind and show the bin picture (H4), with the hebrew-text-editor; at least one A-03 check is a sort |
| rus | syllabus §11 | Add rows for the 10 adopted tags (kind, family, signal, re-teach), so each tag is defined once in the syllabus. Batch §3 keeps the engine id, `parentText` and `homeActivity`. Widen `M-RUS-YESNO` to same / different (R2). `M-RUS-SOFTSIGN`: `skills` C-02, B-13, A-20; `revisitWith` HARDSOFT (R4) |
| rus | band-a-content §3 | Engine ids: `rus.lis.sem`, `rus.lis.seq`, `rus.num.numword`, `rus.lis.tyvy`. Families: SEM, NUMWORD, SEQ to MEANING. Remove `M-RUS-COUNT`. NUMWORD `parentText`: the number word, or the amount itself (R1; then the hebrew-text-editor) |
| rus | band-a-content RUS-A-10, A-11 items 01 to 05 | Counting is practice; the scored step is "how many?" with 3 number words heard on a tap (NUMWORD and SOUND tags); recount §6 (items with tagged distractors) |
| rus | band-a-content RUS-A-19, A-20 | 2-choice items at most half of each skill. The wrong answer on a "same" pair is `M-RUS-YESNO` (a20.11, .14, .16, and the a19 "same" pairs) |
| rus | band-a-content §1 "Distractors" | Point to frame §2.3. Mark the checks; no check is a single 2-choice item |
| all | the batch scripts | Use the catalogue check of §4.2 (the qa-engineer turns it into a content test) |

---

## 5. The approved changes and what they change

### 5.1 Speech recognition per word (D1, CHANGED)
**Where the microphone is used:**
- LS09 say-it;
- the say step of LS10;
- LS08 `echo` and `read_along` (reading aloud, all three courses).

**Where it is never used:**
- placement;
- any scored listening, reading or spelling item (taps decide those);
- letter sounds in isolation (the decision is per word, not per sound);
- free speech in stories;
- personal turns as a check (§5.2).

**Conditions** (the CLAUDE.md child-safety rules, unchanged):
- the parent turned voice on **for that language**;
- the language's model is installed and its hash verified (as `SpeechModel.verify` does today);
- the microphone opens only on a tap, and closes after a silence;
- recognition is streaming and on the device;
- no audio is stored, sent or played back, and no transcript is kept;
- the result is an enum.

**Matching (per word):**
- **The expected set:**
  - the target word;
  - the inflection or variant forms its teacher lists;
  - the **foils**: the item's other options and the minimal-pair partner of the target (vet for wet, люк for лук).
- **Confident:**
  - the target scores at or above the language's accept threshold;
  - it is clear of every foil by the margin (the existing `AnswerMatcher` accept and margin logic, with thresholds per language);
  - for a chunk, every key word the author marks is confident.
- **Unsure:** everything else, including a confidently heard foil and silence. There is **no "wrong" outcome** and no "did you say …?" question in a language lesson.

**Feedback.** The lines are `text-ready` (hebrew-text-editor, 2026-11-03: `שָׁמַעְתִּי:` and `בּוֹאוּ נֹאמַר יַחַד.`, the same in the three courses); the target word is a target clip.
- **Confident:** specific praise naming the word: "שמעתי: apple!" (*I heard: apple!*). It praises the saying, not the child.
- **Unsure:** "בואו נגיד יחד" (*let's say it together*). The voice models the word; there is a choral pause; then the activity moves on.
- **At most one more try,** offered by a tap and never required. There is no retry loop.
- No sound-level correction, no score, no red mark.

**Accent.**
- Accent tags (§4.2) are never judged.
- Thresholds are tuned so that a typical Hebrew-speaker accent of a correct word still comes out confident (the qa-engineer's device test, below).
- **The quiet fallback:** if more than 60% of say-it turns in a visit come out unsure, the rest of that visit's say-it steps run as echo with an "I said it" tap, with no message. A child is never asked to keep trying because a model struggles.

**Evidence:**
- **Confident** is one success for a **speaking (SPK) skill**, representation `embodied`. Speech is capped at 50% of a speaking skill's success evidence. The rest comes from comprehension taps, bubble choices or the parent's "heard it".
- **Unsure** gives **no evidence** of any kind: no result, no misconception, no lowering of P(L). It is a practice event only.
- **Reading aloud gives no mastery evidence in any course** (D22, applied to all three). Reading is scored by "read, then tap the picture".
- **With the microphone off,** speaking skills are fed only by comprehension taps, bubble choices and the parent's weekly "did you hear …?" confirmation (one success per confirmation, same 50% cap). A speaking skill that has none of these stays **"practised"**. The parent sees "practised", never "not mastered".

**Release gate per language:**
- **The test set:** the course's say-it words and their foils, read by adults on the team and, live and supervised by the owner, by children. Only **counts** are kept on the device; nothing is recorded.
- **What must pass:** at most **1 in 20** foil readings comes out confident, and most correct readings come out confident.
- **If it fails,** that language's say-it ships in echo mode until a better model passes.

**Models:**
- heb: the existing model.
- eng, rus: one on-device model each, chosen by the app-developer with the security-engineer, for licence, size, child speech and accent. sherpa-onnx publishes English and Russian zipformer models, for example `sherpa-onnx-zipformer-ru-2024-09-18` and English streaming zipformers. None is chosen yet, and keyword-spotting fit is unconfirmed.
- Each model is downloaded from the app's pack host only when that language's voice is turned on, is hash-checked, and is listed in `network_hosts.json`.
- A new package needs the owner's OK (CLAUDE.md security rule 9).

**Why so careful.** Children's speech is hard for recognisers. A 2022 systematic review (Bhardwaj et al., 76 studies) describes children's speech as acoustically and linguistically far from adult speech. Automated tools were typically under 80% accurate on words with mispronunciations (McKechnie et al. 2018). A learner's accent adds to this. So: two outcomes, both kind; a cap on evidence; and never evidence against.

### 5.2 Scripted personal questions (D10, CHANGED)
**What may be asked**, in authored LS10 `personal` turns only:
- the child's name ("What's your name?", "Как тебя зовут?");
- age;
- likes (food, animals, colours, toys, games);
- who is in the family.

**What is never asked:** where the child lives, an address, a city, the gan or school, a phone number, photos, feelings about home, or anything else. The AI tutor never asks anything personal (unchanged), and it is off in language lessons anyway (§1.6).

**How a turn works:**
1. **The puppet goes first** with its own answer ("My name is Pip. What's your name?"). The child always has a model.
2. **Choices.** The child answers by tap (pictures for likes; numbers 3 to 9 for age; family pictures) or by voice, if voice is on. There is always a **"pass"** choice: the puppet says "That's OK!" and moves on.
3. **Family pictures** offer many shapes of family: parents, one parent, grandparents, siblings, cousins, pets, and "someone else". There is no default family and no follow-up question.
4. **The puppet's reply is generic and warm** ("Nice to meet you!", "Me too!"). It does not repeat the child's name or details aloud, which also avoids paid name lines.
   - An age or a liked word may be echoed **as the target word itself** ("Five!", "Apple!"), because that is the language practice.
5. **The answer is not checked.** A name is never matched. An age or a "like" word gets the per-word confident or unsure feedback only as language practice, and only if voice is on.

**Data:**
- the answer lives only for the next line of the same turn;
- **no attempt row content** (`response` empty, `purpose: personal`), no log, no sync, no tutor, no analytics;
- it is **never used to choose later content** ("never used to profile");
- personal turns are never scored, never in placement, and never required.

**The parent** sees in each language's page that lessons may ask these four things. **The recommendation** (Q-F2, the owner's OK) is a switch to turn personal turns off; with it off, the puppet answers its own question and moves on.

**Online-safety habit.** In Band C, one scripted moment ("we don't tell an app where we live") and a parent co-play card. This is optional; the teachers decide.

### 5.3 Every letter taught whole (D16, CHANGED; D21 for Hebrew)
**The letter introduction**, the same in every course, one per letter:
1. See it big (shape).
2. Hear its **sound** in a key word with a picture. In Hebrew, a letter that cannot be stretched is heard inside a CV unit (D21). In Russian, stops are heard in a syllable. In English, stops are clipped, with no "uh".
3. Hear its **name** as a separate fact: "its name is …, it says …".
4. Watch it drawn (the dot walks the path) and **trace it** (LS02).
5. Find it among 2 or 3 letters, and pick a picture that starts with its sound.

**After the introduction:**
- **Practice mixes the four facets.** Mastery is per facet (§3.3.3 bundles). Copy and memory writing follow within the same group (D4).
- **Blending always uses sounds,** never names, in every course: "ма", not "эм-а"; "sat", not "ess-ay-tee"; בָּ, not "bet-kamats".
- **Letters whose name does not carry their sound** get an explicit "name …, sound …" line and a NAME-family distractor in their items:
  - eng: h, w, y, c, g, x; and the five vowels a, e, i, o, u, whose names are their long sounds while the first sound taught is the short one (added 2026-11-03, §4.4 E4). For a vowel, the name is a distractor only where the target is the short sound (B-16 to C-07); from C-06 and C-08 the long sound is right;
  - heb: א, ע (no sound of their own) and ו;
  - rus: ы, ь, ъ, й, and the consonants whose names put the sound last (эм, эл, эн, эр, эс, эф, ха).
- **Letters with no sound of their own** are taught by what they do: א, ע and ה at the end of a word (heb); ь and ъ (rus).

**Evidence.**
- Combined name-and-sound teaching helped preschoolers learn letter **sounds**, most clearly for letters whose names contain their sound (Piasta, Purpura and Wagner 2010; Piasta and Wagner 2010).
- The meta-analysis found little transfer of alphabet teaching alone to reading or spelling, which is why letters are always used at once in blending and building.
- The NAME-family distractors watch for the known risk of names being used as sounds.

### 5.4 Lines each teacher must change
I do not edit the syllabus files. Each line below is for its teacher, through the orchestrator.

**English: `docs/languages/english/syllabus.md`**

| Line | Now | Change to |
|---|---|---|
| 6 | "becomes final with the owner's spelling decision (§9)" | American spelling and a General American voice are decided (D5) |
| 17 | "Speaking skills (SPK) cannot be scored today: the recogniser is Hebrew only … until owner decision 4" | SPK skills get per-word confident or unsure feedback from an English on-device recogniser when the parent turns voice on (D1). Confident gives capped evidence; unsure gives none (frame §5.1). With the microphone off they stay "practised" or parent-confirmed |
| 36 (A-07) | "(characters only, never the child's own family)" | Scored items stay on the original family picture. An optional scripted personal turn "Who is in your family?" may follow (frame §5.2, LS10) |
| 41 (A-12) | "Practised (LT04 echo; unscored)" | LS09 say-it, per-word recognition when voice is on (frame §5.1) |
| 46 (A-17), 60 (B-08), 99 (C-19) | "echoes … (unscored)", "speaking practised" | The echo step is LS09 with per-word feedback. The bubble choice stays the scored evidence |
| 68 (B-16), 69 (B-17), 81 to 83 (C-01 to C-03) | Sounds only ("sees the letter and says or picks its sound") | Each letter is taught whole: shape, sound, **name** and writing together (D16, frame §5.3). Name ↔ letter items join the mastery evidence. Digraphs are named by their letters |
| 71 (B-19) | Prerequisite "B-16"; "Mastered when … from the start dot only on 2 days" | Split per group (`B-19.G1`, `.G2`) and bundled with B-16 and B-17 (no prerequisite between them). Mastery needs **memory mode** (D4); the start dot is hint level 1 |
| 74 (B-22) | "matches some letter names to letters (receptive) … only letters already known by sound" | The alphabet song and alphabet order. Names are already taught with each group |
| 93 (C-13) | "Names are of characters, not the child." | Character names in scored items. The child's own first name may be written with its capital, on the device only, with a character name as the fallback (as heb A-11, D25) |
| 95 (C-15) | "T04 from the start dot only" | LS02 trace → copy → memory per group (`C-15.G3` …); bundled with C-01 to C-03 |
| 156 (§3.4) | "Letter sounds first; letter names from stage 3 through the alphabet song (B-22) …" | Names are taught with sounds for every letter (D16). "The child is never asked to read by names" stays: blending uses sounds |
| 191 (§4.2) | "What's your name? … (for a puppet only)"; "How old are you? … (for a puppet or a picture of candles)" | Also asked of the child in scripted personal turns (D10, frame §5.2) |
| 193 | "The app never asks the child's own name, age, address or family …" | Scripted lessons may ask name, age, likes and family; the answer stays on the device and is never stored, sent or used. "Where do you live?" and addresses stay out (D10) |
| 210 to 211, 214 (W2, W3, W6) | "T04 full guide → start dot only"; W3 "from the start dot only" | LS02 trace → **copy** → **memory** (D4) |
| 238 (§6.3) | "up to 10 items" | Two strands (oral, literacy), at most 8 items each (frame §3.2) |
| 281 (M-ENG-LETTERNAME) | Re-teach: "sounds first; names only in the alphabet song" | Re-teach: "the name is …, the sound is …", both said; blend with sounds |
| 91 (C-11), 267, 270 (§8) | Gaps G1 to G3 (`M-ENG-WAS-SAW`; no `M-ENG-W` row; AE and AE-E in one row) | As frame §4.3 |
| 318 to 325 (§9) | Four open decisions | Decided: D5, D6, D7, and D1 (CHANGED). Point to `decisions-2026-11-03.md` |

**English: `docs/languages/english/templates.md`**

| Line | Change |
|---|---|
| 18 (S6) | "No English voice answers yet" → an English on-device recogniser, per-word confident or unsure (frame §5.1, F7) |
| 31 (T04) | Add the **copy** mode (LS02) beside `guide: none` |
| 42, 46 to 56 | Rename LT01 to LT11 to the shared ids (frame §2.4) |
| 49 (LT04) | "Unscored (S6) … If an English recogniser is approved later" → LS09 rules (frame §5.1) |
| 50 (LT05) | "**Never asks the child's own details**" → only in scripted personal turns with the safeguards of frame §5.2 |

**Hebrew: `docs/languages/hebrew/syllabus.md`**

| Line | Now | Change to |
|---|---|---|
| 15 | "Every piece of evidence is a tap, drag or trace. A spoken answer or reading aloud never counts against a child, and does not count for mastery either" | Keep the rule. Add: when the parent turns voice on, reading aloud and say-it get per-word confident or unsure feedback from the Hebrew recogniser (D1), still with no mastery evidence (D22, frame §5.1) |
| 159 (B-14), 160 (B-15), 169 (B-24) | B-15 prerequisite "B-11, B-14 (same group)"; B-24 prerequisite "A-14, B-14 (same letter)" | A **bundle** per group: `B-14.Sn`, `B-15.Sn` and `B-24.Sn` open together, with no prerequisite between them (B-15.Sn keeps B-11; B-24.Sn keeps A-14), and count as one new skill (frame §3.3.3, D16). Track B-24, B-25 and B-26 per group too (`.Sn`) |
| 173 (B-28) | "tags M-HEB-PARTIAL, M-HEB-HOMOPHONE are 'on the way', not wrong" | Keep. This is the LS06 sound-right outcome for B-28 (frame §3.3.5), no change of meaning |
| 233 to 241 (§9) | Two strands | Confirmed: LS13 with strands L and C (frame §3.2) |
| §5 | Shape cues in English | G5 (frame §4.3) |

**Hebrew: `docs/languages/hebrew/templates.md`**

| Line | Change |
|---|---|
| 34 (H4) | Becomes LS02 (shared), unchanged in substance |
| 42 (N6) | Add: per-word confident or unsure feedback when voice is on (LS09 inside LS08 `echo`); still unscored |
| 59 to 62 (§4) | Answered in frame §7 |
| H1 to H6, N1 to N7 | Rename to the shared ids (frame §2.4). N3 splits into LS05 (the wheel) and LS04 `units` (the show-me reading) |

**Russian: `docs/languages/russian/syllabus.md`**

| Line | Now | Change to |
|---|---|---|
| 25 (SPK) | "Speaking (modelled, echoed, never scored by a recogniser; §8)" | Per-word confident or unsure feedback from a Russian recogniser when voice is on (D1); capped evidence (frame §5.1) |
| 37 (§2.3) | "Letter **names** wait until Band C (C-25); the child learns sounds." | Each letter is taught whole: shape, sound, name and writing (D16). Blending always uses the sound, never the name |
| 40 (§2.6) | "trace with a guide, then a start dot only, then **write from memory**" | Trace → **copy** → write from memory (D4, LS02) |
| 139 (§7.1, stress marks) | New learner: on new words; heritage and reader: off | Confirm against D15 ("only in the stress skills and on new words in early reading; a parent switch"). I read D15 as approving these route defaults; the orchestrator should confirm with the owner (frame §8, Q-F4) |
| 158 (§7.3) | "Speaking is not placed (no Russian recogniser)" | "Speaking is not placed by the recogniser (frame §3.2); the parent's answer sets it" |
| 160 to 161 (§8) | "Speaking without a Russian recogniser … never scored" | Rewrite to frame §5.1 (D1). Keep the "I said it" tap and the parent's weekly confirmation for when the microphone is off |
| 188 (A-15), 208 (B-08), 259 (C-30) | "§8: practised, parent confirms" / "(practised, §8)" | LS09 or LS10 say step with per-word feedback; capped speech evidence plus a parent confirmation or comprehension |
| 216 (B-18), 218, 219, 220, 230 to 235 (groups) | "sound ↔ letter" | Add the name both ways, and bundle each group with `B-24.Gn` (frame §3.3.3) |
| 222 (B-24) | Prerequisite "B-18 (each group as taught)" | `B-24.G1` to `.G10`, each bundled with its letter group, with no prerequisite between them |
| 224 (B-26) | Memory writing straight after tracing | Add the **copy** step before it (D4): B-24 copy mode or B-26's first representation |
| 254 (C-25) | "Knows letter names and alphabetical order" | "Knows alphabetical order" (the names are already known) |
| 264 to 281 (§11) | Gap G4 | Add rows `M-RUS-R` (accent) and `M-RUS-SOFTSIGN` |
| 286 (§12) | "Scoring speech: no Russian recogniser" | Remove; replaced by frame §5.1 |
| 291 to 299 (§13) | Nine open decisions | Decided (D11 to D18; Q4 is CHANGED by D1; Q7 is CHANGED by D16). Point to `decisions-2026-11-03.md` |
| 243 (C-14) | Prerequisite C-27 (a later number) | Keep, and order the path so that C-27 comes first (G7) |

**Russian: `docs/languages/russian/templates.md`**

| Line | Change |
|---|---|
| 20 (T04) | "Code: none expected" → LS02 copy and memory modes and the free-stroke check are code |
| 39 (R8) | "No recording, no recogniser, no score … Optional later: a Russian recogniser" → LS09 with per-word feedback (frame §5.1); still no recording |
| 41 (R10), 42 (R11) | Become LS02 memory mode and LS13 |
| R1 to R11 | Rename to the shared ids (frame §2.4) |

**Also outside the teachers' files** (for the orchestrator, after the owner approves this frame):
- PLAN.md: the lands table gets an 8th land; "every character speaks in its own voice, everywhere" gets the language exception (§1.3).
- PLAN.md and CLAUDE.md: "Fonts are Heebo and Secular One only" changes once the design-director's fonts are approved (D1, D8, D24).
- `docs/curriculum.md`: §10 gets the presentation band, bundles, sub-skills, set coverage, sound-right, gates and per-course revisits; §11.2 notes that the tutor is off in language lessons and that scripted personal turns are not the tutor. **Done 2026-11-03** (curriculum §10.9, §11.2, and a pointer in §5.2).

---

## 6. The order of milestones
Every milestone has its own plan file and the owner's OK before code (CLAUDE.md workflow). Paid voice steps are run by the owner only. The qa-engineer verifies once per finished feature; the security-engineer reviews sync, models, the microphone, personal turns and packs.

| # | Milestone | Content | Owners | Depends on |
|---|---|---|---|---|
| L0 | **The category shell** | F4 course id (engine, packs, progress, sync, validator invariants §1.5); F8 the land, the doors, the parent pages; F9 engine additions (§3); Today's Adventure inputs; `tutor-turn` refuses language items | app-developer, design-director (land, doors), curriculum-expert (rules), security-engineer | the owner's OK of this frame |
| L1 | **Text, direction and fonts** | F1 runs, F2 fonts (design audit of Heebo; Latin and Cyrillic teaching fonts chosen and shown to the owner), F5 validator checks, **LS01** | design-director, app-developer | L0 |
| L2 | **Voices and clips** | F3 two-clip lines; the three voice pilots (the voice-and-sound-director plans them with character counts; **the owner runs and pays**); the isolated-sound test (D2) | voice-and-sound-director, owner, teachers (listening check), hebrew-text-editor | can run alongside L0 and L1 |
| L3 | **Recognisers and say-it** | F7 English and Russian models (choice, licence, hashing, download, network hosts, the owner's package OK); per-word matcher; release gate per language; **LS09**; LS10 personal mode | app-developer, security-engineer, qa-engineer | L0 |
| L4 | **Band A templates** | **LS08** listen and dialogic, **LS11**, **LS12**, **LS10**, **LS03** drum, **LS13** | app-developer, design-director | L1 (LS01) |
| ENG-1 · HEB-1 · RUS-1 | **Band A of each course, in parallel** | Each teacher's content batch on the shared templates; Hebrew frame lines by the hebrew-text-editor; voicing by the owner | each teacher, hebrew-text-editor, design-director (pictures), voice-and-sound-director | L0 to L4 (L3 only for say-it with recognition: Band A can ship with echo mode if L3 is late) |
| L5 | **Band B templates** | **LS02** trace, copy and memory with F6 stroke data for three scripts; **LS03** full; **LS05**; **LS04**; **LS06** | app-developer, design-director (stroke paths) | L4 |
| ENG-2 · HEB-2 · RUS-2 | **Band B of each course, in parallel** | Letters by bundle, first reading and building | teachers and the team | L5 |
| L6 | **Band C templates** | **LS07**; **LS08** read_first and read_along (word timing per clip); LS14 later | app-developer | L5 |
| ENG-3 · HEB-3 · RUS-3 | **Band C of each course, in parallel** | Sentences, texts, conventions; the Hebrew unpointed bridge as an extension (D26) | teachers and the team | L6 |

**Independence (D5).** From ENG-1, HEB-1 and RUS-1 on, the three courses never wait for each other's content. A late course does not hold the others. Only the shared waves (L4, L5, L6) are shared dependencies, and each is built once.

---

## 7. Answers to the teachers' questions

**English (templates.md §5, syllabus line 325).**
1. *The LT ids, and are LT01 to LT10 shared Languages templates?* Yes. They are now LS01 to LS14 (§2.4). LT01 → LS11, LT02 → LS12, LT03 and LT10 → LS08, LT04 → LS09, LT05 → LS10, LT06 → LS03, LT07 → LS04, LT08 → LS06, LT09 → LS07, LT11 → LS14.
2. *S7, a course id in the engine?* Yes: `course = eng` on skills, items, tags, placement, progress and packs, with the invariants of §1.5.
3. *The check against the shared engine.*
   - The graph has 65 skills, no cycle, and no missing or forward prerequisite (checked by script on 2026-11-03).
   - The limit of 2 new skills per visit holds, with a letter bundle counting as one.
   - Two changes are needed: B-19 and C-15 become per-group sub-skills bundled with their letter groups (§3.3.2, §3.3.3), and placement uses two strands of at most 8 items (§3.2).

**Hebrew (templates.md §4).**
1. *Sub-skills per letter group: one id or ~14 more?* Each group is its **own skill node** with a dotted id (`HEB-B-14.S1`), with its own BKT, revisits and prerequisites. `HEB-B-14` becomes a **roll-up**: it has no BKT, is mastered when all its groups are, and as a prerequisite means "all groups". Decoding skills for step Sn depend on the sub-skills of S1 to Sn. Do the same for B-15, B-24, B-25 and B-26, and bundle B-14.Sn, B-15.Sn and B-24.Sn (§3.3.2, §3.3.3).
2. *The "sound-right" outcome.*
   - The engine stays three-valued. LS06 classifies **exact / sound-right / not yet** against the author's closed list of sound-right spellings for each item. Each skill says whether sound-right counts as `correct` (on the way: B-28, C-19) or `incorrect` (misconception evidence: C-21, C-22).
   - A new attempt field, `detail`, records it for the parent view.
   - The response code is tile indexes only.
   - The child never hears "wrong" for a sound-right answer (§3.3.5).
3. *Two placement strands in one course?* Yes. LS13 takes any number of strands per course, each a staircase with its own entry. L and C are placed separately, and the L strand of an early reader still starts at the lowest unmastered oral skill of the age band (§3.2).
4. *The Languages category frame?* §1. One land with a door per course; its own path, progress, placement and voice; the course id on everything; and no link to the other lands or to the other courses.

**Russian (templates.md §4 and the hand-off line 51).**
1. *How R1 to R11 sit in the shared engine.* R1 → LS03, R2 → LS04 `merge`, R3 → LS05, R4 → LS06 (T05 as its `copy` mode), R5 → LS01 `text stem` (yes, a T01 mode; "read to me" is hint level 1), R6 → LS11, R7 → LS08, R8 → LS09, R9 → LS07, R10 → LS02 `memory`, R11 → LS13. The English and Hebrew courses use R1, R2, R4, R5 and R7 too, as the teacher expected.
2. *R11: reuse the placement frame?* Yes. LS13 is curriculum §10.1 with strands, routes and the questionnaire. Five staircases run across the first 2–3 visits. A strand stops at once if its first two floor probes fail, and the questionnaire skips the letter strands for a child with no letters (§3.2).
3. *R7: word-level timing.* The frame requires per-word timing for `read_along`. Whether it comes from the voice vendor's timestamps or is marked by hand is the voice-and-sound-director's answer.
4. *Build order (templates §4).* Kept in spirit, inside the shared waves (§2.5). Russian Band A needs LS01, LS11, LS08, LS09 and LS12 (wave 1); its Band B core (R1, R2, T04 letters) is wave 2.

---

## 8. Questions for the owner (from this frame)

**APPROVED by the owner on 2026-11-03:** this frame as a whole, and every recommendation below (Q-F1 to Q-F5). Also approved the same day: font option B ("Nitznutz Letters", from Andika, `docs/languages/fonts.md`), fontTools as a dev-only build tool, the Hebrew letter names יוּד, קוּף, וָו and זַיִן, the course's new words, and model files by cable (`adb push`) until the project's own storage hosts them. The owner: "there is a lot of work to do even without the voicing, so let's start": L0 and L1 start now.
| # | Question | Recommendation |
|---|---|---|
| Q-F1 | When a child profile is set up, are the three languages on by default, or does the parent tick them? | Ask once at setup, with each language pre-ticked and one line each saying what it is. The Russian questionnaire follows if Russian is ticked |
| Q-F2 | A parent switch for personal questions in lessons? | Yes, on by default (D10 stands). It is a cheap safety valve for families who prefer it off |
| Q-F3 | Where the Languages island sits on the map | Next to the home island. The design-director shows options |
| Q-F4 | D15 (Russian stress marks): do the route defaults of the syllabus stand (new learner on; heritage and reader off), with the parent switch? | Yes, as the teacher recommended |
| Q-F5 | The AI tutor is off in language lessons (RuleTutor only) | Yes: no target-language text may reach a child without its teacher's approval |

---

## 9. Sources
- The owner's decisions: `docs/languages/decisions-2026-11-03.md`; `docs/languages/README.md`.
- The three syllabi, templates files and research reports (cited there in full); `docs/curriculum.md` §4.1, §5.7, §6.1, §10, §11.2; `app/lib/engine/types.dart`, `app/lib/speech/answer_matcher.dart`, `app/lib/speech/model_spec.dart`, `app/lib/play/response_code.dart` (read 2026-11-03).
- Piasta, S. B. and Wagner, R. K. (2010). Developing early literacy skills: a meta-analysis of alphabet learning and instruction. *Reading Research Quarterly* 45(1), 8–38. And Piasta, Purpura and Wagner (2010), Fostering alphabet knowledge development: a comparison of two instructional approaches, *Reading and Writing* (combined name and sound teaching helped letter-sound learning; the benefits did not generalise to other emergent literacy skills). Summaries: [Reading Rockets](https://readingrockets.org/resources/resource-library/fostering-alphabet-knowledge-development-comparison-two-instructional), [ERIC](https://files.eric.ed.gov/fulltext/ED583491.pdf).
- Bhardwaj, V. et al. (2022). Automatic Speech Recognition (ASR) Systems for Children: A Systematic Literature Review. *Applied Sciences* 12(9), 4419. [MDPI](https://www2.mdpi.com/2076-3417/12/9/4419).
- McKechnie, J. et al. (2018). Automated speech analysis tools for children's speech production: a systematic literature review (accuracy typically under 80% on words with mispronunciations). [Figshare](https://figshare.com/articles/Automated_speech_analysis_tools_for_children_s_speech_production_A_systematic_literature_review/6808892).
- sherpa-onnx pre-trained models, including English and Russian zipformers; keyword spotting documented. Fit for children and for keyword spotting is not yet confirmed. [k2-fsa docs](https://k2-fsa.github.io/sherpa/onnx/pretrained_models).
- For the catalogue decisions of §4.4 (2026-11-03):
  - Read, C. (1971). Pre-school children's knowledge of English phonology. *Harvard Educational Review* 41(1), 1–34 (children's early spellings use letter names for sounds). [UW–Madison](https://langsci.wisc.edu/staff/charles-read).
  - Gerken, L. (1994). A metrical template account of children's weak syllable omissions from multisyllabic words. *Journal of Child Language* 21, 565–584 (weak syllables dropped most often at the start of a word). [Arizona](https://experts.arizona.edu/en/publications/a-metrical-template-account-of-childrens-weak-syllable-omissions-/).
  - Markman, E. M. and Hutchinson, J. E. (1984). Children's sensitivity to constraints on word meaning: taxonomic versus thematic relations. *Cognitive Psychology* 16, 1–27 (children group by theme freely, and look for a kind when a word for it is given).
  - Treiman, R. and Broderick, V. (1998). What's in a name: children's knowledge about the letters in their own names. *Journal of Experimental Child Psychology* 70(2), 97–116 (the first letter of the child's own name is known best). [PDF](https://sites.wustl.edu/treiman/files/2020/02/Treiman-Broderick-1998-Whats-in-a-name.pdf).
  - Ehri, L. C. (2005). Learning to read words: theory, findings, and issues. *Scientific Studies of Reading* 9(2), 167–188 (the pre-alphabetic phase: words recognised by a salient visual cue).
  - Rosenthal, J. and Ehri, L. C. (2008). The mnemonic value of orthography for vocabulary learning. *Journal of Educational Psychology* 100(1), 175–191 (seeing a new word's spelling helps children remember the word).
- Evidence that is thin, said plainly:
  - **`M-ENG-WEAK-SYLL`** (§4.4 E2) rests on studies of children's own speech, not of beat counting by Hebrew-speaking learners.
  - **Same / different judgements** being harder than picture pointing for 3-to-4-year-olds (§4.4 R2) is my working assumption, to check in the owner's play tests.
  - **One person, one language** (§1.3) is common practice, but the evidence that young learners need it is mixed, so it is only the voice fallback.
  - **The 60% unsure fallback and the 1-in-20 false-confident bar** (§5.1) are starting values to tune on the device, not research numbers.
