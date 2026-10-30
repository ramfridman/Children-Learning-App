# Hebrew validation of the alert strings in the app (he.dart)

Written by the hebrew-text-editor on 2026-10-30. I read `app/lib/strings/he.dart` in `D:\nitznutz-alerts` (read-only)
and compared the app-developer's word-alert strings with `hebrew-validation.md` section 5.1, the `final-draft`
approved by the owner's answers of 2026-10-29. This file is the only change. Nothing was voiced.

## 1. Result of the comparison

44 keys were compared: 42 from section 5.1 and 2 new ones. The comparison was made by a script that reads every
`Str(...)` the way Dart does, joining the parts and decoding the `\u2066` / `\u2069` escapes.

| Check | Result |
|---|---|
| **Exact text**: all 42 keys taken from 5.1 (`alertHeard`, `alertWordsNotKept`, `alertActTitle`, `alertActUnsure`, `alertActNow`, `alertActStep1` to `5`, `alertActHelp`, `alertHelp118`, `alertHelp1201`, `alertActDuty`, `alertActNoReport`, `alertAddPhys`, `alertAddSex`, `alertAddSelf`, `alertAddNegl`, `alertAddEmerg`, `alertAddOnline`, `alertAddSecret`, `alertCheckTitle`, `alertCheckMaybe`, `alertCheckAsk`, `alertCheckIf`, `alertRepeatTitle`, `alertRepeatHeard`, `alertRepeatNext`, `alertNoteTitle`, `alertNoteMany`, `alertNoteOnce`, `alertNoteCalm`, `alertNoteHidden`, `alertExposeTitle`, `alertExposeBody`, `alertsHonest`, `alertCardTitle`, `alertCard1` to `4`) | **Identical**, letter for letter. The one difference is the isolates below. `{words}` is named `{w}` in the app, which is fine. |
| **No nikud** (adult text) | None of the 44 has nikud, and none is marked `nikud: true`. |
| **Numbers isolated left to right** | The phone number `050-2270118` is wrapped in U+2066 … U+2069. The developer also wrapped each short number (`118`, `1201`, `105`) wherever it appears, in 8 strings. Every pair is balanced (the same count of U+2066 and U+2069). **Accepted.** It does no harm, and it keeps the paragraph right to left when a string starts with a number (`alertHelp118`, `alertHelp1201`): the first-strong rule skips what is inside an isolate. |
| **Only the three numbers** | Only 118 (with its WhatsApp number), 1201 and 105 appear. No 100 or 101, and no hours. |
| **Geresh and gershayim** | `ער״ן` uses U+05F4 and `צ׳אט` uses U+05F3; there is no ASCII `"` inside an acronym. Quotations use ASCII `"`. |
| **`{child}` after a prefix letter** | None. Every `{child}` follows a space: `של {child}`, `עם {child}`, `על {child}`, `אל {child}`, `אם {child}`. |

**Verdict:** the strings are correct as implemented. They stay `review: needs-editor` until the owner approves them in the
app.

### Outside this task, but in the same alert block

Two older alert strings in this worktree still have the text that `docs/review/hebrew-master.csv` corrected on
2026-10-28 (the corrections are `text-ready`, not yet brought into `he.dart`):
- `alertsNever`: `מוכיחה אותם` (it can read as "proves them") → `נוזפת בהם`.
- `alertRibbonTitle`: `שהובטחה עליו הבטחה` → `שיש עליו הבטחה`.

These are for the app-developer when the master-table corrections are brought in (hebrew-notes.md §4).

## 2. The two new strings

| Key | Text | Check | Status |
|---|---|---|---|
| `alertChildFallback` | `הילדים` | I read it in every template that has `{child}`; all stay grammatical. Examples: `במשחק של הילדים נשמעו המילים`, `ולשוחח עם הילדים בלי ללחוץ`, `אם הילדים לבד עכשיו`, `לאדם שנמצא עם הילדים`, `פנה אל הילדים`, `בהתנהגות של הילדים השתנה`, `מה עובר על הילדים`, and in `alertAbout`, `הילדים: נשמע משהו…`. It has the article, so it must never follow a prefix letter (the rule R-1 already guarantees this). Neutral, no gender. | ok, needs-editor |
| `alertRepeatHeardNoWords` | `בשבוע האחרון נשמעו כמה פעמים דברים דומים.` | The sentence of `alertRepeatHeard` without the quoted words. Correct, and it reads well before `alertRepeatNext` (`כל אחד מהם לבד…`). | ok, needs-editor |

## 3. Drafts for the three texts the developer asked for (`review: needs-editor`)

All three are adult texts: no nikud, `{child}` never after a prefix letter, no diagnosis. They say "heard", not "said",
and they do not present the app as protection. Where a count appears, there are two forms, as in `alertNoteMany` /
`alertNoteOnce`.

### 3.1 C-5 (the child said it happens often), one sentence added under a T1 or T2 text

| Proposed key | Text |
|---|---|
| `alertOften` | `נשמע גם שזה אולי קורה הרבה. כדאי לספר על כך כשמתייעצים.` |

- **Why it is worded like this:**
  - It does not quote the intensity word (`כל יום`, `כל הזמן`), so it adds no child words when the parent turned "keep the words" off.
  - `אולי` keeps it hedged, because the recogniser may be wrong.
  - It points to the help steps that are already shown, so no new advice is added.
- **Question for the owner:** show this line even when the words are not kept? I think yes, because it says no more than the category does, but it is a privacy choice. The security-engineer may want to check it.

### 3.2 W-47 (the child asks the helper to keep a secret), T3, in the digest

| Proposed key | Text |
|---|---|
| `alertSecretAskTitle` | `בקשה לשמור סוד` |
| `alertSecretAskMany` | `השבוע נשמעה במשחק של {child} בקשה לא לספר משהו, {n} פעמים.` |
| `alertSecretAskOnce` | `השבוע נשמעה במשחק של {child} בקשה לא לספר משהו, פעם אחת.` |
| `alertSecretAskCalm` | `לרוב זה משהו קטן, כמו כוס שנשברה. אפשר להזכיר בנחת שהפתעות שומרים בסוד, ודבר שמפחיד או כואב תמיד מספרים. ייתכן גם שהאפליקציה שמעה לא נכון.` |

- **Why it is worded like this:**
  - It names the request, not a suspicion.
  - "a small thing, like a broken cup" is the psychologist's own example of the usual case.
  - The advice repeats the parent card (`alertCard1`), so the parent hears one consistent message.
- **What is left out:** no line tells the parent what the helper answered (TL-5). That would describe the child's conversation in more detail than a T3 digest should. If the owner wants it: `העוזר במשחק ענה שסוד שמפחיד או כואב לא שומרים, ושאפשר לספר למבוגר.`

### 3.3 W-37 in Band A (a child of 3 or 4 says they hit themselves), T3, in the digest

| Proposed key | Text |
|---|---|
| `alertSelfHitTitle` | `מילים על מכות לעצמי` |
| `alertSelfHitMany` | `השבוע נשמעו במשחק של {child} מילים על מכות לעצמי, {n} פעמים.` |
| `alertSelfHitOnce` | `השבוע נשמעו במשחק של {child} מילים על מכות לעצמי, פעם אחת.` |
| `alertSelfHitCalm` | `אצל ילדים צעירים זה קורה לא פעם בזמן התפרצות של כעס או תסכול. כדאי לשים לב אם זה קורה הרבה או אם יש סימנים על הגוף, ולהתייעץ עם רופא הילדים אם משהו מדאיג. ייתכן גם שהאפליקציה שמעה לא נכון.` |

- **Why it is worded like this:**
  - It says only what the psychologist's sources say: head-banging and self-hitting are common in the tantrums of 3 to 5 year olds. I did not add that "it passes with age", which is not in the sources.
  - It names when to act (often, or marks on the body) without naming a condition.
  - It does not quote the child (`אני מכה את עצמי`), for the same privacy reason as 3.1.
- **Note:** `מכות לעצמי` is a plain, slightly colloquial phrase, chosen so as not to use the clinical `פגיעה עצמית` for a 3-year-old. Ages 5 to 8 stay at T2 with the full T2 text, unchanged.

## 4. For the app-developer

1. **Nothing to fix** in the 44 strings. Keep the isolates around the short numbers.
2. **When the owner approves the drafts of section 3,** add them as adult strings:
   - mark them `review: needs-editor`;
   - give `alertSecretAsk*` and `alertSelfHit*` the `{n}` and `פעם אחת` forms, like `alertNoteMany` / `alertNoteOnce`;
   - place `alertOften` under the T1 or T2 body, before the help block;
   - run `tools/export-hebrew-review.py` so the editor's table picks them up.
3. **The two older alert strings** in section 1 come in with the master-table corrections.

## 5. Questions for the owner

1. The three drafts of section 3: agree?
2. Show the C-5 line (`alertOften`) also when "keep the words" is off?
3. In the W-47 digest, should the parent also be told what the helper answered? I recommend no.

## 6. Second check (2026-10-30): `alertHeardTimes` and the implemented drafts

### 6.1 The new string `alertHeardTimes`

| Key | Text | Check | Status |
|---|---|---|---|
| `alertHeardTimes` | `זה נשמע {n} פעמים בתוך חצי שעה.` | Correct Hebrew. | ok, needs-editor |

- **Agreement:** `זה נשמע` (masculine singular, "it was heard") agrees with `זה`.
- **Number:** `פעמים` with a digit count of 2 or more needs no agreement (the app never uses the n = 1 case).
- **Tone:** neutral, says "heard", and judges nothing.
- **Pointing:** none. It is an adult text.
- **Direction:** a bare digit run between Hebrew words shows in the right order, so no isolate is needed.
- **Optional:** for n = 2, spoken Hebrew says `פעמיים`. A separate string `זה נשמע פעמיים בתוך חצי שעה.` would read a little more naturally, but `2 פעמים` written with digits is acceptable on screen. **Not required.**

### 6.2 The drafts of section 3 as implemented

Compared letter for letter with the tables of section 3.

| Keys | Result |
|---|---|
| `alertOften` | identical to the draft |
| `alertSecretAskTitle`, `alertSecretAskMany`, `alertSecretAskOnce`, `alertSecretAskCalm` | identical |
| `alertSelfHitTitle`, `alertSelfHitMany`, `alertSelfHitOnce`, `alertSelfHitCalm` | identical |

All of them:
- have no nikud;
- put `{child}` only after a space (`של {child}`);
- have the `{n}` form and the `פעם אחת` form.

The comments in `he.dart` say the owner approved the W-47 and W-37 drafts on 2026-10-30. The strings still carry
`review: needs-editor` in the table until the owner approves them there. Nothing for the app-developer to fix.

## 7. The "keep the words" help text is no longer true (security-engineer finding, 2026-10-30)

**The problem:** with "keep the words" off, the app still keeps three things: the **kind** of alert, the **count**, and
the "it may happen often" flag. It does not keep the child's words. The current help text says that only the category is
kept, which is no longer true.

| Key | Now | Corrected (`review: needs-editor`) | Why |
|---|---|---|---|
| `alertsKeepWordsHelp` | `כשמופעל, המילים שנאמרו נשמרות עם ההתראה עד 30 יום. כשכבוי, נשמרת רק הקטגוריה.` | `כשמופעל, המילים שנשמעו נשמרות עם ההתראה עד 30 יום. כשכבוי, המילים לא נשמרות. נשמרים רק סוג ההתראה, מספר הפעמים, והאם נשמע שזה אולי קורה הרבה.` | Says exactly what is kept. `שנשמעו` (not `שנאמרו`) matches the other alert texts and the recogniser's uncertainty. The 30 days are stated only for the words: the security-engineer must confirm how long the kind, count and flag are kept before any duration is added for them. |
| `alertsKeepWords` (the switch) | `לשמור בהתראה את המילים שנאמרו` | `לשמור בהתראה את המילים שנשמעו` | The same reason. The meaning is unchanged. |

**Other strings checked for the same claim:**

| Key | Says | Verdict |
|---|---|---|
| `alertWordsNotKept` | `המילים עצמן לא נשמרו, לפי ההגדרות שבחרתם.` | Still true: it is only about the words. |
| `alertsHonest` | Listening only on a tap, misses a lot, no diagnosis, no reporting | Makes no claim about storage. True. |
| `alertCardTitle`, `alertCard1` to `4` | Body safety and secrets | No claim about storage. |
| `alertsNever` | Alerts are not shown in the children's area | True. |
| `alertOften` | Shown even when the words are not kept | Consistent with the corrected help text, which now says the "often" flag is kept. |
| `areaVoiceHelp` | `… ההקלטה נמחקת מיד ולא נשמרת ולא נשלחת לשום מקום …` | **Flag.** True for the *audio*. A parent may still read it as "nothing from the voice is kept", although the recognised words can be kept in an alert when the switch is on. Suggested addition at the end: `המילים שזוהו נשמרות רק בהתראה, ורק אם ההגדרה "לשמור בהתראה את המילים שנשמעו" מופעלת.` The security-engineer confirms it is accurate before the app-developer adds it. |

**For the app-developer:** apply the two corrections of the first table. Add the `areaVoiceHelp` sentence only after
the security-engineer confirms it. Run `tools/export-hebrew-review.py` afterwards; the new texts stay `needs-editor`
until the owner approves them.
