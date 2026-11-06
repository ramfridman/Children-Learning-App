"""Band C of the six lands (M10): the unit specs, written from compact tables, the way tools/band_b.py writes Band B's. Then run
tools/author.py on each spec (tools/regen_content.py does both, in the one order that reproduces the committed files).

    python tools/band_c.py            # writes the specs of the batches that have tables
    python tools/band_c.py C1 C2      # only those batches

This is the skeleton (M10 step 0.4): the unit class, the batch registry, the helpers a table needs for the new items (a number
sentence in tokens, a number-entry item), and nothing else. There is no content in it. Each batch adds its tables in step 2 of its
nine steps (docs/milestones/M10.md section 10), from the batch spec of the curriculum-expert and the checked item tables of the
maths and CS teachers; a table is a function that fills one unit and is registered with @table:

    @table('C1', 'numbers', assets=['apple'])
    def numbers_c1(u):
        u.skill('NUM-C-01', 'title', 'line for the child', 'cone-tree', ['NUM-B-02'], ['pictorial', 'symbolic'], tags=['M-CNT-DECADE'])
        number_item(u, 'NUM-C-01', 'the question', [39, '+', 1, '=', '?'], 40, {30: 'M-CNT-DECADE'}, h2='...', h3='...', ok='...')
        u.lesson('count-on-1', 'title', ['NUM-C-01'], [...], 'celebration')

Every Hebrew text is a draft by the table's author and stays `needs-editor` until the hebrew-text-editor makes it `text-ready`; this
file writes none of its own. Nothing is voiced here (owner, 2026-11-06).
"""
import os
import sys

ARGS = sys.argv[1:]  # band_b sets sys.argv for author.py, which is imported and never run: the batches asked for are read first
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from band_b import Unit, write_all  # noqa: E402
from author import NUMBER_MAX, NUMBER_RULES  # noqa: E402,F401

BATCHES = ('C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9')

# Where a batch's lessons start on the path of their land: after Band A (from 1) and Band B (from 30, the extras from 60). The lessons
# of a batch are numbered up from here in the order of the table, so a land's path walks batch by batch, and the path gate (E0) holds a
# lesson back until its skills are unlocked.
FIRST_SEQUENCE_C1 = 100
SEQUENCE_STEP = 30

# The signs a row or a cell may hold (the validator's `op:` tokens) and what they are called in a table.
SIGNS = ('+', '-', 'x', ':', '=', '<', '>', '(', ')')


def first_sequence(batch):
    return FIRST_SEQUENCE_C1 + SEQUENCE_STEP * BATCHES.index(batch)


class UnitC(Unit):
    """One Band C unit: the lessons of one batch in one land. Like a Band B unit, with the band C, the batch in its name
    (`band-c1-numbers`), the activity ids from `c.` (`c.numc01.1`), and its lessons on the path from the batch's first sequence."""
    BAND = 'C'
    OWN_SPECS = 'band-c'

    def __init__(self, batch, domain, note, assets=(), globs=(), first_seq=None):
        assert batch in BATCHES, 'unknown batch %r' % (batch,)
        name = 'band-%s-%s' % (batch.lower(), domain)
        super().__init__(name, domain, note, first_seq or first_sequence(batch), assets=assets, globs=globs, prefix='c')
        self.batch = batch


# The tables, in the order they were registered: (batch, domain, builder, keywords of the unit).
TABLES = []


def table(batch, domain, **unit):
    """Registers the table of one unit: the function fills the UnitC it is given (skills, tags, items, lessons)."""
    def register(build):
        TABLES.append((batch, domain, build, unit))
        return build
    return register


def tokens(*parts):
    """A number sentence as the row tokens of a tap_answer: an int is a number (`n:52`), a sign is `op:`, '?' is the gap.

        tokens(52, '-', 27, '=', '?')  ->  ['n:52', 'op:-', 'n:27', 'op:=', '?']

    A number is at most NUMBER_MAX (10,000); a sign is one of SIGNS."""
    out = []
    for p in parts:
        if p == '?':
            out.append('?')
        elif isinstance(p, int) and not isinstance(p, bool):
            assert 0 <= p <= NUMBER_MAX, '%r is not a number to %d' % (p, NUMBER_MAX)
            out.append('n:%d' % p)
        else:
            assert p in SIGNS, '%r is not a sign of a number sentence' % (p,)
            out.append('op:%s' % p)
    return out


def number_item(u, skill, prompt, row, value, expected=None, rules=None, h2=None, h3=None, ok=None, **kw):
    """A number-entry item (X3): the child types the number that makes the row true. `row` is a list of parts for `tokens`; `expected`
    is {wrong number: tag} for the wrong numbers the author expects; `rules` is {rule: tag} (author.NUMBER_RULES) for the classifiers
    that name any other wrong number. `h2` and `h3` are the harder hints and `ok` the line for the right answer: all text of the table."""
    return u.act(skill, 'number', prompt=prompt, row=tokens(*row), value=value, expected=dict(expected or {}),
                 rules=dict(rules or {}), h2=h2, h3=h3, correct_text=ok, **kw)


# ======================================================================================== C1: numbers to 100, facts
#
# The tables of batch C1 (docs/milestones/M10.md §4.1, §4.2, §4.7 and §7; the maths teacher, 2026-11-06). Every item is one that
# today's sessions draw: tap_answer rows and choices, number_line, flash, balance and spot_error. The items that need a stage picture
# (base_ten, hundred_chart) or the keypad (answer type number) wait for batch step 3 and are specified in
# docs/knowledge/maths/c1-deferred.md; none of them is in content. Every answer and every tag rule is recomputed by
# tools/check_maths.py. Hebrew: drafts, `needs-editor`, plural address, = read שָׁוֶה.

from author import F, from_, prefix, qty, vav  # noqa: E402
from band_b import NAMES, SHEKEL, steps as step_words  # noqa: E402

BLOCK = NAMES['block'] | {'many': 'קֻבִּיּוֹת'}
NOW = 'עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.'


def tens_words(t):
    """'three tens', the school pattern (owner, 2026-11-06): the digit, then always the plural עֲשָׂרוֹת (feminine):
    אֶחָד עֲשָׂרוֹת, שְׁתֵּי עֲשָׂרוֹת, שָׁלוֹשׁ עֲשָׂרוֹת …"""
    return {1: 'אֶחָד עֲשָׂרוֹת', 2: 'שְׁתֵּי עֲשָׂרוֹת'}.get(t, '%s עֲשָׂרוֹת' % F[t])


def ones_words(o):
    """'four ones', the same pattern (owner, 2026-11-06): אֶחָד יְחִידוֹת, שְׁתֵּי יְחִידוֹת, אַרְבַּע יְחִידוֹת, אֶפֶס יְחִידוֹת."""
    return {1: 'אֶחָד יְחִידוֹת', 2: 'שְׁתֵּי יְחִידוֹת'}.get(o, '%s יְחִידוֹת' % F[o])


def placed(correct, wrong, i):
    """The options: the wrong ones in the table's order, the right one put in the place the item's number picks."""
    out = list(wrong)
    out.insert(i % (len(out) + 1), correct)
    return out


def choose(u, skill, prompt, correct, wrong, i, h2, h3, ok, row=None, **kw):
    """A tap_answer with numerals on tiles. `wrong` is {number: tag}: every wrong option carries the misconception it shows.
    `row` is a number sentence for `tokens` (its gap is the '?')."""
    assert correct not in wrong and all(wrong.values()), 'every wrong option is tagged and none is the answer'
    values = placed(correct, list(wrong), i)
    if row is not None:
        kw['row'] = tokens(*row)
    return u.act(skill, 'pick', prompt=prompt, options=['n:%d' % v for v in values], correct='n:%d' % correct,
                 tags={'n:%d' % v: t for v, t in wrong.items()}, h2=h2, h3=h3, correct_text=ok, **kw)


def lesson_of(u, lid, title, skill, done, a=0, b=None, minutes=6, band=None):
    items = [x['id'] for x in u.d['activities'] if x['skill'] == skill][a:b]
    u.lesson(lid, title, [skill], items, done, minutes=minutes)
    if band:
        u.d['lessons'][-1]['band'] = band


def bridge(u):
    """The skill just added is a bridge skill of Band A or B (M10 §4.7): its file says its own band."""
    u.d['skills'][-1]['band'] = 'B'


def jump(u, skill, frm, to, start, hop, labels=None, **kw):
    """The frog stands on `start` on a line from `frm` to `to` and hops `hop` (forward or back); the child says where it lands."""
    k, way = abs(hop), 'קָדִימָה' if hop > 0 else 'אֲחוֹרָה'
    steps = step_words(k)
    end = start + hop
    marks = sorted(set((labels or [frm, to]) + [start]))
    return u.act(skill, 'numline', mode='jump', **{'from': frm}, to=to, start=start, hops=[hop], target=end, labels=marks,
                 check=kw.pop('check', 'predict'),
                 prompt='הַצְּפַרְדֵּעַ עוֹמֶדֶת עַל %s וְקוֹפֶצֶת %s %s. עַל אֵיזֶה מִסְפָּר הִיא תִּנְחַת?' % (F[start], steps, way),
                 h3='מַתְחִילִים %s וְקוֹפְצִים %s %s: %s. עַכְשָׁו תּוֹרְכֶם.' % (
                     from_(F[start]), steps, way, ', '.join(F[start + (d if hop > 0 else -d)] for d in range(1, k + 1))
                     if k <= 6 else F[end]),
                 correct_text='%s! הַצְּפַרְדֵּעַ נָחֲתָה עַל %s.' % (F[end], F[end]), **kw)


def place_on(u, skill, frm, to, target, labels, **kw):
    """Put the frog on `target` on a line from `frm` to `to` (ticks of one; the labels are the landmarks)."""
    near = max(v for v in labels if v <= target)
    via = ''
    if target - near > 6:  # only the ends are marked: ten steps first, then count on
        via = '%s עֲשָׂרָה צְעָדִים קָדִימָה הֵם %s, וּמִשָּׁם ' % (from_(F[near]), F[near + 10])
        near += 10
    walk = ', '.join(F[v] for v in range(near + 1, target + 1))
    return u.act(skill, 'numline', mode='place', **{'from': frm}, to=to, target=target, labels=labels,
                 prompt='הַצְּפַרְדֵּעַ רוֹצָה לַעֲמֹד עַל %s. נוֹגְעִים בַּמָּקוֹם.' % F[target],
                 h3=('%sסוֹפְרִים קָדִימָה: %s. עַכְשָׁו תּוֹרְכֶם.' % (via, walk) if via else
                     'מַתְחִילִים %s וְסוֹפְרִים קָדִימָה: %s. עַכְשָׁו תּוֹרְכֶם.' % (from_(F[near]), walk)) if walk else
                 'הַמִּסְפָּר כְּתוּב עַל הַצִּיר. עַכְשָׁו תּוֹרְכֶם.',
                 correct_text='%s! הַצְּפַרְדֵּעַ בַּמָּקוֹם הַנָּכוֹן.' % F[target], **kw)


@table('C1', 'numbers', assets=['frog', 'coin_s10', 'coin_s1', 'apple', 'star', 'fish', 'duck', 'ladybug', 'bird'],
       note='Band C, batch C1, Counting Hills: numbers to 100 (NUM-C-01 to C-04, C-06, C-09) and the bridge skills NUM-B-06 and '
            'NUM-B-09. Only items that today\'s sessions draw; the base_ten, hundred_chart and number-entry items are in '
            'docs/knowledge/maths/c1-deferred.md. Hebrew is a draft, needs-editor.')
def numbers_c1(u):
    u.tag('M-PV-FACE', ['NUM-C-03', 'NUM-C-04', 'MATH-C-03'],
          'הילד קורא כל ספרה לפי הערך שלה לבד ולא לפי המקום שלה: ב-34 ה-3 הוא "שלוש" ולא שלושים, ו-41 נראה לו קטן מ-39 כי 1 קטן מ-9.',
          'לשחק בחנות עם מטבעות של עשר ושל שקל: לבנות יחד 34 בשלושה מטבעות של עשר וארבעה של שקל, ולשאול כמה שווים המטבעות של העשר.',
          ['concrete', 'pictorial'], 'הַסִּפְרָה הַזֹּאת עוֹמֶדֶת בַּמָּקוֹם שֶׁל הָעֲשָׂרוֹת. בּוֹאוּ נִבְדֹּק כַּמָּה עֲשָׂרוֹת יֵשׁ.')
    u.tag('M-PV-ZERO', ['NUM-C-02', 'NUM-C-03', 'MATH-C-03'],
          'הילד כותב מספר כמו שהוא שומע אותו, חלק אחרי חלק (עשרים ושלוש נכתב 203), או מוסיף ומשמיט אפסים (70 נכתב 7 או 700).',
          'לכתוב יחד על פתקים: פתק של עשרים ופתק של שלוש, ולהניח את פתק השלוש על האפס של העשרים. כך רואים שהמספר עשרים ושלוש כתוב בשתי ספרות.',
          ['concrete', 'symbolic'], 'בְּמִסְפָּר עִם עֲשָׂרוֹת וִיחִידוֹת יֵשׁ רַק שְׁתֵּי סְפָרוֹת. בּוֹאוּ נִבְדֹּק אֶת הַמָּקוֹם שֶׁל כׇּל סִפְרָה.')
    u.tag('M-SIGN-DIR', ['NUM-C-04'],
          'הילד קורא את הסימנים "גדול מ" ו"קטן מ" הפוך, או בוחר את הסימן לפי המקום של המספר הגדול ולא לפי הצד הפתוח של הסימן.',
          'לצייר תנין רעב שהפה שלו פתוח תמיד אל הערמה הגדולה יותר של עוגיות, ואז להפוך את התנין לסימן.',
          ['pictorial', 'concrete'], 'הַצַּד הַפָּתוּחַ שֶׁל הַסִּימָן פּוֹנֶה תָּמִיד אֶל הַמִּסְפָּר הַגָּדוֹל. בּוֹאוּ נִבְדֹּק.')
    u.tag('M-HC-ROW', ['NUM-C-09'],
          'הילד חושב שעשר יותר בלוח המאה הוא המשבצת הבאה בשורה, ולכן 34 ועוד עשר נראה לו 35.',
          'להדפיס לוח מאה ולהניח עליו מקל באורך עשר משבצות: כל פעם שמוסיפים עשר, יורדים שורה אחת באותו טור.',
          ['pictorial', 'concrete'], 'עֶשֶׂר יוֹתֵר זוֹ שׁוּרָה לְמַטָּה, בְּאוֹתוֹ טוּר. בּוֹאוּ נִרְאֶה.')
    u.tag('M-OP-SWAP', ['NUM-C-09', 'MATH-C-01', 'MATH-C-02', 'MATH-C-03'],
          'הילד עושה את הפעולה ההפוכה: מחבר כשצריך לחסר, או מחסר כשצריך לחבר.',
          'לספר סיפור קטן לכל תרגיל עם חפצים אמיתיים: יש שבע כפיות, לוקחים שלוש. ואז לשאול: נשארו לנו יותר כפיות או פחות?',
          ['concrete', 'story'], 'רֶגַע, מוֹסִיפִים כָּאן אוֹ מוֹרִידִים? בּוֹאוּ נִסְתַּכֵּל שׁוּב עַל הַסִּימָן.')

    # ---- NUM-B-06 (bridge, core): reads the numerals 0 to 10
    u.skill('NUM-B-06', 'קוראים 0–10', 'קוֹרְאִים מִסְפָּרִים עַד עֶשֶׂר', 'pool', ['NUM-A-08'], ['symbolic', 'pictorial'], ['M-NUM-REV'],
            core=True)
    bridge(u)
    # Two numerals that look alike to a young reader (turned or mirrored: 6 and 9, 2 and 5, 1 and 7, 3 and 8) are the
    # distractors, both M-NUM-REV, the one tag the skill watches (the E1 rule of B-15).
    for i, (n, look) in enumerate([(6, (9, 0)), (2, (5, 7)), (9, (6, 4)), (1, (7, 4)), (3, (8, 5)), (5, (2, 3))]):
        choose(u, 'NUM-B-06', 'אֵיפֹה הַמִּסְפָּר %s?' % F[n], n, {v: 'M-NUM-REV' for v in look}, i, band='B',
               h2='הַמִּסְפָּרִים הָאֵלֶּה דּוֹמִים. נִסְתַּכֵּל עַל כׇּל אֶחָד לְאַט, וְנַעֲבֹר עִם הָאֶצְבַּע עַל הַצּוּרָה שֶׁלּוֹ.',
               h3='הִנֵּה הַמִּסְפָּר %s. %s' % (F[n], NOW % F[n]), ok='כֵּן! זֶה %s.' % F[n])
    for i, (n, look, where) in enumerate([(8, (3, 0), 'הַבַּיִת'), (7, (1, 4), 'הָאוֹטוֹבּוּס')]):
        choose(u, 'NUM-B-06', 'עַל %s כָּתוּב מִסְפָּר %s. אֵיפֹה הַמִּסְפָּר?' % (where, F[n]), n, {v: 'M-NUM-REV' for v in look}, i,
               band='B', check='transfer', difficulty=0.5,
               h2='הַמִּסְפָּרִים הָאֵלֶּה דּוֹמִים. נִסְתַּכֵּל עַל כׇּל אֶחָד לְאַט, וְנַעֲבֹר עִם הָאֶצְבַּע עַל הַצּוּרָה שֶׁלּוֹ.',
               h3='הִנֵּה הַמִּסְפָּר %s. %s' % (F[n], NOW % F[n]), ok='כֵּן! זֶה %s.' % F[n])
    # The numeral is shown, never said: the child reads it and finds the set (reverse of "how many?")
    for i, (n, obj) in enumerate([(4, 'apple'), (7, 'star'), (9, 'fish'), (6, 'duck'), (10, 'ladybug'), (3, 'bird')]):
        sets = placed('%s*%d' % (obj, n), ['%s*%d' % (obj, n - 1), '%s*%d' % (obj, n + 1) if n < 10 else '%s*%d' % (obj, n - 2)], i)
        tags = {'%s*%d' % (obj, n - 1): 'M-CNT-SKIP', '%s*%d' % (obj, n + 1): 'M-CNT-DOUBLE', '%s*%d' % (obj, n - 2): 'M-CNT-SKIP'}
        u.act('NUM-B-06', 'pick', band='B', check='reverse', numeral=n, prompt='קִרְאוּ אֶת הַמִּסְפָּר. אֵיזוֹ קְבוּצָה מַתְאִימָה לַמִּסְפָּר?',
              options=sets, correct='%s*%d' % (obj, n), tags={s: tags[s] for s in sets if s in tags},
              h2='קֹדֶם קוֹרְאִים אֶת הַמִּסְפָּר, וְאַחַר כָּךְ סוֹפְרִים כׇּל קְבוּצָה עַד הַסּוֹף.',
              h3='הַמִּסְפָּר הוּא %s. סוֹפְרִים: %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַקְּבוּצָה הַזֹּאת.' % (
                  F[n], ', '.join(F[k] for k in range(1, n + 1))),
              correct_text='כֵּן! %s.' % F[n])

    # ---- NUM-B-09 (bridge, core): quantities to 10 on a ten-frame, at a glance
    u.skill('NUM-B-09', 'רואים כמויות במסגרת של עשר', 'רוֹאִים כַּמָּה בַּמִּסְגֶּרֶת', 'pool', ['NUM-A-10'], ['pictorial', 'symbolic'],
            ['M-CNT-SKIP', 'M-CNT-DOUBLE'], core=True)
    bridge(u)
    for i, (obj, n) in enumerate([('apple', 8), ('star', 6), ('fish', 7), ('duck', 9), ('ladybug', 5), ('bird', 4)]):
        u.act('NUM-B-09', 'flash', band='B', voice=False, obj=obj, count=n, arrangement='ten_frame', flashMs=2000, seed=60 + i,
              options=placed(n, [n - 1, n + 1], i))
    for i, (obj, n) in enumerate([('butterfly', 8), ('cat', 7)]):  # the transfer: other objects in the same frame
        u.act('NUM-B-09', 'flash', band='B', voice=False, obj=obj, count=n, arrangement='ten_frame', flashMs=2000, seed=70 + i,
              options=placed(n, [n - 1, n + 1], i), check='transfer', difficulty=0.5)
    for i, (obj, n) in enumerate([('apple', 7), ('star', 6), ('fish', 8)]):  # how many empty cells to ten (reverse)
        choose(u, 'NUM-B-09', 'כַּמָּה חֲסֵרִים כְּדֵי שֶׁיִּהְיוּ עֶשֶׂר?', 10 - n, {9 - n: 'M-CNT-SKIP', 11 - n: 'M-CNT-DOUBLE'}, i,
               band='B', check='reverse', group={'sprite': obj, 'count': n, 'arrangement': 'ten_frame'},
               h2='בַּמִּסְגֶּרֶת יֵשׁ עֶשֶׂר מִשְׁבָּצוֹת. נִסְפֹּר רַק אֶת הַמִּשְׁבָּצוֹת הָרֵיקוֹת.',
               h3='%s… %s. הוֹסַפְנוּ %s. %s' % (F[n], ', '.join(F[k] for k in range(n + 1, 11)), F[10 - n], NOW % F[10 - n]),
               ok='%s! %s וְעוֹד %s הֵם עֶשֶׂר.' % (F[10 - n], F[n], F[10 - n]))
    for i, n in enumerate([7, 4, 9]):  # the same make-ten, in a number sentence
        choose(u, 'NUM-B-09', 'אֵיזֶה מִסְפָּר חָסֵר?', 10 - n, {10 + n: 'M-EQ-OPER', 11 - n: 'M-CNT-DOUBLE'}, i, band='B',
               row=[n, '+', '?', '=', 10],
               h2='חִשְׁבוּ עַל מִסְגֶּרֶת שֶׁל עֶשֶׂר עִם %s בִּפְנִים. כַּמָּה מִשְׁבָּצוֹת רֵיקוֹת?' % F[n],
               h3='%s וְעוֹד %s שָׁוֶה עֶשֶׂר. %s' % (F[n], F[10 - n], NOW % F[10 - n]),
               ok='%s! %s וְעוֹד %s שָׁוֶה עֶשֶׂר.' % (F[10 - n], F[n], F[10 - n]))

    # ---- NUM-C-01: counts to 100 from any number; counts on over the tens
    u.skill('NUM-C-01', 'סופרים עד 100 מכל מספר', 'סוֹפְרִים עַד מֵאָה', 'cone-tree', ['NUM-B-02', 'NUM-B-17'], ['symbolic', 'pictorial'],
            ['M-CNT-DECADE', 'M-CNT-SEQ'])
    for i, n in enumerate([39, 69, 49, 79, 99]):
        wrong = {n - 9: 'M-CNT-DECADE', (n + 2 if n < 99 else n - 1): 'M-CNT-SEQ'}
        choose(u, 'NUM-C-01', 'מַה בָּא אַחֲרֵי %s?' % F[n], n + 1, wrong, i,
               h2='בְּסוֹף כׇּל עֲשָׂרָה מַגִּיעָה עֲשָׂרָה חֲדָשָׁה. נִסְפֹּר לְאַט: %s, %s, %s…' % (F[n - 2], F[n - 1], F[n]),
               h3='%s, וְאַחֲרָיו %s. %s' % (F[n], F[n + 1], NOW % F[n + 1]), ok='%s! אַחֲרֵי %s בָּא %s.' % (F[n + 1], F[n], F[n + 1]))
    for i, n in enumerate([40, 70]):
        choose(u, 'NUM-C-01', 'מַה בָּא לִפְנֵי %s?' % F[n], n - 1, {n + 9: 'M-CNT-DECADE', n + 1: 'M-CNT-SEQ'}, i, check='reverse',
               h2='נִסְפֹּר לְאַט וְנַעֲצֹר לִפְנֵי %s: %s, %s…' % (F[n], F[n - 3], F[n - 2]),
               h3='%s, וְאַחֲרָיו %s. %s' % (F[n - 1], F[n], NOW % F[n - 1]), ok='%s! לִפְנֵי %s בָּא %s.' % (F[n - 1], F[n], F[n - 1]))
    for i, (seq, gap) in enumerate([((28, 29, 30, 31), 2), ((57, 58, 59, 60), 3), ((88, 89, 90, 91), 2)]):
        ans = seq[gap]
        cells = ['?' if k == gap else v for k, v in enumerate(seq)]
        choose(u, 'NUM-C-01', 'אֵיזֶה מִסְפָּר חָסֵר?', ans, {ans - 10: 'M-CNT-DECADE', ans + 2: 'M-CNT-SEQ'}, i, row=cells,
               h2='סוֹפְרִים מֵהַמִּסְפָּר הָרִאשׁוֹן, צַעַד אַחַר צַעַד, וְעוֹצְרִים בַּמָּקוֹם הָרֵיק.',
               h3='%s. %s' % (', '.join(F[v] for v in seq), NOW % F[ans]), ok='%s! %s.' % (F[ans], ', '.join(F[v] for v in seq)))
    jump(u, 'NUM-C-01', 30, 50, 38, 3)
    jump(u, 'NUM-C-01', 60, 80, 67, 4)

    # ---- NUM-C-02: reads and says numbers to 100 (the number is heard; the tiles are numerals)
    u.skill('NUM-C-02', 'קוראים מספרים עד 100', 'קוֹרְאִים מִסְפָּרִים עַד מֵאָה', 'pool', ['NUM-C-01', 'NUM-B-16'], ['symbolic'],
            ['M-NUM-REV', 'M-PV-ZERO'])
    heard = lambda n: int('%d%d' % (n - n % 10, n % 10))  # 23 written as it is heard: 20, then 3 = 203
    READ_H2 = 'שׁוֹמְעִים קֹדֶם אֶת הָעֲשָׂרוֹת וְאַחַר כָּךְ אֶת הַיְּחִידוֹת. כּוֹתְבִים רַק שְׁתֵּי סְפָרוֹת: סִפְרַת הָעֲשָׂרוֹת מִשְּׂמֹאל.'
    for i, n in enumerate([23, 47, 35, 68, 52, 81, 94, 76]):
        wrong = {int(str(n)[::-1]): 'M-NUM-REV', heard(n): 'M-PV-ZERO'}
        choose(u, 'NUM-C-02', 'אֵיפֹה הַמִּסְפָּר %s?' % F[n], n, wrong, i,
               h2=READ_H2, h3='%s: %s, %s. %s' % (F[n], tens_words(n // 10), vav(ones_words(n % 10)), NOW % F[n]),
               ok='כֵּן! זֶה %s.' % F[n])
    for i, (n, where) in enumerate([(46, 'הַבַּיִת'), (39, 'הָאוֹטוֹבּוּס'), (58, 'הַשַּׂחְקָן'), (62, 'הַדֶּלֶת')]):
        wrong = {int(str(n)[::-1]): 'M-NUM-REV', heard(n): 'M-PV-ZERO'}
        choose(u, 'NUM-C-02', 'הַמִּסְפָּר שֶׁל %s הוּא %s. אֵיפֹה הַמִּסְפָּר?' % (where, F[n]), n, wrong, i, check='transfer', difficulty=0.6,
               h2=READ_H2, h3='%s: %s, %s. %s' % (F[n], tens_words(n // 10), vav(ones_words(n % 10)), NOW % F[n]),
               ok='כֵּן! זֶה %s.' % F[n])

    # ---- NUM-C-03 (core): tens and ones; zero holds a place
    u.skill('NUM-C-03', 'עשרות ויחידות', 'עֲשָׂרוֹת וִיחִידוֹת', 'pool', ['NUM-C-02'], ['symbolic', 'pictorial'],
            ['M-PV-FACE', 'M-PV-ZERO', 'M-NUM-REV'], core=True)
    for i, (t, o) in enumerate([(3, 4), (6, 7), (4, 9), (8, 2)]):  # compose: 30 + 4 = ?
        n = 10 * t + o
        choose(u, 'NUM-C-03', 'כַּמָּה זֶה?', n, {heard(n): 'M-PV-ZERO', int(str(n)[::-1]): 'M-NUM-REV'}, i, row=[10 * t, '+', o, '=', '?'],
               h2='%s הֵן %s, %s. סִפְרַת הָעֲשָׂרוֹת כְּתוּבָה מִשְּׂמֹאל, וְהַיְּחִידוֹת אַחֲרֶיהָ.' % (
                   tens_words(t), F[10 * t], vav(ones_words(o))),
               h3='%s וְעוֹד %s שָׁוֶה %s. %s' % (F[10 * t], F[o], F[n], NOW % F[n]), ok='%s! %s וְעוֹד %s שָׁוֶה %s.' % (F[n], F[10 * t], F[o], F[n]))
    for i, (n, gap) in enumerate([(34, 'tens'), (58, 'tens'), (46, 'ones'), (93, 'tens')]):  # decompose: 34 = ? + 4 (reverse)
        t, o = n - n % 10, n % 10
        if gap == 'tens':
            ans, row, wrong = t, [n, '=', '?', '+', o], {t // 10: 'M-PV-FACE', n + o: 'M-EQ-OPER'}
        else:
            ans, row, wrong = o, [n, '=', t, '+', '?'], {n + t: 'M-EQ-OPER', 10 * o: 'M-PV-ZERO'}
        choose(u, 'NUM-C-03', 'אֵיזֶה מִסְפָּר חָסֵר?', ans, wrong, i, row=row, check='reverse',
               h2='מְפָרְקִים אֶת %s: כַּמָּה עֲשָׂרוֹת יֵשׁ בּוֹ, וְכַמָּה יְחִידוֹת?' % F[n],
               h3='%s יֵשׁ %s %s: %s שָׁוֶה %s וְעוֹד %s. %s' % (prefix('ב', F[n]), tens_words(t // 10), vav(ones_words(o)), F[n], F[t],
                                                                 F[o], NOW % F[ans]),
               ok='%s! %s שָׁוֶה %s וְעוֹד %s.' % (F[ans], F[n], F[t], F[o]))
    for i, (t, o) in enumerate([(3, 4), (5, 2), (2, 6), (4, 0)]):  # ten-shekel and one-shekel coins (transfer)
        n = 10 * t + o
        wrong = {t + o: 'M-MONEY-COUNT', (int(str(n)[::-1]) if o else 10 * n): ('M-NUM-REV' if o else 'M-PV-ZERO')}
        if o:
            wrong[heard(n)] = 'M-PV-ZERO'
        tens_count = ', '.join(F[10 * k] for k in range(1, t + 1))
        ones_count = ', '.join(F[10 * t + k] for k in range(1, o + 1))
        choose(u, 'NUM-C-03', 'כַּמָּה שְׁקָלִים יֵשׁ כָּאן?', n, wrong, i, check='transfer', difficulty=0.6,
               group={'sprite': 'coin_s10', 'count': t}, **({'group2': {'sprite': 'coin_s1', 'count': o}} if o else {}),
               h2='כׇּל מַטְבֵּעַ גָּדוֹל שָׁוֶה עֲשָׂרָה שְׁקָלִים, וְכׇל מַטְבֵּעַ קָטָן שֶׁקֶל אֶחָד. סוֹפְרִים קֹדֶם בַּעֲשָׂרוֹת.',
               h3=('%s, וּמַמְשִׁיכִים: %s. %s' % (tens_count, ones_count, NOW % F[n])) if o else '%s. %s' % (tens_count, NOW % F[n]),
               ok='%s! יֵשׁ כָּאן %s.' % (F[n], qty(n, SHEKEL)))
    for i, (t, o, ones_first) in enumerate([(3, 4, False), (6, 8, False), (2, 7, True), (8, 1, False)]):  # said in words
        n = 10 * t + o
        said = ('%s %s' % (ones_words(o), vav(tens_words(t)))) if ones_first else '%s %s' % (tens_words(t), vav(ones_words(o)))
        choose(u, 'NUM-C-03', '%s. אֵיזֶה מִסְפָּר זֶה?' % said, n, {int(str(n)[::-1]): 'M-NUM-REV', heard(n): 'M-PV-ZERO'}, i,
               h2='אֶת הָעֲשָׂרוֹת כּוֹתְבִים קֹדֶם, מִשְּׂמֹאל, וְאֶת הַיְּחִידוֹת אַחֲרֵיהֶן — גַּם אִם שׁוֹמְעִים אוֹתָן קֹדֶם.',
               h3='%s הֵן %s, וְעוֹד %s: %s. %s' % (tens_words(t), F[10 * t], F[o], F[n], NOW % F[n]), ok='כֵּן! %s.' % F[n])

    # ---- NUM-C-04: compares and orders numbers to 100, with < and >
    u.skill('NUM-C-04', 'משווים מספרים עד 100', 'מַשְׁוִים מִסְפָּרִים עַד מֵאָה', 'pool', ['NUM-C-03', 'NUM-B-10'], ['symbolic'],
            ['M-PV-FACE', 'M-SIGN-DIR'])
    for i, (vals, ask) in enumerate([((41, 39, 14), 'big'), ((62, 59, 26), 'big'), ((73, 68, 37), 'big'), ((85, 79, 58), 'big'),
                                     ((38, 41, 83), 'small'), ((56, 61, 65), 'small')]):
        right = vals[0]
        face, rev = vals[1], vals[2]
        word = 'גָּדוֹל' if ask == 'big' else 'קָטָן'
        most = 'הֲכִי הַרְבֵּה' if ask == 'big' else 'הֲכִי מְעַט'
        choose(u, 'NUM-C-04', 'אֵיזֶה מִסְפָּר %s יוֹתֵר?' % word, right, {face: 'M-PV-FACE', rev: 'M-NUM-REV'}, i,
               **({'check': 'reverse'} if ask == 'small' else {}),
               h2='מַשְׁוִים קֹדֶם אֶת הָעֲשָׂרוֹת: כַּמָּה עֲשָׂרוֹת יֵשׁ בְּכׇל מִסְפָּר? אֶת הַיְּחִידוֹת מַשְׁוִים רַק אִם הָעֲשָׂרוֹת שָׁווֹת.',
               h3='%s יֵשׁ %s — %s עֲשָׂרוֹת. %s' % (prefix('ב', F[right]), tens_words(right // 10), most, NOW % F[right]),
               ok='כֵּן! %s %s יוֹתֵר.' % (F[right], word))
    # A gap in a sentence with < or >: the right number, one a child who compares the ones first would pick (M-PV-FACE), and one
    # that fits the sign read the other way round (M-SIGN-DIR). The first is the lucky-right item: 58 > 43 by the ones too.
    for i, (row, ans, face, sign) in enumerate([([58, '>', '?'], 43, 61, 79), (['?', '<', 47], 39, 52, 68), ([26, '<', '?'], 31, 19, 21),
                                                (['?', '>', 64], 72, 59, 53), ([45, '>', '?'], 38, 51, 57), ([83, '>', '?'], 79, 91, 86)]):
        other = row[0] if row[0] != '?' else row[2]
        big = max(other, ans)
        left, right = (row[0], ans) if row[0] != '?' else (ans, row[2])
        choose(u, 'NUM-C-04', 'אֵיזֶה מִסְפָּר מַתְאִים לַמָּקוֹם הָרֵיק?', ans, {face: 'M-PV-FACE', sign: 'M-SIGN-DIR'}, i, row=row,
               h2='הַצַּד הַפָּתוּחַ שֶׁל הַסִּימָן פּוֹנֶה אֶל הַמִּסְפָּר הַגָּדוֹל יוֹתֵר. מַשְׁוִים קֹדֶם אֶת הָעֲשָׂרוֹת.',
               h3='%s יֵשׁ %s, %s יֵשׁ %s. הַצַּד הַפָּתוּחַ פּוֹנֶה אֶל %s. %s' % (
                   prefix('ב', F[other]), tens_words(other // 10), vav(prefix('ב', F[ans])), tens_words(ans // 10), F[big], NOW % F[ans]),
               ok='כֵּן! %s %s %s. הַצַּד הַפָּתוּחַ פּוֹנֶה אֶל הַגָּדוֹל.' % (
                   F[left], 'גָּדוֹל' if row[1] == '>' else 'קָטָן', from_(F[right])))

    # ---- NUM-C-06: places numbers on the line between the tens (a window of twenty; the 0 to 100 line waits for X5)
    u.skill('NUM-C-06', 'מספרים על ציר עד 100', 'שָׂמִים מִסְפָּרִים עַל הַצִּיר', 'dock', ['NUM-C-03', 'NUM-B-13'], ['pictorial'],
            ['M-NL-DIR', 'M-NL-SPACE'])
    for frm, target in [(40, 47), (20, 33), (60, 72), (80, 91), (30, 44), (70, 78)]:
        place_on(u, 'NUM-C-06', frm, frm + 20, target, [frm, frm + 10, frm + 20])
    for frm, target in [(50, 64), (10, 26)]:  # only the two ends are marked (transfer)
        place_on(u, 'NUM-C-06', frm, frm + 20, target, [frm, frm + 20], check='transfer', difficulty=0.6)
    jump(u, 'NUM-C-06', 40, 60, 48, 5, labels=[40, 50, 60])
    jump(u, 'NUM-C-06', 60, 80, 71, -4, labels=[60, 70, 80])
    jump(u, 'NUM-C-06', 30, 50, 35, 6, labels=[30, 40, 50])
    jump(u, 'NUM-C-06', 80, 100, 92, -3, labels=[80, 90, 100])

    # ---- NUM-C-09: ten more and ten less (the hundred chart: one row down or up, the same column)
    u.skill('NUM-C-09', 'עשר יותר, עשר פחות', 'עֶשֶׂר יוֹתֵר וְעֶשֶׂר פָּחוֹת', 'cone-tree', ['NUM-C-03'], ['symbolic', 'pictorial'],
            ['M-HC-ROW', 'M-OP-SWAP'])
    for i, (n, d) in enumerate([(34, 10), (57, 10), (61, -10), (83, -10), (48, 10)]):
        ans = n + d
        way = 'לְמַטָּה' if d > 0 else 'לְמַעְלָה'
        choose(u, 'NUM-C-09', 'כַּמָּה זֶה?', ans, {n + (1 if d > 0 else -1): 'M-HC-ROW', n - d: 'M-OP-SWAP'}, i,
               row=[n, '+' if d > 0 else '-', 10, '=', '?'],
               h2='בְּלוּחַ הַמֵּאָה, עֶשֶׂר %s זוֹ שׁוּרָה %s בְּאוֹתוֹ טוּר. הַיְּחִידוֹת לֹא מִשְׁתַּנּוֹת, רַק הָעֲשָׂרוֹת.' % (
                   'יוֹתֵר' if d > 0 else 'פָּחוֹת', way),
               h3='%s %s שׁוּרָה %s: %s. %s' % (from_(F[n]), 'יוֹרְדִים' if d > 0 else 'עוֹלִים', way, F[ans], NOW % F[ans]),
               ok='%s! %s %s עֶשֶׂר שָׁוֶה %s.' % (F[ans], F[n], 'וְעוֹד' if d > 0 else 'פָּחוֹת', F[ans]))
    for i, (col, gap) in enumerate([((6, 16, 26, 36, 46), 3), ((14, 24, 34, 44, 54), 2), ((49, 59, 69, 79, 89), 4)]):
        ans = col[gap]
        choose(u, 'NUM-C-09', 'אֵלֶּה מִסְפָּרִים מֵאוֹתוֹ טוּר שֶׁל לוּחַ הַמֵּאָה. אֵיזֶה מִסְפָּר חָסֵר?', ans,
               {col[gap - 1] + 1: 'M-HC-ROW', int(str(ans)[::-1]): 'M-NUM-REV'}, i, row=['?' if k == gap else v for k, v in enumerate(col)],
               h2='בְּטוּר שֶׁל לוּחַ הַמֵּאָה כׇּל מִסְפָּר גָּדוֹל בְּעֶשֶׂר מֵהַמִּסְפָּר שֶׁמֵּעָלָיו. סִפְרַת הַיְּחִידוֹת לֹא מִשְׁתַּנָּה.',
               h3='%s. %s' % (', '.join(F[v] for v in col), NOW % F[ans]), ok='%s! עֶשֶׂר יוֹתֵר, שׁוּרָה לְמַטָּה.' % F[ans])
    for cells, w in (([5, 15, 25, 36, 45], 3), ([73, 63, 52, 43, 33], 2)):
        right = cells[w - 1] + (cells[1] - cells[0])
        u.act('NUM-C-09', 'spot', cells=['n:%d' % v for v in cells], wrong=w, tag='M-HC-ROW', check='error_spotting', difficulty=0.6,
              prompt='חָבֵר כָּתַב מִסְפָּרִים מֵאוֹתוֹ טוּר שֶׁל לוּחַ הַמֵּאָה, וְיֵשׁ בָּהֶם טָעוּת. אֵיפֹה הַטָּעוּת?',
              h3='מִשּׁוּרָה לְשׁוּרָה הַמִּסְפָּר גָּדֵל אוֹ קָטָן בְּעֶשֶׂר, וְסִפְרַת הַיְּחִידוֹת נִשְׁאֶרֶת כְּמוֹ שֶׁהִיא. אֶחָד מֵהַמִּסְפָּרִים לֹא מַתְאִים. עַכְשָׁו תּוֹרְכֶם.',
              correct_text='כֵּן! כָּאן הָיָה צָרִיךְ לִהְיוֹת %s.' % F[right])
    jump(u, 'NUM-C-09', 20, 40, 23, 10, labels=[20, 30, 40])
    jump(u, 'NUM-C-09', 30, 50, 47, -10, labels=[30, 40, 50])

    # ---- NUM-B-01 and NUM-B-10 become core with C1 (three dependants: MATH-B-04, and NUM-C-04): each gets a second representation
    # and a second kind of check, so fresh mastery stays reachable (graph.isCore; mastery_reachable_test)
    jump(u, 'NUM-B-01', 0, 20, 12, 3, labels=[0, 10, 20], band='B')
    jump(u, 'NUM-B-01', 0, 20, 16, 4, labels=[0, 10, 20], band='B')
    for i, (big, small, obj) in enumerate([(7, 4, 'apple'), (9, 6, 'fish')]):  # the smaller number drawn with bigger objects
        choose(u, 'NUM-B-10', 'אֵיזֶה מִסְפָּר גָּדוֹל יוֹתֵר?', big, {small: 'M-CNT-SIZE'}, i, band='B', check='transfer', difficulty=0.5,
               group={'sprite': obj, 'count': big, 'scale': 0.6}, group2={'sprite': obj, 'count': small, 'scale': 1.5},
               h2='הַגֹּדֶל שֶׁל הַצִּיּוּרִים לֹא מְשַׁנֶּה. סוֹפְרִים כׇּל קְבוּצָה, אֶחָד אֶחָד.',
               h3='%s בָּא אַחֲרֵי %s בַּסְּפִירָה, אָז %s גָּדוֹל יוֹתֵר. %s' % (F[big], F[small], F[big], NOW % F[big]),
               ok='כֵּן! %s גָּדוֹל יוֹתֵר.' % F[big])

    # ---- lessons: the bridge first, then C1 in the order of the skills (the path gate holds each until its skills unlock)
    lesson_of(u, 'read-numerals', 'קוֹרְאִים מִסְפָּרִים', 'NUM-B-06', 'כׇּל הַכָּבוֹד! קְרָאתֶם אֶת הַמִּסְפָּרִים.', 0, 7, band='B')
    lesson_of(u, 'read-numerals-more', 'עוֹד מִסְפָּרִים לִקְרֹא', 'NUM-B-06', 'מְצֻיָּן! הַמִּסְפָּרִים כְּבָר מוּכָּרִים.', 7, band='B')
    lesson_of(u, 'ten-frame-glance', 'מִסְגֶּרֶת שֶׁל עֶשֶׂר', 'NUM-B-09', 'יָפֶה מְאֹד! רְאִיתֶם בְּלִי לִסְפֹּר.', 0, 7, band='B')
    lesson_of(u, 'ten-frame-more', 'עוֹד מִסְגָּרוֹת', 'NUM-B-09', 'כׇּל הַכָּבוֹד! הַמִּסְגֶּרֶת מְלֵאָה.', 7, band='B')
    u.lesson('count-and-compare-again', 'סוֹפְרִים וּמַשְׁוִים שׁוּב', ['NUM-B-01', 'NUM-B-10'],
             [x['id'] for x in u.d['activities'] if x['skill'] in ('NUM-B-01', 'NUM-B-10')], 'יָפֶה מְאֹד! סְפַרְתֶּם וְהִשְׁוִיתֶם.', minutes=3)
    u.d['lessons'][-1]['band'] = 'B'
    lesson_of(u, 'count-to-100', 'סוֹפְרִים עַד מֵאָה', 'NUM-C-01', 'כׇּל הַכָּבוֹד! עֲבַרְתֶּם אֶת הָעֲשָׂרוֹת.', minutes=8)
    lesson_of(u, 'read-to-100', 'קוֹרְאִים מִסְפָּרִים גְּדוֹלִים', 'NUM-C-02', 'מְצֻיָּן! כׇּל סִפְרָה בִּמְקוֹמָהּ.', minutes=8)
    lesson_of(u, 'tens-and-ones', 'עֲשָׂרוֹת וִיחִידוֹת', 'NUM-C-03', 'כׇּל הַכָּבוֹד! פֵּרַקְתֶּם לַעֲשָׂרוֹת וְלִיחִידוֹת.', 0, 8, minutes=7)
    lesson_of(u, 'tens-and-ones-more', 'עוֹד עֲשָׂרוֹת וִיחִידוֹת', 'NUM-C-03', 'נִפְלָא! הָעֲשָׂרוֹת וְהַיְּחִידוֹת מוּכָּרוֹת.', 8, minutes=7)
    lesson_of(u, 'compare-to-100', 'מַשְׁוִים מִסְפָּרִים', 'NUM-C-04', 'יָפֶה מְאֹד! הַסִּימָן פּוֹנֶה לַגָּדוֹל.', minutes=8)
    lesson_of(u, 'line-to-100', 'הַצִּיר הַגָּדוֹל', 'NUM-C-06', 'כׇּל הַכָּבוֹד! הַצְּפַרְדֵּעַ בַּמָּקוֹם הַנָּכוֹן.', minutes=8)
    lesson_of(u, 'ten-more-ten-less', 'עֶשֶׂר יוֹתֵר, עֶשֶׂר פָּחוֹת', 'NUM-C-09', 'מְצֻיָּן! שׁוּרָה לְמַטָּה, שׁוּרָה לְמַעְלָה.', minutes=8)


# The fact families of MATH-C-01 (a ≥ b, a + b > 10: every one crosses ten). Each is one variantGroup: with setCoverage, fresh mastery
# needs every family answered right once (M10 §7.3 E1).
FAMILIES = [(9, 3), (9, 5), (9, 7), (8, 4), (8, 6), (8, 7), (7, 5), (7, 6), (6, 5), (6, 6), (8, 8), (9, 9)]
START_LINE = {'M-CNT-DOUBLE': ('vo:fb.count_on_start', 'כְּשֶׁמַּמְשִׁיכִים לִסְפֹּר, לֹא סוֹפְרִים שׁוּב אֶת הַמִּסְפָּר שֶׁמַּתְחִילִים מִמֶּנּוּ. בּוֹאוּ נִבְדֹּק.')}


@table('C1', 'math', assets=['frog', 'block', 'coin_s10', 'apple', 'star', 'fish', 'duck', 'ladybug', 'bird'],
       note='Band C, batch C1, Market: the facts to 9 + 9 (MATH-C-01), fact families (MATH-C-02), whole tens (MATH-C-03) and the bridge '
            'skill MATH-B-04 (count on from the larger number, §8 P8). Hebrew is a draft, needs-editor.')
def math_c1(u):
    u.tag('M-SUB-SMALLBIG', ['MATH-C-01'],
          'הילד מחסר בכל טור את הספרה הקטנה מהגדולה, בלי לשים לב מי למעלה: 15 פחות 7 נראה לו 12, כי 7 פחות 5 הם 2.',
          'לסדר 15 כפיות בערמה של עשר ועוד חמש לבד, ולהוריד שבע. כך רואים שצריך לפתוח את הערמה של העשר.',
          ['concrete', 'pictorial'], 'רֶגַע, מוֹרִידִים מֵהַמִּסְפָּר הַגָּדוֹל. בּוֹאוּ נִפְתַּח אֶת הָעֶשֶׂר וְנִרְאֶה.')

    # ---- MATH-B-04 (bridge): counts on from the larger number
    u.skill('MATH-B-04', 'ממשיכים לספור מהמספר הגדול', 'מַמְשִׁיכִים מֵהַמִּסְפָּר הַגָּדוֹל', 'stall', ['MATH-B-01', 'NUM-B-01'],
            ['symbolic', 'pictorial'], ['M-ADD-RECOUNT'])
    bridge(u)
    for i, (a, b) in enumerate([(2, 7), (3, 8), (2, 8), (2, 9), (3, 6), (4, 9)]):
        s = a + b
        choose(u, 'MATH-B-04', 'כַּמָּה זֶה?', s, {s - 1: 'M-CNT-DOUBLE', b: 'M-CNT-CARD', s + 1: 'M-CNT-DOUBLE'}, i, band='B',
               row=[a, '+', b, '=', '?'], tag_lines=START_LINE,
               h2='לֹא צָרִיךְ לִסְפֹּר הַכֹּל. מַתְחִילִים מֵהַמִּסְפָּר הַגָּדוֹל, %s, וּמוֹסִיפִים עוֹד %s עַל הָאֶצְבָּעוֹת.' % (F[b], F[a]),
               h2_action='show_fingers',
               h3='%s… %s. %s' % (F[b], ', '.join(F[k] for k in range(b + 1, s + 1)), NOW % F[s]),
               ok='%s! %s וְעוֹד %s שָׁוֶה %s.' % (F[s], F[a], F[b], F[s]))
    for start, hop in [(7, 2), (8, 3), (9, 4), (6, 3)]:
        jump(u, 'MATH-B-04', 0, 20, start, hop, labels=[0, 10, 20], band='B')

    # ---- MATH-C-01 (core): the facts to 9 + 9, with fact coverage (E1)
    u.skill('MATH-C-01', 'עובדות חיבור וחיסור עד 9 ועוד 9', 'חִבּוּר וְחִסּוּר עַד שְׁמוֹנֶה עֶשְׂרֵה', 'stall', ['MATH-B-08'],
            ['symbolic', 'pictorial'], ['M-CNT-DOUBLE', 'M-CNT-CARD', 'M-OP-SWAP', 'M-SUB-SMALLBIG', 'M-EQ-OPER'], core=True)
    u.d['skills'][-1]['setCoverage'] = True
    sprites = ['apple', 'star', 'fish', 'duck', 'ladybug', 'bird']
    for i, (a, b) in enumerate(FAMILIES):
        s, group = a + b, 'fact-%d-%d' % (a, b)
        frames = {}
        if i % 2 == 0:  # half of the sums are drawn as two ten-frames (the make-ten picture)
            frames = {'group': {'sprite': sprites[i % 6], 'count': a, 'arrangement': 'ten_frame'},
                      'group2': {'sprite': sprites[i % 6], 'count': b, 'arrangement': 'ten_frame'}}
        choose(u, 'MATH-C-01', 'כַּמָּה זֶה?', s, {s - 1: 'M-CNT-DOUBLE', a: 'M-CNT-CARD', a - b: 'M-OP-SWAP'}, i,
               row=[a, '+', b, '=', '?'], variantGroup=group, tag_lines=START_LINE, **frames,
               h2='מַשְׁלִימִים לְעֶשֶׂר: %s וְעוֹד %s הֵם עֶשֶׂר, וְנִשְׁאֲרוּ עוֹד %s.' % (F[a], F[10 - a], F[b - (10 - a)]),
               h3='עֶשֶׂר וְעוֹד %s הֵם %s. %s' % (F[s - 10], F[s], NOW % F[s]), ok='%s! %s וְעוֹד %s שָׁוֶה %s.' % (F[s], F[a], F[b], F[s]))
        if i % 2 == 0:  # the missing addend (reverse)
            choose(u, 'MATH-C-01', 'אֵיזֶה מִסְפָּר חָסֵר?', b, {a + s: 'M-EQ-OPER', s: 'M-EQ-OPER', b + 1: 'M-CNT-DOUBLE'}, i,
                   row=[a, '+', '?', '=', s], variantGroup=group, check='reverse', tag_lines=START_LINE,
                   h2='%s לְעֶשֶׂר חֲסֵרִים %s, וּמֵעֶשֶׂר %s עוֹד %s.' % (from_(F[a]), F[10 - a], prefix('ל', F[s]), F[s - 10]),
                   h3='%s וְעוֹד %s שָׁוֶה %s. %s' % (F[a], F[b], F[s], NOW % F[b]), ok='%s! %s וְעוֹד %s שָׁוֶה %s.' % (F[b], F[a], F[b], F[s]))
        else:  # the take-away fact of the same family
            choose(u, 'MATH-C-01', 'כַּמָּה זֶה?', a, {s + b: 'M-OP-SWAP', a + 1: 'M-CNT-DOUBLE', smallbig(s, b): 'M-SUB-SMALLBIG'}, i,
                   row=[s, '-', b, '=', '?'], variantGroup=group,
                   h2='יוֹרְדִים קֹדֶם לְעֶשֶׂר: %s פָּחוֹת %s הֵם עֶשֶׂר, וּמוֹרִידִים עוֹד %s.' % (F[s], F[s - 10], F[10 - a]),
                   h3='עֶשֶׂר פָּחוֹת %s הֵם %s. %s' % (F[10 - a], F[a], NOW % F[a]), ok='%s! %s פָּחוֹת %s שָׁוֶה %s.' % (F[a], F[s], F[b], F[a]))
    jump(u, 'MATH-C-01', 0, 20, 8, 7, labels=[0, 10, 20])
    jump(u, 'MATH-C-01', 0, 20, 9, 6, labels=[0, 10, 20])

    # ---- MATH-C-02: the inverse relation; fact families
    u.skill('MATH-C-02', 'חיבור וחיסור הם משפחה', 'מִשְׁפְּחוֹת שֶׁל תַּרְגִּילִים', 'stall', ['MATH-C-01'], ['symbolic', 'concrete'],
            ['M-OP-SWAP', 'M-EQ-OPER'])
    for i, (s, a) in enumerate([(15, 8), (13, 9), (17, 8), (14, 6), (16, 9)]):  # s − ? = a
        b = s - a
        choose(u, 'MATH-C-02', 'אֵיזֶה מִסְפָּר חָסֵר?', b, {s + a: 'M-OP-SWAP', s: 'M-EQ-OPER'}, i, row=[s, '-', '?', '=', a], check='reverse',
               h2='חִבּוּר וְחִסּוּר הֵם מִשְׁפָּחָה: %s וְעוֹד כַּמָּה שָׁוֶה %s?' % (F[a], F[s]),
               h3='%s וְעוֹד %s שָׁוֶה %s, אָז %s פָּחוֹת %s שָׁוֶה %s. %s' % (F[a], F[b], F[s], F[s], F[b], F[a], NOW % F[b]),
               ok='%s! %s פָּחוֹת %s שָׁוֶה %s.' % (F[b], F[s], F[b], F[a]))
    for i, (b, a) in enumerate([(6, 9), (4, 8), (5, 9), (3, 8), (2, 9)]):  # ? − b = a
        s = a + b
        choose(u, 'MATH-C-02', 'אֵיזֶה מִסְפָּר חָסֵר?', s, {a - b: 'M-OP-SWAP', a: 'M-EQ-OPER'}, i, row=['?', '-', b, '=', a], check='reverse',
               h2='מַה הָיָה לִפְנֵי שֶׁהוֹרַדְנוּ? מְחַבְּרִים אֶת מַה שֶּׁנִּשְׁאַר וְאֶת מַה שֶּׁהוֹרַדְנוּ.',
               h3='%s וְעוֹד %s שָׁוֶה %s. %s' % (F[a], F[b], F[s], NOW % F[s]), ok='%s! %s פָּחוֹת %s שָׁוֶה %s.' % (F[s], F[s], F[b], F[a]))
    for (la, lb, r) in [(9, 6, 7), (8, 5, 6)]:  # the balance: 9 + 6 on the left, 7 on the right; add blocks until level (15 − 7)
        u.act('MATH-C-02', 'scale', mode='balance', left=[('block', la, 1), ('block', lb, 1)], right=[('block', r, 1)], block='block',
              result=la + lb - r, tag='M-EQ-OPER', difficulty=0.6,
              prompt='בְּצַד אֶחָד %s וְעוֹד %s, וּבַצַּד הַשֵּׁנִי %s. מוֹסִיפִים קֻבִּיּוֹת עַד שֶׁהַצְּדָדִים שָׁוִים.' % (
                  qty(la, BLOCK), F[lb], F[r]),
              h3='%s וְעוֹד %s שָׁוֶה %s. %s וְעוֹד %s שָׁוֶה %s, אָז מוֹסִיפִים %s.' % (
                  F[la], F[lb], F[la + lb], F[r], F[la + lb - r], F[la + lb], qty(la + lb - r, BLOCK)),
              correct_text='כֵּן! %s וְעוֹד %s שָׁוֶה %s וְעוֹד %s.' % (F[la], F[lb], F[r], F[la + lb - r]))

    # ---- MATH-C-03: whole tens ± (40 + 30 is like 4 + 3, in tens)
    u.skill('MATH-C-03', 'מחברים ומחסרים עשרות שלמות', 'מְחַבְּרִים עֲשָׂרוֹת', 'stall', ['MATH-C-01', 'NUM-C-03'], ['symbolic', 'pictorial'],
            ['M-PV-FACE', 'M-PV-ZERO', 'M-OP-SWAP'])
    for i, (a, op, b) in enumerate([(40, '+', 30), (20, '+', 50), (60, '+', 30), (30, '+', 30), (70, '-', 40), (90, '-', 50),
                                    (80, '-', 20), (50, '-', 30)]):
        ans = a + b if op == '+' else a - b
        swap = abs(a - b) if op == '+' else a + b  # took the smaller from the larger, or added
        choose(u, 'MATH-C-03', 'כַּמָּה זֶה?', ans, {ans // 10: 'M-PV-FACE', ans * 10: 'M-PV-ZERO', swap: 'M-OP-SWAP'}, i,
               row=[a, op, b, '=', '?'],
               h2='חוֹשְׁבִים בַּעֲשָׂרוֹת: %s %s %s — כְּמוֹ %s %s %s.' % (
                   tens_words(a // 10), 'וְעוֹד' if op == '+' else 'פָּחוֹת', tens_words(b // 10), F[a // 10],
                   'וְעוֹד' if op == '+' else 'פָּחוֹת', F[b // 10]),
               h3='%s הֵן %s. %s' % (tens_words(ans // 10), F[ans], NOW % F[ans]),
               ok='%s! %s %s %s שָׁוֶה %s.' % (F[ans], F[a], 'וְעוֹד' if op == '+' else 'פָּחוֹת', F[b], F[ans]))
    for i, (a, b) in enumerate([(4, 3), (2, 5)]):  # ten-shekel coins in two piles (transfer)
        ans = 10 * (a + b)
        choose(u, 'MATH-C-03', 'כַּמָּה שְׁקָלִים יֵשׁ בְּסַךְ הַכֹּל?', ans, {a + b: 'M-MONEY-COUNT', ans * 10: 'M-PV-ZERO'}, i,
               check='transfer', difficulty=0.6, group={'sprite': 'coin_s10', 'count': a}, group2={'sprite': 'coin_s10', 'count': b},
               h2='כׇּל מַטְבֵּעַ שָׁוֶה עֲשָׂרָה שְׁקָלִים. סוֹפְרִים אֶת הַמַּטְבְּעוֹת בַּעֲשָׂרוֹת.',
               h3='%s. %s' % (', '.join(F[10 * k] for k in range(1, a + b + 1)), NOW % F[ans]), ok='%s! יֵשׁ כָּאן %s.' % (F[ans], qty(ans, SHEKEL)))
    for i, (a, s) in enumerate([(40, 90), (30, 70)]):  # the missing tens (reverse)
        b = s - a
        choose(u, 'MATH-C-03', 'אֵיזֶה מִסְפָּר חָסֵר?', b, {b // 10: 'M-PV-FACE', a + s: 'M-EQ-OPER'}, i, row=[a, '+', '?', '=', s],
               check='reverse',
               h2='חוֹשְׁבִים בַּעֲשָׂרוֹת: %s וְעוֹד כַּמָּה עֲשָׂרוֹת הֵן %s?' % (tens_words(a // 10), tens_words(s // 10)),
               h3='%s וְעוֹד %s שָׁוֶה %s. %s' % (F[a], F[b], F[s], NOW % F[b]), ok='%s! %s וְעוֹד %s שָׁוֶה %s.' % (F[b], F[a], F[b], F[s]))

    # ---- lessons
    lesson_of(u, 'count-on-big', 'מַמְשִׁיכִים מֵהַגָּדוֹל', 'MATH-B-04', 'כׇּל הַכָּבוֹד! הִתְחַלְתֶּם מֵהַמִּסְפָּר הַגָּדוֹל.', band='B')
    lesson_of(u, 'facts-to-18', 'חִבּוּר עַד שְׁמוֹנֶה עֶשְׂרֵה', 'MATH-C-01', 'כׇּל הַכָּבוֹד! הִשְׁלַמְתֶּם לְעֶשֶׂר.', 0, 9, minutes=7)
    lesson_of(u, 'facts-to-18-more', 'עוֹד תַּרְגִּילִים', 'MATH-C-01', 'מְצֻיָּן! עֲשִׂיתֶם הַרְבֵּה תַּרְגִּילִים.', 9, 18, minutes=7)
    lesson_of(u, 'facts-to-18-again', 'שׁוּב חִבּוּר וְחִסּוּר', 'MATH-C-01', 'נִפְלָא! עֲבַרְתֶּם אֶת כׇּל הַמִּשְׁפָּחוֹת.', 18, minutes=7)
    lesson_of(u, 'fact-families', 'מִשְׁפְּחוֹת שֶׁל תַּרְגִּילִים', 'MATH-C-02', 'כׇּל הַכָּבוֹד! חִבּוּר וְחִסּוּר הֵם מִשְׁפָּחָה.', minutes=8)
    lesson_of(u, 'whole-tens', 'עֲשָׂרוֹת שְׁלֵמוֹת', 'MATH-C-03', 'מְצֻיָּן! חֲשַׁבְתֶּם בַּעֲשָׂרוֹת.', minutes=8)


def smallbig(a, b):
    """M-SUB-SMALLBIG: the smaller digit from the larger in each column (15 − 7: 1 − 0 and 7 − 5 → 12)."""
    da, db = str(a), str(b).rjust(len(str(a)), '0')
    return int(''.join(str(abs(int(x) - int(y))) for x, y in zip(da, db)))


def make(batches=None):
    """Runs the registered tables of [batches] (all when None) into units and queues them for writing; returns the units made."""
    made = []
    for batch, domain, build, unit in TABLES:
        if batches and batch not in batches:
            continue
        own = dict(unit)
        u = UnitC(batch, domain, own.pop('note', 'Band C, batch %s. Hebrew is a draft, needs-editor.' % batch), **own)
        build(u)
        u.save()
        made.append(u)
    return made


def main(argv):
    batches = [b.upper() for b in argv]
    for b in batches:
        assert b in BATCHES, 'unknown batch %r (batches are %s)' % (b, ' '.join(BATCHES))
    made = make(batches or None)
    write_all()
    if not made:
        print('band_c: no table is registered yet; nothing written')


if __name__ == '__main__':
    main(ARGS)
