# B-15 Hebrew: final text for the content spec

Hebrew text editor, 2026-10-30, worktree `D:\nitznutz-content`, branch `content-b3-b15`. Input: `docs/knowledge/b15-content-spec.md` (H-D). Rules: `docs/agents/hebrew-notes.md` §2 to §5 (Q1 full nikud on the defective spelling; Q7 box word; Q8 and Q12 number gender; Q10 `÷`). Nothing in the spec, the generators, `content/` or the review CSV was changed. The app-developer brings these strings into the generators. Every new string goes into the pack as `"review": "needs-editor"`. Only the owner moves a row past `text-ready`.

**Statuses used here.** `text-ready`: grammar, words and voice text are final and wait for the owner. `reused`: the line already exists in `docs/review/hebrew-master.csv` with the same meaning; the generator copies that row (its id is given) and no new string is made. `proposed`: needs the owner's decision; the generator keeps today's line until he decides.

**Voice text conventions** (§3 of the notes): plain full spelling, nikud kept on every number word (also with a prefix: `לְשָׁלוֹשׁ`, `וְאַרְבָּעָה`) and on homographs (`שָׂחוּ` (swam), which is not `שַׁחוּ` (bowed); `צָמַח` (grew), not `צֶמַח` (a plant); `בָּנָה`; `מִיֵּן`; `יֵרֵד`; `שָׂמִים`, which is V1), no `!`, a number given as the answer followed by a full stop, no digits or symbols. Rare marks (qamatz qatan `כׇּל`) never go to a voice: `כל`.

**Counts.** 35 patterns, 71 strings, as in spec §5: **62 final new strings** (`text-ready`), **9 reused** (H3, H8a/b, H13a/b, H19a/b, H34 ×2). Also **13 extra strings** that the spec's patterns cannot do without (X1a, X1b, X1c ×3, X2, X3a, X3b, X4a, X4b, X5, X6 and the SHP-A-03 sort line; all `text-ready`), and **4 `proposed`** (P1 to P4, the two Band A "לֹא" lines, one of them split by the sorting rule).

---

## 1. Spec §5: the new strings H1 to H35

### 1a. Numbers

| Key | Gloss | ui_text | voice_text | Gender rule | Examples | Status | Note |
|---|---|---|---|---|---|---|---|
| H1a | 3 birds in the nest, all flew away; how many are left? (NUM-A-14, Band A) | הָיוּ שָׁלוֹשׁ צִפֳּרִים בַּקֵּן, וְכֻלָּן עָפוּ. כַּמָּה נִשְׁאֲרוּ? | היו שָׁלוֹשׁ ציפורים בקן, וכולן עפו. כמה נשארו? | `qty(n, obj)` (the number agrees with the noun); `כֻּלָּן` for a feminine noun, `כֻּלָּם` for a masculine one; `עָפוּ` and `נִשְׁאֲרוּ` are the same for both genders | `הָיוּ שְׁתֵּי צִפֳּרִים בַּקֵּן, וְכֻלָּן עָפוּ.`; `הָיוּ אַרְבַּע צִפֳּרִים…` | text-ready | the answer is 0; the options are bare numbers (`אֶפֶס`, `אַחַת`, `שָׁלוֹשׁ`) |
| H1b | 2 fish, all swam away; how many are left? | הָיוּ כָּאן שְׁנֵי דָּגִים, וְכֻלָּם שָׂחוּ רָחוֹק. כַּמָּה נִשְׁאֲרוּ? | היו כאן שְׁנֵי דגים, וכולם שָׂחוּ רחוק. כמה נשארו? | as H1a (`כֻּלָּם`, masculine) | `הָיוּ כָּאן שְׁלוֹשָׁה דָּגִים, וְכֻלָּם שָׂחוּ רָחוֹק.` | text-ready | the draft's `שָׂחוּ לְהֵרָחֵק` is the wrong-word case fixed in notes §2.6; `שָׂחוּ` stays pointed in the voice text (homograph) |
| H2 | A friend wrote numbers and there is a mistake. Where? (NUM-A-08 spots, mirror numerals) | חָבֵר כָּתַב מִסְפָּרִים, וְיֵשׁ בָּהֶם טָעוּת. אֵיפֹה הַטָּעוּת? | חבר כתב מספרים, ויש בהם טעות. איפה הטעות? | none | | text-ready | built on NUM-B-11's line (`b.numb11.1` prompt), with `כָּתַב` in place of `סָפַר` because the mistake is a wrongly written numeral (2 shown as 5). The draft's `סִדֵּר … וְטָעָה` blamed the friend and said "ordered", which is not the error |
| H3 | Which number is smaller? (NUM-B-10) | אֵיזֶה מִסְפָּר קָטָן יוֹתֵר? | איזה מספר קטן יותר? | | | reused | `activity.b.numb10.5` › `prompt.caption.0.v` |
| H4 (×4) | {2 apples} in the basket and {4} outside; how many in all? (NUM-B-14, MATH-B-02) | יֵשׁ שְׁנֵי תַּפּוּחִים בַּסַּל, וְאַרְבָּעָה תַּפּוּחִים בַּחוּץ. כַּמָּה יֵשׁ בְּסַךְ הַכֹּל? | יש שְׁנֵי תפוחים בסל, וְאַרְבָּעָה תפוחים בחוץ. כמה יש בסך הכול? | `qty(a, obj)` and `qty(b, obj)`; **the noun is said twice** (Q8: never a masculine number without its noun; the draft's bare `{אַרְבָּעָה}` broke this); the vav of the second number by `NumWords.vav` (`וּ` before a shva: `וּשְׁנֵי`, `וּשְׁלוֹשָׁה`; `וַ` before a hataf: `וַחֲמִשָּׁה`; otherwise `וְ`, no dagesh: `וְתִשְׁעָה`) | NUM-B-14: `יֵשׁ אַרְבָּעָה תַּפּוּחִים בַּסַּל, וּשְׁנֵי תַּפּוּחִים בַּחוּץ.` MATH-B-02: `יֵשׁ שְׁלוֹשָׁה תַּפּוּחִים בַּסַּל, וְשִׁשָּׁה תַּפּוּחִים בַּחוּץ.` Feminine noun: `יֵשׁ שְׁתֵּי צִפֳּרִים בַּסַּל, וְחָמֵשׁ צִפֳּרִים בַּחוּץ.` | text-ready | 12 words. The correct line and h3 follow NUM-B-14's existing pattern, with the numbers feminine (D7) |
| H34 (×2) | Ten and {four}. Which number? (NUM-B-16 check) | עֶשֶׂר וְעוֹד אַרְבַּע. כַּמָּה זֶה? | עֶשֶׂר ועוד אַרְבַּע. כמה זה? | numbers alone, feminine (`F[k]`) | `עֶשֶׂר וְעוֹד שֶׁבַע. כַּמָּה זֶה?` | reused | the pattern of `b.mathb03.1` and `b.mathb08.*` (`X וְעוֹד Y. כַּמָּה זֶה?`); see also §3 below |

### 1b. Colours, computer science

| Key | Gloss | ui_text | voice_text | Gender rule | Examples | Status | Note |
|---|---|---|---|---|---|---|---|
| H6 (×15) | A friend collects only {red ones}; what got in by mistake? (spots in COL, LOG-A-01, SHP) | חָבֵר אוֹסֵף רַק אֲדֻמִּים. מָה הִגִּיעַ לְכָאן בְּטָעוּת? | חבר אוסף רק אדומים. מה הגיע לכאן בטעות? | the slot is a plural. A colour is an adjective: masculine plural when the things in the row are masculine or mixed (balls, balloons, flowers: all masculine), feminine plural only when all are feminine (`אֲדֻמּוֹת`). A shape or object is its plural noun | slot words (ui / voice): `אֲדֻמִּים` / אדומים, `כְּחֻלִּים` / כחולים, `כְּתֻמִּים` / כתומים, `שְׁחֹרִים` / שחורים, `חוּמִים` / חומים, `אֲפֹרִים` / אפורים, `תַּפּוּחִים` / תפוחים, `בַּרְוָזִים` / ברווזים, `עִגּוּלִים` / עיגולים, `רִבּוּעִים` / ריבועים, `מְשֻׁלָּשִׁים` / משולשים, `מַלְבֵּנִים` / מלבנים, `מְחֻמָּשִׁים` / מחומשים, `צוּרוֹת סְגוּרוֹת` / צורות סגורות, `גְּלִילִים` / גלילים | text-ready | The second sentence is the **owner-approved** Band A question of D11 (`cs.wrong.*`), so Band A and Band B spots share one question clip. The draft's `אָסַף רַק אֲדֻמִּים … אֵיפֹה הַטָּעוּת?` said he collected only red ones, which contradicts the mistake; `אוֹסֵף` (is collecting) does not. `אוּפְּס` was dropped (the pack spells it `אוֹפְּס`, a V1 homograph, and the line is calmer without it). 7 words |
| H7a | Is this a banana? (green banana, tick/cross, COL-A-05) | זוֹ בָּנָנָה? | זו בננה? | `זוֹ` for a feminine noun, `זֶה` for a masculine one | | text-ready | the h3 for a tick answer must be `לִלְחֹץ עַל הַוִּי`, not `עָלָיו`. Note the existing `col.world.banana` h3 has `זֹאת`; the pack's standard is `זוֹ` (notes §2.3), so that row should be changed |
| H7b | Is this an apple? | זֶה תַּפּוּחַ? | זה תפוח? | as H7a | | text-ready | |
| H8a | Red and which colour make orange? (COL-B-01 reverse) | אָדֹם וְ… נַעֲשִׂים כָּתֹם. מָה חָסֵר? | אדום ועוד צבע… נעשים כתום. מה חסר? | | | reused | `activity.b.colb01.7` › prompt. **For the curriculum-expert:** COL-B-01 already has these reverse items (`b.colb01.7`, `.8`, `.9`); a relabel to chk `reverse` may be enough, so no new items are needed |
| H8b | Blue and which colour make green? | כָּחֹל וְ… נַעֲשִׂים יָרֹק. מָה חָסֵר? | כחול ועוד צבע… נעשים ירוק. מה חסר? | | | reused | `activity.b.colb01.8` › prompt |
| H9a | A friend sorted by colour and one shape is in the wrong place; where? (COL-B-04, LOG-B-06, Band B) | חָבֵר מִיֵּן לְפִי צֶבַע, וְצוּרָה אַחַת לֹא בַּמָּקוֹם שֶׁלָּהּ. אֵיפֹה הַטָּעוּת? | חבר מִיֵּן לפי צבע, וצורה אַחַת לא במקום שלה. איפה הטעות? | `צוּרָה אַחַת … שֶׁלָּהּ` (feminine: the cells are shapes) | | text-ready | Band B, so `לֹא` is allowed. `וְצוּרָה`: the צ has a vowel, not a shva, so the vav is `וְ`. 11 words |
| H9b | … sorted by shape … | חָבֵר מִיֵּן לְפִי צוּרָה, וְצוּרָה אַחַת לֹא בַּמָּקוֹם שֶׁלָּהּ. אֵיפֹה הַטָּעוּת? | חבר מִיֵּן לפי צורה, וצורה אַחַת לא במקום שלה. איפה הטעות? | as H9a | | text-ready | |
| H10 | A friend built a rainbow with a mistake; where? (COL-B-06) | חָבֵר בָּנָה קֶשֶׁת, וְיֵשׁ בָּהּ טָעוּת. אֵיפֹה הַטָּעוּת? | חבר בָּנָה קשת, ויש בה טעות. איפה הטעות? | `קֶשֶׁת` is feminine: `בָּהּ` | | text-ready | the draft said "one colour is in the wrong place", but in `[red, orange, purple, …]` the error is a wrong colour, not a wrong place |
| H11a | Brushing teeth: what do we do right after the paste? (CS-A-01) | מְצַחְצְחִים שִׁנַּיִם. מָה עוֹשִׂים מִיָּד אַחֲרֵי הַמִּשְׁחָה? | מצחצחים שיניים. מה עושים מיד אחרי המשחה? | | | text-ready | `מִיָּד` is needed: with three steps, "after the paste" is true of both the brush and the rinse |
| H11b | Washing hands: what do we do right after the soap? | רוֹחֲצִים יָדַיִם. מָה עוֹשִׂים מִיָּד אַחֲרֵי הַסַּבּוֹן? | רוחצים ידיים. מה עושים מיד אחרי הסבון? | | | text-ready (wording) | **The answer key is not mine; I am sending it to the curriculum-expert.** The pack teaches hand-washing as three steps, tap, soap, towel (`cs.routine.wash.*` h3: `קֹדֶם בָּרֶז, אַחַר כָּךְ סַבּוֹן, וּבַסּוֹף מַגֶּבֶת`), so a child who learned it says the towel comes right after the soap. The spec's right answer is "rinse" (a step the routine never shows), and it tags the towel M-SEQ-CAUSE. Either the routine gains a rinse step everywhere, or the right answer is the towel |
| H12 | How many steps to the flag? (CS-A-04, CS-B-01 predict) | כַּמָּה צְעָדִים מֵהָרוֹבּוֹט עַד הַדֶּגֶל? | כמה צעדים מהרובוט עד הדגל? | `צַעַד` is masculine: the correct line is `שָׁלוֹשׁ! שְׁלוֹשָׁה צְעָדִים עַד הַדֶּגֶל.` (with the noun), `צַעַד אֶחָד` for 1 | `אַרְבָּעָה צְעָדִים`, `שְׁנֵי צְעָדִים` | text-ready | `מֵהָרוֹבּוֹט` says where to start counting, which is the M-CS-OFF1 point (the start square does not count). No right or left, no speed |
| H13a | Is this how we brush teeth? Where is the mistake? (CS-A-05 spot) | מְצַחְצְחִים שִׁנַּיִם. מָה הִגִּיעַ לְכָאן בְּטָעוּת? | מצחצחים שיניים. מה הגיע לכאן בטעות? | | | reused | `activity.cs.wrong.teeth` › prompt (**owner-approved**); its h3 (`לְצִחְצוּחַ שִׁנַּיִם צְרִיכִים מִשְׁחָה, מִבְרֶשֶׁת וְכוֹס מַיִם…`) fits the spot too |
| H13b | … wash hands … | רוֹחֲצִים יָדַיִם. מָה הִגִּיעַ לְכָאן בְּטָעוּת? | רוחצים ידיים. מה הגיע לכאן בטעות? | | | reused | `activity.cs.wrong.wash` › prompt (**owner-approved**); h3 `לִרְחִיצַת יָדַיִם צְרִיכִים בָּרֶז, סַבּוֹן וּמַגֶּבֶת…` |

### 1c. Logic

| Key | Gloss | ui_text | voice_text | Gender rule | Examples | Status | Note |
|---|---|---|---|---|---|---|---|
| H14 | Put each one with the same thing (LOG-A-01 sort) | שָׂמִים יַחַד אֶת אוֹתוֹ הַדָּבָר: תַּפּוּחִים עִם תַּפּוּחִים, וְדָגִים עִם דָּגִים. | שָׂמִים יחד את אותו הדבר: תפוחים עם תפוחים, ודגים עם דגים. | the two plural nouns of the bins; the vav by its letter: `וּ` before ב, ו, מ, פ or a shva (`וּבַרְוָזִים`, with no dagesh in the ב), otherwise `וְ` with no dagesh (`וְדָגִים`) | `…: חֲתוּלִים עִם חֲתוּלִים, וּבַרְוָזִים עִם בַּרְוָזִים.` | text-ready | `אוֹתוֹ הַדָּבָר` is the skill's own word (`log.same.*` asks `אֵיפֹה אוֹתוֹ הַדָּבָר?`). The draft `כָּל אֶחָד עִם אוֹתוֹ הַדָּבָר` was unclear: "the same thing" as what? |
| H15 | Sort: big ones here, small ones here (LOG-A-03) | מְמַיְּנִים: גְּדוֹלִים לְכָאן, וּקְטַנִּים לְכָאן. | ממיינים: גדולים לכאן, וקטנים לכאן. | masculine plural (mixed objects) | | text-ready | the shape of COL-B-04's sort prompt; `וּקְטַנִּים` (vav before a shva) |
| H16 | The pattern repeats but has a mistake; where? (LOG-A-04, LOG-A-07 spots, Band A) | הַסֵּדֶר חוֹזֵר, אֲבָל יֵשׁ בּוֹ טָעוּת. אֵיפֹה הַטָּעוּת? | הסדר חוזר, אבל יש בו טעות. איפה הטעות? | | | text-ready | LOG-B-02's line (`b.logb02.1`) with its `לֹא` part (`אֶחָד מֵהֶם לֹא מַתְאִים`) replaced, so the Band A child hears the same frame as Band B later. The h3 for these spots is X5 |
| H17a | The chick came out; what happened just before? (LOG-A-08 reverse) | יָצָא אֶפְרוֹחַ. מָה הָיָה מִיָּד לִפְנֵי זֶה? | יצא אפרוח. מה היה מיד לפני זה? | | | text-ready | `רֶגַע לִפְנֵי` with no object (the draft) is slang. `מִיָּד` matches H11 |
| H17b | A flower grew; what happened just before? | צָמַח פֶּרַח. מָה הָיָה מִיָּד לִפְנֵי זֶה? | צָמַח פרח. מה היה מיד לפני זה? | | | text-ready | the draft's `הַפֶּרַח פָּרַח` says the same word twice. The answer label is the pack's `נֵבֶט` (`log.story.plant.*`) |
| H18 | A friend ordered the towers with a mistake; where? (LOG-B-11) | חָבֵר סִדֵּר אֶת הַמִּגְדָּלִים, וְיֵשׁ טָעוּת. אֵיפֹה הַטָּעוּת? | חבר סידר את המגדלים, ויש טעות. איפה הטעות? | | | text-ready | the same frame as NUM-B-11 and H2 (`וְיֵשׁ … טָעוּת`), with no `וְטָעָה` ("and he erred"). The h3 stays LOG-B-11's `מַתְחִילִים בַּנָּמוּךְ וְגוֹמְרִים בַּגָּבוֹהַּ` (or its reverse for `[5,4,4,2,1]`: `מַתְחִילִים בַּגָּבוֹהַּ וְגוֹמְרִים בַּנָּמוּךְ`) |

### 1d. Shapes, money and maths

| Key | Gloss | ui_text | voice_text | Gender rule | Examples | Status | Note |
|---|---|---|---|---|---|---|---|
| H19a | Build a train from shapes (SHP-A-06) | בּוֹנִים רַכֶּבֶת מִצּוּרוֹת. | בונים רכבת מצורות. | | | reused | `activity.shp.build.train` › prompt. **For the curriculum-expert:** SHP-A-06 already has a train and a tree (`shp.build.train`, `shp.build.tree`), so these are not new objects for a transfer. If new ones are wanted, `בּוֹנִים סִירָה מִצּוּרוֹת.` and `בּוֹנִים מְכוֹנִית מִצּוּרוֹת.` are ready in the same pattern (the design-director draws them) |
| H19b | Build a tree from shapes | בּוֹנִים עֵץ מִצּוּרוֹת. | בונים עץ מצורות. | | | reused | `activity.shp.build.tree` › prompt |
| H20 | Which shape has a curved line? (SHP-A-10) | לְאֵיזוֹ צוּרָה יֵשׁ קַו עָקֹם? | לאיזו צורה יש קו עקום? | `צוּרָה` is feminine: `אֵיזוֹ` | | text-ready | `קַו עָקֹם` is the skill's word (`shp.line.curved`) |
| H21 | Which solid leaves a circle in the sand? (SHP-B-09) | מַטְבִּיעִים בַּחוֹל, כְּמוֹ חוֹתֶמֶת. אֵיזֶה גּוּף מַשְׁאִיר עִגּוּל? | מטביעים בחול, כמו חותמת. איזה גוף משאיר עיגול? | `גּוּף` is masculine: `אֵיזֶה … מַשְׁאִיר` | | text-ready | **For the curriculum-expert:** a ball pressed into sand also leaves a round mark, so the sphere (tagged M-SHP-FACE) can look right to a child. The stamp frame (`מַטְבִּיעִים`, the word of the existing SHP-B-09 h3) points to a flat face and narrows this, but only a picture of the flat print in the options removes the doubt. Never the pyramid (F9): kept |
| H22a | Share {six apples} among the cat, the dog and the duck; all get the same (MATH-A-03) | מְחַלְּקִים שִׁשָּׁה תַּפּוּחִים בֵּין הֶחָתוּל, הַכֶּלֶב וְהַבַּרְוָז. לְכֻלָּם אוֹתוֹ מִסְפָּר. | מחלקים שִׁשָּׁה תפוחים בין החתול, הכלב והברווז. לכולם אותו מספר. | `qty(n, obj)` | `מְחַלְּקִים שִׁשָּׁה תַּפּוּחִים…`; feminine: `מְחַלְּקִים שֵׁשׁ חִפּוּשִׁיּוֹת…` | text-ready | the existing two-friend line (`math.share.*`: `לִשְׁנֵיהֶם אוֹתוֹ מִסְפָּר`) with three friends. The correct line must change too (X2). The existing h3 (`לְכׇל אֶחָד יֵשׁ אוֹתוֹ מִסְפָּר`) and fb.share_uneq fit three friends |
| H22b | … three fish … | מְחַלְּקִים שְׁלוֹשָׁה דָּגִים בֵּין הֶחָתוּל, הַכֶּלֶב וְהַבַּרְוָז. לְכֻלָּם אוֹתוֹ מִסְפָּר. | מחלקים שְׁלוֹשָׁה דגים בין החתול, הכלב והברווז. לכולם אותו מספר. | as H22a | | text-ready | |
| H23a | {3} coins, each apple costs one coin; how many apples? (MATH-A-06 reverse) | כׇּל תַּפּוּחַ עוֹלֶה מַטְבֵּעַ אֶחָד. יֵשׁ לָנוּ שְׁלוֹשָׁה מַטְבְּעוֹת. כַּמָּה תַּפּוּחִים אֶפְשָׁר לִקְנוֹת? | כל תפוח עולה מטבע אֶחָד. יש לנו שְׁלוֹשָׁה מטבעות. כמה תפוחים אפשר לקנות? | `מַטְבֵּעַ` is masculine (plural `מַטְבְּעוֹת`): `שְׁלוֹשָׁה / אַרְבָּעָה מַטְבְּעוֹת` | `…יֵשׁ לָנוּ אַרְבָּעָה מַטְבְּעוֹת…` | text-ready | the first sentence is the existing `math.shop.*` prompt, word for word. `יֵשׁ לָנוּ` (we) instead of the draft's `יֵשׁ לִי`: the helper and the children shop together. The correct line can reuse `math.shop.apples`: `שָׁלוֹשׁ! מַטְבֵּעַ אֶחָד לְכׇל תַּפּוּחַ.` |
| H23b | … {4} coins … | כׇּל תַּפּוּחַ עוֹלֶה מַטְבֵּעַ אֶחָד. יֵשׁ לָנוּ אַרְבָּעָה מַטְבְּעוֹת. כַּמָּה תַּפּוּחִים אֶפְשָׁר לִקְנוֹת? | כל תפוח עולה מטבע אֶחָד. יש לנו אַרְבָּעָה מטבעות. כמה תפוחים אפשר לקנות? | as H23a | | text-ready | |
| H24 (×2) | {3 apples}, more came, now {5}; how many came? (MATH-B-01 check) | יֵשׁ שְׁלוֹשָׁה תַּפּוּחִים. מוֹסִיפִים עוֹד, וְעַכְשָׁו יֵשׁ חֲמִשָּׁה תַּפּוּחִים. כַּמָּה הוֹסַפְנוּ? | יש שְׁלוֹשָׁה תפוחים. מוסיפים עוד, ועכשיו יש חֲמִשָּׁה תפוחים. כמה הוספנו? | `qty(x, obj)` and `qty(t, obj)`, the noun said twice (Q8; the draft's bare `{חֲמִשָּׁה}` broke this) | `יֵשׁ אַרְבָּעָה דָּגִים. מוֹסִיפִים עוֹד, וְעַכְשָׁו יֵשׁ שִׁבְעָה דָּגִים. כַּמָּה הוֹסַפְנוּ?` | text-ready | `בָּאוּ עוֹד` ("more came") does not fit apples; `מוֹסִיפִים` is MATH-B-01's own verb. 11 words |
| H25 (×2) | How much is {3} and {4}? (MATH-B-03, `? = 3 + 4`) | כַּמָּה שָׁוֶה שָׁלוֹשׁ וְעוֹד אַרְבַּע? | כמה שווה שָׁלוֹשׁ ועוד אַרְבַּע? | numbers alone, feminine | 2nd: `כַּמָּה שָׁוֶה תֵּשַׁע פָּחוֹת אַרְבַּע?` | text-ready | read in the written order (`?` first, then `=`), as MATH-B-18 reads `3 + ? = 7`. `=` is read `שָׁוֶה`, with no `לְ`, as everywhere in the pack |
| H26 (×2) | {7} shekels; how many more for ten? (MATH-B-06 transfer) | יֵשׁ לָנוּ שִׁבְעָה שְׁקָלִים. כַּמָּה עוֹד צָרִיךְ כְּדֵי שֶׁיִּהְיוּ לָנוּ עֲשָׂרָה שְׁקָלִים? | יש לנו שִׁבְעָה שקלים. כמה עוד צריך כדי שיהיו לנו עֲשָׂרָה שקלים? | `שֶׁקֶל` is masculine: `שִׁבְעָה / שִׁשָּׁה / עֲשָׂרָה שְׁקָלִים` (with the noun, Q8) | `יֵשׁ לָנוּ שִׁשָּׁה שְׁקָלִים. …` | text-ready | the draft's `שֶׁיִּהְיוּ עֲשָׂרָה` was a masculine number without its noun. The correct line follows MATH-B-06's pattern with the numbers feminine: `שָׁלוֹשׁ! שֶׁבַע וְעוֹד שָׁלוֹשׁ הֵם עֶשֶׂר.` |
| H27 (×2) | {Six ducks}, {two} on each plate; how many plates? (MATH-B-10 reverse) | יֵשׁ שִׁשָּׁה בַּרְוָזִים. עַל כׇּל צַלַּחַת שְׁנֵי בַּרְוָזִים. כַּמָּה צַלָּחוֹת? | יש שִׁשָּׁה ברווזים. על כל צלחת שְׁנֵי ברווזים. כמה צלחות? | `qty(n, obj)` twice (Q8: the draft's bare `{שְׁנַיִם}` broke this) | `יֵשׁ שְׁמוֹנֶה צִפֳּרִים. עַל כׇּל צַלַּחַת אַרְבַּע צִפֳּרִים. כַּמָּה צַלָּחוֹת?` | text-ready | the mirror of MATH-B-10's own prompt (`יֵשׁ שְׁתֵּי צַלָּחוֹת. עַל כׇּל צַלַּחַת…`). The correct line is X6 |
| H28 | Which side will go down? Guess, then see (MATH-B-13 predict) | אֵיזֶה צַד יֵרֵד לְמַטָּה? קֹדֶם מְנַחֲשִׁים, וְאַחַר כָּךְ רוֹאִים. | איזה צד יֵרֵד למטה? קודם מנחשים, ואחר כך רואים. | | | text-ready | `יוֹרֵד לְמַטָּה` is the h3's own word. No right or left (B-13). `יֵרֵד` stays pointed in the voice text |
| H29 | Which coin is worth more? (MATH-B-16) | אֵיזֶה מַטְבֵּעַ שָׁוֶה יוֹתֵר? | איזה מטבע שווה יותר? | | | text-ready | for the half-shekel item the correct line names it `חֲצִי שֶׁקֶל` (`כֵּן! שֶׁקֶל שָׁוֶה יוֹתֵר מֵחֲצִי שֶׁקֶל.`) |
| H30 | M-PART-MISS in a number sentence (G4, per item) | חִבַּרְנוּ אֶת שְׁנֵיהֶם, אֲבָל שֶׁבַע זֶה כְּבָר הַכֹּל. כַּמָּה מוֹסִיפִים לְשָׁלוֹשׁ כְּדֵי לְהַגִּיעַ לְשֶׁבַע? | חיברנו את שניהם, אבל שֶׁבַע זה כבר הכול. כמה מוסיפים לְשָׁלוֹשׁ כדי להגיע לְשֶׁבַע? | T = the whole, X = the part shown, both `F[...]`. The prefix `לְ` is pointed by the number (as for `÷`, Q10): `לִ` before a shva (`לִשְׁתַּיִם`, `לִשְׁמוֹנֶה`, `לִשְׁלֹשׁ עֶשְׂרֵה`), `לַ` before a hataf patah (`לַחֲמֵשׁ עֶשְׂרֵה`), otherwise `לְ` with no dagesh (`לְתֵשַׁע`, `לְאַרְבַּע`, `לְחָמֵשׁ`) | `3 + ? = 7`: as shown. `9 = 5 + ?`: `חִבַּרְנוּ אֶת שְׁנֵיהֶם, אֲבָל תֵּשַׁע זֶה כְּבָר הַכֹּל. כַּמָּה מוֹסִיפִים לְחָמֵשׁ כְּדֵי לְהַגִּיעַ לְתֵשַׁע?` | text-ready | The draft said "after the equals sign is the whole", but in the other orientation (H31, `7 = 3 + ?`) the whole comes *before* the sign, so the line names the number instead. It ends in the count-on strategy of D2. No `לֹא`. Also covers MATH-B-07 and B-08 (`6 + ? = 6` → `לְשֵׁשׁ כְּדֵי לְהַגִּיעַ לְשֵׁשׁ`) |
| H31 (×2) | {7} equals {3} and how many? (MATH-B-18, other orientation) | שֶׁבַע שָׁוֶה שָׁלוֹשׁ וְעוֹד כַּמָּה? | שֶׁבַע שווה שָׁלוֹשׁ ועוד כמה? | numbers alone, feminine | 2nd: `תֵּשַׁע שָׁוֶה חָמֵשׁ וְעוֹד כַּמָּה?` | text-ready | mirrors the existing `שָׁלוֹשׁ וְעוֹד כַּמָּה שָׁוֶה שֶׁבַע?` |
| H32 (×2) | In which column are there {5}? (MATH-B-19 reverse; the options are the column pictures) | מִמָּה יֵשׁ בְּדִיּוּק חָמֵשׁ? | ממה יש בדיוק חָמֵשׁ? | number alone, feminine | 2nd: `מִמָּה יֵשׁ בְּדִיּוּק שָׁלוֹשׁ?` | text-ready | MATH-B-19's own frame (`מִמָּה יֵשׁ הֲכִי הַרְבֵּה?`), because the child taps a picture, not a column. `בְּדִיּוּק` keeps the 6 column (tagged M-CNT-DOUBLE) from looking right ("it has five too") |
| H35 (×3) | Where is the {yellow} shape? (COL-A-02, 03 transfer) | אֵיפֹה הַצּוּרָה הַצְּהֻבָּה? | איפה הצורה הצהובה? | `צוּרָה` is feminine: the feminine adjective, with the article | `הַיְרֻקָּה` (no dagesh in a yod with a shva, as in the pack's `הַנְּקֻדָּה הַיְרֻקָּה`), `הַכְּתֻמָּה`; voice הירוקה, הכתומה | text-ready | the h3 is `זֶה עִגּוּל צָהֹב.` / `זֶה רִבּוּעַ יָרֹק.` (the shape is masculine) `… לִלְחֹץ עָלָיו.` |

H33a, H33b and H34 are in §3 (spec §4). H5 does not exist in the spec.

---

## 2. Spec §1 "pattern" rows: agreement checks and the strings the patterns lack

The spec says "pattern" where an existing prompt takes new values. I checked every row where a new value changes the grammar. **New nouns** that the generator's `OBJECTS` lacks (each needs `g`, `one` and `many`): `frog` {f, `צְפַרְדֵּעַ`, `צְפַרְדְּעִים`}; `chick` {m, `אֶפְרוֹחַ`, `אֶפְרוֹחִים`}; `butterfly` {m, `פַּרְפָּר`, `פַּרְפָּרִים`} (in the pack only as hand-written lines); `shoe` {f, `נַעַל`, `נַעֲלַיִם`}. The prefix `בְּ` in the count hint (G4) goes `בִּצְפַרְדֵּעַ אַחַת` (before a shva), `בְּאֶפְרוֹחַ אֶחָד`, `בְּפַרְפָּר אֶחָד` (no dagesh), `בְּנַעַל אַחַת`.

| Key | Rows | ui_text (pattern) | voice_text | Gender rule | Examples | Status | Note |
|---|---|---|---|---|---|---|---|
| X1a | NUM-A-11, NUM-A-12, MATH-A-07 compare with **unlike** objects (prompt) | יֵשׁ יוֹתֵר צְפַרְדְּעִים אוֹ יוֹתֵר אֶפְרוֹחִים? | יש יותר צפרדעים או יותר אפרוחים? | the two plural nouns; `פָּחוֹת` for "fewer" | `יֵשׁ פָּחוֹת אֶפְרוֹחִים אוֹ פָּחוֹת צְפַרְדְּעִים?` | text-ready | The existing `אֵיפֹה יֵשׁ יוֹתֵר {many}?` names one noun, so it cannot be used for two kinds. 6 words |
| X1b | same (correct line) | כֵּן! יֵשׁ יוֹתֵר צְפַרְדְּעִים. | כן, יש יותר צפרדעים. | | | text-ready | the h3 keeps the existing pattern with two nouns: `בְּצַד אֶחָד יֵשׁ אַרְבַּע צְפַרְדְּעִים, וּבַצַּד הָאַחֵר שְׁלוֹשָׁה אֶפְרוֹחִים. …` (each number agrees with its own noun) |
| X1c | the D1 size lines (M-CNT-SIZE) on a **feminine** set | הֵן גְּדוֹלוֹת, אֲבָל כַּמָּה יֵשׁ? בּוֹאוּ נִסְפֹּר. / הֵן קְטַנּוֹת, אֲבָל כַּמָּה יֵשׁ? בּוֹאוּ נִסְפֹּר. / הֵן רְחוֹקוֹת זוֹ מִזּוֹ, אֲבָל כַּמָּה יֵשׁ? בּוֹאוּ נִסְפֹּר. | הן גדולות, אבל כמה יש? בואו נספור. (and the same for the other two) | the tag line is chosen by the gender of the picked set: `vo:fb.size.big.f`, `.small.f`, `.spread.f` | NUM-A-12: 3 frogs at `scale 1.5` → `הֵן גְּדוֹלוֹת…` | text-ready | **The shared clip `הֵם גְּדוֹלִים` is wrong for frogs.** Three extra clips, or else the curriculum-expert draws the big or spread set from a masculine noun (chicks, ducks) |
| X2 | MATH-A-03 three friends (correct line) | כֵּן! לְכֻלָּם יֵשׁ אוֹתוֹ מִסְפָּר. | כן, לכולם יש אותו מספר. | | | text-ready | the existing `לִשְׁנֵיהֶם` ("both") is wrong for three |
| X6 | MATH-B-10 reverse (correct line) | שָׁלוֹשׁ צַלָּחוֹת! שְׁתַּיִם וְעוֹד שְׁתַּיִם וְעוֹד שְׁתַּיִם הֵם שֵׁשׁ. | שָׁלוֹשׁ צלחות. שְׁתַּיִם ועוד שְׁתַּיִם ועוד שְׁתַּיִם הם שֵׁשׁ. | the answer with its noun (`צַלַּחַת` f: `שְׁתֵּי / שָׁלוֹשׁ צַלָּחוֹת`), then the sum feminine | `שְׁתֵּי צַלָּחוֹת! אַרְבַּע וְעוֹד אַרְבַּע הֵם שְׁמוֹנֶה.` | text-ready | MATH-B-10's correct pattern turned around |

Agreement rules for the other pattern rows (no new wording; the generator must choose the form):

- **flash** (NUM-A-05, 10): `הִסְתַּכְּלוּ טוֹב… כַּמָּה צְפַרְדְּעִים?`; h3 `אֵלֶּה שְׁתֵּי צְפַרְדְּעִים.` / `אֵלֶּה שְׁלוֹשָׁה אֶפְרוֹחִים.`; one: `זוֹ צְפַרְדֵּעַ אַחַת.` / `זֶה אֶפְרוֹחַ אֶחָד.`
- **madd / mtake** (MATH-A-01, 02): `יֵשׁ שְׁתֵּי צְפַרְדְּעִים. מוֹסִיפִים עוֹד שְׁתֵּי צְפַרְדְּעִים.`; the story hint says the noun again (D7): `שְׁלוֹשָׁה אֶפְרוֹחִים וְעוֹד אֶפְרוֹחַ אֶחָד`, `אַרְבַּע צְפַרְדְּעִים, וְלוֹקְחִים צְפַרְדֵּעַ אַחַת`.
- **ordinal** (NUM-A-13): the correct line and h3 follow the answer's gender: `זֶה הַשֵּׁנִי בַּתּוֹר` (chick) but `זוֹ הַשְּׁנִיָּה / הָרִאשׁוֹנָה / הָאַחֲרוֹנָה בַּתּוֹר … לִלְחֹץ עָלֶיהָ` (frog, bird). With the queue [frog, chick, bird, fish] the two answers (chick, fish) are masculine.
- **k_pick h3** (`{r}. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו.`): `עָלֶיהָ` when the answer is a feminine thing; `לִלְחֹץ עַל הַוִּי` for a tick.
- **NUM-B-18 shoes**: `אֶפְשָׁר לְחַלֵּק אֶת כֻּלָּן לְזוּגוֹת, בְּלִי שֶׁתִּשָּׁאֵר אַחַת לְבַד?`, correct `כֵּן, כֻּלָּן בְּזוּגוֹת.` (`כֻּלָּם / כֻּלָּן`, `אֶחָד / אַחַת`, `יִשָּׁאֵר / תִּשָּׁאֵר` by the noun).
- **NUM-B-05 give**: `תְּנוּ לִי שְׁנֵים עָשָׂר דָּגִים.` (12 before a masculine noun is `שְׁנֵים עָשָׂר`, not `שְׁנֵי עָשָׂר`), `תְּנוּ לִי שֵׁשׁ עֶשְׂרֵה צִפֳּרִים.`
- **LOG-A-09 pairs**: `מָה הוֹלֵךְ עִם הַצַּלַּחַת?` → `כֵּן! זוֹ כַּף.`, h3 `צַלַּחַת וְכַף הוֹלְכוֹת יַחַד.` (two feminine nouns, G5); `מָה הוֹלֵךְ עִם הֶעָנָן?` → `כֵּן! זֶה גֶּשֶׁם.`, h3 `עָנָן וְגֶשֶׁם הוֹלְכִים יַחַד.` (no dagesh after `וְ`).
- **SHP-A-07 solids (Band A)**: `solid_box` is **`קֻפְסָה`** in Band A (Q7, D6); the generator's `NAMES['solid_box']` says `תֵּבָה` and must not be used for a Band A item (`כֵּן! זוֹ קֻפְסָה.`, `… לִלְחֹץ עָלֶיהָ.`).
- **SHP-A-03 sort**: COL-B-04's line **without** `עַכְשָׁו` (in COL-B-04 it follows a colour sort; here it is the first sort): `מְמַיְּנִים לְפִי צוּרָה: עִגּוּלִים לְכָאן, וְרִבּוּעִים לְכָאן.` (voice: ממיינים לפי צורה: עיגולים לכאן, וריבועים לכאן.) text-ready.
- **CS-A-03 robot boards (Band A)**: the h3 keeps D10 (`N צְעָדִים לְכִוּוּן הַדֶּגֶל`, never `יָמִינָה / שְׂמֹאלָה`), also on the new 4 × 2 board.
- **MATH-B-07 reverse** (`6 + ? = 6`): the prompt follows MATH-B-18 (`שֵׁשׁ וְעוֹד כַּמָּה שָׁוֶה שֵׁשׁ?`), but MATH-B-18's D2 hints cannot be used with 0 (`מוֹסִיפִים אַחַת אַחַת עַד שֵׁשׁ`, `הֵרַמְנוּ אֶפֶס אֶצְבָּעוֹת`). Use X3 instead.

| Key | Rows | ui_text | voice_text | Gender rule | Examples | Status | Note |
|---|---|---|---|---|---|---|---|
| X3a | MATH-B-07 reverse, hint 2 | שֵׁשׁ כְּבָר יֵשׁ. כַּמָּה צָרִיךְ לְהוֹסִיף כְּדֵי לְהַגִּיעַ לְשֵׁשׁ? | שֵׁשׁ כבר יש. כמה צריך להוסיף כדי להגיע לְשֵׁשׁ? | `F[n]`, `לְ` pointed as in H30 | `אַרְבַּע כְּבָר יֵשׁ. … לְהַגִּיעַ לְאַרְבַּע?` | text-ready | |
| X3b | MATH-B-07 reverse, hint 3 | שֵׁשׁ כְּבָר יֵשׁ, אָז לֹא מוֹסִיפִים כְּלוּם. אֵין כְּלוּם — זֶה אֶפֶס. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אֶפֶס. | שֵׁשׁ כבר יש, אז לא מוסיפים כלום. אין כלום — זה אֶפֶס. עכשיו תורכם — ללחוץ על אֶפֶס. | `F[n]` | `אַרְבַּע כְּבָר יֵשׁ, אָז…` | text-ready | Band B, so `לֹא` is allowed. `אֵין כְּלוּם — זֶה אֶפֶס` is the pack's own phrase |

**Spot hint 3 per item** (the spec: "the right count words + עַכְשָׁו תּוֹרְכֶם"):

| Key | Rows | ui_text (pattern) | voice_text | Rule | Examples | Status | Note |
|---|---|---|---|---|---|---|---|
| X4a | number spots counting up (NUM-A-01, 02, 03, 08; Band A and B) | נִסְפֹּר יַחַד: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. עַכְשָׁו תּוֹרְכֶם. | נספור יחד: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. עכשיו תורכם. | `F[...]` for the right numbers from the first cell to the last, in the row's order | `[6,7,9,9,10]` → `נִסְפֹּר יַחַד: שֵׁשׁ, שֶׁבַע, שְׁמוֹנֶה, תֵּשַׁע, עֶשֶׂר. עַכְשָׁו תּוֹרְכֶם.` | text-ready | replaces NUM-B-11's h3 for these skills (it has `לֹא`) |
| X4b | number spots counting **down** (NUM-B-03) | נִסְפֹּר אֲחוֹרָה: עֶשֶׂר, תֵּשַׁע, שְׁמוֹנֶה, שֶׁבַע, שֵׁשׁ. עַכְשָׁו תּוֹרְכֶם. | נספור אחורה: עֶשֶׂר, תֵּשַׁע, שְׁמוֹנֶה, שֶׁבַע, שֵׁשׁ. עכשיו תורכם. | as X4a, in falling order | `[8,7,6,4,4]` → `נִסְפֹּר אֲחוֹרָה: שְׁמוֹנֶה, שֶׁבַע, שֵׁשׁ, חָמֵשׁ, אַרְבַּע. …` | text-ready | **NUM-B-11's h3 (`הַמִּסְפָּרִים גְּדֵלִים בְּאֶחָד…`) is false for a falling row** and must not be used for NUM-B-03 |
| X5 | pattern spots (LOG-A-04, 07; H16) | חָתוּל, כֶּלֶב, חָתוּל, כֶּלֶב, חָתוּל, כֶּלֶב — כָּכָה הַסֵּדֶר חוֹזֵר. עַכְשָׁו תּוֹרְכֶם. | חתול, כלב, חתול, כלב, חתול, כלב — ככה הסדר חוזר. עכשיו תורכם. | the right row, each cell by its `one` name (with its colour for balls: `כַּדּוּר צָהֹב`) | `[ball_yellow, ball_blue, …]` → `כַּדּוּר צָהֹב, כַּדּוּר כָּחֹל, כַּדּוּר צָהֹב, …` | text-ready | Band A, no `לֹא` |

---

## 3. Spec §4: the B-27 items (NUM-B-16, MATH-B-18)

| Key | Gloss | ui_text | voice_text | Gender rule | Examples | Status | Note |
|---|---|---|---|---|---|---|---|
| H33a | hint 2, frames: the full frame is ten; count only the other one | בַּמִּסְגֶּרֶת הַמְּלֵאָה יֵשׁ עֶשֶׂר. נִסְפֹּר רַק אֶת הַמִּסְגֶּרֶת הָאַחֶרֶת. | במסגרת המלאה יש עֶשֶׂר. נספור רק את המסגרת האחרת. | | | text-ready | `יֵשׁ עֶשֶׂר` (there are ten) instead of the draft's "is ten". `הָאַחֶרֶת` instead of `הַשְּׁנִיָּה`: on an RTL screen "the second" frame is not clear, and `השנייה` is a homograph for a voice |
| H33b | hint 2, fingers: ten fingers and some more; how many more? | עֶשֶׂר אֶצְבָּעוֹת, וְעוֹד כַּמָּה? נִסְפֹּר רַק אֶת הָאֶצְבָּעוֹת שֶׁאַחֲרֵי הָעֶשֶׂר. | עֶשֶׂר אצבעות, ועוד כמה? נספור רק את האצבעות שאחרי הָעֶשֶׂר. | `אֶצְבַּע` is feminine: `עֶשֶׂר אֶצְבָּעוֹת` | | text-ready | the draft's `וְעוֹד קְצָת` is vague; the new line gives the strategy |
| H34 | check: ten and {four}, which number? | (see 1a: reused `X וְעוֹד Y. כַּמָּה זֶה?`) | | | | reused | |
| H30 | MATH-B-18's M-PART-MISS line | (see 1d) | | | | text-ready | |

Spec §3 (tags) adds no new text. Its lines are the existing `vo:fb.*`, apart from fb.size (X1c) and fb.sort_shift (P2 to P4).

---

## 4. Spec §5, last paragraph: the two reused lines with "לֹא" in Band A

The generator keeps today's line for Band A until the owner decides. Each Band A form below needs its own vo id; the Band B line stays as it is.

| Key | Today (Band A uses it) | Proposed Band A ui_text | voice_text | Status | Note |
|---|---|---|---|---|---|
| P1 `k_spot` default h3 | אֶחָד מֵהֶם לֹא מַתְאִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | כֻּלָּם דּוֹמִים, חוּץ מֵאֶחָד. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | כולם דומים, חוץ מֵאֶחָד. עכשיו תורכם — ללחוץ עליו. | proposed | Says what is true, with no `לֹא`. With H6 the slot can name the rule: `כֻּלָּם אֲדֻמִּים, חוּץ מֵאֶחָד.`, `כֻּלָּם עִגּוּלִים, חוּץ מֵאֶחָד.`; a feminine slot: `כֻּלָּן צוּרוֹת סְגוּרוֹת, חוּץ מֵאַחַת. … לִלְחֹץ עָלֶיהָ.` Number and pattern spots use X4 and X5 instead. Band B keeps today's line |
| P2 fb.sort_shift, **colour rule** (COL-A-01 new, COL-A-04 today) | מְחַפְּשִׂים אֶת אוֹתוֹ צֶבַע, לֹא אוֹתוֹ דָּבָר. בּוֹאוּ נִבְדֹּק. | זֶה אוֹתוֹ דָּבָר, אֲבָל מְחַפְּשִׂים אֶת אוֹתוֹ הַצֶּבַע. בּוֹאוּ נִבְדֹּק. | זה אותו דבר, אבל מחפשים את אותו הצבע. בואו נבדוק. | proposed | Built like the owner's Q2 lines: it names what the eye caught, then ends in the strategy. **The line already plays in Band A today** (COL-A-04 `col.sort.*`, LOG-A-03 `log.sort.*`), not only in the new COL-A-01 items |
| P3 fb.sort_shift, **kind rule** (LOG-A-01 spots, LOG-A-03) | (same line) | זֶה אוֹתוֹ צֶבַע, אֲבָל מְחַפְּשִׂים אֶת אוֹתוֹ הַדָּבָר. בּוֹאוּ נִבְדֹּק. | זה אותו צבע, אבל מחפשים את אותו הדבר. בואו נבדוק. | proposed | **Today's line teaches the wrong thing here.** LOG-A-03 (`לְאָן הוֹלֵךְ הַכֶּלֶב?`) and LOG-A-01 spots sort by *kind*, and a child who sorted by colour hears "we look for the same colour". This needs the curriculum-expert's agreement too |
| P4 fb.sort_shift, **shape rule** (SHP-A-02 spots) | (same line) | זֶה אוֹתוֹ צֶבַע, אֲבָל מְחַפְּשִׂים אֶת אוֹתָהּ הַצּוּרָה. בּוֹאוּ נִבְדֹּק. | זה אותו צבע, אבל מחפשים את אותה הצורה. בואו נבדוק. | proposed | as P3 (`צוּרָה` is feminine: `אוֹתָהּ`). A Band B shape rule (COL-B-04, LOG-B-06) would take the same split; Band B can keep `לֹא` |

---

## 5. For the other agents

**Curriculum-expert** (wording that I cannot fix without changing what is taught):
1. H11b: the answer "rinse" against the pack's three-step hand-washing routine (tap, soap, towel).
2. H21: the sphere can look right (a ball leaves a round mark too).
3. P3 and P4: the fb.sort_shift line is about colour, but LOG-A-01, LOG-A-03 and SHP-A-02 are tagged M-SORT-SHIFT for kind and shape rules.
4. Items that already exist: COL-B-01 reverse (`b.colb01.7` to `.9`); SHP-A-06 train and tree; COL-B-03 purple (`b.colb03.7` `אֵיפֹה עוֹד סָגֹל?`); LOG-B-09 "not green and not circle" (`b.logb09.6`).
5. X1c: frogs as the big or spread set need feminine size lines, or swap in a masculine noun.

**App-developer:** add the four nouns to `OBJECTS` (§2); choose forms by gender as listed; give each P- and X-line its own vo id; never use NUM-B-11's spot h3 outside counting-up rows. While reading I also saw `בַּקְעָרָה` in `nonzero.bowl.*`, which should be `בַּקְּעָרָה`; it is outside this spec, so I recorded it here and changed nothing.

**Voice director** (after the owner approves): the lines to watch are H30 (14 words, two numbers with a prefix: a breath at the comma) and X3b and X4 (number lists: the commas are the breaths). The homographs kept pointed are `שָׂחוּ`, `צָמַח`, `בָּנָה`, `מִיֵּן`, `יֵרֵד` and `שָׂמִים`.

---

## 6. After the curriculum addendum

Hebrew text editor, 2026-10-30, after the curriculum-expert's `## Addendum after the Hebrew pass` (A1 to A6) in `docs/knowledge/b15-content-spec.md`. Same rules and statuses as above. Every string below is final for the screen and the voice, written by hand (nothing made by a model), and goes into the pack as `"review": "needs-editor"`. `reused` = the generator copies an existing row; no new string. Checked against the generators (`tools/author.py`, `tools/band_b*.py`) and the unit `names` and `objects`, so each row is what the generator prints once the new values are in.

**Correction to §2.** `butterfly` is **`פַּרְפַּר`** (patah under the second pe) in the singular; only the plural takes qamatz, `פַּרְפָּרִים` (ר takes no dagesh, so the patah lengthens). §2 and A6 wrote `פַּרְפָּר`; the forms in this section replace them. The prefix is `בְּפַרְפַּר אֶחָד` (no dagesh after `בְּ`). See 6.7 for the 9 existing rows with the same slip.

### 6.1 CS-A-01 hands (A1: the answer is the towel)

| id | where | nikud text (ui_text) | voice_text | status | note |
|---|---|---|---|---|---|
| H11b (revised) | CS-A-01 hands, prompt | רוֹחֲצִים יָדַיִם. מָה עוֹשִׂים אַחֲרֵי הַסַּבּוֹן? | רוחצים ידיים. מה עושים אחרי הסבון? | text-ready | **`מִיָּד` comes out** for hands. Teeth needed it (after the paste come both the brush and the rinse). In the hands routine only the towel comes after the soap, so the question is already exact. Also "right after the soap we dry" is not what a child does at the sink (you rinse first), so `מִיָּד` would push a thinking child towards the tap. H11a (teeth) keeps `מִיָּד`. 5 words |
| H11b-c | CS-A-01 hands, correct line | כֵּן! אַחֲרֵי הַסַּבּוֹן מְיַבְּשִׁים בְּמַגֶּבֶת. | כן, אחרי הסבון מייבשים במגבת. | text-ready | as A1 proposes. Checked: `מְיַבְּשִׁים` (plural present, no subject, as `cs.routine.wash.last`'s `בַּסּוֹף מְיַבְּשִׁים בְּמַגֶּבֶת`); `בְּמַגֶּבֶת` with no dagesh in the מ. It answers the prompt in its own words ("after the soap") |
| — | options | מַגֶּבֶת / בָּרֶז / סַבּוֹן | | reused | the labels of `cs.routine.wash.*` (`robots.json` names) |
| — | h3 | `cs.routine.wash.last`'s h3, word for word (`קֹדֶם בָּרֶז, אַחַר כָּךְ סַבּוֹן, וּבַסּוֹף מַגֶּבֶת. … לִלְחֹץ עַל הַמַּגֶּבֶת.`) | | reused | it ends on the towel, so it fits the new answer |

For the curriculum-expert (not a wording issue, so I changed nothing): the tap is tagged M-SEQ-CAUSE ("the step before"), but in life you rinse under the tap after the soap. Dropping `מִיָּד` helps; only the picture settles it (the tap should look like "opening the tap", the start of the routine).

### 6.2 SHP-A-06 boat and car (A3)

| id | where | nikud text (ui_text) | voice_text | status | note |
|---|---|---|---|---|---|
| H19c | SHP-A-06 boat, prompt | בּוֹנִים סִירָה מִצּוּרוֹת. | בונים סירה מצורות. | text-ready | `k_shapebuild` prompt pattern (`בּוֹנִים %s מִצּוּרוֹת.`) |
| H19c-c | boat, correct line | כֵּן! בְּנִיתֶם סִירָה. | כן, בניתם סירה. | text-ready | `k_shapebuild` correct pattern; nothing agrees with the noun |
| H19d | SHP-A-06 car, prompt | בּוֹנִים מְכוֹנִית מִצּוּרוֹת. | בונים מכונית מצורות. | text-ready | |
| H19d-c | car, correct line | כֵּן! בְּנִיתֶם מְכוֹנִית. | כן, בניתם מכונית. | text-ready | |
| — | hints 1 to 3 | the shared `shapebuild` hints (`לְכׇל צוּרָה יֵשׁ מָקוֹם אֶחָד, כְּמוֹ הַצֵּל שֶׁלָּהּ.` …) | | reused | |

### 6.3 Compare items with the new masculine nouns (A4)

`k_compare_more` with `obj` chick (`אֶפְרוֹחַ` / `אֶפְרוֹחִים`, m) or butterfly (`פַּרְפַּר` / `פַּרְפָּרִים`, m). The numbers are masculine (`qty`), with `שְׁנֵי` before the noun for 2. The size lines `vo:fb.size.big / .small / .spread` (`הֵם גְּדוֹלִים…`, `הֵם קְטַנִּים…`, `הֵם רְחוֹקִים זֶה מִזֶּה…`) are right for both nouns: **reused**, no feminine clip. Hints 1 and 2 are the shared ones.

| id | where | nikud text (ui_text) | voice_text | status | note |
|---|---|---|---|---|---|
| C1 | NUM-A-11 chick [4, 3], prompt | אֵיפֹה יֵשׁ יוֹתֵר אֶפְרוֹחִים? | איפה יש יותר אפרוחים? | text-ready | cue `spread`; also the prompt of C3 and C5 |
| C1-l | labels | אַרְבָּעָה אֶפְרוֹחִים / שְׁלוֹשָׁה אֶפְרוֹחִים | | text-ready | screen only |
| C1-c | correct | כֵּן! כָּאן יֵשׁ יוֹתֵר אֶפְרוֹחִים. | כן, כאן יש יותר אפרוחים. | text-ready | shared by C1, C3, C5 (one clip) |
| C1-h3 | h3 | בְּצַד אֶחָד יֵשׁ אַרְבָּעָה אֶפְרוֹחִים, וּבַצַּד הָאַחֵר שְׁלוֹשָׁה אֶפְרוֹחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | בצד אֶחָד יש אַרְבָּעָה אפרוחים, ובצד האחר שְׁלוֹשָׁה אפרוחים. עכשיו תורכם — ללחוץ על הנכונה. | text-ready | 16 words, under 24 |
| C2 | NUM-A-11 butterfly [3, 5], prompt | אֵיפֹה יֵשׁ יוֹתֵר פַּרְפָּרִים? | איפה יש יותר פרפרים? | text-ready | cue `spread` |
| C2-l | labels | שְׁלוֹשָׁה פַּרְפָּרִים / חֲמִשָּׁה פַּרְפָּרִים | | text-ready | |
| C2-c | correct | כֵּן! כָּאן יֵשׁ יוֹתֵר פַּרְפָּרִים. | כן, כאן יש יותר פרפרים. | text-ready | |
| C2-h3 | h3 | בְּצַד אֶחָד יֵשׁ חֲמִשָּׁה פַּרְפָּרִים, וּבַצַּד הָאַחֵר שְׁלוֹשָׁה פַּרְפָּרִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | בצד אֶחָד יש חֲמִשָּׁה פרפרים, ובצד האחר שְׁלוֹשָׁה פרפרים. עכשיו תורכם — ללחוץ על הנכונה. | text-ready | |
| C3 | NUM-A-12 chick [3, 5], prompt / correct | = C1 / = C1-c | | text-ready | cue `big` |
| C3-l | labels | שְׁלוֹשָׁה אֶפְרוֹחִים / חֲמִשָּׁה אֶפְרוֹחִים | | text-ready | |
| C3-h3 | h3 | בְּצַד אֶחָד יֵשׁ חֲמִשָּׁה אֶפְרוֹחִים, וּבַצַּד הָאַחֵר שְׁלוֹשָׁה אֶפְרוֹחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | בצד אֶחָד יש חֲמִשָּׁה אפרוחים, ובצד האחר שְׁלוֹשָׁה אפרוחים. עכשיו תורכם — ללחוץ על הנכונה. | text-ready | |
| C4 | NUM-A-12 butterfly fewer [5, 4], prompt | אֵיפֹה יֵשׁ פָּחוֹת פַּרְפָּרִים? | איפה יש פחות פרפרים? | text-ready | cue `small` (the 5 drawn small); also C6's prompt |
| C4-l | labels | חֲמִשָּׁה פַּרְפָּרִים / אַרְבָּעָה פַּרְפָּרִים | | text-ready | |
| C4-c | correct | כֵּן! כָּאן יֵשׁ פָּחוֹת פַּרְפָּרִים. | כן, כאן יש פחות פרפרים. | text-ready | shared by C4 and C6 |
| C4-h3 | h3 | בְּצַד אֶחָד יֵשׁ אַרְבָּעָה פַּרְפָּרִים, וּבַצַּד הָאַחֵר חֲמִשָּׁה פַּרְפָּרִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | בצד אֶחָד יש אַרְבָּעָה פרפרים, ובצד האחר חֲמִשָּׁה פרפרים. עכשיו תורכם — ללחוץ על הנכונה. | text-ready | the right set first, as the generator does |
| C5 | MATH-A-07 chick [2, 4], prompt / correct | = C1 / = C1-c | | text-ready | cue `big` |
| C5-l | labels | שְׁנֵי אֶפְרוֹחִים / אַרְבָּעָה אֶפְרוֹחִים | | text-ready | `שְׁנֵי`, never `שְׁנַיִם`, before the noun |
| C5-h3 | h3 | בְּצַד אֶחָד יֵשׁ אַרְבָּעָה אֶפְרוֹחִים, וּבַצַּד הָאַחֵר שְׁנֵי אֶפְרוֹחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | בצד אֶחָד יש אַרְבָּעָה אפרוחים, ובצד האחר שְׁנֵי אפרוחים. עכשיו תורכם — ללחוץ על הנכונה. | text-ready | |
| C6 | MATH-A-07 butterfly fewer [5, 3], prompt / correct | = C4 / = C4-c | | text-ready | cue `small` |
| C6-l | labels | חֲמִשָּׁה פַּרְפָּרִים / שְׁלוֹשָׁה פַּרְפָּרִים | | text-ready | |
| C6-h3 | h3 | בְּצַד אֶחָד יֵשׁ שְׁלוֹשָׁה פַּרְפָּרִים, וּבַצַּד הָאַחֵר חֲמִשָּׁה פַּרְפָּרִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | בצד אֶחָד יש שְׁלוֹשָׁה פרפרים, ובצד האחר חֲמִשָּׁה פרפרים. עכשיו תורכם — ללחוץ על הנכונה. | text-ready | |

New spoken strings in 6.3: 3 prompts (C1, C2, C4), 3 correct lines (C1-c, C2-c, C4-c), 6 h3 lines.

### 6.4 The other A3 rows whose nouns change

**COL-B-03, swatch to object** (`k_pick`; band_b `NAMES`: `כַּדּוּר` + colour, m). Prompt, correct line and h3 are COL-B-03's own.

| id | where | nikud text (ui_text) | voice_text | status | note |
|---|---|---|---|---|---|
| CB3-blue | prompt (group `shade_blue_1`) | אֵיפֹה עוֹד כָּחֹל? | איפה עוד כחול? | reused | `b.colb03.1` prompt |
| CB3-blue-l | labels | כַּדּוּר כָּחֹל / כַּדּוּר לָבָן / כַּדּוּר סָגֹל | | text-ready | names from `COLOURS`; all three already in the pack |
| CB3-blue-c | correct | כֵּן! גַּם זֶה כָּחֹל. | כן, גם זה כחול. | reused | `זֶה` agrees with `כַּדּוּר` (m) |
| CB3-blue-h3 | h3 | בָּהִיר וְכֵהֶה הֵם אוֹתוֹ צֶבַע. הַצֶּבַע הוּא כָּחֹל. עַכְשָׁו תּוֹרְכֶם. | בהיר וכהה הם אותו צבע. הצבע הוא כחול. עכשיו תורכם. | reused | it answers the white-ball trap exactly; keep it, not the default `זֶה כַּדּוּר כָּחֹל…` |
| CB3-red | prompt (group `shade_red_3`) | אֵיפֹה עוֹד אָדֹם? | איפה עוד אדום? | reused | `b.colb03.5` prompt |
| CB3-red-l | labels | כַּדּוּר אָדֹם / כַּדּוּר שָׁחֹר / כַּדּוּר כָּתֹם | | text-ready | |
| CB3-red-c / h3 | correct / h3 | כֵּן! גַּם זֶה אָדֹם. / בָּהִיר וְכֵהֶה הֵם אוֹתוֹ צֶבַע. הַצֶּבַע הוּא אָדֹם. עַכְשָׁו תּוֹרְכֶם. | | reused | |

The shared M-COL-SHADE line (`כָּחֹל בָּהִיר וְכָחֹל כֵּהֶה הֵם שְׁנֵיהֶם כָּחֹל…`) also plays on the red item, as it already does on `b.colb03.5` and `.6`. It works as an example; no change asked.

**LOG-B-09** (`הוּא` agrees with the shape nouns, all m).

| id | where | nikud text (ui_text) | voice_text | status | note |
|---|---|---|---|---|---|
| L9a | prompt | הוּא לֹא צָהֹב וְלֹא רִבּוּעַ. אֵיזֶה הוּא? | הוא לא צהוב ולא ריבוע. איזה הוא? | text-ready | |
| L9a-l | labels | עִגּוּל יָרֹק / רִבּוּעַ יָרֹק / עִגּוּל צָהֹב | | text-ready | |
| L9a-c | correct | כֵּן! הוּא לֹא צָהֹב וְלֹא רִבּוּעַ. | כן, הוא לא צהוב ולא ריבוע. | text-ready | |
| L9a-h3 | h3 | מְחַפְּשִׂים מַשֶּׁהוּ שֶׁהוּא לֹא צָהֹב וְגַם לֹא רִבּוּעַ. עַכְשָׁו תּוֹרְכֶם. | מחפשים משהו שהוא לא צהוב וגם לא ריבוע. עכשיו תורכם. | text-ready | the reviewed form of `b.logb09.*` h3 (its ui_text), not the generator's old `צָרִיךְ שֶׁגַּם…` |
| L9b | prompt | הוּא לֹא כָּתֹם וְלֹא מְשֻׁלָּשׁ. אֵיזֶה הוּא? | הוא לא כתום ולא משולש. איזה הוא? | text-ready | |
| L9b-l | labels | רִבּוּעַ אָדֹם / מְשֻׁלָּשׁ אָדֹם / רִבּוּעַ כָּתֹם | | text-ready | |
| L9b-c | correct | כֵּן! הוּא לֹא כָּתֹם וְלֹא מְשֻׁלָּשׁ. | כן, הוא לא כתום ולא משולש. | text-ready | |
| L9b-h3 | h3 | מְחַפְּשִׂים מַשֶּׁהוּ שֶׁהוּא לֹא כָּתֹם וְגַם לֹא מְשֻׁלָּשׁ. עַכְשָׁו תּוֹרְכֶם. | מחפשים משהו שהוא לא כתום וגם לא משולש. עכשיו תורכם. | text-ready | for the design-director: red and orange are a near pair (`NEAR`); the red square and the orange square must look clearly different |

**LOG-B-08** (rule on shape). The four existing prompts wait for the owner (V1, `proposed`: `הִיא` after the noun, and `אִם לֹא` in place of the school word `אַחֶרֶת`). The two new prompts must take the **same** form as the existing four, so both forms are given; the generator uses the one the owner chooses for `b.logb08.1` to `.4`.

| id | where | nikud text (ui_text) | voice_text | status | note |
|---|---|---|---|---|---|
| L8t | triangle, prompt (editor's form) | אִם הַצּוּרָה הִיא מְשֻׁלָּשׁ, שָׂמִים אוֹתָהּ בַּקֻּפְסָה. אִם לֹא — לָעֵשֶׂב. | אם הצורה היא משולש, שָׂמִים אותה בקופסה. אם לא — לעשב. | text-ready (goes in with V1) | `הִיא`: the subject `צוּרָה` is f, although `מְשֻׁלָּשׁ` is m |
| L8t-old | triangle, prompt (today's form, until V1) | אִם הַצּוּרָה מְשֻׁלָּשׁ, שָׂמִים אוֹתָהּ בַּקֻּפְסָה. אַחֶרֶת — לָעֵשֶׂב. | אם הצורה משולש, שָׂמִים אותה בקופסה. אחרת — לעשב. | proposed (with V1) | |
| L8r | rectangle, prompt (editor's form) | אִם הַצּוּרָה הִיא מַלְבֵּן, שָׂמִים אוֹתָהּ בַּקֻּפְסָה. אִם לֹא — לָעֵשֶׂב. | אם הצורה היא מלבן, שָׂמִים אותה בקופסה. אם לא — לעשב. | text-ready (goes in with V1) | |
| L8r-old | rectangle, prompt (today's form) | אִם הַצּוּרָה מַלְבֵּן, שָׂמִים אוֹתָהּ בַּקֻּפְסָה. אַחֶרֶת — לָעֵשֶׂב. | אם הצורה מלבן, שָׂמִים אותה בקופסה. אחרת — לעשב. | proposed (with V1) | |
| — | bins, correct, h3 | `הַקֻּפְסָה` / `הָעֵשֶׂב`; `כֵּן! עֲשִׂיתֶם לְפִי הַכְּלָל.`; `לְכׇל צוּרָה שׁוֹאֲלִים: זֶה מַתְאִים לַכְּלָל? אִם כֵּן — לַקֻּפְסָה. עַכְשָׁו תּוֹרְכֶם.` | | reused | |

**For the curriculum-expert (LOG-B-08 rectangle):** a square *is* a rectangle, so "if the shape is a rectangle" with a square in the pool has two defensible places for that square. The rectangle item's pool must have no square (today's `pool` has two), and it needs `shape_rect_*` (today's has none).

**NUM-B-04 and NUM-A-04, `count_tap`.** The count, the correct line and h3 use bare (feminine) numbers, so only the touch hint and the answer question carry the noun.

| id | where | nikud text (ui_text) | voice_text | status | note |
|---|---|---|---|---|---|
| N4-cat-h1 | NUM-B-04 14 cats, hint 1 | נוֹגְעִים בְּחָתוּל אֶחָד, וְאוֹמְרִים מִסְפָּר אֶחָד. | נוגעים בחתול אֶחָד, ואומרים מספר אֶחָד. | text-ready | |
| N4-cat-q | answer question | כַּמָּה חֲתוּלִים? | כמה חתולים? | text-ready | |
| N4-cat-c | correct | אַרְבַּע עֶשְׂרֵה! סְפַרְתֶּם כׇּל אֶחָד פַּעַם אַחַת. | אַרְבַּע עֶשְׂרֵה. ספרתם כל אֶחָד פעם אַחַת. | text-ready | |
| N4-cat-h3 | h3 | מֵאַחַת עַד אַרְבַּע עֶשְׂרֵה. הַמִּסְפָּר הָאַחֲרוֹן אוֹמֵר כַּמָּה: אַרְבַּע עֶשְׂרֵה! עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַרְבַּע עֶשְׂרֵה. | מֵאַחַת עד אַרְבַּע עֶשְׂרֵה. המספר האחרון אומר כמה: אַרְבַּע עֶשְׂרֵה. עכשיו תורכם — ללחוץ על אַרְבַּע עֶשְׂרֵה. | text-ready | the `k_count_tap` pattern |
| N4-bfly-h1 | NUM-B-04 17 butterflies, hint 1 | נוֹגְעִים בְּפַרְפַּר אֶחָד, וְאוֹמְרִים מִסְפָּר אֶחָד. | נוגעים בפרפר אֶחָד, ואומרים מספר אֶחָד. | text-ready | no dagesh in the פ after `בְּ` (`prefix()` does this) |
| N4-bfly-q | answer question | כַּמָּה פַּרְפָּרִים? | כמה פרפרים? | text-ready | |
| N4-bfly-c | correct | שְׁבַע עֶשְׂרֵה! סְפַרְתֶּם כׇּל אֶחָד פַּעַם אַחַת. | שְׁבַע עֶשְׂרֵה. ספרתם כל אֶחָד פעם אַחַת. | text-ready | |
| N4-bfly-h3 | h3 | מֵאַחַת עַד שְׁבַע עֶשְׂרֵה. הַמִּסְפָּר הָאַחֲרוֹן אוֹמֵר כַּמָּה: שְׁבַע עֶשְׂרֵה! עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שְׁבַע עֶשְׂרֵה. | מֵאַחַת עד שְׁבַע עֶשְׂרֵה. המספר האחרון אומר כמה: שְׁבַע עֶשְׂרֵה. עכשיו תורכם — ללחוץ על שְׁבַע עֶשְׂרֵה. | text-ready | |
| A4-bird-h1 | NUM-A-04 4 birds, hint 1 | נוֹגְעִים בְּצִפּוֹר אַחַת, וְאוֹמְרִים מִסְפָּר אֶחָד. | נוגעים בציפור אַחַת, ואומרים מספר אֶחָד. | text-ready | `צִפּוֹר` f: `אַחַת`; `מִסְפָּר אֶחָד` stays m (its noun is `מִסְפָּר`) |
| A4-bird-q | answer question | כַּמָּה צִפֳּרִים? | כמה ציפורים? | text-ready | |
| A4-bird-c / h3 | correct / h3 | `אַרְבַּע! סְפַרְתֶּם כׇּל אֶחָד פַּעַם אַחַת.` / `אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. הַמִּסְפָּר הָאַחֲרוֹן אוֹמֵר כַּמָּה: אַרְבַּע! עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַרְבַּע.` | | reused | the same text as the existing 4-count items |
| A4-lady-h1 | NUM-A-04 3 ladybugs, hint 1 | נוֹגְעִים בְּחִפּוּשִׁית אַחַת, וְאוֹמְרִים מִסְפָּר אֶחָד. | נוגעים בחיפושית אַחַת, ואומרים מספר אֶחָד. | text-ready | |
| A4-lady-q | answer question | כַּמָּה חִפּוּשִׁיּוֹת? | כמה חיפושיות? | text-ready | |
| A4-lady-c / h3 | correct / h3 | `שָׁלוֹשׁ! …` / `אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. …` (as the existing 3-count items) | | reused | |

(The bird and ladybug hint 1 and question may already exist in `count.*` rows; if so the generator reuses them. Same text either way.)

**COL-A-01** (`k_pick` with explicit options; names from `colours.json`).

| id | where | nikud text (ui_text) | voice_text | status | note |
|---|---|---|---|---|---|
| CA1-ban | prompt (group `banana_yellow`) | אֵיפֹה אוֹתוֹ צֶבַע? | איפה אותו צבע? | reused | `col.match.*` |
| CA1-ban-l | labels | פֶּרַח צָהֹב / בָּנָנָה יְרֻקָּה / כַּדּוּר כָּתֹם | | text-ready | existing label forms |
| CA1-ban-c | correct | כֵּן! זֶה פֶּרַח צָהֹב. | כן, זה פרח צהוב. | text-ready | `זֶה`: the answer is `פֶּרַח` (m), not the banana of the picture (f) |
| CA1-ban-h3 | h3 | זֶה פֶּרַח צָהֹב. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | זה פרח צהוב. עכשיו תורכם — ללחוץ עליו. | text-ready | |
| CA1-bal | prompt (group `balloon_yellow`) | אֵיפֹה אוֹתוֹ צֶבַע? | איפה אותו צבע? | reused | |
| CA1-bal-l | labels | כַּדּוּר צָהֹב / בָּלוֹן יָרֹק / פֶּרַח כָּתֹם | | text-ready | |
| CA1-bal-c / h3 | correct / h3 | כֵּן! זֶה כַּדּוּר צָהֹב. / זֶה כַּדּוּר צָהֹב. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | כן, זה כדור צהוב. / זה כדור צהוב. עכשיו תורכם — ללחוץ עליו. | text-ready | |

The M-SORT-SHIFT trap (green banana, green balloon) plays today's `vo:fb.sort_shift` (A5, Band A). That line is about colour, so it is true here.

**SHP-A-04 (yellow and red):** no text changes. `k_shape` names the shapes without their colour (`אֵיפֹה הָרִבּוּעַ?`, `אֵיפֹה הַמַּלְבֵּן?`, `כֵּן! זֶה רִבּוּעַ.`, `זֶה מַלְבֵּן. … לִלְחֹץ עָלָיו.`): all **reused**.

**CS-A-03 boards (Band A, D10).** Only h3 depends on the board (`robot_steps()`). Prompt and correct line are reused (`מַזִּיזִים אֶת הָרוֹבּוֹט אֶל הַדֶּגֶל.`, `כֵּן! הָרוֹבּוֹט הִגִּיעַ אֶל הַדֶּגֶל.`).

| id | where | nikud text (ui_text) | voice_text | status | note |
|---|---|---|---|---|---|
| R24-h3 | 2 × 4, robot (0, 3), flag (1, 0), solution up ×3, right ×1 | שְׁלוֹשָׁה צְעָדִים לְמַעְלָה, וְאָז צַעַד אֶחָד לְכִוּוּן הַדֶּגֶל. עַכְשָׁו תּוֹרְכֶם. | שְׁלוֹשָׁה צעדים למעלה, ואז צעד אֶחָד לכיוון הדגל. עכשיו תורכם. | text-ready | |
| R34-h3 | 3 × 4, robot (2, 3), flag (0, 0), solution up ×3, left ×2 | שְׁלוֹשָׁה צְעָדִים לְמַעְלָה, וְאָז שְׁנֵי צְעָדִים לְכִוּוּן הַדֶּגֶל. עַכְשָׁו תּוֹרְכֶם. | שְׁלוֹשָׁה צעדים למעלה, ואז שְׁנֵי צעדים לכיוון הדגל. עכשיו תורכם. | text-ready | |

Please write each `solution` **up first**: after the steps up, the flag is on the robot's own row, so "towards the flag" is a straight line. If the robot goes sideways first, "two steps towards the flag" points at a flag that is up and to the side.

### 6.5 New names (A6) and the half-shekel coin

| id | where | one | many | g | with `בְּ` (count hint) | status | note |
|---|---|---|---|---|---|---|---|
| chick | `objects` of `counting-hills.json`, `math.json` | אֶפְרוֹחַ | אֶפְרוֹחִים | m | בְּאֶפְרוֹחַ אֶחָד | text-ready | voice: אפרוח, אפרוחים |
| butterfly | same | **פַּרְפַּר** | פַּרְפָּרִים | m | בְּפַרְפַּר אֶחָד | text-ready | replaces §2's `פַּרְפָּר`; voice: פרפר, פרפרים |
| frog | same | צְפַרְדֵּעַ | צְפַרְדְּעִים | f | בִּצְפַרְדֵּעַ אַחַת | text-ready | already f in band_b `NAMES` |
| shoe | band_b `OBJECTS` | נַעַל | נַעֲלַיִם | f | בְּנַעַל אַחַת | text-ready | NUM-B-18 forms in §2 (`כֻּלָּן`, `אַחַת`, `תִּשָּׁאֵר`) |
| coin_h50 | band_b `NAMES` | מַטְבֵּעַ שֶׁל חֲצִי שֶׁקֶל | | m | | text-ready | voice, if a label is ever read: מטבע של חצי שקל. Same pattern as `COIN_OF` (`מַטְבֵּעַ שֶׁל שֶׁקֶל`) and as H29's `מֵחֲצִי שֶׁקֶל` (`מֵ` before the ח) |
| coin_s1, s5, s10 | band_b `NAMES` | מַטְבֵּעַ שֶׁל שֶׁקֶל / מַטְבֵּעַ שֶׁל חֲמִשָּׁה שְׁקָלִים / מַטְבֵּעַ שֶׁל עֲשָׂרָה שְׁקָלִים | | m | | reused | `COIN_OF` |

The other A6 `names` entries copy existing rows; I checked each one's gender: apple_green, ball_red/blue/yellow, balloon_red/blue (m); plate `צַלַּחַת` f with `def` `הַצַּלַּחַת`; tower_1 to 6 `מִגְדָּל מִסְפָּר אַחַת…` m (the bare number after `מִסְפָּר` stays feminine, which is right); solid_sphere `כַּדּוּר` m; shape_circle_* and shape_square_* m; fish_size_l/s, star_size_l/s m; key m. No new Hebrew in them. **Band A `solid_box` stays `קֻפְסָה`** (A6, Q7).

In flash, ordinal and pattern items: `זֶה אֶפְרוֹחַ אֶחָד.`, `אֵלֶּה שְׁלוֹשָׁה אֶפְרוֹחִים.`, `זֶה פַּרְפַּר אֶחָד.`, `זֶה הַשֵּׁנִי בַּתּוֹר … לִלְחֹץ עָלָיו` (as in §2).

### 6.6 fb.sort_shift in Band B (A5)

| id | where | nikud text (ui_text) | voice_text | status | note |
|---|---|---|---|---|---|
| `vo:fb.sort_shift.shape` | Band B items with `rule: shape` (COL-B-04 shape sort, LOG-B-06 H9b, LOG-B-08 `.3`, `.4`, triangle, rectangle) | זֶה אוֹתוֹ צֶבַע, אֲבָל מְחַפְּשִׂים אֶת אוֹתָהּ הַצּוּרָה. בּוֹאוּ נִבְדֹּק. | זה אותו צבע, אבל מחפשים את אותה הצורה. בואו נבדוק. | **text-ready for Band B** | P4's text. `אוֹתָהּ` agrees with `צוּרָה` (f). The first clause is true only when the child followed the colour, which is what M-SORT-SHIFT means on these items; the tag must fire only then |
| `vo:fb.sort_shift.kind` | Band B items with `rule: kind` (none today) | זֶה אוֹתוֹ צֶבַע, אֲבָל מְחַפְּשִׂים אֶת אוֹתוֹ הַדָּבָר. בּוֹאוּ נִבְדֹּק. | זה אותו צבע, אבל מחפשים את אותו הדבר. בואו נבדוק. | **text-ready for Band B** | P3's text |
| P3, P4 in Band A | LOG-A-01, LOG-A-03, SHP-A-02 | (the same texts) | | **proposed** | the owner decides with P2; Band A keeps today's `vo:fb.sort_shift` until then. Once he approves, one clip serves both bands |

Band B colour items keep today's `vo:fb.sort_shift` (`מְחַפְּשִׂים אֶת אוֹתוֹ צֶבַע, לֹא אוֹתוֹ דָּבָר.`): reused.

### 6.7 Dropped, and one fix to existing rows

- ~~X1a~~ `יֵשׁ יוֹתֵר צְפַרְדְּעִים אוֹ יוֹתֵר אֶפְרוֹחִים?`: **dropped** (A4: one noun per item; the existing `אֵיפֹה יֵשׁ יוֹתֵר {many}?` is used).
- ~~X1b~~ `כֵּן! יֵשׁ יוֹתֵר צְפַרְדְּעִים.`: **dropped** (A4).
- ~~X1c~~ the three feminine size lines `הֵן גְּדוֹלוֹת / קְטַנּוֹת / רְחוֹקוֹת זוֹ מִזּוֹ…`: **dropped** (A4: every M-CNT-SIZE set is masculine). They stay in §2 as history; the generator must not add them. This answers §5 item 5.
- §2's extra strings fall from 13 to 8 (X1a, X1b and the three X1c lines are out).
- **Existing rows with `פַּרְפָּר` in the singular** (screen nikud only; the voice text is plain `פרפר`, so no clip needs re-voicing): `activity.count.butterflies.3` prompt, `feedback.incorrect.0`, `feedback.incorrect.1`; `activity.count.butterflies.4` prompt, `feedback.incorrect.0`, `feedback.incorrect.1`; `activity.count.butterflies.5` `feedback.incorrect.0`, `feedback.incorrect.1`; `lesson.butterflies` celebration. All 9 are `text-ready`. The fix is `פַּרְפָּר` → `פַּרְפַּר` (and `שֶׁפַּרְפָּר` → `שֶׁפַּרְפַּר`). It is a proposal for the owner; with his OK the app-developer changes it in `counting-hills.json`.
