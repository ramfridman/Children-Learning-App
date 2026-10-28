"""The second half of the Band B specs (colours, shapes, logic, computer science). See band_b.py."""
from band_b import COLOURS, NAMES, Unit, clean, numpick, rot, tri  # noqa: E402
from author import F, count_words, place  # noqa: E402

SHAPE_ONE = {'circle': 'עִגּוּל', 'square': 'רִבּוּעַ', 'triangle': 'מְשֻׁלָּשׁ'}
SIDES_DEF = {'triangle': 'הַמְּשֻׁלָּשׁ', 'quad': 'הַמְּרֻבָּע', 'pentagon': 'הַמְּחֻמָּשׁ', 'hexagon': 'הַמְּשֻׁשֶּׁה'}
SIDES_N = {'triangle': 3, 'quad': 4, 'pentagon': 5, 'hexagon': 6}


def lesson_ids(u, skill, a=0, b=None):
    return [x['id'] for x in u.d['activities'] if x['skill'] == skill][a:b]


# ======================================================================================== COLOURS

def colours():
    C = COLOURS
    u = Unit('band-b-colours', 'colors',
             'Band B of Colours: mixing, shades from light to dark, a shade is still the same colour, sorting two ways, the rainbow. '
             'Hebrew is a draft by Claude, needs-editor.',
             30, assets=['shade_%s_%d' % (c, k) for c in ('blue', 'green', 'red', 'purple') for k in (1, 2, 3)] + [
                 'ball_red', 'ball_blue', 'ball_yellow', 'ball_orange', 'ball_green', 'ball_purple', 'shape_circle_red',
                 'shape_circle_blue', 'shape_square_red', 'shape_square_blue', 'shape_triangle_red', 'shape_triangle_blue',
                 'shape_circle_green', 'shape_square_green', 'shape_triangle_green', 'grass', 'basket_empty'])
    u.tag('M-COL-MIX', ['COL-B-01'], 'הילד מנחש את צבע התערובת לפי אחד הצבעים, או חושב שכל ערבוב נותן חום.',
          'לערבב בצבעי אצבעות שתי טיפות, צהוב וכחול, ולהסתכל מה יוצא. אחר כך לנחש לפני שמערבבים.',
          ['concrete', 'pictorial'], 'כְּשֶׁמְּעָרְבְּבִים שְׁנֵי צְבָעִים יוֹצֵא צֶבַע חָדָשׁ. בּוֹאוּ נִבְדֹּק.')
    u.tag('M-COL-SHADE', ['COL-B-02', 'COL-B-03'], 'הילד חושב שכחול בהיר וכחול כהה הם צבעים שונים, או משווה לפי בהירות ולא לפי הצבע.',
          'לצייר פס כחול ולהוסיף בהדרגה לבן, ולהסתכל איך הוא נהיה בהיר ועדיין כחול.',
          ['pictorial', 'concrete'], 'כָּחֹל בָּהִיר וְכָחֹל כֵּהֶה הֵם שְׁנֵיהֶם כָּחֹל. בּוֹאוּ נִסְתַּכֵּל עַל הַצֶּבַע.')

    u.skill('COL-B-01', 'מערבבים צבעים', 'מְעָרְבְּבִים וּמְקַבְּלִים צֶבַע חָדָשׁ', 'pool', ['COL-A-03'], ['concrete', 'pictorial'], ['M-COL-MIX'])
    mixes = [('red', 'yellow', 'orange', 'blue', 'green'), ('blue', 'yellow', 'green', 'red', 'orange'), ('red', 'blue', 'purple', 'yellow', 'green')]
    for i, (x, y, r, w1, w2) in enumerate(mixes + mixes):
        if i >= 3:
            x, y = y, x
        u.act('COL-B-01', 'pick', prompt='אִם מְעָרְבְּבִים %s וְ%s, אֵיזֶה צֶבַע יוֹצֵא?' % (C[x], C[y]),
              group={'sprite': 'ball_' + x, 'count': 1}, group2={'sprite': 'ball_' + y, 'count': 1},
              options=place('ball_' + r, ['ball_' + w1, 'ball_' + w2], i % 3), correct='ball_' + r,
              tags={'ball_' + w1: 'M-COL-MIX', 'ball_' + w2: 'M-COL-MIX'}, rep='concrete', domain='colors',
              correct_text='כֵּן! %s וְ%s נַעֲשִׂים %s.' % (C[x], C[y], C[r]),
              h3='%s וְ%s נַעֲשִׂים %s. עַכְשָׁו תּוֹרְכֶם.' % (C[x], C[y], C[r]))
    for i, (x, y, r, w1, w2) in enumerate(mixes):
        wrong = [w for w in (w1, w2) if w != y][:2]
        u.act('COL-B-01', 'pick', prompt='%s וְ… נַעֲשִׂים %s. מָה חָסֵר?' % (C[x], C[r]), group={'sprite': 'ball_' + x, 'count': 1},
              options=place('ball_' + y, ['ball_' + w for w in wrong], (i + 1) % 3), correct='ball_' + y,
              tags={'ball_' + w: 'M-COL-MIX' for w in wrong}, rep='concrete', domain='colors',
              correct_text='כֵּן! %s וְ%s נַעֲשִׂים %s.' % (C[x], C[y], C[r]), h3='%s וְ%s נַעֲשִׂים %s. עַכְשָׁו תּוֹרְכֶם.' % (C[x], C[y], C[r]))

    u.skill('COL-B-02', 'בהיר וכהה', 'סוֹדְרִים מִבָּהִיר לְכֵהֶה', 'pool', ['COL-A-03'], ['pictorial'], ['M-COL-SHADE'])
    for i, c in enumerate(['blue', 'green', 'red', 'purple']):
        sh = ['shade_%s_%d' % (c, k) for k in (1, 2, 3)]
        u.act('COL-B-02', 'pick', prompt='אֵיזֶה הַכִּי כֵּהֶה?', options=rot(sh, i), correct=sh[2], rep='pictorial', domain='colors',
              correct_text='כֵּן! זֶה הַכִּי כֵּהֶה.', h3='הַכֵּהֶה הוּא הַכִּי חָשׁוּךְ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו.')
        u.act('COL-B-02', 'pick', prompt='אֵיזֶה הַכִּי בָּהִיר?', options=rot(sh, i + 1), correct=sh[0], rep='pictorial', domain='colors',
              correct_text='כֵּן! זֶה הַכִּי בָּהִיר.', h3='הַבָּהִיר הוּא הַכִּי קָרוֹב לְלָבָן. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו.')
    for i, c in enumerate(['blue', 'green', 'red']):
        sh = ['shade_%s_%d' % (c, k) for k in (1, 2, 3)]
        u.act('COL-B-02', 'pick', prompt='מָה בָּאֶמְצַע, בֵּין הַבָּהִיר לַכֵּהֶה?', row=[sh[0], '?', sh[2]],
              options=place(sh[1], [sh[0], sh[2]], i % 3), correct=sh[1], rep='pictorial', domain='colors',
              correct_text='כֵּן! זֶה בָּאֶמְצַע.', h3='מִבָּהִיר לְכֵהֶה: בָּהִיר, אֶמְצָעִי, כֵּהֶה. עַכְשָׁו תּוֹרְכֶם.')

    u.skill('COL-B-03', 'בהיר וכהה הם אותו צבע', 'כָּחֹל בָּהִיר הוּא גַּם כָּחֹל', 'pool', ['COL-B-02'], ['pictorial'], ['M-COL-SHADE'])
    for i, (c, ref, other) in enumerate([('blue', 1, 'red'), ('blue', 3, 'green'), ('green', 1, 'purple'), ('green', 3, 'red'),
                                        ('red', 1, 'blue'), ('red', 3, 'purple'), ('purple', 1, 'green'), ('purple', 3, 'blue')]):
        right_level = 3 if ref == 1 else 1
        lookalike = 'shade_%s_%d' % (other, ref)
        u.act('COL-B-03', 'pick', prompt='אֵיפֹה עוֹד %s?' % C[c], group={'sprite': 'shade_%s_%d' % (c, ref), 'count': 1},
              options=place('shade_%s_%d' % (c, right_level), [lookalike, 'shade_%s_2' % other], i % 3),
              correct='shade_%s_%d' % (c, right_level), tags={lookalike: 'M-COL-SHADE'}, rep='pictorial', domain='colors',
              correct_text='כֵּן! גַּם זֶה %s.' % C[c], h3='בָּהִיר וְכֵהֶה הֵם אוֹתוֹ צֶבַע. הַצֶּבַע הוּא %s. עַכְשָׁו תּוֹרְכֶם.' % C[c])

    u.skill('COL-B-04', 'ממיינים בשתי דרכים', 'מְמַיְּנִים לְפִי צֶבַע וְלְפִי צוּרָה', 'sprout', ['COL-A-04', 'SHP-A-03'], ['concrete'],
            ['M-SORT-SHIFT'])
    sets = [(('shape_circle_red', 'shape_square_red', 'shape_circle_blue', 'shape_square_blue'), ('red', 'blue'), ('circle', 'square')),
            (('shape_circle_green', 'shape_triangle_green', 'shape_circle_red', 'shape_triangle_red'), ('green', 'red'), ('circle', 'triangle'))]
    plural = {'circle': 'עִגּוּלִים', 'square': 'רִבּוּעִים', 'triangle': 'מְשֻׁלָּשִׁים'}
    for (a1, a2, b1, b2), (c1, c2), (s1, s2) in sets:
        u.act('COL-B-04', 'sort', bins=[{'sprite': 'ball_' + c1, 'label': C[c1]}, {'sprite': 'ball_' + c2, 'label': C[c2]}],
              items=[(a1, 1), (b1, 2), (a2, 1), (b2, 2)], prompt='מְמַיְּנִים לְפִי צֶבַע: %s לְכָאן, וְ%s לְכָאן.' % (C[c1], C[c2]),
              domain='colors', h3='כָּל הַצּוּרוֹת בְּאוֹתוֹ צֶבַע הוֹלְכוֹת יַחַד. עַכְשָׁו תּוֹרְכֶם.', correct_text='כֵּן! מִיַּנְתֶּם לְפִי צֶבַע.')
        u.act('COL-B-04', 'sort', bins=[{'sprite': 'shape_%s_red' % s1, 'label': plural[s1]}, {'sprite': 'shape_%s_red' % s2, 'label': plural[s2]}],
              items=[(a1, 1), (b1, 1), (a2, 2), (b2, 2)], prompt='עַכְשָׁו מְמַיְּנִים לְפִי צוּרָה: %s לְכָאן, וְ%s לְכָאן.' % (plural[s1], plural[s2]),
              domain='colors', h3='כָּל הַצּוּרוֹת הַדּוֹמוֹת הוֹלְכוֹת יַחַד, גַּם אִם הַצֶּבַע שׁוֹנֶה. עַכְשָׁו תּוֹרְכֶם.',
              correct_text='כֵּן! מִיַּנְתֶּם לְפִי צוּרָה.')

    u.skill('COL-B-06', 'קשת בענן', 'מְסַדְּרִים אֶת הַקֶּשֶׁת', 'pattern-door', ['COL-B-01'], ['concrete'], ['M-PAT-COPY'])
    rainbow = ['ball_red', 'ball_orange', 'ball_yellow', 'ball_green', 'ball_blue', 'ball_purple']
    words = ', '.join(C[c] for c in ('red', 'orange', 'yellow', 'green', 'blue', 'purple'))
    u.act('COL-B-06', 'build', model=rainbow, palette=rainbow, prompt='בּוֹנִים אֶת הַקֶּשֶׁת בְּאוֹתוֹ סֵדֶר.', domain='colors',
          h3='הַקֶּשֶׁת: %s. עַכְשָׁו תּוֹרְכֶם.' % words)
    u.act('COL-B-06', 'build', model=rainbow[:4], palette=rainbow[:4], prompt='בּוֹנִים אֶת תְּחִלַּת הַקֶּשֶׁת בְּאוֹתוֹ סֵדֶר.',
          domain='colors', h3='תְּחִלַּת הַקֶּשֶׁת: %s. עַכְשָׁו תּוֹרְכֶם.' % ', '.join(C[c] for c in ('red', 'orange', 'yellow', 'green')))
    u.act('COL-B-06', 'build', model=rainbow[::-1], palette=rainbow, sequence=rainbow[::-1],
          prompt='בּוֹנִים אֶת הַקֶּשֶׁת מֵהַסּוֹף לַהַתְחָלָה.', domain='colors',
          h3='מֵהַסּוֹף: %s. עַכְשָׁו תּוֹרְכֶם.' % ', '.join(C[c] for c in ('purple', 'blue', 'green', 'yellow', 'orange', 'red')))
    u.act('COL-B-06', 'build', palette=rainbow, sequence=rainbow, prompt='בּוֹנִים אֶת הַקֶּשֶׁת: %s.' % words, domain='colors',
          h3='הַקֶּשֶׁת: %s. עַכְשָׁו תּוֹרְכֶם.' % words)

    ids = lambda skill, a=0, b=None: lesson_ids(u, skill, a, b)
    u.lesson('mix-colours', 'מְעָרְבְּבִים צְבָעִים', ['COL-B-01'], ids('COL-B-01', 0, 3), 'כׇּל הַכָּבוֹד! עֵרַבְתֶּם צְבָעִים.')
    u.lesson('mix-colours-more', 'מַה חָסֵר בַּתַּעֲרוֹבֶת', ['COL-B-01'], ids('COL-B-01', 3), 'יָפֶה! מְצָאתֶם אֶת הַצֶּבַע הֶחָסֵר.')
    u.lesson('light-and-dark', 'בָּהִיר וְכֵהֶה', ['COL-B-02'], ids('COL-B-02', 0, 6), 'כׇּל הַכָּבוֹד! אַתֶּם מַכִּירִים בָּהִיר וְכֵהֶה.')
    u.lesson('middle-shade', 'הַגָּוֶן שֶׁבָּאֶמְצַע', ['COL-B-02'], ids('COL-B-02', 6), 'מְצֻיָּן! מְצָאתֶם אֶת הָאֶמְצַע.')
    u.lesson('same-colour-shades', 'אוֹתוֹ צֶבַע', ['COL-B-03'], ids('COL-B-03', 0, 4), 'כׇּל הַכָּבוֹד! גְּוָנִים שׁוֹנִים, אוֹתוֹ צֶבַע.')
    u.lesson('same-colour-shades-more', 'עוֹד גְּוָנִים', ['COL-B-03'], ids('COL-B-03', 4), 'נִפְלָא! אַתֶּם רוֹאִים אֶת הַצֶּבַע.')
    u.lesson('sort-two-ways', 'מְמַיְּנִים בִּשְׁתֵּי דְּרָכִים', ['COL-B-04'], ids('COL-B-04'), 'כׇּל הַכָּבוֹד! מִיַּנְתֶּם בִּשְׁתֵּי דְּרָכִים.')
    u.lesson('rainbow', 'הַקֶּשֶׁת', ['COL-B-06'], ids('COL-B-06'), 'וַאוּ! בְּנִיתֶם קֶשֶׁת.')
    u.save()


# ======================================================================================== SHAPES

def shapes():
    u = Unit('band-b-shapes', 'shapes',
             'Band B of Shapes: polygons by their sides, counting sides, square and rectangle, closed shapes, the solids. '
             'Hebrew is a draft by Claude, needs-editor.',
             30, assets=['shape_pentagon', 'shape_hexagon', 'shape_quad', 'shape_open', 'shape_curved', 'solid_cylinder', 'solid_cone',
                         'solid_sphere', 'solid_pyramid', 'solid_box', 'shape_triangle', 'shape_square', 'shape_rect', 'shape_circle',
                         'tick', 'cross'])
    u.tag('M-SHP-CLOSED', ['SHP-B-01', 'SHP-B-04'], 'הילד מכנה צורה פתוחה או עם צלע עקומה "משולש" או "מרובע", כי היא נראית דומה.',
          'לצייר בעיפרון משולש, ואז לצייר אחד שלא סגור בפינה, ולשאול: האם נמלה יכולה ללכת מסביב בלי לצאת?',
          ['pictorial', 'concrete'], 'צוּרָה סְגוּרָה אֵין בָּהּ פֶּתַח, וְהַצְּלָעוֹת שֶׁלָּהּ יְשָׁרוֹת. בּוֹאוּ נִבְדֹּק.')

    u.skill('SHP-B-01', 'מכירים מצולעים', 'מַכִּירִים מְשֻׁלָּשׁ, מְרֻבָּע, מְחֻמָּשׁ וּמְשֻׁשֶּׁה', 'cone-tree', ['SHP-A-03', 'NUM-A-09'],
            ['pictorial'], ['M-SHP-CLOSED'])
    order = ['pentagon', 'hexagon', 'quad', 'triangle', 'pentagon', 'hexagon', 'quad', 'triangle']
    for i, sh in enumerate(order):
        pool = [x for x in ('triangle', 'quad', 'pentagon', 'hexagon') if x != sh]
        wrong = ['shape_' + pool[i % 3], 'shape_open' if i % 2 == 0 else 'shape_curved']
        n = SIDES_N[sh]
        u.act('SHP-B-01', 'pick', prompt='אֵיפֹה %s?' % SIDES_DEF[sh], options=place('shape_' + sh, wrong, i % 3), correct='shape_' + sh,
              tags={wrong[1]: 'M-SHP-CLOSED'}, rep='pictorial', domain='shapes',
              correct_text='כֵּן! %s יֵשׁ לוֹ %s צְלָעוֹת.' % (SIDES_DEF[sh], F[n]),
              h3='%s הוּא צוּרָה סְגוּרָה עִם %s צְלָעוֹת יְשָׁרוֹת. עַכְשָׁו תּוֹרְכֶם.' % (SIDES_DEF[sh], F[n]))

    u.skill('SHP-B-02', 'סופרים צלעות', 'סוֹפְרִים צְלָעוֹת', 'cone-tree', ['SHP-B-01'], ['pictorial'], ['M-CNT-DOUBLE', 'M-CNT-SKIP'])
    for i, (sp, n) in enumerate([('shape_triangle', 3), ('shape_quad', 4), ('shape_pentagon', 5), ('shape_hexagon', 6), ('shape_square', 4),
                                 ('shape_rect', 4), ('shape_pentagon', 5), ('shape_hexagon', 6)]):
        numpick(u, 'SHP-B-02', 'כַּמָּה צְלָעוֹת יֵשׁ לַצּוּרָה הַזֹּאת?', n, [n + 1, n - 1], i, tags={n + 1: 'M-CNT-DOUBLE', n - 1: 'M-CNT-SKIP'},
                rep='pictorial', domain='shapes', group={'sprite': sp, 'count': 1}, text='%s! %s צְלָעוֹת.' % (F[n], F[n]),
                h3='נִסְפֹּר צֶלַע אַחַר צֶלַע, וְלֹא נִסְפֹּר אוֹתָהּ פַּעֲמַיִם: %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (count_words(n), F[n]))

    u.skill('SHP-B-03', 'ריבוע ומלבן', 'רִבּוּעַ וּמַלְבֵּן', 'cone-tree', ['SHP-A-04', 'SHP-B-02'], ['pictorial'], ['M-SHP-SQRECT'])
    for i in range(3):
        u.act('SHP-B-03', 'pick', prompt='לְאֵיזוֹ צוּרָה כָּל הַצְּלָעוֹת שָׁווֹת?', options=place('shape_square', ['shape_rect', 'shape_triangle'], i),
              correct='shape_square', tags={'shape_rect': 'M-SHP-SQRECT'}, rep='pictorial', domain='shapes',
              correct_text='כֵּן! בְּרִבּוּעַ כָּל הַצְּלָעוֹת שָׁווֹת.', h3='בְּרִבּוּעַ כָּל אַרְבַּע הַצְּלָעוֹת שָׁווֹת. עַכְשָׁו תּוֹרְכֶם.')
        u.act('SHP-B-03', 'pick', prompt='אֵיפֹה הַמַּלְבֵּן? לֹא כָּל הַצְּלָעוֹת שָׁווֹת.',
              options=place('shape_rect', ['shape_square', 'shape_circle'], i), correct='shape_rect', tags={'shape_square': 'M-SHP-SQRECT'},
              rep='pictorial', domain='shapes', correct_text='כֵּן! בְּמַלְבֵּן יֵשׁ צְלָעוֹת אֲרֻכּוֹת וּצְלָעוֹת קְצָרוֹת.',
              h3='בְּמַלְבֵּן שְׁתֵּי צְלָעוֹת אֲרֻכּוֹת וּשְׁתֵּי צְלָעוֹת קְצָרוֹת. עַכְשָׁו תּוֹרְכֶם.')

    u.skill('SHP-B-04', 'צורה סגורה', 'צוּרָה סְגוּרָה עִם צְלָעוֹת יְשָׁרוֹת', 'cone-tree', ['SHP-B-01', 'SHP-A-10'], ['pictorial'], ['M-SHP-CLOSED'])
    for i, (sp, closed) in enumerate([('shape_triangle', True), ('shape_open', False), ('shape_pentagon', True), ('shape_curved', False),
                                      ('shape_hexagon', True), ('shape_quad', True), ('shape_open', False), ('shape_curved', False)]):
        u.act('SHP-B-04', 'pick', prompt='הַאִם זוֹ צוּרָה סְגוּרָה עִם צְלָעוֹת יְשָׁרוֹת?', group={'sprite': sp, 'count': 1},
              options=['cross', 'tick'] if i % 2 else ['tick', 'cross'], correct='tick' if closed else 'cross',
              tags={} if closed else {'tick': 'M-SHP-CLOSED'}, rep='pictorial', domain='shapes',
              correct_text='כֵּן, הִיא סְגוּרָה וְיֵשׁ לָהּ צְלָעוֹת יְשָׁרוֹת.' if closed else 'לֹא, הִיא לֹא סְגוּרָה אוֹ שֶׁיֵּשׁ לָהּ צֶלַע עֲקֻמָּה.',
              h3='נִסְתַּכֵּל עַל הַקַּוִּים: הַאִם אֶפְשָׁר לָלֶכֶת מִסָּבִיב וְלַחֲזֹר לַהַתְחָלָה? עַכְשָׁו תּוֹרְכֶם.')

    u.skill('SHP-B-08', 'גופים', 'גָּלִיל, חָרוּט, כַּדּוּר וּפִירָמִידָה', 'cone-tree', ['SHP-A-07'], ['pictorial', 'concrete'], [])
    solids = [('solid_cylinder', 'הַגָּלִיל'), ('solid_cone', 'הֶחָרוּט'), ('solid_sphere', 'הַכַּדּוּר'), ('solid_pyramid', 'הַפִּירָמִידָה'),
              ('solid_box', 'הַתֵּבָה')]
    for i in range(8):
        sp, nm = solids[i % 5]
        others = [x for x, _ in solids if x != sp]
        pair = [others[(i * 2) % 4], others[(i * 2 + 1) % 4]]
        u.act('SHP-B-08', 'pick', prompt='אֵיפֹה %s?' % nm, options=place(sp, pair, i % 3), correct=sp, rep='pictorial', domain='shapes',
              correct_text='כֵּן! זֶה %s.' % nm, h3='%s — נִסְתַּכֵּל עַל הַצּוּרָה שֶׁלּוֹ. עַכְשָׁו תּוֹרְכֶם.' % nm)

    ids = lambda skill, a=0, b=None: lesson_ids(u, skill, a, b)
    u.lesson('polygon-detectives', 'בַּלָּשֵׁי צוּרוֹת', ['SHP-B-01'], ids('SHP-B-01', 0, 4), 'כׇּל הַכָּבוֹד! אַתֶּם מַכִּירִים צוּרוֹת חֲדָשׁוֹת.')
    u.lesson('polygon-detectives-more', 'עוֹד צוּרוֹת', ['SHP-B-01'], ids('SHP-B-01', 4), 'מְצֻיָּן! עוֹד צוּרוֹת בָּרְשִׁימָה.')
    u.lesson('count-sides', 'סוֹפְרִים צְלָעוֹת', ['SHP-B-02'], ids('SHP-B-02', 0, 4), 'כׇּל הַכָּבוֹד! סְפַרְתֶּם צְלָעוֹת.')
    u.lesson('count-sides-more', 'עוֹד צְלָעוֹת', ['SHP-B-02'], ids('SHP-B-02', 4), 'יָפֶה! כָּל צֶלַע פַּעַם אַחַת.')
    u.lesson('square-or-rectangle', 'רִבּוּעַ אוֹ מַלְבֵּן', ['SHP-B-03'], ids('SHP-B-03'), 'כׇּל הַכָּבוֹד! אַתֶּם מַבְחִינִים בֵּין רִבּוּעַ לְמַלְבֵּן.')
    u.lesson('closed-shapes', 'צוּרָה סְגוּרָה', ['SHP-B-04'], ids('SHP-B-04', 0, 4), 'כׇּל הַכָּבוֹד! אַתֶּם מַכִּירִים צוּרָה סְגוּרָה.')
    u.lesson('closed-shapes-more', 'עוֹד צוּרוֹת סְגוּרוֹת', ['SHP-B-04'], ids('SHP-B-04', 4), 'מְצֻיָּן! הִבְחַנְתֶּם בִּצְלָעוֹת יְשָׁרוֹת.')
    u.lesson('solids', 'גּוּפִים', ['SHP-B-08'], ids('SHP-B-08', 0, 5), 'כׇּל הַכָּבוֹד! הִכַּרְתֶּם גּוּפִים.')
    u.lesson('solids-more', 'עוֹד גּוּפִים', ['SHP-B-08'], ids('SHP-B-08', 5), 'יָפֶה מְאוֹד! גּוּפִים בְּכָל מָקוֹם.')
    u.save()


# ======================================================================================== LOGIC

def logic():
    C = COLOURS
    u = Unit('band-b-logic', 'logic',
             'Band B of Logic: longer patterns, the broken pattern, growing patterns, the sorting rule, if-then, deduction, order of five. '
             'Hebrew is a draft by Claude, needs-editor.',
             30, assets=['ball_red', 'ball_blue', 'ball_yellow', 'ball_green', 'cat', 'dog', 'star', 'apple', 'fish'] + [
                 'tower_%d' % k for k in range(1, 7)] + ['rule_colour', 'rule_shape', 'rule_size'] + [
                 'shape_%s_%s' % (s, c) for s in ('circle', 'square', 'triangle') for c in ('red', 'blue', 'green')] + [
                 'apple_size_l', 'star_size_l', 'fish_size_l', 'apple_size_s', 'star_size_s', 'fish_size_s', 'basket_empty', 'grass'])
    u.tag('M-PAT-UNIT', ['LOG-B-02'], 'הילד לא מזהה איזה חלק חוזר בסדר, ולכן לא רואה איפה הוא נשבר.',
          'לשיר שיר עם תנועות חוזרות, למשל טפיחה-טפיחה-מחיאה, ולעצור ולשאול: מה החלק שחוזר?',
          ['embodied', 'pictorial'], 'יֵשׁ חֵלֶק קָטָן שֶׁחוֹזֵר שׁוּב וְשׁוּב. בּוֹאוּ נִמְצָא אוֹתוֹ.')
    u.tag('M-PAT-GROW', ['LOG-B-04'], 'בסדר שגדל, הילד חוזר על האחרון במקום להוסיף עוד אחד.',
          'לבנות מגדל מקוביות: קובייה אחת, שתיים, שלוש. בכל פעם להוסיף עוד אחת, ולשאול כמה יהיו בפעם הבאה.',
          ['concrete', 'pictorial'], 'בַּסֵּדֶר הַזֶּה כָּל מִגְדָּל גָּבוֹהַּ בְּאֶחָד מִקּוֹדְמוֹ. בּוֹאוּ נִסְפֹּר.')
    u.tag('M-LOG-NOT', ['LOG-B-09'], 'הילד מתעלם מאחד התנאים ("לא אדום ולא עיגול") ובוחר לפי אחד בלבד.',
          'לשחק "ניחוש מי": להסתיר חפץ ולתת רמזים "זה לא אדום", "זה לא עגול", ולהקטין את האפשרויות יחד.',
          ['concrete', 'symbolic'], 'צָרִיךְ לְהַקְשִׁיב לִשְׁנֵי הָרְמָזִים יַחַד: לֹא זֶה וְגַם לֹא זֶה. בּוֹאוּ נִבְדֹּק.')

    P = [('ball_red', 'ball_blue', 'ball_yellow'), ('cat', 'dog', 'star'), ('apple', 'fish', 'star'), ('ball_green', 'ball_red', 'ball_blue')]
    u.skill('LOG-B-01', 'מרחיבים סדר', 'מַמְשִׁיכִים סֵדֶר שֶׁל שְׁלוֹשָׁה', 'pattern-door', ['LOG-A-06'], ['pictorial'], ['M-PAT-NEXT'])
    for i, form in enumerate(['AAB', 'ABB', 'ABC', 'AAB', 'ABB', 'ABC', 'ABBC', 'AABB']):
        x, y, z = P[i % len(P)]
        sym = {'A': x, 'B': y, 'C': z}
        unit = [sym[c] for c in form]
        seq = (unit * 4)[:8]
        row = seq[:7] + ['?']
        right = seq[7]
        others = [e for e in dict.fromkeys(unit + [z, x, y]) if e != right][:2]
        u.act('LOG-B-01', 'pick', prompt='מָה בָּא אַחַר כָּךְ?', row=row, options=place(right, others, i % 3), correct=right,
              tags={seq[6]: 'M-PAT-NEXT'} if seq[6] != right else {}, rep='pictorial', domain='logic',
              correct_text='כֵּן! הַסֵּדֶר חוֹזֵר.', h3='הַחֵלֶק שֶׁחוֹזֵר הוּא: %s. עַכְשָׁו תּוֹרְכֶם.' % ', '.join(NAMES[e]['one'] for e in unit))

    u.skill('LOG-B-02', 'מוצאים את החלק החוזר', 'מוֹצְאִים מָה נִשְׁבַּר בַּסֵּדֶר', 'pattern-door', ['LOG-B-01'], ['pictorial'], ['M-PAT-UNIT'])
    for i, (form, w) in enumerate([('AAB', 4), ('ABB', 3), ('ABC', 5), ('AAB', 6), ('ABB', 4), ('ABC', 2)]):
        x, y, z = P[i % len(P)]
        sym = {'A': x, 'B': y, 'C': z}
        seq = ([sym[c] for c in form] * 3)[:8]
        seq[w] = z if seq[w] != z else x
        u.act('LOG-B-02', 'spot', cells=seq, wrong=w, tag='M-PAT-UNIT', rep='pictorial', domain='logic',
              prompt='הַסֵּדֶר חוֹזֵר, אֲבָל אֶחָד מֵהֶם לֹא מַתְאִים. אֵיזֶה?',
              h3='הַחֵלֶק הַחוֹזֵר הוּא: %s. אֶחָד מֵהֶם שׁוֹנֶה. עַכְשָׁו תּוֹרְכֶם.' % ', '.join(NAMES[sym[c]]['one'] for c in form))

    u.skill('LOG-B-04', 'סדר שגדל', 'מִגְדָּלִים שֶׁגְּדֵלִים', 'pattern-door', ['LOG-B-01'], ['pictorial', 'concrete'], ['M-PAT-GROW'])
    for i, (shown, gap) in enumerate([((1, 2, None, 4), 3), ((None, 2, 3, 4), 1), ((1, 2, 3, None), 4), ((2, 3, None, 5), 4),
                                      ((3, 4, None, 6), 5), ((1, 2, 3, 4, None), 5)]):
        row = ['?' if v is None else 'tower_%d' % v for v in shown]
        others = ['tower_%d' % (gap - 1 if gap > 1 else gap + 2), 'tower_%d' % (gap + 1 if gap < 6 else gap - 2)]
        if gap == 1:
            others = ['tower_5', 'tower_6']
        u.act('LOG-B-04', 'pick', prompt='הַמִּגְדָּלִים גְּדֵלִים. אֵיזֶה מִגְדָּל חָסֵר?', row=row, options=place('tower_%d' % gap, others, i % 3),
              correct='tower_%d' % gap, tags={others[0]: 'M-PAT-GROW'}, rep='pictorial', domain='logic',
              correct_text='כֵּן! כָּל מִגְדָּל גָּבוֹהַּ בְּקֻבִּיָּה אַחַת.', h3='כָּל מִגְדָּל גָּבוֹהַּ בְּקֻבִּיָּה אַחַת מִקּוֹדְמוֹ. עַכְשָׁו תּוֹרְכֶם.')

    u.skill('LOG-B-06', 'מוצאים את הכלל', 'מוֹצְאִים מָה מְשֻׁתָּף', 'sprout', ['LOG-A-03'], ['pictorial'], [])
    sets = [(['shape_circle_red', 'shape_square_red', 'shape_triangle_red'], 'rule_colour', 'אוֹתוֹ צֶבַע'),
            (['shape_circle_blue', 'shape_triangle_blue', 'shape_square_blue'], 'rule_colour', 'אוֹתוֹ צֶבַע'),
            (['shape_circle_red', 'shape_circle_blue', 'shape_circle_green'], 'rule_shape', 'אוֹתָהּ צוּרָה'),
            (['shape_square_green', 'shape_square_red', 'shape_square_blue'], 'rule_shape', 'אוֹתָהּ צוּרָה'),
            (['apple_size_l', 'star_size_l', 'fish_size_l'], 'rule_size', 'אוֹתוֹ גֹּדֶל'),
            (['apple_size_s', 'fish_size_s', 'star_size_s'], 'rule_size', 'אוֹתוֹ גֹּדֶל')]
    for i, (row, rule, text) in enumerate(sets):
        others = [r for r in ('rule_colour', 'rule_shape', 'rule_size') if r != rule]
        u.act('LOG-B-06', 'pick', prompt='מַה מְשֻׁתָּף לְכֻלָּם?', row=row, options=place(rule, others, i % 3), correct=rule, rep='pictorial',
              domain='logic', correct_text='כֵּן! כֻּלָּם %s.' % text, h3='נִסְתַּכֵּל עַל כֻּלָּם: כֻּלָּם %s. עַכְשָׁו תּוֹרְכֶם.' % text)

    u.skill('LOG-B-08', 'אם אז', 'אִם… אָז…', 'sprout', ['LOG-B-06'], ['concrete'], ['M-SORT-SHIFT'])
    ifs = [('אִם הַצּוּרָה אֲדֻמָּה, שָׂמִים אוֹתָהּ בַּקֻּפְסָה.', lambda s: s.endswith('_red')),
           ('אִם הַצּוּרָה כְּחֻלָּה, שָׂמִים אוֹתָהּ בַּקֻּפְסָה.', lambda s: s.endswith('_blue')),
           ('אִם הַצּוּרָה עִגּוּל, שָׂמִים אוֹתָהּ בַּקֻּפְסָה.', lambda s: s.startswith('shape_circle')),
           ('אִם הַצּוּרָה רִבּוּעַ, שָׂמִים אוֹתָהּ בַּקֻּפְסָה.', lambda s: s.startswith('shape_square'))]
    pool = ['shape_circle_red', 'shape_square_blue', 'shape_triangle_red', 'shape_circle_blue', 'shape_square_red', 'shape_triangle_blue']
    for i, (text, test) in enumerate(ifs):
        order = pool[i:] + pool[:i]
        u.act('LOG-B-08', 'sort', bins=[{'sprite': 'basket_empty', 'label': 'הַקֻּפְסָה'}, {'sprite': 'grass', 'label': 'הָעֵשֶׂב'}],
              items=[(s, 1 if test(s) else 2) for s in order[:5]], prompt=text + ' אַחֶרֶת — לָעֵשֶׂב.', domain='logic',
              h3='לְכָל צוּרָה שׁוֹאֲלִים: הַאִם זֶה מַתְאִים לַכְּלָל? אִם כֵּן — לַקֻּפְסָה. עַכְשָׁו תּוֹרְכֶם.',
              correct_text='כֵּן! עֲשִׂיתֶם לְפִי הַכְּלָל.')

    u.skill('LOG-B-09', 'חושבים ומסיקים', 'לֹא זֶה וְלֹא זֶה', 'sprout', ['LOG-B-06'], ['concrete', 'symbolic'], ['M-LOG-NOT'])
    cases = [('red', 'circle', 'blue', 'square'), ('blue', 'square', 'green', 'triangle'), ('green', 'triangle', 'red', 'circle'),
             ('red', 'square', 'blue', 'triangle'), ('blue', 'circle', 'green', 'square'), ('green', 'circle', 'red', 'triangle')]
    for i, (nc, ns, rc, rs) in enumerate(cases):
        right = 'shape_%s_%s' % (rs, rc)
        w1 = 'shape_%s_%s' % (ns, rc)  # the shape that it must not be
        w2 = 'shape_%s_%s' % (rs, nc)  # the colour that it must not be
        u.act('LOG-B-09', 'pick', prompt='הוּא לֹא %s וְלֹא %s. אֵיזֶה הוּא?' % (C[nc], SHAPE_ONE[ns]),
              options=place(right, [w1, w2], i % 3), correct=right, tags={w1: 'M-LOG-NOT', w2: 'M-LOG-NOT'}, rep='symbolic', domain='logic',
              correct_text='כֵּן! הוּא לֹא %s וְלֹא %s.' % (C[nc], SHAPE_ONE[ns]),
              h3='צָרִיךְ שֶׁגַּם לֹא %s וְגַם לֹא %s. עַכְשָׁו תּוֹרְכֶם.' % (C[nc], SHAPE_ONE[ns]))

    u.skill('LOG-B-11', 'מסדרים חמישה', 'מְסַדְּרִים מִנָּמוּךְ לְגָבוֹהַּ', 'sprout', ['LOG-A-10'], ['concrete', 'pictorial'], ['M-SER-ENDS'])
    towers = ['tower_%d' % k for k in range(1, 7)]
    u.act('LOG-B-11', 'build', palette=towers[:5], sequence=towers[:5], prompt='מְסַדְּרִים אֶת הַמִּגְדָּלִים מֵהַנָּמוּךְ אֶל הַגָּבוֹהַּ.',
          domain='logic', h3='מַתְחִילִים בַּנָּמוּךְ וְגּוֹמְרִים בַּגָּבוֹהַּ. עַכְשָׁו תּוֹרְכֶם.')
    u.act('LOG-B-11', 'build', palette=towers[:5], sequence=towers[:5][::-1], prompt='מְסַדְּרִים אֶת הַמִּגְדָּלִים מֵהַגָּבוֹהַּ אֶל הַנָּמוּךְ.',
          domain='logic', h3='מַתְחִילִים בַּגָּבוֹהַּ וְגּוֹמְרִים בַּנָּמוּךְ. עַכְשָׁו תּוֹרְכֶם.')
    u.act('LOG-B-11', 'build', palette=towers, sequence=towers, prompt='מְסַדְּרִים שִׁשָּׁה מִגְדָּלִים מֵהַנָּמוּךְ אֶל הַגָּבוֹהַּ.',
          domain='logic', h3='מַתְחִילִים בַּנָּמוּךְ וְגּוֹמְרִים בַּגָּבוֹהַּ. עַכְשָׁו תּוֹרְכֶם.')

    ids = lambda skill, a=0, b=None: lesson_ids(u, skill, a, b)
    u.lesson('longer-patterns', 'סֵדֶר שֶׁל שְׁלוֹשָׁה', ['LOG-B-01'], ids('LOG-B-01', 0, 4), 'כׇּל הַכָּבוֹד! הִמְשַׁכְתֶּם סֵדֶר.')
    u.lesson('longer-patterns-more', 'עוֹד סְדָרִים', ['LOG-B-01'], ids('LOG-B-01', 4), 'מְצֻיָּן! הַסֵּדֶר נִמְשָׁךְ.')
    u.lesson('broken-pattern', 'מָה נִשְׁבַּר', ['LOG-B-02'], ids('LOG-B-02'), 'כׇּל הַכָּבוֹד! מְצָאתֶם אֶת הַשּׁוֹנֶה.')
    u.lesson('growing-towers', 'מִגְדָּלִים שֶׁגְּדֵלִים', ['LOG-B-04'], ids('LOG-B-04'), 'כׇּל הַכָּבוֹד! הַמִּגְדָּלִים גְּדֵלִים.')
    u.lesson('find-the-rule', 'מָה הַכְּלָל', ['LOG-B-06'], ids('LOG-B-06'), 'כׇּל הַכָּבוֹד! מְצָאתֶם אֶת הַכְּלָל.')
    u.lesson('if-then', 'אִם… אָז…', ['LOG-B-08'], ids('LOG-B-08'), 'כׇּל הַכָּבוֹד! עֲשִׂיתֶם לְפִי הַכְּלָל.')
    u.lesson('not-this-not-that', 'לֹא זֶה וְלֹא זֶה', ['LOG-B-09'], ids('LOG-B-09'), 'כׇּל הַכָּבוֹד! פִּתַּחְתֶּם חִידָּה.')
    u.lesson('line-up-five', 'מְסַדְּרִים בְּשׁוּרָה', ['LOG-B-11'], ids('LOG-B-11'), 'כׇּל הַכָּבוֹד! הַמִּגְדָּלִים בַּסֵּדֶר.')
    u.save()


# ======================================================================================== COMPUTER SCIENCE

def robots():
    u = Unit('band-b-robots', 'cs',
             'Band B of Computer science: longer robot paths in a bigger grid, and finding the wrong step in a program. '
             'Hebrew is a draft by Claude, needs-editor.',
             30, assets=['robot', 'flag'])
    u.tag('M-CS-FIXALL', ['CS-B-04'], 'כשיש טעות בתוכנית הילד מוחק את כולה ומתחיל מחדש, במקום לתקן צעד אחד.',
          'להכין יחד סדר פעולות של בוקר (לקום, להתלבש, לאכול), להחליף צעד אחד ולבקש מהילד לתקן רק אותו.',
          ['concrete', 'embodied'], 'לֹא צָרִיךְ לְהַתְחִיל מֵחָדָשׁ. מוֹצְאִים אֶת הַצַּעַד הַלֹּא נָכוֹן וּמְתַקְּנִים רַק אוֹתוֹ.')

    u.skill('CS-B-01', 'תכנון דרך ארוכה', 'מְתַכְנְנִים דֶּרֶךְ שֶׁל כַּמָּה צְעָדִים', 'dock', ['CS-A-04'], ['embodied'], ['M-CS-OFF1'])
    paths = [(4, 4, (0, 3), ['up', 'up', 'right', 'right', 'up']), (4, 4, (3, 3), ['left', 'left', 'up', 'up', 'left']),
             (5, 3, (0, 2), ['right', 'right', 'up', 'right', 'right', 'up']), (4, 4, (0, 0), ['down', 'down', 'right', 'right', 'down']),
             (5, 4, (4, 3), ['left', 'left', 'up', 'up', 'left', 'up']), (4, 4, (1, 3), ['up', 'right', 'up', 'right', 'up', 'left']),
             (5, 4, (0, 3), ['right', 'up', 'right', 'up', 'right', 'up']), (4, 4, (3, 0), ['down', 'left', 'down', 'left', 'down', 'left'])]
    delta = {'up': (0, -1), 'down': (0, 1), 'left': (-1, 0), 'right': (1, 0)}
    for i, (cols, rows, start, sol) in enumerate(paths):
        c, r = start
        for d in sol:
            c, r = c + delta[d][0], r + delta[d][1]
            assert 0 <= c < cols and 0 <= r < rows, (i, sol)
        u.act('CS-B-01', 'robot', mode='plan' if i % 2 == 0 else 'direct', cols=cols, rows=rows, robot=list(start), goal=[c, r], solution=sol,
              maxSteps=min(8, len(sol) + 2), domain='cs',
              prompt='הָרוֹבּוֹט צָרִיךְ לְהַגִּיעַ אֶל הַדֶּגֶל. %s' % (
                  'מְתַכְנְנִים אֶת הַצְּעָדִים וְלוֹחֲצִים עַל הַתְחָלָה.' if i % 2 == 0 else 'מַזִּיזִים אוֹתוֹ בְּעֶזְרַת הַחִצִּים.'))

    u.skill('CS-B-04', 'מתקנים תוכנית', 'מוֹצְאִים אֶת הַצַּעַד הַלֹּא נָכוֹן', 'dock', ['CS-B-01'], ['symbolic', 'embodied'], ['M-CS-FIXALL'])
    progs = [(['up', 'right'], 3, 'left'), (['right', 'right', 'up'], 4, 'down'), (['up', 'up', 'right'], 5, 'left'),
             (['left', 'down'], 3, 'right'), (['right', 'up'], 2, 'down'), (['down', 'down', 'left'], 4, 'right')]
    names = {'up': 'לְמַעְלָה', 'down': 'לְמַטָּה', 'left': 'שְׂמֹאלָה', 'right': 'יָמִינָה'}
    for i, (unit, w, bad) in enumerate(progs):
        seq = (unit * 4)[:6]
        seq[w] = bad if bad != seq[w] else 'up'
        u.act('CS-B-04', 'spot', cells=['dir:' + d for d in seq], wrong=w, tag='M-CS-FIXALL', rep='embodied', domain='cs',
              prompt='הַתָּכְנִית צְרִיכָה לַחֲזֹר עַל: %s. אֵיפֹה הַצַּעַד הַלֹּא נָכוֹן?' % ', '.join(names[d] for d in unit),
              h3='הַתָּכְנִית חוֹזֶרֶת: %s. צַעַד אֶחָד שׁוֹנֶה. עַכְשָׁו תּוֹרְכֶם.' % ', '.join(names[d] for d in unit),
              correct_text='כֵּן! מְצָאתֶם אֶת הַצַּעַד. צָרִיךְ לְתַקֵּן רַק אוֹתוֹ.')

    ids = lambda skill, a=0, b=None: lesson_ids(u, skill, a, b)
    u.lesson('longer-robot-paths', 'דְּרָכִים אֲרֻכּוֹת', ['CS-B-01'], ids('CS-B-01', 0, 4), 'כׇּל הַכָּבוֹד! תִּכְנַנְתֶּם דֶּרֶךְ אֲרֻכָּה.')
    u.lesson('longer-robot-paths-more', 'עוֹד דְּרָכִים', ['CS-B-01'], ids('CS-B-01', 4), 'מְצֻיָּן! הָרוֹבּוֹט הִגִּיעַ.')
    u.lesson('fix-the-program', 'מְתַקְּנִים תָּכְנִית', ['CS-B-04'], ids('CS-B-04'), 'כׇּל הַכָּבוֹד! תִּקַּנְתֶּם אֶת הַצַּעַד.')
    u.save()


def run():
    colours()
    shapes()
    logic()
    robots()
