# The Hebrew course: Band A content batch (HEB-1)

Owner: hebrew-language-teacher. Date: 2026-11-03. Status: **text-ready** (the hebrew-text-editor, 2026-11-03: every text below has its final wording, nikud and voice text, and waits for the owner; `docs/agents/hebrew-notes.md` §9). Words taken from the syllabus lists (`syllabus.md` §3, already `text-ready`) are marked **(tr)**; the new words are `text-ready` too. Nothing is built, drawn or voiced. The three A-03 kind lines (`i-odd-animals`, `i-odd-food`, `i-odd-clothes`, §3), new after the catalogue (frame §4.4 H4), are `text-ready` too (second pass, 2026-11-03).
Skills: `syllabus.md` §6.1 (HEB-A-01 to A-14). Templates: the shared LS ids (`frame.md` §2.3; `templates.md` §2). Tags: `syllabus.md` §5 (the Band A tags are new there). Pronunciation: `pronunciation.csv` (rows `heb-a-…`). Voicing count: §9.

## 0. The rules this batch keeps

- **Band A presentation** (frame §3.1): at most 3 choices, one spoken instruction at a time (≤ 8 words, curriculum §8.3), no reading demand except A-10 to A-12, no "right" or "left" words, 3–5 items per activity, 8-minute visits.
- **Every item carries at least two tagged distractors** (F5). A 2-choice item is the *guided* step of a 3-choice item: it hides one of the item's two tagged distractors, and the engine's 2-choice guard (at most 50% of the evidence) applies.
- **Every hint ladder** has three steps, and step 2 changes the representation (frame §2.3). Step 3, "show me", is a worked example after which the child makes the last move, so every item ends in success (curriculum §9.2).
- **Words a child will later read.** Most picture words are taken from the code-spine lists of `syllabus.md` §3, so a Band A child meets them by ear, with their pictures, before reading them in Bands B and C (decoding is easier for words already in the child's spoken vocabulary), and the same pictures and word clips serve all three bands. Ordinary words stay in (owner, 2026-11-03): טִיל is a rocket to the moon here.
- **Instructions** use the plural imperative, "let's" or the impersonal present (curriculum §8.3), the app's gender-neutral form. **Settled by the editor (`hebrew-notes.md` §9.1):** the course voice does not follow the child's address form; every recorded line is plural or neutral, so there is one clip per line, and no line has a first-person verb or adjective with a gender (so any voice can say them).
- **One voice.** Inside the course the Hebrew teaching voice says every line (frame §1.3); the companion reacts without words. The voice has no gender in its lines (`hebrew-notes.md` §9.1); its sound is the voice director's choice.
- **A word clip is reused everywhere.** A picture's word is one clip ("כַּדּוּר"), played as the option's own sound (LS01 b), after a carrier line ("בּוֹאוּ נִמְצָא:"), and in the specific praise. This keeps the voicing small (§9). Whether the carrier + word joins sound natural is for the voice-and-sound-director's pilot.
- **No speech is scored.** LS09 echo is optional practice; with the parent's voice switch on, it gets confident or unsure feedback, never evidence (`syllabus.md` §0).
- **Pictures** are the design-director's, drawn from real references (`docs/agents/README.md`); §2 lists what each must show.

## 1. How to read the item tables

| Column | Meaning |
|---|---|
| Item | `A-xx.<n>`; **P** = practice, **C** = understanding or delayed check (a new item or representation) |
| Template | the shared id and mode |
| Prompt | the line heard (clip ids in `pronunciation.csv`); Hebrew is `text-ready` |
| Right | the right answer |
| Distractors | each with its tag |
| Rep | representation (frame §3.3.1): `pic` pictorial, `con` concrete, `sto` story, `emb` embodied, `sym` symbolic |

## 2. Word and picture stock (91 pictures, one word clip each)

Ids are `pic.<word>`. Every picture is one clear object (or a small scene), no text in it, the object facing right where it moves (the reading direction). "(tr)" = in the syllabus lists, `text-ready`; all others are new and `text-ready` too (the editor read the nikud, the stress and the fit for ages 3 to 8 of each).

| Group | Word, gloss and picture |
|---|---|
| Animals | כֶּלֶב (tr) dog · חָתוּל (tr) cat (one picture serves חֲתוּלָה (tr), the story's she-cat) · סוּס (tr) horse · דָּג (tr) fish · גָּמָל (tr) camel · אַרְנָב (tr) rabbit · פִּיל (tr) elephant · תַּרְנְגוֹל (tr) rooster · חֲמוֹר (tr) donkey · פַּרְפַּר butterfly · צָב tortoise · נְמָלָה ant · אֶפְרוֹחַ a yellow chick · כִּבְשָׂה a woolly white sheep · צִפּוֹר bird · עֲטַלֵּף bat |
| Food | לֶחֶם (tr) bread · תּוּת (tr) strawberry · תַּפּוּחַ (tr) apple · בֵּיצָה (tr) egg · עוּגָה (tr) cake · פִּיצָה (tr) a round pizza · חָלָב (tr) a glass of milk · גֶּזֶר carrot · בָּנָנָה banana · עוּגִיָּה cookie · פִּתָּה a round pale pita · קֶמַח a bag of flour with some spilt · סֻכָּר a bowl of sugar cubes · זַיִת olive (a green olive with a leaf) |
| Clothes | שִׂמְלָה (tr) a dress printed with strawberries · חֻלְצָה (tr) a shirt (plain; and a blue-white striped one) · סִינָר (tr) an apron · סַנְדָּל (tr) a sandal · כּוֹבַע a hat (plain; and a hat with cat ears) · בֶּגֶד־יָם a swimsuit |
| Things | כַּדּוּר (tr) ball (red; and yellow) · כַּדּוּר צֶמֶר a ball of white wool · בֻּבָּה (tr) doll · דֻּבִּי (tr) teddy bear · כִּסֵּא (tr) chair · שֻׁלְחָן (tr) table · כּוֹס (tr) cup · סִיר (tr) cooking pot · סִירָה (tr) small boat · אֳנִיָּה (tr) big ship · מָטוֹס (tr) plane · טִיל (tr) a space rocket flying to the moon · כַּף (tr) spoon · מַזְלֵג fork · תַּנּוּר an oven, door open · מְקָרֵר fridge · קְעָרָה a mixing bowl · צַלַּחַת a round white plate · מַגֶּבֶת a blue-white striped towel · מִטְרִיָּה umbrella · מִטָּה bed · קֻפְסָה (tr) box · סַל (tr) basket · אָרוֹן (tr) cupboard · חַלּוֹן (tr) window · שָׁעוֹן (tr) clock · בָּלוֹן balloon · גַּג a roof (a house with the roof lit) · בַּיִת (tr) house · אֹהֶל tent · עֲגָלָה a pram · מַתָּנָה (tr) a wrapped present · בֻּעָה a soap bubble · מְעָרָה a cave · קֶשֶׁת rainbow · עֲפִיפוֹן a kite shaped like a butterfly · מַחַט a sewing needle · חוּט (tr) a reel of thread · טַבַּעַת (tr) a ring |
| Nature | כּוֹכָב (tr) star · יָרֵחַ (tr) moon · יָם (tr) sea · עֵץ (tr) tree · שִׂיחַ a round green bush · רוּחַ (tr) wind (leaves and a hat blown sideways) · גֶּשֶׁם (tr) rain · עֲנָנִים (tr) clouds · שֶׁמֶשׁ (tr) sun |
| People and body | אַבָּא (tr) · סָבָא (tr) · סַבְתָּא (tr) · מוֹרָה (tr) a teacher singing with children · יַלְדָּה (tr) a girl singing · אַף (tr) a nose (on a teddy's face) · זָנָב (tr) a tail (on a rabbit, lit) |
| Plurals (A-05) | חֲתוּלִים · כְּלָבִים (tr) · כַּדּוּרִים · בֻּבּוֹת · דֻּבִּים · עוּגוֹת · פִּיצוֹת · סוּסִים · חֲמוֹרִים · סִירוֹת · מְטוֹסִים · בֵּיצִים · תַּפּוּחִים · דָּגִים (3 to 5 of each, same drawing as the singular) |
| Actions (A-02, short animations) | the rabbit kicks the ball (בּוֹעֵט) · the cat searches in a bush (מְחַפֶּשֶׂת) · Nitzi stirs a bowl (מְעַרְבֶּבֶת) · a fish swims (שׂוֹחֶה); the same four in a second scene for the checks |
| Print (A-10 to A-12) | single letters and marks, drawn by the app in Heebo 700 (no picture file): letters, numerals 0 1 2 3 5 7 9, shapes ● ○ ▲ △, small icons ☀ ⭐ ♥ ✿ |

**Words with a second sense** (the editor's list, `hebrew-notes.md` §8.7): none of the picture words above is used for a sense other than its picture. מוֹרָה is "a teacher", not "pointing"; קֶשֶׁת is the rainbow.

## 3. Shared lines (all `text-ready`)

| Id | Line | Use |
|---|---|---|
| i-find | בּוֹאוּ נִמְצָא: | carrier before a word clip (A-02, A-05) |
| i-what-he / i-what-she | מָה הוּא עוֹשֶׂה? / מָה הִיא עוֹשָׂה? | A-02 actions |
| i-rhyme | אֵיזוֹ מִלָּה נִגְמֶרֶת אוֹתוֹ דָּבָר? | A-07, after the cue word clip ("דָּג. אֵיזוֹ מִלָּה נִגְמֶרֶת אוֹתוֹ דָּבָר?") |
| i-rhyme-finish | מַה מַּתְאִים לְסוֹף הַשּׁוּרָה? | A-06 (after the open verse) |
| i-pairs | חַבְּרוּ מִלִּים שֶׁנִּגְמָרוֹת אוֹתוֹ דָּבָר. | A-07 check |
| i-drum | תּוֹפְפוּ פַּעַם לְכׇל חֵלֶק שֶׁל הַמִּלָּה. | A-08 drum (the word with the qamats qatan is sent unpointed to the voice) |
| i-strip | כַּמָּה תֻּפִּים? | A-08 strips |
| i-blend | מָה אָמַר הַתֻּכִּי? | A-09 (the puppet is an original parrot, תֻּכִּי) |
| i-sort-cat | שִׂימוּ כׇּל תְּמוּנָה בַּמָּקוֹם שֶׁלָּהּ. | A-03, A-05 sorts |
| i-odd | מָה הִגִּיעַ לְכָאן בְּטָעוּת? | The editor's odd-one-out line (the maths lands' game). Was "מִי לֹא שַׁיָּךְ?": Band A asks no "not" question (curriculum §8.3), and the same game has had this owner-approved line since 2026-10-29 (`hebrew-notes.md` §2.9). **Not the prompt of a scored A-03 item** (frame §4.4 H4): it names no kind, so the colour and the theme answers are both defensible. The three lines below build on it |
| i-odd-animals | מָה הִגִּיעַ בְּטָעוּת לַקֻּפְסָה שֶׁל בַּעֲלֵי הַחַיִּים? | A-03.4, .7, .9: the odd one out names its kind; the animals box with its picture holds the three cards (§4 A-03). **Final** (editor, second pass): `text-ready`. 7 words (the limit for Band A is 8). It keeps the pattern of `i-odd` ("מָה הִגִּיעַ … בְּטָעוּת") and adds the kind's box; `בַּעֲלֵי חַיִּים` as everywhere in the course (§9.3). Voice text: `מה הגיע בטעות לקופסה של בעלי החיים?`. **If the bin is not drawn as a box**, use "לַמָּקוֹם שֶׁל" (the wording of `i-sort-cat`): `מָה הִגִּיעַ בְּטָעוּת לַמָּקוֹם שֶׁל בַּעֲלֵי הַחַיִּים?` (voice text `מה הגיע בטעות למקום של בעלי החיים?`) |
| i-odd-food | מָה הִגִּיעַ בְּטָעוּת לַקֻּפְסָה שֶׁל הָאֹכֶל? | A-03.5. **Final** (`text-ready`). `הָאֹכֶל` (food) is the word children say; its voice text keeps the nikud, because plain `האוכל` is read with the stress on the last syllable ("the one who eats"). Alternative if the bin is not a box: `מָה הִגִּיעַ בְּטָעוּת לַמָּקוֹם שֶׁל הָאֹכֶל?` |
| i-odd-clothes | מָה הִגִּיעַ בְּטָעוּת לַקֻּפְסָה שֶׁל הַבְּגָדִים? | A-03.6. **Final** (`text-ready`). `הַבְּגָדִים` has the dagesh of a hard b (it is [b], as the IPA column says). Alternative if the bin is not a box: `מָה הִגִּיעַ בְּטָעוּת לַמָּקוֹם שֶׁל הַבְּגָדִים?` |
| i-letters | אֵיפֹה הָאוֹתִיּוֹת? גְּעוּ בְּכׇל הָאוֹתִיּוֹת. | A-10 tap all |
| i-bin-letters / i-bin-other | אוֹתִיּוֹת / דְּבָרִים אֲחֵרִים | A-10 bin labels |
| i-name | אֵיפֹה הַשֵּׁם שֶׁלָּכֶם? | A-11 |
| i-name-letter | אֵיפֹה הָאוֹת הָרִאשׁוֹנָה שֶׁל הַשֵּׁם? | A-11 |
| i-start | אֵיפֹה מַתְחִילִים לִקְרֹא? | A-12 |
| i-follow | הַקְשִׁיבוּ לְכׇל מִלָּה, וּגְעוּ בָּהּ. | A-12 word by word. Was "גְּעוּ בְּכׇל מִלָּה כְּשֶׁאֲנִי קוֹרֵאת" (קוֹרֵאת gave the voice a gender, `hebrew-notes.md` §9.1); the voice reads one word and waits, so the child listens and touches |
| i-order | סַדְּרוּ אֶת הַתְּמוּנוֹת לְפִי הַסִּפּוּר. | A-13 |
| i-first | מַה קָּרָה קֹדֶם? | A-13; also the STORY-ORDER line |
| i-trace | הוֹלְכִים עִם הָאֶצְבַּע עַל הַדֶּרֶךְ. | A-14 |
| bin-animals / bin-food / bin-clothes | בַּעֲלֵי חַיִּים / אֹכֶל / בְּגָדִים | A-03 |
| bin-one / bin-many | אֶחָד / הַרְבֵּה | A-05 |
| ok-1 … ok-8 | נָכוֹן! · כֵּן, זֶהוּ זֶה! · שְׁמַעְתֶּם טוֹב! · הִקְשַׁבְתֶּם עַד הַסּוֹף! · מְצָאתֶם! · יוֹפִי שֶׁל הַקְשָׁבָה! · בְּדִיּוּק! · כׇּל הַכָּבוֹד! | short praise after the item's word clip ("כַּדּוּר! שְׁמַעְתֶּם טוֹב!"): specific because the word is named (curriculum §9.1) |
| ok-hint | לֹא וִתַּרְתֶּם — וּמְצָאתֶם! | correct after hints (curriculum §9.1, `text-ready` there) |
| try-1, try-2 | הַמְּמ… בּוֹאוּ נִבְדֹּק. · בּוֹאוּ נִשְׁמַע שׁוּב. | first error (curriculum §9.2), before the diagnostic line |
| show | בּוֹאוּ נַעֲשֶׂה אֶת זֶה יַחַד. | hint level 3 opener |
| say-together | בּוֹאוּ נֹאמַר יַחַד. (voice text: בואו נגיד יחד.) | LS09 and the unsure result; `text-ready` (the editor's line, `hebrew-notes.md` §8.8) |
| heard | שָׁמַעְתִּי: | LS09 confident result, before the word clip |
| why | כִּי אֵלֶּה… | A-03, before a bin label clip ("כִּי אֵלֶּה… בַּעֲלֵי חַיִּים!"), unscored talk |
| seq-1, seq-2, seq-3 | קֹדֶם · אַחַר כָּךְ · בַּסּוֹף | A-13 level 2 |
| p-al, p-mitachat, p-betoch, p-leyad | עַל · מִתַּחַת · בְּתוֹךְ · לְיַד | A-04 level 1, the place word alone |
| e-… | כָב · נָב · עוֹן · לוֹן · דּוּר · נוּר · רוֹן · טוֹס · רָה | A-06 and A-07 level 1 and 2: the rhyming ends alone (one-syllable words are said whole) |

The **diagnostic line per tag** (the first-error feedback, curriculum §9.2) is in each skill's ladder below, as hint level 1.

## 4. The skills and their items

### HEB-A-01 Listens to a short story and answers "who" and "what" (OL)
**Template:** LS08 `dialogic` (the stories of §5), with LS01 picture questions at the pauses. **Mastery:** picture choice at a pause (`sto`) and after a replayed page (`pic`); check: a new story.

| Item | Template | Prompt (clip) | Right | Distractors | Rep |
|---|---|---|---|---|---|
| A-01.1 P | LS08 pause, story 1 after page 4 | s1-q2 מִי מָצְאָה אֶת הַכַּדּוּר? | the cat | the rabbit [STORY-ROLE] · a dog [STORY-WORLD] | sto |
| A-01.2 P | story 1 after page 3 | s1-q1 לְאָן נָפַל הַכַּדּוּר? | the bush | a tree, which is on the page [STORY-SEEN] · a window [STORY-WORLD] | sto |
| A-01.3 P | story 2 after page 2 | s2-q1 מַה שָּׂמָה נִיצִי בַּקְּעָרָה? | an egg | a spoon, which is on the page [STORY-SEEN] · an apple [STORY-WORLD] | sto |
| A-01.4 P | story 2 after page 4 | s2-q2 לְאָן נִכְנְסָה הָעוּגָה? | the oven | the bowl, on the page [STORY-SEEN] · the fridge, not in the story [STORY-WORLD] | sto |
| A-01.5 P | LS01, page 4 of story 1 replayed, then asked | s1-q2 | the cat | the rabbit [STORY-ROLE] · a dog [STORY-WORLD] | pic |
| A-01.6 P | LS01, page 2 of story 2 replayed | s2-q1 | an egg | a spoon [STORY-SEEN] · an apple [STORY-WORLD] | pic |
| A-01.7 C | story 3 (new) after page 4 | s3-q2 מִי הֵבִיא אֶת הַכּוֹבַע? | the fish | Kubi [STORY-ROLE] · a bird [STORY-WORLD] | sto |
| A-01.8 C | story 3 after page 2 | s3-q1 מָה עָף בָּרוּחַ? | the hat | the boat [STORY-SEEN] · a kite [STORY-WORLD] | sto |

**Hint ladder.** (1) The question again, and the line of the page that answers it is replayed (diagnostic for STORY-ROLE: "מִי עָשָׂה אֶת זֶה בַּסִּפּוּר?"; STORY-SEEN: "מַה שָּׁאַלְנוּ?"; STORY-WORLD: "בּוֹאוּ נִרְאֶה מַה קָּרָה בַּסִּפּוּר שֶׁלָּנוּ."). (2) The page shown again with only the answer's part lit (a new representation: the picture, not the words). (3) Show me: the voice says the answer sentence (the recast, §5) while the answer lights; the child taps it.
**Coverage:** each story's two questions answered right once without a hint.

### HEB-A-02 Learns new everyday words from stories (OL)
**Template:** LS01 hear → pick a picture (`pic`); LS01 audio-only options after an action (`sto`, the action is from the story); LS09 optional echo. **The set:** the 12 target words of the three stories (§5): בּוֹעֵט, שִׂיחַ, מְחַפֶּשֶׂת · קֶמַח, קְעָרָה, מְעַרְבֶּבֶת, תַּנּוּר · סִירָה, כּוֹבַע, רוּחַ, שׂוֹחֶה, and כַּדּוּר. Each is met in its story, on its word card (§5), and in two items below (three contexts, `syllabus.md` §8). Set coverage: every word right once without a hint (frame §3.3.4).

| Item | Template | Prompt | Right | Distractors | Rep |
|---|---|---|---|---|---|
| A-02.1 P | LS01 | i-find + שִׂיחַ | bush | tree [SEM] · cooking pot סִיר [SOUNDALIKE] | pic |
| A-02.2 P | LS01 | i-find + קֶמַח | flour | sugar סֻכָּר [SEM] · rainbow קֶשֶׁת [SOUNDALIKE] | pic |
| A-02.3 P | LS01 | i-find + קְעָרָה | bowl | plate [SEM] · cave מְעָרָה [SOUNDALIKE] | pic |
| A-02.4 P | LS01 | i-find + תַּנּוּר | oven | fridge [SEM] · ball כַּדּוּר [SOUNDALIKE] | pic |
| A-02.5 P | LS01 | i-find + סִירָה | boat | plane [SEM] · teacher מוֹרָה [SOUNDALIKE] | pic |
| A-02.6 P | LS01 | i-find + כּוֹבַע | hat | shirt [SEM] · star כּוֹכָב [SOUNDALIKE] | pic |
| A-02.7 P | LS01 | i-find + רוּחַ | wind | rain [SEM] · apple תַּפּוּחַ [SOUNDALIKE] | pic |
| A-02.8 P | LS01 | i-find + כַּדּוּר | ball | doll [SEM] · oven תַּנּוּר [SOUNDALIKE] | pic |
| A-02.9 P | LS01 audio options, the rabbit kicks | i-what-he; options בּוֹעֵט / זוֹרֵק / בּוֹרֵחַ | בּוֹעֵט | זוֹרֵק throws [SEM] · בּוֹרֵחַ runs away [SOUNDALIKE] | sto |
| A-02.10 P | LS01 audio options, the cat searches | i-what-she; מְחַפֶּשֶׂת / מוֹצֵאת / מְחַבֶּקֶת | מְחַפֶּשֶׂת | מוֹצֵאת finds [SEM] · מְחַבֶּקֶת hugs [SOUNDALIKE] | sto |
| A-02.11 P | LS01 audio options, Nitzi stirs | i-what-she; מְעַרְבֶּבֶת / אוֹפָה / מְדַבֶּרֶת | מְעַרְבֶּבֶת | אוֹפָה bakes [SEM] · מְדַבֶּרֶת talks [SOUNDALIKE] | sto |
| A-02.12 P | LS01 audio options, a fish swims | i-what-he; שׂוֹחֶה / קוֹפֵץ / שׁוֹתֶה | שׂוֹחֶה | קוֹפֵץ jumps [SEM] · שׁוֹתֶה drinks [SOUNDALIKE] | sto |
| A-02.13–16 C | as .1, .3, .6, .7 with the word in a **new picture** (a bush in a park, a bowl of soup, a hat on a snowman, wind moving a boat's sail) | | | the same tags, new distractor pictures | pic |
| A-02.17–18 C | as .9 and .12 in the second action scene (a boy kicks; a duck swims) | | | the same | sto |

Verb items keep the verb's gender with the doer (the rabbit and the fish are "he", the cat and Nitzi "she"). The options of .9 to .12 have no picture: each is a sound button, so the child chooses by the word heard.
**Hint ladder.** (1) The word again, and the diagnostic line: SEM "זֶה דּוֹמֶה. בּוֹאוּ נִשְׁמַע שׁוּב."; SOUNDALIKE "שִׁמְעוּ עַד הַסּוֹף." (2) The word card: the picture with its meaning line (`m-…`, §5), then the two pictures side by side, each named. (3) Show me: the voice names each option, then says the target with its picture lit; the child taps it.
**LS09 (optional, unscored):** after a correct pick, say-together + the word clip. With the parent's voice switch on: confident → heard + the word clip ("שָׁמַעְתִּי: שִׂיחַ!"); unsure → say-together and the voice models the word. Never evidence.

### HEB-A-03 Sorts pictures into simple categories (OL)
**Template:** LS01 `sort_drag` with picture cards (`con`) and LS01 odd one out (`pic`). Bins: בַּעֲלֵי חַיִּים, אֹכֶל, בְּגָדִים (the bin label is heard on a tap, with a picture of a typical member). "בַּעֲלֵי חַיִּים", not "חַיּוֹת": many children use חַיּוֹת for wild animals only, and the set includes a butterfly and an ant.

**The bins (the same in the sorts and the odd ones out).** Each bin is an open box with its typical member's picture on the front: animals the elephant (פִּיל), food the banana (בָּנָנָה), clothes the plain shirt (חֻלְצָה). None of them is a card in an odd-one-out item, and none looks like a trap card (for the design-director).

**Every scored odd one out names its kind and shows its bin** (frame §4.4 H4). The three cards sit in the kind's box, and the prompt is the kind's line (`i-odd-animals`, `i-odd-food`, `i-odd-clothes`, §3, `text-ready`); the bare `i-odd` names no kind and is never the prompt of a scored item. With no kind named, the colour answer (A-03.4: the dog is the only one that is not yellow) and the theme answer are both defensible, and an unclear question never makes an answer wrong. So CAT-THEME and CAT-LOOK are evidence only in an item that named the kind: every odd one out below names it, and every sort shows both bins with their labels. Young children readily group things that go together, and look for things of one kind when the kind is named (Markman and Hutchinson 1984).

| Item | Template | Cards or options | Right | Traps and tags | Rep |
|---|---|---|---|---|---|
| A-03.1 P | sort, animals / food | rabbit, butterfly, carrot, bread | animals: rabbit, butterfly; food: carrot, bread | carrot → animals [CAT-THEME] · butterfly → food [CAT-ATYPICAL] | con |
| A-03.2 P | sort, food / clothes | cake, strawberry, shirt, apron, dress with strawberries | food: cake, strawberry; clothes: shirt, apron, dress | apron → food [CAT-THEME] · strawberry dress → food [CAT-LOOK] | con |
| A-03.3 P | sort, animals / clothes | cat, horse, tortoise, sandal, hat with cat ears | animals: cat, horse, tortoise; clothes: sandal, hat | tortoise → clothes [CAT-ATYPICAL] · cat-ear hat → animals [CAT-LOOK] | con |
| A-03.4 P | odd one out (3), the animals box; i-odd-animals | dog, yellow chick, yellow ball | the ball | dog [CAT-LOOK: grouped chick and ball by colour] · chick [CAT-THEME: grouped dog and ball] | pic |
| A-03.5 P | odd one out, the food box; i-odd-food | pizza, pita, plate | the plate | pizza [CAT-LOOK: pita and plate are round and pale] · pita [CAT-THEME: pizza goes on a plate] | pic |
| A-03.6 P | odd one out, the clothes box; i-odd-clothes | striped shirt, swimsuit, striped towel | the towel | swimsuit [CAT-LOOK] · shirt [CAT-THEME: swimsuit and towel go to the sea] | pic |
| A-03.7 C | odd one out, the animals box; i-odd-animals | cat, sheep, ball of white wool | the wool | cat [CAT-LOOK: sheep and wool are white and woolly] · sheep [CAT-THEME: a cat plays with wool] | pic |
| A-03.8 C | sort, animals / food (new set); i-sort-cat | rooster, ant, cookie, egg | animals: rooster, ant; food: cookie, egg | egg → animals [CAT-THEME] · ant → food [CAT-ATYPICAL] | con |
| A-03.9 C | odd one out, the animals box; i-odd-animals | horse, butterfly, butterfly kite | the kite | horse [CAT-LOOK: butterfly and kite look alike] · butterfly [CAT-ATYPICAL] | pic |

**The checks (approved, frame §4.4 H4).** The A-03 check was "say why (tap the category picture)". Its wrong options (the other categories) reveal nothing nameable, so it cannot carry two tagged distractors. The checks are A-03.7 to .9 instead (new pictures, an untypical member). **A child's two A-03 checks are A-03.8 (a sort, always) and one odd one out (A-03.7 or .9)**: "not" is a load for 3-to-4-year-olds, and the sort asks no "not". The "why" stays as unscored talk: after an odd one out the voice says why + the bin label ("כִּי אֵלֶּה… בַּעֲלֵי חַיִּים!") with the bin picture.
**Hint ladder.** (1) Each card named by the voice, with the bin labels (diagnostic: THEME "הֵם הוֹלְכִים יַחַד. בּוֹאוּ נִבְדֹּק מֵאֵיזֶה סוּג הֵם."; LOOK "הֵם דּוֹמִים בַּצֶּבַע. מָה הֵם בֶּאֱמֶת?"; ATYPICAL "גַּם זֶה חַי: זֶה זָז וְאוֹכֵל."). (2) The bin opens as a family of 4 typical members, and the card is shown beside them (a new representation: a set, not a label). (3) Show me: the voice puts one card in its bin and names why; the child puts the rest.

### HEB-A-04 Follows a one-step instruction with a place word (OL)
**Template:** LS11 `listen_do` drag into a scene (`emb`) and LS01 picture choice for a heard sentence (`pic`). Place words: עַל, מִתַּחַת לְ, בְּתוֹךְ, לְיַד. In LS11 the drop zones are the three places; the thing never changes.

| Item | Template | Prompt | Right | Distractors | Rep |
|---|---|---|---|---|---|
| A-04.1 P | LS11 drag | pl-1 שִׂימוּ אֶת הַכַּדּוּר עַל הַכִּסֵּא. | on the chair | under [PREP] · next to [PREP] | emb |
| A-04.2 P | LS11 drag | pl-2 שִׂימוּ אֶת הַדֻּבִּי בְּתוֹךְ הַקֻּפְסָה. | in the box | on [PREP] · next to [PREP] | emb |
| A-04.3 P | LS11 drag | pl-3 שִׂימוּ אֶת הֶחָתוּל מִתַּחַת לַשֻּׁלְחָן. | under the table | on [PREP] · next to [PREP] | emb |
| A-04.4 P | LS11 drag | pl-4 שִׂימוּ אֶת הַבֻּבָּה לְיַד הַמִּטָּה. | next to the bed | on [PREP] · under [PREP] | emb |
| A-04.5 P | LS01 | pl-5 הַכַּדּוּר עַל הַקֻּפְסָה. | ball on box | box on ball [ROLE-SWAP] · ball in box [PREP] | pic |
| A-04.6 P | LS01 | pl-6 הֶחָתוּל בְּתוֹךְ הַסַּל. | cat in basket | basket upside down on the cat [ROLE-SWAP] · cat next to basket [PREP] | pic |
| A-04.7 P | LS01 | pl-7 הַכֶּלֶב מִתַּחַת לַכִּסֵּא. | dog under chair | dog on chair [ROLE-SWAP] · dog next to chair [PREP] | pic |
| A-04.8 P | LS01 | pl-8 הַצִּפּוֹר עַל הַסִּירָה. | bird on boat | a small boat on a big bird [ROLE-SWAP] · bird in the boat [PREP] | pic |
| A-04.9 C | LS11 drag, a new object | pl-9 שִׂימוּ אֶת הַכּוֹבַע עַל הַשֻּׁלְחָן. | on the table | under [PREP] · next to [PREP] | emb |
| A-04.10 C | LS01, a new object | pl-10 הַתַּפּוּחַ בְּתוֹךְ הַקְּעָרָה. | apple in bowl | bowl upside down on the apple [ROLE-SWAP] · apple next to bowl [PREP] | pic |

**Hint ladder.** (1) The sentence again, the place word stressed a little (diagnostic: PREP "שִׁמְעוּ אֵיפֹה:" + the place word clip; ROLE-SWAP "עַל מַה מְדַבְּרִים?" + the thing's word clip). (2) The companion acts it out with itself and a box, saying the place word (embodied, a new representation). (3) Show me: the thing moves to its place while the sentence plays; the child drags it there.

### HEB-A-05 Understands one and many (OL)
**Template:** LS01 picture choice (`pic`) and LS01 sort of **audio cards** (`con`): a card plays a word when tapped and has no picture, so the child sorts by the ending heard, not by counting. The pick items all ask for the plural, because "אֵיפֹה יֵשׁ חָתוּל?" would also be true of a picture of many cats.

| Item | Template | Prompt | Right | Distractors | Rep |
|---|---|---|---|---|---|
| A-05.1 P | LS01 | i-find + חֲתוּלִים | many cats | one cat [PLURAL] · many dogs [SEM] | pic |
| A-05.2 P | LS01 | i-find + כַּדּוּרִים | many balls | one ball [PLURAL] · many dolls [SEM] | pic |
| A-05.3 P | LS01 | i-find + בֻּבּוֹת | many dolls | one doll [PLURAL] · many teddies [SEM] | pic |
| A-05.4 P | LS01 | i-find + עוּגוֹת | many cakes | one cake [PLURAL] · many pizzas [SEM] | pic |
| A-05.5 P | LS01 | i-find + סוּסִים | many horses | one horse [PLURAL] · many donkeys [SEM] | pic |
| A-05.6 P | LS01 | i-find + סִירוֹת | many boats | one boat [PLURAL] · many planes [SEM] | pic |
| A-05.7 P | LS01 sort, audio cards | i-sort-cat; cards דָּג, דָּגִים, בֻּבָּה, בֻּבּוֹת | one: דָּג, בֻּבָּה; many: דָּגִים, בֻּבּוֹת | any card in the other bin [PLURAL]; the -וֹת card is the harder trap | con |
| A-05.8 C | LS01, a new noun | i-find + בֵּיצִים | many eggs | one egg [PLURAL] · many apples [SEM] | pic |
| A-05.9 C | LS01 sort, audio cards | cards כֶּלֶב, כְּלָבִים, עוּגָה, עוּגוֹת | one: כֶּלֶב, עוּגָה; many: כְּלָבִים, עוּגוֹת | [PLURAL] (כְּלָבִים changes inside the word too) | con |

בֵּיצִים is a feminine noun with ־ִים: a check that the child hears the ending, not the gender.
**Hint ladder.** (1) Both forms said, one after the other ("חָתוּל… חֲתוּלִים"; diagnostic PLURAL "שִׁמְעוּ אֶת הַסּוֹף:" + the plural clip; SEM: the SEM line of §6). (2) The singular under one picture and the plural under many, the ending heard twice (a new representation: a pair). (3) Show me: the voice says the word while the right picture fills with more and more; the child taps it.

### HEB-A-06 Completes a rhyme in a familiar verse (PA)
**Template:** LS12 rhyme mode (`sto`): the verse plays with a pause before its last word (clip `v<n>-open`), 3 picture choices, then the whole verse (`v<n>-full`). The verses are original (decision 3); they are said with a beat, not sung, so no melody needs the owner's OK. Each verse plays twice before its first pause ("familiar").

| Item | Verse (open line … the pause) | Right | Distractors |
|---|---|---|---|
| A-06.1 P | v1 בַּשָּׁמַיִם יֵשׁ כּוֹכָב, / וּבַגִּנָּה קוֹפֵץ… | אַרְנָב | כּוֹס [ALLIT: starts like כּוֹכָב] · חָתוּל [SEM: fits the garden, does not rhyme] |
| A-06.2 P | v2 תִּיק־תַּק עוֹשֶׂה הַשָּׁעוֹן, / וְהֶחָתוּל יוֹשֵׁב… (full: …בַּחַלּוֹן) | חַלּוֹן | שֶׁמֶשׁ [ALLIT] · סַל [SEM] |
| A-06.3 P | v3 זוֹרְקִים לְמַעְלָה כַּדּוּר, / אוֹפִים עוּגָה… (full: …בַּתַּנּוּר) | תַּנּוּר | כַּף [ALLIT] · קְעָרָה [SEM] |
| A-06.4 P | v4 לַיָּרֵחַ טָס לוֹ טִיל, / וּבַגַּן מְטַיֵּל לוֹ… | פִּיל | טַבַּעַת [ALLIT] · גָּמָל [SEM] |
| A-06.5 P | v5 בַּסַּל יֵשׁ תּוּת, / וּבַיָּד שֶׁל סַבְתָּא… | חוּט | תַּפּוּחַ [ALLIT] · מַחַט [SEM] |
| A-06.6 P | v6 בַּשָּׁמַיִם עָף מָטוֹס, / וְעַל הַשֻּׁלְחָן יֵשׁ… | כּוֹס | מִטְרִיָּה [ALLIT] · צַלַּחַת [SEM] |
| A-06.7 P | v7 יֵשׁ לַדֻּבִּי אַף, / וּבַמָּרָק יֵשׁ… | כַּף | אַרְנָב [ALLIT] · מַזְלֵג [SEM] |
| A-06.8 C | v8 (new) עַל הַמַּיִם שָׁטָה סִירָה, / וּבַגַּן שָׁרָה… (full: …הַמּוֹרָה) | מוֹרָה | סוּס [ALLIT] · יַלְדָּה [SEM] |

Every rhyme pair shares its stressed vowel and what follows: ‑av (כּוֹכָב, אַרְנָב), ‑on (שָׁעוֹן, חַלּוֹן), ‑ur (כַּדּוּר, תַּנּוּר), ‑il (טִיל, פִּיל), ‑ut (תּוּת, חוּט), ‑os (מָטוֹס, כּוֹס), ‑af (אַף, כַּף), ‑ra (סִירָה, מוֹרָה). All are stressed on the last syllable, so the rhyme is real in speech. A prefix the verse needs (בַּחַלּוֹן, בַּתַּנּוּר, הַמּוֹרָה) is heard only in the full line; the open line stops before it, and the options are the bare words. In v4, טַבַּעַת (a ring) is the ALLIT distractor because it starts with ט and does not rhyme.
**Hint ladder.** (1) The first line's end word again, then the diagnostic line (ALLIT "זֶה מַתְחִיל אוֹתוֹ דָּבָר. בּוֹאוּ נַקְשִׁיב לַסּוֹף."; SEM "זֶה מַתְאִים. בּוֹאוּ נַקְשִׁיב לַסּוֹף."). (2) The ends only: the voice says the end of the first line's word (the `e-` clip, "כָב") and each option's word after it, so the child hears which one ends the same (a new representation: the ends alone). (3) Show me: the whole verse with the right picture lit on the rhyme; the child taps it.

### HEB-A-07 Tells which word rhymes with a word (PA)
**Template:** LS01 with a sound per option (`pic`; the cue word plays with its picture), 3 pictures, a guided 2-picture step first; check by LS01 `match_pairs` (two pairs only, Band A).

| Item | Cue | Right | Distractors |
|---|---|---|---|
| A-07.1 P | דָּג | גַּג | דֻּבִּי [ALLIT] · יָם [SEM] |
| A-07.2 P | פִּיל | טִיל | פִּיצָה [ALLIT] · גָּמָל [SEM] |
| A-07.3 P | כַּף | אַף | כַּדּוּר [ALLIT] · מַזְלֵג [SEM] |
| A-07.4 P | כּוֹכָב | זָנָב | כּוֹס [ALLIT] · יָרֵחַ [SEM] |
| A-07.5 P | בָּלוֹן | אָרוֹן | בֻּבָּה [ALLIT] · כַּדּוּר [SEM] |
| A-07.6 P | תּוּת | חוּט | תַּרְנְגוֹל [ALLIT] · בָּנָנָה [SEM] |
| A-07.7 P | בַּיִת | זַיִת | בֵּיצָה [ALLIT] · אֹהֶל [SEM] |
| A-07.8 P | תַּנּוּר | כַּדּוּר | תַּפּוּחַ [ALLIT] · עוּגָה [SEM] |
| A-07.9 C | match pairs: כַּף, אַף, כַּדּוּר, תַּנּוּר | כַּף–אַף, כַּדּוּר–תַּנּוּר | כַּף–כַּדּוּר [ALLIT] · כַּף–תַּנּוּר [SEM: kitchen things] |
| A-07.10 C | match pairs: כּוֹכָב, זָנָב, כּוֹס, מָטוֹס | כּוֹכָב–זָנָב, כּוֹס–מָטוֹס | כּוֹכָב–כּוֹס [ALLIT] · כּוֹכָב–מָטוֹס [SEM: both in the sky] |

בַּיִת / זַיִת rhyme on the stressed בַּ/זַ and the ending ‑יִת, both stressed on the first syllable.
**Hint ladder.** As A-06: (1) the cue and the option said with the ends stretched, and the diagnostic line; (2) the ends alone (the `e-` clips, "דּוּר… נוּר"); (3) show me: the two rhyming pictures move together and the voice says both; the child taps.

### HEB-A-08 Claps and counts the syllables of a word (PA)
**Template:** LS03 drum mode (`emb`: tap a drum once per syllable while the word plays slowly, then once more at normal speed) and LS01 "the strip with that many beats" (`pic`; strips of 1, 2 and 3 drums). Classifier and tag: a count of ±1 is M-HEB-SYLL; in the strip items both wrong strips carry it. Words with **open syllables only** (`syllabus.md` §2), stress kept natural.

| Item | Template | Word (picture) | Right | Distractors |
|---|---|---|---|---|
| A-08.1 P | drum | דָּג | 1 | 2, 3 [SYLL] |
| A-08.2 P | drum | דֻּבִּי | 2 | 1, 3 [SYLL] |
| A-08.3 P | drum | בָּנָנָה | 3 | 2, 4 [SYLL] |
| A-08.4 P | drum | פִּיל | 1 | 2, 3 [SYLL] |
| A-08.5 P | drum | עוּגָה | 2 | 1, 3 [SYLL] |
| A-08.6 P | drum | מַתָּנָה | 3 | 2, 4 [SYLL] |
| A-08.7 P | strip | בֻּבָּה | 2 drums | 1, 3 [SYLL] |
| A-08.8 P | strip | כּוֹס | 1 drum | 2, 3 [SYLL] |
| A-08.9 P | strip | חֲתוּלָה | 3 drums | 1, 2 [SYLL] |
| A-08.10 P | strip | סִירָה | 2 drums | 1, 3 [SYLL] |
| A-08.11 C | drum, a 3-syllable word not practised | עֲגָלָה | 3 | 2, 4 [SYLL] |
| A-08.12 C | strip | אֳנִיָּה | 3 drums | 1, 2 [SYLL] |

Not used in A-08 on purpose: words with a shva at the start (גְּלִידָה is 2 beats in speech and 3 when a child says it slowly), a patah gnuva (תַּפּוּחַ), or a closed syllable inside (אַרְנָב). They come in B-07 and B-08.
**Hint ladder.** (1) The word said slowly with a pause between beats (diagnostic SYLL: "בּוֹאוּ נִסְפֹּר לְאַט."). (2) The friend's jaw drops once per beat, with a hand under the chin (a new representation: feel, not hear; the beat is seen). (3) Show me: the drum beats with the word, the count shown as dots; the child drums it.

### HEB-A-09 Blends spoken syllables into a word (PA)
**Template:** LS03 (the puppet parrot says the syllables, about 0.5 s apart: the `u-` clips) + LS01 picture choice (`pic`); the second representation is the drum strip (`con`): the child taps the drums in order, right to left, each plays its syllable, then picks the picture.

| Item | Syllables heard | Right | Distractors |
|---|---|---|---|
| A-09.1 P | בֻּ… בָּה | בֻּבָּה | בֻּעָה [BLEND-FIRST] · סָבָא [BLEND-LAST] |
| A-09.2 P | פִּי… צָה | פִּיצָה | פִּיל [BLEND-FIRST] · בֵּיצָה [BLEND-LAST] |
| A-09.3 P | סִי… רָה | סִירָה | סִיר [BLEND-FIRST] · מוֹרָה [BLEND-LAST] |
| A-09.4 P | אַ… בָּא | אַבָּא | אַף [BLEND-FIRST] · סָבָא [BLEND-LAST] |
| A-09.5 P | בָּ… נָ… נָה | בָּנָנָה | בַּיִת [BLEND-FIRST] · מַתָּנָה [BLEND-LAST] |
| A-09.6 P | מַ… תָּ… נָה | מַתָּנָה | מָטוֹס [BLEND-FIRST] · בָּנָנָה [BLEND-LAST] |
| A-09.7 P | חֲ… תוּ… לָה | חֲתוּלָה | חָלָב [BLEND-FIRST] · עֲגָלָה [BLEND-LAST] |
| A-09.8 P (drum strip) | עֲ… גָ… לָה | עֲגָלָה | עֲנָנִים [BLEND-FIRST] · חֲתוּלָה [BLEND-LAST] |
| A-09.9 C | עֲ… טַ… לֵּף (never heard in the app) | עֲטַלֵּף | עֲנָנִים [BLEND-FIRST] · צִפּוֹר [SEM: another night flyer] |

**Hint ladder.** (1) The syllables again, closer together (diagnostic: FIRST "שִׁמְעוּ עַד הַסּוֹף."; LAST "שִׁמְעוּ מֵהַהַתְחָלָה."). (2) The drum strip: one drum per syllable, the child taps them in order and hears them run together faster each time (a new representation: concrete). (3) Show me: the parrot says the syllables, then the whole word, and the picture lights; the child taps it.

### HEB-A-10 Tells letters from numerals, shapes and drawings (PK)
**Template:** LS01 `sort_drag` with text cards (`con`; bins i-bin-letters and i-bin-other) and LS01 "tap all the letters" (`sym`). Letters are Hebrew print letters in Heebo 700, unpointed (a single letter, not a word). No Latin letters: they are letters too, so "letter or not" would have no single answer. The look-alikes are on purpose: 7 beside ז, 0 and ○ beside ס, 1 beside ו.

| Item | Template | Cards or row | Letters (right) | Traps and tags |
|---|---|---|---|---|
| A-10.1 P | sort | ב, ר, ת, 5, ● | ב, ר, ת | 5 [PRINT-NUM] · ● [PRINT-SHAPE] |
| A-10.2 P | sort | ש, מ, ל, 7, ⭐ | ש, מ, ל | 7 [PRINT-NUM] · ⭐ [PRINT-SHAPE] |
| A-10.3 P | tap all | א, 2, ס, ○, ל | א, ס, ל | 2 [PRINT-NUM] · ○ [PRINT-SHAPE] |
| A-10.4 P | tap all | ו, 1, ד, △, נ | ו, ד, נ | 1 [PRINT-NUM] · △ [PRINT-SHAPE] |
| A-10.5 P | tap all | ז, 7, ס, 0, ♥ | ז, ס | 7, 0 [PRINT-NUM] · ♥ [PRINT-SHAPE] |
| A-10.6 C | sort, a new font (Secular One) | ק, פ, ה, 9, ✿ | ק, פ, ה | 9 [PRINT-NUM] · ✿ [PRINT-SHAPE] |

**Hint ladder.** (1) "בָּאוֹתִיּוֹת קוֹרְאִים וְכוֹתְבִים." (diagnostic NUM: "בָּזֶה סוֹפְרִים."; SHAPE: "זֶה צִיּוּר."). (2) Each card shown in its home: the letter inside a word on a book page, the numeral on a die, the shape on a toy (a new representation: context). (3) Show me: the voice puts one card of each kind in its bin; the child sorts the rest.

### HEB-A-11 Recognises their own written name (PK; on the device only)
**Template:** LS01 text options (`sym`). The name never leaves the device and is never voiced (decision 25; `docs/PLAN.md` child safety). All names are shown **without nikud** (Heebo 700): the child's name is typed by a parent, and nikud would be a cue the other names do not share; a pointed name is shown with its marks removed (removing marks is not generating them). **No-name fallback:** the child's companion's name stands in (ניצי by default).
**Distractor names** come from a closed list, never made up at runtime: **NAME-FIRST** a name with the same first letter; **NAME-LENGTH** a name with the same number of letters and another first letter; never a name equal to the child's. The list (all `text-ready`: 52 names, 43 ordinary Israeli first names and the 9 names of the cast, spelt in the usual way; ordinary Israeli first names, two to five letters, both genders): אורי, אלה, בן, בר, גיל, גפן, דן, דנה, הדר, הילה, ורד, זיו, זוהר, חן, חיים, טל, טליה, יעל, יונתן, כרמל, כנרת, ליה, לביא, מאיה, מיכאל, נועה, ניר, סהר, סתיו, עומר, עדי, פז, פלג, צור, צליל, קרן, קשת, רון, רוני, שירה, שקד, תמר, תום, and the cast names ניצי, נקודי, גוני, קובי, טימי, צעדון, פנינה, נוגה, איתן. If no name in the list has the same first letter, the second distractor is a name whose first letter is the look-alike of the child's (M-HEB-SHAPE pair, `syllabus.md` §5).

| Item | Template | Options | Right | Distractors |
|---|---|---|---|---|
| A-11.1 P (guided) | LS01, 2 names | i-name | the child's name | the NAME-LENGTH name (the NAME-FIRST name is the item's hidden second distractor) |
| A-11.2 P | LS01, 3 names | i-name | the child's name | a NAME-FIRST name [NAME-FIRST] · a NAME-LENGTH name [NAME-LENGTH] |
| A-11.3 P | LS01, a row of 3 letters under the name | i-name-letter | the name's first letter (the rightmost) | its look-alike (ב→כ, ד→ר, ה→ח, ו→ז, ס→ם, ע→צ, ג→נ, ט→מ, and back) [M-HEB-SHAPE-*] · the name's last letter [ORDER: read from the left] |
| A-11.4 C | LS01, 3 names, in Secular One | i-name | the child's name | [NAME-FIRST] · [NAME-LENGTH] |
| A-11.5 C (after a day away) | as A-11.3 | | | |

Where the last letter equals the first, or has no look-alike, the item uses the next rule: a letter of the friend's name.
**Hint ladder.** (1) "הַשֵּׁם שֶׁלָּכֶם מַתְחִיל בָּאוֹת הַזֹּאת." while the first letter of the name lights in the model card at the top (diagnostic FIRST: "גַּם זֶה מַתְחִיל כָּךְ. בּוֹאוּ נִרְאֶה אֶת כׇּל הַשֵּׁם."; LENGTH: "זֶה אָרֹךְ כְּמוֹ הַשֵּׁם שֶׁלָּכֶם, אֲבָל הָאוֹתִיּוֹת אֲחֵרוֹת."). (2) The model name is laid over each option, letter on letter (a new representation: matching shapes). (3) Show me: the right name glows and the companion points; the child taps it.

### HEB-A-12 Knows that print runs right to left and carries the words read (PK)
**Template:** LS08 `listen` with the text shown (story pages of §5) and LS01 tap zones (`sym`). This is the only Band A use of written sentences; the child reads nothing, the voice reads.

| Item | Page | Prompt | Right | Distractors |
|---|---|---|---|---|
| A-12.1 P | story 1, page 1 (two lines) | i-start | the start of the top line (its right end) | the left end of the top line [ORDER] · the picture [PRINT-PICTURE] |
| A-12.2 P | story 1, page 2 | i-start | the right end of the top line | the left end of the bottom line [ORDER] · the picture [PRINT-PICTURE] |
| A-12.3 P | story 2, page 1 (one line) | i-start | the right end | the left end [ORDER] · the picture [PRINT-PICTURE] |
| A-12.4 P | story 1, page 5 | i-follow: the voice reads one word, waits for a tap on it, then the next | each word in order, right to left | a tap on a word to the left of the next one [ORDER] · a tap on the picture [PRINT-PICTURE] |
| A-12.5 P | story 2, page 4 | i-follow | as .4 | as .4 |
| A-12.6 C | story 3, page 3 (new) | i-start | the right end | the left end [ORDER] · the picture [PRINT-PICTURE] |
| A-12.7 C | story 3, page 5 | i-follow | as .4 | as .4 |

**Hint ladder.** (1) "זוֹ תְּמוּנָה. קוֹרְאִים אֶת הַמִּלִּים." or "מַתְחִילִים כָּאן." with the reading arrow over the line (diagnostic ORDER and PRINT-PICTURE). (2) The voice reads the line while a finger moves under the words from right to left (a new representation: motion). (3) Show me: the finger stops at the start and the voice says "מַתְחִילִים כָּאן."; the child taps there. In i-follow items the voice's word-by-word clips are cut from the page clip with word timing (frame §2.3 LS08), so they cost no extra characters.

### HEB-A-13 Puts 3 story pictures in order (OL)
**Template:** LS01 sequence (`pic`): three picture tiles into three slots **right to left** (the first slot is the rightmost, with a small "start" arrow); and LS01 "what happened first" (`sto`). Classifiers: the right order laid left to right → **M-HEB-ORDER**; two pictures swapped → **M-HEB-STORY-ORDER**.

| Item | Story | Pictures (in order) | Distractors |
|---|---|---|---|
| A-13.1 P | 1 | the rabbit kicks (p2) · the cat finds the ball (p4) · they play together (p5) | the order reversed [ORDER] · a swap [STORY-ORDER] |
| A-13.2 P | 2 | flour and egg in the bowl (p2) · the cake goes into the oven (p4) · everyone eats (p5) | as .1 |
| A-13.3 P | 1, "what happened first?" (i-first) | the rabbit kicks | the cat finds the ball [STORY-ORDER] · they play together [STORY-ORDER, the last event] |
| A-13.4 P | 2, i-first | Nitzi mixes | the oven [STORY-ORDER] · eating [STORY-ORDER] |
| A-13.5 C | 3 (new) | the hat flies off (p2) · the fish brings the hat (p4) · "thank you" (p5) | as .1 |

**Hint ladder.** (1) "מַה קָּרָה קֹדֶם?" and the first picture's page line replayed. (2) The three pages replayed in order with the seq clips ("קֹדֶם… אַחַר כָּךְ… בַּסּוֹף") (a new representation: the story told, not the pictures). (3) Show me: the first picture moves into the first slot; the child places the other two.

### HEB-A-14 Traces the pre-writing strokes (WR)
**Template:** LS02 trace mode (`emb`): the full dotted path with the start dot, then the start dot only. Each stroke is a picture path: the finger takes something along it. Classifiers (the existing ones of `trace`): a stroke started at the far end or drawn the other way → **M-HEB-STROKE** (both are its signals); leaving the path is not a tag, only a retry. **A trace-only node (rule E-1, 2026-11-06; `writing-mastery.md` §2.2):** every answer here is practice, so M-HEB-STROKE only picks the feedback line and is never misconception evidence; A-14 is **met once** .5 to .8 (each stroke with the start dot only) are done at hint level 0 or 1, it is never mastered, probed or checked, and it never holds back the S1 letters.

| Item | Stroke | The picture path | Right |
|---|---|---|---|
| A-14.1 P | down | a raindrop falls from a cloud to a flower | top to bottom |
| A-14.2 P | across, right to left | a car drives along a road to its house on the left side of the screen | from the right end to the left end |
| A-14.3 P | arch | a rabbit hops over a hill | from the left foot, up and over, down to the right foot (the school arch, strokes.md §5.3) |
| A-14.4 P | circle | a ladybird walks around a round pond | from the top, round to the right and back (clockwise, like print ס; strokes.md §5.3) |
| A-14.5 P | down, start dot only | rain on another flower | as .1 |
| A-14.6 P | across, start dot only | a boat to its jetty on the left | as .2 |
| A-14.7 P | arch, start dot only | a ball bouncing over a fence | as .3 |
| A-14.8 P | circle, start dot only | a fish around a stone | as .4 |
| A-14.9 P | a combined stroke, start dot only (practice; was the check before E-1) | a door: across the top from left to right, then the right side down, then the left side down (like print ח) | each stroke from its start |

**Direction notes.** Down and right to left are the two directions of Hebrew print (the Ministry: "right to left and top to bottom"). The arch from the right and the counter-clockwise circle from the top follow the reading direction; they are **to be confirmed** against the design-director's print stroke data (F6) and school references before the paths are drawn; the evidence for a pre-writing direction is thin.
**Unscored play beside it:** scribble-writing a card for a friend (no check; the card is kept on the device only until the visit ends).
**Hint ladder.** (1) The start dot pulses and an arrow shows the way (diagnostic: "מַתְחִילִים כָּאן."). (2) The thing on the path moves slowly along it once (motion, a new representation). (3) Full guide (trace mode with the dotted path), and the child traces.

## 5. The stories (LS08 `dialogic`; A-01, A-02, A-12, A-13)

Original, 5 pages, at most 8 words in a sentence, 3–4 target words, 2 pauses with a picture question, a recast after the answer, a word card per target word and a parent co-play card. All Hebrew `text-ready`. The characters are the app's own original cast (Nitzi; Kubi the tortoise) and plain animals.

**Story 1: הַכַּדּוּר שֶׁל הָאַרְנָב (the rabbit's ball).** Target words: בּוֹעֵט, שִׂיחַ, מְחַפֶּשֶׂת (and כַּדּוּר).

| Clip | Page text | Picture |
|---|---|---|
| s1-p1 | הָאַרְנָב מְשַׂחֵק בַּגִּנָּה. יֵשׁ לוֹ כַּדּוּר אָדֹם. | a rabbit with a red ball in a garden; a tree and a bush |
| s1-p2 | הָאַרְנָב בּוֹעֵט חָזָק. הַכַּדּוּר עָף גָּבוֹהַּ! | the kick; the ball high in the air |
| s1-p3 | הַכַּדּוּר נוֹפֵל לְתוֹךְ הַשִּׂיחַ. אֵיפֹה הוּא? | the ball half hidden in the bush; the rabbit looking; the tree beside |
| s1-p4 | הַחֲתוּלָה מְחַפֶּשֶׂת בַּשִּׂיחַ. הִנֵּה הַכַּדּוּר! | a cat with her head in the bush, the ball in her paws |
| s1-p5 | עַכְשָׁו הָאַרְנָב וְהַחֲתוּלָה מְשַׂחֲקִים יַחַד. | both playing with the ball |
| s1-q1 (after p3) | לְאָן נָפַל הַכַּדּוּר? | options: bush ✓, tree [STORY-SEEN], window [STORY-WORLD] |
| s1-r1 | נָכוֹן! הַכַּדּוּר נָפַל לְתוֹךְ הַשִּׂיחַ. | recast |
| s1-q2 (after p4) | מִי מָצְאָה אֶת הַכַּדּוּר? | options: cat ✓, rabbit [STORY-ROLE], dog [STORY-WORLD] |
| s1-r2 | נָכוֹן! הַחֲתוּלָה מָצְאָה אֶת הַכַּדּוּר. | recast |

**Story 2: נִיצִי אוֹפָה עוּגָה (Nitzi bakes a cake).** Target words: קֶמַח, קְעָרָה, מְעַרְבֶּבֶת, תַּנּוּר.

| Clip | Page text | Picture |
|---|---|---|
| s2-p1 | נִיצִי רוֹצָה לֶאֱפוֹת עוּגָה. | Nitzi in a kitchen, an apron on |
| s2-p2 | הִיא שָׂמָה קֶמַח וּבֵיצָה בַּקְּעָרָה. | flour and an egg going into a bowl; a spoon on the table |
| s2-p3 | הִיא מְעַרְבֶּבֶת, מְעַרְבֶּבֶת, מְעַרְבֶּבֶת. | Nitzi stirring, the batter swirling |
| s2-p4 | הָעוּגָה נִכְנֶסֶת לַתַּנּוּר. | the cake tin going into the oven; the empty bowl on the counter |
| s2-p5 | אֵיזֶה רֵיחַ טוֹב! כֻּלָּם אוֹכְלִים עוּגָה. | Nitzi and friends eating cake |
| s2-q1 (after p2) | מַה שָּׂמָה נִיצִי בַּקְּעָרָה? | options: egg ✓, spoon [STORY-SEEN], apple [STORY-WORLD] |
| s2-r1 | נָכוֹן! נִיצִי שָׂמָה בֵּיצָה בַּקְּעָרָה. | recast |
| s2-q2 (after p4) | לְאָן נִכְנְסָה הָעוּגָה? | options: oven ✓, bowl [STORY-SEEN], fridge [STORY-WORLD] |
| s2-r2 | נָכוֹן! הָעוּגָה נִכְנְסָה לַתַּנּוּר. | recast |

**Story 3 (the check story): הַכּוֹבַע שֶׁל קוּבִּי (Kubi's hat).** Target words: סִירָה, כּוֹבַע, רוּחַ, שׂוֹחֶה. Used only for checks (A-01.7–8, A-12.6–7, A-13.5).

| Clip | Page text | Picture |
|---|---|---|
| s3-p1 | קוּבִּי הַצָּב יוֹשֵׁב בְּסִירָה קְטַנָּה. | Kubi in a little boat on a lake, a hat on his head |
| s3-p2 | פִּתְאוֹם רוּחַ חֲזָקָה! הַכּוֹבַע עָף. | the wind; the hat flying; the boat rocking |
| s3-p3 | הַכּוֹבַע נוֹפֵל לַמַּיִם. | the hat on the water |
| s3-p4 | דָּג קָטָן שׂוֹחֶה וּמֵבִיא אֶת הַכּוֹבַע. | a small fish pushing the hat to the boat |
| s3-p5 | "תּוֹדָה, דָּג!" אוֹמֵר קוּבִּי. | Kubi with his hat back on, waving to the fish |
| s3-q1 (after p2) | מָה עָף בָּרוּחַ? | options: hat ✓, boat [STORY-SEEN], kite [STORY-WORLD] |
| s3-r1 | נָכוֹן! הַכּוֹבַע עָף בָּרוּחַ. | recast |
| s3-q2 (after p4) | מִי הֵבִיא אֶת הַכּוֹבַע? | options: fish ✓, Kubi [STORY-ROLE], bird [STORY-WORLD] |
| s3-r2 | נָכוֹן! הַדָּג הֵבִיא אֶת הַכּוֹבַע. | recast |

**Word cards** (heard, with the picture; the meaning in words a 3-year-old knows):

| Clip | Word | Meaning line |
|---|---|---|
| m-boet | בּוֹעֵט | בּוֹעֲטִים בְּכַדּוּר בָּרֶגֶל, וְהוּא עָף רָחוֹק. |
| m-siach | שִׂיחַ | שִׂיחַ הוּא כְּמוֹ עֵץ קָטָן וְנָמוּךְ, עִם הַרְבֵּה עָלִים. |
| m-mechapeset | מְחַפֶּשֶׂת | מְחַפֶּשֶׂת זֶה לְנַסּוֹת לִמְצֹא מַשֶּׁהוּ. |
| m-kemach | קֶמַח | קֶמַח הוּא אֲבָקָה לְבָנָה. מִמֶּנּוּ אוֹפִים לֶחֶם וְעוּגוֹת. |
| m-keara | קְעָרָה | קְעָרָה הִיא כְּלִי עָגֹל וְעָמֹק. |
| m-meurbevet | מְעַרְבֶּבֶת | מְעַרְבֶּבֶת זֶה לְסוֹבֵב בְּכַף, וְהַכֹּל מִתְחַבֵּר. |
| m-tanur | תַּנּוּר | בַּתַּנּוּר חַם מְאֹד. בּוֹ אוֹפִים עוּגוֹת. |
| m-sira | סִירָה | סִירָה שָׁטָה עַל הַמַּיִם. |
| m-kova | כּוֹבַע | כּוֹבַע שָׂמִים עַל הָרֹאשׁ. |
| m-ruach | רוּחַ | רוּחַ זֶה אֲוִיר שֶׁזָּז. אֶת הָרוּחַ לֹא רוֹאִים, אֲבָל מַרְגִּישִׁים. |
| m-soche | שׂוֹחֶה | שׂוֹחֶה זֶה לָזוּז בְּתוֹךְ הַמַּיִם. |

(כַּדּוּר needs no card: it is a known word, used as the anchor.)

**Parent co-play cards** (parent text, unpointed, `text-ready`; shown at the end of each story in the parent's view):
- Story 1: "שאלו: מה היית עושה אם הכדור שלך היה נופל לשיח? מי עוזר לך כשמשהו הולך לאיבוד? אפשר גם לבקש מהילד להמציא סיפור משלו על כדור."
- Story 2: "אפו או הכינו משהו יחד, ותנו לילד לערבב. שאלו: מה שמנו קודם? מה אחר כך? הזכירו את המילים קמח, קערה ותנור."
- Story 3: "בגינה או באמבטיה אפשר לשחק: מה עף ברוח? מה צף על המים? ואחרי הסיפור שאלו: מי עזר לקובי, ולמה?"

## 6. Feedback by tag (the first-error lines, hint level 1)

All are in the ladders above; collected here (`text-ready`; the editor changed the lines that had a "לא", see `hebrew-notes.md` §9.3):

| Tag | Line |
|---|---|
| SEM | זֶה דּוֹמֶה. בּוֹאוּ נִשְׁמַע שׁוּב. |
| SOUNDALIKE | שִׁמְעוּ עַד הַסּוֹף. |
| STORY-ROLE | מִי עָשָׂה אֶת זֶה בַּסִּפּוּר? |
| STORY-SEEN | מַה שָּׁאַלְנוּ? |
| STORY-WORLD | בּוֹאוּ נִרְאֶה מַה קָּרָה בַּסִּפּוּר שֶׁלָּנוּ. |
| STORY-ORDER | מַה קָּרָה קֹדֶם? (the i-first clip) |
| CAT-THEME | הֵם הוֹלְכִים יַחַד. בּוֹאוּ נִבְדֹּק מֵאֵיזֶה סוּג הֵם. |
| CAT-LOOK | הֵם דּוֹמִים בַּצֶּבַע. מָה הֵם בֶּאֱמֶת? |
| CAT-ATYPICAL | גַּם זֶה חַי: זֶה זָז וְאוֹכֵל. |
| PREP | שִׁמְעוּ אֵיפֹה: (then the place word clip) |
| ROLE-SWAP | עַל מַה מְדַבְּרִים? (then the thing's word clip) |
| PLURAL | שִׁמְעוּ אֶת הַסּוֹף: (then the plural clip) |
| ALLIT | זֶה מַתְחִיל אוֹתוֹ דָּבָר. בּוֹאוּ נַקְשִׁיב לַסּוֹף. |
| SEM (rhyme) | זֶה מַתְאִים. בּוֹאוּ נַקְשִׁיב לַסּוֹף. |
| SYLL | בּוֹאוּ נִסְפֹּר לְאַט. |
| BLEND-FIRST | שִׁמְעוּ עַד הַסּוֹף. (shared clip) |
| BLEND-LAST | שִׁמְעוּ מֵהַהַתְחָלָה. |
| PRINT-NUM | בָּזֶה סוֹפְרִים. |
| PRINT-SHAPE | זֶה צִיּוּר. |
| PRINT-PICTURE | זוֹ תְּמוּנָה. קוֹרְאִים אֶת הַמִּלִּים. |
| ORDER, STROKE | מַתְחִילִים כָּאן. (one clip) |
| NAME-FIRST | גַּם זֶה מַתְחִיל כָּךְ. בּוֹאוּ נִרְאֶה אֶת כׇּל הַשֵּׁם. |
| NAME-LENGTH | זֶה אָרֹךְ כְּמוֹ הַשֵּׁם שֶׁלָּכֶם, אֲבָל הָאוֹתִיּוֹת אֲחֵרוֹת. |
| (letters) | בָּאוֹתִיּוֹת קוֹרְאִים וְכוֹתְבִים. |
| (name) | הַשֵּׁם שֶׁלָּכֶם מַתְחִיל בָּאוֹת הַזֹּאת. (the letter lights; the name and the letter are never said) |

## 7. Session shape for Band A visits (frame §3.5)

A visit (8 minutes) has: a warm-up (a verse the child knows, A-06), one focus (one or two new skills), revisit checks blocked by skill, and a delight segment (a story, listened to without questions on a second hearing). A story is heard once with its pauses before any A-12 or A-13 item uses it.

## 8. Counts

| What | Count |
|---|---|
| Skills | 14 (A-01 to A-14) |
| Items | 125: A-01 8 · A-02 18 · A-03 9 · A-04 10 · A-05 9 · A-06 8 · A-07 10 · A-08 12 · A-09 9 · A-10 6 · A-11 5 · A-12 7 · A-13 5 · A-14 9; of them 27 checks (C), every skill but A-14 (a trace-only node, E-1) with at least one, none a single 2-choice item; A-03's two checks per child are A-03.8 (a sort) and A-03.7 or .9 |
| Pictures | 91 objects (§2) + 14 plural sets + 8 action animations + 15 story pages + 9 stroke scenes |
| Word clips | 131 (words, plurals, verbs, bin labels, place and sequence words); 57 are `text-ready` (the syllabus lists and the editor's notes), 74 new |
| Stories | 3 (3 titles, 15 pages, 6 questions, 6 recasts, 11 word cards, 3 parent cards) |
| Verses | 8 (open and full clips) |
| New tags | 18 (`syllabus.md` §5), settled in the catalogue (frame §4.2): 7 MEANING (STORY-*, CAT-*), 3 GUESS (SOUNDALIKE, NAME-FIRST, NAME-LENGTH), 3 GRAMMAR, 2 SEGMENT, 3 PRINT; all diagnostic |
| Letters shown | 20 letters as print-awareness marks (A-10), none taught by name or sound (Band A) |

## 9. Voicing (plan only; Claude never runs a paid voice command)

`pronunciation.csv` holds a row per clip (`heb-a-…`), with its IPA, stress, traps and what the listener must hear. The character count is computed by script from the CSV (the text sent is `say` when it is filled, else `shown`); the voice-and-sound-director turns it into the real plan and cost, and the owner runs and pays.

Counted again by the editor on 2026-11-03 after the final wording (and again after the three kind lines got their voice text: 4,093 became 4,035, because those rows were counted pointed before) (the text sent is `say` when filled, else `shown`; spaces and punctuation count). The teacher's count before the edit was 5,400 pointed and 3,309 unpointed. The sentences are now sent as **voice text** (partial nikud, full spelling, no "!"; `hebrew-notes.md` §3 and §9.4), which is why the instruction, verse and story rows are about 35% shorter; the words, syllables and rhyme ends are still sent fully pointed until the pilot decides (§8.4 there):

| Clips | Rows | Characters as sent (the voice text) | Of them, letters without nikud |
|---|---|---|---|
| Words (`heb-a-w-…`, bins, place and sequence words) | 131 | 929 | 524 |
| Syllable clips (`heb-a-u-…`, A-08 slow and A-09) | 12 | 123 | 84 |
| Rhyme ends (`heb-a-e-…`) | 9 | 34 | 24 |
| Instructions, praise, hints, place sentences (`heb-a-i-…`, `ok-`, `d-`, `pl-` …) | 70 | 1,372 | 1,335 |
| Verses (open and full) | 16 | 514 | 480 |
| Stories (titles, pages, questions, recasts, word cards) | 41 | 1,063 | 1,004 |
| **All of Band A** | **279** | **4,035** | **3,451** |

- Of the 929 word characters, 352 (201 unpointed) are the 57 `text-ready` words whose whole-word clips the syllabus voicing plan needs anyway for Bands B and C (`voice-brief.md` §5): one clip serves all three bands.
- Several Hebrew frame lines are the same words in the three courses (for example `הַקְשִׁיבוּ, וּגְעוּ בַּתְּמוּנָה.`, `בּוֹאוּ נֹאמַר יַחַד.`, `שָׁמַעְתִּי:`); if the voice director uses one voice for them they can be one clip. That is a saving the director plans, not a text change.
- Pointed text is about 60% more characters than unpointed. Which form is sent for sentences is now the voice text (partial nikud); for single words it is the pilot's answer (`hebrew-notes.md` §8.4), and they go pointed in the pilot.
- Not counted: the per-word clips of A-12 (cut from the page clips with word timing), the drum-strip syllables of A-09 (cut from the `u-` clips), any second take, and the parent co-play cards (screen only, never voiced).
- The voice-and-sound-director turns this into the plan and its cost; the owner runs and pays (CLAUDE.md).

## 10. Hand-offs

- **hebrew-text-editor (done, 2026-11-03, second pass):** the three A-03 kind lines of §3 (`i-odd-animals`, `i-odd-food`, `i-odd-clothes`) are final and `text-ready`, with their `say` cells (`pronunciation.csv`) and the "לַמָּקוֹם שֶׁל" alternative in case the bin is not drawn as a box (the design-director's spec draws it as a box, so the lines stay as they are). Every other line, word card, verse, story page, question, recast, feedback line and the name list is `text-ready` too (waiting for the owner). The three questions are settled in `hebrew-notes.md` §9: the course voice speaks in the plural (§9.1); the voice has no gender in its lines, and i-follow no longer uses קוֹרֵאת (§9.1); "מִי לֹא שַׁיָּךְ?" does not stay, it is "מָה הִגִּיעַ לְכָאן בְּטָעוּת?" (§9.3).
- **design-director:** the A-03 bins as open boxes with the typical member's picture on the front (elephant, banana, plain shirt; A-03), holding the three cards of an odd one out; the pictures of §2 and the stories (drawn from real references), the A-10 marks, the A-14 picture paths, and the stroke directions of the arch and the circle (F6).
- **voice-and-sound-director:** the voicing plan from `pronunciation.csv`; whether a carrier line + a word clip joins naturally (§0); the syllable clips of A-09 (about 0.5 s gaps, each syllable a clean CV, level pitch).
- **curriculum-expert:** the 18 new tags (kind and family, and the suggested MEANING family); the A-03 check change (§4). **Settled** (frame §4.4 H1 to H4) and applied here on 2026-11-03: every A-03 odd one out names its kind and shows its bin; A-03.8, a sort, is always one of a child's two checks.
- **app-developer:** LS01 audio-only cards in a sort (A-05.7, .9); the A-11 name rules (strip marks, closed list, NAME-FIRST and NAME-LENGTH choice); LS03 drum count classifier.
- **qa-engineer:** once, when HEB-1 is finished.
