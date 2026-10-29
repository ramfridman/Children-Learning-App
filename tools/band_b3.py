"""Band B, part three: the activities of the templates that came last (match pairs, shop and pay, clock setter, trace) and the chart
to read. See band_b.py."""
import math

from band_b import NAMES, OBJECTS, Unit  # noqa: E402
from author import F, M, qty, count_words, place  # noqa: E402

for _k, _t in {'banana_yellow': ('בָּנָנָה', 'f'), 'ball_red': ('כַּדּוּר אָדֹם', 'm'), 'fish': ('דָּג', 'm'), 'apple': ('תַּפּוּחַ', 'm'),
               'star': ('כּוֹכָב', 'm'), 'duck': ('בַּרְוָז', 'm'), 'bird': ('צִפּוֹר', 'f'), 'cat': ('חָתוּל', 'm'), 'dog': ('כֶּלֶב', 'm')}.items():
    NAMES.setdefault(_k, {'one': _t[0], 'g': _t[1]})

COIN_NAMES = {'a10': 'עֶשֶׂר אֲגוֹרוֹת', 'h50': 'חֲצִי שֶׁקֶל', 's1': 'שֶׁקֶל אֶחָד', 's2': 'שְׁנֵי שְׁקָלִים', 's5': 'חֲמִשָּׁה שְׁקָלִים',
              's10': 'עֲשָׂרָה שְׁקָלִים', 'n20': 'שְׁטָר שֶׁל עֶשְׂרִים', 'n50': 'שְׁטָר שֶׁל חֲמִשִּׁים', 'n100': 'שְׁטָר שֶׁל מֵאָה', 'n200': 'שְׁטָר שֶׁל מָאתַיִם'}
COIN_VALUE = {'a10': 10, 'h50': 50, 's1': 100, 's2': 200, 's5': 500, 's10': 1000, 'n20': 2000, 'n50': 5000, 'n100': 10000, 'n200': 20000}


def shekels(n):
    return 'שֶׁקֶל אֶחָד' if n == 1 else ('שְׁנֵי שְׁקָלִים' if n == 2 else '%s שְׁקָלִים' % M[n])


# ---------------------------------------------------------------- glyphs: strokes in a 100 x 100 box
def arc(cx, cy, rx, ry, a0, a1, n=24):
    out = []
    for k in range(n + 1):
        t = math.radians(a0 + (a1 - a0) * k / n)
        out.append([round(cx + rx * math.cos(t)), round(cy + ry * math.sin(t))])
    return out


def thin(pts):
    """Drop a point that repeats the one before it."""
    out = []
    for p in pts:
        if not out or p != out[-1]:
            out.append(p)
    return out


GLYPHS = {
    '0': [thin(arc(50, 50, 26, 40, -90, -450, 28))],
    '1': [[[36, 30], [54, 12], [54, 90]]],
    '2': [thin(arc(50, 34, 26, 22, -180, 20, 14) + [[22, 88], [80, 88]])],
    '3': [thin(arc(48, 30, 22, 18, -150, 90, 12) + arc(48, 68, 26, 20, -90, 150, 14))],
    '4': [[[62, 10], [20, 62], [82, 62]], [[62, 10], [62, 90]]],
    '5': [thin([[72, 12], [30, 12], [26, 46]] + arc(48, 66, 28, 24, -120, 140, 16))],
    '6': [thin([[66, 12], [44, 26], [28, 50]] + arc(50, 66, 26, 24, 180, -180, 22))],
    '7': [[[22, 14], [78, 14], [40, 90]]],
    '8': [thin(arc(50, 31, 20, 18, -90, -450, 20) + arc(50, 69, 24, 21, -90, -450, 22))],
    '9': [thin(arc(50, 34, 24, 22, 0, -360, 22) + [[74, 36], [70, 62], [46, 90]])],
    'circle': [thin(arc(50, 50, 34, 34, -90, -450, 28))],
    'square': [[[22, 22], [78, 22], [78, 78], [22, 78], [22, 22]]],
    'triangle': [[[50, 15], [85, 82], [15, 82], [50, 15]]],
}


def lesson_ids(u, skill, a=0, b=None):
    return [x['id'] for x in u.d['activities'] if x['skill'] == skill][a:b]


# ======================================================================================== numbers
def extra_numbers():
    u = Unit('band-b-extra-numbers', 'numbers',
             'Tracing the numerals 0 to 9 (T04) and matching numerals to sets (T16). Hebrew is a draft by Claude, needs-editor.', 60,
             assets=['apple', 'star', 'fish', 'duck'], prefix='x')
    u.tag('M-NUM-WRITE', ['NUM-B-07'], 'הילד מתחיל לכתוב ספרה מהקצה הלא נכון, או מצייר אותה בכיוון הפוך.',
          'לכתוב ספרה גדולה באצבע על חול או על קמח במגש, ולהתחיל תמיד מהנקודה: מלמעלה.',
          ['embodied', 'symbolic'], 'מַתְחִילִים מֵהַנְּקֻדָּה הַיְרֻקָּה, וְהוֹלְכִים בַּכִּוּוּן שֶׁל הַנְּקֻדּוֹת. בּוֹאוּ נְנַסֶּה שׁוּב.')
    u.skill('NUM-B-07', 'כותבים מספרים', 'כּוֹתְבִים אֶת הַמִּסְפָּרִים', 'pool', ['NUM-A-08'], ['embodied', 'symbolic'], ['M-NUM-WRITE'])
    for guide in ('full', 'start'):
        for n in range(10):
            u.act('NUM-B-07', 'trace', glyph=str(n), guide=guide, tol=12 if guide == 'full' else 11, domain='numbers',
                  prompt='מְעַקְבִים בָּאֶצְבַּע אַחֲרֵי הַמִּסְפָּר %s.' % F[n] if guide == 'full' else 'כּוֹתְבִים אֶת הַמִּסְפָּר %s. מַתְחִילִים מֵהַנְּקֻדָּה.' % F[n],
                  dirTag='M-NUM-WRITE', h3='מַתְחִילִים מֵהַנְּקֻדָּה הַיְרֻקָּה וְהוֹלְכִים לְאַט אַחֲרֵי הַנְּקֻדּוֹת. עַכְשָׁו תּוֹרְכֶם.',
                  correct_text='כֵּן! כְּתַבְתֶּם אֶת הַמִּסְפָּר %s.' % F[n], difficulty=0.3 if guide == 'full' else 0.5)
    sets = [([1, 2, 3], 'apple', [1, 2, 0]), ([2, 3, 4], 'star', [2, 0, 1]), ([3, 4, 5], 'fish', [1, 2, 0]), ([1, 3, 5], 'duck', [2, 1, 0]),
            ([2, 4, 6], 'apple', [1, 0, 2]), ([4, 5, 6], 'star', [0, 2, 1]), ([1, 2, 3, 4], 'fish', [2, 3, 0, 1])]
    for ns, obj, order in sets:
        o = OBJECTS[obj]
        u.act('NUM-A-07', 'match', band='A', domain='numbers', pairs=[['n:%d' % n, '%s*%d' % (obj, n)] for n in ns], order=order, tag='M-CNT-SIZE',
              prompt='מַתְאִימִים כָּל מִסְפָּר לַקְּבוּצָה שֶׁלּוֹ.', h3='סוֹפְרִים אֶת הַחֲפָצִים בְּכָל קְבוּצָה, וּמוֹצְאִים אֶת הַמִּסְפָּר. עַכְשָׁו תּוֹרְכֶם.',
              correct_text='כֵּן! כָּל מִסְפָּר עִם הַקְּבוּצָה שֶׁלּוֹ.')
    ids = lambda s, a=0, b=None: lesson_ids(u, s, a, b)
    u.lesson('trace-numbers-0-4', 'כּוֹתְבִים 0 עַד 4', ['NUM-B-07'], ids('NUM-B-07', 0, 5), 'כׇּל הַכָּבוֹד! כְּתַבְתֶּם מִסְפָּרִים.')
    u.lesson('trace-numbers-5-9', 'כּוֹתְבִים 5 עַד 9', ['NUM-B-07'], ids('NUM-B-07', 5, 10), 'יָפֶה מְאוֹד! עוֹד מִסְפָּרִים.')
    u.lesson('write-from-the-dot-0-4', 'כּוֹתְבִים מֵהַנְּקֻדָּה', ['NUM-B-07'], ids('NUM-B-07', 10, 15), 'נִפְלָא! כְּתַבְתֶּם לְבַד.')
    u.lesson('write-from-the-dot-5-9', 'עוֹד כּוֹתְבִים מֵהַנְּקֻדָּה', ['NUM-B-07'], ids('NUM-B-07', 15, 20), 'מְצֻיָּן! הַמִּסְפָּרִים בַּמָּקוֹם.')
    u.lesson('match-numbers-sets', 'מִסְפָּר וּקְבוּצָה', ['NUM-A-07'], ids('NUM-A-07', 0, 4), 'כׇּל הַכָּבוֹד! הִתְאַמְתֶּם מִסְפָּרִים.', )
    u.lesson('match-numbers-sets-more', 'עוֹד הַתְאָמוֹת', ['NUM-A-07'], ids('NUM-A-07', 4), 'מְצֻיָּן! כָּל אֶחָד בַּמָּקוֹם שֶׁלּוֹ.')
    for l in u.d['lessons']:
        if l['skills'] == ['NUM-A-07']:
            l['band'] = 'A'
    u.save()


# ======================================================================================== math
def solution(price, purse):
    """The fewest coins that make the price (a list of kinds), or None."""
    best = {0: []}
    for kind, count in purse:
        for _ in range(count):
            for s, l in list(best.items()):
                t = s + COIN_VALUE[kind]
                if t <= price and (t not in best or len(best[t]) > len(l) + 1):
                    best[t] = l + [kind]
    return best.get(price)


def extra_math():
    u = Unit('band-b-extra-math', 'math',
             'Coins, paying exactly, reading a chart and setting the clock (T16, T17, T18 and the chart of tap_answer 1.2). Hebrew is a draft by Claude, needs-editor.',
             60, assets=['coin_a10', 'coin_h50', 'coin_s1', 'coin_s2', 'coin_s5', 'coin_s10', 'note_20', 'note_50', 'note_100', 'note_200', 'banana_yellow', 'ball_red', 'apple', 'fish', 'star', 'block', 'duck'], prefix='x')
    u.tag('M-MONEY-SIZE', ['MATH-B-16'], 'הילד חושב שמטבע גדול שווה יותר (מטבע חצי השקל גדול ממטבע השקל).',
          'לשים על השולחן מטבעות אמיתיים, ולשאול: איזה שווה יותר? לבדוק יחד את המספר שכתוב עליו.', ['concrete', 'pictorial'],
          'לֹא הַגֹּדֶל אוֹמֵר כַּמָּה הַמַּטְבֵּעַ שָׁוֶה, אֶלָּא הַמִּסְפָּר שֶׁעָלָיו. בּוֹאוּ נִסְתַּכֵּל.')
    u.tag('M-MONEY-COUNT', ['MATH-B-17'], 'הילד סופר כמה מטבעות יש, ולא כמה הם שווים: שלושה מטבעות הם "שלושה שקלים" גם אם הם של חמישה.',
          'לשחק בחנות עם מטבעות: לשלם שלושה שקלים פעם עם מטבעות של שקל ופעם עם מטבע של שתיים ומטבע של שקל, ולהשוות.',
          ['concrete', 'symbolic'], 'כָּל מַטְבֵּעַ שָׁוֶה כַּמָּה שֶׁכָּתוּב עָלָיו. בּוֹאוּ נְחַבֵּר אֶת מַה שֶּׁכָּתוּב.')
    u.tag('M-COMP-DIFF', ['MATH-B-19'], 'הילד עונה על "כמה יותר?" בסך הכול של הקבוצה הגדולה, ולא בהפרש.',
          'לסדר שתי שורות של קוביות זו מול זו ולראות יחד כמה קוביות "עודפות" בשורה הארוכה.', ['concrete', 'pictorial'],
          'כְּדֵי לָדַעַת כַּמָּה יוֹתֵר, מַסְתַּכְּלִים כַּמָּה עוֹד יֵשׁ בַּגְּדוֹלָה. בּוֹאוּ נַשְׁוֶה אֶחָד אֶחָד.')

    u.skill('MATH-B-16', 'מכירים מטבעות', 'מַכִּירִים אֶת הַמַּטְבְּעוֹת', 'stall', ['NUM-A-08'], ['pictorial', 'concrete'], ['M-MONEY-SIZE'])
    sets = [(['s1', 's2', 's5'], [1, 2, 0]), (['s2', 's5', 's10'], [2, 0, 1]), (['s1', 's5', 's10'], [1, 2, 0]), (['s1', 's2', 's5', 's10'], [2, 3, 0, 1]),
            (['s2', 's1', 's10'], [1, 2, 0]), (['s5', 's10', 's2', 's1'], [3, 2, 1, 0])]
    for coins, order in sets:
        u.act('MATH-B-16', 'match', domain='math', pairs=[['coin:%s' % c, 'n:%d' % (COIN_VALUE[c] // 100)] for c in coins], order=order, tag='M-MONEY-SIZE',
              prompt='מַתְאִימִים כָּל מַטְבֵּעַ לַמִּסְפָּר שֶׁאוֹמֵר כַּמָּה הוּא שָׁוֶה.', h3='הַמִּסְפָּר שֶׁעַל הַמַּטְבֵּעַ אוֹמֵר כַּמָּה הוּא שָׁוֶה. עַכְשָׁו תּוֹרְכֶם.',
              correct_text='כֵּן! כָּל מַטְבֵּעַ עִם הַמִּסְפָּר שֶׁלּוֹ.')

    u.skill('MATH-B-17', 'משלמים בדיוק', 'מְשַׁלְּמִים בְּדִיּוּק', 'stall', ['MATH-B-16', 'MATH-B-03'], ['concrete'], ['M-MONEY-COUNT'])
    pays = [(3, 'apple', [('s1', 3), ('s2', 2)]), (5, 'banana_yellow', [('s1', 4), ('s2', 2), ('s5', 1)]), (4, 'fish', [('s1', 3), ('s2', 2), ('s5', 1)]),
            (7, 'ball_red', [('s1', 3), ('s2', 2), ('s5', 1)]), (6, 'star', [('s1', 4), ('s2', 2), ('s5', 1)]), (8, 'block', [('s1', 3), ('s2', 2), ('s5', 1)]),
            (9, 'apple', [('s1', 2), ('s2', 3), ('s5', 1)]), (10, 'fish', [('s2', 3), ('s5', 2), ('s10', 1)]), (11, 'duck', [('s1', 2), ('s5', 1), ('s10', 1)])]
    for price, item, purse in pays:
        sol = solution(price * 100, purse)
        assert sol, (price, purse)
        way = ' וְ'.join(COIN_NAMES[k] for k in sol)
        u.act('MATH-B-17', 'pay', domain='math', price=price * 100, item=item, purse=purse, tag='M-MONEY-COUNT',
              prompt='הַמְּחִיר הוּא %s. מְשַׁלְּמִים בְּדִיּוּק, וְלוֹחֲצִים עַל הַ-וִי.' % shekels(price),
              h3='אֶפְשָׁר לְשַׁלֵּם בְּ%s. עַכְשָׁו תּוֹרְכֶם.' % way, correct_text='כֵּן! שִׁלַּמְתֶּם בְּדִיּוּק %s.' % shekels(price))

    u.skill('MATH-B-19', 'קוראים תרשים', 'קוֹרְאִים תַּרְשִׁים שֶׁל תְּמוּנוֹת', 'stall', ['MATH-A-07', 'NUM-B-10'], ['pictorial'], ['M-COMP-DIFF'])
    charts = [([('apple', 3), ('banana_yellow', 5), ('ball_red', 2)], 'most'), ([('fish', 4), ('star', 6), ('duck', 3)], 'most'),
              ([('apple', 5), ('banana_yellow', 2), ('ball_red', 4)], 'least'), ([('fish', 2), ('star', 5), ('duck', 4)], 'least'),
              ([('apple', 3), ('banana_yellow', 5), ('ball_red', 2)], 'total'), ([('fish', 4), ('star', 2), ('duck', 3)], 'total'),
              ([('apple', 3), ('banana_yellow', 5)], 'more'), ([('fish', 6), ('star', 2)], 'more'), ([('star', 4), ('duck', 7)], 'more')]
    for i, (cols, ask) in enumerate(charts):
        counts = [c for _, c in cols]
        names = [NAMES[s]['one'] for s, _ in cols]
        chart = [list(c) for c in cols]
        if ask in ('most', 'least'):
            pick = max(cols, key=lambda c: c[1]) if ask == 'most' else min(cols, key=lambda c: c[1])
            u.act('MATH-B-19', 'pick', domain='math', chart=chart, options=[s for s, _ in cols] if i % 3 == 0 else [s for s, _ in cols][1:] + [cols[0][0]],
                  correct=pick[0], rep='pictorial', prompt='%s' % ('אֵיזֶה יֵשׁ הַכִּי הַרְבֵּה?' if ask == 'most' else 'אֵיזֶה יֵשׁ הַכִּי פָּחוֹת?'),
                  correct_text='כֵּן! בַּתַּרְשִׁים הָעַמּוּד שֶׁלּוֹ %s.' % ('הַכִּי גָּבוֹהַּ' if ask == 'most' else 'הַכִּי נָמוּךְ'),
                  h3='%s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנָּכוֹן.' % ('הָעַמּוּד הַגָּבוֹהַּ הוּא הַכִּי הַרְבֵּה' if ask == 'most' else 'הָעַמּוּד הַנָּמוּךְ הוּא הַכִּי פָּחוֹת'))
        elif ask == 'total':
            r = sum(counts)
            others = [x for x in (r - 1, r + 1, r + 2) if x != r][:2]
            u.act('MATH-B-19', 'pick', domain='math', chart=chart, options=['n:%d' % v for v in place(r, others, i % 3)], correct='n:%d' % r, rep='pictorial',
                  voice=True, prompt='כַּמָּה יֵשׁ בְּסַךְ הַכֹּל בַּתַּרְשִׁים?', correct_text='%s! %s.' % (F[r], ' וְעוֹד '.join(F[c] for c in counts) + ' הֵם ' + F[r]),
                  h3='%s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (' וְעוֹד '.join(F[c] for c in counts) + ' הֵם ' + F[r], F[r]))
        else:
            big, small = max(counts), min(counts)
            d = big - small
            others = [x for x in (big, d + 1, d - 1) if x != d and x >= 0][:2]
            u.act('MATH-B-19', 'pick', domain='math', chart=chart, options=['n:%d' % v for v in place(d, others, i % 3)], correct='n:%d' % d, rep='pictorial',
                  voice=True, tags={'n:%d' % big: 'M-COMP-DIFF'}, prompt='כַּמָּה יוֹתֵר בָּעַמּוּד הַגָּבוֹהַּ מֵאֲשֶׁר בָּעַמּוּד הַנָּמוּךְ?',
                  correct_text='%s! בָּעַמּוּד הַגָּבוֹהַּ יֵשׁ עוֹד %s.' % (F[d], F[d]),
                  h3='%s פָּחוֹת %s שָׁוֶה %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (F[big], F[small], F[d], F[d]))

    # setting the clock belongs to the reading skill that the Band B Math unit already made
    for i, (h, start, handsTag) in enumerate([(3, 12, True), (6, 3, True), (9, 6, True), (1, 7, True), (5, 11, True), (8, 2, True), (11, 4, True), (2, 9, True)]):
        u.act('MATH-B-15', 'clock', domain='math', hour=h, minute=0, start=[start, False], tag='M-CLOCK-HANDS',
              prompt='מַכְוִינִים אֶת הַשָּׁעוֹן לַשָּׁעָה %s.' % F[h], h3='הַמַּחֲוָג הַקָּצָר וְהָעָבֶה מַצְבִּיעַ עַל %s. עַכְשָׁו תּוֹרְכֶם.' % F[h],
              correct_text='כֵּן! הַשָּׁעָה %s.' % F[h])
    ids = lambda s, a=0, b=None: lesson_ids(u, s, a, b)
    u.lesson('know-the-coins', 'מַכִּירִים מַטְבְּעוֹת', ['MATH-B-16'], ids('MATH-B-16', 0, 3), 'כׇּל הַכָּבוֹד! אַתֶּם מַכִּירִים מַטְבְּעוֹת.')
    u.lesson('know-the-coins-more', 'עוֹד מַטְבְּעוֹת', ['MATH-B-16'], ids('MATH-B-16', 3), 'מְצֻיָּן! כָּל מַטְבֵּעַ וְהַשֵּׁם שֶׁלּוֹ.')
    u.lesson('pay-exactly', 'מְשַׁלְּמִים בְּדִיּוּק', ['MATH-B-17'], ids('MATH-B-17', 0, 5), 'כׇּל הַכָּבוֹד! שִׁלַּמְתֶּם בְּדִיּוּק.')
    u.lesson('pay-exactly-more', 'עוֹד לְשַׁלֵּם', ['MATH-B-17'], ids('MATH-B-17', 5), 'מְצֻיָּן! הַחֶשְׁבּוֹן יוֹצֵא.')
    u.lesson('read-the-chart', 'קוֹרְאִים תַּרְשִׁים', ['MATH-B-19'], ids('MATH-B-19', 0, 6), 'כׇּל הַכָּבוֹד! קְרָאתֶם תַּרְשִׁים.')
    u.lesson('read-the-chart-more', 'כַּמָּה יוֹתֵר', ['MATH-B-19'], ids('MATH-B-19', 6), 'יָפֶה! אַתֶּם יוֹדְעִים לְהַשְׁווֹת.')
    u.lesson('set-the-clock', 'מַכְוִינִים שָׁעוֹן', ['MATH-B-15'], ids('MATH-B-15', 0, 4), 'כׇּל הַכָּבוֹד! הַשָּׁעוֹן מְכֻוָּן.')
    u.lesson('set-the-clock-more', 'עוֹד שָׁעוֹת', ['MATH-B-15'], ids('MATH-B-15', 4), 'מְצֻיָּן! הַמַּחֲוָג הַקָּצָר אוֹמֵר.')
    u.save()


# ======================================================================================== shapes
def extra_shapes():
    u = Unit('band-b-extra-shapes', 'shapes',
             'Tracing the first shapes (T04) and matching a solid to its face (T16). Hebrew is a draft by Claude, needs-editor.', 60,
             assets=['shape_circle', 'shape_square', 'shape_triangle', 'shape_rect', 'solid_cylinder', 'solid_cone', 'solid_pyramid', 'solid_box', 'solid_sphere'], prefix='x')
    u.tag('M-SHP-FACE', ['SHP-B-09'], 'הילד לא רואה איזו צורה שטוחה יש על הגוף: את העיגול על הגליל, את המשולש על הפירמידה.',
          'להטביע בפלסטלינה בסיס של כוס, של קופסה ושל קונוס, ולראות איזו צורה נשארת.', ['concrete', 'pictorial'],
          'כְּשֶׁמַּטְבִּיעִים אֶת הַגּוּף בַּחוֹל, נִשְׁאֶרֶת צוּרָה. בּוֹאוּ נְדַמְיֵן אֶת זֶה.')
    for guide in ('full', 'start'):
        for g, name in (('circle', 'הָעִגּוּל'), ('square', 'הָרִבּוּעַ'), ('triangle', 'הַמְּשֻׁלָּשׁ')):
            u.act('SHP-A-02', 'trace', band='A', glyph=g, guide=guide, tol=12, domain='shapes',
                  prompt='מְעַקְבִים בָּאֶצְבַּע אַחֲרֵי %s.' % name if guide == 'full' else 'מְצַיְּרִים אֶת %s. מַתְחִילִים מֵהַנְּקֻדָּה.' % name,
                  h3='מַתְחִילִים מֵהַנְּקֻדָּה הַיְרֻקָּה וְהוֹלְכִים לְאַט. עַכְשָׁו תּוֹרְכֶם.', correct_text='כֵּן! צִיַּרְתֶּם אֶת %s.' % name)
    u.skill('SHP-B-09', 'גוף וצורה שלו', 'כָּל גּוּף וְהַצּוּרָה שֶׁעָלָיו', 'cone-tree', ['SHP-B-08', 'SHP-A-03'], ['pictorial', 'concrete'], ['M-SHP-FACE'])
    pairs = [[('solid_cylinder', 'shape_circle'), ('solid_pyramid', 'shape_triangle'), ('solid_box', 'shape_rect')],
             [('solid_cone', 'shape_circle'), ('solid_box', 'shape_rect'), ('solid_pyramid', 'shape_triangle')],
             [('solid_cylinder', 'shape_circle'), ('solid_box', 'shape_rect')],
             [('solid_sphere', 'shape_circle'), ('solid_pyramid', 'shape_triangle'), ('solid_box', 'shape_rect')]]
    for i, ps in enumerate(pairs):
        order = list(range(len(ps)))
        order = order[1:] + order[:1] if i % 2 == 0 else order[::-1]
        u.act('SHP-B-09', 'match', domain='shapes', pairs=[[l, r] for l, r in ps], order=order, tag='M-SHP-FACE',
              prompt='מַתְאִימִים כָּל גּוּף לַצּוּרָה הַשְּׁטוּחָה שֶׁעַל הַגּוּף.', h3='מַטְבִּיעִים אֶת הַגּוּף וְרוֹאִים אֶת הַצּוּרָה שֶׁנִּשְׁאֶרֶת. עַכְשָׁו תּוֹרְכֶם.',
              correct_text='כֵּן! כָּל גּוּף עִם הַצּוּרָה שֶׁלּוֹ.')
    ids = lambda s, a=0, b=None: lesson_ids(u, s, a, b)
    u.lesson('trace-the-shapes', 'מְעַקְבִים צוּרוֹת', ['SHP-A-02'], ids('SHP-A-02', 0, 3), 'כׇּל הַכָּבוֹד! עִקַּבְתֶּם אַחֲרֵי צוּרוֹת.')
    u.lesson('draw-the-shapes', 'מְצַיְּרִים צוּרוֹת', ['SHP-A-02'], ids('SHP-A-02', 3), 'יָפֶה מְאוֹד! צִיַּרְתֶּם מֵהַנְּקֻדָּה.')
    u.lesson('solid-and-face', 'גּוּף וְצוּרָה', ['SHP-B-09'], ids('SHP-B-09'), 'כׇּל הַכָּבוֹד! הִתְאַמְתֶּם גּוּפִים.')
    for l in u.d['lessons']:
        if l['skills'] == ['SHP-A-02']:
            l['band'] = 'A'
    u.save()


def run():
    extra_numbers()
    extra_math()
    extra_shapes()
