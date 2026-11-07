"""More tests of the language pack generator (run with tools/test_lang_pack.py, which imports them): the teach screens and routes, the own-name
items, the print-direction items (a page that shows its text) and the face of an item."""
import json
import os
import sys
import unittest

TOOLS = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, TOOLS)
import lang_pack  # noqa: E402
from test_lang_pack import Base, Sandbox  # noqa: E402

CSV = ('id,shown,say,ipa\nen-hello,Hello!,Hello!,/h/\nen-bye,Bye!,Bye!,/b/\nen-cat,cat,cat,/k/\nen-dog,dog,dog,/d/\n'
       'en-page,One two. Three four.,One two. Three four.,/p/\n')


class MoreBase(Base):
    def setUp(self):
        super().setUp()
        self.sb.pictures = ['a', 'b', 'c', 'pic-cat', 'pic-dog', 'page-1']
        csv_path = os.path.join(self.sb.root, 'docs', 'languages', 'english', 'pronunciation.csv')
        self._csv = csv_path

    def write_csv(self):
        with open(self._csv, 'w', encoding='utf-8') as fh:
            fh.write(CSV)

    def build(self):
        self.sb.write()
        self.write_csv()
        return lang_pack.Course('eng', self.sb.root).build()

    def problems(self):
        self.sb.write()
        self.write_csv()
        try:
            lang_pack.Course('eng', self.sb.root).build()
        except lang_pack.SpecError as e:
            return '\n'.join(e.problems)
        return ''

    def assertProblem(self, fragment):
        self.assertIn(fragment, self.problems())

    def files(self):
        return {k: json.loads(v) for k, v in self.build().items() if k.endswith('.json')}


class TeachTest(MoreBase):
    def setUp(self):
        super().setUp()
        self.sb.course['teachPictures'] = {'en-cat': 'pic-cat', 'en-dog': 'pic-dog'}
        self.sb.course['glosses'].update({'en-cat': 'he-gl', 'en-dog': 'he-gl'})
        self.sb.course['defaults']['teach'] = {'frame': 'he-tap', 'heard': 'he-listen', 'together': 'he-again'}
        self.sb.unit['teach'] = [['en-cat', 'en-dog']]
        self.sb.unit['routes'] = {'new': {'note': 'teach first'}, 'heritage': {'teach': False}, 'reader': {'as': 'new'}}
        self.sb.unit['items'] = [{'id': 'i01', 'kind': 'tap', 'target': 'en-cat', 'options': ['a', 'b', 'c'], 'wrong': {'b': 'sem', 'c': 'guess'}}]
        self.sb.unit['lessons'] = [{'id': 'greet-1', 'title': 'כותרת', 'items': ['i01']}]

    def test_a_teach_screen_is_a_say_step_flagged_as_one_and_not_an_item_of_the_lesson(self):
        files = self.files()
        doc = files['activity.eng.a01.tc01.json']
        self.assertEqual(doc['template'], 'say_it')
        self.assertEqual(doc['answer'], {'type': 'say_it', 'scored': False, 'teach': True})
        self.assertEqual(doc['purpose'], 'practice')
        self.assertEqual(doc['say']['forms'], ['cat'])
        self.assertEqual(doc['say']['foils'], ['dog'])
        self.assertEqual(doc['scene']['picture']['sprite'], 'asset:pic_cat')
        self.assertNotIn('eng.a01.tc01', files['lesson.eng.greet-1.json']['items'])

    def test_the_lesson_names_the_teach_screens_and_the_routes_that_are_shown_them(self):
        lesson = self.files()['lesson.eng.greet-1.json']
        self.assertEqual(lesson['teach'], [{'items': ['eng.a01.tc01', 'eng.a01.tc02'], 'routes': ['new', 'reader']}])

    def test_a_heritage_speaker_is_never_among_the_routes(self):
        for routes in ({'heritage': {}}, {'new': {}, 'heritage': {'teach': True}}, {'reader': {'as': 'heritage'}}):
            self.sb.unit['routes'] = routes
            for entry in self.files()['lesson.eng.greet-1.json'].get('teach', []):
                self.assertNotIn('heritage', entry['routes'])

    def test_the_reader_goes_as_the_route_it_points_to(self):
        self.sb.unit['routes'] = {'new': {}, 'heritage': {'teach': False}, 'reader': {'as': 'heritage'}}
        self.assertEqual(self.files()['lesson.eng.greet-1.json']['teach'][0]['routes'], ['new'])

    def test_a_unit_where_no_route_is_shown_them_writes_no_teach_entry(self):
        self.sb.unit['routes'] = {'new': {'teach': False}, 'heritage': {'teach': False}, 'reader': {'teach': False}}
        self.assertNotIn('teach', self.files()['lesson.eng.greet-1.json'])

    def test_a_set_goes_before_the_first_lesson_that_asks_one_of_its_words(self):
        self.sb.unit['items'] += [{'id': 'i02', 'kind': 'tap', 'target': 'en-dog', 'options': ['b', 'a'], 'wrong': {'a': 'sem'}}]
        self.sb.course['teachPictures']['en-bye'] = 'b'
        self.sb.unit['teach'] = [['en-cat', 'en-dog'], ['en-dog', 'en-bye']]
        self.sb.unit['lessons'] = [{'id': 'greet-1', 'title': 'כותרת', 'items': ['i01']}, {'id': 'greet-2', 'title': 'כותרת', 'items': ['i02']}]
        files = self.files()
        self.assertEqual([e['items'] for e in files['lesson.eng.greet-1.json']['teach']], [['eng.a01.tc01', 'eng.a01.tc02']])
        self.assertEqual([e['items'] for e in files['lesson.eng.greet-2.json']['teach']], [['eng.a01.tc03', 'eng.a01.tc04']])

    def test_teach_screens_do_not_change_the_praise_the_other_items_say(self):
        with_teach = self.files()['activity.eng.a01.i01.json']['feedback']['correct']
        del self.sb.unit['teach']
        self.assertEqual(self.files()['activity.eng.a01.i01.json']['feedback']['correct'], with_teach)

    def test_a_teach_screen_adds_no_representation_to_its_skill(self):
        with_teach = self.files()['skill.ENG-A-01.json']['representations']
        del self.sb.unit['teach']
        self.assertEqual(self.files()['skill.ENG-A-01.json']['representations'], with_teach)

    def test_a_word_with_no_picture_is_named(self):
        self.sb.course['teachPictures'] = {'en-cat': 'pic-cat'}
        self.assertProblem('the word has no picture in course.json "teachPictures"')

    def test_a_set_of_one_word_has_no_foil(self):
        self.sb.unit['teach'] = [['en-cat']]
        self.assertProblem('a teach set of one word has no foil')

    def test_a_route_record_must_be_a_known_route_and_an_object(self):
        self.sb.unit['routes'] = {'native': {}}
        self.assertProblem('the route "native" is not new, heritage or reader')
        self.sb.unit['routes'] = {'new': 'teach first'}
        self.assertProblem('the record of "new" is an object')
        self.sb.unit['routes'] = {'new': {'as': 'reader'}, 'reader': {'as': 'new'}}
        self.assertProblem('point at each other')


class FontTest(MoreBase):
    def test_an_item_may_ask_for_the_display_face_in_hebrew_only(self):
        self.sb.unit['items'][0]['font'] = 'display'
        self.assertProblem('only "display" (Secular One), and only in the Hebrew course')
        self.sb.unit['items'][0]['font'] = 'comic'
        self.assertProblem('font "comic"')


class PrintTest(MoreBase):
    def setUp(self):
        super().setUp()
        self.sb.course['ladders']['HLN'] = [{'line': 'he-again', 'action': 'replay_prompt_slow'}, {'line': 'he-show', 'action': 'highlight_objects_sequentially'},
                                            {'line': 'he-show', 'action': 'worked_example'}]
        self.sb.defaults_ladder = 'HLN'
        self.sb.course['defaults']['ladder'] = 'HLN'
        self.sb.course['tags']['order'] = {'id': 'eng.lis.order', 'kind': 'diagnostic', 'family': 'DIR', 'parentText': 'טקסט להורה.'}
        self.sb.course['tags']['pp'] = {'id': 'eng.lis.pp', 'kind': 'diagnostic', 'family': 'PRINT', 'parentText': 'טקסט להורה.'}
        self.sb.unit['items'] = [
            {'id': 'p01', 'kind': 'page-zones', 'page': 'page-1', 'clip': 'en-page', 'zones': ['line1-start', 'line2-end', 'picture'],
             'wrong': {'line2-end': 'order', 'picture': 'pp'}},
            {'id': 'p02', 'kind': 'follow', 'page': 'page-1', 'clip': 'en-page', 'wrong': {'other': 'order', 'picture': 'pp'}},
        ]
        self.sb.unit['lessons'] = [{'id': 'greet-1', 'title': 'כותרת', 'items': ['p01', 'p02']}]

    def test_a_zones_page_shows_its_text_one_sentence_to_a_line(self):
        doc = self.files()['activity.eng.a01.p01.json']
        self.assertEqual(doc['template'], 'story')
        self.assertEqual(doc['templateVersion'], '1.1')
        page = doc['scene']['pages'][0]
        self.assertEqual([[w['text'] for w in line] for line in page['lines']], [['One', 'two.'], ['Three', 'four.']])
        self.assertTrue(all('clip' not in w for line in page['lines'] for w in line), 'the voice reads the page, not each word')
        self.assertEqual([(o['zone'], o.get('misconception')) for o in doc['answer']['options']],
                         [('line1-start', None), ('line2-end', 'eng.lis.order'), ('picture', 'eng.lis.pp')])
        self.assertEqual(doc['answer']['correct'], 'o1')
        self.assertEqual(doc['answer']['mode'], 'zones')

    def test_a_follow_page_gives_every_word_a_clip_cut_from_the_page_and_never_voiced(self):
        course = lang_pack.Course('eng', self.sb.root)
        self.sb.write()
        self.write_csv()
        files = {k: json.loads(v) for k, v in lang_pack.Course('eng', self.sb.root).build().items() if k.endswith('.json')}
        words = [w for line in files['activity.eng.a01.p02.json']['scene']['pages'][0]['lines'] for w in line]
        self.assertEqual([w['clip'] for w in words], ['vo:eng.en_page_w%d' % n for n in range(1, 5)])
        course = lang_pack.Course('eng', self.sb.root)
        course.build()
        plan = json.loads(course.plan_bytes())
        self.assertEqual([c['id'] for c in plan['cutClips']], ['en-page-w1', 'en-page-w2', 'en-page-w3', 'en-page-w4'])
        self.assertEqual({c['from'] for c in plan['cutClips']}, {'en-page'})
        self.assertNotIn('en-page-w1', [c['id'] for c in plan['targetClips']])

    def test_every_wrong_zone_needs_its_tag_and_a_zones_page_needs_the_start(self):
        del self.sb.unit['items'][0]['wrong']['picture']
        self.assertProblem('the zone "picture" has no tag')
        self.sb.unit['items'][0]['zones'] = ['line2-end', 'picture']
        self.assertProblem('with "line1-start"')

    def test_a_page_has_one_to_three_lines(self):
        global CSV
        old = CSV
        try:
            CSV = CSV.replace('One two. Three four.,One two. Three four.', 'A. B. C. D.,A. B. C. D.')
            self.assertProblem('has 4 lines (1 to 3')
        finally:
            CSV = old


class OwnNameTest(MoreBase):
    def setUp(self):
        super().setUp()
        self.sb.course['ladders']['HLN'] = [{'line': 'he-again', 'action': 'replay_prompt_slow'}, {'line': 'he-show', 'action': 'highlight_objects_sequentially'},
                                            {'line': 'he-show', 'action': 'worked_example'}]
        self.sb.course['defaults']['ladder'] = 'HLN'
        self.sb.course['tags']['first'] = {'id': 'eng.lis.first', 'kind': 'diagnostic', 'family': 'GUESS', 'parentText': 'טקסט להורה.'}
        self.sb.course['tags']['len'] = {'id': 'eng.lis.len', 'kind': 'diagnostic', 'family': 'GUESS', 'parentText': 'טקסט להורה.'}
        self.sb.course['tags']['bk'] = {'id': 'eng.lis.bk', 'kind': 'diagnostic', 'family': 'SHAPE', 'parentText': 'טקסט להורה.'}
        self.sb.unit['ownName'] = {'names': ['דנה', 'גיל', 'בן'], 'pairs': [{'a': 'ב', 'b': 'כ', 'tag': 'bk'}]}
        self.sb.unit['items'] = [
            {'id': 'n01', 'kind': 'name', 'frame': 'he-tap', 'options': ['own', 'first', 'length'], 'wrong': {'first': 'first', 'length': 'len'}},
            {'id': 'n02', 'kind': 'name-letter', 'frame': 'he-tap', 'options': ['first', 'lookalike', 'last'],
             'wrong': {'lookalike': 'bk', 'last': 'len'}},
        ]
        self.sb.unit['lessons'] = [{'id': 'greet-1', 'title': 'כותרת', 'items': ['n01', 'n02']}]

    def test_the_item_holds_the_rules_and_the_list_and_no_name(self):
        doc = self.files()['activity.eng.a01.n01.json']
        self.assertEqual(doc['templateVersion'], '1.5')
        self.assertEqual(doc['answer']['type'], 'name')
        self.assertEqual(doc['answer']['unit'], 'name')
        self.assertEqual(doc['answer']['names'], ['דנה', 'גיל', 'בן'])
        self.assertEqual([o['source'] for o in doc['answer']['options']], ['own', 'first', 'length'])
        for o in doc['answer']['options']:
            for face in ('text', 'sprite', 'clip', 'numeral'):
                self.assertNotIn(face, o, 'an option is made on the device: it has no face in the pack')
        self.assertEqual(doc['answer']['correct'], 'o1')
        self.assertNotIn('misconception', doc['answer']['options'][0])
        self.assertEqual(doc['answer']['options'][1]['misconception'], 'eng.lis.first')

    def test_a_row_of_letters_carries_the_look_alike_pairs_and_every_pair_tag_is_in_the_pack(self):
        files = self.files()
        doc = files['activity.eng.a01.n02.json']
        self.assertEqual(doc['answer']['unit'], 'letter')
        self.assertEqual(doc['answer']['pairs'], [{'a': 'ב', 'b': 'כ', 'misconception': 'eng.lis.bk'}])
        self.assertIn('misconception.eng.lis.bk.json', files)

    def test_a_two_option_item_allows_one_retry(self):
        self.sb.unit['items'][0]['options'] = ['own', 'length']
        self.assertEqual(self.files()['activity.eng.a01.n01.json']['scoring']['maxAttempts'], 2)

    def test_the_options_must_be_sources_of_the_kind_and_the_right_one_must_be_there(self):
        self.sb.unit['items'][0]['options'] = ['own', 'last']
        self.assertProblem('the options of a name item are 2 or 3 of own, first, length')
        self.sb.unit['items'][0]['options'] = ['first', 'length']
        self.assertProblem('has the option "own" (the right one)')

    def test_the_rules_need_the_list_and_the_pairs(self):
        del self.sb.unit['ownName']['names']
        self.assertProblem('`ownName.names`')
        self.sb.unit['ownName']['names'] = ['דנה']
        del self.sb.unit['ownName']['pairs']
        self.assertProblem('`ownName.pairs`')


class NamesBecomeFilesTest(Base):
    """SEC-BA-1: an id from a teacher's file becomes part of a file name, so it is held to a plain id (tools/test_sec_lang_pack.py runs the
    attack itself)."""

    def gate(self, gate_id):
        self.sb.unit['docs'] = [{'kind': 'gate', 'id': gate_id, 'doc': {'requires': ['ENG-A-01'], 'holds': ['ENG-B-01']}}]

    def test_a_gate_id_is_the_courses_own_and_a_plain_id(self):
        self.gate('eng.oral')
        self.assertIn('gate.eng.oral.json', self.sb.build())
        for bad in ('heb.oral', 'eng.', 'eng.Oral', 'eng.a/b', 'eng.a\\b', 'eng.oral\n', '../eng.oral', 'eng.' + 'x' * 20, 'eng.a.b'):
            with self.subTest(gate_id=bad):
                self.gate(bad)
                self.assertProblem('the gate id')

    def test_an_item_or_lesson_id_with_a_line_end_is_refused(self):
        self.sb.unit['items'][0]['id'] += '\n'
        self.assertProblem('must be lower case letters, digits and hyphens')

    def test_a_file_outside_the_pack_is_refused_before_anything_is_written(self):
        root = self.sb.root
        pack = os.path.join(root, 'content', 'languages', 'eng', 'pack')
        plan = os.path.join(root, 'content', 'languages', 'eng', 'voice-plan.json')
        lang_pack.refuse_outside('eng', pack, {os.path.join(pack, 'pack.json'): b'', plan: b''}, root)  # what is right passes
        for path in (os.path.join(pack, '..', 'x.json'), os.path.join(pack, 'sub', 'x.json'), os.path.join(root, 'x.json')):
            with self.subTest(path=path):
                with self.assertRaises(lang_pack.SpecError):
                    lang_pack.refuse_outside('eng', pack, {path: b''}, root)
        self.assertFalse(os.path.exists(os.path.join(pack, 'sub')), 'no folder is made by the check')


if __name__ == '__main__':
    unittest.main()
