"""The lesson shape of docs/milestones/L7.md section 3 (tools/lang_meet.py) and the rule "met before asked" (tools/lang_met_before.py).

    python tools/test_lang_met_before.py

* a lesson written in recall, meet, find and use is flattened (the Meet screens are not items, a set may stand anywhere with `before`),
  and the old form (`items`) keeps working;
* a Meet screen carries its place in its set, the words before it, the Hebrew meaning, the opener and the carrier;
* the rule refuses, with a named reason each, a scored item that asks a word not met, a picture option with no word clip, a Meet set of more
  than 3 words, a first Find with more than 2 choices, a new word with fewer than 2 Find items, a lesson with no Use item; it warns when a
  new word is not recalled within 3 lessons;
* report mode lists what a lesson in the old form breaks and does not fail the build; `"metBefore": "enforce"` makes every lesson refuse.
Standard library only.
"""
import glob
import io
import json
import os
import sys
import unittest
from contextlib import redirect_stdout

TOOLS = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, TOOLS)
import lang_met_before  # noqa: E402
import lang_pack  # noqa: E402
import test_lang_pack as base  # noqa: E402

CSV = ('id,shown,say,ipa\nen-hello,Hello!,Hello!,/h/\nen-bye,Bye!,Bye!,/b/\nen-cat,Cat,Cat,/k/\nen-dog,Dog,Dog,/d/\nen-pig,Pig,Pig,/p/\n'
       'en-owl,Owl,Owl,/o/\n')
LINES = {'he-meaning': 'בְּעִבְרִית:', 'he-open': 'בּוֹאוּ נַכִּיר.', 'he-hear': 'הַקְשִׁיבוּ:', 'he-gl-cat': 'חָתוּל'}


class Fixture(base.Sandbox):
    """The tiny English course with the four-part shape: words hello and bye on pictures a and b."""

    def __init__(self):
        super().__init__()
        self.pictures = ['a', 'b', 'c', 'd', 'e']
        self.course['defaults']['teach'] = {'frame': 'he-show', 'heard': 'he-again', 'together': 'he-show'}
        self.course['teachPictures'] = {'en-hello': 'a', 'en-bye': 'b', 'en-cat': 'c', 'en-dog': 'd', 'en-pig': 'e', 'en-owl': 'e'}
        self.course['glosses'].update({'en-cat': 'he-gl-cat', 'en-dog': 'he-gl', 'en-pig': 'he-gl', 'en-owl': 'he-gl'})
        for k, v in LINES.items():
            self.course['lines'][k] = {'he': v}
        self.unit['items'] = [self.tap('f1', 'en-hello', 'a', 'b'), self.tap('f2', 'en-bye', 'b', 'a'),
                              self.tap('f3', 'en-hello', 'b', 'a'), self.tap('f4', 'en-bye', 'a', 'b'), self.say('u1')]
        self.unit['lessons'] = [{'id': 'greet-1', 'title': 'בְּרָכוֹת', 'meet': [['en-hello', 'en-bye']],
                                 'find': ['f1', 'f2', 'f3', 'f4'], 'use': ['u1']}]

    CLIPS = {'a': 'en-hello', 'b': 'en-bye', 'c': 'en-cat', 'd': 'en-dog', 'e': 'en-pig'}

    def tap(self, item_id, target, right, *others, three=False):
        """A tap item whose every picture names its word clip (the picture's own word: pictures a to e are hello, bye, cat, dog, pig)."""
        order = [right] + list(others)
        options = [{'pic': p, 'clip': self.CLIPS[p]} for p in order]
        return {'id': item_id, 'kind': 'tap', 'target': target, 'options': options, 'wrong': {p: 'sem' for p in others}}

    @staticmethod
    def say(item_id):
        return {'id': item_id, 'kind': 'say', 'purpose': 'practice', 'picture': 'a', 'clip': 'en-hello', 'forms': ['hello'],
                'foils': ['yellow'], 'heard': 'he-again', 'together': 'he-show'}

    def write(self):
        super().write()
        path = os.path.join(self.root, 'docs', 'languages', 'english', 'pronunciation.csv')
        with open(path, 'w', encoding='utf-8', newline='') as fh:
            fh.write(CSV)

    def lesson_doc(self, lesson_id='greet-1'):
        return json.loads(self.build()['lesson.eng.%s.json' % lesson_id])

    def findings(self):
        self.write()
        course = lang_pack.Course('eng', self.root)
        try:
            course.build()
        except lang_pack.SpecError:
            pass
        return course.met_before

    def rules(self, enforced=None):
        return sorted({f.rule for f in self.findings() if enforced is None or f.enforced == enforced})


class Case(unittest.TestCase):
    def setUp(self):
        self.sb = Fixture()
        self.addCleanup(self.sb.close)

    def assertRefused(self, rule, fragment=''):
        text = self.sb.problems()
        self.assertIn('(%s)' % rule, text, text or 'the build was not refused')
        self.assertIn(fragment, text)


class ShapeTest(Case):
    def test_a_good_lesson_builds_and_breaks_no_rule(self):
        self.assertEqual('', self.sb.problems())
        self.assertEqual([], self.sb.findings())

    def test_the_four_parts_are_flattened_and_the_meet_screens_are_not_items(self):
        doc = self.sb.lesson_doc()
        self.assertEqual(['eng.a01.f1', 'eng.a01.f2', 'eng.a01.f3', 'eng.a01.f4', 'eng.a01.u1'], doc['items'])
        self.assertEqual([{'items': ['eng.a01.tc01', 'eng.a01.tc02'], 'routes': ['new'], 'mode': 'teach'}], doc['teach'])

    def test_a_set_may_stand_in_the_middle_of_a_lesson_before_the_item_it_names(self):
        self.sb.unit['items'] += [self.sb.tap('f5', 'en-cat', 'c', 'a'), self.sb.tap('f6', 'en-dog', 'd', 'c'),
                                  self.sb.tap('f7', 'en-cat', 'c', 'd'), self.sb.tap('f8', 'en-dog', 'd', 'a')]
        lesson = self.sb.unit['lessons'][0]
        lesson['meet'] = [['en-hello', 'en-bye'], {'words': ['en-cat', 'en-dog'], 'before': 'f5'}]
        lesson['find'] = ['f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8']
        doc = self.sb.lesson_doc()
        self.assertEqual(2, len(doc['teach']))
        self.assertNotIn('before', doc['teach'][0])
        self.assertEqual('eng.a01.f5', doc['teach'][1]['before'])
        self.assertEqual(['eng.a01.tc03', 'eng.a01.tc04'], doc['teach'][1]['items'])

    def test_a_set_that_stands_first_has_no_before(self):
        self.sb.unit['lessons'][0]['meet'] = [{'words': ['en-hello', 'en-bye'], 'before': 'f1'}]
        self.assertNotIn('before', self.sb.lesson_doc()['teach'][0])

    def test_a_before_that_is_not_an_item_of_the_lesson_is_named(self):
        self.sb.unit['lessons'][0]['meet'] = [{'words': ['en-hello', 'en-bye'], 'before': 'zz'}]
        self.assertIn('"before" names "zz"', self.sb.problems())

    def test_items_and_parts_may_not_be_mixed(self):
        self.sb.unit['lessons'][0]['items'] = ['f1']
        self.assertIn('not both', self.sb.problems())

    def test_a_lesson_in_the_old_form_still_builds(self):
        self.sb.unit['lessons'] = [{'id': 'greet-1', 'title': 'בְּרָכוֹת', 'items': ['f1', 'f2']}]
        self.assertEqual('', self.sb.problems())
        self.assertNotIn('teach', self.sb.lesson_doc())

    def test_a_meet_screen_knows_its_place_in_its_set_and_the_words_before_it(self):
        files = {k: json.loads(v) for k, v in self.sb.build().items() if k.startswith('activity.eng.a01.tc')}
        first, second = files['activity.eng.a01.tc01.json']['say']['meet'], files['activity.eng.a01.tc02.json']['say']['meet']
        self.assertEqual((0, 2), (first['position'], first['size']))
        self.assertNotIn('earlier', first)
        self.assertEqual((1, 2), (second['position'], second['size']))
        self.assertEqual([{'sprite': 'asset:a', 'clip': 'vo:eng.en_hello'}], second['earlier'])
        self.assertEqual('hello', first['written'])

    def test_the_hebrew_meaning_the_opener_and_the_carrier_are_spoken_lines(self):
        self.sb.course['defaults']['teach'].update({'meaning': 'he-meaning', 'opener': 'he-open', 'hear': 'he-hear'})
        self.sb.course['glosses']['en-bye'] = 'he-gl'
        files = {k: json.loads(v) for k, v in self.sb.build().items() if k.startswith('activity.eng.a01.tc')}
        first = files['activity.eng.a01.tc01.json']['say']['meet']
        second = files['activity.eng.a01.tc02.json']['say']['meet']
        self.assertEqual('vo:eng.he_open', first['opener']['vo'])
        self.assertNotIn('opener', second)
        self.assertEqual({'vo': 'vo:eng.he_hear'}, {'vo': first['hear']['vo']})
        self.assertEqual('vo:eng.en_hello', first['hear']['target'])
        self.assertEqual('vo:eng.he_meaning', first['meaning']['vo'])
        self.assertEqual('vo:eng.he_gl', first['meaning']['target'])
        self.assertEqual('בְּעִבְרִית: שָׁלוֹם', first['meaning']['caption'][0]['v'])

    def test_a_word_with_no_gloss_is_named_when_the_course_says_the_meaning(self):
        self.sb.course['defaults']['teach']['meaning'] = 'he-meaning'
        self.sb.course['glosses'].pop('en-bye')
        self.assertIn('no gloss', self.sb.problems())

    def test_a_word_with_no_picture_is_named(self):
        self.sb.course['teachPictures'].pop('en-bye')
        self.assertIn('no picture in course.json "teachPictures"', self.sb.problems())

    def test_a_focus_stays_inside_its_picture(self):
        self.sb.unit['lessons'][0]['meet'] = [[{'clip': 'en-hello', 'focus': [0.6, 0.5, 0.5, 0.4]}, 'en-bye']]
        self.assertIn('"focus" is [x, y, w, h]', self.sb.problems())
        self.sb.unit['lessons'][0]['meet'] = [[{'clip': 'en-hello', 'focus': [0.5, 0.5, 0.4, 0.4]}, 'en-bye']]
        self.assertEqual('', self.sb.problems())

    def test_a_picture_of_a_choice_that_names_every_word_asks_where(self):
        self.sb.course['defaults']['where'] = 'he-hear'
        files = {k: json.loads(v) for k, v in self.sb.build().items() if k.startswith('activity.eng.a01.f')}
        f1 = files['activity.eng.a01.f1.json']
        self.assertTrue(f1['answer']['askWhere'])
        self.assertEqual([{'when': 'default', 'vo': 'vo:eng.he_hear', 'caption': [{'t': 'he', 'v': 'הַקְשִׁיבוּ:'}],
                           'target': 'vo:eng.en_hello'}], f1['feedback']['incorrect'])

    def test_an_item_with_a_picture_that_names_no_word_does_not_ask_where(self):
        self.sb.course['defaults']['where'] = 'he-hear'
        self.sb.unit['items'][0]['options'][1] = 'b'
        self.sb.unit['lessons'] = [{'id': 'greet-1', 'title': 'x', 'items': ['f1', 'f2']}]
        doc = json.loads(self.sb.build()['activity.eng.a01.f1.json'])
        self.assertNotIn('askWhere', doc['answer'])

    def test_an_item_names_its_word_when_its_prompt_is_a_phrase(self):
        self.sb.unit['items'][0]['asks'] = 'en-hello'
        doc = json.loads(self.sb.build()['activity.eng.a01.f1.json'])
        self.assertEqual('vo:eng.en_hello', doc['asks'])

    def test_a_new_item_with_no_rotation_moves_no_other_praise(self):
        before = json.loads(self.sb.build()['activity.eng.a01.f4.json'])['feedback']['correct']['vo']
        self.sb.unit['items'].append(dict(self.sb.tap('f5', 'en-hello', 'a', 'b'), noRotation=True,
                                          feedback={'right': {'line': 'he-ok', 'target': '@target'}}))
        self.sb.unit['items'].insert(0, dict(self.sb.tap('f0', 'en-hello', 'a', 'b'), noRotation=True,
                                             feedback={'right': {'line': 'he-ok', 'target': '@target'}}))
        self.sb.unit['lessons'][0]['find'] += ['f0', 'f5']
        self.assertEqual(before, json.loads(self.sb.build()['activity.eng.a01.f4.json'])['feedback']['correct']['vo'])


class RuleTest(Case):
    def test_a_scored_item_that_asks_a_word_no_meet_screen_taught_is_refused(self):
        self.sb.unit['items'].append(self.sb.tap('f5', 'en-cat', 'c', 'a'))
        self.sb.unit['lessons'][0]['find'].append('f5')
        self.assertRefused('not-met', 'asks the word "vo:eng.en_cat" before any Meet screen has taught it')

    def test_an_option_that_is_a_word_not_met_is_refused_too(self):
        self.sb.unit['items'][0] = self.sb.tap('f1', 'en-hello', 'a', 'c')
        self.assertRefused('not-met', 'en_cat')

    def test_a_word_is_met_from_its_meet_screen_on_not_before(self):
        self.sb.unit['lessons'][0]['meet'] = [{'words': ['en-hello', 'en-bye'], 'before': 'f3'}]
        self.assertRefused('not-met', 'en_hello')

    def test_a_picture_option_that_names_no_word_clip_is_refused(self):
        self.sb.unit['items'][0]['options'][1] = 'b'
        self.assertRefused('unnamed', 'eng.a01.f1: the picture option(s) o2 name no word clip')

    def test_a_meet_set_of_more_than_three_words_is_refused(self):
        self.sb.unit['lessons'][0]['meet'] = [['en-hello', 'en-bye', 'en-cat', 'en-dog']]
        self.assertRefused('meet-size', 'a Meet set has 4 words; at most 3')

    def test_a_first_find_with_three_choices_is_refused(self):
        self.sb.unit['items'][0] = self.sb.tap('f1', 'en-hello', 'a', 'b', 'c')
        self.sb.unit['lessons'][0]['meet'] = [['en-hello', 'en-bye', 'en-cat']]
        self.assertRefused('first-find', 'the first Find on the new word "vo:eng.en_hello" has 3 choices')

    def test_a_new_word_with_fewer_than_two_find_items_is_refused(self):
        self.sb.unit['lessons'][0]['find'] = ['f1', 'f2', 'f4']
        self.assertRefused('find-count', 'the new word "vo:eng.en_hello" is the target of 1 Find item(s)')

    def test_a_lesson_with_no_use_item_is_refused(self):
        self.sb.unit['lessons'][0].pop('use')
        self.assertRefused('no-use', 'the lesson has no Use item')

    def test_a_find_item_in_the_use_part_does_not_count_as_a_use_item(self):
        self.sb.unit['lessons'][0]['use'] = ['f3']
        self.sb.unit['lessons'][0]['find'] = ['f1', 'f2', 'f4']
        self.assertIn('(no-use)', self.sb.problems())

    def test_a_new_word_that_is_not_recalled_within_three_lessons_is_only_a_warning(self):
        self.sb.unit['items'] += [self.sb.tap('g%d' % n, 'en-bye', 'b', 'a') for n in range(1, 4)]
        self.sb.unit['lessons'] += [{'id': 'later-%d' % n, 'title': 'x', 'items': ['g%d' % n, 'u1']} for n in range(1, 4)]
        found = [f for f in self.sb.findings() if f.rule == 'recall']
        self.assertEqual(['vo:eng.en_hello'], [f.where for f in found])
        self.assertFalse(found[0].enforced)
        self.assertNotIn('(recall)', self.sb.problems())

    def test_a_word_recalled_in_the_next_lessons_is_not_warned(self):
        self.sb.unit['items'] += [self.sb.tap('g1', 'en-hello', 'a', 'b'), self.sb.tap('g2', 'en-bye', 'b', 'a')]
        self.sb.unit['lessons'] += [{'id': 'later-1', 'title': 'x', 'items': ['g1', 'g2', 'u1']}] * 1
        self.sb.unit['lessons'] += [{'id': 'later-2', 'title': 'x', 'items': ['g1', 'u1']}, {'id': 'later-3', 'title': 'x', 'items': ['g2', 'u1']}]
        self.assertNotIn('recall', self.sb.rules())


class ModeTest(Case):
    def old_lesson(self):
        """A lesson in the old form that asks words no Meet screen has taught, and has no Use item."""
        self.sb.unit['items'].append(self.sb.tap('o1', 'en-cat', 'c', 'a'))
        self.sb.unit['lessons'].append({'id': 'old-1', 'title': 'x', 'items': ['o1']})

    def test_in_report_mode_a_lesson_in_the_old_form_is_listed_and_does_not_fail_the_build(self):
        self.old_lesson()
        self.assertEqual('', self.sb.problems())
        found = [f for f in self.sb.findings() if f.lesson == 'eng.old-1']
        self.assertEqual({'not-met', 'no-use'}, {f.rule for f in found})
        self.assertFalse(any(f.enforced for f in found))

    def test_a_lesson_in_the_new_form_is_enforced_in_report_mode(self):
        self.old_lesson()
        self.sb.unit['items'].append(self.sb.tap('f5', 'en-cat', 'c', 'a'))
        self.sb.unit['lessons'][0]['find'].append('f5')
        self.assertRefused('not-met')

    def test_enforce_mode_holds_every_lesson(self):
        self.old_lesson()
        self.sb.course['metBefore'] = 'enforce'
        text = self.sb.problems()
        self.assertIn('lesson eng.old-1 (not-met)', text)
        self.assertIn('lesson eng.old-1 (no-use)', text)

    def test_an_unknown_mode_is_refused(self):
        self.sb.course['metBefore'] = 'sometimes'
        self.assertIn('metBefore is "report" or "enforce"', self.sb.problems())

    def test_the_command_prints_every_violation_of_a_course_and_exits_0(self):
        self.old_lesson()
        self.sb.write()
        out = io.StringIO()
        with redirect_stdout(out):
            code = lang_pack.main(['eng', '--met-before'], root=self.sb.root)
        self.assertEqual(0, code)
        text = out.getvalue()
        self.assertIn('eng: 2 finding(s)', text)
        self.assertIn('not-met eng.old-1', text)
        self.assertIn('no-use eng.old-1', text)
        self.assertIn('0 would refuse the build now', text)

    def test_the_words_of_the_hebrew_course_that_are_everyday_need_no_meet_screen(self):
        self.old_lesson()
        self.sb.course['metBefore'] = 'enforce'
        self.sb.course['everyday'] = ['en-cat']
        self.assertNotIn('lesson eng.old-1 (not-met)', self.sb.problems())


class WhereTest(Case):
    """When a wrong tap says "and where is ...?" (the target must be the right option's own word clip)."""

    def question(self, target):
        """A tap item whose prompt ends with [target] and whose right picture is hello's."""
        item = self.sb.tap('q1', target, 'a', 'b')
        self.sb.unit['items'].append(item)
        self.sb.course['defaults']['where'] = 'he-hear'

    def incorrect(self):
        doc = json.loads(self.sb.build()['activity.eng.a01.q1.json'])
        return doc, doc['feedback']['incorrect']

    def test_an_item_whose_target_is_a_question_keeps_the_lines_of_its_tags_and_its_hint_picture(self):
        self.question('en-cat')
        doc, rules = self.incorrect()
        self.assertNotIn('askWhere', doc['answer'])
        self.assertEqual(['default'], [r['when'] for r in rules])
        self.assertEqual('vo:eng.he_check', rules[0]['vo'])  # the course's own wrong line, not "and where is"
        self.assertNotIn('target', rules[0])

    def test_an_item_whose_target_is_the_right_pictures_word_asks_where(self):
        self.question('en-hello')
        doc, rules = self.incorrect()
        self.assertTrue(doc['answer']['askWhere'])
        self.assertEqual([('default', 'vo:eng.en_hello')], [(r['when'], r['target']) for r in rules])

    def test_a_slow_version_is_the_same_word(self):
        self.assertTrue(lang_pack.Course.same_word('en-hello-slow', 'en-hello'))
        self.assertTrue(lang_pack.Course.same_word('en-hello', 'en-hello'))
        self.assertFalse(lang_pack.Course.same_word('en-hello', 'en-bye'))

    def test_the_target_is_compared_with_the_right_picture_not_with_another_one(self):
        self.question('en-bye')  # bye is the clip of the wrong picture
        self.assertNotIn('askWhere', self.incorrect()[0]['answer'])


class RealCoursesTest(unittest.TestCase):
    """The committed packs: every "and where is ...?" names the right picture's word, and the items whose target is a question, a sentence,
    a page or a syllable string do not ask it."""

    ROOT = os.path.normpath(os.path.join(TOOLS, '..'))
    # From the three courses: English questions and statements, Hebrew strip counts and story pages, Russian questions and probes.
    NOT_WHERE = {'eng': ['a16.i01', 'a16.i02', 'a16.pr1', 'a11.i01', 'a11.n01', 'a11.pr1'],
                 'heb': ['a08.07', 'a08.10', 'a08.12', 'a08.p1', 'a01.05', 'a01.06'],
                 'rus': ['a12.05', 'a12.f01', 'a12.r01', 'a13.f01', 'a13.r01', 'a03.p01', 'a17.p01', 'a19.p02']}
    WHERE = {'eng': ['a06.n01', 'a01.i01'], 'heb': ['a02.01', 'a02.02'], 'rus': ['a01.01', 'a02.01']}

    def doc(self, course, short):
        path = os.path.join(self.ROOT, 'content', 'languages', course, 'pack', 'activity.%s.%s.json' % (course, short))
        with open(path, encoding='utf-8') as fh:
            return json.load(fh)

    def test_the_items_with_a_question_or_a_sentence_for_a_target_keep_their_hint_picture(self):
        for course, ids in self.NOT_WHERE.items():
            for short in ids:
                doc = self.doc(course, short)
                self.assertNotIn('askWhere', doc['answer'], '%s.%s asks "and where is"' % (course, short))
                self.assertNotEqual('vo:%s.he_fb_where' % course, doc['feedback']['incorrect'][-1].get('vo'))

    def test_an_ordinary_find_says_and_where_is_and_the_target(self):
        for course, ids in self.WHERE.items():
            for short in ids:
                doc = self.doc(course, short)
                self.assertTrue(doc['answer'].get('askWhere'), '%s.%s' % (course, short))
                self.assertEqual(doc['prompt']['target'], doc['feedback']['incorrect'][-1]['target'])

    def test_every_and_where_is_names_the_right_pictures_own_clip(self):
        seen = 0
        for course in ('eng', 'heb', 'rus'):
            for path in glob.glob(os.path.join(self.ROOT, 'content', 'languages', course, 'pack', 'activity.*.json')):
                with open(path, encoding='utf-8') as fh:
                    doc = json.load(fh)
                answer = doc.get('answer') or {}
                if not answer.get('askWhere'):
                    continue
                seen += 1
                right = next(o for o in answer['options'] if o['id'] == answer['correct'])
                self.assertTrue(lang_pack.Course.same_word(doc['prompt']['target'], right['clip']), doc['id'])
        self.assertGreater(seen, 500)


class CardClipTest(Case):
    """A close-up card of a listen-and-do item names its word when touched."""

    def build(self, clips):
        self.sb.pictures += ['body', 'card-a', 'card-b']
        item = {'id': 'k1', 'kind': 'listen_do', 'mode': 'cards', 'frame': 'he-tap', 'picture': 'body', 'target': 'en-hello',
                'asks': 'en-hello', 'options': ['a', 'b'], 'right': 'a', 'wrong': {'b': 'sem'}}
        if clips is not None:
            item['partClips'] = clips
        self.sb.unit['items'].append(item)
        self.sb.write()
        areas = {'pictures': {'body': {'a': [0.1, 0.1, 0.3, 0.3], 'b': [0.5, 0.5, 0.3, 0.3]}}}
        with open(os.path.join(self.sb.root, 'content', 'languages', 'pictures', 'scenes.areas.json'), 'w', encoding='utf-8') as fh:
            json.dump(areas, fh)
        with open(os.path.join(self.sb.root, 'content', 'languages', 'pictures', 'body.hotspots.json'), 'w', encoding='utf-8') as fh:
            json.dump({'picture': 'body', 'parts': {}, 'cards': {'a': 'card-a', 'b': 'card-b'}, 'items': {}}, fh)
        course = lang_pack.Course('eng', self.sb.root)
        try:
            files = course.build()
        except lang_pack.SpecError as e:
            return None, '\n'.join(e.problems)
        return json.loads(files['activity.eng.a01.k1.json']), ''

    def test_a_card_carries_the_clip_of_its_part(self):
        doc, _ = self.build({'a': 'en-hello', 'b': 'en-bye'})
        self.assertEqual('cards', doc['answer']['mode'])
        self.assertEqual(['vo:eng.en_hello', 'vo:eng.en_bye'], [o['clip'] for o in doc['answer']['options']])

    def test_a_card_with_no_clip_in_the_item_stays_silent(self):
        doc, _ = self.build(None)
        self.assertTrue(all('clip' not in o for o in doc['answer']['options']))

    def test_a_clip_for_a_part_that_is_no_option_is_named(self):
        _, problems = self.build({'a': 'en-hello', 'zz': 'en-bye'})
        self.assertIn('"partClips" names "zz"', problems)


class NonWordTest(Case):
    """What is no word to meet: a story page, a count, a place sentence and a carrier (module note of tools/lang_met_before.py)."""

    def setUp(self):
        super().setUp()
        Fixture.CLIPS = dict(Fixture.CLIPS, f='en-owl', s='en-pig')
        self.addCleanup(Fixture.CLIPS.pop, 'f')
        self.addCleanup(Fixture.CLIPS.pop, 's')
        self.sb.pictures += ['f', 's', 'drum-strip-1', 'drum-strip-2', 'place-cat-on-box']
        # The owl is named as a word by an item that no lesson plays, so only its role in the lesson decides whether it is asked.
        self.sb.unit['items'].append(self.sb.tap('x1', 'en-hello', 'a', 'f'))

    def play(self, *items, meet=None):
        """Adds [items] to the unit and to the Find part of the lesson."""
        self.sb.unit['items'] += list(items)
        self.sb.unit['lessons'][0]['find'] += [i['id'] for i in items]
        if meet:
            self.sb.unit['lessons'][0]['meet'] = meet

    def not_met(self):
        return sorted(f.where for f in self.sb.findings() if f.rule == 'not-met')

    def test_the_control_a_word_asked_before_its_meet_screen_is_refused(self):
        self.play(self.sb.tap('q1', 'en-owl', 'a', 'b'))
        self.assertEqual(['eng.a01.q1'], self.not_met())

    def test_the_narration_of_a_story_page_is_no_word(self):
        story = {'id': 's1', 'kind': 'story', 'mode': 'listen', 'frame': 'he-tap', 'rep': 'story',
                 'pages': [{'picture': 'c', 'clips': ['en-owl']}, {'picture': 'd', 'clips': ['en-cat']}]}
        self.sb.unit['items'].append(story)
        self.play(self.sb.tap('q1', 'en-owl', 'a', 'b'))
        self.assertEqual([], self.not_met())

    def test_the_clip_of_an_option_whose_picture_is_a_story_page_is_no_word(self):
        story = {'id': 's1', 'kind': 'story', 'mode': 'listen', 'frame': 'he-tap', 'rep': 'story',
                 'pages': [{'picture': 'f', 'clips': ['en-cat']}, {'picture': 's', 'clips': ['en-dog']}]}
        self.sb.unit['items'].append(story)
        self.play(self.sb.tap('q1', 'en-hello', 'f', 's'))  # which page came first? (the pictures are the pages)
        self.assertEqual([], self.not_met())

    def test_the_count_of_a_beat_strip_is_no_word_and_a_strip_needs_no_clip(self):
        strips = {'id': 'q1', 'kind': 'tap', 'target': 'en-hello',
                  'options': [{'pic': 'drum-strip-2', 'clip': 'en-owl'}, {'pic': 'drum-strip-1', 'clip': 'en-pig'}],
                  'right': 'drum-strip-2', 'wrong': {'drum-strip-1': 'sem'}}
        silent = {'id': 'q2', 'kind': 'tap', 'target': 'en-bye', 'options': ['drum-strip-1', 'drum-strip-2'], 'right': 'drum-strip-1',
                  'wrong': {'drum-strip-2': 'sem'}}
        self.play(strips, silent)
        self.assertEqual([], self.not_met())
        self.assertNotIn('unnamed', self.sb.rules())

    def test_the_clip_of_a_place_scene_is_no_word_wherever_else_it_is_used(self):
        scene = {'id': 'q1', 'kind': 'tap', 'target': 'en-owl',
                 'options': [{'pic': 'place-cat-on-box', 'clip': 'en-owl'}, {'pic': 'a', 'clip': 'en-hello'}],
                 'right': 'place-cat-on-box', 'wrong': {'a': 'sem'}}
        self.play(scene)
        self.assertEqual([], self.not_met())

    def test_a_prompt_that_no_option_says_and_no_meet_screen_teaches_is_a_carrier(self):
        self.play(self.sb.tap('q1', 'en-dog', 'a', 'b'))  # en-dog is named nowhere in the course
        self.assertEqual([], self.not_met())

    def test_a_chunk_that_a_meet_screen_teaches_is_a_word_and_is_held_to_the_rule(self):
        # The Meet screen of en-dog stands after the item that asks it: the question is no carrier any more.
        self.sb.unit['items'] += [self.sb.tap('d1', 'en-dog', 'd', 'a'), self.sb.tap('d2', 'en-dog', 'd', 'a')]
        self.play(self.sb.tap('q1', 'en-dog', 'a', 'b'), meet=[['en-hello', 'en-bye'], {'words': ['en-dog', 'en-pig'], 'before': 'd1'}])
        self.sb.unit['lessons'][0]['find'] += ['d1', 'd2']
        self.assertIn('eng.a01.q1', self.not_met())

    def test_a_command_names_its_word_with_asks_and_counts_as_a_find(self):
        command = {'id': 'd1', 'kind': 'listen_do', 'mode': 'buttons', 'frame': 'he-tap', 'picture': 'a', 'target': 'en-bye',
                   'asks': 'en-hello', 'options': [{'pic': 'a', 'clip': 'en-hello'}, {'pic': 'b', 'clip': 'en-bye'}], 'right': 'a',
                   'wrong': {'b': 'sem'}}
        self.sb.unit['lessons'][0]['find'] = ['f1', 'f2', 'f4']  # hello has one Find: f1
        self.assertIn('find-count', self.sb.rules())
        self.play(command)  # the command adds the second Find of hello
        self.assertNotIn('find-count', self.sb.rules())

    def test_asked_reads_asks_before_the_prompt_and_the_right_option(self):
        doc = {'template': 'listen_do', 'asks': 'vo:eng.en_eyes', 'prompt': {'target': 'vo:eng.en_touch_eyes'},
               'answer': {'type': 'choice', 'correct': 'o1', 'options': [{'id': 'o1', 'sprite': 'asset:body_eyes'}]}}
        scored, target, options = lang_met_before.asked(doc)
        self.assertEqual((True, 'vo:eng.en_eyes', [('o1', None, 'asset:body_eyes')]), (scored, target, options))


if __name__ == '__main__':
    unittest.main()
