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
            pick(rule='size')


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

    def test_a_sorting_rule_line_is_one_of_the_two_rule_lines(self):
        for a in self.acts:
            for f in a['feedback']['incorrect']:
                if f['when'] == 'misconception:M-SORT-SHIFT' and f['vo'] != 'vo:fb.sort_shift':
                    self.assertIn(f['vo'], ('vo:fb.sort_shift.shape', 'vo:fb.sort_shift.kind'), a['id'])

    def test_a_tagged_option_is_never_the_right_one(self):
        for a in self.acts:
            for o in a['answer'].get('options', []) if a['answer'].get('type') == 'choice' else []:
                if o['id'] == a['answer']['correct']:
                    self.assertNotIn('misconception', o, a['id'])


if __name__ == '__main__':
    unittest.main()
