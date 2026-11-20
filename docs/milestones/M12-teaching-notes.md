# M12 teaching notes: why she needed help, and Colour Bay as the pilot of the remake

Written 2026-11-20 by the curriculum-expert. Docs only: no content, code or test changed, nothing committed. Read with
`docs/milestones/M12-sound-notes.md` (voice and sound) and `docs/design/m12/delight.md` (touch, celebration, the P0 look stage); section 3.4 here
answers the design-director's hand-off H3 ("what P0 serves").

The owner, 2026-11-19, after Colour Bay with his 2-year-old daughter on the fb39dc08 build (M11 Stage 1 only): "the sound only says a very not
exciting phrase on which color is this.. nothing that makes a child excited at all", "some of the things she did fine and others wasn't very
understandable to her and I had to help her. It's probably because of how the lesson is taught and phrased and sounded", "this app is not a child
friendly at all".

Tags: **[M]** read or counted in the repo, **[R]** read in a cited source (some only as a search summary, said where), **[G]** my judgement. I did
not see her play; every "she probably" is [G].

---

## 0. In one page

**Why she needed help (most likely first):**
1. **Asked before taught.** Every question used words nobody had shown her in this land: "the same colour" (אוֹתוֹ צֶבַע), red, blue, orange,
   purple, pink. The only teaching was hint level 3 ("this is the pink flower, now you tap it"), after misses. The host's greeting was a silent text
   bubble (Goni has no voice in `content/voices.json`) [M].
2. **Every item was a trap built for a 4-year-old.** From the very first item the wrong answers were the two hardest lures that exist for a
   toddler: the **same object in another colour** (a red ball as the model, a blue ball as an option) and the **look-alike hue** (orange next to
   red, purple next to blue). Toddlers match by object kind before colour, and their colour errors sit exactly at those boundaries [R]. Nothing was
   errorless; there was no easy first touch.
3. **The thing the question is about was never shown.** "Where is the same colour?" (same as what?); "red here, and yellow here" (here where?).
   No step was demonstrated: her first drag was never modelled on screen.
4. **Feedback and hints talk instead of show.** "We are looking for the same colour, even if the thing is different. Let's check." "Let's listen to
   the question again." "Let's look at each group and see what it has." Adult meta-talk, 6 to 10 words, nothing she could act on.
5. **No reason, no surprise, no variety.** Four identical "where is the same colour?" screens in a row, read flat, with silence on every touch and
   no story (nobody wanted anything). And she is 2: the basic colour words are being learned around 30 months, orange/purple/pink later [R].

**Stage 2 (lands-ux) already fixes:** a Show before asking (Goni sorts, the child does the last step), hands-on sorts instead of most taps, a Together
item, no scored first screen, shorter lessons on a small phone (5 screens at P1). **Still there:** adult words ("we sort by colour", "here and here",
"every colour to its house"), the colour names said as a list instead of at each move, the first sort already holding the object lure, verbal
hints, look-alike hues and three new colour names in lesson 2, no purpose or story, no planned laugh, no errorless start, and roughly 12 to 16 drags
before anything is celebrated.

**For under-3s:** no new band and no lower Band A for everyone. Agree with the design-director's **P0 look stage** (under 3;0), and add a small
**"first steps" entry of 2 to 3 lessons per land**, made of existing Band A skills in their narrowest form, played **errorless** (nothing can be
wrong), with **no placement, no evidence, no mastery, no revisits**. Colour Bay is the pilot: **Goni the chameleon wants a colour, and turns the
colour of whatever she touches**, so every touch makes something happen and teaches a word.

---

## 1. What she met on fb39dc08

### 1.1 Which lessons [M]
- The Colour Bay path at fb39dc08, by `sequence`: `colour-match` (2), `colour-names` (3), `more-colours` (4), `colour-sorting` (5), … `butterflies`
  (1) lists COL-A-02 but belongs to Counting Hills ("the first skill decides", `world/adventure_adapter.dart`). So her first two Colour Bay lessons
  were almost certainly `colour-match` and `colour-names`.
- Her look stage: the youngest school stage is `gan3` (Band A). With a birth month entered she was **P1** (3 choices, 3 to 4 items an activity);
  without one, the app assumes **4;0 (P2)** (`engine/age.dart`, `assumedMonthsOfBand`). Either way the app treated her as at least a 3-year-old.
  Which profile she played on is an owner question (§6).
- Before the first item: Goni's greeting "הֵי! אֲנִי גּוֹנִי. נִרְאֶה צְבָעִים יַחַד?" (`strings/he.dart`). **Goni has no voice id in
  `content/voices.json`** (then or now), so the greeting was most likely a text bubble with **at least 3 s of silence** (`_greetingPause`; the
  owner can confirm). Every question was
  then read by the companion's voice, flat (sound notes §1b).
- Every tap item showed a "?" (unsure) button (`unsureAllowed: true`) and hints after 2 s of stillness (design §1.1).

### 1.2 Lesson `colour-match` (COL-A-01 match, COL-A-02 name red/blue/yellow/green), 6 items, all `tap_answer`, 3 choices

| # | Item | Said (companion) | Picture | What she must understand and do | What a 2-year-old meets | Adult needed? |
|---|---|---|---|---|---|---|
| 1 | `col.match.red` | "אֵיפֹה אוֹתוֹ צֶבַע?" (*where is the same colour?*) | A red ball on the stage; tiles: orange balloon, red balloon, blue ball | That "the same" means "the same as the ball up there", that "colour" is the feature to compare, that the ball's kind does not matter; tap the red balloon | Two abstract words with no referent said or pointed at; the **blue ball is the obvious match** for a toddler (same thing); red vs **orange balloon** is a boundary pair. 2 of 3 options are traps on the first screen of the land. | **Very likely.** |
| 2 | `col.match.blue` | same words | Blue ball; purple balloon, red ball, blue balloon | as 1 | Same trap: the red **ball** (same object) and **purple** (the hardest neighbour of blue). | Very likely |
| 3 | `col.match.yellow` | same words | Yellow ball; orange balloon, yellow balloon, blue ball | as 1 | Same; a toddler who learned "not the ball" by item 3 may manage. | Likely |
| 4 | `col.match.green` | same words | Green flower; red flower, blue ball, green ball | as 1 | Now the lure is the red **flower**; four identical screens in a row, no variation in the task. | Possible (attention) |
| 5 | `col.name.red.ball` | "אֵיפֹה הַכַּדּוּר הָאָדֹם?" (*where is the red ball?*) | red balloon, red ball, orange ball | Know "red" (never taught here) and "ball" vs "balloon", and hold both at once (noun and colour, COL-A-07's idea) | "Where is the …?" is a 24-month form and fine [R], but two attributes at once and red vs orange are not. | Likely |
| 6 | `col.name.blue.balloon` | "אֵיפֹה הַבָּלוֹן הַכָּחֹל?" | green balloon, blue balloon, blue ball | Know "blue", "balloon" vs "ball" | As 5. | Likely |

Feedback she heard on a miss [M]: on the look-alike "הַצְּבָעִים דּוֹמִים. בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט." (*the colours are alike; let's look
again, slowly*); on the same-object lure "מְחַפְּשִׂים אֶת אוֹתוֹ צֶבַע, גַּם אִם הַדָּבָר שׁוֹנֶה. בּוֹאוּ נִבְדֹּק." (*we look for the same colour
even if the thing is different; let's check*: a concessive clause, 10 words). Hints: 1 "בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה" (*let's listen to the
question again*), 2 "נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד" with the tiles lit in turn, 3 the worked example, which is the first time the
word is linked to the thing. Right: "כֵּן! זֶה בָּלוֹן אָדֹם." (good: it names the colour, but never "red, **like the ball**", so the match and the
name are not joined).

### 1.3 Lesson `colour-names` (COL-A-02, COL-A-03), 8 items

| # | Item | Said | Choices | What a 2-year-old meets | Adult needed? |
|---|---|---|---|---|---|
| 1 | `col.name.yellow.flower` | "אֵיפֹה הַפֶּרַח הַצָּהֹב?" | yellow flower, yellow ball, orange flower | Yellow is a basic word; but the same-colour ball and the orange flower are both lures. | Possible |
| 2 | `col.name.green.ball` | "אֵיפֹה הַכַּדּוּר הַיָּרֹק?" | green balloon, blue ball, green ball | Two attributes again. | Possible |
| 3 | `col.name.red.near` | "אֵיפֹה הַבָּלוֹן הָאָדֹם?" | orange, red, blue balloon | Red vs orange only. | Possible |
| 4 | `col.name.orange` | "אֵיפֹה הַכַּדּוּר הַכָּתֹם?" | red, orange, yellow ball | **A word never heard**, between its two neighbours: a pure guess (1 in 3). | **Very likely** |
| 5 | `col.name.purple` | "אֵיפֹה הַבָּלוֹן הַסָּגֹל?" | blue, pink, purple balloon | New word, both neighbours. | **Very likely** |
| 6 | `col.name.pink` | "אֵיפֹה הַפֶּרַח הַוָּרֹד?" | red, pink, purple flower | New word, both neighbours. | **Very likely** |
| 7 | `b15.cola02.1` | "מְמַיְּנִים לְפִי צֶבַע: אָדֹם לְכָאן, וְכָחֹל לְכָאן." (*we sort by colour: red to here, and blue to here*) | drag 4 things into 2 bins drawn as a red ball and a blue ball | **Her first drag in the land, never shown.** "מְמַיְּנִים" is an adult verb; "לְכָאן… לְכָאן" points nowhere unless a bin lights exactly then; a bin drawn as a ball invites "put it on the ball". | **Very likely** |
| 8 | `b15.cola02.2` | same frame, yellow and green | as 7 | As 7, now known. | Possible |

### 1.4 The pattern behind it [G, with the evidence in §3]
1. **Teach after fail.** The same fault the owner found in the language courses on 2026-11-12 (L7): the meaning arrives at hint 3. A child who does
   not know "purple" can only guess, and three guesses in a row (items 4 to 6) look to her like a game she cannot play.
2. **Diagnostic items used as first items.** Each distractor carries a tag (good diagnosis for a 3- to 4-year-old who already knows the words), but
   no item came first that a beginner could get right. Lures belong after success, not before.
3. **No referent, no model.** The curriculum's own rules (§8.3: "names the action and the object", "model, don't describe", no pronoun without a
   referent) were broken by "the same colour" and "here, here".
4. **Explaining is not helping at 2.** Under 3, children follow a new on-screen action mainly when a live adult shows it (Hiniker and others 2015, in
   `docs/research/age-fit-design.md`) and learn a word from a screen when the touch is on the thing that matters (Kirkorian and others 2016) [R].
   The help she needed was her father's finger, which is exactly what the app should do first.
5. **No reason and no reaction.** Nothing in the lesson wanted anything; the question was a test, not a request; a touch made no sound; a right
   answer was a tile tint and a flat line (design §1.3, sound §1d).

---

## 2. The same lessons on `lands-ux` (Stage 2), honestly

### 2.1 What she would meet now [M]
`colour-match` is now: Show `show.col-a-01` (Goni sorts a red ball, a blue balloon, a red flower into a red and a blue bin; the child moves the
blue flower) → Together `col.match.red` (sort 4 into red and yellow, Goni lays the first) → Alone sorts `col.match.blue`, `col.match.yellow`,
a second Show `show.col-a-02` before `col.name.red.ball` (3 bins red, yellow, green) … → Use `b15.cola02.3` (tap "the yellow shape"). On a P1 phone
the arc keeps at most 5 screens (`arcScreensByStage`). In the 73 Band A colour activities, 33 are sorts, 27 taps, 7 Shows, 6 spot-the-error.

### 2.2 What Stage 2 fixes

| Problem on fb39dc08 | On lands-ux | Fixed? |
|---|---|---|
| Asked before shown | Every lesson opens with Goni's Show, unscored | **Yes**, for the action. Partly for the words (2.3 b) |
| No model of the drag | Goni drags three, she drags the last; Together: Goni lays the first | **Yes** |
| All taps, 3 choices | Mostly sorts (hands-on), a few taps | **Yes** |
| A scored first screen | Show writes no evidence | **Yes** |
| Long lessons | 5 screens at P1 | **Partly** (screens, not touches: 4 drags per sort) |
| "Where is the same colour?" ×4 | Gone from the first lesson except `col.match.green` | **Mostly** |

### 2.3 What remains for a very young child (by item)
a. **Adult words.** Prompts average 5.3 words, 35 of 73 are over 6 words; **30 contain "לְכָאן" and 26 "מְמַיְּנִים"** [M]. The Show opens with
   "כׇּל צֶבַע לַבַּיִת שֶׁלּוֹ" (*every colour to its own house*): "colour" as a category noun and "house" as a metaphor for a bin drawn as a ball.
b. **The names are not joined to the moves.** `show.col-a-02` says "אָדֹם. צָהֹב. יָרֹק." once, at the first move, while only the red thing moves;
   the next moves are silent. `show.col-a-01` says its key line once. A toddler learns a colour word when it is said **as** she looks at the
   colour, and better **after** the thing ("the ball… red", Ramscar and others 2010) [R]. Hebrew puts the adjective after the noun already; the Show
   just has to say it at each move.
c. **The lure comes first.** The Together item `col.match.red` (the first thing she moves herself) holds a yellow **ball** beside a red-ball bin,
   tagged M-SORT-SHIFT. The diagnostic conflict is the first decision, not a later one.
d. **Verbal hints.** Hint 1 "בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה" is on 65 of 66 scored Band A colour items; hint 2 "נִסְתַּכֵּל עַל כׇּל קְבוּצָה,
   וְנִרְאֶה מַה יֵּשׁ לָהּ" on 33; hint 3 "כׇּל הַדְּבָרִים בְּאוֹתוֹ צֶבַע הוֹלְכִים יַחַד" on 19 [M]. The pictures behind them (B-40) help; the
   words do not, for a 2- or 3-year-old.
e. **Questions as tests.** "אֵיפֹה הַצּוּרָה הַצְּהֻבָּה?" (`b15.cola02.3`: "shape" is an unknown word, the yellow circle sits beside an orange
   one). Spot-the-error prompts say "מָה הִגִּיעַ לְכָאן בְּטָעוּת?" (*what got here by mistake?*): a "which is not" task with the word טָעוּת.
f. **Lesson 2 still asks three new names with their neighbours** (orange/red, purple/blue, pink/red) as sorts. Its Show names orange, pink and
   purple, once, as a list.
g. **No purpose, no story, no planned laugh.** Nobody wants anything; the sort is "because". Goni already turns the colour she found
   (`rooms/goni_skin.dart`), but only after a right answer, in a corner.
h. **No errorless first steps, no repetition with variation.** The replay of a lesson is the same set; no visit starts with "everything you
   touch is right".
i. **Pace and talk before the first touch.** Greeting (≥3 s, silent for Goni) + Show (open line, three host moves with pauses, handover line)
   before her first touch: about 15 to 20 s by the code's pauses [G]. A 2-year-old's first touch should come in under 3 s.
j. **Celebration** is still the end card (design §1.2); for her, 12 to 16 drags away.

### 2.4 The first minute now, for a child who knows no colour names [G]
0 to 4 s silent bubble; 4 to 18 s Goni moves three things and says "every colour to its house", "red ball, red balloon: the same colour", "now
your turn: the blue flower" (she does not know which is blue; the flower is the only thing left, so she can succeed by elimination, which is
fine). 18 to 40 s: "we sort by colour: red to here, and yellow to here"; she drags a yellow ball to the red-ball bin (it looks like its twin); it
floats back with "let's try again"; the hint asks her to listen to the question again. That is the moment her father reaches over.

---

## 3. She is 2: what the evidence says, and what to build

### 3.1 What a 2- to 3-year-old can do [R unless marked]

| Area | Evidence | Meaning for the app |
|---|---|---|
| Colour words | Parent reports in 11 languages: about half of toddlers understand the four basic colour words by 21 months, most by about 30 months; eye-tracking shows signs at 19 months; production comes later and errors are over-extensions (Forbes and Plunkett 2018, via the authors' manuscripts and summaries). Errors fall at **category boundaries**, not on the focal colour (Wagner, Dobkins and Barner 2013, via later papers). CDC 2022 at 30 months: "shows he knows at least one color, like pointing to a red crayon when you ask, 'Which one is red?'" | At 2;0 to 2;6, **one basic colour at a time, with maximum contrast** (red vs blue, never red vs orange). Orange, purple, pink, brown, grey wait. A red/orange error at 2 is normal development, not a misconception to log. |
| Learning a colour word | Two-year-olds learned colour words in a short training when the word came **after** the object ("the crayon is red"), not before (Ramscar and others 2010). Corrective contrast ("it's not red, it's X") is studied with mixed results (Au and Laframboise 1990, via citing papers). | Say the colour **after** the thing, at the moment she looks at it: "הַכַּדּוּר… אָדֹם!". On a non-target touch, name what she touched (contrast), lightly. |
| Matching and sorting | Sequential touching (1 to 3 years) is the standard measure of early categorising; sorting by one attribute emerges between about 18 and 36 months; 3-year-olds sorted by colour more after **watching an adult sort by colour** (search summaries of the California infant/toddler foundations and of the studies; I could not open the California page). Toddlers extend and match by **shape or kind** before colour (the shape bias: Landau, Smith and Jones 1988). | Matching by colour must remove the kind lure first (the model and the options of one kind, or a model that is not an object: Goni's skin). Sorting must be shown by the host, then done. |
| Counting | Children learn "one" around 2;6 and spend many months as one-knowers; subset-knowers until about 3;6 (Wynn 1990, 1992; Sarnecka and Wright 2013, via summaries). | Counting Hills' first steps: "one", "one more", "two", and counting chants; not "count 5 butterflies, give 4". |
| Instructions | CDC 2022: 24 months, points to things in a book when asked ("Where is the bear?"); 30 months, follows two-step instructions (in a familiar routine, with a live adult). | "איפה ה…?" is a good form at 2, **if** the word is known. One step, one known noun, one known adjective. |
| Learning from a touch screen | Touch-screen contingency helped 24- to 36-month-olds learn a word **only when the touch was on the important thing** (Kirkorian, Choi and Pempek 2016, n = 116, abstract). Children under 3 followed a new gesture mainly when a live adult showed it (Hiniker and others 2015, as read in `age-fit-design.md`). Learning from video is about half a standard deviation below face-to-face, less with age (Strouse and Samson 2021, meta-analysis of 59 reports). | The touch is the lesson: she touches the red thing and **the red thing and Goni react**. Invite the parent to play beside her; the app cannot fully replace the adult at 2. |
| Humour | Children of 19 to 36 months copy an adult's **jokes** (a hat over the eyes, signalled by laughter) and **correct** the adult's mistakes (signalled by "woops") (Hoicka and Gattis 2008). | A planned silliness with a laugh cue is understood at 2, and a mistake the host makes on purpose is something she can fix: a natural, errorless "do it right" moment. |
| Play and apps | Guided play beat direct instruction on early maths (g = 0.24) and shape knowledge (g = 0.63) (Skene and others 2022, 17 studies). Apps teach when active, engaged, meaningful and social, inside a learning goal (Hirsh-Pasek and others 2015). | A goal inside a small story (help Goni), with the adult invited in. |
| Screens at 2 | AAP 2016: 18 to 24 months only high-quality media, co-viewed; 2 to 5 years about 1 hour a day. WHO 2019: at 2 years, sedentary screen time at most 1 hour, less is better. | Short sessions (P0 default 5 min), a "play together" line for the parent, and a free-play corner. |
| Israel | Day care for birth to 3 is supervised by the Ministry of Education's early-childhood division; its resources stress routine, sensitive adult mediation, curiosity and independence, and set no colour or number targets that I could find. The gan maths programme starts at gan age 3 (curriculum §3.1); colours are gan vocabulary, not a maths goal (`age-fit-teaching.md` §3). | Under 3, the app's job is play and words with an adult, not targets. Our Band A stays the gan-3 entry. |
| Errorless learning | Errorless and prompt-delay procedures come mostly from behaviour analysis (Terrace 1963; Touchette and Howard 1984), largely with children with disabilities; I found **no systematic review in typically developing toddlers**. | Use errorless steps as a **motivation and modelling** choice for P0 and for the first touch of a new skill, not as a proven method. Watch her and adjust. |

### 3.2 What she can and cannot do yet (working profile, P0 = under 3;0) [G from 3.1]
- **Can:** touch to make things happen; match an identical colour when the kind is the same; point to one or two basic colours named, if she has
  heard them often; put things in a container after watching; "one" and "more"; laugh at a silly act; repeat the same game many times.
- **Cannot yet:** colour names beyond the four basic ones, look-alike hues, "the same" as a word, colour and kind at once, sorting with a
  conflicting kind, counting past one or two with meaning, a new gesture shown only by a cartoon hand, waiting through talk.

### 3.3 Recommendation: P0 look stage + a "first steps" entry per land, errorless
- **Not a separate app, not a lower Band A for everyone.** 3- and 4-year-olds need the tagged items, and the band is a content grouping. Lowering
  Band A's entry would empty it of diagnosis.
- **Yes to the design-director's P0** (under 3;0; delight §2): 2 choices, 112 pt targets, one-tap placement, greeting ≤ 2 s, Show ≤ 6 s and
  skippable by touch, 3 screens then the party, no text.
- **New: a "first steps" entry (2 to 3 lessons per land)** built from existing Band A skills in their narrowest form, played errorless. It is
  served only at P0, and to a P1 child as the first lesson of a land only if the parent asks for it. It needs no new skill id; it needs a path
  rule, so it is a **proposal for the owner** (§6 Q2).
- **The errorless start for everyone** (P1 and up too): the Together item of a skill's first lesson has maximum contrast and no lure; lures and
  tags come in Alone, after a success. This keeps every misconception reachable and removes the "trap first" pattern (a content rule, §5 R6).

### 3.4 What P0 serves (answer to design H3)

| Land | First-steps lessons (existing skill, narrowed) | Errorless form | Not at P0 |
|---|---|---|---|
| Colour Bay (pilot, §4) | COL-A-01 match Goni's colour, one colour a visit; COL-A-02 receptive naming of red, yellow, blue, green, one at a time, 2 choices of maximum contrast; COL-A-01/A-04 two baskets, two far-apart colours | Non-target touch: Goni "tries it on" and turns that colour, names it, laughs; the target glows | A-03, A-05, A-06, A-07, look-alike hues, kind-conflict sorts, spot the error |
| Counting Hills | NUM-A-01 counting chant 1 to 3 (tap along, Nekudi says each number); "one" (give one butterfly a flower); "one more" | Each tap counts and the butterfly flies; "give one" accepts only one (the second does not leave the pile) | NUM-A-03/04 beyond 3, give-N above 2 |
| Shape Forest | SHP-A-01 shape sorter with circle and square only, holes much larger than the pieces; MATH-A-04 big and small (two sizes far apart) | A piece dropped near any hole slides to its own hole | names of shapes, triangles in other turns, rectangles |
| Riddle Grotto | LOG-A-01 find the same (2 choices, identical picture vs a very different one); LOG-A-03 two bins by a rule shown with the first two | A wrong pick does a silly dance and the pair glows | odd one out by one attribute among similar, patterns |
| Market Village | MATH-A-04 big and small; "a lot" and "one" (a full basket vs one apple) | Pnina gives whatever she touches and names it | coins, prices, time |
| Robot Harbour | CS-A-02 body moves with Tza'adon ("jump!" and she taps, the robot jumps) | Every arrow tap moves the robot; no goal at first, then one landmark next to it | sequences of steps, routines |

P0 lessons are 3 screens (hook, show-and-together, one alone) plus the party, about 60 to 90 s.

### 3.5 How the engine treats a P0 child (for the app-developer; reasons in brackets)

| Rule | P0 | Why |
|---|---|---|
| Placement / warm-up | None | Nothing to place; a 2-year-old's taps are not a test. |
| Evidence and mastery | **None written.** Attempts are stored as `play` (for the parent's "what she played") and never feed BKT, FSRS or mastery | A boundary error at 2 is development, not a misconception; tags at 2 would mislabel her. |
| Wrong answer | Never: no "not yet" line, no hint ladder, no "?" button. A non-target touch gets the host's playful reaction and the target glows; on the next touch it is done | Errorless (§3.1 caveat); "unclear is never wrong" in its widest form. |
| Revisits and spacing | None scheduled. Today's Adventure rotates the first-steps lessons of the land she taps; she may replay a favourite at once | Repetition is what toddlers ask for; spacing is for durable mastery, which is not the goal yet. |
| Lesson variety | Each visit a different variant (§4.5) | Repetition with variation. |
| Session | Default 5 min, parent can raise to 8; a parent card "play together" on her profile | AAP/WHO; the video deficit. |
| Rewards | A sticker per finished lesson, the party; no medal or trophy (they mean lasting understanding) | |
| Parent view | "Met: red, yellow"; never "learned", "behind" or a level | No stigma (`age-fit-teaching.md` §4). |
| Turning 3;0 (P1) | The Band A path from its start, no placement; "met" marks only pick a familiar first lesson; nothing she did as P0 counts as evidence | Clean start, nothing lost. |

---

## 4. Colour Bay as the pilot of M12: the first three lessons

### 4.1 The frame
**Goni is a chameleon** (`rooms/goni_skin.dart` already recolours him to the colour found). The story of the land: **Goni wants a colour, and
when he touches a thing he turns its colour.** So:
- every touch has a visible, funny effect on the character she watches (cause and effect, specific to the colour: Kirkorian 2016);
- Goni's skin is a **colour model that is not an object**, so "like Goni" teaches matching without the ball/balloon lure;
- a non-target touch is not wrong: Goni turns blue, laughs, says "blue!" (a contrast label), and wants red again.

Roles (M11 Q1 kept): **Goni** (host) wants, shows, changes colour, laughs, cheers at the end. **The companion** (her friend) is on her side:
"let's help Goni!", cheers each find, gives the gentle line after a non-target touch. The companion never quizzes.

### 4.2 Lesson 1: "Goni wants red" (גוני רוצה אדום). COL-A-01, with the word "red" by exposure
Aim: match Goni's colour; hear "אָדֹם" ten times, each time on a red thing she touched. About 70 s at P0, 2.5 min at P1.

| Beat | What happens | Goni | Companion | She does | P0 / P1+ evidence | Laugh |
|---|---|---|---|---|---|---|
| Hook (≤ 3 s, touchable) | Goni (mint) sits on a rock. A red balloon floats in. Goni touches it and ripples red, delighted | H1 | C1 | May touch the balloon: it bobs, Goni ripples again | none / none | the colour flip with a "shloop" |
| Show (≤ 6 s P0, ≤ 10 s P1) | A red flower and a red ball appear; Goni touches each, names it after the thing; then a red apple: Goni points at it with his hand and waits | H2, H3, H4 | — | Touches the apple: it hops into Goni's basket, Goni pulses | none / none | Goni's tongue flicks to the apple |
| Together (errorless by construction) | Three red things (ball, balloon, flower) drop from a tree | H5 per touch | C2 | Each touch: the thing jumps into the basket, Goni names it | none / scored as today but cannot be wrong | the basket burps a tiny bubble at the third |
| Alone a | Red ball vs **blue** balloon (2 choices) | H6 invitation | C3 after a find | Touch | none / scored, default tag | **Non-target:** Goni touches the blue balloon, turns **blue**, gasps and giggles (H7), then the red ball glows |
| Alone b | Red flower vs **yellow** ball | H6 | C3 | Touch | none / scored | same, Goni turns yellow |
| Alone c | Red apple vs **green** apple (same kind, so colour is the only difference) | H6 | C3 | Touch | none / scored | |
| Alone d (**P1 and up only**) | Goni red; red balloon, **orange** balloon, blue ball (today's `col.match.red`, Goni replacing the ball as the model) | H6 | C3 / C4 | Touch | — / scored; M-COL-NAME on orange, M-SORT-SHIFT is not reachable without a kind model, so it moves to lesson 2 | |
| Celebrate | Goni's basket full of red things; he dances red; each touch on the basket pops a red thing up and Goni names it | H8 | C5 | Touches | — | Goni hiccups red bubbles |

### 4.3 Lesson 2: "Two baskets" (שני סלים). COL-A-01 to COL-A-04 (sort by colour), red and yellow, then blue and green
Aim: put each thing in the basket of its colour; hear the colour as each thing goes in.

| Beat | What happens | Goni | Companion | She does | P0 / P1+ | Laugh |
|---|---|---|---|---|---|---|
| Hook | Goni sneezes ("אַפְּצִ'י!") and turns red **and** yellow in stripes; two baskets land, one red, one yellow (a basket tinted with a big colour blob, not a ball sprite) | H9 | C6 | May touch Goni: another sneeze, new stripes | none | the sneeze |
| Show | Goni puts a red ball in the red basket ("red, to the red basket"), a yellow banana in the yellow one; then he puts the second banana **on his head as a hat**, laughs (joke cue), and points at it | H10, H11, H12 | C7 "silly Goni!" | Touches the banana: it jumps into the yellow basket | none | the banana hat (a joke she can fix: Hoicka and Gattis) |
| Together | 4 things, different kinds, no conflict (red flower, yellow balloon, red apple, yellow sun); Goni puts the first | H13 per move | C2 | P0: tap, the thing flies to its basket; P1: drag | none / scored, no lure | a thing that lands does a little bounce and a "plop" |
| Alone a | 4 things, red and yellow, different kinds | — | C3 | P0 tap / P1 drag | none / scored | |
| Alone b (**P1 and up**) | **Kind conflict**: red ball, yellow ball, red balloon, yellow balloon (today's `col.match.red` items, tag M-SORT-SHIFT) | — | C4 after a non-target drop | drag | scored, tagged | |
| Alone c | Blue and green baskets (P0: blue vs yellow instead; blue/green is closer) | H9b | C3 | as above | none / scored | Goni turns blue-green |
| Celebrate | Baskets bounce; Goni half red, half yellow; she taps a basket and it sings its colour name | H14 | C5 | Touches | — | |

### 4.4 Lesson 3: "Where is red?" (איפה האדום?). COL-A-02, receptive naming of the four basic colours, one at a time
Aim: point to a named colour. Hide and seek is the frame: a chameleon hides by colour.

| Beat | What happens | Goni | Companion | She does | P0 / P1+ | Laugh |
|---|---|---|---|---|---|---|
| Hook | Goni turns green on the grass and **vanishes**; the companion asks where Goni is; any touch on the grass and Goni pops out (peekaboo) | H15 | C8 | Touches: Goni pops out and laughs | none | peekaboo |
| Show | A red balloon and a blue ball. Goni: "where is red? … here! red!" touches the balloon, it floats up a little; "where is blue? … here! blue!", the ball bounces | H16, H17 | — | Watches; any touch skips | none | the ball bounces on Goni's head |
| Together | "where is yellow?": yellow flower vs blue ball; at P0 the yellow glows after 2 s still; Goni's hand hovers near it | H18 | C2 | Touch: the flower opens, Goni turns yellow, names it after the thing | none / scored, no lure | |
| Alone a to c | One basic colour each (red, blue, green), 2 choices at P0 (maximum contrast), 3 at P1 with one far and one mid-distance distractor; the target's place varies | H18 | C3 | Touch | none / scored | non-target: the thing does its action, Goni turns that colour and says its name (H19), then the target glows (P0) or waits (P1) |
| Alone d (**P1 and up**) | The boundary items: `col.name.red.near` (orange, red, pink) and `col.name.blue.balloon` reframed (green, blue, purple at P2+) | H18 | C4 | Touch | scored, M-COL-NAME | corrective contrast on a miss (H20) |
| Celebrate | Goni ripples through the four colours; her touches leave paint drops; Goni names the colour of each drop (the design's Colour Bay party toy, delight §4.2.3) | H21 | C5 | Paints | — | |

Lessons 4 onward (A-03 orange, purple, pink; A-06 brown, grey; A-05; A-07) follow the same frame at P1 and up, each new colour introduced by its own
Show beat said at its own move, never as a list, and never asked before it is shown.

### 4.5 What varies on a replay (no two of the first three visits alike)
- **The colour Goni wants** (lesson 1): red, then yellow, blue, green, then a random one she has met. Lesson 2's pair and lesson 3's order rotate.
- **The things**: from ball, balloon, flower, apple, banana, sun, grass in each colour (all drawn: `ball_*`, `balloon_*`, `bloom_*`, `apple`,
  `apple_green`, `banana_*`, `sun`, `grass`), at least two new things a visit.
- **The joke**: the flip, the sneeze, the hat, the hiccup, the peekaboo place (grass, a leaf, the sea), one per visit.
- **The target's place** on the screen; the companion's line from a pool of 6 (C3).
- The structure does **not** vary: same beats, same words for the same act (curriculum §8.3 "same action, same words").

### 4.6 Where the diagnosis lives now (nothing lost)

| Misconception | Old place | New place | Who meets it |
|---|---|---|---|
| M-COL-NAME (look-alike hue) | first lesson, first item | lesson 1 Alone d, lesson 3 Alone d, then the A-03 and A-06 lessons | P1 and up |
| M-SORT-SHIFT (kind over colour) | first item (tap), first Together (sort) | lesson 2 Alone b, then `colour-sorting` | P1 and up |
| M-COL-ONEATTR (colour and kind at once) | `col.name.red.ball`, `col.name.blue.balloon` in lesson 1 | the COL-A-07 lessons, where it belongs | P2 and up (3;6+) |
| M-COL-OBJECT | unchanged (`colours-of-things`) | unchanged | P1 and up |

The existing activities stay in the pack; they move later in the lessons. Every scored P1 item keeps its two tagged distractors or classifiers
(M11 criterion 8).

### 4.7 Hebrew drafts (all `"review": "needs-editor"`; unpointed on purpose; the editor sets nikud, gender and register)
Register: 1 to 4 words a line, the colour after the thing, exclamations, the companion speaks as "we", nothing a test, nothing negative except
the editor's choice in H20.

| Id | Speaker | Draft | Gloss | Note |
|---|---|---|---|---|
| H1 | Goni | וואו! אדום! | Wow! Red! | surprised delight |
| H2 | Goni | הפרח… אדום! | The flower… red! | name after the thing, a beat before the colour |
| H3 | Goni | הכדור… גם אדום! | The ball… red too! | |
| H4 | Goni | ועכשיו… התפוח! | And now… the apple! | his hand on the apple |
| H5 | Goni | אדום! / עוד אדום! / גם אדום! | Red! More red! Red too! | rotate |
| H6 | Goni | עוד אדום, כמו גוני! | More red, like Goni! | the invitation; the colour word changes per visit |
| H7 | Goni | אוי! גוני כחול! (giggle) איפה אדום? | Oh! Goni is blue! Where's red? | the non-target reaction |
| H8 | Goni | כל כך הרבה אדום! | So much red! | |
| H9 | Goni | אפצ'י! | Achoo! | the editor decides the spelling |
| H9b | Goni | עכשיו כחול וירוק! | Now blue and green! | |
| H10 | Goni | אדום — לסל האדום. | Red, to the red basket. | |
| H11 | Goni | צהוב — לסל הצהוב. | Yellow, to the yellow basket. | |
| H12 | Goni | (laughs) כובע! … לא, לסל! | A hat! … no, to the basket! | the joke; the editor may drop "לא" for Band A |
| H13 | Goni | לסל האדום! / לסל הצהוב! | To the red basket! To the yellow basket! | said as the thing lands |
| H14 | Goni | אדום וצהוב! יופי! | Red and yellow! Lovely! | |
| H15 | Goni | (from hiding) כאן אני! | Here I am! | |
| H16 | Goni | איפה אדום? … הנה! אדום! | Where's red? … Here! Red! | |
| H17 | Goni | איפה כחול? … הנה! כחול! | Where's blue? … Here! Blue! | |
| H18 | Goni | איפה הצהוב? | Where's the yellow? | the only question form, after the Show |
| H19 | Goni | זה כחול! (giggle) | That's blue! | the contrast label on a non-target touch |
| H20 | Goni | זה כתום. האדום — הנה. | That's orange. The red, here. | P1+ only, after a miss on a boundary item; corrective contrast |
| H21 | Goni | כל הצבעים! | All the colours! | |
| C1 | companion | גוני אדום! | Goni is red! | |
| C2 | companion | בואו נעזור לגוני! | Let's help Goni! | |
| C3 | companion | מצאנו! / הנה הוא! / יש! / עוד אחד! / גוני שמח! / כל הכבוד שחיפשנו! | Found it! There it is! Yes! One more! Goni is happy! Well done looking! | pool of 6, never the same twice in a row; process praise |
| C4 | companion | ננסה עוד פעם? | Shall we try again? | P1+ only, after a miss; an invitation |
| C5 | companion | חיפשנו ומצאנו! | We looked and we found! | process praise at the party |
| C6 | companion | גוני מצחיק! | Goni is funny! | |
| C7 | companion | גוני, זה לא כובע! | Goni, that's not a hat! | the editor decides on the negative for P0 |
| C8 | companion | איפה גוני? | Where's Goni? | peekaboo |

The old lines this replaces, for the editor's list: the sort frame "מְמַיְּנִים לְפִי צֶבַע: X לְכָאן, וְY לְכָאן" (30 prompts) becomes
"X — לסל ה-X" said at each move with the basket lit; "כׇּל צֶבַע לַבַּיִת שֶׁלּוֹ" goes; the Band A colour hints 1 and 2 (65 and 59 rows) become
a 1- to 3-word line plus the picture ("הנה האדום", "כמו גוני"), with the second still a different representation (B-40 rule).

---

## 5. The rule set: a checklist an author follows (lands and language courses)

Each lesson passes every line before it goes to the editor. R1 to R14 apply to all bands; [P0/P1] marks the stricter limits for the youngest.

| # | Rule | Check |
|---|---|---|
| R1 | **A want, not a test.** The lesson has one sentence of story: a character wants something only the skill can give ("Goni wants red", "the butterflies are hungry", "Pip lost his red sock"). | The hook line states the want. |
| R2 | **Touch in 3 seconds.** [P0/P1] At most one short line before the first touch; the hook itself is touchable. Band B: ≤ 8 s. | Count the voiced seconds before the first touch target is live. |
| R3 | **Every word is met first.** Every content word in a question (colour, shape, number, "same", "more") has been said by the host **while acting on that thing**, in this lesson or an earlier one. Extends L7's met-before and M11's `teaches` to all content words. | Validator: every word of a scored prompt is in a `teaches` list reached earlier. |
| R4 | **Name after the thing, at the moment.** In a Show every move has its own line; the attribute comes after the noun with a beat ("הכדור… אדום"); never a list of names on one move. | Every Show step with a move has a `say`. |
| R5 | **Short and concrete.** [P0/P1] ≤ 4 words a line; Band A ≤ 6; no category nouns (צבע, צורה, קבוצה) as the thing to look at before Band B; no concessive or conditional clauses; no meta-talk ("listen to the question"); "here/there" only with the place lit at that word. | Word count; a stop-list (לכאן, ממיינים, אותו, קבוצה, בטעות, שאלה). |
| R6 | **Errorless first, lures after.** The first item she does herself in a new skill has maximum contrast and no tagged lure; [P0] every item is errorless. Lures (look-alike, kind conflict) come only after one success in the lesson. | The Together item has no `misconception` on any option or item. |
| R7 | **Every touch answers, nothing is "wrong".** A non-target touch gets a playful, informative reaction (the host tries it on, names what was touched), then the target is shown ([P0] at once; Band A after the second try). No line is only "try again". | Each incorrect branch names what was touched or shows something. |
| R8 | **Show, don't tell, in hints.** [P0/P1] hint 1 is visual; any hint line ≤ 5 words; hint 2 changes the representation (B-40); hint 3 the host's hand does it with her and stops before the end. | No hint line on the stop-list. |
| R9 | **Praise the doing, in the story.** The right-answer line says what happened ("Goni is red!") or the effort ("we looked and found"); a pool of at least 6 lines; never person praise. | Pool size ≥ 6. |
| R10 | **One planned laugh.** At least one moment per lesson of incongruity the child can see (a sneeze, a hat on the wrong head, peekaboo, the host's silly mistake with a laugh cue). Never laughing at the child; never the child's answer as the joke. | The arc names the laugh beat. |
| R11 | **Short loops, end on joy.** [P0] 3 screens then the party (about 60 to 90 s); [P1] 5 screens (about 3 min); the last scored item is one she is likely to get; the party is in the story (the basket full, Goni dancing). | Arc caps (`arcScreensByStage`), the last item's difficulty. |
| R12 | **Repetition with variation.** Same beats and words for the same act; a different want, objects, joke and positions on each of the first three visits. | Two seeded visits differ in objects and target. |
| R13 | **Diagnosis intact.** Every scored item at P1 and up keeps ≥ 2 tagged distractors or classifiers; P0 writes no evidence; every misconception of the skill is still reachable in the land (map it as in §4.6). | The M11 criterion 8 test plus a reachability table. |
| R14 | **Invite the adult.** A one-line parent card per lesson ("find red things at home together"), from the misconception file's `home` text. | The skill has a home activity. |

**For the language courses** (L7's recall, meet, find, use already satisfies R3): R1 (the puppet or host wants the word: "Pip wants the red
ball", in Hebrew first), R4 (the Meet says the word after the picture, once per touch), R6 (the first Find has a far distractor; near ones after),
R7 (a non-target tap: the puppet says that word, then the target glows; never "no"), R10 and R12 apply as written. The target-language word is
never in a Band A question before Meet.

---

## 6. What this needs, and the owner's questions

### 6.1 Hand-offs
- **app-developer:** (1) the P0 engine rules of §3.5 (no evidence, `play` attempts, no placement, no revisits, no "?" button, 5-minute default,
  the 3;0 switch); (2) an **errorless mode** for `tap_answer`, `sort_drag`, `give_n`, `shape_builder` (a non-target touch writes nothing at P0,
  triggers the host's reaction line with the touched thing's colour or name, and the target glows; the next touch completes); (3) **Goni's skin
  follows any touched colour** in the hook, the errorless reaction and the party, not only after a right answer; (4) a lesson part **`hook`**
  (one touchable host beat with its line and an optional host state, ≤ 3 s, skipped by a touch); (5) **a line per Show step** (`steps[].say`
  for every move, each its own line) and a "light this place now" mark on a line, for "here/there"; (6) **one-tap placement** for P0 sorts;
  (7) **the host as the colour model** for COL-A-01 tap items (`scene.model: "host"`: "like Goni"); (8) **lesson variants on replay** (a
  seeded choice of target colour and object pool per visit); (9) validator checks for R3 (words met first), R4 (Show steps say), R5 (word
  counts, stop-list for Band A), R6 (no tagged lure in a skill's first Together). Template changes and the validator are yours; I write the data
  once they exist.
- **design-director:** baskets tinted with a colour blob (bins today are a ball or balloon of the colour); Goni's try-on and colour ripple on any
  touch, sneeze stripes, banana hat, hiccup bubbles, the peekaboo camouflage on grass, a leaf and the sea; the target glow for errorless; a check
  that `ball_*` and `balloon_*` read apart at P0 tile size and that the four basic colours are drawn at maximum saturation and distance (and that
  `apple.svg` reads red); the hook staging in under 3 s.
- **voice-and-sound-director:** Goni has **no voice** today; he is cast with the nine host voices. Per line kind: the hook delighted and surprised,
  the label clear with a beat before the colour ("הכדור… אדום"), the joke with a giggle, the non-target reaction amused never disappointed, the
  contrast line (H20) gentle; ≤ 4 words for P0 lines; sounds for the colour change, the basket plop, the sneeze, the peekaboo pop (sound notes
  §3b kit).
- **hebrew-text-editor:** the drafts of §4.7 (nikud, gender-neutral forms for a child alone, register for 2 to 3 years, "אפצ'י", the negatives in
  H12 and C7), the replacement of the 30 "…לְכָאן" sort prompts and of the Band A colour hint lines, and the Show lines named at each move.
- **qa-engineer** (once, when the pilot is built): a P0 lesson writes no evidence; the first Together of every skill has no tagged lure; every
  Show move has a line; Band A prompt and Show lines within the word limits and free of the stop-list; two visits of a lesson differ; every
  misconception of Colour Bay still reachable at P1.

### 6.2 Questions only the owner can answer
1. **Which profile did she play on**, and was a birth month entered? (Her own as gan 3, a sibling's, or a new one? It changes what she got: P1
   or P2, and possibly another child's progress.)
2. **A "first steps" entry for under-3s** (§3.3): 2 to 3 errorless lessons per land at P0, no evidence, no placement, nothing wrong, Colour Bay
   first. Or keep the app at 3 to 8 and give her only the free-play corners (delight §4.3)?
3. **Goni the chameleon who turns the colour of what he touches**, with silly moments (a sneeze, a banana hat, peekaboo) as the Colour Bay story.
   OK?
4. **Errorless start for every child** (§3.3, R6): the first item a child does in a new skill cannot go wrong, and the tagged lures come after a
   success. OK for Bands A to C?
5. **On a miss at 3 and up**, should the host name the colour the child touched ("that's orange") before showing red? (Corrective contrast;
   evidence is mixed; my recommendation: yes, gently, once.)
6. **P0 session default of 5 minutes** with a "play together" card for the parent. OK?
7. **The rule set of §5 for every land and the three language courses** as the M12 content standard, rolled out after the Colour Bay pilot is on
   his phone. OK?

### 6.3 Syllabus change proposed (to the orchestrator, for the owner)
No skill is added, removed or reordered. Proposed: **(a)** a path rule, "a P0 child is served only the first-steps lessons of a land; at 3;0 the
Band A path starts from its first lesson without placement"; **(b)** a lesson-order rule for every skill, "no tagged lure in the first Together"
(R6); **(c)** the first three Colour Bay lessons rebuilt as §4.2 to §4.4, moving `col.name.red.ball` and `col.name.blue.balloon` (M-COL-ONEATTR)
from `colour-match` to the COL-A-07 lessons. Touches: app-developer (engine, templates, validator), design-director, voice-and-sound-director,
hebrew-text-editor, qa-engineer, security-engineer (the `play` attempt kind and what the parent view and sync carry).

---

## 7. Sources
- Forbes, S. H., and Plunkett, K. (2018), cross-linguistic parental reports of colour word comprehension, *Child Development*; eye-tracking work by
  the same authors (manuscripts): https://ueaeprints.uea.ac.uk/66406/1/Accepted_manuscript.pdf ,
  https://ora.ox.ac.uk/objects/uuid:f21fd35b-d4c9-4bb6-960e-ab83cad106e8 (read as search summaries)
- Wagner, K., Dobkins, K., and Barner, D. (2013), slow mapping of colour words (via citing papers): https://repositories.cdlib.org/content/qt0fd2k5pj/qt0fd2k5pj.pdf
- Ramscar, M., and others (2010), "The effects of feature-label-order and their implications for symbolic learning", *Cognitive Science* 34,
  909–957 (two-year-olds and postnominal colour words): https://dyurovsky.github.io/learning-humans-machines/reading/04-reading/ramscar2010.pdf ,
  https://www.scientificamerican.com/article/a-simple-trick-helps-kids-learn-colors/
- Au, T. K., and Laframboise, D. E. (1990), "Acquiring color names via linguistic contrast", *Child Development* 61(6), 1808 (via citing papers):
  https://web.stanford.edu/group/symbolicsystems/Skolnick-thesis.pdf
- CDC, milestones by 30 months (2022 revision): https://www.cdc.gov/ncbddd/actearly/milestones/milestones-30mo.html (read); 24-month items via
  https://www.understood.org/en/articles/developmental-milestones-for-typical-2-year-olds
- Kirkorian, H. L., Choi, K., and Pempek, T. A. (2016), "Toddlers' word learning from contingent and noncontingent video on touch screens",
  *Child Development* 87, 405–413 (abstract): https://koeunchoi.github.io/publication/2016-03-28-word-learning-touchscreens
- Hiniker, A., and others (2015), "Touchscreen prompts for preschoolers", IDC 2015: https://depts.washington.edu/chilllab/?p=186 (and
  `docs/research/age-fit-design.md`)
- Strouse, G. A., and Samson, J. E. (2021), "Learning from video: a meta-analysis of the video deficit in children ages 0 to 6 years", *Child
  Development* 92(1): https://red.library.usd.edu/se-fp/3
- Hoicka, E., and Gattis, M. (2008), "Do the wrong thing: how toddlers tell a joke from a mistake", *Cognitive Development* 23(1), 180–190:
  https://orca.cardiff.ac.uk/id/eprint/5600/
- Wynn, K. (1990, 1992), give-a-number and the knower levels (via): https://pmc.ncbi.nlm.nih.gov/articles/PMC3830647 ,
  https://sites.socsci.uci.edu/~lpearl/courses/readings/SarneckaWright2013_ExactNumber.pdf
- Sorting and sequential touching in toddlers (search summaries): https://pmc.ncbi.nlm.nih.gov/articles/PMC2856652 ; California infant/toddler
  foundations, classification (not opened, a WAF refused): https://www.cde.ca.gov/sp/cd/re/itf09cogdevfdclas.asp
- Landau, B., Smith, L. B., and Jones, S. S. (1988), "The importance of shape in early lexical learning", *Cognitive Development* 3, 299–321 (from
  my own knowledge of the literature; not re-read for this note)
- Skene, K., and others (2022), guided play meta-analysis, *Child Development* 93(4): https://pubmed.ncbi.nlm.nih.gov/35018635/
- Hirsh-Pasek, K., and others (2015), "Putting education in 'educational' apps", *Psychological Science in the Public Interest* 16(1):
  https://www.psychologicalscience.org/publications/educational-apps.html
- WHO (2019), physical activity, sedentary behaviour and sleep for children under 5: https://www.who.int/news/item/24-04-2019-to-grow-up-healthy-children-need-to-sit-less-and-play-more ;
  AAP (2016) media guidance, via https://www.connecticutchildrens.org/advancing-kids/managing-screen-time-young-children
- Errorless learning and prompt delay (mostly with children with disabilities): https://link.springer.com/article/10.1007/s10864-020-09407-0 ,
  https://afirm.fpg.unc.edu/sites/afirm.fpg.unc.edu/files/imce/resources/PP%20EBP%20Brief%20Packet.pdf
- Israel, Ministry of Education, early childhood (birth to 3, day care): https://pop.education.gov.il/kindergarten/developmental-program-early-childhood-education-care/ ;
  the joint developmental programme for birth to 50 months (not opened): https://meyda.education.gov.il/files/Pop/0files/gani-iladim/jointAshalim-gilRach.pdf
- Repo: `git show fb39dc08:content/starter/lesson.colour-match.json`, `lesson.colour-names.json`, `activity.col.*.json`, `content/units/colours.json`,
  `app/lib/world/adventure_adapter.dart`, `app/lib/engine/age.dart`, `app/lib/strings/he.dart`, `app/lib/play/lesson_screen.dart`,
  `content/voices.json`; on `lands-ux`: `content/starter/activity.show.col-a-0*.json`, `lesson.colour-*.json`,
  `content/units/arc/colour-bay.arc.json`, `app/lib/play/lesson_arc.dart`, `app/lib/engine/presentation.dart`, `rooms/goni_skin.dart`;
  `docs/curriculum.md` §2, §8.3, §8.5; `docs/research/age-fit-teaching.md`, `age-fit-design.md`; `docs/milestones/M11.md`, `M11-stage2.md`.
