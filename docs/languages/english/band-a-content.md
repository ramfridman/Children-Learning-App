# English course: Band A content batch (ENG-1)

Owner: english-language-teacher. Date: 2026-11-03. Status: **draft for the team and the owner. Nothing is built or voiced.** The English is the teacher's and final after the listening check; every **Hebrew line is final** (`text-ready`, waiting for the owner, 2026-11-03: the hebrew-text-editor added the nikud, the voice text and the address rule of `docs/agents/hebrew-notes.md` §9); every picture is a brief for the design-director.

Built on: `syllabus.md` §2 Band A (ENG-A-01 to A-17), `templates.md` (the shared ids), `docs/languages/frame.md` (§2.3 templates, §3 mastery and set coverage, §5.1 speech, §5.2 personal turns), `docs/curriculum.md` §9 (feedback) and §10. Pronunciation specs: `pronunciation.csv` (one row per English clip). Made and checked by a script (the counts in §7 are its output).

## 1. The rules every item here follows
- **Band A presentation:** at most 3 choices, one instruction at a time, no reading, no left/right words, big targets. 3 to 5 items per activity. A 7-year-old new to English meets the same items with Band C presentation (fewer per skill).
- **Hebrew frame, English target (D7):** the Hebrew instruction is its own clip, then the English clip (F3). From the second visit, "Listen!" (en-listen) and "Look!" (en-look) start to replace he-ins-listen-tap, with the same icon; the Hebrew stays on the replay button.
- **One right answer, every distractor tagged (frame §2.3).** Every scored item has one right answer and every distractor carries the error it reveals (§8 of the syllabus): `M-ENG-SEM` a same-set neighbour; `M-ENG-L1-GUESS` a familiar picture from another set; `M-ENG-YESNO`; `M-ENG-SYLL` and `M-ENG-WEAK-SYLL` in beat counting; `M-ENG-STORY-RECALL` a story detail from the wrong page. A 3-choice item has two tagged distractors (they may share a tag); a 2-choice item has one. Accent tags are never on a distractor. The drum (LS03, free response) has no fixed distractors: its classifier maps one beat more or fewer to a tag, and any other count is a retry with no tag.
- **The 2-choice rule (frame §2.3):** 2-choice items are at most half of each skill's scored items; every skill with 2-choice items also has 3-choice items (A-01, A-10, A-16), and ENG-A-16's thumbs items are balanced (3 "yes", 3 "no"); a 2-choice item allows one retry only.
- **Checks (C):** each skill has at least two checks with different words (an understanding check, and a different item for the delayed check). A check is a 3-choice item, or in ENG-A-16 a **balanced pair** (one "yes" and one "no", served together, passing only if both are right). A 2-choice item is never a check on its own; a drum item or a probe is never a check.
- **Counting is practice (frame §2.2):** in T02 the counting taps play the number words and are never scored (a skipped or double tap is maths, not English); the scored step is "how many?" with 3 number words heard on a tap.
- **Set coverage (frame §3.3.4):** each word of a set is the right answer of at least one item; each word is its own `variantGroup`. Distractor roles rotate so no picture is always wrong.
- **Feedback** (curriculum §9.1, §9.2): right → one of 8 Hebrew praise lines (he-fb-right-1 to 8) + the English word ("בדיוק! cat"). First error → he-fb-check, then the diagnostic line: he-fb-thats + the English word of the chosen picture + he-fb-listen-again + the target word (the child hears the two words side by side). No red, no buzzer. The hint ladder (§3) follows. After 3 errors in a row on a skill, an easier item.
- **Speech (frame §5.1):** only in LS09 and the say step of LS10, only when a parent turned English voice on; **confident** → he-fb-heard + the word; **unsure** → he-fb-together + the word and a choral pause; at most one more try (he-fb-try-once, by a tap). Never "wrong". Voice off → "I said it".
- **Personal turns (D10, frame §5.2):** 4 optional turns (name A-01, age A-04, family A-07, likes A-08), each with the puppet answering first, a "pass", a generic reply, no storing, no scoring; never an address.
- **Characters:** **Pip** (the English puppet and host) and **Mika** (Pip's friend) are working names for original characters; the design-director draws and may rename them before voicing (a rename changes the Pip lines). The child's companion only reacts (frame §1.3).
- **Order:** the options of every item are shown in a random order (the tables list the right answer first only for reading).
- **Color-blind safe:** red and green are never options in the same item (A-03, A-12).

## 2. Hebrew frame lines (final, `text-ready`)
The rule (`hebrew-notes.md` §9.1): the teaching voice speaks to the children in the plural, in "let's" forms or in the impersonal present, whatever the profile's address form, and says nothing in the first person that has a gender. So there is no per-child version of any line (one clip per line, not three), and any voice can say them. Full nikud (child text). The voice text is the line for ElevenLabs: partial nikud, no "!", no quotes; a word with the sin dot keeps its nikud; a line that ends in a colon is a carrier before another clip.

| Id | Hebrew (final, with nikud) | Voice text (for ElevenLabs) | Meaning | Used in | review |
|---|---|---|---|---|---|
| he-welcome | שָׁלוֹם! בָּאִי הַזֶּה מְדַבְּרִים אַנְגְּלִית. בּוֹאוּ נַקְשִׁיב וּנְשַׂחֵק. | שלום, באי הזה מדברים אנגלית. בואו נקשיב וּנְשַׂחֵק. | Hello! On this island we speak English. Let's listen and play. | first visit | text-ready |
| he-bye | לְהִתְרָאוֹת! הָיָה כֵּיף לְשַׂחֵק בְּאַנְגְּלִית. | להתראות, היה כיף לְשַׂחֵק באנגלית. | Goodbye! It was fun to play in English. | end of a visit | text-ready |
| he-ins-listen-tap | הַקְשִׁיבוּ, וּגְעוּ בַּתְּמוּנָה. | הקשיבו, וגעו בתמונה. | Listen, and touch the picture. | LS01 tap (until "Listen!" replaces it) | text-ready |
| he-ins-who-doing | הַקְשִׁיבוּ, וּגְעוּ בַּתְּמוּנָה שֶׁל הַפְּעֻלָּה. | הקשיבו, וגעו בתמונה של הפעולה. | Listen, and touch the picture of the action. | A-02 LS01 | text-ready |
| he-ins-make-do | הַקְשִׁיבוּ, וְהַרְאוּ לְמִיקָה מַה לַּעֲשׂוֹת: גְּעוּ בַּכַּפְתּוֹר. | הקשיבו, והראו למיקה מה לַעֲשׂוֹת: געו בכפתור. | Listen, and show Mika what to do: touch the button. | A-02 LS11 buttons | text-ready |
| he-ins-do-too | עַכְשָׁו אַתֶּם! עֲשׂוּ אֶת זֶה, וְאָז גְּעוּ בַּכַּפְתּוֹר "סִיַּמְתִּי". | עכשיו אתם, עֲשׂוּ את זה, ואז געו בכפתור — סיימתי. | Now you! Do it, then touch the button "done". | LS11 embodied | text-ready |
| he-ins-count | בּוֹאוּ נִסְפֹּר בְּאַנְגְּלִית. גְּעוּ בְּכׇל אֶחָד. | בואו נספור באנגלית. געו בכל אֶחָד. | Let's count in English. Touch each one. | A-04 T02 | text-ready |
| he-ins-how-many | כַּמָּה יֵשׁ? הַקְשִׁיבוּ לַכַּפְתּוֹרִים, וּגְעוּ בַּמִּסְפָּר הַנָּכוֹן. | כמה יש? הקשיבו לכפתורים, וגעו במספר הנכון. | How many are there? Listen to the buttons, and touch the right number. | A-04 T02, the scored "how many?" step after the counting (frame §2.2); added 2026-11-03 by the English teacher; the same line as Russian F40 | text-ready |
| he-ins-touch-body | הַקְשִׁיבוּ, וּגְעוּ בַּגּוּף שֶׁל מִיקָה. | הקשיבו, וגעו בגוף של מיקה. | Listen, and touch Mika's body. | A-06 LS11 hotspots | text-ready |
| he-ins-give | הַקְשִׁיבוּ, וְגִרְרוּ אֶת הָאֹכֶל לְפִיפּ. | הקשיבו, וגררו את הָאֹכֶל לפיפ. | Listen, and drag the food to Pip. | A-08 LS11 drag | text-ready |
| he-ins-say | עַכְשָׁו תּוֹרְכֶם. אִמְרוּ גַּם אַתֶּם! | עכשיו תורכם. אִמְרוּ גם אתם. | Now it's your turn. You say it too! | LS09 | text-ready |
| he-ins-mic | גְּעוּ בַּמִּיקְרוֹפוֹן, וְאִמְרוּ. | געו במיקרופון, וְאִמְרוּ. | Touch the microphone, and say it. | LS09 voice on | text-ready |
| he-ins-said-it | אָמַרְתֶּם? גְּעוּ בַּכַּפְתּוֹר "אָמַרְתִּי". | אמרתם? געו בכפתור — אמרתי. | Did you say it? Touch the button "I said it". | LS09 voice off | text-ready |
| he-ins-find-said | וְעַכְשָׁו גְּעוּ בַּתְּמוּנָה שֶׁל הַמִּלָּה. | ועכשיו געו בתמונה של המילה. | And now touch the picture of the word. | LS09 then tap | text-ready |
| he-ins-drum | הַקְשִׁיבוּ לַמִּלָּה, וְתוֹפְפוּ פַּעַם אַחַת לְכׇל חֵלֶק. | הקשיבו למילה, ותופפו פעם אַחַת לכל חלק. | Listen to the word, and drum once for each part. | A-14 LS03 drum | text-ready |
| he-ins-strip | כַּמָּה תֻּפִּים? גְּעוּ בַּשּׁוּרָה הַנְּכוֹנָה. | כמה תופים? געו בשורה הנכונה. | How many drums? Touch the right row. | A-14 LS01 | text-ready |
| he-ins-story | בּוֹאוּ נִשְׁמַע סִפּוּר. אֶפְשָׁר לָגַעַת בַּתְּמוּנוֹת. | בואו נשמע סיפור. אפשר לגעת בתמונות. | Let's hear a story. You can touch the pictures. | A-15 LS08 | text-ready |
| he-q-who | מִי זֶה? | מי זה? | Who is it? | A-15 dialogic pause | text-ready |
| he-q-ball-end | אֵצֶל מִי הַכַּדּוּר בַּסּוֹף? | אצל מי הכדור בסוף? | Who has the ball at the end? | A-15 question | text-ready |
| he-q-ball-which | אֵיזֶה כַּדּוּר הָיָה בַּסִּפּוּר? | איזה כדור היה בסיפור? | Which ball was in the story? | A-15 question | text-ready |
| he-q-ball-first | לְיַד מִי הַכַּדּוּר קָפַץ בַּהַתְחָלָה? | ליד מי הכדור קפץ בהתחלה? | Who did the ball bounce past at the beginning? | A-15 question | text-ready |
| he-ins-thumbs | כֵּן אוֹ לֹא? גְּעוּ בַּאֲגוּדָל. | כן או לא? געו באגודל. | Yes or no? Touch a thumb. | A-16 LS01 | text-ready |
| he-ins-box | מַה יֵּשׁ בַּקֻּפְסָה? הַקְשִׁיבוּ לְפִיפּ. | מה יש בקופסה? הקשיבו לפיפ. | What is in the box? Listen to Pip. | A-16 guessing game | text-ready |
| he-ins-box-pick | אָז מַה יֵּשׁ בַּקֻּפְסָה? גְּעוּ בַּתְּמוּנָה. | אז מה יש בקופסה? געו בתמונה. | So what is in the box? Touch the picture. | A-16 guessing game | text-ready |
| he-ins-bubble | מָה עוֹנִים? גְּעוּ בַּבֻּעָה. | מה עונים? געו בבועה. | What do we answer? Touch a bubble. | LS10 | text-ready |
| he-ins-face | הַקְשִׁיבוּ, וּגְעוּ בַּפַּרְצוּף הַנָּכוֹן. | הקשיבו, וגעו בפרצוף הנכון. | Listen, and touch the right face. | A-17 LS01 | text-ready |
| he-ins-chant | בּוֹאוּ נְדַקְלֵם יַחַד, וְנַעֲשֶׂה אֶת הַתְּנוּעוֹת! | בואו נדקלם יחד, וְנַעֲשֶׂה את התנועות. | Let's chant together and do the moves! | LS12 | text-ready |
| he-ins-pairs | מִצְאוּ שְׁתֵּי תְּמוּנוֹת שֶׁהוֹלְכוֹת יַחַד. | מצאו שְׁתֵּי תמונות שהולכות יחד. | Find two pictures that go together. | LS01 pairs | text-ready |
| he-ins-whats-this | הַקְשִׁיבוּ לַשְּׁאֵלָה וְלַתְּשׁוּבָה, וּגְעוּ בַּתְּמוּנָה. | הקשיבו לשאלה ולתשובה, וגעו בתמונה. | Listen to the question and the answer, and touch the picture. | A-11 LS01 | text-ready |
| he-ins-personal | אֶפְשָׁר לַעֲנוֹת בִּתְמוּנָה, אוֹ בְּקוֹל. אֶפְשָׁר גַּם לְדַלֵּג. | אפשר לענות בתמונה, או בקול. אפשר גם לדלג. | You can answer with a picture, or out loud. You can also skip. | LS10 personal | text-ready |
| he-hint-again | הַקְשִׁיבוּ שׁוּב, לְאַט. | הקשיבו שוב, לאט. | Listen again, slowly. | H1 | text-ready |
| he-hint-hebrew | בְּעִבְרִית: | בעברית: | In Hebrew: | H2 (before the gloss) | text-ready |
| he-hint-english | וּבְאַנְגְּלִית: | ובאנגלית: | And in English: | H2 (after the gloss) | text-ready |
| he-hint-showme | הִסְתַּכְּלוּ אֵיךְ עוֹשִׂים. | הסתכלו איך עוֹשִׂים. | Watch how it is done. | H3 (the same line in every ladder) | text-ready |
| he-hint-beats | בּוֹאוּ נִמְחָא כַּפַּיִם לְכׇל חֵלֶק, לְאַט. | בואו נמחא כפיים לכל חלק, לאט. | Let's clap for each part, slowly. | A-14 H2 | text-ready |
| he-hint-page | בּוֹאוּ נַחֲזֹר לָעַמּוּד הַזֶּה בַּסִּפּוּר. | בואו נחזור לעמוד הזה בסיפור. | Let's go back to this page of the story. | A-15 H2 | text-ready |
| he-fb-right-1 | נָכוֹן! | נכון. | Right! | correct, followed by the English word clip (8 lines, curriculum §9.1) | text-ready |
| he-fb-right-2 | כֵּן! | כן. | Yes! | correct, followed by the English word clip (8 lines, curriculum §9.1) | text-ready |
| he-fb-right-3 | יָפֶה מְאֹד! | יפה מאוד. | Very nice! | correct, followed by the English word clip (8 lines, curriculum §9.1) | text-ready |
| he-fb-right-4 | מְצָאתֶם! | מצאתם. | You found it! | correct, followed by the English word clip (8 lines, curriculum §9.1) | text-ready |
| he-fb-right-5 | בְּדִיּוּק! | בדיוק. | Exactly! | correct, followed by the English word clip (8 lines, curriculum §9.1) | text-ready |
| he-fb-right-6 | שְׁמַעְתֶּם טוֹב! | שמעתם טוב. | You heard well! | correct, followed by the English word clip (8 lines, curriculum §9.1) | text-ready |
| he-fb-right-7 | הִקְשַׁבְתֶּם יָפֶה! | הקשבתם יפה. | You listened well! | correct, followed by the English word clip (8 lines, curriculum §9.1) | text-ready |
| he-fb-right-8 | כׇּל הַכָּבוֹד! | כל הכבוד. | Well done! | correct, followed by the English word clip (8 lines, curriculum §9.1) | text-ready |
| he-fb-check | הַמְּמ… בּוֹאוּ נִבְדֹּק. | המממ… בואו נבדוק. | Hmm… let's check. | first error (curriculum §9.2) | text-ready |
| he-fb-thats | זֶה | זה: | That is | diagnostic: "זה" + the chosen word in English | text-ready |
| he-fb-listen-again | בּוֹאוּ נַקְשִׁיב שׁוּב: | בואו נקשיב שוב: | Let's listen again: | diagnostic: then the target word | text-ready |
| he-fb-look-again | בּוֹאוּ נִסְתַּכֵּל שׁוּב עַל הַתְּמוּנָה. | בואו נסתכל שוב על התמונה. | Let's look at the picture again. | A-16 YESNO | text-ready |
| he-fb-beats-together | בּוֹאוּ נְתוֹפֵף יַחַד, לְאַט. | בואו נתופף יחד, לאט. | Let's drum together, slowly. | A-14 error | text-ready |
| he-fb-heard | שָׁמַעְתִּי: | שמעתי: | I heard: | LS09 confident (frame §5.1) + the word | text-ready |
| he-fb-together | בּוֹאוּ נֹאמַר יַחַד. | בואו נגיד יחד. | Let's say it together. | LS09 unsure (frame §5.1); the word follows as its own clip. The same line as the Hebrew and Russian courses | text-ready |
| he-fb-try-once | רוֹצִים לְנַסּוֹת עוֹד פַּעַם? גְּעוּ בַּמִּיקְרוֹפוֹן. | רוצים לנסות עוד פעם? געו במיקרופון. | Want to try once more? Touch the microphone. | LS09: at most one more try, by a tap | text-ready |

**What the editor changed** (the other lines only got nikud and the voice text):
- `he-welcome`: the verb "play" is pi'el (נְשַׂחֵק); the vav before a shva is וּ.
- `he-ins-who-doing`: was "touch the friend who is doing it": the pictures show one friend, and a participle would give the friend a gender.
- `he-ins-make-do`: was "and Mika will do it" (a masculine verb for Mika); now the child "shows Mika what to do", no verb about Mika, so no gender is guessed.
- `he-ins-do-too`: the button is named, and its label is quoted; סִיַּמְתִּי is a first-person past verb, the same in every voice.
- `he-ins-said-it`: same as `he-ins-do-too`: the button is named ("אָמַרְתִּי" is a first-person past verb, the same in every voice).
- `he-ins-drum`: "לְכׇל חֵלֶק", the same words as the Hebrew course (was "על כל חלק").
- `he-ins-give`: the name Pip is פִּיפּ with a hard final pe (dagesh), not a final ף.
- `he-ins-give` (voice text, 2026-11-03, second pass): הָאֹכֶל keeps its nikud, because plain האוכל is read with the stress on the last syllable ("the one who eats"); the same rule is in the Hebrew course (`i-odd-food`).
- `he-ins-how-many` (new, 2026-11-03): the English teacher's draft kept as it was in meaning ("How many are there? Listen to the buttons, and touch the right number"); pointed, plural, 7 words, no gender. `כַּמָּה יֵשׁ?` and not "how many did we count": the number is the answer, and the line is the same as Russian F40 (one clip can serve both courses).
- `he-ins-strip`: was "how many drum beats? touch the right row of drums"; the plural of תֹּף is תֻּפִּים; same wording as the Hebrew course.
- `he-ins-thumbs`: אֲגוּדָל (thumb); בַּ before a hataf.
- `he-ins-personal`: says first that answering is optional; the pass button is "לדלג".
- `he-ins-chant`: נְדַקְלֵם (we recite) is the gan word.
- `he-hint-showme`: was "תראו איך עושים" (a future form used as an order); the app's imperative.
- `he-hint-beats`: was "נמחא כף על כל חלק" (written register); the plural כפיים is the word of the gan songs.
- `he-q-ball-first`: was "ליד מי הכדור קפץ ראשון?" (ראשון is a number word here); "בהתחלה" says what is meant.
- `he-fb-beats-together`: the verb is the one of the Hebrew course (תוֹפֵף), not a third form.
- `he-fb-together`: the same approved line as the Hebrew and Russian courses (hebrew-notes.md 8.8), with a full stop instead of a colon; the model of the word is its own clip.
- `he-fb-thats`: a carrier: the English word of the chosen picture follows as its own clip.

**Glosses for hint level 2** (`he-gl-<word>`, `text-ready`; 68 words, 68 distinct Hebrew words): apple תַּפּוּחַ · baby תִּינוֹק · ball כַּדּוּר · banana בָּנָנָה · big גָּדוֹל · bike אוֹפַנַּיִם · bird צִפּוֹר · blue כָּחֹל · boat סִירָה · book סֵפֶר · bread לֶחֶם · brother אָח · bye בַּיי · cake עוּגָה · car מְכוֹנִית · cat חָתוּל · clap מְחִיאַת כַּפַּיִם · cold קַר · cow פָּרָה · dad אַבָּא · dog כֶּלֶב · drum תֹּף · duck בַּרְוָז · ears אָזְנַיִם · egg בֵּיצָה · elephant פִּיל · eyes עֵינַיִם · feet רַגְלַיִם · fine בְּסֵדֶר · fish דָּג · five חָמֵשׁ · four אַרְבַּע · frog צְפַרְדֵּעַ · goodbye לְהִתְרָאוֹת · grandma סַבְתָּא · grandpa סָבָא · green יָרֹק · hands יָדַיִם · happy שָׂמֵחַ · head רֹאשׁ · hello שָׁלוֹם · hi הַיי · hot חַם · juice מִיץ · jump קִפְצוּ · kite עֲפִיפוֹן · listen הַקְשִׁיבוּ · look הִסְתַּכְּלוּ · milk חָלָב · mom אִמָּא · mouth פֶּה · nose אַף · one אַחַת · pig חֲזִיר · red אָדֹם · sad עָצוּב · sister אָחוֹת · sit-down שְׁבוּ · small קָטָן · stand-up קוּמוּ · stop עִצְרוּ · teddy דֻּבִּי · three שָׁלוֹשׁ · tummy בֶּטֶן · two שְׁתַּיִם · water מַיִם · wave נוֹפְפוּ · yellow צָהֹב.

Editor's notes on the glosses: (1) The voice text of a gloss is the pointed word itself, as for every single-word clip until the voice pilot says whether unpointed words read as well (`hebrew-notes.md` 8.4). (2) Numbers are the counting forms (feminine, bare): אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. (3) The actions are plural imperatives, as the frame lines are; for "clap" the noun מְחִיאַת כַּפַּיִם is used because the plural imperative of מחא could not be checked in a dictionary. (4) A gloss names a word, so an adjective or a noun is in the dictionary form: שָׂמֵחַ, עָצוּב, קָטָן, תִּינוֹק are masculine singular and do **not** follow the character shown (a gloss is a name, not a sentence about a person). (5) "feet" is רַגְלַיִם, the word children use (it also means legs; the picture shows feet). (6) "drum" is תֹּף (plural תֻּפִּים), "bike" is the dual אוֹפַנַּיִם.

## 3. Hint ladders (level 2 changes the representation, level 3 is "show me")
| Ladder | Steps |
|---|---|
| HL-PIC | H1: he-hint-again, then the target slow clip (en-<word>-slow; for a chunk prompt, the key word's slow clip). H2 (D7): he-hint-hebrew + the Hebrew gloss (he-gl-<word>) + he-hint-english + the English word again; for an animal, its sound effect first. H3: he-hint-showme; the friend taps the right picture and the English word plays; the child taps it. |
| HL-ACT | H1: he-hint-again + the slow clip. H2: Mika shows the action as a short animation (a new representation: motion) with he-hint-hebrew + the gloss + he-hint-english + the command. H3: he-hint-showme; Mika does it and taps; the child taps. |
| HL-BODY | H1: he-hint-again + the body word's slow clip. H2: he-hint-hebrew + the gloss + he-hint-english + the word, while the close-up picture of that part appears beside Mika (a new representation). H3: he-hint-showme; Mika touches the part on itself; the child taps it. |
| HL-SET | H1: he-hint-again + the slow number clip. H2: he-hint-hebrew + the Hebrew number + he-hint-english + the number, with that many fingers shown (a new representation). H3: he-hint-showme; the voice counts one set aloud in English, tapping each object, and the child taps it. |
| HL-PAIRS | H1: the two cards of one pair play their words again, slowly. H2: one pair is shown joined with its Hebrew gloss. H3: he-hint-showme; the friend matches one pair; the child matches the rest. |
| HL-BUBBLE | H1: the puppet's line again, then each bubble plays slowly. H2: the scene's key picture glows and the key word's Hebrew gloss plays (he-hint-hebrew + gloss + he-hint-english + word). H3: he-hint-showme; the puppet points at the right bubble and says it; the child taps it. |
| HL-DRUM | H1: the word again, slowly, each beat a little apart. H2: he-hint-beats; hands clap once per beat while each beat lights (a new representation: movement and light). H3: he-hint-showme; the friend drums it; the child drums it after. |
| HL-COUNT | For the scored "how many?" step (the counting taps before it keep the T02 ladder and are never scored). H1: the objects light one by one while the voice counts them again in English, the last number a little longer; then the three buttons play again. H2: that many fingers appear beside the set (a new representation) with he-hint-hebrew + the Hebrew number (he-gl-<n>); the buttons play again. H3: he-hint-showme; the friend taps the right button and it plays; the child taps it. |
| HL-YN | 2-choice items allow one retry only (curriculum §9.2). H1: the question again, slowly, with the picture lit. H2: he-hint-hebrew + the gloss of the asked word + he-hint-english + the word, beside the picture. H3: he-hint-showme; the friend nods or shakes its head and taps the thumb; the child taps it. |
| HL-STORY | H1: the page that answers it plays again. H2: he-hint-page; the page picture comes back with the word pictures lit (the story representation). H3: he-hint-showme; the friend points to the answer on the page and taps it; the child taps it. |
| T02 ladder | The existing `count_tap` ladder, with English number clips, for the counting taps only (practice, never scored); the scored "how many?" step uses HL-COUNT. |

## 4. Items per skill
Columns: the item id; the template (shared ids); the Hebrew frame line; the English prompt (clip ids, `en-…` in `pronunciation.csv`); the options (picture ids, §6); the right answer; the distractors with their tags; the hint ladder; the representation (frame §3.3.1). Items marked *not scored* are practice. **P** marks a placement probe (§5). **C** marks an understanding or delayed check (a 3-choice item, or in ENG-A-16 a balanced pair; never a 2-choice item alone, frame §2.3); each skill has at least two, with different words, so the delayed check uses a different item.

### ENG-A-01 Greetings
Set (each a `variantGroup`): Hello!, Hi!, Goodbye!, Bye!.

| Item | Template | Hebrew frame | English prompt | Options | Right | Distractors (tag) | Hints | Rep. |
|---|---|---|---|---|---|---|---|---|
| i01 **P** | LS01 tap | he-ins-listen-tap | en-hello | pic.greet-arrive-pip; pic.greet-leave-pip | pic.greet-arrive-pip | pic.greet-leave-pip (M-ENG-SEM) | HL-PIC | pictorial |
| i02 | LS01 tap | he-ins-listen-tap | en-goodbye | pic.greet-leave-pip; pic.greet-arrive-pip; pic.mika-eat | pic.greet-leave-pip | pic.greet-arrive-pip (M-ENG-SEM); pic.mika-eat (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i03 **C** | LS01 tap | he-ins-listen-tap | en-hi | pic.greet-arrive-mika; pic.greet-leave-mika; pic.mika-eat | pic.greet-arrive-mika | pic.greet-leave-mika (M-ENG-SEM); pic.mika-eat (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i04 | LS01 tap | he-ins-listen-tap | en-bye | pic.greet-leave-mika; pic.greet-arrive-mika | pic.greet-leave-mika | pic.greet-arrive-mika (M-ENG-SEM) | HL-PIC | pictorial |
| i05 | LS01 tap | he-ins-listen-tap | en-hello | pic.greet-arrive-mika; pic.greet-leave-mika; pic.mika-eat | pic.greet-arrive-mika | pic.greet-leave-mika (M-ENG-SEM); pic.mika-eat (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i06 **C** | LS01 tap | he-ins-listen-tap | en-goodbye | pic.greet-leave-mika; pic.greet-arrive-mika; pic.mika-eat | pic.greet-leave-mika | pic.greet-arrive-mika (M-ENG-SEM); pic.mika-eat (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i07 | LS10 bubble | he-ins-bubble | en-pip-hello (Pip arrives) | bubble: en-hello (wave); bubble: en-goodbye (leaving) | bubble: en-hello (wave) | bubble: en-goodbye (leaving) (M-ENG-SEM) | HL-BUBBLE | story |
| i08 | LS10 bubble | he-ins-bubble | en-goodbye (Pip leaves) | bubble: en-bye (wave); bubble: en-hi (arriving) | bubble: en-bye (wave) | bubble: en-hi (arriving) (M-ENG-SEM) | HL-BUBBLE | story |
| p01 *not scored* | LS10 personal (name) | he-ins-personal | en-pip-hello, en-whats-your-name | voice (if on) or "I said it"; pass | - | - | - | story |
| r01 *not scored* | LS12 chant | he-ins-chant | en-ch-hello-1 … 4 (opens every visit); en-ch-bye-1 … 4 (ends it) | - | - | - | - | story |

- p01: Pip answers first ("I'm Pip"). Reply: en-nice-to-meet-you; on pass: en-thats-ok. The name is never matched, echoed, stored or sent; response empty, purpose personal.
- r01: Routine, practice only.

### ENG-A-02 Actions (TPR)
Set (each a `variantGroup`): Stand up!, Sit down!, Clap!, Jump!, Stop!, Look!, Listen!, Wave!.

| Item | Template | Hebrew frame | English prompt | Options | Right | Distractors (tag) | Hints | Rep. |
|---|---|---|---|---|---|---|---|---|
| i01 | LS01 tap | he-ins-who-doing | en-stand-up | pic.act-standup; pic.act-sitdown; pic.act-clap | pic.act-standup | pic.act-sitdown (M-ENG-SEM); pic.act-clap (M-ENG-L1-GUESS) | HL-ACT | pictorial |
| i02 | LS01 tap | he-ins-who-doing | en-sit-down | pic.act-sitdown; pic.act-standup; pic.act-jump | pic.act-sitdown | pic.act-standup (M-ENG-SEM); pic.act-jump (M-ENG-L1-GUESS) | HL-ACT | pictorial |
| i03 | LS01 tap | he-ins-who-doing | en-clap | pic.act-clap; pic.act-wave; pic.act-look | pic.act-clap | pic.act-wave (M-ENG-SEM); pic.act-look (M-ENG-L1-GUESS) | HL-ACT | pictorial |
| i04 **P** | LS01 tap | he-ins-who-doing | en-jump | pic.act-jump; pic.act-stop; pic.act-listen | pic.act-jump | pic.act-stop (M-ENG-SEM); pic.act-listen (M-ENG-L1-GUESS) | HL-ACT | pictorial |
| i05 | LS01 tap | he-ins-who-doing | en-stop | pic.act-stop; pic.act-jump; pic.act-wave | pic.act-stop | pic.act-jump (M-ENG-SEM); pic.act-wave (M-ENG-L1-GUESS) | HL-ACT | pictorial |
| i06 | LS01 tap | he-ins-who-doing | en-look | pic.act-look; pic.act-listen; pic.act-standup | pic.act-look | pic.act-listen (M-ENG-SEM); pic.act-standup (M-ENG-L1-GUESS) | HL-ACT | pictorial |
| i07 | LS01 tap | he-ins-who-doing | en-listen | pic.act-listen; pic.act-look; pic.act-stop | pic.act-listen | pic.act-look (M-ENG-SEM); pic.act-stop (M-ENG-L1-GUESS) | HL-ACT | pictorial |
| i08 | LS01 tap | he-ins-who-doing | en-wave | pic.act-wave; pic.act-clap; pic.act-sitdown | pic.act-wave | pic.act-clap (M-ENG-SEM); pic.act-sitdown (M-ENG-L1-GUESS) | HL-ACT | pictorial |
| i09 | LS11 buttons | he-ins-make-do | en-jump | button jump; button stop; button listen | button jump | button stop (M-ENG-SEM); button listen (M-ENG-L1-GUESS) | HL-ACT | embodied |
| i10 | LS11 buttons | he-ins-make-do | en-clap | button clap; button wave; button look | button clap | button wave (M-ENG-SEM); button look (M-ENG-L1-GUESS) | HL-ACT | embodied |
| i11 **C** | LS11 buttons | he-ins-make-do | en-sit-down | button sit-down; button stand-up; button jump | button sit-down | button stand-up (M-ENG-SEM); button jump (M-ENG-L1-GUESS) | HL-ACT | embodied |
| i12 **C** | LS11 buttons | he-ins-make-do | en-wave | button wave; button clap; button sit-down | button wave | button clap (M-ENG-SEM); button sit-down (M-ENG-L1-GUESS) | HL-ACT | embodied |
| e01 *not scored* | LS11 embodied | he-ins-do-too | en-stand-up, then en-sit-down | "done" | - | - | - | embodied |
| e02 *not scored* | LS11 embodied | he-ins-do-too | en-jump, en-stop | "done" | - | - | - | embodied |

- e01: Self-report; never counted alone.
- e02: Self-report; never counted alone.

### ENG-A-03 Four colors
Set (each a `variantGroup`): red, blue, yellow, green.

| Item | Template | Hebrew frame | English prompt | Options | Right | Distractors (tag) | Hints | Rep. |
|---|---|---|---|---|---|---|---|---|
| i01 **P** | LS01 tap | he-ins-listen-tap | en-red | pic.balloon-red; pic.balloon-blue; pic.balloon-yellow | pic.balloon-red | pic.balloon-blue (M-ENG-SEM); pic.balloon-yellow (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i02 | LS01 tap | he-ins-listen-tap | en-blue | pic.balloon-blue; pic.balloon-green; pic.balloon-red | pic.balloon-blue | pic.balloon-green (M-ENG-SEM); pic.balloon-red (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i03 | LS01 tap | he-ins-listen-tap | en-yellow | pic.balloon-yellow; pic.balloon-red; pic.balloon-blue | pic.balloon-yellow | pic.balloon-red (M-ENG-SEM); pic.balloon-blue (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i04 | LS01 tap | he-ins-listen-tap | en-green | pic.balloon-green; pic.balloon-yellow; pic.balloon-blue | pic.balloon-green | pic.balloon-yellow (M-ENG-SEM); pic.balloon-blue (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i05 | LS01 tap | he-ins-listen-tap | en-red | pic.boat-red; pic.boat-yellow; pic.boat-blue | pic.boat-red | pic.boat-yellow (M-ENG-SEM); pic.boat-blue (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i06 | LS01 tap | he-ins-listen-tap | en-blue | pic.boat-blue; pic.boat-red; pic.boat-green | pic.boat-blue | pic.boat-red (M-ENG-SEM); pic.boat-green (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i07 **C** | LS01 tap | he-ins-listen-tap | en-yellow | pic.boat-yellow; pic.boat-blue; pic.boat-red | pic.boat-yellow | pic.boat-blue (M-ENG-SEM); pic.boat-red (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i08 **C** | LS01 tap | he-ins-listen-tap | en-green | pic.boat-green; pic.boat-blue; pic.boat-yellow | pic.boat-green | pic.boat-blue (M-ENG-SEM); pic.boat-yellow (M-ENG-L1-GUESS) | HL-PIC | pictorial |

### ENG-A-04 Numbers 1 to 5
Set (each a `variantGroup`): one, two, three, four, five.

| Item | Template | Hebrew frame | English prompt | Options | Right | Distractors (tag) | Hints | Rep. |
|---|---|---|---|---|---|---|---|---|
| i01 | LS01 tap | he-ins-listen-tap | en-one | pic.set-ducks-1; pic.set-ducks-2; pic.set-ducks-3 | pic.set-ducks-1 | pic.set-ducks-2 (M-ENG-SEM); pic.set-ducks-3 (M-ENG-SEM) | HL-SET | pictorial |
| i02 | LS01 tap | he-ins-listen-tap | en-two | pic.set-balls-2; pic.set-balls-1; pic.set-balls-3 | pic.set-balls-2 | pic.set-balls-1 (M-ENG-SEM); pic.set-balls-3 (M-ENG-SEM) | HL-SET | pictorial |
| i03 | LS01 tap | he-ins-listen-tap | en-three | pic.set-ducks-3; pic.set-ducks-2; pic.set-ducks-4 | pic.set-ducks-3 | pic.set-ducks-2 (M-ENG-SEM); pic.set-ducks-4 (M-ENG-SEM) | HL-SET | pictorial |
| i04 | LS01 tap | he-ins-listen-tap | en-four | pic.set-balls-4; pic.set-balls-3; pic.set-balls-5 | pic.set-balls-4 | pic.set-balls-3 (M-ENG-SEM); pic.set-balls-5 (M-ENG-SEM) | HL-SET | pictorial |
| i05 | LS01 tap | he-ins-listen-tap | en-five | pic.set-ducks-5; pic.set-ducks-3; pic.set-ducks-4 | pic.set-ducks-5 | pic.set-ducks-3 (M-ENG-SEM); pic.set-ducks-4 (M-ENG-SEM) | HL-SET | pictorial |
| i06 **C** | T02 count, then LS01 sound options | he-ins-count, then he-ins-how-many | pic.set-ducks-3: counting en-one … en-three, a clip per tap (practice); then the buttons | button en-three; button en-two; button en-four | button en-three | button en-two (M-ENG-SEM); button en-four (M-ENG-SEM) | HL-COUNT | concrete |
| i07 **C** | T02 count, then LS01 sound options | he-ins-count, then he-ins-how-many | pic.set-balls-5: counting en-one … en-five, a clip per tap (practice); then the buttons | button en-five; button en-four; button en-three | button en-five | button en-four (M-ENG-SEM); button en-three (M-ENG-SEM) | HL-COUNT | concrete |
| i08 **P** | LS01 tap | he-ins-listen-tap | en-four | pic.set-ducks-4; pic.set-ducks-5; pic.set-ducks-3 | pic.set-ducks-4 | pic.set-ducks-5 (M-ENG-SEM); pic.set-ducks-3 (M-ENG-SEM) | HL-SET | pictorial |
| p01 *not scored* | LS10 personal (age) | he-ins-personal | en-im-five-how-old | pic.cards-age (3 to 9, each card plays en-three … en-nine); voice (if on); pass | - | - | - | story |

- i06: The counting taps are practice, never scored (frame §2.2): a skipped or double-tapped duck gets T02's own help (the duck lights and the count starts again) and no tag, since a counting error is maths, not English. The scored step is "how many?": three sound buttons with no picture (LS01 c), each plays its number word on a tap; the child taps the one that says how many.
- i07: The counting taps are practice, never scored (frame §2.2): a skipped or double-tapped ball gets T02's own help (the ball lights and the count starts again) and no tag, since a counting error is maths, not English. The scored step is "how many?": three sound buttons with no picture (LS01 c), each plays its number word on a tap; the child taps the one that says how many.
- p01: Pip answers first. Reply: the number word clip the child chose ("Four!"), then en-wow; on pass en-thats-ok. Never scored, stored or sent; response empty.

### ENG-A-05 Eight animals
Set (each a `variantGroup`): cat, dog, fish, bird, cow, duck, pig, frog.

| Item | Template | Hebrew frame | English prompt | Options | Right | Distractors (tag) | Hints | Rep. |
|---|---|---|---|---|---|---|---|---|
| i01 | LS01 tap | he-ins-listen-tap | en-cat | pic.cat; pic.dog; pic.pig | pic.cat | pic.dog (M-ENG-SEM); pic.pig (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i02 | LS01 tap | he-ins-listen-tap | en-dog | pic.dog; pic.cat; pic.cow | pic.dog | pic.cat (M-ENG-SEM); pic.cow (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i03 | LS01 tap | he-ins-listen-tap | en-fish | pic.fish; pic.frog; pic.bird | pic.fish | pic.frog (M-ENG-SEM); pic.bird (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i04 | LS01 tap | he-ins-listen-tap | en-bird | pic.bird; pic.duck; pic.cat | pic.bird | pic.duck (M-ENG-SEM); pic.cat (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i05 **P** | LS01 tap | he-ins-listen-tap | en-cow | pic.cow; pic.pig; pic.fish | pic.cow | pic.pig (M-ENG-SEM); pic.fish (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i06 | LS01 tap | he-ins-listen-tap | en-duck | pic.duck; pic.bird; pic.dog | pic.duck | pic.bird (M-ENG-SEM); pic.dog (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i07 | LS01 tap | he-ins-listen-tap | en-pig | pic.pig; pic.cow; pic.frog | pic.pig | pic.cow (M-ENG-SEM); pic.frog (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i08 | LS01 tap | he-ins-listen-tap | en-frog | pic.frog; pic.fish; pic.duck | pic.frog | pic.fish (M-ENG-SEM); pic.duck (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| m01 **C** | LS01 pairs | he-ins-pairs | (each card plays its word) | pic.cat / pic.cat-2; pic.dog / pic.dog-2; pic.cow / pic.cow-2 | 3 pairs | cat with dog (M-ENG-SEM); cow with dog (M-ENG-L1-GUESS) | HL-PAIRS | pictorial |
| m02 **C** | LS01 pairs | he-ins-pairs | (each card plays its word) | pic.duck / pic.duck-2; pic.bird / pic.bird-2; pic.frog / pic.frog-2 | 3 pairs | duck with bird (M-ENG-SEM); frog with duck (M-ENG-L1-GUESS) | HL-PAIRS | pictorial |

- m01: Two rows of three cards; each match is a choice among three (Band A). Each card says its word on a tap; a wrong pairing hears both words.
- m02: as m01

### ENG-A-06 Body words
Set (each a `variantGroup`): head, eyes, ears, nose, mouth, hands, feet, tummy.

| Item | Template | Hebrew frame | English prompt | Options | Right | Distractors (tag) | Hints | Rep. |
|---|---|---|---|---|---|---|---|---|
| i01 | LS11 hotspot | he-ins-touch-body | en-touch-head | pic.body-mika: tap areas head, tummy, feet (the other parts inactive) | head | tummy (M-ENG-SEM); feet (M-ENG-L1-GUESS) | HL-BODY | embodied |
| i02 | LS11 hotspot | he-ins-touch-body | en-touch-eyes | pic.body-mika: tap areas eyes, ears, mouth (the other parts inactive) | eyes | ears (M-ENG-SEM); mouth (M-ENG-L1-GUESS) | HL-BODY | embodied |
| i03 | LS11 hotspot | he-ins-touch-body | en-touch-ears | pic.body-mika: tap areas ears, eyes, nose (the other parts inactive) | ears | eyes (M-ENG-SEM); nose (M-ENG-L1-GUESS) | HL-BODY | embodied |
| i04 **P** | LS01 tap | he-ins-listen-tap | en-nose | pic.body-nose; pic.body-eyes; pic.body-mouth | pic.body-nose | pic.body-eyes (M-ENG-SEM); pic.body-mouth (M-ENG-SEM) | HL-PIC | pictorial |
| i05 | LS11 hotspot | he-ins-touch-body | en-touch-mouth | pic.body-mika: tap areas mouth, nose, head (the other parts inactive) | mouth | nose (M-ENG-SEM); head (M-ENG-L1-GUESS) | HL-BODY | embodied |
| i06 | LS11 hotspot | he-ins-touch-body | en-clap-your-hands | pic.body-mika: tap areas hands, feet, eyes (the other parts inactive) | hands | feet (M-ENG-SEM); eyes (M-ENG-L1-GUESS) | HL-BODY | embodied |
| i07 | LS11 hotspot | he-ins-touch-body | en-touch-feet | pic.body-mika: tap areas feet, hands, head (the other parts inactive) | feet | hands (M-ENG-SEM); head (M-ENG-L1-GUESS) | HL-BODY | embodied |
| i08 | LS11 hotspot | he-ins-touch-body | en-touch-tummy | pic.body-mika: tap areas tummy, head, hands (the other parts inactive) | tummy | head (M-ENG-SEM); hands (M-ENG-L1-GUESS) | HL-BODY | embodied |
| i09 | LS01 tap | he-ins-listen-tap | en-nose | pic.body-nose; pic.body-mouth; pic.body-ears | pic.body-nose | pic.body-mouth (M-ENG-SEM); pic.body-ears (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i10 | LS01 tap | he-ins-listen-tap | en-ears | pic.body-ears; pic.body-eyes; pic.body-nose | pic.body-ears | pic.body-eyes (M-ENG-SEM); pic.body-nose (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i11 **C** | LS01 tap | he-ins-listen-tap | en-feet | pic.body-feet; pic.body-hands; pic.body-head | pic.body-feet | pic.body-hands (M-ENG-SEM); pic.body-head (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i12 **C** | LS01 tap | he-ins-listen-tap | en-tummy | pic.body-tummy; pic.body-head; pic.body-hands | pic.body-tummy | pic.body-head (M-ENG-SEM); pic.body-hands (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| e01 *not scored* | LS11 embodied | he-ins-do-too | en-touch-head, en-touch-nose, en-touch-feet | "done" | - | - | - | embodied |

- i04: Probe (strand O level 3): the nose close-up among two other face close-ups; a picture tap, not a hotspot (frame §2.3, LS13: a probe is LS01, LS03 or LS06; QA-L4-7, 2026-11-04). It tests the same thing as the hotspot did (hearing "nose" and finding it) with the drawn close-ups `body-nose`, `body-eyes`, `body-mouth`, and with different options from i09 (nose, mouth, ears) so the two are not one item twice. The nose stays a hotspot distractor in i03 and i05 (QA-L4-1 decides its tap area).
- e01: Self-report; never counted alone.

### ENG-A-07 Family words
Set (each a `variantGroup`): mom, dad, baby, brother, sister, grandma, grandpa.

| Item | Template | Hebrew frame | English prompt | Options | Right | Distractors (tag) | Hints | Rep. |
|---|---|---|---|---|---|---|---|---|
| i01 | LS01 tap | he-ins-listen-tap | en-mom | pic.fam-mom; pic.fam-grandma; pic.fam-baby | pic.fam-mom | pic.fam-grandma (M-ENG-SEM); pic.fam-baby (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i02 | LS01 tap | he-ins-listen-tap | en-dad | pic.fam-dad; pic.fam-grandpa; pic.fam-sister | pic.fam-dad | pic.fam-grandpa (M-ENG-SEM); pic.fam-sister (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i03 | LS01 tap | he-ins-listen-tap | en-baby | pic.fam-baby; pic.fam-brother; pic.fam-grandpa | pic.fam-baby | pic.fam-brother (M-ENG-SEM); pic.fam-grandpa (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i04 | LS01 tap | he-ins-listen-tap | en-brother | pic.fam-brother; pic.fam-sister; pic.fam-mom | pic.fam-brother | pic.fam-sister (M-ENG-SEM); pic.fam-mom (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i05 | LS01 tap | he-ins-listen-tap | en-sister | pic.fam-sister; pic.fam-brother; pic.fam-dad | pic.fam-sister | pic.fam-brother (M-ENG-SEM); pic.fam-dad (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i06 | LS01 tap | he-ins-listen-tap | en-grandma | pic.fam-grandma; pic.fam-mom; pic.fam-brother | pic.fam-grandma | pic.fam-mom (M-ENG-SEM); pic.fam-brother (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i07 **C** | LS01 tap | he-ins-listen-tap | en-grandpa | pic.fam-grandpa; pic.fam-dad; pic.fam-baby | pic.fam-grandpa | pic.fam-dad (M-ENG-SEM); pic.fam-baby (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i08 **C** | LS01 tap | he-ins-listen-tap | en-sister (on pic.fam-pip, the whole family) | pic.fam-sister; pic.fam-mom; pic.fam-baby | pic.fam-sister | pic.fam-mom (M-ENG-SEM); pic.fam-baby (M-ENG-L1-GUESS) | HL-PIC | story |
| p01 *not scored* | LS10 personal (family) | he-ins-personal | en-this-is-my-family, en-who-in-family | 8 cards (any number, each plays its word): mom, dad, brother, sister, baby, grandma, grandpa, someone else; pass | - | - | - | story |

- i08: The whole family picture first, then the three cards.
- p01: Many shapes of family; no default and no follow-up question; any number of cards (two moms, one parent, only grandparents all fit), "someone else" holds everyone else (cousins, pets, a carer). The pass is always on screen. Reply: en-nice; on pass en-thats-ok. Response empty.
- p01, why 8 cards (QA-L4-10, 2026-11-04; was 10 with cousin and pet): the schema takes 8, and one turn is better than two: a second family turn would be a follow-up question (frame §5.2.3 has none) and would double the time spent on a personal question. The 8 are the 7 taught family words (so every card is language practice the child has met) and "someone else", which keeps every family shape passable: nothing a child's family has is missing, and the pass is always there. Cousins and pets go into "someone else" (a pet is not a family word of this set; `cat` and `dog` are taught in A-05). Order: mom, dad, brother, sister, then baby, grandma, grandpa, someone else; the phone shows the first 4 and the rest scroll, which is fine because no card is a default and the pass does not scroll.

### ENG-A-08 Food words
Set (each a `variantGroup`): apple, banana, milk, water, bread, egg, cake, juice.

| Item | Template | Hebrew frame | English prompt | Options | Right | Distractors (tag) | Hints | Rep. |
|---|---|---|---|---|---|---|---|---|
| i01 | LS01 tap | he-ins-listen-tap | en-apple | pic.apple; pic.banana; pic.bread | pic.apple | pic.banana (M-ENG-SEM); pic.bread (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i02 **P** | LS01 tap | he-ins-listen-tap | en-banana | pic.banana; pic.apple; pic.milk | pic.banana | pic.apple (M-ENG-SEM); pic.milk (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i03 | LS01 tap | he-ins-listen-tap | en-milk | pic.milk; pic.water; pic.cake | pic.milk | pic.water (M-ENG-SEM); pic.cake (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i04 | LS01 tap | he-ins-listen-tap | en-water | pic.water; pic.juice; pic.egg | pic.water | pic.juice (M-ENG-SEM); pic.egg (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i05 | LS01 tap | he-ins-listen-tap | en-bread | pic.bread; pic.cake; pic.juice | pic.bread | pic.cake (M-ENG-SEM); pic.juice (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i06 | LS01 tap | he-ins-listen-tap | en-egg | pic.egg; pic.bread; pic.apple | pic.egg | pic.bread (M-ENG-SEM); pic.apple (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i07 | LS01 tap | he-ins-listen-tap | en-cake | pic.cake; pic.bread; pic.water | pic.cake | pic.bread (M-ENG-SEM); pic.water (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i08 | LS01 tap | he-ins-listen-tap | en-juice | pic.juice; pic.milk; pic.banana | pic.juice | pic.milk (M-ENG-SEM); pic.banana (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i09 | LS11 drag | he-ins-give | en-give-apple | pic.apple; pic.banana; pic.bread | pic.apple to Pip | pic.banana (M-ENG-SEM); pic.bread (M-ENG-L1-GUESS) | HL-PIC | embodied |
| i10 | LS11 drag | he-ins-give | en-give-milk | pic.milk; pic.water; pic.cake | pic.milk to Pip | pic.water (M-ENG-SEM); pic.cake (M-ENG-L1-GUESS) | HL-PIC | embodied |
| i11 **C** | LS11 drag | he-ins-give | en-give-bread | pic.bread; pic.cake; pic.juice | pic.bread to Pip | pic.cake (M-ENG-SEM); pic.juice (M-ENG-L1-GUESS) | HL-PIC | embodied |
| i12 **C** | LS11 drag | he-ins-give | en-give-juice | pic.juice; pic.milk; pic.banana | pic.juice to Pip | pic.milk (M-ENG-SEM); pic.banana (M-ENG-L1-GUESS) | HL-PIC | embodied |
| p01 *not scored* | LS10 personal (likes) | he-ins-personal | en-i-like-bananas | 6 food cards (each plays its word); voice (if on); pass | - | - | - | story |

- p01: Reply: the food word the child chose ("Apple!"), then en-yum; on pass en-thats-ok. Never used to choose content. Response empty.

### ENG-A-09 Toys and things
Set (each a `variantGroup`): ball, car, teddy, book, bike, boat, drum, kite.

| Item | Template | Hebrew frame | English prompt | Options | Right | Distractors (tag) | Hints | Rep. |
|---|---|---|---|---|---|---|---|---|
| i01 | LS01 tap | he-ins-listen-tap | en-ball | pic.ball; pic.drum; pic.book | pic.ball | pic.drum (M-ENG-SEM); pic.book (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i02 | LS01 tap | he-ins-listen-tap | en-car | pic.car; pic.bike; pic.teddy | pic.car | pic.bike (M-ENG-SEM); pic.teddy (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i03 | LS01 tap | he-ins-listen-tap | en-teddy | pic.teddy; pic.ball; pic.kite | pic.teddy | pic.ball (M-ENG-SEM); pic.kite (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i04 | LS01 tap | he-ins-listen-tap | en-book | pic.book; pic.teddy; pic.boat | pic.book | pic.teddy (M-ENG-SEM); pic.boat (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i05 | LS01 tap | he-ins-listen-tap | en-bike | pic.bike; pic.car; pic.drum | pic.bike | pic.car (M-ENG-SEM); pic.drum (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i06 | LS01 tap | he-ins-listen-tap | en-boat | pic.boat; pic.car; pic.ball | pic.boat | pic.car (M-ENG-SEM); pic.ball (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i07 | LS01 tap | he-ins-listen-tap | en-drum | pic.drum; pic.ball; pic.bike | pic.drum | pic.ball (M-ENG-SEM); pic.bike (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i08 **P** | LS01 tap | he-ins-listen-tap | en-kite | pic.kite; pic.boat; pic.car | pic.kite | pic.boat (M-ENG-SEM); pic.car (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| m01 **C** | LS01 pairs | he-ins-pairs | (each card plays its word) | pic.ball / pic.ball-2; pic.drum / pic.drum-2; pic.kite / pic.kite-2 | 3 pairs | ball with drum (M-ENG-SEM); kite with ball (M-ENG-L1-GUESS) | HL-PAIRS | pictorial |
| m02 **C** | LS01 pairs | he-ins-pairs | (each card plays its word) | pic.car / pic.car-2; pic.bike / pic.bike-2; pic.boat / pic.boat-2 | 3 pairs | car with bike (M-ENG-SEM); boat with car (M-ENG-L1-GUESS) | HL-PAIRS | pictorial |

- m01: as A-05 m01
- m02: as A-05 m01

### ENG-A-10 big/small, hot/cold, happy/sad
Set (each a `variantGroup`): big, small, hot, cold, happy, sad.

| Item | Template | Hebrew frame | English prompt | Options | Right | Distractors (tag) | Hints | Rep. |
|---|---|---|---|---|---|---|---|---|
| i01 | LS01 tap | he-ins-listen-tap | en-big | big dog in pic.dog-big; small dog in pic.dog-big | big dog | small dog (M-ENG-SEM) | HL-PIC | pictorial |
| i02 | LS01 tap | he-ins-listen-tap | en-small | small dog in pic.dog-big; big dog in pic.dog-big | small dog | big dog (M-ENG-SEM) | HL-PIC | pictorial |
| i03 | LS01 tap | he-ins-listen-tap | en-big | big ball in pic.ball-pair; small ball in pic.ball-pair | big ball | small ball (M-ENG-SEM) | HL-PIC | pictorial |
| i04 | LS01 tap | he-ins-listen-tap | en-small | small ball in pic.ball-pair; big ball in pic.ball-pair | small ball | big ball (M-ENG-SEM) | HL-PIC | pictorial |
| i05 | LS01 tap | he-ins-listen-tap | en-hot | pic.cup-hot; pic.cup-cold; pic.mika-sad | pic.cup-hot | pic.cup-cold (M-ENG-SEM); pic.mika-sad (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i06 | LS01 tap | he-ins-listen-tap | en-cold | pic.mika-cold; pic.mika-hot; pic.pip-happy | pic.mika-cold | pic.mika-hot (M-ENG-SEM); pic.pip-happy (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i07 | LS01 tap | he-ins-listen-tap | en-happy | pic.mika-happy; pic.mika-sad; pic.cup-hot | pic.mika-happy | pic.mika-sad (M-ENG-SEM); pic.cup-hot (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i08 | LS01 tap | he-ins-listen-tap | en-sad | pic.pip-sad; pic.pip-happy; pic.cup-cold | pic.pip-sad | pic.pip-happy (M-ENG-SEM); pic.cup-cold (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i09 **C** | LS01 tap | he-ins-listen-tap | en-hot | pic.mika-hot; pic.mika-cold; pic.cup-cold | pic.mika-hot | pic.mika-cold (M-ENG-SEM); pic.cup-cold (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i10 **C** | LS01 tap | he-ins-listen-tap | en-cold | pic.cup-cold; pic.cup-hot; pic.mika-happy | pic.cup-cold | pic.cup-hot (M-ENG-SEM); pic.mika-happy (M-ENG-L1-GUESS) | HL-PIC | pictorial |

- i09: pic.cup-cold is cold, not hot: still one right answer.

### ENG-A-11 "What's this?" "It's a ___."
Set (each a `variantGroup`): ball, car, book, kite, duck, apple, egg.

| Item | Template | Hebrew frame | English prompt | Options | Right | Distractors (tag) | Hints | Rep. |
|---|---|---|---|---|---|---|---|---|
| i01 | LS01 tap | he-ins-whats-this | en-whats-this, en-its-ball | pic.ball; pic.drum; pic.book | pic.ball | pic.drum (M-ENG-SEM); pic.book (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i02 | LS01 tap | he-ins-whats-this | en-whats-this, en-its-book | pic.book; pic.teddy; pic.car | pic.book | pic.teddy (M-ENG-SEM); pic.car (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i03 | LS01 tap | he-ins-whats-this | en-whats-this, en-its-kite | pic.kite; pic.bike; pic.ball | pic.kite | pic.bike (M-ENG-SEM); pic.ball (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i04 **P** | LS01 tap | he-ins-whats-this | en-whats-this, en-its-duck | pic.duck; pic.bird; pic.cat | pic.duck | pic.bird (M-ENG-SEM); pic.cat (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i05 | LS01 tap | he-ins-whats-this | en-whats-this, en-its-apple | pic.apple; pic.banana; pic.car | pic.apple | pic.banana (M-ENG-SEM); pic.car (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i06 | LS01 tap | he-ins-whats-this | en-whats-this, en-its-egg | pic.egg; pic.bread; pic.kite | pic.egg | pic.bread (M-ENG-SEM); pic.kite (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i07 | LS10 bubble | he-ins-bubble | en-whats-this (Pip shows pic.car in pic.pip-holds) | bubble: en-its-car; bubble: en-its-boat; bubble: en-hello | bubble: en-its-car | bubble: en-its-boat (M-ENG-SEM); bubble: en-hello (M-ENG-L1-GUESS) | HL-BUBBLE | story |
| i08 | LS10 bubble | he-ins-bubble | en-whats-this (Pip shows pic.book in pic.pip-holds) | bubble: en-its-book; bubble: en-its-ball; bubble: en-hello | bubble: en-its-book | bubble: en-its-ball (M-ENG-SEM); bubble: en-hello (M-ENG-L1-GUESS) | HL-BUBBLE | story |
| i09 **C** | LS10 bubble | he-ins-bubble | en-whats-this (Pip shows pic.duck in pic.pip-holds) | bubble: en-its-duck; bubble: en-its-frog; bubble: en-hello | bubble: en-its-duck | bubble: en-its-frog (M-ENG-SEM); bubble: en-hello (M-ENG-L1-GUESS) | HL-BUBBLE | story |
| i10 **C** | LS10 bubble | he-ins-bubble | en-whats-this (Pip shows pic.egg in pic.pip-holds) | bubble: en-its-egg; bubble: en-its-apple; bubble: en-hello | bubble: en-its-egg | bubble: en-its-apple (M-ENG-SEM); bubble: en-hello (M-ENG-L1-GUESS) | HL-BUBBLE | story |

### ENG-A-12 Say a word (LS09)
Set (each a `variantGroup`): cat, dog, fish, duck, red, blue, apple, ball.

| Item | Template | Hebrew frame | English prompt | Options | Right | Distractors (tag) | Hints | Rep. |
|---|---|---|---|---|---|---|---|---|
| i01 | LS09 say + LS01 tap | he-ins-say / he-ins-mic or he-ins-said-it, then he-ins-find-said | en-cat (twice, with a pause) | pic.cat; pic.dog; pic.pig | pic.cat | pic.dog (M-ENG-SEM); pic.pig (M-ENG-L1-GUESS) | HL-PIC (the tap) | embodied + pictorial |
| i02 | LS09 say + LS01 tap | he-ins-say / he-ins-mic or he-ins-said-it, then he-ins-find-said | en-dog (twice, with a pause) | pic.dog; pic.cat; pic.cow | pic.dog | pic.cat (M-ENG-SEM); pic.cow (M-ENG-L1-GUESS) | HL-PIC (the tap) | embodied + pictorial |
| i03 | LS09 say + LS01 tap | he-ins-say / he-ins-mic or he-ins-said-it, then he-ins-find-said | en-fish (twice, with a pause) | pic.fish; pic.frog; pic.bird | pic.fish | pic.frog (M-ENG-SEM); pic.bird (M-ENG-L1-GUESS) | HL-PIC (the tap) | embodied + pictorial |
| i04 | LS09 say + LS01 tap | he-ins-say / he-ins-mic or he-ins-said-it, then he-ins-find-said | en-duck (twice, with a pause) | pic.duck; pic.bird; pic.dog | pic.duck | pic.bird (M-ENG-SEM); pic.dog (M-ENG-L1-GUESS) | HL-PIC (the tap) | embodied + pictorial |
| i05 | LS09 say + LS01 tap | he-ins-say / he-ins-mic or he-ins-said-it, then he-ins-find-said | en-red (twice, with a pause) | pic.balloon-red; pic.balloon-blue; pic.balloon-yellow | pic.balloon-red | pic.balloon-blue (M-ENG-SEM); pic.balloon-yellow (M-ENG-L1-GUESS) | HL-PIC (the tap) | embodied + pictorial |
| i06 | LS09 say + LS01 tap | he-ins-say / he-ins-mic or he-ins-said-it, then he-ins-find-said | en-blue (twice, with a pause) | pic.balloon-blue; pic.balloon-green; pic.balloon-red | pic.balloon-blue | pic.balloon-green (M-ENG-SEM); pic.balloon-red (M-ENG-L1-GUESS) | HL-PIC (the tap) | embodied + pictorial |
| i07 **C** | LS09 say + LS01 tap | he-ins-say / he-ins-mic or he-ins-said-it, then he-ins-find-said | en-apple (twice, with a pause) | pic.apple; pic.banana; pic.bread | pic.apple | pic.banana (M-ENG-SEM); pic.bread (M-ENG-L1-GUESS) | HL-PIC (the tap) | embodied + pictorial |
| i08 **C** | LS09 say + LS01 tap | he-ins-say / he-ins-mic or he-ins-said-it, then he-ins-find-said | en-ball (twice, with a pause) | pic.ball; pic.drum; pic.book | pic.ball | pic.drum (M-ENG-SEM); pic.book (M-ENG-L1-GUESS) | HL-PIC (the tap) | embodied + pictorial |

- i01: Expected set: cat, a cat. Foils: cut, cap, dog, pig. Confident → he-fb-heard + en-cat; unsure → he-fb-together + en-cat. The tap counts for ENG-A-12.
- i02: Expected set: dog, a dog. Foils: duck, dig, cat, cow. Confident → he-fb-heard + en-dog; unsure → he-fb-together + en-dog. The tap counts for ENG-A-12.
- i03: Expected set: fish, a fish. Foils: dish, feet, frog, bird. Confident → he-fb-heard + en-fish; unsure → he-fb-together + en-fish. The tap counts for ENG-A-12.
- i04: Expected set: duck, a duck. Foils: dock, deck, bird, dog. Confident → he-fb-heard + en-duck; unsure → he-fb-together + en-duck. The tap counts for ENG-A-12.
- i05: Expected set: red. Foils: bed, led, blue, yellow. Confident → he-fb-heard + en-red; unsure → he-fb-together + en-red. The tap counts for ENG-A-12.
- i06: Expected set: blue. Foils: glue, blow, green, red. Confident → he-fb-heard + en-blue; unsure → he-fb-together + en-blue. The tap counts for ENG-A-12.
- i07: Expected set: apple, an apple. Foils: able, happy, banana, bread. Confident → he-fb-heard + en-apple; unsure → he-fb-together + en-apple. The tap counts for ENG-A-12.
- i08: Expected set: ball, a ball. Foils: bowl, doll, drum, book. Confident → he-fb-heard + en-ball; unsure → he-fb-together + en-ball. The tap counts for ENG-A-12.

### ENG-A-13 Chants
Set (each a `variantGroup`): Clap!, Wave!, Jump!, nose, five.
- **Hello chant (ENG-A-01, A-13; the hello routine)** (`en-ch-hello-1` … `-4`, spoken on a steady beat, original): Hello, hello! / Hello to you! / Clap, clap, clap! / Hello to you!
- **Goodbye chant (ENG-A-01, A-13; the goodbye routine)** (`en-ch-bye-1` … `-4`, spoken on a steady beat, original): Goodbye, goodbye! / Wave, wave, wave! / Bye-bye, bye-bye! / Goodbye to you!
- **Move chant (ENG-A-02, A-13)** (`en-ch-move-1` … `-4`, spoken on a steady beat, original): Stand up! Clap, clap! / Jump, jump, jump! / Look! Listen! / Sit down. Stop!
- **Body chant, call and echo (ENG-A-06, A-13)** (`en-ch-body-1` … `-4`, spoken on a steady beat, original): Touch your head! Head! / Touch your nose! Nose! / Touch your mouth! Mouth! / Touch your feet! Feet!
- **Counting chant (ENG-A-04, A-13)** (`en-ch-count-1` … `-4`, spoken on a steady beat, original): One, two, three, four, five! / Clap with me, clap with me! / One, two, three, four, five! / Jump with me, jump with me!

| Item | Template | Hebrew frame | English prompt | Options | Right | Distractors (tag) | Hints | Rep. |
|---|---|---|---|---|---|---|---|---|
| c01 *not scored* | LS12 chant | he-ins-chant | en-ch-hello-1 … 4 | - | - | - | - | story |
| i01 **C** | LS01 tap | he-ins-listen-tap | en-clap | pic.act-clap; pic.act-wave; pic.act-sitdown | pic.act-clap | pic.act-wave (M-ENG-SEM); pic.act-sitdown (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| c02 *not scored* | LS12 chant | he-ins-chant | en-ch-bye-1 … 4 | - | - | - | - | story |
| i02 **C** | LS01 tap | he-ins-listen-tap | en-wave | pic.act-wave; pic.act-clap; pic.act-look | pic.act-wave | pic.act-clap (M-ENG-SEM); pic.act-look (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| c03 *not scored* | LS12 chant | he-ins-chant | en-ch-move-1 … 4 | - | - | - | - | story |
| i03 **C** | LS01 tap | he-ins-listen-tap | en-jump | pic.act-jump; pic.act-stop; pic.act-listen | pic.act-jump | pic.act-stop (M-ENG-SEM); pic.act-listen (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| c04 *not scored* | LS12 chant | he-ins-chant | en-ch-body-1 … 4 | - | - | - | - | story |
| i04 **C** | LS01 tap | he-ins-listen-tap | en-nose | pic.body-nose; pic.body-mouth; pic.body-feet | pic.body-nose | pic.body-mouth (M-ENG-SEM); pic.body-feet (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| c05 *not scored* | LS12 chant | he-ins-chant | en-ch-count-1 … 4 | - | - | - | - | story |
| i05 **C** | LS01 tap | he-ins-listen-tap | en-five | pic.set-ducks-5; pic.set-ducks-4; pic.set-ducks-3 | pic.set-ducks-5 | pic.set-ducks-4 (M-ENG-SEM); pic.set-ducks-3 (M-ENG-SEM) | HL-PIC | pictorial |

- c01: Pictures light on the key words; joining in is practice.
- i01: The understanding check after the chant.
- c02: Pictures light on the key words; joining in is practice.
- i02: The understanding check after the chant.
- c03: Pictures light on the key words; joining in is practice.
- i03: The understanding check after the chant.
- c04: Pictures light on the key words; joining in is practice.
- i04: The understanding check after the chant.
- c05: Pictures light on the key words; joining in is practice.
- i05: The understanding check after the chant.

### ENG-A-14 Beats (syllables)
Set (each a `variantGroup`): cat, duck, milk, apple, teddy, water, banana, elephant.
**Drum items (LS03, free response, frame §2.3):** the drum has no fixed distractors. Its classifier maps one beat more to `M-ENG-SYLL` and one beat fewer to `M-ENG-WEAK-SYLL`, so the distractor column lists only those outcomes; a count off by 2 or more is a retry with no tag and no misconception evidence. Every beat word is voiced with every beat audible (`pronunciation.csv` `check`). **Strips (LS01):** centred on the right count when it is 2 or more, so each distractor is one beat away (banana: 2, 3 or 4 drums).

| Item | Template | Hebrew frame | English prompt | Options | Right | Distractors (tag) | Hints | Rep. |
|---|---|---|---|---|---|---|---|---|
| i01 | LS03 drum | he-ins-drum | en-cat (with pic.cat) | drum taps | 1 beat | 2 beats (M-ENG-SYLL) | HL-DRUM | concrete |
| i02 | LS03 drum | he-ins-drum | en-duck (with pic.duck) | drum taps | 1 beat | 2 beats (M-ENG-SYLL) | HL-DRUM | concrete |
| i03 | LS03 drum | he-ins-drum | en-milk (with pic.milk) | drum taps | 1 beat | 2 beats (M-ENG-SYLL) | HL-DRUM | concrete |
| i04 | LS03 drum | he-ins-drum | en-apple (with pic.apple) | drum taps | 2 beats | 1 beat (M-ENG-WEAK-SYLL); 3 beats (M-ENG-SYLL) | HL-DRUM | concrete |
| i05 | LS03 drum | he-ins-drum | en-teddy (with pic.teddy) | drum taps | 2 beats | 1 beat (M-ENG-WEAK-SYLL); 3 beats (M-ENG-SYLL) | HL-DRUM | concrete |
| i06 | LS03 drum | he-ins-drum | en-water (with pic.water) | drum taps | 2 beats | 1 beat (M-ENG-WEAK-SYLL); 3 beats (M-ENG-SYLL) | HL-DRUM | concrete |
| i07 | LS03 drum | he-ins-drum | en-banana (with pic.banana) | drum taps | 3 beats | 2 beats (M-ENG-WEAK-SYLL); 4 beats (M-ENG-SYLL) | HL-DRUM | concrete |
| i08 | LS03 drum | he-ins-drum | en-elephant (with pic.elephant) | drum taps | 3 beats | 2 beats (M-ENG-WEAK-SYLL); 4 beats (M-ENG-SYLL) | HL-DRUM | concrete |
| i09 | LS01 tap | he-ins-strip | en-dog | pic.drum-strip-1; pic.drum-strip-2; pic.drum-strip-3 | pic.drum-strip-1 | pic.drum-strip-2 (M-ENG-SYLL); pic.drum-strip-3 (M-ENG-SYLL) | HL-DRUM | pictorial |
| i10 | LS01 tap | he-ins-strip | en-tummy | pic.drum-strip-1; pic.drum-strip-2; pic.drum-strip-3 | pic.drum-strip-2 | pic.drum-strip-1 (M-ENG-WEAK-SYLL); pic.drum-strip-3 (M-ENG-SYLL) | HL-DRUM | pictorial |
| i11 **C** | LS01 tap | he-ins-strip | en-banana | pic.drum-strip-2; pic.drum-strip-3; pic.drum-strip-4 | pic.drum-strip-3 | pic.drum-strip-2 (M-ENG-WEAK-SYLL); pic.drum-strip-4 (M-ENG-SYLL) | HL-DRUM | pictorial |
| i12 **C** | LS01 tap | he-ins-strip | en-yellow | pic.drum-strip-1; pic.drum-strip-2; pic.drum-strip-3 | pic.drum-strip-2 | pic.drum-strip-1 (M-ENG-WEAK-SYLL); pic.drum-strip-3 (M-ENG-SYLL) | HL-DRUM | pictorial |

### ENG-A-15 A picture story
Set (each a `variantGroup`): cat, duck, frog, dog, ball, red.
**The story "Bounce, Ball!"** (original; `en-st-bounce-1` … `-6`; repeated line "Bounce, bounce, bounce!"):
1. Look! A red ball. Bounce, bounce, bounce! *(picture: Pip's red ball bounces out of Pip's hands on a path in a garden.)*
2. Hello, cat! Bounce, bounce, bounce! *(picture: The ball bounces past a cat, who looks up.)*
3. Hello, duck! Bounce, bounce, bounce! *(picture: The ball bounces past a duck by a pond (the dialogic pause comes before this line).)*
4. Hello, frog! Bounce, bounce, bounce! *(picture: The ball bounces over a frog on a stone.)*
5. Hello, dog! Stop, ball, stop! *(picture: A dog jumps and catches the ball.)*
6. The dog gives Pip the ball. Thank you, dog! *(picture: The dog brings the ball back to Pip; Pip hugs the dog.)*

| Item | Template | Hebrew frame | English prompt | Options | Right | Distractors (tag) | Hints | Rep. |
|---|---|---|---|---|---|---|---|---|
| s01 *not scored* | LS08 listen + dialogic | he-ins-story | en-st-bounce-1 … 6 on pic.story-bounce-1 … 6 | tap a picture: its word clip (cat, duck, frog, dog, ball) | - | - | - | story |
| d01 | LS08 dialogic pause (LS01 tap) | he-q-who | (before page 3) | pic.duck; pic.cat; pic.frog | pic.duck | pic.cat (M-ENG-STORY-RECALL); pic.frog (M-ENG-SEM) | HL-STORY | story |
| q01 **C** | LS01 tap | he-q-ball-end | (after the story) | pic.dog; pic.cat; pic.frog | pic.dog | pic.cat (M-ENG-STORY-RECALL); pic.frog (M-ENG-STORY-RECALL) | HL-STORY | story |
| q02 | LS01 tap | he-q-ball-which | (after the story) | pic.ball-red; pic.ball-blue; pic.ball-yellow | pic.ball-red | pic.ball-blue (M-ENG-SEM); pic.ball-yellow (M-ENG-L1-GUESS) | HL-STORY | story |
| q03 **C** | LS01 tap | he-q-ball-first | (after the story) | pic.cat; pic.duck; pic.dog | pic.cat | pic.duck (M-ENG-STORY-RECALL); pic.dog (M-ENG-STORY-RECALL) | HL-STORY | story |
| q04 | LS01 tap | he-ins-listen-tap | en-frog (on page 4 shown again) | pic.frog; pic.fish; pic.duck | pic.frog | pic.fish (M-ENG-SEM); pic.duck (M-ENG-STORY-RECALL) | HL-PIC | story |

- s01: The story itself is practice.
- d01: After the child taps, page 3 plays: "Hello, duck!"
- q02: Options play "red", "blue", "yellow" on a tap.

### ENG-A-16 "Is it a ___?" yes or no
Set (each a `variantGroup`): Yes!, No!.

| Item | Template | Hebrew frame | English prompt | Options | Right | Distractors (tag) | Hints | Rep. |
|---|---|---|---|---|---|---|---|---|
| i01 | LS01 tap (thumbs) | he-ins-thumbs | pic.cat shown; en-isit-cat | pic.thumb-up; pic.thumb-down | pic.thumb-up (then en-yes) | pic.thumb-down (M-ENG-YESNO) | HL-YN | pictorial |
| i02 | LS01 tap (thumbs) | he-ins-thumbs | pic.cat shown; en-isit-dog | pic.thumb-up; pic.thumb-down | pic.thumb-down (then en-no) | pic.thumb-up (M-ENG-YESNO) | HL-YN | pictorial |
| i03 | LS01 tap (thumbs) | he-ins-thumbs | pic.duck shown; en-isit-duck | pic.thumb-up; pic.thumb-down | pic.thumb-up (then en-yes) | pic.thumb-down (M-ENG-YESNO) | HL-YN | pictorial |
| i04 **P** | LS01 tap (thumbs) | he-ins-thumbs | pic.car shown; en-isit-ball | pic.thumb-up; pic.thumb-down | pic.thumb-down (then en-no) | pic.thumb-up (M-ENG-YESNO) | HL-YN | pictorial |
| i05 **C** (pair with i06) | LS01 tap (thumbs) | he-ins-thumbs | pic.cake shown; en-isit-cake | pic.thumb-up; pic.thumb-down | pic.thumb-up (then en-yes) | pic.thumb-down (M-ENG-YESNO) | HL-YN | pictorial |
| i06 **C** (pair with i05) | LS01 tap (thumbs) | he-ins-thumbs | pic.egg shown; en-isit-apple | pic.thumb-up; pic.thumb-down | pic.thumb-down (then en-no) | pic.thumb-up (M-ENG-YESNO) | HL-YN | pictorial |
| g01 | LS08 dialogic + LS01 tap | he-ins-box, then he-ins-box-pick | en-whats-in-the-box; en-isit-cat → en-no, en-isit-dog → en-no, en-isit-duck → en-yes | pic.cat; pic.dog; pic.duck | pic.duck | pic.cat (M-ENG-YESNO); pic.dog (M-ENG-YESNO) | HL-YN | story |
| g02 | LS08 dialogic + LS01 tap | he-ins-box, then he-ins-box-pick | en-whats-in-the-box; en-isit-car → en-no, en-isit-ball → en-yes | pic.car; pic.ball; pic.kite | pic.ball | pic.car (M-ENG-YESNO); pic.kite (M-ENG-L1-GUESS) | HL-YN | story |
| g03 | LS08 dialogic + LS01 tap | he-ins-box, then he-ins-box-pick | en-whats-in-the-box; en-isit-apple → en-no, en-isit-cake → en-no, en-isit-egg → en-yes | pic.apple; pic.cake; pic.egg | pic.egg | pic.apple (M-ENG-YESNO); pic.cake (M-ENG-YESNO) | HL-YN | story |
| g04 | LS08 dialogic + LS01 tap | he-ins-box, then he-ins-box-pick | en-whats-in-the-box; en-isit-fish → en-no, en-isit-frog → en-yes | pic.fish; pic.frog; pic.bird | pic.frog | pic.fish (M-ENG-YESNO); pic.bird (M-ENG-L1-GUESS) | HL-YN | story |
| g05 | LS08 dialogic + LS01 tap | he-ins-box, then he-ins-box-pick | en-whats-in-the-box; en-isit-boat → en-yes | pic.boat; pic.drum; pic.bike | pic.boat | pic.drum (M-ENG-L1-GUESS); pic.bike (M-ENG-L1-GUESS) | HL-YN | story |
| g06 **C** | LS08 dialogic + LS01 tap | he-ins-box, then he-ins-box-pick | en-whats-in-the-box; en-isit-pig → en-no, en-isit-cow → en-yes | pic.pig; pic.cow; pic.duck | pic.cow | pic.pig (M-ENG-YESNO); pic.duck (M-ENG-L1-GUESS) | HL-YN | story |

- i05: The understanding check is the balanced pair i05 + i06 (one "yes", one "no"), served together; it passes only if both are right (frame §2.3).
- i06: Checked with i05 as one balanced pair.
- g01: The box stays closed until the child taps; then it opens.
- g02: The box stays closed until the child taps; then it opens.
- g03: The box stays closed until the child taps; then it opens.
- g04: The box stays closed until the child taps; then it opens.
- g05: The box stays closed until the child taps; then it opens.
- g06: The box stays closed until the child taps; then it opens.

### ENG-A-17 "How are you?" for a puppet
Set (each a `variantGroup`): happy, sad, fine.

| Item | Template | Hebrew frame | English prompt | Options | Right | Distractors (tag) | Hints | Rep. |
|---|---|---|---|---|---|---|---|---|
| i01 | LS01 tap | he-ins-face | en-im-happy | pic.pip-happy; pic.pip-sad; pic.pip-cold | pic.pip-happy | pic.pip-sad (M-ENG-SEM); pic.pip-cold (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i02 | LS01 tap | he-ins-face | en-im-sad | pic.pip-sad; pic.pip-happy; pic.pip-cold | pic.pip-sad | pic.pip-happy (M-ENG-SEM); pic.pip-cold (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i03 | LS01 tap | he-ins-face | en-im-fine | pic.mika-fine; pic.mika-sad; pic.mika-cold | pic.mika-fine | pic.mika-sad (M-ENG-SEM); pic.mika-cold (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i04 | LS01 tap | he-ins-face | en-im-sad | pic.mika-sad; pic.mika-fine; pic.mika-cold | pic.mika-sad | pic.mika-fine (M-ENG-SEM); pic.mika-cold (M-ENG-L1-GUESS) | HL-PIC | pictorial |
| i05 | LS10 bubble + LS09 say | he-ins-bubble, then he-ins-say | pic.scene-mika-icecream; Pip asks Mika en-how-are-you | bubble: en-im-sad; bubble: en-im-happy; bubble: en-goodbye | bubble: en-im-sad | bubble: en-im-happy (M-ENG-SEM); bubble: en-goodbye (M-ENG-L1-GUESS) | HL-BUBBLE | story |
| i06 | LS10 bubble + LS09 say | he-ins-bubble, then he-ins-say | pic.scene-mika-present; Pip asks Mika en-how-are-you | bubble: en-im-happy; bubble: en-im-sad; bubble: en-hello | bubble: en-im-happy | bubble: en-im-sad (M-ENG-SEM); bubble: en-hello (M-ENG-L1-GUESS) | HL-BUBBLE | story |
| i07 **C** | LS10 bubble + LS09 say | he-ins-bubble, then he-ins-say | pic.scene-mika-walk; Pip asks Mika en-how-are-you | bubble: en-im-fine; bubble: en-im-sad; bubble: en-goodbye | bubble: en-im-fine | bubble: en-im-sad (M-ENG-SEM); bubble: en-goodbye (M-ENG-L1-GUESS) | HL-BUBBLE | story |
| i08 **C** | LS10 bubble + LS09 say | he-ins-bubble, then he-ins-say | pic.scene-mika-snow; Pip asks Mika en-how-are-you | bubble: en-im-cold; bubble: en-im-happy; bubble: en-hello | bubble: en-im-cold | bubble: en-im-happy (M-ENG-SEM); bubble: en-hello (M-ENG-L1-GUESS) | HL-BUBBLE | story |

- i01: Happy and fine are never options together (one right answer).
- i02: Happy and fine are never options together (one right answer).
- i03: Happy and fine are never options together (one right answer).
- i04: Happy and fine are never options together (one right answer).
- i05: Say step on the chosen bubble: key word "sad"; foils happy, fine. The question is asked of Mika, never of the child.
- i06: Say step on the chosen bubble: key word "happy"; foils sad, fine. The question is asked of Mika, never of the child.
- i07: Say step on the chosen bubble: key word "fine"; foils sad, happy. The question is asked of Mika, never of the child.
- i08: Say step on the chosen bubble: key word "cold"; foils happy, sad. The question is asked of Mika, never of the child.

## 5. Placement probes (strand O, its Band A levels)
Probes are the items marked **P**, served with `purpose: probe`, no hints, warm feedback, no result shown (frame §3.2). Level 1: A-01 i01, A-03 i01. Level 2: A-05 i05 (cow), A-08 i02 (banana), A-09 i08 (kite). Level 3: A-02 i04 (jump), A-04 i08, A-06 i04 (nose). Level 4: A-11 i05 (duck), A-16 i04. The higher levels of strand O (B-01, B-02, B-05, B-06, B-08, B-10) come with the Band B batch. Speech is never a probe.

## 6. Pictures for the design-director
All original, no text, no brands, no franchise look; one consistent style; Pip and Mika drawn once and reused. Pictures for a "same set" must differ only in the feature taught (color, size, number). `-2` marks a second look of the same thing for match pairs.

| Picture | What it must show |
|---|---|
| pic.act-clap | Mika clapping, with motion lines at the hands. The same Mika, size and background in all eight action pictures. |
| pic.act-jump | Mika in the air, both feet off the ground. The same Mika, size and background in all eight action pictures. |
| pic.act-listen | Mika a hand cupped at one ear, eyes closed. The same Mika, size and background in all eight action pictures. |
| pic.act-look | Mika looking far with a hand over the eyes. The same Mika, size and background in all eight action pictures. |
| pic.act-sitdown | Mika sitting down on a chair. The same Mika, size and background in all eight action pictures. |
| pic.act-standup | Mika rising from a chair, arms up. The same Mika, size and background in all eight action pictures. |
| pic.act-stop | Mika stopping after a run, one hand out flat, dust behind. The same Mika, size and background in all eight action pictures. |
| pic.act-wave | Mika waving one hand. The same Mika, size and background in all eight action pictures. |
| pic.apple | a red apple; on its own, no text or brand. |
| pic.ball | a ball; no text or brand. A second look (`-2`) for match pairs. |
| pic.ball-blue | A blue ball, otherwise identical. |
| pic.ball-pair | A big ball and a small ball side by side, same color. |
| pic.ball-red | A red ball (the story ball). |
| pic.ball-yellow | A yellow ball, otherwise identical. |
| pic.balloon-blue | One blue balloon; identical to the other balloons except the color (pure, named hue). |
| pic.balloon-green | One green balloon; identical to the other balloons except the color (pure, named hue). |
| pic.balloon-red | One red balloon; identical to the other balloons except the color (pure, named hue). |
| pic.balloon-yellow | One yellow balloon; identical to the other balloons except the color (pure, named hue). |
| pic.banana | a yellow banana; on its own, no text or brand. |
| pic.bike | a child's bicycle; no text or brand. A second look (`-2`) for match pairs. |
| pic.bird | a small bird on a branch; one animal, whole, side view, no text. A second pose (`-2`) for match pairs. |
| pic.boat | a small boat on water; no text or brand. A second look (`-2`) for match pairs. |
| pic.boat-blue | One blue toy boat; identical to the other boats except the color. |
| pic.boat-green | One green toy boat; identical to the other boats except the color. |
| pic.boat-red | One red toy boat; identical to the other boats except the color. |
| pic.boat-yellow | One yellow toy boat; identical to the other boats except the color. |
| pic.body-ears | A close-up of Mika's ears, clear and friendly, the same style for all eight. |
| pic.body-eyes | A close-up of Mika's eyes, clear and friendly, the same style for all eight. |
| pic.body-feet | A close-up of Mika's feet, clear and friendly, the same style for all eight. |
| pic.body-hands | A close-up of Mika's hands, clear and friendly, the same style for all eight. |
| pic.body-head | A close-up of Mika's head, clear and friendly, the same style for all eight. |
| pic.body-mika | Mika standing, front view, arms a little out, with tap areas on head, eyes, ears, nose, mouth, hands, feet and tummy; in Band A only 3 areas are active in an item, each with a soft glow. |
| pic.body-mouth | A close-up of Mika's mouth, clear and friendly, the same style for all eight. |
| pic.body-nose | A close-up of Mika's nose, clear and friendly, the same style for all eight. |
| pic.body-tummy | A close-up of Mika's tummy, clear and friendly, the same style for all eight. |
| pic.book | a closed picture book; no text or brand. A second look (`-2`) for match pairs. |
| pic.box | A closed gift box with a question mark; it shakes when the voice asks. |
| pic.bread | a loaf of bread; on its own, no text or brand. |
| pic.bubble | A speech bubble that holds a small picture (the bubble's meaning) and plays its English line on a tap. |
| pic.cake | a round cake (no candles); on its own, no text or brand. |
| pic.car | a toy-like car; no text or brand. A second look (`-2`) for match pairs. |
| pic.cards-age | Seven number cards 3 to 9: the numeral and the same number of dots on each. |
| pic.cat | a cat sitting; one animal, whole, side view, no text. A second pose (`-2`) for match pairs. |
| pic.cow | a cow standing in grass; one animal, whole, side view, no text. A second pose (`-2`) for match pairs. |
| pic.cup-cold | A cup with ice cubes and frost. |
| pic.cup-hot | A cup with steam rising. |
| pic.dog | a friendly dog standing; one animal, whole, side view, no text. A second pose (`-2`) for match pairs. |
| pic.dog-big | A big dog next to a small dog (one scene); the big dog is lit for the item "big". |
| pic.drum | a toy drum with sticks; no text or brand. A second look (`-2`) for match pairs. |
| pic.drum-strip-1 | One drum in a row. |
| pic.drum-strip-2 | Two drums in a row. |
| pic.drum-strip-3 | Three drums in a row. |
| pic.drum-strip-4 | Four drums in a row. |
| pic.duck | a duck on water; one animal, whole, side view, no text. A second pose (`-2`) for match pairs. |
| pic.egg | a whole white egg; on its own, no text or brand. |
| pic.elephant | an elephant, whole body; one animal, whole, side view, no text. A second pose (`-2`) for match pairs. |
| pic.fam-baby | Pip's baby sibling, a portrait card cut from one family picture; ages clear at a glance. |
| pic.fam-brother | Pip's big brother (a boy older than Pip), a portrait card cut from one family picture; ages clear at a glance. |
| pic.fam-dad | Pip's dad, a portrait card cut from one family picture; ages clear at a glance. |
| pic.fam-grandma | Pip's grandma, a portrait card cut from one family picture; ages clear at a glance. |
| pic.fam-grandpa | Pip's grandpa, a portrait card cut from one family picture; ages clear at a glance. |
| pic.fam-mom | Pip's mom, a portrait card cut from one family picture; ages clear at a glance. |
| pic.fam-pip | The whole family picture of Pip (mom, dad, baby, brother, sister, grandma, grandpa) with Pip. |
| pic.fam-sister | Pip's sister (a girl older than Pip), a portrait card cut from one family picture; ages clear at a glance. |
| pic.fam-someone | A friendly "someone else" card: a soft outline of a person with a heart (for the personal turn). |
| pic.fish | a fish (in water, side view); one animal, whole, side view, no text. A second pose (`-2`) for match pairs. |
| pic.frog | a green frog sitting; one animal, whole, side view, no text. A second pose (`-2`) for match pairs. |
| pic.greet-arrive-mika | Mika arrives at a playground gate, smiling and waving. |
| pic.greet-arrive-pip | Pip comes in through an open door, smiling and waving, facing the viewer. |
| pic.greet-leave-mika | Mika leaves the playground through the gate, waving back. |
| pic.greet-leave-pip | Pip walks out through the same door with a small backpack, waving back over one shoulder. |
| pic.juice | a glass of orange juice with a straw; on its own, no text or brand. |
| pic.kite | a kite in the sky; no text or brand. A second look (`-2`) for match pairs. |
| pic.mika-cold | Mika, face and shoulders, in a scarf and hat, shivering, snowflakes; the same framing in all faces. |
| pic.mika-eat | Mika sits and eats a sandwich (no greeting gesture). |
| pic.mika-fine | Mika, face and shoulders, a calm small smile and a thumbs-up; the same framing in all faces. |
| pic.mika-happy | Mika, face and shoulders, a big smile; the same framing in all faces. |
| pic.mika-hot | Mika, face and shoulders, in strong sun, fanning the face, a drop of sweat; the same framing as the faces. |
| pic.mika-sad | Mika, face and shoulders, a sad face, a small tear; the same framing in all faces. |
| pic.milk | a glass of white milk; on its own, no text or brand. |
| pic.pig | a pig standing; one animal, whole, side view, no text. A second pose (`-2`) for match pairs. |
| pic.pip-cold | Pip, face and shoulders, in a scarf and hat, shivering, snowflakes; the same framing in all faces. |
| pic.pip-happy | Pip, face and shoulders, a big smile; the same framing in all faces. |
| pic.pip-holds | Pip holds something up behind a small curtain that opens to show it (the object picture slots in). |
| pic.pip-sad | Pip, face and shoulders, a sad face, a small tear; the same framing in all faces. |
| pic.scene-mika-icecream | Mika looks at a dropped ice cream on the ground (sad). |
| pic.scene-mika-present | Mika opens a present and laughs (happy). |
| pic.scene-mika-snow | Mika stands in the snow, shivering (cold). |
| pic.scene-mika-walk | Mika walks calmly along a path on an ordinary day (fine). |
| pic.set-balls-1 | 1 identical balls in a dice-like pattern, the same size in every set. |
| pic.set-balls-2 | 2 identical balls in a dice-like pattern, the same size in every set. |
| pic.set-balls-3 | 3 identical balls in a dice-like pattern, the same size in every set. |
| pic.set-balls-4 | 4 identical balls in a dice-like pattern, the same size in every set. |
| pic.set-balls-5 | 5 identical balls in a dice-like pattern, the same size in every set. |
| pic.set-ducks-1 | 1 identical yellow ducks in a row, evenly spaced, the same size in every set. |
| pic.set-ducks-2 | 2 identical yellow ducks in a row, evenly spaced, the same size in every set. |
| pic.set-ducks-3 | 3 identical yellow ducks in a row, evenly spaced, the same size in every set. |
| pic.set-ducks-4 | 4 identical yellow ducks in a row, evenly spaced, the same size in every set. |
| pic.set-ducks-5 | 5 identical yellow ducks in a row, evenly spaced, the same size in every set. |
| pic.story-bounce-1 | Story "Bounce, Ball!" page 1: Pip's red ball bounces out of Pip's hands on a path in a garden. |
| pic.story-bounce-2 | Story "Bounce, Ball!" page 2: The ball bounces past a cat, who looks up. |
| pic.story-bounce-3 | Story "Bounce, Ball!" page 3: The ball bounces past a duck by a pond (the dialogic pause comes before this line). |
| pic.story-bounce-4 | Story "Bounce, Ball!" page 4: The ball bounces over a frog on a stone. |
| pic.story-bounce-5 | Story "Bounce, Ball!" page 5: A dog jumps and catches the ball. |
| pic.story-bounce-6 | Story "Bounce, Ball!" page 6: The dog brings the ball back to Pip; Pip hugs the dog. |
| pic.teddy | a teddy bear; no text or brand. A second look (`-2`) for match pairs. |
| pic.thumb-down | A thumbs-down button in a calm color (never red, never a cross). |
| pic.thumb-up | A green thumbs-up button. |
| pic.water | a clear glass of water; on its own, no text or brand. |

## 7. Counts and voicing (counted by the script)
| Skill | Items | Scored | 2-choice |
|---|---|---|---|
| ENG-A-01 | 10 | 8 | 4 |
| ENG-A-02 | 14 | 12 | 0 |
| ENG-A-03 | 8 | 8 | 0 |
| ENG-A-04 | 9 | 8 | 0 |
| ENG-A-05 | 10 | 10 | 0 |
| ENG-A-06 | 13 | 12 | 0 |
| ENG-A-07 | 9 | 8 | 0 |
| ENG-A-08 | 13 | 12 | 0 |
| ENG-A-09 | 10 | 10 | 0 |
| ENG-A-10 | 10 | 10 | 4 |
| ENG-A-11 | 10 | 10 | 0 |
| ENG-A-12 | 8 | 8 | 0 |
| ENG-A-13 | 10 | 5 | 0 |
| ENG-A-14 | 12 | 12 | 0 |
| ENG-A-15 | 6 | 5 | 0 |
| ENG-A-16 | 12 | 12 | 6 |
| ENG-A-17 | 8 | 8 | 0 |
| **Total** | **172** | **158** | **14** |

- **Skills:** 17 (ENG-A-01 to A-17). **Words taught in sets:** 69. **Personal turns:** 4. **Chants:** 5. **Stories:** 1 (6 pages). **Pictures:** 109 briefs.
- **English clips:** 222 (74 words, 68 slow words for hint level 1, 80 chunks, chant lines and story pages); **2,141 characters** (1,773 without the slow clips; `en-cousin` removed with the cousin card, 2026-11-04). Each has a row in `pronunciation.csv`.
- **Hebrew clips:** 52 frame lines and 68 glosses. The 52 final lines (1,207 characters as voice text: the 51 lines of 1,163, the new `he-ins-how-many` of 41, and 3 for the nikud that `he-ins-give` now keeps on הָאֹכֶל) and the 68 glosses (460 characters, pointed, as for every single word until the pilot decides) are **1,667 characters** (counted by the hebrew-text-editor on 2026-11-03 after the final wording).
- **Total for one voicing of Band A:** about **3,806 characters** (English 2,141 + Hebrew about 1,665), about **0.30 USD** at the list price used in `voices.md` (0.08 USD per 1,000 characters, `eleven_v4`). Counting rule: Unicode code points of the exact `say` text (as `voice_gen` counts). Not counted: re-takes after a `heard-wrong`, isolated letter sounds (Band B), the drum and animal sound effects.
- **Nothing is voiced by Claude.** The owner runs every paid command and types the character count (CLAUDE.md › Characters and money).

## 8. Checked by script, and not checked
Checked: at most 3 choices; the right answer among the options; every distractor tagged with a known, non-accent tag; at least 2 tagged distractors per skill; the 2-choice rule of frame §2.3 (a 3-choice item has two tagged distractors, a 2-choice item one; 2-choice items at most half of each skill's scored items; a skill with 2-choice items also has 3-choice items, or its answers are balanced, and ENG-A-16 has as many yes as no); the drum (free response) maps only one beat more or fewer; every skill has at least two checks with different answers; **no 2-choice item alone as a check** (a check is a 3-choice item or a balanced pair), and no free-response item or probe as a check; every set word is the right answer at least once; every picture has a brief; every Hebrew line referenced exists; English clips are Latin only; Hebrew lines have no Latin letters; every English clip has a CSV row; every probe is an LS01, LS03 or LS06 item (frame §2.3, LS13: never speech, never a hotspot); every personal turn has a pass and at most 8 cards. Result: **all pass** (re-run 2026-11-04 after QA-L4-7 and QA-L4-10, and 2026-11-03 after the frame §4.5 changes; the script also fails on a deliberately broken copy with the old A-06 i04 hotspot probe and the old 10 family cards, and on one with a lone 2-choice check, a skill with one check, a drum row with an off-by-2 tag). The frame §4.2 catalogue check (`catalogue.py`) also passes for English: 56 tags, each defined once in syllabus §8 with the kind and family of the catalogue; the 6 tags on Band A distractors are all in it, none an accent tag.
Not checked: the pictures (none drawn); the voice (nothing voiced; every row is `draft`); the Hebrew wording (checked by the hebrew-text-editor on 2026-11-03: `text-ready`); the timing of chant pictures (the voice-and-sound-director); the recogniser foils against a real model (L3).
