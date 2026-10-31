"""The spoken hint lines of the `tap_answer` activities (Band A, and from part 4 Band B and the other templates), written to say what
the hint picture shows (board B-40). Part 4 (the bottom of this file) holds Band B and the other templates.

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
    'SHP-B-08': 'shapes',  # Band B: the one Band B skill that the Band A shapes plan serves (the others have plans of their own)
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
        if c and grp and all((o.get('sprite') or '').startswith('asset:ball_') for o in opts):
            # tap_plans.dart `_asksColourOfObject`: a thing of the world on the stage and plain balls to choose from; level 2 shows
            # an empty paint spot beside the thing (the paint of the right colour would be the answer)
            return (fam, look, 'paint_spot', 'swatch')
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
        if nm.startswith('solid_'):
            # tap_plans.dart `_shapeKind`: the outline of a solid as it is drawn on paper (a sphere is a circle)
            solid = nm[6:]
            if solid in ('sphere', 'cylinder', 'cone', 'pyramid', 'box'):
                return (fam, look, 'ghost_solid', 'ghost_solid')
            return (fam, look, 'card', 'walk')
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
    # COL-A-05 (a thing of the world and plain balls to choose from): an empty dashed paint spot beside the thing
    'paint_spot': ('vo:hint.paint_spot.h2', 'יֵשׁ מָקוֹם רֵיק לַצֶּבַע. אֵיזֶה צֶבַע מַתְאִים לָזֶה?'),
    # SHP-B-08 (and any solid): the solid as it is drawn on paper, only the lines
    'ghost_solid': ('vo:hint.solid_outline.h2', 'הִנֵּה הַגּוּף כְּמוֹ שֶׁמְּצַיְּרִים אוֹתוֹ, רַק קַוִּים. נִסְתַּכֵּל עָלָיו טוֹב.'),
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
    if kind == 'ghost_solid':
        return L2['ghost_solid']
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
    if text in _SHARED or text in _SHARED_B:
        return True
    if text.startswith(L3_B_PREFIXES) or any(rx.match(text) for rx in _TEMPLATES):
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
    if d['template'] != 'tap_answer':
        return retext_other(d, say, reword, F, count_words)
    if d['band'] != 'A' and d['skills'][0]['id'] not in FAMILY:
        return retext_b(d, say, reword, F, count_words, own_h2)
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
    if c[3] == 'ghost_solid':
        # SHP-B-08: the outline of the named solid goes over the options and stops at the one that fits (the name is the question's)
        name = re.sub(r'\?$', '', d['prompt']['caption'][0]['v']).split(' ', 1)[-1]
        new = SOLID_L3.fmt(name)
    if new:
        put(3, (hints[3]['vo'] if hints[3]['vo'].startswith('vo:' + d['id'] + '.') else 'vo:%s.h3' % d['id'], new))


# =====================================================================================================================
# B-40 part 4: Band B `tap_answer` (hints/tap_plans_b.dart) and the other templates (number line, clock, match, sort, build a pattern,
# shape builder, robot, spot the mistake). The same rules as above: a line says what is drawn, at the moment it is drawn.
# =====================================================================================================================

_TEMPLATES = []  # the shapes of the per-activity lines written below, so that the review table can tell which lines are new
_SHARED_B = set()


def S(vo, text):
    """A line shared by a family (one voice clip for all of it): registers its text as one of the new lines."""
    _SHARED_B.add(text)
    return (vo, text)


class T:
    """A per-activity line made of a fixed text and the pieces `{}` that the activity fills in. `tail` lines may carry the old
    "now your turn" ending of the activity. The shape is remembered for `is_b40_text`."""

    def __init__(self, text, tail=True):
        self.text = text
        rx = ''.join('.+?' if part == '{}' else re.escape(part) for part in re.split(r'(\{\})', text))
        if tail:
            rx += r'(?: עַכְשָׁו תּוֹרְכֶם.*)?'
        _TEMPLATES.append(re.compile('^' + rx + '$', re.S))

    def fmt(self, *a):
        out = self.text
        for x in a:
            out = out.replace('{}', x, 1)
        return out


NOW_RX = re.compile('ע[֑-ׇ]*כ[֑-ׇ]*ש[֑-ׇ]*ו[֑-ׇ]*\\s+ת[֑-ׇ]*ו')


def tail_of(old, default='עַכְשָׁו תּוֹרְכֶם.'):
    """The "now your turn — click on ..." ending of the old third hint, so that each item keeps its own ending."""
    m = NOW_RX.search(old)
    return old[m.start():] if m else default


def with_tail(body, old):
    return body + ' ' + tail_of(old)


def _right(d):
    return next(o for o in d['answer']['options'] if o['id'] == d['answer']['correct'])


def cubes(F, n):
    """"three cubes" with the number agreeing with the feminine noun (קֻבִּיָּה)."""
    if n == 0:
        return 'אֵין קֻבִּיּוֹת'
    if n == 1:
        return 'קֻבִּיָּה אַחַת'
    if n == 2:
        return 'שְׁתֵּי קֻבִּיּוֹת'
    return '%s קֻבִּיּוֹת' % F[n]


def plates(F, n):
    if n == 1:
        return 'צַלַּחַת אַחַת'
    if n == 2:
        return 'שְׁתֵּי צַלָּחוֹת'
    return '%s צַלָּחוֹת' % F[n]


_HATAF = {'ֲ': 'ַ', 'ֱ': 'ֶ', 'ֳ': 'ָ'}


def lamed(word):
    """לְ before a number word: לִ before a shva (לִשְׁתַּיִם), לַ before a hataf patah (לַחֲמֵשׁ), as in author.prefix."""
    marks = ''
    k = 1
    while k < len(word) and '֑' <= word[k] <= 'ׇ':
        marks += word[k]
        k += 1
    for hataf, full in _HATAF.items():
        if hataf in marks:
            return 'ל' + full + word
    if 'ְ' in marks and word[0] != 'י':
        return 'לִ' + word
    return 'לְ' + word


# ---------------------------------------------------------------- what a Band B question says in number words (prompt_numbers.dart)
_LETTERS = dict(a='א', b='ב', d='ד', v='ו', x='ח', y='י', k='כ', l='ל', m='מ', n='נ', e='ע', p='פ', r='ר', S='ש', T='ת', h='ה',
                s='ס')


def _w(latin):
    return ''.join(_LETTERS[c] for c in latin)


_UNITS = {_w('aps'): 0, _w('axT'): 1, _w('axd'): 1, _w('STym'): 2, _w('STyym'): 2, _w('Sny'): 2, _w('STy'): 2, _w('SlvS'): 3,
          _w('SlS'): 3, _w('SlvSh'): 3, _w('arbe'): 4, _w('arbeh'): 4, _w('xmS'): 5, _w('xmSh'): 5, _w('SS'): 6, _w('SSh'): 6,
          _w('Sbe'): 7, _w('Sbeh'): 7, _w('Smvnh'): 8, _w('TSe'): 9, _w('TSeh'): 9}
_TEN = {_w('eSr'), _w('eSrh')}
_TENS = {_w('eSrym'): 20, _w('SlvSym'): 30, _w('arbeym'): 40, _w('xmSym'): 50, _w('SSym'): 60, _w('Sbeym'): 70,
         _w('Smvnym'): 80, _w('TSeym'): 90}
_FINALS = str.maketrans('ךםןףץ', 'כמנפצ')


def numbers_in(prompt):
    """The numbers a prompt says as words, in order (prompt_numbers.dart `numbersIn`)."""
    letters = ''.join(ch if 'א' <= ch <= 'ת' else (' ' if not '֑' <= ch <= 'ׇ' else '') for ch in prompt).translate(_FINALS)
    tokens = [t for t in letters.split(' ') if t]
    vav = _w('v')
    bare = lambda t: t[1:] if len(t) > 2 and t.startswith(vav) else t
    out, i = [], 0
    while i < len(tokens):
        t = bare(tokens[i])
        if t in _UNITS:
            unit = _UNITS[t]
            teen = unit >= 1 and i + 1 < len(tokens) and tokens[i + 1] in _TEN
            out.append(10 + unit if teen else unit)
            if teen:
                i += 1
        elif t in _TEN:
            out.append(10)
        elif t in _TENS:
            v = _TENS[t]
            if i + 1 < len(tokens) and tokens[i + 1].startswith(vav):
                more = _UNITS.get(bare(tokens[i + 1]))
                if more is not None and more > 0:
                    v += more
                    i += 1
            out.append(v)
        i += 1
    return out


# ---------------------------------------------------------------- what a flat shape looks like (sprite_outline.dart `outlineOf`)
def outline_of(sprite):
    """(sides, closed, curved) of the picture [sprite] (`asset:shape_pentagon`), or None for one that has no corners (a circle, a solid)."""
    import os
    name = (sprite or '').replace('asset:', '')
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'content', 'starter', name + '.svg')
    if not name or not os.path.exists(path):
        return None
    svg = open(path, encoding='utf-8').read()
    m = re.search(r'<(polygon|polyline)\b[^>]*\bpoints="([^"]*)"', svg)
    if m:
        n = len(re.findall(r'-?\d+\.?\d*', m.group(2))) // 2
        closed = m.group(1) == 'polygon'
        return (n if closed else n - 1), closed, False
    if re.search(r'<rect\b', svg):
        return 4, True, False
    if re.search(r'<path\b[^>]*\bd="M\s*-?[\d.]+[\s,]+-?[\d.]+\s*Q', svg):
        return 11, True, True
    return None


# ---------------------------------------------------------------- what a spot-the-mistake row should have held (right_cell.dart)
def right_cell_of(cells, wrong):
    """The cell that should stand at [wrong] when the row alone tells (a sentence, a count, a repeat), else None."""
    if wrong < 0 or wrong >= len(cells):
        return None
    return _sentence_cell(cells, wrong) or _counting_cell(cells, wrong) or _repeating_cell(cells, wrong)


def _value_of(side):
    def n(c):
        return int(c[2:]) if c.startswith('n:') and c[2:].lstrip('-').isdigit() else None
    if len(side) == 1:
        return n(side[0])
    if len(side) != 3:
        return None
    a, b = n(side[0]), n(side[2])
    if a is None or b is None:
        return None
    return {'op:+': a + b, 'op:-': a - b}.get(side[1])


def _holds(cells):
    eq = cells.index('op:=')
    left, right = _value_of(cells[:eq]), _value_of(cells[eq + 1:])
    return left is not None and left == right


def _sentence_cell(cells, wrong):
    if 'op:=' not in cells:
        return None
    cand = ['op:+', 'op:-'] if cells[wrong].startswith('op:') else ['n:%d' % x for x in range(100)]
    fits = [c for c in cand if _holds(cells[:wrong] + [c] + cells[wrong + 1:])]
    return fits[0] if len(fits) == 1 else None


def _counting_cell(cells, wrong):
    if len(cells) < 3:
        return None
    parts = [re.match(r'^(.*?)(\d+)$', c) for c in cells]
    if any(p is None for p in parts):
        return None
    prefix = parts[0].group(1)
    if any(p.group(1) != prefix for p in parts):
        return None
    v = [int(p.group(2)) for p in parts]
    n = len(v)
    if 0 < wrong < n - 1:
        span = v[wrong + 1] - v[wrong - 1]
        if span % 2:
            return None
        step = span // 2
    elif wrong == n - 1:
        step = v[n - 2] - v[n - 3]
    else:
        step = v[2] - v[1]
    if step == 0:
        return None
    right = v[1] - step if wrong == 0 else v[wrong - 1] + step
    if right < 0 or right == v[wrong]:
        return None
    v[wrong] = right
    if any(v[i] - v[i - 1] != step for i in range(1, n)):
        return None
    return '%s%d' % (prefix, right)


def _repeating_cell(cells, wrong):
    n = len(cells)
    for p in range(1, n // 2 + 1):
        unit, follows = {}, True
        for i in range(n):
            if i == wrong:
                continue
            if unit.setdefault(i % p, cells[i]) != cells[i]:
                follows = False
                break
        if not follows:
            continue
        right = unit.get(wrong % p)
        return None if right is None or right == cells[wrong] else right
    return None


# ---------------------------------------------------------------- the shared lines (one clip for a whole family)
SEQ_H2 = S('vo:hint.path_b.h2', 'הַמִּסְפָּרִים עוֹמְדִים בְּשׁוּרָה, כׇּל אֶחָד בִּמְקוֹמוֹ. הַמִּסְפָּר מֵהַשְּׁאֵלָה מְסֻמָּן, וּלְיָדוֹ מָקוֹם רֵיק.')
SKIP_H2 = S('vo:hint.skip.h2', 'קוֹפְצִים מִמִּסְפָּר לַמִּסְפָּר הַבָּא בַּשּׁוּרָה. נִסְתַּכֵּל אֵיפֹה יֵשׁ מָקוֹם רֵיק.')
TEEN_H2 = S('vo:hint.teen.h2', 'לוּחַ אֶחָד מָלֵא, עֶשֶׂר מִשְׁבְּצוֹת. בַּלּוּחַ הַשֵּׁנִי יֵשׁ עוֹד כַּמָּה.')
TEEN10_H2 = S('vo:hint.teen10.h2', 'לוּחַ אֶחָד מָלֵא, עֶשֶׂר מִשְׁבְּצוֹת.')
TEEN20_H2 = S('vo:hint.teen20.h2', 'שְׁנֵי לוּחוֹת מְלֵאִים, בְּכׇל אֶחָד עֶשֶׂר מִשְׁבְּצוֹת.')
MIX2_H2 = S('vo:hint.mix2.h2', 'שְׁנֵי צְבָעִים, חֵץ, וְעִגּוּל רֵיק. אֵיזֶה צֶבַע יִהְיֶה בָּעִגּוּל?')
MIX1_H2 = S('vo:hint.mix1.h2', 'צֶבַע אֶחָד, עִגּוּל רֵיק, חֵץ, וְהַצֶּבַע שֶׁיָּצָא. אֵיזֶה צֶבַע חָסֵר בָּעִגּוּל?')
SHADES_H2 = S('vo:hint.shades.h2', 'הַצְּבָעִים עוֹמְדִים בְּשׁוּרָה, מֵהַבָּהִיר אֶל הַכֵּהֶה, וְחֵץ מַרְאֶה אֶת הַכִּוּוּן.')
BARS_H2 = S('vo:hint.bars.h2', 'לְכׇל מִסְפָּר יֵשׁ שׁוּרָה שֶׁל קֻבִּיּוֹת, וְכֻלָּן מַתְחִילוֹת מֵאוֹתוֹ קַו. נַשְׁוֶה אֶת הָאֹרֶךְ.')
COINBARS_H2 = S('vo:hint.coinbars.h2', 'לְיַד כׇּל מַטְבֵּעַ שׁוּרַת קֻבִּיּוֹת: קֻבִּיָּה לְכׇל שֶׁקֶל. נַשְׁוֶה אֶת הָאֹרֶךְ.')
PAIRS2_H2 = S('vo:hint.pairs2.h2', 'מְחַבְּרִים בְּקַו זוּג אַחַר זוּג. מִי נִשְׁאָר בְּלִי זוּג?')
CHART_H2 = S('vo:hint.chart.h2', 'לְיַד כׇּל עַמּוּד כָּתוּב כַּמָּה יֵשׁ בּוֹ.')
CHART_PLATES_H2 = S('vo:hint.chart_plates.h2', 'לְיַד כׇּל צַלַּחַת כָּתוּב כַּמָּה יֵשׁ עָלֶיהָ.')
CUBES_OVER_H2 = S('vo:hint.cubes_over.h2', 'מֵעַל כׇּל מִסְפָּר עוֹמְדוֹת קֻבִּיּוֹת, כְּמוֹ שֶׁהַמִּסְפָּר אוֹמֵר.')
CUBES_WHOLE_H2 = S('vo:hint.cubes_whole.h2', 'מֵעַל הַכֹּל יֵשׁ קֻבִּיּוֹת וּמְקוֹמוֹת רֵיקִים. הַקֻּבִּיּוֹת הֵן מַה שֶּׁכְּבָר יֵשׁ.')
PARTS_MISSING_H2 = S('vo:hint.parts_missing.h2', 'הַקֻּבִּיּוֹת הַמְּלֵאוֹת הֵן מַה שֶּׁכְּבָר יֵשׁ. הַמְּקוֹמוֹת הָרֵיקִים הֵם מַה שֶּׁחָסֵר.')
PARTS_SUM_H2 = S('vo:hint.parts_sum.h2', 'שְׁנֵי הַחֲלָקִים בְּשׁוּרָה אַחַת, זֶה לְיַד זֶה. כַּמָּה קֻבִּיּוֹת בַּכֹּל?')
TOTEN_H2 = S('vo:hint.toten.h2', 'הַמִּשְׁבְּצוֹת הָרֵיקוֹת נִדְלָקוֹת אַחַת אַחַת. אֵלֶּה מַה שֶּׁחָסֵר עַד עֶשֶׂר.')
WEEK_H2 = S('vo:hint.week.h2', 'הַיָּמִים עוֹמְדִים בְּשׁוּרָה, לְפִי הַסֵּדֶר. הַיּוֹם מֵהַשְּׁאֵלָה מְסֻמָּן, וְיֵשׁ מָקוֹם רֵיק.')
HOUR_H2 = S('vo:hint.hour.h2', 'קַו מְנֻקָּד מַמְשִׁיךְ אֶת הַמַּחֲוָג הַקָּצָר עַד קְצֵה הַשָּׁעוֹן, וְשָׁם עִגּוּל. לְמַעְלָה מְסֻמָּן שְׁתֵּים עֶשְׂרֵה.')
SIDES_NAMED_H2 = S('vo:hint.sides_named.h2', 'הִנֵּה הַצּוּרָה מֵהַשְּׁאֵלָה. הַצְּלָעוֹת שֶׁלָּהּ נִדְלָקוֹת אַחַת אַחַת.')
SIDES_H2 = S('vo:hint.sides.h2', 'הַצְּלָעוֹת שֶׁל הַצּוּרָה נִדְלָקוֹת אַחַת אַחַת, מִנְּקֻדָּה אַחַת.')
STICKS_H2 = S('vo:hint.sticks.h2', 'לְכׇל צוּרָה יֵשׁ מַקְלוֹת: מַקֵּל לְכׇל צֶלַע, בָּאֹרֶךְ שֶׁלָּהּ.')
STAMPS_H2 = S('vo:hint.stamps.h2', 'מִתַּחַת לְכׇל גּוּף נִרְאֵית הַצּוּרָה שֶׁהוּא מַשְׁאִיר בַּחוֹל.')
LINE_HOP_H2 = S('vo:hint.line_hop.h2', 'הַצְּפַרְדֵּעַ קוֹפֶצֶת קְפִיצָה אַחַת קָדִימָה. קַו מְנֻקָּד מְסַמֵּן אֶת הַקְּפִיצָה, וּמֵעָלָיו הַמִּסְפָּר אַחַת.')
LINE_HOP_BACK_H2 = S('vo:hint.line_hop_back.h2', 'הַצְּפַרְדֵּעַ קוֹפֶצֶת קְפִיצָה אַחַת אָחוֹרָה. קַו מְנֻקָּד מְסַמֵּן אֶת הַקְּפִיצָה, וּמֵעָלָיו הַמִּסְפָּר אַחַת.')
LINE_PLACE_H2 = S('vo:hint.line_place.h2', 'הַצְּפַרְדֵּעַ מַתְחִילָה מֵאֶפֶס וְקוֹפֶצֶת קְפִיצָה אַחַת. קַו מְנֻקָּד מְסַמֵּן אֶת הַקְּפִיצָה, וּמֵעָלָיו הַמִּסְפָּר אַחַת.')
CLOCK_H1_TEXT = 'הַמַּחֲוָג הַקָּצָר וְהָעָבֶה אוֹמֵר אֶת הַשָּׁעָה.'
CLOCK_H1 = ('vo:hint.clock.h1', CLOCK_H1_TEXT)  # the old second hint: it describes what level 1 draws (the short hand is lit)
CLOCK_H2 = S('vo:hint.clock.h2', 'הַמִּסְפָּר שֶׁעַל הַכַּרְטִיס וְאוֹתוֹ מִסְפָּר עַל הַשָּׁעוֹן מְסֻמָּנִים בְּאוֹתוֹ עִגּוּל.')
MATCH_DOTS_H2 = S('vo:hint.match_dots.h2', 'מִתַּחַת לַמִּסְפָּר יֵשׁ נְקֻדּוֹת — כַּמָּה שֶׁהוּא אוֹמֵר.')
MATCH_COIN_H2 = S('vo:hint.match_coin.h2', 'מִתַּחַת לַמַּטְבֵּעַ יֵשׁ נְקֻדּוֹת: נְקֻדָּה לְכׇל שֶׁקֶל.')
MATCH_PRINT_H2 = S('vo:hint.match_print.h2', 'מִתַּחַת לַגּוּף יֵשׁ צוּרָה בְּקַו מְנֻקָּד: מַה שֶּׁהוּא מַשְׁאִיר בַּחוֹל.')
SORT_PASS_H2 = S('vo:hint.sort_pass.h2', 'הַתְּמוּנָה הַבָּאָה עוֹבֶרֶת לְיַד כׇּל קְבוּצָה. נִסְתַּכֵּל לְאֵיזוֹ הִיא מַתְאִימָה.')
BUILD_UNIT_H2 = S('vo:hint.build_unit.h2', 'הַתְּמוּנָה שֶׁמֵּעַל הַמָּקוֹם הָרֵיק מֵאִירָה, וְקַו מְסַמֵּן כׇּל חֵלֶק שֶׁחוֹזֵר.')
BUILD_CELL_H2 = S('vo:hint.build_cell.h2', 'הַתְּמוּנָה שֶׁמֵּעַל הַמָּקוֹם הָרֵיק מֵאִירָה. מַעֲתִיקִים אוֹתָהּ.')
SB_GHOST_H2 = S('vo:hint.sb_ghost.h2', 'הַצֵּל שֶׁל הַמָּקוֹם הַבָּא צָף לְיַד הַתְּמוּנָה. נַשְׁוֶה אוֹתוֹ לַצּוּרוֹת שֶׁלְּמַטָּה.')
ROBOT_FOOT_H2 = S('vo:hint.robot_foot.h2', 'הַחֵץ הָרִאשׁוֹן דּוֹלֵק. הָרוֹבּוֹט הַשָּׁקוּף עוֹמֵד צַעַד אֶחָד הָלְאָה, וְעַל הַמִּשְׁבֶּצֶת הַמִּסְפָּר אַחַת.')
SPOT_RIGHT_H3 = S('vo:hint.spot_right.h3', 'הוֹלְכִים לְאֹרֶךְ הַשּׁוּרָה מֵהַהַתְחָלָה וְעוֹצְרִים אֵצֶל הַשּׁוֹנֶה. מֵעָלָיו מוֹפִיעָה הַתְּמוּנָה שֶׁצְּרִיכָה לִהְיוֹת שָׁם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו.')

# ---------------------------------------------------------------- the per-activity third hints (the process, the answer last)
HOP_AFTER = T('עוֹמְדִים עַל {} וְקוֹפְצִים קְפִיצָה אַחַת קָדִימָה: {}.')
HOP_BEFORE = T('עוֹמְדִים עַל {} וְקוֹפְצִים קְפִיצָה אַחַת אָחוֹרָה: {}.')
HOP_ADD = T('עוֹמְדִים עַל {}, מוֹסִיפִים אַחַת וְקוֹפְצִים קְפִיצָה אַחַת קָדִימָה: {}.')
HOP_TAKE = T('עוֹמְדִים עַל {}, לוֹקְחִים אַחַת וְקוֹפְצִים קְפִיצָה אַחַת אָחוֹרָה: {}.')
SKIP_L3 = T('קוֹפְצִים מִמִּסְפָּר לְמִסְפָּר: {}. עוֹד קְפִיצָה אַחַת — {}.')
TEEN10_L3 = T('בּוֹנִים: לוּחַ אֶחָד מָלֵא — עֶשֶׂר.')
TEEN20_L3 = T('בּוֹנִים: לוּחַ מָלֵא — עֶשֶׂר. עוֹד לוּחַ מָלֵא — עֶשֶׂר. יַחַד — עֶשְׂרִים.')
TEEN_L3 = T('בּוֹנִים: לוּחַ מָלֵא — עֶשֶׂר. בַּלּוּחַ הַשֵּׁנִי — {}. יַחַד — {}.')
MIX2_L3 = T('מְעָרְבְּבִים {} בָּעִגּוּל הָרֵיק — וְיוֹצֵא {}.')
MIX1_L3 = T('{} וְעוֹד צֶבַע נַעֲשִׂים {}. הַצֶּבַע שֶׁחָסֵר בָּעִגּוּל: {}.')
DARK_L3 = T('עוֹבְרִים מֵהַבָּהִיר אֶל הַכֵּהֶה: בָּהִיר, אֶמְצָעִי, כֵּהֶה. הַכֵּהֶה הוּא הָאַחֲרוֹן.')
LIGHT_L3 = T('עוֹבְרִים מֵהַבָּהִיר אֶל הַכֵּהֶה: בָּהִיר, אֶמְצָעִי, כֵּהֶה. הַבָּהִיר הוּא הָרִאשׁוֹן.')
BIG_L3 = T('{} לְמַעְלָה, {} לְמַטָּה. הַשּׁוּרָה הָאֲרֻכָּה יוֹתֵר — {}.')
SMALL_L3 = T('{} לְמַעְלָה, {} לְמַטָּה. הַשּׁוּרָה הַקְּצָרָה יוֹתֵר — {}.')
COIN_L3 = T('{}: {}. {}: {}. הַשּׁוּרָה הָאֲרֻכָּה יוֹתֵר — {}.')
CHART_MOST_L3 = T('סוֹפְרִים כׇּל עַמּוּד: {}. הָעַמּוּד הַגָּבוֹהַּ בְּיוֹתֵר הוּא זֶה שֶׁיֵּשׁ בּוֹ הֲכִי הַרְבֵּה.')
CHART_LEAST_L3 = T('סוֹפְרִים כׇּל עַמּוּד: {}. הָעַמּוּד הַנָּמוּךְ בְּיוֹתֵר הוּא זֶה שֶׁיֵּשׁ בּוֹ הֲכִי מְעַט.')
CHART_EXACT_L3 = T('סוֹפְרִים כׇּל עַמּוּד: {}. מְחַפְּשִׂים אֶת הָעַמּוּד שֶׁיֵּשׁ בּוֹ בְּדִיּוּק {}.')
CHART_TOTAL_L3 = T('סוֹפְרִים כׇּל עַמּוּד: {}. בְּסַךְ הַכֹּל — {}.')
CHART_DIFF_L3 = T('סוֹפְרִים אֶת שְׁנֵי הָעַמּוּדִים: {}, {}. בָּעַמּוּד הַגָּבוֹהַּ יֵשׁ עוֹד {}.')
PLATES_SUM_L3 = T('מוֹסִיפִים צַלַּחַת אַחַר צַלַּחַת: {}.')
PLATES_REV_L3 = T('מוֹסִיפִים צַלַּחַת אַחַר צַלַּחַת: {}. כְּשֶׁהִגַּעְנוּ {} — הָיוּ {}.')
PARTS_MISSING_L3 = T('{} כְּבָר יֵשׁ. סוֹפְרִים אֶת הַמְּקוֹמוֹת הָרֵיקִים: {}.')
PARTS_SUM_L3 = T('סוֹפְרִים אֶת כׇּל הַקֻּבִּיּוֹת בַּשּׁוּרָה: {}.')
ADD_L3 = T('{} וְעוֹד {}. בַּכֹּל — {}.')
ADD_ZERO_B_L3 = T('{}, וְלֹא מוֹסִיפִים כְּלוּם. בַּכֹּל — {}.')
ADD_ZERO_A_L3 = T('אֵין קֻבִּיּוֹת, וְעוֹד {}. בַּכֹּל — {}.')
ADD_ZEROS_L3 = T('אֵין קֻבִּיּוֹת, וְלֹא מוֹסִיפִים כְּלוּם. בַּכֹּל — אֶפֶס.')
TAKE_L3 = T('{}, וְלוֹקְחִים {}. נִשְׁאָרוֹת — {}.')
TAKE_ZERO_L3 = T('{}, וְלֹא לוֹקְחִים כְּלוּם. נִשְׁאָרוֹת — {}.')
TAKE_ALL_L3 = T('{}, וְלוֹקְחִים אֶת כֻּלָּן. לֹא נִשְׁאֲרָה אַף קֻבִּיָּה — אֶפֶס.')
KNOWN_NONE_L3 = T('{} כְּבָר יֵשׁ, וְאֵין מְקוֹמוֹת רֵיקִים. חָסֵר אֶפֶס.')
TOTEN_L3 = T('{} כְּבָר יֵשׁ. סוֹפְרִים אֶת הַמִּשְׁבְּצוֹת הָרֵיקוֹת: {}.')
WEEK_AFTER_L3 = T('הוֹלְכִים בַּשָּׁבוּעַ מִיּוֹם רִאשׁוֹן עַד {}. הַיּוֹם הַבָּא הוּא {}.')
WEEK_FIRST_L3 = T('מַתְחִילִים בְּיוֹם רִאשׁוֹן. הַיּוֹם הַבָּא הוּא {}.')
WEEK_WRAP_L3 = T('הוֹלְכִים בַּשָּׁבוּעַ עַד שַׁבָּת, וְאַחֲרֶיהָ מַתְחִילִים שׁוּב: יוֹם רִאשׁוֹן.')
WEEK_BEFORE_L3 = T('הוֹלְכִים בַּשָּׁבוּעַ מִיּוֹם רִאשׁוֹן עַד {}, וְחוֹזְרִים יוֹם אֶחָד אָחוֹרָה: {}.')
HOUR_L3 = T('סוֹפְרִים שָׁעוֹת סְבִיב הַשָּׁעוֹן, עַד הַמַּחֲוָג הַקָּצָר: {}.')
CORNERS_L3 = T('הַיָּד הוֹלֶכֶת מִפִּנָּה לְפִנָּה וְסוֹפֶרֶת צְלָעוֹת: {}. זֶה {}.')
CLOSED_L3 = T('הַיָּד הוֹלֶכֶת לְאֹרֶךְ הַצְּלָעוֹת וְחוֹזֶרֶת בְּדִיּוּק לְאוֹתָהּ נְקֻדָּה. הַצּוּרָה סְגוּרָה, וְהַצְּלָעוֹת יְשָׁרוֹת.')
OPEN_L3 = T('הַיָּד הוֹלֶכֶת לְאֹרֶךְ הַקַּוִּים, וְלֹא חוֹזֶרֶת לְאוֹתָהּ נְקֻדָּה. הַצּוּרָה פְּתוּחָה.')
CURVED_L3 = T('הַיָּד הוֹלֶכֶת מִסָּבִיב וְחוֹזֶרֶת לַהַתְחָלָה, אֲבָל הַקַּו עָקֹם — אֵין צְלָעוֹת יְשָׁרוֹת.')
STAMPS_L3 = T('מַטְבִּיעִים כׇּל גּוּף בַּחוֹל, וְרוֹאִים אֶת הַצּוּרָה שֶׁנִּשְׁאֶרֶת.')
CLUES_L3 = T('הוּא לֹא {} — הַצּוּרָה {} דּוֹהָה. הוּא לֹא {} — {} דּוֹהֶה. נִשְׁאֲרָה צוּרָה אַחַת.')
SOLID_L3 = T('הַקַּוִּים שֶׁל הַגּוּף עוֹבְרִים עַל כֻּלָּם, וְעוֹצְרִים אֵצֶל {}.')
JUMP_L3 = T('הַצְּפַרְדֵּעַ עוֹמֶדֶת עַל {} וְקוֹפֶצֶת קְפִיצָה אַחַר קְפִיצָה, וְסוֹפֶרֶת: {}. הִיא נוֹחֶתֶת עַל {}.')
JUMP_BACK_L3 = T('הַצְּפַרְדֵּעַ עוֹמֶדֶת עַל {} וְקוֹפֶצֶת אָחוֹרָה קְפִיצָה אַחַר קְפִיצָה, וְסוֹפֶרֶת: {}. הִיא נוֹחֶתֶת עַל {}.')
PLACE_L3 = T('הַצְּפַרְדֵּעַ קוֹפֶצֶת מֵאֶפֶס קְפִיצָה אַחַר קְפִיצָה, וְהַמִּסְפָּר שֶׁמֵּעָלֶיהָ סוֹפֵר: {}.')
CLOCK_L3 = T('לוֹחֲצִים עַל הַפְּלוּס וְהַמַּחֲוָג הַקָּצָר זָז, שָׁעָה אַחַר שָׁעָה: {}.')
# the old third hint stays and a process clause goes in front of it
STICKS_PREFIX = 'הַיָּד עוֹבֶרֶת עַל הַצּוּרוֹת וּמַשְׁוָה אֶת הַמַּקְלוֹת.'
COMMON_PREFIX = 'הַיָּד עוֹבֶרֶת עַל כֻּלָּם בְּסֵדֶר וּמַשְׁוָה בֵּין הַשְּׁכֵנִים.'
L3_B_PREFIXES = (STICKS_PREFIX + ' ', COMMON_PREFIX + ' ')

COLOUR_PLAIN = {'red': 'אָדֹם', 'blue': 'כָּחֹל', 'yellow': 'צָהֹב', 'green': 'יָרֹק', 'orange': 'כָּתֹם', 'purple': 'סָגֹל'}
COLOUR_FEM_DEF = {'red': 'הָאֲדֻמָּה', 'blue': 'הַכְּחֻלָּה', 'yellow': 'הַצְּהֻבָּה', 'green': 'הַיְרֻקָּה', 'orange': 'הַכְּתֻמָּה',
                  'purple': 'הַסְּגֻלָּה'}
SHAPE_PLAIN = {'circle': 'עִגּוּל', 'square': 'רִבּוּעַ', 'triangle': 'מְשֻׁלָּשׁ', 'rect': 'מַלְבֵּן'}
SHAPE_DEF = {'circle': 'הָעִגּוּל', 'square': 'הָרִבּוּעַ', 'triangle': 'הַמְּשֻׁלָּשׁ', 'rect': 'הַמַּלְבֵּן'}
CLUE1_H2 = {c: S('vo:hint.clue1.%s.h2' % c, 'הוּא לֹא %s — אָז הַצּוּרָה %s דּוֹהָה.' % (COLOUR_PLAIN[c], COLOUR_FEM_DEF[c]))
            for c in COLOUR_PLAIN}  # LOG-B-09, level 2: the first clue fades the shape that breaks it (one clip for each colour)
MIXES = {'red+yellow': 'orange', 'blue+yellow': 'green', 'blue+red': 'purple'}
COIN_LABEL = {'a10': 'עֶשֶׂר אֲגוֹרוֹת', 'h50': 'חֲצִי שֶׁקֶל', 's1': 'שֶׁקֶל אֶחָד', 's2': 'שְׁנֵי שְׁקָלִים',
              's5': 'חֲמִשָּׁה שְׁקָלִים', 's10': 'עֲשָׂרָה שְׁקָלִים'}
DAY_NAME = {1: 'יוֹם רִאשׁוֹן', 2: 'יוֹם שֵׁנִי', 3: 'יוֹם שְׁלִישִׁי', 4: 'יוֹם רְבִיעִי', 5: 'יוֹם חֲמִישִׁי', 6: 'יוֹם שִׁשִּׁי',
            7: 'שַׁבָּת'}


def _words(d):
    return set(re.split('[^א-ת]+', plain(d['prompt']['caption'][0]['v'])))


def _raw(d):
    return d['prompt']['caption'][0]['v']


def _sprite(o):
    return (o or {}).get('sprite') or ((o or {}).get('set') or {}).get('sprite')


# ---------------------------------------------------------------- Band B tap_answer: one function for each plan of tap_plans_b.dart
# Each returns (level 1 line or None, level 2 line or None, level 3 text or None); None keeps what the generator wrote.

def _given_for(d, c):
    """tap_plans.dart `_givenFor`: the number the question gives, from the answer [c]."""
    sk = d['skills'][0]['id']
    q = plain(_raw(d))
    row = d['scene'].get('row') or []
    if row:
        gap = row.index('?') if '?' in row else -1
        side = row[gap - 1] if gap > 0 else (row[1] if gap == 0 and len(row) > 1 else None)
        return int(side[2:]) if side and side.startswith('n:') and side[2:].isdigit() else None
    takes = sk == 'NUM-B-11' and 'מתוך' in q
    before = 'לפני' in q or takes
    after = 'אחרי' in q or (sk == 'NUM-B-11' and not takes)
    if not before and not after:
        return None
    return c + 1 if before else c - 1


def _seq(d, F, cw):
    c = _right(d).get('numeral')
    given = None if c is None else _given_for(d, c)
    if given is None:
        return None
    sk = d['skills'][0]['id']
    row = d['scene'].get('row') or []
    old = d['hints'][2]['caption'][0]['v']
    q = plain(_raw(d))
    if sk == 'NUM-B-11' and not row:
        line = (HOP_TAKE if given > c else HOP_ADD).fmt(F[given], F[c])
    else:
        line = (HOP_BEFORE if given > c else HOP_AFTER).fmt(F[given], F[c])
    return (None if row else GAP_H1, SEQ_H2, with_tail(line, old))


def _skip(d, F, cw):
    c = _right(d).get('numeral')
    said = numbers_in(_raw(d))
    if c is None or len(said) < 2:
        return None
    step = said[1] - said[0]
    if step <= 0 or said[-1] + step != c:
        return None
    line = SKIP_L3.fmt(', '.join(F[x] for x in said), F[c])
    return (None, SKIP_H2, with_tail(line, d['hints'][2]['caption'][0]['v']))


def _teens(d, F, cw):
    if d['scene'].get('row'):
        return _seq(d, F, cw)
    n = _right(d).get('numeral')
    if n is None or not 10 <= n <= 20:
        return None
    if n == 10:
        l2, l3 = TEEN10_H2, TEEN10_L3.fmt()
    elif n == 20:
        l2, l3 = TEEN20_H2, TEEN20_L3.fmt()
    else:
        l2, l3 = TEEN_H2, TEEN_L3.fmt(F[n - 10], F[n])
    return (None, l2, with_tail(l3, d['hints'][2]['caption'][0]['v']))


def _colour_name(sprite):
    m = re.search(r'ball_([a-z]+)$', sprite or '')
    return m.group(1) if m else None


def _mix(d, F, cw):
    sc = d['scene']
    first = _colour_name((sc.get('group') or {}).get('sprite'))
    second = _colour_name((sc.get('group2') or {}).get('sprite'))
    picked = _colour_name(_sprite(_right(d)))
    if not first or not picked:
        return None
    finds = second is not None
    made = picked if finds else MIXES.get('+'.join(sorted([first, picked])))
    if not made:
        return None
    old = d['hints'][2]['caption'][0]['v']
    if finds:
        both = COLOUR_PLAIN[first] + ' ' + F.vav(COLOUR_PLAIN[second])
        return (None, MIX2_H2, with_tail(MIX2_L3.fmt(both, COLOUR_PLAIN[made]), old))
    return (None, MIX1_H2, with_tail(MIX1_L3.fmt(COLOUR_PLAIN[first], COLOUR_PLAIN[made], COLOUR_PLAIN[picked]), old))


def _shades(d, F, cw):
    name = (_sprite(_right(d)) or '').replace('asset:', '')
    if not re.match(r'^shade_[a-z]+_\d$', name):
        return None
    row = d['scene'].get('row') or []
    if row:
        known = [r for r in row if re.search(r'_\d$', r)]
        return (None, SHADES_H2, None) if len(known) >= 2 else None
    q = plain(_raw(d))
    old = d['hints'][2]['caption'][0]['v']
    if 'כהה' in q:
        return (None, SHADES_H2, with_tail(DARK_L3.fmt(), old))
    if 'בהיר' in q:
        return (None, SHADES_H2, with_tail(LIGHT_L3.fmt(), old))
    return (None, SHADES_H2, None)


def _compare_bars(d, F, cw):
    vals = [o.get('numeral') for o in d['answer']['options']]
    if len(vals) != 2 or any(v is None for v in vals):
        return None
    q = plain(_raw(d))
    old = d['hints'][2]['caption'][0]['v']
    if 'גדול' in q:
        line = BIG_L3.fmt(cubes(F, vals[0]), cubes(F, vals[1]), F[max(vals)])
    elif 'קטן' in q:
        line = SMALL_L3.fmt(cubes(F, vals[0]), cubes(F, vals[1]), F[min(vals)])
    else:
        return (None, BARS_H2, None)
    return (None, BARS_H2, with_tail(line, old))


def _coin_bars(d, F, cw):
    codes = []
    for o in d['answer']['options']:
        m = re.search(r'coin_([sah])(\d+)$', o.get('sprite') or '')
        if not m or (m.group(1) + m.group(2)) not in COIN_LABEL:
            return None
        codes.append((m.group(1) + m.group(2), float(m.group(2)) if m.group(1) == 's' else float(m.group(2)) / 100))
    if len(codes) != 2:
        return None

    def bar(v):
        if v >= 1:
            return cubes(F, int(v))
        return 'חֲצִי קֻבִּיָּה' if v == 0.5 else 'פָּחוֹת מִקֻּבִּיָּה אַחַת'

    if 'יותר' not in plain(_raw(d)):
        return (None, COINBARS_H2, None)
    top = max(codes, key=lambda x: x[1])
    line = COIN_L3.fmt(COIN_LABEL[codes[0][0]], bar(codes[0][1]), COIN_LABEL[codes[1][0]], bar(codes[1][1]), COIN_LABEL[top[0]])
    return (None, COINBARS_H2, with_tail(line, d['hints'][2]['caption'][0]['v']))


def _pairs(d, F, cw):
    g = d['scene'].get('group')
    if not g or g.get('count', 0) < 2:
        return None
    return (None, PAIRS2_H2, None)  # the old third hint counts the pairs and says who is left: it follows the picture


def _chart(d, F, cw):
    chart = d['scene'].get('chart') or []
    if not chart:
        return None
    counts = [c['count'] for c in chart]
    sk = d['skills'][0]['id']
    old = d['hints'][2]['caption'][0]['v']
    right = _right(d)
    if sk == 'MATH-B-10':
        totals, run = [], 0
        for c in counts:
            run += c
            totals.append(run)
        listed = ', '.join(F[t] for t in totals)
        if d['checkType'] == 'reverse':
            c = right.get('numeral')
            if c != len(chart):
                return (None, CHART_PLATES_H2, None)
            line = PLATES_REV_L3.fmt(listed, lamed(F[totals[-1]]), plates(F, len(chart)))
        else:
            line = PLATES_SUM_L3.fmt(listed)
        return (None, CHART_PLATES_H2, with_tail(line, old))
    q = plain(_raw(d))
    listed = ', '.join(F[c] for c in counts)
    nums = numbers_in(_raw(d))
    if 'הכי הרבה' in q:
        line = CHART_MOST_L3.fmt(listed)
    elif 'הכי מעט' in q:
        line = CHART_LEAST_L3.fmt(listed)
    elif 'בדיוק' in q and nums:
        line = CHART_EXACT_L3.fmt(listed, F[nums[-1]])
    elif 'בסך הכל' in q:
        line = CHART_TOTAL_L3.fmt(listed, F[sum(counts)])
    elif 'יותר בעמוד הגבוה' in q and len(counts) == 2:
        line = CHART_DIFF_L3.fmt(F[max(counts)], F[min(counts)], F[max(counts) - min(counts)])
    else:
        return (None, CHART_H2, None)
    return (None, CHART_H2, with_tail(line, old))


def _whole_parts(d, F, cw):
    sc = d['scene']
    if sc.get('group'):
        return None  # the Band A add plan serves it
    said = numbers_in(_raw(d))
    c = _right(d).get('numeral')
    if len(said) < 2 or c is None:
        return None
    old = d['hints'][2]['caption'][0]['v']
    if c == said[0] - said[1]:
        if c == 0 or said[1] == 0:
            return (None, PARTS_MISSING_H2, None)
        return (None, PARTS_MISSING_H2, with_tail(PARTS_MISSING_L3.fmt(cubes(F, said[1]), cw(c)), old))
    if c == said[0] + said[1]:
        return (None, PARTS_SUM_H2, with_tail(PARTS_SUM_L3.fmt(cw(c)), old))
    return None


def _read_sentence(row, c):
    """tap_plans_b.dart `_readSentence`: the cells of `A op B = R` (or `R = A op B`) and which one is unknown."""
    if 'op:=' not in row or c is None:
        return None
    eq = row.index('op:=')
    left, right = list(range(eq)), list(range(eq + 1, len(row)))
    expr_left = len(left) == 3
    expr, single = (left, right) if expr_left else (right, left)
    if len(single) != 1 or len(expr) != 3 or not row[expr[1]].startswith('op:'):
        return None
    value, unknown = {}, None
    for i in (expr[0], expr[2], single[0]):
        if row[i] == '?':
            unknown = i
            value[i] = c
        elif row[i].startswith('n:') and row[i][2:].isdigit():
            value[i] = int(row[i][2:])
    if unknown is None or len(value) != 3:
        return None
    return dict(a=expr[0], b=expr[2], r=single[0], sign=expr[1], unknown=unknown, value=value)


def _sentence(d, F, cw):
    row = d['scene'].get('row') or []
    c = _right(d).get('numeral')
    s = _read_sentence(row, c)
    if s is None:
        return None
    av, bv, rv = s['value'][s['a']], s['value'][s['b']], s['value'][s['r']]
    addition = row[s['sign']] == 'op:+'
    old = d['hints'][2]['caption'][0]['v']
    if s['unknown'] == s['r']:
        if addition:
            if av == 0 and bv == 0:
                line = ADD_ZEROS_L3.fmt()
            elif bv == 0:
                line = ADD_ZERO_B_L3.fmt(cubes(F, av), F[rv])
            elif av == 0:
                line = ADD_ZERO_A_L3.fmt(cubes(F, bv), F[rv])
            else:
                line = ADD_L3.fmt(cubes(F, av), cubes(F, bv), F[rv])
        elif bv == 0:
            line = TAKE_ZERO_L3.fmt(cubes(F, av), F[rv])
        elif rv == 0:
            line = TAKE_ALL_L3.fmt(cubes(F, av))
        else:
            line = TAKE_L3.fmt(cubes(F, av), F[bv], F[rv])
        return (None, CUBES_OVER_H2, with_tail(line, old))
    known = bv if s['unknown'] == s['a'] else av
    whole = rv if addition else av
    if not addition or whole < known or known == 0:
        return None
    left = whole - known
    line = (KNOWN_NONE_L3.fmt(cubes(F, known)) if left == 0
            else PARTS_MISSING_L3.fmt(cubes(F, known), cw(left)))
    return (None, CUBES_WHOLE_H2, with_tail(line, old))


def _to_ten(d, F, cw):
    g = d['scene'].get('group')
    c = _right(d).get('numeral')
    if not g or c is None or c != 10 - g['count'] or g['count'] >= 10:
        return None
    line = TOTEN_L3.fmt(F[g['count']], cw(c))
    return (None, TOTEN_H2, with_tail(line, d['hints'][2]['caption'][0]['v']))


def _week(d, F, cw):
    m = re.search(r'day_(\d)$', _sprite(_right(d)) or '')
    w = _words(d)
    after = 'אחרי' in w or 'מחר' in w
    before = 'לפני' in w or 'אתמול' in w
    if not m or after == before:
        return None
    day = int(m.group(1))
    given = (7 if day == 1 else day - 1) if after else (1 if day == 7 else day + 1)
    old = d['hints'][2]['caption'][0]['v']
    if after:
        if given > day:
            line = WEEK_WRAP_L3.fmt()
        elif given == 1:
            line = WEEK_FIRST_L3.fmt(DAY_NAME[day])
        else:
            line = WEEK_AFTER_L3.fmt(DAY_NAME[given], DAY_NAME[day])
    elif given < day:
        return (None, WEEK_H2, None)
    else:
        line = WEEK_BEFORE_L3.fmt(DAY_NAME[given], DAY_NAME[day])
    return (None, WEEK_H2, with_tail(line, old))


def _hour(d, F, cw):
    g = d['scene'].get('group')
    m = re.search(r'clock_(\d+)$', (g or {}).get('sprite') or '')
    if not m or g.get('count', 1) != 1:
        return None
    hour = int(m.group(1))
    return (None, HOUR_H2, with_tail(HOUR_L3.fmt(cw(hour)), d['hints'][2]['caption'][0]['v']))


def _prompt_name(d):
    """The name a "where is the ...?" question asks for (with its article), or None."""
    parts = re.sub(r'\?$', '', _raw(d)).split(' ', 1)
    return parts[1] if len(parts) == 2 and plain(parts[0]) == 'איפה' else None


def _corners(d, F, cw):
    o = outline_of(_sprite(_right(d)))
    name = _prompt_name(d)
    if o is None or name is None or not o[1] or o[2]:
        return None
    return (None, SIDES_NAMED_H2, with_tail(CORNERS_L3.fmt(cw(o[0]), name), d['hints'][2]['caption'][0]['v']))


def _sides(d, F, cw):
    g = d['scene'].get('group')
    o = outline_of((g or {}).get('sprite'))
    if o is None or g.get('count', 1) != 1:
        return None
    if d['skills'][0]['id'] == 'SHP-B-02':
        return (None, SIDES_H2, None)  # the old third hint counts the sides one by one, as the numbers on the picture do
    line = CURVED_L3.fmt() if o[2] else (CLOSED_L3.fmt() if o[1] else OPEN_L3.fmt())
    return (None, SIDES_H2, with_tail(line, d['hints'][2]['caption'][0]['v']))


def _sticks(d, F, cw):
    outs = [outline_of(o.get('sprite')) for o in d['answer']['options']]
    if all(x is None for x in outs):
        return None
    return (None, STICKS_H2, STICKS_PREFIX + ' ' + d['hints'][2]['caption'][0]['v'])


def _stamps(d, F, cw):
    known = ('cylinder', 'cone', 'sphere', 'box', 'pyramid')
    if not all(((o.get('sprite') or '').replace('asset:solid_', '') in known and (o.get('sprite') or '').startswith('asset:solid_'))
               for o in d['answer']['options']):
        return None
    return (None, STAMPS_H2, with_tail(STAMPS_L3.fmt(), d['hints'][2]['caption'][0]['v']))


def _common(d, F, cw):
    if len(d['scene'].get('row') or []) < 2:
        return None
    return (None, L2['links'], COMMON_PREFIX + ' ' + d['hints'][2]['caption'][0]['v'].replace('נִסְתַּכֵּל עַל כֻּלָּם: ', ''))


def _clues(d, F, cw):
    rx = re.compile(r'shape_([a-z]+)_([a-z]+)$')
    parts = [rx.search(o.get('sprite') or '') for o in d['answer']['options']]
    if len(parts) != 3 or any(p is None for p in parts):
        return None
    ci = next(i for i, o in enumerate(d['answer']['options']) if o['id'] == d['answer']['correct'])
    right = parts[ci]
    by_colour = by_shape = None
    for i in range(3):
        if i == ci:
            continue
        if parts[i].group(1) == right.group(1) and parts[i].group(2) != right.group(2):
            by_colour = i
        if parts[i].group(2) == right.group(2) and parts[i].group(1) != right.group(1):
            by_shape = i
    if by_colour is None or by_shape is None:
        return None
    colour, shape = parts[by_colour].group(2), parts[by_shape].group(1)
    if colour not in COLOUR_PLAIN or shape not in SHAPE_PLAIN:
        return None
    l2 = CLUE1_H2[colour]
    l3 = CLUES_L3.fmt(COLOUR_PLAIN[colour], COLOUR_FEM_DEF[colour], SHAPE_PLAIN[shape], SHAPE_DEF[shape])
    return (None, l2, with_tail(l3, d['hints'][2]['caption'][0]['v']))


B_FAMILIES = {
    'NUM-B-01': _seq, 'NUM-B-02': _seq, 'NUM-B-03': _seq, 'NUM-B-11': _seq, 'NUM-B-08': _teens, 'NUM-B-17': _skip,
    'COL-B-01': _mix, 'COL-B-02': _shades, 'NUM-B-10': _compare_bars, 'MATH-B-16': _coin_bars, 'NUM-B-18': _pairs,
    'MATH-B-10': _chart, 'MATH-B-19': _chart, 'MATH-B-02': _whole_parts, 'MATH-B-03': _sentence, 'MATH-B-07': _sentence,
    'MATH-B-08': _sentence, 'MATH-B-18': _sentence, 'NUM-B-16': _sentence, 'MATH-B-06': _to_ten, 'MATH-B-14': _week,
    'MATH-B-15': _hour, 'SHP-B-01': _corners, 'SHP-B-02': _sides, 'SHP-B-04': _sides, 'SHP-B-03': _sticks,
    'SHP-B-09': _stamps, 'LOG-B-06': _common, 'LOG-B-09': _clues,
}


def _own_vo(d, hints, level):
    h = hints[level]
    return h['vo'] if h['vo'].startswith('vo:' + d['id'] + '.') else 'vo:%s.h%d' % (d['id'], level)


def _putter(hints, say, reword):
    def put(level, line):
        vo, text = line
        hints[level].update(reword(vo, text) if vo == hints[level]['vo'] else say(vo, text))
    return put


def retext_b(d, say, reword, F, count_words, own_h2=False):
    """Band B `tap_answer`: level 1 (only where the picture is a number and an empty place), level 2 (the new picture) and level 3
    (the process, the answer last) say what tap_plans_b.dart draws. A skill whose plan falls back to the generic card, or to
    the Band A family plan, keeps the lines it has."""
    fn = B_FAMILIES.get(d['skills'][0]['id'])
    hints = {h['level']: h for h in d['hints']}
    if fn is None or 2 not in hints or 3 not in hints:
        return
    got = fn(d, F, count_words)
    if got is None:
        return
    l1, l2, l3 = got
    put = _putter(hints, say, reword)
    if l1:
        put(1, l1)
    if l2 and not own_h2:
        put(2, l2)
    if l3:
        put(3, (_own_vo(d, hints, 3), l3))


# ---------------------------------------------------------------- the other templates (both bands)
def _first_pair_face(d):
    sc = d['scene']
    pairs = d['answer'].get('pairs') or []
    if not pairs:
        return None
    return next((f for f in sc.get('left', []) if f['id'] == pairs[0]['left']), None)


def _unit_length(row):
    for p in range(1, len(row) // 2 + 1):
        if all(row[i] == row[i - p] for i in range(p, len(row))):
            return p
    return None


def retext_other(d, say, reword, F, count_words, own_h2=False):
    """Number line, clock, match, sort, build a pattern, shape builder, robot and spot the mistake: the second (or third) hint says
    what the picture of B-40 parts 3 and 4 draws."""
    t = d['template']
    hints = {h['level']: h for h in d['hints']}
    if 2 not in hints:
        return
    put = _putter(hints, say, reword)
    sc, ans = d['scene'], d['answer']
    l1 = l2 = l3 = None
    if t == 'number_line':
        if sc.get('markerSprite') != 'asset:frog':
            return
        jump = ans['mode'] == 'jump'
        frm, target = sc.get('from', 0), ans['target']
        old = hints[3]['caption'][0]['v'] if 3 in hints else ''
        if jump:
            start, hops = sc['start'], sc['hops']
            if not hops or any((h > 0) != (hops[0] > 0) for h in hops):
                return
            back = hops[0] < 0
            one = start + (-1 if back else 1)
            if one == target or not frm <= one <= sc['to']:
                return
            l2 = LINE_HOP_BACK_H2 if back else LINE_HOP_H2
            total = sum(abs(h) for h in hops)
            l3 = with_tail((JUMP_BACK_L3 if back else JUMP_L3).fmt(F[start], count_words(total), F[target]), old)
        else:
            if frm != 0 or target <= 1:
                return
            l2 = LINE_PLACE_H2
            l3 = with_tail(PLACE_L3.fmt(count_words(target)), old)
    elif t == 'clock_set':
        hour, start = sc['hour'], sc['startHour']
        steps = (hour - start) % 12
        old = hints[3]['caption'][0]['v'] if 3 in hints else ''
        if hints[2]['caption'][0]['v'] == CLOCK_H1_TEXT:
            l1, l2 = CLOCK_H1, CLOCK_H2
        if steps and not sc.get('minute'):
            reached = ', '.join(F[(start + j - 1) % 12 + 1] for j in range(1, steps + 1))
            l3 = with_tail(CLOCK_L3.fmt(reached), old)
    elif t == 'match_pairs':
        face = _first_pair_face(d)
        if face is None:
            return
        coin = re.match(r'^s(\d+)$', face.get('coin') or '')
        solid = (face.get('sprite') or '').replace('asset:solid_', '')
        if face.get('numeral', 0) >= 1 and 'numeral' in face:
            l2 = MATCH_DOTS_H2
        elif coin and int(coin.group(1)) >= 1:
            l2 = MATCH_COIN_H2
        elif (face.get('sprite') or '').startswith('asset:solid_') and solid in ('cylinder', 'cone', 'sphere', 'pyramid', 'box'):
            l2 = MATCH_PRINT_H2
    elif t == 'sort_drag':
        if any(it.get('bin') for it in sc.get('items', [])):
            l2 = SORT_PASS_H2
    elif t == 'build_pattern':
        model = sc.get('model') or []
        if model:
            l2 = BUILD_UNIT_H2 if _unit_length(model) else BUILD_CELL_H2
    elif t == 'shape_builder':
        slots = sc.get('slots') or []
        if slots and any(k in slots[0]['sprite'] for k in ('shape_circle', 'shape_square', 'shape_triangle', 'shape_rect')):
            l2 = SB_GHOST_H2
    elif t == 'robot_path':
        l2 = ROBOT_FOOT_H2
    elif t == 'spot_error':
        if 3 in hints and hints[3]['vo'] == 'vo:hint.spot_but_one.h3' and right_cell_of(sc['cells'], ans['wrong']):
            l3 = SPOT_RIGHT_H3
    else:
        return
    if l1:
        put(1, l1)
    if l2 and not own_h2:
        put(2, l2)
    if l3 and 3 in hints:
        put(3, l3 if isinstance(l3, tuple) else (_own_vo(d, hints, 3), l3))
