"""Turns a unit spec (content/units/<unit>.json) into the pack files an author would otherwise write by hand.

    python tools/author.py content/units/counting-hills.json

The spec holds what only an author can decide (the skills, which objects and numbers, the Hebrew of a question); this
script holds what is the same for every activity of a kind (the file shape, the hint ladder, the voice ids, the
scoring, the tags on the wrong answers). Its output goes to content/starter, is checked by the real validator when the
pack is built, and is the same every time it runs. Every text it writes is `needs-editor` until a person approves it.
"""
import json
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
OUT = os.path.join(ROOT, 'content', 'starter')

# Counting words with niqqud. F: the abstract count and the numeral on a tile; M: with a masculine noun.
F = {0: 'אֶפֶס', 1: 'אַחַת', 2: 'שְׁתַּיִם', 3: 'שָׁלוֹשׁ', 4: 'אַרְבַּע', 5: 'חָמֵשׁ', 6: 'שֵׁשׁ', 7: 'שֶׁבַע',
     8: 'שְׁמוֹנֶה', 9: 'תֵּשַׁע', 10: 'עֶשֶׂר'}
M = {1: 'אֶחָד', 2: 'שְׁנַיִם', 3: 'שְׁלוֹשָׁה', 4: 'אַרְבָּעָה', 5: 'חֲמִשָּׁה', 6: 'שִׁשָּׁה', 7: 'שִׁבְעָה',
     8: 'שְׁמוֹנָה', 9: 'תִּשְׁעָה', 10: 'עֲשָׂרָה'}
ORD_M = ['רִאשׁוֹן', 'שֵׁנִי', 'שְׁלִישִׁי', 'רְבִיעִי']

# One shared line for each misconception, said whatever the activity (the voice is made once).
TAG_FEEDBACK = {
    'M-CNT-SEQ': ('vo:fb.seq', 'הַמְּמ… בּוֹאוּ נִסְפֹּר לְאַט, מִסְפָּר אַחֲרֵי מִסְפָּר.'),
    'M-CNT-DOUBLE': ('vo:fb.double_set', 'אוּלַי סָפַרְנוּ אֶחָד פַּעֲמַיִם? בּוֹאוּ נִבְדֹּק.'),
    'M-CNT-SKIP': ('vo:fb.skip_set', 'אוּלַי פִּסְפַּסְנוּ אֶחָד? בּוֹאוּ נִבְדֹּק.'),
    'M-CNT-CARD': ('vo:fb.card', None),  # already in the pack: read from the existing file
    'M-CNT-SIZE': ('vo:fb.size', 'יוֹתֵר לֹא תָּמִיד אוֹמֵר גָּדוֹל יוֹתֵר. בּוֹאוּ נַשְׁוֶה אֶחָד אֶחָד.'),
    'M-NUM-ZERO': ('vo:fb.zero', 'גַּם אֶפֶס הוּא מִסְפָּר: כְּשֶׁאֵין כְּלוּם, יֵשׁ אֶפֶס.'),
    'M-ORD-CARD': ('vo:fb.ord', 'הַמָּקוֹם בַּתּוֹר אֵינוֹ כַּמָּה יֵשׁ. בּוֹאוּ נִסְפֹּר מֵהַהַתְחָלָה.'),
}
ALMOST = ('vo:fb.almost', 'כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב.')
UNSURE = ('vo:fb.unsure', 'שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד.')

lines = {}  # voice id -> caption: one text for every id, checked below


def say(vo, text):
    assert vo not in lines or lines[vo] == text, 'the line %s has two texts: %r and %r' % (vo, lines[vo], text)
    lines[vo] = text
    return {'vo': vo, 'caption': [{'t': 'he', 'v': text}]}


def qty(n, obj):
    """'three apples' with the number agreeing in gender with the noun."""
    f = obj['g'] == 'f'
    if n == 0:
        return 'אֵין אַף ' + obj['one']
    if n == 1:
        return obj['one'] + ' ' + (F[1] if f else M[1])
    if n == 2:
        return ('שְׁתֵּי ' if f else 'שְׁנֵי ') + obj['many']
    return (F[n] if f else M[n]) + ' ' + obj['many']


def count_words(n):
    return ', '.join(F[i] for i in range(1, n + 1))


def tagged_feedback(tags):
    out = []
    for tag in sorted(tags):
        vo, text = TAG_FEEDBACK[tag]
        if text is None:
            text = existing_line(vo)
        out.append({'when': 'misconception:' + tag, **say(vo, text)})
    out.append({'when': 'default', **say(*ALMOST)})
    return out


_existing = {}


def existing_line(vo):
    if not _existing:
        for name in os.listdir(OUT):
            if name.startswith('activity.') and name.endswith('.json'):
                d = json.load(open(os.path.join(OUT, name), encoding='utf-8'))
                for r in d['feedback']['incorrect']:
                    _existing[r['vo']] = r['caption'][0]['v']
    return _existing[vo]


def hints(act_id, h1, h2, h3, actions=('replay_prompt_slow', 'show_fingers', 'worked_example'), shared=()):
    out = []
    for level, (text, action) in enumerate(zip((h1, h2, h3), actions), start=1):
        vo = 'vo:hint.%s.h%d' % (shared[level - 1], level) if level <= len(shared) and shared[level - 1] else (
            'vo:%s.h%d' % (act_id, level))
        out.append({'level': level, 'action': action, **say(vo, text)})
    return out


def activity(a, template, skills, purpose, check, rep, scene, answer, fb_tags, h, goal, extra=None, prompt=None,
             answer_prompt=None, correct=None):
    i = a['id']
    d = {
        'schema': 'activity/v1', 'id': i, 'review': 'needs-editor', 'revision': 1,
        'template': template, 'templateVersion': '1.1' if template == 'tap_answer' else '1.0',
        'domain': 'numbers', 'band': 'A',
        'skills': [{'id': s, 'weight': w} for s, w in skills],
        'purpose': purpose, 'checkType': check, 'representation': rep,
        'variantGroup': a.get('group', a['kind'].replace('_', '-')),
        'difficulty': {'authored': a.get('difficulty', 0.3)},
        'prompt': {**say('vo:%s.prompt' % i, prompt), 'replayButton': True},
        'scene': scene, 'answer': answer,
    }
    if answer_prompt:
        d['answerPrompt'] = say('vo:%s.how_many' % i, answer_prompt)
    d['feedback'] = {
        'correct': say('vo:%s.correct' % i, correct),
        'incorrect': tagged_feedback(fb_tags),
        'unsure': say(*UNSURE),
    }
    d['hints'] = h
    d['scoring'] = {'maxAttempts': 3, 'creditByHintLevel': [1, 0.8, 0.5, 0]}
    d['tutor'] = {'llmAllowed': True, 'goal': goal, 'mustNotRevealBeforeHint': 3}
    d['a11y'] = {'altText': prompt.replace('!', '.')}
    if extra:
        d.update(extra)
    return d


def options(values, correct_value, tagger, kind, label_of, extra_of=None):
    """Choice options in the given order, each with its misconception tag (if any)."""
    opts, cid, tags = [], None, set()
    for k, v in enumerate(values, start=1):
        o = {'id': 'o%d' % k}
        o.update(kind(v))
        o['label'] = label_of(v)
        tag = None if v == correct_value else tagger(v)
        if tag:
            o['misconception'] = tag
            tags.add(tag)
        if extra_of:
            o.update(extra_of(v))
        if v == correct_value:
            cid = o['id']
        opts.append(o)
    return opts, cid, tags


def choice(opts, cid):
    return {'type': 'choice', 'options': opts, 'correct': cid, 'shuffle': False, 'unsureAllowed': True}


def near_tag(ans):
    """A set one short of the right number is a miss, one over a double count."""
    return lambda v: 'M-CNT-SKIP' if v == ans - 1 else ('M-CNT-DOUBLE' if v == ans + 1 else None)


# ---------------------------------------------------------------- the kinds

def k_next_number(a, ctx):
    n, before = a['n'], a.get('dir') == 'before'
    ans = n - 1 if before else n + 1
    skip = ans - 1 if before else ans + 1
    opts, cid, tags = options(a['options'], ans, lambda v: 'M-CNT-SEQ' if v == skip else None,
                              lambda v: {'numeral': v}, lambda v: F[v])
    word = 'לִפְנֵי' if before else 'אַחֲרֵי'
    prompt = 'מָה בָּא %s %s?' % (word, F[n])
    lo, hi = (ans, n) if before else (1, n)
    return activity(
        a, 'tap_answer', [(a['skill'], 1)] + [(s, 0.5) for s in a.get('also', [])], 'learn', 'practice', 'symbolic',
        {}, choice(opts, cid), tags,
        hints(a['id'], 'בּוֹאוּ נִסְפֹּר יַחַד מֵהַהַתְחָלָה: %s.' % count_words(min(n, 5)),
              'נִסְפֹּר גַּם עִם הָאֶצְבָּעוֹת: %s.' % count_words(min(n, 5)),
              '%s, וְאַחֲרֵי %s בָּא %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (count_words(n), F[n], F[ans], F[ans])
              if not before else '%s. לִפְנֵי %s בָּא %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (
                  count_words(n), F[n], F[ans], F[ans])),
        'child says the number that comes %s %d' % ('before' if before else 'after', n),
        prompt=prompt, correct='%s! כָּךְ סוֹפְרִים.' % F[ans])


def k_flash(a, ctx):
    obj, n = ctx['objects'][a['obj']], a['count']
    opts, cid, tags = options(a['options'], n, lambda v: None, lambda v: {'numeral': v}, lambda v: F[v])
    for o in opts:
        o.pop('label')  # the flash template's tiles are numerals only
    group = {'sprite': 'asset:' + a['obj'], 'count': n, 'arrangement': a.get('arrangement', 'dice'),
             'seed': a.get('seed', 1)}
    return activity(
        a, 'flash', [(a['skill'], 1)], 'learn', 'practice', 'pictorial',
        {'group': group, 'flashMs': a.get('flashMs', 1500)}, choice(opts, cid), tags,
        hints(a['id'], 'בּוֹאוּ נִסְתַּכֵּל שׁוּב, לְאַט.', 'נַחֲזִיק אֶצְבָּעוֹת וְנִסְפֹּר: %s.' % count_words(n),
              'זֶה %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (qty(n, obj), F[n]),
              actions=('replay_prompt_slow', 'show_fingers', 'worked_example'), shared=('flash', None)),
        'child sees the number at a glance, without counting one by one',
        prompt='הִסְתַּכְּלוּ מַהֵר! כַּמָּה %s?' % obj['many'], correct='%s! רְאִיתֶם בְּלִי לִסְפֹּר.' % F[n])


def k_give(a, ctx):
    obj, n = ctx['objects'][a['obj']], a['n']
    return activity(
        a, 'give_n', [(a['skill'], 1)] + [(s, 0.5) for s in a.get('also', [])], 'check', 'reverse', 'concrete',
        {'background': 'asset:meadow', 'source': {'sprite': 'asset:' + a['obj'], 'count': a['source']},
         'target': {'sprite': 'asset:basket_target'}},
        {'type': 'give', 'n': n, 'classifiers': [{'when': 'took_all', 'misconception': 'M-CNT-CARD'}]},
        {'M-CNT-CARD'},
        hints(a['id'], 'תְּנוּ לִי %s. סוֹפְרִים תוֹךְ כְּדֵי שֶׁלּוֹקְחִים.' % qty(n, obj),
              'נִסְפֹּר עִם הָאֶצְבָּעוֹת: %s.' % count_words(n),
              '%s. עֲצְרוּ כְּשֶׁהִגַּעְנוּ אֶל %s. עַכְשָׁו תּוֹרְכֶם.' % (count_words(n), F[n])),
        'child gives exactly the number asked for, not the whole pile',
        extra={'contradicts': 'M-CNT-CARD'},
        prompt='תְּנוּ לִי %s.' % qty(n, obj), correct='%s! נָתַתֶּם בְּדִיּוּק כַּמָּה שֶׁבִּקַּשְׁתִּי.' % F[n])


def k_count_tap(a, ctx):
    obj, n = ctx['objects'][a['obj']], a['count']
    opts, cid, tags = options(a['options'], n, near_tag(n), lambda v: {'value': v}, lambda v: F[v])
    for o in opts:
        o.pop('label')
    return activity(
        a, 'count_tap', [(a['skill'], 1)] + [(s, 0.6) for s in a.get('also', [])], 'learn', 'practice', 'concrete',
        {'background': 'asset:meadow', 'objects': {'sprite': 'asset:' + a['obj'], 'litSprite': 'asset:%s_lit' % a['obj'],
                                                   'count': n, 'arrangement': a.get('arrangement', 'scatter'),
                                                   'onTap': 'glow', 'seed': a.get('seed', 11)},
         'target': {'sprite': 'asset:basket_target'}},
        choice(opts, cid), tags,
        hints(a['id'], 'נוֹגְעִים בְּ%s אֶחָד, וְאוֹמְרִים מִסְפָּר אֶחָד.' % obj['one'],
              'בּוֹאוּ נִסְפֹּר גַּם עִם הָאֶצְבָּעוֹת: %s…' % count_words(3),
              '%s. הַמִּסְפָּר הָאַחֲרוֹן אוֹמֵר כַּמָּה: %s! עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (
                  count_words(n), F[n], F[n]),
              shared=(None, 'ucount')),
        'child touches each one once and answers with the last number counted',
        extra={'traceClassifiers': [{'when': 'same_object_tapped_twice', 'misconception': 'M-CNT-DOUBLE'},
                                    {'when': 'object_never_tapped', 'misconception': 'M-CNT-SKIP'}]},
        prompt='נוֹגְעִים בְּכׇל אֶחָד פַּעַם אַחַת, וְסוֹפְרִים.', answer_prompt='כַּמָּה %s?' % obj['many'],
        correct='%s! סְפַרְתֶּם כׇּל אֶחָד פַּעַם אַחַת.' % F[n])


def k_set_to_numeral(a, ctx):
    obj, n = ctx['objects'][a['obj']], a['count']
    opts, cid, tags = options(a['options'], n, near_tag(n), lambda v: {'numeral': v}, lambda v: F[v])
    group = {'sprite': 'asset:' + a['obj'], 'count': n, 'arrangement': a.get('arrangement', 'scatter'),
             'seed': a.get('seed', 5)}
    scene = {'group': group}
    if a.get('background'):
        scene['background'] = 'asset:' + a['background']
    return activity(
        a, 'tap_answer', [(a['skill'], 1)] + [(s, 0.5) for s in a.get('also', [])], 'practice', 'practice', 'pictorial',
        scene, choice(opts, cid), tags,
        hints(a['id'], 'בּוֹאוּ נְנַסֶּה לִסְפֹּר לְאַט.', 'נִסְפֹּר עִם הָאֶצְבָּעוֹת: %s.' % count_words(max(n, 1)),
              '%s. יֵשׁ %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (count_words(max(n, 1)), qty(n, obj), F[n]),
              shared=('set', None)),
        'child picks the numeral that tells how many',
        prompt='כַּמָּה %s יֵשׁ? בּוֹחֲרִים אֶת הַמִּסְפָּר.' % obj['many'], correct='%s! זֶה הַמִּסְפָּר.' % F[n])


def k_numeral_to_set(a, ctx):
    obj, n = ctx['objects'][a['obj']], a['n']
    opts, cid, tags = options(
        a['options'], n, near_tag(n),
        lambda v: {'set': {'sprite': 'asset:' + a['obj'], 'count': v, 'arrangement': a.get('arrangement', 'line'),
                           'seed': v}},
        lambda v: qty(v, obj))
    return activity(
        a, 'tap_answer', [(a['skill'], 1)], 'practice', 'reverse', 'pictorial', {}, choice(opts, cid), tags,
        hints(a['id'], 'בּוֹאוּ נַקְשִׁיב שׁוּב לַמִּסְפָּר.', 'נִסְפֹּר עִם הָאֶצְבָּעוֹת: %s.' % count_words(n),
              '%s. זֶה %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה.' % (count_words(n), qty(n, obj))),
        'child finds the group that has the number named',
        prompt='אֵיפֹה יֵשׁ %s?' % qty(n, obj), correct='כֵּן! זֶה %s.' % qty(n, obj))


def k_pick_numeral(a, ctx):
    n = a['n']
    opts, cid, tags = options(a['options'], n, lambda v: None, lambda v: {'numeral': v}, lambda v: F[v])
    return activity(
        a, 'tap_answer', [(a['skill'], 1)], 'practice', 'practice', 'symbolic', {}, choice(opts, cid), tags,
        hints(a['id'], 'בּוֹאוּ נַקְשִׁיב שׁוּב: %s.' % F[n], 'נִסְפֹּר עִם הָאֶצְבָּעוֹת עַד %s: %s.' % (F[n], count_words(n)),
              '%s. הַמִּסְפָּר הָאַחֲרוֹן הוּא %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (count_words(n), F[n], F[n])),
        'child finds the numeral that is named',
        prompt='אֵיפֹה הַמִּסְפָּר %s?' % F[n], correct='%s! מָצָאתֶם אֶת הַמִּסְפָּר.' % F[n])


def k_compare_more(a, ctx):
    obj = ctx['objects'][a['obj']]
    more = a.get('ask', 'more') == 'more'
    big, small = a['big'], a['small']
    want = big if more else small
    # the wrong answer is the set that only looks like it has more: wider, bigger things
    opts, cid, tags = [], None, set()
    for k, v in enumerate(a['options'], start=1):
        o = {'id': 'o%d' % k,
             'set': {'sprite': 'asset:' + a['obj'], 'count': v, 'arrangement': a.get('arr', {}).get(str(v), a.get('arrangement', 'line')),
                     'seed': v + k, 'scale': a.get('scale', {}).get(str(v), 1)}, 'label': qty(v, obj)}
        if v == want:
            cid = o['id']
        elif a.get('trap', True):
            o['misconception'] = 'M-CNT-SIZE'
            tags.add('M-CNT-SIZE')
        opts.append(o)
    word = 'יוֹתֵר' if more else 'פָּחוֹת'
    return activity(
        a, 'tap_answer', [(a['skill'], 1)] + [(s, 0.5) for s in a.get('also', [])], 'practice', 'practice',
        a.get('rep', 'pictorial'), {}, choice(opts, cid), tags,
        hints(a['id'], 'בּוֹאוּ נִסְתַּכֵּל שׁוּב עַל שְׁנֵי הַצְּדָדִים.',
              'נַשְׁוֶה אֶחָד אֶחָד: לְכׇל אֶחָד מִצַּד זֶה, אֶחָד מִצַּד זֶה.',
              'בְּצַד אֶחָד יֵשׁ %s, וּבַצַּד הָאַחֵר %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל הַנְּכוֹנָה.' % (
                  qty(want, obj), qty(small if more else big, obj)),
              actions=('replay_prompt_slow', 'highlight_objects_sequentially', 'worked_example')),
        'child compares by number, not by how big or spread out the things look',
        prompt='אֵיפֹה יֵשׁ %s %s?' % (word, obj['many']), correct='כֵּן! כָּאן יֵשׁ %s %s.' % (word, obj['many']))


def k_compare_same(a, ctx):
    obj = ctx['objects'][a['obj']]
    l, r = a['left'], a['right']
    same = l == r
    opts = [{'id': 'o1', 'sprite': 'asset:tick', 'label': 'כֵּן'}, {'id': 'o2', 'sprite': 'asset:cross', 'label': 'לֹא'}]
    cid = 'o1' if same else 'o2'
    opts[1 if same else 0]['misconception'] = 'M-CNT-SIZE'
    scene = {'group': {'sprite': 'asset:' + a['obj'], 'count': l, 'arrangement': a.get('arrangement', 'scatter'),
                       'seed': 3},
             'group2': {'sprite': 'asset:' + a['obj'], 'count': r, 'arrangement': a.get('arrangement2', 'line'),
                        'seed': 8, 'scale': a.get('scale2', 1)}}
    return activity(
        a, 'tap_answer', [(a['skill'], 1)], 'practice', 'practice', 'pictorial', scene, choice(opts, cid),
        {'M-CNT-SIZE'},
        hints(a['id'], 'בּוֹאוּ נִסְתַּכֵּל שׁוּב עַל שְׁנֵי הַצְּדָדִים.',
              'נַשְׁוֶה אֶחָד אֶחָד: לְכׇל אֶחָד מִצַּד זֶה, אֶחָד מִצַּד זֶה.',
              ('בִּשְׁנֵי הַצְּדָדִים יֵשׁ אוֹתוֹ מִסְפָּר: %s.' % F[l]) if same else
              ('בְּצַד אֶחָד יֵשׁ %s, וּבַצַּד הָאַחֵר %s. זֶה לֹא אוֹתוֹ דָּבָר.' % (qty(l, obj), qty(r, obj))),
              actions=('replay_prompt_slow', 'highlight_objects_sequentially', 'worked_example')),
        'child decides whether two groups have the same number, whatever their look',
        prompt='הַאִם יֵשׁ אוֹתוֹ מִסְפָּר בִּשְׁנֵי הַצְּדָדִים?', correct='כֵּן, צָדַקְתֶּם!')


def k_ordinal(a, ctx):
    order = a['line']  # sprite ids, first in the line first
    k = a['pick']  # 0-based position, or -1 for the last
    pos = len(order) - 1 if k == -1 else k
    opts = []
    for i, s in enumerate(order, start=1):
        o = {'id': 'o%d' % i, 'sprite': 'asset:' + s, 'label': ctx['objects'][s]['one']}
        if i - 1 == len(order) - 1 and pos != len(order) - 1:
            o['misconception'] = 'M-ORD-CARD'
        elif pos == len(order) - 1 and i == 1:
            o['misconception'] = 'M-ORD-CARD'
        opts.append(o)
    cid = 'o%d' % (pos + 1)
    for o in opts:
        if o['id'] == cid:
            o.pop('misconception', None)
    tags = {'M-ORD-CARD'} & {o.get('misconception') for o in opts}
    word = 'הָאַחֲרוֹן' if k == -1 else ORD_M[pos]
    return activity(
        a, 'tap_answer', [(a['skill'], 1)], 'learn', 'practice', 'concrete', {}, choice(opts, cid), tags,
        hints(a['id'], 'בּוֹאוּ נַקְשִׁיב שׁוּב לַשְּׁאֵלָה.', 'נִסְפֹּר בַּתּוֹר מֵהַהַתְחָלָה: %s.' % ', '.join(
            ORD_M[:pos + 1] if k != -1 else ORD_M[:len(order)]),
              'הַמָּקוֹם %s בַּתּוֹר הוּא %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו.' % (
                  word if k != -1 else 'הָאַחֲרוֹן', ctx['objects'][order[pos]]['one']),
              actions=('replay_prompt_slow', 'highlight_objects_sequentially', 'worked_example')),
        'child finds the place in the line, not how many there are',
        prompt='מִי %s בַּתּוֹר?' % word if k == -1 else 'מִי %s בַּתּוֹר?' % word,
        correct='כֵּן! זֶה ה%s בַּתּוֹר.' % ('אַחֲרוֹן' if k == -1 else ORD_M[pos]))


def k_zero(a, ctx):
    obj, n = ctx['objects'][a['obj']], a['count']
    tagger = (lambda v: 'M-NUM-ZERO' if v == 1 and n == 0 else None)
    opts, cid, tags = options(a['options'], n, tagger, lambda v: {'numeral': v}, lambda v: F[v])
    group = {'sprite': 'asset:' + a['obj'], 'count': n, 'arrangement': 'line', 'seed': 2}
    return activity(
        a, 'tap_answer', [(a['skill'], 1)], 'learn', 'practice', 'story',
        {'background': 'asset:' + a['place'], 'group': group}, choice(opts, cid), tags,
        hints(a['id'], 'בּוֹאוּ נִסְתַּכֵּל שׁוּב.',
              'נִסְפֹּר עִם הָאֶצְבָּעוֹת: %s' % ('אֵין כְּלוּם לִסְפֹּר.' if n == 0 else count_words(n) + '.'),
              ('אֵין אַף %s. כְּשֶׁאֵין כְּלוּם, הַמִּסְפָּר הוּא %s. עַכְשָׁו תּוֹרְכֶם.' % (obj['one'], F[0])) if n == 0
              else ('%s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (count_words(n), F[n]))),
        'child knows that nothing there is the number zero',
        prompt='כַּמָּה %s %s?' % (obj['many'], a['where']),
        correct=('%s! אֵין אַף %s.' % (F[0], obj['one'])) if n == 0 else '%s! נָכוֹן.' % F[n])


KINDS = {k[2:]: v for k, v in globals().items() if k.startswith('k_')}


# ---------------------------------------------------------------- skills, tags, lessons

def skill_file(s):
    cap = lambda t: [{'t': 'he', 'v': t}]
    d = {
        'schema': 'skill/v1', 'id': s['id'], 'review': 'needs-editor', 'domain': 'numbers', 'band': 'A',
        'title': cap(s['title']), 'worldObject': s['world'], 'childLine': cap(s['child']),
        'prerequisites': [{'skill': p, 'weight': 1} for p in s['needs']],
        'representations': s['reps'], 'misconceptions': s['tags'],
        'retention': {'targetRetention': 0.9, 'initialStabilityDays': 1},
    }
    if s.get('core'):
        d['core'] = True
    return d


def tag_file(t):
    cap = lambda x: [{'t': 'he', 'v': x}]
    return {
        'schema': 'misconception/v1', 'id': t['id'], 'review': 'needs-editor', 'skills': t['skills'],
        'parentText': t['parent'], 'homeActivity': cap(t['home']), 'repairActivities': t.get('repair', []),
        'preferredRepresentations': t['reps'],
    }


def lesson_file(l, sequence):
    return {
        'schema': 'lesson/v1', 'id': l['id'], 'review': 'needs-editor', 'revision': 1, 'band': 'A',
        'title': [{'t': 'he', 'v': l['title']}], 'skills': l['skills'], 'items': l['items'],
        'estimatedMinutes': l.get('minutes', 4), 'sequence': sequence, 'celebration': say('vo:celebrate.%s' % l['id'].replace('-', '_'), l['done']),
    }


def write(name, doc):
    with open(os.path.join(OUT, name), 'w', encoding='utf-8', newline='\n') as fh:
        json.dump(doc, fh, ensure_ascii=False, indent=2)
        fh.write('\n')


def main(path):
    spec = json.load(open(path, encoding='utf-8'))
    ctx = {'objects': spec['objects']}
    made = {'skill': 0, 'misconception': 0, 'activity': 0, 'lesson': 0}
    for t in spec.get('misconceptions', []):
        write('misconception.%s.json' % t['id'], tag_file(t))
        made['misconception'] += 1
    for s in spec['skills']:
        write('skill.%s.json' % s['id'], skill_file(s))
        made['skill'] += 1
    ids = set()
    for a in spec['activities']:
        assert a['id'] not in ids, 'duplicate activity id ' + a['id']
        ids.add(a['id'])
        write('activity.%s.json' % a['id'], KINDS[a['kind']](a, ctx))
        made['activity'] += 1
    # The path of the land: the lessons in the order of the spec, after the older lessons the spec names in "after".
    for number, l in enumerate(spec['lessons'], start=spec.get('firstSequence', 2)):
        for item in l['items']:
            assert item in ids or os.path.exists(os.path.join(OUT, 'activity.%s.json' % item)), 'no activity ' + item
        write('lesson.%s.json' % l['id'], lesson_file(l, number))
        made['lesson'] += 1
    # the pack's asset list gains the sprites this unit uses
    pack_path = os.path.join(OUT, 'pack.json')
    pack = json.load(open(pack_path, encoding='utf-8'))
    have = {x['id'] for x in pack['assets']}
    for aid in spec['assets']:
        if aid not in have:
            pack['assets'].append({'id': aid, 'file': aid + '.svg'})
    json.dump(pack, open(pack_path, 'w', encoding='utf-8', newline='\n'), ensure_ascii=False, indent=2)
    open(pack_path, 'a', encoding='utf-8', newline='\n').write('\n')
    print('wrote', made, 'and', len(lines), 'voice lines')


main(sys.argv[1])
