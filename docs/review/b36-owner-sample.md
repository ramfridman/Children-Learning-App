# B-36 owner sheet: the new texts of the pack and the app (2026-11-01)

From the hebrew-text-editor, for the owner. The plan is `docs/milestones/B36.md` part F and decision 7. You cannot read 3,000 rows, and you do not have to.
You read about 90 rows chosen by pattern (part 4) and the questions I flag (parts 2 and 3). Everything else is approved by the rule in part 5.

**How to answer, from a phone.** Reply with the numbers, for example:

`D1 yes · D2 a yes, b yes, c yes · D3 yes · D4 yes · D5 yes · F1 A · F2 yes · F3 yes · F4 keep אֶל · F5 keep · F6 ok · S1 to S88 OK except S12: say X, S30: delete the second sentence`

"OK" means the screen text and the voice text are both right. If something is wrong, write the fix in your own words; I change the generator, so every row of the same pattern changes at once.

## 1. What happened to the rows

| | Rows |
|---|---|
| Read by the editor (every row that was `proposed` or `needs-editor`) | 3,147 (997 different texts) |
| Now `text-ready`: grammar, nikud, gender and number, plural address, length and the voice text are final | 2,928 |
| Reworded in the sources (units and generators), the draft kept in the `changes` column of the master table | 185 rows (94 texts) |
| Older `text-ready` rows that changed with them | 60 |
| Still `proposed`: V1 | 171 |
| Still `proposed`: the balance sides, D12 | 12 |
| Still `proposed`: the Q2 drafts | 10 |
| Still `proposed`: a teaching question in part 3 (F1 to F3) | 26 |
| Rows you approved before (`owner-approved`), none changed | 115 |

The master table is `docs/review/hebrew-master.csv` (filter the column `status`). My notes and the list of what I changed and why: `docs/agents/hebrew-notes.md` section 14.
Checks that passed on all rows: the length limits (a question is at most 14 words, any other line at most 24), no digit, Latin letter or symbol in a voice text, `test_hebrew_sources`, `test_generators`, and a second regeneration with identical bytes.

## 2. Decision 8, in this sitting: V1, Q2, D12 (and two small ones that go with V1)

These rows change the screen text or the voice text, so they come before the signature.

**D1 · V1, the pronunciation audit.** 171 rows (the audit counted 100; the new rows use the same words). Where: rows whose comment starts `V1` in the master table; the reasons are in `docs/agents/voice-pronunciation-audit.md` sections 4 and 9. In the voice text these words keep their nikud, because plain they read as another word:

| Word | Plain it can be read as | Rows |
|---|---|---|
| בַּתּוֹר (in the line) | "betor", as a | 51 |
| גְּדֵלִים (they grow) | "gdalim", sizes | 43 |
| אֵלֶּה (these) | "ela" | 37 |
| שָׂמִים (we put) | "shamayim", sky | 19 |
| סָפַר (counted) | "sefer", a book | 13 |
| אוֹפְּס (oops) | with an f | 2 |
| נְגַלֶּה, אִמְרוּ, מֵדַלְיָה, בַּשָּׁמַיִם | one row each | 4 |

Also: a beat before `זֶה אֶפֶס` in `אֵין כְּלוּם — זֶה אֶפֶס` (2 rows).
Q: Keep these words pointed in the voice text? *My recommendation: yes.* Reply `D1 yes`, or list the words to drop.

**D2 · Q2, the drafts.** Where: `docs/review/owner-sample.md` rows 4 and 5. Three drafts for the "same number?" and the counting items:

> a. NUM-A-11 "same?" (3 rows): בּוֹאוּ נַעֲשֶׂה זוּגוֹת: לְכֻלָּם יֵשׁ זוּג?
> b. NUM-A-07 (7 rows): בּוֹאוּ נִסְפֹּר כַּמָּה יֵשׁ בְּכׇל קְבוּצָה.
> c. New, NUM-A-11 balance (2 rows, part D; it had the old "more is not always bigger" line, which says the reverse): בּוֹאוּ נִסְפֹּר כַּמָּה קֻבִּיּוֹת יֵשׁ בְּכׇל צַד.

Q: OK, a, b and c? *My recommendation: yes to all three.* Reply `D2 a yes, b yes, c yes`.

**D3 · D12, the sides of a balance, by place and not by right and left** (12 rows, 4 items of MATH-B-13). Where: `owner-sample.md` rows 36 and 37. The design-director must confirm that the beam really tilts.

> הַצַּד שֶׁלְּמַעְלָה קַל יוֹתֵר. מוֹסִיפִים קֻבִּיּוֹת עַד שֶׁשְּׁנֵי הַצְּדָדִים שָׁוִים.
> בַּצַּד שֶׁלְּמַטָּה יֵשׁ חָמֵשׁ קֻבִּיּוֹת, וּבַצַּד שֶׁלְּמַעְלָה שְׁתֵּי קֻבִּיּוֹת. צָרִיךְ עוֹד שָׁלוֹשׁ קֻבִּיּוֹת.

Q: OK? *Yes, if the beam tilts.* Reply `D3 yes`.

**D4 · "אֵינוֹ" (11 rows, the ordinal line, goes with V1 because of `בַּתּוֹר`).**

> now: הַמָּקוֹם בַּתּוֹר אֵינוֹ כַּמָּה יֵשׁ. בּוֹאוּ נִסְפֹּר מֵהַהַתְחָלָה.
> my rule: הַמָּקוֹם בַּתּוֹר הוּא לֹא כַּמָּה יֵשׁ. בּוֹאוּ נִסְפֹּר מֵהַהַתְחָלָה.

Q: Change to "הוּא לֹא" (spoken Hebrew, "אֵינוֹ" is written)? *Yes.* Reply `D4 yes`.

**D5 · "אַחֶרֶת —" (6 rows, LOG-B-08 prompts, goes with V1 because of `שָׂמִים`).**

> now: אִם הַצּוּרָה אֲדֻמָּה, שָׂמִים אוֹתָהּ בַּקֻּפְסָה. אַחֶרֶת — לָעֵשֶׂב.
> my rule: אִם הַצּוּרָה אֲדֻמָּה, שָׂמִים אוֹתָהּ בַּקֻּפְסָה. אִם לֹא — לָעֵשֶׂב.

Q: Change to "אִם לֹא" (school register → spoken)? *Yes.* Reply `D5 yes`.

## 3. Questions I flag (26 rows wait for these, and a few patterns)

**F1 · MATH-B-18, level 3 (9 items).** Your answer Q3 (2026-10-29) asked for "count on from the first number, with fingers". The picture in the app counts the empty places from one and draws no fingers, so the B-40 line says that. Two teachings, one picture.

> A (the line now, matches the picture): שָׁלוֹשׁ קֻבִּיּוֹת כְּבָר יֵשׁ. סוֹפְרִים אֶת הַמְּקוֹמוֹת הָרֵיקִים: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַרְבַּע.
> B (your Q3): שָׁלוֹשׁ… וּמַמְשִׁיכִים: אַרְבַּע, חָמֵשׁ, שֵׁשׁ, שֶׁבַע. הֵרַמְנוּ אַרְבַּע אֶצְבָּעוֹת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַרְבַּע.

Q: A or B? *A* (B needs a new picture, the app-developer and the curriculum-expert). Reply `F1 A`.

**F2 · Spot the mistake, level 3 (9 Band A items).** The B-40 line replaces the line you approved on 2026-10-30 (`כֻּלָּם דּוֹמִים, חוּץ מֵאֶחָד`) in the 9 items where the app draws the right picture above the mistake. The approved line stays in the other 3.

> הוֹלְכִים לְאֹרֶךְ הַשּׁוּרָה מֵהַהַתְחָלָה וְעוֹצְרִים אֵצֶל הַשּׁוֹנֶה. מֵעָלָיו מוֹפִיעָה הַתְּמוּנָה שֶׁצְּרִיכָה לִהְיוֹת שָׁם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו.

Q: Use the new line in those 9? *Yes.* Reply `F2 yes`.

**F3 · MATH-B-08 above ten, level 3 (8 items).** The old line made a ten ("eight and two are ten, three more, thirteen"). The picture is two groups of cubes, not a ten, so the line says the two groups and the sum. The make-ten strategy is out of level 3 until a picture of a ten exists.

> שְׁמוֹנֶה קֻבִּיּוֹת וְעוֹד חָמֵשׁ קֻבִּיּוֹת. בַּכֹּל — שְׁלֹשׁ עֶשְׂרֵה. עַכְשָׁו תּוֹרְכֶם.

Q: OK? *Yes.* Reply `F3 yes`.

**F4 · B-39, "אֶל" or "לְ".** `בּוֹאוּ נֵצֵא לְהַרְפַּתְקָה אֶל {land}.` "אֶל" is a little formal; it is the price of a single `{land}` with no prefix to point (`לְגִבְעוֹת` but `לִמְעָרַת`). The other choice needs six pointed "to" forms. Also: `adventurePlayAgain` names no land by design.

Q: Keep "אֶל"? *Yes.* Reply `F4 keep אֶל`.

**F5 · "לִלְחֹץ עַל" in about 350 hint lines (the screen and the voice say the same).** The audit asked (Q5) whether the voice should say `תִּלְחֲצוּ עַל`, warmer and spoken.

Q: Keep "לִלְחֹץ עַל" on the screen and in the voice for now? *Yes; decide after you hear the A/B.* Reply `F5 keep`.

**F6 · "לִלְחֹץ עָלָיו" after a number (47 rows, Band B).** Example: `שֵׁשׁ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו.` "It" is "the number". Elsewhere the line names it: `לִלְחֹץ עַל שֵׁשׁ`.

Q: Leave "עָלָיו" (it points at the number tile and is gender-neutral), or name the number everywhere? *Leave.* Reply `F6 ok` or `F6 name it`.

## 4. The sample: 88 rows, one for each pattern

Each row: the screen text, the voice text, what it was before if I changed it, how many rows of the table say exactly this, and the question. A row you OK stands for every row built the same way. **The question is "OK?" unless the row has its own Q.** A row marked `status: proposed` is a V1 row (a kept nikud): it is answered by D1.

### A. The hint lines of B-40 (one row for each picture)

**S1 · Level 1, a number row: where to look, no counting** · `b.numb01.1 › hints.0`
> נִסְתַּכֵּל עַל הַמִּסְפָּר, וְעַל הַמָּקוֹם הָרֵיק לְיָדוֹ.
> *voice: נסתכל על המספר, ועל המקום הריק לידו. · same text in 51 rows*

**S2 · Level 1, two groups to compare** · `b15.matha07.1 › hints.0`
> שְׁתֵּי הַקְּבוּצוֹת עוֹמְדוֹת בִּשְׁתֵּי שׁוּרוֹת, זוֹ מֵעַל זוֹ.
> *voice: שְׁתֵּי הקבוצות עומדות בִּשְׁתֵּי שורות, זו מעל זו. · same text in 23 rows*

**S3 · Level 2 in Band B: the week, the day of the question is marked** · `b.mathb14.1 › hints.1`
> הַיָּמִים עוֹמְדִים בְּשׁוּרָה, לְפִי הַסֵּדֶר. הַיּוֹם מֵהַשְּׁאֵלָה מְסֻמָּן, וְיֵשׁ מָקוֹם רֵיק.
> *voice: הימים עומדים בשורה, לפי הסדר. היום מהשאלה מסומן, ויש מקום ריק. · same text in 11 rows*

**S4 · Level 2, the colour on its own** · `b15.cola01.1 › hints.1`
> הִנֵּה רַק הַצֶּבַע. נִסְתַּכֵּל עָלָיו טוֹב.
> *voice: הנה רק הצבע. נסתכל עליו טוב. · same text in 49 rows*

**S5 · Level 2, the shape without colour** · `b15.shpa01.1 › hints.1`
> הִנֵּה רַק הַצּוּרָה, בְּלִי צֶבַע. נִסְתַּכֵּל עָלֶיהָ טוֹב.
> *voice: הנה רק הצורה, בלי צבע. נסתכל עליה טוב. · same text in 32 rows*

**S6 · Level 2, the model of the question** · `b15.loga01.3 › hints.1`
> הִנֵּה הַדּוּגְמָה. נִסְתַּכֵּל עָלֶיהָ טוֹב.
> *voice: הנה הדוגמה. נסתכל עליה טוב. · same text in 11 rows*

**S7 · Level 2, lines pair one to one** · `b15.matha07.1 › hints.1`
> מְחַבְּרִים אֶחָד לְאֶחָד בְּקַוִּים. מִי נִשְׁאָר בְּלִי זוּג?
> *voice: מחברים אֶחָד לְאֶחָד בקווים. מי נשאר בלי זוג? · same text in 30 rows*

**S8 · Level 2, the number path (Band A)** · `next.after.1 › hints.1`
> הַמִּסְפָּרִים עוֹמְדִים בְּשׁוּרָה, מֵאַחַת. נִסְתַּכֵּל עַל הָרִבּוּעַ הָרֵיק.
> *voice: המספרים עומדים בשורה, מֵאַחַת. נסתכל על הריבוע הריק. · same text in 13 rows*

**S9 · Level 2, the part that repeats** · `b15.loga06.1 › hints.1`
> כׇּל חֵלֶק שֶׁחוֹזֵר מְסֻמָּן בְּקַו. נִסְתַּכֵּל אֵיךְ הוּא חוֹזֵר.
> *voice: כל חלק שחוזר מסומן בקו. נסתכל איך הוא חוזר. · same text in 24 rows*

**S10 · Level 2, hands show how many there were** · `b15.matha01.1 › hints.1`
> הָאֶצְבָּעוֹת מַרְאוֹת כַּמָּה הָיָה, וְסוֹפְרִים אֶת הַחֲדָשִׁים אֶחָד אֶחָד.
> *voice: האצבעות מראות כמה היה, וסופרים את החדשים אֶחָד אֶחָד. · same text in 8 rows*

**S11 · Level 2, watch what happens (box and ball)** · `b15.shpa07.1 › hints.1`
> נִרְאֶה מַה קּוֹרֶה כְּשֶׁדּוֹחֲפִים אֶת שְׁנֵיהֶם.
> *voice: נראה מה קורה כשדוחפים את שניהם. · same text in 5 rows*

**S12 · Level 2, the small duck and the basket (the cat items)** · `b15.shpa08.1 › hints.1`
> אֵיפֹה הַבַּרְוָז? בְּתוֹךְ הַסַּל.
> *voice: איפה הברווז? בתוך הסל.*

Q: The cat items say "the duck" because the hint card draws a small duck next to the basket. OK?

**S13 · Level 2, a ten-frame is "מִסְגֶּרֶת" (was "לוּחַ" in the draft)** · `b.numb08.1 › hints.1`
> מִסְגֶּרֶת אַחַת מְלֵאָה, עֶשֶׂר מִשְׁבְּצוֹת. בַּמִּסְגֶּרֶת הַשְּׁנִיָּה יֵשׁ עוֹד כַּמָּה.
> *voice: מסגרת אַחַת מלאה, עֶשֶׂר משבצות. במסגרת השנייה יש עוד כמה. · was: לוּחַ אֶחָד מָלֵא, עֶשֶׂר מִשְׁבְּצוֹת. בַּלּוּחַ הַשֵּׁנִי יֵשׁ עוֹד כַּמָּה. · same text in 11 rows*

Q: One word for a ten-frame, מִסְגֶּרֶת, everywhere (the draft said לוּחַ). OK?

**S14 · Level 2, cubes over each number** · `b.mathb03.1 › hints.1`
> מֵעַל כׇּל מִסְפָּר עוֹמְדוֹת קֻבִּיּוֹת, כְּמוֹ שֶׁהַמִּסְפָּר אוֹמֵר.
> *voice: מעל כל מספר עומדות קוביות, כמו שהמספר אומר. · same text in 28 rows*

**S15 · Level 2, the frog counts its hops** · `b.mathb01.17 › hints.1`
> הַצְּפַרְדֵּעַ קוֹפֶצֶת קְפִיצָה אַחַת קָדִימָה. קַו מְנֻקָּד מְסַמֵּן אֶת הַקְּפִיצָה, וּמֵעָלָיו הַמִּסְפָּר אַחַת.
> *voice: הצפרדע קופצת קפיצה אַחַת קדימה. קו מנוקד מסמן את הקפיצה, ומעליו המספר אַחַת. · same text in 9 rows*

**S16 · Level 2, a dotted line to the rim of the clock** · `b.mathb15.1 › hints.1`
> קַו מְנֻקָּד מַמְשִׁיךְ אֶת הַמַּחֲוָג הַקָּצָר עַד קְצֵה הַשָּׁעוֹן, וְשָׁם עִגּוּל. לְמַעְלָה מְסֻמָּן שְׁתֵּים עֶשְׂרֵה.
> *voice: קו מנוקד ממשיך את המחוג הקצר עד קצה השעון, ושם עיגול. למעלה מסומן שְׁתֵּים עֶשְׂרֵה. · same text in 10 rows*

**S17 · Level 2, the first arrow and the see-through robot** · `b.csb01.1 › hints.1`
> הַחֵץ הָרִאשׁוֹן דּוֹלֵק. הָרוֹבּוֹט הַשָּׁקוּף עוֹמֵד צַעַד אֶחָד הָלְאָה, וְעַל הַמִּשְׁבֶּצֶת הַמִּסְפָּר אַחַת.
> *voice: החץ הראשון דולק. הרובוט השקוף עומד צעד אֶחָד הלאה, ועל המשבצת המספר אַחַת. · same text in 26 rows*

**S18 · Level 2, two paints, an arrow and an empty circle** · `b.colb01.1 › hints.1`
> שְׁנֵי צְבָעִים, חֵץ, וְעִגּוּל רֵיק. אֵיזֶה צֶבַע יִהְיֶה בָּעִגּוּל?
> *voice: שְׁנֵי צבעים, חץ, ועיגול ריק. איזה צבע יהיה בעיגול? · same text in 7 rows*

**S19 · Level 2, a shape fades (the first clue)** · `b.logb09.1 › hints.1`
> הוּא לֹא אָדֹם — אָז הַצּוּרָה הָאֲדֻמָּה דּוֹהָה.
> *voice: הוא לא אדום — אז הצורה האדומה דוהה. · same text in 2 rows*

**S20 · Level 2, the print the solid leaves in the sand** · `x.shpb09.1 › hints.1`
> מִתַּחַת לַגּוּף יֵשׁ צוּרָה בְּקַו מְנֻקָּד: מַה שֶּׁהוּא מַשְׁאִיר בַּחוֹל.
> *voice: מתחת לגוף יש צורה בקו מנוקד: מה שהוא משאיר בחול. · same text in 4 rows*

**S21 · Level 3, a hand passes over all and stops, then the answer (colour)** · `b15.cola01.1 › hints.2`
> הַצֶּבַע עוֹבֵר עַל כֻּלָּם, וְעוֹצֵר אֵצֶל הַמַּתְאִים. זֶה פֶּרַח צָהֹב. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו.
> *voice: הצבע עובר על כולם, ועוצר אצל המתאים. זה פרח צהוב. עכשיו תורכם — ללחוץ עליו. · same text in 3 rows*

Q: Level 3 opens with a hand that goes over all of them, then the answer. OK?

**S22 · Level 3, the places from the flag (an order in a line)** · `ordinal.third › hints.2`
> מַתְחִילִים מֵהַדֶּגֶל: רִאשׁוֹן, שֵׁנִי, שְׁלִישִׁי. זֶה הַשְּׁלִישִׁי בַּתּוֹר. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו.
> *voice: מתחילים מהדגל: ראשון, שֵׁנִי, שלישי. זה השלישי בַּתּוֹר. עכשיו תורכם — ללחוץ עליו. · same text in 2 rows · status: proposed*

**S23 · Level 3, flash: the hand counts first (new opening)** · `flash.dice.3 › hints.2`
> סוֹפְרִים אֶת כֻּלָּם. אֵלֶּה שְׁלוֹשָׁה תַּפּוּחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שָׁלוֹשׁ.
> *voice: סופרים את כולם. אֵלֶּה שְׁלוֹשָׁה תפוחים. עכשיו תורכם — ללחוץ על שָׁלוֹשׁ. · was: אֵלֶּה שְׁלוֹשָׁה תַּפּוּחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שָׁלוֹשׁ. · status: proposed*

Q: Level 3 now counts first (was: "these are three apples" at once). OK?

**S24 · Level 3, one hop from the number given (Band B)** · `b.numb01.1 › hints.2`
> עוֹמְדִים עַל אַחַת עֶשְׂרֵה וְקוֹפְצִים קְפִיצָה אַחַת קָדִימָה: שְׁתֵּים עֶשְׂרֵה. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שְׁתֵּים עֶשְׂרֵה.
> *voice: עומדים על אַחַת עֶשְׂרֵה וקופצים קפיצה אַחַת קדימה: שְׁתֵּים עֶשְׂרֵה. עכשיו תורכם — ללחוץ על שְׁתֵּים עֶשְׂרֵה.*

**S25 · Level 3, skipping by twos** · `b.numb17.10 › hints.2`
> קוֹפְצִים מִמִּסְפָּר לְמִסְפָּר: שְׁתַּיִם, אַרְבַּע, שֵׁשׁ. עוֹד קְפִיצָה אַחַת — שְׁמוֹנֶה. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו.
> *voice: קופצים ממספר למספר: שְׁתַּיִם, אַרְבַּע, שֵׁשׁ. עוד קפיצה אַחַת — שְׁמוֹנֶה. עכשיו תורכם — ללחוץ עליו.*

Q: Ends "לִלְחֹץ עָלָיו" after a number: see F6. OK?

**S26 · Level 3, two ten-frames, "together"** · `b.numb08.1 › hints.2`
> בּוֹנִים: מִסְגֶּרֶת מְלֵאָה — עֶשֶׂר. בַּמִּסְגֶּרֶת הַשְּׁנִיָּה — שְׁתַּיִם. יַחַד — שְׁתֵּים עֶשְׂרֵה. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו.
> *voice: בונים: מסגרת מלאה — עֶשֶׂר. במסגרת השנייה — שְׁתַּיִם. יחד — שְׁתֵּים עֶשְׂרֵה. עכשיו תורכם — ללחוץ עליו. · was: בּוֹנִים: לוּחַ מָלֵא — עֶשֶׂר. בַּלּוּחַ הַשֵּׁנִי — שְׁתַּיִם. יַחַד — שְׁתֵּים עֶשְׂרֵה. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. · same text in 2 rows*

**S27 · Level 3, a chart: "הֲכִי גָּבוֹהַּ" (was "הַגָּבוֹהַּ בְּיוֹתֵר")** · `x.mathb19.1 › hints.2`
> סוֹפְרִים כׇּל עַמּוּד: שָׁלוֹשׁ, חָמֵשׁ, שְׁתַּיִם. הָעַמּוּד הֲכִי גָּבוֹהַּ הוּא זֶה שֶׁיֵּשׁ בּוֹ הֲכִי הַרְבֵּה. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנָּכוֹן.
> *voice: סופרים כל עמוד: שָׁלוֹשׁ, חָמֵשׁ, שְׁתַּיִם. העמוד הכי גבוה הוא זה שיש בו הכי הרבה. עכשיו תורכם — ללחוץ על הנכון. · was: סוֹפְרִים כׇּל עַמּוּד: שָׁלוֹשׁ, חָמֵשׁ, שְׁתַּיִם. הָעַמּוּד הַגָּבוֹהַּ בְּיוֹתֵר הוּא זֶה שֶׁיֵּשׁ בּוֹ הֲכִי הַרְבֵּה. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנָּכוֹן.*

Q: "הֲכִי גָּבוֹהַּ", not "הַגָּבוֹהַּ בְּיוֹתֵר". OK?

**S28 · Level 3, the week, the answer last** · `b.mathb14.2 › hints.2`
> הוֹלְכִים בַּשָּׁבוּעַ מִיּוֹם רִאשׁוֹן עַד יוֹם שִׁשִּׁי. הַיּוֹם הַבָּא הוּא שַׁבָּת. עַכְשָׁו תּוֹרְכֶם.
> *voice: הולכים בשבוע מיום ראשון עד יום שישי. היום הבא הוא שבת. עכשיו תורכם.*

### B. The lines of the new tags and of the M-CNT-CARD contexts, the parent texts (parts B, C and E)

**S29 · M-CNT-CARD: join (the child said one part)** · `b.mathb01.1 › feedback.incorrect.0`
> זֶה רַק חֵלֶק אֶחָד. בּוֹאוּ נִסְפֹּר אֶת כֻּלָּם יַחַד.
> *voice: זה רק חלק אֶחָד. בואו נספור את כולם יחד. · same text in 37 rows*

Q: One line for each context of "the child said a part / the start / the total". OK?

**S30 · M-CNT-CARD: take away (the child said how many were there)** · `b.mathb01.10 › feedback.incorrect.0`
> זֶה כַּמָּה שֶׁהָיוּ בַּהַתְחָלָה, לִפְנֵי שֶׁלָּקַחְנוּ. בּוֹאוּ נִסְפֹּר כַּמָּה נִשְׁאֲרוּ.
> *voice: זה כמה שהיו בהתחלה, לפני שלקחנו. בואו נספור כמה נשארו. · same text in 29 rows*

**S31 · M-CNT-CARD: make ten** · `b.mathb06.10 › feedback.incorrect.0`
> זֶה כַּמָּה שֶׁכְּבָר יֵשׁ. בּוֹאוּ נַמְשִׁיךְ לִסְפֹּר עַד עֶשֶׂר, וְנִרְאֶה כַּמָּה הוֹסַפְנוּ.
> *voice: זה כמה שכבר יש. בואו נמשיך לספור עד עֶשֶׂר, ונראה כמה הוספנו. · same text in 9 rows*

**S32 · M-CNT-CARD: plates** · `b.mathb10.7 › feedback.incorrect.0`
> הַשְּׁאֵלָה הִיא כַּמָּה צַלָּחוֹת. בּוֹאוּ נִסְפֹּר אֶת הַצַּלָּחוֹת.
> *voice: השאלה היא כמה צלחות. בואו נספור את הצלחות. · same text in 2 rows*

**S33 · M-MUL-ADD (new tag)** · `b.mathb10.1 › feedback.incorrect.1`
> חִבַּרְנוּ אֶת שְׁנֵי הַמִּסְפָּרִים. בּוֹאוּ נִסְפֹּר אֶת כֻּלָּם, צַלַּחַת אַחַר צַלַּחַת.
> *voice: חיברנו את שְׁנֵי המספרים. בואו נספור את כולם, צלחת אחר צלחת. · same text in 6 rows*

**S34 · M-OP-SWAP (new tag)** · `b.mathb03.16 › feedback.incorrect.1`
> בּוֹאוּ נִסְתַּכֵּל שׁוּב בַּסִּימָן: מוֹסִיפִים אוֹ לוֹקְחִים?
> *voice: בואו נסתכל שוב בסימן: מוסיפים או לוקחים? · same text in 13 rows*

**S35 · M-TIME-SEQ (new tag)** · `b.mathb14.1 › feedback.incorrect.0`
> בּוֹאוּ נֹאמַר אֶת הַסֵּדֶר מֵהַהַתְחָלָה, אֶחָד אַחֲרֵי הַשֵּׁנִי.
> *voice: בואו נגיד את הסדר מההתחלה, אֶחָד אחרי הַשֵּׁנִי. · same text in 21 rows*

**S36 · M-NUM-NAME (new tag)** · `pick.numeral.1 › feedback.incorrect.0`
> לְכׇל מִסְפָּר יֵשׁ סִפְרָה מִשֶּׁלּוֹ. בּוֹאוּ נִסְתַּכֵּל שׁוּב עַל כׇּל סִפְרָה.
> *voice: לכל מספר יש ספרה משלו. בואו נסתכל שוב על כל ספרה. · same text in 9 rows*

**S37 · M-SHP-NAME (new tag, flat shapes)** · `b15.shpa02.1 › feedback.incorrect.1`
> לְכׇל צוּרָה יֵשׁ שֵׁם מִשֶּׁלָּהּ. בּוֹאוּ נִסְתַּכֵּל שׁוּב עַל הַקַּוִּים וְהַפִּנּוֹת.
> *voice: לכל צורה יש שם משלה. בואו נסתכל שוב על הקווים והפינות. · same text in 18 rows*

**S38 · M-RULE-ONE (new tag)** · `b.logb06.1 › feedback.incorrect.0`
> זֶה נָכוֹן לְאֶחָד מֵהֶם. בּוֹאוּ נִבְדֹּק אִם זֶה נָכוֹן לְכֻלָּם, אֶחָד אֶחָד.
> *voice: זה נכון לְאֶחָד מהם. בואו נבדוק אם זה נכון לכולם, אֶחָד אֶחָד. · same text in 10 rows*

**S39 · M-SEQ-SCRIPT (new tag; the line is reworded)** · `b36.csa05.1 › feedback.incorrect.0`
> בּוֹאוּ נַעֲבֹר עַל הַצְּעָדִים שֶׁל כׇּל אֶחָד, צַעַד אַחַר צַעַד, וְנִרְאֶה לְאֵיפֹה זֶה שַׁיָּךְ.
> *voice: בואו נעבור על הצעדים של כל אֶחָד, צעד אחר צעד, ונראה לאיפה זה שייך. · was: זֶה חֵלֶק מֵהַשְּׁלַבִּים. בּוֹאוּ נַעֲבֹר עֲלֵיהֶם, אֶחָד אַחֲרֵי הַשֵּׁנִי. · same text in 8 rows*

Q: Reworded: the old line did not say what to do. OK?

**S40 · M-ASSOC-LOOK (new tag)** · `b15.loga09.1 › feedback.incorrect.0`
> זֶה נִרְאֶה דּוֹמֶה. בּוֹאוּ נַחְשֹׁב מָה עוֹשִׂים עִם כׇּל דָּבָר, וּמָה הוֹלֵךְ יַחַד.
> *voice: זה נראה דומה. בואו נחשוב מה עושים עם כל דבר, ומה הולך יחד. · same text in 10 rows*

Q: Is "זֶה נִרְאֶה דּוֹמֶה" clear for a 4 year old? OK?

**S41 · shp_name.solids (for solids)** · `b.shpb08.1 › feedback.incorrect.0`
> לְכׇל גּוּף יֵשׁ שֵׁם מִשֶּׁלּוֹ. בּוֹאוּ נִסְתַּכֵּל: הוּא מִתְגַּלְגֵּל? יֵשׁ לוֹ פִּנּוֹת?
> *voice: לכל גוף יש שם משלו. בואו נסתכל: הוא מתגלגל? יש לו פינות? · same text in 10 rows*

**S42 · LOG-A-09: a look-alike takes the place of a random wrong answer (shoe, boat)** · `log.pair.shoe › answer.options.1.label`
> סִירָה

Q: A toy boat now stands where a random picture was (it looks like a shoe, it does not go with a sock). OK?

**S43 · LOG-A-09: a look-alike (bowl, pink ball)** · `log.pair.bowl › answer.options.0.label`
> כַּדּוּר וָרֹד
> *same text in 4 rows*

**S44 · Parent text of a new tag** · `misconception.M-ASSOC-LOOK › parentText`
> הילד בוחר את מה שנראה דומה (בצורה או בצבע), ולא את מה שהולך יחד בשימוש. למשל, ליד מפתח הוא בוחר עיפרון, כי שניהם ארוכים וצהובים.
> *was: הילד בוחר את מה שנראה דומה (צורה או צבע), ולא את מה שהולך יחד בשימוש: למפתח הוא מתאים עיפרון, כי שניהם ארוכים וצהובים.*

**S45 · Parent text of a new tag** · `misconception.M-OP-SWAP › parentText`
> הילד עושה את הפעולה ההפוכה: מחבר כשצריך לחסר (עונה 13 על 9 פחות 4), או מחסר כשצריך לחבר.
> *was: הילד עושה את הפעולה ההפוכה: מחבר כשצריך לחסר (13 בתרגיל 9 פחות 4), או מחסר כשצריך לחבר.*

Q: Plain adult Hebrew for the parents. OK?

**S46 · Parent text of a new tag** · `misconception.M-RULE-ONE › parentText`
> הילד בודק את הכלל רק על אחד הפריטים ולא על כולם: רואה שהראשון עיגול ובוחר בכלל "כולם עיגולים", גם כשהאחרים אינם עיגולים.
> *was: הילד בודק את הכלל רק על אחד הפריטים ולא על כולם: רואה שהראשון עיגול ובוחר "הצורה", גם כשהאחרים אינם עיגולים.*

**S47 · Home activity of a new tag** · `misconception.M-TIME-SEQ › homeActivity.0.v`
> בערב, לספר יחד את היום מההתחלה: בבוקר קמנו, בצהריים אכלנו, בערב התרחצנו, ועכשיו לילה. ובשבוע: לומר יחד את הימים מיום ראשון עד שבת.

### C. The 150 second-representation items (part D): one row for each kind of line that I changed or that is new

**S48 · A claim to judge (yes or no); the frogs are feminine now** · `b36.numa12.1 › prompt`
> שָׁלוֹשׁ צְפַרְדְּעִים גְּדוֹלוֹת וַחֲמִשָּׁה אֶפְרוֹחִים קְטַנִּים. אַחַת הַצְּפַרְדְּעִים אוֹמֶרֶת: "אֲנַחְנוּ יוֹתֵר!" הִיא צוֹדֶקֶת?
> *voice: שָׁלוֹשׁ צפרדעים גדולות וַחֲמִשָּׁה אפרוחים קטנים. אַחַת הצפרדעים אומרת: "אנחנו יותר." היא צודקת? · was: שְׁלוֹשָׁה צְפַרְדְּעִים גְּדוֹלִים וַחֲמִשָּׁה אֶפְרוֹחִים קְטַנִּים. הַצְּפַרְדֵּעַ אוֹמֶרֶת: "אֲנַחְנוּ יוֹתֵר!" הִיא צוֹדֶקֶת?*

Q: A claim to judge; the frogs are feminine now. OK?

**S49 · Build a row that repeats (was a sentence that is not Hebrew)** · `b36.loga04.1 › prompt`
> הִנֵּה חָתוּל וְכֶלֶב. בּוֹנִים שׁוּרָה: הֵם חוֹזְרִים שׁוּב וָשׁוּב.
> *voice: הנה חתול וכלב. בונים שורה: הם חוזרים שוב ושוב. · was: הִנֵּה חָתוּל וְכֶלֶב. עוֹשִׂים שֶׁהֵם יַחְזְרוּ שׁוּב וָשׁוּב. · same text in 2 rows*

**S50 · The answer to a row that repeats (was "you copied the order")** · `b36.loga04.1 › feedback.correct`
> כֵּן! בְּנִיתֶם שׁוּרָה שֶׁחוֹזֶרֶת שׁוּב וָשׁוּב.
> *voice: כן, בניתם שורה שחוזרת שוב ושוב. · was: כֵּן! הֶעְתַּקְתֶּם אֶת הַסֵּדֶר. · same text in 2 rows*

**S51 · Sort the steps of two routines (was "שִׁגְרָה")** · `b36.csa05.1 › prompt`
> כׇּל צַעַד שַׁיָּךְ לְצִחְצוּחַ שִׁנַּיִם אוֹ לִרְחִיצַת יָדַיִם.
> *voice: כל צעד שייך לצחצוח שיניים או לרחיצת ידיים. · was: כׇּל צַעַד אֶל הַשִּׁגְרָה שֶׁלּוֹ: צִחְצוּחַ שִׁנַּיִם אוֹ רְחִיצַת יָדַיִם. · same text in 4 rows*

**S52 · Put steps in order: the answer line** · `b36.csa01.1 › feedback.correct`
> כֵּן! סִדַּרְתֶּם אֶת הַצְּעָדִים.
> *voice: כן, סידרתם את הצעדים. · was: כֵּן! הֶעְתַּקְתֶּם אֶת הַסֵּדֶר. · same text in 2 rows*

**S53 · Give a number of things** · `b36.numa05.2 › prompt`
> תְּנוּ לִי שָׁלוֹשׁ צִפֳּרִים.
> *voice: תנו לי שָׁלוֹשׁ ציפורים. · same text in 4 rows*

**S54 · The balance in words of "sides" (was "pans")** · `b.numb14.12 › prompt`
> שְׁמוֹנֶה קֻבִּיּוֹת בְּצַד אֶחָד, שָׁלוֹשׁ קֻבִּיּוֹת בַּצַּד הַשֵּׁנִי. מוֹסִיפִים קֻבִּיּוֹת עַד שֶׁשְּׁנֵי הַצְּדָדִים שָׁוִים.
> *voice: שְׁמוֹנֶה קוביות בצד אֶחָד, שָׁלוֹשׁ קוביות בצד הַשֵּׁנִי. מוסיפים קוביות עד שֶׁשְּׁנֵי הצדדים שווים. · was: שְׁמוֹנֶה עַל קַעֲרָה אַחַת, שָׁלוֹשׁ עַל הַשְּׁנִיָּה. מוֹסִיפִים קֻבִּיּוֹת עַד שֶׁשְּׁנֵי הַצְּדָדִים שָׁוִים. · same text in 2 rows*

**S55 · The balance, worked example** · `b.numb14.12 › hints.2`
> שְׁמוֹנֶה קֻבִּיּוֹת בְּצַד אֶחָד, שָׁלוֹשׁ קֻבִּיּוֹת בַּצַּד הַשֵּׁנִי. מוֹסִיפִים קֻבִּיָּה אַחַר קֻבִּיָּה, עַד שֶׁיֵּשׁ שְׁמוֹנֶה. עַכְשָׁו תּוֹרְכֶם.
> *voice: שְׁמוֹנֶה קוביות בצד אֶחָד, שָׁלוֹשׁ קוביות בצד הַשֵּׁנִי. מוסיפים קובייה אחר קובייה, עד שיש שְׁמוֹנֶה. עכשיו תורכם. · was: שְׁמוֹנֶה וְשָׁלוֹשׁ: חֲסֵרוֹת חָמֵשׁ. מוֹסִיפִים קֻבִּיָּה אַחַר קֻבִּיָּה. עַכְשָׁו תּוֹרְכֶם.*

**S56 · A frog on the number line: counting on from ten** · `b.numb01.10 › hints.2`
> מַתְחִילִים מֵעֶשֶׂר וְסוֹפְרִים: אַחַת עֶשְׂרֵה, שְׁתֵּים עֶשְׂרֵה, שְׁלֹשׁ עֶשְׂרֵה, אַרְבַּע עֶשְׂרֵה. עַכְשָׁו תּוֹרְכֶם.
> *voice: מתחילים מֵעֶשֶׂר וסופרים: אַחַת עֶשְׂרֵה, שְׁתֵּים עֶשְׂרֵה, שְׁלֹשׁ עֶשְׂרֵה, אַרְבַּע עֶשְׂרֵה. עכשיו תורכם. · was: מַתְחִילִים מִעֶשֶׂר וְסוֹפְרִים: מֵאַחַת עַד אַרְבַּע עֶשְׂרֵה. עַכְשָׁו תּוֹרְכֶם.*

**S57 · From six: "מִשֵּׁשׁ" (the dagesh)** · `b.numb11.19 › prompt`
> שִׂימוּ אֶת הַצְּפַרְדֵּעַ עַל הַמִּסְפָּר שֶׁהוּא אֶחָד יוֹתֵר מִשֵּׁשׁ.
> *voice: שימו את הצפרדע על המספר שהוא אֶחָד יותר מִשֵּׁשׁ. · was: שִׂימוּ אֶת הַצְּפַרְדֵּעַ עַל הַמִּסְפָּר שֶׁהוּא אֶחָד יוֹתֵר מִשֵׁשׁ. · same text in 2 rows*

Q: The dagesh after מִ in מִשֵּׁשׁ. OK?

**S58 · The hidden fish: the noun with its number** · `b.mathb18.10 › prompt`
> בְּסַךְ הַכֹּל יֵשׁ שִׁבְעָה דָּגִים. רוֹאִים שְׁלוֹשָׁה דָּגִים, וְהַשְּׁאָר מֻסְתָּרִים מֵאֲחוֹרֵי הָאֶבֶן. כַּמָּה מֻסְתָּרִים?
> *voice: בסך הכול יש שִׁבְעָה דגים. רואים שְׁלוֹשָׁה דגים, והשאר מוסתרים מאחורי האבן. כמה מוסתרים? · was: בְּסַךְ הַכֹּל יֵשׁ שִׁבְעָה דָּגִים. רוֹאִים שָׁלוֹשׁ, וְהַשְּׁאָר מֻסְתָּרִים מֵאֲחוֹרֵי הָאֶבֶן. כַּמָּה מֻסְתָּרִים? · same text in 2 rows*

**S59 · Mixing colours in a story** · `b.colb01.10 › prompt`
> הַצְּפַרְדֵּעַ רוֹצָה בַּיִת יָרֹק. יֵשׁ לָהּ צֶבַע כָּחֹל. אֵיזֶה צֶבַע הִיא מוֹסִיפָה?
> *voice: הצפרדע רוצה בית ירוק. יש לה צבע כחול. איזה צבע היא מוסיפה? · same text in 2 rows*

**S60 · Roll or stack (was "נֶעֱרָמִים")** · `b36.shpa07.1 › prompt`
> דְּבָרִים שֶׁמִּתְגַּלְגְּלִים לְכָאן, וּדְבָרִים שֶׁאֶפְשָׁר לַעֲרֹם לְכָאן.
> *voice: דברים שמתגלגלים לכאן, ודברים שאפשר לערום לכאן. · was: דְּבָרִים שֶׁמִּתְגַּלְגְּלִים לְכָאן, וּדְבָרִים שֶׁעוֹמְדִים וְנֶעֱרָמִים לְכָאן. · same text in 2 rows*

**S61 · Two cats: a share that is not equal (was "מִלַּכֶּלֶב")** · `b36.matha03.1 › feedback.correct`
> כֵּן, לֶחָתוּל יֵשׁ יוֹתֵר מֵהַכֶּלֶב.
> *voice: כן, לחתול יש יותר מהכלב. · was: כֵּן, לֶחָתוּל יֵשׁ יוֹתֵר מִלַּכֶּלֶב.*

**S62 · Writing a 3 (was "שְׁתֵּי עִקּוּלִים")** · `x.numb07.21 › hints.2`
> כּוֹתְבִים שָׁלוֹשׁ בִּשְׁתֵּי קְשָׁתוֹת שֶׁנִּפְתָּחוֹת שְׂמֹאלָה. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַשָּׁלוֹשׁ הַנְּכוֹנָה.
> *voice: כותבים שָׁלוֹשׁ בִּשְׁתֵּי קשתות שנפתחות שמאלה. עכשיו תורכם — ללחוץ על הַשָּׁלוֹשׁ הנכונה. · was: כּוֹתְבִים שָׁלוֹשׁ בִּשְׁתֵּי עִקּוּלִים שֶׁנִּפְתָּחִים לְצַד שְׂמֹאל. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַשָּׁלוֹשׁ הַנְּכוֹנָה.*

**S63 · Writing a 7 (was "קַו שֶׁכָּבוּי")** · `x.numb07.22 › hints.2`
> כּוֹתְבִים שֶׁבַע: קַו שׁוֹכֵב, וְאַחֲרָיו קַו שֶׁיּוֹרֵד כְּמוֹ מַגְלֵשָׁה. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַשֶּׁבַע הַנְּכוֹנָה.
> *voice: כותבים שֶׁבַע: קו שוכב, ואחריו קו שיורד כמו מגלשה. עכשיו תורכם — ללחוץ על הַשֶּׁבַע הנכונה. · was: כּוֹתְבִים שֶׁבַע בְּקַו שֶׁכָּבוּי וְקַו אֶלְכְּסוֹן שֶׁיּוֹרֵד. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַשֶּׁבַע הַנְּכוֹנָה.*

**S64 · A mirrored digit has its own line** · `x.numb07.21 › feedback.incorrect.1`
> הַסִּפְרָה הַזֹּאת הֲפוּכָה, כְּמוֹ בַּמַּרְאָה. בּוֹאוּ נִסְתַּכֵּל לְאֵיזֶה צַד הִיא פּוֹנָה.
> *voice: הספרה הזאת הפוכה, כמו במראה. בואו נסתכל לאיזה צד היא פונה. · was: הַסִּפְרָה הָרִאשׁוֹנָה אוֹמֶרֶת כַּמָּה עֲשָׂרוֹת. בּוֹאוּ נִסְתַּכֵּל שׁוּב. · same text in 2 rows*

Q: A mirrored digit has a line of its own, about the mirror. OK?

**S65 · Which number is bigger: "הַמִּסְפָּר תֵּשַׁע גָּדוֹל יוֹתֵר"** · `b.numb10.11 › feedback.correct`
> כֵּן! הַמִּסְפָּר תֵּשַׁע גָּדוֹל יוֹתֵר.
> *voice: כן, המספר תֵּשַׁע גדול יותר. · was: כֵּן! תֵּשַׁע גָּדוֹל יוֹתֵר.*

**S66 · Skip counting: the answer line** · `b.numb17.13 › feedback.correct`
> עֶשֶׂר! סְפַרְתֶּם זוּג אַחַר זוּג.
> *voice: עֶשֶׂר. ספרתם זוג אחר זוג. · was: עֶשֶׂר! כֹּל זוּג, וְעוֹד זוּג.*

**S67 · Fix the program (robot)** · `b.csb04.7 › prompt`
> אוֹפְּס, חֵץ אֶחָד הָלַךְ לְמַטָּה בִּמְקוֹם לְמַעְלָה, וְהָרוֹבּוֹט נֶעֱצַר כָּאן. מַגִּיעִים לַדֶּגֶל בַּדֶּרֶךְ הַקְּצָרָה.
> *voice: אוֹפְּס, חץ אֶחָד הלך למטה במקום למעלה, והרובוט נעצר כאן. מגיעים לדגל בדרך הקצרה. · was: אוּפְּס, חֵץ אֶחָד הָלַךְ לְמַטָּה בִּמְקוֹם לְמַעְלָה, וְהָרוֹבּוֹט נֶעֱצַר כָּאן. מַגִּיעִים לַדֶּגֶל בַּדֶּרֶךְ הַקְּצָרָה. · same text in 2 rows · status: proposed*

**S68 · A new tag line: the next hop (M-CNT-DECADE, a new group of ten)** · `b.numb02.10 › feedback.incorrect.0`
> אַחֲרֵי הַתֵּשַׁע מַתְחִילָה קְבוּצָה חֲדָשָׁה שֶׁל עֶשֶׂר. בּוֹאוּ נִסְפֹּר יַחַד.
> *voice: אחרי הַתֵּשַׁע מתחילה קבוצה חדשה של עֶשֶׂר. בואו נספור יחד. · was: אַחֲרֵי הַתֵּשַׁע בָּא עֶשֶׂר חָדָשׁ. בּוֹאוּ נִסְפֹּר יַחַד. · same text in 10 rows*

**S69 · The balance of NUM-A-11 has a counting line of its own** · `b36.numa11.1 › feedback.incorrect.0`
> בּוֹאוּ נִסְפֹּר כַּמָּה קֻבִּיּוֹת יֵשׁ בְּכׇל צַד.
> *voice: בואו נספור כמה קוביות יש בכל צד. · was: יוֹתֵר לֹא תָּמִיד אוֹמֵר גָּדוֹל יוֹתֵר. בּוֹאוּ נַשְׁוֶה אֶחָד אֶחָד. · same text in 2 rows*

**S70 · A lesson title of the new continuation lessons** · `lesson.days-of-the-week-1-b36 › title.0.v`
> יְמֵי הַשָּׁבוּעַ
> *same text in 2 rows*

**S71 · A lesson celebration** · `lesson.build-with-shapes-1-b36 › celebration`
> וַאוּ! בְּנִיתֶם תְּמוּנוֹת מִצּוּרוֹת.
> *voice: וואו, בניתם תמונות מצורות. · same text in 2 rows*

### D. The cube and the cat of B-38 (decision 9)

**S72 · B-38: "where is the cube?"** · `b.shpb08.10 › prompt`
> אֵיפֹה הַקֻּבִּיָּה?
> *voice: איפה הקובייה? · same text in 2 rows*

Q: Band B says "הַקֻּבִּיָּה" for a real cube and "הַתֵּבָה" for the box. OK?

**S73 · B-38: the cube, the answer line** · `b.shpb08.10 › feedback.correct`
> כֵּן! זוֹ הַקֻּבִּיָּה — כׇּל הַצְּדָדִים שֶׁלָּהּ רִבּוּעִים.
> *voice: כן, זו הקובייה — כל הצדדים שלה ריבועים.*

**S74 · B-38: the cube, the worked example** · `b.shpb08.10 › hints.2`
> נִסְתַּכֵּל עַל הַצְּדָדִים. בַּקֻּבִּיָּה כֻּלָּם רִבּוּעִים, וְלַתֵּבָה יֵשׁ צְדָדִים אֲרֻכִּים. עַכְשָׁו תּוֹרְכֶם.
> *voice: נסתכל על הצדדים. בקובייה כולם ריבועים, ולתיבה יש צדדים ארוכים. עכשיו תורכם.*

**S75 · B-38: "where is the box?", the cube is now a wrong answer** · `b.shpb08.5 › feedback.correct`
> כֵּן! זוֹ הַתֵּבָה — אֲרֻכָּה, כְּמוֹ קֻפְסָה שֶׁל נַעֲלַיִם.
> *voice: כן, זו התיבה — ארוכה, כמו קופסה של נעליים.*

Q: The cube is a wrong answer here, so the line says the box is long (decision 9). OK?

**S76 · B-38: the cube and the box, their own line** · `b.shpb08.10 › feedback.incorrect.1`
> בַּקֻּבִּיָּה כׇּל הַצְּדָדִים רִבּוּעִים, וְלַתֵּבָה יֵשׁ צְדָדִים אֲרֻכִּים כְּמוֹ מַלְבֵּן.
> *voice: בקובייה כל הצדדים ריבועים, ולתיבה יש צדדים ארוכים כמו מלבן. · same text in 2 rows*

**S77 · B-38: "what can we stack?" with the cube** · `b15.shpa07.2 › hints.2`
> נִסְתַּכֵּל עַל הַקֻּבִּיָּה. יֵשׁ לָהּ צְדָדִים שְׁטוּחִים, אָז אֶפְשָׁר לָשִׂים עָלֶיהָ עוֹד קֻבִּיָּה. עַכְשָׁו תּוֹרְכֶם.
> *voice: נסתכל על הקובייה. יש לה צדדים שטוחים, אז אפשר לשים עליה עוד קובייה. עכשיו תורכם.*

Q: Band A says "קֻבִּיָּה" only for a real cube (decision 9). OK?

**S78 · B-38: the cat in, on and next to the basket** · `b15.shpa08.1 › prompt`
> אֵיפֹה הֶחָתוּל? בְּתוֹךְ הַסַּל.
> *voice: איפה החתול? בתוך הסל. · same text in 2 rows*

Q: The cat in, on and next to a basket (decision 9). OK?

**S79 · B-38: the cat on the basket, the worked example** · `b15.shpa08.2 › hints.2`
> נִסְתַּכֵּל עַל הַסַּל. הוּא סָגוּר, וְהֶחָתוּל יוֹשֵׁב לְמַעְלָה, אָז הֶחָתוּל עַל הַסַּל. עַכְשָׁו תּוֹרְכֶם.
> *voice: נסתכל על הסל. הוא סגור, והחתול יושב למעלה, אז החתול על הסל. עכשיו תורכם.*

### E. The app: the bottle (B-39) and the name refusal (B-32)

**S80 · B-39 bottle: welcome ({land} is the name of the land)** · `app/lib/strings/he.dart › adventureWelcome`
> בּוֹאוּ נֵצֵא לְהַרְפַּתְקָה אֶל {land}.
> *voice: בואו נֵצֵא להרפתקה אל {land}.*

Q: See F4: "אֶל" or "לְ"? Otherwise OK?

**S81 · B-39 bottle: something needs help** · `app/lib/strings/he.dart › adventureCallForHelp`
> מַשֶּׁהוּ שֶׁל {land} צָרִיךְ עֶזְרָה. בּוֹאוּ נַעֲזֹר.
> *voice: משהו של {land} צריך עזרה. בואו נעזור.*

**S82 · B-39 bottle: continue** · `app/lib/strings/he.dart › adventureSameLand`
> בּוֹאוּ נַמְשִׁיךְ בַּהַרְפַּתְקָה שֶׁל {land}.
> *voice: בואו נמשיך בהרפתקה של {land}.*

**S83 · B-39 bottle: visit another land** · `app/lib/strings/he.dart › adventureOtherLand`
> בּוֹאוּ נְבַקֵּר אֶת {land}.
> *voice: בואו נְבַקֵּר את {land}.*

**S84 · B-39 bottle: play a known game again** · `app/lib/strings/he.dart › adventurePlayAgain`
> בּוֹאוּ נְשַׂחֵק שׁוּב מִשְׂחָק שֶׁאֲנַחְנוּ מַכִּירִים.
> *voice: בואו נשחק שוב משחק שאנחנו מכירים.*

**S85 · B-32 the name refusal message (parent screen, plain)** · `app/lib/strings/he.dart › setupNameBadChars`
> בלי הסימנים < או > ובלי תווים בלתי נראים או מיוחדים. ניקוד אפשר רק אחרי אות, ולא יותר משלושה סימנים על אות. אם השם הודבק, אפשר להקליד אותו מחדש.

Q: A parent reads this when a name is refused. Plain adult Hebrew, no nikud. OK?

### F. The two lines the curriculum-expert flagged (COL-B-02 and COL-B-03) and one found next to them

**S86 · COL-B-02: the middle shade (no size words)** · `b.colb02.9 › feedback.incorrect.0`
> מְחַפְּשִׂים אֶת הָאֶמְצַע: לֹא הֲכִי בָּהִיר וְלֹא הֲכִי כֵּהֶה.
> *voice: מחפשים את האמצע: לא הכי בהיר ולא הכי כהה. · was: מְחַפְּשִׂים אֶת הָאֶמְצַע: לֹא הֲכִי קָטָן וְלֹא הֲכִי גָּדוֹל. · same text in 6 rows*

Q: The line the curriculum-expert asked for: no size words for a shade. OK?

**S87 · COL-B-03: green (no "blue")** · `b.colb03.3 › feedback.incorrect.0`
> בָּהִיר אוֹ כֵּהֶה, זֶה אוֹתוֹ צֶבַע. בּוֹאוּ נִבְדֹּק שׁוּב.
> *voice: בהיר או כהה, זה אותו צבע. בואו נבדוק שוב. · was: כָּחֹל בָּהִיר וְכָחֹל כֵּהֶה הֵם שְׁנֵיהֶם כָּחֹל. בּוֹאוּ נִסְתַּכֵּל עַל הַצֶּבַע. · same text in 15 rows*

Q: The line the curriculum-expert asked for: no "blue" for green, red and purple. OK?

**S88 · COL-B-02: the darkest asked, the child chose the middle (found on the way)** · `b.colb02.1 › feedback.incorrect.1`
> זֶה הָאֶמְצַע. בּוֹאוּ נַשְׁוֶה אֶת כֻּלָּם: בָּהִיר, אֶמְצָעִי, כֵּהֶה.
> *voice: זה האמצע. בואו נשווה את כולם: בהיר, אמצעי, כהה. · was: מְחַפְּשִׂים אֶת הָאֶמְצַע: לֹא הֲכִי קָטָן וְלֹא הֲכִי גָּדוֹל. · same text in 8 rows*

## 5. The rule by which the rest is approved

1. Every row I did not show you is built by one of the patterns above, or says exactly a text you saw (the "same text in N rows" lines). If you OK a pattern, you OK its rows. I read all 3,147 myself, with the item next to the line, for grammar, nikud, gender and number, the plural address, length and a word a 3 to 8 year old knows.
2. If you correct a row, tell me which pattern; I fix the generator and every row of the pattern changes together. The table keeps the draft.
3. Not covered by the rule, and not approved by it: the 171 V1 rows (D1, D4, D5), the 12 balance rows (D3), the 10 Q2 drafts (D2) and the 26 rows of F1 to F3. They stay `proposed` until you answer.
4. After your reply the orchestrator relays it: it adds one rule to `OWNER_APPROVED` in `tools/hebrew_voice_review.py` ("approved by the rule of b36-owner-sample.md, date") for the sample rows and for the other `text-ready` rows, and they become `owner-approved`. I never set that status myself. Then the pack is signed, and exactly these texts are voiced (B-45).

## 6. What I could not settle

- The tag of a mirrored 3 or 7 (`x.numb07.21`, `.22`) is `M-NUM-REV` ("swaps two digits"); `M-NUM-WRITE` fits. I gave the items their own line; the tag is the curriculum-expert's.
- Older lines I left alone because they are `text-ready` and you may have read them: `יֵשׁ הַרְבֵּה בְּסַךְ הַכֹּל, וְחֵלֶק מֵהֶם כְּבָר רָאִינוּ` (M-PART-MISS, 40 rows), and the NUM-A-11 correct line `כֵּן, צָדַקְתֶּם!` that a child hears after answering "לֹא".
- The five bottle lines are voiced once for each of the six lands; the voice director confirms the four pointed land names (`יַעַר הצורות`, `מְעָרַת החידות`, `נְמַל הרובוטים`, `כְּפַר השוק`).
- I did not run the app tests (no Flutter, as asked). Tests that pin Hebrew text in `app/test` may need the new text; the Python tests are green.
