# Suggestions from the Gemini review, and what was done

Date: 2026-10-28. Source: `docs/review/hebrew-review.csv` (1,209 texts) and the instructions you gave Gemini.

## 1. Grammar: "זֶה" (this) that did not agree, and the article of the ordinals (fixed, in pack 0.4.1)

The scan found 38 texts with "זֶה". 14 of them were wrong or unpointed and are fixed in `tools/author.py` (the source of every new activity). The other 24 are correct ("זֶה" for one masculine thing or for "it", as in "זֶה חָכָם לְבַקֵּשׁ עֶזְרָה", "זֶה הַמִּסְפָּר", "מִצַּד זֶה").

| ID (voice line) | Original | Corrected | What was fixed |
|---|---|---|---|
| vo:flash.dice.1.h3 | זֶה חִפּוּשִׁית אַחַת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַחַת. | זוֹ חִפּוּשִׁית אַחַת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַחַת. | הַצְבָּעָה: "אֵלֶּה" לִרְבִּים, "זוֹ" לְנְקֵבָה בִּיחִיד, "זֶה" לְזָכָר בִּיחִיד |
| vo:flash.dice.2.h3 | זֶה שְׁנֵי כּוֹכָבִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שְׁתַּיִם. | אֵלֶּה שְׁנֵי כּוֹכָבִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שְׁתַּיִם. | הַצְבָּעָה: "אֵלֶּה" לִרְבִּים, "זוֹ" לְנְקֵבָה בִּיחִיד, "זֶה" לְזָכָר בִּיחִיד |
| vo:flash.dice.3.h3 | זֶה שְׁלוֹשָׁה תַּפּוּחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שָׁלוֹשׁ. | אֵלֶּה שְׁלוֹשָׁה תַּפּוּחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שָׁלוֹשׁ. | הַצְבָּעָה: "אֵלֶּה" לִרְבִּים, "זוֹ" לְנְקֵבָה בִּיחִיד, "זֶה" לְזָכָר בִּיחִיד |
| vo:flash.dice.4.h3 | זֶה אַרְבַּע חִפּוּשִׁיּוֹת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַרְבַּע. | אֵלֶּה אַרְבַּע חִפּוּשִׁיּוֹת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַרְבַּע. | הַצְבָּעָה: "אֵלֶּה" לִרְבִּים, "זוֹ" לְנְקֵבָה בִּיחִיד, "זֶה" לְזָכָר בִּיחִיד |
| vo:flash.dice.5.h3 | זֶה חֲמִשָּׁה כּוֹכָבִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל חָמֵשׁ. | אֵלֶּה חֲמִשָּׁה כּוֹכָבִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל חָמֵשׁ. | הַצְבָּעָה: "אֵלֶּה" לִרְבִּים, "זוֹ" לְנְקֵבָה בִּיחִיד, "זֶה" לְזָכָר בִּיחִיד |
| vo:flash.frame.4.h3 | זֶה אַרְבָּעָה תַּפּוּחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַרְבַּע. | אֵלֶּה אַרְבָּעָה תַּפּוּחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אַרְבַּע. | הַצְבָּעָה: "אֵלֶּה" לִרְבִּים, "זוֹ" לְנְקֵבָה בִּיחִיד, "זֶה" לְזָכָר בִּיחִיד |
| vo:flash.frame.5.h3 | זֶה חֲמִשָּׁה דָּגִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל חָמֵשׁ. | אֵלֶּה חֲמִשָּׁה דָּגִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל חָמֵשׁ. | הַצְבָּעָה: "אֵלֶּה" לִרְבִּים, "זוֹ" לְנְקֵבָה בִּיחִיד, "זֶה" לְזָכָר בִּיחִיד |
| vo:flash.scatter.3.h3 | זֶה שָׁלוֹשׁ חִפּוּשִׁיּוֹת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שָׁלוֹשׁ. | אֵלֶּה שָׁלוֹשׁ חִפּוּשִׁיּוֹת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שָׁלוֹשׁ. | הַצְבָּעָה: "אֵלֶּה" לִרְבִּים, "זוֹ" לְנְקֵבָה בִּיחִיד, "זֶה" לְזָכָר בִּיחִיד |
| vo:ordinal.first.correct | כֵּן! זֶה הרִאשׁוֹן בַּתּוֹר. | כֵּן! זֶה הָרִאשׁוֹן בַּתּוֹר. | ה הַיְּדִיעָה נִקְּדָה לְפִי הַמִּלָּה |
| vo:ordinal.first.h3 | הַמָּקוֹם רִאשׁוֹן בַּתּוֹר הוּא חָתוּל. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | זֶה הָרִאשׁוֹן בַּתּוֹר. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | ה הַיְּדִיעָה נִקְּדָה לְפִי הַמִּלָּה |
| vo:ordinal.last.correct | כֵּן! זֶה האַחֲרוֹן בַּתּוֹר. | כֵּן! זֶה הָאַחֲרוֹן בַּתּוֹר. | ה הַיְּדִיעָה נִקְּדָה לְפִי הַמִּלָּה |
| vo:ordinal.last.h3 | הַמָּקוֹם הָאַחֲרוֹן בַּתּוֹר הוּא דָּג. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | זֶה הָאַחֲרוֹן בַּתּוֹר. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | ה הַיְּדִיעָה נִקְּדָה לְפִי הַמִּלָּה |
| vo:ordinal.second.correct | כֵּן! זֶה השֵׁנִי בַּתּוֹר. | כֵּן! זֶה הַשֵּׁנִי בַּתּוֹר. | ה הַיְּדִיעָה נִקְּדָה לְפִי הַמִּלָּה |
| vo:ordinal.second.h3 | הַמָּקוֹם שֵׁנִי בַּתּוֹר הוּא בַּרְוָז. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | זֶה הַשֵּׁנִי בַּתּוֹר. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | ה הַיְּדִיעָה נִקְּדָה לְפִי הַמִּלָּה |
| vo:ordinal.third.correct | כֵּן! זֶה השְׁלִישִׁי בַּתּוֹר. | כֵּן! זֶה הַשְּׁלִישִׁי בַּתּוֹר. | ה הַיְּדִיעָה נִקְּדָה לְפִי הַמִּלָּה |
| vo:ordinal.third.h3 | הַמָּקוֹם שְׁלִישִׁי בַּתּוֹר הוּא כֶּלֶב. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | זֶה הַשְּׁלִישִׁי בַּתּוֹר. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | ה הַיְּדִיעָה נִקְּדָה לְפִי הַמִּלָּה |
| vo:ordinal.third.of4.correct | כֵּן! זֶה השְׁלִישִׁי בַּתּוֹר. | כֵּן! זֶה הַשְּׁלִישִׁי בַּתּוֹר. | ה הַיְּדִיעָה נִקְּדָה לְפִי הַמִּלָּה |
| vo:ordinal.third.of4.h3 | הַמָּקוֹם שְׁלִישִׁי בַּתּוֹר הוּא חָתוּל. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | זֶה הַשְּׁלִישִׁי בַּתּוֹר. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו. | ה הַיְּדִיעָה נִקְּדָה לְפִי הַמִּלָּה |
| vo:show.apples.3.correct | כֵּן! זֶה שְׁלוֹשָׁה תַּפּוּחִים. | כֵּן! אֵלֶּה שְׁלוֹשָׁה תַּפּוּחִים. | הַצְבָּעָה: "אֵלֶּה" לִרְבִּים, "זוֹ" לְנְקֵבָה בִּיחִיד, "זֶה" לְזָכָר בִּיחִיד |
| vo:show.apples.3.h3 | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. זֶה שְׁלוֹשָׁה תַּפּוּחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. אֵלֶּה שְׁלוֹשָׁה תַּפּוּחִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | הַצְבָּעָה: "אֵלֶּה" לִרְבִּים, "זוֹ" לְנְקֵבָה בִּיחִיד, "זֶה" לְזָכָר בִּיחִיד |
| vo:show.birds.4.correct | כֵּן! זֶה אַרְבַּע צִפֳּרִים. | כֵּן! אֵלֶּה אַרְבַּע צִפֳּרִים. | הַצְבָּעָה: "אֵלֶּה" לִרְבִּים, "זוֹ" לְנְקֵבָה בִּיחִיד, "זֶה" לְזָכָר בִּיחִיד |
| vo:show.birds.4.h3 | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. זֶה אַרְבַּע צִפֳּרִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. אֵלֶּה אַרְבַּע צִפֳּרִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | הַצְבָּעָה: "אֵלֶּה" לִרְבִּים, "זוֹ" לְנְקֵבָה בִּיחִיד, "זֶה" לְזָכָר בִּיחִיד |
| vo:show.stars.5.correct | כֵּן! זֶה חֲמִשָּׁה כּוֹכָבִים. | כֵּן! אֵלֶּה חֲמִשָּׁה כּוֹכָבִים. | הַצְבָּעָה: "אֵלֶּה" לִרְבִּים, "זוֹ" לְנְקֵבָה בִּיחִיד, "זֶה" לְזָכָר בִּיחִיד |
| vo:show.stars.5.h3 | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. זֶה חֲמִשָּׁה כּוֹכָבִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. אֵלֶּה חֲמִשָּׁה כּוֹכָבִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה. | הַצְבָּעָה: "אֵלֶּה" לִרְבִּים, "זוֹ" לְנְקֵבָה בִּיחִיד, "זֶה" לְזָכָר בִּיחִיד |

*Also found while checking:* the article of the ordinals was written without its niqqud ("זֶה הרִאשׁוֹן"); it is now "הָרִאשׁוֹן", "הַשֵּׁנִי", "הַשְּׁלִישִׁי", "הָאַחֲרוֹן". The ordinal hint also said "הַמָּקוֹם שְׁלִישִׁי בַּתּוֹר הוּא כֶּלֶב", which is not Hebrew; it now says "זֶה הַשְּׁלִישִׁי בַּתּוֹר".

Number and noun agreement ("שְׁלוֹשָׁה תַּפּוּחִים", "שָׁלוֹשׁ חִפּוּשִׁיּוֹת", the numeral tile "שָׁלוֹשׁ") was already as Gemini describes and needed no change.

## 2. Variables in the text

All 30 texts with `{child}`, `{n}`, `{how}`, `{t}` and the like are **screens for adults or the child's own name bubble** (`app/lib/strings/he.dart`). None of them is ever voiced: no line that goes to ElevenLabs holds a variable, by the rule in CLAUDE.md (the model and the voice never see a name, except the one the owner allowed: the child's first name inside a line to be voiced, which no line has yet). So no placeholder name is needed for the voice generation today. The daily welcome by name (a later idea in `PROGRESS.md`) will need it, and will use the child's real first name.

## 3. Exclamation marks and the voice text

223 texts hold "!"; 211 of them are spoken lines (core lines, lessons, helper lines). Of those, 6 are celebrations and ceremonies, which already use the "cheer" voice style you asked for (stability 0.1, style 0.9) and should keep their energy.

The rest are praise in the middle of a lesson ("שָׁלוֹשׁ! זֶה הַמִּסְפָּר."), where a full-strength "!" can sound too loud.

**Proposal, not applied yet** (because the voices were approved and a change costs money): keep the screen text as it is and add a separate *voice text* next to each spoken line, used only for generation, with (a) the first "!" of a lesson line turned into a comma or a period, (b) a short pause (a comma) after the number or the "כֵּן", and (c) partial nikud on the ambiguous words only. Before changing 300 lines, an audition of four lines in both versions costs a few cents.

| Line | Now | Suggested voice text |
|---|---|---|
| vo:numeral.stars.3.correct | שָׁלוֹשׁ! זֶה הַמִּסְפָּר. | שלוש, זה המספר. |
| vo:next.after.2.correct | שָׁלוֹשׁ! כָּךְ סוֹפְרִים. | שלוש. כָּךְ סוֹפְרִים. |
| vo:flash.dice.3.correct | שָׁלוֹשׁ! רְאִיתֶם בְּלִי לִסְפֹּר. | שלוש, ראיתם בלי לספור. |
| vo:celebrate.giving | כׇּל הַכָּבוֹד! נְתַתֶּם בְּדִיּוּק כַּמָּה שֶׁבִּקְשׁוּ. | (unchanged: a celebration keeps its "!") |
