"""The content generators of board B-15 part 1 (tools/author.py, tools/band_b*.py) and the starter pack they write.

    python tools/test_generators.py

* G1: an item's own `check` and `rep` win over its kind's; a spot is an error-spotting check;
* G2: the representation follows the label rule of the B-15 spec §2, and each skill lists what its activities use;
* G3: every kind takes `weights` and `also`;
* G4 and A5: an item's own tag line, and the M-SORT-SHIFT line by sorting rule (the editor's P3 and P4 for a kind or shape
  rule in both bands; the shared line for a colour rule or none);
* G5: MATH-B-10 draws one chart column per plate;
* B-15 part 2: the pieces of the generators that the new items use (a count's own prompt, the give target, the second
  hint's action, the tick's hint, the H30 sentence with its prefixes);
* the starter pack: every activity follows the label rule, every skill file lists its activities' representations, and
  every activity is in the band of its first skill (the validator rule of B-15).
"""
import glob
import json
import os
import sys
import unittest

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(TOOLS, '..'))
STARTER = os.path.join(ROOT, 'content', 'starter')
sys.path.insert(0, TOOLS)
_argv = sys.argv[:]
import author  # noqa: E402
import band_b  # noqa: E402  (it sets sys.argv for author.py, which is imported and never run)
import band_c  # noqa: E402
sys.argv = _argv


def load(pattern):
    return [json.load(open(f, encoding='utf-8')) for f in sorted(glob.glob(os.path.join(STARTER, pattern)))]


NAMES = {'ball_red': {'one': 'כַּדּוּר אָדֹם', 'g': 'm'}, 'ball_blue': {'one': 'כַּדּוּר כָּחֹל', 'g': 'm'},
         'bloom_red': {'one': 'פֶּרַח אָדֹם', 'g': 'm'}}
# the shared line comes from a unit spec when author.py runs; the tests give it the colours unit's text
SHARED_SORT_SHIFT = author.TAG_FEEDBACK.setdefault('M-SORT-SHIFT', ('vo:fb.sort_shift', 'מְחַפְּשִׂים אֶת אוֹתוֹ צֶבַע, לֹא אוֹתוֹ דָּבָר.'))
CTX = {'names': NAMES, 'objects': {'apple': {'g': 'm', 'one': 'תַּפּוּחַ', 'many': 'תַּפּוּחִים'}}}


def pick(**kw):
    a = {'kind': 'pick', 'id': 't.pick', 'skill': 'COL-A-01', 'band': 'A', 'prompt': 'אֵיפֹה אוֹתוֹ צֶבַע?',
         'options': ['ball_red', 'bloom_red'], 'correct': 'bloom_red', 'tags': {'ball_red': 'M-SORT-SHIFT'}}
    a.update(kw)
    return author.k_pick(a, CTX)


def spot(**kw):
    a = {'kind': 'spot', 'id': 't.spot', 'skill': 'NUM-B-11', 'cells': ['n:1', 'n:2', 'n:4'], 'wrong': 2,
         'tag': 'M-CNT-SEQ', 'prompt': 'אֵיפֹה הַטָּעוּת?'}
    a.update(kw)
    return author.k_spot(a, CTX)


class LabelRuleTest(unittest.TestCase):
    def test_hands_on_templates_are_concrete(self):
        for t in ('count_tap', 'give_n', 'sort_drag', 'build_pattern', 'shape_builder', 'shop_pay', 'clock_set'):
            self.assertEqual(author.representation(t, {}, {}), 'concrete', t)

    def test_diagrams_are_pictorial_and_tracing_embodied(self):
        for t in ('number_line', 'match_pairs', 'flash'):
            self.assertEqual(author.representation(t, {}, {}), 'pictorial', t)
        self.assertEqual(author.representation('trace', {}, {}), 'embodied')

    def test_balance_and_robot_by_mode(self):
        self.assertEqual(author.representation('balance', {}, {'mode': 'balance'}), 'concrete')
        self.assertEqual(author.representation('balance', {}, {'mode': 'compare'}), 'pictorial')
        self.assertEqual(author.representation('robot_path', {}, {'mode': 'direct'}), 'concrete')
        self.assertEqual(author.representation('robot_path', {}, {'mode': 'plan'}), 'symbolic')

    def test_spots_by_cells(self):
        self.assertEqual(author.representation('spot_error', {'cells': ['n:1', 'op:+']}, {}), 'symbolic')
        self.assertEqual(author.representation('spot_error', {'cells': ['dir:up', 'dir:up']}, {}), 'symbolic')
        self.assertEqual(author.representation('spot_error', {'cells': ['asset:cat', 'asset:dog']}, {}), 'pictorial')

    def test_taps_are_pictorial_when_anything_is_drawn(self):
        numerals = {'options': [{'id': 'o1', 'numeral': 3}]}
        self.assertEqual(author.representation('tap_answer', {'row': ['n:3', 'op:+', '?']}, numerals), 'symbolic')
        for scene in ({'group': {}}, {'group2': {}}, {'chart': []}, {'row': ['asset:cat', '?']}):
            self.assertEqual(author.representation('tap_answer', scene, numerals), 'pictorial', scene)
        self.assertEqual(author.representation('tap_answer', {}, {'options': [{'id': 'o1', 'sprite': 'asset:cat'}]}),
                         'pictorial')


class ItemOverridesTest(unittest.TestCase):
    def test_a_spot_is_an_error_spotting_check(self):
        self.assertEqual(spot()['checkType'], 'error_spotting')

    def test_a_band_a_spot_never_says_not_in_its_third_hint(self):
        # P1 (owner-approved 2026-10-30): Band A says what is true; Band B keeps "one of them does not fit"; an own h3 wins
        h3 = lambda d: (d['hints'][2]['vo'], d['hints'][2]['caption'][0]['v'])
        self.assertEqual(h3(spot(band='A')), ('vo:hint.spot_but_one.h3', author.SPOT_H3_A))
        self.assertEqual(h3(spot()), ('vo:hint.spot_but_one.h3', author.SPOT_H3_A))
        self.assertEqual(h3(spot(band='B', id='t.spot.b')), ('vo:t.spot.b.h3', author.SPOT_H3_B))
        self.assertEqual(h3(spot(h3='נִסְפֹּר יַחַד.', id='t.spot.own')), ('vo:t.spot.own.h3', 'נִסְפֹּר יַחַד.'))
        self.assertNotIn('לֹא', author.SPOT_H3_A)

    def test_the_items_check_and_rep_win(self):
        d = pick(check='reverse', rep='story')
        self.assertEqual((d['checkType'], d['representation']), ('reverse', 'story'))
        d = pick()
        self.assertEqual((d['checkType'], d['representation']), ('practice', 'pictorial'))

    def test_weights_and_also(self):
        self.assertEqual(spot(also=['NUM-B-10'])['skills'],
                         [{'id': 'NUM-B-11', 'weight': 1}, {'id': 'NUM-B-10', 'weight': 0.5}])
        self.assertEqual(spot(weights={'NUM-A-01': 1, 'NUM-A-03': 0.5})['skills'],
                         [{'id': 'NUM-A-01', 'weight': 1}, {'id': 'NUM-A-03', 'weight': 0.5}])

    def test_an_items_own_tag_line(self):
        line = ('vo:fb.part_miss.sentence', 'שׁוּרַת בְּדִיקָה.')
        d = pick(tag_lines={'M-SORT-SHIFT': line})
        self.assertEqual(d['feedback']['incorrect'][0]['vo'], line[0])


class SortShiftLineTest(unittest.TestCase):
    shared = SHARED_SORT_SHIFT

    def test_a_colour_rule_or_none_keeps_the_shared_line(self):
        for rule in ('colour', None):
            self.assertEqual(author.tag_line('M-SORT-SHIFT', rule=rule), self.shared)

    def test_a_shape_or_kind_rule_takes_the_editors_line_in_either_band(self):
        self.assertEqual(author.tag_line('M-SORT-SHIFT', rule='shape'),
                         ('vo:fb.sort_shift.shape', 'זֶה אוֹתוֹ צֶבַע, אֲבָל מְחַפְּשִׂים אֶת אוֹתָהּ הַצּוּרָה. בּוֹאוּ נִבְדֹּק.'))
        self.assertEqual(author.tag_line('M-SORT-SHIFT', rule='kind'),
                         ('vo:fb.sort_shift.kind', 'זֶה אוֹתוֹ צֶבַע, אֲבָל מְחַפְּשִׂים אֶת אוֹתוֹ הַדָּבָר. בּוֹאוּ נִבְדֹּק.'))
        for band in ('A', 'B'):
            d = pick(band=band, rule='shape')
            self.assertEqual(d['feedback']['incorrect'][0]['vo'], 'vo:fb.sort_shift.shape')

    def test_an_unknown_rule_is_refused(self):
        with self.assertRaises(AssertionError):
            pick(rule='weight')

    def test_a_size_rule_takes_the_editors_size_line(self):
        self.assertEqual(author.tag_line('M-SORT-SHIFT', rule='size')[0], 'vo:fb.sort_shift.size')
        self.assertEqual(pick(band='A', rule='size')['feedback']['incorrect'][0]['vo'], 'vo:fb.sort_shift.size')


class PartTwoPiecesTest(unittest.TestCase):
    def test_a_count_takes_its_own_prompt(self):
        a = {'kind': 'count_tap', 'id': 't.count', 'skill': 'MATH-B-01', 'obj': 'apple', 'count': 5, 'options': [4, 5, 6],
             'prompt': 'מוֹסִיפִים.'}
        d = author.k_count_tap(a, CTX)
        self.assertEqual(d['prompt']['caption'][0]['v'], 'מוֹסִיפִים.')
        del a['prompt']
        a['id'] = 't.count2'
        self.assertIn('נוֹגְעִים בְּכׇל אֶחָד', author.k_count_tap(a, CTX)['prompt']['caption'][0]['v'])

    def test_a_give_takes_its_own_target(self):
        a = {'kind': 'give', 'id': 't.give', 'skill': 'NUM-A-06', 'obj': 'apple', 'n': 3, 'source': 7, 'target': 'bowl_empty'}
        self.assertEqual(author.k_give(a, CTX)['scene']['target']['sprite'], 'asset:bowl_empty')
        del a['target']
        a['id'] = 't.give2'
        self.assertEqual(author.k_give(a, CTX)['scene']['target']['sprite'], 'asset:basket_target')

    def test_the_second_hint_may_change_what_it_does(self):
        self.assertEqual(pick()['hints'][1]['action'], 'highlight_objects_sequentially')
        d = pick(h2='עֶשֶׂר אֶצְבָּעוֹת.', h2_action='show_fingers')
        self.assertEqual((d['hints'][1]['action'], d['hints'][1]['caption'][0]['v']), ('show_fingers', 'עֶשֶׂר אֶצְבָּעוֹת.'))

    def test_the_hint_of_a_tick_says_to_press_the_tick(self):
        names = dict(NAMES, tick={'one': 'כֵּן', 'g': 'm'}, cross={'one': 'לֹא', 'g': 'm'})
        a = {'kind': 'pick', 'id': 't.tick', 'skill': 'COL-A-05', 'prompt': 'זוֹ בָּנָנָה?', 'options': ['cross', 'tick'],
             'correct': 'tick', 'tags': {'cross': 'M-SORT-SHIFT'}}
        d = author.k_pick(a, {'names': names, 'objects': {}})
        self.assertTrue(d['hints'][2]['caption'][0]['v'].endswith('לִלְחֹץ עַל הַוִּי.'))

    def test_a_numeral_to_set_takes_the_tags_of_its_item(self):
        a = {'kind': 'numeral_to_set', 'id': 't.show', 'skill': 'NUM-A-08', 'obj': 'apple', 'n': 3, 'options': [3, 2, 1],
             'tags': {'1': 'M-CNT-SKIP'}}
        d = author.k_numeral_to_set(a, CTX)
        self.assertEqual([o.get('misconception') for o in d['answer']['options']], [None, 'M-CNT-SKIP', 'M-CNT-SKIP'])

    def test_the_sentence_of_h30_points_its_prefixes_by_the_number(self):
        line = band_b.part_miss_line(3, 7)['M-PART-MISS']
        self.assertEqual(line[1], 'חִבַּרְנוּ אֶת שְׁנֵיהֶם, אֲבָל שֶׁבַע זֶה כְּבָר הַכֹּל. כַּמָּה מוֹסִיפִים לְשָׁלוֹשׁ כְּדֵי לְהַגִּיעַ לְשֶׁבַע?')
        self.assertIn('לְחָמֵשׁ כְּדֵי לְהַגִּיעַ לְתֵשַׁע', band_b.part_miss_line(5, 9)['M-PART-MISS'][1])
        self.assertIn('לִשְׁתַּיִם', band_b.part_miss_line(2, 6)['M-PART-MISS'][1])
        self.assertIn('לַחֲמֵשׁ עֶשְׂרֵה', band_b.part_miss_line(15, 17)['M-PART-MISS'][1])
        self.assertIn('לִשְׁלֹשׁ עֶשְׂרֵה', band_b.part_miss_line(8, 13)['M-PART-MISS'][1])

    def test_the_basket_sentence_says_the_noun_twice_and_points_the_vav(self):
        a = band_b.OBJECTS['apple']
        said = 'יֵשׁ %s בַּסַּל, %s בַּחוּץ.' % (author.qty(4, a), author.vav(author.qty(2, a)))
        self.assertEqual(said, 'יֵשׁ אַרְבָּעָה תַּפּוּחִים בַּסַּל, וּשְׁנֵי תַּפּוּחִים בַּחוּץ.')


class StarterPackTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.acts = load('activity.*.json')
        cls.skills = {s['id']: s for s in load('skill.*.json')}

    def test_every_activity_follows_the_label_rule(self):
        bad = []
        for a in self.acts:
            if a['representation'] == 'story' or a['skills'][0]['id'] == 'MATH-B-14':
                continue  # the two exceptions of §2: authored stories, and the day cards that are symbols
            want = author.representation(a['template'], a['scene'], a['answer'])
            if a['representation'] != want:
                bad.append('%s: %s, the rule says %s' % (a['id'], a['representation'], want))
        self.assertEqual(bad, [])

    def test_every_skill_lists_the_representations_its_activities_use(self):
        used = {}
        for a in self.acts:
            used.setdefault(a['skills'][0]['id'], set()).add(a['representation'])
        bad = ['%s: %s, uses %s' % (k, s['representations'], sorted(used[k]))
               for k, s in self.skills.items() if k in used and set(s['representations']) != used[k]]
        self.assertEqual(bad, [])

    def test_every_activity_is_in_the_band_of_its_first_skill(self):
        bad = [a['id'] for a in self.acts if a['band'] != self.skills[a['skills'][0]['id']]['band']]
        self.assertEqual(bad, [])

    def test_spots_are_error_spotting_and_give_n_is_practice_in_its_own_skills(self):
        for a in self.acts:
            if a['template'] == 'spot_error':
                self.assertEqual(a['checkType'], 'error_spotting', a['id'])
            if a['template'] == 'give_n' and a['skills'][0]['id'] in ('NUM-A-06', 'NUM-B-05', 'MATH-A-06'):
                # giving N is the skill's own task, not its reverse: practice, or the transfer of the new items
                self.assertIn(a['checkType'], ('practice', 'transfer'), a['id'])

    def test_math_b_10_draws_one_column_per_plate(self):
        for a in self.acts:
            if a['skills'][0]['id'] == 'MATH-B-10':
                chart = a['scene']['chart']
                self.assertEqual(len({c['count'] for c in chart}), 1, a['id'])
                right = next(o['numeral'] for o in a['answer']['options'] if o['id'] == a['answer']['correct'])
                # how many in all (the sum of the columns) or, the other way round, how many plates (the columns)
                self.assertEqual(len(chart) if a['checkType'] == 'reverse' else sum(c['count'] for c in chart), right, a['id'])
                self.assertEqual(a['templateVersion'], '1.2')

    def test_a_sorting_rule_line_is_one_of_the_rule_lines(self):
        for a in self.acts:
            for f in a['feedback']['incorrect']:
                if f['when'] == 'misconception:M-SORT-SHIFT' and f['vo'] != 'vo:fb.sort_shift':
                    self.assertIn(f['vo'], ('vo:fb.sort_shift.shape', 'vo:fb.sort_shift.kind', 'vo:fb.sort_shift.size'), a['id'])

    def test_a_tagged_option_is_never_the_right_one(self):
        for a in self.acts:
            for o in a['answer'].get('options', []) if a['answer'].get('type') == 'choice' else []:
                if o['id'] == a['answer']['correct']:
                    self.assertNotIn('misconception', o, a['id'])


SCHEMAS = os.path.join(ROOT, 'content', 'schemas')


def schema_props(name, *path):
    """The property names a JSON schema file allows at [path] (it is generated from the app's own schemas)."""
    node = json.load(open(os.path.join(SCHEMAS, name), encoding='utf-8'))
    for key in path:
        node = node['properties'][key]
    return node['properties']


class BandCTest(unittest.TestCase):
    """M10 step 0.4: the Band C generator skeleton, the number-entry kind and the template version rule (the app's validator makes an
    item say the same version)."""

    def number(self, **kw):
        a = {'kind': 'number', 'id': 'c.numc01.1', 'skill': 'NUM-C-02', 'band': 'C', 'prompt': 'q', 'row': band_c.tokens(52, '-', 27, '=', '?'),
             'value': 25, 'expected': {35: 'M-SUB-SMALLBIG', 29: 'M-REGROUP-FORGET'}, 'rules': {'smaller_from_larger': 'M-SUB-SMALLBIG'},
             'h2': 'two', 'h3': 'three', 'correct_text': 'right'}
        a.update(kw)
        for tag in ('M-SUB-SMALLBIG', 'M-REGROUP-FORGET'):
            author.TAG_FEEDBACK.setdefault(tag, ('vo:fb.' + tag[2:].lower().replace('-', '_'), 'line for ' + tag))
        return author.k_number(a, {'names': {}, 'objects': {}})

    def test_the_bubble_shows_the_sentence_a_question_says_over_blocks(self):
        """prompt.math (owner, 2026-11-07): the four items of MATH-C-03 that say a sentence over rods ('אַרְבָּעִים וְעוֹד שְׁלוֹשִׁים') carry
        it as the tokens of a row; the generator refuses a run beside a row (the row already shows it)."""
        runs = {d['id']: d['prompt'].get('math') for d in load('activity.c.mathc03.1[5-8].json')}
        self.assertEqual(runs, {
            'c.mathc03.15': ['n:40', 'op:+', 'n:30', 'op:=', '?'], 'c.mathc03.16': ['n:30', 'op:+', 'n:50', 'op:=', '?'],
            'c.mathc03.17': ['n:70', 'op:-', 'n:40', 'op:=', '?'], 'c.mathc03.18': ['n:60', 'op:-', 'n:20', 'op:=', '?']})
        self.assertEqual({d['templateVersion'] for d in load('activity.c.mathc03.1[5-8].json')}, {'1.4'})
        # no other item has one (the field is for a sentence said and not drawn in a row)
        with_run = [d['id'] for d in load('activity.*.json') if 'math' in d['prompt']]
        self.assertEqual(sorted(with_run), sorted(runs))
        a = {'kind': 'pick', 'id': 'c.mathc03.99', 'skill': 'MATH-C-03', 'band': 'C', 'prompt': 'q', 'options': ['n:7', 'n:8'],
             'correct': 'n:7', 'row': band_c.tokens(3, '+', 4, '=', '?'), 'math': band_c.tokens(3, '+', 4, '=', '?')}
        with self.assertRaises(AssertionError):
            author.k_pick(a, {'names': {}, 'objects': {}})

    def test_tokens_are_numbers_signs_and_the_gap(self):
        self.assertEqual(band_c.tokens(52, '-', 27, '=', '?'), ['n:52', 'op:-', 'n:27', 'op:=', '?'])
        self.assertEqual(band_c.tokens('(', 2, '+', 3, ')', 'x', 4), ['op:(', 'n:2', 'op:+', 'n:3', 'op:)', 'op:x', 'n:4'])
        self.assertEqual(band_c.tokens(10000, ':', 4), ['n:10000', 'op::', 'n:4'])
        with self.assertRaises(AssertionError):
            band_c.tokens(10001)
        with self.assertRaises(AssertionError):
            band_c.tokens(-1)
        with self.assertRaises(AssertionError):
            band_c.tokens(1, '%', 2)
        with self.assertRaises(AssertionError):
            band_c.tokens(True)

    def test_a_number_item_is_a_tap_answer_1_4_with_a_number_answer(self):
        d = self.number()
        self.assertEqual((d['template'], d['templateVersion']), ('tap_answer', '1.4'))
        self.assertEqual(d['answer'], {
            'type': 'number', 'value': 25,
            'expected': [{'value': 29, 'misconception': 'M-REGROUP-FORGET'}, {'value': 35, 'misconception': 'M-SUB-SMALLBIG'}],
            'rules': [{'when': 'smaller_from_larger', 'misconception': 'M-SUB-SMALLBIG'}]})
        self.assertEqual(d['scene']['row'], ['n:52', 'op:-', 'n:27', 'op:=', '?'])
        self.assertFalse(d['voiceAnswer'], 'a number above 20 is not a spoken answer yet (M10 section 11)')
        self.assertEqual(d['representation'], 'symbolic')
        self.assertEqual([f['when'] for f in d['feedback']['incorrect']],
                         ['misconception:M-REGROUP-FORGET', 'misconception:M-SUB-SMALLBIG', 'default'])
        self.assertEqual([h['level'] for h in d['hints']], [1, 2, 3])
        self.assertNotEqual(d['hints'][1]['action'], d['hints'][0]['action'])

    def test_a_stage_picture_makes_it_pictorial(self):
        d = self.number(picture={'kind': 'array', 'rows': 3, 'columns': 4})
        self.assertEqual(d['scene']['picture'], {'kind': 'array', 'rows': 3, 'columns': 4})
        self.assertEqual(d['representation'], 'pictorial')

    def test_what_a_number_item_must_say_and_may_not(self):
        for missing in ('value', 'prompt', 'correct_text', 'h2', 'h3'):
            with self.assertRaises(AssertionError, msg=missing):
                self.number(**{missing: None})
        with self.assertRaises(AssertionError):
            self.number(value=10001)
        with self.assertRaises(AssertionError):
            self.number(expected={25: 'M-SUB-SMALLBIG'})  # the right answer is not a wrong one
        with self.assertRaises(AssertionError):
            self.number(rules={'guessed': 'M-SUB-SMALLBIG'})

    def test_the_item_only_uses_what_the_schema_allows(self):
        d = self.number(picture={'kind': 'clock', 'hour': 2, 'minute': 30})
        self.assertLessEqual(set(d['answer']), set(schema_props('activity.tap_answer.schema.json', 'answer')))
        self.assertLessEqual(set(d['scene']), set(schema_props('activity.tap_answer.schema.json', 'scene')))
        self.assertIn(d['answer']['type'], schema_props('activity.tap_answer.schema.json', 'answer')['type']['enum'])
        self.assertEqual(set(author.NUMBER_RULES),
                         set(schema_props('activity.tap_answer.schema.json', 'answer')['rules']['items']['properties']['when']['enum']))
        self.assertEqual(author.NUMBER_MAX, schema_props('activity.tap_answer.schema.json', 'answer')['value']['maximum'])

    def test_the_template_version_follows_what_an_item_uses(self):
        tv = author.template_version
        plain = {'type': 'choice', 'options': [{'numeral': 7}, {'numeral': 4}]}
        self.assertEqual(tv('tap_answer', {'row': ['n:3', 'op:+', 'n:4', 'op:=', '?']}, plain), '1.1')
        self.assertEqual(tv('tap_answer', {'chart': [1, 2]}, plain), '1.2')
        self.assertEqual(tv('tap_answer', {'row': ['n:3', 'op:<', 'n:4']}, plain), '1.4')
        self.assertEqual(tv('tap_answer', {'row': ['n:1000']}, plain), '1.4')
        self.assertEqual(tv('tap_answer', {'row': ['n:999', 'op::', 'n:3']}, plain), '1.1')
        self.assertEqual(tv('tap_answer', {'row': ['n:1'] * 9}, plain), '1.4')
        self.assertEqual(tv('tap_answer', {'numeral': 101}, plain), '1.4')
        self.assertEqual(tv('tap_answer', {}, {'type': 'choice', 'options': [{'numeral': 4050}, {'numeral': 4500}]}), '1.4')
        self.assertEqual(tv('tap_answer', {}, {'type': 'choice', 'options': [{}] * 5}), '1.4')
        self.assertEqual(tv('tap_answer', {'picture': {'kind': 'array'}}, plain), '1.4')
        self.assertEqual(tv('spot_error', {'cells': ['n:3', 'op:+', 'n:4']}, {'type': 'spot'}), '1.0')
        self.assertEqual(tv('spot_error', {'cells': ['n:4050', 'op:<', 'n:4500']}, {'type': 'spot'}), '1.1')
        self.assertEqual(tv('count_tap', {}, {'type': 'choice'}), '1.0')

    def test_every_activity_of_the_starter_pack_that_needs_a_new_version_says_it(self):
        def ver(v):
            return tuple(int(x) for x in v.split('.'))
        for a in load('activity.*.json'):
            if a['template'] in ('tap_answer', 'spot_error'):
                needs = ver(author.template_version(a['template'], a['scene'], a['answer']))
                if needs >= (1, 4) or a['template'] == 'spot_error':
                    self.assertGreaterEqual(ver(a['templateVersion']), needs, a['id'])

    def test_a_unit_is_band_c_named_by_its_batch_with_its_lessons_after_band_b(self):
        u = band_c.UnitC('C2', 'numbers', 'a note')
        self.assertEqual((u.name, u.d['band'], u.d['domain']), ('band-c2-numbers', 'C', 'numbers'))
        self.assertEqual(u.d['firstSequence'], 130)
        self.assertGreater(band_c.first_sequence('C1'), 65, 'after the last lesson of Band A and B on any path')
        self.assertEqual(u.act('NUM-C-01', 'number', value=1), 'c.numc01.1')
        self.assertEqual(u.act('NUM-C-01', 'number', value=2), 'c.numc01.2')
        self.assertEqual([band_c.first_sequence(b) for b in band_c.BATCHES], sorted(band_c.first_sequence(b) for b in band_c.BATCHES))
        with self.assertRaises(AssertionError):
            band_c.UnitC('C0', 'numbers', 'x')

    def test_a_registered_table_is_written_as_a_spec_that_author_reads(self):
        import tempfile
        saved = (band_c.TABLES[:], band_b.UNITS, list(band_b.MADE))
        tmp = tempfile.mkdtemp()
        try:
            band_b.UNITS = tmp
            band_b.MADE.clear()
            del band_c.TABLES[:]

            @band_c.table('C1', 'numbers', note='n')
            def numbers_c1(u):
                u.skill('NUM-C-02', 'title', 'child', 'cone-tree', ['NUM-C-01'], ['symbolic'], tags=['M-SUB-SMALLBIG'])
                band_c.number_item(u, 'NUM-C-02', 'q', [52, '-', 27, '=', '?'], 25, {35: 'M-SUB-SMALLBIG'},
                                   {'smaller_from_larger': 'M-SUB-SMALLBIG'}, h2='two', h3='three', ok='right')
                u.lesson('take-away-1', 'title', ['NUM-C-02'], ['c.numc02.1'], 'done')

            self.assertEqual([u.name for u in band_c.make(['C2'])], [])
            made = band_c.make(['C1'])
            self.assertEqual([u.name for u in made], ['band-c1-numbers'])
            band_c.write_all()
            spec = json.load(open(os.path.join(tmp, 'band-c1-numbers.json'), encoding='utf-8'))
            self.assertEqual((spec['band'], spec['firstSequence']), ('C', 100))
            self.assertEqual(spec['activities'][0]['kind'], 'number')
            self.assertEqual(spec['activities'][0]['row'], ['n:52', 'op:-', 'n:27', 'op:=', '?'])
            # the spec is what tools/author.py turns into a pack file
            ctx = {'names': spec['names'], 'objects': spec['objects']}
            author.TAG_FEEDBACK.setdefault('M-SUB-SMALLBIG', ('vo:fb.sub_smallbig', 'line'))
            doc = author.KINDS[spec['activities'][0]['kind']]({**spec['activities'][0], 'domain': 'numbers', 'band': 'C'}, ctx)
            self.assertEqual(doc['templateVersion'], '1.4')
            self.assertEqual(doc['band'], 'C')
        finally:
            band_c.TABLES[:] = saved[0]
            band_b.UNITS = saved[1]
            band_b.MADE[:] = saved[2]

    def test_a_band_c_line_takes_the_id_of_an_earlier_identical_line(self):
        saved = (dict(author.pool), dict(author.lines))
        try:
            author.pool.clear()
            author.lines.clear()
            first = author.say('vo:c.test.1.prompt', 'כַּמָּה זֶה?')
            second = author.say('vo:c.test.2.prompt', 'כַּמָּה זֶה?')
            other = author.say('vo:c.test.3.prompt', 'כַּמָּה יֵשׁ?')
            self.assertEqual((first['vo'], second['vo']), ('vo:c.test.1.prompt', 'vo:c.test.1.prompt'))
            self.assertEqual(second['caption'], first['caption'], 'nothing changes on the screen')
            self.assertEqual(other['vo'], 'vo:c.test.3.prompt')
            self.assertNotIn('vo:c.test.2.prompt', author.lines)
        finally:
            author.pool.clear()
            author.pool.update(saved[0])
            author.lines.clear()
            author.lines.update(saved[1])

    def test_a_band_a_or_b_id_and_a_shared_id_are_never_renamed(self):
        saved = (dict(author.pool), dict(author.lines))
        try:
            author.pool.clear()
            author.lines.clear()
            author.say('vo:c.test.1.prompt', 'כַּמָּה זֶה?')
            for vo in ('vo:count.apples.7.prompt', 'vo:b.test.1.prompt', 'vo:fb.test', 'vo:hint.test.h1'):
                self.assertEqual(author.say(vo, 'כַּמָּה זֶה?')['vo'], vo)
        finally:
            author.pool.clear()
            author.pool.update(saved[0])
            author.lines.clear()
            author.lines.update(saved[1])

    def test_a_celebration_is_another_clip_than_the_same_words_asked(self):
        saved = (dict(author.pool), dict(author.lines))
        try:
            author.pool.clear()
            author.lines.clear()
            asked = author.say('vo:c.test.1.prompt', 'כׇּל הַכָּבוֹד!')
            cheered = author.say('vo:celebrate.test_one', 'כׇּל הַכָּבוֹד!', pooled=True)
            again = author.say('vo:celebrate.test_two', 'כׇּל הַכָּבוֹד!', pooled=True)
            self.assertEqual(asked['vo'], 'vo:c.test.1.prompt')
            self.assertEqual((cheered['vo'], again['vo']), ('vo:celebrate.test_one', 'vo:celebrate.test_one'))
        finally:
            author.pool.clear()
            author.pool.update(saved[0])
            author.lines.clear()
            author.lines.update(saved[1])

    def test_the_starter_pack_has_one_band_c_id_for_each_text(self):
        """Band C ids of activities (`vo:c.`) never share a text with another such id, and the pool names the id that is used."""
        texts = {}

        def walk(node, doc):
            if isinstance(node, dict):
                if isinstance(node.get('vo'), str) and node['vo'].startswith('vo:c.') and 'caption' in node:
                    texts.setdefault(json.dumps(node['caption'], ensure_ascii=False), set()).add(node['vo'])
                for v in node.values():
                    walk(v, doc)
            elif isinstance(node, list):
                for v in node:
                    walk(v, doc)

        for f in glob.glob(os.path.join(STARTER, 'activity.c.*.json')):
            walk(json.load(open(f, encoding='utf-8')), f)
        self.assertGreater(len(texts), 300)
        self.assertEqual({t: ids for t, ids in texts.items() if len(ids) > 1}, {})
        pool = json.load(open(os.path.join(ROOT, 'content', 'voice-pool.c.json'), encoding='utf-8'))
        used = {next(iter(ids)) for ids in texts.values()}
        self.assertTrue(used <= set(pool.values()), 'every Band C activity id is in the pool')


if __name__ == '__main__':
    unittest.main()
