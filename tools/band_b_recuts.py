"""M11 Stage 2 (docs/milestones/M11-stage2.md §4): the taps of Band B that move to a hands-on template, as data. tools/band_b.py makes each
item as before (so its id and its lesson places stay), then replaces it with the form here: the same id, `revision: 2`, a new kind.

Written by the curriculum-expert. Every text is a draft (`needs-editor`), built from phrases the pack already says where it can. A tap that
waits for a template extension of step 2.2 (a frame that starts full, cells already given) is not here; the arc file names it.
"""
import json
import os

from author import F, M, from_, prefix, qty, vav

FROG = 'הַצְּפַרְדֵּעַ'
OBJECTS = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'content', 'units', 'counting-hills.json'),
                        encoding='utf-8'))['objects']


def steps(k):
    return 'צַעַד אֶחָד' if k == 1 else ('שְׁנֵי צְעָדִים' if k == 2 else '%s צְעָדִים' % M[k])


def jump(frm, to, start, hops, labels, tag, lead='', text=None, h3=None, mirror=True):
    """The frog stands on `start` and hops; the child touches where it lands (number_line jump, the question of NUM-B-13)."""
    k = sum(hops)
    way = 'קָדִימָה' if k > 0 else 'אֲחוֹרָה'
    target = start + k
    d = {'kind': 'numline', 'mode': 'jump', 'from': frm, 'to': to, 'start': start, 'hops': list(hops), 'target': target,
         'labels': sorted(set(labels)), 'tag': tag, 'check': 'predict',
         # with a lead-in the question is shorter (a line the child hears is at most 14 words): "where will she land?"
         'prompt': ('%s%s עוֹמֶדֶת עַל %s וְקוֹפֶצֶת %s%s. אֵיפֹה הִיא תִּנְחַת?' % (
                        lead, FROG, F[start], steps(abs(k)), '' if k > 0 else ' ' + way) if lead else
                    '%s עוֹמֶדֶת עַל %s וְקוֹפֶצֶת %s %s. עַל אֵיזֶה מִסְפָּר הִיא תִּנְחַת?' % (FROG, F[start], steps(abs(k)), way)),
         'h3': h3 or 'מַתְחִילִים %s וְקוֹפְצִים %s %s. עַכְשָׁו תּוֹרְכֶם.' % (from_(F[start]), steps(abs(k)), way),
         'correct_text': text or '%s! %s נָחֲתָה עַל %s.' % (F[target], FROG, F[target])}
    if not mirror:
        d['mirror'] = False
    return d


def place(frm, to, target, labels, tag, prompt=None, text=None, mirror=True, h3=None):
    """The child puts the frog on a number (number_line place). The worked example counts to it from the nearest marked ten (on, or back)."""
    if h3 is None:
        if frm <= 1:
            way, nums = from_(F[frm]), range(max(frm, 1), target + 1)
        elif target % 10 > 5 and target // 10 * 10 + 10 <= to:
            ten = target // 10 * 10 + 10
            way, nums = '%s וְסוֹפְרִים אֲחוֹרָה' % from_(F[ten]), range(ten - 1, target - 1, -1)
        else:
            ten = max(frm, target // 10 * 10)
            way, nums = from_(F[ten]), range(ten + 1, target + 1)
        h3 = ('מַתְחִילִים %s: %s. עַכְשָׁו תּוֹרְכֶם.' if 'אֲחוֹרָה' in way else 'מַתְחִילִים %s וְסוֹפְרִים: %s. עַכְשָׁו תּוֹרְכֶם.') % (
            way, ', '.join(F[k] for k in nums))
    d = {'kind': 'numline', 'mode': 'place', 'from': frm, 'to': to, 'target': target, 'labels': sorted(set(labels)), 'tag': tag,
         'prompt': prompt or '%s רוֹצָה לַעֲמֹד עַל %s. נוֹגְעִים בַּמָּקוֹם.' % (FROG, F[target]),
         'correct_text': text or '%s! %s בַּמָּקוֹם הַנָּכוֹן.' % (F[target], FROG), 'h3': h3}
    if not mirror:
        d['mirror'] = False
    return d


THE = {'גָּדוֹל': 'הַגָּדוֹל', 'קָטָן': 'הַקָּטָן'}  # the article and its dagesh


def bigger(a, b, ask):
    """NUM-B-10 on the line: both numbers are marked; the frog goes on the bigger (or the smaller). Choosing the other mark reads the line from
    the right (M-NL-DIR): the number further right is the bigger."""
    right = max(a, b) if ask == 'big' else min(a, b)
    word = 'גָּדוֹל' if ask == 'big' else 'קָטָן'
    return place(0, 10, right, [0, a, b, 10], 'M-NL-DIR', mirror=False,
                 prompt='מִי %s יוֹתֵר, %s אוֹ %s? שָׂמִים אֶת %s עַל %s.' % (word, F[a], F[b], FROG, THE[word]),
                 text='כֵּן! %s. עַל הַצִּיר הַמִּסְפָּרִים גְּדֵלִים לְכִוּוּן הַחֵץ.' % F[right],
                 # the hint of the tap it replaces (b.numb10), said of the two numbers on the line
                 h3='%s %s. %s. עַכְשָׁו תּוֹרְכֶם.' % (F[a], vav(F[b]), 'הַמִּסְפָּר שֶׁבָּא יוֹתֵר מְאֻחָר בַּסְּפִירָה גָּדוֹל יוֹתֵר' if ask == 'big' else
                                                   'הַמִּסְפָּר שֶׁבָּא קֹדֶם בַּסְּפִירָה קָטָן יוֹתֵר'))


def share_socks(n):
    """NUM-B-18: an even number of socks dealt one to the cat and one to the dog, in turn: every round is a pair (§3.1, even counts only)."""
    return {'kind': 'share', 'n': n, 'sprite': 'sock', 'friends': ['cat', 'dog'],
            'correct_text': 'כֵּן! לִשְׁנֵיהֶם אוֹתוֹ מִסְפָּר. %s מִתְחַלֵּק לְזוּגוֹת.' % F[n]}


RECUTS = {
    # ---- NUM-B-01: one more on the line to 20 (M-CNT-SEQ; the mirror tick, M-NL-DIR)
    'b.numb01.1': jump(0, 20, 11, [1], [0, 10, 11, 20], 'M-CNT-SEQ'),
    'b.numb01.2': jump(0, 20, 13, [1], [0, 10, 13, 20], 'M-CNT-SEQ'),
    'b.numb01.3': jump(0, 20, 15, [1], [0, 10, 15, 20], 'M-CNT-SEQ'),
    # ---- NUM-B-02: across a ten. The start of the line is the ten that a restart goes back to: a touch on it is M-CNT-DECADE
    'b.numb02.1': jump(10, 30, 19, [1], [10, 19, 30], 'M-CNT-DECADE'),
    'b.numb02.2': jump(20, 40, 29, [1], [20, 29, 40], 'M-CNT-DECADE'),
    'b.numb02.3': jump(10, 30, 20, [1], [10, 20, 30], 'M-CNT-SEQ'),
    'b.numb02.6': jump(10, 30, 21, [-1], [10, 21, 30], 'M-CNT-SEQ'),
    # ---- NUM-B-03: one hop back is one less (the countdown)
    'b.numb03.1': jump(0, 10, 10, [-1], [0, 10], 'M-CNT-SEQ'),
    'b.numb03.2': jump(0, 10, 8, [-1], [0, 8, 10], 'M-CNT-SEQ'),
    'b.numb03.3': jump(0, 10, 6, [-1], [0, 6, 10], 'M-CNT-SEQ'),
    'b.numb03.4': jump(0, 10, 9, [-1], [0, 9, 10], 'M-CNT-SEQ'),
    # ---- NUM-B-08: the written teen found among the labels of the line (recognition; the reversal stays with the taps)
    'b.numb08.2': place(10, 20, 13, list(range(10, 21)), None, mirror=False),
    'b.numb08.5': place(10, 20, 16, list(range(10, 21)), None, mirror=False),
    'b.numb08.7': place(10, 20, 18, list(range(10, 21)), None, mirror=False),
    # ---- NUM-B-10: two numbers marked on the line; further right is bigger (Siegler and Ramani 2008)
    'b.numb10.1': bigger(7, 4, 'big'),
    'b.numb10.2': bigger(5, 9, 'big'),
    'b.numb10.3': bigger(8, 6, 'big'),
    'b.numb10.5': bigger(6, 3, 'small'),
    'b.numb10.6': bigger(9, 2, 'small'),
    'b.numb10.8': bigger(7, 8, 'big'),
    # ---- NUM-B-11: one more is one hop right, one less one hop left
    'b.numb11.7': jump(0, 10, 3, [1], [0, 3, 10], 'M-CNT-SEQ', text='%s! עוֹד אַחַת.' % F[4]),
    'b.numb11.9': jump(0, 10, 8, [1], [0, 8, 10], 'M-CNT-SEQ', text='%s! עוֹד אַחַת.' % F[9]),
    'b.numb11.10': jump(0, 20, 11, [1], [0, 10, 11, 20], 'M-CNT-SEQ', text='%s! עוֹד אַחַת.' % F[12]),
    'b.numb11.12': jump(0, 20, 17, [1], [0, 10, 17, 20], 'M-CNT-SEQ', text='%s! עוֹד אַחַת.' % F[18]),
    'b.numb11.13': jump(0, 10, 4, [-1], [0, 4, 10], 'M-CNT-SEQ', text='%s! אַחַת פָּחוֹת.' % F[3]),
    'b.numb11.15': jump(0, 10, 9, [-1], [0, 9, 10], 'M-CNT-SEQ', text='%s! אַחַת פָּחוֹת.' % F[8]),
    'b.numb11.16': jump(0, 20, 12, [-1], [0, 10, 12, 20], 'M-CNT-SEQ', text='%s! אַחַת פָּחוֹת.' % F[11]),
    'b.numb11.18': jump(0, 20, 18, [-1], [0, 10, 18, 20], 'M-CNT-SEQ', text='%s! אַחַת פָּחוֹת.' % F[17]),
    # ---- NUM-B-16: ten, and a hop of the ones. A touch on the ones alone (4 for 14) is M-NUM-TEEN
    **{i: jump(0, 20, 10, [n - 10], [0, 10, 20], 'M-NUM-TEEN', lead='עֶשֶׂר וְעוֹד %s: ' % F[n - 10],
               text='%s! עֶשֶׂר וְעוֹד %s הֵם %s.' % (F[n], F[n - 10], F[n]))
       for i, n in (('b.numb16.2', 12), ('b.numb16.6', 16), ('b.numb16.8', 18), ('b.numb16.10', 14), ('b.numb16.11', 17))},
    # ---- NUM-B-17: hops of ten and of two. A touch one past the start (31 after 30) is the decade slip
    'b.numb17.7': jump(20, 40, 30, [10], [20, 30], 'M-CNT-DECADE', lead='סוֹפְרִים בַּעֲשָׂרוֹת: '),
    'b.numb17.8': jump(30, 50, 40, [10], [30, 40], 'M-CNT-DECADE', lead='סוֹפְרִים בַּעֲשָׂרוֹת: '),
    'b.numb17.9': jump(60, 80, 70, [10], [60, 70], 'M-CNT-DECADE', lead='סוֹפְרִים בַּעֲשָׂרוֹת: '),
    'b.numb17.10': jump(0, 10, 6, [2], [0, 2, 4, 6, 10], 'M-CNT-SEQ', lead='סוֹפְרִים בִּשְׁתַּיִם: '),
    'b.numb17.11': jump(0, 12, 8, [2], [0, 4, 6, 8, 12], 'M-CNT-SEQ', lead='סוֹפְרִים בִּשְׁתַּיִם: '),
    # ---- NUM-B-18: the even counts dealt in pairs (the odd ones stay taps; a sort holds at most 8 cards, so ten socks stay a tap)
    'b.numb18.1': share_socks(4),
    'b.numb18.3': share_socks(6),
    'b.numb18.6': share_socks(8),
    'b.numb18.9': dict(share_socks(6), sprite='shoe', correct_text='כֵּן! לִשְׁנֵיהֶם אוֹתוֹ מִסְפָּר. שֵׁשׁ מִתְחַלֵּק לְזוּגוֹת.'),
}


def frame(obj, n):
    """Build the picture on the ten-frame: the flash pattern made by hand (as c.numb09.15)."""
    one, many, g = OBJECTS[obj]['one'], OBJECTS[obj]['many'], OBJECTS[obj]['g']
    return {'kind': 'give', 'obj': obj, 'n': n, 'source': n + 4, 'frame': True, 'variantGroup': 'fill-frame', 'check': 'practice',
            'classifiers': {'took_fewer': 'M-CNT-SKIP', 'took_more': 'M-CNT-DOUBLE'},
            'prompt': 'שִׂימוּ בַּמִּסְגֶּרֶת %s.' % qty(n, {'one': one, 'many': many, 'g': g}),
            'h1': 'שִׂימוּ %s, אֶחָד בְּכׇל מִשְׁבֶּצֶת. סוֹפְרִים בִּזְמַן שֶׁשָּׂמִים.' % qty(n, {'one': one, 'many': many, 'g': g}),
            'correct_text': '%s! עַכְשָׁו רוֹאִים %s בְּלִי לִסְפֹּר.' % (F[n], F[n])}


def pay(n, item):
    t, o = divmod(n, 10)
    tens = ', '.join(F[10 * k] for k in range(1, t + 1))
    rest = '' if not o else (', וְעוֹד שֶׁקֶל אֶחָד' if o == 1 else ', וְעוֹד %s שְׁקָלִים' % M[o])
    return {'kind': 'pay', 'price': n * 100, 'item': item, 'purse': [['s10', min(8, t + 2)], ['s1', min(8, o + 3)]], 'tag': 'M-MONEY-COUNT',
            'prompt': 'הַמְּחִיר הוּא %s שְׁקָלִים. מְשַׁלְּמִים בְּדִיּוּק, וְלוֹחֲצִים עַל הַוִּי.' % M[n],
            'h3': 'סוֹפְרִים בַּעֲשָׂרוֹת: %s%s. עַכְשָׁו תּוֹרְכֶם.' % (tens, rest),
            'correct_text': 'כֵּן! שִׁלַּמְתֶּם בְּדִיּוּק %s שְׁקָלִים.' % M[n]}

def ten(start, d):
    if d > 0:
        frm = start // 10 * 10
        labels = [frm, start, frm + 10, frm + 20]
    else:
        frm = start // 10 * 10 - 10
        labels = [frm, frm + 10, start, frm + 20]
    return jump(frm, frm + 20, start, [d], labels, 'M-HC-ROW')

def compare(a, b, ask):
    right = max(a, b) if ask == 'big' else min(a, b)
    lo = min(a, b) // 10 * 10
    hi = lo + 20
    word = 'גָּדוֹל' if ask == 'big' else 'קָטָן'
    return place(lo, hi, right, [lo, a, b, hi], 'M-PV-FACE', mirror=False,
                 prompt='מִי %s יוֹתֵר, %s אוֹ %s? שָׂמִים אֶת הַצְּפַרְדֵּעַ עַל %s.' % (word, F[a], F[b], THE[word]),
                 text='כֵּן! %s. מַשְׁוִים קֹדֶם אֶת הָעֲשָׂרוֹת.' % F[right],
                 h3='%s %s יוֹתֵר: יֵשׁ בּוֹ %s עֲשָׂרוֹת. עַכְשָׁו תּוֹרְכֶם.' % (F[right], word, 'יוֹתֵר' if ask == 'big' else 'פָּחוֹת'))

# ======== Band C (tools/band_c.py, batch C1) and the bridge skills NUM-B-06 and NUM-B-09 it holds
RECUTS.update({
    # NUM-B-06 (Band B, in this file): the numeral named found among the labels of the line 0-10
    'c.numb06.1': place(0, 10, 6, list(range(0, 11)), None, mirror=False),
    'c.numb06.3': place(0, 10, 9, list(range(0, 11)), None, mirror=False),
    'c.numb06.5': place(0, 10, 5, list(range(0, 11)), None, mirror=False),
    # NUM-B-09: build the ten-frame picture (the flash made by hand, as c.numb09.15)
    'c.numb09.1': frame('apple', 8),
    'c.numb09.2': frame('star', 6),
    # NUM-C-01: across a ten. The start of the line is the ten a restart goes back to (M-CNT-DECADE); the line is longer on the right, so the
    # mirror tick is a place of its own (M-NL-DIR)
    'c.numc01.1': jump(30, 45, 39, [1], [30, 39, 45], 'M-CNT-DECADE'),
    'c.numc01.2': jump(60, 75, 69, [1], [60, 69, 75], 'M-CNT-DECADE'),
    'c.numc01.3': jump(40, 55, 49, [1], [40, 49, 55], 'M-CNT-DECADE'),
    'c.numc01.4': jump(70, 85, 79, [1], [70, 79, 85], 'M-CNT-DECADE'),
    'c.numc01.6': jump(30, 45, 40, [-1], [30, 40, 45], 'M-CNT-SEQ'),
    'c.numc01.7': jump(60, 75, 70, [-1], [60, 70, 75], 'M-CNT-SEQ'),
    # NUM-C-02: the number read, then placed between its tens
    'c.numc02.2': place(40, 60, 47, [40, 50, 60], 'M-NL-SPACE'),
    'c.numc02.3': place(30, 50, 32, [30, 40, 50], 'M-NL-SPACE'),
    'c.numc02.5': place(40, 60, 52, [40, 50, 60], 'M-NL-SPACE'),
    'c.numc02.8': place(70, 90, 78, [70, 80, 90], 'M-NL-SPACE'),
    # NUM-C-03: tens and ones as ₪10 and ₪1 coins (the base-ten rods of Stage 3.3 come later)
    'c.numc03.1': pay(34, 'fish'),
    'c.numc03.2': pay(67, 'ball_red'),
    'c.numc03.4': pay(82, 'apple'),
    'c.numc03.14': pay(68, 'star'),
    'c.numc03.15': pay(27, 'duck'),
    'c.numc03.16': pay(81, 'fish'),
    'c.numc03.17': pay(33, 'apple'),
    # NUM-C-04: both numbers marked on the line; the one with the bigger ones digit is the face-value pick (M-PV-FACE)
    'c.numc04.1': compare(41, 39, 'big'),
    'c.numc04.2': compare(59, 62, 'big'),
    'c.numc04.3': compare(68, 73, 'big'),
    'c.numc04.4': compare(85, 79, 'big'),
    'c.numc04.5': compare(41, 38, 'small'),
    'c.numc04.6': compare(61, 56, 'small'),
    # NUM-C-09: a hop of ten. Landing one place on (35 for 34 + 10) is the hundred-chart row slip, M-HC-ROW
    'c.numc09.1': ten(34, 10),
    'c.numc09.2': ten(57, 10),
    'c.numc09.3': ten(61, -10),
    'c.numc09.4': ten(83, -10),
    'c.numc09.5': ten(48, 10),
})
for _k in ('c.numb06.1', 'c.numb06.3', 'c.numb06.5'):
    RECUTS[_k]['check'] = 'practice'


# ======== Market (Grandma Pnina), Bands B and C (docs/milestones/M11-stage2.md §3.2, §4.2)
BLOCK = {'g': 'f', 'one': 'קֻבִּיָּה', 'many': 'קֻבִּיּוֹת'}
PLUS, MINUS = 'וְעוֹד', 'פָּחוֹת'
LEVEL = 'מוֹסִיפִים קֻבִּיּוֹת עַד שֶׁשְּׁנֵי הַצְּדָדִים שָׁוִים.'


def sum_jump(a, b, frm=0, to=10, tag='M-NL-SPACE', via_ten=False):
    """a + b (or a - b for b < 0) as the frog's hops: the sum said first, then the hop. Via ten: two arcs, to the ten and on (§5.5 Ladder 2)."""
    r = a + b
    word = PLUS if b > 0 else MINUS
    hops = [b]
    h3 = None
    if via_ten and (a < 10 < r or r < 10 < a):
        first = 10 - a
        hops = [first, b - first]
        way = '' if b > 0 else ' אֲחוֹרָה'
        h3 = '%s קוֹפְצִים %s%s עַד עֶשֶׂר, וְעוֹד %s: %s. עַכְשָׁו תּוֹרְכֶם.' % (
            from_(F[a]), steps(abs(first)), way, M[abs(b - first)] if abs(b - first) > 1 else 'אֶחָד', F[r])
    labels = [frm, 10, to, a] if to > 10 else [frm, a, to]
    text = '%s! %s %s %s שָׁוֶה %s.' % (F[r], F[a], word, F[abs(b)], F[r])
    d = jump(frm, to, a, hops, labels, tag, lead='%s %s %s: ' % (F[a], word, F[abs(b)]), text=text, h3=h3)
    if len(d['prompt'].split()) > 14:  # a line the child hears is at most 14 words: the hop alone, the sum said by the praise
        d = jump(frm, to, a, hops, labels, tag, text=text, h3=h3)
    return d


def level(big, small, tag, prompt, text):
    """The balance: `big` blocks on one pan, `small` on the other; the child adds blocks until it is level (the part that is missing)."""
    left = [['block', big, 1]] if big <= 12 else [['block', 10, 1], ['block', big - 10, 1]]
    return {'kind': 'scale', 'mode': 'balance', 'left': left, 'right': [['block', small, 1]], 'block': 'block', 'result': big - small,
            'tag': tag, 'prompt': prompt,
            'h3': 'בַּצַּד שֶׁלְּמַטָּה יֵשׁ %s, וּבַצַּד שֶׁלְּמַעְלָה %s. צָרִיךְ עוֹד %s.' % (
                qty(big, BLOCK), qty(small, BLOCK), qty(big - small, BLOCK)),
            'correct_text': text}


def missing(part, whole, tag):
    """part + ? = whole on the balance (MATH-B-02, MATH-B-18)."""
    r = whole - part
    return level(whole, part, tag, '%s וְעוֹד כַּמָּה שָׁוֶה %s? %s' % (F[part], F[whole], LEVEL),
                 'כֵּן! %s וְעוֹד %s שָׁוֶה %s.' % (F[part], F[r], F[whole]))


def plates(n, k, obj, objs):
    """n things dealt to k plates in turn (MATH-B-10): every plate gets the same."""
    one, many, g = objs
    each = n // k
    o = {'one': one, 'many': many, 'g': g}
    return {'kind': 'share', 'n': n, 'sprite': obj, 'friends': ['plate'] * k,
            'prompt': 'מְחַלְּקִים %s %s, אֶחָד לְכׇל צַלַּחַת בַּתּוֹר.' % (qty(n, o), prefix('ל', qty(k, {'g': 'f', 'one': 'צַלַּחַת', 'many': 'צַלָּחוֹת'}))),
            'correct_text': 'כֵּן! בְּכׇל צַלַּחַת %s.' % qty(each, o)}


DAYS = ['יוֹם רִאשׁוֹן', 'יוֹם שֵׁנִי', 'יוֹם שְׁלִישִׁי', 'יוֹם רְבִיעִי', 'יוֹם חֲמִישִׁי', 'יוֹם שִׁשִּׁי', 'שַׁבָּת']


def week(first, decoy):
    """Three days laid in order from `first` (1 is Sunday); the palette has one more day that does not come next (M-CNT-SEQ)."""
    seq = ['day_%d' % d for d in (first, first + 1, first + 2)]
    pal = [seq[1], 'day_%d' % decoy, seq[2], seq[0]]
    return {'kind': 'build', 'sequence': seq, 'palette': pal, 'tag': 'M-CNT-SEQ',
            'prompt': 'מְסַדְּרִים אֶת הַיָּמִים לְפִי הַסֵּדֶר, מִ%s.' % DAYS[first - 1],
            'h3': '%s, %s, %s. עַכְשָׁו תּוֹרְכֶם.' % tuple(DAYS[d - 1] for d in (first, first + 1, first + 2)),
            'correct_text': 'כֵּן! %s, %s, %s.' % tuple(DAYS[d - 1] for d in (first, first + 1, first + 2)), 'goal': 'child lays the days of the week in order'}


def coins_sort(shekels):
    """Agorot and shekels sorted (MATH-B-16). The half-shekel is a big coin that is still agorot: M-MONEY-SIZE."""
    return {'kind': 'sort', 'tag': 'M-MONEY-SIZE', 'rule': 'kind',
            'bins': [{'sprite': 'coin_a10', 'label': 'אֲגוֹרוֹת'}, {'sprite': 'coin_s1', 'label': 'שְׁקָלִים'}],
            'items': [['coin_a10', 1], ['coin_h50', 1, 'M-MONEY-SIZE']] + [[c, 2] for c in shekels],
            'prompt': 'מְמַיְּנִים: אֲגוֹרוֹת לְכָאן, וּשְׁקָלִים לְכָאן.',
            'h3': 'עֶשֶׂר אֲגוֹרוֹת וַחֲצִי שֶׁקֶל הֵם אֲגוֹרוֹת. עַכְשָׁו תּוֹרְכֶם.', 'correct_text': 'כֵּן! מִיַּנְתֶּם אֶת הַמַּטְבְּעוֹת.'}


COLUMN = {'apple': 'תַּפּוּחִים', 'banana_yellow': 'בָּנָנוֹת', 'ball_red': 'כַּדּוּרִים'}


def columns(counts, most):
    """MATH-B-19: the things sorted into columns, one column for each kind (the data before the chart is read)."""
    items = []
    for k, (sprite, n) in enumerate(counts, start=1):
        items += [[sprite, k]] * n
    items = items[::2] + items[1::2]
    return {'kind': 'sort', 'rule': 'kind', 'bins': [{'sprite': s, 'count': 1, 'label': COLUMN[s]} for s, _ in counts], 'items': items,
            'prompt': 'מְמַיְּנִים: כׇּל דָּבָר עִם הַדּוֹמִים לוֹ.',
            'correct_text': 'כֵּן! מִיַּנְתֶּם. %s' % most}


def keypad(row, value, expected, h2, h3, ok, prompt='כַּמָּה זֶה?', check=None):
    """A fact typed on the keypad (recall, §4.1): the tags of the tap's distractors become the expected wrong numbers."""
    d = {'kind': 'number', 'prompt': prompt, 'row': row, 'value': value, 'expected': {str(k): t for k, t in expected.items()}, 'rules': {},
         'h2': h2, 'h3': h3, 'correct_text': ok}
    if check:
        d['check'] = check
    return d


VIA_TEN = 'עוֹבְרִים דֶּרֶךְ הָעֶשֶׂר: קֹדֶם עַד עֶשֶׂר, וְאַחַר כָּךְ מַה שֶּׁנִּשְׁאַר.'
FAMILY = 'חִבּוּר וְחִסּוּר הֵם מִשְׁפָּחָה. אֵיזֶה מִסְפָּר עוֹשֶׂה אֶת הַתַּרְגִּיל נָכוֹן?'


def fact(a, op, b, expected):
    r = a + b if op == '+' else a - b
    word = PLUS if op == '+' else MINUS
    return keypad(['n:%d' % a, 'op:%s' % op, 'n:%d' % b, 'op:=', '?'], r, expected, VIA_TEN,
                  '%s %s %s שָׁוֶה %s. כּוֹתְבִים %s.' % (F[a], word, F[b], F[r], F[r]), '%s! %s %s %s שָׁוֶה %s.' % (F[r], F[a], word, F[b], F[r]))


def family(whole, part, rest, missing_first, expected):
    """whole - ? = rest, or ? - part = rest (MATH-C-02)."""
    row = ['?', 'op:-', 'n:%d' % part, 'op:=', 'n:%d' % rest] if missing_first else ['n:%d' % whole, 'op:-', '?', 'op:=', 'n:%d' % rest]
    value = whole if missing_first else whole - rest
    return keypad(row, value, expected, FAMILY, '%s פָּחוֹת %s שָׁוֶה %s. כּוֹתְבִים %s.' % (F[whole], F[whole - rest], F[rest], F[value]),
                  '%s! %s פָּחוֹת %s שָׁוֶה %s.' % (F[value], F[whole], F[whole - rest], F[rest]), prompt='אֵיזֶה מִסְפָּר חָסֵר?', check='reverse')


def take_away_level(whole, rest):
    """whole - ? = rest on the balance: the rest on one pan, the whole on the other; the blocks added are the part taken (MATH-C-02)."""
    return level(whole, rest, 'M-EQ-OPER',
                 'בְּצַד אֶחָד %s, וּבַצַּד הַשֵּׁנִי %s. %s' % (qty(whole, BLOCK), F[rest], LEVEL),
                 'כֵּן! %s פָּחוֹת %s שָׁוֶה %s.' % (F[whole], F[whole - rest], F[rest]))


def tens_pay(a, b=None, paid=None, item='fish'):
    """MATH-C-03 in the shop: whole tens paid with ₪10 coins. a + b, or the rest of a price when `paid` is already on the counter."""
    if paid is not None:
        price = a - paid
        prompt = '%s עוֹלֶה %s שְׁקָלִים. כְּבָר שִׁלַּמְנוּ %s. מְשַׁלְּמִים אֶת הַשְּׁאָר.' % ('הַדָּג', M[a], M[paid])
        text = 'כֵּן! %s וְעוֹד %s הֵם %s.' % (M[paid], M[price], M[a])
    elif b is not None:
        price = a + b
        prompt = '%s שְׁקָלִים וְעוֹד %s שְׁקָלִים. מְשַׁלְּמִים בְּדִיּוּק, וְלוֹחֲצִים עַל הַוִּי.' % (M[a], M[b])
        text = 'כֵּן! %s וְעוֹד %s הֵם %s.' % (M[a], M[b], M[price])
    else:
        price = a
        prompt = 'הַמְּחִיר הוּא %s שְׁקָלִים. מְשַׁלְּמִים בְּדִיּוּק, וְלוֹחֲצִים עַל הַוִּי.' % M[a]
        text = 'כֵּן! שִׁלַּמְתֶּם בְּדִיּוּק %s שְׁקָלִים.' % M[a]
    t = price // 10
    return {'kind': 'pay', 'price': price * 100, 'item': item, 'purse': [['s10', min(8, t + 2)], ['s1', 4]], 'tag': 'M-MONEY-COUNT',
            'prompt': prompt, 'h3': 'סוֹפְרִים בַּעֲשָׂרוֹת: %s. עַכְשָׁו תּוֹרְכֶם.' % ', '.join(F[10 * k] for k in range(1, t + 1)),
            'correct_text': text}


TENS_WORD = {1: 'עֲשָׂרָה אַחַת', 2: 'שְׁתֵּי עֲשָׂרוֹת', 3: 'שָׁלוֹשׁ עֲשָׂרוֹת', 4: 'אַרְבַּע עֲשָׂרוֹת', 5: 'חָמֵשׁ עֲשָׂרוֹת',
             6: 'שֵׁשׁ עֲשָׂרוֹת', 7: 'שֶׁבַע עֲשָׂרוֹת', 8: 'שְׁמוֹנֶה עֲשָׂרוֹת', 9: 'תֵּשַׁע עֲשָׂרוֹת'}


def tens(a, op, b, expected):
    """Whole tens typed (MATH-C-03): hint 2 says the tens as units ("four tens and three tens")."""
    r = a + b if op == '+' else a - b
    word = PLUS if op == '+' else MINUS
    return keypad(['n:%d' % a, 'op:%s' % op, 'n:%d' % b, 'op:=', '?'], r, expected,
                  'חוֹשְׁבִים בַּעֲשָׂרוֹת: %s %s %s.' % (TENS_WORD[a // 10], word, TENS_WORD[b // 10]),
                  '%s %s %s שָׁוֶה %s. כּוֹתְבִים %s.' % (F[a], word, F[b], F[r], F[r]), '%s! %s %s %s שָׁוֶה %s.' % (F[r], F[a], word, F[b], F[r]))


_FISH = (OBJECTS['fish']['one'], OBJECTS['fish']['many'], OBJECTS['fish']['g'])
_APPLE = (OBJECTS['apple']['one'], OBJECTS['apple']['many'], OBJECTS['apple']['g'])
_STAR = (OBJECTS['star']['one'], OBJECTS['star']['many'], OBJECTS['star']['g'])
_DUCK = (OBJECTS['duck']['one'], OBJECTS['duck']['many'], OBJECTS['duck']['g'])
_BIRD = (OBJECTS['bird']['one'], OBJECTS['bird']['many'], OBJECTS['bird']['g'])

RECUTS.update({
    # MATH-B-01: join and take away as hops ("three and two more")
    'b.mathb01.1': sum_jump(3, 2), 'b.mathb01.2': sum_jump(4, 3), 'b.mathb01.7': sum_jump(5, -2), 'b.mathb01.8': sum_jump(7, -3),
    # MATH-B-02: the missing part on the balance (adding the whole is M-PART-MISS)
    **{i: missing(p, w, 'M-PART-MISS') for i, (p, w) in (('b.mathb02.2', (2, 7)), ('b.mathb02.7', (2, 6)), ('b.mathb02.8', (5, 7)),
                                                          ('b.mathb02.9', (4, 9)), ('b.mathb02.10', (3, 10)))},
    # MATH-B-03: a number sentence as start and hop
    'b.mathb03.1': sum_jump(3, 4), 'b.mathb03.2': sum_jump(5, 2), 'b.mathb03.3': sum_jump(6, 3), 'b.mathb03.5': sum_jump(7, -3),
    'b.mathb03.7': sum_jump(8, -5),
    # MATH-B-04 (Band C table): count on from the larger
    'c.mathb04.1': jump(0, 10, 7, [2], [0, 7, 10], 'M-NL-SPACE', lead='מַתְחִילִים מֵהַגָּדוֹל: ',
                        text='%s! שְׁתַּיִם וְעוֹד שֶׁבַע שָׁוֶה %s.' % (F[9], F[9])),
    'c.mathb04.3': jump(0, 10, 8, [2], [0, 8, 10], 'M-NL-SPACE', lead='מַתְחִילִים מֵהַגָּדוֹל: ',
                        text='%s! שְׁתַּיִם וְעוֹד שְׁמוֹנֶה שָׁוֶה %s.' % (F[10], F[10])),
    # MATH-B-08: within twenty, through ten (two arcs)
    'b.mathb08.1': sum_jump(8, 5, to=20, tag='M-CNT-SKIP', via_ten=True), 'b.mathb08.2': sum_jump(9, 4, to=20, tag='M-CNT-SKIP', via_ten=True),
    'b.mathb08.3': sum_jump(7, 6, to=20, tag='M-CNT-SKIP', via_ten=True), 'b.mathb08.4': sum_jump(8, 7, to=20, tag='M-CNT-SKIP', via_ten=True),
    'b.mathb08.9': sum_jump(13, -4, to=20, tag='M-CNT-SKIP', via_ten=True),
    'b.mathb08.11': sum_jump(12, -5, to=20, tag='M-CNT-SKIP', via_ten=True),
    # MATH-B-10: equal groups dealt to plates
    'b.mathb10.1': plates(6, 2, 'apple', _APPLE), 'b.mathb10.2': plates(6, 3, 'fish', _FISH), 'b.mathb10.3': plates(8, 2, 'star', _STAR),
    'b.mathb10.7': plates(6, 3, 'duck', _DUCK),
    # MATH-B-14: the days laid in order
    'b.mathb14.1': week(3, 6), 'b.mathb14.2': week(5, 2), 'b.mathb14.3': week(1, 5), 'b.mathb14.4': week(2, 6), 'b.mathb14.6': week(4, 1),
    # MATH-B-16: agorot and shekels
    'x.mathb16.7': coins_sort(['coin_s1', 'coin_s2']), 'x.mathb16.8': coins_sort(['coin_s5', 'coin_s10']),
    # MATH-B-18: the missing number on the balance (adding both numbers is M-EQ-OPER)
    **{i: missing(p, w, 'M-EQ-OPER') for i, (p, w) in (('b.mathb18.1', (3, 7)), ('b.mathb18.2', (2, 6)), ('b.mathb18.3', (4, 9)),
                                                       ('b.mathb18.4', (5, 8)))},
    # MATH-B-19: the data sorted into columns first
    'x.mathb19.1': columns([('apple', 2), ('banana_yellow', 3), ('ball_red', 1)], 'יֵשׁ הֲכִי הַרְבֵּה בָּנָנוֹת.'),
    'x.mathb19.2': columns([('apple', 3), ('banana_yellow', 1), ('ball_red', 2)], 'יֵשׁ הֲכִי הַרְבֵּה תַּפּוּחִים.'),
    'x.mathb19.3': columns([('apple', 2), ('banana_yellow', 1), ('ball_red', 3)], 'יֵשׁ הֲכִי מְעַט בָּנָנוֹת.'),
    'x.mathb19.4': columns([('apple', 1), ('banana_yellow', 2), ('ball_red', 3)], 'יֵשׁ הֲכִי מְעַט תַּפּוּחִים.'),
    'x.mathb19.6': columns([('apple', 3), ('banana_yellow', 3), ('ball_red', 2)], 'יֵשׁ שְׁמוֹנֶה בְּסַךְ הַכֹּל.'),
    # MATH-C-01: five facts typed (recall), three through ten on the line
    'c.mathc01.3': fact(9, '+', 5, {13: 'M-CNT-DOUBLE', 9: 'M-CNT-CARD', 4: 'M-OP-SWAP'}),
    'c.mathc01.4': fact(14, '-', 5, {19: 'M-OP-SWAP', 10: 'M-CNT-DOUBLE', 11: 'M-SUB-SMALLBIG'}),
    'c.mathc01.7': fact(8, '+', 4, {11: 'M-CNT-DOUBLE', 8: 'M-CNT-CARD', 4: 'M-OP-SWAP'}),
    'c.mathc01.8': fact(12, '-', 4, {16: 'M-OP-SWAP', 9: 'M-CNT-DOUBLE', 12: 'M-SUB-SMALLBIG'}),
    'c.mathc01.11': fact(8, '+', 7, {14: 'M-CNT-DOUBLE', 8: 'M-CNT-CARD', 1: 'M-OP-SWAP'}),
    'c.mathc01.5': sum_jump(9, 7, to=20, tag='M-CNT-SKIP', via_ten=True), 'c.mathc01.9': sum_jump(8, 6, to=20, tag='M-CNT-SKIP', via_ten=True),
    'c.mathc01.13': sum_jump(7, 5, to=20, tag='M-CNT-SKIP', via_ten=True),
    # MATH-C-02: three missing numbers typed, two on the balance
    'c.mathc02.1': family(15, 7, 8, False, {23: 'M-OP-SWAP', 15: 'M-EQ-OPER'}),
    'c.mathc02.2': family(13, 4, 9, False, {22: 'M-OP-SWAP', 13: 'M-EQ-OPER'}),
    'c.mathc02.6': family(15, 6, 9, True, {3: 'M-OP-SWAP', 9: 'M-EQ-OPER'}),
    'c.mathc02.4': take_away_level(14, 6), 'c.mathc02.5': take_away_level(16, 9),
    # MATH-C-03: whole tens. The facts are typed (the price tag of the shop would show a sum's answer); counting ₪10 coins stays concrete
    'c.mathc03.9': tens_pay(70, item='duck'),
    'c.mathc03.1': tens(40, '+', 30, {7: 'M-PV-FACE', 700: 'M-PV-ZERO', 10: 'M-OP-SWAP'}),
    'c.mathc03.2': tens(20, '+', 50, {7: 'M-PV-FACE', 700: 'M-PV-ZERO', 30: 'M-OP-SWAP'}),
    'c.mathc03.3': tens(60, '+', 30, {9: 'M-PV-FACE', 900: 'M-PV-ZERO', 30: 'M-OP-SWAP'}),
    'c.mathc03.5': tens(70, '-', 40, {3: 'M-PV-FACE', 300: 'M-PV-ZERO', 110: 'M-OP-SWAP'}),
    'c.mathc03.6': tens(90, '-', 50, {4: 'M-PV-FACE', 400: 'M-PV-ZERO', 140: 'M-OP-SWAP'}),
    'c.mathc03.11': keypad(['n:40', 'op:+', '?', 'op:=', 'n:90'], 50, {'5': 'M-PV-FACE', '130': 'M-EQ-OPER'},
                           'חוֹשְׁבִים בַּעֲשָׂרוֹת: אַרְבַּע עֲשָׂרוֹת, וְעוֹד כַּמָּה עֲשָׂרוֹת עַד תֵּשַׁע?',
                           'אַרְבָּעִים וְעוֹד חֲמִשִּׁים שָׁוֶה תִּשְׁעִים. כּוֹתְבִים חֲמִשִּׁים.',
                           'חֲמִשִּׁים! אַרְבָּעִים וְעוֹד חֲמִשִּׁים שָׁוֶה תִּשְׁעִים.', prompt='אֵיזֶה מִסְפָּר חָסֵר?', check='reverse'),
})


# ======== Riddle Grotto (Timi), Band B (docs/milestones/M11-stage2.md §3.5)
def grow(seq, decoy, step):
    """LOG-B-04: the growing towers built in order; the palette has one tower that breaks the rule (M-PAT-GROW)."""
    pal = [seq[2], decoy, seq[0], seq[3], seq[1]]
    return {'kind': 'build', 'sequence': ['tower_%d' % t for t in seq], 'palette': ['tower_%d' % t for t in pal], 'tag': 'M-PAT-GROW',
            'prompt': 'הַמִּגְדָּלִים גְּדֵלִים. בּוֹנִים אֶת כׇּל הַשּׁוּרָה.',
            'h3': ('כׇּל פַּעַם קֻבִּיָּה אַחַת יוֹתֵר. עַכְשָׁו תּוֹרְכֶם.' if step == 1 else 'כׇּל פַּעַם שְׁתֵּי קֻבִּיּוֹת יוֹתֵר. עַכְשָׁו תּוֹרְכֶם.'),
            'correct_text': 'כֵּן! כׇּל מִגְדָּל גָּבוֹהַּ יוֹתֵר מֵהַקּוֹדֵם.'}


COLOUR_WORD = {'red': 'אָדֹם', 'blue': 'כָּחֹל', 'green': 'יָרֹק', 'yellow': 'צָהֹב'}
SHAPE_WORD = {'circle': 'עִגּוּל', 'square': 'רִבּוּעַ', 'triangle': 'מְשֻׁלָּשׁ'}


def rule_sort(by, a, b, items):
    """LOG-B-06: each bin shows one sample, and the child finds the rule from them. A card that matches the other bin's sample in the other
    attribute is the trap (M-COL-ONEATTR)."""
    # the two samples differ only in the rule; the cards vary in the other attribute, which the child must leave aside
    if by == 'colour':
        bins = [{'sprite': 'shape_circle_%s' % a, 'label': COLOUR_WORD[a]}, {'sprite': 'shape_circle_%s' % b, 'label': COLOUR_WORD[b]}]
    else:
        bins = [{'sprite': 'shape_%s_red' % a, 'label': SHAPE_WORD[a]}, {'sprite': 'shape_%s_red' % b, 'label': SHAPE_WORD[b]}]
    return {'kind': 'sort', 'rule': by if by == 'colour' else 'shape', 'tag': 'M-COL-ONEATTR', 'bins': bins, 'items': items,
            'prompt': 'אֵיךְ מִיַּנְתִּי? שָׂמִים כׇּל צוּרָה בַּקְּבוּצָה שֶׁלָּהּ.',
            'h3': 'הַקְּבוּצוֹת הֵן לְפִי %s. עַכְשָׁו תּוֹרְכֶם.' % ('הַצֶּבַע' if by == 'colour' else 'הַצּוּרָה'),
            'correct_text': 'כֵּן! מִצֵּאתֶם אֶת הַכְּלָל.'}


def not_both(colour, shape, items):
    """LOG-B-09: in the basket every shape that is neither the colour nor the shape; the rest on the grass (a card that is one of them, M-LOG-NOT)."""
    fem = {'red': 'אֲדֻמָּה', 'blue': 'כְּחֻלָּה', 'green': 'יְרֻקָּה', 'yellow': 'צְהֻבָּה'}[colour]
    return {'kind': 'sort', 'rule': 'colour', 'tag': 'M-LOG-NOT',
            'bins': [{'sprite': 'bin_basket', 'label': 'הַסַּל'}, {'sprite': 'bin_grass', 'label': 'הַדֶּשֶׁא'}], 'items': items,
            'prompt': 'בַּסַּל: כׇּל צוּרָה שֶׁהִיא לֹא %s וְגַם לֹא %s. הַשְּׁאָר עַל הַדֶּשֶׁא.' % (fem, SHAPE_WORD[shape]),
            'h3': 'בּוֹדְקִים כׇּל צוּרָה פַּעֲמַיִם: הַצֶּבַע, וְאַחַר כָּךְ הַצּוּרָה. עַכְשָׁו תּוֹרְכֶם.', 'correct_text': 'כֵּן! שְׁנֵי הָרְמָזִים נִבְדְּקוּ.'}


_N = 'M-LOG-NOT'
RECUTS.update({
    'b.logb04.1': grow([1, 2, 3, 4], 6, 1), 'b.logb04.3': grow([2, 3, 4, 5], 7, 1), 'b.logb04.5': grow([3, 4, 5, 6], 1, 1),
    'b.logb04.7': grow([1, 3, 5, 7], 4, 2),
    'b.logb06.1': rule_sort('colour', 'red', 'blue', [['shape_square_red', 1], ['shape_triangle_blue', 2], ['shape_triangle_red', 1],
                                                      ['shape_square_blue', 2]]),
    'b.logb06.3': rule_sort('shape', 'circle', 'square', [['shape_circle_blue', 1], ['shape_square_green', 2], ['shape_circle_green', 1],
                                                          ['shape_square_yellow', 2]]),
    'b.logb06.5': rule_sort('colour', 'green', 'yellow', [['shape_square_green', 1], ['shape_triangle_yellow', 2], ['shape_triangle_green', 1],
                                                          ['shape_square_yellow', 2]]),
    'b.logb09.1': not_both('red', 'circle', [['shape_square_blue', 1], ['shape_circle_blue', 2, _N], ['shape_square_red', 2, _N],
                                              ['shape_triangle_green', 1]]),
    'b.logb09.4': not_both('red', 'square', [['shape_triangle_blue', 1], ['shape_square_blue', 2, _N], ['shape_triangle_red', 2, _N],
                                              ['shape_circle_green', 1]]),
    'b.logb09.5': not_both('blue', 'circle', [['shape_square_green', 1], ['shape_circle_green', 2, _N], ['shape_square_blue', 2, _N],
                                               ['shape_triangle_red', 1]]),
})


# ======== Colour Bay (Goni), Band B (docs/milestones/M11-stage2.md §3.3)
HUE = {'red': 'אָדֹם', 'blue': 'כָּחֹל', 'green': 'יָרֹק', 'purple': 'סָגֹל'}


def shades(col, decoy):
    """COL-B-02: three shades laid from the lightest to the darkest; the palette has a shade of another colour (it is not on the way)."""
    seq = ['shade_%s_%d' % (col, k) for k in (1, 2, 3)]
    return {'kind': 'build', 'sequence': seq, 'palette': [seq[2], decoy, seq[0], seq[1]], 'tag': 'M-SER-ENDS',
            'prompt': 'מְסַדְּרִים מֵהַבָּהִיר אֶל הַכֵּהֶה.', 'h3': '%s בָּהִיר, %s, %s כֵּהֶה. עַכְשָׁו תּוֹרְכֶם.' % (HUE[col], HUE[col], HUE[col]),
            'correct_text': 'כֵּן! מֵהַבָּהִיר אֶל הַכֵּהֶה.'}


def same_hue(a, b):
    """COL-B-03: light and dark shades of a colour go with it (a light or dark card put elsewhere is M-COL-SHADE)."""
    items = [['shade_%s_1' % a, 1, 'M-COL-SHADE'], ['shade_%s_3' % b, 2, 'M-COL-SHADE'], ['shade_%s_3' % a, 1, 'M-COL-SHADE'],
             ['shade_%s_1' % b, 2, 'M-COL-SHADE']]
    return {'kind': 'sort', 'rule': 'colour', 'tag': 'M-COL-SHADE',
            'bins': [{'sprite': 'shade_%s_2' % a, 'label': HUE[a]}, {'sprite': 'shade_%s_2' % b, 'label': HUE[b]}], 'items': items,
            'prompt': 'מְמַיְּנִים לְפִי צֶבַע: %s לְכָאן, וְ%s לְכָאן.' % (HUE[a], HUE[b]),
            'h3': 'גַּם בָּהִיר וְגַם כֵּהֶה, זֶה אוֹתוֹ צֶבַע. עַכְשָׁו תּוֹרְכֶם.', 'correct_text': 'כֵּן! בָּהִיר אוֹ כֵּהֶה, אוֹתוֹ צֶבַע.'}


RECUTS.update({
    'b.colb02.1': shades('blue', 'shade_green_2'), 'b.colb02.3': shades('green', 'shade_red_2'), 'b.colb02.5': shades('red', 'shade_purple_2'),
    'b.colb02.7': shades('purple', 'shade_blue_2'), 'b.colb02.9': shades('blue', 'shade_purple_1'),
    'b.colb03.1': same_hue('blue', 'red'), 'b.colb03.2': same_hue('blue', 'green'), 'b.colb03.3': same_hue('green', 'purple'),
    'b.colb03.5': same_hue('red', 'blue'),
})
