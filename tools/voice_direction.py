"""The voice director's table: one row for every distinct voiced text of the app, with its direction.

Reads docs/review/hebrew-master.csv (only rows with status `text-ready`, spoken, and their `voice_text`), the content
files (to find each row's `vo:` id and band) and content/voices.proposed.json (the styles), and writes
docs/audio/voice-direction.csv. It also prints the character counts and the cost of the voicing plan.

    PYTHONIOENCODING=utf-8 python tools/voice_direction.py            # write the table, print the plan
    PYTHONIOENCODING=utf-8 python tools/voice_direction.py --sample 220   # also print a sample to read by eye

Nothing is sent anywhere and nothing is changed: the Hebrew letters of a voice text are never touched here. The
pronunciation column only *proposes* entries (the same letters with points) for content/voices.json › pronunciation;
the text editor confirms the pointing.
"""
import csv
import glob
import json
import os
import random
import re
import sys
from collections import Counter, OrderedDict, defaultdict

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
MASTER = os.path.join(ROOT, 'docs', 'review', 'hebrew-master.csv')
STARTER = os.path.join(ROOT, 'content', 'starter')
CORE = os.path.join(ROOT, 'content', 'lines', 'core.he.json')
PROPOSED = os.path.join(ROOT, 'content', 'voices.proposed.json')
OUT = os.path.join(ROOT, 'docs', 'audio', 'voice-direction.csv')
VOICE_HOME = os.path.join(os.environ.get('USERPROFILE', os.path.expanduser('~')), 'nitznutz-voice')

NIKUD = re.compile('[֑-ׇ]')
HE_LETTER = re.compile('[א-ת]')
PRICE_PER_1000 = 0.04          # eleven_v4_turbo API list price (docs/PLAN.md, ElevenLabs pricing)
CREATOR_MONTH = 275_000        # characters a month on the Creator plan (docs/PLAN.md)

NARRATORS = ['nitzi', 'hero-son']
FRIENDS = ['alien-jili', 'climber-tzuri', 'compass-romi', 'friend-daughter', 'inventor-gali', 'tower-tamir',
           'weaver-keshet']
NARRATOR_OF = {'nitzi': 'nitzi', 'alien-jili': 'nitzi', 'compass-romi': 'nitzi', 'friend-daughter': 'nitzi',
               'inventor-gali': 'nitzi', 'weaver-keshet': 'nitzi', 'hero-son': 'hero-son',
               'climber-tzuri': 'hero-son', 'tower-tamir': 'hero-son'}   # app/lib/app/companion.dart

# Measured on the 318 existing lines of nitzi and hero-son (median, silence at the ends included): about 1.65 words a
# second at speed 1.0 (docs/audio/voice-direction.md, section 1.3). Used only to estimate a line's length.
WORDS_PER_SEC = 1.65

PLAIN = lambda s: NIKUD.sub('', s)  # noqa: E731

NUMBER_WORDS = {PLAIN(w) for w in (
    'אֶפֶס אַחַת אֶחָד אַחַד שְׁתַּיִם שְׁנַיִם שְׁתֵּי שְׁנֵי שְׁתֵּים שְׁנֵים שָׁלוֹשׁ שְׁלוֹשָׁה שְׁלֹשׁ אַרְבַּע אַרְבָּעָה חָמֵשׁ '
    'חֲמִשָּׁה חֲמֵשׁ שֵׁשׁ שִׁשָּׁה שֶׁבַע שִׁבְעָה שְׁבַע שְׁמוֹנֶה שְׁמוֹנָה תֵּשַׁע תִּשְׁעָה תְּשַׁע עֶשֶׂר עֲשָׂרָה עָשָׂר עֶשְׂרֵה '
    'עֶשְׂרִים שְׁלוֹשִׁים אַרְבָּעִים חֲמִשִּׁים שִׁשִּׁים שִׁבְעִים שְׁמוֹנִים תִּשְׁעִים מֵאָה').split()}
NUMBER_PREFIX = ('ו', 'ב', 'ל', 'מ', 'ה', 'ש', 'כ')
STEP_WORDS = {'ימינה', 'שמאלה', 'למעלה', 'למטה', 'קדימה', 'אחורה'}

# Words a TTS can read two ways when they are written without points. Each proposal keeps the letters and adds the
# points of the meaning in the lesson. The text editor confirms; the owner hears it in the audition first.
PRONUNCIATION = OrderedDict([
    ('חום', ('חוּם', 'the colour (chum), not heat (chom)')),
    ('החום', ('הַחוּם', 'the colour (ha-chum), not the heat')),
    ('חסר', ('חָסֵר', 'missing (chaser); the verb chasar is wrong here')),
    ('החסר', ('הֶחָסֵר', 'the missing one (he-chaser)')),
    ('שווה', ('שָׁוֶה', 'equals (shave), as the = sign is read (CLAUDE.md)')),
    ('שווים', ('שָׁוִים', 'equal (shavim)')),
    ('שוות', ('שָׁווֹת', 'equal (shavot)')),
    ('מספר', ('מִסְפָּר', 'a number (mispar), not "tells" (mesaper)')),
    ('המחוג', ('הַמָּחוֹג', 'the clock hand (ha-machog), a rare word')),
    ('ברונזה', ('בְּרוֹנְזָה', 'bronze, a loan word (bronza)')),
    ('מדליה', ('מֶדַלְיָה', 'medal, a loan word (medalya)')),
    ('וואו', ('וָאוּ', 'wow (vau), not va-u or vav')),
    ('המממ', ('הַמְּמ', 'a thinking hum; must not be read as letters (ha-mem-mem)')),
    ('המשושה', ('הַמְּשֻׁשֶּׁה', 'the hexagon (ha-meshushe)')),
    ('המחומש', ('הַמְּחֻמָּשׁ', 'the pentagon (ha-mechumash), not chumash')),
    ('הגליל', ('הַגְּלִיל', 'the cylinder (ha-galil)')),
    ('החרוט', ('הַחָרוּט', 'the cone (ha-charut)')),
    ('התיבה', ('הַתֵּבָה', 'the box (ha-teva)')),
    ('המאזניים', ('הַמֹּאזְנַיִם', 'the scales (ha-moznayim)')),
    ('נבט', ('נֶבֶט', 'a sprout (nevet)')),
    ('הפירמידה', ('הַפִּירָמִידָה', 'the pyramid (ha-piramida), stress on mi')),
    ('בתור', ('בַּתּוֹר', 'in the queue (ba-tor): every voiced line with it is about a queue (ordinals)')),
])

# The proposed style of each kind of line (content/voices.proposed.json › styles holds the numbers).
STYLE_OF_KIND = {
    'question': 'ask', 'instruction': 'ask', 'answer-prompt': 'ask',
    'hint-1': 'hint', 'hint-2': 'hint', 'hint-3': 'model', 'list': 'list',
    'correct': 'warm', 'not-yet': 'gentle', 'unsure': 'warm',
    'celebration': 'cheer', 'cheer': 'cheer', 'ceremony': 'ceremony', 'greeting': 'greet',
    'encourage': 'warm', 'thinking': 'think', 'listen': 'gentle', 'calm': 'calm', 'goodbye': 'calm',
    'tutor': 'tutor',
}
# Seconds the line should fit in (pause budget), at the style's speed; a longer line is flagged.
BUDGET = {   # a guess from the design spec (Tier 1 is short, Tier 2 is 2 to 3 s) and the measured rate; not measured
    'question': 8, 'instruction': 8, 'answer-prompt': 3, 'hint-1': 6, 'hint-2': 8, 'hint-3': 12, 'list': 16,
    'correct': 6, 'not-yet': 6.5, 'unsure': 3.5, 'celebration': 4.5, 'cheer': 2.5, 'ceremony': 3, 'greeting': 3,
    'encourage': 5, 'thinking': 3, 'listen': 5.5, 'calm': 4.5, 'goodbye': 5, 'tutor': 7,
}
BAND_SPEED = {'A': -0.03, 'B': 0.0, 'C': 0.03, '': 0.0, 'mixed': -0.02}


def load_styles():
    with open(PROPOSED, encoding='utf-8') as f:
        return json.load(f)['styles']


def walk_vo(doc, path):
    """The node at a master-table id path (`feedback.incorrect.0.caption.0.v`) minus its caption part."""
    parts = path.split('.')
    if 'caption' in parts:
        parts = parts[:parts.index('caption')]
    node = doc
    for p in parts:
        node = node[int(p)] if isinstance(node, list) else node.get(p)
        if node is None:
            return None
    return node


def kind_of(row, node_path, text):
    plain = PLAIN(text)
    words = [w.strip('.,?…:—') for w in plain.split()]
    nums = sum(1 for w in words if w in NUMBER_WORDS or (len(w) > 2 and w[0] in NUMBER_PREFIX and w[1:] in NUMBER_WORDS))
    steps = sum(1 for w in words if w in STEP_WORDS)
    commas = text.count(',')
    segs = [x.strip() for x in re.split(r'[,:.]', plain) if x.strip()]
    short = sum(1 for x in segs if len(x.split()) <= 2)
    is_list = ((nums >= 5 and commas >= 4) or (steps >= 3 and commas >= 2)
               or (commas >= 4 and short >= commas))   # colours, animals, routine steps
    g = row['group'][0]
    if g == '2':
        cid = row['id']
        for pre, k in (('core.greeting', 'greeting'), ('core.celebrate', 'cheer'), ('core.ceremony', 'ceremony'),
                       ('core.placement', 'encourage'), ('core.thinking', 'thinking'), ('core.listen', 'listen'),
                       ('core.stuck', 'calm'), ('core.breathe', 'calm'), ('core.goodbye', 'goodbye'),
                       ('core.encourage.check', 'thinking'), ('core.encourage.almost', 'not-yet'),
                       ('core.encourage', 'encourage')):
            if cid.startswith(pre):
                return k, is_list
    if g == '4':
        return 'tutor', is_list
    head = node_path.split('.')[0]
    if head == 'prompt':
        k = 'question' if text.rstrip().endswith('?') else 'instruction'
    elif head == 'answerPrompt':
        k = 'answer-prompt'
    elif head == 'hints':
        k = 'hint-%d' % (int(node_path.split('.')[1]) + 1)
    elif head == 'feedback':
        sub = node_path.split('.')[1]
        k = {'correct': 'correct', 'incorrect': 'not-yet', 'unsure': 'unsure'}.get(sub, 'not-yet')
    elif head == 'celebration':
        k = 'celebration'
    else:
        k = 'instruction'
    if is_list and k in ('hint-1', 'hint-2', 'hint-3', 'instruction', 'question', 'correct', 'not-yet'):
        return 'list', True
    return k, is_list


def pause_notes(text, kind, is_list):
    notes = []
    if kind == 'correct' and re.match(r'^[^\s,.]+(\s[^\s,.]+)?\.', text) and any(
            PLAIN(t.strip('.')) in NUMBER_WORDS for t in text.split('.')[0].split()):
        notes.append('number answer alone, then a full beat (about 400 ms) before the reason')
    if kind == 'correct' and text.startswith('לא,'):
        notes.append('a correct answer that starts with "no": the "לא" is the answer, said bright and sure, then a beat')
    if text.startswith(('כן,', 'כמעט,', 'יפה,', 'וואו,', 'יופי,', 'נכון,')):
        notes.append('short opener, a light comma beat (about 200 ms), no exclamation')
    if '—' in text:
        notes.append('dash = a held beat (about 300 ms), not a stop')
    if ':' in text:
        notes.append('colon = a small lift and a beat before what follows')
    if '…' in text:
        notes.append('ellipsis = a thinking pause (about 500 ms), the pitch stays up')
    if is_list:
        n = text.count(',')
        notes.append('%d list commas: an even breath on each (about 250 to 350 ms), same pitch every item, '
                     'the last item lands down' % n)
    if text.count('.') + text.count('?') >= 2 and not is_list:
        notes.append('%d sentences: a full stop is a real pause (about 450 ms)' % (text.count('.') + text.count('?')))
    if text.rstrip().endswith('?'):
        notes.append('question: a soft rise at the end, curious, not testing')
    return '; '.join(notes)


def listen_for(text, kind, is_list):
    out = {
        'question': 'clear, unhurried, the key word (object, colour, number) slightly stressed',
        'instruction': 'calm and clear, the verb first and plain; never bossy',
        'answer-prompt': 'short and light; ends open so the child answers',
        'hint-1': 'helpful, a little slower than the question; no sigh',
        'hint-2': 'slower, pointing with the voice; no impatience',
        'hint-3': 'a worked example: slow, every step said clearly, then "now your turn" bright and inviting',
        'list': 'every item said fully at an even pace; no item clipped or swallowed; the numbers keep their gender',
        'correct': 'warm and glad, not loud; the reason said calmly after the opener',
        'not-yet': 'curious and kind, never disappointed; no falling "sad" pitch on כמעט',
        'unsure': 'welcoming, as if asking for help is good news',
        'celebration': 'bright but short, a smile in the voice; no shout, no clipping at the end',
        'cheer': 'a quick bright cheer, not a shout; peak level kept',
        'ceremony': 'proud and warm, a little slower, a gift being handed over',
        'greeting': 'friendly, as meeting a friend; the character\'s own colour',
        'encourage': 'sincere praise of the effort, never sugary',
        'thinking': 'the hum must sound like a hum (not letters), then a light thoughtful line',
        'listen': 'soft, the fault is the helper\'s ears, never the child\'s speech',
        'calm': 'slow and soft, a quiet ending',
        'goodbye': 'soft, warm, a quiet end; no "come back" pressure',
        'tutor': 'same voice and loudness as the lesson lines around it; addressed in the right gender form',
    }[kind]
    extra = []
    pointed = [w for w in re.findall(r'\S+', text) if NIKUD.search(w)]
    if pointed:
        extra.append('pointed words read as pointed: ' + ' '.join(w.strip('.,?:…—') for w in pointed[:6]))
    if 'שֵׁנִי' in text or 'הַשֵּׁנִי' in text:
        extra.append('שני is the ordinal (sheni), not "two of" (shnei)')
    if re.search(r'(^|\s)ו?ה?ממ', PLAIN(text)) or 'המממ' in text:
        extra.append('the hum: audition, it may be spelled out')
    return out + ('; ' + '; '.join(extra) if extra else '')


def pron_entries(text):
    found = []
    for token in re.findall(r'[א-תְ-ׇ]+', text):
        if token in PRONUNCIATION:
            to, why = PRONUNCIATION[token]
            found.append('%s → %s (%s)' % (token, to, why))
    return '; '.join(OrderedDict.fromkeys(found))


def editor_note(text, kind, est, budget, is_list, row_ids):
    notes = []
    plain = PLAIN(text)
    if is_list and text.count(',') >= 8:
        notes.append('LONG LIST: %d items; the commas are the breaths. Only if the audition shows it rushed: ask for '
                     '"…" instead of "," between the numbers (hebrew-notes.md section 6 offers it); no change asked '
                     'before that' % (text.count(',') + 1))
    if est > budget * 1.25:
        notes.append('LONG: about %.0f s against a %.0f s budget; ask the editor for a full stop to split it into two '
                     'breaths, or a shorter wording' % (est, budget))
    if re.search(r'^\S+, ועוד', text):
        notes.append('comma between a number and "ועוד" makes a pause inside the sum; the other sums have none '
                     '(e.g. "שֵׁשׁ ועוד שָׁלוֹשׁ:"); ask to drop the comma for a single sum phrase')
    if kind == 'correct' and text.startswith('לא,'):
        notes.append('a correct line that starts "לא," can sound like a not-yet; ask for "לא." (the answer alone, '
                     'then the reason, as for number answers)')
    m = re.search(r'ללחוץ על (\S+)\.$', text)
    if is_list and m and re.match(r'^\S+,? ועוד \S+:', text):
        listed = [w.strip() for w in text.split(':', 1)[1].split('.')[0].split(',')]
        if listed and PLAIN(listed[-1]) != PLAIN(m.group(1)):
            notes.append('heard aloud, the count ends on %s but the child is asked to press %s (the same problem '
                         'as G1 in hebrew-notes.md); for the editor and the owner' % (listed[-1], m.group(1)))
    return '; '.join(notes)


def main():
    styles = load_styles()
    rows = list(csv.DictReader(open(MASTER, encoding='utf-8-sig')))
    ready = [r for r in rows if r['status'] == 'text-ready' and r['spoken'] == 'yes' and r['voice_text'].strip()]
    docs = {}

    def doc(name):
        if name not in docs:
            p = os.path.join(STARTER, name)
            docs[name] = json.load(open(p, encoding='utf-8')) if os.path.exists(p) else None
        return docs[name]

    lines = OrderedDict()   # voice_text -> info
    unvoiced = Counter()
    for r in ready:
        g = r['group'][0]
        vo, band, node_path = '', '', r['id']
        if g == '3':
            d = doc(r['source'])
            if d is None:
                unvoiced['no content file'] += 1
                continue
            band = d.get('band', '') or ''
            node = walk_vo(d, r['id'])
            if r['id'].startswith('childLine'):
                unvoiced['skill childLine (shown on the map card, no vo id: not voiced by the app)'] += 1
                continue
            if not isinstance(node, dict) or not str(node.get('vo', '')).startswith('vo:'):
                unvoiced['no vo id at this path'] += 1
                continue
            vo = node['vo']
        elif g == '2':
            vo = 'vo:' + r['id']
        elif g == '4':
            vo = 'tutor:' + r['id']
            m = re.search(r'band (\w)', r['id'])
            band = m.group(1) if m else ''
        else:
            unvoiced['group %s' % g] += 1
            continue
        kind, is_list = kind_of(r, node_path, r['voice_text'])
        t = r['voice_text'].strip()
        info = lines.setdefault(t, {'first': r, 'rows': 0, 'vos': OrderedDict(), 'kinds': Counter(),
                                    'bands': Counter(), 'is_list': is_list, 'group': g})
        info['rows'] += 1
        info['vos'][vo] = True
        info['kinds'][kind] += 1
        info['bands'][band] += 1

    out_rows = []
    for t, info in lines.items():
        kind = info['kinds'].most_common(1)[0][0]
        bands = [b for b in info['bands'] if b]
        band = bands[0] if len(set(bands)) == 1 else ('mixed' if bands else '')
        g = info['group']
        style = STYLE_OF_KIND[kind]
        if g == '2':
            voices = 'own: every friend in its own voice (9)'
            scope = 'own'
        elif g == '4':
            voices = 'hero-son (live helper, gateway pre-warm; see section 2.6)'
            scope = 'tutor'
        else:
            voices = 'nitzi + hero-son (narrators; friends borrow by voice)'
            scope = 'narrator'
        speed = round(styles[style]['speed'] + BAND_SPEED.get(band, 0.0), 2)
        speed = max(0.8, min(1.1, speed))
        words = len(t.split())
        est = words / (WORDS_PER_SEC * speed) + (0.3 * t.count(',') if info['is_list'] else 0)
        budget = BUDGET[kind]
        pace = '%s, speed %.2f, about %.1f s (budget %.0f s)%s' % (
            {'A': 'Band A slow', 'B': 'Band B natural', 'C': 'Band C natural', 'mixed': 'shared across bands',
             '': 'outside lessons'}[band], speed, est, budget, '  OVER' if est > budget else '')
        first = info['first']
        key = '%s › %s' % (first['source'], first['id'])
        out_rows.append(OrderedDict([
            ('line_key', key),
            ('rows_sharing', info['rows']),
            ('vo_ids', len(info['vos'])),
            ('first_vo', next(iter(info['vos']))),
            ('kind', kind),
            ('band', band),
            ('scope', scope),
            ('voices', voices),
            ('style', style),
            ('speed', '%.2f' % speed),
            ('pace', pace),
            ('pause_notes', pause_notes(t, kind, info['is_list'])),
            ('listen_for', listen_for(t, kind, info['is_list'])),
            ('pronunciation', pron_entries(t)),
            ('note_for_text_editor', editor_note(t, kind, est, budget, info['is_list'], info['vos'])),
            ('chars', len(t)),
            ('voice_text', t),
        ]))

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'w', encoding='utf-8-sig', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(out_rows[0].keys()))
        w.writeheader()
        w.writerows(out_rows)

    # ---- the plan (characters and cost) ----
    def chars(sel):
        return sum(r['chars'] for r in out_rows if sel(r))

    narr_lesson = chars(lambda r: r['scope'] == 'narrator')
    core_all = chars(lambda r: r['scope'] == 'own')
    tutor = chars(lambda r: r['scope'] == 'tutor')
    own_min_ids = ('core.greeting', 'core.celebrate', 'core.ceremony', 'core.goodbye', 'core.placement')
    core_min = chars(lambda r: r['scope'] == 'own' and r['first_vo'][3:].startswith(own_min_ids))
    celebr = chars(lambda r: r['kind'] == 'celebration')
    n_lines = Counter(r['scope'] for r in out_rows)
    vo_count = sum(r['vo_ids'] for r in out_rows if r['scope'] == 'narrator')
    vo_chars = 0  # characters if every vo id is voiced separately (how voice_gen counts today)
    for t, info in lines.items():
        if info['group'] == '3':
            vo_chars += len(t) * len(info['vos'])

    # (c) lines that already have audio in the work folders and would be voiced again.
    existing = {}
    for c in NARRATORS + FRIENDS:
        d = os.path.join(VOICE_HOME, c)
        existing[c] = {os.path.basename(p)[3:-4] for p in glob.glob(os.path.join(d, 'vo.*.mp3'))} if os.path.isdir(d) else set()
    text_of_vo = {}
    for t, info in lines.items():
        for v in info['vos']:
            text_of_vo[v] = t
    revoice = {}
    for c, ids in existing.items():
        mine = [i for i in ids if 'vo:' + i in text_of_vo]
        lesson_ids = [i for i in mine if not i.startswith('core.')]
        gone = [i for i in ids if 'vo:' + i not in text_of_vo]
        if c in NARRATORS:
            keep = mine
        else:
            keep = [i for i in mine if i.startswith('core.')]
        revoice[c] = (len(keep), sum(len(text_of_vo['vo:' + i]) for i in keep), len(lesson_ids) if c in FRIENDS else 0,
                      len(gone))

    p = PRICE_PER_1000 / 1000
    print('Distinct voiced texts: %d (narrator %d, own core %d, tutor %d) from %d text-ready spoken rows'
          % (len(out_rows), n_lines['narrator'], n_lines['own'], n_lines['tutor'], len(ready)))
    print('Not voiced by the app:', dict(unvoiced))
    print('Narrator lesson lines: %d distinct texts, %d characters per voice (voiced per vo id instead: %d vo ids, '
          '%d characters)' % (n_lines['narrator'], narr_lesson, vo_count, vo_chars))
    print('Core lines (own lines): %d texts, %d characters per voice; minimal own set %d characters; lesson '
          'celebrations %d characters' % (n_lines['own'], core_all, core_min, celebr))
    a = 2 * (narr_lesson + core_all)
    b = len(FRIENDS) * core_all
    print('(a) narrators: 2 x %d = %d characters, %.2f USD' % (narr_lesson + core_all, a, a * p))
    print('(b) friends own core lines: 7 x %d = %d characters, %.2f USD' % (core_all, b, b * p))
    print('(b-min) friends minimal own set: 7 x %d = %d characters, %.2f USD' % (core_min, 7 * core_min, 7 * core_min * p))
    print('(b+) friends own core + lesson celebrations: 7 x %d = %d, %.2f USD' % (core_all + celebr, 7 * (core_all + celebr), 7 * (core_all + celebr) * p))
    print('(t) hero-son tutor lines: %d characters, %.2f USD (gateway pre-warm)' % (tutor, tutor * p))
    print('(a)+(b): %d characters, %.2f USD, %.2f Creator months' % (a + b, (a + b) * p, (a + b) / CREATOR_MONTH))
    print('(a) per vo id instead of per text: %d characters, %.2f USD' % (2 * (vo_chars + core_all), 2 * (vo_chars + core_all) * p))
    print('(c) already voiced, voiced again (included in a and b):')
    tot_c = 0
    for c, (n, ch, lesson_in_friend, gone) in revoice.items():
        tot_c += ch
        print('    %-16s %3d lines, %5d characters%s%s' % (
            c, n, ch, ('; %d lesson lines in its folder must be moved away (they would shadow the narrator)' %
                       lesson_in_friend) if lesson_in_friend else '',
            ('; %d files have no text-ready line any more' % gone) if gone else ''))
    print('    total %d characters, %.2f USD' % (tot_c, tot_c * p))
    for c in NARRATORS:
        print('Per narrator %s: %d characters, %.2f USD' % (c, narr_lesson + core_all, (narr_lesson + core_all) * p))
    over = sum(1 for r in out_rows if 'OVER' in r['pace'])
    print('Lines over their pause budget: %d; with a note for the text editor: %d; with a pronunciation proposal: %d'
          % (over, sum(1 for r in out_rows if r['note_for_text_editor']), sum(1 for r in out_rows if r['pronunciation'])))
    print('Kinds:', dict(Counter(r['kind'] for r in out_rows)))
    write_audition({r['voice_text']: r for r in out_rows}, styles)

    if '--sample' in sys.argv:
        n = int(sys.argv[sys.argv.index('--sample') + 1])
        rnd = random.Random(20261028)
        pick = rnd.sample(out_rows, min(n, len(out_rows)))
        for r in pick:
            print('---', r['line_key'], '|', r['kind'], r['band'], r['style'], r['speed'], '| x%s' % r['rows_sharing'])
            print('   ', r['voice_text'])
            print('    pause:', r['pause_notes'])
            if r['pronunciation']:
                print('    pron:', r['pronunciation'])
            if r['note_for_text_editor']:
                print('    EDITOR:', r['note_for_text_editor'])


AUDITION = os.path.join(ROOT, 'docs', 'audio', 'audition.csv')
# Twelve lines that cover the kinds of line and the risky words (voice-direction.md section 7, set A).
AUDITION_LINES = [
    'שלום, בואו נשחק.', 'יש שְׁלוֹשָׁה דגים. אֶחָד שחה משם. כמה נשארו?', 'איפה הפרח החום?', 'בואו נקשיב שוב לשאלה.',
    'אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. המספר האחרון אומר כמה: חָמֵשׁ. עכשיו תורכם — ללחוץ על חָמֵשׁ.',
    'הצעדים הם: למעלה, למעלה, ימינה, ימינה, למעלה. עכשיו תורכם.', 'חָמֵשׁ. תֵּשַׁע פחות אַרְבַּע שווה חָמֵשׁ.',
    'כמעט, בואו ננסה שוב.', 'שאלה טובה, בואו נראה יחד.', 'המממ… בואו נספור לאט, מספר אחרי מספר.',
    'וואו, ספרתם עד עֶשֶׂר.', 'הנה גביע ברונזה בשבילכם.',
]
FRIEND_LINES = ['שלום, בואו נשחק.', 'כל הכבוד.', 'הנה גביע ברונזה בשבילכם.']
CHEER_LINES = ['וואו, ספרתם עד עֶשֶׂר.', 'כל הכבוד.', 'נפלא, העשרות כבר מוכרות.']
PRON_LINES = ['איפה הפרח החום?', 'המממ… בואו נספור לאט, מספר אחרי מספר.', 'וואו, ספרתם עד עֶשֶׂר.',
              'הנה גביע ברונזה בשבילכם.', 'חָמֵשׁ. תֵּשַׁע פחות אַרְבַּע שווה חָמֵשׁ.', 'המחוג הקצר והעבה אומר את השעה.']


def settings_arg(st):
    keys = (('stability', 'stability'), ('similarity_boost', 'similarity'), ('style', 'style'),
            ('use_speaker_boost', 'boost'), ('speed', 'speed'))
    return ','.join('%s=%s' % (short, str(st[k]).lower()) for k, short in keys if k in st)


def respell_words(text):
    pron = json.load(open(PROPOSED, encoding='utf-8'))['pronunciation']
    return re.sub(r'[א-תְ-ׇ]+', lambda m: pron.get(m.group(0), m.group(0)), text)


def write_audition(by_text, styles):
    """docs/audio/audition.csv: every clip of the proposed audition, with the exact text and settings to send.
    Nothing is sent here; the owner runs it (voice-direction.md section 7)."""
    rows = []
    current = {k: v['voiceId'] for k, v in json.load(open(os.path.join(ROOT, 'content', 'voices.json'),
                                                           encoding='utf-8'))['voices'].items()}

    def add(set_, character, candidate, style, text, why):
        st = styles[style]
        # cand2 / cand3 / chosen: the owner fills in the voice id he picked in the ElevenLabs voice library.
        vid = current.get(character, '') if candidate == 'current' else ''
        rows.append(OrderedDict([('clip', '%s-%02d' % (set_, len(rows) + 1)), ('set', set_), ('character', character),
                                 ('candidate', candidate), ('voice_id', vid), ('style', style),
                                 ('settings', settings_arg(st)),
                                 ('chars', len(text)), ('why', why), ('text', text)]))

    for c in NARRATORS:
        for cand in ('current', 'cand2', 'cand3'):
            for t in AUDITION_LINES:
                r = by_text.get(t)
                add('A', c, cand, r['style'] if r else 'ask', t, 'voice choice: %s' % (r['kind'] if r else '?'))
    for c in FRIENDS:
        for cand in ('current', 'cand2', 'cand3'):
            for t in FRIEND_LINES:
                add('A', c, cand, 'greet' if t.startswith('שלום') else ('ceremony' if 'גביע' in t else 'cheer'), t,
                    'friend voice choice')
    for c in NARRATORS:
        for t in CHEER_LINES:
            add('B', c, 'chosen', 'cheer', t, 'cheer proposed (calmer)')
            add('B', c, 'chosen', 'cheer_current', t, 'cheer as today (stability 0.1, style 0.9)')
        for t in PRON_LINES:
            add('B', c, 'chosen', by_text[t]['style'] if t in by_text else 'ask', respell_words(t),
                'pronunciation entry applied (compare with set A, same line without it)')
    base = 'בואו נקשיב שוב לשאלה.'
    for label, over in (('speed 0.80', {'speed': 0.8}), ('speed 1.20', {'speed': 1.2}),
                        ('style 0.0', {'style': 0.0}), ('style 0.9', {'style': 0.9})):
        st = dict(styles['hint'], **over)
        styles['_test'] = st
        add('C', 'nitzi', 'chosen', '_test', base, 'does eleven_v4_turbo honour %s? (measure the length)' % label)
    with open(AUDITION, 'w', encoding='utf-8-sig', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    by_set = Counter()
    for r in rows:
        by_set[r['set']] += r['chars']
    total = sum(by_set.values())
    print('Audition: %d clips, %d characters (%s), %.2f USD at %.2f per 1,000; written to %s'
          % (len(rows), total, ', '.join('set %s %d' % kv for kv in sorted(by_set.items())), total * PRICE_PER_1000 / 1000,
             PRICE_PER_1000, os.path.relpath(AUDITION, ROOT)))


if __name__ == '__main__':
    main()
