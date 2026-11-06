"""The robot checker (tools/check_robot.py) against planted bad tasks, and once over the real pack.

    python -I tools/test_check_robot.py
"""
import contextlib
import copy
import io
import json
import os
import shutil
import sys
import tempfile
import unittest

TOOLS = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, TOOLS)
sys.dont_write_bytecode = True  # no __pycache__ in tools/
import check_robot as cr  # noqa: E402

PLAN = {
    'schema': 'activity/v1', 'id': 'plant.plan', 'template': 'robot_path', 'domain': 'cs', 'band': 'B',
    'skills': [{'id': 'CS-B-01', 'weight': 1}],
    'prompt': {'caption': [{'t': 'he', 'v': 'הָרוֹבּוֹט צָרִיךְ לְהַגִּיעַ אֶל הַדֶּגֶל.'}]},
    'scene': {'cols': 4, 'rows': 4, 'robot': {'col': 0, 'row': 3}, 'goal': {'col': 2, 'row': 0},
              'robotSprite': 'asset:robot', 'goalSprite': 'asset:flag'},
    'answer': {'type': 'path', 'mode': 'plan', 'maxSteps': 7, 'solution': ['up', 'up', 'right', 'right', 'up'],
               'misconception': 'M-CS-OFF1'},
}

STEPS = {
    'schema': 'activity/v1', 'id': 'plant.steps', 'template': 'tap_answer', 'domain': 'cs', 'band': 'B',
    'skills': [{'id': 'CS-B-01', 'weight': 1}],
    'prompt': {'caption': [{'t': 'he', 'v': 'כַּמָּה צְעָדִים מֵהָרוֹבּוֹט עַד הַדֶּגֶל?'}]},
    'scene': {'row': ['asset:robot', 'asset:grass', 'asset:grass', 'asset:flag']},
    'answer': {'type': 'choice', 'correct': 'o2', 'options': [
        {'id': 'o1', 'numeral': 2, 'label': 'שְׁתַּיִם', 'misconception': 'M-CNT-SKIP'},
        {'id': 'o2', 'numeral': 3, 'label': 'שָׁלוֹשׁ'},
        {'id': 'o3', 'numeral': 4, 'label': 'אַרְבַּע', 'misconception': 'M-CS-OFF1'}]},
}

REPEAT = {
    'schema': 'activity/v1', 'id': 'plant.repeat', 'template': 'spot_error', 'domain': 'cs', 'band': 'B',
    'skills': [{'id': 'CS-B-04', 'weight': 1}],
    'prompt': {'caption': [{'t': 'he', 'v': 'הַתׇּכְנִית צְרִיכָה לַחֲזֹר עַל: לְמַעְלָה, יָמִינָה. אֵיפֹה הַצַּעַד הַלֹּא נָכוֹן?'}]},
    'scene': {'cells': ['dir:up', 'dir:right', 'dir:up', 'dir:left', 'dir:up', 'dir:right']},
    'answer': {'type': 'spot', 'wrong': 3, 'misconception': 'M-CS-FIXALL'},
}


def run(*docs):
    folder = tempfile.mkdtemp()
    try:
        for d in docs:
            with open(os.path.join(folder, 'activity.%s.json' % d['id']), 'w', encoding='utf-8') as fh:
                json.dump(d, fh, ensure_ascii=False)
        for t in ('M-CS-OFF1', 'M-CNT-SKIP', 'M-CS-FIXALL'):
            with open(os.path.join(folder, 'misconception.%s.json' % t), 'w', encoding='utf-8') as fh:
                json.dump({'id': t}, fh)
        # root: a folder with no app, so only the planted tasks are judged
        rows, counts = cr.check(folder, root=folder)
    finally:
        shutil.rmtree(folder)
    return rows, counts


def codes(rows):
    return {(r[0], r[2]) for r in rows}


def failing(rows):
    return [r for r in rows if r[0] in ('WRONG', 'RULE')]


class Planted(unittest.TestCase):
    def test_good_tasks_pass(self):
        rows, counts = run(PLAN, STEPS, REPEAT)
        self.assertEqual(failing(rows), [])
        self.assertEqual(counts['checked'], 3)
        self.assertEqual(counts['simulated'], 1)

    def test_solution_off_the_grid_or_off_the_flag(self):
        bad = copy.deepcopy(PLAN)
        bad['answer']['solution'] = ['left'] + PLAN['answer']['solution']
        self.assertIn(('WRONG', 'solution'), codes(run(bad)[0]))
        bad = copy.deepcopy(PLAN)
        bad['answer']['solution'] = ['up', 'up', 'right', 'up']
        self.assertIn(('WRONG', 'solution'), codes(run(bad)[0]))

    def test_detour_and_shortest(self):
        bad = copy.deepcopy(PLAN)
        bad['answer']['solution'] = ['up', 'up', 'right', 'right', 'right', 'left', 'up']
        self.assertIn(('RULE', 'detour'), codes(run(bad)[0]))
        bad['answer']['shortest'] = True
        self.assertIn(('WRONG', 'detour'), codes(run(bad)[0]))

    def test_not_solvable_within_the_step_limit(self):
        bad = copy.deepcopy(PLAN)
        bad['answer']['maxSteps'] = 4
        self.assertIn(('WRONG', 'unsolvable'), codes(run(bad)[0]))

    def test_obstacles_and_walls(self):
        bad = copy.deepcopy(PLAN)
        bad['scene']['obstacles'] = [{'col': 0, 'row': 2}]
        self.assertIn(('WRONG', 'solution'), codes(run(bad)[0]))
        shut = copy.deepcopy(PLAN)
        shut['scene']['walls'] = [{'col': 2, 'row': 0, 'side': 'down'}, {'col': 2, 'row': 0, 'side': 'left'},
                                  {'col': 2, 'row': 0, 'side': 'right'}]
        self.assertIn(('WRONG', 'unsolvable'), codes(run(shut)[0]))

    def test_distractor_programs(self):
        item = copy.deepcopy(PLAN)
        item['template'] = 'tap_answer'
        item['answer'] = {'type': 'choice', 'correct': 'o1', 'options': [
            {'id': 'o1', 'program': ['up', 'up', 'up', 'right', 'right']},
            {'id': 'o2', 'program': ['right', 'right', 'up', 'up', 'up'], 'misconception': 'M-CS-OFF1'}]}
        self.assertIn(('WRONG', 'second-right'), codes(run(item)[0]))
        shell = copy.deepcopy(PLAN)
        shell['answer']['solution'] = ['up', 'up', 'up', 'right', 'right']
        f = cr.cm.Findings()
        it = cr.cm.Item(dict(shell, answer=dict(shell['answer'], options=item['answer']['options'], correct='o1')))
        cr.check_path(f, it)
        self.assertIn(('WRONG', 'second-right'), codes(f.rows))
        still = copy.deepcopy(it.doc)
        still['answer']['options'][1]['program'] = ['turnLeft', 'turnRight']
        f = cr.cm.Findings()
        cr.check_path(f, cr.cm.Item(still))
        self.assertIn(('AMBIG', 'invisible'), codes(f.rows))

    def test_band_a_plans_three_steps(self):
        bad = copy.deepcopy(PLAN)
        bad['band'] = 'A'
        bad['skills'] = [{'id': 'CS-A-04', 'weight': 1}]
        self.assertIn(('RULE', 'band'), codes(run(bad)[0]))

    def test_heading_and_repeat(self):
        item = copy.deepcopy(PLAN)
        item['band'] = 'C'
        item['scene']['robot']['facing'] = 'up'
        item['answer']['maxSteps'] = 12
        item['answer']['solution'] = [{'repeat': 3, 'body': ['forward']}, 'turnRight', {'repeat': 2, 'body': ['forward']}]
        self.assertEqual(failing(run(item)[0]), [])
        wrong = copy.deepcopy(item)
        wrong['answer']['solution'][1] = 'turnLeft'
        self.assertIn(('WRONG', 'solution'), codes(run(wrong)[0]))

    def test_steps_row(self):
        bad = copy.deepcopy(STEPS)
        bad['answer']['correct'] = 'o3'
        self.assertIn(('WRONG', 'answer'), codes(run(bad)[0]))

    def test_repeat_spot(self):
        bad = copy.deepcopy(REPEAT)
        bad['answer']['wrong'] = 2
        self.assertIn(('WRONG', 'answer'), codes(run(bad)[0]))
        two = copy.deepcopy(REPEAT)
        two['scene']['cells'][5] = 'dir:down'
        self.assertIn(('WRONG', 'answer'), codes(run(two)[0]))

    def test_exit_code(self):
        folder = tempfile.mkdtemp()
        try:
            bad = copy.deepcopy(PLAN)
            bad['answer']['solution'] = ['up']
            with open(os.path.join(folder, 'activity.plant.json'), 'w', encoding='utf-8') as fh:
                json.dump(bad, fh)
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(cr.main(['--dir', folder]), 1)
        finally:
            shutil.rmtree(folder)


class RealPack(unittest.TestCase):
    def test_every_robots_item_is_read_and_every_grid_simulated(self):
        rows, counts = cr.check()
        self.assertGreater(counts['simulated'], 0)
        self.assertEqual([r for r in rows if r[0] == 'UNCHECKED'], [])
        self.assertEqual([r for r in rows if r[0] == 'WRONG' and r[2] in ('solution', 'unsolvable', 'grid', 'ltr')], [])


if __name__ == '__main__':
    unittest.main()
