"""The maths checker (tools/check_maths.py) against planted bad items, and once over the real pack.

    python -I tools/test_check_maths.py

Every planted item is a small activity in the form of content/starter; a good one gives no WRONG or RULE finding, and
each bad one gives the finding it was planted for.
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
import check_maths as cm  # noqa: E402

CATALOGUE = cm.catalogue_tags()
RECORDS = {'M-CNT-DOUBLE', 'M-CNT-SKIP', 'M-SHP-SQRECT', 'M-SUB-SMALLBIG', 'M-SUB-ORDER', 'M-PART-MISS', 'M-EQ-OPER'}

SUM = {
    'schema': 'activity/v1', 'id': 'plant.sum', 'template': 'tap_answer', 'domain': 'math', 'band': 'B',
    'skills': [{'id': 'MATH-B-01', 'weight': 1}],
    'prompt': {'caption': [{'t': 'he', 'v': 'יֵשׁ שְׁלוֹשָׁה תַּפּוּחִים. מוֹסִיפִים עוֹד שְׁנֵי תַּפּוּחִים. כַּמָּה יֵשׁ עַכְשָׁו?'}]},
    'scene': {'group': {'sprite': 'asset:apple', 'count': 3}, 'group2': {'sprite': 'asset:apple', 'count': 2}},
    'answer': {'type': 'choice', 'correct': 'o1', 'options': [
        {'id': 'o1', 'numeral': 5, 'label': 'חָמֵשׁ'},
        {'id': 'o2', 'numeral': 4, 'label': 'אַרְבַּע', 'misconception': 'M-CNT-SKIP'},
        {'id': 'o3', 'numeral': 6, 'label': 'שֵׁשׁ', 'misconception': 'M-CNT-DOUBLE'}]},
}

ROW = {
    'schema': 'activity/v1', 'id': 'plant.row', 'template': 'tap_answer', 'domain': 'math', 'band': 'C',
    'skills': [{'id': 'MATH-C-05', 'weight': 1}],
    'prompt': {'caption': [{'t': 'he', 'v': 'חֲמִשִּׁים וּשְׁתַּיִם פָּחוֹת עֶשְׂרִים וָשֶׁבַע. כַּמָּה זֶה?'}]},
    'scene': {'row': ['n:52', 'op:-', 'n:27', 'op:=', '?']},
    'answer': {'type': 'choice', 'correct': 'o1', 'options': [
        {'id': 'o1', 'numeral': 25},
        {'id': 'o2', 'numeral': 35, 'misconception': 'M-SUB-SMALLBIG'},
        {'id': 'o3', 'numeral': 24, 'misconception': 'M-CNT-SKIP'}]},
}

RECT = {
    'schema': 'activity/v1', 'id': 'plant.rect', 'template': 'tap_answer', 'domain': 'shapes', 'band': 'B',
    'skills': [{'id': 'SHP-B-03', 'weight': 1}],
    'prompt': {'caption': [{'t': 'he', 'v': 'אֵיפֹה הַמַּלְבֵּן?'}]},
    'scene': {},
    'answer': {'type': 'choice', 'correct': 'o1', 'options': [
        {'id': 'o1', 'sprite': 'asset:shape_rect', 'label': 'מַלְבֵּן'},
        {'id': 'o2', 'sprite': 'asset:shape_square', 'label': 'רִבּוּעַ', 'misconception': 'M-SHP-SQRECT'},
        {'id': 'o3', 'sprite': 'asset:shape_circle', 'label': 'עִגּוּל', 'misconception': 'M-SHP-SQRECT'}]},
}

LINE = {
    'schema': 'activity/v1', 'id': 'plant.line', 'template': 'number_line', 'domain': 'numbers', 'band': 'B',
    'skills': [{'id': 'NUM-B-13', 'weight': 1}],
    'prompt': {'caption': [{'t': 'he', 'v': 'הַצְּפַרְדֵּעַ עוֹמֶדֶת עַל שָׁלוֹשׁ וְקוֹפֶצֶת שְׁנֵי צְעָדִים קָדִימָה.'}]},
    'scene': {'from': 0, 'to': 10, 'labels': list(range(11)), 'start': 3, 'hops': [2]},
    'answer': {'type': 'line', 'mode': 'jump', 'target': 5, 'misconception': 'M-CNT-SKIP',
               'mirrorMisconception': 'M-CNT-DOUBLE'},
}

SPOT = {
    'schema': 'activity/v1', 'id': 'plant.spot', 'template': 'spot_error', 'domain': 'math', 'band': 'B',
    'skills': [{'id': 'MATH-B-03', 'weight': 1}],
    'prompt': {'caption': [{'t': 'he', 'v': 'חָבֵר כָּתַב תַּרְגִּיל, וְהַתְּשׁוּבָה לֹא נְכוֹנָה. אֵיפֹה הַטָּעוּת?'}]},
    'scene': {'cells': ['n:6', 'op:+', 'n:2', 'op:=', 'n:9']},
    'answer': {'type': 'spot', 'wrong': 4, 'misconception': 'M-EQ-OPER'},
}


def run(*docs, svg_dir=None):
    folder = svg_dir or tempfile.mkdtemp()
    try:
        f, counts = cm.check_docs([copy.deepcopy(d) for d in docs], RECORDS, {}, CATALOGUE, cm.Svg(folder))
    finally:
        if svg_dir is None:
            shutil.rmtree(folder)
    return f.rows, counts


def codes(rows, sev=None):
    return {(r[0], r[2]) for r in rows if sev is None or r[0] == sev}


def failing(rows):
    return [r for r in rows if r[0] in cm.FAILING]


class Hebrew(unittest.TestCase):
    def test_numbers(self):
        self.assertEqual(cm.numbers('שְׁלֹשׁ עֶשְׂרֵה'), [13])
        self.assertEqual(cm.numbers('שְׁלוֹשָׁה עָשָׂר תַּפּוּחִים'), [13])
        self.assertEqual(cm.numbers('עֶשְׂרִים וְאַרְבַּע'), [24])
        self.assertEqual(cm.numbers('סוֹפְרִים בִּשְׁתַּיִם: שֵׁשׁ, שְׁמוֹנֶה, עֶשֶׂר.'), [6, 8, 10])
        self.assertEqual(cm.numbers('עֶשֶׂר זֶה שָׁלוֹשׁ וְעוֹד כַּמָּה?'), [10, 3])

    def test_colours_and_shapes(self):
        self.assertEqual(cm.colours_in('אֵיפֹה הַבָּלוֹן הָאָדֹם?'), ['red'])
        self.assertEqual(cm.shapes_in('חָבֵר אוֹסֵף רַק מְשֻׁלָּשִׁים.'), ['triangle'])

    def test_smallbig(self):
        self.assertEqual(cm.smallbig(52, 27), 35)
        self.assertEqual(cm.smallbig(58, 23), 35)


class Planted(unittest.TestCase):
    def test_good_items_pass(self):
        rows, counts = run(SUM, ROW, LINE, SPOT)
        self.assertEqual(failing(rows), [])
        self.assertEqual(counts['checked'], 4)

    def test_wrong_marked_answer(self):
        bad = copy.deepcopy(SUM)
        bad['answer']['correct'] = 'o3'
        self.assertIn(('WRONG', 'answer'), codes(run(bad)[0]))

    def test_second_right_answer(self):
        bad = copy.deepcopy(SUM)
        bad['answer']['options'][1].update(numeral=5, label='חָמֵשׁ')
        self.assertIn(('WRONG', 'second-right'), codes(run(bad)[0]))

    def test_square_is_a_rectangle(self):
        self.assertIn(('WRONG', 'second-right'), codes(run(RECT)[0]))

    def test_untagged_distractor(self):
        bad = copy.deepcopy(SUM)
        del bad['answer']['options'][2]['misconception']
        self.assertIn(('RULE', 'tag-missing'), codes(run(bad)[0]))
        two = copy.deepcopy(SUM)
        two['answer']['options'] = two['answer']['options'][:1] + [{'id': 'o2', 'numeral': 4, 'label': 'אַרְבַּע'}]
        self.assertIn(('RULE', 'tag-missing'), codes(run(two)[0]))

    def test_unknown_tag(self):
        bad = copy.deepcopy(SUM)
        bad['answer']['options'][2]['misconception'] = 'M-MADE-UP'
        self.assertIn(('RULE', 'tag-unknown'), codes(run(bad)[0]))

    def test_tag_rule_reproduces_the_distractor(self):
        # 6 for 3 + 2 is one more: M-CNT-DOUBLE fits; 4 is one less, and tagged M-CNT-DOUBLE it does not
        bad = copy.deepcopy(SUM)
        bad['answer']['options'][1]['misconception'] = 'M-CNT-DOUBLE'
        bad['answer']['options'][2]['misconception'] = 'M-CNT-SKIP'
        rows = run(bad)[0]
        self.assertEqual(sum(1 for r in rows if r[2] == 'tag-rule'), 2)
        # smallbig(52, 27) = 35 is accepted; 45 tagged M-SUB-SMALLBIG is not
        self.assertNotIn(('RULE', 'tag-rule'), codes(run(ROW)[0]))
        bad = copy.deepcopy(ROW)
        bad['answer']['options'][1]['numeral'] = 45
        self.assertIn(('RULE', 'tag-rule'), codes(run(bad)[0]))

    def test_out_of_range_and_too_many_options(self):
        bad = copy.deepcopy(SUM)
        bad['band'] = 'A'
        bad['skills'] = [{'id': 'MATH-A-01', 'weight': 1}]
        bad['scene']['group']['count'] = 9
        bad['prompt']['caption'][0]['v'] = 'יֵשׁ תִּשְׁעָה תַּפּוּחִים. מוֹסִיפִים עוֹד שְׁנֵי תַּפּוּחִים. כַּמָּה יֵשׁ עַכְשָׁו?'
        bad['answer']['options'] = [{'id': 'o1', 'numeral': 11, 'label': 'אַחַת עֶשְׂרֵה'},
                                    {'id': 'o2', 'numeral': 10, 'label': 'עֶשֶׂר', 'misconception': 'M-CNT-SKIP'},
                                    {'id': 'o3', 'numeral': 12, 'label': 'שְׁתֵּים עֶשְׂרֵה', 'misconception': 'M-CNT-DOUBLE'},
                                    {'id': 'o4', 'numeral': 13, 'label': 'שְׁלֹשׁ עֶשְׂרֵה', 'misconception': 'M-CNT-DOUBLE'}]
        found = codes(run(bad)[0])
        self.assertIn(('RULE', 'range'), found)
        self.assertIn(('RULE', 'options'), found)

    def test_picture_count_does_not_match_the_caption(self):
        bad = copy.deepcopy(SUM)
        bad['scene']['group2']['count'] = 4
        self.assertIn(('WRONG', 'picture'), codes(run(bad)[0]))

    def test_label_names_another_number(self):
        bad = copy.deepcopy(SUM)
        bad['answer']['options'][0]['label'] = 'שֵׁשׁ'
        self.assertIn(('WRONG', 'label'), codes(run(bad)[0]))

    def test_number_line_mirrored_or_landing_elsewhere(self):
        bad = copy.deepcopy(LINE)
        bad['scene']['labels'] = list(range(10, -1, -1))
        self.assertIn(('WRONG', 'ltr'), codes(run(bad)[0]))
        bad = copy.deepcopy(LINE)
        bad['answer']['target'] = 6
        self.assertIn(('WRONG', 'answer'), codes(run(bad)[0]))

    def test_spot_error(self):
        true = copy.deepcopy(SPOT)
        true['scene']['cells'][-1] = 'n:8'
        self.assertIn(('WRONG', 'spot'), codes(run(true)[0]))
        moved = copy.deepcopy(SPOT)
        moved['answer']['wrong'] = 0
        self.assertIn(('WRONG', 'spot'), codes(run(moved)[0]))
        loose = copy.deepcopy(SPOT)
        loose['prompt']['caption'][0]['v'] = 'חָבֵר כָּתַב מִסְפָּרִים, וְאֶחָד מֵהֶם לֹא מַתְאִים. אֵיפֹה הַטָּעוּת?'
        self.assertIn(('AMBIG', 'spot-many'), codes(run(loose)[0]))

    def test_equal_sides_that_only_look_equal(self):
        folder = tempfile.mkdtemp()
        try:
            for name, body in (('shape_square', '<rect x="10" y="10" width="80" height="80"/>'),
                               ('shape_triangle', '<polygon points="50,12 90,84 10,84"/>')):
                with open(os.path.join(folder, name + '.svg'), 'w', encoding='utf-8') as fh:
                    fh.write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">%s</svg>' % body)
            item = {'id': 'plant.equal', 'template': 'tap_answer', 'domain': 'shapes', 'band': 'B',
                    'skills': [{'id': 'SHP-B-03', 'weight': 1}],
                    'prompt': {'caption': [{'t': 'he', 'v': 'לְאֵיזוֹ צוּרָה כׇּל הַצְּלָעוֹת שָׁווֹת?'}]}, 'scene': {},
                    'answer': {'type': 'choice', 'correct': 'o1', 'options': [
                        {'id': 'o1', 'sprite': 'asset:shape_square'},
                        {'id': 'o2', 'sprite': 'asset:shape_triangle', 'misconception': 'M-SHP-SQRECT'}]}}
            self.assertIn(('AMBIG', 'looks-equal'), codes(run(item, svg_dir=folder)[0]))
        finally:
            shutil.rmtree(folder)

    def test_an_item_no_rule_reads(self):
        odd = copy.deepcopy(SUM)
        odd['prompt']['caption'][0]['v'] = 'בּוֹחֲרִים מַשֶּׁהוּ.'
        odd['scene'] = {}
        rows, counts = run(odd)
        self.assertIn(('UNCHECKED', 'no-rule'), codes(rows))
        self.assertEqual(counts['checked'], 0)

    def test_exit_codes(self):
        folder = tempfile.mkdtemp()
        try:
            for d in (SUM, LINE):
                with open(os.path.join(folder, 'activity.%s.json' % d['id']), 'w', encoding='utf-8') as fh:
                    json.dump(d, fh, ensure_ascii=False)
            for t in sorted(RECORDS):
                with open(os.path.join(folder, 'misconception.%s.json' % t), 'w', encoding='utf-8') as fh:
                    json.dump({'id': t}, fh)
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(cm.main(['--dir', folder]), 0)
            bad = copy.deepcopy(SUM)
            bad['answer']['correct'] = 'o2'
            with open(os.path.join(folder, 'activity.plant.sum.json'), 'w', encoding='utf-8') as fh:
                json.dump(bad, fh, ensure_ascii=False)
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(cm.main(['--dir', folder]), 1)
        finally:
            shutil.rmtree(folder)


def c1_item(caption, options, correct='o1', row=None, scene=None, skill='NUM-C-04'):
    """A Band C choice item of batch C1 (M10): numerals on tiles, each wrong one with its tag."""
    sc = dict(scene or {})
    if row is not None:
        sc['row'] = row
    return {'schema': 'activity/v1', 'id': 'plant.c1', 'template': 'tap_answer', 'domain': 'numbers', 'band': 'C',
            'skills': [{'id': skill, 'weight': 1}], 'prompt': {'caption': [{'t': 'he', 'v': caption}]}, 'scene': sc,
            'answer': {'type': 'choice', 'correct': correct, 'options': [
                dict({'id': 'o%d' % (k + 1), 'numeral': v}, **({'misconception': t} if t else {}))
                for k, (v, t) in enumerate(options)]}}


class BatchC1(unittest.TestCase):
    """The rules added for batch C1 (M10, the maths teacher, 2026-11-06)."""
    TAGS = RECORDS | {'M-PV-FACE', 'M-PV-ZERO', 'M-SIGN-DIR', 'M-NUM-REV', 'M-MONEY-COUNT', 'M-CNT-CARD'}

    def c1run(self, doc):
        folder = tempfile.mkdtemp()
        try:
            f, _ = cm.check_docs([copy.deepcopy(doc)], self.TAGS, {}, CATALOGUE, cm.Svg(folder))
        finally:
            shutil.rmtree(folder)
        return f.rows

    def failing(self, doc):
        return [r for r in self.c1run(doc) if r[0] != 'NOTE']

    def test_hundreds_are_read(self):
        self.assertEqual(cm.numbers('שְׁלֹשׁ מֵאוֹת וְאַרְבַּע'), [304])
        self.assertEqual(cm.numbers('מָאתַיִם וְשָׁלוֹשׁ'), [203])
        self.assertEqual(cm.numbers('שְׁלֹשׁ מֵאוֹת אַרְבָּעִים וְחָמֵשׁ'), [345])
        self.assertEqual(cm.numbers('מֵאָה'), [100])

    def test_an_inequality_with_its_two_tags(self):
        good = c1_item('אֵיזֶה מִסְפָּר מַתְאִים לַמָּקוֹם הָרֵיק?', [(43, None), (61, 'M-PV-FACE'), (79, 'M-SIGN-DIR')],
                       row=['n:58', 'op:>', '?'])
        self.assertEqual(self.failing(good), [])
        both = copy.deepcopy(good)
        both['answer']['options'][1]['numeral'] = 12  # 58 > 12 is true too
        self.assertIn(('WRONG', 'second-right'), codes(self.c1run(both)))
        swapped = copy.deepcopy(good)
        swapped['answer']['options'][1]['misconception'] = 'M-SIGN-DIR'
        swapped['answer']['options'][2]['misconception'] = 'M-PV-FACE'
        self.assertIn(('RULE', 'tag-rule'), codes(self.c1run(swapped)))

    def test_compare_by_the_ones_first(self):
        good = c1_item('אֵיזֶה מִסְפָּר גָּדוֹל יוֹתֵר?', [(41, None), (39, 'M-PV-FACE'), (14, 'M-NUM-REV')])
        self.assertEqual(self.failing(good), [])
        bad = copy.deepcopy(good)
        bad['answer']['options'][1]['numeral'] = 31  # comparing the ones first picks 39, not 31
        self.assertIn(('RULE', 'tag-rule'), codes(self.c1run(bad)))

    def test_coins_and_a_number_written_as_heard(self):
        coins = c1_item('כַּמָּה שְׁקָלִים יֵשׁ כָּאן?', [(34, None), (7, 'M-MONEY-COUNT'), (43, 'M-NUM-REV'), (304, 'M-PV-ZERO')],
                        scene={'group': {'sprite': 'asset:coin_s10', 'count': 3}, 'group2': {'sprite': 'asset:coin_s1', 'count': 4}},
                        skill='NUM-C-03')
        self.assertEqual(self.failing(coins), [])
        wrong = copy.deepcopy(coins)
        wrong['scene']['group']['count'] = 4  # the coins make 44
        self.assertIn(('WRONG', 'answer'), codes(self.c1run(wrong)))

    def test_tens_and_ones_in_words(self):
        doc = c1_item('שֶׁבַע יְחִידוֹת וּשְׁתֵּי עֲשָׂרוֹת. אֵיזֶה מִסְפָּר זֶה?', [(27, None), (72, 'M-NUM-REV'), (207, 'M-PV-ZERO')],
                      skill='NUM-C-03')
        self.assertEqual(self.failing(doc), [])

    def test_counting_on_that_counts_the_start_only_in_a_sentence(self):
        doc = c1_item('כַּמָּה זֶה?', [(15, None), (14, 'M-CNT-DOUBLE'), (8, 'M-CNT-CARD')], row=['n:8', 'op:+', 'n:7', 'op:=', '?'],
                      skill='MATH-C-01')
        self.assertNotIn(('RULE', 'tag-rule'), codes(self.c1run(doc)))


class C1Gate(unittest.TestCase):
    """QA-C1-10: the gate of batch C1 is every c.* id (its Band A and B bridge items too), and the rules QA-C1-9 asked for."""

    def test_ids_select_by_prefix_whatever_the_band(self):
        bridge = c1_item('אֵיפֹה הַמִּסְפָּר שֵׁשׁ?', [(6, None), (9, 'M-NUM-REV'), (7, 'M-CNT-SEQ')], skill='NUM-B-06')
        bridge.update(id='c.numb06.1', band='B')
        other = copy.deepcopy(bridge)
        other['id'] = 'b.numb06.1'
        it = [cm.Item(bridge), cm.Item(other)]
        self.assertEqual([cm.selected(i, 'C') for i in it], [False, False], '--band C misses the bridge items')
        self.assertEqual([cm.selected(i, ids=['c.']) for i in it], [True, False])
        self.assertEqual([cm.selected(i, 'B', ['c.']) for i in it], [True, False])

    def test_the_gate_counts_the_bridges_and_fails_on_them(self):
        folder = tempfile.mkdtemp()
        try:
            bad = c1_item('אֵיפֹה הַמִּסְפָּר שֵׁשׁ?', [(6, None), (9, 'M-NUM-REV'), (0, 'M-NUM-REV')], skill='NUM-B-06')
            bad.update(id='c.numb06.1', band='B')
            with open(os.path.join(folder, 'activity.c.numb06.1.json'), 'w', encoding='utf-8') as fh:
                json.dump(bad, fh, ensure_ascii=False)
            with open(os.path.join(folder, 'skill.NUM-B-06.json'), 'w', encoding='utf-8') as fh:
                json.dump({'id': 'NUM-B-06', 'misconceptions': ['M-NUM-REV']}, fh)
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(cm.main(['--dir', folder, '--band', 'C', '--strict']), 0, 'the old gate saw nothing')
                self.assertEqual(cm.main(['--dir', folder, '--ids', 'c.', '--strict']), 1, '0 is not 6 turned round')
        finally:
            shutil.rmtree(folder)

    def test_a_single_digit_reversal_is_the_turned_or_mirrored_numeral(self):
        self.assertEqual(cm.tag_candidates('M-NUM-REV', {'x': 6}), {9})
        self.assertEqual(cm.tag_candidates('M-NUM-REV', {'x': 2}), {5})
        self.assertEqual(cm.tag_candidates('M-NUM-REV', {'x': 8}), set())
        self.assertEqual(cm.tag_candidates('M-NUM-REV', {'x': 10}), {1})

    def test_one_tag_twice_only_when_the_skill_watches_it(self):
        skills = {'NUM-B-06': {'misconceptions': ['M-NUM-REV']}}
        twice = c1_item('אֵיפֹה הַמִּסְפָּר שֵׁשׁ?', [(6, None), (9, 'M-NUM-REV'), (9, 'M-NUM-REV')], skill='NUM-B-06')
        other = c1_item('אֵיפֹה הַמִּסְפָּר שֵׁשׁ?', [(6, None), (5, 'M-CNT-SEQ'), (7, 'M-CNT-SEQ')], skill='NUM-B-06')
        folder = tempfile.mkdtemp()
        try:
            rows = lambda d: cm.check_docs([d], RECORDS | {'M-NUM-REV', 'M-CNT-SEQ'}, skills, CATALOGUE, cm.Svg(folder))[0].rows
            self.assertNotIn(('RULE', 'tag-distinct'), codes(rows(twice)))
            self.assertIn(('RULE', 'tag-distinct'), codes(rows(other)))
        finally:
            shutil.rmtree(folder)

    def test_coverage_finds_diagnostic_and_lucky_right_items(self):
        docs = [c1_item('אֵיזֶה מִסְפָּר מַתְאִים לַמָּקוֹם הָרֵיק?', [(43, None), (61, 'M-PV-FACE'), (79, 'M-SIGN-DIR')],
                        row=['n:58', 'op:>', '?']),
                c1_item('אֵיזֶה מִסְפָּר גָּדוֹל יוֹתֵר?', [(41, None), (39, 'M-PV-FACE'), (14, 'M-NUM-REV')])]
        docs[1]['id'] = 'plant.c1b'
        folder = tempfile.mkdtemp()
        try:
            cov = cm.coverage(folder, docs=docs, skills={'NUM-C-04': {'misconceptions': ['M-PV-FACE', 'M-SIGN-DIR']}})
        finally:
            shutil.rmtree(folder)
        self.assertEqual(cov['NUM-C-04']['M-PV-FACE'], (['plant.c1', 'plant.c1b'], ['plant.c1']), '58 > 43 is right by the ones too')
        self.assertEqual(cov['NUM-C-04']['M-SIGN-DIR'], (['plant.c1'], None), 'a sign read backwards is never right')


def base_ten_item(t, o, options, skill='NUM-C-03'):
    d = c1_item('כַּמָּה קֻבִּיּוֹת יֵשׁ כָּאן?', options, skill=skill)
    d['scene']['picture'] = {'kind': 'base_ten', 'tens': t, 'ones': o}
    return d


def chart_item(caption, lit, blank, options, skill='NUM-C-09'):
    d = c1_item(caption, options, skill=skill)
    d['scene']['picture'] = {'kind': 'hundred_chart', 'lit': lit, 'blank': blank}
    return d


def number_doc(caption, value, expected, row=None, rules=(), skill='MATH-C-01', picture=None):
    sc = {} if row is None else {'row': row}
    if picture:
        sc['picture'] = picture
    return {'schema': 'activity/v1', 'id': 'plant.num', 'template': 'tap_answer', 'domain': 'math', 'band': 'C',
            'skills': [{'id': skill, 'weight': 1}], 'prompt': {'caption': [{'t': 'he', 'v': caption}]}, 'scene': sc,
            'answer': {'type': 'number', 'value': value,
                       'expected': [{'value': v, 'misconception': t} for v, t in expected],
                       'rules': [{'when': w, 'misconception': t} for w, t in rules]}}


class Pictures(BatchC1):
    """QA-C1-5: the recognisers of base-ten blocks (10 x tens + ones; M-PV-FACE also counts every block as one), the hundred chart
    (the blank cell) and the number answer (the keypad)."""
    TAGS = BatchC1.TAGS | {'M-HC-ROW', 'M-OP-SWAP', 'M-CNT-DECADE', 'M-CNT-SEQ', 'M-NL-SPACE'}

    def test_base_ten_blocks(self):
        good = base_ten_item(3, 4, [(34, None), (7, 'M-PV-FACE'), (43, 'M-NUM-REV'), (304, 'M-PV-ZERO')])
        self.assertEqual(self.failing(good), [])
        fifty = base_ten_item(5, 0, [(50, None), (5, 'M-PV-FACE'), (500, 'M-PV-ZERO')])
        self.assertEqual(self.failing(fifty), [])
        wrong = copy.deepcopy(good)
        wrong['scene']['picture']['tens'] = 4  # the blocks make 44
        self.assertIn(('WRONG', 'answer'), codes(self.c1run(wrong)))
        face = copy.deepcopy(good)
        face['answer']['options'][1]['numeral'] = 8  # 3 rods and 4 cubes counted as ones are 7, not 8
        self.assertIn(('RULE', 'tag-rule'), codes(self.c1run(face)))

    def test_the_hundred_chart(self):
        good = chart_item('עֶשֶׂר יוֹתֵר מִשְּׁלוֹשִׁים וְאַרְבַּע. אֵיזֶה מִסְפָּר בַּמִּשְׁבֶּצֶת הָרֵיקָה?', [34], [44],
                          [(44, None), (35, 'M-HC-ROW'), (24, 'M-OP-SWAP')])
        self.assertEqual(self.failing(good), [])
        lit = copy.deepcopy(good)
        lit['scene']['picture']['lit'] = [33]  # ten more than 34, but 33 is lit
        self.assertIn(('WRONG', 'picture'), codes(self.c1run(lit)))
        row = copy.deepcopy(good)
        row['answer']['options'][1]['numeral'] = 36
        self.assertIn(('RULE', 'tag-rule'), codes(self.c1run(row)))
        after = chart_item('מַה בָּא אַחֲרֵי אַרְבָּעִים?', [40], [41], [(41, None), (50, 'M-CNT-DECADE'), (42, 'M-CNT-SEQ')],
                           skill='NUM-C-01')
        self.assertEqual(self.failing(after), [])
        two = chart_item('מָה מִסְתַּתֵּר כָּאן?', [48, 68], [58, 59], [(58, None), (49, 'M-HC-ROW')])
        self.assertIn(('WRONG', 'unsolvable'), codes(self.c1run(two)))

    def test_a_number_answer(self):
        good = number_doc('כַּמָּה זֶה?', 8, [(22, 'M-OP-SWAP'), (9, 'M-CNT-DOUBLE'), (12, 'M-SUB-SMALLBIG')],
                          row=['n:15', 'op:-', 'n:7', 'op:=', '?'],
                          rules=[('smaller_from_larger', 'M-SUB-SMALLBIG'), ('added_instead', 'M-OP-SWAP')])
        self.assertEqual(self.failing(good), [])
        said = number_doc('כִּתְבוּ אֶת הַמִּסְפָּר עֶשְׂרִים וְשָׁלוֹשׁ.', 23, [(32, 'M-NUM-REV'), (203, 'M-PV-ZERO')], skill='NUM-C-02')
        self.assertEqual(self.failing(said), [])
        off = copy.deepcopy(good)
        off['answer']['value'] = 9
        self.assertIn(('WRONG', 'answer'), codes(self.c1run(off)))
        right = copy.deepcopy(good)
        right['answer']['expected'][0]['value'] = 8
        self.assertIn(('WRONG', 'second-right'), codes(self.c1run(right)))
        small = copy.deepcopy(good)
        small['answer']['expected'][2]['value'] = 11  # 15 - 7, the smaller digit from the larger, is 12
        self.assertIn(('RULE', 'tag-rule'), codes(self.c1run(small)))
        rule = copy.deepcopy(good)
        rule['answer']['rules'][0]['misconception'] = 'M-OP-SWAP'
        self.assertIn(('RULE', 'number-rule'), codes(self.c1run(rule)))
        plus = number_doc('כַּמָּה זֶה?', 15, [(14, 'M-CNT-DOUBLE')], row=['n:8', 'op:+', 'n:7', 'op:=', '?'],
                          rules=[('smaller_from_larger', 'M-SUB-SMALLBIG')])
        self.assertIn(('RULE', 'number-rule'), codes(self.c1run(plus)), 'no smaller-from-larger in an addition')
        blocks = number_doc('כַּמָּה זֶה?', 70, [(7, 'M-PV-FACE')], row=['n:40', 'op:+', 'n:30', 'op:=', '?'],
                            picture={'kind': 'base_ten', 'tens': 6, 'ones': 0}, skill='MATH-C-03')
        self.assertIn(('WRONG', 'picture'), codes(self.c1run(blocks)), '60 is no number of 40 + 30')

    def test_the_lit_rod(self):
        """litRods: "how much is this rod worth?" asks for the lit rods (10), not the whole picture (27)."""
        good = c1_item('כַּמָּה שָׁוֶה הַמּוֹט שֶׁזּוֹהֵר?', [(10, None), (1, 'M-PV-FACE'), (100, 'M-PV-ZERO')], skill='NUM-C-03')
        good['scene']['picture'] = {'kind': 'base_ten', 'tens': 2, 'ones': 7, 'litRods': 1}
        self.assertEqual(self.failing(good), [])
        whole = copy.deepcopy(good)
        whole['answer']['options'][0]['numeral'] = 27  # the whole picture is not what the rod is worth
        self.assertIn(('WRONG', 'answer'), codes(self.c1run(whole)))
        dark = copy.deepcopy(good)
        del dark['scene']['picture']['litRods']
        self.assertIn(('WRONG', 'unsolvable'), codes(self.c1run(dark)))
        face = copy.deepcopy(good)
        face['answer']['options'][1]['numeral'] = 2  # one rod counted as one is 1
        self.assertIn(('RULE', 'tag-rule'), codes(self.c1run(face)))
        many = copy.deepcopy(good)
        many['scene']['picture'].update(litRods=2, crossedRods=1)
        self.assertIn(('WRONG', 'picture'), codes(self.c1run(many)), 'three of two rods')

    def test_two_pictures_compared(self):
        """picture and picture2 with no row: which of the two numbers of blocks is bigger (or smaller); the tiles must hold both."""
        good = c1_item('אֵיזֶה מִסְפָּר גָּדוֹל יוֹתֵר? מִסְתַּכְּלִים עַל הַקֻּבִּיּוֹת.', [(41, None), (39, 'M-PV-FACE'), (14, 'M-NUM-REV')])
        good['scene'].update(picture={'kind': 'base_ten', 'tens': 4, 'ones': 1}, picture2={'kind': 'base_ten', 'tens': 3, 'ones': 9})
        self.assertEqual(self.failing(good), [])
        small = copy.deepcopy(good)
        small['prompt']['caption'][0]['v'] = 'אֵיזֶה מִסְפָּר קָטָן יוֹתֵר? מִסְתַּכְּלִים עַל הַקֻּבִּיּוֹת.'
        self.assertIn(('WRONG', 'answer'), codes(self.c1run(small)), '39 is the smaller, not 41')
        missing = copy.deepcopy(good)
        missing['scene']['picture2']['ones'] = 8  # 38 is drawn, no tile has it
        self.assertIn(('WRONG', 'picture'), codes(self.c1run(missing)))
        face = copy.deepcopy(good)
        face['answer']['options'][2]['misconception'] = 'M-PV-FACE'  # the ones first pick 39, not 14
        face['answer']['options'][1]['misconception'] = 'M-NUM-REV'
        self.assertIn(('RULE', 'tag-rule'), codes(self.c1run(face)))
        chart = copy.deepcopy(good)
        chart['scene']['picture2'] = {'kind': 'hundred_chart', 'lit': [39], 'blank': [40]}
        self.assertIn(('WRONG', 'picture'), codes(self.c1run(chart)), 'a second picture is blocks')

    def test_blocks_over_a_sentence(self):
        """picture2 is the second number of a sum (40 + 30); crossed-out rods are the number taken away (70 - 40)."""
        tags = [(7, 'M-PV-FACE'), (700, 'M-PV-ZERO'), (10, 'M-OP-SWAP')]
        plus = c1_item('כַּמָּה זֶה?', [(70, None)] + tags, row=['n:40', 'op:+', 'n:30', 'op:=', '?'], skill='MATH-C-03')
        plus['scene'].update(picture={'kind': 'base_ten', 'tens': 4}, picture2={'kind': 'base_ten', 'tens': 3})
        self.assertEqual(self.failing(plus), [])
        off = copy.deepcopy(plus)
        off['scene']['picture2']['tens'] = 2  # 4 rods and 2 rods are not 40 + 30
        self.assertIn(('WRONG', 'picture'), codes(self.c1run(off)))
        minus = c1_item('כַּמָּה נִשְׁאַר?', [(30, None), (3, 'M-PV-FACE'), (300, 'M-PV-ZERO'), (110, 'M-OP-SWAP')],
                        row=['n:70', 'op:-', 'n:40', 'op:=', '?'], skill='MATH-C-03')
        minus['scene']['picture'] = {'kind': 'base_ten', 'tens': 7, 'crossedRods': 4}
        self.assertEqual(self.failing(minus), [])
        three = copy.deepcopy(minus)
        three['scene']['picture']['crossedRods'] = 3  # 3 rods crossed out are 30 taken away, the sentence takes 40
        self.assertIn(('WRONG', 'picture'), codes(self.c1run(three)))
        added = copy.deepcopy(minus)
        added['scene']['row'] = ['n:70', 'op:+', 'n:40', 'op:=', '?']
        self.assertIn(('WRONG', 'picture'), codes(self.c1run(added)), 'rods crossed out over an addition')
        alone = base_ten_item(7, 0, [(70, None), (7, 'M-PV-FACE')])
        alone['scene']['picture']['crossedRods'] = 4
        self.assertIn(('WRONG', 'picture'), codes(self.c1run(alone)), 'rods crossed out with no sentence')
        typed = number_doc('כַּמָּה נִשְׁאַר?', 30, [(3, 'M-PV-FACE')], row=['n:70', 'op:-', 'n:40', 'op:=', '?'],
                           picture={'kind': 'base_ten', 'tens': 7, 'crossedRods': 2}, skill='MATH-C-03')
        self.assertIn(('WRONG', 'picture'), codes(self.c1run(typed)), 'the keypad reads the crossed rods too')

    def test_blocks_with_the_sentence_said(self):
        """The sentence said in the question over its blocks, no row (the cube keeps 12 pt): read from the caption, checked against
        the pictures like a row; M-OP-SWAP is the other operation done."""
        plus = c1_item('אַרְבָּעִים וְעוֹד שְׁלוֹשִׁים. כַּמָּה זֶה?', [(70, None), (7, 'M-PV-FACE'), (700, 'M-PV-ZERO'), (10, 'M-OP-SWAP')],
                       scene={'picture': {'kind': 'base_ten', 'tens': 4}, 'picture2': {'kind': 'base_ten', 'tens': 3}},
                       skill='MATH-C-03')
        plus['prompt']['math'] = ['n:40', 'op:+', 'n:30', 'op:=', '?']
        self.assertEqual(self.failing(plus), [])
        off = copy.deepcopy(plus)
        off['scene']['picture2']['tens'] = 2  # 4 rods and 2 rods are not 40 + 30
        self.assertIn(('WRONG', 'picture'), codes(self.c1run(off)))
        swap = copy.deepcopy(plus)
        swap['answer']['options'][3]['numeral'] = 20  # not 40 - 30
        self.assertTrue(self.failing(swap), 'an M-OP-SWAP tile that is not the other operation')
        minus = c1_item('שִׁבְעִים פָּחוֹת אַרְבָּעִים. כַּמָּה נִשְׁאַר?',
                        [(30, None), (3, 'M-PV-FACE'), (300, 'M-PV-ZERO'), (110, 'M-OP-SWAP')],
                        scene={'picture': {'kind': 'base_ten', 'tens': 7, 'crossedRods': 4}}, skill='MATH-C-03')
        minus['prompt']['math'] = ['n:70', 'op:-', 'n:40', 'op:=', '?']
        self.assertEqual(self.failing(minus), [])
        three = copy.deepcopy(minus)
        three['scene']['picture']['crossedRods'] = 3
        self.assertIn(('WRONG', 'picture'), codes(self.c1run(three)))
        asked = copy.deepcopy(minus)
        asked['prompt']['caption'][0]['v'] = 'שִׁבְעִים פָּחוֹת אַרְבָּעִים. כַּמָּה זֶה?'
        self.assertIn(('WRONG', 'picture'), codes(self.c1run(asked)), 'a take-away asks how many are left')

    def test_the_number_run_in_the_bubble(self):
        """prompt.math (owner, 2026-11-07): a sentence said over blocks also shows in numbers, and the run is that sentence: the same
        numbers, the same sign, the gap last (so it matches the blocks too, which are checked against the sentence said)."""
        plus = c1_item('אַרְבָּעִים וְעוֹד שְׁלוֹשִׁים. כַּמָּה זֶה?', [(70, None), (7, 'M-PV-FACE'), (700, 'M-PV-ZERO'), (10, 'M-OP-SWAP')],
                       scene={'picture': {'kind': 'base_ten', 'tens': 4}, 'picture2': {'kind': 'base_ten', 'tens': 3}},
                       skill='MATH-C-03')
        plus['prompt']['math'] = ['n:40', 'op:+', 'n:30', 'op:=', '?']
        self.assertEqual(self.failing(plus), [])
        missing = copy.deepcopy(plus)
        del missing['prompt']['math']
        self.assertIn(('WRONG', 'math'), codes(self.c1run(missing)), 'a sentence said over blocks shows its numbers too')
        for wrong in (['n:40', 'op:+', 'n:20', 'op:=', '?'], ['n:40', 'op:-', 'n:30', 'op:=', '?'], ['n:30', 'op:+', 'n:40', 'op:=', '?'],
                      ['n:40', 'op:+', 'n:30', 'op:=', 'n:70']):
            bad = copy.deepcopy(plus)
            bad['prompt']['math'] = wrong
            self.assertIn(('WRONG', 'math'), codes(self.c1run(bad)), '%s is not the sentence said' % wrong)
        minus = c1_item('שִׁשִּׁים פָּחוֹת עֶשְׂרִים. כַּמָּה נִשְׁאַר?', [(40, None), (4, 'M-PV-FACE'), (400, 'M-PV-ZERO'), (80, 'M-OP-SWAP')],
                        scene={'picture': {'kind': 'base_ten', 'tens': 6, 'crossedRods': 2}}, skill='MATH-C-03')
        minus['prompt']['math'] = ['n:60', 'op:-', 'n:20', 'op:=', '?']
        self.assertEqual(self.failing(minus), [])
        minus['prompt']['math'] = ['n:60', 'op:+', 'n:20', 'op:=', '?']
        self.assertIn(('WRONG', 'math'), codes(self.c1run(minus)), 'the other operation')
        loose = c1_item('כַּמָּה קֻבִּיּוֹת יֵשׁ כָּאן?', [(34, None), (7, 'M-PV-FACE')], scene={'picture': {'kind': 'base_ten', 'tens': 3, 'ones': 4}},
                        skill='NUM-C-03')
        loose['prompt']['math'] = ['n:30', 'op:+', 'n:4', 'op:=', '?']
        self.assertIn(('WRONG', 'math'), codes(self.c1run(loose)), 'a run for a question that says no sentence')

    def test_blocks_on_the_tiles(self):
        """answer.options[].picture: "where is thirty-four?" with blocks on the tiles; the label names the blocks' number;
        M-NUM-REV is the rods and cubes swapped, M-PV-FACE the digits taken as loose cubes (7)."""
        def tile(k, t, o, label, tag=None):
            return dict({'id': 'o%d' % k, 'picture': {'kind': 'base_ten', 'tens': t, 'ones': o}, 'label': label},
                        **({'misconception': tag} if tag else {}))
        good = c1_item('אֵיפֹה הַמִּסְפָּר שְׁלוֹשִׁים וְאַרְבַּע?', [], skill='NUM-C-03')
        good['answer']['options'] = [tile(1, 3, 4, 'שְׁלוֹשִׁים וְאַרְבַּע'), tile(2, 4, 3, 'אַרְבָּעִים וְשָׁלוֹשׁ', 'M-NUM-REV'),
                                     tile(3, 0, 7, 'שֶׁבַע', 'M-PV-FACE')]
        self.assertEqual(self.failing(good), [])
        moved = copy.deepcopy(good)
        moved['answer']['correct'] = 'o2'
        self.assertIn(('WRONG', 'answer'), codes(self.c1run(moved)))
        label = copy.deepcopy(good)
        label['answer']['options'][1]['label'] = 'שְׁלוֹשִׁים וְאַרְבַּע'
        self.assertIn(('WRONG', 'label'), codes(self.c1run(label)))
        face = copy.deepcopy(good)
        face['answer']['options'][2]['picture']['ones'] = 8
        face['answer']['options'][2]['label'] = 'שְׁמוֹנֶה'
        self.assertIn(('RULE', 'tag-rule'), codes(self.c1run(face)), '3 and 4 as ones are 7 cubes')
        lit = copy.deepcopy(good)
        lit['answer']['options'][1]['picture']['litRods'] = 1
        self.assertIn(('WRONG', 'picture'), codes(self.c1run(lit)))

    def test_the_middle_of_two_marks(self):
        """A row of two marks with the gap between: the middle (45); M-NL-SPACE is the mark next to an end."""
        good = c1_item('עַל הַצִּיר, אֵיזֶה מִסְפָּר נִמְצָא בְּדִיּוּק בָּאֶמְצַע?', [(45, None), (41, 'M-NL-SPACE'), (90, 'M-EQ-OPER')],
                       row=['n:40', '?', 'n:50'], skill='NUM-C-06')
        self.assertEqual(self.failing(good), [])
        far = copy.deepcopy(good)
        far['answer']['options'][1]['numeral'] = 43
        self.assertIn(('RULE', 'tag-rule'), codes(self.c1run(far)))
        moved = copy.deepcopy(good)
        moved['answer']['correct'] = 'o2'
        self.assertIn(('WRONG', 'answer'), codes(self.c1run(moved)))


def estimate_item(target, labels=(0, 100), tolerance=8, mirror='M-NL-DIR', step=10, mode='place'):
    """An X5 item (number_line 1.1): the frog goes about to `target` on the line 0 to 100 (ticks of `step`), right within `tolerance`."""
    import author  # noqa: E402
    answer = {'type': 'line', 'mode': mode, 'target': target, 'tolerance': tolerance, 'misconception': 'M-NL-SPACE'}
    if mirror:
        answer['mirrorMisconception'] = mirror
    return {'schema': 'activity/v1', 'id': 'plant.x5', 'template': 'number_line', 'templateVersion': '1.1', 'domain': 'numbers',
            'band': 'C', 'skills': [{'id': 'NUM-C-06', 'weight': 1}],
            'prompt': {'caption': [{'t': 'he', 'v': 'הַצְּפַרְדֵּעַ '
                                                   'רוֹצָה לַעֲמֹד '
                                                   'עַל %s.' % author.F[target]}]},
            'scene': {'from': 0, 'to': 100, 'tickStep': step, 'labels': list(labels)}, 'answer': answer}


def card_item(row, right, tags, skill='MATH-C-02'):
    """A true-or-false card: a whole sentence in the row, the tick and the cross on the tiles; `tags` is {'tick'|'cross': tag}."""
    options = [dict({'id': 'o%d' % (k + 1), 'sprite': 'asset:' + n},
                    **({'misconception': tags[n]} if n in tags else {})) for k, n in enumerate(('tick', 'cross'))]
    return {'schema': 'activity/v1', 'id': 'plant.card', 'template': 'tap_answer', 'domain': 'math', 'band': 'C',
            'skills': [{'id': skill, 'weight': 1}],
            'prompt': {'caption': [{'t': 'he', 'v': 'הַתַּרְגִּיל '
                                                   'נָכוֹן?'}]},
            'scene': {'row': row, 'optionsOnTiles': True},
            'answer': {'type': 'choice', 'correct': 'o1' if right else 'o2', 'options': options}}


class C1Last(BatchC1):
    """The last pieces of C1 (2026-11-07): the line 0 to 100 placed by estimate (X5) and the true-or-false card of M-SUB-ORDER."""
    TAGS = BatchC1.TAGS | {'M-NL-DIR', 'M-NL-SPACE'}

    def test_the_tolerance_line(self):
        """Right within the tolerance of the target; its mirror a place of its own; no written number in the right region."""
        good = estimate_item(70)
        self.assertEqual(self.failing(good), [])
        self.assertEqual(self.failing(estimate_item(23, labels=(0, 50, 100))), [])
        self.assertIn(('WRONG', 'picture'), codes(self.c1run(estimate_item(70, step=30))), '100 is no tick of 30')
        self.assertIn(('WRONG', 'answer'), codes(self.c1run(estimate_item(70, mode='jump'))), 'a jump has no tolerance')
        self.assertIn(('WRONG', 'answer'), codes(self.c1run(estimate_item(70, tolerance=100))), 'as wide as the line')
        self.assertIn(('RULE', 'tag-rule'), codes(self.c1run(estimate_item(45))), 'the mirror 55 is within 16 of 45')
        self.assertIn(('RULE', 'tag-rule'), codes(self.c1run(estimate_item(70, mirror='M-PV-FACE'))))
        self.assertIn(('AMBIG', 'labelled'), codes(self.c1run(estimate_item(46, labels=(0, 50, 100), mirror=None))), '50 is right')
        self.assertIn(('RULE', 'labelled'), codes(self.c1run(estimate_item(50, labels=(0, 50, 100), mirror=None))))
        self.assertEqual(self.failing(estimate_item(45, mirror=None)), [], 'no mirror tag: the mirror is simply right')
        wrong = estimate_item(70)
        wrong['answer']['target'] = 60
        self.assertIn(('WRONG', 'answer'), codes(self.c1run(wrong)), 'the caption asks for 70')

    def test_a_mirrored_estimate_is_lucky_right_inside_the_tolerance(self):
        docs = [estimate_item(70), dict(estimate_item(46, mirror=None), id='plant.x5b')]
        folder = tempfile.mkdtemp()
        try:
            cov = cm.coverage(folder, docs=docs, skills={'NUM-C-06': {'misconceptions': ['M-NL-DIR']}})
        finally:
            shutil.rmtree(folder)
        self.assertEqual(cov['NUM-C-06']['M-NL-DIR'], (['plant.x5'], ['plant.x5b']), 'the mirror of 46 is 54, within 8')

    def test_the_true_or_false_card(self):
        false = card_item(['n:6', 'op:-', 'n:15', 'op:=', 'n:9'], False, {'tick': 'M-SUB-ORDER'})
        true = card_item(['n:9', 'op:=', 'n:15', 'op:-', 'n:6'], True, {'cross': 'M-EQ-OPER'})
        both = card_item(['n:8', 'op:+', 'n:6', 'op:=', 'n:6', 'op:+', 'n:8'], True, {'cross': 'M-EQ-OPER'})
        for good in (false, true, both):
            self.assertEqual(self.failing(good), [], good['scene']['row'])
        moved = copy.deepcopy(false)
        moved['answer']['correct'] = 'o1'
        self.assertIn(('WRONG', 'answer'), codes(self.c1run(moved)), '6 - 15 = 9 is not true')
        self.assertIn(('RULE', 'tag-rule'), codes(self.c1run(card_item(['n:7', 'op:-', 'n:15', 'op:=', 'n:9'], False,
                                                                       {'tick': 'M-SUB-ORDER'}))), '15 - 7 is not 9 either')
        self.assertIn(('RULE', 'tag-rule'), codes(self.c1run(card_item(['n:15', 'op:-', 'n:6', 'op:=', 'n:9'], True,
                                                                       {'cross': 'M-EQ-OPER'}))), 'the answer is after =')
        self.assertIn(('RULE', 'tag-rule'), codes(self.c1run(card_item(['n:6', 'op:-', 'n:15', 'op:=', 'n:9'], False,
                                                                       {'tick': 'M-EQ-OPER'}))), 'M-EQ-OPER is a cross')

    def test_the_card_covers_sub_order_and_a_true_take_away_is_lucky_right(self):
        docs = [card_item(['n:6', 'op:-', 'n:15', 'op:=', 'n:9'], False, {'tick': 'M-SUB-ORDER'}),
                dict(card_item(['n:9', 'op:=', 'n:15', 'op:-', 'n:6'], True, {'cross': 'M-EQ-OPER'}), id='plant.card2')]
        folder = tempfile.mkdtemp()
        try:
            cov = cm.coverage(folder, docs=docs, skills={'MATH-C-02': {'misconceptions': ['M-SUB-ORDER']}})
        finally:
            shutil.rmtree(folder)
        self.assertEqual(cov['MATH-C-02']['M-SUB-ORDER'], (['plant.card'], ['plant.card2']))

    def test_after_a_number_inside_a_ten_is_lucky_right_for_the_decade(self):
        """After 34 no ten is crossed: the child who stumbles at the tens says 35 too; after 39 and after 40 are diagnostic."""
        import author  # noqa: E402
        docs = [dict(c1_item('מַה בָּא אַחֲרֵי %s?' % author.F[n], [(n + 1, None), (n + 2, 'M-CNT-SEQ')], skill='NUM-C-01'),
                     id='plant.after%d' % n) for n in (34, 39, 40)]
        folder = tempfile.mkdtemp()
        try:
            cov = cm.coverage(folder, docs=docs, skills={'NUM-C-01': {'misconceptions': ['M-CNT-DECADE']}})
        finally:
            shutil.rmtree(folder)
        self.assertEqual(cov['NUM-C-01']['M-CNT-DECADE'], ([], ['plant.after34']))

    def test_the_content_has_them(self):
        """The five estimates of NUM-C-06, the four cards of MATH-C-02 and the two ten-frames of NUM-B-09 are on disk and pass."""
        docs, records, skills = cm.load(cm.STARTER)
        by = {d['id']: d for d in docs}
        x5 = [i for i, d in by.items() if d['template'] == 'number_line' and d['answer'].get('tolerance')]
        cards = [i for i, d in by.items() if d.get('variantGroup') == 'true-or-false']
        frames = [i for i, d in by.items() if d['template'] == 'give_n' and d['scene'].get('frame')]
        self.assertEqual(sorted(x5), ['c.numc06.17', 'c.numc06.3', 'c.numc06.4', 'c.numc06.5', 'c.numc06.6'])
        self.assertEqual(sorted(cards), ['c.mathc02.16', 'c.mathc02.17', 'c.mathc02.18', 'c.mathc02.19'])
        self.assertEqual(sorted(frames), ['c.numb09.15', 'c.numb09.16'])
        self.assertTrue(all(by[i]['templateVersion'] == '1.1' for i in x5 + frames))
        f, _ = cm.check_docs([by[i] for i in x5 + cards + frames], records, skills, CATALOGUE, cm.Svg(cm.STARTER))
        self.assertEqual([r for r in f.rows if r[0] in cm.STRICT_FAILING], [])


def c1_waiting_docs():
    """The items of tools/band_c.py that wait for a mode (DRAWN), built in memory with every mode on, as tools/author.py would write
    them; nothing is written to content. Returns (documents of the waiting items only, ids whose picture the test carried, units)."""
    argv = sys.argv[:]
    import author  # noqa: E402
    import band_b  # noqa: E402  (it sets sys.argv for author.py, which is imported and never run)
    import band_c  # noqa: E402
    sys.argv = argv
    drawn, made = dict(band_c.DRAWN), list(band_b.MADE)
    units = {}
    try:
        for on in (False, True):
            band_c.DRAWN.update(dict.fromkeys(band_c.DRAWN, on))
            for batch, domain, build, unit in band_c.TABLES:
                if batch == 'C1':
                    own = dict(unit)
                    u = band_c.UnitC(batch, domain, own.pop('note', ''), **own)
                    build(u)
                    units.setdefault(on, []).append(u)
    finally:
        band_c.DRAWN.update(drawn)
        band_b.MADE[:] = made
    drawn_ids = {a['id'] for u in units[False] for a in u.d['activities']}
    # the shared lines of the tags, as the starter pack says them (author.py reads them from the unit specs)
    for d in cm.load(cm.STARTER)[0]:
        for fb in (d.get('feedback') or {}).get('incorrect', []):
            if fb.get('when', '').startswith('misconception:'):
                author.TAG_FEEDBACK.setdefault(fb['when'][len('misconception:'):], (fb['vo'], fb['caption'][0]['v']))
    for u in units[True]:
        for t, line in u.d['tagFeedback'].items():
            author.TAG_FEEDBACK.setdefault(t, ('vo:fb.' + t[2:].lower().replace('-', '_'), line))
    docs, carried = [], []
    for u in units[True]:
        ctx = {'objects': u.d['objects'], 'names': u.d['names']}
        for a in u.d['activities']:
            if a['id'] in drawn_ids:
                continue
            a = dict(a, domain=u.d['domain'], band=a.get('band', 'C'))
            doc = author.KINDS[a['kind']](a, ctx)
            if 'picture' in a and 'picture' not in doc['scene']:
                carried.append(a['id'])  # a picture the generator dropped (none since step 3: author.k_pick carries it)
            docs.append(doc)
    return docs, carried, units[True]


class C1Deferred(unittest.TestCase):
    """QA-C1-5: the items of docs/knowledge/maths/c1-deferred.md, written in tools/band_c.py behind DRAWN. Since step 3 (2026-11-07)
    every mode is drawn: each waiting item is in content, as the generator writes it, and passes the gate (check_maths --strict)."""

    @classmethod
    def setUpClass(cls):
        cls.docs, cls.carried, cls.units = c1_waiting_docs()

    def test_every_mode_is_drawn(self):
        import band_c  # noqa: E402
        self.assertEqual({m for m, on in band_c.DRAWN.items() if not on}, set())

    def test_every_waiting_item_is_in_content_as_written(self):
        missing, changed = [], []
        for d in self.docs:
            path = os.path.join(cm.STARTER, 'activity.%s.json' % d['id'])
            if not os.path.exists(path):
                missing.append(d['id'])
                continue
            with open(path, encoding='utf-8') as fh:
                disk = json.load(fh)
            for k in ('template', 'skills', 'scene', 'answer', 'checkType', 'representation', 'variantGroup'):
                if disk.get(k) != d.get(k):
                    changed.append((d['id'], k))
        self.assertEqual(missing, [])
        self.assertEqual(changed, [], 'regenerate the content: python -I tools/regen_content.py')
        self.assertEqual(self.carried, [], 'the generator carries every stage picture into the scene')

    def test_the_waiting_items_on_disk_pass_the_gate(self):
        docs, records, skills = cm.load(cm.STARTER)
        ids = {d['id'] for d in self.docs}
        on_disk = [d for d in docs if d['id'] in ids]
        self.assertEqual(len(on_disk), len(ids))
        f, counts = cm.check_docs(on_disk, records, skills, CATALOGUE, cm.Svg(cm.STARTER))
        self.assertEqual([r for r in f.rows if r[0] in cm.STRICT_FAILING], [])
        self.assertEqual(counts['checked'], len(on_disk))

    def test_every_mode_has_its_items(self):
        kinds = {(d['scene'].get('picture') or {}).get('kind') or d['answer']['type'] for d in self.docs}
        self.assertLessEqual({'base_ten', 'hundred_chart', 'number'}, kinds)
        fields = {k for d in self.docs for k in (d['scene'].get('picture') or {}) if k in ('litRods', 'crossedRods')}
        self.assertEqual(fields, {'litRods', 'crossedRods'})
        self.assertTrue(any('picture2' in d['scene'] for d in self.docs))
        self.assertTrue(any('picture' in o for d in self.docs for o in d['answer'].get('options', [])))
        self.assertGreaterEqual(len(self.docs), 20)

    def test_the_waiting_items_pass_the_gate(self):
        _, records, skills = cm.load(cm.STARTER)
        records |= {t['id'] for u in self.units for t in u.d['misconceptions']}
        f, counts = cm.check_docs(self.docs, records, skills, CATALOGUE, cm.Svg(cm.STARTER))
        self.assertEqual([r for r in f.rows if r[0] in cm.STRICT_FAILING], [])
        self.assertEqual(counts['checked'], len(self.docs))

    def test_switching_a_mode_on_renumbers_no_drawn_item(self):
        on = {a['id']: a for u in self.units for a in u.d['activities']}
        for p in os.listdir(cm.STARTER):
            if p.startswith('activity.c.'):
                with open(os.path.join(cm.STARTER, p), encoding='utf-8') as fh:
                    doc = json.load(fh)
                self.assertIn(doc['id'], on)
                self.assertEqual(on[doc['id']]['skill'], doc['skills'][0]['id'], doc['id'])


def basket_item(hidden=7, seen=2, drawn=None, options=None, skill='MATH-B-04'):
    """The closed-basket item of MATH-B-04 (QA-C1b-5): `hidden` said and not drawn, `seen` added and drawn."""
    d = c1_item('בַּסַּל הַסָּגוּר יֵשׁ שִׁבְעָה תַּפּוּחִים. מוֹסִיפִים לַסַּל עוֹד שְׁנֵי תַּפּוּחִים. כַּמָּה תַּפּוּחִים יֵשׁ בַּסַּל עַכְשָׁו?',
                options or [(hidden + seen, None), (seen, 'M-ADD-RECOUNT'), (hidden, 'M-CNT-CARD'), (hidden + seen + 1, 'M-CNT-DOUBLE')],
                skill=skill, scene={'group': {'sprite': 'asset:apple', 'count': seen if drawn is None else drawn}})
    d.update(domain='math', band='B')
    return d


class Recount(BatchC1):
    """QA-C1b-5: M-ADD-RECOUNT is recorded by the closed-basket item, and the coverage gate (--coverage --strict)."""
    TAGS = BatchC1.TAGS | {'M-ADD-RECOUNT'}

    def test_the_closed_basket(self):
        self.assertEqual(self.failing(basket_item()), [])
        self.assertIn(('WRONG', 'picture'), codes(self.c1run(basket_item(drawn=9))), 'the basket is closed: only the 2 are drawn')
        self.assertIn(('WRONG', 'answer'), codes(self.c1run(basket_item(options=[(2, None), (9, 'M-ADD-RECOUNT'), (7, 'M-CNT-CARD')]))))
        wrong = basket_item(options=[(9, None), (1, 'M-ADD-RECOUNT'), (7, 'M-CNT-CARD'), (10, 'M-CNT-DOUBLE')])
        self.assertIn(('RULE', 'tag-rule'), codes(self.c1run(wrong)), 'counting the drawn ones alone gives 2, not 1')

    def test_recount_shows_only_where_a_part_is_hidden(self):
        """Every number drawn: counting all from one gives the right sum, so a distractor tagged M-ADD-RECOUNT is a tag-rule error."""
        plain = copy.deepcopy(SUM)
        plain['answer']['options'][1]['misconception'] = 'M-ADD-RECOUNT'
        self.assertIn(('RULE', 'tag-rule'), codes(self.c1run(plain)))
        self.assertEqual(cm.tag_candidates('M-ADD-RECOUNT', {'x': 9, 'seen': 2}), {2})
        self.assertEqual(cm.tag_candidates('M-ADD-RECOUNT', {'x': 9}), set())

    def test_every_sum_is_lucky_right_for_recount(self):
        docs = [basket_item()]
        folder = tempfile.mkdtemp()
        try:
            cov = cm.coverage(folder, docs=docs, skills={'MATH-B-04': {'misconceptions': ['M-ADD-RECOUNT']}})
        finally:
            shutil.rmtree(folder)
        self.assertEqual(cov['MATH-B-04']['M-ADD-RECOUNT'], (['plant.c1'], ['plant.c1']), 'the fingers reach 9 too')

    def test_a_classifier_or_a_number_rule_records_its_tag(self):
        give = {'id': 'plant.give', 'template': 'give_n', 'skills': [{'id': 'NUM-B-05'}],
                'answer': {'type': 'give', 'n': 13, 'classifiers': [{'when': 'took_all', 'misconception': 'M-CNT-CARD'}]}}
        keypad = number_doc('?', 34, [(43, 'M-NUM-REV')], rules=[('face_value', 'M-PV-FACE')])
        self.assertEqual(cm.item_tags(cm.Item(give)), {'M-CNT-CARD'})
        self.assertEqual(cm.item_tags(cm.Item(keypad)), {'M-NUM-REV', 'M-PV-FACE'})

    def gate_folder(self, docs, skills):
        folder = tempfile.mkdtemp()
        for d in docs:
            with open(os.path.join(folder, 'activity.%s.json' % d['id']), 'w', encoding='utf-8') as fh:
                json.dump(d, fh, ensure_ascii=False)
        for sk, watch in skills.items():
            with open(os.path.join(folder, 'skill.%s.json' % sk), 'w', encoding='utf-8') as fh:
                json.dump({'id': sk, 'misconceptions': watch}, fh)
        for t in sorted(self.TAGS):
            with open(os.path.join(folder, 'misconception.%s.json' % t), 'w', encoding='utf-8') as fh:
                json.dump({'id': t}, fh)
        return folder

    def test_the_coverage_gate_fails_on_a_tag_with_no_diagnostic_item(self):
        good = basket_item()
        good['id'] = 'c.mathb04.1'
        plain = basket_item(options=[(9, None), (7, 'M-CNT-CARD'), (10, 'M-CNT-DOUBLE')])
        plain['id'] = 'c.mathb04.1'
        for docs, want in (([good], 0), ([plain], 1)):
            folder = self.gate_folder(docs, {'MATH-B-04': ['M-ADD-RECOUNT']})
            try:
                with contextlib.redirect_stdout(io.StringIO()):
                    self.assertEqual(cm.main(['--dir', folder, '--ids', 'c.', '--strict']), 0, 'the finding gate alone passes')
                    self.assertEqual(cm.main(['--dir', folder, '--ids', 'c.', '--coverage']), 0, 'the table alone never fails')
                    self.assertEqual(cm.main(['--dir', folder, '--ids', 'c.', '--coverage', '--strict']), want)
            finally:
                shutil.rmtree(folder)

    def test_the_gate_takes_an_item_elsewhere_or_a_reasoned_exemption(self):
        plain = basket_item(options=[(9, None), (7, 'M-CNT-CARD'), (10, 'M-CNT-DOUBLE')])
        plain['id'] = 'c.mathb04.1'
        elsewhere = basket_item()
        elsewhere['id'] = 'b.mathb04.1'
        folder = self.gate_folder([plain, elsewhere], {'MATH-B-04': ['M-ADD-RECOUNT']})
        try:
            cov = cm.coverage(folder, ids=['c.'])
            self.assertEqual(cov['MATH-B-04']['M-ADD-RECOUNT'][0], [])
            self.assertEqual([g[2] for g in cm.coverage_gate(cov, folder)], ['elsewhere'], 'a Band B item of the skill records it')
            os.remove(os.path.join(folder, 'activity.b.mathb04.1.json'))
            self.assertEqual([g[2] for g in cm.coverage_gate(cov, folder)], ['missing'])
            gate = cm.coverage_gate(cov, folder, exempt={('MATH-B-04', 'M-ADD-RECOUNT'): 'seen in the taps only'})
            self.assertEqual(gate, [('MATH-B-04', 'M-ADD-RECOUNT', 'exempt', 'seen in the taps only')])
        finally:
            shutil.rmtree(folder)

    def test_the_content_has_them_and_passes_the_gate(self):
        docs, records, skills = cm.load(cm.STARTER)
        by = {d['id']: d for d in docs}
        for i, (seen, hidden) in (('c.mathb04.11', (2, 7)), ('c.mathb04.12', (3, 8))):
            tags = {o['numeral']: o.get('misconception') for o in by[i]['answer']['options']}
            self.assertEqual((tags[seen], tags[hidden]), ('M-ADD-RECOUNT', 'M-CNT-CARD'))
            self.assertEqual(by[i]['scene']['group']['count'], seen)
        self.assertEqual(cm.NOT_ITEM_OBSERVABLE, {}, 'every watched tag of C1 has an item now')
        cov = cm.coverage(ids=['c.'])
        self.assertEqual([g for g in cm.coverage_gate(cov) if g[2] == 'missing'], [])


class RealPack(unittest.TestCase):
    def test_every_maths_item_is_read_by_a_rule(self):
        rows, counts = cm.check()
        self.assertGreater(counts['items'], 0)
        self.assertEqual([r for r in rows if r[0] == 'UNCHECKED'], [])
        self.assertEqual([r for r in rows if r[2] == 'ltr' and r[0] == 'WRONG'], [])

    def test_a_moved_answer_is_always_found(self):
        """Move the marked answer of every choice item to each distractor: the checker must say WRONG every time."""
        docs, records, skills = cm.load(cm.STARTER)
        svg = cm.Svg(cm.STARTER)
        already = {r[1] for r in cm.check()[0] if r[2] == 'second-right'}
        missed = []
        for d in docs:
            a = d.get('answer') or {}
            if d.get('domain') not in cm.MATHS_DOMAINS or not a.get('options') or d['id'] in already:
                continue
            for o in a['options']:
                if o['id'] == a.get('correct'):
                    continue
                m = copy.deepcopy(d)
                m['answer']['correct'] = o['id']
                f, _ = cm.check_docs([m], records, skills, CATALOGUE, svg)
                if not any(r[0] == 'WRONG' and r[2] == 'answer' for r in f.rows):
                    missed.append((d['id'], o['id']))
        self.assertEqual(missed, [])


if __name__ == '__main__':
    unittest.main()
