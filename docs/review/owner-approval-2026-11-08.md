# Owner approval snapshot: owner-approval-2026-11-08.csv

Made by `python -I -X utf8 tools/hebrew_voice_review.py --approval-snapshot docs/review/owner-approval-2026-11-08.csv`. It lists every row of `hebrew-master.csv` that is `text-ready` or `proposed`. If the owner says yes, the orchestrator puts the sha256 below and the date in `CONFIG` of `tools/owner_approval.py`; from then on each listed row is `owner-approved` while its text, screen text and voice text are exactly what they are now. A row that is edited falls back and needs a new approval.

sha256 of the snapshot file: `f19724a7337cc62d82d0fb8cdcbf74d612207137a622c6c82847e2e26f29640a`

## Counts

- rows in the snapshot: 14434 (`text-ready` 14325, `proposed` 109)
- spoken (a voice says it): 9762; not spoken (screen only): 4672

| group | text-ready, spoken | text-ready, not spoken | proposed, spoken | proposed, not spoken | all |
|---|---|---|---|---|---|
| 1. App screens and buttons | 7 | 538 | 0 | 0 | 545 |
| 2. Core voice lines (spoken by every friend) | 22 | 0 | 4 | 0 | 26 |
| 3. Lesson content (skills, activities, misconceptions) | 9558 | 4012 | 105 | 0 | 13675 |
| 4. Reviewed helper (tutor) lines | 66 | 0 | 0 | 0 | 66 |
| 6. Helper lexicon (the words the AI helper may use) | 0 | 122 | 0 | 0 | 122 |

## Why the 109 `proposed` rows were still waiting

- 78: V1 (pronunciation audit 2026-10-29): the voice text changed so a voice cannot misread it (a kept nik
- 19: V1 (pronunciation audit 2026-10-29): the voice text keeps a nikud or a beat so a voice cannot misrea
- 9: Owner 2026-11-06 (chat): yes. Was "הַמָּקוֹם בַּתּוֹר אֵינוֹ כַּמָּה יֵשׁ…" (table: "הוּא לֹא כַּמָּ
- 3: Logic sweep, read 2026-11-07. Was "שָׂמִים יַחַד אֶת אוֹתוֹ הַדָּבָר: …" and "מְמַיְּנִים לְשָׁלוֹשׁ

## A sample of 20 voiced lines

Spoken rows with different voice texts (2767 in all), spread evenly over the table (order of source and id). Each shows the text sent to the voice.

| status | source | id | voice text |
|---|---|---|---|
| text-ready | activity.b.colb01.1.json | feedback.correct.caption.0.v | כן, אדום וצהוב נעשים כתום. |
| text-ready | activity.b.logb06.1.json | prompt.caption.0.v | מה משותף לכולם? |
| text-ready | activity.b.mathb03.1.json | hints.2.caption.0.v | שָׁלוֹשׁ ועוד אַרְבַּע: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ… שֶׁבַע. עכשיו תורכם — ללחוץ על שֶׁבַע. |
| text-ready | activity.b.mathb09.6.json | prompt.caption.0.v | שְׁתַּיִם ועוד שְׁתַּיִם, מול אַרְבַּע ועוד שָׁלוֹשׁ. איזה צד כבד יותר? |
| text-ready | activity.b.numb01.1.json | prompt.caption.0.v | מה בא אחרי אַחַת עֶשְׂרֵה? |
| text-ready | activity.b.numb05.4.json | prompt.caption.0.v | תנו לי שִׁבְעָה עָשָׂר ברווזים. |
| text-ready | activity.b.numb13.9.json | hints.2.caption.0.v | מתחילים מֵאֶפֶס וסופרים: מֵאַחַת עד שְׁבַע עֶשְׂרֵה. עכשיו תורכם. |
| text-ready | activity.b.shpb08.1.json | hints.2.caption.0.v | הגליל — נסתכל על הצורה שלו. עכשיו תורכם. |
| text-ready | activity.b15.matha07.1.json | feedback.incorrect.0.caption.0.v | הם גדולים, אבל כמה יש? בואו נספור. |
| text-ready | activity.c.mathb04.11.json | feedback.incorrect.0.caption.0.v | בסל יש עוד, גם אם לא רואים. מתחילים ממה שבסל וממשיכים לספור. |
| text-ready | activity.c.mathc02.17.json | hints.1.caption.0.v | סימן השווה אומר: בִּשְׁנֵי הצדדים יש אותו מספר. |
| text-ready | activity.c.numb09.9.json | hints.2.caption.0.v | שֶׁבַע… שְׁמוֹנֶה, תֵּשַׁע, עֶשֶׂר. הוספנו שָׁלוֹשׁ. עכשיו תורכם — ללחוץ על שָׁלוֹשׁ. |
| text-ready | activity.c.numc03.27.json | feedback.correct.caption.0.v | כן, שילמתם בדיוק חֲמִשִּׁים וּשְׁנַיִם שקלים. |
| text-ready | activity.col.name.black.json | feedback.correct.caption.0.v | כן, זה כדור שחור. |
| text-ready | activity.give.cats.2.json | prompt.caption.0.v | תנו לי שְׁנֵי חתולים. |
| text-ready | activity.math.add.stars.json | hints.2.caption.0.v | שְׁלוֹשָׁה כוכבים ועוד שְׁנֵי כוכבים: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ… חָמֵשׁ. עכשיו תורכם — ללחוץ על חָמֵשׁ. |
| text-ready | activity.pick.numeral.1.json | prompt.caption.0.v | איפה המספר אַחַת? |
| text-ready | activity.x.mathb19.11.json | hints.2.caption.0.v | זה דג. עכשיו תורכם — ללחוץ עליו. |
| text-ready | hero-son.json | count.butterflies.5 / mistake M-CNT-SKIP / hint 2 / band C | בואו נספור לאט, ניגע בכל פרפר פעם אחת, ונראה אם יש פרפר שלא ספרנו. |
| text-ready | lesson.solids-more.json | celebration.caption.0.v | יפה מאוד, גופים בכל מקום. |
