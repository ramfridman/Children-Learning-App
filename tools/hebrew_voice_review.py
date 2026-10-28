"""Reads docs/review/hebrew-review.csv and writes docs/review/hebrew-elevenlabs-review.md and .csv:

  * the rows with a grammar problem (demonstratives, number and noun gender, שתיים/שניים before a noun, a few spellings),
    with the corrected text for the screen (same nikud as the original);
  * every spoken text (a caption that a voice reads), with an ElevenLabs version: softer punctuation, partial nikud
    (kept on number words only), full spelling (ktiv male) for the common words, no curly-bracket variables.

    python tools/hebrew_voice_review.py

Nothing is written back to the pack: the owner decides which rows to take. Texts that several activities share are one row.
"""
import csv
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.argv = sys.argv[:1] + ['-']
from author import F, M  # noqa: E402
from band_b import NAMES, OBJECTS  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
SRC = os.path.join(ROOT, 'docs', 'review', 'hebrew-review.csv')
NIKUD = re.compile('[\u0591-\u05c7]')
TOKEN = re.compile(r"[\u0590-\u05ff'\"״׳]+|[^\u0590-\u05ff]+")
HE_WORD = re.compile(r"[\u0590-\u05ff]")


def plain(s):
    return NIKUD.sub('', s)


# ---------------------------------------------------------------- words that matter for gender
NUM_WORDS = set()
for _n in list(range(0, 21)) + list(range(30, 101, 10)):
    for _t in (F[_n], M[_n] if _n else F[0]):
        NUM_WORDS.update(_t.split())
NUM_WORDS.update(['שְׁנֵי', 'שְׁתֵּי', 'שְׁלֹשׁ', 'שְׁבַע', 'תְּשַׁע', 'שְׁנֵים', 'שְׁתֵּים', 'אַחַד', 'מֵאָה'])
M_ONLY = {'אֶחָד', 'שְׁלוֹשָׁה', 'אַרְבָּעָה', 'חֲמִשָּׁה', 'שִׁשָּׁה', 'שִׁבְעָה', 'שְׁמוֹנָה', 'תִּשְׁעָה', 'עֲשָׂרָה', 'שְׁנֵי', 'שְׁנַיִם'}
F_ONLY = {'אַחַת', 'שָׁלוֹשׁ', 'אַרְבַּע', 'חָמֵשׁ', 'שֵׁשׁ', 'שֶׁבַע', 'תֵּשַׁע', 'עֶשֶׂר', 'שְׁתֵּי', 'שְׁתַּיִם'}

FEM_PL = {'חִפּוּשִׁיּוֹת', 'צִפֳּרִים', 'צִפּוֹרִים', 'צְלָעוֹת', 'צַלָּחוֹת', 'קֻבִּיּוֹת', 'אֶצְבָּעוֹת', 'צוּרוֹת', 'פְּעָמִים',
          'אֲבָנִים', 'נוֹצוֹת', 'מַדְבֵּקוֹת', 'גַּרְבַּיִם', 'תְּמוּנוֹת', 'דְּרָכִים'}
MASC_PL = {'תַּפּוּחִים', 'דָּגִים', 'כּוֹכָבִים', 'בַּרְוָזִים', 'צְעָדִים', 'מִגְדָּלִים', 'מִסְפָּרִים', 'מַטְבְּעוֹת', 'מַקְלוֹת',
           'כַּדּוּרִים', 'בָּלוֹנִים', 'פְּרָחִים', 'דְּבָרִים', 'פַּרְפָּרִים', 'צְדָדִים'}
FEM_SG, MASC_SG = set(), set()
for _o in OBJECTS.values():
    (FEM_PL if _o['g'] == 'f' else MASC_PL).add(_o['many'])
    (FEM_SG if _o['g'] == 'f' else MASC_SG).add(_o['one'])
for _o in NAMES.values():
    (FEM_SG if _o['g'] == 'f' else MASC_SG).add(_o['one'])
FEM_SG -= {'כַּדּוּר', 'כֵּן', 'לֹא'}
MASC_SG -= {'כֵּן', 'לֹא'}
FEM_SG |= {'צִפּוֹר', 'צַלַּחַת', 'קֻבִּיָּה', 'חִפּוּשִׁית', 'בָּנָנָה', 'גֶּרֶב', 'כַּף', 'מִשְׁחָה', 'נַעַל', 'פִּירָמִידָה', 'תֵּבָה',
           'מַגֶּבֶת', 'מִבְרֶשֶׁת', 'מַדֵּלְיָה', 'צוּרָה', 'תְּמוּנָה', 'צַלַּחַת'}
FEM_SG -= MASC_SG & FEM_SG if False else set()


def unprefixed(tok):
    """A word without its pointed one-letter prefixes (the article, וְ, בְּ, לְ, מִ, שֶׁ), for a list look-up."""
    for p in ('הַ', 'הָ', 'הֶ', 'וְ', 'וּ', 'וַ', 'בַּ', 'בְּ', 'לַ', 'לְ', 'לָ', 'מִ', 'מֵ', 'שֶׁ', 'כְּ', 'וּבַ', 'וְהַ'):
        if tok.startswith(p) and len(tok) > len(p) + 1:
            return tok[len(p):]
    return tok


def words(text):
    return [(m.group(0), m.start()) for m in re.finditer(r"[\u0590-\u05ff'\"]+", text)]


# ---------------------------------------------------------------- grammar
MANUAL = {
    # the UI texts that a reading of the whole file found
    'יותר מדי נסיונות. אפשר לנסות שוב בעוד {m} דקות.': ('יותר מדי ניסיונות. אפשר לנסות שוב בעוד {m} דקות.', 'spelling: ניסיונות'),
    'בקרוב, כשיהיו באי מספיק מיומנויות': ('בקרוב, כשיהיו מספיק מיומנויות באי', 'clarity: "באי מספיק" reads as "not enough"; reordered so it is read as "on the island"'),
    'ההתראות לא מוצגות בצד של הילדים, והאפליקציה אף פעם לא מוכיחה אותם.': (
        'ההתראות לא מוצגות בצד של הילדים, והאפליקציה אף פעם לא נוזפת בהם.', 'word: "מוכיחה" can read as "proves"; "נוזפת" is the intended "scolds"'),
    'אֵין כְּלוּם זֶה אֶפֶס': ('אֵין כְּלוּם — זֶה אֶפֶס', 'pacing: a dash before the answer'),
    'אֶפְשָׁר יִהְיֶה לְהַרְוִיחַ אוֹתָהּ בְּקָרוֹב': ('אֶפְשָׁר יִהְיֶה לְהַרְוִיחַ אוֹתָהּ בְּקָרוֹב', ''),
}


def grammar(text):
    """(corrected text, [reasons]); the text is returned unchanged when nothing is wrong."""
    notes = []
    t = text
    if t in MANUAL and MANUAL[t][0] != t:
        return MANUAL[t][0], [MANUAL[t][1]]
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
    # 6. the conjunctive vav and the letter after it
    if re.search(r'(?<![֐-׿])וְ[בגדכפת]ּ', t):
        t = re.sub(r'(?<![֐-׿])(וְ[בגדכפת])ּ', lambda m: m.group(1), t)
        notes.append('nikud: no dagesh after the conjunctive וְ (וְכָחֹל, not וְכָּחֹל)')
    if re.search(r'(?<![֐-׿])וְיְ', t):
        t = re.sub(r'(?<![֐-׿])וְיְ', 'וִי', t)
        notes.append('nikud: וְ before יְ becomes וִי (וִידַעְתֶּם)')
    vav_shva = re.compile(r'(?<![֐-׿])וְ([א-ת])([ְּ]{1,2})')
    if any('ְ' in m.group(2) for m in vav_shva.finditer(t)):
        t = vav_shva.sub(lambda m: ('וּ' + m.group(1) + 'ְ') if 'ְ' in m.group(2) else m.group(0), t)
        notes.append('nikud: וְ before a letter with a shva becomes וּ (וּמְשֻׁלָּשִׁים)')
    if 'נסיונות' in t:
        t = t.replace('נסיונות', 'ניסיונות')
        notes.append('spelling: ניסיונות')
    return t, notes


# ---------------------------------------------------------------- ElevenLabs
KTIV = {  # the plain form that stripping leaves -> the full spelling (only what the holam and qubuts rules cannot give)
    'עכשו': 'עכשיו', 'שוה': 'שווה', 'ששה': 'שישה', 'ששי': 'שישי', 'חמשה': 'חמישה', 'חמשים': 'חמישים', 'שלשים': 'שלושים',
    'רבוע': 'ריבוע', 'עגול': 'עיגול', 'תבה': 'תיבה', 'צפרים': 'ציפורים', 'צפור': 'ציפור', 'חפושיות': 'חיפושיות',
    'חפושית': 'חיפושית', 'שתים': 'שתיים', 'שנים': 'שניים', 'ידים': 'ידיים', 'המאזנים': 'המאזניים', 'צהרים': 'צהריים',
    'ואו': 'וואו', 'הממ': 'המממ', 'קוביה': 'קובייה', 'האזניים': 'האוזניים',
}
# plain "words" produced by the holam/qubuts rules above are already full; the table only covers what hiriq needs.
WATER_SKY = {p + w for p in ('', 'ב', 'ה', 'ל', 'ו', 'מ', 'וה', 'מה', 'וב') for w in ('מים', 'שמים')}
NUMBER_PREFIX = ('וְ', 'וּ', 'וַ', 'לְ', 'לַ', 'בְּ', 'בַּ', 'מִ', 'מֵ', 'שֶׁ', 'כְּ', 'הַ')


def is_number_token(tok):
    if tok in NUM_WORDS:
        return True
    for p in NUMBER_PREFIX:
        if tok.startswith(p) and tok[len(p):] in NUM_WORDS:
            return True
    return False


def ktiv_token(tok):
    """A pointed word as plain text with the vowel letters that the nikud shows: holam and qubuts become וֹ / וּ."""
    letters = []
    chars = list(tok)
    for i, c in enumerate(chars):
        letters.append(c)
        if c in '\u05b9\u05ba' and i > 0:
            carrier = next((x for x in reversed(chars[:i]) if HE_WORD.match(x) and not NIKUD.match(x)), '')
            rest = [x for x in chars[i + 1:] if not NIKUD.match(x)]
            nxt = rest[0] if rest else ''
            if carrier == 'ו' or nxt == 'א' or (nxt == 'ה' and len(rest) == 1) or (nxt == 'ו'):
                continue
            letters.append('\u0000וֹ'[1:])  # a vav (the vowel letter) after the carrier
        elif c in '\u05bb' and i > 0:
            rest = [x for x in chars[i + 1:] if not NIKUD.match(x)]
            if rest and rest[0] != 'ו':
                letters.append('ו')
    out = plain(''.join(letters))
    if tok == 'שִׁנַּיִם':
        return 'שיניים'
    if tok.endswith('ַיִם') and plain(tok) not in WATER_SKY and not out.endswith('יים'):
        out = out[:-2] + 'יים'  # the dual: ידיים, אוזניים, צהריים, פעמיים
    return out


def partial_nikud(text):
    out = []
    for m in TOKEN.finditer(text):
        tok = m.group(0)
        if not HE_WORD.match(tok):
            out.append(tok)
        elif is_number_token(tok):
            out.append(tok)
        else:
            p = ktiv_token(tok)
            out.append(KTIV.get(p, p))
    return ''.join(out)


def soften(text):
    """"!" shouts in ElevenLabs: a short opening ("כֵּן!", "כׇּל הַכָּבוֹד!") becomes a comma, anything else a full stop."""
    res, start = [], 0
    s = text
    i = 0
    out = ''
    clause_start = 0
    while i < len(s):
        c = s[i]
        if c == '!':
            clause = s[clause_start:i]
            more = s[i + 1:].strip()
            if more and len(clause.split()) <= 2 and not clause.strip().endswith(('.', '?')):
                out += ','
            else:
                out += '.'
            clause_start = i + 1
        else:
            out += c
            if c in '.?:':
                clause_start = i + 1
        i += 1
    return re.sub(r'\.\.(?!\.)', '.', out).replace(',,', ',').replace('.,', '.').replace(',.', '.')


PLACEHOLDERS = {'{child}': 'דני', '{companion}': 'ניצי', '{n}': 'שלוש', '{a}': 'שלוש', '{b}': 'חמש'}


def eleven(text):
    notes = []
    t = text
    for k, v in PLACEHOLDERS.items():
        if k in t:
            t = t.replace(k, v)
            notes.append('variable %s → "%s"' % (k, v))
    if '!' in t:
        notes.append('tone: "!" softened')
    t = soften(t)
    before = sum(1 for c in t if NIKUD.match(c))
    t = partial_nikud(t)
    if before:
        notes.append('nikud: partial (kept on number words), full spelling for the other words')
    return t, notes


# ---------------------------------------------------------------- main
VOICED_UI = {'homeBubble'}


def spoken(r):
    if r['group'][0] == '3':
        return 'caption' in r['id'] and 'title' not in r['id'] or r['id'].startswith('childLine')
    if r['group'][0] in '24':
        return r['kind'].startswith('child')
    return r['group'][0] == '1' and r['id'] in VOICED_UI


def main():
    rows = list(csv.DictReader(open(SRC, encoding='utf-8-sig')))
    seen = {}
    for r in rows:
        key = r['text']
        if key not in seen:
            seen[key] = {'ids': [], 'spoken': False, 'text': key}
        seen[key]['ids'].append('%s › %s' % (r['source'], r['id']))
        seen[key]['spoken'] |= spoken(r)
    out = []
    for item in seen.values():
        text = item['text']
        ui, g_notes = grammar(text)
        el, e_notes = ('', [])
        if item['spoken']:
            # the voice reads the corrected sentence
            el, e_notes = eleven(ui)
        if not g_notes and not item['spoken']:
            continue
        if not g_notes and el == text:
            continue
        ids = item['ids']
        out.append({
            'id': ids[0] + (' (+%d more)' % (len(ids) - 1) if len(ids) > 1 else ''),
            'original': text, 'ui': ui if g_notes else text, 'eleven': el, 'explanation': '; '.join(g_notes + e_notes),
            'grammar': bool(g_notes), 'review': any(n.startswith('REVIEW') for n in g_notes),
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
                 'several activities share are one row). A row marked REVIEW in the explanation is a possible mistake that needs a person to decide.\n\n'
                 % (len(fixes), len(out)))
        fh.write('| ID | Original Text | Corrected Text (For UI) | ElevenLabs Optimized Text | Explanation |\n|---|---|---|---|---|\n')
        for x in out:
            fh.write('| %s | %s | %s | %s | %s |\n' % (esc(x['id']), esc(x['original']), esc(x['ui']), esc(x['eleven']), esc(x['explanation'])))
    print('rows', len(out), 'grammar', sum(x['grammar'] for x in out), 'review', sum(x['review'] for x in out))


if __name__ == '__main__':
    main()
