"""The spoken hint lines of the Band A `tap_answer` activities, written to say what the hint picture shows (board B-40).

    imported by tools/author.py (`activity()` calls `retext()` for every finished tap_answer activity of Band A)

B-40 gave every family of `tap_answer` its own picture at each hint level (app/lib/play/hints/tap_plans.dart; the plan is
docs/curriculum/b40-visual-hint-ladder.md, the pictures docs/design/b40-visual-hints.md). A hint line must describe exactly
what is drawn, at the moment it is drawn, so the line follows the picture, and the picture follows the activity's own data.
`tap_class()` therefore reads an activity the way `tapHintPlan()` does (the same family table, the same fall-backs) and
names what each level draws; `retext()` then gives that level its line.

The rules of the text editor (hebrew-notes.md, B-40):
  * level 1 never counts aloud (design spec F2): it names where to look, or stays the replay of the question;
  * level 2 says what the new picture is (the colour on its own, the shape without colour, the empty square, the
    pairing lines...), in a short line that is shared by the whole family so that one clip serves them all;
    a number is said only where the picture counts (hands, hops, numbered places);
  * level 3 may name the answer, because the plan lets the answer be the LAST step of the demonstration (plan section 1,
    T2). A line that opens with the bare answer ("this is a red ball") would name it before the hand has moved, so such a
    line gets one process clause in front ("the colour goes over all of them and stops at the one that fits"). A line
    that is already a process (it counts, reads the row, walks the story) is kept;
  * addressed in the plural or the impersonal ("we look", "looking"); full nikud; no gender guessed;
  * every text stays `needs-editor` until the owner has read it (the master table holds them as `proposed`).
"""
import re

_MARKS = re.compile('[֑-ׇ]')


def plain(s):
    return _MARKS.sub('', s)


# ---------------------------------------------------------------- the family of each Band A tap_answer skill
# (app/lib/content/hint_ladder.dart `_tapFamilyOfSkill`; NUM-A-07 with a numeral on the stage is `numerals`)
FAMILY = {
    'NUM-A-03': 'count', 'NUM-A-04': 'count', 'NUM-A-07': 'count', 'NUM-A-14': 'count', 'MATH-A-06': 'count',
    'CS-A-04': 'count', 'NUM-A-08': 'numerals', 'NUM-A-01': 'sequence', 'NUM-A-02': 'sequence', 'NUM-A-13': 'sequence',
    'NUM-A-11': 'compare', 'NUM-A-12': 'compare', 'MATH-A-07': 'compare', 'MATH-A-01': 'add', 'MATH-A-02': 'add',
    'COL-A-01': 'colour', 'COL-A-02': 'colour', 'COL-A-03': 'colour', 'COL-A-04': 'colour', 'COL-A-05': 'colour',
    'COL-A-06': 'colour', 'COL-A-07': 'colour', 'SHP-A-01': 'shapes', 'SHP-A-02': 'shapes', 'SHP-A-03': 'shapes',
    'SHP-A-04': 'shapes', 'SHP-A-05': 'shapes', 'SHP-A-07': 'shapes', 'SHP-A-08': 'shapes', 'SHP-A-10': 'shapes',
    'LOG-A-04': 'pattern', 'LOG-A-06': 'pattern', 'LOG-A-07': 'pattern', 'LOG-A-10': 'pattern', 'LOG-A-01': 'same',
    'LOG-A-02': 'same', 'LOG-A-03': 'same', 'LOG-A-09': 'same', 'CS-A-01': 'time', 'CS-A-05': 'time',
    'LOG-A-08': 'time', 'MATH-A-05': 'time', 'MATH-A-04': 'measure',
}
COLOURS = {'red', 'blue', 'yellow', 'green', 'orange', 'purple', 'pink', 'brown', 'black', 'white', 'grey', 'gray'}


def _colour_of(ref):
    if not ref:
        return None
    last = ref.split('_')[-1]
    return last if last in COLOURS else None


def _sprite_of(o):
    return o.get('sprite') or (o.get('set') or {}).get('sprite')


def period_of(row):
    """The smallest unit that repeats through the known cells of a row, or None (tap_plans.dart `periodOf`)."""
    for p in range(1, len(row) // 2 + 1):
        fits = True
        for i in range(len(row)):
            if not fits:
                break
            for j in range(i + p, len(row), p):
                if row[i] != '?' and row[j] != '?' and row[i] != row[j]:
                    fits = False
                    break
        if fits:
            return p
    return None


def tap_class(d):
    """(family, what level 1 draws, what level 2 draws, what level 3 does) for a tap_answer activity, or None."""
    sk = d['skills'][0]['id']
    sc, answer = d['scene'], d['answer']
    fam = 'numerals' if (sk == 'NUM-A-07' and sc.get('numeral') is not None) else FAMILY.get(sk)
    if fam is None:
        return None
    opts = answer['options']
    right = next(o for o in opts if o['id'] == answer['correct'])
    n = len(opts)
    q = plain(d['prompt']['caption'][0]['v'])
    grp, grp2, row, num = sc.get('group'), sc.get('group2'), sc.get('row') or [], sc.get('numeral')
    look = 'veil' if (grp or grp2 or row or num is not None) else 'tiles'
    if fam == 'colour':
        c = _colour_of(_sprite_of(right)) or _colour_of((grp or {}).get('sprite'))
        return (fam, look, 'swatch' if c else 'card', 'swatch' if c else 'walk')
    if fam == 'shapes':
        if sk == 'SHP-A-07':
            ball = [o for o in opts if 'sphere' in (o.get('sprite') or '') or 'ball' in (o.get('sprite') or '')]
            box = [o for o in opts if 'box' in (o.get('sprite') or '')]
            if n != 2 or not ball or not box:
                return (fam, look, 'card', 'walk')
            return (fam, look, 'stack' if 'לערם' in q else 'push', 'walk')
        if sk == 'SHP-A-08':
            where = (right.get('sprite') or '').replace('asset:pos_', '')
            if where not in ('above', 'on', 'next', 'under', 'in'):
                return (fam, look, 'card', 'walk')
            return (fam, look, 'pos_under_table' if 'שלחן' in q else 'pos_' + where, 'walk')
        nm = (_sprite_of(right) or '').replace('asset:', '')
        if sk == 'SHP-A-10':
            kind = 'curved' if ('curved' in nm or 'circle' in nm) else 'straight'
        else:
            kind = ('circle' if ('circle' in nm or nm == 'plate') else 'square' if 'square' in nm else
                    'rect' if ('rect' in nm or nm == 'window') else 'triangle' if ('triangle' in nm or nm == 'sign') else None)
        if kind is None:
            return (fam, look, 'card', 'walk')
        return (fam, look, 'ghost_' + kind + ('_turn' if sk == 'SHP-A-03' else ''), 'ghost')
    if fam == 'same':
        if row:
            return (fam, 'veil', 'links', 'oddwalk')
        if (grp or {}).get('sprite'):
            return (fam, look, 'model', 'model')
        return (fam, look, 'card', 'walk')
    if fam == 'compare':
        on_stage = bool(grp and grp2)
        sets = [o for o in opts if o.get('set')]
        if not on_stage and len(sets) != 2:
            return (fam, look, 'card', 'walk')
        return (fam, 'veil' if on_stage else 'rows', 'pairs', 'pairs')
    if fam == 'count':
        if row:
            return (fam, 'veil', 'hops', 'hops')
        if not grp:
            return (fam, 'tiles', 'card', 'walk')
        if right.get('numeral') == 0:
            return (fam, 'veil', 'empty_frame', 'frame_zero')
        return (fam, 'light', 'hands', 'count')
    if fam == 'sequence':
        if sk == 'NUM-A-13':
            return (fam, 'tiles', 'badges', 'ordinal')
        c = right.get('numeral')
        if c is None or ('לפני' not in q and 'אחרי' not in q):
            return (fam, look, 'card', 'walk')
        return (fam, 'gap', 'path', 'path')
    if fam == 'pattern':
        if not row:
            return (fam, look, 'card', 'walk')
        yes_no = all(o.get('sprite') in ('asset:tick', 'asset:cross') for o in opts)
        p = period_of(row)
        return (fam, 'light', 'floor' if (p is None and not yes_no) else 'brackets', 'rowdemo')
    if fam == 'time':
        return (fam, 'veil', 'numbers', 'rowdemo') if row else (fam, 'tiles', 'slots', 'slotwalk')
    if fam == 'add':
        if not grp:
            return (fam, look, 'card', 'walk')
        return (fam, 'veil', 'hands_add' if grp2 else 'hands_take', 'adddemo')
    if fam == 'numerals':
        nn = num if num is not None else right.get('numeral')
        if nn is None or nn < 1:
            return (fam, look, 'card', 'walk')
        return (fam, 'dots' if num is not None else 'tiles', 'path5', 'build' if num is not None else 'pathwalk')
    if fam == 'measure':
        words = set(re.split('[^א-ת]+', q))
        if 'כבד' in words or 'קל' in words:
            return (fam, look, 'card', 'walk')
        return (fam, 'aligned', 'cubes', 'walk')
    return None


# ---------------------------------------------------------------- level 1
GAP_H1 = ('vo:hint.gap.h1', 'נִסְתַּכֵּל עַל הַמִּסְפָּר, וְעַל הַמָּקוֹם הָרֵיק לְיָדוֹ.')
ROWS_H1 = ('vo:hint.rows.h1', 'שְׁתֵּי הַקְּבוּצוֹת עוֹמְדוֹת בִּשְׁתֵּי שׁוּרוֹת, זוֹ מֵעַל זוֹ.')

# ---------------------------------------------------------------- level 2 (one shared line for a picture)
L2 = {
    # the colour on its own, as a paint dab (P9): colour naming, matching and the colour of the things of the world
    'swatch': ('vo:hint.swatch.h2', 'הִנֵּה רַק הַצֶּבַע. נִסְתַּכֵּל עָלָיו טוֹב.'),
    # the shape on its own, as a dashed outline without colour (P9)
    'ghost_circle': ('vo:hint.ghost.h2', 'הִנֵּה רַק הַצּוּרָה, בְּלִי צֶבַע. נִסְתַּכֵּל עָלֶיהָ טוֹב.'),
    'ghost_turn': ('vo:hint.ghost_turn.h2', 'הַצּוּרָה מִסְתּוֹבֶבֶת, וְהִיא עֲדַיִן אוֹתָהּ צוּרָה.'),
    'ghost_curved': ('vo:hint.ghost_curved.h2', 'הִנֵּה רַק קַו עָקֹם. נִסְתַּכֵּל עָלָיו טוֹב.'),
    'ghost_straight': ('vo:hint.ghost_straight.h2', 'הִנֵּה רַק קַו יָשָׁר. נִסְתַּכֵּל עָלָיו טוֹב.'),
    # the model of the question on its own (same thing; where does it go)
    'model': ('vo:hint.sample.h2', 'הִנֵּה הַדּוּגְמָה. נִסְתַּכֵּל עָלֶיהָ טוֹב.'),
    'model_pair': ('vo:hint.sample_pair.h2', 'מְחַפְּשִׂים זוּג לַתְּמוּנָה הַזֹּאת. נִסְתַּכֵּל עָלֶיהָ טוֹב.'),
    # the odd one out: a link between every two neighbours, none of them marked
    'links': ('vo:hint.links.h2', 'קַו מְחַבֵּר בֵּין כׇּל שְׁנֵי שְׁכֵנִים. נַשְׁוֶה אוֹתָם.'),
    # compare: one line from each thing to its partner, the ones without a partner glow
    'pairs': ('vo:hint.pairs.h2', 'מְחַבְּרִים אֶחָד לְאֶחָד בְּקַוִּים. מִי נִשְׁאָר בְּלִי זוּג?'),
    # a number sequence: the number path with the empty square
    'path': ('vo:hint.path.h2', 'הַמִּסְפָּרִים עוֹמְדִים בְּשׁוּרָה, מֵאַחַת. נִסְתַּכֵּל עַל הָרִבּוּעַ הָרֵיק.'),
    # a pattern: a line under every unit that repeats; a row that grows stands on one line
    'brackets': ('vo:hint.core.h2', 'כׇּל חֵלֶק שֶׁחוֹזֵר מְסֻמָּן בְּקַו. נִסְתַּכֵּל אֵיךְ הוּא חוֹזֵר.'),
    'floor': ('vo:hint.floor.h2', 'כֻּלָּם עוֹמְדִים עַל אוֹתוֹ קַו. נַשְׁוֶה כׇּל שָׁכֵן לַשָּׁכֵן שֶׁלּוֹ.'),
    # count on / take away: the hands show how many there were
    'hands_add': ('vo:hint.hands_add.h2', 'הָאֶצְבָּעוֹת מַרְאוֹת כַּמָּה הָיָה, וְסוֹפְרִים אֶת הַחֲדָשִׁים אֶחָד אֶחָד.'),
    'hands_take': ('vo:hint.hands_take.h2', 'הָאֶצְבָּעוֹת מַרְאוֹת כַּמָּה הָיָה, וּמְסַמְּנִים מַה לּוֹקְחִים.'),
    # measure: a stick of cubes along each, from the same start line
    'cubes': ('vo:hint.cubes.h2', 'מוֹדְדִים כׇּל אֶחָד בְּקֻבִּיּוֹת, מֵאוֹתוֹ קַו.'),
    # CS-A-04: the steps from the robot to the flag are the hops between the squares
    'hops': ('vo:hint.hops.h2', 'כׇּל צַעַד הוּא קְפִיצָה אַחַת אֶל הַמִּשְׁבֶּצֶת הַבָּאָה.'),
    # zero: an empty ten-frame
    'empty_frame': ('vo:hint.empty_frame.h2', 'הַמִּשְׁבְּצוֹת רֵיקוֹת — אֵין כְּלוּם לִסְפֹּר.'),
    # SHP-A-07: the question's own two solids are pushed, or one more of each is put on top (watch what happens)
    'push': ('vo:hint.push.h2', 'נִרְאֶה מַה קּוֹרֶה כְּשֶׁדּוֹחֲפִים אֶת שְׁנֵיהֶם.'),
    'stack': ('vo:hint.stack.h2', 'נִרְאֶה מַה קּוֹרֶה כְּשֶׁשָּׂמִים עוֹד אֶחָד מֵעַל כׇּל אֶחָד.'),
    # SHP-A-08: a small toy and a box (or the table); where is the toy
    'pos_above': ('vo:hint.pos_above.h2', 'אֵיפֹה הַבַּרְוָז? מֵעַל הַקֻּפְסָה.'),
    'pos_on': ('vo:hint.pos_on.h2', 'אֵיפֹה הַבַּרְוָז? עַל הַקֻּפְסָה.'),
    'pos_next': ('vo:hint.pos_next.h2', 'אֵיפֹה הַבַּרְוָז? לְיַד הַקֻּפְסָה.'),
    'pos_in': ('vo:hint.pos_in.h2', 'אֵיפֹה הַבַּרְוָז? בְּתוֹךְ הַקֻּפְסָה.'),
    'pos_under_table': ('vo:hint.pos_under.h2', 'אֵיפֹה הַבַּרְוָז? מִתַּחַת לַשֻּׁלְחָן.'),
}
ORDER_WORDS = ['אַחַת', 'שְׁתַּיִם', 'שָׁלוֹשׁ', 'אַרְבַּע', 'חָמֵשׁ']


def l2_line(c, d, F, count_words):
    """(voice id, text) for level 2 of an activity whose class is [c], or None when the line stays as it is."""
    kind = c[2]
    sk = d['skills'][0]['id']
    if kind == 'hands':
        # one finger for each thing that is lit, the count said as the hands rise; an item whose second hint is still the
        # generic look-at-all line (the coins of MATH-A-06) gets the same line as the other counts
        if 'אֶצְבָּעוֹת' in d['hints'][1]['caption'][0]['v']:
            return None
        n = next(o for o in d['answer']['options'] if o['id'] == d['answer']['correct'])['numeral']
        return ('vo:%s.h2' % d['id'], 'נִסְפֹּר עִם הָאֶצְבָּעוֹת: %s.' % count_words(n))
    if kind in ('card', 'badges'):
        return None  # the "?" card (heavy and light wait for the seesaw); the badges keep their lines
    if kind.startswith('ghost_'):
        shape = kind.split('_')[1]
        if shape in ('curved', 'straight'):
            return L2['ghost_' + shape]
        return L2['ghost_turn'] if kind.endswith('_turn') else L2['ghost_circle']
    if kind == 'model':
        return L2['model_pair'] if sk == 'LOG-A-09' else L2['model']
    if kind == 'path5':
        n = d['scene'].get('numeral')
        if n is None:
            n = next(o for o in d['answer']['options'] if o['id'] == d['answer']['correct'])['numeral']
        text = ('קוֹפְצִים אֶל הַמִּסְפָּר הָרִאשׁוֹן: אַחַת.' if n == 1
                else 'קוֹפְצִים עַל הַמִּסְפָּרִים, מֵאַחַת עַד %s.' % F[n])
        return ('vo:hint.path5.%d.h2' % n, text)
    if kind in ('numbers', 'slots'):
        m = len(d['scene'].get('row') or []) if kind == 'numbers' else len(d['answer']['options'])
        return ('vo:hint.order.%d.h2' % m,
                'הַמִּסְפָּרִים מַרְאִים אֶת הַסֵּדֶר: %s.' % ', '.join(ORDER_WORDS[:m]))
    return L2[kind]


# ---------------------------------------------------------------- level 3: a process clause in front of a bare answer
L3_PREFIX = {
    'swatch': 'הַצֶּבַע עוֹבֵר עַל כֻּלָּם, וְעוֹצֵר אֵצֶל הַמַּתְאִים.',
    'ghost': 'הַצּוּרָה עוֹבֶרֶת עַל כֻּלָּם, וְעוֹצֶרֶת אֵצֶל הַמַּתְאִים.',
    'ghost_line': 'הַקַּו עוֹבֵר עַל כֻּלָּם, וְעוֹצֵר אֵצֶל הַמַּתְאִים.',
    'model': 'הַדּוּגְמָה עוֹבֶרֶת עַל כֻּלָּם, וְעוֹצֶרֶת אֵצֶל הַמַּתְאִים.',
    'walk': 'הַיָּד עוֹבֶרֶת עַל כֻּלָּם, וְעוֹצֶרֶת אֵצֶל הַמַּתְאִים.',
    'row': 'קוֹרְאִים מֵהַהַתְחָלָה עַד הַמָּקוֹם הֶחָסֵר.',
}
# Texts that other code builds (author.py kinds): the beginnings, for the review table
KIND_PREFIXES = ('מְחַבְּרִים אֶחָד לְאֶחָד.', 'מַתְחִילִים מֵהַדֶּגֶל:', 'קוֹפְצִים וְסוֹפְרִים:', 'סוֹפְרִים אֶת הַמַּטְבְּעוֹת:')
NOW = plain('עַכְשָׁו')


def is_bare(text):
    """True when four words or fewer come before "now your turn": that is an answer, not a worked example (plan section 2.4)."""
    head = plain(text).split(NOW)[0]
    return len([w for w in re.split(r'[\s—,.:!?]+', head) if w]) <= 4


def is_b40_text(text):
    """Whether [text] is one of the lines this module (or a B-40 kind in author.py) wrote: the review table holds them as proposed."""
    if text in _SHARED:
        return True
    if text.startswith(KIND_PREFIXES) or text.startswith('קוֹפְצִים עַל הַמִּסְפָּרִים, מֵאַחַת עַד'):
        return True
    if text.startswith(('הַמִּסְפָּרִים מַרְאִים אֶת הַסֵּדֶר:', 'קוֹפְצִים אֶל הַמִּסְפָּר הָרִאשׁוֹן:')):
        return True
    return any(text.startswith(p + ' ') for p in L3_PREFIX.values())


_SHARED = {t for _, t in L2.values()} | {GAP_H1[1], ROWS_H1[1]}


def retext(d, say, reword, F, count_words, own_h2=False):
    """Rewrites the hint lines of a finished Band A tap_answer activity [d] to say what its pictures show. [say] registers a voice
    line (a voice id has one text), [reword] gives an id already registered a new text; [F] and [count_words] are the generator's
    number words. An item that wrote its own second hint (`own_h2`) keeps it."""
    if d['template'] != 'tap_answer' or d['band'] != 'A':
        return
    c = tap_class(d)
    hints = {h['level']: h for h in d['hints']}
    if c is None or 2 not in hints:
        return

    def put(level, line):
        vo, text = line
        # the same id gets its new text (a per-activity line), else a shared line of the family
        hints[level].update(reword(vo, text) if vo == hints[level]['vo'] else say(vo, text))

    sk = d['skills'][0]['id']
    right = next(o for o in d['answer']['options'] if o['id'] == d['answer']['correct'])
    # level 1: a sequence names the gap (no counting aloud); a compare off the stage says the groups stand in two rows
    if c[1] == 'gap':
        put(1, GAP_H1)
    elif c[1] == 'rows':
        put(1, ROWS_H1)
    # level 2: the picture's line
    line = None if own_h2 else l2_line(c, d, F, count_words)
    if line:
        put(2, line)
    # level 3
    if 3 not in hints:
        return
    text = hints[3]['caption'][0]['v']
    on_tick = right.get('sprite') in ('asset:tick', 'asset:cross')
    new = None
    if c[3] == 'hops':
        n = right['numeral']
        new = 'קוֹפְצִים וְסוֹפְרִים: %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (count_words(n), F[n])
    elif sk == 'MATH-A-06' and c[3] == 'count' and is_bare(text):
        n = right['numeral']
        new = 'סוֹפְרִים אֶת הַמַּטְבְּעוֹת: %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (count_words(n), F[n])
    elif is_bare(text) and not on_tick:
        prefix = None
        if c[3] == 'swatch':
            prefix = L3_PREFIX['swatch']
        elif c[3] == 'ghost':
            prefix = L3_PREFIX['ghost_line' if sk == 'SHP-A-10' else 'ghost']
        elif c[3] == 'model' and sk == 'LOG-A-01':
            prefix = L3_PREFIX['model']
        elif c[3] == 'walk' and sk == 'SHP-A-07':
            prefix = L3_PREFIX['walk']
        elif c[3] == 'rowdemo' and sk == 'LOG-A-10':
            prefix = L3_PREFIX['row']
        if prefix:
            new = prefix + ' ' + text
    if new:
        put(3, (hints[3]['vo'] if hints[3]['vo'].startswith('vo:' + d['id'] + '.') else 'vo:%s.h3' % d['id'], new))
