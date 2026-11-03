# English course: research report (B-44)

Author: english-language-teacher. Date: 2026-11-03. Status: draft for the owner (plan only, no code).
Method: `.claude/skills/curriculum-research/SKILL.md` (§2's source order). Binding decisions: `docs/languages/README.md` (the owner's six decisions of 2026-11-03). Companion files: `docs/languages/english/syllabus.md`, `templates.md`, `voice-brief.md`.

Citation rule: each source says how it was used. "Opened" means the text was read in this session; "abstract seen" or "record seen" means only the bibliographic record or abstract was read, and only what it says is used; "not opened in this session" marks a standard, well-known reference cited from its published record without re-reading it today, used only for its headline finding. Before any of these is quoted in a parent text or a milestone file, the "not opened" ones should be checked against the paper. Short keys in [brackets] are used in the syllabus.

---

## 1. The question

- **Subject:** English as a foreign language (EFL) for Hebrew-speaking children aged 3 to 8, in the Languages category.
- **Bands:** A (3-4), B (5-6), C (7-8) (`docs/PLAN.md` › Learners & age bands). The child is placed by mastery, not by age (owner, decision 2).
- **Learners:** Hebrew first language. Any child at any level: never heard English; understands some English (heard at home, in gan, from media); already reads some English.
- **What the course teaches:** listening, speaking, **reading and writing**, step by step from the basics (decision 3).
- **What the app can do:** tap, drag, trace, listen; a microphone only on a tap and only when a parent turned voice on; no timers, streaks or guilt. The on-device speech recogniser today is a Hebrew model only (`app/lib/speech/sherpa_engine.dart`, ivrit.ai streaming model). The fonts are Heebo and Secular One; a Latin teaching font is approved in principle (decision 1).
- **Voice:** lessons are taught in Hebrew by a voice that speaks natural Hebrew and native English (decision 6).
- **Decisions this research must support:** the order of skills per band; when reading and writing start; the phonics order; how much Hebrew; how writing works on a phone; how a child is placed; British or American English; what the voice must do.

---

## 2. Sources read

### 2.1 The official programme (Israel, Ministry of Education)

| Key | Source | What it says that matters here |
|---|---|---|
| [MoE-PF] | Ministry of Education, Inspectorate for English Language Education (2009, updated August 2019). *Guidelines for the Teaching of English at the Pre-Foundation Level, aligned with Can-Do descriptors (CEFR) & the ABLE assessment kit.* https://meyda.education.gov.il/files/Mazkirut_Pedagogit/English/prefoundationcando.pdf (opened; text extracted) | The basic literacy skills are, citing the US National Reading Panel: awareness of the sounds of language, print awareness, letter-sound knowledge, vocabulary, word decoding and spelling. Two stages: **reading readiness** (listening and speaking; phonological representations, that is, the new English phonemes; phonological awareness) and **beginning reading and writing** (grapheme-phoneme correspondences, decoding, encoding/spelling, writing, automaticity/fluency). "MUSTS" include **at least three to four months of listening and speaking before reading**; many rhymes, chants, songs and dialogues; explicit teaching of letter **names and sounds**, single-letter graphemes before digraphs, upper and lower case; **closed (CVC) and open (CV) syllable patterns**, which "account for approximately 53% of the words" Israeli beginners meet; decodable texts built only from taught correspondences; explicit spelling; letter formation; emphasis on **onset-rime** because Hebrew stresses other sub-syllabic units; explicit teaching of the **novel phonemes** that do not exist in the L1; instructions for phoneme games "can be practiced in simple English but translated into L1 as needed". It fits "mostly the 3rd grade and the beginning of 4th grade". It has a 200-word pre-foundation list and a list of conversational chunks (Hello, What's your name?, What's this? It's a..., I like..., Where is...?, Thank you...). |
| [MoE-2020] | Ministry of Education, Language Department (November 2020). *English Curriculum 2020.* https://meyda.education.gov.il/files/Mazkirut_Pedagogit/English/Curriculum2020.pdf (opened; text extracted) | Aligned to the CEFR: Pre-Basic User = **Pre-A1** = old "Pre-foundation"; Basic User I = **A1** = old "Foundation". Lexical **Pre-Band I** = Pre-A1 = "Grade 3 and/or first months of Grade 4"; Band I Core I (A1) = grade 4 to mid-grade 5. "Instruction for young learners at the Pre-Basic User (Pre-A1) level focuses primarily on establishing aural/oral skills, as a basis for reading and writing." Table 6, principles of beginning teaching: rich comprehensible input; high-frequency words, chunks and patterns; an oral vocabulary before reading and writing; rhymes, chants, songs, dialogues; teach phonemic awareness; teach decoding and encoding of letters and syllables; build sight vocabulary. It also endorses "a judicious exploitation of L1" and "occasional translations of words, brief explanations of L1-L2 differences". |
| [MoE-PreA1] | Ministry of Education, *Can dos: Pre-basic user (Pre-A1)*, English, elementary. https://pop.education.gov.il/tchumey_daat/english/yesodi/curriculum/basic-user-a2/ (opened; no date on the page) | The Pre-A1 can-do statements. Reception: short, slow, clear questions and instructions; numbers, days; Pre-Band I words with pictures; letters in upper and lower case; full stop and question mark; capital at a sentence start and on a name; reads phonetically spelled words and familiar "irregular words"; reads **left to right and top to bottom**; matches a word to a picture. Production: greetings, please/thank you, "What is it?", recite a rhyme or chant, sing a song from memory, say how one feels. Writing: "Can trace individual letters in the correct direction", copy letters, write the alphabet in upper and lower case, write one's own name with a capital, copy short sentences, end a sentence with a full stop, label pictures by copying words. Linguistic: "spell words according to the appropriate stage in developmental spelling". |
| [MoE-Mikud] | Ministry of Education, recommendations for focusing the elementary English curriculum (COVID period). https://meyda.education.gov.il/files/Pop/0files/english/Yesodi/MikudElementaryNewMarch4.pdf (search result only, not opened) | Lists a grade 3 "Pre-foundation" stage with an emphasis on aural-oral skills and vocabulary. Used only as a pointer. |

**What the programme does not cover.** The Ministry's English programme starts formally at **grade 3** (age 8). I found **no Ministry English programme for kindergarten or grades 1-2** on the Ministry's site (searched in English and Hebrew); news and a Knesset research paper say many schools start English in grade 1 or 2 by local choice (search results, not used as evidence). So for Bands A and B the official programme gives the **content and order** (Pre-A1, oral first, then literacy), but not the age. Our Band C (grades 2-3) overlaps the Ministry's grade 3 start. Everything earlier is our own decision, built on the evidence in §2.3 and §2.4.

### 2.2 Frameworks as yardsticks

| Key | Source | Use |
|---|---|---|
| [CEFR-YL] | Council of Europe (2018). *Collated Representative Samples of Descriptors of Language Competences Developed for Young Learners, Volume 1: Ages 7-10.* https://rm.coe.int/16808b1688 (found; the Pre-A1/A1 section was seen in the search record, the full text not read) | The Pre-A1 band for young learners exists and is organised by reception, production and interaction. Used as the outside yardstick named in [MoE-2020]. |
| [YLE] | Cambridge English (2023). *Young Learners Can Do Statements* poster (Pre A1 Starters, A1 Movers, A2 Flyers). https://www.cambridgeenglish.org/images/461492-young-learners-can-do-statements-.pdf (opened; text extracted) | Pre A1 Starters can-dos: understand simple sentences and very simple descriptions ("This is blue."); respond to simple questions ("How old are you?" "I'm six"); name familiar people and things (cat, mum, dog); spell their name and simple words; recognise and write the letters of the alphabet; copy words, phrases and short sentences; understand simple stories with pictures. |
| [YLE-WL] | Cambridge English. Pre A1 Starters, A1 Movers and A2 Flyers word lists ("for exams from 2018"), linked from https://cambridgeenglish.org/fr/exams-and-tests/young-learners/starters/how-to-prepare (found; the word list itself not opened in this session) | The topic list for vocabulary themes (animals, body, clothes, colours, family, food, home, numbers, school, toys, transport, weather...). Used as a cross-check of themes only, not copied. |

### 2.3 Research syntheses and primary studies

**Early foreign-language learning (input, age, social interaction)**

| Key | Source | Finding | Weight for us |
|---|---|---|---|
| [Jaek17] | Jaekel, N., Schurig, M., Florian, M., & Ritter, M. (2017). From early starters to late finishers? A longitudinal study of early foreign language learning in school. *Language Learning*, 67(3), 631-664. https://doi.org/10.1111/lang.12242 (abstract and press summary seen; full text not opened) | German pupils who started English in grade 1 led in grade 5, but by grade 7 later starters had overtaken them. The authors do not argue against early English as such. | An early start in a low-input setting gives **no automatic lasting advantage**; the amount and quality of input matter more than age. So the app must give a lot of good input and not promise more than it can. |
| [Mun06] | Muñoz, C. (Ed.) (2006). *Age and the Rate of Foreign Language Learning.* Multilingual Matters. (not opened; known book of the Barcelona Age Factor project) | In school settings with few hours, older starters progress faster at first. | Same lesson as [Jaek17]. Thin for ages 3-5. |
| [Kuhl03] | Kuhl, P. K., Tsao, F.-M., & Liu, H.-M. (2003). Foreign-language experience in infancy: Effects of short-term exposure and social interaction on phonetic learning. *PNAS*, 100(15), 9096-9101. https://pubmed.ncbi.nlm.nih.gov/12861072/ (abstract opened) | 9-month-olds learned Mandarin sound contrasts from live speakers, but **not** from the same input on audio-video recordings. | Infants, not our ages; but a warning: passive recorded input teaches little. Our activities must be **contingent** (the child acts, the app answers). |
| [Rose14] | Roseberry, S., Hirsh-Pasek, K., & Golinkoff, R. M. (2014). Skype me! Socially contingent interactions help toddlers learn language. *Child Development*, 85(3), 956-970. https://doi.org/10.1111/cdev.12166 (not opened in this session; cited from the known record) | Toddlers learned new verbs from a live, responsive video partner but not from a pre-recorded one. | Same direction: responsiveness helps. |
| [Asher69] | Asher, J. J. (1969). The total physical response approach to second language learning. *The Modern Language Journal*, 53(1), 3-17. https://doi.org/10.1111/j.1540-4781.1969.tb04552.x (not opened in this session) | Listening comprehension through acting out commands. | Classic, widely used with young learners; **the controlled evidence is old and mostly with older learners**. We use TPR because it suits non-readers and keeps listening before speaking, not because of strong trials. |
| [Coyle14] | Coyle, Y., & Gómez Gracia, R. (2014). Using songs to enhance L2 vocabulary acquisition in preschool children. *ELT Journal*, 68(3), 276-285. (record seen, results not read) | A small study of 25 five-year-old Spanish EFL learners, three song-based lessons. | Small; shows songs are used and studied with our age, not how big the effect is. |
| [Davis17] | Davis, G. M. (2017). Songs in the young learner classroom: a critical review of evidence. *ELT Journal*, 71(4), 499-508. https://doi.org/10.1093/elt/ccx033 (record seen, text not read) | A critical review of the evidence for songs. A related systematic-review poster (search result) reports "predominantly positive effects" but "weak overall strength of evidence". | **Songs: thin evidence.** We use songs and chants for repetition, rhythm, chunks and enjoyment, always paired with a picture task, never as the only teaching. |

**Vocabulary, retrieval and spacing**

| Key | Source | Finding |
|---|---|---|
| [Child02] | Childers, J. B., & Tomasello, M. (2002). Two-year-olds learn novel nouns, verbs, and conventional actions from massed or distributed exposures. *Developmental Psychology*, 38(6), 967-978. (not opened in this session) | Young children retain new words better when exposures are spread out. |
| [Curr] | `docs/curriculum.md` §1 principle 8 and §10.2 (the app's own rules: retrieval at every session start, FSRS spacing about 1 → 3 → 7 → 21 → 60 days, fresh vs durable mastery) | The English course uses the same engine. |
| [MoE-PF] | as above | "Set vocabulary acquisition goals ... monitoring their progress"; recycle words across texts. |

**Phonics and reading in English**

| Key | Source | Finding |
|---|---|---|
| [NRP] | National Reading Panel (2000). *Teaching Children to Read.* NICHD. https://www.nichd.nih.gov/publications/pubs/nrp/smallbook (not opened in this session; cited by [MoE-PF] itself) | Systematic phonics and phonemic-awareness instruction help beginning readers. |
| [Ehri01] | Ehri, L. C., Nunes, S. R., Stahl, S. A., & Willows, D. M. (2001). Systematic phonics instruction helps students learn to read: Evidence from the National Reading Panel's meta-analysis. *Review of Educational Research*, 71(3), 393-447. https://doi.org/10.3102/00346543071003393 (not opened in this session) | Systematic phonics beats unsystematic or no phonics, with the largest effects in kindergarten and grade 1. |
| [CRN18] | Castles, A., Rastle, K., & Nation, K. (2018). Ending the reading wars: Reading acquisition from novice to expert. *Psychological Science in the Public Interest*, 19(1), 5-51. https://doi.org/10.1177/1529100618772271 (not opened in this session) | Alphabetic decoding is the foundation; explicit instruction in letter-sound mappings is needed; afterwards wide reading builds automatic word recognition and comprehension. |
| [EEF-Ph] | Education Endowment Foundation. *Teaching and Learning Toolkit: Phonics.* https://educationendowmentfoundation.org.uk/education-evidence/teaching-learning-toolkit/phonics (not opened in this session) | Phonics rated a high-impact, well-evidenced approach for early readers. |
| [DfE-RF] | Department for Education (England) (2021, updated 2023). *The reading framework: teaching the foundations of literacy.* https://www.gov.uk/government/publications/the-reading-framework-teaching-the-foundations-of-literacy (search record seen) | Talk, stories and **systematic synthetic phonics (SSP)** in the first school year; fidelity to one programme; decodable books matched to taught sounds. Critics in the same results note that comparisons between phonics types do not show a clear winner. |
| [L&S07] | Department for Education and Skills (2007). *Letters and Sounds* (00281-2007BKT-EN), Phase Two. Copy: https://english.hias.hants.gov.uk/mod/resource/view.php?id=1387 (search record seen; the set order confirmed by several school pages) | Phase 2 sets, one a week: **s a t p / i n m d / g o c k / ck e u r / h b f ff l ll ss**; Phase 3: the rest of the alphabet, then digraphs. The order lets children read real words (sat, pin, tap) from the first week. |
| [McT20] | McTigue, E. M., Solheim, O. J., Zimmer, W. K., & Uppstad, P. H. (2020). Critically reviewing GraphoGame across the world. *Reading Research Quarterly*, 55(1), 45-73. https://doi.org/10.1002/rrq.256 (abstract and summaries seen) | A phonics **app** alone showed no significant effect over controls when all studies were pooled; about 0.48 when an adult was engaged with the child. |

**English reading for Hebrew-speaking children**

| Key | Source | Finding |
|---|---|---|
| [KH06] | Kahn-Horwitz, J., Shimron, J., & Sparks, R. L. (2006). Weak and strong novice readers of English as a foreign language: Effects of first language and socioeconomic status. *Annals of Dyslexia*, 56(1), 161-185. https://doi.org/10.1007/s11881-006-0007-1 (abstract seen) | In Hebrew-speaking elementary pupils, **knowledge of English letters** separated strong from weak EFL readers more than Hebrew L1 skills did. |
| [KH12] | Kahn-Horwitz, J., Sparks, R. L., & Goldstein, Z. (2012). English as a foreign language spelling development: A longitudinal study. *Applied Psycholinguistics*, 33(2). https://doi.org/10.1017/S0142716411000397 (abstract seen) | Hebrew L1 pupils followed from grade 4 to 12: early English spelling strongly predicted later spelling; grade-4 L1 literacy mattered. |
| [KH16] | Kahn-Horwitz, J. (2016). Providing English foreign language teachers with content knowledge to facilitate decoding and spelling acquisition: a longitudinal perspective. *Annals of Dyslexia*, 66(1), 147-. https://doi.org/10.1007/s11881-015-0120-0 (title seen only) | Israeli EFL teachers need explicit knowledge of English orthography to teach decoding and spelling. (Also a co-author of [MoE-PF] 2019.) |
| [RKH15] | Russak, S., & Kahn-Horwitz, J. (2015). English as a foreign language spelling: comparisons between good and poor spellers. *Journal of Research in Reading*. (abstract seen) | 233 Hebrew-speaking pupils, grades 5, 8, 10: Hebrew spelling was one of the strongest predictors of English spelling in grades 5 and 8. |
| [RSH11] | Russak, S., & Saiegh-Haddad, E. (2011). Phonological awareness in Hebrew (L1) and English (L2) in normal and disabled readers. *Reading and Writing*, 24(4), 427-442. https://doi.org/10.1007/s11145-010-9235-1 (abstract seen) | Phonological awareness was weaker in English than in Hebrew, and depended on whether the target phoneme **exists in Hebrew**. College students, not children. |
| [Share08] | Share, D. L. (2008). On the Anglocentricities of current reading research and practice. *Psychological Bulletin*, 134(4), 584-615. https://doi.org/10.1037/0033-2909.134.4.584 (not opened in this session) | English spelling is an outlier among alphabets; results from English readers do not transfer automatically to other scripts, and the reverse. |
| [Laufer99] | Laufer, A. (1999). Hebrew. In *Handbook of the International Phonetic Association* (pp. 96-99). Cambridge University Press. (not opened in this session) | Standard Israeli Hebrew has five vowels /a e i o u/ with no length or tense/lax contrast; no /θ ð/; /w/ only marginally in loans; a uvular /ʁ/. |

**Handwriting**

| Key | Source | Finding |
|---|---|---|
| [Long05] | Longcamp, M., Zerbato-Poudou, M.-T., & Velay, J.-L. (2005). The influence of writing practice on letter recognition in preschool children: A comparison between handwriting and typing. *Acta Psychologica*, 119(1), 67-79. (abstract seen) | 38 children aged 3-5: in the **older** children, handwriting practice gave better letter recognition than typing. |
| [PP16] | Patchan, M. M., & Puranik, C. S. (2016). Using tablet computers to teach preschool children to write letters: Exploring the impact of extrinsic and intrinsic feedback. *Computers & Education*, 102, 128-137. https://doi.org/10.1016/j.compedu.2016.07.007 (summary seen) | Children aged 41-65 months: a **finger on a tablet** led to more correctly written letters than a stylus; stylus about equal to paper. |
| [SG16] | Santangelo, T., & Graham, S. (2016). A comprehensive meta-analysis of handwriting instruction. *Educational Psychology Review*, 28(2), 225-265. (not opened in this session) | Explicit handwriting instruction improves legibility and fluency, and also writing quality. |

**The first language in the lesson**

| Key | Source | Finding |
|---|---|---|
| [LM13] | Lee, J. H., & Macaro, E. (2013). Investigating age in the use of L1 or English-only instruction: Vocabulary acquisition by Korean EFL learners. *The Modern Language Journal*, 97(4), 887-901. (abstract seen) | 443 elementary pupils and adults: both groups learned more vocabulary when links were made to the L1, and **the young learners benefited more**. |
| [LN10] | Lugo-Neris, M. J., Jackson, C. W., & Goldstein, H. (2010). Facilitating vocabulary acquisition of young English language learners. *Language, Speech, and Hearing Services in Schools*, 41(3), 314-327. https://doi.org/10.1044/0161-1461(2009/07-0082) (abstract seen) | Spanish-speaking preschoolers in the US learned more English words from storybooks when Spanish explanations ("bridging") were added. A second-language (not foreign-language) setting. |
| [MoE-2020] | as above | "a judicious exploitation of L1". |

### 2.4 Practice sources (illustration only, never evidence)
- The Letters and Sounds and Jolly Phonics style of order (a small set of high-utility letters first, so words come early).
- Letter-formation families (c-a-d-g-o-q; l-i-t; r-n-m-h-b-p) as used in many handwriting schemes. I found no study that compares letter-family orders; this is a practice convention, marked "assumption" in the syllabus.

---

## 3. What the sources agree on

1. **Listening and speaking come first, with lots of meaningful, repeated input** ([MoE-PF] at least 3-4 months; [MoE-2020] Table 6; [YLE]; [Jaek17] and [Mun06] on the weight of input). Comprehension runs ahead of speaking.
2. **Contingent, active input beats passive exposure** ([Kuhl03], [Rose14]). In an app this means: every English line is tied to something the child does (tap, drag, act), and the app answers.
3. **Literacy in English is taught explicitly and systematically**: phonological awareness, letter sounds (and names), blending, segmenting, decodable words and texts, spelling, letter formation ([MoE-PF], [MoE-PreA1], [NRP], [Ehri01], [CRN18], [DfE-RF], [EEF-Ph]).
4. **For Hebrew speakers specifically**: English letters and their sounds are the bottleneck ([KH06]); the phonemes that Hebrew lacks need explicit teaching and are harder in phonological tasks ([MoE-PF], [RSH11], [Laufer99]); onset-rime units need attention ([MoE-PF]); spelling is predictable from early spelling and from L1 literacy ([KH12], [RKH15]).
5. **Handwriting is worth teaching by hand**, and on a tablet a finger works ([Long05], [PP16], [SG16]); the Ministry wants letters traced and copied "in the correct direction" ([MoE-PreA1]).
6. **Some Hebrew helps young learners** with meaning and with instructions ([LM13], [LN10], [MoE-2020], [MoE-PF]).
7. **Spacing and retrieval** make words last ([Child02], [Curr]).

## 4. Where they disagree, or the evidence is thin

- **When to start reading English.** The Ministry starts literacy in grade 3 after an oral period ([MoE-PF], [MoE-2020]). England starts SSP at 4-5, but in the children's first language ([DfE-RF]). I found **no controlled study of teaching English phonics to Hebrew-speaking 5-6-year-olds** who are learning to read Hebrew at the same time. Risk: two scripts with opposite directions while Hebrew decoding is forming. Benefit: young children enjoy letter-sound games, and letter knowledge is the bottleneck later ([KH06]). **Thin.** My choice is in §5.2.
- **Songs, chants and TPR**: widely used, weak or old evidence ([Davis17], [Asher69]). Used for repetition and engagement, always with a task.
- **Phonics apps alone**: weak without an adult ([McT20]). The app must invite a parent in (co-play prompts) and must not claim it replaces a teacher.
- **Which phonics programme or order**: no clear winner between programmes ([DfE-RF] critics; [Ehri01] found systematic beats unsystematic, not one order over another). The order is a reasoned choice (§5.3).
- **L1 use**: the studies are with older children ([LM13]) or with English as the surrounding language ([LN10]). No study of Hebrew support in an English app for 3-8-year-olds. My choice is a principled "Hebrew frame, English target" (§5.5).
- **Speaking assessment by machine**: child speech recognition is unreliable at these ages (`docs/curriculum.md` §1 principle 9: error rates near 35% at 4-6), and our recogniser is Hebrew only. No evidence base for scoring a young EFL child's pronunciation by an app.
- **Placement in a foreign language for 3-8-year-olds**: I found no validated placement test for this age outside commercial products; Cambridge YLE are end-of-level tests, not placement. **Thin.** The design in §5.6 follows the app's own staircase (`docs/curriculum.md` §10.1).
- **Bands A and B in the Ministry programme**: none exists (§2.1). Bands A-B content is aligned to Pre-A1 content, not to an Israeli age.

## 5. Decisions (proposed; the owner decides the numbered ones in §6)

### 5.1 Shape of the course
Seven **stages** that any child passes through in order, whatever the age, placed by mastery:
1. **First words** (listening, actions, songs).
2. **Talking** (chunks and short exchanges) with **sound play** (rhythm, syllables, rhyme, the new English sounds).
3. **Sounds and letters** (letter sounds, oral blending and segmenting, letter formation).
4. **Reading words** (blending CVC words, building them, first tricky words).
5. **More sounds** (digraphs, consonant clusters, long vowels, capitals and full stop).
6. **Reading sentences** (decodable sentences, sentence building, simple grammar in chunks).
7. **Reading and writing short texts** (decodable stories, answering, writing two or three sentences).

Skill ids carry the band where the skill is **usually first taught** (ENG-A, ENG-B, ENG-C). Band decides presentation (session length, motor demands, look); stage and mastery decide content. A Band C child new to English starts at stage 1, with Band C presentation and a faster oral period (syllabus §6).

### 5.2 When reading and writing start
- **Band A (3-4): oral only.** No letters as reading targets (the agent brief and `PLAN.md`: pre-readers). Sound play (rhythm, syllables) is oral.
- **Band B (5-6): oral first, then letter sounds when the oral gate is passed.** The gate: the stage-2 oral core mastered (about 100 words and 15 chunks heard and understood) plus English sound play. Then the first letter sounds with **oral** blending and building words with tiles; reading of VC/CVC words from the first two letter groups only. Default **off** until the gate; a parent can hold the course at "oral only" in the parent area. Rationale: [KH06] (letters are the bottleneck), [MoE-PF] (oral period first), the thin evidence above (so gentle and reversible).
- **Band C (7-8): full literacy track** after a compressed oral period (the Ministry's 3-4 months maps to roughly 20-30 sessions for a child new to English; less for a child who already understands).
- This is owner decision 2 in §6.

### 5.3 The phonics order (systematic synthetic phonics, adapted for Hebrew speakers)
Based on [L&S07] and [MoE-PF], with three adaptations:
- Groups of letters that make real, picturable words early: **s a t p / i n m d / g o c k ck / e u r h b f l (ff ll ss)**, then **j v w x y z zz qu**, then **sh ch th ng**, then long vowels.
- **Short vowels are spread out and contrasted** (a, i, o first; e and u later), because /æ/ /ɛ/ /ʌ/ /ɪ/ do not exist in Hebrew ([Laufer99]) and collapse into Hebrew /a e i/ ([RSH11]).
- **v and w are taught in the same group and contrasted** (van / wet), the most common Hebrew-speaker confusion. **th** gets its own listening and saying practice before reading.
- **Open syllables (CV: he, me, we, go, no)** and **closed syllables (CVC)** are named as patterns, as [MoE-PF] requires, and the silent-e pattern (CVCe) comes at stage 5-6.
- Letter **sounds** first for reading; letter **names** taught alongside from stage 3 through an alphabet song and in Band C for spelling names ([MoE-PF] wants both; teaching sounds first avoids the "c says /siː/" error).
Full order: syllabus §3.

### 5.4 Vocabulary and chunks
- About **300 words and 40 chunks** over the course: stage 1-2 about 120 words, the rest by stage 7. Themes follow [MoE-PF]'s Pre-Band I list and chunks and the [YLE-WL] topics: greetings and feelings, colours, numbers, body, family, animals, food, toys, clothes, home, classroom, actions, weather, days, places and positions, nature, transport.
- Words are concrete, picturable, high-frequency and **decodable where possible** when they reach reading ([MoE-PF]: words read and spelled are built from taught correspondences).
- Meaning comes by **picture and action first**, the English word heard 2-3 times before any Hebrew gloss (agent brief; [Kuhl03]); a Hebrew gloss is a hint, not the default ([LM13]).
- **No personal questions** (`CLAUDE.md` › Child safety). The Ministry's "What's your name? How old are you? Where do you live?" are taught through **puppets and pictures**: the child answers *for a character* ("I'm Bobo", "I'm five" for a picture with five candles), never with their own details, and nothing is stored or sent.

### 5.5 Hebrew support
"Hebrew frame, English target":
- Instructions, praise and hints are in Hebrew at first (hebrew-text-editor owns their wording). Over the stages, ten classroom instructions move into English as taught chunks ("Listen!", "Touch the...", "Look!", "Well done!"), always with the same picture icon, so by stage 4 a child hears short English instructions with Hebrew still on the replay.
- The English item is never translated before the child hears it with a picture. A Hebrew gloss appears only at hint level 2 or for an abstract word (feelings, positions).
- Explicit Hebrew-English contrasts, briefly, where they help: "in English we read from left to right", "English has big and small letters", "this sound does not exist in Hebrew: put your tongue between your teeth" ([MoE-PF], [MoE-2020]).

### 5.6 Placement
- A short, game-like **listening-first staircase** (`docs/curriculum.md` §10.1): picture choice for words (stage 1-2 core), then chunks, then (only if the child is in Band B-C and the parent says the child knows some letters) letter sounds, CVC word reading, sentence reading. Two right moves up, one miss moves down; stop after 2 reversals or 10 items; start one level below the highest level passed.
- **Entry points**: E0 new (stage 1), E1 understands some (stage 2), E2 knows letter sounds (stage 3 end / stage 4), E3 reads CVC words (stage 5), E4 reads sentences (stage 6). Skipped skills become "assumed" and are checked by interleaved retrieval in the first two weeks.
- No result is shown to the child; the parent sees "we start here" and can move it one level.

### 5.7 Writing on a phone
- **Letter formation by finger tracing** with the existing trace template (start dot, direction arrow, stroke order, tolerance), on **four guide lines** (top, x-height dashed, baseline, descender) ([PP16] finger is fine; [Long05] handwriting over typing; [MoE-PreA1] "trace ... in the correct direction").
- **Lowercase first**, by formation families (assumption, §2.4); capitals in stage 5 for names and sentence starts.
- **Spelling (encoding) by letter tiles** dragged left to right into slots, so spelling is practised without the motor load; handwritten words only in Band C and with a large canvas (tablet or landscape phone).
- **Sentences by word tiles**, then completing a sentence from a word bank, then writing a short sentence with tiles plus one word written by hand ([MoE-PreA1]: copy short sentences; complete with a word bank).
- Hebrew writing habits to watch: strokes that start on the right, circles drawn clockwise, writing a word right to left (assumption from the scripts; no study found).

### 5.8 Speaking
- Speaking is practised by **echoing, chanting and role-play** from stage 1. With today's Hebrew-only recogniser, English speaking is **not scored**: the child says it with the voice, then taps. If the owner approves an English on-device model later, it may confirm a word, using the same rule as everywhere: unclear speech is never "wrong" (owner decision 4).

### 5.9 British or American spelling and accent
**Recommendation: American spelling and a General American accent**, for the owner to decide (decision 1). Reasons:
- The Ministry's own English documents use American spelling ("color", "recognize" in [MoE-PF] and [MoE-PreA1]); the children's media English is mostly American.
- General American is **rhotic**: the written r is said (car, bird), which matches how Hebrew-speaking children expect letters to work and makes the r-controlled vowels easier to read.
- Against it: most phonics programmes ([L&S07], [DfE-RF]) were written for Southern British English (non-rhotic), and Cambridge YLE is British. The phonics order still works; only the r-controlled and short-o sounds change (syllabus §3.5).
- Either choice is kept everywhere: spelling, voice, word choice (mom, color, gray, favorite, cookie, candy). A child who later meets the other variety in school is not harmed; Israeli schools accept both if consistent.

## 6. Open questions for the owner

Numbered, with my recommendation. They are repeated in the team report.

1. **British or American English?** Recommend **American** spelling with a **General American** voice (§5.9).
2. **When does English reading start?** Recommend: Band A oral only; Band B letter sounds and simple word reading after an oral gate, with a parent switch "oral only"; Band C full literacy after a compressed oral period (§5.2).
3. **How much Hebrew?** Recommend "Hebrew frame, English target", with ten instructions moving into English over the stages and Hebrew glosses only as hints (§5.5).
4. **Speaking with the microphone in English.** Recommend: unscored echo and role-play first (no microphone needed); later, a separate decision on an English on-device recogniser (a new model and package, the owner's OK) (§5.8).
5. **A Latin teaching font.** Recommend the design-director proposes one with a single-storey "a" and "g" and clear b/d/p/q (Heebo's Latin "a" is double-storey), under decision 1 (`templates.md`).
6. **Isolated phonemes.** If no text-to-speech voice gives clean isolated sounds after a pilot, recommend falling back to a whole word with the sound stretched ("sssun"); a recorded human set would be a separate owner decision (`voice-brief.md`).
7. **Parent co-play.** Recommend short co-play prompts in the parent area for the reading stages, because phonics apps work better with an adult ([McT20]).

## 7. What is out of scope, and why
- Grammar as rules (tenses, parts of speech): taught only as chunks and patterns (Pre-A1).
- Free conversation with the AI tutor in English: the tutor's model sees placeholders only and may not ask personal questions; an English tutor would need its own validator and safety review. Not in this course plan.
- Cursive handwriting: not at Pre-A1; print only ([MoE-PreA1] "standard print conventions").
- Scoring pronunciation: no reliable child-speech basis (§4).
- Keyboard typing: no; tiles and tracing instead ([Long05]).
