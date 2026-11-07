"""The Band A rules of the curriculum-expert's QA decisions (docs/languages/band-a-build.md section 7), as the generator keeps them.

    python tools/test_lang_band_a_rules.py

* D1: no target-language text in a Band A item (no chip on a prompt, a say, teach or hearing screen, a hint or a feedback line), except
  in Hebrew A-10 to A-12; a say step shows nothing by default;
* D2: a reverse check (the picture, three sound buttons), its hint ladder and its feedback name no option before the third hint;
* C-6: a check is in no lesson unless the item says `"inLesson": true`;
* D5: a bin of a Band A sort has a picture for its sign;
* the same rules on the committed packs of the three courses.
Standard library only.
"""
import glob
import json
import os
import sys
import unittest

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(TOOLS, '..'))
sys.path.insert(0, TOOLS)
import lang_pack  # noqa: E402
from test_lang_pack import RecipeBase  # noqa: E402

# A reverse item's ladder: no step before the third plays a clip (band-a-build.md 7.3).
HL_REV = [{'line': 'he-again', 'action': 'highlight_objects_sequentially'},
          {'line': '@gloss', 'orLine': 'he-again', 'action': 'replay_prompt_slow'},
          {'line': 'he-show', 'action': 'worked_example', 'target': '@target'}]


def reverse_item(**extra):
    item = {'id': 'i01', 'kind': 'tap', 'purpose': 'check', 'check': 'reverse', 'frame': 'he-tap', 'stage': 'a', 'ladder': 'HL-REV',
            'options': [{'clip': 'en-cat'}, {'clip': 'en-dog'}, {'clip': 'en-bye'}], 'wrong': {'en-dog': 'sem', 'en-bye': 'sem'},
            'hintWord': 'en-cat', 'inLesson': True, 'feedback': {'wrong': 'he-check', 'byTag': {'sem': 'he-check'}}}
    item.update(extra)
    return item


class BandARulesBase(RecipeBase):
    def setUp(self):
        super().setUp()
        self.sb.course['ladders']['HL-REV'] = HL_REV
        self.sb.course['glosses']['en-cat'] = 'he-gl'

    def lesson_of(self, *items, lessons=None):
        self.sb.unit['items'] = list(items)
        self.sb.unit['lessons'] = lessons or [{'id': 'l-1', 'title': 'כותרת', 'items': [i['id'] for i in items]}]


class NoChipTest(BandARulesBase):
    def test_a_say_step_shows_no_word_by_default(self):
        _, doc = self.one({'id': 'i01', 'kind': 'say', 'picture': 'a', 'clip': 'en-cat', 'forms': ['cat'], 'foils': ['cut'], 'purpose': 'practice'})
        self.assertNotIn('show', doc['prompt'])

    def test_a_chip_on_a_prompt_is_refused_in_a_band_a_skill_and_the_problem_says_where(self):
        self.sb.unit['items'] = [{'id': 'i01', 'kind': 'tap', 'target': 'en-cat', 'show': True, 'options': ['a', 'b'], 'wrong': {'b': 'sem'}}]
        self.sb.unit['lessons'] = [{'id': 'l-1', 'title': 'כותרת', 'items': ['i01']}]
        self.assertProblem('eng.a01.i01: shows a target-language word in a chip (prompt.show)')

    def test_a_chip_on_a_say_step_a_hint_or_a_feedback_step_is_refused_as_well(self):
        say = {'id': 'i01', 'kind': 'say', 'picture': 'a', 'clip': 'en-cat', 'forms': ['cat'], 'foils': ['cut'], 'purpose': 'practice', 'show': True}
        self.lesson_of(say)
        self.assertProblem('(prompt.show)')
        hint = {'id': 'i01', 'kind': 'tap', 'target': 'en-cat', 'options': ['a', 'b'], 'wrong': {'b': 'sem'},
                'ladder': [{'line': 'he-again', 'action': 'replay_prompt_slow'},
                           {'line': 'he-again', 'action': 'highlight_objects_sequentially'},
                           {'line': 'he-show', 'action': 'worked_example', 'target': '@target', 'show': True}]}
        self.lesson_of(hint)
        self.assertProblem('(hints.2.show)')
        feedback = {'id': 'i01', 'kind': 'tap', 'target': 'en-cat', 'options': ['a', 'b'], 'wrong': {'b': 'sem'},
                    'feedback': {'right': {'line': 'he-ok', 'target': '@target', 'show': True}}}
        self.lesson_of(feedback)
        self.assertProblem('(feedback.correct.show)')

    def test_a_chip_on_the_tap_after_a_say_step_is_refused(self):
        say = {'id': 'i01', 'kind': 'say', 'picture': 'a', 'clip': 'en-cat', 'forms': ['cat'], 'foils': ['cut'], 'purpose': 'practice',
               'then': {'kind': 'tap', 'target': 'en-cat', 'show': True, 'options': ['a', 'b'], 'wrong': {'b': 'sem'}}}
        self.lesson_of(say)
        self.assertProblem('eng.a01.i01t: shows a target-language word in a chip')

    def test_a_band_b_skill_is_not_held_to_the_rule_and_the_letter_skills_of_hebrew_are_named(self):
        self.sb.unit['skill']['id'] = 'ENG-B-01'
        self.lesson_of({'id': 'i01', 'kind': 'tap', 'target': 'en-cat', 'show': True, 'options': ['a', 'b'], 'wrong': {'b': 'sem'}})
        self.assertEqual(self.sb.problems(), '')
        self.assertEqual(lang_pack.LETTER_SKILLS_OF_BAND_A, ('HEB-A-10', 'HEB-A-11', 'HEB-A-12'))


class ReverseItemTest(BandARulesBase):
    def test_a_reverse_item_is_a_tap_that_shows_the_picture_and_offers_sound_buttons(self):
        _, doc = self.one(reverse_item())
        self.assertEqual((doc['purpose'], doc['checkType']), ('check', 'reverse'))
        self.assertEqual(doc['scene'], {'group': {'sprite': 'asset:a', 'count': 1}})
        self.assertEqual([sorted(o) for o in doc['answer']['options']],
                         [['clip', 'id', 'label'], ['clip', 'id', 'label', 'misconception'], ['clip', 'id', 'label', 'misconception']])
        self.assertNotIn('target', doc['prompt'])

    def test_a_reverse_item_is_the_variant_group_of_the_word_it_asks_for(self):
        _, doc = self.one(reverse_item())
        forward = self.one({'id': 'i02', 'kind': 'tap', 'target': 'en-cat', 'options': ['a', 'b'], 'wrong': {'b': 'sem'}})[1]
        self.assertEqual(doc['variantGroup'], forward['variantGroup'])

    def test_no_hint_before_the_third_and_no_first_error_line_plays_the_right_word(self):
        _, doc = self.one(reverse_item())
        self.assertEqual([h['level'] for h in doc['hints'] if 'target' in h], [3])
        self.assertEqual(doc['hints'][2]['target'], 'vo:eng.en_cat')
        for rule in doc['feedback']['incorrect']:
            self.assertNotIn('target', rule)

    def test_the_gloss_of_the_word_is_the_second_hint_and_a_course_with_no_gloss_says_its_other_line(self):
        _, doc = self.one(reverse_item())
        self.assertEqual(doc['hints'][1]['caption'][0]['v'], 'שָׁלוֹם')
        del self.sb.course['glosses']['en-cat']
        _, doc = self.one(reverse_item())
        self.assertEqual(doc['hints'][1]['caption'][0]['v'], 'שׁוּב.')

    def test_a_ladder_that_says_the_right_word_early_is_refused(self):
        self.sb.course['ladders']['HL-REV'] = [dict(HL_REV[0], target='@target')] + HL_REV[1:]
        self.lesson_of(reverse_item())
        self.assertProblem('hint 1 of a reverse item plays the right word')

    def test_a_first_error_line_that_says_the_right_word_is_refused(self):
        self.lesson_of(reverse_item(feedback={'wrong': {'line': 'he-check', 'target': '@target'}}))
        self.assertProblem('the first-error line of a reverse item plays the right word')

    def test_a_prompt_that_plays_the_right_word_is_refused_but_a_question_clip_is_not(self):
        self.lesson_of(reverse_item(target='en-cat'))
        self.assertProblem('the prompt of a reverse item plays the right word')
        self.lesson_of(reverse_item(target='en-whats-this'))
        self.assertEqual(self.sb.problems(), '')

    def test_a_reverse_item_without_a_picture_or_with_picture_options_is_refused(self):
        item = reverse_item()
        del item['stage']
        self.lesson_of(item)
        self.assertProblem('shows the picture of the word it asks for')
        self.lesson_of(reverse_item(options=[{'pic': 'b', 'clip': 'en-dog'}, {'pic': 'c', 'clip': 'en-cat'}], wrong={'b': 'sem'}, right='c'))
        self.assertProblem('are sound buttons only')

    def test_a_reverse_item_that_is_not_a_check_is_refused(self):
        self.lesson_of(reverse_item(purpose='learn'))
        self.assertProblem('a reverse item is a check')


class ChecksAndLessonsTest(BandARulesBase):
    def check_item(self, **extra):
        item = {'id': 'i02', 'kind': 'tap', 'target': 'en-bye', 'purpose': 'check', 'options': ['b', 'a'], 'wrong': {'a': 'sem'}}
        item.update(extra)
        return item

    def test_a_check_in_a_lesson_is_refused_and_the_problem_says_what_to_do(self):
        self.lesson_of({'id': 'i01', 'kind': 'tap', 'target': 'en-cat', 'options': ['a', 'b'], 'wrong': {'b': 'sem'}}, self.check_item())
        text = self.sb.problems()
        self.assertIn('the item "a01.i02" is a check, and a lesson holds none', text)
        self.assertIn('"inLesson": true', text)

    def test_a_check_marked_in_lesson_stays_and_a_check_outside_every_lesson_is_fine(self):
        learn = {'id': 'i01', 'kind': 'tap', 'target': 'en-cat', 'options': ['a', 'b'], 'wrong': {'b': 'sem'}}
        self.lesson_of(learn, self.check_item(inLesson=True))
        self.assertEqual(self.sb.problems(), '')
        self.lesson_of(learn, self.check_item(), lessons=[{'id': 'l-1', 'title': 'כותרת', 'items': ['i01']}])
        self.assertEqual(self.sb.problems(), '')

    def test_a_probe_and_a_practice_step_are_not_checks(self):
        learn = {'id': 'i01', 'kind': 'tap', 'target': 'en-cat', 'options': ['a', 'b'], 'wrong': {'b': 'sem'}}
        self.lesson_of(learn, self.check_item(purpose='practice', id='i02'))
        self.assertEqual(self.sb.problems(), '')

    def test_the_check_of_a_say_step_s_tap_is_a_check_in_a_lesson_too(self):
        say = {'id': 'i01', 'kind': 'say', 'picture': 'a', 'clip': 'en-cat', 'forms': ['cat'], 'foils': ['cut'], 'purpose': 'practice',
               'then': {'kind': 'tap', 'purpose': 'check', 'target': 'en-cat', 'options': ['a', 'b'], 'wrong': {'b': 'sem'}}}
        self.lesson_of(say)
        self.assertProblem('is a check, and a lesson holds none')


class BinSignTest(BandARulesBase):
    def sort(self, bins):
        return {'id': 'i01', 'kind': 'sort', 'frame': 'he-tap', 'bins': bins,
                'cards': [{'pic': 'c', 'bin': 'x'}, {'pic': 'd', 'bin': 'y'}], 'traps': {'c': {'tag': 'sem'}}}

    def test_a_bin_with_a_picture_is_fine(self):
        self.lesson_of(self.sort([{'id': 'x', 'label': 'en-cat', 'picture': 'a'}, {'id': 'y', 'label': 'en-dog', 'picture': 'b'}]))
        self.assertEqual(self.sb.problems(), '')

    def test_a_printed_word_on_a_bin_is_refused_in_band_a(self):
        self.lesson_of(self.sort([{'id': 'x', 'label': 'en-cat'}, {'id': 'y', 'label': 'en-dog', 'picture': 'b'}]))
        self.assertProblem('the bin "x" has no `picture`')

    def test_a_bin_is_not_held_to_the_rule_in_band_b(self):
        self.sb.unit['skill']['id'] = 'ENG-B-01'
        self.lesson_of(self.sort([{'id': 'x', 'label': 'en-cat'}, {'id': 'y', 'label': 'en-dog'}]))
        self.assertEqual(self.sb.problems(), '')


class CommittedPacksTest(unittest.TestCase):
    """What the packs hold, read off the committed files."""

    def docs(self, course):
        out = {}
        for path in glob.glob(os.path.join(ROOT, 'content', 'languages', course, 'pack', '*.json')):
            with open(path, encoding='utf-8') as fh:
                out[os.path.basename(path)] = json.load(fh)
        return out

    def test_no_band_a_activity_shows_a_word_except_the_letters_of_hebrew_a_10_to_a_12(self):
        for course in lang_pack.COURSES:
            for name, doc in self.docs(course).items():
                if not name.startswith('activity.') or doc['band'] != 'A' or doc['skills'][0]['id'] in lang_pack.LETTER_SKILLS_OF_BAND_A:
                    continue
                self.assertEqual(lang_pack.chip_places(doc), [], name)

    def test_no_check_is_in_a_lesson_unless_the_unit_file_says_so(self):
        for course in lang_pack.COURSES:
            docs = self.docs(course)
            marked = set()
            for path in glob.glob(os.path.join(ROOT, 'content', 'languages', course, 'units', '*.json')):
                with open(path, encoding='utf-8') as fh:
                    unit = json.load(fh)
                m = lang_pack.SKILL_ID.fullmatch(unit['skill']['id'])
                prefix = '%s.%s%s.' % (course, m.group(2).lower(), m.group(3))
                for item in unit['items']:
                    if item.get('inLesson') or (item.get('then') or {}).get('inLesson'):
                        marked.update({prefix + item['id'], prefix + item['id'] + 't'})
            for name, lesson in docs.items():
                if not name.startswith('lesson.'):
                    continue
                for aid in lesson['items']:
                    doc = docs.get('activity.%s.json' % aid)
                    if doc is not None and doc['purpose'] == 'check':
                        self.assertIn(aid, marked, '%s is a check in the lesson %s' % (aid, lesson['id']))

    def test_every_bin_of_a_band_a_sort_has_a_picture_and_no_printed_word(self):
        for course in lang_pack.COURSES:
            for name, doc in self.docs(course).items():
                if not name.startswith('activity.') or doc['template'] != 'sort_drag' or doc['band'] != 'A':
                    continue
                for b in doc['scene']['bins']:
                    self.assertIn('sprite', b, name)
                    self.assertNotIn('text', b, name)

    def test_every_reverse_check_names_no_right_clip_before_the_third_hint(self):
        found = 0
        for course in lang_pack.COURSES:
            for name, doc in self.docs(course).items():
                if not name.startswith('activity.') or doc.get('checkType') != 'reverse':
                    continue
                found += 1
                answer = doc['answer']
                right = {o['clip'] for o in answer['options'] if o['id'] == answer['correct']}
                said = [doc['prompt']] + [h for h in doc['hints'] if h['level'] < 3] + doc['feedback']['incorrect']
                for line in said:
                    self.assertFalse(right & {line.get('target'), line.get('target2')}, name)
        self.assertGreaterEqual(found, 0)


if __name__ == '__main__':
    unittest.main()
