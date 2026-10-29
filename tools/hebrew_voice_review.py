"""Reads docs/review/hebrew-review.csv and writes docs/review/hebrew-master.csv (one row for every text of the app) and
docs/review/hebrew-elevenlabs-review.md and .csv (only the rows that changed or are spoken, deduplicated):

  * the corrected text for the screen (same nikud style as the original): demonstratives, number and noun gender,
    שְׁתֵּי / שְׁנֵי before a noun, the conjunctive vav, pointing, and the phrase decisions of the Hebrew text editor
    (`SUBS`, `MANUAL`, `TUTOR_SUBS`; the reasons are in docs/agents/hebrew-notes.md);
  * for every spoken text, the voice text for ElevenLabs: softer punctuation, partial nikud (number words keep theirs),
    full spelling (ktiv male) for the other words, no curly-bracket variables (`VOICE_SUBS`, `VOICE_MANUAL`);
  * the status: `text-ready` for the rows the text editor reviewed and is sure of (`REVIEWED`), `proposed` with a
    comment for the rows that wait for the owner (`DOUBT`) and for new rows the editor has not signed (`PENDING`).

    PYTHONIOENCODING=utf-8 python tools/hebrew_voice_review.py

Nothing is written back to the pack: the owner decides which rows to take. What the owner typed in the master table
(the `correction (fill in)` and `comment` columns, and any status after `text-ready`) is kept. The editor's own comments
start with "[editor]" and are rewritten on every run.
"""
import csv
import os
import re
import sys
import unicodedata

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.argv = sys.argv[:1] + ['-']
from author import F, M  # noqa: E402
from band_b import NAMES, OBJECTS  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
SRC = os.path.join(ROOT, 'docs', 'review', 'hebrew-review.csv')
NIKUD = re.compile('[\u0591-\u05c7]')
TOKEN = re.compile(r"[\u0590-\u05ff'\"״׳]+|[^\u0590-\u05ff]+")
HE_WORD = re.compile(r"[\u0590-\u05ff]")
HE_LETTER = re.compile(r"[\u05d0-\u05ea]")

SHVA, HIRIQ, HOLAM, HOLAM_H, QUBUTS, DAGESH, QATAN = '\u05b0', '\u05b4', '\u05b9', '\u05ba', '\u05bb', '\u05bc', '\u05c7'
VOWELS = set('\u05b1\u05b2\u05b3\u05b4\u05b5\u05b6\u05b7\u05b8\u05b9\u05ba\u05bb\u05c7')


def plain(s):
    return NIKUD.sub('', s)


def canon(s):
    """Marks in their canonical order (vowel, dagesh, shin dot), as every text of the pack has them."""
    out, marks = [], []
    for c in s:
        if NIKUD.match(c):
            marks.append(c)
        else:
            out.extend(sorted(marks, key=unicodedata.combining))
            marks = []
            out.append(c)
    out.extend(sorted(marks, key=unicodedata.combining))
    return ''.join(out)


def clusters(tok):
    out = []
    for c in tok:
        if NIKUD.match(c) and out:
            out[-1][1] += c
        else:
            out.append([c, ''])
    return out


# ---------------------------------------------------------------- words that matter for gender
NUM_WORDS = set()
for _n in list(range(0, 21)) + list(range(30, 101, 10)):
    for _t in (F[_n], M[_n] if _n else F[0]):
        NUM_WORDS.update(_t.split())
NUM_WORDS.update(['שְׁנֵי', 'שְׁתֵּי', 'שְׁלֹשׁ', 'שְׁבַע', 'תְּשַׁע', 'שְׁנֵים', 'שְׁתֵּים', 'אַחַד', 'מֵאָה', 'מָאתַיִם'])
M_ONLY = {'אֶחָד', 'שְׁלוֹשָׁה', 'אַרְבָּעָה', 'חֲמִשָּׁה', 'שִׁשָּׁה', 'שִׁבְעָה', 'שְׁמוֹנָה', 'תִּשְׁעָה', 'עֲשָׂרָה', 'שְׁנֵי', 'שְׁנַיִם'}
F_ONLY = {'אַחַת', 'שָׁלוֹשׁ', 'אַרְבַּע', 'חָמֵשׁ', 'שֵׁשׁ', 'שֶׁבַע', 'תֵּשַׁע', 'עֶשֶׂר', 'שְׁתֵּי', 'שְׁתַּיִם'}

FEM_PL = {'חִפּוּשִׁיּוֹת', 'צִפֳּרִים', 'צִפּוֹרִים', 'צְלָעוֹת', 'צַלָּחוֹת', 'קֻבִּיּוֹת', 'אֶצְבָּעוֹת', 'צוּרוֹת', 'פְּעָמִים',
          'אֲבָנִים', 'נוֹצוֹת', 'מַדְבֵּקוֹת', 'תְּמוּנוֹת', 'דְּרָכִים', 'אֲגוֹרוֹת', 'קְבוּצוֹת', 'נְקֻדּוֹת', 'שָׁעוֹת'}
MASC_PL = {'תַּפּוּחִים', 'דָּגִים', 'כּוֹכָבִים', 'בַּרְוָזִים', 'צְעָדִים', 'מִגְדָּלִים', 'מִסְפָּרִים', 'מַטְבְּעוֹת', 'מַקְלוֹת',
           'כַּדּוּרִים', 'בָּלוֹנִים', 'פְּרָחִים', 'דְּבָרִים', 'פַּרְפָּרִים', 'צְדָדִים', 'שְׁקָלִים', 'גַּרְבַּיִם', 'עִגּוּלִים',
           'רִבּוּעִים', 'מְשֻׁלָּשִׁים', 'חֲלָקִים', 'חֲתוּלִים', 'כְּלָבִים'}
FEM_SG, MASC_SG = set(), set()
for _o in OBJECTS.values():
    (FEM_PL if _o['g'] == 'f' else MASC_PL).add(_o['many'])
    (FEM_SG if _o['g'] == 'f' else MASC_SG).add(_o['one'])
for _o in NAMES.values():
    (FEM_SG if _o['g'] == 'f' else MASC_SG).add(_o['one'])
FEM_SG -= {'כַּדּוּר', 'כֵּן', 'לֹא', 'גֶּרֶב'}
MASC_SG -= {'כֵּן', 'לֹא'}
FEM_PL.discard('גַּרְבַּיִם')
FEM_SG |= {'צִפּוֹר', 'צַלַּחַת', 'קֻבִּיָּה', 'חִפּוּשִׁית', 'בָּנָנָה', 'כַּף', 'מִשְׁחָה', 'נַעַל', 'פִּירָמִידָה', 'תֵּבָה',
           'מַגֶּבֶת', 'מִבְרֶשֶׁת', 'מַדֵּלְיָה', 'צוּרָה', 'תְּמוּנָה'}
MASC_SG |= {'גֶּרֶב'}


def unprefixed(tok):
    """A word without its pointed one-letter prefixes (the article, וְ, בְּ, לְ, מִ, שֶׁ), for a list look-up."""
    for p in ('וּבַ', 'וְהַ', 'הַ', 'הָ', 'הֶ', 'וְ', 'וּ', 'וַ', 'בַּ', 'בְּ', 'לַ', 'לְ', 'לָ', 'מִ', 'מֵ', 'שֶׁ', 'כְּ'):
        if tok.startswith(p) and len(tok) > len(p) + 1:
            return tok[len(p):]
    return tok


# ---------------------------------------------------------------- the editor's decisions (docs/agents/hebrew-notes.md)
# Whole texts: the original text -> (the corrected text, why). The generic rules below still run on the result.
MANUAL = {
    'יותר מדי נסיונות. אפשר לנסות שוב בעוד {m} דקות.': ('יותר מדי ניסיונות. אפשר לנסות שוב בעוד {m} דקות.', 'spelling: ניסיונות'),
    'בקרוב, כשיהיו באי מספיק מיומנויות': ('בקרוב, כשיהיו מספיק מיומנויות באי', 'clarity: "באי מספיק" reads as "not enough"; reordered so it is read as "on the island"'),
    'ההתראות לא מוצגות בצד של הילדים, והאפליקציה אף פעם לא מוכיחה אותם.': (
        'ההתראות לא מוצגות בצד של הילדים, והאפליקציה אף פעם לא נוזפת בהם.', 'word: "מוכיחה" can read as "proves"; "נוזפת" is the intended "scolds"'),
    'אֵין כְּלוּם זֶה אֶפֶס': ('אֵין כְּלוּם — זֶה אֶפֶס', 'pacing: a dash before the answer'),
    'זכו בגביע שהובטחה עליו הבטחה': ('זכו בגביע שיש עליו הבטחה', 'style: "שהובטחה עליו הבטחה" is heavy; same meaning'),
    'ביום שמוגדרות בו שעות משחקים רק בהן. ביום בלי שעות משחקים בכל שעה.': (
        'ביום שהוגדרו לו שעות, אפשר לשחק רק בהן. ביום בלי שעות אפשר לשחק בכל שעה.',
        'clarity: "משחקים" reads as "games"; the rule is said with "אפשר לשחק"'),
    'כשהזמן נגמר או בשעות מנוחה לא מוצעת פעילות חדשה, והפעילות הנוכחית מסתיימת בעדינות. כשכבוי הילד ממשיך לשחק.': (
        'כשהזמן נגמר או בשעות מנוחה לא מוצעת פעילות חדשה, והפעילות הנוכחית מסתיימת בעדינות. כשכבוי, הילד ממשיך לשחק.',
        'punctuation: a comma after "כשכבוי"'),
    'לֹא שָׁמַעְתִּי טוֹב — אֶפְשָׁר שׁוּב? אוֹ לִלְחֹץ.': (
        'לֹא שָׁמַעְתִּי טוֹב — אֶפְשָׁר לְהַגִּיד שׁוּב, אוֹ לִלְחֹץ עַל הַתְּשׁוּבָה.',
        'syntax: "אֶפְשָׁר שׁוּב? אוֹ לִלְחֹץ." is two fragments; one whole sentence, same offer'),
    # lesson content (misconception lines, skill titles, parent texts)
    'יוֹתֵר לֹא תָּמִיד אוֹמֵר גָּדוֹל יוֹתֵר. בּוֹאוּ נַשְׁוֶה אֶחָד אֶחָד.': (
        'מָה שֶׁתּוֹפֵס יוֹתֵר מָקוֹם לֹא תָּמִיד יֵשׁ בּוֹ יוֹתֵר. בּוֹאוּ נַשְׁוֶה אֶחָד אֶחָד.',
        'sense: the line said "more does not always mean bigger"; the misconception (M-CNT-SIZE) is the reverse: what looks bigger is not always more'),
    'צוּרָה סְגוּרָה אֵין בָּהּ פֶּתַח, וְהַצְּלָעוֹת שֶׁלָּהּ יְשָׁרוֹת. בּוֹאוּ נִבְדֹּק.': (
        'לְצוּרָה סְגוּרָה אֵין פֶּתַח. וְצָרִיךְ גַּם שֶׁכׇּל הַצְּלָעוֹת יִהְיוּ יְשָׁרוֹת. בּוֹאוּ נִבְדֹּק.',
        'sense and syntax: a closed shape need not have straight sides (a circle); the two checks are said apart, as the question asks them'),
    'הַמָּקוֹם בַּתּוֹר אֵינוֹ כַּמָּה יֵשׁ. בּוֹאוּ נִסְפֹּר מֵהַהַתְחָלָה.': (
        'הַמָּקוֹם בַּתּוֹר הוּא לֹא כַּמָּה יֵשׁ. בּוֹאוּ נִסְפֹּר מֵהַהַתְחָלָה.', 'register: "אֵינוֹ" is written Hebrew; "הוּא לֹא" for a child'),
    'שׁוֹקְלִים עַל מֹאזְנַיִם': ('שוקלים על מאזניים', 'register: a skill title is a parent text, without nikud'),
    'שָׁוֶה זה אותו דבר': ('"שווה" זה אותו דבר', 'register: a skill title is a parent text, without nikud; the sign name in quotes'),
    'להסתיר חמש מטבעות בכף יד סגורה, ולהוסיף עוד שלושה אחד אחד: חמש… שש, שבע, שמונה.': (
        'להסתיר חמישה מטבעות בכף יד סגורה, ולהוסיף עוד שלושה אחד אחד: חמש… שש, שבע, שמונה.',
        'gender: מטבע is masculine (חמישה מטבעות); the counting stays feminine'),
    'להניח שלוש חרוזים או כפתורים בסדר מסוים ולבקש מהילד להניח מתחתם את אותו סדר, אחד מתחת לאחד. לשים אצבע על כל זוג.': (
        'להניח שלושה חרוזים או כפתורים בסדר מסוים ולבקש מהילד להניח מתחתם את אותו סדר, אחד מתחת לאחד. לשים אצבע על כל זוג.',
        'gender: חרוז is masculine (שלושה חרוזים)'),
    'הילד קורא את סימן השוויון כ"עכשיו מחשבים", ולכן 7 = 3 + 4 נראה לו הפוך.': (
        'הילד קורא את סימן השוויון כ"עכשיו מחשבים", ולכן ⁦7 = 3 + 4⁩ נראה לו הפוך.',
        'bidi: the sum is isolated left to right (U+2066 … U+2069); in a right-to-left line it showed as "4 + 3 = 7", the reverse of the example'),
    'לשחק בחנות עם מטבעות: לשלם שלושה שקלים פעם עם מטבעות של שקל ופעם עם מטבע של שתיים ומטבע של שקל, ולהשוות.': (
        'לשחק בחנות עם מטבעות: לשלם שלושה שקלים פעם עם מטבעות של שקל ופעם עם מטבע של שני שקלים ומטבע של שקל, ולהשוות.',
        'word: the coin is "מטבע של שני שקלים"'),
}

# Phrase rules on pointed text: (pattern, replacement, why). Patterns are matched on whole words.
B = r'(?<![\u0590-\u05ff])'   # word start
E = r'(?![\u0590-\u05ff])'    # word end
SUBS = [
    # pointing
    (B + 'כָּל' + E, 'כׇּל', 'nikud: כׇּל with a qamatz qatan, as in the rest of the pack'),
    (r'(?<=[ְּ])כָל' + E, 'כׇל', 'nikud: כׇל with a qamatz qatan, as in the rest of the pack'),
    (B + 'הַכִּי' + E, 'הֲכִי', 'nikud: הֲכִי'),
    (B + 'מִאַחַת' + E, 'מֵאַחַת', 'nikud: מֵ before a guttural (מֵאַחַת)'),
    (B + 'בעֶשֶׂר' + E, 'בְּעֶשֶׂר', 'nikud: the prefix בְּ was not pointed'),
    (B + 'תוֹךְ' + E, 'תּוֹךְ', 'nikud: a dagesh in the first ת (תּוֹךְ)'),
    (B + 'מְאוּחָר' + E, 'מְאֻחָר', 'nikud: מְאֻחָר (qubuts, as the pack points other words)'),
    (B + 'עֲצְרוּ כְּשֶׁהִגַּעְנוּ אֶל' + E, 'עוֹצְרִים כְּשֶׁמַּגִּיעִים אֶל',
     'grammar: "עֲצְרוּ" is mispointed and "כְּשֶׁהִגַּעְנוּ" is the wrong tense; said like the other steps (עוֹצְרִים כְּשֶׁמַּגִּיעִים)'),
    (B + 'לִשְׁלוֹשׁ' + E, 'לְשָׁלוֹשׁ', 'nikud: לְשָׁלוֹשׁ (the prefix before שָׁלוֹשׁ)'),
    (B + 'מִאֶפֶס' + E, 'מֵאֶפֶס', 'nikud: מֵ before a guttural (מֵאֶפֶס)'),
    (B + 'מִהַ', 'מֵהַ', 'nikud: מֵ before a guttural (מֵהַ)'),
    (B + 'בשְׁתַּיִם' + E, 'בִּשְׁתַּיִם', 'nikud: the prefix בִּ was not pointed'),
    (B + 'בְּהֲגִינוּת' + E, 'בַּהֲגִינוּת', 'nikud: בַּ before a hataf patah (בַּהֲגִינוּת)'),
    (B + '(הַ)?שְּׂמֹאלִי' + E, r'\1שְּׂמָאלִי', 'nikud: שְׂמָאלִי ("smali"); שְׂמֹאלָה stays'),
    (B + 'שְׂמֹאלִי' + E, 'שְׂמָאלִי', 'nikud: שְׂמָאלִי ("smali"); שְׂמֹאלָה stays'),
    (B + 'מַסְדִּירִים' + E, 'מְסַדְּרִים', 'word: putting in order is "מְסַדְּרִים" ("מַסְדִּירִים" is "regulate")'),
    (B + 'הַתָּכְנִית' + E, 'הַתׇּכְנִית', 'nikud: תׇּכְנִית with a qamatz qatan (read "tochnit")'),
    (B + 'תָּכְנִית' + E, 'תׇּכְנִית', 'nikud: תׇּכְנִית with a qamatz qatan (read "tochnit")'),
    # words
    (B + 'נַחֲזִיק אֶצְבָּעוֹת' + E, 'נָרִים אֶצְבָּעוֹת', 'word: "נַחֲזִיק אֶצְבָּעוֹת" means "wish luck"; fingers to count on are raised (נָרִים אֶצְבָּעוֹת)'),
    (B + 'נַחֲלֹק לְזוּגוֹת' + E, 'נְחַלֵּק לְזוּגוֹת', 'word: dividing into pairs is "נְחַלֵּק" ("נַחֲלֹק" is sharing)'),
    (B + 'כֻּלָּם בַּזּוּגוֹת' + E, 'כֻּלָּם בְּזוּגוֹת', 'syntax: "כֻּלָּם בְּזוּגוֹת" (in pairs)'),
    (B + 'לָזֶה, בַּתּוֹר' + E, 'לָזֶה, לְפִי הַתּוֹר', 'word: taking turns is "לְפִי הַתּוֹר" ("בַּתּוֹר" is "in the queue")'),
    (B + 'סוֹפְרִים תּוֹךְ כְּדֵי שֶׁלּוֹקְחִים' + E, 'סוֹפְרִים בִּזְמַן שֶׁלּוֹקְחִים', 'vocabulary: "בִּזְמַן שֶׁ" for a young child ("תּוֹךְ כְּדֵי" is adult register)'),
    (r'(מִגְדָּל[^.!?]*?)מִקּוֹדְמוֹ' + E, r'\1מֵהַמִּגְדָּל שֶׁלְּפָנָיו', 'vocabulary: "מִקּוֹדְמוֹ" is literary; "מֵהַמִּגְדָּל שֶׁלְּפָנָיו"'),
    (r'(מִסְפָּר[^.!?]*?)מִקּוֹדְמוֹ' + E, r'\1מֵהַמִּסְפָּר שֶׁלְּפָנָיו', 'vocabulary: "מִקּוֹדְמוֹ" is literary; "מֵהַמִּסְפָּר שֶׁלְּפָנָיו"'),
    (B + 'צָרִיךְ שֶׁגַּם לֹא (\S+) וְגַם לֹא' + E, r'מְחַפְּשִׂים מַשֶּׁהוּ שֶׁהוּא לֹא \1 וְגַם לֹא',
     'syntax: "צָרִיךְ שֶׁגַּם לֹא…" has no subject; "מְחַפְּשִׂים מַשֶּׁהוּ שֶׁהוּא לֹא… וְגַם לֹא…"'),
    (B + '(הַפִּירָמִידָה|הַתֵּבָה) — נִסְתַּכֵּל עַל הַצּוּרָה שֶׁלּוֹ' + E, r'\1 — נִסְתַּכֵּל עַל הַצּוּרָה שֶׁלָּהּ',
     'gender: פִּירָמִידָה and תֵּבָה are feminine (שֶׁלָּהּ)'),
    (B + 'צִפּוֹר שׁוֹנָה מֵהָאֲחֵרִים\. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו', 'הַצִּפּוֹר שׁוֹנָה מֵהָאֲחֵרִים. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלֶיהָ',
     'gender: a bird is pressed with עָלֶיהָ; the article as in the other lines'),
    (B + 'בָּלוֹן אָדֹם שׁוֹנֶה מֵהָאֲחֵרִים', 'הַבָּלוֹן הָאָדֹם שׁוֹנֶה מֵהָאֲחֵרִים', 'syntax: the article (the one on the screen), as in "הַכַּדּוּר הַכָּחֹל שׁוֹנֶה"'),
    (B + 'תַּפּוּחַ שׁוֹנֶה מֵהָאֲחֵרִים', 'הַתַּפּוּחַ שׁוֹנֶה מֵהָאֲחֵרִים', 'syntax: the article (the one on the screen), as in "הַכַּדּוּר הַכָּחֹל שׁוֹנֶה"'),
    (B + 'קְעָרָה וְכַּ?ף הוֹלְכִים יַחַד' + E, 'קְעָרָה וְכַף הוֹלְכוֹת יַחַד', 'agreement: קְעָרָה and כַּף are both feminine (הוֹלְכוֹת)'),
    (B + 'גֶּרֶב וְנַעַל הוֹלְכוֹת יַחַד' + E, 'גֶּרֶב וְנַעַל הוֹלְכִים יַחַד', 'agreement: גֶּרֶב is masculine, so the pair is הוֹלְכִים'),
    (B + 'הָעַמּוּד הַגָּבוֹהַּ הוּא הֲכִי הַרְבֵּה' + E, 'בָּעַמּוּד הַגָּבוֹהַּ יֵשׁ הֲכִי הַרְבֵּה', 'syntax: a column "has" the most (בָּעַמּוּד… יֵשׁ)'),
    (B + 'הָעַמּוּד הַנָּמוּךְ הוּא הֲכִי פָּחוֹת' + E, 'בָּעַמּוּד הַנָּמוּךְ יֵשׁ הֲכִי מְעַט', 'syntax: a column "has" the least (בָּעַמּוּד… יֵשׁ הֲכִי מְעַט)'),
    # pointing of single words
    (B + '(מְ|מָ)צָאתֶם' + E, 'מְצָאתֶם', 'nikud: מְצָאתֶם'),
    (B + 'נָתַתֶּם' + E, 'נְתַתֶּם', 'nikud: נְתַתֶּם'),
    (B + 'נָחַתֶּם' + E, 'נְחַתֶּם', 'nikud: נְחַתֶּם'),
    (B + 'מְאוֹד' + E, 'מְאֹד', 'nikud: מְאֹד, as everywhere else in the pack'),
    (B + 'לְשָׁתֵּי' + E, 'לִשְׁתֵּי', 'nikud: לִשְׁתֵּי'),
    (B + 'מַשְׁווִים' + E, 'מַשְׁוִים', 'nikud: מַשְׁוִים (one vav)'),
    (B + 'לְהַשְׁוֹת' + E, 'לְהַשְׁווֹת', 'nikud: לְהַשְׁווֹת'),
    (B + '(הַ|בְּ|בַּ)?(חַלְלִית|חַלָּלִית)' + E, r'\1חֲלָלִית', 'nikud: חֲלָלִית'),
    (B + 'הַרוֹבּוֹט' + E, 'הָרוֹבּוֹט', 'nikud: the article before ר is הָ'),
    (B + 'הַעֲשָׂרוֹת' + E, 'הָעֲשָׂרוֹת', 'nikud: the article before עֲ is הָ'),
    (B + 'כֻּל דָּבָר' + E, 'כׇּל דָּבָר', 'nikud: כׇּל'),
    (B + 'הַטָּעוּיוֹת' + E, 'הַטָּעֻיּוֹת', 'nikud: הַטָּעֻיּוֹת'),
    (B + 'כַּמָּה חָסַר\?', 'כַּמָּה חָסֵר?', 'nikud: חָסֵר (present tense)'),
    (B + 'מַסְתַּכְּלִים' + E, 'מִסְתַּכְּלִים', 'nikud: מִסְתַּכְּלִים'),
    (B + 'סִימָן הַ-שָׁוֶה אוֹמֵר: שְׁנֵי הַצְּדָדִים אוֹתוֹ דָּבָר', 'סִימַן הַשָּׁוֶה אוֹמֵר: בִּשְׁנֵי הַצְּדָדִים יֵשׁ אוֹתוֹ מִסְפָּר',
     'spelling and sense: "סִימַן הַשָּׁוֶה" (one word, construct); "=" says both sides have the same number'),
    # words
    (B + 'נִפְרֹד אֶת הָעֶשֶׂר' + E, 'נַפְרִיד אֶת הָעֶשֶׂר', 'word: "נִפְרֹד" is "say goodbye"; taking the ten apart is "נַפְרִיד"'),
    (B + 'לְכׇל חָבֵר בַּתּוֹר' + E, 'לְכׇל חָבֵר לְפִי הַתּוֹר', 'word: taking turns is "לְפִי הַתּוֹר" ("בַּתּוֹר" is "in the queue")'),
    (B + 'סוֹדְרִים' + E, 'מְסַדְּרִים', 'word: putting in order is "מְסַדְּרִים"'),
    (B + 'עֵרַבְתֶּם' + E, 'עִרְבַּבְתֶּם', 'word: "עִרְבַּבְתֶּם" (you mixed), the word children use'),
    (B + 'פִּתַּחְתֶּם חִידָּה' + E, 'פְּתַרְתֶּם חִידָה', 'word: a riddle is solved (פְּתַרְתֶּם); "פִּתַּחְתֶּם" is "developed"; nikud חִידָה'),
    (B + 'הִבְחַנְתֶּם בִּצְלָעוֹת יְשָׁרוֹת' + E, 'שַׂמְתֶּם לֵב לִצְלָעוֹת הַיְשָׁרוֹת', 'vocabulary: "שַׂמְתֶּם לֵב" for a child ("הִבְחַנְתֶּם" is adult register)'),
    (B + 'הַמַּחֲוָג הַקָּצָר אוֹמֵר\.', 'הַמַּחֲוָג הַקָּצָר אוֹמֵר אֶת הַשָּׁעָה.', 'syntax: the sentence was cut ("אוֹמֵר" needs its object)'),
    (B + 'עוֹד חֲבֵרִים צוּרוֹת' + E, 'מַכִּירִים עוֹד צוּרוֹת', 'syntax: "חֲבֵרִים צוּרוֹת" is not Hebrew; the title says the activity'),
    (B + 'חֲבֵרִים צוּרוֹת' + E, 'מַכִּירִים צוּרוֹת', 'syntax: "חֲבֵרִים צוּרוֹת" is not Hebrew; the title says the activity'),
    (B + 'עֲשָׂרוֹת וּזְוּגוֹת' + E, 'עֲשָׂרוֹת וְזוּגוֹת', 'nikud: וְזוּגוֹת'),
    (B + 'סְפַרְתֶּם בַּקְּפִיצוֹת' + E, 'סְפַרְתֶּם בִּקְפִיצוֹת', 'syntax: "בִּקְפִיצוֹת" (in jumps)'),
    (B + 'עוֹד לְפָנֶיךָ עֶשְׂרִים' + E, 'עוֹד עַד עֶשְׂרִים', 'address: "לְפָנֶיךָ" speaks to one boy; the title is "עוֹד עַד עֶשְׂרִים", like "עַד עֶשְׂרִים"'),
    (B + 'מְעַקְבִים צוּרוֹת' + E, 'עוֹקְבִים אַחֲרֵי צוּרוֹת', 'word: "מְעַקְבִים" is not a word; "עוֹקְבִים אַחֲרֵי"'),
    (B + 'עִקַּבְתֶּם אַחֲרֵי' + E, 'עֲקַבְתֶּם אַחֲרֵי', 'word: "עֲקַבְתֶּם אַחֲרֵי" (you followed); "עִקַּבְתֶּם" is "you delayed"'),
    (B + 'גָּדוֹל, קָצָר, כָּבֵד' + E, 'גָּדוֹל, אָרֹךְ, כָּבֵד', 'sense: the lesson is big, long and heavy (and their opposites)'),
    (B + 'לְכׇל אֶחָד אוֹתוֹ דָּבָר' + E, 'לְכׇל אֶחָד אוֹתוֹ מִסְפָּר', 'sense: a fair share is "the same number", as the lessons say'),
    (B + 'מוֹצְאִים מִסְפָּר שֶׁחָסֵר וּבְאֶחָד יוֹתֵר' + E, 'מוֹצְאִים מִסְפָּר שֶׁחָסֵר, אֶחָד יוֹתֵר וְאֶחָד פָּחוֹת',
     'syntax: "וּבְאֶחָד יוֹתֵר" was cut; the skill is the missing number, one more and one less'),
    (B + 'זֶה הוּא! הַפֶּרַח הָאָדֹם' + E, 'הִנֵּה הוּא! הַפֶּרַח הָאָדֹם', 'style: "הִנֵּה הוּא!"'),
    (B + 'אֶפְשָׁר: ', '', 'syntax: "אֶפְשָׁר:" before the sum has no verb; the sum says it'),
    (B + 'כֵּן! הַ(מְ\S+) יֵשׁ לוֹ' + E, r'כֵּן! לַ\1 יֵשׁ', 'syntax: "לַמְּשֻׁלָּשׁ יֵשׁ…" (not "הַמְּשֻׁלָּשׁ יֵשׁ לוֹ")'),
    (B + '(בְּ(?:חִפּוּשִׁית|צִפּוֹר)) אֶחָד' + E, r'\1 אַחַת', 'gender: חִפּוּשִׁית and צִפּוֹר are feminine (אַחַת)'),
    (B + 'זוֹ גֶּרֶב' + E, 'זֶה גֶּרֶב', 'gender: גֶּרֶב is masculine (זֶה גֶּרֶב, גֶּרֶב אֶחָד)'),
    (B + 'הַחֲפָצִים' + E, 'הַדְּבָרִים', 'vocabulary: "הַדְּבָרִים" for a young child ("חֲפָצִים" is adult register)'),
    (B + 'מְעַקְבִים בָּאֶצְבַּע' + E, 'עוֹקְבִים בָּאֶצְבַּע', 'word: "מְעַקְבִים" is not a word; tracing is "עוֹקְבִים בָּאֶצְבַּע אַחֲרֵי"'),
    (B + 'מַכְוִינִים' + E, 'מְכַוְּנִים', 'word: a clock is set with "מְכַוְּנִים" (מַכְוִינִים is "guide")'),
    (B + 'אוֹמֵר הַמֹּאזְנַיִם' + E, 'אוֹמְרִים הַמֹּאזְנַיִם', 'agreement: הַמֹּאזְנַיִם is plural (אוֹמְרִים)'),
    (B + 'אוֹ שֶׁהֵם שָׁווֹת' + E, 'אוֹ שֶׁהֵם שָׁוִים', 'agreement: הֵם (the sides) takes שָׁוִים'),
    (B + 'הַמֹּאזְנַיִם שָׁווֹת\.', 'הַמֹּאזְנַיִם מְאֻזָּנִים.', 'sense and agreement: scales are "מְאֻזָּנִים" (balanced), not "שָׁווֹת"'),
    (B + 'עַד שֶׁהַמֹּאזְנַיִם שָׁווֹת' + E, 'עַד שֶׁשְּׁנֵי הַצְּדָדִים שָׁוִים',
     'agreement and sense: the scales are not "שָׁווֹת"; the two sides are equal (שְׁנֵי הַצְּדָדִים שָׁוִים)'),
    (B + 'אֶחָד שָׂחָה לְהֵרָחֵק' + E, 'אֶחָד שָׂחָה מִשָּׁם', 'word: "שָׂחָה לְהֵרָחֵק" is not Hebrew; "swam away" is "שָׂחָה מִשָּׁם"'),
    (B + 'אֵיזוֹ תְּמוּנָה הִיא' + E, 'אֵיזוֹ תְּמוּנָה מַרְאָה', 'sense: a picture "shows" the evening (מַרְאָה), it is not the evening'),
    (B + 'אַחֶרֶת — ', 'אִם לֹא — ', 'vocabulary: "אַחֶרֶת" is school register; "אִם לֹא" for ages 3 to 6'),
    (B + 'אִם הַצּוּרָה (עִגּוּל|רִבּוּעַ|מְשֻׁלָּשׁ|מַלְבֵּן),', r'אִם הַצּוּרָה הִיא \1,', 'syntax: "אִם הַצּוּרָה הִיא עִגּוּל" (a noun after a noun needs הִיא)'),
    (B + 'הַאִם ', '', 'vocabulary: "הַאִם" is written register; a spoken yes-no question needs no word for it'),
    (B + 'וְלוֹחֲצִים עַל הַ-וִי' + E, 'וְלוֹחֲצִים עַל הַוִּי', 'spelling: הַוִּי (the tick button) is one word, no hyphen'),
    (B + 'שֶׁעַל הַגּוּף' + E, 'שֶׁיֵּשׁ עָלָיו', 'style: "לַצּוּרָה הַשְּׁטוּחָה שֶׁיֵּשׁ עָלָיו" says the solid once'),
    (B + 'אֵיזֶה יֵשׁ הֲכִי הַרְבֵּה\?', 'מִמָּה יֵשׁ הֲכִי הַרְבֵּה?', 'syntax: "מִמָּה יֵשׁ הֲכִי הַרְבֵּה?" (of which kind is there most)'),
    (B + 'אֵיזֶה יֵשׁ הֲכִי פָּחוֹת\?', 'מִמָּה יֵשׁ הֲכִי מְעַט?', 'syntax: "מִמָּה יֵשׁ הֲכִי מְעַט?" (of which kind is there least)'),
    (r' הוּא (?=[^ .?]+(?: [^ .?]+)? וְעוֹד כַּמָּה\?)', ' זֶה ','syntax: "אַחַת עֶשְׂרֵה זֶה עֶשֶׂר וְעוֹד כַּמָּה?" (as in "עֶשֶׂר זֶה שָׁלוֹשׁ וְעוֹד כַּמָּה?")'),
]
SUBS = [(re.compile(canon(p)), canon(r), why) for p, r, why in SUBS]

# The reviewed helper lines (group 4) have no nikud: full spelling and the right future forms.
TUTOR_SUBS = [
    (B + 'בוא נסה' + E, 'בוא ננסה', 'grammar: "בוא ננסה" (let us try); "בוא נסה" mixes two forms'),
    (B + 'בואי נסי' + E, 'בואי ננסה', 'grammar: "בואי ננסה" (let us try); "בואי נסי" mixes two forms'),
    (B + 'שלא נספר' + E, 'שעוד לא ספרנו', 'clarity: "שלא נספר" can read as "that will not be counted"'),
    (B + '(ו?)נספר' + E, r'\1נספור', 'spelling: "נספור" (we will count) in full spelling; "נספר" reads as "is counted"'),
    (B + '(ו?)נגע' + E, r'\1ניגע', 'spelling: "ניגע" (we will touch) in full spelling'),
    (B + '(ו?)נתן' + E, r'\1ניתן', 'spelling: "ניתן" (we will give) in full spelling; "נתן" reads as "he gave"'),
    (B + '(ו?)נאמר' + E, r'\1נגיד', 'word: "נגיד" (we will say); "נאמר" reads as "was said"'),
    (B + 'פעם אחת בלבד' + E, 'רק פעם אחת', 'vocabulary: "רק" for a child; "בלבד" is written register'),
    (B + 'ארבעה פרפרים בלבד' + E, 'רק ארבעה פרפרים', 'vocabulary: "רק" for a child; "בלבד" is written register'),
    (B + 'ואז נזיז לפרפר הבא' + E, 'ואז נעבור לפרפר הבא', 'word: we move on to the next one (נעבור), we do not move it'),
    (B + 'להצביע עם אצבע' + E, 'להצביע באצבע', 'style: "להצביע באצבע"'),
]
TUTOR_SUBS = [(re.compile(p), r, why) for p, r, why in TUTOR_SUBS]


def grammar(text, groups=()):
    """(corrected text, [reasons]); the text is returned unchanged when nothing is wrong."""
    notes = []
    t = canon(text)
    if text in MANUAL and MANUAL[text][0] != text:
        t, why = canon(MANUAL[text][0]), MANUAL[text][1]
        notes.append(why)
    if '4' in groups:
        for pat, repl, why in TUTOR_SUBS:
            new = pat.sub(repl, t)
            if new != t:
                t = new
                notes.append(why)
    for pat, repl, why in SUBS:
        new = pat.sub(repl, t)
        if new != t:
            t = new
            notes.append(why)
    # 1. "זוֹ / זֹאת ... לִלְחֹץ עָלָיו": a feminine thing is pressed with עָלֶיהָ
    if re.search(r'(?<![֐-׿])(זוֹ|זֹאת)(?![֐-׿])', t) and 'עָלָיו' in t:
        t = t.replace('עָלָיו', 'עָלֶיהָ')
        notes.append('gender: עָלָיו → עָלֶיהָ (the noun is feminine)')
    # 2. "זֶה" before a feminine singular noun, or before a plural noun / a counted noun
    toks = list(re.finditer(r"[֐-׿'\"]+", t))
    fixes = {}
    for k, m in enumerate(toks[:-1]):
        w = m.group(0)
        if w != 'זֶה' or (k and toks[k - 1].group(0).endswith('אֵי')):
            continue
        nxt = toks[k + 1].group(0)
        base = unprefixed(nxt)
        if base in FEM_SG or nxt in FEM_SG:
            fixes[m.start()] = ('זוֹ', 'demonstrative: זֶה → זוֹ (feminine singular)', m.end())
        elif nxt in MASC_PL or nxt in FEM_PL or base in MASC_PL or base in FEM_PL or (
                nxt in NUM_WORDS and k + 2 < len(toks) and (toks[k + 2].group(0) in MASC_PL | FEM_PL)):
            fixes[m.start()] = ('אֵלֶּה', 'demonstrative: זֶה → אֵלֶּה (plural)', m.end())
    for pos in sorted(fixes, reverse=True):
        repl, why, end = fixes[pos]
        t = t[:pos] + repl + t[end:]
        notes.append(why)
    # 3. שְׁתַּיִם / שְׁנַיִם directly before a noun: the construct form (שְׁתֵּי / שְׁנֵי)
    for m in list(re.finditer(r'(שְׁתַּיִם|שְׁנַיִם)\s+([֐-׿]+)', t)):
        nxt = m.group(2)
        if nxt in FEM_PL | MASC_PL or unprefixed(nxt) in FEM_PL | MASC_PL:
            new = 'שְׁתֵּי' if m.group(1) == 'שְׁתַּיִם' else 'שְׁנֵי'
            t = t[:m.start(1)] + new + t[m.end(1):]
            notes.append('number: %s before a noun → %s' % (m.group(1), new))
    # 4. a masculine plural noun with the feminine "שָׁווֹת"
    pat = r'(?:הַצְּדָדִים|הַמֹּאזְנַיִם)[^.!?]*?שָׁווֹת|שָׁווֹת[^.!?]*?(?:הַצְּדָדִים|הַמֹּאזְנַיִם)'
    if re.search(pat, t):
        t = re.sub(pat, lambda m: m.group(0).replace('שָׁווֹת', 'שָׁוִים'), t)
        notes.append('agreement: שָׁווֹת → שָׁוִים (הַצְּדָדִים and הַמֹּאזְנַיִם are masculine)')
    # 5. number words that do not agree with the noun next to them
    toks = list(re.finditer(r"[֐-׿'\"]+", t))
    for k, m in enumerate(toks[:-1]):
        w, nxt = m.group(0), toks[k + 1].group(0)
        if w in M_ONLY - {'אֶחָד'} and nxt in FEM_PL:
            notes.append('REVIEW number gender: %s %s (masculine number, feminine noun)' % (w, nxt))
        if w in F_ONLY - {'אַחַת'} and nxt in MASC_PL:
            notes.append('REVIEW number gender: %s %s (feminine number, masculine noun)' % (w, nxt))
    for k, m in enumerate(toks[1:], start=1):
        w, prev = m.group(0), toks[k - 1].group(0)
        if w == 'אֶחָד' and prev in FEM_SG:
            notes.append('REVIEW number gender: %s %s' % (prev, w))
        if w == 'אַחַת' and prev in MASC_SG:
            notes.append('REVIEW number gender: %s %s' % (prev, w))
    # 5b. after a prefix with a shva (בְּ, לְ, כְּ) a בגדכפת letter has no dagesh (בְּבַרְוָז, not בְּבַּרְוָז)
    pre = re.compile(r'(?<![֐-׿])([בכ]ְּ|לְ)([בגדכפת])([ְ-ׇֻ]*)ּ')
    if pre.search(t):
        t = pre.sub(lambda m: m.group(1) + m.group(2) + m.group(3), t)
        notes.append('nikud: no dagesh after a prefix with a shva (בְּבַרְוָז)')
    # 5c. a one-letter prefix with a shva before a shva or a hataf: בִּשְׁנֵי, בַּחֲמִשָּׁה, וַחֲמִשָּׁה (not בְּשְׁנֵי, בְּחֲמִשָּׁה, וְחֲמִשָּׁה)
    def prefix_vowel(m):
        cl = clusters(m.group(0))
        if len(cl) < 2 or cl[0][0] not in 'בלכו' or SHVA not in cl[0][1]:
            return m.group(0)
        nm = cl[1][1]
        for hataf, full in (('ֲ', 'ַ'), ('ֱ', 'ֶ'), ('ֳ', 'ָ')):
            if hataf in nm:
                cl[0][1] = cl[0][1].replace(SHVA, full)
                return canon(''.join(a + b for a, b in cl))
        if SHVA in nm and cl[0][0] != 'ו' and cl[1][0] != 'י':
            cl[0][1] = cl[0][1].replace(SHVA, HIRIQ)
            return canon(''.join(a + b for a, b in cl))
        return m.group(0)
    new = re.sub(r'(?<![֐-׿])[בלכו][ְּ]+[א-ת][ְ-ׇ]*', prefix_vowel, t)
    if new != t:
        t = new
        notes.append('nikud: a prefix before a shva or a hataf takes a vowel (בִּשְׁנֵי, בַּחֲמִשָּׁה, וַחֲמִשָּׁה)')
    # 6. the conjunctive vav and the letter after it
    vav_bgdkpt = re.compile(r'(?<![֐-׿])([וּ]|וְ)([בגדכפת])([\u05b0-\u05bb\u05c7]*)\u05bc')
    if vav_bgdkpt.search(t):
        t = vav_bgdkpt.sub(lambda m: m.group(1) + m.group(2) + m.group(3), t)
        notes.append('nikud: no dagesh after the conjunctive וְ (וְכָחֹל, not וְכָּחֹל)')
    if re.search(r'(?<![֐-׿])וְיְ', t):
        t = re.sub(r'(?<![֐-׿])וְיְ', 'וִי', t)
        notes.append('nikud: וְ before יְ becomes וִי (וִידַעְתֶּם)')
    vav_shva = re.compile(r'(?<![֐-׿])וְ([א-ת])([ְּ]{1,2})')
    if any('ְ' in m.group(2) for m in vav_shva.finditer(t)):
        t = vav_shva.sub(lambda m: ('וּ' + m.group(1) + 'ְ') if 'ְ' in m.group(2) else m.group(0), t)
        notes.append('nikud: וְ before a letter with a shva becomes וּ (וּמְשֻׁלָּשִׁים)')
    # 7. מַה before a letter that is not a guttural: patah, and a dagesh in the next letter (מַה לִּבְדֹּק, מַה זֶּה)
    def ma(m):
        cl = clusters(m.group(1))
        if cl[0][0] in 'אהחער' or SHVA in cl[0][1] or DAGESH in cl[0][1]:
            return 'מַה ' + m.group(1)
        cl[0][1] += DAGESH
        return 'מַה ' + canon(''.join(a + b for a, b in cl))
    new = re.sub(r'(?<![֐-׿])מָה ([א-ת][\u05b0-\u05c7]*)', lambda m: ma(m) if m.group(1)[0] not in 'אהחער' else m.group(0), t)
    if new != t:
        t = new
        notes.append('nikud: מַה before a letter that is not a guttural (מַה לִּבְדֹּק)')
    if 'נסיונות' in t:
        t = t.replace('נסיונות', 'ניסיונות')
        notes.append('spelling: ניסיונות')
    return t, notes


# ---------------------------------------------------------------- ElevenLabs
KTIV = {  # the plain form that the rules give -> the full spelling (only what the rules cannot give)
    'עכשו': 'עכשיו', 'ששה': 'שישה', 'ששי': 'שישי', 'חמשה': 'חמישה', 'חמשים': 'חמישים', 'שלשים': 'שלושים',
    'תבה': 'תיבה', 'שתים': 'שתיים', 'שנים': 'שניים', 'ידים': 'ידיים', 'המאזנים': 'המאזניים', 'צהרים': 'צהריים',
    'ואו': 'וואו', 'הממ': 'המממ', 'קוביה': 'קובייה', 'האזניים': 'האוזניים', 'אזניים': 'אוזניים',
    'התכנית': 'התוכנית', 'תכנית': 'תוכנית', 'כסא': 'כיסא', 'צוהריים': 'צהריים', 'צהוריים': 'צהריים',
    'מחווג': 'מחוג', 'מחווגים': 'מחוגים', 'חייה': 'חיה', 'חייות': 'חיות',
    'מיבשים': 'מייבשים', 'שבקשו': 'שביקשו',
}
KTIV_NO_PREFIX = {'ואו', 'הממ', 'שנים', 'שתים'}  # never looked up after a prefix letter (בשנים is "in years")
# words where the hiriq is not written with a yod (a prefix, or a dagesh for a nun that dropped): the plain form
NO_YOD = set()
YES_YOD_M = {'מילה', 'מילים', 'מידה', 'מיטה', 'מילון'}
WATER_SKY = {p + w for p in ('', 'ב', 'ה', 'ל', 'ו', 'מ', 'וה', 'מה', 'וב') for w in ('מים', 'שמים')}
NUMBER_PREFIX = ('וּבִ', 'וּבְ', 'וּלְ', 'וּמִ', 'וְ', 'וּ', 'וַ', 'לְ', 'לַ', 'לִ', 'בְּ', 'בַּ', 'בִּ', 'מִ', 'מֵ', 'שֶׁ', 'כְּ', 'כִּ', 'הַ')


def is_number_token(tok):
    if tok in NUM_WORDS:
        return True
    for p in NUMBER_PREFIX:
        if tok.startswith(p) and tok[len(p):] in NUM_WORDS:
            return True
    return False


def hiriq_yod(cl, i):
    """Is the hiriq on letter i written with a yod in full spelling?"""
    n = len(cl)
    if i + 1 >= n:
        return False
    nl, nm = cl[i + 1]
    if nl == 'י' or not HE_LETTER.match(nl):
        return False  # written already (מִי, שִׁיר, חִפּוּשִׁיּוֹת)
    if nl == 'א' and not (set(nm) & VOWELS):
        return False  # a silent aleph (רִאשׁוֹן)
    if cl[i][0] == 'ה' and DAGESH in nm:
        return False  # a dropped nun after the hif'il ה (הִגִּיעַ, כְּשֶׁהִגַּעְנוּ, הִנֵּה)
    if i + 2 == n and not (set(nm) & VOWELS) and DAGESH not in nm:
        return False  # a closed last syllable (עִם, אִם)
    if SHVA in nm and DAGESH not in nm:
        return False  # a closed syllable (מִסְפָּר, לִלְחֹץ)
    if i == 0 and DAGESH in nm and cl[0][0] in 'מה':
        return False  # a prefix or a dropped nun: מִכָּאן, מִתַּחַת, הִנֵּה, הִגִּיעַ (YES_YOD_M are checked by the caller)
    return True


def ktiv_token(tok):
    """A pointed word as plain text in full spelling (ktiv male): holam and qubuts become וֹ / וּ, a hiriq in an open
    syllable becomes a yod, a consonant vav inside a word is doubled."""
    cl = clusters(tok)
    n = len(cl)
    out = []
    for i, (L, mk) in enumerate(cl):
        nxt = cl[i + 1] if i + 1 < n else None
        if L == 'ו' and i > 0 and HE_LETTER.match(cl[i - 1][0]) and cl[i - 1][0] != 'ו' and not (nxt and nxt[0] == 'ו') and (
                set(mk) & (VOWELS - {HOLAM, HOLAM_H}) or (SHVA in mk and DAGESH in mk)):
            out.append('וו')  # a consonant vav inside a word: שָׁוֶה → שווה, הַוָּרֹד → הוורוד
        elif L == 'י' and i > 0 and DAGESH in mk and HIRIQ not in mk and not (
                nxt and nxt[0] == 'ו' and (set(nxt[1]) & {HOLAM, DAGESH})) and not (
                i == 1 and cl[0][0] in 'הבלכ' and set(cl[0][1]) & {'ַ', 'ָ'}) and not (
                i == 1 and cl[0][0] == 'ש' and 'ֶ' in cl[0][1]) and not (set(cl[i - 1][1]) & {QUBUTS, HOLAM}):
            out.append('יי')  # a doubled consonant yod: שַׁיָּךְ → שייך, מְצַיְּרִים → מציירים, קֻבִּיָּה → קובייה
        else:
            out.append(L)
        if not HE_LETTER.match(L):
            continue
        if HOLAM in mk or HOLAM_H in mk:
            if L != 'ו' and not (nxt and (nxt[0] in 'או' or (nxt[0] == 'ה' and i + 2 == n and not nxt[1]))):
                out.append('ו')
        elif QUBUTS in mk:
            if not (nxt and nxt[0] == 'ו'):
                out.append('ו')
        elif 'ֳ' in mk:
            out.append('ו')  # a hataf qamatz is an "o": צִפֳּרִים → ציפורים
        elif QATAN in mk:
            if not (L == 'כ' and nxt and nxt[0] == 'ל' and i + 2 == n):
                out.append('ו')
        elif HIRIQ in mk and hiriq_yod(cl, i):
            out.append('י')
    p = ''.join(out)
    if tok == 'שִׁנַּיִם':
        return 'שיניים'
    if tok.startswith('מִ') and n > 1 and DAGESH in cl[1][1]:
        cand = 'מי' + p[1:]
        if cand in YES_YOD_M:
            p = cand
    if plain(tok).endswith('ים') and tok.endswith('ַיִם') and plain(tok) not in WATER_SKY and not p.endswith('יים'):
        p = p[:-2] + 'יים'  # the dual: ידיים, אוזניים, צהריים, פעמיים
    if p in NO_YOD:
        p = NO_YOD_FIX.get(p, p)
    return p


NO_YOD_FIX = {}


def ktiv_lookup(p):
    if p in KTIV:
        return KTIV[p]
    for k in (1, 2):
        if len(p) > k + 2 and p[k:] not in KTIV_NO_PREFIX and p[:k] in ('ה', 'ו', 'ב', 'ל', 'מ', 'ש', 'כ', 'וה', 'וב', 'ול', 'שה', 'מה', 'בה', 'לה', 'כש') \
                and p[k:] in KTIV:
            return p[:k] + KTIV[p[k:]]
    return p


def partial_nikud(text):
    out = []
    for m in TOKEN.finditer(text):
        tok = m.group(0)
        if not HE_WORD.match(tok):
            out.append(tok)
        elif is_number_token(tok) or tok in KEEP_POINTED:
            out.append(tok)
        else:
            out.append(ktiv_lookup(ktiv_token(tok)))
    return ''.join(out)


def soften(text):
    """"!" shouts in ElevenLabs: a short opening ("כֵּן!", "כׇּל הַכָּבוֹד!") becomes a comma, anything else a full stop."""
    s = text
    i = 0
    out = ''
    clause_start = 0
    while i < len(s):
        c = s[i]
        if c == '!':
            clause = s[clause_start:i]
            more = s[i + 1:].strip()
            words_ = [w for w in re.findall(r"[֐-׿]+", clause)]
            if words_ and all(is_number_token(w) for w in words_):
                out += '.'  # a number said as the answer: "שָׁלוֹשׁ. חֲמִשָּׁה וְעוֹד…" (a comma would join it to the sum)
            elif more and len(clause.split()) <= 2 and not clause.strip().endswith(('.', '?')):
                out += ','
            else:
                out += '.'
            clause_start = i + 1
        else:
            out += c
            if c in '.?':
                clause_start = i + 1
        i += 1
    return re.sub(r'\.\.(?!\.)', '.', out).replace(',,', ',').replace('.,', '.').replace(',.', '.')


# A variable is never sent to a voice. A line with {child} is voiced once per child with the parent-reviewed first name
# (the owner's decision of 2026-10-25): the voice text leaves the name out and says so; numbers are voiced per value.
PLACEHOLDERS = {'{child}': ('', 'PER-NAME: the first name is said before this line (voiced per child, parent-reviewed spelling)'),
                '{companion}': ('', 'PER-FRIEND: the friend\'s own name is said by its voice')}

# Changes on the voice text (plain, after the spelling rules): (pattern, replacement, why)
VOICE_SUBS = [
    (r'(?<![\u0590-\u05ff])ו… ', 'ועוד צבע… ', 'voice: "וְ…" alone cannot be said; the blank is said as "ועוד צבע…"'),
    (r'לחזור על: ', 'לחזור על הצעדים: ', 'voice: "על:" before a list is said as "על הצעדים:"'),
    (r'(?<![֐-׿])בואו נאמר(?![֐-׿])', 'בואו נגיד', 'voice: "נאמר" can be read as "was said"; "נגיד"'),
    (r'(?<![֐-׿])(ש?)אין כלום זה ', r'\1אין כלום — זה ', 'voice-audit 2026-10-29: a beat before "זה אֶפֶס" (without it '
     'the two clauses run together and the rule is not heard)'),
]
# words that keep their nikud in the voice text because the plain form can be read another way
KEEP_POINTED = {'שֵׁנִי', 'הַשֵּׁנִי', 'הַוִּי', 'לְהֵרָאוֹת', 'נִסְפַּר', 'נְחַתֶּם'}
# The pronunciation audit of 2026-10-29 (docs/agents/voice-pronunciation-audit.md): plain words a voice can read as
# another word. They keep their nikud in the voice text; each row they change stays `proposed` until the owner agrees.
VOICE_AUDIT_KEEP = {
    'שָׂמִים': 'plain "שמים" is read "shamayim" (sky); here it is "samim" (we put)',
    'סָפַר': 'plain "ספר" is read "sefer" (a book); here it is "safar" (counted)',
    'גְּדֵלִים': 'plain "גדלים" can be read "gdalim" (sizes); here it is "gdelim" (grow)',
    'בַּתּוֹר': 'plain "בתור" is often read "betor" (as a); here it is "ba-tor" (in the line)',
    'אִמְרוּ': 'plain "אמרו" is read "amru" (they said); here it is the request "imru" (say)',
    'נְגַלֶּה': 'plain "נגלה" can be read "nigla" (was revealed); here it is "negale" (we will find out)',
    'אוֹפְּס': 'plain "אופס" can be read with an f ("ofes"); the dagesh keeps the p of "oops"',
    'מֵדַלְיָה': 'a loanword: plain "מדליה" can be read "madliya"; the nikud gives "medalya"',
    'אֵלֶּה': 'plain "אלה" can be read "ela"; here it is "ele" (these)',
    'בַּשָּׁמַיִם': 'plain "בשמים" can be read "besamim" (spices); here it is "ba-shamayim" (in the sky)',
}
VOICE_AUDIT_KEEP = {canon(w): why for w, why in VOICE_AUDIT_KEEP.items()}
KEEP_POINTED |= set(VOICE_AUDIT_KEEP)
VOICE_AUDIT = 'voice-audit 2026-10-29'
VOICE_SUBS = [(re.compile(p), r, why) for p, r, why in VOICE_SUBS]
VOICE_MANUAL = {}  # the ui text -> (voice text, why), for lines no rule can say well


def eleven(text):
    notes = []
    t = text
    if text in VOICE_MANUAL:
        t, why = VOICE_MANUAL[text]
        return t, [why]
    for k, (v, why) in PLACEHOLDERS.items():
        if k in t:
            t = t.replace(k + ', ', v).replace(k, v)
            notes.append(why)
    if re.search(r'\{[a-z]+\}', t):
        notes.append('REVIEW: a number variable is left; the line must be voiced once per value')
    if '!' in t:
        notes.append('tone: "!" softened')
    t = soften(t)
    before = sum(1 for c in t if NIKUD.match(c))
    for w, why in VOICE_AUDIT_KEEP.items():
        if re.search(B + w + E, t):
            notes.append('%s: kept the nikud of %s, %s' % (VOICE_AUDIT, w, why))
    t = partial_nikud(t)
    for pat, repl, why in VOICE_SUBS:
        new = pat.sub(repl, t)
        if new != t:
            t = new
            notes.append(why)
    if before:
        notes.append('nikud: partial (kept on number words), full spelling for the other words')
    t = t.strip()
    if t and t[-1] not in '.?…':
        t += '.'
        notes.append('voice: a full stop at the end, so the line closes')
    return t, notes


# ---------------------------------------------------------------- main
VOICED_UI = {'homeBubble', 'homeBubbleNoName'}


def spoken(r):
    if r['group'][0] == '3':
        return 'caption' in r['id'] and 'title' not in r['id'] or r['id'].startswith('childLine')
    if r['group'][0] in '24':
        return r['kind'].startswith('child')
    return r['group'][0] == '1' and r['id'] in VOICED_UI


def analyse(text, is_spoken, groups=()):
    ui, g_notes = grammar(text, groups)
    el, e_notes = eleven(ui) if is_spoken else ('', [])
    return ui, g_notes, el, e_notes


# ---------------------------------------------------------------- review state
# The batches the text editor read in full (group digit, regex on the id, regex on the source); see hebrew-notes.md.
# Group 5 (the alert word lists) is read for spelling only: its coverage needs a person who works with children.
REVIEWED = [
    ('1', r'', r''), ('2', r'', r''), ('3', r'', r''), ('4', r'', r''), ('6', r'', r''),
]
# Rows added after the master pass that the editor has not signed: (group digit, regex on the id, regex on the source,
# the comment). They stay `proposed` for the owner although their group is in REVIEWED; this list wins over REVIEWED,
# DOUBT and NOTE. A new string in a REVIEWED group goes here until the editor has read it (the run prints the new rows).
B26 = 'B-26 (docs/agents/b26-hebrew.md, docs/milestones/B26.md): new, worded by the editor, not yet read by the owner. '
PENDING = [
    ('1', r'^homeIsland(Mine)?$', r'he\.dart$', B26 + 'The island is named after the child (owner, 2026-10-29); the name '
     'is shown as typed and is never voiced or sent to a vendor; no name: "my island".'),
    ('1', r'^homeIsland(Mine)?Semantics$', r'he\.dart$', B26 + 'Screen-reader text, plain; the whole name, never shortened.'),
    ('1', r'^nitziHomeWelcome(NoName)?$', r'he\.dart$', B26 + 'Said by the chosen friend (decision 4), screen only (decision 6). '
     'Q5 of b26-hebrew.md: "בְּרוּכִים הַבָּאִים" for every child (recommended) or by address form?'),
    ('1', r'^nitziHomeHi$', r'he\.dart$', B26 + 'Said by the chosen friend at its house door (decision 4), so it names no '
     'one and has no gendered first person; was "אֲנִי נִיצִי. אֲנִי גָּרָה פֹּה." (fitted Nitzi only).'),
    ('1', r'^nitziHomeTreasures$', r'he\.dart$', B26 + 'True once the Hall and the stickers live in the home (decision 1); '
     'mixed group, so masculine plural "גָּרִים".'),
    ('1', r'^nitziHomeBottle$', r'he\.dart$', B26 + 'The bottle holds a revisit or the next lesson (decision 3), so not '
     '"new"; was "הַבַּקְבּוּק הֵבִיא הַרְפַּתְקָה חֲדָשָׁה.".'),
    ('1', r'^nitziHomeBottleDone$', r'he\.dart$', B26 + 'Q7: only once the daily three-stop plan exists (not built); '
     'until then the bottle always holds a next step and this line is not shown.'),
    ('1', r'^homeBubble$', r'he\.dart$', 'B-26: "the bottle arrived" is not true until the daily bottle exists '
     '(decision 3). Now "{child}, מַה בַּבַּקְבּוּק?" (voice text: "מה בבקבוק?"): true for a revisit or a new lesson, no '
     'verb, so no gender is guessed and it fits every friend; Nitzi\'s home answers it ("בַּבַּקְבּוּק יֵשׁ הַרְפַּתְקָה."). '
     'Step 2 had "{child}, בַּבַּקְבּוּק יֵשׁ הַרְפַּתְקָה!", too wide on tablets (design review b26-step2 §3, QA-25, QA-26): '
     'the fixed part is now 123 at Heebo 500, 24 (was 207; limit 140). Q6 (a per-name line) still stands.'),
    ('1', r'^homeBubbleNoName$', r'he\.dart$', 'B-26 step 3 (QA hand-off, b26-hebrew.md section 7): the map bubble when '
     'the child has no usable name; until now built in code from homeBubble and never in this table. The same question '
     'without the call: complete on its own, no verb, no gender, nothing points at the missing name. Its voice text '
     '"מה בבקבוק?" is the one of homeBubble, so one clip serves both and this line is never per-name.'),
]
# Texts the editor is not sure of: (regex on the original text, the comment). The row stays proposed for the owner.
DOUBT = [
    (r'^מָה שֶׁתּוֹפֵס|^יוֹתֵר לֹא תָּמִיד אוֹמֵר גָּדוֹל יוֹתֵר', 'Q2: the misconception line M-CNT-SIZE said "more does not always mean bigger"; '
     'the proposal says what the misconception is about (what takes more room is not always more). Please confirm.'),
    (r'וְעוֹד… עַד', 'Q3: this missing-addend hint counts from one to the total and then names the answer, which the count does not show. '
     'A clearer hint (count on from the first number) needs a change in tools/band_b*.py; see hebrew-notes.md, generator bug G1.'),
    (r'מָּתֵמָטִיקָאִים', 'Q4: "מָתֵמָטִיקָאִים" is a long word for a three-year-old. Keep it (growth-mindset identity) or say '
     '"זֶה מַה שֶּׁעוֹשִׂים חוֹקְרִים אֲמִתִּיִּים"? Your choice.'),
    (r'גֶּרֶב', 'Q5: גֶּרֶב is masculine in standard Hebrew (גֶּרֶב אֶחָד) and the proposal follows that; many speakers say "גֶּרֶב אַחַת". '
     'Please confirm masculine.'),
    (r'^\{child\}, ', 'Q6: a per-name line. The voice text is the line without the name; the name (parent-reviewed spelling) is said '
     'before it. One clip per child with the name inside sounds best; joining two clips is cheaper. The owner and the voice director decide.'),
]
# Comments the editor leaves on a row that is ready (information for the owner or the voice director): (regex, comment)
NOTE = [
    (r'^שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד\.$', 'said when the child taps "not sure" or "show me": it praises asking, as the brave-asker medal does.'),
    (r'הַתֵּבָה|תֵּבָה', '"תֵּבָה" (box, cuboid) is the school word for the solid; "קֻפְסָה" is the everyday word (Q7).'),
    (r'^עַכְשָׁו נָחִים|^מְבִינִים \{n\}', 'screen only; {n} is filled with digits by the app.'),
]
ALERT_NOTE = 'spelling checked; whether the list is complete needs a person who works with children (not the text editor).'


def first_match(rules, text):
    for pat, comment in rules:
        if re.search(pat, text):
            return comment
    return None


def reviewed(r):
    return any(r['group'].startswith(g) and re.search(i, r['id']) and re.search(s, r['source']) for g, i, s in REVIEWED)


def pending(r):
    for g, i, s, comment in PENDING:
        if r['group'].startswith(g) and re.search(i, r['id']) and re.search(s, r['source']):
            return comment
    return None


def main():
    rows = list(csv.DictReader(open(SRC, encoding='utf-8-sig')))
    seen = {}
    for r in rows:
        key = r['text']
        if key not in seen:
            seen[key] = {'ids': [], 'spoken': False, 'text': key, 'groups': set()}
        seen[key]['ids'].append('%s › %s' % (r['source'], r['id']))
        seen[key]['spoken'] |= spoken(r)
        seen[key]['groups'].add(r['group'][0])
    result = {k: analyse(k, v['spoken'], v['groups']) for k, v in seen.items()}
    out = []
    for item in seen.values():
        text = item['text']
        ui, g_notes, el, e_notes = result[text]
        if not g_notes and not item['spoken']:
            continue
        ids = item['ids']
        out.append({
            'id': ids[0] + (' (+%d more)' % (len(ids) - 1) if len(ids) > 1 else ''),
            'original': text, 'ui': ui if g_notes else text, 'eleven': el, 'explanation': '; '.join(g_notes + e_notes),
            'grammar': bool(g_notes), 'review': any(n.startswith('REVIEW') for n in g_notes + e_notes),
        })
    out.sort(key=lambda x: (not x['grammar'], x['id']))
    path = os.path.join(ROOT, 'docs', 'review', 'hebrew-elevenlabs-review')
    with open(path + '.csv', 'w', encoding='utf-8-sig', newline='') as fh:
        w = csv.writer(fh)
        w.writerow(['ID', 'Original Text', 'Corrected Text (For UI)', 'ElevenLabs Optimized Text', 'Explanation'])
        for x in out:
            w.writerow([x['id'], x['original'], x['ui'], x['eleven'], x['explanation']])
    esc = lambda s: s.replace('|', '\\|').replace('\n', ' ')
    with open(path + '.md', 'w', encoding='utf-8', newline='\n') as fh:
        fixes = [x for x in out if x['grammar']]
        fh.write('# Hebrew review for grammar and for ElevenLabs\n\n')
        fh.write('Made by `tools/hebrew_voice_review.py` from `hebrew-review.csv`. **Nothing here is in the pack yet.** '
                 'Rows with a grammar problem come first (%d); then every spoken text with its ElevenLabs version (%d rows in all; texts that '
                 'several activities share are one row). A row marked REVIEW in the explanation is a possible mistake that needs a person to decide. '
                 'The whole list, one row for each text in the app, is `hebrew-master.csv`; the editor\'s rules are in '
                 '`docs/agents/hebrew-notes.md`.\n\n' % (len(fixes), len(out)))
        fh.write('| ID | Original Text | Corrected Text (For UI) | ElevenLabs Optimized Text | Explanation |\n|---|---|---|---|---|\n')
        for x in out:
            fh.write('| %s | %s | %s | %s | %s |\n' % (esc(x['id']), esc(x['original']), esc(x['ui']), esc(x['eleven']), esc(x['explanation'])))
    master(rows, result)
    print('rows', len(out), 'grammar', sum(x['grammar'] for x in out), 'review', sum(x['review'] for x in out))


MASTER_COLUMNS = ['group', 'source', 'id', 'kind', 'spoken', 'text', 'ui_text', 'voice_text', 'changes', 'status',
                  'correction (fill in)', 'comment']
EDITOR = '[editor] '
OWNER_STATUSES = ('owner-approved', 'voice-ready', 'voiced')


def master(rows, result):
    """The one big table: every text of the app with the corrected screen text, the voice text, what changed and where it stands.
    What the owner typed in the last version of the table (a correction, a comment that is not the editor's, a status after
    text-ready) is kept; such a row is the owner's and the editor does not change its status."""
    path = os.path.join(ROOT, 'docs', 'review', 'hebrew-master.csv')
    kept = {}
    if os.path.exists(path):
        for r in csv.DictReader(open(path, encoding='utf-8-sig')):
            kept[(r['source'], r['id'], r['text'])] = r
    counts = {}
    new_rows = []
    with open(path, 'w', encoding='utf-8-sig', newline='') as fh:
        w = csv.writer(fh)
        w.writerow(MASTER_COLUMNS)
        for r in rows:
            is_spoken = spoken(r)
            ui, g_notes, el, e_notes = result[r['text']]
            notes = g_notes + e_notes
            status = 'proposed' if (g_notes or is_spoken) else 'unchanged'
            comment = ''
            if (r['source'], r['id'], r['text']) not in kept:
                new_rows.append(r)
            wait = pending(r)
            if wait:
                status, comment = 'proposed', EDITOR + wait
            elif reviewed(r):
                doubt, note = first_match(DOUBT, r['text']), first_match(NOTE, r['text'])
                if doubt:
                    status, comment = 'proposed', EDITOR + doubt
                elif any(n.startswith('REVIEW') for n in notes):
                    status, comment = 'proposed', EDITOR + 'a rule flagged this row; not yet decided'
                elif is_spoken and any(n.startswith(VOICE_AUDIT) for n in notes):
                    status, comment = 'proposed', EDITOR + (
                        'V1 (pronunciation audit 2026-10-29): the voice text changed so a voice cannot misread it '
                        '(a kept nikud or a beat; see "changes" and docs/agents/voice-pronunciation-audit.md). Please confirm.')
                else:
                    status = 'text-ready'
                    if note:
                        comment = EDITOR + note
            elif r['group'].startswith('5'):
                comment = EDITOR + ALERT_NOTE
            old = kept.get((r['source'], r['id'], r['text']))
            correction = r['correction (fill in)']
            if old:
                owner_comment = old['comment'].strip() and not old['comment'].startswith(EDITOR.strip())
                if old['correction (fill in)'].strip() or owner_comment or old['status'] in OWNER_STATUSES:
                    status = old['status'] if old['status'] in OWNER_STATUSES or old['correction (fill in)'].strip() else status
                    correction = old['correction (fill in)']
                    comment = old['comment'] if owner_comment else comment
            counts[status] = counts.get(status, 0) + 1
            w.writerow([
                r['group'], r['source'], r['id'], r['kind'], 'yes' if is_spoken else 'no', r['text'], ui, el,
                '; '.join(notes), status, correction, comment or r['comment'],
            ])
    print('master', len(rows), 'rows', counts)
    if kept and new_rows:
        # Not in the last table: the editor has not read them; a row in a REVIEWED group needs a PENDING entry or a read.
        print('new since the last table (%d):' % len(new_rows))
        for r in new_rows:
            print('  %s › %s: %s' % (r['source'], r['id'] or '-', r['text']))


if __name__ == '__main__':
    main()
