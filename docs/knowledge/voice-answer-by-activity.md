# Where a spoken answer makes sense (board B-24)

Curriculum-expert decision, 2026-10-29, pack 0.8.0 (767 activities). Owner sign-off needed on the three "owner may switch on" rows.

## The rule

An activity gets `voiceAnswer: true` only when all three hold:

1. **The child produces the answer.** The question asks for a word the prompt does not already say: a number, a colour, a shape, a day or a time of day. "Where is the number 5?" fails: saying "five" only repeats the prompt, and recognising the 5 can only be shown by tapping it.
2. **Speaking it is the natural reply and shows the skill.** Saying the word shows the same knowledge as the tap: counting, then answering "how many?", naming, or saying the next number.
3. **The speech can be matched.** The options have distinct short spoken forms: numbers, or one distinguishing word. There are no yes or no options, because the matcher reads any "לא" as a negation and retries, so "לא" can never be accepted. There are no two-attribute objects and no left or right words.

Everything else is `false`, and the mic is **not shown at all**, not even faded. Unclear speech is never "wrong" (a retry, then the cards light up for a tap). This decision does not change that.

## Today vs. after

- **Today:** when a parent turned voice on, the mic shows on all 767 activities. It is live on 561 of them (every `tap_answer`, `count_tap` and `flash`) and faded on the other 206.
- **After:** the mic shows on **267** activities and is gone from **500**.

## Table

| template | activity kind (skill ids / prompt pattern) | voiceAnswer | reason | count |
|---|---|---|---|---|
| count_tap | all ("touch each one and count", then "how many?"); the mic stays faded until the "how many?" question, as `listensNow` does today | **true** | Counting, then saying the total, is the cardinality principle said aloud. | 28 |
| flash | all ("look fast! how many?") | **true** | Subitising: the child says the number seen. | 12 |
| tap_answer | **number answer**: all options are numerals and the prompt asks for a number ("כמה…?", "מה בא אחרי/לפני…?", "…ועוד כמה?", "מה השעה?", "כמה צלעות?", "איזה מספר גדול/קטן יותר?"). Skills MATH-A-01 6, MATH-A-02 6, MATH-B-01 12, -02 10, -03 8, -06 8, -07 6, -08 12, -10 6, -15 10, -18 7, MATH-B-19 (the 5 "כמה…" chart items), NUM-A-01 6, NUM-A-02 7, NUM-A-14 6, NUM-B-01 9, -02 9, -03 8, -10 10, -11 12, -14 8, -16 9, -17 6, SHP-B-02 8 | **true** | The answer is a number word the child retrieves. Numbers are the best-supported matcher type. | 194 |
| tap_answer | **name a colour**: COL-A-05 "איזה צבע…?" (4), COL-B-01 all (9: "what colour comes out", "what is missing") | **true** | Producing the colour name is the target. The options differ by the colour word only. | 13 |
| tap_answer | **name a shape**: SHP-A-04 `shp.rect.long` (1), SHP-A-05 "איזו צורה יש ל…?" (3), SHP-B-03 "לאיזו צורה כל הצלעות שוות?" (3) | **true** | Producing the shape name is the target. Each option is one word. | 7 |
| tap_answer | **next in a named sequence**: MATH-A-05 "מה בא אחרי/לפני…" (2), MATH-B-14 days (11) | **true** | Children learn the days and times of day orally. | 13 |
| tap_answer | **where is / find**: the prompt names the answer. NUM-A-08 7, NUM-B-08 12, NUM-A-07 "איפה יש שלושה…" 3, COL-A-02 6, -03 8, -04 6, -06 6, -07 6, COL-A-05 "איפה הבננה/התפוח" 2, COL-B-03 8, SHP-A-02 6, -03 6, SHP-A-04 "איפה המלבן/הריבוע" 5, SHP-A-08 6, SHP-A-10 6, SHP-B-01 8, SHP-B-03 "איפה המלבן?" 3, SHP-B-08 8, MATH-A-05 "איזו תמונה היא…" 4 | false | Recognition, not naming. Saying it repeats the prompt (the owner's report). | 116 |
| tap_answer | **choose the numeral**: NUM-A-07 "כמה…? בוחרים את המספר" | false | The skill is linking a quantity to the written numeral. A spoken count skips the numeral. | 4 |
| tap_answer | **yes / no**: LOG-A-04 6, NUM-A-11 "אותו מספר?" 3, NUM-B-18 8, SHP-B-04 8 | false | The matcher can never accept "לא" (it is read as negation). A spoken "no" can also mean "I don't want to". Speaking adds nothing to a guess between two answers. | 25 |
| tap_answer | **match the same**: COL-A-01, LOG-A-01, SHP-A-01 (6 each) | false | Matching comes before naming (colour words come late, Wagner et al. 2013). Speaking would demand the later skill. | 18 |
| tap_answer | **compare / relate**: MATH-A-04 6, MATH-A-07 6, NUM-A-11 more/fewer 5, NUM-A-12 6, COL-B-02 11, MATH-B-19 most/least 4, LOG-A-10 6, LOG-B-04 6 | false | The natural reply is pointing ("this one"). The options have no name to say. | 50 |
| tap_answer | **pick an object by relation, order or category**: LOG-A-02 6, LOG-A-03 3, LOG-A-06 6, LOG-A-07 6, LOG-A-08 6, LOG-A-09 6, LOG-B-01 8, LOG-B-06 6, LOG-B-09 6, CS-A-01 6, CS-A-05 6, NUM-A-13 7, SHP-A-05 "מה בצורת…" 3, SHP-A-07 6 | false | The answer is a thing, so naming it is extra vocabulary, not the skill. The options share the noun ("כדור"), so a child who says "the ball" goes unmatched. | 81 |
| give_n | all ("תנו לי 5…", buy N, 22) | false | The number is in the prompt. The answer is the set the child makes (the Give-N task). Counting aloud while moving is good, but nothing needs to be heard. | 22 |
| number_line | place (12), jump "על איזה מספר תנחת?" (7) | false | The tap on the line is the linear representation the skill teaches. Jump: owner may switch on later. | 19 |
| balance | compare (14), balance (4) | false | The answer is left, right or equal, and left/right words are unreliable in Band B. | 18 |
| spot_error | all | false | Tap the wrong cell. | 32 |
| trace | all | false | Tracing. | 26 |
| robot_path | all | false | Arrows and a plan. | 20 |
| sort_drag | sort, share | false | Drag. | 17 |
| match_pairs | all | false | Drag or pair. | 17 |
| build_pattern | all | false | Build. | 13 |
| clock_set | all | false | Set the hands. (Reading the clock, MATH-B-15 "מה השעה?", is true above.) | 8 |
| shop_pay | all | false | Pay with coins. | 9 |
| shape_builder | all | false | Build. | 5 |

**Totals:** true 267, false 500.

| template | true | false |
|---|---|---|
| tap_answer | 227 | 294 |
| count_tap | 28 | 0 |
| flash | 12 | 0 |
| the other 12 templates | 0 | 206 |

Five activities are hand-written (they are in no unit spec), so they need the flag set by hand: `count.butterflies.3`, `.4` and `.5` are true; `give.butterflies.4` and `pick.red.flower` are false.

## Where the flag lives and what the validator enforces

- The field is `voiceAnswer` (boolean) on `activity/v1`. `author.py` writes it on **every** activity: the default comes from the template and kind (count_tap, flash, next_number, sum, madd, mtake and zero are true; all other kinds are false), and a unit item can override it with `"voice": true|false`. The `pick` kind covers 370 activities of mixed kinds, so the override is set per skill in the `band_b*.py` tables and on the 10 Band A `pick` items (`col.world.apple.red`, `col.world.banana.ripe`, `col.world.grass`, `col.world.sun`, `math.time.after`, `math.time.before`, `shp.rect.long`, `shp.world.plate.shape`, `shp.world.sign.shape`, `shp.world.window.shape`). NUM-A-08 and NUM-B-08 (numeral options) must come out false.
- The app reads a missing field as false (no mic).
- **Validator errors:**
  - (a) `voiceAnswer: true` on a template other than tap_answer, count_tap or flash.
  - (b) `voiceAnswer: true` with an empty accept-list. Every option must have a numeral or value, or a label with at least one word that the other options do not share, and no two options may have the same spoken form.
  - (c) `voiceAnswer: true` with an option whose spoken form is כן or לא, or contains the token לא.
  - (d) In the starter pack, the field is missing.
- **Validator warning:** `voiceAnswer: true` where one option's number word is a prefix of another's. There are 8 today: `b.mathb03.7` (3/13), `b.mathb15.4`, `b.mathb15.7` and `b.mathb15.8` (2/12), `b.numb02.2`, `b.numb02.3` and `b.numb02.6` (20/2x), `b.numb10.10` (8/18). With the 600 ms early accept on a settled partial, a pause in "שמונה… עשרה" can take 8 for 18.

## For the owner

1. Approve the rule. Three groups are arguably speakable and are off by default; you can switch any of them on later:
   - patterns "מה בא אחר כך?" / "מה חסר?" (LOG-A-06, LOG-A-07, LOG-B-01; 20 activities)
   - number-line jump "where will the frog land?" (7 activities; the session would first need to learn to listen)
   - "מה משותף לכולם?" (LOG-B-06; 6 activities; children answer "כולם אדומים", not "הצבע")
2. A side effect, which is a fix: the 25 yes/no activities currently offer a mic that can never accept "לא". With this decision they lose the mic.

## Sources

- Gelman & Gallistel (1978), *The Child's Understanding of Number*: the counting principles, including cardinality ("how many?" after counting).
- Wynn (1990), *Children's understanding of counting*, Cognition 36: the Give-N task. The answer is the set made, not a word.
- Wagner, Dobkins & Barner (2013), *Slow mapping: Color word learning as a gradual inductive process*, Cognition 127: producing colour words lags behind perceiving and matching colours.
- Siegler & Ramani (2009), J. Educ. Psych. 101: linear number board games. The value is in moving along a left-to-right line.
- ASR on young children's speech has a much higher error rate than on adults' (secondary summary: up to about 35% WER at ages 4 to 6): [Learning Agency](https://the-learning-agency.com/guides-resources/closing-the-child-speech-recognition-gap-evidence-limitations-and-paths-forward/), [arXiv 2102.09918](https://arxiv.org/pdf/2102.09918). This is why the voice is kept to short, distinct answers.
