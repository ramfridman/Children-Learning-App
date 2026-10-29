# Hebrew Kids Learning App (Ages 3–8) — Product Plan

Oct 24, 2026 · @Ram

## Executive summary

**נִיצְנוּץ (Nitznutz)** is a Hebrew-first app for iOS and Android phones and tablets. It teaches children aged 3–8 numbers, colours, shapes, logic, computer science and maths through play, with a tutor they can tap answers to or simply talk to. Its central goal is genuine understanding at each child's own pace: find the gap, explain it another way, practise playfully, and come back later to confirm it lasted.

**What makes it special:**

- **An understanding engine.** Every wrong answer is tagged with the misunderstanding behind it. Failures are traced back to earlier skills, and the explanation switches form when a child struggles. A skill counts as learned only after it holds up in a check at least a week later.
- **A world that grows with the child.** Nitzi the star-jerboa's islands gain a staircase, a rainbow or a robot harbour for each skill understood, and a golden star when it lasts.
- **Talk or tap.** Hebrew speech is recognised on the device; an answer the app couldn't hear is never counted as wrong. The AI tutor asks short, Socratic questions, with a rule-based fallback that works offline.
- **Hebrew-native.** Correct gender agreement, nikud, left-to-right maths inside right-to-left screens, and 208 skills aligned to the Israeli Ministry of Education curriculum.
- **Pluggable characters.** An original cast, an original superhero squad, and family "lite packs" built from your own images for personal use.
- **Safe by design.** No ads, purchases or dark patterns in the child's space. No child audio stored. Adult features sit behind a gate. Every network call is authenticated, signed by the device and capped in cost, and vendor keys never leave the server.

|  |  |
| --- | --- |
| Syllabus | 208 skills across 6 domains and 3 age bands; about 95 in the first release |
| Activity templates | 25, with 12 in the first release |
| Technology | Flutter and Rive; on-device Hebrew speech recognition; ElevenLabs voices per character; Claude Haiku 5.5 tutor |
| Timeline | Built by you with Claude: a family build first, a public release optional |
| Running cost (family use) | About $22/month while character voices are generated (roughly two weeks of quota per voice), then $6–10/month, plus Apple's $99/year |
| AI tutor cost | About $0.02 per child per month (Haiku); live voice about $0.15–0.30 |

**See it:** the [Nitznutz app design canvas](https://claude.ai/artifact/F817YL7q2MqhPEr6K1g29Z) has 34 high-fidelity mockups. They cover phone, iPhone SE and iPad screens in both orientations, the characters (including the two family characters), the Trophy Hall, parent analytics and alerts, the design system, motion and voice states, and developer measurements.

**Play it:** the [Nitznutz playable prototype](https://claude.ai/artifact/S9isCoYqSZvH2kWdd8CdrE) runs six scenes on a phone stage: the island map, counting butterflies, "let's try another way", robot coding, a voice answer and a celebration with world growth. It has an animated Nitzi, Hebrew speech where the device has a Hebrew voice, and synthesised sound. Listening is simulated where the browser blocks the microphone.

**Next steps:**

1. All product decisions needed to start are made; the app name waits for a later rebrand.
2. Start milestone M0 in the build plan: the repository, CI, the Supabase schema with its security rules and tests, and two-factor sign-in on every account.
3. Run the discovery spikes:
   - a speech-recognition test with your own children's recordings;
   - character animation at 60 fps on a cheap Android tablet;
   - an ElevenLabs Hebrew listening test for each character voice;
   - a nikud font test.
4. Try three activities with your children, in the prototype or on paper.

## Vision & product principles

Nitznutz is a Hebrew learning world where children aged 3–8 build real understanding of numbers, colours, shapes, logic, computer science and maths at their own pace. As they learn, they watch their own island world grow. Success is measured by understanding that lasts, not by minutes played.

**Why children will love it:**

- **A world that is theirs.** Every skill they truly understand builds something on their islands, and lasting understanding earns a golden star.
- **A friend who listens.** Nitzi's ears rise and her tail glows with the child's voice, so speaking feels safe and fun.
- **The learning is the toy.** Counting a ladybug's spots, steering a robot, mixing paint: the fun comes from the thinking itself.
- **Characters they choose.** Island hosts, an original superhero squad, and your own family character packs.
- **No failing.** A wrong answer gets a gentle wobble and a new way to look at it, never a buzzer or a red X.

| Principle | What it means in the app |
| --- | --- |
| Understanding over speed | No timers or countdowns. A skill counts as learned only when the child shows it in two different forms, passes an understanding check and still has it a week later. |
| Diagnose, don't just mark | Every wrong option carries a tag for the misunderstanding it reveals. A pattern of tags triggers a quick check of earlier skills and a targeted repair. |
| Try another way | When a child struggles, the explanation changes form (objects, a picture, a number line, a story, a song) instead of repeating louder. |
| Minds-on, one idea at a time | Every tap is a maths decision; there are no reflex games. One new idea per screen, and nothing moves while the child is thinking. |
| Hear it, see it, never need to read it | Instructions are spoken first, with icons and a replay button everywhere. Text with nikud is support, not a requirement. |
| Voice welcome, never required | Every item works by tap. An answer the app couldn't hear is never counted as wrong. |
| Hebrew-native and Israeli | Correct gender agreement, shekels, the shuk, a week starting on Sunday, and maths written the way Israeli classrooms write it. |
| Calm, honest design | No ads, purchases, streak pressure, countdowns or guilt. Sessions end with a calm wind-down, and adult features sit behind a gate. |
| Grown-ups as partners | Plain-Hebrew progress, five-minute activities to do at home, and prompts for playing together. |

## Learners & age bands

Three age bands set the starting point, but each child is placed by mastery per domain, not by age. A 5-year-old can be in Band A for Shapes and Band B for Numbers. A short, game-like placement (3–5 minutes per domain) sets each starting level.

|  | Band A: ages 3–4 (גַּן טְרוֹם־חוֹבָה) | Band B: ages 5–6 (גַּן חוֹבָה to start of כִּתָּה א') | Band C: ages 7–8 (כִּתּוֹת ב'–ג') |
| --- | --- | --- | --- |
| Session length | 8 min default, 12 max | 12 min default, 15 max | 15 min default, 20 max |
| Per activity | 2–4 min, 3–5 items | 4–7 min, 5–8 items | 6–10 min, up to 12 items |
| Reading | Pre-reader: audio and icons only | Emerging: short captions with full nikud, audio first | Reads short pointed instructions; audio stays available |
| Hands | Tap; short drags with big snapping targets | Tap, drag, simple tracing | Precise drags, multi-object moves, paths on a grid |
| Voice answers | One word: a number, colour or yes/no | One or two words | Short sentences, including "how I knew" |
| Maths starting point | Counts small sets; sees 1–3 at a glance; AB patterns | Counts to 20–30; adds and subtracts within 10 with objects | Counts on; place value to 100, then 1,000; multiplication as equal groups |
| Can't yet, so we design around it | Read; follow two instructions at once; use left/right words; handle waiting | Name left and right reliably (comes around 6–7); read instructions alone; cope with speed pressure | Take someone else's left and right; sustain abstract drill; read long text |
| What motivates | Repetition, a familiar friend, being a helper | Pretend play, rules, collections, being "big" | Challenge, secrets and codes, building; dislikes anything babyish |

Parents are users too. They set up profiles, choose how Nitzi addresses each child, control voice, AI and time limits, and see progress in plain Hebrew. Siblings each get their own profile on a shared device.

## Hebrew-first requirements

The app is written in Hebrew from the start, not translated. Hebrew changes the grammar the voices use, the direction of every screen element, the fonts, and what the speech recogniser must accept.

### Speaking to the child

- **Recorded voice is gender-neutral.** Recorded voice-over uses plural commands (לִחֲצוּ, סִפְרוּ), "let's" forms (בּוֹאוּ נִסְפֹּר) or the infinitive (לִלְחֹץ).
- **The AI tutor follows the parent's choice.** At setup a parent picks masculine, feminine or plural, and the tutor's dynamic lines use that form (נַסֵּה / נַסִּי).
- **Core lines never reveal the speaker's gender.** Present-tense "I" verbs do (אֲנִי חוֹשֵׁב / אֲנִי חוֹשֶׁבֶת), so core lines avoid them and any character can say them. Gendered self-talk lives only in each character's optional flavour lines.

### Numbers and colours agree with nouns

| Use | Form | Example |
| --- | --- | --- |
| Counting and arithmetic | Feminine forms | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ… and "שָׁלוֹשׁ וְעוֹד אַרְבַּע שָׁוֶה שֶׁבַע" |
| Masculine nouns | Numeral ending in ־ָה (3–10) | שְׁלוֹשָׁה כְּלָבִים, חֲמִשָּׁה בָּלוֹנִים |
| Feminine nouns | Numeral without ־ָה | שָׁלוֹשׁ בֻּבּוֹת, חָמֵשׁ צִפּוֹרִים |
| One and two | One follows the noun; two changes before a noun | כֶּלֶב אֶחָד, בֻּבָּה אַחַת; שְׁנֵי כְּלָבִים, שְׁתֵּי בֻּבּוֹת |
| Colours | Agree in gender and number; תְּכֵלֶת never changes | כַּדּוּר אָדֹם, בֻּבָּה אֲדֻמָּה, כַּדּוּרִים אֲדֻמִּים |

- **Model it, don't police it.** The voice-over always models correct agreement and uses nouns of both genders. But everyday Israeli speech often says "שָׁלוֹשׁ כְּלָבִים", so the app accepts it as correct about the number. The tutor may echo the correct form ("נָכוֹן, שְׁלוֹשָׁה כְּלָבִים!") but never corrects grammar during maths.
- **Teen numbers are said ones-first.** שְׁלוֹשׁ־עֶשְׂרֵה is spoken "three-ten", the reverse of the digits 13. This is a known source of 13/31 confusion, so the syllabus targets it.

### Nikud

| Band | On-screen text | Nikud |
| --- | --- | --- |
| A | Captions hidden by default; numerals, the child's name and icons only | Full, wherever text appears |
| B | Short captions synced to the voice, word by word | Full |
| C | Instructions as text plus audio | Full through grade 2; grade 3 marks content and ambiguous words, and parents can switch back to full |

Nikud is written into the content with a diacritiser and approved by a Hebrew language editor; it is never generated at runtime.

### Direction

- **Maths is always left-to-right:** equations, number lines (0 on the left), rulers, the hundred chart and graph x-axes, as in Israeli schools.
- **Comparison signs only inside maths blocks.** The signs < and > flip automatically inside Hebrew text, so they may appear only inside maths isolates, and the content tools reject them anywhere else.
- **Division is written 12 ÷ 3** (owner's decision), and = is always read aloud as שָׁוֶה.
- **Stories and patterns read right-to-left,** with a start marker, and the "what's next?" slot sits at the left end.
- **The robot's program is a vertical stack of cards read top to bottom.** This sidesteps the right-to-left versus left-to-right confusion entirely. The movement arrows never mirror.
- **Band A avoids right and left words.** Children aged 3–4 can't use them reliably yet, so they hear landmarks instead ("לְכִוּוּן הָעֵץ", towards the tree). Right and left arrive in Band B with a coloured band on the avatar's right wrist.

### Israeli context

- **Daily life:** the week starts on יוֹם רִאשׁוֹן, and money uses the real coins (10 agorot, ½, 1, 2, 5 and 10 ₪) and notes.
- **Uniquely Israeli maths:** Band C includes Hebrew letter values from א to ל (ט"ו = 15), which are in the grade 1–2 curriculum.
- **Everyone belongs:** names and contexts reflect the diversity of Israeli families. Shabbat and holidays appear as optional, warm settings, never requirements.
- **Speech recognition hears children as they speak:** every gender form, prefixes such as הַ־ and וְ־, and common child pronunciations (שָׁלוֹס for שָׁלוֹשׁ).

## Curriculum & syllabus

The syllabus has **208 skills** across six domains and three bands, plus 8 cross-domain units. Each skill has an ID, a "can do" statement, its prerequisites, its mastery evidence, and the misconceptions to watch for. A skill unlocks when its prerequisites are mastered, never by age or date. The full skill list is in the Syllabus tab.

Full skill list with prerequisites and misconception tags: Syllabus: 208 skills

### Aligned to the Israeli Ministry of Education

- **Kindergarten maths curriculum (2010).** Number concept, spatial sense and geometry, and everyday quantities. Its end-of-גַּן חוֹבָה goals are our Band B exit targets.
- **The new elementary maths curriculum and its milestones (צִיּוּנֵי דֶּרֶךְ).** Grades 1–2 already learn under it, and grade 3 joins in 2026–27 (תשפ"ז). Bands B–C follow its milestones and their order.
- **The Ministry's computational-thinking programmes** for kindergarten and grades 1–2. We teach the same concepts without free typing: grid robots, picture programs, debugging, loops and conditions.
- **Cross-checks:** Clements & Sarama's learning trajectories, NCTM and Common Core K–3, and the CSTA computer-science standards.
- **Where we go beyond the maths curriculum,** clearly labelled: Colours (vocabulary, sorting attribute, then mixing science) and Logic (patterns, classifying, if-then, puzzles), because early patterning predicts later maths.
- **Milestones are reference points, not gates.** A ready 6-year-old can do grade 2 place value, and an 8-year-old can repair make-ten without being labelled "behind".

### Units by domain and band

| Domain | Band A (3–4) | Band B (5–6) | Band C (7–8) | Skills A / B / C |
| --- | --- | --- | --- | --- |
| Numbers | Count with me · Numbers I see · More or less | Counting further · Numerals · Number relations · Toward 100 | Numbers to 100 · Numbers to 1,000 · Big numbers | 14 / 18 / 12 |
| Colours | Find the colour · Colourful world | Mix & shade | Colour science & code | 8 / 7 / 6 |
| Shapes & space | Shape friends · Build it · Where is it? | Shape detectives · Shape builder · Solids & mirrors · Maps & positions | Properties · Solids · Moves · Maps | 10 / 13 / 12 |
| Logic | Same & different · Patterns · Order & pairs | Pattern makers · Sort & classify · Think it through | Rules & codes · Puzzles | 10 / 12 / 8 |
| Computer science | Step by step · Oops-fixers | Program the robot · Repeat it · Rules & data | Smart programs · Conditions & events · Data & machines | 7 / 10 / 10 |
| Math | More & gone · Big & small · My day · The shop · Picture graph | Join & take away · Into the teens · Measure · Time · Shop & coins · Puzzles & data | Addition table · Two-digit ± · × and : · Fractions · Measure · Money & data · Order & laws | 7 / 19 / 25 |
| **Total** |  |  |  | **56 / 79 / 73 = 208** |

Numbers and Math take about 35% of learning time in Band A, 50% in B and 55% in C. Colours shrink from 15% to 3%, living mostly inside cross-domain units by Band C. Ideas spiral: counting to 5 becomes counting to 30, then to 100 and counting on; AB patterns become growing patterns, then rules and missing-number equations.

**Cross-domain units:** Colourful patterns (colours + logic), The robot counts (CS + numbers), Shape houses (shapes + colours + logic), The neighbourhood shop (money + logic), Pixel painter (CS + colours + symmetry), Grandma's kitchen (a recipe as an algorithm), Number-track race (a board game proven to build number sense) and Zoo survey (data).

### 25 activity templates

Engineers build the templates; educators fill them with content. Every template works by tap, and each has a voice path with an accept-list, error classifiers that tag misconceptions, and difficulty knobs.

- **Answer and count:** tap the answer, count and tap, ten-frame flash, speak the answer, match pairs.
- **Build and move:** drag to sort, build the pattern, shape builder, mix the colours, balance scale, equal groups and arrays, fraction fold.
- **Lines and paths:** number-line jump, robot path coding, trace the numeral or shape.
- **Real life:** story problem, shop and pay, clock setter, measure it, data builder.
- **Thinking:** what's next, odd one out, fix the mistake, explain it, sound and move.

### Sample items across the bands

| Band | Skill | Hebrew prompt (meaning) | Answer | A wrong answer and what it reveals |
| --- | --- | --- | --- | --- |
| A | Counting | כַּמָּה כַּדּוּרִים יֵשׁ? (How many balls?), 4 shown | 4 | 5: counted one twice |
| A | Comparing | אֵיפֹה יֵשׁ יוֹתֵר דָּגִים? (Where are there more fish?), 4 big vs 5 small | The 5 small | The 4 big: judges by size, not number |
| A | Shapes | אֵיפֹה עוֹד רִבּוּעַ? (Where is another square?) | The tilted square | Rejects it: thinks a turned square isn't a square |
| B | Teen numbers | אֵיפֹה הַמִּסְפָּר שְׁתֵּים־עֶשְׂרֵה? (Where is 12?) | 12 | 21: reverses the digits |
| B | Equals sign | מָה צָרִיךְ לָשִׂים כְּדֵי שֶׁיִּהְיֶה שָׁוֶה? 3 + 4 = □ + 2 | 5 | 7: reads = as "the answer comes next" |
| B | Loops | Shorten the program ⬆↱⬆↱⬆↱ | Repeat 3 × \[⬆↱\] | Repeat 6: counts steps instead of repeats |
| C | Subtraction | 52 − 27 = □ | 25 | 35: takes the smaller digit from the larger in each column |
| C | Word problems | לְדָנָה 8 מַדְבֵּקוֹת, 3 יוֹתֵר מִנּוֹעָה. כַּמָּה לְנוֹעָה? (Dana has 8 stickers, 3 more than Noa. How many does Noa have?) | 5 | 11: added because of the word "more" |
| C | Fractions | שְׁלִישׁ פִּיצָה אוֹ רֶבַע פִּיצָה? (A third or a quarter of a pizza?) | A third | A quarter: thinks a bigger number means a bigger piece |

### Sample lesson: Band A, "Butterflies in the garden" (about 4 minutes)

| Step | On screen | Nitzi says | The child |
| --- | --- | --- | --- |
| 1 | Warm-up: a red and a yellow flower | אֵיפֹה הַפֶּרַח הָאָדֹם? (Where is the red flower?) | Taps or says "אָדֹם" |
| 2 | 3 butterflies in a line | בּוֹאוּ נִסְפֹּר אוֹתָם. נוֹגְעִים בְּכׇל פַּרְפָּר פַּעַם אַחַת. (Let's count them. Touch each butterfly once.) | Taps each; it flies to the flower as the voice counts |
| 3 | All on the flower; choices 2 · 3 · 4 | כַּמָּה פַּרְפָּרִים יֵשׁ עַל הַפֶּרַח? (How many on the flower?) | 3. Choosing 4 shows double counting; 2 shows a skipped one |
| 4 | 4 butterflies, scattered | Count again; each one flies to the flower | 4 |
| 5 | 5 scattered, and they stay put (harder) | הַפַּעַם הֵם נִשְׁאָרִים בַּמָּקוֹם. (This time they stay in place.) | 5; tapped ones glow so none is recounted |
| 6 | Understanding check: a jar of 7 | תְּנוּ לַפֶּרַח אַרְבָּעָה פַּרְפָּרִים. (Give the flower four butterflies.) | Moves exactly 4; taking all 7 shows the total isn't understood yet |

If a butterfly is counted twice, Nitzi says "looks like one butterfly got counted twice, let's count slowly". The hints escalate from a slower replay, to counting on fingers together, to a worked example where Nitzi counts and hands the turn back. The celebration praises the strategy ("you counted slowly and checked every butterfly"), and a butterfly joins the child's garden.

### First-release content

|  | First release (Bands A–B, Band C preview) | Full launch (Bands A–C) |
| --- | --- | --- |
| Skills | about 95 | 208 + 8 cross-domain units |
| Templates | 12 | 25 |
| Authored activities | about 300 | about 730 |
| Items (many generated from parameters) | about 2,400 | about 6,200 |
| Recorded core voice lines | about 3,000 | about 7,000 |

The first release prioritises the strongest predictors of later maths, in this order: counting, quick recognition of amounts and the ten-frame, comparing, joining and separating within 10, patterns, shapes in any orientation, then robot paths and debugging.

## Genuine understanding: the learning engine

Every skill runs through one loop: diagnose the gap, re-teach it another way, practise playfully, check real understanding, then come back days and weeks later. The engine runs entirely on the device, and every rule is a parameter the curriculum team can tune without engineers.

&#91;embedded content: the understanding loop · 8 steps, 2 loops back\]

A single slip only lowers the estimate; a pattern of tagged errors sends the child to re-teaching. A failed revisit loops back to re-teaching in a new representation, and nothing the child built is ever taken away.

### 1. Diagnose: find the actual misunderstanding

A catalogue of about 70 known misconceptions drives diagnosis. Every wrong option, every telling tap pattern and every likely spoken wrong answer is tagged.

| Misconception | What the child does | How the app repairs it |
| --- | --- | --- |
| Counts an object twice | Says 5 for 4 scattered ladybugs; the tap log shows a repeat | Each ladybug must be moved to a leaf as it is counted |
| Judges "more" by size | Picks 4 big fish over 5 small ones | Pair the fish one-to-one with lines, then count |
| Turned square isn't a square | Rejects a tilted square as a "diamond" | Rotate it with a finger and watch it stay a square; count sides and corners |
| = means "answer comes next" | Answers 7 for 3 + 4 = □ + 2 | A balance scale: what makes both sides the same? |
| Smaller-from-larger subtraction | 52 − 27 = 35 | Base-ten blocks: open a tray of ten into ten singles |
| Keyword grabbing | Adds whenever it hears "more" | Act the story out, then draw a bar model |

- **A pattern, not a single slip.** One wrong answer only lowers the mastery estimate. A misconception becomes active after evidence across at least two separate items.
- **Trace back to earlier skills.** On a real failure, the engine checks the weakest prerequisite with one or two quick "can you help me?" items. If that fails too, it repairs the earlier skill first, then returns.
- **Prove the repair.** After repair, the child gets an item designed to expose the old mistake: 52 − 27, not 58 − 23, which the wrong method gets right by luck.

### 2. Re-teach: try another way

Every core skill has at least three of five representations: **objects to move**, **a picture or model** (ten-frame, number line, bar model), **a story**, **body and song** (fingers, claps, "stand like the robot"), and **symbols**. After two errors, the next item uses a different one. The engine learns which representation works best for each child and tells parents ("learns well with objects to move"). Example ladder for 8 + 5: two ten-frames ("8 and 2 more fill the frame, 3 left"), then fingers, then two jumps on a number line, then a 10-seat bus, then 8 + 5 = 8 + 2 + 3 = 13.

### 3. Check real understanding, not rote

| Check | Example |
| --- | --- |
| Predict, then test | "Where will the robot stop?", then run it |
| Show it another way | Pick the picture that shows the same number as this ten-frame |
| New context | Counted apples? Now count drum beats |
| Reverse question | 3 + 4 = □ and □ + 4 = 7; "how many?" and "give me 4" |
| Spot the error | "The robot counted 1, 2, 3, 3, 4. Oops, what happened?" |
| Explain back | "How did you know?" by tapping a reason picture, or by voice in Band C |

### 4. Mastery with memory

| Status | Rule | The child sees | The parent sees |
| --- | --- | --- | --- |
| Learning | Below the mastery bar | A seedling | Practising |
| Fresh mastery | Mastery estimate ≥ 0.95, at least 4 independent successes over 2 days (6 for core skills), two representations, one understanding check passed (two for core skills) | A leafy plant | Practising, almost there |
| Durable mastery | A delayed check at least 7 days later, with a different item, passes | A tree with fruit and a golden star on the island | Understood |
| Needs a revisit | A delayed check failed, or memory strength is low | A leaf that needs watering; nothing is ever removed | Needs a revisit |
| Gap found | Found by tracing back; repair is under way | Nothing | Gap found, in plain Hebrew |

A memory model (FSRS-style) schedules each check when the chance of remembering drops to 90%. For a typical skill that is roughly 1, 3, 7, 21 and 60 days. Checks are one to three items woven into ordinary play as "calls for help" on the map, so the child never feels tested. A failed check triggers a gentle re-teach in a representation different from both the original and the failed one.

### 5. Self-paced by design

- **No calendar.** Each domain progresses on its own, at most two new skills per session, and only when prerequisites reach 80%.
- **"I'm not sure" is a first-class answer.** It has no penalty, opens help immediately ("great question, let's look together"), and repeated use starts a diagnostic check instead of more items.
- **No timers.** Band C may add an optional, parent-controlled "beat your own record" game, only for facts already durably mastered.

| Session part | Band A (about 8 min) | Band B (about 12 min) | Band C (about 15 min) |
| --- | --- | --- | --- |
| Warm-up, easy win | 1 item | 1–2 items | 2 items |
| Repair of active gaps, if any | up to 25% | up to 25% | up to 25% |
| New learning, 1–2 skills | 35–55% | 35–50% | 30–45% |
| Revisit checks | 15–20% | 20–25% | 25–30% |
| Delight: creative, low stakes | 20% | 20% | 20% |
| Calm wind-down, then stop | always | always | always |

**Worked example (Band C).** Maya, 7½, answers 52 − 27 = 35 and 64 − 38 = 34. The engine flags smaller-from-larger subtraction and checks place value: she knows 52 has 5 tens but can't make 52 from 4 tens. It repairs place value with blocks (opening a ten), returns to subtraction with blocks and then in columns, and clears the flag. When her 21-day check fails, it switches to counting up on a number line (27 → 30 → 50 → 52) and adds a spot-the-error item. She explains by voice, "he took 3 from 8, backwards", passes the next two checks, and the skill becomes durable.

## AI tutor & voice

The tutor is a short-turn, Socratic helper inside activities, not an open chat. Authored lines carry most of the teaching. The AI adds a personal next step when an answer is unexpected, when a child explains their thinking, or when a different explanation is needed. Every behaviour has a rule-based fallback, so the full experience works offline or with AI switched off.

### Voices

- **Every character speaks in its own voice, everywhere.** The companion the child picks is the guide on every screen, and it says *all* the lines: instructions, praise, hints and the tutor's live sentences. Nitzi, each island host, each hero and each family character gets its own ElevenLabs voice, chosen from the voice library or made with Voice Design.
- **Core lines are generated ahead of time with ElevenLabs Eleven v4.** About 3,000 lines per character are generated once, checked by ear, and shipped as audio files in the character pack. So they play instantly and work offline. Hebrew text goes in with nikud on ambiguous words, plus a pronunciation list for names and tricky words. Any line that sounds wrong is regenerated or respelled.
- **The tutor's live sentences use Eleven v4 Turbo (about 100 ms) in the same voice.** Frequent live lines are cached and promoted into the pack. ElevenLabs' older Multilingual v2 and Flash models don't support Hebrew, so they are never used.
- **Family characters get a voice too.** When a parent imports a character, they pick or design its ElevenLabs voice. A one-time script then generates that character's core lines (about 120,000 characters).
- **No voice imitates a real person.** Voices are original designs, or clones only with the speaker's written consent, in line with ElevenLabs' rules.
- **Children never hear grammar corrections.** The tutor may echo a correct form ("נָכוֹן, שְׁלוֹשָׁה כְּלָבִים!") but never says "you said it wrong".

### What the tutor may and must not do

| May | Must not |
| --- | --- |
| Ask one short question at a time: up to 10 words in Band A, 15 in B, 20 in C (the tutor limits table) | Lecture, or explain in more than two sentences |
| Diagnose from the answer and choose the next representation from the authored options | Reveal the answer before the third hint |
| Reflect the child's strategy back: "סָפַרְתָּ מִשְּׁמוֹנֶה הָלְאָה, רַעְיוֹן טוֹב" (you counted on from eight, good idea) | Ask personal questions: name, address, school, family, location, photos |
| Briefly acknowledge frustration and offer a break or an easier item | Chat off-topic, or share opinions on news, religion, politics or appearance |
| Say it is a computer helper when asked | Claim to be human, have feelings, or be a better friend than people |
| Redirect gently to the task | Create urgency or guilt ("אַל תֵּלֵךְ", don't go), or mention purchases |

**Questioning style by band:**

- **Band A, notice → do → say.** "אֵיפֹה עוֹד פַּרְפָּר?" (Where's another butterfly?) Either-or questions scaffold language: "יוֹתֵר אוֹ פָּחוֹת?" (more or fewer?)
- **Band B, predict → test → explain.** "מָה יִקְרֶה אִם נוֹסִיף עוֹד אֶחָד?" (What will happen if we add one more?), then "לָמָּה?" (why?)
- **Band C, what do we know, what do we need, how will we check?** Plus "does it always work? let's try another number".
- **Wait time, every band.** After a question the tutor waits at least 4 seconds in Band A, 5 in B and 6 in C.

### When the child speaks

1. **Recognition happens on the device.** The child taps the mic, and a Hebrew model from ivrit.ai recognises speech locally.
2. **The answer is matched against expected answers.** Matching covers every gender form, prefix and common child pronunciation.
3. **A clear answer counts exactly like a tap.** A clearly wrong answer is tagged with its misconception.
4. **An unsure match gets a confirm.** For example "שָׁלוֹשׁ?" (three?), answered with a tap or a "yes".
5. **Unclear audio is never wrong.** It gets one re-ask, then the item switches to tap. Where recognition keeps failing for a child, the mic stays: it is never taken away (owner's decision, 2026-10-27, because young children are often misheard and a missing mic would teach them voice does not work). Each question has its own repair steps and falls back to tapping; the listens are still recorded as fixed words so a parent can see how voice is going.
6. **Partial answers get one focused follow-up.** The noun alone gets "כַּמָּה?" (how many?). A hedged "maybe five?" counts as an answer, and the tutor checks it together with the child.
7. **"I don't know" or "help" opens the show-me path**, with praise for asking.
8. **Explain-back is sorted, not graded.** An on-device keyword matcher sorts the reason ("made ten", "counted on", "just knew") and reflects it back. Language quality is never scored.
9. **Off-topic chat gets one friendly redirect.** "רַעְיוֹן מְעַנְיֵן! עַכְשָׁו בּוֹאוּ נַחֲזֹר לַחִידָה" (Interesting idea! Now let's get back to the puzzle.)

End of speech to feedback targets about 1 second.

**Example, Band B, a boy working on the equals sign:**

- Tutor: "מָה צָרִיךְ לָשִׂים פֹּה כְּדֵי שֶׁיִּהְיֶה שָׁוֶה? שָׁלוֹשׁ וְעוֹד אַרְבַּע שָׁוֶה… מַשֶּׁהוּ וְעוֹד שְׁתַּיִם." (What goes here so it's equal? Three plus four equals… something plus two.)
- Child: "שֶׁבַע!" (Seven!), the "= means answer next" misconception.
- Tutor: "שָׁלוֹשׁ וְעוֹד אַרְבַּע זֶה בֶּאֱמֶת שֶׁבַע. בּוֹא נָשִׂים אֶת זֶה עַל הַמֹּאזְנַיִם וְנִרְאֶה." (Three plus four really is seven. Let's put it on the balance and see.) The scale tips.
- Tutor: "הַצַּד הַזֶּה כָּבֵד יוֹתֵר. מָה יַעֲזֹר לְאַזֵּן?" (This side is heavier. What will balance it?)
- Child: "חָמֵשׁ?" (Five?) Tutor: "נְנַסֶּה! … מְאֻזָּן! אָז 'שָׁוֶה' אוֹמֵר: שְׁנֵי הַצְּדָדִים אוֹתוֹ דָּבָר." (Let's try! … Balanced! So "equals" means both sides are the same.)

### Safety and limits

- **The model never sees the child.** The AI receives structured context only: the band, the grammatical gender, the activity goal, the last three attempts and the learner state. It never gets the name or audio.
- **Every reply is checked before it is spoken.** A validator tests length, Hebrew-only text, gender agreement, answer leaks, personal-question patterns, links and brands, and checks every word against an approved child vocabulary (see AI safety pipeline). On a failure it retries once, then uses the rule-based line.
- **Usage limits:** 20 AI turns per session and 60 per day per child, a daily spend cap and a remote kill switch.
- **Speed:** the mascot shows "thinking" within 100 ms, a recorded "hmm…" plays at 1.5 seconds, and at 3 seconds the rule-based tutor answers instead.
- **Parents can see everything the helper said.** A 30-day log in the parent area has a report button.
- **Worrying disclosures.** If a child says something worrying, the tutor says one caring line ("זֶה חָשׁוּב. כְּדַאי לְסַפֵּר לְמִישֶׁהוּ גָּדוֹל שֶׁאַתָּה סוֹמֵךְ עָלָיו", it's important to tell a grown-up you trust), does not explore it, and returns to play. Parents get an alert (see Parent controls, analytics & alerts).
- **Model: decided for now: Claude Haiku 5.5 on the owner's own Anthropic API key, for personal use. A free on-device model (e.g. Dicta-LM 3.0 1.7B) may be revisited later. AI text costs about $0.02 per child per month; ElevenLabs voice is the larger cost**.

## World, characters & story

The working name is **נִיצְנוּץ (Nitznutz, "a twinkle")**. A little star-jerboa called Nitzi lands on a tiny island with a spark of starlight in her tail. Every time the child truly understands something, the spark jumps and something grows. The name still needs an Israeli trademark search and a store-name check.

&#91;image: World map concept: the Nitznutz Islands, with a call for help and golden stars\]

| Land | Domain | Host | What grows there |
| --- | --- | --- | --- |
| הָאִי שֶׁל נִיצִי (Nitzi's Island) | Home | Nitzi | Tree-house, lighthouse, the beach where the daily bottle arrives |
| גִּבְעוֹת הַסְּפִירָה (Counting Hills) | Numbers | Nekudi the ladybug | A 1–10 staircase, built step by step |
| מִפְרַץ הַצְּבָעִים (Colour Bay) | Colours | Goni the chameleon | Paint waterfall, rainbow, mixing pools |
| יַעַר הַצּוּרוֹת (Shape Forest) | Shapes | Kubi the tortoise | Cone trees, sphere bushes, a symmetry pond |
| מְעָרַת הַחִידוֹת (Riddle Grotto) | Logic | Timi the octopus | Pattern doors, sorting shells |
| נְמַל הָרוֹבּוֹטִים (Robot Harbour) | Computer science | Tza'adon the robot | Grid docks, a crane, a lighthouse path |
| כְּפַר הַשּׁוּק (Market Village) | Math | Grandma Pnina the pelican | Market stalls, clock tower, scales, shekels |

How the world rewards learning:

- **Growth means understanding.** Each skill owns one object in its land. It shows as a pencil sketch while the child practises, and is drawn in full colour at mastery. Nothing is padlocked.
- **Calls for help are revisits.** When a learned skill is due for a check, its object raises a bell flag ("a bridge board is missing!"). Tapping it opens a 3–5 item mission in a fresh context. Nothing decays or breaks while it waits.
- **Golden stars mean it lasted.** Passing a revisit at least a week later puts a golden star on the object. It is the most prestigious thing in the world, and speed can't earn it.
- **Daily rhythm.** A bottle washes up each morning with "Today's Adventure": three stops (a revisit, something new, a playful apply-it), about 8–12 minutes. The day ends at dusk, when today's sparks rise into a constellation in the Sky Journal.

### The cast

&#91;image: Nitzi's expression sheet: the eight states every character must have, plus 10 Hebrew mouth shapes\]

| Character | Who | Role in learning |
| --- | --- | --- |
| Nitzi (she) | Star-jerboa with an apricot coat, huge ears and a golden tail-spark; curious, a little clumsy, big-sister energy | The guide and AI tutor. When she listens her ears rise and her tail glows with the child's voice, so the child can see they are heard |
| Nekudi (she) | Coral ladybug whose spots rearrange into dice and ten-frame patterns | Counting, quick recognition of amounts, the number line |
| Goni (he) | Dreamy chameleon artist in a beret | Turns into the colour being taught; models mixing |
| Kubi (he) | Slow, cosy tortoise with a mosaic shell and a cone hat | Shell tiles pop out as puzzle pieces; spatial words, symmetry |
| Timi (she) | Lilac octopus detective with a magnifying glass | Patterns, sorting, odd-one-out, if-then |
| Tza'adon (he) | Earnest little robot with a sprout on his antenna | Does exactly what he's told, so his mistakes become debugging |
| Grandma Pnina (she) | Warm market-stall pelican with glasses and an orange pouch | Story problems, money, measuring, telling time |

&#91;image: The six island hosts\]

**The Hero Squad**, an original starter pack, gives hero-loving children four kid superheroes whose powers are learning strategies:

- **Mori the Splitter** splits and joins groups (5 = 2 + 3).
- **Noga Pattern-Seer** sees the repeating unit.
- **Eitan Size-Shifter** grows and shrinks shapes; he uses a sporty wheelchair.
- **Shira Path-Painter** paints arrow paths for robots.

When a hero is the child's companion, the hero animates the "try another way" explanation, so switching method feels like a superpower moment.

### Characters as plug-in packs

- **Screens never name a character.** They ask for a role: guide, domain friend, activity helper, celebration cameo, map companion or sticker.
- **Every character meets one contract.** The same eight states (idle, talk, listen, think, encourage, celebrate, surprised, sleepy), the same 10 Hebrew mouth shapes, a 512×512 frame with a fixed baseline, and named anchor points for speech bubbles and held objects.
- **No clash with colour lessons.** Characters keep large areas away from the ten teaching colours and switch to a muted skin during Colours lessons.
- **The child picks a favourite.** After the first adventure, the child chooses a companion on Friends' Beach. It becomes the guide everywhere: it walks beside them on the map, teaches every lesson, stars in celebrations and presents trophies, and it speaks every line, including the tutor's, in its own ElevenLabs voice.
- **Your own characters arrive as lite packs.** A lite pack is seven still images on a 1024×1024 transparent canvas (idle, mouth closed, mouth open, celebrate, think, listen, encourage) plus a short manifest with the Hebrew name and a voice choice. The app animates them with breathing, squash-and-stretch hops, a moving mouth and a listening lean. This is how characters made for family use only come in. The packs are flagged personal-use, are never bundled in a build, and are blocked from any store build automatically. A parent device uploads a family pack to private family storage, and that family's devices download it with short-lived signed links.

&#91;image: The two family characters: the hero for your son and the starlight fox-dragon for your daughter, in all seven poses\]

Six more original family characters join them, each with a learning power. For your son: צוּרִי הַמְּטַפֵּס (climbs a number wall, counting in jumps), תָּמִיר הַמִּגְדָּל (measures with a growing block tower) and גַּלִּי הַמַּמְצִיאָה (a backpack that unfolds shapes). For your daughter: the sisters קֶשֶׁת אוֹרֶגֶת הַצְּבָעִים (mixes colours with ribbons) and רוֹמִי וְהַמַּצְפֵּן (a compass that points to the next step), plus גִּ'ילִי, a cheeky jelly alien who shares things fairly. All are personal-use only and selectable as the companion in the prototype.

&#91;image: Six more original family characters: three heroes for the son, two sisters and a jelly alien for the daughter, each with seven poses\]

## UX & screens

Phones run in landscape; tablets support both landscape and portrait. Every activity screen has the same layout, so a child learns it once. The guide sits on the right (the start side) with the task flowing left, Home is in the top-right corner, and the help buttons are top-left.

&#91;image: Home screen on an iPhone 16 in landscape: Today's Adventure, three islands, a call for help\]

### Main flows

1. **First launch (adult screens):** the child's name and age, how Nitzi addresses the child (masculine, feminine or plural), an avatar, voice answers on or off, and a session limit.
2. **Profile picker:** big avatar cards for siblings; tap and go. It is skipped when there is one child.
3. **Home map:** Today's Adventure bottle, the lands, Sticker Island, the child's avatar and a small grey Parents button.
4. **Lessons:** a land opens a path of 5–8 stepping stones; each activity has 5–8 items.
5. **Wind-down:** two minutes before the limit, a sun starts sinking. The current activity always finishes, a 30-second dusk ritual follows, and continuing needs the parent gate.
6. **Parent area:** behind a gate, an arithmetic question written in Hebrew words on a shuffled keypad, or a parent PIN.

### Inside an activity

- **Instruction:** Nitzi says one sentence while the scene holds still. A caption with nikud appears, and replay is always available.
- **Attempt:** tap, drag (always with a tap-then-tap alternative), trace or voice. Touch feedback lands within 50 ms.
- **Correct:** a small celebration under 0.8 seconds; the answer stays visible.
- **Not yet:** a gentle wobble. No red X, no buzzer, nothing lost.
- **Help ladder:** after two not-yets, or when the child taps "I'm not sure", the app re-voices the question, then adds a scaffold (number badges, a glowing outline), then says "let's try another way" and flips the card into a different representation.
- **Self-pacing buttons on every activity screen:** replay; "show me", where Nitzi demonstrates a similar item; and "I'm not sure", which is welcomed with "great question!"
- **No timers anywhere.** A child who sits and thinks for 40 seconds is thinking, not failing.

### Talking to Nitzi

- **Tap to talk.** Listening stops after 1.5 seconds of silence (2 seconds in Band A), with an 8-second maximum. There is no open mic and no hold-to-talk.
- **Visible states:** idle, then listening (ears up, a live level ring), thinking, and understood (the heard word appears, e.g. שֶׁבַע?).
- **Not understood is never "wrong".** First Nitzi says her ears got mixed up and asks again. Then she checks what she half-heard with a yes or no. Then the item quietly switches to tap.
- **Parents decide.** The mic appears only if a parent turned voice on during setup; the child is never asked for permission.

### Touch and gestures by band

|  | Band A (3–4) | Band B (5–6) | Band C (7–8) |
| --- | --- | --- | --- |
| Answer target, phone / tablet | 96 / 112 pt (about 15 / 21 mm) | 80 / 96 pt | 64 / 80 pt |
| Smallest control | 64 pt | 56 pt | 56 pt |
| Gap between targets, phone / tablet | 24 / 32 pt | 16 / 24 pt | 12 / 16 pt |
| Choices on screen | Up to 3 | Up to 4 | Up to 5 |
| Gestures | Tap, drag, trace, 3-step programs | Programs up to 8 steps | Loops, number keypad, carousels |

No band uses double-tap, pinch or tilt, and Band A never needs a long-press. The app ignores a repeat tap within 300 ms and a palm resting on the edge. Taps on scenery trigger a fun reaction, never a "wrong".

### Phones and tablets

| Screen | Phone, landscape | Tablet, landscape | Tablet, portrait |
| --- | --- | --- | --- |
| World map | Pans sideways, about 2.5 lands visible | Nearly the whole archipelago | Scrolls vertically |
| Activity | Guide rail plus stage | Guide rail, stage and a toolbox of manipulatives (ten-frame, number line) | Guide strip on top, stage, tray at the bottom |
| Robot coding | 5×3 grid | 6×5 grid, program and palette visible | Grid on top, program below |

Reference sizes are an iPhone 16 (852×393 pt, with 59 pt side insets for the camera), an iPhone SE (667×375 pt, the smallest supported), and an iPad at 1180×820 and 820×1180 pt.

### Right-to-left rules

- **Mirrored:** navigation, the progress trail (fills right to left), the lesson path, story sequences, pattern rows and the robot's program strip.
- **Never mirrored:** the number line (0 on the left), equations (3 + 4 = 7), column arithmetic, clocks and the robot's movement arrows (← always means left on screen).

## Parent controls, analytics & alerts

Parents get a full control centre behind the parental gate. It shows how each child is really learning, lets them set the rules, and alerts them when something needs their attention. On a second phone the same parent account receives alerts as push notifications, synced through Supabase.

### Analytics per child

| View | What it shows |
| --- | --- |
| This week | Minutes per day (bar chart with values), sessions, adventures completed, the newest thing built on the island |
| Understanding by domain | Every skill as a plain-Hebrew "can do" sentence with its status: understood, practising, needs a revisit, gap found. Each one not yet understood says what the app is doing about it |
| Growth over time | Skills reaching lasting understanding over the last 8 weeks (a line), and revisit checks passed |
| What helped | The explanation styles that unlock skills for this child, e.g. "learns well with objects to move" |
| Misconceptions | Misunderstandings found, being repaired and resolved, each with a five-minute activity to do at home |
| Learning habits | Asked for help when unsure, explained how they knew, fixed the robot's bugs. All framed as strengths |
| Tutor log | Everything the AI helper said in the last 30 days, with a report button |

Speed, time per question and raw error counts are never shown, so parents aren't nudged to push for speed.

### Alerts

| Alert | Detected by | What the parent sees |
| --- | --- | --- |
| Played past the limit or during rest hours | Session clock and schedule | When it happened, and a suggestion to adjust the schedule or talk about it |
| Trying to get into the parent area | 3 or more failed parent-gate attempts | Time and count; a suggestion to set a PIN |
| Guessing to farm rewards | Very fast answers across options and many retries in a row | Which activity; the app has already slowed rewards and switched to explanation mode |
| Frustration | Three or more errors in a row with quitting, or rapid random tapping | Which skill; the app has switched explanation style; a calm home activity to try |
| Inappropriate words said to the tutor | On-device word lists on the recognised words | The line as said, privately to the parent; the tutor only redirected gently |
| A worrying disclosure | On-device word lists on the recognised words | A gentle notice with the line and a suggestion to talk with the child. The tutor gave one caring line and pointed to a trusted adult |
| Long absence or a sudden drop in progress | Activity history | Optional weekly note, never sent to the child |

- Each alert carries a severity (info, attention, important) and a one-line "what to do".
- Parents choose where alerts go: in the app, and as a push with no content to their own phone.
- The child is never told they were "reported", and the app never scolds.
- Detection runs on the device. Only the alert itself syncs to the parent's account.

### Controls

- **Time:** a daily limit, a weekly schedule, rest hours, and a bedtime lock, with the gentle wind-down kept.
- **Content:** a band per domain with the recommendation shown, hidden domains, and nikud level.
- **Characters:** which characters each child may choose, and importing family characters.
- **Voice and AI:** voice answers on or off, AI tutor on or off, and the address form (masculine, feminine, plural).
- **Rewards:** turn ceremonies on or off, and attach real-world rewards to trophies.
- **Data:** export a report, delete a child's data.

**Mockups.** The progress view shows weekly minutes against the limit, skills by status per domain, understanding versus retention over 8 weeks, what helped, and misconceptions found and fixed.

&#91;image: Parent analytics on iPad: weekly minutes against the limit, skills by status, 8-week growth, what helped, misconceptions, habits\]

The alerts view ranks each alert by severity with a plain "what to do" line; the controls sit beside it.

&#91;image: Parent alerts and controls on iPad: six alerts with severity and next steps, time limits, bedtime lock, voice and AI, allowed characters, prizes, alert channels\]

## Awards, prizes & the Trophy Hall

Children earn trophies, medals and prizes as they learn, and visit them in the Trophy Hall (הֵיכַל הַגְּבִיעִים), a glowing hall on their home island. Every prize is earned through learning, shown in advance with how to earn it, and never random, bought or taken away.

| Award | How it's earned | How often (rough) |
| --- | --- | --- |
| Bronze land trophy | First skills built in a land | In the first weeks |
| Silver land trophy | Half of a land's skills reach lasting understanding | Every few weeks |
| Gold land trophy | Every skill in a land reaches lasting understanding | A big moment, a few times a year |
| Habit medals | Asking "I'm not sure", explaining how you knew, fixing the robot's bug 5 times, a full weekly garden | About weekly |
| Companion prizes | Costumes and accessories for the chosen character (a new cape colour, ribbon colours), a new dance | With each trophy |
| Island decorations and songs | Milestones such as 10 skills understood | Every week or two |
| Stickers | Every completed lesson | Every session |

- **The ceremony.** The companion presents each new trophy: the lights dim, a spotlight, the trophy spins in, confetti, and the companion's own celebration line in its voice. Trophies use the biggest celebration tier, so they stay special.
- **The hall.** Shelves by land, locked trophies as soft silhouettes that say how to earn them, and a counter of golden stars. Tapping a trophy replays its moment: what the child learned, in one line and an icon. The companion can wear any earned costume.
- **Real-world rewards.** A parent can attach a real promise to a trophy ("כשתזכו בגביע הזהב, נלך לגלידה"). It appears as a ribbon on that trophy, and the parent is notified when it's earned.
- **Healthy by design.** No loot boxes, no streak loss, no prizes for speed or for playing longer. Rewards follow understanding that lasts, which is also what parents see.

**Mockups.** The Trophy Hall has one shelf per island, bronze to gold, with locked trophies as soft silhouettes showing progress. A parent's real-world prize hangs as a ribbon on the trophy it is tied to.

&#91;image: Trophy Hall on a phone: shelves per island, a selected silver trophy with its memory card, the companion on a pedestal\]

&#91;image: Trophy ceremony on a phone: spotlight, spinning trophy, confetti, the companion celebrating and a new prize for the companion\]

&#91;image: Trophy Hall on iPad: all six islands, habit medals, prizes for the companion and a parent ribbon\]

## Visual design system, animation & sound

The look is "sunlit paper cut-outs": flat rounded shapes with one shadow tone, and a soft darker lip on everything you can press, all on warm cream paper. Every colour, size and timing lives in one design-values file that both the mockups and the Flutter app read, so the built app matches the designs.

&#91;image: Design system board: palette, type, buttons, answer cards, mic states, touch sizes\]

### Colour

- **Core palette:** cream background #FFF6E8, ink text #2B2350 (contrast 13.4:1), spark gold #FFC83D, sunset orange #FF8A3D for the main button, sea teal #1A9E9A for listening.
- **Domains** each get a colour *and* a glyph: Numbers coral with a dot trio, Colours magenta with a drop, Shapes green with a triangle, Logic violet with a puzzle piece, Computer science blue with chevrons, Math amber with a plus.
- **Feedback avoids red versus green.** Correct is a gold glow and a check mark, not yet is a wobble and a lilac ring, and a hint is a sky-blue halo.
- **Colour lessons stay accessible.** About 1 in 12 boys has a colour-vision deficiency.
  - Every swatch says its colour name when tapped.
  - The ten teaching colours differ in lightness, not just hue.
  - Optional symbols mark each colour (red has a heart, green a leaf, blue a drop).
  - If a child's mistakes match a colour-blind pattern, the symbols switch on and parents get a gentle, non-diagnostic note.

### Type

| Role | Font | Sizes, phone / tablet |
| --- | --- | --- |
| Titles, wordmark, celebration words | Secular One | Band A 32 / 44 pt, B 30 / 40, C 28 / 36 |
| Captions with nikud, numbers, buttons, parent screens | Heebo, weights 400–800 | Captions: Band A 26 / 32 pt, B 22 / 28, C 20 / 24 |

Rubik and Fredoka are excluded because their vowel marks rendered misplaced in testing. Text with nikud gets a line height of 1.7 so marks never collide. Parents of Band C children can switch to partial nikud.

### Motion

- **Feel:** squash and stretch on everything alive, a crouch before every hop, and ears and tail that lag a few frames behind the body.
- **Pace by band:** base transitions of 450 ms in Band A, 350 ms in B and 280 ms in C, with more bounce for younger children.
- **One thing moves at a time.** Background motion drops while Nitzi speaks.
- **Safety:** the app respects the system's Reduce Motion setting, and nothing flashes faster than 3 times a second.

| Celebration | When | Length | What happens |
| --- | --- | --- | --- |
| Small | Each correct item | Up to 0.8 s | Check badge, sparkle, a spark flies to the progress trail |
| Medium | End of an activity | 2–3 s | Nitzi hops, the host joins, a sticker is revealed |
| Big | A skill is mastered | 5–7 s, skippable after 1.5 s | The camera flies to the land and the new object draws itself in; about once every 3–5 sessions, so it stays special |

### Sound, voice and touch feedback

- **Music:** warm acoustic instruments (ukulele, marimba, glockenspiel) with a light Mediterranean colour. Each land has its own lead instrument, and the wind-down uses a lullaby. During activities the music drops to a quiet bed.
- **Sound cues:** a wooden "tok" for taps, a rising chime for correct (six variations), a soft "boing" for not yet (never a buzzer), and a twinkle for hints.
- **Mixing:** speech always lowers the music by 14 dB, and music stops while the mic listens.
- **Voices:** every character has its own ElevenLabs voice. Band A lines are generated at a slower pace, and every core line is checked by ear before it ships.
- **Vibration:** a light tap on pick-up and snap, a success buzz on correct, and nothing on not yet.

## Technical architecture

One Flutter app serves iOS and Android phones and tablets. Everything a child does works offline. Activities, characters and the curriculum are data, so the content team ships new material without engineers or an app release.

| Concern | Choice | Why it fits this app |
| --- | --- | --- |
| App framework | Flutter 3.47, iOS 16+ and Android 8.0 (API 26)+ | One renderer draws every pixel, so Hebrew right-to-left layout, nikud and animation look identical on a cheap Android tablet and an iPad |
| Characters | Rive state machines with Data Binding | Lip-sync, moods and gaze through one contract that every character follows |
| Game-like activities | Flame, only where a game loop is needed | Robot grid, catching and physics-sorting games |
| Audio | flutter\_soloud | Instant sound; separate voice, effects, music and tutor channels; music ducks under speech |
| Speech recognition | On-device Hebrew model from ivrit.ai, run with sherpa-onnx | No child audio leaves the phone by default |
| Local data | Drift (SQLite) | The learner model and event log live on the device |
| Content authoring | JSON files in Git with a validation script and an in-app preview mode; Payload CMS only for a public release | You and Claude write activities with nikud and preview them on the real device |
| AI tutor | Claude Haiku 5.5 behind the Supabase gateway functions; a rule-based tutor offline | Fast, cheap, returns structured JSON |
| Backend | Supabase in Frankfurt (database, sign-in, gateway functions, private storage) and Cloudflare R2 for signed packs | EU hosting; no third-party analytics or ad SDKs |

React Native (Expo) was the runner-up. It lost on right-to-left consistency, game-loop maturity and pixel testing. Unity lost on Hebrew text and the parent screens.

&#91;embedded content: app architecture · 6 device layers, 4 cloud services\]

Each device layer uses only the layers below it. The learning engine has no UI code, so the same engine also runs in the educators' preview and the test simulator.

### How the main pieces work

- **Activities are data.** About 10–12 engineered templates (count-and-choose, drag-to-sort, pattern, robot path, number line and so on) are driven by JSON files. Every wrong option, tap pattern and expected wrong spoken answer can carry a misconception tag that feeds the learning engine.
- **Content packs.** Signed packs download from the CDN and update only changed files. The store download stays under 100 MB, with about 2 hours of play bundled.
- **Hebrew engineering.** A shared `hebrew_text` package stores each noun with its gender. It produces correct agreement (שְׁלוֹשָׁה בָּלוֹנִים but שָׁלוֹשׁ בֻּבּוֹת), captions, the speech-recognition answer lists and content checks.
- **Direction rules.** Maths always renders left-to-right in its own tiles. Robot arrows, number lines and clocks never mirror; back arrows and progress bars do.
- **Fonts and nikud.** Nikud is written into content with a diacritiser and approved by a person, never generated at runtime. Every font must pass a nikud stress test; Rubik and Fredoka fail for vowel-marked text.
- **Voice in.** The app matches what the child said against the few expected answers, including gender forms, prefixes and child pronunciations such as שָׁלוֹס for שָׁלוֹשׁ. An uncertain result triggers a quick "three?" confirm; anything below that becomes "say it again or tap", never a wrong answer. Target: feedback within 1 second of the child finishing.
- **Voice out.** Every character's core lines are generated ahead of time with ElevenLabs Eleven v4 and shipped in its pack. The tutor's live lines use Eleven v4 Turbo in the same voice, through the gateway.
- **AI tutor.** It is not an open chat. The device sends structured context with no name and no audio. The tutor returns the mascot's emotion, one or two Hebrew sentences in the child's grammatical gender, a hint level, the next step and which explanation style to switch to. A checker blocks answer leaks, wrong gender forms and off-topic text, and anything slower than 3 seconds falls back to the rule-based tutor. Estimated cost: about $0.02 per child per month for the model, plus under $0.25 for live voice.
- **Character packs.** Screens ask for a role slot (guide, helper, celebration, map companion, sticker), and a resolver fills it with the child's chosen companion. Full packs use Rive; lite packs are owner-supplied images the engine animates. Adding a full character takes about 14–22 person-days with no engineering; a lite pack takes 1–2 hours once the images exist.
- **Phones and tablets.** Tablets must now support both orientations: Android 16 ignores orientation locks on screens 600 dp and wider, and the iOS 27 SDK drops the full-screen opt-out. Templates therefore come in wide and tall variants. Three performance tiers keep low-end Android at 60 fps during interaction.
- **Quality gates.**
  - A simulator of 10,000 synthetic children with planted gaps must find those gaps before any change to the learning rules ships.
  - Golden screenshots in right-to-left with real fonts.
  - A consented recording set of about 300 Israeli children's answers. Voice must be right at least 97% of the times it accepts an answer.

## Build specification (family v1)

Build v1 as a local-first Flutter app with one small Supabase backend. Where this section and the technical architecture above differ, this section wins for v1; the rest waits for a public release.

### What v1 uses, and what waits

| Concern | v1: build now | Later: public release only |
| --- | --- | --- |
| Content authoring | JSON files in Git, checked by a validation script; a hidden preview mode in the app | Payload CMS with educator preview |
| Server code | Supabase Edge Functions (TypeScript on Deno), pinned to Frankfurt | Hono containers on Fly.io or AWS |
| Voices | ElevenLabs Eleven v4 core lines pre-generated per character; v4 Turbo for live tutor lines | Same |
| AI tutor | Claude Haiku 5.5 through the tutor function; RuleTutor offline and as fallback | Re-evaluate models. Gemini is excluded: its terms bar apps for under-18s |
| Speech recognition | ivrit.ai Zipformer on the device via sherpa-onnx; the model mirrored on R2 with a pinned hash | A child-adapted model, with separate consent |
| Accounts | One family account. The parent's phone signs in with Apple, Google or an email code; child devices join with a pairing code; children never log in | Several guardians per family |
| Crash reports and analytics | None. An on-device error log the parent can export; parent analytics computed on the device | Self-hosted crash reporting in the EU; allow-listed first-party events |
| Purchases | None | RevenueCat, parent area only |
| Alerts | In the parent area, plus a push with no content to parent devices only | Same, plus an optional email summary |

### Repository layout

- `app/`: the Flutter app, with the child space and parent area in separate feature folders, and `dev` and `release` flavours.
- `packages/`: `engine` (learning engine, no UI), `hebrew_text`, `answer_matcher`, `gateway_client`. (Built in M2: the content schemas and validator live in `app/lib/content/`, shared by the app and the pack builder, so they cannot disagree; there is no `content_schema` package.)
- `content/`: the sources of packs (`content/starter/`, built in M2) and the generated JSON Schema files (`content/schemas/`, from the same definitions the validator uses). Skills, misconceptions, activities and lessons are JSON files; lines and the child vocabulary lexicon follow.
- `supabase/`: migrations, policies, Edge Functions with a shared `auth.ts`, and their tests.
- `tools/`: `validate_content`, `tutor_eval`; for speech (M5) `make-m5-model.ps1` and `run-asr-eval.ps1` (with `app/tool/asr_eval.dart`). `voice_gen` lives in `app/tool/voice_gen.dart` (built in M4: `plan`, `mock`, `audition`, `generate --confirm-chars N`; voice ids and the model id in `content/voices.json`; the key only from `ELEVENLABS_API_KEY`); `tools/make-m4-device-packs.ps1` builds the family character packs and free test voices for a phone. The pack builder is `app/tool/pack_builder.dart` (built in M2: `keygen`, `build`, `verify`, `inspect`, `schema`, `damage`); `content-publish` was built in M6 (`pack_builder publish`); hosting packs on R2 comes with M9. `app/tool/tutor_prewarm.dart` (M6: `plan`, `make --confirm-lines N`, `measure`) fills the server's line cache ahead of time and measures the model and voice times; secret from `NITZNUTZ_PUBLISH_SECRET` only.

### Content packs (as built in M2)

- **File.** `<id>-<version>.nnpack`: a canonical, stored-only zip written and read by the app's own code (`zip_store.dart`): `manifest.json`, `manifest.sig` and flat files; no compression, encryption, zip64, extra fields, comments, folders or unsafe names; entries sorted; one fixed time. The reader re-writes what it parsed and compares it with the input byte for byte, so no byte of the container can change unnoticed. Limits: 402 entries, 64 MB.
- **Signature.** Ed25519 over the label `nitznutz-pack-v1` + a newline + the exact bytes of `manifest.json`, checked with the public key built into the app (`assets/pack_signing_public_key.txt`). The private key is made once by `pack_builder keygen`, written outside the repo (`%USERPROFILE%
itznutz-secretspack-signing.key`; the command refuses any path inside a git working tree) and kept in the owner's password manager.
- **Order of checks (`verifyPack`, one function for the app and the builder).** zip container, then signature, then the manifest is read, then every file's size and SHA-256 against it, and only then are the other JSON files read and checked (schemas, then cross-file rules: every reference exists, tags only from the pack's own catalogue, Hebrew house rules, template and version rules). A pack that needs a newer app or template is proven genuine but kept unread and **hidden**.
- **Install.** Files go to a temporary folder and are moved to `packs/<id>/<version>/` in the no-backup folder in one step, then recorded in `installed_pack`; failure removes the new files and leaves the old pack. Versions only go up; the same version with other bytes is refused; the same bytes do nothing. An installed pack is proven again whenever it is loaded.
- **Documents.** `activity.<id>.json`, `lesson.<id>.json`, `skill.<id>.json`, `misconception.<tag>.json`, plus pictures (SVG) and, from M4, recordings. Templates in M2: `tap_answer`, `count_tap`, `give_n` (all version 1.0). Every document is closed (an unknown field is refused). Hebrew written by an AI or an engineer carries `"review": "needs-editor"`.
- **Local data.** Database version 2 adds `installed_pack` and `attempt` (ids, numbers and fixed words only: activity id and revision, pack and template versions, result, hint level, misconception tag, option chosen, duration).

### The learning engine (as built in M3)

- **Where.** `app/lib/engine/`, pure Dart: it imports only `dart:math` and itself (a test enforces it, and forbids the clock and unseeded random generators). `app/lib/content/engine_adapter.dart` turns pack documents and `attempt` rows into the engine's own types. There is no `packages/engine` yet; the folder can be moved without changing a line.
- **Derived state is never stored.** Skill, memory, misconception, gap and representation state is the result of replaying `attempt` rows in time order (`Engine.replay`); the engine reads no clock and no random source of its own. The only new tables are `session` and `attempt.session_id` (database version 3); a lesson visit is one session. Database version 4 (M4) adds `profile.companion_id`, the id of the companion the child chose (null means Nitzi). Database version 5 (M5) adds `attempt.input` (`tap` or `voice`) and `voice_listen` (fixed words only, to see whether voice works for a child).
- **Parameters.** `EngineParams` holds every number (starting values from curriculum.md section 10 and the tables above), with JSON in and out so a pack can carry a tuned copy later.
- **Probes.** A search for a gap starts after 2 wrong answers in a row (or 3 "not sure", or an active misconception, or a long run of low estimates) on a skill that has prerequisites. It probes at most 3 skills (depth 3, up to 3 levels below), the most suspect first; among near-equal suspects the lowest. A probe passes after enough right answers that guessing alone would pass it less than 2 times in 100 (four at three choices, one for an open item) and fails after two wrong answers (one for an open item); a pass clears everything below that skill. Open probe items (give, drag, trace) are strongly preferred: authors must provide at least one per skill that can be a gap. If nothing below is missing, no gap is recorded.
- **Acceptance (M3).** In 1,000 invented children with a planted gap one to three levels down and history on 80% of skills, the gap is named exactly within 3 probes in 96.2% of cases (91.0% with history on half the skills, 51.3% with none); two slips in a row make a false gap in 1.5%. `dart run tool/simulate.dart` prints the table.
- **Session builder.** Warm-up, repair (at most 25%, probes included), focus (about two skills, 4 to 5 items each), revisit checks (due by memory, a different item of the variant group), delight (neutral for the estimates), the stuck rule (3 wrong in a row, or 2 worked examples in a row), and an end on an easy success from a skill at 0.85 or more.

### Devices, roles and pairing

- **Two roles.** Every enrolled device is either `parent` or `child`. The family's first device, your phone, signs in with Apple, Google or an email code and enrols as `parent`.
- **Child devices join with a code.** On a parent device, "add a child device" shows a 6-digit code: single use, valid 10 minutes, stored hashed. The child device enters it, and `device-pair` returns a one-time sign-in token for the family account, made on the server as a magic-link token hash, which the device exchanges for a session. No Apple or Google sign-in ever happens on a child's device, so a child's own Apple ID or Family Link account is never involved.
- **What a child device may do:** call the tutor, sync learning and settings events, create alerts, and download family packs. Reading alerts or the tutor log, deleting data, revoking or approving devices, and registering characters all need a parent device.
- **A PIN on every device with a child profile.** The arithmetic gate is only the first step in front of it.
- **Enrolment with attestation.** `enroll-challenge` gives a 32-byte challenge, single use, valid 5 minutes. The device makes its hardware key and proves it:
  - **iOS:** App Attest over SHA-256(challenge ‖ the signing key's SPKI bytes), so the attestation is bound to the key that signs requests. The server checks the attestation's certificate chain to Apple's App Attest root, that the app id hash is the SHA-256 of team id plus bundle id, the `appattest` environment, and the challenge.
  - **Android:** Key Attestation of the P-256 key itself, with the challenge set as its attestation challenge. The server checks the chain to Google's hardware attestation root, a security level of TEE or StrongBox, the package name, the signing certificate digest, and the challenge. This works for sideloaded builds and needs no Google API.
  - **Emulators and simulators** can enrol only through a `dev_device_allowlist`, in the `dev` flavour. The server reads the allowlist only when the function setting `ALLOW_DEV_ENROLMENT=true`, which is on in the local stack and off in the cloud project.
- **Device lifecycle.** At most 6 active devices; enrolment offers "replace this device", which revokes the old one; devices unseen for 90 days are revoked automatically. On a fresh install, the app deletes any Keychain items left from an earlier install before doing anything else, because iOS keeps them after an uninstall.

### Signed requests: the exact format

- **What is signed:** these lines joined by a newline: `v1`, `POST`, `/<function-name>`, the time in Unix milliseconds, a UUIDv4 nonce, the base64url SHA-256 of the body, and the device id.
- **How:** ECDSA P-256 with SHA-256. Devices send the DER signature their platform produces; the server converts it to raw r and s before verifying with WebCrypto. Public keys are stored as SPKI DER; iOS converts its raw key before sending.
- **Server checks:** a clock gap over 60 seconds is refused with the server's time, so the client keeps an offset and retries once; each nonce goes into `request_nonce` with a unique key on device and nonce, and a repeat is refused; nonces are purged after 10 minutes.
- **Build detail (M0):** the four headers are `x-device-id`, `x-timestamp`, `x-nonce` and `x-signature` (base64url DER). Every field is validated before the string is joined (function name `[a-z][a-z0-9-]*`, lowercase UUIDs, a 43-character body hash), so no field can carry a newline. The three calls made before a device exists (`enroll-challenge`, `device-enroll`, `device-pair`) are signed with the new key and the nil device id `00000000-0000-0000-0000-000000000000`; the server verifies them against the public key in the request body or the challenge row, never against a stored device. The server checks the point is on the P-256 curve itself, because Deno's WebCrypto accepts an off-curve SPKI. A bad signature, an unknown or revoked device and a repeated nonce all return the same public code `unauthorized`; only `clock_skew` (with the server time) is distinct. Shared vectors live in `testvectors/signed-request.json`.
- **Build detail (M0), challenges and codes:** `enroll-challenge` takes a body `{"purpose": "enroll" | "pair"}` (PLAN said none). `enroll` needs a session token issued under 10 minutes ago and is limited to 10 an hour per user; `pair` needs no session (the child device has none yet) and is limited to 20 an hour per IP address, counted under a keyed hash so no raw address is stored. The call is not device-signed, because no key is trusted yet; only `device-enroll` and `device-pair` are self-signed. Challenges are issued for 4 minutes and pairing codes for 9, one minute under the database caps, so a small clock difference between the function and the database cannot break the insert. Pairing codes are stored as an HMAC-SHA-256 under a server secret, because a 6-digit space is trivial to brute-force from a plain hash.
- **Build detail (M0), Android attestation and enrolment:** the server trusts Google's two published attestation roots (the RSA root and the ECDSA "Key Attestation CA1"), stored in `supabase/functions/_shared/trust/google_roots.ts` with their fingerprints and fetched by the `fetch-trust-roots` workflow over TLS. It checks every certificate's dates and signature, (links that the Edge runtime's WebCrypto refuses, namely a P-384 key signing with SHA-256, which Google's chains contain, are checked with the audited `@noble/curves` library through `_shared/ecdsa.ts` and `attest/cert_sig.ts`; found on the first real phone) that each issuer is a CA, the leaf key equals the submitted key, the challenge, a hardware security level (TEE or StrongBox, with matching KeyMint level), a P-256 signing key generated on the device, a locked and verified bootloader (switchable with the config row `android_require_verified_boot=false` for lab phones), and that the app's package name and signing-certificate SHA-256 are in the config row `android_allowed_apps` (`[{"package_name": ..., "cert_sha256": [...]}]`; an empty or missing list refuses everything). **Not yet checked:** Google's revocation list of attestation keys; to add before any build leaves the family. `device-enroll` is self-signed with the new key and the nil device id, needs a session issued under 10 minutes ago, burns its challenge on any attempt, and creates the family and guardian row on a user's first device. `ALLOW_DEV_ENROLMENT` and the dev allowlist work as described above; the production setting is absent.
- **Build detail (M0), `device-pair` and the child's sign-in:** after the code, the challenge and the attestation are all checked, the gateway looks up the family's guardian account and asks the Auth admin API for a magic-link token (`GET /auth/v1/admin/users/{id}`, then `POST /auth/v1/admin/generate_link` with `type: magiclink`), keyed by our own secret `AUTH_ADMIN_KEY` (a Supabase secret key, never the platform default). It returns only the `hashed_token`; the child device exchanges it with `POST /auth/v1/verify` (`type: "magiclink"`, `token_hash`). A wrong code is counted before anything else is checked: 5 wrong tries kill the challenge, 20 tries an hour per IP address, and 100 attempts an hour for the whole service.
- **Build detail (M0), gateway and keys:** every function runs with `verify_jwt = false` in `supabase/config.toml`, because the app sends the new publishable key (not a JWT) as `apikey`; each function verifies the session token itself against the project's JWKS (ES256/RS256 only, audience `authenticated`, non-anonymous). The `verify_jwt` experiment on the live project is still to run (task C8). Parent sign-in is by 6-digit email code (`/auth/v1/otp` with `create_user: false`, then `/auth/v1/verify` with `type: email`); for this the Supabase *Magic Link* email template must contain `{{ .Token }}`, otherwise only a link is sent. The gateway reaches Postgres as the least-privilege role `app_gateway` over the session pooler.
- **Build detail (M0), Android app:** application id `app.nitznutz.nitznutz` (the `dev` flavour adds `.dev`; this is hard to change after install). `minSdk` 26, `targetSdk` 36, `allowBackup=false` with empty backup and data-extraction rules, cleartext traffic off. The signing key is made by `DeviceKeyChannel.kt` (channel `app.nitznutz/device_key`): a non-exportable P-256 key in the Android Keystore, StrongBox first and then TEE, with the server's challenge as the attestation challenge; only the public key, the certificate chain and DER signatures cross the channel. The Dart side has one network door (`NetGate`, which refuses any host not in `app/network_hosts.json`) used by `GatewayClient` (signed calls, one retry on `clock_skew` using the server's time) and a hand-written `AuthClient`; the `supabase_flutter` SDK is not used. Build settings come from `--dart-define-from-file=config/dev.local.json` (git-ignored); the app refuses to start with a secret key. Enrolling a phone that is already enrolled needs an explicit "replace this device", so the old record is revoked rather than orphaned.
- **Build detail (M7a), the parent area on the device:** `ParentRules` (one JSON setting `parent_rules`, clamped when read) holds the daily limit by band (default 20, 30, 40 minutes; 5 to 180; a child may have her own), rest hours (default 19:30 to 06:30, may wrap midnight), weekly windows per weekday and `lockWhenDone`. `judgeTime` (rest hours, then the schedule, then the limit) says whether a child may start; the map shows a calm rest scene when locked, and a lesson ends after the current activity with a goodbye card (session end reason `limit`, not finished) when time passes. Play time is counted from sessions, one session at most 90 minutes. The progress view (`buildProgress`) is a pure function of the engine's replay: it never stores or shows speed, time per question or counts of mistakes. Alerts are found on the device (`scanHistory` plus an immediate check of the recogniser's words) and kept in the local table `alerts` (database version 6) for 30 days, one per key; the words of a child are kept only with the parent's "keep the words" switch (default on). Word lists are data in `lib/speech/alert_words.dart` (`needs-editor`). Strings of the parent area are gender-neutral.
- **Build detail (M8b), showing and giving:** medals are award keys `medal:<id>` (live: `brave-asker`, five "not sure" or "show me" taps; `try-again`, three right answers after a mistake on the same activity; data only: `explainer`, `bug-fixer`); island decorations are `deco:10`, `deco:20`, `deco:30` for that many skills understood for good. A ceremony (`CeremonyScreen`, drawn in code, skippable, calm with reduce motion) follows a lesson or revisit mission for the highest unseen trophy, else a medal, one at a time; the rest wait in the Trophy Hall (`TrophyHall`: trophies by land, medals and decorations, prizes) with a soft glow. The companion's prize is a scarf in a colour set (`honey`, `sky`, `rose`: one for each tier of trophy), chosen by the child and kept as `outfit_id` on the child profile (database version 9; `child-put` and `sync-pull` carry it; `none` is a value). Family settings gain `ceremonies` (boolean) and `ribbons` (child id, then trophy key, then up to 60 characters of the parent's words; at most 30 in all, no links; the settings document may be 8 KB). The alert category `ribbonEarned` holds the trophy key in `detail` and never the words. `app.delete_child` removes the child's promises from the settings and counts a new version. The ceremony voice lines are `vo:core.ceremony.bronze|silver|gold|medal`, not recorded yet. Pack 0.3.0 adds optional `worldObject` and `childLine` to a skill and `homeActivity` to a misconception (the app reads them already); a publish of a newer pack version carries the approved tutor lines over to the items whose revision did not change (the server keeps only the current version, and the old version's other lines go with it).
- **Build detail (M8a), rewards and the world:** `rewards` table (database version 8; child, award key, kind, time, seen, sync fields; unique per child and key), keys `sticker:<lesson>:<n>`, `star:<skill>`, `trophy:<land>:<tier>`. The rules (`reward_rules.dart`) are pure and see only each skill's lasting-understanding time and the finished lessons. Land trophies need at least 3 skills in the land; bronze = the first two skills at lasting understanding, silver = half (never fewer than bronze), gold = all; fresh mastery earns none (this changes the table above: "first skills built" means lasting). History that already exists is given quietly and only the highest trophy is presented. Rewards sync as events of type `reward` (a kind and a key, nothing else; the server pattern-checks the key). The map's land signs open an island with one object per skill (sketch, colour, colour with fruit and a golden star, plus a bell flag and a dry leaf when a check is due); a bell opens a revisit mission of 3 to 5 items (`mission:<skill>` visits). The daily bottle and the Sky Journal are not in M8.
- **Build detail (M7b), sync and the family:** tables `child_profile` (id, nickname, avatar, companion, address form, age band: the nickname is the one personal text on the server), `event` (`seq` is the cursor; type `attempt` or `session`; payload of ids, numbers and fixed words, at most 2 KB), `alert` (30 days; the child's words only for `inappropriateWords` and `disclosure`, and only when the parent keeps them), `push_token`, `family_settings` (one document, `version` counts the writes), `deleted_child` (tombstones, kept a year); `app.delete_child(family, child)` removes every row of a child in one transaction. Functions: `child-put` and `child-delete` (parent), `sync-push` (at most 40 events, 600 calls an hour a device) and `sync-pull` (after, limit up to 100; the answer carries the family's children and tombstones), `alert-create` (also sends the content-free push to the family's other parent phones), `alert-list`, `alert-read`, `push-token-register`, `settings-get` (every device) and `settings-put` (parent; whitelisted keys only: limits, rest hours, schedule, lock, `keepWords`, `aiHelper`), `tutor-log`. The app's local database is version 7: each answer and visit says when it was sent, an event from another device carries its event id (`uuid v5` of device, kind and row, so a retry is the same event) and a visit its name there (`device:number`). `SyncEngine` order: parent devices save children, send answers and visits and alerts, pull the family (apply tombstones by deleting local data, take new children, apply other devices' events, never its own), a parent device takes in alerts, then the rules (a phone that never synced takes the family's rules before it may send any). Removing a child deletes it here at once and is retried on the server until it is made. The push is Firebase Cloud Messaging with the secret `FCM_SERVICE_ACCOUNT`; its body is the fixed phrase and nothing else. App side: `firebase_core` and `firebase_messaging` with the library's own registration off (manifest); the parent area switch "התראות בטלפון הזה" asks for permission and registers the address (`push-token-register`; `push-token-remove` when switched off); a tap on the notification opens the parent gate at once (the phone remembers the tap natively, `PushTap.kt`; the app shows a loading screen, never the child picker, until the gate is over it); the Firebase client files are git-ignored (`app/android/app/src/{dev,prod}/google-services.json`) and the Gradle plugin is applied only when one exists; the hosts `firebaseinstallations.googleapis.com`, `fcmregistrations.googleapis.com` and `mtalk.google.com` are listed for `parent` only. **Backups:** the login `backup_reader` (read-only, `app` schema only) and `.github/workflows/backup.yml` (weekly `pg_dump`, encrypted with a public age key, kept as an artifact for 28 days; the private key is only with the owner).
- **Build detail (M6), the tutor:** the gateway calls Anthropic (`claude-haiku-5-5`) and ElevenLabs with plain `fetch`, no SDK; the keys are the Supabase secrets `ANTHROPIC_API_KEY` and `ELEVENLABS_API_KEY`, the publish secret is `CONTENT_PUBLISH_SECRET`. Config rows (all optional, defaults in `_shared/tutor_core.ts`): `tutor_enabled` and `live_voice_enabled` (off unless `true`), `tutor_session_cap` 20, `tutor_day_cap` 60, `tutor_prefetch_cap` 40, `tutor_cost_cap_micro` 500000 (0.50 USD a family a day), `elevenlabs_model_id` (no default; no voice without it), `tutor_price_micro` (`in_per_mtok`, `out_per_mtok`, `voice_per_1k_chars`, in millionths of a dollar; placeholders until checked). New tables `content_pack`, `content_item`, `misconception`, `family_character`, `tutor_log`, `tutor_cache`; caps in one atomic function `app.tutor_take`. New functions: `content-publish` and `tutor-prewarm` (publish secret, no device) and `tutor-turn` (device, parent or child role; body of ids, numbers and enums: `child_ref`, `session_ref`, `pack_id`, `pack_version`, `item_id`, `character_id`, `band`, `address_form`, `hint_level`, `mode` = `turn` or `prefetch`, `mistakes` up to 3, `attempts` up to 3; the answer is `results[]` of a line with audio or a RuleTutor reason, always HTTP 200 for failures of the helper). Cache key: pack and version, item, mistake class, hint level, band, address form, guide, prompt version and validator version; only lines that passed the ten checks are kept. **Latency** is the three-case table in `docs/milestones/M6.md` section 2a (prefetched under 100 ms; cache hit about 0.3 to 0.4 s as designed, **measured 0.6 s median round trip from the owner's phone on 2026-10-27**, of which the server is 40 to 125 ms; made live median 1.5 s or less as designed, **measured 2 to 3 s on the server**, so a line made while the child waits often falls back to the authored line and the pre-warm and prefetch carry the experience); the 1.5 s figure is the ceiling for the live case. Haiku 5.5 runs with thinking off, the voice model is `eleven_v4_turbo`, and the pre-warm has its own 40 s budget. **Reviewed lines (added 2026-10-27).** The model drafts and a person approves: `tutor_prewarm evaluate` writes every sentence the model made for the grid to a report, the owner strikes out the ones that are not good Hebrew, and `tutor_prewarm voice --lines <file> --confirm-lines N` speaks exactly the rest (the server runs the ten checks again, asks no model, vocalises with the lexicon, makes the voice and keeps the line under the prompt version `approved`). A reviewed line is looked up before a model-made one and no prompt change makes it unreachable. The model's teaching moves (`content/tutor-moves.json`, English, per misconception and help level, in the config row `tutor_moves`; they move into the pack in M9) tell it what to teach. Live lines carry no name. The app's helper is off by default (dev-page switch `ai_helper`; the parent's switch is M7) and speaks on the second mistake of an activity or an unexpected first mistake.
- **Session token:** every function verifies the bearer token itself against the project's signing keys (JWKS), through `@supabase/server` in `user` mode or `auth.getClaims()`. It requires an authenticated role, an unexpired token, and a user who is a guardian of the device's family. **`verify_jwt` result (M0 task C8, live project, 2026-10-25, `signed-ping` with the flag on):** it works with this project's key type (asymmetric JWT signing keys). A real session token passed. A request with no `Authorization` header (`UNAUTHORIZED_NO_AUTH_HEADER`) and one with a forged token (`UNAUTHORIZED_ASYMMETRIC_JWT`, "Invalid JWT") were refused by the platform before the function ran. The publishable key also passes the platform gate, even with no session (it is public), and our own check then refuses it. So the flag only filters traffic that carries no key at all; it cannot replace the functions' own four checks. **Decision: keep `verify_jwt = false` on every function** (one code path, nothing to break when keys rotate); turning it on later is optional defence in depth, a one-line change per function that does not touch the checks.
- **Region:** the app calls every function with the header `x-region: eu-central-1`, because Edge Functions otherwise run in the region nearest the caller.

### API contracts

Every call is an HTTPS POST to `https://<project>.supabase.co/functions/v1/<name>` with the session token, the publishable key and the signed-request headers. Bodies are JSON, at most 16 KB, checked against a schema, with unknown fields rejected.

| Function | Who may call | Request (main fields) | Response | Limits |
| --- | --- | --- | --- | --- |
| `enroll-challenge` | A fresh sign-in, or a pairing in progress | none | a challenge | 10 an hour per family |
| `device-enroll` | First device: a session signed in under 10 minutes ago | public key, platform, attestation, challenge | device id, role `parent` | 6 active devices |
| `pairing-code-create` | Parent device | none | 6-digit code | 5 an hour |
| `device-pair` | Anyone with a valid code | code, challenge, attestation, public key | device id, role `child`, one-time sign-in token | Code burned after 5 wrong tries; 20 tries an hour per IP |
| `device-list`, `device-revoke` | Parent device | device id | list or done | none |
| `tutor-turn` | Any device | child reference, session id, pack id and version, activity id, item id, band, address form, character id, hint level, the last 3 attempts as option ids, error classes and misconception ids, learner-state numbers and ids | TutorAction JSON and the line's audio (Opus), or a RuleTutor action id | 20 per session and 60 per day per child |
| `sync-push` | Any device | up to 500 events, each matching its type's schema | accepted ids with server sequence numbers | 1 a minute per device |
| `sync-pull` | Any device | `after_seq` | events and deletion markers | none |
| `alert-create` | Any device | category, severity, child reference, time, and the line only if the parent chose to keep it | alert id | 20 a day per device |
| `alerts-read`, `tutor-log-read` | Parent device | filters | rows | none |
| `character-register` | Parent device | character id, Hebrew name (letters and nikud, at most 16), self-gender, voice id from your allow-list | done | none |
| `family-pack-upload` | Parent device | images that passed the on-device checks | stored file names | 10 MB per pack |
| `family-pack-url` | Any device | pack id | signed links valid 5 minutes | none |
| `push-token` | Parent device | APNs or FCM token | done | none |
| `app-config` | Any device | none | kill switches, minimum app version, limits | cached 15 minutes |
| `signed-ping` | Any device (a check, used by the dev harness and health checks) | none | device id, role | none |
| `child-delete`, `family-delete`, `data-export` | Parent device; `family-delete` also needs a sign-in under 10 minutes ago | ids | done or an export file | none |
| `content-publish` | Your computer only, with a separate publish secret | a signed pack's item index | done | none |

### Server data model

The app's tables live in a schema called `app` that the Data API doesn't expose, and the `anon` and `authenticated` roles have no grants on it. So a session token can't read or change any table directly; only the functions can, and they filter every query by the family id taken from the verified token and device. Row Level Security stays on as a second layer. Because the Data API cannot see an unexposed schema, even with the secret key, functions reach `app` through a direct Postgres connection as a dedicated least-privilege role (`app_gateway`, via the pooler). The Supabase client with the secret key is used only for the Auth admin API.

| Table | Key fields | Kept for |
| --- | --- | --- |
| `family`, `guardian` | family id; parent user id | Until deleted |
| `device` | id, family id, role, public key (SPKI), attestation kind, enrolled and last-seen times, revoked time | Until revoked plus 90 days |
| `enroll_challenge`, `pairing_code`, `request_nonce` | value or hash, expiry, used time | Minutes |
| `child_profile` | as tech spec §7.8, plus family id and `deleted_at` | Until deleted |
| `event` | server `seq`, UUIDv7 id, family, child and device ids, client time, engine version, type, payload | Until the child is deleted |
| `family_character` | character id, family id, Hebrew name, self-gender, voice id | Until deleted |
| `content_item`, `misconception` | pack id and version, item id, template, prompt text, answer forms, number set, allowed actions, hint threshold, object ids; misconception descriptions | Current pack versions |
| `alert` | id, family and child ids, category, severity, time, line if kept, read time | 30 days |
| `tutor_log` | family and child ids, time, item id, tutor line, validator result, ElevenLabs request id | 30 days |
| `usage_counter` | scope, key, day, count, cost | 90 days |
| `config`, `push_token` | kill switches, caps, minimum version; parent device tokens | Current |
| `consent` | as tech spec §7.8; append-only; the user id replaced by a hash when the family is deleted | Account life plus 3 years |

The gateway takes every piece of prompt text, including the companion's name and self-gender, from `content_item`, `misconception` and `family_character`. The device sends only ids, numbers and enums.

### Sync rules

- **Cursor:** the server gives every event a sequence number on insert, and `sync-pull` asks for everything after the last one seen. Device clocks never decide what gets synced.
- **Replay order:** events are replayed in order of client time, then device id, then event id. When an older event arrives late, the device replays the affected child's history again.
- **Engine version:** every event carries the engine version. After an update, the app rebuilds learning state from the events.
- **Rewards are their own events.** Replay never takes a sticker, trophy or star away.
- **Settings:** last write wins by server sequence number.
- **Deleted children:** `deleted_at` acts as a marker. `sync-push` refuses events for a deleted child, and `sync-pull` tells every device to delete that child's local data.

### One table of tutor limits

The AI tutor section, the validator and the prompt all use this table.

| Band | Words per reply | Sentences | Wait after a question |
| --- | --- | --- | --- |
| A (3–4) | 10 | 1 | 4 s |
| B (5–6) | 15 | 2 | 5 s |
| C (7–8) | 20 | 2 | 6 s |

### A tutor turn, start to finish

- **The child never waits more than 3 seconds.** The app shows "thinking" within 100 ms, plays a recorded "hmm" at 1.5 s, and uses RuleTutor at 3.0 s.
- **On the server:** checks and caps take about 150 ms, the model has 1.6 s, and voice has 0.9 s. A validator retry happens only if at least 1.5 s are left.
- **One round trip.** `tutor-turn` validates the line, makes its voice with ElevenLabs and returns both, so there is no second call.
- **Warm functions.** The app sends a light `app-config` call when a session starts, so the first tutor turn doesn't pay for a cold start.

### Live lines: pronunciation and captions

- **The vocabulary lexicon carries nikud.** Every allowed word form in it has a reviewed vocalised spelling, so nikud is still never generated by a model.
- **The server vocalises each live line from the lexicon** before sending it to ElevenLabs and before the caption is shown. A word whose letters have more than one reading (for example ספרי) fails the line unless the lexicon fixes its reading for that item.
- **Captions:** live lines have no caption in Band A, and a caption with nikud from the lexicon in Bands B and C.

### How the hard validator checks work

- **Gender:** `hebrew_text` generates an inflection table for every verb in the lexicon. Second-person imperative and future forms are tagged masculine, feminine or plural, and first-person present forms are tagged masculine or feminine. The validator fails any tagged form that doesn't match the parent's chosen address form or the speaking character's gender, and ignores forms that are ambiguous without nikud (such as את). The prompt asks for plural and "let's" forms where possible.
- **Vocabulary:** the allowed set is every inflected form of the lexicon's roughly 3,000 lemmas, plus this item's own nouns and number words, plus the character names. A word passes if any split of its leading prefix letters (ו ה ב כ ל מ ש) lands in the set, so words like בלון that start with a prefix letter still pass.
- **Numbers:** number words are read with a short list of idioms that aren't quantities (פַּעַם אַחַת, אֶחָד־אֶחָד). Every remaining number must belong to the item.
- **Targets:** in the 300-scenario evaluation, good replies are wrongly rejected at most 10% of the time. The pass rate is tracked at every release.

### Alerts in v1

- **Where the words come from:** the speech recogniser returns its full transcript of every voice answer, even though the matcher looks only for the expected answers. Nothing else the child says is ever heard.
- **How they are found:** on-device word lists for each category ("worrying disclosure", "inappropriate words"), kept in the repo and reviewed. No model is involved.
- **What the child hears:** for a worrying disclosure, a pre-recorded caring line that points to a trusted adult, then back to play.
- **What is kept:** the category, time and activity. The child's exact words are kept only while "keep the words" is on in the parent settings (decided: on by default, and the parent can turn it off), and never longer than 30 days.
- **No model for sorting reasons either.** Band C explain-back and off-topic redirects use an on-device keyword matcher that maps to fixed reasons and recorded lines.

### Push to the parent's phone

- **Parent devices only.** Push is set up only after a device enrols as `parent`.
- **iOS:** APNs directly, sent from an Edge Function with a token-based `.p8` key stored as a Supabase secret.
- **Android:** FCM HTTP v1, with `firebase_messaging` auto-init turned off and started only on parent devices.
- **Content:** the push says only "יש התראה חדשה" ("there's a new alert"); the details open behind the gate. v1 has no email.

### Network hosts by device role

| Role | Hosts the app may reach |
| --- | --- |
| Child device | The Supabase project host; the packs host on R2 (content, voices and the mirrored speech model) |
| Parent device | The above, plus Apple or Google sign-in, and on Android the Firebase hosts needed for push |

The host test in CI reads this table from `app/network_hosts.json`. Anthropic and ElevenLabs are never reached from any device.

### Backups and deletion

- **Weekly encrypted export:** a scheduled GitHub Action runs `pg_dump` of the `app` schema, encrypts it with `age` to your public key, and stores it in a private bucket. The last 4 are kept.
- **Deletion:** immediate in the database, and complete in backups within 28 days, when the oldest export ages out. Consent rows lose the user id.
- **Scheduled jobs:** `pg_cron` jobs don't run while a free project is paused. They catch up when it resumes; move to Pro if retention must be exact.
- **Email codes:** set up your own SMTP sender in Supabase, because the built-in sender is heavily rate-limited.

## Security architecture

Nothing a child does needs the network. Only four things ever cross it: content downloads, family sync, parent alerts, and short structured tutor requests. Each crossing is authenticated, rate-limited and capped in money, and every failure falls back to the offline experience without showing the child an error.

**Seven rules the code must follow:**

1. **Secrets never ship.** The app contains only the Supabase URL, the publishable key and the public key that checks content signatures. The Anthropic, ElevenLabs and Supabase secret keys live only in Supabase secrets and your password manager.
2. **Least data.** The model never receives a name, audio, a device identifier, or anything the child typed or said; it sees placeholders (`{child}`, `{companion}`) that are replaced after the reply passes the validator. The voice service never receives audio or a device identifier. It may receive a child's first name, spelled and vocalised by a parent, inside a line that is being voiced (owner decision, 2026-10-25). v1 has no free-text path from the child to the model.
3. **The server writes the prompt.** The device sends ids and enums. The gateway looks up the item's text in its own copy of the signed content, so nothing the device sends becomes prompt text.
4. **Everything from outside is untrusted until checked.** That covers model output, content packs, imported images, sync events and push messages.
5. **Fail safe.** Any failed check means RuleTutor and recorded voice; the child sees no error and loses nothing.
6. **Money is part of security.** Caps at three levels: per child, per family per day, and the provider's own spend limit.
7. **Deny by default.** Database access is off unless a policy allows it, functions reject unknown fields, and only enrolled devices can call the gateway.

&#91;embedded content: trust zones · 3 zones, 6 crossings\]

The gateway is the only door from the device to anything that costs money or holds family data. The vendors see only what the gateway builds, never the device's request.

### Threat model

The two most likely harms at family scale are a leaked vendor key running up a bill, and a database rule mistake exposing family data. The two worst harms are a child hearing something unsafe from the tutor, and a child's private words leaking. Every row below has a control in v1.

| Threat | Likely / impact | Controls in v1 |
| --- | --- | --- |
| A vendor API key leaks from the repo, a build, a log or a screenshot | Medium / high | Keys only in Supabase secrets; `gitleaks` before every commit (a hook that refuses the commit if the scanner is missing) and in CI over the full Git history, with a self-test that plants fake keys (GitHub's own secret scanning is not available on a free account's private repo); ElevenLabs key limited to text-to-speech with a credit limit; Anthropic key in its own workspace with a monthly spend limit; rotation runbook |
| Someone extracts the publishable key and uses the gateway as a free AI or voice service | Medium / high | Every function needs a session token and a request signed by an enrolled, attested device; voice only for lines the gateway just validated; caps per child, per family per day, and at the provider; kill switches |
| A session token is used to read tables directly, skipping the gateway | Medium / high | App tables sit in a schema the Data API doesn't expose, with no grants for signed-in users; a test proves the Data API returns nothing; RLS as a second layer |
| A child, or anyone holding a child's tablet, gets into the parent area | High / medium | PIN on every device with a child profile, with growing lock-outs; child-role devices can't read alerts or the tutor log, delete data or manage devices; the parent area locks when left |
| A new device is added to the family without permission | Low / high | The first device needs a fresh sign-in; others need a one-time pairing code from a parent device; attestation against a server challenge; at most 6 active devices |
| A lost or stolen device | Medium / medium | Revoke it from the parent's phone; its signed requests stop at once; local data is encrypted with a key in the Keychain or Keystore |
| A session token is copied off a device | Low / medium | Tokens in secure storage, excluded from backups; one-hour access tokens; every call also needs the device's hardware key, so a copied token alone is useless |
| Prompt injection changes what the tutor does | Low / high | No free text from the child or device reaches the model; the server builds the prompt from its own content tables; family character names are registered by a parent device and limited to Hebrew letters |
| The tutor says something unsafe, wrong or off-task to a child | Low / critical | Strict output schema; validator for length, Hebrew only, gender, answer leaks, numbers, vocabulary and blocklists; RuleTutor on any failure; parent log with a report button; evaluation suite blocks releases |
| A tampered content pack (on R2 or in transit) | Low / high | Ed25519 signature with the private key kept offline; a hash for every file; versions only go up; safe unpacking |
| A harmful imported image | Low / medium | File type checked from its bytes; PNG, WebP or JPEG only; 2 MB and 4096 px limits; checked again on every device; never sent to any vendor |
| A child's flagged words leak | Low / high | Kept only if the parent leaves "keep the words" on, for 30 days; readable only from a parent device; push messages carry no content |
| Traffic is intercepted | Low / medium | HTTPS only, cleartext blocked on both platforms; a fixed list of hosts per device role, enforced by a test |
| A compromised package or model file | Low / high | Locked versions; dependency alerts and a vulnerability scan in CI; new dependencies reviewed; the speech model checked against a pinned SHA-256 |
| A bug calls the tutor in a loop and burns money | Medium / medium | Client circuit breaker; server caps below the provider limits; spend alerts at 50% and 80% |
| The free Supabase project pauses or loses data | Medium / low | Local-first, so the app keeps working; state rebuilds from events; a weekly encrypted export |

### Security controls by layer

Each control below is a build requirement with a check, not advice. The build plan's definition of done points back here, and the exact formats are in the build specification.

**On the device (Flutter app)**

- **Encrypted local data.** Drift runs on an encrypted SQLite build (SQLite3 Multiple Ciphers or SQLCipher) with a random 256-bit key made on first run. The key lives in `flutter_secure_storage`: iOS Keychain set to "after first unlock, this device only" so background sync still works; Android Keystore, StrongBox where present.
- **No backups of secrets.** Secure-storage items never sync to iCloud or Google backup; on Android `allowBackup` is off and the data-extraction rules exclude the database and tokens. A fresh install clears Keychain items left over from an earlier one.
- **A hardware device key.** A non-exportable P-256 key in the Secure Enclave or Android Keystore, made through a small platform channel and proven with App Attest (iOS) or Key Attestation (Android) against a server challenge. Every gateway call is signed with it.
- **Device roles.** A child device can't read alerts or the tutor log, delete data, or manage devices, even if a child gets past the gate.
- **Parent gate and PIN.** A PIN is required on every device with a child profile; the arithmetic gate only comes before it. **Changed on 2026-10-27 at the owner's request:** the gate question is now a small sum of two single digits shown in digits (for example 6 + 7) on the shuffled keypad, because the multiplication in words was too hard for the parents; the PIN is the real protection. The wrong-answer cool-downs and locks are unchanged. The PIN (4 to 6 digits) is stored as an Argon2id hash with a random salt. Lock-outs grow after 5, 7, 9 and 11 wrong tries (30 s, 2 min, 10 min, 1 h), the counter lives in secure storage so closing the app doesn't reset it, and 3 failures raise an alert. The parent area locks after 5 idle minutes or when the app goes to the background; its screens block screenshots on Android and are hidden in the iOS app switcher.
- **Microphone.** It opens only after a parent turned voice on and the child tapped the mic. Audio stays in memory, is cleared after recognition, and is never written to a file.
- **Imported images.** Type checked from the file's bytes; PNG, WebP or JPEG only (SVG import is refused in v1; the built-in packs ship as PNG); at most 2 MB and 4096 px a side. Every device runs the same checks again when it downloads a family pack.
- **Allowed hosts only.** One network client, limited to the hosts for the device's role. Android blocks cleartext traffic; iOS keeps App Transport Security with no exceptions.
- **Circuit breaker.** After 3 failed tutor calls in a session, AI is off for the rest of that session.
- **Release builds.** Built with `--obfuscate --split-debug-info`, debug logging stripped, and a test that fails if a token or key pattern reaches a log. Builds older than the server's minimum version keep working offline only.

**At the gateway (Edge Functions)**

- **Four checks on every call:** the session token, verified in the function against the project's signing keys; the device signature, time and nonce; that the device is active and belongs to the token's family; and that its role may call this function.
- **Strict input.** Each body is checked against a schema: 16 KB at most, ids and enums only, unknown fields rejected, and every content id must exist in `content_item` for the pack version named.
- **Caps in the database.** One atomic counter update per call enforces the per-child, per-device and per-family limits. The family's daily cost cap sits below the provider limits, so the provider limit is the last line, not the first. Kill switches for the tutor and live voice are in `config`.
- **The prompt is server code.** It is built from a fixed template and the server's own content tables. The model id is pinned to `claude-haiku-5-5`, output is capped at 300 tokens, and the timeouts follow the 3-second plan.
- **Voice in the same call.** Voice is made only for a line that has just passed the validator, with the voice id taken from the server's character table. The ElevenLabs request id is saved, so the nightly job can delete that history item.
- **Quiet logs and errors.** Logs keep a request id, function, latency and outcome, never tokens or child words (those live only in `tutor_log` and `alert`). Errors return a short code with no details. Functions serve no browser origins.

**In the database and storage**

- **No direct table access.** App tables live in the unexposed `app` schema with no grants for `anon` or `authenticated`, so a session token, even a stolen one, can't reach them through the Data API. Functions are the only way in.
- **Row Level Security as the second layer.** Every table still has RLS on, with policies that allow a row only for the caller's family, in case a table is ever exposed by mistake.
- **Secret key only inside functions,** always used with an explicit family filter taken from the verified token and device.
- **Private family packs.** Uploads go through `family-pack-upload` to `family-packs/<family id>/<pack id>/<sha256>.png`. Clients have no storage policies at all; downloads use 5-minute signed links.
- **Accounts.** Sign in with Apple, Google or an email code on the parent's phone only; anonymous sign-in off; Supabase's sign-in rate limits on; your own SMTP sender for email codes.
- **Deletion that is real.** "Delete child" removes the profile, events, alerts, the tutor log and that child's storage, and marks the child deleted for every device. "Delete family" removes everything, including the sign-in account. A nightly job deletes the ElevenLabs history items the gateway created, since that history is kept by default and zero-retention mode is for enterprise customers only.

**Content and supply chain**

- **Pack signing key offline.** The Ed25519 private key is made on your machine and kept in your password manager, never in the repo or CI. The public key is built into the app. Rotation ships an app version that accepts both the old and new keys.
- **Pack manifest.** A SHA-256 for every file, the pack version and the minimum app version. The app refuses a version lower than the one installed, and unpacks safely so no path can land outside the pack folder.
- **Publishing.** `pack_builder` uploads the signed pack to R2 and its item index to `content_item` through `content-publish`, using a publish secret that exists only on your computer.
- **Dependencies.** Lock files committed; Dependabot and an OSV vulnerability scan in CI; every new package reviewed before it is added; the speech model checked against a pinned SHA-256.
- **Repository.** Private; branch protection on `main` with required checks; a fail-closed `gitleaks` pre-commit hook and a full-history `gitleaks` scan in CI. GitHub secret scanning with push protection needs a paid plan on private repositories; switch it on if the plan changes.

**Secrets and accounts**

Turn on two-factor sign-in, ideally passkeys, for GitHub, Supabase, Anthropic, ElevenLabs, Apple, Google, Firebase, Cloudflare and Codemagic.

| Secret | Where it lives | Used by | Rotate |
| --- | --- | --- | --- |
| Anthropic API key | Supabase secret; its own Console workspace with a $5 monthly spend limit | `tutor-turn` | Every 6 months, or at once on any doubt |
| ElevenLabs runtime key | Supabase secret; text-to-speech scope only, with a monthly credit limit | `tutor-turn` | Every 6 months |
| ElevenLabs generation key | `.env` on your computer only | `voice_gen` | After each generation run |
| Supabase secret key | Supabase-managed, inside functions only | Functions and scheduled jobs | On any doubt |
| Supabase publishable key | In the app; public by design, harmless because tables aren't exposed | App | Not needed |
| Content publish secret | Your computer and a Supabase secret | `content-publish` | Yearly |
| Pack signing private key | Offline, in your password manager | `pack_builder` | Yearly, with an app update |
| APNs `.p8` key | Supabase secret | Push to parent iPhones | Yearly |
| Firebase service account | Supabase secret | Push to parent Android phones | Yearly |
| Backup encryption key (`age`) | Private key offline only; public key in the GitHub Action | Weekly export | Yearly |
| Apple signing certificates | Codemagic encrypted variables | iOS builds | When Apple requires |
| Android upload keystore | Password manager plus an offline backup | Android builds | Never lose it |

### AI safety pipeline

The model only proposes; code decides. Every tutor reply passes ten checks before a child hears it, and any failure means a pre-written RuleTutor line instead.

**The validator, in order** (server side, before any voice is made):

1. The reply parses and matches the schema; every enum is valid.
2. `say_text` contains only Hebrew letters, digits and basic punctuation: no Latin letters, links or emoji.
3. Length fits the band, as set in the tutor limits table.
4. **Gender:** tagged verb forms match the parent's address form and the speaking character's own gender (how this works: build specification).
5. **No answer leak:** before the item's hint threshold, no form of the correct answer appears and `reveals_answer` is false.
6. **Maths stays true:** every number in the line, apart from listed idioms, belongs to the item.
7. **Vocabulary gate:** every word, allowing for prefix letters, is a form from the approved child lexicon, the item's own words or a character name. An unknown word fails the reply.
8. **Pronunciation:** every word has a single reviewed reading in the lexicon, so the line can be vocalised for voice and captions.
9. Blocklists catch personal questions (name, home, school, family, phone, photos), purchases, brands, and fear or violence words.
10. `highlight_targets` are object ids from this item, `next_action` is allowed for the template, `target_misconception` is in the active list, and `safety_flag` is `none`.

On a failure the gateway retries once with the reason, but only if at least 1.5 seconds of the budget remain; otherwise it returns the RuleTutor action. Every result, pass or fail, goes to `tutor_log`. The vocabulary gate, blocklists and evaluation suite take the place of a Hebrew moderation model, which v1 doesn't use.

**The system prompt** lives in the repo, is versioned, and is covered by the evaluation suite. It sets the persona and band, the address form, "you are a computer helper and say so if asked", one short question at a time, no personal questions, no topics outside the activity, no guilt or pressure, no purchases or links, and "never give the answer before hint level N". It contains nothing secret, so leaking it does no harm. If Anthropic publishes a child-safety system prompt, it goes first.

**OWASP Top 10 for LLM applications (2025), mapped to this app**

| Risk | How it could happen here | Control |
| --- | --- | --- |
| LLM01 Prompt injection | Text from a device or a pack reaches the prompt | Ids only from the device; the server builds the prompt from signed content; names are data, limited to Hebrew letters |
| LLM02 Sensitive information disclosure | Child data reaches the model | No name (placeholders only), audio, transcript or device id ever sent to the model |
| LLM03 Supply chain | A changed model or dependency | Pinned model id; locked dependencies; a re-run of the evaluation suite before any change |
| LLM04 Data and model poisoning | Bad content or examples steer replies | Content is signed and reviewed; no fine-tuning; no learning from live chats |
| LLM05 Improper output handling | Output treated as code or markup | Output is plain text for voice and a caption only, never HTML, Markdown or commands |
| LLM06 Excessive agency | The model triggers actions | No tools; its actions are suggestions the session builder may refuse |
| LLM07 System prompt leakage | A child coaxes out the prompt | Nothing secret in it; no free-text input in v1 |
| LLM08 Vector and embedding weaknesses | Not applicable | v1 uses no retrieval or embeddings |
| LLM09 Misinformation | Wrong maths in a hint | The numbers check, answer-leak check and RuleTutor fallback |
| LLM10 Unbounded consumption | Loops or abuse drive cost | Token cap, timeouts, per-child, family and provider caps, circuit breaker |

**Anthropic's rules for products used by minors** (guidelines dated 16 March 2026), and how v1 meets them:

- **Must disclose that it's AI.** Parents see it at setup, and the companion says it is a computer helper whenever asked.
- **Content moderation and filtering.** The validator above.
- **Monitoring and reporting.** The parent's 30-day tutor log with a report button, plus alerts.
- **Only intended users.** Child profiles are created only by a parent behind the gate.
- **A child-safety system prompt** from Anthropic, if one is provided, is used.
- **Public compliance statement.** Needed only for a public release.

Anthropic doesn't keep API prompts and replies by default, but content its safety systems flag may be kept for up to 2 years, and zero data retention needs a sales agreement. That is one more reason the gateway never sends personal data. ElevenLabs requires its account holder to be 18 or over: that's you, and children never touch ElevenLabs directly.

### Security testing, release gates and incident runbook

Security is tested by code on every change, not checked once by hand. A build that fails any gate below doesn't reach the children's devices.

**Automated tests (run in CI on every push)**

- **No direct database access:** with a valid session token, every Data API path to the `app` schema returns nothing, and storage can't be listed, read or written.
- **Database rules:** for every table, a user from family A tries to read, add, change and delete family B's rows, and a signed-out caller tries everything; all must fail. Written with `supabase test db` (pgTAP).
- **Gateway:** a missing or expired token, a token signed by the wrong key, a bad signature, a reused nonce, an old timestamp, a revoked device, a child device calling a parent-only function, an oversized body, an unknown field, an unknown content id, a cap reached and a kill switch on must each get the right refusal.
- **Enrolment:** a reused or expired challenge, a wrong or reused pairing code, an attestation for another app, and a seventh device must all be refused.
- **Validator:** a golden set of bad replies (answer leaks, wrong gender, Latin text, unknown words, wrong numbers, ambiguous readings, personal questions) must all be rejected, and the good set must pass at least 90% of the time.
- **Tutor evaluation:** the 300-scenario suite from the technical spec, re-run whenever the prompt, model, lexicon or validator changes. One critical failure blocks the change.
- **App:** a static scan of each Android and iOS build with MobSF (no secrets in the binary, cleartext off, backups off, no exported components), the host test against `network_hosts.json`, and a check that the permission list hasn't grown.
- **Dependencies and secrets:** an OSV scan that fails on high-severity issues, and `gitleaks` over the full history.
- **On real devices:** the Secure Enclave, App Attest and Key Attestation don't exist in simulators, and the iOS platform code can only be built through Codemagic from Windows. So each release is enrolled and tested on a real iPhone or iPad from TestFlight and a real Android device.

**Release gate checklist**

- [ ] All automated tests pass
- [ ] Supabase's Security Advisor shows no errors
- [ ] No new network host, permission or third-party SDK, or each one reviewed and written into this plan
- [ ] The OWASP MASVS level 1 checklist is still met (level 2 before any public release)
- [ ] The spend limits at Anthropic and ElevenLabs are still set

**Every three months:** rotate one key as a drill, read a sample of the tutor log, and test a device revoke.

**Incident runbook**

| Incident | In the first 15 minutes | Then |
| --- | --- | --- |
| A vendor key leaked | Revoke it in the vendor console; set a new Supabase secret; redeploy the functions | Check usage since the leak; find how it leaked and add a test or scan rule for it |
| Spending jumps | Turn off the tutor and live voice in `config`; the app falls back to offline voice | Find the device in `usage_counter`; revoke it if it's not yours; tighten the caps |
| A device is lost or stolen | Revoke it from the parent area on another device, or in the dashboard; end its sessions | Change the parent PIN; re-enrol a replacement |
| Possible data exposure from a rule bug | Turn off the affected function; fix the policy and add the missing test | List what could have been read and by whom. Before any public release, check Amendment 13 duties to report security incidents |
| A parent reports a harmful tutor line | Turn off the tutor | Add the line to the validator's test set and fix the gap; re-run the evaluation before turning it back on |
| A pack might have been tampered with | Remove it from R2 and publish a higher version | If the signing key may be exposed, ship an app update with a new key |

## Privacy, child safety & store compliance

One design rule set covers every regime below. Process on the device, collect the minimum, keep adult features behind a parental gate, and ask separate parental consent for anything extra. For personal family use the store rules don't apply yet, but building to them now avoids a rebuild later. This is a technical reading, not legal advice; privacy counsel should review it before any public release.

| Rule | Status, October 2026 | What it means for the build |
| --- | --- | --- |
| Israel, Privacy Protection Law, Amendment 13 | In force since 14 August 2025. No child-consent age, so parental consent is the practical norm; fines and statutory damages without proof of harm | Hebrew notices at parent onboarding, a consent log, a privacy protection officer from launch, written security procedures |
| Apple Kids Category (guidelines 1.3 and 5.1.4) | No third-party analytics or ads; links, purchases and settings only behind a parental gate; age bands 5 and under, 6–8, 9–11 | Separate child and parent sections in code; gate = a small sum on a shuffled keypad (was a multiplication in Hebrew words until 2026-10-27), or a parent PIN; **before any App Store or Kids Category submission, re-check this gate against Apple's guidance that a parental gate must be hard for a child to pass (the owner's family builds go through TestFlight only)**; self-hosted crash reporting |
| Google Play Families and Expert Approved | No advertising ID or location; approved SDKs only; AI-generated content needs a feedback route; updates must target API 36 from 31 August 2026 | The build fails if a forbidden permission appears; parents get a "report this line" button for the tutor |
| US COPPA, amended | Compliance required from 22 April 2026; voiceprints count as personal information; written retention and security programmes | Applies if US families use it: no voiceprints ever, audio deleted right after recognition, published retention periods |
| EU GDPR Article 8 and the AI Act | Parental consent under 13–16; AI transparency duties from 2 August 2026; emotion recognition in education is banned | EU hosting, a data-protection impact assessment before an EU launch, "the helper is a computer" told to parents and children, the child's emotions never inferred |
| Store intellectual-property rules (Apple 5.2.1, Google Play IP policy) | Third-party characters need the rights holder's permission | Personal-use character packs can never enter a store build; licensed packs carry licence dates, territories and a kill switch |

**Child-safety commitments built into the product:**

- A child profile holds only a nickname, avatar, age range and grammatical gender. No date of birth, photo, school or location.
- No child audio is stored; recognition happens on the device and the audio is released immediately.
- The model never receives the child's name (placeholders only), and the tutor never asks personal questions.
- No chat, user-generated content, public profiles or push notifications to children.
- No dark patterns: no countdowns, loss framing, streak pressure or sad-character exits.
- The microphone opens only when the child taps it, with a visible listening indicator.
- Parents can switch voice and AI off, set time limits, and read a 30-day log of everything the helper said.

## Quality, testing with children & success metrics

Success is lasting understanding, measured in the app and confirmed by an independent study, plus children who choose to come back. Engagement numbers are guard rails, never goals.

### What we measure

| Metric | What it tells us |
| --- | --- |
| Delayed-check pass rate, per skill and band | Whether understanding lasts: the headline number |
| Fresh-to-durable conversion within 30 days | Whether the mastery bar is honest |
| Success on new-context and reverse questions vs familiar ones | Understanding versus rote |
| Misconceptions resolved, and relapses within 60 days | Whether repair works |
| Success on the 2 items after a change of explanation | Which explanations work, per skill and per child |
| Hint level needed over time | Growing independence |

**Guard metrics:** frustration loops (3 or more errors in a row), quitting right after an error, an "I'm not sure" rate stuck high, and session length against the parent's limit.

**A/B tests judge learning, not engagement.** The success measure is accuracy at the next spaced check, and results count only once each variant has 200 or more children.

### Testing with children

|  | Band A (3–4) | Band B (5–6) | Band C (7–8) |
| --- | --- | --- | --- |
| Method | Parent-and-child pairs at home or gan; a researcher voices Nitzi live in early prototypes | Observation, short play tasks, a smiley-face scale | Pairs, light think-aloud, short interview |
| Session | 15–20 min | 20–25 min | 25–30 min |
| Children per round | 6–8 | 6–8 | 5–6 |

- **Cadence.** Every 2 weeks from paper prototype onwards. Monthly lab rounds plus a 2-week home diary study with 20 families in alpha. Quarterly after launch.
- **What we watch for:**
  - hesitation over 3 seconds;
  - glances to the parent;
  - accidental and resting-hand touches;
  - whether children understand Nitzi without captions;
  - how they react when she didn't hear them;
  - smiles, "again!";
  - rapid random tapping, a frustration signal.
- **Template pass bar:** at least 80% of children start correctly from the audio instruction alone.
- **Who takes part:** children from the centre and the periphery, religious and secular families, Hebrew as a first and second language, and children with colour-vision deficiency. Every session has parental consent and the child's own "you can stop any time".

### Engineering quality gates

- **A learning simulator:** 10,000 synthetic children with planted gaps, misconceptions and forgetting. Planted gaps must be found within 3 probes in at least 90% of cases before any change to learning rules ships.
- **Voice evaluation set:** about 300 Israeli children and 30,000 recorded answers by launch, collected with separate written parental consent and used for testing only.
  - **Accuracy:** when the app accepts an answer, it must be right at least 97% of the time.
  - **Coverage:** voice resolves at least 70% of utterances in Band A and 85% in Band C without falling back to tap.
- **Tutor evaluation:** 300 scenarios scored blind by Israeli educators for teaching quality, answer leaks, gender agreement and warmth, plus red-team prompts. Any critical failure blocks a release.
- **Screens and devices:** right-to-left screenshot tests with real fonts for every template, device class and band. Nightly performance runs on a low-end Android tablet and an iPhone SE.
- **Content checks:**
  - a headless playthrough of every activity: the correct path, each tagged wrong path and the full hint ladder;
  - item analytics after 200 children: items that are too easy, too hard or have a distractor nobody picks get revised.

### Independent efficacy study

A meta-analysis of apps for preschool to grade 3 found an average effect of about +0.31 standard deviations, smaller on standardised tests. So we plan modestly and measure independently.

| Stage | Design | Sample | Decision it informs |
| --- | --- | --- | --- |
| 1. Feasibility (alpha) | Single group, 4 weeks | 30 children | Fix templates; tune session length |
| 2. Pilot efficacy (beta) | Randomised waitlist control, 8 weeks; blind one-to-one assessments in Hebrew; retention test 6 weeks later | About 120 children aged 4–6 | Effect on number sense at the delayed test |
| 3. Larger trial (after launch) | Cluster trial through kindergartens or schools with an academic partner | 300–600 children | An evidence claim for parents and schools |

## Roadmap, team & budget

You're building this yourself with Claude, so there is no team payroll or build budget. The phases keep their order, but their length depends on your hours. A family build for your own kids comes first; a public release is optional and later.

&#91;embedded content: roadmap · 5 phases, 4 gates, not to scale\]

The discovery spikes decide how much voice each band gets before the main build starts. The beta then tunes speech thresholds by age and calibrates the learning rules on real children.

**What the MVP includes:**

- everything playable by tap, plus voice for numbers, colours, shapes and yes/no;
- 12 templates and about 95 skills (all of Bands A–B, a Band C preview);
- the full understanding engine, the rule-based tutor, and the AI tutor behind a switch;
- the character pack system with 3–4 original characters, plus lite-pack import in personal builds;
- the content validation script and in-app preview;
- the parent area, sync, and phone and tablet layouts.

**Later:** full Band C, voice explain-back beyond Band C pilots, child-adapted speech recognition, licensed character packs if contracts are signed, play-together mode, a classroom edition, and Arabic or Russian for parent screens.

### Who builds it

You, working with Claude (Claude Code for the app and backend, Claude for content and design), plus ElevenLabs for every voice. Since 2026-10-28 the Claude Code work is split among eight project agents (infrastructure, design, Hebrew text, voice and sound, development, QA, security, curriculum) under one orchestrating session; see `docs/agents/README.md`. Specialists are optional extras, not requirements: a Hebrew language editor to review nikud and wording, a kindergarten or grade 1–3 teacher to sanity-check content, and a Rive animator if you want richer character motion than the built-in procedural animation.

### Running costs (infrastructure only)

For family use with two children, expect about $25–30 a month while voices are being generated, dropping to about $6–10 a month after, plus $99 a year for Apple. Prices were checked on the providers' pages in October 2026.

| Service | What it's for | Plan | Cost |
| --- | --- | --- | --- |
| ElevenLabs | All character voices: core lines generated once, live tutor lines | Creator: 275,000 v4 characters a month. API rates: v4 $0.08 and v4 Turbo $0.04 per 1,000 characters | $22/month while generating; Starter $6/month after |
| Anthropic API (Claude Haiku 5.5) | The AI tutor | Pay as you go, on your own API key from the Claude Console, billed separately from a claude.ai subscription | About $0.02 per child per month, so under $1 |
| Supabase | Parent account, sync between devices, alerts | Free: 500 MB database, 1 GB files. Free projects pause after a week with no activity | $0, or $25/month for Pro if pausing gets in the way |
| Cloudflare R2 | Content, voice and character packs | Free: 10 GB storage, free downloads | $0 |
| Codemagic | Building the iOS app from Windows | Free: 500 Mac build minutes a month | $0; then $0.095 per minute |
| Apple Developer Program | Installing on iPhones and iPads through TestFlight | Required for iOS | $99/year |
| Google Play Console | Only if you publish on Google Play; installing directly on your own Android devices is free | Optional | $25 one-time |
| Rive | Character animation editor | Free plan to start | $0, or about $39/month if you need paid exports |

**Voice generation, worked out:** about 3,000 core lines × about 40 characters is roughly 120,000 characters per character voice, a little under half a month of the Creator plan's 275,000. So generate voices only for the companions your children actually pick: Nitzi plus two favourites is about 360,000 characters, or about 1.3 months of Creator ($22–44 in all). Each extra companion adds about half a month. Live tutor lines add about 3,600 characters per child per month after caching, about $0.15–0.30. The database caps sit below the provider limits: a $5 monthly limit at Anthropic, and a monthly credit limit on the ElevenLabs runtime key.

## Development environment setup

Your computer runs Windows, which handles everything except building the iPhone and iPad app: Apple only allows that on a Mac. The plan uses Codemagic's cloud Macs for iOS builds (500 free minutes a month), so you never need to buy a Mac. Follow the steps in order; each ends with a check.

**Simplified for a family build.** No separate CMS or servers. Lessons live as JSON files in your Git repository, and a small Supabase Edge Function acts as the gateway that holds your Anthropic and ElevenLabs keys. Keys never go inside the app.

### Step 1 — Accounts

- [ ] **GitHub:** a private repository for the code and content.
- [ ] **Anthropic Console** (console.anthropic.com): create an API key for Claude Haiku 5.5 and set a monthly spend limit, e.g. $5. This is separate from your claude.ai subscription.
- [ ] **ElevenLabs** (you already have a paid account): create an API key; in Voice Design or the voice library, save one voice per character and note its voice ID.
- [ ] **Supabase:** a project in the Frankfurt (eu-central-1) region.
- [ ] **Cloudflare:** an R2 bucket for content and voice packs.
- [ ] **Rive:** a free account for character animation.
- [ ] **Apple Developer Program** ($99/year): needed to put the app on iPhones and iPads through TestFlight.
- [ ] **Codemagic:** sign in with GitHub, for iOS builds.
- [ ] Google Play Console ($25) only if you ever publish on Google Play. Installing on your own Android devices doesn't need it.

Also create a free Firebase project (for push alerts to your phone only), and turn on two-factor sign-in, ideally passkeys, for every account above.

### Step 2 — Windows tools

1. **Git for Windows** (2.27 or later). Check: `git --version`.
2. **VS Code** with the **Flutter** and **Dart** extensions.
3. **Claude Code**, installed from the official Claude Code docs, and signed in. You'll build the app together with it, from inside the project folder.
4. **Flutter SDK**, latest stable: in VS Code run "Flutter: New Project", then "Download SDK" into `C:\dev`, and let it add Flutter to PATH. Restart the terminal.
5. **Android Studio**, full version, which brings Java with it. In **Tools → SDK Manager** install the Android SDK Platform that `flutter doctor` asks for (the plan targets API 36), plus Command-line Tools, Build-Tools, Platform-Tools and the Emulator.
6. **Node.js LTS**, for the Supabase CLI and Edge Functions. Check: `node -v`.
7. **Docker Desktop**, so Supabase can run locally while you develop.
8. **Supabase CLI**: pinned in the repository as a dev dependency. Run `npm ci`, then `npx supabase login`. A global `npm install -g supabase` is not supported by Supabase.

### Step 3 — Check the toolchain

1. Open an admin PowerShell and run `flutter doctor --android-licenses`, accepting each licence.
2. Run `flutter doctor`. Android toolchain, Android Studio, VS Code and Flutter should all be green. A warning about Xcode or iOS is expected on Windows.

### Step 4 — Devices

- **Android emulator:** in Android Studio's Device Manager, create a tablet and a phone (landscape), with Graphics set to "Hardware".
- **Real Android phone or tablet:** turn on Developer options and USB debugging, connect it, and check that `flutter devices` lists it. Testing on the real device your kids use matters most.
- **iPad or iPhone:** install the TestFlight app on it; builds arrive there from Codemagic (step 7).

### Step 5 — Create the project

1. Clone your GitHub repository into a short path outside OneDrive (this project uses `D:\Children-Learning-App`) and open it in VS Code.
2. Ask Claude Code to scaffold the app from this plan: the Flutter app, the folder structure, and the packages (Riverpod, Drift, flutter\_soloud, rive, sherpa\_onnx). Then `flutter run` should show the app on the emulator.
3. `supabase init` and `supabase start` start the local database. Then `supabase link` connects it to your cloud project.
4. Store your keys as Supabase secrets, never in the app: `supabase secrets set ANTHROPIC_API_KEY=... ELEVENLABS_API_KEY=...`.
5. Add an `.env` file for local settings, and make sure it is listed in `.gitignore`.

Make the ElevenLabs key for the app with text-to-speech permission only and a credit limit, and keep a separate key on your computer for generating core lines. Put the Anthropic key in its own Console workspace with a monthly spend limit. Add the `gitleaks` pre-commit hook before your first commit (see Secrets and accounts).

### Step 6 — First end-to-end check

- [ ] A Rive or lite character appears and animates on the emulator.
- [ ] A script generates one Hebrew line in a character's ElevenLabs voice (Eleven v4), and the app plays it.
- [ ] The tutor Edge Function returns a Hebrew hint from Claude Haiku 5.5 in the JSON format from the plan.
- [ ] The on-device Hebrew speech model recognises "שָׁלוֹשׁ" on a real Android device.

### Step 7 — iPhone and iPad builds

1. In Apple's developer site, register the app ID. In Codemagic, connect your Apple Developer account so it can sign builds automatically.
2. Add a Codemagic workflow (Claude Code can write the `codemagic.yaml`) that builds the iOS app and uploads it to TestFlight on every push to a release branch.
3. Invite yourself and your family as TestFlight testers, and install from the TestFlight app.

### Step 8 — Content and voice workflow

- Lessons are JSON files in `content/`; a validation script checks each one against the schema in the plan before it's used.
- A voice script reads every core line and generates audio for each character's ElevenLabs voice with Eleven v4. It saves the files into that character's pack, skips lines that already exist, and writes a list of lines for you to listen to and approve.
- Packs upload to Cloudflare R2 and the app downloads them on Wi-Fi.

## Build plan: milestones and acceptance criteria

Build in this order. Security foundations come first because they are cheap to add at the start and costly to retrofit. Each milestone ends with something you can run on a real device, and isn't done until its acceptance checks pass. Hand Claude Code one milestone at a time, with this plan open.

| # | Milestone | What gets built | Done when |
| --- | --- | --- | --- |
| M0 | Foundations | Repo layout; CI with lint, tests, `gitleaks` and the OSV scan; Supabase project with the unexposed app schema, RLS and pgTAP tests; the shared token and signed-request checks; device enrolment and pairing, tested on a real Android device first and on a real iPhone or iPad through TestFlight at the iOS gate (see `docs/milestones/M0.md`); secrets set; two-factor sign-in on every account | CI is green; every cross-family and direct-access test fails as it should; a real Android device enrols and makes a signed call, and later a real iPhone or iPad does the same at the iOS gate; no secret anywhere in the Git history |
| M1 | App shell and design system | Flutter app reading `tokens.json`; right-to-left layout; Heebo and Secular One; phone and tablet layouts; separate child and parent areas; parent gate and PIN; encrypted local database | Screenshots match boards 10 and 13; PIN lock-outs work; the database file can't be opened without the key |
| M2 | Content system and first activity | JSON schemas and the validator; the pack builder that signs packs; pack install with signature checks; the count-and-tap template with misconception tags | The butterflies lesson plays end to end by tap; a pack with one changed byte is refused |
| M3 | Learning engine | Skill graph, mastery and memory model, misconception evidence, representation switching, session builder, and the simulator | The simulator finds planted gaps within 3 probes in at least 90% of cases; the engine imports no UI code |
| M4 | Characters and voice out | Role-slot resolver; lite packs (Nitzi plus the 8 family characters); procedural animation; `voice_gen` for each character's core lines; playback with mouth movement | Changing the companion changes the character and voice on every screen; 60 fps on the low-end Android tablet |
| M5 | Voice in | The on-device speech model, the answer matcher and the mic states | Accepted answers are right at least 97% of the time on a family recording set; unclear speech is never marked wrong |
| M6 | Gateway and AI tutor | Content publishing to the server tables; the lexicon with nikud; `tutor-turn` with the validator and voice in one call; caps, kill switches and the tutor log | Every gateway security test passes; median time to tutor voice is 1.5 s or less; offline and failure paths fall back to RuleTutor |
| M7 | Parent area | Analytics, on-device alert detection, controls, sync, push to parent devices, and data deletion | An alert reaches the parent's phone with no content in the push; deleting a child leaves no rows for that child on the server |
| M8 | Rewards and world | World growth, stickers, the Trophy Hall, the ceremony and parent ribbons | Trophies come only from lasting-mastery events; a parent ribbon shows on the right trophy |
| M9 | Content and family release | About 95 skills authored with Claude, nikud reviewed, voices generated; TestFlight and Android installs | Every activity passes the headless playthrough; the release gate checklist is complete |

**Definition of done for every milestone**

- [ ] Unit and widget tests for new code, plus golden screenshots for new screens, in right-to-left with the real fonts
- [ ] The security controls for the touched layers are built and tested (Security controls by layer)
- [ ] Works with no network, with AI off, and with voice off
- [ ] No new network host, permission or SDK unless reviewed and added to this plan
- [ ] No personal data in logs, prompts or crash output
- [ ] This plan updated where the build differs from it

## Risks & open decisions

The two biggest risks are recognising young children's Hebrew speech, and producing enough high-quality Hebrew content. Both are designed around: voice is optional, and the content tools generate most items from templates.

| Risk | Likelihood / impact | Mitigation |
| --- | --- | --- |
| Speech recognition too weak for young children, especially ages 3–4 | High / medium | Voice is optional; closed answer sets; a confirm step; the 97% accept-accuracy gate; a child evaluation set from month 1; voice scope per band set by data |
| Content production becomes the bottleneck (nikud, voice-over, thousands of items) | High / high | Items generated from parameters; drafting with Claude, checked by the validation script and the in-app preview; a Hebrew editor reviews nikud; first release limited to about 95 skills |
| Hebrew text-to-speech mispronounces words, or the AI uses the wrong gender | High / medium | Words vocalised from the lexicon; a gender check before speaking; an approved phrasebook; listening QA |
| Personal-use franchise characters reach a store build | Medium / critical | Packs flagged personal-use; store builds and the CDN refuse them; licence metadata with a kill switch; legal review before any licensed pack |
| The engine "finds" gaps that aren't there and bores children with repair | Medium / medium | Evidence needed across 2+ items; probes capped per session; repair framed as play; the simulator must pass first |
| Revisit checks start to feel like tests | Medium / medium | Always a different item, woven into "calls for help" on the map; capped per session |
| Rive animation breaks or stutters on cheap Android tablets | Medium / high | Pinned versions behind an abstraction; three performance tiers; nightly performance runs |
| Rule changes: Israeli privacy guidance, EU AI Act obligations from December 2027 | Medium / medium | Minimal data by design; consent log; impact assessment; counsel on retainer |
| A child discloses something worrying to the tutor | Low / high | A caring script that points to a trusted adult; parents are alerted, and the flagged line is kept for 30 days only |
| A vendor key leaks, or the gateway is abused, and runs up a bill | Medium / high | Keys only in Supabase secrets; scoped keys with provider spend limits; device-signed requests; caps per child and family; kill switches (see Security architecture) |
| A database rule mistake exposes family data | Medium / high | Row Level Security with no access by default; automated cross-family tests on every change; Supabase Security Advisor in the release gate |

### Decisions for you

| # | Decision | Options | Recommendation |
| --- | --- | --- | --- |
| 1 | App name | נִיצְנוּץ (Nitznutz), אִי־פֶּלֶא, הוֹפְּלָה, נִיצִי, סַקְרָנִיָּה | Decided for now: keep the working name נִיצְנוּץ and rebrand later; names live in one config file so a rebrand touches no code |
| 2 | Voices for the core lines | One narrator (Nitzi's actor), every character records them, or text-to-speech per character | Decided: every character has its own ElevenLabs voice and speaks all lines; the chosen companion is the guide everywhere |
| 3 | The AI tutor's voice, and saying the child's name | Synthetic voice, or a consented clone of Nitzi's actor; name spoken or shown on screen only | Decided: ElevenLabs. Synthetic or actor clone still open. The child's first name is spoken in lines (owner decision, 2026-10-25); the model only ever sees a placeholder, and a parent reviews the name's vocalised spelling. A consent contract is still needed before any actor clone |
| 4 | Voice answers for ages 3–4 at launch | Yes, limited, or not yet | Decide from the speech evaluation data after the discovery phase |
| 5 | Band C at launch | Full grade 3, or end of grade 2 plus selected grade 3 skills | End of grade 2 plus unit fractions and 10×10 facts; the rest of grade 3 as an update |
| 6 | School conventions | Decided: division as ÷ by default, with `:` selectable in app settings (2026-10-25); = read as שָׁוֶה; × read as כָּפוּל | Use כָּפוּל, the common school word |
| 7 | Direction of pattern rows and story strips | Right-to-left (Hebrew reading order) or left-to-right | Right-to-left, confirmed in child tests |
| 8 | Parent alert when a child says something worrying | Content-free alert, or none | Decided: yes, alerts go to the parent (see Parent controls, analytics & alerts) |
| 9 | "Beat your own record" games in Band C | Include for durable facts only, or none | Include, off by default, with a parent switch |
| 10 | Franchise characters if you go commercial | License them from the rights holder, or original characters only | Original characters for any store release; personal packs stay family-only |
| 11 | Lite-pack import for other parents | Personal builds only, or a "make your own character" feature for everyone | Personal builds only; opening it needs moderation and an IP policy |
| 12 | Launch markets | Israel only, or Israel plus Hebrew-speaking families abroad | Israel first; abroad turns US and EU child-privacy rules into active obligations |
| 13 | App-store age band | Kids Category "5 and under" or "6–8", one app or two | One app for all bands; choose the listing band at submission, since both carry the same Kids Category rules |
| 14 | Holiday and religious content | Prominent, or optional | Present but optional, with a parent setting |
| 15 | Colour-helper symbols | Our own set, or a ColorADD licence | Our own set |
| 16 | Business model | Subscription, family plan, free trial, free content | Decide later; it only affects which packs are gated |

## Sources

The main sources the specialist agents opened, out of about 200 in total. The full lists are in the three specialist reports.

**Curriculum and learning science**

- [Israeli Ministry of Education: kindergarten mathematics curriculum](https://meyda.education.gov.il/files/Mazkirut_Pedagogit/Matematika/TochnitKdamYesodiHeb.pdf)
- [Israeli Ministry of Education: elementary maths curriculum and milestones](https://pop.education.gov.il/tchumey_daat/matmatika/yesodi/oraat-math/tohnit-limudim/)
- [Ministry kindergarten computational thinking materials](https://pop.education.gov.il/kindergarten/topics/computational-thinking/teaching-materials/high-tech/)
- [Ministry guidance on Hebrew numerals](https://meyda.education.gov.il/files/Pop/0files/ivrit_habaah_lashon/pedagogia/shem-mispar.pdf)
- [IES practice guide: Teaching Math to Young Children](https://ies.ed.gov/ncee/wwc/practiceguide/18)
- [Clements & Sarama learning trajectories (summary)](https://www.otffeo.on.ca/en/wp-content/uploads/sites/2/2017/05/Learning_trajectories_math.pdf)
- [CSTA revised PreK–12 computer science standards, draft 2.0](https://csteachers.org/Draft-2.0-Revised-PreK-12-CS-Standards)
- [Hirsh-Pasek et al.: Putting Education in "Educational" Apps](https://www.psychologicalscience.org/publications/educational-apps.html)
- [Kim et al. 2021: meta-analysis of educational apps](https://reacheveryreader.gse.harvard.edu/?p=2498)
- [Ramani, Siegler & Hitti 2012: linear number board games](https://education.umd.edu/sites/default/files/uploads/Ramani%20et%20al.%2C%202012%20%281%29.pdf)
- [Expanding retrieval practice for preschoolers](https://www.learningscientists.org/blog/2022/2/3-1)
- [Gender neutralisation of Hebrew numerals in colloquial speech](https://cris.iucc.ac.il/en/publications/gender-neutralization-in-hebrew-the-case-of-the-numerals-in-collo/)

**Design and UX**

- [NN/g: Touch targets on touchscreens](https://www.nngroup.com/articles/touch-target-size/)
- [Anthony et al. 2013: how children and adults use touchscreens](https://lisa-anthony.com/wp-content/uploads/2013/04/anthony-et-al-jpuc2013.pdf)
- [Joan Ganz Cooney Center / Sesame Workshop: designing touch tablet experiences for preschoolers](https://joanganzcooneycenter.org/?p=19607)
- [Apple Human Interface Guidelines: right to left](https://developer-rno.apple.com/design/human-interface-guidelines/foundations/right-to-left)
- [Open Siddur: Hebrew fonts by diacritic support](https://opensiddur.org/help/fonts/)

**Technology, speech and AI**

- [Flutter supported platforms](https://docs.flutter.dev/reference/supported-platforms)
- [Rive data binding](https://rive.app/docs/runtimes/data-binding)
- [ivrit.ai Hebrew streaming speech model](https://huggingface.co/ivrit-ai/zipformer2-66m-streaming-he)
- [Google Cloud Chirp 3 HD voices](https://docs.cloud.google.com/text-to-speech/docs/chirp3-hd)
- [Azure Speech language support](https://learn.microsoft.com/en-us/azure/ai-services/speech-service/language-support?tabs=tts)
- [Anthropic models overview](https://platform.claude.com/docs/en/models/overview)
- [Anthropic guidelines for organisations serving minors](https://support.claude.com/en/articles/9307344-responsible-use-of-anthropic-s-models-guidelines-for-organizations-serving-minors)
- [Android 16 orientation and resizability changes](https://android-developers.googleblog.com/2025/01/orientation-and-resizability-changes-in-android-16.html)

**Stores, privacy and law**

- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple: Kids apps](https://developer.apple.com/app-store/kids-apps/)
- [Google Play Families policies](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en)
- [Google Play Intellectual Property policy](https://support.google.com/googleplay/android-developer/answer/9888072?hl=en)
- [Hunton: final COPPA rule amendments](https://www.hunton.com/privacy-and-cybersecurity-law-blog/ftc-publishes-final-coppa-rule-amendments)
- [Pearl Cohen: Israel's Amendment 13 to the Privacy Protection Law](https://www.pearlcohen.com/major-amendment-to-israeli-privacy-law-set-to-take-effect/)
