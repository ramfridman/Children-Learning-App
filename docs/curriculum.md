# Curriculum & Pedagogy Plan: Hebrew Learning App for Ages 3–8

Author: Curriculum & Tutoring Lead agent. Date: 24 October 2026. Status: proposal for the coordinator to merge with the Technical plan (tech.md) and the Design plan.

**Numbering note.** At the coordinator's request, this plan adds a section that the original brief did not list: **§5 "Genuine understanding: diagnose → re-teach → revisit"**. As a result, the brief's sections 5–15 are numbered 6–16 here. The two coordinator updates (owner direction on genuine understanding; pluggable characters) run through the whole document. The character rules are in §7.1 and §9.6.

Conventions:
- Skill IDs look like `NUM-A-03`: domain, band, number.
- Misconception tags look like `M-CNT-DOUBLE`.
- Template IDs look like `T05`.
- Understanding-check types are `U1`–`U6`.
- Hebrew is given with nikud where it matters, followed by an English gloss in *italics*.
- "Assumption" marks my own judgement where I found no source.
- Every Hebrew string in this file must still pass the Hebrew language editor (§13.2) before recording.

### Key decisions at a glance

1. **The spine is genuine understanding at the child's own pace.** Every skill runs through one loop: *diagnose → re-teach with a different representation → playful practice → check understanding → revisit*.
   - A skill reaches `fresh_mastery` when the child shows understanding in more than one form. It becomes `durable_mastery` only after a delayed check, at least 7 days later and with a different item, passes. These statuses and the FSRS retention model are tech.md §7's.
   - There is no calendar and no grade lock.
   - There are no timers in Bands A–B, and Band C has only optional "beat your own record" games.
   - "Show me" carries no penalty. (§5)
2. **The syllabus is 208 skills** in 6 domains × 3 bands, plus 8 cross-domain units. Each skill has an ID, a "can do" statement, prerequisites and mastery evidence. Every wrong answer an item offers, and every wrong answer a child is likely to say, is **tagged with the misconception it reveals**, so the engine can trace a failure back to a prerequisite gap. (§4, §5)
3. **The syllabus is aligned to the Israeli Ministry of Education's** kindergarten mathematics curriculum (2010) and the **new elementary mathematics curriculum**. Grades 1–2 already learn under it, and grade 3 joins in 5787 (תשפ"ז, 2026–27).
   - Numbers and operations get about 50% of learning time.
   - CS follows the Ministry's own kindergarten and grade 1–2 computational-thinking programmes and the CSTA standards.
   - Logic and colours go beyond the maths curriculum and are labelled as such. (§3)
4. **There are 25 activity templates**, each with tap and voice interactions, Hebrew accept-lists for spoken answers, error classifiers and difficulty knobs. **Three full lesson scripts** and **36 tagged sample items** show how content is written. (§6, §7)
5. **Tutor scripts are character-neutral.** The core pedagogical lines are written so any companion can say them: they avoid gendering both the listener and the speaker. Each character adds only optional flavour lines (greeting, catchphrase, celebration). Superheroes' "powers" are named maths/logic strategies. A **quiet zone** keeps every character still while the child is thinking. (§7.1, §9.7)

**Interfaces with the technical plan (tech.md) that need a decision.** Each is detailed in the section shown.
- **Spelling convention for vocalised text.** Keep the Hebrew Academy's normative vocalised spelling, which is defective spelling in pointed text (e.g. בֻּבָּה), as tech.md's lexicon already does. The language editor confirms whether early-reader captions should match the reading programme the child's school uses. (§8.4)
- **Division sign.** Israeli elementary textbooks typically write `12 : 3`; tech.md specifies ÷. (§8.6)
- **CS program direction.** I recommend a **vertical, top-to-bottom** program strip. (§8.7)
- **Mirrored signs.** `<` and `>` are bidi-mirrored characters, so they must only ever appear inside LTR math isolates. (§8.6)
- **Voice recognition.** The ASR accept-list must accept non-normative gender agreement, for example שָׁלוֹשׁ כְּלָבִים, as a correct number. (§6)
- **Tutor voice.** A single tutor voice versus pluggable characters' voices is an owner decision. (§15)

## 1. Learning philosophy

Every activity, item, line of voice-over and tutor turn must follow these twelve principles. The content review checklist (§13.3) tests against them.

| # | Principle | What it means in the app |
|---|---|---|
| 1 | **Understanding at the child's own pace matters more than speed or coverage.** | No calendar, no grade lock, no visible timers in Bands A–B. A skill counts as learned only when the child shows it in at least two representations, passes an understanding check, and still has it at a delayed check (durable mastery, §5.7). A child may linger on a skill as long as needed. |
| 2 | **Teach along research-based learning trajectories.** | Skills are ordered by developmental progressions (Clements & Sarama; the IES practice guide's first recommendation, rated "moderate evidence"). Each skill names its prerequisites, and the engine always offers "the next level up" from where the child is. |
| 3 | **Minds-on, not just fingers-on.** | Every tap expresses a mathematical decision: count, compare, predict, plan, check. There are no taps just to advance and no reflex/arcade mechanics. Items where random tapping can succeed (2-choice) never count alone as mastery evidence. |
| 4 | **One idea per screen; protect working memory.** | Each activity introduces at most one new idea. Band A sees ≤3 answer choices and a single-sentence instruction. Nothing decorative moves while the child is thinking. Technology-enhanced storybooks show that hotspots and embedded games distract, while relevant animation and sound help (Takacs et al. meta-analysis). |
| 5 | **Concrete → pictorial → abstract, with many representations.** | Every core skill has ≥3 representations: manipulative, picture or model, story, embodied/song, and symbols. When a child struggles, the engine **switches representation** rather than repeating the same explanation louder (§5.5). |
| 6 | **Diagnose, don't just mark.** | Each wrong option and each likely spoken wrong answer carries a misconception tag. Patterns of tags trigger prerequisite probes and targeted repair (§5.3). |
| 7 | **Errors are information; struggle is productive when there is a safety net.** | There are three tries with escalating hints, and the child always finishes by doing the correct action themselves. No red X, no buzzer, no lives, no "wrong!". |
| 8 | **Retrieval and spacing make learning last.** | Every session opens with retrieval of earlier skills. Spaced checks are scheduled by tech.md's FSRS retention model, at roughly 1 → 3 → 7 → 21 → 60 days for a typical skill, with interleaving from Band B. In preschoolers, expanding retrieval practice more than doubled recall (Fritz et al., summarised by The Learning Scientists). |
| 9 | **Audio-first, tap-always, voice-optional.** | Pre-readers never need to read. Every screen has a replay button. Voice is a delightful extra, with recognition limited to the expected answers. **An unrecognised utterance is never scored as wrong**: young children's speech recognition error rates reach ~35% at ages 4–6 (Learning Agency review). |
| 10 | **Meaningful, and Israeli.** | Contexts come from the children's own lives: the Shabbat/Friday-dinner table, the corner shop (מַכּוֹלֶת) and shekels, the bus, the gan routine, a week that starts on יוֹם רִאשׁוֹן, and Hebrew letter-numbers. Meaning deepens processing (Hirsh-Pasek pillar 3), and IES recommends teaching children to "view and describe their world mathematically". |
| 11 | **Learning is social.** | The tutor asks one short question at a time and listens. Parents get co-play prompts; structured parent–child maths talk with the Bedtime Math app raised first-graders' maths, especially for children of maths-anxious parents. Siblings can play together. |
| 12 | **Praise the process; tie rewards to learning; use no dark patterns.** | Process praise to toddlers predicted later incremental mindset and grade-4 achievement (Gunderson et al. 2018). The child's world grows with *mastery*, never with speed or purchase. There are no streak penalties, loot boxes, countdowns or leaderboards. |

## 2. Learner profiles per band

The profiles below are working assumptions synthesised from the sources. Child testing (§13.4) will refine them. A child is placed by **mastery per domain**, not by age. A 5-year-old can be in Band A for Shapes and Band B for Numbers.

| | **Band A: ages 3–4** (גַּן טְרוֹם־חוֹבָה, pre-K) | **Band B: ages 5–6** (גַּן חוֹבָה → start of כִּתָּה א') | **Band C: ages 7–8** (כִּתּוֹת ב'–ג') |
|---|---|---|---|
| **Attention per activity** | 2–4 min per activity. One idea, 3–5 items, then a change. | 4–7 min per activity, 5–8 items. | 6–10 min per activity. Can sustain a 10–12-item challenge or a multi-step puzzle. |
| **Session length** | Default **8 min**, max 12. AAP guidance is ≤1 h/day of high-quality screen media for ages 2–5, ideally co-viewed. Our share of that should be small. | Default **12 min**, max 15. | Default **15 min**, max 20. A parent can set a different value within each band's limit. |
| **Fine motor** | Tap is reliable. Short drag with large targets is fine; long, precise drags are hard. Avoid pinch, multi-touch and double-tap. Targets ≥ 2 cm on a phone (assumption). Drag must snap generously. | Tap, drag and simple tracing are reliable. Assisted 3–5-year-olds approach older children's skill at drag/tap/trace (Kidscreen summary). Avoid pinch. | Precise drag, multi-object manipulation, and drawing a path through a grid. Pinch is still optional, never required. |
| **Reading** | Pre-reader. Recognises some letters and their own name. Uses **icons and audio only**. Captions are shown only for adults. | Emergent. Some read short words with nikud by the end of the band. Audio is still primary. Text appears as support, **with full nikud**. | Grade 2 decodes pointed text and moves to lexical reading (Share's triplex model). Short instructions with nikud are fine; audio stays available. Grade 3 can read short unpointed sentences, but we keep nikud on content words. |
| **Hebrew language** | Speaks simple clauses. Agreement across phrases is becoming consistent around age 3–4 (Berman & Lustigman). Number–gender agreement is often non-normative, as it is in adult colloquial speech. Knows basic colour words from about age 3. Brown (חוּם) and grey (אָפֹר) come later. | Uses complex sentences and conditionals ("אִם… אָז…"). Understands most instruction verbs. Has the vocabulary for comparisons (יוֹתֵר, פָּחוֹת, הֲכִי). | Can follow two-step instructions and explain reasoning in a sentence ("כִּי…"). Can learn formal terms: מְחֻבָּר, הֶפְרֵשׁ, מַכְפֵּלָה, צֶלַע, קָדְקוֹד. |
| **Mathematical starting point** (Clements & Sarama trajectory levels) | Counts small collections (Corresponder → Counter, small numbers). Perceptual subitizing to 3–4. Recognises AB patterns, and duplicates and extends them by 4. Puts shapes together piece by piece (Piece Assembler). | Counts to 20–30 and objects to 20. Counts back from 10. Conceptual subitizing to 10. Uses a mental number line to 10. Adds and subtracts within 10 with objects. Builds pictures from shapes (Picture Maker). | Counts on and skip-counts. Place value to 100 and then 1,000. Derives facts. Multiplication through equal groups. Moves shapes mentally (slides, flips, turns). |
| **Can** | Match, sort by one attribute, choose among 2–3, imitate a model, follow one-step spoken instructions, do things with the body (clap, point). | Plan 3–6 robot steps, sort by two attributes, compare quantities, use "if-then" in a game, retell a sequence, debug one obvious error. | Plan multi-step solutions, use loops and simple conditions, explain "how I knew", check their own work, handle two-step word problems. |
| **Can't yet (design around it)** | Read, hold more than one instruction, cope with long waits, use left/right labels, work with abstract symbols beyond 1–5, tolerate repeated failure. | Reliably name left/right: the verbal labels come at about ages 6–7. Read instructions independently. Hold large numbers in working memory. Cope with speed pressure. | Take another person's left/right, which is still shaky. Sustain abstract drill without context. Read long text. |
| **Social/motivation** | Loves repetition, a familiar character, being "a helper", and simple cause and effect. Strongly affected by tone of voice. | Loves pretend play, rules, being "big", and collections. Starts comparing self with others, so we avoid leaderboards. | Loves challenge, mastery, secrets and codes, building, and making things for others. Is sensitive to "babyish" design, so Band C needs a more grown-up look. |
| **Voice interaction** | Short answers: one number word, colour or yes/no. Speech recognition is least reliable here, so voice is *encouraged but never needed*. | One- or two-word answers. Can say "שָׁלוֹשׁ" or "הָעִגּוּל הַגָּדוֹל". | Short sentences, including explaining back ("כִּי שֵׁשׁ וְעוֹד אַרְבַּע זֶה עֶשֶׂר"). |

## 3. Alignment with the Israeli curriculum

### 3.1 The official documents we align to

| Document | Status (verified) | Use in this plan |
|---|---|---|
| **תָּכְנִית הַלִּמּוּדִים בְּמָתֵמָטִיקָה לְגַן הַיְלָדִים** (Ministry of Education; 2010/תשע"א) | Mandatory. Replaced the 1995 framework. Three domains: *מֻשַּׂג הַמִּסְפָּר* (number concept), *תְּחוּשָׁה מֶרְחָבִית וְגֵאוֹמֶטְרְיָה* (spatial sense & geometry), *מֻשָּׂגִים כַּמּוּתִיִּים בְּחַיֵּי הַיּוֹם־יוֹם* (everyday quantitative concepts), with problem solving throughout. Its goals are written for the end of גן חובה, with "extensions" (הַרְחָבוֹת) for children who are ready. | Bands A–B. End-of-גן goals = our Band B exit targets. Extensions = Band B "challenge" skills. |
| **New elementary mathematics curriculum** (תָּכְנִית הַלִּמּוּדִים הַחֲדָשָׁה, annotated with *צִיּוּנֵי דֶּרֶךְ*, milestones) | Gradual rollout from תשפ"ה. Grades 1–2 learned under it in תשפ"ו, and **grade 3 joins in תשפ"ז (2026–27)**. Grades 4–6 stay on the 2006 curriculum. Its emphases: procedural fluency balanced with insight, pre-algebraic thinking, and mathematical discourse. Geometry and measurement get ~20% of teaching time. Word problems run throughout the year. | Bands B–C. We follow its milestones and their order. |
| **2006 curriculum** (grades 1–6) | Still in force for grades 4–6. | Background only. |
| **Kindergarten "חֲשִׁיבָה מְחַשּׁוּבִית וְרוֹבּוֹטִיקָה"** (computational thinking & robotics) and the **"הַיְטֶק בְּגַנֵּי הַיְלָדִים"** booklet (2022) | Teaches decomposition, patterns, abstraction, algorithm, sequence, loop (finite/infinite), condition (*אִם… אָז…*) and debugging, through movement games and ScratchJr. It notes that terms such as "abstraction" and "algorithm" are *for the teacher*, not for talk with children. | CS Bands A–B, and our CS vocabulary policy (§8.2). |
| **Elementary computational thinking, grades 1–2** (ScratchJr/Scratch) | Grade 1 units: readiness → environment → planning (algorithm) → repeating actions → "when a character is tapped" (events) → stories → games → touching (condition). Grade 2 adds parallelism, messages and directions. | CS Bands B–C. |

**Cross-checks.**
- **Clements & Sarama learning trajectories** set the developmental order within each skill strand.
- **NCTM Curriculum Focal Points** and **Common Core K–3** catch gaps.
  - Common Core, for example, expects K fluency within 5, "make 10" and 11–19 as ten-and-ones.
  - We include all three. The Israeli grade 1 milestones also stress automatic knowledge of facts to 20.
- **CSTA K–12 standards**:
  - The 2017 1A standards cover algorithms, sequences and loops, decomposition, debugging and data representation.
  - The **revised PreK–12 draft 2.0** targets final publication in summer 2026. It introduces iteration in grade 2 and selection (conditionals) only in grade 3, and spreads AI ideas ("patterns machines use to decide") from K.
  - We introduce simple *if-then* **as an unplugged rule game in Band B**, because the Israeli kindergarten CT booklet does. Formal if-then-else waits for Band C.

### 3.2 Mapping table: Ministry topics → our domains and units

| Ministry topic (level) | Our skills (§4) | Notes |
|---|---|---|
| **Counting aloud** (גן: to 30; extension: beyond 30 and by 2/5/10 to 100; backward from 10) | NUM-A-01/02, NUM-B-01/02/03, NUM-B-17 | Counting milestones in the curriculum: 5 → 10/12 → 20 → 30 → 30+. |
| **Counting objects (מְנִיָּה)**: one-to-one, cardinality (גן: to 20) | NUM-A-03/04/06/09, NUM-B-04/05 | Core of Band A. |
| **Ordinal numbers** (גן: to 6th; extension: to 10th) | NUM-A-13, NUM-B-12 | Hebrew ordinals agree in gender (§8.1). |
| **Estimation** (גן) | NUM-B-15, NUM-C-12 | Grade 1 adds length estimation (MATH-C-17). |
| **Representing quantities, numerals 0–10** (גן; extension to 20) | NUM-A-07/08, NUM-B-06/07/08 | Zero comes after other numbers (curriculum note). |
| **Add/subtract within 10 with objects; equal sharing to 10; "half"** (גן) | MATH-A-01/02/03, MATH-B-01…10 | Grade 1: "two aspects of zero"; half informally. |
| **Repeating patterns** (גן: identify, describe, create) | LOG-A-04…07, LOG-B-01…04, X1 | Patterns sit under *number concept* in the Israeli curriculum; we put them in Logic and cross-link to Numbers. |
| **Spatial relations; simple maps** (גן; maps for 5–6) | SHP-A-08/09, SHP-B-11/12/13, SHP-C-11/12, CS-A/B paths | |
| **Solids & 2D shapes; polygons by sides/vertices; faces; symmetry** (גן) | SHP-A-01…07/10, SHP-B-01…10 | |
| **Relative size, seriation, measurement with arbitrary units** (גן) | MATH-A-04, LOG-A-10, MATH-B-11/12/13 | |
| **Time: daily and cyclical; the clock measures time** (גן) | MATH-A-05, MATH-B-14/15 | |
| **Money: coins and notes; buy/sell play** (גן) | MATH-A-06, MATH-B-16/17 | Coins in circulation: 10 agorot, ½ ₪, 1, 2, 5, 10 ₪. Notes: 20, 50, 100, 200 ₪. |
| **Data: sort, represent, answer questions** (גן) | MATH-A-07, MATH-B-19, COL-B-07, X8 | |
| **Gr. 1 natural numbers to 100**: count to 100, count objects to 50, read/write to 100, by tens, by pairs to 20, compare, `< > =`, number line, even/odd to 20, zero, **letter values א–י** | NUM-B-08…18, NUM-C-01…06 | Letter values (gematria) are a distinctly Israeli item; we include them. |
| **Gr. 1 operations**: ±10 incl. 0; second ten; whole tens; to 20 and beyond; word problems (combine, add, take away, change/עֹדֶף, systematic search, repeated addition); ×/: as repeated addition, sharing and grouping; half; equations by trial | MATH-B-03…10/17/18, MATH-C-01…05, LOG-C-07 | "No particular solution method may be forced" (milestone text), so items accept any strategy. |
| **Gr. 1 measurement**: length (direct, intermediary, arbitrary units and cm, perimeter, estimation); time in whole hours | MATH-B-11/12/15, MATH-C-17 | |
| **Gr. 1 geometry**: straight/curved; polygons by sides; quadrilaterals; rectangle and square; side and vertex; *translation or reflection*; line symmetry | SHP-B-01…04/10, SHP-C-01/02/08 | |
| **Gr. 2 numbers to 1,000**: place value, tens and hundreds, hundred chart, even/odd, letters א–ל to 39 | NUM-C-07…10 | |
| **Gr. 2 operations**: addition table to 9+9; tens; 2-digit ± 1- and 2-digit with and without regrouping; inverse operations; column algorithm; comparison and multi-step word problems; × and : to 6×6 (10×10 for advanced); brackets; money in word problems | MATH-C-01…13, MATH-C-22/24 | |
| **Gr. 2 measurement**: cm/m; area by covering and rectangle area; balance-scale weight in arbitrary units; clock to half and quarter hours; durations | MATH-C-17…20 | |
| **Gr. 2 data**: bar charts of squares (one square per data item) | MATH-C-23, COL-C-06 | |
| **Gr. 2 geometry**: right angles, rectangle, square, solids and their vertices/edges/faces, informal reflection and translation | SHP-C-03/06/07/08 | |
| **Gr. 3 operations**: column ± within 10,000; laws (commutative, associative, distributive) without terminology; 10×10 by heart; × of tens/hundreds; divisibility by 2/3/5/10; column × by 1 digit; division with remainder; order of operations; multiplicative and two-step word problems | NUM-C-11, MATH-C-09…13, MATH-C-24/25 | Column × by 1 digit and divisibility by 3 are **Band C+ enrichment**, outside the launch scope (§13). |
| **Gr. 3 simple fractions**: unit fractions (½ … 1/10, 1/12, 1/60, 1/100) of a whole and of a quantity; comparing unit fractions | MATH-C-14/15/16 | |
| **Gr. 3 measurement**: mm, cm, m, km; g and kg; volume comparison; time to minutes (analog and digital) | MATH-C-17/19/20/21 | |
| **Computational thinking** (גן; grades 1–2) | All CS skills | Ministry CT programme, plus CSTA as a cross-check. |

### 3.3 Where we go beyond, and why

- **Colours.** These are not in the maths curriculum. They belong to kindergarten language, art and science.
  - Colour words are a high-frequency **vocabulary** goal.
  - Colours are an ideal **attribute for sorting and patterns**, which are logic and pre-algebra.
  - From Band B on, colour work becomes **science** (mixing, light and dark) and **data/CS** (colour codes, pixel art).
  - Colours get a smaller share of time in Bands B–C.
- **Logic.** The Israeli curriculum places patterns under number concept and "systematic search" under grade 1 word problems. We gather patterns, classification, if-then, deduction and puzzles into one domain.
  - Patterning in preschool predicts later maths achievement independently of other skills (Rittle-Johnson et al. 2017; Burgoyne et al. 2019, as summarised by IES REL Midwest).
- **Computer science.** The Ministry's CT programmes use ScratchJr. We do the same concepts **without free-form coding**: grid robots, picture programs, debugging, loops and conditions. That is closer to Code.org Course A's unplugged lessons ("Happy Maps", "Happy Loops", "Unspotted Bugs") and to the CSTA K–2 standards.
- **Pace.** Ministry milestones are grade expectations. **We use them as reference points on a continuous map, not as gates.** A 6-year-old who is ready can do grade 2 place value, and an 8-year-old can repair grade 1 make-ten without being labelled "behind".

### 3.4 Time allocation per band (engine default; the adaptive engine may shift ±10%)

| Domain | Band A | Band B | Band C |
|---|---|---|---|
| Numbers | 25% | 25% | 15% |
| Math (operations, measurement, time, money, data) | 10% | 25% | 40% |
| Shapes & space | 20% | 15% | 15% |
| Logic | 15% | 12% | 12% |
| Computer science | 15% | 15% | 15% |
| Colours | 15% | 8% | 3% (mostly inside cross-domain units) |

## 4. Scope & sequence

### 4.1 How to read the tables

**The skill map.** Each domain is a **skill map**, a directed graph of prerequisites. The ordered unit lists below are the default route through it. The engine may take any route that respects prerequisites. A skill never unlocks by age or date. It unlocks when all its prerequisites reach P(L) ≥ 0.8 (tech.md §7.7). The child then learns it to `fresh_mastery`.

**Standard mastery evidence (SE).** Every skill uses this standard unless its row adds something. It is tech.md §7.4's `fresh_mastery` rule, with the curriculum's additions in conditions 2–4. A skill reaches **fresh mastery** when all four conditions hold:
1. the mastery estimate is ≥ 0.95 (tech.md's BKT model);
2. the child has at least **4 independent correct responses over ≥ 2 days** (tech.md), meaning no hint above level 1. **Curriculum addition:** 6 for core skills;
3. those responses come from **at least 2 different representations** (§5.5);
4. the child passes **at least one understanding check** (U1–U6, §5.6).

The skill becomes **`durable_mastery`** when a delayed check at least 7 days later, using a different item from the `variantGroup`, passes (tech.md). The FSRS schedule then keeps checking it (§5.7).
- In 2- and 3-option items, a correct answer counts only when there is no immediate prior wrong answer on the same item, so guessing cannot add up to mastery.
- Spoken answers that the recogniser was not confident about never count as wrong.

**Tag columns.** "Watch for" lists the misconception tags defined in §5.2. Prerequisite IDs may cross domains.

**Spiral.** Each strand reappears in the next band at a higher level. The ↺ column on the strand table (4.8) shows where.

### 4.2 Numbers (NUM)

**Band A: ages 3–4**

| Unit | ID | Can do | Prereqs | Mastery evidence beyond SE | Watch for |
|---|---|---|---|---|---|
| A1 Count with me | NUM-A-01 | Says the counting words 1–5 in order | — | In a song and in tap-along counting | M-CNT-SEQ |
| | NUM-A-02 | Says the counting words 1–10 in order | A-01 | Two contexts; no skipped words | M-CNT-SEQ |
| | NUM-A-03 | Touches each object exactly once while counting (≤5) | A-01 | Scattered and in a line; moving objects allowed | M-CNT-DOUBLE, M-CNT-SKIP |
| | NUM-A-04 | Answers "how many?" with the last number counted (≤5) | A-03 | U4 reversible: also "give me N" | M-CNT-CARD |
| | NUM-A-05 | Instantly recognises 1–3 without counting | — | Flash ≤2 s, three arrangements | — |
| | NUM-A-06 | Counts out N (≤5) from a bigger pile | A-04 | Stops at N; does not take the whole pile | M-CNT-CARD |
| A2 Numbers I see | NUM-A-07 | Matches numerals 1–5 to quantities | A-04 | Both directions (numeral → set, set → numeral) | M-NUM-REV |
| | NUM-A-08 | Picks the numeral 1–5 when it is named | A-01 | — | M-NUM-REV |
| | NUM-A-09 | Counts 6–10 objects with one-to-one and cardinality | A-02, A-04 | Scattered sets | M-CNT-DOUBLE, M-CNT-SKIP |
| | NUM-A-10 | Instantly recognises 4–5 in dice and finger patterns | A-05 | Two pattern types | — |
| A3 More or less | NUM-A-11 | Compares two sets ≤5 by matching: more, fewer, same | A-03 | Includes "same" | M-CNT-SIZE |
| | NUM-A-12 | Compares by counting when the set with more items has the smaller or more crowded objects | A-04, A-11 | U3 transfer (new objects) | M-CNT-SIZE |
| | NUM-A-13 | Uses רִאשׁוֹן/רִאשׁוֹנָה, שֵׁנִי, שְׁלִישִׁי, אַחֲרוֹן (first, second, third, last) | A-02 | Line of animals and a queue | M-ORD-CARD |
| | NUM-A-14 | Knows "none" (אֵין / אֶפֶס) as an empty set | A-04 | "How many birds in the nest?" → 0 | M-NUM-ZERO |

**Band B: ages 5–6**

| Unit | ID | Can do | Prereqs | Mastery evidence beyond SE | Watch for |
|---|---|---|---|---|---|
| B1 Counting further | NUM-B-01 | Counts aloud to 20, including the teens | A-02 | Voice or tap-the-next-number | M-CNT-SEQ |
| | NUM-B-02 | Counts to 30, crossing 19→20 and 29→30 (end-of-גן goal) | B-01 | Starts from 15 and from 25 | M-CNT-DECADE |
| | NUM-B-03 | Counts back from 10 (rocket countdown) | A-02 | Also starts from 7 | M-CNT-SEQ |
| | NUM-B-04 | Counts up to 20 objects in any arrangement, keeping track | A-09 | Scattered sets of 13–20 | M-CNT-DOUBLE, M-CNT-SKIP |
| | NUM-B-05 | Counts out N ≤20 | B-04, A-06 | — | M-CNT-CARD |
| B2 Numerals | NUM-B-06 | Reads 0–10 | A-08 | — | M-NUM-REV |
| | NUM-B-07 | Traces and writes 0–10 with correct stroke direction | B-06 | Trace → dotted → free | M-NUM-REV (mirror) |
| | NUM-B-08 | Reads 11–20 | B-06, B-01 | Distractors include reversed digits (12 vs 21) | M-NUM-REV, M-NUM-TEEN |
| | NUM-B-09 | Sees quantities to 10 on a ten-frame (5 and 3 is 8) | A-10 | Flash ten-frames | — |
| B3 Number relations | NUM-B-10 | Says which of two numbers ≤10 is bigger, with no objects shown | B-06, A-12 | U4 reversible: "which is smaller?" | M-CNT-SIZE |
| | NUM-B-11 | Orders 0–10; finds a missing number; knows "one more" and "one less" | B-10 | — | M-CNT-SEQ |
| | NUM-B-12 | Ordinals to tenth, with the correct gender | A-13 | Masculine and feminine nouns | M-ORD-CARD |
| | NUM-B-13 | Places 0–10 on a number line running left to right | B-11 | Jump and place tasks | M-NL-SPACE, M-NL-DIR |
| | NUM-B-14 | Splits numbers ≤10 into two parts in all the ways | B-09 | U2 "show it another way" | — |
| | NUM-B-15 | Estimates a set ≤20 ("about how many?"), then checks | B-04 | Within ±3 | M-CNT-SIZE |
| B4 Toward 100 | NUM-B-16 | Teen numbers as ten and some ones (14 = 10 and 4) | B-08, B-09 | Two ten-frames and bundles | M-NUM-TEEN |
| | NUM-B-17 | Counts by tens to 100 and by twos to 20 | B-02 | — | M-CNT-DECADE |
| | NUM-B-18 | Even and odd to 20 by pairing | B-04 | Pair up socks | — |

**Band C: ages 7–8**

| Unit | ID | Can do | Prereqs | Mastery evidence beyond SE | Watch for |
|---|---|---|---|---|---|
| C1 Numbers to 100 | NUM-C-01 | Counts to 100 from any number; counts on | B-02, B-17 | Starts at 38, 69, 99 | M-CNT-DECADE |
| | NUM-C-02 | Reads, writes and says numbers to 100 (עֶשְׂרִים וְשָׁלוֹשׁ) | C-01, B-16 | Hear → build → write | M-NUM-REV |
| | NUM-C-03 | Place value: tens and ones; zero holds a place (30 is 3 tens, 0 ones) | C-02 | U2: blocks ↔ digits ↔ words | M-PV-FACE |
| | NUM-C-04 | Compares and orders numbers to 100 with < > = | C-03, B-10 | U5 spot the error | M-PV-FACE, M-SIGN-DIR |
| | NUM-C-05 | Hebrew letter values א–י, then כ and ל (numbers to 39) | B-06 | Reads ט"ו, כ"ג | M-GEM-ORDER |
| | NUM-C-06 | Places numbers on a 0–100 number line | C-03, B-13 | Error ≤ 8 | M-NL-DIR |
| C2 Numbers to 1,000 | NUM-C-07 | Reads and writes 3-digit numbers: hundreds, tens and ones | C-03 | Includes internal zeros (305) | M-PV-FACE, M-PV-ZERO |
| | NUM-C-08 | Skip counts by 2, 5 and 10 from any number, and by 100 | C-07 | Continues number patterns | — |
| | NUM-C-09 | Moves on the hundred chart (+10 is down a row, −10 is up a row) | C-03 | — | — |
| | NUM-C-10 | Even and odd to 1,000; tests rules such as "even + even = even" | B-18, C-07 | U6 explain-back | — |
| C3 Big numbers | NUM-C-11 | Place value and comparison to 10,000 | C-07 | — | M-PV-FACE |
| | NUM-C-12 | Rounds to 10 and 100; estimates | C-06, C-11 | — | — |

### 4.3 Colours (COL)

| Band / unit | ID | Can do | Prereqs | Mastery evidence beyond SE | Watch for |
|---|---|---|---|---|---|
| **A1 Find the colour** | COL-A-01 | Matches identical colours | — | — | — |
| | COL-A-02 | Points to red, blue, yellow and green when they are named | A-01 | Across different objects | M-COL-NAME |
| | COL-A-03 | Points to orange, purple, pink, black and white | A-02 | — | M-COL-NAME |
| | COL-A-04 | Sorts by colour, ignoring shape and size | A-01 | Conflicting shapes and sizes | M-SORT-SHIFT |
| **A2 Colourful world** | COL-A-05 | Knows the usual colours of familiar things, and that they can vary (green and yellow bananas) | A-02 | — | M-COL-OBJECT |
| | COL-A-06 | Identifies brown and grey | A-03 | — | M-COL-NAME |
| | COL-A-07 | Finds an object by colour and noun ("the red doll" among red balls and blue dolls) | A-02 | Both noun genders | M-COL-ONEATTR |
| | COL-A-08 | Colours by a key (1 = red, 2 = blue) | A-02, NUM-A-08 | Cross-domain: Numbers | — |
| **B1 Mix & shade** | COL-B-01 | Predicts orange, green and purple from mixing primaries | A-03 | Predict, then mix to check | M-COL-MIX |
| | COL-B-02 | Orders 3–5 shades of one colour from light to dark (בָּהִיר → כֵּהֶה) | A-03 | — | M-COL-SHADE |
| | COL-B-03 | Knows that light blue and dark blue are both blue (תְּכֵלֶת is a light blue) | B-02 | U3 transfer: greens, reds | M-COL-SHADE |
| | COL-B-04 | Sorts by colour and shape in a 2×2 grid | A-04, SHP-A-03 | Cross-domain: Logic | M-SORT-SHIFT |
| | COL-B-05 | Uses colour as a code: a map key, traffic-light rules | A-02 | — | — |
| | COL-B-06 | Puts the rainbow in order | B-01 | — | — |
| | COL-B-07 | Counts colours in a set and makes a picture graph | A-04, NUM-B-04 | Cross-domain: Math data | — |
| **C1 Colour science & code** | COL-C-01 | Predicts tints (add white) and shades (add black), and mixes of secondary + primary colours | B-01, B-02 | — | M-COL-SHADE, M-COL-MIX |
| | COL-C-02 | Pixel art: colours a grid from a row code | B-05, CS-B-08 | Cross-domain: CS | M-DIR-RTL |
| | COL-C-03 | Colour by answer: maths facts map to a colour key | B-05 | Practice wrapper | — |
| | COL-C-04 | Completes a symmetric coloured design | SHP-C-08 | — | M-SYM-SHIFT |
| | COL-C-05 | Reads a colour-coded chart and its legend | B-07 | — | — |
| | COL-C-06 | Collects colour data and builds a bar chart of squares | B-07 | Grade 2 data milestone | — |

### 4.4 Shapes & space (SHP)

| Band / unit | ID | Can do | Prereqs | Mastery evidence beyond SE | Watch for |
|---|---|---|---|---|---|
| **A1 Shape friends** | SHP-A-01 | Matches identical circles, squares and triangles | — | — | — |
| | SHP-A-02 | Names circle (עִגּוּל), square (רִבּוּעַ) and triangle (מְשֻׁלָּשׁ) in typical form | A-01 | — | — |
| | SHP-A-03 | Recognises shapes in any size and orientation, including thin and tilted triangles | A-02 | U3: rotated and scaled | M-SHP-ORIENT, M-SHP-PROTO, M-SHP-SIZE |
| | SHP-A-04 | Recognises a rectangle (מַלְבֵּן) and tells it from a square informally | A-02 | — | M-SHP-SQRECT |
| | SHP-A-05 | Finds shapes in the world (window, plate, sign) | A-03 | Photos and drawings | M-SHP-PROTO |
| **A2 Build it** | SHP-A-06 | Fills an outline puzzle where each piece is outlined | A-01 | Rotation snaps | — |
| | SHP-A-07 | Ball (כַּדּוּר) vs box/cube (קֻבִּיָּה): rolls or stacks? | — | — | — |
| **A3 Where is it?** | SHP-A-08 | Understands עַל, מִתַּחַת, בְּתוֹךְ, לְיַד, מֵעַל (on, under, in, next to, above) | — | Tap and drag | — |
| | SHP-A-09 | Understands בֵּין, לִפְנֵי, מֵאָחוֹר, לְמַעְלָה, לְמַטָּה (between, in front of, behind, up, down) | A-08 | — | M-DIR-EGO |
| | SHP-A-10 | Tells straight lines from curved ones (יָשָׁר / עָקֹם) | A-02 | — | — |
| **B1 Shape detectives** | SHP-B-01 | Identifies triangles, quadrilaterals (מְרֻבָּע), pentagons (מְחֻמָּשׁ) and hexagons (מְשֻׁשֶּׁה) by counting sides | A-03, NUM-A-09 | Includes "not-shapes" (an open figure, a curved side) | M-SHP-CLOSED, M-SHP-PROTO |
| | SHP-B-02 | Counts sides (צְלָעוֹת) and vertices (קָדְקוֹדִים) | B-01 | — | M-CNT-DOUBLE |
| | SHP-B-03 | Square vs rectangle: a square has all sides equal | A-04, B-02 | — | M-SHP-SQRECT |
| | SHP-B-04 | Sorts polygons from non-polygons (closed, straight sides) | B-01, A-10 | — | M-SHP-CLOSED |
| **B2 Shape builder** | SHP-B-05 | Makes pictures from shapes with no inner outlines | A-06 | — | — |
| | SHP-B-06 | Substitutes shapes: two triangles make a square | B-05 | U2 | — |
| | SHP-B-07 | Cuts a shape into given parts | B-06 | — | — |
| **B3 Solids & mirrors** | SHP-B-08 | Names cube (קֻבִּיָּה), box (תֵּבָה), cylinder (גְּלִיל), cone (חָרוּט), sphere (כַּדּוּר) and pyramid (פִּירָמִידָה) | A-07 | — | — |
| | SHP-B-09 | Matches a solid to its face by "stamping" | B-08, A-03 | — | — |
| | SHP-B-10 | Completes a mirror-symmetric picture; says whether a shape is symmetric | A-03 | — | M-SYM-SHIFT |
| **B4 Maps & positions** | SHP-B-11 | Follows and gives "forward, back, turn" (קָדִימָה, אֲחוֹרָה, הִסְתּוֹבֵב) | A-09 | — | — |
| | SHP-B-12 | Right and left (יָמִין, שְׂמֹאל) on own body, with an anchor (§8.7) | B-11 | Two sessions | M-DIR-LR |
| | SHP-B-13 | Uses a simple map of a familiar place to find a route | B-11 | Maps suit ages 5–6 (Ministry) | M-DIR-EGO |
| **C1 Properties** | SHP-C-01 | Classifies quadrilaterals: square, rectangle, rhombus (מְעֻיָּן), kite (דַּלְתּוֹן), trapezoid (טְרַפֵּז) | B-03 | — | M-SHP-SQRECT, M-SHP-ORIENT |
| | SHP-C-02 | Line (יָשָׁר) vs segment (קֶטַע); broken lines | B-04 | — | — |
| | SHP-C-03 | Finds right angles (זָוִית יְשָׁרָה) with a "corner tester" | C-01 | — | M-SHP-ORIENT |
| | SHP-C-04 | Composes repeating units; tiles a region | B-06 | — | — |
| | SHP-C-05 | Counts hidden shapes: "how many triangles are in this figure?" | B-07 | — | M-CNT-SKIP |
| **C2 Solids** | SHP-C-06 | Counts faces (פֵּאוֹת), edges (מִקְצוֹעוֹת) and vertices of solids | B-09 | — | M-CNT-DOUBLE |
| | SHP-C-07 | Matches nets to cubes and boxes | C-06 | — | — |
| **C3 Moves** | SHP-C-08 | Translation (הֲזָזָה) and reflection (שִׁקּוּף); line of symmetry | B-10 | — | M-SYM-SHIFT |
| | SHP-C-09 | Quarter and half turns (סִבּוּב); mental rotation | C-08 | — | M-SHP-ORIENT |
| | SHP-C-10 | Builds a shape to a spec ("4 sides, one right angle") on a geoboard | C-03 | — | — |
| **C4 Maps** | SHP-C-11 | Grid coordinates (letter + number, like a game board) | B-13 | — | M-DIR-RTL |
| | SHP-C-12 | Takes the robot's or a friend's perspective for right and left | B-12, CS-B-10 | U3 | M-DIR-EGO, M-DIR-LR |

### 4.5 Logic (LOG)

| Band / unit | ID | Can do | Prereqs | Mastery evidence beyond SE | Watch for |
|---|---|---|---|---|---|
| **A1 Same & different** | LOG-A-01 | Finds the one that is the same | — | — | — |
| | LOG-A-02 | Finds the odd one out by one attribute | A-01 | Colour, shape and size | M-SORT-SHIFT |
| | LOG-A-03 | Sorts into two groups by a given rule | A-01 | — | M-SORT-SHIFT |
| **A2 Patterns** | LOG-A-04 | Recognises a repeating pattern: "is it a pattern?" | A-01 | — | — |
| | LOG-A-05 | Copies an AB pattern | A-04 | — | M-PAT-COPY |
| | LOG-A-06 | Extends an AB pattern (what comes next?) | A-05 | Colour, shape, sound and movement | M-PAT-NEXT |
| | LOG-A-07 | Fixes a broken AB pattern | A-06 | — | M-PAT-NEXT |
| **A3 Order & pairs** | LOG-A-08 | Orders a 3-picture story (first, then, finally) | NUM-A-13 | — | M-SEQ-CAUSE |
| | LOG-A-09 | Matches things that go together (sock and shoe) | — | Explains by voice (Band B) | — |
| | LOG-A-10 | Orders 3–4 objects by size (seriation) | A-01 | — | M-SER-ENDS |
| **B1 Pattern makers** | LOG-B-01 | Extends ABB, AAB, ABC and ABCD patterns | A-06 | — | M-PAT-NEXT |
| | LOG-B-02 | Finds the pattern unit (the "core") | B-01 | U2: show it in another material | M-PAT-UNIT |
| | LOG-B-03 | Translates a pattern between modalities (red-blue → clap-stomp → A-B) | B-02 | U2 | M-PAT-UNIT |
| | LOG-B-04 | Growing patterns: 1, 2, 3 blocks… | B-01, NUM-B-11 | — | M-PAT-GROW |
| **B2 Sort & classify** | LOG-B-05 | Sorts by two attributes (2×2 table) | A-03 | — | M-SORT-SHIFT |
| | LOG-B-06 | Finds the sorting rule ("how did I sort?") | B-05 | — | — |
| | LOG-B-07 | Venn diagram with two rings and an overlap | B-05 | — | M-SORT-OVERLAP |
| **B3 Think it through** | LOG-B-08 | If-then rules in a game ("if it's red, put it in the box") | B-05 | — | M-IF-REVERSE |
| | LOG-B-09 | Simple deduction: "it's not red and not a circle — which is it?" | B-05 | — | M-NOT |
| | LOG-B-10 | 4×4 picture sudoku | A-02 | — | — |
| | LOG-B-11 | Seriation of 5–7 items; inserting a new one in order | A-10 | — | M-SER-ENDS |
| | LOG-B-12 | Sequences with causes ("what happened before?") | A-08 | — | M-SEQ-CAUSE |
| **C1 Rules & codes** | LOG-C-01 | Number and shape patterns with a rule (+2, ×2, alternating) | B-04, NUM-C-08 | U6 explain the rule | M-PAT-GROW |
| | LOG-C-02 | Function machine: in → out, find the rule | C-01 | U4 reversible | — |
| | LOG-C-03 | Uses "and", "or", "not" in classification | B-07, B-09 | — | M-NOT, M-SORT-OVERLAP |
| **C2 Puzzles** | LOG-C-04 | Logic grids (3 children × 3 pets) | B-09 | — | — |
| | LOG-C-05 | 6×6 sudoku; KenKen-style sums | B-10, MATH-C-01 | — | — |
| | LOG-C-06 | Truth-teller puzzles and "which clue is useless?" | C-03 | — | — |
| | LOG-C-07 | Systematic search: finds all combinations (3 shirts × 2 hats) | B-05 | Grade 1 milestone "חִפּוּשׂ שִׁיטָתִי" (systematic search) | M-SEARCH-MISS |
| | LOG-C-08 | Analogies: A is to B as C is to ? | B-06 | — | — |

### 4.6 Computer science (CS)

Every CS activity is unplugged-style: arrows, picture cards and robots on a grid. There is no typing. **The program strip runs top to bottom** (§8.7).

| Band / unit | ID | Can do | Prereqs | Mastery evidence beyond SE | Watch for |
|---|---|---|---|---|---|
| **A1 Step by step** | CS-A-01 | Orders 3 picture steps of a routine (wash hands, brush teeth) | LOG-A-08 | — | M-SEQ-CAUSE |
| | CS-A-02 | Follows a spoken 1–2 step instruction with the body ("jump, then clap") | — | Embodied | — |
| | CS-A-03 | Moves a robot one step at a time by tapping arrows (direct control) | SHP-A-09 | Up, down and toward the landmark | M-DIR-EGO |
| | CS-A-04 | Plans a 2–3 step path, then presses "go" | CS-A-03 | — | M-CS-OFF1 |
| **A2 Oops-fixers** | CS-A-05 | Spots the step that is wrong in a picture sequence | A-01 | — | — |
| | CS-A-06 | Notices that the robot did something different from the plan | A-04 | "The robot made a mistake!" | — |
| | CS-A-07 | Repeats a movement pattern (dance) — a pre-loop | LOG-A-06 | — | — |
| **B1 Program the robot** | CS-B-01 | Plans 4–6 step paths in a 4×4 grid | A-04 | — | M-CS-OFF1, M-DIR-LR |
| | CS-B-02 | Turns: the robot turns relative to *its own* heading | B-01, SHP-B-12 | Robot faces different ways | M-DIR-EGO, M-DIR-LR |
| | CS-B-03 | Predicts where a given program will end | B-01 | U4 reversible | M-CS-OFF1 |
| | CS-B-04 | Debugs one wrong step in a program | B-03 | — | M-CS-FIXALL |
| **B2 Repeat it** | CS-B-05 | Finds the repeating part of a dance or path | A-07, LOG-B-02 | — | M-PAT-UNIT |
| | CS-B-06 | Uses a repeat block (×2–×4) to shorten a program | B-05 | Shows it can count steps | M-LOOP-COUNT |
| | CS-B-07 | Events: "when you tap the frog, it jumps" (cause → action) | — | — | — |
| **B3 Rules & data** | CS-B-08 | Follows a picture code: an arrow sequence draws a picture | B-01 | — | M-DIR-RTL |
| | CS-B-09 | If-then rule cards in a game ("if the light is red, stop") | LOG-B-08 | — | M-IF-REVERSE |
| | CS-B-10 | Breaks a big task into parts (decomposition): "first get the key, then the door" | B-01 | — | — |
| **C1 Smart programs** | CS-C-01 | Writes programs of 8–12 steps with obstacles; finds the shortest path | B-01 | — | M-CS-OFF1 |
| | CS-C-02 | Nested reasoning: a loop that holds a turn (draw a square) | B-06 | — | M-LOOP-COUNT |
| | CS-C-03 | Debugs programs with two errors or with a loop error | B-04, C-02 | U5 | M-CS-FIXALL |
| **C2 Conditions & events** | CS-C-04 | if-then-else ("if there's a wall, turn; otherwise go forward") | B-09 | — | M-IF-REVERSE |
| | CS-C-05 | Sensor/event programs: the robot reacts to a coloured tile | C-04, COL-B-05 | — | — |
| | CS-C-06 | Repeat-until (a loop with a stop condition) | C-02, C-04 | — | M-LOOP-COUNT |
| **C3 Data & machines** | CS-C-07 | Variables as a box with a number (score, counter) | MATH-C-01 | CSTA 1A-AP-09 | — |
| | CS-C-08 | Encodes and decodes a binary-picture/pixel message | COL-C-02 | — | — |
| | CS-C-09 | Teaches a "machine" to sort by examples, and sees how it can be wrong | LOG-B-06 | AI idea from the CSTA draft | M-AI-MAGIC |
| | CS-C-10 | Writes a simple algorithm for a daily task, then checks it with a peer or parent | B-10 | — | — |

### 4.7 Math: operations, measurement, time, money, data (MATH)

**Band A: ages 3–4**

| Unit | ID | Can do | Prereqs | Mastery evidence beyond SE | Watch for |
|---|---|---|---|---|---|
| A1 More & gone | MATH-A-01 | Adding 1 or 2 to a small set: "how many now?" (≤5) | NUM-A-04 | Concrete only | M-ADD-RECOUNT (OK at A) |
| | MATH-A-02 | Taking 1 away from a small set (≤5) | NUM-A-04 | Concrete only | — |
| | MATH-A-03 | Shares fairly between two friends (≤6) | NUM-A-06 | — | M-SHARE-UNEQ |
| A2 Big & small | MATH-A-04 | Compares big/small, long/short, tall/short, heavy/light (כָּבֵד / קַל) | — | — | M-MEAS-ALIGN |
| A3 My day | MATH-A-05 | Orders morning, noon, evening and night; before and after | LOG-A-08 | — | — |
| A4 The shop | MATH-A-06 | Pretend-shop play: gives one coin per item | NUM-A-03 | Coins as tokens | — |
| A5 Picture graph | MATH-A-07 | Sorts and compares groups in a picture chart ("which do we have more of?") | LOG-A-03, NUM-A-11 | — | — |

**Band B: ages 5–6**

| Unit | ID | Can do | Prereqs | Mastery evidence beyond SE | Watch for |
|---|---|---|---|---|---|
| B1 Join & take away | MATH-B-01 | Story problems "join" and "take away" within 10 with objects | MATH-A-01/02, NUM-B-05 | Any strategy accepted | M-ADD-RECOUNT |
| | MATH-B-02 | Part-part-whole within 10 (missing part, with objects) | NUM-B-14 | U4 reversible | M-PPW |
| | MATH-B-03 | Reads and writes + − = in number sentences ≤10 | B-01, NUM-B-06 | Symbol ↔ picture | M-EQ-OPER, M-SUB-ORDER |
| | MATH-B-04 | Counts on from the larger addend | B-01, NUM-B-01 | Observed in the hint trace | M-ADD-RECOUNT |
| | MATH-B-05 | Facts within 5, then within 10, become automatic | B-03 | Answers within ~3 s, *measured silently, never shown* | — |
| | MATH-B-06 | Makes 10: pairs that make ten | NUM-B-09 | Ten-frame | — |
| | MATH-B-07 | Zero in addition and subtraction ("two aspects of zero") | B-03, NUM-A-14 | — | M-NUM-ZERO |
| B2 Into the teens | MATH-B-08 | Add/subtract within 20 using ten (8+5 = 8+2+3) | B-06, NUM-B-16 | No method forced | M-ADD-RECOUNT |
| | MATH-B-09 | The equals sign as "same as" (3+4 = 5+2; 7 = 3+4) | B-03 | U5 | M-EQ-OPER |
| | MATH-B-10 | Equal groups: repeated addition, sharing and grouping (≤20) | MATH-A-03, NUM-B-17 | Both kinds of division problem | M-SHARE-UNEQ |
| B3 Measure | MATH-B-11 | Compares length directly and through an intermediary (a string) | MATH-A-04 | — | M-MEAS-ALIGN |
| | MATH-B-12 | Measures with arbitrary units (clips, footsteps) | B-11, NUM-B-04 | No gaps or overlaps | M-MEAS-GAP, M-MEAS-UNIT |
| | MATH-B-13 | Compares weight on a balance | MATH-A-04 | — | M-MEAS-BIG |
| B4 Time | MATH-B-14 | Days of the week (יוֹם רִאשׁוֹן … שַׁבָּת); today, yesterday, tomorrow | MATH-A-05 | — | — |
| | MATH-B-15 | Reads an analog clock to whole hours (grade 1) | NUM-B-08 | — | M-CLOCK-HANDS |
| B5 Shop & coins | MATH-B-16 | Recognises Israeli coins and notes (10 agorot, ½ ₪, ₪1, 2, 5, 10; notes 20, 50) | NUM-B-06 | — | M-MONEY-SIZE |
| | MATH-B-17 | Pays an exact amount ≤10 ₪ with ₪1, 2, 5 and 10 coins; simple change (עֹדֶף) | B-16, B-03 | — | M-MONEY-COUNT |
| B6 Puzzles & data | MATH-B-18 | Solves simple equations by trial and check (□ + 3 = 7) | B-02 | — | M-EQ-OPER |
| | MATH-B-19 | Makes and reads a pictograph or bar of squares; answers "how many more?" | MATH-A-07, NUM-B-10 | — | M-COMP-DIFF |

**Band C: ages 7–8**

| Unit | ID | Can do | Prereqs | Mastery evidence beyond SE | Watch for |
|---|---|---|---|---|---|
| C1 Addition table | MATH-C-01 | Addition and subtraction facts to 9+9, automatic (grades 1–2) | B-08 | Silent latency measure; no timer shown | M-ADD-RECOUNT |
| | MATH-C-02 | Inverse relation: 9+6=15 → 15−6=9; fact families | C-01 | U4 | M-SUB-ORDER |
| | MATH-C-03 | Whole tens ± (40+30 is like 4+3 tens) | C-01, NUM-C-03 | — | M-PV-FACE |
| C2 Two-digit ± | MATH-C-04 | 2-digit ± 1-digit, without and then with regrouping, mentally | C-03 | Number line and blocks | M-SUB-SMALLBIG, M-PV-FACE |
| | MATH-C-05 | 2-digit ± 2-digit, with and without regrouping | C-04 | — | M-SUB-SMALLBIG, M-REGROUP-FORGET |
| | MATH-C-06 | Column algorithm (grade 2; to 1,000/10,000 in grade 3) | C-05, NUM-C-07 | U5 error-spot | M-SUB-SMALLBIG, M-REGROUP-FORGET, M-COLM-ALIGN |
| | MATH-C-07 | Word problems: combine, change, compare ("how many more?"), multi-step, extra information | C-02 | Writes own problem (U6) | M-COMP-DIFF, M-KEYWORD |
| | MATH-C-08 | Missing-number equations; equivalent expressions (8+7 = 10+5) | B-09, C-02 | — | M-EQ-OPER |
| C3 × and : | MATH-C-09 | Multiplication as equal groups and arrays; commutativity (3×4 = 4×3) | B-10 | U2 groups ↔ array ↔ jumps | M-MUL-ADD |
| | MATH-C-10 | Division: sharing and grouping, linked to × | C-09 | U4 | M-SHARE-UNEQ |
| | MATH-C-11 | Multiplication table to 6×6, then to 10×10 (grade 3 by heart) | C-09 | Durable mastery is the key | M-MUL-ADD |
| | MATH-C-12 | × with 0 and 1; × by 10 | C-11 | — | M-MUL-ZERO |
| | MATH-C-13 | Division with a remainder within 100 | C-10, C-11 | — | M-REM-BIG |
| C4 Fractions | MATH-C-14 | Halves and quarters of a shape: equal parts only | MATH-B-10, SHP-B-07 | Non-examples (unequal parts) | M-FRAC-UNEQ |
| | MATH-C-15 | Unit fractions ½ … 1/10 of a whole and of a quantity (⅓ of 21 = 7) | C-14, C-10 | — | M-FRAC-BIGDEN |
| | MATH-C-16 | Compares unit fractions (⅓ > ¼) | C-15 | U6 explain | M-FRAC-BIGDEN |
| C5 Measure | MATH-C-17 | Measures length with a ruler (cm, m), starting at 0; estimates | MATH-B-12 | — | M-RULER-1, M-MEAS-UNIT |
| | MATH-C-18 | Area by covering with squares; perimeter; equal area ≠ equal perimeter | C-17, C-09 | — | M-AREA-PERIM |
| | MATH-C-19 | Weight in g and kg; balance scales | MATH-B-13 | — | M-MEAS-BIG |
| | MATH-C-20 | Clock to the half and quarter hour, then to the minute; durations | MATH-B-15, NUM-C-08 | Analog and digital | M-CLOCK-HANDS, M-TIME-BASE |
| | MATH-C-21 | Volume comparison by filling | MATH-B-11 | — | M-MEAS-TALL |
| C6 Money & data | MATH-C-22 | Shekels and agorot: prices, totals and change to 100 ₪ | MATH-B-17, C-05 | — | M-MONEY-COUNT |
| | MATH-C-23 | Bar charts of squares: build, read, compare, predict | MATH-B-19 | — | M-COMP-DIFF |
| C7 Order & laws | MATH-C-24 | Brackets; then order of operations (× and : before + and −) | C-08, C-11 | — | M-OOO-LTR |
| | MATH-C-25 | Two-step and multiplicative word problems | C-07, C-10 | U6 | M-KEYWORD |

### 4.8 Cross-domain units

| # | Unit | Bands | Combines | Skills practised | Example |
|---|---|---|---|---|---|
| X1 | **צִבְעֵי דֻּגְמָה** — Colourful patterns | A–B | Colours + Logic | COL-A-02, LOG-A-06, LOG-B-01/03 | Bead necklace: red-yellow-red-yellow… "what comes next?" Then make it a clap pattern. |
| X2 | **הָרוֹבּוֹט סוֹפֵר** — The robot counts | A–B | CS + Numbers | CS-A-04, CS-B-06, NUM-A-09, NUM-B-13 | The robot walks the number line; "3 steps forward" = +3; a repeat block becomes "jumps of 2". |
| X3 | **בַּיִת שֶׁל צוּרוֹת** — Shape houses | A–B | Shapes + Colours + Logic | SHP-A-03, COL-B-04, LOG-B-05 | Sort shapes into houses by colour × shape (2×2). |
| X4 | **הַמַּכּוֹלֶת שֶׁל הַשְּׁכוּנָה** — The neighbourhood shop | B–C | Math money + Numbers + Logic | MATH-B-17, MATH-C-22, LOG-C-07 | Buy items for a Friday picnic within a budget; find all the ways to pay ₪7. |
| X5 | **פִּיקְסֶלִים** — Pixel painter | B–C | CS + Colours + Shapes | CS-B-08, COL-C-02, SHP-C-08 | Follow a colour code to draw a symmetric butterfly. |
| X6 | **הַמִּטְבָּח שֶׁל סַבְתָּא** — Grandma's kitchen | B–C | Math measurement + CS algorithm | MATH-B-12, MATH-C-15, CS-C-10 | Recipe as an algorithm; half a cup; ordering steps. |
| X7 | **מְרוּץ עַל לוּחַ הַמִּסְפָּרִים** — Number-track race | A–B | Numbers + Logic (game) | NUM-B-13, NUM-A-12 | A linear 1–10 board game. Linear (not circular) number board games improved number-line estimation, magnitude comparison and numeral identification (Ramani, Siegler & Hitti 2012). |
| X8 | **סְקָר בְּגַן הַחַיּוֹת** — Zoo survey | B–C | Math data + Colours + CS data | MATH-B-19, COL-C-06, MATH-C-23 | Count animals by colour; make a bar chart; "which is most common?" |

### 4.9 Strand spiral (where each idea returns)

| Strand | Band A | Band B | Band C |
|---|---|---|---|
| Counting & cardinality | to 5, then 10; one-to-one | to 30; counting back; to 20 objects | to 100+; counting on; skip counting |
| Subitizing → structure | 1–3, then 4–5 | ten-frames; splitting numbers | place value; arrays |
| Comparing | by matching | numerals to 10; number line 0–10 | to 100 and 10,000 with < > =; rounding |
| Operations | add 1, take 1 away (concrete) | join and separate to 10; make ten; equals as "same" | facts to 9+9; 2-digit; × and :; laws |
| Patterns → algebra | AB patterns | ABB/ABC; the core unit; growing patterns | rules; function machine; missing-number equations |
| Shapes | name 3 shapes; any orientation | count sides; polygons; compose; solids | quadrilateral families; angles; nets; moves |
| Space & direction | on/under/next to | right and left (own body); maps | perspective; grid coordinates |
| Algorithms | 3-step routine; 2–3-step robot path | 4–6-step programs; debugging; repeat | 8–12 steps; nested loops; if-else; variables |
| Measurement | big/small, heavy/light | arbitrary units; balance; whole hours | cm/m, g/kg; minutes; area and perimeter |
| Money | tokens: one coin per item | coins to ₪10; change | ₪ and agorot to ₪100 |
| Data | picture sorting | pictographs | bar charts; predictions |
| Fractions | fair sharing | half informally | unit fractions; comparing |

**Totals.**

| Domain | A | B | C | Total |
|---|---|---|---|---|
| NUM | 14 | 18 | 12 | 44 |
| COL | 8 | 7 | 6 | 21 |
| SHP | 10 | 13 | 12 | 35 |
| LOG | 10 | 12 | 8 | 30 |
| CS | 7 | 10 | 10 | 27 |
| MATH | 7 | 19 | 25 | 51 |
| **Total** | **56** | **79** | **73** | **208 skills** |

There are also 8 cross-domain units. The MVP subset is in §13.1.

## 5. Genuine understanding: diagnose → re-teach → revisit

This section is the spine of the product. Every other section serves it.

### 5.1 The loop

```
 ┌──────────── PROBE ────────────┐
 │ placement / retrieval / item  │
 └──────────────┬────────────────┘
                ▼
     answer + tags + hint trace
                ▼
 ┌────────── DIAGNOSE ───────────┐   no pattern → keep practising
 │ which misconception? which    │──────────────────────────────┐
 │ prerequisite is weak?         │                              │
 └──────────────┬────────────────┘                              │
                ▼                                               │
 ┌────────── RE-TEACH ───────────┐                              │
 │ switch REPRESENTATION (§5.5)  │                              │
 │ or repair PREREQUISITE (§5.3) │                              │
 └──────────────┬────────────────┘                              │
                ▼                                               ▼
 ┌────────── PLAYFUL PRACTICE ──── varied items, interleaved ──────┐
 └──────────────┬──────────────────────────────────────────────────┘
                ▼
 ┌────── CHECK UNDERSTANDING (U1–U6, §5.6) ──────┐
 └──────────────┬────────────────────────────────┘
                ▼
   FRESH MASTERY ──(delayed checks 1·3·7·21·60 d)──► DURABLE MASTERY
                ▲                                       │ check fails
                └──── gentle re-teach, new representation ◄┘
```

**Self-paced by design.**
- Nothing advances by date. A child may stay on a skill for weeks.
- The map shows the skill as a growing plant (🌱 → 🌿 → 🌳), never as "behind".
- **No timers in Bands A–B.** Band C has an optional "beat your own record" game for *already durable* facts only, never against others, and parents can switch it off. Response latency is measured silently for fluency and is never shown.
- **"Show me" (הַרְאוּ לִי) carries no penalty.** Every item has a "?" helper button. Tapping it, or saying "לֹא יוֹדֵעַ / לֹא יוֹדַעַת / תַּרְאֶה לִי / תַּרְאִי לִי / עֶזְרָה" (*don't know / show me / help*):
  - plays a worked demonstration;
  - logs "help-seeking", which counts as positive behaviour, not failure;
  - gives a fresh, similar item.
  
  "Show me" is recorded as tech.md's `unsure` outcome: weak evidence of not-yet-mastered, with no misconception evidence. It **never** counts as a wrong answer and never breaks a "flow" celebration.

### 5.2 Misconception catalogue (with diagnostic signals)

Every distractor and every likely spoken wrong answer carries one of these tags. Authors pick from this list; new tags need curriculum-lead approval. "Repair" names the representation the engine switches to (R codes in §5.5).

| Tag | What the child does | Signal (tagged distractor / spoken answer) | Trace back to | Repair |
|---|---|---|---|---|
| M-CNT-SEQ | Says counting words out of order or skips them (1,2,3,5) | Selects 5 when there are 4; sung sequence breaks | NUM-A-01/02 | R4 counting song with gesture; tap-along |
| M-CNT-DOUBLE | Counts an object twice | Answer = n+1 or n+2 in scattered sets; the tap log shows a repeat tap | NUM-A-03 | R1 "move each one to the basket" (touch-and-move) |
| M-CNT-SKIP | Misses an object | Answer = n−1 in scattered sets | NUM-A-03 | R1 move-to-basket; objects light up as they are counted |
| M-CNT-CARD | Recounts instead of giving the total, or answers with a different number | Answer ≠ last word said; on "give me 4" takes all | NUM-A-04 | R2 "the last number tells how many" (a bubble over the whole set); R4 hold up fingers |
| M-CNT-SIZE | Judges "more" by size or spread instead of number | Picks the bigger-looking or more spread-out set | NUM-A-11/12 | R1 one-to-one pairing with lines; then counting |
| M-CNT-DECADE | Stuck at a decade change (…28, 29, 20-10?) | Spoken "עֶשְׂרִים וְעֶשֶׂר"; selects 20 after 29 | NUM-B-17 | R2 hundred-chart row ending; R1 bundle of ten |
| M-NUM-REV | Reverses digits or mirrors numerals | Selects 21 for 12; traces a backward 3 | NUM-B-08, NUM-C-02 | R2 tens-and-ones blocks next to digits; R3 "first the tens" |
| M-NUM-TEEN | Writes the teens as heard ("שְׁתֵּים־עֶשְׂרֵה" → 2 then 10 = "210") | Builds 2, then 10 | NUM-B-16 | R1 ten-frame plus extras; R2 a 10-bundle |
| M-NUM-ZERO | Thinks zero is "nothing, not a number"; 0 cannot be an answer | Picks 1 for an empty nest; refuses 0 | NUM-A-14 | R3 story "all the birds flew away"; R2 the number line starts at 0 |
| M-ORD-CARD | Confuses ordinal with cardinal ("the third" = three of them) | Taps three objects instead of the third one | NUM-A-13 | R4 queue role-play; R2 a number badge on each position |
| M-SPACE-WORD | Confuses paired spatial words (עַל/מִתַּחַת, לִפְנֵי/מֵאָחוֹר) | Picks the opposite position | SHP-A-08/09 | R4 put a toy on/under a real table at home (parent prompt); R1 drag-and-see with the word echoed |
| M-NL-SPACE | Places numbers with unequal gaps | Places 5 near 9 on a 0–10 line | NUM-B-13 | R4 jump equal hops; R1 a linear board game (X7) |
| M-NL-DIR | Runs the number line right to left, following Hebrew reading order | Places 2 to the right of 8 | NUM-B-13 | R2 the line grows from a "0 house" on the left, with a ruler image (§8.6) |
| M-PV-FACE | Uses face value instead of place value (in 34 the 3 is "3") | Says 3 for "how many tens is 34 worth?"; adds 34+5 as 84 | NUM-C-03 | R1 base-ten blocks; R2 a place-value chart |
| M-PV-ZERO | Drops or adds internal zeros (305 → 35, or 3005) | Picks 35 for "שְׁלֹשׁ מֵאוֹת וְחָמֵשׁ" | NUM-C-07 | R1 blocks with an empty tens column |
| M-SIGN-DIR | Reads < and > backwards; picks the sign by the bigger number's position | Wrong sign whenever the pair is swapped | NUM-C-04, NUM-B-10 | R2 "the wide-open side faces the bigger number" (an animated beak opening toward the bigger pile), always inside an LTR math isolate so the glyph never mirrors (§8.6); R1 compare towers first |
| M-GEM-ORDER | Reads ט"ו (15) as "9 and 6" without knowing why 15 is not written י"ה | — (enrichment) | NUM-C-05 | R3 cultural story; explain once |
| M-COL-NAME | Uses a colour word for the wrong hue (calls orange "red") | A consistent pattern of swaps | COL-A-02/03 | R1 colour-matching first, then naming; R3 a colour-of-things song |
| M-COL-SHADE | Treats a shade as a different hue (light blue isn't blue), or a dark colour as black | Puts light blue in "not blue"; navy → black | COL-B-02/03 | R1 a slider adding white or black to one colour; R2 a paint-chip strip |
| M-COL-MIX | Predicts a mix by "the stronger colour wins" | Predicts red + yellow = red | COL-B-01 | R1 a virtual paint-mixing tub; predict → mix → see |
| M-COL-OBJECT | Thinks object colour is fixed (bananas are only yellow) | Rejects a green banana | COL-A-05 | R3 a ripening story |
| M-COL-ONEATTR | Attends to one attribute only (colour but not noun) | For "the red doll" picks a red ball | COL-A-07 | R1 two-step find: first dolls, then red |
| M-SORT-SHIFT | Switches the sorting rule mid-sort | Mixed bins | LOG-A-03 | R2 a rule card stays visible on each bin; R4 "say the rule" |
| M-SORT-OVERLAP | Cannot place an item that belongs to both sets | Leaves the overlap empty | LOG-B-07 | R1 rings that slide together |
| M-SHP-ORIENT | A rotated square ("diamond") is not a square; an upside-down triangle is not a triangle | Rejects a tilted square; calls it "יַהֲלוֹם" (diamond) | SHP-A-03 | R1 rotate the shape with a finger and watch it stay a square; R2 count sides and corners |
| M-SHP-PROTO | Accepts only the typical shape (an equilateral triangle) | Rejects a long, thin triangle | SHP-A-03 | R2 the "3 straight sides, closed" checklist; many examples and non-examples |
| M-SHP-SIZE | Thinks a big triangle and a small triangle are different shapes | Rejects scaled shapes | SHP-A-03 | R1 a resize slider |
| M-SHP-SQRECT | Thinks a square is not a rectangle, or a long rectangle is a square | Classifies wrongly | SHP-A-04, SHP-B-03 | R1 stretch a square into a rectangle; R2 measure the sides |
| M-SHP-CLOSED | Accepts an open figure as a triangle | Selects a three-line figure with a gap | SHP-B-01/04 | R3 "can the sheep get out?"; R1 close the gap |
| M-SYM-SHIFT | Copies the design instead of mirroring it | Completes the half by translating it | SHP-B-10, SHP-C-08 | R1 a fold-the-paper animation; a mirror tool |
| M-DIR-EGO | Uses own viewpoint when the robot or map faces another way | Fails only when the robot faces down or toward the child | SHP-A-09, CS-B-02 | R4 "stand like the robot"; R1 rotate the board so the robot faces up |
| M-DIR-LR | Confuses right and left | A consistent mirror path | SHP-B-12 | R4 the body anchor (§8.7); coloured wristband icons |
| M-DIR-RTL | Assumes the "next" step or column goes leftward because Hebrew reads that way, or the reverse | Starts the pixel row from the wrong side; reads the program strip in the wrong order | CS-B-08, COL-C-02 | R2 a numbered start marker (1) and a finger trail; a vertical program strip (§8.7) |
| M-PAT-COPY | Copies elements without the order | — | LOG-A-05 | R1 place each bead under its model |
| M-PAT-NEXT | Continues with the last element or a random one | Picks a repeat of the last item | LOG-A-06/B-01 | R4 chant the pattern aloud ("אָדֹם־כָּחֹל, אָדֹם־כָּחֹל"); R1 put a box round the core |
| M-PAT-UNIT | Cannot see the repeating unit | Wrong core in "find the core" | LOG-B-02 | R2 wrap the core with a train car |
| M-PAT-GROW | Treats a growing pattern as repeating | Picks the first step again | LOG-B-04 | R1 build towers step by step |
| M-SEQ-CAUSE | Ignores cause and effect in order (cracks the egg after the cake is baked) | Wrong order around the causal pair | LOG-A-08 | R3 a story; R1 "can this happen before that?" |
| M-SER-ENDS | Orders only the ends (biggest, smallest) and leaves the middle random | Middle out of order | LOG-A-10 | R1 a staircase outline to fit into |
| M-IF-REVERSE | Reverses if-then ("if it's in the box, it's red") | Applies the rule to the wrong items | LOG-B-08, CS-B-09 | R3 traffic-light story; R4 a Simon-says game |
| M-NOT | Ignores "not" (לֹא) | Selects the named item | LOG-B-09 | R2 a cross-out stamp on excluded items |
| M-SEARCH-MISS | Lists combinations unsystematically and misses some | Finds 4 of 6 | LOG-C-07 | R2 a table, filled row by row |
| M-CS-OFF1 | Off by one step: counts the start square, or one short | The robot ends one square short or past | CS-A-04, CS-B-01 | R4 "hop" the squares with a finger; R1 a footprint per step |
| M-CS-FIXALL | Deletes the whole program instead of finding the bug | Clears the program | CS-B-04 | R1 step-through: run the program one step at a time; stop at the first surprise |
| M-LOOP-COUNT | Wrong repeat count: counts the steps, not the repeats | ×6 instead of ×3 for a 3-unit dance | CS-B-06 | R2 colour-boxed repeats; R4 dance the repeats |
| M-AI-MAGIC | Thinks the machine "just knows" | — | CS-C-09 | R1 give the machine bad examples and watch it fail |
| M-ADD-RECOUNT | Counts all from 1 instead of counting on (a strategy level, not an error) | Slow; the tap log shows recounting | MATH-B-04 | R2 a hidden cup ("5 are in the cup… 6, 7, 8"); R4 fingers |
| M-PPW | Doesn't see the whole as made of parts; adds when a part is missing | For "7 = 3 + □" answers 10 | MATH-B-02 | R2 a part-part-whole mat; bar model |
| M-EQ-OPER | Reads = as "do it now, the answer comes next" | For 3 + 4 = □ + 2 answers 7 (or 9); rejects 7 = 3 + 4 | MATH-B-09 | R1 a balance scale; R3 "same as" language: "זֶה כְּמוֹ זֶה"; equations in both orientations |
| M-SUB-ORDER | Thinks subtraction is commutative (3 − 5 = 2) | Picks 2 for 3 − 5 (Band C) | MATH-B-03 | R3 "you have 3 sweets, can you give away 5?" |
| M-SUB-SMALLBIG | Subtracts the smaller digit from the larger in each column (52 − 27 = 35) | Picks 35 for 52 − 27 | MATH-C-04/05; traces to NUM-C-03 | R1 base-ten blocks: trade a ten for ten ones; R2 a number line counting up |
| M-REGROUP-FORGET | Regroups but forgets the carried ten (47 + 25 = 62) | Answer is 10 short | MATH-C-05 | R1 blocks; then the column with a "ten-coin" token |
| M-COLM-ALIGN | Misaligns columns (34 + 5 aligned left = 84) | Answer is 84 | MATH-C-06; traces to NUM-C-03 | R2 a place-value grid behind the column |
| M-COMP-DIFF | Answers "how many more?" with one set's total | Picks 8 (the larger set) for "8 vs 5, how many more?" | MATH-B-19, MATH-C-07 | R1 line up the two rows; the extras glow |
| M-KEYWORD | Picks the operation from a keyword ("more" means add) | Adds in "Dana has 3 more than Noa, Dana has 8; how many does Noa have?" | MATH-C-07 | R3 act out the story; R2 a bar model |
| M-MUL-ADD | Adds instead of multiplying (3 × 4 = 7) | Picks 7 | MATH-C-09 | R1 equal groups of objects; R2 an array |
| M-MUL-ZERO | Thinks × 0 = the number | Picks 5 for 5 × 0 | MATH-C-12 | R3 "5 plates with 0 cookies on each" |
| M-SHARE-UNEQ | Shares unequally ("one to you, two to me") | Unequal groups | MATH-A-03, MATH-B-10 | R1 deal one by one |
| M-REM-BIG | Leaves a remainder ≥ the divisor | 17 : 5 = 2 remainder 7 | MATH-C-13 | R1 group the leftovers again |
| M-FRAC-UNEQ | Calls unequal parts "halves" or "quarters" | Picks an unequal split | MATH-C-14 | R1 fold and overlay; R3 "fair share" story |
| M-FRAC-ONEPIECE | Thinks "each gets one piece, so it's the same" and ignores piece size | Picks "the same" when comparing ⅓ and ¼ of equal wholes | MATH-C-15 | R1 overlay the pieces; R3 "would you rather have one slice of a pizza shared by 3 or by 8?" |
| M-FRAC-BIGDEN | Thinks a bigger denominator means a bigger piece (¼ > ⅓) | Picks ¼ as bigger | MATH-C-16 | R3 a pizza shared by more friends; R1 fraction strips side by side |
| M-MEAS-ALIGN | Compares lengths without aligning the ends | Picks the one that sticks out further | MATH-A-04, MATH-B-11 | R1 slide both to a start line |
| M-MEAS-GAP | Leaves gaps or overlaps between units | Counts gapped clips | MATH-B-12 | R1 a snap-to-touch "train" of units |
| M-MEAS-UNIT | Ignores the unit size (8 small clips = 8 big clips) | Thinks more units means longer | MATH-B-12, MATH-C-17 | R1 measure the same strip with two units; "bigger unit → fewer units" |
| M-RULER-1 | Starts the ruler at 1, or counts tick marks instead of spaces | Answer is 1 too big | MATH-C-17 | R2 a ruler made of unit blocks |
| M-MEAS-BIG | Thinks bigger means heavier | Predicts the balloon is heavier than the stone | MATH-B-13 | R1 a balance; predict → test |
| M-MEAS-TALL | Thinks taller means holds more | Picks the tall thin glass | MATH-C-21 | R1 pour between containers |
| M-AREA-PERIM | Confuses area with perimeter | Counts edge units for area | MATH-C-18 | R1 fill (tiles) vs fence (sticks) |
| M-CLOCK-HANDS | Swaps the hour and minute hands | Reads 3:00 as 12:15 | MATH-B-15, MATH-C-20 | R1 a clock with a short, thick hour hand that moves alone first; R3 "the short hand is the boss of hours" |
| M-TIME-BASE | Treats time as base 100 (1:50 + 20 min = 1:70) | Picks 1:70 | MATH-C-20 | R2 a 60-minute ring/strip |
| M-MONEY-SIZE | Thinks a bigger coin is worth more (the ½ ₪ coin is larger than the ₪1 coin) | Picks ½ ₪ as "more" | MATH-B-16 | R2 value labels; R3 a shop with prices |
| M-MONEY-COUNT | Counts coins instead of value (three coins = ₪3) | Picks ₪3 for 5+2+1 | MATH-B-17 | R1 swap coins for ₪1 coins and count |
| M-OOO-LTR | Computes left to right regardless of operation order (2 + 3 × 4 = 20) | Picks 20 | MATH-C-24 | R3 a story with groups; R2 brackets highlighting |

### 5.3 How the engine traces a failure to a gap and repairs it

1. **Tag every response.**
   - Each option has a `misconceptionTag` or `correct`.
   - Spoken answers are mapped to a value by the accept-list (§6), and that value inherits its option's tag. "Wrong for an unknown reason" is `M-UNKNOWN`.
   - Wrong spoken answers that match no option are logged by value. For example, "תֵּשַׁע" for 4+5 is correct, but "אַרְבַּע" is tagged `M-CNT-CARD` if the template's error classifier sees that the child gave the first addend.
2. **Diagnose a pattern, not a single error.** Use tech.md §7.2's evidence rule:
   - `score ← 0.8·score + strength`, where strength is 1.0 for a tap answer and 0.5 for a low-confidence voice answer;
   - the misconception is **active** at `score ≥ 1.5` across at least 2 independent items;
   - it is **resolved** after 3 diagnostic items that could have shown it but did not.

   A dedicated diagnostic item (§5.3, item-design rules) counts as strength 1.0.
   - Slips (a random wrong answer with no repeated tag) only lower the BKT estimate.
3. **Trace back.** Each tag in §5.2 names a skill to trace back to. The engine also walks the prerequisite graph of the failing skill.
   - **(a)** It finds the prerequisites whose mastery estimate is < 0.8, or whose durable state has lapsed.
   - **(b)** It runs a **probe**: 2–3 quick items on the most suspect prerequisite, presented as a "mini-game" with no visible switch.
   - **(c)** If the probe fails, the prerequisite becomes the **repair target**. If it passes, the misconception is treated as local to the current skill.
4. **Repair.** The engine runs a short "repair loop": 3–6 items on the target, in a *different representation* from the one that failed (§5.5). It starts with a worked example ("watch me" / "show me") and ends with an independent item.
5. **Return.** The engine goes back to the original skill and offers an item that **specifically contradicts the misconception**. Example: after an `M-SUB-SMALLBIG` repair, it serves 52 − 27 with base-ten blocks, then in a column. A pass clears the tag.
6. **Record.** Tags persist per child with timestamps. They feed the parent view in plain Hebrew (§12) and the authoring dashboard (aggregated), which shows which items create confusion.

**Item-design rules for diagnostic distractors.** These rules are enforced in CMS review.
- In items with ≥3 options, **at least 2 distractors must carry distinct misconception tags.** A "random" distractor is allowed only in 4-option items.
- In 2-option items, the distractor *must* be tagged. The item never counts alone as mastery evidence.
- Every core skill needs **at least one dedicated diagnostic item per tag listed in its "Watch for" column**. That item's only plausible wrong answer is the tagged one.
- Spoken answers: authors list the 1–3 most likely wrong values with their tags (`voice.expectedErrors`).
- Every tag has at least one item where the misconception gives a **wrong** answer and one where it would accidentally give the **right** answer. This stops false "mastery". Example for M-SUB-SMALLBIG: 58 − 23 works by luck, so we must also use 52 − 27.

### 5.4 Prerequisite repair example (engine view)

```
Child on MATH-C-05 (2-digit subtraction). Responses: 52−27→35 (M-SUB-SMALLBIG), 64−38→34 (M-SUB-SMALLBIG)
→ tag suspected → graph walk: NUM-C-03 (place value) p=0.71  ← suspect; MATH-C-01 facts p=0.97 ✓
→ probe NUM-C-03: "how many tens in 52?" → child: 5 ✓ ; "make 52 with 4 tens" → child fails ✗
→ repair target: NUM-C-03 "regrouping view" (R1 base-ten blocks: unbundle one ten)
→ 4 items (blocks), 1 item (place-value chart), 1 independent
→ return: 52−27 with blocks → 25 ✓ ; 71−46 in column → 25 ✓ → tag cleared; spaced check scheduled
```

### 5.5 Alternative explanations: representations and ladders

Every core skill has **≥3 representations**, authored as separate activity variants that share a skill ID.

| Code | Representation | Examples |
|---|---|---|
| R1 | **Concrete/manipulative**: virtual objects the child moves | Drag counters, base-ten blocks, paint tubs, balance-scale weights, shape tiles, the robot itself |
| R2 | **Pictorial/model** | Ten-frame, dot patterns, number line, bar model, hundred chart, arrays, Venn rings |
| R3 | **Story/context** | The shop, a picnic, the bus, a Shabbat table, a character's problem |
| R4 | **Embodied/song/gesture** | Fingers, claps, jumps, "stand like the robot", counting songs |
| R5 | **Abstract symbols** | Numerals, `+ − = < >`, arrow codes |

**Switching rule** (tech.md §7.3). After 2 errors, or a hint at level 3, the next item uses a different representation. The default order is R1 → R2 → R5, with R3/R4 used as needed. It never repeats the same explanation louder or slower more than once. Hint level 1 may replay the prompt slowly; hint level 2 must change representation or add a model. The engine also learns each child's best repair representation per skill family through tech.md's Thompson-sampling bandit (§10.5).

**Ladder 1: NUM-A-04 "how many?" (cardinality), Band A**

| Step | Representation | Activity |
|---|---|---|
| 1 | R4 | Count on fingers together with the character: "אַחַת, שְׁתַּיִם, שָׁלוֹשׁ — שָׁלוֹשׁ אֶצְבָּעוֹת!" (*one, two, three — three fingers!*). The whole hand is raised at the end. |
| 2 | R1 | Drag each apple into a basket. The basket shows a big numeral bubble that updates with each apple, and the last number stays on the basket. |
| 3 | R2 | Dots in a dice pattern; tap to count, then the dots "hug" into one group labelled 3. |
| 4 | R3 | "The rabbit invited 3 friends. Are there enough chairs?" Count the chairs and say the total. |
| 5 | R5 | Choose the numeral 3 to put on the basket label. |
| Check | U4 | "Give me 3" from a pile of 7 (the reverse direction). |

**Ladder 2: MATH-B-08 "add within 20 using ten" (8 + 5), Band B**

| Step | Representation | Activity |
|---|---|---|
| 1 | R1 | Two ten-frames. Drag 8 counters, then 5 more. The child sees that 2 fill the first frame and 3 go to the next: "10 and 3". |
| 2 | R4 | Fingers: "8 and 2 more fingers is 10 — and 3 more". |
| 3 | R2 | Number line: a jump of +2 to 10, then +3. Two arcs. |
| 4 | R3 | A bus with 10 seats: 8 children are on, 5 get on. How many are on now, and how many have to stand? |
| 5 | R5 | `8 + 5 = 8 + 2 + 3 = 13` built from tiles (LTR). |
| Check | U2, U4 | "Show 7 + 6 another way" (choose a picture); "□ + 5 = 13". |

**Ladder 3: CS-B-02 "robot turns relative to its own heading", Band B**

| Step | Representation | Activity |
|---|---|---|
| 1 | R4 | "Stand up and face the robot's way" (camera off; the child just does it). The character models it: "turn to your right hand". |
| 2 | R1 | Rotate the board so the robot faces up; drag the turn card and watch. |
| 3 | R2 | The robot wears a coloured "right-hand" glove (the same colour as the right-turn arrow card). |
| 4 | R3 | Story: "The robot is coming back home, toward us. Which way is *its* right?" |
| 5 | R5 | Arrow-only program with the robot facing down. |
| Check | U1, U5 | Predict where the robot will end. Then: "The robot turned the wrong way — fix it." |

**Ladder 4: MATH-B-09 "the equals sign means 'same as'", Band B → C**

| Step | Representation | Activity |
|---|---|---|
| 1 | R1 | Balance scale: put 3 + 4 blocks on one side; what makes it balance? Try 7, then 5 + 2. |
| 2 | R3 | "Two friends have the same number of stickers. One has 3 + 4…" |
| 3 | R2 | Bar model with two equal bars. |
| 4 | R5 | `7 = 3 + 4`, `3 + 4 = 5 + 2`, and true/false items: "is `5 = 5` true?" |
| Check | U5 | "The robot wrote `3 + 4 = 7 + 2`. Is that right? Fix it." |

### 5.6 Checks for real understanding (not rote)

Each skill's mastery evidence requires **at least one** check from this list. Core skills, those marked as prerequisites for ≥3 other skills, require **two different** checks.

| Code | Check | Bands | Example |
|---|---|---|---|
| U1 | **Predict, then check** | A–C | "How many will there be after the bird lands?", then animate. "Where will the robot stop?", then run. |
| U2 | **Show it another way** | B–C | "Here is 8 on a ten-frame. Find the picture that shows the same number." Make 6 with two hands differently. |
| U3 | **Transfer** (new context, objects or orientation) | A–C | Counted apples? Now count sounds (drum beats). Triangles in any rotation. Make ten with shekels. |
| U4 | **Reversible question** | A–C | `3 + 4 = □` and `□ + 4 = 7`. "How many?" and "Give me 4". Program → endpoint, and endpoint → program. |
| U5 | **Error spotting** | B–C (A: the "oops" version) | "The robot counted the frogs: 1, 2, 3, 3, 4. Oops! What happened?" |
| U6 | **Explain back** ("אֵיךְ יָדַעְתָּ / יָדַעַתְּ?", *how did you know?*) | B by tap (choose the reason picture); C by voice or tap | "Because 6 and 4 make 10" by voice, or tap the ten-frame picture that shows the reason. The answer is scored by matching to reason categories (§11.4), never by grammar. |

### 5.7 Revisits: fresh vs durable mastery

| State | Definition | What the child sees |
|---|---|---|
| `learning` 🌱 | Has started, below the fresh criterion | A seedling on the map |
| `fresh_mastery` 🌿 | The full mastery evidence is met (§4.1) | A plant with leaves |
| `durable_mastery` 🌳 | Fresh, and passed a delayed check ≥ 7 days later with a different item; R at or above target | A tree with fruit; adds a permanent item to the child's world |
| `needs_revisit` 🍂 | A delayed check failed, or R < 0.7 | A leaf needs watering; no "loss" is shown, and world items are never removed |
| `gap` 🔎 | Found by a diagnostic walk; repair pending | Not shown to the child; the parent sees "gap found" with plain-Hebrew text |

**Spaced schedule.** tech.md §7.4's FSRS model schedules each check when retrievability R falls to 0.9, with a gap of at least 1 day and at most 90. For a typical skill this works out to roughly **1, 3, 7, 21 and 60 days**, the target the owner asked for.
- The intervals expand by ×1.5 on a confident pass (correct and fast, no hint).
- They hold on a pass with a hint, and drop back two steps on a fail.
- A "check" is 1–3 items **interleaved into ordinary play**, so the child is not told it is a test. It uses a *different item and representation* from the last practice.
- Expanding retrieval suits preschoolers: Fritz et al. found recall more than doubled.

**When a check fails.** The skill becomes `needs_revisit`, and the engine:
1. runs a gentle re-teach of 2–4 items, starting with a worked example in a representation **different from both** the original teaching and the failed check;
2. reruns the diagnosis: is a prerequisite also `needs_revisit`? (§5.3);
3. re-checks in the same or next session;
4. restarts the schedule at the 3-day step after a pass.

The parent view says "חוֹזְרִים עַל זֶה בְּכֵיף" (*we're revisiting this, happily*), not "forgot".

**Interleaving.** From Band B, practice blocks mix 2–3 related skills, such as addition and subtraction, or squares and rectangles, once each skill is at least "learning, p ≥ 0.6". Band A interleaves only across *activities*, not within one.

### 5.8 Worked examples across bands

**Band A: "Noa" (age 3½), counting.**
1. On NUM-A-04, Noa answers 5 for 4 scattered ladybugs twice. The tap log shows the same bug tapped twice, so `M-CNT-DOUBLE` is suspected.
2. The trace goes to NUM-A-03 (one-to-one). The probe, "touch each bug once" with lighting, shows double-touching.
3. Repair (R1): "Let's move each ladybug to the leaf." Every ladybug she moves cannot be recounted. Three items.
4. Then R4: a finger-touch song. Return to ladybugs in a line, then scattered: correct.
5. U4 check: "give the bird 4 seeds". Pass.
6. Six days later, an interleaved check counting drum beats (U3 transfer) passes. Twenty days later a mixed check passes, and the skill becomes durable 🌳. The parent sees "נוֹגַעַת בְּכׇל חֵפֶץ פַּעַם אַחַת כְּשֶׁסּוֹפְרִים" (*touches each object once when counting*).

**Band B: "Itai" (age 5½), teen numerals.**
1. He picks 21 when he hears "שְׁתֵּים־עֶשְׂרֵה" (twelve), and once builds "2 then 10". The tags are `M-NUM-REV` and `M-NUM-TEEN`.
2. The trace goes to NUM-B-16 (teens as ten and ones). The probe "show 12 on two ten-frames" fails.
3. Repair:
   - R1: fill one frame (10) plus 2. The numeral appears as the 1 under the full frame and the 2 under the extras. The colours of the digits match the colours of the frames.
   - R4: "ten fingers and two toes."
   - R3: a story about egg cartons.
4. Return: 12 vs 21 discrimination with the frames. Pass.
5. A U2 check, "which picture shows 21?", passes.
6. At the 7-day check he fails 17 vs 71. The skill is `needs_revisit`, and the re-teach uses R2 (hundred-chart rows: 17 is in the 1st row of tens) instead of the frames. He passes, and the schedule restarts.

**Band C: "Maya" (age 7½), subtraction.** This is the engine trace in §5.4.
- The re-teach used base-ten blocks. Her delayed check at 21 days fails again on 63 − 28.
- The engine notices that blocks are now *her* successful representation only with blocks visible.
- It switches to R2 (an open number line counting up: 28 → 30 → 60 → 63, so 2 + 30 + 3 = 35). It then adds a U5 error-spot: "The robot says 63 − 28 = 45. Where did it go wrong?"
- Maya explains by voice: "הוּא הוֹרִיד שָׁלוֹשׁ מִשְּׁמוֹנֶה, הָפוּךְ" (*he took 3 from 8, backwards*). The tutor classifies this as a correct reason (`reason:smaller_from_larger_detected`).
- She passes the next two checks, and the skill becomes durable.

**Band B: "Lior" (age 6), robot turns in RTL.**
- Lior's paths fail only when the robot faces down: a mirrored path in each case. The tags are `M-DIR-EGO` with `M-DIR-LR` (not M-DIR-RTL), because faces-up programs pass.
- The trace goes to SHP-B-12 (right/left on own body). The probe ("touch your right ear" icon → tap the right hand on the avatar) passes, so the gap is perspective, not labels.
- Repair: Ladder 3, steps 1–3. U1 and U5 pass, and the skill is fresh. The 3-day check passes.

## 6. Activity types library

### 6.1 Rules shared by every template

**Tap path.** Every template is fully playable by tap or drag. Any drag can also be done by "tap the object, then tap the target", for motor accessibility and for Band A.

**Voice path.** Voice is optional, activates only after the prompt ends, and shows a glowing "listening" ear on the character.
- **Matching** is constrained to the template's expected values. tech.md's `hebrew_text` builds the accept-list for each value:
  - masculine and feminine forms (שָׁלוֹשׁ / שְׁלוֹשָׁה);
  - construct forms (שְׁנֵי / שְׁתֵּי);
  - the noun with or without ה־ or ו־;
  - non-normative but common forms (שָׁלוֹשׁ כְּלָבִים is accepted as 3, see §8.1);
  - child mispronunciations listed in the lexicon (for example "שָׁלוֹס" and "שְׁתַיִם" without the dagesh);
  - fillers ("אֶמ…", "זֶה…") are ignored.
- **Low confidence** gets a confirm with a tap: "אָמַרְתֶּם שָׁלוֹשׁ?" (*did you say three?*), plus the three choices.
- **Very low confidence** gets one gentle re-ask ("לֹא שָׁמַעְתִּי טוֹב — אֶפְשָׁר שׁוּב? אוֹ לִלְחֹץ" / *I didn't hear well — again? or tap*), then falls back to tap.
- **An unrecognised utterance never counts as wrong.**
- **Partial answers.** If the child says the noun only ("כְּלָבִים", *dogs*), the tutor asks "כַּמָּה כְּלָבִים?" (*how many dogs?*).

**Error classifiers.** Each template defines the classifiers that map responses to misconception tags (`feedback.incorrect[].when` in tech.md).

**Universal knobs** apply to every template:
- `setSize` / `range`;
- `numChoices` (2–4);
- `distractorTags` (which misconceptions to probe);
- `representation` (R1–R5);
- `scaffold` (worked example, guided, independent);
- `clutter` (number of irrelevant objects);
- `voiceAllowed`;
- `hintLadder`.

### 6.2 Template catalogue

| ID | Template | Description | Skills / bands | Tap interaction | Voice: what the child says → accept-list (examples) | Difficulty knobs |
|---|---|---|---|---|---|---|
| T01 | **Tap the answer** | A question with 2–4 picture or numeral choices | All domains · A–C | Tap a choice | The value: "שָׁלוֹשׁ / שְׁלוֹשָׁה / 3"; colour "אָדֹם / אֲדֻמָּה / הָאָדֹם"; shape "עִגּוּל / הָעִגּוּל" | numChoices, distractor tags, image abstraction |
| T02 | **Count & tap** | Count a scattered set by tapping each object, which lights up, then choose or say the total | NUM-A-03…09, NUM-B-04 · A–B | Tap each object (the counter increments), then tap a number | Count aloud along: each counting word is recognised **in sequence**. Total: "אַרְבַּע / אַרְבָּעָה / אַרְבָּעָה פַּרְפָּרִים / אַרְבַּע פַּרְפָּרִים" | set size, arrangement (line, grid, scatter, moving), lit vs unlit taps, objects that move after tapping |
| T03 | **Drag to sort** | Sort objects into 2–4 bins by a rule | COL-A-04, LOG-A-03, LOG-B-05/07, SHP-B-04 · A–C | Drag (or tap-tap) to a bin | Name the bin: "בַּקֻּפְסָה הָאֲדֻמָּה / לָאֲדֻמִּים / לַשְּׁנִיָּה" (*in the red box / to the reds / to the second one*) | number of bins, attributes in conflict, hidden rule (child infers it), Venn overlap |
| T04 | **Trace the numeral / shape** | Trace a dotted path with a start dot and arrow | NUM-B-07, SHP-A-02 · B | Finger trace; tolerance band | Optional: say the name at the end | tolerance, guides (full → start dot only), stroke-order check |
| T05 | **Build the pattern** | Continue, copy, fix or create a pattern | LOG-A-05…07, LOG-B-01…04, X1 · A–C | Drag beads or tiles into slots | Say the next item: "כָּחֹל / כְּחֻלָּה / הַכָּחֹל", "עִגּוּל"; for sound patterns, clap (detected as an audio onset, not speech) | core length (AB → ABCD), growing patterns, number of missing items (end, middle), modality |
| T06 | **What's next?** | Sequence an item or pick the next picture in a story or process | LOG-A-08, LOG-B-12, CS-A-01 · A–B | Tap or drag pictures into order | "קֹדֶם… אַחַר כָּךְ…" (*first… then…*): accepted only for picking one item | length 3–6, causal vs arbitrary steps |
| T07 | **Robot path coding** | Plan a program of arrows, run it, debug | CS-A-03…CS-C-06, X2 · A–C | Tap arrow cards into a **vertical** program strip (top to bottom); press ▶ | Direction words: "קָדִימָה, אֲחוֹרָה, יָמִינָה, שְׂמֹאלָה, לְמַעְלָה, לְמַטָּה" (also "יָמִין", "שְׂמֹאל", "יְמִינָה"); "פַּעֲמַיִם / שָׁלוֹשׁ פְּעָמִים" (*twice, three times*). A spoken program adds cards one at a time with confirmation | grid size, obstacles, start heading, number of steps, available blocks (move/turn/repeat/if), step-through mode, required shortest path |
| T08 | **Balance scale** | Put weights or number-blocks on a balance to compare or equalise | MATH-A-04, MATH-B-09/13, MATH-C-08/19 · A–C | Drag blocks onto pans; the scale tilts | "שָׁוֶה" (*equal*), "הַצַּד הַזֶּה כָּבֵד יוֹתֵר" (*this side is heavier*), a number for the missing weight | numbers, symbolic vs object weights, equation form (□ + 2 = 3 + 4) |
| T09 | **Number-line jump** | A character jumps along a 0–N line: place, add, subtract | NUM-B-13, NUM-C-06, MATH-B-08, MATH-C-04 · B–C | Tap where to land; drag the jump arc | The landing number; "קְפִיצָה שֶׁל שְׁתַּיִם" (*a jump of two*) | range (10 → 1,000), labelled ticks (all → ends only), jump size, open number line |
| T10 | **Shape builder** | Fill an outline or build a picture from tiles | SHP-A-06, SHP-B-05…07, SHP-C-04 · A–C | Drag; tap to rotate; flip button (Band C) | Name the piece needed: "מְשֻׁלָּשׁ" | outline detail (each piece → whole silhouette), rotation needed, piece count, substitution |
| T11 | **Mix the colours** | Predict a mix, then pour paints into a tub | COL-B-01, COL-C-01 · B–C | Drag paint tubes; slider for amount of white or black | Predict: "כָּתֹם / כְּתֻמָּה", "סָגֹל", "יָרֹק" | primaries vs secondaries, tints and shades, predict-first required |
| T12 | **Speak the answer** | A voice-first wrapper around T01/T02/T09 items (the tap fallback is always shown) | All · A–C | Fallback tap choices appear after 4 s of silence or on request | The template's accept-list. Gender-agreement variants are always accepted | which items allow voice; confirm threshold |
| T13 | **Story problem** | A short animated scene with a question, using manipulatives | MATH-B-01/02, MATH-C-07/25, X4 · B–C | Act it out with objects; then choose or build the answer | The number, with or without the noun: "חָמֵשׁ סֻכָּרִיּוֹת / חֲמִשָּׁה" | problem type (join, separate, part-part-whole, compare), unknown position (result, change, start), extra information, two steps |
| T14 | **Ten-frame flash** | Show a dot or ten-frame pattern briefly, then answer (subitizing) | NUM-A-05/10, NUM-B-09 · A–B | Tap a number | The number | exposure (2 s → 0.7 s; Band A minimum 2 s), arrangement, five-structure |
| T15 | **Odd one out** | Find the item that doesn't belong; optionally explain | LOG-A-02, LOG-C-08, SHP-B-04 · A–C | Tap | Name the item; Band C: "כִּי הוּא לֹא עִגּוּל" (*because it's not a circle*) → reason categories | number of attributes, subtlety, multiple valid answers (accept any with a reason) |
| T16 | **Match pairs** | Connect a numeral to a set, a colour to a word, a solid to its face | NUM-A-07, SHP-B-09, MATH-B-16 · A–B | Draw a line, or tap-tap | — (tap only) | pairs 2–6, memory (cards face down) variant |
| T17 | **Shop & pay** | Pay a price with coins; make change | MATH-A-06, MATH-B-16/17, MATH-C-22, X4 · A–C | Drag coins to the counter | "שְׁנֵי שְׁקָלִים", "חֲמִשָּׁה שְׁקָלִים", "שֶׁקֶל וָחֵצִי" (*₪1.50*); "עֶשֶׂר אֲגוֹרוֹת" | price, available coins, exact pay vs change, number of solutions |
| T18 | **Clock setter** | Set or read an analog or digital clock | MATH-B-15, MATH-C-20 · B–C | Drag the hands (hour hand only first) | "שָׁלוֹשׁ", "שָׁלוֹשׁ וָחֵצִי", "רֶבַע לְאַרְבַּע" (*quarter to four*), "שָׁלוֹשׁ וַעֲשָׂרָה" | hour → half → quarter → 5-min → minute; linked hands; elapsed time |
| T19 | **Measure it** | Measure with units, or a ruler starting at 0 | MATH-B-11/12, MATH-C-17/18 · B–C | Drag units end to end, or slide the ruler | Number plus unit: "שִׁבְעָה סַנְטִימֶטְרִים / שֶׁבַע סַנְטִימֶטְרִים" (both accepted) | unit type, gaps allowed (diagnostic), ruler starting at 1 (error-spot) |
| T20 | **Data builder** | Build a pictograph or square bar chart from a set; answer questions | MATH-A-07, MATH-B-19, MATH-C-23, X8 · A–C | Drag items into columns; tap a bar | "כְּלָבִים" (*dogs*), "שָׁלוֹשׁ יוֹתֵר" (*three more*) | categories 2–5, question type (most, how many more, total), scale |
| T21 | **Fix the mistake (debug)** | The character made a mistake; find and fix it (understanding check U5) | All · B–C (A: "oops" version) | Tap the wrong step; drag the correct one | "הַשָּׁלוֹשׁ הַשֵּׁנִי" (*the second 3*), "הוּא סָפַר פַּעֲמַיִם" (*he counted twice*) → reason categories | number of errors, error subtlety, explain required (C) |
| T22 | **Equal groups / arrays** | Build groups or arrays; share fairly | MATH-A-03, MATH-B-10, MATH-C-09…13 · A–C | Deal objects to plates; drag an array frame | "שָׁלוֹשׁ קְבוּצוֹת שֶׁל אַרְבַּע" (*three groups of four*), the product | group size, number of groups, remainder, array vs groups |
| T23 | **Fraction fold** | Fold or cut shapes into equal parts; take a fraction of a set | MATH-C-14…16 · C | Drag the fold line; tap pieces | "חֵצִי, שְׁלִישׁ, רֶבַע, חֲמִישִׁית…" (*half, third, quarter, fifth*) | shape, number of parts, unequal non-examples, part of a quantity |
| T24 | **Sound & move (embodied)** | Clap, jump, wave or count along; the app shows and the child imitates. The child self-reports or a parent confirms, with no camera | NUM-A-01, LOG-B-03, CS-A-02 · A–B | Tap "done!" or echo-tap the rhythm | Counting along; clapping detected by microphone onsets (optional) | tempo, length, modality |
| T25 | **Explain it** | After an answer: "how did you know?" (understanding check U6) | Core skills · B–C | Tap one of 2–3 reason pictures (for example, a ten-frame, fingers, or counting on) | Free short answer, classified into reason categories by the tutor (§11.4); never scored on language | number of reason options, voice vs tap |

### 6.3 Error classifiers per template (excerpt)

| Template | Classifier | Fires when | Tag |
|---|---|---|---|
| T02 | `double_tap_same` / `answer_n_plus_1` | The same object was tapped twice, or the answer is n+1 on a scatter | M-CNT-DOUBLE |
| T02 | `answer_n_minus_1` | The answer is n−1 on a scatter | M-CNT-SKIP |
| T02 | `last_word_not_total` | The child counted correctly but chose a different total | M-CNT-CARD |
| T07 | `mirror_path` | The executed path mirrors the target across the robot's heading | M-DIR-LR / M-DIR-EGO (by the robot's heading) |
| T07 | `off_by_one_end` | The robot ends one square short or past | M-CS-OFF1 |
| T07 | `program_cleared` | The child deletes ≥80% of the steps on a debug item | M-CS-FIXALL |
| T08 | `answer_equals_left_total` | For a + b = □ + c, the answer is a + b | M-EQ-OPER |
| T09 | `jump_from_one` | The jump starts at 1 instead of 0 | M-NL-SPACE |
| T13 | `used_keyword_op` | The answer matches the keyword-driven wrong operation | M-KEYWORD |
| T17 | `count_coins_not_value` | The amount paid equals the number of coins | M-MONEY-COUNT |
| T19 | `start_at_one` | The reading is 1 too big | M-RULER-1 |

## 7. Sample content

### 7.1 How tutor scripts are written: neutral core and character flavour

Characters are pluggable. The child picks a favourite companion, and new characters, including an original superhero squad, are added over time. Every script therefore has two layers.

| Layer | Who writes it | Rules |
|---|---|---|
| **Core lines** (`core:`) | Curriculum team; reviewed by a pedagogy expert | Carry *all* the learning: instruction, question, hints, feedback, explanation. **Character-neutral**: no catchphrase, no reference to a character's world, no self-gender. Any voice can say them. They are recorded once per character voice, or synthesised by tutor TTS (§15). The listener's gender is neutral in pre-recorded audio (plural or "let's" forms). |
| **Flavour lines** (`flavour:<characterId>:…`) | Character writers; curriculum sign-off | Optional and short (≤ 2 s). Only these slots: `greeting`, `encourage` (catchphrase), `celebrate`, `farewell`, and `power` (the hero's strategy name, §9.7). **They never carry information the child needs**, never replace a core line, and never play during thinking time. If a flavour line is missing, the item still works. |

**Self-gender trap.** Hebrew first-person verbs in the present tense show the speaker's gender: אֲנִי חוֹשֵׁב (masculine) / אֲנִי חוֹשֶׁבֶת (feminine), both *I think*. Core lines avoid them by using:
- "let's" forms: בּוֹאוּ נִסְפֹּר;
- the past or future tense, which are gender-neutral in the first person: סָפַרְתִּי, אֶסְפֹּר;
- impersonal forms: אֶפְשָׁר, צָרִיךְ, כְּדַאי.

Gendered self-talk lives only in flavour lines.

**Sample item, NUM-A-04 "how many?", in three layers**

| Slot | Text | Gloss |
|---|---|---|
| core: prompt | כַּמָּה פַּרְפָּרִים יֵשׁ? בּוֹאוּ נִסְפֹּר. | *How many butterflies are there? Let's count.* |
| core: correct | אַרְבָּעָה פַּרְפָּרִים! סְפַרְתֶּם כׇּל אֶחָד פַּעַם אַחַת. | *Four butterflies! You counted each one once.* |
| flavour:**Pili** (a gentle owl-like dreamer; original) — `greeting` | הוּ־הוּ, חֲבֵרִים! פִּילִי פֹּה. | *Hoo-hoo, friends! Pili's here.* |
| flavour:**Pili** — `celebrate` | הוּ־הוּ־הוּרָא! | *Hoo-hoo-hooray!* |
| flavour:**Kav-Zinuk** (קַו־זִנּוּק, *Jump-Line*; a hero from the original squad whose power is the number line) — `greeting` | קַו־זִנּוּק בַּדֶּרֶךְ! | *Jump-Line is on the way!* |
| flavour:**Kav-Zinuk** — `celebrate` | זִנּוּק שֶׁל אַלּוּפִים! | *A champions' jump!* |

The engine plays `greeting` at the start of the activity, never between the prompt and the answer. `celebrate` plays after `core: correct`, never instead of it. The names here are placeholders for the Design team's characters.

### 7.2 Lesson script 1: Band A, Numbers. "Butterflies in the garden" (NUM-A-03/04)

| | |
|---|---|
| **Skills** | NUM-A-03 one-to-one; NUM-A-04 cardinality (≤5). Review item: COL-A-02. |
| **Length** | ~4 min, 5 items. Representations R1 (touch-and-move), R2 (dots), R4 (fingers). |
| **Screen** | A garden; a flower in the centre; 3–5 butterflies on leaves. A replay button (🔊) is top-start (it mirrors in RTL). A "?" helper sits next to it. |

**Script.** Lines are core unless marked *flavour*.

| # | Screen | Tutor line (Hebrew) | Gloss | Child action / correct answer |
|---|---|---|---|---|
| 0 | The companion waves | *flavour:greeting* | — | — |
| 1 | Warm-up retrieval (COL-A-02): 2 flowers, red and yellow | אֵיפֹה הַפֶּרַח הָאָדֹם? | *Where is the red flower?* | Tap or say "פֹּה / הָאָדֹם / אָדֹם". |
| 2 | 3 butterflies in a line | פַּרְפָּרִים בָּאוּ לַגִּנָּה! בּוֹאוּ נִסְפֹּר אוֹתָם. נוֹגְעִים בְּכׇל פַּרְפָּר פַּעַם אַחַת. | *Butterflies came to the garden! Let's count them. Touch each butterfly once.* | Tap each one (it flies to the flower and the counter says "אַחַת… שְׁתַּיִם… שָׁלוֹשׁ"). |
| 3 | All 3 are on the flower; three answer bubbles (2 · 3 · 4, as dots plus a numeral) | כַּמָּה פַּרְפָּרִים יֵשׁ עַל הַפֶּרַח? | *How many butterflies are on the flower?* | **3** (tap, or say "שָׁלוֹשׁ / שְׁלוֹשָׁה / שְׁלוֹשָׁה פַּרְפָּרִים"). Distractors: 4 → M-CNT-DOUBLE; 2 → M-CNT-SKIP. |
| 4 | 4 butterflies, scattered | עַכְשָׁו הֵם מְפֻזָּרִים. נִסְפֹּר שׁוּב — כׇּל פַּרְפָּר עָף לַפֶּרַח. | *Now they're scattered. Let's count again — each butterfly flies to the flower.* | Tap ×4 → **4**. |
| 5 | 5 scattered; **no fly-away** (the harder step) | הַפַּעַם הֵם נִשְׁאָרִים בַּמָּקוֹם. כַּמָּה פַּרְפָּרִים? | *This time they stay in place. How many butterflies?* | **5**. Tapped butterflies glow so none are recounted. |
| 6 | Understanding check U4: a jar with 7 butterflies and an empty flower | תְּנוּ לַפֶּרַח אַרְבָּעָה פַּרְפָּרִים. | *Give the flower four butterflies.* | Drag exactly 4 and tap ✔. Taking all 7 → M-CNT-CARD. |

**Wrong-answer feedback** (core, by classifier):
- **M-CNT-DOUBLE** (answer 4 for 3): "הַמְּמ… נִרְאֶה שֶׁפַּרְפָּר אֶחָד נִסְפַּר פַּעֲמַיִם. בּוֹאוּ נִסְפֹּר לְאַט." *Hmm… looks like one butterfly got counted twice. Let's count slowly.*
- **M-CNT-SKIP** (answer 2 for 3): "אוּלַי פִּסְפַּסְנוּ פַּרְפָּר? בּוֹאוּ נִבְדֹּק." *Maybe we missed a butterfly? Let's check.*
- **Default**: "כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב." *Almost! Let's try again.*

**Hints** (each one changes support, never just repeats louder):

| Level | Action | Line | Gloss |
|---|---|---|---|
| H1 | Replay the prompt slowly; the butterflies wiggle one by one | נוֹגְעִים בְּפַרְפָּר אֶחָד, וְאוֹמְרִים מִסְפָּר אֶחָד. | *Touch one butterfly, and say one number.* |
| H2 | Switch to R4: an animated hand counts on its fingers next to the butterflies | בּוֹאוּ נִסְפֹּר גַּם עִם הָאֶצְבָּעוֹת: אַחַת… שְׁתַּיִם… | *Let's count on our fingers too: one… two…* |
| H3 | Worked example: the guide counts each butterfly aloud, then hands the move back | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. הַמִּסְפָּר הָאַחֲרוֹן אוֹמֵר כַּמָּה: שָׁלוֹשׁ! עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שָׁלוֹשׁ. | *One, two, three. The last number tells how many: three! Now your turn — tap three.* |

**Celebration.** "כׇּל הַכָּבוֹד! סְפַרְתֶּם לְאַט וּבְדַקְתֶּם כׇּל פַּרְפָּר." *Well done! You counted slowly and checked every butterfly.* Then *flavour:celebrate*. The butterflies form the numeral 5 for 2 seconds, and a butterfly sticker is added to the garden world.

### 7.3 Lesson script 2: Band B, Computer science. "The robot goes home" (CS-B-01/02/04)

| | |
|---|---|
| **Skills** | CS-B-01 plan 4–6 steps; CS-B-02 turns; CS-B-04 debug one step. Review item: SHP-B-12. |
| **Length** | ~6 min, 5 items. A 4×4 grid. The program strip runs **vertically, top to bottom**, beside the grid, with a "1" start marker at the top. |
| **Cards** | ⬆ "קָדִימָה" (*forward*), ↰ "פְּנִיָּה שְׂמֹאלָה" (*turn left*), ↱ "פְּנִיָּה יָמִינָה" (*turn right*). The turn cards are coloured: right = green, matching the robot's green right-hand glove; left = orange glove. |

| # | Screen | Tutor line (Hebrew) | Gloss | Correct answer |
|---|---|---|---|---|
| 1 | Warm-up (SHP-B-12): the avatar's two hands | אֵיפֹה הַיָּד הַיְּמָנִית? | *Where is the right hand?* | Tap the right hand. |
| 2 | Robot at the bottom, facing up; home 3 squares up | הָרוֹבּוֹט רוֹצֶה הַבַּיְתָה. אֵילוּ צְעָדִים הוּא צָרִיךְ? שָׂמִים כַּרְטִיסִים, וְלוֹחֲצִים ▶. | *The robot wants to go home. Which steps does it need? Put cards, then press play.* | ⬆⬆⬆ |
| 3 | Home is 2 up and 1 right | עַכְשָׁו הַבַּיִת בְּצַד. צָרִיךְ גַּם לִפְנוֹת. | *Now the house is to the side. It needs to turn too.* | ⬆⬆↱⬆ (any valid path is accepted) |
| 4 | Robot facing **down** (toward the child); home is to the robot's right | הָרוֹבּוֹט מִסְתַּכֵּל אֵלֵינוּ. אֵיפֹה הַיָּמִין שֶׁלּוֹ? | *The robot is looking at us. Where is its right?* | ↱⬆ (the child's left!). Wrong → M-DIR-EGO. |
| 5 | U5 debug: a program with one wrong turn; the robot bumps a tree | אוֹי! הָרוֹבּוֹט נִתְקַע בָּעֵץ. אֵיזֶה כַּרְטִיס צָרִיךְ לְתַקֵּן? | *Oops! The robot got stuck at the tree. Which card needs fixing?* | Tap card 3 and swap it to ↰. Clearing all → M-CS-FIXALL. |

**Wrong-answer feedback:**
- **Mirror path** (M-DIR-LR): "הָרוֹבּוֹט פָּנָה לַצַּד הַשֵּׁנִי. בּוֹאוּ נִסְתַּכֵּל עַל הַכְּפָפָה הַיְּרֻקָּה שֶׁלּוֹ." *The robot turned the other way. Let's look at its green glove.*
- **Off by one** (M-CS-OFF1): "הוּא עָצַר צַעַד אֶחָד לִפְנֵי הַבַּיִת. כַּמָּה רִבּוּעִים עוֹד?" *It stopped one step before the house. How many more squares?*
- **Debug cleared** (M-CS-FIXALL): "לֹא צָרִיךְ לִמְחֹק הַכֹּל! נַרְאֶה אֶת הַתָּכְנִית צַעַד אַחַר צַעַד וְנִמְצָא אֵיפֹה הִיא מַפְתִּיעָה." *No need to delete everything! Let's watch the program step by step and find where it surprises us.* The step-through mode switches on.

**Hints:**
- **H1, step-through.** Each card lights up as the robot moves. "נַרְאֶה מָה כׇּל כַּרְטִיס עוֹשֶׂה." *Let's see what each card does.*
- **H2, a different representation.** Rotate the board so the robot faces up (R1). The child may also stand up: "קוּמוּ וְהִסְתּוֹבְבוּ כְּמוֹ הָרוֹבּוֹט." *Stand up and turn like the robot.*
- **H3, worked example.** Footprints appear on the correct path; the child places the cards along it.

**Celebration.** "הַתָּכְנִית שֶׁלָּכֶם עָבְדָה! תִּכְנַנְתֶּם, בְּדַקְתֶּם וְתִקַּנְתֶּם — כְּמוֹ מְתַכְנְתִים אֲמִתִּיִּים." *Your program worked! You planned, checked and fixed — like real programmers.* Then *flavour:celebrate*. The robot's house lights up, and a new room is added to the robot's home in the child's world.

### 7.4 Lesson script 3: Band C, Math. "The class bake sale" (MATH-C-05 / MATH-C-07, with M-SUB-SMALLBIG diagnosis)

| | |
|---|---|
| **Skills** | MATH-C-05 2-digit subtraction with regrouping; MATH-C-07 word problems; MATH-C-22 shekels. |
| **Length** | ~8 min, 6 items. Representations R3 (bake sale), R1 (base-ten blocks: rods = ten, cubes = one), R2 (open number line), R5 (column). Equations are always laid out LTR. |

| # | Screen | Tutor line (Hebrew) | Gloss | Correct answer |
|---|---|---|---|---|
| 1 | Retrieval: `13 − 6 = □` (EquationRow LTR) | כַּמָּה זֶה שְׁלוֹשׁ־עֶשְׂרֵה פָּחוֹת שֵׁשׁ? | *What is thirteen minus six?* | **7** |
| 2 | 52 cookies on trays (5 trays of 10 + 2) | אָפִינוּ חֲמִשִּׁים וּשְׁתַּיִם עוּגִיּוֹת. מָכַרְנוּ עֶשְׂרִים וָשֶׁבַע. כַּמָּה נִשְׁאֲרוּ? | *We baked 52 cookies. We sold 27. How many are left?* | **25**. Distractors: 35 → M-SUB-SMALLBIG; 79 → M-KEYWORD/op; 15 → M-REGROUP-FORGET. |
| 3 | If correct: U6 explain — three reason pictures (blocks unbundled; number line 27 → 30 → 50 → 52; "I just knew") | אֵיךְ חִשַּׁבְתֶּם? אֶפְשָׁר לְסַפֵּר אוֹ לִבְחֹר תְּמוּנָה. | *How did you work it out? Tell me or pick a picture.* | Any reason picture; the voice answer is classified (§11.4). |
| 4 | Error-spot (U5): "a friend wrote" `64 − 38 = 34` | חָבֵר כָּתַב שֶׁשִּׁשִּׁים וְאַרְבַּע פָּחוֹת שְׁלוֹשִׁים וּשְׁמוֹנֶה זֶה שְׁלוֹשִׁים וְאַרְבַּע. מָה דַּעְתְּכֶם? | *A friend wrote that 64 minus 38 is 34. What do you think?* | Wrong → **26**. Tap the ones column. Voice reason: "הוּא הוֹרִיד אַרְבַּע מִשְּׁמוֹנֶה" (*he took 4 from 8*). |
| 5 | Money transfer (U3): a cake costs ₪35; pay with a ₪50 note | עוּגָה עוֹלָה שְׁלוֹשִׁים וַחֲמִשָּׁה שְׁקָלִים. שִׁלַּמְנוּ בִּשְׁטָר שֶׁל חֲמִשִּׁים. כַּמָּה עֹדֶף? | *A cake costs ₪35. We paid with a ₪50 note. How much change?* | **₪15** ("חֲמִשָּׁה־עָשָׂר שְׁקָלִים / חֲמֵשׁ־עֶשְׂרֵה" both accepted). |
| 6 | Reversible (U4): `□ − 27 = 25` | אֵיזֶה מִסְפָּר, פָּחוֹת עֶשְׂרִים וָשֶׁבַע, נוֹתֵן עֶשְׂרִים וְחָמֵשׁ? | *Which number, minus 27, gives 25?* | **52** |

**Wrong-answer feedback:**
- **35** (M-SUB-SMALLBIG): "מְעַנְיֵן! בּוֹאוּ נִבְדֹּק עִם הַקֻּבִּיּוֹת: יֵשׁ רַק שְׁתֵּי עוּגִיּוֹת בּוֹדְדוֹת — אֶפְשָׁר לָקַחַת מֵהֶן שֶׁבַע?" *Interesting! Let's check with the blocks: there are only two single cookies — can we take seven from them?*
- **79**: "שִׂימוּ לֵב — מָכַרְנוּ, אָז יֵשׁ לָנוּ יוֹתֵר אוֹ פָּחוֹת עוּגִיּוֹת?" *Notice — we sold some, so do we have more cookies or fewer?*
- **15**: "קָרוֹב מְאוֹד! בּוֹאוּ נִסְפֹּר אֶת הָעֲשָׂרוֹת שֶׁנִּשְׁאֲרוּ." *Very close! Let's count the tens that are left.*

**Hints:**
- **H1.** Highlight the 2 single cookies and the 7. "בּוֹאוּ נַתְחִיל מֵהַיְּחִידוֹת. יֵשׁ מַסְפִּיק?" *Let's start from the ones. Are there enough?*
- **H2, switch to R1.** Drag a tray of 10 to "open" it into 10 singles: "פּוֹתְחִים מַגָּשׁ שֶׁל עֶשֶׂר" (*open a tray of ten*). Or switch to R2, counting up on a number line from 27 → 30 → 50 → 52.
- **H3, worked example.** "פָּתַחְנוּ מַגָּשׁ: עַכְשָׁו יֵשׁ שְׁתֵּים־עֶשְׂרֵה בּוֹדְדוֹת. שְׁתֵּים־עֶשְׂרֵה פָּחוֹת שֶׁבַע — חָמֵשׁ. אַרְבָּעָה מַגָּשִׁים פָּחוֹת שְׁנַיִם — שְׁנַיִם. כַּמָּה בַּסַּךְ הַכֹּל?" *We opened a tray: now there are 12 singles. 12 minus 7 — 5. Four trays minus two — two. How many in total?*

**Celebration.** "פִּתַּרְתֶּם, הִסְבַּרְתֶּם וּמְצָאתֶם טָעוּת שֶׁל חָבֵר. זוֹ חֲשִׁיבָה שֶׁל מָתֵמָטִיקָאִים!" *You solved it, explained it and found a friend's mistake. That's mathematicians' thinking!* Then *flavour:celebrate*, plus a bakery shelf in the child's town fills with the cookies they "saved".

### 7.5 Example items (36), with tagged distractors

| # | Skill | Band | Template | Hebrew prompt (gloss) | Answer | Distractors → tag |
|---|---|---|---|---|---|---|
| 1 | NUM-A-04 | A | T02 | כַּמָּה כַּדּוּרִים יֵשׁ? (*How many balls?*) — 4 | 4 | 5 → DOUBLE; 3 → SKIP |
| 2 | NUM-A-05 | A | T14 | כַּמָּה נְקֻדּוֹת רְאִיתֶם? (*How many dots did you see?*) — 3 flashed | 3 | 2, 4 → logged only (subitizing items are fluency items, not diagnostic) |
| 3 | NUM-A-12 | A | T01 | אֵיפֹה יֵשׁ יוֹתֵר דָּגִים? (*Where are there more fish?*) — 4 big vs 5 small | the 5 small | 4 big → M-CNT-SIZE |
| 4 | NUM-A-13 | A | T01 | מִי הָרִאשׁוֹן בַּתּוֹר? (*Who is first in line?*) | the front animal | the last → M-ORD-CARD |
| 5 | NUM-A-14 | A | T01 | כַּמָּה צִפּוֹרִים בַּקֵּן עַכְשָׁו? (*How many birds in the nest now?*) — all flew away | 0 (אֶפֶס / אֵין) | 1 → M-NUM-ZERO |
| 6 | COL-A-02 | A | T01 | אֵיפֹה הַבָּלוֹן הַכָּחֹל? (*Where is the blue balloon?*) | blue | green → M-COL-NAME |
| 7 | COL-A-07 | A | T01 | תְּנוּ לִי אֶת הַבֻּבָּה הָאֲדֻמָּה. (*Give me the red doll.*) | the red doll | red ball → M-COL-ONEATTR; blue doll |
| 8 | SHP-A-03 | A | T01 | אֵיפֹה עוֹד רִבּוּעַ? (*Where is another square?*) | the tilted square | a long thin rectangle → M-SHP-SQRECT; a non-square rhombus → M-SHP-PROTO (attends to "pointy look", not sides and corners) |
| 9 | SHP-A-08 | A | T03 | שִׂימוּ אֶת הֶחָתוּל מִתַּחַת לַשֻּׁלְחָן. (*Put the cat under the table.*) | under | on → M-SPACE-WORD |
| 10 | LOG-A-06 | A | T05 | מָה בָּא אַחֲרֵי? 🍎🍌🍎🍌🍎… (*What comes next?*) | 🍌 | 🍎 → M-PAT-NEXT |
| 11 | CS-A-04 | A | T07 | עִזְרוּ לַחִפּוּשִׁית לְהַגִּיעַ לָעָלֶה. (*Help the beetle reach the leaf.*) — 2 up | ⬆⬆ | ⬆⬆⬆ → M-CS-OFF1 |
| 12 | MATH-A-03 | A | T22 | חַלְּקוּ אֶת הָעוּגִיּוֹת בְּשָׁוֶה בֵּין שְׁנֵי הַדֻּבִּים. (*Share the cookies fairly between the two bears.*) — 6 | 3 & 3 | 4 & 2 → M-SHARE-UNEQ |
| 13 | NUM-B-02 | B | T01 | מָה בָּא אַחֲרֵי עֶשְׂרִים וְתֵשַׁע? (*What comes after 29?*) | 30 | 20 → M-CNT-DECADE |
| 14 | NUM-B-08 | B | T01 | אֵיפֹה הַמִּסְפָּר שְׁתֵּים־עֶשְׂרֵה? (*Where is the number 12?*) | 12 | 21 → M-NUM-REV; 2 |
| 15 | NUM-B-12 | B | T01 | אֵיזוֹ הַבֻּבָּה הַשְּׁלִישִׁית? (*Which is the third doll?*) | the 3rd | three dolls tapped → M-ORD-CARD |
| 16 | NUM-B-13 | B | T09 | אֵיפֹה גָּר הַמִּסְפָּר שֶׁבַע? (*Where does 7 live?*) — a 0–10 line | position 7 | near 3 (counted from the right) → M-NL-DIR |
| 17 | NUM-B-14 | B | T22 | בְּכַמָּה דְּרָכִים אֶפְשָׁר לָשִׂים 5 צִפּוֹרִים עַל שְׁנֵי עֲנָפִים? (*How many ways can 5 birds sit on two branches?*) | 6 ways (0+5…5+0) | 3 → missed the reverse pairs |
| 18 | COL-B-01 | B | T11 | מָה יֵצֵא אִם נְעַרְבֵּב צָהֹב וְכָחֹל? (*What will we get if we mix yellow and blue?*) | green | blue → M-COL-MIX |
| 19 | COL-B-03 | B | T03 | שִׂימוּ אֶת כׇּל הַכְּחֻלִּים בַּסַּל. (*Put all the blue ones in the basket.*) — includes light and dark blue | all blues | leave out light blue → M-COL-SHADE |
| 20 | SHP-B-01 | B | T01 | אֵיזוֹ צוּרָה הִיא מְשֻׁלָּשׁ? (*Which shape is a triangle?*) | the long thin triangle | open 3-line figure → M-SHP-CLOSED; a triangle with a curved side |
| 21 | SHP-B-10 | B | T10 | הַשְׁלִימוּ אֶת הַפַּרְפָּר שֶׁיִּהְיֶה סִימֶטְרִי. (*Complete the butterfly so it's symmetric.*) | mirrored half | a copied half → M-SYM-SHIFT |
| 22 | LOG-B-02 | B | T05 | אֵיזֶה חֵלֶק חוֹזֵר? 🔴🔴🔵🔴🔴🔵 (*Which part repeats?*) | 🔴🔴🔵 | 🔴🔵 → M-PAT-UNIT |
| 23 | LOG-B-09 | B | T01 | זֶה לֹא אָדֹם וְלֹא עִגּוּל. מָה זֶה? (*It's not red and not a circle. What is it?*) | the blue square | the red square → M-NOT |
| 24 | CS-B-06 | B | T07 | אֵיךְ אֶפְשָׁר לְקַצֵּר אֶת הַתָּכְנִית? (*How can we make the program shorter?*) ⬆↱⬆↱⬆↱ | repeat ×3 [⬆↱] | ×6 → M-LOOP-COUNT |
| 25 | MATH-B-02 | B | T13 | בַּכִּתָּה 7 יְלָדִים. 3 בַּחוּץ. כַּמָּה בִּפְנִים? (*7 children in the class. 3 are outside. How many are inside?*) | 4 | 10 → M-PPW |
| 26 | MATH-B-09 | B | T08 | מָה צָרִיךְ לָשִׂים כְּדֵי שֶׁיִּהְיֶה שָׁוֶה? `3 + 4 = □ + 2` (*What do we need so it's equal?*) | 5 | 7 → M-EQ-OPER; 9 → M-EQ-OPER (adds all) |
| 27 | MATH-B-15 | B | T18 | מָה הַשָּׁעָה? (*What time is it?*) — 3:00 | 3 o'clock (שָׁלוֹשׁ) | 12 → M-CLOCK-HANDS |
| 28 | MATH-B-17 | B | T17 | שַׁלְּמוּ 7 שְׁקָלִים. (*Pay 7 shekels.*) — coins 5, 2, 1, 1 | 5+2 (or 5+1+1) | three coins of any value → M-MONEY-COUNT |
| 29 | NUM-C-03 | C | T01 | כַּמָּה עֲשָׂרוֹת יֵשׁ בַּמִּסְפָּר 30? (*How many tens are in 30?*) | 3 | 0 → M-PV-FACE |
| 30 | NUM-C-04 | C | T01 | אֵיזֶה סִימָן מַתְאִים? `47 □ 74` (*Which sign fits?*) | `<` | `>` → M-SIGN-DIR / M-PV-FACE |
| 31 | NUM-C-07 | C | T01 | אֵיפֹה הַמִּסְפָּר שְׁלֹשׁ מֵאוֹת וְחָמֵשׁ? (*Where is three hundred and five?*) | 305 | 35, 3005 → M-PV-ZERO |
| 32 | MATH-C-05 | C | T01 | `52 − 27 = □` | 25 | 35 → M-SUB-SMALLBIG; 15 → M-REGROUP-FORGET |
| 33 | MATH-C-07 | C | T13 | לְדָנָה 8 מַדְבֵּקוֹת, 3 יוֹתֵר מִנּוֹעָה. כַּמָּה לְנוֹעָה? (*Dana has 8 stickers, 3 more than Noa. How many does Noa have?*) | 5 | 11 → M-KEYWORD |
| 34 | MATH-C-11 | C | T22 | `4 × 6 = □` — an array of 4 rows | 24 | 10 → M-MUL-ADD; 20 |
| 35 | MATH-C-16 | C | T23 | מָה יוֹתֵר גָּדוֹל — שְׁלִישׁ פִּיצָה אוֹ רֶבַע פִּיצָה? (*Which is bigger — a third of a pizza or a quarter of a pizza?*) | a third | a quarter → M-FRAC-BIGDEN; "the same" → M-FRAC-ONEPIECE |
| 36 | CS-C-04 | C | T07 | הוֹסִיפוּ כְּלָל: אִם יֵשׁ קִיר — … (*Add a rule: if there's a wall — …*) | "if wall → turn, else forward" | reversed if/else → M-IF-REVERSE |

## 8. Hebrew language specifics for content

### 8.1 Counting forms and number agreement

| Use | Form | Example |
|---|---|---|
| **Abstract counting, arithmetic, numerals read aloud** | **Feminine** forms. This is the Ministry's language guidance: feminine for counting, arithmetic, phone numbers and similar uses. | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ, שֵׁשׁ, שֶׁבַע, שְׁמוֹנֶה, תֵּשַׁע, עֶשֶׂר. `3 + 4 = 7` is read "שָׁלוֹשׁ וְעוֹד אַרְבַּע שָׁוֶה (or זֶה) שֶׁבַע". |
| **Counting masculine nouns** | Masculine numeral, which for 3–10 **ends in ־ָה**: the "reverse" agreement pattern | שְׁלוֹשָׁה כְּלָבִים, חֲמִשָּׁה בָּלוֹנִים, עֲשָׂרָה כַּדּוּרִים |
| **Counting feminine nouns** | Feminine numeral, with no ־ָה | שָׁלוֹשׁ בֻּבּוֹת, חָמֵשׁ צִפּוֹרִים (צִפּוֹר is feminine!), עֶשֶׂר מְכוֹנִיּוֹת |
| **One** | Comes **after** the noun and agrees with it | כֶּלֶב אֶחָד, בֻּבָּה אַחַת |
| **Two** | Absolute שְׁנַיִם/שְׁתַּיִם; before a noun שְׁנֵי/שְׁתֵּי | שְׁנֵי כְּלָבִים, שְׁתֵּי בֻּבּוֹת |
| **Teens** | Masculine: אַחַד־עָשָׂר, שְׁנֵים־עָשָׂר, שְׁלוֹשָׁה־עָשָׂר… Feminine: אַחַת־עֶשְׂרֵה, שְׁתֵּים־עֶשְׂרֵה, שְׁלוֹשׁ־עֶשְׂרֵה… | שְׁתֵּים־עֶשְׂרֵה עוּגִיּוֹת; שְׁנֵים־עָשָׂר יְלָדִים |
| **Tens and compounds** | The tens word is gender-invariant; the unit agrees and comes after it, joined with ו | עֶשְׂרִים וְשָׁלוֹשׁ בֻּבּוֹת / עֶשְׂרִים וּשְׁלוֹשָׁה כְּלָבִים |
| **"The three …"** (construct, definite) | Masculine שְׁלֹשֶׁת הַ־; feminine שְׁלוֹשׁ הַ־ | שְׁלֹשֶׁת הַדֻּבִּים, שְׁלוֹשׁ הַבֻּבּוֹת |
| **Shekels** | שֶׁקֶל is masculine; אֲגוֹרָה is feminine; "a shekel and a half" is שֶׁקֶל וָחֵצִי | חֲמִשָּׁה שְׁקָלִים; עֶשֶׂר אֲגוֹרוֹת |
| **Ordinals** | Agree in gender; written content uses ordinals up to עֲשִׂירִי | רִאשׁוֹן/רִאשׁוֹנָה, שֵׁנִי/שְׁנִיָּה, שְׁלִישִׁי/שְׁלִישִׁית, רְבִיעִי/רְבִיעִית, חֲמִישִׁי/חֲמִישִׁית, שִׁשִּׁי/שִׁשִּׁית, שְׁבִיעִי/שְׁבִיעִית, שְׁמִינִי/שְׁמִינִית, תְּשִׁיעִי/תְּשִׁיעִית, עֲשִׂירִי/עֲשִׂירִית |
| **Days of the week** | Counted from יוֹם רִאשׁוֹן (Sunday) | יוֹם רִאשׁוֹן, שֵׁנִי, שְׁלִישִׁי, רְבִיעִי, חֲמִישִׁי, שִׁשִּׁי, שַׁבָּת |

**Policy.**
1. **The voice-over always models normative agreement.** Content picks nouns of both genders in balance, so children hear both.
2. **The app accepts what children actually say.**
   - In colloquial Israeli Hebrew, numerals tend toward the neutral, usually feminine, form even with masculine nouns (Gender neutralization study, IUCC).
   - So a child who says "שָׁלוֹשׁ כְּלָבִים" is **correct about the number**. The tutor does not correct grammar during maths.
3. **Only the AI tutor's dynamic lines** may lightly recast. It repeats the answer in normative form without a correction cue: child: "שָׁלוֹשׁ כְּלָבִים!" → tutor: "נָכוֹן, שְׁלוֹשָׁה כְּלָבִים!". It never says "you said it wrong".
4. **Number–noun gender is not a maths skill and is never scored.**
5. **Teen order.** In "שְׁלוֹשׁ־עֶשְׂרֵה" the ones are spoken before the ten, the reverse of the digits "13". This is the source of M-NUM-TEEN. Two-digit numbers from 20 up are spoken tens-first (עֶשְׂרִים וְשָׁלוֹשׁ), which matches the digit order.

### 8.2 Core vocabulary (with gender where relevant)

**Colours.** Adjectives agree with the noun.

| m. | f. | m. pl. | f. pl. | Gloss |
|---|---|---|---|---|
| אָדֹם | אֲדֻמָּה | אֲדֻמִּים | אֲדֻמּוֹת | red |
| כָּחֹל | כְּחֻלָּה | כְּחֻלִּים | כְּחֻלּוֹת | blue |
| צָהֹב | צְהֻבָּה | צְהֻבִּים | צְהֻבּוֹת | yellow |
| יָרֹק | יְרֻקָּה | יְרֻקִּים | יְרֻקּוֹת | green |
| כָּתֹם | כְּתֻמָּה | כְּתֻמִּים | כְּתֻמּוֹת | orange |
| סָגֹל | סְגֻלָּה | סְגֻלִּים | סְגֻלּוֹת | purple |
| וָרֹד | וְרֻדָּה | וְרֻדִּים | וְרֻדּוֹת | pink |
| שָׁחֹר | שְׁחֹרָה | שְׁחֹרִים | שְׁחֹרוֹת | black |
| לָבָן | לְבָנָה | לְבָנִים | לְבָנוֹת | white |
| אָפֹר | אֲפֹרָה | אֲפֹרִים | אֲפֹרוֹת | grey |
| חוּם | חוּמָה | חוּמִים | חוּמוֹת | brown (often invariant חוּם in speech; accept both) |

- **Invariable colour nouns** used as adjectives: תְּכֵלֶת (*light blue*), זָהָב (*gold*), כֶּסֶף (*silver*), בֶּז' (*beige*, Band C only). For example "כַּדּוּר תְּכֵלֶת", "שִׂמְלָה תְּכֵלֶת".
- Light and dark: בָּהִיר/בְּהִירָה, כֵּהֶה/כֵּהָה, for example "כָּחֹל בָּהִיר", "יְרֻקָּה כֵּהָה".

**Shapes.** Each noun has a fixed gender, which matters for agreement: "עִגּוּל גָּדוֹל" but "צוּרָה גְּדוֹלָה".
- 2D: עִגּוּל (circle, m), רִבּוּעַ (square, m), מְשֻׁלָּשׁ (triangle, m), מַלְבֵּן (rectangle, m), מְרֻבָּע (quadrilateral, m), מְחֻמָּשׁ, מְשֻׁשֶּׁה, מְעֻיָּן (rhombus), דַּלְתּוֹן (kite), טְרַפֵּז (trapezoid), אֶלִיפְּסָה (oval, f), כּוֹכָב (star), לֵב (heart).
- 3D: קֻבִּיָּה (cube, f), תֵּבָה (box, f), גְּלִיל (cylinder), חָרוּט (cone), כַּדּוּר (sphere/ball), פִּירָמִידָה (f).
- Parts: צֶלַע (side, f; plural צְלָעוֹת), קָדְקוֹד (vertex; plural קָדְקוֹדִים), פֵּאָה (face), מִקְצוֹעַ (edge), זָוִית (angle), יָשָׁר/קַו יָשָׁר (straight line), קֶטַע (segment), עָקֹם (curved), סָגוּר/פָּתוּחַ (closed/open).
- **Watch:** רִבּוּעַ (square) and מְרֻבָּע (quadrilateral) sound alike to children. They are taught in separate units (SHP-A-02 vs SHP-B-01), always with pictures.

**Maths words.**

| Hebrew | Gloss | Band |
|---|---|---|
| וְעוֹד, פָּחוֹת | plus, minus | B |
| שָׁוֶה / זֶה / יוֹצֵא | equals: normative / children's "is" / "comes out". Content uses שָׁוֶה; "זֶה כְּמוֹ" (*same as*) supports the balance meaning | B |
| יוֹתֵר, פָּחוֹת, אוֹתוֹ מִסְפָּר, הֲכִי הַרְבֵּה, הֲכִי מְעַט | more, fewer/less, the same number, the most, the fewest | A |
| גָּדוֹל מִ־, קָטָן מִ־ | bigger than, smaller than | B |
| כַּמָּה יוֹתֵר?, כַּמָּה חָסֵר? | how many more? how many are missing? | B |
| עֲשָׂרוֹת, יְחִידוֹת, מֵאוֹת | tens, ones, hundreds | C |
| זוּגִי, אִי־זוּגִי | even, odd | B–C |
| כָּפוּל, לְחַלֵּק בְּ־ | times (school usage), divided by | C |
| סְכוּם, הֶפְרֵשׁ, מַכְפֵּלָה, מָנָה, שְׁאֵרִית | sum, difference, product, quotient, remainder (formal; grade 3) | C |
| חֵצִי, רֶבַע, שְׁלִישׁ | half, quarter, third | B–C |
| עֹדֶף, מְחִיר, לְשַׁלֵּם | change, price, to pay | B |
| שֶׁקֶל/שְׁקָלִים, אֲגוֹרָה/אֲגוֹרוֹת, מַטְבֵּעַ, שְׁטָר | shekel(s), agora(s), coin, banknote | B |
| אֹרֶךְ, אָרֹךְ/קָצָר, גָּבֹהַּ/נָמוּךְ, כָּבֵד/קַל, מָלֵא/רֵיק | length, long/short, tall/short, heavy/light, full/empty | A |
| שָׁעוֹן, מָחוֹג קָצָר / מָחוֹג אָרֹךְ, חֲצִי שָׁעָה, רֶבַע שָׁעָה, דַּקָּה | clock, short hand / long hand, half an hour, quarter of an hour, minute | B–C |

**Spatial words.**

| Hebrew | Gloss | Band |
|---|---|---|
| עַל, מִתַּחַת לְ־, מֵעַל לְ־, בְּתוֹךְ, לְיַד, בֵּין | on, under, above, inside, next to, between | A |
| לִפְנֵי, מֵאֲחוֹרֵי, לְמַעְלָה, לְמַטָּה, בָּאֶמְצַע, בַּפִּנָּה, קָרוֹב, רָחוֹק | in front of, behind, up, down, in the middle, in the corner, near, far | A–B |
| יָמִין/שְׂמֹאל (nouns), יָמִינָה/שְׂמֹאלָה (to the right/left), יְמָנִי/שְׂמָאלִי (adjectives) | right/left | B |
| קָדִימָה, אֲחוֹרָה, פְּנִיָּה, לְהִסְתּוֹבֵב | forward, backward, a turn, to turn around | B |

**CS words for children.** Following the Ministry CT booklet, technical terms such as *אַלְגּוֹרִיתְם* (algorithm) and *הַפְשָׁטָה* (abstraction) are for adults. Children hear:

| Concept | Children hear | Band |
|---|---|---|
| program | תׇּכְנִית (needs the qamats qatan glyph) or רֶצֶף צְעָדִים (*a sequence of steps*) | A–C |
| step, command, card | צַעַד, פְּקֻדָּה, כַּרְטִיס | A–C |
| run | לְהַפְעִיל (*to run*) ▶ | A–C |
| repeat | חֲזֹר 3 פְּעָמִים (*repeat 3 times*), חֲזָרָה | B |
| condition | אִם… אָז… (*if… then…*); אַחֶרֶת (*otherwise*) | B (rules), C (else) |
| event | כַּאֲשֶׁר לוֹחֲצִים (*when we tap*) | B |
| bug | טָעוּת / תַּקָּלָה (*mistake / glitch*); the playful "בָּאג" (a cartoon bug) from Band C | A–C |
| fix | לְתַקֵּן | A–C |
| plan | לְתַכְנֵן | A–C |
| decompose | לְחַלֵּק לַחֲלָקִים קְטַנִּים (*split into small parts*) | B–C |
| variable | קֻפְסָה עִם מִסְפָּר (*a box with a number*); מִשְׁתַּנֶּה (*variable*) only in C | C |

### 8.3 Instructions for pre-readers

- **Audio first.** Each screen has one short spoken instruction, ≤ 8 words in Band A and ≤ 12 in Band B. It names the action and the object: "לִלְחֹץ עַל הַבָּלוֹן הַכָּחֹל" (*tap the blue balloon*).
- **Verb forms.**
  - Recorded VO uses the **plural imperative** (לִחֲצוּ, גִּרְרוּ, סִפְרוּ — *tap, drag, count*), **"let's" forms** (בּוֹאוּ נִסְפֹּר) or the **infinitive** (לִלְחֹץ, לִגְרֹר — *to tap, to drag*).
  - Use the plural imperative for actions, and "let's" for joint thinking.
  - These are the forms used in the Ministry's own early-grade booklet (צִבְעוּ, הַקִּיפוּ, הַשְׁלִימוּ — *colour, circle, complete*).
- **Same action, same words, same icon** everywhere. A tap is always a finger icon plus לִלְחֹץ; a drag is a hand-with-arrow icon plus לִגְרֹר.
- **Model, don't describe.** For new templates, an animated ghost hand shows the action once.
- **Replay** (🔊) on every screen. It replays the instruction, not the hint.
- **Questions end with a pause** of 1.5–2 s before any choices animate in.
- **Avoid in instructions:** negatives for Band A ("לֹא…"), two-step instructions for Band A, and pronouns without a referent ("שִׂימוּ אוֹתוֹ שָׁם", *put it there*).

### 8.4 Nikud policy per band

| Band | Child-facing text | Nikud |
|---|---|---|
| A | Captions hidden by default (adults can show them). Only numerals, the child's avatar name and icons appear on screen. | Full nikud wherever text appears |
| B | Short captions synced with VO (word-by-word highlight). Large font. | **Full nikud** on all child-facing text |
| C | Instructions as text plus audio. | Full nikud through grade 2. In grade 3, nikud on content words and ambiguous words, with a parent toggle for "ניקוד מלא" (*full nikud*). |

- **Spelling.** Follow the Hebrew Academy rules for vocalised text (*כְּתִיב מְנֻקָּד*), for example בֻּבָּה and צָהֹב.
- **The language editor decides on any deviation** toward the full-spelling-plus-nikud style that some early-reader books use. Consistency within the app matters more than the choice itself.
- Nikud is stored in content (tech.md §4.2). The *qamats qatan* in תׇּכְנִית and כׇּל must render correctly.
- Maths words on number tiles appear without nikud only in Band C and only when the word is also spoken.

### 8.5 Voice-over style guide

**Tone and pace.**
- **Tone:** warm, calm and curious. The voice of a kind גַּנֶּנֶת or older cousin, not a TV host. Enthusiasm is kept for real achievements.
- **Pace:** Band A about 25–30% slower than adult conversation; Band B about 15% slower; Band C near-natural.
  - Leave clear pauses between the number words when counting.
  - Pause 1.5–2 s after every question.
- **Prosody:** stress the key word, the one that carries the learning: "אֵיפֹה **יוֹתֵר** דָּגִים?" (*where are there more fish?*). There is no sing-song on mathematical words.
- **Length:** feedback ≤ 2 s; hints ≤ 5 s; worked examples ≤ 12 s; celebrations ≤ 3 s.

**Words and patterns to avoid.**
- Avoid "טָעוּת!" (*mistake!*) as a verdict, "לֹא נָכוֹן", "רַע", "אוּף" (*not right, bad, ugh*), sighing, and any sound of disappointment.
- Avoid "זֶה קַל" (*this is easy*): it makes failing shameful. Use "זֶה אֶתְגָּר" (*this is a challenge*) or "בּוֹאוּ נְנַסֶּה" (*let's try*).
- Avoid "מַהֵר" (*quick*), "מִי הִצְלִיחַ רִאשׁוֹן" (*who got it first*), and comparisons with others.
- Avoid person praise: "גְּאוֹן", "חָכָם/חֲכָמָה", "מֻכְשָׁר" (*genius, smart, gifted*).
- Avoid guilt and FOMO lines: "אֲנִי עָצוּב שֶׁהָלַכְתָּ" (*I'm sad you left*), "אַל תַּפְסִיקוּ עַכְשָׁו" (*don't stop now*).
- Avoid English loanwords where a child-friendly Hebrew word exists.
- Avoid babyish diminutives and baby talk. In Band C they feel patronising.

**Pronunciation.**
- Standard modern Israeli Hebrew.
- Keep the plosive פּ/בּ/כּ correct after prefixes in maths words, for example "וּשְׁתַּיִם", "בִּשְׁתַּיִם".
- The lexicon carries the pronunciation of every content word for VO actors and TTS (tech.md §4.6).

**Inclusivity.**
- Names and contexts should reflect the diversity of Israeli Hebrew-speaking families: for example נוֹעָה, אִיתַי, מַאיָה, יוֹסֵף, לִיאוֹר, תָּמָר, אֲבִיגַיִל, דָּנִיאֵל, מִיכָאֵל, נָתָן, אַיָּלָה.
- Holidays and Shabbat appear as optional, warm contexts, never as requirements.

### 8.6 Mixed-direction content: maths inside RTL screens

**Verified conventions.**
- Israeli maths notation runs **left to right** even though Hebrew text runs right to left. Examples:
  - equations: `3 + 4 = 7`;
  - number sequences and number lines, which ascend left to right as in the Ministry's grade 1 booklet (`0 1 2 … 10`);
  - x-axes, which run left to right in Israeli textbooks (Gorelik).
- A Haifa study found more errors on right-to-left number sets, which supports LTR for numbers.

**Rules for content.**
1. **Equations, number lines, hundred charts, rulers, number tracks and bar-chart x-axes are LTR.** They are never mirrored; tech.md's `EquationRow` lays them out.
2. **Reading the equation aloud:** the VO reads tokens left to right, and each token highlights as it is spoken. This teaches the reading direction of maths explicitly in Band B.
3. **Comparison signs `<` and `>` are Unicode bidi-mirrored.** In an RTL run, `<` *displays* as `>`. They may appear **only inside LTR math isolates** (EquationRow or a math token), never typed into Hebrew strings. The CMS lint must reject them outside math tokens. The same applies to brackets.
4. **Division sign.** Israeli elementary textbooks typically use the colon, `12 : 3`. **Verify against approved textbooks before content production**, and if confirmed, change tech.md's ÷ default.
   - Multiplication uses `×` in Bands B–C.
   - The minus sign is U+2212 (tech.md).
5. **Mixed sentences:** "יֵשׁ ‎`8`‎ תַּפּוּחִים" — a bare number is fine in Hebrew text. Expressions always go in an isolate.
6. **Shekel prices:** Band B uses coin images and whole shekels. Band C formats prices with ICU `he-IL` currency formatting. No decimals until Band C.

**Sequences that are not maths.** These follow **Hebrew reading order, right to left**, with an explicit start marker and an animated direction arrow:
- story strips;
- pattern rows ("what comes next?");
- picture routines.

Rationale: children read these as "text-like" sequences, and the Ministry's own kindergarten materials present them in reading order (assumption, to be validated in child tests, §15).

The **"next" slot sits at the left end**, so the question mark is always where the eye arrives last.

### 8.7 Right and left for children in an RTL interface (robot coding)

1. **Vertical program strip, top to bottom.** This avoids a clash between RTL reading order and LTR maths order. Each new card is added at the bottom, with a "1" marker at the top and step numbers. tech.md sets `sequenceDirection: vertical_ttb`.
2. **Arrows are absolute and never mirrored.** "↑ forward" means the robot's forward. Band A uses **direct-control** absolute arrows (⬆⬇ and toward a landmark) and **no right/left words**.
3. **Band A–B** use a **landmark language** first: "לְכִוּוּן הָעֵץ" (*toward the tree*), "לְכִוּוּן הַשֶּׁמֶשׁ" (*toward the sun*). The words יָמִין/שְׂמֹאל are introduced with a body anchor in SHP-B-12.
   - The anchor is a coloured band on the avatar's right wrist, matching the colour of the right-turn card (green). There is a matching parent prompt: "put a green sticker on your child's right hand".
   - Verbal left/right labels are typically learned around ages 6–7, and many adults remain unsure.
4. **Turns are robot-relative from Band B.** The robot has a visible face and a coloured "right glove". Items deliberately include a robot facing down or toward the child, to diagnose M-DIR-EGO. A rotate-board scaffold is available.
5. **Grid coordinates (Band C):** numbers run along the bottom, left to right (maths convention). Letters א, ב, ג… run down the side, top to bottom. No axis runs right to left, so the child never has to read a coordinate axis backwards.
6. **The UI chrome mirrors as normal for RTL** (Apple HIG): back/next, progress bars and the replay button position. **Never** mirror the robot's arrows, the clock, number lines, maps or illustrations.

## 9. Feedback & motivation pedagogy

### 9.1 Responding to correct answers

- **Name what was right and how**, in under 2 s: "חֲמִשָּׁה! סְפַרְתֶּם כׇּל אֶחָד פַּעַם אַחַת." *Five! You counted each one once.*
  - Specific, elaborative feedback is what most preschool edutainment games lack; they mostly offer generic "right/wrong" (Nikolayev et al. 2021 review).
- **Vary the lines.** Each template has ≥8 correct-feedback lines per band, and the same line is not repeated within 3 items.
- **Brief by default.** Most correct answers get a short sound plus one line. Bigger celebrations are kept for mastery moments (§9.5).
- **Correct after hints** is still praised for persisting: "לֹא וִתַּרְתֶּם — וּמְצָאתֶם!" *You didn't give up — and you found it!*

### 9.2 Responding to incorrect answers

**The sequence:**
1. Neutral acknowledgement, with no "wrong" word: "הַמְּמ… בּוֹאוּ נִבְדֹּק." *Hmm… let's check.*
2. **Diagnostic feedback** from the classifier (§6.3), which tells the child what to check, not just that they were wrong.
3. Retry.

**Visual and sound design.**
- No red X, no buzzer, and no shaking screen. The wrong choice gently fades back.
- The character looks *curious*, not sad.

**How many tries.** A child gets **three tries, with hints escalating each time.**

| Attempt | Response |
|---|---|
| 1st error | Diagnostic feedback, then H1 is available (auto after 6 s of inactivity in Band A) |
| 2nd error | H2: **switch representation** or add a model (§5.5) |
| 3rd error | H3: a **worked example**. The child then makes the final correct action themselves, so the item still ends in success. |

- After a worked example, the engine serves a **similar item** to try independently.
- The child **never sees more than 3 consecutive errors** on one skill. After 3 failed items in a row, the engine switches to an easier item, a prerequisite probe, or a different activity with a "let's come back to this later" framing (§10.4).
- 2-choice items allow only one retry, because a second guess is trivial. Then the worked example follows.

**Productive struggle.**
- Hints are *offered*, not forced: the "?" glows after a wait of 8 s in Band B and 12 s in Band C.
- The engine does not interrupt a child who is actively manipulating objects. Thinking time is protected.
- For Band C puzzle items (LOG-C, CS-C), the hint offer appears only after the first unsuccessful run.

### 9.3 Praising effort and strategy (core lines, gender-neutral)

| Hebrew | Gloss | Praises |
|---|---|---|
| נִסִּיתֶם כַּמָּה דְּרָכִים — וְזֶה עָזַר! | *You tried a few ways — and it helped!* | strategy flexibility |
| בְּדַקְתֶּם שׁוּב לִפְנֵי שֶׁעֲנִיתֶם. זֶה מַה שֶּׁמָּתֵמָטִיקָאִים עוֹשִׂים. | *You checked again before answering. That's what mathematicians do.* | checking |
| זֶה הָיָה קָשֶׁה, וְהַמֹּחַ שֶׁלָּכֶם הִתְאַמֵּץ וְגָדַל. | *That was hard, and your brain worked hard and grew.* | effort/growth |
| מְצָאתֶם אֶת הַטָּעוּת וְתִקַּנְתֶּם. כׇּל הַכָּבוֹד! | *You found the mistake and fixed it. Well done!* | debugging |
| הִשְׁתַּמַּשְׁתֶּם בָּעֶשֶׂר כְּדֵי לְחַשֵּׁב. רַעְיוֹן מְצֻיָּן! | *You used the ten to work it out. Great idea!* | specific strategy |
| טָעִינוּ? מְעֻלֶּה — עַכְשָׁו אֲנַחְנוּ יוֹדְעִים מָה לִבְדֹּק. | *We made a mistake? Excellent — now we know what to check.* | errors as information |
| עוֹד לֹא — אֲבָל כִּמְעַט. | *Not yet — but almost.* | "yet" framing |
| בִּקַּשְׁתֶּם עֶזְרָה — זֶה חָכָם לְבַקֵּשׁ עֶזְרָה. | *You asked for help — asking for help is smart.* | help-seeking (praises the action, not the person) |

**Rationale.** Process praise to toddlers predicted incremental mindsets and later achievement (Gunderson et al. 2018). Person praise ("you're so smart") is avoided entirely.

**Tutor lines with the child's gender.** The AI tutor's dynamic lines use the gender the parent chose, for example "נִסִּיתָ / נִסִּית כַּמָּה דְּרָכִים" (*you tried a few ways*, m/f).

### 9.4 Never shaming

- There are no lives, no "game over", no losing stars or stickers, and no visible score that falls.
- Mistakes are never shown to anyone else. Siblings on the same device can't see each other's errors (§10.6).
- "I don't know" is welcomed (§5.1).
- The engine never says the child "should already know" something. `needs_revisit` skills are framed as "watering the plant".
- No grade-level labels are shown to the child. The parent view describes skills, not grades (§12).

### 9.5 Celebrations that don't distract

| Moment | Celebration | Max length |
|---|---|---|
| Correct item | Sound plus one line plus a tiny character reaction | ≤ 2 s |
| End of activity | A summary of what was learned ("לָמַדְנוּ לִסְפֹּר עַד חָמֵשׁ", *we learned to count to five*) plus a world item | ≤ 5 s |
| Fresh mastery 🌿 | A plant grows on the map; the next skill opens | ≤ 5 s |
| Durable mastery 🌳 | A tree bears fruit; a permanent world item | ≤ 6 s, once |

**Celebration rules.**
- A celebration **restates the learning**, so it reinforces rather than distracts.
- **Never during thinking time**, and never with animation on screen while the next question is asked.
- Celebrations can be skipped with a tap after 1 s.
- There are no random jackpots or variable "surprise boxes", which are a slot-machine pattern.

### 9.6 Intrinsic vs extrinsic rewards

1. **Intrinsic first.** The main reward is competence. The child sees progress, such as the garden growing, or "now I can count to 20!", and solves interesting puzzles.
   - Mastery-driven world-building: each skill area has a corner of the child's world (a garden, a robot workshop, a shop) that grows **only through mastery**.
2. **Extrinsic, but tied to learning.** Stickers and world items are earned **for durable mastery and for effort milestones** (for example, "tried a new kind of puzzle"), never per tap and never for speed.
   - Each sticker shows the skill it came from ("מַדְבֵּקַת הַסְּפִירָה", *the counting sticker*), so rewards point back to learning.
   - The rewards are useful in the world: the child arranges them in their garden.
3. **No over-justification traps.** Free-play spaces, such as the paint studio, robot sandbox and shape builder, are open without rewards. They are where children practise because they want to.
4. **No currencies.** There are no coins to spend, no shop and no daily-login rewards.
5. **Streak language is soft.** "שִׂחַקְנוּ יַחַד 3 יָמִים הַשָּׁבוּעַ" (*we played together 3 days this week*) is shown to the parent only. A streak never "breaks".

### 9.7 Characters: motivation without distraction

**Favourite characters as motivation.**
- Children engage more and learn more with characters they like and trust. A companion who "learns alongside" the child turns practice into a social activity, which is Hirsh-Pasek's fourth pillar.
- The child chooses the companion, which supports autonomy, and can switch at any time.
- Companions remember the child's progress ("בַּפַּעַם הַקּוֹדֶמֶת בָּנִינוּ מִגְדָּל שֶׁל עֶשֶׂר", *last time we built a tower of ten*) but never personal details (§11.6).

**Heroes whose powers are strategies.** In the original superhero squad, each hero's "power" is a named strategy children can borrow. The strategy is the power, so using it *is* the learning.

| Hero (placeholder name) | Power = strategy | Used for | Power line (flavour slot `power`) |
|---|---|---|---|
| קַו־זִנּוּק (*Jump-Line*) | Jumping on the number line | NUM-B-13, MATH-B-08, MATH-C-04 | "כֹּחַ זִנּוּק! קוֹפְצִים עַד הָעֶשֶׂר." *Jump power! Jump to the ten.* |
| עֶשֶׂר־מְלֵאָה (*Full-Ten*) | Making ten / ten-frames | MATH-B-06/08 | "מְמַלְּאִים עֶשֶׂר!" *Let's fill a ten!* |
| עֵין־הַדֻּגְמָה (*Pattern-Eye*) | Spotting the repeating unit | LOG-B-02, CS-B-05 | "מָה חוֹזֵר?" *What repeats?* |
| מְפָרֵק (*The Splitter*) | Decomposing a problem into parts | CS-B-10, MATH-C-07 | "מְחַלְּקִים לַחֲלָקִים קְטַנִּים!" *Split it into small parts!* |
| בּוֹדֵק־כָּפוּל (*Double-Check*) | Checking the answer another way | U5, MATH-C-02 | "בּוֹדְקִים בְּדֶרֶךְ אַחֶרֶת!" *Check it another way!* |

- In a hint, the core line explains the strategy; the hero's power line is only a cue.
- The child can "call" a hero, which plays that hero's H2 representation. Over time the child calls the strategy by name: "אֲנִי אֶשְׁתַּמֵּשׁ בְּקַו־זִנּוּק!" (*I'll use Jump-Line!*).

**Limits: the learning moment always wins.**
1. **Quiet zone.** From the prompt's end until the child answers, characters may only blink, look at the task and give idle breathing. No jokes, no flavour lines, no movement across the play area.
2. **No character content in the item area.** Characters stay in their dock and never cover answer choices or manipulatives.
3. **Flavour ≤ 2 s.** At most one flavour line per item, and none during hints or worked examples, which are core only.
4. **No character stories inside lessons** beyond a one-line context. Longer character episodes, if the owner wants them, live outside learning sessions and are short (§15).
5. **No collect-the-character mechanics.** Characters are never locked behind payment or random rewards. New characters arrive for everyone, or unlock through *learning milestones*.
6. **Characters model learning, not perfection.** Heroes make mistakes too (they are used in U5 error-spotting) and use "not yet" language. A hero never says "too easy for me".
7. **Fear-free.** Heroes protect, build and fix. There are no villains to defeat under time pressure and no peril tied to wrong answers.

## 10. Adaptive learning rules

These rules parameterise tech.md's learning engine (BKT per skill, Elo-style item difficulty, spaced scheduler, session builder). Numbers are starting values to tune in the beta (§14).

### 10.1 Placement: gentle, game-like, per domain

- **Not a test.** Placement happens in the first 2–3 sessions as a "welcome to the world" adventure. Each domain has a **placement mini-game** of 4–8 items that adapts up and down, like a staircase.
  - Example (Numbers): "help the squirrel collect acorns" uses count (≤5) → count (≤10) → compare → read numerals → teen numbers.
- **Start point.** Each domain starts at the band suggested by the parent's age bracket, at the *start* of that band's middle unit.
- **Staircase.** Two correct answers move up one level; one error moves down one level, and the next item is easier.
  - It stops after 2 reversals or 8 items.
  - The placement is the highest level with ≥2/3 correct, **minus one unit**. Starting slightly easy builds confidence; the engine climbs fast if the child is ready.
- **Skipped skills** below the placement are marked "assumed", with a prior p = 0.85 (not mastered).
  - Assumed skills are verified through interleaved retrieval in the first 2 weeks.
  - A failed verification turns the skill into a normal learning target. No penalty is shown.
- **Effects on the child.** No results are shown to the child, and every placement item gives positive feedback.
- **Parents.** Parents see a summary: "נַתְחִיל מִכָּאן" (*we'll start here*), per domain. They can adjust it one level.

### 10.2 Mastery model

| Parameter | Value (starting point) |
|---|---|
| BKT prior p(L₀) | 0.2 for a new skill; 0.85 for an "assumed" skill |
| Credit by hint level (tech.md `creditByHintLevel`) | 1.0 none · 0.8 H1 · 0.5 H2 · 0.0 H3; "show me" = `unsure` (weight 0.3) |
| `fresh_mastery` | tech.md rule: P(L) ≥ 0.95, ≥ 4 successes over ≥ 2 days, mastery representation and checks passed. **Curriculum additions:** ≥ 2 representations; ≥ 1 check (2 for core skills); 6 successes for core skills |
| Advance | A skill unlocks when all prerequisites reach P(L) ≥ 0.8; at most 2 new skills per session (tech.md) |
| Review | A skill enters the spaced schedule at fresh mastery (§5.7) |
| Step back | p < 0.4 after ≥5 items, or a confirmed misconception tag, triggers a prerequisite probe and repair (§5.3) |
| `durable_mastery` | A delayed check passes ≥ 7 days later, using a different `variantGroup` item (tech.md) |
| `needs_revisit` | A delayed check fails, or R < 0.7; gentle re-teach (§5.7) |
| Guessing guard | tech.md sets BKT guess P(G) = 1/k. **Curriculum addition:** 2-option items count at most 50% of the success evidence |
| Fluency (Band C facts) | Median latency is measured silently and used only to schedule review; never shown |

### 10.3 Session composition

A **session** is one visit with a clear end. Defaults are 8 / 12 / 15 minutes by band (§2). The phases follow tech.md §7.7, and its per-band ranges apply.

| Segment | Share | Contents |
|---|---|---|
| Warm-up | 1–2 items | Easy, high-success retrieval |
| Repair | ≤ 25% | Active gaps and misconceptions, if any (§5.3) |
| Focus | 30–55% | 1–2 learning skills: a worked example first, then guided, then independent |
| Revisit checks | 15–30% (A → C) | Due checks, interleaved across domains in Bands B–C; Band A mostly blocked by domain |
| Delight | ~20% | Open space (paint, build, robot sandbox) or a cross-domain unit; no new demands |

**Rules.**
- **Mood check.** Every session includes ≥1 domain the child chose (from 2–3 offered) and ≥1 the engine chose.
- **Switching.** Activities switch every 2–4 min (A), 4–7 min (B) or 6–10 min (C).
- **Ending.** The session ends on success. The last item is always at p ≥ 0.85. A wind-down line follows: "לָמַדְנוּ הַיּוֹם… נִתְרָאֶה בַּפַּעַם הַבָּאָה" (*today we learned… see you next time*).
- **"One more?"** The child is never prompted. tech.md allows one optional "one more" if the parent enables it, and Curriculum recommends it be off by default. When the parent's daily limit is reached, the session ends gracefully after the current item.

### 10.4 Stuck or bored

| Signal | Interpretation | Response |
|---|---|---|
| 3 errors in a row on a skill, or 2 H3 worked examples in a row | Stuck | Stop the skill. Switch to an easier, related item, then a different activity. Schedule a re-teach with a new representation next session. Line: "נַחֲזֹר לָזֶה בְּפַעַם אַחֶרֶת. בּוֹאוּ נְשַׂחֵק בְּמַשֶּׁהוּ אַחֵר." *We'll come back to this another time. Let's play something else.* |
| Long inactivity (>20 s in Band A, >40 s in Band C) with no touches | Possibly stuck or distracted | First a gentle replay, then "?". After two inactivity events, offer a choice of activity. |
| Random rapid tapping (≥4 taps in 2 s on wrong targets) | Frustrated or exploring | Pause the scoring of that item. The character invites: "בּוֹאוּ נִנְשֹׁם רֶגַע" (*let's take a breath*); after a pause, an easier item. |
| ≥8 correct in a row at p > 0.95, all fast, no hints | Bored / under-challenged | Offer a "challenge" (אֶתְגָּר) item from the next skill. If correct, fast-track: skip the remaining practice and run the understanding check now. |
| Quits right after an error (logged) | Frustration | The next session starts with that domain's easiest due review, not the failed skill. |
| Picks the same domain every time | Preference | Respect it (≥50% of time), but the engine weaves other domains in through cross-domain units (X1–X8). |

### 10.5 Personal representation profile

The engine keeps, per child and domain, a success rate for each representation (R1–R5) after a failure. When choosing a repair, it picks the representation with the best record for this child, excluding the one that just failed. This uses Thompson sampling with a prior favouring CPA order. It is how "a different explanation" becomes "a better explanation for this child" over time.

### 10.6 Mixed-age siblings on one device

- **Profiles.** Each child has their own profile: avatar, companion, band per domain, gender form. A **picture-based profile picker** (avatar faces) opens the app. No reading or passwords are needed.
- **Wrong-profile guard.** If a "Band A" profile suddenly answers Band C items perfectly, or the reverse, the app asks once with a friendly check: "זֶה עֲדַיִן [avatar]?" (*is this still [avatar]?*), showing the avatar faces.
- **Together mode.** "מְשַׂחֲקִים יַחַד" (*playing together*) is for two children, or a parent and child.
  - Turns alternate. Each child gets items at **their own level** within the same shared scene: the older sibling plans a robot path, while the younger counts the steps.
  - Shared success celebrations. No head-to-head scoring.
- **Teach-back.** An older sibling can take the "helper" role for the younger one's item. The app prompts the older child to *give a hint, not the answer*. This counts as a U6 explain-back for the older child (logged as a separate reason category).
- **Data separation.** Data stays separate per profile. Together-mode responses are credited to the child whose turn it was.

### 10.7 Mapping to tech.md's data fields

| Curriculum term | tech.md field / value |
|---|---|
| Representation R1 / R2 / R3 / R4 / R5 | `representation`: `concrete` / `pictorial` / `story` / `embodied` / `symbolic` |
| Understanding check U1 / U2 / U3 / U4 / U5 / U6 | `checkType`: `predict` / `show_another_way` (**new**) / `transfer` / `reverse` / `error_spotting` / `explain_back` |
| Misconception tag `M-CNT-DOUBLE` | `misconception` id, e.g. `num.count.double_count`. The catalogue in §5.2 is the source list; the content team assigns dotted ids 1:1, and each catalogue row becomes a misconception record with `parentText` and `repairActivities`. |
| Dedicated diagnostic item | `purpose: probe` (no hints), or `purpose: diagnostic` |
| Expected wrong spoken answers | the `voice` block's `expectedErrors` with `misconception` |
| "Contradicts" item (§5.3, return step) | **new** field `contradicts: <misconception id>`, used by the session builder after repair |
| "Show me" / "I don't know" | `outcome: unsure` (BKT weight 0.3, no misconception evidence) |
| Core skill (≥ 3 dependants) | **new** `core: true`, which raises `masteryRequires.checkTypes` to 2 and the success count to 6 |

### 10.8 Today's Adventure (the bottle on the home island)

The bottle opens one stop, chosen by a pure, deterministic rule: a due revisit first once a day, then up to two lessons before the next revisit; new learning continues the land played last for up to three lessons, then moves to another land (lowest level first, then the land played longest ago); a lesson left right after an incorrect answer, and a skill already checked today, rest until the next day; when everything is finished, a known lesson is played again. Age enters only as parameters (band today, the school stage after B-29). Full rule, inputs and 28 worked examples: `docs/curriculum/todays-adventure-rule.md`.

## 11. The AI tutor's pedagogical behaviour

The AI tutor is the *dynamic layer* on top of authored content. Most of what children hear comes from authored core lines. The tutor speaks when a response needs a personalised next step: an unexpected spoken answer, an explain-back, or a choice of representation.

**Offline fallback.** tech.md's RuleTutor gives the same pedagogical actions offline. Every behaviour below must also have a rule-based fallback.

### 11.1 Persona

- **The tutor speaks through the child's chosen companion.** Its core pedagogy is identical for every character. Only the flavour slots differ (§7.1).
- **Personality.** A curious, patient learning partner who thinks aloud with the child: "בּוֹאוּ נִבְדֹּק יַחַד" (*let's check together*).
- **Honesty about being a program.** In the parents' setup, and when a child asks "אַתָּה אֲמִתִּי?" (*are you real?*), the tutor says it is a computer helper.
  - Child line: "אֲנִי עוֹזֵר־מַחְשֵׁב שֶׁאוֹהֵב חִידוֹת" (*I'm a computer helper who loves puzzles*), with gender per the character.
  - Research suggests transparency about AI's nature supports healthy boundaries (Xu, Joan Ganz Cooney Center).
- **Tutor dynamic lines** address the child in the gender the parent chose (נַסֵּה / נַסִּי, *try*). If no gender was chosen, they use the plural/"let's" forms.

### 11.2 May and may not

| The tutor MAY | The tutor MUST NOT |
|---|---|
| Ask **one** short question at a time (≤ 12 words in A, ≤ 15 in B, ≤ 20 in C) | Give explanations longer than 2 sentences, or lecture |
| Diagnose from the answer and the child's words, and pick the next representation from the item's authored options (§5.5) | Reveal the answer before hint level 3 (enforced by the gateway, tech.md `mustNotRevealBeforeHint`) |
| Recast the child's words in correct Hebrew without marking an error | Correct grammar or pronunciation during maths |
| Reflect the child's strategy back ("סָפַרְתָּ מִשְּׁמוֹנֶה הָלְאָה — רַעְיוֹן טוֹב", *you counted on from eight — good idea*) | Ask personal questions: name, address, school, family, feelings about home, photos, location |
| Briefly acknowledge feelings ("זֶה מְתַסְכֵּל לִפְעָמִים", *it's frustrating sometimes*) and offer a break or easier item | Chat off-topic, tell stories unrelated to the task, give opinions, discuss news, religion, politics, appearance or other people |
| Redirect politely to the task when the child goes off-topic | Promise rewards, create urgency, guilt ("אַל תֵּלֵךְ", *don't go*), or mention purchases |
| Say "I don't know" about non-task questions and redirect | Claim to be human, to have feelings, or to be the child's friend "more than" people |
| Hand off to the parent for anything sensitive (a script, §11.6) | Store or repeat anything personal the child volunteers; infer emotions for profiling |

### 11.3 Socratic patterns per band

| Band | Pattern | Example (core-style lines; tutor dynamic lines use the child's gender) |
|---|---|---|
| A | **Notice → do → say.** Point to one thing, ask for one action, name the result. Choice questions, not open ones. | "אֵיפֹה עוֹד פַּרְפָּר?" (*Where's another butterfly?*) → "אֲנַחְנוּ בְּשָׁלוֹשׁ. וְעַכְשָׁו?" (*We're at three. And now?*) |
| A | **Either-or** to scaffold language | "יֵשׁ פֹּה יוֹתֵר אוֹ פָּחוֹת?" (*Are there more here, or fewer?*) |
| B | **Predict → test → explain** | "מָה יִקְרֶה אִם נוֹסִיף עוֹד אֶחָד?" (*What will happen if we add one more?*) → [test] → "לָמָּה?" (*Why?*) |
| B | **Compare two answers** | "חָבֵר אָמַר תֵּשַׁע וְחָבֵר אָמַר שְׁמוֹנֶה. אֵיךְ נִבְדֹּק?" (*One friend said nine and one said eight. How can we check?*) |
| C | **What do you know? What do you need? How will you check?** | "מָה יָדוּעַ לָנוּ?" (*What do we know?*) → "מָה צָרִיךְ לִמְצֹא?" (*What do we need to find?*) → "אֵיךְ נִבְדֹּק שֶׁזֶּה נָכוֹן?" (*How will we check it's right?*) |
| C | **Generalise** | "זֶה תָּמִיד עוֹבֵד? נְנַסֶּה עִם מִסְפָּר אַחֵר." (*Does it always work? Let's try another number.*) |
| All | **Wait time** | After any question, the tutor waits ≥ 4 s (A), ≥ 5 s (B) or ≥ 6 s (C) before saying anything else |

### 11.4 Using the child's spoken answer

1. **A clear expected value** (from the accept-list) is treated as a tap on that value.
2. **A clear unexpected value** is mapped to a misconception tag if it is listed in `expectedErrors`, or if the template classifier recognises it. Otherwise it is logged as `M-UNKNOWN`.
3. **A partial answer**, such as the noun without a number, or "יוֹתֵר" without saying which set, gets one focused follow-up question: "כַּמָּה?" (*how many?*), "אֵיזֶה צַד?" (*which side?*).
4. **Hedged or uncertain** answers ("אוּלַי חָמֵשׁ?", *maybe five?*) count as an answer. The tutor responds to the uncertainty: "בּוֹא/בּוֹאִי נִבְדֹּק יַחַד" (*come, let's check together*).
5. **Unclear audio** gets one re-ask, then tap. It is never wrong.
6. **"I don't know" or "help"** is the "show me" path (§5.1), with praise for asking.
7. **Explain-back (U6).** The gateway gives the LLM the item, the correct answer and the authored **reason categories**:
   - for 8 + 5: `make_ten`, `count_on`, `doubles_near` (6+6+1), `count_all`, `known_fact`, `no_reason`, `incorrect_reason`;
   - the LLM returns one category plus a confidence;
   - the tutor reflects the strategy back ("הִשְׁלַמְתָּ לְעֶשֶׂר — דֶּרֶךְ חֲכָמָה", *you completed ten — a clever way*);
   - `incorrect_reason` with a correct answer triggers a gentle follow-up item, because the answer may have been a lucky guess;
   - language quality is never scored.
8. **Off-task speech.** The tutor makes one friendly redirect and never engages: "רַעְיוֹן מְעַנְיֵן! עַכְשָׁו בּוֹאוּ נַחֲזֹר לַחִידָה." *Interesting idea! Now let's get back to the puzzle.*

### 11.5 Example dialogues

**Band A (NUM-A-04), child gender: feminine**
> **Tutor:** כַּמָּה פַּרְפָּרִים יֵשׁ? *(How many butterflies are there?)*
> **Child:** פַּרְפָּר! *(Butterfly!)*
> **Tutor:** כֵּן, פַּרְפָּרִים! בּוֹאִי נִסְפֹּר אוֹתָם — תִּגְעִי בְּכׇל אֶחָד. *(Yes, butterflies! Let's count them — touch each one.)* `[partial answer → focused follow-up]`
> **Child:** (taps) אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. *(One, two, three, four, five.)* `[4 butterflies; one touched twice → M-CNT-DOUBLE]`
> **Tutor:** הַמְּמ… הַפַּרְפָּר הַזֶּה קִבֵּל שְׁנֵי מִסְפָּרִים. בּוֹאִי נַזִּיז כׇּל פַּרְפָּר לַפֶּרַח כְּשֶׁסּוֹפְרִים. *(Hmm… this butterfly got two numbers. Let's move each butterfly to the flower as we count.)* `[switch to R1]`
> **Child:** אַחַת… שְׁתַּיִם… שָׁלוֹשׁ… אַרְבַּע! *(One… two… three… four!)*
> **Tutor:** אַרְבָּעָה פַּרְפָּרִים! סָפַרְתְּ כׇּל אֶחָד פַּעַם אַחַת. *(Four butterflies! You counted each one once.)* `[recast to the masculine numeral, no correction]`

**Band B (MATH-B-09), child gender: masculine**
> **Tutor:** מָה צָרִיךְ לָשִׂים פֹּה, כְּדֵי שֶׁיִּהְיֶה שָׁוֶה? שָׁלוֹשׁ וְעוֹד אַרְבַּע, שָׁוֶה… מַשֶּׁהוּ וְעוֹד שְׁתַּיִם. *(What do we need to put here so it's equal? Three plus four equals… something plus two.)*
> **Child:** שֶׁבַע! *(Seven!)* `[M-EQ-OPER]`
> **Tutor:** שָׁלוֹשׁ וְעוֹד אַרְבַּע זֶה בֶּאֱמֶת שֶׁבַע. בּוֹא נָשִׂים אֶת זֶה עַל הַמֹּאזְנַיִם וְנִרְאֶה. *(Three plus four really is seven. Let's put it on the balance and see.)* `[switch to R1 balance; the scale tips]`
> **Tutor:** הַצַּד הַזֶּה כָּבֵד יוֹתֵר. מָה יַעֲזֹר לְאַזֵּן? *(This side is heavier. What will help balance it?)*
> **Child:** אָה… חָמֵשׁ? *(Ah… five?)*
> **Tutor:** נְנַסֶּה! … מְאֻזָּן! אָז "שָׁוֶה" אוֹמֵר: שְׁנֵי הַצְּדָדִים אוֹתוֹ דָּבָר. *(Let's try! … Balanced! So "equals" means: both sides are the same.)*

**Band C (MATH-C-05, explain-back), child gender: feminine**
> **Tutor:** מָצָאת עֶשְׂרִים וְחָמֵשׁ. אֵיךְ יָדַעַתְּ? *(You found twenty-five. How did you know?)*
> **Child:** הִתְחַלְתִּי מֵעֶשְׂרִים וָשֶׁבַע וְהוֹסַפְתִּי עַד חֲמִשִּׁים וּשְׁתַּיִם. *(I started from twenty-seven and added up to fifty-two.)* `[reason: count_up_number_line]`
> **Tutor:** סָפַרְתְּ קָדִימָה — כְּמוֹ קַו־זִנּוּק! כַּמָּה קְפִיצוֹת עָשִׂית? *(You counted forward — like Jump-Line! How many jumps did you make?)* `[strategy reflected; hero cue; one question]`
> **Child:** שָׁלוֹשׁ, וְאָז עֶשְׂרִים, וְאָז שְׁתַּיִם. *(Three, then twenty, then two.)*
> **Tutor:** שָׁלוֹשׁ וְעֶשְׂרִים וּשְׁתַּיִם — עֶשְׂרִים וְחָמֵשׁ. בְּדִיקָה מְצֻיֶּנֶת! *(Three and twenty and two — twenty-five. Excellent check!)*

**Off-topic, Band B, child gender: masculine**
> **Child:** יֵשׁ לִי כֶּלֶב בַּבַּיִת! *(I have a dog at home!)*
> **Tutor:** אֵיזֶה כֵּיף לְאַהֵב חַיּוֹת! בּוֹא נִרְאֶה כַּמָּה כְּלָבִים יֵשׁ בַּגִּנָּה שֶׁלָּנוּ. *(How fun to love animals! Let's see how many dogs there are in our garden.)* `[acknowledge, no follow-up about home, redirect to task]`

### 11.6 Safety and escalation scripts

- **Off-limit content.** If a child says something worrying ("מִישֶׁהוּ מַרְבִּיץ לִי", *someone is hitting me*) or anything outside learning, the tutor does not explore it. It says one caring line, "זֶה חָשׁוּב. כְּדַאי לְסַפֵּר לְמִישֶׁהוּ גָּדוֹל שֶׁאַתָּה סוֹמֵךְ עָלָיו." (*That's important. It's good to tell a grown-up you trust.*), and then gently returns to play.
- **Parent alert.** Whether to show the parent a content-free alert is a privacy and legal decision for the owner (§15). The tutor never records the child's words; per tech.md, audio stays on the device.
- **Prompt and validator rules** in the gateway (tech.md §9.4):
  - the band's word limit;
  - one question per turn;
  - no answer before H3;
  - a ban list of personal-question patterns (שֵׁם, כְּתֹבֶת, גַּן, בֵּית סֵפֶר, אִמָּא, אַבָּא + question words; *name, address, kindergarten, school, mum, dad*);
  - no first-person feelings;
  - no URLs or brand names.

  A violation falls back to the RuleTutor line.

## 12. Parents

### 12.1 What progress to show, by skill and in plain Hebrew

- **Domain view.** Each domain is a simple map of units. Under each unit, every skill appears as one plain-Hebrew sentence, written from the "can do" statement, with tech.md's four labels:
  - **מֵבִין/ה** — *understood* (`durable_mastery`);
  - **מִתְאַמֵּן/ת** — *practising* (`learning`, `fresh_mastery`);
  - **צָרִיךְ/ה חֲזָרָה** — *needs a revisit*;
  - **מָצָאנוּ פַּעַר** — *gap found*.

  Example: "סוֹפֶרֶת עַד 10 חֲפָצִים וְיוֹדַעַת שֶׁהַמִּסְפָּר הָאַחֲרוֹן אוֹמֵר כַּמָּה — מְבִינָה" (*counts up to 10 objects and knows the last number tells how many — understood*).
- **"What we noticed" cards.** Each active misconception has a `parentText` in plain Hebrew, with no jargon, plus a one-line home tip. Example (M-EQ-OPER): "חוֹשֵׁב שֶׁ־= אוֹמֵר 'עַכְשָׁו הַתְּשׁוּבָה'. בַּבַּיִת: שַׂחֲקוּ בְּ'מִי שָׁוֶה לְמִי' עִם קוּבִּיּוֹת." *Thinks "=" means "now the answer". At home: play "who equals whom" with blocks.*
- **"Learns well with…"** is drawn from `representation_stats`, for example "לוֹמֶדֶת טוֹב עִם חֲפָצִים שֶׁמְּזִיזִים" (*learns well with objects you can move*).
- **Alignment line, optional and off by default.** "בְּגַן חוֹבָה / כִּתָּה א' לוֹמְדִים…" (*in גן חובה / grade 1 they learn…*) as context, never as "behind" or "ahead". Ages are not compared and percentiles are never shown.
- **Effort and habits.** Minutes per week, days played, the number of "show me" requests (framed positively: "בִּקְּשָׁה עֶזְרָה 4 פְּעָמִים — מְצֻיָּן"), and the skills that became durable this week.
- **Weekly digest**, optional and on the device: three sentences covering what was learned, what we're revisiting, and one co-play idea.

### 12.2 Offline activities linked to skills (examples)

Each skill has 1–2 "בַּבַּיִת" (*at home*) ideas. Each takes ≤ 5 minutes and uses things found at home.

| Skill | At-home activity (Hebrew title — what to do) |
|---|---|
| NUM-A-03/04 | **"סוֹפְרִים צְעָדִים"** (*counting steps*) — count stairs or steps aloud, touching each one; ask "כַּמָּה הָיוּ?" (*how many were there?*). |
| NUM-B-13, X7 | **"מֵרוֹץ עַל הַשָּׁטִיחַ"** (*carpet race*) — a paper number track 1–10 and a die with 1–2; say each number you land on. |
| COL-B-01 | **"צֶבַע מְעֻרְבָּב"** (*mixed colour*) — mix two food colours in water and predict first. |
| SHP-A-03 | **"צַיָּדֵי צוּרוֹת"** (*shape hunters*) — find 3 triangles in the house, including "upside-down" ones. |
| SHP-B-12 | **"מַדְבֵּקָה יְרֻקָּה"** (*green sticker*) — a sticker on the right hand; play "turn right, turn left" while walking. |
| LOG-A-06 | **"דֻּגְמָה בַּשֻּׁלְחָן"** (*table pattern*) — fork, spoon, fork, spoon… "what comes next?" |
| CS-A-01, CS-C-10 | **"מַתְכּוֹן"** (*recipe*) — make a sandwich by following the child's exact instructions; laugh at the "bugs". |
| MATH-B-09 | **"מֹאזְנַיִם"** (*balance*) — a coat hanger with two cups; make it balance with coins. |
| MATH-B-17, X4 | **"מַכּוֹלֶת בַּבַּיִת"** (*home shop*) — price toys ₪1–10; the child pays with real coins and gets change. |
| MATH-C-20 | **"כַּמָּה זְמַן עַד…"** (*how long until…*) — read the kitchen clock together before a TV show or dinner. |

### 12.3 Co-play

- **Co-play mode** (מְשַׂחֲקִים יַחַד, §10.6) has "parent prompts" in small text that only adults read:
  - questions to ask, for example "שַׁאֲלוּ: אֵיךְ יָדַעְתָּ?" (*ask: how did you know?*);
  - "don't give the answer — give a hint";
  - a suggestion to point, count, or let the child explain.

  Structured parent–child maths talk is effective, especially for maths-anxious parents (Berkowitz et al. 2015).
- **"Talk about it" cards** appear after a session, for the drive home: "שַׁאֲלוּ אֶת הַיֶּלֶד/ה: אֵיךְ עוֹזְרִים לָרוֹבּוֹט לִפְנוֹת?" (*ask your child: how do we help the robot turn?*).
- **Parent tone guide.** A short page on praising process ("נִסִּיתָ דֶּרֶךְ חֲדָשָׁה" over "אַתָּה חָכָם", *you tried a new way* over *you're smart*), not rushing, and not doing the item for the child.
- **Everything parental sits behind the parental gate** (tech.md), with no external links in the child's space.

## 13. Content volume and production

### 13.1 MVP vs full launch

| | **MVP** (closed beta, Bands A–B; Band C partial) | **Full launch** (Bands A–C) |
|---|---|---|
| Skills | **≈ 95**: all of Bands A–B for NUM, COL, SHP, LOG and CS (≈ 80) + MATH-A/B core (≈ 15). Band C: NUM-C-01…06 and MATH-C-01…05 as a "preview" | **208** + 8 cross-domain units |
| Templates | 12: T01, T02, T03, T05, T07, T08, T09, T10, T13, T14, T21, T25 (tech.md says 10–12) | 25 |
| Representations | ≥ 3 per core skill (tech.md requirement); ≥ 2 per other skill | ≥ 3 per core skill; ≥ 2 per skill; 4–5 for the 30 most-failed skills (data-driven) |
| Activities (authored instances) | ≈ 95 skills × ~3 = **≈ 300** | ≈ 208 × 3.5 = **≈ 730** |
| Items | ≈ 25 per skill (practice + diagnostic + check variants) ≈ **2,400**. Many are generated by parameters (set sizes, numbers) from ~600 authored item templates | ≈ 30 per skill ≈ **6,200** (≈ 1,500 authored item templates) |
| Misconception records | ≈ 45 (Bands A–B tags in §5.2) | ≈ 70 |
| VO lines (core) | ≈ 3,000 short lines. Number, colour and noun phrases are recorded as **concatenable segments** with lexicon entries (e.g. "שְׁלוֹשָׁה" + "כְּלָבִים") to avoid a combinatorial explosion. Sentence-level lines are recorded whole. | ≈ 7,000 |
| Flavour lines per character | ≈ 40 (5 slots × ~8 variants) | ≈ 60 |
| Cross-domain units | X1, X2, X3, X7 | X1–X8 |
| Parent texts | Every skill's plain-Hebrew sentence; every misconception's `parentText` and home tip | Same, plus weekly digest templates |

**Prioritisation inside the MVP**, in this order:
1. counting and cardinality;
2. subitizing and the ten-frame;
3. comparing;
4. join and separate within 10;
5. AB patterns;
6. shapes in any orientation;
7. robot paths and debugging.

The order follows the strongest predictors of later maths (early numeracy, symbolic number, patterning) and the Ministry's גן goals. IES REL Midwest summarises the evidence: early numeracy and number sense predict later maths more strongly than other early skills.

### 13.2 Team (curriculum side)

| Role | FTE (MVP) | Notes |
|---|---|---|
| Curriculum lead (early-childhood maths/CS education) | 1 | Owns the skill graph, misconception catalogue and review gate |
| Content authors (Israeli early-childhood maths/CS educators) | 2–3 | Write activities and items in the CMS |
| Hebrew language editor (children's Hebrew, nikud) | 0.5–1 | Agreement, nikud, VO scripts, reading level |
| Pedagogy/psychology reviewer (developmental) | 0.25 | Monthly review; feedback and motivation lines |
| Kindergarten teacher and grade 1–3 teacher advisors | 2 × 0.1 | Alignment with practice; classroom realism |
| VO director plus actors | per session | Plus character voices per pack |
| Child-testing researcher | 0.5 | Runs §13.4 and §14 |

### 13.3 Production process (per unit)

1. **Spec.** The curriculum lead writes the unit spec: skills, prerequisites, watch-for tags, representations required, checks required.
2. **Author.** Authors build activities in the CMS from templates and enter items with tagged distractors and expected spoken errors.
   - Hebrew is entered with nikud, with Nakdan suggestions confirmed by a human (tech.md §4.2).
   - Every distractor carries a tag (§5.3 rules); the CMS blocks untagged distractors.
3. **Self-check in Studio Preview** on a phone, in both genders and with simulated ASR results.
4. **Expert review** against the review checklist below.
5. **Hebrew review**: nikud, agreement, VO-friendliness, and the self-gender trap (§7.1). This is the `nikud-reviewed` CMS state.
6. **Pedagogy sign-off**: the `pedagogy-reviewed` CMS state.
7. **VO recording.** Core lines are recorded per character voice, or approved for TTS. Flavour lines are recorded by the character actor. After QC the state is `VO-ready`.
8. **Child test** (§13.4) for every new template, and for 1 in 5 new activities.
9. **Publish** to beta (5%), then wider, per tech.md rollout.
10. **Item analytics after 200 children**: p-correct, distractor tag rates, hint rates, "unsure" rates. Items with p < 0.3 or > 0.97, or with an untriggered distractor, are revised.

**Review checklist (excerpt).** Each item answers yes or no.
- Is the learning goal named?
- Is there one idea per screen (§1)?
- Is it playable by tap?
- Is the instruction audio-only friendly?
- Are ≥ 2 distractors tagged?
- Is the hint ladder present, with H2 changing representation?
- Is the feedback diagnostic, never shaming?
- Do the core lines contain no self-gender or character references?
- Is the gender agreement correct?
- Is maths in LTR tokens, with no `<` or `>` outside them?
- Is it culturally inclusive?
- Is nothing moving during thinking time?

### 13.4 Child testing

- **Formative play tests.** Monthly. 8–12 children per band per round, at home or in a גַּן with consent. A researcher observes against a protocol: does the child understand what to do without help? Where do they hesitate? What do they say?
  - Pass bar for a template: ≥ 80% of children start correctly after the audio instruction alone.
- **Voice tests.** Consented recordings for the ASR evaluation set (tech.md), separate consent, with a parent present.
- **Think-aloud with Band C**, and interviews with parents.
- **Inclusion.** Include children with Hebrew as a second language, and children from Arabic- or Russian-speaking homes, in Hebrew-medium schools. Their needs will be common.


## 14. Measuring learning

### 14.1 In-app evidence (continuous)

**Primary metrics. These measure lasting understanding, not engagement.**

| Metric | Definition | Why it matters |
|---|---|---|
| **Delayed-check pass rate** | Share of revisit checks passed, per skill and per band | The best in-app sign of *lasting* understanding |
| **Fresh → durable conversion** | Share of fresh skills that reach durable mastery within 30 days (tech.md metric) | Shows whether the mastery bar is honest |
| **Transfer and reverse success** | Success on U3/U4 checks compared with familiar-format items | Separates understanding from rote |
| **Misconception resolution** | Share of active misconceptions resolved, and how many relapse within 60 days | Shows whether repair works |
| **Repair effectiveness** | After a representation switch, success on the next 2 items (the bandit reward) | Shows which explanations work |
| **Hint dependence over time** | Hint level needed per skill, falling over sessions | Shows growing independence |

**Guard metrics.**
- Frustration loops: 3 or more errors in a row.
- Quits right after an error.
- Rate of "unsure" answers, where *rising* is fine and *stuck high* is not.
- Session length against the parent's limit.
- Share of time spent in Delight. We want healthy play, not avoidance.

**Item quality** (§13.3, step 10): distractor tag rates, untriggered distractors, and p-correct out of range.

### 14.2 Pre/post checks (built in)

- **Placement baseline.** Placement (§10.1) records the starting point per domain.
- **Quarterly "mini-check".** Per domain, a short game-like set of 8–10 items in a fixed, IRT-calibrated form, at the child's band. It is presented as a "garden visit" (בִּקּוּר בַּגִּנָּה) and gives no feedback on correctness beyond warm encouragement.
- **What the change shows.** The change on this fixed form is our internal growth measure. It is shown to parents only as skill statements.
- **Not a gate.** The mini-check never gates progress.

### 14.3 Efficacy study plan (small, staged)

Kim et al.'s meta-analysis found an average effect of **+0.31 SD** for preschool–grade 3 apps. Effects were larger in preschool, larger on constrained skills, and **larger on researcher-made than on standardised tests**. So we plan to measure on independent, standardised-style tasks, and we will report modest expectations.

| Stage | Design | Sample | Measures | Decision |
|---|---|---|---|---|
| **1. Usability and feasibility** (MVP alpha) | Single-group, 4 weeks | 30 children (10 per band A, B, early C) | Observation; completion; the template pass bar; parent survey | Fix templates; tune session length |
| **2. Pilot efficacy** (beta, 8 weeks) | Randomised waitlist control. Families get the app now or after 8 weeks. Recommend ~3 × 10–12 min per week. | ~120 children aged 4–6 (60 per arm), from varied Israeli communities | **Pre/post, administered by assessors blind to arm, one-to-one, in Hebrew**: <br>• a counting and cardinality task; <br>• numeral identification; <br>• magnitude comparison and number-line estimation (0–10, 0–20), using the Ramani/Siegler-style tasks; <br>• a short pattern task; <br>• an unplugged robot-sequencing task. <br>Optionally, an Israeli kindergarten readiness screener if one is licensable. <br>Delayed post-test at +6 weeks for retention. | Effect sizes per outcome. **Primary outcome: number sense at the delayed test.** |
| **3. Larger trial** (post-launch) | A cluster RCT through גנים or schools, possibly with an academic partner (Israeli universities have early-maths and CT research groups, e.g. Haifa) | 300–600 | Standardised maths measures and a CT assessment; implementation fidelity | Evidence claim for parents and schools |

**Ethics and privacy.** Use separate research consent, with a parent present for assessments. No audio is kept beyond the consented evaluation set. The analysis plan is pre-registered, and null results are reported honestly.

## 15. Open decisions for the owner

1. **Tutor voice vs character voices.**
   - **Option a:** each character has a studio voice, and core lines are recorded per character. This is costlier, but core VO could be ~3,000 lines × N characters.
   - **Option b:** one shared "narrator/tutor" voice says the core lines, and characters add flavour.
   - **Option c:** TTS in each character's voice.
   - *Recommendation:* (b) for the MVP, with the chosen companion's flavour lines; move to (a) for 1–2 flagship characters later.
2. **Superhero squad scope.** Should heroes appear only as strategy "powers" in hints and celebrations (recommended), or also in short non-learning episodes outside sessions? If episodes are wanted, they need the same no-dark-patterns rules.
3. **Band C ambition.** Does full launch cover the whole grade 3 curriculum, including column multiplication and division with remainder, or stop at the end of grade 2 plus selected grade 3 skills (unit fractions, 10×10 facts)? *Recommendation:* end of grade 2 at launch, with grade 3 as an update.
4. **Religious and cultural contexts.** How prominent should Shabbat, holidays and Hebrew-calendar content (gematria dates) be? *Recommendation:* present but optional, with a parent setting.
5. **Gendered tutor lines** when the parent picks "prefer not to say": plural or "let's" forms only (recommended), or let the child choose later.
6. **Division sign and textbook conventions.** Confirm `:` vs ÷, the reading of `=` (שָׁוֶה vs "זֶה"), and the times word (כָּפוּל vs פִּי), against the approved textbooks most Israeli schools use. This needs a quick review by a grade 1–3 teacher.
7. **Pattern and story direction.** Should pattern rows and story strips run right to left (proposed, §8.6)? Confirm in child tests before content production.
8. **Safety escalation.** If a child says something worrying to the tutor, should the parent see a content-free alert? This is legal and privacy sensitive.
9. **Optional Band C "beat your record" games.** Include them for durable facts only (recommended), or not at all?
10. **School/גן edition.** Is a teacher view with class-level misconception reports in scope later? It affects data design now.
11. **Arabic and Russian support** for parent-area text, given Israel's demographics. The child's space stays Hebrew.
12. **Efficacy study budget and academic partner** (§14.3, stages 2–3).

## 16. Sources

Pages I opened and relied on:

**Israeli Ministry of Education**
- [Kindergarten mathematics curriculum (TochnitKdamYesodiHeb.pdf)](https://meyda.education.gov.il/files/Mazkirut_Pedagogit/Matematika/TochnitKdamYesodiHeb.pdf)
- [Kindergarten curriculum page (curriculum-kindergarten)](https://pop.education.gov.il/kindergarten/magar-ganey-yeladim/curriculum-kindergarten)
- [Kindergarten maths draft (Math1.pdf)](https://meyda.education.gov.il/files/Tochniyot_Limudim/KdamYesodi/Math1.pdf)
- [Kindergarten maths: spatial sense excerpt (Math3.pdf)](https://meyda.education.gov.il/files/Tochniyot_Limudim/KdamYesodi/Math3.pdf)
- [Cultivating arithmetic thinking in early childhood](https://pop.education.gov.il/kindergarten/magar-ganey-yeladim/cultivating-arithmetic-thinking-early-childhood/)
- [Elementary maths curriculum page (new curriculum, milestones)](https://pop.education.gov.il/tchumey_daat/matmatika/yesodi/oraat-math/tohnit-limudim/)
- [Annotated curriculum introduction (MevoeretMavo.pdf)](http://meyda.education.gov.il/files/Tochniyot_Limudim/Math/Yesodi/Mevoeret/MevoeretMavo.pdf)
- [Grade 1 milestones: natural numbers](https://meyda.education.gov.il/files/Tochniyot_Limudim/Math/Yesodi/Mevoeret/A.MisparimTivyim.pdf)
- [Grade 1 milestones: operations](https://meyda.education.gov.il/files/Tochniyot_Limudim/Math/Yesodi/Mevoeret/A.Peulot.pdf)
- [Grade 1 milestones: measurement](https://meyda.education.gov.il/files/Tochniyot_Limudim/Math/Yesodi/Mevoeret/A.Medidot.pdf)
- [Grade 1 milestones: geometry](https://meyda.education.gov.il/files/Tochniyot_Limudim/Math/Yesodi/Mevoeret/A.Geometriya.pdf)
- [Grade 2 milestones: natural numbers](https://meyda.education.gov.il/files/Tochniyot_Limudim/Math/Yesodi/Mevoeret/B.MisparimTivyim.pdf)
- [Grade 2 milestones: operations](https://meyda.education.gov.il/files/Tochniyot_Limudim/Math/Yesodi/Mevoeret/B.Peulot.pdf)
- [Grade 2 milestones: measurement](https://meyda.education.gov.il/files/Tochniyot_Limudim/Math/Yesodi/Mevoeret/B.Medidot.pdf)
- [Grade 2 milestones: data](https://meyda.education.gov.il/files/Tochniyot_Limudim/Math/Yesodi/Mevoeret/B.Netunim.pdf)
- [Grade 3 milestones: operations](https://meyda.education.gov.il/files/Tochniyot_Limudim/Math/Yesodi/Mevoeret/C.Peulot.pdf)
- [Grade 3 milestones: fractions](https://meyda.education.gov.il/files/Tochniyot_Limudim/Math/Yesodi/Mevoeret/C.Shvarim.pdf)
- [Grade 3 milestones: measurement](https://meyda.education.gov.il/files/Tochniyot_Limudim/Math/Yesodi/Mevoeret/C.Medidot.pdf)
- [2006 grade 1–6 curriculum introduction (mavo1.pdf)](https://meyda.education.gov.il/files/mazkirut_pedagogit/matematika/tochnyotlemud/mavo1.pdf)
- [Grade 2 curriculum, 2006 (kita2.pdf)](https://meyda.education.gov.il/files/Tochniyot_Limudim/Math/Yesodi/kita2.pdf)
- [Supervisor's guidance, תשפ"ז (mafmar_yesodi_tashpaz.pdf)](https://meyda.education.gov.il/files/Mazkirut_Pedagogit/math/primary-school/math2025/mafmar_yesodi_tashpaz.pdf)
- [Supervisor's guidance, תשפ"ו (mafmar_yesodi2025.pdf)](https://meyda.education.gov.il/files/Mazkirut_Pedagogit/math/primary-school/math2025/mafmar_yesodi2025.pdf)
- [Grade 1 home-learning booklet (bookletmatha1.pdf)](https://meyda.education.gov.il/files/Mazkirut_Pedagogit/math/primary-school/math2023/bookletmatha1.pdf)
- [Kindergarten computational thinking & robotics materials](https://pop.education.gov.il/kindergarten/topics/computational-thinking/teaching-materials/high-tech/)
- ["High-Tech in Kindergartens" CT booklet (ogdan_ganim.pdf)](https://meyda.education.gov.il/files/PreSchool/hitech/ogdan_ganim.pdf)
- [Grade 1 computational thinking](https://pop.education.gov.il/tchumey_daat/madaei-mahshev-robotika/yesodi/noseem_nilmadim/thoughtful-thinking-first-grade/)
- [Grade 2 CT study topics](https://meyda.education.gov.il/files/Pop/0files/madaei-mahshev-robotika/Yesodi/pedagogy/second-grade-study-topics.pdf)
- [Hebrew numerals guidance (shem-mispar.pdf)](https://meyda.education.gov.il/files/Pop/0files/ivrit_habaah_lashon/pedagogia/shem-mispar.pdf)

**Learning trajectories, standards and international benchmarks**
- [TIMSS 2015 Encyclopedia: Israel mathematics curriculum](https://timssandpirls.bc.edu/timss2015/encyclopedia/countries/israel/the-mathematics-curriculum-in-primary-and-lower-secondary-grades/)
- [Learning trajectories (Clements & Sarama), OTF summary](https://www.otffeo.on.ca/en/wp-content/uploads/sites/2/2017/05/Learning_trajectories_math.pdf)
- [IES/REL subitizing developmental progression](https://ies.ed.gov/ncee/rel/math-young-children/pdf/TMYC_Mod1_Subitizing_Developmental_Progression.pdf)
- [Building Blocks evaluation (Clements & Sarama 2008)](https://www.mheducation.com/prek-12/resources/research/library/math/effects-of-a-research-based-preschool-math-curriculum.html)
- [IES practice guide: Teaching Math to Young Children](https://ies.ed.gov/ncee/wwc/practiceguide/18)
- [NCTM Curriculum Focal Points](https://www.sresd.org/downloads/instructional/math/focal_points.pdf)
- [Common Core kindergarten standards](https://mathsisfun.com/links/core-kindergarten.html)
- [CSTA K–2 standards (Washington OSPI)](https://ospi.k12.wa.us/sites/default/files/2022-12/cs-standards-k-2.pdf)
- [CSTA revised PreK–12 standards, Draft 2.0](https://csteachers.org/Draft-2.0-Revised-PreK-12-CS-Standards)
- [CSTA: AI and Beyond, 2026 standards updates](https://csteachers.org/resources-library/ai-and-beyond-updates-to-the-2026-csta-standards/)
- [Code.org CS Fundamentals Course A](https://curriculum.code.org/csf-18/coursea/)
- [Code.org CS Fundamentals overview](https://curriculum.code.org/csf-18/)
- [ScratchJr / Coding as Another Language seminar (Raspberry Pi Foundation)](https://www.raspberrypi.org/app/uploads/2023/08/Seminar_July2023.pdf)

**Learning science and app evidence**
- [Hirsh-Pasek et al.: Putting Education in "Educational" Apps](https://www.psychologicalscience.org/publications/educational-apps.html)
- [Kim et al. 2021 meta-analysis of educational apps](https://reacheveryreader.gse.harvard.edu/?p=2498)
- [Takacs, Swart & Bus: multimedia and interactive storybooks meta-analysis](https://docs.opendeved.net/lib/9LS8BP3N)
- [Nikolayev et al.: feedback in preschool edutainment games](https://reacheveryreader.gse.harvard.edu/?p=1615)
- [Adaptive vs corrective feedback in a fraction game](https://imec-publications.be/entities/publication/049ae1f8-4018-4258-b406-19fbde07c8b5/full)
- [Expanding retrieval practice for preschoolers (Learning Scientists)](https://www.learningscientists.org/blog/2022/2/3-1)
- [Gunderson et al. 2018: parent praise and later achievement](https://ecrhub.org/publications/parent-praise-toddlers-predicts-fourth-grade-academic-achievement-childrens)
- [Ramani, Siegler & Hitti 2012: linear number board games](https://education.umd.edu/sites/default/files/uploads/Ramani%20et%20al.%2C%202012%20%281%29.pdf)
- [IES REL Midwest: early maths skills that predict later proficiency](https://ies.ed.gov/ncee/edlabs/regions/midwest/askarel/2021/math-skills-predicting-future-math-proficiency.aspx)
- [CRA meta-analysis (Ebner et al. 2025)](https://scholars.uky.edu/en/publications/a-meta-analytic-review-of-the-concrete-representational-abstract-/)
- [Berkowitz et al. 2015, Bedtime Math (UChicago News)](https://news.uchicago.edu/article/2015/10/08/math-story-time-home-bolsters-achievement-school)
- [Xu: AI's role in children's learning (Joan Ganz Cooney Center)](https://joanganzcooneycenter.org/2024/10/07/different-but-complementary/)
- [Pitchford & Mullen 2006: colour term acquisition](https://www.mvr.mcgill.ca/Kathy/PDF-05-09/Pitchford-Mullen-2006.pdf)
- [Preschoolers and touchscreen gestures (Kidscreen)](https://kidscreen.com/?p=73678)
- [Screen-time guidance for preschoolers (KidsHealth / AAP)](https://kidshealth.org/RadyChildrens/en/parents/screentime-preschool.html)

**Hebrew language, reading, RTL and speech**
- [Berman & Lustigman: developmental language profile for Hebrew](https://www.tau.ac.il/~rberman/papers/2012_Berman%20&%20Lustigman_HARSP%20-%20A%20developmental%20language%20profile%20for%20Hebrew%20(chapter).pdf)
- [Gender neutralization of Hebrew numerals in colloquial speech](https://cris.iucc.ac.il/en/publications/gender-neutralization-in-hebrew-the-case-of-the-numerals-in-collo/)
- [Share & Bar-On: triplex model of Hebrew reading development](https://cris.haifa.ac.il/en/publications/learning-to-read-a-semitic-abjad-the-triplex-model-of-hebrew-read/)
- [Reading direction and numerical processing (Haifa)](https://cris.haifa.ac.il/en/publications/the-effect-of-reading-direction-habit-on-numerical-processing/)
- [X-axis direction in RTL languages (Gorelik)](https://gorelik.net/2019/05/19/x-axis-direction-in-right-to-left-languages-part-two)
- [Unicode bidi mirroring of maths operators (L2/18-026)](https://www.unicode.org/L2/L2018/18026-bidi-math-prop.html)
- [Apple Human Interface Guidelines: right to left](https://developer-rno.apple.com/design/human-interface-guidelines/foundations/right-to-left)
- [Left–right confusion](https://en.wikipedia.org/wiki/Left%E2%80%93right_confusion)
- [Fahoum & Levy: robots and spatial abilities in kindergarten (Chais 2023)](https://www.openu.ac.il/Lists/MediaServer_Documents/innovation/chais/2023/a3_1.pdf)
- [Learning Agency: closing the child speech recognition gap](https://the-learning-agency.com/guides-resources/closing-the-child-speech-recognition-gap-evidence-limitations-and-paths-forward/)
- [Israeli new shekel: coins and notes in circulation](https://en.wikipedia.org/wiki/Israeli_new_shekel)
- [FTC final COPPA amendments, audio exception (Hunton)](https://www.hunton.com/privacy-and-cybersecurity-law-blog/ftc-publishes-final-coppa-rule-amendments)

**Internal**
- `/home/claude/kids-app/tech.md`, the Technical Architecture plan, sections 4–7 and 9 (for interfaces and data fields).

