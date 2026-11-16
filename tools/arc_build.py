"""Turns the lesson arc sources of the lands (content/units/arc/<land>.arc.json, schema lesson-arc-source/v0) into pack files
(M11 Stage 2, docs/milestones/M11-stage2.md sections 2 and 7.4):

    python tools/arc_build.py                 # every arc file
    python tools/arc_build.py content/units/arc/shape-forest.arc.json

It runs after tools/author.py (tools/regen_content.py does it), because the lessons it adds parts to are written by author.py:

1. one Show activity per skill, content/starter/activity.<show id>.json (`purpose: show`, the skill's hands-on template, the host's lines and
   steps in `show`), unscored; the sprites a Show uses join the pack's asset list when their svg is in content/starter;
2. `parts` on each lesson of the arc (show, secondShow, recall, together with its lead and the host's lead-in, alone, use, handover), and
   `items` as the flat list of the lesson's own items for a reader that does not know the parts (together, alone, use; never a Show);
3. the host's lines are in those files as `vo` with a caption, so the voicing plan (voice_gen plan, tools/voicing_inventory.py) counts them as
   pending clips; nothing is voiced here and nothing is paid.

The output is a pure function of the arc file and the files author.py wrote: the same sources give the same bytes. A Show whose template the
app cannot play yet (a drag in listen_do, step 2.2c) makes its lessons stay flat lists: they get no `parts` and are named in
`arc_checks.dart` (`arcLessonsWaiting`).

The rules V1 to V3 of the spec are checked here as the files are made (the build stops on a broken arc); V4 to V7 and W1 run in the app's
validator over the whole pack (app/lib/content/arc_checks.dart), which the pack builder and the installer both run.
"""
import glob
import json
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
OUT = os.path.join(ROOT, 'content', 'starter')
ARC_DIR = os.path.join(ROOT, 'content', 'units', 'arc')

# The templates the app has a Show player for (and, but for the clock, a lead player): the host does the first steps of the item (sort: its cards or the
# deal of a share, shape builder: its places, trace: the sides of its path as arc_checks.dart `traceSideCount` counts them, number line: its hops, give
# N: the objects, count and tap: the touches, pattern: the places to fill, balance: the blocks, shop: the coins, robot: the arrows).
LEAD_TEMPLATES = ('sort_drag', 'shape_builder', 'trace', 'number_line', 'give_n', 'count_tap', 'build_pattern', 'balance', 'shop_pay',
                  'robot_path', 'clock_set')
# The move words of a step of a Show (app/lib/content/schemas.dart `_showStep`): what the host's, or the child's, step does on each template.
STEP_WORDS = ('item', 'bin', 'piece', 'slot', 'segment', 'hop', 'point', 'place', 'move', 'touch', 'cell', 'block', 'put', 'pan', 'coin', 'arrow',
              'hand', 'to')
# A Show of the robot skill that is direct control (an arrow moves the robot at once); any other is a plan (cards, then go). A `mode` in the arc's
# Show wins over this table.
ROBOT_DIRECT_SKILLS = ('CS-A-03',)
# The Show's check of a touch on a line placed between its ticks (an estimate): within a third of a tick step.
SHOW_PLACE_TOLERANCE_DIV = 3
# The templateVersion a Show is written in where the template has features the Show uses (app/lib/content/schemas.dart `templateVersions`: a test
# holds the two tables equal); every other template's Show is 1.0.
TEMPLATE_VERSION = {'give_n': '1.2', 'build_pattern': '1.2', 'number_line': '1.2', 'shop_pay': '1.1', 'count_tap': '1.1', 'sort_drag': '1.0'}
# The first Together lead of a template that the arc source gives none (lead 0 was all the app could play before these players): one step.
DEFAULT_LEAD = 1
# The shared lines of the activity that every Show and its feedback use (author.py: ALMOST and UNSURE, one text for one id).
ALMOST = ('vo:fb.almost', 'בּוֹאוּ נְנַסֶּה שׁוּב.')
UNSURE = ('vo:fb.unsure', 'שְׁאֵלָה טוֹבָה! בּוֹאוּ נִרְאֶה יַחַד.')
TEMPLATE_OF_LEAD_LINE = {'sort_drag': 'sort_drag', 'shape_builder': 'shape_builder', 'tap_answer': 'tap_answer',
                         'trace': 'trace', 'listen_do': 'listen_do',
                         # M11 Stage 2, the other lands: a Together item of a template with no lead player yet (lead 0) has its host's line of
                         # that template; a pick that is not a tap says the tap's line (the strategy, then the hint-1 picture)
                         'number_line': 'number_line', 'give_n': 'give_n', 'count_tap': 'count_tap', 'build_pattern': 'build_pattern',
                         'balance': 'balance', 'shop_pay': 'shop_pay', 'robot_path': 'robot_path', 'clock_set': 'clock_set',
                         'flash': 'tap_answer', 'spot_error': 'tap_answer', 'match_pairs': 'tap_answer'}


class ShowWaits(Exception):
    """A Show the arc source has not given everything the player needs for (its lessons stay flat lists until it does)."""


def child_step(show):
    return show['steps'][-1]


def pattern_rows(show):
    """The whole row of a pattern Show (the answer's `sequence`): the given cells, then what each step lays, the host's and the child's. A cell
    the row never fills is a broken Show."""
    slots = show['scene']['slots']
    row = [None] * slots
    for g in show['scene'].get('given', []):
        row[g['cell']] = g['face']
    for st in show['steps']:
        row[st['cell']] = st['piece']
    if not all(row):
        raise ShowWaits('%s: a place of the row is neither given nor laid by a step (the arc gives no `scene.given` for the cells the host does not lay)' % show['id'])
    return row


def show_answer(show):
    """The answer block of a Show (a Show is never scored; the schema wants the template's own type, and the session reads the right end of the
    example from it: the landing of a line, the count to give, the row, the blocks to add)."""
    t, steps, scene = show['template'], show['steps'], show['scene']
    if t == 'sort_drag':
        return {'type': 'sort', 'mode': 'sort'}
    if t == 'shape_builder':
        return {'type': 'shapes'}
    if t == 'trace':
        return {'type': 'trace'}
    if t == 'number_line':
        last = child_step(show)
        if 'place' in last:
            target = last['place']
            answer = {'type': 'line', 'mode': 'place', 'target': target}
            step = scene.get('tickStep', 1)
            if step > 1 and (target - scene['from']) % step:
                answer['tolerance'] = max(1, step // SHOW_PLACE_TOLERANCE_DIV)
            return answer
        landing = scene['start'] + sum(s['hop'] for s in steps)
        return {'type': 'line', 'mode': 'jump', 'target': landing}
    if t == 'count_tap':
        n = scene['objects']['count']
        # (the wrong option names a tag only because the schema asks every choice to: a Show is never scored)
        return {'type': 'choice', 'options': [{'id': 'o1', 'value': n}, {'id': 'o2', 'value': n + 1, 'misconception': 'M-CNT-SKIP'}], 'correct': 'o1', 'shuffle': False,
                'unsureAllowed': True}
    if t == 'give_n':
        return {'type': 'give', 'n': sum(s['move'] for s in steps), 'classifiers': []}
    if t == 'build_pattern':
        return {'type': 'build', 'sequence': pattern_rows(show)}
    if t == 'balance':
        if all('pan' in s for s in steps):
            weights = [sum(g['count'] * g.get('weight', 1) for g in scene[side]['groups']) for side in ('left', 'right')]
            return {'type': 'scale', 'mode': 'compare', 'result': 'same' if weights[0] == weights[1] else ('left' if weights[0] > weights[1] else 'right')}
        return {'type': 'scale', 'mode': 'balance', 'result': str(sum(s['block'] for s in steps))}
    if t == 'shop_pay':
        return {'type': 'pay'}
    if t == 'robot_path':
        mode = show.get('mode') or ('direct' if show['skill'] in ROBOT_DIRECT_SKILLS else 'plan')
        arrows = [s['arrow'] for s in steps]
        return {'type': 'path', 'mode': mode, 'maxSteps': max(len(arrows), 4), 'solution': arrows}
    if t == 'clock_set':
        return {'type': 'clock'}
    raise AssertionError('%s: no Show answer for the template %s' % (show['id'], t))


def is_pointed(text):
    """Whether every Hebrew word of [text] carries a niqqud mark (U+05B0 to U+05BC), as the pack's captions must in Bands A and B."""
    words = [w for w in text.split() if any('א' <= c <= 'ת' for c in w)]
    return bool(words) and all(any('ְ' <= c <= 'ּ' for c in w) for w in words)


def show_predict(show, open_vo):
    """The host's question before the example, as the pack has it: its line (a clip of its own, pending) and the answers the child may touch. A
    question the arc gives with fewer than two answers is only asked."""
    p = show.get('predict')
    if not p:
        return None
    out = {'choices': [{'id': 'o%d' % (i + 1), 'label': c} for i, c in enumerate(p.get('choices', []))]}
    # A line the child reads in Band A or B is fully pointed, and nikud is never made by a model or a tool: the question the arc gives plain
    # (a draft for the hebrew-text-editor) is not written as a line of its own, and the Show's opening line, which is pointed, is the question.
    if is_pointed(p['line']):
        out['line'] = spoken(open_vo.rsplit('.', 1)[0] + '.predict', p['line'])
    else:
        print('  note: %s: the predict question "%s" is not pointed yet; the opening line asks (the editor points it, then it is a line of its own)' % (show['id'], p['line']))
    return out


def asset_refs(value):
    """Every `asset:` picture a piece of a scene names, at any depth."""
    if isinstance(value, str):
        return {value} if value.startswith('asset:') else set()
    if isinstance(value, list):
        return set().union(*[asset_refs(v) for v in value]) if value else set()
    if isinstance(value, dict):
        return set().union(*[asset_refs(v) for v in value.values()]) if value else set()
    return set()


def read(name):
    with open(os.path.join(OUT, name), encoding='utf-8') as fh:
        return json.load(fh)


def write(name, doc):
    with open(os.path.join(OUT, name), 'w', encoding='utf-8', newline='\n') as fh:
        json.dump(doc, fh, ensure_ascii=False, indent=2)
        fh.write('\n')


def spoken(vo, text):
    return {'vo': vo, 'caption': [{'t': 'he', 'v': text}]}


def show_doc(show, land, band_of):
    """The Show as an activity document. The prompt is the host's opening line, the praise is its key line said again (the child has just seen
    what it says), and a wrong touch is the shared "let's try again": nothing is written for any of them (the Show is unscored)."""
    lines = {l['role']: l for l in show['lines']}
    for role in ('open', 'key', 'handover'):
        assert role in lines, '%s has no %s line' % (show['id'], role)
    assert len(show['lines']) <= 3, '%s has more than three host lines (V2)' % show['id']
    assert show['handOver'] == 'last', show['id']
    steps = []
    for st in show['steps']:
        out = {'by': st['by']}
        for k in STEP_WORDS:
            if k in st:
                out[k] = st[k]
        if st.get('say') == 'key':
            out['say'] = 'key'
        # the motion of the host's hand: the arc names it by its own key (trace, count, sticks, walk, push, stack, turn, stamp)
        for motion in ('trace', 'count', 'sticks', 'walk', 'push', 'stack', 'turn', 'stamp'):
            if motion in st:
                out['motion'] = motion
                if isinstance(st[motion], str):
                    out['detail'] = st[motion]
                break
        steps.append(out)
    assert [s['by'] for s in steps].count('child') == 1 and steps[-1]['by'] == 'child', '%s: the child makes the last step only (V2)' % show['id']
    skill = show['skill']
    open_line, key_line = lines['open'], lines['key']
    show = dict(show, steps=steps)
    doc = {
        'schema': 'activity/v1', 'id': show['id'], 'review': 'needs-editor', 'revision': 1, 'template': show['template'],
        'templateVersion': TEMPLATE_VERSION.get(show['template'], '1.0'), 'domain': land, 'band': show.get('band') or band_of[skill],
        'skills': [{'id': skill, 'weight': 1}], 'purpose': 'show', 'checkType': 'practice',
        'representation': show['representation'], 'variantGroup': 'show', 'difficulty': {'authored': 0.05},
        'prompt': dict(spoken(open_line['vo'], open_line['text']), replayButton=True),
        'scene': show['scene'],
        'answer': show_answer(show),
        'voiceAnswer': False,
        'feedback': {
            'correct': spoken(key_line['vo'], key_line['text']),
            'incorrect': [dict(when='default', **spoken(*ALMOST))],
            'unsure': spoken(*UNSURE),
        },
        'hints': [],
        'scoring': {'maxAttempts': 3, 'creditByHintLevel': [1, 0.8, 0.5, 0]},
        'tutor': {'llmAllowed': False, 'goal': 'the host does a worked example and the child makes only the last step',
                  'mustNotRevealBeforeHint': 0},
        'a11y': {'altText': open_line['text']},
        'show': {
            'handOver': 'last',
            'lines': [dict(role=l['role'], **spoken(l['vo'], l['text'])) for l in show['lines']],
            'steps': steps,
            'teaches': list(show['teaches']),
        },
    }
    predict = show_predict(show, open_line['vo'])
    if predict:
        doc['show']['predict'] = predict
    if show['template'] == 'count_tap':
        # the touch of the last object ends a Show: "how many?" is asked only in an item, and the key line is the praise
        doc['answerPrompt'] = spoken(key_line['vo'], key_line['text'])
        doc['traceClassifiers'] = []
    return doc


def fewest_coin_way(price, kinds):
    """The kinds of a way to pay [price] (agorot) from a purse of [kinds] with the fewest coins; the app's `fewestCoinWay` (content/pay_way.dart)."""
    values = {'a10': 10, 'h50': 50, 's1': 100, 's2': 200, 's5': 500, 's10': 1000, 'n20': 2000, 'n50': 5000, 'n100': 10000, 'n200': 20000}
    best = {0: []}
    for i, kind in enumerate(kinds):
        for total, way in list(best.items()):
            s = total + values[kind]
            if s <= price and (s not in best or len(best[s]) > len(way) + 1):
                best[s] = way + [i]
    return [kinds[i] for i in best.get(price, [])]


def leadable_steps(a):
    """How many steps the host may lead in an item (arc_checks.dart `leadableSteps`): the cards of a sort or its deal, the places of a shape builder,
    the hops of a jump, the objects to give or touch, the places of a pattern the child fills, the blocks of a weighing, the coins of the fewest-coin
    payment, the arrows of the way. None where the host has nothing to lead (a place on a line, a comparison, a clock, a tap)."""
    t, sc, an = a['template'], a['scene'], a['answer']
    if t == 'sort_drag':
        return len(sc['items'])
    if t == 'shape_builder':
        return len(sc['slots'])
    if t == 'number_line':
        return len(sc.get('hops', [])) if an['mode'] == 'jump' else None
    if t == 'give_n':
        return an['n']
    if t == 'count_tap':
        return sc['objects']['count']
    if t == 'build_pattern':
        given = {g['cell']: g['face'] for g in sc.get('given', [])}
        return sum(1 for i, face in enumerate(an.get('sequence', [])) if given.get(i) != face)
    if t == 'balance':
        return int(an['result']) if an['mode'] == 'balance' else None
    if t == 'shop_pay':
        return len(fewest_coin_way(sc['price'], [p['kind'] for p in sc['purse'] for _ in range(p['count'])]))
    if t == 'robot_path':
        return len(an['solution'])
    return None


def lead_of(authored, activity):
    """The lead of a Together item: what the arc gives, else one step where the host has two or more to lead (a first lead of one is the spec's)."""
    if activity['template'] == 'trace':
        return authored
    steps = leadable_steps(activity)
    if steps is None or steps < 2 or activity['template'] not in LEAD_TEMPLATES:
        return 0
    return min(authored or DEFAULT_LEAD, steps - 1)


def lesson_parts(lesson, show_ids, host_lines, number):
    """The parts of one lesson, or None when its Show cannot be played yet."""
    by_template = {l['template']: l for l in host_lines if l['role'] == 'together_lead'}
    handovers = [l for l in host_lines if l['role'] == 'handover']
    first = lesson['show']
    if first not in show_ids:
        return None
    parts = {'show': first}
    second = lesson.get('secondShow')
    if second:
        assert second['id'] in show_ids, 'the second Show of %s is not built' % lesson['id']
        skill = read('activity.%s.json' % second['id'])['skills'][0]['id']
        before = next((i for i in lesson['alone'] if read('activity.%s.json' % i)['skills'][0]['id'] == skill), None)
        if before:
            parts['secondShow'] = {'id': second['id'], 'before': before}
    if lesson.get('recall'):
        parts['recall'] = list(lesson['recall'])
    together = []
    for t in lesson['together']:
        activity = read('activity.%s.json' % t['id'])
        template = activity['template']
        line = by_template.get(TEMPLATE_OF_LEAD_LINE[template])
        if line is None:
            # the arc source has no lead-in of this template for its host: the tap's (the strategy line) stands in, and the build says so
            line = by_template['tap_answer']
            print('  note: %s has no host lead-in for %s; %s uses the tap lead-in' % (lesson['id'], template, t['id']))
        together.append({'id': t['id'], 'lead': lead_of(t['lead'], activity), 'line': spoken(line['vo'], line['text'])})
    if together:
        parts['together'] = together
    # QA-2: the planner serves nothing from an empty Alone pool, so such a lesson would be played flat with no Show. The build refuses it, as the
    # app's validator does (arc_checks.dart, V1).
    assert lesson['alone'], 'the lesson %s has an empty Alone pool: a lesson in parts needs at least one Alone item (QA-2)' % lesson['id']
    parts['alone'] = list(lesson['alone'])
    if lesson.get('use'):
        parts['use'] = list(lesson['use'])
    if handovers:
        h = handovers[number % len(handovers)]
        parts['handover'] = spoken(h['vo'], h['text'])
    return parts


def build(path):
    arc = json.load(open(path, encoding='utf-8'))
    assert arc['schema'] == 'lesson-arc-source/v0', path
    land = arc['land']
    band_of = {}
    for name in sorted(os.listdir(OUT)):
        if name.startswith('skill.') and name.endswith('.json'):
            d = read(name)
            band_of[d['id']] = d['band']
    pack_path = os.path.join(OUT, 'pack.json')
    pack = json.load(open(pack_path, encoding='utf-8'))
    have = {x['id'] for x in pack['assets']}
    show_ids, waiting, missing = set(), [], set()
    waits = {}  # the Show that is not built, to what it waits for (a lesson of it says so itself: `partsWait`)
    for show in arc['shows']:
        if show['template'] not in LEAD_TEMPLATES:
            waiting.append(show['id'])
            waits[show['id']] = (show.get('status') or 'a template the app cannot play yet')
            continue
        try:
            doc = show_doc(show, land, band_of)
        except ShowWaits as e:
            print('  waits: %s' % e)
            waiting.append(show['id'])
            waits[show['id']] = str(e)
            continue
        write('activity.%s.json' % show['id'], doc)
        show_ids.add(show['id'])
        for ref in sorted(asset_refs(doc['scene']) | asset_refs(doc['show']['steps'])):
            aid = ref[len('asset:'):]
            if aid in have:
                continue
            if os.path.exists(os.path.join(OUT, aid + '.svg')):
                pack['assets'].append({'id': aid, 'file': aid + '.svg'})
                have.add(aid)
            else:
                missing.add(aid)
    assert not missing, 'sprites of a Show that have no svg in content/starter yet: %s' % ', '.join(sorted(missing))
    made = 0
    for number, lesson in enumerate(arc['lessons']):
        name = 'lesson.%s.json' % lesson['id']
        doc = read(name)
        parts = lesson_parts(lesson, show_ids, arc['hostLines'], number)
        if parts is None:
            doc.pop('parts', None)
            doc['partsWait'] = ('%s waits: %s' % (lesson['show'], waits.get(lesson['show'], 'it is not built')))[:200]
            write(name, doc)
            continue
        doc.pop('partsWait', None)
        doc['parts'] = parts
        items = []
        for i in [t['id'] for t in parts.get('together', [])] + parts['alone'] + parts.get('use', []):
            if i not in items:
                items.append(i)
        assert items, lesson['id']
        # the flat list is the lesson's own items (it never holds a Show or an item of another skill's recall)
        doc['items'] = items
        # keep the parts after the fields author.py wrote, in the order of the spec
        write(name, doc)
        made += 1
    json.dump(pack, open(pack_path, 'w', encoding='utf-8', newline='\n'), ensure_ascii=False, indent=2)
    open(pack_path, 'a', encoding='utf-8', newline='\n').write('\n')
    print('arc %s: %d Shows, %d lessons in parts, %d Shows waiting (%s)' % (land, len(show_ids), made, len(waiting), ', '.join(waiting)))


def main(paths):
    for path in paths or sorted(glob.glob(os.path.join(ARC_DIR, '*.arc.json'))):
        build(path)


if __name__ == '__main__':
    main(sys.argv[1:])
