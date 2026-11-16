"""Tests of tools/arc_build.py: the Shows and the lesson parts it writes from content/units/arc/*.arc.json (M11 Stage 2). By ids and structure;
no Hebrew text is pinned (the editor owns it).

    python tools/test_arc_build.py
"""
import glob
import json
import os
import unittest

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
STARTER = os.path.join(ROOT, 'content', 'starter')


def load(name):
    with open(os.path.join(STARTER, name), encoding='utf-8') as fh:
        return json.load(fh)


def arcs():
    for path in sorted(glob.glob(os.path.join(ROOT, 'content', 'units', 'arc', '*.arc.json'))):
        with open(path, encoding='utf-8') as fh:
            yield json.load(fh)


class ArcBuildTest(unittest.TestCase):
    def test_every_buildable_show_is_a_unscored_activity(self):
        built = 0
        for arc in arcs():
            for show in arc['shows']:
                if show['template'] not in ('sort_drag', 'shape_builder', 'trace'):
                    self.assertFalse(os.path.exists(os.path.join(STARTER, 'activity.%s.json' % show['id'])), show['id'])
                    continue
                d = load('activity.%s.json' % show['id'])
                built += 1
                self.assertEqual(d['purpose'], 'show')
                self.assertEqual(d['hints'], [])
                self.assertEqual(d['show']['handOver'], 'last')
                steps = d['show']['steps']
                self.assertEqual([s['by'] for s in steps].count('child'), 1)
                self.assertEqual(steps[-1]['by'], 'child')
                self.assertLessEqual(len(d['show']['lines']), 3)
                self.assertEqual({l['role'] for l in d['show']['lines']}, {'open', 'key', 'handover'})
                # the opening line is the prompt, the key line is said again as the praise
                self.assertEqual(d['prompt']['vo'], next(l['vo'] for l in d['show']['lines'] if l['role'] == 'open'))
                self.assertEqual(d['feedback']['correct']['vo'], next(l['vo'] for l in d['show']['lines'] if l['role'] == 'key'))
        self.assertGreaterEqual(built, 16)

    def test_every_lesson_in_parts_flattens_to_its_own_items_and_never_holds_a_show(self):
        n = 0
        for arc in arcs():
            for lesson in arc['lessons']:
                d = load('lesson.%s.json' % lesson['id'])
                parts = d.get('parts')
                if parts is None:
                    continue
                n += 1
                own = [t['id'] for t in parts.get('together', [])] + parts['alone'] + parts.get('use', [])
                self.assertEqual(d['items'], list(dict.fromkeys(own)), lesson['id'])
                self.assertNotIn(parts['show'], d['items'])
                self.assertTrue(os.path.exists(os.path.join(STARTER, 'activity.%s.json' % parts['show'])))
                for t in parts.get('together', []):
                    a = load('activity.%s.json' % t['id'])
                    # a share has no lead player (arc_checks.dart leadableSteps): its Together item is led 0, as every other template's
                    if a['template'] in ('sort_drag', 'shape_builder', 'trace') and a['answer'].get('mode') != 'share':
                        steps = {'sort_drag': lambda: len(a['scene']['items']), 'shape_builder': lambda: len(a['scene']['slots']),
                                 'trace': lambda: sum(len(s) - 1 if len(s) <= 8 else 4 for s in a['scene']['strokes'])}[a['template']]()
                        self.assertTrue(1 <= t['lead'] < steps, t)
                    else:
                        self.assertEqual(t['lead'], 0, t)
        self.assertGreaterEqual(n, 20)

    def test_a_lesson_with_an_empty_alone_pool_is_refused(self):
        # QA-2: the planner serves nothing from an empty Alone pool, so the build refuses such a lesson instead of writing parts that play flat
        import sys
        sys.path.insert(0, os.path.join(ROOT, 'tools'))
        import arc_build
        lesson = {'id': 'x', 'show': 'show.shp-a-01', 'together': [], 'alone': []}
        with self.assertRaises(AssertionError) as raised:
            arc_build.lesson_parts(lesson, {'show.shp-a-01'}, [], 0)
        self.assertIn('empty Alone pool', str(raised.exception))
        lesson['alone'] = ['shp.match.square']
        self.assertEqual(arc_build.lesson_parts(lesson, {'show.shp-a-01'}, [], 0)['alone'], ['shp.match.square'])

    def test_the_lessons_that_wait_for_a_show_keep_their_flat_list(self):
        d = load('lesson.where-is-it.json')
        self.assertNotIn('parts', d)
        self.assertTrue(d['items'])

    def test_the_voice_list_gets_the_host_lines(self):
        # every host line of a lesson's parts and of a Show carries a vo id with its caption, so voicing counts it as a pending clip
        d = load('lesson.any-shape.json')
        for t in d['parts']['together']:
            self.assertTrue(t['line']['vo'].startswith('vo:host.'))
        self.assertTrue(d['parts']['handover']['vo'].startswith('vo:host.'))
        show = load('activity.%s.json' % d['parts']['show'])
        self.assertTrue(all(l['vo'].startswith('vo:host.') for l in show['show']['lines']))

    def test_the_build_is_deterministic(self):
        import subprocess
        import sys
        before = {n: open(os.path.join(STARTER, n), 'rb').read() for n in os.listdir(STARTER) if n.startswith(('activity.show.', 'lesson.'))}
        subprocess.run([sys.executable, '-s', os.path.join(ROOT, 'tools', 'arc_build.py')], cwd=ROOT, check=True, stdout=subprocess.DEVNULL)
        after = {n: open(os.path.join(STARTER, n), 'rb').read() for n in before}
        self.assertEqual(before, after)


if __name__ == '__main__':
    unittest.main()
