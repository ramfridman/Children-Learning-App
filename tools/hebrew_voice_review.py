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
FEM_SG -= {'כַּדּוּר', 'כֵּן', 'לֹא'}
MASC_SG -= {'כֵּן', 'לֹא', 'גֶּרֶב'}
# גֶּרֶב is feminine in this app (owner, Q5, 2026-10-29): "זוֹ גֶּרֶב", "גֶּרֶב אַחַת", "נַעַל וְגֶרֶב הוֹלְכוֹת".
FEM_SG |= {'צִפּוֹר', 'צַלַּחַת', 'קֻבִּיָּה', 'חִפּוּשִׁית', 'בָּנָנָה', 'כַּף', 'מִשְׁחָה', 'נַעַל', 'פִּירָמִידָה', 'תֵּבָה',
           'מַגֶּבֶת', 'מִבְרֶשֶׁת', 'מַדֵּלְיָה', 'צוּרָה', 'תְּמוּנָה', 'גֶּרֶב', 'קֻפְסָה'}
FEM_PL.add('גַּרְבַּיִם')
MASC_PL |= {'צְבָעִים', 'גְּבִיעִים', 'חֲלָקִים', 'רְמָזִים'}
# the singular of a counted plural noun (to say the noun again with its number: "וְעוֹד תַּפּוּחַ אֶחָד")
NOUN_ONE = {_o['many']: _o['one'] for _o in OBJECTS.values()}
OWNER = 'owner 2026-10-29'


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
    # (the M-CNT-SIZE line "יוֹתֵר לֹא תָּמִיד אוֹמֵר גָּדוֹל יוֹתֵר" is chosen per item by its cue: ROW_RULES, owner Q2)
    'לָקַחְנוּ אֶת כֻּלָּם. הַפֶּרַח רוֹצֶה רַק אַרְבָּעָה — בּוֹאוּ נִסְפֹּר אוֹתָם.': (
        'לָקַחְנוּ אֶת כֻּלָּם. בּוֹאוּ נִסְפֹּר וְנַעֲצֹר בַּמִּסְפָּר שֶׁצָּרִיךְ.',
        'sense (B-13, curriculum audit F1): the shared vo:fb.card line named "the flower" and "four" in all 22 give-N '
        'activities; 17 ask for another number and 21 have no flower. A neutral line that is true everywhere'),
    'בְּדַקְתֶּם שׁוּב לִפְנֵי שֶׁעֲנִיתֶם. זֶה מַה שֶּׁמָּתֵמָטִיקָאִים עוֹשִׂים.': (
        'בְּדַקְתֶּם שׁוּב לִפְנֵי שֶׁעֲנִיתֶם. כָּכָה עוֹשִׂים חוֹקְרִים.',
        'vocabulary (owner Q4, 2026-10-29: a shorter, simpler line, option A chosen): "מָתֵמָטִיקָאִים" is long for a three-year-old'),
    'כֵּן! זֶה הַתֵּבָה.': ('כֵּן! זוֹ הַתֵּבָה — כְּמוֹ קֻפְסָה שֶׁל נַעֲלַיִם.',
                         'vocabulary (owner Q7, 2026-10-29): Band B teaches "תֵּבָה" bridged to the word the child knows'),
    'הַתֵּבָה — נִסְתַּכֵּל עַל הַצּוּרָה שֶׁלּוֹ. עַכְשָׁו תּוֹרְכֶם.': (
        'הַתֵּבָה דּוֹמָה לְקֻפְסָה שֶׁל נַעֲלַיִם. עַכְשָׁו תּוֹרְכֶם.',
        'vocabulary (owner Q7, 2026-10-29): the worked example bridges "תֵּבָה" to a shoe box (and the old line said '
        '"שֶׁלּוֹ" of a feminine noun)'),
    'סֵדֶר שֶׁל שְׁלוֹשָׁה': ('סֵדֶר שֶׁל שְׁלוֹשָׁה דְּבָרִים', 'number (owner Q8, 2026-10-29): never a masculine number without its noun'),
    'מַמְשִׁיכִים סֵדֶר שֶׁל שְׁלוֹשָׁה': ('מַמְשִׁיכִים סֵדֶר שֶׁל שְׁלוֹשָׁה דְּבָרִים',
                                       'number (owner Q8, 2026-10-29): never a masculine number without its noun'),
    # app screens: B-26 (owner, 2026-10-29) and Q6
    '{child}, הַבַּקְבּוּק הִגִּיעַ!': ('{child}, מַה בַּבַּקְבּוּק?',
                                     'sense (B-26; owner Q6, 2026-10-29): the per-name line is a name clip joined to the '
                                     'shared clip "מה בבקבוק?"; "the bottle arrived" is not true until the daily bottle exists'),
    'זֶה הַבַּיִת שֶׁלִּי.': ('זֶה הַבַּיִת שֶׁלָּנוּ.', 'wording (B-26, owner 2026-10-29): "our home", said by any friend'),
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
    (B + 'נַעַל וְגֶּ?רֶב הוֹלְכִים יַחַד' + E, 'נַעַל וְגֶרֶב הוֹלְכוֹת יַחַד',
     'agreement (owner Q5, 2026-10-29: גֶּרֶב is feminine): נַעַל and גֶּרֶב are both feminine (הוֹלְכוֹת)'),
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
    # B-13 (board, 2026-10-28): the child's space has no speed language (CLAUDE.md, design-spec §5.4; design audit F3)
    (B + 'הִסְתַּכְּלוּ מַהֵר!', 'הִסְתַּכְּלוּ טוֹב…', 'tone (B-13, design audit F3): no speed language in the child\'s space; '
     '"הִסְתַּכְּלוּ טוֹב…" (look carefully), the dots give the look a beat'),
    (B + 'הִסְתַּכְּלוּ מַהֵר' + E, 'הִסְתַּכְּלוּ טוֹב', 'tone (B-13, design audit F3): no speed language in the child\'s space'),
    # B-13 (curriculum audit F13): no "not" question in Band A (curriculum §8.3); drafts, the rows stay proposed
    (B + 'מָה לֹא שַׁיָּךְ\?', 'מָה הִגִּיעַ לְכָאן בְּטָעוּת?', 'band A (B-13, curriculum audit F13): a question without "לֹא" '
     '(curriculum §8.3); approved by the owner 2026-10-29'),
    (B + 'מָה לֹא מִתְגַּלְגֵּל\?', 'מָה נִשְׁאָר עוֹמֵד בַּמָּקוֹם?', 'band A (B-13, curriculum audit F13): a question without '
     '"לֹא" (curriculum §8.3); approved by the owner 2026-10-29'),
    # B-13 (curriculum audit F8, F13): right and left are a skill (SHP-B-12) not built yet; the balance sides by their place
    (B + 'הַצַּד הַיְמָנִי קַל יוֹתֵר' + E, 'הַצַּד שֶׁלְּמַעְלָה קַל יוֹתֵר', 'band B (B-13, curriculum audit F8): no right and '
     'left words before SHP-B-12; the light side of a balance is the one that is up; draft'),
    (B + 'בַּצַּד הַשְּׂמָאלִי יֵשׁ', 'בַּצַּד שֶׁלְּמַטָּה יֵשׁ', 'band B (B-13, curriculum audit F8): the heavy side is the one '
     'that is down; draft'),
    (B + 'וּבַצַּד הַיְמָנִי' + E, 'וּבַצַּד שֶׁלְּמַעְלָה', 'band B (B-13, curriculum audit F8): the light side is the one that is up; draft'),
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
    (B + 'ולעצור אחרי ארבעה' + E, 'ולעצור כשמגיעים לארבע', 'number (owner Q8, 2026-10-29): never a masculine number '
     'without its noun; the count stops at "ארבע" (counting is feminine)'),
]
TUTOR_SUBS = [(re.compile(p), r, why) for p, r, why in TUTOR_SUBS]


def grammar(text, groups=()):
    """(corrected text, [reasons]); the text is returned unchanged when nothing is wrong."""
    notes = []
    t = canon(text)
    if t in MANUAL_C and canon(MANUAL_C[t][0]) != t:
        t, why = canon(MANUAL_C[t][0]), MANUAL_C[t][1]
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
    # 8. owner Q8 (2026-10-29): a number standing alone (a sum, an answer, a count) is feminine; a number with its noun
    #    agrees with the noun; never a masculine number without its noun
    # Owner Q12 (2026-10-29): "by one" stays masculine where no other number is in the line ("אֶחָד יוֹתֵר, אֶחָד פָּחוֹת",
    # "גְּדֵלִים בְּאֶחָד", "גָּבוֹהַּ בְּאֶחָד"); inside a sentence of numbers it is feminine ("שְׁתֵּים עֶשְׂרֵה! עוֹד אַחַת."): numeric()
    for _ in range(2):  # twice: "עוֹד אֶחָד, עוֹד שְׁנַיִם" sees the feminine "שְׁתַּיִם" on the second pass
        t, q8 = numbers_alone(t)
        notes += [n for n in q8 if n not in notes]
    return t, notes


MANUAL_C = {canon(k): v for k, v in MANUAL.items()}
MASC2FEM = {M[_i]: F[_i] for _i in range(1, 11)}
SUM_WORDS = {'וְעוֹד', 'פָּחוֹת', 'שָׁוֶה', 'הֵם', 'כָּפוּל'}
# words after a bare number that are not its noun (the number stands alone): "אַרְבָּעָה בַּסַּל", "שִׁשָּׁה בְּסַךְ הַכֹּל"
NOT_A_NOUN = SUM_WORDS | {'בְּסַךְ', 'בַּסַּל', 'אָז', 'וְעוֹד'}
Q8_WHY = 'number (owner Q8, 2026-10-29): a number standing alone is feminine (%s → %s), as the tiles and the counting'
Q8_NOUN = 'number (owner Q8, 2026-10-29): never a masculine number without its noun; the noun is said again (%s)'


ONE_MORE = {'עוֹד', 'קְחוּ'}
FEM_NUM = {w for _i in range(2, 21) for w in F[_i].split()} - {'עֶשְׂרֵה'}


def numeric(t, m):
    """Is this "אֶחָד" in a sentence about numbers (another number word stands in the text)?"""
    rest = t[:m.start()] + t[m.end():]
    return any(w in FEM_NUM or (w in MASC2FEM and w != '\u05d0\u05b6\u05d7\u05b8\u05d3') for w in re.findall(r'[\u0590-\u05ff]+', rest))


def numbers_alone(t):
    """Owner Q8: masculine number words (אֶחָד … עֲשָׂרָה) that do not stand before their noun become feminine. Kept:
    a number before its noun (שְׁלוֹשָׁה תַּפּוּחִים, שְׁלוֹשָׁה עָשָׂר), and "אֶחָד" as a pronoun or in the idioms
    "אֶחָד אֶחָד", "כׇּל אֶחָד", "אֶחָד מֵהֶם", "עוֹד אֶחָד", "אֶחָד פָּחוֹת / יוֹתֵר", "בְּאֶחָד" (one thing, one unit):
    "אֶחָד" changes only inside a sum (next to וְעוֹד, פָּחוֹת, שָׁוֶה). After a story noun ("שְׁלוֹשָׁה תַּפּוּחִים וְעוֹד
    אֶחָד") the noun is said again ("וְעוֹד תַּפּוּחַ אֶחָד")."""
    toks = list(re.finditer(r'[֐-׿]+', t))
    edits, notes = [], []
    for k, m in enumerate(toks):
        w = m.group(0)
        if w not in MASC2FEM:
            continue
        prev = toks[k - 1] if k else None
        nxt = toks[k + 1] if k + 1 < len(toks) else None
        pw = prev.group(0) if prev and t[prev.end():m.start()] == ' ' else None
        nw = nxt.group(0) if nxt and t[m.end():nxt.start()] == ' ' else None
        # "עוֹד אֶחָד", "קְחוּ אֶחָד", "אֶחָד פָּחוֹת" in a sentence of numbers ("שְׁתֵּים עֶשְׂרֵה! עוֹד אֶחָד.") is a number;
        # alone ("אֶחָד יוֹתֵר, אֶחָד פָּחוֹת", "עוֹד אֶחָד הָלַךְ") it stays (owner Q12, 2026-10-29)
        one_num = w == 'אֶחָד' and (pw in ONE_MORE or nw in ('פָּחוֹת', 'יוֹתֵר')) and numeric(t, m)
        if nw and nw not in NOT_A_NOUN and not one_num:
            if nw in MASC_PL or nw == 'עָשָׂר' or w == 'אֶחָד':
                continue  # before its noun, or "אֶחָד" before anything that is not a sum word
            notes.append('REVIEW number: %s %s (a masculine number before a word that is not a known noun)' % (w, nw))
            continue
        if w == 'אֶחָד' and not (pw in SUM_WORDS or nw in SUM_WORDS - {'פָּחוֹת'}) and not one_num:
            continue  # "פִּסְפַּסְנוּ אֶחָד", "אֶחָד אֶחָד", "לוֹקְחִים אֶחָד" (an apple): a pronoun for a thing
        if pw == 'וְעוֹד' and k >= 3 and toks[k - 2].group(0) in NOUN_ONE and toks[k - 3].group(0) in MASC2FEM.keys() | {'שְׁנֵי'}:
            noun = toks[k - 2].group(0)
            repl = NOUN_ONE[noun] + ' אֶחָד' if w == 'אֶחָד' else ('שְׁנֵי ' + noun if w == 'שְׁנַיִם' else w + ' ' + noun)
            edits.append((m.start(), m.end(), repl))
            notes.append(Q8_NOUN % repl)
            continue
        edits.append((m.start(), m.end(), MASC2FEM[w]))
        notes.append(Q8_WHY % (w, MASC2FEM[w]))
    for s, e, r in sorted(edits, reverse=True):
        t = t[:s] + r + t[e:]
    return t, list(dict.fromkeys(notes))


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
PLACEHOLDERS = {'{child}': ('', 'PER-NAME (owner Q6, 2026-10-29): a separate name clip per child (parent-reviewed spelling, made and '
                            'cached on the device, never a repo file or a bundled pack) is played right before this shared clip'),
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
# B-39 (Today's Adventure): the bottle's five lines. {land} is a land name, not a person's name, so it is not dropped (unlike
# {child}): each line is voiced once for each of the six lands (PER-LAND, like {n} is voiced per value). The voice names are
# listed in docs/agents/hebrew-notes.md; no name of a child or friend is in any of them.
PER_LAND = ('PER-LAND (B-39): voiced once for each of the six lands, with {land} replaced by the voice name of the land '
            '(גבעות הספירה, מפרץ הצבעים, יַעַר הצורות, מְעָרַת החידות, נְמַל הרובוטים, כְּפַר השוק); no child or friend name; no "!"')
VOICE_MANUAL.update({
    canon('בּוֹאוּ נֵצֵא לְהַרְפַּתְקָה אֶל {land}.'): ('בואו נֵצֵא להרפתקה אל {land}.', PER_LAND),
    canon('מַשֶּׁהוּ שֶׁל {land} צָרִיךְ עֶזְרָה. בּוֹאוּ נַעֲזֹר.'): ('משהו של {land} צריך עזרה. בואו נעזור.', PER_LAND),
    canon('בּוֹאוּ נַמְשִׁיךְ בַּהַרְפַּתְקָה שֶׁל {land}.'): ('בואו נמשיך בהרפתקה של {land}.', PER_LAND),
    canon('בּוֹאוּ נְבַקֵּר אֶת {land}.'): ('בואו נְבַקֵּר את {land}.', PER_LAND),
})


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
VOICED_UI = {'homeBubble', 'homeBubbleNoName', 'adventureWelcome', 'adventureCallForHelp', 'adventureSameLand',
             'adventureOtherLand', 'adventurePlayAgain'}


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
B39 = 'B-39 (docs/curriculum/todays-adventure-rule.md section 8, docs/agents/hebrew-notes.md): new, worded by the editor, not yet read by the owner. '
B15 = 'B-15 part 2 (docs/knowledge/b15-hebrew.md): new, not yet read by the owner. '
PENDING = [
    ('1', r'^homeIsland(Mine)?$', r'he\.dart$', B26 + 'The island is named after the child (owner, 2026-10-29); the name '
     'is shown as typed and is never voiced or sent to a vendor; no name: "my island" (b26-hebrew.md section 5, Q3, not answered yet).'),
    ('1', r'^homeIsland(Mine)?Semantics$', r'he\.dart$', B26 + 'Screen-reader text, plain; the whole name, never shortened.'),
    ('1', r'^nitziHomeTreasures$', r'he\.dart$', B26 + 'True once the Hall and the stickers live in the home (decision 1); '
     'mixed group, so masculine plural "גָּרִים".'),
    ('1', r'^nitziHomeBottle$', r'he\.dart$', B26 + 'The bottle holds a revisit or the next lesson (decision 3), so not '
     '"new"; was "הַבַּקְבּוּק הֵבִיא הַרְפַּתְקָה חֲדָשָׁה.".'),
    ('1', r'^adventure(Welcome|CallForHelp|SameLand|OtherLand|PlayAgain)$', r'he\.dart$', B39 + 'The bottle line for one reason '
     '(todays-adventure-rule.md section 8). "we" and "let us" only: no child name, no friend name, no gender, no time word. {land} follows '
     'only a separate word (אֶל, אֶת, שֶׁל), so the construct and the pointing of the land name never change.'),
    ('1', r'^adventure(Welcome|CallForHelp|SameLand|OtherLand|PlayAgain)Semantics$', r'he\.dart$', B39 + 'Screen-reader label of the '
     'bottle for that reason, plain text; {land} is the plain land name (land*Semantics).'),
    ('1', r'^land(Counting|Colors|Shapes|Logic|Robots|Market)Semantics$', r'he\.dart$', B39 + 'The plain land name for the '
     'bottle screen-reader label (the pointed names are land*).'),
    # B-15 part 2 (docs/knowledge/b15-hebrew.md): the editor's own strings are text-ready there. These are the lines the generator
    # made from a pattern that the tables do not give, so the editor reads them; the last element is a regex on the text.
    ('3', r'feedback\.correct', r'^activity\.b15\.matha04\.', B15 + 'The correct line of the fish and star size items (editor read it, 2026-10-30: correct, '
     '"זֶה" agrees with "דָּג" and "כּוֹכָב"). The owner approved only the two hints (2026-10-30); this line waits.',
     r'כֵּן! זֶה הַדָּג הַגָּדוֹל|כֵּן! זֶה הַכּוֹכָב הַקָּטָן'),
    ('3', r'hints\.2', r'^activity\.b15\.cola05\.', B15 + 'The hint of a tick answer: "לִלְחֹץ עַל הַוִּי" (H7a, the editor) in the pattern of the other hints.',
     r'לִלְחֹץ עַל הַוִּי'),
    # 2026-10-30: the owner approved P3-P5, the 15 spill lessons, NUM-B-08, NUM-B-18, the size and odd-one hints and the COL-A-05
    # correct lines (OWNER_APPROVED below), so they are no longer pending.
    # Decided by the owner on 2026-10-29 and so no longer here (hebrew-notes.md D14): nitziHomeWelcome(NoName),
    # nitziHomeBottleDone, homeBubble, homeBubbleNoName (ROW_RULES, text-ready) and nitziHomeHi (OWNER_APPROVED).
]
# Texts the editor is not sure of, or drafts the owner must pick: (regex on the original text, the comment). The row stays
# proposed for the owner. (Q2-Q8, Q11, Q12 were decided by the owner on 2026-10-29: ROW_RULES, SUBS, MANUAL, OWNER_APPROVED.)
DOUBT = [
    (r'הַצַּד הַיְמָנִי קַל|בַּצַּד הַשְּׂ?מָ?ֹ?אלִי יֵשׁ', 'B-13 (curriculum audit F8, F13): draft. Right and left are not taught before '
     'SHP-B-12, so the sides are named by where they are: the light side is up, the heavy side is down. True only if the '
     'balance picture tilts (design-director to confirm).'),
]
# Rows the OWNER approved (his own answers, relayed by the orchestrator; the editor never approves): (regex on the source,
# regex on the original text, the comment). Their status is `owner-approved`. Nothing else is ever set to it by this script.
OWNER_APPROVED = [
    (r'core\.he\.json$', r'מָּתֵמָטִיקָאִים', 'Q4: the owner chose option A, "בְּדַקְתֶּם שׁוּב לִפְנֵי שֶׁעֲנִיתֶם. כָּכָה עוֹשִׂים '
     'חוֹקְרִים." (owner-approved 2026-10-29).'),
    (r'^activity\.', r'^לָקַחְנוּ אֶת כֻּלָּם\. הַפֶּרַח', 'B-13 (curriculum audit F1): the owner approved the neutral give-N line '
     'for all 22 activities (owner-approved 2026-10-29). vo:fb.card is voiced once.'),
    (r'he\.dart$', r'^זֶה הַבַּיִת שֶׁלָּנוּ\.$', 'B-26 (b26-hebrew.md 7.3, question 3): the owner chose this exact line for '
     'nitziHomeHi, "our house" (owner-approved 2026-10-29).'),
    (r'^activity\.cs\.wrong\.', r'מָה לֹא שַׁיָּךְ', 'B-13 (curriculum audit F13): the owner approved "מָה הִגִּיעַ לְכָאן '
     'בְּטָעוּת?" for the Band A "not" question (owner-approved 2026-10-29).'),
    (r'^activity\.shp\.solid\.', r'מָה לֹא מִתְגַּלְגֵּל', 'B-13 (curriculum audit F13): the owner approved "מַה נִּשְׁאָר עוֹמֵד '
     'בַּמָּקוֹם?" for the Band A "not" question (owner-approved 2026-10-29).'),
    # The owner's answers of 2026-10-30 for B-15 ("1. I approve. 2. I approve. 3. Use the new one."); only these exact texts.
    # (1) P3, P4 and P5, the sorting-rule lines, in every activity where they play (Band A and Band B).
    (r'^activity\.', r'^זֶה אוֹתוֹ צֶבַע, אֲבָל מְחַפְּשִׂים אֶת אוֹתוֹ הַדָּבָר\. בּוֹאוּ נִבְדֹּק\.$',
     'B-15 P3 (kind rule): the owner approved it for both bands (owner-approved 2026-10-30). vo:fb.sort_shift.kind.'),
    (r'^activity\.', r'^זֶה אוֹתוֹ צֶבַע, אֲבָל מְחַפְּשִׂים אֶת אוֹתָהּ הַצּוּרָה\. בּוֹאוּ נִבְדֹּק\.$',
     'B-15 P4 (shape rule): the owner approved it for both bands (owner-approved 2026-10-30). vo:fb.sort_shift.shape.'),
    (r'^activity\.', r'^זֶה דּוֹמֶה, אֲבָל מְחַפְּשִׂים אֶת אוֹתוֹ הַגֹּדֶל\. בּוֹאוּ נִבְדֹּק\.$',
     'B-15 P5 (size rule): the owner approved it (owner-approved 2026-10-30). vo:fb.sort_shift.size.'),
    # (2) b15-hebrew.md section 7: the 15 spill lessons, NUM-B-08, NUM-B-18, the size and odd-one hints, COL-A-05 tick lines.
    (r'^lesson\.[a-z0-9-]+-b15\.json$', r'', 'B-15 (b15-hebrew.md 7.1): the owner approved the title and the celebration line of the 15 '
     'spill lessons (owner-approved 2026-10-30).', r'^(title\.0\.v|celebration\.caption\.0\.v)$'),
    (r'^activity\.b\.numb08\.', r'^אֵיזֶה מִסְפָּר חָסֵר\?$', 'B-15 (b15-hebrew.md 7.2): the owner approved the prompt and its alt text '
     '(owner-approved 2026-10-30).'),
    (r'^activity\.b\.numb18\.', r'אַחַת נִשְׁאֶרֶת', 'B-15 (b15-hebrew.md 7.3): the owner approved the feminine odd line '
     '(owner-approved 2026-10-30).'),
    (r'^activity\.b15\.matha04\.', r'^(הַדָּג הַגָּדוֹל|הַכּוֹכָב הַקָּטָן) תּוֹפֵס', 'B-15 (b15-hebrew.md 7.4): the owner approved the fish '
     'and star size hints (owner-approved 2026-10-30).'),
    (r'^activity\.b15\.loga02\.', r'שׁוֹנֶה מֵהָאֲחֵרִים', 'B-15 (b15-hebrew.md 7.5): the owner approved the odd-one-out hint '
     '(owner-approved 2026-10-30).'),
    (r'^activity\.b15\.cola05\.', r'^כֵּן! (זוֹ בָּנָנָה יְרֻקָּה|זֶה תַּפּוּחַ יָרֹק)\.$', 'B-15 (b15-hebrew.md 7.6): the owner approved '
     'the tick-answer lines of COL-A-05 (owner-approved 2026-10-30).'),
    # (3) P1: the third hint of a Band A spot with no hint of its own (tools/author.py SPOT_H3_A, vo:hint.spot_but_one.h3).
    (r'^activity\.', r'^כֻּלָּם דּוֹמִים, חוּץ מֵאֶחָד\. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו\.$',
     'B-15 P1 (b15-hebrew.md 4): the owner chose the new Band A hint 3 in place of "אֶחָד מֵהֶם לֹא מַתְאִים" '
     '(owner-approved 2026-10-30). One clip, vo:hint.spot_but_one.h3.'),
]


def owner_approved(r):
    for src, txt, comment, *rid in OWNER_APPROVED:  # an optional fourth element: a regex on the row id
        if (re.search(src, r['source']) and re.search(canon(txt), canon(r['text']))
                and (not rid or re.search(rid[0], r['id']))):
            return comment
    return None


# Comments the editor leaves on a row that is ready (information for the owner or the voice director): (regex, comment)
NOTE = [
    (r'^שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד\.$', 'said when the child taps "not sure" or "show me": it praises asking, as the brave-asker medal does.'),
    (r'הַתֵּבָה|תֵּבָה', 'Q7 (owner 2026-10-29): "תֵּבָה" is the Band B word, bridged to "קֻפְסָה שֶׁל נַעֲלַיִם" in the '
     'feedback and the worked example; a spoken "קֻפְסָה" is accepted as right (app-developer). Band A says "קֻפְסָה".'),
    (r'^עַכְשָׁו נָחִים|^מְבִינִים \{n\}', 'screen only; {n} is filled with digits by the app.'),
    (r'הִסְתַּכְּלוּ מַהֵר', 'B-13 (design audit F3): "look fast" became "look carefully" (no speed language); the '
     'curriculum-expert confirms the flash still teaches subitising (the picture still hides after a moment).'),
    (r'גֶּרֶב', 'Q5 (owner 2026-10-29): גֶּרֶב is feminine in this app (זוֹ גֶּרֶב, נַעַל וְגֶרֶב הוֹלְכוֹת).'),
    (r'^\{child\}, מַה בַּבַּקְבּוּק|^\{child\}, הַבַּקְבּוּק', 'Q6 (owner 2026-10-29): a name clip per child (the '
     'parent-reviewed first name, made and cached on the device only; never a file in the repo or a bundled pack, SEC-5) '
     'is played right before the shared clip "מה בבקבוק?", which homeBubbleNoName also uses.'),
]

# ---------------------------------------------------------------- per-row rules (the owner's answers of 2026-10-29)
WORD2N = {canon(F[_i]): _i for _i in range(0, 21)}
WORD2N.update({canon(M[_i]): _i for _i in range(1, 21)})
ADDEND_PROMPT = re.compile(canon(r'^(\S+) וְעוֹד כַּמָּה שָׁוֶה (\S+)\?$'))
ADDEND_PROMPT_FLIPPED = re.compile(canon(r'^(\S+) שָׁוֶה (\S+) וְעוֹד כַּמָּה\?$'))  # `7 = 3 + ?` (B-15, H31): the whole first


def addend_words(ctx):
    """(the number that is there, the total) of a missing-addend prompt in either order, or None."""
    prompt = canon(ctx.get('prompt.caption.0.v', ''))
    m = ADDEND_PROMPT.match(prompt)
    if m:
        return m.group(1), m.group(2)
    m = ADDEND_PROMPT_FLIPPED.match(prompt)
    return (m.group(2), m.group(1)) if m else None


def fem_before_noun(n):
    return 'שְׁתֵּי' if n == 2 else F[n]


def masc_before_noun(n):
    return 'שְׁנֵי' if n == 2 else M[n]


def missing_addend_model(r, ctx):
    """Owner Q3, hint 2 (level 2): a concrete model first; the answer is not said before hint 3."""
    words = addend_words(ctx)
    if not words:
        return None
    return '%s כְּבָר יֵשׁ. מוֹסִיפִים אַחַת אַחַת עַד %s, וְסוֹפְרִים כַּמָּה הוֹסַפְנוּ.' % words


def missing_addend_count_on(r, ctx):
    """Owner Q3, hint 3 (level 3): count on from the first number, one finger per count, then the answer."""
    words = addend_words(ctx)
    if not words:
        return None
    x, total = WORD2N[words[0]], WORD2N[words[1]]
    k = total - x
    return '%s… וּמַמְשִׁיכִים: %s. הֵרַמְנוּ %s אֶצְבָּעוֹת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (
        F[x], ', '.join(F[i] for i in range(x + 1, total + 1)), fem_before_noun(k), F[k])


COIN_PLAIN = [('שקל אחד', 1), ('שני שקלים', 2), ('חמשה שקלים', 5), ('עשרה שקלים', 10)]  # plain() of pointed text is ktiv chaser
SHOP_PRICE = re.compile(canon(r'הַמְּחִיר הוּא (.+) שְׁקָלִים'))
COIN_NAME = {1: 'מַטְבֵּעַ שֶׁל שֶׁקֶל', 2: 'מַטְבֵּעַ שֶׁל שְׁנֵי שְׁקָלִים', 5: 'מַטְבֵּעַ שֶׁל חֲמִשָּׁה שְׁקָלִים',
             10: 'מַטְבֵּעַ שֶׁל עֲשָׂרָה שְׁקָלִים'}


def shop_coins(r, ctx):
    """Owner Q11: name each coin by its value (the biggest first), then the total."""
    p = plain(r['text'])
    coins = sorted((v for name, v in COIN_PLAIN for _ in re.finditer(name, p)), reverse=True)
    price = SHOP_PRICE.search(canon(ctx.get('prompt.caption.0.v', '')))
    if not coins or not price or WORD2N.get(price.group(1)) != sum(coins):
        print('shop hint not rebuilt (the coins do not add up to the price):', r['source'], coins)
        return None
    if len(coins) == 1:
        return 'מַטְבֵּעַ אֶחָד שֶׁל %s. עַכְשָׁו תּוֹרְכֶם.' % COIN_NAME[coins[0]].split(' שֶׁל ', 1)[1]
    parts = [COIN_NAME[coins[0]]]
    for i, v in enumerate(coins[1:], start=1):
        name = ('עוֹד ' + COIN_NAME[v]) if v == coins[i - 1] else COIN_NAME[v]
        parts.append(name)
    said = ', '.join(parts[:-1]) + (' וְ' if parts[-1].startswith('עוֹד') else ' וּ') + parts[-1]
    return '%s — בְּיַחַד %s שְׁקָלִים. עַכְשָׁו תּוֹרְכֶם.' % (said, masc_before_noun(sum(coins)))


ROBOT_WORDS = {canon(k): v for k, v in {'יָמִינָה': 'h', 'שְׂמֹאלָה': 'h', 'לְמַעְלָה': 'לְמַעְלָה', 'לְמַטָּה': 'לְמַטָּה'}.items()}
ROBOT_HINT = re.compile(canon(r'^הַצְּעָדִים הֵם: (.+)\. עַכְשָׁו תּוֹרְכֶם\.$'))


def robot_landmarks(r, ctx):
    """Band A hears landmarks, not right and left (PLAN.md; curriculum audit F13): the sideways steps go towards the flag."""
    m = ROBOT_HINT.match(canon(r['text']))
    if not m:
        return None
    steps = [ROBOT_WORDS.get(s.strip()) for s in m.group(1).split(',')]
    if None in steps:
        return None
    runs = []
    for s in steps:
        if runs and runs[-1][0] == s:
            runs[-1][1] += 1
        else:
            runs.append([s, 1])
    said = []
    for s, n in runs:
        where = 'לְכִוּוּן הַדֶּגֶל' if s == 'h' else s
        said.append(('צַעַד אֶחָד' if n == 1 else '%s צְעָדִים' % masc_before_noun(n)) + ' ' + where)
    return '%s. עַכְשָׁו תּוֹרְכֶם.' % ', וְאָז '.join(said)


SIZE_LINES = {
    'big': 'הֵם גְּדוֹלִים, אֲבָל כַּמָּה יֵשׁ? בּוֹאוּ נִסְפֹּר.',
    'small': 'הֵם קְטַנִּים, אֲבָל כַּמָּה יֵשׁ? בּוֹאוּ נִסְפֹּר.',
    'spread': 'הֵם רְחוֹקִים זֶה מִזֶּה, אֲבָל כַּמָּה יֵשׁ? בּוֹאוּ נִסְפֹּר.',
    'pairs': 'בּוֹאוּ נַעֲשֶׂה זוּגוֹת: לְכֻלָּם יֵשׁ זוּג?',
    'count': 'בּוֹאוּ נִסְפֹּר כַּמָּה יֵשׁ בְּכׇל קְבוּצָה.',
}
SIZE_OLD = r'^יוֹתֵר לֹא תָּמִיד אוֹמֵר גָּדוֹל יוֹתֵר'
Q2 = 'sense (owner Q2, 2026-10-29): the M-CNT-SIZE line is chosen by the item\'s cue, names what the eye caught, has no ' \
     '"לֹא" and ends in the strategy; the old line ("more does not always mean bigger") said the reverse'
TR, PR = 'text-ready', 'proposed'
# (regex on the source, regex on the id, regex on the original text, the new text or a builder (row, texts of the same
#  source by id) or None (status only), why, status, comment). The first match wins; the generic rules still run on the
#  new text. A row rule wins over DOUBT and NOTE.
ROW_RULES = [
    # Q2: the cue of each item (scale for size, arrangement for spread; the yes/no "same" items compare by pairing)
    (r'^activity\.more\.big\.', r'^feedback\.incorrect', SIZE_OLD, SIZE_LINES['big'], Q2 + ' (big)', TR,
     'Q2 (owner 2026-10-29): the child picked the big ones. vo:fb.size must split by cue (hebrew-notes.md D2).'),
    (r'^activity\.fewer\.big\.', r'^feedback\.incorrect', SIZE_OLD, SIZE_LINES['small'], Q2 + ' (small)', TR,
     'Q2 (owner 2026-10-29): in a "fewer" item the child picked the small ones (the teaching view\'s size line, turned '
     'round). vo:fb.size must split by cue (hebrew-notes.md D2).'),
    (r'^activity\.more\.spread\.', r'^feedback\.incorrect', SIZE_OLD, SIZE_LINES['spread'], Q2 + ' (spread)', TR,
     'Q2 (owner 2026-10-29): the child picked the spread-out ones. vo:fb.size must split by cue (hebrew-notes.md D2).'),
    (r'^activity\.same\.', r'^feedback\.incorrect', SIZE_OLD, SIZE_LINES['pairs'], Q2 + ' (pairs)', PR,
     'Q2 draft: NUM-A-11 compares by pairing, but its items ask "the same number?" (yes or no), not "more" or "fewer", so '
     'the two matching lines of the teaching view do not fit; this pairing line is new. Please confirm.'),
    (r'^activity\.x\.numa07\.', r'^feedback\.incorrect', SIZE_OLD, SIZE_LINES['count'], Q2 + ' (counting; NUM-A-07)', PR,
     'Q2 draft: NUM-A-07 (match a numeral to a set) should lose the M-CNT-SIZE tag (curriculum audit F4); then this row '
     'goes away. Until then, the counting line.'),
    # Q3: the missing addend, a concrete model at hint 2, count on at hint 3
    (r'^activity\.b\.mathb18\.', r'^hints\.1\.caption', r'', missing_addend_model,
     'teaching (owner Q3, 2026-10-29): hint 2 builds the model first (the start is there, add one at a time up to the total, '
     'count what was added); it does not say the answer', TR,
     'Q3 (owner 2026-10-29). Needs its own vo id per item (today the shared hint-2 line) and the dots drawn (audit F12).'),
    (r'^activity\.b\.mathb18\.', r'^hints\.2\.caption', r'', missing_addend_count_on,
     'teaching (owner Q3, 2026-10-29): hint 3 counts on from the first number, one finger per count, then names the answer '
     '(the old hint counted from one to the total)', TR,
     'Q3 (owner 2026-10-29). The fingers must be drawn (audit F12); the distractor 10 (M-PPW) is a content change (hebrew-notes.md D4).'),
    # Q11: the shop hint names each coin by its value, then the total; hint 2 stays
    (r'^activity\.x\.mathb17\.', r'^hints\.2\.caption', r'', shop_coins,
     'teaching (owner Q11, 2026-10-29): each coin is named by its value ("מַטְבֵּעַ שֶׁל שְׁנֵי שְׁקָלִים"), then the total; '
     '"שְׁנֵי שְׁקָלִים" alone can be one coin or two', TR, 'Q11 (owner 2026-10-29). Hint 2 is unchanged.'),
    # B-13 / PLAN.md: Band A robot hints without right and left
    (r'^activity\.cs\.robot\.(direct|plan)\.', r'^hints\.2\.caption', r'יָמִינָה|שְׂמֹאלָה', robot_landmarks,
     'band A (B-13, curriculum audit F13; PLAN.md "Band A avoids right and left words"): the sideways steps are said '
     '"לְכִוּוּן הַדֶּגֶל", up and down stay', TR,
     'B-13: landmark wording as PLAN.md asks; the flag is the only landmark on these grids. Curriculum-expert to confirm.'),
    # Q7: Band A says קֻפְסָה for the box-shaped solid (SHP-A-07)
    (r'^activity\.shp\.solid\.', r'', r'קֻבִּיָּה', lambda r, ctx: canon(r['text']).replace(canon('קֻבִּיָּה'), canon('קֻפְסָה')),
     'vocabulary (owner Q7, 2026-10-29): Band A calls the box-shaped solid "קֻפְסָה" (קֻבִּיָּה only for a real cube)', TR,
     'Q7 (owner 2026-10-29). The design-director draws a shoe-box cuboid for it (audit F9).'),
    # B-26 (owner, 2026-10-29): the welcome for every child; "our home"; the bottle-done line waits for the plan
    (r'he\.dart$', r'^nitziHomeWelcome(NoName)?$', r'', None, '', TR,
     'B-26 (owner 2026-10-29): "בְּרוּכִים הַבָּאִים" for every child, whatever the address form.'),
    (r'he\.dart$', r'^nitziHomeHi$', r'', None, '', TR, 'B-26 (owner 2026-10-29): "זֶה הַבַּיִת שֶׁלָּנוּ." (our home).'),
    (r'he\.dart$', r'^nitziHomeBottleDone$', r'', None, '', TR,
     'B-26 (owner 2026-10-29): the wording stands; shown only once the daily three-stop plan exists.'),
    (r'he\.dart$', r'^homeBubble(NoName)?$', r'', None, '', TR,
     'Q6 (owner 2026-10-29): a name clip per child (parent-reviewed first name, made and cached on the device only, never a '
     'repo file or a bundled pack, SEC-5) joined before the shared clip "מה בבקבוק?"; homeBubbleNoName plays the shared clip alone.'),
]


def row_rule(r, ctx):
    """(new text or None, why, status, comment) of the first row rule that matches, or None."""
    for src, rid, txt, build, why, status, comment in ROW_RULES:
        if re.search(src, r['source']) and re.search(rid, r['id']) and re.search(canon(txt), canon(r['text'])):
            new = build(r, ctx) if callable(build) else build
            if callable(build) and new is None:
                continue
            return (canon(new) if new else None), why, status, comment
    return None
ALERT_NOTE = 'spelling checked; whether the list is complete needs a person who works with children (not the text editor).'


def first_match(rules, text):
    for pat, comment in rules:
        if re.search(pat, text):
            return comment
    return None


def reviewed(r):
    return any(r['group'].startswith(g) and re.search(i, r['id']) and re.search(s, r['source']) for g, i, s in REVIEWED)


def pending(r):
    for g, i, s, comment, *text in PENDING:
        if (r['group'].startswith(g) and re.search(i, r['id']) and re.search(s, r['source'])
                and (not text or re.search(canon(text[0]), canon(r['text'])))):
            return comment
    return None


def main():
    rows = list(csv.DictReader(open(SRC, encoding='utf-8-sig')))
    by_source = {}
    for r in rows:
        by_source.setdefault(r['source'], {})[r['id']] = r['text']
    seen, rules = {}, {}
    for n, r in enumerate(rows):
        rule = row_rule(r, by_source[r['source']]) if r['group'][0] in '123' else None
        rules[n] = rule
        key = (r['text'], rule[0] if rule else None, rule[1] if rule else None)
        if key not in seen:
            seen[key] = {'ids': [], 'spoken': False, 'text': r['text'], 'groups': set(), 'rule': rule}
        seen[key]['ids'].append('%s › %s' % (r['source'], r['id']))
        seen[key]['spoken'] |= spoken(r)
        seen[key]['groups'].add(r['group'][0])
    result = {}
    for k, v in seen.items():
        rule = v['rule']
        if rule and rule[0]:
            ui, g_notes = grammar(rule[0], v['groups'])
            g_notes = [rule[1]] + g_notes
            el, e_notes = eleven(ui) if v['spoken'] else ('', [])
            result[k] = (ui, g_notes, el, e_notes)
        else:
            result[k] = analyse(v['text'], v['spoken'], v['groups'])
    out = []
    for k, item in seen.items():
        text = item['text']
        ui, g_notes, el, e_notes = result[k]
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
    master(rows, result, rules)
    print('rows', len(out), 'grammar', sum(x['grammar'] for x in out), 'review', sum(x['review'] for x in out))


MASTER_COLUMNS = ['group', 'source', 'id', 'kind', 'spoken', 'text', 'ui_text', 'voice_text', 'changes', 'status',
                  'correction (fill in)', 'comment']
EDITOR = '[editor] '
OWNER_STATUSES = ('owner-approved', 'voice-ready', 'voiced')


def master(rows, result, rules):
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
        for n, r in enumerate(rows):
            is_spoken = spoken(r)
            rule = rules[n]
            ui, g_notes, el, e_notes = result[(r['text'], rule[0] if rule else None, rule[1] if rule else None)]
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
                v1 = is_spoken and any(n_.startswith(VOICE_AUDIT) for n_ in notes)
                if rule:
                    status, comment = rule[2], EDITOR + rule[3]
                    if any(n_.startswith('REVIEW') for n_ in notes):
                        status, comment = 'proposed', comment + ' A rule flagged this row; not yet decided.'
                    elif v1 and status == 'text-ready':
                        status, comment = 'proposed', comment + ' V1 (pronunciation audit 2026-10-29): a kept nikud in the voice text; please confirm.'
                elif doubt:
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
            approved = owner_approved(r)
            if approved:
                status, comment = 'owner-approved', EDITOR + approved
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
