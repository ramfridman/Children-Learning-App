# The Hebrew language and literacy course: research report (B-44)

Author: hebrew-language-teacher (Hebrew Teacher Agent), 2026-11-03. Status: research for the owner's decision. Plan only: nothing is built, no voice was made, nothing was spent.
Companion files: `docs/languages/hebrew/syllabus.md` (the scope and sequence), `docs/languages/hebrew/templates.md` (the activity templates), `docs/languages/hebrew/voice-brief.md` (the voice and letter-shape requirements).

Binding decisions: `docs/languages/README.md` (the owner, 2026-11-03), especially decision 2 (any child, any level), decision 3 (reading **and writing**, step by step from the very basics) and decision 4 (the Hebrew course is its own course and has nothing to do with the app's Hebrew interface).

## 0. The answer in one page

1. **The course follows the Ministry's new programme, which was published this year.** It is *תוכנית הלימודים להוראת השפה והאוריינות ברצף שבין הגן לכיתות א–ב* (Ministry of Education 2026), with two parts: reading and writing (*רכישת הקריאה והכתיבה*) and communicative competence (*כשירות תקשורתית*). It splits the gan years into three stages (ages 3–4, 4–5, 5–6) and continues into grade 1 (reading and writing built on alphabetic knowledge) and grade 2 (lexical and morpho-orthographic reading). I read both parts in full, and the supervisor's grade 1 policy letter for תשפ"ו (§2).
2. **Pointed Hebrew is learnt by sound: letter plus vowel sign, read as a consonant–vowel unit (*צירוף*), then joined into the word.** This is the Ministry's own description of grade 1 decoding (*ִפּי/צָה → פיצה*). It is also the first phase of Share and Bar-On's triplex model (§3). The CV unit is the natural grain of the course. Hebrew speakers split a syllable into body (CV) and coda (C), not onset and rime (Share and Blum 2005). So the phonological work goes syllable → CV unit → single consonant, and the reading work goes letter+vowel → CV → word.
3. **The order of vowel signs is not fixed by the Ministry** ("סדר סימני הניקוד אינו מחייב"). The policy letter adds that most reading methods open with /a/. There is no study that compares vowel orders (§5.2), so the evidence is thin. I propose a → i → o → u → e → shva and the hatafs, with the reasons, as **owner decision 1**.
4. **No published order of letters is evidence-based for Hebrew either.** I propose six letter groups built on four principles: sounds that can be stretched first, frequent and useful letters, letters that make real picturable words with the vowels already taught, and **confusable letters kept apart in time** and then contrasted on purpose (ב/כ, ד/ר, ה/ח/ת, ו/ז/ן, ס/ם, ע/צ). The soft forms ב כ פ come later than the dagesh forms, as their own step. This is **owner decision 2**.
5. **Reading and writing go together from the start.** The Ministry asks for phonetic ("invented") writing from gan-boger, and for full phonetic writing in grade 1. In grade 1 it does not expect conventional spelling: "קלב" for כלב is a stage, not an error. Israeli longitudinal studies show that kindergarten writing predicts grade 1 decoding, spelling and comprehension (Shatil, Share and Levin 2000). Coached joint writing raised alphabetic skills (Levin and Aram 2012). So spelling items accept a sound-right spelling in Bands B and early C, and conventional spelling is a separate, later skill.
6. **Handwriting:** the Ministry asks for explicit teaching of letter formation "in print and in script" (*בדפוס ובכתב*) in grade 1, with script letters grouped by movement. The arch group is ר ה ת ח ק ב, and the falling group is י ו מ נ ן. The policy letter asks teachers to dwell on the round script. Tracing alone is weak: in an fMRI study of 5-year-olds, only free handwriting, not tracing or typing, recruited the reading network for letters (James and Engelhardt 2012). So the app moves from trace → copy → write from memory. Print letters come in Band B, and script letters (recognise, then write) in Band C.
7. **Unpointed text is formally a grade 3 step** ("הסרת הניקוד תיעשה באופן פורמלי ובצורה מדורגת רק במהלך כיתה ג", policy letter). Grade 2 reads "a few very frequent or short words" without nikud (programme). So the syllabus ends with a bridge (frequent words unpointed, full spelling with helping nikud), not with unpointed reading of texts.
8. **Oral language is half the course, not a warm-up.** The communicative-competence part has goals in vocabulary, morphology, syntax, conversation and extended discourse for every stage. Interactive (dialogic) reading has moderate effects on oral language (Mol, Bus and de Jong 2009), and vocabulary teaching works for young children (Marulis and Neuman 2010). The app's part is listening, word learning, morphology by ear and picture, and story structure. Children can answer by tap, and voice is optional and never scored wrong.
9. **What the app cannot judge, it does not score.** Reading aloud and speaking cannot be scored reliably for young children by speech recognition (curriculum §1 principle 9). Decoding mastery is therefore shown by silent reading tasks with tight distractors: read a word and pick its picture against look-alike and sound-alike words. Reading aloud is practice, with an optional parent check (**owner decision 5**).
10. **Placement** uses seven entry points, from "plays with sounds" to "reads pointed sentences and some unpointed words", in a tap-only staircase of at most 8 items per strand (§10).

## 1. The question

- **Subject:** Hebrew as a first language. The course covers oral language growth and early literacy: phonological awareness, letters, nikud, decoding, fluency and comprehension, handwriting, phonetic and then conventional spelling, and first sentences.
- **Bands:** A (3–4), B (5–6) and C (7–8) (`docs/PLAN.md` › Learners & age bands). A child is placed by mastery, not age.
- **Learners:** Hebrew-speaking children, from one who knows no letter to one who reads pointed text fluently (decision 2). Some will hear another language at home. This course does not assume a family, a school's reading method or the child's name.
- **What the app can do:** tap, drag, trace with a finger, listen and replay, and a parent-enabled mic on a tap. It has no timers, streaks or speed.
- **The decisions it must support:** the scope and sequence, the letter and vowel order, the writing sequence, the templates, the voice and font requirements, and placement.

## 2. The official programme (Ministry of Education)

### 2.1 Documents read

| Document | What it is | How I read it |
|---|---|---|
| **רכישת הקריאה והכתיבה: יעדים נדרשים והצעות לפעילויות המקדמות את השגתם** (Bar-On, Shany, Aram, Levi-Shimon and Kolan; Ministry of Education 2026), part of *תוכנית הלימודים להוראת השפה והאוריינות ברצף שבין הגן לכיתות א–ב* — https://meyda.education.gov.il/files/Pop/0files/ivrit_hinuch_leshoni/Yesodi/acquisition-reading-writing.pdf | The required goals, per stage, for phonological awareness, letter knowledge, reading and writing, from gan (3–4) to grade 2 | **Read in full** (42 pages, text extracted with `pdftotext`) |
| **כשירות תקשורתית: יעדים נדרשים והצעות לפעילויות** (Bar-On, Yifat, Zadunaisky-Ehrlich and Kolan; Ministry of Education 2026) — https://meyda.education.gov.il/files/Pop/0files/ivrit_hinuch_leshoni/Yesodi/kshirut.pdf | The oral-language goals: vocabulary, morphology, syntax, conversation and extended discourse, per stage | Read: the goal statements of every stage; the activity lists skimmed |
| **הוראת השפה העברית בכיתה א — איגרת המפמ"ר, תשפ"ו** — https://meyda.education.gov.il/files/Pop/0files/ivrit_hinuch_leshoni/Yesodi/horaa.pdf | The binding grade 1 policy, built on the new programme | Read: the required achievements, the 13 teaching principles and the appendix on acquisition |
| **לוחות מילים לפי סימני ניקוד** (Kolan) — https://meyda.education.gov.il/files/Pop/0files/ivrit_hinuch_leshoni/Yesodi/word-boards.pdf | Six word boards grouped by vowel sign, used for soft assessment of decoding | Read |
| The grade 1 Hebrew teaching page — https://pop.education.gov.il/tchumey_daat/ivrit_chinhch_leshony/yesodi/pedagogy-hebrew-linguistic-education/teaching-hebrew-grade1 | It links the programme, the letter, the literacy profile, the reading profile, practice boards per vowel and dialogic-reading units | Read |
| The full programme document — https://meyda.education.gov.il/files/Pop/0files/ivrit_hinuch_leshoni/Yesodi/tohnit-limudim-safa.pdf | The programme as one document | **Not opened.** I read its two goal parts above, which cite it as Ministry of Education (2026) |

The earlier report `docs/research/age-fit-teaching.md` (2026-10-29) said that gan literacy is "not decoding", and it could not open the grade 1 letter. The 2026 programme changes that picture a little. Gan-boger (5–6) includes **partial decoding** of new words in the child's surroundings ("התנסויות בקריאת מילים חדשות באמצעות פענוח חלקי של האותיות והצלילים במילה") and **phonetic writing**. **Formal, systematic** decoding instruction is a grade 1 goal.

### 2.2 The stages and their goals (my summary, with the Ministry's terms)

**Stage 1: gan-tsairim, ages 3–4 (ניצני קריאה וכתיבה: הבנת העיקרון האוניברסלי)**
- *Phonological awareness:* recognise and enjoy rhyme; complete repeated sound patterns in rhymes and books.
- *Print:* tell letters from random marks; know the word "letters" and say a few letter names (not necessarily linked to their shapes); notice written words around them; recognise their own first name.
- *Writing:* scribble with features of writing.

**Stage 2: gan-tsairim-bogrim, ages 4–5 (from the universal to the alphabetic principle)**
- *Phonological awareness at the syllable level:* identify and complete rhyme; split words into syllables; blend syllables into words; identify and isolate the opening syllable. Words go from open syllables only (דובי, מתנה), to open and closed (ח–לב, חול–צה), to clusters (גלי–דה), to closed syllables (ספ–סל).
- *Print:* directionality and lines of print; read their own name and classmates' names and common words around them; know some letters and link a letter's shape to its name.
- *Writing:* child writing in play, letter-like and with some letters; write their own name (sometimes with reversed direction or shape); try writing letters. At this stage the representation of syllables is partial, and the letters אהו"י (the vowel letters) are not represented.

**Stage 3: gan-bogrim, ages 5–6 (understanding the alphabetic principle)**
- *Phonological awareness below the syllable, and the letter–sound link:* split words into syllables and smaller units; blend units into words; identify and isolate the opening **CV unit** (*צירוף של עיצור ותנועה*); identify and isolate the **closing consonant**; identify the **opening consonant**; delete a syllable (כפתור without כף → תור).
  - Practical notes: final consonants that can be stretched (ש, ר, ל, ח) are easier to isolate. To identify an opening consonant, **start with words that open with a cluster** (גלידה, כביש, שריקה), where the CV need not be split, and only then go to CV-initial words (בובה, חלון). Continuant consonants are easier: ש ז ס ל ר ח מ נ.
  - Expose the child to the consonant's sound, the letter's name and the letter's shape together.
- *Print:* know the letter names and link each to its shape; know word boundaries; recognise common words; notice the graphic layout of text types (poem, story, card, menu); try reading new words by partial decoding.
- *Writing:* write words in basic, partial and full phonetic writing (פרח as פ; מטוס as מתס). Establish the motor pattern of letters. Write words and phrases for real purposes. Accept any writing, "even if partial or wrong (omissions and substitutions)".

**Stage 4: grade 1 (reading and writing based on alphabetic knowledge)**
- *Alphabetic knowledge, in full:* all letters; all vowel signs; the letters אהו"י (as consonants and as vowels); **homophonous letters** ט–ת, ח–כ, ש–ס, ב–ו, א–ה–ע, ק–כ; **homographic letters** בכ"פ and ש.
  - Explicit, structured, systematic teaching takes **about six months**, and must end **by the end of the school year at the latest**. It is taught in small groups of 6–8, grouped by pace.
  - Teach the letter and the vowel sign and how they join into a CV unit (שִ, or with a vowel letter שִׁי). Practise decoding lists of CV units in which the letter or the vowel changes. Match print letters to script letters step by step.
- *Reading:* accurate linear phonological decoding (reading "מקוטעת" or "מצרפת") of words, sentences and short texts in the vowel signs taught, and say what they mean.
  - Use recurring word structures to decode faster (שמר/כתב; שביר, דביק, שעיר). Show first signs of orthographic recognition of recurring words.
  - "**The order of vowel signs is not binding**." Each sign is practised alone first (בנה), then combined (סִפֵּר).
- *Writing:* **full phonetic writing**, meaning all sounds, consonants and vowels, but not necessarily by the spelling rules (קלב for כלב, יצה for יצא).
  - Children understand word boundaries and leave spaces. Their writing is organised and legible. They internalise the motor pattern.
  - During the year they represent vowels with אהו"י and learn the final letters.
  - Teaching is explicit, **"in print and in script"**, with direction kept. Script letters are learnt in groups by direction: the arch group ר → ה, ת, ח, ק, ב, and the "falling" group י, ו, מ, נ, ן.

**Stage 5: grade 2 (lexical and morpho-orthographic reading)**
- *Reading:* more and more words recognised automatically. Recognition builds on orthographic learning (repeated decoding of עַגְבָנִיָּה) and on morpho-orthographic knowledge (patterns and roots: תַּלְמִיד, תַּרְגִּיל; כָּתַב, כּוֹתֶבֶת, מִכְתָּב).
  - Children read inflection morphemes as units (ים, ות, תי, יו) and the prefixed function letters (בכל"מ, ש, ה, ו).
  - They read **a few very frequent or short words without nikud**. They read pointed sentences and short texts fluently, sometimes still in CV units, with growing rate and prosody. They know some punctuation.
- *Writing:* all sounds represented, with errors in homophonous letters still typical. Common homophonous function letters (final ת, the conjunctive ו) and words from very common roots are spelt right. Writing grows more fluent and legible.

**Grades 3–4** (context-based reading and morphology-based writing) are "to be published later". So the move to unpointed text has no published goals yet.

### 2.3 The grade 1 policy letter (תשפ"ו), the points that bind the course

- **Pointed script first.** "נלמד את יסודות הקריאה והכתיבה של מערכת הכתיב המנוקדת. הסרת הניקוד תיעשה באופן פורמלי ובצורה מדורגת רק במהלך כיתה ג."
- **The approach is analytic-phonic:** systematic teaching of grapheme–phoneme links, and linear decoding by "letter + vowel sign" units.
- **Reading and writing are taught side by side.** Phonetic writing in grade 1 "is a very effective way" to secure alphabetic knowledge.
- **Different starting points suit different children:** the phoneme (letter, then vowel), the CV unit, or the whole word (word → CV unit). Some children respond to building up from the unit to the word, and others to breaking down from the word.
- **Handwriting:** form letters by each letter's accepted writing direction; "dwell on the round script" ("רצוי להתעכב על הכתיבה בכתב העגול").
- **Vowel letters:** most methods open with /a/ CV units. Children learn early that /a/ is shown by the sign alone inside a word, and by sign + ה at the end of a word (שָׁנָה). Overusing vowel letters (שימלה) is better than underusing them (תלמד).
- **Monitoring:** a literacy profile at the start of grade 1 (October–November), then a reading profile and soft assessments with the word boards.

### 2.4 Communicative competence (oral language)

The programme defines two halves: **linguistic knowledge** (vocabulary, morphology, syntax) and **discourse skills** (conversation mechanics, dialogue, extended discourse).
- **Ages 3–4:** basic vocabulary of concrete nouns, verbs and adjectives from near worlds; basic control of obligatory inflection (gender, number, verb forms), still with errors on irregulars and agreement ("כל העיפרונים נפלו"); long but simple sentences; first extended discourse about here-and-now (a personal story, an experience, an explanation).
- **Ages 5–6:** wide vocabulary with more specific nouns and common abstract nouns; coordinated and complex sentences; extended discourse also beyond here-and-now: story, description, explanation.
- **Grades 1–2:** growing vocabulary, including rare and abstract words, terms from school subjects and new meanings of known words; compound and complex sentences; informative discourse (explanation by reason, argument).

### 2.5 What this means for the course

- The skill map follows the five stages above, and the bands map to them: A ≈ stage 1–2, B ≈ stage 2–3 (+ the start of 4), C ≈ stage 4–5. Mastery moves a child on, not age (curriculum §3.3: milestones are reference points, not gates).
- The **CV unit** is a named unit in both phonological awareness and decoding. The app must voice CV units cleanly (`voice-brief.md`).
- **Homophones and homographs** are named goals with fixed lists. They become the distractor families of the course (§7).
- Writing is in **every** band: scribble-play in A, letters, name and phonetic words in B, full phonetic writing, final forms, script and first conventional spelling in C.

## 3. Learning to read pointed Hebrew: the research

| Source | What it shows | How I read it |
|---|---|---|
| Share, D. L. and Bar-On, A. (2018). Learning to read a Semitic abjad: the triplex model of Hebrew reading development. *Journal of Learning Disabilities* 51(5), 444–453. https://pubmed.ncbi.nlm.nih.gov/28703637 | Three phases: (1) sublexical, sequential spelling-to-sound translation in grade 1; (2) lexical and morphological word recognition in grade 2; (3) supralexical use of sentence context in the upper grades, needed for the many homographs of unpointed text. The move from pointed to unpointed text is "a major challenge". | Abstract (and the earlier summary in `age-fit-teaching.md`) |
| Share, D. L. (1995). Phonological recoding and self-teaching: sine qua non of reading acquisition. *Cognition* 55(2), 151–218. https://doi.org/10.1016/0010-0277(94)00645-2 | The self-teaching hypothesis: each successful decoding of a word is a learning trial that builds its written form. The Ministry's grade 2 text names this mechanism ("מנגנון הלמידה העצמית"). | Known paper; cited for the mechanism only |
| Share, D. L. (2008). On the Anglocentricities of current reading research and practice: the perils of overreliance on an "outlier" orthography. *Psychological Bulletin* 134(4), 584–615. https://doi.org/10.1037/0033-2909.134.4.584 | English is an outlier, and findings such as onset–rime units do not transfer to Hebrew. | Known paper; cited for the caution |
| Share, D. (2017). Learning to read Hebrew. In L. Verhoeven and C. Perfetti (Eds.), *Learning to Read across Languages and Writing Systems* (ch. 7). Cambridge University Press. https://www.cambridge.org/core/books/learning-to-read-across-languages-and-writing-systems/learning-to-read-hebrew/F19120C3895ADF9995EA3A0283FACE4A | A handbook chapter on Hebrew reading. The book's contents list Share as author, and the chapter page lists only the editors. | Bibliographic record only; **not read** |
| Shany, M., Bar-On, A. and Katzir, T. (2012). Reading different orthographic structures in the shallow-pointed Hebrew script: a cross-grade study in elementary school. *Reading and Writing* 25(6), 1217–1238. https://doi.org/10.1007/s11145-011-9314-y | A nationally representative sample of grades 2, 4 and 6 reading pointed words of different structures. Accuracy and rate differ by orthographic structure, which supports both universal and Hebrew-specific models. | Abstract |
| Schiff, R. (2012). Shallow and deep orthographies in Hebrew: the role of vowelization in reading development for unvowelized scripts. *Journal of Psycholinguistic Research* 41(6), 409–424. https://education.biu.ac.il/en/node/4541 | 126 children in grades 2, 4 and 6: second graders read pointed text faster and more accurately. In grade 2, pointed-word accuracy mediates unpointed reading, and the effect is gone by grade 6. **Nikud is a scaffold for the later unpointed reading.** | Abstract |
| Shimron, J. (1993). The role of vowels in reading: a review of studies of English and Hebrew. *Psychological Bulletin* 114(1), 52–67. https://doi.org/10.1037/0033-2909.114.1.52 | Vowel signs help beginning and less skilled readers. | Known review; cited for that point only |
| Mizrachi, N. (MA in progress, supervisor D. Share). Methods of teaching reading in first grade Hebrew-speaking classrooms in Israel. University of Haifa, Safra project research summary. https://ejsafra.haifa.ac.il/wp-content/uploads/2022/01/research25.pdf | Almost all Israeli grade 1 instruction is "phonic". There is "considerable controversy over the grain-size" (whole words, CV units or single letters and diacritics), and "little is known" about its impact. | Read (one paragraph) |

**The CV unit as the reading unit.** The Ministry describes grade 1 decoding as reading "צירופי אות וסימן ניקוד" and joining them into a word (*ִפּי/צָה*). It describes the next stage as reading larger units (מִשְׁ–קֶ–פֶת, not מִ–שְׁ–קֶ–פֶ–ת), which come at the end of grade 1 or the start of grade 2 (policy letter, appendix). Phonologically, Hebrew speakers treat CV as a unit (Share and Blum 2005, §4). Whether the **teaching** grain should be the CV unit, the single sign or the word is open (Mizrachi), and the Ministry allows all three starting points. **My choice:** the letter and the vowel sign are each taught explicitly, the CV unit is the unit the child reads and hears, and whole words come as soon as the CVs allow. A whole-word-first route is offered as the second representation for a child who stalls (policy letter: different children, different starting points).

## 4. Phonological awareness in Hebrew

| Source | What it shows | How I read it |
|---|---|---|
| Share, D. L. and Blum, P. (2005). Syllable splitting in literate and preliterate Hebrew speakers: onsets and rimes or bodies and codas? *Journal of Experimental Child Psychology* 92(2), 182–202. https://cris.haifa.ac.il/en/publications/syllable-splitting-in-literate-and-preliterate-hebrew-speakers-on/ | In CVC syllables, the **body (CV)** is the more accessible two-phoneme unit, not the rime. For single phonemes, preliterate children have an advantage for onsets, and literate children prefer codas. | Abstract |
| Bentin, S. and Leshem, H. (1993). On the interaction between phonological awareness and reading acquisition: it's a two-way street. *Annals of Dyslexia* 43, 125–148. https://doi.org/10.1007/BF02928178 | Explicit phonological training in preschoolers builds the missing skills and can help prevent reading failure, and learning to read in turn sharpens phonemic awareness. | Abstract |
| Kozminsky, L. and Kozminsky, E. (1995). The effects of early phonological awareness training on reading success. *Learning and Instruction* 5, 187–201. https://manuscript.isc.ac/Inventory/10/433418.htm (catalogue record) | Longitudinal kindergarten training. Initial phoneme isolation and sound deletion predicted grade 1 reading. | Abstract (the country is not stated in what I saw; I believe it is Israeli, **unverified**) |
| Ehri, L. C., Nunes, S. R., Willows, D. M., Schuster, B. V., Yaghoub-Zadeh, Z. and Shanahan, T. (2001). Phonemic awareness instruction helps children learn to read: evidence from the National Reading Panel's meta-analysis. *Reading Research Quarterly* 36(3), 250–287. https://doi.org/10.1598/RRQ.36.3.2 | Phonemic awareness teaching helps reading and spelling. It works best when taught **with letters**, focused on one or two skills, and in short programmes. | Known meta-analysis; mostly English |
| National Early Literacy Panel (2008). *Developing Early Literacy*. National Institute for Literacy. https://lincs.ed.gov/publications/pdf/NELPReport09.pdf | Alphabet knowledge, phonological awareness, rapid naming, writing one's name and phonological memory predict later literacy. Code-focused interventions and shared reading have effects. | Known report; mostly English |

**What follows.**
- Hebrew phonological awareness runs **rhyme → syllables → CV unit (body) → final consonant → initial consonant → full segmentation**. The Ministry orders gan-boger in the same way: the opening CV unit, then the closing consonant, then the opening consonant.
- English's onset–rime ladder is the wrong model (Share 2008; Share and Blum 2005), so the app never asks for a "rime" in a CVC word.
- From stage 3 on, phonological work is done **with letters on screen** (Ehri et al. 2001; the Ministry's "בשילוב המילה הכתובה").

## 5. The order of letters and vowel signs

### 5.1 Letters

| Source | What it shows | How I read it |
|---|---|---|
| Treiman, R., Levin, I. and Kessler, B. (2007). Learning of letter names follows similar principles across languages: evidence from Hebrew. *Journal of Experimental Child Psychology* 96(2), 87–106. https://profiles.wustl.edu/en/publications/learning-of-letter-names-follows-similar-principles-across-langua/ | Israeli children learn first the letters of **their own name** and frequent letters. Errors come from **shape similarity** and **alphabet adjacency**, and less from sound similarity, because Hebrew letter names sound less alike than English ones. | Abstract |
| Levin, I., Patel, S., Margalit, T. and Barad, N. (2002). Letter names: effect on letter saying, spelling, and word recognition in Hebrew. *Applied Psycholinguistics* 23(2), 269–300. https://www.cambridge.org/core/journals/applied-psycholinguistics/article/letter-names-effect-on-letter-saying-spelling-and-word-recognition-in-hebrew/F5EA025ABE16F199E59C984E188A78B6 | Letter names shape how Hebrew-speaking children say, spell and recognise words. | Bibliographic record |
| Treiman, R., Levin, I. and Kessler, B. (2012). Linking the shapes of alphabet letters to their sounds: the case of Hebrew. *Reading and Writing* 25, 569–585. https://profiles.wustl.edu/en/publications/linking-the-shapes-of-alphabet-letters-to-their-sounds-the-case-o/ | Children sometimes give a letter **a CV sound taken from the first phonemes of its name**, for example "ga" for ג from גימל. | Abstract snippet |
| Share, D. L. (2004). Knowing letter names and learning letter sounds: a causal connection. *Journal of Experimental Child Psychology* 88(3), 213–233. https://cris.haifa.ac.il/en/publications/knowing-letter-names-and-learning-letter-sounds-a-causal-connecti/ | An experiment: letter names that contain the letter's sound help children learn the sound, and unrelated names do not. | Abstract (the language of the participants is not stated in what I saw) |
| Levin, I. and Ehri, L. C. (2009). Young children's ability to read and spell their own and classmates' names: the role of letter knowledge. *Scientific Studies of Reading* (2009). https://www.bohrium.com/paper-details/the-proper-name-as-starting-point-for-basic-reading-skills/811877052041920513-8422 (aggregator record; DOI not verified) | Hebrew-speaking children's reading and spelling of their own and classmates' names, in and out of context, linked to letter knowledge. | Record and abstract only |

**Evidence for an order: thin.** No study compares letter orders in Hebrew. The Ministry leaves the order to the approved reading methods. So the order in the syllabus is a reasoned proposal, built on these principles:
1. **The child's own letters first**, as a doorway, on the device only (Treiman et al. 2007; the Ministry's stage 1–3 activities use names throughout). There is a fallback for a child with no name set.
2. **Sounds that can be stretched before stops** (מ ל ש ר נ ס ז), for blending and for isolating sounds (the Ministry, stage 3).
3. **Frequent letters that make real, picturable words** with the vowels already taught.
4. **Confusable shapes apart in time, then contrasted on purpose** (Treiman et al. 2007: shape confusions are the main error).
5. **One sound per letter first.** The dagesh forms בּ כּ פּ (b, k, p) and שׁ come first. Their second sounds ב כ פ (v, χ, f) and שׂ (s) are a later step on their own, taught as "the same letter, another sound" (the Ministry's homographic letters).
6. **Letter names and sounds are both taught, and named as different things.** A letter name contains the CV that the name starts with (גִּי from גִּימֶל), and children over-extend it (Treiman et al. 2012). So the item "what sound does it make?" is never answered with the name, and the distractor family M-HEB-NAMESOUND catches it.

### 5.2 Vowel signs

| Source | What it shows | How I read it |
|---|---|---|
| The Ministry's programme (2026), grade 1 | "סדר סימני הניקוד אינו מחייב." Practise each sign alone first, then combined. | Read |
| The policy letter תשפ"ו, appendix | Most methods open with /a/ CV units; /a/ is sign-only inside a word and sign + ה at the end. /e/ follows the same pattern (בוכה). /o/, /u/ and /i/ are sometimes shown by ו/י inside a word. | Read |
| Ravid, D. and Haimowitz, S. (2006). The vowel path: learning about vowel representation in written Hebrew. *Written Language & Literacy* 9(1), 67–93. https://doi.org/10.1075/wll.9.1.06rav | In kindergarten, final vowel letters appear in this order: ה (for a and e), then ו and י (for o, u, i). Syllables are easier than words in kindergarten, and the two converge in grade 1. | Abstract (the publisher page returned 403) |
| The Ministry's practice boards (the grade 1 page) | Boards are grouped: חולם; קמץ, פתח, חטף פתח, שווא; סגול, צירה; חיריק; שורוק, קובוץ. The order is not stated. | Read (the list) |

**Evidence for an order: thin.** No study compares vowel orders. **My proposal (owner decision 1):** a (ָ ַ) → i (ִ, ִי) → o (וֹ, ֹ) → u (וּ, ֻ) → e (ֵ, ֵי, ֶ) → shva (silent first, then at the start of a word) → hatafs (ֲ ֱ ֳ). The reasons:
- **a first.** It is the most common way methods open (policy letter), and in modern Israeli Hebrew qamats and patah sound the same, so two signs teach one sound. The word-final ָה gives the first lesson on vowel letters (Ravid and Haimowitz: ה is the first vowel letter children use).
- **i second.** The sign is a single dot under the letter, with no shape like that of a (no confusion). ִי teaches that a vowel can be sign + letter. With a and i, many real words are possible (מִי, לִי, שִׁיר, דִּירָה).
- **o and u next, as a contrasted pair.** Both use ו (וֹ, וּ), and ו is also a consonant (v). Holam and shuruk are told apart by the dot's place, so they are taught one after the other, with a deliberate contrast step.
- **e after o and u.** Tsere and segol look like little groups of dots (two side by side, three in a triangle), which a child can confuse with kubuts and with each other. They come when the child already reads three vowel sounds. The final ֶה again ties to the vowel letter ה.
- **Shva and hatafs last.** Silent shva closes a syllable and is needed early in real words, so a gentle form comes right after i (ילְ–דָּה). Shva at the start of a word, as pronounced in modern Hebrew (גְּלִידָה = [gli-], שְׂמִיכָה = [smi-]), and the hatafs come later. This is where letter-by-letter reading most often goes wrong, and the voice must model the modern pronunciation (`voice-brief.md` §3).
- A school's own method may use another order. The app is a separate course, and every vowel is reached by mastery, so a child who already reads a vowel at school is placed past it (§10).

## 6. The move to unpointed text

| Source | What it says |
|---|---|
| Policy letter תשפ"ו | The formal, gradual removal of nikud happens **only in grade 3**. |
| Programme, grade 2 | Children rely a little less on nikud and read a few very frequent or short words unpointed. |
| Schiff (2012) | Pointed accuracy in grade 2 carries unpointed reading, and nikud is a scaffold that fades. |
| Share and Bar-On (2018) | Unpointed text has many homographs, so sentence context (phase 3) is needed, in the upper grades. |
| `docs/curriculum.md` §8.4 | The app's own nikud policy: full nikud in child-facing text through grade 2; in grade 3, nikud on content and ambiguous words, with a parent toggle. |

**Decision:** the course ends at a **bridge**, not at unpointed reading of texts.
- Frequent short words without nikud (the grade 2 goal).
- Full spelling (ktiv male) with helping nikud (*ניקוד עזר*), as in the Ministry's "קריאה מהנה!" programme texts for grades 2–4.
- Recognising the inflection morphemes and prefixes as units (the grade 2 morpho-orthographic goals).

Unpointed reading of whole sentences is an **extension** that opens by mastery (owner decision 10). Where it goes is a curriculum-expert question for a later band.

## 7. Confusable letters, homophones and homographs

From the Ministry's lists and Treiman et al. (2007), the course has three kinds of confusion. Each kind is a family of tagged distractors (syllabus §5):
- **Shape (reading):** ב/כ, ד/ר (and ך), ה/ח/ת, ו/ז/ן (and י by length), ס/ם, ע/צ, ג/נ, ט/מ, plus the dagesh dot that changes ב/בּ, כ/כּ, פ/פּ and the shin/sin dot. Hebrew children's letter-name errors are mostly shape errors (Treiman et al. 2007).
- **Homophones (spelling, not reading):** ט/ת, כ/ק, ח/כ, ב/ו, א/ה/ע, ס/שׂ (the Ministry lists ש/ס). In pointed text these never make a reading error, because each letter has one sound in context. They make **spelling** errors, which are "typical" in grade 2 (programme). So they are never a reason for "wrong" in Band B writing, and become a spelling skill in Band C.
- **Homographs (reading):** בּ/ב, כּ/כ, פּ/פ, שׁ/שׂ. One shape, two sounds, told apart by a dot.

## 8. Handwriting: print and script

| Source | What it shows | How I read it |
|---|---|---|
| Programme (2026), stages 2–4 | Gan: tools from thick to thin, letters in sand, foam and the air; establish the motor pattern. Grade 1: explicit teaching "in print and in script", kinaesthetic memory aids, large surfaces first, script letters in direction groups (ר ה ת ח ק ב; י ו מ נ ן); match print to script letters step by step. | Read |
| Policy letter תשפ"ו, principle 10 | Form each letter by its accepted direction; dwell on the round script. | Read |
| James, K. H. and Engelhardt, L. (2012). The effects of handwriting experience on functional brain development in pre-literate children. *Trends in Neuroscience and Education* 1(1), 32–42. https://pmc.ncbi.nlm.nih.gov/articles/PMC4274624 | 5-year-olds printed, typed or **traced** letters. Only after printing did letter viewing recruit the reading network; **tracing and typing did not**. The sample was small (about 15). | Abstract and summaries |
| Patchan, M. M. and Puranik, C. S. (2016). Using tablet computers to teach preschool children to write letters: exploring the impact of extrinsic and intrinsic feedback. *Computers & Education* 102, 128–137. https://researchconnections.org/childcare/resources/32955 | Preschoolers practised letters on paper, with a finger on a tablet, or with a stylus on a tablet. **The finger group wrote more letters correctly** than the stylus group. Immediate on-screen error feedback added nothing. | Abstract (the final title may differ slightly; the author's CV lists a working title) |
| Santangelo, T. and Graham, S. (2016). A comprehensive meta-analysis of handwriting instruction. *Educational Psychology Review* 28(2), 225–265. https://doi.org/10.1007/s10648-015-9335-1 | Explicit handwriting instruction improves legibility and fluency, and also the quality and length of writing. | Known meta-analysis; mostly English |

**Decisions (owner decision 6):**
- **Band B: print letters**, in three steps per letter. First trace (a model with a start dot and direction). Then copy (the model beside an empty box). Then write from memory (hear the sound or name, write it). The app judges the start point, the stroke direction and the shape.
- Finger writing is right for this age (Patchan and Puranik 2016), so no stylus is needed.
- On-screen error feedback is gentle and comes at the end of a stroke, never during it.
- **Band C: script letters (כתב יד).** First recognise them (match print ↔ script), then write them in the Ministry's direction groups, with final forms and spacing.
- Script is what Israeli grade 1 writes in, and the Ministry asks for it. Print writing is not dropped: it is how a gan child writes (the Ministry's stage 3 phonetic writing).
- **Paper.** The app cannot replace pencil and paper. Each handwriting skill has a parent co-play card for paper practice (curriculum §12.2).

**Evidence for the age of script: thin.** The Ministry puts script in grade 1, and I found no study of the best age for Hebrew script. A ready 5½-year-old may start script recognition by mastery, but **script writing waits for Band C or for mastered print writing of that letter**.

## 9. Early writing and invented spelling

| Source | What it shows | How I read it |
|---|---|---|
| Shatil, E., Share, D. L. and Levin, I. (2000). On the contribution of kindergarten writing to grade 1 literacy: a longitudinal study in Hebrew. *Applied Psycholinguistics* 21(1), 1–21. https://cris.haifa.ac.il/en/publications/on-the-contribution-of-kindergarten-writing-to-grade-1-literacy-a/ | Kindergarten word writing predicted grade 1 decoding, spelling and reading comprehension, beyond intelligence. Only a third of the children showed a working alphabetic principle in kindergarten. | Abstract |
| Levin, I., Both-De Vries, A., Aram, D. and Bus, A. (2005). Writing starts with own name writing: from scribbling to conventional spelling in Israeli and Dutch children. *Applied Psycholinguistics* 26(3), 463–477. https://resolve.cambridge.org/core/journals/applied-psycholinguistics/article/abs/writing-starts-with-own-name-writing-from-scribbling-to-conventional-spelling-in-israeli-and-dutch-children/F3BB6F301AA826FDCD1BC6973FBA5151 | Own name writing leads the way into writing. | Bibliographic record |
| Levin, I. and Aram, D. (2012). Mother–child joint writing and storybook reading and their effects on kindergartners' literacy: an intervention study. *Reading and Writing* 25(1), 217–249. https://dx.doi.org/10.1007/s11145-010-9254-y | Low-SES Israeli families, three coached groups. Coached **writing mediation raised children's alphabetic skills**; coached storybook reading did not raise language as expected. Writing gains were larger for older children. | Abstract |
| Ouellette, G. and Sénéchal, M. (2017). Invented spelling in kindergarten as a predictor of reading and spelling in grade 1: a new pathway to literacy, or just the same road, less known? *Developmental Psychology* 53(1), 77–88. https://doi.org/10.1037/dev0000179 | Kindergarten invented spelling predicted grade 1 reading beyond alphabet knowledge and phonological awareness (English; word lists, not sentences). | Abstract and summaries |
| Ravid, D. and Tolchinsky, L. (2002). Developing linguistic literacy: a comprehensive model. *Journal of Child Language* 29(2), 417–447. https://doi.org/10.1017/S0305000902005111 | Linguistic literacy grows from the interplay of spoken and written language, including morphology and register. | Known paper; cited for the frame |
| Levin, I., Ravid, D. and Rapaport, S. (2001). Morphology and spelling among Hebrew-speaking children: from kindergarten to first grade. *Journal of Child Language* 28(3), 741–772. https://doi.org/10.1017/S0305000901004834 | Morphological knowledge and spelling grow together in Hebrew. | Known paper; not opened |

**Decisions (owner decision 11):**
- The writing tasks have a **sound-right** outcome. In Bands B and early C, a spelling that shows every sound with a homophone letter (קלב) is "you wrote every sound!", and then the book spelling is shown. It is never "wrong" (the Ministry: accept any writing in gan; full phonetic writing is the grade 1 goal).
- **Conventional spelling** of frequent words, function letters and common roots is a separate Band C skill, which uses the morphology (root families, ת at the end, ו׳ החיבור). It follows the grade 2 goals.
- **Building a word from letter tiles** is the app's writing medium for spelling, because a finger cannot write a whole word legibly on a phone. Finger writing is for letters (§8).

## 10. Vocabulary and oral language

| Source | What it shows | How I read it |
|---|---|---|
| Mol, S. E., Bus, A. G. and de Jong, M. T. (2009). Interactive book reading in early education: a tool to stimulate print knowledge as well as oral language. *Review of Educational Research* 79(2), 979–1007. https://doi.org/10.3102/0034654309332561 | 31 studies, 2,049 children: a **moderate** effect on oral language, and a small share of variance in alphabetic knowledge. Effects shrink in natural classrooms. | Abstract |
| Marulis, L. M. and Neuman, S. B. (2010). The effects of vocabulary intervention on young children's word learning: a meta-analysis. *Review of Educational Research* 80(3), 300–335. https://doi.org/10.3102/0034654310377087 | Vocabulary interventions work for young children. Explicit teaching with rich context works better than incidental exposure. | Known meta-analysis |
| Whitehurst, G. J. et al. (1988). Accelerating language development through picture book reading. *Developmental Psychology* 24(4), 552–559. https://doi.org/10.1037/0012-1649.24.4.552 | The origin of dialogic reading: an adult asks open questions, expands the answer and praises. | Known paper |
| Aram, D. and Biron, S. (2004). Joint storybook reading and joint writing interventions among low SES preschoolers: differential contributions to early literacy. *Early Childhood Research Quarterly* 19, 588–610 (the title varies between reference lists; DOI not verified; cited in https://pubs.asha.org/doi/10.1044/0161-1461(2006/023)) | In Israel, storybook reading helped vocabulary and joint writing helped alphabetic skills. | Known from citations; **not opened** |
| Programme (2026), communicative competence | Goals per stage (§2.4); the Ministry's dialogic-reading units (קריאה דיאלוגית של ספרי ילדים). | Read |

**What follows for an app.**
- Dialogic reading is a conversation, and an app can only do part of it. The narrator reads a short original story with pictures. At planned pauses the narrator asks a CROWD-type question (completion, recall, open, wh-, distancing) with **picture choices**. A spoken answer is optional and never scored, and the answer is expanded and recast in the voice ("נָכוֹן, הַחֲתוּלָה טִפְּסָה עַל הָעֵץ").
- Distancing and open questions belong to the parent: each story has a co-play card with 2–3 questions for the parent to ask.
- **Words are taught on purpose:** 3–5 target words per story, each with a child-friendly meaning, a picture, use in two more contexts, and later retrieval. Concrete nouns and verbs come in A, more specific and some abstract words in B, and school and abstract words in C (the programme, §2.4).
- **Morphology by ear:** gender and number agreement, plurals, word families (roots), "words in the same tune" (*מילים באותה מנגינה*: patterns such as אָכִיל, שָׁבִיר, דָּבִיק; רַקְדָן, חַיְּכָן). The programme uses these for grades 1–2 reading, and they make the bridge from oral morphology to reading in Band C.
- **Stories must be original.** The Ministry's lists name copyrighted books (Datya Ben-Dor, Mirik Snir and others). The app writes its own rhymes and stories (owner decision 12).

**Evidence on screen-based oral language is weak.** Most studies are with live adults, and the effects shrink outside the lab (Mol et al. 2009). The app's oral-language strand therefore leans on the parent co-play cards, and claims modest effects.

## 11. Placement

The curriculum's placement rules apply (`docs/curriculum.md` §10.1: game-like, 4–8 items, a staircase, start one unit low, "assumed" skills verified later, no result shown to the child). For Hebrew I add:
- **Seven entry points**, each tied to a stage of the Ministry's map (syllabus §9).
- **Two strands are placed separately:** oral language and phonological awareness on one side, the code (letters, decoding, writing) on the other. A 4-year-old with rich language may know no letters, and a 6-year-old who reads may have a narrow vocabulary.
- **Only tap tasks place a child.** Reading is placed by "read the word, tap its picture" with look-alike and sound-alike distractors, never by reading aloud.
- **A parent's answer to one question** ("does the child read pointed words?") sets the starting staircase step, never the result.
- **Evidence for app placement accuracy: none found.** Placement is a short, cheap guess that mastery corrects (`age-fit-teaching.md` §0).

## 12. What the app cannot do (out of scope, with reasons)

- **Score reading aloud or speech.** Recognition errors in young children are high (curriculum §1 principle 9). Reading aloud is practice: the child hears a model, reads, and can hear the model again. A parent may optionally confirm in the parent area (owner decision 5).
- **Replace pencil and paper or a teacher in a small group.** The Ministry's model is small-group teaching with feedback on reading aloud. The app gives the code practice, the listening and the retrieval, and leaves conversation and paper writing to the parent cards.
- **Teach grades 3–4 morphology and unpointed reading.** The Ministry has not published those goals yet. The course stops at the bridge (§6).
- **Dyslexia screening or diagnosis.** A child who stays stuck after the ladder and the alternative representation gets a gentle parent note to talk to the gan teacher or the school. The app gives no label.

## 13. Where the evidence is thin (said plainly)

1. **Vowel and letter order:** no comparative study; the Ministry leaves it to the methods. My order is reasoned, not proven.
2. **Teaching grain (CV unit, sign or word):** an open controversy (Mizrachi/Share). I chose CV as the unit and allow word-first as the second representation.
3. **App-based oral language and dialogic reading:** effects shown with live adults; smaller in real settings.
4. **Tracing on a screen:** the fMRI study is small, and the tablet study used Latin uppercase letters. Neither used Hebrew. The trace → copy → memory sequence follows them, and it is a design choice.
5. **Age of script writing:** set by the Ministry's grade 1, not by a study.
6. **Isolated sounds from a TTS voice:** no evidence that a TTS voice can make clean isolated Hebrew phonemes. This must be piloted (`voice-brief.md`).
7. Several sources were read only as abstracts (each is marked above). The Ministry documents were read in full. The rows marked "known paper" (Share 1995, Share 2008, Shimron 1993, Ehri et al. 2001, Marulis and Neuman 2010, Whitehurst et al. 1988, Ravid and Tolchinsky 2002, Levin, Ravid and Rapaport 2001, Ouellette and Sénéchal 2017) are standard references. Their DOIs come from my own knowledge and were **not re-opened today**, so the curriculum-expert should click them once before the syllabus is approved.

## 14. Decisions for the owner (numbered, with my recommendation)

1. **Vowel order a → i → o → u → e → shva → hatafs.** Recommended (§5.2).
2. **Six letter groups** (the letters of steps S1, S2, S4, S5, S6 and S7 in the syllabus §3), with confusable letters apart in time and the soft בכפ/שׂ as their own step. Recommended.
3. **CV unit as the reading and listening unit.** Isolated consonant clips only for sounds that can be stretched, after a pilot. Recommended.
4. **If TTS cannot make clean isolated sounds and CV units,** record them with a native-speaking adult (about 120 short clips; no voice cloning) instead of shipping wrong sounds. This needs the owner's OK and a plan from the voice-and-sound-director. Recommended as the fallback, after the pilot.
5. **Reading aloud is unscored practice,** with an optional parent confirmation in the parent area. Recommended.
6. **Handwriting:** print letters in Band B (trace → copy → memory), script letters in Band C (recognise → write by direction groups), finger on screen plus parent paper cards. Recommended.
7. **Teaching font:** keep Heebo for print if the design-director's audit passes (`voice-brief.md` §6). Otherwise approve a teaching font, and approve a script-letter set drawn as strokes. A decision after the audit.
8. **Use the child's own first name** (on the device only) as early letter material, with a no-name fallback. Recommended. The security-engineer confirms that it is the same on-device name already stored.
9. **Placement in two strands** (language and phonological awareness; the code), tap-only, seven entry points. Recommended.
10. **The unpointed bridge is the end of Band C,** and unpointed sentences are an extension unlocked by mastery. Recommended.
11. **Spelling:** "sound-right" in B and early C, never wrong; conventional spelling as separate later skills. Recommended.
12. **Original rhymes, songs and stories only,** written by the team (needs-editor) and, for songs, a melody the owner approves. Recommended.

## 15. Sources (all cited above)

Official:
- Ministry of Education (2026). תוכנית הלימודים להוראת השפה והאוריינות ברצף שבין הגן לכיתות א–ב: רכישת הקריאה והכתיבה. https://meyda.education.gov.il/files/Pop/0files/ivrit_hinuch_leshoni/Yesodi/acquisition-reading-writing.pdf
- Ministry of Education (2026). … כשירות תקשורתית. https://meyda.education.gov.il/files/Pop/0files/ivrit_hinuch_leshoni/Yesodi/kshirut.pdf
- Ministry of Education (תשפ"ו). הוראת השפה העברית בכיתה א — איגרת המפמ"ר. https://meyda.education.gov.il/files/Pop/0files/ivrit_hinuch_leshoni/Yesodi/horaa.pdf
- Kolan, L. לוחות מילים לפי סימני ניקוד. https://meyda.education.gov.il/files/Pop/0files/ivrit_hinuch_leshoni/Yesodi/word-boards.pdf
- Grade 1 Hebrew page. https://pop.education.gov.il/tchumey_daat/ivrit_chinhch_leshony/yesodi/pedagogy-hebrew-linguistic-education/teaching-hebrew-grade1

Research: the tables of §3–§10 (each with a link and how it was read).

Practice sources (illustration only, never evidence): the Ministry's practice boards per vowel and the "צומחים מחדש" programme, both linked from the grade 1 page.
