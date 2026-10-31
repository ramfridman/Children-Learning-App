# Phone test, November 2026: everything new since the phone last got a build

Written by the QA agent on 2026-10-31 for the branch `b40-visual-hints` (it contains `main` plus B-40). One or more sittings with the PC and the Samsung (SM-S938B). About 3 hours in all; it splits cleanly into three sittings (see "Plan of the sittings"). Each step says what to do, what you should see, and **what to tell me if it does not happen**. If a step fails, write down its number and what you saw (a screenshot is best), then go on to the next one. Nothing here can damage the phone, the children's data or the project.

Style model: `docs/phone-test-day.md` and `docs/qa/phone-check-m9.md`. Pack and sync background: `docs/qa/b3-b15-verification.md`, `docs/qa/b26-step4-verification.md`, `docs/qa/b28-verification.md`, `docs/qa/alert-tiers-verification.md`. The picture ladder: `docs/curriculum/b40-visual-hint-ladder.md` and `docs/design/b40-visual-hints.md`.

**What your phone has now:** app 0.5.0+5 (the B-23/B-24 build of 2026-10-29, pack 0.9.0). **What this build adds:**

| Since | What | Where in this file |
|---|---|---|
| PR 6, B-28 | The child's name is limited to 24 characters, on the phone and on the server | Part 1 |
| PR 8, B-26 | Nitzi's home: the island named after the child, with the bottle, the book and the lighthouse | Part 1 |
| B-34 | The map speech bubble sits at the companion's mouth again | Part 1 |
| PR 11, B-3 and B-15 | Pack 0.10.0, signed by you and bundled in the app: 200 new activities, 15 new lessons, sorting by kind, shape and size, sharing among three | Part 2 |
| B-40 | The visual hint ladder for every activity (a different picture at each of the three hints, a pointing hand that shows the way at the third), the seesaw, the shop and sort hands that come from below, the robot's first leg | Part 3 |
| PR 9 | Word alerts in three tiers: **merged but NOT deployed to the server** | Part 4 (after the deploy, B-37) |
| Pack 0.10.0 | **Not published** to the server | Part 4 (after you publish) |
| PR 10 | The voice tool: nothing on the phone | (nothing to test) |

**Things that are on purpose, so do not report them:**
- The version in the parent area still reads **0.5.0**. The version number was not raised. See step 0.7 for how to tell the builds apart.
- **The hint words are still the old ones.** The 1,142 rewritten hint lines wait on the branch `b40-hint-texts-b` for the next pack, so in this build the written and spoken hints (for example "look slowly, one by one") may not say what the new picture shows. Report a picture that is wrong or unclear, not a hint sentence that does not match it.
- **New lines are not voiced.** The 200 new activities and the new hint pictures have no recorded voice yet (the voicing is one batch later, B-45). Text on screen, silence or an older line is normal on them.
- The phone is used sideways, as the app is. This sitting checks the **phone only**: nobody has checked the new pictures on a real tablet.
- Known and open: with the system text size at 1.3 or more some map and picker texts overflow (QA-19); on the phone the shop's speech bubble nearly touches the confirm tile (minor); very small pictures (the ladybug and a few others) are small because their art has a wide margin.

**Use test children, not your children's profiles.** The dev "Open any lesson" page writes answers for the child you choose, and Part 3 makes mistakes on purpose. Make two test children in step 0.8 (one aged 4 = Band A, one aged 6 = Band B) and delete them at the end (step 5.1).

## Plan of the sittings

| Sitting | Parts | About |
|---|---|---|
| 1 | Part 0 (build), Part 1 (home, name, bubble, regression) | 45 min |
| 2 | Part 2 (the 15 new lessons and the new sort kinds) | 50 min |
| 3 | Part 3 (the hint ladder, family by family), then Part 5 (what to send) | 80 to 100 min; it can stop after any family and carry on another day |
| Later | Part 4 (alerts after the deploy, pack after you publish) | 20 min each |

## Part 0. Before you start (15 minutes)

Open PowerShell. No `&&` anywhere: type each line, press Enter, wait for it to finish.

| # | Do this | You should see | If not, tell me |
|---|---|---|---|
| 0.1 | `cd D:\nitznutz-content` | the prompt moves to that folder | the error |
| 0.2 | `git fetch` then `git checkout b40-visual-hints` then `git pull` (three lines, one after the other) | `b40-visual-hints` (it may say you are already on it; that is fine) and `Already up to date.` or a short list of files | the last lines it printed. If git says the branch is used by another folder, tell me; do not force anything |
| 0.3 | `$env:Path += ";$env:LOCALAPPDATA\Android\Sdk\platform-tools"` then `adb devices` (phone plugged in, unlocked, "Allow USB debugging" accepted) | a line that ends in `device` | `unauthorized`, or no line |
| 0.4 | `cd app` then `flutter pub get` | `Got dependencies!` (or `No dependencies changed`) | the last 20 lines |
| 0.5 | `flutter build apk --debug --flavor dev --dart-define-from-file=config/dev.local.json` (the first build takes several minutes; both words "dev" matter: this makes "Nitznutz Dev" and turns the dev pages on) | `Built build\app\outputs\flutter-apk\app-dev-debug.apk` | the **last 20 lines** of the output (the single most useful thing) |
| 0.6 | `adb install --user 0 -r build\app\outputs\flutter-apk\app-dev-debug.apk` (`-r` keeps the app's data: the children, the PIN and the answers stay) | `Success` | the exact error text. **Do not uninstall the app** (that deletes the data); if it says `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, stop and tell me |
| 0.7 | **Tell the builds apart.** Open "Nitznutz Dev". Parents button (PIN), scroll to the bottom, **long press the line "גרסה 0.5.0"**: the page "Nitznutz dev harness" opens. Tap **List installed packs** | the output starts with **`starter 0.10.0`** (the old build says `starter 0.9.0` or `0.8.0`). Also true only of the new build: a "Open any lesson" list that holds ids ending in `-b15`, and a map sign that reads "הָאִי שֶׁל" and a name | the line it printed |
| 0.8 | Back in the parent area, tap "הוספת ילד" twice and make two test children: **"בדיקה א"**, age **4**, and **"בדיקה ב"**, age **6** (any avatar, any address form) | two new children in the picker | anything that blocks saving |
| 0.9 | In PowerShell open a second window and run `adb logcat -c` (clears the old log). Leave the phone plugged in all along | nothing printed | an error |

If the app crashes at any point: `adb logcat -d -s flutter | Out-File -Encoding utf8 crash.txt` and send me `crash.txt`.

**How to reach any lesson (used in Parts 2 and 3).** Parents (PIN) > scroll down > long press the version > dev page > scroll to "7. Lessons" > **Open any lesson**. At the top choose the child (the A child for Band A lessons, the B child for Band B), optionally the template in the second list, and tap the lesson id. The lesson opens on its first question. The home (palm) button, top right, returns to the list. Lessons play their questions in the order of the list in this file.

## Part 1. Home, name, bubble, and the old things still work (45 minutes, sitting 1)

### 1a. The map and the bubble (B-34, B-23, 10 minutes)

| # | Do this | You should see | If not, tell me |
|---|---|---|---|
| 1.1 | Pick "בדיקה ב". The map opens | a sideways strip of **seven** islands, each with a label and a play button; the companion stands on the map; a speech bubble "בדיקה ב, מַה בַּבַּקְבּוּק?" | the number of islands; a missing label |
| 1.2 | Look at the bubble | its little tail **points at the companion's mouth** and the bubble sits beside the head, not floating high above it | where the tail points (a photo) |
| 1.3 | Scroll the map along and back | the bubble stays with the companion; nothing is cut at the edges | what was cut |
| 1.4 | Open Friends' Beach (the small plus), choose another friend, go home | the same bubble, now at **that friend's** mouth | the friend's name and what you saw |
| 1.5 | Tap the companion once | it greets or waves; no crash | |

### 1b. Nitzi's home (B-26, 15 minutes)

| # | Do this | You should see | If not, tell me |
|---|---|---|---|
| 1.6 | On the map find the sign of the island with the child's name | it reads **"הָאִי שֶׁל בדיקה ב"** (the name as you typed it), with nikud on "הָאִי שֶׁל", not cut | a cut or overlapping name |
| 1.7 | Tap the sign | the child's home opens: a close-up of the island with the **bottle**, the companion at its house door, a **book** and a **lighthouse**, the island's name at the top, and a back pebble | what is missing |
| 1.8 | Tap the **empty sand above the bottle** | nothing happens (the tap is the drawn bottle plus a small margin; you checked this earlier) | anything opens |
| 1.9 | Tap the **bottle** | it opens the next lesson of Counting Hills (until Today's Adventure is built it always does); press the palm button to come back | where it went |
| 1.10 | Tap the **book** | the sticker book opens ("הַמַּדְבֵּקוֹת שֶׁלִּי"); back returns to the home | |
| 1.11 | Tap the **lighthouse** | the Trophy Hall opens ("הֵיכַל הַגְּבִיעִים"); back returns to the home | |
| 1.12 | Tap the back pebble | the map returns **at the same place you left it** (not scrolled to the start) | where it came back to |
| 1.13 | On the map tap the **"הַהַרְפַּתְקָה שֶׁל הַיּוֹם" pill** | it opens the home too (it used to do nothing); no three dots in the pill | |
| 1.14 | Look at the home for anything timed, counting down, red or harsh | nothing: it only waits | |

### 1c. The 24-character name limit (B-28, 10 minutes)

| # | Do this | You should see | If not, tell me |
|---|---|---|---|
| 1.15 | Parents > "הוספת ילד" > in the name field type 30 letters in a row (for example `אבגדהוזחטיכלמנסעפצקרשתאבג`) | typing **stops at 24 characters**; a counter shows **24/24**; the 25th letter cannot be typed | how many characters it let through |
| 1.16 | Paste a long text into the name (copy 40 letters from anywhere, paste) | the field holds exactly the first 24; nothing half-cut (an emoji is kept whole or left out) | what stayed in the field |
| 1.17 | Type a name containing `<` (symbols keyboard) | a red note "בלי הסימנים < או > ..." and **Save is greyed out** | whether Save still worked |
| 1.18 | Type only spaces | no note and Save greyed out | |
| 1.19 | Save a child with a **24-letter name**. Back on the map look at the island sign | the sign shrinks the text first; if it still does not fit it ends with "…" and **never cuts a letter in half**; the home's title is whole | a cut letter, or text over the "+" or the Counting sign |
| 1.20 | (Parents area, write it down: it blocks screenshots.) Open the children list | the long-named child is listed; the list is readable | an overlap |

Delete the 24-letter child now (parents list, remove) or keep it for step 5.1.

### 1d. Quick check that the old things still work (10 minutes)

| # | Do this | You should see | If not, tell me |
|---|---|---|---|
| 1.21 | "בדיקה א": Counting Hills, play button, play the whole first lesson (the butterflies) to the end | five steps, a praise card with the character, a gold home button; no cross, no harsh sound | where it stopped |
| 1.22 | Parents > "Voice answers" switch **on** (allow the microphone). Open `count-to-ten` (Open any lesson): is there a microphone? Then open a find-and-tap lesson such as `shape-friends` | the microphone is there when speaking is the answer (counting) and **absent** when the answer is a tap | a mic where it makes no sense |
| 1.23 | Turn "Voice answers" **off** again unless you want it for Part 4 | the mic is gone at once | |

## Part 2. The 15 new lessons and the new sorting (50 minutes, sitting 2)

All 15 are **Band A**: use "בדיקה א". They sit deep in each land's path (their numbers are 7 to 25), so reach them with Open any lesson. For each: the first question is quoted so you know it is the right lesson; each lesson ends with a praise card whose first words are quoted. Look for: pictures clear at phone size, nothing too small to touch, the right answer unambiguous for a 3 to 4 year old, **no "not" or "wrong" feeling**, a question that makes sense, nikud complete.

| # | Lesson id (land) | First question (hebrew, nikud) | What to look for | If not, tell me |
|---|---|---|---|---|
| 2.1 | `colour-names-1-b15` (Colour Bay) | "אֵיפֹה הַצּוּרָה הַצְּהֻבָּה?" then 2 more finds and 2 spot-the-odd-one questions. Card: "כׇּל הַכָּבוֹד! הִסְתַּכַּלְתֶּם טוֹב עַל הַצְּבָעִים." | yellow and green shapes are told apart; a "spot the one that does not belong" row is easy to tap | a colour that looks wrong |
| 2.2 | `colours-again-1-b15` (Colour Bay, 8 questions) | "אֵיפֹה אוֹתוֹ צֶבַע?" with matching, two **sorting** questions (drag), and two spot questions. Card about orange, red, black and white | orange, red, black, white are clearly different; a sort you can finish by dragging | a drag that does not drop; colours too close |
| 2.3 | `colours-again-2-b15` (Colour Bay) | "חָבֵר אוֹסֵף רַק חוּמִים. מָה הִגִּיעַ לְכָאן בְּטָעוּת?" (2 questions). Card about brown and grey | brown and grey are clear; **the guide's words for "the odd one" do not say "wrong"** | a "לֹא" that sounds like a scolding |
| 2.4 | `colour-sorting-again-1-b15` (Colour Bay, 1 question) | "אֵיפֹה הַפֶּרַח הָאָדֹם?" | the red flower is obvious next to other flowers | |
| 2.5 | `more-comparing-1-b15` (Counting Hills, 2 questions) | "אֵיפֹה יֵשׁ יוֹתֵר אֶפְרוֹחִים?" | the two groups are about the same size on purpose: can you still tell which has more? Chicks are not too small | pictures too small to count |
| 2.6 | `more-counting-1-b15` (Counting Hills, 8 questions) | "כַּמָּה פַּרְפָּרִים יֵשׁ? בּוֹחֲרִים אֶת הַמִּסְפָּר." Counting animals, touching each once, then the number; one spot-the-mistake | each touch counts once; the numerals are big | a creature that cannot be touched |
| 2.7 | `more-counting-2-b15` (Counting Hills, 1 question) | "נוֹגְעִים בְּכׇל אֶחָד פַּעַם אַחַת, וְסוֹפְרִים." | a count of small things scattered about; the touch lands on the thing you meant | a thing you could not hit |
| 2.8 | `more-counting-words-1-b15` (Counting Hills, 8 questions) | counting along 1 to 10 by touch, and 3 spot-the-error rows of numbers | numbers are drawn **left to right, 1 on the left, never mirrored** | any row that runs the other way |
| 2.9 | `more-counting-words-2-b15` (Counting Hills, 1 question) | "חָבֵר סָפַר מִסְפָּרִים, וְיֵשׁ בָּהֶם טָעוּת. אֵיפֹה הַטָּעוּת?" | one wrong number in a row; easy to tap | |
| 2.10 | `patterns-again-1-b15` (Riddle Grotto, 1 question) | "מַה בָּא אַחַר כָּךְ?" | a row with a "?" at its **right** end | the "?" on the left |
| 2.11 | `same-and-different-again-1-b15` (Riddle Grotto, 6 questions) | "אֵיפֹה אוֹתוֹ הַדָּבָר?" then spot-the-different and more | the answer is the same **kind** of thing, not the same colour | a question with two right answers |
| 2.12 | `stories-and-pairs-again-1-b15` (Riddle Grotto, 2 questions) | "מָה הוֹלֵךְ עִם הַצַּלַּחַת?" | the pairs make sense to a small child; nothing odd | a pair you would argue with |
| 2.13 | `shape-friends-again-1-b15` (Shape Forest, 3 questions) | "אֵיפֹה הָרִבּוּעַ?" and two spot questions. Card about circles and squares | circles and squares are clear in several colours | |
| 2.14 | `shapes-around-us-again-1-b15` (Shape Forest, 1 question) | "לְאֵיזוֹ צוּרָה יֵשׁ קַו עָקֹם?" (a mic may show: it is a spoken-answer question) | the curved line against the straight line is visible | |
| 2.15 | `step-by-step-again-1-b15` (Robot Harbour, 2 questions) | "מְצַחְצְחִים שִׁנַּיִם. מָה הִגִּיעַ לְכָאן בְּטָעוּת?" and a washing-hands one | the steps of brushing and washing are in a sensible order and each is a picture | a step that is hard to tell |

New sorting in existing lessons (the pack now sorts by **kind**, by **shape**, by **size** and shares among **three**). Use "בדיקה א":

| # | Lesson id | Do this | You should see | If not, tell me |
|---|---|---|---|---|
| 2.16 | `same-and-different-again` (the 5th and 6th questions are new, by kind) | Sort the pictures into two boxes by kind; once drop one in the wrong box | a gentle "not yet" that says what to look at; the box names fit the kind | a line that blames or is wrong |
| 2.17 | `sort-by-hand` (the last two questions are new, by size) | Sort big against small | big and small are really different sizes | |
| 2.18 | `any-shape-again` (shapes) | Sort circles and squares, including a tilted square | the tilted square is still a square to you | |
| 2.19 | `sharing-again` (the last two questions are new, **three friends**: six apples, three fish among the cat, the dog and the duck) | Share so that everyone gets the same | three plates, equal shares possible, a clear end | a share that cannot come out equal |

## Part 3. The visual hint ladder (80 to 100 minutes, sitting 3)

### 3a. How a hint ladder works, and how to look at it

Every activity now has **three levels of help**, and each draws a different thing:

| Level | What the child gets | Rule you check |
|---|---|---|
| **1. Look here** | a sky-blue glow or ring on part of the *question* (the gap, the group, the start) | it **never marks or brightens an answer** |
| **2. Another way** | the same problem drawn another way (hands, a ten-frame, a path, a bracket, a ghost shape, cubes), or the guide does the first step only | it **never shows the answer** |
| **3. Watch me** | a sky-blue pointing hand does the whole process in order; the answer comes **last** and the hand ends on the right tile; then it is your turn | the answer appears only at the end; the child makes the final tap |

**Three ways to get the levels** (try all three once, in step 3.1 to 3.3, then use the lamp):

- **The lamp** (top-left corner, the bulb): tap it once for level 1, again for level 2, again for level 3. This is the fastest way and costs the child nothing.
- **Wrong answers on purpose**: the 1st wrong tap shows level 1 (with a short line), the 2nd shows level 2, the 3rd shows level 3 (the demonstration). **An item with only two choices needs just two wrong taps** (the 1st shows level 2, the 2nd the demonstration).
- **"Show me"** (the eye, next to the lamp): the guide welcomes you and gives the next level. It is never a mistake.

After the demonstration ends (at most 10 seconds) the right answer gets a soft halo and **only the right answer is taken**. A wrong tap then is not answered with another "not yet".

**Rules to watch in every row below** (report any breach with the step number):

| Rule | What it means on screen |
|---|---|
| R1. No answer early | before hint 3 has finished, **nothing** shows the right tile, cell, bin, coin or arrow brighter, bigger or different from the others (at hint 1, tiles may glow *in turn, all alike, none staying lit*) |
| R2. Nothing mirrored | number rows, number lines, patterns, clocks and robot arrows run left to right with 0 or 1 on the left and the gap or "?" at the right end. **One exception on purpose:** in "who is first" (`who-is-first`) the place badges stand on the answer tiles, with "1" on the right-hand tile and a small flag, because the queue runs right to left |
| R3. The hand hides nothing important | on the phone the hand never covers the speech bubble, the running total in the shop, the gold places, or a bin's label; where it would, it comes from the side or from **below** |
| R4. Clear at phone size | you can tell what each picture is without leaning in; nothing blurred, stretched or cut |
| R5. Calm | nothing timed, no countdown, nothing red or harsh, no cross, no buzzer; every motion comes to rest |
| R6. Fingers add up | when fingers or ten-frame counters are drawn, there is **one for each thing counted**, no more |
| R7. Colour is not the only cue | outside Colour Bay, the hint never relies on colour alone |

### 3b. The recipe (Band A child, 10 minutes)

| # | Do this | You should see | If not, tell me |
|---|---|---|---|
| 3.1 | "בדיקה א": Open any lesson > `shape-friends`. Read the question, then tap a **wrong** tile on purpose | a gentle "not yet", the guide says what to look at, and **level 1**: a sky glow/ring on part of the question or the tiles lighting in turn; no tile is marked as right | a cross, a harsh sound, a tile that stays brighter than the others |
| 3.2 | Tap another wrong tile | **level 2**: a new picture (a dashed outline of the named shape beside the question); still no answer marked | the same picture as level 1; the answer marked |
| 3.3 | Tap a third wrong tile | **level 3**: the pointing hand walks over the options and **ends on the right tile**, which then glows. Then tap it | the right tile marked before the hand arrived; the hand hiding the bubble |
| 3.4 | Next question: use the **lamp** three times instead, waiting for each picture to settle | the same three levels as above, in order | the lamp doing something different |
| 3.5 | Next question: tap the **eye** once, then the lamp | the eye is welcomed (not a mistake) and gives the next level; the lamp then gives the one after | the eye counted as a mistake |
| 3.6 | During the hand at level 3, **tap any tile** | the hand goes **at once** and your tap is taken (the right one: praise; a wrong one: "not yet" and its own hint a moment later) | the hand carries on over your finger |
| 3.7 | Finish the lesson | the praise card and gold home button | |

### 3c. Count, give, flash (counting hands and ten-frames, 15 minutes)

Use "בדיקה א" for Band A and "בדיקה ב" for Band B. Do each with the lamp, three times.

| # | Lesson (child) | Do this | You should see | If not, tell me |
|---|---|---|---|---|
| 3.8 | `count-to-ten` (A) | Touch the objects (do not answer) then use the lamp 3 times | L1 the objects light in turn. L2 a card with **two hands** (a full hand of five, then the rest), **one finger for each object**. L3 the pointing hand counts every object, a number badge stays on each, the last number is held, the answer tile glows **last**. R6 | more or fewer fingers than objects (a serious one: write the number) |
| 3.9 | `count-more-things` (A) | the same | the same ladder with a different picture | |
| 3.10 | `many-things` (B, 11 to 20 objects) | the same | L2 draws **one or two ten-frames** filling from the top row **from the left**, one counter per object (not hands). R6 | a frame filled from the right; a wrong count |
| 3.11 | `giving` (A) and `give-up-to-20` (B) | the lamp 3 times without giving | L1 the plate and a goal card with the number and its dots beside the button (the button stays where it is). L2 hands (up to 10) or ten-frames (above 10). L3 the hand **takes each one from the pile and puts it on the flower**, a badge on each place, then they go back; you give | the card covering the button; a wrong number |
| 3.12 | `glance-small` and `glance-more` (A) | after the group flashes away, ask for help | L1 the group shown again a little longer. L2 the same number another way (dots in a row, or a finger pattern). L3 the group stays, the hand counts the pictures, the last badge is the count | the group not shown again |

### 3d. Tap the answer, Band A (25 minutes)

Each row: open the lesson, and use the lamp 3 times on one question (any question of the lesson will do). The "you should see" is the idea; the exact picture differs a little with the question.

| # | Lesson (A child) | Idea | You should see | If not, tell me |
|---|---|---|---|---|
| 3.13 | `colour-match` or `more-colours` (colours) | name a colour | L2 a **paint of the named colour with a small helper symbol** (heart, sun, star, leaf...). L3 the hand tries each option and ends on the match (R7) | the colour as the only cue; the paint very pale |
| 3.14 | `colours-of-things` (a thing of the world, with colour balls to choose) | which colour is the apple? | L2 an **empty dashed paint spot** beside the apple (it does **not** paint the right colour: R1) | the answer colour painted at L2 |
| 3.15 | `more-or-less` and `tricky-sizes` (compare two groups) | where are there more? | L2 pair lines between the two groups with the unpaired ones ringed; the two groups kept at **equal spacing** so size does not fool you; L3 the pairs are drawn one by one and the leftovers counted | lines that cross the answer tiles |
| 3.16 | `find-the-number` and `counting-words` (numbers) | which number is missing / comes next | L2 a **number path** left to right with the gap empty. L3 the hand walks it and the number lands last. R2 | a path running right to left |
| 3.17 | `who-is-first` (ordinals) | who is first in the queue | **no path**; place badges on the answer tiles, "1" on the **right-hand tile** with a small flag; L3 the hand walks the tiles from the front. (R2 exception, on purpose) | the badges missing; the flag on the wrong side |
| 3.18 | `patterns` and `more-patterns` (pattern rows) | what comes next | the row appears **one cell at a time from the left** and the "?" last at the **right**; L2 brackets under the repeating part; L3 the hand reads it and the unit slides into the gap | the row from the right; the "?" on the left |
| 3.19 | `first-then-last` and `my-day` (order in time) | what happens first | L2 numbered slots left to right; L3 the hand walks the slots | slots out of order |
| 3.20 | `add-one-more` and `take-one-away` | the sum in a story | L2 a card with fingers or objects joining/leaving; L3 the hand does it and the result tile glows last | the result shown at L1 or L2 |
| 3.21 | `roll-or-stack` (solids) | which one rolls / stands / stacks | both solids get the **same push arrow** and only the ball rolls away; for stacking, a second one stays on the box and slides off the ball | the answer shown by only one solid moving at L1 |
| 3.22 | `where-is-it` and `where-is-it-again` (position words) | "under", "on" | L2 a small card with a **duck** and the thing the question names (a box, a bin, the table) in the asked position, not the answer tile's own picture | the answer tile's ball shown in the card |
| 3.23 | `big-small-long-heavy`, the **3rd and 4th** questions (long, short) | which is longer | L2 a stick of cubes along each; both start from one line | |
| 3.24 | `big-small-long-heavy`, the **5th and 6th** questions (**heavy and light, the seesaw**) | which is heavier | L1 the two tiles light in turn. L2 a **seesaw held level on two blocks**, with the two things in the **same order as their tiles**. L3 the hand takes the blocks away, the plank **tips slowly** until the heavy end rests on the ground, and the hand ends on the right tile | a plank that tips at L2; the things in the wrong order; the heavy end not the lower |

### 3e. Tap the answer, Band B (15 minutes)

"בדיקה ב", lamp 3 times on one question each.

| # | Lesson | Idea | You should see | If not, tell me |
|---|---|---|---|---|
| 3.25 | `count-to-20` | the number after | a **path of ten numbers around the given number**, left to right; L3 a hop along it | |
| 3.26 | `which-is-bigger` | compare numbers | a **bar of cubes for each option from one start line**; L3 the hand compares | bars not on one line |
| 3.27 | `make-ten`, `to-twenty` | fill to ten | the ten-frame with the **empty cells** shown; cubes over numbers; the answer in the empty cell last | |
| 3.28 | `read-the-teens` | a teen number | a **full ten-frame and the ones**, the numeral only at the end; R6 | |
| 3.29 | `days-of-the-week` | the day after | **seven day cards left to right** with the asked day empty and the given day ringed | |
| 3.30 | `what-time` | read the clock | the short hand lit, a **ray to the numeral at the dial's rim** with the 12 marked, then the hours counted round; the clock is not mirrored | a mirrored clock |
| 3.31 | `count-sides`, `polygon-detectives` | corners and sides | each side or corner lit **in order from a start dot** | |
| 3.32 | `solids` | name the solid | L2 the dashed outline of the named solid | |
| 3.33 | `mix-colours`, `light-and-dark` | mixing, shades | two paints and an **empty place for the mix** (the mix appears last); a strip of shades with an arrow from the lightest | the mix shown early |
| 3.34 | `read-the-chart`, `equal-groups` | read columns | a **count over each column**, left to right | |
| 3.35 | `growing-towers`, `pairs`, `missing-part` | growing patterns, pairs, missing part | cubes under each step; pair lines in twos with the odd one ringed; a row of cubes with the known part drawn and the rest empty | |

### 3f. The other templates, one by one (35 minutes)

| # | Lesson (child) | Do this | You should see | If not, tell me |
|---|---|---|---|---|
| 3.36 | **Number line** `frog-line-10` (place) and `frog-jumps` (jump), B | lamp 3 times, then try touching a tick yourself during L3 | L1 0, the arrow and landmark ticks lit. L2 **one hop** with one dotted arc and the number 1. L3 the marker **hops one unit at a time**, each hop with an arc and its number, the hand on each landing; the answer tick is **never lit before L3**; 0 is at the **left** | a line mirrored; the answer tick lit at L1 or L2 |
| 3.37 | **Clock** `set-the-clock` (B) | lamp 3 times without moving anything | L1 the short hand lit and a card with the target number; L2 the card and the numeral on the dial ringed alike; L3 the hand presses the **plus** tile once per hour with the hour numbered on the dial. The long hand stays on 12 | the target hands drawn on the dial early |
| 3.38 | **Match** `match-numbers-sets` (A) | lamp 3 times | L2 the **dots under the numeral** in a tight strip. L3 the hand goes to a card, then its partner and draws one dotted line, then the pair is taken out and it is your turn | the partner marked at L1 or L2 |
| 3.39 | **Match** `know-the-coins` (B) and `solid-and-face` (B) | lamp 3 times | L2 a coin drawn as **that many dots** (not agorot); L2 for a solid: a **dashed print of its face** | a coin that looks wrong |
| 3.40 | **Sort** `sort-by-hand` (A) | lamp 3 times | L1 each bin lit in turn. L2 a **copy of the next picture glides past the sample of each bin and stops at none**. L3 the hand takes **one** picture from the tray **from below** to its bin, the guide puts it in, takes it out again, and the bin stays lit. R3: the hand never covers a bin's label | a bin marked at L1 or L2; the hand over a label |
| 3.41 | **Share** `sharing` and `sharing-again` (A) | lamp 3 times | L1 each plate lit. L2 **one round dealt (one each) and stops**. L3 the hand deals every picture, 900 ms each, then they all go back | all dealt at L2 |
| 3.42 | **Build a pattern** `copy-patterns` (A) | lamp 3 times | L2 **brackets under each copy of the repeating unit** in the model, the model cell above the next place lit. L3 the hand takes each picture from the model cell it copies, the places fill one by one, then empty; the first place stays lit. Rows left to right | a row filled from the right |
| 3.43 | **Shape builder** `build-with-shapes` (A) | lamp 3 times | L1 the next empty outline lit. L2 that outline **lifts off as a dashed ghost** beside the picture; nothing in the tray is marked. L3 the hand takes the piece that fits to its place | the right piece marked at L1 or L2 |
| 3.44 | **Robot, Band A** `robot-moves` (direct) and `robot-plans` (plan) (A) | lamp 3 times | L1 the robot's face and the flag lit. L2 a footprint **1** on the ghost's square. L3 the hand presses each arrow of the way, the robot steps, a **numbered badge stays on each square**; at the flag the robot goes back. Arrows are drawn: left, up, down, right, **never mirrored** | an arrow pointing the wrong way |
| 3.45 | **Robot, Band B plan, the first leg** `longer-robot-paths` (B): the **1st and 3rd** questions are plan questions | in the plan row put in one **wrong** arrow, then use the lamp for level 2 | L2 first lights the **undo button** (no footprints yet). Undo until what is left is a correct start, then L2 shows **only the first run of same-direction arrows**: numbered footprints on those squares, the ghost on the last, that arrow lit; it **ends at the first turn** and never shows more than half the steps. The **plan row is drawn left to right**, and a "left" step points **left** | a "left" arrow pointing right; the whole way shown at L2 |
| 3.46 | **Shop** `pay-exactly` (B) | lamp 3 times | L1 the price and counter lit and the counter shows **a dashed place for each shekel** of the price (rows of five from the left). L2 the **biggest coin of the way** on the counter and its places turn gold. L3 the hand takes each coin **from below**, biggest first, each fills its places in gold under the running total ("5", "7", "8"), the hand ends on the pay button, then the coins go back. R3: **the total, the gold places and the labels stay visible** | the hand over the total; a coin that looks wrong. (The bubble nearly touching the confirm tile is known) |
| 3.47 | **Balance, hidden lean** `equals-balance` (B) | lamp 3 times | L1 each pan lit in turn and a **small peg holds the beam level**. L2 a **tower of cubes on each pan** (one cube per unit, the taller is the heavier), the beam **still level**, a dotted line across the top of the shorter tower. L3 the peg slides out, the beam **tips slowly**, the hand goes to the lower pan and then the matching arrow tile | the beam leaning before L3; no side marked |
| 3.48 | **Balance, weighing** `weigh-it` and `balance-it` (B) | lamp 3 times | L2 the cubes the right pan still needs are **empty places** on its tower. L3 the hand presses plus and the cubes go on one by one, then come off | |
| 3.49 | **Spot the mistake, rows that count** `count-order` (B) and `more-counting-words-1-b15` (A) | lamp 3 times | L1 the light runs along the row. L2 a **correct number path under the row, cell by cell** (no cell ringed, the mistake not shown). L3 the hand reads the row from the left, **stops on the mistake and a small card shows what belongs there** | the mistake ringed at L1 or L2 |
| 3.50 | **Spot the mistake, sums** `find-the-slip` (B) | lamp 3 times | L2 **cubes over each number**, number by number. L3 as above | |
| 3.51 | **Spot the mistake, patterns and programs** `fix-patterns-again` (A), `broken-pattern` (B), `fix-the-program` (B) | lamp 3 times | L2 **a bracket under each whole copy of the unit** (as it will be when fixed), one after another | |
| 3.52 | **Spot the mistake, with no own picture** `step-by-step-again-1-b15` (A, both questions) | lamp 3 times | there is no special L2 picture here (known): the sky bar under the row stays and it still ends well | a dead end |
| 3.53 | **Trace** `trace-numbers-0-4` and `trace-the-shapes` (A for shapes, B for numbers) | lamp 3 times, then trace | the start dot and the first arrow pulse; a walking dot; L3 the pointing hand follows the dot along the whole stroke, then you trace | a dot that goes the wrong way |
| 3.54 | **Rainbow** `rainbow` (B, build a pattern) | lamp 3 times | the pattern ladder as in 3.42; the six paints of the rainbow in order for the one spot question | |

### 3g. Reduce motion and touch (10 minutes)

| # | Do this | You should see | If not, tell me |
|---|---|---|---|
| 3.55 | Phone Settings > Accessibility > Visibility enhancements > **Remove animations** on (or Developer options > Window, Transition and Animator animation scale = off). Reopen a lesson and ask for the three levels on `shape-friends`, `frog-line-10`, `equals-balance`, `robot-moves` | every picture simply **appears** (a short fade, no travel, no turning): the hand appears at its places instead of gliding, the beam is drawn already tipped, the marker and the robot do not glide; a **still sky start dot** under the first cell of a row. **Everything is still understandable and still ends on the right tile** | a picture that never appears; a hand that is missing |
| 3.56 | **Turn the animation setting back** | motion returns | |
| 3.57 | In count and tap, give N and the robot, touch a tile while the hand is demonstrating | in these three the guide moves the objects itself, so your touch is **not taken until the demonstration ends** (different from tap the answer, 3.6) | the touch taken half way, a stuck screen |
| 3.58 | After level 3 in any family, tap the **wrong** tile | the hand is gone; only the right tile is taken; no extra "not yet" | |
| 3.59 | Leave a lesson with the palm button while the hand is moving | back at once; no sound left over | |

## Part 4. Steps waiting for a release

These two are **not for today** unless you tell me the release has been done.

### 4a. Word alerts (after the deploy, B-37)

Needs from you first: your OK, then I deploy the two migrations, then `alert-create`, `alert-list` and `settings-put`, then the app (this build). Until then do **not** say any worrying phrase to the mic: the old server may refuse it and it would be kept aside. The phrase used below is deliberately the gentlest kind, a weekly **note**. Do not test the other tiers on the phone; the computer tests cover them (see `docs/qa/alert-tiers-verification.md`). Use the Band B test child. Parents > "Voice answers" on.

| # | Do this | You should see | If not, tell me |
|---|---|---|---|
| 4a.1 | Parents area: look for the alerts entry "התראות" | the alerts screen opens; at the top "אין התראות..." or the list; below it the "keep the words" switch ("לשמור בהתראה את המילים שנשמעו") and the honest text (the app listens only when a child taps the mic, misses a lot, neither diagnoses nor reports). Nothing overflows | what overflows. (Write the screen down, no screenshots here) |
| 4a.2 | Open `count-to-ten`, tap the mic and say, instead of a number, "אל תספר לאמא" | for the child: only the normal handling of a word that is not an answer; **no mention of the words, no cross, nothing scary** | anything the child would notice |
| 4a.3 | Press home, wait 20 seconds, reopen the app (that syncs). Parents > "התראות" | one calm note "בקשה לשמור סוד": "השבוע נשמעה במשחק של בדיקה ב בקשה לא לספר משהו, פעם אחת." with a calm explanation; the words are shown only if "keep the words" is on | the text that appeared |
| 4a.4 | Repeat 4a.2 once more, sync again | the same note now says it was heard **two times** ("2 פעמים"), not a second note | a second note |
| 4a.5 | Turn "keep the words" **off** | the words disappear from the note and the screen says they were not kept | the words still showing |
| 4a.6 | `adb logcat -d -s flutter` then look for `sync:` lines (see the end of Part 5) | none, or only lines you report | all lines |

### 4b. The published pack 0.10.0 (after you publish it with the next app version)

Publishing sends the pack's item list to the server for the AI helper. The phone plays the bundled pack in either case, so these steps only test the helper on the new items. Do them after the AI helper's switch and keys work for you (dev page).

| # | Do this | You should see | If not, tell me |
|---|---|---|---|
| 4b.1 | Dev page: **Check the AI helper chain (one real call)** | a line ending without an error (`app-config ... tutor_enabled=...`) | the line |
| 4b.2 | AI helper switch on. Open `colours-again-1-b15` with the Band A child and make one mistake | a short, kind line within about 3 seconds, or the normal written line if the helper is off or slow; no cross; nothing about the child personally | a slow screen; any odd text |
| 4b.3 | Switch the helper off again | back to the plain lines | |

## Part 5. What to send me

1. **For each failure:** the step number, a screenshot, and what you saw in one line. Take a screenshot with Power + Volume down, or from the PC: `adb shell screencap -p /sdcard/s.png` then `adb pull /sdcard/s.png s.png` (do not use `adb exec-out screencap > file` in PowerShell 5.1: it damages the picture). For a hand that moves, a 20 second video helps: `adb shell screenrecord --time-limit 20 /sdcard/r.mp4` then `adb pull /sdcard/r.mp4 r.mp4`.
2. **The parent area and the dev page block screenshots** (they come out black). For those write down what you saw.
3. **The sync check, once, after Part 3:** `adb logcat -d -s flutter | Select-String "sync:"`. A sync that works prints **nothing**. If it prints lines, send them all (they hold only ids and counts, nothing personal). A line like `sync: N of M events refused by the server` after playing the new `b15` items would mean the server does not yet know the new content; please report it.
4. **If anything crashed:** `adb logcat -d -s flutter | Out-File -Encoding utf8 crash.txt`, and send `crash.txt`.
5. **Your honest view, one line each:** the hand (clear / confusing / too slow), the seesaw, the ten-frames and hands (right size?), the shop and sort hands from below, and which hint picture a 4-year-old would not understand.

### 5.1 Clean up

Parents > delete the test children "בדיקה א" and "בדיקה ב" (and the 24-letter one) so their answers do not stay with your children's data. (If you deleted the phone's real children by mistake, stop and tell me; do not uninstall.)

I re-run the failing tests after each fix and record each defect as `QA-<n>` in `docs/qa/`.
