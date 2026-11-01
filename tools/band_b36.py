"""B-36 part D, the Band B half: a second way of showing each of the 38 Band B skills that were taught one way only
(docs/curriculum/b36-second-representations.md, section 3), plus the two Band A count items of NUM-A-07 whose lessons live in
band-b-extra-numbers. Each unit builder of band_b.py, band_b2.py and band_b3.py calls its function here just before `u.save()`,
so the ids are the next free numbers of each skill (existing ids never move) and every new item joins the lesson the spec names,
or a new continuation lesson `<lesson>-1-b36` placed after the older ones. Every text is a draft and stays `needs-editor`.
"""
import statistics

from author import F, M, count_words, from_, qty, vav  # noqa: E402

CARD_TAKE = ['vo:fb.card.take', 'זֶה כַּמָּה שֶׁהָיוּ בַּהַתְחָלָה, לִפְנֵי שֶׁלָּקַחְנוּ. בּוֹאוּ נִסְפֹּר כַּמָּה נִשְׁאֲרוּ.']
SOLIDS_LINE = ['vo:fb.shp_name.solids', 'לְכׇל גּוּף יֵשׁ שֵׁם מִשֶּׁלּוֹ. בּוֹאוּ נִסְתַּכֵּל: הוּא מִתְגַּלְגֵּל? יֵשׁ לוֹ פִּנּוֹת?']
SHADE_ENDS = ['vo:fb.ser_ends.shade', 'מְחַפְּשִׂים אֶת הָאֶמְצַע: לֹא הֲכִי בָּהִיר וְלֹא הֲכִי כֵּהֶה.']
SHADE_END_PICK = ['vo:fb.ser_ends.shade_end', 'זֶה הָאֶמְצַע. בּוֹאוּ נַשְׁוֶה אֶת כֻּלָּם: בָּהִיר, אֶמְצָעִי, כֵּהֶה.']
MIRROR_LINE = ['vo:fb.num_mirror', 'הַסִּפְרָה הַזֹּאת הֲפוּכָה, כְּמוֹ בַּמַּרְאָה. בּוֹאוּ נִסְתַּכֵּל לְאֵיזֶה צַד הִיא פּוֹנָה.']
SHADE_SAME = ['vo:fb.col_shade.plain', 'בָּהִיר אוֹ כֵּהֶה, זֶה אוֹתוֹ צֶבַע. בּוֹאוּ נִבְדֹּק שׁוּב.']


def steps(k):
    return 'צַעַד אֶחָד' if k == 1 else ('שְׁנֵי צְעָדִים' if k == 2 else '%s צְעָדִים' % M[k])


class Adder:
    """Adds the items of one unit and records where each belongs."""

    def __init__(self, u):
        self.u = u
        self.placed = []  # (item id, lesson id)

    def difficulty(self, skill, kind):
        base = statistics.median([a['difficulty'] for a in self.u.d['activities'] if a['skill'] == skill] or [0.5])
        base += {'count_tap': -0.05, 'give': -0.05, 'scale': 0.05, 'build': 0.05}.get(kind, 0)
        return round(min(0.9, max(0.1, base)), 2)

    def add(self, want, lesson, skill, kind, **kw):
        kw.setdefault('difficulty', self.difficulty(skill, kind))
        new_id = kw.pop('id', None)
        got = self.u.act(skill, kind, **kw)
        if new_id:  # a Band A item that lives in a Band B unit
            act = self.u.d['activities'][-1]
            act['id'] = new_id
            got = new_id
        else:
            assert got == want, 'the spec says %s, the generator made %s' % (want, got)
        self.placed.append((got, lesson))
        return got

    def finish(self):
        lessons = {l['id']: l for l in self.u.d['lessons']}
        for item, lesson in self.placed:
            if lesson not in lessons:
                base = lessons[lesson.replace('-1-b36', '')]
                new = {'id': lesson, 'title': base['title'], 'skills': base['skills'], 'items': [], 'minutes': base['minutes'],
                       'done': base['done']}
                self.u.d['lessons'].append(new)
                lessons[lesson] = new
            lessons[lesson]['items'].append(item)


def cubes(n):
    """'three cubes' with the number agreeing with the feminine noun."""
    return 'קֻבִּיָּה אַחַת' if n == 1 else ('שְׁתֵּי קֻבִּיּוֹת' if n == 2 else '%s קֻבִּיּוֹת' % F[n])


def tiles(correct, others, i):
    """The right numeral among its wrong ones, in the place the item number picks."""
    o = ['n:%d' % v for v in others]
    o.insert(i % 3, 'n:%d' % correct)
    return o


# ======================================================================================== numbers (band_b.py numbers())
def numbers(u):
    A = Adder(u)
    obj = u.d['objects']

    def line(want, lesson, skill, frm, to, labels, target, check, tag='M-CNT-SEQ', word='עַל'):
        A.add(want, lesson, skill, 'numline', mode='place', to=to, target=target, labels=labels, tag=tag, check=check, **{'from': frm},
              prompt='הַצְּפַרְדֵּעַ רוֹצָה לַעֲמֹד עַל %s. נוֹגְעִים בַּמָּקוֹם.' % F[target])

    line('b.numb01.10', 'count-to-20-more', 'NUM-B-01', 10, 20, [10, 20], 14, 'practice')
    line('b.numb01.11', 'count-to-20-more', 'NUM-B-01', 10, 20, [10, 15, 20], 17, 'transfer')
    line('b.numb02.10', 'count-to-30-more', 'NUM-B-02', 15, 35, [15, 25, 35], 30, 'practice', tag='M-CNT-DECADE')
    line('b.numb02.11', 'count-to-30-more', 'NUM-B-02', 10, 30, [10, 15, 30], 20, 'transfer', tag='M-CNT-DECADE')
    for want, start, check in (('b.numb03.11', 10, 'predict'), ('b.numb03.12', 7, 'predict')):
        A.add(want, 'rocket-countdown', 'NUM-B-03', 'numline', mode='jump', to=10, start=start, hops=[-3], target=start - 3,
              labels=list(range(0, 11)), tag='M-CNT-SEQ', check=check,
              prompt='הַצְּפַרְדֵּעַ סוֹפֶרֶת אֲחוֹרָה כְּמוֹ חֲלָלִית: %s, %s אֲחוֹרָה. עַל אֵיזֶה מִסְפָּר הִיא תִּנְחַת?' % (
                  from_(F[start]), steps(3)),
              h3='מַתְחִילִים %s וְקוֹפְצִים %s אֲחוֹרָה. עַכְשָׁו תּוֹרְכֶם.' % (from_(F[start]), steps(3)))
    for want, o, n, opts, check in (('b.numb04.12', 'fish', 13, [12, 13, 14], 'practice'), ('b.numb04.13', 'ladybug', 16, [15, 16, 17], 'transfer')):
        A.add(want, 'many-things-more', 'NUM-B-04', 'set_to_numeral', obj=o, count=n, options=opts, arrangement='ten_frame', check=check)
    for want, o, ask, wrong, who, check in (('b.numb05.11', 'fish', 12, 13, 'הֶחָתוּל', 'reverse'), ('b.numb05.12', 'bird', 16, 15, 'הַבַּרְוָז', 'transfer')):
        pile = '%s*%d#ten_frame'
        A.add(want, 'give-up-to-20', 'NUM-B-05', 'pick', check=check,
              prompt='יֵשׁ כָּאן %s. %s בִּקֵּשׁ %s. אֵיזוֹ צַלַּחַת נְכוֹנָה?' % (qty(20, obj[o]), who, qty(ask, obj[o])),
              group={'sprite': o, 'count': 20, 'arrangement': 'ten_frame', 'seed': 5},
              options=[pile % (o, ask), pile % (o, 20), pile % (o, wrong)], correct=pile % (o, ask),
              tags={pile % (o, 20): 'M-CNT-CARD', pile % (o, wrong): 'M-CNT-DOUBLE' if wrong == ask + 1 else 'M-CNT-SKIP'},
              correct_text='כֵּן! %s.' % qty(ask, obj[o]),
              h3='סוֹפְרִים וְעוֹצְרִים: %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַצַּלַּחַת.' % count_words(ask))
    for want, o, n, wrong, off, check in (('b.numb08.15', 'fish', 13, 3, 14, 'practice'), ('b.numb08.16', 'star', 17, 7, 16, 'transfer')):
        pile = '%s*%d#ten_frame'
        A.add(want, 'read-the-teens-more', 'NUM-B-08', 'pick', check=check, numeral=n,
              prompt='אֵיזוֹ צַלַּחַת יֵשׁ בָּהּ בְּדִיּוּק כַּמָּה שֶׁכָּתוּב?',
              options=[pile % (o, n), pile % (o, wrong), pile % (o, off)], correct=pile % (o, n),
              tags={pile % (o, wrong): 'M-NUM-TEEN', pile % (o, off): 'M-CNT-SEQ'}, correct_text='כֵּן! %s.' % qty(n, obj[o]),
              h3='עֶשֶׂר וְעוֹד %s: %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַצַּלַּחַת.' % (F[n - 10], F[n]))
    A.add('b.numb10.11', 'which-is-bigger-more', 'NUM-B-10', 'pick', check='practice',
          prompt='אֵיזֶה מִסְפָּר גָּדוֹל יוֹתֵר, %s אוֹ %s?' % (F[9], F[6]),
          group={'sprite': 'apple', 'count': 9, 'arrangement': 'ten_frame', 'seed': 3},
          group2={'sprite': 'apple', 'count': 6, 'arrangement': 'ten_frame', 'seed': 8, 'scale': 1.5},
          options=['n:9', 'n:6'], correct='n:9', tags={'n:6': 'M-CNT-SIZE'}, size_cue='big', correct_text='כֵּן! הַמִּסְפָּר %s גָּדוֹל יוֹתֵר.' % F[9],
          h3='מְחַבְּרִים אֶחָד לְאֶחָד: לְתֵשַׁע יֵשׁ עוֹד שָׁלוֹשׁ בְּלִי זוּג, אָז תֵּשַׁע גָּדוֹל יוֹתֵר. עַכְשָׁו תּוֹרְכֶם.')
    A.add('b.numb10.12', 'which-is-bigger-more', 'NUM-B-10', 'pick', check='reverse',
          prompt='אֵיזֶה מִסְפָּר קָטָן יוֹתֵר, %s אוֹ %s?' % (F[4], F[7]),
          group={'sprite': 'apple', 'count': 4, 'arrangement': 'line', 'seed': 3},
          group2={'sprite': 'apple', 'count': 7, 'arrangement': 'line', 'seed': 8, 'scale': 0.7},
          options=['n:4', 'n:7'], correct='n:4', tags={'n:7': 'M-CNT-SIZE'}, size_cue='small', correct_text='כֵּן! הַמִּסְפָּר %s קָטָן יוֹתֵר.' % F[4],
          h3='מְחַבְּרִים אֶחָד לְאֶחָד: לְשֶׁבַע יֵשׁ עוֹד שָׁלוֹשׁ בְּלִי זוּג, אָז אַרְבַּע קָטָן יוֹתֵר. עַכְשָׁו תּוֹרְכֶם.')
    A.add('b.numb11.19', 'one-more-one-less-1-b36', 'NUM-B-11', 'numline', mode='place', to=10, target=7, labels=[0, 6, 10], tag='M-CNT-SEQ',
          check='practice', prompt='שִׂימוּ אֶת הַצְּפַרְדֵּעַ עַל הַמִּסְפָּר שֶׁהוּא אֶחָד יוֹתֵר %s.' % from_(F[6]),
          h3='מַתְחִילִים בְּשֵׁשׁ וְקוֹפְצִים קְפִיצָה אַחַת קָדִימָה. עַכְשָׁו תּוֹרְכֶם.')
    A.add('b.numb11.20', 'one-more-one-less-1-b36', 'NUM-B-11', 'numline', mode='place', to=10, target=8, labels=[0, 9, 10], tag='M-CNT-SEQ',
          check='reverse', prompt='שִׂימוּ אֶת הַצְּפַרְדֵּעַ עַל הַמִּסְפָּר שֶׁהוּא אֶחָד פָּחוֹת %s.' % from_(F[9]),
          h3='מַתְחִילִים בְּתֵשַׁע וְקוֹפְצִים קְפִיצָה אַחַת אֲחוֹרָה. עַכְשָׁו תּוֹרְכֶם.')
    for want, cells, w, check in (('b.numb13.22', [0, 1, 2, 3, 8, 5, 6], 4, 'error_spotting'), ('b.numb13.23', [4, 5, 6, 2, 8, 9, 10], 3, 'error_spotting')):
        right = cells[w - 1] + 1
        A.add(want, 'frog-jumps', 'NUM-B-13', 'spot', cells=['n:%d' % c for c in cells], wrong=w, tag='M-NL-SPACE', check=check,
              prompt='חָבֵר כָּתַב אֶת הַמִּסְפָּרִים שֶׁל קַו הַצְּפַרְדֵּעַ, וּמִסְפָּר אֶחָד לֹא בַּמָּקוֹם. אֵיפֹה הוּא?',
              correct_text='כֵּן! בַּמָּקוֹם הַזֶּה הָיָה צָרִיךְ לִהְיוֹת %s.' % F[right])
    for want, left, right, check in (('b.numb14.11', 6, 2, 'practice'), ('b.numb14.12', 8, 3, 'transfer')):
        A.add(want, 'split-numbers-more', 'NUM-B-14', 'scale', mode='balance', left=[('block', left, 1)], right=[('block', right, 1)],
              block='block', result=left - right, tag='M-PART-MISS', check=check,
              prompt='%s בְּצַד אֶחָד, %s בַּצַּד הַשֵּׁנִי. מוֹסִיפִים קֻבִּיּוֹת עַד שֶׁשְּׁנֵי הַצְּדָדִים שָׁוִים.' % (cubes(left), cubes(right)),
              h3='%s בְּצַד אֶחָד, %s בַּצַּד הַשֵּׁנִי. מוֹסִיפִים קֻבִּיָּה אַחַר קֻבִּיָּה, עַד שֶׁיֵּשׁ %s. עַכְשָׁו תּוֹרְכֶם.' % (
                  cubes(left), cubes(right), F[left]),
              correct_text='כֵּן! הַמֹּאזְנַיִם מְאֻזָּנִים.')
    A.add('b.numb17.13', 'tens-and-twos-1-b36', 'NUM-B-17', 'pick', check='practice',
          prompt='סוֹפְרִים גַּרְבַּיִם בְּזוּגוֹת. כַּמָּה גַּרְבַּיִם יֵשׁ?', group={'sprite': 'sock', 'count': 10, 'arrangement': 'ten_frame', 'seed': 3},
          options=tiles(10, [8, 12], 0), correct='n:10', tags={'n:8': 'M-CNT-SKIP', 'n:12': 'M-CNT-DOUBLE'}, correct_text='%s! סְפַרְתֶּם זוּג אַחַר זוּג.' % F[10],
          h3='סוֹפְרִים בִּשְׁתַּיִם: שְׁתַּיִם, אַרְבַּע, שֵׁשׁ, שְׁמוֹנֶה, עֶשֶׂר. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל עֶשֶׂר.')
    A.add('b.numb17.14', 'tens-and-twos-1-b36', 'NUM-B-17', 'numline', mode='jump', to=20, start=4, hops=[2, 2], target=8, labels=[0, 4, 10, 20],
          tag='M-CNT-SEQ', check='predict',
          prompt='הַצְּפַרְדֵּעַ עוֹמֶדֶת עַל %s וְקוֹפֶצֶת שְׁתֵּי קְפִיצוֹת שֶׁל שְׁתַּיִם. עַל אֵיזֶה מִסְפָּר הִיא תִּנְחַת?' % F[4],
          h3='מַתְחִילִים %s וְקוֹפְצִים בִּשְׁתַּיִם: %s, %s. עַכְשָׁו תּוֹרְכֶם.' % (from_(F[4]), F[6], F[8]))
    for want, o, n, check in (('b.numb18.11', 'sock', 8, 'practice'), ('b.numb18.12', 'shoe', 6, 'transfer')):
        A.add(want, 'pairs', 'NUM-B-18', 'share', sprite=o, n=n, friends=['cat', 'dog'], check=check,
              correct_text='כֵּן! לִשְׁנֵיהֶם יֵשׁ אוֹתוֹ מִסְפָּר: %s. %s הוּא מִסְפָּר זוּגִי.' % (F[n // 2], F[n]))
    A.finish()


# ======================================================================================== maths (band_b.py math())
def math(u):
    A = Adder(u)
    obj = u.d['objects']
    for want, left, right, check in (('b.mathb06.11', 10, 7, 'practice'), ('b.mathb06.12', 10, 4, 'transfer')):
        A.add(want, 'make-ten-more', 'MATH-B-06', 'scale', mode='balance', left=[('block', left, 1)], right=[('block', right, 1)], block='block',
              result=left - right, tag='M-PART-MISS', check=check,
              prompt='%s בְּצַד אֶחָד, %s בַּצַּד הַשֵּׁנִי. מוֹסִיפִים קֻבִּיּוֹת עַד שֶׁשְּׁנֵי הַצְּדָדִים שָׁוִים.' % (cubes(left), cubes(right)),
              h3='%s בְּצַד אֶחָד, %s בַּצַּד הַשֵּׁנִי. מוֹסִיפִים קֻבִּיָּה אַחַר קֻבִּיָּה, עַד שֶׁיֵּשׁ %s. עַכְשָׁו תּוֹרְכֶם.' % (
                  cubes(left), cubes(right), F[left]),
              correct_text='כֵּן! הַמֹּאזְנַיִם מְאֻזָּנִים.')
    A.add('b.mathb07.9', 'zero-sums', 'MATH-B-07', 'pick', check='practice',
          prompt='%s, וְעוֹד אֶפֶס. כַּמָּה יֵשׁ עַכְשָׁו?' % qty(5, obj['apple']),
          group={'sprite': 'apple', 'count': 5, 'arrangement': 'ten_frame', 'seed': 3},
          group2={'sprite': 'apple', 'count': 0, 'arrangement': 'ten_frame', 'seed': 8},
          options=tiles(5, [0, 6], 0), correct='n:5', tags={'n:0': 'M-NUM-ZERO', 'n:6': 'M-NUM-ZERO'},
          correct_text='%s! כְּשֶׁמּוֹסִיפִים אֶפֶס, הַמִּסְפָּר נִשְׁאָר.' % F[5],
          h3='%s וְעוֹד אֶפֶס: נִשְׁאֲרִים %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (F[5], F[5], F[5]))
    A.add('b.mathb07.10', 'zero-sums', 'MATH-B-07', 'pick', check='predict',
          prompt='הָיוּ %s, וְכֻלָּם שָׂחוּ הַרְחֵק. כַּמָּה נִשְׁאֲרוּ?' % qty(4, obj['fish']),
          group={'sprite': 'fish', 'count': 4, 'arrangement': 'line', 'seed': 3},
          options=tiles(0, [1, 4], 2), correct='n:0', tags={'n:1': 'M-NUM-ZERO', 'n:4': 'M-CNT-CARD'},
          tag_lines={'M-CNT-CARD': CARD_TAKE}, correct_text='%s! כְּשֶׁכֻּלָּם הָלְכוּ, נִשְׁאַר אֶפֶס.' % F[0],
          h3='%s פָּחוֹת %s: לֹא נִשְׁאַר אַף אֶחָד. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (F[4], F[4], F[0]))
    A.add('b.mathb08.15', 'to-twenty-more', 'MATH-B-08', 'pick', check='practice',
          prompt='יֵשׁ %s, וְעוֹד %s. כַּמָּה יֵשׁ בְּסַךְ הַכֹּל?' % (qty(8, obj['apple']), qty(5, obj['apple'])),
          group={'sprite': 'apple', 'count': 8, 'arrangement': 'ten_frame', 'seed': 3},
          group2={'sprite': 'apple', 'count': 5, 'arrangement': 'ten_frame', 'seed': 8},
          options=tiles(13, [3, 12], 0), correct='n:13', tags={'n:3': 'M-OP-SWAP', 'n:12': 'M-CNT-DOUBLE'},
          correct_text='%s! %s וְעוֹד %s.' % (F[13], F[8], F[5]),
          h3='%s וְעוֹד %s: מְמַלְאִים עֶשֶׂר וְסוֹפְרִים הָלְאָה. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (F[8], F[5], F[13]))
    A.add('b.mathb08.16', 'to-twenty-more', 'MATH-B-08', 'pick', check='transfer',
          prompt='הָיוּ %s. %s עָפוּ. כַּמָּה נִשְׁאֲרוּ?' % (qty(14, obj['star']), qty(5, obj['star'])),
          group={'sprite': 'star', 'count': 14, 'arrangement': 'ten_frame', 'seed': 3},
          options=tiles(9, [19, 14], 1), correct='n:9', tags={'n:19': 'M-OP-SWAP', 'n:14': 'M-CNT-CARD'},
          tag_lines={'M-CNT-CARD': CARD_TAKE}, correct_text='%s! %s פָּחוֹת %s.' % (F[9], F[14], F[5]),
          h3='%s פָּחוֹת %s: לוֹקְחִים חָמֵשׁ מֵהַמִּסְגֶּרֶת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (F[14], F[5], F[9]))
    A.add('b.mathb10.9', 'equal-groups', 'MATH-B-10', 'share', sprite='fish', n=8, friends=['cat', 'dog'], check='practice')
    A.add('b.mathb10.10', 'equal-groups', 'MATH-B-10', 'share', sprite='apple', n=6, friends=['cat', 'dog', 'duck'], check='transfer',
          prompt='מְחַלְּקִים %s בֵּין הֶחָתוּל, הַכֶּלֶב וְהַבַּרְוָז. לְכֻלָּם אוֹתוֹ מִסְפָּר.' % qty(6, obj['apple']))
    A.add('b.mathb14.12', 'days-of-the-week-1-b36', 'MATH-B-14', 'build', palette=['day_3', 'day_1', 'day_4', 'day_2'],
          sequence=['day_1', 'day_2', 'day_3', 'day_4'], tag='M-TIME-SEQ', check='practice',
          prompt='מְסַדְּרִים אֶת הַיָּמִים, מִיּוֹם רִאשׁוֹן.', correct_text='כֵּן! סִדַּרְתֶּם אֶת הַיָּמִים.',
          h3='יוֹם רִאשׁוֹן, יוֹם שֵׁנִי, יוֹם שְׁלִישִׁי, יוֹם רְבִיעִי. עַכְשָׁו תּוֹרְכֶם.')
    A.add('b.mathb14.13', 'days-of-the-week-1-b36', 'MATH-B-14', 'build', palette=['day_7', 'day_5', 'day_6'],
          sequence=['day_5', 'day_6', 'day_7'], tag='M-TIME-SEQ', check='transfer',
          prompt='מְסַדְּרִים אֶת הַיָּמִים, מִיּוֹם חֲמִישִׁי עַד שַׁבָּת.', correct_text='כֵּן! סִדַּרְתֶּם אֶת הַיָּמִים.',
          h3='יוֹם חֲמִישִׁי, יוֹם שִׁשִּׁי, שַׁבָּת. עַכְשָׁו תּוֹרְכֶם.')
    for want, total, seen, check in (('b.mathb18.10', 7, 3, 'practice'), ('b.mathb18.11', 9, 5, 'transfer')):
        hidden = total - seen
        A.add(want, 'missing-number', 'MATH-B-18', 'pick', check=check,
              prompt='בְּסַךְ הַכֹּל יֵשׁ %s. רוֹאִים %s, וְהַשְּׁאָר מֻסְתָּרִים מֵאֲחוֹרֵי הָאֶבֶן. כַּמָּה מֻסְתָּרִים?' % (qty(total, obj['fish']), qty(seen, obj['fish'])),
              group={'sprite': 'fish', 'count': seen, 'arrangement': 'line', 'seed': 3}, group2={'sprite': 'stone', 'count': 1},
              options=tiles(hidden, [total, seen + total], 0 if want.endswith('10') else 2), correct='n:%d' % hidden,
              tags={'n:%d' % total: 'M-PART-MISS', 'n:%d' % (seen + total): 'M-OP-SWAP'},
              correct_text='%s! %s וְעוֹד %s הֵם %s.' % (F[hidden], F[seen], F[hidden], F[total]),
              h3='רוֹאִים %s, וּבְסַךְ הַכֹּל יֵשׁ %s. מַה שֶּׁחָסֵר: %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (F[seen], F[total], F[hidden], F[hidden]))
    A.finish()


# ======================================================================================== colours (band_b2.py colours())
def colours(u):
    A = Adder(u)
    A.add('b.colb01.10', 'mix-colours-more', 'COL-B-01', 'pick', check='practice', rep='story',
          prompt='הַצְּפַרְדֵּעַ רוֹצָה בַּיִת יָרֹק. יֵשׁ לָהּ צֶבַע כָּחֹל. אֵיזֶה צֶבַע הִיא מוֹסִיפָה?',
          group={'sprite': 'ball_blue', 'count': 1}, options=['ball_yellow', 'ball_red', 'ball_green'], correct='ball_yellow',
          tags={'ball_red': 'M-COL-MIX', 'ball_green': 'M-COL-MIX'}, correct_text='כֵּן! כָּחֹל וְצָהֹב עוֹשִׂים יָרֹק.',
          h3='כָּחֹל וְצָהֹב מְעֹרָבִים יַחַד עוֹשִׂים יָרֹק. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַצָּהֹב.')
    A.add('b.colb01.11', 'mix-colours-more', 'COL-B-01', 'pick', check='predict', rep='story',
          prompt='הֶחָתוּל מְעָרֵב צֶבַע אָדֹם וְצֶבַע צָהֹב בִּשְׁבִיל הַכַּדּוּר שֶׁלּוֹ. אֵיזֶה צֶבַע יִהְיֶה לַכַּדּוּר?',
          group={'sprite': 'ball_red', 'count': 1}, group2={'sprite': 'ball_yellow', 'count': 1},
          options=['ball_orange', 'ball_red', 'ball_purple'], correct='ball_orange',
          tags={'ball_red': 'M-COL-MIX', 'ball_purple': 'M-COL-MIX'}, correct_text='כֵּן! אָדֹם וְצָהֹב עוֹשִׂים כָּתֹם.',
          h3='אָדֹם וְצָהֹב מְעֹרָבִים יַחַד עוֹשִׂים כָּתֹם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַכָּתֹם.')
    for want, colour, order, check in (('b.colb02.13', 'blue', [3, 1, 2], 'practice'), ('b.colb02.14', 'green', [2, 3, 1], 'transfer')):
        A.add(want, 'middle-shade', 'COL-B-02', 'build', palette=['shade_%s_%d' % (colour, k) for k in order],
              sequence=['shade_%s_%d' % (colour, k) for k in (1, 2, 3)], tag='M-SER-ENDS', tag_lines={'M-SER-ENDS': SHADE_ENDS}, check=check,
              prompt='מְסַדְּרִים מֵהַבָּהִיר אֶל הַכֵּהֶה.', correct_text='כֵּן! סִדַּרְתֶּם מֵהַבָּהִיר אֶל הַכֵּהֶה.', h3='מַתְחִילִים בַּבָּהִיר, אַחֲרָיו הָאֶמְצָעִי, וּבַסּוֹף הַכֵּהֶה. עַכְשָׁו תּוֹרְכֶם.')
    for want, (c1, w1), (c2, w2), items, check in (
            ('b.colb03.11', ('blue', 'כָּחֹל'), ('red', 'אָדֹם'), [('shade_blue_1', 1), ('shade_red_3', 2), ('shade_blue_3', 1), ('shade_red_1', 2),
                                                                  ('ball_blue', 1), ('ball_red', 2)], 'practice'),
            ('b.colb03.12', ('green', 'יָרֹק'), ('purple', 'סָגֹל'), [('shade_green_1', 1), ('shade_purple_3', 2), ('shade_green_3', 1),
                                                                     ('shade_purple_1', 2)], 'transfer')):
        A.add(want, 'same-colour-shades-more', 'COL-B-03', 'sort', rule='colour', tag='M-COL-SHADE', tag_lines={'M-COL-SHADE': SHADE_SAME}, check=check,
              prompt='%s לְכָאן, וְ%s לְכָאן, בָּהִיר אוֹ כֵּהֶה.' % (w1, w2),
              bins=[{'sprite': 'shade_%s_2' % c1, 'label': w1}, {'sprite': 'shade_%s_2' % c2, 'label': w2}], items=[list(i) for i in items])
    A.finish()


# ======================================================================================== shapes (band_b2.py shapes())
def shapes(u):
    A = Adder(u)
    sides3, sides4, sides5 = 'שָׁלוֹשׁ צְלָעוֹת', 'אַרְבַּע צְלָעוֹת', 'חָמֵשׁ צְלָעוֹת'
    A.add('b.shpb01.11', 'polygon-detectives-more', 'SHP-B-01', 'sort', tag='M-SHP-PROTO', check='practice',
          prompt='מַכְנִיסִים כׇּל צוּרָה לַצּוּרָה שֶׁיֵּשׁ לָהּ אוֹתוֹ מִסְפָּר שֶׁל צְלָעוֹת.',
          bins=[{'sprite': 'shape_triangle', 'label': sides3}, {'sprite': 'shape_quad', 'label': sides4}],
          items=[['shape_triangle_thin', 1], ['shape_square_tilt', 2], ['shape_triangle_down', 1], ['shape_rect', 2], ['shape_triangle_red', 1],
                 ['shape_square_orange', 2]])
    A.add('b.shpb01.12', 'polygon-detectives-more', 'SHP-B-01', 'sort', tag='M-SHP-PROTO', check='transfer',
          prompt='מַכְנִיסִים כׇּל צוּרָה לַצּוּרָה שֶׁיֵּשׁ לָהּ אוֹתוֹ מִסְפָּר שֶׁל צְלָעוֹת.',
          bins=[{'sprite': 'shape_triangle', 'label': sides3}, {'sprite': 'shape_quad', 'label': sides4},
                {'sprite': 'shape_pentagon', 'label': sides5}],
          items=[['shape_triangle_thin', 1], ['shape_rect', 2], ['shape_pentagon', 3], ['shape_square', 2], ['shape_triangle_down', 1]])
    A.add('b.shpb02.11', 'count-sides-more', 'SHP-B-02', 'trace', glyph='triangle', guide='full', tol=12, check='practice',
          prompt='עוֹקְבִים בָּאֶצְבַּע אַחֲרֵי כׇּל צֵלַע שֶׁל הַמְּשֻׁלָּשׁ, אַחַת אַחֲרֵי הַשְּׁנִיָּה.',
          h3='שָׁלוֹשׁ צְלָעוֹת: הוֹלְכִים עַל אַחַת, עַל עוֹד אַחַת, וְעַל הַשְּׁלִישִׁית. עַכְשָׁו תּוֹרְכֶם.',
          correct_text='כֵּן! עֲבַרְתֶּם עַל שָׁלוֹשׁ צְלָעוֹת.')
    A.add('b.shpb02.12', 'count-sides-more', 'SHP-B-02', 'trace', glyph='square', guide='start', tol=11, check='transfer',
          prompt='מְצַיְּרִים אֶת הָרִבּוּעַ, צֶלַע אַחַר צֶלַע. מַתְחִילִים מֵהַנְּקֻדָּה.',
          h3='אַרְבַּע צְלָעוֹת: הוֹלְכִים עַל כׇּל צֶלַע, אַחַת אַחַר אַחַת. עַכְשָׁו תּוֹרְכֶם.', correct_text='כֵּן! עֲבַרְתֶּם עַל אַרְבַּע צְלָעוֹת.')
    A.add('b.shpb03.8', 'square-or-rectangle', 'SHP-B-03', 'sort', tag='M-SHP-SQRECT', check='practice',
          prompt='כׇּל הַצְּלָעוֹת שָׁווֹת לְכָאן, צְלָעוֹת אֲרֻכּוֹת וּקְצָרוֹת לְכָאן.',
          bins=[{'sprite': 'shape_square_green', 'label': 'כׇּל הַצְּלָעוֹת שָׁווֹת'}, {'sprite': 'shape_rect_green', 'label': 'אֲרֻכּוֹת וּקְצָרוֹת'}],
          items=[['shape_square_tilt', 1], ['shape_rect_blue', 2], ['shape_square_red', 1], ['shape_rect_orange', 2], ['shape_square_yellow', 1],
                 ['shape_rect_red', 2]])
    A.add('b.shpb03.9', 'square-or-rectangle', 'SHP-B-03', 'sort', tag='M-SHP-SQRECT', check='transfer',
          prompt='כׇּל הַצְּלָעוֹת שָׁווֹת לְכָאן, צְלָעוֹת אֲרֻכּוֹת וּקְצָרוֹת לְכָאן.',
          bins=[{'sprite': 'shape_square', 'label': 'כׇּל הַצְּלָעוֹת שָׁווֹת'}, {'sprite': 'shape_rect', 'label': 'אֲרֻכּוֹת וּקְצָרוֹת'}],
          items=[['shape_rect_yellow', 2], ['shape_square_blue', 1], ['shape_rect_green', 2], ['shape_square_orange', 1], ['shape_square_tilt', 1]])
    A.add('b.shpb04.10', 'closed-shapes-more', 'SHP-B-04', 'sort', tag='M-SHP-CLOSED', check='practice',
          prompt='צוּרוֹת סְגוּרוֹת עִם קַוִּים יְשָׁרִים לְכָאן, וְכׇל הַשְּׁאָר לְכָאן.',
          bins=[{'sprite': 'shape_pentagon', 'label': 'סְגוּרוֹת, קַוִּים יְשָׁרִים'}, {'sprite': 'shape_open', 'label': 'כׇּל הַשְּׁאָר'}],
          items=[['shape_triangle', 1], ['shape_curved', 2], ['shape_hexagon', 1], ['shape_quad', 1], ['line_curved_arc', 2]])
    A.add('b.shpb04.11', 'closed-shapes-more', 'SHP-B-04', 'sort', tag='M-SHP-CLOSED', check='transfer',
          prompt='צוּרוֹת סְגוּרוֹת עִם קַוִּים יְשָׁרִים לְכָאן, וְכׇל הַשְּׁאָר לְכָאן.',
          bins=[{'sprite': 'shape_square', 'label': 'סְגוּרוֹת, קַוִּים יְשָׁרִים'}, {'sprite': 'shape_curved', 'label': 'כׇּל הַשְּׁאָר'}],
          items=[['shape_open_quad', 2], ['shape_pentagon', 1], ['shape_open', 2], ['shape_triangle_thin', 1], ['shape_circle', 2]])
    A.add('b.shpb08.11', 'solids-more', 'SHP-B-08', 'sort', tag='M-SHP-NAME', tag_lines={'M-SHP-NAME': SOLIDS_LINE}, check='practice',
          prompt='מַכְנִיסִים כׇּל דָּבָר אֶל הַגּוּף שֶׁהוּא דּוֹמֶה לוֹ.',
          bins=[{'sprite': 'solid_cylinder'}, {'sprite': 'solid_cone'}, {'sprite': 'solid_sphere'}],
          items=[['obj_can', 1], ['obj_party_hat', 2], ['ball_red', 3], ['obj_drum', 1]])
    A.add('b.shpb08.12', 'solids-more', 'SHP-B-08', 'sort', tag='M-SHP-NAME', tag_lines={'M-SHP-NAME': SOLIDS_LINE}, check='transfer',
          prompt='מַכְנִיסִים כׇּל דָּבָר אֶל הַגּוּף שֶׁהוּא דּוֹמֶה לוֹ.',
          bins=[{'sprite': 'solid_box'}, {'sprite': 'solid_cylinder'}, {'sprite': 'solid_sphere'}],
          items=[['obj_gift', 1], ['obj_can', 2], ['ball_blue', 3]])
    A.finish()


# ======================================================================================== logic (band_b2.py logic())
def logic(u):
    A = Adder(u)
    A.add('b.logb01.11', 'longer-patterns-more', 'LOG-B-01', 'build', tag='M-PAT-NEXT', check='practice',
          palette=['frog', 'chick', 'bird'], model=['frog', 'chick', 'chick'] * 2, sequence=['frog', 'chick', 'chick'] * 2 + ['frog', 'chick'],
          prompt='מַעֲתִיקִים אֶת הַסֵּדֶר וְעוֹשִׂים אוֹתוֹ אָרֹךְ יוֹתֵר.',
          h3='צְפַרְדֵּעַ, אֶפְרוֹחַ, אֶפְרוֹחַ, וְשׁוּב מֵהַתְחָלָה, עַד שֶׁכׇּל הַמְּקוֹמוֹת מָלֵאִים. עַכְשָׁו תּוֹרְכֶם.')
    A.add('b.logb01.12', 'longer-patterns-more', 'LOG-B-01', 'build', tag='M-PAT-NEXT', check='transfer',
          palette=['apple', 'fish', 'star'], model=['apple', 'fish', 'star'] * 2, sequence=['apple', 'fish', 'star'] * 2 + ['apple', 'fish'],
          prompt='מַעֲתִיקִים אֶת הַסֵּדֶר וְעוֹשִׂים אוֹתוֹ אָרֹךְ יוֹתֵר.',
          h3='תַּפּוּחַ, דָּג, כּוֹכָב, וְשׁוּב מֵהַתְחָלָה, עַד שֶׁכׇּל הַמְּקוֹמוֹת מָלֵאִים. עַכְשָׁו תּוֹרְכֶם.')
    A.add('b.logb02.7', 'broken-pattern', 'LOG-B-02', 'build', tag='M-PAT-UNIT', check='practice',
          palette=['ball_red', 'ball_blue', 'ball_yellow'], model=['ball_red', 'ball_red', 'ball_blue'] * 2, sequence=['ball_red', 'ball_red', 'ball_blue'],
          prompt='בּוֹנִים רַק אֶת הַחֵלֶק הַקָּטָן שֶׁחוֹזֵר.', h3='הַחֵלֶק שֶׁחוֹזֵר: אָדֹם, אָדֹם, כָּחֹל. עַכְשָׁו תּוֹרְכֶם.')
    A.add('b.logb02.8', 'broken-pattern', 'LOG-B-02', 'build', tag='M-PAT-UNIT', check='transfer',
          palette=['cat', 'dog', 'star'], model=['cat', 'dog', 'star'] * 2, sequence=['cat', 'dog', 'star'],
          prompt='בּוֹנִים רַק אֶת הַחֵלֶק הַקָּטָן שֶׁחוֹזֵר.', h3='הַחֵלֶק שֶׁחוֹזֵר: חָתוּל, כֶּלֶב, כּוֹכָב. עַכְשָׁו תּוֹרְכֶם.')
    A.add('b.logb04.9', 'growing-towers', 'LOG-B-04', 'build', tag='M-PAT-GROW', check='practice',
          palette=['tower_3', 'tower_1', 'tower_4', 'tower_2'], sequence=['tower_1', 'tower_2', 'tower_3', 'tower_4'],
          prompt='בּוֹנִים מַדְרֵגוֹת שֶׁל מִגְדָּלִים: כׇּל מִגְדָּל גָּבוֹהַּ בְּאֶחָד מֵהַקּוֹדֵם.',
          h3='כׇּל מִגְדָּל גָּבוֹהַּ בְּאֶחָד: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע. עַכְשָׁו תּוֹרְכֶם.')
    A.add('b.logb04.10', 'growing-towers', 'LOG-B-04', 'build', tag='M-PAT-GROW', check='transfer',
          palette=['tower_5', 'tower_2', 'tower_4', 'tower_3', 'tower_6'], sequence=['tower_2', 'tower_3', 'tower_4', 'tower_5'],
          prompt='בּוֹנִים מַדְרֵגוֹת שֶׁל מִגְדָּלִים. מַתְחִילִים בְּמִגְדָּל שֶׁל שְׁתֵּי קֻבִּיּוֹת.',
          h3='כׇּל מִגְדָּל גָּבוֹהַּ בְּאֶחָד: שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. עַכְשָׁו תּוֹרְכֶם.')
    box, grass = {'sprite': 'basket_empty', 'label': 'הַקֻּפְסָה'}, {'sprite': 'grass', 'label': 'הָעֵשֶׂב'}
    A.add('b.logb06.9', 'find-the-rule', 'LOG-B-06', 'sort', rule='colour', tag='M-RULE-ONE', check='practice',
          prompt='חָבֵר הִתְחִיל לְמַיֵּן. מִסְתַּכְּלִים עַל שְׁתֵּי הַקֻּפְסָאוֹת, וּמְמַיְּנִים אֶת הַשְּׁאָר בְּאוֹתָהּ דֶּרֶךְ.',
          bins=[{'sprite': 'shape_circle_red'}, {'sprite': 'shape_circle_blue'}],
          items=[['shape_square_red', 1], ['shape_triangle_blue', 2], ['shape_square_blue', 2], ['shape_triangle_red', 1]])
    A.add('b.logb06.10', 'find-the-rule', 'LOG-B-06', 'sort', rule='shape', tag='M-RULE-ONE', check='transfer',
          prompt='חָבֵר הִתְחִיל לְמַיֵּן. מִסְתַּכְּלִים עַל שְׁתֵּי הַקֻּפְסָאוֹת, וּמְמַיְּנִים אֶת הַשְּׁאָר בְּאוֹתָהּ דֶּרֶךְ.',
          bins=[{'sprite': 'shape_square_red'}, {'sprite': 'shape_triangle_red'}],
          items=[['shape_square_blue', 1], ['shape_triangle_green', 2], ['shape_square_yellow', 1], ['shape_triangle_blue', 2]])
    A.add('b.logb08.7', 'if-then', 'LOG-B-08', 'spot', tag='M-RULE-ONE', check='error_spotting',
          cells=['shape_circle_red', 'shape_circle_blue', 'shape_square_red', 'shape_circle_green'], wrong=2,
          prompt='הַכְּלָל: אִם זֶה עִגּוּל, זֶה נִכְנָס לַקֻּפְסָה. הִנֵּה מַה שֶּׁבַּקֻּפְסָה. מִי נִכְנַס בְּטָעוּת?')
    A.add('b.logb08.8', 'if-then', 'LOG-B-08', 'spot', tag='M-RULE-ONE', check='error_spotting',
          cells=['shape_square_blue', 'shape_triangle_blue', 'shape_circle_red', 'shape_circle_blue'], wrong=2,
          prompt='הַכְּלָל: אִם זֶה כָּחֹל, זֶה נִכְנָס לַקֻּפְסָה. הִנֵּה מַה שֶּׁבַּקֻּפְסָה. מִי נִכְנַס בְּטָעוּת?')
    A.add('b.logb09.9', 'not-this-not-that', 'LOG-B-09', 'sort', tag='M-LOG-NOT', check='practice',
          prompt='לֹא אָדֹם וְלֹא עִגּוּל: לַקֻּפְסָה. כׇּל הַשְּׁאָר: לָעֵשֶׂב.', bins=[box, grass],
          items=[['shape_square_blue', 1], ['shape_circle_blue', 2], ['shape_square_red', 2], ['shape_triangle_green', 1], ['shape_circle_red', 2]])
    A.add('b.logb09.10', 'not-this-not-that', 'LOG-B-09', 'sort', tag='M-LOG-NOT', check='transfer',
          prompt='לֹא כָּחֹל וְלֹא רִבּוּעַ: לַקֻּפְסָה. כׇּל הַשְּׁאָר: לָעֵשֶׂב.', bins=[box, grass],
          items=[['shape_triangle_green', 1], ['shape_square_green', 2], ['shape_triangle_blue', 2], ['shape_circle_red', 1], ['shape_square_blue', 2]])
    A.finish()


# ======================================================================================== robots (band_b2.py robots())
def robots(u):
    A = Adder(u)
    A.add('b.csb04.7', 'fix-the-program', 'CS-B-04', 'robot', mode='direct', cols=4, rows=3, robot=[2, 2], goal=[2, 0], solution=['up', 'up'],
          domain='cs', check='transfer',
          prompt='אוּפְּס, חֵץ אֶחָד הָלַךְ לְמַטָּה בִּמְקוֹם לְמַעְלָה, וְהָרוֹבּוֹט נֶעֱצַר כָּאן. מַגִּיעִים לַדֶּגֶל בַּדֶּרֶךְ הַקְּצָרָה.')
    A.add('b.csb04.8', 'fix-the-program', 'CS-B-04', 'robot', mode='direct', cols=4, rows=2, robot=[1, 1], goal=[3, 1], solution=['right', 'right'],
          domain='cs', check='transfer', prompt='הַתׇּכְנִית אָמְרָה שְׂמֹאלָה בִּמְקוֹם יָמִינָה. מַגִּיעִים אֶל הַדֶּגֶל בַּדֶּרֶךְ הַקְּצָרָה.')
    A.finish()


# ======================================================================================== band_b3.py
def extra_numbers(u, names):
    A = Adder(u)
    for key, text in (('glyph_3', F[3]), ('glyph_3_rev', 'שָׁלוֹשׁ הֲפוּכָה'), ('glyph_8', F[8]), ('glyph_7', F[7]), ('glyph_7_rev', 'שֶׁבַע הֲפוּכָה'),
                      ('glyph_1', F[1])):
        names.setdefault(key, {'one': text, 'g': 'f'})
    A.add('x.numb07.21', 'write-from-the-dot-0-4', 'NUM-B-07', 'pick', check='practice',
          prompt='אֵיפֹה הַשָּׁלוֹשׁ כְּתוּבָה נָכוֹן?', options=['glyph_3', 'glyph_3_rev', 'glyph_8'], correct='glyph_3',
          tags={'glyph_3_rev': 'M-NUM-REV', 'glyph_8': 'M-NUM-NAME'}, correct_text='כֵּן! כָּכָה כּוֹתְבִים שָׁלוֹשׁ.',
          h3='כּוֹתְבִים שָׁלוֹשׁ בִּשְׁתֵּי קְשָׁתוֹת שֶׁנִּפְתָּחוֹת שְׂמֹאלָה. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַשָּׁלוֹשׁ הַנְּכוֹנָה.',
          tag_lines={'M-NUM-REV': MIRROR_LINE})
    A.add('x.numb07.22', 'write-from-the-dot-5-9', 'NUM-B-07', 'pick', check='transfer',
          prompt='אֵיפֹה הַשֶּׁבַע כְּתוּבָה נָכוֹן?', options=['glyph_7', 'glyph_7_rev', 'glyph_1'], correct='glyph_7',
          tags={'glyph_7_rev': 'M-NUM-REV', 'glyph_1': 'M-NUM-NAME'}, correct_text='כֵּן! כָּכָה כּוֹתְבִים שֶׁבַע.',
          h3='כּוֹתְבִים שֶׁבַע: קַו שׁוֹכֵב, וְאַחֲרָיו קַו שֶׁיּוֹרֵד כְּמוֹ מַגְלֵשָׁה. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַשֶּׁבַע הַנְּכוֹנָה.',
          tag_lines={'M-NUM-REV': MIRROR_LINE})
    for i, (o, n, opts, check) in enumerate((('cat', 4, [3, 4, 5], 'practice'), ('butterfly', 5, [4, 5, 6], 'transfer')), start=1):
        A.add('b36.numa07.%d' % i, 'match-numbers-sets-more', 'NUM-A-07', 'count_tap', id='b36.numa07.%d' % i, band='A', domain='numbers', obj=o,
              count=n, options=opts, also=['NUM-A-04'], check=check, seed=70 + i)
    A.finish()


def extra_math(u, shekels, solution, coins_said):
    A = Adder(u)
    for want, price, purse, item, check in (
            ('x.mathb16.9', 5, [('s5', 1), ('s2', 1), ('s1', 2), ('a10', 2)], 'star', 'practice'),
            ('x.mathb16.10', 10, [('s10', 1), ('s5', 1), ('s2', 1), ('s1', 1), ('h50', 1)], 'apple', 'transfer')):
        sol = solution(price * 100, purse)
        assert sol, (price, purse)
        A.add(want, 'know-the-coins-more', 'MATH-B-16', 'pay', domain='math', price=price * 100, item=item, purse=purse, tag='M-MONEY-COUNT',
              misconception='M-MONEY-SIZE', check=check,
              prompt='הַמְּחִיר הוּא %s. מְשַׁלְּמִים בְּדִיּוּק, וְלוֹחֲצִים עַל הַוִּי.' % shekels(price), h3=coins_said(sol),
              correct_text='כֵּן! שִׁלַּמְתֶּם בְּדִיּוּק %s.' % shekels(price))
    for want, chart, total, wrong, check in (
            ('x.mathb17.12', [('coin_s5', 1), ('coin_s2', 1), ('coin_s1', 1)], 8, (3, 7), 'practice'),
            ('x.mathb17.13', [('coin_s10', 1), ('coin_s2', 2)], 14, (3, 12), 'transfer')):
        A.add(want, 'pay-exactly-more', 'MATH-B-17', 'pick', domain='math', check=check, prompt='כַּמָּה כֶּסֶף יֵשׁ כָּאן?', chart=chart, voice=True,
              options=tiles(total, list(wrong), 0), correct='n:%d' % total, tags={'n:%d' % wrong[0]: 'M-MONEY-COUNT', 'n:%d' % wrong[1]: 'M-CNT-SKIP'},
              correct_text='%s! מְחַבְּרִים אֶת מַה שֶּׁכָּתוּב עַל הַמַּטְבְּעוֹת.' % F[total],
              h3='מְחַבְּרִים אֶת מַה שֶּׁכָּתוּב עַל כׇּל מַטְבֵּעַ: %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (F[total], F[total]))
    A.add('x.mathb19.12', 'read-the-chart-more', 'MATH-B-19', 'sort', domain='math', rule='kind', tag='M-SORT-SHIFT', check='practice',
          prompt='כׇּל אֶחָד אֶל הַטּוּר שֶׁלּוֹ.', bins=[{'sprite': 'apple', 'label': 'תַּפּוּחִים'}, {'sprite': 'ball_red', 'label': 'כַּדּוּרִים'}],
          items=[['apple', 1], ['ball_red', 2], ['apple', 1], ['apple', 1], ['ball_red', 2], ['apple', 1]])
    A.add('x.mathb19.13', 'read-the-chart-more', 'MATH-B-19', 'sort', domain='math', rule='kind', tag='M-SORT-SHIFT', check='transfer',
          prompt='כׇּל אֶחָד אֶל הַטּוּר שֶׁלּוֹ.',
          bins=[{'sprite': 'banana_yellow', 'label': 'בָּנָנוֹת'}, {'sprite': 'ball_yellow', 'label': 'כַּדּוּרִים'}, {'sprite': 'star', 'label': 'כּוֹכָבִים'}],
          items=[['banana_yellow', 1], ['ball_yellow', 2], ['star', 3], ['star', 3], ['banana_yellow', 1], ['ball_yellow', 2]])
    A.finish()


def extra_shapes(u):
    A = Adder(u)
    A.add('x.shpb09.7', 'solid-and-face', 'SHP-B-09', 'sort', tag='M-SHP-FACE', check='practice',
          prompt='מַנִּיחִים כׇּל גּוּף עַל הַצּוּרָה שֶׁהוּא מַשְׁאִיר בַּחוֹל.', bins=[{'sprite': 'shape_circle'}, {'sprite': 'shape_square'}],
          items=[['solid_cylinder', 1], ['solid_cube', 2]])
    A.add('x.shpb09.8', 'solid-and-face', 'SHP-B-09', 'sort', tag='M-SHP-FACE', check='transfer',
          prompt='מַנִּיחִים כׇּל גּוּף עַל הַצּוּרָה שֶׁהוּא מַשְׁאִיר בַּחוֹל.',
          bins=[{'sprite': 'shape_square'}, {'sprite': 'shape_rect'}, {'sprite': 'shape_circle'}],
          items=[['solid_cube', 1], ['solid_box', 2], ['solid_cone', 3]])
    A.finish()
