"""The Maths Teacher's checker: recomputes every maths activity of the pack from the item's own data (M10 step 0.5).

    python -I tools/check_maths.py                 # every maths item of content/starter
    python -I tools/check_maths.py --band C --strict   # the gate of a Band C batch (ambiguous or unchecked items fail too)
    python -I tools/check_maths.py --list          # also print every finding, not only the table
    python -I tools/check_maths.py --dir <folder>  # another folder of activity.*.json (a next-pack, a test)

The lands: Counting Hills (numbers), Market (math), Shapes, Logic, and Colour Bay where the answer follows a rule.
For every item it checks, in this order (docs/milestones/M10.md, acceptance 3 and 4; docs/curriculum.md §5.2 and §5.3):

1. the marked answer, recomputed from the item's own numbers, sprites and caption, is right;
2. no other option is also right (a second right answer), and no option is right by an inclusive definition (a square is a
   rectangle) while the item marks it wrong;
3. every distractor carries a misconception tag where §5.3 needs one (3 or more options: two tagged with distinct tags, or the
   same tag when the skill watches one tag; a random one only from 4 options; 2 options: the distractor is tagged); every
   tag is in the catalogue or has a misconception record; a numeric tag reproduces its distractor (M-CNT-DOUBLE = n+1 or n+2,
   M-SUB-SMALLBIG(52, 27) = 35 and so on);
4. the numbers stay in the skill's range (curriculum §4) and the options in the band's limit (PLAN.md: 3, 4, 5);
5. the picture matches the item: the caption's numbers are the counts drawn, a spoken option label names the number, colour,
   shape, tower or day that its picture shows, and a shape's drawn sides are the sides the item counts;
6. left-to-right maths is not mirrored: a number sentence is true read left to right, a number line runs from small to big,
   and the app's renderers keep their left-to-right isolates.

Severities: WRONG (wrong content: a wrong answer, a second right answer, a picture or label that says another number) >
RULE (a tag rule, the range, the band's option limit) > AMBIG (the child could fairly read the item another way) > NOTE.
An item no rule here understands is UNCHECKED. The exit code is 1 when there is a WRONG or a RULE finding (with --strict
also an AMBIG or UNCHECKED one), else 0. Python 3 standard library only.
"""
import argparse
import glob
import json
import os
import re
import sys
from collections import Counter, defaultdict
from itertools import permutations

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(TOOLS, '..'))
STARTER = os.path.join(ROOT, 'content', 'starter')
CURRICULUM = os.path.join(ROOT, 'docs', 'curriculum.md')

MATHS_DOMAINS = ('numbers', 'math', 'shapes', 'logic', 'colors')
SEVERITIES = ('WRONG', 'RULE', 'AMBIG', 'NOTE', 'UNCHECKED')
FAILING = ('WRONG', 'RULE')
STRICT_FAILING = ('WRONG', 'RULE', 'AMBIG', 'UNCHECKED')

# PLAN.md › Learners & age bands: choices on screen.
BAND_OPTIONS = {'A': 3, 'B': 4, 'C': 5}
# The biggest number a band's items use, and the skill ranges of curriculum §4 where a skill says less or more.
BAND_MAX = {'A': 10, 'B': 20, 'C': 10000}
SKILL_MAX = {
    'NUM-A-01': 5, 'NUM-A-03': 5, 'NUM-A-04': 5, 'NUM-A-05': 3, 'NUM-A-06': 5, 'NUM-A-07': 5, 'NUM-A-08': 5,
    'NUM-A-10': 5, 'NUM-A-11': 5, 'NUM-A-14': 5,
    'NUM-B-02': 30, 'NUM-B-03': 10, 'NUM-B-06': 10, 'NUM-B-07': 10, 'NUM-B-09': 10, 'NUM-B-10': 10, 'NUM-B-11': 20,
    'NUM-B-13': 20, 'NUM-B-14': 10, 'NUM-B-17': 100,
    'MATH-A-01': 5, 'MATH-A-02': 5, 'MATH-A-03': 6, 'MATH-A-06': 5,
    'MATH-B-01': 10, 'MATH-B-02': 10, 'MATH-B-03': 10, 'MATH-B-06': 10, 'MATH-B-07': 10, 'MATH-B-09': 10,
    'MATH-B-17': 12, 'MATH-B-18': 10,
    # M10 batch C1: numbers to 100, facts to 9 + 9 (an option may name a bigger number: 203 for "twenty-three" written as heard)
    'NUM-C-01': 100, 'NUM-C-02': 100, 'NUM-C-03': 100, 'NUM-C-04': 100, 'NUM-C-06': 100, 'NUM-C-09': 100,
    'MATH-C-01': 18, 'MATH-C-02': 18, 'MATH-C-03': 100,
}

# ---------------------------------------------------------------- Hebrew


def plain(text):
    """The text without nikud and cantillation (a maqaf becomes a space)."""
    return re.sub('[֑-ֽֿ-ׇ]', '', (text or '').replace('־', ' '))


def tokens(text):
    return re.findall('[א-ת]+', plain(text))


UNITS = {
    'אפס': 0, 'אחת': 1, 'אחד': 1, 'שתים': 2, 'שתיים': 2, 'שנים': 2, 'שניים': 2, 'שני': 2, 'שתי': 2,
    'שלוש': 3, 'שלש': 3, 'שלושה': 3, 'שלשה': 3, 'ארבע': 4, 'ארבעה': 4, 'חמש': 5, 'חמשה': 5, 'חמישה': 5,
    'שש': 6, 'ששה': 6, 'שישה': 6, 'שבע': 7, 'שבעה': 7, 'שמונה': 8, 'תשע': 9, 'תשעה': 9,
}
TEN = {'עשר', 'עשרה'}
TENS = {'עשרים': 20, 'שלושים': 30, 'שלשים': 30, 'ארבעים': 40, 'חמישים': 50, 'חמשים': 50, 'שישים': 60, 'ששים': 60,
        'שבעים': 70, 'שמונים': 80, 'תשעים': 90, 'מאה': 100}


def _num_word(tok):
    """(value, kind) of one number word, with or without a leading ו; kind is unit, ten or tens."""
    for t, vav in ((tok, False), (tok[1:], True) if tok.startswith('ו') and len(tok) > 2 else (None, None)):
        if t is None:
            continue
        if t in UNITS:
            return UNITS[t], 'unit', vav
        if t in TEN:
            return 10, 'ten', vav
        if t in TENS:
            return TENS[t], 'tens', vav
    return None


def numbers(text):
    """The numbers a Hebrew sentence says, in order: שְׁלֹשׁ עֶשְׂרֵה = 13, עֶשְׂרִים וְאַרְבַּע = 24, תַּפּוּחַ אֶחָד = 1."""
    out = []
    for part in re.split(r'[,.?!:;—–…]', plain(text)):
        out += _numbers(tokens(part))
    return out


def _group(toks, i):
    """(value, next index) of the number of up to two words at toks[i] (a number word): 13, 24, 30, 7."""
    value, kind, _ = _num_word(toks[i])
    nxt = _num_word(toks[i + 1]) if i + 1 < len(toks) else None
    if kind == 'unit' and value > 0 and nxt and nxt[1] == 'ten' and not nxt[2]:
        return value + 10, i + 2
    if kind == 'tens' and value < 100 and nxt and nxt[1] == 'unit' and nxt[2]:
        return value + nxt[0], i + 2
    return value, i + 1


HUNDRED_WORDS = {'מאות', 'מאת'}


def _numbers(toks):
    """The numbers of a list of words, hundreds too (M10 C1): שְׁלֹשׁ מֵאוֹת וְאַרְבַּע = 304, מָאתַיִם = 200, מֵאָה וְעֶשְׂרִים = 120."""
    out = []
    i = 0
    while i < len(toks):
        t = toks[i][1:] if toks[i].startswith('ו') and len(toks[i]) > 2 else toks[i]
        w = _num_word(toks[i])
        hundreds = None
        if t == 'מאתים':
            hundreds, j = 200, i + 1
        elif w and w[1] == 'unit' and w[0] > 0 and i + 1 < len(toks) and toks[i + 1] in HUNDRED_WORDS:
            hundreds, j = w[0] * 100, i + 2
        elif t == 'מאה':
            hundreds, j = 100, i + 1
        if hundreds is not None:
            # the rest of the number: a vav-joined part (וְאַרְבַּע, וְעֶשְׂרִים), or tens with the vav on their ones (אַרְבָּעִים וְחָמֵשׁ)
            if j < len(toks) and _num_word(toks[j]):
                nw = _num_word(toks[j])
                rest, k = _group(toks, j)
                if nw[2] or (nw[1] == 'tens' and k == j + 2):
                    out.append(hundreds + rest)
                    i = k
                    continue
            out.append(hundreds)
            i = j
            continue
        if w is None:
            i += 1
            continue
        value, i = _group(toks, i)
        out.append(value)
    return out


COLOUR_WORDS = {
    'red': ('אדם', 'אדמה', 'אדמים', 'אדמות'), 'blue': ('כחל', 'כחלה', 'כחלים', 'כחלות'),
    'yellow': ('צהב', 'צהבה', 'צהבים', 'צהבות'), 'green': ('ירק', 'ירקה', 'ירקים', 'ירקות'),
    'orange': ('כתם', 'כתמה', 'כתמים', 'כתמות'), 'purple': ('סגל', 'סגלה', 'סגלים'),
    'pink': ('ורד', 'ורדה', 'ורדים'), 'black': ('שחר', 'שחרה', 'שחרים'), 'white': ('לבן', 'לבנה', 'לבנים'),
    'brown': ('חום', 'חומה', 'חומים'), 'grey': ('אפר', 'אפרה', 'אפרים'),
}
SHAPE_WORDS = {
    'circle': ('עגול', 'עגולים'), 'square': ('רבוע', 'רבועים'), 'triangle': ('משלש', 'משלשים'),
    'rect': ('מלבן', 'מלבנים'), 'quad': ('מרבע', 'מרבעים'), 'pentagon': ('מחמש', 'מחמשים'), 'hexagon': ('מששה',),
}
SOLID_WORDS = {'cylinder': ('גליל', 'גלילים'), 'cone': ('חרוט',), 'pyramid': ('פירמידה',), 'box': ('תבה', 'קפסה'),
               'cube': ('קביה',), 'sphere': ('כדור',)}
KIND_WORDS = {'ball': ('כדור', 'כדורים'), 'balloon': ('בלון', 'בלונים'), 'bloom': ('פרח', 'פרחים'),
              'banana': ('בננה',), 'apple': ('תפוח', 'תפוחים'), 'fish': ('דג', 'דגים'), 'duck': ('ברוז', 'ברוזים'),
              'cat': ('חתול', 'חתולים'), 'dog': ('כלב', 'כלבים'), 'star': ('כוכב', 'כוכבים'), 'shape': ('צורה',)}
DAY_WORDS = {'ראשון': 1, 'שני': 2, 'שלישי': 3, 'רביעי': 4, 'חמישי': 5, 'ששי': 6, 'שישי': 6, 'שבת': 7}
TIME_WORDS = {'בקר': 'morning', 'צהרים': 'noon', 'ערב': 'evening', 'לילה': 'night'}
TIME_ORDER = ['morning', 'noon', 'evening', 'night']
POS_WORDS = {'על': 'on', 'מתחת': 'under', 'בתוך': 'in', 'ליד': 'next', 'מעל': 'above'}


def _find(words, table):
    """The keys of [table] whose words appear in [words] (one prefix ה, ו, ב or ל is allowed), in order of appearance."""
    out = []
    for w in words:
        for cand in (w, w[1:] if len(w) > 2 and w[0] in 'הובל' else None):
            hit = next((k for k, vs in table.items() if cand in vs), None) if cand else None
            if hit:
                out.append(hit)
                break
    return out


def colours_in(text):
    return _find(tokens(text), COLOUR_WORDS)


def shapes_in(text):
    return _find(tokens(text), SHAPE_WORDS)


# ---------------------------------------------------------------- sprites

COLOURS = ('red', 'blue', 'yellow', 'green', 'orange', 'purple', 'pink', 'black', 'white', 'brown', 'grey')
RAINBOW = ['red', 'orange', 'yellow', 'green', 'blue', 'purple']
MIX = {frozenset(('red', 'yellow')): 'orange', frozenset(('blue', 'yellow')): 'green',
       frozenset(('red', 'blue')): 'purple'}
SIDES = {'triangle': 3, 'square': 4, 'rect': 4, 'quad': 4, 'pentagon': 5, 'hexagon': 6}
POLYGONS = set(SIDES)
COINS = {'a10': 0.1, 'h50': 0.5, 's1': 1, 's2': 2, 's5': 5, 's10': 10}
SIZE_RANK = {'s': 1, 'm': 2, 'l': 3}
# Plain objects whose colour every child knows from the picture.
OBJECT_COLOUR = {'apple': 'red', 'sun': 'yellow', 'grass': 'green', 'banana_yellow': 'yellow'}
WORLD_SHAPE = {'window': 'rect', 'plate': 'circle', 'sign': 'triangle'}
PAIRS = {'plate': {'spoon'}, 'bowl': {'spoon'}, 'brush': {'paste'}, 'sock': {'shoe'}, 'shoe': {'sock'},
         'key': {'lock'}, 'lock': {'key'}, 'pencil': {'paper'}, 'cloud': {'rain'}}
STORIES = [['egg', 'egg_crack', 'chick'], ['plant_seed', 'plant_sprout', 'plant_flower'], ['cloud', 'rain', 'rainbow']]
ROLLS = {'sphere', 'cylinder', 'cone', 'ball'}
STACKS = {'box', 'cube', 'cylinder'}
STAYS = {'box', 'cube'}
CIRCLE_FACE = {'cylinder', 'cone'}
FACES = {'cylinder': {'circle'}, 'cone': {'circle'}, 'pyramid': {'triangle', 'square'}, 'box': {'rect', 'square'},
         'cube': {'square'}, 'sphere': set()}
HEAVY = {'stone': 3, 'feather': 1, 'balloon': 1}


def sprite_info(s):
    """What a sprite shows, read from its asset name: kind, colour, shape, solid, size, n (a tower, a shade, a clock, a day)."""
    if isinstance(s, dict):
        s = s.get('sprite', '')
    n = (s or '')[6:] if (s or '').startswith('asset:') else (s or '')
    info = {'name': n, 'kind': n}
    m = re.fullmatch(r'shape_(circle|square|triangle|rect|pentagon|hexagon|quad|open|curved)(?:_(\w+))?', n)
    if m:
        info.update(kind='shape', shape=m[1])
        if m[2] in COLOURS:
            info['colour'] = m[2]
        elif m[2]:
            info['variant'] = m[2]
        return info
    m = re.fullmatch(r'(ball|balloon|bloom|banana|flower)_(\w+)', n)
    if m and m[2] in COLOURS:
        info.update(kind={'flower': 'bloom'}.get(m[1], m[1]), colour=m[2])
        return info
    m = re.fullmatch(r'(\w+?)_size_([sml])', n)
    if m:
        info.update(kind=m[1], size=SIZE_RANK[m[2]])
        return info
    m = re.fullmatch(r'(tower|day|clock)_(\d+)', n)
    if m:
        info.update(kind=m[1], n=int(m[2]))
        return info
    m = re.fullmatch(r'shade_(\w+)_(\d)', n)
    if m:
        info.update(kind='shade', colour=m[1], n=int(m[2]))
        return info
    m = re.fullmatch(r'solid_(\w+)', n)
    if m:
        info.update(kind='solid', solid=m[1])
        return info
    m = re.fullmatch(r'coin_(\w+)', n)
    if m:
        info.update(kind='coin', value=COINS.get(m[1]))
        return info
    m = re.fullmatch(r'note_(\d+)', n)
    if m:
        info.update(kind='note', value=int(m[1]))
        return info
    m = re.fullmatch(r'time_(\w+)', n)
    if m:
        info.update(kind='time', time=m[1])
        return info
    m = re.fullmatch(r'line_(straight|curved)(?:_\w+)?', n)
    if m:
        info.update(kind='line', line=m[1])
        return info
    m = re.fullmatch(r'stick_(long|short)', n)
    if m:
        info.update(kind='stick', size=3 if m[1] == 'long' else 1)
        return info
    m = re.fullmatch(r'pos_(\w+)', n)
    if m:
        info.update(kind='pos', pos=m[1])
        return info
    if n == 'apple_green':
        info.update(kind='apple', colour='green')
    elif n in OBJECT_COLOUR:
        info.update(kind={'banana_yellow': 'banana'}.get(n, n), colour=OBJECT_COLOUR[n])
    return info


class Svg:
    """The drawn geometry of a shape sprite: the corners of its outline (a polygon or a rect), from the SVG in the folder."""

    def __init__(self, folder):
        self.folder = folder
        self.cache = {}

    def corners(self, sprite):
        name = sprite_info(sprite)['name']
        if name in self.cache:
            return self.cache[name]
        path = os.path.join(self.folder, name + '.svg')
        pts = None
        if os.path.exists(path):
            with open(path, encoding='utf-8') as fh:
                src = fh.read()
            m = re.search(r'<polygon[^>]*points="([^"]+)"', src)
            if m:
                nums = [float(v) for v in re.findall(r'-?\d+(?:\.\d+)?', m[1])]
                pts = list(zip(nums[0::2], nums[1::2]))
            else:
                m = re.search(r'<rect[^>]*\swidth="([\d.]+)"[^>]*\sheight="([\d.]+)"', src)
                if m and '<circle' not in src:
                    w, h = float(m[1]), float(m[2])
                    pts = [(0, 0), (w, 0), (w, h), (0, h)]
        self.cache[name] = pts
        return pts

    def sides(self, sprite):
        pts = self.corners(sprite)
        if not pts:
            return None
        return [((pts[i][0] - pts[i - 1][0]) ** 2 + (pts[i][1] - pts[i - 1][1]) ** 2) ** 0.5 for i in range(len(pts))]


# ---------------------------------------------------------------- catalogue


def catalogue_tags(path=CURRICULUM):
    """The tags of the misconception catalogue, curriculum §5.2 (rows that start with `| M-`)."""
    if not os.path.exists(path):
        return set()
    with open(path, encoding='utf-8') as fh:
        return set(re.findall(r'^\| (M-[A-Z0-9-]+) \|', fh.read(), re.M))


def load(folder):
    items, records, skills = [], set(), {}
    for f in sorted(glob.glob(os.path.join(folder, '*.json'))):
        base = os.path.basename(f)
        try:
            with open(f, encoding='utf-8') as fh:
                doc = json.load(fh)
        except (OSError, ValueError):
            continue
        if base.startswith('misconception.'):
            records.add(doc.get('id'))
        elif base.startswith('skill.'):
            skills[doc.get('id')] = doc
        elif base.startswith('activity.') and isinstance(doc, dict):
            items.append(doc)
    return items, records, skills


# ---------------------------------------------------------------- the item


class Item:
    def __init__(self, doc):
        self.doc = doc
        self.id = doc.get('id', '?')
        self.template = doc.get('template')
        self.band = doc.get('band', 'B')
        self.domain = doc.get('domain')
        self.skill = (doc.get('skills') or [{}])[0].get('id', '')
        self.scene = doc.get('scene') or {}
        self.answer = doc.get('answer') or {}
        self.caption = ' '.join(c.get('v', '') for c in (doc.get('prompt') or {}).get('caption', []))
        self.cap = plain(self.caption)
        self.words = tokens(self.caption)
        self.options = self.answer.get('options') or []
        self.correct = self.answer.get('correct')

    def has(self, *phrases):
        return any(p in self.cap for p in phrases)

    def group(self, key='group'):
        g = self.scene.get(key)
        return g if isinstance(g, dict) else None


def opt_value(o):
    """The number an option shows (a numeral, a value or a set's count), else None."""
    for k in ('numeral', 'value'):
        if isinstance(o.get(k), (int, float)):
            return o[k]
    if isinstance(o.get('set'), dict):
        return o['set'].get('count')
    return None


def opt_info(o):
    if isinstance(o.get('set'), dict):
        info = sprite_info(o['set'].get('sprite'))
        if 'size' not in info and o['set'].get('scale') is not None:
            info['size'] = o['set']['scale']
        return info
    return sprite_info(o.get('sprite'))


class Findings:
    def __init__(self):
        self.rows = []

    def add(self, sev, item, code, msg):
        self.rows.append((sev, item.id if isinstance(item, Item) else item, code, msg))


# ---------------------------------------------------------------- arithmetic

OPS = {'+': lambda a, b: a + b, '-': lambda a, b: a - b, '−': lambda a, b: a - b, 'x': lambda a, b: a * b,
       '×': lambda a, b: a * b, ':': lambda a, b: a / b if b else None, '÷': lambda a, b: a / b if b else None}


def evaluate(toks):
    """The value of a list of numbers and operators, × and : before + and −; None when it cannot be computed."""
    if not toks or len(toks) % 2 == 0:
        return None
    vals = [toks[0]]
    ops = []
    for i in range(1, len(toks), 2):
        op, v = toks[i], toks[i + 1]
        if not isinstance(v, (int, float)) or op not in OPS:
            return None
        if op in 'x×:÷':
            r = OPS[op](vals[-1], v)
            if r is None:
                return None
            vals[-1] = r
        else:
            vals.append(v)
            ops.append(op)
    total = vals[0]
    for op, v in zip(ops, vals[1:]):
        total = OPS[op](total, v)
    return total


def parse_cells(cells):
    """A row or cells of `n:`/`op:`/`?` tokens as numbers, operator strings and None for the gap; None when not maths."""
    out = []
    for c in cells:
        if not isinstance(c, str):
            return None
        if c == '?':
            out.append(None)
        elif c.startswith('n:'):
            try:
                out.append(int(c[2:]))
            except ValueError:
                return None
        elif c.startswith('op:'):
            out.append(c[3:])
        else:
            return None
    return out


def equation_true(seq):
    if '=' not in seq:
        return None
    k = seq.index('=')
    left, right = evaluate(seq[:k]), evaluate(seq[k + 1:])
    if left is None or right is None:
        return None
    return abs(left - right) < 1e-9


RELATIONS = ('<', '>')


def relation_true(seq):
    """A number sentence with one relation (=, < or >), read left to right; None when it cannot be computed."""
    rels = [k for k, t in enumerate(seq) if t in ('=',) + RELATIONS]
    if len(rels) != 1:
        return None
    k = rels[0]
    left, right = evaluate(seq[:k]), evaluate(seq[k + 1:])
    if left is None or right is None:
        return None
    return {'=': abs(left - right) < 1e-9, '<': left < right, '>': left > right}[seq[k]]


def by_ones(n):
    """M-PV-FACE in a comparison: the number judged by its ones first (41 < 39, since 1 < 9)."""
    n = int(n)
    return (n % 10, n // 10)


def solve_gap(seq, top=1000):
    """Every whole number 0..top that makes the number sentence with one gap true."""
    gap = seq.index(None)
    return [v for v in range(0, top + 1) if equation_true(seq[:gap] + [v] + seq[gap + 1:])]


def smallbig(a, b):
    """M-SUB-SMALLBIG: the smaller digit from the larger in each column (52 − 27 = 35)."""
    da, db = str(a), str(b).rjust(len(str(a)), '0')
    if len(db) > len(da):
        return None
    return int(''.join(str(abs(int(x) - int(y))) for x, y in zip(da, db)))


def tag_candidates(tag, ctx):
    """The wrong values a tag's rule produces for an item (ctx: x the answer, a and b the numbers, op, whole); None: no rule."""
    x = ctx.get('x')
    a, b, op, whole = ctx.get('a'), ctx.get('b'), ctx.get('op'), ctx.get('whole')
    rel = ctx.get('relation')
    if rel is not None:  # a gap in an inequality: the values that each tag's way of reading the sentence accepts
        seq, gap = rel, rel.index(None)
        k = next(i for i, t in enumerate(seq) if t in RELATIONS)
        fill = lambda v: seq[:gap] + [v] + seq[gap + 1:]
        if tag == 'M-SIGN-DIR':  # the sign read the other way round
            flip = {'<': '>', '>': '<'}[seq[k]]
            return {v for v in range(0, 1001) if relation_true(fill(v)[:k] + [flip] + fill(v)[k + 1:])}
        if tag == 'M-PV-FACE' and len(seq) == 3 and k == 1:  # the two numbers compared by their ones first
            def face(v):
                left, right = by_ones(fill(v)[0]), by_ones(fill(v)[2])
                return left < right if seq[k] == '<' else left > right
            return {v for v in range(0, 1001) if face(v)}
        return None
    if x is None:
        return None
    cmp = ctx.get('compare')
    if cmp is not None and tag == 'M-PV-FACE':  # the biggest (or smallest) option judged by the ones first
        pick = max if ctx.get('want') == 'max' else min
        return {pick(cmp, key=by_ones)}
    given = [v for v in ctx.get('given', []) if isinstance(v, (int, float))]
    near = lambda *ds: {x + d for d in ds}
    if tag == 'M-CNT-DOUBLE':
        # in a number sentence with +, counting on that counts the start as one of the added (8 + 7: "8, 9, …, 14") gives one
        # less (M10 §4.2, MATH-C-01); in a join of two drawn sets one less is a miss (M-CNT-SKIP)
        return near(1, 2) | (near(-1) if op == '+' and ctx.get('sentence') else set())
    if tag == 'M-CNT-SKIP':
        return near(-1, -2)
    if tag in ('M-CNT-SEQ', 'M-CS-OFF1'):
        return near(1, -1, 2, -2) if tag == 'M-CNT-SEQ' else near(1, -1)
    if tag == 'M-CNT-DECADE':
        prev = ctx.get('prev', x - 1)
        return near(10, -10) | {prev // 10 * 10, prev - 9, prev + 1, (prev // 10) * 10 + 10 * 10}
    if tag in ('M-PART-MISS', 'M-PPW'):
        out = set(given)
        if len(given) >= 2:
            out.add(sum(given[:2]))
        if whole is not None:
            out.add(whole)
        return out
    if tag == 'M-EQ-OPER':
        out = set(given)
        if len(given) >= 2:
            out.add(sum(given))
            out.add(given[0] + given[-1])
        return out | near(1, -1)
    if tag == 'M-NUM-REV':
        if x >= 10:
            return {int(str(int(x))[::-1])}
        return None
    if tag == 'M-NUM-TEEN':
        out = set(given)
        if 10 < x < 20 or 10 <= ctx.get('whole', 0) < 20:
            out |= {ctx.get('whole', x), int('%d10' % (x % 10)) if x % 10 else 10}
        return out
    if tag == 'M-NUM-ZERO':
        return {0, 1} | near(1, -1) | set(given)
    if tag == 'M-CLOCK-HANDS':
        return {12}
    if tag == 'M-COMP-DIFF':
        return set(given)
    if tag == 'M-MONEY-COUNT':
        return {ctx['coins']} if 'coins' in ctx else None
    if tag == 'M-SUB-ORDER' and a is not None and b is not None:
        return {abs(a - b)}
    if tag == 'M-SUB-SMALLBIG' and a is not None and b is not None:
        r = smallbig(a, b)
        return {r} if r is not None else None
    if tag == 'M-REGROUP-FORGET':
        return near(-10, 10)
    if tag == 'M-MUL-ADD' and a is not None and b is not None:
        return {a + b}
    if tag == 'M-MUL-ZERO' and a is not None and b is not None:
        return {a, b} - {0}
    if tag == 'M-RULER-1':
        return near(1)
    if tag == 'M-PV-FACE' and x is not None:
        return {int(d) for d in str(int(x))}
    if tag == 'M-PV-ZERO':
        s = str(int(x))
        out = {int(s.replace('0', '') or 0), int(s + '0')}
        # the number written as it is heard, place by place: "twenty-three" as 20 and 3 = 203, 305 as 300 and 5 = 3005
        parts = [int(d) * 10 ** (len(s) - 1 - i) for i, d in enumerate(s) if d != '0']
        if len(parts) >= 2:
            out.add(int(''.join(str(p) for p in parts)))
        return out
    if tag == 'M-OOO-LTR' and ctx.get('ltr') is not None:
        return {ctx['ltr']}
    return None


# ---------------------------------------------------------------- the checks of a choice item


class Choice:
    """What a recogniser found: which options are right, and the context of the tag rules and the range."""

    def __init__(self, kind, right, ctx=None, nums=(), inclusive=None):
        self.kind = kind
        self.right = right  # option -> bool
        self.ctx = ctx or {}
        self.nums = list(nums)
        self.inclusive = inclusive  # option -> bool: right by an inclusive definition, though not what the item means


def numeric(kind, x, ctx=None, nums=()):
    c = dict(ctx or {})
    c['x'] = x
    return Choice(kind, lambda o: opt_value(o) is not None and abs(opt_value(o) - x) < 1e-9, c, list(nums) + [x])


def by_info(kind, pred, inclusive=None):
    return Choice(kind, lambda o: bool(pred(opt_info(o))), inclusive=(lambda o: bool(inclusive(opt_info(o))))
                  if inclusive else None)


def shape_member(info, shape, inclusive):
    """Whether a sprite is a [shape]; [inclusive]: a square is also a rectangle and a quadrilateral."""
    s = info.get('shape')
    if s is None:
        return False
    if s == shape:
        return True
    if shape == 'quad':
        return s in ('square', 'rect', 'quad')
    if inclusive and shape == 'rect':
        return s == 'square'
    return False


def seq_value(info):
    """The place of a sprite in a series: a size, a tower's height, a shade's darkness."""
    if 'size' in info:
        return info['size']
    if info.get('kind') in ('tower', 'shade'):
        return info.get('n')
    return None


def period_fill(row, gap):
    """The values the gap can take so that the row repeats with its shortest period (one value: not ambiguous)."""
    n = len(row)
    answers = []
    for p in range(1, n):
        core = [None] * p
        ok = True
        for i, v in enumerate(row):
            if i == gap:
                continue
            if core[i % p] is None:
                core[i % p] = v
            elif core[i % p] != v:
                ok = False
                break
        if not ok or core[gap % p] is None:
            continue
        # the pattern has to show its unit at least twice outside the gap
        if n < 2 * p:
            continue
        answers.append((p, core[gap % p]))
        break
    return answers


def periodic(row):
    n = len(row)
    for p in range(1, n // 2 + 1):
        if all(row[i] == row[i % p] for i in range(n)):
            return p
    return None


def recognise_choice(it, svg):
    """The recogniser of a choice item (tap_answer, count_tap, flash), or None."""
    cap, sc = it.cap, it.scene
    nums = numbers(it.caption)
    g, g2 = it.group(), it.group('group2')
    gc = g.get('count') if g else None
    g2c = g2.get('count') if g2 else None
    row = sc.get('row') if isinstance(sc.get('row'), list) else None
    seq = parse_cells(row) if row else None
    chart = sc.get('chart') if isinstance(sc.get('chart'), list) else None
    out = []  # picture findings: (severity, code, msg)

    def picture(expect, shown, what):
        if expect is not None and shown is not None and expect != shown:
            out.append(('WRONG', 'picture', '%s: the caption says %s, the picture shows %s' % (what, expect, shown)))

    # --- count_tap and flash: the count of the objects drawn
    if it.template in ('count_tap', 'flash'):
        obj = sc.get('objects') or sc.get('group') or {}
        n = obj.get('count')
        if it.has('מוסיפים עוד') and len(nums) >= 2:
            picture(nums[0] + nums[1], n, 'the objects')
            return numeric('story-sum-count', n, {'given': nums[:2]}, nums[:2]), out
        return numeric('count', n, {}, [n]), out

    # --- an inequality with a gap (M10 C1): every option is tried in the sentence, read left to right
    if seq and None in seq and any(t in RELATIONS for t in seq):
        given = [t for t in seq if isinstance(t, (int, float))]
        gap = seq.index(None)
        if nums and sorted(nums) != sorted(given):
            picture(sorted(nums), sorted(given), 'the numbers of the sentence')
        holds = lambda o: opt_value(o) is not None and relation_true(seq[:gap] + [opt_value(o)] + seq[gap + 1:]) is True
        return Choice('inequality', holds, {'relation': seq, 'given': given},
                      given + [opt_value(o) for o in it.options if holds(o)]), out

    # --- a number sentence in a row: solve the gap
    if seq and None in seq and any(isinstance(t, str) for t in seq):
        sols = solve_gap(seq)
        if len(sols) != 1:
            out.append(('WRONG', 'unsolvable', 'the number sentence %s has %d solutions' % (row, len(sols))))
            return None, out
        x = sols[0]
        given = [t for t in seq if isinstance(t, (int, float))]
        if nums and sorted(nums) != sorted(given):
            picture(sorted(nums), sorted(given), 'the numbers of the sentence')
        plus, minus = cap.count('ועוד'), cap.count('פחות')
        if plus + minus and (plus != seq.count('+') or minus != seq.count('-') + seq.count('−')):
            out.append(('WRONG', 'picture', 'the caption reads %d plus and %d minus, the row has %s' % (plus, minus, row)))
        rev = list(reversed(seq))
        ops = [t for t in seq if isinstance(t, str) and t != '=']
        ctx = {'given': given, 'op': ops[0] if ops else None, 'sentence': True}
        if len(given) >= 2 and seq.index(None) == len(seq) - 1:
            ctx['a'], ctx['b'] = given[0], given[1]
        # LTR: the sentence read right to left must not be the one the answer belongs to
        if rev != seq and None in rev:
            rsols = solve_gap(rev)
            if rsols and x not in rsols and any(opt_value(o) in rsols for o in it.options):
                out.append(('NOTE', 'ltr', 'read right to left the sentence gives %s, an option' % rsols[0]))
        return numeric('sentence', x, ctx, given), out
    if seq and None in seq and all(isinstance(t, int) or t is None for t in seq):
        known = [(i, v) for i, v in enumerate(seq) if v is not None]
        (i0, v0), (i1, v1) = known[0], known[1]
        step = (v1 - v0) / (i1 - i0)
        gap = seq.index(None)
        x = v0 + step * (gap - i0)
        if any(v != v0 + step * (i - i0) for i, v in known):
            out.append(('WRONG', 'unsolvable', 'the row %s is not a counting sequence' % row))
        return numeric('missing-in-row', int(x), {'given': [v for _, v in known]}, [v for _, v in known]), out

    # --- coins and notes: the shekels drawn (M10 C1: ten-shekel coins as tens, one-shekel coins as ones)
    if g and sprite_info(g).get('kind') in ('coin', 'note') and it.has('שקל') and not it.has('כדי ש'):
        total, coins, given = 0, 0, []
        for grp in (g, g2):
            if grp:
                info = sprite_info(grp)
                if info.get('kind') not in ('coin', 'note'):
                    return None, out
                total += (info.get('value') or 0) * grp.get('count', 0)
                coins += grp.get('count', 0)
                given.append(grp.get('count', 0))
        return numeric('coin-total', total, {'coins': coins, 'given': given}, [total]), out

    # --- tens and ones said in words ("three tens and four ones", in either order)
    if it.has('עשרות') and it.has('יחידות', 'יחידה'):
        w = it.words

        def said_with(*names):
            for k, t in enumerate(w):
                if t in names or (t.startswith('ו') and t[1:] in names):
                    if t.endswith('ה') and k + 1 < len(w) and _num_word(w[k + 1]):  # "יחידה אחת"
                        return _num_word(w[k + 1])[0]
                    if k > 0 and _num_word(w[k - 1]):
                        return _num_word(w[k - 1])[0]
            return None
        tens, ones = said_with('עשרות'), said_with('יחידות', 'יחידה')
        if tens is not None and ones is not None:
            return numeric('place-words', 10 * tens + ones, {'given': [tens, ones]}, [10 * tens + ones]), out

    # --- stories with pictures
    if g and g2 and it.has('מוסיפים עוד', 'ובא עוד', 'ובאו עוד', 'בחוץ. כמה יש בסך הכל', 'ועוד') and it.has('כמה') \
            and not it.has('ועוד כמה'):
        a, b = (nums + [None, None])[:2]
        picture(a, gc, 'the first group')
        picture(b, g2c, 'the second group')
        return numeric('join', gc + g2c, {'given': [gc, g2c], 'a': gc, 'b': g2c, 'op': '+'}, [gc, g2c]), out
    if g and it.has('ועכשו יש') and it.has('כמה הוספנו') and len(nums) >= 2:
        picture(nums[0], gc, 'the group')
        return numeric('change-unknown', nums[1] - nums[0], {'given': nums[:2], 'whole': nums[1]}, nums[:2]), out
    if g and it.has('בסך הכל') and it.has('בחוץ') and it.has('כמה בחוץ') and len(nums) >= 2:
        picture(nums[0], gc, 'the group (the whole)')
        return numeric('missing-part', nums[0] - nums[1], {'given': nums[:2], 'whole': nums[0]}, nums[:2]), out
    if g and it.has('כלם', 'כלן') and it.has('נשארו') and nums:
        picture(nums[0], gc, 'the group')
        return numeric('all-gone', 0, {'given': nums[:1]}, nums[:1]), out
    if g and it.has('נשארו') and it.has('לוקחים', 'נאכל', 'נפל', 'שחה משם', 'מכניסים') and len(nums) >= 2:
        picture(nums[0], gc, 'the group')
        return numeric('take-away', nums[0] - nums[1], {'given': nums[:2], 'whole': nums[0], 'a': nums[0], 'b': nums[1],
                                                        'op': '-'}, nums[:2]), out
    if it.has('כדי שיהיה', 'כדי שיהיו') and nums:
        target = nums[-1]
        have = nums[0] if len(nums) >= 2 else gc
        picture(have, gc, 'the group')
        return numeric('make-target', target - have, {'given': [have, target], 'whole': target}, [have, target]), out
    if it.has('זה') and it.has('ועוד כמה') and len(nums) >= 2:
        whole, part = nums[0], nums[1]
        if g and g2:
            picture(whole, gc + g2c, 'the two groups together')
            picture(part, gc, 'the first group')
        return numeric('missing-addend', whole - part, {'given': [whole, part], 'whole': whole}, [whole, part]), out
    if g and g2 and it.has('ועוד') and it.has('כמה זה') and len(nums) >= 2:
        picture(nums[0], gc, 'the first group')
        picture(nums[1], g2c, 'the second group')
        return numeric('join', gc + g2c, {'given': [gc, g2c], 'a': gc, 'b': g2c}, [gc, g2c]), out
    if chart and it.has('על כל צלחת'):
        if it.has('כמה צלחות') and len(nums) >= 2:
            total, per = nums[0], nums[1]
            picture(total, sum(c.get('count', 0) for c in chart), 'the plates together')
            if total % per:
                out.append(('WRONG', 'unsolvable', '%d does not share into groups of %d' % (total, per)))
            return numeric('grouping', total // per, {'given': [total, per]}, [total, per]), out
        if len(nums) >= 2:
            plates, per = nums[0], nums[1]
            picture(plates, len(chart), 'the plates')
            for c in chart:
                picture(per, c.get('count'), 'a plate')
            return numeric('equal-groups', plates * per, {'given': [plates, per], 'a': plates, 'b': per},
                           [plates, per]), out
    if chart:
        counts = [c.get('count', 0) for c in chart]
        if it.has('כמה יותר'):
            return numeric('compare-diff', max(counts) - min(counts), {'given': [max(counts), min(counts)]}, counts), out
        if it.has('בסך הכל'):
            return numeric('chart-total', sum(counts), {}, counts), out
        by = {sprite_info(c.get('sprite'))['name']: c.get('count') for c in chart}
        if it.has('הכי הרבה', 'הכי מעט'):
            want = max(counts) if it.has('הכי הרבה') else min(counts)
            if counts.count(want) > 1:
                out.append(('WRONG', 'second-right', 'two bars have %d' % want))
            return Choice('chart-extreme', lambda o: by.get(opt_info(o)['name']) == want, nums=counts), out
        if it.has('בדיוק') and nums:
            return Choice('chart-exact', lambda o: by.get(opt_info(o)['name']) == nums[0], nums=counts), out

    # --- the counting sequence
    if it.has('סופרים ב') and it.has('מה בא אחר כך') and len(nums) >= 3:
        step = nums[-1] - nums[-2]
        if nums[-2] - nums[-3] != step:
            out.append(('WRONG', 'unsolvable', 'the counting %s has no single step' % nums))
        return numeric('skip-count', nums[-1] + step, {'given': nums, 'prev': nums[-1]}, nums), out
    days = [DAY_WORDS[w] for w in it.words if w in DAY_WORDS]
    if (it.has('יום ') or 'שבת' in it.words) and days:
        d = days[0]
        if it.has('אחרי', 'מחר'):
            x = d % 7 + 1
        elif it.has('לפני', 'אתמול'):
            x = (d - 2) % 7 + 1
        else:
            return None, out
        return Choice('days', lambda o: opt_info(o).get('n') == x), out
    times = [TIME_WORDS[w[1:] if w.startswith('ה') and w[1:] in TIME_WORDS else w] for w in it.words
             if w in TIME_WORDS or (w.startswith('ה') and w[1:] in TIME_WORDS)]
    if times:
        k = TIME_ORDER.index(times[0])
        if it.has('אחרי'):
            want = TIME_ORDER[(k + 1) % 4]
        elif it.has('לפני'):
            want = TIME_ORDER[(k - 1) % 4]
        else:
            want = times[0]
        return Choice('time-of-day', lambda o: opt_info(o).get('time') == want), out
    if it.has('מה בא אחרי', 'הוסיפו עוד אחת אל') and nums:
        return numeric('next', nums[-1] + 1, {'prev': nums[-1], 'given': [nums[-1]]}, nums), out
    if it.has('מה בא לפני', 'קחו אחת מתוך') and nums:
        return numeric('before', nums[-1] - 1, {'prev': nums[-1], 'given': [nums[-1]]}, nums), out
    if it.has('איפה המספר') and nums:
        return numeric('pick-numeral', nums[0], {}, nums), out
    if it.has('איזה מספר גדול יותר', 'איזה מספר קטן יותר'):
        vals = [opt_value(o) for o in it.options]
        x = max(vals) if it.has('גדול') else min(vals)
        return numeric('compare-numerals', x, {'compare': vals, 'want': 'max' if it.has('גדול') else 'min'}, vals), out
    if it.has('איפה יש') and it.has('יותר', 'פחות') and all(isinstance(o.get('set'), dict) for o in it.options):
        vals = [opt_value(o) for o in it.options]
        x = max(vals) if it.has('יותר') else min(vals)
        if vals.count(x) > 1:
            out.append(('WRONG', 'second-right', 'two sets have %d' % x))
        return Choice('compare-sets', lambda o: opt_value(o) == x, {'sets': it.options}, vals), out
    if it.has('איפה יש') and (nums or isinstance(sc.get('numeral'), int)) and \
            all(isinstance(o.get('set'), dict) for o in it.options):
        n = nums[0] if nums else sc['numeral']
        picture(n, sc.get('numeral'), 'the numeral shown')
        return numeric('numeral-to-set', n, {}, [n]), out
    yes_no = {o['id']: opt_info(o)['name'] for o in it.options}
    yes = next((i for i, n in yes_no.items() if n == 'tick'), None)
    if yes and len(it.options) == 2:
        verdict = None
        if it.has('אותו מספר') and g and g2:
            verdict = gc == g2c
        elif it.has('לזוגות') and g:
            verdict = gc % 2 == 0
        elif it.has('צורה סגורה') and g:
            verdict = sprite_info(g)['shape'] in POLYGONS if sprite_info(g).get('shape') else False
        elif it.has('הסדר חוזר') and row:
            verdict = periodic(row) is not None
        elif it.has('זו בננה', 'זה תפוח') and g:
            verdict = sprite_info(g)['kind'] == ('banana' if it.has('בננה') else 'apple')
        if verdict is None:
            return None, out
        return Choice('yes-no', lambda o: (opt_info(o)['name'] == 'tick') == verdict,
                      {'nums': [gc, g2c]}, [v for v in (gc, g2c) if v is not None]), out
    if it.has('אפשר לקנות') and nums and g:
        picture(nums[-1], gc, 'the coins')
        return numeric('coins-to-items', nums[-1], {}, [nums[-1]]), out
    if it.has('כמה') and it.has('יש? בוחרים', 'בקערה', 'בקן', 'בסל') and g:
        return numeric('count-group', gc, {}, [gc]), out
    if it.has('מה השעה') and g:
        return numeric('clock-read', sprite_info(g).get('n'), {}, []), out
    if it.has('כמה צלעות') and g:
        info = sprite_info(g)
        n = SIDES.get(info.get('shape'))
        drawn = svg.corners(g)
        if n is not None and drawn is not None and len(drawn) != n:
            out.append(('WRONG', 'picture', 'the %s is drawn with %d sides' % (info['name'], len(drawn))))
        return numeric('sides', n, {}, [n] if n else []), out
    if it.has('איזה מטבע שוה יותר'):
        vals = [opt_info(o).get('value') or 0 for o in it.options]
        return Choice('coin-value', lambda o: (opt_info(o).get('value') or 0) == max(vals)), out

    # --- shapes
    if it.has('כל הצלעות שוות') and not it.has('לא כל'):
        def equal_sides(info):
            s = svg.sides('asset:' + info['name'])
            return bool(s) and max(s) - min(s) <= 0.5
        near = []
        for o in it.options:
            s = svg.sides(o.get('sprite'))
            if s and not equal_sides(opt_info(o)) and (max(s) - min(s)) / max(s) < 0.08:
                near.append('%s (sides %s)' % (opt_info(o)['name'], '/'.join('%.0f' % v for v in s)))
        if near:
            out.append(('AMBIG', 'looks-equal', 'all sides look equal on %s' % ', '.join(near)))
        return by_info('equal-sides', equal_sides), out
    if it.has('לא כל הצלעות שוות'):
        return by_info('rect-not-square', lambda i: i.get('shape') == 'rect'), out
    if it.has('קו עקם') and it.has('לאיזו צורה'):
        return by_info('curved-shape', lambda i: i.get('shape') in ('circle', 'curved')), out
    if it.has('הקו הישר', 'הקו העקם'):
        want = 'straight' if it.has('ישר') else 'curved'
        return by_info('line', lambda i: i.get('line') == want), out
    if it.has('מתגלגל'):
        return by_info('rolls', lambda i: i.get('solid') in ROLLS or i.get('kind') == 'ball'), out
    if it.has('לערם'):
        return by_info('stacks', lambda i: i.get('solid') in STACKS), out
    if it.has('נשאר עומד'):
        return by_info('stays', lambda i: i.get('solid') in STAYS), out
    if it.has('משאיר עגול'):
        return by_info('circle-face', lambda i: i.get('solid') in CIRCLE_FACE), out
    if it.has('איזו צורה ארכה'):
        return by_info('long-shape', lambda i: i.get('shape') == 'rect'), out
    if it.has('איפה הכדור?') and any(w in POS_WORDS for w in it.words):
        want = next(POS_WORDS[w] for w in it.words if w in POS_WORDS)
        return by_info('position', lambda i: i.get('pos') == want), out
    if it.has('מה בצורת'):
        want = (shapes_in(cap) or [None])[0]
        return by_info('world-shape', lambda i: WORLD_SHAPE.get(i['name']) == want), out
    if it.has('איזו צורה יש ל') and g:
        want = WORLD_SHAPE.get(sprite_info(g)['name'])
        return by_info('world-shape', lambda i: i.get('shape') == want), out
    if it.has('איפה אותה צורה') and g:
        want = sprite_info(g).get('shape')
        return by_info('same-shape', lambda i: i.get('shape') == want), out
    if it.has('איפה אותו צבע') and g:
        want = sprite_info(g).get('colour')
        return by_info('same-colour', lambda i: i.get('colour') == want), out
    if it.has('איפה אותו הדבר') and g:
        gi = sprite_info(g)
        same = [o for o in it.options if opt_info(o)['name'] == gi['name']]
        kin = [o['id'] for o in it.options if opt_info(o)['kind'] == gi['kind'] and o not in same]
        if same and kin:
            out.append(('AMBIG', 'same-thing', '"the same thing" is the same kind in other items of the skill (a green '
                        'apple for a red one), and here %s is the same kind too' % ', '.join(kin)))
        if same:
            return by_info('same-thing', lambda i: i['name'] == gi['name']), out
        return by_info('same-thing', lambda i: i['kind'] == gi['kind']), out
    if it.has('הוא לא') and len(colours_in(cap)) == 1 and len(shapes_in(cap)) == 1:
        nc, ns = colours_in(cap)[0], shapes_in(cap)[0]
        return by_info('not-not', lambda i: i.get('colour') != nc and i.get('shape') != ns), out
    if it.has('מערבבים'):
        cs = colours_in(cap)
        if len(cs) == 2:
            want = MIX.get(frozenset(cs))
            return by_info('mix', lambda i: i.get('colour') == want), out
    if it.has('נעשים') and it.has('מה חסר'):
        cs = colours_in(cap)
        if len(cs) == 2:
            have, result = cs
            want = [c for c in COLOURS if MIX.get(frozenset((have, c))) == result]
            return by_info('mix-missing', lambda i: i.get('colour') in want), out
    if it.has('הכי בהיר', 'הכי כהה'):
        vals = [opt_info(o).get('n') for o in it.options]
        want = min(vals) if it.has('בהיר') else max(vals)
        return by_info('shade-extreme', lambda i: i.get('n') == want), out
    if it.has('איפה עוד', 'מי עוד') and colours_in(cap):
        want = colours_in(cap)[0]
        return by_info('same-hue', lambda i: i.get('colour') == want), out
    if it.has('איזה צבע') and g:
        want = sprite_info(g).get('colour')
        if it.has('בננה בשלה'):
            want = 'yellow'
        return by_info('object-colour', lambda i: i.get('colour') == want), out
    if it.has('איפה הבננה', 'איפה התפוח'):
        want = 'banana' if it.has('בננה') else 'apple'
        return by_info('kind', lambda i: i['kind'] == want), out
    if it.has('מה הולך עם') and g:
        want = PAIRS.get(sprite_info(g)['name'], set())
        return by_info('pairs', lambda i: i['name'] in want), out
    if it.has('לאן הולך') and g:
        gi = sprite_info(g)
        if all(opt_info(o)['kind'] == gi['kind'] for o in it.options):
            return by_info('sort-target', lambda i: i.get('colour') == gi.get('colour')), out
        return by_info('sort-target', lambda i: i['kind'] == gi['kind']), out
    if it.has('מה משתף לכלם') and row:
        infos = [sprite_info(r) for r in row]
        common = set()
        if len({i.get('colour') for i in infos}) == 1 and infos[0].get('colour'):
            common.add('rule_colour')
        if len({i.get('shape') for i in infos}) == 1 and infos[0].get('shape'):
            common.add('rule_shape')
        sizes = {i.get('size', 2) for i in infos}
        if len(sizes) == 1:
            common.add('rule_size')
        return by_info('common-rule', lambda i: i['name'] in common), out
    if it.has('מי שונה') and row:
        c = Counter(row)
        odd = {k for k, v in c.items() if v == 1}
        return Choice('odd-one-out', lambda o: ('asset:' + opt_info(o)['name']) in odd, nums=[]), out
    for story in STORIES:
        names = {opt_info(o)['name'] for o in it.options}
        if not names & set(story):
            continue
        if row and '?' in row and all(r == '?' or sprite_info(r)['name'] in story for r in row):
            k = row.index('?')
            return by_info('story', lambda i, s=story, k=k: i['name'] == s[k]), out
        if it.has('קדם'):
            return by_info('story', lambda i, s=story: i['name'] == s[0]), out
        if it.has('בסוף'):
            return by_info('story', lambda i, s=story: i['name'] == s[-1]), out
        if it.has('לפני', 'אחר כך'):
            cue = {'יצא אפרוח': 'chick', 'צמח פרח': 'plant_flower', 'הביצה נסדקה': 'egg_crack'}
            here = next((v for k, v in cue.items() if k in cap), None)
            if here in story:
                k = story.index(here) + (1 if it.has('אחר כך') else -1)
                if 0 <= k < len(story):
                    return by_info('story', lambda i, s=story, k=k: i['name'] == s[k]), out
    if it.has('איזה', 'מה') and it.has('גדול', 'קטן', 'ארך', 'קצר') and not row:
        vals = [opt_info(o).get('size') for o in it.options]
        if None not in vals:
            want = max(vals) if it.has('גדול', 'ארך') else min(vals)
            return by_info('size', lambda i: i.get('size') == want), out
    if it.has('מה כבד', 'מה קל'):
        w = [HEAVY.get(opt_info(o)['name'].split('_')[0]) for o in it.options]
        if None not in w:
            want = max(w) if it.has('כבד') else min(w)
            return by_info('weight', lambda i: HEAVY.get(i['name'].split('_')[0]) == want), out
    if it.has('בתור'):
        k = {'ראשון': 0, 'שני': 1, 'שלישי': 2}.get(next((w for w in it.words if w in ('ראשון', 'שני', 'שלישי')), ''))
        if it.has('האחרון'):
            k = len(it.options) - 1
        if k is not None:
            ids = [o['id'] for o in it.options]
            if len(ids) - 1 - k != k:
                    out.append(('AMBIG', 'queue-direction', 'the queue is the row of tiles, drawn left to right with no head '
                            'of the line shown; a child reading right to left counts from the other end (%s)' %
                            ids[len(ids) - 1 - k]))
            return Choice('ordinal', lambda o, k=k: o['id'] == ids[k]), out
    if row:
        infos = [sprite_info(r) if r != '?' else None for r in row]
        gap = row.index('?') if '?' in row else None
        if gap is not None and it.has('בסוף', 'קדם', 'באמצע', 'גדלים', 'חסר') and \
                all(i is None or seq_value(i) is not None for i in infos):
            known = [(k, seq_value(i)) for k, i in enumerate(infos) if i is not None]
            (i0, v0), (i1, v1) = known[0], known[-1]
            step = (v1 - v0) / (i1 - i0)
            want = v0 + step * (gap - i0)
            kinds = {i['kind'] for i in infos if i}
            if any(abs(v - (v0 + step * (k - i0))) > 1e-9 for k, v in known):
                out.append(('WRONG', 'unsolvable', 'the row %s is not one series' % row))
            return by_info('series', lambda i: i['kind'] in kinds and seq_value(i) == want), out
        if gap is not None and it.has('מה בא אחר כך', 'מה חסר'):
            fills = period_fill(row, gap)
            if not fills:
                out.append(('WRONG', 'unsolvable', 'the row %s does not repeat' % row))
                return None, out
            want = fills[0][1]
            return Choice('pattern', lambda o: o.get('sprite') == want), out

    # --- colour or shape by name ("where is the red balloon?", "where is the triangle?")
    want_c, want_s = colours_in(cap), shapes_in(cap)
    want_solid = _find(it.words, SOLID_WORDS) if it.has('איפה') else []
    want_k = _find(it.words, KIND_WORDS)
    if it.has('איפה') and (want_c or want_s or want_solid):
        if want_c:
            kind = want_k[0] if want_k else None
            return by_info('find-colour', lambda i: i.get('colour') == want_c[0] and
                           (kind in (None, 'shape') or i['kind'] == kind)), out
        if want_s:
            return by_info('find-shape', lambda i: shape_member(i, want_s[0], False),
                           inclusive=lambda i: shape_member(i, want_s[0], True)), out
        solid = want_solid[0]
        return by_info('find-solid', lambda i: i.get('solid') == solid or (solid == 'sphere' and i['kind'] == 'ball')), out
    return None, out


# ---------------------------------------------------------------- labels: a spoken label names what its picture shows


def check_label(f, it, o):
    label = o.get('label')
    if not label:
        return
    v = opt_value(o)
    info = opt_info(o)
    said = numbers(label)
    if isinstance(o.get('numeral'), (int, float)) or isinstance(o.get('value'), (int, float)):
        if said and said != [v]:
            f.add('WRONG', it, 'label', '%s: the label says %s, the tile shows %s' % (o['id'], said, v))
    elif isinstance(o.get('set'), dict) and said:
        if said != [v]:
            f.add('WRONG', it, 'label', '%s: the label says %s, the set has %s' % (o['id'], said, v))
    if info.get('kind') == 'tower' and said and said != [info['n']]:
        f.add('WRONG', it, 'label', '%s: the label says tower %s, the picture is tower %s' % (o['id'], said, info['n']))
    if info.get('kind') == 'day':
        d = [DAY_WORDS[w] for w in tokens(label) if w in DAY_WORDS]
        if d and d[0] != info['n']:
            f.add('WRONG', it, 'label', '%s: the label says day %s, the picture is day %s' % (o['id'], d[0], info['n']))
    cs = colours_in(label)
    if cs and info.get('colour') and cs[0] != info['colour']:
        f.add('WRONG', it, 'label', '%s: the label says %s, the picture is %s' % (o['id'], cs[0], info['colour']))
    ss = shapes_in(label)
    if ss and info.get('shape') and ss[0] != info['shape'] and not (info['shape'] == 'quad' and ss[0] == 'quad'):
        f.add('WRONG', it, 'label', '%s: the label says %s, the picture is a %s' % (o['id'], ss[0], info['shape']))


# ---------------------------------------------------------------- tag rules (§5.3)


def check_tags(f, it, known_tags, catalogue, skills, choice):
    tags = []
    for t in (it.answer.get(k) for k in it.answer if 'isconception' in k):
        if isinstance(t, str):
            tags.append(t)
    for c in it.answer.get('classifiers') or []:
        if c.get('misconception'):
            tags.append(c['misconception'])
    for o in it.options:
        if o.get('misconception'):
            tags.append(o['misconception'])
    for t in tags:
        if t not in known_tags and t not in catalogue:
            f.add('RULE', it, 'tag-unknown', '%s has no misconception record and is not in the catalogue' % t)
        elif t not in catalogue:
            f.add('NOTE', it, 'tag-catalogue', '%s is not in the §5.2 catalogue (a record only)' % t)
    if not it.options:
        return
    distract = [o for o in it.options if o['id'] != it.correct]
    right = next((o for o in it.options if o['id'] == it.correct), None)
    if right is not None and right.get('misconception'):
        f.add('RULE', it, 'tag-on-right', 'the right option %s carries %s' % (right['id'], right['misconception']))
    tagged = [o for o in distract if o.get('misconception')]
    untagged = [o['id'] for o in distract if not o.get('misconception')]
    n = len(it.options)
    watch = (skills.get(it.skill) or {}).get('misconceptions') or []
    if n == 2:
        if untagged:
            f.add('RULE', it, 'tag-missing', 'a 2-option item: the distractor %s has no tag' % untagged[0])
    elif n >= 3:
        if len(untagged) > (1 if n >= 4 else 0):
            f.add('RULE', it, 'tag-missing', '%d options: untagged distractors %s' % (n, ', '.join(untagged)))
        distinct = {o['misconception'] for o in tagged}
        if len(tagged) >= 2 and len(distinct) < 2 and len(watch) != 1:
            f.add('RULE', it, 'tag-distinct', 'two distractors share %s, and %s watches %d tags' %
                  (next(iter(distinct)), it.skill, len(watch)))
    if choice is not None:
        for o in tagged:
            v = opt_value(o)
            if v is None:
                continue
            cand = tag_candidates(o['misconception'], choice.ctx)
            if cand is not None and not any(abs(v - c) < 1e-9 for c in cand):
                f.add('RULE', it, 'tag-rule', '%s = %s is not what %s gives here (%s)' %
                      (o['id'], v, o['misconception'], ', '.join(str(int(c) if c == int(c) else c) for c in sorted(cand))))


# ---------------------------------------------------------------- the other templates


def check_spot(f, it):
    cells = it.scene.get('cells') or []
    wrong = it.answer.get('wrong')
    seq = parse_cells(cells)
    if seq is not None and '=' in seq:
        if equation_true(seq):
            f.add('WRONG', it, 'spot', 'the sentence %s is true: there is no mistake' % cells)
            return 'sentence'
        if not isinstance(seq[wrong], (int, float)):
            f.add('WRONG', it, 'spot', 'the marked cell %d is an operator' % wrong)
        fixes = []
        for k, t in enumerate(seq):
            if isinstance(t, (int, float)):
                if any(equation_true(seq[:k] + [v] + seq[k + 1:]) for v in range(0, 101)):
                    fixes.append(k)
        if wrong not in fixes:
            f.add('WRONG', it, 'spot', 'changing the marked cell %d cannot make it true' % wrong)
        pinned = it.has('התשובה')
        if pinned:
            k = seq.index('=')
            answer_side = k + 1 if len(seq) - k == 2 else (0 if k == 1 else None)
            if answer_side is not None and wrong != answer_side:
                f.add('WRONG', it, 'spot', 'the caption says the answer is wrong, the marked cell %d is not the answer'
                      % wrong)
        elif len(fixes) > 1:
            f.add('AMBIG', it, 'spot-many', 'the caption does not say which number is wrong, and changing any of cells %s '
                  'makes it true' % fixes)
        return 'sentence'
    if seq is not None and all(isinstance(t, int) for t in seq):
        step_hint = 10 if it.has('בעשרות') else (2 if it.has('בשתים') else None)
        found = set()
        for i in range(len(seq)):
            for j in range(i + 1, len(seq)):
                if (seq[j] - seq[i]) % (j - i):
                    continue
                step = (seq[j] - seq[i]) // (j - i)
                if step == 0 or (step_hint and abs(step) != step_hint):
                    continue
                start = seq[i] - i * step
                bad = [k for k, v in enumerate(seq) if v != start + k * step]
                if len(bad) == 1:
                    found.add(bad[0])
        if not found:
            f.add('WRONG', it, 'spot', 'no counting with one mistake fits %s' % seq)
        elif wrong not in found:
            f.add('WRONG', it, 'spot', 'the mistake is at %s, the item marks %d' % (sorted(found), wrong))
        elif len(found) > 1:
            f.add('AMBIG', it, 'spot-many', 'one mistake fits at cells %s' % sorted(found))
        return 'counting'
    infos = [sprite_info(c) for c in cells]
    cls = None
    if it.has('אוסף רק'):
        cs, ss = colours_in(it.cap), shapes_in(it.cap)
        solids = _find(it.words, SOLID_WORDS)
        kinds = _find(it.words, KIND_WORDS)
        if cs:
            cls = lambda i: i.get('colour') == cs[0]
        elif ss:
            cls = lambda i: shape_member(i, ss[0], True)
        elif it.has('צורות סגורות'):
            cls = lambda i: i.get('shape') in POLYGONS
        elif solids:
            cls = lambda i: i.get('solid') == solids[0]
        elif kinds:
            cls = lambda i: i['kind'] == kinds[0]
    elif it.has('מין לפי צבע', 'מין לפי צורה'):
        key = 'colour' if it.has('צבע') else 'shape'
        common = Counter(i.get(key) for i in infos).most_common(1)[0][0]
        cls = lambda i: i.get(key) == common
    if cls is not None:
        odd = [k for k, i in enumerate(infos) if not cls(i)]
        if odd != [wrong]:
            f.add('WRONG', it, 'spot', 'the cells that do not belong are %s, the item marks %d' % (odd, wrong))
        return 'collection'
    vals = [seq_value(i) for i in infos]
    if it.has('סדר את המגדלים') and None not in vals:
        good = [k for k in range(len(vals)) if all(vals[j] == vals[0] + j for j in range(len(vals)) if j != k)
                or all(vals[j] == vals[0] - j for j in range(len(vals)) if j != k)]
        if wrong not in good or len(good) != 1:
            f.add('WRONG' if wrong not in good else 'AMBIG', it, 'spot', 'the tower out of order is at %s, marked %d' %
                  (good, wrong))
        return 'series'
    if it.has('קשת'):
        want = RAINBOW[:len(cells)]
        odd = [k for k, i in enumerate(infos) if i.get('colour') != want[k]]
        if odd != [wrong]:
            f.add('WRONG', it, 'spot', 'the rainbow is wrong at %s, the item marks %d' % (odd, wrong))
        return 'rainbow'
    if it.has('הסדר חוזר'):
        found = set()
        n = len(cells)
        for p in range(1, n // 2 + 1):
            for k in range(n):
                core = {}
                ok = True
                for i in range(n):
                    if i == k:
                        continue
                    if core.setdefault(i % p, cells[i]) != cells[i]:
                        ok = False
                        break
                if ok and core.get(k % p) not in (None, cells[k]) and len(core) == p:
                    found.add(k)
            if found:
                break
        if wrong not in found:
            f.add('WRONG', it, 'spot', 'the cell that breaks the pattern is %s, the item marks %d' % (sorted(found), wrong))
        elif len(found) > 1:
            f.add('AMBIG', it, 'spot-many', 'the pattern can break at cells %s' % sorted(found))
        return 'pattern'
    return None


def check_number_line(f, it):
    sc, a = it.scene, it.answer
    lo, hi, labels = sc.get('from'), sc.get('to'), sc.get('labels') or []
    if lo is None or hi is None or lo >= hi:
        f.add('WRONG', it, 'ltr', 'the line runs from %s to %s' % (lo, hi))
    if labels != sorted(labels) or len(set(labels)) != len(labels):
        f.add('WRONG', it, 'ltr', 'the labels %s do not grow left to right' % labels)
    if labels and (labels[0] < lo or labels[-1] > hi):
        f.add('WRONG', it, 'picture', 'labels %s outside %s..%s' % (labels, lo, hi))
    if not a.get('mirrorMisconception'):
        f.add('NOTE', it, 'ltr', 'no mirrorMisconception (M-NL-DIR) on a number line')
    nums = numbers(it.caption)
    target = a.get('target')
    if a.get('mode') == 'jump':
        start, hops = sc.get('start'), sc.get('hops') or []
        back = it.has('אחורה')
        if nums[:1] and nums[0] != start:
            f.add('WRONG', it, 'picture', 'the caption starts at %s, the frog stands on %s' % (nums[0], start))
        if len(nums) >= 2 and sum(abs(h) for h in hops) != nums[1]:
            f.add('WRONG', it, 'picture', 'the caption jumps %s, the hops are %s' % (nums[1], hops))
        if any((h < 0) != back for h in hops):
            f.add('WRONG', it, 'picture', 'the caption says %s, the hops are %s' % ('back' if back else 'forward', hops))
        x = start + sum(hops)
        if x != target:
            f.add('WRONG', it, 'answer', 'the frog lands on %s, the item marks %s' % (x, target))
        return [start] + [abs(h) for h in hops] + [x]
    if nums and nums[0] != target:
        f.add('WRONG', it, 'answer', 'the caption asks for %s, the target is %s' % (nums[0], target))
    if target is not None and (target < lo or target > hi):
        f.add('WRONG', it, 'answer', 'the target %s is off the line' % target)
    return [target]


def check_balance(f, it):
    sc, a = it.scene, it.answer
    def side(s):
        gs = (sc.get(s) or {}).get('groups') or []
        return gs, sum(g.get('count', 0) * g.get('weight', 1) for g in gs)
    lg, lw = side('left')
    rg, rw = side('right')
    nums = numbers(it.caption)
    if it.has('מול') and len(nums) >= 4:
        drawn = [g.get('count') for g in lg + rg]
        if drawn != nums[:4]:
            f.add('WRONG', it, 'picture', 'the caption says %s, the pans hold %s' % (nums[:4], drawn))
    if a.get('mode') == 'compare':
        want = 'same' if lw == rw else ('left' if lw > rw else 'right')
        if a.get('result') != want:
            f.add('WRONG', it, 'answer', 'left %s, right %s: the answer is %s, the item marks %s' %
                  (lw, rw, want, a.get('result')))
    elif a.get('mode') == 'balance':
        want = str(abs(lw - rw))
        if a.get('result') != want:
            f.add('WRONG', it, 'answer', 'left %s, right %s: %s blocks, the item marks %s' % (lw, rw, want, a.get('result')))
        if it.has('הצד הימני קל') and not rw < lw:
            f.add('WRONG', it, 'picture', 'the caption says the right pan is lighter, it holds %s against %s' % (rw, lw))
        if it.has('הצד השמאלי קל') and not lw < rw:
            f.add('WRONG', it, 'picture', 'the caption says the left pan is lighter, it holds %s against %s' % (lw, rw))
    return [g.get('count') for g in lg + rg]


def check_give(f, it):
    n = it.answer.get('n')
    nums = numbers(it.caption)
    src = (it.scene.get('source') or {}).get('count')
    if nums and nums[-1] != n:
        f.add('WRONG', it, 'answer', 'the caption asks for %s, the item wants %s' % (nums[-1], n))
    if src is not None and src <= n:
        f.add('AMBIG', it, 'take-all', 'the pile has %s, so taking the whole pile is also right: M-CNT-CARD cannot show, '
              'and a child who grabs everything is marked right' % src)
    return [n]


def check_clock(f, it):
    sc = it.scene
    nums = numbers(it.caption)
    if nums and nums[0] != sc.get('hour'):
        f.add('WRONG', it, 'answer', 'the caption asks for %s, the clock wants %s' % (nums[0], sc.get('hour')))
    if sc.get('minute') not in (0, None) and it.skill == 'MATH-B-15':
        f.add('RULE', it, 'range', 'MATH-B-15 reads whole hours, the item has minute %s' % sc.get('minute'))
    if sc.get('startHour') == sc.get('hour') and not sc.get('startHalf') and sc.get('minute') in (0, None):
        f.add('WRONG', it, 'answer', 'the clock already shows %s:00 at the start' % sc.get('hour'))
    return [sc.get('hour')]


def check_shop(f, it):
    sc = it.scene
    price = (sc.get('price') or 0) / 100
    nums = numbers(it.caption)
    if nums and nums[0] != price:
        f.add('WRONG', it, 'answer', 'the caption says %s shekels, the price is %s' % (nums[0], price))
    coins = []
    for p in sc.get('purse') or []:
        coins += [COINS.get(p.get('kind'), 0)] * p.get('count', 0)
    can = {0}
    for c in coins:
        can |= {round(v + c, 2) for v in can}
    if round(price, 2) not in can:
        f.add('WRONG', it, 'unsolvable', 'the purse %s cannot pay %s exactly' % (sc.get('purse'), price))
    return [price]


def check_match(f, it):
    left, right = it.scene.get('left') or [], it.scene.get('right') or []
    pairs = it.answer.get('pairs') or []
    def val(e):
        if isinstance(e.get('numeral'), (int, float)):
            return ('n', e['numeral'])
        if e.get('coin'):
            return ('n', COINS.get(e['coin']))
        info = sprite_info(e.get('sprite'))
        if e.get('count') and info.get('kind') not in ('solid', 'shape'):
            return ('n', e['count'])
        if info.get('solid'):
            return ('solid', info['solid'])
        if info.get('shape'):
            return ('shape', info['shape'])
        return ('?', info['name'])
    def fits(l, r):
        vl, vr = val(l), val(r)
        if vl[0] == 'n' and vr[0] == 'n':
            return vl[1] == vr[1]
        if vl[0] == 'solid' and vr[0] == 'shape':
            return vr[1] in FACES.get(vl[1], set())
        if vr[0] == 'solid' and vl[0] == 'shape':
            return vl[1] in FACES.get(vr[1], set())
        return None
    for e in left + right:
        if e.get('label'):
            said = numbers(e['label'])
            v = val(e)
            if said and v[0] == 'n' and said != [v[1]]:
                f.add('WRONG', it, 'label', '%s: the label says %s, the picture is %s' % (e['id'], said, v[1]))
    byid = {e['id']: e for e in left + right}
    for p in pairs:
        ok = fits(byid.get(p['left'], {}), byid.get(p['right'], {}))
        if ok is False:
            f.add('WRONG', it, 'answer', 'the pair %s–%s does not match' % (p['left'], p['right']))
        if ok is None:
            f.add('UNCHECKED', it, 'match', 'no rule for the pair %s–%s' % (p['left'], p['right']))
    if len(left) == len(right) and len(left) <= 6:
        good = 0
        for perm in permutations(right):
            if all(fits(l, r) for l, r in zip(left, perm)):
                good += 1
        if good > 1:
            f.add('AMBIG', it, 'match-many', '%d different ways to pair them all are right' % good)
    return [v[1] for v in map(val, left + right) if v[0] == 'n']


def check_sort(f, it):
    bins = it.scene.get('bins') or []
    items = it.scene.get('items') or []
    a = it.answer
    if a.get('mode') == 'share':
        nums = numbers(it.caption)
        if nums and nums[0] != len(items):
            f.add('WRONG', it, 'picture', 'the caption shares %s, there are %d items' % (nums[0], len(items)))
        if len(items) % max(1, len(bins)):
            f.add('WRONG', it, 'unsolvable', '%d items do not share fairly between %d' % (len(items), len(bins)))
        return [len(items)]
    binfo = {b['id']: sprite_info(b.get('sprite')) for b in bins}
    if it.has('אם הצורה'):
        cs, ss = colours_in(it.cap), shapes_in(it.cap)
        rule = (lambda i: i.get('colour') == cs[0]) if cs else ((lambda i: shape_member(i, ss[0], True)) if ss else None)
        if rule is None:
            f.add('UNCHECKED', it, 'sort', 'no rule read from the caption')
            return []
        for x in items:
            want = bins[0]['id'] if rule(sprite_info(x.get('sprite'))) else bins[1]['id']
            if x.get('bin') != want:
                f.add('WRONG', it, 'answer', '%s (%s) belongs in %s, the item puts it in %s' %
                      (x['id'], sprite_info(x.get('sprite'))['name'], want, x.get('bin')))
        return []
    key = 'colour' if it.has('לפי צבע') else 'shape' if it.has('לפי צורה') else 'size' if it.has('גדולים') else None
    if key is None:
        keys = [k for k in ('colour', 'shape', 'size', 'kind') if len({b.get(k) for b in binfo.values()}) == len(bins)
                and None not in {b.get(k) for b in binfo.values()}]
        key = keys[0] if keys else None
    if key is None:
        f.add('UNCHECKED', it, 'sort', 'no sorting rule found')
        return []
    for x in items:
        xi = sprite_info(x.get('sprite'))
        fits = [b for b, bi in binfo.items() if bi.get(key) == xi.get(key) or
                (key == 'shape' and shape_member(xi, bi.get('shape'), True) and xi.get('shape') != 'square')]
        fits = [b for b, bi in binfo.items() if bi.get(key) == xi.get(key)] or fits
        if x.get('bin') not in fits:
            f.add('WRONG', it, 'answer', '%s (%s) sorted by %s belongs in %s, the item puts it in %s' %
                  (x['id'], xi['name'], key, fits, x.get('bin')))
    return []


def check_build(f, it):
    sc, a = it.scene, it.answer
    want = a.get('sequence') or []
    model = sc.get('model')
    infos = [sprite_info(s) for s in want]
    expect = None
    if it.has('מהסוף להתחלה') and it.has('קשת'):
        expect = ['asset:ball_' + c for c in reversed(RAINBOW)][:len(want)]
        if model and model != expect:
            f.add('WRONG', it, 'picture', 'the model is not the rainbow from its end')
    elif model:
        expect = model
    elif it.has('קשת'):
        expect = ['asset:ball_' + c for c in RAINBOW][:len(want)]
        if infos and infos[0].get('kind') != 'ball':
            expect = None
    elif it.has('מהנמוך אל הגבוה', 'מהגבוה אל הנמוך'):
        vals = sorted(seq_value(i) for i in infos)
        if it.has('מהגבוה'):
            vals = vals[::-1]
        if [seq_value(i) for i in infos] != vals:
            f.add('WRONG', it, 'answer', 'the towers %s are not in order' % [seq_value(i) for i in infos])
        nums = numbers(it.caption)
        if nums and nums[0] != len(want):
            f.add('WRONG', it, 'picture', 'the caption says %s towers, the answer has %d' % (nums[0], len(want)))
    if expect is not None and want != expect:
        f.add('WRONG', it, 'answer', 'the answer %s is not %s' % ([sprite_info(s)['name'] for s in want],
                                                                  [sprite_info(s)['name'] for s in expect]))
    if it.has('תחלת הקשת') and model:
        names = [sprite_info(s).get('colour') for s in model]
        if names != RAINBOW[:len(names)]:
            f.add('WRONG', it, 'picture', 'the model %s is not the start of the rainbow' % names)
    if it.has('את הקשת') and model and not it.has('תחלת'):
        names = [sprite_info(s).get('colour') for s in model]
        if names != RAINBOW[:len(names)] and not it.has('מהסוף'):
            f.add('WRONG', it, 'picture', 'the model %s is not in rainbow order' % names)
    if sc.get('slots') not in (None, len(want)):
        f.add('WRONG', it, 'picture', '%s slots for %d steps' % (sc.get('slots'), len(want)))
    missing = [s for s in want if s not in (sc.get('palette') or [])]
    if missing:
        f.add('WRONG', it, 'unsolvable', 'the palette lacks %s' % missing)
    return []


# ---------------------------------------------------------------- the app keeps maths left to right

LTR_RENDERERS = ['tap_answer_session.dart', 'number_line_session.dart', 'spot_error_session.dart', 'choice_row.dart',
                 'clock_set_session.dart', 'balance_session.dart', 'build_pattern_session.dart', 'match_pairs_session.dart',
                 'shop_pay_session.dart']


def app_ltr(root=ROOT):
    """The renderers of rows, lines, clocks and tiles that must hold a left-to-right isolate; the missing ones."""
    play = os.path.join(root, 'app', 'lib', 'play')
    if not os.path.isdir(play):
        return []
    missing = []
    for name in LTR_RENDERERS:
        p = os.path.join(play, name)
        if not os.path.exists(p):
            continue
        with open(p, encoding='utf-8') as fh:
            if 'TextDirection.ltr' not in fh.read():
                missing.append(name)
    return missing


# ---------------------------------------------------------------- the run


def check(folder=STARTER, band=None, root=ROOT):
    """(findings, counts) for the maths items of [folder]; counts: items, checked, by kind."""
    docs, records, skills = load(folder)
    catalogue = catalogue_tags(os.path.join(root, 'docs', 'curriculum.md'))
    f, counts = check_docs(docs, records, skills, catalogue, Svg(folder), band)
    for name in app_ltr(root):
        f.add('WRONG', 'app/lib/play/' + name, 'ltr', 'the renderer has no left-to-right isolate')
    return f.rows, counts


def check_docs(docs, records, skills, catalogue, svg, band=None):
    """The findings and counts of a list of activity documents."""
    f = Findings()
    counts = Counter()
    for doc in docs:
        if doc.get('domain') not in MATHS_DOMAINS:
            continue
        it = Item(doc)
        if band and it.band != band:
            continue
        counts['items'] += 1
        choice = None
        nums = []
        kind = None
        try:
            if it.options:
                choice, pics = recognise_choice(it, svg)
                for sev, code, msg in pics:
                    f.add(sev, it, code, msg)
                if choice is not None:
                    kind = choice.kind
                    nums = choice.nums
                    rights = [o['id'] for o in it.options if choice.right(o)]
                    if it.correct not in rights:
                        f.add('WRONG', it, 'answer', 'the marked answer %s is not right; right: %s' %
                              (it.correct, rights or 'none'))
                    extra = [r for r in rights if r != it.correct]
                    if extra:
                        f.add('WRONG', it, 'second-right', 'also right: %s' % ', '.join(extra))
                    if choice.inclusive:
                        incl = [o['id'] for o in it.options if o['id'] != it.correct and not choice.right(o)
                                and choice.inclusive(o)]
                        if incl:
                            f.add('WRONG', it, 'second-right', 'right by the definition (a square is a rectangle): %s, '
                                  'marked wrong%s' % (', '.join(incl), ' and tagged %s' % next(
                                      (o.get('misconception') for o in it.options if o['id'] in incl), '')))
                for o in it.options:
                    check_label(f, it, o)
            elif it.template == 'spot_error':
                kind = check_spot(f, it)
                cells = parse_cells(it.scene.get('cells') or []) or []
                nums = [t for t in cells if isinstance(t, (int, float))]
            elif it.template == 'number_line':
                kind, nums = 'number-line', check_number_line(f, it)
            elif it.template == 'balance':
                kind, nums = 'balance', check_balance(f, it)
            elif it.template == 'give_n':
                kind, nums = 'give', check_give(f, it)
            elif it.template == 'clock_set':
                kind, nums = 'clock', check_clock(f, it)
            elif it.template == 'shop_pay':
                kind, nums = 'shop', check_shop(f, it)
            elif it.template == 'match_pairs':
                kind, nums = 'match', check_match(f, it)
            elif it.template == 'sort_drag':
                kind, nums = 'sort', check_sort(f, it)
            elif it.template == 'build_pattern':
                kind, nums = 'build', check_build(f, it)
            elif it.template in ('trace', 'shape_builder'):
                kind = 'n/a'
        except (KeyError, IndexError, TypeError, ValueError, ZeroDivisionError) as e:
            f.add('UNCHECKED', it, 'error', 'the checker could not read the item (%s: %s)' % (type(e).__name__, e))
            kind = None
        if kind is None:
            f.add('UNCHECKED', it, 'no-rule', 'no rule of this checker understands the item (%s)' % it.template)
        else:
            counts['checked'] += 1
            counts['kind:' + kind] += 1
        # the band's limits
        limit = BAND_OPTIONS.get(it.band)
        if it.options and limit and len(it.options) > limit:
            f.add('RULE', it, 'options', '%d options; Band %s shows at most %d' % (len(it.options), it.band, limit))
        top = SKILL_MAX.get(it.skill, BAND_MAX.get(it.band, 10000))
        big = [v for v in nums if isinstance(v, (int, float)) and v > top]
        if big:
            f.add('RULE', it, 'range', '%s uses %s, above its range (%d)' % (it.skill, big, top))
        cap = max(top, BAND_MAX.get(it.band, 10000))
        far = [opt_value(o) for o in it.options if isinstance(opt_value(o), (int, float)) and
               (opt_value(o) > cap + 2 or opt_value(o) < 0)]
        if far and it.skill != 'NUM-B-08':
            f.add('RULE', it, 'range', 'options %s are outside Band %s' % (far, it.band))
        check_tags(f, it, records, catalogue, skills, choice)
    return f, counts


def table(rows, counts):
    lines = []
    sev = Counter(r[0] for r in rows)
    items_by = defaultdict(set)
    for s, i, *_ in rows:
        items_by[s].add(i)
    lines.append('check_maths: %d maths items, %d checked by a rule, %d unchecked' %
                 (counts['items'], counts['checked'], counts['items'] - counts['checked']))
    lines.append('%-10s %8s %8s' % ('severity', 'findings', 'items'))
    for s in SEVERITIES:
        lines.append('%-10s %8d %8d' % (s, sev[s], len(items_by[s])))
    codes = Counter((r[0], r[2]) for r in rows)
    lines.append('%-10s %-16s %8s' % ('severity', 'code', 'findings'))
    for (s, c), n in sorted(codes.items(), key=lambda kv: (SEVERITIES.index(kv[0][0]), -kv[1])):
        lines.append('%-10s %-16s %8d' % (s, c, n))
    return '\n'.join(lines)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--dir', default=STARTER, help='the folder of activity, skill and misconception files')
    ap.add_argument('--band', choices=('A', 'B', 'C'))
    ap.add_argument('--strict', action='store_true', help='ambiguous and unchecked items fail too (the Band C gate)')
    ap.add_argument('--list', action='store_true', help='print every finding')
    ap.add_argument('--json', help='also write the findings to this file')
    args = ap.parse_args(argv)
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except (AttributeError, ValueError):
        pass
    rows, counts = check(args.dir, args.band)
    rows.sort(key=lambda r: (SEVERITIES.index(r[0]), str(r[1]), r[2]))
    if args.list:
        for s, i, c, m in rows:
            print('%-9s %-24s %-14s %s' % (s, i, c, m))
        print()
    print(table(rows, counts))
    if args.json:
        with open(args.json, 'w', encoding='utf-8') as fh:
            json.dump([dict(zip(('severity', 'id', 'code', 'message'), r)) for r in rows], fh, ensure_ascii=False,
                      indent=1)
    fail = STRICT_FAILING if args.strict else FAILING
    return 1 if any(r[0] in fail for r in rows) else 0


if __name__ == '__main__':
    sys.exit(main())
