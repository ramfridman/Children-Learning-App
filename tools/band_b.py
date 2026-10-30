"""Writes the unit specs of Band B (content/units/band-b-*.json) from compact tables, so the Hebrew that has to be
reviewed is made by one pair of hands and the same rules. Then run tools/author.py on each spec.

    python tools/band_b.py            # writes the specs
    for u in content/units/band-b-*.json; do python tools/author.py $u; done

Every text is a draft and stays `needs-editor` until the owner has approved it.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.argv = sys.argv[:1] + ['-']  # author.py is imported, never run
from author import F, M, count_words, from_, place, prefix, qty, vav  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
UNITS = os.path.join(ROOT, 'content', 'units')


def load(name):
    return json.load(open(os.path.join(UNITS, name + '.json'), encoding='utf-8'))


COLOURS = load('colours')['colours']  # red -> אָדֹם ...
OBJECTS = {**load('counting-hills')['objects'], **load('math')['objects']}
OBJECTS['sock'] = {'g': 'f', 'one': 'גֶּרֶב', 'many': 'גַּרְבַּיִם'}
OBJECTS['shoe'] = {'g': 'f', 'one': 'נַעַל', 'many': 'נַעֲלַיִם'}
SHEKEL = {'g': 'm', 'one': 'שֶׁקֶל', 'many': 'שְׁקָלִים'}
PLATE = {'g': 'f', 'one': 'צַלַּחַת', 'many': 'צַלָּחוֹת'}

NAMES = {
    'tick': {'one': 'כֵּן', 'g': 'm'}, 'cross': {'one': 'לֹא', 'g': 'm'},
    'shape_pentagon': {'one': 'מְחֻמָּשׁ', 'g': 'm'}, 'shape_hexagon': {'one': 'מְשֻׁשֶּׁה', 'g': 'm'},
    'shape_quad': {'one': 'מְרֻבָּע', 'g': 'm'}, 'shape_triangle': {'one': 'מְשֻׁלָּשׁ', 'g': 'm'},
    'shape_circle': {'one': 'עִגּוּל', 'g': 'm'}, 'shape_square': {'one': 'רִבּוּעַ', 'g': 'm'},
    'shape_rect': {'one': 'מַלְבֵּן', 'g': 'm'}, 'shape_open': {'one': 'צוּרָה פְּתוּחָה', 'g': 'f'},
    'shape_curved': {'one': 'צוּרָה עֲקֻמָּה', 'g': 'f'},
    'solid_cylinder': {'one': 'גָּלִיל', 'g': 'm'}, 'solid_cone': {'one': 'חָרוּט', 'g': 'm'},
    'solid_sphere': {'one': 'כַּדּוּר', 'g': 'm'}, 'solid_pyramid': {'one': 'פִּירָמִידָה', 'g': 'f'},
    'solid_box': {'one': 'תֵּבָה', 'g': 'f'},
    'rule_colour': {'one': 'הַצֶּבַע', 'g': 'm'}, 'rule_shape': {'one': 'הַצּוּרָה', 'g': 'f'},
    'rule_size': {'one': 'הַגֹּדֶל', 'g': 'm'},
    'frog': {'one': 'צְפַרְדֵּעַ', 'g': 'f'}, 'block': {'one': 'קֻבִּיָּה', 'g': 'f'},
    'stone': {'one': 'אֶבֶן', 'g': 'f'}, 'feather': {'one': 'נוֹצָה', 'g': 'f'},
    'cat': {'one': 'חָתוּל', 'g': 'm'}, 'dog': {'one': 'כֶּלֶב', 'g': 'm'},
    'rainbow': {'one': 'קֶשֶׁת', 'g': 'f'}, 'coin': {'one': 'מַטְבֵּעַ', 'g': 'm'},
}
for _c, _adj in (('blue', 'כָּחֹל'), ('green', 'יָרֹק'), ('red', 'אָדֹם'), ('purple', 'סָגֹל')):
    for _k, _t in enumerate(('%s בָּהִיר', '%s', '%s כֵּהֶה'), start=1):
        NAMES['shade_%s_%d' % (_c, _k)] = {'one': _t % _adj, 'g': 'm'}
for _k, _o in OBJECTS.items():
    NAMES.setdefault(_k, {'one': _o['one'], 'g': _o['g']})
DAYS = ['יוֹם רִאשׁוֹן', 'יוֹם שֵׁנִי', 'יוֹם שְׁלִישִׁי', 'יוֹם רְבִיעִי', 'יוֹם חֲמִישִׁי', 'יוֹם שִׁשִּׁי', 'שַׁבָּת']
for _k, _d in enumerate(DAYS, start=1):
    NAMES['day_%d' % _k] = {'one': _d, 'g': 'm'}
for _h in range(1, 13):
    NAMES['clock_%d' % _h] = {'one': 'הַשָּׁעוֹן שֶׁמַּרְאֶה %s' % F[_h], 'g': 'm'}
for _t in range(1, 7):
    NAMES['tower_%d' % _t] = {'one': 'מִגְדָּל מִסְפָּר %s' % F[_t], 'g': 'm'}
for _c, _adj in COLOURS.items():
    NAMES['ball_' + _c] = {'one': 'כַּדּוּר ' + _adj, 'g': 'm'}
for _s, (_one, _) in {'circle': ('עִגּוּל', 0), 'square': ('רִבּוּעַ', 0), 'triangle': ('מְשֻׁלָּשׁ', 0), 'rect': ('מַלְבֵּן', 0)}.items():
    for _c, _adj in COLOURS.items():
        NAMES['shape_%s_%s' % (_s, _c)] = {'one': '%s %s' % (_one, _adj), 'g': 'm'}


# Board B-24 (docs/knowledge/voice-answer-by-activity.md): the skills whose `pick` questions the child answers by saying a
# word the question does not say (a number, a colour, a day). Other kinds keep the default of author.py; a skill that mixes
# both (MATH-B-19, SHP-B-03) is not listed and passes voice=True on its spoken questions.
VOICE_SKILLS = frozenset({
    'COL-B-01', 'MATH-B-02', 'MATH-B-03', 'MATH-B-06', 'MATH-B-07', 'MATH-B-08', 'MATH-B-10', 'MATH-B-14', 'MATH-B-15',
    'MATH-B-18', 'NUM-B-10', 'NUM-B-11', 'NUM-B-14', 'NUM-B-17', 'SHP-B-02',
})


def rot(values, i):
    """The same options in another order for each activity (the author's order, never random)."""
    k = i % len(values)
    return values[k:] + values[:k]


def tri(correct, i, others):
    """Three options with the right one in the place that the activity's number picks."""
    o = list(others)
    o.insert(i % 3, correct)
    return o


SHARED_FB = {}  # tag -> the line, for tags that the units of Band B share
MADE = []  # the units made in this run, written together by write_all()


def write_all():
    for u in MADE:
        u.write()


class Unit:
    def __init__(self, name, domain, note, first_seq, assets=(), globs=(), prefix='b'):
        self.d = {'unit': name, 'domain': domain, 'band': 'B', 'note': note, 'firstSequence': first_seq,
                  'assetGlobs': list(globs), 'assets': list(assets), 'objects': OBJECTS, 'names': NAMES,
                  'tagFeedback': {}, 'misconceptions': [], 'skills': [], 'activities': [], 'lessons': []}
        self.name = name
        self.prefix = prefix
        self.counter = {}

    def tag(self, id, skills, parent, home, reps, line):
        self.d['misconceptions'].append({'id': id, 'skills': skills, 'parent': parent, 'home': home, 'reps': reps})
        self.d['tagFeedback'][id] = line
        SHARED_FB[id] = line

    def skill(self, id, title, child, world, needs, reps, tags=(), core=False):
        s = {'id': id, 'title': title, 'child': child, 'world': world, 'needs': list(needs), 'reps': list(reps),
             'tags': list(tags)}
        if core:
            s['core'] = True
        self.d['skills'].append(s)

    def act(self, skill, kind, **kw):
        key = skill.lower().replace('-', '')
        self.counter[key] = self.counter.get(key, 0) + 1
        i = self.counter[key]
        a = {'kind': kind, 'id': '%s.%s.%d' % (self.prefix, key, i), 'skill': skill, 'difficulty': kw.pop('difficulty', round(min(0.9, 0.3 + 0.07 * i), 2))}
        if kind == 'pick' and skill in VOICE_SKILLS:
            a['voice'] = True
        a.update(kw)
        self.d['activities'].append(a)
        return a['id']

    def lesson(self, id, title, skills, items, done, minutes=5):
        self.d['lessons'].append({'id': id, 'title': title, 'skills': skills, 'items': items, 'minutes': minutes, 'done': done})

    def save(self):
        """Queued: the specs are written by write_all() once every unit is made, so each one gets the lines of all."""
        MADE.append(self)

    def write(self):
        # the lines of every Band B unit of this run, then those of the hand-written Band A specs; never the Band B specs
        # on disk, which hold the lines of the last run (an old text would come back)
        for t, line in SHARED_FB.items():
            self.d['tagFeedback'].setdefault(t, line)
        for other in sorted(os.listdir(UNITS)):
            if other.endswith('.json') and not other.startswith('band-b-'):
                for t, line in load(other[:-5]).get('tagFeedback', {}).items():
                    self.d['tagFeedback'].setdefault(t, line)
        path = os.path.join(UNITS, self.name + '.json')
        with open(path, 'w', encoding='utf-8', newline='\n') as fh:
            json.dump(self.d, fh, ensure_ascii=False, indent=1)
            fh.write('\n')
        print(self.name, len(self.d['skills']), 'skills', len(self.d['activities']), 'activities', len(self.d['lessons']), 'lessons')


def steps(k):
    return 'צַעַד אֶחָד' if k == 1 else ('שְׁנֵי צְעָדִים' if k == 2 else '%s צְעָדִים' % M[k])


def clean(correct, others, lo=0, hi=100):
    """Two wrong numbers: different from the right one and from each other, filled up with the nearest ones."""
    out = []
    for o in list(others) + [correct + 1, correct - 1, correct + 2, correct - 2, correct + 3]:
        if o != correct and o not in out and lo <= o <= hi:
            out.append(o)
    return out[:2]


def numpick(u, skill, prompt, correct, others, i, tags=None, h3=None, text=None, **kw):
    """A question with numerals on tiles (its representation follows the label rule of author.py)."""
    others = clean(correct, others)
    return u.act(skill, 'pick', prompt=prompt, options=tri('n:%d' % correct, i, ['n:%d' % o for o in others]),
                 correct='n:%d' % correct, tags={('n:%d' % k): v for k, v in (tags or {}).items()},
                 **({'h3': h3} if h3 else {}), **({'correct_text': text} if text else {}), **kw)


def numpick3(u, skill, prompt, correct, wrong, i, **kw):
    """Three numerals on tiles: the right one and two wrong ones, each with the tag it shows (None for none)."""
    return u.act(skill, 'pick', prompt=prompt, options=tri('n:%d' % correct, i, ['n:%d' % v for v in wrong]), correct='n:%d' % correct,
                 tags={'n:%d' % v: t for v, t in wrong.items() if t}, **kw)


def jump_item(u, skill, start, hop, **kw):
    """The frog hops forward on a line from 0 to 10 and the child says where it lands (the question of NUM-B-13)."""
    return u.act(skill, 'numline', mode='jump', to=10, start=start, hops=[hop], target=start + hop, labels=list(range(0, 11)),
                 prompt='הַצְּפַרְדֵּעַ עוֹמֶדֶת עַל %s וְקוֹפֶצֶת %s קָדִימָה. עַל אֵיזֶה מִסְפָּר הִיא תִּנְחַת?' % (F[start], steps(hop)),
                 h3='מַתְחִילִים %s וְקוֹפְצִים %s קָדִימָה. עַכְשָׁו תּוֹרְכֶם.' % (from_(F[start]), steps(hop)), **kw)


def basket_total(u, skill, obj, a, b, tagged, i, **kw):
    """H4: some in the basket and some outside, how many in all? `tagged` is the part the child may answer with (M-PART-MISS)."""
    o, r = OBJECTS[obj], a + b
    return u.act(skill, 'pick', check='reverse', prompt='יֵשׁ %s בַּסַּל, %s בַּחוּץ. כַּמָּה יֵשׁ בְּסַךְ הַכֹּל?' % (qty(a, o), vav(qty(b, o))),
                 group={'sprite': obj, 'count': a}, group2={'sprite': obj, 'count': b},
                 options=tri('n:%d' % r, i, ['n:%d' % tagged, 'n:%d' % (r + 1)]), correct='n:%d' % r,
                 tags={'n:%d' % tagged: 'M-PART-MISS', 'n:%d' % (r + 1): 'M-CNT-DOUBLE'},
                 correct_text='%s! %s וְעוֹד %s הֵם %s.' % (F[r], F[a], F[b], F[r]),
                 h3='%s וְעוֹד %s: %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (F[a], F[b], count_words(r), F[r]), **kw)


def part_miss_line(x, total):
    """H30 (G4): M-PART-MISS in a number sentence names the whole and ends in the count-on strategy."""
    return {'M-PART-MISS': ('vo:fb.part_miss.sentence.%d_%d' % (x, total),
                            'חִבַּרְנוּ אֶת שְׁנֵיהֶם, אֲבָל %s זֶה כְּבָר הַכֹּל. כַּמָּה מוֹסִיפִים %s כְּדֵי לְהַגִּיעַ %s?' % (
                                F[total], prefix('ל', F[x]), prefix('ל', F[total])))}


def missing_addend(u, skill, x, total, i, flipped=False, **kw):
    """x + ? = total (flipped: total = x + ?). The options are the answer, the whole (M-EQ-OPER) and the sum of the two
    numbers shown (M-PART-MISS, said by H30); the hints count on from x (D2)."""
    r = total - x
    row = ['n:%d' % total, 'op:=', 'n:%d' % x, 'op:+', '?'] if flipped else ['n:%d' % x, 'op:+', '?', 'op:=', 'n:%d' % total]
    prompt = ('%s שָׁוֶה %s וְעוֹד כַּמָּה?' % (F[total], F[x])) if flipped else '%s וְעוֹד כַּמָּה שָׁוֶה %s?' % (F[x], F[total])
    text = ('%s! %s שָׁוֶה %s וְעוֹד %s.' % (F[r], F[total], F[x], F[r])) if flipped else '%s! %s וְעוֹד %s שָׁוֶה %s.' % (F[r], F[x], F[r], F[total])
    return numpick3(u, skill, prompt, r, {total: 'M-EQ-OPER', x + total: 'M-PART-MISS'}, i, row=row, tag_lines=part_miss_line(x, total),
                    correct_text=text,
                    h2='%s כְּבָר יֵשׁ. מוֹסִיפִים אַחַת אַחַת עַד %s, וְסוֹפְרִים כַּמָּה הוֹסַפְנוּ.' % (F[x], F[total]),
                    h3='%s… וּמַמְשִׁיכִים: %s. הֵרַמְנוּ %s אֶצְבָּעוֹת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (
                        F[x], ', '.join(F[k] for k in range(x + 1, total + 1)), 'שְׁתֵּי' if r == 2 else F[r], F[r]), **kw)


# ======================================================================================== NUMBERS

def numbers():
    u = Unit('band-b-numbers', 'numbers',
             'Band B of Numbers: counting to 30, back from ten, 13 to 20 objects, reading the teens, which is bigger, the number '
             'line, splitting a number, ten and some, by tens and twos, even and odd. Hebrew is a draft by Claude, needs-editor.',
             30, assets=['frog', 'tick', 'cross', 'sock', 'block'], globs=['stick_*'])
    u.tag('M-CNT-DECADE', ['NUM-B-02', 'NUM-B-17'], 'הילד לא יודע מה בא אחרי תשע בכל עשרת: אחרי 19 הוא אומר 10 או 100.',
          'לספור יחד מדרגות או מעלות לפני השינה: עשרים ותשע… ומה אחר כך? להפסיק לפני הספרה האחרונה ולתת לילד להשלים.',
          ['concrete', 'symbolic'], 'אַחֲרֵי הַתֵּשַׁע בָּא עֶשֶׂר חָדָשׁ. בּוֹאוּ נִסְפֹּר יַחַד.')
    u.tag('M-NUM-REV', ['NUM-B-08'], 'הילד מחליף בין שתי הספרות: 12 ו-21, 13 ו-31.',
          'לכתוב מספר דו־ספרתי על דף, לקרוא אותו יחד, ואז לכתוב את ההפוך ולשאול מי גדול יותר.',
          ['symbolic', 'concrete'], 'הַסִּפְרָה הָרִאשׁוֹנָה אוֹמֶרֶת כַּמָּה עֲשָׂרוֹת. בּוֹאוּ נִסְתַּכֵּל שׁוּב.')
    u.tag('M-NUM-TEEN', ['NUM-B-16'], 'הילד קורא מספר בין 11 ל-19 כספרה אחת בלבד, ולא כעשר ועוד כמה.',
          'לשים עשר כפיות בצד ואת השאר בצד אחר, ולומר: ארבע עשרה זה עשר ועוד ארבע.',
          ['concrete', 'pictorial'], 'בַּמִּסְפָּר הַזֶּה יֵשׁ עֶשֶׂר, וְעוֹד כַּמָּה? בּוֹאוּ נַפְרִיד אֶת הָעֶשֶׂר.')
    u.tag('M-NL-SPACE', ['NUM-B-13'], 'הילד מסמן על ציר המספרים לפי המקום ולא לפי הרווח בין הסימונים, או סופר את נקודת ההתחלה.',
          'לצייר על רצפה או על נייר ציר עם צעדים שווים, ולקפוץ עליו: מתחילים מהמספר ולא סופרים אותו.',
          ['embodied', 'symbolic'], 'כׇּל קְפִיצָה שָׁוָה. בּוֹאוּ נִקְפֹּץ יַחַד וְנִסְפֹּר.')
    u.tag('M-NL-DIR', ['NUM-B-13'], 'הילד קורא את ציר המספרים מימין לשמאל, כמו מילים, והמספרים הקטנים בצד הלא נכון.',
          'להסביר שבמתמטיקה הציר תמיד הולך משמאל לימין, והמספרים גדלים בכיוון החץ.',
          ['embodied', 'symbolic'], 'הַמִּסְפָּרִים הַקְּטַנִּים בַּצַּד הַשְּׂמֹאלִי, וְהֵם גְּדֵלִים לְכִוּוּן הַחֵץ.')
    u.tag('M-PART-MISS', ['MATH-B-02', 'NUM-B-14'], 'הילד מוסיף במקום לחסר כשחסר חלק, ועונה בסכום.',
          'להסתיר חלק מהחפצים בכוס, ולשאול כמה בכוס אם יש בסך הכול שבעה וחמישה בחוץ.',
          ['concrete', 'pictorial'], 'יֵשׁ הַרְבֵּה בְּסַךְ הַכֹּל, וְחֵלֶק מֵהֶם כְּבָר רָאִינוּ. כַּמָּה חָסֵר?')

    # ---- NUM-B-01..03: counting words
    u.skill('NUM-B-01', 'סופרים עד 20', 'סוֹפְרִים עַד עֶשְׂרִים', 'cone-tree', ['NUM-A-02'], ['symbolic', 'concrete'], ['M-CNT-SEQ'])
    u.skill('NUM-B-02', 'סופרים עד 30', 'סוֹפְרִים עַד שְׁלוֹשִׁים', 'cone-tree', ['NUM-B-01'], ['symbolic'], ['M-CNT-DECADE'])
    u.skill('NUM-B-03', 'סופרים אחורה מעשר', 'סוֹפְרִים אֲחוֹרָה כְּמוֹ בַּחֲלָלִית', 'cone-tree', ['NUM-A-02'], ['symbolic'], ['M-CNT-SEQ'])
    for i, (n, d) in enumerate([(11, 'after'), (13, 'after'), (15, 'after'), (12, 'after'), (16, 'after'), (14, 'before'),
                                (17, 'before'), (20, 'before'), (18, 'after')]):
        ans = n + 1 if d == 'after' else n - 1
        skip = ans + 1 if d == 'after' else ans - 1
        # "what comes before" is the reverse of the skill's counting on (B-15 addendum A3)
        u.act('NUM-B-01', 'next_number', n=n, dir=d, options=tri(ans, i, [skip, n]), **({'check': 'reverse'} if d == 'before' else {}))
    for i, (n, d) in enumerate([(19, 'after'), (29, 'after'), (20, 'after'), (24, 'after'), (28, 'after'), (21, 'before'),
                                (30, 'before'), (26, 'after'), (27, 'after')]):
        ans = n + 1 if d == 'after' else n - 1
        restart = n - 9 if (d == 'after' and n % 10 == 9) else (ans + 1 if d == 'after' else ans - 1)
        u.act('NUM-B-02', 'next_number', n=n, dir=d, decade=True, options=tri(ans, i, [restart, n]),
              **({'check': 'reverse'} if d == 'before' else {}))
    for i, n in enumerate([10, 8, 6, 9, 7, 5, 4, 3]):
        u.act('NUM-B-03', 'next_number', n=n, dir='before', options=tri(n - 1, i, [n - 2, n]))

    # B-15 §1: a count backwards with a mistake in it (X4b: the row counts down)
    for shown, w in (([10, 9, 7, 7, 6], 2), ([8, 7, 6, 4, 4], 3)):
        right = list(shown)
        right[w] = shown[w - 1] - 1
        u.act('NUM-B-03', 'spot', cells=['n:%d' % v for v in shown], wrong=w, tag='M-CNT-SEQ', check='error_spotting', difficulty=0.5,
              prompt='חָבֵר סָפַר מִסְפָּרִים, וְיֵשׁ בָּהֶם טָעוּת. אֵיפֹה הַטָּעוּת?',
              h3='נִסְפֹּר אֲחוֹרָה: %s. עַכְשָׁו תּוֹרְכֶם.' % ', '.join(F[v] for v in right),
              correct_text='כֵּן! בַּמָּקוֹם הַזֶּה הָיָה צָרִיךְ לִהְיוֹת %s.' % F[right[w]])

    # ---- NUM-B-04, 05: objects up to 20
    u.skill('NUM-B-04', 'סופרים עד 20 עצמים', 'סוֹפְרִים עַד עֶשְׂרִים חֲפָצִים', 'cone-tree', ['NUM-A-09'], ['concrete', 'pictorial'],
            ['M-CNT-DOUBLE', 'M-CNT-SKIP'])
    u.skill('NUM-B-05', 'נותנים עד 20', 'נוֹתְנִים בְּדִיּוּק כַּמָּה שֶׁמְּבַקְשִׁים', 'cone-tree', ['NUM-B-04', 'NUM-A-06'],
            ['concrete'], ['M-CNT-CARD'])
    for i, (obj, n) in enumerate([('apple', 12), ('star', 14), ('fish', 13), ('duck', 16), ('ladybug', 15), ('bird', 17),
                                  ('apple', 18), ('fish', 19), ('star', 20)]):
        u.act('NUM-B-04', 'count_tap', obj=obj, count=n, options=tri(n, i, [n - 1, n + 1] if n < 20 else [n - 1, n - 2]), seed=20 + i)
    for i, (obj, n) in enumerate([('apple', 13), ('star', 15), ('fish', 14), ('duck', 17), ('ladybug', 16), ('bird', 18),
                                  ('apple', 19), ('fish', 20)]):
        u.act('NUM-B-05', 'give', obj=obj, n=n, source=20, check='practice')  # giving N is this skill's own task (B-15 §2)

    # B-15 §1 and addendum A3: the transfer to other sprites, and to giving into other places
    for i, (obj, n) in enumerate([('cat', 14), ('butterfly', 17)]):
        u.act('NUM-B-04', 'count_tap', obj=obj, count=n, options=tri(n, i, [n - 1, n + 1]), seed=40 + i, check='transfer', difficulty=0.6)
    for obj, n, into in (('fish', 12, 'bowl_empty'), ('bird', 16, 'nest_empty')):
        u.act('NUM-B-05', 'give', obj=obj, n=n, source=20, target=into, check='transfer', difficulty=0.6)

    # ---- NUM-B-08: reading 11..20 with reversed digits as the trap
    u.skill('NUM-B-08', 'קוראים 11–20', 'קוֹרְאִים אֶת הַמִּסְפָּרִים עַד עֶשְׂרִים', 'pool', ['NUM-A-08', 'NUM-B-01'], ['symbolic'],
            ['M-NUM-REV'])
    for i, n in enumerate([12, 13, 14, 15, 16, 17, 18, 19]):
        rev = int(str(n)[::-1])
        numpick(u, 'NUM-B-08', 'אֵיפֹה הַמִּסְפָּר %s?' % F[n], n, [rev, n + 1 if n < 19 else n - 2], i, tags={rev: 'M-NUM-REV'},
                text='כֵּן! זֶה %s.' % F[n])
    for i, n in enumerate([20, 11, 18, 12]):
        if n == 11:  # its digits read the same both ways: the trap is the "one" heard first (B-15 §3)
            numpick(u, 'NUM-B-08', 'אֵיפֹה הַמִּסְפָּר %s?' % F[n], n, [1, 12], i, tags={1: 'M-NUM-TEEN', 12: 'M-CNT-SEQ'},
                    text='כֵּן! זֶה %s.' % F[n])
            continue
        numpick(u, 'NUM-B-08', 'אֵיפֹה הַמִּסְפָּר %s?' % F[n], n, [int(str(n)[::-1]) if n % 10 else 2, n - 1], i,
                tags={int(str(n)[::-1]) if n % 10 else 2: 'M-NUM-REV'}, text='כֵּן! זֶה %s.' % F[n])

    # B-15 §1: the number missing from a row of numerals
    for i, (seq, ans, rev, nxt) in enumerate([([11, 12, None, 14], 13, 31, 15), ([16, None, 18], 17, 71, 18)]):
        numpick3(u, 'NUM-B-08', 'אֵיזֶה מִסְפָּר חָסֵר?', ans, {rev: 'M-NUM-REV', nxt: 'M-CNT-SEQ'}, i, check='transfer', difficulty=0.6,
                 row=['?' if v is None else 'n:%d' % v for v in seq], correct_text='כֵּן! זֶה %s.' % F[ans],
                 h3='%s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (', '.join(F[ans if v is None else v] for v in seq), F[ans]))

    # ---- NUM-B-10: which numeral is bigger
    u.skill('NUM-B-10', 'איזה מספר גדול יותר', 'מַשְׁוִים שְׁנֵי מִסְפָּרִים', 'pool', ['NUM-A-12', 'NUM-A-08'], ['symbolic'], ['M-CNT-SIZE'])
    for i, (a, b, ask) in enumerate([(7, 4, 'big'), (5, 9, 'big'), (12, 8, 'big'), (15, 17, 'big'), (6, 3, 'small'), (9, 2, 'small'),
                                     (14, 11, 'small'), (19, 20, 'big'), (13, 31, 'big'), (18, 8, 'big')]):
        right, wrong = (max(a, b), min(a, b)) if ask == 'big' else (min(a, b), max(a, b))
        word = 'גָּדוֹל' if ask == 'big' else 'קָטָן'
        u.act('NUM-B-10', 'pick', prompt='אֵיזֶה מִסְפָּר %s יוֹתֵר?' % word,
              options=['n:%d' % right, 'n:%d' % wrong] if i % 2 == 0 else ['n:%d' % wrong, 'n:%d' % right], correct='n:%d' % right,
              **({'check': 'reverse'} if ask == 'small' else {}),  # "which is smaller?" (B-15 addendum A3)
              correct_text='כֵּן! %s.' % F[right],
              h3='%s %s. %s. עַכְשָׁו תּוֹרְכֶם.' % (F[a], vav(F[b]), 'הַמִּסְפָּר שֶׁבָּא יוֹתֵר מְאֻחָר בַּסְּפִירָה גָּדוֹל יוֹתֵר' if ask == 'big' else 'הַמִּסְפָּר שֶׁבָּא קֹדֶם בַּסְּפִירָה קָטָן יוֹתֵר'))

    # ---- NUM-B-11: order, one more, one less
    u.skill('NUM-B-11', 'סדר המספרים, אחד יותר ואחד פחות', 'מוֹצְאִים מִסְפָּר שֶׁחָסֵר, אֶחָד יוֹתֵר וְאֶחָד פָּחוֹת', 'pool', ['NUM-B-10'],
            ['symbolic'], ['M-CNT-SEQ'])
    rows = [(1, 5, 3, 8), (3, 5, 1, 9), (5, 5, 4, 2), (6, 6, 2, 12), (10, 5, 3, 14), (4, 6, 5, 12)]
    for start, length, w, v in rows:
        cells = ['n:%d' % (start + k) for k in range(length)]
        cells[w] = 'n:%d' % v
        u.act('NUM-B-11', 'spot', cells=cells, wrong=w, tag='M-CNT-SEQ',
              prompt='חָבֵר סָפַר מִסְפָּרִים, וְיֵשׁ בָּהֶם טָעוּת. אֵיפֹה הַטָּעוּת?',
              h3='הַמִּסְפָּרִים גְּדֵלִים בְּאֶחָד כָּל פַּעַם. אֶחָד מֵהֶם לֹא מַתְאִים. עַכְשָׁו תּוֹרְכֶם.',
              correct_text='כֵּן! בַּמָּקוֹם הַזֶּה הָיָה צָרִיךְ לִהְיוֹת %s.' % F[start + w])
    for i, n in enumerate([3, 6, 8, 11, 14, 17]):
        numpick(u, 'NUM-B-11', 'הוֹסִיפוּ עוֹד אַחַת אֶל %s. כַּמָּה יֵשׁ עַכְשָׁו?' % F[n], n + 1, [n, n + 2], i,
                tags={n + 2: 'M-CNT-SEQ'}, text='%s! עוֹד אַחַת.' % F[n + 1])
    for i, n in enumerate([4, 7, 9, 12, 15, 18]):
        numpick(u, 'NUM-B-11', 'קְחוּ אַחַת מִתּוֹךְ %s. כַּמָּה נִשְׁאֲרוּ?' % F[n], n - 1, [n, n - 2], i,
                tags={n - 2: 'M-CNT-SEQ'}, text='%s! אַחַת פָּחוֹת.' % F[n - 1])

    # ---- NUM-B-13: the number line
    u.skill('NUM-B-13', 'ציר המספרים', 'קוֹפְצִים עַל צִיר הַמִּסְפָּרִים', 'dock', ['NUM-B-11'], ['embodied', 'symbolic'],
            ['M-NL-SPACE', 'M-NL-DIR'])
    for n in (3, 7, 5, 8, 2, 9):
        u.act('NUM-B-13', 'numline', mode='place', to=10, target=n, labels=list(range(0, 11)),
              prompt='הַצְּפַרְדֵּעַ רוֹצָה לַעֲמֹד עַל %s. נוֹגְעִים בַּמָּקוֹם.' % F[n])
    for n in (13, 6, 17, 15, 9, 18):
        u.act('NUM-B-13', 'numline', mode='place', to=20, target=n, labels=[0, 5, 10, 15, 20],
              prompt='הַצְּפַרְדֵּעַ רוֹצָה לַעֲמֹד עַל %s. נוֹגְעִים בַּמָּקוֹם.' % F[n])
    for start, hops, d in [(2, [3], 'f'), (4, [2], 'f'), (1, [5], 'f'), (7, [-3], 'b'), (9, [-4], 'b'), (3, [2, 3], 'f'), (8, [-2, -3], 'b')]:
        end = start + sum(hops)
        k = abs(sum(hops))
        way = 'קָדִימָה' if d == 'f' else 'אֲחוֹרָה'
        u.act('NUM-B-13', 'numline', mode='jump', to=10, start=start, hops=hops, target=end, labels=list(range(0, 11)),
              check='predict',  # "on which number will she land?" (B-15 §1)
              prompt='הַצְּפַרְדֵּעַ עוֹמֶדֶת עַל %s וְקוֹפֶצֶת %s %s. עַל אֵיזֶה מִסְפָּר הִיא תִּנְחַת?' % (F[start], steps(k), way),
              h3='מַתְחִילִים %s וְקוֹפְצִים %s %s. עַכְשָׁו תּוֹרְכֶם.' % (from_(F[start]), steps(k), way))

    for n in (5, 8):  # B-15 §1: the transfer to a line with only its two ends marked
        u.act('NUM-B-13', 'numline', mode='place', to=10, target=n, labels=[0, 10], check='transfer', difficulty=0.6,
              prompt='הַצְּפַרְדֵּעַ רוֹצָה לַעֲמֹד עַל %s. נוֹגְעִים בַּמָּקוֹם.' % F[n])

    # ---- NUM-B-14: splitting a number
    u.skill('NUM-B-14', 'מפרקים מספר לשני חלקים', 'מְפָרְקִים מִסְפָּר לִשְׁנֵי חֲלָקִים', 'pool', ['NUM-A-10'], ['concrete', 'symbolic'],
            ['M-PART-MISS'])
    for i, (obj, total, part) in enumerate([('apple', 5, 2), ('star', 6, 4), ('fish', 7, 3), ('duck', 8, 5), ('ladybug', 9, 4),
                                            ('bird', 10, 6), ('apple', 8, 3), ('star', 10, 7)]):
        o = OBJECTS[obj]
        rest = total - part
        numpick(u, 'NUM-B-14', 'יֵשׁ %s. מַכְנִיסִים %s לַסַּל. כַּמָּה נִשְׁאֲרוּ בַּחוּץ?' % (qty(total, o), qty(part, o)), rest,
                [total, part] if rest not in (total, part) else [total + 1, part + 1], i, tags={total: 'M-PART-MISS'},
                group={'sprite': obj, 'count': total},
                text='%s! %s וְעוֹד %s הֵם %s.' % (F[rest], F[rest], F[part], F[total]),
                h3='%s. הִכְנַסְנוּ %s, אָז נִשְׁאֲרוּ %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (count_words(total), F[part], F[rest], F[rest]))

    # B-15 §1 (H4): the parts put back together
    for i, (obj, a, b) in enumerate([('apple', 4, 2), ('fish', 5, 3)]):
        basket_total(u, 'NUM-B-14', obj, a, b, a, i, difficulty=0.6)

    # ---- NUM-B-16: a teen is ten and some
    u.skill('NUM-B-16', 'עשר ועוד כמה', 'רוֹאִים עֶשֶׂר וְעוֹד כַּמָּה', 'pool', ['NUM-B-08', 'NUM-B-14'], ['concrete', 'pictorial'],
            ['M-NUM-TEEN'])
    for i, n in enumerate([11, 12, 13, 14, 15, 16, 17, 18, 19]):
        obj = ['apple', 'star', 'fish', 'duck', 'ladybug', 'bird', 'apple', 'star', 'fish'][i]
        # B-15 §4 options: the whole number (the ten not taken apart), and the tens digit read as the ones; for 11, the ten
        others = {n: 'M-NUM-TEEN', 1: 'M-NUM-REV'} if n > 11 else {n: 'M-NUM-TEEN', 10: 'M-PART-MISS'}
        if i % 2 == 0:  # a full frame and the frame of the ones; the second hint counts only the second frame (H33a)
            kind = dict(group={'sprite': obj, 'count': 10, 'arrangement': 'ten_frame'}, group2={'sprite': obj, 'count': n - 10, 'arrangement': 'ten_frame'},
                        h2='בַּמִּסְגֶּרֶת הַמְּלֵאָה יֵשׁ עֶשֶׂר. נִסְפֹּר רַק אֶת הַמִּסְגֶּרֶת הָאַחֶרֶת.', h2_action='highlight_objects_sequentially')
        else:  # the number sentence; the second hint counts the fingers after the ten (H33b)
            kind = dict(row=['n:%d' % n, 'op:=', 'n:10', 'op:+', '?'],
                        h2='עֶשֶׂר אֶצְבָּעוֹת, וְעוֹד כַּמָּה? נִסְפֹּר רַק אֶת הָאֶצְבָּעוֹת שֶׁאַחֲרֵי הָעֶשֶׂר.', h2_action='show_fingers')
        numpick(u, 'NUM-B-16', '%s זֶה עֶשֶׂר וְעוֹד כַּמָּה?' % F[n], n - 10, list(others), i,
                tags=others, text='%s! עֶשֶׂר וְעוֹד %s הֵם %s.' % (F[n - 10], F[n - 10], F[n]),
                h3='%s. עֶשֶׂר, וְעוֹד %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (count_words(n), count_words(n - 10), F[n - 10]), **kind)

    # B-15 §4 (H34): two frames and the question the other way round
    for i, (obj, k) in enumerate([('duck', 4), ('star', 7)]):
        n = 10 + k
        numpick3(u, 'NUM-B-16', 'עֶשֶׂר וְעוֹד %s. כַּמָּה זֶה?' % F[k], n, {int(str(n)[::-1]): 'M-NUM-REV', 10: 'M-PART-MISS'}, i,
                 check='reverse', difficulty=0.6, group={'sprite': obj, 'count': 10, 'arrangement': 'ten_frame'},
                 group2={'sprite': obj, 'count': k, 'arrangement': 'ten_frame'},
                 correct_text='%s! עֶשֶׂר וְעוֹד %s הֵם %s.' % (F[n], F[k], F[n]),
                 h3='%s. עֶשֶׂר, וְעוֹד %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (count_words(n), count_words(k), F[n]))

    # ---- NUM-B-17: by tens and twos
    u.skill('NUM-B-17', 'סופרים בעשרות ובזוגות', 'סוֹפְרִים בַּעֲשָׂרוֹת וּבִשְׁתַּיִם', 'cone-tree', ['NUM-B-02'], ['symbolic'],
            ['M-CNT-DECADE', 'M-CNT-SEQ'])
    for start, step, length, w, v, nm in [(10, 10, 5, 3, 35, 'בַּעֲשָׂרוֹת'), (10, 10, 5, 2, 25, 'בַּעֲשָׂרוֹת'), (20, 10, 5, 4, 51, 'בַּעֲשָׂרוֹת'),
                                          (2, 2, 5, 3, 9, 'בִּשְׁתַּיִם'), (2, 2, 5, 2, 7, 'בִּשְׁתַּיִם'), (4, 2, 5, 4, 13, 'בִּשְׁתַּיִם')]:
        cells = ['n:%d' % (start + step * k) for k in range(length)]
        cells[w] = 'n:%d' % v
        u.act('NUM-B-17', 'spot', cells=cells, wrong=w, tag='M-CNT-DECADE' if step == 10 else 'M-CNT-SEQ',
              prompt='סוֹפְרִים %s. אֵיפֹה הַטָּעוּת?' % nm,
              h3='כׇּל מִסְפָּר גָּדוֹל מֵהַמִּסְפָּר שֶׁלְּפָנָיו %s. עַכְשָׁו תּוֹרְכֶם.' % prefix('ב', 'עֶשֶׂר' if step == 10 else 'שְׁתַּיִם'),
              correct_text='כֵּן! כָּאן הָיָה צָרִיךְ לִהְיוֹת %s.' % F[start + step * w])
    for i, (seq, nxt, nm) in enumerate([((10, 20, 30), 40, 'בַּעֲשָׂרוֹת'), ((20, 30, 40), 50, 'בַּעֲשָׂרוֹת'), ((50, 60, 70), 80, 'בַּעֲשָׂרוֹת'),
                                        ((2, 4, 6), 8, 'בִּשְׁתַּיִם'), ((4, 6, 8), 10, 'בִּשְׁתַּיִם'), ((6, 8, 10), 12, 'בִּשְׁתַּיִם')]):
        step = seq[1] - seq[0]
        numpick(u, 'NUM-B-17', 'סוֹפְרִים %s: %s. מַה בָּא אַחַר כָּךְ?' % (nm, ', '.join(F[x] for x in seq)), nxt,
                [seq[-1] + 1, nxt + step], i, tags={seq[-1] + 1: 'M-CNT-DECADE' if step == 10 else 'M-CNT-SEQ'},
                text='%s! %s.' % (F[nxt], ', '.join(F[x] for x in seq + (nxt,))))

    # ---- NUM-B-18: even and odd
    u.skill('NUM-B-18', 'זוגי ולא זוגי', 'מְחַלְּקִים לְזוּגוֹת', 'pool', ['NUM-B-04'], ['concrete'], [])
    for i, n in enumerate([4, 5, 6, 7, 9, 8, 11, 10]):
        even = n % 2 == 0
        u.act('NUM-B-18', 'pick', prompt='אֶפְשָׁר לְחַלֵּק אֶת כֻּלָּם לְזוּגוֹת, בְּלִי שֶׁיִּשָּׁאֵר אֶחָד לְבַד?',
              group={'sprite': 'sock', 'count': n, 'arrangement': 'scatter'}, options=['cross', 'tick'] if i % 2 else ['tick', 'cross'],
              correct='tick' if even else 'cross',
              correct_text='כֵּן, כֻּלָּם בְּזוּגוֹת.' if even else 'לֹא, אֶחָד נִשְׁאָר לְבַד.',
              h3='נְחַלֵּק לְזוּגוֹת: %s. %s. עַכְשָׁו תּוֹרְכֶם.' % (', '.join('זוּג' for _ in range(n // 2)),
                                                                'כֻּלָּם בְּזוּגוֹת' if even else 'אֶחָד נִשְׁאָר לְבַד'))

    # B-15 §1: shoes (feminine) instead of socks
    for i, n in enumerate([6, 7]):
        even = n % 2 == 0
        u.act('NUM-B-18', 'pick', check='transfer', difficulty=0.6, prompt='אֶפְשָׁר לְחַלֵּק אֶת כֻּלָּן לְזוּגוֹת, בְּלִי שֶׁתִּשָּׁאֵר אַחַת לְבַד?',
              group={'sprite': 'shoe', 'count': n, 'arrangement': 'scatter'}, options=['cross', 'tick'] if i % 2 else ['tick', 'cross'],
              correct='tick' if even else 'cross',
              correct_text='כֵּן, כֻּלָּן בְּזוּגוֹת.' if even else 'לֹא, אַחַת נִשְׁאֶרֶת לְבַד.',
              h3='נְחַלֵּק לְזוּגוֹת: %s. %s. עַכְשָׁו תּוֹרְכֶם.' % (', '.join('זוּג' for _ in range(n // 2)),
                                                                'כֻּלָּן בְּזוּגוֹת' if even else 'אַחַת נִשְׁאֶרֶת לְבַד'))

    # ---- lessons
    def ids(skill, a=0, b=None):
        return [x['id'] for x in u.d['activities'] if x['skill'] == skill][a:b]

    u.lesson('count-to-20', 'סוֹפְרִים עַד עֶשְׂרִים', ['NUM-B-01'], ids('NUM-B-01', 0, 5), 'כׇּל הַכָּבוֹד! סְפַרְתֶּם עַד עֶשְׂרִים.')
    u.lesson('count-to-20-more', 'עוֹד סְפִירָה עַד עֶשְׂרִים', ['NUM-B-01'], ids('NUM-B-01', 5), 'יָפֶה מְאֹד! הַסְּפִירָה מַמְשִׁיכָה.')
    u.lesson('count-to-30', 'סוֹפְרִים עַד שְׁלוֹשִׁים', ['NUM-B-02'], ids('NUM-B-02', 0, 5), 'כׇּל הַכָּבוֹד! עָבַרְתֶּם אֶת הָעֲשָׂרוֹת.')
    u.lesson('count-to-30-more', 'עוֹד עֲשָׂרוֹת', ['NUM-B-02'], ids('NUM-B-02', 5), 'נִפְלָא! הָעֲשָׂרוֹת כְּבָר מוּכָּרוֹת.')
    u.lesson('rocket-countdown', 'סְפִירָה לַאֲחוֹר', ['NUM-B-03'], ids('NUM-B-03'), 'שָׁלוֹשׁ, שְׁתַּיִם, אַחַת… הַחֲלָלִית טָסָה!')
    u.lesson('many-things', 'הַרְבֵּה חֲפָצִים', ['NUM-B-04'], ids('NUM-B-04', 0, 5), 'כׇּל הַכָּבוֹד! סְפַרְתֶּם הַרְבֵּה חֲפָצִים.')
    u.lesson('many-things-more', 'עוֹד הַרְבֵּה חֲפָצִים', ['NUM-B-04'], ids('NUM-B-04', 5), 'מְצֻיָּן! כׇּל אֶחָד פַּעַם אַחַת.')
    u.lesson('give-up-to-20', 'נוֹתְנִים עַד עֶשְׂרִים', ['NUM-B-05'], ids('NUM-B-05'), 'יָפֶה! נְתַתֶּם בְּדִיּוּק כַּמָּה שֶׁבִּקַּשְׁנוּ.')
    u.lesson('read-the-teens', 'קוֹרְאִים אֶת הַמִּסְפָּרִים', ['NUM-B-08'], ids('NUM-B-08', 0, 6), 'כׇּל הַכָּבוֹד! אַתֶּם קוֹרְאִים מִסְפָּרִים.')
    u.lesson('read-the-teens-more', 'עוֹד מִסְפָּרִים', ['NUM-B-08'], ids('NUM-B-08', 6), 'מְצֻיָּן! הַסִּפְרוֹת בַּמָּקוֹם הַנָּכוֹן.')
    u.lesson('which-is-bigger', 'אֵיזֶה גָּדוֹל יוֹתֵר', ['NUM-B-10'], ids('NUM-B-10', 0, 5), 'יָפֶה! הִשְׁוִיתֶם מִסְפָּרִים.')
    u.lesson('which-is-bigger-more', 'עוֹד הַשְׁוָאוֹת', ['NUM-B-10'], ids('NUM-B-10', 5), 'מְצֻיָּן! אַתֶּם יוֹדְעִים מִי גָּדוֹל.')
    u.lesson('count-order', 'הַמִּסְפָּרִים בַּסֵּדֶר', ['NUM-B-11'], ids('NUM-B-11', 0, 6), 'כׇּל הַכָּבוֹד! מְצָאתֶם אֶת הַטָּעֻיּוֹת.')
    u.lesson('one-more-one-less', 'אֶחָד יוֹתֵר, אֶחָד פָּחוֹת', ['NUM-B-11'], ids('NUM-B-11', 6), 'נִפְלָא! אֶחָד יוֹתֵר וְאֶחָד פָּחוֹת.')
    u.lesson('frog-line-10', 'הַצְּפַרְדֵּעַ עַל הַצִּיר', ['NUM-B-13'], ids('NUM-B-13', 0, 6), 'כׇּל הַכָּבוֹד! הַצְּפַרְדֵּעַ בַּמָּקוֹם הַנָּכוֹן.')
    u.lesson('frog-line-20', 'צִיר עַד עֶשְׂרִים', ['NUM-B-13'], ids('NUM-B-13', 6, 12), 'יָפֶה מְאֹד! הַצִּיר אָרֹךְ יוֹתֵר.')
    u.lesson('frog-jumps', 'הַצְּפַרְדֵּעַ קוֹפֶצֶת', ['NUM-B-13'], ids('NUM-B-13', 12), 'וַאוּ! קְפִיצוֹת מְצֻיָּנוֹת.')
    u.lesson('split-numbers', 'מְפָרְקִים מִסְפָּרִים', ['NUM-B-14'], ids('NUM-B-14', 0, 5), 'כׇּל הַכָּבוֹד! אַתֶּם יוֹדְעִים לְפָרֵק.')
    u.lesson('split-numbers-more', 'עוֹד פֵּרוּקִים', ['NUM-B-14'], ids('NUM-B-14', 5), 'מְצֻיָּן! כׇּל חֵלֶק בִּמְקוֹמוֹ.')
    u.lesson('ten-and-some', 'עֶשֶׂר וְעוֹד כַּמָּה', ['NUM-B-16'], ids('NUM-B-16', 0, 5), 'כׇּל הַכָּבוֹד! רְאִיתֶם אֶת הָעֶשֶׂר.')
    u.lesson('ten-and-some-more', 'עוֹד עֶשֶׂר וְעוֹד', ['NUM-B-16'], ids('NUM-B-16', 5), 'נִפְלָא! הַמִּסְפָּרִים הַגְּדוֹלִים כְּבָר מוּכָּרִים.')
    u.lesson('tens-and-twos', 'עֲשָׂרוֹת וְזוּגוֹת', ['NUM-B-17'], ids('NUM-B-17'), 'יָפֶה מְאֹד! סְפַרְתֶּם בִּקְפִיצוֹת.')
    u.lesson('pairs', 'זוּגוֹת', ['NUM-B-18'], ids('NUM-B-18'), 'כׇּל הַכָּבוֹד! חִלַּקְתֶּם לְזוּגוֹת.')
    u.save()


# ======================================================================================== MATH

def math():
    u = Unit('band-b-math', 'math',
             'Band B of Money and Maths: join and take away, missing part, number sentences, make ten, zero, within twenty, '
             '"equals" as "the same as", equal groups, weighing, days of the week, the clock, and the missing number. '
             'Hebrew is a draft by Claude, needs-editor.',
             30, assets=['block', 'stone', 'feather', 'tick', 'cross'], globs=['day_*', 'clock_*'])
    u.tag('M-EQ-OPER', ['MATH-B-03', 'MATH-B-09', 'MATH-B-18'], 'הילד קורא את סימן השוויון כ"עכשיו מחשבים", ולכן ⁦7 = 3 + 4⁩ נראה לו הפוך.',
          'לשים שני צדדים על מאזניים של בית, למשל שלוש כפיות ועוד ארבע מול שבע, ולומר: זה שווה, שני הצדדים אותו דבר.',
          ['concrete', 'symbolic'], 'סִימַן הַשָּׁוֶה אוֹמֵר: בִּשְׁנֵי הַצְּדָדִים יֵשׁ אוֹתוֹ מִסְפָּר. בּוֹאוּ נִבְדֹּק.')
    u.tag('M-MEAS-BIG', ['MATH-B-13'], 'הילד חושב שמה שגדול יותר גם כבד יותר.',
          'להחזיק בכל יד חפץ גדול וקל (כדור נייר) וחפץ קטן וכבד (אבן), ולנחש מי כבד יותר לפני שמרגישים.',
          ['concrete'], 'גָּדוֹל לֹא תָּמִיד כָּבֵד. בּוֹאוּ נִשְׁקֹל וְנִרְאֶה.')
    u.tag('M-CLOCK-HANDS', ['MATH-B-15'], 'הילד מחליף בין המחוג הקצר למחוג הארוך: קורא 3:00 כ"שתים עשרה".',
          'להסביר: המחוג הקצר והעבה הוא "הבוס של השעות". להסתכל ביחד בשעון קיר בכל שעה עגולה.',
          ['pictorial', 'embodied'], 'הַמַּחֲוָג הַקָּצָר וְהָעָבֶה אוֹמֵר אֶת הַשָּׁעָה. בּוֹאוּ נִסְתַּכֵּל עָלָיו.')
    u.tag('M-ADD-RECOUNT', ['MATH-B-01', 'MATH-B-08'], 'הילד סופר הכול מההתחלה במקום להמשיך מהמספר הגדול.',
          'להסתיר חמישה מטבעות בכף יד סגורה, ולהוסיף עוד שלושה אחד אחד: חמש… שש, שבע, שמונה.',
          ['concrete', 'embodied'], 'אֵין צֹרֶךְ לִסְפֹּר הַכֹּל מֵחָדָשׁ. מַתְחִילִים מֵהַמִּסְפָּר הַגָּדוֹל.')
    # ---- MATH-B-01: join and take away
    u.skill('MATH-B-01', 'מוסיפים ולוקחים עד 10', 'מוֹסִיפִים וְלוֹקְחִים', 'stall', ['MATH-A-01', 'MATH-A-02'], ['concrete', 'pictorial'],
            ['M-ADD-RECOUNT'], core=True)
    adds = [('apple', 3, 2), ('fish', 4, 3), ('star', 5, 2), ('duck', 2, 6), ('ladybug', 6, 3), ('bird', 4, 4)]
    takes = [('apple', 5, 2), ('fish', 7, 3), ('star', 6, 4), ('duck', 9, 5), ('ladybug', 8, 3), ('bird', 10, 6)]
    for i, (obj, x, y) in enumerate(adds):
        u.act('MATH-B-01', 'sum', mode='add', obj=obj, a=x, b=y, pos=i % 3)
    for i, (obj, x, y) in enumerate(takes):
        u.act('MATH-B-01', 'sum', mode='take', obj=obj, a=x, b=y, pos=i % 3)

    # B-15 §1: touch and count a join (a second representation), the reverse of a join, and the jump on the line
    for i, (obj, x, y) in enumerate([('apple', 3, 2), ('apple', 4, 3)]):
        u.act('MATH-B-01', 'count_tap', obj=obj, count=x + y, options=tri(x + y, i, [x + y - 1, x + y + 1]), seed=50 + i, difficulty=0.5,
              prompt='יֵשׁ %s. מוֹסִיפִים עוֹד %s. כַּמָּה יֵשׁ עַכְשָׁו?' % (qty(x, OBJECTS[obj]), qty(y, OBJECTS[obj])))
    for i, (obj, x, t) in enumerate([('apple', 3, 5), ('fish', 4, 7)]):
        r = t - x
        numpick3(u, 'MATH-B-01', 'יֵשׁ %s. מוֹסִיפִים עוֹד, וְעַכְשָׁו יֵשׁ %s. כַּמָּה הוֹסַפְנוּ?' % (qty(x, OBJECTS[obj]), qty(t, OBJECTS[obj])), r,
                 {t: 'M-PART-MISS', x: 'M-CNT-DOUBLE'}, i, check='reverse', difficulty=0.6, voice=True, group={'sprite': obj, 'count': x},
                 correct_text='%s! %s וְעוֹד %s הֵם %s.' % (F[r], F[x], F[r], F[t]),
                 h3='%s וְעוֹד %s: %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (F[x], F[r], count_words(t), F[r]))
    for start, hop in ((3, 2), (4, 3)):
        jump_item(u, 'MATH-B-01', start, hop, check='transfer', difficulty=0.6)

    # ---- MATH-B-02: the missing part
    u.skill('MATH-B-02', 'מוצאים חלק שחסר', 'מוֹצְאִים אֶת הַחֵלֶק שֶׁחָסֵר', 'stall', ['NUM-B-14', 'MATH-B-01'], ['concrete', 'symbolic'],
            ['M-PART-MISS'])
    for i, (obj, total, part) in enumerate([('apple', 6, 4), ('fish', 7, 2), ('star', 8, 5), ('duck', 9, 3), ('ladybug', 10, 7), ('bird', 8, 6)]):
        u.act('MATH-B-02', 'sum', mode='missing', obj=obj, a=total, b=part, pos=i % 3)
    for i, (total, part) in enumerate([(6, 2), (7, 5), (9, 4), (10, 3)]):
        r = total - part
        u.act('MATH-B-02', 'pick', prompt='%s זֶה %s וְעוֹד כַּמָּה?' % (F[total], F[part]),
              options=tri('n:%d' % r, i, ['n:%d' % total, 'n:%d' % (r + 1)]), correct='n:%d' % r, tags={'n:%d' % total: 'M-PART-MISS'},
              correct_text='%s! %s וְעוֹד %s הֵם %s.' % (F[r], F[part], F[r], F[total]),
              h3='%s וְעוֹד %s: %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (F[part], F[r], count_words(total), F[r]))

    # B-15 §1 (H4): the parts put back together, outside the basket this time
    for i, (obj, a, b) in enumerate([('star', 2, 5), ('duck', 3, 6)]):
        basket_total(u, 'MATH-B-02', obj, a, b, b, i, difficulty=0.6)

    # ---- MATH-B-03: number sentences
    u.skill('MATH-B-03', 'קוראים תרגילים', 'קוֹרְאִים תַּרְגִּילִים עִם פְּלוּס וּמִינוּס', 'stall', ['MATH-B-01', 'NUM-A-08'], ['symbolic'],
            ['M-EQ-OPER'], core=True)
    for i, (x, op, y) in enumerate([(3, '+', 4), (5, '+', 2), (6, '+', 3), (2, '+', 7), (7, '-', 3), (9, '-', 4), (8, '-', 5), (10, '-', 6)]):
        r = x + y if op == '+' else x - y
        word = 'וְעוֹד' if op == '+' else 'פָּחוֹת'
        opcell = 'op:+' if op == '+' else 'op:-'
        # B-15 §3: the larger addend or the start alone (M-CNT-CARD, untagged until it has a line of its own: the shared
        # one is the give-N line), and a count on or back that counts the start too
        near = r - 1 if op == '+' else r + 1
        others = [max(x, y) if op == '+' else x, near]
        u.act('MATH-B-03', 'pick', prompt='%s %s %s. כַּמָּה זֶה?' % (F[x], word, F[y]),
              row=['n:%d' % x, opcell, 'n:%d' % y, 'op:=', '?'], options=tri('n:%d' % r, i, ['n:%d' % o for o in others]),
              correct='n:%d' % r, tags={'n:%d' % near: 'M-CNT-DOUBLE'}, correct_text='%s! %s %s %s שָׁוֶה %s.' % (F[r], F[x], word, F[y], F[r]),
              h3='%s %s %s: %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (F[x], word, F[y], count_words(r), F[r]))
    for x, op, y, r, bad, w in [(3, '+', 4, 7, 8, 4), (6, '+', 2, 8, 9, 4), (9, '-', 4, 5, 6, 4), (7, '-', 2, 5, 4, 4)]:
        cells = ['n:%d' % x, 'op:' + op, 'n:%d' % y, 'op:=', 'n:%d' % bad]
        u.act('MATH-B-03', 'spot', cells=cells, wrong=w, tag='M-EQ-OPER',
              prompt='חָבֵר כָּתַב תַּרְגִּיל, וְהַתְּשׁוּבָה לֹא נְכוֹנָה. אֵיפֹה הַטָּעוּת?',
              h3='%s %s %s שָׁוֶה %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַתְּשׁוּבָה הַלֹּא נְכוֹנָה.' % (F[x], 'וְעוֹד' if op == '+' else 'פָּחוֹת', F[y], F[r]),
              correct_text='כֵּן! %s %s %s שָׁוֶה %s.' % (F[x], 'וְעוֹד' if op == '+' else 'פָּחוֹת', F[y], F[r]))

    # B-15 §1: the sum on the number line (a second representation), and the answer written first (H25)
    for start, hop in ((5, 2), (3, 6)):
        jump_item(u, 'MATH-B-03', start, hop, difficulty=0.5)
    for i, (x, op, y) in enumerate([(3, '+', 4), (9, '-', 4)]):
        r = x + y if op == '+' else x - y
        word = 'וְעוֹד' if op == '+' else 'פָּחוֹת'
        numpick3(u, 'MATH-B-03', 'כַּמָּה שָׁוֶה %s %s %s?' % (F[x], word, F[y]), r,
                 {max(x, y) if op == '+' else x: None, r - 1 if op == '+' else r + 1: 'M-CNT-DOUBLE'}, i, check='reverse', difficulty=0.6,
                 row=['?', 'op:=', 'n:%d' % x, 'op:' + op, 'n:%d' % y], correct_text='%s! %s %s %s שָׁוֶה %s.' % (F[r], F[x], word, F[y], F[r]),
                 h3='%s %s %s: %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (F[x], word, F[y], count_words(r), F[r]))

    # ---- MATH-B-06: make ten
    u.skill('MATH-B-06', 'משלימים לעשר', 'מַשְׁלִימִים לְעֶשֶׂר', 'dock', ['MATH-B-02'], ['concrete', 'symbolic'], [])
    for i, n in enumerate([5, 7, 8, 6, 9, 4, 3, 2]):
        obj = ['apple', 'star', 'fish', 'duck', 'ladybug', 'bird', 'apple', 'star'][i]
        # B-15 §3: the whole (ten), and the number already there (M-CNT-CARD, untagged as in MATH-B-03); for five, one more
        others = {10: 'M-PART-MISS', n: None} if n != 5 else {10: 'M-PART-MISS', 6: 'M-CNT-DOUBLE'}
        numpick(u, 'MATH-B-06', 'יֵשׁ %s. כַּמָּה צָרִיךְ לְהוֹסִיף כְּדֵי שֶׁיִּהְיֶה עֶשֶׂר?' % qty(n, OBJECTS[obj]), 10 - n,
                list(others), i, tags={k: v for k, v in others.items() if v},
                group={'sprite': obj, 'count': n, 'arrangement': 'ten_frame' if i % 2 == 0 else 'line'},
                text='%s! %s וְעוֹד %s הֵם עֶשֶׂר.' % (F[10 - n], F[n], F[10 - n]),
                h3='%s, וְעוֹד %s: %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (F[n], F[10 - n], count_words(10), F[10 - n]))

    # B-15 §1 (H26): the same question with shekels (the transfer)
    for i, n in enumerate((7, 6)):
        numpick3(u, 'MATH-B-06', 'יֵשׁ לָנוּ %s. כַּמָּה עוֹד צָרִיךְ כְּדֵי שֶׁיִּהְיוּ לָנוּ עֲשָׂרָה שְׁקָלִים?' % qty(n, SHEKEL), 10 - n,
                 {10: 'M-PART-MISS', n: None}, i, check='transfer', difficulty=0.6, group={'sprite': 'coin_s1', 'count': n},
                 correct_text='%s! %s וְעוֹד %s הֵם עֶשֶׂר.' % (F[10 - n], F[n], F[10 - n]),
                 h3='%s, וְעוֹד %s: %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (F[n], F[10 - n], count_words(10), F[10 - n]))

    # ---- MATH-B-07: zero in sums
    u.skill('MATH-B-07', 'אפס בחיבור ובחיסור', 'אֶפֶס לֹא מְשַׁנֶּה', 'dock', ['MATH-B-03', 'NUM-A-14'], ['symbolic'], ['M-NUM-ZERO'])
    for i, (x, op, y) in enumerate([(5, '+', 0), (0, '+', 4), (7, '-', 0), (3, '-', 3), (6, '-', 6), (0, '+', 0)]):
        r = x + y if op == '+' else x - y
        word = 'וְעוֹד' if op == '+' else 'פָּחוֹת'
        # B-15 §3: refusing zero (1) and, for n - n, n (M-CNT-CARD, untagged as in MATH-B-03); on n + 0, 0 + n and n - 0
        # the traps are 0 and the neighbour, both the zero misconception; on 0 + 0, 1 and 2
        if r == 0:
            others = {1: 'M-NUM-ZERO', 2: 'M-NUM-ZERO'} if x == 0 else {1: 'M-NUM-ZERO', x: None}
        else:
            others = {0: 'M-NUM-ZERO', r + 1 if op == '+' else r - 1: 'M-NUM-ZERO'}
        numpick(u, 'MATH-B-07', '%s %s %s. כַּמָּה זֶה?' % (F[x], word, F[y]), r, list(others), i,
                tags={k: v for k, v in others.items() if v}, text='%s! %s %s %s שָׁוֶה %s.' % (F[r], F[x], word, F[y], F[r]), row=['n:%d' % x, 'op:' + op, 'n:%d' % y, 'op:=', '?'])

    # B-15 §1: the reverse (zero is what is missing); X3a and X3b instead of the hints that count on from the number
    for i, n in enumerate((6, 4)):
        numpick3(u, 'MATH-B-07', '%s וְעוֹד כַּמָּה שָׁוֶה %s?' % (F[n], F[n]), 0, {n: 'M-EQ-OPER', 2 * n: 'M-PART-MISS'}, i, check='reverse',
                 difficulty=0.6, row=['n:%d' % n, 'op:+', '?', 'op:=', 'n:%d' % n], tag_lines=part_miss_line(n, n),
                 correct_text='%s! %s וְעוֹד %s שָׁוֶה %s.' % (F[0], F[n], F[0], F[n]),
                 h2='%s כְּבָר יֵשׁ. כַּמָּה צָרִיךְ לְהוֹסִיף כְּדֵי לְהַגִּיעַ %s?' % (F[n], prefix('ל', F[n])),
                 h3='%s כְּבָר יֵשׁ, אָז לֹא מוֹסִיפִים כְּלוּם. אֵין כְּלוּם — זֶה אֶפֶס. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל אֶפֶס.' % F[n])

    # ---- MATH-B-08: within twenty
    u.skill('MATH-B-08', 'מחברים ומחסרים עד 20', 'מְחַבְּרִים עַד עֶשְׂרִים', 'dock', ['MATH-B-06', 'NUM-B-16'], ['symbolic', 'concrete'],
            ['M-ADD-RECOUNT'])
    for i, (x, y) in enumerate([(8, 5), (9, 4), (7, 6), (8, 7), (9, 6), (6, 9), (7, 8), (9, 9)]):
        r = x + y
        # B-15 §3 as MATH-B-03: the larger addend or the start (untagged), and counting the start too
        numpick(u, 'MATH-B-08', '%s וְעוֹד %s. כַּמָּה זֶה?' % (F[x], F[y]), r, [max(x, y), r - 1], i, tags={r - 1: 'M-CNT-DOUBLE'}, row=['n:%d' % x, 'op:+', 'n:%d' % y, 'op:=', '?'],
                text='%s! %s וְעוֹד %s הֵם עֶשֶׂר, וְעוֹד %s.' % (F[r], F[x], F[10 - x], F[r - 10]),
                h3='%s וְעוֹד %s הֵם עֶשֶׂר. נִשְׁאָר עוֹד %s, אָז %s. עַכְשָׁו תּוֹרְכֶם.' % (F[x], F[10 - x], F[y - (10 - x)], F[r]))
    for i, (x, y) in enumerate([(13, 4), (15, 3), (12, 5), (17, 2)]):
        r = x - y
        numpick(u, 'MATH-B-08', '%s פָּחוֹת %s. כַּמָּה זֶה?' % (F[x], F[y]), r, [x, r + 1], i, tags={r + 1: 'M-CNT-DOUBLE'}, row=['n:%d' % x, 'op:-', 'n:%d' % y, 'op:=', '?'],
                text='%s! %s פָּחוֹת %s שָׁוֶה %s.' % (F[r], F[x], F[y], F[r]))

    # B-15 §1: the missing addend when the sum reaches past ten
    for i, (x, total) in enumerate([(8, 13), (9, 15)]):
        missing_addend(u, 'MATH-B-08', x, total, i, check='reverse', difficulty=0.6)

    # ---- MATH-B-09: equals means the same as
    u.skill('MATH-B-09', '"שווה" זה אותו דבר', 'שְׁנֵי הַצְּדָדִים אוֹתוֹ דָּבָר', 'dock', ['MATH-B-03'], ['concrete', 'symbolic'], ['M-EQ-OPER'])
    for i, (la, lb, ra, rb) in enumerate([(3, 4, 5, 2), (2, 5, 4, 3), (6, 1, 3, 4), (4, 4, 5, 3)]):
        u.act('MATH-B-09', 'scale', mode='compare', hideTilt=True, left=[('apple', la), ('star', lb)], right=[('fish', ra), ('duck', rb)],
              result='same', tag='M-EQ-OPER',
              prompt='%s וְעוֹד %s, מוּל %s וְעוֹד %s. מָה אוֹמְרִים הַמֹּאזְנַיִם?' % (F[la], F[lb], F[ra], F[rb]),
              h3='%s וְעוֹד %s הֵם %s. וְגַם %s וְעוֹד %s הֵם %s. שְׁנֵי הַצְּדָדִים שָׁוִים.' % (F[la], F[lb], F[la + lb], F[ra], F[rb], F[ra + rb]),
              correct_text='כֵּן! שְׁנֵי הַצְּדָדִים שָׁוִים: %s שָׁוֶה %s.' % (F[la + lb], F[ra + rb]))
    for i, (la, lb, ra, rb, res) in enumerate([(5, 4, 3, 2, 'left'), (2, 2, 4, 3, 'right'), (6, 3, 2, 4, 'left'), (1, 3, 3, 3, 'right')]):
        u.act('MATH-B-09', 'scale', mode='compare', hideTilt=True, left=[('apple', la), ('star', lb)], right=[('fish', ra), ('duck', rb)],
              result=res, tag='M-EQ-OPER',
              prompt='%s וְעוֹד %s, מוּל %s וְעוֹד %s. אֵיזֶה צַד כָּבֵד יוֹתֵר?' % (F[la], F[lb], F[ra], F[rb]),
              h3='%s וְעוֹד %s הֵם %s, %s וְעוֹד %s הֵם %s. הַצַּד שֶׁיֵּשׁ בּוֹ יוֹתֵר כָּבֵד יוֹתֵר.' % (F[la], F[lb], F[la + lb], vav(F[ra]), F[rb], F[ra + rb]),
              correct_text='כֵּן! %s בְּצַד אֶחָד, %s בַּצַּד הַשֵּׁנִי.' % (F[la + lb], F[ra + rb]))
    for i, (x, y, z) in enumerate([(3, 4, 7), (5, 2, 7), (6, 3, 9), (4, 5, 9)]):
        u.act('MATH-B-09', 'spot', cells=['n:%d' % z, 'op:=', 'n:%d' % x, 'op:+', 'n:%d' % (y + 1)], wrong=4, tag='M-EQ-OPER',
              prompt='חָבֵר כָּתַב מִסְפָּרִים, וְאֶחָד מֵהֶם לֹא מַתְאִים. אֵיפֹה הַטָּעוּת?',
              h3='%s שָׁוֶה %s וְעוֹד %s. עַכְשָׁו תּוֹרְכֶם.' % (F[z], F[x], F[y]), correct_text='כֵּן! %s שָׁוֶה %s וְעוֹד %s.' % (F[z], F[x], F[y]))

    # ---- MATH-B-10: equal groups
    u.skill('MATH-B-10', 'קבוצות שוות', 'קְבוּצוֹת עִם אוֹתוֹ מִסְפָּר', 'stall', ['MATH-A-03'], ['concrete', 'pictorial'], ['M-SHARE-UNEQ'])
    for i, (g, per, obj) in enumerate([(2, 3, 'apple'), (3, 2, 'fish'), (2, 4, 'star'), (3, 3, 'duck'), (4, 2, 'ladybug'), (2, 5, 'bird')]):
        o = OBJECTS[obj]
        r = g * per
        # G5 (B-15): one chart column per plate. Options (§3): one plate (M-CNT-CARD) and the groups added to the size
        # (M-MUL-ADD, not in the pack), both untagged until they have lines
        numpick(u, 'MATH-B-10', 'יֵשׁ %s. עַל כׇּל צַלַּחַת %s. כַּמָּה יֵשׁ בְּסַךְ הַכֹּל?' % (qty(g, PLATE), qty(per, o)), r,
                [per, g + per], i, chart=[[obj, per]] * g,
                text='%s! %s הֵם %s.' % (F[r], ' וְעוֹד '.join(F[per] for _ in range(g)), F[r]),
                h3='%s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (' וְעוֹד '.join(F[per] for _ in range(g)), F[r]))

    # B-15 §1 (H27, X6): how many plates?
    for i, (g, per, obj) in enumerate([(3, 2, 'duck'), (2, 4, 'bird')]):
        o = OBJECTS[obj]
        r = g * per
        numpick3(u, 'MATH-B-10', 'יֵשׁ %s. עַל כׇּל צַלַּחַת %s. כַּמָּה צַלָּחוֹת?' % (qty(r, o), qty(per, o)), g, {r: None, per: None}, i,
                 check='reverse', difficulty=0.6, chart=[[obj, per]] * g,
                 correct_text='%s! %s הֵם %s.' % (qty(g, PLATE), ' וְעוֹד '.join(F[per] for _ in range(g)), F[r]))

    # ---- MATH-B-13: weigh on the balance
    u.skill('MATH-B-13', 'שוקלים על מאזניים', 'מִי כָּבֵד יוֹתֵר', 'pool', ['MATH-A-04'], ['concrete'], ['M-MEAS-BIG'])
    for i, (ls, lc, rs, rc, res) in enumerate([('stone', 1, 'feather', 1, 'left'), ('feather', 2, 'stone', 1, 'right'), ('apple', 3, 'apple', 3, 'same'),
                                               ('block', 4, 'block', 2, 'left'), ('stone', 2, 'feather', 3, 'left'), ('block', 3, 'block', 5, 'right')]):
        weights = {'stone': 3, 'feather': 1, 'apple': 1, 'block': 1}
        lw, rw = weights[ls], weights[rs]
        n1 = NAMES.get(ls, {'one': 'תַּפּוּחַ', 'g': 'm'})['one']
        u.act('MATH-B-13', 'scale', mode='compare', left=[(ls, lc, lw)], right=[(rs, rc, rw)], result=res, tag='M-MEAS-BIG',
              prompt='אֵיזֶה צַד כָּבֵד יוֹתֵר? אוֹ שֶׁהֵם שָׁוִים?',
              h3='הַצַּד הַכָּבֵד יוֹרֵד לְמַטָּה. עַכְשָׁו תּוֹרְכֶם.', correct_text='כֵּן! הַצַּד הַזֶּה כָּבֵד יוֹתֵר.' if res != 'same' else 'כֵּן! שְׁנֵי הַצְּדָדִים שָׁוִים.')
    for i, (lc, rc) in enumerate([(5, 2), (6, 3), (4, 1), (7, 5)]):
        u.act('MATH-B-13', 'scale', mode='balance', left=[('block', lc, 1)], right=[('block', rc, 1)], block='block', result=lc - rc, tag='M-MEAS-BIG',
              # the balance sides (D12) are an owner draft (proposed): this prompt keeps its text until he approves it
              prompt='הַצַּד הַיְמָנִי קַל יוֹתֵר. מוֹסִיפִים קֻבִּיּוֹת עַד שֶׁהַמֹּאזְנַיִם שָׁווֹת.',
              h3='בַּצַּד הַשְּׂמָאלִי יֵשׁ %s, וּבַצַּד הַיְמָנִי %s. צָרִיךְ עוֹד %s.' % (qty(lc, NAMES['block'] | {'many': 'קֻבִּיּוֹת'}), qty(rc, NAMES['block'] | {'many': 'קֻבִּיּוֹת'}), qty(lc - rc, NAMES['block'] | {'many': 'קֻבִּיּוֹת'})),
              correct_text='כֵּן! הַמֹּאזְנַיִם מְאֻזָּנִים.')

    # B-15 §1 (H28): guess which side goes down, then see; the big light thing against a small heavy one
    for left, right, res in ((('balloon_red', 1, 1), ('stone', 1, 3), 'right'), (('key', 1, 2), ('balloon_blue', 1, 1), 'left')):
        u.act('MATH-B-13', 'scale', mode='compare', hideTilt=True, left=[left], right=[right], result=res, tag='M-MEAS-BIG',
              check='predict', difficulty=0.6, prompt='אֵיזֶה צַד יֵרֵד לְמַטָּה? קֹדֶם מְנַחֲשִׁים, וְאַחַר כָּךְ רוֹאִים.',
              h3='הַצַּד הַכָּבֵד יוֹרֵד לְמַטָּה. עַכְשָׁו תּוֹרְכֶם.', correct_text='כֵּן! הַצַּד הַזֶּה כָּבֵד יוֹתֵר.')

    # ---- MATH-B-14: days of the week
    u.skill('MATH-B-14', 'ימי השבוע', 'יוֹם רִאשׁוֹן, יוֹם שֵׁנִי…', 'dock', ['MATH-A-05'], ['pictorial', 'symbolic'], [])
    for i, (k, ask) in enumerate([(3, 'after'), (6, 'after'), (1, 'after'), (5, 'before'), (7, 'before'), (4, 'after'), (2, 'before')]):
        ans = k % 7 + 1 if ask == 'after' else (k - 2) % 7 + 1
        wrong = [x for x in (k, ans % 7 + 1 if ask == 'after' else (ans - 2) % 7 + 1) if x != ans]
        word = 'אַחֲרֵי' if ask == 'after' else 'לִפְנֵי'
        u.act('MATH-B-14', 'pick', prompt='מַה בָּא %s %s?' % (word, DAYS[k - 1]),
              options=tri('day_%d' % ans, i, ['day_%d' % w for w in wrong]), correct='day_%d' % ans, rep='symbolic',
              tags={'day_%d' % w: 'M-CNT-SEQ' for w in wrong}, correct_text='כֵּן! %s.' % DAYS[ans - 1], h3='%s, %s. עַכְשָׁו תּוֹרְכֶם.' % (DAYS[min(k, ans) - 1], DAYS[max(k, ans) - 1]) if abs(k - ans) == 1 else 'הַיָּמִים בַּסֵּדֶר: %s. עַכְשָׁו תּוֹרְכֶם.' % ', '.join(DAYS))
    for i, (k, ask) in enumerate([(3, 'tomorrow'), (5, 'tomorrow'), (2, 'yesterday'), (6, 'yesterday')]):
        base = {'tomorrow': 'מָחָר', 'yesterday': 'אֶתְמוֹל'}[ask]
        today = k
        ans = today % 7 + 1 if ask == 'tomorrow' else (today - 2) % 7 + 1
        wrong = [today, ans % 7 + 1] if ask == 'tomorrow' else [today, (ans - 2) % 7 + 1]
        u.act('MATH-B-14', 'pick', prompt='הַיּוֹם %s. מַה יִּהְיֶה %s?' % (DAYS[today - 1], base) if ask == 'tomorrow' else 'הַיּוֹם %s. מָה הָיָה %s?' % (DAYS[today - 1], base),
              options=tri('day_%d' % ans, i, ['day_%d' % w for w in wrong]), correct='day_%d' % ans, rep='symbolic',
              tags={'day_%d' % w: 'M-CNT-SEQ' for w in wrong}, **({'check': 'reverse'} if ask == 'yesterday' else {}),
              correct_text='כֵּן! %s %s.' % (base, DAYS[ans - 1]), h3='הַיּוֹם %s. עַכְשָׁו תּוֹרְכֶם.' % DAYS[today - 1])

    # ---- MATH-B-15: the clock, whole hours
    u.skill('MATH-B-15', 'קוראים שעון', 'קוֹרְאִים שָׁעוֹת עֲגֻלּוֹת', 'pool', ['NUM-B-08'], ['pictorial', 'symbolic'], ['M-CLOCK-HANDS'])
    for i, h in enumerate([3, 6, 9, 1, 4, 8, 11, 2, 5, 7]):
        wrong = [12, h + 1 if h < 11 else 2]
        numpick(u, 'MATH-B-15', 'מָה הַשָּׁעָה?', h, wrong, i, tags={12: 'M-CLOCK-HANDS'}, group={'sprite': 'clock_%d' % h, 'count': 1},
                text='כֵּן! הַשָּׁעָה %s.' % F[h], h3='הַמַּחֲוָג הַקָּצָר וְהָעָבֶה אוֹמֵר אֶת הַשָּׁעָה: %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (F[h], F[h]))

    # ---- MATH-B-18: the missing number
    u.skill('MATH-B-18', 'מוצאים מספר חסר', 'מוֹצְאִים אֶת הַמִּסְפָּר הֶחָסֵר', 'dock', ['MATH-B-02', 'MATH-B-03'], ['symbolic'], ['M-EQ-OPER'])
    for i, (x, total) in enumerate([(3, 7), (2, 6), (4, 9), (5, 8), (6, 10), (1, 5), (7, 9)]):
        missing_addend(u, 'MATH-B-18', x, total, i)

    # B-15 §1 (H31): the other way round, `7 = 3 + ?`
    for i, (x, total) in enumerate([(3, 7), (5, 9)]):
        missing_addend(u, 'MATH-B-18', x, total, i + 7, flipped=True, check='transfer', difficulty=0.6)

    # ---- lessons
    def ids(skill, a=0, b=None):
        return [x['id'] for x in u.d['activities'] if x['skill'] == skill][a:b]

    u.lesson('join-more', 'מוֹסִיפִים', ['MATH-B-01'], ids('MATH-B-01', 0, 6), 'כׇּל הַכָּבוֹד! הוֹסַפְתֶּם וְחִשַּׁבְתֶּם.')
    u.lesson('take-away-more', 'לוֹקְחִים', ['MATH-B-01'], ids('MATH-B-01', 6), 'יָפֶה מְאֹד! לְקַחְתֶּם וְחִשַּׁבְתֶּם.')
    u.lesson('missing-part', 'הַחֵלֶק שֶׁחָסֵר', ['MATH-B-02'], ids('MATH-B-02', 0, 6), 'כׇּל הַכָּבוֹד! מְצָאתֶם אֶת הַחֵלֶק.')
    u.lesson('missing-part-more', 'עוֹד חֲלָקִים', ['MATH-B-02'], ids('MATH-B-02', 6), 'מְצֻיָּן! הַכֹּל שָׁלֵם.')
    u.lesson('read-sums', 'קוֹרְאִים תַּרְגִּילִים', ['MATH-B-03'], ids('MATH-B-03', 0, 8), 'כׇּל הַכָּבוֹד! קְרָאתֶם תַּרְגִּילִים.')
    u.lesson('find-the-slip', 'מוֹצְאִים טָעוּת', ['MATH-B-03'], ids('MATH-B-03', 8), 'מְצֻיָּן! מְצָאתֶם אֶת הַטָּעוּת.')
    u.lesson('make-ten', 'מַשְׁלִימִים לְעֶשֶׂר', ['MATH-B-06'], ids('MATH-B-06', 0, 5), 'כׇּל הַכָּבוֹד! הִגַּעְתֶּם לְעֶשֶׂר.')
    u.lesson('make-ten-more', 'עוֹד עֶשֶׂר', ['MATH-B-06'], ids('MATH-B-06', 5), 'יָפֶה! עֶשֶׂר כׇּל פַּעַם.')
    u.lesson('zero-sums', 'אֶפֶס בַּתַּרְגִּילִים', ['MATH-B-07'], ids('MATH-B-07'), 'נִפְלָא! אֶפֶס לֹא מְשַׁנֶּה.')
    u.lesson('to-twenty', 'עַד עֶשְׂרִים', ['MATH-B-08'], ids('MATH-B-08', 0, 8), 'כׇּל הַכָּבוֹד! חִבַּרְתֶּם עַד עֶשְׂרִים.')
    u.lesson('to-twenty-more', 'עוֹד עַד עֶשְׂרִים', ['MATH-B-08'], ids('MATH-B-08', 8), 'מְצֻיָּן! גַּם חִסַּרְתֶּם.')
    u.lesson('equals-balance', 'שָׁוֶה זֶה אוֹתוֹ דָּבָר', ['MATH-B-09'], ids('MATH-B-09', 0, 8), 'כׇּל הַכָּבוֹד! שְׁנֵי הַצְּדָדִים שָׁוִים.')
    u.lesson('equals-slip', 'מוֹצְאִים אֶת הַטָּעוּת', ['MATH-B-09'], ids('MATH-B-09', 8), 'יָפֶה! הַצְּדָדִים מְאֻזָּנִים.')
    u.lesson('equal-groups', 'קְבוּצוֹת שָׁווֹת', ['MATH-B-10'], ids('MATH-B-10'), 'כׇּל הַכָּבוֹד! בְּכׇל צַלַּחַת אוֹתוֹ מִסְפָּר.')
    u.lesson('weigh-it', 'שׁוֹקְלִים', ['MATH-B-13'], ids('MATH-B-13', 0, 6), 'כׇּל הַכָּבוֹד! אַתֶּם יוֹדְעִים לִשְׁקֹל.')
    u.lesson('balance-it', 'מְאַזְּנִים', ['MATH-B-13'], ids('MATH-B-13', 6), 'יָפֶה מְאֹד! הַמֹּאזְנַיִם מְאֻזָּנִים.')
    u.lesson('days-of-the-week', 'יְמֵי הַשָּׁבוּעַ', ['MATH-B-14'], ids('MATH-B-14'), 'כׇּל הַכָּבוֹד! אַתֶּם מַכִּירִים אֶת הַיָּמִים.')
    u.lesson('what-time', 'מָה הַשָּׁעָה', ['MATH-B-15'], ids('MATH-B-15', 0, 5), 'כׇּל הַכָּבוֹד! קְרָאתֶם שָׁעוֹן.')
    u.lesson('what-time-more', 'עוֹד שָׁעוֹת', ['MATH-B-15'], ids('MATH-B-15', 5), 'מְצֻיָּן! הַמַּחֲוָג הַקָּצָר אוֹמֵר אֶת הַשָּׁעָה.')
    u.lesson('missing-number', 'הַמִּסְפָּר הֶחָסֵר', ['MATH-B-18'], ids('MATH-B-18'), 'נִפְלָא! מְצָאתֶם אֶת הַמִּסְפָּר.')
    u.save()


if __name__ == '__main__':
    # one module for every part (band_b2 and band_b3 import "band_b", not "__main__"), so the units share SHARED_FB and MADE
    import band_b
    import band_b2
    import band_b3
    band_b.numbers()
    band_b.math()
    band_b2.run()
    band_b3.run()
    band_b.write_all()
