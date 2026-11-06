# The Russian course: Band B pilot slice (RUS-2b, letter group 1: А У О М)

*Owner: russian-language-teacher. Draft 2026-11-06, step **L5-2c** of `docs/milestones/L5.md` (approved by the owner on 2026-11-06 with every recommendation of its §13). For the curriculum-expert (frame), the hebrew-text-editor (the Hebrew frame lines and parent texts, all `needs-editor`), the design-director (the pictures, §7) and the voice-and-sound-director (the clip list, §8; free plan only). Plan only: nothing here is built or voiced. **Voices come later** (owner, 2026-11-06): every spoken line is written as text with its clip id and stays in `voPending` until the owner voices the course.*
*Built on: `syllabus.md` (B-18, B-19, B-24, B-26; §3 letter order, §3.1 letter names, §4 decodable words, §7.1 routes and stress marks, §11 tags), `templates.md`, frame `docs/languages/frame.md` (§2.3 templates and the 2-choice rule, §3.3 mastery and bundles, §4 catalogue, §5.3 the letter taught whole), L5 §5 (the template specs), §6 (rule E-1) and §8 (what the slice holds), `docs/languages/strokes.md` §5.2 (the Cyrillic stroke set, `teacher-checked`), and the Band A batch `band-a-content.md` (the format copied here).*

## 1. How the slice works

**What it holds** (L5 §8): the group 1 bundle and what follows it.

| Skill | What | Templates | Items |
|---|---|---|---|
| RUS-B-18 ● | Letters А У О М (capital and small) whole: shape, sound, name | LS02 `intro` (unscored); LS01 text faces, sound buttons, text stem, **tap-all**, `match_pairs` with text faces | 4 intros + 18 |
| `RUS-B-24.G1` | Tracing the 8 forms (bundled with B-18) | LS02 `trace` (`guide: start`) | 8 (practice, E-1) |
| `RUS-B-26.G1` | Copy, then write from memory, cued by the sound or the name | LS02 `copy` (`model: beside`), `memory` (`cue: sound | name`) | 12 |
| RUS-B-19 ● | Merge М with a vowel: ма мо му, and ом; read ма́ма, ау́, му | LS03 1.1 `boxes`; LS04 `merge`; LS01 (d) text stem | 9 |

**Not in the slice:** B-25 (its prerequisites are B-14 and B-20, group 2); LS05 as an item (the Russian strip is B-21, group 3; here it appears only as the level-2 hint of B-19, L5 §5.9); LS06 and LS08 `echo` (RUS-2a and later sub-batches); B-02 and B-07 (RUS-2a; they use LS01 now and LS07 later, owner's Q5, so nothing of them is in this slice).

**The bundle** (frame §3.3.3; L5 E-2). `B-18` and `B-24.G1` open together on B-18's prerequisite (B-12) and count as one new skill in a visit. The four `intro` items come first (А, У on the first visit, О, М on the next), then the facets mix. `B-26.G1` follows as the next skill of the same group (its prerequisite is `B-24.G1`); B-19 follows B-18.

**Every letter is taught whole** (D16, frame §5.3). Each intro shows the letter big (capital and small), plays its **sound** and a key word with a picture, then its **name** as a separate fact with the syllabus carriers (`קוֹרְאִים לָהּ` + name, `וְהִיא אוֹמֶרֶת` + sound, §3.1, `text-ready`), then the dot walks the path and the child traces once. After the intro the four facets mix: sound → letter, letter → sound, name ↔ letter, letter → picture, plus find the letter in a row and capital ↔ small.
- **Name = sound for А, У, О** (syllabus §3.1): for these three the name line plays the same clip as the sound (`snd-a` twice), which teaches that a vowel letter says its name. So their name facet is met by their sound items; only **М (эм)** has separate name items (b18.09, b18.10) and a NAME distractor (the name blend "эм-а", the picture э́му).
- **Blending uses the sound, never the name** ("ма", not "эм-а"). The name blend is only ever a distractor button (`nb-*` clips), tagged M-RUS-NAME, and its level-2 re-teach says both lines: "its name is эм, it says ммм".

**Print letters only** (D13). Every form is a print form of the Cyrillic stroke set (`content/languages/strokes/cyrillic.json`, `teacher-checked`); letter tiles are drawn in the course font (Nitznutz Letters).

**Stress marks** (D15, syllabus §7.1). None of these skills is a stress skill, and all come before B-23, so **no stress mark is shown on screen on any route**: the text stem shows `мама`, `ау`, `му`. Stress is written (U+0301) only in the voice text and the specs (`ма́ма`, `ау́`), and a mark never goes on ё (none here).

**Two clips per line** (F3): a Hebrew frame clip (§2, `FB01` to `FB27`, plus the Band A `F02` and `F36` and the syllabus carriers `F-NAME`, `F-SAYS`), then a Russian clip. A Hebrew clip never contains a Russian sound or word.

**Presentation** (Band B): up to 4 choices (6 cards in a tap-all row), 5 to 8 items an activity, activities of 4 to 7 minutes, visits of 12 minutes by default. Letter and syllable tiles are left to right inside the right-to-left screen (F1); the slide, the boxes and the tile rows always run left to right.

**Distractors** (frame §2.3). Every scored choice item has tagged distractors (two in a 3-choice item; one in a 2-choice item). 2-choice items: 3 of B-18's 18 scored items (b18.05 to .07, letter → sound for the vowels), never a check, one retry only. Free-response items (LS02 copy and memory, LS03) have classifiers (L5 §5.2, §5.3); an error they cannot name is a retry with no tag.
- **Look-alike letters as distractors.** Some letter-choice items use print look-alikes the child has **not** been taught yet (Л Д for А, Ч for У, С for О, Н Л И for М), tagged M-RUS-SHAPE. The child needs only to know the target to reject them; the look-alikes are kept apart in the letter order on purpose (syllabus §3), and a SHAPE error puts the pair on `revisitWith`, so it comes back when the partner is taught. *To confirm with the curriculum-expert:* the F5 decodable check is for words; a single untaught letter as a SHAPE distractor in a LET skill must be allowed by the validator.
- **а and о** are paired as sound-alikes (M-RUS-SOUND) on purpose: unstressed о is said [ɐ] in Russian speech (молоко́ [məlɐˈko]), so a child who hears Russian at home links the letter О with an "а" sound; isolated and stressed, they must be told apart. **о and у** are the two rounded vowels (as וֹ / וּ in Hebrew, M-HEB-VOWEL-OU): also M-RUS-SOUND.
- Words with an **unstressed first vowel** (окно́ [ɐkˈno], арбу́з [ɐrˈbus], оса́) are never a key word or an option for a vowel letter here: their first sound is not the letter's sound.

**Checks and probes.** **C** marks an understanding or delayed check (3 choices, or a tap-all row; never a 2-choice item): 3 for each core skill (B-18, B-19). **P** marks a placement probe for the Band B levels (strand 3 letters: b18.04; strand 4 reading: b19.07).

**Coverage** (frame §3.3.4, L5 E-3). B-18 is fresh only when every letter of the group is right once without a hint in each facet: sound → letter (b18.01 to .04), letter → sound (.05 to .08), name ↔ letter (М: .09, .10; А У О through their sound items), letter → picture (.11 to .14), capital ↔ small (.18). B-19: ма, мо, му each right once (b19.03 to .05). B-26.G1: every form right once in memory mode (b26g1.05 to .12).

**Writing and rule E-1** (L5 §6, owner's Q1). Trace answers (B-24.G1) are practice: `B-24.G1` counts as met when each of the 8 forms has been traced once with the start dot only (b24g1.01 to .08), and it never blocks. Copy successes count like a level-1 hint; memory successes count in full; `B-26.G1` is fresh only with memory successes on two days, one cued by the sound and one by the name. **For А, У, О the sound and the name are one clip**, so the two cues coincide; I propose that for a name = sound letter the two representations be met by its **two forms** (the capital and the small letter written from memory, on different days). For М the cues are separate (b26g1.11 sound, b26g1.12 name). → curriculum-expert, as part of the E-1 spec (L5-2a).

**Representations** (frame §3.3.1). B-18: `symbolic` (letter ↔ sound, name, tiles, pairs) and `pictorial` (letter → picture, where the choice is among pictures whose words play on tap). B-19: `symbolic` (the slide and the text stems) and `concrete` (LS03: the syllable laid out as two chips, the analysis the merge is built on, Zhurova's method). B-24.G1, B-26.G1: `embodied`, with E-1's cues as the two representations.

**Routes** (syllabus §7.1, frame §3.3.7). The items are the same for every route; the routes change the gate, the support and the pace.
- **New learner (N):** the letters gate (D17: A-12 and three themes, and age 5 or more, parent override) holds the whole slice. Five words are new to Band A and get an LS09 **teach screen** first (the picture, the word twice with F05 between): а́ист, о́блако, мак, му́ха, э́му. The other picture words (у́тка, мышь, кот, дом, нос, ко́шка, коро́ва, ма́ма, па́па, ба́бушка) are Band A words. Reading items (b19.07 to .09) use only words whose meaning is known (ма́ма is A-02; ау́ and му are taught by their pictures in b19.01 and the teach screen of b19.08, below).
- **Heritage (H):** no age gate; letters as soon as B-12 is mastered. No teach screens (a word the child does not know, such as э́му, is heard on a tap of its picture). The same items.
- **Reader (R):** placed by strand 3 and 4 probes (b18.04, b19.07); usually tests out of the slice and starts later. If served, as heritage.

**Pictures.** Original art only; ids are proposals for the design-director (§7). Option pictures in a letter → picture item play their word on tap (LS01 b), so the child judges the first sound of a word heard, not guessed. In a **text stem** (reading) item the option pictures do **not** play their words, so the item stays a reading item; "read it to me" is hint level 1 and lowers the credit to 0.8.

**Feedback.** Right: the app's praise line, then the Russian target clip again (a recast). Not yet: the gentle line and the next hint. Never "wrong", never red; a stroke that misses fades softly and the start dot comes back (L5 §5.2).

## 2. Hebrew frame lines (drafts, `needs-editor`)

Unpointed drafts for the hebrew-text-editor, who adds the nikud and the voice text. Plural, gender-neutral, no Russian inside a Hebrew clip; "האות" is feminine. The lines already final are reused as they are.

| Id | Hebrew (draft) | Used in | Review |
|---|---|---|---|
| F02 | הַקְשִׁיבוּ שׁוּב. | hint level 1 (Band A line) | text-ready |
| F36 | הִסְתַּכְּלוּ עַל הַפֶּה. | B-18 hint level 2 (the mouth picture; Band A line) | text-ready |
| F-NAME | קוֹרְאִים לָהּ: (voice text `קוראים לה:`) | intro step 3; NAME re-teach; carrier before the name clip | text-ready (syllabus §3.1) |
| F-SAYS | וְהִיא אוֹמֶרֶת: (voice text `והיא אומרת:`) | intro step 3; NAME re-teach; carrier before the sound clip | text-ready (syllabus §3.1) |
| FB01 | הנה אות חדשה. | intro step 1 (the letter big) | needs-editor |
| FB02 | זו האות הגדולה, וזו האות הקטנה. | intro step 1 (capital, then small, each lights) | needs-editor |
| FB03 | הקשיבו לצליל שלה: | intro step 2, carrier before the sound clip | needs-editor |
| FB04 | כמו בהתחלה של: | intro step 2, carrier before the key word (held first sound) | needs-editor |
| FB05 | הסתכלו איך כותבים אותה. | intro step 4 (the dot walks the path) | needs-editor |
| FB06 | עכשיו אתם: עברו עם האצבע על הקו. | intro step 4 and every trace item | needs-editor |
| FB07 | הקשיבו לצליל, וגעו באות. | sound → letter | needs-editor |
| FB08 | איזה צליל האות אומרת? הקשיבו לכפתורים, וגעו בצליל הנכון. | letter → sound (sound buttons) | needs-editor |
| FB09 | הקשיבו לשם, וגעו באות. | name → letter | needs-editor |
| FB10 | איך קוראים לאות? הקשיבו לכפתורים, וגעו בשם הנכון. | letter → name (sound buttons) | needs-editor |
| FB11 | באיזו תמונה המילה מתחילה בצליל של האות? | letter → picture (the words play on tap) | needs-editor |
| FB12 | געו בכל האותיות שאומרות: | tap-all, carrier before the sound clip | needs-editor |
| FB13 | חברו כל אות גדולה לאות הקטנה שלה. | capital ↔ small pairs | needs-editor |
| FB14 | כתבו את האות במסגרת, כמו בדוגמה. | copy | needs-editor |
| FB15 | כתבו אות גדולה שאומרת: | memory, capital, sound cue (carrier) | needs-editor |
| FB16 | כתבו אות קטנה שאומרת: | memory, small, sound cue (carrier) | needs-editor |
| FB17 | כתבו אות קטנה שקוראים לה: | memory, small, name cue (carrier) | needs-editor |
| FB18 | הקשיבו למילה, ושימו אסימון אחד לכל צליל. | LS03 count step | needs-editor |
| FB19 | עכשיו צבעו את האסימונים. | LS03 colour step (the colour buttons carry their shape marks, taught in B-12) | needs-editor |
| FB20 | געו בקופסה של הצליל: | LS03 which step, carrier before the sound clip | needs-editor |
| FB21 | החליקו את האצבע לפי החץ, והקשיבו. | LS04 the slide | needs-editor |
| FB22 | מה שמעתם? הקשיבו לכפתורים, וגעו בנכון. | LS04 the choice (sound buttons) | needs-editor |
| FB23 | קראו, וגעו בתמונה. | LS01 text stem | needs-editor |
| FB24 | זוכרים את התמונה של האות? | B-18 hint level 2 (the key word picture beside the letter) | needs-editor |
| FB25 | הסתכלו, ואז נסו שוב. | LS02 hint level 2 (the stroke drawn slowly once) | needs-editor |
| FB26 | בואו נעבור על הקו יחד. | LS02 hint level 3 (trace with the full path) | needs-editor |
| FB27 | הקשיבו איך הצליל משתנה. | B-19 hint level 2 (the vowel strip, LS05 `explore` as a hint) | needs-editor |

What each line must make clear (for the editor): FB03 and FB04 come before a Russian clip, so they end on a colon and the voice pauses; FB08, FB10 and FB22 tell the child that the answers are **heard on a tap** (as F40 of Band A); FB12 asks for **all** the letters, not one; FB15 to FB17 say big or small, because the box alone does not; "אסימון" (FB18, FB19) is the chip of the sound scheme (Russian фи́шка); RUS-2a's B-09 to B-17 will use the same word, so the editor's choice here holds for the whole course. No left / right words (FB21 says "by the arrow").

## 3. Misconception tags used in the slice

Kinds, families and engine ids as frame §4.2. The two **proposed** tags (L5 §14 item 3) are new; their rows go to syllabus §11 and the catalogue (curriculum-expert, L5-7). `parentText` and `homeActivity`: the Band A ones are `text-ready`; the others are drafts for the hebrew-text-editor (`needs-editor`; adult text, no nikud, "הילד").

| Tag | Engine id | Kind | Family | Signal in this slice | Level-2 re-teach | parentText | homeActivity | Review |
|---|---|---|---|---|---|---|---|---|
| M-RUS-NAME | `rus.let.name` | diagnostic | NAME | the name blend "эм-а" chosen for ма (b19.03 to .06); э́му chosen for М (b18.14, .15); the name эм chosen for the sound (b18.08); the sound chosen for the name (b18.10, see §9 item 3) | both lines: "its name is эм, it says ммм" (F-NAME, F-SAYS), then the slide (LS04) | לכל אות ברוסית יש שם ויש צליל. לאות М קוראים эм, אבל היא אומרת ммм. כשקוראים מחברים צלילים: ма, ולא эм-а. בהתחלה ילדים מערבבים בין השם לצליל, וזה רגיל. | כשאתם רואים יחד את האות М, אמרו: "קוראים לה эм, והיא אומרת ммм", ואז קראו יחד ма. | needs-editor |
| M-RUS-SHAPE | `rus.let.shape` | diagnostic (`revisitWith` the pair) | SHAPE | a print look-alike chosen (Л Д for А, Ч for У, С for О, Л И for М); a mismatched capital and small pair (b18.18); LS02 partner classifier (У → Ч, О → С, А → Л) | the letter drawn slowly beside its look-alike, the part that differs lit (the bar of А, the tail of У, the closed ring of О) | יש אותיות רוסיות שנראות דומה (У ו־Ч, О ו־С). הילד עוד מתבלבל ביניהן, וזה רגיל בשלב הזה. | כתבו את שתי האותיות זו ליד זו, ומצאו יחד במה הן שונות. | needs-editor |
| M-RUS-SOUND | `rus.voc.sound` | diagnostic | GUESS | a sound-alike chosen: [о] for [а] and back, [о] for [у] and back, [н] for [м], эн for эм; a picture whose word sounds like the read one (па́па for ма́ма, ко́шка "мяу" for му) | the mouth picture (F36): open for а, round for о and у, lips closed for м, tongue up for н; each option said with its mouth | (Band A, final) מילים שנשמעות דומה (сок ו־суп) עדיין מתחלפות לילד. זה שלב רגיל בלמידת שפה חדשה. | (Band A, final) אמרו לאט שתי מילים דומות, אחת אחרי השנייה, והצביעו על התמונה של כל אחת. | text-ready |
| M-RUS-NOTFIRST | `rus.pho.notfirst` | diagnostic | SEGMENT | a picture whose word has the sound inside or at the end (мак for А, му́ха for У, кот for О, дом for М); in LS03 `which`, the end box tapped for the start | each option said with its first sound held, the mouth showing it | (Band A, final) הילד שומע את הצליל במילה, אבל עוד לא ברור לו שהוא בהתחלה. | (Band A, final) משחק "מה מתחיל ב־ммм?": משכו את הצליל הראשון של מילה, ומצאו עוד דבר שמתחיל כך. | text-ready |
| M-RUS-RTL | `rus.rea.rtl` | diagnostic | DIR | the reversed syllable chosen (ам for ма, ом for мо, ум for му, мо for ом); the picture of the reversed word (the crying baby "уа" for ау) | the slide again with the arrow from the left start dot; the tile row lights left to right | ברוסית קוראים וכותבים משמאל לימין, הפוך מעברית. לפעמים הילד קורא הברה הפוך (ам במקום ма). זה טבעי לילד שקורא עברית. | קראו יחד הברות קצרות, והעבירו את האצבע מתחת לאותיות משמאל לימין. | needs-editor |
| M-RUS-SEM | `rus.lis.sem` | diagnostic | MEANING | a picture of the same theme chosen in a text stem (ба́бушка for ма́ма): the word guessed from its theme, not read | the word read slowly by the voice while the slide lights each part (LS04 as the hint) | (Band A, final) הילד כבר מכיר את הנושא, ומילים קרובות (כמו שתי חיות) עדיין מתחלפות לפעמים. זה רגיל בלמידת מילים חדשות. | (Band A, final) הניחו שני חפצים מאותו נושא, אמרו ברוסית את השם של אחד מהם, ובקשו מהילד להצביע עליו. | text-ready |
| M-RUS-SYLL | `rus.pho.syll` | diagnostic | SEGMENT | LS03 count one more or one fewer than the sounds (L5 §5.3; see §9 item 4) | the word said slowly, each sound stretched, a hand tapping each box as it sounds | (Band A, final) בספירת חלקי מילה במחיאות כפיים, קורה שהילד מוחא פעם אחת יותר או פחות. | (Band A, final) מחאו כפיים יחד לכל חלק בשמות של צעצועים: ку-кла, ма-ши-на. | text-ready |
| M-RUS-HARDSOFT | `rus.pho.hardsoft` | diagnostic | CONTRAST | LS03 colour: the hard м coloured green (soft) | the mouth: no smile for the hard м (a wide smile is for the soft one) | (Band A, final) | (Band A, final) | text-ready |
| **M-RUS-VOWEL-CONS** (proposed) | `rus.pho.vowel_cons` | diagnostic | SEGMENT | LS03 colour: a vowel chip coloured as a consonant (blue or green), or a consonant chip coloured red | "can you sing it?" with the mouth picture (L5 §5.3): а and у are sung with the mouth open and the air free; at м the lips close | הילד עוד מתבלבל בין צליל שאפשר לשיר בפה פתוח (а, у, о) לבין צליל שהפה עוצר בו (м: השפתיים נסגרות). ההבחנה הזאת היא הבסיס לצבעים של תרשים הצלילים. | שירו יחד צליל ארוך: "аааа", "уууу". אחר כך אמרו "ммм", ושימו לב שהשפתיים סגורות. | needs-editor |
| **M-RUS-STROKE** (proposed) | `rus.wri.stroke` | diagnostic | STROKE | LS02 copy and memory: a stroke started far from its start, drawn the other way, off its guide lines, or the whole letter mirrored (а, У, у) | the stroke drawn slowly once (motion), then the start dot and the arrow of that stroke | הילד כותב את האות כך שאפשר לזהות אותה, אבל מתחיל ממקום אחר, מצייר קו בכיוון ההפוך, או כותב אותה הפוכה כמו במראה. בספרי הכתיבה הרוסיים כותבים אות בחלקים: קודם הקווים מלמעלה למטה, ואחר כך הקווים לרוחב משמאל לימין. | כתבו יחד אות גדולה באצבע, באוויר או בחול, ואמרו את הסדר בקול: "מלמעלה למטה". | needs-editor |

**The two proposed tags, for syllabus §11 and the catalogue:**
- **M-RUS-VOWEL-CONS**: diagnostic, family SEGMENT (L5 §14 item 3). First skill **B-12** set by hand (its home skill: "tells a vowel from a consonant"), so the engine id is `rus.pho.vowel_cons`. By the §4.1 rule alone the pilot's first use (B-19) would make it `rus.rea.vowel_cons`, and ids are frozen once assigned, so the hand setting must be in the catalogue before this slice is packed. `skills`: B-12, B-14, B-19. Either direction is the same confusion, so it is one tag.
- **M-RUS-STROKE**: diagnostic, family STROKE. First skill B-26 (its first item, b26g1.01; WRI), engine id `rus.wri.stroke`. It covers start, direction, guide lines and a mirrored letter: Russian has no LINES or MIRROR tag, and one formation tag is enough at this age (the English course splits it in three, the Hebrew course has STROKE and MIRROR). If the curriculum-expert prefers a mirror tag of family SHAPE as Hebrew does (`M-HEB-MIRROR`), mirror moves to a third tag; the items need only the classify map changed. `skills`: B-26, B-24. Trace items (B-24) do not use it: trace keeps today's path check, and a trace answer is practice (E-1).

`revisitWith` (frame §3.4): SHAPE with its pair (А/Л, А/Д, У/Ч, О/С, М/Л, М/И), so each look-alike returns with the letter of group 1 when its own group is taught (Л group 3, Д group 6, Ч group 7, С group 2, И group 3). Not used here: M-RUS-LATIN (all four letters read the same as their Latin look-alikes A O M, except У/Y, which no item tests with a Latin letter: the screen stays pure Cyrillic), M-RUS-YI, -YOT, -SOFTSIGN (later groups).

## 4. The skills

### RUS-B-18 ● Group 1 letters А У О М (bundled with `B-24.G1`)
*Strand LET · prerequisite B-12 · templates: LS02 `intro`; LS01 (a) text faces, (b) a sound per option, (c) sound buttons, (d) text stem, tap-all, `match_pairs` with text faces*

| Route | How the skill is served |
|---|---|
| New learner | After the letters gate. Teach screens (LS09) for а́ист, о́блако, мак, му́ха, э́му before their first item. Visit 1: i01 А, i02 У, then 01, 02, 05, 06, 11, 12, 16 and the traces of А, а, У, у; visit 2: i03 О, i04 М, then 03, 04, 07 to 10, 13, 14, 17; later visits: 15, 18 and the rest mixed |
| Heritage | No teach screens; the same order, two intros a visit, more items a visit |
| Reader | Probes first (b18.04); if served, as heritage |

**Intros** (LS02 `intro`, unscored, the worked example of the bundle; frame §5.3, L5 §5.2). Each intro: FB01 (the letter big, capital and small) → FB02 (each form lights) → FB03 + the sound clip → FB04 + the key word with its first sound held, its picture shown → F-NAME + the name clip → F-SAYS + the sound clip → FB05 (the dot walks the capital's path) → FB06 (one trace of the capital with the full guide). Response: nothing scored, nothing written.

| Item | Template · mode | Form traced | Sound | Key word (picture) | Name | Notes |
|---|---|---|---|---|---|---|
| `rus.b18.i01` | LS02 `intro` | `cyrillic.a.cap` | `snd-a` | `sf-aist` а́ист `pic.stork` | `snd-a` (а: name = sound) | the stressed first а of а́ист is the letter's sound |
| `rus.b18.i02` | LS02 `intro` | `cyrillic.u.cap` | `snd-u` | `sf-utka` у́тка `pic.duck` | `snd-u` (у) | |
| `rus.b18.i03` | LS02 `intro` | `cyrillic.o.cap` | `snd-o` | `sf-oblako` о́блако `pic.cloud` | `snd-o` (о) | о́блако, not окно́ or оса́: their first о is unstressed, said [ɐ] |
| `rus.b18.i04` | LS02 `intro` | `cyrillic.em.cap` | `snd-m` | `sf-mysh` мышь `pic.mouse` | `ln-em` (эм) | name ≠ sound: F-NAME + эм, F-SAYS + ммм. мышь, not мяч or мёд (soft м) |

**Items.**

| Item | Template · mode | Frame (Hebrew) → Russian clip | Shown | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|---|
| `rus.b18.01` | LS01 tap, text faces | FB07 → `snd-a` | 3 letter tiles | А | Л (M-RUS-SHAPE) · О (M-RUS-SOUND) | NHR | Л: А without its bar; О: the pair that reduction joins |
| `rus.b18.02` | LS01 tap, text faces | FB07 → `snd-u` | 3 letter tiles | У | Ч (M-RUS-SHAPE) · О (M-RUS-SOUND) | NHR | У and Ч: the classic print pair |
| `rus.b18.03` C | LS01 tap, text faces | FB07 → `snd-o` | 3 letter tiles | О | С (M-RUS-SHAPE) · У (M-RUS-SOUND) | NHR | С: an open О |
| `rus.b18.04` P | LS01 tap, text faces | FB07 → `snd-m` | 3 letter tiles | М | Н (M-RUS-SOUND) · Л (M-RUS-SHAPE) | NHR | [н] the other nasal; placement strand 3, group 1 |
| `rus.b18.05` | LS01 text stem + sound buttons (2) | FB08 → — | А | `snd-a` | `snd-o` (M-RUS-SOUND) | NHR | 2-choice |
| `rus.b18.06` | LS01 text stem + sound buttons (2) | FB08 → — | У | `snd-u` | `snd-o` (M-RUS-SOUND) | NHR | 2-choice |
| `rus.b18.07` | LS01 text stem + sound buttons (2) | FB08 → — | О | `snd-o` | `snd-u` (M-RUS-SOUND) | NHR | 2-choice |
| `rus.b18.08` | LS01 text stem + sound buttons (3) | FB08 → — | М | `snd-m` | `ln-em` (M-RUS-NAME) · `snd-n` (M-RUS-SOUND) | NHR | the name for the sound: the D16 trap |
| `rus.b18.09` | LS01 tap, text faces | FB09 → `ln-em` | 3 letter tiles | М | Н (M-RUS-SOUND) · Л (M-RUS-SHAPE) | NHR | эн sounds like эм |
| `rus.b18.10` | LS01 text stem + sound buttons (3) | FB10 → — | М | `ln-em` | `ln-en` (M-RUS-SOUND) · `snd-m` (M-RUS-NAME) | NHR | the sound for the name (§9 item 3) |
| `rus.b18.11` | LS01 text stem, picture options | FB11 → — | А | а́ист `pic.stork` | мак `pic.poppy` (M-RUS-NOTFIRST) · о́блако `pic.cloud` (M-RUS-SOUND) | NHR | each picture plays its word on tap: `w-aist`, `w-mak`, `w-oblako` |
| `rus.b18.12` | LS01 text stem, picture options | FB11 → — | У | у́тка `pic.duck` | му́ха `pic.fly` (M-RUS-NOTFIRST) · о́блако `pic.cloud` (M-RUS-SOUND) | NHR | `w-utka`, `w-muha`, `w-oblako` |
| `rus.b18.13` | LS01 text stem, picture options | FB11 → — | О | о́блако `pic.cloud` | кот `pic.tomcat` (M-RUS-NOTFIRST) · у́тка `pic.duck` (M-RUS-SOUND) | NHR | `w-oblako`, `w-kot`, `w-utka` |
| `rus.b18.14` | LS01 text stem, picture options | FB11 → — | М | мышь `pic.mouse` | э́му `pic.emu` (M-RUS-NAME) · дом `pic.house` (M-RUS-NOTFIRST) | NHR | э́му starts with the name эм [ɛm]; `w-mysh`, `w-emu`, `w-dom` |
| `rus.b18.15` C | LS01 text stem, picture options | FB11 → — | М | мак `pic.poppy` | нос `hot.nose` (M-RUS-SOUND) · э́му `pic.emu` (M-RUS-NAME) | NHR | a new target word; `w-mak`, `w-nos`, `w-emu` |
| `rus.b18.16` C | LS01 tap-all, text faces | FB12 → `snd-u` | the row У Ч У О Ч У | the three У (cards 1, 3, 6) | Ч, Ч (M-RUS-SHAPE) · О (M-RUS-SOUND) | NHR | right only when all three У and no other card are tapped |
| `rus.b18.17` | LS01 tap-all, text faces | FB12 → `snd-m` | the row М Н М Л И М | the three М (cards 1, 3, 6) | Н (M-RUS-SOUND) · Л (M-RUS-SHAPE) · И (M-RUS-SHAPE) | NHR | |
| `rus.b18.18` | LS01 `match_pairs`, text faces | FB13 → — | А У О М above, а у о м below (shuffled) | А–а, У–у, О–о, М–м | any mismatched pair (M-RUS-SHAPE) | NHR | а and у are the forms that differ from their capitals (syllabus §3) |

**Hint ladder.** 1: the clip again, slower, the target letter's tile outlined (F02). 2: a new representation: the **key word picture** beside each letter tile (FB24: а́ист beside А, у́тка beside У …), and the mouth picture for the sound (F36: open for а, round for о and у, lips closed for м, tongue up for н); for a NAME error both lines, F-NAME + `ln-em`, F-SAYS + `snd-m`; for a SHAPE error the letter is drawn slowly beside its look-alike, the differing part lit. 3: show me: the right tile glows, its sound plays, the dot walks its path; a tap goes on (no credit), and the letter returns later in a fresh item.

**Mastery and notes.** Core: 6 correct over 2 days, 3 checks (03, 15, 16), at least 2 representations (`symbolic`; `pictorial` in 11 to 15). Coverage per facet as §1. 2-choice items 05 to 07: 3 of 18, never a check. `revisitWith` SHAPE pairs.

### `RUS-B-24.G1` Tracing А а У у О о М м (bundled with B-18)
*Strand WRI · no prerequisite inside the bundle · template: LS02 `trace` 2.0, letter canvas, three guide lines with the descender (у)*

| Item | Template · mode | Form | Guide | Frame → Russian clip | Classify | Routes | Notes |
|---|---|---|---|---|---|---|---|
| `rus.b24g1.01` | LS02 `trace` | `cyrillic.a.cap` | start | FB06 → `snd-a` | path check (retry, no tag) | NHR | 3 strokes: left leg, right leg, the bar left to right |
| `rus.b24g1.02` | LS02 `trace` | `cyrillic.a` | start | FB06 → `snd-a` | path check | NHR | the two-storey а: hook and stem, then the bowl |
| `rus.b24g1.03` | LS02 `trace` | `cyrillic.u.cap` | start | FB06 → `snd-u` | path check | NHR | the long arm first, then the short arm |
| `rus.b24g1.04` | LS02 `trace` | `cyrillic.u` | start | FB06 → `snd-u` | path check | NHR | the long arm goes down to the descender line |
| `rus.b24g1.05` | LS02 `trace` | `cyrillic.o.cap` | start | FB06 → `snd-o` | path check | NHR | one stroke, anticlockwise from the top |
| `rus.b24g1.06` | LS02 `trace` | `cyrillic.o` | start | FB06 → `snd-o` | path check | NHR | |
| `rus.b24g1.07` | LS02 `trace` | `cyrillic.em.cap` | start | FB06 → `snd-m` | path check | NHR | 4 strokes: the two sticks, then the two diagonals down to the middle (never in one go, strokes.md §5.2) |
| `rus.b24g1.08` | LS02 `trace` | `cyrillic.em` | start | FB06 → `snd-m` | path check | NHR | |

**Hint ladder.** 1: the arrow of the stroke the child is on, beside the start dot. 2: that stroke drawn slowly once, then the box clears (FB25; motion). 3: trace with the full dotted path (FB26). A stroke that leaves the path fades softly and the start dot returns.

**Mastery and notes.** Trace answers are practice (E-1). The node counts as met ("practised") when each of the 8 forms has been traced once with the start dot only; it never blocks. The capital's first trace with the full guide is in its intro; a small form's full guide is hint level 3. Response: `ok`, or the stroke number.

### `RUS-B-26.G1` Copy, then write from memory
*Strand WRI · prerequisite `B-24.G1` · templates: LS02 `copy` (`model: beside`), LS02 `memory`; the free-stroke check at the end of each stroke (L5 §5.2)*

Every item's classify map: start, direction, lines → M-RUS-STROKE; mirror (only for the forms that are not symmetric: а, У, у) → M-RUS-STROKE; partners → M-RUS-SHAPE as listed. А О М о м are their own mirror images, so they have no mirror classifier. Anything else is a retry with no tag.

| Item | Template · mode | Form | Model / cue | Frame → Russian clip | Partners (tag) | Routes | Notes |
|---|---|---|---|---|---|---|---|
| `rus.b26g1.01` | LS02 `copy` | `cyrillic.a` | beside | FB14 → `snd-a` | — | NHR | mirror → M-RUS-STROKE |
| `rus.b26g1.02` | LS02 `copy` | `cyrillic.u` | beside | FB14 → `snd-u` | `cyrillic.che` (M-RUS-SHAPE) | NHR | mirror → M-RUS-STROKE; у below the base line |
| `rus.b26g1.03` | LS02 `copy` | `cyrillic.o.cap` | beside | FB14 → `snd-o` | `cyrillic.es.cap` (M-RUS-SHAPE) | NHR | an open ring reads as С |
| `rus.b26g1.04` | LS02 `copy` | `cyrillic.em.cap` | beside | FB14 → `snd-m` | — | NHR | |
| `rus.b26g1.05` | LS02 `memory` | `cyrillic.a.cap` | sound (= name) | FB15 → `snd-a` | `cyrillic.el.cap` (M-RUS-SHAPE) | NHR | А without its bar (thin, §9 item 6) |
| `rus.b26g1.06` | LS02 `memory` | `cyrillic.a` | sound (= name) | FB16 → `snd-a` | — | NHR | mirror → M-RUS-STROKE |
| `rus.b26g1.07` | LS02 `memory` | `cyrillic.u.cap` | sound (= name) | FB15 → `snd-u` | `cyrillic.che.cap` (M-RUS-SHAPE) | NHR | mirror → M-RUS-STROKE |
| `rus.b26g1.08` | LS02 `memory` | `cyrillic.u` | sound (= name) | FB16 → `snd-u` | `cyrillic.che` (M-RUS-SHAPE) | NHR | mirror → M-RUS-STROKE |
| `rus.b26g1.09` | LS02 `memory` | `cyrillic.o.cap` | sound (= name) | FB15 → `snd-o` | `cyrillic.es.cap` (M-RUS-SHAPE) | NHR | |
| `rus.b26g1.10` | LS02 `memory` | `cyrillic.o` | sound (= name) | FB16 → `snd-o` | `cyrillic.es` (M-RUS-SHAPE) | NHR | |
| `rus.b26g1.11` | LS02 `memory` | `cyrillic.em.cap` | sound | FB15 → `snd-m` | — | NHR | the sound cue of М |
| `rus.b26g1.12` | LS02 `memory` | `cyrillic.em` | name | FB17 → `ln-em` | — | NHR | the name cue of М |

**Hint ladder.** 1: the start dot and the arrow of the stroke the child is on. 2: that stroke drawn slowly once, then the box clears (FB25; a new representation: motion). 3: this item as a trace with the start dot (FB26). After a success the model replays once in its order (order is not scored, owner's Q2).

**Mastery and notes.** E-1: copy successes count like a level-1 hint, memory successes in full; fresh only with memory successes on two days, one with each cue. For А У О the sound and the name are one clip: I propose the capital and the small form as their two representations (§1, §9 item 2). Coverage: each form right once in memory (05 to 12). Response: `ok`, or the stroke number and the classifier (`s2.dir`); the child's points live only in the session.

### RUS-B-19 ● Merge: ма мо му (and ом); first reading
*Strand REA · prerequisite B-18 · templates: LS03 1.1 `boxes` (unit `phoneme`; steps count, colour, which); LS04 `merge`; LS01 (d) text stem*

| Route | How the skill is served |
|---|---|
| New learner | 01, 02 (hear and lay out the syllable), then 03 to 06 (slide and choose), then 07 to 09 (read). Teach screen for ау́ (the picture of the child calling in the woods) before 08 |
| Heritage | The same order, faster; no teach screen |
| Reader | Probe first (b19.07); if served, as heritage |

**LS03 1.1 (`concrete`): the syllable heard and laid out as two chips** (the analysis the merge is built on: a blue chip and a red chip, which the slide then joins).

| Item | Template · mode | Frame → Russian clip | Word (picture · clip · slow) | Units (clip · kind) | Steps | Answer (code) | Classify | Routes |
|---|---|---|---|---|---|---|---|---|
| `rus.b19.01` | LS03 `boxes`, `phoneme` | FB18, FB19, FB20 → `snd-m` | му `pic.cow` · `w-mu` · `sl-mu` | м `snd-m` hard · у `snd-u` vowel | count, colour, which (м) | `n=2.c=br.w=1` | count ±1 → M-RUS-SYLL; a vowel coloured as a consonant or the reverse → M-RUS-VOWEL-CONS; м coloured green → M-RUS-HARDSOFT; the end box for [м] → M-RUS-NOTFIRST | NHR |
| `rus.b19.02` | LS03 `boxes`, `phoneme` | FB18, FB19, FB20 → `snd-a` | ам `pic.act.eat` · `w-am` · `sl-am` | а `snd-a` vowel · м `snd-m` hard | count, colour, which (а) | `n=2.c=rb.w=1` | as 01; the end box for [а] → M-RUS-NOTFIRST | NHR |

**LS04 `merge` (`symbolic`): slide, then choose the syllable heard.** The consonant tile slides to the vowel tile while the voice holds м ("ммм…"), and as they meet the merged syllable sounds (for ом, the vowel is held into м). The slide is practice; the choice from three sound buttons is scored. If a part has no clean clip of its own (the D2 pilot), the stretched whole (`mg-*`) plays while the parts light (L5 §5.5).

| Item | Template · mode | Frame → Russian clip | Word (shown) | Parts (clip · stretch) | Whole · stretched | Right | Distractors (tag) | Routes |
|---|---|---|---|---|---|---|---|---|
| `rus.b19.03` | LS04 `merge` | FB21, FB22 → — | ма | м `snd-m` stretch · а `snd-a` | `syl-ma` · `mg-ma` | `syl-ma` | `nb-em-a` (M-RUS-NAME) · `syl-am` (M-RUS-RTL) | NHR |
| `rus.b19.04` C | LS04 `merge` | FB21, FB22 → — | мо | м `snd-m` stretch · о `snd-o` | `syl-mo` · `mg-mo` | `syl-mo` | `nb-em-o` (M-RUS-NAME) · `syl-om` (M-RUS-RTL) | NHR |
| `rus.b19.05` | LS04 `merge` | FB21, FB22 → — | му | м `snd-m` stretch · у `snd-u` | `syl-mu` · `mg-mu` | `syl-mu` | `nb-em-u` (M-RUS-NAME) · `syl-um` (M-RUS-RTL) | NHR |
| `rus.b19.06` C | LS04 `merge` | FB21, FB22 → — | ом | о `snd-o` stretch · м `snd-m` | `syl-om` · `mg-om` | `syl-om` | `syl-mo` (M-RUS-RTL) · `nb-o-em` (M-RUS-NAME) | NHR |

**LS01 (d) text stem (`symbolic`): read, then choose the picture.** The option pictures do not play their words; "read it to me" (hint level 1) plays the stem's clip and lowers the credit to 0.8. No stress mark on screen (D15).

| Item | Template · mode | Frame → Russian clip | Shown (stem) | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|---|
| `rus.b19.07` P | LS01 text stem | FB23 → `w-mama` (read it to me) | мама | ма́ма `pic.fam.mother` | па́па `pic.fam.father` (M-RUS-SOUND) · ба́бушка `pic.fam.grandmother` (M-RUS-SEM) | NHR | the first word (syllabus §3); placement strand 4 |
| `rus.b19.08` | LS01 text stem | FB23 → `w-au` | ау | ау́ `pic.rus.call-au` | the crying baby "уа" `pic.baby-cry` (M-RUS-RTL) · the cow "му" `pic.cow` (M-RUS-SOUND) | NHR | ау́: the call in the woods (syllabus §4); уа is ау read right to left |
| `rus.b19.09` C | LS01 text stem | FB23 → `w-mu` | му | the cow "му" `pic.cow` | the cat "мяу" `pic.cat` (M-RUS-SOUND) · ау́ `pic.rus.call-au` (M-RUS-SOUND) | NHR | му is what a cow says; both distractors share a sound with it |

**Hint ladder.** 1: LS04: the slide again, slowly, each part lit as it sounds (F02); LS03: the word again slowly, each sound stretched with a pause between (`sl-mu`, `sl-am`); text stem: "read it to me" (the stem's clip, credit 0.8). 2: a new representation: the **vowel strip** as a hint screen (L5 §5.9: `hints.level2: { "show": "change_part", "mode": "explore", "frame": "м_", "parts": ["а", "о", "у"] }`): the child slides а, о, у under м and hears ма, мо, му change (FB27); for a NAME error, F-NAME + `ln-em`, F-SAYS + `snd-m` first; for LS03, the stage of L5 §5.3 (the word stretched with a pause per sound; "can you sing it?" with the mouth picture). 3: show me: the friend slides and points to the answer (LS04), or lays the chips (LS03), or reads the word as the slide lights it (text stem); a tap goes on.

**Mastery and notes.** Core: 6 correct over 2 days, 3 checks (04, 06, 09), two representations (`concrete` 01, 02; `symbolic` 03 to 09). Coverage: ма, мо, му each right once without a hint. The name-blend buttons (`nb-*`) are the NAME distractor of L5 §5.5 and frame §5.3; they are never a model to copy, and the right answer is always said again after any choice.

## 5. Lessons (proposed, for the session builder of the batch script)
Band B: 12 minutes, activities of 4 to 7 minutes, 5 to 8 items. Every visit opens with retrieval (a known Band A song or word). E-2: a bundle's intros come first.

| Lesson | Activities |
|---|---|
| G1-1 | i01 А, i02 У · b18.01, .02, .05, .06, .11, .12 · b24g1.01 to .04 |
| G1-2 | i03 О, i04 М · b18.03, .04, .07, .08, .09, .10, .13, .14 · b24g1.05 to .08 |
| G1-3 | b18.15 to .18 (and due checks) · b26g1.01 to .04 · b19.01, .02 |
| G1-4 | b19.03 to .06 · b26g1.05 to .08 · b19.07 |
| G1-5 | b19.08, .09 · b26g1.09 to .12 · mixed review of b18 |

## 6. Co-play card (proposed; L5 §5.8, parent area only, never voiced)

| Id | Course | Skills | Kind | Hebrew text (draft, `needs-editor`) | Picture |
|---|---|---|---|---|---|
| `card.rus.g1` | rus | B-18, B-19, `B-24.G1`, `B-26.G1` | coplay | הכרנו את האותיות הראשונות ברוסית: А, У, О, М. חפשו אותן יחד בספר או על אריזה, ואמרו את הצליל של כל אחת. לאות М קוראים эм, אבל היא אומרת ммм. קראו יחד: ма, мо, му, мама. אפשר גם לכתוב את האותיות באצבע על הגב, ולנחש איזו אות זו. | the four letters, big |

I propose one card per letter group for the whole course (L5 §5.8 left it to the teacher): a parent who reads Russian helps most when told which letters were met and that the sound, not the name, is used to read.

## 7. Pictures (for the design-director)
Original art only, drawn from real references (`docs/languages/pictures.md` style). "Exists" means the id is in the Band A batch or `pictures.md`.

| Picture | Word (stress for the voice) | Used in | Brief | Status |
|---|---|---|---|---|
| `pic.stork` | а́ист | i01, b18.11 | a white stork standing on one leg (black wing tips, red beak and legs) | **new** |
| `pic.cloud` | о́блако | i03, b18.11, .12, .13 | one white fluffy cloud on a pale sky patch (no sun, no rain) | **new** |
| `pic.poppy` | мак | b18.11, .15 | one red poppy flower with its black centre and a green stem | **new** |
| `pic.fly` | му́ха | b18.12 | a house fly, friendly, large on the card (two wings, big eyes) | **new** |
| `pic.emu` | э́му | b18.14, .15 | an emu, the tall brown-grey bird (long neck, no ostrich plumes) | **new** |
| `pic.rus.call-au` | ау́ | b19.08, .09 | the friend in a wood, hands cupped round the mouth, calling (sound lines, no letters) | **new** |
| `pic.baby-cry` | (уа, distractor) | b19.08 | a baby in a cot, crying softly (not distressing) | **new** |
| `pic.act.eat` | ам | b19.02 | the friend taking a big bite of an apple, mouth wide | **new** (or reuse `mika-eat`, if it shows the bite) |
| `mouth-open` | (hint) | B-18 hint level 2 | the friend's mouth wide open for а (joins the set `mouth-lips`, `-round`, `-tongue` …) | **new** |
| `pic.duck` | у́тка | i02, b18.12, .13 | (Band A) | exists |
| `pic.mouse` | мышь | i04, b18.14 | (Band A) | exists |
| `pic.tomcat` | кот | b18.13 | (Band A) | exists |
| `pic.house` | дом | b18.14 | (Band A) | exists |
| `hot.nose` | нос | b18.15 | the friend's face, the nose shown large (Band A rule for body words as options) | exists |
| `pic.cow` | коро́ва; "му" | b19.01, .08, .09 | (Band A); for "му" the same cow, mouth open, mooing | exists |
| `pic.cat` | ко́шка; "мяу" | b19.09 | (Band A); mouth open, miaowing | exists |
| `pic.fam.mother`, `pic.fam.father`, `pic.fam.grandmother` | ма́ма, па́па, ба́бушка | b19.07 | (Band A, the original family) | exist |
| `mouth-lips`, `mouth-round`, `mouth-tongue` | (hints) | B-18, B-19 level 2 | (Band A hint set: м; о у; н) | exist |

Not pictures but art the templates need (design-director with the app-developer): the letter tiles of А У О М and the look-alikes Л Д С Ч Н И in Nitznutz Letters; the copy box beside its model; the LS03 chips and colour buttons with their shape marks; the LS04 tiles on a left-to-right track; the vowel strip а о у under м for the B-19 hint.

**New pictures: 9** (8 item pictures and 1 mouth shape); 10 Band A pictures and 3 mouth shapes reused.

## 8. Clips and pronunciation specs
Every clip of the slice. **New rows** (32) are written here in the `pronunciation.csv` format for the voice; they are added to `pronunciation.csv` (status `draft`) when the orchestrator merges this slice (this step touched only this file). Accent: standard Russian (Moscow) for all. Letter sounds follow D2: each `snd-*` row names its fallback, and no item changes whichever form the pilot picks.

| id | shown | say | ipa | stress | traps | check |
|---|---|---|---|---|---|---|
| `snd-u` | [у] | у | [u] | - | a [j] glide before it ("ю"); drifting to о | a short, rounded, close u; fallback: the held start of `sf-utka` |
| `snd-o` | [о] | о | [o] | - | a [w] glide before it; too open | a clear rounded o, as stressed; fallback: the held start of `sf-oblako` |
| `snd-n` | [н] | ннн | [nː] | - | the name эн; a vowel after it | a held hum with the tongue up and no vowel; fallback: the syllable на |
| `ln-em` | эм | эм | [ɛm] | эм | said as the bare sound [m], or as English "em" with a closed e | the letter's name, open э, one syllable |
| `ln-en` | эн | эн | [ɛn] | эн | as `ln-em` | open э then н; same pitch and length as `ln-em` |
| `syl-mo` | мо | мо | [mo] | мо | reduced to [mə] or [mɐ] | hard м and a full о (an isolated syllable is stressed) |
| `syl-mu` | му | му | [mu] | му | a soft м ([mʲu]) | hard м and a rounded у |
| `syl-am` | ам | ам | [am] | ам | a vowel after м ([amə]) | open а, then the lips close on м |
| `syl-om` | ом | ом | [om] | ом | reduced to [ɐm] | full о, then м |
| `syl-um` | ум | ум | [um] | ум | a vowel after м | у, then м |
| `nb-em-a` | эм-а | эм… а | [ɛm ‖ a] | - | run together as one word (эма) | the wrong-way model: the name эм, a short pause, then а; distractor only |
| `nb-em-o` | эм-о | эм… о | [ɛm ‖ o] | - | as `nb-em-a` | as `nb-em-a`, with о |
| `nb-em-u` | эм-у | эм… у | [ɛm ‖ u] | - | as `nb-em-a` | as `nb-em-a`, with у |
| `nb-o-em` | о-эм | о… эм | [o ‖ ɛm] | - | as `nb-em-a` | о, a short pause, then the name эм; distractor only |
| `mg-ma` | ма | ммм-ма | [mːːa] | ма | a vowel before м; a break between м and а | м held about one second and running straight into а, with no break: the merge |
| `mg-mo` | мо | ммм-мо | [mːːo] | мо | as `mg-ma`; о reduced | as `mg-ma`, a full о |
| `mg-mu` | му | ммм-му | [mːːu] | му | as `mg-ma` | as `mg-ma`, a rounded у |
| `mg-om` | ом | ооо-ом | [oːːm] | ом | a break before м | о held about one second and closing straight onto м |
| `sf-aist` | аист | а-а-а́ист | [ˈaːʲɪst] | а | one syllable ("айст"); stress on и | а held, then the word in two syllables, а stressed |
| `sf-utka` | утка | у-у-у́тка | [ˈuːtkə] | ут | full а at the end | у held, then the word; the end reduced |
| `sf-oblako` | облако | о-о-о́блако | [ˈoːbləkə] | об | full о and а at the end (said as spelt) | о held, then the word; the last two vowels reduced |
| `sf-mysh` | мышь | м-м-мышь | [mːɨʂ] | мышь | a soft м; ы said as и | hard м held, a true ы, a hard ш with no softness |
| `w-aist` | аист | а́ист | [ˈaʲɪst] | а | one syllable; stress on и (аи́ст) | two syllables, stress on а |
| `w-oblako` | облако | о́блако | [ˈobləkə] | об | full vowels at the end | stress on the first о; ла and ко reduced |
| `w-mak` | мак | мак | [mak] | мак | a soft м ([mʲak]) | hard м, open а, a clean final к |
| `w-muha` | муха | му́ха | [ˈmuxə] | му | stress on ха; х as a Hebrew ח is fine, as ה is not | stress on му; [x], the end reduced |
| `w-emu` | эму | э́му | [ˈɛmu] | э | stress on у (эму́) | stress on э, an open э: it must be heard to start with эм |
| `w-au` | ау | ау́ | [ɐˈu] | у | stress on а | stress on у, a call, slightly drawn out |
| `w-mu` | му | му | [mu] | му | mooed long (that is `sl-mu`) | a plain му, as a cow says it in a children's book |
| `w-am` | ам | ам | [am] | ам | a vowel after м | the sound of a big bite |
| `sl-mu` | му | м-м-му-у | [mːuː] | му | a break between the sounds | each sound stretched, with no break: the slow hint clip of b19.01 |
| `sl-am` | ам | а-а-ам-м | [aːmː] | ам | as `sl-mu` | as `sl-mu`: the slow hint clip of b19.02 |

**Reused rows** (in `pronunciation.csv` already): `snd-a`, `snd-m`, `syl-ma`, `w-mama`, `w-utka`, `w-mysh`, `w-kot`, `w-dom`, `w-nos`.

Before voicing, the listening check (pronunciation-spec §4) is mine for every clip: in particular the names (`ln-*`) never said as the bare sound, the merges (`mg-*`) with no break, the name blends (`nb-*`) with a clear break, and every isolated syllable with a full, unreduced vowel. `ln-em` / `ln-en`, `snd-m` / `snd-n`, `snd-o` / `snd-u` are pairs in one item: same pitch and loudness.

## 9. Open points (to the curriculum-expert, through the orchestrator)
1. **Untaught look-alikes as SHAPE distractors** (Л Д С Ч Н И in b18.01 to .04, .09, .16, .17): the validator's F5 decodable check must not refuse a single letter tile in a LET skill. If it must, these items take a group-1 letter instead and lose the SHAPE signal.
2. **E-1 for letters whose name is their sound** (А У О, and later Ы И Е Ё Ю Я Э): the two cues are one clip. Proposed: the two representations are the capital and the small form, each written from memory, on different days.
3. **M-RUS-NAME in the other direction** (b18.10: the sound ммм chosen when the name is asked): the tag's signal names only "the name for the sound". Proposed: widen it to "the name and the sound mixed up, either way" (same family, same re-teach: both lines said). No new tag.
4. **M-RUS-SYLL for a phoneme count** (LS03 in `phoneme` units, b19.01, .02): L5 §5.3 maps any count ±1 to M-RUS-SYLL, whose signal and parent text speak of syllables. Proposed: widen its signal to "one unit more or fewer, syllables or sounds"; the hebrew-text-editor adds one sentence to its `parentText` ("…או צליל אחד יותר או פחות במילה").
5. **The first skill of M-RUS-VOWEL-CONS** set by hand to B-12 (§3), before the pack is built, so the frozen id is `rus.pho.vowel_cons`.
6. **The LS02 partner А → Л** (b26g1.05) is thin: a bar-less А is a missing stroke more than a look-alike, and the qa-engineer's samples will show whether the partner fires. If it fires on ordinary unfinished А's, drop it (the free-stroke check already asks for the missing bar).
7. **Placement probes**: two are marked here (b18.04, b19.07); the full set for the Band B levels of strands 3 and 4 comes with RUS-2b.

## 10. Counts and what the script checked

| Skill | Items | Scored | Checks (C) | 2-choice |
|---|---|---|---|---|
| RUS-B-18 ● (with the 4 intros) | 22 | 18 | 3 | 3 |
| `RUS-B-24.G1` | 8 | 0 (practice, E-1) | 0 | 0 |
| `RUS-B-26.G1` | 12 | 12 (copy counts as a level-1 hint) | 0 | 0 |
| RUS-B-19 ● | 9 | 9 | 3 | 0 |
| **Total** | **51** | **39** | **6** | **3** |

The checks and figures below are from the script run on this file (`check_band_b_pilot.py`, run on 2026-11-06; it is not in the repository, and the catalogue test of L5-7 is where it belongs). It reads this file, `syllabus.md` (skills and sub-skills), frame §4.2 (the `catalogue:rus` block), `pronunciation.csv`, `content/languages/strokes/cyrillic.json` and the Band A batch's pictures, and checks: every skill, tag, clip, form, picture and frame line exists; the two proposed tags and their engine ids are new; each 3-choice item has 2 tagged distractors and each 2-choice item 1, 2-choice items at most half of a skill and never a check; core skills have 3 checks; the LS03 answers match their units; the LS04 parts join to the word; Russian text is pure Cyrillic (no Latin look-alike, also as a lone letter); no stress mark on screen or on ё. It was tested on a mutated copy (an unknown tag, a Latin O tile, a missing clip, a stress mark on a shown syllable): it caught all four.

<!-- script-results:start -->
- Items: 51 (B-18 22, B-24.G1 8, B-26.G1 12, B-19 9); scored 39; checks 6; probes 2; 2-choice 3.
- Tags used: 10 (M-RUS-HARDSOFT, M-RUS-NAME, M-RUS-NOTFIRST, M-RUS-RTL, M-RUS-SEM, M-RUS-SHAPE, M-RUS-SOUND, M-RUS-STROKE, M-RUS-SYLL, M-RUS-VOWEL-CONS); in the catalogue: 8; proposed: ['M-RUS-STROKE', 'M-RUS-VOWEL-CONS']; accent tags on items: 0.
- Skills: ['RUS-B-18', 'RUS-B-19', 'RUS-B-24.G1', 'RUS-B-26.G1'], all in the syllabus (B-24.G1 and B-26.G1 as its sub-skills).
- Stroke forms: 13 distinct (cyrillic.a, cyrillic.a.cap, cyrillic.che, cyrillic.che.cap, cyrillic.el.cap, cyrillic.em, cyrillic.em.cap, cyrillic.es, cyrillic.es.cap, cyrillic.o, cyrillic.o.cap, cyrillic.u, cyrillic.u.cap), all in `cyrillic.json` (`teacher-checked`).
- Clips: 41 distinct used; 32 new rows in §8, none already in `pronunciation.csv`, each used; 9 reused (snd-a, snd-m, syl-ma, w-dom, w-kot, w-mama, w-mysh, w-nos, w-utka); referenced but in no table: [].
- Pictures: 18 used; 8 new item pictures; the rest in the Band A batch.
- Frame lines: 31 in §2 (27 new drafts), each used.
- Script: 90 distinct Cyrillic words, no Latin look-alike inside any; no stress mark on ё; no stress mark in any on-screen text; no Cyrillic or Latin letter in a Hebrew line.
- Characters for voicing (free count; nothing run): Russian `say` of the 32 new rows 147 with stress marks, 139 without; Hebrew drafts FB01 to FB27 740 characters unpointed (the editor's voice text will differ).
- Problems: none
<!-- script-results:end -->
