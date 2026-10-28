# The teaching view on five Hebrew questions (board B-2)

Curriculum-expert (Knowledge Agent), 2026-10-28. This answers questions 2, 3, 7, 8 and 11 of `docs/agents/hebrew-notes.md` §5. It looks at them from the learning side, so the owner can decide. The wording of any final line belongs to the hebrew-text-editor. Every Hebrew line below is a draft marked `"review": "needs-editor"`.

How sure each statement is: **[read]** I read it in the pack, the code or a source; **[source]** a cited source; **[memory]** an established finding I know but did not re-read today; **[guess]** my own judgement.

---

## 1. Question 2: what the M-CNT-SIZE line must say

**Where the line plays [read]:**
- `vo:fb.size`, 16 rows: NUM-A-11 and NUM-A-12, ages 3 to 4, with "where are there more" and "where are there fewer" items, and items where one set is bigger and others where one set is spread out;
- wrongly, also NUM-A-07 match pairs (audit F4).

**The line today:** "יוֹתֵר לֹא תָּמִיד אוֹמֵר גָּדוֹל יוֹתֵר" ("more does not always mean bigger"). It states the misconception backwards.

**The editor's proposal:** "מַה שֶּׁתּוֹפֵס יוֹתֵר מָקוֹם לֹא תָּמִיד יֵשׁ בּוֹ יוֹתֵר. בּוֹאוּ נַשְׁוֶה אֶחָד אֶחָד." Its meaning is right.

**What the line must do (the teaching view):**
1. **Name what the eye was caught by** ("they are big", "they are spread out"), so the child notices the cue they used.
   - In Piaget's number task, children of 3 to 4 say the longer or more spread row has more. [source: Piaget's conservation of number, as summarised in [Vaia](https://vaia.com/en-us/explanations/psychology/cognition/conservation-of-number-piaget)]
   - Later work shows they can do better when the task is clear. [source: McGarrigle and Donaldson 1974, in the same summary]
   - So a clear, concrete redirection works at this age; an abstract rule does not [guess].
2. **Turn the child to the strategy, not to a rule:**
   - NUM-A-11 compares by matching, so the strategy there is pairing one to one;
   - NUM-A-12 compares by counting, so the strategy there is counting.
   - This is the curriculum's own repair (§5.2: "R1 one-to-one pairing with lines; then counting").
   - In Clements and Sarama's comparing trajectory, comparing by counting when the sizes differ comes after comparing by matching [memory].
3. **Have no negation.** These are Band A lines. Curriculum §8.3 rules out "לֹא…" for Band A.
   - Studies of how young children understand negation find it costly to process, and children often pick the item that *has* the named thing. [source: [Nordmeyer and Frank, Stanford](https://langcog.stanford.edu/papers/NF-underreview.pdf); [escholarship](https://escholarship.org/content/qt29c57371/qt29c57371.pdf?t=sgior4)]
   - Both the old line and the proposed one have "לֹא תָּמִיד" at their centre.
4. **Be short and concrete.** Feedback is at most 2 seconds and at most 8 words in Band A (§8.5 and §8.3). "תּוֹפֵס מָקוֹם" is an abstract phrase for a 3-year-old, and "יֵשׁ בּוֹ" suggests a container [guess].

**Recommendation:** two lines chosen by the item's cue. The generator knows the cue: `scale` for size, `arrangement` for spread. Each line ends in the strategy of its skill. All four lines are drafts marked `needs-editor`:

| Skill and cue | Draft |
|---|---|
| NUM-A-12, size | "הֵם גְּדוֹלִים, אֲבָל כַּמָּה יֵשׁ? בּוֹאוּ נִסְפֹּר." |
| NUM-A-12, spread | "הֵם רְחוֹקִים זֶה מִזֶּה, אֲבָל כַּמָּה יֵשׁ? בּוֹאוּ נִסְפֹּר." |
| NUM-A-11 (matching), "more" items | "בּוֹאוּ נְחַבֵּר כָּל אֶחָד לְחָבֵר — וְנִרְאֶה אֵיפֹה נִשְׁאָר עוֹד." |
| NUM-A-11 (matching), "fewer" items | "בּוֹאוּ נְחַבֵּר כָּל אֶחָד לְחָבֵר — וְנִרְאֶה אֵיפֹה חָסֵר." |

- **The picture must do the work:** hint 2 of these items should draw the pairing lines. Today `tap_answer` draws nothing for a hint (audit F12).
- **If the owner wants a single line:** the editor's proposal is acceptable for Band B, but not for Band A, because of the negation and the abstract phrase.
- **Remove the tag from NUM-A-07** in any case (audit F4).

---

## 2. Question 3: count on or count all for the missing addend (MATH-B-18)

**The items [read]:**
- "שָׁלוֹשׁ וְעוֹד כַּמָּה שָׁוֶה שֶׁבַע?", with `3 + ? = 7` drawn left to right;
- the choices are the answer, the total (tagged M-EQ-OPER), and an untagged n ± 1;
- hint 3 counts "אַחַת … שֶׁבַע" and then says "tap 4", so the child hears seven numbers and is told the answer without seeing where 4 comes from.

**The editor's G1 counts on:** "שָׁלוֹשׁ, וּמַמְשִׁיכִים לִסְפֹּר עַד שֶׁבַע: אַרְבַּע, חָמֵשׁ, שֵׁשׁ, שֶׁבַע. סָפַרְנוּ אַרְבַּע".

**The teaching view:**
1. **The order of strategies.** For a "join, change unknown" problem (a start, an unknown change, a known result), Cognitively Guided Instruction describes two strategies in this order:
   - direct modelling: build the start, add objects up to the result, count what was added;
   - then "counting on to": start at the known number and count up to the total while keeping track. [source: practitioner summaries of Carpenter et al., [Relay: counting on and back](https://relay.libguides.com/math-interventions/counting-on-back) and [direct models](https://relay.libguides.com/math-interventions/direct-models)]
   - A child moves to the counting strategy once direct modelling is reliable [same source].
2. **Keeping track is the hard part of counting up.** The child must count 4, 5, 6, 7 and at the same time know that this was *four* counts. [source: [IntegrowMath, missing addend tasks](https://www.integrowmath.org/ready-set-math/subgoal/17): count from the first number "keeping track of the number of counts to the total"]
   - Said only aloud, as G1 has it, the tracking is invisible [guess].
3. **Count all from 1 is not wrong for a 5-year-old.** It is the direct-modelling level, and M-ADD-RECOUNT is "a strategy level, not an error" (§5.2). But counting 1 to 7 does not answer "how many were added" unless the first three are marked.
4. **Order on the path.** MATH-B-04 (count on from the larger number) is not in the pack. Counting on should be taught before it is used as the worked example for the missing addend, so MATH-B-04 should be a prerequisite of MATH-B-18 (audit §3, B3).

**Recommendation:** use both strategies, in the curriculum's order (concrete, then counting on), across the help ladder:

| Step | What happens | Draft line (`needs-editor`) |
|---|---|---|
| First mistake, "7" | The total was given | "שֶׁבַע זֶה כְּבָר הַכֹּל. כַּמָּה צָרִיךְ לְהוֹסִיף לְשָׁלוֹשׁ?" |
| First mistake, "10" (new distractor, tag M-PPW) | The two numbers that are shown were added | "חִבַּרְנוּ אֶת שְׁנֵיהֶם. הַשֶּׁבַע הוּא הַכֹּל — מָה חָסֵר?" |
| Hint 2, direct model (R1) | Seven dots; three are coloured or put under a cup; the rest light one by one | "שָׁלוֹשׁ כְּבָר יֵשׁ. נִסְפֹּר אֶת מָה שֶׁהוֹסַפְנוּ: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע." |
| Hint 3, count on with tracking (R4) | The guide says three, then raises one finger per count | "שָׁלוֹשׁ… אַרְבַּע, חָמֵשׁ, שֵׁשׁ, שֶׁבַע. אַרְבַּע אֶצְבָּעוֹת — לִלְחֹץ עַל אַרְבַּע." |

- **So the answer to "count on or count all" is: count on, but with visible tracking, and after a direct model.**
- G1's words are right for hint 3 once fingers or dots show the four counts.
- **To build it:** the app-developer must make `tap_answer` draw the hint actions (audit F12), and the generator must add the "10" distractor.

---

## 3. Question 7: תֵּבָה or קֻפְסָה for the box-shaped solid

**Where the word is used [read]:** SHP-B-08 and 09, ages 5 to 6. SHP-A-07, ages 3 to 4, uses the same picture under the name קֻבִּיָּה (audit F9).

**The evidence:**
1. **The official term is תיבה.**
   - The Ministry's kindergarten mathematics curriculum lists the solids תיבה, קובייה, פירמידה, גליל and חרוט, and the grade 2 programme names "כדור, חרוט, פירמידה, גליל, תיבה וקובייה". [source, read only through a search engine's summary; I could not extract the PDF text myself: [Ministry, kindergarten mathematics](https://meyda.education.gov.il/files/Tochniyot_Limudim/KdamYesodi/Math3.pdf), [grade 2 geometry](https://meyda.education.gov.il/files/Tochniyot_Limudim/Math/Yesodi/Mevoeret/B.Geometriya.pdf)]
   - Our curriculum (§4.4, §8.2) uses תֵּבָה for the same reason.
2. **The kindergarten guidance starts from everyday packages.**
   - The Ministry's broadcast "בעין גאומטרית" asks children to bring packaging in interesting shapes, "not necessarily solids that have names". [read: [Ministry, בעין גאומטרית](https://pop.education.gov.il/sherutey-tiksuv-bachinuch/academya-bareshet/kol-hashidurim/ain-geomtrit/)]
   - So the gan way into the solid is the box the child knows, קופסה.
3. **Young children learn a new word best tied to one they know** (a known word plus the precise one, in context, used again and again) [memory: Beck, McKeown and Kucan's "tiers" of vocabulary teaching; not re-read].
   - תֵּבָה as a shape is a word a 5-year-old will meet at school and not at home [guess].
4. **A word cannot teach while the picture contradicts it.** Today the "box" is an isometric cube, so neither word fits it (audit F9).

**Recommendation:**
1. **Band B (SHP-B-08 and 09):** teach תֵּבָה, always bridged to the known word the first times:
   - in the prompt or the correct feedback: "תֵּבָה — כְּמוֹ קֻפְסָה שֶׁל נַעֲלַיִם." (a draft, `needs-editor`);
   - when a voice answer says "קֻפְסָה", accept it as right, and repeat it back as "נָכוֹן, תֵּבָה" (curriculum §8.1's recast policy).
2. **Band A (SHP-A-07):** use "קֻפְסָה" for a box-shaped thing, and keep קֻבִּיָּה for a picture that really is a cube.
3. **Before either:** the design-director draws a shoe-box-shaped cuboid and a separate cube.

---

## 4. Question 8: sums about objects, feminine as at gan, or agreement with the noun

**The case [read]:** a hint says "חֲמִשָּׁה פָּחוֹת שְׁנַיִם" after "five apples": masculine, with the noun left out. The answer tiles, the counting and the numerals the child taps are read in the feminine ("שָׁלוֹשׁ").

**The evidence:**
1. **The rule.** The Ministry's Hebrew-language teaching material, citing the Academy, says that abstract numbers that do not count a specific noun, "למשל מספרים בתרגילי חשבון" (for example, numbers in arithmetic exercises), are expressed in the feminine. Its example is "אחת ועוד אחת שווה שתיים". [read: [Ministry, "שם המספר"](https://meyda.education.gov.il/files/Pop/0files/ivrit_habaah_lashon/pedagogia/shem-mispar.pdf); text extracted from the PDF]
   - A number with its noun agrees with the noun (curriculum §8.1).
2. **What children hear.** In everyday speech numbers drift toward the short feminine form. [source, through a search summary: Gonen and Rubinstein, *Te'uda* 27, [Tel Aviv University](https://humanities.tau.ac.il/sites/humanities.tau.ac.il/files/media_server/Jewish%20History/Teuda/Teuda-%20vol%2027-%20English/Teuda-%20Vol%2027-%2018-%20Gonen%20%26%20Rubinstein.pdf)]
   - So feminine sums are what children already hear at gan and at home [guess for gan practice; I found no written gan source].
3. **The teaching reason:**
   - **One word per number.** If a hint says "שְׁלוֹשָׁה" and the tile the child must touch is read "שָׁלוֹשׁ", a 5-year-old has one more mapping to make, between two words for one numeral [guess, from cognitive load].
   - **It marks the step from story to sum.** Moving from the story ("five apples") to the number sentence ("חָמֵשׁ פָּחוֹת שְׁתַּיִם") is the step from concrete to symbolic (curriculum principle 5). Switching to the abstract feminine form at that moment marks the step instead of blurring it [guess].

**Recommendation:**
- **When the noun is said, agree fully with it:** "חֲמִשָּׁה תַּפּוּחִים, לוֹקְחִים שְׁנֵי תַּפּוּחִים — נִשְׁאֲרוּ שְׁלוֹשָׁה תַּפּוּחִים."
- **When the number stands alone, as in a sum or a sentence of numbers, it is feminine, as in the Academy's rule:** "חָמֵשׁ פָּחוֹת שְׁתַּיִם שָׁוֶה שָׁלוֹשׁ."
- **Never use a masculine number without its noun.**
- **A story hint may end with the abstract sum in the feminine.** That is a good worked example: story, then sum.

---

## 5. Question 11: should the shop hints name the coins or the amounts?

**The case [read]:**
- Hint 3 of the nine `x.mathb17` items says, for example, "אֶפְשָׁר לְשַׁלֵּם בִּשְׁנֵי שְׁקָלִים וַחֲמִשָּׁה שְׁקָלִים", while the coins that pay are lit.
- The misconception this template diagnoses is M-MONEY-COUNT (counting coins instead of value). Its classifier fires when the number of coins equals the price in shekels.

**The teaching view:**
1. **"שְׁנֵי שְׁקָלִים" is ambiguous in exactly the way the misconception is.** It can mean one ₪2 coin or two ₪1 coins.
   - `x.mathb17.7` says "שְׁנֵי שְׁקָלִים וּשְׁנֵי שְׁקָלִים וַחֲמִשָּׁה שְׁקָלִים" with a purse that holds two ₪1 coins. A child who takes "two shekels" as two coins is following the words.
2. **The curriculum's repair separates the coin from its value** (R1, "swap coins for ₪1 coins and count"; R2, "value labels").
   - A hint that names the coin as a thing with a value ("מַטְבֵּעַ שֶׁל שְׁנֵי שְׁקָלִים") does this in words.
   - It is also how Israeli adults speak: "מטבע של חמישה שקלים", or the shorter "חמש שקל" [guess, everyday usage].
3. **The words should name what is lit** [memory: Mayer's signalling principle, that words pointing at what the eye should look at help learning].
   - Today the hint names an amount while the screen lights coins.
4. **Children over-weight size when they value coins.** [source: [Scientific Reports 2020](https://www.nature.com/articles/s41598-020-62419-8.pdf), on the "bigger is better" pull of coin value, building on Bruner and Goodman]
   - The real ½ ₪ coin is bigger than the ₪1 coin, and the app draws them at their real sizes (audit, "Checked and found right").
   - So the value must be said with each coin.
5. **Length.** Band B hints are at most 5 seconds (§8.5). Two coins with their values and a total is about 12 words, roughly 4 to 5 seconds [guess at speaking rate]. Three coins need the short form after the first.

**Recommendation:** name each coin by its value, then say the total. Both are drafts marked `needs-editor`:
- two coins: "מַטְבֵּעַ שֶׁל חֲמִשָּׁה שְׁקָלִים וּמַטְבֵּעַ שֶׁל שְׁנֵי שְׁקָלִים — בְּיַחַד שִׁבְעָה שְׁקָלִים."
- three coins: "מַטְבֵּעַ שֶׁל חֲמִשָּׁה, מַטְבֵּעַ שֶׁל שְׁנַיִם וְעוֹד מַטְבֵּעַ שֶׁל שְׁנַיִם — בְּיַחַד תִּשְׁעָה שְׁקָלִים."

**Keep hint 2 as it is** ("כָּל מַטְבֵּעַ שָׁוֶה כַּמָּה שֶׁכָּתוּב עָלָיו"): it is the right second help.

---

## Summary for the owner
| Question | Recommendation |
|---|---|
| 2 | Two short lines by cue, without "לֹא", ending in the strategy (pairing for NUM-A-11, counting for NUM-A-12). The editor's line is acceptable for Band B only. |
| 3 | Count on, with visible tracking (fingers), after a concrete direct model at hint 2. Add the distractor 10 (M-PPW). Teach MATH-B-04 first. |
| 7 | תֵּבָה in Band B, bridged ("כְּמוֹ קֻפְסָה"), with קופסה accepted by voice; קֻפְסָה in Band A. A real cuboid picture first. |
| 8 | Feminine for any number on its own (the Academy's rule for arithmetic); full agreement when the noun is said; never a masculine number without its noun. |
| 11 | Name each coin by its value, then the total. |
