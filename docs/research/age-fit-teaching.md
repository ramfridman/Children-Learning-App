# Teaching by actual age (B-29): research and recommendation

Author: curriculum-expert (Knowledge Agent), 2026-10-29. Status: research for the owner's decision. Nothing here is built.
Companion report: `docs/research/age-fit-design.md` (design-director, presentation by age).

## 0. The answer in one page

1. **Age is a good first guess and a poor judge.** Within one age the spread of number knowledge is wider than the gain from one birthday to the next. In the Israeli data, the advantage of being older at school entry is real (Attar and Cohen-Zada 2017), and in the US data it is carried by what the child already knows about number (Jordan et al. 2009). So age should set where a child **starts** and how a screen is **presented**. What the child **knows** (mastery per land) should decide everything after the first few minutes.
2. **Split two things the app now mixes in one "band":**
   - **Presentation stage, by age in months, per child.** It sets target size, number of choices, captions, session length, voice-answer length, how the hint ladder opens and how grown-up the look is.
   - **Content level, by mastery, per land.** It sets which skill comes next, item difficulty, repair, revisits and moving on.
   A bright 4-year-old gets Band B numbers with big targets and audio. A struggling 7-year-old gets Band A content in a grown-up look, never a baby look.
3. **Store the month and year of birth, never the day, only on the device.** The age in months is computed on the device when it is needed. The server and sync keep carrying only coarse enums: the band (as today), plus, if the owner agrees, a school stage (gan 3 to grade 3) that the parent confirms. This needs the owner to change PLAN.md line 1036 and needs the security-engineer's design.
4. **Use half-year rows, not months and not whole years.** Evidence on milestones is too coarse for monthly steps. Whole years make a jump at every birthday, and in Israel two children in the same class can be almost 12 months apart.
5. **Never move a child backwards and never move on at a birthday.** Changes apply at the start of the next session. The content path moves only by mastery. The school stage moves on 1 September, and the parent sees it first.
6. **Fix the path first (B-15), then age-fit, then content for the extremes.** An age-based starting lesson is worthless while `nextLessonId` walks every lesson in `sequence` order and placement trusts one lucky answer (`docs/knowledge/m9-audit.md` F6, F7).

## 1. How age is used today (read in the code, worktree `D:\nitznutz-b26`)

| Where | What it does |
|---|---|
| `app/lib/parent/child_form.dart:28,109-114` | The parent picks a whole age 3 to 8 (default 5) once. Only the band is saved (`ageBand: bandForAge(_age).index`). The age itself is thrown away and never moves on. |
| `app/lib/design/components.dart:581` | `bandForAge`: 3 and 4 give A, 5 and 6 give B, 7 and 8 give C. |
| `app/lib/design/tokens.g.dart:180-182` | The band sets touch sizes and `maxChoices` (3, 4 or 5), type sizes and pebble size. |
| `app/lib/play/lesson_screen.dart:133,159,276`, `parent/parent_rules.dart:82` | The band sets the Band A treatment, the time limit and the band sent to the tutor. |
| `supabase/functions/child-put`, `tutor-turn`, `_shared/tutor_prompt.ts` | The server stores `age_band` 0 to 2. The tutor uses the band for word limits and choice of phrasing. |
| `app/lib/world/next_lesson.dart` | The path ignores both band and mastery: it takes the first unfinished lesson by `sequence`. |
| `app/lib/world/placement.dart` | The warm-up spreads up to 8 items along the whole path. One right first try with no hint marks the lesson as known. |

So today one whole number chosen once sets the presentation for the child's whole life in the app. It is not used for content, and it is never updated.

**Coverage of the pack (`content/starter`, counted 2026-10-29):** 767 activities, 160 lessons, 100 skills, 44 misconceptions.

| Band | Skills in the pack / planned in curriculum §4 | Activities |
|---|---|---|
| A | 51 / 56 | 347 (Numbers 100, Logic 60, Math 60, Shapes 59, Colours 44, CS 24) |
| B | 49 / 79 | 420 (Numbers 159, Math 130, Shapes 42, Logic 39, Colours 36, CS 14) |
| C | 0 / 73 | 0 |

## 2. Development in months, ages 3 to 8

The table is a working picture. Rows marked [C] are carried from `docs/curriculum.md` §2, which cites its sources. Rows marked [R] were checked for this report (sources in §8). Every age is a typical age with a wide spread. The CDC and AAP 2022 milestone checklists moved each milestone from the age when half of children reach it to the age when **75%** do, because a 50% age flags half of all normal children (Zubler et al. 2022, read through secondary coverage).

| Area | About 3;0 to 3;11 | About 4;0 to 4;11 | About 5;0 to 5;11 | About 6;0 to 6;11 | About 7;0 to 8;11 |
|---|---|---|---|---|---|
| Counting and cardinality | Learns "one", "two", "three" one word at a time. Many are 1-, 2- or 3-knowers. Recites further than it counts. [R] | Becomes a cardinal-principle knower, often late in the year and sometimes after 5. Counts 5 to 10 objects. [R][C] | Counts objects to 20, recites to 30, counts back from 10, subitises small groups conceptually. [C] | Grade 1 work: to 100, tens, facts to 20. [C] | Place value to 100 then 1,000, skip counting, equal groups. [C] |
| Language and literacy | Simple clauses. Basic colour words from about 3; brown and grey later. [C] | Phonological sensitivity at the syllable level first. [R] | Gan goal: the alphabetic principle, letter names, shapes and sounds; **not** decoding words (Ministry gan literacy programme). [R] | Grade 1: sound-by-sound decoding of pointed text (Share and Bar-On, phase 1). [R] | Grade 2: whole-word (lexical) reading. Unpointed text is a later step. [R] |
| Working memory | About 2 to 2.5 items for preschoolers and early-school children. [R] | Same order. Grows steadily with age. [R] | Same order. | About 2.5 chunks in first grade (adults 3.5). [R] | Still growing linearly through the school years. [R] |
| Attention | "2 to 5 minutes per year of age" is a popular rule. **I found no study behind it**; treat it as folk advice. Use the curriculum's per-activity times and watch the child. [R] | | | | |
| Fine motor | Tap; short drags with big snapping targets. [C] | | Tap, drag and simple tracing. [C] | | Precise drags, paths on a grid. [C] |
| Logic and space | AB patterns; sort by one attribute. [C] | | Sort by two attributes; "if-then" in a game; 3 to 6 robot steps. [C] | Left and right words come at about 6 to 7. [C] | Loops and simple conditions; another person's left and right is still shaky. [C] |
| Instructions | One step, spoken, one at a time. [C] | | Understands most instruction verbs; does not read them alone. [C] | | Follows two steps; reads short pointed instructions. [C] |

**What changes inside one year (the owner's question).** Within a year, three things move enough to matter:
- **Number words:** Wynn's stages of about 4 to 6 months per known number word, from 2;9 to about 4;6. A denser replication found the process slower and more gradual than Wynn proposed (Rousselle and Vossius 2021).
- **Letters and sounds** in the gan-hova year.
- **Decoding** inside grade 1, which the school teaches month by month.

Motor control, working memory and attention grow steadily, with no sharp step at a birthday.

**Evidence that age predicts readiness only roughly:**
- Kindergarten number competence strongly predicted maths growth and level up to grade 3. The advantage of children who started older was **accounted for** by their number knowledge at entry (Jordan et al. 2009, abstract). The skill, not the age, is what carries forward.
- In England, August-born children do worse mostly because they are 11 months younger **when tested**. They are also more often labelled as having special needs: 12.5% against 7.1% at age 11 (Crawford, Dearden and Greaves 2013). Age in months matters, and judging a child against older classmates mislabels the youngest.
- In Israel, starting school a year older raised grade 5 Hebrew by 0.34 SD and maths by 0.19 SD (Attar and Cohen-Zada 2017).
- Learning-trajectory levels are described as levels, not stages. The ages attached to them are typical and depend on teaching. I could not open the primary text that says so; a reproduction of the Building Blocks table calls them "rough guides" and "lower bounds".

**Where mastery overrides age:** always for what to learn next and how hard the next item is. Age keeps only:
- the starting guess for a land the child has not played;
- presentation limits that are about the body and reading (target size, captions), because a 4-year-old who knows teen numbers still cannot read the instruction;
- safety and wellbeing defaults (session length).

## 3. Israel: stages, cut-off and expectations

**The school year and the cut-off.** The compulsory education law counts a child as having reached an age at the start of a school year if they reach it before 1 January of that school year. Compulsory schooling starts at 3. I read this on the Tel Aviv municipality page; the Ministry's exemption guidance quoting section 3 I saw only as a search snippet. So a class is one **calendar birth year**, January to December. Older research used a Hebrew-calendar date in Tevet (Attar and Cohen-Zada). Current municipal notices state the range in Gregorian dates with Tevet equivalents. I could not open the Ministry's own registration circular, so the exact current rule is **not verified at the Ministry source**.

| School year 2026-27 (תשפ"ז) | Born (calendar year) | Age on 1 September 2026 |
|---|---|---|
| גן טרום-טרום חובה (age 3) | 2023 | 2;8 (born 31 Dec) to 3;8 (born 1 Jan) |
| גן טרום חובה (age 4) | 2022 | 3;8 to 4;8 |
| גן חובה (age 5) | 2021 | 4;8 to 5;8 |
| כיתה א׳ | 2020 (confirmed by a municipal notice, seen as a snippet) | 5;8 to 6;8 |
| כיתה ב׳ | 2019 | 6;8 to 7;8 |
| כיתה ג׳ | 2018 | 7;8 to 8;8 |

**Consequences for the app:**
1. **The same class spans almost 12 months.** A December child is the youngest in every class for eight years. A whole-year age (today's chips) says "3" for a child who is 2;8 in the age-3 gan in September.
2. **Grade cannot always be computed from the birth date.** Autumn-born children (September to December) may stay a second year in gan hova. Tel Aviv allows deferral only for them, except rare cases decided by a committee. About 10% of a cohort stays (ynet, about 2021). So the parent must be able to **confirm the stage**, not only the birth date.
3. **The school year turns on 1 September.** What the child meets in gan or class changes then, not at the birthday.

**What the Ministry expects at each stage** (summary; detail in `docs/curriculum.md` §3.1 and §3.2):
- **Gan (3 to 6).** Maths goals are written for the **end of gan hova**, with extensions for children who are ready. They are not split by gan year:
  - number concept, spatial sense and geometry, and everyday quantities;
  - counting to 30, counting objects to 20, numerals 0 to 10, adding and taking away within 10 with objects;
  - shapes and solids, patterns, money and time in daily life.
  The kindergarten programme page also lists computational thinking and financial education. Literacy in gan: phonological awareness (syllables first), letter names, shapes and sounds, emergent writing and book orientation, explicitly **not** decoding. Colours are kindergarten vocabulary, not a maths goal.
- **Grade 1.** Numbers to 100, facts to 20, whole hours, polygons. Reading: decoding pointed text, mapped by an early-literacy profile at the start of the year. I could not open the binding policy letter for the month-by-month targets.
- **Grades 2 and 3.** Numbers to 1,000 and then 10,000, multiplication to 10 × 10, half and quarter hours, then minutes, unit fractions in grade 3. Reading moves to whole words, and texts lose nikud from about grade 3 (Share and Bar-On; curricular descriptions).

**Mapping our bands to Israeli stages:**
- Band A = the two younger gan years.
- Band B = gan hova and grade 1.
- Band C = grades 2 and 3.

The school stage is a better anchor than age in years, because it is what the child meets every morning.

## 4. How adaptive systems handle the starting point and progress

**Three ways to set the start:**
- **By age or grade alone:** quick, but wrong for many children (§2).
- **A placement test:** better, but for young children it must be short, playful and robust to guessing.
- **Pure mastery from zero:** safe, but it bores capable children.

What the evidence supports is a combination:
1. **Use age as a prior, then adapt.** In Math Garden, ability and item difficulty update after every answer (Elo-based; Klinkenberg, Straatemeier and van der Maas 2011, about 3.5 million problems from 3,648 children). The "cold start" problem for a new learner is solved in the literature by estimating starting ability from **learner features such as age** (Park et al., cited in Park, Cornillie, van der Maas and Van Den Noortgate 2019). This is what curriculum §10.1 already says: "start at the band suggested by the age, staircase placement, minus one unit".
2. **Aim for high success.** In a 6-week experiment (grades 3 to 6), the higher the set success rate, the more problems children chose to do and the more their maths improved. Anxiety fell equally in all conditions (Jansen et al. 2013). For ages 3 to 8, aim item choice at about 75 to 85% expected success, and end sessions on success (§10.3).
3. **Let the parent move the level by one step.** Khan Academy Kids lets the parent raise or lower the level from the parent area. Its own help page refused my request (403), so I saw this only in secondary descriptions; **not verified** at the source.

**How many levels make sense:**
- **Content:** skills on a continuous path per land. Bands A, B and C are only authoring groups.
- **Presentation:** **half-year rows** of a table computed from age in months. Evidence does not support finer steps: milestones are reported per year or half-year at the 75th percentile; working-memory estimates differ by about half an item between preschool and grade 1; number-word stages are 4 to 6 months apart. Whole years are too coarse inside a 12-month class.
- **School stage:** six values (gan 3, gan 4, gan hova, grades 1, 2 and 3), moved on 1 September.

**Moving on as the birthday passes, without breaking progress:**
- Mastery, finished lessons, stickers and the representation profile **never** depend on age, so a new age cannot erase them.
- A new half-year row applies **at the start of the next session**, never inside a lesson.
- Age only **opens** things (larger choices, captions, older look). It never takes away a skill the child has shown. The parent can hold a younger look or a "does not read yet" setting.
- The starting point for a land is used **once**, at the first visit. After that, age has no say in that land's path.
- The school stage moves on 1 September after a one-line parent notice with an override.

**Risks of age-labelling and how to avoid them:**
- **Stigma.** Age-adjustment exists because the youngest in a class get misjudged and labelled (the IFS finding on special-needs labels). Teachers in English early-years classes report that grouping by ability hurts some children's self-esteem: 45% in Bradbury and Roberts-Holmes 2017, as summarised by the TES; I read only the summary.
  - Never show the child a band letter, an age or a level number.
  - Never show the parent "behind" or "ahead of age". Show skills learned and next steps. If a norm is ever shown, it must be age-adjusted to the month (IFS recommendation).
- **A bright 4-year-old stuck in Band A.** No age ceiling on content: placement and the "challenge" offer (§10.4) can take a 4-year-old into Band B numbers. Presentation stays at age 4: audio, big targets, no reading.
- **A struggling 7-year-old shown babyish content.** The same Band A skill is shown with the 7-year-old's presentation: grown-up look, no baby voice, no "small" framing. The tutor says "practice" or "warm-up", never "easy". The design-director's report must define the look; the content needs some second skins (§6).
- **The wrong-profile guard (§10.6)** must use the presentation stage, not the band, or a strong younger sibling will set it off.

## 5. Recommendation for this app

### 5.1 What age drives and what mastery drives

| Decision | Driven by | Rule (starting values, to tune with the children) |
|---|---|---|
| Starting lesson of a land not yet played | **Age (school stage)** as a prior, then the warm-up | Age-suggested start minus one unit (§10.1). The warm-up runs a staircase around it, needs 2 of 3 right, and treats skipped lessons as "assumed" with verification. Needs B-15 F7 fixed first. |
| Next skill, moving on, repair, revisits | **Mastery** | Curriculum §10.2 to §10.4. Age plays no part. |
| Item difficulty within a skill | **Mastery** (Elo/BKT), age only as the first item's prior | Aim at about 75 to 85% expected success. |
| Maximum number of answer choices | **Age**, capped down by the item | Under 3;6: 2, at most 3. 3;6 to 4;11: 3. 5;0 to 6;5: 3 to 4. 6;6 and up: 4 to 5. Two-choice items keep counting at most 50% of the evidence. |
| Items per activity, session length | **Age**, the parent can set lower | Under 3;6: 3 items, 6 to 8 min. 3;6 to 4;11: 3 to 5 items, 8 min. 5;0 to 6;5: 5 to 8 items, 12 min. 6;6 and up: 8 to 12 items, 15 min (maximum 20). |
| Hint ladder | **Age** sets the opening, **mastery** sets the level | Under 5: the first hint is already visual (point and pulse), and "show me" comes after the 2nd try. 5 and up: the first hint is a question. Level 2 always changes the representation. |
| Captions and reading | **Age** default, the **parent's reading setting** wins | Under 5;0: no captions for the child. 5;0 to 6;5: short pointed captions after the voice. 6;6 and up, or "reads short words": pointed instructions. |
| Instruction words (left and right, comparatives, formal terms) | **Age** for the words used in instructions; **mastery** for teaching them | "Right" and "left" in instructions only from about 6;0. Before that, landmarks. |
| Voice answers | **Age** for length, the activity's `voiceAnswer` flag for whether | Under 5: one word. 5 to 6: one or two words. 7 and up: short sentences. Unclear speech is never wrong. |
| Revisit share and interleaving | **Age** | About 15% at 3, rising to 30% by 7 and up. Blocked by land under 5, interleaved from 5. |
| Look, tone, characters' register | **Age** (presentation stage), never the content level | Defined by the design-director. |
| Tutor word limits | **Presentation stage** enum | Replaces `band` in `tutor-turn`. |
| Parent time limit default | **Age** | As today by band, computed from the stage. |

### 5.2 What to store, and the privacy trade-off

PLAN.md line 1036 says a profile holds "an age range, no date of birth". CLAUDE.md limits personal data. My proposal, for the security-engineer to test and the owner to decide:

| Data | Where | Why |
|---|---|---|
| Month and year of birth (no day), optional | **Device only**, in the encrypted database; never synced, logged or sent | Enough for age in months within ±1 month. The day adds nothing for teaching. |
| Age in months, presentation stage | **Computed on the device** when needed; never stored or sent | |
| School stage (gan 3 to grade 3) | Device. Sync **only if the owner agrees**, as an enum plus the school year it was set for | Lets a second device agree without the birth date. It says no more than "age range". |
| Band (A, B, C) | Synced as today | The server's tutor limits and time defaults need it, or need the stage enum instead. |
| Reading setting, look override | Device; may sync as enums | |

**What the server really needs:** a coarse enum for the tutor (band or stage) and the parent's time-limit defaults. Nothing about months or dates.

**Cost of device-only:** a family with a phone and a tablet types the month and year on each device, or the second device uses the synced school stage only. I recommend accepting that cost.

**PLAN.md would change** from "age range" to "age range; month and year of birth kept only on the device".

### 5.3 Migration of existing profiles (band only)

1. **No change on update.** A profile without a birth month keeps its band. Its presentation stage defaults to the middle of the band (A: 4;0, B: 6;0, C: 7;6). Its path and progress are untouched.
2. **One calm parent card** (adult area, behind the gate): "Add the month and year of birth so the lessons fit the age (optional)", plus the school stage pre-filled from the year, editable. The text is for the hebrew-text-editor.
3. **When the parent adds it:**
   - the presentation stage is recomputed at the next session;
   - the stored band becomes derived from the stage, for the server;
   - mastery, finished lessons and placement results are kept;
   - lands not yet visited use the age-based start; lands already played keep their path.
4. **If the new band is lower than the old one** (the parent had picked an older age): presentation is not made younger without the parent's OK. Content is not moved either way.
5. The age chips in `child_form.dart` are replaced by month and year plus stage for new profiles.

## 6. Content missing at the extremes, and the order to build it

**The young end (2;8 to 3;5, possible in the age-3 gan).** Band A starts with counting to 5 and 3-choice items. A child who knows only "one" and "two" (a 2-knower) needs:
- a **ramp of 1, 2 and 3 only**: "give me two", spotting one or two at a glance, same or not same, big and small, sorting into 2 bins;
- 2-choice items;
- audio only, one tap.

This is a small set: about 5 to 8 lessons made from existing templates, mostly data in the band tables. It matters only if one of the children is under about 3;6. **The ages are not in any file; the owner must tell us.**

**The old end (Band C, 7;0 to 8;11).** Nothing exists: 0 of 73 planned skills. A 7-year-old today finishes the Band B path and goes round it again (`next_lesson.dart`), which is the "babyish" risk in its plainest form.

**Order (each step needs its own plan and the owner's OK):**
1. **B-15 first.** The path must follow prerequisites and mastery, and the warm-up must not trust one lucky answer. Build the missing core Band B skills too: NUM-B-06 numerals 0 to 10 and NUM-B-09 ten-frames (m9-audit F6). Age-fit is built on this.
2. **Presentation stage and the age-based start (B-29 itself).** Mostly app work and data. It gives older children the right look on existing content at once.
3. **The rest of Band B** (30 planned skills missing). It covers gan hova and grade 1, the widest age window.
4. **Band C, grade 2 core first:**
   - NUM-C place value to 100 and 1,000;
   - MATH-C addition and subtraction within 100 with and without regrouping;
   - clock to half and quarter hours; money with change;
   - CS-C loops; equal groups.
   Grade 3 (multiplication to 10 × 10, unit fractions, time to minutes) comes after.
5. **The young ramp**, only if a child is under about 3;6. If so, it moves to step 2.

If one child is 7 or 8 now, step 4 moves before step 3. The real ages decide.

## 7. Open questions for the owner (each with my recommendation)

1. **May the app keep the month and year of birth on the device?** Recommendation: yes, month and year only, device only, optional; PLAN.md line 1036 changes to say so.
2. **May the school stage (an enum) sync to the server?** Recommendation: yes. It is no more than an age range and it lets two devices agree. If not, the second device asks for the month and year again.
3. **Should the parent confirm the stage (gan or grade), not only the birth date?** Recommendation: yes. Autumn-born children may stay a second year in gan hova (about 10%).
4. **Separate presentation (by age) from content (by mastery)?** Recommendation: yes. It is the core of this plan and the guard against both "stuck" and "babyish".
5. **Should age ever cap content?** Recommendation: no cap. Only prerequisites, mastery and the reading and motor demands of an activity limit it.
6. **Should the parent see comparisons with age norms?** Recommendation: no. Show skills and next steps. If a norm is ever shown, age-adjust it to the month.
7. **The children's month and year of birth (or at least their stage).** Needed to order §6 and to plan B-29. Give them to the orchestrator in the session, not in a committed file.
8. **A parent reading setting ("does not read yet", "reads short words", "reads short sentences")?** Recommendation: yes. It overrides the age default for captions and instructions.

## 8. Sources

Read means I opened the page or the abstract on 2026-10-29. Snippet means I saw only the search engine's extract.

**Israel**
- Tel Aviv-Yafo municipality, "רישום לגני ילדים" (2026-27): the compulsory law from age 3 by the end of December; the age-3 cohort of 2023. https://www.tel-aviv.gov.il/Residents/Education/Pages/KRegistration.aspx (read)
- Tel Aviv-Yafo municipality, kindergarten page on staying another year: deferral only for September to December births; exceptions by a committee. https://www.tel-aviv.gov.il/Residents/Education/Pages/SpecialResidentsKindergarten.aspx (read)
- ynet, "הדילמה של ההורים לילדים שעולים לכיתה א'" (about 2021): about 10% of a cohort stays another year in gan hova. https://www.ynet.co.il/news/article/BkIQ2xwWO (read; the date is inferred from the image paths)
- Efrat local council, first-grade registration notice 2026-27: born 1.1.2020 to 31.12.2020. https://www.efrat.muni.il/uploads/n/1768209093.1550.pdf (snippet; the PDF could not be read)
- Ministry of Education, exemption guidance 2025-26, quoting section 3 of the law ("before 1 January"). (snippet only)
- Ministry of Education, kindergarten curriculum page (domains; maths programme replacing the 1995 framework; computational thinking and financial education listed). https://pop.education.gov.il/kindergarten/magar-ganey-yeladim/curriculum-kindergarten (read)
- Ministry of Education, gan language and literacy documents (phonological awareness, letter knowledge, not decoding). meyda.education.gov.il PreSchool files (snippets only)
- Ministry of Education, Hebrew grade 1 page (policy letter, early-literacy profile). https://pop.education.gov.il/tchumey_daat/ivrit_chinhch_leshony/yesodi/pedagogy-hebrew-linguistic-education/teaching-hebrew-grade1 (read; the linked PDFs not opened)
- Attar, I. and Cohen-Zada, D. (2017). The Effect of School Entrance Age on Educational Outcomes: Evidence Using Multiple Cutoff Dates and Exact Date of Birth. IZA DP 10568; Journal of Economic Behavior and Organization 153 (2018). https://ideas.repec.org/p/iza/izadps/dp10568.html (abstract read)
- Share, D. L. and Bar-On, A. (2018). Learning to Read a Semitic Abjad: The Triplex Model of Hebrew Reading Development. Journal of Learning Disabilities 51(5). https://pubmed.ncbi.nlm.nih.gov/28703637 (abstract read)

**Development**
- Rousselle, L. and Vossius, L. (2021). Acquiring the Cardinal Knowledge of Number Words: A Conceptual Replication. Journal of Numerical Cognition 7(3). https://jnc.psychopen.eu/index.php/jnc/article/view/7029 (abstract read)
- Zubler, J. M. et al. (2022). Evidence-Informed Milestones for Developmental Surveillance Tools. Pediatrics 149(3). doi:10.1542/peds.2021-052138 (secondary coverage only, e.g. https://www.disabilityscoop.com/2022/02/10/cdc-revises-developmental-milestones-for-young-kids/29698/)
- Crawford, C., Dearden, L. and Greaves, E. (2013). When You Are Born Matters: Evidence for England. IFS for the Nuffield Foundation. https://www.nuffieldfoundation.org/impact-month-birth-child-development (read)
- Jordan, N. C., Kaplan, D., Ramineni, C. and Locuniak, M. N. (2009). Early Math Matters. Developmental Psychology 45(3), 850-867. (abstract via search)
- Duncan, G. J. et al. (2007). School Readiness and Later Achievement. Developmental Psychology 43(6). (search summaries only; the APA page returned empty)
- Gathercole, S. E., Pickering, S. J., Ambridge, B. and Wearing, H. (2004). The Structure of Working Memory From 4 to 15 Years of Age. Developmental Psychology 40(2). https://pubmed.ncbi.nlm.nih.gov/14979759/ (abstract via search)
- Cowan, N. (2016). Working Memory Maturation. Perspectives on Psychological Science 11(2). https://pmc.ncbi.nlm.nih.gov/articles/PMC4800832 (read, first part)
- Clements, D. H. and Sarama, J., Building Blocks learning trajectories handout (2014): level names; no ages in it. https://oldsite.earlychildhoodwebinars.com/wp-content/uploads/2013/11/Building-Blocks-Learning-Trajectories-handout-Clements-Sarama.pdf (text extracted and read). The "rough guides, lower bounds" wording came from a reproduction at https://hamiltonnicole.blogspot.com/2015/03/primary-math-continuum.html (snippet; not primary).
- "Minutes of attention per year of age": only parenting blogs were found, no primary study (e.g. https://www.earlyyears.tv/attention-span-development/). Treated as unverified.

**Adaptivity and labelling**
- Klinkenberg, S., Straatemeier, M. and van der Maas, H. L. J. (2011). Computer adaptive practice of Maths ability using a new item response model for on the fly ability and difficulty estimation. Computers and Education 57(2). (abstract via search)
- Park, J. Y., Cornillie, F., van der Maas, H. L. J. and Van Den Noortgate, W. (2019). A Multidimensional IRT Approach for Dynamically Monitoring Ability Growth in Computerized Practice Environments. Frontiers in Psychology. https://www.frontiersin.org/articles/10.3389/fpsyg.2019.00620 (read: the cold start problem, age as a learner feature)
- Jansen, B. R. J. et al. (2013). The influence of experiencing success in math on math anxiety, perceived math competence, and math performance. Learning and Individual Differences 24. https://dare.uva.nl/id/789fc422-4935-49ca-bcba-803239522951 (abstract read; the exact success rates not given there)
- Khan Academy Kids, "How the Learning Path works". https://khankids.zendesk.com/hc/en-us/articles/360041615571 (403; secondary reviews only)
- Bradbury, A. and Roberts-Holmes, G. (2017). Grouping in Early Years and Key Stage 1: A "necessary evil"? NEU / UCL. https://discovery.ucl.ac.uk/id/eprint/10039076/ (listing and a TES summary only)

**Not verified:**
- the Ministry's own current registration circular and cut-off;
- the grade 1 month-by-month reading targets;
- Khan Academy Kids' placement logic;
- the exact Math Garden starting rating and success targets;
- the primary Clements and Sarama text on the ages of the levels.
