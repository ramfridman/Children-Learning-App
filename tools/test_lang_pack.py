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
                            ignore=shutil.ignore_patterns('pack', 'voice-plan.json', 'fonts', 'latin.json', 'cyrillic.json', 'hebrew-print.json', 'hebrew-script.json') if rel == 'content/languages'
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


def strings(node, key):
    """Every string of a document under [key] (every string when [key] is None), at any depth."""
    out = []
    if isinstance(node, dict):
        for k, v in node.items():
            if isinstance(v, str):
                if key is None or k == key:
                    out.append(v)
            else:
                out += strings(v, key)
    elif isinstance(node, list):
        for v in node:
            if isinstance(v, str):
                if key is None:
                    out.append(v)
            else:
                out += strings(v, key)
    return out


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
                    for tag in strings(d, 'misconception'):
                        self.assertIn(tag, tags, name)
                if name.startswith('skill.'):
                    self.assertTrue(set(d['misconceptions']) <= tags, name)
                    self.assertTrue({p['skill'] for p in d['prerequisites']} <= skills, name)

    def test_every_distractor_is_tagged_and_two_choice_items_allow_one_retry(self):
        for course in lang_pack.COURSES:
            for name, d in self.docs(course).items():
                if not name.startswith('activity.'):
                    continue
                answer = d['answer']
                if answer.get('type') != 'choice':
                    continue  # a sort, a pair, a drum, a story that is only heard, a personal turn: the tags are on the card, the face or the classifier
                options = answer['options']
                right = answer['correct'] if isinstance(answer['correct'], list) else [answer['correct']]
                wrong = [o for o in options if o['id'] not in right]
                self.assertTrue(all('misconception' in o for o in wrong), name)
                if d['template'] != 'count_tap':
                    self.assertEqual(d['scoring']['maxAttempts'], 2 if len(options) == 2 else 3, name)

    def test_every_picture_an_item_shows_is_in_the_pack_and_in_the_shared_library(self):
        for course in lang_pack.COURSES:
            pack_dir = os.path.join(ROOT, 'content', 'languages', course, 'pack')
            assets = {a['id']: a['file'] for a in self.docs(course)['pack.json']['assets']}
            for asset, file in assets.items():
                self.assertTrue(os.path.exists(os.path.join(pack_dir, file)), file)
                shared = os.path.join(ROOT, 'content', 'languages', 'pictures', asset.replace('_', '-') + '.svg')
                if not os.path.exists(shared):
                    # made by the generator: the blank target of a count, or a thing on a glow
                    self.assertTrue(asset == 'blank' or asset.endswith('_lit'), file)
                    continue
                with open(os.path.join(pack_dir, file), 'rb') as a, open(shared, 'rb') as b:
                    self.assertEqual(a.read(), b.read(), file)
            for name, d in self.docs(course).items():
                if name.startswith('activity.'):
                    for ref in strings(d, None):
                        if ref.startswith('asset:'):
                            self.assertIn(ref[len('asset:'):], assets, name)

    def test_the_voice_plan_lists_every_clip_a_document_names(self):
        for course in lang_pack.COURSES:
            with open(os.path.join(ROOT, 'content', 'languages', course, 'voice-plan.json'), encoding='utf-8') as fh:
                plan = json.load(fh)
            # The clips of single words of a `follow` page are cut from the clip of their page: they are named, and never voiced of their own.
            cut = {c['vo'] for c in plan.get('cutClips', [])}
            planned = {c['vo'] for c in plan['frameLines']} | {c['vo'] for c in plan['targetClips']} | cut
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
            for c in plan.get('cutClips', []):
                self.assertTrue(c['from'] and c['text'], c)
                self.assertNotIn(c['vo'], {t['vo'] for t in plan['targetClips']}, 'a cut clip is not a clip to voice')


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


# ---------------------------------------------------------------------------------------------------------------- the recipes

EXTRA_CSV = ('en-cat,cat,cat.,/k/\nen-dog,dog,dog.,/d/\nen-one,one,one.,/w/\nen-two,two,two.,/t/\nen-three,three,three.,/t/\n'
             'en-whats-this,What\'s this?,What is this?,/w/\nen-its-cat,It\'s a cat.,It is a cat.,/i/\nen-yes,yes,yes.,/j/\n'
             'en-ch-1,Hello cat,Hello cat.,/h/\nen-ch-2,Bye dog,Bye dog.,/b/\nen-cat-slow,cat,cat.,/k/\nen-thats-ok,That\'s OK!,That is OK.,/o/\n')
EXTRA_LINES = {'he-q': 'מִי זֶה?', 'he-pass': 'זֶה בְּסֵדֶר!', 'he-heard': 'שָׁמַעְתִּי:', 'he-together': 'נֹאמַר יַחַד.', 'he-bin': 'קֻפְסָה'}


class RecipeBase(Base):
    """A sandbox that has the clips, lines and pictures the recipes need."""

    def setUp(self):
        super().setUp()
        global CSV
        self.saved = CSV
        CSV = CSV + EXTRA_CSV
        self.addCleanup(self.restore)
        self.sb.pictures = ['a', 'b', 'c', 'd', 'e', 'f']
        self.sb.course['lines'].update({k: {'he': v} for k, v in EXTRA_LINES.items()})
        self.sb.course['defaults'].update({'pass': 'he-pass', 'heard': 'he-heard', 'together': 'he-together'})
        self.sb.course['ladders']['HL'][1]['orLine'] = 'he-show'  # a word with no gloss says another line
        self.sb.course['tags']['yesno'] = {'id': 'eng.lis.yesno', 'kind': 'diagnostic', 'family': 'MEANING', 'parentText': 'טקסט להורה.'}

    def restore(self):
        global CSV
        CSV = self.saved

    def one(self, item, extra_lessons=True):
        self.sb.unit['items'] = [item]
        self.sb.unit['lessons'] = [{'id': 'l-1', 'title': 'כותרת', 'items': [item['id']]}]
        files = self.files()
        return files, files['activity.eng.a01.%s.json' % item['id']]


class RecipesTest(RecipeBase):
    def test_a_tap_item_can_have_a_stage_picture_a_second_target_clip_and_a_clip_after_the_right_answer(self):
        _, doc = self.one({'id': 'i01', 'kind': 'tap', 'target': 'en-whats-this', 'target2': 'en-its-cat', 'hintWord': 'en-cat',
                           'stage': 'a', 'options': ['b', 'c'], 'wrong': {'c': 'sem'}, 'after': 'en-yes', 'pole': 'yes'})
        self.assertEqual(doc['scene'], {'group': {'sprite': 'asset:a', 'count': 1}})
        self.assertEqual((doc['prompt']['target'], doc['prompt']['target2']), ('vo:eng.en_whats_this', 'vo:eng.en_its_cat'))
        self.assertEqual(doc['feedback']['correct']['target'], 'vo:eng.en_yes')
        self.assertEqual(doc['answer']['pole'], 'yes')

    def test_sound_only_options_are_buttons_and_a_wrong_one_is_named_by_its_clip(self):
        _, doc = self.one({'id': 'i01', 'kind': 'tap', 'options': [{'clip': 'en-cat'}, {'clip': 'en-dog'}], 'wrong': {'en-dog': 'sem'}})
        self.assertEqual([sorted(o) for o in doc['answer']['options']], [['clip', 'id', 'label'], ['clip', 'id', 'label', 'misconception']])

    def test_a_tap_all_names_its_right_cards_and_is_tap_answer_1_4(self):
        _, doc = self.one({'id': 'i01', 'kind': 'tap', 'face': 'letter', 'options': ['text:a', 'text:b', 'text:c'],
                           'letters': ['text:a', 'text:b'], 'wrong': {'text:c': 'sem'}})
        self.assertEqual((doc['templateVersion'], doc['answer']['all'], doc['answer']['correct']), ('1.4', True, ['o1', 'o2']))

    def test_a_per_item_feedback_line_and_an_inline_ladder_replace_the_course_ones(self):
        step = {'line': 'he-again', 'action': 'replay_prompt_slow'}
        _, doc = self.one({'id': 'i01', 'kind': 'tap', 'target': 'en-cat', 'options': ['a', 'b'], 'wrong': {'b': 'sem'},
                           'feedback': {'byTag': {'sem': {'line': 'he-show'}}}, 'ladder': [step, step, dict(step, action='worked_example')]})
        self.assertEqual(doc['feedback']['incorrect'][0]['caption'][0]['v'], LINES['he-show'])
        self.assertEqual(len(doc['hints']), 3)

    def test_a_say_item_with_a_tap_makes_two_activities_that_a_lesson_plays_in_order(self):
        files, doc = self.one({'id': 'i01', 'kind': 'say', 'picture': 'a', 'clip': 'en-cat', 'forms': ['cat'], 'foils': ['cut'],
                               'purpose': 'practice', 'then': {'kind': 'tap', 'target': 'en-cat', 'options': ['a', 'b'],
                                                               'wrong': {'b': 'sem'}}})
        self.assertEqual(doc['template'], 'say_it')
        self.assertEqual(doc['answer'], {'type': 'say_it', 'scored': False})
        self.assertEqual(files['lesson.eng.l-1.json']['items'], ['eng.a01.i01', 'eng.a01.i01t'])
        self.assertEqual(files['activity.eng.a01.i01t.json']['template'], 'tap_answer')

    def test_a_puppet_bubble_answers_with_the_right_bubble_and_a_personal_turn_is_never_scored(self):
        _, doc = self.one({'id': 'i01', 'kind': 'puppet', 'picture': 'a', 'prompt': ['en-cat', 'en-dog'],
                           'options': [{'clip': 'en-yes', 'pic': 'b'}, {'clip': 'en-dog'}], 'wrong': {'en-dog': 'sem'}})
        self.assertEqual(doc['feedback']['correct']['target'], 'vo:eng.en_yes')
        self.assertEqual(doc['prompt']['target2'], 'vo:eng.en_dog')
        _, doc = self.one({'id': 'p01', 'kind': 'puppet', 'mode': 'personal', 'topic': 'age', 'picture': 'a', 'prompt': ['en-cat'],
                           'cards': ['n:3'], 'cardClips': ['en-three'], 'reply': ['@card', 'en-yes'], 'pass': 'en-thats-ok'})
        self.assertEqual((doc['purpose'], doc['answer']['type'], doc['answer']['options'][0]['numeral']), ('practice', 'none', 3))
        self.assertEqual(doc['answer']['pass']['target'], 'vo:eng.en_thats_ok')

    def test_a_drum_item_maps_one_more_and_one_fewer_to_tags_and_is_free_response(self):
        _, doc = self.one({'id': 'i01', 'kind': 'drum', 'frame': 'he-tap', 'word': ['en-cat'], 'slow': ['en-cat-slow'], 'picture': 'a',
                           'beats': 2, 'oneMore': 'sem', 'oneFewer': 'guess'})
        self.assertEqual(doc['answer']['beats'], 2)
        self.assertEqual([c['when'] for c in doc['answer']['classifiers']], ['one_more', 'one_fewer'])
        self.assertNotIn('target', doc['prompt'])

    def test_a_count_lights_the_things_from_their_own_picture_and_its_options_are_number_words(self):
        files, doc = self.one({'id': 'i01', 'kind': 'count', 'objects': 'a', 'count': 2, 'clips': ['en-one', 'en-two'],
                               'answerPrompt': 'he-q', 'options': [{'clip': 'en-two', 'value': 2}, {'clip': 'en-three', 'value': 3}],
                               'wrong': {'en-three': 'sem'}})
        self.assertEqual(doc['scene']['objects']['litSprite'], 'asset:a_lit')
        self.assertIn({'id': 'a_lit', 'file': 'a_lit.svg'}, files['pack.json']['assets'])
        self.assertEqual(doc['answer']['options'][1]['value'], 3)
        self.assertEqual(doc['scene']['target'], {'sprite': 'asset:blank'})

    def test_pairs_have_two_rows_and_the_bottom_row_stands_one_place_along(self):
        _, doc = self.one({'id': 'i01', 'kind': 'pairs', 'pairs': [['a', 'b', 'en-cat'], ['c', 'd', 'en-dog']],
                           'wrong': {'a+d': 'sem'}})
        self.assertEqual([f['id'] for f in doc['scene']['left']], ['l1', 'l2'])
        self.assertEqual([f['id'] for f in doc['scene']['right']], ['r2', 'r1'])
        self.assertTrue(all('misconception' in f for f in doc['scene']['right']))

    def test_a_sort_has_bins_that_say_their_name_and_cards_that_carry_the_tag_of_their_mistake(self):
        _, doc = self.one({'id': 'i01', 'kind': 'sort', 'frame': 'he-tap', 'bins': [{'id': 'x', 'label': 'en-cat', 'picture': 'a'},
                                                                                   {'id': 'y', 'label': 'en-dog', 'picture': 'b'}],
                           'cards': [{'pic': 'c', 'clip': 'en-cat', 'bin': 'x'}, {'pic': 'd', 'bin': 'y'}],
                           'traps': {'c': {'tag': 'sem'}}})
        self.assertEqual([c['bin'] for c in doc['scene']['items']], ['b1', 'b2'])
        self.assertEqual(doc['scene']['items'][0]['misconception'], 'eng.lis.sem')
        self.assertEqual(doc['answer']['mode'], 'sort')

    def test_a_chant_lights_the_pictures_whose_word_a_line_says(self):
        _, doc = self.one({'id': 'i01', 'kind': 'chant', 'frame': 'he-tap', 'lines': ['en-ch-1', 'en-ch-2'],
                           'pictures': [{'pic': 'a', 'clip': 'en-cat'}, {'pic': 'b', 'clip': 'en-dog'}]})
        self.assertEqual([l['lights'] for l in doc['scene']['lines']], [[0], [1]])
        self.assertEqual((doc['purpose'], doc['answer']), ('practice', {'type': 'none', 'mode': 'chant'}))

    def test_a_story_has_pages_and_a_dialogic_pause_with_a_recast(self):
        _, doc = self.one({'id': 'i01', 'kind': 'story', 'mode': 'dialogic', 'frame': 'he-tap', 'question': 'he-q',
                           'pages': [{'picture': 'a', 'clips': ['en-cat']}, {'picture': 'b', 'clips': ['en-dog']}],
                           'pauseAfter': 0, 'options': ['c', 'd'], 'wrong': {'d': 'sem'}, 'recast': 'en-dog'})
        self.assertEqual((doc['answer']['mode'], doc['answer']['pauseAfter']), ('dialogic', 0))
        self.assertEqual(doc['feedback']['correct']['target'], 'vo:eng.en_dog')

    def test_a_place_command_reads_the_places_of_its_picture(self):
        self.sb.unit['items'] = [{'id': 'i01', 'kind': 'listen_do', 'mode': 'place', 'frame': 'he-tap', 'picture': 'a', 'thing': 'b',
                                  'options': ['on', 'under'], 'right': 'on', 'wrong': {'under': 'sem'}}]
        self.sb.unit['lessons'] = [{'id': 'l-1', 'title': 'כותרת', 'items': ['i01']}]
        self.sb.write()
        areas = {'pictures': {'a': {'on': [0.3, 0.1, 0.4, 0.3], 'under': [0.3, 0.6, 0.4, 0.3], '@thing': [0.7, 0.1, 0.29, 0.29]}}}
        with open(os.path.join(self.sb.root, 'content', 'languages', 'pictures', 'scenes.areas.json'), 'w', encoding='utf-8') as fh:
            json.dump(areas, fh)
        files = {k: json.loads(v) for k, v in lang_pack.Course('eng', self.sb.root).build().items() if k.endswith('.json')}
        doc = files['activity.eng.a01.i01.json']
        self.assertEqual(doc['answer']['options'][0]['at'], {'x': 0.3, 'y': 0.1, 'w': 0.4, 'h': 0.3})
        self.assertEqual(doc['scene']['thing']['sprite'], 'asset:b')

    def test_a_place_with_no_touch_area_is_named_for_the_design_director(self):
        self.sb.unit['items'] = [{'id': 'i01', 'kind': 'listen_do', 'mode': 'place', 'frame': 'he-tap', 'picture': 'a', 'thing': 'b',
                                  'options': ['on', 'under'], 'right': 'on', 'wrong': {'under': 'sem'}}]
        self.sb.unit['lessons'] = [{'id': 'l-1', 'title': 'כותרת', 'items': ['i01']}]
        self.assertProblem('has no touch area "on"')

    def test_a_second_target_clip_needs_a_first(self):
        self.sb.unit['items'] = [{'id': 'i01', 'kind': 'tap', 'target2': 'en-cat', 'options': ['a', 'b'], 'wrong': {'b': 'sem'}}]
        self.sb.unit['lessons'] = [{'id': 'l-1', 'title': 'כותרת', 'items': ['i01']}]
        self.assertProblem('second target clip has a first one')


if __name__ == '__main__':
    # The tests of test_lang_pack_more.py run with these (it imports this file, so it is imported only when this one is the script).
    from test_lang_pack_more import FontTest, OwnNameTest, PrintTest, TeachTest  # noqa: F401
    unittest.main()
