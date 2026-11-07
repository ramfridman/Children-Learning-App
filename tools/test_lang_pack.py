"""The language pack generator (tools/lang_pack.py) and the pack sources of the three courses it writes.

    python tools/test_lang_pack.py

* the committed pack sources (content/languages/<course>/pack) and voice plans are exactly what the course files give, twice over;
* what the generator derives (ids, `vo:` ids, skill representations and tags, lessons, assets, the pack file, the voice plan);
* the rules it checks before the pack builder does (every problem is said, none is silent): lines, clips, pictures, tags,
  options, ladders, ids, lessons, placement, versions;
* the invariants of docs/languages/frame.md section 1.5 in the written files (one course, the tutor off, review marks).
Standard library only. The signed packs are tested in app/test/language_packs_build_test.dart (the same files, the real validator).
"""
import copy
import glob
import json
import os
import shutil
import sys
import tempfile
import unittest

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(TOOLS, '..'))
sys.path.insert(0, TOOLS)
import lang_pack  # noqa: E402

LINES = {'he-tap': 'הַקְשִׁיבוּ.', 'he-again': 'שׁוּב.', 'he-show': 'הִסְתַּכְּלוּ.', 'he-gl': 'שָׁלוֹם', 'he-ok': 'נָכוֹן!',
         'he-check': 'הַמְּמ…', 'he-listen': 'הַקְשִׁיבוּ שׁוּב:', 'he-bye': 'לְהִתְרָאוֹת!'}


def base_course():
    return {
        'course': 'eng',
        'pack': {'version': '0.1.0', 'minAppVersion': '0.5.0'},
        'defaults': {'frame': 'he-tap', 'ladder': 'HL', 'celebration': 'he-bye', 'rep': 'pictorial'},
        'feedback': {'right': [{'line': 'he-ok', 'target': '@target'}], 'wrong': {'line': 'he-check'},
                     'unsure': {'line': 'he-listen', 'target': '@target'}},
        'ladders': {'HL': [{'line': 'he-again', 'action': 'replay_prompt_slow', 'target': '@slow'},
                           {'line': '@gloss', 'action': 'highlight_objects_sequentially', 'target': '@target'},
                           {'line': 'he-show', 'action': 'worked_example', 'target': '@target'}]},
        'glosses': {'en-hello': 'he-gl', 'en-bye': 'he-gl'},
        'tags': {'sem': {'id': 'eng.lis.sem', 'kind': 'diagnostic', 'family': 'MEANING', 'parentText': 'טקסט להורה.'},
                 'guess': {'id': 'eng.lis.guess', 'kind': 'diagnostic', 'family': 'GUESS', 'parentText': 'טקסט להורה.'}},
        'lines': {k: {'he': v} for k, v in LINES.items()},
    }


def base_unit():
    return {
        'skill': {'id': 'ENG-A-01', 'strand': 'lis', 'title': 'בְּרָכוֹת'},
        'items': [
            {'id': 'i01', 'kind': 'tap', 'target': 'en-hello', 'options': ['a', 'b', 'c'], 'wrong': {'b': 'sem', 'c': 'guess'}},
            {'id': 'i02', 'kind': 'tap', 'target': 'en-bye', 'options': ['b', 'a'], 'wrong': {'a': 'sem'}, 'purpose': 'check'},
        ],
        'lessons': [{'id': 'greet-1', 'title': 'בְּרָכוֹת', 'items': ['i01', 'i02']}],
    }


CSV = 'id,shown,say,ipa\nen-hello,Hello!,Hello!,/h/\nen-bye,Bye!,Bye!,/b/\nen-bye-slow,Bye!,Bye!,/b/\n'


class Sandbox:
    """A root folder with one tiny English course, for the tests that change it."""

    def __init__(self):
        self.root = tempfile.mkdtemp(prefix='nn_lang_')
        self.course = base_course()
        self.unit = base_unit()
        self.placement = None
        self.pictures = ['a', 'b', 'c']
        self.write()

    def write(self):
        base = os.path.join(self.root, 'content', 'languages')
        shutil.rmtree(base, ignore_errors=True)
        os.makedirs(os.path.join(base, 'eng', 'units'))
        os.makedirs(os.path.join(base, 'pictures'))
        os.makedirs(os.path.join(self.root, 'docs', 'languages', 'english'), exist_ok=True)
        with open(os.path.join(self.root, 'docs', 'languages', 'english', 'pronunciation.csv'), 'w', encoding='utf-8') as fh:
            fh.write(CSV)
        for p in self.pictures:
            with open(os.path.join(base, 'pictures', p + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
                fh.write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256"><circle cx="1" cy="1" r="1"/></svg>\n')
        self.dump(os.path.join(base, 'eng', 'course.json'), self.course)
        self.dump(os.path.join(base, 'eng', 'units', '01-unit.json'), self.unit)
        if self.placement is not None:
            self.dump(os.path.join(base, 'eng', 'placement.json'), self.placement)

    @staticmethod
    def dump(path, doc):
        with open(path, 'w', encoding='utf-8', newline='\n') as fh:
            json.dump(doc, fh, ensure_ascii=False, indent=2)

    def build(self):
        self.write()
        return lang_pack.Course('eng', self.root).build()

    def problems(self):
        """The problems the files have, as one string (empty if none)."""
        self.write()
        try:
            lang_pack.Course('eng', self.root).build()
        except lang_pack.SpecError as e:
            return '\n'.join(e.problems)
        return ''

    def close(self):
        shutil.rmtree(self.root, ignore_errors=True)


class Base(unittest.TestCase):
    def setUp(self):
        self.sb = Sandbox()
        self.addCleanup(self.sb.close)

    def files(self):
        return {k: json.loads(v) for k, v in self.sb.build().items() if k.endswith('.json')}

    def assertProblem(self, fragment):
        text = self.sb.problems()
        self.assertIn(fragment, text)


class CommittedSourcesTest(unittest.TestCase):
    """What is committed is what the course files give."""

    def test_the_committed_pack_sources_are_current(self):
        stale = lang_pack.run(check=True, quiet=True)
        self.assertEqual(stale, [], 'run `python tools/lang_pack.py all` (out of date: %s)' % [os.path.relpath(s, ROOT) for s in stale])

    def test_a_regeneration_on_a_copy_gives_the_committed_files_and_is_stable(self):
        tmp = tempfile.mkdtemp(prefix='nn_lang_regen_')
        self.addCleanup(shutil.rmtree, tmp, True)
        for rel in ('content/languages', 'docs/languages'):
            shutil.copytree(os.path.join(ROOT, rel), os.path.join(tmp, rel),
                            ignore=shutil.ignore_patterns('pack', 'voice-plan.json', 'fonts', 'strokes') if rel == 'content/languages'
                            else None)
        for _ in range(2):
            lang_pack.run(root=tmp, quiet=True)
            for course in lang_pack.COURSES:
                for name in os.listdir(os.path.join(ROOT, 'content', 'languages', course, 'pack')):
                    with open(os.path.join(ROOT, 'content', 'languages', course, 'pack', name), 'rb') as a, \
                            open(os.path.join(tmp, 'content', 'languages', course, 'pack', name), 'rb') as b:
                        self.assertEqual(a.read(), b.read(), '%s/%s' % (course, name))

    def test_every_pack_file_is_one_the_generator_writes(self):
        for course in lang_pack.COURSES:
            pack_dir, out = lang_pack.outputs(course)
            self.assertEqual(set(glob.glob(os.path.join(pack_dir, '*'))), {p for p in out if p.startswith(pack_dir)})


class PilotInvariantsTest(unittest.TestCase):
    """The rules of frame section 1.5 and 1.6, read off the written files of the three pilots."""

    def docs(self, course):
        pack_dir = os.path.join(ROOT, 'content', 'languages', course, 'pack')
        out = {}
        for path in glob.glob(os.path.join(pack_dir, '*.json')):
            with open(path, encoding='utf-8') as fh:
                out[os.path.basename(path)] = json.load(fh)
        return out

    def test_the_pack_is_lang_course_and_every_document_agrees(self):
        for course in lang_pack.COURSES:
            docs = self.docs(course)
            pack = docs.pop('pack.json')
            self.assertEqual((pack['id'], pack['course']), ('lang-' + course, course))
            for name, d in docs.items():
                self.assertEqual(d['course'], course, name)
                self.assertEqual(d['review'], 'needs-editor', name)

    def test_ids_carry_the_course(self):
        for course in lang_pack.COURSES:
            for name, d in self.docs(course).items():
                if name.startswith(('activity.', 'lesson.')):
                    self.assertTrue(d['id'].startswith(course + '.'), name)
                if name.startswith('skill.'):
                    self.assertTrue(d['id'].startswith(course.upper() + '-'), name)
                if name.startswith('misconception.'):
                    self.assertTrue(d['id'].startswith(course + '.'), name)

    def test_nothing_points_into_another_course_and_the_tutor_is_off(self):
        for course in lang_pack.COURSES:
            docs = self.docs(course)
            skills = {d['id'] for n, d in docs.items() if n.startswith('skill.')}
            tags = {d['id'] for n, d in docs.items() if n.startswith('misconception.')}
            for name, d in docs.items():
                if name.startswith('activity.'):
                    self.assertFalse(d['tutor']['llmAllowed'], name)
                    self.assertTrue({s['id'] for s in d['skills']} <= skills, name)
                    for o in d['answer']['options']:
                        if 'misconception' in o:
                            self.assertIn(o['misconception'], tags, name)
                if name.startswith('skill.'):
                    self.assertTrue(set(d['misconceptions']) <= tags, name)
                    self.assertTrue({p['skill'] for p in d['prerequisites']} <= skills, name)

    def test_every_distractor_is_tagged_and_two_choice_items_allow_one_retry(self):
        for course in lang_pack.COURSES:
            for name, d in self.docs(course).items():
                if not name.startswith('activity.'):
                    continue
                options = d['answer']['options']
                wrong = [o for o in options if o['id'] != d['answer']['correct']]
                self.assertTrue(all('misconception' in o for o in wrong), name)
                self.assertEqual(d['scoring']['maxAttempts'], 2 if len(options) == 2 else 3, name)

    def test_every_picture_an_item_shows_is_in_the_pack_and_in_the_shared_library(self):
        for course in lang_pack.COURSES:
            pack_dir = os.path.join(ROOT, 'content', 'languages', course, 'pack')
            assets = {a['id']: a['file'] for a in self.docs(course)['pack.json']['assets']}
            for asset, file in assets.items():
                self.assertTrue(os.path.exists(os.path.join(pack_dir, file)), file)
                with open(os.path.join(pack_dir, file), 'rb') as a, \
                        open(os.path.join(ROOT, 'content', 'languages', 'pictures', asset.replace('_', '-') + '.svg'), 'rb') as b:
                    self.assertEqual(a.read(), b.read(), file)
            for name, d in self.docs(course).items():
                if name.startswith('activity.'):
                    for o in d['answer']['options']:
                        if 'sprite' in o:
                            self.assertIn(o['sprite'][len('asset:'):], assets)

    def test_the_voice_plan_lists_every_clip_a_document_names(self):
        for course in lang_pack.COURSES:
            with open(os.path.join(ROOT, 'content', 'languages', course, 'voice-plan.json'), encoding='utf-8') as fh:
                plan = json.load(fh)
            planned = {c['vo'] for c in plan['frameLines']} | {c['vo'] for c in plan['targetClips']}
            named = set()

            def scan(n):
                if isinstance(n, str) and n.startswith('vo:'):
                    named.add(n)
                elif isinstance(n, dict):
                    for v in n.values():
                        scan(v)
                elif isinstance(n, list):
                    for v in n:
                        scan(v)
            scan(list(self.docs(course).values()))
            self.assertEqual(named, planned, course)
            for c in plan['targetClips']:
                self.assertTrue(c['shown'], c)
            for c in plan['frameLines']:
                self.assertTrue(c['he'], c)


class DerivedTest(Base):
    def test_ids_vo_refs_and_defaults(self):
        f = self.files()
        a = f['activity.eng.a01.i01.json']
        self.assertEqual(a['template'], 'tap_answer')
        self.assertEqual(a['prompt']['vo'], 'vo:eng.he_tap')
        self.assertEqual(a['prompt']['target'], 'vo:eng.en_hello')
        self.assertTrue(a['prompt']['replayButton'])
        self.assertEqual(a['variantGroup'], 'en-hello')
        self.assertEqual((a['purpose'], a['checkType']), ('learn', 'practice'))
        self.assertEqual(a['answer']['correct'], 'o1')
        self.assertTrue(a['answer']['shuffle'])

    def test_a_check_is_a_check(self):
        a = self.files()['activity.eng.a01.i02.json']
        self.assertEqual((a['purpose'], a['checkType']), ('check', 'transfer'))

    def test_the_hint_ladder_has_three_steps_the_slow_clip_where_there_is_one_and_the_gloss(self):
        f = self.files()
        hints = f['activity.eng.a01.i01.json']['hints']
        self.assertEqual([h['level'] for h in hints], [1, 2, 3])
        self.assertEqual([h['action'] for h in hints],
                         ['replay_prompt_slow', 'highlight_objects_sequentially', 'worked_example'])
        self.assertEqual(hints[0]['target'], 'vo:eng.en_hello', 'no slow clip in the table: the clip itself')
        self.assertEqual(hints[1]['vo'], 'vo:eng.he_gl')
        slow = f['activity.eng.a01.i02.json']['hints'][0]
        self.assertEqual(slow['target'], 'vo:eng.en_bye_slow')

    def test_a_two_choice_item_allows_one_retry(self):
        f = self.files()
        self.assertEqual(f['activity.eng.a01.i01.json']['scoring']['maxAttempts'], 3)
        self.assertEqual(f['activity.eng.a01.i02.json']['scoring']['maxAttempts'], 2)

    def test_the_distractors_carry_their_tags(self):
        a = self.files()['activity.eng.a01.i01.json']
        tags = {o['id']: o.get('misconception') for o in a['answer']['options']}
        self.assertEqual(tags, {'o1': None, 'o2': 'eng.lis.sem', 'o3': 'eng.lis.guess'})

    def test_the_skill_lists_what_its_items_use(self):
        s = self.files()['skill.ENG-A-01.json']
        self.assertEqual(s['representations'], ['pictorial'])
        self.assertEqual(s['misconceptions'], ['eng.lis.guess', 'eng.lis.sem'])
        self.assertEqual((s['course'], s['domain'], s['band'], s['strand']), ('eng', 'languages', 'A', 'lis'))

    def test_a_tag_no_item_uses_is_not_in_the_pack(self):
        self.sb.course['tags']['extra'] = {'id': 'eng.lis.extra', 'kind': 'diagnostic', 'parentText': 'x'}
        self.assertNotIn('misconception.eng.lis.extra.json', self.sb.build())

    def test_the_tag_documents_know_their_skills(self):
        t = self.files()['misconception.eng.lis.sem.json']
        self.assertEqual((t['skills'], t['kind'], t['family']), (['ENG-A-01'], 'diagnostic', 'MEANING'))

    def test_a_lesson_is_numbered_in_file_order_and_takes_the_default_celebration(self):
        l = self.files()['lesson.eng.greet-1.json']
        self.assertEqual((l['sequence'], l['skills'], l['items']), (1, ['ENG-A-01'], ['eng.a01.i01', 'eng.a01.i02']))
        self.assertEqual(l['celebration']['vo'], 'vo:eng.he_bye')

    def test_the_pack_file_lists_exactly_the_pictures_used(self):
        built = self.sb.build()
        pack = json.loads(built['pack.json'])
        self.assertEqual((pack['id'], pack['course'], pack['version'], pack['vo']), ('lang-eng', 'eng', '0.1.0', []))
        self.assertEqual([a['id'] for a in pack['assets']], ['a', 'b', 'c'])
        self.assertEqual({k for k in built if k.endswith('.svg')}, {'a.svg', 'b.svg', 'c.svg'})

    def test_a_picture_id_with_hyphens_becomes_an_asset_id_with_underscores(self):
        self.sb.pictures += ['pip-arrive']
        self.sb.unit['items'][0]['options'][0] = 'pip-arrive'
        built = self.sb.build()
        self.assertIn('pip_arrive.svg', built)

    def test_a_text_option_is_a_letter_face(self):
        self.sb.unit['items'][0] = {'id': 'i01', 'kind': 'tap', 'options': ['text:ב', 'text:5', 'text:●'],
                                    'wrong': {'text:5': 'sem', 'text:●': 'guess'}, 'target': 'en-hello'}
        a = self.files()['activity.eng.a01.i01.json']
        self.assertEqual(a['answer']['face'], 'letter')
        self.assertEqual(a['answer']['options'][0]['text'], 'ב')

    def test_an_option_may_carry_its_own_clip(self):
        self.sb.unit['items'][0]['options'][0] = {'pic': 'a', 'clip': 'en-bye'}
        a = self.files()['activity.eng.a01.i01.json']
        self.assertEqual(a['answer']['options'][0]['clip'], 'vo:eng.en_bye')

    def test_the_voice_plan_has_the_texts(self):
        self.sb.write()
        c = lang_pack.Course('eng', self.sb.root)
        c.build()
        plan = c.voice_plan
        self.assertEqual([x['id'] for x in plan['targetClips']], ['en-bye', 'en-bye-slow', 'en-hello'])
        self.assertEqual(plan['targetClips'][2]['shown'], 'Hello!')
        self.assertIn('he-gl', {x['id'] for x in plan['frameLines']})

    def test_the_hebrew_text_is_always_needs_editor(self):
        for name, d in self.files().items():
            if name != 'pack.json':
                self.assertEqual(d['review'], 'needs-editor', name)

    def test_the_same_files_give_the_same_bytes(self):
        self.assertEqual(self.sb.build(), self.sb.build())

    def test_a_skill_passes_its_engine_fields_through(self):
        self.sb.unit['skill'].update({'setCoverage': True, 'worldObject': 'greeting-flag', 'childLine': 'שָׁלוֹם'})
        s = self.files()['skill.ENG-A-01.json']
        self.assertTrue(s['setCoverage'])
        self.assertEqual(s['worldObject'], 'greeting-flag')
        self.assertEqual(s['childLine'], [{'t': 'he', 'v': 'שָׁלוֹם'}])


class RawAndGateTest(Base):
    def test_a_raw_item_is_stamped_with_its_id_course_domain_and_review(self):
        self.sb.unit['items'].append({'id': 'r01', 'kind': 'raw', 'activity': {
            'template': 'sing_along', 'templateVersion': '1.0', 'representation': 'story', 'purpose': 'practice'}})
        d = self.files()['activity.eng.a01.r01.json']
        self.assertEqual((d['id'], d['course'], d['domain'], d['band'], d['review']),
                         ('eng.a01.r01', 'eng', 'languages', 'A', 'needs-editor'))
        self.assertEqual(d['skills'], [{'id': 'ENG-A-01', 'weight': 1}])

    def test_a_raw_item_needs_a_template_and_a_representation(self):
        self.sb.unit['items'].append({'id': 'r01', 'kind': 'raw', 'activity': {'purpose': 'practice'}})
        self.assertProblem('a raw item has "activity"')
        self.sb.unit['items'][-1]['activity'] = {'template': 'sing_along', 'representation': 'nope'}
        self.assertProblem('a raw activity names its "representation"')

    def test_a_gate_document_is_written_with_the_course(self):
        self.sb.unit['docs'] = [{'kind': 'gate', 'id': 'eng.oral', 'doc': {'requires': ['ENG-A-01'], 'holds': ['ENG-B-01']}}]
        g = self.files()['gate.eng.oral.json']
        self.assertEqual((g['schema'], g['course'], g['review']), ('gate/v1', 'eng', 'needs-editor'))


class PlacementTest(Base):
    def setUp(self):
        super().setUp()
        self.sb.unit['items'] += [
            {'id': 'p01', 'kind': 'tap', 'purpose': 'probe', 'target': 'en-hello', 'options': ['a', 'b'], 'wrong': {'b': 'sem'}},
            {'id': 'p02', 'kind': 'tap', 'purpose': 'probe', 'target': 'en-bye', 'options': ['b', 'a'], 'wrong': {'a': 'sem'}},
        ]
        self.sb.placement = {
            'perVisit': 8, 'thanks': 'he-ok', 'celebration': 'he-bye',
            'strands': [{'id': 'o', 'start': [{'answer': 'knowsLetters', 'equals': 'some', 'level': 1}],
                         'levels': [{'items': ['a01.p01'], 'assumes': ['ENG-A-01']}, {'items': ['a01.p02']}]}]}

    def test_the_placement_document_names_probes_by_their_full_ids(self):
        p = self.files()['placement.eng.placement.json']
        self.assertEqual(p['id'], 'eng.placement')
        self.assertEqual(p['strands'][0]['levels'][0], {'items': ['eng.a01.p01'], 'assumes': ['ENG-A-01']})
        self.assertEqual(p['strands'][0]['levels'][1], {'items': ['eng.a01.p02']})
        self.assertEqual(p['strands'][0]['start'][0]['level'], 1)
        self.assertEqual((p['thanks']['vo'], p['celebration']['vo']), ('vo:eng.he_ok', 'vo:eng.he_bye'))

    def test_a_probe_must_be_a_probe(self):
        self.sb.placement['strands'][0]['levels'][1]['items'] = ['a01.i01']
        self.assertProblem('must have "purpose": "probe"')

    def test_a_probe_must_exist(self):
        self.sb.placement['strands'][0]['levels'][1]['items'] = ['a01.p09']
        self.assertProblem('is not an item')

    def test_assumed_skills_must_be_in_the_pack(self):
        self.sb.placement['strands'][0]['levels'][0]['assumes'] = ['ENG-A-09']
        self.assertProblem('which is not a skill of this pack')


class RulesTest(Base):
    def test_a_good_sandbox_has_no_problems(self):
        self.assertEqual(self.sb.problems(), '')

    def test_a_line_that_is_not_written_is_named(self):
        self.sb.unit['items'][0]['frame'] = 'he-nope'
        self.assertProblem('the line "he-nope" is not in course.json "lines"')

    def test_a_clip_with_no_pronunciation_row_is_named(self):
        self.sb.unit['items'][0]['target'] = 'en-nope'
        self.assertProblem('the clip "en-nope" has no row')

    def test_a_missing_picture_is_named(self):
        self.sb.unit['items'][0]['options'][0] = 'nowhere'
        self.sb.unit['items'][0]['right'] = 'nowhere'
        self.assertProblem('the picture "nowhere" is not in content/languages/pictures')

    def test_an_untagged_distractor_is_refused(self):
        del self.sb.unit['items'][0]['wrong']['c']
        self.assertProblem('the distractor "c" has no tag')

    def test_an_unknown_tag_is_refused(self):
        self.sb.unit['items'][0]['wrong']['c'] = 'nope'
        self.assertProblem('the tag "nope" is not in course.json "tags"')

    def test_the_right_answer_must_be_an_option(self):
        self.sb.unit['items'][0]['right'] = 'z'
        self.assertProblem('the right answer "z" is not among the options')

    def test_a_band_a_item_has_two_or_three_options(self):
        self.sb.unit['items'][0]['options'] = ['a']
        self.assertProblem('has 2 or 3 options')

    def test_an_option_listed_twice_is_refused(self):
        self.sb.unit['items'][0]['options'] = ['a', 'b', 'b']
        self.assertProblem('an option is listed twice')

    def test_wrong_may_not_name_a_foreign_option(self):
        self.sb.unit['items'][0]['wrong']['zzz'] = 'sem'
        self.assertProblem('"wrong" names "zzz"')

    def test_a_skill_of_another_course_is_refused(self):
        self.sb.unit['skill']['id'] = 'HEB-A-01'
        self.assertProblem('the prefix is the course in capitals')

    def test_a_prerequisite_must_be_in_the_pack(self):
        self.sb.unit['skill']['prerequisites'] = [{'skill': 'ENG-A-00'}]
        self.assertProblem('is not a skill of this course pack')

    def test_a_skill_needs_a_strand_and_a_title(self):
        del self.sb.unit['skill']['strand']
        del self.sb.unit['skill']['title']
        text = self.sb.problems()
        self.assertIn('needs a "strand"', text)
        self.assertIn('needs a title', text)

    def test_duplicate_items_are_refused(self):
        self.sb.unit['items'][1]['id'] = 'i01'
        self.assertProblem('the id eng.a01.i01 is used twice')

    def test_a_lesson_names_items_of_this_course(self):
        self.sb.unit['lessons'][0]['items'].append('i77')
        self.assertProblem('the item "i77" is not in this course')

    def test_a_lesson_needs_a_title(self):
        del self.sb.unit['lessons'][0]['title']
        self.assertProblem('needs a title (Hebrew)')

    def test_a_ladder_has_three_steps(self):
        del self.sb.course['ladders']['HL'][2]
        self.assertProblem('a ladder has exactly 3 steps')

    def test_a_ladder_step_has_a_known_action(self):
        self.sb.course['ladders']['HL'][0]['action'] = 'dance'
        self.assertProblem('has action "dance"')

    def test_a_gloss_must_be_there(self):
        del self.sb.course['glosses']['en-hello']
        self.assertProblem('"glosses" has none for "en-hello"')

    def test_an_unknown_ladder_is_refused(self):
        self.sb.unit['items'][0]['ladder'] = 'HL-9'
        self.assertProblem('the ladder "HL-9" is not in course.json "ladders"')

    def test_a_tag_needs_a_kind_a_family_from_the_list_and_a_parent_text(self):
        self.sb.course['tags']['sem'].update({'kind': 'x', 'family': 'NOPE'})
        del self.sb.course['tags']['sem']['parentText']
        text = self.sb.problems()
        self.assertIn('kind must be one of', text)
        self.assertIn('family must be one of', text)
        self.assertIn('needs "parentText"', text)

    def test_a_tag_id_follows_course_strand_slug(self):
        self.sb.course['tags']['sem']['id'] = 'M-ENG-SEM'
        self.assertProblem('id must be <course>.<strand>.<slug>')

    def test_a_pack_version_must_be_semver(self):
        self.sb.course['pack']['version'] = '1.0'
        self.assertProblem('pack.version must look like 0.1.0')

    def test_a_line_id_must_be_a_clip_id(self):
        self.sb.course['lines']['He_Bad'] = {'he': 'x'}
        self.assertProblem('must be lower case letters, digits and hyphens')

    def test_the_course_in_the_file_must_match_its_folder(self):
        self.sb.course['course'] = 'rus'
        self.assertProblem('course must be "eng"')

    def test_feedback_needs_its_three_parts(self):
        del self.sb.course['feedback']['unsure']
        self.assertProblem('feedback needs "right"')

    def test_an_unknown_kind_is_refused(self):
        self.sb.unit['items'][0]['kind'] = 'dance'
        self.assertProblem('unknown kind "dance"')

    def test_every_problem_is_said_at_once(self):
        self.sb.unit['items'][0]['frame'] = 'he-nope'
        self.sb.unit['items'][1]['target'] = 'en-nope'
        self.sb.course['pack']['version'] = 'x'
        text = self.sb.problems()
        self.assertIn('he-nope', text)
        self.assertIn('en-nope', text)
        self.assertIn('pack.version', text)

    def test_the_pack_is_not_written_when_there_are_problems(self):
        self.sb.unit['items'][0]['frame'] = 'he-nope'
        self.sb.write()
        with self.assertRaises(lang_pack.SpecError):
            lang_pack.run(('eng',), root=self.sb.root, quiet=True)
        self.assertFalse(os.path.exists(os.path.join(self.sb.root, 'content', 'languages', 'eng', 'pack')))


class WriteTest(Base):
    def test_run_writes_the_pack_folder_and_removes_what_the_spec_no_longer_makes(self):
        self.sb.write()
        lang_pack.run(('eng',), root=self.sb.root, quiet=True)
        pack = os.path.join(self.sb.root, 'content', 'languages', 'eng', 'pack')
        stale = os.path.join(pack, 'activity.eng.a01.old.json')
        with open(stale, 'w') as fh:
            fh.write('{}')
        self.assertEqual(lang_pack.run(('eng',), root=self.sb.root, check=True, quiet=True), [stale])
        lang_pack.run(('eng',), root=self.sb.root, quiet=True)
        self.assertFalse(os.path.exists(stale))
        self.assertEqual(lang_pack.run(('eng',), root=self.sb.root, check=True, quiet=True), [])

    def test_a_course_without_a_course_file_is_skipped(self):
        self.assertEqual(lang_pack.run(('rus',), root=self.sb.root, quiet=True), [])
        self.assertFalse(os.path.exists(os.path.join(self.sb.root, 'content', 'languages', 'rus', 'pack')))

    def test_the_command_line_says_the_problems_and_exits_1(self):
        self.sb.unit['items'][0]['frame'] = 'he-nope'
        self.sb.write()
        self.assertEqual(lang_pack.main(['eng'], root=self.sb.root), 1)
        self.assertEqual(lang_pack.main(['fra'], root=self.sb.root), 2)


if __name__ == '__main__':
    unittest.main()
