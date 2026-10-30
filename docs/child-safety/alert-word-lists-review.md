# Review of the alert word lists: findings, sources, risks and recommendations

**Author and standing.** Written by an AI (Claude) acting as a child-psychology and child-protection adviser for the Nitznutz project, on 2026-10-29. I am **not a licensed clinician, social worker or lawyer**. Everything here is research-based advice for the owner's own family app. A real professional must confirm it before the app is relied on (section 8). Hebrew in these files is `review: needs-editor`.

**Files in this set**
- `alert-word-lists-review.md` (this file): findings, sources, risks, recommendations, open questions.
- `alert-word-lists-proposed.md`: the proposed lists as tables, with tiers, subcategories, variants and the list of what was left out.
- `alert-wording-drafts.md`: drafts for the parent alert, the settings text and the tutor lines.
- `alert-test-list.md`: concrete phrases that must and must not match, and behaviour tests.

---

## 0. Headlines

1. **The question was "complete and well chosen?" Answer: no, on both counts.** Today there are 8 swear words and 15 phrases, all in one tier. They miss most of how young children really tell, and several entries will fire on harmless things (siblings, films, a place name), which teaches a parent to ignore the one alert that matters.
2. **Use three tiers, not two lists.** T1 "act" (clear statements), T2 "check context" (ambiguous or very common), T3 "note" (swearing, in a digest, never pushed). This fixes most of the false-positive problem without losing recall.
3. **Match windows, not exact runs.** Verb family plus "to me" within three words in any order, one filler word allowed, prefix `ש/ו` tolerated. This is cheap and catches "he really hits me", "that they hit me", "I really want to die".
4. **Never fuzzy-match short words.** In this repo the phonetic key of the swear `חרא` equals that of `כל` (all), `קל` (light) and `קר` (cold).
5. **Add a cool-down.** Today every answer makes a new alert (the dedupe key contains the millisecond). A child saying one swear five times gets five alerts.
6. **Treat any self-harm wording as T1 at every age**, including 3 to 4. Research says young children's death talk is poorly understood, not harmless.
7. **Be honest about the channel.** The mic opens only on a tap, in a lesson, to answer a question. The recogniser is much worse on young children than on adults. The word lists will catch a minority of what a child might say. The app must never present itself as protection (section 6).
8. **The tutor line in PLAN.md is a good design but is masculine-only, has no receipt, and I found no implementation in `app/lib`.** Fix and implement as in `alert-wording-drafts.md`.
9. **The alert can go to the very person a child may be talking about.** Fine for the owner's own family; a design risk if the app ever leaves it.
10. **Cheapest big win:** a 30 to 45 minute review with a kindergarten or school counsellor (section 8).

Numbers proposed: **16 word entries** (about 70 token forms), **48 phrase entries** (15 T1, 1 age-dependent, 31 T2, 1 T3), 5 combination rules, about 220 test cases.

---

## 1. What the code does today

Read from `D:\nitznutz-b26` (branch worktree):

- `app/lib/speech/alert_words.dart` lines 14 to 42: `inappropriateWords` (8 words: `חרא זין מזדיין מזדיינת תזדיין זונה שרמוטה מניאק`) and `disclosurePhrases` (15 phrases). Lines 45 to 72: `checkWords` normalises each recogniser hypothesis (`normalizeHebrew`: no niqqud, final letters folded, punctuation and geresh to space, Latin lower-cased), splits to tokens, and a phrase must be a **run of consecutive tokens** (`_hasRun`). A single swear token is enough. A disclosure wins over a swear. **Any** of the recogniser's hypotheses counts.
- `app/lib/play/lesson_screen.dart` 143 to 156 and `app/lib/speech/voice_answer.dart` 203: after each voice answer the hypotheses are handed on once (`onWords`) and looked at on the device.
- `app/lib/parent/alerts.dart` 258 to 274: the alert is saved with `words: keepWords ? texts.first : ''` (the **first** hypothesis, which may not be the one that matched). Severity: disclosure is the only `important`.
- `app/lib/parent/alert_scan.dart` 57 to 73: the dedupe key is `words:<profile>:<millisecond>`, so **nothing is ever merged**.
- `app/lib/strings/he.dart` 291 to 294: the four alert texts quoted in `alert-wording-drafts.md`.
- `docs/PLAN.md` 486 to 501 (Alerts), 341 (the tutor line), 803 to 809 (Alerts in v1); `docs/curriculum.md` 11.6; `docs/agents/hebrew-notes.md` group 5 (spelling checked, completeness left open as question 9).
- Recogniser: ivrit.ai Zipformer through sherpa-onnx, on the device (`docs/tech.md`). Adult accuracy is good (5.1 and 8.9 word error rate in the project's notes); for children `docs/milestones/M5.md` says the accuracy goal is **not yet met**.

### Findings

| # | Finding | Effect |
|---|---|---|
| F1 | One tier for all 15 phrases; "disclosure" is always `important`. | A sibling quarrel and a death wish look the same to the parent. |
| F2 | Coverage is narrow: no secrecy, no online or stranger, no "alone" beyond one phrase, no witnessing violence, no threat for telling, no fear of a named person, no past tense, no feminine verb forms of `מכה`, one sexual phrase pair, two self-harm phrases. | Many ways children actually tell are invisible. |
| F3 | Noisy entries: `נגעו בי` / `נוגעים בי` ("they touched me": playground and tag), `מפחידים אותי` (films), `מכה אותי` / `מרביץ לי` (siblings). | Alert fatigue on the important category. |
| F4 | Exact consecutive-run matching misses: `הוא הרביץ לי` (past), `הכו אותי`, `שמרביצים לי` (prefix), `מרביצים לי ממש חזק` is fine but `אני כל כך רוצה למות` is not, `רוצה למות` without `אני`. | False negatives, which are the costly kind. |
| F5 | `לא רוצה לחיות` also matches `לא רוצה לחיות בעיר`. | A false important alert about a move. |
| F6 | Two children share one device. "He hit me" between siblings is daily. | The commonest harmless trigger is in the important tier. |
| F7 | Any hypothesis counts for a single swear token; recorded `words` is the first hypothesis. | Mis-hearings raise swear alerts; the parent can see a text that does not contain the trigger. |
| F8 | No cool-down or merging. | One outburst = many alerts. |
| F9 | `checkWords` is exact (good). But `phoneticKey` in the same package collapses `חרא`, `כל`, `קל`, `קר` to `kl`. | If anyone later adds "tolerant" matching with `similarity`, `חרא` will fire on "all". |
| F10 | `זין` is also the **name of the letter ז**; Band C has Hebrew letter values (ז = 7), literacy later has letter names. `כלי זיין` means weapons. | A systematic false swear alert in a letter lesson. |
| F11 | No English swearing, no `כוס אמק`, no `בן זונה`, no slurs, no exposure words (`סקס`, `פורנו`). | Gaps a parent would care about. |
| F12 | Age-blind. A 3 year old repeating a swear and a 7 year old get the same alert; `אני לבד בבית` is the same at 4 and at 8. | Noise at 3 to 4, a missed urgency at 4 for "alone". |
| F13 | The tutor's caring line is in PLAN and `curriculum.md` only; I found no use in `app/lib`. The text uses `אתה` only. | The promised behaviour may not exist; a girl hears the wrong gender. |
| F14 | The lists are Dart constants without version or reviewer. | A counsellor's correction needs an app release. |
| F15 | The mic opens only on a tap to answer; disclosures made elsewhere are never heard. | The detector has big holes by design (also a privacy strength). |
| F16 | The alert goes to the parent account. | If the person described is a parent, the alert reaches them. |

---

## 2. How young children actually disclose (research)

I could not find one paper that settles the Hebrew-speaking 3 to 8 year old case. What follows is the well-supported general picture, with the source and what I took from it. Where I only saw a search-result summary, it says so.

### 2.1 What the evidence says
- **Disclosure is a process, not one event.** A child often reveals a part ("tests the waters"), watches the adult's reaction, and may take it back if the adult is upset. Telling in small parts does not mean lying. [S2 UPMC; S1 Alaggia et al.]
- **Young children are often not heard, or tell indirectly.** In the review of 2000 to 2016 studies, children under 7 were at higher risk of delayed disclosure; younger children were more often discovered by accident or through a witness than by purposeful telling; indirect and behavioural signals are common. When children were questioned, about half of 3 to 6 year olds disclosed (against two thirds at 7 to 10). [S1, citing Kogan 2004, Collings 2005, Hershkowitz 2005]
- **Role play, drawing and stories** are common routes for preschoolers ("accidental disclosure"). [S2] A "friend" or "what if" framing is described in practice guidance, but the one source I found for it is a low-authority slide set; treat as plausible, not established. [search result, unverified]
- **Who they tell first.** In one sample of young children about 47 percent first told siblings or friends, about 43 percent a parent. [S1, citing Hershkowitz 2007] An Israeli study of 30 alleged victims, including pre-schoolers, found that over half delayed telling from a week to two years and that children told less readily when they expected a negative reaction. [S5, abstract-level, from a search summary]
- **Why they stay silent:** fear, shame, self-blame, threats, fear of not being believed, fear of harming the family, not wanting to burden parents. [S1; S6 Ministry of Education leaflet] **Young children often do not realise that what happened was harmful.** [S6]
- **87 percent of children who are sexually abused in Israel are abused by someone they know**, not a stranger. [S6, as printed in the Ministry of Education leaflet; I could not trace its original source]
- **What helps telling:** being asked, a calm and believing adult, a supportive parent-child relationship, previous talk about body safety. [S1, S6, S7]

### 2.2 What this means for word lists
1. The words children use are **indirect and partial**: "he hits me", "they hurt me", "I'm scared of X", "I'm alone", "it's a secret". A list built on adult legal vocabulary will miss them.
2. Many tell with **no subject or an unnamed subject** ("they", "someone") or about **a named adult** ("daddy", "the teacher"). Both shapes need entries.
3. **Secrecy is a signal in itself** (a child told "don't tell", or threatened if they tell). It is a separate subcategory in the proposal.
4. A single sentence will rarely be a full disclosure. The proposal therefore lets two softer signals within 7 days add up (rule C-1).
5. **Do not interrogate.** The parent and the tutor should listen and not ask leading questions; Haruv warns that questioning at home can damage a later professional interview. [S7, S8]

### 2.3 Normal versus concerning

| Topic | Developmentally common (ages 3 to 8) | More concerning | Source or basis |
|---|---|---|---|
| Hitting, kicking, pushing | Peer and sibling aggression is common in gan and drops with age | Frequent, severe, or about a named adult, or with marks | Ministry of Education psychology page (via a search summary); general knowledge |
| Swearing | Common from about 3 to 4; learnt from home, street, screens; often tests reactions | A child using vulgar sexual language that is not age-typical, or attacking others with it | Raising Children Network (via a search summary); S6 for "age-inappropriate sexual behaviour" |
| Body curiosity, "doctor play", showing private parts to a same-age friend | Common at 3 to 6 | Sexual knowledge or behaviour that does not fit the age; an older child or an adult involved; coercion or secrecy | S6 and S10 ("age-inappropriate sexual behaviour"); general developmental knowledge, not individually cited |
| "I want to die", "I wish I were dead" | Young children's understanding of death develops with age; in a tantrum it may be an expression of anger or a misunderstanding of finality | Repeated, calm, with a method, or with themes of violence and death in play | S3 Hennefield et al. 2022 (3 to 6.9 year olds with depression: children with active suicidal thoughts told more stories with violence, homicide and suicide); sources say what the words mean is unclear. Take it seriously. |
| Fear of a person or place | Fears of the dark, dogs, monsters are normal | Fear of a specific person, of going home, or of a setting | S11 (signs: recoil from a parent or carer); general knowledge |
| Being alone | Short supervised moments | A very young child alone; hunger; a carer unable to care | S9 Knesset summary (see 3.2) |
| Secrets | Surprises (birthday gifts) are fun | "Don't tell" about touching, hurting or fear | Body-safety guidance (search summary); S7 |

**The line I am least able to draw is the "I want to die" one.** A young child may mean nothing like an adult does, and may still be at risk; the research says clinicians do not fully know. The proposal therefore never tries to separate them: it fires at T1 and leaves the interpretation to the parent and a professional. The only exceptions are plain idioms (`מת מצחוק`, `בא לי למות מבושה`).

### 2.4 Children repeating swear words
Swearing at 3 to 6 is common and typically learned from home, street or screens; calm, low-drama responses work best; telling a child off can make a word more attractive. [Raising Children Network, via a search summary] A child who has just been given a microphone will also test it. So: **T3, a digest, no push**; at ages 3 to 4 not even a digest by default (proposal section 6). The parent text says exactly this.

---

## 3. The Israeli context

### 3.1 Duty to report (חובת דיווח)
- The duty is in the Penal Law, **section 368ד**. Per a Knesset Research and Information Centre summary (9 Feb 2021): *any person*, and especially a professional (doctor, educator, psychologist, nursery staff, or the person responsible for the minor), who **suspects** an offence against a minor by the person responsible for him must report **as soon as possible to a statutory social worker (youth-law, `פקיד סעד`) or to the police**. Failing to do so is a criminal offence with a penalty of **3 months (anyone) up to 6 months (professionals and those responsible)**. The offences covered are neglect or abandonment, assault or abuse, human trafficking, sexual offences and prostitution, and endangering life or health. There is a specific duty for sexual offences by a family member under 18, and for staff of a nursery or institution. [S9]
- Haruv: the duty applies for harm by the person responsible (parents, teachers, instructors), harm inside the family including between siblings, and harm between pupils in an institution when it is sexual or physical with serious injury. The report goes to the police or to the welfare services; "before everything it is a moral duty"; the purpose is to stop the harm and get treatment. A parent may consult a child-protection centre (`בית לין`, eight centres), **also anonymously**, before deciding. [S7, S8]
- The Ministry of Health speaks of a "reasonable ground" to suspect. [S10]
- **I could not read the statute itself.** The penalty is also mentioned as "up to 3 months" on a Kol Zchut page (not opened, via a search summary) and a 2023 bill that proposes raising "six months" to "one year" (status unknown). **A lawyer should confirm the current text.**
- **Leaving a child alone.** The same Knesset summary says the Penal Law forbids leaving a child up to age six without supervision, and neglecting a child's basic needs up to 16. [S9, section 3.1.4] This is why W-25 is T1 for ages 3 to 5. The penalty figures in a search summary were not confirmed.
- **What the duty means for the app.** The duty sits on people, not on software. The app is **not a reporting channel**, and the parent message says so. The parent who reads an alert may, depending on what they learn, have a duty; the message names the right places (118, a youth-law social worker, the police) and does not give legal advice.

### 3.2 Helplines (verified status)

| Number | What it is | Status | Evidence |
|---|---|---|---|
| **118** | Ministry of Welfare and Social Security information and first-help line. Free. 24 hours. Hebrew, Arabic, Amharic, Russian. Also a WhatsApp or text message to **050-2270118**. For emergencies, sexual abuse, family violence and the like; can advise on reporting. | **Verified on two Ministry pages** | S12, S10, S11 |
| **1201 (ער"ן)** | Anonymous emotional first aid by phone, chat, email, SMS; open to all ages; a separate channel for young people. | **Number and service verified on ERAN's own site.** 24-hour operation was only seen in a secondary summary and ERAN's page did not state hours. | S13 |
| **105** | National Headquarters for Protecting Children Online. Reports of harm to minors online. Children, parents, professionals and the public may call; reported 24/7 except Yom Kippur (then 100); WhatsApp 052-1210105. | **Listed on three Ministry pages by name (S6, S10, S12; S10 also gives the number). Hours and WhatsApp come from search-engine summaries of the gov.il page, which blocked my direct fetch.** Re-check on gov.il before printing hours. | S10, S12, S14 |
| **100** | Police. Immediate danger to a child or family. | Listed on a Ministry of Health page. | S11 |
| **101** | Magen David Adom (ambulance). | **Not verified in my sources**; widely known; check before printing. | none |
| **1202 / 1203** | National sexual-assault helplines (women / men), run by the sexual-assault crisis centres' association; adult-oriented. One health page also lists 1202 under child sexual abuse. | Verified as existing, audience unclear. Not printed in the parent message. | S10, S12 |
| `*6552`, extension 5 | Ministry of Education emotional support line for pupils, parents and staff; Sunday to Thursday 8:00 to 20:00, Friday 8:00 to 14:00. | Verified on the Ministry leaflet (S6). Optional. | S6 |
| `בית לין` child-protection centres | Eight centres: social worker, child interviewer, doctor under one roof; consultation possible without giving a name. | Service verified (S6, S7, S8). A star-number (`9519*`) appears on one page only; **not printed**. | S6 |
| 106 | Municipal call centre. One Health page lists it for "children in distress", but municipal 106 lines are general and routing varies. | **Not printed.** | S11 vs search results |
| 1-800-220-000 (family violence), ELI 1-800-223-966 | | Not verified; not printed. | none |

### 3.3 What a parent should do first (Israeli guidance, merged)
1. Stay calm. Listen fully without showing panic or judgement. [S6]
2. Tell the child clearly: you believe them, it is not their fault, you are glad they told. [S6, S7]
3. **Do not investigate or interrogate yourself** and do not agree on a version of events; you can damage a later professional child interview. [S7]
4. Do not promise to keep it secret. [general child-protection practice; the Ministry texts say to involve professionals]
5. **Consult early**: 118, a `בית לין` centre (anonymous consultation is possible), the school counsellor. [S6, S7, S8, S10]
6. For a suspected sexual injury within the last days, go quickly to a hospital acute centre (open 24/7 for children and adults). [S6, S7]
7. In immediate danger: 100 (police) or 101.
8. Do not confront the person the child named before you have advised yourself.

### 3.4 What the app may and may not claim
**May:** that it listens for some words on the phone only when the child taps the mic, that it can miss things and can be wrong, that it keeps the words for a limited time if the parent allows it, and where to get help.
**May not:** that it detects abuse, protects the child, reports to anyone, diagnoses, or that silence means safety. It should never present a category as a conclusion ("abuse", "bullying") but only as "something that may be worth a conversation".

---

## 4. Colloquial and child Hebrew, and the recogniser

Mostly general knowledge of Hebrew; I could find no source on how 3 to 8 year olds phrase disclosures in Hebrew. **The hebrew-text-editor and a gan counsellor must correct this section.**

### 4.1 How children phrase it
- **Plural "they" and "someone":** `מרביצים לי`, `מכים אותי`, `מישהו נגע לי`, `אנשים מפחידים אותי`. Plural impersonal is frequent and safe to treat as T1 for hitting.
- **Named adults, with the possessive:** `אבא שלי`, `אמא שלי`, `הגננת`, `המורה`, `הדוד`, `החבר של אמא`.
- **Verbs of hitting:** `מכה`, `מרביץ` (very colloquial; also used for kicking a ball), `נותן מכות`, `אכלתי מכות`, `חטפתי`; `סוטר` (slap); `בועט`; `דוחף`; `צובט`; `נושך`.
- **Touch and the body:** children use child words (`פיפי`, `בולבול`, `ציצי`, `טוסיק`) and the school phrase "private places" (`מקומות פרטיים`). I could not verify the word list; it is flagged for the editor.
- **Feelings instead of facts:** `אני פוחד`, `אני מפחדת ממנו`, `לא רוצה ללכת`, `כואב לי`.
- **Alone:** `אני לבד בבית`, `אין אף אחד בבית`, `השאירו אותי לבד`.
- **Secrets:** `זה סוד`, `אסור לי לספר`, `הוא אמר שלא לספר`, `אם אספר הוא יכה אותי`.
- **Strangers and online:** `איש בטלפון`, `מישהו במשחק`, `ביקש ממני תמונה`.
- **Death and disappearing:** `אני רוצה למות`, `לא רוצה לחיות`, `הלוואי שלא נולדתי`, `אני רוצה להיעלם`.
- **Idioms to avoid:** `אמא תהרוג אותי`, `אני מת מצחוק`, `מתה על`, `אני מת לאכול`, `בא לי למות מבושה`.
- **Gender:** the child's own gender shows in `פוחד / פוחדת`, `מפחד / מפחדת`; other people's in `מרביץ / מרביצה`, `הכה / הכתה`. Lists must hold both.
- **Child pronunciation** (general knowledge, to confirm): `ר` may sound as `י/ל`, `ש` as `ס` or `ת`, final consonants drop, plural endings blur. The recogniser then writes a different word.

### 4.2 What the recogniser is likely to do
- Adult-trained models are worse on young children. Published figures vary widely by data and model: about 40 percent word error rate for preschool classroom speech in one study, 63.5 percent for a child subset in another, up to 84 percent for off-the-shelf systems in a third (via search summaries; none was for Hebrew). The project's own adult figure is 5.1 and 8.9 percent and the children's accuracy goal is **not yet met** (M5).
- *Illustrative arithmetic, not a measurement:* if each word is right 60 percent of the time and the errors are independent, a three-word phrase is fully right about 22 percent of the time. This is why window matching, an N-best list and short entries matter, and why the app must not be sold as protection.
- Likely errors (general knowledge): dropping short function words (`לי`, `אני`), confusing `אותי` / `אותו` / `אותה`, turning a rare word into a common one, odd spellings of names and loan words, and the geresh. The normaliser turns a geresh into a space, so a loan word with one splits into two tokens.
- **Spelling habits to cover:** full spelling (ktiv male) is expected from this model; the proposal collapses a doubled yod or vav on both sides, tolerates the one-letter prefixes `ש ו כש`, and lists feminine and masculine forms.
- **Hotwords.** The sherpa-onnx hotword feature (still to be verified for this model, `tech.md` open question 3) could bias the recogniser toward the T1 phrases. Worth a test.

---

## 5. Risk analysis

### 5.1 Costs
- **False negative:** a child says something and no one is told. This is the severe cost. It cannot be eliminated (section 4.2). It must be reduced where cheap: windows, N-best, prefix and gender families, SELF at T1.
- **False positive:** a parent is alerted to something harmless. Each costs a little. A stream of them teaches the parent to ignore the alert, which turns later true alerts into false negatives. This is why T1 must stay small and clear and why the sibling-quarrel and film phrases are T2.
- **A false positive of the "wrong accuser" kind** (the parent reads a harmless sentence as an accusation against someone). The parent text avoids naming categories as conclusions.

### 5.2 By age
- **Ages 3 to 4:** speech is least recognised; swearing is mostly repetition; "alone at home" is urgent; undressing words are care. Rules: swears counted only, W-14 off, W-25 T1, W-37 at T3.
- **Ages 5 to 6:** the best range for plain disclosure sentences; peer aggression and "doctor play" peak; swear digest on.
- **Ages 7 to 8:** more indirect and ironic language, online groups, worthlessness statements, more recognised speech. W-36 and W-42 start here.

### 5.3 Where it will fire wrongly (known)
Sibling quarrels (W-03, W-08), film and game monsters (W-21, W-10 in doll play), tag games (not matched on purpose), `זין` in a letter lesson (R7), hide-and-seek (W-07), parent care (W-14), idioms (guards), surprises (guard).

### 5.4 Where it will miss (known)
Everything outside the mic window; any sentence the recogniser garbles (most for ages 3 to 4); disclosures that are acted out or drawn; children who never say it; and anything my lists do not contain (children say surprising things). **A silent app is not a safe child.**

---

## 6. Design recommendations

| # | Recommendation | Why |
|---|---|---|
| R1 | **Three tiers.** T1 → `disclosure`, important, push without content (as in PLAN). T2 → a new "check" alert, attention, no push. T3 → a daily or weekly digest, info, never pushed. `checkWords` returns tier, subcategory, matched hypothesis and list version. | F1, F3 |
| R2 | **Matching model.** Verb family plus "to me" within a window of three tokens, any order; one filler token inside fixed phrases (two in the SELF block); one-letter prefix tolerance on verbs (`ש ו כש`) and body words (`ב ל ה ש מ כ`); both genders and plural forms listed. | F4 |
| R3 | **Guards.** Negation within two tokens before the verb cancels (`לא מרביצים לי`); idiom list for death words; surprise list for secrecy; a place after `לחיות` cancels; a child as the hitter (`אני מרביץ`) does not match. | F5, section 2.3 |
| R4 | **N-best policy.** T1 may fire on any hypothesis. T2 and T3 need the top hypothesis or at least two hypotheses. Store the **matching** hypothesis, not `texts.first`. | F7 |
| R5 | **Cool-down and dedupe.** Per child and per subcategory, merge hits within 10 minutes into one alert with a count; a new alert only after 30 quiet minutes or a higher tier. T3 goes to a digest with a count. | F8 |
| R6 | **Age rules** as in the proposal's section 6 table (swears, `לבד בבית`, undressing, self-hitting, worthlessness, online groups). | F12 |
| R7 | **Lesson-aware suppression.** Remove from the text every token that is an accepted answer of the current activity before matching swears (letter name ז = `זין`; Band C letter values). | F10 |
| R8 | **No fuzzy matching below six letters; none at all for the lists.** Document that `phoneticKey` and `similarity` must never be used for alerts. | F9 |
| R9 | **Lists as a signed, versioned data pack** with `reviewed_by` and `reviewed_on`, loaded by the matcher; the list version stored on each alert. The security-engineer reviews the pack path. | F14 |
| R10 | **Tutor.** Implement the T1 and mild T2 lines from `alert-wording-drafts.md`, pre-recorded and chosen on the device; one line, no questions, never promise secrecy, offer a calm pause. Keep the PLAN idea, fix the text. | F13 |
| R11 | **Parent message** per tier, with the recogniser-may-be-wrong sentence, the first steps, 118, 1201, 105, 100 and 101, and the duty-to-report sentence. | section 3 |
| R12 | **What the app claims** (settings text) as in the drafts, and a short parent card on secrets and private places. | 3.4 |
| R13 | **Parent feedback.** A "this was nothing" button on T2 alerts only, stored locally as a count, to measure the false-positive rate without storing child text. | tuning |
| R14 | **Recipients.** Alerts go to the parent account(s) the owner chooses; add a note to the T1 text about not confronting a named person before advice. For any future use outside this family, consider a second adult recipient. | F16 |
| R15 | **Emergency path.** For SELF and NEGL-emergency (W-28) the parent text names 101 and says to go to the child now. The app does not try to call anyone. | 5.1 |
| R16 | **Evaluation.** Test with sentences read aloud by adults imitating children now; with real children's recordings only if the owner decides to relax the "no child audio stored" rule for a consented test (Q7). Measure recall on the T1 list and the false-alarm rate on a day of ordinary play. | section 4.2 |

---

## 7. Sources, with what I took and how well I could check it

"Fetched" means I read the page or document text. "Summary only" means I saw it only through a search-engine summary and have not verified the detail. I did not find or invent any other sources.

| ID | Source | What I took | Status |
|---|---|---|---|
| S1 | Alaggia, Collin-Vézina, Lateef (2019), *Facilitators and Barriers to Child Sexual Abuse (CSA) Disclosures: A Research Update (2000 to 2016)*, Trauma, Violence & Abuse 20(2). https://pmc.ncbi.nlm.nih.gov/articles/PMC6429637 | Disclosure as a process; under-7 delayed disclosure; younger children found by accident; disclosure rates by age when asked; first recipients; barriers and facilitators | Fetched (first 100,000 of 158,000 characters) |
| S2 | UPMC Children's Advocacy Center, "Disclosure". https://www.upmc.com/services/south-central-pa/pediatrics/resources/crc/disclosure | Role play and drawing; testing the waters; retraction; partial telling is not lying; what the adult should say | Fetched |
| S3 | Hennefield et al. (2022), *Young Children with Suicidal Thoughts and Behaviors More Likely to Resolve Conflicts with Violence, Homicide, or Suicide: A Study of Internal Working Models Using Narratives*. https://bpb-us-e2.wpmucdn.com/sites.wustl.edu/dist/8/3495/files/2022/06/Hennefield-et-al.-2022.pdf | 228 depressed 3 to 6.9 year olds; suicidal ideation present from the preschool years; narrative themes; the sample is a clinical one, not the general population | Fetched (text extracted from the PDF) |
| S4 | McElvaney, *Disclosure of child sexual abuse: delays, non-disclosure and partial disclosure*, Child Abuse Review. https://www.nationalcac.org/wp-content/uploads/2022/08/Disclosure-of-child-sexual-abuse-Delays-non-disclosures-and-partial-disclosures..pdf | Consensus that most people abused in childhood do not tell until adulthood; partial disclosure | Summary only |
| S5 | Israeli study of 30 alleged child sexual-abuse victims and their parents (University of Haifa record; PubMed 17316793; authors and journal as I recall: Hershkowitz, Lanes, Lamb, *Child Abuse & Neglect* 2007). https://pubmed.ncbi.nlm.nih.gov/17316793/ | Over half delayed telling from a week to two years; expected negative reaction delays telling; sample included preschool children | **Summary only; authors and year to be verified** |
| S6 | Ministry of Education, Psychological Counselling Service, parents' leaflet "אם לא נדבר, איך נדע?". https://meyda.education.gov.il/files/shefi/miniutumeniatpgia/Shavua_Maharechet_2023/Alon_Horim.pdf | Young children often do not realise they were harmed; reasons for silence; what a child needs (listen, believe, not guilty, no interrogation); 87 percent known to the child; `*6552`; `בית לין`; hospital acute centres 24/7; 1202 / 1203; 105 | Fetched |
| S7 | Ynet parents' guide (Aug 2022) built on the Haruv Institute kit "טוב שסיפרת": "כל מה שעושים אחרי גילוי פגיעה מינית בילדים | מדריך". https://www.ynet.co.il/parents/article/hj0cyqem5 (read from the copy at https://haruv.org.il/wp-content/uploads/2024/07/כל-מה-שעושים-אחרי-גילוי-פגיעה-מינית-בילדים-_-מדריך.pdf) | Reaction (believe, not your fault, thank them); who must report and to whom; consult `בית לין`; do not question the child yourself | Fetched |
| S8 | Haruv Institute, "טוב שסיפרת" chapter 5, reporting duty summary. https://haruv.org.il/wp-content/uploads/2023/06/סיכום-פרק-5-חובת-הדיווח.pdf | Cases covered; police or welfare; youth-law social worker in each local authority; anonymous consultation at `בית לין`; acute rooms within 72 hours | Fetched |
| S9 | Knesset Research and Information Centre (9 Feb 2021), "מרכזים לטיפול בקטינים נפגעי אלימות מצד בגירים". https://fs.knesset.gov.il/globaldocs/MMM/738cbe9e-cbd0-ea11-8107-00155d0aee38/2_738cbe9e-cbd0-ea11-8107-00155d0aee38_11_17708.pdf | Duty to report (anyone, especially professionals) to a youth-law social worker or the police; penalty 3 to 6 months; offences covered; ban on leaving a child up to age 6 unsupervised | Fetched (text extracted) |
| S10 | Ministry of Health, "פגיעה מינית בילדות". https://me.health.gov.il/mental-health/information-and-updates/managing-sexual-abuse/childhood-sexual-abuse/ | Children freeze and stay silent; signs (including age-inappropriate sexual behaviour); how to react; reasonable ground to report; 118 24/7, 1201, 105, 1202, 1203 | Fetched |
| S11 | Ministry of Health, "אלימות במשפחה: זיהוי וקבלת עזרה". https://me.health.gov.il/parenting/learn-more/family-parental-welfare/warning-signs-of-domestic-violence/ | Signs a child is exposed to family violence (recoil from a carer, games that repeat violence); 100, 118 and its WhatsApp number, 106, `בית לין`, ELI, ERAN, Aluma | Fetched |
| S12 | Ministry of Education SHEFI, "גורמי סיוע ופנייה לעזרה". https://shefi.education.gov.il/top-topics/sexual-abuse-in-children/appeal-for-help/ | 118 (free; Hebrew, Arabic, Amharic, Russian; emergencies, sexual abuse, family violence), 1201, 1202, 1203, 105, `*6552` extension 5 | Fetched |
| S13 | ERAN, https://www.eran.org.il/ | Phone 1201; anonymous emotional first aid by phone and online chat; open to all ages; a young-people channel | Fetched; hours not on the page |
| S14 | gov.il, "מוקד 105" (https://www.gov.il/he/departments/units/105_call_center), police unit 105 page, and the Child Online Protection Bureau (launched Nov 2018) | Who may call; hours 24/7 except Yom Kippur; WhatsApp 052-1210105 | **Summary only** (the pages returned 403 to my fetch); `105.org.il` says it is unofficial but links to the same WhatsApp number |
| S15 | Raising Children Network (Australia), "Swearing: why children do it". https://raisingchildren.net.au/preschoolers/behaviour/common-concerns/swearing-preschoolers | Swearing at 3 to 6 is common; calm, low-drama response | **Summary only** (page returned 403) |
| S16 | Child speech recognition literature (e.g. https://arxiv.org/abs/2203.12886 and related) | Word error rates for young children are far above adults' and vary widely | **Summary only; none was Hebrew** |
| S17 | Project documents: `docs/tech.md`, `docs/milestones/M5.md`, `docs/PLAN.md`, `docs/curriculum.md`, `docs/agents/hebrew-notes.md` | The recogniser, its adult accuracy, the "not yet met" children's accuracy, Alerts, the tutor line | Read |

Not verified at all: the Hebrew child words for private parts; the exact current text and penalty of section 368ד; 101; the hours of 105 and ERAN from their own pages; the origin of the 87 percent figure; the ELI, Aluma and `בית לין` star numbers; any claim about the share of children who "tell about a friend" (only a low-authority slide set).

---

## 8. Limits, and what a human must still confirm

### 8.1 Limits of this work
- I am an AI. I have not met your children, I am not a clinician, and I cannot assess risk. The tiers are my judgement from the sources above.
- The false-positive and false-negative judgements are estimates. Nothing here was measured on real recordings.
- The Hebrew is unreviewed and the child vocabulary is unverified.
- The legal summary comes from a Knesset research note and guidance pages, not from the statute.

### 8.2 What a professional should confirm before the app is relied on
**A child psychologist or a gan or school counsellor**
1. That the T1 list (the 15 base rows) matches what children that age actually say, and that no common form is missing.
2. The child words for private parts and for hitting in current use in gan.
3. Whether peer touch and "doctor play" rows are tiered right (W-12, W-14).
4. The treatment of "I want to die" at ages 3 to 5, and the wording for the parent.
5. The tutor lines TL-1 to TL-6: tone, whether to name a trusted adult, whether the calm pause is right.

**A youth-law social worker (עו"ס לחוק הנוער), `בית לין` or 118**
6. The parent message: whether the steps, the order and the legal sentence are right and safe.
7. Whether to print 105 and 1201 and which other numbers.

**A lawyer**
8. The reporting-duty sentence, and whether keeping a child's words for 30 days has legal consequences either way.

**The hebrew-text-editor**
9. All Hebrew in `alert-wording-drafts.md` and the lists (list at the end of the drafts file).

### 8.3 What the owner can do cheaply
- **A 30 to 45 minute conversation with the kindergarten counsellor, the school counsellor, or the municipal educational psychology service (שפ"ח).** Bring three pages: the 15 T1 rows, the parent T1 message, the tutor lines. Ask: "What have you heard children say? What is missing? What would worry you?" and "Is this message safe to send to a worried parent?" Pay them if they ask.
- **Call 118 once**, say you are building a family app and ask what they would want a parent to know and do first. They are an official service; I cannot say whether they will answer questions about an app, so ask politely.
- **Ask the Haruv Institute** (the source of the "טוב שסיפרת" kit) whether they will look at the parent text. I cannot say whether they take such requests.
- **Do a dry run with yourself and your partner:** read each T1 row aloud as a child would say it, with the voice recogniser, and see which ones the phone writes correctly (the closest thing to a recall test that costs nothing and stores no child audio).
- **Read the two Ministry leaflets (S6, S10) once.** They are short, official and written for parents.

---

## 9. Open questions for the owner

| # | Question | My lean |
|---|---|---|
| Q1 | Who receives T1 and T2 alerts: only you, both parents, or one parent plus a trusted adult? | Both parents; the T1 text already warns against confronting before advice. |
| Q2 | Should a T2 alert push to the phone (no content), or only show in the app? | In the app only; C-1 turns two into a T1 push. |
| Q3 | Keep the child's words for 30 days (PLAN default on)? Would you want them kept longer if an alert turned out to matter? Ask a lawyer about evidence versus privacy. | Keep as PLAN says; ask the lawyer. |
| Q4 | Swear words: keep as a digest, or switch off for ages 3 to 4 (the proposal), or drop the swear alert entirely? | Digest from 5; off for 3 to 4. |
| Q5 | After a T1 tutor line, should the lesson stop and show a calm pause screen, or return to play? | Pause with a child's choice (design-director). |
| Q6 | Which counsellor or social worker can you ask for the 30 to 45 minute review? | Gan counsellor first. |
| Q7 | May a **consented** test with recordings of your own children's real speech be made, in spite of "no child audio stored"? If not, adult read-aloud tests only. | Adult read-aloud now; decide on a one-off consented test later. |
| Q8 | Do you want an alert when a child says they hit someone (`אני מרביץ לאחי`)? It is a different question from disclosure. | No, not as part of this feature. |
| Q9 | Should slurs (`ערבוש`, `כושי`, `מפגר`) be a swear class? Sensitive and political; your decision. | Keep S-13 and S-14 at T3 and let the parent decide. |
| Q10 | Move the lists to a signed data pack so a counsellor's fix needs no release? | Yes. |
| Q11 | Which numbers to print: 118, 1201, 105, 100, 101 as drafted, or fewer? | As drafted, after checking 101 and the hours of 105. |
| Q12 | Honesty with the child: today the child is never told that words can reach the parent. The tutor line avoids promising secrecy; do you want a simple age-appropriate sentence in the first-run explanation ("I'm only a helper; grown-ups can see how you're doing")? | Yes, simple and honest. |
| Q13 | If the person a child describes could be a parent, the alert reaches that parent. Is that acceptable for this private family app? | Yes for now; revisit if the app is ever shared. |
| Q14 | Do you want the app to say "alone at home" is T1 up to age 5 (as the law treats leaving a child up to 6)? | Yes. |
| Q15 | The tutor line is not in the code that I could find. Should it be built in this milestone or the next? | Next, with the voice step; voicing is your paid step, not Claude's. |
