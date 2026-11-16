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

# The templates the app has a lead player for: the host does the first steps of the item (sort: its cards, shape builder: its places, trace: the sides
# of its path, counted as arc_checks.dart `traceSideCount` does).
LEAD_TEMPLATES = ('sort_drag', 'shape_builder', 'trace')
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


# The answer block of a Show of each template (a Show is never scored; the schema wants the template's own type).
SHOW_ANSWER = {'sort_drag': {'type': 'sort', 'mode': 'sort'}, 'shape_builder': {'type': 'shapes'}, 'trace': {'type': 'trace'}}


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
        for k in ('item', 'bin', 'piece', 'slot', 'segment'):
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
    return {
        'schema': 'activity/v1', 'id': show['id'], 'review': 'needs-editor', 'revision': 1, 'template': show['template'],
        'templateVersion': '1.0', 'domain': land, 'band': show.get('band') or band_of[skill],
        'skills': [{'id': skill, 'weight': 1}], 'purpose': 'show', 'checkType': 'practice',
        'representation': show['representation'], 'variantGroup': 'show', 'difficulty': {'authored': 0.05},
        'prompt': dict(spoken(open_line['vo'], open_line['text']), replayButton=True),
        'scene': show['scene'],
        'answer': SHOW_ANSWER[show['template']],
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
        template = read('activity.%s.json' % t['id'])['template']
        line = by_template[TEMPLATE_OF_LEAD_LINE[template]]
        # a template with no lead player has no steps for the host to do: the host only says its line (lead 0)
        lead = t['lead'] if template in LEAD_TEMPLATES else 0
        together.append({'id': t['id'], 'lead': lead, 'line': spoken(line['vo'], line['text'])})
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
    for show in arc['shows']:
        if show['template'] not in LEAD_TEMPLATES:
            waiting.append(show['id'])
            continue
        doc = show_doc(show, land, band_of)
        write('activity.%s.json' % show['id'], doc)
        show_ids.add(show['id'])
        refs = set(s['sprite'] for s in doc['scene'].get('bins', []) + doc['scene'].get('items', []) + doc['scene'].get('slots', []) if 'sprite' in s)
        refs |= set(doc['scene'].get('decoys', []))
        if doc['scene'].get('background'):
            refs.add(doc['scene']['background'])
        for ref in sorted(refs):
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
            continue
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
