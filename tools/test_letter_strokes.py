"""F6, the letter stroke data, and the HEB-A-14 stroke scenes (docs/languages/strokes.md).

    python tools/test_letter_strokes.py

* the four sets are what the generator writes (nothing edited by hand) and every form passes the generator's checks;
* the counts: latin 52, cyrillic 66, hebrew-print 27, hebrew-script 27 (frame F6);
* every stroke fits the trace template's format: whole box units 0 to 100, 2 to 60 points, its start is its first point,
  1 to 6 strokes a letter, and a line stroke is long enough to trace (a dot or a short mark says so);
* each set is marked needs-teacher until its teacher has checked it (then teacher-checked: latin, cyrillic, hebrew-print, hebrew-script and the A-14 scenes, 2026-11-05);
* the A-14 scenes: 9 items whose strokes drop into the existing `trace` activity as they are (1 to 3 strokes, the schema's
  limits), each with its picture and (but the door) its mover on disk.
The --fit check against the fonts needs Chrome and is run by hand (python tools/make_letter_strokes.py --fit).
"""
import json
import math
import os
import sys
import unittest

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(TOOLS, '..'))
sys.path.insert(0, TOOLS)
import make_letter_strokes as ls  # noqa: E402

STROKES = os.path.join(ROOT, 'content', 'languages', 'strokes')
PICTURES = os.path.join(ROOT, 'content', 'languages', 'pictures')
COUNTS = {'latin': 52, 'cyrillic': 66, 'hebrew-print': 27, 'hebrew-script': 27}
# the sets their teacher has checked (docs/languages/strokes.md section 5); every other set stays needs-teacher
REVIEWED = {'latin': 'teacher-checked', 'cyrillic': 'teacher-checked', 'hebrew-print': 'teacher-checked', 'hebrew-script': 'teacher-checked'}


def load(name):
    with open(os.path.join(STROKES, name + '.json'), encoding='utf-8') as fh:
        return json.load(fh)


class LetterStrokesTest(unittest.TestCase):
    def test_generated_and_checked(self):
        for spec in ls.all_specs():
            forms, problems = ls.build_set(spec)
            self.assertEqual(problems, [], spec.SET['set'])
            on_disk = load(spec.SET['set'])
            self.assertEqual([ls.public(f) for f in forms], on_disk['forms'], 'regenerate: python tools/make_letter_strokes.py')

    def test_counts_and_review(self):
        for name, n in COUNTS.items():
            d = load(name)
            self.assertEqual(d['schema'], ls.SCHEMA)
            self.assertEqual(len(d['forms']), n, name)
            self.assertEqual(d['count'], n)
            self.assertEqual(d['review'], REVIEWED.get(name, 'needs-teacher'), name)
            self.assertEqual(len({f['id'] for f in d['forms']}), n, 'ids are unique')

    def test_trace_format(self):
        for name in COUNTS:
            for f in load(name)['forms']:
                self.assertTrue(1 <= len(f['strokes']) <= ls.MAX_STROKES, f['id'])
                for s in f['strokes']:
                    pts = s['points']
                    self.assertTrue(2 <= len(pts) <= ls.MAX_POINTS, f['id'])
                    for x, y in pts:
                        self.assertTrue(isinstance(x, int) and isinstance(y, int) and 0 <= x <= 100 and 0 <= y <= 100, f['id'])
                    self.assertEqual(s['start'], pts[0])
                    self.assertEqual(s['end'], pts[-1])
                    self.assertIn(s['kind'], ('line', 'dot', 'short'))
                    long = sum(math.dist(pts[i - 1], pts[i]) for i in range(1, len(pts)))
                    if s['kind'] == 'line':
                        self.assertGreaterEqual(long, ls.MIN_TRACE - 1, f['id'])
                    self.assertTrue(s['moves'], f['id'])

    def test_alternates(self):
        """The other right builds of a letter (tools/strokes_alternates.py): at most MAX_BUILDS a form, within the same caps, no path and no
        moves (a build is only compared with the child's strokes), never the model again, and only for the forms listed there."""
        from strokes_alternates import ALTERNATES
        found = {}
        for name in COUNTS:
            for f in load(name)['forms']:
                builds = f.get('alternates', [])
                if not builds:
                    continue
                found[f['id']] = len(builds)
                self.assertLessEqual(len(builds), ls.MAX_BUILDS, f['id'])
                for b in builds:
                    self.assertTrue(1 <= len(b['strokes']) <= ls.MAX_STROKES, f['id'])
                    self.assertNotEqual([s['points'] for s in b['strokes']], [s['points'] for s in f['strokes']], f['id'])
                    for s in b['strokes']:
                        self.assertEqual(set(s) - {'retrace'}, {'kind', 'points'}, f['id'])
                        self.assertTrue(2 <= len(s['points']) <= ls.MAX_POINTS, f['id'])
                        for x, y in s['points']:
                            self.assertTrue(isinstance(x, int) and isinstance(y, int) and 0 <= x <= 100 and 0 <= y <= 100, f['id'])
        self.assertEqual(found, {k: len(v) for k, v in ALTERNATES.items()})

    def test_hebrew_groups_and_finals(self):
        script = load('hebrew-script')['forms']
        groups = {f['char']: f['group'] for f in script}
        for ch in 'רהתחקב':
            self.assertEqual(groups[ch], 'arch', ch)
        for ch in 'יומנן':
            self.assertEqual(groups[ch], 'falling', ch)
        for d in (load('hebrew-print'), load('hebrew-script')):
            finals = {f['char'] for f in d['forms'] if f['final']}
            self.assertEqual(finals, set('ךםןףץ'))
            for f in d['forms']:
                if f['char'] in 'קךןףץ':
                    self.assertEqual(f['sits'][1], 'basement', f['id'])


class StrokeScenesTest(unittest.TestCase):
    def test_items(self):
        d = load('prewriting-heb-a14')
        self.assertEqual(len(d['items']), 9)
        self.assertEqual(d['review'], 'teacher-checked')  # hebrew-language-teacher, 2026-11-05
        for it in d['items']:
            self.assertTrue(os.path.exists(os.path.join(PICTURES, it['picture'] + '.svg')), it['picture'])
            if it['mover']:
                self.assertTrue(os.path.exists(os.path.join(PICTURES, it['mover'] + '.svg')), it['mover'])
                self.assertIn(it['orient'], ('none', 'face', 'tangent', 'tangent-upright'))
            # the `trace` schema: 1 to 3 strokes, each 2 to 60 whole points in 0..100, and at least 25 units long
            self.assertTrue(1 <= len(it['scenePoints']) <= 3, it['id'])
            for pts in it['scenePoints']:
                self.assertTrue(2 <= len(pts) <= 60)
                self.assertTrue(all(0 <= v <= 100 and isinstance(v, int) for p in pts for v in p))
                self.assertGreaterEqual(sum(math.dist(pts[i - 1], pts[i]) for i in range(1, len(pts))), 25)
        self.assertEqual([it['guide'] for it in d['items']], ['full'] * 4 + ['start'] * 5)
        door = d['items'][8]
        self.assertEqual([s['moves'] for s in door['strokes']], [['right'], ['down'], ['down']])

    def test_no_text_in_pictures(self):
        for name in os.listdir(PICTURES):
            if name.startswith(('stroke-', 'mover-')):
                with open(os.path.join(PICTURES, name), encoding='utf-8') as fh:
                    self.assertNotIn('<text', fh.read(), name)


if __name__ == '__main__':
    unittest.main()
