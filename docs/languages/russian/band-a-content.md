# The Russian course: Band A content batch (RUS-1)

*Owner: russian-language-teacher. Draft 2026-11-03, for the owner's OK, then the design-director (the pictures) and the voice-and-sound-director (the clips). **The Hebrew frame lines (§2) and the parent texts (§3) are `text-ready`** (hebrew-text-editor, 2026-11-03). Changed the same day for the settled catalogue (frame §4.5): the three new Hebrew texts (F40, and the `parentText` of M-RUS-YESNO and M-RUS-NUMWORD) were worded by the editor in a second pass the same day, and are `text-ready` too. Plan only; nothing here is built or voiced.*
*Built on: `syllabus.md` (skills RUS-A-01 to A-20, §5 vocabulary, §8 speaking, §11 tags), `templates.md`, the shared frame `docs/languages/frame.md` (templates LS01 to LS14 §2.3, mastery §3.3, catalogue format §4.1, speech §5.1, personal turns §5.2), `docs/curriculum.md` §6.1, §9.2 and §10. Every Russian clip id is a row of `pronunciation.csv`.*

## 1. How the batch works

**Skills and templates.** All 20 Band A skills. Templates are wave 1 of the frame (LS01, LS03 drum, LS08 `listen` and `dialogic`, LS09, LS10, LS11, LS12) and the existing T02 `count_tap` (its counting taps are practice; its scored step is "how many?", frame §2.2). Nothing here needs wave 2 or 3, and nothing shows Russian text to the child.

**Presentation.** Band A presentation (frame §3.1): at most 3 choices, one instruction at a time, no reading, no left and right words, big targets, no timer; 3 to 5 items per activity, activities of 2 to 4 minutes, visits of 8 minutes by default (syllabus §1). A child with Band B or C presentation who is placed here gets the same items, fewer per skill.

**Two clips per line** (F3). Every prompt is a Hebrew frame clip (§2, ids F01 to F39) and then a Russian clip (a `pronunciation.csv` id). A Hebrew clip never contains a Russian word, and a Russian clip never contains Hebrew. Every option picture plays its Russian word on tap (LS01 b). Lessons are taught in Hebrew for every child (D12); the meaning of a Russian word is given by its picture, never by a Hebrew translation in the voice.

**Feedback.** A right answer: the app's existing praise line, then the Russian target clip again (a recast; no new text). Not yet: the app's existing gentle line and the next hint (curriculum §9.2). Never "wrong". Speaking follows syllabus §8: per-word confident or unsure, `שָׁמַעְתִּי:` + the word, or `בּוֹאוּ נֹאמַר יַחַד.` and the model.

**Hints.** Each skill has one three-step ladder: 1 attention (the clip again, slower, F02); 2 a **new representation** (an action, a scene, the mouth, fingers, a row of pages); 3 show me (the answer is played and lit, a tap goes on, the item returns later). Credit by hint level as curriculum §10.2.

**Distractors** (frame §2.3). Every scored item has tagged distractors: a 3-choice item has two (they may share a tag when one misconception explains both); a 2-choice item (yes / no, same / different, two sound buttons) has one, it allows one retry only, and 2-choice items are **at most half of each skill's scored items**. In a same / different item, the wrong answer on a "same" pair is `M-RUS-YESNO` (an answer habit), and on a "different" pair it keeps its contrast tag. Counting taps (T02) are practice and carry no tag (frame §2.2). The tags are in §3.

**Checks.** An item marked **C** after its id is an understanding or delayed check: a new item or a second representation, always with 3 choices (never a single 2-choice item; frame §2.3). Every skill has at least two, a core skill (●) three, so the delayed check can use a different item.

**Coverage** (frame §3.3.4). A word-set skill is mastered only when each of its words has been answered right once without a hint. Items rotate the words until coverage is met.

**Routes** (syllabus §7.1, frame §3.3.7). The items are the same for every route; the routes change the order, the support and the pace:
- **New learner (N):** every new word first has a **teach screen** (LS09: the picture, the word clip, F05 the pause, the word again), in sets of 4 to 5 words; then the items of at most two sets at a time; say-it is echo first. Items marked `N` only (the listen-first story readings) are for this route.
- **Heritage (H):** strand 1 of placement usually marks much of Band A as "assumed" (checked later by interleaved retrieval); a skill that is served starts at its second representation with no teach screens; say-it is picture first (the child tries alone, then hears the model); A-15 extends to every word of A-02 to A-09; speaking and the grammar points (A-01 grown-up forms, A-12 кто / что) are weighted up.
- **Reader (R):** the oral strands follow strand 1 of placement, as heritage or as new. With Band B or C presentation, the word may appear under its picture **after** the answer (print exposure, no demand, no stress mark: the reader default of syllabus §7.1). The design-director and the curriculum-expert decide whether this caption is built in wave 1.

**Personal turns** (D10, frame §5.2). Two optional LS10 `personal` items (A-01 name, A-02 family), never scored, never required, with a "pass" and a parent switch. The puppet answers first, the child's answer is not checked, kept, sent or repeated. Where the child lives is never asked.

**Stress.** Nothing is written for the child in Band A, so no stress mark appears on screen. Stress is in every clip's spec (`pronunciation.csv` `say` and `stress`), and the listening check confirms it.

**Pictures.** Original art only (no franchise characters); picture ids are proposals for the design-director (§5). Clear, single-object pictures for LS01; scenes for LS11; one original family for A-02 and A-13. Any clothes on any friend.

## 2. Hebrew frame lines (final, `text-ready`)
Full nikud (child text), plural and gender-neutral as in the rest of the app (the rule: `docs/agents/hebrew-notes.md` §9.1). The voice text is the line for ElevenLabs (partial nikud, no "!", a colon kept on a carrier line). Written 2026-11-03 by the hebrew-text-editor from the teacher's unpointed drafts.

| Id | Hebrew (final, with nikud) | Voice text (for ElevenLabs) | Used in | Review |
|---|---|---|---|---|
| F01 | הַקְשִׁיבוּ, וּגְעוּ בַּתְּמוּנָה. | הקשיבו, וגעו בתמונה. | LS01 hear → picture (A-02, A-05, A-07, A-08, A-09, A-15 tap) | text-ready |
| F02 | הַקְשִׁיבוּ שׁוּב. | הקשיבו שוב. | hint level 1 in every skill (the app has no line for "listen again" yet; this is it) | text-ready |
| F03 | בּוֹאוּ נֹאמַר יַחַד. | בואו נגיד יחד. | LS09 unsure, and the new-learner echo (text-ready, hebrew-text-editor 2026-11-03; voice text בואו נגיד יחד.) | text-ready |
| F04 | שָׁמַעְתִּי: | שמעתי: | LS09 confident, followed by the word clip | text-ready |
| F05 | עַכְשָׁו אַתֶּם. | עכשיו אתם. | LS09 the pause for the child | text-ready |
| F06 | מַה זֶּה? נַסּוּ לְהַגִּיד בְּרוּסִית. | מה זה? נסו להגיד ברוסית. | LS09 picture first (A-15) | text-ready |
| F07 | מָה עוֹנִים לֶחָבֵר? | מה עונים לֶחָבֵר? | LS10 bubble choice (A-01, A-14) | text-ready |
| F08 | הַקְשִׁיבוּ, וּמִצְאוּ אֶת זֶה אֵצֶל הֶחָבֵר. | הקשיבו, ומצאו את זה אצל החבר. | LS11 body hotspots (A-03) | text-ready |
| F09 | הַקְשִׁיבוּ, וְעִזְרוּ לֶחָבֵר לַעֲשׂוֹת אֶת זֶה. | הקשיבו, ועזרו לֶחָבֵר לַעֲשׂוֹת את זה. | LS11 action buttons (A-04) | text-ready |
| F10 | עַכְשָׁו אַתֶּם! עֲשׂוּ אֶת זֶה, וְאָז גְּעוּ בַּכַּפְתּוֹר. | עכשיו אתם, עֲשׂוּ את זה, ואז געו בכפתור. | LS11 embodied version (A-03, A-04; never counted alone) | text-ready |
| F11 | הַקְשִׁיבוּ, וְשִׂימוּ אֶת זֶה בַּצַּלַּחַת שֶׁל הֶחָבֵר. | הקשיבו, וְשִׂימוּ את זה בצלחת של החבר. | LS11 picnic (A-07) | text-ready |
| F12 | הַקְשִׁיבוּ, וְשִׂימוּ אֶת זֶה בַּקֻּפְסָה. | הקשיבו, וְשִׂימוּ את זה בקופסה. | LS11 tidy-up (A-08) | text-ready |
| F13 | הַקְשִׁיבוּ, וְהַלְבִּישׁוּ אֶת הֶחָבֵר. | הקשיבו, והלבישו את החבר. | LS11 dress the friend (A-09) | text-ready |
| F14 | הַקְשִׁיבוּ, וּגְעוּ בַּצֶּבַע. | הקשיבו, וגעו בצבע. | LS01 colour patch (A-06) | text-ready |
| F15 | בּוֹאוּ נִסְפֹּר יַחַד. | בואו נספור יחד. | T02 count and tap (A-10, A-11) | text-ready |
| F16 | הַקְשִׁיבוּ לַמִּסְפָּר, וּגְעוּ בַּתְּמוּנָה. | הקשיבו למספר, וגעו בתמונה. | LS01 number → set (A-10, A-11) | text-ready |
| F17 | הַקְשִׁיבוּ לַשְּׁאֵלָה, וּגְעוּ בַּתְּשׁוּבָה. | הקשיבו לשאלה, וגעו בתשובה. | A-12 question → answer (audio options or windows) | text-ready |
| F18 | זֶה נָכוֹן? | זה נכון? | yes / no items (A-12, A-13) | text-ready |
| F19 | הַקְשִׁיבוּ, וּמִצְאוּ אֶת זֶה בַּחֶדֶר. | הקשיבו, ומצאו את זה בחדר. | LS11 scene search (A-13) | text-ready |
| F20 | הַקְשִׁיבוּ לַבַּקָּשָׁה, וּתְנוּ לֶחָבֵר אֶת מַה שֶּׁמְּבַקְשִׁים. | הקשיבו לבקשה, ותנו לֶחָבֵר את מה שמבקשים. | LS11 give (A-14) | text-ready |
| F21 | בּוֹאוּ נַקְשִׁיב לְסִפּוּר. | בואו נקשיב לסיפור. | LS08 listen (A-16) | text-ready |
| F22 | מַה יִּקְרֶה עַכְשָׁו? | מה יקרה עכשיו? | LS08 dialogic pause (A-16) | text-ready |
| F23 | מִי הָיָה בַּסִּפּוּר? | מי היה בסיפור? | A-16 story 1 question | text-ready |
| F24 | מַה מָּצָא הַקִּפּוֹד? | מה מצא הקיפוד? | A-16 story 2 question | text-ready |
| F25 | מָה חִפְּשָׂה הַיַּלְדָּה? | מה חִפְּשָׂה הילדה? | A-16 story 3 question | text-ready |
| F26 | הַקְשִׁיבוּ לַשִּׁיר. | הקשיבו לשיר. | LS12 chant (A-17) | text-ready |
| F27 | אֵיזוֹ מִלָּה מַתְאִימָה לַסּוֹף? | איזו מילה מתאימה לסוף? | LS12 rhyme gap (A-17) | text-ready |
| F28 | תּוֹפְפוּ עַל הַתֹּף: פַּעַם אַחַת לְכׇל חֵלֶק בַּמִּלָּה. | תופפו על התוף: פעם אַחַת לכל חלק במילה. | LS03 drum (A-18) | text-ready |
| F29 | בְּאֵיזוֹ תְּמוּנָה יֵשׁ שָׁלוֹשׁ מְחִיאוֹת כַּפַּיִם? | באיזו תמונה יש שָׁלוֹשׁ מחיאות כפיים? | A-18 | text-ready |
| F30 | בְּאֵיזוֹ תְּמוּנָה יֵשׁ שְׁתֵּי מְחִיאוֹת כַּפַּיִם? | באיזו תמונה יש שְׁתֵּי מחיאות כפיים? | A-18 | text-ready |
| F31 | בְּאֵיזוֹ תְּמוּנָה יֵשׁ מְחִיאַת כַּפַּיִם אַחַת? | באיזו תמונה יש מחיאת כפיים אַחַת? | A-18 | text-ready |
| F32 | בְּאֵיזוֹ תְּמוּנָה הַמִּלָּה מַתְחִילָה אוֹתוֹ דָּבָר? | באיזו תמונה המילה מתחילה אותו דבר? | A-19 same first sound | text-ready |
| F33 | הַמִּלִּים מַתְחִילוֹת אוֹתוֹ דָּבָר? | המילים מתחילות אותו דבר? | A-19 same / different start (audio options) | text-ready |
| F34 | הַקְשִׁיבוּ לִשְׁתֵּי הַמִּלִּים. אוֹתוֹ דָּבָר, אוֹ לֹא? | הקשיבו לִשְׁתֵּי המילים. אותו דבר, או לא? | A-20 same / different | text-ready |
| F35 | אֵיזוֹ מִלָּה שְׁמַעְתֶּם? | איזו מילה שמעתם? | A-20 picture choice | text-ready |
| F36 | הִסְתַּכְּלוּ עַל הַפֶּה. | הסתכלו על הפה. | A-20 hint level 2 | text-ready |
| F37 | מִי עוֹשֶׂה אֶת הַקּוֹל הַזֶּה? הַקְשִׁיבוּ לִשְׁתֵּי הַמִּלִּים. | מי עוֹשֶׂה את הקול הזה? הקשיבו לִשְׁתֵּי המילים. | A-05 animal sound → word | text-ready |
| F38 | אֵיזוֹ מִלָּה מַתְאִימָה לַתְּמוּנָה? | איזו מילה מתאימה לתמונה? | A-02 picture → two words | text-ready |
| F39 | מִישֶׁהוּ בָּא, אוֹ הוֹלֵךְ? | מישהו בא, או הולך? | A-01 picture choice | text-ready |
| F40 | כַּמָּה יֵשׁ? הַקְשִׁיבוּ לַכַּפְתּוֹרִים, וּגְעוּ בַּמִּסְפָּר הַנָּכוֹן. | כמה יש? הקשיבו לכפתורים, וגעו במספר הנכון. | T02 "how many?" after the counting (A-10, A-11 items 01–05; frame §2.2) | text-ready |

**F40** is for the "how many?" step of frame §2.2: the child has just counted along with the voice, and now chooses the number word from 3 sound buttons. The Russian teacher's draft was "כמה ספרנו? הקשיבו, וגעו במספר."; the editor made it the same line as the English `he-ins-how-many` (one clip can serve both courses, as F01 and F03 do), for three reasons: unpointed `ספרנו` can be read as "our book" (`סִפְרֵנוּ`) and would need a pointed word in the voice text; "how many did we count" asks about the counting, and the counting is practice, not the question; and "listen to the buttons, and touch the right number" tells the child that the answers are heard on a tap. 7 words, plural, no gender, no numeral named.

**What the editor changed** (the other lines only got nikud and the voice text):
- F04: first-person past: the same for every voice; a carrier before the word clip.
- F06: מַה + dagesh before a full vowel; "להגיד" is the spoken verb.
- F07: the friend is "הֶחָבֵר" (the app's word for the companion); no pronoun.
- F17: was "החבר שואל" (a masculine verb for the friend).
- F19: the object "אֶת זֶה" was missing ("find in the room" what?).
- F20: was "מה שהוא מבקש": no pronoun for the friend; the request is impersonal.
- F29: שלוש: מחיאות is feminine.
- F30: שְׁתֵּי before a noun.
- F33: מילים is feminine: מתחילות.
- F39: was "החבר בא, או הולך?" (masculine verbs for the friend).
- F40 (new): see the note under the table: the same line as the English `he-ins-how-many`.
- `parentText` of M-RUS-YESNO (second pass, 2026-11-03): the teacher's draft had two quoted phrases with a vav inside quotes (`ו"לא אותו דבר"`) and three clauses in a row; now one condition (`אם הילד עונה … בשאלות של כן ולא, או בשאלות של אותו דבר או לא`) and the same two sentences of calm. The words of the question, `אותו דבר או לא`, are the words of F34, so the parent reads what the child heard. No `да` inside it (the tag also covers same / different).
- `parentText` of M-RUS-NUMWORD (second pass): the draft said that the number word "or maybe the amount" is new and that numbers "are exchanged"; now "the child confuses adjacent numbers" (`סמוכים`: три and четыре are neighbours, they are not necessarily close in sound), and two possible reasons, each a whole clause (`ייתכן ש… או ש…`). It states no diagnosis and no blame; the home activity is unchanged.
- F01 is the same line as `he-ins-listen-tap` of the English course, F03 the same as `he-fb-together`: one clip can serve both courses if the voice director uses one voice for them.
- The friend is called "הֶחָבֵר" (the app's word for the companion) and never "הוא" or "היא"; no verb is said about the friend in these lines, so the friend's gender is not guessed (`hebrew-notes.md` §9.1). The Hebrew clip never contains a Russian word, and the lines address the children in the plural.

## 3. Misconception tags used in Band A
Kinds, families and engine ids as the shared catalogue (frame §4.2, settled 2026-11-03). The ten tags marked **new** came with this batch and were adopted (frame §4.4 R1). Each tag's kind, family, signal and re-teach are defined once, in syllabus §11; this table keeps the engine id, `parentText` and `homeActivity`, and repeats the Band A signal and re-teach for the batch. `M-RUS-COUNT` was **not adopted** and is removed: counting taps are practice (frame §2.2). `parentText` and `homeActivity` are Hebrew texts for the parent area, `text-ready` (hebrew-text-editor, 2026-11-03; adult text, no nikud, "הילד" as in the rest of the parent area), filling gap G6 for these tags. Russian words inside them are left-to-right runs.

| Tag | Engine id | Kind | Family | Signal (Band A) | Level-2 re-teach | parentText (final) | homeActivity (final) |
|---|---|---|---|---|---|---|---|
| M-RUS-SEM **new** | `rus.lis.sem` | diagnostic | MEANING | a word of the same theme chosen (another animal, another family member) | the word in its scene (the skill's level 2) | הילד כבר מכיר את הנושא, ומילים קרובות (כמו שתי חיות) עדיין מתחלפות לפעמים. זה רגיל בלמידת מילים חדשות. | הניחו שני חפצים מאותו נושא, אמרו ברוסית את השם של אחד מהם, ובקשו מהילד להצביע עליו. |
| M-RUS-SOUND **new** | `rus.voc.sound` | diagnostic | GUESS | a word that sounds like the target chosen (сок / суп, кот / кит, семь / во́семь) | the two words said one after the other, each with its picture | מילים שנשמעות דומה (сок ו־суп) עדיין מתחלפות לילד. זה שלב רגיל בלמידת שפה חדשה. | אמרו לאט שתי מילים דומות, אחת אחרי השנייה, והצביעו על התמונה של כל אחת. |
| M-RUS-KTO **new** | `rus.grm.kto` | diagnostic | GRAMMAR | a thing chosen for Кто э́то?, or a living being for Что э́то? | alive or not: the living ones move, the things stay still | ברוסית שואלים кто ("מי") על אנשים ועל בעלי חיים, ו־что ("מה") על חפצים. בעברית אומרים "מה זה?" גם על חתול, ולכן זה מבלבל בהתחלה. | בספר תמונות: על חיה או על אדם שאלו "Кто это?", ועל חפץ שאלו "Что это?". |
| M-RUS-TYVY **new** | `rus.lis.tyvy` | diagnostic | GRAMMAR | приве́т or пока́ chosen for a grown-up who is not family | the scene acted: the grown-up arrives, the friend greets with здра́вствуйте | למבוגר שאינו מהמשפחה אומרים ברוסית здравствуйте ו־до свидания, ולחבר привет ו־пока. זו הצורה המנומסת; במשפחה ובין חברים מדברים כרגיל. | כשפוגשים מבוגר שמדבר רוסית, אמרו יחד "здравствуйте". |
| M-RUS-YESNO **new** | `rus.grm.yesno` | diagnostic | GUESS | a two-way answer given by habit: да on a "no" item, нет on a "yes" item, or "different" on a "same" pair (A-19, A-20) | yes / no: the friend points and says the thing's real name; same / different: the two clips again, each lighting its own card | אם הילד עונה כל פעם אותה תשובה בשאלות של כן ולא, או בשאלות של אותו דבר או לא, כנראה שהשאלה עדיין לא ברורה לו עד הסוף. זה נורמלי בהתחלה. | שאלו בצחוק "Это кот?" על דברים בבית, לפעמים נכון ולפעמים לא, וענו יחד да או нет. |
| M-RUS-NUMWORD **new** | `rus.num.numword` | diagnostic | MEANING | the set next to the heard number chosen (number → set), or the number word next to the count chosen after counting ("how many?") | fingers: the number shown one finger at a time | כשהילד מתבלבל בין מספרים סמוכים (три ו־четыре), ייתכן שמילת המספר ברוסית עדיין חדשה לו, או שהכמות עצמה עדיין חדשה לו. זה רגיל בגיל הזה. | ספרו יחד ברוסית דברים בבית: מדרגות, כפיות, צעצועים. |
| M-RUS-RHYME-ONSET **new** | `rus.pho.rhyme_onset` | diagnostic | RHYME | a word with the same start chosen instead of the rhyme (но́ги for нос) | word pairs: the line-1 rhyme word before each option | כשמחפשים חרוז, ילדים בוחרים לפעמים מילה שמתחילה אותו דבר (нос ו־ноги) במקום מילה שנגמרת אותו דבר. | אמרו שתי מילים מתחרזות ברוסית (кот – рот) ושאלו: נשמע דומה בסוף? |
| M-RUS-SYLL **new** | `rus.pho.syll` | diagnostic | SEGMENT | one beat more or fewer on the drum, or the picture with the wrong number of claps | a hand claps with the child on each beat | בספירת חלקי מילה במחיאות כפיים, קורה שהילד מוחא פעם אחת יותר או פחות. | מחאו כפיים יחד לכל חלק בשמות של צעצועים: ку-кла, ма-ши-на. |
| M-RUS-NOTFIRST **new** | `rus.pho.notfirst` | diagnostic | SEGMENT | a word with the sound at the end chosen (дом for м) | the mouth shows the first sound while each option is said with its first sound held | הילד שומע את הצליל במילה, אבל עוד לא ברור לו שהוא בהתחלה. | משחק "מה מתחיל ב־ммм?": משכו את הצליל הראשון של מילה, ומצאו עוד דבר שמתחיל כך. |
| M-RUS-SEQ **new** | `rus.lis.seq` | diagnostic | MEANING | after a story, a picture that did not happen in it | the pages laid out in a row and replayed | אחרי הסיפור הילד בחר תמונה שלא הייתה בו. כדאי להקשיב לסיפור שוב, עם התמונות. | קראו יחד ספר תמונות ושאלו "מה יקרה עכשיו?" לפני שמדפדפים. |
| M-RUS-HARDSOFT | `rus.pho.hardsoft` | diagnostic | CONTRAST | лук chosen for люк (A-20) | the mouth: a wide smile for the soft one | ברוסית יש עיצורים "רכים" ו"קשים" (лук "בצל", люк "מכסה בכביש"). בעברית אין הבדל כזה, ולכן לוקח זמן לשמוע אותו. | אמרו את הזוג лук – люк, עם חיוך רחב ב־люк, ושחקו "איזו מילה שמעתם?". |
| M-RUS-YI | `rus.pho.yi` | diagnostic | CONTRAST | ми́шка chosen for мы́шка; "same" for мы / ми (A-20) | the puzzled friend says "ы…" | הצליל ы לא קיים בעברית, ולכן мышка ("עכבר") ו־мишка ("דובי") נשמעות דומה. | עשו יחד "פרצוף מתלבט" ואמרו ы…, ואחר כך мышка ו־мишка. |

`revisitWith`: M-RUS-HARDSOFT with M-RUS-YI; M-RUS-SOUND items with their pair (сок / суп, кот / кит, мышь / ми́шка, шесть / семь, семь / во́семь, де́вять / де́сять). M-RUS-R (accent) is never on a distractor and never judged, so it is not in this table.

## 4. The skills

### RUS-A-01 Greetings
*Strand LIS/SPK · prerequisites — · templates: LS01 pictorial, LS10 puppet talk with the say step (LS09), LS10 `personal` (optional)*

**Teach screens (LS09, new-learner route):** set 1: приве́т, пока́, здра́вствуйте, до свида́ния. Each word: the picture, the word clip twice with F05 between (F03 if the child is shy), then on.

| Route | How the skill is served |
|---|---|
| New learner | All four teach screens (LS09, picture and clip twice); items 01 to 07 in order; the say step is echo first |
| Heritage | No teach screens; starts at 04 (LS10); say step picture first; 06 and 07 (the grown-up forms) weighted up |
| Reader | As heritage or new, by strand 1 |

| Item | Template | Frame (Hebrew) → Russian clip | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|
| `rus.a01.01` | LS01 pictorial | F39 → `w-privet` | приве́т `pic.rus.arrive` | пока́ `pic.rus.leave` (M-RUS-SEM) · спаси́бо `pic.rus.gift` (M-RUS-SEM) | NHR | pictures: arriving ✓, leaving, being given an apple |
| `rus.a01.02` | LS01 pictorial | F39 → `w-poka` | пока́ `pic.rus.leave` | приве́т `pic.rus.arrive` (M-RUS-SEM) · спаси́бо `pic.rus.gift` (M-RUS-SEM) | NHR |  |
| `rus.a01.03` C | LS01 pictorial | F39 → `w-do-svidanija` | `pic.rus.leave` | приве́т `pic.rus.arrive` (M-RUS-SEM) · спаси́бо `pic.rus.gift` (M-RUS-SEM) | NHR | до свида́ния heard; the leaving picture is the answer (both are goodbye) |
| `rus.a01.04` | LS10 bubbles | F07 → `w-privet` | приве́т `pic.rus.arrive` | пока́ `pic.rus.leave` (M-RUS-SEM) · спаси́бо `pic.rus.gift` (M-RUS-SEM) | NHR | a child friend arrives and says Приве́т!; the bubbles are heard on tap; then the say step |
| `rus.a01.05` | LS10 bubbles | F07 → `w-poka` | пока́ `pic.rus.leave` | приве́т `pic.rus.arrive` (M-RUS-SEM) · здра́вствуйте `w-zdravstvujte` (M-RUS-SEM) | NHR | the child friend leaves |
| `rus.a01.06` | LS10 bubbles | F07 → `w-zdravstvuj` | здра́вствуйте `w-zdravstvujte` | приве́т `pic.rus.arrive` (M-RUS-TYVY) · пока́ `pic.rus.leave` (M-RUS-SEM) | NHR | a grown-up neighbour (not family) arrives and greets the child with Здра́вствуй!; the child answers a grown-up with Здра́вствуйте |
| `rus.a01.07` C | LS10 bubbles | F07 → `w-do-svidanija` | до свида́ния `w-do-svidanija` | пока́ `pic.rus.leave` (M-RUS-TYVY) · приве́т `pic.rus.arrive` (M-RUS-SEM) | NHR | the neighbour leaves with До свида́ния! |
| `rus.a01.08` | LS10 personal | — → `ch-menja-zovut` + `ch-kak-tebja-zovut` | (not checked) | — | NHR | optional, never scored (frame §5.2): the puppet says its own name first (`ch-menja-zovut`: shown `Меня зовут Саша.`, said `Меня́ зову́т Са́ша.`; the puppet is Са́ша, a fixed character, so the name is written in the line and no placeholder is sent to a voice); the child says a name (voice on) or taps "pass"; the puppet answers ch-ochen-prijatno, or ch-horosho after a pass. The name is never matched, kept or repeated |

**Hint ladder.** 1: the line again, slower, with the friend's hand already waving in or out (F02). 2: the scene is acted (story): the door opens and the friend walks in, or out, while the voice says the word. 3: show me: the right picture or bubble glows, the voice says the word, the friend waves; the child taps it to go on (no credit), and the word comes back later in a fresh item.

**Mastery and notes.** LS01 pictorial (01–03) and LS10 role-play (04–07): two representations. Coverage: приве́т, пока́, здра́вствуйте, до свида́ния each right once without a hint.

### RUS-A-02 Family
*Strand VOC · prerequisites — · templates: LS01 pictorial (the original family picture; never the child's own family), LS01 audio options, LS09 teach, LS10 `personal` (optional)*

**Teach screens (LS09, new-learner route):** set 1: ма́ма, па́па, ба́бушка, де́душка · set 2: брат, сестра́, малы́ш, семья́ · set 3: ма́льчик, де́вочка. Each word: the picture, the word clip twice with F05 between (F03 if the child is shy), then on.

| Route | How the skill is served |
|---|---|
| New learner | Teach in three sets (LS09); items 01–14, two sets at a time, each word right once |
| Heritage | No teach screens; items 05–15; picture first in the say-it of A-15 |
| Reader | As heritage or new, by strand 1; with Band B or C presentation the word appears under the picture after the answer, without a stress mark |

| Item | Template | Frame (Hebrew) → Russian clip | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|
| `rus.a02.01` | LS01 pictorial | F01 → — | ма́ма `pic.fam.mother` | па́па `pic.fam.father` (M-RUS-SOUND) · ба́бушка `pic.fam.grandmother` (M-RUS-SEM) | NHR |  |
| `rus.a02.02` | LS01 pictorial | F01 → — | па́па `pic.fam.father` | ма́ма `pic.fam.mother` (M-RUS-SOUND) · де́душка `pic.fam.grandfather` (M-RUS-SEM) | NHR |  |
| `rus.a02.03` | LS01 pictorial | F01 → — | ба́бушка `pic.fam.grandmother` | де́душка `pic.fam.grandfather` (M-RUS-SOUND) · ма́ма `pic.fam.mother` (M-RUS-SEM) | NHR |  |
| `rus.a02.04` | LS01 pictorial | F01 → — | де́душка `pic.fam.grandfather` | ба́бушка `pic.fam.grandmother` (M-RUS-SOUND) · па́па `pic.fam.father` (M-RUS-SEM) | NHR |  |
| `rus.a02.05` | LS01 pictorial | F01 → — | брат `pic.fam.brother` | сестра́ `pic.fam.sister` (M-RUS-SEM) · па́па `pic.fam.father` (M-RUS-SEM) | NHR |  |
| `rus.a02.06` | LS01 pictorial | F01 → — | сестра́ `pic.fam.sister` | брат `pic.fam.brother` (M-RUS-SEM) · ба́бушка `pic.fam.grandmother` (M-RUS-SEM) | NHR |  |
| `rus.a02.07` | LS01 pictorial | F01 → — | малы́ш `pic.fam.baby` | де́душка `pic.fam.grandfather` (M-RUS-SEM) · ба́бушка `pic.fam.grandmother` (M-RUS-SEM) | NHR |  |
| `rus.a02.08` | LS01 pictorial | F01 → — | ма́льчик `pic.boy` | де́вочка `pic.girl` (M-RUS-SEM) · де́душка `pic.fam.grandfather` (M-RUS-SEM) | NHR |  |
| `rus.a02.09` C | LS01 pictorial | F01 → — | де́вочка `pic.girl` | ма́льчик `pic.boy` (M-RUS-SEM) · ба́бушка `pic.fam.grandmother` (M-RUS-SEM) | NHR |  |
| `rus.a02.10` C | LS01 pictorial | F01 → — | семья́ `pic.fam.all` | ма́ма `pic.fam.mother` (M-RUS-SEM) · малы́ш `pic.fam.baby` (M-RUS-SEM) | NHR |  |
| `rus.a02.11` | LS01 audio options (2) | F38 → — | ба́бушка `pic.fam.grandmother` | де́душка `pic.fam.grandfather` (M-RUS-SOUND) | NHR | picture: the grandmother; two sound buttons |
| `rus.a02.12` | LS01 audio options (2) | F38 → — | па́па `pic.fam.father` | ма́ма `pic.fam.mother` (M-RUS-SOUND) | NHR | picture: the father |
| `rus.a02.13` | LS01 audio options (2) | F38 → — | сестра́ `pic.fam.sister` | брат `pic.fam.brother` (M-RUS-SEM) | NHR | picture: the sister |
| `rus.a02.14` | LS01 audio options (2) | F38 → — | ма́льчик `pic.boy` | де́вочка `pic.girl` (M-RUS-SEM) | NHR | picture: the boy |
| `rus.a02.15` | LS10 personal | — → `ch-u-menja-est` + `ch-kto-u-tebja-v-seme` | (not checked) | — | NHR | optional, never scored (frame §5.2): the puppet tells its own family first; the child taps family pictures of many shapes (parents, one parent, grandparents, siblings, cousins, pets, "someone else") or passes; the puppet answers ch-zdorovo, or ch-horosho after a pass; no follow-up |

**Hint ladder.** 1: the word again, slowly, twice (F02). 2: the family picture: the person waves inside the whole family, and the voice says the word (from a single picture to the person in context). 3: show me: the right picture glows and the word is said; a tap goes on; the word returns later.

**Mastery and notes.** hear → picture (01–10) and picture → two words (11–14). брат and ма́льчик, сестра́ and де́вочка are never options in the same item (a brother is also a boy).

### RUS-A-03 Body
*Strand VOC/LIS · prerequisites A-01 · templates: LS11 hotspots on the friend and on a doll; the embodied version (the child shows it on themself and taps the button; F10, never counted alone)*

**Teach screens (LS09, new-learner route):** set 1: нос, рот, глаза́, у́ши · set 2: ру́ки, но́ги, живо́т, голова́ · set 3: па́льцы, зу́бы, во́лосы. Each word: the picture, the word clip twice with F05 between (F03 if the child is shy), then on.

| Route | How the skill is served |
|---|---|
| New learner | Teach in three sets; items 01–15 |
| Heritage | No teach screens; items 01–15 mixed; the embodied step after each correct tap |
| Reader | As heritage or new |

| Item | Template | Frame (Hebrew) → Russian clip | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|
| `rus.a03.01` | LS11 hotspots | F08 → `ch-pokazhi-nos` | нос `hot.nose` | рот `hot.mouth` (M-RUS-SOUND) · глаза́ `hot.eyes` (M-RUS-SEM) | NHR | on the friend; only these three parts glow |
| `rus.a03.02` | LS11 hotspots | F08 → `ch-pokazhi-rot` | рот `hot.mouth` | нос `hot.nose` (M-RUS-SOUND) · у́ши `hot.ears` (M-RUS-SEM) | NHR |  |
| `rus.a03.03` | LS11 hotspots | F08 → `ch-pokazhi-glaza` | глаза́ `hot.eyes` | у́ши `hot.ears` (M-RUS-SEM) · нос `hot.nose` (M-RUS-SEM) | NHR |  |
| `rus.a03.04` | LS11 hotspots | F08 → `ch-pokazhi-ushi` | у́ши `hot.ears` | глаза́ `hot.eyes` (M-RUS-SEM) · ру́ки `hot.arms` (M-RUS-SOUND) | NHR |  |
| `rus.a03.05` | LS11 hotspots | F08 → `ch-pokazhi-ruki` | ру́ки `hot.arms` | но́ги `hot.legs` (M-RUS-SEM) · у́ши `hot.ears` (M-RUS-SOUND) | NHR |  |
| `rus.a03.06` | LS11 hotspots | F08 → `ch-pokazhi-nogi` | но́ги `hot.legs` | ру́ки `hot.arms` (M-RUS-SEM) · нос `hot.nose` (M-RUS-SOUND) | NHR |  |
| `rus.a03.07` | LS11 hotspots | F08 → `ch-pokazhi-zhivot` | живо́т `hot.belly` | голова́ `hot.head` (M-RUS-SEM) · но́ги `hot.legs` (M-RUS-SEM) | NHR |  |
| `rus.a03.08` | LS11 hotspots | F08 → `ch-pokazhi-paltsy` | па́льцы `hot.fingers` | нос `hot.nose` (M-RUS-SEM) · во́лосы `hot.hair` (M-RUS-SEM) | NHR |  |
| `rus.a03.09` | LS11 hotspots | F08 → `ch-pokazhi-zuby` | зу́бы `hot.teeth` | глаза́ `hot.eyes` (M-RUS-SEM) · у́ши `hot.ears` (M-RUS-SEM) | NHR |  |
| `rus.a03.10` | LS11 hotspots | F08 → `ch-pokazhi-volosy` | во́лосы `hot.hair` | живо́т `hot.belly` (M-RUS-SEM) · ру́ки `hot.arms` (M-RUS-SEM) | NHR |  |
| `rus.a03.11` | LS11 hotspots | F08 → `ch-pokazhi-golovu` | голова́ `hot.head` | но́ги `hot.legs` (M-RUS-SEM) · живо́т `hot.belly` (M-RUS-SEM) | NHR |  |
| `rus.a03.12` | LS11 hotspots (doll) | F08 → `ch-pokazhi-nos` | нос `hot.nose` | рот `hot.mouth` (M-RUS-SOUND) · глаза́ `hot.eyes` (M-RUS-SEM) | NHR | the same command on a doll in a dress-up scene (second representation) |
| `rus.a03.13` | LS11 hotspots (doll) | F08 → `ch-pokazhi-ushi` | у́ши `hot.ears` | глаза́ `hot.eyes` (M-RUS-SEM) · ру́ки `hot.arms` (M-RUS-SOUND) | NHR |  |
| `rus.a03.14` C | LS11 hotspots (doll) | F08 → `ch-pokazhi-nogi` | но́ги `hot.legs` | ру́ки `hot.arms` (M-RUS-SEM) · нос `hot.nose` (M-RUS-SOUND) | NHR |  |
| `rus.a03.15` C | LS11 hotspots (doll) | F08 → `ch-pokazhi-zhivot` | живо́т `hot.belly` | голова́ `hot.head` (M-RUS-SEM) · но́ги `hot.legs` (M-RUS-SEM) | NHR |  |

**Hint ladder.** 1: the command again, slowly (F02). 2: embodied: the friend touches its own part and wiggles it while the word is said (a new representation: action). 3: show me: the part glows and the word clip plays; a tap goes on.

**Mastery and notes.** Покажи́ го́лову: the stress moves (голова́ → го́лову); the plural parts are the same in the command. Hotspots never overlap: no item asks рот with зу́бы, па́льцы with ру́ки, or во́лосы with голова́ as options.

### RUS-A-04 ● One-step commands
*Strand LIS · prerequisites A-03 · templates: LS01 pictorial, LS11 action buttons, the embodied version (F10, never counted alone)*

**Teach screens (LS09, new-learner route):** set 1: иди́, беги́, пры́гай · set 2: сядь, встань, хло́пай, возьми́ мяч. Each word: the picture, the word clip twice with F05 between (F03 if the child is shy), then on.

| Route | How the skill is served |
|---|---|
| New learner | Teach in two sets; items 01–13; the embodied step after each LS11 item |
| Heritage | No teach screens; items 08–13 then 01–07; the embodied step offered |
| Reader | As heritage or new |

| Item | Template | Frame (Hebrew) → Russian clip | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|
| `rus.a04.01` | LS01 pictorial | F01 → — | иди́ `pic.act.walk` | беги́ `pic.act.run` (M-RUS-SEM) · сядь `pic.act.sit` (M-RUS-SEM) | NHR | static action pictures |
| `rus.a04.02` | LS01 pictorial | F01 → — | беги́ `pic.act.run` | иди́ `pic.act.walk` (M-RUS-SEM) · пры́гай `pic.act.jump` (M-RUS-SEM) | NHR |  |
| `rus.a04.03` | LS01 pictorial | F01 → — | пры́гай `pic.act.jump` | хло́пай `pic.act.clap` (M-RUS-SOUND) · беги́ `pic.act.run` (M-RUS-SEM) | NHR |  |
| `rus.a04.04` | LS01 pictorial | F01 → — | хло́пай `pic.act.clap` | пры́гай `pic.act.jump` (M-RUS-SOUND) · встань `pic.act.stand` (M-RUS-SEM) | NHR |  |
| `rus.a04.05` | LS01 pictorial | F01 → — | сядь `pic.act.sit` | встань `pic.act.stand` (M-RUS-SEM) · иди́ `pic.act.walk` (M-RUS-SEM) | NHR |  |
| `rus.a04.06` | LS01 pictorial | F01 → — | встань `pic.act.stand` | сядь `pic.act.sit` (M-RUS-SEM) · хло́пай `pic.act.clap` (M-RUS-SEM) | NHR |  |
| `rus.a04.07` C | LS01 pictorial | F01 → — | возьми́ мяч `pic.act.take` | сядь `pic.act.sit` (M-RUS-SEM) · хло́пай `pic.act.clap` (M-RUS-SEM) | NHR |  |
| `rus.a04.08` | LS11 action buttons | F09 → — | иди́ `pic.act.walk` | беги́ `pic.act.run` (M-RUS-SEM) · сядь `pic.act.sit` (M-RUS-SEM) | NHR | the friend in a playground does what the child taps |
| `rus.a04.09` | LS11 action buttons | F09 → — | беги́ `pic.act.run` | иди́ `pic.act.walk` (M-RUS-SEM) · пры́гай `pic.act.jump` (M-RUS-SEM) | NHR |  |
| `rus.a04.10` | LS11 action buttons | F09 → — | пры́гай `pic.act.jump` | хло́пай `pic.act.clap` (M-RUS-SOUND) · беги́ `pic.act.run` (M-RUS-SEM) | NHR |  |
| `rus.a04.11` | LS11 action buttons | F09 → — | хло́пай `pic.act.clap` | пры́гай `pic.act.jump` (M-RUS-SOUND) · встань `pic.act.stand` (M-RUS-SEM) | NHR |  |
| `rus.a04.12` C | LS11 action buttons | F09 → — | сядь `pic.act.sit` | встань `pic.act.stand` (M-RUS-SEM) · иди́ `pic.act.walk` (M-RUS-SEM) | NHR |  |
| `rus.a04.13` C | LS11 action buttons | F09 → — | встань `pic.act.stand` | сядь `pic.act.sit` (M-RUS-SEM) · хло́пай `pic.act.clap` (M-RUS-SEM) | NHR |  |

**Hint ladder.** 1: the command again, with the friend getting ready (no hint of which action) (F02). 2: embodied: the voice says the command and a small figure does the action once, in a new place (motion instead of a still picture). 3: show me: the friend does it while the command is said; a tap goes on.

**Mastery and notes.** Core skill: 6 correct over 2 days, 2 checks; LS01 and LS11 both needed. дай and покажи́ are met in A-14 and A-03.

### RUS-A-05 Animals
*Strand VOC · prerequisites — · templates: LS01 pictorial, LS01 audio options after an animal sound effect, LS09 teach*

**Teach screens (LS09, new-learner route):** set 1: ко́шка, соба́ка, мышь, ры́ба, пти́ца · set 2: коро́ва, ло́шадь, свинья́, коза́ · set 3: у́тка, ку́рица, пету́х · set 4: за́яц, медве́дь, волк, лиса́ · set 5: ёж, бе́лка, слон, жира́ф · set 6: кот, кит. Each word: the picture, the word clip twice with F05 between (F03 if the child is shy), then on.

| Route | How the skill is served |
|---|---|
| New learner | Teach in six sets; items of two sets at a time; set coverage before mastery |
| Heritage | No teach screens; items 01–32 in mixed sets; кот / ко́шка both accepted in the say-it of A-15 |
| Reader | As heritage or new |

| Item | Template | Frame (Hebrew) → Russian clip | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|
| `rus.a05.01` | LS01 pictorial | F01 → — | ко́шка `pic.cat` | соба́ка `pic.dog` (M-RUS-SEM) · мышь `pic.mouse` (M-RUS-SEM) | NHR |  |
| `rus.a05.02` | LS01 pictorial | F01 → — | кот `pic.tomcat` | соба́ка `pic.dog` (M-RUS-SEM) · кит `pic.whale` (M-RUS-SOUND) | NHR |  |
| `rus.a05.03` | LS01 pictorial | F01 → — | соба́ка `pic.dog` | ко́шка `pic.cat` (M-RUS-SEM) · коро́ва `pic.cow` (M-RUS-SEM) | NHR |  |
| `rus.a05.04` | LS01 pictorial | F01 → — | мышь `pic.mouse` | ко́шка `pic.cat` (M-RUS-SEM) · ми́шка `pic.teddy` (M-RUS-SOUND) | NHR |  |
| `rus.a05.05` | LS01 pictorial | F01 → — | ры́ба `pic.fish` | пти́ца `pic.bird` (M-RUS-SEM) · кит `pic.whale` (M-RUS-SEM) | NHR |  |
| `rus.a05.06` | LS01 pictorial | F01 → — | пти́ца `pic.bird` | ры́ба `pic.fish` (M-RUS-SEM) · бе́лка `pic.squirrel` (M-RUS-SEM) | NHR |  |
| `rus.a05.07` | LS01 pictorial | F01 → — | коро́ва `pic.cow` | коза́ `pic.goat` (M-RUS-SOUND) · ло́шадь `pic.horse` (M-RUS-SEM) | NHR |  |
| `rus.a05.08` | LS01 pictorial | F01 → — | ло́шадь `pic.horse` | коро́ва `pic.cow` (M-RUS-SEM) · свинья́ `pic.pig` (M-RUS-SEM) | NHR |  |
| `rus.a05.09` | LS01 pictorial | F01 → — | свинья́ `pic.pig` | коро́ва `pic.cow` (M-RUS-SEM) · семья́ `pic.fam.all` (M-RUS-SOUND) | NHR |  |
| `rus.a05.10` | LS01 pictorial | F01 → — | коза́ `pic.goat` | коро́ва `pic.cow` (M-RUS-SOUND) · свинья́ `pic.pig` (M-RUS-SEM) | NHR |  |
| `rus.a05.11` | LS01 pictorial | F01 → — | у́тка `pic.duck` | ку́рица `pic.hen` (M-RUS-SEM) · ры́ба `pic.fish` (M-RUS-SEM) | NHR |  |
| `rus.a05.12` | LS01 pictorial | F01 → — | ку́рица `pic.hen` | пету́х `pic.rooster` (M-RUS-SEM) · у́тка `pic.duck` (M-RUS-SEM) | NHR |  |
| `rus.a05.13` | LS01 pictorial | F01 → — | пету́х `pic.rooster` | ку́рица `pic.hen` (M-RUS-SEM) · у́тка `pic.duck` (M-RUS-SEM) | NHR |  |
| `rus.a05.14` | LS01 pictorial | F01 → — | за́яц `pic.hare` | бе́лка `pic.squirrel` (M-RUS-SEM) · ёж `pic.hedgehog` (M-RUS-SEM) | NHR |  |
| `rus.a05.15` | LS01 pictorial | F01 → — | медве́дь `pic.bear` | волк `pic.wolf` (M-RUS-SEM) · слон `pic.elephant` (M-RUS-SEM) | NHR |  |
| `rus.a05.16` | LS01 pictorial | F01 → — | волк `pic.wolf` | соба́ка `pic.dog` (M-RUS-SEM) · лиса́ `pic.fox` (M-RUS-SEM) | NHR |  |
| `rus.a05.17` | LS01 pictorial | F01 → — | лиса́ `pic.fox` | волк `pic.wolf` (M-RUS-SEM) · ко́шка `pic.cat` (M-RUS-SEM) | NHR |  |
| `rus.a05.18` | LS01 pictorial | F01 → — | ёж `pic.hedgehog` | за́яц `pic.hare` (M-RUS-SEM) · мышь `pic.mouse` (M-RUS-SEM) | NHR |  |
| `rus.a05.19` | LS01 pictorial | F01 → — | бе́лка `pic.squirrel` | за́яц `pic.hare` (M-RUS-SEM) · лиса́ `pic.fox` (M-RUS-SEM) | NHR |  |
| `rus.a05.20` | LS01 pictorial | F01 → — | слон `pic.elephant` | медве́дь `pic.bear` (M-RUS-SEM) · жира́ф `pic.giraffe` (M-RUS-SEM) | NHR |  |
| `rus.a05.21` C | LS01 pictorial | F01 → — | жира́ф `pic.giraffe` | слон `pic.elephant` (M-RUS-SEM) · шарф `pic.scarf` (M-RUS-SOUND) | NHR |  |
| `rus.a05.22` C | LS01 pictorial | F01 → — | кит `pic.whale` | ры́ба `pic.fish` (M-RUS-SEM) · кот `pic.tomcat` (M-RUS-SOUND) | NHR |  |
| `rus.a05.23` | LS01 audio options (2) | F37 → — | ко́шка `pic.cat` | соба́ка `pic.dog` (M-RUS-SEM) | NHR | a real animal sound effect (no words), then two sound buttons |
| `rus.a05.24` | LS01 audio options (2) | F37 → — | соба́ка `pic.dog` | ко́шка `pic.cat` (M-RUS-SEM) | NHR |  |
| `rus.a05.25` | LS01 audio options (2) | F37 → — | коро́ва `pic.cow` | коза́ `pic.goat` (M-RUS-SOUND) | NHR |  |
| `rus.a05.26` | LS01 audio options (2) | F37 → — | ло́шадь `pic.horse` | коро́ва `pic.cow` (M-RUS-SEM) | NHR |  |
| `rus.a05.27` | LS01 audio options (2) | F37 → — | свинья́ `pic.pig` | коро́ва `pic.cow` (M-RUS-SEM) | NHR |  |
| `rus.a05.28` | LS01 audio options (2) | F37 → — | коза́ `pic.goat` | коро́ва `pic.cow` (M-RUS-SOUND) | NHR |  |
| `rus.a05.29` | LS01 audio options (2) | F37 → — | у́тка `pic.duck` | пету́х `pic.rooster` (M-RUS-SEM) | NHR |  |
| `rus.a05.30` | LS01 audio options (2) | F37 → — | пету́х `pic.rooster` | ку́рица `pic.hen` (M-RUS-SEM) | NHR |  |
| `rus.a05.31` | LS01 audio options (2) | F37 → — | мышь `pic.mouse` | ми́шка `pic.teddy` (M-RUS-SOUND) | NHR |  |
| `rus.a05.32` | LS01 audio options (2) | F37 → — | волк `pic.wolf` | соба́ка `pic.dog` (M-RUS-SEM) | NHR |  |

**Hint ladder.** 1: the word again, slowly, twice (F02). 2: the animal comes alive: it moves and makes its real sound while the word is said (a scene instead of a still picture). 3: show me: the right picture glows and the word is said; a tap goes on.

**Mastery and notes.** ко́шка and кот never appear in the same item (both name a cat); a bird target never has пти́ца as a distractor (a duck is also a bird). Sound effects are real animal recordings from the sound library (voice-and-sound-director), not voiced words.

### RUS-A-06 Colours
*Strand VOC · prerequisites A-05 · templates: LS01 colour patches, LS01 objects of one kind in three colours*

**Teach screens (LS09, new-learner route):** set 1: кра́сный, си́ний, жёлтый · set 2: зелёный, бе́лый, чёрный. Each word: the picture, the word clip twice with F05 between (F03 if the child is shy), then on.

| Route | How the skill is served |
|---|---|
| New learner | Teach in two sets; items 01–12 |
| Heritage | No teach screens; items 07–12 then 01–06 |
| Reader | As heritage or new |

| Item | Template | Frame (Hebrew) → Russian clip | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|
| `rus.a06.01` | LS01 colour patch | F14 → — | кра́сный `col.red` | жёлтый `col.yellow` (M-RUS-SEM) · си́ний `col.blue` (M-RUS-SEM) | NHR |  |
| `rus.a06.02` | LS01 colour patch | F14 → — | си́ний `col.blue` | зелёный `col.green` (M-RUS-SEM) · чёрный `col.black` (M-RUS-SEM) | NHR |  |
| `rus.a06.03` | LS01 colour patch | F14 → — | жёлтый `col.yellow` | зелёный `col.green` (M-RUS-SOUND) · бе́лый `col.white` (M-RUS-SEM) | NHR |  |
| `rus.a06.04` | LS01 colour patch | F14 → — | зелёный `col.green` | жёлтый `col.yellow` (M-RUS-SOUND) · си́ний `col.blue` (M-RUS-SEM) | NHR |  |
| `rus.a06.05` | LS01 colour patch | F14 → — | бе́лый `col.white` | чёрный `col.black` (M-RUS-SEM) · жёлтый `col.yellow` (M-RUS-SEM) | NHR |  |
| `rus.a06.06` | LS01 colour patch | F14 → — | чёрный `col.black` | бе́лый `col.white` (M-RUS-SEM) · кра́сный `col.red` (M-RUS-SOUND) | NHR |  |
| `rus.a06.07` | LS01 object colour | F14 → — | кра́сный `col.red` | жёлтый `col.yellow` (M-RUS-SEM) · си́ний `col.blue` (M-RUS-SEM) | NHR | three balls (мяч) or three balloons (ша́рик) that differ only in colour |
| `rus.a06.08` | LS01 object colour | F14 → — | си́ний `col.blue` | зелёный `col.green` (M-RUS-SEM) · чёрный `col.black` (M-RUS-SEM) | NHR |  |
| `rus.a06.09` | LS01 object colour | F14 → — | жёлтый `col.yellow` | зелёный `col.green` (M-RUS-SOUND) · бе́лый `col.white` (M-RUS-SEM) | NHR |  |
| `rus.a06.10` | LS01 object colour | F14 → — | зелёный `col.green` | жёлтый `col.yellow` (M-RUS-SOUND) · си́ний `col.blue` (M-RUS-SEM) | NHR |  |
| `rus.a06.11` C | LS01 object colour | F14 → — | бе́лый `col.white` | чёрный `col.black` (M-RUS-SEM) · жёлтый `col.yellow` (M-RUS-SEM) | NHR |  |
| `rus.a06.12` C | LS01 object colour | F14 → — | чёрный `col.black` | бе́лый `col.white` (M-RUS-SEM) · кра́сный `col.red` (M-RUS-SOUND) | NHR |  |

**Hint ladder.** 1: the word again, slowly (F02). 2: the colour on a familiar thing, shown without words: red on an apple, yellow on the sun, green on grass, blue on the sea, white on snow, black on a night sky (a new representation: the world instead of a patch). 3: show me: the patch glows and the word is said.

**Mastery and notes.** Only the masculine form is heard (кра́сный), alone or with masculine objects, so no agreement is met before B-02. си́ний is a medium-dark blue; light blue is голубо́й, a different colour in Russian, taught later.

### RUS-A-07 Food and drink
*Strand VOC · prerequisites — · templates: LS01 pictorial, LS11 picnic drag, LS09 teach*

**Teach screens (LS09, new-learner route):** set 1: молоко́, вода́, сок, чай · set 2: хлеб, сыр, суп, ка́ша, яйцо́, пече́нье · set 3: я́блоко, бана́н, гру́ша, апельси́н · set 4: клубни́ка, виногра́д, арбу́з · set 5: морко́вь, огуре́ц, помидо́р, карто́шка. Each word: the picture, the word clip twice with F05 between (F03 if the child is shy), then on.

| Route | How the skill is served |
|---|---|
| New learner | Teach in five sets; items of two sets at a time |
| Heritage | No teach screens; items 22–27 first, then 01–21 mixed |
| Reader | As heritage or new |

| Item | Template | Frame (Hebrew) → Russian clip | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|
| `rus.a07.01` | LS01 pictorial | F01 → — | молоко́ `pic.milk` | вода́ `pic.water` (M-RUS-SEM) · сок `pic.juice` (M-RUS-SEM) | NHR |  |
| `rus.a07.02` | LS01 pictorial | F01 → — | вода́ `pic.water` | молоко́ `pic.milk` (M-RUS-SEM) · чай `pic.tea` (M-RUS-SEM) | NHR |  |
| `rus.a07.03` | LS01 pictorial | F01 → — | сок `pic.juice` | суп `pic.soup` (M-RUS-SOUND) · вода́ `pic.water` (M-RUS-SEM) | NHR |  |
| `rus.a07.04` | LS01 pictorial | F01 → — | чай `pic.tea` | молоко́ `pic.milk` (M-RUS-SEM) · сок `pic.juice` (M-RUS-SEM) | NHR |  |
| `rus.a07.05` | LS01 pictorial | F01 → — | хлеб `pic.bread` | сыр `pic.cheese` (M-RUS-SEM) · пече́нье `pic.cookie` (M-RUS-SEM) | NHR |  |
| `rus.a07.06` | LS01 pictorial | F01 → — | сыр `pic.cheese` | суп `pic.soup` (M-RUS-SOUND) · хлеб `pic.bread` (M-RUS-SEM) | NHR |  |
| `rus.a07.07` | LS01 pictorial | F01 → — | суп `pic.soup` | сок `pic.juice` (M-RUS-SOUND) · ка́ша `pic.porridge` (M-RUS-SEM) | NHR |  |
| `rus.a07.08` | LS01 pictorial | F01 → — | ка́ша `pic.porridge` | суп `pic.soup` (M-RUS-SEM) · ко́шка `pic.cat` (M-RUS-SOUND) | NHR |  |
| `rus.a07.09` | LS01 pictorial | F01 → — | яйцо́ `pic.egg` | хлеб `pic.bread` (M-RUS-SEM) · я́блоко `pic.apple` (M-RUS-SOUND) | NHR |  |
| `rus.a07.10` | LS01 pictorial | F01 → — | пече́нье `pic.cookie` | хлеб `pic.bread` (M-RUS-SEM) · яйцо́ `pic.egg` (M-RUS-SEM) | NHR |  |
| `rus.a07.11` | LS01 pictorial | F01 → — | я́блоко `pic.apple` | гру́ша `pic.pear` (M-RUS-SEM) · молоко́ `pic.milk` (M-RUS-SOUND) | NHR |  |
| `rus.a07.12` | LS01 pictorial | F01 → — | бана́н `pic.banana` | апельси́н `pic.orange` (M-RUS-SEM) · гру́ша `pic.pear` (M-RUS-SEM) | NHR |  |
| `rus.a07.13` | LS01 pictorial | F01 → — | гру́ша `pic.pear` | я́блоко `pic.apple` (M-RUS-SEM) · ка́ша `pic.porridge` (M-RUS-SOUND) | NHR |  |
| `rus.a07.14` | LS01 pictorial | F01 → — | апельси́н `pic.orange` | бана́н `pic.banana` (M-RUS-SEM) · арбу́з `pic.watermelon` (M-RUS-SOUND) | NHR |  |
| `rus.a07.15` | LS01 pictorial | F01 → — | клубни́ка `pic.strawberry` | виногра́д `pic.grapes` (M-RUS-SEM) · помидо́р `pic.tomato` (M-RUS-SEM) | NHR |  |
| `rus.a07.16` | LS01 pictorial | F01 → — | виногра́д `pic.grapes` | клубни́ка `pic.strawberry` (M-RUS-SEM) · огуре́ц `pic.cucumber` (M-RUS-SEM) | NHR |  |
| `rus.a07.17` | LS01 pictorial | F01 → — | арбу́з `pic.watermelon` | апельси́н `pic.orange` (M-RUS-SOUND) · огуре́ц `pic.cucumber` (M-RUS-SEM) | NHR |  |
| `rus.a07.18` | LS01 pictorial | F01 → — | морко́вь `pic.carrot` | огуре́ц `pic.cucumber` (M-RUS-SEM) · карто́шка `pic.potato` (M-RUS-SEM) | NHR |  |
| `rus.a07.19` | LS01 pictorial | F01 → — | огуре́ц `pic.cucumber` | помидо́р `pic.tomato` (M-RUS-SEM) · морко́вь `pic.carrot` (M-RUS-SEM) | NHR |  |
| `rus.a07.20` | LS01 pictorial | F01 → — | помидо́р `pic.tomato` | огуре́ц `pic.cucumber` (M-RUS-SEM) · я́блоко `pic.apple` (M-RUS-SEM) | NHR |  |
| `rus.a07.21` | LS01 pictorial | F01 → — | карто́шка `pic.potato` | морко́вь `pic.carrot` (M-RUS-SEM) · ко́шка `pic.cat` (M-RUS-SOUND) | NHR |  |
| `rus.a07.22` | LS11 picnic (drag) | F11 → — | сок `pic.juice` | суп `pic.soup` (M-RUS-SOUND) · вода́ `pic.water` (M-RUS-SEM) | NHR | three foods glow on a picnic cloth; the child drags one to the friend's plate |
| `rus.a07.23` | LS11 picnic (drag) | F11 → — | сыр `pic.cheese` | суп `pic.soup` (M-RUS-SOUND) · хлеб `pic.bread` (M-RUS-SEM) | NHR |  |
| `rus.a07.24` | LS11 picnic (drag) | F11 → — | я́блоко `pic.apple` | гру́ша `pic.pear` (M-RUS-SEM) · молоко́ `pic.milk` (M-RUS-SOUND) | NHR |  |
| `rus.a07.25` | LS11 picnic (drag) | F11 → — | бана́н `pic.banana` | апельси́н `pic.orange` (M-RUS-SEM) · гру́ша `pic.pear` (M-RUS-SEM) | NHR |  |
| `rus.a07.26` C | LS11 picnic (drag) | F11 → — | морко́вь `pic.carrot` | огуре́ц `pic.cucumber` (M-RUS-SEM) · карто́шка `pic.potato` (M-RUS-SEM) | NHR |  |
| `rus.a07.27` C | LS11 picnic (drag) | F11 → — | огуре́ц `pic.cucumber` | помидо́р `pic.tomato` (M-RUS-SEM) · морко́вь `pic.carrot` (M-RUS-SEM) | NHR |  |

**Hint ladder.** 1: the word again, slowly, twice (F02). 2: the food in use: milk pours into a cup, the friend bites the apple, soup steams in a bowl (a scene instead of a still picture). 3: show me: the right food glows and the word is said.

**Mastery and notes.** hear → picture (01–21) and the picnic (22–27). рис is met in A-20.

### RUS-A-08 Toys and play
*Strand VOC · prerequisites — · templates: LS01 pictorial, LS11 tidy-up drag, LS09 teach*

**Teach screens (LS09, new-learner route):** set 1: мяч, ку́кла, маши́на, ку́бики, ми́шка · set 2: ша́рик, пирами́дка, кни́га, каранда́ш, юла́. Each word: the picture, the word clip twice with F05 between (F03 if the child is shy), then on.

| Route | How the skill is served |
|---|---|
| New learner | Teach in two sets; items 01–15 |
| Heritage | No teach screens; items 11–15, then 01–10 |
| Reader | As heritage or new |

| Item | Template | Frame (Hebrew) → Russian clip | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|
| `rus.a08.01` | LS01 pictorial | F01 → — | мяч `pic.ball` | ша́рик `pic.balloon` (M-RUS-SEM) · ку́бики `pic.blocks` (M-RUS-SEM) | NHR |  |
| `rus.a08.02` | LS01 pictorial | F01 → — | ку́кла `pic.doll` | ку́бики `pic.blocks` (M-RUS-SOUND) · ми́шка `pic.teddy` (M-RUS-SEM) | NHR |  |
| `rus.a08.03` | LS01 pictorial | F01 → — | маши́на `pic.car` | мяч `pic.ball` (M-RUS-SEM) · юла́ `pic.top` (M-RUS-SEM) | NHR |  |
| `rus.a08.04` | LS01 pictorial | F01 → — | ку́бики `pic.blocks` | ку́кла `pic.doll` (M-RUS-SOUND) · пирами́дка `pic.stacker` (M-RUS-SEM) | NHR |  |
| `rus.a08.05` | LS01 pictorial | F01 → — | ми́шка `pic.teddy` | мышь `pic.mouse` (M-RUS-SOUND) · ку́кла `pic.doll` (M-RUS-SEM) | NHR |  |
| `rus.a08.06` | LS01 pictorial | F01 → — | ша́рик `pic.balloon` | мяч `pic.ball` (M-RUS-SEM) · ку́бики `pic.blocks` (M-RUS-SEM) | NHR |  |
| `rus.a08.07` | LS01 pictorial | F01 → — | пирами́дка `pic.stacker` | ку́бики `pic.blocks` (M-RUS-SEM) · юла́ `pic.top` (M-RUS-SEM) | NHR |  |
| `rus.a08.08` | LS01 pictorial | F01 → — | кни́га `pic.book` | каранда́ш `pic.pencil` (M-RUS-SEM) · ку́кла `pic.doll` (M-RUS-SEM) | NHR |  |
| `rus.a08.09` | LS01 pictorial | F01 → — | каранда́ш `pic.pencil` | кни́га `pic.book` (M-RUS-SEM) · маши́на `pic.car` (M-RUS-SEM) | NHR |  |
| `rus.a08.10` | LS01 pictorial | F01 → — | юла́ `pic.top` | мяч `pic.ball` (M-RUS-SEM) · пирами́дка `pic.stacker` (M-RUS-SEM) | NHR |  |
| `rus.a08.11` | LS11 tidy-up (drag) | F12 → — | мяч `pic.ball` | ша́рик `pic.balloon` (M-RUS-SEM) · ку́бики `pic.blocks` (M-RUS-SEM) | NHR | three toys glow on the floor; the child drags one into the toy box |
| `rus.a08.12` | LS11 tidy-up (drag) | F12 → — | ку́кла `pic.doll` | ку́бики `pic.blocks` (M-RUS-SOUND) · ми́шка `pic.teddy` (M-RUS-SEM) | NHR |  |
| `rus.a08.13` | LS11 tidy-up (drag) | F12 → — | ми́шка `pic.teddy` | мышь `pic.mouse` (M-RUS-SOUND) · ку́кла `pic.doll` (M-RUS-SEM) | NHR |  |
| `rus.a08.14` C | LS11 tidy-up (drag) | F12 → — | кни́га `pic.book` | каранда́ш `pic.pencil` (M-RUS-SEM) · ку́кла `pic.doll` (M-RUS-SEM) | NHR |  |
| `rus.a08.15` C | LS11 tidy-up (drag) | F12 → — | юла́ `pic.top` | мяч `pic.ball` (M-RUS-SEM) · пирами́дка `pic.stacker` (M-RUS-SEM) | NHR |  |

**Hint ladder.** 1: the word again, slowly (F02). 2: the toy plays: the ball bounces, the top spins, the car drives (motion instead of a still picture). 3: show me: the toy glows and the word is said.

**Mastery and notes.** ми́шка (a teddy) against мышь (a mouse) prepares A-20. кни́жка, the friendly form of кни́га, is heard in the A-17 chant.

### RUS-A-09 Clothes
*Strand VOC · prerequisites A-08 · templates: LS11 dress the friend, LS01 pictorial, LS09 teach*

**Teach screens (LS09, new-learner route):** set 1: ша́пка, ку́ртка, пла́тье, футбо́лка, штаны́ · set 2: носки́, боти́нки, сапоги́, шарф, ва́режки. Each word: the picture, the word clip twice with F05 between (F03 if the child is shy), then on.

| Route | How the skill is served |
|---|---|
| New learner | Teach in two sets; items 01–15 |
| Heritage | No teach screens; items 11–15, then 01–10 |
| Reader | As heritage or new |

| Item | Template | Frame (Hebrew) → Russian clip | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|
| `rus.a09.01` | LS01 pictorial | F01 → — | ша́пка `pic.hat` | шарф `pic.scarf` (M-RUS-SOUND) · ку́ртка `pic.jacket` (M-RUS-SEM) | NHR |  |
| `rus.a09.02` | LS01 pictorial | F01 → — | ку́ртка `pic.jacket` | ку́кла `pic.doll` (M-RUS-SOUND) · пла́тье `pic.dress` (M-RUS-SEM) | NHR |  |
| `rus.a09.03` | LS01 pictorial | F01 → — | пла́тье `pic.dress` | футбо́лка `pic.tshirt` (M-RUS-SEM) · штаны́ `pic.trousers` (M-RUS-SEM) | NHR |  |
| `rus.a09.04` | LS01 pictorial | F01 → — | футбо́лка `pic.tshirt` | ку́ртка `pic.jacket` (M-RUS-SEM) · пла́тье `pic.dress` (M-RUS-SEM) | NHR |  |
| `rus.a09.05` | LS01 pictorial | F01 → — | штаны́ `pic.trousers` | носки́ `pic.socks` (M-RUS-SEM) · футбо́лка `pic.tshirt` (M-RUS-SEM) | NHR |  |
| `rus.a09.06` | LS01 pictorial | F01 → — | носки́ `pic.socks` | боти́нки `pic.shoes` (M-RUS-SEM) · нос `hot.nose` (M-RUS-SOUND) | NHR |  |
| `rus.a09.07` | LS01 pictorial | F01 → — | боти́нки `pic.shoes` | сапоги́ `pic.boots` (M-RUS-SEM) · носки́ `pic.socks` (M-RUS-SEM) | NHR |  |
| `rus.a09.08` | LS01 pictorial | F01 → — | сапоги́ `pic.boots` | боти́нки `pic.shoes` (M-RUS-SEM) · ша́пка `pic.hat` (M-RUS-SEM) | NHR |  |
| `rus.a09.09` | LS01 pictorial | F01 → — | шарф `pic.scarf` | ша́пка `pic.hat` (M-RUS-SOUND) · ва́режки `pic.mittens` (M-RUS-SEM) | NHR |  |
| `rus.a09.10` | LS01 pictorial | F01 → — | ва́режки `pic.mittens` | шарф `pic.scarf` (M-RUS-SEM) · носки́ `pic.socks` (M-RUS-SEM) | NHR |  |
| `rus.a09.11` | LS11 dress the friend (drag) | F13 → — | ша́пка `pic.hat` | шарф `pic.scarf` (M-RUS-SOUND) · ку́ртка `pic.jacket` (M-RUS-SEM) | NHR | three clothes glow beside the friend; the child drags one onto it |
| `rus.a09.12` | LS11 dress the friend (drag) | F13 → — | пла́тье `pic.dress` | футбо́лка `pic.tshirt` (M-RUS-SEM) · штаны́ `pic.trousers` (M-RUS-SEM) | NHR |  |
| `rus.a09.13` | LS11 dress the friend (drag) | F13 → — | носки́ `pic.socks` | боти́нки `pic.shoes` (M-RUS-SEM) · нос `hot.nose` (M-RUS-SOUND) | NHR |  |
| `rus.a09.14` C | LS11 dress the friend (drag) | F13 → — | шарф `pic.scarf` | ша́пка `pic.hat` (M-RUS-SOUND) · ва́режки `pic.mittens` (M-RUS-SEM) | NHR |  |
| `rus.a09.15` C | LS11 dress the friend (drag) | F13 → — | ва́режки `pic.mittens` | шарф `pic.scarf` (M-RUS-SEM) · носки́ `pic.socks` (M-RUS-SEM) | NHR |  |

**Hint ladder.** 1: the word again, slowly (F02). 2: the clothing is put on the friend for a moment (the hat on the head, the socks on the feet), then taken off again. 3: show me: the clothing glows and the word is said.

**Mastery and notes.** Any clothes on any friend: no item says who may wear what.

### RUS-A-10 Numbers 1–5
*Strand NUM · prerequisites — · templates: T02 count and tap (Russian number clips; the taps are practice) with its scored "how many?" step (3 number words heard on a tap), LS01 number → set*

**Teach screens (LS09, new-learner route):** set 1: оди́н, два, три, четы́ре, пять. Each word: the picture, the word clip twice with F05 between (F03 if the child is shy), then on.

| Route | How the skill is served |
|---|---|
| New learner | Teach by counting along (F15) with each set; items 01–10 |
| Heritage | Items 06–10, then 01–05 |
| Reader | As heritage or new |

| Item | Template | Frame (Hebrew) → Russian clip | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|
| `rus.a10.01` | T02 count, then "how many?" | F15 → — (count 2, practice); F40 → `ch-skolko` | два `n-2` | оди́н `n-1` (M-RUS-NUMWORD) · три `n-3` (M-RUS-NUMWORD) | NHR | the counting: one number clip per tap (practice, no tag; the count is not said again before the question); then F40 → `ch-skolko` and 3 sound buttons with no numeral and no picture (LS01 c), since a numeral could be answered without the Russian word |
| `rus.a10.02` | T02 count, then "how many?" | F15 → — (count 3, practice); F40 → `ch-skolko` | три `n-3` | два `n-2` (M-RUS-NUMWORD) · четы́ре `n-4` (M-RUS-NUMWORD) | NHR |  |
| `rus.a10.03` | T02 count, then "how many?" | F15 → — (count 4, practice); F40 → `ch-skolko` | четы́ре `n-4` | три `n-3` (M-RUS-NUMWORD) · пять `n-5` (M-RUS-NUMWORD) | NHR |  |
| `rus.a10.04` | T02 count, then "how many?" | F15 → — (count 5, practice); F40 → `ch-skolko` | пять `n-5` | четы́ре `n-4` (M-RUS-NUMWORD) · три `n-3` (M-RUS-NUMWORD) | NHR |  |
| `rus.a10.05` C | T02 count, then "how many?" | F15 → — (count 3, practice); F40 → `ch-skolko` | три `n-3` | четы́ре `n-4` (M-RUS-NUMWORD) · два `n-2` (M-RUS-NUMWORD) | NHR | new objects in a row (not a dice pattern); the buttons in another order |
| `rus.a10.06` | LS01 number → set | F16 → `n-1` | a set of 1 (оди́н) | a set of 2 (два) (M-RUS-NUMWORD) · a set of 3 (три) (M-RUS-NUMWORD) | NHR | sets of the same objects (apples, balls, ducks), in a dice or ten-frame pattern |
| `rus.a10.07` | LS01 number → set | F16 → `n-2` | a set of 2 (два) | a set of 1 (оди́н) (M-RUS-NUMWORD) · a set of 3 (три) (M-RUS-NUMWORD) | NHR |  |
| `rus.a10.08` | LS01 number → set | F16 → `n-3` | a set of 3 (три) | a set of 2 (два) (M-RUS-NUMWORD) · a set of 4 (четы́ре) (M-RUS-NUMWORD) | NHR |  |
| `rus.a10.09` | LS01 number → set | F16 → `n-4` | a set of 4 (четы́ре) | a set of 3 (три) (M-RUS-NUMWORD) · a set of 5 (пять) (M-RUS-NUMWORD) | NHR |  |
| `rus.a10.10` C | LS01 number → set | F16 → `n-5` | a set of 5 (пять) | a set of 4 (четы́ре) (M-RUS-NUMWORD) · a set of 3 (три) (M-RUS-NUMWORD) | NHR |  |

**Hint ladder.** 1: the number (after counting: the three number words) again; the friend points at the first object (F02). 2: fingers: the friend's hand shows the number, one finger at a time, while the voice counts (a new representation). 3: show me: number → set: the right set lights and the voice counts it up to the number; "how many?": the voice counts the objects again and the right button glows and plays.

**Mastery and notes.** Two representations (frame §4.4 R1): count, then choose (concrete), and number → set (pictorial). The counting taps are practice and never scored: a skipped or double-tapped object is a counting error (maths), and the app says the number words while the child taps, so the friend simply counts again with the child. The scored step is "how many?" (frame §2.2). Amounts: 1 to 3 in any arrangement, 4 and 5 as dice or finger patterns, 6 to 10 as ten-frames. A wrong number word may mean the amount itself is still new, not only the Russian word (the NUMWORD parent text says both). Counting is said without a noun (оди́н, два, три), so number–noun agreement (C-28) is not met here.

### RUS-A-11 Numbers 6–10
*Strand NUM · prerequisites A-10 · templates: as A-10*

**Teach screens (LS09, new-learner route):** set 1: шесть, семь, во́семь, де́вять, де́сять. Each word: the picture, the word clip twice with F05 between (F03 if the child is shy), then on.

| Route | How the skill is served |
|---|---|
| New learner | Teach by counting along; items 01–10 |
| Heritage | Items 06–10, then 01–05 |
| Reader | As heritage or new |

| Item | Template | Frame (Hebrew) → Russian clip | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|
| `rus.a11.01` | T02 count, then "how many?" | F15 → — (count 6, practice); F40 → `ch-skolko` | шесть `n-6` | семь `n-7` (M-RUS-SOUND) · пять `n-5` (M-RUS-NUMWORD) | NHR | the objects in a ten-frame; otherwise as A-10 01 |
| `rus.a11.02` | T02 count, then "how many?" | F15 → — (count 7, practice); F40 → `ch-skolko` | семь `n-7` | во́семь `n-8` (M-RUS-SOUND) · шесть `n-6` (M-RUS-NUMWORD) | NHR |  |
| `rus.a11.03` | T02 count, then "how many?" | F15 → — (count 8, practice); F40 → `ch-skolko` | во́семь `n-8` | семь `n-7` (M-RUS-SOUND) · де́вять `n-9` (M-RUS-NUMWORD) | NHR |  |
| `rus.a11.04` | T02 count, then "how many?" | F15 → — (count 9, practice); F40 → `ch-skolko` | де́вять `n-9` | де́сять `n-10` (M-RUS-SOUND) · во́семь `n-8` (M-RUS-NUMWORD) | NHR |  |
| `rus.a11.05` C | T02 count, then "how many?" | F15 → — (count 10, practice); F40 → `ch-skolko` | де́сять `n-10` | де́вять `n-9` (M-RUS-SOUND) · во́семь `n-8` (M-RUS-NUMWORD) | NHR |  |
| `rus.a11.06` | LS01 number → set | F16 → `n-6` | a set of 6 (шесть) | a set of 7 (семь) (M-RUS-SOUND) · a set of 5 (пять) (M-RUS-NUMWORD) | NHR | sets of the same objects (apples, balls, ducks), in a dice or ten-frame pattern |
| `rus.a11.07` | LS01 number → set | F16 → `n-7` | a set of 7 (семь) | a set of 8 (во́семь) (M-RUS-SOUND) · a set of 6 (шесть) (M-RUS-NUMWORD) | NHR |  |
| `rus.a11.08` | LS01 number → set | F16 → `n-8` | a set of 8 (во́семь) | a set of 7 (семь) (M-RUS-SOUND) · a set of 9 (де́вять) (M-RUS-NUMWORD) | NHR |  |
| `rus.a11.09` | LS01 number → set | F16 → `n-9` | a set of 9 (де́вять) | a set of 10 (де́сять) (M-RUS-SOUND) · a set of 8 (во́семь) (M-RUS-NUMWORD) | NHR |  |
| `rus.a11.10` C | LS01 number → set | F16 → `n-10` | a set of 10 (де́сять) | a set of 9 (де́вять) (M-RUS-SOUND) · a set of 8 (во́семь) (M-RUS-NUMWORD) | NHR |  |

**Hint ladder.** 1: as A-10 (F02). 2: as A-10 (two hands). 3: as A-10.

**Mastery and notes.** As A-10 (the counting is practice; "how many?" is scored). The sound-alikes are the point: шесть / семь, семь / во́семь, де́вять / де́сять (M-RUS-SOUND).

### RUS-A-12 ● Что э́то? / Кто э́то? — Э́то …
*Strand GRM · prerequisites A-05, A-08 · templates: LS01 audio options, LS01 windows, LS01 yes / no (2 choices)*

| Route | How the skill is served |
|---|---|
| New learner | All items; кто / что first with animals and people the child knows from A-02 and A-05 |
| Heritage | All items; кто / что weighted up (Hebrew מה זה? is said of animals too, so кто for an animal is a transfer point) |
| Reader | As heritage or new |

| Item | Template | Frame (Hebrew) → Russian clip | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|
| `rus.a12.01` | LS01 audio options | F17 → `ch-chto-eto` | «Э́то мяч.» `ch-eto-mjach` | «Э́то ку́кла.» `ch-eto-kukla` (M-RUS-SEM) · «Э́то кот.» `sen-2` (M-RUS-SEM) | NHR | picture: a ball; three spoken answers |
| `rus.a12.02` | LS01 audio options | F17 → `ch-kto-eto` | «Э́то ко́шка.» `ch-eto-koshka` | «Э́то соба́ка.» `ch-eto-sobaka` (M-RUS-SEM) · «Э́то мяч.» `ch-eto-mjach` (M-RUS-SEM) | NHR | picture: a cat |
| `rus.a12.03` | LS01 audio options | F17 → `ch-chto-eto` | «Э́то я́блоко.» `ch-eto-jabloko` | «Э́то бана́н.» `ch-eto-banan` (M-RUS-SEM) · «Э́то молоко́.» `ch-eto-moloko` (M-RUS-SOUND) | NHR | picture: an apple |
| `rus.a12.04` C | LS01 audio options | F17 → `ch-kto-eto` | «Э́то ма́ма.» `ch-eto-mama` | «Э́то па́па.» `ch-eto-papa` (M-RUS-SOUND) · «Э́то ба́бушка.» `ch-eto-babushka` (M-RUS-SEM) | NHR | picture: the mother |
| `rus.a12.05` | LS01 windows | F17 → `ch-kto-eto` | соба́ка `pic.dog` | мяч `pic.ball` (M-RUS-KTO) · маши́на `pic.car` (M-RUS-KTO) | NHR | three windows open; the answer is the living one; the recast is ch-eto-sobaka |
| `rus.a12.06` | LS01 windows | F17 → `ch-kto-eto` | ба́бушка `pic.fam.grandmother` | хлеб `pic.bread` (M-RUS-KTO) · ша́пка `pic.hat` (M-RUS-KTO) | NHR | recast ch-eto-babushka |
| `rus.a12.07` C | LS01 windows | F17 → `ch-chto-eto` | маши́на `pic.car` | ко́шка `pic.cat` (M-RUS-KTO) · ма́льчик `pic.boy` (M-RUS-KTO) | NHR | the answer is the thing; recast ch-eto-mashina |
| `rus.a12.08` C | LS01 windows | F17 → `ch-chto-eto` | я́блоко `pic.apple` | ёж `pic.hedgehog` (M-RUS-KTO) · де́вочка `pic.girl` (M-RUS-KTO) | NHR | recast ch-eto-jabloko |
| `rus.a12.09` | LS01 yes / no | F18 → `ch-eto-kot-q` | нет `pic.no` | да `pic.yes` (M-RUS-YESNO) | NHR | picture: a dog; the recast is w-net then ch-eto-sobaka |
| `rus.a12.10` | LS01 yes / no | F18 → `ch-eto-mjach-q` | да `pic.yes` | нет `pic.no` (M-RUS-YESNO) | NHR | picture: a ball; recast w-da then ch-eto-mjach |
| `rus.a12.11` | LS01 yes / no | F18 → `ch-eto-ryba-q` | нет `pic.no` | да `pic.yes` (M-RUS-YESNO) | NHR | picture: a bird |
| `rus.a12.12` | LS01 yes / no | F18 → `ch-eto-kukla-q` | да `pic.yes` | нет `pic.no` (M-RUS-YESNO) | NHR | picture: a doll; recast w-da then ch-eto-kukla |

**Hint ladder.** 1: the question again, slowly (F02). 2: alive or not (a new representation): the living things in the windows breathe and blink, the things stay still, while the question is asked again; for yes / no, the friend points at the picture and says its real name. 3: show me: the right answer glows and is played; a tap goes on.

**Mastery and notes.** Core skill. Yes / no items (09–12) are 2-choice: at most half of the evidence (curriculum §10.2). Toys shaped like animals (ми́шка) are never used for кто / что.

### RUS-A-13 Где …? — Вот …, да / нет
*Strand GRM · prerequisites A-12 · templates: LS11 scene search, LS01 yes / no*

| Route | How the skill is served |
|---|---|
| New learner | All items |
| Heritage | All items; 07–10 first |
| Reader | As heritage or new |

| Item | Template | Frame (Hebrew) → Russian clip | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|
| `rus.a13.01` | LS11 scene search | F19 → `ch-gde-mjach` | мяч `pic.ball` | ша́рик `pic.balloon` (M-RUS-SEM) · ку́кла `pic.doll` (M-RUS-SEM) | NHR | a room scene; three things glow; after the tap the voice says ch-vot-mjach |
| `rus.a13.02` | LS11 scene search | F19 → `ch-gde-koshka` | ко́шка `pic.cat` | соба́ка `pic.dog` (M-RUS-SEM) · ка́ша `pic.porridge` (M-RUS-SOUND) | NHR | recast ch-vot-koshka |
| `rus.a13.03` | LS11 scene search | F19 → `ch-gde-mysh` | мышь `pic.mouse` | ми́шка `pic.teddy` (M-RUS-SOUND) · ко́шка `pic.cat` (M-RUS-SEM) | NHR | recast ch-vot-mysh |
| `rus.a13.04` | LS11 scene search | F19 → `ch-gde-shapka` | ша́пка `pic.hat` | шарф `pic.scarf` (M-RUS-SOUND) · ку́ртка `pic.jacket` (M-RUS-SEM) | NHR | recast ch-vot-shapka |
| `rus.a13.05` C | LS11 scene search | F19 → `ch-gde-jabloko` | я́блоко `pic.apple` | молоко́ `pic.milk` (M-RUS-SOUND) · гру́ша `pic.pear` (M-RUS-SEM) | NHR | recast ch-vot-jabloko |
| `rus.a13.06` C | LS11 scene search | F19 → `ch-gde-mama` | ма́ма `pic.fam.mother` | па́па `pic.fam.father` (M-RUS-SOUND) · ба́бушка `pic.fam.grandmother` (M-RUS-SEM) | NHR | the original family in a garden; recast ch-vot-mama |
| `rus.a13.07` | LS01 yes / no | F18 → `ch-vot-mjach` | нет `pic.no` | да `pic.yes` (M-RUS-YESNO) | NHR | the friend holds up a doll and says Вот мяч! |
| `rus.a13.08` | LS01 yes / no | F18 → `ch-vot-koshka` | да `pic.yes` | нет `pic.no` (M-RUS-YESNO) | NHR | the friend points at the cat |
| `rus.a13.09` | LS01 yes / no | F18 → `ch-vot-shapka` | нет `pic.no` | да `pic.yes` (M-RUS-YESNO) | NHR | the friend holds up a scarf |
| `rus.a13.10` | LS01 yes / no | F18 → `ch-vot-mama` | да `pic.yes` | нет `pic.no` (M-RUS-YESNO) | NHR | the friend points at the mother |

**Hint ladder.** 1: the question again, slowly (F02). 2: the friend looks around the room and its eyes stop near the right place (a new representation: gaze in the scene). 3: show me: the thing glows and the voice says Вот …!.

**Mastery and notes.** Scene search (01–06) and yes / no (07–10, 2-choice, at most half of the evidence).

### RUS-A-14 Polite requests
*Strand GRM · prerequisites A-01, A-07 · templates: LS11 give (drag), LS10 bubbles with the say step*

| Route | How the skill is served |
|---|---|
| New learner | All items |
| Heritage | All items; 10–11 with the say step picture first |
| Reader | As heritage or new |

| Item | Template | Frame (Hebrew) → Russian clip | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|
| `rus.a14.01` | LS11 give (drag) | F20 → `ch-daj-mjach` | мяч `pic.ball` | ша́рик `pic.balloon` (M-RUS-SEM) · ку́кла `pic.doll` (M-RUS-SEM) | NHR | the friend asks; the child drags the thing to its hands; the friend says w-spasibo |
| `rus.a14.02` | LS11 give (drag) | F20 → `ch-daj-sok` | сок `pic.juice` | суп `pic.soup` (M-RUS-SOUND) · молоко́ `pic.milk` (M-RUS-SEM) | NHR |  |
| `rus.a14.03` | LS11 give (drag) | F20 → `ch-daj-hleb` | хлеб `pic.bread` | сыр `pic.cheese` (M-RUS-SEM) · я́блоко `pic.apple` (M-RUS-SEM) | NHR |  |
| `rus.a14.04` | LS11 give (drag) | F20 → `ch-daj-jabloko` | я́блоко `pic.apple` | бана́н `pic.banana` (M-RUS-SEM) · молоко́ `pic.milk` (M-RUS-SOUND) | NHR |  |
| `rus.a14.05` | LS11 give (drag) | F20 → `ch-daj-banan` | бана́н `pic.banana` | апельси́н `pic.orange` (M-RUS-SEM) · я́блоко `pic.apple` (M-RUS-SEM) | NHR |  |
| `rus.a14.06` | LS11 give (drag) | F20 → `ch-daj-karandash` | каранда́ш `pic.pencil` | кни́га `pic.book` (M-RUS-SEM) · мяч `pic.ball` (M-RUS-SEM) | NHR |  |
| `rus.a14.07` | LS11 give (drag) | F20 → `ch-hochu-syr` | сыр `pic.cheese` | сок `pic.juice` (M-RUS-SOUND) · хлеб `pic.bread` (M-RUS-SEM) | NHR |  |
| `rus.a14.08` | LS11 give (drag) | F20 → `ch-hochu-apelsin` | апельси́н `pic.orange` | арбу́з `pic.watermelon` (M-RUS-SOUND) · бана́н `pic.banana` (M-RUS-SEM) | NHR |  |
| `rus.a14.09` C | LS11 give (drag) | F20 → `ch-hochu-moloko` | молоко́ `pic.milk` | вода́ `pic.water` (M-RUS-SEM) · я́блоко `pic.apple` (M-RUS-SOUND) | NHR |  |
| `rus.a14.10` | LS10 bubbles | F07 → `w-na` | спаси́бо `pic.rus.gift` | пока́ `pic.rus.leave` (M-RUS-SEM) · приве́т `pic.rus.arrive` (M-RUS-SEM) | NHR | the friend hands the child an apple: На!; after the answer the friend says w-pozhalujsta; then the say step |
| `rus.a14.11` C | LS10 bubbles | F07 → — | «Дай, пожа́луйста, сок.» `ch-daj-sok` | «Дай, пожа́луйста, суп.» `ch-daj-sup` (M-RUS-SOUND) · спаси́бо `pic.rus.gift` (M-RUS-SEM) | NHR | a thought bubble shows juice; the child picks what to say; the say step marks пожа́луйста and сок as key words |

**Hint ladder.** 1: the request again, slowly (F02). 2: the friend reaches toward the thing and mimes it (eats, drinks, draws) while asking again (a new representation: action). 3: show me: the thing glows and slides to the friend; a tap goes on.

**Mastery and notes.** Only nouns whose accusative looks like the nominative are asked for (masculine things and neuter words: мяч, сок, я́блоко), so the case change waits for B-07.

### RUS-A-15 ● Names a picture with one word
*Strand SPK · prerequisites A-12 · templates: LS09 say-it (per-word feedback when voice is on, syllabus §8), then the picture tap (LS01, 3 pictures, the A-05 to A-09 distractor of the word)*

| Route | How the skill is served |
|---|---|
| New learner | Echo first: picture, the model, F05 the pause, the model again; from the third encounter of a word, picture first (F06), then the model |
| Heritage | Picture first from the start; then the model; extended to every word of A-02 to A-09 with the same variant and foil rule |
| Reader | As heritage or new, by strand 1 |

| Item | Template | Frame (Hebrew) → Russian clip | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|
| `rus.a15.01` | LS09 say-it | F06 → — | ма́ма `pic.fam.mother` | — | NHR | variants: ма́мочка; foils: па́па, ба́бушка |
| `rus.a15.02` | LS09 say-it | F06 → — | па́па `pic.fam.father` | — | NHR | variants: па́почка; foils: ма́ма, де́душка |
| `rus.a15.03` | LS09 say-it | F06 → — | ба́бушка `pic.fam.grandmother` | — | NHR | variants: ба́ба; foils: де́душка, ма́ма |
| `rus.a15.04` | LS09 say-it | F06 → — | кот `pic.tomcat` | — | NHR | variants: ко́тик; foils: кит, рот |
| `rus.a15.05` | LS09 say-it | F06 → — | ко́шка `pic.cat` | — | NHR | variants: ко́шечка, ки́ска; foils: ка́ша, ку́кла |
| `rus.a15.06` | LS09 say-it | F06 → — | соба́ка `pic.dog` | — | NHR | variants: соба́чка; foils: ко́шка |
| `rus.a15.07` C | LS09 say-it | F06 → — | мышь `pic.mouse` | — | NHR | variants: мы́шка; foils: ми́шка |
| `rus.a15.08` | LS09 say-it | F06 → — | ры́ба `pic.fish` | — | NHR | variants: ры́бка; foils: ру́ки |
| `rus.a15.09` | LS09 say-it | F06 → — | мяч `pic.ball` | — | NHR | variants: мя́чик; foils: мышь, меч |
| `rus.a15.10` | LS09 say-it | F06 → — | ку́кла `pic.doll` | — | NHR | variants: ку́колка; foils: ку́бики, ку́ртка |
| `rus.a15.11` | LS09 say-it | F06 → — | маши́на `pic.car` | — | NHR | variants: маши́нка; foils: мали́на |
| `rus.a15.12` C | LS09 say-it | F06 → — | ми́шка `pic.teddy` | — | NHR | variants: медве́дь; foils: мы́шка, мышь |
| `rus.a15.13` | LS09 say-it | F06 → — | нос `hot.nose` | — | NHR | variants: но́сик; foils: рот, сок |
| `rus.a15.14` | LS09 say-it | F06 → — | рот `hot.mouth` | — | NHR | variants: ро́тик; foils: кот, нос |
| `rus.a15.15` | LS09 say-it | F06 → — | ру́ки `hot.arms` | — | NHR | variants: рука́, ру́чки; foils: но́ги |
| `rus.a15.16` | LS09 say-it | F06 → — | сок `pic.juice` | — | NHR | variants: со́чок; foils: суп, сыр |
| `rus.a15.17` | LS09 say-it | F06 → — | хлеб `pic.bread` | — | NHR | variants: хле́бушек; foils: сыр |
| `rus.a15.18` | LS09 say-it | F06 → — | молоко́ `pic.milk` | — | NHR | variants: —; foils: я́блоко |
| `rus.a15.19` | LS09 say-it | F06 → — | я́блоко `pic.apple` | — | NHR | variants: я́блочко; foils: молоко́ |
| `rus.a15.20` | LS09 say-it | F06 → — | бана́н `pic.banana` | — | NHR | variants: —; foils: бара́н |
| `rus.a15.21` C | LS09 say-it | F06 → — | ша́пка `pic.hat` | — | NHR | variants: ша́почка; foils: шарф, па́пка |
| `rus.a15.22` | LS09 say-it | F06 → — | a set of 1 (оди́н) | — | NHR | variants: —; foils: два |
| `rus.a15.23` | LS09 say-it | F06 → — | a set of 3 (три) | — | NHR | variants: —; foils: два |
| `rus.a15.24` | LS09 say-it | F06 → — | a set of 5 (пять) | — | NHR | variants: —; foils: шесть |

**Hint ladder.** 1: the word's first syllable is said, then a pause ("ма…") (F02). 2: the whole word modelled (F03 בּוֹאוּ נֹאמַר יַחַד.) with a choral pause: the voice and the child together. 3: show me: the word is said twice with its picture; "I said it" or a tap goes on.

**Mastery and notes.** Core skill. Speech evidence (confident only) is capped at 50%; the rest is the picture tap and the parent's weekly confirmation (syllabus §8). With the microphone off: "I said it" (practice) and the confirmation. Variants are accepted as the target; foils are the item's other options and the minimal-pair partner, for the matcher only (never voiced, never shown). The checks (07, 12, 21: words with a minimal-pair foil) are served picture first (F06) with no model before them, on a later visit; the picture tap that follows has 3 pictures, so a check is never a single 2-choice item.

### RUS-A-16 A 3-picture story
*Strand LIS · prerequisites A-04, A-12 · templates: LS08 `listen` and `dialogic`, LS01 after the story*

| Route | How the skill is served |
|---|---|
| New learner | Listen first (01, 04, 07), then dialogic on a later visit |
| Heritage | Dialogic on the first reading (skip 01, 04, 07); the echo of the repeated line (st1-2) with LS09 if voice is on (unscored) |
| Reader | As heritage |

| Item | Template | Frame (Hebrew) → Russian clip | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|
| `rus.a16.01` | LS08 listen | F21 → `st1-t` + `st1-1` + `st1-2` + `st1-3` | (listen) | — | N | story 1, three pages; a tap on a picture plays its word (соба́ка, мяч) |
| `rus.a16.02` | LS08 dialogic | F22 → `st1-1` + `st1-2` | `pic.st1.p3` | `pic.st1.sleep` (M-RUS-SEQ) · `pic.st1.cat` (M-RUS-SEQ) | NHR | after page 2: the dog with the ball ✓; the dog asleep in its bed (not in the story); a cat with the ball (the wrong character) |
| `rus.a16.03` | LS01 after the story | F23 → — | соба́ка `pic.dog` | ко́шка `pic.cat` (M-RUS-SEQ) · коро́ва `pic.cow` (M-RUS-SEQ) | NHR | who was in the story |
| `rus.a16.04` | LS08 listen | F21 → `st2-t` + `st2-1` + `st2-2` + `st2-3` | (listen) | — | N | story 2 |
| `rus.a16.05` | LS08 dialogic | F22 → `st2-1` + `st2-2` | `pic.st2.p3` | `pic.st2.sleep` (M-RUS-SEQ) · `pic.st2.bear` (M-RUS-SEQ) | NHR | after page 2: the hedgehog eating the apple ✓; the hedgehog asleep; a bear eating the apple |
| `rus.a16.06` C | LS01 after the story | F24 → — | я́блоко `pic.apple` | бана́н `pic.banana` (M-RUS-SEQ) · мяч `pic.ball` (M-RUS-SEQ) | NHR | what the hedgehog found |
| `rus.a16.07` | LS08 listen | F21 → `st3-1` + `st3-2` + `st3-3` | (listen) | — | N | story 3 (title w-shapka) |
| `rus.a16.08` | LS08 dialogic | F22 → `st3-1` + `st3-2` | `pic.st3.p3` | `pic.st3.beach` (M-RUS-SEQ) · `pic.st3.boy` (M-RUS-SEQ) | NHR | after page 2: the girl finds the hat ✓; the girl on a hot beach; a boy with a ball |
| `rus.a16.09` C | LS01 after the story | F25 → — | ша́пка `pic.hat` | шарф `pic.scarf` (M-RUS-SEM) · мяч `pic.ball` (M-RUS-SEQ) | NHR | what the girl looked for |

**Hint ladder.** 1: the last page is read again (F02). 2: the pages so far are shown in a row and replayed one by one (a new representation: the sequence laid out). 3: show me: page 3 is turned and read; a tap goes on.

**Mastery and notes.** The stories are original (D3). Pages: story 1 a dog and a ball; story 2 a hedgehog finds an apple; story 3 a cold girl finds her hat. Reading is not involved; the questions are scored.

### RUS-A-17 Rhyme
*Strand PHO · prerequisites A-01 · templates: LS12 sing along, rhyme mode (spoken chants: no melody, so no tune to approve)*

| Route | How the skill is served |
|---|---|
| New learner | Each chant heard whole on one visit, its gap item on the next |
| Heritage | Chant and gap item in the same visit |
| Reader | As heritage |

| Item | Template | Frame (Hebrew) → Russian clip | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|
| `rus.a17.01` | LS12 rhyme gap | F27 → `rh1-gap` | нос `hot.nose` | но́ги `hot.legs` (M-RUS-RHYME-ONSET) · рот `hot.mouth` (M-RUS-SEM) | NHR | the chant rh1 is heard whole first (F26); after the answer the whole chant again |
| `rus.a17.02` | LS12 rhyme gap | F27 → `rh2-gap` | рот `hot.mouth` | ру́ки `hot.arms` (M-RUS-RHYME-ONSET) · нос `hot.nose` (M-RUS-SEM) | NHR | chant rh2 |
| `rus.a17.03` | LS12 rhyme gap | F27 → `rh3-gap` | кит `pic.whale` | кот `pic.tomcat` (M-RUS-RHYME-ONSET) · ры́ба `pic.fish` (M-RUS-SEM) | NHR | chant rh3 |
| `rus.a17.04` C | LS12 rhyme gap | F27 → `rh4-gap` | носо́к `pic.sock` | нос `hot.nose` (M-RUS-RHYME-ONSET) · ша́пка `pic.hat` (M-RUS-SEM) | NHR | chant rh4 |
| `rus.a17.05` C | LS12 rhyme gap | F27 → `rh5-gap` | кни́жка `pic.book` | ку́кла `pic.doll` (M-RUS-RHYME-ONSET) · мяч `pic.ball` (M-RUS-SEM) | NHR | chant rh5 |

**Hint ladder.** 1: the chant again, slower, with a beat on the line ends (F02). 2: word pairs (a new representation: two words side by side): the rhyme word of line 1 is said before each option (пёс … но́ги? пёс … нос? пёс … рот?), using the clips w-pjos, w-kot, w-spit, w-sok, w-mishka. 3: show me: the whole chant with the right picture lit.

**Mastery and notes.** The five chants are original. The words пёс, спит, кит, носо́к and кни́жка are met here with their pictures.

### RUS-A-18 Syllables
*Strand PHO · prerequisites A-17 · templates: LS03 drum mode, LS01 "the picture with three claps"*

| Route | How the skill is served |
|---|---|
| New learner | Drum items 01–13 first, the claps items 14–19 on a later visit |
| Heritage | All items mixed |
| Reader | As heritage |

| Item | Template | Frame (Hebrew) → Russian clip | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|
| `rus.a18.01` | LS03 drum | F28 → — | 1 tap | 2 taps (M-RUS-SYLL) · 3 taps (M-RUS-SYLL) | NHR | кот: the picture, the word, then the syllable clip; the child taps the drum |
| `rus.a18.02` | LS03 drum | F28 → — | 1 tap | 2 taps (M-RUS-SYLL) · 3 taps (M-RUS-SYLL) | NHR | мяч |
| `rus.a18.03` | LS03 drum | F28 → — | 1 tap | 2 taps (M-RUS-SYLL) · 3 taps (M-RUS-SYLL) | NHR | сыр |
| `rus.a18.04` | LS03 drum | F28 → `sy-mama` | 2 taps | 1 tap (M-RUS-SYLL) · 3 taps (M-RUS-SYLL) | NHR | ма́ма |
| `rus.a18.05` | LS03 drum | F28 → `sy-ryba` | 2 taps | 1 tap (M-RUS-SYLL) · 3 taps (M-RUS-SYLL) | NHR | ры́ба |
| `rus.a18.06` | LS03 drum | F28 → `sy-kukla` | 2 taps | 1 tap (M-RUS-SYLL) · 3 taps (M-RUS-SYLL) | NHR | ку́кла |
| `rus.a18.07` | LS03 drum | F28 → `sy-utka` | 2 taps | 1 tap (M-RUS-SYLL) · 3 taps (M-RUS-SYLL) | NHR | у́тка |
| `rus.a18.08` | LS03 drum | F28 → `sy-koshka` | 2 taps | 1 tap (M-RUS-SYLL) · 3 taps (M-RUS-SYLL) | NHR | ко́шка |
| `rus.a18.09` | LS03 drum | F28 → `sy-sobaka` | 3 taps | 2 taps (M-RUS-SYLL) · 4 taps (M-RUS-SYLL) | NHR | соба́ка |
| `rus.a18.10` | LS03 drum | F28 → `sy-mashina` | 3 taps | 2 taps (M-RUS-SYLL) · 4 taps (M-RUS-SYLL) | NHR | маши́на |
| `rus.a18.11` | LS03 drum | F28 → `sy-moloko` | 3 taps | 2 taps (M-RUS-SYLL) · 4 taps (M-RUS-SYLL) | NHR | молоко́ |
| `rus.a18.12` | LS03 drum | F28 → `sy-babushka` | 3 taps | 2 taps (M-RUS-SYLL) · 4 taps (M-RUS-SYLL) | NHR | ба́бушка |
| `rus.a18.13` | LS03 drum | F28 → `sy-karandash` | 3 taps | 2 taps (M-RUS-SYLL) · 4 taps (M-RUS-SYLL) | NHR | каранда́ш |
| `rus.a18.14` | LS01 pictorial | F29 → — | соба́ка `pic.dog` | ко́шка `pic.cat` (M-RUS-SYLL) · сыр `pic.cheese` (M-RUS-SYLL) | NHR | each picture plays its word on tap |
| `rus.a18.15` | LS01 pictorial | F29 → — | маши́на `pic.car` | ку́кла `pic.doll` (M-RUS-SYLL) · мяч `pic.ball` (M-RUS-SYLL) | NHR |  |
| `rus.a18.16` | LS01 pictorial | F29 → — | молоко́ `pic.milk` | ры́ба `pic.fish` (M-RUS-SYLL) · сыр `pic.cheese` (M-RUS-SYLL) | NHR |  |
| `rus.a18.17` | LS01 pictorial | F30 → — | ма́ма `pic.fam.mother` | кот `pic.tomcat` (M-RUS-SYLL) · ба́бушка `pic.fam.grandmother` (M-RUS-SYLL) | NHR |  |
| `rus.a18.18` C | LS01 pictorial | F30 → — | ры́ба `pic.fish` | нос `hot.nose` (M-RUS-SYLL) · соба́ка `pic.dog` (M-RUS-SYLL) | NHR |  |
| `rus.a18.19` C | LS01 pictorial | F31 → — | нос `hot.nose` | ру́ки `hot.arms` (M-RUS-SYLL) · голова́ `hot.head` (M-RUS-SYLL) | NHR |  |

**Hint ladder.** 1: the syllable clip again, slower (F02). 2: the friend claps with the child: a hand appears on each beat (a new representation: seeing the beats). 3: show me: the drum is tapped for the child, beat by beat, with the syllables.

**Mastery and notes.** The syllable clips (`sy-*`) are said by syllables with full vowels, as Russian kindergartens do for clapping; they are never a speaking model (pronunciation.csv). One-syllable words use the ordinary word clip. Counts 1 to 3 only.

### RUS-A-19 The first sound (a long one)
*Strand PHO · prerequisites A-18 · templates: LS01 pictorial with a held-first-sound model, LS01 same / different (2 choices)*

| Route | How the skill is served |
|---|---|
| New learner | Items 01–05 and 12 first; 06–11 on a later visit |
| Heritage | All items mixed |
| Reader | As heritage |

| Item | Template | Frame (Hebrew) → Russian clip | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|
| `rus.a19.01` | LS01 pictorial | F32 → `sf-mama` | мышь `pic.mouse` | нос `hot.nose` (M-RUS-SOUND) · дом `pic.house` (M-RUS-NOTFIRST) | NHR | the model word is heard with its first sound held (intonational highlighting); no isolated sound is needed |
| `rus.a19.02` | LS01 pictorial | F32 → `sf-sok` | сыр `pic.cheese` | шар `pic.bigballoon` (M-RUS-SOUND) · нос `hot.nose` (M-RUS-NOTFIRST) | NHR |  |
| `rus.a19.03` | LS01 pictorial | F32 → `sf-shapka` | шарф `pic.scarf` | сок `pic.juice` (M-RUS-SOUND) · мышь `pic.mouse` (M-RUS-NOTFIRST) | NHR |  |
| `rus.a19.04` | LS01 pictorial | F32 → `sf-nos` | но́ги `hot.legs` | ма́ма `pic.fam.mother` (M-RUS-SOUND) · слон `pic.elephant` (M-RUS-NOTFIRST) | NHR |  |
| `rus.a19.05` C | LS01 pictorial | F32 → `sf-ryba` | рот `hot.mouth` | кот `pic.tomcat` (M-RUS-SOUND) · шар `pic.bigballoon` (M-RUS-NOTFIRST) | NHR |  |
| `rus.a19.06` | LS01 audio options (same / different) | F33 → `w-mysh` + `w-mama` | "same" | "different" (M-RUS-YESNO) | NHR | two words, each with its picture |
| `rus.a19.07` | LS01 audio options (same / different) | F33 → `w-sok` + `w-shar` | "different" | "same" (M-RUS-SOUND) | NHR |  |
| `rus.a19.08` | LS01 audio options (same / different) | F33 → `w-shapka` + `w-sharf` | "same" | "different" (M-RUS-YESNO) | NHR |  |
| `rus.a19.09` | LS01 audio options (same / different) | F33 → `w-nos` + `w-rot` | "different" | "same" (M-RUS-SOUND) | NHR |  |
| `rus.a19.10` | LS01 audio options (same / different) | F33 → `w-ryba` + `w-rot` | "same" | "different" (M-RUS-YESNO) | NHR |  |
| `rus.a19.11` | LS01 audio options (same / different) | F33 → `w-mysh` + `w-nos` | "different" | "same" (M-RUS-SOUND) | NHR | м and н: two nasals, the likeliest sound-alike start |
| `rus.a19.12` C | LS01 pictorial | F32 → `sf-sok` | слон `pic.elephant` | шар `pic.bigballoon` (M-RUS-SOUND) · нос `hot.nose` (M-RUS-NOTFIRST) | NHR | a new target for a known model: слон starts with the held с |

**Hint ladder.** 1: the model again, with the first sound held longer (F02). 2: the mouth picture: the friend's mouth shows the first sound (lips closed for м, teeth for с, rounded for ш, tongue up for н, a tongue-tip trill for р) while each option is said with its first sound held. 3: show me: the right picture glows and both words are said with their first sound held.

**Mastery and notes.** Only hard consonants that can be held (м, с, ш, н, р) are targets, so the hard / soft difference (A-20) is not mixed in: мяч (soft м) is never an option for м. Same / different items (06–11) are 2-choice: 6 of the 12 scored items (at most half, frame §2.3), balanced (3 "same": 06, 08, 10; 3 "different": 07, 09, 11). A wrong answer on a "same" pair is M-RUS-YESNO; on a "different" pair, M-RUS-SOUND. The checks (05, 12) are picture items.

### RUS-A-20 ● Hard / soft and ы / и
*Strand PHO/LIS · prerequisites A-19 · templates: LS09 teach (meaning first), LS01 pictorial minimal pairs, LS01 same / different (audio only, 2 choices)*

**Teach screens (LS09, new-learner route):** set 1: лук, люк, мы́шка, ми́шка, рысь, рис. Each word: the picture, the word clip twice with F05 between (F03 if the child is shy), then on.

| Route | How the skill is served |
|---|---|
| New learner | Teach all six words (meaning first; люк, рысь, рис and мы́шка are new); items 01–06 and 17–20, then 07–16 on later visits |
| Heritage | Teach screens shortened to one hearing; all items mixed |
| Reader | As heritage |

| Item | Template | Frame (Hebrew) → Russian clip | Right answer | Distractors (tag) | Routes | Notes |
|---|---|---|---|---|---|---|
| `rus.a20.01` | LS01 pictorial | F35 → `mp-luk` | лук `pic.onion` | люк `pic.manhole` (M-RUS-HARDSOFT) · жук `pic.beetle` (M-RUS-SOUND) | NHR |  |
| `rus.a20.02` | LS01 pictorial | F35 → `mp-ljuk` | люк `pic.manhole` | лук `pic.onion` (M-RUS-HARDSOFT) · жук `pic.beetle` (M-RUS-SOUND) | NHR |  |
| `rus.a20.03` | LS01 pictorial | F35 → `w-myshka` | мы́шка `pic.mouse` | ми́шка `pic.teddy` (M-RUS-YI) · ко́шка `pic.cat` (M-RUS-SOUND) | NHR |  |
| `rus.a20.04` | LS01 pictorial | F35 → `w-mishka` | ми́шка `pic.teddy` | мы́шка `pic.mouse` (M-RUS-YI) · кни́жка `pic.book` (M-RUS-SOUND) | NHR |  |
| `rus.a20.05` | LS01 pictorial | F35 → `w-rys` | рысь `pic.lynx` | рис `pic.rice` (M-RUS-YI) · ры́ба `pic.fish` (M-RUS-SOUND) | NHR |  |
| `rus.a20.06` | LS01 pictorial | F35 → `w-ris` | рис `pic.rice` | рысь `pic.lynx` (M-RUS-YI) · кит `pic.whale` (M-RUS-SOUND) | NHR |  |
| `rus.a20.07` | LS01 same / different | F34 → `syl-my` + `syl-mi` | "different" | "same" (M-RUS-YI) | NHR | audio only |
| `rus.a20.08` | LS01 same / different | F34 → `mp-luk` + `mp-ljuk` | "different" | "same" (M-RUS-HARDSOFT) | NHR |  |
| `rus.a20.09` | LS01 same / different | F34 → `syl-ly` + `syl-li` | "different" | "same" (M-RUS-YI) | NHR |  |
| `rus.a20.10` | LS01 same / different | F34 → `syl-la` + `syl-lja` | "different" | "same" (M-RUS-HARDSOFT) | NHR |  |
| `rus.a20.11` | LS01 same / different | F34 → `syl-my` + `syl-my` | "same" | "different" (M-RUS-YESNO) | NHR |  |
| `rus.a20.12` | LS01 same / different | F34 → `syl-sy` + `syl-sy` | "same" | "different" (M-RUS-YESNO) | NHR | one clip played twice |
| `rus.a20.13` | LS01 same / different | F34 → `syl-no` + `syl-njo` | "different" | "same" (M-RUS-HARDSOFT) | NHR |  |
| `rus.a20.14` | LS01 same / different | F34 → `mp-luk` + `mp-luk` | "same" | "different" (M-RUS-YESNO) | NHR |  |
| `rus.a20.15` | LS01 same / different | F34 → `w-rys` + `w-rys` | "same" | "different" (M-RUS-YESNO) | NHR | one clip played twice (рысь / рис is tested with pictures: 05, 06, 19, 20) |
| `rus.a20.16` | LS01 same / different | F34 → `syl-mi` + `syl-mi` | "same" | "different" (M-RUS-YESNO) | NHR |  |
| `rus.a20.17` | LS01 pictorial | F35 → `w-myshka` | мы́шка `pic.mouse` | ми́шка `pic.teddy` (M-RUS-YI) · кни́жка `pic.book` (M-RUS-SOUND) | NHR | as 03, with another sound-alike |
| `rus.a20.18` C | LS01 pictorial | F35 → `w-mishka` | ми́шка `pic.teddy` | мы́шка `pic.mouse` (M-RUS-YI) · ко́шка `pic.cat` (M-RUS-SOUND) | NHR | as 04, with another sound-alike |
| `rus.a20.19` C | LS01 pictorial | F35 → `w-rys` | рысь `pic.lynx` | рис `pic.rice` (M-RUS-YI) · мышь `pic.mouse` (M-RUS-SOUND) | NHR | мышь nearly rhymes with рысь (the same ы) |
| `rus.a20.20` C | LS01 pictorial | F35 → `w-ris` | рис `pic.rice` | рысь `pic.lynx` (M-RUS-YI) · ры́ба `pic.fish` (M-RUS-SOUND) | NHR |  |

**Hint ladder.** 1: the two words again, slower, each with its picture (F02). 2: the mouth (F36): the friend smiles wide for the soft one (люк, ми́шка, рис, ли, ля, нё) and keeps a round or neutral mouth for the hard one; for ы, the puzzled friend says "ы…" (the M-RUS-YI re-teach). 3: show me: the pair is played, the target lit: лук … люк.

**Mastery and notes.** Core skill: 6 correct over 2 days, 2 checks, at least 2 representations. Same / different (07–16) is 10 of the 20 scored items (at most half, frame §2.3), balanced (5 "same": 11, 12, 14, 15, 16, each one clip played twice; 5 "different": 07, 08, 09, 10, 13). A wrong answer on a "same" pair is M-RUS-YESNO; on a "different" pair, its contrast tag (HARDSOFT or YI). The checks (18, 19, 20) are picture minimal pairs: pointing to the picture of a heard word is the better evidence at 3 to 4 (frame §4.4 R2; an assumption to check in the owner's play tests). Minimal-pair clips have the same pitch and loudness (pronunciation.csv `check`). `revisitWith`: HARDSOFT and YI items are checked together.


## 5. Words and pictures
Every Russian word met in Band A, its clip and its picture. Picture ids are proposals for the design-director; one picture can serve several words (кни́га and кни́жка, мышь and мы́шка). Hotspots (`hot.*`) are regions on the friend's body in A-03; where a body word is an option elsewhere (A-17, A-19), the same id means a picture of the friend's face or body with that part shown large.

| Russian (stress for the voice) | Clip | Picture | Picture brief (design-director) |
|---|---|---|---|
| апельси́н | `w-apelsin` | `pic.orange` | an orange |
| арбу́з | `w-arbuz` | `pic.watermelon` | a watermelon |
| ба́бушка | `w-babushka` | `pic.fam.grandmother` | the grandmother (grey hair, glasses) |
| бана́н | `w-banan` | `pic.banana` | a banana |
| беги́ | `w-begi` | `pic.act.run` | the friend running |
| бе́лка | `w-belka` | `pic.squirrel` | a squirrel |
| бе́лый | `w-belyj` | `col.white` | a white patch with a grey outline |
| боти́нки | `w-botinki` | `pic.shoes` | a pair of shoes |
| брат | `w-brat` | `pic.fam.brother` | the older brother (about 9), arrow from the family picture |
| ва́режки | `w-varezhki` | `pic.mittens` | a pair of mittens |
| виногра́д | `w-vinograd` | `pic.grapes` | a bunch of grapes |
| вода́ | `w-voda` | `pic.water` | a glass of clear water with a drop |
| возьми́ мяч | `ch-vozmi-mjach` | `pic.act.take` | the friend picking up a ball |
| волк | `w-volk` | `pic.wolf` | a wolf |
| во́лосы | `w-volosy` | `hot.hair` | hotspot: the hair |
| встань | `w-vstan` | `pic.act.stand` | the friend standing up from a chair |
| глаза́ | `w-glaza` | `hot.eyes` | hotspot: both eyes |
| голова́ | `w-golova` | `hot.head` | hotspot: the head |
| гру́ша | `w-grusha` | `pic.pear` | a pear |
| да | `w-da` | `pic.yes` | a friend nodding (a green tick on the button) |
| де́вочка | `w-devochka` | `pic.girl` | a girl of about 5, alone (not from the family) |
| де́душка | `w-dedushka` | `pic.fam.grandfather` | the grandfather (grey hair, a cap) |
| до свида́ния | `w-do-svidanija` | — | (heard only) |
| дом | `w-dom` | `pic.house` | a house |
| живо́т | `w-zhivot` | `hot.belly` | hotspot: the belly |
| жира́ф | `w-zhiraf` | `pic.giraffe` | a giraffe |
| жук | `w-zhuk` | `pic.beetle` | a beetle |
| жёлтый | `w-zholtyj` | `col.yellow` | a yellow patch |
| за́яц | `w-zajats` | `pic.hare` | a hare |
| здра́вствуйте | `w-zdravstvujte` | — | (heard only) |
| зелёный | `w-zeljonyj` | `col.green` | a green patch |
| зу́бы | `w-zuby` | `hot.teeth` | hotspot: the teeth (the friend grins widely) |
| иди́ | `w-idi` | `pic.act.walk` | the friend walking |
| каранда́ш | `w-karandash` | `pic.pencil` | a pencil |
| карто́шка | `w-kartoshka` | `pic.potato` | potatoes |
| ка́ша | `w-kasha` | `pic.porridge` | a bowl of porridge |
| кит | `w-kit` | `pic.whale` | a whale |
| клубни́ка | `w-klubnika` | `pic.strawberry` | strawberries |
| кни́га | `w-kniga` | `pic.book` | a picture book |
| кни́жка | `w-knizhka` | `pic.book` | a picture book (кни́жка is the friendly form of кни́га) |
| коза́ | `w-koza` | `pic.goat` | a goat |
| коро́ва | `w-korova` | `pic.cow` | a cow |
| кот | `w-kot` | `pic.tomcat` | a big striped tomcat |
| ко́шка | `w-koshka` | `pic.cat` | a cat |
| кра́сный | `w-krasnyj` | `col.red` | a red patch |
| ку́бики | `w-kubiki` | `pic.blocks` | toy blocks |
| ку́кла | `w-kukla` | `pic.doll` | a doll |
| ку́рица | `w-kuritsa` | `pic.hen` | a hen |
| ку́ртка | `w-kurtka` | `pic.jacket` | a jacket |
| лиса́ | `w-lisa` | `pic.fox` | a fox |
| ло́шадь | `w-loshad` | `pic.horse` | a horse |
| лук | `mp-luk` | `pic.onion` | an onion |
| люк | `mp-ljuk` | `pic.manhole` | a round hatch in the street |
| малы́ш | `w-malysh` | `pic.fam.baby` | the baby of the family (a toddler, no clear gender) |
| ма́льчик | `w-malchik` | `pic.boy` | a boy of about 5, alone (not from the family) |
| ма́ма | `w-mama` | `pic.fam.mother` | the mother of the original family |
| маши́на | `w-mashina` | `pic.car` | a toy car |
| медве́дь | `w-medved` | `pic.bear` | a brown bear (a real animal, not a toy) |
| ми́шка | `w-mishka` | `pic.teddy` | a teddy bear |
| молоко́ | `w-moloko` | `pic.milk` | a glass of milk beside a milk carton |
| морко́вь | `w-morkov` | `pic.carrot` | a carrot |
| мы́шка | `w-myshka` | `pic.mouse` | a mouse (мы́шка is the friendly form of мышь) |
| мышь | `w-mysh` | `pic.mouse` | a mouse |
| мяч | `w-mjach` | `pic.ball` | a ball |
| нет | `w-net` | `pic.no` | a friend shaking its head (a grey cross on the button) |
| но́ги | `w-nogi` | `hot.legs` | hotspot: both legs with feet |
| нос | `w-nos` | `hot.nose` | hotspot: the nose |
| носки́ | `w-noski` | `pic.socks` | a pair of socks |
| носо́к | `w-nosok` | `pic.sock` | one sock |
| огуре́ц | `w-ogurets` | `pic.cucumber` | a cucumber |
| па́льцы | `w-paltsy` | `hot.fingers` | hotspot: the fingers of one raised hand |
| па́па | `w-papa` | `pic.fam.father` | the father of the original family |
| пету́х | `w-petuh` | `pic.rooster` | a rooster (big comb and tail) |
| пече́нье | `w-pechenje` | `pic.cookie` | a round biscuit |
| пирами́дка | `w-piramidka` | `pic.stacker` | a ring-stacking pyramid toy |
| пла́тье | `w-platje` | `pic.dress` | a dress |
| пока́ | `w-poka` | `pic.rus.leave` | the friend walks out of the door, waving goodbye |
| помидо́р | `w-pomidor` | `pic.tomato` | a tomato |
| приве́т | `w-privet` | `pic.rus.arrive` | the friend comes in at the door, waving hello |
| пры́гай | `w-prygaj` | `pic.act.jump` | the friend jumping |
| пти́ца | `w-ptitsa` | `pic.bird` | a small songbird |
| пёс | `w-pjos` | `pic.dog.shaggy` | a shaggy, friendly dog (the chant) |
| рис | `w-ris` | `pic.rice` | a bowl of white rice |
| рот | `w-rot` | `hot.mouth` | hotspot: the mouth (closed smile) |
| ру́ки | `w-ruki` | `hot.arms` | hotspot: both arms with hands |
| ры́ба | `w-ryba` | `pic.fish` | a fish |
| рысь | `w-rys` | `pic.lynx` | a lynx (ear tufts, short tail) |
| сапоги́ | `w-sapogi` | `pic.boots` | a pair of boots |
| свинья́ | `w-svinja` | `pic.pig` | a pig |
| семья́ | `w-semja` | `pic.fam.all` | the whole original family together |
| сестра́ | `w-sestra` | `pic.fam.sister` | the older sister (about 9), arrow from the family picture |
| си́ний | `w-sinij` | `col.blue` | a medium-dark blue patch (never light blue: that is голубо́й) |
| слон | `w-slon` | `pic.elephant` | an elephant |
| соба́ка | `w-sobaka` | `pic.dog` | a dog |
| сок | `w-sok` | `pic.juice` | a glass of orange juice with a straw |
| спаси́бо | `w-spasibo` | `pic.rus.gift` | the friend is handed an apple and smiles |
| суп | `w-sup` | `pic.soup` | a bowl of soup with a spoon |
| сыр | `w-syr` | `pic.cheese` | a wedge of yellow cheese with holes |
| сядь | `w-sjad` | `pic.act.sit` | the friend sitting down on a chair |
| у́тка | `w-utka` | `pic.duck` | a duck |
| у́ши | `w-ushi` | `hot.ears` | hotspot: both ears |
| футбо́лка | `w-futbolka` | `pic.tshirt` | a T-shirt |
| хлеб | `w-hleb` | `pic.bread` | a loaf of bread |
| хло́пай | `w-hlopaj` | `pic.act.clap` | the friend clapping |
| чай | `w-chaj` | `pic.tea` | a cup of tea |
| чёрный | `w-chornyj` | `col.black` | a black patch |
| ша́пка | `w-shapka` | `pic.hat` | a warm hat |
| шар | `w-shar` | `pic.bigballoon` | a big round balloon |
| ша́рик | `w-sharik` | `pic.balloon` | a small balloon on a string |
| шарф | `w-sharf` | `pic.scarf` | a scarf |
| штаны́ | `w-shtany` | `pic.trousers` | trousers |
| юла́ | `w-jula` | `pic.top` | a spinning top |
| я́блоко | `w-yabloko` | `pic.apple` | a red apple |
| яйцо́ | `w-jajtso` | `pic.egg` | an egg |
| ёж | `w-yozh` | `pic.hedgehog` | a hedgehog |
| ёжик | `w-jozhik` | `pic.hedgehog` | a hedgehog (the story) |

## 6. Counts
| Skill | Items |
|---|---|
| RUS-A-01 | 8 |
| RUS-A-02 | 15 |
| RUS-A-03 | 15 |
| RUS-A-04 ● | 13 |
| RUS-A-05 | 32 |
| RUS-A-06 | 12 |
| RUS-A-07 | 27 |
| RUS-A-08 | 15 |
| RUS-A-09 | 15 |
| RUS-A-10 | 10 |
| RUS-A-11 | 10 |
| RUS-A-12 ● | 12 |
| RUS-A-13 | 10 |
| RUS-A-14 | 11 |
| RUS-A-15 ● | 24 |
| RUS-A-16 | 9 |
| RUS-A-17 | 5 |
| RUS-A-18 | 19 |
| RUS-A-19 | 12 |
| RUS-A-20 ● | 20 |

- **Items:** 294 in 20 skills, of which 265 have tagged distractors (the rest are LS09 say-it, story listening and the two optional personal turns); plus **117 teach screens** (LS09) for the new-learner route. **44 checks** (C): two per skill, three per core skill, none a single 2-choice item. **38 two-choice items**, at most half of every skill's scored items (A-19 6 of 12, A-20 10 of 20, both balanced same / different). The 10 counting steps of A-10 and A-11 are practice; their scored part is "how many?" (frame §2.2). Changed on 2026-11-03 for frame §4.5: A-19 +1 item, A-20 +4.
- **Words:** 116 Russian words with a picture or a clip; **40 Hebrew frame lines** (§2), all `text-ready`.
- **Pronunciation specs:** **214 new rows** in `pronunciation.csv` (status `draft`), and 20 pilot rows reused; the table has 269 rows. On 2026-11-03 `ch-skolko` (Ско́лько?, for "how many?") was added and `syl-si` removed (its only item, a20.12, is now the "same" pair сы / сы). Every new row has its stress (the `stress` column; U+0301 in `say`).
- **Characters for voicing (for the voice-and-sound-director's plan; nothing is run by Claude):**
  - Russian, the new rows' `say` text: **2363 characters** with the stress marks (U+0301 counted), 2127 without them (was 2356 and 2121: +9 for Ско́лько?, −2 for си). The 20 reused pilot rows add 104 characters if they are voiced again for the course.
  - Hebrew frame lines: **979 characters** of voice text for the 40 final lines (965 without F03, already approved), counted by the hebrew-text-editor on 2026-11-03 after the final wording (938 for F01 to F39, and 41 for F40; the drafts counted 877). The voice text has partial nikud (number words, sin-dot words and a few ambiguous words keep theirs). F40 is the same line as the English `he-ins-how-many`: if the two courses share a voice, one clip of 41 characters serves both.
  - The owner runs and pays for every generation, after the voice-and-sound-director shows the count and the cost.
- **Clip check (by script):** clips referenced but missing from the CSV: []; batch rows referenced nowhere: [].
